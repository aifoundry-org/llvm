#!/bin/bash
BASE="vadd.ll"
OP="$1"
TEST="v${OP}.ll"
set -ex
sed -e "s/add/${OP}/g" < ${BASE} > ${TEST}
if ./mktest.py ${TEST} >& LOG ; then
    lit.py ${TEST}
    git add ${TEST}
    emacsclient -n ${TEST}
    exit 0
fi
llc -mcpu=et-soc1-min -target-abi lp64f -debug-only=isel < ${TEST} >& ISEL || true
emacsclient -n ISEL
exit 0

