; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"
%VEC = type <8 x i32>

define signext i32 @ext4(%VEC*  %0) {
  %x = load %VEC, %VEC* %0
  %vecext = extractelement %VEC %x, i32 4
  ret i32 %vecext
}

; CHECK:	flq2	ft0, 0(a0)
; CHECK-NEXT:	fmvs.x.ps	a0, ft0, 4

;
; this sext.w is not needed JIRA ESP-351
;
; CHECK-NEXT:	sext.w	a0, a0
