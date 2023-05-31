// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -mabi=lp64f -O3 -o - -S %s | FileCheck %s

float f() {
  unsigned short int src = 0xb800;
  float dst;
  __asm__ __volatile__("fmv.s.x %[dst], %[src]\n"
                       "fcvt.ps.f16 %[dst], %[dst]\n"
                       : [ dst ] "=f"(dst)
                       : [ vmask ] "M"(1), [src] "r"(src)
                       :);
  return dst;
}

float f2() {
  unsigned short int src = 0xb800;
  float dst;
  __asm__ __volatile__("fmv.s.x %[dst], %[src]\n"
                       "fcvt.ps.f16 %[dst], %[dst]\n"
                       : [ dst ] "=f"(dst)
                       : [ vmask ] "M"(1), [src] "r"(src)
                       :);
  __asm__ __volatile__("fmv.s.x %[dst], %[src]\n"
                       "fcvt.ps.f16 %[dst], %[dst]\n"
                       : [ dst ] "=f"(dst)
                       : [ vmask ] "M"(2), [src] "r"(src)
                       :);

  return dst;
}

float f3() {
  unsigned short int src = 0xb800;
  float dst;
  __asm__ __volatile__("fmv.s.x %[dst], %[src]\n"
                       "fcvt.ps.f16 %[dst], %[dst]\n"
                       : [ dst ] "=f"(dst)
                       : [ vmask ] "M"(1), [src] "r"(src)
                       :);
  __asm__ __volatile__("fmv.s.x %[dst], %[src]\n"
                       "fcvt.ps.f16 %[dst], %[dst]\n"
                       : [ dst ] "=f"(dst)
                       : [ vmask ] "M"(1), [src] "r"(src)
                       :);

  return dst;
}


float f4(int length) {
  unsigned short int src = 0xb800;
  float dst;
  int mask = length & 7;
  __asm__ __volatile__("fmv.s.x %[dst], %[src]\n"
                       "fcvt.ps.f16 %[dst], %[dst]\n"
                       : [ dst ] "=f"(dst)
                       : [ vmask ] "M"(1), [src] "r"(src)
                       :);
  __asm__ __volatile__("fmv.s.x %[dst], %[src]\n"
                       "fcvt.ps.f16 %[dst], %[dst]\n"
                       : [ dst ] "=f"(dst)
                       : [ vmask ] "M"(mask), [src] "r"(src)
                       :);

  return dst;
}


float f5(int length) {
  unsigned short int src = 0xb800;
  float dst;
  int mask = length > 8 ? 8 : 1;
  __asm__ __volatile__("fmv.s.x %[dst], %[src]\n"
                       "fcvt.ps.f16 %[dst], %[dst]\n"
                       : [ dst ] "=f"(dst)
                       : [ vmask ] "M"(1), [src] "r"(src)
                       :);
  __asm__ __volatile__("fmv.s.x %[dst], %[src]\n"
                       "fcvt.ps.f16 %[dst], %[dst]\n"
                       : [ dst ] "=f"(dst)
                       : [ vmask ] "M"(mask), [src] "r"(src)
                       :);

  return dst;
}


// CHECK: _Z1fv:
// CHECK: 	lui	a0, 12
// CHECK-NEXT: 	addiw	a0, a0, -2048
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK: 	fmv.w.x	fa0, a0
// CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
// CHECK: 	addi	a0, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z2f2v:
// CHECK: 	lui	a0, 12
// CHECK-NEXT: 	addiw	a0, a0, -2048
// CHECK-NEXT: 	addi	a1, zero, 1
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK: 	fmv.w.x	ft0, a0
// CHECK-NEXT: 	fcvt.ps.f16	ft0, ft0
// CHECK: 	mov.m.x	m0, zero, 2
// CHECK: 	fmv.w.x	fa0, a0
// CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
// CHECK: 	addi	a0, zero, 2
// CHECK-NEXT: 	ret
// CHECK: _Z2f3v:
// CHECK: 	lui	a0, 12
// CHECK-NEXT: 	addiw	a0, a0, -2048
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK: 	fmv.w.x	ft0, a0
// CHECK-NEXT: 	fcvt.ps.f16	ft0, ft0
// CHECK: 	fmv.w.x	fa0, a0
// CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
// CHECK: 	addi	a0, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z2f4i:
// CHECK: 	lui	a1, 12
// CHECK-NEXT: 	addiw	a1, a1, -2048
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK: 	fmv.w.x	ft0, a1
// CHECK-NEXT: 	fcvt.ps.f16	ft0, ft0
// CHECK: 	andi	a0, a0, 7
// CHECK-NEXT: 	mov.m.x	m0, a0, 0
// CHECK: 	fmv.w.x	fa0, a1
// CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
// CHECK: 	addi	a0, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z2f5i:
// CHECK: 	lui	a1, 12
// CHECK-NEXT: 	addiw	a1, a1, -2048
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	addi	a2, zero, 8
// CHECK: 	fmv.w.x	ft0, a1
// CHECK-NEXT: 	fcvt.ps.f16	ft0, ft0
// CHECK: 	blt	a2, a0, .LBB4_2
// CHECK: 	addi	a2, zero, 1
// CHECK-NEXT: .LBB4_2:
// CHECK-NEXT: 	mov.m.x	m0, a2, 0
// CHECK: 	fmv.w.x	fa0, a1
// CHECK-NEXT: 	fcvt.ps.f16	fa0, fa0
// CHECK: 	ret
