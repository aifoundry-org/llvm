// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -O3 -o - -S %s | FileCheck %s
#define SHARED __attribute__((address_space(1)))
#define GLOBAL __attribute__((address_space(2)))

void shared_store(SHARED char *P, char c) { *P = c; }
void shared_store(SHARED short *P, short c) { *P = c; }
void shared_store(SHARED int *P, int c) { *P = c; }

// CHECK: _Z12shared_storePU3AS1cc:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fbcx.ps	ft1, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fscbl.ps	ft1, ft0(a0)
// CHECK-NEXT: 	ret
// CHECK: _Z12shared_storePU3AS1ss:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fbcx.ps	ft1, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fschl.ps	ft1, ft0(a0)
// CHECK-NEXT: 	ret
// CHECK: _Z12shared_storePU3AS1ii:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fbcx.ps	ft1, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fscwl.ps	ft1, ft0(a0)
// CHECK-NEXT: 	ret
