#!/usr/bin/env python3
from os.path import join,dirname, abspath
from subprocess import Popen, PIPE
import re
import sys

rvinst_re = re.compile("^def .*{\t//.* RVInst ");

class Instruction:
    "An instruction as specified in tblgen records output"
    def __init__(self,name,classes):
        # classes is the list of base class contributing
        # to the definition of an instruction
        self.name = name
        self.classes = classes
        self.attrs = {}
    def addAttr(self,attr):
        self.attrs[attr.name] = attr
    def getValue(self, attrname):
        "Return the value of an attribute by name"
        a = self.attrs.get(attrname,None)
        if not a:
            return None
        if a.ty == "string":
            return a.value[1:-1]
        if a.ty == "dag":
            v = a.value[1:-1]
            v = v[4:] if v.startswith("ins ") else v[5:]
            if not v:
                return []
            return v.split(", ")
        if a.ty == "bit":
            return int(a.value)
        if a.ty.startswith("bits"):
            return a.value[2:-2].split(", ")
        
        return a.value

    def __getitem__(self,key):
        return self.getValue(key)
    
    def getOperandNames(self):
        "Return the list of names of operands in the AsmString attribute"
        _ , args = self.getValue("AsmString").split("\t",1)
        Names = []
        for m in re.finditer(r"\$([a-z0-9]+)|\$\{([a-z0-9]+)\}", args):
            name = m.group(1) if m.group(1) else m.group(2)
            Names.append(name)
        return Names

    def is_float(self):
        "True iff this a floating point extension"
        if "_PS" not in self.name:
            return False
        # this instruction seems like it should be _PI because
        # it does integer sign extensions of loaded values
        if re.match("FMV[SZ]|FG32|FSC32|FLW|FSW|FG[BHW][GL]?_PS|FSC[BHW][GL]?_PS",
                    self.name):
            return False
        return True

class Attr:
    def __init__(self,name,is_field,ty, value):
        self.name = name
        self.is_field = is_field
        self.ty = ty
        self.value = value
        

def instructionsOnly(line):
    return rvinst_re.match(line) is not None

def readDefinitions(tbl, rfilter=instructionsOnly):
    for line in tbl:
        if line.startswith("------------- Defs "):
            break
    Insts  =[]
    Active = False;
    Current = None
    for line in tbl:
        if rfilter(line):
            Active = True
            Words = line.split(" ")
            Current = Instruction(Words[1], Words[4:])
            Insts.append(Current)
            continue
        if not Active:
            continue            
        if line.startswith("}"):
            Active = False
            continue
        try:
            lhs,rhs=line[2:-2].split(' = ',1)
            w = lhs.split()
            is_field = w[0] == "field"
            if is_field:
                w.pop(0)
            ty, name = w
            Current.addAttr(Attr(name,is_field, ty, rhs))
        except BaseException:
            print(line[:-1])
            print(lhs,rhs)
            print(w)
            raise
    return Insts

ROOT=dirname(dirname(dirname(abspath(__file__))))
BUILD=join(ROOT,"build")
BIN=join(BUILD,"bin")
def getRecords(rfilter=instructionsOnly):
    cmd = [join(BIN,"llvm-tblgen"),
           "-I", join(ROOT,"llvm/lib/Target/RISCV"),
           "-I", join(ROOT,"llvm/lib/Target"),
           "-I", join(ROOT,"llvm/include"),
           join(ROOT,"llvm/lib/Target/RISCV/RISCV.td")]
    p = Popen(cmd, stdout=PIPE, encoding="utf-8")
    return readDefinitions(p.stdout,rfilter)
           

if __name__ == "__main__":
    for r in getRecords():
        if "HasEsperanto" in r.attrs["Predicates"].value:
            print(r.name, r.getValue("Inst"))

