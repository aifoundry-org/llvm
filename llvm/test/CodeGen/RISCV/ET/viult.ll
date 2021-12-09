; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @ltu(%VEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, <8 x i32>* %0
  %y = load %VEC, <8 x i32>* %1
  %cmp = icmp ult %VEC %x, %y
  %sext = sext <8 x i1> %cmp to %VEC
  store %VEC %sext, %VEC* %result
  ret void
}

; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fltu.pi	ft0, ft0, ft1
; CHECK-NEXT:	fsq2	ft0, 0(a0)
