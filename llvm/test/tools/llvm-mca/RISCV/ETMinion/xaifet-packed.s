# RUN: llvm-mca -mtriple=riscv64 -mcpu=et-soc1 -iterations=100 -instruction-tables=none < %s | FileCheck %s
#
# Packed-single shapes from the ET-SoC-1 AAC decoder kernels, in GNU
# spelling.  TXFMA results are 7 cycles away, swizzles 2, loads 4; a
# dependent packed chain runs at one op per 7 cycles, seven independent
# chains keep the unit full.

# One complex butterfly step on 8 lanes, fully dependent:
# ld (4) + mul (7) + swizzle (2) + sub (7) + st (1) = 21 cycles.
# CHECK-LABEL: [0] Code Region - butterfly-dependent
# CHECK:       Total Cycles:      2101
# LLVM-MCA-BEGIN butterfly-dependent
aif.flw.ps ft0, 0(a0)
aif.fmul.ps ft1, ft0, ft2
aif.fswizz.ps ft3, ft1, 177
aif.fsub.ps ft4, ft1, ft3
aif.fsw.ps ft4, 0(a1)
# LLVM-MCA-END

# The same work on four independent lane groups, interleaved by stage: the
# loads and multiplies of group N+1 fill the latency of group N and four
# steps cost 26 cycles instead of 84.
# CHECK-LABEL: [1] Code Region - butterfly-4way
# CHECK:       Total Cycles:      2601
# LLVM-MCA-BEGIN butterfly-4way
aif.flw.ps ft0, 0(a0)
aif.flw.ps ft5, 32(a0)
aif.flw.ps ft6, 64(a0)
aif.flw.ps ft7, 96(a0)
aif.fmul.ps ft1, ft0, ft2
aif.fmul.ps fs0, ft5, ft2
aif.fmul.ps fs1, ft6, ft2
aif.fmul.ps fs2, ft7, ft2
aif.fswizz.ps ft3, ft1, 177
aif.fswizz.ps fs3, fs0, 177
aif.fswizz.ps fs4, fs1, 177
aif.fswizz.ps fs5, fs2, 177
aif.fsub.ps ft4, ft1, ft3
aif.fsub.ps fs6, fs0, fs3
aif.fsub.ps fs7, fs1, fs4
aif.fsub.ps fs8, fs2, fs5
aif.fsw.ps ft4, 0(a1)
aif.fsw.ps fs6, 32(a1)
aif.fsw.ps fs7, 64(a1)
aif.fsw.ps fs8, 96(a1)
# LLVM-MCA-END

# vector_fmul written naively: two loads, one multiply, one store per 8
# lanes.  The groups are independent but the core is in-order, so the store
# waits 7 cycles for its multiply and the next group's loads wait behind the
# store: 13 cycles per group.  This is the case the scheduler must fix by
# hoisting the next group's loads above the store.
# CHECK-LABEL: [2] Code Region - vector-fmul
# CHECK:       Total Cycles:      3901
# LLVM-MCA-BEGIN vector-fmul
aif.flw.ps ft0, 0(a0)
aif.flw.ps ft1, 0(a1)
aif.fmul.ps ft2, ft0, ft1
aif.fsw.ps ft2, 0(a2)
aif.flw.ps ft3, 32(a0)
aif.flw.ps ft4, 32(a1)
aif.fmul.ps ft5, ft3, ft4
aif.fsw.ps ft5, 32(a2)
aif.flw.ps ft6, 64(a0)
aif.flw.ps ft7, 64(a1)
aif.fmul.ps ft8, ft6, ft7
aif.fsw.ps ft8, 64(a2)
# LLVM-MCA-END

# Mask set-up and two independent packed ops: mov.m.x is a 2-cycle SH-SW
# op and the arithmetic issues behind it without waiting.
# CHECK-LABEL: [3] Code Region - masked
# CHECK:       Total Cycles:      307
# LLVM-MCA-BEGIN masked
aif.mov.m.x m0, zero, 0x0f
aif.fmul.ps ft1, ft0, ft2
aif.fadd.ps ft3, ft4, ft5
# LLVM-MCA-END

# PCM check idioms: a dependent chain of packed integer compare/and/or on
# SH-SW, 2 cycles each: 1 + 4 * 2 = 9.
# CHECK-LABEL: [4] Code Region - packed-int
# CHECK:       Total Cycles:      902
# LLVM-MCA-BEGIN packed-int
aif.fand.pi ft1, ft0, ft2
aif.fltu.pi ft3, ft1, ft4
aif.for.pi ft5, ft3, ft6
aif.fmaxu.pi ft7, ft5, ft8
aif.fsub.pi ft9, ft7, ft10
# LLVM-MCA-END
