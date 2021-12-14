#!/bin/bash
WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export INSTALL_DIR="$( realpath $WORKDIR/../../../install )"
set -x

cd $WORKDIR
./runtest.py ../../llvm/test/CodeGen/RISCV/ET > RESULTS
if ! cmp RESULTS EXPECTED ; then
    diff RESULTS EXPECTED
    exit 1
fi
exit 0
