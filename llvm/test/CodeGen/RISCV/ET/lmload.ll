; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%MASK = type <8 x i1>

declare %VEC @llvm.masked.load.v8i32.p1v8i32(%VEC addrspace(1)*, i32 immarg, %MASK, %VEC)

define void @mload(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1,
		    %VEC addrspace(1)* %2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %r = call %VEC @llvm.masked.load.v8i32.p1v8i32(%VEC addrspace(1)* %2, i32 4, %MASK %m, %VEC undef)
  store %VEC %r, %VEC * %result, align 32
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	fltm.pi	[[V5:m[0-9]+]], [[V0]], [[V2]]
; CHECK-NEXT:	mov.m.x	[[V6:m[0-9]+]], zero, 255
; CHECK-NEXT:	fbci.pi	[[V7:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	mov.m.x	[[V8:m[0-9]+]], zero, 170
; CHECK-NEXT:	faddi.pi	[[V9:f(a|s|t)[0-9]+]], [[V7]], 4
; CHECK-NEXT:	mov.m.x	[[V10:m[0-9]+]], zero, 204
; CHECK-NEXT:	faddi.pi	[[V11:f(a|s|t)[0-9]+]], [[V9]], 8
; CHECK-NEXT:	mov.m.x	[[V12:m[0-9]+]], zero, 240
; CHECK-NEXT:	faddi.pi	[[V13:f(a|s|t)[0-9]+]], [[V11]], 16
; CHECK-NEXT:	maskand	[[V14:m[0-9]+]], [[V5]], [[V5]]
; CHECK-NEXT:	fgwl.ps	[[V15:f(a|s|t)[0-9]+]], [[V13]]([[V16:(a|s|t)[0-9]+]])
; CHECK-NEXT:	fsq2	[[V15]], 0([[V17:(a|s|t)[0-9]+]])
