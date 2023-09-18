; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: norecurse nounwind readnone
define float @f1(i64 %0) local_unnamed_addr #0 {
  %2 = uitofp i64 %0 to float
  ret float %2
}

; Function Attrs: norecurse nounwind readnone
define float @f2(i64 %0) local_unnamed_addr #0 {
  %2 = sitofp i64 %0 to float
  ret float %2
}

; Function Attrs: norecurse nounwind readnone
define i64 @f3(float %0) local_unnamed_addr #0 {
  %2 = fptosi float %0 to i64
  ret i64 %2
}

; Function Attrs: norecurse nounwind readnone
define i64 @f4(float %0) local_unnamed_addr #0 {
  %2 = fptoui float %0 to i64
  ret i64 %2
}

attributes #0 = { norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64f"}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{i32 1, !"SmallDataLimit", i32 0}
!4 = !{!"clang version 11.1.0 (git@gitlab.com:esperantotech/software/esperanto-llvm.git 37c8488b80dc046980aba17ee6219c53832da4f1)"}
; CHECK: f1:
; CHECK: 	lui	a1, 325632
; CHECK-NEXT: 	fmv.w.x	ft0, a1
; CHECK-NEXT: 	srli	a1, a0, 32
; CHECK-NEXT: 	fcvt.s.wu	ft1, a1
; CHECK-NEXT: 	slli	a0, a0, 32
; CHECK-NEXT: 	srli	a0, a0, 32
; CHECK-NEXT: 	fcvt.s.wu	ft2, a0
; CHECK-NEXT: 	fmadd.s	fa0, ft1, ft0, ft2
; CHECK-NEXT: 	ret
; CHECK: f2:
; CHECK: 	addi	a1, zero, 1
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
; CHECK-NEXT: 	ret
; CHECK: f3:
; CHECK: 	fcvt.w.s	a0, fa0, rtz
; CHECK-NEXT: 	ret
; CHECK: f4:
; CHECK: 	fcvt.wu.s	a0, fa0, rtz
; CHECK-NEXT: 	ret
