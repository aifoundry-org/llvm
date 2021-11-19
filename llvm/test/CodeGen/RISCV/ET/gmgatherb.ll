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
; CHECK-NEXT:	maskand	[[V6:m[0-9]+]], [[V5]], [[V5]]
; CHECK-NEXT:	fgbg.ps	[[V7:f(a|s|t)[0-9]+]], [[V0]]([[V8:(a|s|t)[0-9]+]])
; CHECK-NEXT:	mov.m.x	[[V9:m[0-9]+]], zero, 255
; CHECK-NEXT:	fbci.pi	[[V10:f(a|s|t)[0-9]+]], 0
; CHECK-NEXT:	mov.m.x	[[V11:m[0-9]+]], zero, 170
; CHECK-NEXT:	faddi.pi	[[V12:f(a|s|t)[0-9]+]], [[V10]], 1
; CHECK-NEXT:	mov.m.x	[[V13:m[0-9]+]], zero, 204
; CHECK-NEXT:	faddi.pi	[[V14:f(a|s|t)[0-9]+]], [[V12]], 2
; CHECK-NEXT:	mov.m.x	[[V15:m[0-9]+]], zero, 240
; CHECK-NEXT:	faddi.pi	[[V16:f(a|s|t)[0-9]+]], [[V14]], 4
; CHECK-NEXT:	mov.m.x	[[V17:m[0-9]+]], zero, 255
; CHECK-NEXT:	mov.m.x	[[V18:m[0-9]+]], zero, 255
; CHECK-NEXT:	fscb.ps	[[V7]], [[V16]]([[V19:(a|s|t)[0-9]+]])
