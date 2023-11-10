# XETsimd - Esperanto Technologies SIMD instructions

# RUN: llvm-mc --arch=riscv64 -mcpu=et-soc1-min --show-encoding %s | FileCheck -check-prefixes=CHECK-ENC,CHECK-INST %s

# CHECK-INST: bitmixb	s7, gp, gp
# CHECK-ENC: encoding: [0xbb,0xfb,0x31,0x80]
bitmixb	s7, gp, gp

# CHECK-INST: cubefaceidx.ps	fa0, fs9, ft9
# CHECK-ENC: encoding: [0x7b,0x95,0xdc,0x89]
cubefaceidx.ps	fa0, fs9, ft9

# CHECK-INST: cubeface.ps	ft9, fa3, ft10
# CHECK-ENC: encoding: [0xfb,0x8e,0xe6,0x89]
cubeface.ps	ft9, fa3, ft10

# CHECK-INST: cubesgnsc.ps	ft9, ft8, fs9
# CHECK-ENC: encoding: [0xfb,0x2e,0x9e,0x89]
cubesgnsc.ps	ft9, ft8, fs9

# CHECK-INST: cubesgntc.ps	fs2, ft6, fa6
# CHECK-ENC: encoding: [0x7b,0x39,0x03,0x89]
cubesgntc.ps	fs2, ft6, fa6

#====----------------------------------------------------------------------===//
# SIMD FP|INT instructions
#====----------------------------------------------------------------------===//

# CHECK-INST: faddi.pi	fa4, ft1, -96
# CHECK-ENC: encoding: [0x3f,0x87,0x00,0xec]
faddi.pi	fa4, ft1, -96

# CHECK-INST: fadd.pi	fs10, fa5, fs8
# CHECK-ENC: encoding: [0x7b,0x8d,0x87,0x07]
fadd.pi	fs10, fa5, fs8

# CHECK-INST: fadd.ps	fs0, ft0, fs4, rtz
# CHECK-ENC: encoding: [0x7b,0x14,0x40,0x01]
fadd.ps	fs0, ft0, fs4, rtz

# CHECK-INST: fandi.pi	fa7, fs1, 16
# CHECK-ENC: encoding: [0xbf,0x98,0x04,0x05]
fandi.pi	fa7, fs1, 16

# CHECK-INST: fand.pi	ft2, fs8, fa1
# CHECK-ENC: encoding: [0x7b,0x71,0xbc,0x06]
fand.pi	ft2, fs8, fa1

# CHECK-INST: fbci.pi	fs9, 1015523
# CHECK-ENC: encoding: [0xdf,0x3c,0xee,0xf7]
fbci.pi	fs9, 1015523

# CHECK-INST: fbci.ps	fs9, 946477
# CHECK-ENC: encoding: [0x9f,0xdc,0x12,0xe7]
fbci.ps	fs9, 946477

# CHECK-INST: fbcx.ps	fa3, s3
# CHECK-ENC: encoding: [0x8b,0xb6,0x09,0x00]
fbcx.ps	fa3, s3

# CHECK-INST: fbc.ps	fs0, 1529(s9)
# CHECK-ENC: encoding: [0x0b,0x84,0x9c,0x5f]
fbc.ps	fs0, 1529(s9)

# CHECK-INST: fclass.ps	fs0, fs8
# CHECK-ENC: encoding: [0x7b,0x14,0x0c,0xe0]
fclass.ps	fs0, fs8

# CHECK-INST: fcmovm.ps	ft5, fa7, fs6
# CHECK-ENC: encoding: [0xf7,0x82,0x68,0x01]
fcmovm.ps	ft5, fa7, fs6

# CHECK-INST: fcmov.ps	fs11, ft1, ft8, fa1
# CHECK-ENC: encoding: [0xbf,0xad,0xc0,0x5d]
fcmov.ps	fs11, ft1, ft8, fa1

# CHECK-INST: fcvt.f10.ps	fa2, ft1
# CHECK-ENC: encoding: [0x7b,0x86,0xb0,0xd8]
fcvt.f10.ps	fa2, ft1

# CHECK-INST: fcvt.f11.ps	fa0, ft4
# CHECK-ENC: encoding: [0x7b,0x05,0x82,0xd8]
fcvt.f11.ps	fa0, ft4

# CHECK-INST: fcvt.f16.ps	ft1, fa2
# CHECK-ENC: encoding: [0xfb,0x00,0x96,0xd8]
fcvt.f16.ps	ft1, fa2

# CHECK-INST: fcvt.ps.f10	ft5, fa0
# CHECK-ENC: encoding: [0xfb,0x02,0x85,0xd0]
fcvt.ps.f10	ft5, fa0

# CHECK-INST: fcvt.ps.f11	fa0, fa6
# CHECK-ENC: encoding: [0x7b,0x05,0x98,0xd0]
fcvt.ps.f11	fa0, fa6

# CHECK-INST: fcvt.ps.f16	fa4, fs0
# CHECK-ENC: encoding: [0x7b,0x07,0xa4,0xd0]
fcvt.ps.f16	fa4, fs0

# CHECK-INST: fcvt.ps.pw	fs0, ft1, rtz
# CHECK-ENC: encoding: [0x7b,0x94,0x00,0xd0]
fcvt.ps.pw	fs0, ft1, rtz

# CHECK-INST: fcvt.ps.pwu	ft8, ft0, rtz
# CHECK-ENC: encoding: [0x7b,0x1e,0x10,0xd0]
fcvt.ps.pwu	ft8, ft0, rtz

# CHECK-INST: fcvt.ps.rast	ft7, fa0
# CHECK-ENC: encoding: [0xfb,0x03,0x25,0xd0]
fcvt.ps.rast	ft7, fa0

# CHECK-INST: fcvt.ps.sn16	ft11, fa2
# CHECK-ENC: encoding: [0xfb,0x0f,0x96,0xd1]
fcvt.ps.sn16	ft11, fa2

# CHECK-INST: fcvt.ps.sn8	fs1, ft2
# CHECK-ENC: encoding: [0xfb,0x04,0xb1,0xd1]
fcvt.ps.sn8	fs1, ft2

# CHECK-INST: fcvt.ps.un10	fs0, fs11
# CHECK-ENC: encoding: [0x7b,0x84,0x2d,0xd1]
fcvt.ps.un10	fs0, fs11

# CHECK-INST: fcvt.ps.un16	fa7, ft5
# CHECK-ENC: encoding: [0xfb,0x88,0x12,0xd1]
fcvt.ps.un16	fa7, ft5

# CHECK-INST: fcvt.ps.un2	fs0, fa7
# CHECK-ENC: encoding: [0x7b,0x84,0x78,0xd1]
fcvt.ps.un2	fs0, fa7

# CHECK-INST: fcvt.ps.un24	ft6, ft1
# CHECK-ENC: encoding: [0x7b,0x83,0x00,0xd1]
fcvt.ps.un24	ft6, ft1

# CHECK-INST: fcvt.ps.un8	fa3, fa4
# CHECK-ENC: encoding: [0xfb,0x06,0x37,0xd1]
fcvt.ps.un8	fa3, fa4

# CHECK-INST: fcvt.pwu.ps	ft10, ft1, rup
# CHECK-ENC: encoding: [0x7b,0xbf,0x10,0xc0]
fcvt.pwu.ps	ft10, ft1, rup

# CHECK-INST: fcvt.pw.ps	fs6, ft5, rup
# CHECK-ENC: encoding: [0x7b,0xbb,0x02,0xc0]
fcvt.pw.ps	fs6, ft5, rup

# CHECK-INST: fcvt.rast.ps	ft11, fs7
# CHECK-ENC: encoding: [0xfb,0x8f,0x2b,0xc0]
fcvt.rast.ps	ft11, fs7

# CHECK-INST: fcvt.sn16.ps	ft1, fs7
# CHECK-ENC: encoding: [0xfb,0x80,0x9b,0xd9]
fcvt.sn16.ps	ft1, fs7

# CHECK-INST: fcvt.sn8.ps	fs3, ft5
# CHECK-ENC: encoding: [0xfb,0x89,0xb2,0xd9]
fcvt.sn8.ps	fs3, ft5

# CHECK-INST: fcvt.un10.ps	ft5, fa6
# CHECK-ENC: encoding: [0xfb,0x02,0x28,0xd9]
fcvt.un10.ps	ft5, fa6

# CHECK-INST: fcvt.un16.ps	fs9, ft6
# CHECK-ENC: encoding: [0xfb,0x0c,0x13,0xd9]
fcvt.un16.ps	fs9, ft6

# CHECK-INST: fcvt.un24.ps	fs8, ft8
# CHECK-ENC: encoding: [0x7b,0x0c,0x0e,0xd9]
fcvt.un24.ps	fs8, ft8

# CHECK-INST: fcvt.un2.ps	fa0, fa3
# CHECK-ENC: encoding: [0x7b,0x85,0x76,0xd9]
fcvt.un2.ps	fa0, fa3

# CHECK-INST: fcvt.un8.ps	fa0, ft2
# CHECK-ENC: encoding: [0x7b,0x05,0x31,0xd9]
fcvt.un8.ps	fa0, ft2

# CHECK-INST: fdivu.pi	fa1, fa5, fa2
# CHECK-ENC: encoding: [0xfb,0x95,0xc7,0x1e]
fdivu.pi	fa1, fa5, fa2

# CHECK-INST: fdiv.pi	ft3, fa0, fs4
# CHECK-ENC: encoding: [0xfb,0x01,0x45,0x1f]
fdiv.pi	ft3, fa0, fs4

# CHECK-INST: fdiv.ps	fs10, ft5, fs11, rdn
# CHECK-ENC: encoding: [0x7b,0xad,0xb2,0x19]
fdiv.ps	fs10, ft5, fs11, rdn

# CHECK-INST: feqm.ps	m4, ft5, ft8
# CHECK-ENC: encoding: [0x7b,0xe2,0xc2,0xa1]
feqm.ps	m4, ft5, ft8

# CHECK-INST: feq.pi	ft10, fa1, fs0
# CHECK-ENC: encoding: [0x7b,0xaf,0x85,0xa6]
feq.pi	ft10, fa1, fs0

# CHECK-INST: feq.ps	fa5, ft4, fs2
# CHECK-ENC: encoding: [0xfb,0x27,0x22,0xa1]
feq.ps	fa5, ft4, fs2

# CHECK-INST: fexp.ps	fs10, ft3
# CHECK-ENC: encoding: [0x7b,0x8d,0x41,0x58]
fexp.ps	fs10, ft3

# CHECK-INST: flog.ps	fa0, fs10
# CHECK-ENC: encoding: [0x7b,0x05,0x3d,0x58]
flog.ps	fa0, fs10

# CHECK-INST: ffrc.ps	fs9, ft8
# CHECK-ENC: encoding: [0xfb,0x0c,0x2e,0x58]
ffrc.ps	fs9, ft8

# CHECK-INST: fg32b.ps	fa2, a0(s0)
# CHECK-ENC: encoding: [0x0b,0x16,0x85,0x08]
fg32b.ps	fa2, a0(s0)

# CHECK-INST: fg32h.ps	ft10, s6(s9)
# CHECK-ENC: encoding: [0x0b,0x1f,0x9b,0x11]
fg32h.ps	ft10, s6(s9)

# CHECK-INST: fg32w.ps	fs5, ra(a0)
# CHECK-ENC: encoding: [0x8b,0x9a,0xa0,0x20]
fg32w.ps	fs5, ra(a0)

# CHECK-INST: fgb.ps	fs11, ft7(s4)
# CHECK-ENC: encoding: [0x8b,0x9d,0x43,0x49]
fgb.ps	fs11, ft7(s4)

# CHECK-INST: fgh.ps	ft3, ft7(t5)
# CHECK-ENC: encoding: [0x8b,0x91,0xe3,0x51]
fgh.ps	ft3, ft7(t5)

# CHECK-INST: fgw.ps	fs10, fa7(s3)
# CHECK-ENC: encoding: [0x0b,0x9d,0x38,0x61]
fgw.ps	fs10, fa7(s3)

# CHECK-INST: flem.ps	m6, ft4, ft3
# CHECK-ENC: encoding: [0x7b,0x43,0x32,0xa0]
flem.ps	m6, ft4, ft3

# CHECK-INST: fle.pi	ft2, fs3, fa7
# CHECK-ENC: encoding: [0x7b,0x81,0x19,0xa7]
fle.pi	ft2, fs3, fa7

# CHECK-INST: fle.ps	ft9, fs11, fa1
# CHECK-ENC: encoding: [0xfb,0x8e,0xbd,0xa0]
fle.ps	ft9, fs11, fa1

# CHECK-INST: flq2	fa5, -2020(sp)
# CHECK-ENC: encoding: [0x87,0x57,0xc1,0x81]
flq2	fa5, -2020(sp)

# CHECK-INST: fltm.pi	m0, ft3, fs1
# CHECK-ENC: encoding: [0x7b,0x80,0x91,0x3e]
fltm.pi	m0, ft3, fs1

# CHECK-INST: fltm.ps	m6, ft2, fa3
# CHECK-ENC: encoding: [0x7b,0x53,0xd1,0xa0]
fltm.ps	m6, ft2, fa3

# CHECK-INST: fltu.pi	ft5, fa1, fs10
# CHECK-ENC: encoding: [0xfb,0xb2,0xa5,0xa7]
fltu.pi	ft5, fa1, fs10

# CHECK-INST: flt.pi	ft11, fa4, fs8
# CHECK-ENC: encoding: [0xfb,0x1f,0x87,0xa7]
flt.pi	ft11, fa4, fs8

# CHECK-INST: flt.ps	fs11, fs3, fs5
# CHECK-ENC: encoding: [0xfb,0x9d,0x59,0xa1]
flt.ps	fs11, fs3, fs5

# CHECK-INST: flw.ps	ft9, 1224(s5)
# CHECK-ENC: encoding: [0x8b,0xae,0x8a,0x4c]
flw.ps	ft9, 1224(s5)

# CHECK-INST: fmadd.ps	fs0, fs2, ft8, ft8, rmm
# CHECK-ENC: encoding: [0x5b,0x44,0xc9,0xe1]
fmadd.ps	fs0, fs2, ft8, ft8, rmm

# CHECK-INST: fmaxu.pi	ft10, fs3, fs11
# CHECK-ENC: encoding: [0x7b,0xbf,0xb9,0x2f]
fmaxu.pi	ft10, fs3, fs11

# CHECK-INST: fmax.pi	ft3, fs1, fs6
# CHECK-ENC: encoding: [0xfb,0x91,0x64,0x2f]
fmax.pi	ft3, fs1, fs6

# CHECK-INST: fmax.ps	fa0, fs2, ft3
# CHECK-ENC: encoding: [0x7b,0x15,0x39,0x28]
fmax.ps	fa0, fs2, ft3

# CHECK-INST: fminu.pi	ft5, ft2, ft2
# CHECK-ENC: encoding: [0xfb,0x22,0x21,0x2e]
fminu.pi	ft5, ft2, ft2

# CHECK-INST: fmin.pi	fs10, fs10, fs3
# CHECK-ENC: encoding: [0x7b,0x0d,0x3d,0x2f]
fmin.pi	fs10, fs10, fs3

# CHECK-INST: fmin.ps	fa1, ft5, ft5
# CHECK-ENC: encoding: [0xfb,0x85,0x52,0x28]
fmin.ps	fa1, ft5, ft5

# CHECK-INST: fmsub.ps	fs0, fs7, fs6, ft3, rmm
# CHECK-ENC: encoding: [0x5b,0xc4,0x6b,0x1b]
fmsub.ps	fs0, fs7, fs6, ft3, rmm

# CHECK-INST: fmulhu.pi	ft6, fs7, fs4
# CHECK-ENC: encoding: [0x7b,0xa3,0x4b,0x17]
fmulhu.pi	ft6, fs7, fs4

# CHECK-INST: fmulh.pi	fa3, fa3, fs1
# CHECK-ENC: encoding: [0xfb,0x96,0x96,0x16]
fmulh.pi	fa3, fa3, fs1

# CHECK-INST: fmul.pi	ft4, ft7, ft4
# CHECK-ENC: encoding: [0x7b,0x82,0x43,0x16]
fmul.pi	ft4, ft7, ft4

# CHECK-INST: fmul.ps	fa5, fa2, fs10, rtz
# CHECK-ENC: encoding: [0xfb,0x17,0xa6,0x11]
fmul.ps	fa5, fa2, fs10, rtz

# CHECK-INST: fmvs.x.ps	s0, fs0, 6
# CHECK-ENC: encoding: [0x7b,0x24,0x64,0xe0]
fmvs.x.ps	fp, fs0, 6

# CHECK-INST: fmvz.x.ps	a5, ft6, 6
# CHECK-ENC: encoding: [0xfb,0x07,0x63,0xe0]
fmvz.x.ps	a5, ft6, 6

# CHECK-INST: fnmadd.ps	ft10, ft8, fs5, fs3, rdn
# CHECK-ENC: encoding: [0x5b,0x2f,0x5e,0x9f]
fnmadd.ps	ft10, ft8, fs5, fs3, rdn

# CHECK-INST: fnmsub.ps	ft0, ft11, fs7, fa5, rtz
# CHECK-ENC: encoding: [0x5b,0x90,0x7f,0x7d]
fnmsub.ps	ft0, ft11, fs7, fa5, rtz

# CHECK-INST: fnot.pi	fs10, fs6
# CHECK-ENC: encoding: [0x7b,0x2d,0x0b,0x06]
fnot.pi	fs10, fs6

# CHECK-INST: for.pi	ft10, fa0, fa4
# CHECK-ENC: encoding: [0x7b,0x6f,0xe5,0x06]
for.pi	ft10, fa0, fa4

# CHECK-INST: fpackrepb.pi	ft8, fs11
# CHECK-ENC: encoding: [0x7b,0x8e,0x0d,0x26]
fpackrepb.pi	ft8, fs11

# CHECK-INST: fpackreph.pi	ft2, ft10
# CHECK-ENC: encoding: [0x7b,0x11,0x0f,0x26]
fpackreph.pi	ft2, ft10

# CHECK-INST: frcp_fix.rast	ft3, fs0, fa1
# CHECK-ENC: encoding: [0xfb,0x01,0xb4,0x30]
frcp_fix.rast	ft3, fs0, fa1

# CHECK-INST: frcp.ps	ft11, fs2
# CHECK-ENC: encoding: [0xfb,0x0f,0x79,0x58]
frcp.ps	ft11, fs2

# CHECK-INST: fremu.pi	ft4, ft4, ft1
# CHECK-ENC: encoding: [0x7b,0x32,0x12,0x1e]
fremu.pi	ft4, ft4, ft1

# CHECK-INST: frem.pi	fa2, fs10, ft1
# CHECK-ENC: encoding: [0x7b,0x26,0x1d,0x1e]
frem.pi	fa2, fs10, ft1

# CHECK-INST: fround.ps	fa3, fs7, rtz
# CHECK-ENC: encoding: [0xfb,0x96,0x1b,0x58]
fround.ps	fa3, fs7, rtz

# CHECK-INST: frsq.ps	fs1, fs1
# CHECK-ENC: encoding: [0xfb,0x84,0x84,0x58]
frsq.ps	fs1, fs1

# CHECK-INST: fsat8.pi	ft1, fs7
# CHECK-ENC: encoding: [0xfb,0xb0,0x0b,0x06]
fsat8.pi	ft1, fs7

# CHECK-INST: fsatu8.pi	fa1, fa2
# CHECK-ENC: encoding: [0xfb,0x35,0x16,0x06]
fsatu8.pi	fa1, fa2

# CHECK-INST: fsc32b.ps	ft7, gp(s3)
# CHECK-ENC: encoding: [0x8b,0x93,0x31,0x89]
fsc32b.ps	ft7, gp(s3)

# CHECK-INST: fsc32h.ps	fa3, s6(tp)
# CHECK-ENC: encoding: [0x8b,0x16,0x4b,0x90]
fsc32h.ps	fa3, s6(tp)

# CHECK-INST: fsc32w.ps	ft0, t5(a0)
# CHECK-ENC: encoding: [0x0b,0x10,0xaf,0xa0]
fsc32w.ps	ft0, t5(a0)

# CHECK-INST: fscb.ps	ft9, ft1(zero)
# CHECK-ENC: encoding: [0x8b,0x9e,0x00,0xc8]
fscb.ps	ft9, ft1(zero)

# CHECK-INST: fsch.ps	fs2, fa0(t5)
# CHECK-ENC: encoding: [0x0b,0x19,0xe5,0xd1]
fsch.ps	fs2, fa0(t5)

# CHECK-INST: fscw.ps	ft1, ft0(a0)
# CHECK-ENC: encoding: [0x8b,0x10,0xa0,0xe0]
fscw.ps	ft1, ft0(a0)

# CHECK-INST: fsetm.pi	m0, fa5
# CHECK-ENC: encoding: [0x7b,0xc0,0x07,0xa6]
fsetm.pi	m0, fa5

# CHECK-INST: fsgnjn.ps	ft6, fs10, ft2
# CHECK-ENC: encoding: [0x7b,0x13,0x2d,0x20]
fsgnjn.ps	ft6, fs10, ft2

# CHECK-INST: fsgnjx.ps	ft9, fs2, fs0
# CHECK-ENC: encoding: [0xfb,0x2e,0x89,0x20]
fsgnjx.ps	ft9, fs2, fs0

# CHECK-INST: fsgnj.ps	fs3, fa7, ft0
# CHECK-ENC: encoding: [0xfb,0x89,0x08,0x20]
fsgnj.ps	fs3, fa7, ft0

# CHECK-INST: fsin.ps	ft2, ft4
# CHECK-ENC: encoding: [0x7b,0x01,0x62,0x58]
fsin.ps	ft2, ft4

# CHECK-INST: fslli.pi	ft1, fs10, 25
# CHECK-ENC: encoding: [0xfb,0x10,0x9d,0x4f]
fslli.pi	ft1, fs10, 25

# CHECK-INST: fsll.pi	ft3, ft9, fa7
# CHECK-ENC: encoding: [0xfb,0x91,0x1e,0x07]
fsll.pi	ft3, ft9, fa7

# CHECK-INST: fsq2	fa4, -1100(s5)
# CHECK-ENC: encoding: [0x27,0xda,0xea,0xba]
fsq2	fa4, -1100(s5)

# CHECK-INST: fsqrt.ps	ft2, fs11
# CHECK-ENC: encoding: [0x7b,0x81,0x0d,0x58]
fsqrt.ps	ft2, fs11

# CHECK-INST: fsrai.pi	ft1, fs5, 5
# CHECK-ENC: encoding: [0xfb,0xf0,0x5a,0x4e]
fsrai.pi	ft1, fs5, 5

# CHECK-INST: fsra.pi	fs1, ft11, ft2
# CHECK-ENC: encoding: [0xfb,0xd4,0x2f,0x0e]
fsra.pi	fs1, ft11, ft2

# CHECK-INST: fsrli.pi	fs0, fa4, 5
# CHECK-ENC: encoding: [0x7b,0x54,0x57,0x4e]
fsrli.pi	fs0, fa4, 5

# CHECK-INST: fsrl.pi	fa2, fs0, fa4
# CHECK-ENC: encoding: [0x7b,0x56,0xe4,0x06]
fsrl.pi	fa2, fs0, fa4

# CHECK-INST: fsub.pi	ft0, ft10, ft9
# CHECK-ENC: encoding: [0x7b,0x00,0xdf,0x0f]
fsub.pi	ft0, ft10, ft9

# CHECK-INST: fsub.ps	ft2, ft2, fs8, dyn
# CHECK-ENC: encoding: [0x7b,0x71,0x81,0x09]
fsub.ps	ft2, ft2, fs8, dyn

# CHECK-INST: fswizz.ps	ft3, fa4, 188
# CHECK-ENC: encoding: [0xfb,0x41,0x77,0xe7]
fswizz.ps	ft3, fa4, 188

# CHECK-INST: fsw.ps	fs4, 1772(a1)
# CHECK-ENC: encoding: [0x0b,0xe6,0x45,0x6f]
fsw.ps	fs4, 1772(a1)

# CHECK-INST: fxor.pi	ft10, fa6, fs6
# CHECK-ENC: encoding: [0x7b,0x4f,0x68,0x07]
fxor.pi	ft10, fa6, fs6

#====----------------------------------------------------------------------===//
# Masking instructions
#====----------------------------------------------------------------------===//

# CHECK-INST: maskand	m3, m5, m0
# CHECK-ENC: encoding: [0xfb,0xf1,0x02,0x66]
maskand	m3, m5, m0

# CHECK-INST: masknot	m6, m6
# CHECK-ENC: encoding: [0x7b,0x23,0x03,0x66]
masknot	m6, m6

# CHECK-INST: maskor	m0, m7, m5
# CHECK-ENC: encoding: [0x7b,0xe0,0x53,0x66]
maskor	m0, m7, m5

# CHECK-INST: maskpopc	s9, m7
# CHECK-ENC: encoding: [0xfb,0x8c,0x03,0x52]
maskpopc	s9, m7

# CHECK-INST: maskpopcz	s10, m4
# CHECK-ENC: encoding: [0x7b,0x0d,0x02,0x54]
maskpopcz	s10, m4

# CHECK-INST: maskpopc.rast	m1, m3, m2, 2
# CHECK-ENC: encoding: [0xfb,0x80,0x29,0x5e]
maskpopc.rast	m1, m3, m2, 2

# CHECK-INST: maskxor	m6, m6, m2
# CHECK-ENC: encoding: [0x7b,0x43,0x23,0x66]
maskxor	m6, m6, m2

# CHECK-INST: mova.m.x	t1
# CHECK-ENC: encoding: [0x7b,0x10,0x03,0xd6]
mova.m.x	t1

# CHECK-INST: mova.x.m	s1
# CHECK-ENC: encoding: [0xfb,0x04,0x00,0xd6]
mova.x.m	s1

# CHECK-INST: mov.m.x	m3, t0, 201
# CHECK-ENC: encoding: [0xfb,0x91,0x92,0x57]
mov.m.x	m3, t0, 201

# CHECK-INST: packb	a1, a2, a4
# CHECK-ENC: encoding: [0xbb,0x65,0xe6,0x80]
packb	a1, a2, a4