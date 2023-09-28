; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"
%VEC = type <8 x float>

define void @rem(%VEC* %result, %VEC* %0, %VEC* %1) {
  %x = load %VEC, %VEC* %0
  %y = load %VEC, %VEC* %1
  %rem = frem %VEC %x, %y
  store %VEC %rem, %VEC* %result
  ret void
}

; CHECK:        addi    sp, sp, -112
; CHECK-NEXT:        .cfi_def_cfa_offset 112
; CHECK-NEXT:        sd      ra, 104(sp)
; CHECK-NEXT:        sd      s0, 96(sp)
; CHECK-NEXT:        .cfi_offset ra, -8
; CHECK-NEXT:        .cfi_offset s0, -16
; CHECK-NEXT:        flq2    fa0, 0(a1)
; CHECK-NEXT:        fsq2    fa0, 0(sp)
; CHECK-NEXT:        flq2    fa1, 0(a2)
; CHECK-NEXT:        fsq2    fa1, 32(sp)
; CHECK-NEXT:        add     s0, zero, a0
; CHECK-NEXT:                                        # kill: def $f10_f killed $f10_f killed $f10_ps
; CHECK-NEXT:                                        # kill: def $f11_f killed $f11_f killed $f11_ps
; CHECK-NEXT:        call    fmodf
; CHECK-NEXT:        mov.m.x m0, zero, 255
; CHECK-NEXT:        fmv.x.w a0, fa0
; CHECK-NEXT:        fbcx.ps ft0, a0
; CHECK-NEXT:        fsq2    ft0, 64(sp)
; CHECK-NEXT:        flq2    ft0, 0(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 1
; CHECK-NEXT:        fmv.w.x fa0, a0
; CHECK-NEXT:        flq2    ft0, 32(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 1
; CHECK-NEXT:        fmv.w.x fa1, a0
; CHECK-NEXT:        call    fmodf
; CHECK-NEXT:        mov.m.x m0, zero, 2
; CHECK-NEXT:        fmv.x.w a0, fa0
; CHECK-NEXT:        flq2    ft0, 64(sp)
; CHECK-NEXT:        fbcx.ps ft0, a0
; CHECK-NEXT:        fsq2    ft0, 64(sp)
; CHECK-NEXT:        flq2    ft0, 0(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 2
; CHECK-NEXT:        fmv.w.x fa0, a0
; CHECK-NEXT:        flq2    ft0, 32(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 2
; CHECK-NEXT:        fmv.w.x fa1, a0
; CHECK-NEXT:        call    fmodf
; CHECK-NEXT:        mov.m.x m0, zero, 4
; CHECK-NEXT:        fmv.x.w a0, fa0
; CHECK-NEXT:        flq2    ft0, 64(sp)
; CHECK-NEXT:        fbcx.ps ft0, a0
; CHECK-NEXT:        fsq2    ft0, 64(sp)
; CHECK-NEXT:        flq2    ft0, 0(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 3
; CHECK-NEXT:        fmv.w.x fa0, a0
; CHECK-NEXT:        flq2    ft0, 32(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 3
; CHECK-NEXT:        fmv.w.x fa1, a0
; CHECK-NEXT:        call    fmodf
; CHECK-NEXT:        mov.m.x m0, zero, 8
; CHECK-NEXT:        fmv.x.w a0, fa0
; CHECK-NEXT:        flq2    ft0, 64(sp)
; CHECK-NEXT:        fbcx.ps ft0, a0
; CHECK-NEXT:        fsq2    ft0, 64(sp)
; CHECK-NEXT:        flq2    ft0, 0(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 4
; CHECK-NEXT:        fmv.w.x fa0, a0
; CHECK-NEXT:        flq2    ft0, 32(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 4
; CHECK-NEXT:        fmv.w.x fa1, a0
; CHECK-NEXT:        call    fmodf
; CHECK-NEXT:        mov.m.x m0, zero, 16
; CHECK-NEXT:        fmv.x.w a0, fa0
; CHECK-NEXT:        flq2    ft0, 64(sp)
; CHECK-NEXT:        fbcx.ps ft0, a0
; CHECK-NEXT:        fsq2    ft0, 64(sp)
; CHECK-NEXT:        flq2    ft0, 0(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 5
; CHECK-NEXT:        fmv.w.x fa0, a0
; CHECK-NEXT:        flq2    ft0, 32(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 5
; CHECK-NEXT:        fmv.w.x fa1, a0
; CHECK-NEXT:        call    fmodf
; CHECK-NEXT:        mov.m.x m0, zero, 32
; CHECK-NEXT:        fmv.x.w a0, fa0
; CHECK-NEXT:        flq2    ft0, 64(sp)
; CHECK-NEXT:        fbcx.ps ft0, a0
; CHECK-NEXT:        fsq2    ft0, 64(sp)
; CHECK-NEXT:        flq2    ft0, 0(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 6
; CHECK-NEXT:        fmv.w.x fa0, a0
; CHECK-NEXT:        flq2    ft0, 32(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 6
; CHECK-NEXT:        fmv.w.x fa1, a0
; CHECK-NEXT:        call    fmodf
; CHECK-NEXT:        mov.m.x m0, zero, 64
; CHECK-NEXT:        fmv.x.w a0, fa0
; CHECK-NEXT:        flq2    ft0, 64(sp)
; CHECK-NEXT:        fbcx.ps ft0, a0
; CHECK-NEXT:        fsq2    ft0, 64(sp)
; CHECK-NEXT:        flq2    ft0, 0(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 7
; CHECK-NEXT:        fmv.w.x fa0, a0
; CHECK-NEXT:        flq2    ft0, 32(sp)
; CHECK-NEXT:        fmvz.x.ps       a0, ft0, 7
; CHECK-NEXT:        fmv.w.x fa1, a0
; CHECK-NEXT:        call    fmodf
; CHECK-NEXT:        mov.m.x m0, zero, 128
; CHECK-NEXT:        fmv.x.w a0, fa0
; CHECK-NEXT:        flq2    ft0, 64(sp)
; CHECK-NEXT:        fbcx.ps ft0, a0
; CHECK-NEXT:        fsq2    ft0, 0(s0)
; CHECK-NEXT:        ld      s0, 96(sp)
; CHECK-NEXT:        ld      ra, 104(sp)
; CHECK-NEXT:        addi    sp, sp, 112
; CHECK-NEXT:        ret