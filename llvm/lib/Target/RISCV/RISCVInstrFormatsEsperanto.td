//===-- RISCVRegisterInfoEsperanto.td -===== Register defs -*- tablegen -*-===//
//
// No copy rights
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the instruction extension formats for
//  Esperanto ET-SOC-1
//===----------------------------------------------------------------------===//

// New instruction formats
def InstFormatE1  : InstFormat<18>;
def InstFormatE2  : InstFormat<19>;

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

