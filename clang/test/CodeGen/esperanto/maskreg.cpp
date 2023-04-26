// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -mabi=lp64f -O3 -o - -S %s | FileCheck %s

int main(int argc, char **argv) {

  unsigned int __attribute__((vector_size(sizeof(unsigned int) * 8))) dst;
  unsigned int __attribute__((vector_size(sizeof(unsigned int) * 8))) src1;
  unsigned int __attribute__((vector_size(sizeof(unsigned int) * 8))) src2;

  unsigned int long mask = 0xff;

  __asm__("fbci.pi %[src1], %[value1]\n"
          "fbci.pi %[src2], %[value2]\n"
          "fadd.pi %[dst], %[src1], %[src2]\n"
          : [ dst ] "=f"(dst), [ src1 ] "=f"(src1),
            [ src2 ] "=f"(src2)
          : [ mask0 ] "M"(255), [ value1 ] "i"(1), [ value2 ] "i"(2));

  return dst[0];
}

int main2(int argc, char **argv) {

  unsigned int __attribute__((vector_size(sizeof(unsigned int) * 8))) dst;
  unsigned int __attribute__((vector_size(sizeof(unsigned int) * 8))) src1;
  unsigned int __attribute__((vector_size(sizeof(unsigned int) * 8))) src2;

  unsigned int long mask = 0xff;

  __asm__("fbci.pi %[src1], %[value1]\n"
          "fbci.pi %[src2], %[value2]\n"
          "fadd.pi %[dst], %[src1], %[src2]\n"
          : [ dst ] "=f"(dst), [ src1 ] "=f"(src1),
            [ src2 ] "=f"(src2)
          : [ mask0 ] "M"(mask), [ mask_any1 ] "N"(mask), [ mask_any2 ] "N"(mask), [ value1 ] "i"(1), [ value2 ] "i"(2));

  return dst[0];
}
// CHECK: main:
// CHECK: 	addi	a0, zero, 255
// CHECK-NEXT: 	mov.m.x	m0, a0, 0
// CHECK: 	fbci.pi	ft1, 1
// CHECK-NEXT: 	fbci.pi	ft2, 2
// CHECK-NEXT: 	fadd.pi	ft0, ft1, ft2
// CHECK: 	fmvs.x.ps	a0, ft0, 0
// CHECK-NEXT: 	sext.w	a0, a0
// CHECK-NEXT: 	ret
// CHECK: _Z5main2iPPc:
// CHECK: 	addi	a0, zero, 255
// CHECK-NEXT: 	mov.m.x	m0, a0, 0
// CHECK-NEXT: 	mov.m.x	m1, a0, 0
// CHECK-NEXT: 	mov.m.x	m2, a0, 0
// CHECK: 	fbci.pi	ft1, 1
// CHECK-NEXT: 	fbci.pi	ft2, 2
// CHECK-NEXT: 	fadd.pi	ft0, ft1, ft2
// CHECK: 	fmvs.x.ps	a0, ft0, 0
// CHECK-NEXT: 	sext.w	a0, a0
// CHECK-NEXT: 	ret
