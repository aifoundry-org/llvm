; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%VECh = type <8 x i16>
%PVECh = type <8 x i16 addrspace(1) *>
%MASK = type <8 x i1>

declare void @llvm.masked.scatter.v8i16.v8p1i16(%VECh, %PVECh , i32 immarg, %MASK)

define void @lmscatterb(%VEC* %result,
                    %VEC* %0,
		    %VEC* %1,
		    i16 addrspace(1) *%2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %t = trunc %VEC %x to %VECh
  %array = getelementptr inbounds i16, i16 addrspace(1) * %2, %VEC %x
  tail call void @llvm.masked.scatter.v8i16.v8p1i16(%VECh %t, %PVECh %array, i32 4, %MASK %m)
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	fltm.pi	[[V5:m[0-9]+]], [[V0]], [[V2]]
; CHECK-NEXT:	fslli.pi	[[V6:f(a|s|t)[0-9]+]], [[V0]], 1
; CHECK-NEXT:	fschl.ps	[[V0]], [[V6]]([[V7:(a|s|t)[0-9]+]])
