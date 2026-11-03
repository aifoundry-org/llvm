//===-- RISCVScheduleXAIF.td - Scheduling Definitions XAIF -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Scheduling classes for the AI Foundry ET (XAIFET) extension.  The classes
// follow the Minion VPU's functional units (VPU Specification §2.2.7,
// Table 11), which is the only structure any implementation of this
// extension has so far:
//
//   TXFMA     : packed and scalar FP arithmetic, packed integer multiply,
//               packed conversions and rounding.  Result at F8.
//   SH-SW     : packed integer ALU/logic/shift/compare, sign inject,
//               swizzle, broadcast, moves, masks.  Result at F3.
//   Trans ROM : reciprocal, rsqrt, exp, log, sin.  Same latency as TXFMA.
//   Load      : flw.ps, fbc.ps, gathers, flq2.  Data through the DCache.
//   Store     : fsw.ps, scatters, fsq2.  Executed in F1 by SH-SW.
//   Atomics   : L2/global atomics, both integer and packed.
//   ToInt     : results delivered to the integer register file or a mask
//               register through the core WB port (fmvz/fmvs.x.ps,
//               feqm/fltm/flem.ps, fltm.pi, fsetm.pi, maskpopc*, mova.x.m).
//   FDiv/FSqrt: fdiv.ps, fsqrt.ps, fdiv/fdivu/frem/fremu.pi (iterative).
//
//===----------------------------------------------------------------------===//

def WriteXAIFTXFMA      : SchedWrite;  // aif.fadd/fsub/fmul.ps, fmul*.pi, fcvt.*, fround/ffrc.ps
def WriteXAIFFMA        : SchedWrite;  // aif.fmadd/fmsub/fnmadd/fnmsub.ps
def WriteXAIFTrans      : SchedWrite;  // aif.frcp/frsq/fexp/flog/fsin.ps
def WriteXAIFFDiv       : SchedWrite;  // aif.fdiv.ps, fdiv/fdivu/frem/fremu.pi
def WriteXAIFFSqrt      : SchedWrite;  // aif.fsqrt.ps
def WriteXAIFSHSW       : SchedWrite;  // packed integer ALU, compares to freg, sgnj, cube*
def WriteXAIFSwizzle    : SchedWrite;  // aif.fswizz.ps, fcmov/fcmovm.ps, fpackrep*, fsat*
def WriteXAIFBroadcast  : SchedWrite;  // aif.fbcx.ps, fbci.ps, fbci.pi (register/immediate)
def WriteXAIFMask       : SchedWrite;  // aif.maskand/or/xor/not, mov.m.x, mova.m.x
def WriteXAIFToInt      : SchedWrite;  // aif.fmvz/fmvs.x.ps, maskpopc*, mova.x.m
def WriteXAIFToMask     : SchedWrite;  // aif.feqm/fltm/flem.ps, fltm.pi, fsetm.pi
def WriteXAIFLD         : SchedWrite;  // aif.flw.ps, fbc.ps, flq2
def WriteXAIFGather     : SchedWrite;  // aif.fg*.ps, fg32*.ps
def WriteXAIFST         : SchedWrite;  // aif.fsw.ps, fsq2
def WriteXAIFScatter    : SchedWrite;  // aif.fsc*.ps, fsc32*.ps
def WriteXAIFAtomic     : SchedWrite;  // aif.amo*.w/d (integer result)
def WriteXAIFFAtomic    : SchedWrite;  // aif.famo*.pi/ps
def WriteXAIFIALU       : SchedWrite;  // aif.packb, aif.bitmixb

def ReadXAIFTXFMA       : SchedRead;
def ReadXAIFFMA         : SchedRead;
def ReadXAIFFMAAddend   : SchedRead;
def ReadXAIFSHSW        : SchedRead;
def ReadXAIFMask        : SchedRead;
def ReadXAIFMemBase     : SchedRead;
def ReadXAIFIndex       : SchedRead;   // gather/scatter index vector or offset GPR
def ReadXAIFStoreData   : SchedRead;
def ReadXAIFAtomicData  : SchedRead;

multiclass UnsupportedSchedXAIF {
let Unsupported = true in {
def : WriteRes<WriteXAIFTXFMA, []>;
def : WriteRes<WriteXAIFFMA, []>;
def : WriteRes<WriteXAIFTrans, []>;
def : WriteRes<WriteXAIFFDiv, []>;
def : WriteRes<WriteXAIFFSqrt, []>;
def : WriteRes<WriteXAIFSHSW, []>;
def : WriteRes<WriteXAIFSwizzle, []>;
def : WriteRes<WriteXAIFBroadcast, []>;
def : WriteRes<WriteXAIFMask, []>;
def : WriteRes<WriteXAIFToInt, []>;
def : WriteRes<WriteXAIFToMask, []>;
def : WriteRes<WriteXAIFLD, []>;
def : WriteRes<WriteXAIFGather, []>;
def : WriteRes<WriteXAIFST, []>;
def : WriteRes<WriteXAIFScatter, []>;
def : WriteRes<WriteXAIFAtomic, []>;
def : WriteRes<WriteXAIFFAtomic, []>;
def : WriteRes<WriteXAIFIALU, []>;

def : ReadAdvance<ReadXAIFTXFMA, 0>;
def : ReadAdvance<ReadXAIFFMA, 0>;
def : ReadAdvance<ReadXAIFFMAAddend, 0>;
def : ReadAdvance<ReadXAIFSHSW, 0>;
def : ReadAdvance<ReadXAIFMask, 0>;
def : ReadAdvance<ReadXAIFMemBase, 0>;
def : ReadAdvance<ReadXAIFIndex, 0>;
def : ReadAdvance<ReadXAIFStoreData, 0>;
def : ReadAdvance<ReadXAIFAtomicData, 0>;
} // Unsupported = true
}
