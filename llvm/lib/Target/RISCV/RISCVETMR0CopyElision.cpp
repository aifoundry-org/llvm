//===-- RISCVETMR0CopyElision -- MR0 copy elision -------------------------===//
//
//===----------------------------------------------------------------------===//
//
// This file contains a pass that performs elision of copies when destination
// is MR0.
//
//===----------------------------------------------------------------------===//

#include "RISCV.h"
#include "RISCVInstrInfo.h"
#include "RISCVTargetMachine.h"

#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/CodeGen/LivePhysRegs.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"

using namespace llvm;

#define RISCV_PASS_NAME "RISCV ET MR0 copy elision"
#define DEBUG_TYPE "mr0-copy-elision"

static cl::opt<bool> EnableMR0CopyElision(DEBUG_TYPE "-enable", cl::init(true));

namespace {

class MaskValue {
public:
  enum class Type {
    None,  /// Mask value is not defined
    Const, /// Mask value is defined as a build-time constant
    Reg    /// Mask value is defined as an expression (that either depends of
        /// runtime inputs or simply it is not trivially provable whether it is
        /// a constant)
  };

private:
  Type type{Type::None};
  union {
    uint32_t Const;
    Register Reg;
  } Data{0};

public:
  bool isValid() const { return type != Type::None; }
  bool isConst() const { return type == Type::Const; }
  bool isReg() const { return type == Type::Reg; }

  uint32_t getConst() const {
    assert(type == Type::Const);
    return Data.Const;
  }

  uint32_t getReg() const {
    assert(type == Type::Reg);
    return Data.Reg;
  }

  void invalidate() { type = Type::None; }

  void setConst(uint32_t Const) {
    type = Type::Const;
    Data.Const = Const;
  }

  void setReg(Register Reg) {
    type = Type::Reg;
    Data.Reg = Reg;
  }

  bool operator==(const MaskValue &value) const {
    if (type != value.type)
      return false;
    bool result;
    switch (value.type) {
    case Type::None:
      result = true;
      break;
    case Type::Const:
      result = getConst() == value.getConst();
      break;
    case Type::Reg:
      result = getReg() == value.getReg();
      break;
    default:
      assert(false);
      result = false;
      break;
    }
    return result;
  }

  bool operator!=(const MaskValue &value) const {
    return not operator==(value);
  }
};

class RISCVETMR0CopyElision : public MachineFunctionPass {
public:
  const RISCVInstrInfo *TII;
  static char ID;

  RISCVETMR0CopyElision() : MachineFunctionPass(ID) {
    initializeRISCVExpandPseudoPass(*PassRegistry::getPassRegistry());
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override { return RISCV_PASS_NAME; }

private:
  // Determine that value that will be in M0 at the
  // end if each basic block represented by a virtual
  // register. 0 indicates an unknown value.
  void computeAtEnd(MachineFunction &MF);

  // Determine which MR0 class registers must be spilled because
  // they are live when some other value is in M0.
  void spillForConflicts(MachineBasicBlock &MBB);

  // Process the block and update mask register references
  // and rematerialize mask values instead of reloading them
  // where possible.
  void processBlock(MachineBasicBlock &MBB);

  MachineRegisterInfo *MRI;

  // The contents of M0 at the end of a block described
  // as the register that defined the value
  DenseMap<MachineBasicBlock *, MaskValue> M0atEnd;

  // True if R correspond to the register X0 or a copy of it.
  bool isZero(Register R) const {
    if (R == RISCV::X0)
      return true;
    if (R.isPhysical())
      return false;
    MachineInstr *Def = MRI->getVRegDef(R);
    return (Def && Def->isCopy() && isZero(Def->getOperand(1).getReg()));
  };

  /// \brief Return the value set on MR0
  void valueSetOnMR0(const MachineInstr &MI, MaskValue &value) const {
    // If at the begin of the copies chain and destination is not mr0, this
    // instruction definately does not set mr0 to any value
    Register dest = (MI.getNumOperands() and MI.getOperand(0).isReg()) > 0
                        ? MI.getOperand(0).getReg()
                        : Register(0);
    if (not isVirtualMR0(dest)) {
      // The caller to this function should have confirmed that MR0 is set
      // prior to calling
      assert(false);
      value.invalidate();
      return;
    }
    LLVM_DEBUG(dbgs() << "It is virtual MR0\n");
    // Detect the common pattern of a chain of zero or more copies ending with:
    // - MOV_M_X materializing an immediate on the MR0 register
    // - ADDI materializing an immediate on a GPR register
    // - something else
    Register source = Register(0);
    const MachineInstr *current = &MI;
    while (current->isCopy()) {
      LLVM_DEBUG(dbgs() << "Skipping one step on the chain of copies...\n");
      source = current->getOperand(1).getReg();
      current = MRI->getVRegDef(source);
      assert(current);
    }

    if (current->getOpcode() == RISCV::MOV_M_X and
        isZero(current->getOperand(1).getReg())) {
      uint32_t Const = current->getOperand(2).getImm();
      value.setConst(Const);
      LLVM_DEBUG(dbgs() << "At the end of the chain of copies found const "
                           "value from mov.m.x ("
                        << Const << ")\n");
      return;
    } else if (current->getOpcode() == RISCV::ADDI and
               current->getNumOperands() >= 2 and
               current->getOperand(1).isReg() and
               isZero(current->getOperand(1).getReg())) {
      uint32_t Const = current->getOperand(2).getImm();
      value.setConst(Const);
      LLVM_DEBUG(
          dbgs()
          << "At the end of the chain of copies found const value from addi ("
          << Const << ")\n");
      return;
    } else if (source.isValid()) {
      value.setReg(source);
      LLVM_DEBUG(dbgs() << "Using vreg (" << source << ")\n");
      return;
    }

    // The mask is set, but we bailout trying to guess its value or its origin
    value.setReg(dest);
  }

  /// @brief True if R is in class MR0
  bool isVirtualMR0(Register R) const {
    assert(R.isValid());
    return R.isVirtual() and MRI->getRegClass(R) == &RISCV::MR0RegClass;
  }

  /// @brief True if R is in class MR
  bool isVirtualMR(Register R) const {
    assert(R.isValid());
    return R.isVirtual() and MRI->getRegClass(R) == &RISCV::MRRegClass;
  }

  /// @brief True if R is a virtual register in GPR class
  bool isVirtualGPR(Register R) const {
    assert(R.isValid());
    return R.isVirtual() and MRI->getRegClass(R) == &RISCV::GPRRegClass;
  }

  /// @brief Whether one of the iterated MachineOperand items is a register in
  /// MR0 class
  /// @param operands Range to iterate
  /// @param whichOne Which iterated operand is in MR0 class
  /// @return true iif one of the operands is in MR0
  bool anyMR0(iterator_range<MachineInstr::mop_iterator> operands,
              Register &whichOne) const {
    for (auto op : operands) {
      if (op.isReg()) {
        Register Dest = op.getReg();
        if (isVirtualMR0(Dest)) {
          whichOne = Dest;
          return true;
        }
      }
    }
    whichOne = Register(0);
    return false;
  }

  /// @brief Whether one of the MachineOperand items produced by the
  /// MachineInstr is a register in MR0 class
  /// @param MI MachineInstr to analize
  /// @param dest Which destination operand is in MR0 class
  /// @return true iif one of the operands is in MR0
  bool producesMR0Value(MachineInstr &MI, Register &dest) const {
    return anyMR0(MI.defs(), dest);
  }

  /// @brief Whether one of the MachineOperand items produced by the
  /// MachineInstr is a register in MR0 class
  /// @param MI MachineInstr to analize
  /// @return true iif one of the operands is in MR0
  bool producesMR0Value(MachineInstr &MI) const {
    Register ignored;
    return anyMR0(MI.defs(), ignored);
  }

  /// @brief Whether one of the MachineOperand items consumed by the
  /// MachineInstr is a register in MR0 class
  /// @param MI MachineInstr to analize
  /// @param whichOne Which consumed operand is in MR0 class
  /// @return true iif one of the operands is in MR0
  bool consumesMR0Value(MachineInstr &MI, Register &whichOne) const {
    Register ignored;
    return anyMR0(MI.uses(), ignored);
  }

  /// @brief For a given MachineInstr that produces an MR0 value, materialize
  /// its instruction
  bool emitMR0ValueProduction(MachineBasicBlock &MBB, MachineInstr &MI,
                              Register dest, const MaskValue &value);

  /// @brief For a given MachineBasicBlock, materialize MIR nodes that write to
  /// MR0
  bool materializeMR0Values(MachineBasicBlock &MBB);
};

char RISCVETMR0CopyElision::ID = 0;

bool RISCVETMR0CopyElision::runOnMachineFunction(MachineFunction &MF) {
  if (!EnableMR0CopyElision || MF.getFunction().hasOptNone() ||
      !MF.getSubtarget<RISCVSubtarget>().hasEsperanto())
    return false;

  TII = static_cast<const RISCVInstrInfo *>(MF.getSubtarget().getInstrInfo());
  MRI = &MF.getRegInfo();

  M0atEnd.clear();
  computeAtEnd(MF);

  bool changed = false;
  for (MachineBasicBlock &MBB : MF) {
    changed |= materializeMR0Values(MBB);
  }

  return changed;
}

void RISCVETMR0CopyElision::computeAtEnd(MachineFunction &MF) {
  for (MachineBasicBlock *MBB : post_order(&MF)) {
    MaskValue value;
    value.invalidate();
    for (MachineInstr &MI : make_early_inc_range(reverse(*MBB))) {
      if (producesMR0Value(MI)) {
        valueSetOnMR0(MI, value);
        break;
      }
    }
    M0atEnd[MBB] = value;
  }
}

bool RISCVETMR0CopyElision::emitMR0ValueProduction(MachineBasicBlock &MBB,
                                                   MachineInstr &MI,
                                                   Register dest,
                                                   const MaskValue &value) {
  bool emitted = false;
  auto DL = MI.getDebugLoc();
  if (value.isConst()) {
    // Materialize a constant
    uint32_t srcImm = value.getConst();
    LLVM_DEBUG(dbgs() << "Emitting const MR0 " << srcImm << "\n");
    BuildMI(MBB, MI, DL, TII->get(RISCV::MOV_M_X), dest)
        .addReg(RISCV::X0)
        .addImm(srcImm);
    MI.removeFromParent();
    emitted = true;
  } else if (value.isReg()) {
    Register srcReg = value.getReg();
    if (isVirtualMR0(srcReg)) {
      LLVM_DEBUG(dbgs() << "Omitting copy from " << srcReg << " to " << dest
                        << "\n");
      emitted = false;
    } else if (isVirtualMR(srcReg)) {
      LLVM_DEBUG(dbgs() << "Emitting copy from MR " << srcReg << " to "
                        << dest << "\n");
      BuildMI(MBB, MI, DL, TII->get(RISCV::MASKAND), dest)
          .addReg(srcReg)
          .addReg(srcReg);
      MI.removeFromParent();
      emitted = true;
    } else {
      assert(isVirtualGPR(srcReg));
      LLVM_DEBUG(dbgs() << "Emitting copy from GPR " << srcReg << " to "
                        << dest << "\n");
      BuildMI(MBB, MI, DL, TII->get(RISCV::MOV_M_X), dest)
          .addReg(srcReg)
          .addImm(0);
      MI.removeFromParent();
      emitted = true;
    }
  }
  return emitted;
}

bool RISCVETMR0CopyElision::materializeMR0Values(MachineBasicBlock &MBB) {
  MaskValue current;
  current.invalidate();
  bool changed = false;
  for (MachineInstr &MI : make_early_inc_range(MBB)) {
    LLVM_DEBUG(dbgs() << MI);
    Register dest;
    if (producesMR0Value(MI, dest)) {
      LLVM_DEBUG(dbgs() << "Produces MR0\n");
      MaskValue value;
      valueSetOnMR0(MI, value);
      assert(value.isValid());
      if (not(current.isValid() and current == value)) {
        if (emitMR0ValueProduction(MBB, MI, dest, value)) {
          changed = true;
          current = value;
        }
      }
    }
  }
  return changed;
}

} // end of anonymous namespace

INITIALIZE_PASS(RISCVETMR0CopyElision, "riscv-expand-pseudo", RISCV_PASS_NAME,
                false, false)
namespace llvm {
FunctionPass *createRISCVETMR0CopyElisionPass() {
  return new RISCVETMR0CopyElision();
}

} // end of namespace llvm