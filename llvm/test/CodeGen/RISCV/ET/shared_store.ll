; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: nofree norecurse nounwind writeonly
define void @_Z12shared_storePU3AS1cc(i8 addrspace(1)* nocapture %0, i8 zeroext %1) local_unnamed_addr #0 {
  store i8 %1, i8 addrspace(1)* %0, align 1, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @_Z12shared_storePU3AS1ss(i16 addrspace(1)* nocapture %0, i16 signext %1) local_unnamed_addr #0 {
  store i16 %1, i16 addrspace(1)* %0, align 2, !tbaa !8
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @_Z12shared_storePU3AS1ii(i32 addrspace(1)* nocapture %0, i32 signext %1) local_unnamed_addr #0 {
  store i32 %1, i32 addrspace(1)* %0, align 4, !tbaa !10
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
!7 = !{!"Simple C++ TBAA"}
!8 = !{!9, !9, i64 0}
!9 = !{!"short", !6, i64 0}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !6, i64 0}
; CHECK: _Z12shared_storePU3AS1cc:
; CHECK: 	fmv.w.x	ft0, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	fbcx.ps	ft1, a1
; CHECK-NEXT: 	fscbl.ps	ft1, ft0(a0)
; CHECK-NEXT: 	ret
; CHECK: _Z12shared_storePU3AS1ss:
; CHECK: 	fmv.w.x	ft0, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	fbcx.ps	ft1, a1
; CHECK-NEXT: 	fschl.ps	ft1, ft0(a0)
; CHECK-NEXT: 	ret
; CHECK: _Z12shared_storePU3AS1ii:
; CHECK: 	fmv.w.x	ft0, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	fbcx.ps	ft1, a1
; CHECK-NEXT: 	fscwl.ps	ft1, ft0(a0)
; CHECK-NEXT: 	ret
