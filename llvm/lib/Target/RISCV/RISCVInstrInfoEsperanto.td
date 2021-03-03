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

def OPC_FLQ2      : RISCVOpcode<0b0000111>;

let Predicates = [HasEsperanto] in {
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def FLQ2 : RVInstI<0b101, OPC_FLQ2, (outs FPR256:$rd),
                                    (ins GPR:$rs1, simm12:$imm12),
                         "flq2", "$rd, ${imm12}(${rs1})">;



} // HasEsperanto
                                    
