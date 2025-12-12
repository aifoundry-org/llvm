#!/usr/bin/env python3
from argparse import ArgumentParser
from os.path import exists, join
from sys import stderr, stdin
import re

from cmds import do_parse_args, output, command, shell
from et_encodings import getEncodings
from et_names import REGS, ROUNDING_MODES
from tblgen import getRecords

DESCRIPTION="""Validate an object file against expected
machine encodings. From the output of llvm-objdump -d,
we get the actual encoding and the disassemble 
instruction in input form. We map the instruction opcode
to the encoding formation, verify the literal fields and
map the operands to their expected encodints"""

inst_re = re.compile("^ +([0-9a-f]+): ([0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+)\s+(\S+)\t(.*)")

IS_REG = { "rd", "rs1", "rs2", "rs3" }

def main():
    args = parse_args()

    encodings = getEncodings()
    encMap = { e.opcode.lower() : e for e in encodings }

    instructions = {}
    for r in getRecords():
        if "HasEsperanto" not in r.getValue("Predicates"):
            continue
        if r.getValue("Pseudo"):
            continue
        instructions[r.name] = r

    exitCode = 0
    # scan the llvm-objdump looking for 32-bit instructions
    for lineno, line in enumerate(output(
            f"llvm-objdump -d {args.obj} --mcpu=et-soc1-min"), start=1):
        m = inst_re.fullmatch(line)
        if not m:
            continue

        if args.verbose:
            print(lineno, line)
        opcode = m.group(3)
        asm_args = m.group(4)
        # convert the 4 hex bytes little-endian
        # to 32-bits big-endian (when printed)
        bytes =  "".join(reversed(m.group(2).split(" ")))
        bits =  bin(int(bytes,16))[2:].rjust(32,'0')
        def msg(*opts):
            if args.verbose:
                print(lineno, opcode, *opts)
        errors = False;
        def err(*opts):
            global errors, exitCode
            errors = True
            exitCode = 1
            print(lineno, opcode, *opts)
        msg(asm_args, bytes, bits)

        # find the encoding pattern from the CSV files
        e = encMap.get(opcode,None)
        if not e:
            err("unknown encoding")
            continue
        msg("encoding", e)
        # find the specification from the table gen file
        inst = instructions.get(opcode.replace(".","_").upper(),None)
        if not inst:
            err("unkown instruction", opcode)
            continue
        
        # help function to extract a field fran from "bits"
        def field(bits, r):
            "Extract range r from bits"
            h = 31 - r[0]
            l = 32 - r[1]
            b = bits[h:l]
            return b

        s = " ".join([field(bits,f.range()) for f in e.fields])
        msg(s)

        # Pick off certain non-literal fields from
        # the encoded instructions.

        # The order of operands is not the same
        # as the order in which they are encoded
        # so we assume the AsmString in instructions
        # is accurate and references field names
        # in encoded instructions
        operands = inst.getOperandNames()
        msg(operands)

        # map register names to the encoding values
        RegValues = {}
        rm = None
        imm = None
        for reg in asm_operands(asm_args):
            aname = operands.pop(0)
            # offset for memory op...
            if isinstance(reg,int):
                msg("imm", reg, aname)
                imm = reg
                continue
            # Otherwise, this is a named operand
            if reg in REGS:
                msg("reg", reg, REGS[reg], "name", aname)
                RegValues[aname] = REGS[reg]
            elif reg in ROUNDING_MODES:
                rm = ROUNDING_MODES[reg]
            else:
                # note we assume there is only one immediate
                # operand to each instructions
                try:
                    imm = int(reg)
                except BaseException:
                    err("bad arg", reg)

        # a hack for when rs2 is in the rd slot...
        if imm is not None:
            if imm < 0:
                temp = bin(-imm-1)[2:]
                temp = "".join(['1' if c == '0' else '0' for c in temp])
                # print(imm, temp, bin(-imm-1))
                imm = temp.rjust(20, '1')
            # convert to bits
            else:
                imm = bin(imm)[2:].rjust(20,'0')
        msg('rm', rm,'imm',imm,'regs',RegValues)

        # walk the fields in the instruction format and
        # match them against expected values 
        for f in e.fields:
            fbits = field(bits, f.range())
            if f.is_literal():
                if f.name != fbits:
                    err("invalid encoding", f.low, f, "found", fbits)
                continue
            msg(f.name, f.low, fbits)

            v = int(fbits,2)
            if f.name in IS_REG:
                if v != RegValues.get(f.name,None):
                    err("bad reg", f.name, v, RegValues.get(f.name,None))
                continue
            if any([f.name.startswith(p) for p in ["imm","idx"]]):
                if imm is None:
                    err("expected immediate", f)
                    continue
                ibits = buildImmediate(f.name, imm)
                msg("ibits", f.name, ibits)
                if fbits != ibits:
                    err("bad immediate", f, fbits, ibits)
                    continue
                continue
            if f.name == "rm":
                if int(fbits,2) != rm:
                    err("bad rm", fbits, rm)
                continue
            err("unkown field", f, v)

        if args.verbose and not errors:
            print(lineno, opcode, "ok")
            
    exit(exitCode)

imm_re = re.compile(r"^\[([0-9]+)(:([0-9]+))\]")
    
def buildImmediate(name, immbits):
    """Parse an immediate field which is a name folowed by
a list of bit positions in the immediate value"""

    name = name[name.find("["):]
    result = ""
    while name:
        m = imm_re.match(name)
        assert m, "invalid immediate"
        h = int(m.group(1))
        if m.group(2):
            l = int(m.group(3))
        else:
            l = h
        peice = immbits[-h-1:-l] if l else immbits[-h-1:]
        result += peice
        name = name[len(m.group(0)):]
    return result
    

def parse_args():
    parser = ArgumentParser(DESCRIPTION)
    parser.add_argument("obj", help="Object file to be verified")
    return do_parse_args(parser)

def asm_operands(asm_args):
    "Return operands values from assembler string"
    for a in asm_args.split(", "):
        m = re.match(r"(-?[0-9]*)\((.*)\)", a)
        if m:
            if m.group(1) != "":
                imm = int(m.group(1))
                yield imm;
            yield m.group(2)
            continue
        m = re.match(r"([a-z0-9]+)\((.*)\)", a)
        if m:
            yield m.group(1)
            yield m.group(2)
            continue
        yield a

if __name__ == "__main__":
    main()
