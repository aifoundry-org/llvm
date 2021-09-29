
//
// No copy rights
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the instruction extension formats for
//  Esperanto ET-SOC-1
//===----------------------------------------------------------------------===//


def SDT_RISCVBroadcast : SDTypeProfile<1,1, []>;
def et_broadcast : SDNode<"RISCVISD::ET_BROADCAST", SDT_RISCVBroadcast>;

def OPC_MEM_PS      : RISCVOpcode<0b0001011>;
def OPC_IMM_PS      : RISCVOpcode<0b0011111>;
def OPC_IMM10_PI    : RISCVOpcode<0b0111111>;
def OPC_OP3_PS      : RISCVOpcode<0b1011011>;
def OPC_IMM_PI      : RISCVOpcode<0b1011111>;
def OPC_CVT_PS      : RISCVOpcode<0b1110111>;
def OPC_OP_PS       : RISCVOpcode<0b1111011>;

// new instruction formats (this don't appear to
// be used anywhere so are not tested in any way)
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
def InstFormatE12  : InstFormat<29>;
def InstFormatE13  : InstFormat<30>;
def InstFormatE14  : InstFormat<31>;

// Optional floating point rounding modes
def OFRMArg : AsmOperandClass {
  let Name = "OFRMArg";
  let IsOptional = 1;
  let RenderMethod = "addFRMArgOperands";
  let DiagnosticType = "InvalidFRMArg";
}

def ofrmarg : Operand<XLenVT>, ImmLeaf<XLenVT, [{return isUInt<3>(Imm);}]> {
  let ParserMatchClass = OFRMArg;
  let PrintMethod = "printFRMArg";
  let DecoderMethod = "decodeFRMArg";
}

def uimm3 : Operand<XLenVT>, ImmLeaf<XLenVT, [{return isUInt<3>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<3>;
  let DecoderMethod = "decodeUImmOperand<3>";
  let OperandType = "OPERAND_UIMM3";
  let OperandNamespace = "RISCVOp";
}

def uimm4 : Operand<XLenVT>, ImmLeaf<XLenVT, [{return isUInt<4>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<4>;
  let DecoderMethod = "decodeUImmOperand<4>";
  let OperandType = "OPERAND_UIMM4";
  let OperandNamespace = "RISCVOp";
}

def uimm8 : Operand<XLenVT>, ImmLeaf<XLenVT, [{return isUInt<8>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<8>;
  let DecoderMethod = "decodeUImmOperand<8>";
  let OperandType = "OPERAND_UIMM8";
  let OperandNamespace = "RISCVOp";
}

def simm10 : Operand<XLenVT>, ImmLeaf<XLenVT, [{return isInt<10>(Imm);}]> {
  let ParserMatchClass = SImmAsmOperand<10>;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeSImmOperand<10>";
  let MCOperandPredicate = [{
    int64_t Imm;
    if (MCOp.evaluateAsConstantImm(Imm))
      return isInt<10>(Imm);
    return MCOp.isBareSymbolRef();
  }];
  let OperandType = "OPERAND_SIMM10";
  let OperandNamespace = "RISCVOp";
}

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

def uimm20 : UImm20Operand, ImmLeaf<XLenVT, [{return isUInt<20>(Imm);}]>{
  let ParserMatchClass = UImmAsmOperand<20, "LUI">;
}
def imm32 : Operand<i64>, PatLeaf<(i32 imm), [{ return true;}]> ;

// Transforms used for converting intrinsics to machine instructions
def LO3   : SDNodeXForm<imm, [{ return transform_LO<3>(N); }]>;
def LO4   : SDNodeXForm<imm, [{ return transform_LO<4>(N); }]>;
def LO5   : SDNodeXForm<imm, [{ return transform_LO<5>(N); }]>;
def LO8   : SDNodeXForm<imm, [{ return transform_LO<8>(N); }]>;
def LO10s : SDNodeXForm<imm, [{ return transform_LOs<10>(N); }]>;
def LO12s : SDNodeXForm<imm, [{ return transform_LOs<12>(N); }]>;
def LO20  : SDNodeXForm<imm, [{ return transform_LO<20>(N); }]>;
def LO20s  : SDNodeXForm<imm, [{ return transform_LOs<20>(N); }]>;


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

  let Inst{31-25} = 0b0110011;
  let Inst{24-23} = 0b00;
  let Inst{22-20} = rs2;
  let Inst{19-18} = 0b00;
  let Inst{17-15} = rs1;
  let Inst{14-12} = funct3;
  let Inst{11-10} = 0b00;
  let Inst{9-7} = rd;
  let Opcode = opcode.Value;
}

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

// Example: FSCW.PS
class RVInstE12<bits<7> funct7,bits<3> funct3,
              RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE12> {
  bits<5> rs1;
  bits<5> rs2;
  bits<5> rs3;

  let Inst{31-25} = funct7;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = funct3;
  let Inst{11-7} = rs3;
  let Opcode = opcode.Value;
}

// Example: SBG
class RVInstE13<bits<7> funct7,bits<3> funct3,
              RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE13> {
  bits<5> rs1;
  bits<5> rs2;

  let Inst{31-25} = funct7;
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = funct3;
  let Inst{11-7} = 0b00000;
  let Opcode = opcode.Value;
}

// Example: FSWL.PS
class RVInstE14<bits<7> funct7,bits<3> funct3, RISCVOpcode opcode, dag outs, dag ins,
              string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatE14> {
  bits<5> rs2;
  bits<5> rs1;

  let Inst{31-25} = funct7;
  let Inst{24-20} = 0b00000;
  let Inst{19-15} = rs1;
  let Inst{14-12} = funct3;
  let Inst{11-7} = rs2;
  let Opcode = opcode.Value;
}


