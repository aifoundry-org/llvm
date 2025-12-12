#!/usr/bin/env python3
from argparse import ArgumentParser
from sys import stderr, stdin
from os.path import exists, join
import re
from cmds import do_parse_args, output, command, shell
from tblgen import getRecords
from et_names import GPR, FPR, ROUNDING_MODES_LIST
from random import randrange, getrandbits

DESCRIPTION="""Generate examples of each ET extension
with randomly chosen valid parameters"""

def main():
    args = parse_args()
    for r in getRecords():
        if r.getValue("isPseudo"):
            continue
        # exclude Maxion instructions if the target is et-soc1-min
        if args.target == "et-soc1-min" and "HasEsperantoMaxion" in r.getValue("Predicates"):
            continue
        if "HasEsperanto" not in r.getValue("Predicates"):
            continue
        generate(r)

def generate(inst):
    asm = inst.getValue("AsmString")
    opcode,args = asm.split("\t",1)
    values = {}
    createValues(inst.getValue("InOperandList"),values)
    createValues(inst.getValue("OutOperandList"),values)
    # print(f"# \t{opcode}\t{args}")
    # print("#", values)
    nargs = ""
    end = 0
    for m in re.finditer(r"\$([a-z0-9]+)|\$\{([a-z0-9]+)\}", args):
        name = m.group(1) if m.group(1) else m.group(2)
        nargs += args[end:m.start()] + values[name]
        end = m.end()
    nargs += args[end:]
    print(f"\t{opcode}\t{nargs}")


def createValues(dag, values):
    for v in dag:
        ty,name = v.split(":",1)
        a = ty
        if ty.startswith("GPR"):
            a = GPR[randrange(32)]
        elif ty.startswith("FPR"):
            a = FPR[randrange(32)]
        elif ty.startswith("MR"):
            a = "m" + str(randrange(8))
        elif ty == "uimm20_lui":
            a = str(getrandbits(20))
        elif ty.startswith("simm"):
            w = int(ty[4:])
            a = str((1<<(w-1)) - getrandbits(w))
        elif ty.startswith("uimm"):
            w = int(ty[4:])
            a = str(getrandbits(w))
        elif ty == "frmarg" or ty == "ofrmarg":
            rm = randrange(6)
            if rm == 5:
                rm = 7
            a = ROUNDING_MODES_LIST[rm]
        else:
            print("unknown type:", ty)
            exit(1)
        values[name[1:]] = a

def parse_args():
    parser = ArgumentParser(DESCRIPTION)
    parser.add_argument("--target", default="et-soc1-min",
                        help="target triple to select et-soc1-min or et-soc1-max")
    return do_parse_args(parser)

if __name__ == "__main__":
    main()
