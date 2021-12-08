; RUN: llc -mcpu=et-soc1-min -mabi=lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @add(%VEC* %result,
                 %VEC* %0,
        	 %VEC* %1){
  %y = load %VEC, %VEC* %1
  %add = add %VEC %y, <i32 26, i32 26, i32 26, i32 26, i32 26, i32 26, i32 26, i32 26>
  store %VEC %add, %VEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	faddi.pi	ft0, ft0, 26
