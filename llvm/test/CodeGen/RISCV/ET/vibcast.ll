; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s

target triple = "riscv64-unknown-unknown-elf"

define void @bcast(<8 x i32>* %result) {
  store <8 x i32> <i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1>, <8 x i32>* %result
  ret void
}


; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbci.pi	ft0, 1
