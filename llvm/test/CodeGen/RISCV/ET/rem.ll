; RUN: llc -mcpu=et-soc1-min -target-abi lp64f < %s | FileCheck %s
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: norecurse nounwind readnone
define signext i32 @f1(i32 signext %0, i32 signext %1) local_unnamed_addr #0 {
  %3 = urem i32 %0, %1
  ret i32 %3
}

; Function Attrs: nofree norecurse nounwind
define void @f2(<8 x i32>* noalias nocapture sret align 32 %0, <8 x i32>* nocapture readonly %1, <8 x i32>* nocapture readonly %2) local_unnamed_addr #1 {
  %4 = load <8 x i32>, <8 x i32>* %1, align 32, !tbaa !5
  %5 = load <8 x i32>, <8 x i32>* %2, align 32, !tbaa !5
  %6 = urem <8 x i32> %4, %5
  store <8 x i32> %6, <8 x i32>* %0, align 32, !tbaa !5
  ret void
}

; Function Attrs: norecurse nounwind readnone
define zeroext i8 @f3(i32 signext %0) local_unnamed_addr #0 {
  %2 = srem i32 %0, 10
  %3 = trunc i32 %2 to i8
  %4 = add nsw i8 %3, 48
  ret i8 %4
}

; Function Attrs: nofree norecurse nounwind writeonly
define void @createString(i32 signext %0, i8* nocapture %1) local_unnamed_addr #2 {
  %3 = icmp slt i32 %0, 2047
  %4 = select i1 %3, i32 %0, i32 2047
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %29

6:                                                ; preds = %2
  %7 = icmp sgt i32 %4, 1
  %8 = select i1 %7, i32 %4, i32 1
  %9 = icmp ult i32 %8, 8
  br i1 %9, label %26, label %10

10:                                               ; preds = %6
  %11 = and i32 %8, 2147483640
  br label %12

12:                                               ; preds = %12, %10
  %13 = phi i32 [ 0, %10 ], [ %21, %12 ]
  %14 = phi <8 x i32> [ <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>, %10 ], [ %22, %12 ]
  %15 = urem <8 x i32> %14, <i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10>
  %16 = trunc <8 x i32> %15 to <8 x i8>
  %17 = or <8 x i8> %16, <i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48, i8 48>
  %18 = zext i32 %13 to i64
  %19 = getelementptr inbounds i8, i8* %1, i64 %18
  %20 = bitcast i8* %19 to <8 x i8>*
  store <8 x i8> %17, <8 x i8>* %20, align 1, !tbaa !5
  %21 = add i32 %13, 8
  %22 = add <8 x i32> %14, <i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8>
  %23 = icmp eq i32 %21, %11
  br i1 %23, label %24, label %12, !llvm.loop !8

24:                                               ; preds = %12
  %25 = icmp eq i32 %8, %11
  br i1 %25, label %29, label %26

26:                                               ; preds = %24, %6
  %27 = phi i32 [ %11, %24 ], [ 0, %6 ]
  %28 = zext i32 %27 to i64
  br label %32

29:                                               ; preds = %32, %24, %2
  %30 = sext i32 %4 to i64
  %31 = getelementptr inbounds i8, i8* %1, i64 %30
  store i8 0, i8* %31, align 1, !tbaa !5
  ret void

32:                                               ; preds = %26, %32
  %33 = phi i64 [ %28, %26 ], [ %39, %32 ]
  %34 = trunc i64 %33 to i32
  %35 = urem i32 %34, 10
  %36 = trunc i32 %35 to i8
  %37 = or i8 %36, 48
  %38 = getelementptr inbounds i8, i8* %1, i64 %33
  store i8 %37, i8* %38, align 1, !tbaa !5
  %39 = add nuw nsw i64 %33, 1
  %40 = trunc i64 %39 to i32
  %41 = icmp sgt i32 %4, %40
  br i1 %41, label %32, label %29, !llvm.loop !10
}

attributes #0 = { norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nofree norecurse nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nofree norecurse nounwind writeonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="et-soc1-min" "target-features"="+64bit,+c,+f,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }

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
!8 = distinct !{!8, !9}
!9 = !{!"llvm.loop.isvectorized", i32 1}
!10 = distinct !{!10, !11, !9}
!11 = !{!"llvm.loop.unroll.runtime.disable"}
; CHECK: f1:
; CHECK: 	remuw	a0, a0, a1
; CHECK-NEXT: 	ret
; CHECK: f2:
; CHECK: 	flq2	ft0, 0(a2)
; CHECK-NEXT: 	flq2	ft1, 0(a1)
; CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 0
; CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 0
; CHECK-NEXT: 	remuw	a1, a2, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbcx.ps	ft2, a1
; CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 1
; CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 1
; CHECK-NEXT: 	remuw	a1, a2, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 2
; CHECK-NEXT: 	fbcx.ps	ft2, a1
; CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 2
; CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 2
; CHECK-NEXT: 	remuw	a1, a2, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 4
; CHECK-NEXT: 	fbcx.ps	ft2, a1
; CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 3
; CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 3
; CHECK-NEXT: 	remuw	a1, a2, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 8
; CHECK-NEXT: 	fbcx.ps	ft2, a1
; CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 4
; CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 4
; CHECK-NEXT: 	remuw	a1, a2, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 16
; CHECK-NEXT: 	fbcx.ps	ft2, a1
; CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 5
; CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 5
; CHECK-NEXT: 	remuw	a1, a2, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 32
; CHECK-NEXT: 	fbcx.ps	ft2, a1
; CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 6
; CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 6
; CHECK-NEXT: 	remuw	a1, a2, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 64
; CHECK-NEXT: 	fbcx.ps	ft2, a1
; CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 7
; CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 7
; CHECK-NEXT: 	remuw	a1, a2, a1
; CHECK-NEXT: 	mov.m.x	m0, zero, 128
; CHECK-NEXT: 	fbcx.ps	ft2, a1
; CHECK-NEXT: 	fsq2	ft2, 0(a0)
; CHECK-NEXT: 	ret
; CHECK: f3:
; CHECK: 	lui	a1, 13107
; CHECK-NEXT: 	addiw	a1, a1, 819
; CHECK-NEXT: 	slli	a1, a1, 12
; CHECK-NEXT: 	addi	a1, a1, 819
; CHECK-NEXT: 	slli	a1, a1, 12
; CHECK-NEXT: 	addi	a1, a1, 819
; CHECK-NEXT: 	slli	a1, a1, 13
; CHECK-NEXT: 	addi	a1, a1, 1639
; CHECK-NEXT: 	mulh	a1, a0, a1
; CHECK-NEXT: 	srli	a2, a1, 63
; CHECK-NEXT: 	srli	a1, a1, 2
; CHECK-NEXT: 	add	a1, a1, a2
; CHECK-NEXT: 	addi	a2, zero, 10
; CHECK-NEXT: 	mul	a1, a1, a2
; CHECK-NEXT: 	sub	a0, a0, a1
; CHECK-NEXT: 	addi	a0, a0, 48
; CHECK-NEXT: 	andi	a0, a0, 255
; CHECK-NEXT: 	ret
; CHECK: createString:
; CHECK: 	addi	sp, sp, -16
; CHECK-NEXT: 	addi	a2, zero, 2047
; CHECK-NEXT: 	add	a3, zero, a0
; CHECK-NEXT: 	blt	a0, a2, .LBB3_2
; CHECK: 	addi	a3, zero, 2047
; CHECK-NEXT: .LBB3_2:
; CHECK-NEXT: 	addi	a2, zero, 1
; CHECK-NEXT: 	sext.w	a7, a3
; CHECK-NEXT: 	blt	a0, a2, .LBB3_12
; CHECK: 	blt	a2, a7, .LBB3_5
; CHECK: 	addi	a3, zero, 1
; CHECK-NEXT: .LBB3_5:
; CHECK-NEXT: 	sext.w	a6, a3
; CHECK-NEXT: 	addi	a0, zero, 8
; CHECK-NEXT: 	bgeu	a6, a0, .LBB3_7
; CHECK: 	mv	a3, zero
; CHECK-NEXT: 	j	.LBB3_10
; CHECK-NEXT: .LBB3_7:
; CHECK-NEXT: 	mv	a4, zero
; CHECK-NEXT: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	mova.x.m	a2
; CHECK-NEXT: 	andi	a2, a2, 255
; CHECK-NEXT: 	sb	a2, 15(sp)
; CHECK-NEXT: 	fbci.pi	ft0, 0
; CHECK-NEXT: 	mov.m.x	m0, zero, 170
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
; CHECK-NEXT: 	mov.m.x	m0, zero, 204
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
; CHECK-NEXT: 	mov.m.x	m0, zero, 240
; CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
; CHECK-NEXT: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	fbci.pi	ft2, 10
; CHECK-NEXT: 	fbci.pi	ft1, 48
; CHECK-NEXT: 	lui	a0, 524288
; CHECK-NEXT: 	addiw	a0, a0, -8
; CHECK-NEXT: 	and	a3, a3, a0
; CHECK-NEXT: 	fmvs.x.ps	t0, ft2, 0
; CHECK-NEXT: 	fmvs.x.ps	t1, ft2, 1
; CHECK-NEXT: 	fmvs.x.ps	t2, ft2, 2
; CHECK-NEXT: 	fmvs.x.ps	t3, ft2, 3
; CHECK-NEXT: 	fmvs.x.ps	t4, ft2, 4
; CHECK-NEXT: 	fmvs.x.ps	t5, ft2, 5
; CHECK-NEXT: 	fmvs.x.ps	t6, ft2, 6
; CHECK-NEXT: 	fmvs.x.ps	a0, ft2, 7
; CHECK-NEXT: 	fcmovm.ps	ft2, ft0, ft0
; CHECK-NEXT: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	mova.x.m	a2
; CHECK-NEXT: 	andi	a2, a2, 255
; CHECK-NEXT: 	sb	a2, 14(sp)
; CHECK-NEXT: 	mov.m.x	m0, zero, 2
; CHECK-NEXT: 	mova.x.m	a2
; CHECK-NEXT: 	andi	a2, a2, 255
; CHECK-NEXT: 	sb	a2, 13(sp)
; CHECK-NEXT: 	mov.m.x	m0, zero, 4
; CHECK-NEXT: 	mova.x.m	a2
; CHECK-NEXT: 	andi	a2, a2, 255
; CHECK-NEXT: 	sb	a2, 12(sp)
; CHECK-NEXT: 	mov.m.x	m0, zero, 8
; CHECK-NEXT: 	mova.x.m	a2
; CHECK-NEXT: 	andi	a2, a2, 255
; CHECK-NEXT: 	sb	a2, 11(sp)
; CHECK-NEXT: 	mov.m.x	m0, zero, 16
; CHECK-NEXT: 	mova.x.m	a2
; CHECK-NEXT: 	andi	a2, a2, 255
; CHECK-NEXT: 	sb	a2, 10(sp)
; CHECK-NEXT: 	mov.m.x	m0, zero, 32
; CHECK-NEXT: 	mova.x.m	a2
; CHECK-NEXT: 	andi	a2, a2, 255
; CHECK-NEXT: 	sb	a2, 9(sp)
; CHECK-NEXT: .LBB3_8:
; CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 0
; CHECK-NEXT: 	remuw	a2, a2, t0
; CHECK-NEXT: 	lb	a5, 15(sp)
; CHECK-NEXT: 	mov.m.x	m0, a5, 0
; CHECK-NEXT: 	fbcx.ps	ft3, a2
; CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 1
; CHECK-NEXT: 	remuw	a2, a2, t1
; CHECK-NEXT: 	lb	a5, 13(sp)
; CHECK-NEXT: 	mov.m.x	m0, a5, 0
; CHECK-NEXT: 	fbcx.ps	ft3, a2
; CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 2
; CHECK-NEXT: 	remuw	a2, a2, t2
; CHECK-NEXT: 	lb	a5, 12(sp)
; CHECK-NEXT: 	mov.m.x	m0, a5, 0
; CHECK-NEXT: 	fbcx.ps	ft3, a2
; CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 3
; CHECK-NEXT: 	remuw	a2, a2, t3
; CHECK-NEXT: 	lb	a5, 11(sp)
; CHECK-NEXT: 	mov.m.x	m0, a5, 0
; CHECK-NEXT: 	fbcx.ps	ft3, a2
; CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 4
; CHECK-NEXT: 	remuw	a2, a2, t4
; CHECK-NEXT: 	lb	a5, 10(sp)
; CHECK-NEXT: 	mov.m.x	m0, a5, 0
; CHECK-NEXT: 	fbcx.ps	ft3, a2
; CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 5
; CHECK-NEXT: 	remuw	a2, a2, t5
; CHECK-NEXT: 	lb	a5, 9(sp)
; CHECK-NEXT: 	mov.m.x	m0, a5, 0
; CHECK-NEXT: 	fbcx.ps	ft3, a2
; CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 6
; CHECK-NEXT: 	remuw	a2, a2, t6
; CHECK-NEXT: 	mov.m.x	m0, zero, 64
; CHECK-NEXT: 	fbcx.ps	ft3, a2
; CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 7
; CHECK-NEXT: 	remuw	a2, a2, a0
; CHECK-NEXT: 	mov.m.x	m0, zero, 128
; CHECK-NEXT: 	fbcx.ps	ft3, a2
; CHECK-NEXT: 	mov.m.x	m0, zero, 255
; CHECK-NEXT: 	faddi.pi	ft2, ft2, 8
; CHECK-NEXT: 	lb	a5, 14(sp)
; CHECK-NEXT: 	mov.m.x	m0, a5, 0
; CHECK-NEXT: 	for.pi	ft3, ft3, ft1
; CHECK-NEXT: 	slli	a2, a4, 32
; CHECK-NEXT: 	srli	a2, a2, 32
; CHECK-NEXT: 	add	a2, a2, a1
; CHECK-NEXT: 	addiw	a5, a4, 8
; CHECK-NEXT: 	addi	a4, a4, 8
; CHECK-NEXT: 	fscb.ps	ft3, ft0(a2)
; CHECK-NEXT: 	bne	a5, a3, .LBB3_8
; CHECK: 	beq	a6, a3, .LBB3_12
; CHECK-NEXT: .LBB3_10:
; CHECK-NEXT: 	lui	a0, 1035469
; CHECK-NEXT: 	addiw	a0, a0, -819
; CHECK-NEXT: 	slli	a0, a0, 12
; CHECK-NEXT: 	addi	a0, a0, -819
; CHECK-NEXT: 	slli	a0, a0, 12
; CHECK-NEXT: 	addi	a0, a0, -819
; CHECK-NEXT: 	slli	a0, a0, 12
; CHECK-NEXT: 	addi	a0, a0, -819
; CHECK-NEXT: 	addi	a6, zero, 10
; CHECK-NEXT: .LBB3_11:
; CHECK-NEXT: 	slli	a4, a3, 32
; CHECK-NEXT: 	srli	a4, a4, 32
; CHECK-NEXT: 	mulhu	a4, a4, a0
; CHECK-NEXT: 	srli	a4, a4, 3
; CHECK-NEXT: 	mul	a4, a4, a6
; CHECK-NEXT: 	sub	a4, a3, a4
; CHECK-NEXT: 	ori	a4, a4, 48
; CHECK-NEXT: 	add	a5, a1, a3
; CHECK-NEXT: 	addiw	a2, a3, 1
; CHECK-NEXT: 	addi	a3, a3, 1
; CHECK-NEXT: 	sb	a4, 0(a5)
; CHECK-NEXT: 	blt	a2, a7, .LBB3_11
; CHECK-NEXT: .LBB3_12:
; CHECK-NEXT: 	add	a0, a1, a7
; CHECK-NEXT: 	sb	zero, 0(a0)
; CHECK-NEXT: 	addi	sp, sp, 16
; CHECK-NEXT: 	ret
