//===-- RISCVETMaskAllocator -- custom mask register allocation -----------===//
//
//===----------------------------------------------------------------------===//
//
// This file contains a pass that performs custom allocation of
// Esperanto mask registers
//
//===----------------------------------------------------------------------===//

#include "RISCV.h"
#include "RISCVInstrInfo.h"
#include "RISCVTargetMachine.h"

#include "llvm/CodeGen/LivePhysRegs.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"

using namespace llvm;

#define RISCV_PASS_NAME "RISCV ET Mask allocator"
#define DEBUG_TYPE "mask-alloc"

static cl::opt<bool> EnableMaskAlloc(DEBUG_TYPE "-enable", cl::init(true));

namespace {

class RISCVETMaskAllocator : public MachineFunctionPass {
public:
  const RISCVInstrInfo *TII;
  static char ID;

  RISCVETMaskAllocator() : MachineFunctionPass(ID) {
    initializeRISCVExpandPseudoPass(*PassRegistry::getPassRegistry());
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override { return RISCV_PASS_NAME; }

private:
  // Determine that value that will be in M0 at the
  // end if each basic block represented by a virtual
  // register. 0 indicates an unknown value.
  void computeAtEnd(MachineFunction &MF);

  // Determine which MR0 class registers much be spilled because
  // they are live when some other value is in M0.
  void spillForConflicts(MachineBasicBlock &MBB);

  // Process the block and update mask register references
  // and rematerialize mask values instead of reloading them
  // where possible.
  void processBlock(MachineBasicBlock &MBB);

  MachineRegisterInfo *MRI;

  // The contents of M0 at the end of a block described
  // as the register that defined the value
  DenseMap<MachineBasicBlock *, Register> M0atEnd;

  // A mapping of a MR0 virtual register to a MR register
  // when we determine that the MR0 conflicts with some
  // other MR0 register
  DenseMap<Register, Register> GeneralMask;
#ifndef NDEBUG
  // Debugging only, inverse of GeneralMask
  DenseMap<Register, Register> SourceReg;
#endif

  Register getGeneralMask(Register R) {
    auto Iter = GeneralMask.find(R);
    return (Iter == GeneralMask.end() ? Register(0) : Iter->second);
  }
  // Create an unconstrained MRRegClass virtual register
  // for the MR0 class register and return it. These values
  // are recorded in GeneralMask
  Register makeGeneral(Register R);

  // If a mask register is known to hold a specific
  // set of lanes, we record that here.
  DenseMap<Register, unsigned> Lanes;
  unsigned getMaskLanes(Register R) {
    auto Iter = Lanes.find(R);
    return (Iter == Lanes.end() ? 0 : Iter->second);
  }

  // Find the register corrsponding to the value in M0
  // at the start of basic block MBB.
  Register getInputM0(MachineBasicBlock &MBB) {
    bool First = true;
    Register Current(0);
    for (MachineBasicBlock *P : MBB.predecessors()) {
      auto Iter = M0atEnd.find(P);
      if (Iter == M0atEnd.end())
        continue;
      if (First) {
        First = false;
        Current = Iter->second;
      } else if (Current != Iter->second) {
        Current = 0;
        break;
      }
    }
    return Current;
  }

  // If MI has an operand constrained to be M0, return it.
  // Otherwise null.
  MachineOperand *getM0Ref(MachineInstr &MI) {
    const MCInstrDesc &Desc = MI.getDesc();
    for (unsigned Idx = 0; Idx < Desc.getNumOperands(); Idx++)
      if (Desc.OpInfo[Idx].RegClass == RISCV::MR0RegClassID)
        return &MI.getOperand(Idx);
#if 0
    for (MachineOperand &Op : MI.explicit_operands()) {
      if (!Op.isReg())
        continue;
      Register R = Op.getReg();
      if (R.isPhysical())
        continue;
      if (MRI->getRegClass(R) == &RISCV::MR0RegClass)
        return &Op;
      }
#endif
    return nullptr;
  };

  // If MI has an operand constrained to be M0, return the
  // register currently stored in that operand.
  Register getM0RefReg(MachineInstr &MI) {
    if (MachineOperand *Op = getM0Ref(MI))
      return Op->getReg();
    return 0;
  }

  // True if R correspond to the register X0 or a copy of it.
  bool isZero(Register R) {
    if (R == RISCV::X0)
      return true;
    if (R.isPhysical())
      return false;
    MachineInstr *Def = MRI->getVRegDef(R);
    return (Def && Def->isCopy() && isZero(Def->getOperand(1).getReg()));
  };

  // Return the bit mask of lanes set by this instruction
  // or 0 if it does not set any lanes.
  unsigned setsMaskLanes(const MachineInstr &MI) {
    if (MI.isCopy()) {
      Register R = MI.getOperand(1).getReg();
      if (R.isPhysical())
        return 0;
      MachineInstr *Def = MRI->getVRegDef(R);
      return (Def ? setsMaskLanes(*Def) : 0);
    }
    return (MI.getOpcode() == RISCV::MOV_M_X &&
                    isZero(MI.getOperand(1).getReg())
                ? MI.getOperand(2).getImm()
                : 0);
  }

  // True if R is a virtual register in class MR0 (must be allocated to m0)
  bool isMR0(Register R) {
    return R && R.isVirtual() && MRI->getRegClass(R) == &RISCV::MR0RegClass;
  }
};

char RISCVETMaskAllocator::ID = 0;

bool RISCVETMaskAllocator::runOnMachineFunction(MachineFunction &MF) {

  if (!EnableMaskAlloc || MF.getFunction().hasOptNone() ||
      !MF.getSubtarget<RISCVSubtarget>().hasEsperanto())
    return false;

  TII = static_cast<const RISCVInstrInfo *>(MF.getSubtarget().getInstrInfo());
  MRI = &MF.getRegInfo();
  LLVM_DEBUG({
    dbgs() << "Before mask allocation\n";
    MF.dump();
  });
  M0atEnd.clear();
  GeneralMask.clear();
  Lanes.clear();
#ifndef NDEBUG
  SourceReg.clear();
#endif
  computeAtEnd(MF);
  if (M0atEnd.empty())
    return false;
  for (MachineBasicBlock &MBB : MF)
    spillForConflicts(MBB);
  for (MachineBasicBlock &MBB : MF)
    processBlock(MBB);
  LLVM_DEBUG({
    dbgs() << "After mask allocation\n";
    MF.dump();
  });
  return !GeneralMask.empty();
}

void RISCVETMaskAllocator::computeAtEnd(MachineFunction &MF) {
  bool Changed;
  do {
    // A simple data flow problem where we compute
    // the mask value symbolic at the bottom of a block making
    // optimistic assumptions about blocks not yet seen and
    // pessimistic assumptions about calls and inline assembly.
    Changed = false;
    for (MachineBasicBlock &MBB : MF) {
      Register Current = getInputM0(MBB);
      for (MachineInstr &MI : MBB) {
        if (Register M0 = getM0RefReg(MI)) {
          if (M0 != Current)
            Current = M0;
        } else if (MI.isInlineAsm() ||
                   any_of(MI.operands(),
                          [](MachineOperand &Op) { return Op.isRegMask(); }))
          Current = 0; // Calls kill masks
      }
      Register &End = M0atEnd[&MBB];
      Changed |= (End && End != Current);
      End = Current;
      LLVM_DEBUG(dbgs() << "at end BB" << MBB.getNumber() << " %"
                        << (int)(Current ? Current.virtRegIndex() : -1)
                        << "\n");
    }
  } while (Changed);
}

void RISCVETMaskAllocator::spillForConflicts(MachineBasicBlock &MBB) {
  Register Current = getInputM0(MBB);
  for (MachineInstr &MI : MBB) {
    // If this instruction has an M0 reference that is not
    // the current M0 value, then we will "spill" the
    // that register and later insert a copy here.
    Register M0 = getM0RefReg(MI);
    if (M0 && M0 != Current) {
      makeGeneral(M0);
      LLVM_DEBUG(dbgs() << "Reload M0 %" << M0.virtRegIndex() << " from %"
                        << getGeneralMask(M0).virtRegIndex() << "\n");
      Current = M0;
    }

    LLVM_DEBUG(dbgs() << "spill %" << (Current ? Current.virtRegIndex() : 0)
                      << " " << MI);
    // We might have register marked as M0 through propagation of register
    // classes so we look for those here: This handles the case such as
    //  %4 = maskor  %1, %2  where both %1 and %2 are  MR0 class.
    for (MachineOperand &Op : MI.explicit_uses()) {
      if (!Op.isReg())
        continue;
      Register M = Op.getReg();
      if (M != Current && isMR0(M)) {
        LLVM_DEBUG(dbgs() << "Conflicting M %" << M.virtRegIndex() << " from %"
                          << getGeneralMask(M).virtRegIndex() << " for " << MI);
        makeGeneral(M);
      }
    }

    // Update the notion of what is the current MR0
    for (MachineOperand &Def : MI.defs()) {
      Register M = Def.getReg();
      if (isMR0(M))
        Current = M;
    }

    // Note where an mask is set to a constant set of lanes.
    if (unsigned L = setsMaskLanes(MI)) {
      Lanes.try_emplace(MI.getOperand(0).getReg(), L);
      LLVM_DEBUG(dbgs() << format("Lanes 0x%x ", L) << MI);
    }
  }
}

#ifndef NDEBUG
static unsigned DebugCount = 0;
#endif

void RISCVETMaskAllocator::processBlock(MachineBasicBlock &MBB) {
  Register Current = getInputM0(MBB);
  // TODO -- we should avoid reloading register at a loop top
  //   when it is not redefined in the loop.
  if (Current && GeneralMask.count(Current))
    Current = 0;

  Register CurrentSrc = 0;
  unsigned CurrentLanes = 0;
  LLVM_DEBUG(dbgs() << "\n block " << MBB.getNumber() << "\n");
  MachineBasicBlock::iterator Cur = MBB.getFirstNonPHI();
  MachineBasicBlock::iterator End = MBB.end();
  while (Cur != End) {
    Register Prior = Current;
    unsigned PriorLanes = CurrentLanes;
    MachineInstr &MI = *Cur++;
    MachineOperand *M0 = getM0Ref(MI);
    // If there is an M0 constrained register,
    // update our notion of what is in M0 to match
    // what this instruction neeeds.
    if (M0) {
      Register R = M0->getReg();
      if (R != Current) {
        Register VR = getGeneralMask(R);
        assert(VR && "Should have spilled register");
        if (VR != CurrentSrc) {
          // We need to reload a new value into M0 at this point.
          // We create a new MR0 register to hold the value.
          CurrentSrc = VR;
          Current = MRI->createVirtualRegister(&RISCV::MR0RegClass);
          unsigned Lanes = getMaskLanes(R);
          if (Lanes) {
            if (Lanes == CurrentLanes) {
              // THe new value is the same as the previous MR0 so
              // we just copy which ends the old live range and creates a new
              // one that should be elimianted by coalescing.
              BuildMI(MBB, &MI, MI.getDebugLoc(), TII->get(RISCV::COPY),
                      Current)
                  .addReg(Prior);
              LLVM_DEBUG(dbgs()
                         << "rematerialize by copy %" << Current.virtRegIndex()
                         << " <- %" << CurrentSrc.virtRegIndex()
                         << format(" as 0x%x from %d\n", Lanes,
                                   SourceReg[CurrentSrc].virtRegIndex()));
            } else {
              // We can rematerialize a value rather than making a copy from a
              // value that might spill
              BuildMI(MBB, &MI, MI.getDebugLoc(), TII->get(RISCV::MOV_M_X),
                      Current)
                  .addReg(RISCV::X0)
                  .addImm(Lanes);
              LLVM_DEBUG(dbgs()
                         << "rematerialize %" << Current.virtRegIndex()
                         << " <- %" << CurrentSrc.virtRegIndex()
                         << format("as 0x%x from %d\n", Lanes,
                                   SourceReg[CurrentSrc].virtRegIndex()));
              CurrentLanes = Lanes;
            }
          } else {

            // Copy from the unconstrained mask register to the MR0
            // register. We use  a MASKAND rather than a COPY to prevent
            // the register allocator from coalescing and which has
            // the effect of incorrectly treating the CurrentSrc as MR0
            CurrentLanes = getMaskLanes(CurrentSrc);
            BuildMI(MBB, &MI, MI.getDebugLoc(), TII->get(RISCV::MASKAND),
                    Current)
                .addReg(CurrentSrc)
                .addReg(CurrentSrc);
            LLVM_DEBUG(dbgs()
                       << "add copy %" << Current.virtRegIndex() << " <- %"
                       << CurrentSrc.virtRegIndex() << " from %"
                       << SourceReg[CurrentSrc].virtRegIndex() << "\n");
          }
        }
        assert(Current != 0 && "Invalid mask register");
        M0->setReg(Current);
      }
    }

    // If we moved registers to general register, update the non-m0 references
    for (MachineOperand &Op : MI.explicit_operands()) {
      if (&Op == M0 || !Op.isReg()) {
        if (Op.isRegMask()) {
          // assume a call that kills
          Current = 0;
          CurrentSrc = 0;
          CurrentLanes = 0;
        }
        continue;
      }
      Register R = Op.getReg();
      if (!R.isVirtual())
        continue;
      if (Register New = getGeneralMask(R))
        Op.setReg(New);
      else if (Op.isDef() && MRI->getRegClass(R) == &RISCV::MR0RegClass) {
        Current = R;
        CurrentSrc = R;
        CurrentLanes = 0;
      }
    }
    if (MI.isInlineAsm()) {
      Current = 0;
      CurrentSrc = 0;
      CurrentLanes = 0;
    }
    LLVM_DEBUG(dbgs() << DebugCount << " process %"
                      << (int)(Current ? Current.virtRegIndex() : -1) << " -> %"
                      << (int)(CurrentSrc ? CurrentSrc.virtRegIndex() : -1)
                      << " L" << CurrentLanes << " " << MI);
    // Some additional cleanup for copies
    if (MI.isCopy()) {
      Register Dst = MI.getOperand(0).getReg();
      Register Src = MI.getOperand(1).getReg();
      if (Src == Dst)
        MI.removeFromParent();
      else if (isMR0(Dst) && Src.isVirtual()) {

        if (unsigned L = getMaskLanes(Src)) {
          if (L == PriorLanes) {
            // Copy from the current M0 register since it has the right lanes
            // set. this should be eliminated by coalescing
            MI.getOperand(1).setReg(Prior);
          } else {
            // Rematerialize the value in Dst rather than risking a spill of
            // Src/
            BuildMI(MBB, &MI, MI.getDebugLoc(), TII->get(RISCV::MOV_M_X),
                    Current)
                .addReg(RISCV::X0)
                .addImm(L);
            MI.removeFromParent();
          }
        } else {
          // Change the copy so we
          // don't allow an MR0 register to propagate its class
          BuildMI(MBB, &MI, MI.getDebugLoc(), TII->get(RISCV::MASKAND), Dst)
              .addReg(Src)
              .addReg(Src);
          MI.removeFromParent();
        }
      }
    }
#ifndef NDEBUG
    DebugCount += 1;
#endif
  }
}

Register RISCVETMaskAllocator::makeGeneral(Register R) {
  auto Iter = GeneralMask.find(R);
  if (Iter != GeneralMask.end())
    return Iter->second;

  Register G{0};
  MachineInstr *Def = MRI->getVRegDef(R);
  if (Def->isCopy()) {
    Register Src = Def->getOperand(1).getReg();
    if (Src.isVirtual()) {
      if (MRI->getRegClass(Src) == &RISCV::MR0RegClass)
        G = makeGeneral(Src);
      else
        G = Src;
    }
  }
  if (!G)
    G = MRI->createVirtualRegister(&RISCV::MRRegClass);
  if (unsigned L = getMaskLanes(R)) {
    Lanes.try_emplace(G, L);
    LLVM_DEBUG(dbgs() << format("Lanes 0x%x for %%d\n", L, G.virtRegIndex()));
  }
  GeneralMask.try_emplace(R, G);
#ifndef NDEBUG
  SourceReg.try_emplace(G, R);
#endif
  LLVM_DEBUG(dbgs() << "map %" << R.virtRegIndex() << " to %"
                    << G.virtRegIndex() << "\n");
  return G;
}

} // end of anonymous namespace

INITIALIZE_PASS(RISCVETMaskAllocator, "riscv-expand-pseudo", RISCV_PASS_NAME,
                false, false)
namespace llvm {
FunctionPass *createRISCVETMaskAllocatorPass() {
  return new RISCVETMaskAllocator();
}

} // end of namespace llvm
