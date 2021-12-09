; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s

target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>

define void @bcast(%VEC* %result, float %i) {
    %vecinit = insertelement %VEC undef, float %i, i32 0
    %vecinit7 = shufflevector %VEC %vecinit, %VEC undef, <8 x i32> zeroinitializer
    store %VEC %vecinit7, %VEC* %result
    ret void
}

; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbcx.ps	ft0, a1
