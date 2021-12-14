#!/bin/bash
DIR=$(realpath $(dirname $0))
set -ex
cd $DIR
../build/bin/llvm-lit ../clang/test/CodeGen/esperanto ../llvm/test/CodeGen/RISCV
cd python
bash runtests.sh
cd ../test
bash runtests.sh
