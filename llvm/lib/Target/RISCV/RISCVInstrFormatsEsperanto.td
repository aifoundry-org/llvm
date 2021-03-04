//===-- RISCVRegisterInfoEsperanto.td -===== Register defs -*- tablegen -*-===//
//
// No copy rights
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the instruction extension formats for
//  Esperanto ET-SOC-1
//===----------------------------------------------------------------------===//

/*
def simm20 : Operand<XLenVT>, ImmLeaf<XLenVT, [{return isInt<20>(Imm);}]> {
  let ParserMatchClass = SImmAsmOperand<20>;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeSImmOperand<20>";
  let MCOperandPredicate = [{
    int64_t Imm;
    if (MCOp.evaluateAsConstantImm(Imm))
      return isInt<20>(Imm);
    return MCOp.isBareSymbolRef();
  }];
  let OperandType = "OPERAND_SIMM20";
  let OperandNamespace = "RISCVOp";
}
*/

def OPC_MEM_PS      : RISCVOpcode<0b0001011>;
def OPC_G_PS        : RISCVOpcode<0b0001011>;
def OPC_OP_IMM_32PS : RISCVOpcode<0b0011111>;
def OPC_OP_PS       : RISCVOpcode<0b1111011>;
def OPC_OP3_PS      : RISCVOpcode<0b1011011>;

// new instruction formats
def InstFormatE1  : InstFormat<18>;
def InstFormatE2  : InstFormat<19>;
def InstFormatE3  : InstFormat<20>;
def InstFormatE4  : InstFormat<21>;
def InstFormatE5  : InstFormat<22>;

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

// Example: FSCW.PS
class RVInstE2<bits<5> funct5,RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE2> {
  bits<5> rd;
  bits<5> rs1;
  bits<5> rs2;

  let Inst{31-27} = funct5;
  let Inst{26-25} = 0b00;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = 0b001;
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
class RVInstRPS<bits<5> funct5, bits<3> funct3, RISCVOpcode opcode,
                string opcodestr> :
         RVInstR<!mul(funct5,4), funct3, opcode,
                 (outs FPR256:$rd),
                 (ins FPR256:$rs1, FPR256:$rs2),
                 opcodestr, "$rd, $rs1, $rs2">;

// Example: FSCW.PS
class RVInstR3PS<bits<5> funct5, bits<3> funct3, RISCVOpcode opcode,
                string opcodestr> :
         RVInstE2<funct5, opcode,
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
                  
