; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>

define void @fnmadd(%VEC* %result,
                 %VEC* %0,
        	 %VEC* %1,
        	 %VEC* %2){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %z = load %VEC, %VEC* %2
  %mul = fmul contract %VEC %x, %y
  %neg = fneg %VEC %mul
  %sub = fsub contract %VEC %neg, %z
  store %VEC %sub, %VEC* %result
  ret void
}

; fnmadd => (fsub (fneg (fmul x, y)) z)
; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fnmadd.ps ft0, ft0, ft1, ft2, dyn
