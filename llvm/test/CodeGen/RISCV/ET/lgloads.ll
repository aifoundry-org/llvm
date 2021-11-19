; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128"
target triple = "riscv64-unknown-unknown-elf"

define void @min(<8 x float>* %result, <8 x float> addrspace(1)* %z, <8 x float> addrspace(2)* %x) {
entry:
  %0 = load <8 x float>, <8 x float> addrspace(1)* %z, align 32
  %1 = load <8 x float>, <8 x float> addrspace(2)* %x, align 32
  %add = fadd <8 x float> %0, %1
  store <8 x float> %add, <8 x float>* %result, align 32
  ret void
}

; CHECK:	mov.m.x	[[V0:m[0-9]+]], zero, 255
; CHECK-NEXT:	fbci.pi	[[V1:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	mov.m.x	[[V2:m[0-9]+]], zero, 170
; CHECK-NEXT:	faddi.pi	[[V3:f(a|s|t)[0-9]+]], [[V1]], 4
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 204
; CHECK-NEXT:	faddi.pi	[[V5:f(a|s|t)[0-9]+]], [[V3]], 8
; CHECK-NEXT:	mov.m.x	[[V6:m[0-9]+]], zero, 240
; CHECK-NEXT:	faddi.pi	[[V7:f(a|s|t)[0-9]+]], [[V5]], 16
; CHECK-NEXT:	mov.m.x	[[V8:m[0-9]+]], zero, 255
; CHECK-NEXT:	fgwl.ps	[[V9:f(a|s|t)[0-9]+]], [[V7]]([[V10:(a|s|t)[0-9]+]])
; CHECK-NEXT:	fgwg.ps	[[V11:f(a|s|t)[0-9]+]], [[V7]]([[V12:(a|s|t)[0-9]+]])
; CHECK-NEXT:	fadd.ps	[[V13:f(a|s|t)[0-9]+]], [[V9]], [[V11]], dyn
; CHECK-NEXT:	fsq2	[[V13]], 0([[V14:(a|s|t)[0-9]+]])
