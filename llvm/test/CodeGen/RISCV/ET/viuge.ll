; RUN: llc -mcpu=et-soc1-min -mabi=lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @uge(%VEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, <8 x i32>* %0
  %y = load %VEC, <8 x i32>* %1
  %cmp = icmp uge %VEC %x, %y
  %sext = sext <8 x i1> %cmp to %VEC
  store %VEC %sext, %VEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fltu.pi	ft0, ft0, ft1
; CHECK-NEXT:	fnot.pi	ft0, ft0
