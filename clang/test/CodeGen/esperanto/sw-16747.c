// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -mabi=lp64f -O0 -o - -S %s | FileCheck %s

void f1() {
     unsigned long int uvalue = 0x123456789ABCDEF0;
     float f = (float)uvalue;
}

void f2() {
     signed long int svalue = 0x123456789ABCDEF0;
     float f = (float)svalue;
}

void f3() {
     float fvalue = 123.f;
     signed long int svalue = (signed long int)fvalue;
}

void f4() {
     float fvalue = 123.f;
     unsigned long int svalue = (unsigned long int)fvalue;
}

// CHECK: f1:
// CHECK: 	addi	sp, sp, -48
// CHECK-NEXT: 	sd	ra, 40(sp)
// CHECK-NEXT: 	sd	s0, 32(sp)
// CHECK-NEXT: 	addi	s0, sp, 48
// CHECK-NEXT: 	lui	a0, 583
// CHECK-NEXT: 	addiw	a0, a0, -1875
// CHECK-NEXT: 	slli	a0, a0, 14
// CHECK-NEXT: 	addi	a0, a0, -947
// CHECK-NEXT: 	slli	a0, a0, 12
// CHECK-NEXT: 	addi	a0, a0, 1511
// CHECK-NEXT: 	slli	a0, a0, 13
// CHECK-NEXT: 	addi	a0, a0, -272
// CHECK-NEXT: 	sd	a0, -24(s0)
// CHECK-NEXT: 	ld	a0, -24(s0)
// CHECK-NEXT: 	sw	a0, -32(s0)
// CHECK-NEXT: 	srli	a0, a0, 32
// CHECK-NEXT: 	sw	a0, -40(s0)
// CHECK-NEXT: 	ld	a0, -32(s0)
// CHECK-NEXT: 	fcvt.s.wu	ft0, a0
// CHECK-NEXT: 	ld	a0, -40(s0)
// CHECK-NEXT: 	fcvt.s.wu	ft1, a0
// CHECK-NEXT: 	lui	a0, 325632
// CHECK-NEXT: 	fmv.w.x	ft2, a0
// CHECK-NEXT: 	fmadd.s	ft0, ft1, ft2, ft0
// CHECK-NEXT: 	fsw	ft0, -28(s0)
// CHECK-NEXT: 	ld	s0, 32(sp)
// CHECK-NEXT: 	ld	ra, 40(sp)
// CHECK-NEXT: 	addi	sp, sp, 48
// CHECK-NEXT: 	ret
// CHECK: f2:
// CHECK: 	addi	sp, sp, -64
// CHECK-NEXT: 	sd	ra, 56(sp)
// CHECK-NEXT: 	sd	s0, 48(sp)
// CHECK-NEXT: 	addi	s0, sp, 64
// CHECK-NEXT: 	lui	a0, 583
// CHECK-NEXT: 	addiw	a0, a0, -1875
// CHECK-NEXT: 	slli	a0, a0, 14
// CHECK-NEXT: 	addi	a0, a0, -947
// CHECK-NEXT: 	slli	a0, a0, 12
// CHECK-NEXT: 	addi	a0, a0, 1511
// CHECK-NEXT: 	slli	a0, a0, 13
// CHECK-NEXT: 	addi	a0, a0, -272
// CHECK-NEXT: 	sd	a0, -24(s0)
// CHECK-NEXT: 	ld	a0, -24(s0)
// CHECK-NEXT: 	addi	a1, zero, -1
// CHECK-NEXT: 	slli	a1, a1, 63
// CHECK-NEXT: 	addi	a1, a1, -1
// CHECK-NEXT: 	xor	a1, a1, a0
// CHECK-NEXT: 	sw	a1, -32(s0)
// CHECK-NEXT: 	srli	a1, a1, 32
// CHECK-NEXT: 	sw	a1, -40(s0)
// CHECK-NEXT: 	addi	a1, zero, 383
// CHECK-NEXT: 	slli	a1, a1, 23
// CHECK-NEXT: 	lui	a2, 260096
// CHECK-NEXT: 	mv	a3, zero
// CHECK-NEXT: 	add	a4, zero, a3
// CHECK-NEXT: 	sd	a1, -48(s0)
// CHECK-NEXT: 	sd	a2, -56(s0)
// CHECK-NEXT: 	sd	a4, -64(s0)
// CHECK-NEXT: 	bge	a3, a0, .LBB1_2
// CHECK: 	ld	a0, -48(s0)
// CHECK-NEXT: 	ld	a1, -48(s0)
// CHECK-NEXT: 	sd	a0, -56(s0)
// CHECK-NEXT: 	sd	a1, -64(s0)
// CHECK-NEXT: .LBB1_2:
// CHECK-NEXT: 	ld	a0, -64(s0)
// CHECK-NEXT: 	ld	a1, -56(s0)
// CHECK-NEXT: 	ld	a2, -32(s0)
// CHECK-NEXT: 	fcvt.s.wu	ft0, a2
// CHECK-NEXT: 	ld	a2, -40(s0)
// CHECK-NEXT: 	fcvt.s.wu	ft1, a2
// CHECK-NEXT: 	lui	a2, 325632
// CHECK-NEXT: 	fmv.w.x	ft2, a2
// CHECK-NEXT: 	fmadd.s	ft0, ft1, ft2, ft0
// CHECK-NEXT: 	fmv.w.x	ft1, a1
// CHECK-NEXT: 	fmv.w.x	ft2, a0
// CHECK-NEXT: 	fmadd.s	ft0, ft0, ft1, ft2
// CHECK-NEXT: 	fsw	ft0, -28(s0)
// CHECK-NEXT: 	ld	s0, 48(sp)
// CHECK-NEXT: 	ld	ra, 56(sp)
// CHECK-NEXT: 	addi	sp, sp, 64
// CHECK-NEXT: 	ret
// CHECK: f3:
// CHECK: 	addi	sp, sp, -48
// CHECK-NEXT: 	sd	ra, 40(sp)
// CHECK-NEXT: 	sd	s0, 32(sp)
// CHECK-NEXT: 	addi	s0, sp, 48
// CHECK-NEXT: 	lui	a0, 274272
// CHECK-NEXT: 	sw	a0, -20(s0)
// CHECK-NEXT: 	flw	ft0, -20(s0)
// CHECK-NEXT: 	fsw	ft0, -36(s0)
// CHECK-NEXT: 	ld	a0, -36(s0)
// CHECK-NEXT: 	fmv.w.x	ft0, a0
// CHECK-NEXT: 	fcvt.w.s	a0, ft0
// CHECK-NEXT: 	fmv.w.x	ft0, a0
// CHECK-NEXT: 	fsw	ft0, -32(s0)
// CHECK-NEXT: 	ld	s0, 32(sp)
// CHECK-NEXT: 	ld	ra, 40(sp)
// CHECK-NEXT: 	addi	sp, sp, 48
// CHECK-NEXT: 	ret
// CHECK: f4:
// CHECK: 	addi	sp, sp, -48
// CHECK-NEXT: 	sd	ra, 40(sp)
// CHECK-NEXT: 	sd	s0, 32(sp)
// CHECK-NEXT: 	addi	s0, sp, 48
// CHECK-NEXT: 	lui	a0, 274272
// CHECK-NEXT: 	sw	a0, -20(s0)
// CHECK-NEXT: 	flw	ft0, -20(s0)
// CHECK-NEXT: 	fsw	ft0, -36(s0)
// CHECK-NEXT: 	ld	a0, -36(s0)
// CHECK-NEXT: 	fmv.w.x	ft0, a0
// CHECK-NEXT: 	fcvt.wu.s	a0, ft0
// CHECK-NEXT: 	fmv.w.x	ft0, a0
// CHECK-NEXT: 	fsw	ft0, -32(s0)
// CHECK-NEXT: 	ld	s0, 32(sp)
// CHECK-NEXT: 	ld	ra, 40(sp)
// CHECK-NEXT: 	addi	sp, sp, 48
// CHECK-NEXT: 	ret
