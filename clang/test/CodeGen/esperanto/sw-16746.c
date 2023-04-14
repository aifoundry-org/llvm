// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -mabi=lp64f -O3 -o - -S %s | FileCheck %s

void f() {
  unsigned short int value = 0x1234;
  unsigned short int mem;
  unsigned short int *address = &mem;

  // Using the "A" modifier (an alias for "0(addr)")
  asm volatile(
    "shg %[val], %[addr]"
    : [addr] "=A" (*address)
    : [val]   "r" (value)
  );

  // Trying the "(addr)" and "0(addr)" variants
  asm volatile(
    "shg %[val], (%[addr])\n"
    "shg %[val], 0(%[addr])"
    :
    : [addr] "r" (*address), [val] "r" (value)
  );
}
// CHECK: f:
// CHECK: 	addi	sp, sp, -16
// CHECK-NEXT: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	lui	a0, 1
// CHECK-NEXT: 	addiw	a0, a0, 564
// CHECK-NEXT: 	addi	a1, sp, 14
// CHECK: 	shg	a0, (a1)
// CHECK: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fgh.ps	ft0, ft0(a1)
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	fmvz.x.ps	a1, ft0, 0
// CHECK-NEXT: 	lui	a2, 16
// CHECK-NEXT: 	addiw	a2, a2, -1
// CHECK-NEXT: 	and	a1, a1, a2
// CHECK: 	shg	a0, (a1)
// CHECK-NEXT: 	shg	a0, (a1)
// CHECK: 	addi	sp, sp, 16
// CHECK-NEXT: 	ret
