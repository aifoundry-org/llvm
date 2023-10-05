; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"


define void @vselect_test_varvec_varvec(<8 x i32>* %sel.result,
                                        <8 x i32>* %0,
        	                            <8 x i32>* %1){
entry:
  %x = load <8 x i32>, <8 x i32>* %0
  %y = load <8 x i32>, <8 x i32>* %1
  %c = icmp eq <8 x i32> %x, %y
  %sel = select <8 x i1> %c, <8 x i32> %x, <8 x i32> %y
  store <8 x i32> %sel, <8 x i32>* %sel.result
  ret void
}

define void @vselect_test_varvec_constvec(<8 x i32>* %sel.result,
                                          <8 x i32>* %0){
entry:
  %x = load <8 x i32>, <8 x i32>* %0
  %c = icmp eq <8 x i32> %x, zeroinitializer
  %sel = select <8 x i1> %c, <8 x i32> %x, <8 x i32> <i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912>
  store <8 x i32> %sel, <8 x i32>* %sel.result
  ret void
}

define void @vselect_test_constvec_varvec(<8 x i32>* %sel.result,
                                          <8 x i32>* %0){
entry:
  %x = load <8 x i32>, <8 x i32>* %0
  %c = icmp eq <8 x i32> %x, zeroinitializer
  %sel = select <8 x i1> %c, <8 x i32> <i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912>, <8 x i32> %x
  store <8 x i32> %sel, <8 x i32>* %sel.result
  ret void
}

define void @vselect_test_constvec_constvec(<8 x i32>* %sel.result,
                                            <8 x i32>* %0){
entry:
  %x = load <8 x i32>, <8 x i32>* %0
  %c = icmp eq <8 x i32> %x, zeroinitializer
  %sel = select <8 x i1> %c, <8 x i32> <i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912, i32 -306674912>, <8 x i32> zeroinitializer
  store <8 x i32> %sel, <8 x i32>* %sel.result
  ret void
}


; CHECK:	vselect_test_varvec_varvec:
; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	flq2	ft1, 0(a2)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	feq.pi	ft2, ft0, ft1
; CHECK-NEXT:	fcmov.ps	ft0, ft2, ft0, ft1
; CHECK-NEXT:	fsq2	ft0, 0(a0)
; CHECK-NEXT:	ret
; CHECK:	vselect_test_varvec_constvec:
; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbci.pi	ft1, 0
; CHECK-NEXT:	lui	a1, 973704
; CHECK-NEXT:	addiw	a1, a1, 800
; CHECK-NEXT:	fbcx.ps	ft2, a1
; CHECK-NEXT:	feq.pi	ft1, ft0, ft1
; CHECK-NEXT:	fcmov.ps	ft0, ft1, ft0, ft2
; CHECK-NEXT:	fsq2	ft0, 0(a0)
; CHECK-NEXT:	ret
; CHECK:	vselect_test_constvec_varvec:
; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbci.pi	ft1, 0
; CHECK-NEXT:	lui	a1, 973704
; CHECK-NEXT:	addiw	a1, a1, 800
; CHECK-NEXT:	fbcx.ps	ft2, a1
; CHECK-NEXT:	feq.pi	ft1, ft0, ft1
; CHECK-NEXT:	fcmov.ps	ft0, ft1, ft2, ft0
; CHECK-NEXT:	fsq2	ft0, 0(a0)
; CHECK-NEXT:	ret
; CHECK:	vselect_test_constvec_constvec:
; CHECK:	flq2	ft0, 0(a1)
; CHECK-NEXT:	mov.m.x	m0, zero, 255
; CHECK-NEXT:	fbci.pi	ft1, 0
; CHECK-NEXT:	lui	a1, 973704
; CHECK-NEXT:	addiw	a1, a1, 800
; CHECK-NEXT:	fbcx.ps	ft2, a1
; CHECK-NEXT:	feq.pi	ft0, ft0, ft1
; CHECK-NEXT:	fcmov.ps	ft0, ft0, ft2, ft1
; CHECK-NEXT:	fsq2	ft0, 0(a0)
; CHECK-NEXT:	ret