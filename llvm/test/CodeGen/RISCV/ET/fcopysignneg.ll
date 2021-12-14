; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"
%VEC = type <8 x float>

declare %VEC @llvm.copysign.v8f32(%VEC, %VEC)

define void @copysign(%VEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %z = fneg %VEC %y
  %rem = call %VEC @llvm.copysign.v8f32(%VEC %x, %VEC %z)
  store %VEC %rem, %VEC* %result
  ret void
}
; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fsgnjn.ps	ft0, ft0, ft1
