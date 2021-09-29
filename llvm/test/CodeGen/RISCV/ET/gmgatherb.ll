; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%VECb = type <8 x i8>
%PVEC = type <8 x i8 addrspace(2) * > 
%MASK = type <8 x i1>

declare %VECb @llvm.masked.gather.v8i8.v8p2i8(%PVEC , i32 immarg, %MASK, %VECb)

define void @gmgatherb(%VECb * %result,
                       %VEC* %0,
		       %VEC* %1,
		       i8 addrspace(2) * %2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %array = getelementptr inbounds i8, i8 addrspace(2) * %2, %VEC %x
  %r = call %VECb @llvm.masked.gather.v8i8.v8p2i8(%PVEC %array, i32 4, %MASK %m, %VECb undef)
  store %VECb %r, %VECb * %result, align 32
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fltm.pi	m1, ft0, ft1
; CHECK-NEXT:	fslli.pi	ft0, ft0, 2
; CHECK-NEXT:	maskand	m0, m1, m1
; CHECK-NEXT:	fgbg.ps	ft0, ft0(a3)
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
; CHECK-NEXT:	fscb.ps	ft0, ft1(a0)
