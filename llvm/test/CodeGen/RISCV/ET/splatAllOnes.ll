; RUN: llc -mcpu=et-soc1-min -mabi=lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @not(%VEC* %agg.result,
                 %VEC* %0,
        	 %VEC* %1){
entry:
  store %VEC <i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1>, %VEC* %agg.result
  ret void
}

; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbci.pi	ft0, -1
