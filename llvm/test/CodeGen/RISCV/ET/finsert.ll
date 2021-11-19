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

; CHECK:	lui	[[V0:(a|s|t)[0-9]+]], %hi(.LCPI0_0)
; CHECK-NEXT:	flw	[[V1:f(a|s|t)[0-9]+]], %lo(.LCPI0_0)([[V0]])
; CHECK-NEXT:	fmv.w.x	[[V2:f(a|s|t)[0-9]+]], [[V3:(a|s|t)[0-9]+]]
; CHECK-NEXT:	flq2	[[V4:f(a|s|t)[0-9]+]], 0([[V5:(a|s|t)[0-9]+]])
; CHECK-NEXT:	fmv.x.w	[[V6:(a|s|t)[0-9]+]], [[V1]]
; CHECK-NEXT:	mov.m.x	[[V7:m[0-9]+]], zero, 16
; CHECK-NEXT:	fmv.x.w	[[V8:(a|s|t)[0-9]+]], [[V2]]
; CHECK-NEXT:	mov.m.x	[[V9:m[0-9]+]], zero, 8
; CHECK-NEXT:	fbcx.ps	[[V10:f(a|s|t)[0-9]+]], [[V8]]
; CHECK-NEXT:	mov.m.x	[[V11:m[0-9]+]], zero, 16
; CHECK-NEXT:	fbcx.ps	[[V12:f(a|s|t)[0-9]+]], [[V6]]
; CHECK-NEXT:	fsq2	[[V12]], 0([[V13:(a|s|t)[0-9]+]])
