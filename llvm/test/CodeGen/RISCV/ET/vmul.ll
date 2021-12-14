; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @mul(%VEC* %agg.result,
                 %VEC* %0,
        	 %VEC* %1){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %mul = mul %VEC %y, %x
  store %VEC %mul, %VEC* %agg.result
  ret void
}

; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fmul.pi	ft0, ft1, ft0
