; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: nounwind
define void @f() local_unnamed_addr #0 {
  %1 = tail call i64 asm sideeffect "amoaddg.d $0, $2, ($1)\0Aamoaddg.w $0, $2, ($1)\0Aamoaddl.d $0, $2, ($1)\0Aamoaddl.w $0, $2, ($1)\0Aamoandg.d $0, $2, ($1)\0Aamoandg.w $0, $2, ($1)\0Aamoandl.d $0, $2, ($1)\0Aamoandl.w $0, $2, ($1)\0Aamocmpswapg.d $0, $2, ($1)\0Aamocmpswapg.w $0, $2, ($1)\0Aamocmpswapl.d $0, $2, ($1)\0Aamocmpswapl.w $0, $2, ($1)\0Aamomaxg.d $0, $2, ($1)\0Aamomaxg.w $0, $2, ($1)\0Aamomaxl.d $0, $2, ($1)\0Aamomaxl.w $0, $2, ($1)\0Aamomaxug.d $0, $2, ($1)\0Aamomaxug.w $0, $2, ($1)\0Aamomaxul.d $0, $2, ($1)\0Aamomaxul.w $0, $2, ($1)\0Aamoming.d $0, $2, ($1)\0Aamoming.w $0, $2, ($1)\0Aamominl.d $0, $2, ($1)\0Aamominl.w $0, $2, ($1)\0Aamominug.d $0, $2, ($1)\0Aamominug.w $0, $2, ($1)\0Aamominul.d $0, $2, ($1)\0Aamominul.w $0, $2, ($1)\0Aamoorg.d $0, $2, ($1)\0Aamoorg.w $0, $2, ($1)\0Aamoorl.d $0, $2, ($1)\0Aamoorl.w $0, $2, ($1)\0Aamoswapg.d $0, $2, ($1)\0Aamoswapg.w $0, $2, ($1)\0Aamoswapl.d $0, $2, ($1)\0Aamoswapl.w $0, $2, ($1)\0Aamoxorg.d $0, $2, ($1)\0Aamoxorg.w $0, $2, ($1)\0Aamoxorl.d $0, $2, ($1)\0Aamoxorl.w $0, $2, ($1)\0Aamoaddg.d $0, $2, 0($1)\0Aamoaddg.w $0, $2, 0($1)\0Aamoaddl.d $0, $2, 0($1)\0Aamoaddl.w $0, $2, 0($1)\0Aamoandg.d $0, $2, 0($1)\0Aamoandg.w $0, $2, 0($1)\0Aamoandl.d $0, $2, 0($1)\0Aamoandl.w $0, $2, 0($1)\0Aamocmpswapg.d $0, $2, 0($1)\0Aamocmpswapg.w $0, $2, 0($1)\0Aamocmpswapl.d $0, $2, 0($1)\0Aamocmpswapl.w $0, $2, 0($1)\0Aamomaxg.d $0, $2, 0($1)\0Aamomaxg.w $0, $2, 0($1)\0Aamomaxl.d $0, $2, 0($1)\0Aamomaxl.w $0, $2, 0($1)\0Aamomaxug.d $0, $2, 0($1)\0Aamomaxug.w $0, $2, 0($1)\0Aamomaxul.d $0, $2, 0($1)\0Aamomaxul.w $0, $2, 0($1)\0Aamoming.d $0, $2, 0($1)\0Aamoming.w $0, $2, 0($1)\0Aamominl.d $0, $2, 0($1)\0Aamominl.w $0, $2, 0($1)\0Aamominug.d $0, $2, 0($1)\0Aamominug.w $0, $2, 0($1)\0Aamominul.d $0, $2, 0($1)\0Aamominul.w $0, $2, 0($1)\0Aamoorg.d $0, $2, 0($1)\0Aamoorg.w $0, $2, 0($1)\0Aamoorl.d $0, $2, 0($1)\0Aamoorl.w $0, $2, 0($1)\0Aamoswapg.d $0, $2, 0($1)\0Aamoswapg.w $0, $2, 0($1)\0Aamoswapl.d $0, $2, 0($1)\0Aamoswapl.w $0, $2, 0($1)\0Aamoxorg.d $0, $2, 0($1)\0Aamoxorg.w $0, $2, 0($1)\0Aamoxorl.d $0, $2, 0($1)\0Aamoxorl.w $0, $2, 0($1)\0A", "=r,r,r"(i64 undef, i64 1311768467463790320) #1, !srcloc !5
  ret void
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
!5 = !{i32 363, i32 408, i32 452, i32 496, i32 540, i32 584, i32 628, i32 672, i32 716, i32 764, i32 812, i32 860, i32 908, i32 952, i32 996, i32 1040, i32 1084, i32 1129, i32 1174, i32 1219, i32 1264, i32 1308, i32 1352, i32 1396, i32 1440, i32 1485, i32 1530, i32 1575, i32 1620, i32 1663, i32 1706, i32 1749, i32 1792, i32 1837, i32 1882, i32 1927, i32 1972, i32 2016, i32 2060, i32 2104, i32 2181, i32 2226, i32 2271, i32 2316, i32 2361, i32 2406, i32 2451, i32 2496, i32 2541, i32 2590, i32 2639, i32 2688, i32 2737, i32 2782, i32 2827, i32 2872, i32 2917, i32 2963, i32 3009, i32 3055, i32 3101, i32 3146, i32 3191, i32 3236, i32 3281, i32 3327, i32 3373, i32 3419, i32 3465, i32 3509, i32 3553, i32 3597, i32 3641, i32 3687, i32 3733, i32 3779, i32 3825, i32 3870, i32 3915, i32 3960}
; CHECK: f:
; CHECK: 	lui	a0, 583
; CHECK-NEXT: 	addiw	a0, a0, -1875
; CHECK-NEXT: 	slli	a0, a0, 14
; CHECK-NEXT: 	addi	a0, a0, -947
; CHECK-NEXT: 	slli	a0, a0, 12
; CHECK-NEXT: 	addi	a0, a0, 1511
; CHECK-NEXT: 	slli	a0, a0, 13
; CHECK-NEXT: 	addi	a0, a0, -272
; CHECK: 	amoaddg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoaddg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoaddl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoaddl.w	a0, a0, (a0)
; CHECK-NEXT: 	amoandg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoandg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoandl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoandl.w	a0, a0, (a0)
; CHECK-NEXT: 	amocmpswapg.d	a0, a0, (a0)
; CHECK-NEXT: 	amocmpswapg.w	a0, a0, (a0)
; CHECK-NEXT: 	amocmpswapl.d	a0, a0, (a0)
; CHECK-NEXT: 	amocmpswapl.w	a0, a0, (a0)
; CHECK-NEXT: 	amomaxg.d	a0, a0, (a0)
; CHECK-NEXT: 	amomaxg.w	a0, a0, (a0)
; CHECK-NEXT: 	amomaxl.d	a0, a0, (a0)
; CHECK-NEXT: 	amomaxl.w	a0, a0, (a0)
; CHECK-NEXT: 	amomaxug.d	a0, a0, (a0)
; CHECK-NEXT: 	amomaxug.w	a0, a0, (a0)
; CHECK-NEXT: 	amomaxul.d	a0, a0, (a0)
; CHECK-NEXT: 	amomaxul.w	a0, a0, (a0)
; CHECK-NEXT: 	amoming.d	a0, a0, (a0)
; CHECK-NEXT: 	amoming.w	a0, a0, (a0)
; CHECK-NEXT: 	amominl.d	a0, a0, (a0)
; CHECK-NEXT: 	amominl.w	a0, a0, (a0)
; CHECK-NEXT: 	amominug.d	a0, a0, (a0)
; CHECK-NEXT: 	amominug.w	a0, a0, (a0)
; CHECK-NEXT: 	amominul.d	a0, a0, (a0)
; CHECK-NEXT: 	amominul.w	a0, a0, (a0)
; CHECK-NEXT: 	amoorg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoorg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoorl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoorl.w	a0, a0, (a0)
; CHECK-NEXT: 	amoswapg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoswapg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoswapl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoswapl.w	a0, a0, (a0)
; CHECK-NEXT: 	amoxorg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoxorg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoxorl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoxorl.w	a0, a0, (a0)
; CHECK-NEXT: 	amoaddg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoaddg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoaddl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoaddl.w	a0, a0, (a0)
; CHECK-NEXT: 	amoandg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoandg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoandl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoandl.w	a0, a0, (a0)
; CHECK-NEXT: 	amocmpswapg.d	a0, a0, (a0)
; CHECK-NEXT: 	amocmpswapg.w	a0, a0, (a0)
; CHECK-NEXT: 	amocmpswapl.d	a0, a0, (a0)
; CHECK-NEXT: 	amocmpswapl.w	a0, a0, (a0)
; CHECK-NEXT: 	amomaxg.d	a0, a0, (a0)
; CHECK-NEXT: 	amomaxg.w	a0, a0, (a0)
; CHECK-NEXT: 	amomaxl.d	a0, a0, (a0)
; CHECK-NEXT: 	amomaxl.w	a0, a0, (a0)
; CHECK-NEXT: 	amomaxug.d	a0, a0, (a0)
; CHECK-NEXT: 	amomaxug.w	a0, a0, (a0)
; CHECK-NEXT: 	amomaxul.d	a0, a0, (a0)
; CHECK-NEXT: 	amomaxul.w	a0, a0, (a0)
; CHECK-NEXT: 	amoming.d	a0, a0, (a0)
; CHECK-NEXT: 	amoming.w	a0, a0, (a0)
; CHECK-NEXT: 	amominl.d	a0, a0, (a0)
; CHECK-NEXT: 	amominl.w	a0, a0, (a0)
; CHECK-NEXT: 	amominug.d	a0, a0, (a0)
; CHECK-NEXT: 	amominug.w	a0, a0, (a0)
; CHECK-NEXT: 	amominul.d	a0, a0, (a0)
; CHECK-NEXT: 	amominul.w	a0, a0, (a0)
; CHECK-NEXT: 	amoorg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoorg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoorl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoorl.w	a0, a0, (a0)
; CHECK-NEXT: 	amoswapg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoswapg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoswapl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoswapl.w	a0, a0, (a0)
; CHECK-NEXT: 	amoxorg.d	a0, a0, (a0)
; CHECK-NEXT: 	amoxorg.w	a0, a0, (a0)
; CHECK-NEXT: 	amoxorl.d	a0, a0, (a0)
; CHECK-NEXT: 	amoxorl.w	a0, a0, (a0)
; CHECK: 	ret