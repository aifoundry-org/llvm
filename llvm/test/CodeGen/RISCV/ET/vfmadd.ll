; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>

define void @fma(%VEC* %agg.result,
                 %VEC* %0,
        	 %VEC* %1,
        	 %VEC* %2){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %z = load %VEC, %VEC* %2
  %mul = fmul contract %VEC %x, %y
  %add = fadd contract %VEC %mul, %z
  store %VEC %add, %VEC* %agg.result
  ret void
}

; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fmadd.ps ft0, ft0, ft1, ft2, dyn
