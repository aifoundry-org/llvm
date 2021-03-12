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
                   (ins FPR256:$rs1, GPR:$rs2, simm12:$imm12),
                   "fsw.ps", "$rs1, ${imm12}(${rs2})">;

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

let hasSideEffects = 0, mayStore = 0, mayLoad = 0 in {
def FBCI_PS : RVInstU<OPC_IMM_PS,
                      (outs FPR256:$rd),
                      (ins uimm20_lui:$imm20),
                      "fbci.ps", "$rd, $imm20"> ;
def FGW_PS : RVInstRPS<0b0110000, 0b001, OPC_MEM_PS, "fgw.ps">;  // Are these loads?
def FGH_PS : RVInstRPS<0b0101000, 0b001, OPC_MEM_PS, "fgh.ps">;
def FGB_PS : RVInstRPS<0b0100100, 0b001, OPC_MEM_PS, "fgb.ps">;
def FSCW_PS : RVInstR3PS<0b11100, 0b001, OPC_MEM_PS, "fscw.ps">; // Are these stores?
def FSCH_PS : RVInstR3PS<0b11010, 0b001, OPC_MEM_PS, "fsch.ps">;
def FSCB_PS : RVInstR3PS<0b11001, 0b001, OPC_MEM_PS, "fscb.ps">;

def FADD_PS : RVInstRPSrm<0b0000000, OPC_OP_PS, "fadd.ps">;
def FSUB_PS : RVInstRPSrm<0b0000100, OPC_OP_PS, "fsub.ps">;
def FMUL_PS : RVInstRPSrm<0b0001000, OPC_OP_PS, "fmul.ps">;
def FDIV_PS : RVInstRPSrm<0b0001100, OPC_OP_PS, "fdiv.ps">;
def FMIN_PS : RVInstRPS<0b0010100, 0b000, OPC_OP_PS, "fmin.ps">;
def FMAX_PS : RVInstRPS<0b0010100, 0b001, OPC_OP_PS, "fmax.ps">;
def FMADD_PS : RVInstR4PSrm<0b00, OPC_OP3_PS, "fmadd.ps">;
def FMSUB_PS : RVInstR4PSrm<0b01, OPC_OP3_PS, "fmsub.ps">;
def FNMSUB_PS : RVInstR4PSrm<0b10, OPC_OP3_PS, "fnmsub.ps">;
def FNMADD_PS : RVInstR4PSrm<0b11, OPC_OP3_PS, "fnmadd.ps">;
def FCMOV_PS : RVInstE4<0b10, RISCVOpcode<0b0111111>,
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
def FCVT_PS_PWU : RVInstRPSrm2<0b1101000, 1, OPC_OP_PS, "fcvt.ps.pwu">;
def FMVZ_X_PS : RVInstRPSidx<0b1110000, 0b000, OPC_OP_PS, "fmvz.x.ps">;
def FMVS_X_PS : RVInstRPSidx<0b1110000, 0b010, OPC_OP_PS, "fmvs.x.ps">;

def FSGNJN_PS : RVInstRPS<0b0010000, 0b001, OPC_OP_PS, "fsgnjn.ps">;
def FSGNJ_PS  : RVInstRPS<0b0010000, 0b000, OPC_OP_PS, "fsgnj.ps">;
def FSGNJX_PS : RVInstRPS<0b0010000, 0b010, OPC_OP_PS, "fsgnjx.ps">;
def FLE_PS    : RVInstRPS<0b1010000, 0b000, OPC_OP_PS, "fle.ps">;
def FLT_PS    : RVInstRPS<0b1010000, 0b001, OPC_OP_PS, "flt.ps">;
def FEQ_PS    : RVInstRPS<0b1010000, 0b010, OPC_OP_PS, "feq.ps">;

def FLEM_PS   : RVInstRPSM<0b1010000, 0b100, OPC_OP_PS, "flem.ps">;
def FLTM_PS   : RVInstRPSM<0b1010000, 0b101, OPC_OP_PS, "fltm.ps">;
def FEQM_PS   : RVInstRPSM<0b1010000, 0b110, OPC_OP_PS, "feqm.ps">;
        
def FCLASS_PS : PSUnary<0b1110000, 0b00000, 0b001, OPC_OP_PS, "fclass.ps">;

def FCVT_PS_F10  : RVInstRCvtPS<0b01000, 0b000, "fcvt.ps.f10">;
def FCVT_PS_F11  : RVInstRCvtPS<0b01001, 0b000, "fcvt.ps.f11">;
def FCVT_PS_F16  : RVInstRCvtPS<0b01010, 0b000, "fcvt.ps.f16">;
def FCVT_PS_UN24 : RVInstRCvtPS<0b10000, 0b000, "fcvt.ps.un24">;
def FCVT_PS_UN16 : RVInstRCvtPS<0b10001, 0b000, "fcvt.ps.un16">;
def FCVT_PS_UN10 : RVInstRCvtPS<0b10010, 0b000, "fcvt.ps.un10">;
def FCVT_PS_UN8  : RVInstRCvtPS<0b10011, 0b000, "fcvt.ps.un8">;
def FCVT_PS_UN2  : RVInstRCvtPS<0b10111, 0b000, "fcvt.ps.un2">;
def FCVT_PS_SN16 : RVInstRCvtPS<0b11001, 0b000, "fcvt.ps.sn16">;
def FCVT_PS_SN8  : RVInstRCvtPS<0b11011, 0b000, "fcvt.ps.sn8">;
def FCVT_F11_PS  : RVInstRCvtPS<0b01000, 0b000, "fcvt.f11.ps">;
def FCVT_F16_PS  : RVInstRCvtPS<0b01001, 0b000, "fcvt.f16.ps">;
def FCVT_F10_PS  : RVInstRCvtPS<0b01011, 0b000, "fcvt.f10.ps">;
def FCVT_UN24_PS : RVInstRCvtPS<0b10000, 0b000, "fcvt.un24.ps">;
def FCVT_UN16_PS : RVInstRCvtPS<0b10001, 0b000, "fcvt.un16.ps">;
def FCVT_UN10_PS : RVInstRCvtPS<0b10010, 0b000, "fcvt.un10.ps">;
def FCVT_UN8_PS  : RVInstRCvtPS<0b10011, 0b000, "fcvt.un8.ps">;
def FCVT_UN2_PS  : RVInstRCvtPS<0b10111, 0b000, "fcvt.un2.ps">;
def FCVT_SN16_PS : RVInstRCvtPS<0b11001, 0b000, "fcvt.sn16.ps">;
def FCVT_SN8_PS  : RVInstRCvtPS<0b11011, 0b000, "fcvt.sn8.ps">;

def FBCI_PI : RVInstU<OPC_IMM_PI, (outs FPR256:$rd), (ins),
                      "fbci.pi", "$rd">;

def FADD_PI   : RVInstRPS<0b0000011, 0b000, OPC_OP_PS, "fadd.pi">;
def FSUB_PI   : RVInstRPS<0b0000111, 0b000, OPC_OP_PS, "fsub.pi">;
def FMUL_PI   : RVInstRPS<0b0001011, 0b000, OPC_OP_PS, "fmul.pi">;
def FMULH_PI  : RVInstRPS<0b0001011, 0b001, OPC_OP_PS, "fmulh.pi">;
def FMULHU_PI : RVInstRPS<0b0001011, 0b010, OPC_OP_PS, "fmulhu.pi">;
def FDIV_PI   : RVInstRPS<0b0001111, 0b000, OPC_OP_PS, "fdiv.pi">;
def FDIVU_PI  : RVInstRPS<0b0001111, 0b001, OPC_OP_PS, "fdivu.pi">;
def FREM_PI   : RVInstRPS<0b0001111, 0b010, OPC_OP_PS, "frem.pi">;
def FREMU_PI  : RVInstRPS<0b0001111, 0b011, OPC_OP_PS, "fremu.pi">;
def FMIN_PI   : RVInstRPS<0b0010111, 0b000, OPC_OP_PS, "fmin.pi">;
def FMAX_PI   : RVInstRPS<0b0010111, 0b001, OPC_OP_PS, "fmax.pi">;
def FMINU_PI  : RVInstRPS<0b0010111, 0b010, OPC_OP_PS, "fminu.pi">;
def FMAXU_PI  : RVInstRPS<0b0010111, 0b011, OPC_OP_PS, "fmaxu.pi">;

def FLTM_PI : RVInstRPSM<0b0011111, 0b000, OPC_OP_PS, "fltm.pi">;

def FAND_PI : RVInstRPS<0b0000011, 0b111, OPC_OP_PS, "fand.pi">;
def FOR_PI  : RVInstRPS<0b0000011, 0b111, OPC_OP_PS, "for.pi">;
def FNOT_PI : PSUnary<0b0000011, 0b00000, 0b010, OPC_OP_PS, "fnot.pi">;
def FXOR_PI : RVInstRPS<0b0000011, 0b100, OPC_OP_PS, "fxor.pi">;
def FSLL_PI : RVInstRPS<0b0000011, 0b001, OPC_OP_PS, "fsll.pi">;
def FSRL_PI : RVInstRPS<0b0000011, 0b101, OPC_OP_PS, "fsrl.pi">;
def FSRA_PI : RVInstRPS<0b0000111, 0b101, OPC_OP_PS, "fsra.pi">;
def FLE_PI  : RVInstRPS<0b1010011, 0b000, OPC_OP_PS, "fle.pi">;
def FLT_PI  : RVInstRPS<0b1010011, 0b001, OPC_OP_PS, "flt.pi">;
def FEQ_PI  : RVInstRPS<0b1010011, 0b010, OPC_OP_PS, "feq.pi">;
def FLTU_PI : RVInstRPS<0b1010011, 0b011, OPC_OP_PS, "fltu.pi">;

def FSETM_PI : MUnary<0b1010011, 0b00000, 0b100, OPC_OP_PS, "fsetm.pi">;

def FADDI_PI : PSUnaryI<0b000, OPC_IMM10_PI, "faddi.pi">;
def FANDI_PI : PSUnaryI<0b001, OPC_IMM10_PI, "fandi.pi">;

def FSLLI_PI : PSUnaryI5<0b001, OPC_OP_PS, "fslli.pi">;
def FSRLI_PI : PSUnaryI5<0b101, OPC_OP_PS, "fsrli.pi">;
def FSRAI_PI : PSUnaryI5<0b101, OPC_OP_PS, "fsrai.pi">;

def FSIN_PS : PSUnary<0b0101100, 0b00110, 0b000, OPC_OP_PS, "fsin.ps">;
def FEXP_PS : PSUnary<0b0101100, 0b00100, 0b000, OPC_OP_PS, "fexp.ps">;
def FLOG_PS : PSUnary<0b0101100, 0b00011, 0b000, OPC_OP_PS, "flog.ps">;
def FFRC_PS : PSUnary<0b0101100, 0b00010, 0b000, OPC_OP_PS, "ffrc.ps">;
def FROUND_PS : RVInstE7<OPC_OP_PS,
                         (outs FPR256:$rd),
                         (ins FPR256:$rs1, frmarg:$rm),
                          "fround.ps", "$rs1, $rm">;
def FSQRT_PS : PSUnary<0b0101100, 0b00000, 0b000, OPC_OP_PS, "fsqrt.ps">;
def FRCP_PS  : PSUnary<0b0101100, 0b00111, 0b000, OPC_OP_PS, "frcp.ps">;
def FRSQ_PS  : PSUnary<0b0101100, 0b01000, 0b000, OPC_OP_PS, "frsq.ps">;

def CUBEFACE_PS    : RVInstRPS<0b1000100, 0b000, OPC_OP_PS, "cubeface.ps">;
def CUBEFACEIDX_PS : RVInstRPS<0b1000100, 0b001, OPC_OP_PS, "cubefaceidx.ps">;
def CUBESGNSC_PS   : RVInstRPS<0b1000100, 0b010, OPC_OP_PS, "cubesgnsc.ps">;
def CUBESGNTC_PS   : RVInstRPS<0b1000100, 0b011, OPC_OP_PS, "cubesgntc.ps">;

def PACKB    : ALUW_rr<0b1000000, 0b110, "packb">;
def BITMIXB  : ALUW_rr<0b1000000, 0b111, "bitmixb">;

def MOV_M_X : RVInstE8<OPC_OP_PS,
                     (outs MR:$rd),
                     (ins GPR:$rs1, simm12:$imm), // TODO simm8
                     "mov.m.x", "$rs1, $imm">;
def MOVA_X_M : RVInstR<0b1101011, 0b001, OPC_OP_PS,
                     (outs GPR:$rd),
                     (ins),
                     "mova.x.m", "$rd"> {
    let rs1 = 0;
    let rs2 = 0;
}


def MASKAND : MBinary<0b111, "maskand">;
def MASKOR  : MBinary<0b110, "maskor">;
def MASKNOT : RVInstE9<0b010, OPC_OP_PS, (outs MR:$rd),
             (ins MR:$rs1), "masknot", "$rd, $rs1"> { let rs2 = 0; }
def MASKXOR  : MBinary<0b100, "maskxor">;

def MASKPOPC : PopInst<0b01,"maskpopc">;
def MASKPOPZ : PopInst<0b10,"maskpopz">;
def MASKPOPC_RAST : RVInstE11<OPC_OP_PS, (outs MR:$rd),
             (ins GPR:$rs1, MR:$rs2, uimm5:$imm), // TODO uimm4?
             "maskpopc.rast", "$rd, $rs1, $rs2, $imm">;

def FPACKREPB_PI :
       PSUnary<0b0010011, 0b00000, 0b000, OPC_OP_PS, "fpackrepb.pi">;
def FPACKREPH_PI :
       PSUnary<0b0010011, 0b00000, 0b001, OPC_OP_PS, "fpackreph.pi">;

// Load?
def FG32W_PS : RVInstRPS<0b0010000, 0b001, OPC_MEM_PS, "fg32w.ps">; 
def FG32H_PS : RVInstRPS<0b0001000, 0b001, OPC_MEM_PS, "fg32h.ps">; 
def FG32B_PS : RVInstRPS<0b0000100, 0b001, OPC_MEM_PS, "fg32b.ps">; 

// Are these stores?
def FSC32W_PS : RVInstR3PS<0b10100, 0b001, OPC_MEM_PS, "fsc32w.ps">;
def FSC32H_PS : RVInstR3PS<0b10010, 0b001, OPC_MEM_PS, "fsc32h.ps">;
def FSC32B_PS : RVInstR3PS<0b10001, 0b001, OPC_MEM_PS, "fsc32b.ps">;


def FCMOVM_PS : RVInstRPS<0b0000000, 0b000, OPC_CVT_PS, "fcmovm.ps">;
def FRCP_FIX_RAST : RVInstRPS<0b0011000, 0b000, OPC_CVT_PS, "frcp_fix.rast">;
def FCVT_RAST_PS : PSUnary<0b1100000,0b00010,0b000, OPC_CVT_PS, "fcvt.rast.ps">;
def FCVT_PS_RAST : PSUnary<0b1101000, 0b00010, 0b000, OPC_CVT_PS, "fcvt.ps.rast">;
def FSAT8_PI : PSUnary<0b0000011, 0b00000, 0b011, OPC_CVT_PS, "fsat8.pi">;
def FSATU8_PI : PSUnary<0b0000011, 0b00001, 0b011, OPC_CVT_PS, "fsatu8.pi">;
def FLWL_PS : RVInstR<0b0001000,0b111,OPC_MEM_PS,
                      (outs FPR256:$rd), (ins GPR:$rs1),
                      "flwl.ps", "$rd, (${rs1})"> { let rs2 = 0; let mayLoad = 1; }
def FSWL_PS : RVInstR<0b0101000,0b111,OPC_MEM_PS,
                      (outs), (ins FPR256:$rs1, GPR:$rs2),
                      "fswl.ps", "$rs1, (${rs2})"> { let mayStore = 1; }
def FGBL_PS : PSGlobalL<0b1000000, 0b111, "fgbl.ps">;
def FGHL_PS : PSGlobalL<0b1000100, 0b111, "fghl.ps">;
def FGWL_PS : PSGlobalL<0b1001000, 0b111, "fgwl.ps">;

def FSCBL_PS : PSGlobalS<0b1100000, 0b111, "fscbl.ps">;
def FSCHL_PS : PSGlobalS<0b1100100, 0b111, "fschl.ps">;
def FSCWL_PS : PSGlobalS<0b1101000, 0b111, "fscwl.ps">;

def FLWG_PS : RVInstR<0b0001001, 0b111, OPC_MEM_PS, (outs FPR256:$rd),
           (ins GPR:$rs1), "flwg.ps", "(${rs1})"> { let rs2 = 0; let mayLoad = 1; }
           
def FSWG_PS : RVInstR<0b0101001, 0b111, OPC_MEM_PS, (outs),
           (ins FPR256:$rs1, GPR:$rs2), "fswg.ps", "${rs1}, (${rs2})"> { let mayStore = 1; }

def FGBG_PS : PSGlobalL<0b1000001, 0b111, "fgbg.ps">; // verify these are loads
def FGHG_PS : PSGlobalL<0b1001001, 0b111, "fghg.ps">;
def FGWG_PS : PSGlobalL<0b1010001, 0b111, "fgwg.ps">;

let mayStore = 1 in {
def FSCBG_PS : PSGlobalS<0b1100001, 0b111, "fscbg.ps">;
def FSCHG_PS : PSGlobalS<0b1100101, 0b111, "fschg.ps">;
def FSCWG_PS : PSGlobalS<0b1101001, 0b111, "fscwg.ps">;
}

let mayLoad = 1, mayStore =1 in {
def FAMOADDL_PI  : PSGlobalL<0b0000011, 0b100, "famoaddl.pi">;
def FAMOSWAPL_PI : PSGlobalL<0b0000111, 0b100, "famoswapl.pi">;
def FAMOANDL_PI  : PSGlobalL<0b0001011, 0b100, "famoandl.pi">;
def FAMOORL_PI   : PSGlobalL<0b0001111, 0b100, "famoorl.pi">;
def FAMOXORL_PI  : PSGlobalL<0b0010011, 0b100, "famoxorl.pi">;
def FAMOMINL_PI  : PSGlobalL<0b0010111, 0b100, "famominl.pi">;
def FAMOMAXL_PI  : PSGlobalL<0b0011011, 0b100, "famomaxl.pi">;
def FAMOMINUL_PI : PSGlobalL<0b0011111, 0b100, "famominul.pi">;
def FAMOMAXUL_PI : PSGlobalL<0b0100011, 0b100, "famomaxul.pi">;
def FAMOMINL_PS  : PSGlobalL<0b0010100, 0b100, "famominl.ps">;
def FAMOMAXL_PS  : PSGlobalL<0b0011000, 0b100, "famomaxl.ps">;

def FAMOADDG_PI  : PSGlobalL<0b1000011, 0b100, "famoaddg.pi">;
def FAMOSWAPG_PI : PSGlobalL<0b1000111, 0b100, "famoswapg.pi">;
def FAMOANDG_PI  : PSGlobalL<0b1001011, 0b100, "famoandg.pi">;
def FAMOORG_PI   : PSGlobalL<0b1001111, 0b100, "famoorg.pi">;
def FAMOXORG_PI  : PSGlobalL<0b1010011, 0b100, "famoxorg.pi">;
def FAMOMING_PI  : PSGlobalL<0b1010111, 0b100, "famoming.pi">;
def FAMOMAXG_PI  : PSGlobalL<0b1011011, 0b100, "famomaxg.pi">;
def FAMOMINUG_PI : PSGlobalL<0b1011111, 0b100, "famominug.pi">;
def FAMOMAXUG_PI : PSGlobalL<0b1100011, 0b100, "famomaxug.pi">;
def FAMOMING_PS  : PSGlobalL<0b1010100, 0b100, "famoming.ps">;
def FAMOMAXG_PS  : PSGlobalL<0b1011000, 0b100, "famomaxg.ps">;

def AMOSWAPL_W : EGlobalL<0b0000100, 0b010, "amoswapl.w">;
def AMOADDL_W  : EGlobalL<0b0000000, 0b010, "amoaddl.w">;
def AMOXORL_W  : EGlobalL<0b0010000, 0b010, "amoxorl.w">;
def AMOANDL_W  : EGlobalL<0b0110000, 0b010, "amoandl.w">;
def AMOORL_W   : EGlobalL<0b0100000, 0b010, "amoorl.w">;
def AMOMINL_W  : EGlobalL<0b1000000, 0b010, "amominl.w">;
def AMOMAXL_W  : EGlobalL<0b1010000, 0b010, "amomaxl.w">;
def AMOMINUL_W : EGlobalL<0b1100000, 0b010, "amominul.w">;
def AMOMAXUL_W : EGlobalL<0b1110000, 0b010, "amomaxul.w">;

def AMOSWAPG_W : EGlobalL<0b0000101, 0b010, "amoswapg.w">;
def AMOADDG_W  : EGlobalL<0b0000001, 0b010, "amoaddg.w">;
def AMOXORG_W  : EGlobalL<0b0010001, 0b010, "amoxorg.w">;
def AMOANDG_W  : EGlobalL<0b0110001, 0b010, "amoandg.w">;
def AMOORG_W   : EGlobalL<0b0100001, 0b010, "amoorg.w">;
def AMOMING_W  : EGlobalL<0b1000001, 0b010, "amoming.w">;
def AMOMAXG_W  : EGlobalL<0b1010001, 0b010, "amomaxg.w">;
def AMOMINUG_W : EGlobalL<0b1100001, 0b010, "amominug.w">;
def AMOMAXUG_W : EGlobalL<0b1110001, 0b010, "amomaxug.w">;

def AMOSWAPL_D : EGlobalL<0b0000100, 0b011, "amoswapl.d">;
def AMOADDL_D  : EGlobalL<0b0000000, 0b011, "amoaddl.d">;
def AMOXORL_D  : EGlobalL<0b0010000, 0b011, "amoxorl.d">;
def AMOANDL_D  : EGlobalL<0b0110000, 0b011, "amoandl.d">;
def AMOORL_D   : EGlobalL<0b0100000, 0b011, "amoorl.d">;
def AMOMINL_D  : EGlobalL<0b1000000, 0b011, "amominl.d">;
def AMOMAXL_D  : EGlobalL<0b1010000, 0b011, "amomaxl.d">;
def AMOMINUL_D : EGlobalL<0b1100000, 0b011, "amominul.d">;
def AMOMAXUL_D : EGlobalL<0b1110000, 0b011, "amomaxul.d">;

def AMOSWAPG_D : EGlobalL<0b0000101, 0b011, "amoswapg.d">;
def AMOADDG_D  : EGlobalL<0b0000001, 0b011, "amoaddg.d">;
def AMOXORG_D  : EGlobalL<0b0010001, 0b011, "amoxorg.d">;
def AMOANDG_D  : EGlobalL<0b0110001, 0b011, "amoandg.d">;
def AMOORG_D   : EGlobalL<0b0100001, 0b011, "amoorg.d">;
def AMOMING_D  : EGlobalL<0b1000001, 0b011, "amoming.d">;
def AMOMAXG_D  : EGlobalL<0b1010001, 0b011, "amomaxg.d">;
def AMOMINUG_D : EGlobalL<0b1100001, 0b011, "amominug.d">;
def AMOMAXUG_D : EGlobalL<0b1110001, 0b011, "amomaxug.d">;

} // let mayLoad = 1, mayStore =1 in
let mayLoad = 1, rd = 0 in {
def SBL : EGlobalL<0b0001000, 0b011, "sbl">;
def SHL : EGlobalL<0b0001100, 0b011, "shl">;
def SBG : EGlobalL<0b0001001, 0b011, "sbg">;
def SHG : EGlobalL<0b0001101, 0b011, "shg">;
}

} // let hasSideEffects = 0, mayLoad = 0, mayStore = 0 

  
} // HasEsperanto
                                    
  
