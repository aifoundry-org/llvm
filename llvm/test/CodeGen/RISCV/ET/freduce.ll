; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"
%VEC = type <8 x float>
%IVEC = type <8 x i32>

define float @rreduce(%VEC* %0) {
  %x = load %VEC, %VEC* %0
  %2 = shufflevector %VEC %x, %VEC undef, %IVEC <i32 2, i32 3, i32 undef, i32 undef, i32 6, i32 7, i32 undef, i32 undef>
  %3 = fadd %VEC %x, %2
  %4 = shufflevector %VEC %3, %VEC undef, %IVEC  <i32 1, i32 undef, i32 undef, i32 undef, i32 5, i32 undef, i32 undef, i32 undef>  
  %5 = fadd %VEC %3, %4
  %lo = extractelement %VEC %5, i32 0
  %hi = extractelement %VEC %5, i32 4
  %r = fadd float %lo, %hi
  ret float %r
}
; CHECK:	flq2	ft0, 0(a0)
; CHECK-NEXT:	fswizz.ps	ft1, ft0, 238
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fadd.ps	ft0, ft0, ft1, dyn
; CHECK-NEXT:	fswizz.ps	ft1, ft0, 229
; CHECK-NEXT:	fadd.ps	ft0, ft0, ft1, dyn
; CHECK-NEXT:	fmvz.x.ps	a0, ft0, 4
; CHECK-NEXT:	fmv.w.x	ft1, a0
; CHECK-NEXT:	fadd.s	ft0, ft0, ft1
; CHECK-NEXT:	fmv.x.w	a0, ft0
