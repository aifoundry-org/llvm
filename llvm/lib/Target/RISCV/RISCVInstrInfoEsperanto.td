//===-- RISCVRegisterInfoEsperanto.td -===== Register defs -*- tablegen -*-===//
//
// No copy rights
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the instruction extensions for
//  Esperanto ET-SOC-1
//===----------------------------------------------------------------------===//

include "RISCVInstrFormatsEsperanto.td"

let Predicates = [HasEsperanto] in {

// Guess: load two consecutive 16-bit floats...
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def FLQ2 : RVInstI<0b101, OPC_LOAD_FP,
                   (outs FPR32:$rd),
                   (ins GPR:$rs1, simm12:$imm12),
                   "flq2", "$rd, ${imm12}(${rs1})">;

// Guess: store two consecutive 16-bit floats...
let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def FSQ2 : RVInstS<0b101, OPC_STORE_FP,
                   (outs),
                   (ins FPR32:$rs2, GPR:$rs1, simm12:$imm12),
                   "fsq2", "$rs2, ${imm12}(${rs1})">;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def FLW_PS : RVInstI<0b010, OPC_MEM_PS,
                   (outs FPR256:$rd),
                   (ins GPR:$rs1, simm12:$imm12),
                   "flw.ps", "$rd, ${imm12}(${rs1})">;
                                        
let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def FSW_PS : RVInstS<0b110, OPC_MEM_PS,
                   (outs),
                   (ins FPR256:$rs2, GPR:$rs1, simm12:$imm12),
                   "fsw.ps", "$rs2, ${imm12}(${rs1})">;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def FBC_PS : RVInstI<0b000, OPC_MEM_PS,
                   (outs FPR256:$rd),
                   (ins GPR:$rs1, simm12:$imm12),
                   "fbc.ps", "$rd, ${imm12}(${rs1})">;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def FBCX_PS : RVInstI<0b011, OPC_MEM_PS,
                   (outs FPR256:$rd),
                   (ins GPR:$rs1, simm12:$imm12),
                   "fbcx.ps", "$rd, (${rs1})"> {
    let imm12 = 0;
}        

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
/*
Omit for now until we find out whether the immedaite is signed or not.
def FBCI_PS : RVInstU<OPC_OP_IMM_32PS,
                      (outs FPR256:$rd),
                      (ins simm20:$imm20),
                      "fbci.ps", "$rd, $imm20"> ;
*/
def FGW_PS : RVInstRPS<0b01100, 0b001, OPC_G_PS, "fgw.ps">;
def FGH_PS : RVInstRPS<0b01010, 0b001, OPC_G_PS, "fgh.ps">;
def FGB_PS : RVInstRPS<0b01001, 0b001, OPC_G_PS, "fgb.ps">;
def FSCW_PS : RVInstR3PS<0b11100, 0b001, OPC_G_PS, "fscw.ps">;
def FSCH_PS : RVInstR3PS<0b11010, 0b001, OPC_G_PS, "fsch.ps">;
def FSCB_PS : RVInstR3PS<0b11001, 0b001, OPC_G_PS, "fscb.ps">;
def FADD_PS : RVInstRPSrm<0b0000000, OPC_OP_PS, "fadd.ps">;
def FSUB_PS : RVInstRPSrm<0b0000100, OPC_OP_PS, "fsub.ps">;
def FMUL_PS : RVInstRPSrm<0b0001000, OPC_OP_PS, "fmul.ps">;
def FDIV_PS : RVInstRPSrm<0b0001100, OPC_OP_PS, "fdiv.ps">;
def FMIN_PS : RVInstRPS<0b00101, 0b000, OPC_G_PS, "fmin.ps">;
def FMAX_PS : RVInstRPS<0b00101, 0b001, OPC_G_PS, "fmax.ps">;
def FMADD_PS : RVInstR4PSrm<0b00, OPC_OP3_PS, "fmadd.ps">;
def FMSUB_PS : RVInstR4PSrm<0b01, OPC_OP3_PS, "fmsub.ps">;
def FNMSUB_PS : RVInstR4PSrm<0b10, OPC_OP3_PS, "fnmsub.ps">;
def FNMADD_PS : RVInstR4PSrm<0b11, OPC_OP3_PS, "fnmadd.ps">;
def FCMOV : RVInstE4<0b10, RISCVOpcode<0b0111111>,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2, FPR256:$rs3),
                    "fcmov.ps", "$rd, $rs1, $rs2, $rs3"> {
    let rm = 0b010;                    
}
//  TODO -- is this store? in case the model is wrong and
//  the documentation misnames the registers
def FSWIZZ_PS : RVInstE1<0b1110011, OPC_OP_PS,
                         (outs FPR256:$rd),
                         (ins FPR256:$rs1, simm12:$imm), // TODO: simm8
                         "fswizz.ps", "$rd, $rs1, $imm">;
def FCVT_PW_PS  : RVInstRPSrm2<0b1100000, 0,  OPC_OP_PS, "fcvt.pw.ps">;
def FCVT_PWU_PS : RVInstRPSrm2<0b1100000, 1, OPC_OP_PS, "fcvt.pwu.ps">;
def FCVT_PS_PW  : RVInstRPSrm2<0b1101000, 0, OPC_OP_PS, "fcvt.ps.pw">;
def FCVT_PS_PWU : RVInstRPSrm2<0b1101000, 1, OPC_OP_PS, "fcvt.ps.pw">;
def FMVZ_X_PS : RVInstRPSidx<0b1110000, 0b000, OPC_OP_PS, "fmvz.x.ps">;
def FMVS_X_PS : RVInstRPSidx<0b1110000, 0b010, OPC_OP_PS, "fmvs.x.ps">;

def FSGNJN_PS : RVInstRPS<0b00100, 0b001, OPC_OP_PS, "fsgnjn.ps">;
def FSGNJ_PS  : RVInstRPS<0b00100, 0b000, OPC_OP_PS, "fsgnj.ps">;
def FSGNJX_PS : RVInstRPS<0b00100, 0b010, OPC_OP_PS, "fsgnjx.ps">;
def FLE_PS    : RVInstRPS<0b10100, 0b000, OPC_OP_PS, "fle.ps">;
def FLT_PS    : RVInstRPS<0b10100, 0b001, OPC_OP_PS, "flt.ps">;
def FEQ_PS    : RVInstRPS<0b10100, 0b010, OPC_OP_PS, "feq.ps">;

def FLEM_PS   : RVInstRPSM<0b10100, 0b100, OPC_OP_PS, "flem.ps">;
def FLTM_PS   : RVInstRPSM<0b10100, 0b101, OPC_OP_PS, "fltm.ps">;
def FEQM_PS   : RVInstRPSM<0b10100, 0b110, OPC_OP_PS, "feqm.ps">;
}


} // HasEsperanto
                                    
