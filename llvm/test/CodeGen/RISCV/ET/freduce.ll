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
; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V2:m[0-9]+]], zero, 255
; CHECK-NEXT:	fswizz.ps	[[V3:f(a|s|t)[0-9]+]], [[V0]], 238
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	fadd.ps	[[V5:f(a|s|t)[0-9]+]], [[V0]], [[V3]], dyn
; CHECK-NEXT:	fswizz.ps	[[V6:f(a|s|t)[0-9]+]], [[V5]], 229
; CHECK-NEXT:	fadd.ps	[[V7:f(a|s|t)[0-9]+]], [[V5]], [[V6]], dyn
; CHECK-NEXT:	fmvz.x.ps	[[V8:(a|s|t)[0-9]+]], [[V7]], 4
; CHECK-NEXT:	fmv.w.x	[[V9:f(a|s|t)[0-9]+]], [[V8]]
; CHECK-NEXT:	fadd.s	[[V10:f(a|s|t)[0-9]+]], [[V7]], [[V9]]
; CHECK-NEXT:	fmv.x.w	[[V11:(a|s|t)[0-9]+]], [[V10]]
