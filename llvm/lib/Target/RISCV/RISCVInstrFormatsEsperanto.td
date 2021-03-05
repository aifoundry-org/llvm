
//
// No copy rights
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the instruction extension formats for
//  Esperanto ET-SOC-1
//===----------------------------------------------------------------------===//

def OPC_MEM_PS      : RISCVOpcode<0b0001011>;
def OPC_IMM_PS      : RISCVOpcode<0b0011111>;
def OPC_IMM10_PI    : RISCVOpcode<0b0111111>;
def OPC_OP3_PS      : RISCVOpcode<0b1011011>;
def OPC_IMM_PI      : RISCVOpcode<0b1011111>;
def OPC_CVT_PS      : RISCVOpcode<0b1110111>;
def OPC_OP_PS       : RISCVOpcode<0b1111011>;

// new instruction formats
def InstFormatE1  : InstFormat<18>;
def InstFormatE2  : InstFormat<19>;
def InstFormatE3  : InstFormat<20>;
def InstFormatE4  : InstFormat<21>;
def InstFormatE5  : InstFormat<22>;
def InstFormatE6  : InstFormat<23>;
def InstFormatE7  : InstFormat<24>;
def InstFormatE8  : InstFormat<25>;
def InstFormatE9  : InstFormat<26>;
def InstFormatE10  : InstFormat<27>;
def InstFormatE11  : InstFormat<28>;

// Example: FSWIZZ.PS
class RVInstE1<bits<7> funct7,RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE1> {
  bits<5> rd;
  bits<5> rs1;
  bits<8> imm;

  let Inst{31-25} = funct7;
  let Inst{24-20} = imm{7-3};
  let Inst{19-15} = rs1;
  let Inst{14-12} = imm{2-0};
  let Inst{11-7} = rd;
  let Opcode = opcode.Value;
}

// Example: FADDI.PS
class RVInstE2<bits<3> funct3,RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE3> {
  bits<10> imm;
  bits<5> rs1;
  bits<5> rd;

  let Inst{31-27} = imm{9-5};
  let Inst{26-25} = 0b10;
  let Inst{24-20} = imm{4-0};
  let Inst{19-15} = rs1;
  let Inst{14-12} = funct3;
  let Inst{11-7} = rd;
  let Opcode = opcode.Value;
}

// Example: FSLLI.PS
class RVInstE6<bits<3> funct3,RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE6> {
  bits<5> imm;
  bits<5> rs1;
  bits<5> rd;

  let Inst{31-25} = 0b0100111;
  let Inst{24-20} = imm;
  let Inst{19-15} = rs1;
  let Inst{14-12} = funct3;
  let Inst{11-7} = rd;
  let Opcode = opcode.Value;
}


// Example: FADD.PS
class RVInstE3<bits<7> funct7,RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE3> {
  bits<5> rd;
  bits<5> rs1;
  bits<5> rs2;
  bits<3> rm;

  let Inst{31-25} = funct7;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = rm;
  let Inst{11-7} = rd;
  let Opcode = opcode.Value;
}

// Example: FMADD.PS
class RVInstE4<bits<2> funct2,RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE4> {
  bits<5> rd;
  bits<5> rs1;
  bits<5> rs2;
  bits<5> rs3;
  bits<3> rm;

  let Inst{31-27} = rs3;
  let Inst{26-25} = funct2;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = rm;
  let Inst{11-7} = rd;
  let Opcode = opcode.Value;
}


// Example: FMVZ.X.PS
class RVInstE5<bits<7> funct7,bits<3> funct3,
              RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE5> {
  bits<5> rd;
  bits<5> rs1;
  bits<3> idx;

  let Inst{31-25} = funct7;
  let Inst{24-23} = 0;
  let Inst{22-20} = idx;
  let Inst{19-15} = rs1;
  let Inst{14-12} = funct3;
  let Inst{11-7} = rd;
  let Opcode = opcode.Value;
}

// Example: FGW.PS
class RVInstRPS<bits<7> funct7, bits<3> funct3, RISCVOpcode opcode,
                string opcodestr> :
         RVInstR<funct7, funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2),
                 opcodestr, "$rd, $rs1, $rs2">;

// Example: FSCW.PS
class RVInstR3PS<bits<5> funct5, bits<3> funct3, RISCVOpcode opcode,
                string opcodestr> :
         RVInstR<!mul(funct5,4), funct3, opcode,
                 (outs),
                 (ins FPR256:$rs1, FPR256:$rs2, FPR256:$rs3),
                 opcodestr, "$rs1, $rs2, $rs3">;

// Example FADD.PS
class RVInstRPSrm<bits<7> funct7, RISCVOpcode opcode,
                  string opcodestr> :
         RVInstE3<funct7, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2, frmarg:$rm),
                 opcodestr, "$rd, $rs1, $rs2, $rm">;

// Example: FMADD.PS
class RVInstR4PSrm<bits<2> funct2, RISCVOpcode opcode,
                string opcodestr> :
         RVInstE4<funct2, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2, FPR256:$rs3, frmarg:$rm),
                 opcodestr, "$rd, $rs1, $rs2, $rs3, $rm">;

// Example: FCVT.pW.pS
class RVInstRPSrm2<bits<7> funct7, bits<5> funct1, RISCVOpcode opcode,
                  string opcodestr> :
         RVInstE3<funct7, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1,frmarg:$rm),
                 opcodestr, "$rd, $rs1, $rm"> {
    let rs2 = funct1;
}

// TODO -- verify register classes
class RVInstRPSidx<bits<7> funct7, bits<3> funct3, RISCVOpcode opcode,
                  string opcodestr> :
         RVInstE5<funct7, funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, uimm5:$idx), // TODO -- uimm3
                 opcodestr, "$rd, $rs1, $idx">;
                  
// Example: FLEM.PS
class RVInstRPSM<bits<7> funct7, bits<3> funct3, RISCVOpcode opcode,
                string opcodestr> :
         RVInstR<funct7, funct3, opcode,
                 (outs MR:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2),
                 opcodestr, "$rd, $rs1, $rs2">;

// Example: FCLASS.PS
class PSUnary<bits<7> funct7, bits<5> funct5, bits<3> funct3, RISCVOpcode opcode, string opcodestr> :
         RVInstR<funct7, funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1),
                 opcodestr, "$rd, $rs1"> {
    let rs2 = funct5;
}

class PSUnaryI<bits<3> funct3, RISCVOpcode opcode, string opcodestr> :
         RVInstE2<funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, simm12:$imm),  // TODO create simm10
                 opcodestr, "$rd, $rs1, ${imm}">;
                 
class PSUnaryI5<bits<3> funct3, RISCVOpcode opcode, string opcodestr> :
         RVInstE6<funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, uimm5:$imm),  // verify unsigned
                 opcodestr, "$rd, $rs1, ${imm}">;

// Example: FNOT>PI
class MUnary<bits<7> funct7, bits<5> funct5, bits<3> funct3, RISCVOpcode opcode, string opcodestr> :
         RVInstR<funct7, funct3, opcode,
                 (outs MR:$rd),
                 (ins FPR256:$rs1),
                 opcodestr, "$rd, $rs1"> {
    let rs2 = funct5;
}

// Common element for FCVT operations
class RVInstRCvtPS<bits<5> funct5, bits<3> funct3, string opcodestr> :
     PSUnary<0b1101100, funct5, funct3, RISCVOpcode<0b1111011>, opcodestr>;

class PSGlobalL<bits<7> funct7, bits<3> funct3, string opcodestr> :
     RVInstR<funct7, funct3, OPC_MEM_PS, (outs FPR256:$rd),
            (ins GPR:$rs1, GPR:$rs2), opcodestr,
            "${rs1}, ${rs2}"> { let mayLoad = 1; } // TODO: check syntax
class PSGlobalS<bits<7> funct7, bits<3> funct3, string opcodestr> :
     RVInstR<funct7, funct3, OPC_MEM_PS, (outs),
            (ins FPR256:$rs1, GPR:$rs2, GPR:$rs3), opcodestr,
            "${rs1}, ${rs2}, ${rs3}"> { let mayStore = 1; } // TODO: check syntax

class EGlobalL<bits<7> funct7, bits<3> funct3, string opcodestr> :
     RVInstR<funct7, funct3, OPC_OP_32, (outs GPR:$rd),
            (ins GPR:$rs1, GPR:$rs2), opcodestr,
            "${rs1}, ${rs2}"> { let mayLoad = 1; } // TODO: check syntax

// Example: FROUND.P
class RVInstE7<RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE7> {
  bits<5> rs1;
  bits<3> rm;
  bits<5> rd;

  let Inst{31-20} = 0b010110000001;
  let Inst{19-15} = rs1;
  let Inst{14-12} = rm;
  let Inst{11-7} = rd;
  let Opcode = opcode.Value;
}

// Example: MOV.M.X
class RVInstE8<RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE8> {
  bits<8> imm;
  bits<5> rs1;
  bits<3> rd;

  let Inst{31-25} = 0b0101011;
  let Inst{24-20} = imm{7-3};
  let Inst{19-15} = rs1;
  let Inst{14-12} = imm{2-0};
  let Inst{11-10} = 0b00;
  let Inst{9-7} = rd;
  let Opcode = opcode.Value;
}

// Example: MASKAND
class RVInstE9<bits<3> funct3, RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE9> {
  bits<3> rs2;
  bits<3> rs1;
  bits<3> rd;

  let Inst{31-25} = 0b0101111;
  let Inst{24-23} = 0b00;
  let Inst{22-20} = rs2;
  let Inst{19-18} = 0b00;
  let Inst{17-15} = rs1;
  let Inst{14-12} = funct3;
  let Inst{11-10} = 0b00;
  let Inst{9-7} = rd;
  let Opcode = opcode.Value;
}

class MBinary<bits<3> funct3, string codestr> :
    RVInstE9<funct3, OPC_OP_PS, (outs MR:$rd),
             (ins MR:$rs1, MR:$rs2), codestr, "$rd, $rs1, $rs2">;

// Example: MASKPOPC
class RVInstE10<bits<2> funct2, RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE10> {
  bits<3> rs1;
  bits<5> rd;

  let Inst{31-27} = 0b01010;
  let Inst{26-25} = funct2;
  let Inst{24-18} = 0b0000000;
  let Inst{17-15} = rs1;
  let Inst{14-12} = 0b000;
  let Inst{11-7} = rd;
  let Opcode = opcode.Value;
}

class PopInst<bits<2> funct2, string opcodestr> :
      RVInstE10<funct2, OPC_OP_PS, (outs GPR:$rd), (ins MR:$rs1),
                opcodestr, "$rd, $rs1">;

// Example: MASKPOPC.RAST
class RVInstE11<RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE11> {
  bits<4> imm;
  bits<3> rs2;
  bits<3> rs1;
  bits<5> rd;

  let Inst{31-25} = 0b0101111;
  let Inst{24-23} = imm{3-2};
  let Inst{22-20} = rs2;
  let Inst{19-18} = imm{1-0};
  let Inst{17-15} = rs1;
  let Inst{14-12} = 0b000;
  let Inst{11-7} = rd;
  let Opcode = opcode.Value;
}

