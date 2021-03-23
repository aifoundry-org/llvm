#!/usr/bin/env python3
from argparse import ArgumentParser
from sys import stderr, stdout
from os.path import exists, join
from et_encodings import getEncodings

DESCRIPTION="""List all the disctint instruction formats
Formats are distinct when they have different positions
for registers or immediate values."""

def main():
    ArgumentParser(DESCRIPTION).parse_args()
    formats = set()
    for e in getEncodings():
        n = e.opcode.replace(".", "_")
        Format = []
        for f in e.fields:
            if f.is_literal():
                txt = ".".rjust(f.width,'.')
                if len(Format) > 0 and Format[-1][0] == ".":
                    Format[-1] += txt
                    continue
            else:
                txt = f.name
            Format.append(txt)
        ft = " ".join(Format)
        if ft in formats:
            continue
        formats.add(ft)
        print(e.opcode.ljust(15),ft)
        

if __name__ == "__main__":
    main()
