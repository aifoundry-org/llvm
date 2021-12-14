; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>
%IVEC = type <8 x i32>

define void @oge(%IVEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %cmp = fcmp oge %VEC %x, %y
  %sext = sext <8 x i1> %cmp to %IVEC
  store %IVEC %sext, %IVEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fle.ps	ft0, ft1, ft0
; CHECK-NEXT:	fsq2	ft0, 0(a0)
