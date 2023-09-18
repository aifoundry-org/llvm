; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: nounwind readnone
define i64 @_Z9fmov_testlf(i64 %0, float %1) local_unnamed_addr #0 {
  %3 = tail call i64 @llvm.riscv.fmv.x.w(float %1)
  ret i64 %3
}

; Function Attrs: nounwind readnone
declare i64 @llvm.riscv.fmv.x.w(float) #1

attributes #0 = { nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64f"}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{i32 1, !"SmallDataLimit", i32 0}
!4 = !{!"clang version 11.1.0 (git@gitlab.com:esperantotech/software/esperanto-llvm.git 5569c7106bb7c4b56aef6dd5508f6732c7c5fdcc)"}
; CHECK: _Z9fmov_testlf:
; CHECK: 	# %bb.0:
; CHECK-NEXT: 	fmv.x.w	a0, fa0
; CHECK-NEXT: 	ret
