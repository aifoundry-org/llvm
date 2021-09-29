; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
source_filename = "build.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128"
target triple = "riscv64-unknown-unknown-elf"

define void @rem(<8 x float>* %result, <8 x float>* %0, float %y) {
entry:
  %x = load <8 x float>, <8 x float>* %0
  %1 = insertelement <8 x float> %x, float 1.000000e+00, i32 4
  %vecins1 = insertelement <8 x float> %1, float %y, i32 3
  store <8 x float> %vecins1, <8 x float>* %result
  ret void
}

; CHECK:	lui	a3, %hi(.LCPI0_0)
; CHECK-NEXT:	flw	ft0, %lo(.LCPI0_0)(a3)
; CHECK-NEXT:	fmv.w.x	ft1, a2
; CHECK-NEXT:	flq2	ft2, 0(a1)
; CHECK-NEXT:	fmv.x.w	a1, ft0
; CHECK-NEXT:	fmv.x.w	a2, ft1
; CHECK-NEXT:	mov.m.x	m0, zero, 8
; CHECK-NEXT:	fbcx.ps	ft2, a2
; CHECK-NEXT:	mov.m.x	m0, zero, 16
; CHECK-NEXT:	fbcx.ps	ft2, a1
