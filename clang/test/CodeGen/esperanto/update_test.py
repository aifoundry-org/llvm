#!/usr/bin/env python3
from argparse import ArgumentParser
from shutil import move
from subprocess import check_output
import re

def main():
    args = parse_args()

    out = open("temp.cpp", "w")
    with open(args.test, "r") as src:
        for line in src:
            if re.match("^// CHECK", line):
                continue
            print(line.rstrip(), file=out)
        
    
    cmd = f"clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -O3 -o - -S {args.test}"
    prefix = "CHECK"
    for line in check_output(cmd.split(" "),encoding='utf-8').split("\n"):
        if re.match("^\t\.", line):
            prefix = "CHECK"
            continue
        if re.match("^.Lfunc", line):
            prefix = "CHECK"
            continue
        line = re.sub("\s*#.*","", line)
        if not line:
            prefix = "CHECK"
            continue
        print("//", prefix + ":", line, file=out)

        prefix = "CHECK-NEXT"
    out.close()
    move("temp.cpp", args.test)
    


def parse_args():
    parser = ArgumentParser()
    parser.add_argument("test")
    return parser.parse_args()

if __name__ == "__main__":
    main()
