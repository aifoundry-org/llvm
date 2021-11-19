#!/bin/bash
DIR=$(realpath $(dirname $0))
cd $DIR
../build/bin/llvm-lit ../clang/test/CodeGen/esperanto ../llvm/test/CodeGen/RISCV

