#!/usr/bin/env python3
from argparse import ArgumentParser
from subprocess import run, PIPE

def main():
    p = ArgumentParser()
    p.add_argument("src", help="source test")
    args = p.parse_args()
    with open(args.src,"r") as src:
        lines = [ line[:-1] for line in src if not line.startswith(";") ]


    with open(args.src,"r") as src:
        p = run(["llc", "-mcpu=et-soc1-min -mabi=lp64f"], check=True, stdin=src,stdout=PIPE)

    with open(args.src, "w") as src:
        print("; RUN: llc -mcpu=et-soc1-min -mabi=lp64f < %s | FileCheck %s", file=src)
        for line in lines:
            print(line,file=src)

        asm = iter(p.stdout.decode("utf-8").split("\n"))
        for line in asm:
            if line.startswith("# %bb.0:"):
                break
        prefix = "; CHECK:"
        for line in asm:
            if "fsq2" in line or line == "\tret":
                break
            print(prefix+line,file=src)
            prefix = "; CHECK-NEXT:"
        
    
    
    
if __name__ == "__main__":
    main()
