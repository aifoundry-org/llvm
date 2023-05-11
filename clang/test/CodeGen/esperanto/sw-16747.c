// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -mabi=lp64f -O3 -o - -S %s | FileCheck %s

float f1(unsigned long int uvalue) {
  float f = (float)uvalue;
  return f;
}

float f2(signed long int svalue) {
  float f = (float)svalue;
  return f;
}

signed long int f3(float fvalue) {
  signed long int svalue = (signed long int)fvalue;
  return svalue;
}

unsigned long int f4(float fvalue) {
  unsigned long int uvalue = (unsigned long int)fvalue;
  return uvalue;
}

// CHECK: f1:
// CHECK: 	srli	a1, a0, 32
// CHECK-NEXT: 	fcvt.s.wu	ft0, a1
// CHECK-NEXT: 	slli	a0, a0, 32
// CHECK-NEXT: 	srli	a0, a0, 32
// CHECK-NEXT: 	fcvt.s.wu	ft1, a0
// CHECK-NEXT: 	fmadd.s	fa0, ft0, 1333788672, ft1, dyn
// CHECK-NEXT: 	ret
// CHECK: f2:
// CHECK: 	addi	a1, zero, 1
// CHECK-NEXT: 	neg	a2, a1
// CHECK-NEXT: 	srli	a2, a2, 1
// CHECK-NEXT: 	and	a2, a2, a0
// CHECK-NEXT: 	slli	a1, a1, 63
// CHECK-NEXT: 	and	a0, a0, a1
// CHECK-NEXT: 	srai	a0, a0, 63
// CHECK-NEXT: 	srli	a1, a0, 1
// CHECK-NEXT: 	xor	a1, a1, a2
// CHECK-NEXT: 	srli	a2, a1, 32
// CHECK-NEXT: 	fcvt.s.wu	ft0, a2
// CHECK-NEXT: 	slli	a1, a1, 32
// CHECK-NEXT: 	srli	a1, a1, 32
// CHECK-NEXT: 	fcvt.s.wu	ft1, a1
// CHECK-NEXT: 	fmadd.s	ft0, ft0, 1333788672, ft1, dyn
// CHECK-NEXT: 	fcvt.s.w	ft1, a0
// CHECK-NEXT: 	slli	a0, a0, 1
// CHECK-NEXT: 	addi	a0, a0, 1
// CHECK-NEXT: 	fcvt.s.w	ft2, a0
// CHECK-NEXT: 	fmadd.s	fa0, ft0, ft2, ft1
// CHECK-NEXT: 	ret
// CHECK: f3:
// CHECK: 	addi	sp, sp, -16
// CHECK-NEXT: 	fsw	fa0, 12(sp)
// CHECK-NEXT: 	ld	a0, 12(sp)
// CHECK-NEXT: 	fmv.w.x	ft0, a0
// CHECK-NEXT: 	fcvt.w.s	a0, ft0
// CHECK-NEXT: 	addi	sp, sp, 16
// CHECK-NEXT: 	ret
// CHECK: f4:
// CHECK: 	addi	sp, sp, -16
// CHECK-NEXT: 	fsw	fa0, 12(sp)
// CHECK-NEXT: 	ld	a0, 12(sp)
// CHECK-NEXT: 	fmv.w.x	ft0, a0
// CHECK-NEXT: 	fcvt.wu.s	a0, ft0
// CHECK-NEXT: 	addi	sp, sp, 16
// CHECK-NEXT: 	ret
