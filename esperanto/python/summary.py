#!/usr/bin/env python3
from argparse import ArgumentParser
from et_encodings import getEncodings
from os.path import join, dirname, abspath
from sys import stdin
from tblgen import getRecords
import re

DESCRIPTION="""Print summary of information in tablegen files.
This includes opcode names, with whether they may load or store and
the encoding pattern"""


def main():
    ArgumentParser(DESCRIPTION).parse_args()
    summary = {}
    for r in getRecords():
        if "HasEsperanto" not in r.getValue("Predicates"):
            continue
        if r.name.endswith("_EX") or r.name.startswith("Stack"):
            continue;

        summary[r.name] = r
        asm = r.getValue("AsmString")
        opcode,_ = asm.split("\t")
        if r.name != opcode.replace(".","_").upper():
            print("invalid opcode", r.name, opcode)

    for e in getEncodings():
        n = e.opcode.replace(".", "_")
        if e.mode != "ET" or n in summary:
            continue
        if e.minion == "0":
            continue
        print("unsupported",e.opcode,f"minion={e.minion}")

    # print informat in the same order it is listed in the .td
    # file which matches the draft PRM
    for Name in getOrder(TDF):
        r = summary.get(Name,None)
        if not r:
            print(Name.ljust(15), "missing")
            continue
        if r.name.endswith("_EX") or r.name.startswith("Stack"):
            continue

        L = "L" if r.getValue("mayLoad")  else " "
        S = "S" if r.getValue("mayStore") else " "
        Inst = r.getValue("Inst")
        Outs = r.getValue("OutOperandList")
        Ins = r.getValue("InOperandList")
        print(Name.ljust(15), L+S,
              packInst(Inst), " ", trimOps(Outs+Ins))



def packInst(Inst):
    """Convert the description of instruction bits to a format
    which match the PRM more or less"""
    Count = len(Inst)
    # print(Count, Inst)
    Idx = 0
    Result = ""
    while (Idx < Count):
        e = Inst[Idx]
        Idx += 1
        if e in ["0", "1"]:
            Result += e
            continue
        # print('e',e)
        name,width = e.split("{",1)
        # print(name, width, Idx)
        width = int(width[:-1])+1
        Idx += width -1
        Result += name.center(width)
    if Count != 32:
        Result += f" {Count}?"
    return Result

op_re = re.compile(r"(([A-Za-z0-9_])+:\$([A-Za-z0-9]+))")
def trimOps(ops):
    """Clean op the input/output ops a bit, drop immediates"""
    Result = []
    for op in ops:
        m = op_re.match(op)
        if not m:
            print(op)
        if m.group(3).startswith("imm"):
            continue
        Result.append(m.group(1))
    return " ".join(Result)

ROOT= dirname(dirname(dirname(abspath(__file__))))
TDF = join(ROOT,"llvm/lib/Target/RISCV/RISCVInstrInfoEsperanto.td")
def getOrder(tdf):
    "Scan the .td file to find specification order"
    with open(tdf, "r") as td:
        defs = []
        for line in td:
            words = line.split()
            if len(words) < 2:
                continue
            if words[0] != "def":
                continue
            if "Pseudo" in line:
                continue
            if words[1] in ['""', ':']:
                continue
            defs.append(words[1])
    return defs

if __name__ == "__main__":
    main()
