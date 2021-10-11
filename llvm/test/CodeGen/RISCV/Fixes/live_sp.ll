; RUN: llc -o %t -filetype=obj %s
; ModuleID = 'bad.ll'
source_filename = "20030811-1-4c6a0e.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128"
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: noinline nounwind optnone
declare void @vararg(i32 signext, ...) #0

; Function Attrs: noinline nounwind optnone
define void @test1() #0 {
entry:
  %a = alloca i32, align 4
  %0 = call i8* @llvm.returnaddress(i32 0)
  %1 = ptrtoint i8* %0 to i64
  %conv = trunc i64 %1 to i32
  store i32 %conv, i32* %a, align 4
  %2 = load i32, i32* %a, align 4
  call void (i32, ...) @vararg(i32 signext 0, i32 signext %2)
  ret void
}

; Function Attrs: nounwind readnone
declare i8* @llvm.returnaddress(i32 immarg) #1

attributes #0 = { noinline nounwind optnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64"}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{i32 1, !"SmallDataLimit", i32 0}
!4 = !{!"clang version 11.1.0 (llvm-project.git 46be9858036231ebe43273efbd5ae838bc7181c7)"}
