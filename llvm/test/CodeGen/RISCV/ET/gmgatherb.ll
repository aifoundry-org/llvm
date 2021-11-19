; RUN: llc -mcpu=et-soc1-min < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>
%VECb = type <8 x i8>
%PVEC = type <8 x i8 addrspace(2) * > 
%MASK = type <8 x i1>

declare %VECb @llvm.masked.gather.v8i8.v8p2i8(%PVEC , i32 immarg, %MASK, %VECb)

define void @gmgatherb(%VECb * %result,
                       %VEC* %0,
		       %VEC* %1,
		       i8 addrspace(2) * %2) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %m = icmp slt %VEC %x, %y
  %array = getelementptr inbounds i8, i8 addrspace(2) * %2, %VEC %x
  %r = call %VECb @llvm.masked.gather.v8i8.v8p2i8(%PVEC %array, i32 4, %MASK %m, %VECb undef)
  store %VECb %r, %VECb * %result, align 32
  ret void
}

; CHECK:	flq2	[[V0:f(a|s|t)[0-9]+]], 0([[V1:(a|s|t)[0-9]+]])
; CHECK-NEXT:	flq2	[[V2:f(a|s|t)[0-9]+]], 0([[V3:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V4:m[0-9]+]], zero, 255
; CHECK-NEXT:	fltm.pi	[[V5:m[0-9]+]], [[V0]], [[V2]]
; CHECK-NEXT:	fgbg.ps	[[V6:f(a|s|t)[0-9]+]], [[V0]]([[V7:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V8:m[0-9]+]], zero, 255
; CHECK-NEXT:	fbci.pi	[[V9:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	mov.m.x	[[V10:m[0-9]+]], zero, 170
; CHECK-NEXT:	faddi.pi	[[V11:f(a|s|t)[0-9]+]], [[V9]], 1
; CHECK-NEXT:	mov.m.x	[[V12:m[0-9]+]], zero, 204
; CHECK-NEXT:	faddi.pi	[[V13:f(a|s|t)[0-9]+]], [[V11]], 2
; CHECK-NEXT:	mov.m.x	[[V14:m[0-9]+]], zero, 240
; CHECK-NEXT:	faddi.pi	[[V15:f(a|s|t)[0-9]+]], [[V13]], 4
; CHECK-NEXT:	mov.m.x	[[V16:m[0-9]+]], zero, 255
; CHECK-NEXT:	fscb.ps	[[V6]], [[V15]]([[V17:(a|s|t)[0-9]+]])
