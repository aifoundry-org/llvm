; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: norecurse nounwind readnone
define signext i32 @main(i32 signext %0, i8** nocapture readnone %1) local_unnamed_addr #0 {
  %3 = tail call { <8 x i32>, <8 x i32>, <8 x i32> } asm "fbci.pi $1, $4\0Afbci.pi $2, $5\0Afadd.pi $0, $1, $2\0A", "=f,=f,=f,M,i,i"(i32 255, i32 1, i32 2) #2, !srcloc !5
  %4 = extractvalue { <8 x i32>, <8 x i32>, <8 x i32> } %3, 0
  %5 = extractelement <8 x i32> %4, i32 0
  ret i32 %5
}

; Function Attrs: nounwind readnone
define signext i32 @_Z5main2iPPc(i32 signext %0, i8** nocapture readnone %1) local_unnamed_addr #1 {
  %3 = tail call { <8 x i32>, <8 x i32>, <8 x i32> } asm "fbci.pi $1, $6\0Afbci.pi $2, $7\0Afadd.pi $0, $1, $2\0A", "=f,=f,=f,M,N,N,i,i,~{m3},~{m4},~{m5},~{m6},~{m7}"(i64 255, i64 255, i64 255, i32 1, i32 2) #2, !srcloc !6
  %4 = extractvalue { <8 x i32>, <8 x i32>, <8 x i32> } %3, 0
  %5 = extractelement <8 x i32> %4, i32 0
  ret i32 %5
}

attributes #0 = { norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="256" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="256" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64f"}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{i32 1, !"SmallDataLimit", i32 0}
!4 = !{!"clang version 11.1.0 (git@gitlab.com:esperantotech/software/esperanto-llvm.git 37c8488b80dc046980aba17ee6219c53832da4f1)"}
!5 = !{i32 420, i32 462, i32 503}
!6 = !{i32 1023, i32 1065, i32 1106}
; CHECK: main:
; CHECK: 	mov.m.x	m0, zero, 255
; CHECK: 	fbci.pi	ft1, 1
; CHECK-NEXT: 	fbci.pi	ft2, 2
; CHECK-NEXT: 	fadd.pi	ft0, ft1, ft2
; CHECK: 	fmvs.x.ps	a0, ft0, 0
; CHECK-NEXT: 	sext.w	a0, a0
; CHECK-NEXT: 	addi	a1, zero, 255
; CHECK-NEXT: 	ret
; CHECK: _Z5main2iPPc:
; CHECK: 	addi	a0, zero, 255
; CHECK-NEXT: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	mov.m.x	m1, a0, 0
; CHECK-NEXT: 	mov.m.x	m2, a0, 0
; CHECK: 	fbci.pi	ft1, 1
; CHECK-NEXT: 	fbci.pi	ft2, 2
; CHECK-NEXT: 	fadd.pi	ft0, ft1, ft2
; CHECK: 	fmvs.x.ps	a0, ft0, 0
; CHECK-NEXT: 	sext.w	a0, a0
; CHECK-NEXT: 	ret
