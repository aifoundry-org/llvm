// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -O3 -o - -S %s | FileCheck %s
#define SHARED __attribute__((address_space(1)))
#define GLOBAL __attribute__((address_space(2)))

void global_store(GLOBAL char *P, char c) { *P = c; }
void global_store(GLOBAL short *P, short c) { *P = c; }
void global_store(GLOBAL int *P, int c) { *P = c; }

// CHECK: _Z12global_storePU3AS2cc:
// CHECK: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	fbcx.ps	ft1, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fscbg.ps	ft0, ft1(a0)
// CHECK-NEXT: 	ret
// CHECK: _Z12global_storePU3AS2ss:
// CHECK: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	fbcx.ps	ft1, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fschg.ps	ft0, ft1(a0)
// CHECK-NEXT: 	ret
// CHECK: _Z12global_storePU3AS2ii:
// CHECK: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	fbcx.ps	ft1, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fscwg.ps	ft0, ft1(a0)
// CHECK-NEXT: 	ret
