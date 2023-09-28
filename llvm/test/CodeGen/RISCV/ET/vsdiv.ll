; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

%VEC = type <8 x i32>

define void @sdiv(%VEC* %agg.result,
                 %VEC* %0,
        	 %VEC* %1){
entry:
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %add = sdiv %VEC %y, %x
  store %VEC %add, %VEC* %agg.result
  ret void
}

; CHECK:	        flq2    ft0, 0(a1)
; CHECK-NEXT:        flq2    ft1, 0(a2)
; CHECK-NEXT:        fmvs.x.ps       a1, ft0, 0
; CHECK-NEXT:        fmvs.x.ps       a2, ft1, 0
; CHECK-NEXT:        divw    a1, a2, a1
; CHECK-NEXT:        mov.m.x m0, zero, 255
; CHECK-NEXT:        fbcx.ps ft2, a1
; CHECK-NEXT:        fmvs.x.ps       a1, ft0, 1
; CHECK-NEXT:        fmvs.x.ps       a2, ft1, 1
; CHECK-NEXT:        divw    a1, a2, a1
; CHECK-NEXT:        mov.m.x m0, zero, 2
; CHECK-NEXT:        fbcx.ps ft2, a1
; CHECK-NEXT:        fmvs.x.ps       a1, ft0, 2
; CHECK-NEXT:        fmvs.x.ps       a2, ft1, 2
; CHECK-NEXT:        divw    a1, a2, a1
; CHECK-NEXT:        mov.m.x m0, zero, 4
; CHECK-NEXT:        fbcx.ps ft2, a1
; CHECK-NEXT:        fmvs.x.ps       a1, ft0, 3
; CHECK-NEXT:        fmvs.x.ps       a2, ft1, 3
; CHECK-NEXT:        divw    a1, a2, a1
; CHECK-NEXT:        mov.m.x m0, zero, 8
; CHECK-NEXT:        fbcx.ps ft2, a1
; CHECK-NEXT:        fmvs.x.ps       a1, ft0, 4
; CHECK-NEXT:        fmvs.x.ps       a2, ft1, 4
; CHECK-NEXT:        divw    a1, a2, a1
; CHECK-NEXT:        mov.m.x m0, zero, 16
; CHECK-NEXT:        fbcx.ps ft2, a1
; CHECK-NEXT:        fmvs.x.ps       a1, ft0, 5
; CHECK-NEXT:        fmvs.x.ps       a2, ft1, 5
; CHECK-NEXT:        divw    a1, a2, a1
; CHECK-NEXT:        mov.m.x m0, zero, 32
; CHECK-NEXT:        fbcx.ps ft2, a1
; CHECK-NEXT:        fmvs.x.ps       a1, ft0, 6
; CHECK-NEXT:        fmvs.x.ps       a2, ft1, 6
; CHECK-NEXT:        divw    a1, a2, a1
; CHECK-NEXT:        mov.m.x m0, zero, 64
; CHECK-NEXT:        fbcx.ps ft2, a1
; CHECK-NEXT:        fmvs.x.ps       a1, ft0, 7
; CHECK-NEXT:        fmvs.x.ps       a2, ft1, 7
; CHECK-NEXT:        divw    a1, a2, a1
; CHECK-NEXT:        mov.m.x m0, zero, 128
; CHECK-NEXT:        fbcx.ps ft2, a1
; CHECK-NEXT:        fsq2    ft2, 0(a0)
; CHECK-NEXT:        ret