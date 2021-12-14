; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"
%VEC = type <8 x float>

declare %VEC @llvm.log2.v8f32(%VEC)

define void @fsin(%VEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %log2 = call %VEC @llvm.log2.v8f32(%VEC %x)
  store %VEC %log2, %VEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	flog.ps	ft0, ft0
