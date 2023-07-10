# RUN: llvm-mc %s  --arch=riscv64 -mcpu=et-soc1-min --riscv-no-aliases --show-encoding | FileCheck %s

fswg.ps f0, (a1)
# CHECK: fswg.ps ft0, (a1)
# CHECK: # encoding: [0x0b,0xf0,0x05,0x52]

fswl.ps f0, (a1)
# CHECK: fswl.ps ft0, (a1)
# CHECK: # encoding: [0x0b,0xf0,0x05,0x50]