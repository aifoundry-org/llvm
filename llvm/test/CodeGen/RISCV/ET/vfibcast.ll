; XFAIL: *
;  Jira ESP-343
; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s

target triple = "riscv64-unknown-unknown-elf"

define void @bcast(<8 x float>* %result) {
  store <8 x float> <float 1.000000e+00, float 1.000000e+00, float 1.000000e+00, float 1.000000e+00, float 1.000000e+00, float 1.000000e+00, float 1.000000e+00, float 1.000000e+00>, <8 x float>* %result
  ret void
}

; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbci.ps	ft0, ???
