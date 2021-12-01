#!/bin/bash
#
# A simple script to exercise the assembler and compiler builtins
#
set -ex
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT
./gen_asm.py > $TMP/test.s
PATH="../../build/bin:$PATH"
TARGET="-target riscv64-unknown-elf -mcpu=et-soc1-min"
clang -c ${TARGET} $TMP/test.s -o $TMP/test.o
./verify.py $TMP/test.o
./gen_ctest.py > $TMP/test.c
clang -c ${TARGET}  $TMP/test.c -o $TMP/test.o
clang -c ${TARGET} -O2  $TMP/test.c -o $TMP/test.o


