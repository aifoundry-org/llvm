; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
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

; CHECK:	mov.m.x	[[V0:m[0-9]+]], zero, 255
; CHECK-NEXT:	fbci.pi	[[V1:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	mov.m.x	m0, zero, 170
; CHECK-NEXT:	faddi.pi	[[V2:f(a|s|t)[0-9]+]], [[V1]], 1
; CHECK-NEXT:	mov.m.x	m0, zero, 204
; CHECK-NEXT:	faddi.pi	[[V3:f(a|s|t)[0-9]+]], [[V2]], 2
; CHECK-NEXT:	mov.m.x	m0, zero, 240
; CHECK-NEXT:	faddi.pi	[[V4:f(a|s|t)[0-9]+]], [[V3]], 4
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fgb.ps	[[V5:f(a|s|t)[0-9]+]], [[V1]]([[V6:(a|s|t)[0-9]+]])
; CHECK-NEXT:	faddi.pi	[[V5]], [[V5]], 1
; CHECK-NEXT:	fscb.ps	[[V5]], [[V1]]([[V7:(a|s|t)[0-9]+]])