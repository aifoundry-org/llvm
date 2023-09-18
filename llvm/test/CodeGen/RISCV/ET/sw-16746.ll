; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: nounwind
define void @f() local_unnamed_addr #0 {
  %1 = alloca i16, align 2
  %2 = bitcast i16* %1 to i8*
  call void @llvm.lifetime.start.p0i8(i64 2, i8* nonnull %2) #2
  call void asm sideeffect "shg $1, $0", "=*A,r"(i16* nonnull %1, i16 4660) #2, !srcloc !5
  %3 = load i16, i16* %1, align 2, !tbaa !6
  call void asm sideeffect "shg $1, ($0)\0Ashg $1, 0($0)", "r,r"(i16 %3, i16 4660) #2, !srcloc !10
  call void @llvm.lifetime.end.p0i8(i64 2, i8* nonnull %2) #2
  ret void
}

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #1

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #1

attributes #0 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { argmemonly nounwind willreturn }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64f"}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{i32 1, !"SmallDataLimit", i32 0}
!4 = !{!"clang version 11.1.0 (git@gitlab.com:esperantotech/software/esperanto-llvm.git 37c8488b80dc046980aba17ee6219c53832da4f1)"}
!5 = !{i32 299}
!6 = !{!7, !7, i64 0}
!7 = !{!"short", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i32 450, i32 481}
; CHECK: f:
; CHECK: 	addi	sp, sp, -16
; CHECK-NEXT: 	lui	a0, 1
; CHECK-NEXT: 	addiw	a0, a0, 564
; CHECK-NEXT: 	addi	a1, sp, 14
; CHECK: 	shg	a0, (a1)
; CHECK: 	lhu	a1, 14(sp)
; CHECK: 	shg	a0, (a1)
; CHECK-NEXT: 	shg	a0, (a1)
; CHECK: 	addi	sp, sp, 16
; CHECK-NEXT: 	ret
