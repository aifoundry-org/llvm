; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>
%IVEC = type <8 x i32>

define void @si2f(%VEC* %result,
                  %IVEC* %0){
entry:
  %x = load %IVEC, %IVEC* %0  
  %y = uitofp %IVEC %x to %VEC
  store %VEC %y, %VEC* %result
  ret void
}

; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fcvt.ps.pwu	ft0, ft0, dyn
