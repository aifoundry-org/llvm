//===-- RISCVISelDAGToDAG.cpp - A dag to dag inst selector for RISCV ------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines an instruction selector for the RISCV target.
//
//===----------------------------------------------------------------------===//

#include "RISCVISelDAGToDAG.h"
#include "MCTargetDesc/RISCVMCTargetDesc.h"
#include "Utils/RISCVMatInt.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/IR/IntrinsicsRISCV.h"
#include "llvm/Support/Alignment.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "riscv-isel"

#ifdef ESPERANTO
static cl::opt<bool> OptimizeMasksFlag(DEBUG_TYPE "-opt-masks", cl::init(true));
static cl::opt<unsigned>
    OptimizeMasksLimit(DEBUG_TYPE "-opt-masks-limit",
                       cl::init(std::numeric_limits<unsigned>::max()));
#endif

void RISCVDAGToDAGISel::PostprocessISelDAG() { doPeepholeLoadStoreADDI(); }

#ifdef ESPERANTO
void RISCVDAGToDAGISel::PreprocessISelDAG() {
  if (Subtarget->hasEsperanto())
    doEsperantoRewrites();
}
#endif

static SDNode *selectImm(SelectionDAG *CurDAG, const SDLoc &DL, int64_t Imm,
                         MVT XLenVT) {
  RISCVMatInt::InstSeq Seq;
  RISCVMatInt::generateInstSeq(Imm, XLenVT == MVT::i64, Seq);

  SDNode *Result = nullptr;
  SDValue SrcReg = CurDAG->getRegister(RISCV::X0, XLenVT);
  for (RISCVMatInt::Inst &Inst : Seq) {
    SDValue SDImm = CurDAG->getTargetConstant(Inst.Imm, DL, XLenVT);
    if (Inst.Opc == RISCV::LUI)
      Result = CurDAG->getMachineNode(RISCV::LUI, DL, XLenVT, SDImm);
    else
      Result = CurDAG->getMachineNode(Inst.Opc, DL, XLenVT, SrcReg, SDImm);

    // Only the first instruction has X0 as its source.
    SrcReg = SDValue(Result, 0);
  }

  return Result;
}

// Returns true if the Node is an ISD::AND with a constant argument. If so,
// set Mask to that constant value.
static bool isConstantMask(SDNode *Node, uint64_t &Mask) {
  if (Node->getOpcode() == ISD::AND &&
      Node->getOperand(1).getOpcode() == ISD::Constant) {
    Mask = cast<ConstantSDNode>(Node->getOperand(1))->getZExtValue();
    return true;
  }
  return false;
}

void RISCVDAGToDAGISel::Select(SDNode *Node) {
  // If we have a custom node, we have already selected.
  if (Node->isMachineOpcode()) {
    LLVM_DEBUG(dbgs() << "== "; Node->dump(CurDAG); dbgs() << "\n");
    Node->setNodeId(-1);
    return;
  }

  // Instruction Selection not handled by the auto-generated tablegen selection
  // should be handled here.
  unsigned Opcode = Node->getOpcode();
  MVT XLenVT = Subtarget->getXLenVT();
  SDLoc DL(Node);
  EVT VT = Node->getValueType(0);

  switch (Opcode) {
  case ISD::ADD: {
    // Optimize (add r, imm) to (addi (addi r, imm0) imm1) if applicable. The
    // immediate must be in specific ranges and have a single use.
    if (auto *ConstOp = dyn_cast<ConstantSDNode>(Node->getOperand(1))) {
      if (!(ConstOp->hasOneUse()))
        break;
      // The imm must be in range [-4096,-2049] or [2048,4094].
      int64_t Imm = ConstOp->getSExtValue();
      if (!(-4096 <= Imm && Imm <= -2049) && !(2048 <= Imm && Imm <= 4094))
        break;
      // Break the imm to imm0+imm1.
      SDLoc DL(Node);
      EVT VT = Node->getValueType(0);
      const SDValue ImmOp0 = CurDAG->getTargetConstant(Imm - Imm / 2, DL, VT);
      const SDValue ImmOp1 = CurDAG->getTargetConstant(Imm / 2, DL, VT);
      auto *NodeAddi0 = CurDAG->getMachineNode(RISCV::ADDI, DL, VT,
                                               Node->getOperand(0), ImmOp0);
      auto *NodeAddi1 = CurDAG->getMachineNode(RISCV::ADDI, DL, VT,
                                               SDValue(NodeAddi0, 0), ImmOp1);
      ReplaceNode(Node, NodeAddi1);
      return;
    }
    break;
  }
  case ISD::Constant: {
    auto ConstNode = cast<ConstantSDNode>(Node);
    if (VT == XLenVT && ConstNode->isNullValue()) {
      SDValue New = CurDAG->getCopyFromReg(CurDAG->getEntryNode(), SDLoc(Node),
                                           RISCV::X0, XLenVT);
      ReplaceNode(Node, New.getNode());
      return;
    }
    int64_t Imm = ConstNode->getSExtValue();
    if (XLenVT == MVT::i64) {
      ReplaceNode(Node, selectImm(CurDAG, SDLoc(Node), Imm, XLenVT));
      return;
    }
    break;
  }
  case ISD::FrameIndex: {
    SDValue Imm = CurDAG->getTargetConstant(0, DL, XLenVT);
    int FI = cast<FrameIndexSDNode>(Node)->getIndex();
    SDValue TFI = CurDAG->getTargetFrameIndex(FI, VT);
    ReplaceNode(Node, CurDAG->getMachineNode(RISCV::ADDI, DL, VT, TFI, Imm));
    return;
  }
  case ISD::SRL: {
    if (!Subtarget->is64Bit())
      break;
    SDValue Op0 = Node->getOperand(0);
    SDValue Op1 = Node->getOperand(1);
    uint64_t Mask;
    // Match (srl (and val, mask), imm) where the result would be a
    // zero-extended 32-bit integer. i.e. the mask is 0xffffffff or the result
    // is equivalent to this (SimplifyDemandedBits may have removed lower bits
    // from the mask that aren't necessary due to the right-shifting).
    if (Op1.getOpcode() == ISD::Constant &&
        isConstantMask(Op0.getNode(), Mask)) {
      uint64_t ShAmt = cast<ConstantSDNode>(Op1.getNode())->getZExtValue();

      if ((Mask | maskTrailingOnes<uint64_t>(ShAmt)) == 0xffffffff) {
        SDValue ShAmtVal =
            CurDAG->getTargetConstant(ShAmt, SDLoc(Node), XLenVT);
        CurDAG->SelectNodeTo(Node, RISCV::SRLIW, XLenVT, Op0.getOperand(0),
                             ShAmtVal);
        return;
      }
    }
    break;
  }
  case RISCVISD::READ_CYCLE_WIDE:
    assert(!Subtarget->is64Bit() && "READ_CYCLE_WIDE is only used on riscv32");

    ReplaceNode(Node, CurDAG->getMachineNode(RISCV::ReadCycleWide, DL, MVT::i32,
                                             MVT::i32, MVT::Other,
                                             Node->getOperand(0)));
    return;
  }

  // Select the default instruction.
  SelectCode(Node);
}

bool RISCVDAGToDAGISel::SelectInlineAsmMemoryOperand(
    const SDValue &Op, unsigned ConstraintID, std::vector<SDValue> &OutOps) {
  switch (ConstraintID) {
  case InlineAsm::Constraint_m:
    // We just support simple memory operands that have a single address
    // operand and need no special handling.
    OutOps.push_back(Op);
    return false;
  case InlineAsm::Constraint_A:
    OutOps.push_back(Op);
    return false;
  default:
    break;
  }

  return true;
}

bool RISCVDAGToDAGISel::SelectAddrFI(SDValue Addr, SDValue &Base) {
  if (auto FIN = dyn_cast<FrameIndexSDNode>(Addr)) {
    Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), Subtarget->getXLenVT());
    return true;
  }
  return false;
}

// Check that it is a SLOI (Shift Left Ones Immediate). We first check that
// it is the right node tree:
//
//  (OR (SHL RS1, VC2), VC1)
//
// and then we check that VC1, the mask used to fill with ones, is compatible
// with VC2, the shamt:
//
//  VC1 == maskTrailingOnes<uint64_t>(VC2)

bool RISCVDAGToDAGISel::SelectSLOI(SDValue N, SDValue &RS1, SDValue &Shamt) {
  MVT XLenVT = Subtarget->getXLenVT();
  if (N.getOpcode() == ISD::OR) {
    SDValue Or = N;
    if (Or.getOperand(0).getOpcode() == ISD::SHL) {
      SDValue Shl = Or.getOperand(0);
      if (isa<ConstantSDNode>(Shl.getOperand(1)) &&
          isa<ConstantSDNode>(Or.getOperand(1))) {
        if (XLenVT == MVT::i64) {
          uint64_t VC1 = Or.getConstantOperandVal(1);
          uint64_t VC2 = Shl.getConstantOperandVal(1);
          if (VC1 == maskTrailingOnes<uint64_t>(VC2)) {
            RS1 = Shl.getOperand(0);
            Shamt = CurDAG->getTargetConstant(VC2, SDLoc(N),
                           Shl.getOperand(1).getValueType());
            return true;
          }
        }
        if (XLenVT == MVT::i32) {
          uint32_t VC1 = Or.getConstantOperandVal(1);
          uint32_t VC2 = Shl.getConstantOperandVal(1);
          if (VC1 == maskTrailingOnes<uint32_t>(VC2)) {
            RS1 = Shl.getOperand(0);
            Shamt = CurDAG->getTargetConstant(VC2, SDLoc(N),
                           Shl.getOperand(1).getValueType());
            return true;
          }
        }
      }
    }
  }
  return false;
}

// Check that it is a SROI (Shift Right Ones Immediate). We first check that
// it is the right node tree:
//
//  (OR (SRL RS1, VC2), VC1)
//
// and then we check that VC1, the mask used to fill with ones, is compatible
// with VC2, the shamt:
//
//  VC1 == maskLeadingOnes<uint64_t>(VC2)

bool RISCVDAGToDAGISel::SelectSROI(SDValue N, SDValue &RS1, SDValue &Shamt) {
  MVT XLenVT = Subtarget->getXLenVT();
  if (N.getOpcode() == ISD::OR) {
    SDValue Or = N;
    if (Or.getOperand(0).getOpcode() == ISD::SRL) {
      SDValue Srl = Or.getOperand(0);
      if (isa<ConstantSDNode>(Srl.getOperand(1)) &&
          isa<ConstantSDNode>(Or.getOperand(1))) {
        if (XLenVT == MVT::i64) {
          uint64_t VC1 = Or.getConstantOperandVal(1);
          uint64_t VC2 = Srl.getConstantOperandVal(1);
          if (VC1 == maskLeadingOnes<uint64_t>(VC2)) {
            RS1 = Srl.getOperand(0);
            Shamt = CurDAG->getTargetConstant(VC2, SDLoc(N),
                           Srl.getOperand(1).getValueType());
            return true;
          }
        }
        if (XLenVT == MVT::i32) {
          uint32_t VC1 = Or.getConstantOperandVal(1);
          uint32_t VC2 = Srl.getConstantOperandVal(1);
          if (VC1 == maskLeadingOnes<uint32_t>(VC2)) {
            RS1 = Srl.getOperand(0);
            Shamt = CurDAG->getTargetConstant(VC2, SDLoc(N),
                           Srl.getOperand(1).getValueType());
            return true;
          }
        }
      }
    }
  }
  return false;
}

// Check that it is a RORI (Rotate Right Immediate). We first check that
// it is the right node tree:
//
//  (ROTL RS1, VC)
//
// The compiler translates immediate rotations to the right given by the call
// to the rotateright32/rotateright64 intrinsics as rotations to the left.
// Since the rotation to the left can be easily emulated as a rotation to the
// right by negating the constant, there is no encoding for ROLI.
// We then select the immediate left rotations as RORI by the complementary
// constant:
//
//  Shamt == XLen - VC

bool RISCVDAGToDAGISel::SelectRORI(SDValue N, SDValue &RS1, SDValue &Shamt) {
  MVT XLenVT = Subtarget->getXLenVT();
  if (N.getOpcode() == ISD::ROTL) {
    if (isa<ConstantSDNode>(N.getOperand(1))) {
      if (XLenVT == MVT::i64) {
        uint64_t VC = N.getConstantOperandVal(1);
        Shamt = CurDAG->getTargetConstant((64 - VC), SDLoc(N),
                                          N.getOperand(1).getValueType());
        RS1 = N.getOperand(0);
        return true;
      }
      if (XLenVT == MVT::i32) {
        uint32_t VC = N.getConstantOperandVal(1);
        Shamt = CurDAG->getTargetConstant((32 - VC), SDLoc(N),
                                          N.getOperand(1).getValueType());
        RS1 = N.getOperand(0);
        return true;
      }
    }
  }
  return false;
}


// Check that it is a SLLIUW (Shift Logical Left Immediate Unsigned i32
// on RV64).
// SLLIUW is the same as SLLI except for the fact that it clears the bits
// XLEN-1:32 of the input RS1 before shifting.
// We first check that it is the right node tree:
//
//  (AND (SHL RS1, VC2), VC1)
//
// We check that VC2, the shamt is less than 32, otherwise the pattern is
// exactly the same as SLLI and we give priority to that.
// Eventually we check that that VC1, the mask used to clear the upper 32 bits
// of RS1, is correct:
//
//  VC1 == (0xFFFFFFFF << VC2)

bool RISCVDAGToDAGISel::SelectSLLIUW(SDValue N, SDValue &RS1, SDValue &Shamt) {
  if (N.getOpcode() == ISD::AND && Subtarget->getXLenVT() == MVT::i64) {
    SDValue And = N;
    if (And.getOperand(0).getOpcode() == ISD::SHL) {
      SDValue Shl = And.getOperand(0);
      if (isa<ConstantSDNode>(Shl.getOperand(1)) &&
          isa<ConstantSDNode>(And.getOperand(1))) {
        uint64_t VC1 = And.getConstantOperandVal(1);
        uint64_t VC2 = Shl.getConstantOperandVal(1);
        if (VC2 < 32 && VC1 == ((uint64_t)0xFFFFFFFF << VC2)) {
          RS1 = Shl.getOperand(0);
          Shamt = CurDAG->getTargetConstant(VC2, SDLoc(N),
                                            Shl.getOperand(1).getValueType());
          return true;
        }
      }
    }
  }
  return false;
}

// Check that it is a SLOIW (Shift Left Ones Immediate i32 on RV64).
// We first check that it is the right node tree:
//
//  (SIGN_EXTEND_INREG (OR (SHL RS1, VC2), VC1))
//
// and then we check that VC1, the mask used to fill with ones, is compatible
// with VC2, the shamt:
//
//  VC1 == maskTrailingOnes<uint32_t>(VC2)

bool RISCVDAGToDAGISel::SelectSLOIW(SDValue N, SDValue &RS1, SDValue &Shamt) {
  if (Subtarget->getXLenVT() == MVT::i64 &&
      N.getOpcode() == ISD::SIGN_EXTEND_INREG &&
      cast<VTSDNode>(N.getOperand(1))->getVT() == MVT::i32) {
    if (N.getOperand(0).getOpcode() == ISD::OR) {
      SDValue Or = N.getOperand(0);
      if (Or.getOperand(0).getOpcode() == ISD::SHL) {
        SDValue Shl = Or.getOperand(0);
        if (isa<ConstantSDNode>(Shl.getOperand(1)) &&
            isa<ConstantSDNode>(Or.getOperand(1))) {
          uint32_t VC1 = Or.getConstantOperandVal(1);
          uint32_t VC2 = Shl.getConstantOperandVal(1);
          if (VC1 == maskTrailingOnes<uint32_t>(VC2)) {
            RS1 = Shl.getOperand(0);
            Shamt = CurDAG->getTargetConstant(VC2, SDLoc(N),
                                              Shl.getOperand(1).getValueType());
            return true;
          }
        }
      }
    }
  }
  return false;
}

// Check that it is a SROIW (Shift Right Ones Immediate i32 on RV64).
// We first check that it is the right node tree:
//
//  (OR (SHL RS1, VC2), VC1)
//
// and then we check that VC1, the mask used to fill with ones, is compatible
// with VC2, the shamt:
//
//  VC1 == maskLeadingOnes<uint32_t>(VC2)

bool RISCVDAGToDAGISel::SelectSROIW(SDValue N, SDValue &RS1, SDValue &Shamt) {
  if (N.getOpcode() == ISD::OR && Subtarget->getXLenVT() == MVT::i64) {
    SDValue Or = N;
    if (Or.getOperand(0).getOpcode() == ISD::SRL) {
      SDValue Srl = Or.getOperand(0);
      if (isa<ConstantSDNode>(Srl.getOperand(1)) &&
          isa<ConstantSDNode>(Or.getOperand(1))) {
        uint32_t VC1 = Or.getConstantOperandVal(1);
        uint32_t VC2 = Srl.getConstantOperandVal(1);
        if (VC1 == maskLeadingOnes<uint32_t>(VC2)) {
          RS1 = Srl.getOperand(0);
          Shamt = CurDAG->getTargetConstant(VC2, SDLoc(N),
                                            Srl.getOperand(1).getValueType());
          return true;
        }
      }
    }
  }
  return false;
}

// Check that it is a RORIW (i32 Right Rotate Immediate on RV64).
// We first check that it is the right node tree:
//
//  (SIGN_EXTEND_INREG (OR (SHL (AsserSext RS1, i32), VC2),
//                         (SRL (AND (AssertSext RS2, i32), VC3), VC1)))
//
// Then we check that the constant operands respect these constraints:
//
// VC2 == 32 - VC1
// VC3 == maskLeadingOnes<uint32_t>(VC2)
//
// being VC1 the Shamt we need, VC2 the complementary of Shamt over 32
// and VC3 a 32 bit mask of (32 - VC1) leading ones.

bool RISCVDAGToDAGISel::SelectRORIW(SDValue N, SDValue &RS1, SDValue &Shamt) {
  if (N.getOpcode() == ISD::SIGN_EXTEND_INREG &&
      Subtarget->getXLenVT() == MVT::i64 &&
      cast<VTSDNode>(N.getOperand(1))->getVT() == MVT::i32) {
    if (N.getOperand(0).getOpcode() == ISD::OR) {
      SDValue Or = N.getOperand(0);
      if (Or.getOperand(0).getOpcode() == ISD::SHL &&
          Or.getOperand(1).getOpcode() == ISD::SRL) {
        SDValue Shl = Or.getOperand(0);
        SDValue Srl = Or.getOperand(1);
        if (Srl.getOperand(0).getOpcode() == ISD::AND) {
          SDValue And = Srl.getOperand(0);
          if (isa<ConstantSDNode>(Srl.getOperand(1)) &&
              isa<ConstantSDNode>(Shl.getOperand(1)) &&
              isa<ConstantSDNode>(And.getOperand(1))) {
            uint32_t VC1 = Srl.getConstantOperandVal(1);
            uint32_t VC2 = Shl.getConstantOperandVal(1);
            uint32_t VC3 = And.getConstantOperandVal(1);
            if (VC2 == (32 - VC1) &&
                VC3 == maskLeadingOnes<uint32_t>(VC2)) {
              RS1 = Shl.getOperand(0);
              Shamt = CurDAG->getTargetConstant(VC1, SDLoc(N),
                                              Srl.getOperand(1).getValueType());
              return true;
            }
          }
        }
      }
    }
  }
  return false;
}

// Check that it is a FSRIW (i32 Funnel Shift Right Immediate on RV64).
// We first check that it is the right node tree:
//
//  (SIGN_EXTEND_INREG (OR (SHL (AsserSext RS1, i32), VC2),
//                         (SRL (AND (AssertSext RS2, i32), VC3), VC1)))
//
// Then we check that the constant operands respect these constraints:
//
// VC2 == 32 - VC1
// VC3 == maskLeadingOnes<uint32_t>(VC2)
//
// being VC1 the Shamt we need, VC2 the complementary of Shamt over 32
// and VC3 a 32 bit mask of (32 - VC1) leading ones.

bool RISCVDAGToDAGISel::SelectFSRIW(SDValue N, SDValue &RS1, SDValue &RS2,
                                    SDValue &Shamt) {
  if (N.getOpcode() == ISD::SIGN_EXTEND_INREG &&
      Subtarget->getXLenVT() == MVT::i64 &&
      cast<VTSDNode>(N.getOperand(1))->getVT() == MVT::i32) {
    if (N.getOperand(0).getOpcode() == ISD::OR) {
      SDValue Or = N.getOperand(0);
      if (Or.getOperand(0).getOpcode() == ISD::SHL &&
          Or.getOperand(1).getOpcode() == ISD::SRL) {
        SDValue Shl = Or.getOperand(0);
        SDValue Srl = Or.getOperand(1);
        if (Srl.getOperand(0).getOpcode() == ISD::AND) {
          SDValue And = Srl.getOperand(0);
          if (isa<ConstantSDNode>(Srl.getOperand(1)) &&
              isa<ConstantSDNode>(Shl.getOperand(1)) &&
              isa<ConstantSDNode>(And.getOperand(1))) {
            uint32_t VC1 = Srl.getConstantOperandVal(1);
            uint32_t VC2 = Shl.getConstantOperandVal(1);
            uint32_t VC3 = And.getConstantOperandVal(1);
            if (VC2 == (32 - VC1) &&
                VC3 == maskLeadingOnes<uint32_t>(VC2)) {
              RS1 = Shl.getOperand(0);
              RS2 = And.getOperand(0);
              Shamt = CurDAG->getTargetConstant(VC1, SDLoc(N),
                                              Srl.getOperand(1).getValueType());
              return true;
            }
          }
        }
      }
    }
  }
  return false;
}

// Merge an ADDI into the offset of a load/store instruction where possible.
// (load (addi base, off1), off2) -> (load base, off1+off2)
// (store val, (addi base, off1), off2) -> (store val, base, off1+off2)
// This is possible when off1+off2 fits a 12-bit immediate.
void RISCVDAGToDAGISel::doPeepholeLoadStoreADDI() {
  SelectionDAG::allnodes_iterator Position(CurDAG->getRoot().getNode());
  ++Position;

  while (Position != CurDAG->allnodes_begin()) {
    SDNode *N = &*--Position;
    // Skip dead nodes and any non-machine opcodes.
    if (N->use_empty() || !N->isMachineOpcode())
      continue;

    int OffsetOpIdx;
    int BaseOpIdx;

    // Only attempt this optimisation for I-type loads and S-type stores.
    switch (N->getMachineOpcode()) {
    default:
      continue;
    case RISCV::LB:
    case RISCV::LH:
    case RISCV::LW:
    case RISCV::LBU:
    case RISCV::LHU:
    case RISCV::LWU:
    case RISCV::LD:
    case RISCV::FLW:
    case RISCV::FLD:
      BaseOpIdx = 0;
      OffsetOpIdx = 1;
      break;
    case RISCV::SB:
    case RISCV::SH:
    case RISCV::SW:
    case RISCV::SD:
    case RISCV::FSW:
    case RISCV::FSD:
      BaseOpIdx = 1;
      OffsetOpIdx = 2;
      break;
    }

    if (!isa<ConstantSDNode>(N->getOperand(OffsetOpIdx)))
      continue;

    SDValue Base = N->getOperand(BaseOpIdx);

    // If the base is an ADDI, we can merge it in to the load/store.
    if (!Base.isMachineOpcode() || Base.getMachineOpcode() != RISCV::ADDI)
      continue;

    SDValue ImmOperand = Base.getOperand(1);
    uint64_t Offset2 = N->getConstantOperandVal(OffsetOpIdx);

    if (auto Const = dyn_cast<ConstantSDNode>(ImmOperand)) {
      int64_t Offset1 = Const->getSExtValue();
      int64_t CombinedOffset = Offset1 + Offset2;
      if (!isInt<12>(CombinedOffset))
        continue;
      ImmOperand = CurDAG->getTargetConstant(CombinedOffset, SDLoc(ImmOperand),
                                             ImmOperand.getValueType());
    } else if (auto GA = dyn_cast<GlobalAddressSDNode>(ImmOperand)) {
      // If the off1 in (addi base, off1) is a global variable's address (its
      // low part, really), then we can rely on the alignment of that variable
      // to provide a margin of safety before off1 can overflow the 12 bits.
      // Check if off2 falls within that margin; if so off1+off2 can't overflow.
      const DataLayout &DL = CurDAG->getDataLayout();
      Align Alignment = GA->getGlobal()->getPointerAlignment(DL);
      if (Offset2 != 0 && Alignment <= Offset2)
        continue;
      int64_t Offset1 = GA->getOffset();
      int64_t CombinedOffset = Offset1 + Offset2;
      ImmOperand = CurDAG->getTargetGlobalAddress(
          GA->getGlobal(), SDLoc(ImmOperand), ImmOperand.getValueType(),
          CombinedOffset, GA->getTargetFlags());
    } else if (auto CP = dyn_cast<ConstantPoolSDNode>(ImmOperand)) {
      // Ditto.
      Align Alignment = CP->getAlign();
      if (Offset2 != 0 && Alignment <= Offset2)
        continue;
      int64_t Offset1 = CP->getOffset();
      int64_t CombinedOffset = Offset1 + Offset2;
      ImmOperand = CurDAG->getTargetConstantPool(
          CP->getConstVal(), ImmOperand.getValueType(), CP->getAlign(),
          CombinedOffset, CP->getTargetFlags());
    } else {
      continue;
    }

    LLVM_DEBUG(dbgs() << "Folding add-immediate into mem-op:\nBase:    ");
    LLVM_DEBUG(Base->dump(CurDAG));
    LLVM_DEBUG(dbgs() << "\nN: ");
    LLVM_DEBUG(N->dump(CurDAG));
    LLVM_DEBUG(dbgs() << "\n");

    // Modify the offset operand of the load/store.
    if (BaseOpIdx == 0) // Load
      CurDAG->UpdateNodeOperands(N, Base.getOperand(0), ImmOperand,
                                 N->getOperand(2));
    else // Store
      CurDAG->UpdateNodeOperands(N, N->getOperand(0), Base.getOperand(0),
                                 ImmOperand, N->getOperand(3));

    // The add-immediate may now be dead, in which case remove it.
    if (Base.getNode()->use_empty())
      CurDAG->RemoveDeadNode(Base.getNode());
  }
}

#ifdef ESPERANTO
void RISCVDAGToDAGISel::doEsperantoRewrites() {

  SmallVector<SDNode *, 8> DeadNodes;
  SelectionDAG::allnodes_iterator End = CurDAG->allnodes_end();
  SelectionDAG::allnodes_iterator Cur = CurDAG->allnodes_begin();
  while (Cur != End) {
    SDNode &N = *Cur++;
    esperantoRewrite(&N);
  }
  DEBUG_WITH_TYPE("isel", {
    dbgs() << "After esperanto rewrite:\n";
    CurDAG->dump();
  });
}

void RISCVDAGToDAGISel::esperantoRewrite(SDNode *N) {
  switch (N->getOpcode()) {
  default:
    return;
  case ISD::LOAD:
    return esperantoMemop(cast<MemSDNode>(N),
                          /*Value*/ SDValue(),
                          /*Addr*/ N->getOperand(1),
                          /*PassThru*/ SDValue(),
                          /*Mask*/ SDValue(),
                          cast<LoadSDNode>(N)->getExtensionType());
  case ISD::STORE:
    return esperantoMemop(cast<MemSDNode>(N),
                          /*Value*/ N->getOperand(1),
                          /*Addr*/ N->getOperand(2),
                          /*PassThru*/ SDValue(),
                          /*Mask*/ SDValue(), ISD::LoadExtType::NON_EXTLOAD);
  case ISD::INTRINSIC_W_CHAIN:
    if (N->getConstantOperandVal(1) == Intrinsic::riscv_et_gather)
      esperantoGather(cast<MemIntrinsicSDNode>(N));
    return;
  case ISD::INTRINSIC_VOID:
    if (N->getConstantOperandVal(1) == Intrinsic::riscv_et_scatter)
      esperantoScatter(cast<MemIntrinsicSDNode>(N));
    return;
  case ISD::BUILD_VECTOR:
    return esperantoBUILD_VECTOR(N);
  case ISD::EXTRACT_VECTOR_ELT:
    return esperantoEXTRACT_VECTOR_ELT(N);
  case ISD::INSERT_VECTOR_ELT:
    return esperantoINSERT_VECTOR_ELT(N);
  case ISD::VECTOR_SHUFFLE:
    return esperantoVECTOR_SHUFFLE(N);
  case ISD::SETCC:
    if (N->getValueType(0) == MVT::v8i1)
      esperantoVECTOR_SETCC(N);
    return;
  }
}

#ifndef NDEBUG
static const char *bits(unsigned Lanes) {
  static char bits_[9];
  for (unsigned Idx = 0; Idx < 8; Idx++)
    bits_[7 - Idx] = '0' + ((Lanes >> Idx) & 1);
  bits_[8] = 0;
  return bits_;
}
#endif

// This function attempts to build a constant v8i32 vector by starting
// with a broadcast of the minimum value and then a series
// of add-immediate operations that effect subsets of the vector to
// build up the final values.
static SDValue buildComplexIntegerVector(SDNode *N, SelectionDAG *CurDAG) {

  // If the value is an immediate integer return it, otherwise None.
  auto getImmediate = [](SDValue Elt) -> Optional<int> {
    auto *EltC = dyn_cast<ConstantSDNode>(Elt);
    if (EltC == nullptr) {
      return None;
    }
    int64_t value = EltC->getSExtValue();
    return value;
  };

  // Find the minium of the small immediates
  Optional<int> Min;
  for (SDValue Elt : N->ops()) {
    Optional<int> imm = getImmediate(Elt);
    if (imm.hasValue() and isUInt<20>(*imm)) {
      if (Min.hasValue())
        Min = std::min(Min, imm);
      else
        Min = imm;
    }
  }

  // Split the lanes in:
  // - Lanes with small immediates suitable for uint<20>, which are encoded as the
  //   minimum values which is also uint<20> plus an uint<10> offset.
  // - Lanes suitable for fbci.pi, also fitting in 20 bits but not representable with an uint<10> offset.
  // - Lanes with immediates whatsoever not having optimal encoding.
  // - Lanes with non-immediates
  //
  // An immediate is said to have optimal encoding iif:
  // - It is representable as a 20 bits unsigned integer.
  // - If not the mininium of the immediates representable as 20 unsigned integers,
  //   it should be representable as 10 bits unsigned offset added to the minimum.
  //
  // We use a MapVector so that we output the values in a deterministic
  MapVector<SDValue, unsigned> NonImmediateLanes;
  MapVector<int, unsigned> Immediates;
  MapVector<int, unsigned> OtherUint20Immediates;
  MapVector<int, unsigned> OutlierImmediates;
  for (unsigned Idx = 0; Idx < 8; Idx++) {
    SDValue Elt = N->getOperand(Idx);
    unsigned Lane = 1 << Idx;
    Optional<int> C = getImmediate(Elt);
    if (not C.hasValue())
      NonImmediateLanes[Elt] |= Lane;
    else if (isUInt<20>(*C) and isUInt<10>(*C - *Min))
      Immediates[*C] |= Lane;
    else if (isUInt<20>(*C))
      OtherUint20Immediates[*C] |= Lane;
    else
      OutlierImmediates[*C] |= Lane;
  }

  LLVM_DEBUG(dbgs() << "build vector "; N->dump(););
  LLVM_DEBUG(dbgs() << "min " << Min << "\n");

  // Compute all bit positions which will need to be set in some lane
  // assuming we initialize to Min
  unsigned Bits = 0;
  for (auto &Pair : Immediates)
    Bits |= (Pair.first - *Min);

  // For each bit position, determine which vector
  // immediate lanes needs that bit to be set.
  // If we have "3" in one lane and "7" in another
  // The bit masks for 0b001 and 0b010 will refer to
  // both those lanes and 0b100 will refer to the "7"
  // lane and not the "3".
  struct Bit2LaneElt {
    unsigned Value;
    unsigned Lanes;
  };
  SmallVector<Bit2LaneElt, 8> Bits2Lanes;
  while (Bits) {
    unsigned SingleBitValue = (1 << llvm::countTrailingZeros(Bits));
    Bits &= ~SingleBitValue;
    unsigned Lanes = 0;
    for (auto &Pair : Immediates)
      if ((Pair.first - *Min) & SingleBitValue)
        Lanes |= Pair.second;
    Bits2Lanes.push_back({SingleBitValue, Lanes});
  }

  // Sort so that values with the same lanes are adjacent
  auto cmp = [](const Bit2LaneElt &X, const Bit2LaneElt &Y) {
    return X.Lanes < Y.Lanes;
  };
  std::sort(Bits2Lanes.begin(), Bits2Lanes.end(), cmp);

  LLVM_DEBUG({
    for (Bit2LaneElt E : Bits2Lanes)
      dbgs() << "value " << E.Value << " lanes " << bits(E.Lanes) << " "
             << E.Lanes << "\n";
  });

  // Combine values that effect the same lanes into a single
  // value. For example if we have just "3" and "7" in Immediates
  // this will combine the 0b001 and 0b010 will change
  // the first to be 0b011 and clear the second so we do
  // both bits 1 and 2 in a single operation leaving
  // the 0b100 value for the "7" lane unmodified.
  for (unsigned Idx = 0; Idx < Bits2Lanes.size(); Idx++) {
    unsigned Lanes = Bits2Lanes[Idx].Lanes;
    if (!Lanes)
      continue;
    for (unsigned Jdx = Idx + 1; Jdx < Bits2Lanes.size(); Jdx++)
      if (Bits2Lanes[Jdx].Lanes == Lanes) {
        unsigned Accum = Bits2Lanes[Idx].Value + Bits2Lanes[Jdx].Value;
        if (isIntN(10, Accum)) {
          Bits2Lanes[Idx].Value = Accum;
          Bits2Lanes[Jdx].Lanes = 0;
        }
      }
  }
  // Remove the lanes folded into another value which now have no bits to
  // contribute
  Bits2Lanes.erase(std::remove_if(Bits2Lanes.begin(), Bits2Lanes.end(),
                                  [](Bit2LaneElt &E) { return E.Lanes == 0; }),
                   Bits2Lanes.end());

  SDLoc DL(N);
  EVT VT = N->getValueType(0);
  // build a mask for the specified lanes
  auto mask = [CurDAG, N, DL](unsigned Lanes) {
    return SDValue(
        CurDAG->getMachineNode(RISCV::MOV_M_X, SDLoc(N), MVT::v8i1,
                               CurDAG->getRegister(RISCV::X0, MVT::i64),
                               CurDAG->getTargetConstant(Lanes, DL, MVT::i32)),
        0);
  };
  auto Undef = SDValue(CurDAG->getMachineNode(TargetOpcode::IMPLICIT_DEF, DL,
                                              N->getVTList(), {}),
                       0);
  SDValue Value = Undef;

  if ((1 + Bits2Lanes.size()) >= Immediates.size()) {
    // try setting the first mask to all lanes
    // hoping that might be the ambient value in M0...
    if (!Immediates.empty()) {
      Immediates.front().second = 0xff;
      // It is cheaper to just poke in each immediate value separately
      for (auto &Pair : Immediates) {
        assert(isIntN(10, Pair.second));
        Value = SDValue(CurDAG->getMachineNode(
                            RISCV::FBCI_PI_EX, SDLoc(N), VT, Value,
                            CurDAG->getTargetConstant(Pair.first, DL, MVT::i32),
                            mask(Pair.second)),
                        0);
      }
    } else {
      NonImmediateLanes.front().second = 0xff;
    }
  } else {
    // Initialize the value to Min in all lanes
    Value =
        SDValue(CurDAG->getMachineNode(
                    RISCV::FBCI_PI_EX, SDLoc(N), VT, Value,
                    CurDAG->getTargetConstant(*Min, DL, MVT::i32), mask(0xff)),
                0);
    // Now build remaining values a few bits at a time
    for (Bit2LaneElt &Bits : Bits2Lanes)
      Value = SDValue(CurDAG->getMachineNode(
                          RISCV::FADDI_PI_EX, DL, VT,
                          {Value, Value,
                           CurDAG->getTargetConstant(Bits.Value, DL, MVT::i32),
                           mask(Bits.Lanes)}),
                      0);
  }

  // Now broadcast other immediates fitting as 20 bits unsigned integer
  for (auto &Pair : OtherUint20Immediates) {
    SDValue v0 = CurDAG->getTargetConstant(Pair.first, DL, MVT::i32);
    Value = SDValue(CurDAG->getMachineNode(RISCV::FBCI_PI_EX, SDLoc(N), VT,
                                           Value, v0, mask(Pair.second)),
                    0);
  }

  // Now broadcast the outlier immediates
  for (auto &Pair : OutlierImmediates) {
    int bits0 = (Pair.first >> 12) & ((1 << 20) - 1);
    int bits1 = (Pair.first >> 2) & ((1 << 10) - 1);
    int bits2 = Pair.first & ((1 << 2) - 1);

    SDValue v0 = CurDAG->getTargetConstant(bits0, DL, MVT::i32);
    SDValue v1 = CurDAG->getTargetConstant(bits1, DL, MVT::i32);
    SDValue v2 = CurDAG->getTargetConstant(bits2, DL, MVT::i32);

    SDValue ten = CurDAG->getTargetConstant(10, DL, MVT::i32);
    SDValue two = CurDAG->getTargetConstant(2, DL, MVT::i32);

    Value = SDValue(CurDAG->getMachineNode(RISCV::FBCI_PI_EX, SDLoc(N), VT,
                                           Value, v0, mask(Pair.second)),
                    0);
    if (bits0) {
      Value = SDValue(
          CurDAG->getMachineNode(RISCV::FSLLI_PI_EX, DL, VT,
                                 {Value, Value, ten, mask(Pair.second)}),
          0);
    }

    if (bits1) {
      Value =
          SDValue(CurDAG->getMachineNode(RISCV::FADDI_PI_EX, DL, VT,
                                         {Value, Value, v1, mask(Pair.second)}),
                  0);
    }

    if (bits0 or bits1) {
      Value = SDValue(
          CurDAG->getMachineNode(RISCV::FSLLI_PI_EX, DL, VT,
                                 {Value, Value, two, mask(Pair.second)}),
          0);
    }

    if (bits2) {
      Value =
          SDValue(CurDAG->getMachineNode(RISCV::FADDI_PI_EX, DL, VT,
                                         {Value, Value, v2, mask(Pair.second)}),
                  0);
    }
  }

  // Now broadcast the values which are not immediate. One poke for each
  // value spanning multiple lanes.
  for (auto &Pair : NonImmediateLanes)
    Value =
        SDValue(CurDAG->getMachineNode(RISCV::FBCX_PS_EX, SDLoc(N), VT, Value,
                                       Pair.first, mask(Pair.second)),
                0);

  return Value;
}

void RISCVDAGToDAGISel::esperantoBUILD_VECTOR(SDNode *N) {
  // Try to implemented using MOV_M_X where
  // the result is a constant-valued bit-vector.
  auto checkBuildMask = [this](SDNode *N) -> bool {
    // Use MOV_M_X to set a mask to a constant
    assert(N->getNumOperands() <= MAX_VECTOR_LANES);
    uint64_t Value = 0;
    for (auto Pair : enumerate(N->ops())) {
      if (auto *C = dyn_cast<ConstantSDNode>(Pair.value())) {
        if (C->getZExtValue())
          Value |= (static_cast<uint64_t>(1) << Pair.index());
      } else if (!SDValue(Pair.value()).isUndef())
        return false;
    }

    // All-set is handled by patterns including in XOR -> MASKNOT
    if (Value == 0xff)
      return true;

    SDValue MaskValue = CurDAG->getTargetConstant(Value, SDLoc(N), MVT::i64);
    SDValue Zero = CurDAG->getRegister(RISCV::X0, MVT::i64);
    SDNode *NewN = CurDAG->getMachineNode(RISCV::MOV_M_X, SDLoc(N),
                                          N->getValueType(0), Zero, MaskValue);
    ReplaceNode(N, NewN);
    return true;
  };

  // Try to implement using integer immediate broadcast
  auto checkIntegerBroadcast = [this](SDNode *N, SDValue Model, SDValue Input,
                                      SDValue M0Mask) {
    if (!isa<ConstantSDNode>(Model))
      return false;
    // We have a special opcode for broadcast so we can pattern match
    // effectively when looking for immediate operands of operations.
    SDValue NewN = CurDAG->getNode(RISCVISD::ET_BROADCAST, SDLoc(N),
                                   N->getValueType(0), Model);
    ReplaceNode(N, NewN.getNode());
    return true;
  };

  // Try to implement using the restricted float immediate broadcast
  auto checkFloatBroadcast = [this](SDNode *N, SDValue Model, SDValue Input,
                                    SDValue M0Mask) {
    auto *C = dyn_cast<ConstantFPSDNode>(Model);
    if (!C)
      return false;
    // Immediate is a 20-bit unsigned which is expanded to 32 bits
    // using the algorithm below.
    uint64_t V = C->getValueAPF().bitcastToAPInt().getZExtValue();
    // Can we fold this into the 20 bit format?
    uint64_t V20 = V >> 20;
    uint64_t Low = V20 & 0xf;
    uint64_t Low12 = Low < 8 ? ((Low << 8) | (Low << 4) | Low)
                             : ((Low << 8) | (Low << 4) | (Low + 1));
    uint64_t Expanded = (V20 << 12) | Low12;
    if (Expanded != V)
      return false;
    SDValue NewC = CurDAG->getTargetConstant(V20, SDLoc(N), MVT::i64);
    SDNode *NewN = CurDAG->getMachineNode(
        RISCV::FBCI_PS_EX, SDLoc(N), N->getVTList(), {Input, NewC, M0Mask});
    ReplaceNode(N, NewN);
    return true;
  };

  if (N->getValueType(0) == MVT::v8i1) {
    if (checkBuildMask(N))
      return;
    assert(all_of(N->ops(),
                  [](SDValue Op) { return Op.getValueType() == MVT::i64; }));
    SmallVector<SDValue, 8> Operands(N->op_begin(), N->op_end());
    SDValue NewV = CurDAG->getBuildVector(MVT::v8i32, SDLoc(N), Operands);
    SDValue NewCC = CurDAG->getSetCC(
        SDLoc(N), MVT::v8i1, NewV, CurDAG->getConstant(0, SDLoc(N), MVT::v8i32),
        ISD::CondCode::SETNE);
    ReplaceNode(N, NewCC.getNode());
    return;
  }

  SDValue Model = N->getOperand(0);
  bool Splat = true;
  bool Scalar = true;
  for (auto Pair : enumerate(N->ops())) {
    SDValue Op = Pair.value();
    if (Op == Model) {
      if (Pair.index())
        Scalar = false;
    } else if (!Op.isUndef()) {
      Splat = false;
    }
  }
  if (!Splat) {
    SDValue NewN = buildComplexIntegerVector(N, CurDAG);
    ReplaceNode(N, NewN.getNode());
    return;
  }

  SDValue Input = SDValue(CurDAG->getMachineNode(TargetOpcode::IMPLICIT_DEF,
                                                 SDLoc(N), N->getVTList(), {}),
                          0);
  EVT VT = Model->getValueType(0);
  if (Scalar) {
    // Special case where we have only one element and we just insert
    // that element into an otherwise Undefined vector.
    SDValue NewN = CurDAG->getTargetInsertSubreg(
        RISCV::sub_32, SDLoc(N), N->getSimpleValueType(0), Input, Model);
    ReplaceNode(N, NewN.getNode());
    return;
  }
  SDValue M0Mask =
      SDValue(CurDAG->getMachineNode(
                  RISCV::MOV_M_X, SDLoc(N), MVT::v8i1,
                  CurDAG->getRegister(RISCV::X0, MVT::i64),
                  CurDAG->getTargetConstant(0xff, SDLoc(N), MVT::i64)),
              0);
  if (checkIntegerBroadcast(N, Model, Input, M0Mask))
    return;

  if (VT.isFloatingPoint()) {
    if (checkFloatBroadcast(N, Model, Input, M0Mask))
      return;
    // We have to move the floating point value to the GPR registers.
    // (and type it as an i64)
    // TODO: handle the case for constants better
    Model = SDValue(
        CurDAG->getMachineNode(RISCV::FMV_X_W, SDLoc(N), MVT::i64, Model), 0);
  }

  SDNode *NewN = CurDAG->getMachineNode(RISCV::FBCX_PS_EX, SDLoc(N),
                                        N->getVTList(), {Input, Model, M0Mask});
  ReplaceNode(N, NewN);
}

void RISCVDAGToDAGISel::esperantoEXTRACT_VECTOR_ELT(SDNode *E) {
  EVT VT = E->getSimpleValueType(0);
  if (VT != MVT::i64)
    return;

  // This case breaks tblgen's type system because we are
  // extracting an i64 from an v8i32
  SDValue Input = E->getOperand(0);
  SDValue Index = E->getOperand(1);
  auto *C = dyn_cast<ConstantSDNode>(Index.getNode());
  if (Input.getValueType() == MVT::v8i1) {
    SDNode *Mask =
        CurDAG->getMachineNode(RISCV::COPY, SDLoc(E), MVT::i64, Input);
    SDValue Shr =
        CurDAG->getNode(ISD::SRL, SDLoc(E), MVT::i64, SDValue(Mask, 0), Index);
    SDValue Bit = CurDAG->getNode(ISD::AND, SDLoc(E), MVT::i64, Shr,
                                  CurDAG->getConstant(1, SDLoc(E), MVT::i64));
    return ReplaceNode(E, Bit.getNode());
  }
  SDNode *NewN = CurDAG->getMachineNode(
      RISCV::FMVS_X_PS, SDLoc(E), MVT::i64,
      {Input,
       CurDAG->getTargetConstant(C->getZExtValue(), SDLoc(E), MVT::i32)});
  ReplaceNode(E, NewN);
}

void RISCVDAGToDAGISel::esperantoINSERT_VECTOR_ELT(SDNode *I) {

  SDValue InputVec = I->getOperand(0);
  SDValue InputElt = I->getOperand(1);
  SDValue Index = I->getOperand(2);
  unsigned MaskVal = 1 << cast<ConstantSDNode>(Index)->getZExtValue();
  SDLoc DL(I);
  SDValue Mask = SDValue(
      CurDAG->getMachineNode(RISCV::MOV_M_X, DL, MVT::v8i1,
                             CurDAG->getRegister(RISCV::X0, MVT::i64),
                             CurDAG->getTargetConstant(MaskVal, DL, MVT::i32)),
      0);

  if (auto *C = dyn_cast<ConstantSDNode>(InputElt)) {
    if (isInt<20>(C->getSExtValue())) {
      SDNode *NewN = CurDAG->getMachineNode(
          RISCV::FBCI_PI_EX, DL, I->getValueType(0), InputVec,
          CurDAG->getTargetConstant(C->getSExtValue(), DL, MVT::i32), Mask);
      ReplaceNode(I, NewN);
      return;
    }
  }
  if (InputElt.getValueType() == MVT::f32)
    InputElt = SDValue(
        CurDAG->getMachineNode(RISCV::FMV_X_W, DL, MVT::i32, InputElt), 0);
  // TODO -- handle FBCI_PS
  SDNode *NewN = CurDAG->getMachineNode(
      RISCV::FBCX_PS_EX, DL, I->getValueType(0), InputVec, InputElt, Mask);
  ReplaceNode(I, NewN);
}

void RISCVDAGToDAGISel::esperantoVECTOR_SHUFFLE(SDNode *N) {
  auto *VS = cast<ShuffleVectorSDNode>(N);
  ArrayRef<int> Mask = VS->getMask();
  unsigned MaskValue = 0;
  for (unsigned Idx = 0; Idx < 4; Idx++) {
    int M = Mask[Idx];
    if (M < 0) {
      M = Mask[Idx + 4];
      if (M < 0)
        M = Idx;
    }
    MaskValue |= M << (2 * Idx);
  }

  SDValue Input = SDValue(CurDAG->getMachineNode(TargetOpcode::IMPLICIT_DEF,
                                                 SDLoc(N), N->getVTList(), {}),
                          0);
  SDValue AllLanes = CurDAG->getConstant(1, SDLoc(N), MVT::v8i1);
  SDNode *NewN = CurDAG->getMachineNode(
      RISCV::FSWIZZ_PS_EX, SDLoc(N), N->getValueType(0),
      {Input, N->getOperand(0),
       CurDAG->getTargetConstant(MaskValue, SDLoc(N), MVT::i32),
       AllLanes}); // All Lanes Mask
  ReplaceNode(N, NewN);
}

static SDValue LowerSETCC(SDValue Op, SelectionDAG &DAG) {
  // This is only enabled for Esperanto mask generating operations
  assert(Op.getValueType() == MVT::v8i1);

  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(2))->get();
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);
  bool isFloat = (LHS.getValueType() == MVT::v8f32);
  SDLoc DL(Op);

  // Helper lambda functions to abstract node constructions

  // Build a condition code node for CC.
  auto cc = [&DAG, DL](ISD::CondCode CC) { return DAG.getCondCode(CC); };

  // Logical operators
  auto not_ = [&DAG, DL](SDValue X) {
    return DAG.getNode(ISD::XOR, DL, MVT::v8i1, X,
                       DAG.getSplatBuildVector(
                           MVT::v8i1, DL, DAG.getConstant(1, DL, MVT::i64)));
  };
  auto and_ = [&DAG, DL](SDValue X, SDValue Y) {
    return DAG.getNode(ISD::AND, DL, MVT::v8i1, X, Y);
  };
  auto or_ = [&DAG, DL](SDValue X, SDValue Y) {
    return DAG.getNode(ISD::OR, DL, MVT::v8i1, X, Y);
  };

  // Build a SELECT with the operand's swapped using CC is the code.
  auto swapOperands = [&](ISD::CondCode CC) {
    return DAG.getNode(ISD::SETCC, DL, MVT::v8i1, RHS, LHS, cc(CC),
                       Op->getFlags());
  };
  // Build a new SELECT with CC but other parameters the same
  auto make = [&](ISD::CondCode CC) {
    return DAG.getNode(ISD::SETCC, DL, MVT::v8i1, LHS, RHS, cc(CC),
                       Op->getFlags());
  };
  // Compute a mask that is true when both operands are not NaN
  auto ordered = [&]() {
    SDValue OLHS =
        DAG.getNode(ISD::SETCC, DL, MVT::v8i1, LHS, LHS, cc(ISD::SETO));
    SDValue ORHS =
        DAG.getNode(ISD::SETCC, DL, MVT::v8i1, RHS, RHS, cc(ISD::SETO));
    // TOOD -- somewhere we should fold an and by
    // using the OLHS mask to ORHS
    return and_(OLHS, ORHS);
  };

  // Rewrite CC kinds to mostly avoid operations not directly supported
  // by the hardare. In some cases, we can't fully avoid that because
  // subsequent combining/simplification will just reverse the action here
  // or where the rewrite yields much worse code than a code generation
  // pattern.
  switch (CC) {
  default:
    return Op;
  case ISD::SETOGT:
    return swapOperands(ISD::SETOLT);
  case ISD::SETOGE:
    return swapOperands(ISD::SETOLE);
  case ISD::SETONE:
    return and_(not_(make(ISD::SETOEQ)), ordered());
  case ISD::SETO:
    return (LHS == RHS ? Op : ordered());
  case ISD::SETUO:
    return not_(ordered());
  case ISD::SETUEQ:
    return or_(make(ISD::SETOEQ), not_(ordered()));
  case ISD::SETULE:
    return (isFloat ? or_(make(ISD::SETOLE), not_(ordered())) : Op);
  case ISD::SETULT:
    return (isFloat ? or_(make(ISD::SETOLT), not_(ordered())) : Op);
  case ISD::SETUGT:
    return (isFloat ? or_(swapOperands(ISD::SETOLT), not_(ordered()))
                    : swapOperands(ISD::SETULT));
  case ISD::SETUGE:
    return (isFloat ? or_(swapOperands(ISD::SETOLE), not_(ordered())) : Op);
  case ISD::SETGT:
    return swapOperands(ISD::SETLT);
  case ISD::SETGE:
    return swapOperands(ISD::SETLE);
  }
  return Op;
}

void RISCVDAGToDAGISel::esperantoVECTOR_SETCC(SDNode *N) {
  SDValue New = LowerSETCC(SDValue(N, 0), *CurDAG);
  if (New.getNode() != N)
    ReplaceNode(N, New.getNode());
}

static void getLoadParams(MemSDNode *M, ISD::LoadExtType Ext, unsigned *Opcode,
                          unsigned *TruncateMask) {
  unsigned AddrSpace = M->getAddressSpace();
  static unsigned OpMap[9] = {
      RISCV::FGB_PS_EX, RISCV::FGBL_PS_EX, RISCV::FGBG_PS_EX,
      RISCV::FGH_PS_EX, RISCV::FGHL_PS_EX, RISCV::FGHG_PS_EX,
      RISCV::FGW_PS_EX, RISCV::FGWL_PS_EX, RISCV::FGWG_PS_EX,
  };

  switch (M->getMemoryVT().getScalarSizeInBits()) {
  default:
    llvm_unreachable("invalid MVT for shared memory op");
  case 8:
    *Opcode = OpMap[AddrSpace];
    *TruncateMask = 0xff;
    break;
  case 16:
    *Opcode = OpMap[3 + AddrSpace];
    *TruncateMask = 0xffff;
    break;
  case 32:
    *Opcode = OpMap[6 + AddrSpace];
    *TruncateMask = 0;
    break;
  }
  if (Ext != ISD::LoadExtType::ZEXTLOAD)
    *TruncateMask = 0;
}

static void getStoreParams(MemSDNode *M, unsigned *Opcode) {
  unsigned AddrSpace = M->getAddressSpace();
  assert(AddrSpace < 3);
  static unsigned OpMap[9] = {
      RISCV::FSCB_PS_EX, RISCV::FSCBL_PS_EX, RISCV::FSCBG_PS_EX,
      RISCV::FSCH_PS_EX, RISCV::FSCHL_PS_EX, RISCV::FSCHG_PS_EX,
      RISCV::FSCW_PS_EX, RISCV::FSCWL_PS_EX, RISCV::FSCWG_PS_EX,
  };
  switch (M->getMemoryVT().getScalarSizeInBits()) {
  default:
    llvm_unreachable("invalid MVT for shared memory op");
  case 8:
    *Opcode = OpMap[AddrSpace];
    break;
  case 16:
    *Opcode = OpMap[3 + AddrSpace];
    break;
  case 32:
    *Opcode = OpMap[6 + AddrSpace];
    break;
  }
}

void RISCVDAGToDAGISel::esperantoMemop(MemSDNode *M, SDValue Value,
                                       SDValue Addr, SDValue PassThru,
                                       SDValue Mask, ISD::LoadExtType Ext) {
  unsigned MemWidth = M->getMemoryVT().getScalarSizeInBits();
  if (MemWidth > 32 || (M->getAddressSpace() == 0 && MemWidth == 32))
    return;
  unsigned Opcode;
  unsigned TruncateMask = 0; // target operations only do sign extensions so
                             // we may need to truncate the result
  if (!Value) {
    getLoadParams(M, Ext, &Opcode, &TruncateMask);
  } else {
    getStoreParams(M, &Opcode);
  }

  auto constant = [this, M](int Value) {
    return CurDAG->getTargetConstant(Value, SDLoc(M), MVT::i32);
  };
  auto mask = [this, M](unsigned Value) {
    return SDValue(CurDAG->getMachineNode(
                       RISCV::MOV_M_X, SDLoc(M), MVT::v8i1,
                       CurDAG->getRegister(RISCV::X0, MVT::i64),
                       CurDAG->getTargetConstant(Value, SDLoc(M), MVT::i32)),
                   0);
  };

  SDValue Chain = M->getOperand(0);

  bool isVector =
      (Value ? Value.getValueType() : M->getValueType(0)).isVector();
  SDValue ZeroReg = CurDAG->getRegister(RISCV::X0, MVT::i64);
  if (!Mask)
    Mask = mask(isVector ? 0xff : 0x01);
  SDValue UndefVec(
      CurDAG->getMachineNode(TargetOpcode::IMPLICIT_DEF, SDLoc(M), MVT::v8i32),
      0);
  SDNode *NewM;
  SDValue IndexVec;
  if (isVector) {
    IndexVec = SDValue(CurDAG->getMachineNode(
                           RISCV::FBCX_PS_EX, SDLoc(M), MVT::v8i32,
                           {UndefVec, ZeroReg, mask(isVector ? 0xff : 0x1)}),
                       0);
    // This is generally done earlier in RISCVOPtimizeMemIntrinsics but
    // in some cases we spill a vector to the stack to accomplish a bitcast
    // those scenarios are generally as poor choice and should be eliminated.
    // (TODO: one example Jira ESP-462)
    for (unsigned Idx = 1; Idx < 8; Idx++)
      IndexVec = SDValue(
          CurDAG->getMachineNode(RISCV::FBCI_PI_EX, SDLoc(M), MVT::v8i32,
                                 {IndexVec, constant(Idx), mask(1 << Idx)}),
          0);
    if (MemWidth > 8)
      IndexVec = CurDAG->getNode(
          ISD::SHL, SDLoc(M), MVT::v8i32, IndexVec,
          CurDAG->getSplatBuildVector(
              MVT::v8i32, SDLoc(M),
              CurDAG->getConstant(MemWidth == 16 ? 1 : 2, SDLoc(M), MVT::i32)));
  } else {
    IndexVec = SDValue(
        CurDAG->getMachineNode(
            RISCV::INSERT_SUBREG, SDLoc(M), MVT::v8i32,
            {SDValue(CurDAG->getMachineNode(RISCV::IMPLICIT_DEF, SDLoc(M),
                                            MVT::v8f32),
                     0),
             CurDAG->getConstant(0, SDLoc(M), MVT::i64),
             CurDAG->getTargetConstant(RISCV::sub_32, SDLoc(M), MVT::i32)}),
        0);
  }
  if (!Value) {
    NewM = CurDAG->getMachineNode(Opcode, SDLoc(M), {MVT::v8i32, MVT::Other},
                                  {UndefVec, IndexVec, Addr, Mask, Chain});
    CurDAG->setNodeMemRefs(dyn_cast<MachineSDNode>(NewM), M->getMemOperand());
    Chain = SDValue(NewM, 1);
    SDValue Result = SDValue(NewM, 0);
    if (!isVector) {
      bool f32 = M->getValueType(0) == MVT::f32;
      if (f32) {
        Result = SDValue(
            CurDAG->getMachineNode(
                RISCV::EXTRACT_SUBREG, SDLoc(M), MVT::f32, Result,
                CurDAG->getTargetConstant(RISCV::sub_32, SDLoc(M), MVT::i32)),
            0);
      } else {
        SDValue Zero = CurDAG->getTargetConstant(0, SDLoc(M), MVT::i32);
        unsigned MoveOpcode =
            (Ext == ISD::ZEXTLOAD ? RISCV::FMVZ_X_PS : RISCV::FMVS_X_PS);
        Result = SDValue(CurDAG->getMachineNode(MoveOpcode, SDLoc(M),
                                                f32 ? MVT::f32 : MVT::i64,
                                                {SDValue(NewM, 0), Zero}),
                         0);
        if (TruncateMask)
          Result = CurDAG->getNode(
              ISD::AND, SDLoc(M), MVT::i64,
              {Result, CurDAG->getConstant(TruncateMask, SDLoc(M), MVT::i64)});
      }
    } else if (TruncateMask) {
      Result = CurDAG->getNode(
          ISD::AND, SDLoc(M), MVT::v8i32,
          {Result, CurDAG->getSplatBuildVector(
                       MVT::v8i32, SDLoc(M),
                       CurDAG->getConstant(TruncateMask, SDLoc(M), MVT::i64))});
    }
    ReplaceUses(SDValue(M, 0), Result); // Update the value
    ReplaceUses(SDValue(M, 1), Chain);  // Update the chain
    CurDAG->RemoveDeadNode(M);
  } else {
    if (!isVector) {
      bool f32 = Value->getValueType(0) == MVT::f32;
      if (f32) {
        Value = SDValue(
            CurDAG->getMachineNode(
                RISCV::INSERT_SUBREG, SDLoc(M), MVT::v8f32,
                {SDValue(CurDAG->getMachineNode(RISCV::IMPLICIT_DEF, SDLoc(M),
                                        MVT::v8f32),0),
                 Value,
                 CurDAG->getTargetConstant(RISCV::sub_32, SDLoc(M), MVT::i32)}),
            0);
      } else {
        // Copy the value into the vector register file
        Value =
            SDValue(CurDAG->getMachineNode(RISCV::FBCX_PS_EX, SDLoc(M),
                                           MVT::v8i32, {UndefVec, Value, Mask}),
                    0);
      }
    }
    // and store it to memory
    NewM = CurDAG->getMachineNode(Opcode, SDLoc(M), MVT::Other,
                                  {Value, IndexVec, Addr, Mask, Chain});
    CurDAG->setNodeMemRefs(dyn_cast<MachineSDNode>(NewM), M->getMemOperand());
    ReplaceNode(M, NewM);
  }
}

void RISCVDAGToDAGISel::esperantoGather(MemIntrinsicSDNode *M) {
  SDValue Chain = M->getOperand(0);
  SDValue Addr = M->getOperand(2);
  SDValue IndexVec = M->getOperand(3);
  SDValue PassThru = M->getOperand(4);
  auto Ext = static_cast<ISD::LoadExtType>(M->getConstantOperandVal(5));
  SDValue Mask = M->getOperand(6);
  unsigned Opcode;
  unsigned TruncateMask;
  getLoadParams(M, Ext, &Opcode, &TruncateMask);

  SDNode *NewM =
      CurDAG->getMachineNode(Opcode, SDLoc(M), M->getVTList(),
                             {PassThru, IndexVec, Addr, Mask, Chain});
  CurDAG->setNodeMemRefs(dyn_cast<MachineSDNode>(NewM), M->getMemOperand());
  ReplaceNode(M, NewM);
}

void RISCVDAGToDAGISel::esperantoScatter(MemIntrinsicSDNode *M) {
  SDValue Chain = M->getOperand(0);
  SDValue Value = M->getOperand(2);
  SDValue Addr = M->getOperand(3);
  SDValue IndexVec = M->getOperand(4);
  SDValue Mask = M->getOperand(5);
  unsigned Opcode;
  getStoreParams(M, &Opcode);

  SDNode *NewM = CurDAG->getMachineNode(Opcode, SDLoc(M), MVT::Other,
                                        {Value, IndexVec, Addr, Mask, Chain});
  CurDAG->setNodeMemRefs(dyn_cast<MachineSDNode>(NewM), M->getMemOperand());
  ReplaceNode(M, NewM);
}

namespace {

class OptimizeMaskCommon {
protected:
  MachineFunction &MF;
  MachineRegisterInfo &MRI;
  virtual void processBlock(MachineBasicBlock &MBB) = 0;

public:
  OptimizeMaskCommon(MachineFunction &MF) : MF(MF), MRI(MF.getRegInfo()) {}
  void run() {
    for (MachineBasicBlock &MBB : MF)
      processBlock(MBB);
  }

protected:
  bool definesMask(MachineInstr &MI) {
    unsigned N = MI.getNumDefs();
    if (!N)
      return false;
    if (!MI.getOperand(0).isReg())
      return false;
    Register R = MI.getOperand(0).getReg();
    return (R.isVirtual() && (MRI.getRegClass(R) == &RISCV::MRRegClass ||
                              MRI.getRegClass(R) == &RISCV::MR0RegClass));
  }
};

class OptimizeVectorMasks : public OptimizeMaskCommon {
public:
  OptimizeVectorMasks(MachineFunction &MF) : OptimizeMaskCommon(MF) {}

private:
  DenseMap<MachineInstr *, Register> LiveLanesMap;
  DenseSet<MachineInstr *> Seen;
  Register getLiveLanes(MachineInstr &MI) {
    auto Iter = LiveLanesMap.find(&MI);
    return Iter == LiveLanesMap.end() ? Register(0) : Iter->second;
  };
  static bool isAllLanes(const MachineInstr &MI) {
    return (MI.getOpcode() == RISCV::MOV_M_X &&
            MI.getOperand(1).getReg() == RISCV::X0 &&
            MI.getOperand(2).getImm() == 0xff);
  }
  bool isAllLanes(Register R) {
    if (R.isPhysical())
      return false;
    MachineInstr *MI = MRI.getVRegDef(R);
    return (MI && isAllLanes(*MI));
  }
  Register getMaskReg(const MachineInstr &MI) {
    unsigned N = MI.getNumExplicitOperands();
    const MachineOperand &MOp = MI.getOperand(N - 1);
    if (!MOp.isReg() || MOp.isDef())
      return 0;
    Register M = MOp.getReg();
    if (M.isPhysical() || (MRI.getRegClass(M) != &RISCV::MR0RegClass &&
                           MRI.getRegClass(M) != &RISCV::MRRegClass))
      return 0;
    return M;
  }
  Register isMaskedVectorOp(const MachineInstr &MI) {
    if (any_of(MI.explicit_operands(), [this](const MachineOperand &Op) {
          if (!Op.isReg())
            return false;
          Register R = Op.getReg();
          return (R.isVirtual() &&
                  MRI.getRegClass(R) == &RISCV::FPR256RegClass);
        }))
      return getMaskReg(MI);
    return 0;
  }
  int DebugCount{0};
  unsigned ChangeCount{0};
  class CommonMask {
    bool Bottom{false};
    Register Common{0};

  public:
    CommonMask(Register R = 0) : Common(R) {}
    void add(Register R) {
      if (R == 0)
        Bottom = true;
      else if (Common == 0)
        Common = R;
      else if (R != Common)
        Bottom = true;
    }
    operator bool() const { return !Bottom && Common; }
    Register get() {
      assert(Common && !Bottom);
      return Common;
    }
    void setBottom() { Bottom = true; }
  };

  void processBlock(MachineBasicBlock &MBB) override {
    // clang-format off
    // The goal here is to look for a matter such as
    //   %51:mr = MOV_M_X $x0, 255
    //   ...
    //   %64:mr0 = COPY %7:mr
    //   %63:fpr256 = FGW_PS_EX %6:fpr256(tied-def 0), %60:fpr256, %9:gpr, %64:mr0
    //   %66:fpr256 = IMPLICIT_DEF
    //   %67:mr0 = COPY %51:mr
    //   %65:fpr256 = FADD_PS_EX %66:fpr256(tied-def 0), killed %58:fpr256, killed %63:fpr256, 7, %67:mr0
    //   %68:mr0 = COPY %7:mr
    //   FSCW_PS_EX killed %65:fpr256, %60:fpr256, %5:gpr, %68:mr0
    // Here we would prefer to use %7 the mask that controls the FADD_PS_EX
    // since only the lanes it selects are live

    // We need to know that %51 selects a superset of %7 but
    // only lanes %7 are live.

    // We will retain the pattern of mask copies and so need to know that
    // assignments such as to %67 have common usage.
    // clang-format on

    auto sourceReg = [this, &MBB](Register M) {
      if (!M)
        return M;
      for (;;) {
        MachineInstr *Def = MRI.getVRegDef(M);
        if (!Def || Def->getParent() != &MBB || !Def->isCopy())
          break;
        M = Def->getOperand(1).getReg();
      }
      return M;
    };

    LiveLanesMap.clear();
    Seen.clear();
    LLVM_DEBUG(dbgs() << "optimize masks " << MBB.getName() << "\n");
    for (MachineInstr &MI : reverse(MBB)) {
      LLVM_DEBUG(dbgs() << DebugCount << ": " << MI);
      DebugCount += 1;
      Seen.insert(&MI);
      if (definesMask(MI)) {
        if (!MI.isCopy())
          continue;
        Register M = MI.getOperand(0).getReg();
        if (M.isPhysical())
          continue;
        CommonMask Live;
        for (MachineInstr &UI : MRI.use_nodbg_instructions(M))
          Live.add(getLiveLanes(UI));
        if (!Live)
          continue;

        Register L = Live.get();
        LiveLanesMap.try_emplace(&MI, L);

        Register Src = sourceReg(MI.getOperand(1).getReg());
        if (Src == L)
          continue;
        MachineInstr *Def = MRI.getVRegDef(L);
        if (Seen.count(Def))
          continue;
        if (!isAllLanes(Src)) // TODO -- really is Live not a subset of Src
          continue;
        if (ChangeCount == OptimizeMasksLimit)
          return;

        // Replace Src with Live
        MI.getOperand(1).setReg(L);
        LLVM_DEBUG(dbgs() << "change mask " << ChangeCount << " " << MI);
        ChangeCount += 1;
        continue;
      }

      if (MI.getOpcode() == RISCV::FCMOV_PS_EX)
        continue;
      if (MI.getOpcode() == RISCV::FCMOVM_PS_EX)
        continue;

      // Find the mask controlling this instruction
      // and verify it is a vector instruction
      Register M = sourceReg(isMaskedVectorOp(MI));
      if (!M)
        continue;

      // There are a few patterns where we update an output
      // register by writing a subset of the live lanes.
      // In that case we treat all lanves as live.
      if (MI.isRegTiedToDefOperand(1)) {
        MachineInstr *Def = MRI.getVRegDef(MI.getOperand(1).getReg());
        if (Def->getOpcode() != RISCV::IMPLICIT_DEF)
          continue;
      }

      LLVM_DEBUG(dbgs() << "Mask is "
                        << "%" << M.virtRegIndex() << "\n");

      // Loads and stores have accurate masks based on control flow
      if (MI.mayLoadOrStore()) {
        // Some kind of store
        LiveLanesMap.try_emplace(&MI, M);
        continue;
      }

      // Verify uses of MI have a common controlling mask
      CommonMask Live;
      for (MachineOperand &D : MI.defs()) {
        Register R = D.getReg();
        if (R.isPhysical()) {
          Live.setBottom();
          break;
        }
        if (MRI.getRegClass(R) == &RISCV::FPR256RegClass)
          for (MachineInstr &UI : MRI.use_nodbg_instructions(R))
            // TODO special case conditional move?
            Live.add(getLiveLanes(UI));
      }
      if (!Live) {
        LiveLanesMap.try_emplace(&MI, M);
        continue;
      }
      LLVM_DEBUG(dbgs() << "Live mask "
                        << "%" << Live.get().virtRegIndex() << " " << MI);
      LiveLanesMap.try_emplace(&MI, Live.get());
    }
  }
};
} // namespace

void RISCVDAGToDAGISel::optimizeMaskCopies(MachineFunction &MF) {
  // The fast register allocator does not correctly handle
  // references to M0 and marks them killed incorrectly
  if (MF.getTarget().getOptLevel() != CodeGenOpt::Level::None &&
      !MF.getFunction().hasOptNone()) {
    if (OptimizeMasksFlag) {
      LLVM_DEBUG({
        dbgs() << "Before Vector Masks ";
        MF.dump();
      });
      OptimizeVectorMasks(MF).run();
    }
  }
}
#endif

// This pass converts a legalized DAG into a RISCV-specific DAG, ready
// for instruction scheduling.
FunctionPass *llvm::createRISCVISelDag(RISCVTargetMachine &TM) {
  return new RISCVDAGToDAGISel(TM);
}
