; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: nounwind
define float @_Z1fv() local_unnamed_addr #0 {
  %1 = tail call float asm sideeffect "fmv.s.x $0, $2\0Afcvt.ps.f16 $0, $0\0A", "=f,M,r"(i32 1, i16 -18432) #1, !srcloc !5
  ret float %1
}

; Function Attrs: nounwind
define float @_Z2f2v() local_unnamed_addr #0 {
  %1 = tail call float asm sideeffect "fmv.s.x $0, $2\0Afcvt.ps.f16 $0, $0\0A", "=f,M,r"(i32 1, i16 -18432) #1, !srcloc !6
  %2 = tail call float asm sideeffect "fmv.s.x $0, $2\0Afcvt.ps.f16 $0, $0\0A", "=f,M,r"(i32 2, i16 -18432) #1, !srcloc !7
  ret float %2
}

; Function Attrs: nounwind
define float @_Z2f3v() local_unnamed_addr #0 {
  %1 = tail call float asm sideeffect "fmv.s.x $0, $2\0Afcvt.ps.f16 $0, $0\0A", "=f,M,r"(i32 1, i16 -18432) #1, !srcloc !8
  %2 = tail call float asm sideeffect "fmv.s.x $0, $2\0Afcvt.ps.f16 $0, $0\0A", "=f,M,r"(i32 1, i16 -18432) #1, !srcloc !9
  ret float %2
}

; Function Attrs: nounwind
define float @_Z2f4i(i32 signext %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 7
  %3 = tail call float asm sideeffect "fmv.s.x $0, $2\0Afcvt.ps.f16 $0, $0\0A", "=f,M,r"(i32 1, i16 -18432) #1, !srcloc !10
  %4 = tail call float asm sideeffect "fmv.s.x $0, $2\0Afcvt.ps.f16 $0, $0\0A", "=f,M,r"(i32 %2, i16 -18432) #1, !srcloc !11
  ret float %4
}

; Function Attrs: nounwind
define float @_Z2f5i(i32 signext %0) local_unnamed_addr #0 {
  %2 = icmp sgt i32 %0, 8
  %3 = select i1 %2, i32 8, i32 1
  %4 = tail call float asm sideeffect "fmv.s.x $0, $2\0Afcvt.ps.f16 $0, $0\0A", "=f,M,r"(i32 1, i16 -18432) #1, !srcloc !12
  %5 = tail call float asm sideeffect "fmv.s.x $0, $2\0Afcvt.ps.f16 $0, $0\0A", "=f,M,r"(i32 %3, i16 -18432) #1, !srcloc !13
  ret float %5
}

attributes #0 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64f"}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{i32 1, !"SmallDataLimit", i32 0}
!4 = !{!"clang version 11.1.0 (git@gitlab.com:esperantotech/software/esperanto-llvm.git 37c8488b80dc046980aba17ee6219c53832da4f1)"}
!5 = !{i32 196, i32 247}
!6 = !{i32 506, i32 557}
!7 = !{i32 738, i32 789}
!8 = !{i32 1049, i32 1100}
!9 = !{i32 1281, i32 1332}
!10 = !{i32 1628, i32 1679}
!11 = !{i32 1860, i32 1911}
!12 = !{i32 2218, i32 2269}
!13 = !{i32 2450, i32 2501}
; CHECK: _Z1fv:
; CHECK: 	lui	a0, 12
; CHECK-NEXT: 	addiw	a0, a0, -2048
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK: 	fmv.w.x	fa0, a0
; CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
; CHECK: 	addi	a0, zero, 1
; CHECK-NEXT: 	ret
; CHECK: _Z2f2v:
; CHECK: 	lui	a0, 12
; CHECK-NEXT: 	addiw	a0, a0, -2048
; CHECK-NEXT: 	addi	a1, zero, 1
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK: 	fmv.w.x	ft0, a0
; CHECK-NEXT: 	fcvt.ps.f16	ft0, ft0
; CHECK: 	mov.m.x	m0, zero, 2
; CHECK: 	fmv.w.x	fa0, a0
; CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
; CHECK: 	addi	a0, zero, 2
; CHECK-NEXT: 	ret
; CHECK: _Z2f3v:
; CHECK: 	lui	a0, 12
; CHECK-NEXT: 	addiw	a0, a0, -2048
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK: 	fmv.w.x	ft0, a0
; CHECK-NEXT: 	fcvt.ps.f16	ft0, ft0
; CHECK: 	fmv.w.x	fa0, a0
; CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
; CHECK: 	addi	a0, zero, 1
; CHECK-NEXT: 	ret
; CHECK: _Z2f4i:
; CHECK: 	lui	a1, 12
; CHECK-NEXT: 	addiw	a1, a1, -2048
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK: 	fmv.w.x	ft0, a1
; CHECK-NEXT: 	fcvt.ps.f16	ft0, ft0
; CHECK: 	andi	a0, a0, 7
; CHECK-NEXT: 	mov.m.x	m0, a0, 0
; CHECK: 	fmv.w.x	fa0, a1
; CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
; CHECK: 	addi	a0, zero, 1
; CHECK-NEXT: 	ret
; CHECK: _Z2f5i:
; CHECK: 	lui	a1, 12
; CHECK-NEXT: 	addiw	a1, a1, -2048
; CHECK-NEXT: 	mov.m.x	m0, zero, 1
; CHECK-NEXT: 	addi	a2, zero, 8
; CHECK: 	fmv.w.x	ft0, a1
; CHECK-NEXT: 	fcvt.ps.f16	ft0, ft0
; CHECK: 	blt	a2, a0, .LBB4_2
; CHECK: 	addi	a2, zero, 1
; CHECK-NEXT: .LBB4_2:
; CHECK-NEXT: 	mov.m.x	m0, a2, 0
; CHECK: 	fmv.w.x	fa0, a1
; CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
; CHECK: 	ret
