# RUN: llvm-mc -triple=riscv64 --preserve-comments \
# RUN:    %s \
# RUN:    | FileCheck %s

/*c0*/ li /*c1*/ a0 /*c2*/ , /*c3*/ 0 /*c4*/
# CHECK: li      a0, 0   # c0    # c1    # c2    # c3
