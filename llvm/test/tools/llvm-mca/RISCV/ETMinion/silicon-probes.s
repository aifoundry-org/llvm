# RUN: llvm-mca -mtriple=riscv64 -mcpu=et-soc1 -iterations=100 -instruction-tables=none < %s | FileCheck %s
#
# The bodies of the ET-SoC-1 silicon probes (FFmpeg et-audio/full/
# microprofile-probes.c): eight instructions of one shape followed by the
# loop-counter decrement.  The measured cycles per iteration on hart 0 and
# the model's straight-line cycles must be related by the 12-cycle taken
# branch redirect that closes every iteration (bnez itself plus 11 bubbles),
# which llvm-mca does not simulate:
#
#   shape                     silicon   mca   silicon - mca
#   16 nop + addi              29.01    17         12
#   8 independent fmul.s       21.01     9         12
#   8 dependent fmul.s         63.01    56          7  (chain overlaps the redirect: 8*7 = 56, +7)
#   8 independent ld           21.01     9         12
#   8 dependent ld             42.01    32         10  (8*4 = 32, +10)
#   8 not-taken bnez           21.01     9         12
#
# Any change to TXFMA (7), load-use (4), issue width or RetireOOO moves one
# of these totals.

# CHECK-LABEL: [0] Code Region - nops
# CHECK:       Total Cycles:      1701
# LLVM-MCA-BEGIN nops
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
addi a0, a0, -1
# LLVM-MCA-END

# CHECK-LABEL: [1] Code Region - fmul-independent
# CHECK:       Total Cycles:      906
# LLVM-MCA-BEGIN fmul-independent
fmul.s fa0, fa0, fa1
fmul.s fa2, fa2, fa1
fmul.s fa3, fa3, fa1
fmul.s fa4, fa4, fa1
fmul.s fa5, fa5, fa1
fmul.s fa6, fa6, fa1
fmul.s fa7, fa7, fa1
fmul.s fs0, fs0, fa1
addi a0, a0, -1
# LLVM-MCA-END

# CHECK-LABEL: [2] Code Region - fmul-chain
# CHECK:       Total Cycles:      5601
# LLVM-MCA-BEGIN fmul-chain
fmul.s fa0, fa0, fa1
fmul.s fa0, fa0, fa1
fmul.s fa0, fa0, fa1
fmul.s fa0, fa0, fa1
fmul.s fa0, fa0, fa1
fmul.s fa0, fa0, fa1
fmul.s fa0, fa0, fa1
fmul.s fa0, fa0, fa1
addi a0, a0, -1
# LLVM-MCA-END

# CHECK-LABEL: [3] Code Region - ld-independent
# CHECK:       Total Cycles:      903
# LLVM-MCA-BEGIN ld-independent
ld a2, 0(a1)
ld a3, 0(a1)
ld a4, 0(a1)
ld a5, 0(a1)
ld a6, 0(a1)
ld a7, 0(a1)
ld t0, 0(a1)
ld t1, 0(a1)
addi a0, a0, -1
# LLVM-MCA-END

# CHECK-LABEL: [4] Code Region - ld-chain
# CHECK:       Total Cycles:      3201
# LLVM-MCA-BEGIN ld-chain
ld a1, 0(a1)
ld a1, 0(a1)
ld a1, 0(a1)
ld a1, 0(a1)
ld a1, 0(a1)
ld a1, 0(a1)
ld a1, 0(a1)
ld a1, 0(a1)
addi a0, a0, -1
# LLVM-MCA-END

# CHECK-LABEL: [5] Code Region - bnez-not-taken
# CHECK:       Total Cycles:      901
# LLVM-MCA-BEGIN bnez-not-taken
bnez zero, 1f
1:
bnez zero, 2f
2:
bnez zero, 3f
3:
bnez zero, 4f
4:
bnez zero, 5f
5:
bnez zero, 6f
6:
bnez zero, 7f
7:
bnez zero, 8f
8:
addi a0, a0, -1
# LLVM-MCA-END

# A dependent mul chain: MulDiv is not pipelined, 8 cycles for mul.
# CHECK-LABEL: [6] Code Region - mul-chain
# CHECK:       Total Cycles:      6401
# LLVM-MCA-BEGIN mul-chain
mul a1, a1, a2
mul a1, a1, a2
mul a1, a1, a2
mul a1, a1, a2
mul a1, a1, a2
mul a1, a1, a2
mul a1, a1, a2
mul a1, a1, a2
addi a0, a0, -1
# LLVM-MCA-END

# Independent muls are no faster: one request at a time.
# CHECK-LABEL: [7] Code Region - mul-independent
# CHECK:       Total Cycles:      6401
# LLVM-MCA-BEGIN mul-independent
mul a2, a1, a1
mul a3, a1, a1
mul a4, a1, a1
mul a5, a1, a1
mul a6, a1, a1
mul a7, a1, a1
mul t0, a1, a1
mul t1, a1, a1
addi a0, a0, -1
# LLVM-MCA-END
