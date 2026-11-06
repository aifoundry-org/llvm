#include "RISCV.h"
#include "RISCVInstrInfo.h"
#include "RISCVSubtarget.h"
#include "llvm/CodeGen/MachineFunctionAnalysisManager.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachinePassManager.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"

using namespace llvm;

#define DEBUG_TYPE "riscv-insert-xaif-mask"
#define PASS_NAME "RISC-V Insert XAIFET Mask State"

namespace {

class RISCVInsertXAIFMaskLegacy : public MachineFunctionPass {
public:
  static char ID;

  RISCVInsertXAIFMaskLegacy() : MachineFunctionPass(ID) {}

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override { return PASS_NAME; }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    MachineFunctionPass::getAnalysisUsage(AU);
  }

  MachineFunctionProperties getRequiredProperties() const override {
    return MachineFunctionProperties().setNoVRegs();
  }
};

} // end anonymous namespace

char RISCVInsertXAIFMaskLegacy::ID = 0;

INITIALIZE_PASS(RISCVInsertXAIFMaskLegacy, DEBUG_TYPE, PASS_NAME, false, false)

// Helper: Does this instruction require m0 to be all-ones?
static bool isUnmaskedXAIFVectorOp(const MachineInstr &MI) {
  switch (MI.getOpcode()) {
  case RISCV::AIF_FSGNJ_PS:
  case RISCV::AIF_FSGNJN_PS:
  case RISCV::AIF_FSGNJX_PS:
  case RISCV::AIF_FADD_PS:
  case RISCV::AIF_FSUB_PS:
  case RISCV::AIF_FMUL_PS:
  case RISCV::AIF_FDIV_PS:
  case RISCV::AIF_FMADD_PS:
  case RISCV::AIF_FMSUB_PS:
  case RISCV::AIF_FNMSUB_PS:
  case RISCV::AIF_FNMADD_PS:
  case RISCV::AIF_FADD_PI:
  case RISCV::AIF_FSUB_PI:
  case RISCV::AIF_FMUL_PI:
  case RISCV::AIF_FAND_PI:
  case RISCV::AIF_FOR_PI:
  case RISCV::AIF_FXOR_PI:
  case RISCV::AIF_FBCI_PS:
  case RISCV::AIF_FBCI_PI:
  case RISCV::AIF_FBCX_PS:
  case RISCV::AIF_FBC_PS:
    return true;
  default:
    return false;
  }
}

// Helper: Checks if MI is a full enable mask
static bool isSetM0AllOnes(const MachineInstr &MI) {
  return MI.getOpcode() == RISCV::AIF_MOV_M_X &&
         MI.getNumOperands() >= 3 &&
         MI.getOperand(0).isReg() && MI.getOperand(0).getReg() == RISCV::M0 &&
         MI.getOperand(1).isReg() && MI.getOperand(1).getReg() == RISCV::X0 &&
         MI.getOperand(2).isImm() && MI.getOperand(2).getImm() == 255;
}

// Helper: Does this instruction define/clobber M0 with a custom mask or call?
static bool modifiesM0(const MachineInstr &MI, const TargetRegisterInfo *TRI) {
  return MI.modifiesRegister(RISCV::M0, TRI);
}

static bool runInsertXAIFMask(MachineFunction &MF) {
  const auto &ST = MF.getSubtarget<RISCVSubtarget>();
  if (!ST.hasVendorXAIFET())
    return false;

  const auto &TII = *ST.getInstrInfo();
  const auto *TRI = ST.getRegisterInfo();
  bool Changed = false;

  enum class M0State { Unknown, AllOnes, Custom };

  for (MachineBasicBlock &MBB : MF) {
    M0State CurState = M0State::Unknown;

    for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
      if (isUnmaskedXAIFVectorOp(MI)) {
        if (CurState != M0State::AllOnes) {
          // Insert: aif.mov.m.x m0, zero, 255
          BuildMI(MBB, MI, MI.getDebugLoc(), TII.get(RISCV::AIF_MOV_M_X),
                  RISCV::M0)
              .addReg(RISCV::X0)
              .addImm(255);
          CurState = M0State::AllOnes;
          Changed = true;
        }
      } else if (isSetM0AllOnes(MI)) {
        CurState = M0State::AllOnes;
      } else if (modifiesM0(MI, TRI)) {
        CurState = M0State::Custom;
      }
    }
  }

  return Changed;
}

bool RISCVInsertXAIFMaskLegacy::runOnMachineFunction(MachineFunction &MF) {
  return runInsertXAIFMask(MF);
}

FunctionPass *llvm::createRISCVInsertXAIFMaskLegacyPass() {
  return new RISCVInsertXAIFMaskLegacy();
}

PreservedAnalyses
RISCVInsertXAIFMaskPass::run(MachineFunction &MF,
                             MachineFunctionAnalysisManager &MFAM) {
  return runInsertXAIFMask(MF) ? getMachineFunctionPassPreservedAnalyses()
                                     .preserveSet<CFGAnalyses>()
                               : PreservedAnalyses::all();
}
