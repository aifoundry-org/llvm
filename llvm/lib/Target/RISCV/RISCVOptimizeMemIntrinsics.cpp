//===- RISCVOptimizeMemIntrinsics.cpp - optimize esperanto vector ops -----===//
//
//
//===----------------------------------------------------------------------===//
//
// This is an Esperanto specific pass that looks for vector loads and stores
// whose addresses are loop invariant and attempts to replacement to before
// "scalar replacement" on them so all the memory traffic is done outside
// of the loop. This applies only to innermost loops and only uses alias
// analysis to determine data dependences
//
// We also look for redundant loads which can be pair with a preceding
// load or store to the same location.
//
// We also hoisted, in a register-pressure aware manner, loop invariant
// vector operations of the loop. Where safe, we replace predicating masks
// with all-1s to enable this poisting.
//
// We also look for vector select operations where we can fold the
// selected into a preceding definiton by adding the other operand
// of the selected as the pass-through input.
//
//===----------------------------------------------------------------------===//
#ifdef ESPERANTO
#include "RISCV.h"
#include "RISCVTargetMachine.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/IntrinsicsRISCV.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include <type_traits>

using namespace llvm;

#define DEBUG_TYPE "opt-mem"

static cl::opt<bool>
    EnableOptMem(DEBUG_TYPE, cl::init(true),
                 cl::desc("Enable vector->register optimization"));

static cl::opt<bool> HoistInvariants(
    DEBUG_TYPE "-hoist", cl::init(false),
    cl::desc("Hoist invariant vector operations out of inner loops"));

#ifndef NDEBUG
static cl::opt<unsigned>
    OptLimit(DEBUG_TYPE "-limit",
             cl::init(std::numeric_limits<unsigned>::max()));
#endif


static Intrinsic::ID getStoreForm(Intrinsic::ID ID);

namespace {
// This structure represent all information in an ET vector intrinsic memory access
// We may the ID for loads to the corresponding stores so those are treated as equal
struct Access {
  using TupleTy = std::tuple<Value *, Value *, Value *, Intrinsic::ID>;
  TupleTy Tuple;
  Value *getAddr() const { return std::get<0>(Tuple); }
  Value *getVectorAddr() const { return (getStoreID() ? getAddr() : nullptr); }
  Value *getIndex() const { return std::get<1>(Tuple); }
  Value *getMask() const { return std::get<2>(Tuple); }
  Intrinsic::ID getStoreID() const { return std::get<3>(Tuple); }
  Access(Value *Addr, Value *Index, Value *Mask, Intrinsic::ID ID)
      : Tuple(Addr, Index, Mask, getStoreForm(ID)) {}
  bool operator==(const Access &Other) const{ return Tuple == Other.Tuple; }
};
} // namespace
namespace llvm {
 template <> struct DenseMapInfo<Access> {
  static inline Access getEmptyKey() { return Access(nullptr, nullptr, nullptr, 0); }
  static inline Access getTombstoneKey() { return Access(nullptr, nullptr, nullptr, 1); }
  static unsigned getHashValue(const Access &Val) {
    size_t H = reinterpret_cast<size_t>(Val.getAddr());
    H ^= reinterpret_cast<size_t>(Val.getIndex());
    H ^= reinterpret_cast<size_t>(Val.getMask());
    H ^= static_cast<unsigned>(Val.getStoreID());
    return (H >> 32) ^ H;
  }
  static bool isEqual(const Access &LHS, const Access &RHS) {
    return LHS == RHS;
  }
  // static unsigned getHashValue(const T &Val);
  // static bool isEqual(const T &LHS, const T &RHS);
};
}

namespace {
class RISCVOptimizeMemIntrinsics : public FunctionPass {

public:
  static char ID; // Pass identification, replacement for typeid

  RISCVOptimizeMemIntrinsics(RISCVTargetMachine &TM)
      : FunctionPass(ID), TM(&TM) {
    initializeRISCVOptimizeMemIntrinsicsPass(*PassRegistry::getPassRegistry());
  }
  RISCVOptimizeMemIntrinsics() : FunctionPass(ID), TM(nullptr) {
    initializeRISCVOptimizeMemIntrinsicsPass(*PassRegistry::getPassRegistry());
  }

  bool runOnFunction(Function &F) override;

  void rewriteGatherScatters(Function &F);

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.addRequired<AAResultsWrapperPass>();
    AU.addRequired<LoopInfoWrapperPass>();
  }

private:
  RISCVTargetMachine *TM = nullptr;
  AliasAnalysis *AA = nullptr;
  Function *CurrentFunction = nullptr;

  bool MadeChange;

  // Walk down the loop tree to find inner most loops
  // to which we apply transformations
  void analyzeLoop(Loop &LI);

  // Return an address value if this is an vector load or store
  // operand whose address and mask are loop invariant.
  bool isInvariantVector(Instruction &I, Loop &LI);

  // Return the operand that is the value to be stored
  Value *getVectorStoreInput(Instruction &I);

  // Return the memory access information for ET intrinsic operation I
  Access getMemoryAccess(Instruction &I);

  // True if two instructions that are vector memory operations 
  // are not aliased
  bool noAlias(Instruction& I, Instruction& J) {
    Value *IA = getMemoryAccess(I).getAddr();
    Value *JA = getMemoryAccess(J).getAddr();
    return AA->isNoAlias(IA,JA);
  }

  // Look for a vector load which can be matched with a preceding
  // identical load or corresponding store. Also look for 
  // preceding dead store covered by Iq
  bool combinePriorMemOp(Instruction &I,
                         const SmallVectorImpl<Instruction *> &VectorOps,
                         SmallVectorImpl<Instruction*> *DeadOps,
                         Loop &LI);

  // Try to fold a vector select into previous instructions
  bool foldSelect(Instruction &I);

  void rewriteGather(Instruction &I);
  void rewriteScatter(Instruction &I);
  bool isUniform(Value *Addr, Value **Base, Value **Index_, unsigned *Scale);

  DenseMap<Instruction *, unsigned> Index; // Debugging only
  unsigned getIndex(Instruction &I) {
    auto Iter = Index.find(&I);
    return (Iter == Index.end() ? 0 : Iter->second);
  }
};

} // end anonymous namespace

char RISCVOptimizeMemIntrinsics::ID = 0;

char &RISCVOptimizeMemIntrinsicsID = RISCVOptimizeMemIntrinsics::ID;

INITIALIZE_PASS(RISCVOptimizeMemIntrinsics, DEBUG_TYPE,
                "Optimize Esperanto Mem Operations", false, false)

FunctionPass *
llvm::createRISCVOptimizeMemIntrinsicsPass(RISCVTargetMachine &TM) {
  return new RISCVOptimizeMemIntrinsics(TM);
}

bool RISCVOptimizeMemIntrinsics::runOnFunction(Function &F) {
  CurrentFunction = &F;
  rewriteGatherScatters(F);

  if (!EnableOptMem)
    return false;
  if (!TM->getSubtargetImpl(F)->hasEsperanto())
    return false;
  AA = &getAnalysis<AAResultsWrapperPass>().getAAResults();
  LoopInfo &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();

  MadeChange = false;
  for (Loop *L : LI.getTopLevelLoops())
    analyzeLoop(*L);
  LLVM_DEBUG({
    if (MadeChange) {
      dbgs() << "After optmem\n";
      F.dump();
    }
  });
  return MadeChange;
}

// true if V is a constant or is an isntruction
// outside of innermost loop L.
static bool isInvariant(Value *V, Loop &L) {
  if (auto *I = dyn_cast<Instruction>(V))
    return !L.contains(I);
  return true;
}

// Return the operand index of a mask operand if any
static Optional<size_t> getMaskOperand(Instruction &I) {
  if (I.getNumOperands() < 2)
    return None;

  // Exclude the operands on masks whose last operand
  // can not be simply replaced with all true.
  switch (dyn_cast<CallInst>(&I)->getIntrinsicID()) {
  case Intrinsic::riscv_maskand_m:
  case Intrinsic::riscv_maskor_m:
  case Intrinsic::riscv_maskxor_m:
  case Intrinsic::riscv_masknot_m:
  case Intrinsic::riscv_maskand:
  case Intrinsic::riscv_maskor:
  case Intrinsic::riscv_maskxor:
  case Intrinsic::riscv_masknot:
    return None;
  }
  unsigned Index = I.getNumOperands() - 2;
  Value *Mask = I.getOperand(Index);
  Type *Ty = Mask->getType();
  if (!isa<FixedVectorType>(Ty) || Ty->getScalarSizeInBits() != 1)
    return None;
  return Index;
}

namespace {
// This class monitors register pressure and moves
// loop invariant operations out of a loop where possible
class CodeHoister {
public:
  CodeHoister(Loop &L)
      : L(L), Builder(L.getLoopPredecessor()->getTerminator()) {
    assert(L.getNumBlocks() == 1);
    BasicBlock &BB = **L.block_begin();
    RegPressure = estimateVectorUsage(BB);
  }

  // If I is invarant and register pressure allows,
  // hoist it out of the loop.
  bool tryHoist(Instruction &I) {
    if (RegPressure >= RegPressureLimit || !canHoistVector(I))
      return false;

    // Verify non-mask operands are loop invariant
    Optional<size_t> Mask = getMaskOperand(I);
    for (auto Pair : enumerate(I.operands()))
      if (Mask != Pair.index() && !isInvariant(Pair.value(), L))
        return false;

    if (Mask.hasValue())
      replaceMaskWithAllOnes(I, *Mask);

    // Can we CSE with a previously hoisted term?
    auto Iter = find_if(
        Hoisted, [this, &I](Instruction *Prior) { return matches(*Prior, I); });
    if (Iter != Hoisted.end()) {
      LLVM_DEBUG(dbgs() << "use " << I << "\n");
      I.replaceAllUsesWith(*Iter);
      I.eraseFromParent();
      return true;
    }
    LLVM_DEBUG(dbgs() << "hoist " << I << "\n");
    // Hoist this instruction...
    RegPressure += 1;
    Hoisted.push_back(&I);
    I.moveBefore(L.getLoopPredecessor()->getTerminator());
    return true;
  }

private:
  // An estimate of the number of vector registers needed for the loop
  unsigned RegPressure;
  // A limited on the above value
  const unsigned RegPressureLimit = 28;
  Loop &L;

  IRBuilder<> Builder;

  // Operands which have been hoisted out of the loop
  // which are searched to find CSE's
  SmallVector<Instruction *, 16> Hoisted;

  // A computation of v8i1 all ones, built once on demand.
  Value *allOnes{nullptr};

  // Esimate the number of vector registers need to implement
  // a single-basic-block loop whose block is BB.
  unsigned estimateVectorUsage(BasicBlock &BB);

  // We try to hoist vector intrinsics that don't have any side effects
  bool canHoistVector(Instruction &I) {
    if (auto *C = dyn_cast<CallInst>(&I))
      return (C->getIntrinsicID() && !C->mayReadOrWriteMemory() &&
              !C->mayHaveSideEffects());
    return false;
  }

  // Replace mask operand in position Idx  with all-ones so we
  // to break any loop dependence and improve CSE ability
  void replaceMaskWithAllOnes(Instruction &I, size_t Idx) {
    if (!allOnes)
      allOnes = Builder.CreateIntrinsic(
          llvm::Intrinsic::riscv_mov_m_x_m, {},
          {Builder.getInt64(0), Builder.getInt32(0xff)}, nullptr, "alltrue");
    I.setOperand(Idx, allOnes);
  }

  // True if I1 and I2 compute the same value
  bool matches(Instruction &I1, Instruction &I2) {
    if (I1.getNumOperands() != I2.getNumOperands())
      return false;
    // We know both instructions are intrinsics and the
    // final operand is will discriminant between different
    // intrinsics.
    for (unsigned Idx = 0; Idx < I1.getNumOperands(); Idx++)
      if (I1.getOperand(Idx) != I2.getOperand(Idx))
        return false;
    return true;
  }
};
} // namespace

void RISCVOptimizeMemIntrinsics::analyzeLoop(Loop &LI) {
  if (!LI.getSubLoops().empty()) {
    for (Loop *Subloop : LI)
      analyzeLoop(*Subloop);
    return;
  }

  // Vector loop will only have one block so fare.
  // TODO -- we may need to extend this to multi-block
  // loops because scalar if-statemetns may be preserved as
  // control flow
  if (LI.getNumBlocks() > 1)
    return;

  BasicBlock *Succ = LI.getUniqueExitBlock();
  if (!Succ)
    return;

#ifndef NDEBUG
  static unsigned Count = 0;
  Count += 1;
  if (Count > OptLimit) {
    LLVM_DEBUG(dbgs() << "Reached limit " << OptLimit << "\n");
    return;
  }
#endif

  LLVM_DEBUG(Index.clear());

  // Find all of the stores and the address terms
  // when those address are loop invariant.
  // Panic if we see inline asm.
  using StoreElt = std::pair<Instruction *, Access>;
  SmallVector<StoreElt, 8> Stores;
  BasicBlock &BB = **LI.block_begin();
  LLVM_DEBUG(dbgs() << "analyzing loop " << BB.getName() << "\n");
  for (Instruction &I : BB) {
    LLVM_DEBUG({
      Index.try_emplace(&I, Index.size() + 1);
      dbgs() << getIndex(I) << ": " << I << "\n";
    });
    if (I.mayWriteToMemory())
      Stores.emplace_back(&I, getMemoryAccess(I));
    if (isa<InlineAsm>(I))
      return;
  }

  // Compare all memory accesses with the stores to see if there
  // is any dangerous aliasing.
  for (Instruction &I : BB)
    if (I.mayReadOrWriteMemory()) {
      Access A = getMemoryAccess(I);
      for (StoreElt &S : Stores) {
        if (S.second == A || noAlias(*S.first, I))
          continue;
        LLVM_DEBUG(dbgs() << "Has alias " << getIndex(I) << " " << I << "\n");
        LLVM_DEBUG(dbgs() << "    with  " << getIndex(*S.first) << " " << *S.first << "\n");
        // S and I alias but don't both have the same invariant address
        // so we clear the address field on the store which will prevent
        // anything aliased to it from being rewriten to scalars
        S.second = Access(0, 0, 0, 0);
      }
    }

  // A list of phi nodes created and their associated memory address
  SmallVector<std::pair<PHINode *, Access>, 4> NewPhiNodes;
  // mapping of memory address to current value "in" the memory at
  // that address and the last store (which will be moved out of the
  // loop)
  struct LastRef {
    Instruction *LastStore = nullptr;
    Value *CurrentValue = nullptr;
  };
  using DefMapT = SmallDenseMap<Access, LastRef>;
  DefMapT DefMap;

  // List of vector operations in execution order
  SmallVector<Instruction *, 16> VectorOps;
  // List of stores which have been shown to be dead.
  SmallVector<Instruction *, 8> DeadOps;

  CodeHoister Hoister(LI);

  BasicBlock::iterator Cur = BB.begin();
  BasicBlock::iterator End = BB.end();
  while (Cur != End) {
    Instruction &I = *Cur++;

    // Try to hoist invariant operations out of the loop
    if (HoistInvariants && Hoister.tryHoist(I))
      continue;

    if (foldSelect(I))
      continue;

    if (!I.mayReadOrWriteMemory())
      continue;

    Access I_Access = getMemoryAccess(I);
    llvm::Value *Addr = I_Access.getVectorAddr();
    if (!Addr)
      continue;
#ifndef NDEBUG
    unsigned OpIndex = getIndex(I);
    LLVM_DEBUG(dbgs() << "Checking " << OpIndex << " " << I << "\n");
#endif

    // True if I has some store that is aliased with it that
    // is not the same set of memory locations
    auto hasConflictingStore = [&Stores, I_Access, &I, this]() {
      return !all_of(Stores, [&I, I_Access, this](StoreElt S) {
        return (S.second == I_Access || noAlias(I, *S.first));
      });
    };

    // For non-inviariant operations, we look to combine with
    // an earlier operations
    if (!isInvariantVector(I, LI) || hasConflictingStore()) {
      // CSE redundant vector loads or remember
      // them in execution order
      if (!combinePriorMemOp(I, VectorOps, &DeadOps, LI))
        VectorOps.push_back(&I);
      continue;
    }

    if (I.mayWriteToMemory()) {
      // For stores, record the value stored to memory for subsequent loads
      Value *Value = getVectorStoreInput(I);
      LastRef &Last = DefMap[I_Access];
      Last.CurrentValue = Value;
      // If there was a preceding store, it is now dead and can be removed
      if (Last.LastStore) {
        LLVM_DEBUG(dbgs() << "Remove dead store " << getIndex(*Last.LastStore)
                          << " " << *Last.LastStore << "\n");
        DeadOps.push_back(Last.LastStore);
      }
      Last.LastStore = &I;
      continue;
    }

    auto Iter = DefMap.find(I_Access);
    if (Iter != DefMap.end()) {
      // We have a preceding definition in the loop which we can
      // forward substituted to uses of this load.
      LLVM_DEBUG(dbgs() << "Remove redundant load " << getIndex(I) << " " << I
                        << "\n");
      LLVM_DEBUG(dbgs() << " with " << *Iter->getSecond().CurrentValue << "\n");

      I.replaceAllUsesWith(Iter->getSecond().CurrentValue);
      DeadOps.push_back(&I);
      continue;
    }
    if (!any_of(Stores, [I_Access, this](StoreElt S) {
          return S.second == I_Access;
        })) {
      // This load has no store so we can just hoist it out of the loop.
      // this should already have been done so do nothing for this edge case
      continue;
    }
    // There is a subsequent store in the loop so here we
    // need to hoist the upwards exposed load "I" into the loop header
    // and build a phi node.
    LLVM_DEBUG(dbgs() << "Hoist to loop header " << getIndex(I) << " " << I
                      << "\n");
    auto *Phi = PHINode::Create(I.getType(), 2, "etvec", &*BB.begin());
    DefMap[I_Access].CurrentValue = Phi;
    I.replaceAllUsesWith(Phi);
    BasicBlock *Pred = LI.getLoopPredecessor();
    I.removeFromParent();
    I.insertBefore(Pred->getTerminator());
    Phi->addIncoming(&I, Pred);
    NewPhiNodes.emplace_back(Phi, I_Access);
    MadeChange = true;
  }
  if (!DeadOps.empty()) {
    MadeChange = true;
    for (Instruction *Def : DeadOps)
      Def->eraseFromParent();
  }

  if (DefMap.empty())
    return;
  MadeChange = true;

  // Build back edgse to new phi nodes from final definitions
  // The second component is the address of the to be deleted store
  for (std::pair<PHINode *, Access> P : NewPhiNodes)
    P.first->addIncoming(DefMap[P.second].CurrentValue, &BB);

  // Any stores to sinK?
  if (!any_of(DefMap, [](DefMapT::iterator::reference R) -> bool {
        return R.getSecond().LastStore;
      }))
    return;

  // sink the stores in an epilogue block
  if (!Succ->getUniquePredecessor())
    Succ = SplitBlockPredecessors(Succ, {&BB}, "etvec");
  for (auto &Pair : DefMap) {
    Instruction *S = Pair.getSecond().LastStore;
    LLVM_DEBUG(dbgs() << "Sink store " << getIndex(*S) << " " << *S << "\n");
    S->removeFromParent();
    S->insertBefore(Succ->getFirstNonPHI());
  }
  return;
}

bool RISCVOptimizeMemIntrinsics::isInvariantVector(Instruction &I, Loop &LI) {
  auto *C = dyn_cast<CallInst>(&I);
  if (!C || C->getNumArgOperands() == 0 || C->getIntrinsicID() < Intrinsic::riscv_amoaddg_d)
    return false;
  // Verify all operands except a value to be stored are invariant.
  return all_of(make_range(C->data_operands_begin() + C->mayWriteToMemory(),
                           C->data_operands_end()),
                [&LI](Value *V) { return isInvariant(V, LI); });
}

Value *RISCVOptimizeMemIntrinsics::getVectorStoreInput(Instruction &I) {
  return I.getOperand(0);
}

Access RISCVOptimizeMemIntrinsics::getMemoryAccess(Instruction &I) {

  auto *CI = dyn_cast<CallInst>(&I);
  if (!CI)
    return {&I, nullptr, nullptr, 0};
  switch (CI->getIntrinsicID()) {
  default:
    return Access(&I, nullptr, nullptr, CI->getIntrinsicID());
  case Intrinsic::riscv_flq2:
    return Access(I.getOperand(1), I.getOperand(0), nullptr, CI->getIntrinsicID());
  case Intrinsic::riscv_fsq2:
    return Access(I.getOperand(2), I.getOperand(1), nullptr, CI->getIntrinsicID());

  case Intrinsic::riscv_flw_ps_m:
  case Intrinsic::riscv_fsw_ps_m:
  case Intrinsic::riscv_flwg_ps_m:
  case Intrinsic::riscv_flwl_ps_m:
  case Intrinsic::riscv_fswg_ps_m:
  case Intrinsic::riscv_fswl_ps_m:
    return Access(I.getOperand(2), I.getOperand(1), I.getOperand(3),
                  CI->getIntrinsicID());

  case Intrinsic::riscv_fgb_ps_m:
  case Intrinsic::riscv_fgh_ps_m:
  case Intrinsic::riscv_fgw_ps_m:
  case Intrinsic::riscv_fgbg_ps_m:
  case Intrinsic::riscv_fghg_ps_m:
  case Intrinsic::riscv_fgwg_ps_m:
  case Intrinsic::riscv_fgbl_ps_m:
  case Intrinsic::riscv_fghl_ps_m:
  case Intrinsic::riscv_fgwl_ps_m:
  case Intrinsic::riscv_fscb_ps_m:
  case Intrinsic::riscv_fsch_ps_m:
  case Intrinsic::riscv_fscw_ps_m:
  case Intrinsic::riscv_fscbg_ps_m:
  case Intrinsic::riscv_fschg_ps_m:
  case Intrinsic::riscv_fscwg_ps_m:
  case Intrinsic::riscv_fscbl_ps_m:
  case Intrinsic::riscv_fschl_ps_m:
  case Intrinsic::riscv_fscwl_ps_m:
    return Access(I.getOperand(1), I.getOperand(2), I.getOperand(3),
                  CI->getIntrinsicID());
  }
}

// Map load memory operations to their corresponding store
// instructions that would assign to the same memory locations
// (assuming address, index value and mask are the same)
static Intrinsic::ID getStoreForm(Intrinsic::ID ID) {
  switch (ID) {
  default:
    return ID;
  case Intrinsic::riscv_flq2:
    return Intrinsic::riscv_fsq2;
#define CASE(L, S)                                                             \
  case Intrinsic::riscv_##L##_ps_m:                                            \
    return Intrinsic::riscv_##S##_ps_m
    CASE(flw, fsw);
    CASE(flwg, fswg);
    CASE(flwl, fswl);
    CASE(fgb, fscb);
    CASE(fgh, fsch);
    CASE(fgw, fscw);
    CASE(fgbg, fscbg);
    CASE(fghg, fschg);
    CASE(fgwg, fscwg);
    CASE(fgbl, fscbl);
    CASE(fghl, fschl);
    CASE(fgwl, fscwl);
#undef CASE
  }
}

// Return the input value if V is a masknot intrinsic, else null
static Value *isMaskNot(Value *V) {
  if (auto *C = dyn_cast_or_null<CallInst>(V))
    if (C->getIntrinsicID() == Intrinsic::riscv_masknot_m)
      return C->getOperand(0);
  return nullptr;
}

bool RISCVOptimizeMemIntrinsics::combinePriorMemOp(
    Instruction &I, const SmallVectorImpl<Instruction *> &VectorOps, SmallVectorImpl<Instruction*> *DeadOps, Loop &LI) {

  // return true if I and Prior refer to the
  // same set of memory locations. Prior might be a store.
  auto sameVector = [&I, &LI, this](Instruction *Prior) {

    bool isStore = Prior->mayWriteToMemory();
    // Verify non-store parameters are the same, ignoring the last
    // operand which is the function and special casing the masks.
    Access P_Access = getMemoryAccess(*Prior);
    Access I_Access = getMemoryAccess(I);
    if (P_Access.getAddr() != I_Access.getAddr() ||
        P_Access.getIndex() != I_Access.getIndex() ||
        P_Access.getStoreID() != I_Access.getStoreID())
      return false;
    if (P_Access.getMask() == I_Access.getMask())
      return true;

    // Different masks store to load, give up
    if (Prior->mayWriteToMemory())
      return false;

    // Look for loads with complementary masks.
    // TODO -- we might need to hand  (m & x) v. (~m & x)
    // to reduce the mask to "x".
    Value *M = isMaskNot(I_Access.getMask());
    if (!M || M != P_Access.getMask())
      return false;

    // Separately loading both sides of a vector,
    // replace the first load's mask to load the whole
    // vector and pretend then they are the same
    LLVM_DEBUG(dbgs() << "Promoting mask to all " << getIndex(*Prior) << " "
                      << *Prior << "\n");
    IRBuilder<> B(LI.getLoopPredecessor()->getTerminator());
    Value *AllTrue = B.CreateIntrinsic(llvm::Intrinsic::riscv_mov_m_x_m, {},
                                       {B.getInt64(0), B.getInt32(0xff)},
                                       nullptr, "alltrue");
    unsigned MaskIdx = I.getNumOperands() - 2;
    Prior->setOperand(MaskIdx + isStore, AllTrue);
    MadeChange = true;
    return true;
  };

  Value *ReplaceWith = nullptr;
  // Look backwards through preceding memory ops
  // until we find an alias or matching load.
  for (Instruction *Prior : reverse(VectorOps)) {
    if (noAlias(I, *Prior))
      continue;
    bool isStore = Prior->mayWriteToMemory();
    if (isStore) {
      if (!sameVector(Prior))
        return false;
      if (I.mayWriteToMemory()) {
          // Prior is dead .. 
          LLVM_DEBUG(dbgs()
                     << "Remove dead " << getIndex(*Prior) << " " << *Prior);
          DeadOps->push_back(Prior);
          return false;
      }
      LLVM_DEBUG(dbgs() << "Replace from " << getIndex(*Prior) << " " << *Prior
                        << "\n");
      ReplaceWith = Prior->getOperand(0);
      break;
    }
    if (I.mayWriteToMemory())
      return false;
    // Load/load
    if (!sameVector(Prior))
      continue;
    LLVM_DEBUG(dbgs() << "Replace from " << getIndex(*Prior) << " " << *Prior
                      << "\n");
    ReplaceWith = Prior;
    break;
  }
  if (!ReplaceWith)
    return false;
  MadeChange = true;
  LLVM_DEBUG(dbgs() << "Replace " << getIndex(I) << " " << I << "\n");
  I.replaceAllUsesWith(ReplaceWith);
  DeadOps->push_back(&I);
  return true;
}

// true if V is an vector instruction with a pass through input
static bool hasPassThru(Value *V) {
  auto *C = dyn_cast<CallInst>(V);
  // any Esperanto intrinsic whose first operand is undefined
  // is a pass through
  return (C && C->getIntrinsicID() >= Intrinsic::riscv_amoaddg_d &&
          C->getNumOperands() > 1 && isa<UndefValue>(C->getOperand(0)));
}

// Return the mask value for a vector instrinsic if it has
// one or null.
static Value *getMask(Instruction *V) {
  auto *C = dyn_cast<CallInst>(V);
  if (!C)
    return nullptr;
  if (Optional<size_t> Idx = getMaskOperand(*C))
    return C->getOperand(*Idx);
  return nullptr;
}

// Return true if A and B are masks such that A == ~B
static bool isComplement(Value *A, Value *B) {
  return (isMaskNot(A) == B || isMaskNot(B) == A);
}

bool RISCVOptimizeMemIntrinsics::foldSelect(Instruction &I) {
  if (!isa<SelectInst>(I))
    return false;
  Value *Cond = I.getOperand(0);
  if (Cond->hasOneUse())
    if (Value *M = isMaskNot(Cond)) {
      // avoid a mask complement by swappign operands.
      Value *T = I.getOperand(1);
      I.setOperand(1, I.getOperand(2));
      I.setOperand(2, T);
      I.setOperand(0, M);
      dyn_cast<Instruction>(Cond)->eraseFromParent();
      Cond = M;
    }

  // Skip a bitcast to find the underlying operation
  auto skipCast = [&I](Value *V) -> Instruction * {
    auto *BC = dyn_cast<BitCastInst>(V);
    if (BC)
      V = BC->getOperand(0);

    Instruction *VI = dyn_cast<Instruction>(V);
    if (!VI || VI->getParent() != I.getParent())
      return nullptr;
    return VI;
  };

  // add a bit cast if needed so V ias type Ty.
  auto addCast = [](Instruction *V, Type *Ty) -> Value * {
    if (V->getType() == Ty)
      return V;
    return IRBuilder<>(&*std::next(V->getIterator())).CreateBitCast(V, Ty);
  };

  Instruction *T = skipCast(I.getOperand(1));
  if (!T)
    return false;
  Instruction *F = skipCast(I.getOperand(2));
  if (!F)
    return false;

  if (T->comesBefore(F)) {
    // (m ? T : F(U, !m))) --> F(T,!m)
    if (!isComplement(getMask(F), Cond))
      return false;
    std::swap(T, F);
    // now effectively (!m ? F(U,!m) : T)
  }

  // If T has an available pass through operand
  // then we can stuff F into that
  if (!hasPassThru(T))
    return false;
  LLVM_DEBUG(dbgs() << "fold " << I << "\n");
  const unsigned PASS_THROUGH = 0;
  T->setOperand(PASS_THROUGH,
                addCast(F, T->getOperand(PASS_THROUGH)->getType()));
  I.replaceAllUsesWith(addCast(T, I.getType()));
  I.eraseFromParent();
  return true;
}

unsigned CodeHoister::estimateVectorUsage(BasicBlock &BB) {
  // The set of invariants referenced in the loop
  // which are live over the entire loop assuming
  // they are in a register.
  SmallDenseSet<Value *, 8> Invariants;

  // NumLive will be the number of vector values
  // defined in the loop and live at the current
  // point.
  unsigned NumLive = 0;
  // The maximum of NumLive at any point in the loop
  unsigned MaxLive = 0;
  // Map an instruction that defines a vector
  // to the number of uses of that vector we have
  // not yet seen.
  SmallDenseMap<Instruction *, int> LiveCount;
  for (Instruction &I : BB) {
    if (!isa<PHINode>(I)) {
      for (llvm::Value *Op : I.operands()) {
        if (!isa<FixedVectorType>(Op->getType()))
          continue;
        auto *Def = dyn_cast<Instruction>(Op);
        if (!Def || !L.contains(Def)) {
          Invariants.insert(Op);
          continue;
        }
        int &C = LiveCount[Def];
#ifndef NDEBUG
        if (C < 1) {
          BB.dump();
          dbgs() << "failed on " << I << "\nwith def " << *Def << "\n";
        }
#endif
        assert(C > 0);
        if (--C == 0)
          NumLive -= 1;
      }
    }
    if (!isa<FixedVectorType>(I.getType()))
      continue;
    if (unsigned NumUses = I.getNumUses()) {
      LiveCount.try_emplace(&I, NumUses);
      NumLive += 1;
      MaxLive = std::max(MaxLive, NumLive);
    }
  }
  return Invariants.size() + MaxLive;
}

void RISCVOptimizeMemIntrinsics::rewriteGatherScatters(Function &F) {
  for (BasicBlock &BB : F)
    for (BasicBlock::iterator Cur = BB.begin(); Cur != BB.end();) {
      Instruction &I = *Cur++;
      if (I.getOpcode() != Instruction::Call)
        continue;
      switch (dyn_cast<CallBase>(&I)->getIntrinsicID()) {
      case Intrinsic::masked_scatter:
        rewriteScatter(I);
        break;
      case Intrinsic::masked_gather:
        rewriteGather(I);
        break;
      }
    }
}

// Decompose an address vector into a common base pointer
// and a vector of offsets.
bool RISCVOptimizeMemIntrinsics::isUniform(Value *Addr, Value **Base_,
                                           Value **Index_, unsigned *Scale) {
  auto *VTy = dyn_cast<FixedVectorType>(Addr->getType());
  if (!VTy || VTy->getNumElements() != 8)
    return false;
  auto *GEP = dyn_cast<GetElementPtrInst>(Addr);
  if (!GEP)
    return false;
  // We need a scalar base
  Value *Base = GEP->getOperand(0);
  if (Base->getType()->isVectorTy())
    return false;
  // Find the unique vector index...
  DataLayout DL = CurrentFunction->getParent()->getDataLayout();
  gep_type_iterator Cur = gep_type_begin(GEP);
  gep_type_iterator End = gep_type_end(GEP);
  Value *Index = nullptr;
  IRBuilder<> B(GEP);
  SmallVector<Value *, 8> Indices;
  for (; Cur != End; ++Cur) {
    Value *Operand = Cur.getOperand();
    auto *Ty = dyn_cast<FixedVectorType>(Operand->getType());
    if (!Ty) {
      Indices.push_back(Operand);
      continue;
    }
    if (Index)
      // TODO -- change to scale the index and the sum the
      //   multiple instances
      return false; // multiple vector operands should never happen...

    Indices.push_back(B.getInt64(0));
    TypeSize ElementSize = DL.getTypeAllocSize(Cur.getIndexedType());
    if (ElementSize.isScalable())
      return false;
    *Scale = ElementSize.getFixedSize();
    Index = Operand;
    if (Ty->getScalarSizeInBits() == 64) {
      auto *Cast = dyn_cast<CastInst>(Index);
      if (!Cast)
        return false;
      Index = Cast->getOperand(0);
    }
  }
  assert(Index && "Failed to find vector operand to vector GEP");
  // Found a suitable GEP, so we know
  // lower that to a scalar GEP by replacing the
  // vector index with 0 and returning the index value ant
  // its scaling factor to the parent.
  *Base_ = B.CreateGEP(nullptr, Base, Indices);
  *Index_ = Index;
  return true;
}

void RISCVOptimizeMemIntrinsics::rewriteGather(Instruction &I) {
  Value *Base, *Index;
  unsigned Scale;
  if (!isUniform(I.getOperand(0), &Base, &Index, &Scale))
    return;
  assert(isa<UndefValue>(I.getOperand(3)) &&
         "Expected undefined Pass through in gather");
  IRBuilder<> B(&I);
  if (Index->getType()->getScalarSizeInBits() < 32)
    Index = B.CreateSExt(Index, FixedVectorType::get(B.getInt32Ty(), 8));
  Value *ByteIndex =
      B.CreateMul(Index, B.CreateVectorSplat(8, B.getInt32(Scale)));
  // Convert to "et_masked_gather"

  Type *Ret = I.getType();
  unsigned MemoryWidth = Ret->getScalarSizeInBits();
  if (MemoryWidth < 32)
    Ret = FixedVectorType::get(B.getInt32Ty(), 8);
  Value *G =
      B.CreateIntrinsic(Intrinsic::riscv_et_gather, {Ret, Base->getType()},
                        {/*Ptr*/ Base, ByteIndex,
                         /*PassThru*/ UndefValue::get(Ret),
                         /*Load Ext*/ B.getInt32(ISD::LoadExtType::NON_EXTLOAD),
                         /*Mask*/ I.getOperand(2)});
  if (Ret != I.getType())
    G = B.CreateTrunc(G, I.getType());
  I.replaceAllUsesWith(G);
  I.eraseFromParent();
}

void RISCVOptimizeMemIntrinsics::rewriteScatter(Instruction &I) {
  Value *Base, *Index;
  unsigned Scale;
  if (!isUniform(I.getOperand(1), &Base, &Index, &Scale))
    return;

  IRBuilder<> B(&I);
  if (Index->getType()->getScalarSizeInBits() < 32)
    Index = B.CreateSExt(Index, FixedVectorType::get(B.getInt32Ty(), 8));
  Value *ByteIndex =
      B.CreateMul(Index, B.CreateVectorSplat(8, B.getInt32(Scale)));

  // Convert to "et_masked_gather"
  CallInst *S = B.CreateIntrinsic(Intrinsic::riscv_et_scatter,
                                  {I.getOperand(0)->getType(), Base->getType()},
                                  {/*Value*/ I.getOperand(0),
                                   /*Ptr*/ Base, ByteIndex,
                                   /*Mask*/ I.getOperand(3)});
  I.replaceAllUsesWith(S);
  I.eraseFromParent();
}

#endif
