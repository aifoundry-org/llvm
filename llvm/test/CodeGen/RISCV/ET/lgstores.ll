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

; CHECK:	flq2	ft0, 0(a0)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbcx.ps	ft1, zero
; CHECK-NEXT:	mov.m.x	m0, zero, 2
; CHECK-NEXT:	fbci.pi	ft1, 1
; CHECK-NEXT:	mov.m.x	m0, zero, 4
; CHECK-NEXT:	fbci.pi	ft1, 2
; CHECK-NEXT:	mov.m.x	m0, zero, 8
; CHECK-NEXT:	fbci.pi	ft1, 3
; CHECK-NEXT:	mov.m.x	m0, zero, 16
; CHECK-NEXT:	fbci.pi	ft1, 4
; CHECK-NEXT:	mov.m.x	m0, zero, 32
; CHECK-NEXT:	fbci.pi	ft1, 5
; CHECK-NEXT:	mov.m.x	m0, zero, 64
; CHECK-NEXT:	fbci.pi	ft1, 6
; CHECK-NEXT:	mov.m.x	m0, zero, 128
; CHECK-NEXT:	fbci.pi	ft1, 7
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fslli.pi	ft1, ft1, 2
; CHECK-NEXT:	fscwl.ps	ft0, ft1(a1)
; CHECK-NEXT:	fscwg.ps	ft0, ft1(a2)
