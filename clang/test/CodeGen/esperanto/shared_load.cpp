// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -O3 -o - -S %s | FileCheck %s
#define SHARED __attribute__((address_space(1)))
#define GLOBAL __attribute__((address_space(2)))

int shared_load(SHARED char *P) { return *P; }
int shared_load(SHARED short *P) { return *P; }
int shared_load(SHARED int *P) { return *P; }

unsigned int shared_load(SHARED unsigned char *P) { return *P; }
unsigned int shared_load(SHARED unsigned short *P) { return *P; }
unsigned int shared_load(SHARED unsigned int *P) { return *P; }

// CHECK: _Z11shared_loadPU3AS1c:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fgbl.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvz.x.ps	a0, ft0, 0
// CHECK-NEXT: 	andi	a0, a0, 255
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11shared_loadPU3AS1s:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fghl.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvs.x.ps	a0, ft0, 0
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11shared_loadPU3AS1i:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fgwl.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvs.x.ps	a0, ft0, 0
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11shared_loadPU3AS1h:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fgbl.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvz.x.ps	a0, ft0, 0
// CHECK-NEXT: 	andi	a0, a0, 255
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11shared_loadPU3AS1t:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fghl.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvz.x.ps	a0, ft0, 0
// CHECK-NEXT: 	lui	a1, 16
// CHECK-NEXT: 	addiw	a1, a1, -1
// CHECK-NEXT: 	and	a0, a0, a1
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11shared_loadPU3AS1j:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fgwl.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvs.x.ps	a0, ft0, 0
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
