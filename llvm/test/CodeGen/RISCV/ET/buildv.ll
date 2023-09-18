; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: nofree norecurse nounwind writeonly
define void @build0(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  %4 = insertelement <8 x i32> <i32 3, i32 5, i32 10, i32 undef, i32 undef, i32 undef, i32 3, i32 10>, i32 %1, i32 3
  %5 = insertelement <8 x i32> %4, i32 %1, i32 4
  %6 = insertelement <8 x i32> %5, i32 %2, i32 5
  store <8 x i32> %6, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @build1(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  %4 = insertelement <8 x i32> <i32 3, i32 4, i32 5, i32 6, i32 undef, i32 8, i32 undef, i32 10>, i32 %1, i32 4
  %5 = insertelement <8 x i32> %4, i32 %1, i32 6
  store <8 x i32> %5, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @build2(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  %4 = insertelement <8 x i32> <i32 6, i32 8, i32 136, i32 12, i32 undef, i32 16, i32 undef, i32 20>, i32 %1, i32 4
  %5 = insertelement <8 x i32> %4, i32 %1, i32 6
  store <8 x i32> %5, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @build3(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  store <8 x i32> <i32 0, i32 2, i32 5, i32 2, i32 0, i32 5, i32 0, i32 0>, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @build4(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  store <8 x i32> <i32 0, i32 2, i32 1, i32 3, i32 0, i32 1, i32 2, i32 1023>, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @build5(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  store <8 x i32> <i32 0, i32 2, i32 1, i32 3, i32 524288, i32 524287, i32 -524288, i32 -524289>, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @build6(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  store <8 x i32> <i32 0, i32 1, i32 2, i32 4, i32 8, i32 16, i32 32, i32 64>, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @build7(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  store <8 x i32> <i32 0, i32 1, i32 2, i32 4, i32 8, i32 9, i32 32, i32 33>, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @build8(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  %4 = insertelement <8 x i32> <i32 3, i32 4, i32 5, i32 6, i32 undef, i32 8, i32 undef, i32 -4>, i32 %1, i32 4
  %5 = insertelement <8 x i32> %4, i32 %1, i32 6
  store <8 x i32> %5, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @build9(<8 x i32>* noalias nocapture sret align 32 %0, i32 signext %1, i32 signext %2) local_unnamed_addr #0 {
  %4 = insertelement <8 x i32> <i32 undef, i32 undef, i32 undef, i32 undef, i32 undef, i32 undef, i32 undef, i32 524288>, i32 %1, i32 0
  %5 = insertelement <8 x i32> %4, i32 %2, i32 1
  %6 = insertelement <8 x i32> %5, i32 %1, i32 2
  %7 = insertelement <8 x i32> %6, i32 %1, i32 3
  %8 = insertelement <8 x i32> %7, i32 %2, i32 4
  %9 = insertelement <8 x i32> %8, i32 %2, i32 5
  %10 = insertelement <8 x i32> %9, i32 %1, i32 6
  store <8 x i32> %10, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

attributes #0 = { nofree norecurse nounwind writeonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }

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
; CHECK: build0:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 3
; CHECK-NEXT: 	mov.m.x	m0, zero, 2
; CHECK-NEXT: 	fbci.pi	ft0, 5
; CHECK-NEXT: 	mov.m.x	m0, zero, 132
; CHECK-NEXT: 	fbci.pi	ft0, 10
; CHECK-NEXT: 	mov.m.x	m0, zero, 24
; CHECK-NEXT: 	fbcx.ps	ft0, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 32
; CHECK-NEXT: 	fbcx.ps	ft0, a2
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: build1:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 3
; CHECK-NEXT: 	mov.m.x	m0, zero, 140
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 160
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
; CHECK-NEXT: 	mov.m.x	m0, zero, 170
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
; CHECK-NEXT: 	mov.m.x	m0, zero, 80
; CHECK-NEXT: 	fbcx.ps	ft0, a1
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: build2:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 6
; CHECK-NEXT: 	mov.m.x	m0, zero, 4
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 128
; CHECK-NEXT: 	mov.m.x	m0, zero, 136
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
; CHECK-NEXT: 	mov.m.x	m0, zero, 160
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 8
; CHECK-NEXT: 	mov.m.x	m0, zero, 174
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 80
; CHECK-NEXT: 	fbcx.ps	ft0, a1
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: build3:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 0
; CHECK-NEXT: 	mov.m.x	m0, zero, 10
; CHECK-NEXT: 	fbci.pi	ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 36
; CHECK-NEXT: 	fbci.pi	ft0, 5
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: build4:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 0
; CHECK-NEXT: 	mov.m.x	m0, zero, 66
; CHECK-NEXT: 	fbci.pi	ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 36
; CHECK-NEXT: 	fbci.pi	ft0, 1
; CHECK-NEXT: 	mov.m.x	m0, zero, 8
; CHECK-NEXT: 	fbci.pi	ft0, 3
; CHECK-NEXT: 	mov.m.x	m0, zero, 128
; CHECK-NEXT: 	fbci.pi	ft0, 1023
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: build5:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 0
; CHECK-NEXT: 	mov.m.x	m0, zero, 10
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 12
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
; CHECK-NEXT: 	mov.m.x	m0, zero, 16
; CHECK-NEXT: 	fbci.pi	ft0, 524288
; CHECK-NEXT: 	mov.m.x	m0, zero, 32
; CHECK-NEXT: 	fbci.pi	ft0, 524287
; CHECK-NEXT: 	mov.m.x	m0, zero, 64
; CHECK-NEXT: 	fbci.pi	ft0, 1048448
; CHECK-NEXT: 	fslli.pi	ft0, ft0, 10
; CHECK-NEXT: 	fslli.pi	ft0, ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 128
; CHECK-NEXT: 	fbci.pi	ft0, 1048447
; CHECK-NEXT: 	fslli.pi	ft0, ft0, 10
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 1023
; CHECK-NEXT: 	fslli.pi	ft0, ft0, 2
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 3
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: build6:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 0
; CHECK-NEXT: 	mov.m.x	m0, zero, 2
; CHECK-NEXT: 	fbci.pi	ft0, 1
; CHECK-NEXT: 	mov.m.x	m0, zero, 4
; CHECK-NEXT: 	fbci.pi	ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 8
; CHECK-NEXT: 	fbci.pi	ft0, 4
; CHECK-NEXT: 	mov.m.x	m0, zero, 16
; CHECK-NEXT: 	fbci.pi	ft0, 8
; CHECK-NEXT: 	mov.m.x	m0, zero, 32
; CHECK-NEXT: 	fbci.pi	ft0, 16
; CHECK-NEXT: 	mov.m.x	m0, zero, 64
; CHECK-NEXT: 	fbci.pi	ft0, 32
; CHECK-NEXT: 	mov.m.x	m0, zero, 128
; CHECK-NEXT: 	fbci.pi	ft0, 64
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: build7:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 0
; CHECK-NEXT: 	mov.m.x	m0, zero, 4
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 8
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
; CHECK-NEXT: 	mov.m.x	m0, zero, 48
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 8
; CHECK-NEXT: 	mov.m.x	m0, zero, 162
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
; CHECK-NEXT: 	mov.m.x	m0, zero, 192
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 32
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: build8:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 3
; CHECK-NEXT: 	mov.m.x	m0, zero, 12
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 32
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
; CHECK-NEXT: 	mov.m.x	m0, zero, 42
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
; CHECK-NEXT: 	mov.m.x	m0, zero, 128
; CHECK-NEXT: 	fbci.pi	ft0, 1048575
; CHECK-NEXT: 	fslli.pi	ft0, ft0, 10
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 1023
; CHECK-NEXT: 	fslli.pi	ft0, ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 80
; CHECK-NEXT: 	fbcx.ps	ft0, a1
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: build9:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft0, 524288
; CHECK-NEXT: 	mov.m.x	m0, zero, 77
; CHECK-NEXT: 	fbcx.ps	ft0, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 50
; CHECK-NEXT: 	fbcx.ps	ft0, a2
; CHECK-NEXT: 	fsq2	ft0, 0(a0)
; CHECK-NEXT: 	ret
