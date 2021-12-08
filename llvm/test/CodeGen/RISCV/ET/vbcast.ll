; RUN: llc -mcpu=et-soc1-min -mabi=lp64f < %s | FileCheck %s

target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @bcast(%VEC* %result, i32 %i) {
    %vecinit = insertelement %VEC undef, i32 %i, i32 0
    %vecinit7 = shufflevector %VEC %vecinit, %VEC undef, %VEC zeroinitializer
    store %VEC %vecinit7, %VEC* %result
    ret void
}

; CHECK:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbcx.ps	ft0, a1
