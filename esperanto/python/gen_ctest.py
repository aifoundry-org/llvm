#!/usr/bin/env python3
from argparse import ArgumentParser
from os.path import exists, join
from sys import stderr, stdin
from tblgen import getRecords
import re

from cmds import do_parse_args, output, command, shell
from et_names import GPR, FPR, ROUNDING_MODES_LIST

DESCRIPTION="""Generate trivial C functions each of which tests
one of the builtin functions corresponding to the explicit
form of an ET instruction"""

def main():
    args = parse_args()
    records = [ r for r in getRecords()
                   if "HasEsperanto" in r.getValue("Predicates")]
    recordNames = { r.name for r in records }
    for r in records:
        if args.include and not re.match(args.include, r.name, re.I):
            continue
        if args.exclude and re.match(args.exclude, r.name, re.I):
            continue
        # when there is an "explicit" pseudo instruction
        # use that instead of the actual machine instruction
        if r.name + "_EX" in recordNames:
            continue
        # Exclude the stack pseudo ops
        # Exclude the MOVA operation as they are not modeled fully
        if any([r.name.startswith(p) for p in ["Stack", "MOVA"]]):
            continue
        generate(r)

        
def generate(inst):
    "Generate a C function to exersize 'inst'"
    asm = inst.getValue("AsmString")
    opcode,args = asm.split("\t",1)
    name = inst.name.lower()
    if name.endswith("_ex"):
        name = name[:-3]
    isFloat = inst.is_float()
    results = convert(inst.getValue("OutOperandList"), isFloat)
    if not results:
        ret_ty = "void"
        ret_keyword = ""
    else:
        ret_ty =results[0][0]
        ret_keyword = "return "
    asm_args = convert(inst.getValue("InOperandList"),isFloat)
    if inst.getValue("mayLoad") or inst.getValue("mayStore"):
        # the address operand is always the last parameter
        # and is always an int*
        idx = -2 if inst.name.endswith("_EX") else -1
        asm_args[idx] = ("int *", asm_args[idx][1])

    # when the type of a argument is a int, then it is an immediate
    # (the value is the field width) which we replace with the
    # always legal value of 0.
    typed_args = ",".join([
        f"{ty} {n}" for ty,n in asm_args if not isinstance(ty,int) ])
    args = ",".join([n if not isinstance(ty,int) else "0"
                              for ty,n in asm_args])
    print(f"""\
{ret_ty} test_{name}({typed_args}) {{
    {ret_keyword}__builtin_riscv_{name}({args});
}}""")


# map operand types to C-types or integers for literal field width    
intTypeMap = { "GPR" : "long" ,
               "MR" : "long",
               "MR0" : "long",
               "FPR32" : "float",
               "frmarg" : 3,
               "ofrmarg" : 3,
               "uimm3" : 3,
               "uimm4" : 4,
               "uimm5" : 5,
               "uimm8" : 8,
               "simm10" : 10,
               "simm12" : 12,
               "simm20" : 20,
               "uimm20_lui" : 20,
               "FPR256" : "int __attribute((vector_size (32)))" }
# used for floating point instructions
floatTypeMap = intTypeMap.copy()
floatTypeMap["FPR256"] = "float __attribute((vector_size (32)))"

def convert(ops, isFloat):
    "Convert tblgen ops to C-type,name pairs"
    typeMap = floatTypeMap if isFloat else intTypeMap
    result = []
    for op in ops:
        ty, name = op.split(":",1)
        name = name[1:]
        ty = typeMap[ty]
        result.append((ty,name))
    return result
        

def parse_args():
    parser = ArgumentParser(DESCRIPTION)
    parser.add_argument("--include",
                        help="regular expression to select instructions")
    parser.add_argument("--exclude",
                        help="regular expression to de-select instructions")
    return do_parse_args(parser)

if __name__ == "__main__":
    main()
