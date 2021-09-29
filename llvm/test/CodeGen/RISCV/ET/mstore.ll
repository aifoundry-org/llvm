; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%MASK = type <8 x i1>

declare void @llvm.masked.store.v8i32.p0v8i32(%VEC, %VEC *, i32 immarg, %MASK);

define void @mstore(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  tail call void @llvm.masked.store.v8i32.p0v8i32(%VEC %x, %VEC* %result, i32 4, %MASK %m)
  ret void
}
; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fltm.pi	m0, ft0, ft1
; CHECK-NEXT:	fsw.ps	ft0, 0(a0)
