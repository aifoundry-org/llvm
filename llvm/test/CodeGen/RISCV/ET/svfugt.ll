; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x float>
%IVEC = type <8 x i32>

define void @ugt(%VEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %cmp = fcmp ugt %VEC %x, %y
  %r = select <8 x i1> %cmp, %VEC %x, %VEC %y
  store %VEC %r, %VEC* %result
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	fltm.ps	[[V5:m[0-9]+]], [[V2]], [[V0]]
; CHECK-NEXT:	feqm.ps	[[V6:m[0-9]+]], [[V2]], [[V2]]
; CHECK-NEXT:	feqm.ps	[[V7:m[0-9]+]], [[V0]], [[V0]]
; CHECK-NEXT:	maskand	[[V8:m[0-9]+]], [[V7]], [[V6]]
; CHECK-NEXT:	masknot	[[V9:m[0-9]+]], [[V8]]
; CHECK-NEXT:	maskor	[[V10:m[0-9]+]], [[V5]], [[V9]]
; CHECK-NEXT:	fcmovm.ps	[[V11:f(a|s|t)[0-9]+]], [[V0]], [[V2]]
; CHECK-NEXT:	fsq2	[[V11]], 0([[V12:(a|s|t)[0-9]+]])
