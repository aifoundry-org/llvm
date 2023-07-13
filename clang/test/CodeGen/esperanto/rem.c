// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -mabi=lp64f -O3 -o - -S %s | FileCheck %s

unsigned int f1(
  unsigned int a,
  unsigned int b) {
  return a % b;
}

unsigned int __attribute__((vector_size(sizeof(unsigned int) * 8))) f2(
  unsigned int __attribute__((vector_size(sizeof(unsigned int) * 8))) a,
  unsigned int __attribute__((vector_size(sizeof(unsigned int) * 8))) b) {
  return a % b;
}

char f3(int i) {
  return '0' + (char)(i % 10);
}

void createString(int length, char *str) {
  length = (length < 2048) ? length :2048 - 1;

  // Fill the string with characters
  for (int i = 0; i < length; ++i) {
    str[i] = '0' + (char)(i % 10);  // Add consecutive digits '0' to '9'
  }
  str[length] = '\0';  // Null-terminate the string
}


// CHECK: f1:
// CHECK: 	remuw	a0, a0, a1
// CHECK-NEXT: 	ret
// CHECK: f2:
// CHECK: 	flq2	ft0, 0(a2)
// CHECK-NEXT: 	flq2	ft1, 0(a1)
// CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 0
// CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 0
// CHECK-NEXT: 	remuw	a1, a2, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbcx.ps	ft2, a1
// CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 1
// CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 1
// CHECK-NEXT: 	remuw	a1, a2, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 2
// CHECK-NEXT: 	fbcx.ps	ft2, a1
// CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 2
// CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 2
// CHECK-NEXT: 	remuw	a1, a2, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 4
// CHECK-NEXT: 	fbcx.ps	ft2, a1
// CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 3
// CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 3
// CHECK-NEXT: 	remuw	a1, a2, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 8
// CHECK-NEXT: 	fbcx.ps	ft2, a1
// CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 4
// CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 4
// CHECK-NEXT: 	remuw	a1, a2, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 16
// CHECK-NEXT: 	fbcx.ps	ft2, a1
// CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 5
// CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 5
// CHECK-NEXT: 	remuw	a1, a2, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 32
// CHECK-NEXT: 	fbcx.ps	ft2, a1
// CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 6
// CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 6
// CHECK-NEXT: 	remuw	a1, a2, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 64
// CHECK-NEXT: 	fbcx.ps	ft2, a1
// CHECK-NEXT: 	fmvs.x.ps	a1, ft0, 7
// CHECK-NEXT: 	fmvs.x.ps	a2, ft1, 7
// CHECK-NEXT: 	remuw	a1, a2, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 128
// CHECK-NEXT: 	fbcx.ps	ft2, a1
// CHECK-NEXT: 	fsq2	ft2, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: f3:
// CHECK: 	lui	a1, 13107
// CHECK-NEXT: 	addiw	a1, a1, 819
// CHECK-NEXT: 	slli	a1, a1, 12
// CHECK-NEXT: 	addi	a1, a1, 819
// CHECK-NEXT: 	slli	a1, a1, 12
// CHECK-NEXT: 	addi	a1, a1, 819
// CHECK-NEXT: 	slli	a1, a1, 13
// CHECK-NEXT: 	addi	a1, a1, 1639
// CHECK-NEXT: 	mulh	a1, a0, a1
// CHECK-NEXT: 	srli	a2, a1, 63
// CHECK-NEXT: 	srli	a1, a1, 2
// CHECK-NEXT: 	add	a1, a1, a2
// CHECK-NEXT: 	addi	a2, zero, 10
// CHECK-NEXT: 	mul	a1, a1, a2
// CHECK-NEXT: 	sub	a0, a0, a1
// CHECK-NEXT: 	addi	a0, a0, 48
// CHECK-NEXT: 	andi	a0, a0, 255
// CHECK-NEXT: 	ret
// CHECK: createString:
// CHECK: 	addi	sp, sp, -16
// CHECK-NEXT: 	addi	a2, zero, 2047
// CHECK-NEXT: 	add	a3, zero, a0
// CHECK-NEXT: 	blt	a0, a2, .LBB3_2
// CHECK: 	addi	a3, zero, 2047
// CHECK-NEXT: .LBB3_2:
// CHECK-NEXT: 	addi	a2, zero, 1
// CHECK-NEXT: 	sext.w	a7, a3
// CHECK-NEXT: 	blt	a0, a2, .LBB3_12
// CHECK: 	blt	a2, a7, .LBB3_5
// CHECK: 	addi	a3, zero, 1
// CHECK-NEXT: .LBB3_5:
// CHECK-NEXT: 	sext.w	a6, a3
// CHECK-NEXT: 	addi	a0, zero, 8
// CHECK-NEXT: 	bgeu	a6, a0, .LBB3_7
// CHECK: 	mv	a3, zero
// CHECK-NEXT: 	j	.LBB3_10
// CHECK-NEXT: .LBB3_7:
// CHECK-NEXT: 	mv	a4, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	mova.x.m	a2
// CHECK-NEXT: 	andi	a2, a2, 255
// CHECK-NEXT: 	sb	a2, 15(sp)
// CHECK-NEXT: 	fbci.pi	ft0, 0
// CHECK-NEXT: 	mov.m.x	m0, zero, 170
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
// CHECK-NEXT: 	mov.m.x	m0, zero, 204
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
// CHECK-NEXT: 	mov.m.x	m0, zero, 240
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
// CHECK-NEXT: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft2, 10
// CHECK-NEXT: 	fbci.pi	ft1, 48
// CHECK-NEXT: 	lui	a0, 524288
// CHECK-NEXT: 	addiw	a0, a0, -8
// CHECK-NEXT: 	and	a3, a3, a0
// CHECK-NEXT: 	fmvs.x.ps	t0, ft2, 0
// CHECK-NEXT: 	fmvs.x.ps	t1, ft2, 1
// CHECK-NEXT: 	fmvs.x.ps	t2, ft2, 2
// CHECK-NEXT: 	fmvs.x.ps	t3, ft2, 3
// CHECK-NEXT: 	fmvs.x.ps	t4, ft2, 4
// CHECK-NEXT: 	fmvs.x.ps	t5, ft2, 5
// CHECK-NEXT: 	fmvs.x.ps	t6, ft2, 6
// CHECK-NEXT: 	fmvs.x.ps	a0, ft2, 7
// CHECK-NEXT: 	fcmovm.ps	ft2, ft0, ft0
// CHECK-NEXT: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	mova.x.m	a2
// CHECK-NEXT: 	andi	a2, a2, 255
// CHECK-NEXT: 	sb	a2, 14(sp)
// CHECK-NEXT: 	mov.m.x	m0, zero, 2
// CHECK-NEXT: 	mova.x.m	a2
// CHECK-NEXT: 	andi	a2, a2, 255
// CHECK-NEXT: 	sb	a2, 13(sp)
// CHECK-NEXT: 	mov.m.x	m0, zero, 4
// CHECK-NEXT: 	mova.x.m	a2
// CHECK-NEXT: 	andi	a2, a2, 255
// CHECK-NEXT: 	sb	a2, 12(sp)
// CHECK-NEXT: 	mov.m.x	m0, zero, 8
// CHECK-NEXT: 	mova.x.m	a2
// CHECK-NEXT: 	andi	a2, a2, 255
// CHECK-NEXT: 	sb	a2, 11(sp)
// CHECK-NEXT: 	mov.m.x	m0, zero, 16
// CHECK-NEXT: 	mova.x.m	a2
// CHECK-NEXT: 	andi	a2, a2, 255
// CHECK-NEXT: 	sb	a2, 10(sp)
// CHECK-NEXT: 	mov.m.x	m0, zero, 32
// CHECK-NEXT: 	mova.x.m	a2
// CHECK-NEXT: 	andi	a2, a2, 255
// CHECK-NEXT: 	sb	a2, 9(sp)
// CHECK-NEXT: .LBB3_8:
// CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 0
// CHECK-NEXT: 	remuw	a2, a2, t0
// CHECK-NEXT: 	lb	a5, 15(sp)
// CHECK-NEXT: 	mov.m.x	m0, a5, 0
// CHECK-NEXT: 	fbcx.ps	ft3, a2
// CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 1
// CHECK-NEXT: 	remuw	a2, a2, t1
// CHECK-NEXT: 	lb	a5, 13(sp)
// CHECK-NEXT: 	mov.m.x	m0, a5, 0
// CHECK-NEXT: 	fbcx.ps	ft3, a2
// CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 2
// CHECK-NEXT: 	remuw	a2, a2, t2
// CHECK-NEXT: 	lb	a5, 12(sp)
// CHECK-NEXT: 	mov.m.x	m0, a5, 0
// CHECK-NEXT: 	fbcx.ps	ft3, a2
// CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 3
// CHECK-NEXT: 	remuw	a2, a2, t3
// CHECK-NEXT: 	lb	a5, 11(sp)
// CHECK-NEXT: 	mov.m.x	m0, a5, 0
// CHECK-NEXT: 	fbcx.ps	ft3, a2
// CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 4
// CHECK-NEXT: 	remuw	a2, a2, t4
// CHECK-NEXT: 	lb	a5, 10(sp)
// CHECK-NEXT: 	mov.m.x	m0, a5, 0
// CHECK-NEXT: 	fbcx.ps	ft3, a2
// CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 5
// CHECK-NEXT: 	remuw	a2, a2, t5
// CHECK-NEXT: 	lb	a5, 9(sp)
// CHECK-NEXT: 	mov.m.x	m0, a5, 0
// CHECK-NEXT: 	fbcx.ps	ft3, a2
// CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 6
// CHECK-NEXT: 	remuw	a2, a2, t6
// CHECK-NEXT: 	mov.m.x	m0, zero, 64
// CHECK-NEXT: 	fbcx.ps	ft3, a2
// CHECK-NEXT: 	fmvs.x.ps	a2, ft2, 7
// CHECK-NEXT: 	remuw	a2, a2, a0
// CHECK-NEXT: 	mov.m.x	m0, zero, 128
// CHECK-NEXT: 	fbcx.ps	ft3, a2
// CHECK-NEXT: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	faddi.pi	ft2, ft2, 8
// CHECK-NEXT: 	lb	a5, 14(sp)
// CHECK-NEXT: 	mov.m.x	m0, a5, 0
// CHECK-NEXT: 	for.pi	ft3, ft3, ft1
// CHECK-NEXT: 	slli	a2, a4, 32
// CHECK-NEXT: 	srli	a2, a2, 32
// CHECK-NEXT: 	add	a2, a2, a1
// CHECK-NEXT: 	addiw	a5, a4, 8
// CHECK-NEXT: 	addi	a4, a4, 8
// CHECK-NEXT: 	fscb.ps	ft3, ft0(a2)
// CHECK-NEXT: 	bne	a5, a3, .LBB3_8
// CHECK: 	beq	a6, a3, .LBB3_12
// CHECK-NEXT: .LBB3_10:
// CHECK-NEXT: 	lui	a0, 1035469
// CHECK-NEXT: 	addiw	a0, a0, -819
// CHECK-NEXT: 	slli	a0, a0, 12
// CHECK-NEXT: 	addi	a0, a0, -819
// CHECK-NEXT: 	slli	a0, a0, 12
// CHECK-NEXT: 	addi	a0, a0, -819
// CHECK-NEXT: 	slli	a0, a0, 12
// CHECK-NEXT: 	addi	a0, a0, -819
// CHECK-NEXT: 	addi	a6, zero, 10
// CHECK-NEXT: .LBB3_11:
// CHECK-NEXT: 	slli	a4, a3, 32
// CHECK-NEXT: 	srli	a4, a4, 32
// CHECK-NEXT: 	mulhu	a4, a4, a0
// CHECK-NEXT: 	srli	a4, a4, 3
// CHECK-NEXT: 	mul	a4, a4, a6
// CHECK-NEXT: 	sub	a4, a3, a4
// CHECK-NEXT: 	ori	a4, a4, 48
// CHECK-NEXT: 	add	a5, a1, a3
// CHECK-NEXT: 	addiw	a2, a3, 1
// CHECK-NEXT: 	addi	a3, a3, 1
// CHECK-NEXT: 	sb	a4, 0(a5)
// CHECK-NEXT: 	blt	a2, a7, .LBB3_11
// CHECK-NEXT: .LBB3_12:
// CHECK-NEXT: 	add	a0, a1, a7
// CHECK-NEXT: 	sb	zero, 0(a0)
// CHECK-NEXT: 	addi	sp, sp, 16
// CHECK-NEXT: 	ret
