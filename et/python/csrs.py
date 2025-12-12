#!/usr/bin/env python3
from argparse import ArgumentParser
from sys import stdin, stderr
from tblgen import getRecords
import re

CSRT = {}
for d in getRecords(lambda line: " SysReg" in line):
    name = d["Name"]
    if not name:
        continue
    CSRT[name] = "".join(d["Encoding"]).rjust(12,"0")

CSR = {}
ADD = {}
with open("csrs.h","r") as c:
    for line in c:
        m = re.match(r"CSRDEF\(0x([0-9a-f]+), ([a-z0-9_]+),", line)
        if not m:
            if line.startswith("CSRDEF"):
                print("error", line[:-1])
            continue
        encoding = bin(int(m.group(1),16))[2:].rjust(12,"0")
        name = m.group(2)
        if name not in CSRT:
            ADD[name] = encoding
            continue
        if CSRT[name] != encoding:
            print("bad", name, encoding, CSRT[name])

for key in sorted(ADD):
    encoding = hex(int(ADD[key],2))
    print(f'def : SysReg<"{key}", {encoding}>;')


