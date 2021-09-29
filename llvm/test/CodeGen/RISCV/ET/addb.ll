; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128"
target triple = "riscv64-unknown-unknown-elf"

%E = type i8
%V = type <8 x %E>
%P = type %E addrspace(0) *
%VP = type %V addrspace(0) *
%PV = type <8 x %P>
%MASK = type <8 x i1>


define void @copy(%P %x, %P %y) {
     
   %vx = bitcast %P %x to %VP
   %r  = load %V, %VP %vx
   %a  = add %V %r, <i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1>
   %vy = bitcast %P %y to %VP
   store %V %a, %VP %vy
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
; CHECK-NEXT:	fgb.ps	ft1, ft0(a0)
; CHECK-NEXT:	faddi.pi	ft1, ft1, 1
; CHECK-NEXT:	fscb.ps	ft1, ft0(a1)
