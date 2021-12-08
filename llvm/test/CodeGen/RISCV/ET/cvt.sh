#!/bin/bash
TEST="s$1"
set -ex
cp $1 ${TEST}
sed -i 's/%sext = sext <8 x i1> %cmp to %I*VEC/%r = select <8 x i1> %cmp, %VEC %x, %VEC %y/' ${TEST}
sed -i 's/store %I*VEC %sext, %I*VEC\* %result/store %VEC %r, %VEC* %result/' ${TEST}
sed -i 's/%I*VEC\* %result/%VEC* %result/' ${TEST}
if ./mktest.py ${TEST} >& LOG ; then
    lit.py ${TEST}
    git add ${TEST}
    emacsclient -n ${TEST}
    exit 0
fi
llc -mcpu=et-soc1-min -mabi=lp64f -debug-only=isel < ${TEST} >& ISEL || true
emacsclient -n ISEL


