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

; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbcx.ps	ft0, zero
; CHECK-NEXT:	mov.m.x	m0, zero, 2
; CHECK-NEXT:	fbci.pi	ft0, 1
; CHECK-NEXT:	mov.m.x	m0, zero, 4
; CHECK-NEXT:	fbci.pi	ft0, 2
; CHECK-NEXT:	mov.m.x	m0, zero, 8
; CHECK-NEXT:	fbci.pi	ft0, 3
; CHECK-NEXT:	mov.m.x	m0, zero, 16
; CHECK-NEXT:	fbci.pi	ft0, 4
; CHECK-NEXT:	mov.m.x	m0, zero, 32
; CHECK-NEXT:	fbci.pi	ft0, 5
; CHECK-NEXT:	mov.m.x	m0, zero, 64
; CHECK-NEXT:	fbci.pi	ft0, 6
; CHECK-NEXT:	mov.m.x	m0, zero, 128
; CHECK-NEXT:	fbci.pi	ft0, 7
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fslli.pi	ft0, ft0, 2
; CHECK-NEXT:	fgwl.ps	ft1, ft0(a1)
; CHECK-NEXT:	fgwg.ps	ft0, ft0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fadd.ps	ft0, ft1, ft0, dyn
