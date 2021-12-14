; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"
%VEC = type <8 x float>

define void @rem(%VEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %rem = frem %VEC %x, %y
  store %VEC %rem, %VEC* %result
  ret void
}
; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fdiv.ps	ft2, ft0, ft1, dyn
; CHECK-NEXT:	fround.ps	ft2, ft2, rtz
; CHECK-NEXT:	fnmsub.ps	ft0, ft2, ft1, ft0, dyn
