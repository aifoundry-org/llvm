; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: norecurse nounwind readnone
define float @f1(float %0, float %1) local_unnamed_addr #0 {
  %3 = fdiv float %0, %1
  ret float %3
}

; Function Attrs: nofree norecurse nounwind
define void @f2(<8 x float>* noalias nocapture sret align 32 %0, <8 x float>* nocapture readonly %1, <8 x float>* nocapture readonly %2) local_unnamed_addr #1 {
  %4 = load <8 x float>, <8 x float>* %1, align 32, !tbaa !5
  %5 = load <8 x float>, <8 x float>* %2, align 32, !tbaa !5
  %6 = fdiv <8 x float> %4, %5
  store <8 x float> %6, <8 x float>* %0, align 32, !tbaa !5
  ret void
}

attributes #0 = { norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nofree norecurse nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64f"}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{i32 1, !"SmallDataLimit", i32 0}
!4 = !{!"clang version 11.1.0 (git@gitlab.com:esperantotech/software/esperanto-llvm.git 37c8488b80dc046980aba17ee6219c53832da4f1)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"omnipotent char", !7, i64 0}
!7 = !{!"Simple C/C++ TBAA"}
; CHECK: f1:
; CHECK: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	frcp.ps	ft0, fa1
; CHECK-NEXT: 	fmul.ps	fa0, fa0, ft0, dyn
; CHECK: 	ret
; CHECK: f2:
; CHECK: 	flq2	ft0, 0(a2)
; CHECK-NEXT: 	flq2	ft1, 0(a1)
; CHECK-NEXT: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	frcp.ps	ft0, ft0
; CHECK-NEXT: 	fmul.ps	ft0, ft1, ft0, dyn
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
