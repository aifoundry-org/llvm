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
export CMAKE_C_COMPILER=`which gcc`
export CMAKE_CXX_COMPILER=`which g++`
cmake -G Ninja  \
      -DLLVM_ENABLE_PROJECTS="clang;compiler-rt" \
      -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
      -DCMAKE_C_COMPILER="${CMAKE_C_COMPILER}" \
      -DCMAKE_CXX_OMPILER="${CMAKE_CXX_COMPILER}" \
      -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS=-DESPERANTO \
      -DLLVM_TARGET_ARCH=host \
      -DLLVM_DEFAULT_TARGET_TRIPLE="riscv64-unknown-elf" \
      -DLLVM_TARGETS_TO_BUILD="X86;RISCV" \
      ../llvm
cmake --build . --target install
