// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -mabi=lp64f -O3 -o - -S %s | FileCheck %s

void f() {
  unsigned long int dst;
  unsigned long int expected = 0x123456789abcdef0;
  unsigned long int value = 0x123456789abcdef0;
  unsigned long int mem;
  unsigned long int *address = &mem;

  asm volatile(
    // Test the "(addr)" format
    "amoaddg.d %[dst], %[val], (%[addr])\n"
    "amoaddg.w %[dst], %[val], (%[addr])\n"
    "amoaddl.d %[dst], %[val], (%[addr])\n"
    "amoaddl.w %[dst], %[val], (%[addr])\n"
    "amoandg.d %[dst], %[val], (%[addr])\n"
    "amoandg.w %[dst], %[val], (%[addr])\n"
    "amoandl.d %[dst], %[val], (%[addr])\n"
    "amoandl.w %[dst], %[val], (%[addr])\n"
    "amocmpswapg.d %[dst], %[val], (%[addr])\n"
    "amocmpswapg.w %[dst], %[val], (%[addr])\n"
    "amocmpswapl.d %[dst], %[val], (%[addr])\n"
    "amocmpswapl.w %[dst], %[val], (%[addr])\n"
    "amomaxg.d %[dst], %[val], (%[addr])\n"
    "amomaxg.w %[dst], %[val], (%[addr])\n"
    "amomaxl.d %[dst], %[val], (%[addr])\n"
    "amomaxl.w %[dst], %[val], (%[addr])\n"
    "amomaxug.d %[dst], %[val], (%[addr])\n"
    "amomaxug.w %[dst], %[val], (%[addr])\n"
    "amomaxul.d %[dst], %[val], (%[addr])\n"
    "amomaxul.w %[dst], %[val], (%[addr])\n"
    "amoming.d %[dst], %[val], (%[addr])\n"
    "amoming.w %[dst], %[val], (%[addr])\n"
    "amominl.d %[dst], %[val], (%[addr])\n"
    "amominl.w %[dst], %[val], (%[addr])\n"
    "amominug.d %[dst], %[val], (%[addr])\n"
    "amominug.w %[dst], %[val], (%[addr])\n"
    "amominul.d %[dst], %[val], (%[addr])\n"
    "amominul.w %[dst], %[val], (%[addr])\n"
    "amoorg.d %[dst], %[val], (%[addr])\n"
    "amoorg.w %[dst], %[val], (%[addr])\n"
    "amoorl.d %[dst], %[val], (%[addr])\n"
    "amoorl.w %[dst], %[val], (%[addr])\n"
    "amoswapg.d %[dst], %[val], (%[addr])\n"
    "amoswapg.w %[dst], %[val], (%[addr])\n"
    "amoswapl.d %[dst], %[val], (%[addr])\n"
    "amoswapl.w %[dst], %[val], (%[addr])\n"
    "amoxorg.d %[dst], %[val], (%[addr])\n"
    "amoxorg.w %[dst], %[val], (%[addr])\n"
    "amoxorl.d %[dst], %[val], (%[addr])\n"
    "amoxorl.w %[dst], %[val], (%[addr])\n"
    // Test the "0(addr)" format
    "amoaddg.d %[dst], %[val], 0(%[addr])\n"
    "amoaddg.w %[dst], %[val], 0(%[addr])\n"
    "amoaddl.d %[dst], %[val], 0(%[addr])\n"
    "amoaddl.w %[dst], %[val], 0(%[addr])\n"
    "amoandg.d %[dst], %[val], 0(%[addr])\n"
    "amoandg.w %[dst], %[val], 0(%[addr])\n"
    "amoandl.d %[dst], %[val], 0(%[addr])\n"
    "amoandl.w %[dst], %[val], 0(%[addr])\n"
    "amocmpswapg.d %[dst], %[val], 0(%[addr])\n"
    "amocmpswapg.w %[dst], %[val], 0(%[addr])\n"
    "amocmpswapl.d %[dst], %[val], 0(%[addr])\n"
    "amocmpswapl.w %[dst], %[val], 0(%[addr])\n"
    "amomaxg.d %[dst], %[val], 0(%[addr])\n"
    "amomaxg.w %[dst], %[val], 0(%[addr])\n"
    "amomaxl.d %[dst], %[val], 0(%[addr])\n"
    "amomaxl.w %[dst], %[val], 0(%[addr])\n"
    "amomaxug.d %[dst], %[val], 0(%[addr])\n"
    "amomaxug.w %[dst], %[val], 0(%[addr])\n"
    "amomaxul.d %[dst], %[val], 0(%[addr])\n"
    "amomaxul.w %[dst], %[val], 0(%[addr])\n"
    "amoming.d %[dst], %[val], 0(%[addr])\n"
    "amoming.w %[dst], %[val], 0(%[addr])\n"
    "amominl.d %[dst], %[val], 0(%[addr])\n"
    "amominl.w %[dst], %[val], 0(%[addr])\n"
    "amominug.d %[dst], %[val], 0(%[addr])\n"
    "amominug.w %[dst], %[val], 0(%[addr])\n"
    "amominul.d %[dst], %[val], 0(%[addr])\n"
    "amominul.w %[dst], %[val], 0(%[addr])\n"
    "amoorg.d %[dst], %[val], 0(%[addr])\n"
    "amoorg.w %[dst], %[val], 0(%[addr])\n"
    "amoorl.d %[dst], %[val], 0(%[addr])\n"
    "amoorl.w %[dst], %[val], 0(%[addr])\n"
    "amoswapg.d %[dst], %[val], 0(%[addr])\n"
    "amoswapg.w %[dst], %[val], 0(%[addr])\n"
    "amoswapl.d %[dst], %[val], 0(%[addr])\n"
    "amoswapl.w %[dst], %[val], 0(%[addr])\n"
    "amoxorg.d %[dst], %[val], 0(%[addr])\n"
    "amoxorg.w %[dst], %[val], 0(%[addr])\n"
    "amoxorl.d %[dst], %[val], 0(%[addr])\n"
    "amoxorl.w %[dst], %[val], 0(%[addr])\n"
    : [ dst ] "=r" (dst)
    : [ addr ] "r" (*address), [ val ] "r" (value)
  );
}
// CHECK: f:
// CHECK: 	lui	a0, 583
// CHECK-NEXT: 	addiw	a0, a0, -1875
// CHECK-NEXT: 	slli	a0, a0, 14
// CHECK-NEXT: 	addi	a0, a0, -947
// CHECK-NEXT: 	slli	a0, a0, 12
// CHECK-NEXT: 	addi	a0, a0, 1511
// CHECK-NEXT: 	slli	a0, a0, 13
// CHECK-NEXT: 	addi	a0, a0, -272
// CHECK: 	amoaddg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoaddg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoaddl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoaddl.w	a0, a0, (a0)
// CHECK-NEXT: 	amoandg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoandg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoandl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoandl.w	a0, a0, (a0)
// CHECK-NEXT: 	amocmpswapg.d	a0, a0, (a0)
// CHECK-NEXT: 	amocmpswapg.w	a0, a0, (a0)
// CHECK-NEXT: 	amocmpswapl.d	a0, a0, (a0)
// CHECK-NEXT: 	amocmpswapl.w	a0, a0, (a0)
// CHECK-NEXT: 	amomaxg.d	a0, a0, (a0)
// CHECK-NEXT: 	amomaxg.w	a0, a0, (a0)
// CHECK-NEXT: 	amomaxl.d	a0, a0, (a0)
// CHECK-NEXT: 	amomaxl.w	a0, a0, (a0)
// CHECK-NEXT: 	amomaxug.d	a0, a0, (a0)
// CHECK-NEXT: 	amomaxug.w	a0, a0, (a0)
// CHECK-NEXT: 	amomaxul.d	a0, a0, (a0)
// CHECK-NEXT: 	amomaxul.w	a0, a0, (a0)
// CHECK-NEXT: 	amoming.d	a0, a0, (a0)
// CHECK-NEXT: 	amoming.w	a0, a0, (a0)
// CHECK-NEXT: 	amominl.d	a0, a0, (a0)
// CHECK-NEXT: 	amominl.w	a0, a0, (a0)
// CHECK-NEXT: 	amominug.d	a0, a0, (a0)
// CHECK-NEXT: 	amominug.w	a0, a0, (a0)
// CHECK-NEXT: 	amominul.d	a0, a0, (a0)
// CHECK-NEXT: 	amominul.w	a0, a0, (a0)
// CHECK-NEXT: 	amoorg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoorg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoorl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoorl.w	a0, a0, (a0)
// CHECK-NEXT: 	amoswapg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoswapg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoswapl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoswapl.w	a0, a0, (a0)
// CHECK-NEXT: 	amoxorg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoxorg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoxorl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoxorl.w	a0, a0, (a0)
// CHECK-NEXT: 	amoaddg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoaddg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoaddl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoaddl.w	a0, a0, (a0)
// CHECK-NEXT: 	amoandg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoandg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoandl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoandl.w	a0, a0, (a0)
// CHECK-NEXT: 	amocmpswapg.d	a0, a0, (a0)
// CHECK-NEXT: 	amocmpswapg.w	a0, a0, (a0)
// CHECK-NEXT: 	amocmpswapl.d	a0, a0, (a0)
// CHECK-NEXT: 	amocmpswapl.w	a0, a0, (a0)
// CHECK-NEXT: 	amomaxg.d	a0, a0, (a0)
// CHECK-NEXT: 	amomaxg.w	a0, a0, (a0)
// CHECK-NEXT: 	amomaxl.d	a0, a0, (a0)
// CHECK-NEXT: 	amomaxl.w	a0, a0, (a0)
// CHECK-NEXT: 	amomaxug.d	a0, a0, (a0)
// CHECK-NEXT: 	amomaxug.w	a0, a0, (a0)
// CHECK-NEXT: 	amomaxul.d	a0, a0, (a0)
// CHECK-NEXT: 	amomaxul.w	a0, a0, (a0)
// CHECK-NEXT: 	amoming.d	a0, a0, (a0)
// CHECK-NEXT: 	amoming.w	a0, a0, (a0)
// CHECK-NEXT: 	amominl.d	a0, a0, (a0)
// CHECK-NEXT: 	amominl.w	a0, a0, (a0)
// CHECK-NEXT: 	amominug.d	a0, a0, (a0)
// CHECK-NEXT: 	amominug.w	a0, a0, (a0)
// CHECK-NEXT: 	amominul.d	a0, a0, (a0)
// CHECK-NEXT: 	amominul.w	a0, a0, (a0)
// CHECK-NEXT: 	amoorg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoorg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoorl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoorl.w	a0, a0, (a0)
// CHECK-NEXT: 	amoswapg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoswapg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoswapl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoswapl.w	a0, a0, (a0)
// CHECK-NEXT: 	amoxorg.d	a0, a0, (a0)
// CHECK-NEXT: 	amoxorg.w	a0, a0, (a0)
// CHECK-NEXT: 	amoxorl.d	a0, a0, (a0)
// CHECK-NEXT: 	amoxorl.w	a0, a0, (a0)
// CHECK: 	ret
