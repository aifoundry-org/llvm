//===-- RISCVRegisterInfoEsperanto.td -===== Register defs -*- tablegen -*-===//
//
// No copy rights
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the instruction extensions for
//  Esperanto ET-SOC1-MIN/MAX
//
// In this specification we follow the following conventions
//
// 1. New Instruction formats are named
//
//        ETInst<pat>
//
//    where <pat> is a sequence of Rd,R1,R2,R3,I,Rm which roughly
//    correspond to the variable parts of particular instruction
//    encodings. Instruction formats are in
//    RISCVInstrFormatEsperanto.d
//
// 2. To handle masked vector operations, we introduce pseudo
//    instructions with "_EX" suffix (for "explicit").  These pseudo
//    operands include the output register if any as a tied input
//    register and also make the reference to m0 explicit using the MR0
//    register class. Late in compilation these are lowered to the
//    non-explicit base instructions.
//
//    We add the tied input of the output as the first input operand and
//    the implicit mask as the last. This fact is assumed in the lowring
//    code.  RISCVExpandPseudoInsts.cpp
//
// 3. We create multiclasses that define the base instruction and its _EX
//    variant and name those classes to capture "ins", "outs" and operand
//    strings:
//
//       ETOps<pat>
//
//    where <pat> is like above possibly with a suffix such as G or FG to
//    distinguish cases with similar encoding but different asm-strings.
//
//
//===----------------------------------------------------------------------===//

include "RISCVInstrFormatsEsperanto.td"

let DecoderNamespace = "Esperanto" in {
let Predicates = [HasEsperanto] in {

// Guess: load two consecutive 16-bit floats...
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def FLQ2 : RVInstI<0b101, OPC_LOAD_FP,
                   (outs FPR256:$rd),
                   (ins simm12:$imm12, GPR:$rs1),
                   "flq2", "$rd, ${imm12}(${rs1})">;

// Guess: store two consecutive 16-bit floats...
let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def FSQ2 : RVInstS<0b101, OPC_STORE_FP,
                   (outs),
                   (ins FPR256:$rs2, simm12:$imm12, GPR:$rs1),
                   "fsq2", "$rs2, ${imm12}(${rs1})">;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in {
def FLW_PS : RVInstI<0b010, OPC_MEM_PS,
                   (outs FPR256:$rd),
                   (ins simm12:$imm12, GPR:$rs1),
                   "flw.ps", "$rd, ${imm12}(${rs1})">;
def FLW_PS_EX : Pseudo<(outs FPR256:$rd),
                       (ins FPR256:$in, simm12:$imm12, GPR:$rs1, MR0:$m0), [],
                       "flw.ps", "$rd, ${imm12}(${rs1}), $m0"> {
  let Constraints = "$rd = $in";
}
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in {
def FSW_PS : RVInstS<0b110, OPC_MEM_PS,
                   (outs),
                   (ins FPR256:$rs2, simm12:$imm12, GPR:$rs1),
                   "fsw.ps", "$rs2, ${imm12}(${rs1})">;
def FSW_PS_EX : Pseudo<(outs),
                   (ins FPR256:$rs2, simm12:$imm12, GPR:$rs1, MR0:$m0),
                   [], "fsw.ps", "$rs2, ${imm12}(${rs1}), $m0">;
}

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in {
def FBC_PS : RVInstI<0b000, OPC_MEM_PS,
                   (outs FPR256:$rd),
                   (ins simm12:$imm12, GPR:$rs1),
                   "fbc.ps", "$rd, ${imm12}(${rs1})">;
def FBC_PS_EX : Pseudo<(outs FPR256:$rd),
                   (ins FPR256:$in, simm12:$imm12, GPR:$rs1, MR0:$m0), [],
                   "fbc.ps", "$rd, ${imm12}(${rs1}), $m0"> {
  let Constraints = "$rd = $in";
}
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
def FBCX_PS : RVInstI<0b011, OPC_MEM_PS,
                   (outs FPR256:$rd),
                   (ins GPR:$rs1),
                   "fbcx.ps", "$rd, ${rs1}"> {
    let imm12 = 0;
}
def FBCX_PS_EX : Pseudo<(outs FPR256:$rd),
                   (ins FPR256:$in, GPR:$rs1, MR0:$m0),[],
                   "fbcx.ps", "$rd, ${rs1}, $m0"> {
  let Constraints = "$rd = $in";
}

def FBCI_PS : RVInstU<OPC_IMM_PS,
                      (outs FPR256:$rd),
                      (ins uimm20_lui:$imm20),
                      "fbci.ps", "$rd, $imm20"> ;

def FBCI_PS_EX : Pseudo<(outs FPR256:$rd),
                        (ins FPR256:$in, uimm20_lui:$imm20, MR0:$m0), [],
                      "fbci.ps", "$rd, $imm20, $m0"> {
  let Constraints = "$rd = $in";
}

multiclass ETOpsRdF1R2G<bits<7> funct7, string opcodestr> {
   def "" : RVInstR<funct7, 0b001, OPC_MEM_PS,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, GPR:$rs2),
                 opcodestr, "$rd, ${rs1}(${rs2})">;
   def _EX : Pseudo<
                 (outs FPR256:$rd),
                 (ins FPR256:$in, FPR256:$rs1, GPR:$rs2, MR0:$m0), [],
                 opcodestr, "$rd, ${rs1}(${rs2}), $m0"> {
         let Constraints = "$rd = $in";
   }
}
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in {
defm FGW_PS : ETOpsRdF1R2G<0b0110000, "fgw.ps">;
defm FGH_PS : ETOpsRdF1R2G<0b0101000, "fgh.ps">;
defm FGB_PS : ETOpsRdF1R2G<0b0100100, "fgb.ps">;
}

multiclass ETOpsR3R1R2<bits<7> funct7, bits<3> funct3, string opcodestr> {
   def "" : RVInstE12<funct7, funct3, OPC_MEM_PS,
                  (outs),
                  (ins FPR256:$rs3, FPR256:$rs1, GPR:$rs2),
                  opcodestr, "$rs3, ${rs1}(${rs2})">;
   def _EX : Pseudo<
                 (outs),
                 (ins FPR256:$rs3, FPR256:$rs1, GPR:$rs2, MR0:$m0), [],
                  opcodestr, "$rs3, ${rs1}(${rs2}), $m0">;
}
let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in {
defm FSCW_PS : ETOpsR3R1R2<0b1110000, 0b001, "fscw.ps">;
defm FSCH_PS : ETOpsR3R1R2<0b1101000, 0b001, "fsch.ps">;
defm FSCB_PS : ETOpsR3R1R2<0b1100100, 0b001, "fscb.ps">;
}

multiclass ETOpsRdR1R2Rm<bits<7> funct7, RISCVOpcode opcode,
                  string opcodestr> {
    def "" : RVInstE3<funct7, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2, ofrmarg:$rm),
                 opcodestr, "$rd, $rs1, $rs2, $rm">;
    def _EX : Pseudo<(outs FPR256:$rd),
             (ins FPR256:$in, FPR256:$rs1, FPR256:$rs2, ofrmarg:$rm, MR0:$m0),
             [], opcodestr, "$rd, $rs1, $rs2, $rm, $m0">  {
         let Constraints = "$rd = $in";
   }
}
defm FADD_PS : ETOpsRdR1R2Rm<0b0000000, OPC_OP_PS, "fadd.ps">;
defm FSUB_PS : ETOpsRdR1R2Rm<0b0000100, OPC_OP_PS, "fsub.ps">;
defm FMUL_PS : ETOpsRdR1R2Rm<0b0001000, OPC_OP_PS, "fmul.ps">;
defm FDIV_PS : ETOpsRdR1R2Rm<0b0001100, OPC_OP_PS, "fdiv.ps">;

multiclass ETOpsRdR1R2<bits<7> funct7, bits<3> funct3, RISCVOpcode opcode,
                string opcodestr> {
    def "" : RVInstR<funct7, funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2),
                 opcodestr, "$rd, $rs1, $rs2">;
    def _EX :    Pseudo<(outs FPR256:$rd),
             (ins FPR256:$in, FPR256:$rs1, FPR256:$rs2, MR0:$m0),
             [], opcodestr, "$rd, $rs1, $rs2, $m0">  {
         let Constraints = "$rd = $in";
   }
}
defm FMIN_PS : ETOpsRdR1R2<0b0010100, 0b000, OPC_OP_PS, "fmin.ps">;
defm FMAX_PS : ETOpsRdR1R2<0b0010100, 0b001, OPC_OP_PS, "fmax.ps">;


multiclass ETOpsRdR1R2R3Rm<bits<2> funct2, RISCVOpcode opcode,
                string opcodestr> {
    def "" :  RVInstE4<funct2, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2, FPR256:$rs3, ofrmarg:$rm),
                 opcodestr, "$rd, $rs1, $rs2, $rs3, $rm">;
    def _EX : Pseudo<(outs FPR256:$rd),
                 (ins FPR256:$in, FPR256:$rs1,
                          FPR256:$rs2, FPR256:$rs3, ofrmarg:$rm, MR0:$m0),
                 [], opcodestr, "$rd, $rs1, $rs2, $rs3, $rm, $m0">  {
         let Constraints = "$rd = $in";
   }
}
defm FMADD_PS : ETOpsRdR1R2R3Rm<0b00, OPC_OP3_PS, "fmadd.ps">;
defm FMSUB_PS : ETOpsRdR1R2R3Rm<0b01, OPC_OP3_PS, "fmsub.ps">;
defm FNMSUB_PS : ETOpsRdR1R2R3Rm<0b10, OPC_OP3_PS, "fnmsub.ps">;
defm FNMADD_PS : ETOpsRdR1R2R3Rm<0b11, OPC_OP3_PS, "fnmadd.ps">;

def FCMOV_PS : RVInstE4<0b10, RISCVOpcode<0b0111111>,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2, FPR256:$rs3),
                    "fcmov.ps", "$rd, $rs1, $rs2, $rs3"> {
    let rm = 0b010;
}
def FCMOV_PS_EX : Pseudo<
                 (outs FPR256:$rd),
                 (ins FPR256:$in, FPR256:$rs1, FPR256:$rs2,
                      FPR256:$rs3, MR0:$m0), [],
                 "fcmov.ps", "$rd, $rs1, $rs2, $rs3, $m0"> {
         let Constraints = "$rd = $in";
}

def FSWIZZ_PS : RVInstE1<0b1110011, OPC_OP_PS,
                         (outs FPR256:$rd),
                         (ins FPR256:$rs1, uimm8:$imm),
                         "fswizz.ps", "$rd, $rs1, $imm">;
def FSWIZZ_PS_EX : Pseudo<(outs FPR256:$rd),
                         (ins FPR256:$in, FPR256:$rs1, uimm8:$imm, MR0:$m0),
                         [], "fswizz.ps", "$rd, $rs1, $imm, $m0"> {
    let Constraints = "$rd = $in";
}

multiclass ETOpsRdR1Rm<bits<7> funct7, bits<5> funct1, RISCVOpcode opcode,
                  string opcodestr> {
   def "" : RVInstE3<funct7, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, ofrmarg:$rm),
                 opcodestr, "$rd, $rs1, $rm"> {
       let rs2 = funct1;
   }
   def _EX : Pseudo<(outs FPR256:$rd),
          (ins FPR256:$in, FPR256:$rs1, ofrmarg:$rm, MR0:$m0),
          [], opcodestr, "$rd, $rs1, $rm, $m0">  {
         let Constraints = "$rd = $in";
   }
}

defm FCVT_PW_PS  : ETOpsRdR1Rm<0b1100000, 0,  OPC_OP_PS, "fcvt.pw.ps">;
defm FCVT_PWU_PS : ETOpsRdR1Rm<0b1100000, 1, OPC_OP_PS, "fcvt.pwu.ps">;
defm FCVT_PS_PW  : ETOpsRdR1Rm<0b1101000, 0, OPC_OP_PS, "fcvt.ps.pw">;
defm FCVT_PS_PWU : ETOpsRdR1Rm<0b1101000, 1, OPC_OP_PS, "fcvt.ps.pwu">;

class ETOpsRdR1Idx<bits<7> funct7, bits<3> funct3, RISCVOpcode opcode,
                  string opcodestr> :
         RVInstE5<funct7, funct3, opcode,
                 (outs GPR:$rd),
                 (ins FPR256:$rs1, uimm3:$idx),
                 opcodestr, "$rd, $rs1, $idx">;

def FMVZ_X_PS : ETOpsRdR1Idx<0b1110000, 0b000, OPC_OP_PS, "fmvz.x.ps">;
// no _EX variant
def FMVS_X_PS : ETOpsRdR1Idx<0b1110000, 0b010, OPC_OP_PS, "fmvs.x.ps">;
// no _EX variant

defm FSGNJN_PS : ETOpsRdR1R2<0b0010000, 0b001, OPC_OP_PS, "fsgnjn.ps">;
defm FSGNJ_PS  : ETOpsRdR1R2<0b0010000, 0b000, OPC_OP_PS, "fsgnj.ps">;
defm FSGNJX_PS : ETOpsRdR1R2<0b0010000, 0b010, OPC_OP_PS, "fsgnjx.ps">;
defm FLE_PS    : ETOpsRdR1R2<0b1010000, 0b000, OPC_OP_PS, "fle.ps">;
defm FLT_PS    : ETOpsRdR1R2<0b1010000, 0b001, OPC_OP_PS, "flt.ps">;
defm FEQ_PS    : ETOpsRdR1R2<0b1010000, 0b010, OPC_OP_PS, "feq.ps">;

multiclass ETOpsMdR1R2<bits<7> funct7, bits<3> funct3, RISCVOpcode opcode,
                string opcodestr> {
    def "" : RVInstR<funct7, funct3, opcode,
                 (outs MR:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2),
                 opcodestr, "$rd, $rs1, $rs2">;
    def _EX : Pseudo<(outs MR:$rd),
             (ins MR:$in, FPR256:$rs1, FPR256:$rs2, MR0:$m0), [],
             opcodestr, "$rd, $rs1, $rs2, $m0"> {
        let Constraints = "$rd = $in";
    }
}

defm FLEM_PS   : ETOpsMdR1R2<0b1010000, 0b100, OPC_OP_PS, "flem.ps">;
defm FLTM_PS   : ETOpsMdR1R2<0b1010000, 0b101, OPC_OP_PS, "fltm.ps">;
defm FEQM_PS   : ETOpsMdR1R2<0b1010000, 0b110, OPC_OP_PS, "feqm.ps">;

multiclass ETOpsRdR1<bits<7> funct7, bits<5> funct5, bits<3> funct3,
                        RISCVOpcode opcode, string opcodestr> {
    def "" : RVInstR<funct7, funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1),
                 opcodestr, "$rd, $rs1"> {
        let rs2 = funct5;
    }
    def _EX :      Pseudo<(outs FPR256:$rd),
            (ins FPR256:$in, FPR256:$rs1, MR0:$m0), [],
            opcodestr, "$rd, $rs1, $m0"> {
        let Constraints = "$rd = $in";
    }
}

defm FCLASS_PS : ETOpsRdR1<0b1110000, 0b00000, 0b001, OPC_OP_PS, "fclass.ps">;

multiclass ETOpsCvt<bits<7> funct7, bits<5> funct5, string opcodestr> {
    defm "" : ETOpsRdR1<funct7, funct5, 0b000,
                        RISCVOpcode<0b1111011>, opcodestr>;
}

defm FCVT_PS_F10  : ETOpsCvt<0b1101000, 0b01000, "fcvt.ps.f10">;
defm FCVT_PS_F11  : ETOpsCvt<0b1101000, 0b01001, "fcvt.ps.f11">;
defm FCVT_PS_F16  : ETOpsCvt<0b1101000, 0b01010, "fcvt.ps.f16">;
defm FCVT_PS_UN24 : ETOpsCvt<0b1101000, 0b10000, "fcvt.ps.un24">;
defm FCVT_PS_UN16 : ETOpsCvt<0b1101000, 0b10001, "fcvt.ps.un16">;
defm FCVT_PS_UN10 : ETOpsCvt<0b1101000, 0b10010, "fcvt.ps.un10">;
defm FCVT_PS_UN8  : ETOpsCvt<0b1101000, 0b10011, "fcvt.ps.un8">;
defm FCVT_PS_UN2  : ETOpsCvt<0b1101000, 0b10111, "fcvt.ps.un2">;
defm FCVT_PS_SN16 : ETOpsCvt<0b1101000, 0b11001, "fcvt.ps.sn16">;
defm FCVT_PS_SN8  : ETOpsCvt<0b1101000, 0b11011, "fcvt.ps.sn8">;
defm FCVT_F11_PS  : ETOpsCvt<0b1101100, 0b01000, "fcvt.f11.ps">;
defm FCVT_F16_PS  : ETOpsCvt<0b1101100, 0b01001, "fcvt.f16.ps">;
defm FCVT_F10_PS  : ETOpsCvt<0b1101100, 0b01011, "fcvt.f10.ps">;
defm FCVT_UN24_PS : ETOpsCvt<0b1101100, 0b10000, "fcvt.un24.ps">;
defm FCVT_UN16_PS : ETOpsCvt<0b1101100, 0b10001, "fcvt.un16.ps">;
defm FCVT_UN10_PS : ETOpsCvt<0b1101100, 0b10010, "fcvt.un10.ps">;
defm FCVT_UN8_PS  : ETOpsCvt<0b1101100, 0b10011, "fcvt.un8.ps">;
defm FCVT_UN2_PS  : ETOpsCvt<0b1101100, 0b10111, "fcvt.un2.ps">;
defm FCVT_SN16_PS : ETOpsCvt<0b1101100, 0b11001, "fcvt.sn16.ps">;
defm FCVT_SN8_PS  : ETOpsCvt<0b1101100, 0b11011, "fcvt.sn8.ps">;

def FBCI_PI : RVInstU<OPC_IMM_PI,
                      (outs FPR256:$rd),
                      (ins simm20:$imm20),
                      "fbci.pi", "$rd, ${imm20}">;
def FBCI_PI_EX : Pseudo<(outs FPR256:$rd),
                        (ins FPR256:$in, simm20:$imm20, MR0:$m0), [],
                      "fbci.pi", "$rd, ${imm20}, $m0"> {
     let Constraints = "$rd = $in";
}
defm FADD_PI   : ETOpsRdR1R2<0b0000011, 0b000, OPC_OP_PS, "fadd.pi">;
defm FSUB_PI   : ETOpsRdR1R2<0b0000111, 0b000, OPC_OP_PS, "fsub.pi">;
defm FMUL_PI   : ETOpsRdR1R2<0b0001011, 0b000, OPC_OP_PS, "fmul.pi">;
defm FMULH_PI  : ETOpsRdR1R2<0b0001011, 0b001, OPC_OP_PS, "fmulh.pi">;
defm FMULHU_PI : ETOpsRdR1R2<0b0001011, 0b010, OPC_OP_PS, "fmulhu.pi">;
defm FDIV_PI   : ETOpsRdR1R2<0b0001111, 0b000, OPC_OP_PS, "fdiv.pi">;
defm FDIVU_PI  : ETOpsRdR1R2<0b0001111, 0b001, OPC_OP_PS, "fdivu.pi">;
defm FREM_PI   : ETOpsRdR1R2<0b0001111, 0b010, OPC_OP_PS, "frem.pi">;
defm FREMU_PI  : ETOpsRdR1R2<0b0001111, 0b011, OPC_OP_PS, "fremu.pi">;
defm FMIN_PI   : ETOpsRdR1R2<0b0010111, 0b000, OPC_OP_PS, "fmin.pi">;
defm FMAX_PI   : ETOpsRdR1R2<0b0010111, 0b001, OPC_OP_PS, "fmax.pi">;
defm FMINU_PI  : ETOpsRdR1R2<0b0010111, 0b010, OPC_OP_PS, "fminu.pi">;
defm FMAXU_PI  : ETOpsRdR1R2<0b0010111, 0b011, OPC_OP_PS, "fmaxu.pi">;

defm FLTM_PI : ETOpsMdR1R2<0b0011111, 0b000, OPC_OP_PS, "fltm.pi">;

defm FAND_PI : ETOpsRdR1R2<0b0000011, 0b111, OPC_OP_PS, "fand.pi">;
defm FOR_PI  : ETOpsRdR1R2<0b0000011, 0b110, OPC_OP_PS, "for.pi">;
defm FNOT_PI : ETOpsRdR1<0b0000011, 0b00000, 0b010, OPC_OP_PS, "fnot.pi">;
defm FXOR_PI : ETOpsRdR1R2<0b0000011, 0b100, OPC_OP_PS, "fxor.pi">;
defm FSLL_PI : ETOpsRdR1R2<0b0000011, 0b001, OPC_OP_PS, "fsll.pi">;
defm FSRL_PI : ETOpsRdR1R2<0b0000011, 0b101, OPC_OP_PS, "fsrl.pi">;
defm FSRA_PI : ETOpsRdR1R2<0b0000111, 0b101, OPC_OP_PS, "fsra.pi">;
defm FLE_PI  : ETOpsRdR1R2<0b1010011, 0b000, OPC_OP_PS, "fle.pi">;
defm FLT_PI  : ETOpsRdR1R2<0b1010011, 0b001, OPC_OP_PS, "flt.pi">;
defm FEQ_PI  : ETOpsRdR1R2<0b1010011, 0b010, OPC_OP_PS, "feq.pi">;
defm FLTU_PI : ETOpsRdR1R2<0b1010011, 0b011, OPC_OP_PS, "fltu.pi">;

multiclass ETOpsMdR1<bits<7> funct7, bits<3> funct3,
                     RISCVOpcode opcode, string opcodestr> {
    def "" :  RVInstR<funct7, funct3, opcode,
                 (outs MR:$rd),
                 (ins FPR256:$rs1),
                 opcodestr, "$rd, $rs1"> {
        let rs2 = 0;
    }
    def _EX : Pseudo<(outs MR:$rd),
           (ins MR:$in, FPR256:$rs1, MR0:$m0),
           [], opcodestr, "$rd, $rs1, $m0"> {
        let Constraints = "$rd = $in";
    }
}

defm FSETM_PI : ETOpsMdR1<0b1010011, 0b100, OPC_OP_PS, "fsetm.pi">;

multiclass ETOpsRdR1I10<bits<3> funct3, RISCVOpcode opcode, string opcodestr> {
    def "" : RVInstE2<funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, simm10:$imm),
                 opcodestr, "$rd, $rs1, ${imm}">;
    def _EX : Pseudo<(outs FPR256:$rd),
            (ins FPR256:$in, FPR256:$rs1, simm10:$imm, MR0:$m0), [],
            opcodestr, "$rd, $rs1, ${imm}, $m0"> {
        let Constraints = "$rd = $in";
    }
}

defm FADDI_PI : ETOpsRdR1I10<0b000, OPC_IMM10_PI, "faddi.pi">;
defm FANDI_PI : ETOpsRdR1I10<0b001, OPC_IMM10_PI, "fandi.pi">;

multiclass ETOpsRdR1I5<bits<3> funct3, RISCVOpcode opcode, string opcodestr> {
    def "" : RVInstE6<funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, uimm5:$imm),
                 opcodestr, "$rd, $rs1, ${imm}">;
    def _EX : Pseudo<(outs FPR256:$rd),
            (ins FPR256:$in, FPR256:$rs1, uimm5:$imm, MR0:$m0), [],
            opcodestr, "$rd, $rs1, ${imm}, $m0"> {
        let Constraints = "$rd = $in";
    }
}

defm FSLLI_PI : ETOpsRdR1I5<0b001, OPC_OP_PS, "fslli.pi">;
defm FSRLI_PI : ETOpsRdR1I5<0b101, OPC_OP_PS, "fsrli.pi">;
defm FSRAI_PI : ETOpsRdR1I5<0b111, OPC_OP_PS, "fsrai.pi">;

defm FSIN_PS : ETOpsRdR1<0b0101100, 0b00110, 0b000, OPC_OP_PS, "fsin.ps">;
defm FEXP_PS : ETOpsRdR1<0b0101100, 0b00100, 0b000, OPC_OP_PS, "fexp.ps">;
defm FLOG_PS : ETOpsRdR1<0b0101100, 0b00011, 0b000, OPC_OP_PS, "flog.ps">;
defm FFRC_PS : ETOpsRdR1<0b0101100, 0b00010, 0b000, OPC_OP_PS, "ffrc.ps">;

def FROUND_PS : RVInstE7<OPC_OP_PS,
                         (outs FPR256:$rd),
                         (ins FPR256:$rs1, ofrmarg:$rm),
                          "fround.ps", "$rd, $rs1, $rm">;
def FROUND_PS_EX : Pseudo<(outs FPR256:$rd),
                           (ins FPR256:$in, FPR256:$rs1, ofrmarg:$rm, MR0:$m0),
                          [], "fround.ps", "$rd, $rs1, $rm, $m0"> {
        let Constraints = "$rd = $in";
}

defm FSQRT_PS : ETOpsRdR1<0b0101100, 0b00000, 0b000, OPC_OP_PS, "fsqrt.ps">;
defm FRCP_PS  : ETOpsRdR1<0b0101100, 0b00111, 0b000, OPC_OP_PS, "frcp.ps">;
defm FRSQ_PS  : ETOpsRdR1<0b0101100, 0b01000, 0b000, OPC_OP_PS, "frsq.ps">;

defm CUBEFACE_PS    : ETOpsRdR1R2<0b1000100, 0b000, OPC_OP_PS, "cubeface.ps">;
defm CUBEFACEIDX_PS : ETOpsRdR1R2<0b1000100, 0b001, OPC_OP_PS, "cubefaceidx.ps">;
defm CUBESGNSC_PS   : ETOpsRdR1R2<0b1000100, 0b010, OPC_OP_PS, "cubesgnsc.ps">;
defm CUBESGNTC_PS   : ETOpsRdR1R2<0b1000100, 0b011, OPC_OP_PS, "cubesgntc.ps">;

def PACKB    : ALUW_rr<0b1000000, 0b110, "packb">;
def BITMIXB  : ALUW_rr<0b1000000, 0b111, "bitmixb">;

def MOV_M_X : RVInstE8<OPC_OP_PS,
                     (outs MR:$rd),
                     (ins GPR:$rs1, uimm8:$imm),
                     "mov.m.x", "$rd, $rs1, $imm">;
def MOVA_X_M : RVInstR<0b1101011, 0b000, OPC_OP_PS,
                     (outs GPR:$rd),
                     (ins),
                     "mova.x.m", "$rd"> {
    let rs1 = 0;
    let rs2 = 0;
}

def MOVA_M_X : RVInstR<0b1101011, 0b001, OPC_OP_PS,
                     (outs),
                     (ins GPR:$rs1),
                     "mova.m.x", "$rs1"> {
    let rd = 0;
    let rs2 = 0;
}

class ETOpsMdM1M2<bits<3> funct3, string codestr> :
    RVInstE9<funct3, OPC_OP_PS, (outs MR:$rd),
             (ins MR:$rs1, MR:$rs2), codestr, "$rd, $rs1, $rs2">;

def MASKAND : ETOpsMdM1M2<0b111, "maskand">;
def MASKOR  : ETOpsMdM1M2<0b110, "maskor">;
def MASKNOT : RVInstE9<0b010, OPC_OP_PS, (outs MR:$rd),
             (ins MR:$rs1), "masknot", "$rd, $rs1"> { let rs2 = 0; }
def MASKXOR  : ETOpsMdM1M2<0b100, "maskxor">;

class ETOpsRdM1<bits<2> funct2, string opcodestr> :
      RVInstE10<funct2, OPC_OP_PS, (outs GPR:$rd), (ins MR:$rs1),
                opcodestr, "$rd, $rs1">;

def MASKPOPC  : ETOpsRdM1<0b01,"maskpopc">;
def MASKPOPCZ : ETOpsRdM1<0b10,"maskpopcz">;

def MASKPOPC_RAST : RVInstE11<OPC_OP_PS, (outs MR:$rd),
             (ins MR:$rs1, MR:$rs2, uimm4:$imm),
             "maskpopc.rast", "$rd, $rs1, $rs2, $imm">;

defm FPACKREPB_PI :
       ETOpsRdR1<0b0010011, 0b00000, 0b000, OPC_OP_PS, "fpackrepb.pi">;
defm FPACKREPH_PI :
       ETOpsRdR1<0b0010011, 0b00000, 0b001, OPC_OP_PS, "fpackreph.pi">;


multiclass ETOpsRdR1R2G<bits<7> funct7, string opcodestr> {
    def "" : RVInstR<funct7, 0b001, OPC_MEM_PS,
                 (outs FPR256:$rd),
                 (ins GPR:$rs1, GPR:$rs2),
                 opcodestr, "$rd, ${rs1}(${rs2})">;
    def _EX : Pseudo<
                 (outs FPR256:$rd),
                 (ins FPR256:$in, GPR:$rs1, GPR:$rs2, MR0:$m0), [],
                 opcodestr, "$rd, ${rs1}(${rs2}), m0">  {
        let Constraints = "$rd = $in";
    }
}

let mayLoad = 1 in {
defm FG32W_PS : ETOpsRdR1R2G<0b0010000, "fg32w.ps">;
defm FG32H_PS : ETOpsRdR1R2G<0b0001000, "fg32h.ps">;
defm FG32B_PS : ETOpsRdR1R2G<0b0000100, "fg32b.ps">;
}

let mayStore = 1 in {
defm FSC32W_PS : ETOpsR3R1R2<0b1010000, 0b001, "fsc32w.ps">;
defm FSC32H_PS : ETOpsR3R1R2<0b1001000, 0b001, "fsc32h.ps">;
defm FSC32B_PS : ETOpsR3R1R2<0b1000100, 0b001, "fsc32b.ps">;
}

// Specialse FCMOVM has no implicit input since all of output
// is defined.
def FCMOVM_PS : RVInstR<0b0000000, 0b000, OPC_CVT_PS,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2),
                 "fcmovm.ps", "$rd, $rs1, $rs2">;
def FCMOVM_PS_EX : Pseudo<(outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2, MR0:$m0), [],
                 "fcmovm.ps", "$rd, $rs1, $rs2, $m0">;

defm FRCP_FIX_RAST : ETOpsRdR1R2<0b0011000, 0b000, OPC_OP_PS, "frcp_fix.rast">;
defm FCVT_RAST_PS : ETOpsRdR1<0b1100000,0b00010,0b000, OPC_OP_PS, "fcvt.rast.ps">;
defm FCVT_PS_RAST : ETOpsRdR1<0b1101000, 0b00010, 0b000, OPC_OP_PS, "fcvt.ps.rast">;
defm FSAT8_PI : ETOpsRdR1<0b0000011, 0b00000, 0b011, OPC_OP_PS, "fsat8.pi">;
defm FSATU8_PI : ETOpsRdR1<0b0000011, 0b00001, 0b011, OPC_OP_PS, "fsatu8.pi">;

multiclass ETOpsFdR1<bits<7> funct7, string opcodestr> {
   def "" : RVInstR<funct7,0b111,OPC_MEM_PS,
                      (outs FPR256:$rd), (ins GPR:$rs1),
                      opcodestr, "$rd, (${rs1})"> {
       let rs2 = 0;
  }
  def _EX : Pseudo<(outs FPR256:$rd),
                   (ins FPR256:$in, GPR:$rs1, MR0:$m0), [],
                   opcodestr, "$rd, (${rs1}), $m0"> {
    let Constraints = "$rd = $in";
  }
}

let mayLoad = 1 in {
defm FLWL_PS : ETOpsFdR1<0b0001000, "flwl.ps">;
defm FLWG_PS : ETOpsFdR1<0b0001001, "flwg.ps">;
}

multiclass ETOpsF1R2<bits<7> funct7, string opcodestr> {
    def "" : RVInstE14<funct7,0b111,OPC_MEM_PS,
                      (outs), (ins FPR256:$rs1, GPR:$rs2),
                      opcodestr, "$rs1, (${rs2})">;
    def _EX : Pseudo<(outs), (ins FPR256:$rs1, GPR:$rs2, MR0:$m0), [],
                     opcodestr, "$rs1, (${rs2}), $m0">;
}

let mayStore = 1 in {
defm FSWL_PS : ETOpsF1R2<0b0101000, "fswl.ps">;
defm FSWG_PS : ETOpsF1R2<0b0101001, "fswg.ps">;
}


multiclass ETOpsRdR1R2FG<bits<7> funct7, bits<3> funct3, string opcodestr> {
   def "" : RVInstR<funct7, funct3, OPC_MEM_PS, (outs FPR256:$rd),
            (ins FPR256:$rs1, GPR:$rs2), opcodestr,
            "$rd, ${rs1}(${rs2})">;
   def _EX : Pseudo<(outs FPR256:$rd),
            (ins FPR256:$in, FPR256:$rs1, GPR:$rs2, MR0:$m0), [], opcodestr,
            "$rd, ${rs1}(${rs2}), $m0"> {
      let Constraints = "$rd = $in";
   }
}

let mayLoad = 1 in {
defm FGBL_PS : ETOpsRdR1R2FG<0b1000000, 0b111, "fgbl.ps">;
defm FGHL_PS : ETOpsRdR1R2FG<0b1000100, 0b111, "fghl.ps">;
defm FGWL_PS : ETOpsRdR1R2FG<0b1001000, 0b111, "fgwl.ps">;
}

multiclass ETOpsR3R1R2FS<bits<7> funct7, bits<3> funct3, string opcodestr> {
  def "" : RVInstE12<funct7, funct3, OPC_MEM_PS, (outs),
            (ins FPR256:$rs3, FPR256:$rs1, GPR:$rs2), opcodestr,
            "${rs3}, ${rs1}(${rs2})">;
  def _EX : Pseudo<(outs),
            (ins FPR256:$rs3, FPR256:$rs1, GPR:$rs2, MR0:$m0),
            [], opcodestr,
            "${rs3}, ${rs1}(${rs2}), $m0">;
}

let mayStore = 1 in {
defm FSCBL_PS : ETOpsR3R1R2FS<0b1100000, 0b111, "fscbl.ps">;
defm FSCHL_PS : ETOpsR3R1R2FS<0b1100100, 0b111, "fschl.ps">;
defm FSCWL_PS : ETOpsR3R1R2FS<0b1101000, 0b111, "fscwl.ps">;
}


let mayLoad = 1 in {
defm FGBG_PS : ETOpsRdR1R2FG<0b1000001, 0b111, "fgbg.ps">;
defm FGHG_PS : ETOpsRdR1R2FG<0b1000101, 0b111, "fghg.ps">;
defm FGWG_PS : ETOpsRdR1R2FG<0b1001001, 0b111, "fgwg.ps">;
}
let mayStore = 1 in {
defm FSCBG_PS : ETOpsR3R1R2FS<0b1100001, 0b111, "fscbg.ps">;
defm FSCHG_PS : ETOpsR3R1R2FS<0b1100101, 0b111, "fschg.ps">;
defm FSCWG_PS : ETOpsR3R1R2FS<0b1101001, 0b111, "fscwg.ps">;
}

let mayLoad = 1, mayStore = 1 in {
defm FAMOADDL_PI  : ETOpsRdR1R2FG<0b0000011, 0b100, "famoaddl.pi">;
defm FAMOSWAPL_PI : ETOpsRdR1R2FG<0b0000111, 0b100, "famoswapl.pi">;
defm FAMOANDL_PI  : ETOpsRdR1R2FG<0b0001011, 0b100, "famoandl.pi">;
defm FAMOORL_PI   : ETOpsRdR1R2FG<0b0001111, 0b100, "famoorl.pi">;
defm FAMOXORL_PI  : ETOpsRdR1R2FG<0b0010011, 0b100, "famoxorl.pi">;
defm FAMOMINL_PI  : ETOpsRdR1R2FG<0b0010111, 0b100, "famominl.pi">;
defm FAMOMAXL_PI  : ETOpsRdR1R2FG<0b0011011, 0b100, "famomaxl.pi">;
defm FAMOMINUL_PI : ETOpsRdR1R2FG<0b0011111, 0b100, "famominul.pi">;
defm FAMOMAXUL_PI : ETOpsRdR1R2FG<0b0100011, 0b100, "famomaxul.pi">;
defm FAMOMINL_PS  : ETOpsRdR1R2FG<0b0011000, 0b100, "famominl.ps">;
defm FAMOMAXL_PS  : ETOpsRdR1R2FG<0b0010100, 0b100, "famomaxl.ps">;

defm FAMOADDG_PI  : ETOpsRdR1R2FG<0b1000011, 0b100, "famoaddg.pi">;
defm FAMOSWAPG_PI : ETOpsRdR1R2FG<0b1000111, 0b100, "famoswapg.pi">;
defm FAMOANDG_PI  : ETOpsRdR1R2FG<0b1001011, 0b100, "famoandg.pi">;
defm FAMOORG_PI   : ETOpsRdR1R2FG<0b1001111, 0b100, "famoorg.pi">;
defm FAMOXORG_PI  : ETOpsRdR1R2FG<0b1010011, 0b100, "famoxorg.pi">;
defm FAMOMING_PI  : ETOpsRdR1R2FG<0b1010111, 0b100, "famoming.pi">;
defm FAMOMAXG_PI  : ETOpsRdR1R2FG<0b1011011, 0b100, "famomaxg.pi">;
defm FAMOMINUG_PI : ETOpsRdR1R2FG<0b1011111, 0b100, "famominug.pi">;
defm FAMOMAXUG_PI : ETOpsRdR1R2FG<0b1100011, 0b100, "famomaxug.pi">;
defm FAMOMING_PS  : ETOpsRdR1R2FG<0b1011000, 0b100, "famoming.ps">;
defm FAMOMAXG_PS  : ETOpsRdR1R2FG<0b1010100, 0b100, "famomaxg.ps">;
}

class ETOpsR2R1<bits<7> funct7, bits<3> funct3, string opcodestr> :
     RVInstR<funct7, funct3, OPC_OP_32, (outs GPR:$rd),
            (ins GPR:$rs2, GPR:$rs1), opcodestr,
            "${rd}, ${rs2}, (${rs1})">;

let mayLoad = 1, mayStore = 1 in {
def AMOSWAPL_W : ETOpsR2R1<0b0000100, 0b010, "amoswapl.w">;
def AMOADDL_W  : ETOpsR2R1<0b0000000, 0b010, "amoaddl.w">;
def AMOXORL_W  : ETOpsR2R1<0b0010000, 0b010, "amoxorl.w">;
def AMOANDL_W  : ETOpsR2R1<0b0110000, 0b010, "amoandl.w">;
def AMOORL_W   : ETOpsR2R1<0b0100000, 0b010, "amoorl.w">;
def AMOMINL_W  : ETOpsR2R1<0b1000000, 0b010, "amominl.w">;
def AMOMAXL_W  : ETOpsR2R1<0b1010000, 0b010, "amomaxl.w">;
def AMOMINUL_W : ETOpsR2R1<0b1100000, 0b010, "amominul.w">;
def AMOMAXUL_W    : ETOpsR2R1<0b1110000, 0b010, "amomaxul.w">;
def AMOCMPSWAPL_W : ETOpsR2R1<0b1111000, 0b010, "amocmpswapl.w">;

def AMOSWAPG_W : ETOpsR2R1<0b0000101, 0b010, "amoswapg.w">;
def AMOADDG_W  : ETOpsR2R1<0b0000001, 0b010, "amoaddg.w">;
def AMOXORG_W  : ETOpsR2R1<0b0010001, 0b010, "amoxorg.w">;
def AMOANDG_W  : ETOpsR2R1<0b0110001, 0b010, "amoandg.w">;
def AMOORG_W   : ETOpsR2R1<0b0100001, 0b010, "amoorg.w">;
def AMOMING_W  : ETOpsR2R1<0b1000001, 0b010, "amoming.w">;
def AMOMAXG_W  : ETOpsR2R1<0b1010001, 0b010, "amomaxg.w">;
def AMOMINUG_W : ETOpsR2R1<0b1100001, 0b010, "amominug.w">;
def AMOMAXUG_W : ETOpsR2R1<0b1110001, 0b010, "amomaxug.w">;
def AMOCMPSWAPG_W : ETOpsR2R1<0b1111001, 0b010, "amocmpswapg.w">;

def AMOSWAPL_D : ETOpsR2R1<0b0000100, 0b011, "amoswapl.d">;
def AMOADDL_D  : ETOpsR2R1<0b0000000, 0b011, "amoaddl.d">;
def AMOXORL_D  : ETOpsR2R1<0b0010000, 0b011, "amoxorl.d">;
def AMOANDL_D  : ETOpsR2R1<0b0110000, 0b011, "amoandl.d">;
def AMOORL_D   : ETOpsR2R1<0b0100000, 0b011, "amoorl.d">;
def AMOMINL_D  : ETOpsR2R1<0b1000000, 0b011, "amominl.d">;
def AMOMAXL_D  : ETOpsR2R1<0b1010000, 0b011, "amomaxl.d">;
def AMOMINUL_D : ETOpsR2R1<0b1100000, 0b011, "amominul.d">;
def AMOMAXUL_D : ETOpsR2R1<0b1110000, 0b011, "amomaxul.d">;
def AMOCMPSWAPL_D : ETOpsR2R1<0b1111000, 0b011, "amocmpswapl.d">;

def AMOSWAPG_D : ETOpsR2R1<0b0000101, 0b011, "amoswapg.d">;
def AMOADDG_D  : ETOpsR2R1<0b0000001, 0b011, "amoaddg.d">;
def AMOXORG_D  : ETOpsR2R1<0b0010001, 0b011, "amoxorg.d">;
def AMOANDG_D  : ETOpsR2R1<0b0110001, 0b011, "amoandg.d">;
def AMOORG_D   : ETOpsR2R1<0b0100001, 0b011, "amoorg.d">;
def AMOMING_D  : ETOpsR2R1<0b1000001, 0b011, "amoming.d">;
def AMOMAXG_D  : ETOpsR2R1<0b1010001, 0b011, "amomaxg.d">;
def AMOMINUG_D : ETOpsR2R1<0b1100001, 0b011, "amominug.d">;
def AMOMAXUG_D : ETOpsR2R1<0b1110001, 0b011, "amomaxug.d">;
def AMOCMPSWAPG_D : ETOpsR2R1<0b1111001, 0b011, "amocmpswapg.d">;

} // let mayLoad = 1, mayStore =1 in


class ETOpsR1R2S<bits<7> funct7, bits<3> funct3, string opcodestr> :
     RVInstR<funct7, funct3, OPC_OP_32, (outs),
            (ins GPR:$rs2, GPR:$rs1), opcodestr,
            "${rs2}, (${rs1})"> {
    let rd = 0;
}

let mayLoad = 1 in {
def SBL : ETOpsR1R2S<0b0001000, 0b011, "sbl">;
def SHL : ETOpsR1R2S<0b0001100, 0b011, "shl">;
def SBG : ETOpsR1R2S<0b0001001, 0b011, "sbg">;
def SHG : ETOpsR1R2S<0b0001101, 0b011, "shg">;
}

// These pseudo operations are used for stack references
// where various places assume the offset immediate follows
// the address operand.
let mayStore = 1 in
def StackFSQ2 : Pseudo<(outs),
                     (ins FPR256:$rs2, GPR:$rs1, simm12:$imm), [],
                     "fsq2", "$rs2, ${imm}(${rs1})">;
let mayLoad = 1 in
def StackFLQ2 : Pseudo<(outs FPR256:$rd),
                     (ins GPR:$rs1, simm12:$imm), [],
                     "flq2", "$rd, ${imm}(${rs1})">;

// These pseudo operations are used for spill and reload
// of mask operations
let mayStore = 1 in
def StackMS : Pseudo<(outs),
                     (ins MR:$rs2, GPR:$rs1, simm12:$imm), [],
                     "ms", "$rs2, ${imm}(${rs1})">;
let mayLoad = 1 in
def StackML : Pseudo<(outs MR:$rd),
                     (ins GPR:$rs1, simm12:$imm), [],
                     "ml", "$rd, ${imm}(${rs1})">;

} // let hasSideEffects = 0, mayLoad = 0, mayStore = 0

} // HasEsperanto
} // DecoderNamespace

//===----------------------------------------------------------------------===//
// Pseudo-instructions and codegen patterns
//===----------------------------------------------------------------------===//

class EspPat<dag pattern, dag result> : Pat<pattern, result> {
  let Predicates = [HasEsperanto];
}

foreach ty = [v8i32, v8f32] in {
def : EspPat<(store (ty FPR256:$rs2), GPR:$rs1), (FSQ2 $rs2, 0, $rs1)>;
def : EspPat<(store (ty FPR256:$rs2), AddrFI:$rs1), (StackFSQ2 $rs2, $rs1, 0)>;
def : EspPat<(store (ty FPR256:$rs2), (add GPR:$rs1, simm12:$imm12)),
          (FSQ2 $rs2, (LO12s $imm12), $rs1)>;
def : EspPat<(store (ty FPR256:$rs2), (add AddrFI:$rs1, simm12:$imm12)),
          (StackFSQ2 $rs2, $rs1, (LO12s $imm12))>;

def : EspPat<(ty (load GPR:$rs1)), (FLQ2 0, $rs1)>;
def : EspPat<(ty (load (add GPR:$rs1, simm12:$imm12))),
             (FLQ2 (LO12s $imm12), $rs1)>;
def : EspPat<(ty (load (add AddrFI:$rs1, simm12:$imm12))),
             (StackFLQ2 $rs1, (LO12s $imm12))>;
def : EspPat<(ty (load (add AddrFI:$rs1, simm12:$imm12))),
             (StackFLQ2 $rs1, (LO12s $imm12))>;
}


class RoundingMode<int Value> {
   int rm = Value;
}
def RTZ : RoundingMode<0b001> ;
def DYN : RoundingMode<0b111> ;

def allLanes : OutPatFrag<(ops ), (MOV_M_X X0, 0xff)>;

def : EspPat<(v8i32 (et_broadcast simm20:$e0)),
          (FBCI_PI_EX (IMPLICIT_DEF), (LO20s $e0), (allLanes))>;

def : EspPat<(v8i32 (et_broadcast GPR:$e0)),
          (FBCX_PS_EX (IMPLICIT_DEF), $e0, (allLanes))>;

def : EspPat<(add (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FADD_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(add (v8i32 FPR256:$rs1), (et_broadcast simm10:$c)),
          (FADDI_PI_EX (IMPLICIT_DEF), $rs1, (LO10s $c), (allLanes))>;
def : EspPat<(sub (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FSUB_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(mul (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FMUL_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(and (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FAND_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(and (v8i32 FPR256:$rs1), (et_broadcast simm10:$c)),
          (FANDI_PI_EX (IMPLICIT_DEF), $rs1, (LO10s $c), (allLanes))>;
def : EspPat<(or (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FOR_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(xor (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FXOR_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

def splat8 : PatFrag<(ops node:$X),
                     (build_vector $X, $X, $X, $X, $X, $X, $X, $X)>;

def : EspPat<(xor (v8i32 FPR256:$rs1), (et_broadcast (i64 -1))),
          (FNOT_PI_EX (IMPLICIT_DEF), $rs1, (allLanes))>;

// The simulator does uses all bits of the shift amount
// instead of the low 5 like the sllw.s instructions deos
// so here we explicitly mask the low bits so that vector
// and scalar aggree.
def : EspPat<(shl (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FSLL_PI_EX (IMPLICIT_DEF), $rs1,
                      (FANDI_PI_EX (IMPLICIT_DEF), $rs2, 31, (allLanes)),
                      (allLanes))>;

def : EspPat<(shl (v8i32 FPR256:$rs1), (v8i32 (et_broadcast uimm5:$c))),
          (FSLLI_PI_EX (IMPLICIT_DEF), $rs1, (LO5 $c), (allLanes))>;

// same comment as shl above
def : EspPat<(srl (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FSRL_PI_EX (IMPLICIT_DEF), $rs1,
                      (FANDI_PI_EX (IMPLICIT_DEF), $rs2, 31, (allLanes)),
                      (allLanes))>;

def : EspPat<(srl (v8i32 FPR256:$rs1), (v8i32 (et_broadcast uimm5:$c))),
          (FSRLI_PI_EX (IMPLICIT_DEF), $rs1, (LO5 $c), (allLanes))>;

// same comment as shl above
def : EspPat<(sra (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FSRA_PI_EX (IMPLICIT_DEF), $rs1,
                      (FANDI_PI_EX (IMPLICIT_DEF), $rs2, 31, (allLanes)),
                      (allLanes))>;

def : EspPat<(sra (v8i32 FPR256:$rs1), (v8i32 (et_broadcast uimm5:$c))),
          (FSRAI_PI_EX (IMPLICIT_DEF), $rs1, (LO5 $c), (allLanes))>;


def : EspPat<(sdiv (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FDIV_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(udiv (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FDIVU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(srem (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FREM_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(urem (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FREMU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(fadd (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (FADD_PS_EX (IMPLICIT_DEF), $rs1, $rs2, DYN.rm, (allLanes))>;
def : EspPat<(fsub (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (FSUB_PS_EX (IMPLICIT_DEF), $rs1, $rs2, DYN.rm, (allLanes))>;
def : EspPat<(fmul (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (FMUL_PS_EX (IMPLICIT_DEF), $rs1, $rs2, DYN.rm, (allLanes))>;
def : EspPat<(fdiv (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (FDIV_PS_EX (IMPLICIT_DEF), $rs1, $rs2, DYN.rm, (allLanes))>;
def : EspPat<(fdiv (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (FDIV_PS_EX (IMPLICIT_DEF), $rs1, $rs2, DYN.rm, (allLanes))>;

def : EspPat<(frem (v8f32 FPR256:$x), (v8f32 FPR256:$y)),
          (FNMSUB_PS_EX
                (IMPLICIT_DEF),
                (FROUND_PS_EX (IMPLICIT_DEF),
                      (FDIV_PS_EX (IMPLICIT_DEF), $x, $y, DYN.rm, (allLanes)),
                      /*RTZ*/ 0b001, (allLanes)),
                $y, $x, DYN.rm, (allLanes))>;


def : EspPat<(fma (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2), (v8f32 FPR256:$rs3)),
          (FMADD_PS_EX (IMPLICIT_DEF), $rs1, $rs2, $rs3, DYN.rm,
                       (allLanes))>;
def : EspPat<(fmad (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2), (v8f32 FPR256:$rs3)),
          (FADD_PS_EX (IMPLICIT_DEF),
                      (FMUL_PS_EX (IMPLICIT_DEF), $rs1, $rs2, DYN.rm, (allLanes)),
                      $rs3, DYN.rm, (allLanes))>;
def : EspPat<(fmad (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2), (fneg (v8f32 FPR256:$rs3))),
          (FSUB_PS_EX (IMPLICIT_DEF),
                      (FMUL_PS_EX (IMPLICIT_DEF), $rs1, $rs2, DYN.rm, (allLanes)),
                      $rs3, DYN.rm, (allLanes))>;

def : EspPat<(fmad (fneg (v8f32 FPR256:$rs1)), (v8f32 FPR256:$rs2), (v8f32 FPR256:$rs3)),
          (FSUB_PS_EX (IMPLICIT_DEF),
                      $rs3,
                      (FMUL_PS_EX (IMPLICIT_DEF), $rs1, $rs2, DYN.rm, (allLanes)),
                      DYN.rm, (allLanes))>;

def : EspPat<(fmad (v8f32 FPR256:$rs1), (fneg (v8f32 FPR256:$rs2)), (v8f32 FPR256:$rs3)),
          (FSUB_PS_EX (IMPLICIT_DEF),
                      $rs3,
                      (FMUL_PS_EX (IMPLICIT_DEF), $rs1, $rs2, DYN.rm, (allLanes)),
                      DYN.rm, (allLanes))>;

def : EspPat<(fma (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2), (fneg (v8f32 FPR256:$rs3))),
          (FMSUB_PS_EX (IMPLICIT_DEF), $rs1, $rs2, $rs3, DYN.rm,
                       (allLanes))>;

def : EspPat<(fma (fneg (v8f32 FPR256:$rs1)), (v8f32 FPR256:$rs2),
                                              (v8f32 FPR256:$rs3)),
          (FNMSUB_PS_EX (IMPLICIT_DEF), $rs1, $rs2, $rs3, DYN.rm,
                        (allLanes))>;

def : EspPat<(fma (v8f32 FPR256:$rs1), (fneg (v8f32 FPR256:$rs2)),
                                       (v8f32 FPR256:$rs3)),
          (FNMSUB_PS_EX (IMPLICIT_DEF), $rs1, $rs2, $rs3, DYN.rm,
                        (allLanes))>;

def : EspPat<(fma (fneg (v8f32 FPR256:$rs1)), (v8f32 FPR256:$rs2),
                                              (fneg (v8f32 FPR256:$rs3))),
          (FNMADD_PS_EX (IMPLICIT_DEF), $rs1, $rs2, $rs3, DYN.rm,
                        (allLanes))>;

def : EspPat<(fneg (fma (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2),
                                             (v8f32 FPR256:$rs3))),
          (FNMADD_PS_EX (IMPLICIT_DEF), $rs1, $rs2, $rs3, DYN.rm,
                        (allLanes))>;

def : EspPat<(fminimum (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (FMIN_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

def : EspPat<(fmaximum (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (FMAX_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

def : EspPat<(fcopysign (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (FSGNJ_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

def : EspPat<(fcopysign (v8f32 FPR256:$rs1), (fneg (v8f32 FPR256:$rs2))),
          (FSGNJN_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

def : EspPat<(fabs (v8f32 FPR256:$rs1)),
          (FSGNJX_PS_EX (IMPLICIT_DEF), $rs1, $rs1, (allLanes))>;

def : EspPat<(fsqrt (v8f32 FPR256:$rs1)),
          (FSQRT_PS_EX (IMPLICIT_DEF), $rs1, (allLanes))>;

def : EspPat<(fsin (v8f32 FPR256:$rs1)),
          (FSIN_PS_EX (IMPLICIT_DEF), $rs1, (allLanes))>;

def : EspPat<(fneg (v8f32 FPR256:$rs1)),
          (FSGNJN_PS_EX (IMPLICIT_DEF), $rs1, $rs1, (allLanes))>;

def : EspPat<(flog2 (v8f32 FPR256:$rs1)),
          (FLOG_PS_EX (IMPLICIT_DEF), $rs1, (allLanes))>;

def : EspPat<(fexp2 (v8f32 FPR256:$rs1)),
          (FEXP_PS_EX (IMPLICIT_DEF), $rs1, (allLanes))>;


def : EspPat<(setoeq (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (v8i1 (FEQM_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)))>;
def : EspPat<(v8i32 (sext (v8i1 (setoeq (v8f32 FPR256:$rs1),
                                        (v8f32 FPR256:$rs2))))),
             (FEQ_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(v8i32 (setoeq (v8f32 FPR256:$rs1),
                                        (v8f32 FPR256:$rs2))),
             (FEQ_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;


def : EspPat<(setolt (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (v8i1 (FLTM_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)))>;
def : EspPat<(v8i32 (sext (v8i1 (setolt (v8f32 FPR256:$rs1),
                                        (v8f32 FPR256:$rs2))))),
          (FLT_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(v8i32 (setolt (v8f32 FPR256:$rs1),
                                        (v8f32 FPR256:$rs2))),
          (FLT_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

def : EspPat<(setole (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (v8i1 (FLEM_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)))>;
def : EspPat<(v8i32 (sext (v8i1 (setole (v8f32 FPR256:$rs1),
                                        (v8f32 FPR256:$rs2))))),
          (FLE_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(v8i32 (setole (v8f32 FPR256:$rs1),
                                        (v8f32 FPR256:$rs2))),
          (FLE_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;


def : EspPat<(seto (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (v8i1 (FEQM_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)))>;

def : EspPat<(v8i32 (sext (v8i1 (seto (v8f32 FPR256:$rs1),
                                        (v8f32 FPR256:$rs2))))),
          (FEQ_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(v8i32 (seto (v8f32 FPR256:$rs1),
                          (v8f32 FPR256:$rs2))),
          (FEQ_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;


def : EspPat<(setune (v8f32 FPR256:$rs1), (v8f32 FPR256:$rs2)),
          (v8i1 (MASKNOT
                (FEQM_PS_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))))>;


def : EspPat<(setult (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (v8i1 (FSETM_PI_EX (IMPLICIT_DEF),
                       (FLTU_PI_EX  (IMPLICIT_DEF), $rs1, $rs2, (allLanes)),
                       (allLanes)))>;

def : EspPat<(v8i32 (sext (v8i1 (setult (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))))),
          (FLTU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(v8i32 (setult (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
          (FLTU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

def : EspPat<(v8i32 (sext (v8i1 (setle (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))))),
          (FLE_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(v8i32 (setle (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
          (FLE_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(setle (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (v8i1 (FSETM_PI_EX (IMPLICIT_DEF),
                       (FLE_PI_EX  (IMPLICIT_DEF), $rs1, $rs2, (allLanes)),
                       (allLanes)))>;

foreach ty = [v8i32, v8f32] in {
def : EspPat<(vselect (v8i1 (setle (ty FPR256:$rs1), (ty FPR256:$rs2))),
                   (ty FPR256:$true), (ty FPR256:$false)),
          (ty (FCMOV_PS_EX (ty (IMPLICIT_DEF)),
                      (FLE_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)),
                      $true, $false,
                      (allLanes)))>;
}

def : EspPat<(v8i32 (sext (v8i1 (setlt (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))))),
          (FLT_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(v8i32 (setlt (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
          (FLT_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(v8i1 (setlt (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
          (FLTM_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

// 0, -1  -> -1, 0
def v8i32_not : OutPatFrag<(ops node:$n),
          (FNOT_PI_EX (IMPLICIT_DEF), $n, (allLanes))>;

// x != y -->  !(x == y)
def : EspPat<(v8i1 (setne (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
             (MASKNOT (FSETM_PI_EX (IMPLICIT_DEF),
                                (FEQ_PI_EX (IMPLICIT_DEF),
                                             $rs1, $rs2, (allLanes)),
                                (allLanes)))>;
def : EspPat<(v8i32 (sext (v8i1 (setne (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))))),
           (v8i32_not (FEQ_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)))>;
def : EspPat<(v8i32 (setne (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
           (v8i32_not (FEQ_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)))>;

def : EspPat<(v8i32 (sext (v8i1 (seteq (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))))),
          (v8i32 (FEQ_PI_EX  (IMPLICIT_DEF), $rs1, $rs2, (allLanes)))>;
def : EspPat<(seteq (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
             (v8i32 (FEQ_PI_EX  (IMPLICIT_DEF), $rs1, $rs2,
                                   (allLanes)))>;

def : EspPat<(seteq (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (v8i1 (FSETM_PI_EX (IMPLICIT_DEF),
                       (FEQ_PI_EX  (IMPLICIT_DEF), $rs1, $rs2,
                                   (allLanes)),
                       (allLanes)))>;

foreach ty = [v8i32, v8f32] in {
def : EspPat<(vselect (v8i1 (seteq (ty FPR256:$rs1), (ty FPR256:$rs2))),
                   (ty FPR256:$true), (ty FPR256:$false)),
          (ty (FCMOV_PS_EX (ty (IMPLICIT_DEF)),
                      (FEQ_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)),
                      $true, $false,
                      (allLanes)))>;
}


def : EspPat<(v8i32 (sext (v8i1 (setult (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))))),
          (FLTU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(v8i32 (setult (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
          (FLTU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

foreach ty = [v8i32, v8f32] in {
def : EspPat<(vselect (v8i1 (setult (ty FPR256:$rs1), (ty FPR256:$rs2))),
                   (ty FPR256:$true), (ty FPR256:$false)),
          (ty (FCMOV_PS_EX (ty (IMPLICIT_DEF)),
                      (FLTU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)),
                      $true, $false,
                      (allLanes)))>;
}

// x >=u y => !(y < x)
def : EspPat<(setuge (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (v8i1 (MASKNOT (FLTM_PI_EX (IMPLICIT_DEF),
                                     $rs2, $rs1, (allLanes))))>;

def : EspPat<(v8i32 (sext (v8i1 (setuge (v8i32 FPR256:$rs1),
                                        (v8i32 FPR256:$rs2))))),
          (v8i32_not (FLTU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)))>;
def : EspPat<(v8i32 (setuge (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
          (v8i32_not (FLTU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)))>;


// x <=u  y =>   x <u y  | x == y
def et_ule : OutPatFrag<(ops node:$rs1, node:$rs2),
          (FOR_PI_EX (IMPLICIT_DEF),
                     (FLTU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)),
                     (FEQ_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes)),
                     (allLanes))>;

def : EspPat<(v8i32 (sext (v8i1 (setule (v8i32 FPR256:$rs1),
                                        (v8i32 FPR256:$rs2))))),
          (et_ule $rs1, $rs2)>;
def : EspPat<(v8i32 (setule (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
          (et_ule $rs1, $rs2)>;
def : EspPat<(v8i1 (setule (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2))),
          (v8i1 (FSETM_PI_EX (IMPLICIT_DEF), (et_ule $rs1, $rs2), (allLanes)))>;

foreach ty = [v8i32, v8f32] in {
def : EspPat<(vselect (v8i1 (setule (ty FPR256:$rs1), (ty FPR256:$rs2))),
                   (ty FPR256:$true), (ty FPR256:$false)),
          (ty (FCMOV_PS_EX (ty (IMPLICIT_DEF)),
                      (et_ule $rs1, $rs2),
                      $true, $false,
                      (allLanes)))>;
}

def : EspPat<(smin (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FMIN_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(smax (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FMAX_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(umin (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FMINU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;
def : EspPat<(umax (v8i32 FPR256:$rs1), (v8i32 FPR256:$rs2)),
          (FMAXU_PI_EX (IMPLICIT_DEF), $rs1, $rs2, (allLanes))>;

// Rounding modes match RISVInstrInfoF.td
def : EspPat<(sint_to_fp (v8i32 FPR256:$rs1)),
          (v8f32 (FCVT_PS_PW_EX (v8f32 (IMPLICIT_DEF)), $rs1,
                                   DYN.rm, (allLanes)))>;
def : EspPat<(uint_to_fp (v8i32 FPR256:$rs1)),
          (v8f32 (FCVT_PS_PWU_EX (v8f32 (IMPLICIT_DEF)), $rs1,
                                DYN.rm, (allLanes)))>;
def : EspPat<(fp_to_sint (v8f32 FPR256:$rs1)),
          (v8i32 (FCVT_PW_PS_EX (v8i32 (IMPLICIT_DEF)), $rs1,
                                  RTZ.rm, (allLanes)))>;
def : EspPat<(fp_to_uint (v8f32 FPR256:$rs1)),
          (v8i32 (FCVT_PWU_PS_EX (v8i32 (IMPLICIT_DEF)), $rs1,
                                  RTZ.rm, (allLanes)))>;

def : EspPat<(v8i32 (sext (v8i1 MR:$m))),
          (FBCI_PI_EX (FBCI_PI_EX (IMPLICIT_DEF), 0, (allLanes)),
                      -1, $m)>;

def : EspPat<(xor (v8i1 MR:$m), (v8i1 (splat8 (i64 1)))),
           (MASKNOT $m)>;

def : EspPat<(xor (v8i1 MR:$m), (v8i1 (splat8 (i1 1)))),
           (MASKNOT $m)>;

def : EspPat<(v8i1 (splat8 (i1 1))), (allLanes)>;
def : EspPat<(v8i1 (splat8 (i64 1))), (allLanes)>;

foreach ty = [v8f32, v8i32] in {
   def : EspPat<(ty (vselect MR:$cond, FPR256:$true, FPR256:$false)),
          (FCMOVM_PS_EX $true, $false, $cond)>;
   def : EspPat<(ty (vselect FPR256:$cond, FPR256:$true, FPR256:$false)),
          (FCMOV_PS_EX (IMPLICIT_DEF), $true, $false, $cond, (allLanes))>;
}

def : EspPat<(v8i32 (splat8 (i64 -1))),
          (FBCI_PI_EX (IMPLICIT_DEF), -1, (allLanes))>;

def : EspPat<(v8i32 (build_vector GPR:$e0, GPR:$e1, GPR:$e2, GPR:$e3,
                               GPR:$e4, GPR:$e5, GPR:$e6, GPR:$e7)),
          (v8i32 (FBCX_PS_EX
          (v8i32 (FBCX_PS_EX
          (v8i32 (FBCX_PS_EX
          (v8i32 (FBCX_PS_EX
          (v8i32 (FBCX_PS_EX
          (v8i32 (FBCX_PS_EX
          (v8i32 (FBCX_PS_EX
          (v8i32 (FBCX_PS_EX (v8i32 (IMPLICIT_DEF)),
              $e0, (v8i1 (MOV_M_X X0, 0b00000001)))),
              $e1, (v8i1 (MOV_M_X X0, 0b00000010)))),
              $e2, (v8i1 (MOV_M_X X0, 0b00000100)))),
              $e3, (v8i1 (MOV_M_X X0, 0b00001000)))),
              $e4, (v8i1 (MOV_M_X X0, 0b00010000)))),
              $e5, (v8i1 (MOV_M_X X0, 0b00100000)))),
              $e6, (v8i1 (MOV_M_X X0, 0b01000000)))),
              $e7, (v8i1 (MOV_M_X X0, 0b10000000))))>;

def : EspPat<(v8f32 (build_vector FPR32:$e0, undef, undef, undef,
                               undef, undef, undef, undef)),
           (v8f32 (INSERT_SUBREG (v8f32 (IMPLICIT_DEF)), $e0, sub_32))>;

def : EspPat<(v8i32 (build_vector (i64 GPR:$e0), undef, undef, undef,
                               undef, undef, undef, undef)),
           (v8i32 (INSERT_SUBREG (v8i32 (IMPLICIT_DEF)), $e0, sub_32))>;

def : EspPat<(v8f32 (build_vector FPR32:$e0, FPR32:$e1, FPR32:$e2, FPR32:$e3,
                               FPR32:$e4, FPR32:$e5, FPR32:$e6, FPR32:$e7)),
          (v8f32 (FBCX_PS_EX
          (v8f32 (FBCX_PS_EX
          (v8f32 (FBCX_PS_EX
          (v8f32 (FBCX_PS_EX
          (v8f32 (FBCX_PS_EX
          (v8f32 (FBCX_PS_EX
          (v8f32 (FBCX_PS_EX
          (v8f32 (FBCX_PS_EX (v8f32 (IMPLICIT_DEF)),
              (FMV_X_W $e0), (v8i1 (MOV_M_X X0, 0b00000001)))),
              (FMV_X_W $e1), (v8i1 (MOV_M_X X0, 0b00000010)))),
              (FMV_X_W $e2), (v8i1 (MOV_M_X X0, 0b00000100)))),
              (FMV_X_W $e3), (v8i1 (MOV_M_X X0, 0b00001000)))),
              (FMV_X_W $e4), (v8i1 (MOV_M_X X0, 0b00010000)))),
              (FMV_X_W $e5), (v8i1 (MOV_M_X X0, 0b00100000)))),
              (FMV_X_W $e6), (v8i1 (MOV_M_X X0, 0b01000000)))),
              (FMV_X_W $e7), (v8i1 (MOV_M_X X0, 0b10000000))))>;

def : EspPat<(v8i32 (build_vector simm20:$e0, simm20:$e1,
                               simm20:$e2, simm20:$e3,
                               simm20:$e4, simm20:$e5,
                               simm20:$e6, simm20:$e7)),
          (FBCI_PI_EX
          (FBCI_PI_EX
          (FBCI_PI_EX
          (FBCI_PI_EX
          (FBCI_PI_EX
          (FBCI_PI_EX
          (FBCI_PI_EX
          (FBCI_PI_EX (v8i32 (IMPLICIT_DEF)),
              (LO20s $e0), (v8i1 (MOV_M_X X0, 0b00000001))),
              (LO20s $e1), (v8i1 (MOV_M_X X0, 0b00000010))),
              (LO20s $e2), (v8i1 (MOV_M_X X0, 0b00000100))),
              (LO20s $e3), (v8i1 (MOV_M_X X0, 0b00001000))),
              (LO20s $e4), (v8i1 (MOV_M_X X0, 0b00010000))),
              (LO20s $e5), (v8i1 (MOV_M_X X0, 0b00100000))),
              (LO20s $e6), (v8i1 (MOV_M_X X0, 0b01000000))),
              (LO20s $e7), (v8i1 (MOV_M_X X0, 0b10000000)))>;

def : EspPat<(v8i1 (and (v8i1 MR:$x), (v8i1 MR:$y))), (MASKAND $x, $y)>;
def : EspPat<(v8i1 (or (v8i1 MR:$x), (v8i1 MR:$y))), (MASKOR $x, $y)>;
def : EspPat<(v8i1 (xor (v8i1 MR:$x), (v8i1 MR:$y))), (MASKXOR $x, $y)>;

def : EspPat<(v8i32 (bitconvert (v8f32 FPR256:$in))), (v8i32 (COPY $in))>;
def : EspPat<(v8f32 (bitconvert (v8i32 FPR256:$in))), (v8f32 (COPY $in))>;

let Defs = [M0] in
def IOTA : Pseudo<(outs FPR256:$rd), (ins), [], "iota", "$rd">;
def : EspPat<(int_riscv_iota), (IOTA)>;
def HARTID : Pseudo<(outs GPR:$rd), (ins), [], "hartid", "$rd">;
def : EspPat<(int_riscv_hartid), (HARTID)>;

def TO_VECTOR : Pseudo<(outs FPR256:$rd), (ins GPR:$rs1), [], "fmv.ps.x", "$rd, $rs1">;
def : EspPat<(int_riscv_et_to_vector GPR:$rs1),
             (TO_VECTOR $rs1)>;

def : EspPat<(f32 (extractelt FPR256:$rd, 0)),
          (f32 (EXTRACT_SUBREG $rd, sub_32))>;

def : EspPat<(f32 (extractelt FPR256:$rs1, uimm5:$idx)),
          (f32 (FMV_W_X (FMVZ_X_PS $rs1, (LO3 $idx))))>;

def : EspPat<(v8f32 (insertelt (v8f32 FPR256:$rs1), (f32 FPR32:$rs2), (i64 0))),
          (v8f32 (INSERT_SUBREG $rs1, $rs2, sub_32))>;

foreach SrcTy = [v8i32, v8f32] in {
    foreach DstTy = [v8i32, v8f32] in {
        def : EspPat<(DstTy (int_riscv_coerce_vector (SrcTy FPR256:$rs1))),
                         (COPY $rs1)>;
    }
}

def : EspPat<(v8i32 (masked_ld GPR:$ptr, undef, (v8i1 MR:$mask), FPR256:$passthru)),
          (FLW_PS_EX $passthru, 0, $ptr, $mask)>;
def : EspPat<(v8f32 (masked_ld GPR:$ptr, undef, (v8i1 MR:$mask), FPR256:$passthru)),
          (FLW_PS_EX $passthru, 0, $ptr, $mask)>;

def : EspPat<(masked_st (v8i32 FPR256:$rs1), GPR:$ptr, undef, (v8i1 MR:$mask)),
          (FSW_PS_EX $rs1, 0, $ptr, $mask)>;
def : EspPat<(masked_st (v8f32 FPR256:$rs1), GPR:$ptr, undef, (v8i1 MR:$mask)),
          (FSW_PS_EX $rs1, 0, $ptr, $mask)>;


include "RISCVInstrInfoEsperantoPatterns.td"

def : EspPat<(i64 (addrspacecast GPR:$in)), (COPY $in)>;

