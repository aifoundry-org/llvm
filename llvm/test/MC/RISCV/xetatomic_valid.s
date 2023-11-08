# XETatomic - Esperanto Technologies AMO instructions
	
# RUN: llvm-mc --arch=riscv64 -mcpu=et-soc1-min --show-encoding %s | FileCheck -check-prefixes=CHECK-ENC,CHECK-INST %s 

#====----------------------------------------------------------------------===//
# Scalar INT AMO local|global
#====----------------------------------------------------------------------===//

# CHECK-INST: amoaddg.d	a4, s9, (t1)            
# CHECK-ENC: encoding: [0x3b,0x37,0x93,0x03]
amoaddg.d	a4, s9, (t1)

# CHECK-INST: amoaddg.w	t1, s5, (t0)            
# CHECK-ENC: encoding: [0x3b,0xa3,0x52,0x03]
amoaddg.w	t1, s5, (t0)

# CHECK-INST: amoaddl.d	a4, s4, (a6)            
# CHECK-ENC: encoding: [0x3b,0x37,0x48,0x01]
amoaddl.d	a4, s4, (a6)

# CHECK-INST: amoaddl.w	tp, t2, (gp)            
# CHECK-ENC: encoding: [0x3b,0xa2,0x71,0x00]
amoaddl.w	tp, t2, (gp)

# CHECK-INST: amoandg.d	s2, a5, (a2)            
# CHECK-ENC: encoding: [0x3b,0x39,0xf6,0x62]
amoandg.d	s2, a5, (a2)

# CHECK-INST: amoandg.w	t0, s8, (s2)            
# CHECK-ENC: encoding: [0xbb,0x22,0x89,0x63]
amoandg.w	t0, s8, (s2)

# CHECK-INST: amoandl.d	sp, ra, (a4)            
# CHECK-ENC: encoding: [0x3b,0x31,0x17,0x60]
amoandl.d	sp, ra, (a4)

# CHECK-INST: amoandl.w	t5, s0, (gp)            
# CHECK-ENC: encoding: [0x3b,0xaf,0x81,0x60]
amoandl.w	t5, s0, (gp)

# CHECK-INST: amocmpswapg.d	s0, gp, (a3)            
# CHECK-ENC: encoding: [0x3b,0xb4,0x36,0xf2]
amocmpswapg.d	fp, gp, (a3)

# CHECK-INST: amocmpswapg.w	a5, tp, (s8)            
# CHECK-ENC: encoding: [0xbb,0x27,0x4c,0xf2]
amocmpswapg.w	a5, tp, (s8)

# CHECK-INST: amocmpswapl.d	t5, s6, (s1)            
# CHECK-ENC: encoding: [0x3b,0xbf,0x64,0xf1]
amocmpswapl.d	t5, s6, (s1)

# CHECK-INST: amocmpswapl.w	a7, s0, (sp)            
# CHECK-ENC: encoding: [0xbb,0x28,0x81,0xf0]
amocmpswapl.w	a7, s0, (sp)

# CHECK-INST: amomaxg.d	tp, s10, (a2)           
# CHECK-ENC: encoding: [0x3b,0x32,0xa6,0xa3]
amomaxg.d	tp, s10, (a2)

# CHECK-INST: amomaxg.w	a0, s6, (a1)            
# CHECK-ENC: encoding: [0x3b,0xa5,0x65,0xa3]
amomaxg.w	a0, s6, (a1)

# CHECK-INST: amomaxl.d	a6, s7, (s4)            
# CHECK-ENC: encoding: [0x3b,0x38,0x7a,0xa1]
amomaxl.d	a6, s7, (s4)

# CHECK-INST: amomaxl.w	s4, s3, (a7)            
# CHECK-ENC: encoding: [0x3b,0xaa,0x38,0xa1]
amomaxl.w	s4, s3, (a7)

# CHECK-INST: amomaxug.d	t0, s4, (t2)            
# CHECK-ENC: encoding: [0xbb,0xb2,0x43,0xe3]
amomaxug.d	t0, s4, (t2)

# CHECK-INST: amomaxug.w	s5, t5, (t2)            
# CHECK-ENC: encoding: [0xbb,0xaa,0xe3,0xe3]
amomaxug.w	s5, t5, (t2)

# CHECK-INST: amomaxul.d	t2, t2, (tp)            
# CHECK-ENC: encoding: [0xbb,0x33,0x72,0xe0]
amomaxul.d	t2, t2, (tp)

# CHECK-INST: amomaxul.w	t5, a2, (t4)            
# CHECK-ENC: encoding: [0x3b,0xaf,0xce,0xe0]
amomaxul.w	t5, a2, (t4)

# CHECK-INST: amoming.d	s0, t0, (s1)            
# CHECK-ENC: encoding: [0x3b,0xb4,0x54,0x82]
amoming.d	fp, t0, (s1)

# CHECK-INST: amoming.w	a1, s4, (t2)            
# CHECK-ENC: encoding: [0xbb,0xa5,0x43,0x83]
amoming.w	a1, s4, (t2)

# CHECK-INST: amominl.d	t0, a5, (t3)            
# CHECK-ENC: encoding: [0xbb,0x32,0xfe,0x80]
amominl.d	t0, a5, (t3)

# CHECK-INST: amominl.w	t3, s5, (gp)            
# CHECK-ENC: encoding: [0x3b,0xae,0x51,0x81]
amominl.w	t3, s5, (gp)

# CHECK-INST: amominug.d	s9, t1, (s3)            
# CHECK-ENC: encoding: [0xbb,0xbc,0x69,0xc2]
amominug.d	s9, t1, (s3)

# CHECK-INST: amominug.w	a4, s0, (gp)            
# CHECK-ENC: encoding: [0x3b,0xa7,0x81,0xc2]
amominug.w	a4, fp, (gp)

# CHECK-INST: amominul.d	ra, a6, (ra)            
# CHECK-ENC: encoding: [0xbb,0xb0,0x00,0xc1]
amominul.d	ra, a6, (ra)

# CHECK-INST: amominul.w	a1, a3, (s8)            
# CHECK-ENC: encoding: [0xbb,0x25,0xdc,0xc0]
amominul.w	a1, a3, (s8)

# CHECK-INST: amoorg.d	a5, a7, (a4)                    
# CHECK-ENC: encoding: [0xbb,0x37,0x17,0x43]
amoorg.d	a5, a7, (a4)

# CHECK-INST: amoorg.w	s10, a5, (s9)                   
# CHECK-ENC: encoding: [0x3b,0xad,0xfc,0x42]
amoorg.w	s10, a5, (s9)

# CHECK-INST: amoorl.d	ra, t3, (zero)                  
# CHECK-ENC: encoding: [0xbb,0x30,0xc0,0x41]
amoorl.d	ra, t3, (zero)

# CHECK-INST: amoorl.w	t5, a5, (a7)                    
# CHECK-ENC: encoding: [0x3b,0xaf,0xf8,0x40]
amoorl.w	t5, a5, (a7)

# CHECK-INST: amoswapg.d	s7, sp, (sp)            
# CHECK-ENC: encoding: [0xbb,0x3b,0x21,0x0a]
amoswapg.d	s7, sp, (sp)

# CHECK-INST: amoswapg.w	a7, t3, (s9)            
# CHECK-ENC: encoding: [0xbb,0xa8,0xcc,0x0b]
amoswapg.w	a7, t3, (s9)

# CHECK-INST: amoswapl.d	sp, gp, (t5)            
# CHECK-ENC: encoding: [0x3b,0x31,0x3f,0x08]
amoswapl.d	sp, gp, (t5)

# CHECK-INST: amoswapl.w	s1, a7, (s9)            
# CHECK-ENC: encoding: [0xbb,0xa4,0x1c,0x09]
amoswapl.w	s1, a7, (s9)

# CHECK-INST: amoxorg.d	t4, s1, (s1)            
# CHECK-ENC: encoding: [0xbb,0xbe,0x94,0x22]
amoxorg.d	t4, s1, (s1)

# CHECK-INST: amoxorg.w	gp, a4, (sp)            
# CHECK-ENC: encoding: [0xbb,0x21,0xe1,0x22]
amoxorg.w	gp, a4, (sp)

# CHECK-INST: amoxorl.d	sp, a0, (a0)            
# CHECK-ENC: encoding: [0x3b,0x31,0xa5,0x20]
amoxorl.d	sp, a0, (a0)

# CHECK-INST: amoxorl.w	s1, a7, (s0)            
# CHECK-ENC: encoding: [0xbb,0x24,0x14,0x21]
amoxorl.w	s1, a7, (fp)

# CHECK-INST: amoaddg.d	a4, s9, (t1)            
# CHECK-ENC: encoding: [0x3b,0x37,0x93,0x03]
amoaddg.d	a4, s9, 0(t1)

# CHECK-INST: amoaddg.w	t1, s5, (t0)            
# CHECK-ENC: encoding: [0x3b,0xa3,0x52,0x03]
amoaddg.w	t1, s5, 0(t0)

# CHECK-INST: amoaddl.d	a4, s4, (a6)            
# CHECK-ENC: encoding: [0x3b,0x37,0x48,0x01]
amoaddl.d	a4, s4, 0(a6)

# CHECK-INST: amoaddl.w	tp, t2, (gp)            
# CHECK-ENC: encoding: [0x3b,0xa2,0x71,0x00]
amoaddl.w	tp, t2, 0(gp)

# CHECK-INST: amoandg.d	s2, a5, (a2)            
# CHECK-ENC: encoding: [0x3b,0x39,0xf6,0x62]
amoandg.d	s2, a5, 0(a2)

# CHECK-INST: amoandg.w	t0, s8, (s2)            
# CHECK-ENC: encoding: [0xbb,0x22,0x89,0x63]
amoandg.w	t0, s8, 0(s2)

# CHECK-INST: amoandl.d	sp, ra, (a4)            
# CHECK-ENC: encoding: [0x3b,0x31,0x17,0x60]
amoandl.d	sp, ra, 0(a4)

# CHECK-INST: amoandl.w	t5, s0, (gp)            
# CHECK-ENC: encoding: [0x3b,0xaf,0x81,0x60]
amoandl.w	t5, s0, 0(gp)

# CHECK-INST: amocmpswapg.d	s0, gp, (a3)            
# CHECK-ENC: encoding: [0x3b,0xb4,0x36,0xf2]
amocmpswapg.d	fp, gp, 0(a3)

# CHECK-INST: amocmpswapg.w	a5, tp, (s8)            
# CHECK-ENC: encoding: [0xbb,0x27,0x4c,0xf2]
amocmpswapg.w	a5, tp, 0(s8)

# CHECK-INST: amocmpswapl.d	t5, s6, (s1)            
# CHECK-ENC: encoding: [0x3b,0xbf,0x64,0xf1]
amocmpswapl.d	t5, s6, 0(s1)

# CHECK-INST: amocmpswapl.w	a7, s0, (sp)            
# CHECK-ENC: encoding: [0xbb,0x28,0x81,0xf0]
amocmpswapl.w	a7, s0, 0(sp)

# CHECK-INST: amomaxg.d	tp, s10, (a2)           
# CHECK-ENC: encoding: [0x3b,0x32,0xa6,0xa3]
amomaxg.d	tp, s10, 0(a2)

# CHECK-INST: amomaxg.w	a0, s6, (a1)            
# CHECK-ENC: encoding: [0x3b,0xa5,0x65,0xa3]
amomaxg.w	a0, s6, 0(a1)

# CHECK-INST: amomaxl.d	a6, s7, (s4)            
# CHECK-ENC: encoding: [0x3b,0x38,0x7a,0xa1]
amomaxl.d	a6, s7, 0(s4)

# CHECK-INST: amomaxl.w	s4, s3, (a7)            
# CHECK-ENC: encoding: [0x3b,0xaa,0x38,0xa1]
amomaxl.w	s4, s3, 0(a7)

# CHECK-INST: amomaxug.d	t0, s4, (t2)            
# CHECK-ENC: encoding: [0xbb,0xb2,0x43,0xe3]
amomaxug.d	t0, s4, 0(t2)

# CHECK-INST: amomaxug.w	s5, t5, (t2)            
# CHECK-ENC: encoding: [0xbb,0xaa,0xe3,0xe3]
amomaxug.w	s5, t5, 0(t2)

# CHECK-INST: amomaxul.d	t2, t2, (tp)            
# CHECK-ENC: encoding: [0xbb,0x33,0x72,0xe0]
amomaxul.d	t2, t2, 0(tp)

# CHECK-INST: amomaxul.w	t5, a2, (t4)            
# CHECK-ENC: encoding: [0x3b,0xaf,0xce,0xe0]
amomaxul.w	t5, a2, 0(t4)

# CHECK-INST: amoming.d	s0, t0, (s1)            
# CHECK-ENC: encoding: [0x3b,0xb4,0x54,0x82]
amoming.d	fp, t0, 0(s1)

# CHECK-INST: amoming.w	a1, s4, (t2)            
# CHECK-ENC: encoding: [0xbb,0xa5,0x43,0x83]
amoming.w	a1, s4, 0(t2)

# CHECK-INST: amominl.d	t0, a5, (t3)            
# CHECK-ENC: encoding: [0xbb,0x32,0xfe,0x80]
amominl.d	t0, a5, 0(t3)

# CHECK-INST: amominl.w	t3, s5, (gp)            
# CHECK-ENC: encoding: [0x3b,0xae,0x51,0x81]
amominl.w	t3, s5, 0(gp)

# CHECK-INST: amominug.d	s9, t1, (s3)            
# CHECK-ENC: encoding: [0xbb,0xbc,0x69,0xc2]
amominug.d	s9, t1, 0(s3)

# CHECK-INST: amominug.w	a4, s0, (gp)            
# CHECK-ENC: encoding: [0x3b,0xa7,0x81,0xc2]
amominug.w	a4, fp, 0(gp)

# CHECK-INST: amominul.d	ra, a6, (ra)            
# CHECK-ENC: encoding: [0xbb,0xb0,0x00,0xc1]
amominul.d	ra, a6, 0(ra)

# CHECK-INST: amominul.w	a1, a3, (s8)            
# CHECK-ENC: encoding: [0xbb,0x25,0xdc,0xc0]
amominul.w	a1, a3, 0(s8)

# CHECK-INST: amoorg.d	a5, a7, (a4)                    
# CHECK-ENC: encoding: [0xbb,0x37,0x17,0x43]
amoorg.d	a5, a7, 0(a4)

# CHECK-INST: amoorg.w	s10, a5, (s9)                   
# CHECK-ENC: encoding: [0x3b,0xad,0xfc,0x42]
amoorg.w	s10, a5, 0(s9)

# CHECK-INST: amoorl.d	ra, t3, (zero)                  
# CHECK-ENC: encoding: [0xbb,0x30,0xc0,0x41]
amoorl.d	ra, t3, 0(zero)

# CHECK-INST: amoorl.w	t5, a5, (a7)                    
# CHECK-ENC: encoding: [0x3b,0xaf,0xf8,0x40]
amoorl.w	t5, a5, 0(a7)

# CHECK-INST: amoswapg.d	s7, sp, (sp)            
# CHECK-ENC: encoding: [0xbb,0x3b,0x21,0x0a]
amoswapg.d	s7, sp, 0(sp)

# CHECK-INST: amoswapg.w	a7, t3, (s9)            
# CHECK-ENC: encoding: [0xbb,0xa8,0xcc,0x0b]
amoswapg.w	a7, t3, 0(s9)

# CHECK-INST: amoswapl.d	sp, gp, (t5)            
# CHECK-ENC: encoding: [0x3b,0x31,0x3f,0x08]
amoswapl.d	sp, gp, 0(t5)

# CHECK-INST: amoswapl.w	s1, a7, (s9)            
# CHECK-ENC: encoding: [0xbb,0xa4,0x1c,0x09]
amoswapl.w	s1, a7, 0(s9)

# CHECK-INST: amoxorg.d	t4, s1, (s1)            
# CHECK-ENC: encoding: [0xbb,0xbe,0x94,0x22]
amoxorg.d	t4, s1, 0(s1)

# CHECK-INST: amoxorg.w	gp, a4, (sp)            
# CHECK-ENC: encoding: [0xbb,0x21,0xe1,0x22]
amoxorg.w	gp, a4, 0(sp)

# CHECK-INST: amoxorl.d	sp, a0, (a0)            
# CHECK-ENC: encoding: [0x3b,0x31,0xa5,0x20]
amoxorl.d	sp, a0, 0(a0)

# CHECK-INST: amoxorl.w	s1, a7, (s0)            
# CHECK-ENC: encoding: [0xbb,0x24,0x14,0x21]
amoxorl.w	s1, a7, 0(fp)

#====----------------------------------------------------------------------===//
# SIMD INT AMO local|global
#====----------------------------------------------------------------------===//

# CHECK-INST: famoaddg.pi	fa5, ft5(a5)            
# CHECK-ENC: encoding: [0x8b,0xc7,0xf2,0x86]
famoaddg.pi	fa5, ft5(a5)

# CHECK-INST: famoaddl.pi	fs3, ft1(gp)            
# CHECK-ENC: encoding: [0x8b,0xc9,0x30,0x06]
famoaddl.pi	fs3, ft1(gp)

# CHECK-INST: famoandg.pi	fs7, ft5(s3)            
# CHECK-ENC: encoding: [0x8b,0xcb,0x32,0x97]
famoandg.pi	fs7, ft5(s3)

# CHECK-INST: famoandl.pi	fs6, fs5(a0)            
# CHECK-ENC: encoding: [0x0b,0xcb,0xaa,0x16]
famoandl.pi	fs6, fs5(a0)

# CHECK-INST: famomaxg.pi	ft0, ft10(s6)           
# CHECK-ENC: encoding: [0x0b,0x40,0x6f,0xb7]
famomaxg.pi	ft0, ft10(s6)

# CHECK-INST: famomaxg.ps	fs1, fs9(s7)            
# CHECK-ENC: encoding: [0x8b,0xc4,0x7c,0xa9]
famomaxg.ps	fs1, fs9(s7)

# CHECK-INST: famomaxl.pi	ft11, ft6(t5)           
# CHECK-ENC: encoding: [0x8b,0x4f,0xe3,0x37]
famomaxl.pi	ft11, ft6(t5)

# CHECK-INST: famomaxl.ps	fs6, fs9(zero)          
# CHECK-ENC: encoding: [0x0b,0xcb,0x0c,0x28]
famomaxl.ps	fs6, fs9(zero)

# CHECK-INST: famomaxug.pi	ft9, fs1(s5)            
# CHECK-ENC: encoding: [0x8b,0xce,0x54,0xc7]
famomaxug.pi	ft9, fs1(s5)

# CHECK-INST: famomaxul.pi	ft11, fs3(s4)           
# CHECK-ENC: encoding: [0x8b,0xcf,0x49,0x47]
famomaxul.pi	ft11, fs3(s4)

# CHECK-INST: famoming.pi	fa5, ft6(a7)            
# CHECK-ENC: encoding: [0x8b,0x47,0x13,0xaf]
famoming.pi	fa5, ft6(a7)

# CHECK-INST: famoming.ps	ft2, ft8(s0)            
# CHECK-ENC: encoding: [0x0b,0x41,0x8e,0xb0]
famoming.ps	ft2, ft8(fp)

# CHECK-INST: famominl.pi	ft6, fs2(a0)            
# CHECK-ENC: encoding: [0x0b,0x43,0xa9,0x2e]
famominl.pi	ft6, fs2(a0)

# CHECK-INST: famominl.ps	ft5, ft4(s3)            
# CHECK-ENC: encoding: [0x8b,0x42,0x32,0x31]
famominl.ps	ft5, ft4(s3)

# CHECK-INST: famominug.pi	ft7, fs10(s1)           
# CHECK-ENC: encoding: [0x8b,0x43,0x9d,0xbe]
famominug.pi	ft7, fs10(s1)

# CHECK-INST: famominul.pi	fa6, fs10(tp)           
# CHECK-ENC: encoding: [0x0b,0x48,0x4d,0x3e]
famominul.pi	fa6, fs10(tp)

# CHECK-INST: famoorg.pi	ft9, fs8(gp)            
# CHECK-ENC: encoding: [0x8b,0x4e,0x3c,0x9e]
famoorg.pi	ft9, fs8(gp)

# CHECK-INST: famoorl.pi	fa0, ft8(s5)            
# CHECK-ENC: encoding: [0x0b,0x45,0x5e,0x1f]
famoorl.pi	fa0, ft8(s5)

# CHECK-INST: famoswapg.pi	fs5, fs9(s10)           
# CHECK-ENC: encoding: [0x8b,0xca,0xac,0x8f]
famoswapg.pi	fs5, fs9(s10)

# CHECK-INST: famoswapl.pi	fs0, fa4(s10)           
# CHECK-ENC: encoding: [0x0b,0x44,0xa7,0x0f]
famoswapl.pi	fs0, fa4(s10)

# CHECK-INST: famoxorg.pi	fs7, ft9(t5)            
# CHECK-ENC: encoding: [0x8b,0xcb,0xee,0xa7]
famoxorg.pi	fs7, ft9(t5)

# CHECK-INST: famoxorl.pi	fa7, fs7(a4)            
# CHECK-ENC: encoding: [0x8b,0xc8,0xeb,0x26]
famoxorl.pi	fa7, fs7(a4)

#====----------------------------------------------------------------------===//
# SIMD global
#====----------------------------------------------------------------------===//

# CHECK-INST: fgbg.ps	fs7, fs6(s0)                    
# CHECK-ENC: encoding: [0x8b,0x7b,0x8b,0x82]
fgbg.ps	fs7, fs6(s0)

# CHECK-INST: fghg.ps	fa4, fs8(s6)                    
# CHECK-ENC: encoding: [0x0b,0x77,0x6c,0x8b]
fghg.ps	fa4, fs8(s6)

# CHECK-INST: fgwg.ps	fa6, fs6(tp)                    
# CHECK-ENC: encoding: [0x0b,0x78,0x4b,0x92]
fgwg.ps	fa6, fs6(tp)

# CHECK-INST: flwg.ps	fs10, (a4)                      
# CHECK-ENC: encoding: [0x0b,0x7d,0x07,0x12]
flwg.ps	fs10, (a4)

# CHECK-INST: fscbg.ps	fa6, fs5(t0)                    
# CHECK-ENC: encoding: [0x0b,0xf8,0x5a,0xc2]
fscbg.ps	fa6, fs5(t0)

# CHECK-INST: fschg.ps	fa3, fs9(s8)                    
# CHECK-ENC: encoding: [0x8b,0xf6,0x8c,0xcb]
fschg.ps	fa3, fs9(s8)

# CHECK-INST: fscwg.ps	ft4, fs9(s0)                    
# CHECK-ENC: encoding: [0x0b,0xf2,0x8c,0xd2]
fscwg.ps	ft4, fs9(s0)

# CHECK-INST: fswg.ps	fa5, (t5)                       
# CHECK-ENC: encoding: [0x8b,0x77,0x0f,0x52]
fswg.ps	fa5, (t5)

#====----------------------------------------------------------------------===//
# SIMD local
#====----------------------------------------------------------------------===//

# CHECK-INST: fgbl.ps	fs3, ft11(ra)                   
# CHECK-ENC: encoding: [0x8b,0xf9,0x1f,0x80]
fgbl.ps	fs3, ft11(ra)

# CHECK-INST: fghl.ps	ft1, fs2(s5)                    
# CHECK-ENC: encoding: [0x8b,0x70,0x59,0x89]
fghl.ps	ft1, fs2(s5)

# CHECK-INST: fgwl.ps	ft6, fs2(gp)                    
# CHECK-ENC: encoding: [0x0b,0x73,0x39,0x90]
fgwl.ps	ft6, fs2(gp)

# CHECK-INST: flwl.ps	fs1, (t2)                       
# CHECK-ENC: encoding: [0x8b,0xf4,0x03,0x10]
flwl.ps	fs1, (t2)

# CHECK-INST: fscbl.ps	ft5, ft7(s5)                    
# CHECK-ENC: encoding: [0x8b,0xf2,0x53,0xc1]
fscbl.ps	ft5, ft7(s5)

# CHECK-INST: fschl.ps	fs8, ft1(t1)                    
# CHECK-ENC: encoding: [0x0b,0xfc,0x60,0xc8]
fschl.ps	fs8, ft1(t1)

# CHECK-INST: fscwl.ps	fs0, ft11(ra)                   
# CHECK-ENC: encoding: [0x0b,0xf4,0x1f,0xd0]
fscwl.ps	fs0, ft11(ra)

# CHECK-INST: fswl.ps	ft7, (t2)                       
# CHECK-ENC: encoding: [0x8b,0xf3,0x03,0x50]
fswl.ps	ft7, (t2)

#====----------------------------------------------------------------------===//
# Scalar global
#====----------------------------------------------------------------------===//

# CHECK-INST: sbg	a6, (t4)                        
# CHECK-ENC: encoding: [0x3b,0xb0,0x0e,0x13]
sbg	a6, (t4)

# CHECK-INST: shg	sp, (s6)                        
# CHECK-ENC: encoding: [0x3b,0x30,0x2b,0x1a]
shg	sp, (s6)

# CHECK-INST: sbg	a6, (t4)                        
# CHECK-ENC: encoding: [0x3b,0xb0,0x0e,0x13]
sbg	a6, 0(t4)

# CHECK-INST: shg	sp, (s6)                        
# CHECK-ENC: encoding: [0x3b,0x30,0x2b,0x1a]
shg	sp, 0(s6)
	
#====----------------------------------------------------------------------===//
# Scalar local
#====----------------------------------------------------------------------===//

# CHECK-INST: sbl	a3, (s0)                        
# CHECK-ENC: encoding: [0x3b,0x30,0xd4,0x10]
sbl	a3, (fp)

# CHECK-INST: shl	s0, (s10)                       
# CHECK-ENC: encoding: [0x3b,0x30,0x8d,0x18]
shl	fp, (s10)

# CHECK-INST: sbl	a3, (s0)                        
# CHECK-ENC: encoding: [0x3b,0x30,0xd4,0x10]
sbl	a3, 0(fp)

# CHECK-INST: shl	s0, (s10)                       
# CHECK-ENC: encoding: [0x3b,0x30,0x8d,0x18]
shl	fp, 0(s10)
