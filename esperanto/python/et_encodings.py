#!/usr/bin/env python3
import csv
import re
from os.path import dirname, realpath

ROOT=dirname(realpath(__file__))
CSV=f"{ROOT}/2018.02.07.RISC-V_Encodings_Instruction_Opcodes.csv"

DESCRIPTION=f"""This reads the 'golden' definition of instruction
encodings from {CSV} and provides methods to access those
encidings as sequences of fields which either it string
literals, parts of immediates, or registernames"""


# Instructions are devided in to three sections
#   RV32I,  RV64I, ET1
# Each instruction has an opcode, a flag indicating
# if it is implemented on the minion, a mode which
# names the section and then the list of fields

class Inst:
    def __init__(self, opcode, minion,  mode, fields):
        self.opcode = opcode
        self.minion = minion
        self.mode = mode
        self.fields = fields
    def __str__ (self):
        return self.opcode + " " + ",".join([str(f) for f in self.fields])


imm_re = re.compile(r"imm\[([0-9]+):([0-9]+)\]")
        
class Field:
    """A field has a name, a low bit position and a bit width.
    For literals, name is a string of 0 and 1 values."""
    def __init__(self, name, low, width):
        self.name = name
        self.low = low
        self.width = width
    def __str__(self):
        return f"{self.name}:{self.width}"
    def is_imm(self):
        return self.name.startswith("imm")
    def range(self):
        return (self.low + self.width - 1, self.low)
        
    def is_literal(self):
        return self.name[0] in "01"
        
def getEncodings():
    "Read and return the target instruction encodings"
    Insts = []
    with open(CSV,"r") as csvfile:
        reader = csv.reader(csvfile)
        reader.__next__()
        reader.__next__()
        reader.__next__()
        for row in reader:
            assert row[0] == ''
            if row[1] == '':
                mode = row[33]
                continue
            Insts.append(Inst(row[33], row[34], mode, buildFields(row[1:33])))
    return Insts
    

def buildFields(raw):
    """Conver the coluns into fields by combining adjacent columns
that are part of the same field"""
    fields = []
    count = 0
    while count < 32:
        assert raw[count] != ''
        name = raw[count]
        width = 1;
        while count+width < 32 and raw[count+width] == '':
            width += 1
        low = 32 - (count+width)
        fields.append(Field(name, low, width))
        count += width
    return fields
        
        
if __name__ == "__main__":
    from argparse import ArgumentParser
    ArgumentParser(DESCRIPTION).parse_args()
    for inst in getEncodings():
        print(inst.opcode, inst.minion, inst.mode,
              " ".join([str(s) for s in inst.fields]))
        for f in inst.fields:
            if f.is_imm():
                h,l = f.range()
                print(f.name,h,l)
