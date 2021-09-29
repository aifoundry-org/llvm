; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @gt(%VEC* %result, %VEC* %0, %VEC* %1, %VEC* %2) {
  %x = load %VEC, <8 x i32>* %0
  %y = load %VEC, <8 x i32>* %1
  %z = load %VEC, <8 x i32>* %2
  %cmp = icmp sgt %VEC %x, %y
  %r = select <8 x i1> %cmp, %VEC %y, %VEC %z
  store %VEC %r, %VEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	flq2	ft2, 0(a3)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fltm.pi	m0, ft1, ft0
; CHECK-NEXT:	fcmovm.ps	ft0, ft1, ft2
