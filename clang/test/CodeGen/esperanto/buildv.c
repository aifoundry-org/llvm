// RUN: %clang_cc1 -triple riscv64-unknown-unknown-elf -S -target-cpu et-soc1-min -O2 -o - %s | FileCheck %s
typedef unsigned Vec __attribute__((vector_size(32)));

#define example(name, e0, e1, e2, e3, e4, e5, e6, e7) \
  Vec build##name(unsigned x, unsigned y) {           \
    Vec V = {e0, e1, e2, e3, e4, e5, e6, e7};         \
    return V;                                         \
  }

// 5 distinct values, all separately set
example(0, 3, 5, 10, x, x, y, 3, 10);
// 3 adds and one non-immediate
example(1, 3, 4, 5, 6, x, 8, x, 10);
// 4 adds, and one non-immediate
example(2, 6, 8, 2 + 6 + 128, 12, x, 16, x, 20);
// 3 unique values
example(3, 0, 2, 5, 2, 0, 5, 0, 0);
// 3 adds
example(4, 0, 2, 1, 3, 0, 1, 2, 1023);
// stress 20-bit limit
example(5, 0, 2, 1, 3, (1 << 19), (1 << 19) - 1, -(1 << 19), -(1 << 19) - 1);
// too many adds, treat as non-immediate
example(6, 0, 1, 2, 4, 8, 16, 32, 64);
// 5 adds
example(7, 0, 1, 2, 4, 8, 9, 32, 33);
// negative minimum, 4 adds, one non-immediate
example(8, 3, 4, 5, 6, x, 8, x, -4)
// no immediates ...
example(9, x, y, x, x, y, y, x, 1<<19)
// CHECK: build0:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft0, 3
// CHECK-NEXT: 	mov.m.x	m0, zero, 2
// CHECK-NEXT: 	fbci.pi	ft0, 5
// CHECK-NEXT: 	mov.m.x	m0, zero, 132
// CHECK-NEXT: 	fbci.pi	ft0, 10
// CHECK-NEXT: 	mov.m.x	m0, zero, 24
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 32
// CHECK-NEXT: 	fbcx.ps	ft0, a2
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: build1:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft0, 3
// CHECK-NEXT: 	mov.m.x	m0, zero, 140
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
// CHECK-NEXT: 	mov.m.x	m0, zero, 160
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
// CHECK-NEXT: 	mov.m.x	m0, zero, 170
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
// CHECK-NEXT: 	mov.m.x	m0, zero, 80
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: build2:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft0, 6
// CHECK-NEXT: 	mov.m.x	m0, zero, 4
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 128
// CHECK-NEXT: 	mov.m.x	m0, zero, 136
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
// CHECK-NEXT: 	mov.m.x	m0, zero, 160
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 8
// CHECK-NEXT: 	mov.m.x	m0, zero, 174
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
// CHECK-NEXT: 	mov.m.x	m0, zero, 80
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: build3:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft0, 0
// CHECK-NEXT: 	mov.m.x	m0, zero, 10
// CHECK-NEXT: 	fbci.pi	ft0, 2
// CHECK-NEXT: 	mov.m.x	m0, zero, 36
// CHECK-NEXT: 	fbci.pi	ft0, 5
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: build4:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft0, 0
// CHECK-NEXT: 	mov.m.x	m0, zero, 44
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
// CHECK-NEXT: 	mov.m.x	m0, zero, 74
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
// CHECK-NEXT: 	mov.m.x	m0, zero, 128
// CHECK-NEXT: 	addi	a1, zero, 1023
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: build5:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft0, -524288
// CHECK-NEXT: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	fbcx.ps	ft0, zero
// CHECK-NEXT: 	mov.m.x	m0, zero, 2
// CHECK-NEXT: 	addi	a1, zero, 2
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 4
// CHECK-NEXT: 	addi	a1, zero, 1
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 8
// CHECK-NEXT: 	addi	a1, zero, 3
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 16
// CHECK-NEXT: 	lui	a1, 128
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 32
// CHECK-NEXT: 	addiw	a1, a1, -1
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 128
// CHECK-NEXT: 	lui	a1, 1048448
// CHECK-NEXT: 	addiw	a1, a1, -1
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: build6:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft0, 0
// CHECK-NEXT: 	mov.m.x	m0, zero, 2
// CHECK-NEXT: 	fbci.pi	ft0, 1
// CHECK-NEXT: 	mov.m.x	m0, zero, 4
// CHECK-NEXT: 	fbci.pi	ft0, 2
// CHECK-NEXT: 	mov.m.x	m0, zero, 8
// CHECK-NEXT: 	fbci.pi	ft0, 4
// CHECK-NEXT: 	mov.m.x	m0, zero, 16
// CHECK-NEXT: 	fbci.pi	ft0, 8
// CHECK-NEXT: 	mov.m.x	m0, zero, 32
// CHECK-NEXT: 	fbci.pi	ft0, 16
// CHECK-NEXT: 	mov.m.x	m0, zero, 64
// CHECK-NEXT: 	fbci.pi	ft0, 32
// CHECK-NEXT: 	mov.m.x	m0, zero, 128
// CHECK-NEXT: 	fbci.pi	ft0, 64
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: build7:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft0, 0
// CHECK-NEXT: 	mov.m.x	m0, zero, 4
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
// CHECK-NEXT: 	mov.m.x	m0, zero, 8
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
// CHECK-NEXT: 	mov.m.x	m0, zero, 48
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 8
// CHECK-NEXT: 	mov.m.x	m0, zero, 162
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
// CHECK-NEXT: 	mov.m.x	m0, zero, 192
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 32
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: build8:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbci.pi	ft0, -4
// CHECK-NEXT: 	mov.m.x	m0, zero, 5
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 1
// CHECK-NEXT: 	mov.m.x	m0, zero, 9
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 2
// CHECK-NEXT: 	mov.m.x	m0, zero, 33
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 4
// CHECK-NEXT: 	mov.m.x	m0, zero, 46
// CHECK-NEXT: 	faddi.pi	ft0, ft0, 8
// CHECK-NEXT: 	mov.m.x	m0, zero, 80
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
// CHECK: build9:
// CHECK: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	mov.m.x	m0, zero, 50
// CHECK-NEXT: 	fbcx.ps	ft0, a2
// CHECK-NEXT: 	mov.m.x	m0, zero, 128
// CHECK-NEXT: 	lui	a1, 128
// CHECK-NEXT: 	fbcx.ps	ft0, a1
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
