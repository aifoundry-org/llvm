#!/bin/bash
set -x
./runtest.py ../../llvm/test/CodeGen/RISCV/ET > RESULTS
if ! cmp RESULTS EXPECTED ; then
    diff RESULTS EXPECTED
    exit 1
fi
exit 0
