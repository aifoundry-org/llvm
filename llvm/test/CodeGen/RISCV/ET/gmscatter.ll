; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%PVEC = type <8 x i32 addrspace(2) *>
%MASK = type <8 x i1>

declare void @llvm.masked.scatter.v8i32.v8p2i32(%VEC, %PVEC , i32 immarg, %MASK)

define void @lmscatter(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1,
		    i32 addrspace(2) *%2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %array = getelementptr inbounds i32, i32 addrspace(2) * %2, %VEC %x
  tail call void @llvm.masked.scatter.v8i32.v8p2i32(%VEC %x, %PVEC %array, i32 4, %MASK %m)
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fltm.pi	m1, ft0, ft1
; CHECK-NEXT:	fslli.pi	ft1, ft0, 2
; CHECK-NEXT:	maskand	m0, m1, m1
; CHECK-NEXT:	fscwg.ps	ft0, ft1(a3)
