; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%MASK = type <8 x i1>

declare %VEC @llvm.masked.load.v8i32.p2v8i32(%VEC addrspace(2)*, i32 immarg, %MASK, %VEC)

define void @mload(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1,
		    %VEC addrspace(2)* %2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %r = call %VEC @llvm.masked.load.v8i32.p2v8i32(%VEC addrspace(2)* %2, i32 4, %MASK %m, %VEC undef)
  store %VEC %r, %VEC * %result, align 32
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fltm.pi	m1, ft0, ft1
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
; CHECK-NEXT:	maskand	m0, m1, m1
; CHECK-NEXT:	fgwg.ps	ft0, ft0(a3)
