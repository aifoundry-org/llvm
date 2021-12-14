; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @add(%VEC* %agg.result,
                 %VEC* %0,
        	 %VEC* %1){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %add = add %VEC %y, %x
  store %VEC %add, %VEC* %agg.result
  ret void
}

; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fadd.pi	ft0, ft1, ft0
