; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: norecurse nounwind readonly
define signext i32 @_Z11shared_loadPU3AS1c(i8 addrspace(1)* nocapture readonly %0) local_unnamed_addr #0 {
  %2 = load i8, i8 addrspace(1)* %0, align 1, !tbaa !5
  %3 = zext i8 %2 to i32
  ret i32 %3
}

; Function Attrs: norecurse nounwind readonly
define signext i32 @_Z11shared_loadPU3AS1s(i16 addrspace(1)* nocapture readonly %0) local_unnamed_addr #0 {
  %2 = load i16, i16 addrspace(1)* %0, align 2, !tbaa !8
  %3 = sext i16 %2 to i32
  ret i32 %3
}

; Function Attrs: norecurse nounwind readonly
define signext i32 @_Z11shared_loadPU3AS1i(i32 addrspace(1)* nocapture readonly %0) local_unnamed_addr #0 {
  %2 = load i32, i32 addrspace(1)* %0, align 4, !tbaa !10
  ret i32 %2
}

; Function Attrs: norecurse nounwind readonly
define signext i32 @_Z11shared_loadPU3AS1h(i8 addrspace(1)* nocapture readonly %0) local_unnamed_addr #0 {
  %2 = load i8, i8 addrspace(1)* %0, align 1, !tbaa !5
  %3 = zext i8 %2 to i32
  ret i32 %3
}

; Function Attrs: norecurse nounwind readonly
define signext i32 @_Z11shared_loadPU3AS1t(i16 addrspace(1)* nocapture readonly %0) local_unnamed_addr #0 {
  %2 = load i16, i16 addrspace(1)* %0, align 2, !tbaa !8
  %3 = zext i16 %2 to i32
  ret i32 %3
}

; Function Attrs: norecurse nounwind readonly
define signext i32 @_Z11shared_loadPU3AS1j(i32 addrspace(1)* nocapture readonly %0) local_unnamed_addr #0 {
  %2 = load i32, i32 addrspace(1)* %0, align 4, !tbaa !10
  ret i32 %2
}

attributes #0 = { norecurse nounwind readonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }

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
; CHECK: _Z11shared_loadPU3AS1c:
; CHECK: 	fmv.w.x	ft0, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	fgbl.ps	ft0, ft0(a0)
; CHECK-NEXT: 	fmvz.x.ps	a0, ft0, 0
; CHECK-NEXT: 	andi	a0, a0, 255
; CHECK-NEXT: 	mov.m.x	m1, zero, 1
; CHECK-NEXT: 	ret
; CHECK: _Z11shared_loadPU3AS1s:
; CHECK: 	fmv.w.x	ft0, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	fghl.ps	ft0, ft0(a0)
; CHECK-NEXT: 	fmvs.x.ps	a0, ft0, 0
; CHECK-NEXT: 	mov.m.x	m1, zero, 1
; CHECK-NEXT: 	ret
; CHECK: _Z11shared_loadPU3AS1i:
; CHECK: 	fmv.w.x	ft0, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	fgwl.ps	ft0, ft0(a0)
; CHECK-NEXT: 	fmvs.x.ps	a0, ft0, 0
; CHECK-NEXT: 	mov.m.x	m1, zero, 1
; CHECK-NEXT: 	ret
; CHECK: _Z11shared_loadPU3AS1h:
; CHECK: 	fmv.w.x	ft0, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	fgbl.ps	ft0, ft0(a0)
; CHECK-NEXT: 	fmvz.x.ps	a0, ft0, 0
; CHECK-NEXT: 	andi	a0, a0, 255
; CHECK-NEXT: 	mov.m.x	m1, zero, 1
; CHECK-NEXT: 	ret
; CHECK: _Z11shared_loadPU3AS1t:
; CHECK: 	fmv.w.x	ft0, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	fghl.ps	ft0, ft0(a0)
; CHECK-NEXT: 	fmvz.x.ps	a0, ft0, 0
; CHECK-NEXT: 	lui	a1, 16
; CHECK-NEXT: 	addiw	a1, a1, -1
; CHECK-NEXT: 	and	a0, a0, a1
; CHECK-NEXT: 	mov.m.x	m1, zero, 1
; CHECK-NEXT: 	ret
; CHECK: _Z11shared_loadPU3AS1j:
; CHECK: 	fmv.w.x	ft0, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	fgwl.ps	ft0, ft0(a0)
; CHECK-NEXT: 	fmvs.x.ps	a0, ft0, 0
; CHECK-NEXT: 	mov.m.x	m1, zero, 1
; CHECK-NEXT: 	ret
