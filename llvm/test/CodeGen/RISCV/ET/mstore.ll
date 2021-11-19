; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%MASK = type <8 x i1>

declare void @llvm.masked.store.v8i32.p0v8i32(%VEC, %VEC *, i32 immarg, %MASK);

define void @mstore(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  tail call void @llvm.masked.store.v8i32.p0v8i32(%VEC %x, %VEC* %result, i32 4, %MASK %m)
  ret void
}
; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	fltm.pi	[[V5:m[0-9]+]], [[V0]], [[V2]]
; CHECK-NEXT:	maskand	[[V6:m[0-9]+]], [[V5]], [[V5]]
; CHECK-NEXT:	fsw.ps	[[V0]], 0([[V7:(a|s|t)[0-9]+]])
