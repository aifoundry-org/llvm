#!/usr/bin/env python3
from argparse import ArgumentParser
from sys import stdin, stderr
from tblgen import getRecords
import re

DESCRIPTION="""
This script takes information from RISCV.td and 
generates three files

  BuiltinsRISCVET.def -- the set of builtin functions
      supported for Esperanto instructions
  IntrinsicsRISCET.def -- the LLVM intrinsics corresponding
      to Esperanto instructions.
  RISCVInstrInfoEsperantoPatterns.td -- DAG ISEL patterns
      to convert intrinsics to instructions.

Note where an "explicit" form of an instruction exists,
that is used for builtins and intrinsics rather than
the one with implicit register inputs. 
"""

def main():
    ArgumentParser(DESCRIPTION).parse_args()

    summary = {}
    target_prefix = "riscv"
    intrinsics = open("IntrinsicsRISCVET.td","w")
    builtins = open("BuiltinsRISCVET.def", "w")
    patterns = open("RISCVInstrInfoEsperantoPatterns.td", "w")
    print(f'let TargetPrefix = "{target_prefix}" in {{',file=intrinsics)
    records = getRecords();
    recordNames = { r.name for r in records } 
    
    for r in records:
        if "HasEsperanto" not in r.getValue("Predicates"):
            continue
        if r.name + "_EX" in recordNames:
            continue
        # Exclude the stack pseudo ops
        # Exclude the MOVA operation as they are not modeled fully
        if any([r.name.startswith(p) for p in ["Stack", "MOVA"]]):
            continue
        name = r.name.lower()
        builtinName = name[:-3] if r.name.endswith("_EX") else name
        mayLoad = r["mayLoad"]
        mayStore = r["mayStore"]
        isFloat = builtinName.endswith("_ps")
        result = getTypes(r.getValue("OutOperandList"), isFloat)
        in_ops = r.getValue("InOperandList")
        args = getTypes(in_ops, isFloat)
        attrs = getImmediates(r.getValue("InOperandList"))

        if mayLoad or mayStore:
            attrs.append("IntrArgMemOnly");
            if not mayStore:
                attrs.append("IntrReadMem");
            if not mayLoad:
                attrs.append("IntrWriteMem");
            addr = len(args)-1
            args[addr] = "llvm_ptr_ty"
            attrs.append(f"NoCapture<ArgIndex<{addr}>>")
        else:
            attrs.append("IntrNoMem")

        if result:
            btypes = getBuiltinTypes(r.getValue("OutOperandList"), isFloat)
        else:
            btypes = "v"

        ins = r.getValue("InOperandList")
        btypes += getBuiltinTypes(ins, isFloat)
        # last argument a pointer?
        if mayLoad or mayStore:
            # always pointer to int32
            if btypes.endswith("LiIi"): # addr + offset
                btypes = btypes[:-4] + "i*Ii"
            else:
                assert btypes.endswith("Li"),f"bad types {btypes} for {r.name}"
                btypes = btypes[:-2] + "i*"
            
        attrs = ",".join(attrs)
        result = ",".join(result)
        args = ",".join(args)
        print(f"""\
def int_{target_prefix}_{builtinName} : 
  GCCBuiltin<"__builtin_{target_prefix}_{builtinName}">,
  Intrinsic<[{result}],
            [{args}],
            [{attrs}]>;""", file=intrinsics);

        print(f'BUILTIN(__builtin_{target_prefix}_{builtinName} , "{btypes}", "")',
              file=builtins)

        def addType(op):
            ty, n = op.split(":",1)
            if ty in TXMap:
                return "timm:" + n
            if ty != "FPR256":
                return op            
            ty = "v8f32" if isFloat else "v8i32"
            return f"({ty} {op})"
        def addTX(op):
            ty, n = op.split(":",1)
            tx = TXMap.get(ty,None)
            if tx:
                return f"({tx} {n})"
            return n
        intr_args = ", ".join([ addType(op) for op in in_ops ])
        intr_out = ", ".join([ addTX(op) for op in in_ops ])
        
        print(f'def :Pat<(int_{target_prefix}_{builtinName} {intr_args}),',
              f'({r.name} {intr_out})>;', file=patterns)
        
    print(f'}} // TargetPrefix = "{target_prefix}"',file=intrinsics)


intTypeMap = { "GPR" : "llvm_i64_ty" ,
               "MR" : "llvm_i64_ty",
               "MR0" : "llvm_i64_ty",
               "FPR32" : "llvm_f32_ty",
               "frmarg" : "llvm_i64_ty",
               "ofrmarg" : "llvm_i64_ty",
               "uimm3" : "llvm_i64_ty",
               "uimm5" : "llvm_i64_ty",
               "FPR256" : "llvm_v8i32_ty" }
floatTypeMap = intTypeMap.copy()
floatTypeMap["FPR256"] = "llvm_v8f32_ty"


TXMap = {  "frmarg" : "LO3",
           "ofrmarg" : "LO3",
           "uimm3" : "LO3",
           "uimm4" : "LO3",
           "uimm5" : "LO5",
           "uimm8" : "LO8",
           "simm10" : "LO10s",
           "simm12" : "LO12s",
           "uimm20_lui" : "LO20",
}

def getTypes(ops, isFloat):
    typeMap = floatTypeMap if isFloat else intTypeMap
    typeList = []
    for op in ops:
        ty,name = op.split(":")
        if name.startswith("$imm"):
            rty = "llvm_i32_ty"        
        else:
            rty = typeMap.get(ty,None)
            if rty is None:
                print("invalid type",op,file=stderr)
                exit(1)
        typeList.append(rty)
    return typeList
        

def getImmediates(ops):
    imms = []
    for idx,op in enumerate(ops):
        ty,name = op.split(":")
        if not (name.startswith("$imm") or name == "$idx" or name == "$rm"):
            continue
        imms.append(f"ImmArg<ArgIndex<{idx}>>")
    return imms

builtinIntTypeMap = {
    "GPR" : "Li" ,
    "MR" : "Li",
    "MR0" : "Li",
    "FPR32" : "f",
    "frmarg" : "IULi",
    "ofrmarg" : "IULi",
    "uimm3" : "IULi",
    "uimm5" : "IULi",
    "FPR256" : "V8i",
}
builtinFloatTypeMap = builtinIntTypeMap.copy()
builtinFloatTypeMap["FPR256"] = "V8f"


def getBuiltinTypes(ops, isFloat):
    typeMap = builtinFloatTypeMap if isFloat else builtinIntTypeMap
    typeList = []
    for op in ops:
        ty,name = op.split(":")
        if name.startswith("$imm"):
            rty = "Ii"        
        else:
            rty = typeMap.get(ty,None)
            if rty is None:
                print("invalid type",op,file=stderr)
                exit(1)
        typeList.append(rty)
    return "".join(typeList)


if __name__ == "__main__":
    main()
