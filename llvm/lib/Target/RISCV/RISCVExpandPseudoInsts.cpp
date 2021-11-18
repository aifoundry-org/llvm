//===-- RISCVExpandPseudoInsts.cpp - Expand pseudo instructions -----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a pass that expands pseudo instructions into target
// instructions. This pass should be run after register allocation but before
// the post-regalloc scheduling pass.
//
//===----------------------------------------------------------------------===//

#include "RISCV.h"
#include "RISCVInstrInfo.h"
#include "RISCVTargetMachine.h"

#include "llvm/CodeGen/LivePhysRegs.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"

using namespace llvm;

#define RISCV_EXPAND_PSEUDO_NAME "RISCV pseudo instruction expansion pass"

namespace {

class RISCVExpandPseudo : public MachineFunctionPass {
public:
  const RISCVInstrInfo *TII;
  static char ID;

  RISCVExpandPseudo() : MachineFunctionPass(ID) {
    initializeRISCVExpandPseudoPass(*PassRegistry::getPassRegistry());
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override { return RISCV_EXPAND_PSEUDO_NAME; }

private:
  bool expandMBB(MachineBasicBlock &MBB);
  bool expandMI(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                MachineBasicBlock::iterator &NextMBBI);
  bool expandAuipcInstPair(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator MBBI,
                           MachineBasicBlock::iterator &NextMBBI,
                           unsigned FlagsHi, unsigned SecondOpcode);
  bool expandLoadLocalAddress(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MBBI,
                              MachineBasicBlock::iterator &NextMBBI);
  bool expandLoadAddress(MachineBasicBlock &MBB,
                         MachineBasicBlock::iterator MBBI,
                         MachineBasicBlock::iterator &NextMBBI);
  bool expandLoadTLSIEAddress(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MBBI,
                              MachineBasicBlock::iterator &NextMBBI);
  bool expandLoadTLSGDAddress(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MBBI,
                              MachineBasicBlock::iterator &NextMBBI);
  bool expandImplicitOperands(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MBBI,
                              MachineBasicBlock::iterator &NextMBBI,
                              unsigned Opcode);
#ifdef ESPERANTO
  bool expandStackOps(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                      MachineBasicBlock::iterator &NextMBBI);
  bool expandMaskLS(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                    MachineBasicBlock::iterator &NextMBBI);
  bool expandIOTA(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                  MachineBasicBlock::iterator &NextMBBI);
  bool expandHARTID(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                  MachineBasicBlock::iterator &NextMBBI);
  bool expandTO_VECTOR(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                       MachineBasicBlock::iterator &NextMBBI);
#endif
};

char RISCVExpandPseudo::ID = 0;

bool RISCVExpandPseudo::runOnMachineFunction(MachineFunction &MF) {
  TII = static_cast<const RISCVInstrInfo *>(MF.getSubtarget().getInstrInfo());
  bool Modified = false;
  for (auto &MBB : MF)
    Modified |= expandMBB(MBB);
  return Modified;
}

bool RISCVExpandPseudo::expandMBB(MachineBasicBlock &MBB) {
  bool Modified = false;

  MachineBasicBlock::iterator MBBI = MBB.begin(), E = MBB.end();
  while (MBBI != E) {
    MachineBasicBlock::iterator NMBBI = std::next(MBBI);
    Modified |= expandMI(MBB, MBBI, NMBBI);
    MBBI = NMBBI;
  }

  return Modified;
}

static Optional<unsigned> getImplicitOpcode(unsigned Opcode) {
  switch (Opcode) {
  default:
    return None;
  case RISCV::CUBEFACEIDX_PS_EX:
    return RISCV::CUBEFACEIDX_PS;
  case RISCV::CUBEFACE_PS_EX:
    return RISCV::CUBEFACE_PS;
  case RISCV::CUBESGNSC_PS_EX:
    return RISCV::CUBESGNSC_PS;
  case RISCV::CUBESGNTC_PS_EX:
    return RISCV::CUBESGNTC_PS;
  case RISCV::FADDI_PI_EX:
    return RISCV::FADDI_PI;
  case RISCV::FADD_PI_EX:
    return RISCV::FADD_PI;
  case RISCV::FADD_PS_EX:
    return RISCV::FADD_PS;
  case RISCV::FAMOADDG_PI_EX:
    return RISCV::FAMOADDG_PI;
  case RISCV::FAMOADDL_PI_EX:
    return RISCV::FAMOADDL_PI;
  case RISCV::FAMOANDG_PI_EX:
    return RISCV::FAMOANDG_PI;
  case RISCV::FAMOANDL_PI_EX:
    return RISCV::FAMOANDL_PI;
  case RISCV::FAMOMAXG_PI_EX:
    return RISCV::FAMOMAXG_PI;
  case RISCV::FAMOMAXG_PS_EX:
    return RISCV::FAMOMAXG_PS;
  case RISCV::FAMOMAXL_PI_EX:
    return RISCV::FAMOMAXL_PI;
  case RISCV::FAMOMAXL_PS_EX:
    return RISCV::FAMOMAXL_PS;
  case RISCV::FAMOMAXUG_PI_EX:
    return RISCV::FAMOMAXUG_PI;
  case RISCV::FAMOMAXUL_PI_EX:
    return RISCV::FAMOMAXUL_PI;
  case RISCV::FAMOMING_PI_EX:
    return RISCV::FAMOMING_PI;
  case RISCV::FAMOMING_PS_EX:
    return RISCV::FAMOMING_PS;
  case RISCV::FAMOMINL_PI_EX:
    return RISCV::FAMOMINL_PI;
  case RISCV::FAMOMINL_PS_EX:
    return RISCV::FAMOMINL_PS;
  case RISCV::FAMOMINUG_PI_EX:
    return RISCV::FAMOMINUG_PI;
  case RISCV::FAMOMINUL_PI_EX:
    return RISCV::FAMOMINUL_PI;
  case RISCV::FAMOORG_PI_EX:
    return RISCV::FAMOORG_PI;
  case RISCV::FAMOORL_PI_EX:
    return RISCV::FAMOORL_PI;
  case RISCV::FAMOSWAPG_PI_EX:
    return RISCV::FAMOSWAPG_PI;
  case RISCV::FAMOSWAPL_PI_EX:
    return RISCV::FAMOSWAPL_PI;
  case RISCV::FAMOXORG_PI_EX:
    return RISCV::FAMOXORG_PI;
  case RISCV::FAMOXORL_PI_EX:
    return RISCV::FAMOXORL_PI;
  case RISCV::FANDI_PI_EX:
    return RISCV::FANDI_PI;
  case RISCV::FAND_PI_EX:
    return RISCV::FAND_PI;
  case RISCV::FBCI_PI_EX:
    return RISCV::FBCI_PI;
  case RISCV::FBCI_PS_EX:
    return RISCV::FBCI_PS;
  case RISCV::FBCX_PS_EX:
    return RISCV::FBCX_PS;
  case RISCV::FBC_PS_EX:
    return RISCV::FBC_PS;
  case RISCV::FCLASS_PS_EX:
    return RISCV::FCLASS_PS;
  case RISCV::FCMOVM_PS_EX:
    return RISCV::FCMOVM_PS;
  case RISCV::FCMOV_PS_EX:
    return RISCV::FCMOV_PS;
  case RISCV::FCVT_F10_PS_EX:
    return RISCV::FCVT_F10_PS;
  case RISCV::FCVT_F11_PS_EX:
    return RISCV::FCVT_F11_PS;
  case RISCV::FCVT_F16_PS_EX:
    return RISCV::FCVT_F16_PS;
  case RISCV::FCVT_PS_F10_EX:
    return RISCV::FCVT_PS_F10;
  case RISCV::FCVT_PS_F11_EX:
    return RISCV::FCVT_PS_F11;
  case RISCV::FCVT_PS_F16_EX:
    return RISCV::FCVT_PS_F16;
  case RISCV::FCVT_PS_PWU_EX:
    return RISCV::FCVT_PS_PWU;
  case RISCV::FCVT_PS_PW_EX:
    return RISCV::FCVT_PS_PW;
  case RISCV::FCVT_PS_RAST_EX:
    return RISCV::FCVT_PS_RAST;
  case RISCV::FCVT_PS_SN16_EX:
    return RISCV::FCVT_PS_SN16;
  case RISCV::FCVT_PS_SN8_EX:
    return RISCV::FCVT_PS_SN8;
  case RISCV::FCVT_PS_UN10_EX:
    return RISCV::FCVT_PS_UN10;
  case RISCV::FCVT_PS_UN16_EX:
    return RISCV::FCVT_PS_UN16;
  case RISCV::FCVT_PS_UN24_EX:
    return RISCV::FCVT_PS_UN24;
  case RISCV::FCVT_PS_UN2_EX:
    return RISCV::FCVT_PS_UN2;
  case RISCV::FCVT_PS_UN8_EX:
    return RISCV::FCVT_PS_UN8;
  case RISCV::FCVT_PWU_PS_EX:
    return RISCV::FCVT_PWU_PS;
  case RISCV::FCVT_PW_PS_EX:
    return RISCV::FCVT_PW_PS;
  case RISCV::FCVT_RAST_PS_EX:
    return RISCV::FCVT_RAST_PS;
  case RISCV::FCVT_SN16_PS_EX:
    return RISCV::FCVT_SN16_PS;
  case RISCV::FCVT_SN8_PS_EX:
    return RISCV::FCVT_SN8_PS;
  case RISCV::FCVT_UN10_PS_EX:
    return RISCV::FCVT_UN10_PS;
  case RISCV::FCVT_UN16_PS_EX:
    return RISCV::FCVT_UN16_PS;
  case RISCV::FCVT_UN24_PS_EX:
    return RISCV::FCVT_UN24_PS;
  case RISCV::FCVT_UN2_PS_EX:
    return RISCV::FCVT_UN2_PS;
  case RISCV::FCVT_UN8_PS_EX:
    return RISCV::FCVT_UN8_PS;
  case RISCV::FDIVU_PI_EX:
    return RISCV::FDIVU_PI;
  case RISCV::FDIV_PI_EX:
    return RISCV::FDIV_PI;
  case RISCV::FDIV_PS_EX:
    return RISCV::FDIV_PS;
  case RISCV::FEQM_PS_EX:
    return RISCV::FEQM_PS;
  case RISCV::FEQ_PI_EX:
    return RISCV::FEQ_PI;
  case RISCV::FEQ_PS_EX:
    return RISCV::FEQ_PS;
  case RISCV::FEXP_PS_EX:
    return RISCV::FEXP_PS;
  case RISCV::FFRC_PS_EX:
    return RISCV::FFRC_PS;
  case RISCV::FG32B_PS_EX:
    return RISCV::FG32B_PS;
  case RISCV::FG32H_PS_EX:
    return RISCV::FG32H_PS;
  case RISCV::FG32W_PS_EX:
    return RISCV::FG32W_PS;
  case RISCV::FGBG_PS_EX:
    return RISCV::FGBG_PS;
  case RISCV::FGBL_PS_EX:
    return RISCV::FGBL_PS;
  case RISCV::FGB_PS_EX:
    return RISCV::FGB_PS;
  case RISCV::FGHG_PS_EX:
    return RISCV::FGHG_PS;
  case RISCV::FGHL_PS_EX:
    return RISCV::FGHL_PS;
  case RISCV::FGH_PS_EX:
    return RISCV::FGH_PS;
  case RISCV::FGWG_PS_EX:
    return RISCV::FGWG_PS;
  case RISCV::FGWL_PS_EX:
    return RISCV::FGWL_PS;
  case RISCV::FGW_PS_EX:
    return RISCV::FGW_PS;
  case RISCV::FLEM_PS_EX:
    return RISCV::FLEM_PS;
  case RISCV::FLE_PI_EX:
    return RISCV::FLE_PI;
  case RISCV::FLE_PS_EX:
    return RISCV::FLE_PS;
  case RISCV::FLOG_PS_EX:
    return RISCV::FLOG_PS;
  case RISCV::FLTM_PI_EX:
    return RISCV::FLTM_PI;
  case RISCV::FLTM_PS_EX:
    return RISCV::FLTM_PS;
  case RISCV::FLTU_PI_EX:
    return RISCV::FLTU_PI;
  case RISCV::FLT_PI_EX:
    return RISCV::FLT_PI;
  case RISCV::FLT_PS_EX:
    return RISCV::FLT_PS;
  case RISCV::FLWG_PS_EX:
    return RISCV::FLWG_PS;
  case RISCV::FLWL_PS_EX:
    return RISCV::FLWL_PS;
  case RISCV::FLW_PS_EX:
    return RISCV::FLW_PS;
  case RISCV::FMADD_PS_EX:
    return RISCV::FMADD_PS;
  case RISCV::FMAXU_PI_EX:
    return RISCV::FMAXU_PI;
  case RISCV::FMAX_PI_EX:
    return RISCV::FMAX_PI;
  case RISCV::FMAX_PS_EX:
    return RISCV::FMAX_PS;
  case RISCV::FMINU_PI_EX:
    return RISCV::FMINU_PI;
  case RISCV::FMIN_PI_EX:
    return RISCV::FMIN_PI;
  case RISCV::FMIN_PS_EX:
    return RISCV::FMIN_PS;
  case RISCV::FMSUB_PS_EX:
    return RISCV::FMSUB_PS;
  case RISCV::FMULHU_PI_EX:
    return RISCV::FMULHU_PI;
  case RISCV::FMULH_PI_EX:
    return RISCV::FMULH_PI;
  case RISCV::FMUL_PI_EX:
    return RISCV::FMUL_PI;
  case RISCV::FMUL_PS_EX:
    return RISCV::FMUL_PS;
  case RISCV::FNMADD_PS_EX:
    return RISCV::FNMADD_PS;
  case RISCV::FNMSUB_PS_EX:
    return RISCV::FNMSUB_PS;
  case RISCV::FNOT_PI_EX:
    return RISCV::FNOT_PI;
  case RISCV::FOR_PI_EX:
    return RISCV::FOR_PI;
  case RISCV::FPACKREPB_PI_EX:
    return RISCV::FPACKREPB_PI;
  case RISCV::FPACKREPH_PI_EX:
    return RISCV::FPACKREPH_PI;
  case RISCV::FRCP_FIX_RAST_EX:
    return RISCV::FRCP_FIX_RAST;
  case RISCV::FRCP_PS_EX:
    return RISCV::FRCP_PS;
  case RISCV::FREMU_PI_EX:
    return RISCV::FREMU_PI;
  case RISCV::FREM_PI_EX:
    return RISCV::FREM_PI;
  case RISCV::FROUND_PS_EX:
    return RISCV::FROUND_PS;
  case RISCV::FRSQ_PS_EX:
    return RISCV::FRSQ_PS;
  case RISCV::FSAT8_PI_EX:
    return RISCV::FSAT8_PI;
  case RISCV::FSATU8_PI_EX:
    return RISCV::FSATU8_PI;
  case RISCV::FSC32B_PS_EX:
    return RISCV::FSC32B_PS;
  case RISCV::FSC32H_PS_EX:
    return RISCV::FSC32H_PS;
  case RISCV::FSC32W_PS_EX:
    return RISCV::FSC32W_PS;
  case RISCV::FSCBG_PS_EX:
    return RISCV::FSCBG_PS;
  case RISCV::FSCBL_PS_EX:
    return RISCV::FSCBL_PS;
  case RISCV::FSCB_PS_EX:
    return RISCV::FSCB_PS;
  case RISCV::FSCHG_PS_EX:
    return RISCV::FSCHG_PS;
  case RISCV::FSCHL_PS_EX:
    return RISCV::FSCHL_PS;
  case RISCV::FSCH_PS_EX:
    return RISCV::FSCH_PS;
  case RISCV::FSCWG_PS_EX:
    return RISCV::FSCWG_PS;
  case RISCV::FSCWL_PS_EX:
    return RISCV::FSCWL_PS;
  case RISCV::FSCW_PS_EX:
    return RISCV::FSCW_PS;
  case RISCV::FSETM_PI_EX:
    return RISCV::FSETM_PI;
  case RISCV::FSGNJN_PS_EX:
    return RISCV::FSGNJN_PS;
  case RISCV::FSGNJX_PS_EX:
    return RISCV::FSGNJX_PS;
  case RISCV::FSGNJ_PS_EX:
    return RISCV::FSGNJ_PS;
  case RISCV::FSIN_PS_EX:
    return RISCV::FSIN_PS;
  case RISCV::FSLLI_PI_EX:
    return RISCV::FSLLI_PI;
  case RISCV::FSLL_PI_EX:
    return RISCV::FSLL_PI;
  case RISCV::FSQRT_PS_EX:
    return RISCV::FSQRT_PS;
  case RISCV::FSRAI_PI_EX:
    return RISCV::FSRAI_PI;
  case RISCV::FSRA_PI_EX:
    return RISCV::FSRA_PI;
  case RISCV::FSRLI_PI_EX:
    return RISCV::FSRLI_PI;
  case RISCV::FSRL_PI_EX:
    return RISCV::FSRL_PI;
  case RISCV::FSUB_PI_EX:
    return RISCV::FSUB_PI;
  case RISCV::FSUB_PS_EX:
    return RISCV::FSUB_PS;
  case RISCV::FSWG_PS_EX:
    return RISCV::FSWG_PS;
  case RISCV::FSWIZZ_PS_EX:
    return RISCV::FSWIZZ_PS;
  case RISCV::FSWL_PS_EX:
    return RISCV::FSWL_PS;
  case RISCV::FSW_PS_EX:
    return RISCV::FSW_PS;
  case RISCV::FXOR_PI_EX:
    return RISCV::FXOR_PI;
  }
}

bool RISCVExpandPseudo::expandMI(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MBBI,
                                 MachineBasicBlock::iterator &NextMBBI) {
  // RISCVInstrInfo::getInstSizeInBytes hard-codes the number of expanded
  // instructions for each pseudo, and must be updated when adding new pseudos
  // or changing existing ones.
  switch (MBBI->getOpcode()) {
  case RISCV::PseudoLLA:
    return expandLoadLocalAddress(MBB, MBBI, NextMBBI);
  case RISCV::PseudoLA:
    return expandLoadAddress(MBB, MBBI, NextMBBI);
  case RISCV::PseudoLA_TLS_IE:
    return expandLoadTLSIEAddress(MBB, MBBI, NextMBBI);
  case RISCV::PseudoLA_TLS_GD:
    return expandLoadTLSGDAddress(MBB, MBBI, NextMBBI);
#ifdef ESPERANTO
  case RISCV::StackFLQ2:
  case RISCV::StackFSQ2:
    return expandStackOps(MBB, MBBI, NextMBBI);
  case RISCV::IOTA:
    return expandIOTA(MBB, MBBI, NextMBBI);
  case RISCV::HARTID:
    return expandHARTID(MBB, MBBI, NextMBBI);
  case RISCV::TO_VECTOR:
    return expandTO_VECTOR(MBB, MBBI, NextMBBI);
#endif
  default:
    if (Optional<unsigned> ImplicitOpcode =
            getImplicitOpcode(MBBI->getOpcode()))
      return expandImplicitOperands(MBB, MBBI, NextMBBI, *ImplicitOpcode);
    break;
  }

  return false;
}

bool RISCVExpandPseudo::expandAuipcInstPair(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    MachineBasicBlock::iterator &NextMBBI, unsigned FlagsHi,
    unsigned SecondOpcode) {
  MachineFunction *MF = MBB.getParent();
  MachineInstr &MI = *MBBI;
  DebugLoc DL = MI.getDebugLoc();

  Register DestReg = MI.getOperand(0).getReg();
  const MachineOperand &Symbol = MI.getOperand(1);

  MachineBasicBlock *NewMBB = MF->CreateMachineBasicBlock(MBB.getBasicBlock());

  // Tell AsmPrinter that we unconditionally want the symbol of this label to be
  // emitted.
  NewMBB->setLabelMustBeEmitted();

  MF->insert(++MBB.getIterator(), NewMBB);

  BuildMI(NewMBB, DL, TII->get(RISCV::AUIPC), DestReg)
      .addDisp(Symbol, 0, FlagsHi);
  BuildMI(NewMBB, DL, TII->get(SecondOpcode), DestReg)
      .addReg(DestReg)
      .addMBB(NewMBB, RISCVII::MO_PCREL_LO);

  // Move all the rest of the instructions to NewMBB.
  NewMBB->splice(NewMBB->end(), &MBB, std::next(MBBI), MBB.end());
  // Update machine-CFG edges.
  NewMBB->transferSuccessorsAndUpdatePHIs(&MBB);
  // Make the original basic block fall-through to the new.
  MBB.addSuccessor(NewMBB);

  // Make sure live-ins are correctly attached to this new basic block.
  LivePhysRegs LiveRegs;
  computeAndAddLiveIns(LiveRegs, *NewMBB);

  NextMBBI = MBB.end();
  MI.eraseFromParent();
  return true;
}

bool RISCVExpandPseudo::expandLoadLocalAddress(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    MachineBasicBlock::iterator &NextMBBI) {
  return expandAuipcInstPair(MBB, MBBI, NextMBBI, RISCVII::MO_PCREL_HI,
                             RISCV::ADDI);
}

bool RISCVExpandPseudo::expandLoadAddress(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    MachineBasicBlock::iterator &NextMBBI) {
  MachineFunction *MF = MBB.getParent();

  unsigned SecondOpcode;
  unsigned FlagsHi;
  if (MF->getTarget().isPositionIndependent()) {
    const auto &STI = MF->getSubtarget<RISCVSubtarget>();
    SecondOpcode = STI.is64Bit() ? RISCV::LD : RISCV::LW;
    FlagsHi = RISCVII::MO_GOT_HI;
  } else {
    SecondOpcode = RISCV::ADDI;
    FlagsHi = RISCVII::MO_PCREL_HI;
  }
  return expandAuipcInstPair(MBB, MBBI, NextMBBI, FlagsHi, SecondOpcode);
}

bool RISCVExpandPseudo::expandLoadTLSIEAddress(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    MachineBasicBlock::iterator &NextMBBI) {
  MachineFunction *MF = MBB.getParent();

  const auto &STI = MF->getSubtarget<RISCVSubtarget>();
  unsigned SecondOpcode = STI.is64Bit() ? RISCV::LD : RISCV::LW;
  return expandAuipcInstPair(MBB, MBBI, NextMBBI, RISCVII::MO_TLS_GOT_HI,
                             SecondOpcode);
}

bool RISCVExpandPseudo::expandLoadTLSGDAddress(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    MachineBasicBlock::iterator &NextMBBI) {
  return expandAuipcInstPair(MBB, MBBI, NextMBBI, RISCVII::MO_TLS_GD_HI,
                             RISCV::ADDI);
}

bool RISCVExpandPseudo::expandImplicitOperands(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    MachineBasicBlock::iterator &NextMBBI, unsigned Opcode) {

  // For the Esperanto target, we lower marked vector operations
  // that have explicit inputs to the machine target instruction
  // where they are implicit. This is done by removing any tied input
  // and the last operand which is the implicit m0 reference.
  MachineInstr& MI = *MBBI;
  MachineInstrBuilder B =
      BuildMI(MBB, MBBI, MI.getDebugLoc(), TII->get(Opcode));
  unsigned NumOps = MI.getNumExplicitOperands();
  for (auto Pair : enumerate(MI.operands())) {
    if (Pair.index() == NumOps - 1)
      continue;
    if (Pair.value().isReg() && !Pair.value().isDef() && Pair.value().isTied())
      continue;
    B.add(Pair.value());
  }
  MI.eraseFromParent();
  return true;
}

#ifdef ESPERANTO
bool RISCVExpandPseudo::expandStackOps(MachineBasicBlock &MBB,
                                       MachineBasicBlock::iterator MBBI,
                                       MachineBasicBlock::iterator &NextMBBI) {
  unsigned Opcode =
      (MBBI->getOpcode() == RISCV::StackFLQ2 ? RISCV::FLQ2 : RISCV::FSQ2);
  BuildMI(MBB, MBBI, MBBI->getDebugLoc(), TII->get(Opcode))
      .add(MBBI->getOperand(0))
      .add(MBBI->getOperand(2))
      .add(MBBI->getOperand(1))
      .cloneMemRefs(*MBBI);
  MBBI->eraseFromParent();
  return true;
}

bool RISCVExpandPseudo::expandIOTA(MachineBasicBlock &MBB,
                                   MachineBasicBlock::iterator MBBI,
                                   MachineBasicBlock::iterator &NextMBBI) {
  Register DstReg = MBBI->getOperand(0).getReg();
  DebugLoc DL = MBBI->getDebugLoc();

  for (unsigned Idx = 0; Idx < 8; Idx++) {
    BuildMI(MBB, MBBI, DL, TII->get(RISCV::MOV_M_X), RISCV::M0).addReg(RISCV::X0).addImm(1ull << Idx);
    BuildMI(MBB, MBBI, DL, TII->get(RISCV::FBCI_PI), DstReg).addImm(Idx);
  }
  MBBI->eraseFromParent();
  return true;
}

bool RISCVExpandPseudo::expandHARTID(MachineBasicBlock &MBB,
                                   MachineBasicBlock::iterator MBBI,
                                   MachineBasicBlock::iterator &NextMBBI) 
 {
  Register DstReg = MBBI->getOperand(0).getReg();
  DebugLoc DL = MBBI->getDebugLoc();
  BuildMI(MBB, MBBI, DL, TII->get(RISCV::CSRRS), DstReg)
      .addImm(RISCVSysReg::lookupSysRegByName("HARTID")->Encoding)
      .addReg(RISCV::X0);
  MBBI->eraseFromParent();
  return true;
}

bool RISCVExpandPseudo::expandTO_VECTOR(MachineBasicBlock &MBB,
                                        MachineBasicBlock::iterator MBBI,
                                        MachineBasicBlock::iterator &NextMBBI) {
  Register DstReg = MBBI->getOperand(0).getReg();
  DebugLoc DL = MBBI->getDebugLoc();
  BuildMI(MBB, MBBI, DL, TII->get(RISCV::FMV_W_X), DstReg)
      .addReg(MBBI->getOperand(1).getReg());
  MBBI->eraseFromParent();
  return true;
}
#endif

} // end of anonymous namespace

INITIALIZE_PASS(RISCVExpandPseudo, "riscv-expand-pseudo",
                RISCV_EXPAND_PSEUDO_NAME, false, false)
namespace llvm {

FunctionPass *createRISCVExpandPseudoPass() { return new RISCVExpandPseudo(); }

} // end of namespace llvm
