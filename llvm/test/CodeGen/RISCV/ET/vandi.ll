; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @and(%VEC* %agg.result,
                 %VEC* %0,
        	 %VEC* %1){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %and = and %VEC %y, <i32 42, i32 42, i32 42, i32 42, i32 42, i32 42, i32 42, i32 42>
  store %VEC %and, %VEC* %agg.result
  ret void
}

; CHECK:	flq2	ft0, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fandi.pi	ft0, ft0, 42
