; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: noinline nounwind optnone
define i64 @_Z15float_To_Signedf(float %0) #0 {
  %2 = alloca float, align 4
  store float %0, float* %2, align 4
  %3 = load float, float* %2, align 4
  %4 = fptosi float %3 to i64
  ret i64 %4
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z17float_To_Unsignedf(float %0) #0 {
  %2 = alloca float, align 4
  store float %0, float* %2, align 4
  %3 = load float, float* %2, align 4
  %4 = fptoui float %3 to i64
  ret i64 %4
}

; Function Attrs: noinline nounwind optnone
define float @_Z15signed_To_Floatm(i64 %0) #0 {
  %2 = alloca i64, align 8
  store i64 %0, i64* %2, align 8
  %3 = load i64, i64* %2, align 8
  %4 = sitofp i64 %3 to float
  ret float %4
}

; Function Attrs: noinline nounwind optnone
define float @_Z17unsigned_To_Floatm(i64 %0) #0 {
  %2 = alloca i64, align 8
  store i64 %0, i64* %2, align 8
  %3 = load i64, i64* %2, align 8
  %4 = uitofp i64 %3 to float
  ret float %4
}

; Function Attrs: noinline nounwind optnone
define float @_Z24signed_To_Float_Overflowv() #0 {
  %1 = alloca i64, align 8
  store i64 2147483647, i64* %1, align 8
  %2 = load i64, i64* %1, align 8
  %3 = sitofp i64 %2 to float
  ret float %3
}

; Function Attrs: noinline nounwind optnone
define float @_Z25signed_To_Float_Underflowv() #0 {
  %1 = alloca i64, align 8
  store i64 -2147483648, i64* %1, align 8
  %2 = load i64, i64* %1, align 8
  %3 = sitofp i64 %2 to float
  ret float %3
}

; Function Attrs: noinline nounwind optnone
define float @_Z26unsigned_To_Float_Overflowv() #0 {
  %1 = alloca i64, align 8
  store i64 4294967295, i64* %1, align 8
  %2 = load i64, i64* %1, align 8
  %3 = uitofp i64 %2 to float
  ret float %3
}

; Function Attrs: noinline nounwind optnone
define float @_Z27unsigned_To_Float_Underflowv() #0 {
  %1 = alloca i64, align 8
  store i64 0, i64* %1, align 8
  %2 = load i64, i64* %1, align 8
  %3 = uitofp i64 %2 to float
  ret float %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z21lossy_Float_To_Signedv() #0 {
  %1 = alloca float, align 4
  store float 0x419D6F3460000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptosi float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z19naN_float_To_Signedv() #0 {
  %1 = alloca float, align 4
  store float 0x7FF8000000000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptosi float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z19inf_Float_To_Signedv() #0 {
  %1 = alloca float, align 4
  store float 0x7FF0000000000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptosi float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z22negInf_Float_To_Signedv() #0 {
  %1 = alloca float, align 4
  store float 0xFFF0000000000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptosi float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z23rounded_Float_To_Signedv() #0 {
  %1 = alloca float, align 4
  store float 0x405EDD3AA0000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptosi float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z20zero_Float_To_Signedv() #0 {
  %1 = alloca float, align 4
  store float 0.000000e+00, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptosi float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z23lossy_Float_To_Unsignedv() #0 {
  %1 = alloca float, align 4
  store float 0x419D6F3460000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptoui float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z21naN_float_To_Unsignedv() #0 {
  %1 = alloca float, align 4
  store float 0x7FF8000000000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptoui float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z21inf_Float_To_Unsignedv() #0 {
  %1 = alloca float, align 4
  store float 0x7FF0000000000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptoui float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z24negInf_Float_To_Unsignedv() #0 {
  %1 = alloca float, align 4
  store float 0xFFF0000000000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptoui float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z25rounded_Float_To_Unsignedv() #0 {
  %1 = alloca float, align 4
  store float 0x405EDD3AA0000000, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptoui float %2 to i64
  ret i64 %3
}

; Function Attrs: noinline nounwind optnone
define i64 @_Z22zero_Float_To_Unsignedv() #0 {
  %1 = alloca float, align 4
  store float 0.000000e+00, float* %1, align 4
  %2 = load float, float* %1, align 4
  %3 = fptoui float %2 to i64
  ret i64 %3
}

attributes #0 = { noinline nounwind optnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64f"}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{i32 1, !"SmallDataLimit", i32 0}
!4 = !{!"clang version 11.1.0 (git@gitlab.com:esperantotech/software/esperanto-llvm.git 153ef510907a8b3de94af9367b97a6cd20439f78)"}

; CHECK: 	_Z15float_To_Signedf:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	fsw	fa0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.w.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z17float_To_Unsignedf:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	fsw	fa0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.wu.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z15signed_To_Floatm:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	sd	a0, -24(s0)
; CHECK-NEXT: 	ld	a0, -24(s0)
; CHECK-NEXT: 	addi	a1, zero, 1
; CHECK-NEXT: 	neg	a2, a1
; CHECK-NEXT: 	srli	a2, a2, 1
; CHECK-NEXT: 	and	a2, a2, a0
; CHECK-NEXT: 	slli	a1, a1, 63
; CHECK-NEXT: 	and	a0, a0, a1
; CHECK-NEXT: 	srai	a0, a0, 63
; CHECK-NEXT: 	srli	a1, a0, 1
; CHECK-NEXT: 	xor	a1, a1, a2
; CHECK-NEXT: 	srli	a2, a1, 32
; CHECK-NEXT: 	fcvt.s.wu	ft0, a2
; CHECK-NEXT: 	slli	a1, a1, 32
; CHECK-NEXT: 	srli	a1, a1, 32
; CHECK-NEXT: 	fcvt.s.wu	ft1, a1
; CHECK-NEXT: 	lui	a1, 325632
; CHECK-NEXT: 	fmv.w.x	ft2, a1
; CHECK-NEXT: 	fmadd.s	ft0, ft0, ft2, ft1
; CHECK-NEXT: 	fcvt.s.w	ft1, a0
; CHECK-NEXT: 	slli	a0, a0, 1
; CHECK-NEXT: 	addi	a0, a0, 1
; CHECK-NEXT: 	fcvt.s.w	ft2, a0
; CHECK-NEXT: 	fmadd.s	fa0, ft0, ft2, ft1
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z17unsigned_To_Floatm:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	sd	a0, -24(s0)
; CHECK-NEXT: 	ld	a0, -24(s0)
; CHECK-NEXT: 	lui	a1, 325632
; CHECK-NEXT: 	fmv.w.x	ft0, a1
; CHECK-NEXT: 	srli	a1, a0, 32
; CHECK-NEXT: 	fcvt.s.wu	ft1, a1
; CHECK-NEXT: 	slli	a0, a0, 32
; CHECK-NEXT: 	srli	a0, a0, 32
; CHECK-NEXT: 	fcvt.s.wu	ft2, a0
; CHECK-NEXT: 	fmadd.s	fa0, ft1, ft0, ft2
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z24signed_To_Float_Overflowv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 524288
; CHECK-NEXT: 	addiw	a0, a0, -1
; CHECK-NEXT: 	sd	a0, -24(s0)
; CHECK-NEXT: 	ld	a0, -24(s0)
; CHECK-NEXT: 	addi	a1, zero, 1
; CHECK-NEXT: 	neg	a2, a1
; CHECK-NEXT: 	srli	a2, a2, 1
; CHECK-NEXT: 	and	a2, a2, a0
; CHECK-NEXT: 	slli	a1, a1, 63
; CHECK-NEXT: 	and	a0, a0, a1
; CHECK-NEXT: 	srai	a0, a0, 63
; CHECK-NEXT: 	srli	a1, a0, 1
; CHECK-NEXT: 	xor	a1, a1, a2
; CHECK-NEXT: 	srli	a2, a1, 32
; CHECK-NEXT: 	fcvt.s.wu	ft0, a2
; CHECK-NEXT: 	slli	a1, a1, 32
; CHECK-NEXT: 	srli	a1, a1, 32
; CHECK-NEXT: 	fcvt.s.wu	ft1, a1
; CHECK-NEXT: 	lui	a1, 325632
; CHECK-NEXT: 	fmv.w.x	ft2, a1
; CHECK-NEXT: 	fmadd.s	ft0, ft0, ft2, ft1
; CHECK-NEXT: 	fcvt.s.w	ft1, a0
; CHECK-NEXT: 	slli	a0, a0, 1
; CHECK-NEXT: 	addi	a0, a0, 1
; CHECK-NEXT: 	fcvt.s.w	ft2, a0
; CHECK-NEXT: 	fmadd.s	fa0, ft0, ft2, ft1
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z25signed_To_Float_Underflowv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 524288
; CHECK-NEXT: 	sd	a0, -24(s0)
; CHECK-NEXT: 	ld	a0, -24(s0)
; CHECK-NEXT: 	addi	a1, zero, 1
; CHECK-NEXT: 	neg	a2, a1
; CHECK-NEXT: 	srli	a2, a2, 1
; CHECK-NEXT: 	and	a2, a2, a0
; CHECK-NEXT: 	slli	a1, a1, 63
; CHECK-NEXT: 	and	a0, a0, a1
; CHECK-NEXT: 	srai	a0, a0, 63
; CHECK-NEXT: 	srli	a1, a0, 1
; CHECK-NEXT: 	xor	a1, a1, a2
; CHECK-NEXT: 	srli	a2, a1, 32
; CHECK-NEXT: 	fcvt.s.wu	ft0, a2
; CHECK-NEXT: 	slli	a1, a1, 32
; CHECK-NEXT: 	srli	a1, a1, 32
; CHECK-NEXT: 	fcvt.s.wu	ft1, a1
; CHECK-NEXT: 	lui	a1, 325632
; CHECK-NEXT: 	fmv.w.x	ft2, a1
; CHECK-NEXT: 	fmadd.s	ft0, ft0, ft2, ft1
; CHECK-NEXT: 	fcvt.s.w	ft1, a0
; CHECK-NEXT: 	slli	a0, a0, 1
; CHECK-NEXT: 	addi	a0, a0, 1
; CHECK-NEXT: 	fcvt.s.w	ft2, a0
; CHECK-NEXT: 	fmadd.s	fa0, ft0, ft2, ft1
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z26unsigned_To_Float_Overflowv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	addi	a0, zero, 1
; CHECK-NEXT: 	slli	a0, a0, 32
; CHECK-NEXT: 	addi	a0, a0, -1
; CHECK-NEXT: 	sd	a0, -24(s0)
; CHECK-NEXT: 	ld	a0, -24(s0)
; CHECK-NEXT: 	lui	a1, 325632
; CHECK-NEXT: 	fmv.w.x	ft0, a1
; CHECK-NEXT: 	srli	a1, a0, 32
; CHECK-NEXT: 	fcvt.s.wu	ft1, a1
; CHECK-NEXT: 	slli	a0, a0, 32
; CHECK-NEXT: 	srli	a0, a0, 32
; CHECK-NEXT: 	fcvt.s.wu	ft2, a0
; CHECK-NEXT: 	fmadd.s	fa0, ft1, ft0, ft2
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z27unsigned_To_Float_Underflowv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	sd	zero, -24(s0)
; CHECK-NEXT: 	ld	a0, -24(s0)
; CHECK-NEXT: 	lui	a1, 325632
; CHECK-NEXT: 	fmv.w.x	ft0, a1
; CHECK-NEXT: 	srli	a1, a0, 32
; CHECK-NEXT: 	fcvt.s.wu	ft1, a1
; CHECK-NEXT: 	slli	a0, a0, 32
; CHECK-NEXT: 	srli	a0, a0, 32
; CHECK-NEXT: 	fcvt.s.wu	ft2, a0
; CHECK-NEXT: 	fmadd.s	fa0, ft1, ft0, ft2
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z21lossy_Float_To_Signedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 315064
; CHECK-NEXT: 	addiw	a0, a0, -1629
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.w.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z19naN_float_To_Signedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 523264
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.w.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z19inf_Float_To_Signedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 522240
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.w.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z22negInf_Float_To_Signedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	addi	a0, zero, 511
; CHECK-NEXT: 	slli	a0, a0, 23
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.w.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z23rounded_Float_To_Signedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 274287
; CHECK-NEXT: 	addiw	a0, a0, -1579
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.w.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z20zero_Float_To_Signedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	sw	zero, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.w.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z23lossy_Float_To_Unsignedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 315064
; CHECK-NEXT: 	addiw	a0, a0, -1629
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.wu.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z21naN_float_To_Unsignedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 523264
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.wu.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z21inf_Float_To_Unsignedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 522240
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.wu.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z24negInf_Float_To_Unsignedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	addi	a0, zero, 511
; CHECK-NEXT: 	slli	a0, a0, 23
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.wu.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z25rounded_Float_To_Unsignedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	lui	a0, 274287
; CHECK-NEXT: 	addiw	a0, a0, -1579
; CHECK-NEXT: 	sw	a0, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.wu.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret
; CHECK: 	_Z22zero_Float_To_Unsignedv:
; CHECK: 	addi	sp, sp, -32
; CHECK-NEXT: 	sd	ra, 24(sp)
; CHECK-NEXT: 	sd	s0, 16(sp)
; CHECK-NEXT: 	addi	s0, sp, 32
; CHECK-NEXT: 	sw	zero, -20(s0)
; CHECK-NEXT: 	flw	ft0, -20(s0)
; CHECK-NEXT: 	fcvt.wu.s	a0, ft0, rtz
; CHECK-NEXT: 	ld	s0, 16(sp)
; CHECK-NEXT: 	ld	ra, 24(sp)
; CHECK-NEXT: 	addi	sp, sp, 32
; CHECK-NEXT: 	ret