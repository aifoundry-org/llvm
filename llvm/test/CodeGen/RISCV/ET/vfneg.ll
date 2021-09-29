; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>

define void @fadd(%VEC* %result,
                  %VEC* %0){
entry:
  %x = load %VEC, %VEC* %0
  %neg = fneg %VEC %x
  store %VEC %neg, %VEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fsgnjn.ps	ft0, ft0, ft0
