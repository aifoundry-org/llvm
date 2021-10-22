//===- RISCVTargetTransformInfo.h - RISC-V specific TTI ---------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
/// \file
/// This file defines a TargetTransformInfo::Concept conforming object specific
/// to the RISC-V target machine. It uses the target's detailed information to
/// provide more precise answers to certain TTI queries, while letting the
/// target independent and default TTI implementations handle the rest.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_RISCV_RISCVTARGETTRANSFORMINFO_H
#define LLVM_LIB_TARGET_RISCV_RISCVTARGETTRANSFORMINFO_H

#include "RISCVSubtarget.h"
#include "RISCVTargetMachine.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/BasicTTIImpl.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Value.h"

namespace llvm {

class RISCVTTIImpl : public BasicTTIImplBase<RISCVTTIImpl> {
  using BaseT = BasicTTIImplBase<RISCVTTIImpl>;
  using TTI = TargetTransformInfo;

  friend BaseT;

  const RISCVSubtarget *ST;
  const RISCVTargetLowering *TLI;

  const RISCVSubtarget *getST() const { return ST; }
  const RISCVTargetLowering *getTLI() const { return TLI; }

public:
  explicit RISCVTTIImpl(const RISCVTargetMachine *TM, const Function &F)
      : BaseT(TM, F.getParent()->getDataLayout()), ST(TM->getSubtargetImpl(F)),
        TLI(ST->getTargetLowering()) {}

  int getIntImmCost(const APInt &Imm, Type *Ty, TTI::TargetCostKind CostKind);
  int getIntImmCostInst(unsigned Opcode, unsigned Idx, const APInt &Imm, Type *Ty,
                        TTI::TargetCostKind CostKind);
  int getIntImmCostIntrin(Intrinsic::ID IID, unsigned Idx, const APInt &Imm,
                          Type *Ty, TTI::TargetCostKind CostKind);

  // This definition inhibits SLP vectorizer from producing vectorized types
  // that are not currently supported by ISel
  unsigned getNumberOfParts(Type* Tp) {
#ifndef ESPERANTO
    if (auto* VTy = dyn_cast<FixedVectorType>(Tp))
      return VTy->getNumElements();
#endif
    return BasicTTIImplBase::getNumberOfParts(Tp);
  }

#ifdef ESPERANTO
  static const unsigned ETSOC1_VL = 8;
  static const unsigned ETSOC1_WIDTH = 32;

  unsigned getRegisterBitWidth(bool Vector) const {
    if (ST->hasEsperanto() && Vector)
      return ETSOC1_WIDTH * ETSOC1_VL;
    return BasicTTIImplBase::getRegisterBitWidth(Vector);
  }

  Type *validEsperantoType(Type *Ty, unsigned *Scale) {
    auto *VTy = dyn_cast<FixedVectorType>(Ty);
    *Scale = 1;
    if (!VTy)
      return Ty;
    if (!ST->hasEsperanto() || VTy->getNumElements() > ETSOC1_VL)
      return nullptr;
    Type *ETy = VTy->getElementType();
    unsigned Bits = ETy->getScalarSizeInBits();
    if (Bits == 64) {
      *Scale = VTy->getNumElements();
      return ETy;
    }
    return (Bits == ETSOC1_WIDTH || (0 < Bits && Bits < ETSOC1_WIDTH &&
                                     VTy->getNumElements() == ETSOC1_VL))
               ? ETy
               : nullptr;
  }
#endif

  unsigned getArithmeticInstrCost(
      unsigned Opcode, Type *Ty,
      TTI::TargetCostKind CostKind = TTI::TCK_RecipThroughput,
      TTI::OperandValueKind Opd1Info = TTI::OK_AnyValue,
      TTI::OperandValueKind Opd2Info = TTI::OK_AnyValue,
      TTI::OperandValueProperties Opd1PropInfo = TTI::OP_None,
      TTI::OperandValueProperties Opd2PropInfo = TTI::OP_None,
      ArrayRef<const Value *> Args = ArrayRef<const Value *>(),
      const Instruction *CxtI = nullptr) {
#ifdef ESPERANTO
    unsigned Scale = 1;
    Ty = validEsperantoType(Ty, &Scale);
    if (!Ty)
      return 10000;
    return Scale * BasicTTIImplBase::getArithmeticInstrCost(
                       Opcode, Ty, CostKind, Opd1Info, Opd2Info, Opd1PropInfo,
                       Opd2PropInfo, Args, CxtI);
#else
    if (isa<FixedVectorType>(Ty))
      return 10000;
    return BasicTTIImplBase::getArithmeticInstrCost(
        Opcode, Ty, CostKind, Opd1Info, Opd2Info, Opd1PropInfo, Opd2PropInfo,
        Args, CxtI);
#endif
  }

  unsigned getCmpSelInstrCost(unsigned Opcode, Type *ValTy, Type *CondTy,
                              TTI::TargetCostKind CostKind,
                              const Instruction *I = nullptr) {

#ifdef ESPERANTO
    unsigned Scale = 1;
    if (CondTy && !validEsperantoType(CondTy, &Scale))
      return 10000;
    return Scale * BasicTTIImplBase::getCmpSelInstrCost(Opcode, ValTy, CondTy,
                                                        CostKind,
#else
    if (CondTy && isa<FixedVectorType>(CondTy))
      return 10000;
    return BasicTTIImplBase::getCmpSelInstrCost(Opcode, ValTy, CondTy, CostKind,
#endif
                                                        I);
  }

  /// Return true if the target supports masked store.
  bool isLegalMaskedStore(Type *DataType, Align Alignment) const {
    unsigned Width = DataType->getScalarSizeInBits();
    if (Width <= 1 || Alignment.value() * 8 < Width)
      return false;
    if (auto *VT = dyn_cast<FixedVectorType>(DataType))
      if (VT->getScalarSizeInBits() != 32 && VT->getNumElements() != 8)
        return false;
    return true;
  }

  bool isLegalMaskedLoad(Type *DataType, Align Alignment) const {
    return isLegalMaskedStore(DataType, Alignment);
  }

  bool isLegalMaskedGather(Type *DataType, Align Alignment) const {
    return isLegalMaskedStore(DataType, Alignment);
  }
  bool isLegalMaskedScatter(Type *DataType, Align Alignment) const {
    return isLegalMaskedStore(DataType, Alignment);
  }
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_RISCV_RISCVTARGETTRANSFORMINFO_H
