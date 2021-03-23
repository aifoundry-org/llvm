#!/bin/bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" &> /dev/null && pwd )"
cd "$DIR/.."
INSTALL=${INSTALL:-"$(pwd)/install"}
BUILD=${BUILD:-build}
set -e
pwd
mkdir -p ${BUILD}
cd ${BUILD}
cmake -G Ninja  \
      -DLLVM_ENABLE_PROJECTS="clang;compiler-rt" \
      -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
      -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS=-DESPERANTO \
      -DLLVM_TARGET_ARCH=host \
      -DLLVM_DEFAULT_TARGET_TRIPLE="riscv64-unknown-elf" \
      -DLLVM_TARGETS_TO_BUILD="X86;RISCV" \
      ../llvm
cmake --build . --target install
