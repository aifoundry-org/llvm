//==- RISCVSchedETMinion.td - CORE-ET ET-Minion Scheduling Definitions -*- tablegen -*-=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Scheduling model for the CORE-ET ET-Minion core (ET-SoC-1,
// AiNEKKO Erbium).  Sources: the CORE-ET RTL and design documents
// (FE/Intpipe Description, Minion VPU Specification, Minion DCache
// Description) and cycle probes run on ET-SoC-1 silicon.
//
// The Minion is a single-issue, in-order, dual-threaded RV64IMFC core with
// an 8-lane packed-single VPU.  The facts this model encodes:
//
//  * No branch predictor.  Fetch is sequential; every taken branch, jal,
//    jalr and ret redirects the frontend at the TAG stage and costs 12
//    cycles issue-to-issue (11 bubbles).  A not-taken branch is free.
//    Measured: 13.01 cycles for "addi; bnez" loop, 109 for 8 taken jumps.
//  * Integer ALU results bypass at 1 cycle.  Load data is available at WB
//    or later: load-use is 4 cycles (measured 42 = 8*4 + 10 for an 8-deep
//    pointer chase with the loop overhead).
//  * MulDiv is a single non-pipelined unit: 32/64-bit multiply 4/8 cycles,
//    divide 33/65.  A second mul/div stalls until the first completes.
//  * All FP arithmetic, scalar and packed, runs on the VPU's TXFMA unit:
//    7-stage, pipelined, result bypassed from F8 => 7-cycle dependency
//    (measured 63 = 8*7 + 7 for an 8-deep fmul.s chain).  Independent FP
//    ops issue every cycle.
//  * The SH-SW unit (integer/logic/swizzle/sign-inject/moves) returns
//    results from F3 => 2-cycle dependency.
//  * fcvt/feq/flt/fle/fclass/fmv.x.w deliver an integer result through the
//    core's WB port (VPU §2.1.7) after the VPU pipeline: 8 cycles.  These
//    are read from the RTL, not yet probed on silicon.
//  * fdiv.s/fsqrt.s are trapped and emulated (Minion Description; the
//    decoder build forbids them with -mno-fdiv).  Given large latencies.
//  * DCache: 4 KB, 64 B lines, 32 B rows; an aligned 256-bit VPU access is
//    one row, a misaligned one takes two passes through the replay queue.
//    Stores are read-modify-write of the row.
//
//===----------------------------------------------------------------------===//

def ETMinionModel : SchedMachineModel {
  let IssueWidth = 1;          // One instruction per cycle.
  let MicroOpBufferSize = 0;   // In-order.
  let LoadLatency = 4;         // Data at WB, consumer at WB+1.
  let MispredictPenalty = 11;  // Every taken control transfer: 12 cycles
                               // issue-to-issue, i.e. 11 lost slots.
  let CompleteModel = false;
  let UnsupportedFeatures = [HasStdExtZbkb, HasStdExtZbkc, HasStdExtZbkx,
                             HasStdExtZcmt, HasStdExtZknd, HasStdExtZkne,
                             HasStdExtZknh, HasStdExtZksed, HasStdExtZksh,
                             HasStdExtZkr, HasVInstructions, HasVInstructionsI64];
}

//===----------------------------------------------------------------------===//
// Functional units.

let BufferSize = 0 in {
def ETMinionALU     : ProcResource<1>; // Integer ALU (EX stage)
def ETMinionLSU     : ProcResource<1>; // DCache pipeline
def ETMinionBranch  : ProcResource<1>; // Branch resolution (TAG stage)
def ETMinionTXFMA   : ProcResource<1>; // VPU TXFMA: FP arithmetic, 7 stages
def ETMinionSHSW    : ProcResource<1>; // VPU short/swizzle: 2 stages
def ETMinionTrans   : ProcResource<1>; // VPU transcendental ROMs
def ETMinionMulDiv  : ProcResource<1>; // Integer MulDiv, one request at a time
}

//===----------------------------------------------------------------------===//

let SchedModel = ETMinionModel in {

// The core retires integer instructions at WB while loads (which "retire
// even if they miss"), MulDiv (asynchronous write-back) and every VPU
// instruction (result at F8, five stages after WB) are still in flight; a
// consumer waits in ID on the scoreboard, an independent younger
// instruction does not.  RetireOOO tells the in-order simulator exactly
// that: only true dependencies stall, not write-back order.

// Branches and jumps.  A taken transfer costs MispredictPenalty; the
// instruction itself occupies one slot.
def : WriteRes<WriteJmp,  [ETMinionBranch]>;
def : WriteRes<WriteJal,  [ETMinionBranch]>;
def : WriteRes<WriteJalr, [ETMinionBranch]>;

// Integer ALU: 1 cycle, full bypass.
def : WriteRes<WriteIALU32,     [ETMinionALU]>;
def : WriteRes<WriteIALU,       [ETMinionALU]>;
def : WriteRes<WriteShiftImm32, [ETMinionALU]>;
def : WriteRes<WriteShiftImm,   [ETMinionALU]>;
def : WriteRes<WriteShiftReg32, [ETMinionALU]>;
def : WriteRes<WriteShiftReg,   [ETMinionALU]>;

let RetireOOO = 1 in {
// MulDiv: not pipelined (FE/Intpipe §3.4.2: "one request at a time").
def : WriteRes<WriteIMul32, [ETMinionMulDiv]> { let Latency = 4;
                                                let ReleaseAtCycles = [4]; }
def : WriteRes<WriteIMul,   [ETMinionMulDiv]> { let Latency = 8;
                                                let ReleaseAtCycles = [8]; }
def : WriteRes<WriteIDiv32, [ETMinionMulDiv]> { let Latency = 33;
                                                let ReleaseAtCycles = [33]; }
def : WriteRes<WriteIRem32, [ETMinionMulDiv]> { let Latency = 33;
                                                let ReleaseAtCycles = [33]; }
def : WriteRes<WriteIDiv,   [ETMinionMulDiv]> { let Latency = 65;
                                                let ReleaseAtCycles = [65]; }
def : WriteRes<WriteIRem,   [ETMinionMulDiv]> { let Latency = 65;
                                                let ReleaseAtCycles = [65]; }

// Loads: data at WB, consumer at WB+1 (4 cycles).
let Latency = 4 in {
def : WriteRes<WriteLDB,   [ETMinionLSU]>;
def : WriteRes<WriteLDH,   [ETMinionLSU]>;
def : WriteRes<WriteLDW,   [ETMinionLSU]>;
def : WriteRes<WriteLDD,   [ETMinionLSU]>;
def : WriteRes<WriteFLD32, [ETMinionLSU]>;
}

} // RetireOOO = 1
// Stores retire immediately; the row read-modify-write is off the
// critical path unless a load to the same row follows.
def : WriteRes<WriteSTB,   [ETMinionLSU]>;
def : WriteRes<WriteSTH,   [ETMinionLSU]>;
def : WriteRes<WriteSTW,   [ETMinionLSU]>;
def : WriteRes<WriteSTD,   [ETMinionLSU]>;
def : WriteRes<WriteFST32, [ETMinionLSU]>;

let RetireOOO = 1 in {
// Atomics go to the L2 (DCache §3.5): far slower than a hit.
let Latency = 20, ReleaseAtCycles = [20] in {
def : WriteRes<WriteAtomicW,   [ETMinionLSU]>;
def : WriteRes<WriteAtomicD,   [ETMinionLSU]>;
def : WriteRes<WriteAtomicLDW, [ETMinionLSU]>;
def : WriteRes<WriteAtomicLDD, [ETMinionLSU]>;
def : WriteRes<WriteAtomicSTW, [ETMinionLSU]>;
def : WriteRes<WriteAtomicSTD, [ETMinionLSU]>;
}

// Scalar single-precision FP.  Everything arithmetic is TXFMA (7); sign
// inject, min/max and moves into the VPU are SH-SW (2); results back to the
// integer file are 8.
let Latency = 7 in {
def : WriteRes<WriteFAdd32,       [ETMinionTXFMA]>;
def : WriteRes<WriteFMul32,       [ETMinionTXFMA]>;
def : WriteRes<WriteFMA32,        [ETMinionTXFMA]>;
def : WriteRes<WriteFCvtI32ToF32, [ETMinionTXFMA]>;
def : WriteRes<WriteFCvtI64ToF32, [ETMinionTXFMA]>;
}
let Latency = 2 in {
def : WriteRes<WriteFSGNJ32,      [ETMinionSHSW]>;
def : WriteRes<WriteFMinMax32,    [ETMinionSHSW]>;
def : WriteRes<WriteFMovI32ToF32, [ETMinionSHSW]>;
}
let Latency = 8 in {
def : WriteRes<WriteFCvtF32ToI32, [ETMinionTXFMA]>;
def : WriteRes<WriteFCvtF32ToI64, [ETMinionTXFMA]>;
def : WriteRes<WriteFCmp32,       [ETMinionTXFMA]>;
def : WriteRes<WriteFClass32,     [ETMinionTXFMA]>;
def : WriteRes<WriteFMovF32ToI32, [ETMinionSHSW]>;
}
// fdiv.s / fsqrt.s: trap-and-emulate.  Treat as very long, non-pipelined.
def : WriteRes<WriteFDiv32,  [ETMinionTXFMA]> { let Latency = 60;
                                                let ReleaseAtCycles = [60]; }
def : WriteRes<WriteFSqrt32, [ETMinionTXFMA]> { let Latency = 60;
                                                let ReleaseAtCycles = [60]; }

} // RetireOOO = 1
def : WriteRes<WriteCSR, [ETMinionALU]>;
def : WriteRes<WriteNop, []>;

def : InstRW<[WriteIALU], (instrs COPY)>;

//===----------------------------------------------------------------------===//
// XAIFET packed-single extension (VPU Specification §2.2.7, Table 11).

let RetireOOO = 1 in {
let Latency = 7 in {
def : WriteRes<WriteXAIFTXFMA, [ETMinionTXFMA]>;
def : WriteRes<WriteXAIFFMA,   [ETMinionTXFMA]>;
def : WriteRes<WriteXAIFTrans, [ETMinionTrans]>;
}
let Latency = 2 in {
def : WriteRes<WriteXAIFSHSW,      [ETMinionSHSW]>;
def : WriteRes<WriteXAIFSwizzle,   [ETMinionSHSW]>;
def : WriteRes<WriteXAIFBroadcast, [ETMinionSHSW]>;
def : WriteRes<WriteXAIFMask,      [ETMinionSHSW]>;
}
let Latency = 8 in {
def : WriteRes<WriteXAIFToInt,  [ETMinionSHSW]>;
def : WriteRes<WriteXAIFToMask, [ETMinionSHSW]>;
}
// Packed loads: one 32-byte row when aligned; 4-cycle load-use.
let Latency = 4 in {
def : WriteRes<WriteXAIFLD,     [ETMinionLSU]>;
}
// A gather is 8 DCache accesses serialised through the replay queue.
def : WriteRes<WriteXAIFGather, [ETMinionLSU]> { let Latency = 12;
                                                 let ReleaseAtCycles = [8]; }
def : WriteRes<WriteXAIFST,      [ETMinionLSU, ETMinionSHSW]>;
def : WriteRes<WriteXAIFScatter, [ETMinionLSU, ETMinionSHSW]> {
  let ReleaseAtCycles = [8, 1];
}
let Latency = 20, ReleaseAtCycles = [20] in {
def : WriteRes<WriteXAIFAtomic,  [ETMinionLSU]>;
def : WriteRes<WriteXAIFFAtomic, [ETMinionLSU]>;
}
// Iterative packed divide / sqrt (not on the decoder's allowlist; the
// latency is a placeholder until probed).
def : WriteRes<WriteXAIFFDiv,  [ETMinionTXFMA]> { let Latency = 30;
                                                  let ReleaseAtCycles = [30]; }
def : WriteRes<WriteXAIFFSqrt, [ETMinionTXFMA]> { let Latency = 30;
                                                  let ReleaseAtCycles = [30]; }
def : WriteRes<WriteXAIFIALU, [ETMinionALU]>;

} // RetireOOO = 1
def : ReadAdvance<ReadXAIFTXFMA, 0>;
def : ReadAdvance<ReadXAIFFMA, 0>;
def : ReadAdvance<ReadXAIFFMAAddend, 0>;
def : ReadAdvance<ReadXAIFSHSW, 0>;
def : ReadAdvance<ReadXAIFMask, 0>;
def : ReadAdvance<ReadXAIFMemBase, 0>;
def : ReadAdvance<ReadXAIFIndex, 0>;
def : ReadAdvance<ReadXAIFStoreData, 0>;
def : ReadAdvance<ReadXAIFAtomicData, 0>;

//===----------------------------------------------------------------------===//
// Bypass: no forwarding earlier than the writer's latency.

def : ReadAdvance<ReadJmp, 0>;
def : ReadAdvance<ReadJalr, 0>;
def : ReadAdvance<ReadCSR, 0>;
def : ReadAdvance<ReadStoreData, 0>;
def : ReadAdvance<ReadMemBase, 0>;
def : ReadAdvance<ReadIALU, 0>;
def : ReadAdvance<ReadIALU32, 0>;
def : ReadAdvance<ReadShiftImm, 0>;
def : ReadAdvance<ReadShiftImm32, 0>;
def : ReadAdvance<ReadShiftReg, 0>;
def : ReadAdvance<ReadShiftReg32, 0>;
def : ReadAdvance<ReadIDiv, 0>;
def : ReadAdvance<ReadIDiv32, 0>;
def : ReadAdvance<ReadIRem, 0>;
def : ReadAdvance<ReadIRem32, 0>;
def : ReadAdvance<ReadIMul, 0>;
def : ReadAdvance<ReadIMul32, 0>;
def : ReadAdvance<ReadAtomicWA, 0>;
def : ReadAdvance<ReadAtomicWD, 0>;
def : ReadAdvance<ReadAtomicDA, 0>;
def : ReadAdvance<ReadAtomicDD, 0>;
def : ReadAdvance<ReadAtomicLDW, 0>;
def : ReadAdvance<ReadAtomicLDD, 0>;
def : ReadAdvance<ReadAtomicSTW, 0>;
def : ReadAdvance<ReadAtomicSTD, 0>;
def : ReadAdvance<ReadFStoreData, 0>;
def : ReadAdvance<ReadFMemBase, 0>;
def : ReadAdvance<ReadFAdd32, 0>;
def : ReadAdvance<ReadFMul32, 0>;
def : ReadAdvance<ReadFMA32, 0>;
def : ReadAdvance<ReadFMA32Addend, 0>;
def : ReadAdvance<ReadFDiv32, 0>;
def : ReadAdvance<ReadFSqrt32, 0>;
def : ReadAdvance<ReadFCmp32, 0>;
def : ReadAdvance<ReadFSGNJ32, 0>;
def : ReadAdvance<ReadFMinMax32, 0>;
def : ReadAdvance<ReadFCvtF32ToI32, 0>;
def : ReadAdvance<ReadFCvtF32ToI64, 0>;
def : ReadAdvance<ReadFCvtI32ToF32, 0>;
def : ReadAdvance<ReadFCvtI64ToF32, 0>;
def : ReadAdvance<ReadFMovF32ToI32, 0>;
def : ReadAdvance<ReadFMovI32ToF32, 0>;
def : ReadAdvance<ReadFClass32, 0>;

//===----------------------------------------------------------------------===//
// Unsupported extensions.

defm : UnsupportedSchedD;
//defm : UnsupportedSchedZfaWithD;
//defm : UnsupportedSchedZfaWithZfh;
defm : UnsupportedSchedSFB;
defm : UnsupportedSchedV;
defm : UnsupportedSchedZvk;
defm : UnsupportedSchedZba;
defm : UnsupportedSchedZbb;
defm : UnsupportedSchedZbc;
defm : UnsupportedSchedZbs;
defm : UnsupportedSchedZbkb;
defm : UnsupportedSchedZbkx;
defm : UnsupportedSchedZfa;
defm : UnsupportedSchedZfhmin;
defm : UnsupportedSchedZabha;
defm : UnsupportedSchedXsf;
} // SchedModel = ETMinionModel
