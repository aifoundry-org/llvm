; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>
%IVEC = type <8 x i32>

define void @ogt(%VEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %cmp = fcmp contract ogt %VEC %x, %y
  %r = select <8 x i1> %cmp, %VEC %x, %VEC %y
  store %VEC %r, %VEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fmax.ps	ft0, ft0, ft1
