; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"
%VEC = type <8 x float>

declare %VEC @llvm.sqrt.v8f32(%VEC)

define void @fsqrt(%VEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %rem = call %VEC @llvm.sqrt.v8f32(%VEC %x)
  store %VEC %rem, %VEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fsqrt.ps	ft0, ft0
