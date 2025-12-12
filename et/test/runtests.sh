#!/bin/bash

WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
set -x
cd $WORKDIR

export INSTALL_DIR="$( realpath $WORKDIR/../../../install )"

./runtest.py ../../llvm/test/CodeGen/RISCV/ET >RESULTS
if ! cmp RESULTS EXPECTED ; then
    diff RESULTS EXPECTED
    exit 1
fi
rm -f RESULTS
exit 0
