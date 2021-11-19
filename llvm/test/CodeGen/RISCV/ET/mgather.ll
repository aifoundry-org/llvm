; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%PVEC = type <8 x i32 *>
%MASK = type <8 x i1>

declare %VEC @llvm.masked.gather.v8i32.v8p0i32(%PVEC , i32 immarg, %MASK, %VEC)

define void @mload(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1,
		    i32 * %2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %array = getelementptr inbounds i32, i32 * %2, %VEC %x
  %r = call %VEC @llvm.masked.gather.v8i32.v8p0i32(%PVEC %array, i32 4, %MASK %m, %VEC undef)
  store %VEC %r, %VEC * %result, align 32
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	fltm.pi	[[V5:m[0-9]+]], [[V0]], [[V2]]
; CHECK-NEXT:	fslli.pi	[[V6:f(a|s|t)[0-9]+]], [[V0]], 2
; CHECK-NEXT:	maskand	[[V7:m[0-9]+]], [[V5]], [[V5]]
; CHECK-NEXT:	fgw.ps	[[V8:f(a|s|t)[0-9]+]], [[V6]]([[V9:(a|s|t)[0-9]+]])
; CHECK-NEXT:	fsq2	[[V8]], 0([[V10:(a|s|t)[0-9]+]])
