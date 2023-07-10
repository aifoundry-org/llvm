// RUN: %clang -fPIC --target=riscv64-unknown-elf -mcpu=et-soc1-min -mabi=lp64f -O3 -o - -S %s | FileCheck %s

float f1(
  float a,
  float b) {
  return a / b;
}

float __attribute__((vector_size(sizeof(float) * 8))) f2(
  float __attribute__((vector_size(sizeof(float) * 8))) a,
  float __attribute__((vector_size(sizeof(float) * 8))) b) {
  return a / b;
}
// CHECK: f1:
// CHECK: 	mov.m.x	m0, zero, 1
// CHECK-NEXT: 	frcp.ps	ft0, fa1
// CHECK-NEXT: 	fmul.ps	fa0, fa0, ft0, dyn
// CHECK: 	ret
// CHECK: f2:
// CHECK: 	flq2	ft0, 0(a2)
// CHECK-NEXT: 	flq2	ft1, 0(a1)
// CHECK-NEXT: 	mov.m.x	m0, zero, 255
// CHECK-NEXT: 	frcp.ps	ft0, ft0
// CHECK-NEXT: 	fmul.ps	ft0, ft1, ft0, dyn
// CHECK-NEXT: 	fsq2	ft0, 0(a0)
// CHECK-NEXT: 	ret
