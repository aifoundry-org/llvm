; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128"
target triple = "riscv64-unknown-unknown-elf"

define void @stores(<8 x float>* %r, <8 x float> addrspace(1)* %z, <8 x float> addrspace(2)* %x) {
entry:
  %0 = load <8 x float>, <8 x float> * %r, align 32
  store <8 x float> %0, <8 x float> addrspace(1)* %z, align 32
  store <8 x float> %0, <8 x float> addrspace(2)* %x, align 32
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V2:m[0-9]+]], zero, 255
; CHECK-NEXT:	fbci.pi	[[V3:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 170
; CHECK-NEXT:	faddi.pi	[[V5:f(a|s|t)[0-9]+]], [[V3]], 4
; CHECK-NEXT:	mov.m.x	[[V6:m[0-9]+]], zero, 204
; CHECK-NEXT:	faddi.pi	[[V7:f(a|s|t)[0-9]+]], [[V5]], 8
; CHECK-NEXT:	mov.m.x	[[V8:m[0-9]+]], zero, 240
; CHECK-NEXT:	faddi.pi	[[V9:f(a|s|t)[0-9]+]], [[V7]], 16
; CHECK-NEXT:	mov.m.x	[[V10:m[0-9]+]], zero, 255
; CHECK-NEXT:	mov.m.x	[[V11:m[0-9]+]], zero, 255
; CHECK-NEXT:	fscwl.ps	[[V0]], [[V9]]([[V12:(a|s|t)[0-9]+]])
; CHECK-NEXT:	fscwg.ps	[[V0]], [[V9]]([[V13:(a|s|t)[0-9]+]])
