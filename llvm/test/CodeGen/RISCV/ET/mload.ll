; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%MASK = type <8 x i1>

declare %VEC @llvm.masked.load.v8i32.p0v8i32(%VEC *, i32 immarg, %MASK, %VEC)

define void @mload(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1,
		    %VEC* %2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %r = call %VEC @llvm.masked.load.v8i32.p0v8i32(%VEC* %2, i32 4, %MASK %m, %VEC undef)
  store %VEC %r, %VEC * %result, align 32
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fltm.pi	m0, ft0, ft1
; CHECK-NEXT:	flw.ps	ft0, 0(a3)
