//==- RISCVSchedETMinion.td - CORE-ET ET-Minion Scheduling Definitions -*- tablegen -*-=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

def ETMinionModel : SchedMachineModel {
  let IssueWidth = 1;         // Single-issue in-order
  let MicroOpBufferSize = 0;  // In-order core
  let LoadLatency = 4;        // 4 cycles to WB
  let MispredictPenalty = 12; // 12 cycles redirect penalty on taken branch
  let CompleteModel = 0;

  let UnsupportedFeatures = [HasStdExtZbkb, HasStdExtZbkc, HasStdExtZbkx,
                             HasStdExtZcmt, HasStdExtZknd, HasStdExtZkne, HasStdExtZknh,
                             HasStdExtZksed, HasStdExtZksh, HasStdExtZkr];
}

let SchedModel = ETMinionModel in {

// Execution Units / Ports
def ETMinionUnitPipe   : ProcResource<1>;
def ETMinionUnitMulDiv : ProcResource<1>;
def ETMinionUnitFDiv   : ProcResource<1>;

// --- Integer ALU: 1-cycle latency ---
def : WriteRes<WriteIALU,         [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteIALU32,       [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteShiftImm,     [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteShiftImm32,   [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteShiftReg,     [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteShiftReg32,   [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteJmp,          [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteJal,          [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteJalr,         [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteSFB,          [ETMinionUnitPipe]> { let Latency = 1; }

// --- Loads & Stores ---
def : WriteRes<WriteLDB,          [ETMinionUnitPipe]> { let Latency = 4; }
def : WriteRes<WriteLDH,          [ETMinionUnitPipe]> { let Latency = 4; }
def : WriteRes<WriteLDW,          [ETMinionUnitPipe]> { let Latency = 4; }
def : WriteRes<WriteLDD,          [ETMinionUnitPipe]> { let Latency = 4; }
def : WriteRes<WriteFLD32,        [ETMinionUnitPipe]> { let Latency = 4; }
def : WriteRes<WriteSTB,          [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteSTH,          [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteSTW,          [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteSTD,          [ETMinionUnitPipe]> { let Latency = 1; }
def : WriteRes<WriteFST32,        [ETMinionUnitPipe]> { let Latency = 1; }

// --- Integer Multiply / Divide (Scalar MulDiv unit) ---
def : WriteRes<WriteIMul32, [ETMinionUnitPipe, ETMinionUnitMulDiv]> {
  let Latency = 4;
  let ReleaseAtCycles = [1, 3];
}
def : WriteRes<WriteIMul,   [ETMinionUnitPipe, ETMinionUnitMulDiv]> {
  let Latency = 8;
  let ReleaseAtCycles = [1, 7];
}
def : WriteRes<WriteIDiv32, [ETMinionUnitPipe, ETMinionUnitMulDiv]> {
  let Latency = 33;
  let ReleaseAtCycles = [1, 32];
}
def : WriteRes<WriteIDiv,   [ETMinionUnitPipe, ETMinionUnitMulDiv]> {
  let Latency = 65;
  let ReleaseAtCycles = [1, 64];
}
def : WriteRes<WriteIRem32, [ETMinionUnitPipe, ETMinionUnitMulDiv]> {
  let Latency = 33;
  let ReleaseAtCycles = [1, 32];
}
def : WriteRes<WriteIRem,   [ETMinionUnitPipe, ETMinionUnitMulDiv]> {
  let Latency = 65;
  let ReleaseAtCycles = [1, 64];
}

// --- Floating Point Arithmetic (Single-Precision) ---
def : WriteRes<WriteFAdd32,       [ETMinionUnitPipe]> { let Latency = 7; }
def : WriteRes<WriteFMul32,       [ETMinionUnitPipe]> { let Latency = 7; }
def : WriteRes<WriteFMA32,        [ETMinionUnitPipe]> { let Latency = 7; }
def : WriteRes<WriteFCvtI32ToF32, [ETMinionUnitPipe]> { let Latency = 7; }
def : WriteRes<WriteFCvtI64ToF32, [ETMinionUnitPipe]> { let Latency = 7; }
def : WriteRes<WriteFMovI32ToF32, [ETMinionUnitPipe]> { let Latency = 7; }
def : WriteRes<WriteFSGNJ32,      [ETMinionUnitPipe]> { let Latency = 2; }
def : WriteRes<WriteFMinMax32,    [ETMinionUnitPipe]> { let Latency = 7; }
def : WriteRes<WriteFCmp32,       [ETMinionUnitPipe]> { let Latency = 8; }
def : WriteRes<WriteFCvtF32ToI32, [ETMinionUnitPipe]> { let Latency = 8; }
def : WriteRes<WriteFCvtF32ToI64, [ETMinionUnitPipe]> { let Latency = 8; }
def : WriteRes<WriteFMovF32ToI32, [ETMinionUnitPipe]> { let Latency = 8; }
def : WriteRes<WriteFClass32,     [ETMinionUnitPipe]> { let Latency = 8; }

// --- Floating Point Div / Sqrt ---
def : WriteRes<WriteFDiv32,  [ETMinionUnitPipe, ETMinionUnitFDiv]> {
  let Latency = 20;
  let ReleaseAtCycles = [1, 19];
}
def : WriteRes<WriteFSqrt32, [ETMinionUnitPipe, ETMinionUnitFDiv]> {
  let Latency = 25;
  let ReleaseAtCycles = [1, 24];
}

// --- Others ---
def : WriteRes<WriteCSR,       [ETMinionUnitPipe]>;
def : WriteRes<WriteNop,       []>;
def : InstRW<[WriteIALU], (instrs COPY)>;

// --- Bypass and Advance ---
def : ReadAdvance<ReadJmp,          0>;
def : ReadAdvance<ReadJalr,         0>;
def : ReadAdvance<ReadCSR,          0>;
def : ReadAdvance<ReadStoreData,    0>;
def : ReadAdvance<ReadMemBase,      0>;
def : ReadAdvance<ReadIALU,         0>;
def : ReadAdvance<ReadIALU32,       0>;
def : ReadAdvance<ReadShiftImm,     0>;
def : ReadAdvance<ReadShiftImm32,   0>;
def : ReadAdvance<ReadShiftReg,     0>;
def : ReadAdvance<ReadShiftReg32,   0>;
def : ReadAdvance<ReadIDiv,         0>;
def : ReadAdvance<ReadIDiv32,       0>;
def : ReadAdvance<ReadIRem,         0>;
def : ReadAdvance<ReadIRem32,       0>;
def : ReadAdvance<ReadIMul,         0>;
def : ReadAdvance<ReadIMul32,       0>;
def : ReadAdvance<ReadSFBALU,       0>;
def : ReadAdvance<ReadSFBJmp,       0>;

// 32-bit FP Read Advances
def : ReadAdvance<ReadFMemBase,     0>;
def : ReadAdvance<ReadFStoreData,   0>;
def : ReadAdvance<ReadFAdd32,       0>;
def : ReadAdvance<ReadFMul32,       0>;
def : ReadAdvance<ReadFMA32,        0>;
def : ReadAdvance<ReadFMA32Addend,  0>;
def : ReadAdvance<ReadFDiv32,       0>;
def : ReadAdvance<ReadFSqrt32,      0>;
def : ReadAdvance<ReadFCmp32,       0>;
def : ReadAdvance<ReadFSGNJ32,      0>;
def : ReadAdvance<ReadFMinMax32,    0>;
def : ReadAdvance<ReadFCvtF32ToI32, 0>;
def : ReadAdvance<ReadFCvtF32ToI64, 0>;
def : ReadAdvance<ReadFCvtI32ToF32, 0>;
def : ReadAdvance<ReadFCvtI64ToF32, 0>;
def : ReadAdvance<ReadFMovF32ToI32, 0>;
def : ReadAdvance<ReadFMovI32ToF32, 0>;
def : ReadAdvance<ReadFClass32,     0>;

//===----------------------------------------------------------------------===//
// Unsupported Extensions Multiclasses
//===----------------------------------------------------------------------===//
defm : UnsupportedSchedA;
defm : UnsupportedSchedD;
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