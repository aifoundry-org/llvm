; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%VECh = type <8 x i16>
%PVECh = type <8 x i16 addrspace(1) *>
%MASK = type <8 x i1>

declare void @llvm.masked.scatter.v8i16.v8p1i16(%VECh, %PVECh , i32 immarg, %MASK)

define void @lmscatterb(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1,
		    i16 addrspace(1) *%2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %t = trunc %VEC %x to %VECh
  %array = getelementptr inbounds i16, i16 addrspace(1) * %2, %VEC %x
  tail call void @llvm.masked.scatter.v8i16.v8p1i16(%VECh %t, %PVECh %array, i32 4, %MASK %m)
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fltm.pi	m1, ft0, ft1
; CHECK-NEXT:	fslli.pi	ft1, ft0, 2
; CHECK-NEXT:	maskand	m0, m1, m1
; CHECK-NEXT:	fschl.ps	ft0, ft1(a3)
