; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

define void @rem(<8 x i32>* %result, <8 x i32>* %0, i32 signext %y) {
  %x = load <8 x i32>, <8 x i32>* %0
  %t = insertelement <8 x i32> %x, i32 1234, i32 4
  %vecins1 = insertelement <8 x i32> %t, i32 %y, i32 3
  store <8 x i32> %vecins1, <8 x i32>* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	mov.m.x	m0, zero, 8
; CHECK-NEXT:	fbcx.ps	ft0, a2
; CHECK-NEXT:	mov.m.x	m0, zero, 16
; CHECK-NEXT:	fbci.pi	ft0, 1234
