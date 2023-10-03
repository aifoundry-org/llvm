; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s

target triple = "riscv64-unknown-unknown-elf"

define void @f1(i8* nocapture %0) local_unnamed_addr #0 {
  %2 = bitcast i8* %0 to <1 x i8>*
  store <1 x i8> <i8 48>, <1 x i8>* %2, align 1
  ret void
}
; CHECK:        addi    a1, zero, 48
; CHECK-NEXT:   sb      a1, 0(a0)

define void @f2(i8* nocapture %0) local_unnamed_addr #0 {
  %2 = bitcast i8* %0 to <2 x i8>*
  store <2 x i8> <i8 48, i8 48>, <2 x i8>* %2, align 1
  ret void
}
; CHECK:        addi    a1, zero, 48
; CHECK-NEXT:   sb      a1, 1(a0)
; CHECK-NEXT:   sb      a1, 0(a0)

define void @f4(i8* nocapture %0) local_unnamed_addr #0 {
  %2 = bitcast i8* %0 to <4 x i8>*
  store <4 x i8> <i8 48, i8 48, i8 48, i8 48>, <4 x i8>* %2, align 1
  ret void
}
; CHECK:        sb      a1, 3(a0)
; CHECK-NEXT:   sb      a1, 2(a0)
; CHECK-NEXT:   sb      a1, 1(a0)
; CHECK-NEXT:   sb      a1, 0(a0)

define void @f8(i8* nocapture %0) local_unnamed_addr #0 {
  %2 = bitcast i8* %0 to <8 x i8>*
  store <8 x i8> <i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48>, <8 x i8>* %2, align 1
  ret void
}
; CHECK:        mov.m.x m0, zero, 255
; CHECK-NEXT:   fbci.pi ft0, 48
; CHECK-NEXT:   mov.m.x m0, zero, 255
; CHECK-NEXT:   fbci.pi ft1, 0
; CHECK-NEXT:   mov.m.x m0, zero, 170
; CHECK-NEXT:   faddi.pi        ft1, ft1, 1
; CHECK-NEXT:   mov.m.x m0, zero, 204
; CHECK-NEXT:   faddi.pi        ft1, ft1, 2
; CHECK-NEXT:   mov.m.x m0, zero, 240
; CHECK-NEXT:   faddi.pi        ft1, ft1, 4
; CHECK-NEXT:   mov.m.x m1, zero, 255
; CHECK-NEXT:   mov.m.x m0, zero, 255
; CHECK-NEXT:   fscb.ps ft0, ft1(a0)

define void @f16(i8* nocapture %0) local_unnamed_addr #0 {
  %2 = bitcast i8* %0 to <16 x i8>*
  store <16 x i8> <i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48>, <16 x i8>* %2, align 1
  ret void
}
; CHECK:        mov.m.x m0, zero, 255
; CHECK-NEXT:   fbci.pi ft0, 48
; CHECK-NEXT:   mov.m.x m0, zero, 255
; CHECK-NEXT:   fbcx.ps ft1, zero
; CHECK-NEXT:   mov.m.x m0, zero, 2
; CHECK-NEXT:   fbci.pi ft1, 1
; CHECK-NEXT:   mov.m.x m0, zero, 4
; CHECK-NEXT:   fbci.pi ft1, 2
; CHECK-NEXT:   mov.m.x m0, zero, 8
; CHECK-NEXT:   fbci.pi ft1, 3
; CHECK-NEXT:   mov.m.x m0, zero, 16
; CHECK-NEXT:   fbci.pi ft1, 4
; CHECK-NEXT:   mov.m.x m0, zero, 32
; CHECK-NEXT:   fbci.pi ft1, 5
; CHECK-NEXT:   mov.m.x m0, zero, 64
; CHECK-NEXT:   fbci.pi ft1, 6
; CHECK-NEXT:   mov.m.x m0, zero, 128
; CHECK-NEXT:   fbci.pi ft1, 7
; CHECK-NEXT:   addi    a1, a0, 8
; CHECK-NEXT:   mov.m.x m0, zero, 255
; CHECK-NEXT:   fscb.ps ft0, ft1(a1)
; CHECK-NEXT:   fscb.ps ft0, ft1(a0)