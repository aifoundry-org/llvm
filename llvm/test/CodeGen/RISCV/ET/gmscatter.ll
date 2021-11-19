; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%PVEC = type <8 x i32 addrspace(2) *>
%MASK = type <8 x i1>

declare void @llvm.masked.scatter.v8i32.v8p2i32(%VEC, %PVEC , i32 immarg, %MASK)

define void @lmscatter(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1,
		    i32 addrspace(2) *%2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %array = getelementptr inbounds i32, i32 addrspace(2) * %2, %VEC %x
  tail call void @llvm.masked.scatter.v8i32.v8p2i32(%VEC %x, %PVEC %array, i32 4, %MASK %m)
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	fltm.pi	[[V5:m[0-9]+]], [[V0]], [[V2]]
; CHECK-NEXT:	fslli.pi	[[V6:f(a|s|t)[0-9]+]], [[V0]], 2
; CHECK-NEXT:	fscwg.ps	[[V0]], [[V6]]([[V7:(a|s|t)[0-9]+]])
