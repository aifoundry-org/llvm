; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>
%IVEC = type <8 x i32>

define void @one(%IVEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %cmp = fcmp one %VEC %x, %y
  %sext = sext <8 x i1> %cmp to %IVEC
  store %IVEC %sext, %IVEC* %result
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	mov.m.x	[[V5:m[0-9]+]], zero, 255
; CHECK-NEXT:	feqm.ps	[[V6:m[0-9]+]], [[V0]], [[V0]]
; CHECK-NEXT:	feqm.ps	[[V7:m[0-9]+]], [[V2]], [[V2]]
; CHECK-NEXT:	maskand	[[V8:m[0-9]+]], [[V7]], [[V6]]
; CHECK-NEXT:	feqm.ps	[[V9:m[0-9]+]], [[V2]], [[V0]]
; CHECK-NEXT:	masknot	[[V10:m[0-9]+]], [[V9]]
; CHECK-NEXT:	maskand	[[V11:m[0-9]+]], [[V10]], [[V8]]
; CHECK-NEXT:	fbci.pi	[[V12:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	maskand	[[V13:m[0-9]+]], [[V11]], [[V11]]
; CHECK-NEXT:	fbci.pi	[[V14:f(a|s|t)[0-9]+]], -1
; CHECK-NEXT:	fsq2	[[V14]], 0([[V15:(a|s|t)[0-9]+]])
