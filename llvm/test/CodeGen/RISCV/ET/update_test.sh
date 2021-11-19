#!/bin/bash
TEST=$1
if [ "$TEST" == "all" ] ; then
    for ll in *.ll ; do
	./update_test.sh $ll
    done
    exit 0
fi
llc -mcpu=et-soc1-min < ${TEST} > temp.s
if  FileCheck ${TEST} < temp.s >& /dev/null ; then
    echo passed
    rm temp.s
    exit 0
fi
ROOT=$(git rev-parse --show-toplevel)
sed -n '/bb.0:/, /\tret/p' temp.s | tail -n +2 | head -n -1 > check.s
$ROOT/../esp-main/c_on_sysemu/tsvc/update_test.py  < check.s > CHECKS
if ! FileCheck CHECKS < temp.s ; then
    echo Update failed
    exit 0
fi

grep -v "; CHECK" $TEST | cat - CHECKS > new
mv new $TEST
rm CHECKS check.s temp.s


