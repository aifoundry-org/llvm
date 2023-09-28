; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>

define void @fdiv(%VEC* %agg.result,
                 %VEC* %0,
        	 %VEC* %1){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %add = fdiv %VEC %y, %x
  store %VEC %add, %VEC* %agg.result
  ret void
}

; CHECK:	           flq2    ft0, 0(a1)
; CHECK-NEXT:        flq2    ft1, 0(a2)
; CHECK-NEXT:        mov.m.x m0, zero, 255
; CHECK-NEXT:        frcp.ps ft0, ft0
; CHECK-NEXT:        fmul.ps ft0, ft1, ft0, dyn
; CHECK-NEXT:        fsq2    ft0, 0(a0)
; CHECK-NEXT:        ret