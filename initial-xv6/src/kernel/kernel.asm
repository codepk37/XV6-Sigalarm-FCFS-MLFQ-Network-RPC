
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	93013103          	ld	sp,-1744(sp) # 80008930 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	94070713          	addi	a4,a4,-1728 # 80008990 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	77e78793          	addi	a5,a5,1918 # 800067e0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb01f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00003097          	auipc	ra,0x3
    8000012e:	bb6080e7          	jalr	-1098(ra) # 80002ce0 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	94650513          	addi	a0,a0,-1722 # 80010ad0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	93648493          	addi	s1,s1,-1738 # 80010ad0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9c690913          	addi	s2,s2,-1594 # 80010b68 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	a10080e7          	jalr	-1520(ra) # 80001bd0 <myproc>
    800001c8:	00003097          	auipc	ra,0x3
    800001cc:	962080e7          	jalr	-1694(ra) # 80002b2a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	65c080e7          	jalr	1628(ra) # 80002832 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00003097          	auipc	ra,0x3
    80000216:	a78080e7          	jalr	-1416(ra) # 80002c8a <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	8aa50513          	addi	a0,a0,-1878 # 80010ad0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	89450513          	addi	a0,a0,-1900 # 80010ad0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8ef72b23          	sw	a5,-1802(a4) # 80010b68 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	80450513          	addi	a0,a0,-2044 # 80010ad0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	a44080e7          	jalr	-1468(ra) # 80002d36 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7d650513          	addi	a0,a0,2006 # 80010ad0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	7b270713          	addi	a4,a4,1970 # 80010ad0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	78878793          	addi	a5,a5,1928 # 80010ad0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7f27a783          	lw	a5,2034(a5) # 80010b68 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	74670713          	addi	a4,a4,1862 # 80010ad0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	73648493          	addi	s1,s1,1846 # 80010ad0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6fa70713          	addi	a4,a4,1786 # 80010ad0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	78f72223          	sw	a5,1924(a4) # 80010b70 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	6be78793          	addi	a5,a5,1726 # 80010ad0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	72c7ab23          	sw	a2,1846(a5) # 80010b6c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	72a50513          	addi	a0,a0,1834 # 80010b68 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	450080e7          	jalr	1104(ra) # 80002896 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	67050513          	addi	a0,a0,1648 # 80010ad0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	1d078793          	addi	a5,a5,464 # 80022648 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6407a223          	sw	zero,1604(a5) # 80010b90 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	cf250513          	addi	a0,a0,-782 # 80008260 <digits+0x220>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	3cf72823          	sw	a5,976(a4) # 80008950 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	5d4dad83          	lw	s11,1492(s11) # 80010b90 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	57e50513          	addi	a0,a0,1406 # 80010b78 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	42050513          	addi	a0,a0,1056 # 80010b78 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	40448493          	addi	s1,s1,1028 # 80010b78 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	3c450513          	addi	a0,a0,964 # 80010b98 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1507a783          	lw	a5,336(a5) # 80008950 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1207b783          	ld	a5,288(a5) # 80008958 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	12073703          	ld	a4,288(a4) # 80008960 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	336a0a13          	addi	s4,s4,822 # 80010b98 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0ee48493          	addi	s1,s1,238 # 80008958 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0ee98993          	addi	s3,s3,238 # 80008960 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	002080e7          	jalr	2(ra) # 80002896 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	2c850513          	addi	a0,a0,712 # 80010b98 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0707a783          	lw	a5,112(a5) # 80008950 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	07673703          	ld	a4,118(a4) # 80008960 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0667b783          	ld	a5,102(a5) # 80008958 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	29a98993          	addi	s3,s3,666 # 80010b98 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	05248493          	addi	s1,s1,82 # 80008958 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	05290913          	addi	s2,s2,82 # 80008960 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	f14080e7          	jalr	-236(ra) # 80002832 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	26448493          	addi	s1,s1,612 # 80010b98 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	00e7bc23          	sd	a4,24(a5) # 80008960 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	1de48493          	addi	s1,s1,478 # 80010b98 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00023797          	auipc	a5,0x23
    80000a00:	de478793          	addi	a5,a5,-540 # 800237e0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	1b490913          	addi	s2,s2,436 # 80010bd0 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	11650513          	addi	a0,a0,278 # 80010bd0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00023517          	auipc	a0,0x23
    80000ad2:	d1250513          	addi	a0,a0,-750 # 800237e0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	0e048493          	addi	s1,s1,224 # 80010bd0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	0c850513          	addi	a0,a0,200 # 80010bd0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	09c50513          	addi	a0,a0,156 # 80010bd0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	044080e7          	jalr	68(ra) # 80001bb4 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	012080e7          	jalr	18(ra) # 80001bb4 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	006080e7          	jalr	6(ra) # 80001bb4 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	fee080e7          	jalr	-18(ra) # 80001bb4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	fae080e7          	jalr	-82(ra) # 80001bb4 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	f82080e7          	jalr	-126(ra) # 80001bb4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdb821>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	d24080e7          	jalr	-732(ra) # 80001ba4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	ae070713          	addi	a4,a4,-1312 # 80008968 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	d08080e7          	jalr	-760(ra) # 80001ba4 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	19c080e7          	jalr	412(ra) # 8000305a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00006097          	auipc	ra,0x6
    80000eca:	95a080e7          	jalr	-1702(ra) # 80006820 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	2a8080e7          	jalr	680(ra) # 80002176 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	37a50513          	addi	a0,a0,890 # 80008260 <digits+0x220>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	35a50513          	addi	a0,a0,858 # 80008260 <digits+0x220>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	bc2080e7          	jalr	-1086(ra) # 80001af0 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	0fc080e7          	jalr	252(ra) # 80003032 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	11c080e7          	jalr	284(ra) # 8000305a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00006097          	auipc	ra,0x6
    80000f4a:	8c4080e7          	jalr	-1852(ra) # 8000680a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00006097          	auipc	ra,0x6
    80000f52:	8d2080e7          	jalr	-1838(ra) # 80006820 <plicinithart>
    binit();         // buffer cache
    80000f56:	00003097          	auipc	ra,0x3
    80000f5a:	a5a080e7          	jalr	-1446(ra) # 800039b0 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	0fa080e7          	jalr	250(ra) # 80004058 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	0a0080e7          	jalr	160(ra) # 80005006 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00006097          	auipc	ra,0x6
    80000f72:	9ba080e7          	jalr	-1606(ra) # 80006928 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	f64080e7          	jalr	-156(ra) # 80001eda <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9ef72223          	sw	a5,-1564(a4) # 80008968 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9d87b783          	ld	a5,-1576(a5) # 80008970 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdb817>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00001097          	auipc	ra,0x1
    80001232:	82c080e7          	jalr	-2004(ra) # 80001a5a <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	70a7be23          	sd	a0,1820(a5) # 80008970 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdb820>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <initializeCircularQueue>:

struct MultiCircularQueue {
    struct CircularQueue queues[NUM_QUEUES];
};

void initializeCircularQueue(struct CircularQueue *queue) {
    80001836:	1141                	addi	sp,sp,-16
    80001838:	e422                	sd	s0,8(sp)
    8000183a:	0800                	addi	s0,sp,16
    // queue->front = -1;
    // queue->rear = -1;
    for (int i = 0; i < MAX_SIZE; i++) {
    8000183c:	20850793          	addi	a5,a0,520
        queue->items[i] = 0;
    80001840:	00053023          	sd	zero,0(a0)
    for (int i = 0; i < MAX_SIZE; i++) {
    80001844:	0521                	addi	a0,a0,8
    80001846:	fef51de3          	bne	a0,a5,80001840 <initializeCircularQueue+0xa>
    }
}
    8000184a:	6422                	ld	s0,8(sp)
    8000184c:	0141                	addi	sp,sp,16
    8000184e:	8082                	ret

0000000080001850 <isCircularQueueEmpty>:

int isCircularQueueEmpty(struct MultiCircularQueue *multiQueue,int n) {
    80001850:	1141                	addi	sp,sp,-16
    80001852:	e422                	sd	s0,8(sp)
    80001854:	0800                	addi	s0,sp,16
    struct CircularQueue *queue=&multiQueue->queues[n];
    int tot=0;
    for(int i=0;i<MAX_SIZE;i++){
    80001856:	00659793          	slli	a5,a1,0x6
    8000185a:	97ae                	add	a5,a5,a1
    8000185c:	078e                	slli	a5,a5,0x3
    8000185e:	97aa                	add	a5,a5,a0
    80001860:	20878693          	addi	a3,a5,520
    int tot=0;
    80001864:	4501                	li	a0,0
    80001866:	a029                	j	80001870 <isCircularQueueEmpty+0x20>
        if(queue->items[i]!=0){//exist
            tot++;
    80001868:	2505                	addiw	a0,a0,1
    for(int i=0;i<MAX_SIZE;i++){
    8000186a:	07a1                	addi	a5,a5,8
    8000186c:	00d78563          	beq	a5,a3,80001876 <isCircularQueueEmpty+0x26>
        if(queue->items[i]!=0){//exist
    80001870:	6398                	ld	a4,0(a5)
    80001872:	fb7d                	bnez	a4,80001868 <isCircularQueueEmpty+0x18>
    80001874:	bfdd                	j	8000186a <isCircularQueueEmpty+0x1a>
        }
    }
    return (tot==0); //1 empty
}
    80001876:	00153513          	seqz	a0,a0
    8000187a:	6422                	ld	s0,8(sp)
    8000187c:	0141                	addi	sp,sp,16
    8000187e:	8082                	ret

0000000080001880 <isCircularQueueFull>:

int isCircularQueueFull(struct CircularQueue *queue) {
    80001880:	1141                	addi	sp,sp,-16
    80001882:	e422                	sd	s0,8(sp)
    80001884:	0800                	addi	s0,sp,16
    int tot=0;
    for(int i=0;i<MAX_SIZE;i++){
    80001886:	20850693          	addi	a3,a0,520
    int tot=0;
    8000188a:	4701                	li	a4,0
    8000188c:	a029                	j	80001896 <isCircularQueueFull+0x16>
        if(queue->items[i]!=0){//exist
            tot++;
    8000188e:	2705                	addiw	a4,a4,1
    for(int i=0;i<MAX_SIZE;i++){
    80001890:	0521                	addi	a0,a0,8
    80001892:	00d50563          	beq	a0,a3,8000189c <isCircularQueueFull+0x1c>
        if(queue->items[i]!=0){//exist
    80001896:	611c                	ld	a5,0(a0)
    80001898:	fbfd                	bnez	a5,8000188e <isCircularQueueFull+0xe>
    8000189a:	bfdd                	j	80001890 <isCircularQueueFull+0x10>
        }
    }
    
    return (tot==MAX_SIZE); //1 full
    8000189c:	fbf70713          	addi	a4,a4,-65
    
}
    800018a0:	00173513          	seqz	a0,a4
    800018a4:	6422                	ld	s0,8(sp)
    800018a6:	0141                	addi	sp,sp,16
    800018a8:	8082                	ret

00000000800018aa <enqueueToCircularQueue>:

void enqueueToCircularQueue(struct CircularQueue *queue, struct proc * value) {
    800018aa:	1101                	addi	sp,sp,-32
    800018ac:	ec06                	sd	ra,24(sp)
    800018ae:	e822                	sd	s0,16(sp)
    800018b0:	e426                	sd	s1,8(sp)
    800018b2:	e04a                	sd	s2,0(sp)
    800018b4:	1000                	addi	s0,sp,32
    800018b6:	84aa                	mv	s1,a0
    800018b8:	892e                	mv	s2,a1
    if (isCircularQueueFull(queue)) {
    800018ba:	00000097          	auipc	ra,0x0
    800018be:	fc6080e7          	jalr	-58(ra) # 80001880 <isCircularQueueFull>
    800018c2:	87a6                	mv	a5,s1
        printf("Queue is full. Cannot enqueue.\n");
        return;
    }
    
    for(int i=0;i<MAX_SIZE;i++){
    800018c4:	04100693          	li	a3,65
    if (isCircularQueueFull(queue)) {
    800018c8:	e901                	bnez	a0,800018d8 <enqueueToCircularQueue+0x2e>
        if(queue->items[i]==0){
    800018ca:	6398                	ld	a4,0(a5)
    800018cc:	cf19                	beqz	a4,800018ea <enqueueToCircularQueue+0x40>
    for(int i=0;i<MAX_SIZE;i++){
    800018ce:	2505                	addiw	a0,a0,1
    800018d0:	07a1                	addi	a5,a5,8
    800018d2:	fed51ce3          	bne	a0,a3,800018ca <enqueueToCircularQueue+0x20>
    800018d6:	a839                	j	800018f4 <enqueueToCircularQueue+0x4a>
        printf("Queue is full. Cannot enqueue.\n");
    800018d8:	00007517          	auipc	a0,0x7
    800018dc:	90050513          	addi	a0,a0,-1792 # 800081d8 <digits+0x198>
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	caa080e7          	jalr	-854(ra) # 8000058a <printf>
        return;
    800018e8:	a031                	j	800018f4 <enqueueToCircularQueue+0x4a>
            //found empty place
            queue->items[i]=value;
    800018ea:	00351793          	slli	a5,a0,0x3
    800018ee:	94be                	add	s1,s1,a5
    800018f0:	0124b023          	sd	s2,0(s1)
    }
    // printf("%dproc pid enqueued to queue%d , at ticks %d\n",value->pid,ticks);
    
    
    
}
    800018f4:	60e2                	ld	ra,24(sp)
    800018f6:	6442                	ld	s0,16(sp)
    800018f8:	64a2                	ld	s1,8(sp)
    800018fa:	6902                	ld	s2,0(sp)
    800018fc:	6105                	addi	sp,sp,32
    800018fe:	8082                	ret

0000000080001900 <initializeMultiCircularQueue>:

void initializeMultiCircularQueue(struct MultiCircularQueue *multiQueue) {
    80001900:	1101                	addi	sp,sp,-32
    80001902:	ec06                	sd	ra,24(sp)
    80001904:	e822                	sd	s0,16(sp)
    80001906:	e426                	sd	s1,8(sp)
    80001908:	1000                	addi	s0,sp,32
    8000190a:	84aa                	mv	s1,a0
    for (int i = 0; i < NUM_QUEUES; i++) {
        initializeCircularQueue(&multiQueue->queues[i]);
    8000190c:	00000097          	auipc	ra,0x0
    80001910:	f2a080e7          	jalr	-214(ra) # 80001836 <initializeCircularQueue>
    80001914:	20848513          	addi	a0,s1,520
    80001918:	00000097          	auipc	ra,0x0
    8000191c:	f1e080e7          	jalr	-226(ra) # 80001836 <initializeCircularQueue>
    80001920:	41048513          	addi	a0,s1,1040
    80001924:	00000097          	auipc	ra,0x0
    80001928:	f12080e7          	jalr	-238(ra) # 80001836 <initializeCircularQueue>
    8000192c:	61848513          	addi	a0,s1,1560
    80001930:	00000097          	auipc	ra,0x0
    80001934:	f06080e7          	jalr	-250(ra) # 80001836 <initializeCircularQueue>
    }
}
    80001938:	60e2                	ld	ra,24(sp)
    8000193a:	6442                	ld	s0,16(sp)
    8000193c:	64a2                	ld	s1,8(sp)
    8000193e:	6105                	addi	sp,sp,32
    80001940:	8082                	ret

0000000080001942 <enqueueToMultiCircularQueue>:

void enqueueToMultiCircularQueue(struct MultiCircularQueue *multiQueue, int queueNumber, struct proc * value) {
    80001942:	1141                	addi	sp,sp,-16
    80001944:	e406                	sd	ra,8(sp)
    80001946:	e022                	sd	s0,0(sp)
    80001948:	0800                	addi	s0,sp,16
    if (queueNumber >= 0 && queueNumber < NUM_QUEUES) {
    8000194a:	478d                	li	a5,3
    8000194c:	02b7e063          	bltu	a5,a1,8000196c <enqueueToMultiCircularQueue+0x2a>
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    80001950:	00659793          	slli	a5,a1,0x6
    80001954:	97ae                	add	a5,a5,a1
    80001956:	078e                	slli	a5,a5,0x3
    80001958:	85b2                	mv	a1,a2
    8000195a:	953e                	add	a0,a0,a5
    8000195c:	00000097          	auipc	ra,0x0
    80001960:	f4e080e7          	jalr	-178(ra) # 800018aa <enqueueToCircularQueue>
        // printf("%d %d %d\n",value->pid,queueNumber,ticks);//pid  make graph
    } else {
        printf("Invalid queue number.\n");
    }
}
    80001964:	60a2                	ld	ra,8(sp)
    80001966:	6402                	ld	s0,0(sp)
    80001968:	0141                	addi	sp,sp,16
    8000196a:	8082                	ret
        printf("Invalid queue number.\n");
    8000196c:	00007517          	auipc	a0,0x7
    80001970:	88c50513          	addi	a0,a0,-1908 # 800081f8 <digits+0x1b8>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	c16080e7          	jalr	-1002(ra) # 8000058a <printf>
}
    8000197c:	b7e5                	j	80001964 <enqueueToMultiCircularQueue+0x22>

000000008000197e <display>:
void display(struct MultiCircularQueue *multiQueue){
    8000197e:	7139                	addi	sp,sp,-64
    80001980:	fc06                	sd	ra,56(sp)
    80001982:	f822                	sd	s0,48(sp)
    80001984:	f426                	sd	s1,40(sp)
    80001986:	f04a                	sd	s2,32(sp)
    80001988:	ec4e                	sd	s3,24(sp)
    8000198a:	e852                	sd	s4,16(sp)
    8000198c:	e456                	sd	s5,8(sp)
    8000198e:	0080                	addi	s0,sp,64
    for (int i = 0; i < NUM_QUEUES; i++) {
    80001990:	20850913          	addi	s2,a0,520
    80001994:	6785                	lui	a5,0x1
    80001996:	a2878793          	addi	a5,a5,-1496 # a28 <_entry-0x7ffff5d8>
    8000199a:	00f50a33          	add	s4,a0,a5
        if (1||!isCircularQueueEmpty(multiQueue, i)) {
            
            struct CircularQueue *queue=&multiQueue->queues[i];
            
            for (int pos = 0; pos < MAX_SIZE; pos++) {
                printf("%d ",queue->items[pos]);
    8000199e:	00007997          	auipc	s3,0x7
    800019a2:	87298993          	addi	s3,s3,-1934 # 80008210 <digits+0x1d0>
            }
            printf("\n");
    800019a6:	00007a97          	auipc	s5,0x7
    800019aa:	8baa8a93          	addi	s5,s5,-1862 # 80008260 <digits+0x220>
            for (int pos = 0; pos < MAX_SIZE; pos++) {
    800019ae:	df890493          	addi	s1,s2,-520 # df8 <_entry-0x7ffff208>
                printf("%d ",queue->items[pos]);
    800019b2:	608c                	ld	a1,0(s1)
    800019b4:	854e                	mv	a0,s3
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	bd4080e7          	jalr	-1068(ra) # 8000058a <printf>
            for (int pos = 0; pos < MAX_SIZE; pos++) {
    800019be:	04a1                	addi	s1,s1,8
    800019c0:	ff2499e3          	bne	s1,s2,800019b2 <display+0x34>
            printf("\n");
    800019c4:	8556                	mv	a0,s5
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	bc4080e7          	jalr	-1084(ra) # 8000058a <printf>
    for (int i = 0; i < NUM_QUEUES; i++) {
    800019ce:	20890913          	addi	s2,s2,520
    800019d2:	fd491ee3          	bne	s2,s4,800019ae <display+0x30>

        }
    }
}
    800019d6:	70e2                	ld	ra,56(sp)
    800019d8:	7442                	ld	s0,48(sp)
    800019da:	74a2                	ld	s1,40(sp)
    800019dc:	7902                	ld	s2,32(sp)
    800019de:	69e2                	ld	s3,24(sp)
    800019e0:	6a42                	ld	s4,16(sp)
    800019e2:	6aa2                	ld	s5,8(sp)
    800019e4:	6121                	addi	sp,sp,64
    800019e6:	8082                	ret

00000000800019e8 <dequeueFromMultiCircularQueue>:
void dequeueFromMultiCircularQueue(struct MultiCircularQueue *multiQueue, struct proc * value) {
    800019e8:	7139                	addi	sp,sp,-64
    800019ea:	fc06                	sd	ra,56(sp)
    800019ec:	f822                	sd	s0,48(sp)
    800019ee:	f426                	sd	s1,40(sp)
    800019f0:	f04a                	sd	s2,32(sp)
    800019f2:	ec4e                	sd	s3,24(sp)
    800019f4:	e852                	sd	s4,16(sp)
    800019f6:	e456                	sd	s5,8(sp)
    800019f8:	e05a                	sd	s6,0(sp)
    800019fa:	0080                	addi	s0,sp,64
    800019fc:	8a2a                	mv	s4,a0
    800019fe:	84ae                	mv	s1,a1
    for (int i = 0; i < NUM_QUEUES; i++) {
    80001a00:	8aaa                	mv	s5,a0
    80001a02:	4901                	li	s2,0
        if (!isCircularQueueEmpty(multiQueue, i)) {
            
            struct CircularQueue *queue=&multiQueue->queues[i];
            
            for (int pos = 0; pos < MAX_SIZE; pos++) {
    80001a04:	04100993          	li	s3,65
    for (int i = 0; i < NUM_QUEUES; i++) {
    80001a08:	4b11                	li	s6,4
        if (!isCircularQueueEmpty(multiQueue, i)) {
    80001a0a:	85ca                	mv	a1,s2
    80001a0c:	8552                	mv	a0,s4
    80001a0e:	00000097          	auipc	ra,0x0
    80001a12:	e42080e7          	jalr	-446(ra) # 80001850 <isCircularQueueEmpty>
    80001a16:	c519                	beqz	a0,80001a24 <dequeueFromMultiCircularQueue+0x3c>
    for (int i = 0; i < NUM_QUEUES; i++) {
    80001a18:	2905                	addiw	s2,s2,1
    80001a1a:	208a8a93          	addi	s5,s5,520
    80001a1e:	ff6916e3          	bne	s2,s6,80001a0a <dequeueFromMultiCircularQueue+0x22>
    80001a22:	a015                	j	80001a46 <dequeueFromMultiCircularQueue+0x5e>
    80001a24:	87d6                	mv	a5,s5
                if(queue->items[pos]==value){
    80001a26:	6398                	ld	a4,0(a5)
    80001a28:	00970763          	beq	a4,s1,80001a36 <dequeueFromMultiCircularQueue+0x4e>
            for (int pos = 0; pos < MAX_SIZE; pos++) {
    80001a2c:	2505                	addiw	a0,a0,1
    80001a2e:	07a1                	addi	a5,a5,8
    80001a30:	ff351be3          	bne	a0,s3,80001a26 <dequeueFromMultiCircularQueue+0x3e>
    80001a34:	b7d5                	j	80001a18 <dequeueFromMultiCircularQueue+0x30>
                    // printf("bef %d\n",queue->items[pos]);
                    *&queue->items[pos] = 0;
    80001a36:	00691793          	slli	a5,s2,0x6
    80001a3a:	97ca                	add	a5,a5,s2
    80001a3c:	97aa                	add	a5,a5,a0
    80001a3e:	078e                	slli	a5,a5,0x3
    80001a40:	9a3e                	add	s4,s4,a5
    80001a42:	000a3023          	sd	zero,0(s4)

        }
    }
    // printf("No element found in any queue. Cannot dequeue.\n");
    
}
    80001a46:	70e2                	ld	ra,56(sp)
    80001a48:	7442                	ld	s0,48(sp)
    80001a4a:	74a2                	ld	s1,40(sp)
    80001a4c:	7902                	ld	s2,32(sp)
    80001a4e:	69e2                	ld	s3,24(sp)
    80001a50:	6a42                	ld	s4,16(sp)
    80001a52:	6aa2                	ld	s5,8(sp)
    80001a54:	6b02                	ld	s6,0(sp)
    80001a56:	6121                	addi	sp,sp,64
    80001a58:	8082                	ret

0000000080001a5a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a5a:	7139                	addi	sp,sp,-64
    80001a5c:	fc06                	sd	ra,56(sp)
    80001a5e:	f822                	sd	s0,48(sp)
    80001a60:	f426                	sd	s1,40(sp)
    80001a62:	f04a                	sd	s2,32(sp)
    80001a64:	ec4e                	sd	s3,24(sp)
    80001a66:	e852                	sd	s4,16(sp)
    80001a68:	e456                	sd	s5,8(sp)
    80001a6a:	e05a                	sd	s6,0(sp)
    80001a6c:	0080                	addi	s0,sp,64
    80001a6e:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a70:	00010497          	auipc	s1,0x10
    80001a74:	f9048493          	addi	s1,s1,-112 # 80011a00 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a78:	8b26                	mv	s6,s1
    80001a7a:	00006a97          	auipc	s5,0x6
    80001a7e:	586a8a93          	addi	s5,s5,1414 # 80008000 <etext>
    80001a82:	04000937          	lui	s2,0x4000
    80001a86:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a88:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a8a:	00017a17          	auipc	s4,0x17
    80001a8e:	976a0a13          	addi	s4,s4,-1674 # 80018400 <tickslock>
    char *pa = kalloc();
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	054080e7          	jalr	84(ra) # 80000ae6 <kalloc>
    80001a9a:	862a                	mv	a2,a0
    if (pa == 0)
    80001a9c:	c131                	beqz	a0,80001ae0 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a9e:	416485b3          	sub	a1,s1,s6
    80001aa2:	858d                	srai	a1,a1,0x3
    80001aa4:	000ab783          	ld	a5,0(s5)
    80001aa8:	02f585b3          	mul	a1,a1,a5
    80001aac:	2585                	addiw	a1,a1,1
    80001aae:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ab2:	4719                	li	a4,6
    80001ab4:	6685                	lui	a3,0x1
    80001ab6:	40b905b3          	sub	a1,s2,a1
    80001aba:	854e                	mv	a0,s3
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	682080e7          	jalr	1666(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ac4:	1a848493          	addi	s1,s1,424
    80001ac8:	fd4495e3          	bne	s1,s4,80001a92 <proc_mapstacks+0x38>
  }
}
    80001acc:	70e2                	ld	ra,56(sp)
    80001ace:	7442                	ld	s0,48(sp)
    80001ad0:	74a2                	ld	s1,40(sp)
    80001ad2:	7902                	ld	s2,32(sp)
    80001ad4:	69e2                	ld	s3,24(sp)
    80001ad6:	6a42                	ld	s4,16(sp)
    80001ad8:	6aa2                	ld	s5,8(sp)
    80001ada:	6b02                	ld	s6,0(sp)
    80001adc:	6121                	addi	sp,sp,64
    80001ade:	8082                	ret
      panic("kalloc");
    80001ae0:	00006517          	auipc	a0,0x6
    80001ae4:	73850513          	addi	a0,a0,1848 # 80008218 <digits+0x1d8>
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	a58080e7          	jalr	-1448(ra) # 80000540 <panic>

0000000080001af0 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001af0:	7139                	addi	sp,sp,-64
    80001af2:	fc06                	sd	ra,56(sp)
    80001af4:	f822                	sd	s0,48(sp)
    80001af6:	f426                	sd	s1,40(sp)
    80001af8:	f04a                	sd	s2,32(sp)
    80001afa:	ec4e                	sd	s3,24(sp)
    80001afc:	e852                	sd	s4,16(sp)
    80001afe:	e456                	sd	s5,8(sp)
    80001b00:	e05a                	sd	s6,0(sp)
    80001b02:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001b04:	00006597          	auipc	a1,0x6
    80001b08:	71c58593          	addi	a1,a1,1820 # 80008220 <digits+0x1e0>
    80001b0c:	0000f517          	auipc	a0,0xf
    80001b10:	0e450513          	addi	a0,a0,228 # 80010bf0 <pid_lock>
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	032080e7          	jalr	50(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b1c:	00006597          	auipc	a1,0x6
    80001b20:	70c58593          	addi	a1,a1,1804 # 80008228 <digits+0x1e8>
    80001b24:	0000f517          	auipc	a0,0xf
    80001b28:	0e450513          	addi	a0,a0,228 # 80010c08 <wait_lock>
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	01a080e7          	jalr	26(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001b34:	00010497          	auipc	s1,0x10
    80001b38:	ecc48493          	addi	s1,s1,-308 # 80011a00 <proc>
  {
    initlock(&p->lock, "proc");
    80001b3c:	00006b17          	auipc	s6,0x6
    80001b40:	6fcb0b13          	addi	s6,s6,1788 # 80008238 <digits+0x1f8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001b44:	8aa6                	mv	s5,s1
    80001b46:	00006a17          	auipc	s4,0x6
    80001b4a:	4baa0a13          	addi	s4,s4,1210 # 80008000 <etext>
    80001b4e:	04000937          	lui	s2,0x4000
    80001b52:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b54:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b56:	00017997          	auipc	s3,0x17
    80001b5a:	8aa98993          	addi	s3,s3,-1878 # 80018400 <tickslock>
    initlock(&p->lock, "proc");
    80001b5e:	85da                	mv	a1,s6
    80001b60:	8526                	mv	a0,s1
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	fe4080e7          	jalr	-28(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001b6a:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b6e:	415487b3          	sub	a5,s1,s5
    80001b72:	878d                	srai	a5,a5,0x3
    80001b74:	000a3703          	ld	a4,0(s4)
    80001b78:	02e787b3          	mul	a5,a5,a4
    80001b7c:	2785                	addiw	a5,a5,1
    80001b7e:	00d7979b          	slliw	a5,a5,0xd
    80001b82:	40f907b3          	sub	a5,s2,a5
    80001b86:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b88:	1a848493          	addi	s1,s1,424
    80001b8c:	fd3499e3          	bne	s1,s3,80001b5e <procinit+0x6e>
  }
}
    80001b90:	70e2                	ld	ra,56(sp)
    80001b92:	7442                	ld	s0,48(sp)
    80001b94:	74a2                	ld	s1,40(sp)
    80001b96:	7902                	ld	s2,32(sp)
    80001b98:	69e2                	ld	s3,24(sp)
    80001b9a:	6a42                	ld	s4,16(sp)
    80001b9c:	6aa2                	ld	s5,8(sp)
    80001b9e:	6b02                	ld	s6,0(sp)
    80001ba0:	6121                	addi	sp,sp,64
    80001ba2:	8082                	ret

0000000080001ba4 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001ba4:	1141                	addi	sp,sp,-16
    80001ba6:	e422                	sd	s0,8(sp)
    80001ba8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001baa:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001bac:	2501                	sext.w	a0,a0
    80001bae:	6422                	ld	s0,8(sp)
    80001bb0:	0141                	addi	sp,sp,16
    80001bb2:	8082                	ret

0000000080001bb4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001bb4:	1141                	addi	sp,sp,-16
    80001bb6:	e422                	sd	s0,8(sp)
    80001bb8:	0800                	addi	s0,sp,16
    80001bba:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001bbc:	2781                	sext.w	a5,a5
    80001bbe:	079e                	slli	a5,a5,0x7
  return c;
}
    80001bc0:	0000f517          	auipc	a0,0xf
    80001bc4:	06050513          	addi	a0,a0,96 # 80010c20 <cpus>
    80001bc8:	953e                	add	a0,a0,a5
    80001bca:	6422                	ld	s0,8(sp)
    80001bcc:	0141                	addi	sp,sp,16
    80001bce:	8082                	ret

0000000080001bd0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	1000                	addi	s0,sp,32
  push_off();
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	fb0080e7          	jalr	-80(ra) # 80000b8a <push_off>
    80001be2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001be4:	2781                	sext.w	a5,a5
    80001be6:	079e                	slli	a5,a5,0x7
    80001be8:	0000f717          	auipc	a4,0xf
    80001bec:	00870713          	addi	a4,a4,8 # 80010bf0 <pid_lock>
    80001bf0:	97ba                	add	a5,a5,a4
    80001bf2:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	036080e7          	jalr	54(ra) # 80000c2a <pop_off>
  return p;
}
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	60e2                	ld	ra,24(sp)
    80001c00:	6442                	ld	s0,16(sp)
    80001c02:	64a2                	ld	s1,8(sp)
    80001c04:	6105                	addi	sp,sp,32
    80001c06:	8082                	ret

0000000080001c08 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c08:	1141                	addi	sp,sp,-16
    80001c0a:	e406                	sd	ra,8(sp)
    80001c0c:	e022                	sd	s0,0(sp)
    80001c0e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	fc0080e7          	jalr	-64(ra) # 80001bd0 <myproc>
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	072080e7          	jalr	114(ra) # 80000c8a <release>

  if (first)
    80001c20:	00007797          	auipc	a5,0x7
    80001c24:	cc07a783          	lw	a5,-832(a5) # 800088e0 <first.1>
    80001c28:	eb89                	bnez	a5,80001c3a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c2a:	00001097          	auipc	ra,0x1
    80001c2e:	448080e7          	jalr	1096(ra) # 80003072 <usertrapret>
}
    80001c32:	60a2                	ld	ra,8(sp)
    80001c34:	6402                	ld	s0,0(sp)
    80001c36:	0141                	addi	sp,sp,16
    80001c38:	8082                	ret
    first = 0;
    80001c3a:	00007797          	auipc	a5,0x7
    80001c3e:	ca07a323          	sw	zero,-858(a5) # 800088e0 <first.1>
    fsinit(ROOTDEV);
    80001c42:	4505                	li	a0,1
    80001c44:	00002097          	auipc	ra,0x2
    80001c48:	394080e7          	jalr	916(ra) # 80003fd8 <fsinit>
    80001c4c:	bff9                	j	80001c2a <forkret+0x22>

0000000080001c4e <allocpid>:
{
    80001c4e:	1101                	addi	sp,sp,-32
    80001c50:	ec06                	sd	ra,24(sp)
    80001c52:	e822                	sd	s0,16(sp)
    80001c54:	e426                	sd	s1,8(sp)
    80001c56:	e04a                	sd	s2,0(sp)
    80001c58:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c5a:	0000f917          	auipc	s2,0xf
    80001c5e:	f9690913          	addi	s2,s2,-106 # 80010bf0 <pid_lock>
    80001c62:	854a                	mv	a0,s2
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	f72080e7          	jalr	-142(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001c6c:	00007797          	auipc	a5,0x7
    80001c70:	c7878793          	addi	a5,a5,-904 # 800088e4 <nextpid>
    80001c74:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c76:	0014871b          	addiw	a4,s1,1
    80001c7a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c7c:	854a                	mv	a0,s2
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	00c080e7          	jalr	12(ra) # 80000c8a <release>
}
    80001c86:	8526                	mv	a0,s1
    80001c88:	60e2                	ld	ra,24(sp)
    80001c8a:	6442                	ld	s0,16(sp)
    80001c8c:	64a2                	ld	s1,8(sp)
    80001c8e:	6902                	ld	s2,0(sp)
    80001c90:	6105                	addi	sp,sp,32
    80001c92:	8082                	ret

0000000080001c94 <proc_pagetable>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	e04a                	sd	s2,0(sp)
    80001c9e:	1000                	addi	s0,sp,32
    80001ca0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	686080e7          	jalr	1670(ra) # 80001328 <uvmcreate>
    80001caa:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001cac:	c121                	beqz	a0,80001cec <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cae:	4729                	li	a4,10
    80001cb0:	00005697          	auipc	a3,0x5
    80001cb4:	35068693          	addi	a3,a3,848 # 80007000 <_trampoline>
    80001cb8:	6605                	lui	a2,0x1
    80001cba:	040005b7          	lui	a1,0x4000
    80001cbe:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cc0:	05b2                	slli	a1,a1,0xc
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	3dc080e7          	jalr	988(ra) # 8000109e <mappages>
    80001cca:	02054863          	bltz	a0,80001cfa <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cce:	4719                	li	a4,6
    80001cd0:	05893683          	ld	a3,88(s2)
    80001cd4:	6605                	lui	a2,0x1
    80001cd6:	020005b7          	lui	a1,0x2000
    80001cda:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cdc:	05b6                	slli	a1,a1,0xd
    80001cde:	8526                	mv	a0,s1
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	3be080e7          	jalr	958(ra) # 8000109e <mappages>
    80001ce8:	02054163          	bltz	a0,80001d0a <proc_pagetable+0x76>
}
    80001cec:	8526                	mv	a0,s1
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6902                	ld	s2,0(sp)
    80001cf6:	6105                	addi	sp,sp,32
    80001cf8:	8082                	ret
    uvmfree(pagetable, 0);
    80001cfa:	4581                	li	a1,0
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	830080e7          	jalr	-2000(ra) # 8000152e <uvmfree>
    return 0;
    80001d06:	4481                	li	s1,0
    80001d08:	b7d5                	j	80001cec <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d0a:	4681                	li	a3,0
    80001d0c:	4605                	li	a2,1
    80001d0e:	040005b7          	lui	a1,0x4000
    80001d12:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d14:	05b2                	slli	a1,a1,0xc
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	54c080e7          	jalr	1356(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d20:	4581                	li	a1,0
    80001d22:	8526                	mv	a0,s1
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	80a080e7          	jalr	-2038(ra) # 8000152e <uvmfree>
    return 0;
    80001d2c:	4481                	li	s1,0
    80001d2e:	bf7d                	j	80001cec <proc_pagetable+0x58>

0000000080001d30 <proc_freepagetable>:
{
    80001d30:	1101                	addi	sp,sp,-32
    80001d32:	ec06                	sd	ra,24(sp)
    80001d34:	e822                	sd	s0,16(sp)
    80001d36:	e426                	sd	s1,8(sp)
    80001d38:	e04a                	sd	s2,0(sp)
    80001d3a:	1000                	addi	s0,sp,32
    80001d3c:	84aa                	mv	s1,a0
    80001d3e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d40:	4681                	li	a3,0
    80001d42:	4605                	li	a2,1
    80001d44:	040005b7          	lui	a1,0x4000
    80001d48:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d4a:	05b2                	slli	a1,a1,0xc
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	518080e7          	jalr	1304(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d54:	4681                	li	a3,0
    80001d56:	4605                	li	a2,1
    80001d58:	020005b7          	lui	a1,0x2000
    80001d5c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d5e:	05b6                	slli	a1,a1,0xd
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	502080e7          	jalr	1282(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d6a:	85ca                	mv	a1,s2
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	7c0080e7          	jalr	1984(ra) # 8000152e <uvmfree>
}
    80001d76:	60e2                	ld	ra,24(sp)
    80001d78:	6442                	ld	s0,16(sp)
    80001d7a:	64a2                	ld	s1,8(sp)
    80001d7c:	6902                	ld	s2,0(sp)
    80001d7e:	6105                	addi	sp,sp,32
    80001d80:	8082                	ret

0000000080001d82 <freeproc>:
{
    80001d82:	1101                	addi	sp,sp,-32
    80001d84:	ec06                	sd	ra,24(sp)
    80001d86:	e822                	sd	s0,16(sp)
    80001d88:	e426                	sd	s1,8(sp)
    80001d8a:	1000                	addi	s0,sp,32
    80001d8c:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d8e:	6d28                	ld	a0,88(a0)
    80001d90:	c509                	beqz	a0,80001d9a <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	c56080e7          	jalr	-938(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001d9a:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d9e:	68a8                	ld	a0,80(s1)
    80001da0:	c511                	beqz	a0,80001dac <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001da2:	64ac                	ld	a1,72(s1)
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	f8c080e7          	jalr	-116(ra) # 80001d30 <proc_freepagetable>
  p->pagetable = 0;
    80001dac:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001db0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001db4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001db8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001dbc:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001dc0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001dc4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dc8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001dcc:	0004ac23          	sw	zero,24(s1)
}
    80001dd0:	60e2                	ld	ra,24(sp)
    80001dd2:	6442                	ld	s0,16(sp)
    80001dd4:	64a2                	ld	s1,8(sp)
    80001dd6:	6105                	addi	sp,sp,32
    80001dd8:	8082                	ret

0000000080001dda <allocproc>:
{
    80001dda:	1101                	addi	sp,sp,-32
    80001ddc:	ec06                	sd	ra,24(sp)
    80001dde:	e822                	sd	s0,16(sp)
    80001de0:	e426                	sd	s1,8(sp)
    80001de2:	e04a                	sd	s2,0(sp)
    80001de4:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001de6:	00010497          	auipc	s1,0x10
    80001dea:	c1a48493          	addi	s1,s1,-998 # 80011a00 <proc>
    80001dee:	00016917          	auipc	s2,0x16
    80001df2:	61290913          	addi	s2,s2,1554 # 80018400 <tickslock>
    acquire(&p->lock);
    80001df6:	8526                	mv	a0,s1
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	dde080e7          	jalr	-546(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001e00:	4c9c                	lw	a5,24(s1)
    80001e02:	cf81                	beqz	a5,80001e1a <allocproc+0x40>
      release(&p->lock);
    80001e04:	8526                	mv	a0,s1
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	e84080e7          	jalr	-380(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e0e:	1a848493          	addi	s1,s1,424
    80001e12:	ff2492e3          	bne	s1,s2,80001df6 <allocproc+0x1c>
  return 0;
    80001e16:	4481                	li	s1,0
    80001e18:	a051                	j	80001e9c <allocproc+0xc2>
  p->pid = allocpid();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	e34080e7          	jalr	-460(ra) # 80001c4e <allocpid>
    80001e22:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e24:	4785                	li	a5,1
    80001e26:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e28:	fffff097          	auipc	ra,0xfffff
    80001e2c:	cbe080e7          	jalr	-834(ra) # 80000ae6 <kalloc>
    80001e30:	892a                	mv	s2,a0
    80001e32:	eca8                	sd	a0,88(s1)
    80001e34:	c93d                	beqz	a0,80001eaa <allocproc+0xd0>
  p->pagetable = proc_pagetable(p);
    80001e36:	8526                	mv	a0,s1
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	e5c080e7          	jalr	-420(ra) # 80001c94 <proc_pagetable>
    80001e40:	892a                	mv	s2,a0
    80001e42:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001e44:	cd3d                	beqz	a0,80001ec2 <allocproc+0xe8>
  memset(&p->context, 0, sizeof(p->context));
    80001e46:	07000613          	li	a2,112
    80001e4a:	4581                	li	a1,0
    80001e4c:	06048513          	addi	a0,s1,96
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	e82080e7          	jalr	-382(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001e58:	00000797          	auipc	a5,0x0
    80001e5c:	db078793          	addi	a5,a5,-592 # 80001c08 <forkret>
    80001e60:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e62:	60bc                	ld	a5,64(s1)
    80001e64:	6705                	lui	a4,0x1
    80001e66:	97ba                	add	a5,a5,a4
    80001e68:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e6a:	1804aa23          	sw	zero,404(s1)
  p->r_time = 0;
    80001e6e:	1804ae23          	sw	zero,412(s1)
  p->etime = 0;
    80001e72:	1604a623          	sw	zero,364(s1)
  p->ctime = ticks;
    80001e76:	00007797          	auipc	a5,0x7
    80001e7a:	b0e7a783          	lw	a5,-1266(a5) # 80008984 <ticks>
    80001e7e:	16f4a423          	sw	a5,360(s1)
  p->cur_ticks = 0;         //  sigalarm
    80001e82:	1604ae23          	sw	zero,380(s1)
  p->handler_permission = 1;//  sigalarm
    80001e86:	4705                	li	a4,1
    80001e88:	18e4a423          	sw	a4,392(s1)
  p->p_arrival_time=ticks;
    80001e8c:	18f4a623          	sw	a5,396(s1)
  p->queuenumber=0; //initially at 0 queue
    80001e90:	1804a823          	sw	zero,400(s1)
  p->wtime=0;
    80001e94:	1804ac23          	sw	zero,408(s1)
  p->w_time=0;
    80001e98:	1a04a023          	sw	zero,416(s1)
}
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	60e2                	ld	ra,24(sp)
    80001ea0:	6442                	ld	s0,16(sp)
    80001ea2:	64a2                	ld	s1,8(sp)
    80001ea4:	6902                	ld	s2,0(sp)
    80001ea6:	6105                	addi	sp,sp,32
    80001ea8:	8082                	ret
    freeproc(p);
    80001eaa:	8526                	mv	a0,s1
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	ed6080e7          	jalr	-298(ra) # 80001d82 <freeproc>
    release(&p->lock);
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	dd4080e7          	jalr	-556(ra) # 80000c8a <release>
    return 0;
    80001ebe:	84ca                	mv	s1,s2
    80001ec0:	bff1                	j	80001e9c <allocproc+0xc2>
    freeproc(p);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	ebe080e7          	jalr	-322(ra) # 80001d82 <freeproc>
    release(&p->lock);
    80001ecc:	8526                	mv	a0,s1
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	dbc080e7          	jalr	-580(ra) # 80000c8a <release>
    return 0;
    80001ed6:	84ca                	mv	s1,s2
    80001ed8:	b7d1                	j	80001e9c <allocproc+0xc2>

0000000080001eda <userinit>:
{
    80001eda:	1101                	addi	sp,sp,-32
    80001edc:	ec06                	sd	ra,24(sp)
    80001ede:	e822                	sd	s0,16(sp)
    80001ee0:	e426                	sd	s1,8(sp)
    80001ee2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	ef6080e7          	jalr	-266(ra) # 80001dda <allocproc>
    80001eec:	84aa                	mv	s1,a0
  initproc = p;
    80001eee:	00007797          	auipc	a5,0x7
    80001ef2:	a8a7b523          	sd	a0,-1398(a5) # 80008978 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ef6:	03400613          	li	a2,52
    80001efa:	00007597          	auipc	a1,0x7
    80001efe:	9f658593          	addi	a1,a1,-1546 # 800088f0 <initcode>
    80001f02:	6928                	ld	a0,80(a0)
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	452080e7          	jalr	1106(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001f0c:	6785                	lui	a5,0x1
    80001f0e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001f10:	6cb8                	ld	a4,88(s1)
    80001f12:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001f16:	6cb8                	ld	a4,88(s1)
    80001f18:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f1a:	4641                	li	a2,16
    80001f1c:	00006597          	auipc	a1,0x6
    80001f20:	32458593          	addi	a1,a1,804 # 80008240 <digits+0x200>
    80001f24:	15848513          	addi	a0,s1,344
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	ef4080e7          	jalr	-268(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001f30:	00006517          	auipc	a0,0x6
    80001f34:	32050513          	addi	a0,a0,800 # 80008250 <digits+0x210>
    80001f38:	00003097          	auipc	ra,0x3
    80001f3c:	aca080e7          	jalr	-1334(ra) # 80004a02 <namei>
    80001f40:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f44:	478d                	li	a5,3
    80001f46:	cc9c                	sw	a5,24(s1)
  sahil=1 ; //interrupt new process
    80001f48:	4785                	li	a5,1
    80001f4a:	00007717          	auipc	a4,0x7
    80001f4e:	a2f72b23          	sw	a5,-1482(a4) # 80008980 <sahil>
  release(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d36080e7          	jalr	-714(ra) # 80000c8a <release>
}
    80001f5c:	60e2                	ld	ra,24(sp)
    80001f5e:	6442                	ld	s0,16(sp)
    80001f60:	64a2                	ld	s1,8(sp)
    80001f62:	6105                	addi	sp,sp,32
    80001f64:	8082                	ret

0000000080001f66 <growproc>:
{
    80001f66:	1101                	addi	sp,sp,-32
    80001f68:	ec06                	sd	ra,24(sp)
    80001f6a:	e822                	sd	s0,16(sp)
    80001f6c:	e426                	sd	s1,8(sp)
    80001f6e:	e04a                	sd	s2,0(sp)
    80001f70:	1000                	addi	s0,sp,32
    80001f72:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f74:	00000097          	auipc	ra,0x0
    80001f78:	c5c080e7          	jalr	-932(ra) # 80001bd0 <myproc>
    80001f7c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f7e:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f80:	01204c63          	bgtz	s2,80001f98 <growproc+0x32>
  else if (n < 0)
    80001f84:	02094663          	bltz	s2,80001fb0 <growproc+0x4a>
  p->sz = sz;
    80001f88:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f8a:	4501                	li	a0,0
}
    80001f8c:	60e2                	ld	ra,24(sp)
    80001f8e:	6442                	ld	s0,16(sp)
    80001f90:	64a2                	ld	s1,8(sp)
    80001f92:	6902                	ld	s2,0(sp)
    80001f94:	6105                	addi	sp,sp,32
    80001f96:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f98:	4691                	li	a3,4
    80001f9a:	00b90633          	add	a2,s2,a1
    80001f9e:	6928                	ld	a0,80(a0)
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	470080e7          	jalr	1136(ra) # 80001410 <uvmalloc>
    80001fa8:	85aa                	mv	a1,a0
    80001faa:	fd79                	bnez	a0,80001f88 <growproc+0x22>
      return -1;
    80001fac:	557d                	li	a0,-1
    80001fae:	bff9                	j	80001f8c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fb0:	00b90633          	add	a2,s2,a1
    80001fb4:	6928                	ld	a0,80(a0)
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	412080e7          	jalr	1042(ra) # 800013c8 <uvmdealloc>
    80001fbe:	85aa                	mv	a1,a0
    80001fc0:	b7e1                	j	80001f88 <growproc+0x22>

0000000080001fc2 <fork>:
{
    80001fc2:	7139                	addi	sp,sp,-64
    80001fc4:	fc06                	sd	ra,56(sp)
    80001fc6:	f822                	sd	s0,48(sp)
    80001fc8:	f426                	sd	s1,40(sp)
    80001fca:	f04a                	sd	s2,32(sp)
    80001fcc:	ec4e                	sd	s3,24(sp)
    80001fce:	e852                	sd	s4,16(sp)
    80001fd0:	e456                	sd	s5,8(sp)
    80001fd2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	bfc080e7          	jalr	-1028(ra) # 80001bd0 <myproc>
    80001fdc:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001fde:	00000097          	auipc	ra,0x0
    80001fe2:	dfc080e7          	jalr	-516(ra) # 80001dda <allocproc>
    80001fe6:	10050c63          	beqz	a0,800020fe <fork+0x13c>
    80001fea:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001fec:	048ab603          	ld	a2,72(s5)
    80001ff0:	692c                	ld	a1,80(a0)
    80001ff2:	050ab503          	ld	a0,80(s5)
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	572080e7          	jalr	1394(ra) # 80001568 <uvmcopy>
    80001ffe:	04054863          	bltz	a0,8000204e <fork+0x8c>
  np->sz = p->sz;
    80002002:	048ab783          	ld	a5,72(s5)
    80002006:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    8000200a:	058ab683          	ld	a3,88(s5)
    8000200e:	87b6                	mv	a5,a3
    80002010:	058a3703          	ld	a4,88(s4)
    80002014:	12068693          	addi	a3,a3,288
    80002018:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000201c:	6788                	ld	a0,8(a5)
    8000201e:	6b8c                	ld	a1,16(a5)
    80002020:	6f90                	ld	a2,24(a5)
    80002022:	01073023          	sd	a6,0(a4)
    80002026:	e708                	sd	a0,8(a4)
    80002028:	eb0c                	sd	a1,16(a4)
    8000202a:	ef10                	sd	a2,24(a4)
    8000202c:	02078793          	addi	a5,a5,32
    80002030:	02070713          	addi	a4,a4,32
    80002034:	fed792e3          	bne	a5,a3,80002018 <fork+0x56>
  np->trapframe->a0 = 0;
    80002038:	058a3783          	ld	a5,88(s4)
    8000203c:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80002040:	0d0a8493          	addi	s1,s5,208
    80002044:	0d0a0913          	addi	s2,s4,208
    80002048:	150a8993          	addi	s3,s5,336
    8000204c:	a00d                	j	8000206e <fork+0xac>
    freeproc(np);
    8000204e:	8552                	mv	a0,s4
    80002050:	00000097          	auipc	ra,0x0
    80002054:	d32080e7          	jalr	-718(ra) # 80001d82 <freeproc>
    release(&np->lock);
    80002058:	8552                	mv	a0,s4
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	c30080e7          	jalr	-976(ra) # 80000c8a <release>
    return -1;
    80002062:	597d                	li	s2,-1
    80002064:	a059                	j	800020ea <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80002066:	04a1                	addi	s1,s1,8
    80002068:	0921                	addi	s2,s2,8
    8000206a:	01348b63          	beq	s1,s3,80002080 <fork+0xbe>
    if (p->ofile[i])
    8000206e:	6088                	ld	a0,0(s1)
    80002070:	d97d                	beqz	a0,80002066 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002072:	00003097          	auipc	ra,0x3
    80002076:	026080e7          	jalr	38(ra) # 80005098 <filedup>
    8000207a:	00a93023          	sd	a0,0(s2)
    8000207e:	b7e5                	j	80002066 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002080:	150ab503          	ld	a0,336(s5)
    80002084:	00002097          	auipc	ra,0x2
    80002088:	194080e7          	jalr	404(ra) # 80004218 <idup>
    8000208c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002090:	4641                	li	a2,16
    80002092:	158a8593          	addi	a1,s5,344
    80002096:	158a0513          	addi	a0,s4,344
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	d82080e7          	jalr	-638(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    800020a2:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    800020a6:	8552                	mv	a0,s4
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	be2080e7          	jalr	-1054(ra) # 80000c8a <release>
  acquire(&wait_lock);
    800020b0:	0000f497          	auipc	s1,0xf
    800020b4:	b5848493          	addi	s1,s1,-1192 # 80010c08 <wait_lock>
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	b1c080e7          	jalr	-1252(ra) # 80000bd6 <acquire>
  np->parent = p;
    800020c2:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    800020c6:	8526                	mv	a0,s1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	bc2080e7          	jalr	-1086(ra) # 80000c8a <release>
  acquire(&np->lock);
    800020d0:	8552                	mv	a0,s4
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b04080e7          	jalr	-1276(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    800020e0:	8552                	mv	a0,s4
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	ba8080e7          	jalr	-1112(ra) # 80000c8a <release>
}
    800020ea:	854a                	mv	a0,s2
    800020ec:	70e2                	ld	ra,56(sp)
    800020ee:	7442                	ld	s0,48(sp)
    800020f0:	74a2                	ld	s1,40(sp)
    800020f2:	7902                	ld	s2,32(sp)
    800020f4:	69e2                	ld	s3,24(sp)
    800020f6:	6a42                	ld	s4,16(sp)
    800020f8:	6aa2                	ld	s5,8(sp)
    800020fa:	6121                	addi	sp,sp,64
    800020fc:	8082                	ret
    return -1;
    800020fe:	597d                	li	s2,-1
    80002100:	b7ed                	j	800020ea <fork+0x128>

0000000080002102 <pf>:
void pf(struct proc *p){
    80002102:	1101                	addi	sp,sp,-32
    80002104:	ec06                	sd	ra,24(sp)
    80002106:	e822                	sd	s0,16(sp)
    80002108:	e426                	sd	s1,8(sp)
    8000210a:	1000                	addi	s0,sp,32
    8000210c:	84aa                	mv	s1,a0
  allpid[p->pid]=0;
    8000210e:	5918                	lw	a4,48(a0)
    80002110:	070a                	slli	a4,a4,0x2
    80002112:	0000f797          	auipc	a5,0xf
    80002116:	ade78793          	addi	a5,a5,-1314 # 80010bf0 <pid_lock>
    8000211a:	97ba                	add	a5,a5,a4
    8000211c:	4207a823          	sw	zero,1072(a5)
  dequeueFromMultiCircularQueue(&multiQueue, p); //remove proc from queue
    80002120:	85aa                	mv	a1,a0
    80002122:	0000f517          	auipc	a0,0xf
    80002126:	08e50513          	addi	a0,a0,142 # 800111b0 <multiQueue>
    8000212a:	00000097          	auipc	ra,0x0
    8000212e:	8be080e7          	jalr	-1858(ra) # 800019e8 <dequeueFromMultiCircularQueue>
  printf(" %d- %d-\n",p->state,p->pid);
    80002132:	5890                	lw	a2,48(s1)
    80002134:	4c8c                	lw	a1,24(s1)
    80002136:	00006517          	auipc	a0,0x6
    8000213a:	12250513          	addi	a0,a0,290 # 80008258 <digits+0x218>
    8000213e:	ffffe097          	auipc	ra,0xffffe
    80002142:	44c080e7          	jalr	1100(ra) # 8000058a <printf>
}
    80002146:	60e2                	ld	ra,24(sp)
    80002148:	6442                	ld	s0,16(sp)
    8000214a:	64a2                	ld	s1,8(sp)
    8000214c:	6105                	addi	sp,sp,32
    8000214e:	8082                	ret

0000000080002150 <initpid>:
void initpid(){
    80002150:	1141                	addi	sp,sp,-16
    80002152:	e422                	sd	s0,8(sp)
    80002154:	0800                	addi	s0,sp,16
  for(int i=0;i<100;i=i+1){allpid[i]=0;}
    80002156:	0000f797          	auipc	a5,0xf
    8000215a:	eca78793          	addi	a5,a5,-310 # 80011020 <allpid>
    8000215e:	0000f717          	auipc	a4,0xf
    80002162:	05270713          	addi	a4,a4,82 # 800111b0 <multiQueue>
    80002166:	0007a023          	sw	zero,0(a5)
    8000216a:	0791                	addi	a5,a5,4
    8000216c:	fee79de3          	bne	a5,a4,80002166 <initpid+0x16>
}
    80002170:	6422                	ld	s0,8(sp)
    80002172:	0141                	addi	sp,sp,16
    80002174:	8082                	ret

0000000080002176 <scheduler>:
{
    80002176:	7119                	addi	sp,sp,-128
    80002178:	fc86                	sd	ra,120(sp)
    8000217a:	f8a2                	sd	s0,112(sp)
    8000217c:	f4a6                	sd	s1,104(sp)
    8000217e:	f0ca                	sd	s2,96(sp)
    80002180:	ecce                	sd	s3,88(sp)
    80002182:	e8d2                	sd	s4,80(sp)
    80002184:	e4d6                	sd	s5,72(sp)
    80002186:	e0da                	sd	s6,64(sp)
    80002188:	fc5e                	sd	s7,56(sp)
    8000218a:	f862                	sd	s8,48(sp)
    8000218c:	f466                	sd	s9,40(sp)
    8000218e:	f06a                	sd	s10,32(sp)
    80002190:	ec6e                	sd	s11,24(sp)
    80002192:	0100                	addi	s0,sp,128
  initpid();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	fbc080e7          	jalr	-68(ra) # 80002150 <initpid>
    printf("MLFQ\n");
    8000219c:	00006517          	auipc	a0,0x6
    800021a0:	0cc50513          	addi	a0,a0,204 # 80008268 <digits+0x228>
    800021a4:	ffffe097          	auipc	ra,0xffffe
    800021a8:	3e6080e7          	jalr	998(ra) # 8000058a <printf>
    800021ac:	8792                	mv	a5,tp
  int id = r_tp();
    800021ae:	2781                	sext.w	a5,a5
    c->proc = 0;
    800021b0:	00779693          	slli	a3,a5,0x7
    800021b4:	0000f717          	auipc	a4,0xf
    800021b8:	a3c70713          	addi	a4,a4,-1476 # 80010bf0 <pid_lock>
    800021bc:	9736                	add	a4,a4,a3
    800021be:	02073823          	sd	zero,48(a4)
              swtch(&c->context, &p->context); // do 1 quantum tick
    800021c2:	0000f717          	auipc	a4,0xf
    800021c6:	a6670713          	addi	a4,a4,-1434 # 80010c28 <cpus+0x8>
    800021ca:	9736                	add	a4,a4,a3
    800021cc:	f8e43023          	sd	a4,-128(s0)
        if (p->state == RUNNABLE &&allpid[p->pid]==0)
    800021d0:	0000f997          	auipc	s3,0xf
    800021d4:	a2098993          	addi	s3,s3,-1504 # 80010bf0 <pid_lock>
            allpid[p->pid]=1;
    800021d8:	4a05                	li	s4,1
              c->proc = p;
    800021da:	00d987b3          	add	a5,s3,a3
    800021de:	f8f43423          	sd	a5,-120(s0)
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    800021e2:	0000fb17          	auipc	s6,0xf
    800021e6:	fceb0b13          	addi	s6,s6,-50 # 800111b0 <multiQueue>
      for (p = proc; p < &proc[NPROC]; p++){
    800021ea:	00016497          	auipc	s1,0x16
    800021ee:	21648493          	addi	s1,s1,534 # 80018400 <tickslock>
    800021f2:	a8d5                	j	800022e6 <scheduler+0x170>
        release(&p->lock);  //got all runnable right now ,including new swapns
    800021f4:	854a                	mv	a0,s2
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	a94080e7          	jalr	-1388(ra) # 80000c8a <release>
      for (p = proc; p < &proc[NPROC]; p++){
    800021fe:	1a890913          	addi	s2,s2,424
    80002202:	02990e63          	beq	s2,s1,8000223e <scheduler+0xc8>
         acquire(&p->lock);
    80002206:	854a                	mv	a0,s2
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	9ce080e7          	jalr	-1586(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE &&allpid[p->pid]==0)
    80002210:	01892783          	lw	a5,24(s2)
    80002214:	ff5790e3          	bne	a5,s5,800021f4 <scheduler+0x7e>
    80002218:	03092703          	lw	a4,48(s2)
    8000221c:	00271793          	slli	a5,a4,0x2
    80002220:	97ce                	add	a5,a5,s3
    80002222:	4307a783          	lw	a5,1072(a5)
    80002226:	f7f9                	bnez	a5,800021f4 <scheduler+0x7e>
            allpid[p->pid]=1;
    80002228:	070a                	slli	a4,a4,0x2
    8000222a:	974e                	add	a4,a4,s3
    8000222c:	43472823          	sw	s4,1072(a4)
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    80002230:	85ca                	mv	a1,s2
    80002232:	855a                	mv	a0,s6
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	676080e7          	jalr	1654(ra) # 800018aa <enqueueToCircularQueue>
}
    8000223c:	bf65                	j	800021f4 <scheduler+0x7e>
      if(isCircularQueueEmpty(&multiQueue,0)!=1){
    8000223e:	4581                	li	a1,0
    80002240:	855a                	mv	a0,s6
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	60e080e7          	jalr	1550(ra) # 80001850 <isCircularQueueEmpty>
    8000224a:	05451e63          	bne	a0,s4,800022a6 <scheduler+0x130>
      else if(isCircularQueueEmpty(&multiQueue,1)!=1){//queue 0 ,absent
    8000224e:	85d2                	mv	a1,s4
    80002250:	855a                	mv	a0,s6
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	5fe080e7          	jalr	1534(ra) # 80001850 <isCircularQueueEmpty>
    8000225a:	17451063          	bne	a0,s4,800023ba <scheduler+0x244>
      else if(isCircularQueueEmpty(&multiQueue,2)!=1){ //go q2 
    8000225e:	4589                	li	a1,2
    80002260:	855a                	mv	a0,s6
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	5ee080e7          	jalr	1518(ra) # 80001850 <isCircularQueueEmpty>
    8000226a:	27451863          	bne	a0,s4,800024da <scheduler+0x364>
      else if(isCircularQueueEmpty(&multiQueue,3)!=1){ //go q 3 
    8000226e:	458d                	li	a1,3
    80002270:	855a                	mv	a0,s6
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	5de080e7          	jalr	1502(ra) # 80001850 <isCircularQueueEmpty>
    8000227a:	07450663          	beq	a0,s4,800022e6 <scheduler+0x170>
    8000227e:	0000fa97          	auipc	s5,0xf
    80002282:	54aa8a93          	addi	s5,s5,1354 # 800117c8 <multiQueue+0x618>
    80002286:	0000fd17          	auipc	s10,0xf
    8000228a:	74ad0d13          	addi	s10,s10,1866 # 800119d0 <queuemaxindex>
            if(sahil==1){
    8000228e:	00006c97          	auipc	s9,0x6
    80002292:	6f2c8c93          	addi	s9,s9,1778 # 80008980 <sahil>
            if(ticks% agetime==0){ // %100
    80002296:	00006c17          	auipc	s8,0x6
    8000229a:	6eec0c13          	addi	s8,s8,1774 # 80008984 <ticks>
    8000229e:	06400b93          	li	s7,100
            if (p->state == RUNNABLE)
    800022a2:	4d8d                	li	s11,3
    800022a4:	a65d                	j	8000264a <scheduler+0x4d4>
    800022a6:	0000fa97          	auipc	s5,0xf
    800022aa:	f0aa8a93          	addi	s5,s5,-246 # 800111b0 <multiQueue>
    800022ae:	0000fd17          	auipc	s10,0xf
    800022b2:	10ad0d13          	addi	s10,s10,266 # 800113b8 <multiQueue+0x208>
            if(sahil==1){
    800022b6:	00006b97          	auipc	s7,0x6
    800022ba:	6cab8b93          	addi	s7,s7,1738 # 80008980 <sahil>
            if(ticks% agetime==0){ // %100
    800022be:	00006c97          	auipc	s9,0x6
    800022c2:	6c6c8c93          	addi	s9,s9,1734 # 80008984 <ticks>
    800022c6:	06400c13          	li	s8,100
            if (p->state == RUNNABLE)
    800022ca:	4d8d                	li	s11,3
    800022cc:	a841                	j	8000235c <scheduler+0x1e6>
              printf("--\n");
    800022ce:	00006517          	auipc	a0,0x6
    800022d2:	fa250513          	addi	a0,a0,-94 # 80008270 <digits+0x230>
    800022d6:	ffffe097          	auipc	ra,0xffffe
    800022da:	2b4080e7          	jalr	692(ra) # 8000058a <printf>
              sahil=0;
    800022de:	00006797          	auipc	a5,0x6
    800022e2:	6a07a123          	sw	zero,1698(a5) # 80008980 <sahil>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022ee:	10079073          	csrw	sstatus,a5
      for (p = proc; p < &proc[NPROC]; p++){
    800022f2:	0000f917          	auipc	s2,0xf
    800022f6:	70e90913          	addi	s2,s2,1806 # 80011a00 <proc>
        if (p->state == RUNNABLE &&allpid[p->pid]==0)
    800022fa:	4a8d                	li	s5,3
    800022fc:	b729                	j	80002206 <scheduler+0x90>
              p->state = RUNNING;
    800022fe:	4791                	li	a5,4
    80002300:	00f92c23          	sw	a5,24(s2)
              c->proc = p;
    80002304:	f8843783          	ld	a5,-120(s0)
    80002308:	0327b823          	sd	s2,48(a5)
              swtch(&c->context, &p->context); // do 1 quantum tick
    8000230c:	06090593          	addi	a1,s2,96
    80002310:	f8043503          	ld	a0,-128(s0)
    80002314:	00001097          	auipc	ra,0x1
    80002318:	cb4080e7          	jalr	-844(ra) # 80002fc8 <swtch>
              c->proc = 0;
    8000231c:	f8843783          	ld	a5,-120(s0)
    80002320:	0207b823          	sd	zero,48(a5)
    80002324:	a09d                	j	8000238a <scheduler+0x214>
                dequeueFromMultiCircularQueue(&multiQueue, p);
    80002326:	85ca                	mv	a1,s2
    80002328:	855a                	mv	a0,s6
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	6be080e7          	jalr	1726(ra) # 800019e8 <dequeueFromMultiCircularQueue>
                p->rtime=0; //start rtime 0 in new queue
    80002332:	18092a23          	sw	zero,404(s2)
                p->wtime=0;
    80002336:	18092c23          	sw	zero,408(s2)
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    8000233a:	85ca                	mv	a1,s2
    8000233c:	0000f517          	auipc	a0,0xf
    80002340:	07c50513          	addi	a0,a0,124 # 800113b8 <multiQueue+0x208>
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	566080e7          	jalr	1382(ra) # 800018aa <enqueueToCircularQueue>
            release(&p->lock);
    8000234c:	854a                	mv	a0,s2
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	93c080e7          	jalr	-1732(ra) # 80000c8a <release>
          for (int pos=0; pos<MAX_SIZE; pos++) ////
    80002356:	0aa1                	addi	s5,s5,8
    80002358:	f9aa87e3          	beq	s5,s10,800022e6 <scheduler+0x170>
            if(sahil==1){
    8000235c:	000ba783          	lw	a5,0(s7)
    80002360:	f74787e3          	beq	a5,s4,800022ce <scheduler+0x158>
            if(ticks% agetime==0){ // %100
    80002364:	000ca783          	lw	a5,0(s9)
    80002368:	0387f7bb          	remuw	a5,a5,s8
    8000236c:	38078d63          	beqz	a5,80002706 <scheduler+0x590>
            p=queue->items[pos]; //proc *p
    80002370:	000ab903          	ld	s2,0(s5)
            if(p==0){continue;} //no process at pos
    80002374:	fe0901e3          	beqz	s2,80002356 <scheduler+0x1e0>
            acquire(&p->lock);
    80002378:	854a                	mv	a0,s2
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	85c080e7          	jalr	-1956(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE)
    80002382:	01892783          	lw	a5,24(s2)
    80002386:	f7b78ce3          	beq	a5,s11,800022fe <scheduler+0x188>
            release(&p->lock);
    8000238a:	854a                	mv	a0,s2
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8fe080e7          	jalr	-1794(ra) # 80000c8a <release>
            acquire(&p->lock);
    80002394:	854a                	mv	a0,s2
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	840080e7          	jalr	-1984(ra) # 80000bd6 <acquire>
            if((p->rtime > maxtick[0] ) || (p->state==SLEEPING && p->wtime>1)){ //remove from q 0 ,push que 1
    8000239e:	19492783          	lw	a5,404(s2)
    800023a2:	f8fa42e3          	blt	s4,a5,80002326 <scheduler+0x1b0>
    800023a6:	01892703          	lw	a4,24(s2)
    800023aa:	4789                	li	a5,2
    800023ac:	faf710e3          	bne	a4,a5,8000234c <scheduler+0x1d6>
    800023b0:	19892783          	lw	a5,408(s2)
    800023b4:	f6fa49e3          	blt	s4,a5,80002326 <scheduler+0x1b0>
    800023b8:	bf51                	j	8000234c <scheduler+0x1d6>
    800023ba:	0000fa97          	auipc	s5,0xf
    800023be:	ffea8a93          	addi	s5,s5,-2 # 800113b8 <multiQueue+0x208>
    800023c2:	0000fd97          	auipc	s11,0xf
    800023c6:	1fed8d93          	addi	s11,s11,510 # 800115c0 <multiQueue+0x410>
            if(sahil==1){
    800023ca:	00006c17          	auipc	s8,0x6
    800023ce:	5b6c0c13          	addi	s8,s8,1462 # 80008980 <sahil>
            if(ticks% agetime==0){ // %100
    800023d2:	00006d17          	auipc	s10,0x6
    800023d6:	5b2d0d13          	addi	s10,s10,1458 # 80008984 <ticks>
    800023da:	06400c93          	li	s9,100
            if (p->state == RUNNABLE)
    800023de:	4b8d                	li	s7,3
    800023e0:	a8a5                	j	80002458 <scheduler+0x2e2>
              printf("--\n");
    800023e2:	00006517          	auipc	a0,0x6
    800023e6:	e8e50513          	addi	a0,a0,-370 # 80008270 <digits+0x230>
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	1a0080e7          	jalr	416(ra) # 8000058a <printf>
              sahil=0;
    800023f2:	00006797          	auipc	a5,0x6
    800023f6:	5807a723          	sw	zero,1422(a5) # 80008980 <sahil>
              break;  //goto top after 1 tick ,unexplored new process arrived
    800023fa:	b5f5                	j	800022e6 <scheduler+0x170>
              p->state = RUNNING;
    800023fc:	4791                	li	a5,4
    800023fe:	00f92c23          	sw	a5,24(s2)
              c->proc = p;
    80002402:	f8843783          	ld	a5,-120(s0)
    80002406:	0327b823          	sd	s2,48(a5)
              swtch(&c->context, &p->context); // do 1 quantum tick
    8000240a:	06090593          	addi	a1,s2,96
    8000240e:	f8043503          	ld	a0,-128(s0)
    80002412:	00001097          	auipc	ra,0x1
    80002416:	bb6080e7          	jalr	-1098(ra) # 80002fc8 <swtch>
              c->proc = 0;
    8000241a:	f8843783          	ld	a5,-120(s0)
    8000241e:	0207b823          	sd	zero,48(a5)
    80002422:	a095                	j	80002486 <scheduler+0x310>
            if((p->rtime > maxtick[1] && p->state==RUNNABLE) || (p->state==SLEEPING && p->wtime>1)){ //remove from q 0 ,push que 1
    80002424:	19892783          	lw	a5,408(s2)
    80002428:	02fa5563          	bge	s4,a5,80002452 <scheduler+0x2dc>
                dequeueFromMultiCircularQueue(&multiQueue, p);
    8000242c:	85ca                	mv	a1,s2
    8000242e:	855a                	mv	a0,s6
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	5b8080e7          	jalr	1464(ra) # 800019e8 <dequeueFromMultiCircularQueue>
                p->rtime=0; //start rtime 0 in new queue
    80002438:	18092a23          	sw	zero,404(s2)
                p->wtime=0;
    8000243c:	18092c23          	sw	zero,408(s2)
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    80002440:	85ca                	mv	a1,s2
    80002442:	0000f517          	auipc	a0,0xf
    80002446:	17e50513          	addi	a0,a0,382 # 800115c0 <multiQueue+0x410>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	460080e7          	jalr	1120(ra) # 800018aa <enqueueToCircularQueue>
          for (int pos=0; pos<MAX_SIZE; pos++)
    80002452:	0aa1                	addi	s5,s5,8
    80002454:	e9ba89e3          	beq	s5,s11,800022e6 <scheduler+0x170>
            if(sahil==1){
    80002458:	000c2783          	lw	a5,0(s8)
    8000245c:	f94783e3          	beq	a5,s4,800023e2 <scheduler+0x26c>
            if(ticks% agetime==0){ // %100
    80002460:	000d2783          	lw	a5,0(s10)
    80002464:	0397f7bb          	remuw	a5,a5,s9
    80002468:	28078f63          	beqz	a5,80002706 <scheduler+0x590>
            p=queue->items[pos]; //proc *p
    8000246c:	000ab903          	ld	s2,0(s5)
            if(p==0){continue;}  //no process at pos
    80002470:	fe0901e3          	beqz	s2,80002452 <scheduler+0x2dc>
            acquire(&p->lock);
    80002474:	854a                	mv	a0,s2
    80002476:	ffffe097          	auipc	ra,0xffffe
    8000247a:	760080e7          	jalr	1888(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE)
    8000247e:	01892783          	lw	a5,24(s2)
    80002482:	f7778de3          	beq	a5,s7,800023fc <scheduler+0x286>
            release(&p->lock);
    80002486:	854a                	mv	a0,s2
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	802080e7          	jalr	-2046(ra) # 80000c8a <release>
            if((p->rtime > maxtick[1] && p->state==RUNNABLE) || (p->state==SLEEPING && p->wtime>1)){ //remove from q 0 ,push que 1
    80002490:	19492783          	lw	a5,404(s2)
    80002494:	00fbd663          	bge	s7,a5,800024a0 <scheduler+0x32a>
    80002498:	01892783          	lw	a5,24(s2)
    8000249c:	f97788e3          	beq	a5,s7,8000242c <scheduler+0x2b6>
    800024a0:	01892783          	lw	a5,24(s2)
    800024a4:	4709                	li	a4,2
    800024a6:	f6e78fe3          	beq	a5,a4,80002424 <scheduler+0x2ae>
            else if((p->wtime > 12 && p->state==RUNNABLE) ){ //remove from q 1 ,push que0
    800024aa:	19892683          	lw	a3,408(s2)
    800024ae:	4731                	li	a4,12
    800024b0:	fad751e3          	bge	a4,a3,80002452 <scheduler+0x2dc>
    800024b4:	f9779fe3          	bne	a5,s7,80002452 <scheduler+0x2dc>
                dequeueFromMultiCircularQueue(&multiQueue, p);
    800024b8:	85ca                	mv	a1,s2
    800024ba:	855a                	mv	a0,s6
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	52c080e7          	jalr	1324(ra) # 800019e8 <dequeueFromMultiCircularQueue>
                p->wtime=0; //start rtime 0 in new queue
    800024c4:	18092c23          	sw	zero,408(s2)
                p->rtime=0;
    800024c8:	18092a23          	sw	zero,404(s2)
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    800024cc:	85ca                	mv	a1,s2
    800024ce:	855a                	mv	a0,s6
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	3da080e7          	jalr	986(ra) # 800018aa <enqueueToCircularQueue>
}
    800024d8:	bfad                	j	80002452 <scheduler+0x2dc>
    800024da:	0000fa97          	auipc	s5,0xf
    800024de:	0e6a8a93          	addi	s5,s5,230 # 800115c0 <multiQueue+0x410>
    800024e2:	0000fd97          	auipc	s11,0xf
    800024e6:	2e6d8d93          	addi	s11,s11,742 # 800117c8 <multiQueue+0x618>
            if(sahil==1){
    800024ea:	00006c17          	auipc	s8,0x6
    800024ee:	496c0c13          	addi	s8,s8,1174 # 80008980 <sahil>
            if(ticks% agetime==0){ // %100
    800024f2:	00006d17          	auipc	s10,0x6
    800024f6:	492d0d13          	addi	s10,s10,1170 # 80008984 <ticks>
    800024fa:	06400c93          	li	s9,100
            if (p->state == RUNNABLE)
    800024fe:	4b8d                	li	s7,3
    80002500:	a8a5                	j	80002578 <scheduler+0x402>
              printf("--\n");
    80002502:	00006517          	auipc	a0,0x6
    80002506:	d6e50513          	addi	a0,a0,-658 # 80008270 <digits+0x230>
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	080080e7          	jalr	128(ra) # 8000058a <printf>
              sahil=0;
    80002512:	00006797          	auipc	a5,0x6
    80002516:	4607a723          	sw	zero,1134(a5) # 80008980 <sahil>
              break;  //goto top after 1 tick ,unexplored new process arrived
    8000251a:	b3f1                	j	800022e6 <scheduler+0x170>
              p->state = RUNNING;
    8000251c:	4791                	li	a5,4
    8000251e:	00f92c23          	sw	a5,24(s2)
              c->proc = p;
    80002522:	f8843783          	ld	a5,-120(s0)
    80002526:	0327b823          	sd	s2,48(a5)
              swtch(&c->context, &p->context); // do 1 quantum tick
    8000252a:	06090593          	addi	a1,s2,96
    8000252e:	f8043503          	ld	a0,-128(s0)
    80002532:	00001097          	auipc	ra,0x1
    80002536:	a96080e7          	jalr	-1386(ra) # 80002fc8 <swtch>
              c->proc = 0;
    8000253a:	f8843783          	ld	a5,-120(s0)
    8000253e:	0207b823          	sd	zero,48(a5)
    80002542:	a095                	j	800025a6 <scheduler+0x430>
            if((p->rtime > maxtick[2] && p->state==RUNNABLE) || (p->state==SLEEPING && p->wtime>3)){ //remove from q 0 ,push que 1
    80002544:	19892783          	lw	a5,408(s2)
    80002548:	02fbd563          	bge	s7,a5,80002572 <scheduler+0x3fc>
                dequeueFromMultiCircularQueue(&multiQueue, p);
    8000254c:	85ca                	mv	a1,s2
    8000254e:	855a                	mv	a0,s6
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	498080e7          	jalr	1176(ra) # 800019e8 <dequeueFromMultiCircularQueue>
                p->rtime=0; //start rtime 0 in new queue
    80002558:	18092a23          	sw	zero,404(s2)
                p->wtime=0;
    8000255c:	18092c23          	sw	zero,408(s2)
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    80002560:	85ca                	mv	a1,s2
    80002562:	0000f517          	auipc	a0,0xf
    80002566:	26650513          	addi	a0,a0,614 # 800117c8 <multiQueue+0x618>
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	340080e7          	jalr	832(ra) # 800018aa <enqueueToCircularQueue>
          for (int pos=0; pos<MAX_SIZE; pos++)
    80002572:	0aa1                	addi	s5,s5,8
    80002574:	d7ba89e3          	beq	s5,s11,800022e6 <scheduler+0x170>
            if(sahil==1){
    80002578:	000c2783          	lw	a5,0(s8)
    8000257c:	f94783e3          	beq	a5,s4,80002502 <scheduler+0x38c>
            if(ticks% agetime==0){ // %100
    80002580:	000d2783          	lw	a5,0(s10)
    80002584:	0397f7bb          	remuw	a5,a5,s9
    80002588:	16078f63          	beqz	a5,80002706 <scheduler+0x590>
            p=queue->items[pos]; //proc *p
    8000258c:	000ab903          	ld	s2,0(s5)
            if(p==0){continue;}  //no process at pos
    80002590:	fe0901e3          	beqz	s2,80002572 <scheduler+0x3fc>
            acquire(&p->lock);
    80002594:	854a                	mv	a0,s2
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	640080e7          	jalr	1600(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE)
    8000259e:	01892783          	lw	a5,24(s2)
    800025a2:	f7778de3          	beq	a5,s7,8000251c <scheduler+0x3a6>
            release(&p->lock);
    800025a6:	854a                	mv	a0,s2
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	6e2080e7          	jalr	1762(ra) # 80000c8a <release>
            if((p->rtime > maxtick[2] && p->state==RUNNABLE) || (p->state==SLEEPING && p->wtime>3)){ //remove from q 0 ,push que 1
    800025b0:	19492703          	lw	a4,404(s2)
    800025b4:	47a5                	li	a5,9
    800025b6:	00e7d663          	bge	a5,a4,800025c2 <scheduler+0x44c>
    800025ba:	01892783          	lw	a5,24(s2)
    800025be:	f97787e3          	beq	a5,s7,8000254c <scheduler+0x3d6>
    800025c2:	01892783          	lw	a5,24(s2)
    800025c6:	4709                	li	a4,2
    800025c8:	f6e78ee3          	beq	a5,a4,80002544 <scheduler+0x3ce>
            else if(p->wtime > 30 && p->state==RUNNABLE  ){ //remove from q 2 ,push que 1 //18
    800025cc:	19892683          	lw	a3,408(s2)
    800025d0:	4779                	li	a4,30
    800025d2:	fad750e3          	bge	a4,a3,80002572 <scheduler+0x3fc>
    800025d6:	f9779ee3          	bne	a5,s7,80002572 <scheduler+0x3fc>
                dequeueFromMultiCircularQueue(&multiQueue, p);
    800025da:	85ca                	mv	a1,s2
    800025dc:	855a                	mv	a0,s6
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	40a080e7          	jalr	1034(ra) # 800019e8 <dequeueFromMultiCircularQueue>
                p->wtime=0; //start rtime 0 in new queue
    800025e6:	18092c23          	sw	zero,408(s2)
                p->rtime=0;
    800025ea:	18092a23          	sw	zero,404(s2)
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    800025ee:	85ca                	mv	a1,s2
    800025f0:	0000f517          	auipc	a0,0xf
    800025f4:	dc850513          	addi	a0,a0,-568 # 800113b8 <multiQueue+0x208>
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	2b2080e7          	jalr	690(ra) # 800018aa <enqueueToCircularQueue>
}
    80002600:	bf8d                	j	80002572 <scheduler+0x3fc>
              printf("--\n");
    80002602:	00006517          	auipc	a0,0x6
    80002606:	c6e50513          	addi	a0,a0,-914 # 80008270 <digits+0x230>
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	f80080e7          	jalr	-128(ra) # 8000058a <printf>
              sahil=0;
    80002612:	00006797          	auipc	a5,0x6
    80002616:	3607a723          	sw	zero,878(a5) # 80008980 <sahil>
              break;  //goto top after 1 tick ,unexplored new process arrived
    8000261a:	b1f1                	j	800022e6 <scheduler+0x170>
              p->state = RUNNING;
    8000261c:	4791                	li	a5,4
    8000261e:	00f92c23          	sw	a5,24(s2)
              c->proc = p;
    80002622:	f8843783          	ld	a5,-120(s0)
    80002626:	0327b823          	sd	s2,48(a5)
              swtch(&c->context, &p->context); // do 1 quantum tick
    8000262a:	06090593          	addi	a1,s2,96
    8000262e:	f8043503          	ld	a0,-128(s0)
    80002632:	00001097          	auipc	ra,0x1
    80002636:	996080e7          	jalr	-1642(ra) # 80002fc8 <swtch>
              c->proc = 0;
    8000263a:	f8843783          	ld	a5,-120(s0)
    8000263e:	0207b823          	sd	zero,48(a5)
    80002642:	a815                	j	80002676 <scheduler+0x500>
          for (int pos=0; pos<MAX_SIZE; pos++)
    80002644:	0aa1                	addi	s5,s5,8
    80002646:	cbaa80e3          	beq	s5,s10,800022e6 <scheduler+0x170>
            if(sahil==1){
    8000264a:	000ca783          	lw	a5,0(s9)
    8000264e:	fb478ae3          	beq	a5,s4,80002602 <scheduler+0x48c>
            if(ticks% agetime==0){ // %100
    80002652:	000c2783          	lw	a5,0(s8)
    80002656:	0377f7bb          	remuw	a5,a5,s7
    8000265a:	c7d5                	beqz	a5,80002706 <scheduler+0x590>
            p=queue->items[pos]; //proc *p
    8000265c:	000ab903          	ld	s2,0(s5)
            if(p==0){continue;}  //no process at pos
    80002660:	fe0902e3          	beqz	s2,80002644 <scheduler+0x4ce>
            acquire(&p->lock);
    80002664:	854a                	mv	a0,s2
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	570080e7          	jalr	1392(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE)
    8000266e:	01892783          	lw	a5,24(s2)
    80002672:	fbb785e3          	beq	a5,s11,8000261c <scheduler+0x4a6>
            release(&p->lock);
    80002676:	854a                	mv	a0,s2
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	612080e7          	jalr	1554(ra) # 80000c8a <release>
            if(p->wtime > 40 && p->state==RUNNABLE  ){ //remove from q 3 ,push que 2
    80002680:	19892703          	lw	a4,408(s2)
    80002684:	02800793          	li	a5,40
    80002688:	fae7dee3          	bge	a5,a4,80002644 <scheduler+0x4ce>
    8000268c:	01892783          	lw	a5,24(s2)
    80002690:	fbb79ae3          	bne	a5,s11,80002644 <scheduler+0x4ce>
                dequeueFromMultiCircularQueue(&multiQueue, p);
    80002694:	85ca                	mv	a1,s2
    80002696:	855a                	mv	a0,s6
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	350080e7          	jalr	848(ra) # 800019e8 <dequeueFromMultiCircularQueue>
                p->wtime=0; //start rtime 0 in new queue
    800026a0:	18092c23          	sw	zero,408(s2)
                p->rtime=0;
    800026a4:	18092a23          	sw	zero,404(s2)
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    800026a8:	85ca                	mv	a1,s2
    800026aa:	0000f517          	auipc	a0,0xf
    800026ae:	f1650513          	addi	a0,a0,-234 # 800115c0 <multiQueue+0x410>
    800026b2:	fffff097          	auipc	ra,0xfffff
    800026b6:	1f8080e7          	jalr	504(ra) # 800018aa <enqueueToCircularQueue>
}
    800026ba:	b769                	j	80002644 <scheduler+0x4ce>
            release(&p->lock);  //got all runnable right now ,including new swapns
    800026bc:	8526                	mv	a0,s1
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	5cc080e7          	jalr	1484(ra) # 80000c8a <release>
          for (int pos=0; pos<MAX_SIZE; pos++)
    800026c6:	0921                	addi	s2,s2,8
    800026c8:	b1590de3          	beq	s2,s5,800021e2 <scheduler+0x6c>
            p=queue->items[pos]; //proc *p
    800026cc:	00093483          	ld	s1,0(s2)
            if(p==0){continue;}  //no process at pos
    800026d0:	d8fd                	beqz	s1,800026c6 <scheduler+0x550>
            acquire(&p->lock);
    800026d2:	8526                	mv	a0,s1
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	502080e7          	jalr	1282(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE ||p->state==SLEEPING)
    800026dc:	4c9c                	lw	a5,24(s1)
    800026de:	37f9                	addiw	a5,a5,-2
    800026e0:	fcfa6ee3          	bltu	s4,a5,800026bc <scheduler+0x546>
                dequeueFromMultiCircularQueue(&multiQueue, p);
    800026e4:	85a6                	mv	a1,s1
    800026e6:	855a                	mv	a0,s6
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	300080e7          	jalr	768(ra) # 800019e8 <dequeueFromMultiCircularQueue>
                p->wtime=0; //start rtime 0 in new queue
    800026f0:	1804ac23          	sw	zero,408(s1)
                p->rtime=0;
    800026f4:	1804aa23          	sw	zero,404(s1)
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
    800026f8:	85a6                	mv	a1,s1
    800026fa:	855a                	mv	a0,s6
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	1ae080e7          	jalr	430(ra) # 800018aa <enqueueToCircularQueue>
}
    80002704:	bf65                	j	800026bc <scheduler+0x546>
          for (int pos=0; pos<MAX_SIZE; pos++)
    80002706:	0000f917          	auipc	s2,0xf
    8000270a:	0c290913          	addi	s2,s2,194 # 800117c8 <multiQueue+0x618>
    8000270e:	0000fa97          	auipc	s5,0xf
    80002712:	2c2a8a93          	addi	s5,s5,706 # 800119d0 <queuemaxindex>
                dequeueFromMultiCircularQueue(&multiQueue, p);
    80002716:	0000fb17          	auipc	s6,0xf
    8000271a:	a9ab0b13          	addi	s6,s6,-1382 # 800111b0 <multiQueue>
    8000271e:	b77d                	j	800026cc <scheduler+0x556>

0000000080002720 <sched>:
{
    80002720:	7179                	addi	sp,sp,-48
    80002722:	f406                	sd	ra,40(sp)
    80002724:	f022                	sd	s0,32(sp)
    80002726:	ec26                	sd	s1,24(sp)
    80002728:	e84a                	sd	s2,16(sp)
    8000272a:	e44e                	sd	s3,8(sp)
    8000272c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000272e:	fffff097          	auipc	ra,0xfffff
    80002732:	4a2080e7          	jalr	1186(ra) # 80001bd0 <myproc>
    80002736:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	424080e7          	jalr	1060(ra) # 80000b5c <holding>
    80002740:	c93d                	beqz	a0,800027b6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002742:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002744:	2781                	sext.w	a5,a5
    80002746:	079e                	slli	a5,a5,0x7
    80002748:	0000e717          	auipc	a4,0xe
    8000274c:	4a870713          	addi	a4,a4,1192 # 80010bf0 <pid_lock>
    80002750:	97ba                	add	a5,a5,a4
    80002752:	0a87a703          	lw	a4,168(a5)
    80002756:	4785                	li	a5,1
    80002758:	06f71763          	bne	a4,a5,800027c6 <sched+0xa6>
  if (p->state == RUNNING)
    8000275c:	4c98                	lw	a4,24(s1)
    8000275e:	4791                	li	a5,4
    80002760:	06f70b63          	beq	a4,a5,800027d6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002764:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002768:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000276a:	efb5                	bnez	a5,800027e6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000276c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000276e:	0000e917          	auipc	s2,0xe
    80002772:	48290913          	addi	s2,s2,1154 # 80010bf0 <pid_lock>
    80002776:	2781                	sext.w	a5,a5
    80002778:	079e                	slli	a5,a5,0x7
    8000277a:	97ca                	add	a5,a5,s2
    8000277c:	0ac7a983          	lw	s3,172(a5)
    80002780:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002782:	2781                	sext.w	a5,a5
    80002784:	079e                	slli	a5,a5,0x7
    80002786:	0000e597          	auipc	a1,0xe
    8000278a:	4a258593          	addi	a1,a1,1186 # 80010c28 <cpus+0x8>
    8000278e:	95be                	add	a1,a1,a5
    80002790:	06048513          	addi	a0,s1,96
    80002794:	00001097          	auipc	ra,0x1
    80002798:	834080e7          	jalr	-1996(ra) # 80002fc8 <swtch>
    8000279c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000279e:	2781                	sext.w	a5,a5
    800027a0:	079e                	slli	a5,a5,0x7
    800027a2:	993e                	add	s2,s2,a5
    800027a4:	0b392623          	sw	s3,172(s2)
}
    800027a8:	70a2                	ld	ra,40(sp)
    800027aa:	7402                	ld	s0,32(sp)
    800027ac:	64e2                	ld	s1,24(sp)
    800027ae:	6942                	ld	s2,16(sp)
    800027b0:	69a2                	ld	s3,8(sp)
    800027b2:	6145                	addi	sp,sp,48
    800027b4:	8082                	ret
    panic("sched p->lock");
    800027b6:	00006517          	auipc	a0,0x6
    800027ba:	ac250513          	addi	a0,a0,-1342 # 80008278 <digits+0x238>
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	d82080e7          	jalr	-638(ra) # 80000540 <panic>
    panic("sched locks");
    800027c6:	00006517          	auipc	a0,0x6
    800027ca:	ac250513          	addi	a0,a0,-1342 # 80008288 <digits+0x248>
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	d72080e7          	jalr	-654(ra) # 80000540 <panic>
    panic("sched running");
    800027d6:	00006517          	auipc	a0,0x6
    800027da:	ac250513          	addi	a0,a0,-1342 # 80008298 <digits+0x258>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	d62080e7          	jalr	-670(ra) # 80000540 <panic>
    panic("sched interruptible");
    800027e6:	00006517          	auipc	a0,0x6
    800027ea:	ac250513          	addi	a0,a0,-1342 # 800082a8 <digits+0x268>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	d52080e7          	jalr	-686(ra) # 80000540 <panic>

00000000800027f6 <yield>:
{
    800027f6:	1101                	addi	sp,sp,-32
    800027f8:	ec06                	sd	ra,24(sp)
    800027fa:	e822                	sd	s0,16(sp)
    800027fc:	e426                	sd	s1,8(sp)
    800027fe:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	3d0080e7          	jalr	976(ra) # 80001bd0 <myproc>
    80002808:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	3cc080e7          	jalr	972(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002812:	478d                	li	a5,3
    80002814:	cc9c                	sw	a5,24(s1)
  sched();
    80002816:	00000097          	auipc	ra,0x0
    8000281a:	f0a080e7          	jalr	-246(ra) # 80002720 <sched>
  release(&p->lock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	46a080e7          	jalr	1130(ra) # 80000c8a <release>
}
    80002828:	60e2                	ld	ra,24(sp)
    8000282a:	6442                	ld	s0,16(sp)
    8000282c:	64a2                	ld	s1,8(sp)
    8000282e:	6105                	addi	sp,sp,32
    80002830:	8082                	ret

0000000080002832 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002832:	7179                	addi	sp,sp,-48
    80002834:	f406                	sd	ra,40(sp)
    80002836:	f022                	sd	s0,32(sp)
    80002838:	ec26                	sd	s1,24(sp)
    8000283a:	e84a                	sd	s2,16(sp)
    8000283c:	e44e                	sd	s3,8(sp)
    8000283e:	1800                	addi	s0,sp,48
    80002840:	89aa                	mv	s3,a0
    80002842:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	38c080e7          	jalr	908(ra) # 80001bd0 <myproc>
    8000284c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	388080e7          	jalr	904(ra) # 80000bd6 <acquire>
  release(lk);
    80002856:	854a                	mv	a0,s2
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	432080e7          	jalr	1074(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002860:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002864:	4789                	li	a5,2
    80002866:	cc9c                	sw	a5,24(s1)
  
  sched();
    80002868:	00000097          	auipc	ra,0x0
    8000286c:	eb8080e7          	jalr	-328(ra) # 80002720 <sched>

  // Tidy up.
  p->chan = 0;
    80002870:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002874:	8526                	mv	a0,s1
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	414080e7          	jalr	1044(ra) # 80000c8a <release>
  acquire(lk);
    8000287e:	854a                	mv	a0,s2
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	356080e7          	jalr	854(ra) # 80000bd6 <acquire>
}
    80002888:	70a2                	ld	ra,40(sp)
    8000288a:	7402                	ld	s0,32(sp)
    8000288c:	64e2                	ld	s1,24(sp)
    8000288e:	6942                	ld	s2,16(sp)
    80002890:	69a2                	ld	s3,8(sp)
    80002892:	6145                	addi	sp,sp,48
    80002894:	8082                	ret

0000000080002896 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002896:	7139                	addi	sp,sp,-64
    80002898:	fc06                	sd	ra,56(sp)
    8000289a:	f822                	sd	s0,48(sp)
    8000289c:	f426                	sd	s1,40(sp)
    8000289e:	f04a                	sd	s2,32(sp)
    800028a0:	ec4e                	sd	s3,24(sp)
    800028a2:	e852                	sd	s4,16(sp)
    800028a4:	e456                	sd	s5,8(sp)
    800028a6:	0080                	addi	s0,sp,64
    800028a8:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800028aa:	0000f497          	auipc	s1,0xf
    800028ae:	15648493          	addi	s1,s1,342 # 80011a00 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800028b2:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800028b4:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800028b6:	00016917          	auipc	s2,0x16
    800028ba:	b4a90913          	addi	s2,s2,-1206 # 80018400 <tickslock>
    800028be:	a811                	j	800028d2 <wakeup+0x3c>
      }
      release(&p->lock);
    800028c0:	8526                	mv	a0,s1
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	3c8080e7          	jalr	968(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800028ca:	1a848493          	addi	s1,s1,424
    800028ce:	03248663          	beq	s1,s2,800028fa <wakeup+0x64>
    if (p != myproc())
    800028d2:	fffff097          	auipc	ra,0xfffff
    800028d6:	2fe080e7          	jalr	766(ra) # 80001bd0 <myproc>
    800028da:	fea488e3          	beq	s1,a0,800028ca <wakeup+0x34>
      acquire(&p->lock);
    800028de:	8526                	mv	a0,s1
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	2f6080e7          	jalr	758(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800028e8:	4c9c                	lw	a5,24(s1)
    800028ea:	fd379be3          	bne	a5,s3,800028c0 <wakeup+0x2a>
    800028ee:	709c                	ld	a5,32(s1)
    800028f0:	fd4798e3          	bne	a5,s4,800028c0 <wakeup+0x2a>
        p->state = RUNNABLE;
    800028f4:	0154ac23          	sw	s5,24(s1)
    800028f8:	b7e1                	j	800028c0 <wakeup+0x2a>
    }
  }
}
    800028fa:	70e2                	ld	ra,56(sp)
    800028fc:	7442                	ld	s0,48(sp)
    800028fe:	74a2                	ld	s1,40(sp)
    80002900:	7902                	ld	s2,32(sp)
    80002902:	69e2                	ld	s3,24(sp)
    80002904:	6a42                	ld	s4,16(sp)
    80002906:	6aa2                	ld	s5,8(sp)
    80002908:	6121                	addi	sp,sp,64
    8000290a:	8082                	ret

000000008000290c <reparent>:
{
    8000290c:	7179                	addi	sp,sp,-48
    8000290e:	f406                	sd	ra,40(sp)
    80002910:	f022                	sd	s0,32(sp)
    80002912:	ec26                	sd	s1,24(sp)
    80002914:	e84a                	sd	s2,16(sp)
    80002916:	e44e                	sd	s3,8(sp)
    80002918:	e052                	sd	s4,0(sp)
    8000291a:	1800                	addi	s0,sp,48
    8000291c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000291e:	0000f497          	auipc	s1,0xf
    80002922:	0e248493          	addi	s1,s1,226 # 80011a00 <proc>
      pp->parent = initproc;
    80002926:	00006a17          	auipc	s4,0x6
    8000292a:	052a0a13          	addi	s4,s4,82 # 80008978 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000292e:	00016997          	auipc	s3,0x16
    80002932:	ad298993          	addi	s3,s3,-1326 # 80018400 <tickslock>
    80002936:	a029                	j	80002940 <reparent+0x34>
    80002938:	1a848493          	addi	s1,s1,424
    8000293c:	01348d63          	beq	s1,s3,80002956 <reparent+0x4a>
    if (pp->parent == p)
    80002940:	7c9c                	ld	a5,56(s1)
    80002942:	ff279be3          	bne	a5,s2,80002938 <reparent+0x2c>
      pp->parent = initproc;
    80002946:	000a3503          	ld	a0,0(s4)
    8000294a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	f4a080e7          	jalr	-182(ra) # 80002896 <wakeup>
    80002954:	b7d5                	j	80002938 <reparent+0x2c>
}
    80002956:	70a2                	ld	ra,40(sp)
    80002958:	7402                	ld	s0,32(sp)
    8000295a:	64e2                	ld	s1,24(sp)
    8000295c:	6942                	ld	s2,16(sp)
    8000295e:	69a2                	ld	s3,8(sp)
    80002960:	6a02                	ld	s4,0(sp)
    80002962:	6145                	addi	sp,sp,48
    80002964:	8082                	ret

0000000080002966 <exit>:
{
    80002966:	7179                	addi	sp,sp,-48
    80002968:	f406                	sd	ra,40(sp)
    8000296a:	f022                	sd	s0,32(sp)
    8000296c:	ec26                	sd	s1,24(sp)
    8000296e:	e84a                	sd	s2,16(sp)
    80002970:	e44e                	sd	s3,8(sp)
    80002972:	e052                	sd	s4,0(sp)
    80002974:	1800                	addi	s0,sp,48
    80002976:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002978:	fffff097          	auipc	ra,0xfffff
    8000297c:	258080e7          	jalr	600(ra) # 80001bd0 <myproc>
    80002980:	892a                	mv	s2,a0
  if (p == initproc)
    80002982:	00006797          	auipc	a5,0x6
    80002986:	ff67b783          	ld	a5,-10(a5) # 80008978 <initproc>
    8000298a:	0d050493          	addi	s1,a0,208
    8000298e:	15050993          	addi	s3,a0,336
    80002992:	02a79363          	bne	a5,a0,800029b8 <exit+0x52>
    panic("init exiting");
    80002996:	00006517          	auipc	a0,0x6
    8000299a:	92a50513          	addi	a0,a0,-1750 # 800082c0 <digits+0x280>
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	ba2080e7          	jalr	-1118(ra) # 80000540 <panic>
      fileclose(f);
    800029a6:	00002097          	auipc	ra,0x2
    800029aa:	744080e7          	jalr	1860(ra) # 800050ea <fileclose>
      p->ofile[fd] = 0;
    800029ae:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800029b2:	04a1                	addi	s1,s1,8
    800029b4:	01348563          	beq	s1,s3,800029be <exit+0x58>
    if (p->ofile[fd])
    800029b8:	6088                	ld	a0,0(s1)
    800029ba:	f575                	bnez	a0,800029a6 <exit+0x40>
    800029bc:	bfdd                	j	800029b2 <exit+0x4c>
  begin_op();
    800029be:	00002097          	auipc	ra,0x2
    800029c2:	264080e7          	jalr	612(ra) # 80004c22 <begin_op>
  iput(p->cwd);
    800029c6:	15093503          	ld	a0,336(s2)
    800029ca:	00002097          	auipc	ra,0x2
    800029ce:	a46080e7          	jalr	-1466(ra) # 80004410 <iput>
  end_op();
    800029d2:	00002097          	auipc	ra,0x2
    800029d6:	2ce080e7          	jalr	718(ra) # 80004ca0 <end_op>
  p->cwd = 0;
    800029da:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    800029de:	0000e497          	auipc	s1,0xe
    800029e2:	21248493          	addi	s1,s1,530 # 80010bf0 <pid_lock>
    800029e6:	0000e997          	auipc	s3,0xe
    800029ea:	22298993          	addi	s3,s3,546 # 80010c08 <wait_lock>
    800029ee:	854e                	mv	a0,s3
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	1e6080e7          	jalr	486(ra) # 80000bd6 <acquire>
  reparent(p);
    800029f8:	854a                	mv	a0,s2
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	f12080e7          	jalr	-238(ra) # 8000290c <reparent>
  wakeup(p->parent);
    80002a02:	03893503          	ld	a0,56(s2)
    80002a06:	00000097          	auipc	ra,0x0
    80002a0a:	e90080e7          	jalr	-368(ra) # 80002896 <wakeup>
  acquire(&p->lock);
    80002a0e:	854a                	mv	a0,s2
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	1c6080e7          	jalr	454(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002a18:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    80002a1c:	4795                	li	a5,5
    80002a1e:	00f92c23          	sw	a5,24(s2)
  p->etime = ticks;
    80002a22:	00006797          	auipc	a5,0x6
    80002a26:	f627a783          	lw	a5,-158(a5) # 80008984 <ticks>
    80002a2a:	16f92623          	sw	a5,364(s2)
  dequeueFromMultiCircularQueue(&multiQueue, p); //remove proc from queue
    80002a2e:	85ca                	mv	a1,s2
    80002a30:	0000e517          	auipc	a0,0xe
    80002a34:	78050513          	addi	a0,a0,1920 # 800111b0 <multiQueue>
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	fb0080e7          	jalr	-80(ra) # 800019e8 <dequeueFromMultiCircularQueue>
  allpid[p->pid]=0;
    80002a40:	03092783          	lw	a5,48(s2)
    80002a44:	078a                	slli	a5,a5,0x2
    80002a46:	97a6                	add	a5,a5,s1
    80002a48:	4207a823          	sw	zero,1072(a5)
  release(&wait_lock);
    80002a4c:	854e                	mv	a0,s3
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	23c080e7          	jalr	572(ra) # 80000c8a <release>
  allpid[p->pid]=0;
    80002a56:	03092783          	lw	a5,48(s2)
    80002a5a:	078a                	slli	a5,a5,0x2
    80002a5c:	94be                	add	s1,s1,a5
    80002a5e:	4204a823          	sw	zero,1072(s1)
  dequeueFromMultiCircularQueue(&multiQueue, p); //remove proc from queue
    80002a62:	85ca                	mv	a1,s2
    80002a64:	0000e517          	auipc	a0,0xe
    80002a68:	74c50513          	addi	a0,a0,1868 # 800111b0 <multiQueue>
    80002a6c:	fffff097          	auipc	ra,0xfffff
    80002a70:	f7c080e7          	jalr	-132(ra) # 800019e8 <dequeueFromMultiCircularQueue>
  sched();
    80002a74:	00000097          	auipc	ra,0x0
    80002a78:	cac080e7          	jalr	-852(ra) # 80002720 <sched>
  panic("zombie exit");
    80002a7c:	00006517          	auipc	a0,0x6
    80002a80:	85450513          	addi	a0,a0,-1964 # 800082d0 <digits+0x290>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	abc080e7          	jalr	-1348(ra) # 80000540 <panic>

0000000080002a8c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002a8c:	7179                	addi	sp,sp,-48
    80002a8e:	f406                	sd	ra,40(sp)
    80002a90:	f022                	sd	s0,32(sp)
    80002a92:	ec26                	sd	s1,24(sp)
    80002a94:	e84a                	sd	s2,16(sp)
    80002a96:	e44e                	sd	s3,8(sp)
    80002a98:	1800                	addi	s0,sp,48
    80002a9a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002a9c:	0000f497          	auipc	s1,0xf
    80002aa0:	f6448493          	addi	s1,s1,-156 # 80011a00 <proc>
    80002aa4:	00016997          	auipc	s3,0x16
    80002aa8:	95c98993          	addi	s3,s3,-1700 # 80018400 <tickslock>
  {
    acquire(&p->lock);
    80002aac:	8526                	mv	a0,s1
    80002aae:	ffffe097          	auipc	ra,0xffffe
    80002ab2:	128080e7          	jalr	296(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002ab6:	589c                	lw	a5,48(s1)
    80002ab8:	01278d63          	beq	a5,s2,80002ad2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002abc:	8526                	mv	a0,s1
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	1cc080e7          	jalr	460(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ac6:	1a848493          	addi	s1,s1,424
    80002aca:	ff3491e3          	bne	s1,s3,80002aac <kill+0x20>
  }
  return -1;
    80002ace:	557d                	li	a0,-1
    80002ad0:	a829                	j	80002aea <kill+0x5e>
      p->killed = 1;
    80002ad2:	4785                	li	a5,1
    80002ad4:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002ad6:	4c98                	lw	a4,24(s1)
    80002ad8:	4789                	li	a5,2
    80002ada:	00f70f63          	beq	a4,a5,80002af8 <kill+0x6c>
      release(&p->lock);
    80002ade:	8526                	mv	a0,s1
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	1aa080e7          	jalr	426(ra) # 80000c8a <release>
      return 0;
    80002ae8:	4501                	li	a0,0
}
    80002aea:	70a2                	ld	ra,40(sp)
    80002aec:	7402                	ld	s0,32(sp)
    80002aee:	64e2                	ld	s1,24(sp)
    80002af0:	6942                	ld	s2,16(sp)
    80002af2:	69a2                	ld	s3,8(sp)
    80002af4:	6145                	addi	sp,sp,48
    80002af6:	8082                	ret
        p->state = RUNNABLE;
    80002af8:	478d                	li	a5,3
    80002afa:	cc9c                	sw	a5,24(s1)
    80002afc:	b7cd                	j	80002ade <kill+0x52>

0000000080002afe <setkilled>:

void setkilled(struct proc *p)
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	1000                	addi	s0,sp,32
    80002b08:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	0cc080e7          	jalr	204(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002b12:	4785                	li	a5,1
    80002b14:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002b16:	8526                	mv	a0,s1
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	172080e7          	jalr	370(ra) # 80000c8a <release>
}
    80002b20:	60e2                	ld	ra,24(sp)
    80002b22:	6442                	ld	s0,16(sp)
    80002b24:	64a2                	ld	s1,8(sp)
    80002b26:	6105                	addi	sp,sp,32
    80002b28:	8082                	ret

0000000080002b2a <killed>:

int killed(struct proc *p)
{
    80002b2a:	1101                	addi	sp,sp,-32
    80002b2c:	ec06                	sd	ra,24(sp)
    80002b2e:	e822                	sd	s0,16(sp)
    80002b30:	e426                	sd	s1,8(sp)
    80002b32:	e04a                	sd	s2,0(sp)
    80002b34:	1000                	addi	s0,sp,32
    80002b36:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	09e080e7          	jalr	158(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002b40:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002b44:	8526                	mv	a0,s1
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	144080e7          	jalr	324(ra) # 80000c8a <release>
  return k;
}
    80002b4e:	854a                	mv	a0,s2
    80002b50:	60e2                	ld	ra,24(sp)
    80002b52:	6442                	ld	s0,16(sp)
    80002b54:	64a2                	ld	s1,8(sp)
    80002b56:	6902                	ld	s2,0(sp)
    80002b58:	6105                	addi	sp,sp,32
    80002b5a:	8082                	ret

0000000080002b5c <wait>:
{
    80002b5c:	715d                	addi	sp,sp,-80
    80002b5e:	e486                	sd	ra,72(sp)
    80002b60:	e0a2                	sd	s0,64(sp)
    80002b62:	fc26                	sd	s1,56(sp)
    80002b64:	f84a                	sd	s2,48(sp)
    80002b66:	f44e                	sd	s3,40(sp)
    80002b68:	f052                	sd	s4,32(sp)
    80002b6a:	ec56                	sd	s5,24(sp)
    80002b6c:	e85a                	sd	s6,16(sp)
    80002b6e:	e45e                	sd	s7,8(sp)
    80002b70:	e062                	sd	s8,0(sp)
    80002b72:	0880                	addi	s0,sp,80
    80002b74:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	05a080e7          	jalr	90(ra) # 80001bd0 <myproc>
    80002b7e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002b80:	0000e517          	auipc	a0,0xe
    80002b84:	08850513          	addi	a0,a0,136 # 80010c08 <wait_lock>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	04e080e7          	jalr	78(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002b90:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002b92:	4a15                	li	s4,5
        havekids = 1;
    80002b94:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002b96:	00016997          	auipc	s3,0x16
    80002b9a:	86a98993          	addi	s3,s3,-1942 # 80018400 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b9e:	0000ec17          	auipc	s8,0xe
    80002ba2:	06ac0c13          	addi	s8,s8,106 # 80010c08 <wait_lock>
    havekids = 0;
    80002ba6:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002ba8:	0000f497          	auipc	s1,0xf
    80002bac:	e5848493          	addi	s1,s1,-424 # 80011a00 <proc>
    80002bb0:	a0bd                	j	80002c1e <wait+0xc2>
          pid = pp->pid;
    80002bb2:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002bb6:	000b0e63          	beqz	s6,80002bd2 <wait+0x76>
    80002bba:	4691                	li	a3,4
    80002bbc:	02c48613          	addi	a2,s1,44
    80002bc0:	85da                	mv	a1,s6
    80002bc2:	05093503          	ld	a0,80(s2)
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	aa6080e7          	jalr	-1370(ra) # 8000166c <copyout>
    80002bce:	02054563          	bltz	a0,80002bf8 <wait+0x9c>
          freeproc(pp);
    80002bd2:	8526                	mv	a0,s1
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	1ae080e7          	jalr	430(ra) # 80001d82 <freeproc>
          release(&pp->lock);
    80002bdc:	8526                	mv	a0,s1
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	0ac080e7          	jalr	172(ra) # 80000c8a <release>
          release(&wait_lock);
    80002be6:	0000e517          	auipc	a0,0xe
    80002bea:	02250513          	addi	a0,a0,34 # 80010c08 <wait_lock>
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	09c080e7          	jalr	156(ra) # 80000c8a <release>
          return pid;
    80002bf6:	a0b5                	j	80002c62 <wait+0x106>
            release(&pp->lock);
    80002bf8:	8526                	mv	a0,s1
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	090080e7          	jalr	144(ra) # 80000c8a <release>
            release(&wait_lock);
    80002c02:	0000e517          	auipc	a0,0xe
    80002c06:	00650513          	addi	a0,a0,6 # 80010c08 <wait_lock>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	080080e7          	jalr	128(ra) # 80000c8a <release>
            return -1;
    80002c12:	59fd                	li	s3,-1
    80002c14:	a0b9                	j	80002c62 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002c16:	1a848493          	addi	s1,s1,424
    80002c1a:	03348463          	beq	s1,s3,80002c42 <wait+0xe6>
      if (pp->parent == p)
    80002c1e:	7c9c                	ld	a5,56(s1)
    80002c20:	ff279be3          	bne	a5,s2,80002c16 <wait+0xba>
        acquire(&pp->lock);
    80002c24:	8526                	mv	a0,s1
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	fb0080e7          	jalr	-80(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002c2e:	4c9c                	lw	a5,24(s1)
    80002c30:	f94781e3          	beq	a5,s4,80002bb2 <wait+0x56>
        release(&pp->lock);
    80002c34:	8526                	mv	a0,s1
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	054080e7          	jalr	84(ra) # 80000c8a <release>
        havekids = 1;
    80002c3e:	8756                	mv	a4,s5
    80002c40:	bfd9                	j	80002c16 <wait+0xba>
    if (!havekids || killed(p))
    80002c42:	c719                	beqz	a4,80002c50 <wait+0xf4>
    80002c44:	854a                	mv	a0,s2
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	ee4080e7          	jalr	-284(ra) # 80002b2a <killed>
    80002c4e:	c51d                	beqz	a0,80002c7c <wait+0x120>
      release(&wait_lock);
    80002c50:	0000e517          	auipc	a0,0xe
    80002c54:	fb850513          	addi	a0,a0,-72 # 80010c08 <wait_lock>
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	032080e7          	jalr	50(ra) # 80000c8a <release>
      return -1;
    80002c60:	59fd                	li	s3,-1
}
    80002c62:	854e                	mv	a0,s3
    80002c64:	60a6                	ld	ra,72(sp)
    80002c66:	6406                	ld	s0,64(sp)
    80002c68:	74e2                	ld	s1,56(sp)
    80002c6a:	7942                	ld	s2,48(sp)
    80002c6c:	79a2                	ld	s3,40(sp)
    80002c6e:	7a02                	ld	s4,32(sp)
    80002c70:	6ae2                	ld	s5,24(sp)
    80002c72:	6b42                	ld	s6,16(sp)
    80002c74:	6ba2                	ld	s7,8(sp)
    80002c76:	6c02                	ld	s8,0(sp)
    80002c78:	6161                	addi	sp,sp,80
    80002c7a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002c7c:	85e2                	mv	a1,s8
    80002c7e:	854a                	mv	a0,s2
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	bb2080e7          	jalr	-1102(ra) # 80002832 <sleep>
    havekids = 0;
    80002c88:	bf39                	j	80002ba6 <wait+0x4a>

0000000080002c8a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002c8a:	7179                	addi	sp,sp,-48
    80002c8c:	f406                	sd	ra,40(sp)
    80002c8e:	f022                	sd	s0,32(sp)
    80002c90:	ec26                	sd	s1,24(sp)
    80002c92:	e84a                	sd	s2,16(sp)
    80002c94:	e44e                	sd	s3,8(sp)
    80002c96:	e052                	sd	s4,0(sp)
    80002c98:	1800                	addi	s0,sp,48
    80002c9a:	84aa                	mv	s1,a0
    80002c9c:	892e                	mv	s2,a1
    80002c9e:	89b2                	mv	s3,a2
    80002ca0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	f2e080e7          	jalr	-210(ra) # 80001bd0 <myproc>
  if (user_dst)
    80002caa:	c08d                	beqz	s1,80002ccc <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002cac:	86d2                	mv	a3,s4
    80002cae:	864e                	mv	a2,s3
    80002cb0:	85ca                	mv	a1,s2
    80002cb2:	6928                	ld	a0,80(a0)
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	9b8080e7          	jalr	-1608(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002cbc:	70a2                	ld	ra,40(sp)
    80002cbe:	7402                	ld	s0,32(sp)
    80002cc0:	64e2                	ld	s1,24(sp)
    80002cc2:	6942                	ld	s2,16(sp)
    80002cc4:	69a2                	ld	s3,8(sp)
    80002cc6:	6a02                	ld	s4,0(sp)
    80002cc8:	6145                	addi	sp,sp,48
    80002cca:	8082                	ret
    memmove((char *)dst, src, len);
    80002ccc:	000a061b          	sext.w	a2,s4
    80002cd0:	85ce                	mv	a1,s3
    80002cd2:	854a                	mv	a0,s2
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	05a080e7          	jalr	90(ra) # 80000d2e <memmove>
    return 0;
    80002cdc:	8526                	mv	a0,s1
    80002cde:	bff9                	j	80002cbc <either_copyout+0x32>

0000000080002ce0 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002ce0:	7179                	addi	sp,sp,-48
    80002ce2:	f406                	sd	ra,40(sp)
    80002ce4:	f022                	sd	s0,32(sp)
    80002ce6:	ec26                	sd	s1,24(sp)
    80002ce8:	e84a                	sd	s2,16(sp)
    80002cea:	e44e                	sd	s3,8(sp)
    80002cec:	e052                	sd	s4,0(sp)
    80002cee:	1800                	addi	s0,sp,48
    80002cf0:	892a                	mv	s2,a0
    80002cf2:	84ae                	mv	s1,a1
    80002cf4:	89b2                	mv	s3,a2
    80002cf6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	ed8080e7          	jalr	-296(ra) # 80001bd0 <myproc>
  if (user_src)
    80002d00:	c08d                	beqz	s1,80002d22 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002d02:	86d2                	mv	a3,s4
    80002d04:	864e                	mv	a2,s3
    80002d06:	85ca                	mv	a1,s2
    80002d08:	6928                	ld	a0,80(a0)
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	9ee080e7          	jalr	-1554(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002d12:	70a2                	ld	ra,40(sp)
    80002d14:	7402                	ld	s0,32(sp)
    80002d16:	64e2                	ld	s1,24(sp)
    80002d18:	6942                	ld	s2,16(sp)
    80002d1a:	69a2                	ld	s3,8(sp)
    80002d1c:	6a02                	ld	s4,0(sp)
    80002d1e:	6145                	addi	sp,sp,48
    80002d20:	8082                	ret
    memmove(dst, (char *)src, len);
    80002d22:	000a061b          	sext.w	a2,s4
    80002d26:	85ce                	mv	a1,s3
    80002d28:	854a                	mv	a0,s2
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	004080e7          	jalr	4(ra) # 80000d2e <memmove>
    return 0;
    80002d32:	8526                	mv	a0,s1
    80002d34:	bff9                	j	80002d12 <either_copyin+0x32>

0000000080002d36 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002d36:	7139                	addi	sp,sp,-64
    80002d38:	fc06                	sd	ra,56(sp)
    80002d3a:	f822                	sd	s0,48(sp)
    80002d3c:	f426                	sd	s1,40(sp)
    80002d3e:	f04a                	sd	s2,32(sp)
    80002d40:	ec4e                	sd	s3,24(sp)
    80002d42:	e852                	sd	s4,16(sp)
    80002d44:	e456                	sd	s5,8(sp)
    80002d46:	e05a                	sd	s6,0(sp)
    80002d48:	0080                	addi	s0,sp,64
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"}; //completed execution zombie 
  struct proc *p;
  char *state;

  printf("ticks %d\n",ticks);
    80002d4a:	00006597          	auipc	a1,0x6
    80002d4e:	c3a5a583          	lw	a1,-966(a1) # 80008984 <ticks>
    80002d52:	00005517          	auipc	a0,0x5
    80002d56:	59650513          	addi	a0,a0,1430 # 800082e8 <digits+0x2a8>
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	830080e7          	jalr	-2000(ra) # 8000058a <printf>

  for (p = proc; p < &proc[NPROC]; p++)
    80002d62:	0000f497          	auipc	s1,0xf
    80002d66:	df648493          	addi	s1,s1,-522 # 80011b58 <proc+0x158>
    80002d6a:	00015917          	auipc	s2,0x15
    80002d6e:	7ee90913          	addi	s2,s2,2030 # 80018558 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d72:	4a95                	li	s5,5
      state = states[p->state];
    else
      state = "???";
    80002d74:	00005997          	auipc	s3,0x5
    80002d78:	56c98993          	addi	s3,s3,1388 # 800082e0 <digits+0x2a0>
    printf("%d %s %s %d %d \n", p->pid, state, p->name,p->r_time,p->w_time); //r_time in test of total till now
    80002d7c:	00005a17          	auipc	s4,0x5
    80002d80:	57ca0a13          	addi	s4,s4,1404 # 800082f8 <digits+0x2b8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d84:	00005b17          	auipc	s6,0x5
    80002d88:	5bcb0b13          	addi	s6,s6,1468 # 80008340 <states.0>
    80002d8c:	a831                	j	80002da8 <procdump+0x72>
    printf("%d %s %s %d %d \n", p->pid, state, p->name,p->r_time,p->w_time); //r_time in test of total till now
    80002d8e:	46bc                	lw	a5,72(a3)
    80002d90:	42f8                	lw	a4,68(a3)
    80002d92:	ed86a583          	lw	a1,-296(a3)
    80002d96:	8552                	mv	a0,s4
    80002d98:	ffffd097          	auipc	ra,0xffffd
    80002d9c:	7f2080e7          	jalr	2034(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002da0:	1a848493          	addi	s1,s1,424
    80002da4:	03248263          	beq	s1,s2,80002dc8 <procdump+0x92>
    if (p->state == UNUSED)
    80002da8:	86a6                	mv	a3,s1
    80002daa:	ec04a783          	lw	a5,-320(s1)
    80002dae:	dbed                	beqz	a5,80002da0 <procdump+0x6a>
      state = "???";
    80002db0:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002db2:	fcfaeee3          	bltu	s5,a5,80002d8e <procdump+0x58>
    80002db6:	02079713          	slli	a4,a5,0x20
    80002dba:	01d75793          	srli	a5,a4,0x1d
    80002dbe:	97da                	add	a5,a5,s6
    80002dc0:	6390                	ld	a2,0(a5)
    80002dc2:	f671                	bnez	a2,80002d8e <procdump+0x58>
      state = "???";
    80002dc4:	864e                	mv	a2,s3
    80002dc6:	b7e1                	j	80002d8e <procdump+0x58>
  }
  // for(int i=0;i<100;i=i+1){
  //     printf("%d",allpid[i]);
  //   }printf("\n");
    
  display(&multiQueue);
    80002dc8:	0000e517          	auipc	a0,0xe
    80002dcc:	3e850513          	addi	a0,a0,1000 # 800111b0 <multiQueue>
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	bae080e7          	jalr	-1106(ra) # 8000197e <display>
}
    80002dd8:	70e2                	ld	ra,56(sp)
    80002dda:	7442                	ld	s0,48(sp)
    80002ddc:	74a2                	ld	s1,40(sp)
    80002dde:	7902                	ld	s2,32(sp)
    80002de0:	69e2                	ld	s3,24(sp)
    80002de2:	6a42                	ld	s4,16(sp)
    80002de4:	6aa2                	ld	s5,8(sp)
    80002de6:	6b02                	ld	s6,0(sp)
    80002de8:	6121                	addi	sp,sp,64
    80002dea:	8082                	ret

0000000080002dec <waitx>:

// waitx
int waitx(uint64 addr, uint *w_time, uint *r_time)
{
    80002dec:	711d                	addi	sp,sp,-96
    80002dee:	ec86                	sd	ra,88(sp)
    80002df0:	e8a2                	sd	s0,80(sp)
    80002df2:	e4a6                	sd	s1,72(sp)
    80002df4:	e0ca                	sd	s2,64(sp)
    80002df6:	fc4e                	sd	s3,56(sp)
    80002df8:	f852                	sd	s4,48(sp)
    80002dfa:	f456                	sd	s5,40(sp)
    80002dfc:	f05a                	sd	s6,32(sp)
    80002dfe:	ec5e                	sd	s7,24(sp)
    80002e00:	e862                	sd	s8,16(sp)
    80002e02:	e466                	sd	s9,8(sp)
    80002e04:	e06a                	sd	s10,0(sp)
    80002e06:	1080                	addi	s0,sp,96
    80002e08:	8b2a                	mv	s6,a0
    80002e0a:	8bae                	mv	s7,a1
    80002e0c:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	dc2080e7          	jalr	-574(ra) # 80001bd0 <myproc>
    80002e16:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002e18:	0000e517          	auipc	a0,0xe
    80002e1c:	df050513          	addi	a0,a0,-528 # 80010c08 <wait_lock>
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	db6080e7          	jalr	-586(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002e28:	4c81                	li	s9,0
      { 
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);
        
        havekids = 1;
        if (np->state == ZOMBIE)
    80002e2a:	4a15                	li	s4,5
        havekids = 1;
    80002e2c:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002e2e:	00015997          	auipc	s3,0x15
    80002e32:	5d298993          	addi	s3,s3,1490 # 80018400 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002e36:	0000ed17          	auipc	s10,0xe
    80002e3a:	dd2d0d13          	addi	s10,s10,-558 # 80010c08 <wait_lock>
    havekids = 0;
    80002e3e:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002e40:	0000f497          	auipc	s1,0xf
    80002e44:	bc048493          	addi	s1,s1,-1088 # 80011a00 <proc>
    80002e48:	a07d                	j	80002ef6 <waitx+0x10a>
          pid = np->pid;
    80002e4a:	0304a983          	lw	s3,48(s1)
          allpid[pid]=0;
    80002e4e:	00299713          	slli	a4,s3,0x2
    80002e52:	0000e797          	auipc	a5,0xe
    80002e56:	d9e78793          	addi	a5,a5,-610 # 80010bf0 <pid_lock>
    80002e5a:	97ba                	add	a5,a5,a4
    80002e5c:	4207a823          	sw	zero,1072(a5)
          dequeueFromMultiCircularQueue(&multiQueue, np); //remove proc from queue
    80002e60:	85a6                	mv	a1,s1
    80002e62:	0000e517          	auipc	a0,0xe
    80002e66:	34e50513          	addi	a0,a0,846 # 800111b0 <multiQueue>
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	b7e080e7          	jalr	-1154(ra) # 800019e8 <dequeueFromMultiCircularQueue>
          *r_time = np->r_time;
    80002e72:	19c4a783          	lw	a5,412(s1)
    80002e76:	00fc2023          	sw	a5,0(s8)
          *w_time = np->etime - np->ctime - np->r_time;//
    80002e7a:	16c4a783          	lw	a5,364(s1)
    80002e7e:	1684a703          	lw	a4,360(s1)
    80002e82:	9f99                	subw	a5,a5,a4
    80002e84:	19c4a703          	lw	a4,412(s1)
    80002e88:	9f99                	subw	a5,a5,a4
    80002e8a:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002e8e:	000b0e63          	beqz	s6,80002eaa <waitx+0xbe>
    80002e92:	4691                	li	a3,4
    80002e94:	02c48613          	addi	a2,s1,44
    80002e98:	85da                	mv	a1,s6
    80002e9a:	05093503          	ld	a0,80(s2)
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	7ce080e7          	jalr	1998(ra) # 8000166c <copyout>
    80002ea6:	02054563          	bltz	a0,80002ed0 <waitx+0xe4>
          freeproc(np);
    80002eaa:	8526                	mv	a0,s1
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	ed6080e7          	jalr	-298(ra) # 80001d82 <freeproc>
          release(&np->lock);
    80002eb4:	8526                	mv	a0,s1
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	dd4080e7          	jalr	-556(ra) # 80000c8a <release>
          release(&wait_lock);
    80002ebe:	0000e517          	auipc	a0,0xe
    80002ec2:	d4a50513          	addi	a0,a0,-694 # 80010c08 <wait_lock>
    80002ec6:	ffffe097          	auipc	ra,0xffffe
    80002eca:	dc4080e7          	jalr	-572(ra) # 80000c8a <release>
          return pid;
    80002ece:	a09d                	j	80002f34 <waitx+0x148>
            release(&np->lock);
    80002ed0:	8526                	mv	a0,s1
    80002ed2:	ffffe097          	auipc	ra,0xffffe
    80002ed6:	db8080e7          	jalr	-584(ra) # 80000c8a <release>
            release(&wait_lock);
    80002eda:	0000e517          	auipc	a0,0xe
    80002ede:	d2e50513          	addi	a0,a0,-722 # 80010c08 <wait_lock>
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	da8080e7          	jalr	-600(ra) # 80000c8a <release>
            return -1;
    80002eea:	59fd                	li	s3,-1
    80002eec:	a0a1                	j	80002f34 <waitx+0x148>
    for (np = proc; np < &proc[NPROC]; np++)
    80002eee:	1a848493          	addi	s1,s1,424
    80002ef2:	03348463          	beq	s1,s3,80002f1a <waitx+0x12e>
      if (np->parent == p)
    80002ef6:	7c9c                	ld	a5,56(s1)
    80002ef8:	ff279be3          	bne	a5,s2,80002eee <waitx+0x102>
        acquire(&np->lock);
    80002efc:	8526                	mv	a0,s1
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	cd8080e7          	jalr	-808(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002f06:	4c9c                	lw	a5,24(s1)
    80002f08:	f54781e3          	beq	a5,s4,80002e4a <waitx+0x5e>
        release(&np->lock);
    80002f0c:	8526                	mv	a0,s1
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	d7c080e7          	jalr	-644(ra) # 80000c8a <release>
        havekids = 1;
    80002f16:	8756                	mv	a4,s5
    80002f18:	bfd9                	j	80002eee <waitx+0x102>
    if (!havekids || p->killed)
    80002f1a:	c701                	beqz	a4,80002f22 <waitx+0x136>
    80002f1c:	02892783          	lw	a5,40(s2)
    80002f20:	cb8d                	beqz	a5,80002f52 <waitx+0x166>
      release(&wait_lock);
    80002f22:	0000e517          	auipc	a0,0xe
    80002f26:	ce650513          	addi	a0,a0,-794 # 80010c08 <wait_lock>
    80002f2a:	ffffe097          	auipc	ra,0xffffe
    80002f2e:	d60080e7          	jalr	-672(ra) # 80000c8a <release>
      return -1;
    80002f32:	59fd                	li	s3,-1
  }
}
    80002f34:	854e                	mv	a0,s3
    80002f36:	60e6                	ld	ra,88(sp)
    80002f38:	6446                	ld	s0,80(sp)
    80002f3a:	64a6                	ld	s1,72(sp)
    80002f3c:	6906                	ld	s2,64(sp)
    80002f3e:	79e2                	ld	s3,56(sp)
    80002f40:	7a42                	ld	s4,48(sp)
    80002f42:	7aa2                	ld	s5,40(sp)
    80002f44:	7b02                	ld	s6,32(sp)
    80002f46:	6be2                	ld	s7,24(sp)
    80002f48:	6c42                	ld	s8,16(sp)
    80002f4a:	6ca2                	ld	s9,8(sp)
    80002f4c:	6d02                	ld	s10,0(sp)
    80002f4e:	6125                	addi	sp,sp,96
    80002f50:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002f52:	85ea                	mv	a1,s10
    80002f54:	854a                	mv	a0,s2
    80002f56:	00000097          	auipc	ra,0x0
    80002f5a:	8dc080e7          	jalr	-1828(ra) # 80002832 <sleep>
    havekids = 0;
    80002f5e:	b5c5                	j	80002e3e <waitx+0x52>

0000000080002f60 <update_time>:

void update_time()
{
    80002f60:	7179                	addi	sp,sp,-48
    80002f62:	f406                	sd	ra,40(sp)
    80002f64:	f022                	sd	s0,32(sp)
    80002f66:	ec26                	sd	s1,24(sp)
    80002f68:	e84a                	sd	s2,16(sp)
    80002f6a:	e44e                	sd	s3,8(sp)
    80002f6c:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002f6e:	0000f497          	auipc	s1,0xf
    80002f72:	a9248493          	addi	s1,s1,-1390 # 80011a00 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002f76:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002f78:	00015917          	auipc	s2,0x15
    80002f7c:	48890913          	addi	s2,s2,1160 # 80018400 <tickslock>
    80002f80:	a811                	j	80002f94 <update_time+0x34>
    {
      p->rtime++;
      p->r_time++;
    }
    release(&p->lock);
    80002f82:	8526                	mv	a0,s1
    80002f84:	ffffe097          	auipc	ra,0xffffe
    80002f88:	d06080e7          	jalr	-762(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002f8c:	1a848493          	addi	s1,s1,424
    80002f90:	03248563          	beq	s1,s2,80002fba <update_time+0x5a>
    acquire(&p->lock);
    80002f94:	8526                	mv	a0,s1
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	c40080e7          	jalr	-960(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002f9e:	4c9c                	lw	a5,24(s1)
    80002fa0:	ff3791e3          	bne	a5,s3,80002f82 <update_time+0x22>
      p->rtime++;
    80002fa4:	1944a783          	lw	a5,404(s1)
    80002fa8:	2785                	addiw	a5,a5,1
    80002faa:	18f4aa23          	sw	a5,404(s1)
      p->r_time++;
    80002fae:	19c4a783          	lw	a5,412(s1)
    80002fb2:	2785                	addiw	a5,a5,1
    80002fb4:	18f4ae23          	sw	a5,412(s1)
    80002fb8:	b7e9                	j	80002f82 <update_time+0x22>
  }
    80002fba:	70a2                	ld	ra,40(sp)
    80002fbc:	7402                	ld	s0,32(sp)
    80002fbe:	64e2                	ld	s1,24(sp)
    80002fc0:	6942                	ld	s2,16(sp)
    80002fc2:	69a2                	ld	s3,8(sp)
    80002fc4:	6145                	addi	sp,sp,48
    80002fc6:	8082                	ret

0000000080002fc8 <swtch>:
    80002fc8:	00153023          	sd	ra,0(a0)
    80002fcc:	00253423          	sd	sp,8(a0)
    80002fd0:	e900                	sd	s0,16(a0)
    80002fd2:	ed04                	sd	s1,24(a0)
    80002fd4:	03253023          	sd	s2,32(a0)
    80002fd8:	03353423          	sd	s3,40(a0)
    80002fdc:	03453823          	sd	s4,48(a0)
    80002fe0:	03553c23          	sd	s5,56(a0)
    80002fe4:	05653023          	sd	s6,64(a0)
    80002fe8:	05753423          	sd	s7,72(a0)
    80002fec:	05853823          	sd	s8,80(a0)
    80002ff0:	05953c23          	sd	s9,88(a0)
    80002ff4:	07a53023          	sd	s10,96(a0)
    80002ff8:	07b53423          	sd	s11,104(a0)
    80002ffc:	0005b083          	ld	ra,0(a1)
    80003000:	0085b103          	ld	sp,8(a1)
    80003004:	6980                	ld	s0,16(a1)
    80003006:	6d84                	ld	s1,24(a1)
    80003008:	0205b903          	ld	s2,32(a1)
    8000300c:	0285b983          	ld	s3,40(a1)
    80003010:	0305ba03          	ld	s4,48(a1)
    80003014:	0385ba83          	ld	s5,56(a1)
    80003018:	0405bb03          	ld	s6,64(a1)
    8000301c:	0485bb83          	ld	s7,72(a1)
    80003020:	0505bc03          	ld	s8,80(a1)
    80003024:	0585bc83          	ld	s9,88(a1)
    80003028:	0605bd03          	ld	s10,96(a1)
    8000302c:	0685bd83          	ld	s11,104(a1)
    80003030:	8082                	ret

0000000080003032 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80003032:	1141                	addi	sp,sp,-16
    80003034:	e406                	sd	ra,8(sp)
    80003036:	e022                	sd	s0,0(sp)
    80003038:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000303a:	00005597          	auipc	a1,0x5
    8000303e:	33658593          	addi	a1,a1,822 # 80008370 <states.0+0x30>
    80003042:	00015517          	auipc	a0,0x15
    80003046:	3be50513          	addi	a0,a0,958 # 80018400 <tickslock>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	afc080e7          	jalr	-1284(ra) # 80000b46 <initlock>
}
    80003052:	60a2                	ld	ra,8(sp)
    80003054:	6402                	ld	s0,0(sp)
    80003056:	0141                	addi	sp,sp,16
    80003058:	8082                	ret

000000008000305a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000305a:	1141                	addi	sp,sp,-16
    8000305c:	e422                	sd	s0,8(sp)
    8000305e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003060:	00003797          	auipc	a5,0x3
    80003064:	6f078793          	addi	a5,a5,1776 # 80006750 <kernelvec>
    80003068:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000306c:	6422                	ld	s0,8(sp)
    8000306e:	0141                	addi	sp,sp,16
    80003070:	8082                	ret

0000000080003072 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80003072:	1141                	addi	sp,sp,-16
    80003074:	e406                	sd	ra,8(sp)
    80003076:	e022                	sd	s0,0(sp)
    80003078:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000307a:	fffff097          	auipc	ra,0xfffff
    8000307e:	b56080e7          	jalr	-1194(ra) # 80001bd0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003082:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003086:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003088:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000308c:	00004697          	auipc	a3,0x4
    80003090:	f7468693          	addi	a3,a3,-140 # 80007000 <_trampoline>
    80003094:	00004717          	auipc	a4,0x4
    80003098:	f6c70713          	addi	a4,a4,-148 # 80007000 <_trampoline>
    8000309c:	8f15                	sub	a4,a4,a3
    8000309e:	040007b7          	lui	a5,0x4000
    800030a2:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800030a4:	07b2                	slli	a5,a5,0xc
    800030a6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030a8:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800030ac:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800030ae:	18002673          	csrr	a2,satp
    800030b2:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800030b4:	6d30                	ld	a2,88(a0)
    800030b6:	6138                	ld	a4,64(a0)
    800030b8:	6585                	lui	a1,0x1
    800030ba:	972e                	add	a4,a4,a1
    800030bc:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800030be:	6d38                	ld	a4,88(a0)
    800030c0:	00000617          	auipc	a2,0x0
    800030c4:	19860613          	addi	a2,a2,408 # 80003258 <usertrap>
    800030c8:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800030ca:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800030cc:	8612                	mv	a2,tp
    800030ce:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030d0:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800030d4:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800030d8:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030dc:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800030e0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030e2:	6f18                	ld	a4,24(a4)
    800030e4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800030e8:	6928                	ld	a0,80(a0)
    800030ea:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800030ec:	00004717          	auipc	a4,0x4
    800030f0:	fb070713          	addi	a4,a4,-80 # 8000709c <userret>
    800030f4:	8f15                	sub	a4,a4,a3
    800030f6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800030f8:	577d                	li	a4,-1
    800030fa:	177e                	slli	a4,a4,0x3f
    800030fc:	8d59                	or	a0,a0,a4
    800030fe:	9782                	jalr	a5
}
    80003100:	60a2                	ld	ra,8(sp)
    80003102:	6402                	ld	s0,0(sp)
    80003104:	0141                	addi	sp,sp,16
    80003106:	8082                	ret

0000000080003108 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80003108:	7179                	addi	sp,sp,-48
    8000310a:	f406                	sd	ra,40(sp)
    8000310c:	f022                	sd	s0,32(sp)
    8000310e:	ec26                	sd	s1,24(sp)
    80003110:	e84a                	sd	s2,16(sp)
    80003112:	e44e                	sd	s3,8(sp)
    80003114:	1800                	addi	s0,sp,48
  acquire(&tickslock);
    80003116:	00015517          	auipc	a0,0x15
    8000311a:	2ea50513          	addi	a0,a0,746 # 80018400 <tickslock>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	ab8080e7          	jalr	-1352(ra) # 80000bd6 <acquire>
  ticks++;  
    80003126:	00006717          	auipc	a4,0x6
    8000312a:	85e70713          	addi	a4,a4,-1954 # 80008984 <ticks>
    8000312e:	431c                	lw	a5,0(a4)
    80003130:	2785                	addiw	a5,a5,1
    80003132:	c31c                	sw	a5,0(a4)
  update_time();
    80003134:	00000097          	auipc	ra,0x0
    80003138:	e2c080e7          	jalr	-468(ra) # 80002f60 <update_time>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    8000313c:	0000f497          	auipc	s1,0xf
    80003140:	8c448493          	addi	s1,s1,-1852 # 80011a00 <proc>
    // if (p->state == RUNNING)
    // {
      
    //   p->rtime++;
    // }
    if (p->state == SLEEPING)
    80003144:	4989                	li	s3,2
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80003146:	00015917          	auipc	s2,0x15
    8000314a:	2ba90913          	addi	s2,s2,698 # 80018400 <tickslock>
    8000314e:	a811                	j	80003162 <clockintr+0x5a>
    {
      p->wtime++;
      p->w_time++;//of test
    }
    release(&p->lock);
    80003150:	8526                	mv	a0,s1
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	b38080e7          	jalr	-1224(ra) # 80000c8a <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    8000315a:	1a848493          	addi	s1,s1,424
    8000315e:	03248563          	beq	s1,s2,80003188 <clockintr+0x80>
    acquire(&p->lock);
    80003162:	8526                	mv	a0,s1
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	a72080e7          	jalr	-1422(ra) # 80000bd6 <acquire>
    if (p->state == SLEEPING)
    8000316c:	4c9c                	lw	a5,24(s1)
    8000316e:	ff3791e3          	bne	a5,s3,80003150 <clockintr+0x48>
      p->wtime++;
    80003172:	1984a783          	lw	a5,408(s1)
    80003176:	2785                	addiw	a5,a5,1
    80003178:	18f4ac23          	sw	a5,408(s1)
      p->w_time++;//of test
    8000317c:	1a04a783          	lw	a5,416(s1)
    80003180:	2785                	addiw	a5,a5,1
    80003182:	1af4a023          	sw	a5,416(s1)
    80003186:	b7e9                	j	80003150 <clockintr+0x48>
  }
  wakeup(&ticks);
    80003188:	00005517          	auipc	a0,0x5
    8000318c:	7fc50513          	addi	a0,a0,2044 # 80008984 <ticks>
    80003190:	fffff097          	auipc	ra,0xfffff
    80003194:	706080e7          	jalr	1798(ra) # 80002896 <wakeup>
  release(&tickslock);
    80003198:	00015517          	auipc	a0,0x15
    8000319c:	26850513          	addi	a0,a0,616 # 80018400 <tickslock>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	aea080e7          	jalr	-1302(ra) # 80000c8a <release>
}
    800031a8:	70a2                	ld	ra,40(sp)
    800031aa:	7402                	ld	s0,32(sp)
    800031ac:	64e2                	ld	s1,24(sp)
    800031ae:	6942                	ld	s2,16(sp)
    800031b0:	69a2                	ld	s3,8(sp)
    800031b2:	6145                	addi	sp,sp,48
    800031b4:	8082                	ret

00000000800031b6 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    800031b6:	1101                	addi	sp,sp,-32
    800031b8:	ec06                	sd	ra,24(sp)
    800031ba:	e822                	sd	s0,16(sp)
    800031bc:	e426                	sd	s1,8(sp)
    800031be:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031c0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    800031c4:	00074d63          	bltz	a4,800031de <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    800031c8:	57fd                	li	a5,-1
    800031ca:	17fe                	slli	a5,a5,0x3f
    800031cc:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    800031ce:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    800031d0:	06f70363          	beq	a4,a5,80003236 <devintr+0x80>
  }
}
    800031d4:	60e2                	ld	ra,24(sp)
    800031d6:	6442                	ld	s0,16(sp)
    800031d8:	64a2                	ld	s1,8(sp)
    800031da:	6105                	addi	sp,sp,32
    800031dc:	8082                	ret
      (scause & 0xff) == 9)
    800031de:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    800031e2:	46a5                	li	a3,9
    800031e4:	fed792e3          	bne	a5,a3,800031c8 <devintr+0x12>
    int irq = plic_claim();
    800031e8:	00003097          	auipc	ra,0x3
    800031ec:	670080e7          	jalr	1648(ra) # 80006858 <plic_claim>
    800031f0:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800031f2:	47a9                	li	a5,10
    800031f4:	02f50763          	beq	a0,a5,80003222 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    800031f8:	4785                	li	a5,1
    800031fa:	02f50963          	beq	a0,a5,8000322c <devintr+0x76>
    return 1;
    800031fe:	4505                	li	a0,1
    else if (irq)
    80003200:	d8f1                	beqz	s1,800031d4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003202:	85a6                	mv	a1,s1
    80003204:	00005517          	auipc	a0,0x5
    80003208:	17450513          	addi	a0,a0,372 # 80008378 <states.0+0x38>
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	37e080e7          	jalr	894(ra) # 8000058a <printf>
      plic_complete(irq);
    80003214:	8526                	mv	a0,s1
    80003216:	00003097          	auipc	ra,0x3
    8000321a:	666080e7          	jalr	1638(ra) # 8000687c <plic_complete>
    return 1;
    8000321e:	4505                	li	a0,1
    80003220:	bf55                	j	800031d4 <devintr+0x1e>
      uartintr();
    80003222:	ffffd097          	auipc	ra,0xffffd
    80003226:	776080e7          	jalr	1910(ra) # 80000998 <uartintr>
    8000322a:	b7ed                	j	80003214 <devintr+0x5e>
      virtio_disk_intr();
    8000322c:	00004097          	auipc	ra,0x4
    80003230:	b18080e7          	jalr	-1256(ra) # 80006d44 <virtio_disk_intr>
    80003234:	b7c5                	j	80003214 <devintr+0x5e>
    if (cpuid() == 0)
    80003236:	fffff097          	auipc	ra,0xfffff
    8000323a:	96e080e7          	jalr	-1682(ra) # 80001ba4 <cpuid>
    8000323e:	c901                	beqz	a0,8000324e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003240:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003244:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003246:	14479073          	csrw	sip,a5
    return 2;
    8000324a:	4509                	li	a0,2
    8000324c:	b761                	j	800031d4 <devintr+0x1e>
      clockintr();
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	eba080e7          	jalr	-326(ra) # 80003108 <clockintr>
    80003256:	b7ed                	j	80003240 <devintr+0x8a>

0000000080003258 <usertrap>:
{
    80003258:	1101                	addi	sp,sp,-32
    8000325a:	ec06                	sd	ra,24(sp)
    8000325c:	e822                	sd	s0,16(sp)
    8000325e:	e426                	sd	s1,8(sp)
    80003260:	e04a                	sd	s2,0(sp)
    80003262:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003264:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80003268:	1007f793          	andi	a5,a5,256
    8000326c:	e3b1                	bnez	a5,800032b0 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000326e:	00003797          	auipc	a5,0x3
    80003272:	4e278793          	addi	a5,a5,1250 # 80006750 <kernelvec>
    80003276:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000327a:	fffff097          	auipc	ra,0xfffff
    8000327e:	956080e7          	jalr	-1706(ra) # 80001bd0 <myproc>
    80003282:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003284:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003286:	14102773          	csrr	a4,sepc
    8000328a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000328c:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80003290:	47a1                	li	a5,8
    80003292:	02f70763          	beq	a4,a5,800032c0 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	f20080e7          	jalr	-224(ra) # 800031b6 <devintr>
    8000329e:	892a                	mv	s2,a0
    800032a0:	c92d                	beqz	a0,80003312 <usertrap+0xba>
  if (killed(p))
    800032a2:	8526                	mv	a0,s1
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	886080e7          	jalr	-1914(ra) # 80002b2a <killed>
    800032ac:	c555                	beqz	a0,80003358 <usertrap+0x100>
    800032ae:	a045                	j	8000334e <usertrap+0xf6>
    panic("usertrap: not from user mode");
    800032b0:	00005517          	auipc	a0,0x5
    800032b4:	0e850513          	addi	a0,a0,232 # 80008398 <states.0+0x58>
    800032b8:	ffffd097          	auipc	ra,0xffffd
    800032bc:	288080e7          	jalr	648(ra) # 80000540 <panic>
    if (killed(p))
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	86a080e7          	jalr	-1942(ra) # 80002b2a <killed>
    800032c8:	ed1d                	bnez	a0,80003306 <usertrap+0xae>
    p->trapframe->epc += 4;
    800032ca:	6cb8                	ld	a4,88(s1)
    800032cc:	6f1c                	ld	a5,24(a4)
    800032ce:	0791                	addi	a5,a5,4
    800032d0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800032d6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032da:	10079073          	csrw	sstatus,a5
    syscall();
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	31e080e7          	jalr	798(ra) # 800035fc <syscall>
  if (killed(p))
    800032e6:	8526                	mv	a0,s1
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	842080e7          	jalr	-1982(ra) # 80002b2a <killed>
    800032f0:	ed31                	bnez	a0,8000334c <usertrap+0xf4>
  usertrapret();
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	d80080e7          	jalr	-640(ra) # 80003072 <usertrapret>
}
    800032fa:	60e2                	ld	ra,24(sp)
    800032fc:	6442                	ld	s0,16(sp)
    800032fe:	64a2                	ld	s1,8(sp)
    80003300:	6902                	ld	s2,0(sp)
    80003302:	6105                	addi	sp,sp,32
    80003304:	8082                	ret
      exit(-1);
    80003306:	557d                	li	a0,-1
    80003308:	fffff097          	auipc	ra,0xfffff
    8000330c:	65e080e7          	jalr	1630(ra) # 80002966 <exit>
    80003310:	bf6d                	j	800032ca <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003312:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003316:	5890                	lw	a2,48(s1)
    80003318:	00005517          	auipc	a0,0x5
    8000331c:	0a050513          	addi	a0,a0,160 # 800083b8 <states.0+0x78>
    80003320:	ffffd097          	auipc	ra,0xffffd
    80003324:	26a080e7          	jalr	618(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003328:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000332c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003330:	00005517          	auipc	a0,0x5
    80003334:	0b850513          	addi	a0,a0,184 # 800083e8 <states.0+0xa8>
    80003338:	ffffd097          	auipc	ra,0xffffd
    8000333c:	252080e7          	jalr	594(ra) # 8000058a <printf>
    setkilled(p);
    80003340:	8526                	mv	a0,s1
    80003342:	fffff097          	auipc	ra,0xfffff
    80003346:	7bc080e7          	jalr	1980(ra) # 80002afe <setkilled>
    8000334a:	bf71                	j	800032e6 <usertrap+0x8e>
  if (killed(p))
    8000334c:	4901                	li	s2,0
    exit(-1);
    8000334e:	557d                	li	a0,-1
    80003350:	fffff097          	auipc	ra,0xfffff
    80003354:	616080e7          	jalr	1558(ra) # 80002966 <exit>
  if (which_dev == 2  && p->handler_permission == 1  ) { 
    80003358:	4789                	li	a5,2
    8000335a:	f8f91ce3          	bne	s2,a5,800032f2 <usertrap+0x9a>
    8000335e:	1884a703          	lw	a4,392(s1)
    80003362:	4785                	li	a5,1
    80003364:	00f70763          	beq	a4,a5,80003372 <usertrap+0x11a>
    yield();
    80003368:	fffff097          	auipc	ra,0xfffff
    8000336c:	48e080e7          	jalr	1166(ra) # 800027f6 <yield>
    80003370:	b749                	j	800032f2 <usertrap+0x9a>
      struct trapframe *tf = kalloc();      /// sighandler part
    80003372:	ffffd097          	auipc	ra,0xffffd
    80003376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000337a:	892a                	mv	s2,a0
      memmove(tf, p->trapframe, PGSIZE);
    8000337c:	6605                	lui	a2,0x1
    8000337e:	6cac                	ld	a1,88(s1)
    80003380:	ffffe097          	auipc	ra,0xffffe
    80003384:	9ae080e7          	jalr	-1618(ra) # 80000d2e <memmove>
      p->alarm_tf = tf;   //tf saved in alarm_tf
    80003388:	1924b023          	sd	s2,384(s1)
      p->cur_ticks++;
    8000338c:	17c4a783          	lw	a5,380(s1)
    80003390:	2785                	addiw	a5,a5,1
    80003392:	16f4ae23          	sw	a5,380(s1)
      if (p->cur_ticks % p->ticks == 0){
    80003396:	1784a703          	lw	a4,376(s1)
    8000339a:	02e7e7bb          	remw	a5,a5,a4
    8000339e:	f7e9                	bnez	a5,80003368 <usertrap+0x110>
        p->trapframe->epc = p->handler; //give state of periodic ,i.e call periodic function
    800033a0:	6cbc                	ld	a5,88(s1)
    800033a2:	1704b703          	ld	a4,368(s1)
    800033a6:	ef98                	sd	a4,24(a5)
        p->handler_permission = 0; //0
    800033a8:	1804a423          	sw	zero,392(s1)
    800033ac:	bf75                	j	80003368 <usertrap+0x110>

00000000800033ae <kerneltrap>:
{
    800033ae:	7179                	addi	sp,sp,-48
    800033b0:	f406                	sd	ra,40(sp)
    800033b2:	f022                	sd	s0,32(sp)
    800033b4:	ec26                	sd	s1,24(sp)
    800033b6:	e84a                	sd	s2,16(sp)
    800033b8:	e44e                	sd	s3,8(sp)
    800033ba:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033bc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033c0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033c4:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800033c8:	1004f793          	andi	a5,s1,256
    800033cc:	cb85                	beqz	a5,800033fc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033ce:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800033d2:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800033d4:	ef85                	bnez	a5,8000340c <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	de0080e7          	jalr	-544(ra) # 800031b6 <devintr>
    800033de:	cd1d                	beqz	a0,8000341c <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800033e0:	4789                	li	a5,2
    800033e2:	06f50a63          	beq	a0,a5,80003456 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800033e6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800033ea:	10049073          	csrw	sstatus,s1
}
    800033ee:	70a2                	ld	ra,40(sp)
    800033f0:	7402                	ld	s0,32(sp)
    800033f2:	64e2                	ld	s1,24(sp)
    800033f4:	6942                	ld	s2,16(sp)
    800033f6:	69a2                	ld	s3,8(sp)
    800033f8:	6145                	addi	sp,sp,48
    800033fa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800033fc:	00005517          	auipc	a0,0x5
    80003400:	00c50513          	addi	a0,a0,12 # 80008408 <states.0+0xc8>
    80003404:	ffffd097          	auipc	ra,0xffffd
    80003408:	13c080e7          	jalr	316(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    8000340c:	00005517          	auipc	a0,0x5
    80003410:	02450513          	addi	a0,a0,36 # 80008430 <states.0+0xf0>
    80003414:	ffffd097          	auipc	ra,0xffffd
    80003418:	12c080e7          	jalr	300(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    8000341c:	85ce                	mv	a1,s3
    8000341e:	00005517          	auipc	a0,0x5
    80003422:	03250513          	addi	a0,a0,50 # 80008450 <states.0+0x110>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	164080e7          	jalr	356(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000342e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003432:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003436:	00005517          	auipc	a0,0x5
    8000343a:	02a50513          	addi	a0,a0,42 # 80008460 <states.0+0x120>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	14c080e7          	jalr	332(ra) # 8000058a <printf>
    panic("kerneltrap");
    80003446:	00005517          	auipc	a0,0x5
    8000344a:	03250513          	addi	a0,a0,50 # 80008478 <states.0+0x138>
    8000344e:	ffffd097          	auipc	ra,0xffffd
    80003452:	0f2080e7          	jalr	242(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003456:	ffffe097          	auipc	ra,0xffffe
    8000345a:	77a080e7          	jalr	1914(ra) # 80001bd0 <myproc>
    8000345e:	d541                	beqz	a0,800033e6 <kerneltrap+0x38>
    80003460:	ffffe097          	auipc	ra,0xffffe
    80003464:	770080e7          	jalr	1904(ra) # 80001bd0 <myproc>
    80003468:	4d18                	lw	a4,24(a0)
    8000346a:	4791                	li	a5,4
    8000346c:	f6f71de3          	bne	a4,a5,800033e6 <kerneltrap+0x38>
    yield();
    80003470:	fffff097          	auipc	ra,0xfffff
    80003474:	386080e7          	jalr	902(ra) # 800027f6 <yield>
    80003478:	b7bd                	j	800033e6 <kerneltrap+0x38>

000000008000347a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000347a:	1101                	addi	sp,sp,-32
    8000347c:	ec06                	sd	ra,24(sp)
    8000347e:	e822                	sd	s0,16(sp)
    80003480:	e426                	sd	s1,8(sp)
    80003482:	1000                	addi	s0,sp,32
    80003484:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	74a080e7          	jalr	1866(ra) # 80001bd0 <myproc>
  switch (n) {
    8000348e:	4795                	li	a5,5
    80003490:	0497e163          	bltu	a5,s1,800034d2 <argraw+0x58>
    80003494:	048a                	slli	s1,s1,0x2
    80003496:	00005717          	auipc	a4,0x5
    8000349a:	01a70713          	addi	a4,a4,26 # 800084b0 <states.0+0x170>
    8000349e:	94ba                	add	s1,s1,a4
    800034a0:	409c                	lw	a5,0(s1)
    800034a2:	97ba                	add	a5,a5,a4
    800034a4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800034a6:	6d3c                	ld	a5,88(a0)
    800034a8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800034aa:	60e2                	ld	ra,24(sp)
    800034ac:	6442                	ld	s0,16(sp)
    800034ae:	64a2                	ld	s1,8(sp)
    800034b0:	6105                	addi	sp,sp,32
    800034b2:	8082                	ret
    return p->trapframe->a1;
    800034b4:	6d3c                	ld	a5,88(a0)
    800034b6:	7fa8                	ld	a0,120(a5)
    800034b8:	bfcd                	j	800034aa <argraw+0x30>
    return p->trapframe->a2;
    800034ba:	6d3c                	ld	a5,88(a0)
    800034bc:	63c8                	ld	a0,128(a5)
    800034be:	b7f5                	j	800034aa <argraw+0x30>
    return p->trapframe->a3;
    800034c0:	6d3c                	ld	a5,88(a0)
    800034c2:	67c8                	ld	a0,136(a5)
    800034c4:	b7dd                	j	800034aa <argraw+0x30>
    return p->trapframe->a4;
    800034c6:	6d3c                	ld	a5,88(a0)
    800034c8:	6bc8                	ld	a0,144(a5)
    800034ca:	b7c5                	j	800034aa <argraw+0x30>
    return p->trapframe->a5;
    800034cc:	6d3c                	ld	a5,88(a0)
    800034ce:	6fc8                	ld	a0,152(a5)
    800034d0:	bfe9                	j	800034aa <argraw+0x30>
  panic("argraw");
    800034d2:	00005517          	auipc	a0,0x5
    800034d6:	fb650513          	addi	a0,a0,-74 # 80008488 <states.0+0x148>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	066080e7          	jalr	102(ra) # 80000540 <panic>

00000000800034e2 <fetchaddr>:
{
    800034e2:	1101                	addi	sp,sp,-32
    800034e4:	ec06                	sd	ra,24(sp)
    800034e6:	e822                	sd	s0,16(sp)
    800034e8:	e426                	sd	s1,8(sp)
    800034ea:	e04a                	sd	s2,0(sp)
    800034ec:	1000                	addi	s0,sp,32
    800034ee:	84aa                	mv	s1,a0
    800034f0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800034f2:	ffffe097          	auipc	ra,0xffffe
    800034f6:	6de080e7          	jalr	1758(ra) # 80001bd0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800034fa:	653c                	ld	a5,72(a0)
    800034fc:	02f4f863          	bgeu	s1,a5,8000352c <fetchaddr+0x4a>
    80003500:	00848713          	addi	a4,s1,8
    80003504:	02e7e663          	bltu	a5,a4,80003530 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003508:	46a1                	li	a3,8
    8000350a:	8626                	mv	a2,s1
    8000350c:	85ca                	mv	a1,s2
    8000350e:	6928                	ld	a0,80(a0)
    80003510:	ffffe097          	auipc	ra,0xffffe
    80003514:	1e8080e7          	jalr	488(ra) # 800016f8 <copyin>
    80003518:	00a03533          	snez	a0,a0
    8000351c:	40a00533          	neg	a0,a0
}
    80003520:	60e2                	ld	ra,24(sp)
    80003522:	6442                	ld	s0,16(sp)
    80003524:	64a2                	ld	s1,8(sp)
    80003526:	6902                	ld	s2,0(sp)
    80003528:	6105                	addi	sp,sp,32
    8000352a:	8082                	ret
    return -1;
    8000352c:	557d                	li	a0,-1
    8000352e:	bfcd                	j	80003520 <fetchaddr+0x3e>
    80003530:	557d                	li	a0,-1
    80003532:	b7fd                	j	80003520 <fetchaddr+0x3e>

0000000080003534 <fetchstr>:
{
    80003534:	7179                	addi	sp,sp,-48
    80003536:	f406                	sd	ra,40(sp)
    80003538:	f022                	sd	s0,32(sp)
    8000353a:	ec26                	sd	s1,24(sp)
    8000353c:	e84a                	sd	s2,16(sp)
    8000353e:	e44e                	sd	s3,8(sp)
    80003540:	1800                	addi	s0,sp,48
    80003542:	892a                	mv	s2,a0
    80003544:	84ae                	mv	s1,a1
    80003546:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003548:	ffffe097          	auipc	ra,0xffffe
    8000354c:	688080e7          	jalr	1672(ra) # 80001bd0 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003550:	86ce                	mv	a3,s3
    80003552:	864a                	mv	a2,s2
    80003554:	85a6                	mv	a1,s1
    80003556:	6928                	ld	a0,80(a0)
    80003558:	ffffe097          	auipc	ra,0xffffe
    8000355c:	22e080e7          	jalr	558(ra) # 80001786 <copyinstr>
    80003560:	00054e63          	bltz	a0,8000357c <fetchstr+0x48>
  return strlen(buf);
    80003564:	8526                	mv	a0,s1
    80003566:	ffffe097          	auipc	ra,0xffffe
    8000356a:	8e8080e7          	jalr	-1816(ra) # 80000e4e <strlen>
}
    8000356e:	70a2                	ld	ra,40(sp)
    80003570:	7402                	ld	s0,32(sp)
    80003572:	64e2                	ld	s1,24(sp)
    80003574:	6942                	ld	s2,16(sp)
    80003576:	69a2                	ld	s3,8(sp)
    80003578:	6145                	addi	sp,sp,48
    8000357a:	8082                	ret
    return -1;
    8000357c:	557d                	li	a0,-1
    8000357e:	bfc5                	j	8000356e <fetchstr+0x3a>

0000000080003580 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003580:	1101                	addi	sp,sp,-32
    80003582:	ec06                	sd	ra,24(sp)
    80003584:	e822                	sd	s0,16(sp)
    80003586:	e426                	sd	s1,8(sp)
    80003588:	1000                	addi	s0,sp,32
    8000358a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	eee080e7          	jalr	-274(ra) # 8000347a <argraw>
    80003594:	c088                	sw	a0,0(s1)
  return 1;
}
    80003596:	4505                	li	a0,1
    80003598:	60e2                	ld	ra,24(sp)
    8000359a:	6442                	ld	s0,16(sp)
    8000359c:	64a2                	ld	s1,8(sp)
    8000359e:	6105                	addi	sp,sp,32
    800035a0:	8082                	ret

00000000800035a2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800035a2:	1101                	addi	sp,sp,-32
    800035a4:	ec06                	sd	ra,24(sp)
    800035a6:	e822                	sd	s0,16(sp)
    800035a8:	e426                	sd	s1,8(sp)
    800035aa:	1000                	addi	s0,sp,32
    800035ac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	ecc080e7          	jalr	-308(ra) # 8000347a <argraw>
    800035b6:	e088                	sd	a0,0(s1)
  return 1;
}
    800035b8:	4505                	li	a0,1
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	64a2                	ld	s1,8(sp)
    800035c0:	6105                	addi	sp,sp,32
    800035c2:	8082                	ret

00000000800035c4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800035c4:	7179                	addi	sp,sp,-48
    800035c6:	f406                	sd	ra,40(sp)
    800035c8:	f022                	sd	s0,32(sp)
    800035ca:	ec26                	sd	s1,24(sp)
    800035cc:	e84a                	sd	s2,16(sp)
    800035ce:	1800                	addi	s0,sp,48
    800035d0:	84ae                	mv	s1,a1
    800035d2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800035d4:	fd840593          	addi	a1,s0,-40
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	fca080e7          	jalr	-54(ra) # 800035a2 <argaddr>
  return fetchstr(addr, buf, max);
    800035e0:	864a                	mv	a2,s2
    800035e2:	85a6                	mv	a1,s1
    800035e4:	fd843503          	ld	a0,-40(s0)
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	f4c080e7          	jalr	-180(ra) # 80003534 <fetchstr>
}
    800035f0:	70a2                	ld	ra,40(sp)
    800035f2:	7402                	ld	s0,32(sp)
    800035f4:	64e2                	ld	s1,24(sp)
    800035f6:	6942                	ld	s2,16(sp)
    800035f8:	6145                	addi	sp,sp,48
    800035fa:	8082                	ret

00000000800035fc <syscall>:

};

void
syscall(void)
{
    800035fc:	1101                	addi	sp,sp,-32
    800035fe:	ec06                	sd	ra,24(sp)
    80003600:	e822                	sd	s0,16(sp)
    80003602:	e426                	sd	s1,8(sp)
    80003604:	e04a                	sd	s2,0(sp)
    80003606:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003608:	ffffe097          	auipc	ra,0xffffe
    8000360c:	5c8080e7          	jalr	1480(ra) # 80001bd0 <myproc>
    80003610:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003612:	05853903          	ld	s2,88(a0)
    80003616:	0a893783          	ld	a5,168(s2)
    8000361a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000361e:	37fd                	addiw	a5,a5,-1
    80003620:	4765                	li	a4,25
    80003622:	00f76f63          	bltu	a4,a5,80003640 <syscall+0x44>
    80003626:	00369713          	slli	a4,a3,0x3
    8000362a:	00005797          	auipc	a5,0x5
    8000362e:	e9e78793          	addi	a5,a5,-354 # 800084c8 <syscalls>
    80003632:	97ba                	add	a5,a5,a4
    80003634:	639c                	ld	a5,0(a5)
    80003636:	c789                	beqz	a5,80003640 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003638:	9782                	jalr	a5
    8000363a:	06a93823          	sd	a0,112(s2)
    8000363e:	a839                	j	8000365c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003640:	15848613          	addi	a2,s1,344
    80003644:	588c                	lw	a1,48(s1)
    80003646:	00005517          	auipc	a0,0x5
    8000364a:	e4a50513          	addi	a0,a0,-438 # 80008490 <states.0+0x150>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	f3c080e7          	jalr	-196(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003656:	6cbc                	ld	a5,88(s1)
    80003658:	577d                	li	a4,-1
    8000365a:	fbb8                	sd	a4,112(a5)
  }
}
    8000365c:	60e2                	ld	ra,24(sp)
    8000365e:	6442                	ld	s0,16(sp)
    80003660:	64a2                	ld	s1,8(sp)
    80003662:	6902                	ld	s2,0(sp)
    80003664:	6105                	addi	sp,sp,32
    80003666:	8082                	ret

0000000080003668 <sys_getreadcount>:


int readcount=0;

uint64
sys_getreadcount(void){ //////////////////
    80003668:	1141                	addi	sp,sp,-16
    8000366a:	e422                	sd	s0,8(sp)
    8000366c:	0800                	addi	s0,sp,16
	return readcount;  ///////////
}
    8000366e:	00005517          	auipc	a0,0x5
    80003672:	31a52503          	lw	a0,794(a0) # 80008988 <readcount>
    80003676:	6422                	ld	s0,8(sp)
    80003678:	0141                	addi	sp,sp,16
    8000367a:	8082                	ret

000000008000367c <sys_sigalarm>:

//////////
uint64 
sys_sigalarm(void)
{
    8000367c:	1101                	addi	sp,sp,-32
    8000367e:	ec06                	sd	ra,24(sp)
    80003680:	e822                	sd	s0,16(sp)
    80003682:	1000                	addi	s0,sp,32
  int ticks;
  uint64 handleraddrs;
  if(argint(0, &ticks) < 0)  //read arg0 
    80003684:	fec40593          	addi	a1,s0,-20
    80003688:	4501                	li	a0,0
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	ef6080e7          	jalr	-266(ra) # 80003580 <argint>
    return -1;
    80003692:	57fd                	li	a5,-1
  if(argint(0, &ticks) < 0)  //read arg0 
    80003694:	02054d63          	bltz	a0,800036ce <sys_sigalarm+0x52>
  if(argaddr(1, &handleraddrs) < 0) //read arg1
    80003698:	fe040593          	addi	a1,s0,-32
    8000369c:	4505                	li	a0,1
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	f04080e7          	jalr	-252(ra) # 800035a2 <argaddr>
    return -1;
    800036a6:	57fd                	li	a5,-1
  if(argaddr(1, &handleraddrs) < 0) //read arg1
    800036a8:	02054363          	bltz	a0,800036ce <sys_sigalarm+0x52>

  myproc()->ticks = ticks;  //here 2 , becomes 0 sigalarm(0,--)
    800036ac:	ffffe097          	auipc	ra,0xffffe
    800036b0:	524080e7          	jalr	1316(ra) # 80001bd0 <myproc>
    800036b4:	fec42783          	lw	a5,-20(s0)
    800036b8:	16f52c23          	sw	a5,376(a0)
     // myproc()->alarm_on = 1;
  myproc()->handler = handleraddrs;  //func periodic ka address
    800036bc:	ffffe097          	auipc	ra,0xffffe
    800036c0:	514080e7          	jalr	1300(ra) # 80001bd0 <myproc>
    800036c4:	fe043783          	ld	a5,-32(s0)
    800036c8:	16f53823          	sd	a5,368(a0)
  //myproc()->a1 = myproc()->trapframe->a0;
  //myproc()->a2 = myproc()->trapframe->a1;

  return 0;
    800036cc:	4781                	li	a5,0
}
    800036ce:	853e                	mv	a0,a5
    800036d0:	60e2                	ld	ra,24(sp)
    800036d2:	6442                	ld	s0,16(sp)
    800036d4:	6105                	addi	sp,sp,32
    800036d6:	8082                	ret

00000000800036d8 <sys_sigreturn>:


uint64 
sys_sigreturn(void)
{
    800036d8:	1101                	addi	sp,sp,-32
    800036da:	ec06                	sd	ra,24(sp)
    800036dc:	e822                	sd	s0,16(sp)
    800036de:	e426                	sd	s1,8(sp)
    800036e0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800036e2:	ffffe097          	auipc	ra,0xffffe
    800036e6:	4ee080e7          	jalr	1262(ra) # 80001bd0 <myproc>
    800036ea:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alarm_tf, PGSIZE);//give state of main before returning
    800036ec:	6605                	lui	a2,0x1
    800036ee:	18053583          	ld	a1,384(a0)
    800036f2:	6d28                	ld	a0,88(a0)
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	63a080e7          	jalr	1594(ra) # 80000d2e <memmove>
  //myproc()->trapframe->a0 = myproc()->a1;
  //myproc()->trapframe->a1 = myproc()->a2;
  kfree(p->alarm_tf);
    800036fc:	1804b503          	ld	a0,384(s1)
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	2e8080e7          	jalr	744(ra) # 800009e8 <kfree>
  p->handler_permission = 1;//1
    80003708:	4785                	li	a5,1
    8000370a:	18f4a423          	sw	a5,392(s1)
  //trapp always happens cur % tick but //making handler_permission=1,gives opprtunity to call periodic
  // if handler_permission =0 always , periodic isnt called
  // printf("perm_1");
  return myproc()->trapframe->a0;//previously executing thread
    8000370e:	ffffe097          	auipc	ra,0xffffe
    80003712:	4c2080e7          	jalr	1218(ra) # 80001bd0 <myproc>
    80003716:	6d3c                	ld	a5,88(a0)
}
    80003718:	7ba8                	ld	a0,112(a5)
    8000371a:	60e2                	ld	ra,24(sp)
    8000371c:	6442                	ld	s0,16(sp)
    8000371e:	64a2                	ld	s1,8(sp)
    80003720:	6105                	addi	sp,sp,32
    80003722:	8082                	ret

0000000080003724 <sys_exit>:



uint64
sys_exit(void)
{
    80003724:	1101                	addi	sp,sp,-32
    80003726:	ec06                	sd	ra,24(sp)
    80003728:	e822                	sd	s0,16(sp)
    8000372a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000372c:	fec40593          	addi	a1,s0,-20
    80003730:	4501                	li	a0,0
    80003732:	00000097          	auipc	ra,0x0
    80003736:	e4e080e7          	jalr	-434(ra) # 80003580 <argint>
  exit(n);
    8000373a:	fec42503          	lw	a0,-20(s0)
    8000373e:	fffff097          	auipc	ra,0xfffff
    80003742:	228080e7          	jalr	552(ra) # 80002966 <exit>
  return 0; // not reached
}
    80003746:	4501                	li	a0,0
    80003748:	60e2                	ld	ra,24(sp)
    8000374a:	6442                	ld	s0,16(sp)
    8000374c:	6105                	addi	sp,sp,32
    8000374e:	8082                	ret

0000000080003750 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003750:	1141                	addi	sp,sp,-16
    80003752:	e406                	sd	ra,8(sp)
    80003754:	e022                	sd	s0,0(sp)
    80003756:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003758:	ffffe097          	auipc	ra,0xffffe
    8000375c:	478080e7          	jalr	1144(ra) # 80001bd0 <myproc>
}
    80003760:	5908                	lw	a0,48(a0)
    80003762:	60a2                	ld	ra,8(sp)
    80003764:	6402                	ld	s0,0(sp)
    80003766:	0141                	addi	sp,sp,16
    80003768:	8082                	ret

000000008000376a <sys_fork>:

uint64
sys_fork(void)
{
    8000376a:	1141                	addi	sp,sp,-16
    8000376c:	e406                	sd	ra,8(sp)
    8000376e:	e022                	sd	s0,0(sp)
    80003770:	0800                	addi	s0,sp,16
  return fork();
    80003772:	fffff097          	auipc	ra,0xfffff
    80003776:	850080e7          	jalr	-1968(ra) # 80001fc2 <fork>
}
    8000377a:	60a2                	ld	ra,8(sp)
    8000377c:	6402                	ld	s0,0(sp)
    8000377e:	0141                	addi	sp,sp,16
    80003780:	8082                	ret

0000000080003782 <sys_wait>:

uint64
sys_wait(void)
{
    80003782:	1101                	addi	sp,sp,-32
    80003784:	ec06                	sd	ra,24(sp)
    80003786:	e822                	sd	s0,16(sp)
    80003788:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000378a:	fe840593          	addi	a1,s0,-24
    8000378e:	4501                	li	a0,0
    80003790:	00000097          	auipc	ra,0x0
    80003794:	e12080e7          	jalr	-494(ra) # 800035a2 <argaddr>
  return wait(p);
    80003798:	fe843503          	ld	a0,-24(s0)
    8000379c:	fffff097          	auipc	ra,0xfffff
    800037a0:	3c0080e7          	jalr	960(ra) # 80002b5c <wait>
}
    800037a4:	60e2                	ld	ra,24(sp)
    800037a6:	6442                	ld	s0,16(sp)
    800037a8:	6105                	addi	sp,sp,32
    800037aa:	8082                	ret

00000000800037ac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800037ac:	7179                	addi	sp,sp,-48
    800037ae:	f406                	sd	ra,40(sp)
    800037b0:	f022                	sd	s0,32(sp)
    800037b2:	ec26                	sd	s1,24(sp)
    800037b4:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800037b6:	fdc40593          	addi	a1,s0,-36
    800037ba:	4501                	li	a0,0
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	dc4080e7          	jalr	-572(ra) # 80003580 <argint>
  addr = myproc()->sz;
    800037c4:	ffffe097          	auipc	ra,0xffffe
    800037c8:	40c080e7          	jalr	1036(ra) # 80001bd0 <myproc>
    800037cc:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800037ce:	fdc42503          	lw	a0,-36(s0)
    800037d2:	ffffe097          	auipc	ra,0xffffe
    800037d6:	794080e7          	jalr	1940(ra) # 80001f66 <growproc>
    800037da:	00054863          	bltz	a0,800037ea <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800037de:	8526                	mv	a0,s1
    800037e0:	70a2                	ld	ra,40(sp)
    800037e2:	7402                	ld	s0,32(sp)
    800037e4:	64e2                	ld	s1,24(sp)
    800037e6:	6145                	addi	sp,sp,48
    800037e8:	8082                	ret
    return -1;
    800037ea:	54fd                	li	s1,-1
    800037ec:	bfcd                	j	800037de <sys_sbrk+0x32>

00000000800037ee <sys_sleep>:

uint64
sys_sleep(void)
{
    800037ee:	7139                	addi	sp,sp,-64
    800037f0:	fc06                	sd	ra,56(sp)
    800037f2:	f822                	sd	s0,48(sp)
    800037f4:	f426                	sd	s1,40(sp)
    800037f6:	f04a                	sd	s2,32(sp)
    800037f8:	ec4e                	sd	s3,24(sp)
    800037fa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800037fc:	fcc40593          	addi	a1,s0,-52
    80003800:	4501                	li	a0,0
    80003802:	00000097          	auipc	ra,0x0
    80003806:	d7e080e7          	jalr	-642(ra) # 80003580 <argint>
  acquire(&tickslock);
    8000380a:	00015517          	auipc	a0,0x15
    8000380e:	bf650513          	addi	a0,a0,-1034 # 80018400 <tickslock>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	3c4080e7          	jalr	964(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    8000381a:	00005917          	auipc	s2,0x5
    8000381e:	16a92903          	lw	s2,362(s2) # 80008984 <ticks>
  while (ticks - ticks0 < n)
    80003822:	fcc42783          	lw	a5,-52(s0)
    80003826:	cf9d                	beqz	a5,80003864 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003828:	00015997          	auipc	s3,0x15
    8000382c:	bd898993          	addi	s3,s3,-1064 # 80018400 <tickslock>
    80003830:	00005497          	auipc	s1,0x5
    80003834:	15448493          	addi	s1,s1,340 # 80008984 <ticks>
    if (killed(myproc()))
    80003838:	ffffe097          	auipc	ra,0xffffe
    8000383c:	398080e7          	jalr	920(ra) # 80001bd0 <myproc>
    80003840:	fffff097          	auipc	ra,0xfffff
    80003844:	2ea080e7          	jalr	746(ra) # 80002b2a <killed>
    80003848:	ed15                	bnez	a0,80003884 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000384a:	85ce                	mv	a1,s3
    8000384c:	8526                	mv	a0,s1
    8000384e:	fffff097          	auipc	ra,0xfffff
    80003852:	fe4080e7          	jalr	-28(ra) # 80002832 <sleep>
  while (ticks - ticks0 < n)
    80003856:	409c                	lw	a5,0(s1)
    80003858:	412787bb          	subw	a5,a5,s2
    8000385c:	fcc42703          	lw	a4,-52(s0)
    80003860:	fce7ece3          	bltu	a5,a4,80003838 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003864:	00015517          	auipc	a0,0x15
    80003868:	b9c50513          	addi	a0,a0,-1124 # 80018400 <tickslock>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	41e080e7          	jalr	1054(ra) # 80000c8a <release>
  return 0;
    80003874:	4501                	li	a0,0
}
    80003876:	70e2                	ld	ra,56(sp)
    80003878:	7442                	ld	s0,48(sp)
    8000387a:	74a2                	ld	s1,40(sp)
    8000387c:	7902                	ld	s2,32(sp)
    8000387e:	69e2                	ld	s3,24(sp)
    80003880:	6121                	addi	sp,sp,64
    80003882:	8082                	ret
      release(&tickslock);
    80003884:	00015517          	auipc	a0,0x15
    80003888:	b7c50513          	addi	a0,a0,-1156 # 80018400 <tickslock>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	3fe080e7          	jalr	1022(ra) # 80000c8a <release>
      return -1;
    80003894:	557d                	li	a0,-1
    80003896:	b7c5                	j	80003876 <sys_sleep+0x88>

0000000080003898 <sys_kill>:

uint64
sys_kill(void)
{
    80003898:	1101                	addi	sp,sp,-32
    8000389a:	ec06                	sd	ra,24(sp)
    8000389c:	e822                	sd	s0,16(sp)
    8000389e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800038a0:	fec40593          	addi	a1,s0,-20
    800038a4:	4501                	li	a0,0
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	cda080e7          	jalr	-806(ra) # 80003580 <argint>
  return kill(pid);
    800038ae:	fec42503          	lw	a0,-20(s0)
    800038b2:	fffff097          	auipc	ra,0xfffff
    800038b6:	1da080e7          	jalr	474(ra) # 80002a8c <kill>
}
    800038ba:	60e2                	ld	ra,24(sp)
    800038bc:	6442                	ld	s0,16(sp)
    800038be:	6105                	addi	sp,sp,32
    800038c0:	8082                	ret

00000000800038c2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800038c2:	1101                	addi	sp,sp,-32
    800038c4:	ec06                	sd	ra,24(sp)
    800038c6:	e822                	sd	s0,16(sp)
    800038c8:	e426                	sd	s1,8(sp)
    800038ca:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800038cc:	00015517          	auipc	a0,0x15
    800038d0:	b3450513          	addi	a0,a0,-1228 # 80018400 <tickslock>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	302080e7          	jalr	770(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800038dc:	00005497          	auipc	s1,0x5
    800038e0:	0a84a483          	lw	s1,168(s1) # 80008984 <ticks>
  release(&tickslock);
    800038e4:	00015517          	auipc	a0,0x15
    800038e8:	b1c50513          	addi	a0,a0,-1252 # 80018400 <tickslock>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	39e080e7          	jalr	926(ra) # 80000c8a <release>
  return xticks;
}
    800038f4:	02049513          	slli	a0,s1,0x20
    800038f8:	9101                	srli	a0,a0,0x20
    800038fa:	60e2                	ld	ra,24(sp)
    800038fc:	6442                	ld	s0,16(sp)
    800038fe:	64a2                	ld	s1,8(sp)
    80003900:	6105                	addi	sp,sp,32
    80003902:	8082                	ret

0000000080003904 <sys_waitx>:
extern int readcount;

uint64
sys_waitx(void)
{
    80003904:	7139                	addi	sp,sp,-64
    80003906:	fc06                	sd	ra,56(sp)
    80003908:	f822                	sd	s0,48(sp)
    8000390a:	f426                	sd	s1,40(sp)
    8000390c:	f04a                	sd	s2,32(sp)
    8000390e:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003910:	fd840593          	addi	a1,s0,-40
    80003914:	4501                	li	a0,0
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	c8c080e7          	jalr	-884(ra) # 800035a2 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000391e:	fd040593          	addi	a1,s0,-48
    80003922:	4505                	li	a0,1
    80003924:	00000097          	auipc	ra,0x0
    80003928:	c7e080e7          	jalr	-898(ra) # 800035a2 <argaddr>
  argaddr(2, &addr2);
    8000392c:	fc840593          	addi	a1,s0,-56
    80003930:	4509                	li	a0,2
    80003932:	00000097          	auipc	ra,0x0
    80003936:	c70080e7          	jalr	-912(ra) # 800035a2 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000393a:	fc040613          	addi	a2,s0,-64
    8000393e:	fc440593          	addi	a1,s0,-60
    80003942:	fd843503          	ld	a0,-40(s0)
    80003946:	fffff097          	auipc	ra,0xfffff
    8000394a:	4a6080e7          	jalr	1190(ra) # 80002dec <waitx>
    8000394e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003950:	ffffe097          	auipc	ra,0xffffe
    80003954:	280080e7          	jalr	640(ra) # 80001bd0 <myproc>
    80003958:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000395a:	4691                	li	a3,4
    8000395c:	fc440613          	addi	a2,s0,-60
    80003960:	fd043583          	ld	a1,-48(s0)
    80003964:	6928                	ld	a0,80(a0)
    80003966:	ffffe097          	auipc	ra,0xffffe
    8000396a:	d06080e7          	jalr	-762(ra) # 8000166c <copyout>
    return -1;
    8000396e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003970:	00054f63          	bltz	a0,8000398e <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003974:	4691                	li	a3,4
    80003976:	fc040613          	addi	a2,s0,-64
    8000397a:	fc843583          	ld	a1,-56(s0)
    8000397e:	68a8                	ld	a0,80(s1)
    80003980:	ffffe097          	auipc	ra,0xffffe
    80003984:	cec080e7          	jalr	-788(ra) # 8000166c <copyout>
    80003988:	00054a63          	bltz	a0,8000399c <sys_waitx+0x98>
    return -1;
  return ret;
    8000398c:	87ca                	mv	a5,s2
}
    8000398e:	853e                	mv	a0,a5
    80003990:	70e2                	ld	ra,56(sp)
    80003992:	7442                	ld	s0,48(sp)
    80003994:	74a2                	ld	s1,40(sp)
    80003996:	7902                	ld	s2,32(sp)
    80003998:	6121                	addi	sp,sp,64
    8000399a:	8082                	ret
    return -1;
    8000399c:	57fd                	li	a5,-1
    8000399e:	bfc5                	j	8000398e <sys_waitx+0x8a>

00000000800039a0 <sys_getyear>:



int 
sys_getyear(void){
    800039a0:	1141                	addi	sp,sp,-16
    800039a2:	e422                	sd	s0,8(sp)
    800039a4:	0800                	addi	s0,sp,16
	return 1975;
}
    800039a6:	7b700513          	li	a0,1975
    800039aa:	6422                	ld	s0,8(sp)
    800039ac:	0141                	addi	sp,sp,16
    800039ae:	8082                	ret

00000000800039b0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800039b0:	7179                	addi	sp,sp,-48
    800039b2:	f406                	sd	ra,40(sp)
    800039b4:	f022                	sd	s0,32(sp)
    800039b6:	ec26                	sd	s1,24(sp)
    800039b8:	e84a                	sd	s2,16(sp)
    800039ba:	e44e                	sd	s3,8(sp)
    800039bc:	e052                	sd	s4,0(sp)
    800039be:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800039c0:	00005597          	auipc	a1,0x5
    800039c4:	be058593          	addi	a1,a1,-1056 # 800085a0 <syscalls+0xd8>
    800039c8:	00015517          	auipc	a0,0x15
    800039cc:	a5050513          	addi	a0,a0,-1456 # 80018418 <bcache>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	176080e7          	jalr	374(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800039d8:	0001d797          	auipc	a5,0x1d
    800039dc:	a4078793          	addi	a5,a5,-1472 # 80020418 <bcache+0x8000>
    800039e0:	0001d717          	auipc	a4,0x1d
    800039e4:	ca070713          	addi	a4,a4,-864 # 80020680 <bcache+0x8268>
    800039e8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800039ec:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800039f0:	00015497          	auipc	s1,0x15
    800039f4:	a4048493          	addi	s1,s1,-1472 # 80018430 <bcache+0x18>
    b->next = bcache.head.next;
    800039f8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800039fa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800039fc:	00005a17          	auipc	s4,0x5
    80003a00:	baca0a13          	addi	s4,s4,-1108 # 800085a8 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003a04:	2b893783          	ld	a5,696(s2)
    80003a08:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a0a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a0e:	85d2                	mv	a1,s4
    80003a10:	01048513          	addi	a0,s1,16
    80003a14:	00001097          	auipc	ra,0x1
    80003a18:	4c8080e7          	jalr	1224(ra) # 80004edc <initsleeplock>
    bcache.head.next->prev = b;
    80003a1c:	2b893783          	ld	a5,696(s2)
    80003a20:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003a22:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a26:	45848493          	addi	s1,s1,1112
    80003a2a:	fd349de3          	bne	s1,s3,80003a04 <binit+0x54>
  }
}
    80003a2e:	70a2                	ld	ra,40(sp)
    80003a30:	7402                	ld	s0,32(sp)
    80003a32:	64e2                	ld	s1,24(sp)
    80003a34:	6942                	ld	s2,16(sp)
    80003a36:	69a2                	ld	s3,8(sp)
    80003a38:	6a02                	ld	s4,0(sp)
    80003a3a:	6145                	addi	sp,sp,48
    80003a3c:	8082                	ret

0000000080003a3e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003a3e:	7179                	addi	sp,sp,-48
    80003a40:	f406                	sd	ra,40(sp)
    80003a42:	f022                	sd	s0,32(sp)
    80003a44:	ec26                	sd	s1,24(sp)
    80003a46:	e84a                	sd	s2,16(sp)
    80003a48:	e44e                	sd	s3,8(sp)
    80003a4a:	1800                	addi	s0,sp,48
    80003a4c:	892a                	mv	s2,a0
    80003a4e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003a50:	00015517          	auipc	a0,0x15
    80003a54:	9c850513          	addi	a0,a0,-1592 # 80018418 <bcache>
    80003a58:	ffffd097          	auipc	ra,0xffffd
    80003a5c:	17e080e7          	jalr	382(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003a60:	0001d497          	auipc	s1,0x1d
    80003a64:	c704b483          	ld	s1,-912(s1) # 800206d0 <bcache+0x82b8>
    80003a68:	0001d797          	auipc	a5,0x1d
    80003a6c:	c1878793          	addi	a5,a5,-1000 # 80020680 <bcache+0x8268>
    80003a70:	02f48f63          	beq	s1,a5,80003aae <bread+0x70>
    80003a74:	873e                	mv	a4,a5
    80003a76:	a021                	j	80003a7e <bread+0x40>
    80003a78:	68a4                	ld	s1,80(s1)
    80003a7a:	02e48a63          	beq	s1,a4,80003aae <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003a7e:	449c                	lw	a5,8(s1)
    80003a80:	ff279ce3          	bne	a5,s2,80003a78 <bread+0x3a>
    80003a84:	44dc                	lw	a5,12(s1)
    80003a86:	ff3799e3          	bne	a5,s3,80003a78 <bread+0x3a>
      b->refcnt++;
    80003a8a:	40bc                	lw	a5,64(s1)
    80003a8c:	2785                	addiw	a5,a5,1
    80003a8e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a90:	00015517          	auipc	a0,0x15
    80003a94:	98850513          	addi	a0,a0,-1656 # 80018418 <bcache>
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	1f2080e7          	jalr	498(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003aa0:	01048513          	addi	a0,s1,16
    80003aa4:	00001097          	auipc	ra,0x1
    80003aa8:	472080e7          	jalr	1138(ra) # 80004f16 <acquiresleep>
      return b;
    80003aac:	a8b9                	j	80003b0a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003aae:	0001d497          	auipc	s1,0x1d
    80003ab2:	c1a4b483          	ld	s1,-998(s1) # 800206c8 <bcache+0x82b0>
    80003ab6:	0001d797          	auipc	a5,0x1d
    80003aba:	bca78793          	addi	a5,a5,-1078 # 80020680 <bcache+0x8268>
    80003abe:	00f48863          	beq	s1,a5,80003ace <bread+0x90>
    80003ac2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003ac4:	40bc                	lw	a5,64(s1)
    80003ac6:	cf81                	beqz	a5,80003ade <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003ac8:	64a4                	ld	s1,72(s1)
    80003aca:	fee49de3          	bne	s1,a4,80003ac4 <bread+0x86>
  panic("bget: no buffers");
    80003ace:	00005517          	auipc	a0,0x5
    80003ad2:	ae250513          	addi	a0,a0,-1310 # 800085b0 <syscalls+0xe8>
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	a6a080e7          	jalr	-1430(ra) # 80000540 <panic>
      b->dev = dev;
    80003ade:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003ae2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003ae6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003aea:	4785                	li	a5,1
    80003aec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003aee:	00015517          	auipc	a0,0x15
    80003af2:	92a50513          	addi	a0,a0,-1750 # 80018418 <bcache>
    80003af6:	ffffd097          	auipc	ra,0xffffd
    80003afa:	194080e7          	jalr	404(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003afe:	01048513          	addi	a0,s1,16
    80003b02:	00001097          	auipc	ra,0x1
    80003b06:	414080e7          	jalr	1044(ra) # 80004f16 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b0a:	409c                	lw	a5,0(s1)
    80003b0c:	cb89                	beqz	a5,80003b1e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b0e:	8526                	mv	a0,s1
    80003b10:	70a2                	ld	ra,40(sp)
    80003b12:	7402                	ld	s0,32(sp)
    80003b14:	64e2                	ld	s1,24(sp)
    80003b16:	6942                	ld	s2,16(sp)
    80003b18:	69a2                	ld	s3,8(sp)
    80003b1a:	6145                	addi	sp,sp,48
    80003b1c:	8082                	ret
    virtio_disk_rw(b, 0);
    80003b1e:	4581                	li	a1,0
    80003b20:	8526                	mv	a0,s1
    80003b22:	00003097          	auipc	ra,0x3
    80003b26:	ff0080e7          	jalr	-16(ra) # 80006b12 <virtio_disk_rw>
    b->valid = 1;
    80003b2a:	4785                	li	a5,1
    80003b2c:	c09c                	sw	a5,0(s1)
  return b;
    80003b2e:	b7c5                	j	80003b0e <bread+0xd0>

0000000080003b30 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003b30:	1101                	addi	sp,sp,-32
    80003b32:	ec06                	sd	ra,24(sp)
    80003b34:	e822                	sd	s0,16(sp)
    80003b36:	e426                	sd	s1,8(sp)
    80003b38:	1000                	addi	s0,sp,32
    80003b3a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003b3c:	0541                	addi	a0,a0,16
    80003b3e:	00001097          	auipc	ra,0x1
    80003b42:	472080e7          	jalr	1138(ra) # 80004fb0 <holdingsleep>
    80003b46:	cd01                	beqz	a0,80003b5e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003b48:	4585                	li	a1,1
    80003b4a:	8526                	mv	a0,s1
    80003b4c:	00003097          	auipc	ra,0x3
    80003b50:	fc6080e7          	jalr	-58(ra) # 80006b12 <virtio_disk_rw>
}
    80003b54:	60e2                	ld	ra,24(sp)
    80003b56:	6442                	ld	s0,16(sp)
    80003b58:	64a2                	ld	s1,8(sp)
    80003b5a:	6105                	addi	sp,sp,32
    80003b5c:	8082                	ret
    panic("bwrite");
    80003b5e:	00005517          	auipc	a0,0x5
    80003b62:	a6a50513          	addi	a0,a0,-1430 # 800085c8 <syscalls+0x100>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	9da080e7          	jalr	-1574(ra) # 80000540 <panic>

0000000080003b6e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003b6e:	1101                	addi	sp,sp,-32
    80003b70:	ec06                	sd	ra,24(sp)
    80003b72:	e822                	sd	s0,16(sp)
    80003b74:	e426                	sd	s1,8(sp)
    80003b76:	e04a                	sd	s2,0(sp)
    80003b78:	1000                	addi	s0,sp,32
    80003b7a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003b7c:	01050913          	addi	s2,a0,16
    80003b80:	854a                	mv	a0,s2
    80003b82:	00001097          	auipc	ra,0x1
    80003b86:	42e080e7          	jalr	1070(ra) # 80004fb0 <holdingsleep>
    80003b8a:	c92d                	beqz	a0,80003bfc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003b8c:	854a                	mv	a0,s2
    80003b8e:	00001097          	auipc	ra,0x1
    80003b92:	3de080e7          	jalr	990(ra) # 80004f6c <releasesleep>

  acquire(&bcache.lock);
    80003b96:	00015517          	auipc	a0,0x15
    80003b9a:	88250513          	addi	a0,a0,-1918 # 80018418 <bcache>
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	038080e7          	jalr	56(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003ba6:	40bc                	lw	a5,64(s1)
    80003ba8:	37fd                	addiw	a5,a5,-1
    80003baa:	0007871b          	sext.w	a4,a5
    80003bae:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003bb0:	eb05                	bnez	a4,80003be0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003bb2:	68bc                	ld	a5,80(s1)
    80003bb4:	64b8                	ld	a4,72(s1)
    80003bb6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003bb8:	64bc                	ld	a5,72(s1)
    80003bba:	68b8                	ld	a4,80(s1)
    80003bbc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003bbe:	0001d797          	auipc	a5,0x1d
    80003bc2:	85a78793          	addi	a5,a5,-1958 # 80020418 <bcache+0x8000>
    80003bc6:	2b87b703          	ld	a4,696(a5)
    80003bca:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003bcc:	0001d717          	auipc	a4,0x1d
    80003bd0:	ab470713          	addi	a4,a4,-1356 # 80020680 <bcache+0x8268>
    80003bd4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003bd6:	2b87b703          	ld	a4,696(a5)
    80003bda:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003bdc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003be0:	00015517          	auipc	a0,0x15
    80003be4:	83850513          	addi	a0,a0,-1992 # 80018418 <bcache>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	0a2080e7          	jalr	162(ra) # 80000c8a <release>
}
    80003bf0:	60e2                	ld	ra,24(sp)
    80003bf2:	6442                	ld	s0,16(sp)
    80003bf4:	64a2                	ld	s1,8(sp)
    80003bf6:	6902                	ld	s2,0(sp)
    80003bf8:	6105                	addi	sp,sp,32
    80003bfa:	8082                	ret
    panic("brelse");
    80003bfc:	00005517          	auipc	a0,0x5
    80003c00:	9d450513          	addi	a0,a0,-1580 # 800085d0 <syscalls+0x108>
    80003c04:	ffffd097          	auipc	ra,0xffffd
    80003c08:	93c080e7          	jalr	-1732(ra) # 80000540 <panic>

0000000080003c0c <bpin>:

void
bpin(struct buf *b) {
    80003c0c:	1101                	addi	sp,sp,-32
    80003c0e:	ec06                	sd	ra,24(sp)
    80003c10:	e822                	sd	s0,16(sp)
    80003c12:	e426                	sd	s1,8(sp)
    80003c14:	1000                	addi	s0,sp,32
    80003c16:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c18:	00015517          	auipc	a0,0x15
    80003c1c:	80050513          	addi	a0,a0,-2048 # 80018418 <bcache>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	fb6080e7          	jalr	-74(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003c28:	40bc                	lw	a5,64(s1)
    80003c2a:	2785                	addiw	a5,a5,1
    80003c2c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c2e:	00014517          	auipc	a0,0x14
    80003c32:	7ea50513          	addi	a0,a0,2026 # 80018418 <bcache>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	054080e7          	jalr	84(ra) # 80000c8a <release>
}
    80003c3e:	60e2                	ld	ra,24(sp)
    80003c40:	6442                	ld	s0,16(sp)
    80003c42:	64a2                	ld	s1,8(sp)
    80003c44:	6105                	addi	sp,sp,32
    80003c46:	8082                	ret

0000000080003c48 <bunpin>:

void
bunpin(struct buf *b) {
    80003c48:	1101                	addi	sp,sp,-32
    80003c4a:	ec06                	sd	ra,24(sp)
    80003c4c:	e822                	sd	s0,16(sp)
    80003c4e:	e426                	sd	s1,8(sp)
    80003c50:	1000                	addi	s0,sp,32
    80003c52:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c54:	00014517          	auipc	a0,0x14
    80003c58:	7c450513          	addi	a0,a0,1988 # 80018418 <bcache>
    80003c5c:	ffffd097          	auipc	ra,0xffffd
    80003c60:	f7a080e7          	jalr	-134(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003c64:	40bc                	lw	a5,64(s1)
    80003c66:	37fd                	addiw	a5,a5,-1
    80003c68:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c6a:	00014517          	auipc	a0,0x14
    80003c6e:	7ae50513          	addi	a0,a0,1966 # 80018418 <bcache>
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	018080e7          	jalr	24(ra) # 80000c8a <release>
}
    80003c7a:	60e2                	ld	ra,24(sp)
    80003c7c:	6442                	ld	s0,16(sp)
    80003c7e:	64a2                	ld	s1,8(sp)
    80003c80:	6105                	addi	sp,sp,32
    80003c82:	8082                	ret

0000000080003c84 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003c84:	1101                	addi	sp,sp,-32
    80003c86:	ec06                	sd	ra,24(sp)
    80003c88:	e822                	sd	s0,16(sp)
    80003c8a:	e426                	sd	s1,8(sp)
    80003c8c:	e04a                	sd	s2,0(sp)
    80003c8e:	1000                	addi	s0,sp,32
    80003c90:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003c92:	00d5d59b          	srliw	a1,a1,0xd
    80003c96:	0001d797          	auipc	a5,0x1d
    80003c9a:	e5e7a783          	lw	a5,-418(a5) # 80020af4 <sb+0x1c>
    80003c9e:	9dbd                	addw	a1,a1,a5
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	d9e080e7          	jalr	-610(ra) # 80003a3e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003ca8:	0074f713          	andi	a4,s1,7
    80003cac:	4785                	li	a5,1
    80003cae:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003cb2:	14ce                	slli	s1,s1,0x33
    80003cb4:	90d9                	srli	s1,s1,0x36
    80003cb6:	00950733          	add	a4,a0,s1
    80003cba:	05874703          	lbu	a4,88(a4)
    80003cbe:	00e7f6b3          	and	a3,a5,a4
    80003cc2:	c69d                	beqz	a3,80003cf0 <bfree+0x6c>
    80003cc4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003cc6:	94aa                	add	s1,s1,a0
    80003cc8:	fff7c793          	not	a5,a5
    80003ccc:	8f7d                	and	a4,a4,a5
    80003cce:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003cd2:	00001097          	auipc	ra,0x1
    80003cd6:	126080e7          	jalr	294(ra) # 80004df8 <log_write>
  brelse(bp);
    80003cda:	854a                	mv	a0,s2
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	e92080e7          	jalr	-366(ra) # 80003b6e <brelse>
}
    80003ce4:	60e2                	ld	ra,24(sp)
    80003ce6:	6442                	ld	s0,16(sp)
    80003ce8:	64a2                	ld	s1,8(sp)
    80003cea:	6902                	ld	s2,0(sp)
    80003cec:	6105                	addi	sp,sp,32
    80003cee:	8082                	ret
    panic("freeing free block");
    80003cf0:	00005517          	auipc	a0,0x5
    80003cf4:	8e850513          	addi	a0,a0,-1816 # 800085d8 <syscalls+0x110>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	848080e7          	jalr	-1976(ra) # 80000540 <panic>

0000000080003d00 <balloc>:
{
    80003d00:	711d                	addi	sp,sp,-96
    80003d02:	ec86                	sd	ra,88(sp)
    80003d04:	e8a2                	sd	s0,80(sp)
    80003d06:	e4a6                	sd	s1,72(sp)
    80003d08:	e0ca                	sd	s2,64(sp)
    80003d0a:	fc4e                	sd	s3,56(sp)
    80003d0c:	f852                	sd	s4,48(sp)
    80003d0e:	f456                	sd	s5,40(sp)
    80003d10:	f05a                	sd	s6,32(sp)
    80003d12:	ec5e                	sd	s7,24(sp)
    80003d14:	e862                	sd	s8,16(sp)
    80003d16:	e466                	sd	s9,8(sp)
    80003d18:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003d1a:	0001d797          	auipc	a5,0x1d
    80003d1e:	dc27a783          	lw	a5,-574(a5) # 80020adc <sb+0x4>
    80003d22:	cff5                	beqz	a5,80003e1e <balloc+0x11e>
    80003d24:	8baa                	mv	s7,a0
    80003d26:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003d28:	0001db17          	auipc	s6,0x1d
    80003d2c:	db0b0b13          	addi	s6,s6,-592 # 80020ad8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d30:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003d32:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d34:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003d36:	6c89                	lui	s9,0x2
    80003d38:	a061                	j	80003dc0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003d3a:	97ca                	add	a5,a5,s2
    80003d3c:	8e55                	or	a2,a2,a3
    80003d3e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003d42:	854a                	mv	a0,s2
    80003d44:	00001097          	auipc	ra,0x1
    80003d48:	0b4080e7          	jalr	180(ra) # 80004df8 <log_write>
        brelse(bp);
    80003d4c:	854a                	mv	a0,s2
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	e20080e7          	jalr	-480(ra) # 80003b6e <brelse>
  bp = bread(dev, bno);
    80003d56:	85a6                	mv	a1,s1
    80003d58:	855e                	mv	a0,s7
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	ce4080e7          	jalr	-796(ra) # 80003a3e <bread>
    80003d62:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003d64:	40000613          	li	a2,1024
    80003d68:	4581                	li	a1,0
    80003d6a:	05850513          	addi	a0,a0,88
    80003d6e:	ffffd097          	auipc	ra,0xffffd
    80003d72:	f64080e7          	jalr	-156(ra) # 80000cd2 <memset>
  log_write(bp);
    80003d76:	854a                	mv	a0,s2
    80003d78:	00001097          	auipc	ra,0x1
    80003d7c:	080080e7          	jalr	128(ra) # 80004df8 <log_write>
  brelse(bp);
    80003d80:	854a                	mv	a0,s2
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	dec080e7          	jalr	-532(ra) # 80003b6e <brelse>
}
    80003d8a:	8526                	mv	a0,s1
    80003d8c:	60e6                	ld	ra,88(sp)
    80003d8e:	6446                	ld	s0,80(sp)
    80003d90:	64a6                	ld	s1,72(sp)
    80003d92:	6906                	ld	s2,64(sp)
    80003d94:	79e2                	ld	s3,56(sp)
    80003d96:	7a42                	ld	s4,48(sp)
    80003d98:	7aa2                	ld	s5,40(sp)
    80003d9a:	7b02                	ld	s6,32(sp)
    80003d9c:	6be2                	ld	s7,24(sp)
    80003d9e:	6c42                	ld	s8,16(sp)
    80003da0:	6ca2                	ld	s9,8(sp)
    80003da2:	6125                	addi	sp,sp,96
    80003da4:	8082                	ret
    brelse(bp);
    80003da6:	854a                	mv	a0,s2
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	dc6080e7          	jalr	-570(ra) # 80003b6e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003db0:	015c87bb          	addw	a5,s9,s5
    80003db4:	00078a9b          	sext.w	s5,a5
    80003db8:	004b2703          	lw	a4,4(s6)
    80003dbc:	06eaf163          	bgeu	s5,a4,80003e1e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003dc0:	41fad79b          	sraiw	a5,s5,0x1f
    80003dc4:	0137d79b          	srliw	a5,a5,0x13
    80003dc8:	015787bb          	addw	a5,a5,s5
    80003dcc:	40d7d79b          	sraiw	a5,a5,0xd
    80003dd0:	01cb2583          	lw	a1,28(s6)
    80003dd4:	9dbd                	addw	a1,a1,a5
    80003dd6:	855e                	mv	a0,s7
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	c66080e7          	jalr	-922(ra) # 80003a3e <bread>
    80003de0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003de2:	004b2503          	lw	a0,4(s6)
    80003de6:	000a849b          	sext.w	s1,s5
    80003dea:	8762                	mv	a4,s8
    80003dec:	faa4fde3          	bgeu	s1,a0,80003da6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003df0:	00777693          	andi	a3,a4,7
    80003df4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003df8:	41f7579b          	sraiw	a5,a4,0x1f
    80003dfc:	01d7d79b          	srliw	a5,a5,0x1d
    80003e00:	9fb9                	addw	a5,a5,a4
    80003e02:	4037d79b          	sraiw	a5,a5,0x3
    80003e06:	00f90633          	add	a2,s2,a5
    80003e0a:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003e0e:	00c6f5b3          	and	a1,a3,a2
    80003e12:	d585                	beqz	a1,80003d3a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e14:	2705                	addiw	a4,a4,1
    80003e16:	2485                	addiw	s1,s1,1
    80003e18:	fd471ae3          	bne	a4,s4,80003dec <balloc+0xec>
    80003e1c:	b769                	j	80003da6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003e1e:	00004517          	auipc	a0,0x4
    80003e22:	7d250513          	addi	a0,a0,2002 # 800085f0 <syscalls+0x128>
    80003e26:	ffffc097          	auipc	ra,0xffffc
    80003e2a:	764080e7          	jalr	1892(ra) # 8000058a <printf>
  return 0;
    80003e2e:	4481                	li	s1,0
    80003e30:	bfa9                	j	80003d8a <balloc+0x8a>

0000000080003e32 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003e32:	7179                	addi	sp,sp,-48
    80003e34:	f406                	sd	ra,40(sp)
    80003e36:	f022                	sd	s0,32(sp)
    80003e38:	ec26                	sd	s1,24(sp)
    80003e3a:	e84a                	sd	s2,16(sp)
    80003e3c:	e44e                	sd	s3,8(sp)
    80003e3e:	e052                	sd	s4,0(sp)
    80003e40:	1800                	addi	s0,sp,48
    80003e42:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003e44:	47ad                	li	a5,11
    80003e46:	02b7e863          	bltu	a5,a1,80003e76 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003e4a:	02059793          	slli	a5,a1,0x20
    80003e4e:	01e7d593          	srli	a1,a5,0x1e
    80003e52:	00b504b3          	add	s1,a0,a1
    80003e56:	0504a903          	lw	s2,80(s1)
    80003e5a:	06091e63          	bnez	s2,80003ed6 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003e5e:	4108                	lw	a0,0(a0)
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	ea0080e7          	jalr	-352(ra) # 80003d00 <balloc>
    80003e68:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003e6c:	06090563          	beqz	s2,80003ed6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003e70:	0524a823          	sw	s2,80(s1)
    80003e74:	a08d                	j	80003ed6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003e76:	ff45849b          	addiw	s1,a1,-12
    80003e7a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003e7e:	0ff00793          	li	a5,255
    80003e82:	08e7e563          	bltu	a5,a4,80003f0c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003e86:	08052903          	lw	s2,128(a0)
    80003e8a:	00091d63          	bnez	s2,80003ea4 <bmap+0x72>
      addr = balloc(ip->dev);
    80003e8e:	4108                	lw	a0,0(a0)
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	e70080e7          	jalr	-400(ra) # 80003d00 <balloc>
    80003e98:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003e9c:	02090d63          	beqz	s2,80003ed6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003ea0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003ea4:	85ca                	mv	a1,s2
    80003ea6:	0009a503          	lw	a0,0(s3)
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	b94080e7          	jalr	-1132(ra) # 80003a3e <bread>
    80003eb2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003eb4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003eb8:	02049713          	slli	a4,s1,0x20
    80003ebc:	01e75593          	srli	a1,a4,0x1e
    80003ec0:	00b784b3          	add	s1,a5,a1
    80003ec4:	0004a903          	lw	s2,0(s1)
    80003ec8:	02090063          	beqz	s2,80003ee8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003ecc:	8552                	mv	a0,s4
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	ca0080e7          	jalr	-864(ra) # 80003b6e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ed6:	854a                	mv	a0,s2
    80003ed8:	70a2                	ld	ra,40(sp)
    80003eda:	7402                	ld	s0,32(sp)
    80003edc:	64e2                	ld	s1,24(sp)
    80003ede:	6942                	ld	s2,16(sp)
    80003ee0:	69a2                	ld	s3,8(sp)
    80003ee2:	6a02                	ld	s4,0(sp)
    80003ee4:	6145                	addi	sp,sp,48
    80003ee6:	8082                	ret
      addr = balloc(ip->dev);
    80003ee8:	0009a503          	lw	a0,0(s3)
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	e14080e7          	jalr	-492(ra) # 80003d00 <balloc>
    80003ef4:	0005091b          	sext.w	s2,a0
      if(addr){
    80003ef8:	fc090ae3          	beqz	s2,80003ecc <bmap+0x9a>
        a[bn] = addr;
    80003efc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003f00:	8552                	mv	a0,s4
    80003f02:	00001097          	auipc	ra,0x1
    80003f06:	ef6080e7          	jalr	-266(ra) # 80004df8 <log_write>
    80003f0a:	b7c9                	j	80003ecc <bmap+0x9a>
  panic("bmap: out of range");
    80003f0c:	00004517          	auipc	a0,0x4
    80003f10:	6fc50513          	addi	a0,a0,1788 # 80008608 <syscalls+0x140>
    80003f14:	ffffc097          	auipc	ra,0xffffc
    80003f18:	62c080e7          	jalr	1580(ra) # 80000540 <panic>

0000000080003f1c <iget>:
{
    80003f1c:	7179                	addi	sp,sp,-48
    80003f1e:	f406                	sd	ra,40(sp)
    80003f20:	f022                	sd	s0,32(sp)
    80003f22:	ec26                	sd	s1,24(sp)
    80003f24:	e84a                	sd	s2,16(sp)
    80003f26:	e44e                	sd	s3,8(sp)
    80003f28:	e052                	sd	s4,0(sp)
    80003f2a:	1800                	addi	s0,sp,48
    80003f2c:	89aa                	mv	s3,a0
    80003f2e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003f30:	0001d517          	auipc	a0,0x1d
    80003f34:	bc850513          	addi	a0,a0,-1080 # 80020af8 <itable>
    80003f38:	ffffd097          	auipc	ra,0xffffd
    80003f3c:	c9e080e7          	jalr	-866(ra) # 80000bd6 <acquire>
  empty = 0;
    80003f40:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f42:	0001d497          	auipc	s1,0x1d
    80003f46:	bce48493          	addi	s1,s1,-1074 # 80020b10 <itable+0x18>
    80003f4a:	0001e697          	auipc	a3,0x1e
    80003f4e:	65668693          	addi	a3,a3,1622 # 800225a0 <log>
    80003f52:	a039                	j	80003f60 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003f54:	02090b63          	beqz	s2,80003f8a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f58:	08848493          	addi	s1,s1,136
    80003f5c:	02d48a63          	beq	s1,a3,80003f90 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003f60:	449c                	lw	a5,8(s1)
    80003f62:	fef059e3          	blez	a5,80003f54 <iget+0x38>
    80003f66:	4098                	lw	a4,0(s1)
    80003f68:	ff3716e3          	bne	a4,s3,80003f54 <iget+0x38>
    80003f6c:	40d8                	lw	a4,4(s1)
    80003f6e:	ff4713e3          	bne	a4,s4,80003f54 <iget+0x38>
      ip->ref++;
    80003f72:	2785                	addiw	a5,a5,1
    80003f74:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003f76:	0001d517          	auipc	a0,0x1d
    80003f7a:	b8250513          	addi	a0,a0,-1150 # 80020af8 <itable>
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	d0c080e7          	jalr	-756(ra) # 80000c8a <release>
      return ip;
    80003f86:	8926                	mv	s2,s1
    80003f88:	a03d                	j	80003fb6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003f8a:	f7f9                	bnez	a5,80003f58 <iget+0x3c>
    80003f8c:	8926                	mv	s2,s1
    80003f8e:	b7e9                	j	80003f58 <iget+0x3c>
  if(empty == 0)
    80003f90:	02090c63          	beqz	s2,80003fc8 <iget+0xac>
  ip->dev = dev;
    80003f94:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003f98:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003f9c:	4785                	li	a5,1
    80003f9e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003fa2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003fa6:	0001d517          	auipc	a0,0x1d
    80003faa:	b5250513          	addi	a0,a0,-1198 # 80020af8 <itable>
    80003fae:	ffffd097          	auipc	ra,0xffffd
    80003fb2:	cdc080e7          	jalr	-804(ra) # 80000c8a <release>
}
    80003fb6:	854a                	mv	a0,s2
    80003fb8:	70a2                	ld	ra,40(sp)
    80003fba:	7402                	ld	s0,32(sp)
    80003fbc:	64e2                	ld	s1,24(sp)
    80003fbe:	6942                	ld	s2,16(sp)
    80003fc0:	69a2                	ld	s3,8(sp)
    80003fc2:	6a02                	ld	s4,0(sp)
    80003fc4:	6145                	addi	sp,sp,48
    80003fc6:	8082                	ret
    panic("iget: no inodes");
    80003fc8:	00004517          	auipc	a0,0x4
    80003fcc:	65850513          	addi	a0,a0,1624 # 80008620 <syscalls+0x158>
    80003fd0:	ffffc097          	auipc	ra,0xffffc
    80003fd4:	570080e7          	jalr	1392(ra) # 80000540 <panic>

0000000080003fd8 <fsinit>:
fsinit(int dev) {
    80003fd8:	7179                	addi	sp,sp,-48
    80003fda:	f406                	sd	ra,40(sp)
    80003fdc:	f022                	sd	s0,32(sp)
    80003fde:	ec26                	sd	s1,24(sp)
    80003fe0:	e84a                	sd	s2,16(sp)
    80003fe2:	e44e                	sd	s3,8(sp)
    80003fe4:	1800                	addi	s0,sp,48
    80003fe6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003fe8:	4585                	li	a1,1
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	a54080e7          	jalr	-1452(ra) # 80003a3e <bread>
    80003ff2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ff4:	0001d997          	auipc	s3,0x1d
    80003ff8:	ae498993          	addi	s3,s3,-1308 # 80020ad8 <sb>
    80003ffc:	02000613          	li	a2,32
    80004000:	05850593          	addi	a1,a0,88
    80004004:	854e                	mv	a0,s3
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	d28080e7          	jalr	-728(ra) # 80000d2e <memmove>
  brelse(bp);
    8000400e:	8526                	mv	a0,s1
    80004010:	00000097          	auipc	ra,0x0
    80004014:	b5e080e7          	jalr	-1186(ra) # 80003b6e <brelse>
  if(sb.magic != FSMAGIC)
    80004018:	0009a703          	lw	a4,0(s3)
    8000401c:	102037b7          	lui	a5,0x10203
    80004020:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004024:	02f71263          	bne	a4,a5,80004048 <fsinit+0x70>
  initlog(dev, &sb);
    80004028:	0001d597          	auipc	a1,0x1d
    8000402c:	ab058593          	addi	a1,a1,-1360 # 80020ad8 <sb>
    80004030:	854a                	mv	a0,s2
    80004032:	00001097          	auipc	ra,0x1
    80004036:	b4a080e7          	jalr	-1206(ra) # 80004b7c <initlog>
}
    8000403a:	70a2                	ld	ra,40(sp)
    8000403c:	7402                	ld	s0,32(sp)
    8000403e:	64e2                	ld	s1,24(sp)
    80004040:	6942                	ld	s2,16(sp)
    80004042:	69a2                	ld	s3,8(sp)
    80004044:	6145                	addi	sp,sp,48
    80004046:	8082                	ret
    panic("invalid file system");
    80004048:	00004517          	auipc	a0,0x4
    8000404c:	5e850513          	addi	a0,a0,1512 # 80008630 <syscalls+0x168>
    80004050:	ffffc097          	auipc	ra,0xffffc
    80004054:	4f0080e7          	jalr	1264(ra) # 80000540 <panic>

0000000080004058 <iinit>:
{
    80004058:	7179                	addi	sp,sp,-48
    8000405a:	f406                	sd	ra,40(sp)
    8000405c:	f022                	sd	s0,32(sp)
    8000405e:	ec26                	sd	s1,24(sp)
    80004060:	e84a                	sd	s2,16(sp)
    80004062:	e44e                	sd	s3,8(sp)
    80004064:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004066:	00004597          	auipc	a1,0x4
    8000406a:	5e258593          	addi	a1,a1,1506 # 80008648 <syscalls+0x180>
    8000406e:	0001d517          	auipc	a0,0x1d
    80004072:	a8a50513          	addi	a0,a0,-1398 # 80020af8 <itable>
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	ad0080e7          	jalr	-1328(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000407e:	0001d497          	auipc	s1,0x1d
    80004082:	aa248493          	addi	s1,s1,-1374 # 80020b20 <itable+0x28>
    80004086:	0001e997          	auipc	s3,0x1e
    8000408a:	52a98993          	addi	s3,s3,1322 # 800225b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000408e:	00004917          	auipc	s2,0x4
    80004092:	5c290913          	addi	s2,s2,1474 # 80008650 <syscalls+0x188>
    80004096:	85ca                	mv	a1,s2
    80004098:	8526                	mv	a0,s1
    8000409a:	00001097          	auipc	ra,0x1
    8000409e:	e42080e7          	jalr	-446(ra) # 80004edc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800040a2:	08848493          	addi	s1,s1,136
    800040a6:	ff3498e3          	bne	s1,s3,80004096 <iinit+0x3e>
}
    800040aa:	70a2                	ld	ra,40(sp)
    800040ac:	7402                	ld	s0,32(sp)
    800040ae:	64e2                	ld	s1,24(sp)
    800040b0:	6942                	ld	s2,16(sp)
    800040b2:	69a2                	ld	s3,8(sp)
    800040b4:	6145                	addi	sp,sp,48
    800040b6:	8082                	ret

00000000800040b8 <ialloc>:
{
    800040b8:	715d                	addi	sp,sp,-80
    800040ba:	e486                	sd	ra,72(sp)
    800040bc:	e0a2                	sd	s0,64(sp)
    800040be:	fc26                	sd	s1,56(sp)
    800040c0:	f84a                	sd	s2,48(sp)
    800040c2:	f44e                	sd	s3,40(sp)
    800040c4:	f052                	sd	s4,32(sp)
    800040c6:	ec56                	sd	s5,24(sp)
    800040c8:	e85a                	sd	s6,16(sp)
    800040ca:	e45e                	sd	s7,8(sp)
    800040cc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800040ce:	0001d717          	auipc	a4,0x1d
    800040d2:	a1672703          	lw	a4,-1514(a4) # 80020ae4 <sb+0xc>
    800040d6:	4785                	li	a5,1
    800040d8:	04e7fa63          	bgeu	a5,a4,8000412c <ialloc+0x74>
    800040dc:	8aaa                	mv	s5,a0
    800040de:	8bae                	mv	s7,a1
    800040e0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800040e2:	0001da17          	auipc	s4,0x1d
    800040e6:	9f6a0a13          	addi	s4,s4,-1546 # 80020ad8 <sb>
    800040ea:	00048b1b          	sext.w	s6,s1
    800040ee:	0044d593          	srli	a1,s1,0x4
    800040f2:	018a2783          	lw	a5,24(s4)
    800040f6:	9dbd                	addw	a1,a1,a5
    800040f8:	8556                	mv	a0,s5
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	944080e7          	jalr	-1724(ra) # 80003a3e <bread>
    80004102:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004104:	05850993          	addi	s3,a0,88
    80004108:	00f4f793          	andi	a5,s1,15
    8000410c:	079a                	slli	a5,a5,0x6
    8000410e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004110:	00099783          	lh	a5,0(s3)
    80004114:	c3a1                	beqz	a5,80004154 <ialloc+0x9c>
    brelse(bp);
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	a58080e7          	jalr	-1448(ra) # 80003b6e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000411e:	0485                	addi	s1,s1,1
    80004120:	00ca2703          	lw	a4,12(s4)
    80004124:	0004879b          	sext.w	a5,s1
    80004128:	fce7e1e3          	bltu	a5,a4,800040ea <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000412c:	00004517          	auipc	a0,0x4
    80004130:	52c50513          	addi	a0,a0,1324 # 80008658 <syscalls+0x190>
    80004134:	ffffc097          	auipc	ra,0xffffc
    80004138:	456080e7          	jalr	1110(ra) # 8000058a <printf>
  return 0;
    8000413c:	4501                	li	a0,0
}
    8000413e:	60a6                	ld	ra,72(sp)
    80004140:	6406                	ld	s0,64(sp)
    80004142:	74e2                	ld	s1,56(sp)
    80004144:	7942                	ld	s2,48(sp)
    80004146:	79a2                	ld	s3,40(sp)
    80004148:	7a02                	ld	s4,32(sp)
    8000414a:	6ae2                	ld	s5,24(sp)
    8000414c:	6b42                	ld	s6,16(sp)
    8000414e:	6ba2                	ld	s7,8(sp)
    80004150:	6161                	addi	sp,sp,80
    80004152:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004154:	04000613          	li	a2,64
    80004158:	4581                	li	a1,0
    8000415a:	854e                	mv	a0,s3
    8000415c:	ffffd097          	auipc	ra,0xffffd
    80004160:	b76080e7          	jalr	-1162(ra) # 80000cd2 <memset>
      dip->type = type;
    80004164:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004168:	854a                	mv	a0,s2
    8000416a:	00001097          	auipc	ra,0x1
    8000416e:	c8e080e7          	jalr	-882(ra) # 80004df8 <log_write>
      brelse(bp);
    80004172:	854a                	mv	a0,s2
    80004174:	00000097          	auipc	ra,0x0
    80004178:	9fa080e7          	jalr	-1542(ra) # 80003b6e <brelse>
      return iget(dev, inum);
    8000417c:	85da                	mv	a1,s6
    8000417e:	8556                	mv	a0,s5
    80004180:	00000097          	auipc	ra,0x0
    80004184:	d9c080e7          	jalr	-612(ra) # 80003f1c <iget>
    80004188:	bf5d                	j	8000413e <ialloc+0x86>

000000008000418a <iupdate>:
{
    8000418a:	1101                	addi	sp,sp,-32
    8000418c:	ec06                	sd	ra,24(sp)
    8000418e:	e822                	sd	s0,16(sp)
    80004190:	e426                	sd	s1,8(sp)
    80004192:	e04a                	sd	s2,0(sp)
    80004194:	1000                	addi	s0,sp,32
    80004196:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004198:	415c                	lw	a5,4(a0)
    8000419a:	0047d79b          	srliw	a5,a5,0x4
    8000419e:	0001d597          	auipc	a1,0x1d
    800041a2:	9525a583          	lw	a1,-1710(a1) # 80020af0 <sb+0x18>
    800041a6:	9dbd                	addw	a1,a1,a5
    800041a8:	4108                	lw	a0,0(a0)
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	894080e7          	jalr	-1900(ra) # 80003a3e <bread>
    800041b2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800041b4:	05850793          	addi	a5,a0,88
    800041b8:	40d8                	lw	a4,4(s1)
    800041ba:	8b3d                	andi	a4,a4,15
    800041bc:	071a                	slli	a4,a4,0x6
    800041be:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800041c0:	04449703          	lh	a4,68(s1)
    800041c4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800041c8:	04649703          	lh	a4,70(s1)
    800041cc:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800041d0:	04849703          	lh	a4,72(s1)
    800041d4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800041d8:	04a49703          	lh	a4,74(s1)
    800041dc:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800041e0:	44f8                	lw	a4,76(s1)
    800041e2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800041e4:	03400613          	li	a2,52
    800041e8:	05048593          	addi	a1,s1,80
    800041ec:	00c78513          	addi	a0,a5,12
    800041f0:	ffffd097          	auipc	ra,0xffffd
    800041f4:	b3e080e7          	jalr	-1218(ra) # 80000d2e <memmove>
  log_write(bp);
    800041f8:	854a                	mv	a0,s2
    800041fa:	00001097          	auipc	ra,0x1
    800041fe:	bfe080e7          	jalr	-1026(ra) # 80004df8 <log_write>
  brelse(bp);
    80004202:	854a                	mv	a0,s2
    80004204:	00000097          	auipc	ra,0x0
    80004208:	96a080e7          	jalr	-1686(ra) # 80003b6e <brelse>
}
    8000420c:	60e2                	ld	ra,24(sp)
    8000420e:	6442                	ld	s0,16(sp)
    80004210:	64a2                	ld	s1,8(sp)
    80004212:	6902                	ld	s2,0(sp)
    80004214:	6105                	addi	sp,sp,32
    80004216:	8082                	ret

0000000080004218 <idup>:
{
    80004218:	1101                	addi	sp,sp,-32
    8000421a:	ec06                	sd	ra,24(sp)
    8000421c:	e822                	sd	s0,16(sp)
    8000421e:	e426                	sd	s1,8(sp)
    80004220:	1000                	addi	s0,sp,32
    80004222:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004224:	0001d517          	auipc	a0,0x1d
    80004228:	8d450513          	addi	a0,a0,-1836 # 80020af8 <itable>
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	9aa080e7          	jalr	-1622(ra) # 80000bd6 <acquire>
  ip->ref++;
    80004234:	449c                	lw	a5,8(s1)
    80004236:	2785                	addiw	a5,a5,1
    80004238:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000423a:	0001d517          	auipc	a0,0x1d
    8000423e:	8be50513          	addi	a0,a0,-1858 # 80020af8 <itable>
    80004242:	ffffd097          	auipc	ra,0xffffd
    80004246:	a48080e7          	jalr	-1464(ra) # 80000c8a <release>
}
    8000424a:	8526                	mv	a0,s1
    8000424c:	60e2                	ld	ra,24(sp)
    8000424e:	6442                	ld	s0,16(sp)
    80004250:	64a2                	ld	s1,8(sp)
    80004252:	6105                	addi	sp,sp,32
    80004254:	8082                	ret

0000000080004256 <ilock>:
{
    80004256:	1101                	addi	sp,sp,-32
    80004258:	ec06                	sd	ra,24(sp)
    8000425a:	e822                	sd	s0,16(sp)
    8000425c:	e426                	sd	s1,8(sp)
    8000425e:	e04a                	sd	s2,0(sp)
    80004260:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004262:	c115                	beqz	a0,80004286 <ilock+0x30>
    80004264:	84aa                	mv	s1,a0
    80004266:	451c                	lw	a5,8(a0)
    80004268:	00f05f63          	blez	a5,80004286 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000426c:	0541                	addi	a0,a0,16
    8000426e:	00001097          	auipc	ra,0x1
    80004272:	ca8080e7          	jalr	-856(ra) # 80004f16 <acquiresleep>
  if(ip->valid == 0){
    80004276:	40bc                	lw	a5,64(s1)
    80004278:	cf99                	beqz	a5,80004296 <ilock+0x40>
}
    8000427a:	60e2                	ld	ra,24(sp)
    8000427c:	6442                	ld	s0,16(sp)
    8000427e:	64a2                	ld	s1,8(sp)
    80004280:	6902                	ld	s2,0(sp)
    80004282:	6105                	addi	sp,sp,32
    80004284:	8082                	ret
    panic("ilock");
    80004286:	00004517          	auipc	a0,0x4
    8000428a:	3ea50513          	addi	a0,a0,1002 # 80008670 <syscalls+0x1a8>
    8000428e:	ffffc097          	auipc	ra,0xffffc
    80004292:	2b2080e7          	jalr	690(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004296:	40dc                	lw	a5,4(s1)
    80004298:	0047d79b          	srliw	a5,a5,0x4
    8000429c:	0001d597          	auipc	a1,0x1d
    800042a0:	8545a583          	lw	a1,-1964(a1) # 80020af0 <sb+0x18>
    800042a4:	9dbd                	addw	a1,a1,a5
    800042a6:	4088                	lw	a0,0(s1)
    800042a8:	fffff097          	auipc	ra,0xfffff
    800042ac:	796080e7          	jalr	1942(ra) # 80003a3e <bread>
    800042b0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800042b2:	05850593          	addi	a1,a0,88
    800042b6:	40dc                	lw	a5,4(s1)
    800042b8:	8bbd                	andi	a5,a5,15
    800042ba:	079a                	slli	a5,a5,0x6
    800042bc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800042be:	00059783          	lh	a5,0(a1)
    800042c2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800042c6:	00259783          	lh	a5,2(a1)
    800042ca:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800042ce:	00459783          	lh	a5,4(a1)
    800042d2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800042d6:	00659783          	lh	a5,6(a1)
    800042da:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800042de:	459c                	lw	a5,8(a1)
    800042e0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800042e2:	03400613          	li	a2,52
    800042e6:	05b1                	addi	a1,a1,12
    800042e8:	05048513          	addi	a0,s1,80
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	a42080e7          	jalr	-1470(ra) # 80000d2e <memmove>
    brelse(bp);
    800042f4:	854a                	mv	a0,s2
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	878080e7          	jalr	-1928(ra) # 80003b6e <brelse>
    ip->valid = 1;
    800042fe:	4785                	li	a5,1
    80004300:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004302:	04449783          	lh	a5,68(s1)
    80004306:	fbb5                	bnez	a5,8000427a <ilock+0x24>
      panic("ilock: no type");
    80004308:	00004517          	auipc	a0,0x4
    8000430c:	37050513          	addi	a0,a0,880 # 80008678 <syscalls+0x1b0>
    80004310:	ffffc097          	auipc	ra,0xffffc
    80004314:	230080e7          	jalr	560(ra) # 80000540 <panic>

0000000080004318 <iunlock>:
{
    80004318:	1101                	addi	sp,sp,-32
    8000431a:	ec06                	sd	ra,24(sp)
    8000431c:	e822                	sd	s0,16(sp)
    8000431e:	e426                	sd	s1,8(sp)
    80004320:	e04a                	sd	s2,0(sp)
    80004322:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004324:	c905                	beqz	a0,80004354 <iunlock+0x3c>
    80004326:	84aa                	mv	s1,a0
    80004328:	01050913          	addi	s2,a0,16
    8000432c:	854a                	mv	a0,s2
    8000432e:	00001097          	auipc	ra,0x1
    80004332:	c82080e7          	jalr	-894(ra) # 80004fb0 <holdingsleep>
    80004336:	cd19                	beqz	a0,80004354 <iunlock+0x3c>
    80004338:	449c                	lw	a5,8(s1)
    8000433a:	00f05d63          	blez	a5,80004354 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000433e:	854a                	mv	a0,s2
    80004340:	00001097          	auipc	ra,0x1
    80004344:	c2c080e7          	jalr	-980(ra) # 80004f6c <releasesleep>
}
    80004348:	60e2                	ld	ra,24(sp)
    8000434a:	6442                	ld	s0,16(sp)
    8000434c:	64a2                	ld	s1,8(sp)
    8000434e:	6902                	ld	s2,0(sp)
    80004350:	6105                	addi	sp,sp,32
    80004352:	8082                	ret
    panic("iunlock");
    80004354:	00004517          	auipc	a0,0x4
    80004358:	33450513          	addi	a0,a0,820 # 80008688 <syscalls+0x1c0>
    8000435c:	ffffc097          	auipc	ra,0xffffc
    80004360:	1e4080e7          	jalr	484(ra) # 80000540 <panic>

0000000080004364 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004364:	7179                	addi	sp,sp,-48
    80004366:	f406                	sd	ra,40(sp)
    80004368:	f022                	sd	s0,32(sp)
    8000436a:	ec26                	sd	s1,24(sp)
    8000436c:	e84a                	sd	s2,16(sp)
    8000436e:	e44e                	sd	s3,8(sp)
    80004370:	e052                	sd	s4,0(sp)
    80004372:	1800                	addi	s0,sp,48
    80004374:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004376:	05050493          	addi	s1,a0,80
    8000437a:	08050913          	addi	s2,a0,128
    8000437e:	a021                	j	80004386 <itrunc+0x22>
    80004380:	0491                	addi	s1,s1,4
    80004382:	01248d63          	beq	s1,s2,8000439c <itrunc+0x38>
    if(ip->addrs[i]){
    80004386:	408c                	lw	a1,0(s1)
    80004388:	dde5                	beqz	a1,80004380 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000438a:	0009a503          	lw	a0,0(s3)
    8000438e:	00000097          	auipc	ra,0x0
    80004392:	8f6080e7          	jalr	-1802(ra) # 80003c84 <bfree>
      ip->addrs[i] = 0;
    80004396:	0004a023          	sw	zero,0(s1)
    8000439a:	b7dd                	j	80004380 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000439c:	0809a583          	lw	a1,128(s3)
    800043a0:	e185                	bnez	a1,800043c0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800043a2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800043a6:	854e                	mv	a0,s3
    800043a8:	00000097          	auipc	ra,0x0
    800043ac:	de2080e7          	jalr	-542(ra) # 8000418a <iupdate>
}
    800043b0:	70a2                	ld	ra,40(sp)
    800043b2:	7402                	ld	s0,32(sp)
    800043b4:	64e2                	ld	s1,24(sp)
    800043b6:	6942                	ld	s2,16(sp)
    800043b8:	69a2                	ld	s3,8(sp)
    800043ba:	6a02                	ld	s4,0(sp)
    800043bc:	6145                	addi	sp,sp,48
    800043be:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800043c0:	0009a503          	lw	a0,0(s3)
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	67a080e7          	jalr	1658(ra) # 80003a3e <bread>
    800043cc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800043ce:	05850493          	addi	s1,a0,88
    800043d2:	45850913          	addi	s2,a0,1112
    800043d6:	a021                	j	800043de <itrunc+0x7a>
    800043d8:	0491                	addi	s1,s1,4
    800043da:	01248b63          	beq	s1,s2,800043f0 <itrunc+0x8c>
      if(a[j])
    800043de:	408c                	lw	a1,0(s1)
    800043e0:	dde5                	beqz	a1,800043d8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800043e2:	0009a503          	lw	a0,0(s3)
    800043e6:	00000097          	auipc	ra,0x0
    800043ea:	89e080e7          	jalr	-1890(ra) # 80003c84 <bfree>
    800043ee:	b7ed                	j	800043d8 <itrunc+0x74>
    brelse(bp);
    800043f0:	8552                	mv	a0,s4
    800043f2:	fffff097          	auipc	ra,0xfffff
    800043f6:	77c080e7          	jalr	1916(ra) # 80003b6e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800043fa:	0809a583          	lw	a1,128(s3)
    800043fe:	0009a503          	lw	a0,0(s3)
    80004402:	00000097          	auipc	ra,0x0
    80004406:	882080e7          	jalr	-1918(ra) # 80003c84 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000440a:	0809a023          	sw	zero,128(s3)
    8000440e:	bf51                	j	800043a2 <itrunc+0x3e>

0000000080004410 <iput>:
{
    80004410:	1101                	addi	sp,sp,-32
    80004412:	ec06                	sd	ra,24(sp)
    80004414:	e822                	sd	s0,16(sp)
    80004416:	e426                	sd	s1,8(sp)
    80004418:	e04a                	sd	s2,0(sp)
    8000441a:	1000                	addi	s0,sp,32
    8000441c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000441e:	0001c517          	auipc	a0,0x1c
    80004422:	6da50513          	addi	a0,a0,1754 # 80020af8 <itable>
    80004426:	ffffc097          	auipc	ra,0xffffc
    8000442a:	7b0080e7          	jalr	1968(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000442e:	4498                	lw	a4,8(s1)
    80004430:	4785                	li	a5,1
    80004432:	02f70363          	beq	a4,a5,80004458 <iput+0x48>
  ip->ref--;
    80004436:	449c                	lw	a5,8(s1)
    80004438:	37fd                	addiw	a5,a5,-1
    8000443a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000443c:	0001c517          	auipc	a0,0x1c
    80004440:	6bc50513          	addi	a0,a0,1724 # 80020af8 <itable>
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	846080e7          	jalr	-1978(ra) # 80000c8a <release>
}
    8000444c:	60e2                	ld	ra,24(sp)
    8000444e:	6442                	ld	s0,16(sp)
    80004450:	64a2                	ld	s1,8(sp)
    80004452:	6902                	ld	s2,0(sp)
    80004454:	6105                	addi	sp,sp,32
    80004456:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004458:	40bc                	lw	a5,64(s1)
    8000445a:	dff1                	beqz	a5,80004436 <iput+0x26>
    8000445c:	04a49783          	lh	a5,74(s1)
    80004460:	fbf9                	bnez	a5,80004436 <iput+0x26>
    acquiresleep(&ip->lock);
    80004462:	01048913          	addi	s2,s1,16
    80004466:	854a                	mv	a0,s2
    80004468:	00001097          	auipc	ra,0x1
    8000446c:	aae080e7          	jalr	-1362(ra) # 80004f16 <acquiresleep>
    release(&itable.lock);
    80004470:	0001c517          	auipc	a0,0x1c
    80004474:	68850513          	addi	a0,a0,1672 # 80020af8 <itable>
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	812080e7          	jalr	-2030(ra) # 80000c8a <release>
    itrunc(ip);
    80004480:	8526                	mv	a0,s1
    80004482:	00000097          	auipc	ra,0x0
    80004486:	ee2080e7          	jalr	-286(ra) # 80004364 <itrunc>
    ip->type = 0;
    8000448a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000448e:	8526                	mv	a0,s1
    80004490:	00000097          	auipc	ra,0x0
    80004494:	cfa080e7          	jalr	-774(ra) # 8000418a <iupdate>
    ip->valid = 0;
    80004498:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000449c:	854a                	mv	a0,s2
    8000449e:	00001097          	auipc	ra,0x1
    800044a2:	ace080e7          	jalr	-1330(ra) # 80004f6c <releasesleep>
    acquire(&itable.lock);
    800044a6:	0001c517          	auipc	a0,0x1c
    800044aa:	65250513          	addi	a0,a0,1618 # 80020af8 <itable>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	728080e7          	jalr	1832(ra) # 80000bd6 <acquire>
    800044b6:	b741                	j	80004436 <iput+0x26>

00000000800044b8 <iunlockput>:
{
    800044b8:	1101                	addi	sp,sp,-32
    800044ba:	ec06                	sd	ra,24(sp)
    800044bc:	e822                	sd	s0,16(sp)
    800044be:	e426                	sd	s1,8(sp)
    800044c0:	1000                	addi	s0,sp,32
    800044c2:	84aa                	mv	s1,a0
  iunlock(ip);
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	e54080e7          	jalr	-428(ra) # 80004318 <iunlock>
  iput(ip);
    800044cc:	8526                	mv	a0,s1
    800044ce:	00000097          	auipc	ra,0x0
    800044d2:	f42080e7          	jalr	-190(ra) # 80004410 <iput>
}
    800044d6:	60e2                	ld	ra,24(sp)
    800044d8:	6442                	ld	s0,16(sp)
    800044da:	64a2                	ld	s1,8(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret

00000000800044e0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800044e0:	1141                	addi	sp,sp,-16
    800044e2:	e422                	sd	s0,8(sp)
    800044e4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800044e6:	411c                	lw	a5,0(a0)
    800044e8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800044ea:	415c                	lw	a5,4(a0)
    800044ec:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800044ee:	04451783          	lh	a5,68(a0)
    800044f2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800044f6:	04a51783          	lh	a5,74(a0)
    800044fa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800044fe:	04c56783          	lwu	a5,76(a0)
    80004502:	e99c                	sd	a5,16(a1)
}
    80004504:	6422                	ld	s0,8(sp)
    80004506:	0141                	addi	sp,sp,16
    80004508:	8082                	ret

000000008000450a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000450a:	457c                	lw	a5,76(a0)
    8000450c:	0ed7e963          	bltu	a5,a3,800045fe <readi+0xf4>
{
    80004510:	7159                	addi	sp,sp,-112
    80004512:	f486                	sd	ra,104(sp)
    80004514:	f0a2                	sd	s0,96(sp)
    80004516:	eca6                	sd	s1,88(sp)
    80004518:	e8ca                	sd	s2,80(sp)
    8000451a:	e4ce                	sd	s3,72(sp)
    8000451c:	e0d2                	sd	s4,64(sp)
    8000451e:	fc56                	sd	s5,56(sp)
    80004520:	f85a                	sd	s6,48(sp)
    80004522:	f45e                	sd	s7,40(sp)
    80004524:	f062                	sd	s8,32(sp)
    80004526:	ec66                	sd	s9,24(sp)
    80004528:	e86a                	sd	s10,16(sp)
    8000452a:	e46e                	sd	s11,8(sp)
    8000452c:	1880                	addi	s0,sp,112
    8000452e:	8b2a                	mv	s6,a0
    80004530:	8bae                	mv	s7,a1
    80004532:	8a32                	mv	s4,a2
    80004534:	84b6                	mv	s1,a3
    80004536:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004538:	9f35                	addw	a4,a4,a3
    return 0;
    8000453a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000453c:	0ad76063          	bltu	a4,a3,800045dc <readi+0xd2>
  if(off + n > ip->size)
    80004540:	00e7f463          	bgeu	a5,a4,80004548 <readi+0x3e>
    n = ip->size - off;
    80004544:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004548:	0a0a8963          	beqz	s5,800045fa <readi+0xf0>
    8000454c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000454e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004552:	5c7d                	li	s8,-1
    80004554:	a82d                	j	8000458e <readi+0x84>
    80004556:	020d1d93          	slli	s11,s10,0x20
    8000455a:	020ddd93          	srli	s11,s11,0x20
    8000455e:	05890613          	addi	a2,s2,88
    80004562:	86ee                	mv	a3,s11
    80004564:	963a                	add	a2,a2,a4
    80004566:	85d2                	mv	a1,s4
    80004568:	855e                	mv	a0,s7
    8000456a:	ffffe097          	auipc	ra,0xffffe
    8000456e:	720080e7          	jalr	1824(ra) # 80002c8a <either_copyout>
    80004572:	05850d63          	beq	a0,s8,800045cc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004576:	854a                	mv	a0,s2
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	5f6080e7          	jalr	1526(ra) # 80003b6e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004580:	013d09bb          	addw	s3,s10,s3
    80004584:	009d04bb          	addw	s1,s10,s1
    80004588:	9a6e                	add	s4,s4,s11
    8000458a:	0559f763          	bgeu	s3,s5,800045d8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000458e:	00a4d59b          	srliw	a1,s1,0xa
    80004592:	855a                	mv	a0,s6
    80004594:	00000097          	auipc	ra,0x0
    80004598:	89e080e7          	jalr	-1890(ra) # 80003e32 <bmap>
    8000459c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800045a0:	cd85                	beqz	a1,800045d8 <readi+0xce>
    bp = bread(ip->dev, addr);
    800045a2:	000b2503          	lw	a0,0(s6)
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	498080e7          	jalr	1176(ra) # 80003a3e <bread>
    800045ae:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800045b0:	3ff4f713          	andi	a4,s1,1023
    800045b4:	40ec87bb          	subw	a5,s9,a4
    800045b8:	413a86bb          	subw	a3,s5,s3
    800045bc:	8d3e                	mv	s10,a5
    800045be:	2781                	sext.w	a5,a5
    800045c0:	0006861b          	sext.w	a2,a3
    800045c4:	f8f679e3          	bgeu	a2,a5,80004556 <readi+0x4c>
    800045c8:	8d36                	mv	s10,a3
    800045ca:	b771                	j	80004556 <readi+0x4c>
      brelse(bp);
    800045cc:	854a                	mv	a0,s2
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	5a0080e7          	jalr	1440(ra) # 80003b6e <brelse>
      tot = -1;
    800045d6:	59fd                	li	s3,-1
  }
  return tot;
    800045d8:	0009851b          	sext.w	a0,s3
}
    800045dc:	70a6                	ld	ra,104(sp)
    800045de:	7406                	ld	s0,96(sp)
    800045e0:	64e6                	ld	s1,88(sp)
    800045e2:	6946                	ld	s2,80(sp)
    800045e4:	69a6                	ld	s3,72(sp)
    800045e6:	6a06                	ld	s4,64(sp)
    800045e8:	7ae2                	ld	s5,56(sp)
    800045ea:	7b42                	ld	s6,48(sp)
    800045ec:	7ba2                	ld	s7,40(sp)
    800045ee:	7c02                	ld	s8,32(sp)
    800045f0:	6ce2                	ld	s9,24(sp)
    800045f2:	6d42                	ld	s10,16(sp)
    800045f4:	6da2                	ld	s11,8(sp)
    800045f6:	6165                	addi	sp,sp,112
    800045f8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045fa:	89d6                	mv	s3,s5
    800045fc:	bff1                	j	800045d8 <readi+0xce>
    return 0;
    800045fe:	4501                	li	a0,0
}
    80004600:	8082                	ret

0000000080004602 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004602:	457c                	lw	a5,76(a0)
    80004604:	10d7e863          	bltu	a5,a3,80004714 <writei+0x112>
{
    80004608:	7159                	addi	sp,sp,-112
    8000460a:	f486                	sd	ra,104(sp)
    8000460c:	f0a2                	sd	s0,96(sp)
    8000460e:	eca6                	sd	s1,88(sp)
    80004610:	e8ca                	sd	s2,80(sp)
    80004612:	e4ce                	sd	s3,72(sp)
    80004614:	e0d2                	sd	s4,64(sp)
    80004616:	fc56                	sd	s5,56(sp)
    80004618:	f85a                	sd	s6,48(sp)
    8000461a:	f45e                	sd	s7,40(sp)
    8000461c:	f062                	sd	s8,32(sp)
    8000461e:	ec66                	sd	s9,24(sp)
    80004620:	e86a                	sd	s10,16(sp)
    80004622:	e46e                	sd	s11,8(sp)
    80004624:	1880                	addi	s0,sp,112
    80004626:	8aaa                	mv	s5,a0
    80004628:	8bae                	mv	s7,a1
    8000462a:	8a32                	mv	s4,a2
    8000462c:	8936                	mv	s2,a3
    8000462e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004630:	00e687bb          	addw	a5,a3,a4
    80004634:	0ed7e263          	bltu	a5,a3,80004718 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004638:	00043737          	lui	a4,0x43
    8000463c:	0ef76063          	bltu	a4,a5,8000471c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004640:	0c0b0863          	beqz	s6,80004710 <writei+0x10e>
    80004644:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004646:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000464a:	5c7d                	li	s8,-1
    8000464c:	a091                	j	80004690 <writei+0x8e>
    8000464e:	020d1d93          	slli	s11,s10,0x20
    80004652:	020ddd93          	srli	s11,s11,0x20
    80004656:	05848513          	addi	a0,s1,88
    8000465a:	86ee                	mv	a3,s11
    8000465c:	8652                	mv	a2,s4
    8000465e:	85de                	mv	a1,s7
    80004660:	953a                	add	a0,a0,a4
    80004662:	ffffe097          	auipc	ra,0xffffe
    80004666:	67e080e7          	jalr	1662(ra) # 80002ce0 <either_copyin>
    8000466a:	07850263          	beq	a0,s8,800046ce <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000466e:	8526                	mv	a0,s1
    80004670:	00000097          	auipc	ra,0x0
    80004674:	788080e7          	jalr	1928(ra) # 80004df8 <log_write>
    brelse(bp);
    80004678:	8526                	mv	a0,s1
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	4f4080e7          	jalr	1268(ra) # 80003b6e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004682:	013d09bb          	addw	s3,s10,s3
    80004686:	012d093b          	addw	s2,s10,s2
    8000468a:	9a6e                	add	s4,s4,s11
    8000468c:	0569f663          	bgeu	s3,s6,800046d8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004690:	00a9559b          	srliw	a1,s2,0xa
    80004694:	8556                	mv	a0,s5
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	79c080e7          	jalr	1948(ra) # 80003e32 <bmap>
    8000469e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800046a2:	c99d                	beqz	a1,800046d8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800046a4:	000aa503          	lw	a0,0(s5)
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	396080e7          	jalr	918(ra) # 80003a3e <bread>
    800046b0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800046b2:	3ff97713          	andi	a4,s2,1023
    800046b6:	40ec87bb          	subw	a5,s9,a4
    800046ba:	413b06bb          	subw	a3,s6,s3
    800046be:	8d3e                	mv	s10,a5
    800046c0:	2781                	sext.w	a5,a5
    800046c2:	0006861b          	sext.w	a2,a3
    800046c6:	f8f674e3          	bgeu	a2,a5,8000464e <writei+0x4c>
    800046ca:	8d36                	mv	s10,a3
    800046cc:	b749                	j	8000464e <writei+0x4c>
      brelse(bp);
    800046ce:	8526                	mv	a0,s1
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	49e080e7          	jalr	1182(ra) # 80003b6e <brelse>
  }

  if(off > ip->size)
    800046d8:	04caa783          	lw	a5,76(s5)
    800046dc:	0127f463          	bgeu	a5,s2,800046e4 <writei+0xe2>
    ip->size = off;
    800046e0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800046e4:	8556                	mv	a0,s5
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	aa4080e7          	jalr	-1372(ra) # 8000418a <iupdate>

  return tot;
    800046ee:	0009851b          	sext.w	a0,s3
}
    800046f2:	70a6                	ld	ra,104(sp)
    800046f4:	7406                	ld	s0,96(sp)
    800046f6:	64e6                	ld	s1,88(sp)
    800046f8:	6946                	ld	s2,80(sp)
    800046fa:	69a6                	ld	s3,72(sp)
    800046fc:	6a06                	ld	s4,64(sp)
    800046fe:	7ae2                	ld	s5,56(sp)
    80004700:	7b42                	ld	s6,48(sp)
    80004702:	7ba2                	ld	s7,40(sp)
    80004704:	7c02                	ld	s8,32(sp)
    80004706:	6ce2                	ld	s9,24(sp)
    80004708:	6d42                	ld	s10,16(sp)
    8000470a:	6da2                	ld	s11,8(sp)
    8000470c:	6165                	addi	sp,sp,112
    8000470e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004710:	89da                	mv	s3,s6
    80004712:	bfc9                	j	800046e4 <writei+0xe2>
    return -1;
    80004714:	557d                	li	a0,-1
}
    80004716:	8082                	ret
    return -1;
    80004718:	557d                	li	a0,-1
    8000471a:	bfe1                	j	800046f2 <writei+0xf0>
    return -1;
    8000471c:	557d                	li	a0,-1
    8000471e:	bfd1                	j	800046f2 <writei+0xf0>

0000000080004720 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004720:	1141                	addi	sp,sp,-16
    80004722:	e406                	sd	ra,8(sp)
    80004724:	e022                	sd	s0,0(sp)
    80004726:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004728:	4639                	li	a2,14
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	678080e7          	jalr	1656(ra) # 80000da2 <strncmp>
}
    80004732:	60a2                	ld	ra,8(sp)
    80004734:	6402                	ld	s0,0(sp)
    80004736:	0141                	addi	sp,sp,16
    80004738:	8082                	ret

000000008000473a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000473a:	7139                	addi	sp,sp,-64
    8000473c:	fc06                	sd	ra,56(sp)
    8000473e:	f822                	sd	s0,48(sp)
    80004740:	f426                	sd	s1,40(sp)
    80004742:	f04a                	sd	s2,32(sp)
    80004744:	ec4e                	sd	s3,24(sp)
    80004746:	e852                	sd	s4,16(sp)
    80004748:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000474a:	04451703          	lh	a4,68(a0)
    8000474e:	4785                	li	a5,1
    80004750:	00f71a63          	bne	a4,a5,80004764 <dirlookup+0x2a>
    80004754:	892a                	mv	s2,a0
    80004756:	89ae                	mv	s3,a1
    80004758:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000475a:	457c                	lw	a5,76(a0)
    8000475c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000475e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004760:	e79d                	bnez	a5,8000478e <dirlookup+0x54>
    80004762:	a8a5                	j	800047da <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004764:	00004517          	auipc	a0,0x4
    80004768:	f2c50513          	addi	a0,a0,-212 # 80008690 <syscalls+0x1c8>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	dd4080e7          	jalr	-556(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004774:	00004517          	auipc	a0,0x4
    80004778:	f3450513          	addi	a0,a0,-204 # 800086a8 <syscalls+0x1e0>
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	dc4080e7          	jalr	-572(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004784:	24c1                	addiw	s1,s1,16
    80004786:	04c92783          	lw	a5,76(s2)
    8000478a:	04f4f763          	bgeu	s1,a5,800047d8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000478e:	4741                	li	a4,16
    80004790:	86a6                	mv	a3,s1
    80004792:	fc040613          	addi	a2,s0,-64
    80004796:	4581                	li	a1,0
    80004798:	854a                	mv	a0,s2
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	d70080e7          	jalr	-656(ra) # 8000450a <readi>
    800047a2:	47c1                	li	a5,16
    800047a4:	fcf518e3          	bne	a0,a5,80004774 <dirlookup+0x3a>
    if(de.inum == 0)
    800047a8:	fc045783          	lhu	a5,-64(s0)
    800047ac:	dfe1                	beqz	a5,80004784 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800047ae:	fc240593          	addi	a1,s0,-62
    800047b2:	854e                	mv	a0,s3
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	f6c080e7          	jalr	-148(ra) # 80004720 <namecmp>
    800047bc:	f561                	bnez	a0,80004784 <dirlookup+0x4a>
      if(poff)
    800047be:	000a0463          	beqz	s4,800047c6 <dirlookup+0x8c>
        *poff = off;
    800047c2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800047c6:	fc045583          	lhu	a1,-64(s0)
    800047ca:	00092503          	lw	a0,0(s2)
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	74e080e7          	jalr	1870(ra) # 80003f1c <iget>
    800047d6:	a011                	j	800047da <dirlookup+0xa0>
  return 0;
    800047d8:	4501                	li	a0,0
}
    800047da:	70e2                	ld	ra,56(sp)
    800047dc:	7442                	ld	s0,48(sp)
    800047de:	74a2                	ld	s1,40(sp)
    800047e0:	7902                	ld	s2,32(sp)
    800047e2:	69e2                	ld	s3,24(sp)
    800047e4:	6a42                	ld	s4,16(sp)
    800047e6:	6121                	addi	sp,sp,64
    800047e8:	8082                	ret

00000000800047ea <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800047ea:	711d                	addi	sp,sp,-96
    800047ec:	ec86                	sd	ra,88(sp)
    800047ee:	e8a2                	sd	s0,80(sp)
    800047f0:	e4a6                	sd	s1,72(sp)
    800047f2:	e0ca                	sd	s2,64(sp)
    800047f4:	fc4e                	sd	s3,56(sp)
    800047f6:	f852                	sd	s4,48(sp)
    800047f8:	f456                	sd	s5,40(sp)
    800047fa:	f05a                	sd	s6,32(sp)
    800047fc:	ec5e                	sd	s7,24(sp)
    800047fe:	e862                	sd	s8,16(sp)
    80004800:	e466                	sd	s9,8(sp)
    80004802:	e06a                	sd	s10,0(sp)
    80004804:	1080                	addi	s0,sp,96
    80004806:	84aa                	mv	s1,a0
    80004808:	8b2e                	mv	s6,a1
    8000480a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000480c:	00054703          	lbu	a4,0(a0)
    80004810:	02f00793          	li	a5,47
    80004814:	02f70363          	beq	a4,a5,8000483a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004818:	ffffd097          	auipc	ra,0xffffd
    8000481c:	3b8080e7          	jalr	952(ra) # 80001bd0 <myproc>
    80004820:	15053503          	ld	a0,336(a0)
    80004824:	00000097          	auipc	ra,0x0
    80004828:	9f4080e7          	jalr	-1548(ra) # 80004218 <idup>
    8000482c:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000482e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004832:	4cb5                	li	s9,13
  len = path - s;
    80004834:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004836:	4c05                	li	s8,1
    80004838:	a87d                	j	800048f6 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000483a:	4585                	li	a1,1
    8000483c:	4505                	li	a0,1
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	6de080e7          	jalr	1758(ra) # 80003f1c <iget>
    80004846:	8a2a                	mv	s4,a0
    80004848:	b7dd                	j	8000482e <namex+0x44>
      iunlockput(ip);
    8000484a:	8552                	mv	a0,s4
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	c6c080e7          	jalr	-916(ra) # 800044b8 <iunlockput>
      return 0;
    80004854:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004856:	8552                	mv	a0,s4
    80004858:	60e6                	ld	ra,88(sp)
    8000485a:	6446                	ld	s0,80(sp)
    8000485c:	64a6                	ld	s1,72(sp)
    8000485e:	6906                	ld	s2,64(sp)
    80004860:	79e2                	ld	s3,56(sp)
    80004862:	7a42                	ld	s4,48(sp)
    80004864:	7aa2                	ld	s5,40(sp)
    80004866:	7b02                	ld	s6,32(sp)
    80004868:	6be2                	ld	s7,24(sp)
    8000486a:	6c42                	ld	s8,16(sp)
    8000486c:	6ca2                	ld	s9,8(sp)
    8000486e:	6d02                	ld	s10,0(sp)
    80004870:	6125                	addi	sp,sp,96
    80004872:	8082                	ret
      iunlock(ip);
    80004874:	8552                	mv	a0,s4
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	aa2080e7          	jalr	-1374(ra) # 80004318 <iunlock>
      return ip;
    8000487e:	bfe1                	j	80004856 <namex+0x6c>
      iunlockput(ip);
    80004880:	8552                	mv	a0,s4
    80004882:	00000097          	auipc	ra,0x0
    80004886:	c36080e7          	jalr	-970(ra) # 800044b8 <iunlockput>
      return 0;
    8000488a:	8a4e                	mv	s4,s3
    8000488c:	b7e9                	j	80004856 <namex+0x6c>
  len = path - s;
    8000488e:	40998633          	sub	a2,s3,s1
    80004892:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004896:	09acd863          	bge	s9,s10,80004926 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000489a:	4639                	li	a2,14
    8000489c:	85a6                	mv	a1,s1
    8000489e:	8556                	mv	a0,s5
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	48e080e7          	jalr	1166(ra) # 80000d2e <memmove>
    800048a8:	84ce                	mv	s1,s3
  while(*path == '/')
    800048aa:	0004c783          	lbu	a5,0(s1)
    800048ae:	01279763          	bne	a5,s2,800048bc <namex+0xd2>
    path++;
    800048b2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800048b4:	0004c783          	lbu	a5,0(s1)
    800048b8:	ff278de3          	beq	a5,s2,800048b2 <namex+0xc8>
    ilock(ip);
    800048bc:	8552                	mv	a0,s4
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	998080e7          	jalr	-1640(ra) # 80004256 <ilock>
    if(ip->type != T_DIR){
    800048c6:	044a1783          	lh	a5,68(s4)
    800048ca:	f98790e3          	bne	a5,s8,8000484a <namex+0x60>
    if(nameiparent && *path == '\0'){
    800048ce:	000b0563          	beqz	s6,800048d8 <namex+0xee>
    800048d2:	0004c783          	lbu	a5,0(s1)
    800048d6:	dfd9                	beqz	a5,80004874 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800048d8:	865e                	mv	a2,s7
    800048da:	85d6                	mv	a1,s5
    800048dc:	8552                	mv	a0,s4
    800048de:	00000097          	auipc	ra,0x0
    800048e2:	e5c080e7          	jalr	-420(ra) # 8000473a <dirlookup>
    800048e6:	89aa                	mv	s3,a0
    800048e8:	dd41                	beqz	a0,80004880 <namex+0x96>
    iunlockput(ip);
    800048ea:	8552                	mv	a0,s4
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	bcc080e7          	jalr	-1076(ra) # 800044b8 <iunlockput>
    ip = next;
    800048f4:	8a4e                	mv	s4,s3
  while(*path == '/')
    800048f6:	0004c783          	lbu	a5,0(s1)
    800048fa:	01279763          	bne	a5,s2,80004908 <namex+0x11e>
    path++;
    800048fe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004900:	0004c783          	lbu	a5,0(s1)
    80004904:	ff278de3          	beq	a5,s2,800048fe <namex+0x114>
  if(*path == 0)
    80004908:	cb9d                	beqz	a5,8000493e <namex+0x154>
  while(*path != '/' && *path != 0)
    8000490a:	0004c783          	lbu	a5,0(s1)
    8000490e:	89a6                	mv	s3,s1
  len = path - s;
    80004910:	8d5e                	mv	s10,s7
    80004912:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004914:	01278963          	beq	a5,s2,80004926 <namex+0x13c>
    80004918:	dbbd                	beqz	a5,8000488e <namex+0xa4>
    path++;
    8000491a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000491c:	0009c783          	lbu	a5,0(s3)
    80004920:	ff279ce3          	bne	a5,s2,80004918 <namex+0x12e>
    80004924:	b7ad                	j	8000488e <namex+0xa4>
    memmove(name, s, len);
    80004926:	2601                	sext.w	a2,a2
    80004928:	85a6                	mv	a1,s1
    8000492a:	8556                	mv	a0,s5
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	402080e7          	jalr	1026(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004934:	9d56                	add	s10,s10,s5
    80004936:	000d0023          	sb	zero,0(s10)
    8000493a:	84ce                	mv	s1,s3
    8000493c:	b7bd                	j	800048aa <namex+0xc0>
  if(nameiparent){
    8000493e:	f00b0ce3          	beqz	s6,80004856 <namex+0x6c>
    iput(ip);
    80004942:	8552                	mv	a0,s4
    80004944:	00000097          	auipc	ra,0x0
    80004948:	acc080e7          	jalr	-1332(ra) # 80004410 <iput>
    return 0;
    8000494c:	4a01                	li	s4,0
    8000494e:	b721                	j	80004856 <namex+0x6c>

0000000080004950 <dirlink>:
{
    80004950:	7139                	addi	sp,sp,-64
    80004952:	fc06                	sd	ra,56(sp)
    80004954:	f822                	sd	s0,48(sp)
    80004956:	f426                	sd	s1,40(sp)
    80004958:	f04a                	sd	s2,32(sp)
    8000495a:	ec4e                	sd	s3,24(sp)
    8000495c:	e852                	sd	s4,16(sp)
    8000495e:	0080                	addi	s0,sp,64
    80004960:	892a                	mv	s2,a0
    80004962:	8a2e                	mv	s4,a1
    80004964:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004966:	4601                	li	a2,0
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	dd2080e7          	jalr	-558(ra) # 8000473a <dirlookup>
    80004970:	e93d                	bnez	a0,800049e6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004972:	04c92483          	lw	s1,76(s2)
    80004976:	c49d                	beqz	s1,800049a4 <dirlink+0x54>
    80004978:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000497a:	4741                	li	a4,16
    8000497c:	86a6                	mv	a3,s1
    8000497e:	fc040613          	addi	a2,s0,-64
    80004982:	4581                	li	a1,0
    80004984:	854a                	mv	a0,s2
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	b84080e7          	jalr	-1148(ra) # 8000450a <readi>
    8000498e:	47c1                	li	a5,16
    80004990:	06f51163          	bne	a0,a5,800049f2 <dirlink+0xa2>
    if(de.inum == 0)
    80004994:	fc045783          	lhu	a5,-64(s0)
    80004998:	c791                	beqz	a5,800049a4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000499a:	24c1                	addiw	s1,s1,16
    8000499c:	04c92783          	lw	a5,76(s2)
    800049a0:	fcf4ede3          	bltu	s1,a5,8000497a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800049a4:	4639                	li	a2,14
    800049a6:	85d2                	mv	a1,s4
    800049a8:	fc240513          	addi	a0,s0,-62
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	432080e7          	jalr	1074(ra) # 80000dde <strncpy>
  de.inum = inum;
    800049b4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049b8:	4741                	li	a4,16
    800049ba:	86a6                	mv	a3,s1
    800049bc:	fc040613          	addi	a2,s0,-64
    800049c0:	4581                	li	a1,0
    800049c2:	854a                	mv	a0,s2
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	c3e080e7          	jalr	-962(ra) # 80004602 <writei>
    800049cc:	1541                	addi	a0,a0,-16
    800049ce:	00a03533          	snez	a0,a0
    800049d2:	40a00533          	neg	a0,a0
}
    800049d6:	70e2                	ld	ra,56(sp)
    800049d8:	7442                	ld	s0,48(sp)
    800049da:	74a2                	ld	s1,40(sp)
    800049dc:	7902                	ld	s2,32(sp)
    800049de:	69e2                	ld	s3,24(sp)
    800049e0:	6a42                	ld	s4,16(sp)
    800049e2:	6121                	addi	sp,sp,64
    800049e4:	8082                	ret
    iput(ip);
    800049e6:	00000097          	auipc	ra,0x0
    800049ea:	a2a080e7          	jalr	-1494(ra) # 80004410 <iput>
    return -1;
    800049ee:	557d                	li	a0,-1
    800049f0:	b7dd                	j	800049d6 <dirlink+0x86>
      panic("dirlink read");
    800049f2:	00004517          	auipc	a0,0x4
    800049f6:	cc650513          	addi	a0,a0,-826 # 800086b8 <syscalls+0x1f0>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	b46080e7          	jalr	-1210(ra) # 80000540 <panic>

0000000080004a02 <namei>:

struct inode*
namei(char *path)
{
    80004a02:	1101                	addi	sp,sp,-32
    80004a04:	ec06                	sd	ra,24(sp)
    80004a06:	e822                	sd	s0,16(sp)
    80004a08:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a0a:	fe040613          	addi	a2,s0,-32
    80004a0e:	4581                	li	a1,0
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	dda080e7          	jalr	-550(ra) # 800047ea <namex>
}
    80004a18:	60e2                	ld	ra,24(sp)
    80004a1a:	6442                	ld	s0,16(sp)
    80004a1c:	6105                	addi	sp,sp,32
    80004a1e:	8082                	ret

0000000080004a20 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a20:	1141                	addi	sp,sp,-16
    80004a22:	e406                	sd	ra,8(sp)
    80004a24:	e022                	sd	s0,0(sp)
    80004a26:	0800                	addi	s0,sp,16
    80004a28:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004a2a:	4585                	li	a1,1
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	dbe080e7          	jalr	-578(ra) # 800047ea <namex>
}
    80004a34:	60a2                	ld	ra,8(sp)
    80004a36:	6402                	ld	s0,0(sp)
    80004a38:	0141                	addi	sp,sp,16
    80004a3a:	8082                	ret

0000000080004a3c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004a3c:	1101                	addi	sp,sp,-32
    80004a3e:	ec06                	sd	ra,24(sp)
    80004a40:	e822                	sd	s0,16(sp)
    80004a42:	e426                	sd	s1,8(sp)
    80004a44:	e04a                	sd	s2,0(sp)
    80004a46:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004a48:	0001e917          	auipc	s2,0x1e
    80004a4c:	b5890913          	addi	s2,s2,-1192 # 800225a0 <log>
    80004a50:	01892583          	lw	a1,24(s2)
    80004a54:	02892503          	lw	a0,40(s2)
    80004a58:	fffff097          	auipc	ra,0xfffff
    80004a5c:	fe6080e7          	jalr	-26(ra) # 80003a3e <bread>
    80004a60:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004a62:	02c92683          	lw	a3,44(s2)
    80004a66:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004a68:	02d05863          	blez	a3,80004a98 <write_head+0x5c>
    80004a6c:	0001e797          	auipc	a5,0x1e
    80004a70:	b6478793          	addi	a5,a5,-1180 # 800225d0 <log+0x30>
    80004a74:	05c50713          	addi	a4,a0,92
    80004a78:	36fd                	addiw	a3,a3,-1
    80004a7a:	02069613          	slli	a2,a3,0x20
    80004a7e:	01e65693          	srli	a3,a2,0x1e
    80004a82:	0001e617          	auipc	a2,0x1e
    80004a86:	b5260613          	addi	a2,a2,-1198 # 800225d4 <log+0x34>
    80004a8a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004a8c:	4390                	lw	a2,0(a5)
    80004a8e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a90:	0791                	addi	a5,a5,4
    80004a92:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004a94:	fed79ce3          	bne	a5,a3,80004a8c <write_head+0x50>
  }
  bwrite(buf);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	096080e7          	jalr	150(ra) # 80003b30 <bwrite>
  brelse(buf);
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	fffff097          	auipc	ra,0xfffff
    80004aa8:	0ca080e7          	jalr	202(ra) # 80003b6e <brelse>
}
    80004aac:	60e2                	ld	ra,24(sp)
    80004aae:	6442                	ld	s0,16(sp)
    80004ab0:	64a2                	ld	s1,8(sp)
    80004ab2:	6902                	ld	s2,0(sp)
    80004ab4:	6105                	addi	sp,sp,32
    80004ab6:	8082                	ret

0000000080004ab8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ab8:	0001e797          	auipc	a5,0x1e
    80004abc:	b147a783          	lw	a5,-1260(a5) # 800225cc <log+0x2c>
    80004ac0:	0af05d63          	blez	a5,80004b7a <install_trans+0xc2>
{
    80004ac4:	7139                	addi	sp,sp,-64
    80004ac6:	fc06                	sd	ra,56(sp)
    80004ac8:	f822                	sd	s0,48(sp)
    80004aca:	f426                	sd	s1,40(sp)
    80004acc:	f04a                	sd	s2,32(sp)
    80004ace:	ec4e                	sd	s3,24(sp)
    80004ad0:	e852                	sd	s4,16(sp)
    80004ad2:	e456                	sd	s5,8(sp)
    80004ad4:	e05a                	sd	s6,0(sp)
    80004ad6:	0080                	addi	s0,sp,64
    80004ad8:	8b2a                	mv	s6,a0
    80004ada:	0001ea97          	auipc	s5,0x1e
    80004ade:	af6a8a93          	addi	s5,s5,-1290 # 800225d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ae2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004ae4:	0001e997          	auipc	s3,0x1e
    80004ae8:	abc98993          	addi	s3,s3,-1348 # 800225a0 <log>
    80004aec:	a00d                	j	80004b0e <install_trans+0x56>
    brelse(lbuf);
    80004aee:	854a                	mv	a0,s2
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	07e080e7          	jalr	126(ra) # 80003b6e <brelse>
    brelse(dbuf);
    80004af8:	8526                	mv	a0,s1
    80004afa:	fffff097          	auipc	ra,0xfffff
    80004afe:	074080e7          	jalr	116(ra) # 80003b6e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b02:	2a05                	addiw	s4,s4,1
    80004b04:	0a91                	addi	s5,s5,4
    80004b06:	02c9a783          	lw	a5,44(s3)
    80004b0a:	04fa5e63          	bge	s4,a5,80004b66 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b0e:	0189a583          	lw	a1,24(s3)
    80004b12:	014585bb          	addw	a1,a1,s4
    80004b16:	2585                	addiw	a1,a1,1
    80004b18:	0289a503          	lw	a0,40(s3)
    80004b1c:	fffff097          	auipc	ra,0xfffff
    80004b20:	f22080e7          	jalr	-222(ra) # 80003a3e <bread>
    80004b24:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b26:	000aa583          	lw	a1,0(s5)
    80004b2a:	0289a503          	lw	a0,40(s3)
    80004b2e:	fffff097          	auipc	ra,0xfffff
    80004b32:	f10080e7          	jalr	-240(ra) # 80003a3e <bread>
    80004b36:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004b38:	40000613          	li	a2,1024
    80004b3c:	05890593          	addi	a1,s2,88
    80004b40:	05850513          	addi	a0,a0,88
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	1ea080e7          	jalr	490(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	fe2080e7          	jalr	-30(ra) # 80003b30 <bwrite>
    if(recovering == 0)
    80004b56:	f80b1ce3          	bnez	s6,80004aee <install_trans+0x36>
      bunpin(dbuf);
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	fffff097          	auipc	ra,0xfffff
    80004b60:	0ec080e7          	jalr	236(ra) # 80003c48 <bunpin>
    80004b64:	b769                	j	80004aee <install_trans+0x36>
}
    80004b66:	70e2                	ld	ra,56(sp)
    80004b68:	7442                	ld	s0,48(sp)
    80004b6a:	74a2                	ld	s1,40(sp)
    80004b6c:	7902                	ld	s2,32(sp)
    80004b6e:	69e2                	ld	s3,24(sp)
    80004b70:	6a42                	ld	s4,16(sp)
    80004b72:	6aa2                	ld	s5,8(sp)
    80004b74:	6b02                	ld	s6,0(sp)
    80004b76:	6121                	addi	sp,sp,64
    80004b78:	8082                	ret
    80004b7a:	8082                	ret

0000000080004b7c <initlog>:
{
    80004b7c:	7179                	addi	sp,sp,-48
    80004b7e:	f406                	sd	ra,40(sp)
    80004b80:	f022                	sd	s0,32(sp)
    80004b82:	ec26                	sd	s1,24(sp)
    80004b84:	e84a                	sd	s2,16(sp)
    80004b86:	e44e                	sd	s3,8(sp)
    80004b88:	1800                	addi	s0,sp,48
    80004b8a:	892a                	mv	s2,a0
    80004b8c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004b8e:	0001e497          	auipc	s1,0x1e
    80004b92:	a1248493          	addi	s1,s1,-1518 # 800225a0 <log>
    80004b96:	00004597          	auipc	a1,0x4
    80004b9a:	b3258593          	addi	a1,a1,-1230 # 800086c8 <syscalls+0x200>
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	fa6080e7          	jalr	-90(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004ba8:	0149a583          	lw	a1,20(s3)
    80004bac:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004bae:	0109a783          	lw	a5,16(s3)
    80004bb2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004bb4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004bb8:	854a                	mv	a0,s2
    80004bba:	fffff097          	auipc	ra,0xfffff
    80004bbe:	e84080e7          	jalr	-380(ra) # 80003a3e <bread>
  log.lh.n = lh->n;
    80004bc2:	4d34                	lw	a3,88(a0)
    80004bc4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004bc6:	02d05663          	blez	a3,80004bf2 <initlog+0x76>
    80004bca:	05c50793          	addi	a5,a0,92
    80004bce:	0001e717          	auipc	a4,0x1e
    80004bd2:	a0270713          	addi	a4,a4,-1534 # 800225d0 <log+0x30>
    80004bd6:	36fd                	addiw	a3,a3,-1
    80004bd8:	02069613          	slli	a2,a3,0x20
    80004bdc:	01e65693          	srli	a3,a2,0x1e
    80004be0:	06050613          	addi	a2,a0,96
    80004be4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004be6:	4390                	lw	a2,0(a5)
    80004be8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004bea:	0791                	addi	a5,a5,4
    80004bec:	0711                	addi	a4,a4,4
    80004bee:	fed79ce3          	bne	a5,a3,80004be6 <initlog+0x6a>
  brelse(buf);
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	f7c080e7          	jalr	-132(ra) # 80003b6e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004bfa:	4505                	li	a0,1
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	ebc080e7          	jalr	-324(ra) # 80004ab8 <install_trans>
  log.lh.n = 0;
    80004c04:	0001e797          	auipc	a5,0x1e
    80004c08:	9c07a423          	sw	zero,-1592(a5) # 800225cc <log+0x2c>
  write_head(); // clear the log
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	e30080e7          	jalr	-464(ra) # 80004a3c <write_head>
}
    80004c14:	70a2                	ld	ra,40(sp)
    80004c16:	7402                	ld	s0,32(sp)
    80004c18:	64e2                	ld	s1,24(sp)
    80004c1a:	6942                	ld	s2,16(sp)
    80004c1c:	69a2                	ld	s3,8(sp)
    80004c1e:	6145                	addi	sp,sp,48
    80004c20:	8082                	ret

0000000080004c22 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c22:	1101                	addi	sp,sp,-32
    80004c24:	ec06                	sd	ra,24(sp)
    80004c26:	e822                	sd	s0,16(sp)
    80004c28:	e426                	sd	s1,8(sp)
    80004c2a:	e04a                	sd	s2,0(sp)
    80004c2c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c2e:	0001e517          	auipc	a0,0x1e
    80004c32:	97250513          	addi	a0,a0,-1678 # 800225a0 <log>
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	fa0080e7          	jalr	-96(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004c3e:	0001e497          	auipc	s1,0x1e
    80004c42:	96248493          	addi	s1,s1,-1694 # 800225a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c46:	4979                	li	s2,30
    80004c48:	a039                	j	80004c56 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004c4a:	85a6                	mv	a1,s1
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	ffffe097          	auipc	ra,0xffffe
    80004c52:	be4080e7          	jalr	-1052(ra) # 80002832 <sleep>
    if(log.committing){
    80004c56:	50dc                	lw	a5,36(s1)
    80004c58:	fbed                	bnez	a5,80004c4a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c5a:	5098                	lw	a4,32(s1)
    80004c5c:	2705                	addiw	a4,a4,1
    80004c5e:	0007069b          	sext.w	a3,a4
    80004c62:	0027179b          	slliw	a5,a4,0x2
    80004c66:	9fb9                	addw	a5,a5,a4
    80004c68:	0017979b          	slliw	a5,a5,0x1
    80004c6c:	54d8                	lw	a4,44(s1)
    80004c6e:	9fb9                	addw	a5,a5,a4
    80004c70:	00f95963          	bge	s2,a5,80004c82 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004c74:	85a6                	mv	a1,s1
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffe097          	auipc	ra,0xffffe
    80004c7c:	bba080e7          	jalr	-1094(ra) # 80002832 <sleep>
    80004c80:	bfd9                	j	80004c56 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004c82:	0001e517          	auipc	a0,0x1e
    80004c86:	91e50513          	addi	a0,a0,-1762 # 800225a0 <log>
    80004c8a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004c94:	60e2                	ld	ra,24(sp)
    80004c96:	6442                	ld	s0,16(sp)
    80004c98:	64a2                	ld	s1,8(sp)
    80004c9a:	6902                	ld	s2,0(sp)
    80004c9c:	6105                	addi	sp,sp,32
    80004c9e:	8082                	ret

0000000080004ca0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004ca0:	7139                	addi	sp,sp,-64
    80004ca2:	fc06                	sd	ra,56(sp)
    80004ca4:	f822                	sd	s0,48(sp)
    80004ca6:	f426                	sd	s1,40(sp)
    80004ca8:	f04a                	sd	s2,32(sp)
    80004caa:	ec4e                	sd	s3,24(sp)
    80004cac:	e852                	sd	s4,16(sp)
    80004cae:	e456                	sd	s5,8(sp)
    80004cb0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004cb2:	0001e497          	auipc	s1,0x1e
    80004cb6:	8ee48493          	addi	s1,s1,-1810 # 800225a0 <log>
    80004cba:	8526                	mv	a0,s1
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	f1a080e7          	jalr	-230(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004cc4:	509c                	lw	a5,32(s1)
    80004cc6:	37fd                	addiw	a5,a5,-1
    80004cc8:	0007891b          	sext.w	s2,a5
    80004ccc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004cce:	50dc                	lw	a5,36(s1)
    80004cd0:	e7b9                	bnez	a5,80004d1e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004cd2:	04091e63          	bnez	s2,80004d2e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004cd6:	0001e497          	auipc	s1,0x1e
    80004cda:	8ca48493          	addi	s1,s1,-1846 # 800225a0 <log>
    80004cde:	4785                	li	a5,1
    80004ce0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	fa6080e7          	jalr	-90(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004cec:	54dc                	lw	a5,44(s1)
    80004cee:	06f04763          	bgtz	a5,80004d5c <end_op+0xbc>
    acquire(&log.lock);
    80004cf2:	0001e497          	auipc	s1,0x1e
    80004cf6:	8ae48493          	addi	s1,s1,-1874 # 800225a0 <log>
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	eda080e7          	jalr	-294(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004d04:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d08:	8526                	mv	a0,s1
    80004d0a:	ffffe097          	auipc	ra,0xffffe
    80004d0e:	b8c080e7          	jalr	-1140(ra) # 80002896 <wakeup>
    release(&log.lock);
    80004d12:	8526                	mv	a0,s1
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	f76080e7          	jalr	-138(ra) # 80000c8a <release>
}
    80004d1c:	a03d                	j	80004d4a <end_op+0xaa>
    panic("log.committing");
    80004d1e:	00004517          	auipc	a0,0x4
    80004d22:	9b250513          	addi	a0,a0,-1614 # 800086d0 <syscalls+0x208>
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	81a080e7          	jalr	-2022(ra) # 80000540 <panic>
    wakeup(&log);
    80004d2e:	0001e497          	auipc	s1,0x1e
    80004d32:	87248493          	addi	s1,s1,-1934 # 800225a0 <log>
    80004d36:	8526                	mv	a0,s1
    80004d38:	ffffe097          	auipc	ra,0xffffe
    80004d3c:	b5e080e7          	jalr	-1186(ra) # 80002896 <wakeup>
  release(&log.lock);
    80004d40:	8526                	mv	a0,s1
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	f48080e7          	jalr	-184(ra) # 80000c8a <release>
}
    80004d4a:	70e2                	ld	ra,56(sp)
    80004d4c:	7442                	ld	s0,48(sp)
    80004d4e:	74a2                	ld	s1,40(sp)
    80004d50:	7902                	ld	s2,32(sp)
    80004d52:	69e2                	ld	s3,24(sp)
    80004d54:	6a42                	ld	s4,16(sp)
    80004d56:	6aa2                	ld	s5,8(sp)
    80004d58:	6121                	addi	sp,sp,64
    80004d5a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d5c:	0001ea97          	auipc	s5,0x1e
    80004d60:	874a8a93          	addi	s5,s5,-1932 # 800225d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004d64:	0001ea17          	auipc	s4,0x1e
    80004d68:	83ca0a13          	addi	s4,s4,-1988 # 800225a0 <log>
    80004d6c:	018a2583          	lw	a1,24(s4)
    80004d70:	012585bb          	addw	a1,a1,s2
    80004d74:	2585                	addiw	a1,a1,1
    80004d76:	028a2503          	lw	a0,40(s4)
    80004d7a:	fffff097          	auipc	ra,0xfffff
    80004d7e:	cc4080e7          	jalr	-828(ra) # 80003a3e <bread>
    80004d82:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004d84:	000aa583          	lw	a1,0(s5)
    80004d88:	028a2503          	lw	a0,40(s4)
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	cb2080e7          	jalr	-846(ra) # 80003a3e <bread>
    80004d94:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004d96:	40000613          	li	a2,1024
    80004d9a:	05850593          	addi	a1,a0,88
    80004d9e:	05848513          	addi	a0,s1,88
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	f8c080e7          	jalr	-116(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004daa:	8526                	mv	a0,s1
    80004dac:	fffff097          	auipc	ra,0xfffff
    80004db0:	d84080e7          	jalr	-636(ra) # 80003b30 <bwrite>
    brelse(from);
    80004db4:	854e                	mv	a0,s3
    80004db6:	fffff097          	auipc	ra,0xfffff
    80004dba:	db8080e7          	jalr	-584(ra) # 80003b6e <brelse>
    brelse(to);
    80004dbe:	8526                	mv	a0,s1
    80004dc0:	fffff097          	auipc	ra,0xfffff
    80004dc4:	dae080e7          	jalr	-594(ra) # 80003b6e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004dc8:	2905                	addiw	s2,s2,1
    80004dca:	0a91                	addi	s5,s5,4
    80004dcc:	02ca2783          	lw	a5,44(s4)
    80004dd0:	f8f94ee3          	blt	s2,a5,80004d6c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004dd4:	00000097          	auipc	ra,0x0
    80004dd8:	c68080e7          	jalr	-920(ra) # 80004a3c <write_head>
    install_trans(0); // Now install writes to home locations
    80004ddc:	4501                	li	a0,0
    80004dde:	00000097          	auipc	ra,0x0
    80004de2:	cda080e7          	jalr	-806(ra) # 80004ab8 <install_trans>
    log.lh.n = 0;
    80004de6:	0001d797          	auipc	a5,0x1d
    80004dea:	7e07a323          	sw	zero,2022(a5) # 800225cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004dee:	00000097          	auipc	ra,0x0
    80004df2:	c4e080e7          	jalr	-946(ra) # 80004a3c <write_head>
    80004df6:	bdf5                	j	80004cf2 <end_op+0x52>

0000000080004df8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004df8:	1101                	addi	sp,sp,-32
    80004dfa:	ec06                	sd	ra,24(sp)
    80004dfc:	e822                	sd	s0,16(sp)
    80004dfe:	e426                	sd	s1,8(sp)
    80004e00:	e04a                	sd	s2,0(sp)
    80004e02:	1000                	addi	s0,sp,32
    80004e04:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e06:	0001d917          	auipc	s2,0x1d
    80004e0a:	79a90913          	addi	s2,s2,1946 # 800225a0 <log>
    80004e0e:	854a                	mv	a0,s2
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	dc6080e7          	jalr	-570(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e18:	02c92603          	lw	a2,44(s2)
    80004e1c:	47f5                	li	a5,29
    80004e1e:	06c7c563          	blt	a5,a2,80004e88 <log_write+0x90>
    80004e22:	0001d797          	auipc	a5,0x1d
    80004e26:	79a7a783          	lw	a5,1946(a5) # 800225bc <log+0x1c>
    80004e2a:	37fd                	addiw	a5,a5,-1
    80004e2c:	04f65e63          	bge	a2,a5,80004e88 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e30:	0001d797          	auipc	a5,0x1d
    80004e34:	7907a783          	lw	a5,1936(a5) # 800225c0 <log+0x20>
    80004e38:	06f05063          	blez	a5,80004e98 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e3c:	4781                	li	a5,0
    80004e3e:	06c05563          	blez	a2,80004ea8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004e42:	44cc                	lw	a1,12(s1)
    80004e44:	0001d717          	auipc	a4,0x1d
    80004e48:	78c70713          	addi	a4,a4,1932 # 800225d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004e4c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004e4e:	4314                	lw	a3,0(a4)
    80004e50:	04b68c63          	beq	a3,a1,80004ea8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004e54:	2785                	addiw	a5,a5,1
    80004e56:	0711                	addi	a4,a4,4
    80004e58:	fef61be3          	bne	a2,a5,80004e4e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004e5c:	0621                	addi	a2,a2,8
    80004e5e:	060a                	slli	a2,a2,0x2
    80004e60:	0001d797          	auipc	a5,0x1d
    80004e64:	74078793          	addi	a5,a5,1856 # 800225a0 <log>
    80004e68:	97b2                	add	a5,a5,a2
    80004e6a:	44d8                	lw	a4,12(s1)
    80004e6c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004e6e:	8526                	mv	a0,s1
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	d9c080e7          	jalr	-612(ra) # 80003c0c <bpin>
    log.lh.n++;
    80004e78:	0001d717          	auipc	a4,0x1d
    80004e7c:	72870713          	addi	a4,a4,1832 # 800225a0 <log>
    80004e80:	575c                	lw	a5,44(a4)
    80004e82:	2785                	addiw	a5,a5,1
    80004e84:	d75c                	sw	a5,44(a4)
    80004e86:	a82d                	j	80004ec0 <log_write+0xc8>
    panic("too big a transaction");
    80004e88:	00004517          	auipc	a0,0x4
    80004e8c:	85850513          	addi	a0,a0,-1960 # 800086e0 <syscalls+0x218>
    80004e90:	ffffb097          	auipc	ra,0xffffb
    80004e94:	6b0080e7          	jalr	1712(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004e98:	00004517          	auipc	a0,0x4
    80004e9c:	86050513          	addi	a0,a0,-1952 # 800086f8 <syscalls+0x230>
    80004ea0:	ffffb097          	auipc	ra,0xffffb
    80004ea4:	6a0080e7          	jalr	1696(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004ea8:	00878693          	addi	a3,a5,8
    80004eac:	068a                	slli	a3,a3,0x2
    80004eae:	0001d717          	auipc	a4,0x1d
    80004eb2:	6f270713          	addi	a4,a4,1778 # 800225a0 <log>
    80004eb6:	9736                	add	a4,a4,a3
    80004eb8:	44d4                	lw	a3,12(s1)
    80004eba:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004ebc:	faf609e3          	beq	a2,a5,80004e6e <log_write+0x76>
  }
  release(&log.lock);
    80004ec0:	0001d517          	auipc	a0,0x1d
    80004ec4:	6e050513          	addi	a0,a0,1760 # 800225a0 <log>
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	dc2080e7          	jalr	-574(ra) # 80000c8a <release>
}
    80004ed0:	60e2                	ld	ra,24(sp)
    80004ed2:	6442                	ld	s0,16(sp)
    80004ed4:	64a2                	ld	s1,8(sp)
    80004ed6:	6902                	ld	s2,0(sp)
    80004ed8:	6105                	addi	sp,sp,32
    80004eda:	8082                	ret

0000000080004edc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004edc:	1101                	addi	sp,sp,-32
    80004ede:	ec06                	sd	ra,24(sp)
    80004ee0:	e822                	sd	s0,16(sp)
    80004ee2:	e426                	sd	s1,8(sp)
    80004ee4:	e04a                	sd	s2,0(sp)
    80004ee6:	1000                	addi	s0,sp,32
    80004ee8:	84aa                	mv	s1,a0
    80004eea:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004eec:	00004597          	auipc	a1,0x4
    80004ef0:	82c58593          	addi	a1,a1,-2004 # 80008718 <syscalls+0x250>
    80004ef4:	0521                	addi	a0,a0,8
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	c50080e7          	jalr	-944(ra) # 80000b46 <initlock>
  lk->name = name;
    80004efe:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f02:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f06:	0204a423          	sw	zero,40(s1)
}
    80004f0a:	60e2                	ld	ra,24(sp)
    80004f0c:	6442                	ld	s0,16(sp)
    80004f0e:	64a2                	ld	s1,8(sp)
    80004f10:	6902                	ld	s2,0(sp)
    80004f12:	6105                	addi	sp,sp,32
    80004f14:	8082                	ret

0000000080004f16 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f16:	1101                	addi	sp,sp,-32
    80004f18:	ec06                	sd	ra,24(sp)
    80004f1a:	e822                	sd	s0,16(sp)
    80004f1c:	e426                	sd	s1,8(sp)
    80004f1e:	e04a                	sd	s2,0(sp)
    80004f20:	1000                	addi	s0,sp,32
    80004f22:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f24:	00850913          	addi	s2,a0,8
    80004f28:	854a                	mv	a0,s2
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	cac080e7          	jalr	-852(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004f32:	409c                	lw	a5,0(s1)
    80004f34:	cb89                	beqz	a5,80004f46 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f36:	85ca                	mv	a1,s2
    80004f38:	8526                	mv	a0,s1
    80004f3a:	ffffe097          	auipc	ra,0xffffe
    80004f3e:	8f8080e7          	jalr	-1800(ra) # 80002832 <sleep>
  while (lk->locked) {
    80004f42:	409c                	lw	a5,0(s1)
    80004f44:	fbed                	bnez	a5,80004f36 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004f46:	4785                	li	a5,1
    80004f48:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004f4a:	ffffd097          	auipc	ra,0xffffd
    80004f4e:	c86080e7          	jalr	-890(ra) # 80001bd0 <myproc>
    80004f52:	591c                	lw	a5,48(a0)
    80004f54:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004f56:	854a                	mv	a0,s2
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	d32080e7          	jalr	-718(ra) # 80000c8a <release>
}
    80004f60:	60e2                	ld	ra,24(sp)
    80004f62:	6442                	ld	s0,16(sp)
    80004f64:	64a2                	ld	s1,8(sp)
    80004f66:	6902                	ld	s2,0(sp)
    80004f68:	6105                	addi	sp,sp,32
    80004f6a:	8082                	ret

0000000080004f6c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004f6c:	1101                	addi	sp,sp,-32
    80004f6e:	ec06                	sd	ra,24(sp)
    80004f70:	e822                	sd	s0,16(sp)
    80004f72:	e426                	sd	s1,8(sp)
    80004f74:	e04a                	sd	s2,0(sp)
    80004f76:	1000                	addi	s0,sp,32
    80004f78:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f7a:	00850913          	addi	s2,a0,8
    80004f7e:	854a                	mv	a0,s2
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	c56080e7          	jalr	-938(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004f88:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f8c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004f90:	8526                	mv	a0,s1
    80004f92:	ffffe097          	auipc	ra,0xffffe
    80004f96:	904080e7          	jalr	-1788(ra) # 80002896 <wakeup>
  release(&lk->lk);
    80004f9a:	854a                	mv	a0,s2
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	cee080e7          	jalr	-786(ra) # 80000c8a <release>
}
    80004fa4:	60e2                	ld	ra,24(sp)
    80004fa6:	6442                	ld	s0,16(sp)
    80004fa8:	64a2                	ld	s1,8(sp)
    80004faa:	6902                	ld	s2,0(sp)
    80004fac:	6105                	addi	sp,sp,32
    80004fae:	8082                	ret

0000000080004fb0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004fb0:	7179                	addi	sp,sp,-48
    80004fb2:	f406                	sd	ra,40(sp)
    80004fb4:	f022                	sd	s0,32(sp)
    80004fb6:	ec26                	sd	s1,24(sp)
    80004fb8:	e84a                	sd	s2,16(sp)
    80004fba:	e44e                	sd	s3,8(sp)
    80004fbc:	1800                	addi	s0,sp,48
    80004fbe:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004fc0:	00850913          	addi	s2,a0,8
    80004fc4:	854a                	mv	a0,s2
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	c10080e7          	jalr	-1008(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004fce:	409c                	lw	a5,0(s1)
    80004fd0:	ef99                	bnez	a5,80004fee <holdingsleep+0x3e>
    80004fd2:	4481                	li	s1,0
  release(&lk->lk);
    80004fd4:	854a                	mv	a0,s2
    80004fd6:	ffffc097          	auipc	ra,0xffffc
    80004fda:	cb4080e7          	jalr	-844(ra) # 80000c8a <release>
  return r;
}
    80004fde:	8526                	mv	a0,s1
    80004fe0:	70a2                	ld	ra,40(sp)
    80004fe2:	7402                	ld	s0,32(sp)
    80004fe4:	64e2                	ld	s1,24(sp)
    80004fe6:	6942                	ld	s2,16(sp)
    80004fe8:	69a2                	ld	s3,8(sp)
    80004fea:	6145                	addi	sp,sp,48
    80004fec:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004fee:	0284a983          	lw	s3,40(s1)
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	bde080e7          	jalr	-1058(ra) # 80001bd0 <myproc>
    80004ffa:	5904                	lw	s1,48(a0)
    80004ffc:	413484b3          	sub	s1,s1,s3
    80005000:	0014b493          	seqz	s1,s1
    80005004:	bfc1                	j	80004fd4 <holdingsleep+0x24>

0000000080005006 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005006:	1141                	addi	sp,sp,-16
    80005008:	e406                	sd	ra,8(sp)
    8000500a:	e022                	sd	s0,0(sp)
    8000500c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000500e:	00003597          	auipc	a1,0x3
    80005012:	71a58593          	addi	a1,a1,1818 # 80008728 <syscalls+0x260>
    80005016:	0001d517          	auipc	a0,0x1d
    8000501a:	6d250513          	addi	a0,a0,1746 # 800226e8 <ftable>
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	b28080e7          	jalr	-1240(ra) # 80000b46 <initlock>
}
    80005026:	60a2                	ld	ra,8(sp)
    80005028:	6402                	ld	s0,0(sp)
    8000502a:	0141                	addi	sp,sp,16
    8000502c:	8082                	ret

000000008000502e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000502e:	1101                	addi	sp,sp,-32
    80005030:	ec06                	sd	ra,24(sp)
    80005032:	e822                	sd	s0,16(sp)
    80005034:	e426                	sd	s1,8(sp)
    80005036:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005038:	0001d517          	auipc	a0,0x1d
    8000503c:	6b050513          	addi	a0,a0,1712 # 800226e8 <ftable>
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	b96080e7          	jalr	-1130(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005048:	0001d497          	auipc	s1,0x1d
    8000504c:	6b848493          	addi	s1,s1,1720 # 80022700 <ftable+0x18>
    80005050:	0001e717          	auipc	a4,0x1e
    80005054:	65070713          	addi	a4,a4,1616 # 800236a0 <disk>
    if(f->ref == 0){
    80005058:	40dc                	lw	a5,4(s1)
    8000505a:	cf99                	beqz	a5,80005078 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000505c:	02848493          	addi	s1,s1,40
    80005060:	fee49ce3          	bne	s1,a4,80005058 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005064:	0001d517          	auipc	a0,0x1d
    80005068:	68450513          	addi	a0,a0,1668 # 800226e8 <ftable>
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	c1e080e7          	jalr	-994(ra) # 80000c8a <release>
  return 0;
    80005074:	4481                	li	s1,0
    80005076:	a819                	j	8000508c <filealloc+0x5e>
      f->ref = 1;
    80005078:	4785                	li	a5,1
    8000507a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000507c:	0001d517          	auipc	a0,0x1d
    80005080:	66c50513          	addi	a0,a0,1644 # 800226e8 <ftable>
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	c06080e7          	jalr	-1018(ra) # 80000c8a <release>
}
    8000508c:	8526                	mv	a0,s1
    8000508e:	60e2                	ld	ra,24(sp)
    80005090:	6442                	ld	s0,16(sp)
    80005092:	64a2                	ld	s1,8(sp)
    80005094:	6105                	addi	sp,sp,32
    80005096:	8082                	ret

0000000080005098 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005098:	1101                	addi	sp,sp,-32
    8000509a:	ec06                	sd	ra,24(sp)
    8000509c:	e822                	sd	s0,16(sp)
    8000509e:	e426                	sd	s1,8(sp)
    800050a0:	1000                	addi	s0,sp,32
    800050a2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800050a4:	0001d517          	auipc	a0,0x1d
    800050a8:	64450513          	addi	a0,a0,1604 # 800226e8 <ftable>
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	b2a080e7          	jalr	-1238(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800050b4:	40dc                	lw	a5,4(s1)
    800050b6:	02f05263          	blez	a5,800050da <filedup+0x42>
    panic("filedup");
  f->ref++;
    800050ba:	2785                	addiw	a5,a5,1
    800050bc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800050be:	0001d517          	auipc	a0,0x1d
    800050c2:	62a50513          	addi	a0,a0,1578 # 800226e8 <ftable>
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	bc4080e7          	jalr	-1084(ra) # 80000c8a <release>
  return f;
}
    800050ce:	8526                	mv	a0,s1
    800050d0:	60e2                	ld	ra,24(sp)
    800050d2:	6442                	ld	s0,16(sp)
    800050d4:	64a2                	ld	s1,8(sp)
    800050d6:	6105                	addi	sp,sp,32
    800050d8:	8082                	ret
    panic("filedup");
    800050da:	00003517          	auipc	a0,0x3
    800050de:	65650513          	addi	a0,a0,1622 # 80008730 <syscalls+0x268>
    800050e2:	ffffb097          	auipc	ra,0xffffb
    800050e6:	45e080e7          	jalr	1118(ra) # 80000540 <panic>

00000000800050ea <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800050ea:	7139                	addi	sp,sp,-64
    800050ec:	fc06                	sd	ra,56(sp)
    800050ee:	f822                	sd	s0,48(sp)
    800050f0:	f426                	sd	s1,40(sp)
    800050f2:	f04a                	sd	s2,32(sp)
    800050f4:	ec4e                	sd	s3,24(sp)
    800050f6:	e852                	sd	s4,16(sp)
    800050f8:	e456                	sd	s5,8(sp)
    800050fa:	0080                	addi	s0,sp,64
    800050fc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800050fe:	0001d517          	auipc	a0,0x1d
    80005102:	5ea50513          	addi	a0,a0,1514 # 800226e8 <ftable>
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	ad0080e7          	jalr	-1328(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000510e:	40dc                	lw	a5,4(s1)
    80005110:	06f05163          	blez	a5,80005172 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005114:	37fd                	addiw	a5,a5,-1
    80005116:	0007871b          	sext.w	a4,a5
    8000511a:	c0dc                	sw	a5,4(s1)
    8000511c:	06e04363          	bgtz	a4,80005182 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005120:	0004a903          	lw	s2,0(s1)
    80005124:	0094ca83          	lbu	s5,9(s1)
    80005128:	0104ba03          	ld	s4,16(s1)
    8000512c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005130:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005134:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005138:	0001d517          	auipc	a0,0x1d
    8000513c:	5b050513          	addi	a0,a0,1456 # 800226e8 <ftable>
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	b4a080e7          	jalr	-1206(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80005148:	4785                	li	a5,1
    8000514a:	04f90d63          	beq	s2,a5,800051a4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000514e:	3979                	addiw	s2,s2,-2
    80005150:	4785                	li	a5,1
    80005152:	0527e063          	bltu	a5,s2,80005192 <fileclose+0xa8>
    begin_op();
    80005156:	00000097          	auipc	ra,0x0
    8000515a:	acc080e7          	jalr	-1332(ra) # 80004c22 <begin_op>
    iput(ff.ip);
    8000515e:	854e                	mv	a0,s3
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	2b0080e7          	jalr	688(ra) # 80004410 <iput>
    end_op();
    80005168:	00000097          	auipc	ra,0x0
    8000516c:	b38080e7          	jalr	-1224(ra) # 80004ca0 <end_op>
    80005170:	a00d                	j	80005192 <fileclose+0xa8>
    panic("fileclose");
    80005172:	00003517          	auipc	a0,0x3
    80005176:	5c650513          	addi	a0,a0,1478 # 80008738 <syscalls+0x270>
    8000517a:	ffffb097          	auipc	ra,0xffffb
    8000517e:	3c6080e7          	jalr	966(ra) # 80000540 <panic>
    release(&ftable.lock);
    80005182:	0001d517          	auipc	a0,0x1d
    80005186:	56650513          	addi	a0,a0,1382 # 800226e8 <ftable>
    8000518a:	ffffc097          	auipc	ra,0xffffc
    8000518e:	b00080e7          	jalr	-1280(ra) # 80000c8a <release>
  }
}
    80005192:	70e2                	ld	ra,56(sp)
    80005194:	7442                	ld	s0,48(sp)
    80005196:	74a2                	ld	s1,40(sp)
    80005198:	7902                	ld	s2,32(sp)
    8000519a:	69e2                	ld	s3,24(sp)
    8000519c:	6a42                	ld	s4,16(sp)
    8000519e:	6aa2                	ld	s5,8(sp)
    800051a0:	6121                	addi	sp,sp,64
    800051a2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800051a4:	85d6                	mv	a1,s5
    800051a6:	8552                	mv	a0,s4
    800051a8:	00000097          	auipc	ra,0x0
    800051ac:	34c080e7          	jalr	844(ra) # 800054f4 <pipeclose>
    800051b0:	b7cd                	j	80005192 <fileclose+0xa8>

00000000800051b2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800051b2:	715d                	addi	sp,sp,-80
    800051b4:	e486                	sd	ra,72(sp)
    800051b6:	e0a2                	sd	s0,64(sp)
    800051b8:	fc26                	sd	s1,56(sp)
    800051ba:	f84a                	sd	s2,48(sp)
    800051bc:	f44e                	sd	s3,40(sp)
    800051be:	0880                	addi	s0,sp,80
    800051c0:	84aa                	mv	s1,a0
    800051c2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800051c4:	ffffd097          	auipc	ra,0xffffd
    800051c8:	a0c080e7          	jalr	-1524(ra) # 80001bd0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800051cc:	409c                	lw	a5,0(s1)
    800051ce:	37f9                	addiw	a5,a5,-2
    800051d0:	4705                	li	a4,1
    800051d2:	04f76763          	bltu	a4,a5,80005220 <filestat+0x6e>
    800051d6:	892a                	mv	s2,a0
    ilock(f->ip);
    800051d8:	6c88                	ld	a0,24(s1)
    800051da:	fffff097          	auipc	ra,0xfffff
    800051de:	07c080e7          	jalr	124(ra) # 80004256 <ilock>
    stati(f->ip, &st);
    800051e2:	fb840593          	addi	a1,s0,-72
    800051e6:	6c88                	ld	a0,24(s1)
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	2f8080e7          	jalr	760(ra) # 800044e0 <stati>
    iunlock(f->ip);
    800051f0:	6c88                	ld	a0,24(s1)
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	126080e7          	jalr	294(ra) # 80004318 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800051fa:	46e1                	li	a3,24
    800051fc:	fb840613          	addi	a2,s0,-72
    80005200:	85ce                	mv	a1,s3
    80005202:	05093503          	ld	a0,80(s2)
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	466080e7          	jalr	1126(ra) # 8000166c <copyout>
    8000520e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005212:	60a6                	ld	ra,72(sp)
    80005214:	6406                	ld	s0,64(sp)
    80005216:	74e2                	ld	s1,56(sp)
    80005218:	7942                	ld	s2,48(sp)
    8000521a:	79a2                	ld	s3,40(sp)
    8000521c:	6161                	addi	sp,sp,80
    8000521e:	8082                	ret
  return -1;
    80005220:	557d                	li	a0,-1
    80005222:	bfc5                	j	80005212 <filestat+0x60>

0000000080005224 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005224:	7179                	addi	sp,sp,-48
    80005226:	f406                	sd	ra,40(sp)
    80005228:	f022                	sd	s0,32(sp)
    8000522a:	ec26                	sd	s1,24(sp)
    8000522c:	e84a                	sd	s2,16(sp)
    8000522e:	e44e                	sd	s3,8(sp)
    80005230:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005232:	00854783          	lbu	a5,8(a0)
    80005236:	c3d5                	beqz	a5,800052da <fileread+0xb6>
    80005238:	84aa                	mv	s1,a0
    8000523a:	89ae                	mv	s3,a1
    8000523c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000523e:	411c                	lw	a5,0(a0)
    80005240:	4705                	li	a4,1
    80005242:	04e78963          	beq	a5,a4,80005294 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005246:	470d                	li	a4,3
    80005248:	04e78d63          	beq	a5,a4,800052a2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000524c:	4709                	li	a4,2
    8000524e:	06e79e63          	bne	a5,a4,800052ca <fileread+0xa6>
    ilock(f->ip);
    80005252:	6d08                	ld	a0,24(a0)
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	002080e7          	jalr	2(ra) # 80004256 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000525c:	874a                	mv	a4,s2
    8000525e:	5094                	lw	a3,32(s1)
    80005260:	864e                	mv	a2,s3
    80005262:	4585                	li	a1,1
    80005264:	6c88                	ld	a0,24(s1)
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	2a4080e7          	jalr	676(ra) # 8000450a <readi>
    8000526e:	892a                	mv	s2,a0
    80005270:	00a05563          	blez	a0,8000527a <fileread+0x56>
      f->off += r;
    80005274:	509c                	lw	a5,32(s1)
    80005276:	9fa9                	addw	a5,a5,a0
    80005278:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000527a:	6c88                	ld	a0,24(s1)
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	09c080e7          	jalr	156(ra) # 80004318 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005284:	854a                	mv	a0,s2
    80005286:	70a2                	ld	ra,40(sp)
    80005288:	7402                	ld	s0,32(sp)
    8000528a:	64e2                	ld	s1,24(sp)
    8000528c:	6942                	ld	s2,16(sp)
    8000528e:	69a2                	ld	s3,8(sp)
    80005290:	6145                	addi	sp,sp,48
    80005292:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005294:	6908                	ld	a0,16(a0)
    80005296:	00000097          	auipc	ra,0x0
    8000529a:	3c6080e7          	jalr	966(ra) # 8000565c <piperead>
    8000529e:	892a                	mv	s2,a0
    800052a0:	b7d5                	j	80005284 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800052a2:	02451783          	lh	a5,36(a0)
    800052a6:	03079693          	slli	a3,a5,0x30
    800052aa:	92c1                	srli	a3,a3,0x30
    800052ac:	4725                	li	a4,9
    800052ae:	02d76863          	bltu	a4,a3,800052de <fileread+0xba>
    800052b2:	0792                	slli	a5,a5,0x4
    800052b4:	0001d717          	auipc	a4,0x1d
    800052b8:	39470713          	addi	a4,a4,916 # 80022648 <devsw>
    800052bc:	97ba                	add	a5,a5,a4
    800052be:	639c                	ld	a5,0(a5)
    800052c0:	c38d                	beqz	a5,800052e2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800052c2:	4505                	li	a0,1
    800052c4:	9782                	jalr	a5
    800052c6:	892a                	mv	s2,a0
    800052c8:	bf75                	j	80005284 <fileread+0x60>
    panic("fileread");
    800052ca:	00003517          	auipc	a0,0x3
    800052ce:	47e50513          	addi	a0,a0,1150 # 80008748 <syscalls+0x280>
    800052d2:	ffffb097          	auipc	ra,0xffffb
    800052d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
    return -1;
    800052da:	597d                	li	s2,-1
    800052dc:	b765                	j	80005284 <fileread+0x60>
      return -1;
    800052de:	597d                	li	s2,-1
    800052e0:	b755                	j	80005284 <fileread+0x60>
    800052e2:	597d                	li	s2,-1
    800052e4:	b745                	j	80005284 <fileread+0x60>

00000000800052e6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800052e6:	715d                	addi	sp,sp,-80
    800052e8:	e486                	sd	ra,72(sp)
    800052ea:	e0a2                	sd	s0,64(sp)
    800052ec:	fc26                	sd	s1,56(sp)
    800052ee:	f84a                	sd	s2,48(sp)
    800052f0:	f44e                	sd	s3,40(sp)
    800052f2:	f052                	sd	s4,32(sp)
    800052f4:	ec56                	sd	s5,24(sp)
    800052f6:	e85a                	sd	s6,16(sp)
    800052f8:	e45e                	sd	s7,8(sp)
    800052fa:	e062                	sd	s8,0(sp)
    800052fc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800052fe:	00954783          	lbu	a5,9(a0)
    80005302:	10078663          	beqz	a5,8000540e <filewrite+0x128>
    80005306:	892a                	mv	s2,a0
    80005308:	8b2e                	mv	s6,a1
    8000530a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000530c:	411c                	lw	a5,0(a0)
    8000530e:	4705                	li	a4,1
    80005310:	02e78263          	beq	a5,a4,80005334 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005314:	470d                	li	a4,3
    80005316:	02e78663          	beq	a5,a4,80005342 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000531a:	4709                	li	a4,2
    8000531c:	0ee79163          	bne	a5,a4,800053fe <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005320:	0ac05d63          	blez	a2,800053da <filewrite+0xf4>
    int i = 0;
    80005324:	4981                	li	s3,0
    80005326:	6b85                	lui	s7,0x1
    80005328:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000532c:	6c05                	lui	s8,0x1
    8000532e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005332:	a861                	j	800053ca <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005334:	6908                	ld	a0,16(a0)
    80005336:	00000097          	auipc	ra,0x0
    8000533a:	22e080e7          	jalr	558(ra) # 80005564 <pipewrite>
    8000533e:	8a2a                	mv	s4,a0
    80005340:	a045                	j	800053e0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005342:	02451783          	lh	a5,36(a0)
    80005346:	03079693          	slli	a3,a5,0x30
    8000534a:	92c1                	srli	a3,a3,0x30
    8000534c:	4725                	li	a4,9
    8000534e:	0cd76263          	bltu	a4,a3,80005412 <filewrite+0x12c>
    80005352:	0792                	slli	a5,a5,0x4
    80005354:	0001d717          	auipc	a4,0x1d
    80005358:	2f470713          	addi	a4,a4,756 # 80022648 <devsw>
    8000535c:	97ba                	add	a5,a5,a4
    8000535e:	679c                	ld	a5,8(a5)
    80005360:	cbdd                	beqz	a5,80005416 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005362:	4505                	li	a0,1
    80005364:	9782                	jalr	a5
    80005366:	8a2a                	mv	s4,a0
    80005368:	a8a5                	j	800053e0 <filewrite+0xfa>
    8000536a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000536e:	00000097          	auipc	ra,0x0
    80005372:	8b4080e7          	jalr	-1868(ra) # 80004c22 <begin_op>
      ilock(f->ip);
    80005376:	01893503          	ld	a0,24(s2)
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	edc080e7          	jalr	-292(ra) # 80004256 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005382:	8756                	mv	a4,s5
    80005384:	02092683          	lw	a3,32(s2)
    80005388:	01698633          	add	a2,s3,s6
    8000538c:	4585                	li	a1,1
    8000538e:	01893503          	ld	a0,24(s2)
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	270080e7          	jalr	624(ra) # 80004602 <writei>
    8000539a:	84aa                	mv	s1,a0
    8000539c:	00a05763          	blez	a0,800053aa <filewrite+0xc4>
        f->off += r;
    800053a0:	02092783          	lw	a5,32(s2)
    800053a4:	9fa9                	addw	a5,a5,a0
    800053a6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800053aa:	01893503          	ld	a0,24(s2)
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	f6a080e7          	jalr	-150(ra) # 80004318 <iunlock>
      end_op();
    800053b6:	00000097          	auipc	ra,0x0
    800053ba:	8ea080e7          	jalr	-1814(ra) # 80004ca0 <end_op>

      if(r != n1){
    800053be:	009a9f63          	bne	s5,s1,800053dc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800053c2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800053c6:	0149db63          	bge	s3,s4,800053dc <filewrite+0xf6>
      int n1 = n - i;
    800053ca:	413a04bb          	subw	s1,s4,s3
    800053ce:	0004879b          	sext.w	a5,s1
    800053d2:	f8fbdce3          	bge	s7,a5,8000536a <filewrite+0x84>
    800053d6:	84e2                	mv	s1,s8
    800053d8:	bf49                	j	8000536a <filewrite+0x84>
    int i = 0;
    800053da:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800053dc:	013a1f63          	bne	s4,s3,800053fa <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800053e0:	8552                	mv	a0,s4
    800053e2:	60a6                	ld	ra,72(sp)
    800053e4:	6406                	ld	s0,64(sp)
    800053e6:	74e2                	ld	s1,56(sp)
    800053e8:	7942                	ld	s2,48(sp)
    800053ea:	79a2                	ld	s3,40(sp)
    800053ec:	7a02                	ld	s4,32(sp)
    800053ee:	6ae2                	ld	s5,24(sp)
    800053f0:	6b42                	ld	s6,16(sp)
    800053f2:	6ba2                	ld	s7,8(sp)
    800053f4:	6c02                	ld	s8,0(sp)
    800053f6:	6161                	addi	sp,sp,80
    800053f8:	8082                	ret
    ret = (i == n ? n : -1);
    800053fa:	5a7d                	li	s4,-1
    800053fc:	b7d5                	j	800053e0 <filewrite+0xfa>
    panic("filewrite");
    800053fe:	00003517          	auipc	a0,0x3
    80005402:	35a50513          	addi	a0,a0,858 # 80008758 <syscalls+0x290>
    80005406:	ffffb097          	auipc	ra,0xffffb
    8000540a:	13a080e7          	jalr	314(ra) # 80000540 <panic>
    return -1;
    8000540e:	5a7d                	li	s4,-1
    80005410:	bfc1                	j	800053e0 <filewrite+0xfa>
      return -1;
    80005412:	5a7d                	li	s4,-1
    80005414:	b7f1                	j	800053e0 <filewrite+0xfa>
    80005416:	5a7d                	li	s4,-1
    80005418:	b7e1                	j	800053e0 <filewrite+0xfa>

000000008000541a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000541a:	7179                	addi	sp,sp,-48
    8000541c:	f406                	sd	ra,40(sp)
    8000541e:	f022                	sd	s0,32(sp)
    80005420:	ec26                	sd	s1,24(sp)
    80005422:	e84a                	sd	s2,16(sp)
    80005424:	e44e                	sd	s3,8(sp)
    80005426:	e052                	sd	s4,0(sp)
    80005428:	1800                	addi	s0,sp,48
    8000542a:	84aa                	mv	s1,a0
    8000542c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000542e:	0005b023          	sd	zero,0(a1)
    80005432:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005436:	00000097          	auipc	ra,0x0
    8000543a:	bf8080e7          	jalr	-1032(ra) # 8000502e <filealloc>
    8000543e:	e088                	sd	a0,0(s1)
    80005440:	c551                	beqz	a0,800054cc <pipealloc+0xb2>
    80005442:	00000097          	auipc	ra,0x0
    80005446:	bec080e7          	jalr	-1044(ra) # 8000502e <filealloc>
    8000544a:	00aa3023          	sd	a0,0(s4)
    8000544e:	c92d                	beqz	a0,800054c0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005450:	ffffb097          	auipc	ra,0xffffb
    80005454:	696080e7          	jalr	1686(ra) # 80000ae6 <kalloc>
    80005458:	892a                	mv	s2,a0
    8000545a:	c125                	beqz	a0,800054ba <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000545c:	4985                	li	s3,1
    8000545e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005462:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005466:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000546a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000546e:	00003597          	auipc	a1,0x3
    80005472:	2fa58593          	addi	a1,a1,762 # 80008768 <syscalls+0x2a0>
    80005476:	ffffb097          	auipc	ra,0xffffb
    8000547a:	6d0080e7          	jalr	1744(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    8000547e:	609c                	ld	a5,0(s1)
    80005480:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005484:	609c                	ld	a5,0(s1)
    80005486:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000548a:	609c                	ld	a5,0(s1)
    8000548c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005490:	609c                	ld	a5,0(s1)
    80005492:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005496:	000a3783          	ld	a5,0(s4)
    8000549a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000549e:	000a3783          	ld	a5,0(s4)
    800054a2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800054a6:	000a3783          	ld	a5,0(s4)
    800054aa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800054ae:	000a3783          	ld	a5,0(s4)
    800054b2:	0127b823          	sd	s2,16(a5)
  return 0;
    800054b6:	4501                	li	a0,0
    800054b8:	a025                	j	800054e0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800054ba:	6088                	ld	a0,0(s1)
    800054bc:	e501                	bnez	a0,800054c4 <pipealloc+0xaa>
    800054be:	a039                	j	800054cc <pipealloc+0xb2>
    800054c0:	6088                	ld	a0,0(s1)
    800054c2:	c51d                	beqz	a0,800054f0 <pipealloc+0xd6>
    fileclose(*f0);
    800054c4:	00000097          	auipc	ra,0x0
    800054c8:	c26080e7          	jalr	-986(ra) # 800050ea <fileclose>
  if(*f1)
    800054cc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800054d0:	557d                	li	a0,-1
  if(*f1)
    800054d2:	c799                	beqz	a5,800054e0 <pipealloc+0xc6>
    fileclose(*f1);
    800054d4:	853e                	mv	a0,a5
    800054d6:	00000097          	auipc	ra,0x0
    800054da:	c14080e7          	jalr	-1004(ra) # 800050ea <fileclose>
  return -1;
    800054de:	557d                	li	a0,-1
}
    800054e0:	70a2                	ld	ra,40(sp)
    800054e2:	7402                	ld	s0,32(sp)
    800054e4:	64e2                	ld	s1,24(sp)
    800054e6:	6942                	ld	s2,16(sp)
    800054e8:	69a2                	ld	s3,8(sp)
    800054ea:	6a02                	ld	s4,0(sp)
    800054ec:	6145                	addi	sp,sp,48
    800054ee:	8082                	ret
  return -1;
    800054f0:	557d                	li	a0,-1
    800054f2:	b7fd                	j	800054e0 <pipealloc+0xc6>

00000000800054f4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800054f4:	1101                	addi	sp,sp,-32
    800054f6:	ec06                	sd	ra,24(sp)
    800054f8:	e822                	sd	s0,16(sp)
    800054fa:	e426                	sd	s1,8(sp)
    800054fc:	e04a                	sd	s2,0(sp)
    800054fe:	1000                	addi	s0,sp,32
    80005500:	84aa                	mv	s1,a0
    80005502:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005504:	ffffb097          	auipc	ra,0xffffb
    80005508:	6d2080e7          	jalr	1746(ra) # 80000bd6 <acquire>
  if(writable){
    8000550c:	02090d63          	beqz	s2,80005546 <pipeclose+0x52>
    pi->writeopen = 0;
    80005510:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005514:	21848513          	addi	a0,s1,536
    80005518:	ffffd097          	auipc	ra,0xffffd
    8000551c:	37e080e7          	jalr	894(ra) # 80002896 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005520:	2204b783          	ld	a5,544(s1)
    80005524:	eb95                	bnez	a5,80005558 <pipeclose+0x64>
    release(&pi->lock);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffb097          	auipc	ra,0xffffb
    8000552c:	762080e7          	jalr	1890(ra) # 80000c8a <release>
    kfree((char*)pi);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffb097          	auipc	ra,0xffffb
    80005536:	4b6080e7          	jalr	1206(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    8000553a:	60e2                	ld	ra,24(sp)
    8000553c:	6442                	ld	s0,16(sp)
    8000553e:	64a2                	ld	s1,8(sp)
    80005540:	6902                	ld	s2,0(sp)
    80005542:	6105                	addi	sp,sp,32
    80005544:	8082                	ret
    pi->readopen = 0;
    80005546:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000554a:	21c48513          	addi	a0,s1,540
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	348080e7          	jalr	840(ra) # 80002896 <wakeup>
    80005556:	b7e9                	j	80005520 <pipeclose+0x2c>
    release(&pi->lock);
    80005558:	8526                	mv	a0,s1
    8000555a:	ffffb097          	auipc	ra,0xffffb
    8000555e:	730080e7          	jalr	1840(ra) # 80000c8a <release>
}
    80005562:	bfe1                	j	8000553a <pipeclose+0x46>

0000000080005564 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005564:	711d                	addi	sp,sp,-96
    80005566:	ec86                	sd	ra,88(sp)
    80005568:	e8a2                	sd	s0,80(sp)
    8000556a:	e4a6                	sd	s1,72(sp)
    8000556c:	e0ca                	sd	s2,64(sp)
    8000556e:	fc4e                	sd	s3,56(sp)
    80005570:	f852                	sd	s4,48(sp)
    80005572:	f456                	sd	s5,40(sp)
    80005574:	f05a                	sd	s6,32(sp)
    80005576:	ec5e                	sd	s7,24(sp)
    80005578:	e862                	sd	s8,16(sp)
    8000557a:	1080                	addi	s0,sp,96
    8000557c:	84aa                	mv	s1,a0
    8000557e:	8aae                	mv	s5,a1
    80005580:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005582:	ffffc097          	auipc	ra,0xffffc
    80005586:	64e080e7          	jalr	1614(ra) # 80001bd0 <myproc>
    8000558a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffb097          	auipc	ra,0xffffb
    80005592:	648080e7          	jalr	1608(ra) # 80000bd6 <acquire>
  while(i < n){
    80005596:	0b405663          	blez	s4,80005642 <pipewrite+0xde>
  int i = 0;
    8000559a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000559c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000559e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800055a2:	21c48b93          	addi	s7,s1,540
    800055a6:	a089                	j	800055e8 <pipewrite+0x84>
      release(&pi->lock);
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffb097          	auipc	ra,0xffffb
    800055ae:	6e0080e7          	jalr	1760(ra) # 80000c8a <release>
      return -1;
    800055b2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800055b4:	854a                	mv	a0,s2
    800055b6:	60e6                	ld	ra,88(sp)
    800055b8:	6446                	ld	s0,80(sp)
    800055ba:	64a6                	ld	s1,72(sp)
    800055bc:	6906                	ld	s2,64(sp)
    800055be:	79e2                	ld	s3,56(sp)
    800055c0:	7a42                	ld	s4,48(sp)
    800055c2:	7aa2                	ld	s5,40(sp)
    800055c4:	7b02                	ld	s6,32(sp)
    800055c6:	6be2                	ld	s7,24(sp)
    800055c8:	6c42                	ld	s8,16(sp)
    800055ca:	6125                	addi	sp,sp,96
    800055cc:	8082                	ret
      wakeup(&pi->nread);
    800055ce:	8562                	mv	a0,s8
    800055d0:	ffffd097          	auipc	ra,0xffffd
    800055d4:	2c6080e7          	jalr	710(ra) # 80002896 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800055d8:	85a6                	mv	a1,s1
    800055da:	855e                	mv	a0,s7
    800055dc:	ffffd097          	auipc	ra,0xffffd
    800055e0:	256080e7          	jalr	598(ra) # 80002832 <sleep>
  while(i < n){
    800055e4:	07495063          	bge	s2,s4,80005644 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800055e8:	2204a783          	lw	a5,544(s1)
    800055ec:	dfd5                	beqz	a5,800055a8 <pipewrite+0x44>
    800055ee:	854e                	mv	a0,s3
    800055f0:	ffffd097          	auipc	ra,0xffffd
    800055f4:	53a080e7          	jalr	1338(ra) # 80002b2a <killed>
    800055f8:	f945                	bnez	a0,800055a8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800055fa:	2184a783          	lw	a5,536(s1)
    800055fe:	21c4a703          	lw	a4,540(s1)
    80005602:	2007879b          	addiw	a5,a5,512
    80005606:	fcf704e3          	beq	a4,a5,800055ce <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000560a:	4685                	li	a3,1
    8000560c:	01590633          	add	a2,s2,s5
    80005610:	faf40593          	addi	a1,s0,-81
    80005614:	0509b503          	ld	a0,80(s3)
    80005618:	ffffc097          	auipc	ra,0xffffc
    8000561c:	0e0080e7          	jalr	224(ra) # 800016f8 <copyin>
    80005620:	03650263          	beq	a0,s6,80005644 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005624:	21c4a783          	lw	a5,540(s1)
    80005628:	0017871b          	addiw	a4,a5,1
    8000562c:	20e4ae23          	sw	a4,540(s1)
    80005630:	1ff7f793          	andi	a5,a5,511
    80005634:	97a6                	add	a5,a5,s1
    80005636:	faf44703          	lbu	a4,-81(s0)
    8000563a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000563e:	2905                	addiw	s2,s2,1
    80005640:	b755                	j	800055e4 <pipewrite+0x80>
  int i = 0;
    80005642:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005644:	21848513          	addi	a0,s1,536
    80005648:	ffffd097          	auipc	ra,0xffffd
    8000564c:	24e080e7          	jalr	590(ra) # 80002896 <wakeup>
  release(&pi->lock);
    80005650:	8526                	mv	a0,s1
    80005652:	ffffb097          	auipc	ra,0xffffb
    80005656:	638080e7          	jalr	1592(ra) # 80000c8a <release>
  return i;
    8000565a:	bfa9                	j	800055b4 <pipewrite+0x50>

000000008000565c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000565c:	715d                	addi	sp,sp,-80
    8000565e:	e486                	sd	ra,72(sp)
    80005660:	e0a2                	sd	s0,64(sp)
    80005662:	fc26                	sd	s1,56(sp)
    80005664:	f84a                	sd	s2,48(sp)
    80005666:	f44e                	sd	s3,40(sp)
    80005668:	f052                	sd	s4,32(sp)
    8000566a:	ec56                	sd	s5,24(sp)
    8000566c:	e85a                	sd	s6,16(sp)
    8000566e:	0880                	addi	s0,sp,80
    80005670:	84aa                	mv	s1,a0
    80005672:	892e                	mv	s2,a1
    80005674:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005676:	ffffc097          	auipc	ra,0xffffc
    8000567a:	55a080e7          	jalr	1370(ra) # 80001bd0 <myproc>
    8000567e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005680:	8526                	mv	a0,s1
    80005682:	ffffb097          	auipc	ra,0xffffb
    80005686:	554080e7          	jalr	1364(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000568a:	2184a703          	lw	a4,536(s1)
    8000568e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005692:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005696:	02f71763          	bne	a4,a5,800056c4 <piperead+0x68>
    8000569a:	2244a783          	lw	a5,548(s1)
    8000569e:	c39d                	beqz	a5,800056c4 <piperead+0x68>
    if(killed(pr)){
    800056a0:	8552                	mv	a0,s4
    800056a2:	ffffd097          	auipc	ra,0xffffd
    800056a6:	488080e7          	jalr	1160(ra) # 80002b2a <killed>
    800056aa:	e949                	bnez	a0,8000573c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056ac:	85a6                	mv	a1,s1
    800056ae:	854e                	mv	a0,s3
    800056b0:	ffffd097          	auipc	ra,0xffffd
    800056b4:	182080e7          	jalr	386(ra) # 80002832 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056b8:	2184a703          	lw	a4,536(s1)
    800056bc:	21c4a783          	lw	a5,540(s1)
    800056c0:	fcf70de3          	beq	a4,a5,8000569a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800056c4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800056c6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800056c8:	05505463          	blez	s5,80005710 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800056cc:	2184a783          	lw	a5,536(s1)
    800056d0:	21c4a703          	lw	a4,540(s1)
    800056d4:	02f70e63          	beq	a4,a5,80005710 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800056d8:	0017871b          	addiw	a4,a5,1
    800056dc:	20e4ac23          	sw	a4,536(s1)
    800056e0:	1ff7f793          	andi	a5,a5,511
    800056e4:	97a6                	add	a5,a5,s1
    800056e6:	0187c783          	lbu	a5,24(a5)
    800056ea:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800056ee:	4685                	li	a3,1
    800056f0:	fbf40613          	addi	a2,s0,-65
    800056f4:	85ca                	mv	a1,s2
    800056f6:	050a3503          	ld	a0,80(s4)
    800056fa:	ffffc097          	auipc	ra,0xffffc
    800056fe:	f72080e7          	jalr	-142(ra) # 8000166c <copyout>
    80005702:	01650763          	beq	a0,s6,80005710 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005706:	2985                	addiw	s3,s3,1
    80005708:	0905                	addi	s2,s2,1
    8000570a:	fd3a91e3          	bne	s5,s3,800056cc <piperead+0x70>
    8000570e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005710:	21c48513          	addi	a0,s1,540
    80005714:	ffffd097          	auipc	ra,0xffffd
    80005718:	182080e7          	jalr	386(ra) # 80002896 <wakeup>
  release(&pi->lock);
    8000571c:	8526                	mv	a0,s1
    8000571e:	ffffb097          	auipc	ra,0xffffb
    80005722:	56c080e7          	jalr	1388(ra) # 80000c8a <release>
  return i;
}
    80005726:	854e                	mv	a0,s3
    80005728:	60a6                	ld	ra,72(sp)
    8000572a:	6406                	ld	s0,64(sp)
    8000572c:	74e2                	ld	s1,56(sp)
    8000572e:	7942                	ld	s2,48(sp)
    80005730:	79a2                	ld	s3,40(sp)
    80005732:	7a02                	ld	s4,32(sp)
    80005734:	6ae2                	ld	s5,24(sp)
    80005736:	6b42                	ld	s6,16(sp)
    80005738:	6161                	addi	sp,sp,80
    8000573a:	8082                	ret
      release(&pi->lock);
    8000573c:	8526                	mv	a0,s1
    8000573e:	ffffb097          	auipc	ra,0xffffb
    80005742:	54c080e7          	jalr	1356(ra) # 80000c8a <release>
      return -1;
    80005746:	59fd                	li	s3,-1
    80005748:	bff9                	j	80005726 <piperead+0xca>

000000008000574a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000574a:	1141                	addi	sp,sp,-16
    8000574c:	e422                	sd	s0,8(sp)
    8000574e:	0800                	addi	s0,sp,16
    80005750:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005752:	8905                	andi	a0,a0,1
    80005754:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005756:	8b89                	andi	a5,a5,2
    80005758:	c399                	beqz	a5,8000575e <flags2perm+0x14>
      perm |= PTE_W;
    8000575a:	00456513          	ori	a0,a0,4
    return perm;
}
    8000575e:	6422                	ld	s0,8(sp)
    80005760:	0141                	addi	sp,sp,16
    80005762:	8082                	ret

0000000080005764 <exec>:

int
exec(char *path, char **argv)
{
    80005764:	de010113          	addi	sp,sp,-544
    80005768:	20113c23          	sd	ra,536(sp)
    8000576c:	20813823          	sd	s0,528(sp)
    80005770:	20913423          	sd	s1,520(sp)
    80005774:	21213023          	sd	s2,512(sp)
    80005778:	ffce                	sd	s3,504(sp)
    8000577a:	fbd2                	sd	s4,496(sp)
    8000577c:	f7d6                	sd	s5,488(sp)
    8000577e:	f3da                	sd	s6,480(sp)
    80005780:	efde                	sd	s7,472(sp)
    80005782:	ebe2                	sd	s8,464(sp)
    80005784:	e7e6                	sd	s9,456(sp)
    80005786:	e3ea                	sd	s10,448(sp)
    80005788:	ff6e                	sd	s11,440(sp)
    8000578a:	1400                	addi	s0,sp,544
    8000578c:	892a                	mv	s2,a0
    8000578e:	dea43423          	sd	a0,-536(s0)
    80005792:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005796:	ffffc097          	auipc	ra,0xffffc
    8000579a:	43a080e7          	jalr	1082(ra) # 80001bd0 <myproc>
    8000579e:	84aa                	mv	s1,a0

  begin_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	482080e7          	jalr	1154(ra) # 80004c22 <begin_op>

  if((ip = namei(path)) == 0){
    800057a8:	854a                	mv	a0,s2
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	258080e7          	jalr	600(ra) # 80004a02 <namei>
    800057b2:	c93d                	beqz	a0,80005828 <exec+0xc4>
    800057b4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	aa0080e7          	jalr	-1376(ra) # 80004256 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800057be:	04000713          	li	a4,64
    800057c2:	4681                	li	a3,0
    800057c4:	e5040613          	addi	a2,s0,-432
    800057c8:	4581                	li	a1,0
    800057ca:	8556                	mv	a0,s5
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	d3e080e7          	jalr	-706(ra) # 8000450a <readi>
    800057d4:	04000793          	li	a5,64
    800057d8:	00f51a63          	bne	a0,a5,800057ec <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800057dc:	e5042703          	lw	a4,-432(s0)
    800057e0:	464c47b7          	lui	a5,0x464c4
    800057e4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800057e8:	04f70663          	beq	a4,a5,80005834 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800057ec:	8556                	mv	a0,s5
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	cca080e7          	jalr	-822(ra) # 800044b8 <iunlockput>
    end_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	4aa080e7          	jalr	1194(ra) # 80004ca0 <end_op>
  }
  return -1;
    800057fe:	557d                	li	a0,-1
}
    80005800:	21813083          	ld	ra,536(sp)
    80005804:	21013403          	ld	s0,528(sp)
    80005808:	20813483          	ld	s1,520(sp)
    8000580c:	20013903          	ld	s2,512(sp)
    80005810:	79fe                	ld	s3,504(sp)
    80005812:	7a5e                	ld	s4,496(sp)
    80005814:	7abe                	ld	s5,488(sp)
    80005816:	7b1e                	ld	s6,480(sp)
    80005818:	6bfe                	ld	s7,472(sp)
    8000581a:	6c5e                	ld	s8,464(sp)
    8000581c:	6cbe                	ld	s9,456(sp)
    8000581e:	6d1e                	ld	s10,448(sp)
    80005820:	7dfa                	ld	s11,440(sp)
    80005822:	22010113          	addi	sp,sp,544
    80005826:	8082                	ret
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	478080e7          	jalr	1144(ra) # 80004ca0 <end_op>
    return -1;
    80005830:	557d                	li	a0,-1
    80005832:	b7f9                	j	80005800 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005834:	8526                	mv	a0,s1
    80005836:	ffffc097          	auipc	ra,0xffffc
    8000583a:	45e080e7          	jalr	1118(ra) # 80001c94 <proc_pagetable>
    8000583e:	8b2a                	mv	s6,a0
    80005840:	d555                	beqz	a0,800057ec <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005842:	e7042783          	lw	a5,-400(s0)
    80005846:	e8845703          	lhu	a4,-376(s0)
    8000584a:	c735                	beqz	a4,800058b6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000584c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000584e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005852:	6a05                	lui	s4,0x1
    80005854:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005858:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000585c:	6d85                	lui	s11,0x1
    8000585e:	7d7d                	lui	s10,0xfffff
    80005860:	ac3d                	j	80005a9e <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005862:	00003517          	auipc	a0,0x3
    80005866:	f0e50513          	addi	a0,a0,-242 # 80008770 <syscalls+0x2a8>
    8000586a:	ffffb097          	auipc	ra,0xffffb
    8000586e:	cd6080e7          	jalr	-810(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005872:	874a                	mv	a4,s2
    80005874:	009c86bb          	addw	a3,s9,s1
    80005878:	4581                	li	a1,0
    8000587a:	8556                	mv	a0,s5
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	c8e080e7          	jalr	-882(ra) # 8000450a <readi>
    80005884:	2501                	sext.w	a0,a0
    80005886:	1aa91963          	bne	s2,a0,80005a38 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000588a:	009d84bb          	addw	s1,s11,s1
    8000588e:	013d09bb          	addw	s3,s10,s3
    80005892:	1f74f663          	bgeu	s1,s7,80005a7e <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005896:	02049593          	slli	a1,s1,0x20
    8000589a:	9181                	srli	a1,a1,0x20
    8000589c:	95e2                	add	a1,a1,s8
    8000589e:	855a                	mv	a0,s6
    800058a0:	ffffb097          	auipc	ra,0xffffb
    800058a4:	7bc080e7          	jalr	1980(ra) # 8000105c <walkaddr>
    800058a8:	862a                	mv	a2,a0
    if(pa == 0)
    800058aa:	dd45                	beqz	a0,80005862 <exec+0xfe>
      n = PGSIZE;
    800058ac:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800058ae:	fd49f2e3          	bgeu	s3,s4,80005872 <exec+0x10e>
      n = sz - i;
    800058b2:	894e                	mv	s2,s3
    800058b4:	bf7d                	j	80005872 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058b6:	4901                	li	s2,0
  iunlockput(ip);
    800058b8:	8556                	mv	a0,s5
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	bfe080e7          	jalr	-1026(ra) # 800044b8 <iunlockput>
  end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	3de080e7          	jalr	990(ra) # 80004ca0 <end_op>
  p = myproc();
    800058ca:	ffffc097          	auipc	ra,0xffffc
    800058ce:	306080e7          	jalr	774(ra) # 80001bd0 <myproc>
    800058d2:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800058d4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800058d8:	6785                	lui	a5,0x1
    800058da:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800058dc:	97ca                	add	a5,a5,s2
    800058de:	777d                	lui	a4,0xfffff
    800058e0:	8ff9                	and	a5,a5,a4
    800058e2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800058e6:	4691                	li	a3,4
    800058e8:	6609                	lui	a2,0x2
    800058ea:	963e                	add	a2,a2,a5
    800058ec:	85be                	mv	a1,a5
    800058ee:	855a                	mv	a0,s6
    800058f0:	ffffc097          	auipc	ra,0xffffc
    800058f4:	b20080e7          	jalr	-1248(ra) # 80001410 <uvmalloc>
    800058f8:	8c2a                	mv	s8,a0
  ip = 0;
    800058fa:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800058fc:	12050e63          	beqz	a0,80005a38 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005900:	75f9                	lui	a1,0xffffe
    80005902:	95aa                	add	a1,a1,a0
    80005904:	855a                	mv	a0,s6
    80005906:	ffffc097          	auipc	ra,0xffffc
    8000590a:	d34080e7          	jalr	-716(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    8000590e:	7afd                	lui	s5,0xfffff
    80005910:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005912:	df043783          	ld	a5,-528(s0)
    80005916:	6388                	ld	a0,0(a5)
    80005918:	c925                	beqz	a0,80005988 <exec+0x224>
    8000591a:	e9040993          	addi	s3,s0,-368
    8000591e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005922:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005924:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005926:	ffffb097          	auipc	ra,0xffffb
    8000592a:	528080e7          	jalr	1320(ra) # 80000e4e <strlen>
    8000592e:	0015079b          	addiw	a5,a0,1
    80005932:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005936:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000593a:	13596663          	bltu	s2,s5,80005a66 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000593e:	df043d83          	ld	s11,-528(s0)
    80005942:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005946:	8552                	mv	a0,s4
    80005948:	ffffb097          	auipc	ra,0xffffb
    8000594c:	506080e7          	jalr	1286(ra) # 80000e4e <strlen>
    80005950:	0015069b          	addiw	a3,a0,1
    80005954:	8652                	mv	a2,s4
    80005956:	85ca                	mv	a1,s2
    80005958:	855a                	mv	a0,s6
    8000595a:	ffffc097          	auipc	ra,0xffffc
    8000595e:	d12080e7          	jalr	-750(ra) # 8000166c <copyout>
    80005962:	10054663          	bltz	a0,80005a6e <exec+0x30a>
    ustack[argc] = sp;
    80005966:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000596a:	0485                	addi	s1,s1,1
    8000596c:	008d8793          	addi	a5,s11,8
    80005970:	def43823          	sd	a5,-528(s0)
    80005974:	008db503          	ld	a0,8(s11)
    80005978:	c911                	beqz	a0,8000598c <exec+0x228>
    if(argc >= MAXARG)
    8000597a:	09a1                	addi	s3,s3,8
    8000597c:	fb3c95e3          	bne	s9,s3,80005926 <exec+0x1c2>
  sz = sz1;
    80005980:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005984:	4a81                	li	s5,0
    80005986:	a84d                	j	80005a38 <exec+0x2d4>
  sp = sz;
    80005988:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000598a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000598c:	00349793          	slli	a5,s1,0x3
    80005990:	f9078793          	addi	a5,a5,-112
    80005994:	97a2                	add	a5,a5,s0
    80005996:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000599a:	00148693          	addi	a3,s1,1
    8000599e:	068e                	slli	a3,a3,0x3
    800059a0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800059a4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800059a8:	01597663          	bgeu	s2,s5,800059b4 <exec+0x250>
  sz = sz1;
    800059ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800059b0:	4a81                	li	s5,0
    800059b2:	a059                	j	80005a38 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800059b4:	e9040613          	addi	a2,s0,-368
    800059b8:	85ca                	mv	a1,s2
    800059ba:	855a                	mv	a0,s6
    800059bc:	ffffc097          	auipc	ra,0xffffc
    800059c0:	cb0080e7          	jalr	-848(ra) # 8000166c <copyout>
    800059c4:	0a054963          	bltz	a0,80005a76 <exec+0x312>
  p->trapframe->a1 = sp;
    800059c8:	058bb783          	ld	a5,88(s7)
    800059cc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800059d0:	de843783          	ld	a5,-536(s0)
    800059d4:	0007c703          	lbu	a4,0(a5)
    800059d8:	cf11                	beqz	a4,800059f4 <exec+0x290>
    800059da:	0785                	addi	a5,a5,1
    if(*s == '/')
    800059dc:	02f00693          	li	a3,47
    800059e0:	a039                	j	800059ee <exec+0x28a>
      last = s+1;
    800059e2:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800059e6:	0785                	addi	a5,a5,1
    800059e8:	fff7c703          	lbu	a4,-1(a5)
    800059ec:	c701                	beqz	a4,800059f4 <exec+0x290>
    if(*s == '/')
    800059ee:	fed71ce3          	bne	a4,a3,800059e6 <exec+0x282>
    800059f2:	bfc5                	j	800059e2 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800059f4:	4641                	li	a2,16
    800059f6:	de843583          	ld	a1,-536(s0)
    800059fa:	158b8513          	addi	a0,s7,344
    800059fe:	ffffb097          	auipc	ra,0xffffb
    80005a02:	41e080e7          	jalr	1054(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005a06:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005a0a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005a0e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a12:	058bb783          	ld	a5,88(s7)
    80005a16:	e6843703          	ld	a4,-408(s0)
    80005a1a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a1c:	058bb783          	ld	a5,88(s7)
    80005a20:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a24:	85ea                	mv	a1,s10
    80005a26:	ffffc097          	auipc	ra,0xffffc
    80005a2a:	30a080e7          	jalr	778(ra) # 80001d30 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005a2e:	0004851b          	sext.w	a0,s1
    80005a32:	b3f9                	j	80005800 <exec+0x9c>
    80005a34:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005a38:	df843583          	ld	a1,-520(s0)
    80005a3c:	855a                	mv	a0,s6
    80005a3e:	ffffc097          	auipc	ra,0xffffc
    80005a42:	2f2080e7          	jalr	754(ra) # 80001d30 <proc_freepagetable>
  if(ip){
    80005a46:	da0a93e3          	bnez	s5,800057ec <exec+0x88>
  return -1;
    80005a4a:	557d                	li	a0,-1
    80005a4c:	bb55                	j	80005800 <exec+0x9c>
    80005a4e:	df243c23          	sd	s2,-520(s0)
    80005a52:	b7dd                	j	80005a38 <exec+0x2d4>
    80005a54:	df243c23          	sd	s2,-520(s0)
    80005a58:	b7c5                	j	80005a38 <exec+0x2d4>
    80005a5a:	df243c23          	sd	s2,-520(s0)
    80005a5e:	bfe9                	j	80005a38 <exec+0x2d4>
    80005a60:	df243c23          	sd	s2,-520(s0)
    80005a64:	bfd1                	j	80005a38 <exec+0x2d4>
  sz = sz1;
    80005a66:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005a6a:	4a81                	li	s5,0
    80005a6c:	b7f1                	j	80005a38 <exec+0x2d4>
  sz = sz1;
    80005a6e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005a72:	4a81                	li	s5,0
    80005a74:	b7d1                	j	80005a38 <exec+0x2d4>
  sz = sz1;
    80005a76:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005a7a:	4a81                	li	s5,0
    80005a7c:	bf75                	j	80005a38 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005a7e:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a82:	e0843783          	ld	a5,-504(s0)
    80005a86:	0017869b          	addiw	a3,a5,1
    80005a8a:	e0d43423          	sd	a3,-504(s0)
    80005a8e:	e0043783          	ld	a5,-512(s0)
    80005a92:	0387879b          	addiw	a5,a5,56
    80005a96:	e8845703          	lhu	a4,-376(s0)
    80005a9a:	e0e6dfe3          	bge	a3,a4,800058b8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005a9e:	2781                	sext.w	a5,a5
    80005aa0:	e0f43023          	sd	a5,-512(s0)
    80005aa4:	03800713          	li	a4,56
    80005aa8:	86be                	mv	a3,a5
    80005aaa:	e1840613          	addi	a2,s0,-488
    80005aae:	4581                	li	a1,0
    80005ab0:	8556                	mv	a0,s5
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	a58080e7          	jalr	-1448(ra) # 8000450a <readi>
    80005aba:	03800793          	li	a5,56
    80005abe:	f6f51be3          	bne	a0,a5,80005a34 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005ac2:	e1842783          	lw	a5,-488(s0)
    80005ac6:	4705                	li	a4,1
    80005ac8:	fae79de3          	bne	a5,a4,80005a82 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005acc:	e4043483          	ld	s1,-448(s0)
    80005ad0:	e3843783          	ld	a5,-456(s0)
    80005ad4:	f6f4ede3          	bltu	s1,a5,80005a4e <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005ad8:	e2843783          	ld	a5,-472(s0)
    80005adc:	94be                	add	s1,s1,a5
    80005ade:	f6f4ebe3          	bltu	s1,a5,80005a54 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005ae2:	de043703          	ld	a4,-544(s0)
    80005ae6:	8ff9                	and	a5,a5,a4
    80005ae8:	fbad                	bnez	a5,80005a5a <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005aea:	e1c42503          	lw	a0,-484(s0)
    80005aee:	00000097          	auipc	ra,0x0
    80005af2:	c5c080e7          	jalr	-932(ra) # 8000574a <flags2perm>
    80005af6:	86aa                	mv	a3,a0
    80005af8:	8626                	mv	a2,s1
    80005afa:	85ca                	mv	a1,s2
    80005afc:	855a                	mv	a0,s6
    80005afe:	ffffc097          	auipc	ra,0xffffc
    80005b02:	912080e7          	jalr	-1774(ra) # 80001410 <uvmalloc>
    80005b06:	dea43c23          	sd	a0,-520(s0)
    80005b0a:	d939                	beqz	a0,80005a60 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b0c:	e2843c03          	ld	s8,-472(s0)
    80005b10:	e2042c83          	lw	s9,-480(s0)
    80005b14:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b18:	f60b83e3          	beqz	s7,80005a7e <exec+0x31a>
    80005b1c:	89de                	mv	s3,s7
    80005b1e:	4481                	li	s1,0
    80005b20:	bb9d                	j	80005896 <exec+0x132>

0000000080005b22 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005b22:	7179                	addi	sp,sp,-48
    80005b24:	f406                	sd	ra,40(sp)
    80005b26:	f022                	sd	s0,32(sp)
    80005b28:	ec26                	sd	s1,24(sp)
    80005b2a:	e84a                	sd	s2,16(sp)
    80005b2c:	1800                	addi	s0,sp,48
    80005b2e:	892e                	mv	s2,a1
    80005b30:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005b32:	fdc40593          	addi	a1,s0,-36
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	a4a080e7          	jalr	-1462(ra) # 80003580 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005b3e:	fdc42703          	lw	a4,-36(s0)
    80005b42:	47bd                	li	a5,15
    80005b44:	02e7eb63          	bltu	a5,a4,80005b7a <argfd+0x58>
    80005b48:	ffffc097          	auipc	ra,0xffffc
    80005b4c:	088080e7          	jalr	136(ra) # 80001bd0 <myproc>
    80005b50:	fdc42703          	lw	a4,-36(s0)
    80005b54:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdb83a>
    80005b58:	078e                	slli	a5,a5,0x3
    80005b5a:	953e                	add	a0,a0,a5
    80005b5c:	611c                	ld	a5,0(a0)
    80005b5e:	c385                	beqz	a5,80005b7e <argfd+0x5c>
    return -1;
  if(pfd)
    80005b60:	00090463          	beqz	s2,80005b68 <argfd+0x46>
    *pfd = fd;
    80005b64:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005b68:	4501                	li	a0,0
  if(pf)
    80005b6a:	c091                	beqz	s1,80005b6e <argfd+0x4c>
    *pf = f;
    80005b6c:	e09c                	sd	a5,0(s1)
}
    80005b6e:	70a2                	ld	ra,40(sp)
    80005b70:	7402                	ld	s0,32(sp)
    80005b72:	64e2                	ld	s1,24(sp)
    80005b74:	6942                	ld	s2,16(sp)
    80005b76:	6145                	addi	sp,sp,48
    80005b78:	8082                	ret
    return -1;
    80005b7a:	557d                	li	a0,-1
    80005b7c:	bfcd                	j	80005b6e <argfd+0x4c>
    80005b7e:	557d                	li	a0,-1
    80005b80:	b7fd                	j	80005b6e <argfd+0x4c>

0000000080005b82 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005b82:	1101                	addi	sp,sp,-32
    80005b84:	ec06                	sd	ra,24(sp)
    80005b86:	e822                	sd	s0,16(sp)
    80005b88:	e426                	sd	s1,8(sp)
    80005b8a:	1000                	addi	s0,sp,32
    80005b8c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005b8e:	ffffc097          	auipc	ra,0xffffc
    80005b92:	042080e7          	jalr	66(ra) # 80001bd0 <myproc>
    80005b96:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005b98:	0d050793          	addi	a5,a0,208
    80005b9c:	4501                	li	a0,0
    80005b9e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005ba0:	6398                	ld	a4,0(a5)
    80005ba2:	cb19                	beqz	a4,80005bb8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005ba4:	2505                	addiw	a0,a0,1
    80005ba6:	07a1                	addi	a5,a5,8
    80005ba8:	fed51ce3          	bne	a0,a3,80005ba0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005bac:	557d                	li	a0,-1
}
    80005bae:	60e2                	ld	ra,24(sp)
    80005bb0:	6442                	ld	s0,16(sp)
    80005bb2:	64a2                	ld	s1,8(sp)
    80005bb4:	6105                	addi	sp,sp,32
    80005bb6:	8082                	ret
      p->ofile[fd] = f;
    80005bb8:	01a50793          	addi	a5,a0,26
    80005bbc:	078e                	slli	a5,a5,0x3
    80005bbe:	963e                	add	a2,a2,a5
    80005bc0:	e204                	sd	s1,0(a2)
      return fd;
    80005bc2:	b7f5                	j	80005bae <fdalloc+0x2c>

0000000080005bc4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005bc4:	715d                	addi	sp,sp,-80
    80005bc6:	e486                	sd	ra,72(sp)
    80005bc8:	e0a2                	sd	s0,64(sp)
    80005bca:	fc26                	sd	s1,56(sp)
    80005bcc:	f84a                	sd	s2,48(sp)
    80005bce:	f44e                	sd	s3,40(sp)
    80005bd0:	f052                	sd	s4,32(sp)
    80005bd2:	ec56                	sd	s5,24(sp)
    80005bd4:	e85a                	sd	s6,16(sp)
    80005bd6:	0880                	addi	s0,sp,80
    80005bd8:	8b2e                	mv	s6,a1
    80005bda:	89b2                	mv	s3,a2
    80005bdc:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005bde:	fb040593          	addi	a1,s0,-80
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	e3e080e7          	jalr	-450(ra) # 80004a20 <nameiparent>
    80005bea:	84aa                	mv	s1,a0
    80005bec:	14050f63          	beqz	a0,80005d4a <create+0x186>
    return 0;

  ilock(dp);
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	666080e7          	jalr	1638(ra) # 80004256 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005bf8:	4601                	li	a2,0
    80005bfa:	fb040593          	addi	a1,s0,-80
    80005bfe:	8526                	mv	a0,s1
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	b3a080e7          	jalr	-1222(ra) # 8000473a <dirlookup>
    80005c08:	8aaa                	mv	s5,a0
    80005c0a:	c931                	beqz	a0,80005c5e <create+0x9a>
    iunlockput(dp);
    80005c0c:	8526                	mv	a0,s1
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	8aa080e7          	jalr	-1878(ra) # 800044b8 <iunlockput>
    ilock(ip);
    80005c16:	8556                	mv	a0,s5
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	63e080e7          	jalr	1598(ra) # 80004256 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c20:	000b059b          	sext.w	a1,s6
    80005c24:	4789                	li	a5,2
    80005c26:	02f59563          	bne	a1,a5,80005c50 <create+0x8c>
    80005c2a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdb864>
    80005c2e:	37f9                	addiw	a5,a5,-2
    80005c30:	17c2                	slli	a5,a5,0x30
    80005c32:	93c1                	srli	a5,a5,0x30
    80005c34:	4705                	li	a4,1
    80005c36:	00f76d63          	bltu	a4,a5,80005c50 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005c3a:	8556                	mv	a0,s5
    80005c3c:	60a6                	ld	ra,72(sp)
    80005c3e:	6406                	ld	s0,64(sp)
    80005c40:	74e2                	ld	s1,56(sp)
    80005c42:	7942                	ld	s2,48(sp)
    80005c44:	79a2                	ld	s3,40(sp)
    80005c46:	7a02                	ld	s4,32(sp)
    80005c48:	6ae2                	ld	s5,24(sp)
    80005c4a:	6b42                	ld	s6,16(sp)
    80005c4c:	6161                	addi	sp,sp,80
    80005c4e:	8082                	ret
    iunlockput(ip);
    80005c50:	8556                	mv	a0,s5
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	866080e7          	jalr	-1946(ra) # 800044b8 <iunlockput>
    return 0;
    80005c5a:	4a81                	li	s5,0
    80005c5c:	bff9                	j	80005c3a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005c5e:	85da                	mv	a1,s6
    80005c60:	4088                	lw	a0,0(s1)
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	456080e7          	jalr	1110(ra) # 800040b8 <ialloc>
    80005c6a:	8a2a                	mv	s4,a0
    80005c6c:	c539                	beqz	a0,80005cba <create+0xf6>
  ilock(ip);
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	5e8080e7          	jalr	1512(ra) # 80004256 <ilock>
  ip->major = major;
    80005c76:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005c7a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005c7e:	4905                	li	s2,1
    80005c80:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005c84:	8552                	mv	a0,s4
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	504080e7          	jalr	1284(ra) # 8000418a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005c8e:	000b059b          	sext.w	a1,s6
    80005c92:	03258b63          	beq	a1,s2,80005cc8 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005c96:	004a2603          	lw	a2,4(s4)
    80005c9a:	fb040593          	addi	a1,s0,-80
    80005c9e:	8526                	mv	a0,s1
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	cb0080e7          	jalr	-848(ra) # 80004950 <dirlink>
    80005ca8:	06054f63          	bltz	a0,80005d26 <create+0x162>
  iunlockput(dp);
    80005cac:	8526                	mv	a0,s1
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	80a080e7          	jalr	-2038(ra) # 800044b8 <iunlockput>
  return ip;
    80005cb6:	8ad2                	mv	s5,s4
    80005cb8:	b749                	j	80005c3a <create+0x76>
    iunlockput(dp);
    80005cba:	8526                	mv	a0,s1
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	7fc080e7          	jalr	2044(ra) # 800044b8 <iunlockput>
    return 0;
    80005cc4:	8ad2                	mv	s5,s4
    80005cc6:	bf95                	j	80005c3a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005cc8:	004a2603          	lw	a2,4(s4)
    80005ccc:	00003597          	auipc	a1,0x3
    80005cd0:	ac458593          	addi	a1,a1,-1340 # 80008790 <syscalls+0x2c8>
    80005cd4:	8552                	mv	a0,s4
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	c7a080e7          	jalr	-902(ra) # 80004950 <dirlink>
    80005cde:	04054463          	bltz	a0,80005d26 <create+0x162>
    80005ce2:	40d0                	lw	a2,4(s1)
    80005ce4:	00003597          	auipc	a1,0x3
    80005ce8:	ab458593          	addi	a1,a1,-1356 # 80008798 <syscalls+0x2d0>
    80005cec:	8552                	mv	a0,s4
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	c62080e7          	jalr	-926(ra) # 80004950 <dirlink>
    80005cf6:	02054863          	bltz	a0,80005d26 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005cfa:	004a2603          	lw	a2,4(s4)
    80005cfe:	fb040593          	addi	a1,s0,-80
    80005d02:	8526                	mv	a0,s1
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	c4c080e7          	jalr	-948(ra) # 80004950 <dirlink>
    80005d0c:	00054d63          	bltz	a0,80005d26 <create+0x162>
    dp->nlink++;  // for ".."
    80005d10:	04a4d783          	lhu	a5,74(s1)
    80005d14:	2785                	addiw	a5,a5,1
    80005d16:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d1a:	8526                	mv	a0,s1
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	46e080e7          	jalr	1134(ra) # 8000418a <iupdate>
    80005d24:	b761                	j	80005cac <create+0xe8>
  ip->nlink = 0;
    80005d26:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005d2a:	8552                	mv	a0,s4
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	45e080e7          	jalr	1118(ra) # 8000418a <iupdate>
  iunlockput(ip);
    80005d34:	8552                	mv	a0,s4
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	782080e7          	jalr	1922(ra) # 800044b8 <iunlockput>
  iunlockput(dp);
    80005d3e:	8526                	mv	a0,s1
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	778080e7          	jalr	1912(ra) # 800044b8 <iunlockput>
  return 0;
    80005d48:	bdcd                	j	80005c3a <create+0x76>
    return 0;
    80005d4a:	8aaa                	mv	s5,a0
    80005d4c:	b5fd                	j	80005c3a <create+0x76>

0000000080005d4e <sys_dup>:
{
    80005d4e:	7179                	addi	sp,sp,-48
    80005d50:	f406                	sd	ra,40(sp)
    80005d52:	f022                	sd	s0,32(sp)
    80005d54:	ec26                	sd	s1,24(sp)
    80005d56:	e84a                	sd	s2,16(sp)
    80005d58:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005d5a:	fd840613          	addi	a2,s0,-40
    80005d5e:	4581                	li	a1,0
    80005d60:	4501                	li	a0,0
    80005d62:	00000097          	auipc	ra,0x0
    80005d66:	dc0080e7          	jalr	-576(ra) # 80005b22 <argfd>
    return -1;
    80005d6a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d6c:	02054363          	bltz	a0,80005d92 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005d70:	fd843903          	ld	s2,-40(s0)
    80005d74:	854a                	mv	a0,s2
    80005d76:	00000097          	auipc	ra,0x0
    80005d7a:	e0c080e7          	jalr	-500(ra) # 80005b82 <fdalloc>
    80005d7e:	84aa                	mv	s1,a0
    return -1;
    80005d80:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005d82:	00054863          	bltz	a0,80005d92 <sys_dup+0x44>
  filedup(f);
    80005d86:	854a                	mv	a0,s2
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	310080e7          	jalr	784(ra) # 80005098 <filedup>
  return fd;
    80005d90:	87a6                	mv	a5,s1
}
    80005d92:	853e                	mv	a0,a5
    80005d94:	70a2                	ld	ra,40(sp)
    80005d96:	7402                	ld	s0,32(sp)
    80005d98:	64e2                	ld	s1,24(sp)
    80005d9a:	6942                	ld	s2,16(sp)
    80005d9c:	6145                	addi	sp,sp,48
    80005d9e:	8082                	ret

0000000080005da0 <sys_read>:
{
    80005da0:	7179                	addi	sp,sp,-48
    80005da2:	f406                	sd	ra,40(sp)
    80005da4:	f022                	sd	s0,32(sp)
    80005da6:	1800                	addi	s0,sp,48
  readcount=readcount+1;
    80005da8:	00003717          	auipc	a4,0x3
    80005dac:	be070713          	addi	a4,a4,-1056 # 80008988 <readcount>
    80005db0:	431c                	lw	a5,0(a4)
    80005db2:	2785                	addiw	a5,a5,1
    80005db4:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005db6:	fd840593          	addi	a1,s0,-40
    80005dba:	4505                	li	a0,1
    80005dbc:	ffffd097          	auipc	ra,0xffffd
    80005dc0:	7e6080e7          	jalr	2022(ra) # 800035a2 <argaddr>
  argint(2, &n);
    80005dc4:	fe440593          	addi	a1,s0,-28
    80005dc8:	4509                	li	a0,2
    80005dca:	ffffd097          	auipc	ra,0xffffd
    80005dce:	7b6080e7          	jalr	1974(ra) # 80003580 <argint>
  if(argfd(0, 0, &f) < 0)
    80005dd2:	fe840613          	addi	a2,s0,-24
    80005dd6:	4581                	li	a1,0
    80005dd8:	4501                	li	a0,0
    80005dda:	00000097          	auipc	ra,0x0
    80005dde:	d48080e7          	jalr	-696(ra) # 80005b22 <argfd>
    80005de2:	87aa                	mv	a5,a0
    return -1;
    80005de4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005de6:	0007cc63          	bltz	a5,80005dfe <sys_read+0x5e>
  return fileread(f, p, n);
    80005dea:	fe442603          	lw	a2,-28(s0)
    80005dee:	fd843583          	ld	a1,-40(s0)
    80005df2:	fe843503          	ld	a0,-24(s0)
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	42e080e7          	jalr	1070(ra) # 80005224 <fileread>
}
    80005dfe:	70a2                	ld	ra,40(sp)
    80005e00:	7402                	ld	s0,32(sp)
    80005e02:	6145                	addi	sp,sp,48
    80005e04:	8082                	ret

0000000080005e06 <sys_write>:
{
    80005e06:	7179                	addi	sp,sp,-48
    80005e08:	f406                	sd	ra,40(sp)
    80005e0a:	f022                	sd	s0,32(sp)
    80005e0c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005e0e:	fd840593          	addi	a1,s0,-40
    80005e12:	4505                	li	a0,1
    80005e14:	ffffd097          	auipc	ra,0xffffd
    80005e18:	78e080e7          	jalr	1934(ra) # 800035a2 <argaddr>
  argint(2, &n);
    80005e1c:	fe440593          	addi	a1,s0,-28
    80005e20:	4509                	li	a0,2
    80005e22:	ffffd097          	auipc	ra,0xffffd
    80005e26:	75e080e7          	jalr	1886(ra) # 80003580 <argint>
  if(argfd(0, 0, &f) < 0)
    80005e2a:	fe840613          	addi	a2,s0,-24
    80005e2e:	4581                	li	a1,0
    80005e30:	4501                	li	a0,0
    80005e32:	00000097          	auipc	ra,0x0
    80005e36:	cf0080e7          	jalr	-784(ra) # 80005b22 <argfd>
    80005e3a:	87aa                	mv	a5,a0
    return -1;
    80005e3c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e3e:	0007cc63          	bltz	a5,80005e56 <sys_write+0x50>
  return filewrite(f, p, n);
    80005e42:	fe442603          	lw	a2,-28(s0)
    80005e46:	fd843583          	ld	a1,-40(s0)
    80005e4a:	fe843503          	ld	a0,-24(s0)
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	498080e7          	jalr	1176(ra) # 800052e6 <filewrite>
}
    80005e56:	70a2                	ld	ra,40(sp)
    80005e58:	7402                	ld	s0,32(sp)
    80005e5a:	6145                	addi	sp,sp,48
    80005e5c:	8082                	ret

0000000080005e5e <sys_close>:
{
    80005e5e:	1101                	addi	sp,sp,-32
    80005e60:	ec06                	sd	ra,24(sp)
    80005e62:	e822                	sd	s0,16(sp)
    80005e64:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005e66:	fe040613          	addi	a2,s0,-32
    80005e6a:	fec40593          	addi	a1,s0,-20
    80005e6e:	4501                	li	a0,0
    80005e70:	00000097          	auipc	ra,0x0
    80005e74:	cb2080e7          	jalr	-846(ra) # 80005b22 <argfd>
    return -1;
    80005e78:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005e7a:	02054463          	bltz	a0,80005ea2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005e7e:	ffffc097          	auipc	ra,0xffffc
    80005e82:	d52080e7          	jalr	-686(ra) # 80001bd0 <myproc>
    80005e86:	fec42783          	lw	a5,-20(s0)
    80005e8a:	07e9                	addi	a5,a5,26
    80005e8c:	078e                	slli	a5,a5,0x3
    80005e8e:	953e                	add	a0,a0,a5
    80005e90:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005e94:	fe043503          	ld	a0,-32(s0)
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	252080e7          	jalr	594(ra) # 800050ea <fileclose>
  return 0;
    80005ea0:	4781                	li	a5,0
}
    80005ea2:	853e                	mv	a0,a5
    80005ea4:	60e2                	ld	ra,24(sp)
    80005ea6:	6442                	ld	s0,16(sp)
    80005ea8:	6105                	addi	sp,sp,32
    80005eaa:	8082                	ret

0000000080005eac <sys_fstat>:
{
    80005eac:	1101                	addi	sp,sp,-32
    80005eae:	ec06                	sd	ra,24(sp)
    80005eb0:	e822                	sd	s0,16(sp)
    80005eb2:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005eb4:	fe040593          	addi	a1,s0,-32
    80005eb8:	4505                	li	a0,1
    80005eba:	ffffd097          	auipc	ra,0xffffd
    80005ebe:	6e8080e7          	jalr	1768(ra) # 800035a2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005ec2:	fe840613          	addi	a2,s0,-24
    80005ec6:	4581                	li	a1,0
    80005ec8:	4501                	li	a0,0
    80005eca:	00000097          	auipc	ra,0x0
    80005ece:	c58080e7          	jalr	-936(ra) # 80005b22 <argfd>
    80005ed2:	87aa                	mv	a5,a0
    return -1;
    80005ed4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ed6:	0007ca63          	bltz	a5,80005eea <sys_fstat+0x3e>
  return filestat(f, st);
    80005eda:	fe043583          	ld	a1,-32(s0)
    80005ede:	fe843503          	ld	a0,-24(s0)
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	2d0080e7          	jalr	720(ra) # 800051b2 <filestat>
}
    80005eea:	60e2                	ld	ra,24(sp)
    80005eec:	6442                	ld	s0,16(sp)
    80005eee:	6105                	addi	sp,sp,32
    80005ef0:	8082                	ret

0000000080005ef2 <sys_link>:
{
    80005ef2:	7169                	addi	sp,sp,-304
    80005ef4:	f606                	sd	ra,296(sp)
    80005ef6:	f222                	sd	s0,288(sp)
    80005ef8:	ee26                	sd	s1,280(sp)
    80005efa:	ea4a                	sd	s2,272(sp)
    80005efc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005efe:	08000613          	li	a2,128
    80005f02:	ed040593          	addi	a1,s0,-304
    80005f06:	4501                	li	a0,0
    80005f08:	ffffd097          	auipc	ra,0xffffd
    80005f0c:	6bc080e7          	jalr	1724(ra) # 800035c4 <argstr>
    return -1;
    80005f10:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f12:	10054e63          	bltz	a0,8000602e <sys_link+0x13c>
    80005f16:	08000613          	li	a2,128
    80005f1a:	f5040593          	addi	a1,s0,-176
    80005f1e:	4505                	li	a0,1
    80005f20:	ffffd097          	auipc	ra,0xffffd
    80005f24:	6a4080e7          	jalr	1700(ra) # 800035c4 <argstr>
    return -1;
    80005f28:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f2a:	10054263          	bltz	a0,8000602e <sys_link+0x13c>
  begin_op();
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	cf4080e7          	jalr	-780(ra) # 80004c22 <begin_op>
  if((ip = namei(old)) == 0){
    80005f36:	ed040513          	addi	a0,s0,-304
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	ac8080e7          	jalr	-1336(ra) # 80004a02 <namei>
    80005f42:	84aa                	mv	s1,a0
    80005f44:	c551                	beqz	a0,80005fd0 <sys_link+0xde>
  ilock(ip);
    80005f46:	ffffe097          	auipc	ra,0xffffe
    80005f4a:	310080e7          	jalr	784(ra) # 80004256 <ilock>
  if(ip->type == T_DIR){
    80005f4e:	04449703          	lh	a4,68(s1)
    80005f52:	4785                	li	a5,1
    80005f54:	08f70463          	beq	a4,a5,80005fdc <sys_link+0xea>
  ip->nlink++;
    80005f58:	04a4d783          	lhu	a5,74(s1)
    80005f5c:	2785                	addiw	a5,a5,1
    80005f5e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f62:	8526                	mv	a0,s1
    80005f64:	ffffe097          	auipc	ra,0xffffe
    80005f68:	226080e7          	jalr	550(ra) # 8000418a <iupdate>
  iunlock(ip);
    80005f6c:	8526                	mv	a0,s1
    80005f6e:	ffffe097          	auipc	ra,0xffffe
    80005f72:	3aa080e7          	jalr	938(ra) # 80004318 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005f76:	fd040593          	addi	a1,s0,-48
    80005f7a:	f5040513          	addi	a0,s0,-176
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	aa2080e7          	jalr	-1374(ra) # 80004a20 <nameiparent>
    80005f86:	892a                	mv	s2,a0
    80005f88:	c935                	beqz	a0,80005ffc <sys_link+0x10a>
  ilock(dp);
    80005f8a:	ffffe097          	auipc	ra,0xffffe
    80005f8e:	2cc080e7          	jalr	716(ra) # 80004256 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005f92:	00092703          	lw	a4,0(s2)
    80005f96:	409c                	lw	a5,0(s1)
    80005f98:	04f71d63          	bne	a4,a5,80005ff2 <sys_link+0x100>
    80005f9c:	40d0                	lw	a2,4(s1)
    80005f9e:	fd040593          	addi	a1,s0,-48
    80005fa2:	854a                	mv	a0,s2
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	9ac080e7          	jalr	-1620(ra) # 80004950 <dirlink>
    80005fac:	04054363          	bltz	a0,80005ff2 <sys_link+0x100>
  iunlockput(dp);
    80005fb0:	854a                	mv	a0,s2
    80005fb2:	ffffe097          	auipc	ra,0xffffe
    80005fb6:	506080e7          	jalr	1286(ra) # 800044b8 <iunlockput>
  iput(ip);
    80005fba:	8526                	mv	a0,s1
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	454080e7          	jalr	1108(ra) # 80004410 <iput>
  end_op();
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	cdc080e7          	jalr	-804(ra) # 80004ca0 <end_op>
  return 0;
    80005fcc:	4781                	li	a5,0
    80005fce:	a085                	j	8000602e <sys_link+0x13c>
    end_op();
    80005fd0:	fffff097          	auipc	ra,0xfffff
    80005fd4:	cd0080e7          	jalr	-816(ra) # 80004ca0 <end_op>
    return -1;
    80005fd8:	57fd                	li	a5,-1
    80005fda:	a891                	j	8000602e <sys_link+0x13c>
    iunlockput(ip);
    80005fdc:	8526                	mv	a0,s1
    80005fde:	ffffe097          	auipc	ra,0xffffe
    80005fe2:	4da080e7          	jalr	1242(ra) # 800044b8 <iunlockput>
    end_op();
    80005fe6:	fffff097          	auipc	ra,0xfffff
    80005fea:	cba080e7          	jalr	-838(ra) # 80004ca0 <end_op>
    return -1;
    80005fee:	57fd                	li	a5,-1
    80005ff0:	a83d                	j	8000602e <sys_link+0x13c>
    iunlockput(dp);
    80005ff2:	854a                	mv	a0,s2
    80005ff4:	ffffe097          	auipc	ra,0xffffe
    80005ff8:	4c4080e7          	jalr	1220(ra) # 800044b8 <iunlockput>
  ilock(ip);
    80005ffc:	8526                	mv	a0,s1
    80005ffe:	ffffe097          	auipc	ra,0xffffe
    80006002:	258080e7          	jalr	600(ra) # 80004256 <ilock>
  ip->nlink--;
    80006006:	04a4d783          	lhu	a5,74(s1)
    8000600a:	37fd                	addiw	a5,a5,-1
    8000600c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006010:	8526                	mv	a0,s1
    80006012:	ffffe097          	auipc	ra,0xffffe
    80006016:	178080e7          	jalr	376(ra) # 8000418a <iupdate>
  iunlockput(ip);
    8000601a:	8526                	mv	a0,s1
    8000601c:	ffffe097          	auipc	ra,0xffffe
    80006020:	49c080e7          	jalr	1180(ra) # 800044b8 <iunlockput>
  end_op();
    80006024:	fffff097          	auipc	ra,0xfffff
    80006028:	c7c080e7          	jalr	-900(ra) # 80004ca0 <end_op>
  return -1;
    8000602c:	57fd                	li	a5,-1
}
    8000602e:	853e                	mv	a0,a5
    80006030:	70b2                	ld	ra,296(sp)
    80006032:	7412                	ld	s0,288(sp)
    80006034:	64f2                	ld	s1,280(sp)
    80006036:	6952                	ld	s2,272(sp)
    80006038:	6155                	addi	sp,sp,304
    8000603a:	8082                	ret

000000008000603c <sys_unlink>:
{
    8000603c:	7151                	addi	sp,sp,-240
    8000603e:	f586                	sd	ra,232(sp)
    80006040:	f1a2                	sd	s0,224(sp)
    80006042:	eda6                	sd	s1,216(sp)
    80006044:	e9ca                	sd	s2,208(sp)
    80006046:	e5ce                	sd	s3,200(sp)
    80006048:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000604a:	08000613          	li	a2,128
    8000604e:	f3040593          	addi	a1,s0,-208
    80006052:	4501                	li	a0,0
    80006054:	ffffd097          	auipc	ra,0xffffd
    80006058:	570080e7          	jalr	1392(ra) # 800035c4 <argstr>
    8000605c:	18054163          	bltz	a0,800061de <sys_unlink+0x1a2>
  begin_op();
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	bc2080e7          	jalr	-1086(ra) # 80004c22 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006068:	fb040593          	addi	a1,s0,-80
    8000606c:	f3040513          	addi	a0,s0,-208
    80006070:	fffff097          	auipc	ra,0xfffff
    80006074:	9b0080e7          	jalr	-1616(ra) # 80004a20 <nameiparent>
    80006078:	84aa                	mv	s1,a0
    8000607a:	c979                	beqz	a0,80006150 <sys_unlink+0x114>
  ilock(dp);
    8000607c:	ffffe097          	auipc	ra,0xffffe
    80006080:	1da080e7          	jalr	474(ra) # 80004256 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006084:	00002597          	auipc	a1,0x2
    80006088:	70c58593          	addi	a1,a1,1804 # 80008790 <syscalls+0x2c8>
    8000608c:	fb040513          	addi	a0,s0,-80
    80006090:	ffffe097          	auipc	ra,0xffffe
    80006094:	690080e7          	jalr	1680(ra) # 80004720 <namecmp>
    80006098:	14050a63          	beqz	a0,800061ec <sys_unlink+0x1b0>
    8000609c:	00002597          	auipc	a1,0x2
    800060a0:	6fc58593          	addi	a1,a1,1788 # 80008798 <syscalls+0x2d0>
    800060a4:	fb040513          	addi	a0,s0,-80
    800060a8:	ffffe097          	auipc	ra,0xffffe
    800060ac:	678080e7          	jalr	1656(ra) # 80004720 <namecmp>
    800060b0:	12050e63          	beqz	a0,800061ec <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800060b4:	f2c40613          	addi	a2,s0,-212
    800060b8:	fb040593          	addi	a1,s0,-80
    800060bc:	8526                	mv	a0,s1
    800060be:	ffffe097          	auipc	ra,0xffffe
    800060c2:	67c080e7          	jalr	1660(ra) # 8000473a <dirlookup>
    800060c6:	892a                	mv	s2,a0
    800060c8:	12050263          	beqz	a0,800061ec <sys_unlink+0x1b0>
  ilock(ip);
    800060cc:	ffffe097          	auipc	ra,0xffffe
    800060d0:	18a080e7          	jalr	394(ra) # 80004256 <ilock>
  if(ip->nlink < 1)
    800060d4:	04a91783          	lh	a5,74(s2)
    800060d8:	08f05263          	blez	a5,8000615c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800060dc:	04491703          	lh	a4,68(s2)
    800060e0:	4785                	li	a5,1
    800060e2:	08f70563          	beq	a4,a5,8000616c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800060e6:	4641                	li	a2,16
    800060e8:	4581                	li	a1,0
    800060ea:	fc040513          	addi	a0,s0,-64
    800060ee:	ffffb097          	auipc	ra,0xffffb
    800060f2:	be4080e7          	jalr	-1052(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060f6:	4741                	li	a4,16
    800060f8:	f2c42683          	lw	a3,-212(s0)
    800060fc:	fc040613          	addi	a2,s0,-64
    80006100:	4581                	li	a1,0
    80006102:	8526                	mv	a0,s1
    80006104:	ffffe097          	auipc	ra,0xffffe
    80006108:	4fe080e7          	jalr	1278(ra) # 80004602 <writei>
    8000610c:	47c1                	li	a5,16
    8000610e:	0af51563          	bne	a0,a5,800061b8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006112:	04491703          	lh	a4,68(s2)
    80006116:	4785                	li	a5,1
    80006118:	0af70863          	beq	a4,a5,800061c8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000611c:	8526                	mv	a0,s1
    8000611e:	ffffe097          	auipc	ra,0xffffe
    80006122:	39a080e7          	jalr	922(ra) # 800044b8 <iunlockput>
  ip->nlink--;
    80006126:	04a95783          	lhu	a5,74(s2)
    8000612a:	37fd                	addiw	a5,a5,-1
    8000612c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006130:	854a                	mv	a0,s2
    80006132:	ffffe097          	auipc	ra,0xffffe
    80006136:	058080e7          	jalr	88(ra) # 8000418a <iupdate>
  iunlockput(ip);
    8000613a:	854a                	mv	a0,s2
    8000613c:	ffffe097          	auipc	ra,0xffffe
    80006140:	37c080e7          	jalr	892(ra) # 800044b8 <iunlockput>
  end_op();
    80006144:	fffff097          	auipc	ra,0xfffff
    80006148:	b5c080e7          	jalr	-1188(ra) # 80004ca0 <end_op>
  return 0;
    8000614c:	4501                	li	a0,0
    8000614e:	a84d                	j	80006200 <sys_unlink+0x1c4>
    end_op();
    80006150:	fffff097          	auipc	ra,0xfffff
    80006154:	b50080e7          	jalr	-1200(ra) # 80004ca0 <end_op>
    return -1;
    80006158:	557d                	li	a0,-1
    8000615a:	a05d                	j	80006200 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000615c:	00002517          	auipc	a0,0x2
    80006160:	64450513          	addi	a0,a0,1604 # 800087a0 <syscalls+0x2d8>
    80006164:	ffffa097          	auipc	ra,0xffffa
    80006168:	3dc080e7          	jalr	988(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000616c:	04c92703          	lw	a4,76(s2)
    80006170:	02000793          	li	a5,32
    80006174:	f6e7f9e3          	bgeu	a5,a4,800060e6 <sys_unlink+0xaa>
    80006178:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000617c:	4741                	li	a4,16
    8000617e:	86ce                	mv	a3,s3
    80006180:	f1840613          	addi	a2,s0,-232
    80006184:	4581                	li	a1,0
    80006186:	854a                	mv	a0,s2
    80006188:	ffffe097          	auipc	ra,0xffffe
    8000618c:	382080e7          	jalr	898(ra) # 8000450a <readi>
    80006190:	47c1                	li	a5,16
    80006192:	00f51b63          	bne	a0,a5,800061a8 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006196:	f1845783          	lhu	a5,-232(s0)
    8000619a:	e7a1                	bnez	a5,800061e2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000619c:	29c1                	addiw	s3,s3,16
    8000619e:	04c92783          	lw	a5,76(s2)
    800061a2:	fcf9ede3          	bltu	s3,a5,8000617c <sys_unlink+0x140>
    800061a6:	b781                	j	800060e6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	61050513          	addi	a0,a0,1552 # 800087b8 <syscalls+0x2f0>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	390080e7          	jalr	912(ra) # 80000540 <panic>
    panic("unlink: writei");
    800061b8:	00002517          	auipc	a0,0x2
    800061bc:	61850513          	addi	a0,a0,1560 # 800087d0 <syscalls+0x308>
    800061c0:	ffffa097          	auipc	ra,0xffffa
    800061c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
    dp->nlink--;
    800061c8:	04a4d783          	lhu	a5,74(s1)
    800061cc:	37fd                	addiw	a5,a5,-1
    800061ce:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800061d2:	8526                	mv	a0,s1
    800061d4:	ffffe097          	auipc	ra,0xffffe
    800061d8:	fb6080e7          	jalr	-74(ra) # 8000418a <iupdate>
    800061dc:	b781                	j	8000611c <sys_unlink+0xe0>
    return -1;
    800061de:	557d                	li	a0,-1
    800061e0:	a005                	j	80006200 <sys_unlink+0x1c4>
    iunlockput(ip);
    800061e2:	854a                	mv	a0,s2
    800061e4:	ffffe097          	auipc	ra,0xffffe
    800061e8:	2d4080e7          	jalr	724(ra) # 800044b8 <iunlockput>
  iunlockput(dp);
    800061ec:	8526                	mv	a0,s1
    800061ee:	ffffe097          	auipc	ra,0xffffe
    800061f2:	2ca080e7          	jalr	714(ra) # 800044b8 <iunlockput>
  end_op();
    800061f6:	fffff097          	auipc	ra,0xfffff
    800061fa:	aaa080e7          	jalr	-1366(ra) # 80004ca0 <end_op>
  return -1;
    800061fe:	557d                	li	a0,-1
}
    80006200:	70ae                	ld	ra,232(sp)
    80006202:	740e                	ld	s0,224(sp)
    80006204:	64ee                	ld	s1,216(sp)
    80006206:	694e                	ld	s2,208(sp)
    80006208:	69ae                	ld	s3,200(sp)
    8000620a:	616d                	addi	sp,sp,240
    8000620c:	8082                	ret

000000008000620e <sys_open>:

uint64
sys_open(void)
{
    8000620e:	7131                	addi	sp,sp,-192
    80006210:	fd06                	sd	ra,184(sp)
    80006212:	f922                	sd	s0,176(sp)
    80006214:	f526                	sd	s1,168(sp)
    80006216:	f14a                	sd	s2,160(sp)
    80006218:	ed4e                	sd	s3,152(sp)
    8000621a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000621c:	f4c40593          	addi	a1,s0,-180
    80006220:	4505                	li	a0,1
    80006222:	ffffd097          	auipc	ra,0xffffd
    80006226:	35e080e7          	jalr	862(ra) # 80003580 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000622a:	08000613          	li	a2,128
    8000622e:	f5040593          	addi	a1,s0,-176
    80006232:	4501                	li	a0,0
    80006234:	ffffd097          	auipc	ra,0xffffd
    80006238:	390080e7          	jalr	912(ra) # 800035c4 <argstr>
    8000623c:	87aa                	mv	a5,a0
    return -1;
    8000623e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006240:	0a07c963          	bltz	a5,800062f2 <sys_open+0xe4>

  begin_op();
    80006244:	fffff097          	auipc	ra,0xfffff
    80006248:	9de080e7          	jalr	-1570(ra) # 80004c22 <begin_op>

  if(omode & O_CREATE){
    8000624c:	f4c42783          	lw	a5,-180(s0)
    80006250:	2007f793          	andi	a5,a5,512
    80006254:	cfc5                	beqz	a5,8000630c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006256:	4681                	li	a3,0
    80006258:	4601                	li	a2,0
    8000625a:	4589                	li	a1,2
    8000625c:	f5040513          	addi	a0,s0,-176
    80006260:	00000097          	auipc	ra,0x0
    80006264:	964080e7          	jalr	-1692(ra) # 80005bc4 <create>
    80006268:	84aa                	mv	s1,a0
    if(ip == 0){
    8000626a:	c959                	beqz	a0,80006300 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000626c:	04449703          	lh	a4,68(s1)
    80006270:	478d                	li	a5,3
    80006272:	00f71763          	bne	a4,a5,80006280 <sys_open+0x72>
    80006276:	0464d703          	lhu	a4,70(s1)
    8000627a:	47a5                	li	a5,9
    8000627c:	0ce7ed63          	bltu	a5,a4,80006356 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006280:	fffff097          	auipc	ra,0xfffff
    80006284:	dae080e7          	jalr	-594(ra) # 8000502e <filealloc>
    80006288:	89aa                	mv	s3,a0
    8000628a:	10050363          	beqz	a0,80006390 <sys_open+0x182>
    8000628e:	00000097          	auipc	ra,0x0
    80006292:	8f4080e7          	jalr	-1804(ra) # 80005b82 <fdalloc>
    80006296:	892a                	mv	s2,a0
    80006298:	0e054763          	bltz	a0,80006386 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000629c:	04449703          	lh	a4,68(s1)
    800062a0:	478d                	li	a5,3
    800062a2:	0cf70563          	beq	a4,a5,8000636c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800062a6:	4789                	li	a5,2
    800062a8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800062ac:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800062b0:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800062b4:	f4c42783          	lw	a5,-180(s0)
    800062b8:	0017c713          	xori	a4,a5,1
    800062bc:	8b05                	andi	a4,a4,1
    800062be:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800062c2:	0037f713          	andi	a4,a5,3
    800062c6:	00e03733          	snez	a4,a4
    800062ca:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800062ce:	4007f793          	andi	a5,a5,1024
    800062d2:	c791                	beqz	a5,800062de <sys_open+0xd0>
    800062d4:	04449703          	lh	a4,68(s1)
    800062d8:	4789                	li	a5,2
    800062da:	0af70063          	beq	a4,a5,8000637a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800062de:	8526                	mv	a0,s1
    800062e0:	ffffe097          	auipc	ra,0xffffe
    800062e4:	038080e7          	jalr	56(ra) # 80004318 <iunlock>
  end_op();
    800062e8:	fffff097          	auipc	ra,0xfffff
    800062ec:	9b8080e7          	jalr	-1608(ra) # 80004ca0 <end_op>

  return fd;
    800062f0:	854a                	mv	a0,s2
}
    800062f2:	70ea                	ld	ra,184(sp)
    800062f4:	744a                	ld	s0,176(sp)
    800062f6:	74aa                	ld	s1,168(sp)
    800062f8:	790a                	ld	s2,160(sp)
    800062fa:	69ea                	ld	s3,152(sp)
    800062fc:	6129                	addi	sp,sp,192
    800062fe:	8082                	ret
      end_op();
    80006300:	fffff097          	auipc	ra,0xfffff
    80006304:	9a0080e7          	jalr	-1632(ra) # 80004ca0 <end_op>
      return -1;
    80006308:	557d                	li	a0,-1
    8000630a:	b7e5                	j	800062f2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000630c:	f5040513          	addi	a0,s0,-176
    80006310:	ffffe097          	auipc	ra,0xffffe
    80006314:	6f2080e7          	jalr	1778(ra) # 80004a02 <namei>
    80006318:	84aa                	mv	s1,a0
    8000631a:	c905                	beqz	a0,8000634a <sys_open+0x13c>
    ilock(ip);
    8000631c:	ffffe097          	auipc	ra,0xffffe
    80006320:	f3a080e7          	jalr	-198(ra) # 80004256 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006324:	04449703          	lh	a4,68(s1)
    80006328:	4785                	li	a5,1
    8000632a:	f4f711e3          	bne	a4,a5,8000626c <sys_open+0x5e>
    8000632e:	f4c42783          	lw	a5,-180(s0)
    80006332:	d7b9                	beqz	a5,80006280 <sys_open+0x72>
      iunlockput(ip);
    80006334:	8526                	mv	a0,s1
    80006336:	ffffe097          	auipc	ra,0xffffe
    8000633a:	182080e7          	jalr	386(ra) # 800044b8 <iunlockput>
      end_op();
    8000633e:	fffff097          	auipc	ra,0xfffff
    80006342:	962080e7          	jalr	-1694(ra) # 80004ca0 <end_op>
      return -1;
    80006346:	557d                	li	a0,-1
    80006348:	b76d                	j	800062f2 <sys_open+0xe4>
      end_op();
    8000634a:	fffff097          	auipc	ra,0xfffff
    8000634e:	956080e7          	jalr	-1706(ra) # 80004ca0 <end_op>
      return -1;
    80006352:	557d                	li	a0,-1
    80006354:	bf79                	j	800062f2 <sys_open+0xe4>
    iunlockput(ip);
    80006356:	8526                	mv	a0,s1
    80006358:	ffffe097          	auipc	ra,0xffffe
    8000635c:	160080e7          	jalr	352(ra) # 800044b8 <iunlockput>
    end_op();
    80006360:	fffff097          	auipc	ra,0xfffff
    80006364:	940080e7          	jalr	-1728(ra) # 80004ca0 <end_op>
    return -1;
    80006368:	557d                	li	a0,-1
    8000636a:	b761                	j	800062f2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000636c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006370:	04649783          	lh	a5,70(s1)
    80006374:	02f99223          	sh	a5,36(s3)
    80006378:	bf25                	j	800062b0 <sys_open+0xa2>
    itrunc(ip);
    8000637a:	8526                	mv	a0,s1
    8000637c:	ffffe097          	auipc	ra,0xffffe
    80006380:	fe8080e7          	jalr	-24(ra) # 80004364 <itrunc>
    80006384:	bfa9                	j	800062de <sys_open+0xd0>
      fileclose(f);
    80006386:	854e                	mv	a0,s3
    80006388:	fffff097          	auipc	ra,0xfffff
    8000638c:	d62080e7          	jalr	-670(ra) # 800050ea <fileclose>
    iunlockput(ip);
    80006390:	8526                	mv	a0,s1
    80006392:	ffffe097          	auipc	ra,0xffffe
    80006396:	126080e7          	jalr	294(ra) # 800044b8 <iunlockput>
    end_op();
    8000639a:	fffff097          	auipc	ra,0xfffff
    8000639e:	906080e7          	jalr	-1786(ra) # 80004ca0 <end_op>
    return -1;
    800063a2:	557d                	li	a0,-1
    800063a4:	b7b9                	j	800062f2 <sys_open+0xe4>

00000000800063a6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800063a6:	7175                	addi	sp,sp,-144
    800063a8:	e506                	sd	ra,136(sp)
    800063aa:	e122                	sd	s0,128(sp)
    800063ac:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800063ae:	fffff097          	auipc	ra,0xfffff
    800063b2:	874080e7          	jalr	-1932(ra) # 80004c22 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800063b6:	08000613          	li	a2,128
    800063ba:	f7040593          	addi	a1,s0,-144
    800063be:	4501                	li	a0,0
    800063c0:	ffffd097          	auipc	ra,0xffffd
    800063c4:	204080e7          	jalr	516(ra) # 800035c4 <argstr>
    800063c8:	02054963          	bltz	a0,800063fa <sys_mkdir+0x54>
    800063cc:	4681                	li	a3,0
    800063ce:	4601                	li	a2,0
    800063d0:	4585                	li	a1,1
    800063d2:	f7040513          	addi	a0,s0,-144
    800063d6:	fffff097          	auipc	ra,0xfffff
    800063da:	7ee080e7          	jalr	2030(ra) # 80005bc4 <create>
    800063de:	cd11                	beqz	a0,800063fa <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800063e0:	ffffe097          	auipc	ra,0xffffe
    800063e4:	0d8080e7          	jalr	216(ra) # 800044b8 <iunlockput>
  end_op();
    800063e8:	fffff097          	auipc	ra,0xfffff
    800063ec:	8b8080e7          	jalr	-1864(ra) # 80004ca0 <end_op>
  return 0;
    800063f0:	4501                	li	a0,0
}
    800063f2:	60aa                	ld	ra,136(sp)
    800063f4:	640a                	ld	s0,128(sp)
    800063f6:	6149                	addi	sp,sp,144
    800063f8:	8082                	ret
    end_op();
    800063fa:	fffff097          	auipc	ra,0xfffff
    800063fe:	8a6080e7          	jalr	-1882(ra) # 80004ca0 <end_op>
    return -1;
    80006402:	557d                	li	a0,-1
    80006404:	b7fd                	j	800063f2 <sys_mkdir+0x4c>

0000000080006406 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006406:	7135                	addi	sp,sp,-160
    80006408:	ed06                	sd	ra,152(sp)
    8000640a:	e922                	sd	s0,144(sp)
    8000640c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000640e:	fffff097          	auipc	ra,0xfffff
    80006412:	814080e7          	jalr	-2028(ra) # 80004c22 <begin_op>
  argint(1, &major);
    80006416:	f6c40593          	addi	a1,s0,-148
    8000641a:	4505                	li	a0,1
    8000641c:	ffffd097          	auipc	ra,0xffffd
    80006420:	164080e7          	jalr	356(ra) # 80003580 <argint>
  argint(2, &minor);
    80006424:	f6840593          	addi	a1,s0,-152
    80006428:	4509                	li	a0,2
    8000642a:	ffffd097          	auipc	ra,0xffffd
    8000642e:	156080e7          	jalr	342(ra) # 80003580 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006432:	08000613          	li	a2,128
    80006436:	f7040593          	addi	a1,s0,-144
    8000643a:	4501                	li	a0,0
    8000643c:	ffffd097          	auipc	ra,0xffffd
    80006440:	188080e7          	jalr	392(ra) # 800035c4 <argstr>
    80006444:	02054b63          	bltz	a0,8000647a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006448:	f6841683          	lh	a3,-152(s0)
    8000644c:	f6c41603          	lh	a2,-148(s0)
    80006450:	458d                	li	a1,3
    80006452:	f7040513          	addi	a0,s0,-144
    80006456:	fffff097          	auipc	ra,0xfffff
    8000645a:	76e080e7          	jalr	1902(ra) # 80005bc4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000645e:	cd11                	beqz	a0,8000647a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006460:	ffffe097          	auipc	ra,0xffffe
    80006464:	058080e7          	jalr	88(ra) # 800044b8 <iunlockput>
  end_op();
    80006468:	fffff097          	auipc	ra,0xfffff
    8000646c:	838080e7          	jalr	-1992(ra) # 80004ca0 <end_op>
  return 0;
    80006470:	4501                	li	a0,0
}
    80006472:	60ea                	ld	ra,152(sp)
    80006474:	644a                	ld	s0,144(sp)
    80006476:	610d                	addi	sp,sp,160
    80006478:	8082                	ret
    end_op();
    8000647a:	fffff097          	auipc	ra,0xfffff
    8000647e:	826080e7          	jalr	-2010(ra) # 80004ca0 <end_op>
    return -1;
    80006482:	557d                	li	a0,-1
    80006484:	b7fd                	j	80006472 <sys_mknod+0x6c>

0000000080006486 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006486:	7135                	addi	sp,sp,-160
    80006488:	ed06                	sd	ra,152(sp)
    8000648a:	e922                	sd	s0,144(sp)
    8000648c:	e526                	sd	s1,136(sp)
    8000648e:	e14a                	sd	s2,128(sp)
    80006490:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006492:	ffffb097          	auipc	ra,0xffffb
    80006496:	73e080e7          	jalr	1854(ra) # 80001bd0 <myproc>
    8000649a:	892a                	mv	s2,a0
  
  begin_op();
    8000649c:	ffffe097          	auipc	ra,0xffffe
    800064a0:	786080e7          	jalr	1926(ra) # 80004c22 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800064a4:	08000613          	li	a2,128
    800064a8:	f6040593          	addi	a1,s0,-160
    800064ac:	4501                	li	a0,0
    800064ae:	ffffd097          	auipc	ra,0xffffd
    800064b2:	116080e7          	jalr	278(ra) # 800035c4 <argstr>
    800064b6:	04054b63          	bltz	a0,8000650c <sys_chdir+0x86>
    800064ba:	f6040513          	addi	a0,s0,-160
    800064be:	ffffe097          	auipc	ra,0xffffe
    800064c2:	544080e7          	jalr	1348(ra) # 80004a02 <namei>
    800064c6:	84aa                	mv	s1,a0
    800064c8:	c131                	beqz	a0,8000650c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800064ca:	ffffe097          	auipc	ra,0xffffe
    800064ce:	d8c080e7          	jalr	-628(ra) # 80004256 <ilock>
  if(ip->type != T_DIR){
    800064d2:	04449703          	lh	a4,68(s1)
    800064d6:	4785                	li	a5,1
    800064d8:	04f71063          	bne	a4,a5,80006518 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800064dc:	8526                	mv	a0,s1
    800064de:	ffffe097          	auipc	ra,0xffffe
    800064e2:	e3a080e7          	jalr	-454(ra) # 80004318 <iunlock>
  iput(p->cwd);
    800064e6:	15093503          	ld	a0,336(s2)
    800064ea:	ffffe097          	auipc	ra,0xffffe
    800064ee:	f26080e7          	jalr	-218(ra) # 80004410 <iput>
  end_op();
    800064f2:	ffffe097          	auipc	ra,0xffffe
    800064f6:	7ae080e7          	jalr	1966(ra) # 80004ca0 <end_op>
  p->cwd = ip;
    800064fa:	14993823          	sd	s1,336(s2)
  return 0;
    800064fe:	4501                	li	a0,0
}
    80006500:	60ea                	ld	ra,152(sp)
    80006502:	644a                	ld	s0,144(sp)
    80006504:	64aa                	ld	s1,136(sp)
    80006506:	690a                	ld	s2,128(sp)
    80006508:	610d                	addi	sp,sp,160
    8000650a:	8082                	ret
    end_op();
    8000650c:	ffffe097          	auipc	ra,0xffffe
    80006510:	794080e7          	jalr	1940(ra) # 80004ca0 <end_op>
    return -1;
    80006514:	557d                	li	a0,-1
    80006516:	b7ed                	j	80006500 <sys_chdir+0x7a>
    iunlockput(ip);
    80006518:	8526                	mv	a0,s1
    8000651a:	ffffe097          	auipc	ra,0xffffe
    8000651e:	f9e080e7          	jalr	-98(ra) # 800044b8 <iunlockput>
    end_op();
    80006522:	ffffe097          	auipc	ra,0xffffe
    80006526:	77e080e7          	jalr	1918(ra) # 80004ca0 <end_op>
    return -1;
    8000652a:	557d                	li	a0,-1
    8000652c:	bfd1                	j	80006500 <sys_chdir+0x7a>

000000008000652e <sys_exec>:

uint64
sys_exec(void)
{
    8000652e:	7145                	addi	sp,sp,-464
    80006530:	e786                	sd	ra,456(sp)
    80006532:	e3a2                	sd	s0,448(sp)
    80006534:	ff26                	sd	s1,440(sp)
    80006536:	fb4a                	sd	s2,432(sp)
    80006538:	f74e                	sd	s3,424(sp)
    8000653a:	f352                	sd	s4,416(sp)
    8000653c:	ef56                	sd	s5,408(sp)
    8000653e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006540:	e3840593          	addi	a1,s0,-456
    80006544:	4505                	li	a0,1
    80006546:	ffffd097          	auipc	ra,0xffffd
    8000654a:	05c080e7          	jalr	92(ra) # 800035a2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000654e:	08000613          	li	a2,128
    80006552:	f4040593          	addi	a1,s0,-192
    80006556:	4501                	li	a0,0
    80006558:	ffffd097          	auipc	ra,0xffffd
    8000655c:	06c080e7          	jalr	108(ra) # 800035c4 <argstr>
    80006560:	87aa                	mv	a5,a0
    return -1;
    80006562:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006564:	0c07c363          	bltz	a5,8000662a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80006568:	10000613          	li	a2,256
    8000656c:	4581                	li	a1,0
    8000656e:	e4040513          	addi	a0,s0,-448
    80006572:	ffffa097          	auipc	ra,0xffffa
    80006576:	760080e7          	jalr	1888(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000657a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000657e:	89a6                	mv	s3,s1
    80006580:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006582:	02000a13          	li	s4,32
    80006586:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000658a:	00391513          	slli	a0,s2,0x3
    8000658e:	e3040593          	addi	a1,s0,-464
    80006592:	e3843783          	ld	a5,-456(s0)
    80006596:	953e                	add	a0,a0,a5
    80006598:	ffffd097          	auipc	ra,0xffffd
    8000659c:	f4a080e7          	jalr	-182(ra) # 800034e2 <fetchaddr>
    800065a0:	02054a63          	bltz	a0,800065d4 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800065a4:	e3043783          	ld	a5,-464(s0)
    800065a8:	c3b9                	beqz	a5,800065ee <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	53c080e7          	jalr	1340(ra) # 80000ae6 <kalloc>
    800065b2:	85aa                	mv	a1,a0
    800065b4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800065b8:	cd11                	beqz	a0,800065d4 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800065ba:	6605                	lui	a2,0x1
    800065bc:	e3043503          	ld	a0,-464(s0)
    800065c0:	ffffd097          	auipc	ra,0xffffd
    800065c4:	f74080e7          	jalr	-140(ra) # 80003534 <fetchstr>
    800065c8:	00054663          	bltz	a0,800065d4 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800065cc:	0905                	addi	s2,s2,1
    800065ce:	09a1                	addi	s3,s3,8
    800065d0:	fb491be3          	bne	s2,s4,80006586 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065d4:	f4040913          	addi	s2,s0,-192
    800065d8:	6088                	ld	a0,0(s1)
    800065da:	c539                	beqz	a0,80006628 <sys_exec+0xfa>
    kfree(argv[i]);
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	40c080e7          	jalr	1036(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065e4:	04a1                	addi	s1,s1,8
    800065e6:	ff2499e3          	bne	s1,s2,800065d8 <sys_exec+0xaa>
  return -1;
    800065ea:	557d                	li	a0,-1
    800065ec:	a83d                	j	8000662a <sys_exec+0xfc>
      argv[i] = 0;
    800065ee:	0a8e                	slli	s5,s5,0x3
    800065f0:	fc0a8793          	addi	a5,s5,-64
    800065f4:	00878ab3          	add	s5,a5,s0
    800065f8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800065fc:	e4040593          	addi	a1,s0,-448
    80006600:	f4040513          	addi	a0,s0,-192
    80006604:	fffff097          	auipc	ra,0xfffff
    80006608:	160080e7          	jalr	352(ra) # 80005764 <exec>
    8000660c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000660e:	f4040993          	addi	s3,s0,-192
    80006612:	6088                	ld	a0,0(s1)
    80006614:	c901                	beqz	a0,80006624 <sys_exec+0xf6>
    kfree(argv[i]);
    80006616:	ffffa097          	auipc	ra,0xffffa
    8000661a:	3d2080e7          	jalr	978(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000661e:	04a1                	addi	s1,s1,8
    80006620:	ff3499e3          	bne	s1,s3,80006612 <sys_exec+0xe4>
  return ret;
    80006624:	854a                	mv	a0,s2
    80006626:	a011                	j	8000662a <sys_exec+0xfc>
  return -1;
    80006628:	557d                	li	a0,-1
}
    8000662a:	60be                	ld	ra,456(sp)
    8000662c:	641e                	ld	s0,448(sp)
    8000662e:	74fa                	ld	s1,440(sp)
    80006630:	795a                	ld	s2,432(sp)
    80006632:	79ba                	ld	s3,424(sp)
    80006634:	7a1a                	ld	s4,416(sp)
    80006636:	6afa                	ld	s5,408(sp)
    80006638:	6179                	addi	sp,sp,464
    8000663a:	8082                	ret

000000008000663c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000663c:	7139                	addi	sp,sp,-64
    8000663e:	fc06                	sd	ra,56(sp)
    80006640:	f822                	sd	s0,48(sp)
    80006642:	f426                	sd	s1,40(sp)
    80006644:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006646:	ffffb097          	auipc	ra,0xffffb
    8000664a:	58a080e7          	jalr	1418(ra) # 80001bd0 <myproc>
    8000664e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006650:	fd840593          	addi	a1,s0,-40
    80006654:	4501                	li	a0,0
    80006656:	ffffd097          	auipc	ra,0xffffd
    8000665a:	f4c080e7          	jalr	-180(ra) # 800035a2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000665e:	fc840593          	addi	a1,s0,-56
    80006662:	fd040513          	addi	a0,s0,-48
    80006666:	fffff097          	auipc	ra,0xfffff
    8000666a:	db4080e7          	jalr	-588(ra) # 8000541a <pipealloc>
    return -1;
    8000666e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006670:	0c054463          	bltz	a0,80006738 <sys_pipe+0xfc>
  fd0 = -1;
    80006674:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006678:	fd043503          	ld	a0,-48(s0)
    8000667c:	fffff097          	auipc	ra,0xfffff
    80006680:	506080e7          	jalr	1286(ra) # 80005b82 <fdalloc>
    80006684:	fca42223          	sw	a0,-60(s0)
    80006688:	08054b63          	bltz	a0,8000671e <sys_pipe+0xe2>
    8000668c:	fc843503          	ld	a0,-56(s0)
    80006690:	fffff097          	auipc	ra,0xfffff
    80006694:	4f2080e7          	jalr	1266(ra) # 80005b82 <fdalloc>
    80006698:	fca42023          	sw	a0,-64(s0)
    8000669c:	06054863          	bltz	a0,8000670c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066a0:	4691                	li	a3,4
    800066a2:	fc440613          	addi	a2,s0,-60
    800066a6:	fd843583          	ld	a1,-40(s0)
    800066aa:	68a8                	ld	a0,80(s1)
    800066ac:	ffffb097          	auipc	ra,0xffffb
    800066b0:	fc0080e7          	jalr	-64(ra) # 8000166c <copyout>
    800066b4:	02054063          	bltz	a0,800066d4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800066b8:	4691                	li	a3,4
    800066ba:	fc040613          	addi	a2,s0,-64
    800066be:	fd843583          	ld	a1,-40(s0)
    800066c2:	0591                	addi	a1,a1,4
    800066c4:	68a8                	ld	a0,80(s1)
    800066c6:	ffffb097          	auipc	ra,0xffffb
    800066ca:	fa6080e7          	jalr	-90(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800066ce:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066d0:	06055463          	bgez	a0,80006738 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800066d4:	fc442783          	lw	a5,-60(s0)
    800066d8:	07e9                	addi	a5,a5,26
    800066da:	078e                	slli	a5,a5,0x3
    800066dc:	97a6                	add	a5,a5,s1
    800066de:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800066e2:	fc042783          	lw	a5,-64(s0)
    800066e6:	07e9                	addi	a5,a5,26
    800066e8:	078e                	slli	a5,a5,0x3
    800066ea:	94be                	add	s1,s1,a5
    800066ec:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800066f0:	fd043503          	ld	a0,-48(s0)
    800066f4:	fffff097          	auipc	ra,0xfffff
    800066f8:	9f6080e7          	jalr	-1546(ra) # 800050ea <fileclose>
    fileclose(wf);
    800066fc:	fc843503          	ld	a0,-56(s0)
    80006700:	fffff097          	auipc	ra,0xfffff
    80006704:	9ea080e7          	jalr	-1558(ra) # 800050ea <fileclose>
    return -1;
    80006708:	57fd                	li	a5,-1
    8000670a:	a03d                	j	80006738 <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000670c:	fc442783          	lw	a5,-60(s0)
    80006710:	0007c763          	bltz	a5,8000671e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006714:	07e9                	addi	a5,a5,26
    80006716:	078e                	slli	a5,a5,0x3
    80006718:	97a6                	add	a5,a5,s1
    8000671a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000671e:	fd043503          	ld	a0,-48(s0)
    80006722:	fffff097          	auipc	ra,0xfffff
    80006726:	9c8080e7          	jalr	-1592(ra) # 800050ea <fileclose>
    fileclose(wf);
    8000672a:	fc843503          	ld	a0,-56(s0)
    8000672e:	fffff097          	auipc	ra,0xfffff
    80006732:	9bc080e7          	jalr	-1604(ra) # 800050ea <fileclose>
    return -1;
    80006736:	57fd                	li	a5,-1
}
    80006738:	853e                	mv	a0,a5
    8000673a:	70e2                	ld	ra,56(sp)
    8000673c:	7442                	ld	s0,48(sp)
    8000673e:	74a2                	ld	s1,40(sp)
    80006740:	6121                	addi	sp,sp,64
    80006742:	8082                	ret
	...

0000000080006750 <kernelvec>:
    80006750:	7111                	addi	sp,sp,-256
    80006752:	e006                	sd	ra,0(sp)
    80006754:	e40a                	sd	sp,8(sp)
    80006756:	e80e                	sd	gp,16(sp)
    80006758:	ec12                	sd	tp,24(sp)
    8000675a:	f016                	sd	t0,32(sp)
    8000675c:	f41a                	sd	t1,40(sp)
    8000675e:	f81e                	sd	t2,48(sp)
    80006760:	fc22                	sd	s0,56(sp)
    80006762:	e0a6                	sd	s1,64(sp)
    80006764:	e4aa                	sd	a0,72(sp)
    80006766:	e8ae                	sd	a1,80(sp)
    80006768:	ecb2                	sd	a2,88(sp)
    8000676a:	f0b6                	sd	a3,96(sp)
    8000676c:	f4ba                	sd	a4,104(sp)
    8000676e:	f8be                	sd	a5,112(sp)
    80006770:	fcc2                	sd	a6,120(sp)
    80006772:	e146                	sd	a7,128(sp)
    80006774:	e54a                	sd	s2,136(sp)
    80006776:	e94e                	sd	s3,144(sp)
    80006778:	ed52                	sd	s4,152(sp)
    8000677a:	f156                	sd	s5,160(sp)
    8000677c:	f55a                	sd	s6,168(sp)
    8000677e:	f95e                	sd	s7,176(sp)
    80006780:	fd62                	sd	s8,184(sp)
    80006782:	e1e6                	sd	s9,192(sp)
    80006784:	e5ea                	sd	s10,200(sp)
    80006786:	e9ee                	sd	s11,208(sp)
    80006788:	edf2                	sd	t3,216(sp)
    8000678a:	f1f6                	sd	t4,224(sp)
    8000678c:	f5fa                	sd	t5,232(sp)
    8000678e:	f9fe                	sd	t6,240(sp)
    80006790:	c1ffc0ef          	jal	ra,800033ae <kerneltrap>
    80006794:	6082                	ld	ra,0(sp)
    80006796:	6122                	ld	sp,8(sp)
    80006798:	61c2                	ld	gp,16(sp)
    8000679a:	7282                	ld	t0,32(sp)
    8000679c:	7322                	ld	t1,40(sp)
    8000679e:	73c2                	ld	t2,48(sp)
    800067a0:	7462                	ld	s0,56(sp)
    800067a2:	6486                	ld	s1,64(sp)
    800067a4:	6526                	ld	a0,72(sp)
    800067a6:	65c6                	ld	a1,80(sp)
    800067a8:	6666                	ld	a2,88(sp)
    800067aa:	7686                	ld	a3,96(sp)
    800067ac:	7726                	ld	a4,104(sp)
    800067ae:	77c6                	ld	a5,112(sp)
    800067b0:	7866                	ld	a6,120(sp)
    800067b2:	688a                	ld	a7,128(sp)
    800067b4:	692a                	ld	s2,136(sp)
    800067b6:	69ca                	ld	s3,144(sp)
    800067b8:	6a6a                	ld	s4,152(sp)
    800067ba:	7a8a                	ld	s5,160(sp)
    800067bc:	7b2a                	ld	s6,168(sp)
    800067be:	7bca                	ld	s7,176(sp)
    800067c0:	7c6a                	ld	s8,184(sp)
    800067c2:	6c8e                	ld	s9,192(sp)
    800067c4:	6d2e                	ld	s10,200(sp)
    800067c6:	6dce                	ld	s11,208(sp)
    800067c8:	6e6e                	ld	t3,216(sp)
    800067ca:	7e8e                	ld	t4,224(sp)
    800067cc:	7f2e                	ld	t5,232(sp)
    800067ce:	7fce                	ld	t6,240(sp)
    800067d0:	6111                	addi	sp,sp,256
    800067d2:	10200073          	sret
    800067d6:	00000013          	nop
    800067da:	00000013          	nop
    800067de:	0001                	nop

00000000800067e0 <timervec>:
    800067e0:	34051573          	csrrw	a0,mscratch,a0
    800067e4:	e10c                	sd	a1,0(a0)
    800067e6:	e510                	sd	a2,8(a0)
    800067e8:	e914                	sd	a3,16(a0)
    800067ea:	6d0c                	ld	a1,24(a0)
    800067ec:	7110                	ld	a2,32(a0)
    800067ee:	6194                	ld	a3,0(a1)
    800067f0:	96b2                	add	a3,a3,a2
    800067f2:	e194                	sd	a3,0(a1)
    800067f4:	4589                	li	a1,2
    800067f6:	14459073          	csrw	sip,a1
    800067fa:	6914                	ld	a3,16(a0)
    800067fc:	6510                	ld	a2,8(a0)
    800067fe:	610c                	ld	a1,0(a0)
    80006800:	34051573          	csrrw	a0,mscratch,a0
    80006804:	30200073          	mret
	...

000000008000680a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000680a:	1141                	addi	sp,sp,-16
    8000680c:	e422                	sd	s0,8(sp)
    8000680e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006810:	0c0007b7          	lui	a5,0xc000
    80006814:	4705                	li	a4,1
    80006816:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006818:	c3d8                	sw	a4,4(a5)
}
    8000681a:	6422                	ld	s0,8(sp)
    8000681c:	0141                	addi	sp,sp,16
    8000681e:	8082                	ret

0000000080006820 <plicinithart>:

void
plicinithart(void)
{
    80006820:	1141                	addi	sp,sp,-16
    80006822:	e406                	sd	ra,8(sp)
    80006824:	e022                	sd	s0,0(sp)
    80006826:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006828:	ffffb097          	auipc	ra,0xffffb
    8000682c:	37c080e7          	jalr	892(ra) # 80001ba4 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006830:	0085171b          	slliw	a4,a0,0x8
    80006834:	0c0027b7          	lui	a5,0xc002
    80006838:	97ba                	add	a5,a5,a4
    8000683a:	40200713          	li	a4,1026
    8000683e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006842:	00d5151b          	slliw	a0,a0,0xd
    80006846:	0c2017b7          	lui	a5,0xc201
    8000684a:	97aa                	add	a5,a5,a0
    8000684c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006850:	60a2                	ld	ra,8(sp)
    80006852:	6402                	ld	s0,0(sp)
    80006854:	0141                	addi	sp,sp,16
    80006856:	8082                	ret

0000000080006858 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006858:	1141                	addi	sp,sp,-16
    8000685a:	e406                	sd	ra,8(sp)
    8000685c:	e022                	sd	s0,0(sp)
    8000685e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006860:	ffffb097          	auipc	ra,0xffffb
    80006864:	344080e7          	jalr	836(ra) # 80001ba4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006868:	00d5151b          	slliw	a0,a0,0xd
    8000686c:	0c2017b7          	lui	a5,0xc201
    80006870:	97aa                	add	a5,a5,a0
  return irq;
}
    80006872:	43c8                	lw	a0,4(a5)
    80006874:	60a2                	ld	ra,8(sp)
    80006876:	6402                	ld	s0,0(sp)
    80006878:	0141                	addi	sp,sp,16
    8000687a:	8082                	ret

000000008000687c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000687c:	1101                	addi	sp,sp,-32
    8000687e:	ec06                	sd	ra,24(sp)
    80006880:	e822                	sd	s0,16(sp)
    80006882:	e426                	sd	s1,8(sp)
    80006884:	1000                	addi	s0,sp,32
    80006886:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006888:	ffffb097          	auipc	ra,0xffffb
    8000688c:	31c080e7          	jalr	796(ra) # 80001ba4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006890:	00d5151b          	slliw	a0,a0,0xd
    80006894:	0c2017b7          	lui	a5,0xc201
    80006898:	97aa                	add	a5,a5,a0
    8000689a:	c3c4                	sw	s1,4(a5)
}
    8000689c:	60e2                	ld	ra,24(sp)
    8000689e:	6442                	ld	s0,16(sp)
    800068a0:	64a2                	ld	s1,8(sp)
    800068a2:	6105                	addi	sp,sp,32
    800068a4:	8082                	ret

00000000800068a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800068a6:	1141                	addi	sp,sp,-16
    800068a8:	e406                	sd	ra,8(sp)
    800068aa:	e022                	sd	s0,0(sp)
    800068ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800068ae:	479d                	li	a5,7
    800068b0:	04a7cc63          	blt	a5,a0,80006908 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800068b4:	0001d797          	auipc	a5,0x1d
    800068b8:	dec78793          	addi	a5,a5,-532 # 800236a0 <disk>
    800068bc:	97aa                	add	a5,a5,a0
    800068be:	0187c783          	lbu	a5,24(a5)
    800068c2:	ebb9                	bnez	a5,80006918 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800068c4:	00451693          	slli	a3,a0,0x4
    800068c8:	0001d797          	auipc	a5,0x1d
    800068cc:	dd878793          	addi	a5,a5,-552 # 800236a0 <disk>
    800068d0:	6398                	ld	a4,0(a5)
    800068d2:	9736                	add	a4,a4,a3
    800068d4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800068d8:	6398                	ld	a4,0(a5)
    800068da:	9736                	add	a4,a4,a3
    800068dc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800068e0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800068e4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800068e8:	97aa                	add	a5,a5,a0
    800068ea:	4705                	li	a4,1
    800068ec:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800068f0:	0001d517          	auipc	a0,0x1d
    800068f4:	dc850513          	addi	a0,a0,-568 # 800236b8 <disk+0x18>
    800068f8:	ffffc097          	auipc	ra,0xffffc
    800068fc:	f9e080e7          	jalr	-98(ra) # 80002896 <wakeup>
}
    80006900:	60a2                	ld	ra,8(sp)
    80006902:	6402                	ld	s0,0(sp)
    80006904:	0141                	addi	sp,sp,16
    80006906:	8082                	ret
    panic("free_desc 1");
    80006908:	00002517          	auipc	a0,0x2
    8000690c:	ed850513          	addi	a0,a0,-296 # 800087e0 <syscalls+0x318>
    80006910:	ffffa097          	auipc	ra,0xffffa
    80006914:	c30080e7          	jalr	-976(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006918:	00002517          	auipc	a0,0x2
    8000691c:	ed850513          	addi	a0,a0,-296 # 800087f0 <syscalls+0x328>
    80006920:	ffffa097          	auipc	ra,0xffffa
    80006924:	c20080e7          	jalr	-992(ra) # 80000540 <panic>

0000000080006928 <virtio_disk_init>:
{
    80006928:	1101                	addi	sp,sp,-32
    8000692a:	ec06                	sd	ra,24(sp)
    8000692c:	e822                	sd	s0,16(sp)
    8000692e:	e426                	sd	s1,8(sp)
    80006930:	e04a                	sd	s2,0(sp)
    80006932:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006934:	00002597          	auipc	a1,0x2
    80006938:	ecc58593          	addi	a1,a1,-308 # 80008800 <syscalls+0x338>
    8000693c:	0001d517          	auipc	a0,0x1d
    80006940:	e8c50513          	addi	a0,a0,-372 # 800237c8 <disk+0x128>
    80006944:	ffffa097          	auipc	ra,0xffffa
    80006948:	202080e7          	jalr	514(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000694c:	100017b7          	lui	a5,0x10001
    80006950:	4398                	lw	a4,0(a5)
    80006952:	2701                	sext.w	a4,a4
    80006954:	747277b7          	lui	a5,0x74727
    80006958:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000695c:	14f71b63          	bne	a4,a5,80006ab2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006960:	100017b7          	lui	a5,0x10001
    80006964:	43dc                	lw	a5,4(a5)
    80006966:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006968:	4709                	li	a4,2
    8000696a:	14e79463          	bne	a5,a4,80006ab2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000696e:	100017b7          	lui	a5,0x10001
    80006972:	479c                	lw	a5,8(a5)
    80006974:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006976:	12e79e63          	bne	a5,a4,80006ab2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000697a:	100017b7          	lui	a5,0x10001
    8000697e:	47d8                	lw	a4,12(a5)
    80006980:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006982:	554d47b7          	lui	a5,0x554d4
    80006986:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000698a:	12f71463          	bne	a4,a5,80006ab2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000698e:	100017b7          	lui	a5,0x10001
    80006992:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006996:	4705                	li	a4,1
    80006998:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000699a:	470d                	li	a4,3
    8000699c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000699e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800069a0:	c7ffe6b7          	lui	a3,0xc7ffe
    800069a4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdaf7f>
    800069a8:	8f75                	and	a4,a4,a3
    800069aa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069ac:	472d                	li	a4,11
    800069ae:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800069b0:	5bbc                	lw	a5,112(a5)
    800069b2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800069b6:	8ba1                	andi	a5,a5,8
    800069b8:	10078563          	beqz	a5,80006ac2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800069bc:	100017b7          	lui	a5,0x10001
    800069c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800069c4:	43fc                	lw	a5,68(a5)
    800069c6:	2781                	sext.w	a5,a5
    800069c8:	10079563          	bnez	a5,80006ad2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800069cc:	100017b7          	lui	a5,0x10001
    800069d0:	5bdc                	lw	a5,52(a5)
    800069d2:	2781                	sext.w	a5,a5
  if(max == 0)
    800069d4:	10078763          	beqz	a5,80006ae2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800069d8:	471d                	li	a4,7
    800069da:	10f77c63          	bgeu	a4,a5,80006af2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800069de:	ffffa097          	auipc	ra,0xffffa
    800069e2:	108080e7          	jalr	264(ra) # 80000ae6 <kalloc>
    800069e6:	0001d497          	auipc	s1,0x1d
    800069ea:	cba48493          	addi	s1,s1,-838 # 800236a0 <disk>
    800069ee:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800069f0:	ffffa097          	auipc	ra,0xffffa
    800069f4:	0f6080e7          	jalr	246(ra) # 80000ae6 <kalloc>
    800069f8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800069fa:	ffffa097          	auipc	ra,0xffffa
    800069fe:	0ec080e7          	jalr	236(ra) # 80000ae6 <kalloc>
    80006a02:	87aa                	mv	a5,a0
    80006a04:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006a06:	6088                	ld	a0,0(s1)
    80006a08:	cd6d                	beqz	a0,80006b02 <virtio_disk_init+0x1da>
    80006a0a:	0001d717          	auipc	a4,0x1d
    80006a0e:	c9e73703          	ld	a4,-866(a4) # 800236a8 <disk+0x8>
    80006a12:	cb65                	beqz	a4,80006b02 <virtio_disk_init+0x1da>
    80006a14:	c7fd                	beqz	a5,80006b02 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006a16:	6605                	lui	a2,0x1
    80006a18:	4581                	li	a1,0
    80006a1a:	ffffa097          	auipc	ra,0xffffa
    80006a1e:	2b8080e7          	jalr	696(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006a22:	0001d497          	auipc	s1,0x1d
    80006a26:	c7e48493          	addi	s1,s1,-898 # 800236a0 <disk>
    80006a2a:	6605                	lui	a2,0x1
    80006a2c:	4581                	li	a1,0
    80006a2e:	6488                	ld	a0,8(s1)
    80006a30:	ffffa097          	auipc	ra,0xffffa
    80006a34:	2a2080e7          	jalr	674(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006a38:	6605                	lui	a2,0x1
    80006a3a:	4581                	li	a1,0
    80006a3c:	6888                	ld	a0,16(s1)
    80006a3e:	ffffa097          	auipc	ra,0xffffa
    80006a42:	294080e7          	jalr	660(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a46:	100017b7          	lui	a5,0x10001
    80006a4a:	4721                	li	a4,8
    80006a4c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006a4e:	4098                	lw	a4,0(s1)
    80006a50:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006a54:	40d8                	lw	a4,4(s1)
    80006a56:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006a5a:	6498                	ld	a4,8(s1)
    80006a5c:	0007069b          	sext.w	a3,a4
    80006a60:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006a64:	9701                	srai	a4,a4,0x20
    80006a66:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006a6a:	6898                	ld	a4,16(s1)
    80006a6c:	0007069b          	sext.w	a3,a4
    80006a70:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006a74:	9701                	srai	a4,a4,0x20
    80006a76:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006a7a:	4705                	li	a4,1
    80006a7c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006a7e:	00e48c23          	sb	a4,24(s1)
    80006a82:	00e48ca3          	sb	a4,25(s1)
    80006a86:	00e48d23          	sb	a4,26(s1)
    80006a8a:	00e48da3          	sb	a4,27(s1)
    80006a8e:	00e48e23          	sb	a4,28(s1)
    80006a92:	00e48ea3          	sb	a4,29(s1)
    80006a96:	00e48f23          	sb	a4,30(s1)
    80006a9a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006a9e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006aa2:	0727a823          	sw	s2,112(a5)
}
    80006aa6:	60e2                	ld	ra,24(sp)
    80006aa8:	6442                	ld	s0,16(sp)
    80006aaa:	64a2                	ld	s1,8(sp)
    80006aac:	6902                	ld	s2,0(sp)
    80006aae:	6105                	addi	sp,sp,32
    80006ab0:	8082                	ret
    panic("could not find virtio disk");
    80006ab2:	00002517          	auipc	a0,0x2
    80006ab6:	d5e50513          	addi	a0,a0,-674 # 80008810 <syscalls+0x348>
    80006aba:	ffffa097          	auipc	ra,0xffffa
    80006abe:	a86080e7          	jalr	-1402(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006ac2:	00002517          	auipc	a0,0x2
    80006ac6:	d6e50513          	addi	a0,a0,-658 # 80008830 <syscalls+0x368>
    80006aca:	ffffa097          	auipc	ra,0xffffa
    80006ace:	a76080e7          	jalr	-1418(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006ad2:	00002517          	auipc	a0,0x2
    80006ad6:	d7e50513          	addi	a0,a0,-642 # 80008850 <syscalls+0x388>
    80006ada:	ffffa097          	auipc	ra,0xffffa
    80006ade:	a66080e7          	jalr	-1434(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006ae2:	00002517          	auipc	a0,0x2
    80006ae6:	d8e50513          	addi	a0,a0,-626 # 80008870 <syscalls+0x3a8>
    80006aea:	ffffa097          	auipc	ra,0xffffa
    80006aee:	a56080e7          	jalr	-1450(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006af2:	00002517          	auipc	a0,0x2
    80006af6:	d9e50513          	addi	a0,a0,-610 # 80008890 <syscalls+0x3c8>
    80006afa:	ffffa097          	auipc	ra,0xffffa
    80006afe:	a46080e7          	jalr	-1466(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006b02:	00002517          	auipc	a0,0x2
    80006b06:	dae50513          	addi	a0,a0,-594 # 800088b0 <syscalls+0x3e8>
    80006b0a:	ffffa097          	auipc	ra,0xffffa
    80006b0e:	a36080e7          	jalr	-1482(ra) # 80000540 <panic>

0000000080006b12 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006b12:	7119                	addi	sp,sp,-128
    80006b14:	fc86                	sd	ra,120(sp)
    80006b16:	f8a2                	sd	s0,112(sp)
    80006b18:	f4a6                	sd	s1,104(sp)
    80006b1a:	f0ca                	sd	s2,96(sp)
    80006b1c:	ecce                	sd	s3,88(sp)
    80006b1e:	e8d2                	sd	s4,80(sp)
    80006b20:	e4d6                	sd	s5,72(sp)
    80006b22:	e0da                	sd	s6,64(sp)
    80006b24:	fc5e                	sd	s7,56(sp)
    80006b26:	f862                	sd	s8,48(sp)
    80006b28:	f466                	sd	s9,40(sp)
    80006b2a:	f06a                	sd	s10,32(sp)
    80006b2c:	ec6e                	sd	s11,24(sp)
    80006b2e:	0100                	addi	s0,sp,128
    80006b30:	8aaa                	mv	s5,a0
    80006b32:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b34:	00c52d03          	lw	s10,12(a0)
    80006b38:	001d1d1b          	slliw	s10,s10,0x1
    80006b3c:	1d02                	slli	s10,s10,0x20
    80006b3e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006b42:	0001d517          	auipc	a0,0x1d
    80006b46:	c8650513          	addi	a0,a0,-890 # 800237c8 <disk+0x128>
    80006b4a:	ffffa097          	auipc	ra,0xffffa
    80006b4e:	08c080e7          	jalr	140(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006b52:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b54:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006b56:	0001db97          	auipc	s7,0x1d
    80006b5a:	b4ab8b93          	addi	s7,s7,-1206 # 800236a0 <disk>
  for(int i = 0; i < 3; i++){
    80006b5e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b60:	0001dc97          	auipc	s9,0x1d
    80006b64:	c68c8c93          	addi	s9,s9,-920 # 800237c8 <disk+0x128>
    80006b68:	a08d                	j	80006bca <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006b6a:	00fb8733          	add	a4,s7,a5
    80006b6e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006b72:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006b74:	0207c563          	bltz	a5,80006b9e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006b78:	2905                	addiw	s2,s2,1
    80006b7a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80006b7c:	05690c63          	beq	s2,s6,80006bd4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006b80:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006b82:	0001d717          	auipc	a4,0x1d
    80006b86:	b1e70713          	addi	a4,a4,-1250 # 800236a0 <disk>
    80006b8a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006b8c:	01874683          	lbu	a3,24(a4)
    80006b90:	fee9                	bnez	a3,80006b6a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006b92:	2785                	addiw	a5,a5,1
    80006b94:	0705                	addi	a4,a4,1
    80006b96:	fe979be3          	bne	a5,s1,80006b8c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006b9a:	57fd                	li	a5,-1
    80006b9c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006b9e:	01205d63          	blez	s2,80006bb8 <virtio_disk_rw+0xa6>
    80006ba2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006ba4:	000a2503          	lw	a0,0(s4)
    80006ba8:	00000097          	auipc	ra,0x0
    80006bac:	cfe080e7          	jalr	-770(ra) # 800068a6 <free_desc>
      for(int j = 0; j < i; j++)
    80006bb0:	2d85                	addiw	s11,s11,1
    80006bb2:	0a11                	addi	s4,s4,4
    80006bb4:	ff2d98e3          	bne	s11,s2,80006ba4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006bb8:	85e6                	mv	a1,s9
    80006bba:	0001d517          	auipc	a0,0x1d
    80006bbe:	afe50513          	addi	a0,a0,-1282 # 800236b8 <disk+0x18>
    80006bc2:	ffffc097          	auipc	ra,0xffffc
    80006bc6:	c70080e7          	jalr	-912(ra) # 80002832 <sleep>
  for(int i = 0; i < 3; i++){
    80006bca:	f8040a13          	addi	s4,s0,-128
{
    80006bce:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006bd0:	894e                	mv	s2,s3
    80006bd2:	b77d                	j	80006b80 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006bd4:	f8042503          	lw	a0,-128(s0)
    80006bd8:	00a50713          	addi	a4,a0,10
    80006bdc:	0712                	slli	a4,a4,0x4

  if(write)
    80006bde:	0001d797          	auipc	a5,0x1d
    80006be2:	ac278793          	addi	a5,a5,-1342 # 800236a0 <disk>
    80006be6:	00e786b3          	add	a3,a5,a4
    80006bea:	01803633          	snez	a2,s8
    80006bee:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006bf0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006bf4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006bf8:	f6070613          	addi	a2,a4,-160
    80006bfc:	6394                	ld	a3,0(a5)
    80006bfe:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c00:	00870593          	addi	a1,a4,8
    80006c04:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c06:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c08:	0007b803          	ld	a6,0(a5)
    80006c0c:	9642                	add	a2,a2,a6
    80006c0e:	46c1                	li	a3,16
    80006c10:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c12:	4585                	li	a1,1
    80006c14:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006c18:	f8442683          	lw	a3,-124(s0)
    80006c1c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c20:	0692                	slli	a3,a3,0x4
    80006c22:	9836                	add	a6,a6,a3
    80006c24:	058a8613          	addi	a2,s5,88
    80006c28:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80006c2c:	0007b803          	ld	a6,0(a5)
    80006c30:	96c2                	add	a3,a3,a6
    80006c32:	40000613          	li	a2,1024
    80006c36:	c690                	sw	a2,8(a3)
  if(write)
    80006c38:	001c3613          	seqz	a2,s8
    80006c3c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c40:	00166613          	ori	a2,a2,1
    80006c44:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006c48:	f8842603          	lw	a2,-120(s0)
    80006c4c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c50:	00250693          	addi	a3,a0,2
    80006c54:	0692                	slli	a3,a3,0x4
    80006c56:	96be                	add	a3,a3,a5
    80006c58:	58fd                	li	a7,-1
    80006c5a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c5e:	0612                	slli	a2,a2,0x4
    80006c60:	9832                	add	a6,a6,a2
    80006c62:	f9070713          	addi	a4,a4,-112
    80006c66:	973e                	add	a4,a4,a5
    80006c68:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80006c6c:	6398                	ld	a4,0(a5)
    80006c6e:	9732                	add	a4,a4,a2
    80006c70:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c72:	4609                	li	a2,2
    80006c74:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006c78:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006c7c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006c80:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006c84:	6794                	ld	a3,8(a5)
    80006c86:	0026d703          	lhu	a4,2(a3)
    80006c8a:	8b1d                	andi	a4,a4,7
    80006c8c:	0706                	slli	a4,a4,0x1
    80006c8e:	96ba                	add	a3,a3,a4
    80006c90:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006c94:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006c98:	6798                	ld	a4,8(a5)
    80006c9a:	00275783          	lhu	a5,2(a4)
    80006c9e:	2785                	addiw	a5,a5,1
    80006ca0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ca4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006ca8:	100017b7          	lui	a5,0x10001
    80006cac:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006cb0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006cb4:	0001d917          	auipc	s2,0x1d
    80006cb8:	b1490913          	addi	s2,s2,-1260 # 800237c8 <disk+0x128>
  while(b->disk == 1) {
    80006cbc:	4485                	li	s1,1
    80006cbe:	00b79c63          	bne	a5,a1,80006cd6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006cc2:	85ca                	mv	a1,s2
    80006cc4:	8556                	mv	a0,s5
    80006cc6:	ffffc097          	auipc	ra,0xffffc
    80006cca:	b6c080e7          	jalr	-1172(ra) # 80002832 <sleep>
  while(b->disk == 1) {
    80006cce:	004aa783          	lw	a5,4(s5)
    80006cd2:	fe9788e3          	beq	a5,s1,80006cc2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006cd6:	f8042903          	lw	s2,-128(s0)
    80006cda:	00290713          	addi	a4,s2,2
    80006cde:	0712                	slli	a4,a4,0x4
    80006ce0:	0001d797          	auipc	a5,0x1d
    80006ce4:	9c078793          	addi	a5,a5,-1600 # 800236a0 <disk>
    80006ce8:	97ba                	add	a5,a5,a4
    80006cea:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006cee:	0001d997          	auipc	s3,0x1d
    80006cf2:	9b298993          	addi	s3,s3,-1614 # 800236a0 <disk>
    80006cf6:	00491713          	slli	a4,s2,0x4
    80006cfa:	0009b783          	ld	a5,0(s3)
    80006cfe:	97ba                	add	a5,a5,a4
    80006d00:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d04:	854a                	mv	a0,s2
    80006d06:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d0a:	00000097          	auipc	ra,0x0
    80006d0e:	b9c080e7          	jalr	-1124(ra) # 800068a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d12:	8885                	andi	s1,s1,1
    80006d14:	f0ed                	bnez	s1,80006cf6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d16:	0001d517          	auipc	a0,0x1d
    80006d1a:	ab250513          	addi	a0,a0,-1358 # 800237c8 <disk+0x128>
    80006d1e:	ffffa097          	auipc	ra,0xffffa
    80006d22:	f6c080e7          	jalr	-148(ra) # 80000c8a <release>
}
    80006d26:	70e6                	ld	ra,120(sp)
    80006d28:	7446                	ld	s0,112(sp)
    80006d2a:	74a6                	ld	s1,104(sp)
    80006d2c:	7906                	ld	s2,96(sp)
    80006d2e:	69e6                	ld	s3,88(sp)
    80006d30:	6a46                	ld	s4,80(sp)
    80006d32:	6aa6                	ld	s5,72(sp)
    80006d34:	6b06                	ld	s6,64(sp)
    80006d36:	7be2                	ld	s7,56(sp)
    80006d38:	7c42                	ld	s8,48(sp)
    80006d3a:	7ca2                	ld	s9,40(sp)
    80006d3c:	7d02                	ld	s10,32(sp)
    80006d3e:	6de2                	ld	s11,24(sp)
    80006d40:	6109                	addi	sp,sp,128
    80006d42:	8082                	ret

0000000080006d44 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006d44:	1101                	addi	sp,sp,-32
    80006d46:	ec06                	sd	ra,24(sp)
    80006d48:	e822                	sd	s0,16(sp)
    80006d4a:	e426                	sd	s1,8(sp)
    80006d4c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006d4e:	0001d497          	auipc	s1,0x1d
    80006d52:	95248493          	addi	s1,s1,-1710 # 800236a0 <disk>
    80006d56:	0001d517          	auipc	a0,0x1d
    80006d5a:	a7250513          	addi	a0,a0,-1422 # 800237c8 <disk+0x128>
    80006d5e:	ffffa097          	auipc	ra,0xffffa
    80006d62:	e78080e7          	jalr	-392(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006d66:	10001737          	lui	a4,0x10001
    80006d6a:	533c                	lw	a5,96(a4)
    80006d6c:	8b8d                	andi	a5,a5,3
    80006d6e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006d70:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006d74:	689c                	ld	a5,16(s1)
    80006d76:	0204d703          	lhu	a4,32(s1)
    80006d7a:	0027d783          	lhu	a5,2(a5)
    80006d7e:	04f70863          	beq	a4,a5,80006dce <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006d82:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006d86:	6898                	ld	a4,16(s1)
    80006d88:	0204d783          	lhu	a5,32(s1)
    80006d8c:	8b9d                	andi	a5,a5,7
    80006d8e:	078e                	slli	a5,a5,0x3
    80006d90:	97ba                	add	a5,a5,a4
    80006d92:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006d94:	00278713          	addi	a4,a5,2
    80006d98:	0712                	slli	a4,a4,0x4
    80006d9a:	9726                	add	a4,a4,s1
    80006d9c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006da0:	e721                	bnez	a4,80006de8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006da2:	0789                	addi	a5,a5,2
    80006da4:	0792                	slli	a5,a5,0x4
    80006da6:	97a6                	add	a5,a5,s1
    80006da8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006daa:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006dae:	ffffc097          	auipc	ra,0xffffc
    80006db2:	ae8080e7          	jalr	-1304(ra) # 80002896 <wakeup>

    disk.used_idx += 1;
    80006db6:	0204d783          	lhu	a5,32(s1)
    80006dba:	2785                	addiw	a5,a5,1
    80006dbc:	17c2                	slli	a5,a5,0x30
    80006dbe:	93c1                	srli	a5,a5,0x30
    80006dc0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006dc4:	6898                	ld	a4,16(s1)
    80006dc6:	00275703          	lhu	a4,2(a4)
    80006dca:	faf71ce3          	bne	a4,a5,80006d82 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006dce:	0001d517          	auipc	a0,0x1d
    80006dd2:	9fa50513          	addi	a0,a0,-1542 # 800237c8 <disk+0x128>
    80006dd6:	ffffa097          	auipc	ra,0xffffa
    80006dda:	eb4080e7          	jalr	-332(ra) # 80000c8a <release>
}
    80006dde:	60e2                	ld	ra,24(sp)
    80006de0:	6442                	ld	s0,16(sp)
    80006de2:	64a2                	ld	s1,8(sp)
    80006de4:	6105                	addi	sp,sp,32
    80006de6:	8082                	ret
      panic("virtio_disk_intr status");
    80006de8:	00002517          	auipc	a0,0x2
    80006dec:	ae050513          	addi	a0,a0,-1312 # 800088c8 <syscalls+0x400>
    80006df0:	ffff9097          	auipc	ra,0xffff9
    80006df4:	750080e7          	jalr	1872(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
