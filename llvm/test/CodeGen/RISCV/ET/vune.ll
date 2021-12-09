; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>
%IVEC = type <8 x i32>

define void @une(%IVEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %cmp = fcmp une %VEC %x, %y
  %sext = sext <8 x i1> %cmp to %IVEC
  store %IVEC %sext, %IVEC* %result
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	mov.m.x	[[V5:m[0-9]+]], zero, 255
; CHECK-NEXT:	feqm.ps	[[V6:m[0-9]+]], [[V0]], [[V2]]
; CHECK-NEXT:	masknot	[[V7:m[0-9]+]], [[V6]]
; CHECK-NEXT:	fbci.pi	[[V8:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	maskand	[[V9:m[0-9]+]], [[V7]], [[V7]]
; CHECK-NEXT:	fbci.pi	[[V10:f(a|s|t)[0-9]+]], -1
; CHECK-NEXT:	fsq2	[[V10]], 0([[V11:(a|s|t)[0-9]+]])
