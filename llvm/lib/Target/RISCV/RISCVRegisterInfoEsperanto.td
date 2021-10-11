//===-- RISCVRegisterInfoEsperanto.td -===== Register defs -*- tablegen -*-===//
//
// No copy 
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the register state extensions for
//  Esperanto ET-SOC-1 CPU
//===----------------------------------------------------------------------===//

// floating point registers are extended to 256-bits where the
// scalar register occupy the low 32 bits but clear the high
// bits for both 32-bit and 64-bit floating pointer operations.

let Namespace = "RISCV" in {
// Because RISCVReg256 register have AsmName and AltNames that alias with their
// 32-bit sub-register, RISCVAsmParser will need to coerce a register number
// from a RISCVReg32 to the equivalent RISCVReg256 when appropriate.
class RISCVReg256<RISCVReg32 subreg> : Register<""> {
  let HWEncoding{4-0} = subreg.HWEncoding{4-0};
  let SubRegs = [subreg];
  let SubRegIndices = [sub_32];
  let AsmName = subreg.AsmName;
  let AltNames = subreg.AltNames;
}

let RegAltNameIndices = [ABIRegAltName] in {
  foreach Index = 0-31 in {
    def F#Index#_PS : RISCVReg256<!cast<RISCVReg32>("F"#Index#"_F")>,
      DwarfRegNum<[!add(Index, 32)]>;
  }
}

// The order of registers represents the preferred allocation sequence,
// meaning caller-save regs are listed before callee-save.
def FPR256 : RegisterClass<"RISCV", [v8i32, v8f32],
                                    256, (add
    (sequence "F%u_PS", 0, 7),
    (sequence "F%u_PS", 10, 17),
    (sequence "F%u_PS", 28, 31),
    (sequence "F%u_PS", 8, 9),
    (sequence "F%u_PS", 18, 27)
)> {
  let RegInfos = RegInfoByHwMode<
      [RV32,                 RV64,                   DefaultMode],
      [RegInfo<2563,256,32>, RegInfo<256,256,32>, RegInfo<256,256,32>]>;
}

let RegAltNameIndices = [ABIRegAltName] in {
// Mask registers m0...m7
foreach Index = 0-7 in {
  def M#Index : RISCVReg<Index, "m"#Index, ["m"#Index]>,
                         DwarfRegNum<[!add(Index, 97)]>;
}
}

// Including i64 here is a hack to make handling builtins
// easier. Perhaps we should drop builtin support for
// masks and remove i64 here
def MR : RegisterClass<"RISCV", [i64, v8i1], 8, (add
                       (sequence "M%u", 1, 7), M0)> {
    let Size = 8;
}
def MR0 : RegisterClass<"RISCV", [i64, v8i1], 8, (add M0)> {
    let Size = 8;
}

} // Namespace RISCV
