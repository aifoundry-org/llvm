; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%E = type i16
%V = type <8 x %E>
%P = type %E addrspace(0) *
%VP = type %V addrspace(0) *
%PV = type <8 x %P>
%MASK = type <8 x i1>


define void @copy(%P %x, %P %y) {
     
   %vx = bitcast %P %x to %VP
   %r  = load %V, %VP %vx
   %a  = add %V %r, <i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1>
   %vy = bitcast %P %y to %VP
   store %V %a, %VP %vy
   ret void
}


; CHECK:	mov.m.x	[[V0:m[0-9]+]], zero, 255
; CHECK-NEXT:	fbci.pi	[[V1:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	mov.m.x	[[V2:m[0-9]+]], zero, 170
; CHECK-NEXT:	faddi.pi	[[V3:f(a|s|t)[0-9]+]], [[V1]], 2
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 204
; CHECK-NEXT:	faddi.pi	[[V5:f(a|s|t)[0-9]+]], [[V3]], 4
; CHECK-NEXT:	mov.m.x	[[V6:m[0-9]+]], zero, 240
; CHECK-NEXT:	faddi.pi	[[V7:f(a|s|t)[0-9]+]], [[V5]], 8
; CHECK-NEXT:	mov.m.x	[[V8:m[0-9]+]], zero, 255
; CHECK-NEXT:	fgh.ps	[[V9:f(a|s|t)[0-9]+]], [[V7]]([[V10:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V11:m[0-9]+]], zero, 255
; CHECK-NEXT:	faddi.pi	[[V12:f(a|s|t)[0-9]+]], [[V9]], 1
; CHECK-NEXT:	fsch.ps	[[V12]], [[V7]]([[V13:(a|s|t)[0-9]+]])
