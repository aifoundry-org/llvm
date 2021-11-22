// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -O3 -o - -S %s | FileCheck %s
#define SHARED __attribute__((address_space(1)))
#define GLOBAL __attribute__((address_space(2)))

int global_load(GLOBAL char *P) { return *P; }
int global_load(GLOBAL short *P) { return *P; }
int global_load(GLOBAL int *P) { return *P; }

unsigned int global_load(GLOBAL unsigned char *P) { return *P; }
unsigned int global_load(GLOBAL unsigned short *P) { return *P; }
unsigned int global_load(GLOBAL unsigned int *P) { return *P; }

// CHECK: _Z11global_loadPU3AS2c:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fgbg.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvz.x.ps	a0, ft0, 0
// CHECK-NEXT: 	andi	a0, a0, 255
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11global_loadPU3AS2s:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fghg.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvs.x.ps	a0, ft0, 0
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11global_loadPU3AS2i:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fgwg.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvs.x.ps	a0, ft0, 0
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11global_loadPU3AS2h:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fgbg.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvz.x.ps	a0, ft0, 0
// CHECK-NEXT: 	andi	a0, a0, 255
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11global_loadPU3AS2t:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fghg.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvz.x.ps	a0, ft0, 0
// CHECK-NEXT: 	lui	a1, 16
// CHECK-NEXT: 	addiw	a1, a1, -1
// CHECK-NEXT: 	and	a0, a0, a1
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
// CHECK: _Z11global_loadPU3AS2j:
// CHECK: 	fmv.w.x	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fgwg.ps	ft0, ft0(a0)
// CHECK-NEXT: 	fmvs.x.ps	a0, ft0, 0
// CHECK-NEXT: 	mov.m.x	m1, zero, 1
// CHECK-NEXT: 	ret
