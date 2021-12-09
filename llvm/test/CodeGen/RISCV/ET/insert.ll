; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

define void @rem(<8 x i32>* %result, <8 x i32>* %0, i32 signext %y) {
  %x = load <8 x i32>, <8 x i32>* %0
  %t = insertelement <8 x i32> %x, i32 1234, i32 4
  %vecins1 = insertelement <8 x i32> %t, i32 %y, i32 3
  store <8 x i32> %vecins1, <8 x i32>* %result
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V2:m[0-9]+]], zero, 16
; CHECK-NEXT:	mov.m.x	[[V3:m[0-9]+]], zero, 8
; CHECK-NEXT:	fbcx.ps	[[V4:f(a|s|t)[0-9]+]], [[V5:(a|s|t)[0-9]+]]
; CHECK-NEXT:	mov.m.x	[[V6:m[0-9]+]], zero, 16
; CHECK-NEXT:	fbci.pi	[[V7:f(a|s|t)[0-9]+]], 1234
; CHECK-NEXT:	fsq2	[[V7]], 0([[V8:(a|s|t)[0-9]+]])
