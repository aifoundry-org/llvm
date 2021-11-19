; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%MASK = type <8 x i1>

declare void @llvm.masked.store.v8i32.p2v8i32(%VEC, %VEC addrspace(2)*, i32 immarg, %MASK);

define void @mstore(%VEC addrspace(2)* %result,
                    %VEC* %0,
		    %VEC* %1){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  tail call void @llvm.masked.store.v8i32.p2v8i32(%VEC %x, %VEC addrspace(2)* %result, i32 4, %MASK %m)
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	fltm.pi	[[V5:m[0-9]+]], [[V0]], [[V2]]
; CHECK-NEXT:	fbci.pi	[[V6:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	mov.m.x	[[V7:m[0-9]+]], zero, 170
; CHECK-NEXT:	faddi.pi	[[V8:f(a|s|t)[0-9]+]], [[V6]], 4
; CHECK-NEXT:	mov.m.x	[[V9:m[0-9]+]], zero, 204
; CHECK-NEXT:	faddi.pi	[[V10:f(a|s|t)[0-9]+]], [[V8]], 8
; CHECK-NEXT:	mov.m.x	[[V11:m[0-9]+]], zero, 240
; CHECK-NEXT:	faddi.pi	[[V12:f(a|s|t)[0-9]+]], [[V10]], 16
; CHECK-NEXT:	maskand	[[V13:m[0-9]+]], [[V5]], [[V5]]
; CHECK-NEXT:	fscwg.ps	[[V0]], [[V12]]([[V14:(a|s|t)[0-9]+]])
