; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>
%IVEC = type <8 x i32>

define void @f2si(%IVEC* %result,
                  %VEC* %0){
entry:
  %x = load %VEC, %VEC* %0  
  %y = fptosi %VEC %x to %IVEC
  store %IVEC %y, %IVEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fcvt.pw.ps	ft0, ft0, rtz
