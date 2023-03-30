
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ce70713          	addi	a4,a4,-1842 # 80008920 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c4c78793          	addi	a5,a5,-948 # 80005cb0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca6f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	488080e7          	jalr	1160(ra) # 800025b4 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	8d450513          	addi	a0,a0,-1836 # 80010a60 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	8c448493          	addi	s1,s1,-1852 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	95290913          	addi	s2,s2,-1710 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	8ee080e7          	jalr	-1810(ra) # 80001ab2 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	232080e7          	jalr	562(ra) # 800023fe <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	f7c080e7          	jalr	-132(ra) # 80002156 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	348080e7          	jalr	840(ra) # 8000255e <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	83650513          	addi	a0,a0,-1994 # 80010a60 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	82050513          	addi	a0,a0,-2016 # 80010a60 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	88f72023          	sw	a5,-1920(a4) # 80010af8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	78e50513          	addi	a0,a0,1934 # 80010a60 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	312080e7          	jalr	786(ra) # 8000260a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	76050513          	addi	a0,a0,1888 # 80010a60 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	73c70713          	addi	a4,a4,1852 # 80010a60 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	71278793          	addi	a5,a5,1810 # 80010a60 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	77c7a783          	lw	a5,1916(a5) # 80010af8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	6d070713          	addi	a4,a4,1744 # 80010a60 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	6c048493          	addi	s1,s1,1728 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	68470713          	addi	a4,a4,1668 # 80010a60 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	70f72723          	sw	a5,1806(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	64878793          	addi	a5,a5,1608 # 80010a60 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	6cc7a023          	sw	a2,1728(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	6b450513          	addi	a0,a0,1716 # 80010af8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	d6e080e7          	jalr	-658(ra) # 800021ba <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	5fa50513          	addi	a0,a0,1530 # 80010a60 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00020797          	auipc	a5,0x20
    80000482:	77a78793          	addi	a5,a5,1914 # 80020bf8 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5c07a823          	sw	zero,1488(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	34f72e23          	sw	a5,860(a4) # 800088e0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	560dad83          	lw	s11,1376(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	50a50513          	addi	a0,a0,1290 # 80010b08 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	3a650513          	addi	a0,a0,934 # 80010b08 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	38a48493          	addi	s1,s1,906 # 80010b08 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	34a50513          	addi	a0,a0,842 # 80010b28 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0d67a783          	lw	a5,214(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	0a273703          	ld	a4,162(a4) # 800088e8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0a27b783          	ld	a5,162(a5) # 800088f0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	2b8a0a13          	addi	s4,s4,696 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	07048493          	addi	s1,s1,112 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	07098993          	addi	s3,s3,112 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	914080e7          	jalr	-1772(ra) # 800021ba <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	24650513          	addi	a0,a0,582 # 80010b28 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fee7a783          	lw	a5,-18(a5) # 800088e0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	ff47b783          	ld	a5,-12(a5) # 800088f0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	fe473703          	ld	a4,-28(a4) # 800088e8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	218a0a13          	addi	s4,s4,536 # 80010b28 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	fd048493          	addi	s1,s1,-48 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	fd090913          	addi	s2,s2,-48 # 800088f0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	826080e7          	jalr	-2010(ra) # 80002156 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	1e248493          	addi	s1,s1,482 # 80010b28 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f8f73b23          	sd	a5,-106(a4) # 800088f0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	15848493          	addi	s1,s1,344 # 80010b28 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	37e78793          	addi	a5,a5,894 # 80021d90 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	12e90913          	addi	s2,s2,302 # 80010b60 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	09250513          	addi	a0,a0,146 # 80010b60 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	2ae50513          	addi	a0,a0,686 # 80021d90 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	05c48493          	addi	s1,s1,92 # 80010b60 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	04450513          	addi	a0,a0,68 # 80010b60 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	01850513          	addi	a0,a0,24 # 80010b60 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	f12080e7          	jalr	-238(ra) # 80001a96 <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	ee0080e7          	jalr	-288(ra) # 80001a96 <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	ed4080e7          	jalr	-300(ra) # 80001a96 <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	ebc080e7          	jalr	-324(ra) # 80001a96 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	e7c080e7          	jalr	-388(ra) # 80001a96 <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	e50080e7          	jalr	-432(ra) # 80001a96 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	bea080e7          	jalr	-1046(ra) # 80001a86 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	a5470713          	addi	a4,a4,-1452 # 800088f8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	bce080e7          	jalr	-1074(ra) # 80001a86 <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	1c4080e7          	jalr	452(ra) # 80001096 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	870080e7          	jalr	-1936(ra) # 8000274a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	e0e080e7          	jalr	-498(ra) # 80005cf0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	0ba080e7          	jalr	186(ra) # 80001fa4 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	412080e7          	jalr	1042(ra) # 8000134c <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	154080e7          	jalr	340(ra) # 80001096 <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	a88080e7          	jalr	-1400(ra) # 800019d2 <procinit>
    trapinit();      // trap vectors
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	7d0080e7          	jalr	2000(ra) # 80002722 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	7f0080e7          	jalr	2032(ra) # 8000274a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	d78080e7          	jalr	-648(ra) # 80005cda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	d86080e7          	jalr	-634(ra) # 80005cf0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	f30080e7          	jalr	-208(ra) # 80002ea2 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	5d4080e7          	jalr	1492(ra) # 8000354e <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	572080e7          	jalr	1394(ra) # 800044f4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	e6e080e7          	jalr	-402(ra) # 80005df8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	df8080e7          	jalr	-520(ra) # 80001d8a <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	94f72c23          	sw	a5,-1704(a4) # 800088f8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <pteprint>:
extern char trampoline[]; // trampoline.S


//CHARISIS SKORDAS EDIT-----INSTERTING VMPRINT FUNCTION
//more explanation is given in readme
void pteprint(pagetable_t pagetable, int level){
    80000faa:	7159                	addi	sp,sp,-112
    80000fac:	f486                	sd	ra,104(sp)
    80000fae:	f0a2                	sd	s0,96(sp)
    80000fb0:	eca6                	sd	s1,88(sp)
    80000fb2:	e8ca                	sd	s2,80(sp)
    80000fb4:	e4ce                	sd	s3,72(sp)
    80000fb6:	e0d2                	sd	s4,64(sp)
    80000fb8:	fc56                	sd	s5,56(sp)
    80000fba:	f85a                	sd	s6,48(sp)
    80000fbc:	f45e                	sd	s7,40(sp)
    80000fbe:	f062                	sd	s8,32(sp)
    80000fc0:	ec66                	sd	s9,24(sp)
    80000fc2:	e86a                	sd	s10,16(sp)
    80000fc4:	e46e                	sd	s11,8(sp)
    80000fc6:	1880                	addi	s0,sp,112
    80000fc8:	8aae                	mv	s5,a1

        for(int i=0; i<512; i++){
    80000fca:	8a2a                	mv	s4,a0
    80000fcc:	4981                	li	s3,0
                pte_t pte = pagetable[i];
                if(pte & PTE_V){	//check if index of pte is valid(NOT NULL),checking so if there is mapped physical address in the particular VA
                        for(int j=0; j<=level-1; j++){
                                printf(".. ");		//till one level before the end,because the assignment wanted to be ".. .. ..X"
                        }
                        printf("..%d: pte %p pa %p \n", i, pte, PTE2PA(pte));
    80000fce:	00007c97          	auipc	s9,0x7
    80000fd2:	10ac8c93          	addi	s9,s9,266 # 800080d8 <digits+0x98>
                        for(int j=0; j<=level-1; j++){
    80000fd6:	4d01                	li	s10,0
                                printf(".. ");		//till one level before the end,because the assignment wanted to be ".. .. ..X"
    80000fd8:	00007b17          	auipc	s6,0x7
    80000fdc:	0f8b0b13          	addi	s6,s6,248 # 800080d0 <digits+0x90>
                }
                if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_W)) == 0){          //lower level page table
    80000fe0:	4c05                	li	s8,1
                        uint64 child = PTE2PA(pte);		//unsigned 64-bit integer
                        pteprint((pagetable_t) child, level+1);
    80000fe2:	00158d9b          	addiw	s11,a1,1
        for(int i=0; i<512; i++){
    80000fe6:	20000b93          	li	s7,512
    80000fea:	a01d                	j	80001010 <pteprint+0x66>
                        printf("..%d: pte %p pa %p \n", i, pte, PTE2PA(pte));
    80000fec:	00a95693          	srli	a3,s2,0xa
    80000ff0:	06b2                	slli	a3,a3,0xc
    80000ff2:	864a                	mv	a2,s2
    80000ff4:	85ce                	mv	a1,s3
    80000ff6:	8566                	mv	a0,s9
    80000ff8:	fffff097          	auipc	ra,0xfffff
    80000ffc:	596080e7          	jalr	1430(ra) # 8000058e <printf>
                if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_W)) == 0){          //lower level page table
    80001000:	00797793          	andi	a5,s2,7
    80001004:	03878763          	beq	a5,s8,80001032 <pteprint+0x88>
        for(int i=0; i<512; i++){
    80001008:	2985                	addiw	s3,s3,1
    8000100a:	0a21                	addi	s4,s4,8
    8000100c:	03798c63          	beq	s3,s7,80001044 <pteprint+0x9a>
                pte_t pte = pagetable[i];
    80001010:	000a3903          	ld	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffdd270>
                if(pte & PTE_V){	//check if index of pte is valid(NOT NULL),checking so if there is mapped physical address in the particular VA
    80001014:	00197793          	andi	a5,s2,1
    80001018:	d7e5                	beqz	a5,80001000 <pteprint+0x56>
                        for(int j=0; j<=level-1; j++){
    8000101a:	fd5059e3          	blez	s5,80000fec <pteprint+0x42>
    8000101e:	84ea                	mv	s1,s10
                                printf(".. ");		//till one level before the end,because the assignment wanted to be ".. .. ..X"
    80001020:	855a                	mv	a0,s6
    80001022:	fffff097          	auipc	ra,0xfffff
    80001026:	56c080e7          	jalr	1388(ra) # 8000058e <printf>
                        for(int j=0; j<=level-1; j++){
    8000102a:	2485                	addiw	s1,s1,1
    8000102c:	fe9a9ae3          	bne	s5,s1,80001020 <pteprint+0x76>
    80001030:	bf75                	j	80000fec <pteprint+0x42>
                        uint64 child = PTE2PA(pte);		//unsigned 64-bit integer
    80001032:	00a95513          	srli	a0,s2,0xa
                        pteprint((pagetable_t) child, level+1);
    80001036:	85ee                	mv	a1,s11
    80001038:	0532                	slli	a0,a0,0xc
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	f70080e7          	jalr	-144(ra) # 80000faa <pteprint>
    80001042:	b7d9                	j	80001008 <pteprint+0x5e>
                }
        }
}
    80001044:	70a6                	ld	ra,104(sp)
    80001046:	7406                	ld	s0,96(sp)
    80001048:	64e6                	ld	s1,88(sp)
    8000104a:	6946                	ld	s2,80(sp)
    8000104c:	69a6                	ld	s3,72(sp)
    8000104e:	6a06                	ld	s4,64(sp)
    80001050:	7ae2                	ld	s5,56(sp)
    80001052:	7b42                	ld	s6,48(sp)
    80001054:	7ba2                	ld	s7,40(sp)
    80001056:	7c02                	ld	s8,32(sp)
    80001058:	6ce2                	ld	s9,24(sp)
    8000105a:	6d42                	ld	s10,16(sp)
    8000105c:	6da2                	ld	s11,8(sp)
    8000105e:	6165                	addi	sp,sp,112
    80001060:	8082                	ret

0000000080001062 <vmprint>:

void vmprint(pagetable_t pagetable){
    80001062:	1101                	addi	sp,sp,-32
    80001064:	ec06                	sd	ra,24(sp)
    80001066:	e822                	sd	s0,16(sp)
    80001068:	e426                	sd	s1,8(sp)
    8000106a:	1000                	addi	s0,sp,32
    8000106c:	84aa                	mv	s1,a0

        printf("Page Table: %p\n", pagetable);
    8000106e:	85aa                	mv	a1,a0
    80001070:	00007517          	auipc	a0,0x7
    80001074:	08050513          	addi	a0,a0,128 # 800080f0 <digits+0xb0>
    80001078:	fffff097          	auipc	ra,0xfffff
    8000107c:	516080e7          	jalr	1302(ra) # 8000058e <printf>
        pteprint(pagetable,0);
    80001080:	4581                	li	a1,0
    80001082:	8526                	mv	a0,s1
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f26080e7          	jalr	-218(ra) # 80000faa <pteprint>
}
    8000108c:	60e2                	ld	ra,24(sp)
    8000108e:	6442                	ld	s0,16(sp)
    80001090:	64a2                	ld	s1,8(sp)
    80001092:	6105                	addi	sp,sp,32
    80001094:	8082                	ret

0000000080001096 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001096:	1141                	addi	sp,sp,-16
    80001098:	e422                	sd	s0,8(sp)
    8000109a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000109c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010a0:	00008797          	auipc	a5,0x8
    800010a4:	8607b783          	ld	a5,-1952(a5) # 80008900 <kernel_pagetable>
    800010a8:	83b1                	srli	a5,a5,0xc
    800010aa:	577d                	li	a4,-1
    800010ac:	177e                	slli	a4,a4,0x3f
    800010ae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010b0:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010b4:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010b8:	6422                	ld	s0,8(sp)
    800010ba:	0141                	addi	sp,sp,16
    800010bc:	8082                	ret

00000000800010be <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010be:	7139                	addi	sp,sp,-64
    800010c0:	fc06                	sd	ra,56(sp)
    800010c2:	f822                	sd	s0,48(sp)
    800010c4:	f426                	sd	s1,40(sp)
    800010c6:	f04a                	sd	s2,32(sp)
    800010c8:	ec4e                	sd	s3,24(sp)
    800010ca:	e852                	sd	s4,16(sp)
    800010cc:	e456                	sd	s5,8(sp)
    800010ce:	e05a                	sd	s6,0(sp)
    800010d0:	0080                	addi	s0,sp,64
    800010d2:	84aa                	mv	s1,a0
    800010d4:	89ae                	mv	s3,a1
    800010d6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010d8:	57fd                	li	a5,-1
    800010da:	83e9                	srli	a5,a5,0x1a
    800010dc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010de:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010e0:	04b7f263          	bgeu	a5,a1,80001124 <walk+0x66>
    panic("walk");
    800010e4:	00007517          	auipc	a0,0x7
    800010e8:	01c50513          	addi	a0,a0,28 # 80008100 <digits+0xc0>
    800010ec:	fffff097          	auipc	ra,0xfffff
    800010f0:	458080e7          	jalr	1112(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010f4:	060a8663          	beqz	s5,80001160 <walk+0xa2>
    800010f8:	00000097          	auipc	ra,0x0
    800010fc:	a02080e7          	jalr	-1534(ra) # 80000afa <kalloc>
    80001100:	84aa                	mv	s1,a0
    80001102:	c529                	beqz	a0,8000114c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001104:	6605                	lui	a2,0x1
    80001106:	4581                	li	a1,0
    80001108:	00000097          	auipc	ra,0x0
    8000110c:	bde080e7          	jalr	-1058(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001110:	00c4d793          	srli	a5,s1,0xc
    80001114:	07aa                	slli	a5,a5,0xa
    80001116:	0017e793          	ori	a5,a5,1
    8000111a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000111e:	3a5d                	addiw	s4,s4,-9
    80001120:	036a0063          	beq	s4,s6,80001140 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001124:	0149d933          	srl	s2,s3,s4
    80001128:	1ff97913          	andi	s2,s2,511
    8000112c:	090e                	slli	s2,s2,0x3
    8000112e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001130:	00093483          	ld	s1,0(s2)
    80001134:	0014f793          	andi	a5,s1,1
    80001138:	dfd5                	beqz	a5,800010f4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000113a:	80a9                	srli	s1,s1,0xa
    8000113c:	04b2                	slli	s1,s1,0xc
    8000113e:	b7c5                	j	8000111e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001140:	00c9d513          	srli	a0,s3,0xc
    80001144:	1ff57513          	andi	a0,a0,511
    80001148:	050e                	slli	a0,a0,0x3
    8000114a:	9526                	add	a0,a0,s1
}
    8000114c:	70e2                	ld	ra,56(sp)
    8000114e:	7442                	ld	s0,48(sp)
    80001150:	74a2                	ld	s1,40(sp)
    80001152:	7902                	ld	s2,32(sp)
    80001154:	69e2                	ld	s3,24(sp)
    80001156:	6a42                	ld	s4,16(sp)
    80001158:	6aa2                	ld	s5,8(sp)
    8000115a:	6b02                	ld	s6,0(sp)
    8000115c:	6121                	addi	sp,sp,64
    8000115e:	8082                	ret
        return 0;
    80001160:	4501                	li	a0,0
    80001162:	b7ed                	j	8000114c <walk+0x8e>

0000000080001164 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001164:	57fd                	li	a5,-1
    80001166:	83e9                	srli	a5,a5,0x1a
    80001168:	00b7f463          	bgeu	a5,a1,80001170 <walkaddr+0xc>
    return 0;
    8000116c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000116e:	8082                	ret
{
    80001170:	1141                	addi	sp,sp,-16
    80001172:	e406                	sd	ra,8(sp)
    80001174:	e022                	sd	s0,0(sp)
    80001176:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001178:	4601                	li	a2,0
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	f44080e7          	jalr	-188(ra) # 800010be <walk>
  if(pte == 0)
    80001182:	c105                	beqz	a0,800011a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001184:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001186:	0117f693          	andi	a3,a5,17
    8000118a:	4745                	li	a4,17
    return 0;
    8000118c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000118e:	00e68663          	beq	a3,a4,8000119a <walkaddr+0x36>
}
    80001192:	60a2                	ld	ra,8(sp)
    80001194:	6402                	ld	s0,0(sp)
    80001196:	0141                	addi	sp,sp,16
    80001198:	8082                	ret
  pa = PTE2PA(*pte);
    8000119a:	00a7d513          	srli	a0,a5,0xa
    8000119e:	0532                	slli	a0,a0,0xc
  return pa;
    800011a0:	bfcd                	j	80001192 <walkaddr+0x2e>
    return 0;
    800011a2:	4501                	li	a0,0
    800011a4:	b7fd                	j	80001192 <walkaddr+0x2e>

00000000800011a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011a6:	715d                	addi	sp,sp,-80
    800011a8:	e486                	sd	ra,72(sp)
    800011aa:	e0a2                	sd	s0,64(sp)
    800011ac:	fc26                	sd	s1,56(sp)
    800011ae:	f84a                	sd	s2,48(sp)
    800011b0:	f44e                	sd	s3,40(sp)
    800011b2:	f052                	sd	s4,32(sp)
    800011b4:	ec56                	sd	s5,24(sp)
    800011b6:	e85a                	sd	s6,16(sp)
    800011b8:	e45e                	sd	s7,8(sp)
    800011ba:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011bc:	c205                	beqz	a2,800011dc <mappages+0x36>
    800011be:	8aaa                	mv	s5,a0
    800011c0:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011c2:	77fd                	lui	a5,0xfffff
    800011c4:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011c8:	15fd                	addi	a1,a1,-1
    800011ca:	00c589b3          	add	s3,a1,a2
    800011ce:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011d2:	8952                	mv	s2,s4
    800011d4:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011d8:	6b85                	lui	s7,0x1
    800011da:	a015                	j	800011fe <mappages+0x58>
    panic("mappages: size");
    800011dc:	00007517          	auipc	a0,0x7
    800011e0:	f2c50513          	addi	a0,a0,-212 # 80008108 <digits+0xc8>
    800011e4:	fffff097          	auipc	ra,0xfffff
    800011e8:	360080e7          	jalr	864(ra) # 80000544 <panic>
      panic("mappages: remap");
    800011ec:	00007517          	auipc	a0,0x7
    800011f0:	f2c50513          	addi	a0,a0,-212 # 80008118 <digits+0xd8>
    800011f4:	fffff097          	auipc	ra,0xfffff
    800011f8:	350080e7          	jalr	848(ra) # 80000544 <panic>
    a += PGSIZE;
    800011fc:	995e                	add	s2,s2,s7
  for(;;){
    800011fe:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001202:	4605                	li	a2,1
    80001204:	85ca                	mv	a1,s2
    80001206:	8556                	mv	a0,s5
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	eb6080e7          	jalr	-330(ra) # 800010be <walk>
    80001210:	cd19                	beqz	a0,8000122e <mappages+0x88>
    if(*pte & PTE_V)
    80001212:	611c                	ld	a5,0(a0)
    80001214:	8b85                	andi	a5,a5,1
    80001216:	fbf9                	bnez	a5,800011ec <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001218:	80b1                	srli	s1,s1,0xc
    8000121a:	04aa                	slli	s1,s1,0xa
    8000121c:	0164e4b3          	or	s1,s1,s6
    80001220:	0014e493          	ori	s1,s1,1
    80001224:	e104                	sd	s1,0(a0)
    if(a == last)
    80001226:	fd391be3          	bne	s2,s3,800011fc <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000122a:	4501                	li	a0,0
    8000122c:	a011                	j	80001230 <mappages+0x8a>
      return -1;
    8000122e:	557d                	li	a0,-1
}
    80001230:	60a6                	ld	ra,72(sp)
    80001232:	6406                	ld	s0,64(sp)
    80001234:	74e2                	ld	s1,56(sp)
    80001236:	7942                	ld	s2,48(sp)
    80001238:	79a2                	ld	s3,40(sp)
    8000123a:	7a02                	ld	s4,32(sp)
    8000123c:	6ae2                	ld	s5,24(sp)
    8000123e:	6b42                	ld	s6,16(sp)
    80001240:	6ba2                	ld	s7,8(sp)
    80001242:	6161                	addi	sp,sp,80
    80001244:	8082                	ret

0000000080001246 <kvmmap>:
{
    80001246:	1141                	addi	sp,sp,-16
    80001248:	e406                	sd	ra,8(sp)
    8000124a:	e022                	sd	s0,0(sp)
    8000124c:	0800                	addi	s0,sp,16
    8000124e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001250:	86b2                	mv	a3,a2
    80001252:	863e                	mv	a2,a5
    80001254:	00000097          	auipc	ra,0x0
    80001258:	f52080e7          	jalr	-174(ra) # 800011a6 <mappages>
    8000125c:	e509                	bnez	a0,80001266 <kvmmap+0x20>
}
    8000125e:	60a2                	ld	ra,8(sp)
    80001260:	6402                	ld	s0,0(sp)
    80001262:	0141                	addi	sp,sp,16
    80001264:	8082                	ret
    panic("kvmmap");
    80001266:	00007517          	auipc	a0,0x7
    8000126a:	ec250513          	addi	a0,a0,-318 # 80008128 <digits+0xe8>
    8000126e:	fffff097          	auipc	ra,0xfffff
    80001272:	2d6080e7          	jalr	726(ra) # 80000544 <panic>

0000000080001276 <kvmmake>:
{
    80001276:	1101                	addi	sp,sp,-32
    80001278:	ec06                	sd	ra,24(sp)
    8000127a:	e822                	sd	s0,16(sp)
    8000127c:	e426                	sd	s1,8(sp)
    8000127e:	e04a                	sd	s2,0(sp)
    80001280:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001282:	00000097          	auipc	ra,0x0
    80001286:	878080e7          	jalr	-1928(ra) # 80000afa <kalloc>
    8000128a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000128c:	6605                	lui	a2,0x1
    8000128e:	4581                	li	a1,0
    80001290:	00000097          	auipc	ra,0x0
    80001294:	a56080e7          	jalr	-1450(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001298:	4719                	li	a4,6
    8000129a:	6685                	lui	a3,0x1
    8000129c:	10000637          	lui	a2,0x10000
    800012a0:	100005b7          	lui	a1,0x10000
    800012a4:	8526                	mv	a0,s1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	fa0080e7          	jalr	-96(ra) # 80001246 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012ae:	4719                	li	a4,6
    800012b0:	6685                	lui	a3,0x1
    800012b2:	10001637          	lui	a2,0x10001
    800012b6:	100015b7          	lui	a1,0x10001
    800012ba:	8526                	mv	a0,s1
    800012bc:	00000097          	auipc	ra,0x0
    800012c0:	f8a080e7          	jalr	-118(ra) # 80001246 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012c4:	4719                	li	a4,6
    800012c6:	004006b7          	lui	a3,0x400
    800012ca:	0c000637          	lui	a2,0xc000
    800012ce:	0c0005b7          	lui	a1,0xc000
    800012d2:	8526                	mv	a0,s1
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	f72080e7          	jalr	-142(ra) # 80001246 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012dc:	00007917          	auipc	s2,0x7
    800012e0:	d2490913          	addi	s2,s2,-732 # 80008000 <etext>
    800012e4:	4729                	li	a4,10
    800012e6:	80007697          	auipc	a3,0x80007
    800012ea:	d1a68693          	addi	a3,a3,-742 # 8000 <_entry-0x7fff8000>
    800012ee:	4605                	li	a2,1
    800012f0:	067e                	slli	a2,a2,0x1f
    800012f2:	85b2                	mv	a1,a2
    800012f4:	8526                	mv	a0,s1
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	f50080e7          	jalr	-176(ra) # 80001246 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012fe:	4719                	li	a4,6
    80001300:	46c5                	li	a3,17
    80001302:	06ee                	slli	a3,a3,0x1b
    80001304:	412686b3          	sub	a3,a3,s2
    80001308:	864a                	mv	a2,s2
    8000130a:	85ca                	mv	a1,s2
    8000130c:	8526                	mv	a0,s1
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f38080e7          	jalr	-200(ra) # 80001246 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001316:	4729                	li	a4,10
    80001318:	6685                	lui	a3,0x1
    8000131a:	00006617          	auipc	a2,0x6
    8000131e:	ce660613          	addi	a2,a2,-794 # 80007000 <_trampoline>
    80001322:	040005b7          	lui	a1,0x4000
    80001326:	15fd                	addi	a1,a1,-1
    80001328:	05b2                	slli	a1,a1,0xc
    8000132a:	8526                	mv	a0,s1
    8000132c:	00000097          	auipc	ra,0x0
    80001330:	f1a080e7          	jalr	-230(ra) # 80001246 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001334:	8526                	mv	a0,s1
    80001336:	00000097          	auipc	ra,0x0
    8000133a:	606080e7          	jalr	1542(ra) # 8000193c <proc_mapstacks>
}
    8000133e:	8526                	mv	a0,s1
    80001340:	60e2                	ld	ra,24(sp)
    80001342:	6442                	ld	s0,16(sp)
    80001344:	64a2                	ld	s1,8(sp)
    80001346:	6902                	ld	s2,0(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <kvminit>:
{
    8000134c:	1141                	addi	sp,sp,-16
    8000134e:	e406                	sd	ra,8(sp)
    80001350:	e022                	sd	s0,0(sp)
    80001352:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001354:	00000097          	auipc	ra,0x0
    80001358:	f22080e7          	jalr	-222(ra) # 80001276 <kvmmake>
    8000135c:	00007797          	auipc	a5,0x7
    80001360:	5aa7b223          	sd	a0,1444(a5) # 80008900 <kernel_pagetable>
}
    80001364:	60a2                	ld	ra,8(sp)
    80001366:	6402                	ld	s0,0(sp)
    80001368:	0141                	addi	sp,sp,16
    8000136a:	8082                	ret

000000008000136c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000136c:	715d                	addi	sp,sp,-80
    8000136e:	e486                	sd	ra,72(sp)
    80001370:	e0a2                	sd	s0,64(sp)
    80001372:	fc26                	sd	s1,56(sp)
    80001374:	f84a                	sd	s2,48(sp)
    80001376:	f44e                	sd	s3,40(sp)
    80001378:	f052                	sd	s4,32(sp)
    8000137a:	ec56                	sd	s5,24(sp)
    8000137c:	e85a                	sd	s6,16(sp)
    8000137e:	e45e                	sd	s7,8(sp)
    80001380:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001382:	03459793          	slli	a5,a1,0x34
    80001386:	e795                	bnez	a5,800013b2 <uvmunmap+0x46>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	892e                	mv	s2,a1
    8000138c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000138e:	0632                	slli	a2,a2,0xc
    80001390:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001394:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001396:	6b05                	lui	s6,0x1
    80001398:	0735e863          	bltu	a1,s3,80001408 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000139c:	60a6                	ld	ra,72(sp)
    8000139e:	6406                	ld	s0,64(sp)
    800013a0:	74e2                	ld	s1,56(sp)
    800013a2:	7942                	ld	s2,48(sp)
    800013a4:	79a2                	ld	s3,40(sp)
    800013a6:	7a02                	ld	s4,32(sp)
    800013a8:	6ae2                	ld	s5,24(sp)
    800013aa:	6b42                	ld	s6,16(sp)
    800013ac:	6ba2                	ld	s7,8(sp)
    800013ae:	6161                	addi	sp,sp,80
    800013b0:	8082                	ret
    panic("uvmunmap: not aligned");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	d7e50513          	addi	a0,a0,-642 # 80008130 <digits+0xf0>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	18a080e7          	jalr	394(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800013c2:	00007517          	auipc	a0,0x7
    800013c6:	d8650513          	addi	a0,a0,-634 # 80008148 <digits+0x108>
    800013ca:	fffff097          	auipc	ra,0xfffff
    800013ce:	17a080e7          	jalr	378(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	16a080e7          	jalr	362(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800013e2:	00007517          	auipc	a0,0x7
    800013e6:	d8e50513          	addi	a0,a0,-626 # 80008170 <digits+0x130>
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	15a080e7          	jalr	346(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    800013f2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013f4:	0532                	slli	a0,a0,0xc
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	608080e7          	jalr	1544(ra) # 800009fe <kfree>
    *pte = 0;
    800013fe:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001402:	995a                	add	s2,s2,s6
    80001404:	f9397ce3          	bgeu	s2,s3,8000139c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001408:	4601                	li	a2,0
    8000140a:	85ca                	mv	a1,s2
    8000140c:	8552                	mv	a0,s4
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	cb0080e7          	jalr	-848(ra) # 800010be <walk>
    80001416:	84aa                	mv	s1,a0
    80001418:	d54d                	beqz	a0,800013c2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000141a:	6108                	ld	a0,0(a0)
    8000141c:	00157793          	andi	a5,a0,1
    80001420:	dbcd                	beqz	a5,800013d2 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001422:	3ff57793          	andi	a5,a0,1023
    80001426:	fb778ee3          	beq	a5,s7,800013e2 <uvmunmap+0x76>
    if(do_free){
    8000142a:	fc0a8ae3          	beqz	s5,800013fe <uvmunmap+0x92>
    8000142e:	b7d1                	j	800013f2 <uvmunmap+0x86>

0000000080001430 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001430:	1101                	addi	sp,sp,-32
    80001432:	ec06                	sd	ra,24(sp)
    80001434:	e822                	sd	s0,16(sp)
    80001436:	e426                	sd	s1,8(sp)
    80001438:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	6c0080e7          	jalr	1728(ra) # 80000afa <kalloc>
    80001442:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001444:	c519                	beqz	a0,80001452 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001446:	6605                	lui	a2,0x1
    80001448:	4581                	li	a1,0
    8000144a:	00000097          	auipc	ra,0x0
    8000144e:	89c080e7          	jalr	-1892(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001452:	8526                	mv	a0,s1
    80001454:	60e2                	ld	ra,24(sp)
    80001456:	6442                	ld	s0,16(sp)
    80001458:	64a2                	ld	s1,8(sp)
    8000145a:	6105                	addi	sp,sp,32
    8000145c:	8082                	ret

000000008000145e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000145e:	7179                	addi	sp,sp,-48
    80001460:	f406                	sd	ra,40(sp)
    80001462:	f022                	sd	s0,32(sp)
    80001464:	ec26                	sd	s1,24(sp)
    80001466:	e84a                	sd	s2,16(sp)
    80001468:	e44e                	sd	s3,8(sp)
    8000146a:	e052                	sd	s4,0(sp)
    8000146c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000146e:	6785                	lui	a5,0x1
    80001470:	04f67863          	bgeu	a2,a5,800014c0 <uvmfirst+0x62>
    80001474:	8a2a                	mv	s4,a0
    80001476:	89ae                	mv	s3,a1
    80001478:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000147a:	fffff097          	auipc	ra,0xfffff
    8000147e:	680080e7          	jalr	1664(ra) # 80000afa <kalloc>
    80001482:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001484:	6605                	lui	a2,0x1
    80001486:	4581                	li	a1,0
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	85e080e7          	jalr	-1954(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001490:	4779                	li	a4,30
    80001492:	86ca                	mv	a3,s2
    80001494:	6605                	lui	a2,0x1
    80001496:	4581                	li	a1,0
    80001498:	8552                	mv	a0,s4
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	d0c080e7          	jalr	-756(ra) # 800011a6 <mappages>
  memmove(mem, src, sz);
    800014a2:	8626                	mv	a2,s1
    800014a4:	85ce                	mv	a1,s3
    800014a6:	854a                	mv	a0,s2
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	89e080e7          	jalr	-1890(ra) # 80000d46 <memmove>
}
    800014b0:	70a2                	ld	ra,40(sp)
    800014b2:	7402                	ld	s0,32(sp)
    800014b4:	64e2                	ld	s1,24(sp)
    800014b6:	6942                	ld	s2,16(sp)
    800014b8:	69a2                	ld	s3,8(sp)
    800014ba:	6a02                	ld	s4,0(sp)
    800014bc:	6145                	addi	sp,sp,48
    800014be:	8082                	ret
    panic("uvmfirst: more than a page");
    800014c0:	00007517          	auipc	a0,0x7
    800014c4:	cc850513          	addi	a0,a0,-824 # 80008188 <digits+0x148>
    800014c8:	fffff097          	auipc	ra,0xfffff
    800014cc:	07c080e7          	jalr	124(ra) # 80000544 <panic>

00000000800014d0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014d0:	1101                	addi	sp,sp,-32
    800014d2:	ec06                	sd	ra,24(sp)
    800014d4:	e822                	sd	s0,16(sp)
    800014d6:	e426                	sd	s1,8(sp)
    800014d8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014da:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014dc:	00b67d63          	bgeu	a2,a1,800014f6 <uvmdealloc+0x26>
    800014e0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014e2:	6785                	lui	a5,0x1
    800014e4:	17fd                	addi	a5,a5,-1
    800014e6:	00f60733          	add	a4,a2,a5
    800014ea:	767d                	lui	a2,0xfffff
    800014ec:	8f71                	and	a4,a4,a2
    800014ee:	97ae                	add	a5,a5,a1
    800014f0:	8ff1                	and	a5,a5,a2
    800014f2:	00f76863          	bltu	a4,a5,80001502 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014f6:	8526                	mv	a0,s1
    800014f8:	60e2                	ld	ra,24(sp)
    800014fa:	6442                	ld	s0,16(sp)
    800014fc:	64a2                	ld	s1,8(sp)
    800014fe:	6105                	addi	sp,sp,32
    80001500:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001502:	8f99                	sub	a5,a5,a4
    80001504:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001506:	4685                	li	a3,1
    80001508:	0007861b          	sext.w	a2,a5
    8000150c:	85ba                	mv	a1,a4
    8000150e:	00000097          	auipc	ra,0x0
    80001512:	e5e080e7          	jalr	-418(ra) # 8000136c <uvmunmap>
    80001516:	b7c5                	j	800014f6 <uvmdealloc+0x26>

0000000080001518 <uvmalloc>:
  if(newsz < oldsz)
    80001518:	0ab66563          	bltu	a2,a1,800015c2 <uvmalloc+0xaa>
{
    8000151c:	7139                	addi	sp,sp,-64
    8000151e:	fc06                	sd	ra,56(sp)
    80001520:	f822                	sd	s0,48(sp)
    80001522:	f426                	sd	s1,40(sp)
    80001524:	f04a                	sd	s2,32(sp)
    80001526:	ec4e                	sd	s3,24(sp)
    80001528:	e852                	sd	s4,16(sp)
    8000152a:	e456                	sd	s5,8(sp)
    8000152c:	e05a                	sd	s6,0(sp)
    8000152e:	0080                	addi	s0,sp,64
    80001530:	8aaa                	mv	s5,a0
    80001532:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001534:	6985                	lui	s3,0x1
    80001536:	19fd                	addi	s3,s3,-1
    80001538:	95ce                	add	a1,a1,s3
    8000153a:	79fd                	lui	s3,0xfffff
    8000153c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001540:	08c9f363          	bgeu	s3,a2,800015c6 <uvmalloc+0xae>
    80001544:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001546:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000154a:	fffff097          	auipc	ra,0xfffff
    8000154e:	5b0080e7          	jalr	1456(ra) # 80000afa <kalloc>
    80001552:	84aa                	mv	s1,a0
    if(mem == 0){
    80001554:	c51d                	beqz	a0,80001582 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001556:	6605                	lui	a2,0x1
    80001558:	4581                	li	a1,0
    8000155a:	fffff097          	auipc	ra,0xfffff
    8000155e:	78c080e7          	jalr	1932(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001562:	875a                	mv	a4,s6
    80001564:	86a6                	mv	a3,s1
    80001566:	6605                	lui	a2,0x1
    80001568:	85ca                	mv	a1,s2
    8000156a:	8556                	mv	a0,s5
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	c3a080e7          	jalr	-966(ra) # 800011a6 <mappages>
    80001574:	e90d                	bnez	a0,800015a6 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001576:	6785                	lui	a5,0x1
    80001578:	993e                	add	s2,s2,a5
    8000157a:	fd4968e3          	bltu	s2,s4,8000154a <uvmalloc+0x32>
  return newsz;
    8000157e:	8552                	mv	a0,s4
    80001580:	a809                	j	80001592 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001582:	864e                	mv	a2,s3
    80001584:	85ca                	mv	a1,s2
    80001586:	8556                	mv	a0,s5
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	f48080e7          	jalr	-184(ra) # 800014d0 <uvmdealloc>
      return 0;
    80001590:	4501                	li	a0,0
}
    80001592:	70e2                	ld	ra,56(sp)
    80001594:	7442                	ld	s0,48(sp)
    80001596:	74a2                	ld	s1,40(sp)
    80001598:	7902                	ld	s2,32(sp)
    8000159a:	69e2                	ld	s3,24(sp)
    8000159c:	6a42                	ld	s4,16(sp)
    8000159e:	6aa2                	ld	s5,8(sp)
    800015a0:	6b02                	ld	s6,0(sp)
    800015a2:	6121                	addi	sp,sp,64
    800015a4:	8082                	ret
      kfree(mem);
    800015a6:	8526                	mv	a0,s1
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	456080e7          	jalr	1110(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015b0:	864e                	mv	a2,s3
    800015b2:	85ca                	mv	a1,s2
    800015b4:	8556                	mv	a0,s5
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f1a080e7          	jalr	-230(ra) # 800014d0 <uvmdealloc>
      return 0;
    800015be:	4501                	li	a0,0
    800015c0:	bfc9                	j	80001592 <uvmalloc+0x7a>
    return oldsz;
    800015c2:	852e                	mv	a0,a1
}
    800015c4:	8082                	ret
  return newsz;
    800015c6:	8532                	mv	a0,a2
    800015c8:	b7e9                	j	80001592 <uvmalloc+0x7a>

00000000800015ca <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015ca:	7179                	addi	sp,sp,-48
    800015cc:	f406                	sd	ra,40(sp)
    800015ce:	f022                	sd	s0,32(sp)
    800015d0:	ec26                	sd	s1,24(sp)
    800015d2:	e84a                	sd	s2,16(sp)
    800015d4:	e44e                	sd	s3,8(sp)
    800015d6:	e052                	sd	s4,0(sp)
    800015d8:	1800                	addi	s0,sp,48
    800015da:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015dc:	84aa                	mv	s1,a0
    800015de:	6905                	lui	s2,0x1
    800015e0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e2:	4985                	li	s3,1
    800015e4:	a821                	j	800015fc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015e6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015e8:	0532                	slli	a0,a0,0xc
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	fe0080e7          	jalr	-32(ra) # 800015ca <freewalk>
      pagetable[i] = 0;
    800015f2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015f6:	04a1                	addi	s1,s1,8
    800015f8:	03248163          	beq	s1,s2,8000161a <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015fc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015fe:	00f57793          	andi	a5,a0,15
    80001602:	ff3782e3          	beq	a5,s3,800015e6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001606:	8905                	andi	a0,a0,1
    80001608:	d57d                	beqz	a0,800015f6 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000161a:	8552                	mv	a0,s4
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
}
    80001624:	70a2                	ld	ra,40(sp)
    80001626:	7402                	ld	s0,32(sp)
    80001628:	64e2                	ld	s1,24(sp)
    8000162a:	6942                	ld	s2,16(sp)
    8000162c:	69a2                	ld	s3,8(sp)
    8000162e:	6a02                	ld	s4,0(sp)
    80001630:	6145                	addi	sp,sp,48
    80001632:	8082                	ret

0000000080001634 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001634:	1101                	addi	sp,sp,-32
    80001636:	ec06                	sd	ra,24(sp)
    80001638:	e822                	sd	s0,16(sp)
    8000163a:	e426                	sd	s1,8(sp)
    8000163c:	1000                	addi	s0,sp,32
    8000163e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001640:	e999                	bnez	a1,80001656 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001642:	8526                	mv	a0,s1
    80001644:	00000097          	auipc	ra,0x0
    80001648:	f86080e7          	jalr	-122(ra) # 800015ca <freewalk>
}
    8000164c:	60e2                	ld	ra,24(sp)
    8000164e:	6442                	ld	s0,16(sp)
    80001650:	64a2                	ld	s1,8(sp)
    80001652:	6105                	addi	sp,sp,32
    80001654:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001656:	6605                	lui	a2,0x1
    80001658:	167d                	addi	a2,a2,-1
    8000165a:	962e                	add	a2,a2,a1
    8000165c:	4685                	li	a3,1
    8000165e:	8231                	srli	a2,a2,0xc
    80001660:	4581                	li	a1,0
    80001662:	00000097          	auipc	ra,0x0
    80001666:	d0a080e7          	jalr	-758(ra) # 8000136c <uvmunmap>
    8000166a:	bfe1                	j	80001642 <uvmfree+0xe>

000000008000166c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000166c:	c679                	beqz	a2,8000173a <uvmcopy+0xce>
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
    80001682:	0880                	addi	s0,sp,80
    80001684:	8b2a                	mv	s6,a0
    80001686:	8aae                	mv	s5,a1
    80001688:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000168a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000168c:	4601                	li	a2,0
    8000168e:	85ce                	mv	a1,s3
    80001690:	855a                	mv	a0,s6
    80001692:	00000097          	auipc	ra,0x0
    80001696:	a2c080e7          	jalr	-1492(ra) # 800010be <walk>
    8000169a:	c531                	beqz	a0,800016e6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000169c:	6118                	ld	a4,0(a0)
    8000169e:	00177793          	andi	a5,a4,1
    800016a2:	cbb1                	beqz	a5,800016f6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016a4:	00a75593          	srli	a1,a4,0xa
    800016a8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016ac:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	44a080e7          	jalr	1098(ra) # 80000afa <kalloc>
    800016b8:	892a                	mv	s2,a0
    800016ba:	c939                	beqz	a0,80001710 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016bc:	6605                	lui	a2,0x1
    800016be:	85de                	mv	a1,s7
    800016c0:	fffff097          	auipc	ra,0xfffff
    800016c4:	686080e7          	jalr	1670(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016c8:	8726                	mv	a4,s1
    800016ca:	86ca                	mv	a3,s2
    800016cc:	6605                	lui	a2,0x1
    800016ce:	85ce                	mv	a1,s3
    800016d0:	8556                	mv	a0,s5
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	ad4080e7          	jalr	-1324(ra) # 800011a6 <mappages>
    800016da:	e515                	bnez	a0,80001706 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016dc:	6785                	lui	a5,0x1
    800016de:	99be                	add	s3,s3,a5
    800016e0:	fb49e6e3          	bltu	s3,s4,8000168c <uvmcopy+0x20>
    800016e4:	a081                	j	80001724 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016e6:	00007517          	auipc	a0,0x7
    800016ea:	ad250513          	addi	a0,a0,-1326 # 800081b8 <digits+0x178>
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	e56080e7          	jalr	-426(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    800016f6:	00007517          	auipc	a0,0x7
    800016fa:	ae250513          	addi	a0,a0,-1310 # 800081d8 <digits+0x198>
    800016fe:	fffff097          	auipc	ra,0xfffff
    80001702:	e46080e7          	jalr	-442(ra) # 80000544 <panic>
      kfree(mem);
    80001706:	854a                	mv	a0,s2
    80001708:	fffff097          	auipc	ra,0xfffff
    8000170c:	2f6080e7          	jalr	758(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001710:	4685                	li	a3,1
    80001712:	00c9d613          	srli	a2,s3,0xc
    80001716:	4581                	li	a1,0
    80001718:	8556                	mv	a0,s5
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	c52080e7          	jalr	-942(ra) # 8000136c <uvmunmap>
  return -1;
    80001722:	557d                	li	a0,-1
}
    80001724:	60a6                	ld	ra,72(sp)
    80001726:	6406                	ld	s0,64(sp)
    80001728:	74e2                	ld	s1,56(sp)
    8000172a:	7942                	ld	s2,48(sp)
    8000172c:	79a2                	ld	s3,40(sp)
    8000172e:	7a02                	ld	s4,32(sp)
    80001730:	6ae2                	ld	s5,24(sp)
    80001732:	6b42                	ld	s6,16(sp)
    80001734:	6ba2                	ld	s7,8(sp)
    80001736:	6161                	addi	sp,sp,80
    80001738:	8082                	ret
  return 0;
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret

000000008000173e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000173e:	1141                	addi	sp,sp,-16
    80001740:	e406                	sd	ra,8(sp)
    80001742:	e022                	sd	s0,0(sp)
    80001744:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001746:	4601                	li	a2,0
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	976080e7          	jalr	-1674(ra) # 800010be <walk>
  if(pte == 0)
    80001750:	c901                	beqz	a0,80001760 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001752:	611c                	ld	a5,0(a0)
    80001754:	9bbd                	andi	a5,a5,-17
    80001756:	e11c                	sd	a5,0(a0)
}
    80001758:	60a2                	ld	ra,8(sp)
    8000175a:	6402                	ld	s0,0(sp)
    8000175c:	0141                	addi	sp,sp,16
    8000175e:	8082                	ret
    panic("uvmclear");
    80001760:	00007517          	auipc	a0,0x7
    80001764:	a9850513          	addi	a0,a0,-1384 # 800081f8 <digits+0x1b8>
    80001768:	fffff097          	auipc	ra,0xfffff
    8000176c:	ddc080e7          	jalr	-548(ra) # 80000544 <panic>

0000000080001770 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001770:	c6bd                	beqz	a3,800017de <copyout+0x6e>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	e062                	sd	s8,0(sp)
    80001788:	0880                	addi	s0,sp,80
    8000178a:	8b2a                	mv	s6,a0
    8000178c:	8c2e                	mv	s8,a1
    8000178e:	8a32                	mv	s4,a2
    80001790:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001792:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001794:	6a85                	lui	s5,0x1
    80001796:	a015                	j	800017ba <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001798:	9562                	add	a0,a0,s8
    8000179a:	0004861b          	sext.w	a2,s1
    8000179e:	85d2                	mv	a1,s4
    800017a0:	41250533          	sub	a0,a0,s2
    800017a4:	fffff097          	auipc	ra,0xfffff
    800017a8:	5a2080e7          	jalr	1442(ra) # 80000d46 <memmove>

    len -= n;
    800017ac:	409989b3          	sub	s3,s3,s1
    src += n;
    800017b0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b6:	02098263          	beqz	s3,800017da <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017be:	85ca                	mv	a1,s2
    800017c0:	855a                	mv	a0,s6
    800017c2:	00000097          	auipc	ra,0x0
    800017c6:	9a2080e7          	jalr	-1630(ra) # 80001164 <walkaddr>
    if(pa0 == 0)
    800017ca:	cd01                	beqz	a0,800017e2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017cc:	418904b3          	sub	s1,s2,s8
    800017d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800017d2:	fc99f3e3          	bgeu	s3,s1,80001798 <copyout+0x28>
    800017d6:	84ce                	mv	s1,s3
    800017d8:	b7c1                	j	80001798 <copyout+0x28>
  }
  return 0;
    800017da:	4501                	li	a0,0
    800017dc:	a021                	j	800017e4 <copyout+0x74>
    800017de:	4501                	li	a0,0
}
    800017e0:	8082                	ret
      return -1;
    800017e2:	557d                	li	a0,-1
}
    800017e4:	60a6                	ld	ra,72(sp)
    800017e6:	6406                	ld	s0,64(sp)
    800017e8:	74e2                	ld	s1,56(sp)
    800017ea:	7942                	ld	s2,48(sp)
    800017ec:	79a2                	ld	s3,40(sp)
    800017ee:	7a02                	ld	s4,32(sp)
    800017f0:	6ae2                	ld	s5,24(sp)
    800017f2:	6b42                	ld	s6,16(sp)
    800017f4:	6ba2                	ld	s7,8(sp)
    800017f6:	6c02                	ld	s8,0(sp)
    800017f8:	6161                	addi	sp,sp,80
    800017fa:	8082                	ret

00000000800017fc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017fc:	c6bd                	beqz	a3,8000186a <copyin+0x6e>
{
    800017fe:	715d                	addi	sp,sp,-80
    80001800:	e486                	sd	ra,72(sp)
    80001802:	e0a2                	sd	s0,64(sp)
    80001804:	fc26                	sd	s1,56(sp)
    80001806:	f84a                	sd	s2,48(sp)
    80001808:	f44e                	sd	s3,40(sp)
    8000180a:	f052                	sd	s4,32(sp)
    8000180c:	ec56                	sd	s5,24(sp)
    8000180e:	e85a                	sd	s6,16(sp)
    80001810:	e45e                	sd	s7,8(sp)
    80001812:	e062                	sd	s8,0(sp)
    80001814:	0880                	addi	s0,sp,80
    80001816:	8b2a                	mv	s6,a0
    80001818:	8a2e                	mv	s4,a1
    8000181a:	8c32                	mv	s8,a2
    8000181c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000181e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001820:	6a85                	lui	s5,0x1
    80001822:	a015                	j	80001846 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001824:	9562                	add	a0,a0,s8
    80001826:	0004861b          	sext.w	a2,s1
    8000182a:	412505b3          	sub	a1,a0,s2
    8000182e:	8552                	mv	a0,s4
    80001830:	fffff097          	auipc	ra,0xfffff
    80001834:	516080e7          	jalr	1302(ra) # 80000d46 <memmove>

    len -= n;
    80001838:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000183c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000183e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001842:	02098263          	beqz	s3,80001866 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001846:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000184a:	85ca                	mv	a1,s2
    8000184c:	855a                	mv	a0,s6
    8000184e:	00000097          	auipc	ra,0x0
    80001852:	916080e7          	jalr	-1770(ra) # 80001164 <walkaddr>
    if(pa0 == 0)
    80001856:	cd01                	beqz	a0,8000186e <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001858:	418904b3          	sub	s1,s2,s8
    8000185c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000185e:	fc99f3e3          	bgeu	s3,s1,80001824 <copyin+0x28>
    80001862:	84ce                	mv	s1,s3
    80001864:	b7c1                	j	80001824 <copyin+0x28>
  }
  return 0;
    80001866:	4501                	li	a0,0
    80001868:	a021                	j	80001870 <copyin+0x74>
    8000186a:	4501                	li	a0,0
}
    8000186c:	8082                	ret
      return -1;
    8000186e:	557d                	li	a0,-1
}
    80001870:	60a6                	ld	ra,72(sp)
    80001872:	6406                	ld	s0,64(sp)
    80001874:	74e2                	ld	s1,56(sp)
    80001876:	7942                	ld	s2,48(sp)
    80001878:	79a2                	ld	s3,40(sp)
    8000187a:	7a02                	ld	s4,32(sp)
    8000187c:	6ae2                	ld	s5,24(sp)
    8000187e:	6b42                	ld	s6,16(sp)
    80001880:	6ba2                	ld	s7,8(sp)
    80001882:	6c02                	ld	s8,0(sp)
    80001884:	6161                	addi	sp,sp,80
    80001886:	8082                	ret

0000000080001888 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001888:	c6c5                	beqz	a3,80001930 <copyinstr+0xa8>
{
    8000188a:	715d                	addi	sp,sp,-80
    8000188c:	e486                	sd	ra,72(sp)
    8000188e:	e0a2                	sd	s0,64(sp)
    80001890:	fc26                	sd	s1,56(sp)
    80001892:	f84a                	sd	s2,48(sp)
    80001894:	f44e                	sd	s3,40(sp)
    80001896:	f052                	sd	s4,32(sp)
    80001898:	ec56                	sd	s5,24(sp)
    8000189a:	e85a                	sd	s6,16(sp)
    8000189c:	e45e                	sd	s7,8(sp)
    8000189e:	0880                	addi	s0,sp,80
    800018a0:	8a2a                	mv	s4,a0
    800018a2:	8b2e                	mv	s6,a1
    800018a4:	8bb2                	mv	s7,a2
    800018a6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018a8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018aa:	6985                	lui	s3,0x1
    800018ac:	a035                	j	800018d8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018ae:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018b2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018b4:	0017b793          	seqz	a5,a5
    800018b8:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018bc:	60a6                	ld	ra,72(sp)
    800018be:	6406                	ld	s0,64(sp)
    800018c0:	74e2                	ld	s1,56(sp)
    800018c2:	7942                	ld	s2,48(sp)
    800018c4:	79a2                	ld	s3,40(sp)
    800018c6:	7a02                	ld	s4,32(sp)
    800018c8:	6ae2                	ld	s5,24(sp)
    800018ca:	6b42                	ld	s6,16(sp)
    800018cc:	6ba2                	ld	s7,8(sp)
    800018ce:	6161                	addi	sp,sp,80
    800018d0:	8082                	ret
    srcva = va0 + PGSIZE;
    800018d2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018d6:	c8a9                	beqz	s1,80001928 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018d8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018dc:	85ca                	mv	a1,s2
    800018de:	8552                	mv	a0,s4
    800018e0:	00000097          	auipc	ra,0x0
    800018e4:	884080e7          	jalr	-1916(ra) # 80001164 <walkaddr>
    if(pa0 == 0)
    800018e8:	c131                	beqz	a0,8000192c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018ea:	41790833          	sub	a6,s2,s7
    800018ee:	984e                	add	a6,a6,s3
    if(n > max)
    800018f0:	0104f363          	bgeu	s1,a6,800018f6 <copyinstr+0x6e>
    800018f4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018f6:	955e                	add	a0,a0,s7
    800018f8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018fc:	fc080be3          	beqz	a6,800018d2 <copyinstr+0x4a>
    80001900:	985a                	add	a6,a6,s6
    80001902:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001904:	41650633          	sub	a2,a0,s6
    80001908:	14fd                	addi	s1,s1,-1
    8000190a:	9b26                	add	s6,s6,s1
    8000190c:	00f60733          	add	a4,a2,a5
    80001910:	00074703          	lbu	a4,0(a4)
    80001914:	df49                	beqz	a4,800018ae <copyinstr+0x26>
        *dst = *p;
    80001916:	00e78023          	sb	a4,0(a5)
      --max;
    8000191a:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000191e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001920:	ff0796e3          	bne	a5,a6,8000190c <copyinstr+0x84>
      dst++;
    80001924:	8b42                	mv	s6,a6
    80001926:	b775                	j	800018d2 <copyinstr+0x4a>
    80001928:	4781                	li	a5,0
    8000192a:	b769                	j	800018b4 <copyinstr+0x2c>
      return -1;
    8000192c:	557d                	li	a0,-1
    8000192e:	b779                	j	800018bc <copyinstr+0x34>
  int got_null = 0;
    80001930:	4781                	li	a5,0
  if(got_null){
    80001932:	0017b793          	seqz	a5,a5
    80001936:	40f00533          	neg	a0,a5
}
    8000193a:	8082                	ret

000000008000193c <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000193c:	7139                	addi	sp,sp,-64
    8000193e:	fc06                	sd	ra,56(sp)
    80001940:	f822                	sd	s0,48(sp)
    80001942:	f426                	sd	s1,40(sp)
    80001944:	f04a                	sd	s2,32(sp)
    80001946:	ec4e                	sd	s3,24(sp)
    80001948:	e852                	sd	s4,16(sp)
    8000194a:	e456                	sd	s5,8(sp)
    8000194c:	e05a                	sd	s6,0(sp)
    8000194e:	0080                	addi	s0,sp,64
    80001950:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001952:	0000f497          	auipc	s1,0xf
    80001956:	65e48493          	addi	s1,s1,1630 # 80010fb0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000195a:	8b26                	mv	s6,s1
    8000195c:	00006a97          	auipc	s5,0x6
    80001960:	6a4a8a93          	addi	s5,s5,1700 # 80008000 <etext>
    80001964:	04000937          	lui	s2,0x4000
    80001968:	197d                	addi	s2,s2,-1
    8000196a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	00015a17          	auipc	s4,0x15
    80001970:	044a0a13          	addi	s4,s4,68 # 800169b0 <tickslock>
    char *pa = kalloc();
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	186080e7          	jalr	390(ra) # 80000afa <kalloc>
    8000197c:	862a                	mv	a2,a0
    if(pa == 0)
    8000197e:	c131                	beqz	a0,800019c2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001980:	416485b3          	sub	a1,s1,s6
    80001984:	858d                	srai	a1,a1,0x3
    80001986:	000ab783          	ld	a5,0(s5)
    8000198a:	02f585b3          	mul	a1,a1,a5
    8000198e:	2585                	addiw	a1,a1,1
    80001990:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001994:	4719                	li	a4,6
    80001996:	6685                	lui	a3,0x1
    80001998:	40b905b3          	sub	a1,s2,a1
    8000199c:	854e                	mv	a0,s3
    8000199e:	00000097          	auipc	ra,0x0
    800019a2:	8a8080e7          	jalr	-1880(ra) # 80001246 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a6:	16848493          	addi	s1,s1,360
    800019aa:	fd4495e3          	bne	s1,s4,80001974 <proc_mapstacks+0x38>
  }
}
    800019ae:	70e2                	ld	ra,56(sp)
    800019b0:	7442                	ld	s0,48(sp)
    800019b2:	74a2                	ld	s1,40(sp)
    800019b4:	7902                	ld	s2,32(sp)
    800019b6:	69e2                	ld	s3,24(sp)
    800019b8:	6a42                	ld	s4,16(sp)
    800019ba:	6aa2                	ld	s5,8(sp)
    800019bc:	6b02                	ld	s6,0(sp)
    800019be:	6121                	addi	sp,sp,64
    800019c0:	8082                	ret
      panic("kalloc");
    800019c2:	00007517          	auipc	a0,0x7
    800019c6:	84650513          	addi	a0,a0,-1978 # 80008208 <digits+0x1c8>
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	b7a080e7          	jalr	-1158(ra) # 80000544 <panic>

00000000800019d2 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800019d2:	7139                	addi	sp,sp,-64
    800019d4:	fc06                	sd	ra,56(sp)
    800019d6:	f822                	sd	s0,48(sp)
    800019d8:	f426                	sd	s1,40(sp)
    800019da:	f04a                	sd	s2,32(sp)
    800019dc:	ec4e                	sd	s3,24(sp)
    800019de:	e852                	sd	s4,16(sp)
    800019e0:	e456                	sd	s5,8(sp)
    800019e2:	e05a                	sd	s6,0(sp)
    800019e4:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019e6:	00007597          	auipc	a1,0x7
    800019ea:	82a58593          	addi	a1,a1,-2006 # 80008210 <digits+0x1d0>
    800019ee:	0000f517          	auipc	a0,0xf
    800019f2:	19250513          	addi	a0,a0,402 # 80010b80 <pid_lock>
    800019f6:	fffff097          	auipc	ra,0xfffff
    800019fa:	164080e7          	jalr	356(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    800019fe:	00007597          	auipc	a1,0x7
    80001a02:	81a58593          	addi	a1,a1,-2022 # 80008218 <digits+0x1d8>
    80001a06:	0000f517          	auipc	a0,0xf
    80001a0a:	19250513          	addi	a0,a0,402 # 80010b98 <wait_lock>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	14c080e7          	jalr	332(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a16:	0000f497          	auipc	s1,0xf
    80001a1a:	59a48493          	addi	s1,s1,1434 # 80010fb0 <proc>
      initlock(&p->lock, "proc");
    80001a1e:	00007b17          	auipc	s6,0x7
    80001a22:	80ab0b13          	addi	s6,s6,-2038 # 80008228 <digits+0x1e8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a26:	8aa6                	mv	s5,s1
    80001a28:	00006a17          	auipc	s4,0x6
    80001a2c:	5d8a0a13          	addi	s4,s4,1496 # 80008000 <etext>
    80001a30:	04000937          	lui	s2,0x4000
    80001a34:	197d                	addi	s2,s2,-1
    80001a36:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a38:	00015997          	auipc	s3,0x15
    80001a3c:	f7898993          	addi	s3,s3,-136 # 800169b0 <tickslock>
      initlock(&p->lock, "proc");
    80001a40:	85da                	mv	a1,s6
    80001a42:	8526                	mv	a0,s1
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	116080e7          	jalr	278(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001a4c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a50:	415487b3          	sub	a5,s1,s5
    80001a54:	878d                	srai	a5,a5,0x3
    80001a56:	000a3703          	ld	a4,0(s4)
    80001a5a:	02e787b3          	mul	a5,a5,a4
    80001a5e:	2785                	addiw	a5,a5,1
    80001a60:	00d7979b          	slliw	a5,a5,0xd
    80001a64:	40f907b3          	sub	a5,s2,a5
    80001a68:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6a:	16848493          	addi	s1,s1,360
    80001a6e:	fd3499e3          	bne	s1,s3,80001a40 <procinit+0x6e>
  }
}
    80001a72:	70e2                	ld	ra,56(sp)
    80001a74:	7442                	ld	s0,48(sp)
    80001a76:	74a2                	ld	s1,40(sp)
    80001a78:	7902                	ld	s2,32(sp)
    80001a7a:	69e2                	ld	s3,24(sp)
    80001a7c:	6a42                	ld	s4,16(sp)
    80001a7e:	6aa2                	ld	s5,8(sp)
    80001a80:	6b02                	ld	s6,0(sp)
    80001a82:	6121                	addi	sp,sp,64
    80001a84:	8082                	ret

0000000080001a86 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a86:	1141                	addi	sp,sp,-16
    80001a88:	e422                	sd	s0,8(sp)
    80001a8a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a8c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a8e:	2501                	sext.w	a0,a0
    80001a90:	6422                	ld	s0,8(sp)
    80001a92:	0141                	addi	sp,sp,16
    80001a94:	8082                	ret

0000000080001a96 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a96:	1141                	addi	sp,sp,-16
    80001a98:	e422                	sd	s0,8(sp)
    80001a9a:	0800                	addi	s0,sp,16
    80001a9c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a9e:	2781                	sext.w	a5,a5
    80001aa0:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aa2:	0000f517          	auipc	a0,0xf
    80001aa6:	10e50513          	addi	a0,a0,270 # 80010bb0 <cpus>
    80001aaa:	953e                	add	a0,a0,a5
    80001aac:	6422                	ld	s0,8(sp)
    80001aae:	0141                	addi	sp,sp,16
    80001ab0:	8082                	ret

0000000080001ab2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001ab2:	1101                	addi	sp,sp,-32
    80001ab4:	ec06                	sd	ra,24(sp)
    80001ab6:	e822                	sd	s0,16(sp)
    80001ab8:	e426                	sd	s1,8(sp)
    80001aba:	1000                	addi	s0,sp,32
  push_off();
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	0e2080e7          	jalr	226(ra) # 80000b9e <push_off>
    80001ac4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ac6:	2781                	sext.w	a5,a5
    80001ac8:	079e                	slli	a5,a5,0x7
    80001aca:	0000f717          	auipc	a4,0xf
    80001ace:	0b670713          	addi	a4,a4,182 # 80010b80 <pid_lock>
    80001ad2:	97ba                	add	a5,a5,a4
    80001ad4:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	168080e7          	jalr	360(ra) # 80000c3e <pop_off>
  return p;
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret

0000000080001aea <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001aea:	1141                	addi	sp,sp,-16
    80001aec:	e406                	sd	ra,8(sp)
    80001aee:	e022                	sd	s0,0(sp)
    80001af0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001af2:	00000097          	auipc	ra,0x0
    80001af6:	fc0080e7          	jalr	-64(ra) # 80001ab2 <myproc>
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	1a4080e7          	jalr	420(ra) # 80000c9e <release>

  if (first) {
    80001b02:	00007797          	auipc	a5,0x7
    80001b06:	d6e7a783          	lw	a5,-658(a5) # 80008870 <first.1683>
    80001b0a:	eb89                	bnez	a5,80001b1c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b0c:	00001097          	auipc	ra,0x1
    80001b10:	c56080e7          	jalr	-938(ra) # 80002762 <usertrapret>
}
    80001b14:	60a2                	ld	ra,8(sp)
    80001b16:	6402                	ld	s0,0(sp)
    80001b18:	0141                	addi	sp,sp,16
    80001b1a:	8082                	ret
    first = 0;
    80001b1c:	00007797          	auipc	a5,0x7
    80001b20:	d407aa23          	sw	zero,-684(a5) # 80008870 <first.1683>
    fsinit(ROOTDEV);
    80001b24:	4505                	li	a0,1
    80001b26:	00002097          	auipc	ra,0x2
    80001b2a:	9a8080e7          	jalr	-1624(ra) # 800034ce <fsinit>
    80001b2e:	bff9                	j	80001b0c <forkret+0x22>

0000000080001b30 <allocpid>:
{
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	e04a                	sd	s2,0(sp)
    80001b3a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b3c:	0000f917          	auipc	s2,0xf
    80001b40:	04490913          	addi	s2,s2,68 # 80010b80 <pid_lock>
    80001b44:	854a                	mv	a0,s2
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	0a4080e7          	jalr	164(ra) # 80000bea <acquire>
  pid = nextpid;
    80001b4e:	00007797          	auipc	a5,0x7
    80001b52:	d2678793          	addi	a5,a5,-730 # 80008874 <nextpid>
    80001b56:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b58:	0014871b          	addiw	a4,s1,1
    80001b5c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b5e:	854a                	mv	a0,s2
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	13e080e7          	jalr	318(ra) # 80000c9e <release>
}
    80001b68:	8526                	mv	a0,s1
    80001b6a:	60e2                	ld	ra,24(sp)
    80001b6c:	6442                	ld	s0,16(sp)
    80001b6e:	64a2                	ld	s1,8(sp)
    80001b70:	6902                	ld	s2,0(sp)
    80001b72:	6105                	addi	sp,sp,32
    80001b74:	8082                	ret

0000000080001b76 <proc_pagetable>:
{
    80001b76:	1101                	addi	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	e04a                	sd	s2,0(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	8ac080e7          	jalr	-1876(ra) # 80001430 <uvmcreate>
    80001b8c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b8e:	c121                	beqz	a0,80001bce <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b90:	4729                	li	a4,10
    80001b92:	00005697          	auipc	a3,0x5
    80001b96:	46e68693          	addi	a3,a3,1134 # 80007000 <_trampoline>
    80001b9a:	6605                	lui	a2,0x1
    80001b9c:	040005b7          	lui	a1,0x4000
    80001ba0:	15fd                	addi	a1,a1,-1
    80001ba2:	05b2                	slli	a1,a1,0xc
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	602080e7          	jalr	1538(ra) # 800011a6 <mappages>
    80001bac:	02054863          	bltz	a0,80001bdc <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bb0:	4719                	li	a4,6
    80001bb2:	05893683          	ld	a3,88(s2)
    80001bb6:	6605                	lui	a2,0x1
    80001bb8:	020005b7          	lui	a1,0x2000
    80001bbc:	15fd                	addi	a1,a1,-1
    80001bbe:	05b6                	slli	a1,a1,0xd
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	5e4080e7          	jalr	1508(ra) # 800011a6 <mappages>
    80001bca:	02054163          	bltz	a0,80001bec <proc_pagetable+0x76>
}
    80001bce:	8526                	mv	a0,s1
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6902                	ld	s2,0(sp)
    80001bd8:	6105                	addi	sp,sp,32
    80001bda:	8082                	ret
    uvmfree(pagetable, 0);
    80001bdc:	4581                	li	a1,0
    80001bde:	8526                	mv	a0,s1
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	a54080e7          	jalr	-1452(ra) # 80001634 <uvmfree>
    return 0;
    80001be8:	4481                	li	s1,0
    80001bea:	b7d5                	j	80001bce <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bec:	4681                	li	a3,0
    80001bee:	4605                	li	a2,1
    80001bf0:	040005b7          	lui	a1,0x4000
    80001bf4:	15fd                	addi	a1,a1,-1
    80001bf6:	05b2                	slli	a1,a1,0xc
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	772080e7          	jalr	1906(ra) # 8000136c <uvmunmap>
    uvmfree(pagetable, 0);
    80001c02:	4581                	li	a1,0
    80001c04:	8526                	mv	a0,s1
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	a2e080e7          	jalr	-1490(ra) # 80001634 <uvmfree>
    return 0;
    80001c0e:	4481                	li	s1,0
    80001c10:	bf7d                	j	80001bce <proc_pagetable+0x58>

0000000080001c12 <proc_freepagetable>:
{
    80001c12:	1101                	addi	sp,sp,-32
    80001c14:	ec06                	sd	ra,24(sp)
    80001c16:	e822                	sd	s0,16(sp)
    80001c18:	e426                	sd	s1,8(sp)
    80001c1a:	e04a                	sd	s2,0(sp)
    80001c1c:	1000                	addi	s0,sp,32
    80001c1e:	84aa                	mv	s1,a0
    80001c20:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c22:	4681                	li	a3,0
    80001c24:	4605                	li	a2,1
    80001c26:	040005b7          	lui	a1,0x4000
    80001c2a:	15fd                	addi	a1,a1,-1
    80001c2c:	05b2                	slli	a1,a1,0xc
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	73e080e7          	jalr	1854(ra) # 8000136c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c36:	4681                	li	a3,0
    80001c38:	4605                	li	a2,1
    80001c3a:	020005b7          	lui	a1,0x2000
    80001c3e:	15fd                	addi	a1,a1,-1
    80001c40:	05b6                	slli	a1,a1,0xd
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	728080e7          	jalr	1832(ra) # 8000136c <uvmunmap>
  uvmfree(pagetable, sz);
    80001c4c:	85ca                	mv	a1,s2
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	9e4080e7          	jalr	-1564(ra) # 80001634 <uvmfree>
}
    80001c58:	60e2                	ld	ra,24(sp)
    80001c5a:	6442                	ld	s0,16(sp)
    80001c5c:	64a2                	ld	s1,8(sp)
    80001c5e:	6902                	ld	s2,0(sp)
    80001c60:	6105                	addi	sp,sp,32
    80001c62:	8082                	ret

0000000080001c64 <freeproc>:
{
    80001c64:	1101                	addi	sp,sp,-32
    80001c66:	ec06                	sd	ra,24(sp)
    80001c68:	e822                	sd	s0,16(sp)
    80001c6a:	e426                	sd	s1,8(sp)
    80001c6c:	1000                	addi	s0,sp,32
    80001c6e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c70:	6d28                	ld	a0,88(a0)
    80001c72:	c509                	beqz	a0,80001c7c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	d8a080e7          	jalr	-630(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001c7c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c80:	68a8                	ld	a0,80(s1)
    80001c82:	c511                	beqz	a0,80001c8e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c84:	64ac                	ld	a1,72(s1)
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	f8c080e7          	jalr	-116(ra) # 80001c12 <proc_freepagetable>
  p->pagetable = 0;
    80001c8e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c92:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c96:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c9a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c9e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ca2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ca6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001caa:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cae:	0004ac23          	sw	zero,24(s1)
}
    80001cb2:	60e2                	ld	ra,24(sp)
    80001cb4:	6442                	ld	s0,16(sp)
    80001cb6:	64a2                	ld	s1,8(sp)
    80001cb8:	6105                	addi	sp,sp,32
    80001cba:	8082                	ret

0000000080001cbc <allocproc>:
{
    80001cbc:	1101                	addi	sp,sp,-32
    80001cbe:	ec06                	sd	ra,24(sp)
    80001cc0:	e822                	sd	s0,16(sp)
    80001cc2:	e426                	sd	s1,8(sp)
    80001cc4:	e04a                	sd	s2,0(sp)
    80001cc6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc8:	0000f497          	auipc	s1,0xf
    80001ccc:	2e848493          	addi	s1,s1,744 # 80010fb0 <proc>
    80001cd0:	00015917          	auipc	s2,0x15
    80001cd4:	ce090913          	addi	s2,s2,-800 # 800169b0 <tickslock>
    acquire(&p->lock);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	f10080e7          	jalr	-240(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001ce2:	4c9c                	lw	a5,24(s1)
    80001ce4:	cf81                	beqz	a5,80001cfc <allocproc+0x40>
      release(&p->lock);
    80001ce6:	8526                	mv	a0,s1
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	fb6080e7          	jalr	-74(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf0:	16848493          	addi	s1,s1,360
    80001cf4:	ff2492e3          	bne	s1,s2,80001cd8 <allocproc+0x1c>
  return 0;
    80001cf8:	4481                	li	s1,0
    80001cfa:	a889                	j	80001d4c <allocproc+0x90>
  p->pid = allocpid();
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	e34080e7          	jalr	-460(ra) # 80001b30 <allocpid>
    80001d04:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d06:	4785                	li	a5,1
    80001d08:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	df0080e7          	jalr	-528(ra) # 80000afa <kalloc>
    80001d12:	892a                	mv	s2,a0
    80001d14:	eca8                	sd	a0,88(s1)
    80001d16:	c131                	beqz	a0,80001d5a <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	e5c080e7          	jalr	-420(ra) # 80001b76 <proc_pagetable>
    80001d22:	892a                	mv	s2,a0
    80001d24:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d26:	c531                	beqz	a0,80001d72 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d28:	07000613          	li	a2,112
    80001d2c:	4581                	li	a1,0
    80001d2e:	06048513          	addi	a0,s1,96
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	fb4080e7          	jalr	-76(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001d3a:	00000797          	auipc	a5,0x0
    80001d3e:	db078793          	addi	a5,a5,-592 # 80001aea <forkret>
    80001d42:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d44:	60bc                	ld	a5,64(s1)
    80001d46:	6705                	lui	a4,0x1
    80001d48:	97ba                	add	a5,a5,a4
    80001d4a:	f4bc                	sd	a5,104(s1)
}
    80001d4c:	8526                	mv	a0,s1
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    freeproc(p);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	f08080e7          	jalr	-248(ra) # 80001c64 <freeproc>
    release(&p->lock);
    80001d64:	8526                	mv	a0,s1
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	f38080e7          	jalr	-200(ra) # 80000c9e <release>
    return 0;
    80001d6e:	84ca                	mv	s1,s2
    80001d70:	bff1                	j	80001d4c <allocproc+0x90>
    freeproc(p);
    80001d72:	8526                	mv	a0,s1
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	ef0080e7          	jalr	-272(ra) # 80001c64 <freeproc>
    release(&p->lock);
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	f20080e7          	jalr	-224(ra) # 80000c9e <release>
    return 0;
    80001d86:	84ca                	mv	s1,s2
    80001d88:	b7d1                	j	80001d4c <allocproc+0x90>

0000000080001d8a <userinit>:
{
    80001d8a:	1101                	addi	sp,sp,-32
    80001d8c:	ec06                	sd	ra,24(sp)
    80001d8e:	e822                	sd	s0,16(sp)
    80001d90:	e426                	sd	s1,8(sp)
    80001d92:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	f28080e7          	jalr	-216(ra) # 80001cbc <allocproc>
    80001d9c:	84aa                	mv	s1,a0
  initproc = p;
    80001d9e:	00007797          	auipc	a5,0x7
    80001da2:	b6a7b523          	sd	a0,-1174(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001da6:	03400613          	li	a2,52
    80001daa:	00007597          	auipc	a1,0x7
    80001dae:	ad658593          	addi	a1,a1,-1322 # 80008880 <initcode>
    80001db2:	6928                	ld	a0,80(a0)
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	6aa080e7          	jalr	1706(ra) # 8000145e <uvmfirst>
  p->sz = PGSIZE;
    80001dbc:	6785                	lui	a5,0x1
    80001dbe:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dc0:	6cb8                	ld	a4,88(s1)
    80001dc2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dc6:	6cb8                	ld	a4,88(s1)
    80001dc8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dca:	4641                	li	a2,16
    80001dcc:	00006597          	auipc	a1,0x6
    80001dd0:	46458593          	addi	a1,a1,1124 # 80008230 <digits+0x1f0>
    80001dd4:	15848513          	addi	a0,s1,344
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	060080e7          	jalr	96(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001de0:	00006517          	auipc	a0,0x6
    80001de4:	46050513          	addi	a0,a0,1120 # 80008240 <digits+0x200>
    80001de8:	00002097          	auipc	ra,0x2
    80001dec:	108080e7          	jalr	264(ra) # 80003ef0 <namei>
    80001df0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001df4:	478d                	li	a5,3
    80001df6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001df8:	8526                	mv	a0,s1
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	ea4080e7          	jalr	-348(ra) # 80000c9e <release>
}
    80001e02:	60e2                	ld	ra,24(sp)
    80001e04:	6442                	ld	s0,16(sp)
    80001e06:	64a2                	ld	s1,8(sp)
    80001e08:	6105                	addi	sp,sp,32
    80001e0a:	8082                	ret

0000000080001e0c <growproc>:
{
    80001e0c:	1101                	addi	sp,sp,-32
    80001e0e:	ec06                	sd	ra,24(sp)
    80001e10:	e822                	sd	s0,16(sp)
    80001e12:	e426                	sd	s1,8(sp)
    80001e14:	e04a                	sd	s2,0(sp)
    80001e16:	1000                	addi	s0,sp,32
    80001e18:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	c98080e7          	jalr	-872(ra) # 80001ab2 <myproc>
    80001e22:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e24:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e26:	01204c63          	bgtz	s2,80001e3e <growproc+0x32>
  } else if(n < 0){
    80001e2a:	02094663          	bltz	s2,80001e56 <growproc+0x4a>
  p->sz = sz;
    80001e2e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e30:	4501                	li	a0,0
}
    80001e32:	60e2                	ld	ra,24(sp)
    80001e34:	6442                	ld	s0,16(sp)
    80001e36:	64a2                	ld	s1,8(sp)
    80001e38:	6902                	ld	s2,0(sp)
    80001e3a:	6105                	addi	sp,sp,32
    80001e3c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e3e:	4691                	li	a3,4
    80001e40:	00b90633          	add	a2,s2,a1
    80001e44:	6928                	ld	a0,80(a0)
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	6d2080e7          	jalr	1746(ra) # 80001518 <uvmalloc>
    80001e4e:	85aa                	mv	a1,a0
    80001e50:	fd79                	bnez	a0,80001e2e <growproc+0x22>
      return -1;
    80001e52:	557d                	li	a0,-1
    80001e54:	bff9                	j	80001e32 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e56:	00b90633          	add	a2,s2,a1
    80001e5a:	6928                	ld	a0,80(a0)
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	674080e7          	jalr	1652(ra) # 800014d0 <uvmdealloc>
    80001e64:	85aa                	mv	a1,a0
    80001e66:	b7e1                	j	80001e2e <growproc+0x22>

0000000080001e68 <fork>:
{
    80001e68:	7179                	addi	sp,sp,-48
    80001e6a:	f406                	sd	ra,40(sp)
    80001e6c:	f022                	sd	s0,32(sp)
    80001e6e:	ec26                	sd	s1,24(sp)
    80001e70:	e84a                	sd	s2,16(sp)
    80001e72:	e44e                	sd	s3,8(sp)
    80001e74:	e052                	sd	s4,0(sp)
    80001e76:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e78:	00000097          	auipc	ra,0x0
    80001e7c:	c3a080e7          	jalr	-966(ra) # 80001ab2 <myproc>
    80001e80:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	e3a080e7          	jalr	-454(ra) # 80001cbc <allocproc>
    80001e8a:	10050b63          	beqz	a0,80001fa0 <fork+0x138>
    80001e8e:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e90:	04893603          	ld	a2,72(s2)
    80001e94:	692c                	ld	a1,80(a0)
    80001e96:	05093503          	ld	a0,80(s2)
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	7d2080e7          	jalr	2002(ra) # 8000166c <uvmcopy>
    80001ea2:	04054663          	bltz	a0,80001eee <fork+0x86>
  np->sz = p->sz;
    80001ea6:	04893783          	ld	a5,72(s2)
    80001eaa:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001eae:	05893683          	ld	a3,88(s2)
    80001eb2:	87b6                	mv	a5,a3
    80001eb4:	0589b703          	ld	a4,88(s3)
    80001eb8:	12068693          	addi	a3,a3,288
    80001ebc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ec0:	6788                	ld	a0,8(a5)
    80001ec2:	6b8c                	ld	a1,16(a5)
    80001ec4:	6f90                	ld	a2,24(a5)
    80001ec6:	01073023          	sd	a6,0(a4)
    80001eca:	e708                	sd	a0,8(a4)
    80001ecc:	eb0c                	sd	a1,16(a4)
    80001ece:	ef10                	sd	a2,24(a4)
    80001ed0:	02078793          	addi	a5,a5,32
    80001ed4:	02070713          	addi	a4,a4,32
    80001ed8:	fed792e3          	bne	a5,a3,80001ebc <fork+0x54>
  np->trapframe->a0 = 0;
    80001edc:	0589b783          	ld	a5,88(s3)
    80001ee0:	0607b823          	sd	zero,112(a5)
    80001ee4:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ee8:	15000a13          	li	s4,336
    80001eec:	a03d                	j	80001f1a <fork+0xb2>
    freeproc(np);
    80001eee:	854e                	mv	a0,s3
    80001ef0:	00000097          	auipc	ra,0x0
    80001ef4:	d74080e7          	jalr	-652(ra) # 80001c64 <freeproc>
    release(&np->lock);
    80001ef8:	854e                	mv	a0,s3
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	da4080e7          	jalr	-604(ra) # 80000c9e <release>
    return -1;
    80001f02:	5a7d                	li	s4,-1
    80001f04:	a069                	j	80001f8e <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f06:	00002097          	auipc	ra,0x2
    80001f0a:	680080e7          	jalr	1664(ra) # 80004586 <filedup>
    80001f0e:	009987b3          	add	a5,s3,s1
    80001f12:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f14:	04a1                	addi	s1,s1,8
    80001f16:	01448763          	beq	s1,s4,80001f24 <fork+0xbc>
    if(p->ofile[i])
    80001f1a:	009907b3          	add	a5,s2,s1
    80001f1e:	6388                	ld	a0,0(a5)
    80001f20:	f17d                	bnez	a0,80001f06 <fork+0x9e>
    80001f22:	bfcd                	j	80001f14 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f24:	15093503          	ld	a0,336(s2)
    80001f28:	00001097          	auipc	ra,0x1
    80001f2c:	7e4080e7          	jalr	2020(ra) # 8000370c <idup>
    80001f30:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f34:	4641                	li	a2,16
    80001f36:	15890593          	addi	a1,s2,344
    80001f3a:	15898513          	addi	a0,s3,344
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	efa080e7          	jalr	-262(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001f46:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f4a:	854e                	mv	a0,s3
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	d52080e7          	jalr	-686(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001f54:	0000f497          	auipc	s1,0xf
    80001f58:	c4448493          	addi	s1,s1,-956 # 80010b98 <wait_lock>
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	c8c080e7          	jalr	-884(ra) # 80000bea <acquire>
  np->parent = p;
    80001f66:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	d32080e7          	jalr	-718(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001f74:	854e                	mv	a0,s3
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	c74080e7          	jalr	-908(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001f7e:	478d                	li	a5,3
    80001f80:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f84:	854e                	mv	a0,s3
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d18080e7          	jalr	-744(ra) # 80000c9e <release>
}
    80001f8e:	8552                	mv	a0,s4
    80001f90:	70a2                	ld	ra,40(sp)
    80001f92:	7402                	ld	s0,32(sp)
    80001f94:	64e2                	ld	s1,24(sp)
    80001f96:	6942                	ld	s2,16(sp)
    80001f98:	69a2                	ld	s3,8(sp)
    80001f9a:	6a02                	ld	s4,0(sp)
    80001f9c:	6145                	addi	sp,sp,48
    80001f9e:	8082                	ret
    return -1;
    80001fa0:	5a7d                	li	s4,-1
    80001fa2:	b7f5                	j	80001f8e <fork+0x126>

0000000080001fa4 <scheduler>:
{
    80001fa4:	7139                	addi	sp,sp,-64
    80001fa6:	fc06                	sd	ra,56(sp)
    80001fa8:	f822                	sd	s0,48(sp)
    80001faa:	f426                	sd	s1,40(sp)
    80001fac:	f04a                	sd	s2,32(sp)
    80001fae:	ec4e                	sd	s3,24(sp)
    80001fb0:	e852                	sd	s4,16(sp)
    80001fb2:	e456                	sd	s5,8(sp)
    80001fb4:	e05a                	sd	s6,0(sp)
    80001fb6:	0080                	addi	s0,sp,64
    80001fb8:	8792                	mv	a5,tp
  int id = r_tp();
    80001fba:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fbc:	00779a93          	slli	s5,a5,0x7
    80001fc0:	0000f717          	auipc	a4,0xf
    80001fc4:	bc070713          	addi	a4,a4,-1088 # 80010b80 <pid_lock>
    80001fc8:	9756                	add	a4,a4,s5
    80001fca:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fce:	0000f717          	auipc	a4,0xf
    80001fd2:	bea70713          	addi	a4,a4,-1046 # 80010bb8 <cpus+0x8>
    80001fd6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fd8:	498d                	li	s3,3
        p->state = RUNNING;
    80001fda:	4b11                	li	s6,4
        c->proc = p;
    80001fdc:	079e                	slli	a5,a5,0x7
    80001fde:	0000fa17          	auipc	s4,0xf
    80001fe2:	ba2a0a13          	addi	s4,s4,-1118 # 80010b80 <pid_lock>
    80001fe6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe8:	00015917          	auipc	s2,0x15
    80001fec:	9c890913          	addi	s2,s2,-1592 # 800169b0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff8:	10079073          	csrw	sstatus,a5
    80001ffc:	0000f497          	auipc	s1,0xf
    80002000:	fb448493          	addi	s1,s1,-76 # 80010fb0 <proc>
    80002004:	a03d                	j	80002032 <scheduler+0x8e>
        p->state = RUNNING;
    80002006:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000200a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000200e:	06048593          	addi	a1,s1,96
    80002012:	8556                	mv	a0,s5
    80002014:	00000097          	auipc	ra,0x0
    80002018:	6a4080e7          	jalr	1700(ra) # 800026b8 <swtch>
        c->proc = 0;
    8000201c:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80002020:	8526                	mv	a0,s1
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	c7c080e7          	jalr	-900(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000202a:	16848493          	addi	s1,s1,360
    8000202e:	fd2481e3          	beq	s1,s2,80001ff0 <scheduler+0x4c>
      acquire(&p->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	bb6080e7          	jalr	-1098(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    8000203c:	4c9c                	lw	a5,24(s1)
    8000203e:	ff3791e3          	bne	a5,s3,80002020 <scheduler+0x7c>
    80002042:	b7d1                	j	80002006 <scheduler+0x62>

0000000080002044 <sched>:
{
    80002044:	7179                	addi	sp,sp,-48
    80002046:	f406                	sd	ra,40(sp)
    80002048:	f022                	sd	s0,32(sp)
    8000204a:	ec26                	sd	s1,24(sp)
    8000204c:	e84a                	sd	s2,16(sp)
    8000204e:	e44e                	sd	s3,8(sp)
    80002050:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	a60080e7          	jalr	-1440(ra) # 80001ab2 <myproc>
    8000205a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	b14080e7          	jalr	-1260(ra) # 80000b70 <holding>
    80002064:	c93d                	beqz	a0,800020da <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002066:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	0000f717          	auipc	a4,0xf
    80002070:	b1470713          	addi	a4,a4,-1260 # 80010b80 <pid_lock>
    80002074:	97ba                	add	a5,a5,a4
    80002076:	0a87a703          	lw	a4,168(a5)
    8000207a:	4785                	li	a5,1
    8000207c:	06f71763          	bne	a4,a5,800020ea <sched+0xa6>
  if(p->state == RUNNING)
    80002080:	4c98                	lw	a4,24(s1)
    80002082:	4791                	li	a5,4
    80002084:	06f70b63          	beq	a4,a5,800020fa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000208c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000208e:	efb5                	bnez	a5,8000210a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002090:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002092:	0000f917          	auipc	s2,0xf
    80002096:	aee90913          	addi	s2,s2,-1298 # 80010b80 <pid_lock>
    8000209a:	2781                	sext.w	a5,a5
    8000209c:	079e                	slli	a5,a5,0x7
    8000209e:	97ca                	add	a5,a5,s2
    800020a0:	0ac7a983          	lw	s3,172(a5)
    800020a4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020a6:	2781                	sext.w	a5,a5
    800020a8:	079e                	slli	a5,a5,0x7
    800020aa:	0000f597          	auipc	a1,0xf
    800020ae:	b0e58593          	addi	a1,a1,-1266 # 80010bb8 <cpus+0x8>
    800020b2:	95be                	add	a1,a1,a5
    800020b4:	06048513          	addi	a0,s1,96
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	600080e7          	jalr	1536(ra) # 800026b8 <swtch>
    800020c0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	97ca                	add	a5,a5,s2
    800020c8:	0b37a623          	sw	s3,172(a5)
}
    800020cc:	70a2                	ld	ra,40(sp)
    800020ce:	7402                	ld	s0,32(sp)
    800020d0:	64e2                	ld	s1,24(sp)
    800020d2:	6942                	ld	s2,16(sp)
    800020d4:	69a2                	ld	s3,8(sp)
    800020d6:	6145                	addi	sp,sp,48
    800020d8:	8082                	ret
    panic("sched p->lock");
    800020da:	00006517          	auipc	a0,0x6
    800020de:	16e50513          	addi	a0,a0,366 # 80008248 <digits+0x208>
    800020e2:	ffffe097          	auipc	ra,0xffffe
    800020e6:	462080e7          	jalr	1122(ra) # 80000544 <panic>
    panic("sched locks");
    800020ea:	00006517          	auipc	a0,0x6
    800020ee:	16e50513          	addi	a0,a0,366 # 80008258 <digits+0x218>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	452080e7          	jalr	1106(ra) # 80000544 <panic>
    panic("sched running");
    800020fa:	00006517          	auipc	a0,0x6
    800020fe:	16e50513          	addi	a0,a0,366 # 80008268 <digits+0x228>
    80002102:	ffffe097          	auipc	ra,0xffffe
    80002106:	442080e7          	jalr	1090(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000210a:	00006517          	auipc	a0,0x6
    8000210e:	16e50513          	addi	a0,a0,366 # 80008278 <digits+0x238>
    80002112:	ffffe097          	auipc	ra,0xffffe
    80002116:	432080e7          	jalr	1074(ra) # 80000544 <panic>

000000008000211a <yield>:
{
    8000211a:	1101                	addi	sp,sp,-32
    8000211c:	ec06                	sd	ra,24(sp)
    8000211e:	e822                	sd	s0,16(sp)
    80002120:	e426                	sd	s1,8(sp)
    80002122:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002124:	00000097          	auipc	ra,0x0
    80002128:	98e080e7          	jalr	-1650(ra) # 80001ab2 <myproc>
    8000212c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	abc080e7          	jalr	-1348(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002136:	478d                	li	a5,3
    80002138:	cc9c                	sw	a5,24(s1)
  sched();
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	f0a080e7          	jalr	-246(ra) # 80002044 <sched>
  release(&p->lock);
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	b5a080e7          	jalr	-1190(ra) # 80000c9e <release>
}
    8000214c:	60e2                	ld	ra,24(sp)
    8000214e:	6442                	ld	s0,16(sp)
    80002150:	64a2                	ld	s1,8(sp)
    80002152:	6105                	addi	sp,sp,32
    80002154:	8082                	ret

0000000080002156 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002156:	7179                	addi	sp,sp,-48
    80002158:	f406                	sd	ra,40(sp)
    8000215a:	f022                	sd	s0,32(sp)
    8000215c:	ec26                	sd	s1,24(sp)
    8000215e:	e84a                	sd	s2,16(sp)
    80002160:	e44e                	sd	s3,8(sp)
    80002162:	1800                	addi	s0,sp,48
    80002164:	89aa                	mv	s3,a0
    80002166:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	94a080e7          	jalr	-1718(ra) # 80001ab2 <myproc>
    80002170:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	a78080e7          	jalr	-1416(ra) # 80000bea <acquire>
  release(lk);
    8000217a:	854a                	mv	a0,s2
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	b22080e7          	jalr	-1246(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002184:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002188:	4789                	li	a5,2
    8000218a:	cc9c                	sw	a5,24(s1)

  sched();
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	eb8080e7          	jalr	-328(ra) # 80002044 <sched>

  // Tidy up.
  p->chan = 0;
    80002194:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	b04080e7          	jalr	-1276(ra) # 80000c9e <release>
  acquire(lk);
    800021a2:	854a                	mv	a0,s2
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	a46080e7          	jalr	-1466(ra) # 80000bea <acquire>
}
    800021ac:	70a2                	ld	ra,40(sp)
    800021ae:	7402                	ld	s0,32(sp)
    800021b0:	64e2                	ld	s1,24(sp)
    800021b2:	6942                	ld	s2,16(sp)
    800021b4:	69a2                	ld	s3,8(sp)
    800021b6:	6145                	addi	sp,sp,48
    800021b8:	8082                	ret

00000000800021ba <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021ba:	7139                	addi	sp,sp,-64
    800021bc:	fc06                	sd	ra,56(sp)
    800021be:	f822                	sd	s0,48(sp)
    800021c0:	f426                	sd	s1,40(sp)
    800021c2:	f04a                	sd	s2,32(sp)
    800021c4:	ec4e                	sd	s3,24(sp)
    800021c6:	e852                	sd	s4,16(sp)
    800021c8:	e456                	sd	s5,8(sp)
    800021ca:	0080                	addi	s0,sp,64
    800021cc:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021ce:	0000f497          	auipc	s1,0xf
    800021d2:	de248493          	addi	s1,s1,-542 # 80010fb0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021d6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021d8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021da:	00014917          	auipc	s2,0x14
    800021de:	7d690913          	addi	s2,s2,2006 # 800169b0 <tickslock>
    800021e2:	a821                	j	800021fa <wakeup+0x40>
        p->state = RUNNABLE;
    800021e4:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	ab4080e7          	jalr	-1356(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021f2:	16848493          	addi	s1,s1,360
    800021f6:	03248463          	beq	s1,s2,8000221e <wakeup+0x64>
    if(p != myproc()){
    800021fa:	00000097          	auipc	ra,0x0
    800021fe:	8b8080e7          	jalr	-1864(ra) # 80001ab2 <myproc>
    80002202:	fea488e3          	beq	s1,a0,800021f2 <wakeup+0x38>
      acquire(&p->lock);
    80002206:	8526                	mv	a0,s1
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	9e2080e7          	jalr	-1566(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002210:	4c9c                	lw	a5,24(s1)
    80002212:	fd379be3          	bne	a5,s3,800021e8 <wakeup+0x2e>
    80002216:	709c                	ld	a5,32(s1)
    80002218:	fd4798e3          	bne	a5,s4,800021e8 <wakeup+0x2e>
    8000221c:	b7e1                	j	800021e4 <wakeup+0x2a>
    }
  }
}
    8000221e:	70e2                	ld	ra,56(sp)
    80002220:	7442                	ld	s0,48(sp)
    80002222:	74a2                	ld	s1,40(sp)
    80002224:	7902                	ld	s2,32(sp)
    80002226:	69e2                	ld	s3,24(sp)
    80002228:	6a42                	ld	s4,16(sp)
    8000222a:	6aa2                	ld	s5,8(sp)
    8000222c:	6121                	addi	sp,sp,64
    8000222e:	8082                	ret

0000000080002230 <reparent>:
{
    80002230:	7179                	addi	sp,sp,-48
    80002232:	f406                	sd	ra,40(sp)
    80002234:	f022                	sd	s0,32(sp)
    80002236:	ec26                	sd	s1,24(sp)
    80002238:	e84a                	sd	s2,16(sp)
    8000223a:	e44e                	sd	s3,8(sp)
    8000223c:	e052                	sd	s4,0(sp)
    8000223e:	1800                	addi	s0,sp,48
    80002240:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002242:	0000f497          	auipc	s1,0xf
    80002246:	d6e48493          	addi	s1,s1,-658 # 80010fb0 <proc>
      pp->parent = initproc;
    8000224a:	00006a17          	auipc	s4,0x6
    8000224e:	6bea0a13          	addi	s4,s4,1726 # 80008908 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002252:	00014997          	auipc	s3,0x14
    80002256:	75e98993          	addi	s3,s3,1886 # 800169b0 <tickslock>
    8000225a:	a029                	j	80002264 <reparent+0x34>
    8000225c:	16848493          	addi	s1,s1,360
    80002260:	01348d63          	beq	s1,s3,8000227a <reparent+0x4a>
    if(pp->parent == p){
    80002264:	7c9c                	ld	a5,56(s1)
    80002266:	ff279be3          	bne	a5,s2,8000225c <reparent+0x2c>
      pp->parent = initproc;
    8000226a:	000a3503          	ld	a0,0(s4)
    8000226e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002270:	00000097          	auipc	ra,0x0
    80002274:	f4a080e7          	jalr	-182(ra) # 800021ba <wakeup>
    80002278:	b7d5                	j	8000225c <reparent+0x2c>
}
    8000227a:	70a2                	ld	ra,40(sp)
    8000227c:	7402                	ld	s0,32(sp)
    8000227e:	64e2                	ld	s1,24(sp)
    80002280:	6942                	ld	s2,16(sp)
    80002282:	69a2                	ld	s3,8(sp)
    80002284:	6a02                	ld	s4,0(sp)
    80002286:	6145                	addi	sp,sp,48
    80002288:	8082                	ret

000000008000228a <exit>:
{
    8000228a:	7179                	addi	sp,sp,-48
    8000228c:	f406                	sd	ra,40(sp)
    8000228e:	f022                	sd	s0,32(sp)
    80002290:	ec26                	sd	s1,24(sp)
    80002292:	e84a                	sd	s2,16(sp)
    80002294:	e44e                	sd	s3,8(sp)
    80002296:	e052                	sd	s4,0(sp)
    80002298:	1800                	addi	s0,sp,48
    8000229a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	816080e7          	jalr	-2026(ra) # 80001ab2 <myproc>
    800022a4:	89aa                	mv	s3,a0
  if(p == initproc)
    800022a6:	00006797          	auipc	a5,0x6
    800022aa:	6627b783          	ld	a5,1634(a5) # 80008908 <initproc>
    800022ae:	0d050493          	addi	s1,a0,208
    800022b2:	15050913          	addi	s2,a0,336
    800022b6:	02a79363          	bne	a5,a0,800022dc <exit+0x52>
    panic("init exiting");
    800022ba:	00006517          	auipc	a0,0x6
    800022be:	fd650513          	addi	a0,a0,-42 # 80008290 <digits+0x250>
    800022c2:	ffffe097          	auipc	ra,0xffffe
    800022c6:	282080e7          	jalr	642(ra) # 80000544 <panic>
      fileclose(f);
    800022ca:	00002097          	auipc	ra,0x2
    800022ce:	30e080e7          	jalr	782(ra) # 800045d8 <fileclose>
      p->ofile[fd] = 0;
    800022d2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022d6:	04a1                	addi	s1,s1,8
    800022d8:	01248563          	beq	s1,s2,800022e2 <exit+0x58>
    if(p->ofile[fd]){
    800022dc:	6088                	ld	a0,0(s1)
    800022de:	f575                	bnez	a0,800022ca <exit+0x40>
    800022e0:	bfdd                	j	800022d6 <exit+0x4c>
  begin_op();
    800022e2:	00002097          	auipc	ra,0x2
    800022e6:	e2a080e7          	jalr	-470(ra) # 8000410c <begin_op>
  iput(p->cwd);
    800022ea:	1509b503          	ld	a0,336(s3)
    800022ee:	00001097          	auipc	ra,0x1
    800022f2:	616080e7          	jalr	1558(ra) # 80003904 <iput>
  end_op();
    800022f6:	00002097          	auipc	ra,0x2
    800022fa:	e96080e7          	jalr	-362(ra) # 8000418c <end_op>
  p->cwd = 0;
    800022fe:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002302:	0000f497          	auipc	s1,0xf
    80002306:	89648493          	addi	s1,s1,-1898 # 80010b98 <wait_lock>
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	8de080e7          	jalr	-1826(ra) # 80000bea <acquire>
  reparent(p);
    80002314:	854e                	mv	a0,s3
    80002316:	00000097          	auipc	ra,0x0
    8000231a:	f1a080e7          	jalr	-230(ra) # 80002230 <reparent>
  wakeup(p->parent);
    8000231e:	0389b503          	ld	a0,56(s3)
    80002322:	00000097          	auipc	ra,0x0
    80002326:	e98080e7          	jalr	-360(ra) # 800021ba <wakeup>
  acquire(&p->lock);
    8000232a:	854e                	mv	a0,s3
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	8be080e7          	jalr	-1858(ra) # 80000bea <acquire>
  p->xstate = status;
    80002334:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002338:	4795                	li	a5,5
    8000233a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	95e080e7          	jalr	-1698(ra) # 80000c9e <release>
  sched();
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	cfc080e7          	jalr	-772(ra) # 80002044 <sched>
  panic("zombie exit");
    80002350:	00006517          	auipc	a0,0x6
    80002354:	f5050513          	addi	a0,a0,-176 # 800082a0 <digits+0x260>
    80002358:	ffffe097          	auipc	ra,0xffffe
    8000235c:	1ec080e7          	jalr	492(ra) # 80000544 <panic>

0000000080002360 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002360:	7179                	addi	sp,sp,-48
    80002362:	f406                	sd	ra,40(sp)
    80002364:	f022                	sd	s0,32(sp)
    80002366:	ec26                	sd	s1,24(sp)
    80002368:	e84a                	sd	s2,16(sp)
    8000236a:	e44e                	sd	s3,8(sp)
    8000236c:	1800                	addi	s0,sp,48
    8000236e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002370:	0000f497          	auipc	s1,0xf
    80002374:	c4048493          	addi	s1,s1,-960 # 80010fb0 <proc>
    80002378:	00014997          	auipc	s3,0x14
    8000237c:	63898993          	addi	s3,s3,1592 # 800169b0 <tickslock>
    acquire(&p->lock);
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	868080e7          	jalr	-1944(ra) # 80000bea <acquire>
    if(p->pid == pid){
    8000238a:	589c                	lw	a5,48(s1)
    8000238c:	01278d63          	beq	a5,s2,800023a6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	90c080e7          	jalr	-1780(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000239a:	16848493          	addi	s1,s1,360
    8000239e:	ff3491e3          	bne	s1,s3,80002380 <kill+0x20>
  }
  return -1;
    800023a2:	557d                	li	a0,-1
    800023a4:	a829                	j	800023be <kill+0x5e>
      p->killed = 1;
    800023a6:	4785                	li	a5,1
    800023a8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023aa:	4c98                	lw	a4,24(s1)
    800023ac:	4789                	li	a5,2
    800023ae:	00f70f63          	beq	a4,a5,800023cc <kill+0x6c>
      release(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8ea080e7          	jalr	-1814(ra) # 80000c9e <release>
      return 0;
    800023bc:	4501                	li	a0,0
}
    800023be:	70a2                	ld	ra,40(sp)
    800023c0:	7402                	ld	s0,32(sp)
    800023c2:	64e2                	ld	s1,24(sp)
    800023c4:	6942                	ld	s2,16(sp)
    800023c6:	69a2                	ld	s3,8(sp)
    800023c8:	6145                	addi	sp,sp,48
    800023ca:	8082                	ret
        p->state = RUNNABLE;
    800023cc:	478d                	li	a5,3
    800023ce:	cc9c                	sw	a5,24(s1)
    800023d0:	b7cd                	j	800023b2 <kill+0x52>

00000000800023d2 <setkilled>:

void
setkilled(struct proc *p)
{
    800023d2:	1101                	addi	sp,sp,-32
    800023d4:	ec06                	sd	ra,24(sp)
    800023d6:	e822                	sd	s0,16(sp)
    800023d8:	e426                	sd	s1,8(sp)
    800023da:	1000                	addi	s0,sp,32
    800023dc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	80c080e7          	jalr	-2036(ra) # 80000bea <acquire>
  p->killed = 1;
    800023e6:	4785                	li	a5,1
    800023e8:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	8b2080e7          	jalr	-1870(ra) # 80000c9e <release>
}
    800023f4:	60e2                	ld	ra,24(sp)
    800023f6:	6442                	ld	s0,16(sp)
    800023f8:	64a2                	ld	s1,8(sp)
    800023fa:	6105                	addi	sp,sp,32
    800023fc:	8082                	ret

00000000800023fe <killed>:

int
killed(struct proc *p)
{
    800023fe:	1101                	addi	sp,sp,-32
    80002400:	ec06                	sd	ra,24(sp)
    80002402:	e822                	sd	s0,16(sp)
    80002404:	e426                	sd	s1,8(sp)
    80002406:	e04a                	sd	s2,0(sp)
    80002408:	1000                	addi	s0,sp,32
    8000240a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000240c:	ffffe097          	auipc	ra,0xffffe
    80002410:	7de080e7          	jalr	2014(ra) # 80000bea <acquire>
  k = p->killed;
    80002414:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	884080e7          	jalr	-1916(ra) # 80000c9e <release>
  return k;
}
    80002422:	854a                	mv	a0,s2
    80002424:	60e2                	ld	ra,24(sp)
    80002426:	6442                	ld	s0,16(sp)
    80002428:	64a2                	ld	s1,8(sp)
    8000242a:	6902                	ld	s2,0(sp)
    8000242c:	6105                	addi	sp,sp,32
    8000242e:	8082                	ret

0000000080002430 <wait>:
{
    80002430:	715d                	addi	sp,sp,-80
    80002432:	e486                	sd	ra,72(sp)
    80002434:	e0a2                	sd	s0,64(sp)
    80002436:	fc26                	sd	s1,56(sp)
    80002438:	f84a                	sd	s2,48(sp)
    8000243a:	f44e                	sd	s3,40(sp)
    8000243c:	f052                	sd	s4,32(sp)
    8000243e:	ec56                	sd	s5,24(sp)
    80002440:	e85a                	sd	s6,16(sp)
    80002442:	e45e                	sd	s7,8(sp)
    80002444:	e062                	sd	s8,0(sp)
    80002446:	0880                	addi	s0,sp,80
    80002448:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	668080e7          	jalr	1640(ra) # 80001ab2 <myproc>
    80002452:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002454:	0000e517          	auipc	a0,0xe
    80002458:	74450513          	addi	a0,a0,1860 # 80010b98 <wait_lock>
    8000245c:	ffffe097          	auipc	ra,0xffffe
    80002460:	78e080e7          	jalr	1934(ra) # 80000bea <acquire>
    havekids = 0;
    80002464:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002466:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002468:	00014997          	auipc	s3,0x14
    8000246c:	54898993          	addi	s3,s3,1352 # 800169b0 <tickslock>
        havekids = 1;
    80002470:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002472:	0000ec17          	auipc	s8,0xe
    80002476:	726c0c13          	addi	s8,s8,1830 # 80010b98 <wait_lock>
    havekids = 0;
    8000247a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000247c:	0000f497          	auipc	s1,0xf
    80002480:	b3448493          	addi	s1,s1,-1228 # 80010fb0 <proc>
    80002484:	a0bd                	j	800024f2 <wait+0xc2>
          pid = pp->pid;
    80002486:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000248a:	000b0e63          	beqz	s6,800024a6 <wait+0x76>
    8000248e:	4691                	li	a3,4
    80002490:	02c48613          	addi	a2,s1,44
    80002494:	85da                	mv	a1,s6
    80002496:	05093503          	ld	a0,80(s2)
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	2d6080e7          	jalr	726(ra) # 80001770 <copyout>
    800024a2:	02054563          	bltz	a0,800024cc <wait+0x9c>
          freeproc(pp);
    800024a6:	8526                	mv	a0,s1
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	7bc080e7          	jalr	1980(ra) # 80001c64 <freeproc>
          release(&pp->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7ec080e7          	jalr	2028(ra) # 80000c9e <release>
          release(&wait_lock);
    800024ba:	0000e517          	auipc	a0,0xe
    800024be:	6de50513          	addi	a0,a0,1758 # 80010b98 <wait_lock>
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7dc080e7          	jalr	2012(ra) # 80000c9e <release>
          return pid;
    800024ca:	a0b5                	j	80002536 <wait+0x106>
            release(&pp->lock);
    800024cc:	8526                	mv	a0,s1
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	7d0080e7          	jalr	2000(ra) # 80000c9e <release>
            release(&wait_lock);
    800024d6:	0000e517          	auipc	a0,0xe
    800024da:	6c250513          	addi	a0,a0,1730 # 80010b98 <wait_lock>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7c0080e7          	jalr	1984(ra) # 80000c9e <release>
            return -1;
    800024e6:	59fd                	li	s3,-1
    800024e8:	a0b9                	j	80002536 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ea:	16848493          	addi	s1,s1,360
    800024ee:	03348463          	beq	s1,s3,80002516 <wait+0xe6>
      if(pp->parent == p){
    800024f2:	7c9c                	ld	a5,56(s1)
    800024f4:	ff279be3          	bne	a5,s2,800024ea <wait+0xba>
        acquire(&pp->lock);
    800024f8:	8526                	mv	a0,s1
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6f0080e7          	jalr	1776(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002502:	4c9c                	lw	a5,24(s1)
    80002504:	f94781e3          	beq	a5,s4,80002486 <wait+0x56>
        release(&pp->lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	794080e7          	jalr	1940(ra) # 80000c9e <release>
        havekids = 1;
    80002512:	8756                	mv	a4,s5
    80002514:	bfd9                	j	800024ea <wait+0xba>
    if(!havekids || killed(p)){
    80002516:	c719                	beqz	a4,80002524 <wait+0xf4>
    80002518:	854a                	mv	a0,s2
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	ee4080e7          	jalr	-284(ra) # 800023fe <killed>
    80002522:	c51d                	beqz	a0,80002550 <wait+0x120>
      release(&wait_lock);
    80002524:	0000e517          	auipc	a0,0xe
    80002528:	67450513          	addi	a0,a0,1652 # 80010b98 <wait_lock>
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	772080e7          	jalr	1906(ra) # 80000c9e <release>
      return -1;
    80002534:	59fd                	li	s3,-1
}
    80002536:	854e                	mv	a0,s3
    80002538:	60a6                	ld	ra,72(sp)
    8000253a:	6406                	ld	s0,64(sp)
    8000253c:	74e2                	ld	s1,56(sp)
    8000253e:	7942                	ld	s2,48(sp)
    80002540:	79a2                	ld	s3,40(sp)
    80002542:	7a02                	ld	s4,32(sp)
    80002544:	6ae2                	ld	s5,24(sp)
    80002546:	6b42                	ld	s6,16(sp)
    80002548:	6ba2                	ld	s7,8(sp)
    8000254a:	6c02                	ld	s8,0(sp)
    8000254c:	6161                	addi	sp,sp,80
    8000254e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002550:	85e2                	mv	a1,s8
    80002552:	854a                	mv	a0,s2
    80002554:	00000097          	auipc	ra,0x0
    80002558:	c02080e7          	jalr	-1022(ra) # 80002156 <sleep>
    havekids = 0;
    8000255c:	bf39                	j	8000247a <wait+0x4a>

000000008000255e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000255e:	7179                	addi	sp,sp,-48
    80002560:	f406                	sd	ra,40(sp)
    80002562:	f022                	sd	s0,32(sp)
    80002564:	ec26                	sd	s1,24(sp)
    80002566:	e84a                	sd	s2,16(sp)
    80002568:	e44e                	sd	s3,8(sp)
    8000256a:	e052                	sd	s4,0(sp)
    8000256c:	1800                	addi	s0,sp,48
    8000256e:	84aa                	mv	s1,a0
    80002570:	892e                	mv	s2,a1
    80002572:	89b2                	mv	s3,a2
    80002574:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	53c080e7          	jalr	1340(ra) # 80001ab2 <myproc>
  if(user_dst){
    8000257e:	c08d                	beqz	s1,800025a0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002580:	86d2                	mv	a3,s4
    80002582:	864e                	mv	a2,s3
    80002584:	85ca                	mv	a1,s2
    80002586:	6928                	ld	a0,80(a0)
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	1e8080e7          	jalr	488(ra) # 80001770 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002590:	70a2                	ld	ra,40(sp)
    80002592:	7402                	ld	s0,32(sp)
    80002594:	64e2                	ld	s1,24(sp)
    80002596:	6942                	ld	s2,16(sp)
    80002598:	69a2                	ld	s3,8(sp)
    8000259a:	6a02                	ld	s4,0(sp)
    8000259c:	6145                	addi	sp,sp,48
    8000259e:	8082                	ret
    memmove((char *)dst, src, len);
    800025a0:	000a061b          	sext.w	a2,s4
    800025a4:	85ce                	mv	a1,s3
    800025a6:	854a                	mv	a0,s2
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	79e080e7          	jalr	1950(ra) # 80000d46 <memmove>
    return 0;
    800025b0:	8526                	mv	a0,s1
    800025b2:	bff9                	j	80002590 <either_copyout+0x32>

00000000800025b4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025b4:	7179                	addi	sp,sp,-48
    800025b6:	f406                	sd	ra,40(sp)
    800025b8:	f022                	sd	s0,32(sp)
    800025ba:	ec26                	sd	s1,24(sp)
    800025bc:	e84a                	sd	s2,16(sp)
    800025be:	e44e                	sd	s3,8(sp)
    800025c0:	e052                	sd	s4,0(sp)
    800025c2:	1800                	addi	s0,sp,48
    800025c4:	892a                	mv	s2,a0
    800025c6:	84ae                	mv	s1,a1
    800025c8:	89b2                	mv	s3,a2
    800025ca:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	4e6080e7          	jalr	1254(ra) # 80001ab2 <myproc>
  if(user_src){
    800025d4:	c08d                	beqz	s1,800025f6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025d6:	86d2                	mv	a3,s4
    800025d8:	864e                	mv	a2,s3
    800025da:	85ca                	mv	a1,s2
    800025dc:	6928                	ld	a0,80(a0)
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	21e080e7          	jalr	542(ra) # 800017fc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025e6:	70a2                	ld	ra,40(sp)
    800025e8:	7402                	ld	s0,32(sp)
    800025ea:	64e2                	ld	s1,24(sp)
    800025ec:	6942                	ld	s2,16(sp)
    800025ee:	69a2                	ld	s3,8(sp)
    800025f0:	6a02                	ld	s4,0(sp)
    800025f2:	6145                	addi	sp,sp,48
    800025f4:	8082                	ret
    memmove(dst, (char*)src, len);
    800025f6:	000a061b          	sext.w	a2,s4
    800025fa:	85ce                	mv	a1,s3
    800025fc:	854a                	mv	a0,s2
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	748080e7          	jalr	1864(ra) # 80000d46 <memmove>
    return 0;
    80002606:	8526                	mv	a0,s1
    80002608:	bff9                	j	800025e6 <either_copyin+0x32>

000000008000260a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000260a:	715d                	addi	sp,sp,-80
    8000260c:	e486                	sd	ra,72(sp)
    8000260e:	e0a2                	sd	s0,64(sp)
    80002610:	fc26                	sd	s1,56(sp)
    80002612:	f84a                	sd	s2,48(sp)
    80002614:	f44e                	sd	s3,40(sp)
    80002616:	f052                	sd	s4,32(sp)
    80002618:	ec56                	sd	s5,24(sp)
    8000261a:	e85a                	sd	s6,16(sp)
    8000261c:	e45e                	sd	s7,8(sp)
    8000261e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002620:	00006517          	auipc	a0,0x6
    80002624:	aa850513          	addi	a0,a0,-1368 # 800080c8 <digits+0x88>
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	f66080e7          	jalr	-154(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002630:	0000f497          	auipc	s1,0xf
    80002634:	ad848493          	addi	s1,s1,-1320 # 80011108 <proc+0x158>
    80002638:	00014917          	auipc	s2,0x14
    8000263c:	4d090913          	addi	s2,s2,1232 # 80016b08 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002640:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002642:	00006997          	auipc	s3,0x6
    80002646:	c6e98993          	addi	s3,s3,-914 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    8000264a:	00006a97          	auipc	s5,0x6
    8000264e:	c6ea8a93          	addi	s5,s5,-914 # 800082b8 <digits+0x278>
    printf("\n");
    80002652:	00006a17          	auipc	s4,0x6
    80002656:	a76a0a13          	addi	s4,s4,-1418 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000265a:	00006b97          	auipc	s7,0x6
    8000265e:	c9eb8b93          	addi	s7,s7,-866 # 800082f8 <states.1727>
    80002662:	a00d                	j	80002684 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002664:	ed86a583          	lw	a1,-296(a3)
    80002668:	8556                	mv	a0,s5
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	f24080e7          	jalr	-220(ra) # 8000058e <printf>
    printf("\n");
    80002672:	8552                	mv	a0,s4
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	f1a080e7          	jalr	-230(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000267c:	16848493          	addi	s1,s1,360
    80002680:	03248163          	beq	s1,s2,800026a2 <procdump+0x98>
    if(p->state == UNUSED)
    80002684:	86a6                	mv	a3,s1
    80002686:	ec04a783          	lw	a5,-320(s1)
    8000268a:	dbed                	beqz	a5,8000267c <procdump+0x72>
      state = "???";
    8000268c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000268e:	fcfb6be3          	bltu	s6,a5,80002664 <procdump+0x5a>
    80002692:	1782                	slli	a5,a5,0x20
    80002694:	9381                	srli	a5,a5,0x20
    80002696:	078e                	slli	a5,a5,0x3
    80002698:	97de                	add	a5,a5,s7
    8000269a:	6390                	ld	a2,0(a5)
    8000269c:	f661                	bnez	a2,80002664 <procdump+0x5a>
      state = "???";
    8000269e:	864e                	mv	a2,s3
    800026a0:	b7d1                	j	80002664 <procdump+0x5a>
  }
}
    800026a2:	60a6                	ld	ra,72(sp)
    800026a4:	6406                	ld	s0,64(sp)
    800026a6:	74e2                	ld	s1,56(sp)
    800026a8:	7942                	ld	s2,48(sp)
    800026aa:	79a2                	ld	s3,40(sp)
    800026ac:	7a02                	ld	s4,32(sp)
    800026ae:	6ae2                	ld	s5,24(sp)
    800026b0:	6b42                	ld	s6,16(sp)
    800026b2:	6ba2                	ld	s7,8(sp)
    800026b4:	6161                	addi	sp,sp,80
    800026b6:	8082                	ret

00000000800026b8 <swtch>:
    800026b8:	00153023          	sd	ra,0(a0)
    800026bc:	00253423          	sd	sp,8(a0)
    800026c0:	e900                	sd	s0,16(a0)
    800026c2:	ed04                	sd	s1,24(a0)
    800026c4:	03253023          	sd	s2,32(a0)
    800026c8:	03353423          	sd	s3,40(a0)
    800026cc:	03453823          	sd	s4,48(a0)
    800026d0:	03553c23          	sd	s5,56(a0)
    800026d4:	05653023          	sd	s6,64(a0)
    800026d8:	05753423          	sd	s7,72(a0)
    800026dc:	05853823          	sd	s8,80(a0)
    800026e0:	05953c23          	sd	s9,88(a0)
    800026e4:	07a53023          	sd	s10,96(a0)
    800026e8:	07b53423          	sd	s11,104(a0)
    800026ec:	0005b083          	ld	ra,0(a1)
    800026f0:	0085b103          	ld	sp,8(a1)
    800026f4:	6980                	ld	s0,16(a1)
    800026f6:	6d84                	ld	s1,24(a1)
    800026f8:	0205b903          	ld	s2,32(a1)
    800026fc:	0285b983          	ld	s3,40(a1)
    80002700:	0305ba03          	ld	s4,48(a1)
    80002704:	0385ba83          	ld	s5,56(a1)
    80002708:	0405bb03          	ld	s6,64(a1)
    8000270c:	0485bb83          	ld	s7,72(a1)
    80002710:	0505bc03          	ld	s8,80(a1)
    80002714:	0585bc83          	ld	s9,88(a1)
    80002718:	0605bd03          	ld	s10,96(a1)
    8000271c:	0685bd83          	ld	s11,104(a1)
    80002720:	8082                	ret

0000000080002722 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002722:	1141                	addi	sp,sp,-16
    80002724:	e406                	sd	ra,8(sp)
    80002726:	e022                	sd	s0,0(sp)
    80002728:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000272a:	00006597          	auipc	a1,0x6
    8000272e:	bfe58593          	addi	a1,a1,-1026 # 80008328 <states.1727+0x30>
    80002732:	00014517          	auipc	a0,0x14
    80002736:	27e50513          	addi	a0,a0,638 # 800169b0 <tickslock>
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	420080e7          	jalr	1056(ra) # 80000b5a <initlock>
}
    80002742:	60a2                	ld	ra,8(sp)
    80002744:	6402                	ld	s0,0(sp)
    80002746:	0141                	addi	sp,sp,16
    80002748:	8082                	ret

000000008000274a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000274a:	1141                	addi	sp,sp,-16
    8000274c:	e422                	sd	s0,8(sp)
    8000274e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002750:	00003797          	auipc	a5,0x3
    80002754:	4d078793          	addi	a5,a5,1232 # 80005c20 <kernelvec>
    80002758:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000275c:	6422                	ld	s0,8(sp)
    8000275e:	0141                	addi	sp,sp,16
    80002760:	8082                	ret

0000000080002762 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002762:	1141                	addi	sp,sp,-16
    80002764:	e406                	sd	ra,8(sp)
    80002766:	e022                	sd	s0,0(sp)
    80002768:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000276a:	fffff097          	auipc	ra,0xfffff
    8000276e:	348080e7          	jalr	840(ra) # 80001ab2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002772:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002776:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002778:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000277c:	00005617          	auipc	a2,0x5
    80002780:	88460613          	addi	a2,a2,-1916 # 80007000 <_trampoline>
    80002784:	00005697          	auipc	a3,0x5
    80002788:	87c68693          	addi	a3,a3,-1924 # 80007000 <_trampoline>
    8000278c:	8e91                	sub	a3,a3,a2
    8000278e:	040007b7          	lui	a5,0x4000
    80002792:	17fd                	addi	a5,a5,-1
    80002794:	07b2                	slli	a5,a5,0xc
    80002796:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002798:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000279c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000279e:	180026f3          	csrr	a3,satp
    800027a2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027a4:	6d38                	ld	a4,88(a0)
    800027a6:	6134                	ld	a3,64(a0)
    800027a8:	6585                	lui	a1,0x1
    800027aa:	96ae                	add	a3,a3,a1
    800027ac:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027ae:	6d38                	ld	a4,88(a0)
    800027b0:	00000697          	auipc	a3,0x0
    800027b4:	13068693          	addi	a3,a3,304 # 800028e0 <usertrap>
    800027b8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027ba:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027bc:	8692                	mv	a3,tp
    800027be:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027c4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027c8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027cc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027d0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027d2:	6f18                	ld	a4,24(a4)
    800027d4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027d8:	6928                	ld	a0,80(a0)
    800027da:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027dc:	00005717          	auipc	a4,0x5
    800027e0:	8c070713          	addi	a4,a4,-1856 # 8000709c <userret>
    800027e4:	8f11                	sub	a4,a4,a2
    800027e6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027e8:	577d                	li	a4,-1
    800027ea:	177e                	slli	a4,a4,0x3f
    800027ec:	8d59                	or	a0,a0,a4
    800027ee:	9782                	jalr	a5
}
    800027f0:	60a2                	ld	ra,8(sp)
    800027f2:	6402                	ld	s0,0(sp)
    800027f4:	0141                	addi	sp,sp,16
    800027f6:	8082                	ret

00000000800027f8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027f8:	1101                	addi	sp,sp,-32
    800027fa:	ec06                	sd	ra,24(sp)
    800027fc:	e822                	sd	s0,16(sp)
    800027fe:	e426                	sd	s1,8(sp)
    80002800:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002802:	00014497          	auipc	s1,0x14
    80002806:	1ae48493          	addi	s1,s1,430 # 800169b0 <tickslock>
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	3de080e7          	jalr	990(ra) # 80000bea <acquire>
  ticks++;
    80002814:	00006517          	auipc	a0,0x6
    80002818:	0fc50513          	addi	a0,a0,252 # 80008910 <ticks>
    8000281c:	411c                	lw	a5,0(a0)
    8000281e:	2785                	addiw	a5,a5,1
    80002820:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002822:	00000097          	auipc	ra,0x0
    80002826:	998080e7          	jalr	-1640(ra) # 800021ba <wakeup>
  release(&tickslock);
    8000282a:	8526                	mv	a0,s1
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	472080e7          	jalr	1138(ra) # 80000c9e <release>
}
    80002834:	60e2                	ld	ra,24(sp)
    80002836:	6442                	ld	s0,16(sp)
    80002838:	64a2                	ld	s1,8(sp)
    8000283a:	6105                	addi	sp,sp,32
    8000283c:	8082                	ret

000000008000283e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000283e:	1101                	addi	sp,sp,-32
    80002840:	ec06                	sd	ra,24(sp)
    80002842:	e822                	sd	s0,16(sp)
    80002844:	e426                	sd	s1,8(sp)
    80002846:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002848:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000284c:	00074d63          	bltz	a4,80002866 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002850:	57fd                	li	a5,-1
    80002852:	17fe                	slli	a5,a5,0x3f
    80002854:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002856:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002858:	06f70363          	beq	a4,a5,800028be <devintr+0x80>
  }
}
    8000285c:	60e2                	ld	ra,24(sp)
    8000285e:	6442                	ld	s0,16(sp)
    80002860:	64a2                	ld	s1,8(sp)
    80002862:	6105                	addi	sp,sp,32
    80002864:	8082                	ret
     (scause & 0xff) == 9){
    80002866:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000286a:	46a5                	li	a3,9
    8000286c:	fed792e3          	bne	a5,a3,80002850 <devintr+0x12>
    int irq = plic_claim();
    80002870:	00003097          	auipc	ra,0x3
    80002874:	4b8080e7          	jalr	1208(ra) # 80005d28 <plic_claim>
    80002878:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000287a:	47a9                	li	a5,10
    8000287c:	02f50763          	beq	a0,a5,800028aa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002880:	4785                	li	a5,1
    80002882:	02f50963          	beq	a0,a5,800028b4 <devintr+0x76>
    return 1;
    80002886:	4505                	li	a0,1
    } else if(irq){
    80002888:	d8f1                	beqz	s1,8000285c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000288a:	85a6                	mv	a1,s1
    8000288c:	00006517          	auipc	a0,0x6
    80002890:	aa450513          	addi	a0,a0,-1372 # 80008330 <states.1727+0x38>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	cfa080e7          	jalr	-774(ra) # 8000058e <printf>
      plic_complete(irq);
    8000289c:	8526                	mv	a0,s1
    8000289e:	00003097          	auipc	ra,0x3
    800028a2:	4ae080e7          	jalr	1198(ra) # 80005d4c <plic_complete>
    return 1;
    800028a6:	4505                	li	a0,1
    800028a8:	bf55                	j	8000285c <devintr+0x1e>
      uartintr();
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	104080e7          	jalr	260(ra) # 800009ae <uartintr>
    800028b2:	b7ed                	j	8000289c <devintr+0x5e>
      virtio_disk_intr();
    800028b4:	00004097          	auipc	ra,0x4
    800028b8:	9c2080e7          	jalr	-1598(ra) # 80006276 <virtio_disk_intr>
    800028bc:	b7c5                	j	8000289c <devintr+0x5e>
    if(cpuid() == 0){
    800028be:	fffff097          	auipc	ra,0xfffff
    800028c2:	1c8080e7          	jalr	456(ra) # 80001a86 <cpuid>
    800028c6:	c901                	beqz	a0,800028d6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028c8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028cc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ce:	14479073          	csrw	sip,a5
    return 2;
    800028d2:	4509                	li	a0,2
    800028d4:	b761                	j	8000285c <devintr+0x1e>
      clockintr();
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	f22080e7          	jalr	-222(ra) # 800027f8 <clockintr>
    800028de:	b7ed                	j	800028c8 <devintr+0x8a>

00000000800028e0 <usertrap>:
{
    800028e0:	1101                	addi	sp,sp,-32
    800028e2:	ec06                	sd	ra,24(sp)
    800028e4:	e822                	sd	s0,16(sp)
    800028e6:	e426                	sd	s1,8(sp)
    800028e8:	e04a                	sd	s2,0(sp)
    800028ea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ec:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028f0:	1007f793          	andi	a5,a5,256
    800028f4:	e3b1                	bnez	a5,80002938 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f6:	00003797          	auipc	a5,0x3
    800028fa:	32a78793          	addi	a5,a5,810 # 80005c20 <kernelvec>
    800028fe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002902:	fffff097          	auipc	ra,0xfffff
    80002906:	1b0080e7          	jalr	432(ra) # 80001ab2 <myproc>
    8000290a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000290c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000290e:	14102773          	csrr	a4,sepc
    80002912:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002914:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002918:	47a1                	li	a5,8
    8000291a:	02f70763          	beq	a4,a5,80002948 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	f20080e7          	jalr	-224(ra) # 8000283e <devintr>
    80002926:	892a                	mv	s2,a0
    80002928:	c151                	beqz	a0,800029ac <usertrap+0xcc>
  if(killed(p))
    8000292a:	8526                	mv	a0,s1
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	ad2080e7          	jalr	-1326(ra) # 800023fe <killed>
    80002934:	c929                	beqz	a0,80002986 <usertrap+0xa6>
    80002936:	a099                	j	8000297c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002938:	00006517          	auipc	a0,0x6
    8000293c:	a1850513          	addi	a0,a0,-1512 # 80008350 <states.1727+0x58>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	c04080e7          	jalr	-1020(ra) # 80000544 <panic>
    if(killed(p))
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	ab6080e7          	jalr	-1354(ra) # 800023fe <killed>
    80002950:	e921                	bnez	a0,800029a0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002952:	6cb8                	ld	a4,88(s1)
    80002954:	6f1c                	ld	a5,24(a4)
    80002956:	0791                	addi	a5,a5,4
    80002958:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000295e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002962:	10079073          	csrw	sstatus,a5
    syscall();
    80002966:	00000097          	auipc	ra,0x0
    8000296a:	2d4080e7          	jalr	724(ra) # 80002c3a <syscall>
  if(killed(p))
    8000296e:	8526                	mv	a0,s1
    80002970:	00000097          	auipc	ra,0x0
    80002974:	a8e080e7          	jalr	-1394(ra) # 800023fe <killed>
    80002978:	c911                	beqz	a0,8000298c <usertrap+0xac>
    8000297a:	4901                	li	s2,0
    exit(-1);
    8000297c:	557d                	li	a0,-1
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	90c080e7          	jalr	-1780(ra) # 8000228a <exit>
  if(which_dev == 2)
    80002986:	4789                	li	a5,2
    80002988:	04f90f63          	beq	s2,a5,800029e6 <usertrap+0x106>
  usertrapret();
    8000298c:	00000097          	auipc	ra,0x0
    80002990:	dd6080e7          	jalr	-554(ra) # 80002762 <usertrapret>
}
    80002994:	60e2                	ld	ra,24(sp)
    80002996:	6442                	ld	s0,16(sp)
    80002998:	64a2                	ld	s1,8(sp)
    8000299a:	6902                	ld	s2,0(sp)
    8000299c:	6105                	addi	sp,sp,32
    8000299e:	8082                	ret
      exit(-1);
    800029a0:	557d                	li	a0,-1
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	8e8080e7          	jalr	-1816(ra) # 8000228a <exit>
    800029aa:	b765                	j	80002952 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ac:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029b0:	5890                	lw	a2,48(s1)
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	9be50513          	addi	a0,a0,-1602 # 80008370 <states.1727+0x78>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	bd4080e7          	jalr	-1068(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029c6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	9d650513          	addi	a0,a0,-1578 # 800083a0 <states.1727+0xa8>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	bbc080e7          	jalr	-1092(ra) # 8000058e <printf>
    setkilled(p);
    800029da:	8526                	mv	a0,s1
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	9f6080e7          	jalr	-1546(ra) # 800023d2 <setkilled>
    800029e4:	b769                	j	8000296e <usertrap+0x8e>
    yield();
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	734080e7          	jalr	1844(ra) # 8000211a <yield>
    800029ee:	bf79                	j	8000298c <usertrap+0xac>

00000000800029f0 <kerneltrap>:
{
    800029f0:	7179                	addi	sp,sp,-48
    800029f2:	f406                	sd	ra,40(sp)
    800029f4:	f022                	sd	s0,32(sp)
    800029f6:	ec26                	sd	s1,24(sp)
    800029f8:	e84a                	sd	s2,16(sp)
    800029fa:	e44e                	sd	s3,8(sp)
    800029fc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029fe:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a06:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a0a:	1004f793          	andi	a5,s1,256
    80002a0e:	cb85                	beqz	a5,80002a3e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a10:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a14:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a16:	ef85                	bnez	a5,80002a4e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a18:	00000097          	auipc	ra,0x0
    80002a1c:	e26080e7          	jalr	-474(ra) # 8000283e <devintr>
    80002a20:	cd1d                	beqz	a0,80002a5e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a22:	4789                	li	a5,2
    80002a24:	06f50a63          	beq	a0,a5,80002a98 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a28:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2c:	10049073          	csrw	sstatus,s1
}
    80002a30:	70a2                	ld	ra,40(sp)
    80002a32:	7402                	ld	s0,32(sp)
    80002a34:	64e2                	ld	s1,24(sp)
    80002a36:	6942                	ld	s2,16(sp)
    80002a38:	69a2                	ld	s3,8(sp)
    80002a3a:	6145                	addi	sp,sp,48
    80002a3c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a3e:	00006517          	auipc	a0,0x6
    80002a42:	98250513          	addi	a0,a0,-1662 # 800083c0 <states.1727+0xc8>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	afe080e7          	jalr	-1282(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a4e:	00006517          	auipc	a0,0x6
    80002a52:	99a50513          	addi	a0,a0,-1638 # 800083e8 <states.1727+0xf0>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	aee080e7          	jalr	-1298(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002a5e:	85ce                	mv	a1,s3
    80002a60:	00006517          	auipc	a0,0x6
    80002a64:	9a850513          	addi	a0,a0,-1624 # 80008408 <states.1727+0x110>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	b26080e7          	jalr	-1242(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a70:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a74:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a78:	00006517          	auipc	a0,0x6
    80002a7c:	9a050513          	addi	a0,a0,-1632 # 80008418 <states.1727+0x120>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	b0e080e7          	jalr	-1266(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a88:	00006517          	auipc	a0,0x6
    80002a8c:	9a850513          	addi	a0,a0,-1624 # 80008430 <states.1727+0x138>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	ab4080e7          	jalr	-1356(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	01a080e7          	jalr	26(ra) # 80001ab2 <myproc>
    80002aa0:	d541                	beqz	a0,80002a28 <kerneltrap+0x38>
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	010080e7          	jalr	16(ra) # 80001ab2 <myproc>
    80002aaa:	4d18                	lw	a4,24(a0)
    80002aac:	4791                	li	a5,4
    80002aae:	f6f71de3          	bne	a4,a5,80002a28 <kerneltrap+0x38>
    yield();
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	668080e7          	jalr	1640(ra) # 8000211a <yield>
    80002aba:	b7bd                	j	80002a28 <kerneltrap+0x38>

0000000080002abc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002abc:	1101                	addi	sp,sp,-32
    80002abe:	ec06                	sd	ra,24(sp)
    80002ac0:	e822                	sd	s0,16(sp)
    80002ac2:	e426                	sd	s1,8(sp)
    80002ac4:	1000                	addi	s0,sp,32
    80002ac6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	fea080e7          	jalr	-22(ra) # 80001ab2 <myproc>
  switch (n) {
    80002ad0:	4795                	li	a5,5
    80002ad2:	0497e163          	bltu	a5,s1,80002b14 <argraw+0x58>
    80002ad6:	048a                	slli	s1,s1,0x2
    80002ad8:	00006717          	auipc	a4,0x6
    80002adc:	99070713          	addi	a4,a4,-1648 # 80008468 <states.1727+0x170>
    80002ae0:	94ba                	add	s1,s1,a4
    80002ae2:	409c                	lw	a5,0(s1)
    80002ae4:	97ba                	add	a5,a5,a4
    80002ae6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aec:	60e2                	ld	ra,24(sp)
    80002aee:	6442                	ld	s0,16(sp)
    80002af0:	64a2                	ld	s1,8(sp)
    80002af2:	6105                	addi	sp,sp,32
    80002af4:	8082                	ret
    return p->trapframe->a1;
    80002af6:	6d3c                	ld	a5,88(a0)
    80002af8:	7fa8                	ld	a0,120(a5)
    80002afa:	bfcd                	j	80002aec <argraw+0x30>
    return p->trapframe->a2;
    80002afc:	6d3c                	ld	a5,88(a0)
    80002afe:	63c8                	ld	a0,128(a5)
    80002b00:	b7f5                	j	80002aec <argraw+0x30>
    return p->trapframe->a3;
    80002b02:	6d3c                	ld	a5,88(a0)
    80002b04:	67c8                	ld	a0,136(a5)
    80002b06:	b7dd                	j	80002aec <argraw+0x30>
    return p->trapframe->a4;
    80002b08:	6d3c                	ld	a5,88(a0)
    80002b0a:	6bc8                	ld	a0,144(a5)
    80002b0c:	b7c5                	j	80002aec <argraw+0x30>
    return p->trapframe->a5;
    80002b0e:	6d3c                	ld	a5,88(a0)
    80002b10:	6fc8                	ld	a0,152(a5)
    80002b12:	bfe9                	j	80002aec <argraw+0x30>
  panic("argraw");
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	92c50513          	addi	a0,a0,-1748 # 80008440 <states.1727+0x148>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a28080e7          	jalr	-1496(ra) # 80000544 <panic>

0000000080002b24 <fetchaddr>:
{
    80002b24:	1101                	addi	sp,sp,-32
    80002b26:	ec06                	sd	ra,24(sp)
    80002b28:	e822                	sd	s0,16(sp)
    80002b2a:	e426                	sd	s1,8(sp)
    80002b2c:	e04a                	sd	s2,0(sp)
    80002b2e:	1000                	addi	s0,sp,32
    80002b30:	84aa                	mv	s1,a0
    80002b32:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	f7e080e7          	jalr	-130(ra) # 80001ab2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b3c:	653c                	ld	a5,72(a0)
    80002b3e:	02f4f863          	bgeu	s1,a5,80002b6e <fetchaddr+0x4a>
    80002b42:	00848713          	addi	a4,s1,8
    80002b46:	02e7e663          	bltu	a5,a4,80002b72 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b4a:	46a1                	li	a3,8
    80002b4c:	8626                	mv	a2,s1
    80002b4e:	85ca                	mv	a1,s2
    80002b50:	6928                	ld	a0,80(a0)
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	caa080e7          	jalr	-854(ra) # 800017fc <copyin>
    80002b5a:	00a03533          	snez	a0,a0
    80002b5e:	40a00533          	neg	a0,a0
}
    80002b62:	60e2                	ld	ra,24(sp)
    80002b64:	6442                	ld	s0,16(sp)
    80002b66:	64a2                	ld	s1,8(sp)
    80002b68:	6902                	ld	s2,0(sp)
    80002b6a:	6105                	addi	sp,sp,32
    80002b6c:	8082                	ret
    return -1;
    80002b6e:	557d                	li	a0,-1
    80002b70:	bfcd                	j	80002b62 <fetchaddr+0x3e>
    80002b72:	557d                	li	a0,-1
    80002b74:	b7fd                	j	80002b62 <fetchaddr+0x3e>

0000000080002b76 <fetchstr>:
{
    80002b76:	7179                	addi	sp,sp,-48
    80002b78:	f406                	sd	ra,40(sp)
    80002b7a:	f022                	sd	s0,32(sp)
    80002b7c:	ec26                	sd	s1,24(sp)
    80002b7e:	e84a                	sd	s2,16(sp)
    80002b80:	e44e                	sd	s3,8(sp)
    80002b82:	1800                	addi	s0,sp,48
    80002b84:	892a                	mv	s2,a0
    80002b86:	84ae                	mv	s1,a1
    80002b88:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b8a:	fffff097          	auipc	ra,0xfffff
    80002b8e:	f28080e7          	jalr	-216(ra) # 80001ab2 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b92:	86ce                	mv	a3,s3
    80002b94:	864a                	mv	a2,s2
    80002b96:	85a6                	mv	a1,s1
    80002b98:	6928                	ld	a0,80(a0)
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	cee080e7          	jalr	-786(ra) # 80001888 <copyinstr>
    80002ba2:	00054e63          	bltz	a0,80002bbe <fetchstr+0x48>
  return strlen(buf);
    80002ba6:	8526                	mv	a0,s1
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	2c2080e7          	jalr	706(ra) # 80000e6a <strlen>
}
    80002bb0:	70a2                	ld	ra,40(sp)
    80002bb2:	7402                	ld	s0,32(sp)
    80002bb4:	64e2                	ld	s1,24(sp)
    80002bb6:	6942                	ld	s2,16(sp)
    80002bb8:	69a2                	ld	s3,8(sp)
    80002bba:	6145                	addi	sp,sp,48
    80002bbc:	8082                	ret
    return -1;
    80002bbe:	557d                	li	a0,-1
    80002bc0:	bfc5                	j	80002bb0 <fetchstr+0x3a>

0000000080002bc2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	1000                	addi	s0,sp,32
    80002bcc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	eee080e7          	jalr	-274(ra) # 80002abc <argraw>
    80002bd6:	c088                	sw	a0,0(s1)
}
    80002bd8:	60e2                	ld	ra,24(sp)
    80002bda:	6442                	ld	s0,16(sp)
    80002bdc:	64a2                	ld	s1,8(sp)
    80002bde:	6105                	addi	sp,sp,32
    80002be0:	8082                	ret

0000000080002be2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	e426                	sd	s1,8(sp)
    80002bea:	1000                	addi	s0,sp,32
    80002bec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	ece080e7          	jalr	-306(ra) # 80002abc <argraw>
    80002bf6:	e088                	sd	a0,0(s1)
}
    80002bf8:	60e2                	ld	ra,24(sp)
    80002bfa:	6442                	ld	s0,16(sp)
    80002bfc:	64a2                	ld	s1,8(sp)
    80002bfe:	6105                	addi	sp,sp,32
    80002c00:	8082                	ret

0000000080002c02 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c02:	7179                	addi	sp,sp,-48
    80002c04:	f406                	sd	ra,40(sp)
    80002c06:	f022                	sd	s0,32(sp)
    80002c08:	ec26                	sd	s1,24(sp)
    80002c0a:	e84a                	sd	s2,16(sp)
    80002c0c:	1800                	addi	s0,sp,48
    80002c0e:	84ae                	mv	s1,a1
    80002c10:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c12:	fd840593          	addi	a1,s0,-40
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	fcc080e7          	jalr	-52(ra) # 80002be2 <argaddr>
  return fetchstr(addr, buf, max);
    80002c1e:	864a                	mv	a2,s2
    80002c20:	85a6                	mv	a1,s1
    80002c22:	fd843503          	ld	a0,-40(s0)
    80002c26:	00000097          	auipc	ra,0x0
    80002c2a:	f50080e7          	jalr	-176(ra) # 80002b76 <fetchstr>
}
    80002c2e:	70a2                	ld	ra,40(sp)
    80002c30:	7402                	ld	s0,32(sp)
    80002c32:	64e2                	ld	s1,24(sp)
    80002c34:	6942                	ld	s2,16(sp)
    80002c36:	6145                	addi	sp,sp,48
    80002c38:	8082                	ret

0000000080002c3a <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c3a:	1101                	addi	sp,sp,-32
    80002c3c:	ec06                	sd	ra,24(sp)
    80002c3e:	e822                	sd	s0,16(sp)
    80002c40:	e426                	sd	s1,8(sp)
    80002c42:	e04a                	sd	s2,0(sp)
    80002c44:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	e6c080e7          	jalr	-404(ra) # 80001ab2 <myproc>
    80002c4e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c50:	05853903          	ld	s2,88(a0)
    80002c54:	0a893783          	ld	a5,168(s2)
    80002c58:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c5c:	37fd                	addiw	a5,a5,-1
    80002c5e:	4751                	li	a4,20
    80002c60:	00f76f63          	bltu	a4,a5,80002c7e <syscall+0x44>
    80002c64:	00369713          	slli	a4,a3,0x3
    80002c68:	00006797          	auipc	a5,0x6
    80002c6c:	81878793          	addi	a5,a5,-2024 # 80008480 <syscalls>
    80002c70:	97ba                	add	a5,a5,a4
    80002c72:	639c                	ld	a5,0(a5)
    80002c74:	c789                	beqz	a5,80002c7e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c76:	9782                	jalr	a5
    80002c78:	06a93823          	sd	a0,112(s2)
    80002c7c:	a839                	j	80002c9a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c7e:	15848613          	addi	a2,s1,344
    80002c82:	588c                	lw	a1,48(s1)
    80002c84:	00005517          	auipc	a0,0x5
    80002c88:	7c450513          	addi	a0,a0,1988 # 80008448 <states.1727+0x150>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	902080e7          	jalr	-1790(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c94:	6cbc                	ld	a5,88(s1)
    80002c96:	577d                	li	a4,-1
    80002c98:	fbb8                	sd	a4,112(a5)
  }
}
    80002c9a:	60e2                	ld	ra,24(sp)
    80002c9c:	6442                	ld	s0,16(sp)
    80002c9e:	64a2                	ld	s1,8(sp)
    80002ca0:	6902                	ld	s2,0(sp)
    80002ca2:	6105                	addi	sp,sp,32
    80002ca4:	8082                	ret

0000000080002ca6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ca6:	1101                	addi	sp,sp,-32
    80002ca8:	ec06                	sd	ra,24(sp)
    80002caa:	e822                	sd	s0,16(sp)
    80002cac:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cae:	fec40593          	addi	a1,s0,-20
    80002cb2:	4501                	li	a0,0
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	f0e080e7          	jalr	-242(ra) # 80002bc2 <argint>
  exit(n);
    80002cbc:	fec42503          	lw	a0,-20(s0)
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	5ca080e7          	jalr	1482(ra) # 8000228a <exit>
  return 0;  // not reached
}
    80002cc8:	4501                	li	a0,0
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	6105                	addi	sp,sp,32
    80002cd0:	8082                	ret

0000000080002cd2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cd2:	1141                	addi	sp,sp,-16
    80002cd4:	e406                	sd	ra,8(sp)
    80002cd6:	e022                	sd	s0,0(sp)
    80002cd8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	dd8080e7          	jalr	-552(ra) # 80001ab2 <myproc>
}
    80002ce2:	5908                	lw	a0,48(a0)
    80002ce4:	60a2                	ld	ra,8(sp)
    80002ce6:	6402                	ld	s0,0(sp)
    80002ce8:	0141                	addi	sp,sp,16
    80002cea:	8082                	ret

0000000080002cec <sys_fork>:

uint64
sys_fork(void)
{
    80002cec:	1141                	addi	sp,sp,-16
    80002cee:	e406                	sd	ra,8(sp)
    80002cf0:	e022                	sd	s0,0(sp)
    80002cf2:	0800                	addi	s0,sp,16
  return fork();
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	174080e7          	jalr	372(ra) # 80001e68 <fork>
}
    80002cfc:	60a2                	ld	ra,8(sp)
    80002cfe:	6402                	ld	s0,0(sp)
    80002d00:	0141                	addi	sp,sp,16
    80002d02:	8082                	ret

0000000080002d04 <sys_wait>:

uint64
sys_wait(void)
{
    80002d04:	1101                	addi	sp,sp,-32
    80002d06:	ec06                	sd	ra,24(sp)
    80002d08:	e822                	sd	s0,16(sp)
    80002d0a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d0c:	fe840593          	addi	a1,s0,-24
    80002d10:	4501                	li	a0,0
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	ed0080e7          	jalr	-304(ra) # 80002be2 <argaddr>
  return wait(p);
    80002d1a:	fe843503          	ld	a0,-24(s0)
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	712080e7          	jalr	1810(ra) # 80002430 <wait>
}
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	6105                	addi	sp,sp,32
    80002d2c:	8082                	ret

0000000080002d2e <sys_sbrk>:


//---------------------- CHARISIS SKORDAS EDIT	---------------------------------//
uint64 sys_sbrk(void){
    80002d2e:	7179                	addi	sp,sp,-48
    80002d30:	f406                	sd	ra,40(sp)
    80002d32:	f022                	sd	s0,32(sp)
    80002d34:	ec26                	sd	s1,24(sp)
    80002d36:	e84a                	sd	s2,16(sp)
    80002d38:	1800                	addi	s0,sp,48
	uint64 addr;
	int n;

  	argint(0, &n);
    80002d3a:	fdc40593          	addi	a1,s0,-36
    80002d3e:	4501                	li	a0,0
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	e82080e7          	jalr	-382(ra) # 80002bc2 <argint>

  	addr = myproc()->sz;
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	d6a080e7          	jalr	-662(ra) # 80001ab2 <myproc>
    80002d50:	6524                	ld	s1,72(a0)
  	if(n < 0){
    80002d52:	fdc42783          	lw	a5,-36(s0)
    80002d56:	0007c963          	bltz	a5,80002d68 <sys_sbrk+0x3a>
		uvmdealloc(myproc()->pagetable, addr, myproc()->sz);
	}

	return addr;
}
    80002d5a:	8526                	mv	a0,s1
    80002d5c:	70a2                	ld	ra,40(sp)
    80002d5e:	7402                	ld	s0,32(sp)
    80002d60:	64e2                	ld	s1,24(sp)
    80002d62:	6942                	ld	s2,16(sp)
    80002d64:	6145                	addi	sp,sp,48
    80002d66:	8082                	ret
		uvmdealloc(myproc()->pagetable, addr, myproc()->sz);
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	d4a080e7          	jalr	-694(ra) # 80001ab2 <myproc>
    80002d70:	05053903          	ld	s2,80(a0)
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	d3e080e7          	jalr	-706(ra) # 80001ab2 <myproc>
    80002d7c:	6530                	ld	a2,72(a0)
    80002d7e:	85a6                	mv	a1,s1
    80002d80:	854a                	mv	a0,s2
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	74e080e7          	jalr	1870(ra) # 800014d0 <uvmdealloc>
	return addr;
    80002d8a:	bfc1                	j	80002d5a <sys_sbrk+0x2c>

0000000080002d8c <sys_sleep>:
//---------------------	CHARISIS SKORDAS EDIT------------------------------------//
uint64
sys_sleep(void)
{
    80002d8c:	7139                	addi	sp,sp,-64
    80002d8e:	fc06                	sd	ra,56(sp)
    80002d90:	f822                	sd	s0,48(sp)
    80002d92:	f426                	sd	s1,40(sp)
    80002d94:	f04a                	sd	s2,32(sp)
    80002d96:	ec4e                	sd	s3,24(sp)
    80002d98:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d9a:	fcc40593          	addi	a1,s0,-52
    80002d9e:	4501                	li	a0,0
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	e22080e7          	jalr	-478(ra) # 80002bc2 <argint>
  acquire(&tickslock);
    80002da8:	00014517          	auipc	a0,0x14
    80002dac:	c0850513          	addi	a0,a0,-1016 # 800169b0 <tickslock>
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	e3a080e7          	jalr	-454(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002db8:	00006917          	auipc	s2,0x6
    80002dbc:	b5892903          	lw	s2,-1192(s2) # 80008910 <ticks>
  while(ticks - ticks0 < n){
    80002dc0:	fcc42783          	lw	a5,-52(s0)
    80002dc4:	cf9d                	beqz	a5,80002e02 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dc6:	00014997          	auipc	s3,0x14
    80002dca:	bea98993          	addi	s3,s3,-1046 # 800169b0 <tickslock>
    80002dce:	00006497          	auipc	s1,0x6
    80002dd2:	b4248493          	addi	s1,s1,-1214 # 80008910 <ticks>
    if(killed(myproc())){
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	cdc080e7          	jalr	-804(ra) # 80001ab2 <myproc>
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	620080e7          	jalr	1568(ra) # 800023fe <killed>
    80002de6:	ed15                	bnez	a0,80002e22 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002de8:	85ce                	mv	a1,s3
    80002dea:	8526                	mv	a0,s1
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	36a080e7          	jalr	874(ra) # 80002156 <sleep>
  while(ticks - ticks0 < n){
    80002df4:	409c                	lw	a5,0(s1)
    80002df6:	412787bb          	subw	a5,a5,s2
    80002dfa:	fcc42703          	lw	a4,-52(s0)
    80002dfe:	fce7ece3          	bltu	a5,a4,80002dd6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e02:	00014517          	auipc	a0,0x14
    80002e06:	bae50513          	addi	a0,a0,-1106 # 800169b0 <tickslock>
    80002e0a:	ffffe097          	auipc	ra,0xffffe
    80002e0e:	e94080e7          	jalr	-364(ra) # 80000c9e <release>
  return 0;
    80002e12:	4501                	li	a0,0
}
    80002e14:	70e2                	ld	ra,56(sp)
    80002e16:	7442                	ld	s0,48(sp)
    80002e18:	74a2                	ld	s1,40(sp)
    80002e1a:	7902                	ld	s2,32(sp)
    80002e1c:	69e2                	ld	s3,24(sp)
    80002e1e:	6121                	addi	sp,sp,64
    80002e20:	8082                	ret
      release(&tickslock);
    80002e22:	00014517          	auipc	a0,0x14
    80002e26:	b8e50513          	addi	a0,a0,-1138 # 800169b0 <tickslock>
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	e74080e7          	jalr	-396(ra) # 80000c9e <release>
      return -1;
    80002e32:	557d                	li	a0,-1
    80002e34:	b7c5                	j	80002e14 <sys_sleep+0x88>

0000000080002e36 <sys_kill>:

uint64
sys_kill(void)
{
    80002e36:	1101                	addi	sp,sp,-32
    80002e38:	ec06                	sd	ra,24(sp)
    80002e3a:	e822                	sd	s0,16(sp)
    80002e3c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e3e:	fec40593          	addi	a1,s0,-20
    80002e42:	4501                	li	a0,0
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	d7e080e7          	jalr	-642(ra) # 80002bc2 <argint>
  return kill(pid);
    80002e4c:	fec42503          	lw	a0,-20(s0)
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	510080e7          	jalr	1296(ra) # 80002360 <kill>
}
    80002e58:	60e2                	ld	ra,24(sp)
    80002e5a:	6442                	ld	s0,16(sp)
    80002e5c:	6105                	addi	sp,sp,32
    80002e5e:	8082                	ret

0000000080002e60 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e60:	1101                	addi	sp,sp,-32
    80002e62:	ec06                	sd	ra,24(sp)
    80002e64:	e822                	sd	s0,16(sp)
    80002e66:	e426                	sd	s1,8(sp)
    80002e68:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e6a:	00014517          	auipc	a0,0x14
    80002e6e:	b4650513          	addi	a0,a0,-1210 # 800169b0 <tickslock>
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	d78080e7          	jalr	-648(ra) # 80000bea <acquire>
  xticks = ticks;
    80002e7a:	00006497          	auipc	s1,0x6
    80002e7e:	a964a483          	lw	s1,-1386(s1) # 80008910 <ticks>
  release(&tickslock);
    80002e82:	00014517          	auipc	a0,0x14
    80002e86:	b2e50513          	addi	a0,a0,-1234 # 800169b0 <tickslock>
    80002e8a:	ffffe097          	auipc	ra,0xffffe
    80002e8e:	e14080e7          	jalr	-492(ra) # 80000c9e <release>
  return xticks;
}
    80002e92:	02049513          	slli	a0,s1,0x20
    80002e96:	9101                	srli	a0,a0,0x20
    80002e98:	60e2                	ld	ra,24(sp)
    80002e9a:	6442                	ld	s0,16(sp)
    80002e9c:	64a2                	ld	s1,8(sp)
    80002e9e:	6105                	addi	sp,sp,32
    80002ea0:	8082                	ret

0000000080002ea2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ea2:	7179                	addi	sp,sp,-48
    80002ea4:	f406                	sd	ra,40(sp)
    80002ea6:	f022                	sd	s0,32(sp)
    80002ea8:	ec26                	sd	s1,24(sp)
    80002eaa:	e84a                	sd	s2,16(sp)
    80002eac:	e44e                	sd	s3,8(sp)
    80002eae:	e052                	sd	s4,0(sp)
    80002eb0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eb2:	00005597          	auipc	a1,0x5
    80002eb6:	67e58593          	addi	a1,a1,1662 # 80008530 <syscalls+0xb0>
    80002eba:	00014517          	auipc	a0,0x14
    80002ebe:	b0e50513          	addi	a0,a0,-1266 # 800169c8 <bcache>
    80002ec2:	ffffe097          	auipc	ra,0xffffe
    80002ec6:	c98080e7          	jalr	-872(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eca:	0001c797          	auipc	a5,0x1c
    80002ece:	afe78793          	addi	a5,a5,-1282 # 8001e9c8 <bcache+0x8000>
    80002ed2:	0001c717          	auipc	a4,0x1c
    80002ed6:	d5e70713          	addi	a4,a4,-674 # 8001ec30 <bcache+0x8268>
    80002eda:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ede:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee2:	00014497          	auipc	s1,0x14
    80002ee6:	afe48493          	addi	s1,s1,-1282 # 800169e0 <bcache+0x18>
    b->next = bcache.head.next;
    80002eea:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eec:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002eee:	00005a17          	auipc	s4,0x5
    80002ef2:	64aa0a13          	addi	s4,s4,1610 # 80008538 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002ef6:	2b893783          	ld	a5,696(s2)
    80002efa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002efc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f00:	85d2                	mv	a1,s4
    80002f02:	01048513          	addi	a0,s1,16
    80002f06:	00001097          	auipc	ra,0x1
    80002f0a:	4c4080e7          	jalr	1220(ra) # 800043ca <initsleeplock>
    bcache.head.next->prev = b;
    80002f0e:	2b893783          	ld	a5,696(s2)
    80002f12:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f14:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f18:	45848493          	addi	s1,s1,1112
    80002f1c:	fd349de3          	bne	s1,s3,80002ef6 <binit+0x54>
  }
}
    80002f20:	70a2                	ld	ra,40(sp)
    80002f22:	7402                	ld	s0,32(sp)
    80002f24:	64e2                	ld	s1,24(sp)
    80002f26:	6942                	ld	s2,16(sp)
    80002f28:	69a2                	ld	s3,8(sp)
    80002f2a:	6a02                	ld	s4,0(sp)
    80002f2c:	6145                	addi	sp,sp,48
    80002f2e:	8082                	ret

0000000080002f30 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f30:	7179                	addi	sp,sp,-48
    80002f32:	f406                	sd	ra,40(sp)
    80002f34:	f022                	sd	s0,32(sp)
    80002f36:	ec26                	sd	s1,24(sp)
    80002f38:	e84a                	sd	s2,16(sp)
    80002f3a:	e44e                	sd	s3,8(sp)
    80002f3c:	1800                	addi	s0,sp,48
    80002f3e:	89aa                	mv	s3,a0
    80002f40:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f42:	00014517          	auipc	a0,0x14
    80002f46:	a8650513          	addi	a0,a0,-1402 # 800169c8 <bcache>
    80002f4a:	ffffe097          	auipc	ra,0xffffe
    80002f4e:	ca0080e7          	jalr	-864(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f52:	0001c497          	auipc	s1,0x1c
    80002f56:	d2e4b483          	ld	s1,-722(s1) # 8001ec80 <bcache+0x82b8>
    80002f5a:	0001c797          	auipc	a5,0x1c
    80002f5e:	cd678793          	addi	a5,a5,-810 # 8001ec30 <bcache+0x8268>
    80002f62:	02f48f63          	beq	s1,a5,80002fa0 <bread+0x70>
    80002f66:	873e                	mv	a4,a5
    80002f68:	a021                	j	80002f70 <bread+0x40>
    80002f6a:	68a4                	ld	s1,80(s1)
    80002f6c:	02e48a63          	beq	s1,a4,80002fa0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f70:	449c                	lw	a5,8(s1)
    80002f72:	ff379ce3          	bne	a5,s3,80002f6a <bread+0x3a>
    80002f76:	44dc                	lw	a5,12(s1)
    80002f78:	ff2799e3          	bne	a5,s2,80002f6a <bread+0x3a>
      b->refcnt++;
    80002f7c:	40bc                	lw	a5,64(s1)
    80002f7e:	2785                	addiw	a5,a5,1
    80002f80:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f82:	00014517          	auipc	a0,0x14
    80002f86:	a4650513          	addi	a0,a0,-1466 # 800169c8 <bcache>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	d14080e7          	jalr	-748(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002f92:	01048513          	addi	a0,s1,16
    80002f96:	00001097          	auipc	ra,0x1
    80002f9a:	46e080e7          	jalr	1134(ra) # 80004404 <acquiresleep>
      return b;
    80002f9e:	a8b9                	j	80002ffc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa0:	0001c497          	auipc	s1,0x1c
    80002fa4:	cd84b483          	ld	s1,-808(s1) # 8001ec78 <bcache+0x82b0>
    80002fa8:	0001c797          	auipc	a5,0x1c
    80002fac:	c8878793          	addi	a5,a5,-888 # 8001ec30 <bcache+0x8268>
    80002fb0:	00f48863          	beq	s1,a5,80002fc0 <bread+0x90>
    80002fb4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fb6:	40bc                	lw	a5,64(s1)
    80002fb8:	cf81                	beqz	a5,80002fd0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fba:	64a4                	ld	s1,72(s1)
    80002fbc:	fee49de3          	bne	s1,a4,80002fb6 <bread+0x86>
  panic("bget: no buffers");
    80002fc0:	00005517          	auipc	a0,0x5
    80002fc4:	58050513          	addi	a0,a0,1408 # 80008540 <syscalls+0xc0>
    80002fc8:	ffffd097          	auipc	ra,0xffffd
    80002fcc:	57c080e7          	jalr	1404(ra) # 80000544 <panic>
      b->dev = dev;
    80002fd0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fd4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fd8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fdc:	4785                	li	a5,1
    80002fde:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe0:	00014517          	auipc	a0,0x14
    80002fe4:	9e850513          	addi	a0,a0,-1560 # 800169c8 <bcache>
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	cb6080e7          	jalr	-842(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002ff0:	01048513          	addi	a0,s1,16
    80002ff4:	00001097          	auipc	ra,0x1
    80002ff8:	410080e7          	jalr	1040(ra) # 80004404 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ffc:	409c                	lw	a5,0(s1)
    80002ffe:	cb89                	beqz	a5,80003010 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003000:	8526                	mv	a0,s1
    80003002:	70a2                	ld	ra,40(sp)
    80003004:	7402                	ld	s0,32(sp)
    80003006:	64e2                	ld	s1,24(sp)
    80003008:	6942                	ld	s2,16(sp)
    8000300a:	69a2                	ld	s3,8(sp)
    8000300c:	6145                	addi	sp,sp,48
    8000300e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003010:	4581                	li	a1,0
    80003012:	8526                	mv	a0,s1
    80003014:	00003097          	auipc	ra,0x3
    80003018:	fd4080e7          	jalr	-44(ra) # 80005fe8 <virtio_disk_rw>
    b->valid = 1;
    8000301c:	4785                	li	a5,1
    8000301e:	c09c                	sw	a5,0(s1)
  return b;
    80003020:	b7c5                	j	80003000 <bread+0xd0>

0000000080003022 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003022:	1101                	addi	sp,sp,-32
    80003024:	ec06                	sd	ra,24(sp)
    80003026:	e822                	sd	s0,16(sp)
    80003028:	e426                	sd	s1,8(sp)
    8000302a:	1000                	addi	s0,sp,32
    8000302c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000302e:	0541                	addi	a0,a0,16
    80003030:	00001097          	auipc	ra,0x1
    80003034:	46e080e7          	jalr	1134(ra) # 8000449e <holdingsleep>
    80003038:	cd01                	beqz	a0,80003050 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000303a:	4585                	li	a1,1
    8000303c:	8526                	mv	a0,s1
    8000303e:	00003097          	auipc	ra,0x3
    80003042:	faa080e7          	jalr	-86(ra) # 80005fe8 <virtio_disk_rw>
}
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	64a2                	ld	s1,8(sp)
    8000304c:	6105                	addi	sp,sp,32
    8000304e:	8082                	ret
    panic("bwrite");
    80003050:	00005517          	auipc	a0,0x5
    80003054:	50850513          	addi	a0,a0,1288 # 80008558 <syscalls+0xd8>
    80003058:	ffffd097          	auipc	ra,0xffffd
    8000305c:	4ec080e7          	jalr	1260(ra) # 80000544 <panic>

0000000080003060 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003060:	1101                	addi	sp,sp,-32
    80003062:	ec06                	sd	ra,24(sp)
    80003064:	e822                	sd	s0,16(sp)
    80003066:	e426                	sd	s1,8(sp)
    80003068:	e04a                	sd	s2,0(sp)
    8000306a:	1000                	addi	s0,sp,32
    8000306c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000306e:	01050913          	addi	s2,a0,16
    80003072:	854a                	mv	a0,s2
    80003074:	00001097          	auipc	ra,0x1
    80003078:	42a080e7          	jalr	1066(ra) # 8000449e <holdingsleep>
    8000307c:	c92d                	beqz	a0,800030ee <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000307e:	854a                	mv	a0,s2
    80003080:	00001097          	auipc	ra,0x1
    80003084:	3da080e7          	jalr	986(ra) # 8000445a <releasesleep>

  acquire(&bcache.lock);
    80003088:	00014517          	auipc	a0,0x14
    8000308c:	94050513          	addi	a0,a0,-1728 # 800169c8 <bcache>
    80003090:	ffffe097          	auipc	ra,0xffffe
    80003094:	b5a080e7          	jalr	-1190(ra) # 80000bea <acquire>
  b->refcnt--;
    80003098:	40bc                	lw	a5,64(s1)
    8000309a:	37fd                	addiw	a5,a5,-1
    8000309c:	0007871b          	sext.w	a4,a5
    800030a0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030a2:	eb05                	bnez	a4,800030d2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030a4:	68bc                	ld	a5,80(s1)
    800030a6:	64b8                	ld	a4,72(s1)
    800030a8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030aa:	64bc                	ld	a5,72(s1)
    800030ac:	68b8                	ld	a4,80(s1)
    800030ae:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030b0:	0001c797          	auipc	a5,0x1c
    800030b4:	91878793          	addi	a5,a5,-1768 # 8001e9c8 <bcache+0x8000>
    800030b8:	2b87b703          	ld	a4,696(a5)
    800030bc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030be:	0001c717          	auipc	a4,0x1c
    800030c2:	b7270713          	addi	a4,a4,-1166 # 8001ec30 <bcache+0x8268>
    800030c6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030c8:	2b87b703          	ld	a4,696(a5)
    800030cc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030ce:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030d2:	00014517          	auipc	a0,0x14
    800030d6:	8f650513          	addi	a0,a0,-1802 # 800169c8 <bcache>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	bc4080e7          	jalr	-1084(ra) # 80000c9e <release>
}
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6902                	ld	s2,0(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret
    panic("brelse");
    800030ee:	00005517          	auipc	a0,0x5
    800030f2:	47250513          	addi	a0,a0,1138 # 80008560 <syscalls+0xe0>
    800030f6:	ffffd097          	auipc	ra,0xffffd
    800030fa:	44e080e7          	jalr	1102(ra) # 80000544 <panic>

00000000800030fe <bpin>:

void
bpin(struct buf *b) {
    800030fe:	1101                	addi	sp,sp,-32
    80003100:	ec06                	sd	ra,24(sp)
    80003102:	e822                	sd	s0,16(sp)
    80003104:	e426                	sd	s1,8(sp)
    80003106:	1000                	addi	s0,sp,32
    80003108:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000310a:	00014517          	auipc	a0,0x14
    8000310e:	8be50513          	addi	a0,a0,-1858 # 800169c8 <bcache>
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	ad8080e7          	jalr	-1320(ra) # 80000bea <acquire>
  b->refcnt++;
    8000311a:	40bc                	lw	a5,64(s1)
    8000311c:	2785                	addiw	a5,a5,1
    8000311e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003120:	00014517          	auipc	a0,0x14
    80003124:	8a850513          	addi	a0,a0,-1880 # 800169c8 <bcache>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	b76080e7          	jalr	-1162(ra) # 80000c9e <release>
}
    80003130:	60e2                	ld	ra,24(sp)
    80003132:	6442                	ld	s0,16(sp)
    80003134:	64a2                	ld	s1,8(sp)
    80003136:	6105                	addi	sp,sp,32
    80003138:	8082                	ret

000000008000313a <bunpin>:

void
bunpin(struct buf *b) {
    8000313a:	1101                	addi	sp,sp,-32
    8000313c:	ec06                	sd	ra,24(sp)
    8000313e:	e822                	sd	s0,16(sp)
    80003140:	e426                	sd	s1,8(sp)
    80003142:	1000                	addi	s0,sp,32
    80003144:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003146:	00014517          	auipc	a0,0x14
    8000314a:	88250513          	addi	a0,a0,-1918 # 800169c8 <bcache>
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	a9c080e7          	jalr	-1380(ra) # 80000bea <acquire>
  b->refcnt--;
    80003156:	40bc                	lw	a5,64(s1)
    80003158:	37fd                	addiw	a5,a5,-1
    8000315a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000315c:	00014517          	auipc	a0,0x14
    80003160:	86c50513          	addi	a0,a0,-1940 # 800169c8 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b3a080e7          	jalr	-1222(ra) # 80000c9e <release>
}
    8000316c:	60e2                	ld	ra,24(sp)
    8000316e:	6442                	ld	s0,16(sp)
    80003170:	64a2                	ld	s1,8(sp)
    80003172:	6105                	addi	sp,sp,32
    80003174:	8082                	ret

0000000080003176 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003176:	1101                	addi	sp,sp,-32
    80003178:	ec06                	sd	ra,24(sp)
    8000317a:	e822                	sd	s0,16(sp)
    8000317c:	e426                	sd	s1,8(sp)
    8000317e:	e04a                	sd	s2,0(sp)
    80003180:	1000                	addi	s0,sp,32
    80003182:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003184:	00d5d59b          	srliw	a1,a1,0xd
    80003188:	0001c797          	auipc	a5,0x1c
    8000318c:	f1c7a783          	lw	a5,-228(a5) # 8001f0a4 <sb+0x1c>
    80003190:	9dbd                	addw	a1,a1,a5
    80003192:	00000097          	auipc	ra,0x0
    80003196:	d9e080e7          	jalr	-610(ra) # 80002f30 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000319a:	0074f713          	andi	a4,s1,7
    8000319e:	4785                	li	a5,1
    800031a0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031a4:	14ce                	slli	s1,s1,0x33
    800031a6:	90d9                	srli	s1,s1,0x36
    800031a8:	00950733          	add	a4,a0,s1
    800031ac:	05874703          	lbu	a4,88(a4)
    800031b0:	00e7f6b3          	and	a3,a5,a4
    800031b4:	c69d                	beqz	a3,800031e2 <bfree+0x6c>
    800031b6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031b8:	94aa                	add	s1,s1,a0
    800031ba:	fff7c793          	not	a5,a5
    800031be:	8ff9                	and	a5,a5,a4
    800031c0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031c4:	00001097          	auipc	ra,0x1
    800031c8:	120080e7          	jalr	288(ra) # 800042e4 <log_write>
  brelse(bp);
    800031cc:	854a                	mv	a0,s2
    800031ce:	00000097          	auipc	ra,0x0
    800031d2:	e92080e7          	jalr	-366(ra) # 80003060 <brelse>
}
    800031d6:	60e2                	ld	ra,24(sp)
    800031d8:	6442                	ld	s0,16(sp)
    800031da:	64a2                	ld	s1,8(sp)
    800031dc:	6902                	ld	s2,0(sp)
    800031de:	6105                	addi	sp,sp,32
    800031e0:	8082                	ret
    panic("freeing free block");
    800031e2:	00005517          	auipc	a0,0x5
    800031e6:	38650513          	addi	a0,a0,902 # 80008568 <syscalls+0xe8>
    800031ea:	ffffd097          	auipc	ra,0xffffd
    800031ee:	35a080e7          	jalr	858(ra) # 80000544 <panic>

00000000800031f2 <balloc>:
{
    800031f2:	711d                	addi	sp,sp,-96
    800031f4:	ec86                	sd	ra,88(sp)
    800031f6:	e8a2                	sd	s0,80(sp)
    800031f8:	e4a6                	sd	s1,72(sp)
    800031fa:	e0ca                	sd	s2,64(sp)
    800031fc:	fc4e                	sd	s3,56(sp)
    800031fe:	f852                	sd	s4,48(sp)
    80003200:	f456                	sd	s5,40(sp)
    80003202:	f05a                	sd	s6,32(sp)
    80003204:	ec5e                	sd	s7,24(sp)
    80003206:	e862                	sd	s8,16(sp)
    80003208:	e466                	sd	s9,8(sp)
    8000320a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000320c:	0001c797          	auipc	a5,0x1c
    80003210:	e807a783          	lw	a5,-384(a5) # 8001f08c <sb+0x4>
    80003214:	10078163          	beqz	a5,80003316 <balloc+0x124>
    80003218:	8baa                	mv	s7,a0
    8000321a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000321c:	0001cb17          	auipc	s6,0x1c
    80003220:	e6cb0b13          	addi	s6,s6,-404 # 8001f088 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003224:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003226:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003228:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000322a:	6c89                	lui	s9,0x2
    8000322c:	a061                	j	800032b4 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000322e:	974a                	add	a4,a4,s2
    80003230:	8fd5                	or	a5,a5,a3
    80003232:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003236:	854a                	mv	a0,s2
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	0ac080e7          	jalr	172(ra) # 800042e4 <log_write>
        brelse(bp);
    80003240:	854a                	mv	a0,s2
    80003242:	00000097          	auipc	ra,0x0
    80003246:	e1e080e7          	jalr	-482(ra) # 80003060 <brelse>
  bp = bread(dev, bno);
    8000324a:	85a6                	mv	a1,s1
    8000324c:	855e                	mv	a0,s7
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	ce2080e7          	jalr	-798(ra) # 80002f30 <bread>
    80003256:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003258:	40000613          	li	a2,1024
    8000325c:	4581                	li	a1,0
    8000325e:	05850513          	addi	a0,a0,88
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	a84080e7          	jalr	-1404(ra) # 80000ce6 <memset>
  log_write(bp);
    8000326a:	854a                	mv	a0,s2
    8000326c:	00001097          	auipc	ra,0x1
    80003270:	078080e7          	jalr	120(ra) # 800042e4 <log_write>
  brelse(bp);
    80003274:	854a                	mv	a0,s2
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	dea080e7          	jalr	-534(ra) # 80003060 <brelse>
}
    8000327e:	8526                	mv	a0,s1
    80003280:	60e6                	ld	ra,88(sp)
    80003282:	6446                	ld	s0,80(sp)
    80003284:	64a6                	ld	s1,72(sp)
    80003286:	6906                	ld	s2,64(sp)
    80003288:	79e2                	ld	s3,56(sp)
    8000328a:	7a42                	ld	s4,48(sp)
    8000328c:	7aa2                	ld	s5,40(sp)
    8000328e:	7b02                	ld	s6,32(sp)
    80003290:	6be2                	ld	s7,24(sp)
    80003292:	6c42                	ld	s8,16(sp)
    80003294:	6ca2                	ld	s9,8(sp)
    80003296:	6125                	addi	sp,sp,96
    80003298:	8082                	ret
    brelse(bp);
    8000329a:	854a                	mv	a0,s2
    8000329c:	00000097          	auipc	ra,0x0
    800032a0:	dc4080e7          	jalr	-572(ra) # 80003060 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032a4:	015c87bb          	addw	a5,s9,s5
    800032a8:	00078a9b          	sext.w	s5,a5
    800032ac:	004b2703          	lw	a4,4(s6)
    800032b0:	06eaf363          	bgeu	s5,a4,80003316 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800032b4:	41fad79b          	sraiw	a5,s5,0x1f
    800032b8:	0137d79b          	srliw	a5,a5,0x13
    800032bc:	015787bb          	addw	a5,a5,s5
    800032c0:	40d7d79b          	sraiw	a5,a5,0xd
    800032c4:	01cb2583          	lw	a1,28(s6)
    800032c8:	9dbd                	addw	a1,a1,a5
    800032ca:	855e                	mv	a0,s7
    800032cc:	00000097          	auipc	ra,0x0
    800032d0:	c64080e7          	jalr	-924(ra) # 80002f30 <bread>
    800032d4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d6:	004b2503          	lw	a0,4(s6)
    800032da:	000a849b          	sext.w	s1,s5
    800032de:	8662                	mv	a2,s8
    800032e0:	faa4fde3          	bgeu	s1,a0,8000329a <balloc+0xa8>
      m = 1 << (bi % 8);
    800032e4:	41f6579b          	sraiw	a5,a2,0x1f
    800032e8:	01d7d69b          	srliw	a3,a5,0x1d
    800032ec:	00c6873b          	addw	a4,a3,a2
    800032f0:	00777793          	andi	a5,a4,7
    800032f4:	9f95                	subw	a5,a5,a3
    800032f6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032fa:	4037571b          	sraiw	a4,a4,0x3
    800032fe:	00e906b3          	add	a3,s2,a4
    80003302:	0586c683          	lbu	a3,88(a3)
    80003306:	00d7f5b3          	and	a1,a5,a3
    8000330a:	d195                	beqz	a1,8000322e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330c:	2605                	addiw	a2,a2,1
    8000330e:	2485                	addiw	s1,s1,1
    80003310:	fd4618e3          	bne	a2,s4,800032e0 <balloc+0xee>
    80003314:	b759                	j	8000329a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003316:	00005517          	auipc	a0,0x5
    8000331a:	26a50513          	addi	a0,a0,618 # 80008580 <syscalls+0x100>
    8000331e:	ffffd097          	auipc	ra,0xffffd
    80003322:	270080e7          	jalr	624(ra) # 8000058e <printf>
  return 0;
    80003326:	4481                	li	s1,0
    80003328:	bf99                	j	8000327e <balloc+0x8c>

000000008000332a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000332a:	7179                	addi	sp,sp,-48
    8000332c:	f406                	sd	ra,40(sp)
    8000332e:	f022                	sd	s0,32(sp)
    80003330:	ec26                	sd	s1,24(sp)
    80003332:	e84a                	sd	s2,16(sp)
    80003334:	e44e                	sd	s3,8(sp)
    80003336:	e052                	sd	s4,0(sp)
    80003338:	1800                	addi	s0,sp,48
    8000333a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000333c:	47ad                	li	a5,11
    8000333e:	02b7e763          	bltu	a5,a1,8000336c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003342:	02059493          	slli	s1,a1,0x20
    80003346:	9081                	srli	s1,s1,0x20
    80003348:	048a                	slli	s1,s1,0x2
    8000334a:	94aa                	add	s1,s1,a0
    8000334c:	0504a903          	lw	s2,80(s1)
    80003350:	06091e63          	bnez	s2,800033cc <bmap+0xa2>
      addr = balloc(ip->dev);
    80003354:	4108                	lw	a0,0(a0)
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	e9c080e7          	jalr	-356(ra) # 800031f2 <balloc>
    8000335e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003362:	06090563          	beqz	s2,800033cc <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003366:	0524a823          	sw	s2,80(s1)
    8000336a:	a08d                	j	800033cc <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000336c:	ff45849b          	addiw	s1,a1,-12
    80003370:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003374:	0ff00793          	li	a5,255
    80003378:	08e7e563          	bltu	a5,a4,80003402 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000337c:	08052903          	lw	s2,128(a0)
    80003380:	00091d63          	bnez	s2,8000339a <bmap+0x70>
      addr = balloc(ip->dev);
    80003384:	4108                	lw	a0,0(a0)
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	e6c080e7          	jalr	-404(ra) # 800031f2 <balloc>
    8000338e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003392:	02090d63          	beqz	s2,800033cc <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003396:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000339a:	85ca                	mv	a1,s2
    8000339c:	0009a503          	lw	a0,0(s3)
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	b90080e7          	jalr	-1136(ra) # 80002f30 <bread>
    800033a8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033aa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ae:	02049593          	slli	a1,s1,0x20
    800033b2:	9181                	srli	a1,a1,0x20
    800033b4:	058a                	slli	a1,a1,0x2
    800033b6:	00b784b3          	add	s1,a5,a1
    800033ba:	0004a903          	lw	s2,0(s1)
    800033be:	02090063          	beqz	s2,800033de <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033c2:	8552                	mv	a0,s4
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	c9c080e7          	jalr	-868(ra) # 80003060 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033cc:	854a                	mv	a0,s2
    800033ce:	70a2                	ld	ra,40(sp)
    800033d0:	7402                	ld	s0,32(sp)
    800033d2:	64e2                	ld	s1,24(sp)
    800033d4:	6942                	ld	s2,16(sp)
    800033d6:	69a2                	ld	s3,8(sp)
    800033d8:	6a02                	ld	s4,0(sp)
    800033da:	6145                	addi	sp,sp,48
    800033dc:	8082                	ret
      addr = balloc(ip->dev);
    800033de:	0009a503          	lw	a0,0(s3)
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	e10080e7          	jalr	-496(ra) # 800031f2 <balloc>
    800033ea:	0005091b          	sext.w	s2,a0
      if(addr){
    800033ee:	fc090ae3          	beqz	s2,800033c2 <bmap+0x98>
        a[bn] = addr;
    800033f2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033f6:	8552                	mv	a0,s4
    800033f8:	00001097          	auipc	ra,0x1
    800033fc:	eec080e7          	jalr	-276(ra) # 800042e4 <log_write>
    80003400:	b7c9                	j	800033c2 <bmap+0x98>
  panic("bmap: out of range");
    80003402:	00005517          	auipc	a0,0x5
    80003406:	19650513          	addi	a0,a0,406 # 80008598 <syscalls+0x118>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	13a080e7          	jalr	314(ra) # 80000544 <panic>

0000000080003412 <iget>:
{
    80003412:	7179                	addi	sp,sp,-48
    80003414:	f406                	sd	ra,40(sp)
    80003416:	f022                	sd	s0,32(sp)
    80003418:	ec26                	sd	s1,24(sp)
    8000341a:	e84a                	sd	s2,16(sp)
    8000341c:	e44e                	sd	s3,8(sp)
    8000341e:	e052                	sd	s4,0(sp)
    80003420:	1800                	addi	s0,sp,48
    80003422:	89aa                	mv	s3,a0
    80003424:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003426:	0001c517          	auipc	a0,0x1c
    8000342a:	c8250513          	addi	a0,a0,-894 # 8001f0a8 <itable>
    8000342e:	ffffd097          	auipc	ra,0xffffd
    80003432:	7bc080e7          	jalr	1980(ra) # 80000bea <acquire>
  empty = 0;
    80003436:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003438:	0001c497          	auipc	s1,0x1c
    8000343c:	c8848493          	addi	s1,s1,-888 # 8001f0c0 <itable+0x18>
    80003440:	0001d697          	auipc	a3,0x1d
    80003444:	71068693          	addi	a3,a3,1808 # 80020b50 <log>
    80003448:	a039                	j	80003456 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000344a:	02090b63          	beqz	s2,80003480 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000344e:	08848493          	addi	s1,s1,136
    80003452:	02d48a63          	beq	s1,a3,80003486 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003456:	449c                	lw	a5,8(s1)
    80003458:	fef059e3          	blez	a5,8000344a <iget+0x38>
    8000345c:	4098                	lw	a4,0(s1)
    8000345e:	ff3716e3          	bne	a4,s3,8000344a <iget+0x38>
    80003462:	40d8                	lw	a4,4(s1)
    80003464:	ff4713e3          	bne	a4,s4,8000344a <iget+0x38>
      ip->ref++;
    80003468:	2785                	addiw	a5,a5,1
    8000346a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000346c:	0001c517          	auipc	a0,0x1c
    80003470:	c3c50513          	addi	a0,a0,-964 # 8001f0a8 <itable>
    80003474:	ffffe097          	auipc	ra,0xffffe
    80003478:	82a080e7          	jalr	-2006(ra) # 80000c9e <release>
      return ip;
    8000347c:	8926                	mv	s2,s1
    8000347e:	a03d                	j	800034ac <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003480:	f7f9                	bnez	a5,8000344e <iget+0x3c>
    80003482:	8926                	mv	s2,s1
    80003484:	b7e9                	j	8000344e <iget+0x3c>
  if(empty == 0)
    80003486:	02090c63          	beqz	s2,800034be <iget+0xac>
  ip->dev = dev;
    8000348a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000348e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003492:	4785                	li	a5,1
    80003494:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003498:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000349c:	0001c517          	auipc	a0,0x1c
    800034a0:	c0c50513          	addi	a0,a0,-1012 # 8001f0a8 <itable>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	7fa080e7          	jalr	2042(ra) # 80000c9e <release>
}
    800034ac:	854a                	mv	a0,s2
    800034ae:	70a2                	ld	ra,40(sp)
    800034b0:	7402                	ld	s0,32(sp)
    800034b2:	64e2                	ld	s1,24(sp)
    800034b4:	6942                	ld	s2,16(sp)
    800034b6:	69a2                	ld	s3,8(sp)
    800034b8:	6a02                	ld	s4,0(sp)
    800034ba:	6145                	addi	sp,sp,48
    800034bc:	8082                	ret
    panic("iget: no inodes");
    800034be:	00005517          	auipc	a0,0x5
    800034c2:	0f250513          	addi	a0,a0,242 # 800085b0 <syscalls+0x130>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	07e080e7          	jalr	126(ra) # 80000544 <panic>

00000000800034ce <fsinit>:
fsinit(int dev) {
    800034ce:	7179                	addi	sp,sp,-48
    800034d0:	f406                	sd	ra,40(sp)
    800034d2:	f022                	sd	s0,32(sp)
    800034d4:	ec26                	sd	s1,24(sp)
    800034d6:	e84a                	sd	s2,16(sp)
    800034d8:	e44e                	sd	s3,8(sp)
    800034da:	1800                	addi	s0,sp,48
    800034dc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034de:	4585                	li	a1,1
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	a50080e7          	jalr	-1456(ra) # 80002f30 <bread>
    800034e8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034ea:	0001c997          	auipc	s3,0x1c
    800034ee:	b9e98993          	addi	s3,s3,-1122 # 8001f088 <sb>
    800034f2:	02000613          	li	a2,32
    800034f6:	05850593          	addi	a1,a0,88
    800034fa:	854e                	mv	a0,s3
    800034fc:	ffffe097          	auipc	ra,0xffffe
    80003500:	84a080e7          	jalr	-1974(ra) # 80000d46 <memmove>
  brelse(bp);
    80003504:	8526                	mv	a0,s1
    80003506:	00000097          	auipc	ra,0x0
    8000350a:	b5a080e7          	jalr	-1190(ra) # 80003060 <brelse>
  if(sb.magic != FSMAGIC)
    8000350e:	0009a703          	lw	a4,0(s3)
    80003512:	102037b7          	lui	a5,0x10203
    80003516:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000351a:	02f71263          	bne	a4,a5,8000353e <fsinit+0x70>
  initlog(dev, &sb);
    8000351e:	0001c597          	auipc	a1,0x1c
    80003522:	b6a58593          	addi	a1,a1,-1174 # 8001f088 <sb>
    80003526:	854a                	mv	a0,s2
    80003528:	00001097          	auipc	ra,0x1
    8000352c:	b40080e7          	jalr	-1216(ra) # 80004068 <initlog>
}
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6942                	ld	s2,16(sp)
    80003538:	69a2                	ld	s3,8(sp)
    8000353a:	6145                	addi	sp,sp,48
    8000353c:	8082                	ret
    panic("invalid file system");
    8000353e:	00005517          	auipc	a0,0x5
    80003542:	08250513          	addi	a0,a0,130 # 800085c0 <syscalls+0x140>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	ffe080e7          	jalr	-2(ra) # 80000544 <panic>

000000008000354e <iinit>:
{
    8000354e:	7179                	addi	sp,sp,-48
    80003550:	f406                	sd	ra,40(sp)
    80003552:	f022                	sd	s0,32(sp)
    80003554:	ec26                	sd	s1,24(sp)
    80003556:	e84a                	sd	s2,16(sp)
    80003558:	e44e                	sd	s3,8(sp)
    8000355a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000355c:	00005597          	auipc	a1,0x5
    80003560:	07c58593          	addi	a1,a1,124 # 800085d8 <syscalls+0x158>
    80003564:	0001c517          	auipc	a0,0x1c
    80003568:	b4450513          	addi	a0,a0,-1212 # 8001f0a8 <itable>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	5ee080e7          	jalr	1518(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003574:	0001c497          	auipc	s1,0x1c
    80003578:	b5c48493          	addi	s1,s1,-1188 # 8001f0d0 <itable+0x28>
    8000357c:	0001d997          	auipc	s3,0x1d
    80003580:	5e498993          	addi	s3,s3,1508 # 80020b60 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003584:	00005917          	auipc	s2,0x5
    80003588:	05c90913          	addi	s2,s2,92 # 800085e0 <syscalls+0x160>
    8000358c:	85ca                	mv	a1,s2
    8000358e:	8526                	mv	a0,s1
    80003590:	00001097          	auipc	ra,0x1
    80003594:	e3a080e7          	jalr	-454(ra) # 800043ca <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003598:	08848493          	addi	s1,s1,136
    8000359c:	ff3498e3          	bne	s1,s3,8000358c <iinit+0x3e>
}
    800035a0:	70a2                	ld	ra,40(sp)
    800035a2:	7402                	ld	s0,32(sp)
    800035a4:	64e2                	ld	s1,24(sp)
    800035a6:	6942                	ld	s2,16(sp)
    800035a8:	69a2                	ld	s3,8(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret

00000000800035ae <ialloc>:
{
    800035ae:	715d                	addi	sp,sp,-80
    800035b0:	e486                	sd	ra,72(sp)
    800035b2:	e0a2                	sd	s0,64(sp)
    800035b4:	fc26                	sd	s1,56(sp)
    800035b6:	f84a                	sd	s2,48(sp)
    800035b8:	f44e                	sd	s3,40(sp)
    800035ba:	f052                	sd	s4,32(sp)
    800035bc:	ec56                	sd	s5,24(sp)
    800035be:	e85a                	sd	s6,16(sp)
    800035c0:	e45e                	sd	s7,8(sp)
    800035c2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035c4:	0001c717          	auipc	a4,0x1c
    800035c8:	ad072703          	lw	a4,-1328(a4) # 8001f094 <sb+0xc>
    800035cc:	4785                	li	a5,1
    800035ce:	04e7fa63          	bgeu	a5,a4,80003622 <ialloc+0x74>
    800035d2:	8aaa                	mv	s5,a0
    800035d4:	8bae                	mv	s7,a1
    800035d6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035d8:	0001ca17          	auipc	s4,0x1c
    800035dc:	ab0a0a13          	addi	s4,s4,-1360 # 8001f088 <sb>
    800035e0:	00048b1b          	sext.w	s6,s1
    800035e4:	0044d593          	srli	a1,s1,0x4
    800035e8:	018a2783          	lw	a5,24(s4)
    800035ec:	9dbd                	addw	a1,a1,a5
    800035ee:	8556                	mv	a0,s5
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	940080e7          	jalr	-1728(ra) # 80002f30 <bread>
    800035f8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035fa:	05850993          	addi	s3,a0,88
    800035fe:	00f4f793          	andi	a5,s1,15
    80003602:	079a                	slli	a5,a5,0x6
    80003604:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003606:	00099783          	lh	a5,0(s3)
    8000360a:	c3a1                	beqz	a5,8000364a <ialloc+0x9c>
    brelse(bp);
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	a54080e7          	jalr	-1452(ra) # 80003060 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003614:	0485                	addi	s1,s1,1
    80003616:	00ca2703          	lw	a4,12(s4)
    8000361a:	0004879b          	sext.w	a5,s1
    8000361e:	fce7e1e3          	bltu	a5,a4,800035e0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003622:	00005517          	auipc	a0,0x5
    80003626:	fc650513          	addi	a0,a0,-58 # 800085e8 <syscalls+0x168>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	f64080e7          	jalr	-156(ra) # 8000058e <printf>
  return 0;
    80003632:	4501                	li	a0,0
}
    80003634:	60a6                	ld	ra,72(sp)
    80003636:	6406                	ld	s0,64(sp)
    80003638:	74e2                	ld	s1,56(sp)
    8000363a:	7942                	ld	s2,48(sp)
    8000363c:	79a2                	ld	s3,40(sp)
    8000363e:	7a02                	ld	s4,32(sp)
    80003640:	6ae2                	ld	s5,24(sp)
    80003642:	6b42                	ld	s6,16(sp)
    80003644:	6ba2                	ld	s7,8(sp)
    80003646:	6161                	addi	sp,sp,80
    80003648:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000364a:	04000613          	li	a2,64
    8000364e:	4581                	li	a1,0
    80003650:	854e                	mv	a0,s3
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	694080e7          	jalr	1684(ra) # 80000ce6 <memset>
      dip->type = type;
    8000365a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000365e:	854a                	mv	a0,s2
    80003660:	00001097          	auipc	ra,0x1
    80003664:	c84080e7          	jalr	-892(ra) # 800042e4 <log_write>
      brelse(bp);
    80003668:	854a                	mv	a0,s2
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	9f6080e7          	jalr	-1546(ra) # 80003060 <brelse>
      return iget(dev, inum);
    80003672:	85da                	mv	a1,s6
    80003674:	8556                	mv	a0,s5
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	d9c080e7          	jalr	-612(ra) # 80003412 <iget>
    8000367e:	bf5d                	j	80003634 <ialloc+0x86>

0000000080003680 <iupdate>:
{
    80003680:	1101                	addi	sp,sp,-32
    80003682:	ec06                	sd	ra,24(sp)
    80003684:	e822                	sd	s0,16(sp)
    80003686:	e426                	sd	s1,8(sp)
    80003688:	e04a                	sd	s2,0(sp)
    8000368a:	1000                	addi	s0,sp,32
    8000368c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000368e:	415c                	lw	a5,4(a0)
    80003690:	0047d79b          	srliw	a5,a5,0x4
    80003694:	0001c597          	auipc	a1,0x1c
    80003698:	a0c5a583          	lw	a1,-1524(a1) # 8001f0a0 <sb+0x18>
    8000369c:	9dbd                	addw	a1,a1,a5
    8000369e:	4108                	lw	a0,0(a0)
    800036a0:	00000097          	auipc	ra,0x0
    800036a4:	890080e7          	jalr	-1904(ra) # 80002f30 <bread>
    800036a8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036aa:	05850793          	addi	a5,a0,88
    800036ae:	40c8                	lw	a0,4(s1)
    800036b0:	893d                	andi	a0,a0,15
    800036b2:	051a                	slli	a0,a0,0x6
    800036b4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036b6:	04449703          	lh	a4,68(s1)
    800036ba:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036be:	04649703          	lh	a4,70(s1)
    800036c2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036c6:	04849703          	lh	a4,72(s1)
    800036ca:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036ce:	04a49703          	lh	a4,74(s1)
    800036d2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036d6:	44f8                	lw	a4,76(s1)
    800036d8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036da:	03400613          	li	a2,52
    800036de:	05048593          	addi	a1,s1,80
    800036e2:	0531                	addi	a0,a0,12
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	662080e7          	jalr	1634(ra) # 80000d46 <memmove>
  log_write(bp);
    800036ec:	854a                	mv	a0,s2
    800036ee:	00001097          	auipc	ra,0x1
    800036f2:	bf6080e7          	jalr	-1034(ra) # 800042e4 <log_write>
  brelse(bp);
    800036f6:	854a                	mv	a0,s2
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	968080e7          	jalr	-1688(ra) # 80003060 <brelse>
}
    80003700:	60e2                	ld	ra,24(sp)
    80003702:	6442                	ld	s0,16(sp)
    80003704:	64a2                	ld	s1,8(sp)
    80003706:	6902                	ld	s2,0(sp)
    80003708:	6105                	addi	sp,sp,32
    8000370a:	8082                	ret

000000008000370c <idup>:
{
    8000370c:	1101                	addi	sp,sp,-32
    8000370e:	ec06                	sd	ra,24(sp)
    80003710:	e822                	sd	s0,16(sp)
    80003712:	e426                	sd	s1,8(sp)
    80003714:	1000                	addi	s0,sp,32
    80003716:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003718:	0001c517          	auipc	a0,0x1c
    8000371c:	99050513          	addi	a0,a0,-1648 # 8001f0a8 <itable>
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	4ca080e7          	jalr	1226(ra) # 80000bea <acquire>
  ip->ref++;
    80003728:	449c                	lw	a5,8(s1)
    8000372a:	2785                	addiw	a5,a5,1
    8000372c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000372e:	0001c517          	auipc	a0,0x1c
    80003732:	97a50513          	addi	a0,a0,-1670 # 8001f0a8 <itable>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	568080e7          	jalr	1384(ra) # 80000c9e <release>
}
    8000373e:	8526                	mv	a0,s1
    80003740:	60e2                	ld	ra,24(sp)
    80003742:	6442                	ld	s0,16(sp)
    80003744:	64a2                	ld	s1,8(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret

000000008000374a <ilock>:
{
    8000374a:	1101                	addi	sp,sp,-32
    8000374c:	ec06                	sd	ra,24(sp)
    8000374e:	e822                	sd	s0,16(sp)
    80003750:	e426                	sd	s1,8(sp)
    80003752:	e04a                	sd	s2,0(sp)
    80003754:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003756:	c115                	beqz	a0,8000377a <ilock+0x30>
    80003758:	84aa                	mv	s1,a0
    8000375a:	451c                	lw	a5,8(a0)
    8000375c:	00f05f63          	blez	a5,8000377a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003760:	0541                	addi	a0,a0,16
    80003762:	00001097          	auipc	ra,0x1
    80003766:	ca2080e7          	jalr	-862(ra) # 80004404 <acquiresleep>
  if(ip->valid == 0){
    8000376a:	40bc                	lw	a5,64(s1)
    8000376c:	cf99                	beqz	a5,8000378a <ilock+0x40>
}
    8000376e:	60e2                	ld	ra,24(sp)
    80003770:	6442                	ld	s0,16(sp)
    80003772:	64a2                	ld	s1,8(sp)
    80003774:	6902                	ld	s2,0(sp)
    80003776:	6105                	addi	sp,sp,32
    80003778:	8082                	ret
    panic("ilock");
    8000377a:	00005517          	auipc	a0,0x5
    8000377e:	e8650513          	addi	a0,a0,-378 # 80008600 <syscalls+0x180>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	dc2080e7          	jalr	-574(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000378a:	40dc                	lw	a5,4(s1)
    8000378c:	0047d79b          	srliw	a5,a5,0x4
    80003790:	0001c597          	auipc	a1,0x1c
    80003794:	9105a583          	lw	a1,-1776(a1) # 8001f0a0 <sb+0x18>
    80003798:	9dbd                	addw	a1,a1,a5
    8000379a:	4088                	lw	a0,0(s1)
    8000379c:	fffff097          	auipc	ra,0xfffff
    800037a0:	794080e7          	jalr	1940(ra) # 80002f30 <bread>
    800037a4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a6:	05850593          	addi	a1,a0,88
    800037aa:	40dc                	lw	a5,4(s1)
    800037ac:	8bbd                	andi	a5,a5,15
    800037ae:	079a                	slli	a5,a5,0x6
    800037b0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037b2:	00059783          	lh	a5,0(a1)
    800037b6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037ba:	00259783          	lh	a5,2(a1)
    800037be:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037c2:	00459783          	lh	a5,4(a1)
    800037c6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ca:	00659783          	lh	a5,6(a1)
    800037ce:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037d2:	459c                	lw	a5,8(a1)
    800037d4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037d6:	03400613          	li	a2,52
    800037da:	05b1                	addi	a1,a1,12
    800037dc:	05048513          	addi	a0,s1,80
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	566080e7          	jalr	1382(ra) # 80000d46 <memmove>
    brelse(bp);
    800037e8:	854a                	mv	a0,s2
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	876080e7          	jalr	-1930(ra) # 80003060 <brelse>
    ip->valid = 1;
    800037f2:	4785                	li	a5,1
    800037f4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037f6:	04449783          	lh	a5,68(s1)
    800037fa:	fbb5                	bnez	a5,8000376e <ilock+0x24>
      panic("ilock: no type");
    800037fc:	00005517          	auipc	a0,0x5
    80003800:	e0c50513          	addi	a0,a0,-500 # 80008608 <syscalls+0x188>
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	d40080e7          	jalr	-704(ra) # 80000544 <panic>

000000008000380c <iunlock>:
{
    8000380c:	1101                	addi	sp,sp,-32
    8000380e:	ec06                	sd	ra,24(sp)
    80003810:	e822                	sd	s0,16(sp)
    80003812:	e426                	sd	s1,8(sp)
    80003814:	e04a                	sd	s2,0(sp)
    80003816:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003818:	c905                	beqz	a0,80003848 <iunlock+0x3c>
    8000381a:	84aa                	mv	s1,a0
    8000381c:	01050913          	addi	s2,a0,16
    80003820:	854a                	mv	a0,s2
    80003822:	00001097          	auipc	ra,0x1
    80003826:	c7c080e7          	jalr	-900(ra) # 8000449e <holdingsleep>
    8000382a:	cd19                	beqz	a0,80003848 <iunlock+0x3c>
    8000382c:	449c                	lw	a5,8(s1)
    8000382e:	00f05d63          	blez	a5,80003848 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003832:	854a                	mv	a0,s2
    80003834:	00001097          	auipc	ra,0x1
    80003838:	c26080e7          	jalr	-986(ra) # 8000445a <releasesleep>
}
    8000383c:	60e2                	ld	ra,24(sp)
    8000383e:	6442                	ld	s0,16(sp)
    80003840:	64a2                	ld	s1,8(sp)
    80003842:	6902                	ld	s2,0(sp)
    80003844:	6105                	addi	sp,sp,32
    80003846:	8082                	ret
    panic("iunlock");
    80003848:	00005517          	auipc	a0,0x5
    8000384c:	dd050513          	addi	a0,a0,-560 # 80008618 <syscalls+0x198>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	cf4080e7          	jalr	-780(ra) # 80000544 <panic>

0000000080003858 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003858:	7179                	addi	sp,sp,-48
    8000385a:	f406                	sd	ra,40(sp)
    8000385c:	f022                	sd	s0,32(sp)
    8000385e:	ec26                	sd	s1,24(sp)
    80003860:	e84a                	sd	s2,16(sp)
    80003862:	e44e                	sd	s3,8(sp)
    80003864:	e052                	sd	s4,0(sp)
    80003866:	1800                	addi	s0,sp,48
    80003868:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000386a:	05050493          	addi	s1,a0,80
    8000386e:	08050913          	addi	s2,a0,128
    80003872:	a021                	j	8000387a <itrunc+0x22>
    80003874:	0491                	addi	s1,s1,4
    80003876:	01248d63          	beq	s1,s2,80003890 <itrunc+0x38>
    if(ip->addrs[i]){
    8000387a:	408c                	lw	a1,0(s1)
    8000387c:	dde5                	beqz	a1,80003874 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000387e:	0009a503          	lw	a0,0(s3)
    80003882:	00000097          	auipc	ra,0x0
    80003886:	8f4080e7          	jalr	-1804(ra) # 80003176 <bfree>
      ip->addrs[i] = 0;
    8000388a:	0004a023          	sw	zero,0(s1)
    8000388e:	b7dd                	j	80003874 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003890:	0809a583          	lw	a1,128(s3)
    80003894:	e185                	bnez	a1,800038b4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003896:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000389a:	854e                	mv	a0,s3
    8000389c:	00000097          	auipc	ra,0x0
    800038a0:	de4080e7          	jalr	-540(ra) # 80003680 <iupdate>
}
    800038a4:	70a2                	ld	ra,40(sp)
    800038a6:	7402                	ld	s0,32(sp)
    800038a8:	64e2                	ld	s1,24(sp)
    800038aa:	6942                	ld	s2,16(sp)
    800038ac:	69a2                	ld	s3,8(sp)
    800038ae:	6a02                	ld	s4,0(sp)
    800038b0:	6145                	addi	sp,sp,48
    800038b2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038b4:	0009a503          	lw	a0,0(s3)
    800038b8:	fffff097          	auipc	ra,0xfffff
    800038bc:	678080e7          	jalr	1656(ra) # 80002f30 <bread>
    800038c0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038c2:	05850493          	addi	s1,a0,88
    800038c6:	45850913          	addi	s2,a0,1112
    800038ca:	a811                	j	800038de <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038cc:	0009a503          	lw	a0,0(s3)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	8a6080e7          	jalr	-1882(ra) # 80003176 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038d8:	0491                	addi	s1,s1,4
    800038da:	01248563          	beq	s1,s2,800038e4 <itrunc+0x8c>
      if(a[j])
    800038de:	408c                	lw	a1,0(s1)
    800038e0:	dde5                	beqz	a1,800038d8 <itrunc+0x80>
    800038e2:	b7ed                	j	800038cc <itrunc+0x74>
    brelse(bp);
    800038e4:	8552                	mv	a0,s4
    800038e6:	fffff097          	auipc	ra,0xfffff
    800038ea:	77a080e7          	jalr	1914(ra) # 80003060 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038ee:	0809a583          	lw	a1,128(s3)
    800038f2:	0009a503          	lw	a0,0(s3)
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	880080e7          	jalr	-1920(ra) # 80003176 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038fe:	0809a023          	sw	zero,128(s3)
    80003902:	bf51                	j	80003896 <itrunc+0x3e>

0000000080003904 <iput>:
{
    80003904:	1101                	addi	sp,sp,-32
    80003906:	ec06                	sd	ra,24(sp)
    80003908:	e822                	sd	s0,16(sp)
    8000390a:	e426                	sd	s1,8(sp)
    8000390c:	e04a                	sd	s2,0(sp)
    8000390e:	1000                	addi	s0,sp,32
    80003910:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003912:	0001b517          	auipc	a0,0x1b
    80003916:	79650513          	addi	a0,a0,1942 # 8001f0a8 <itable>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	2d0080e7          	jalr	720(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003922:	4498                	lw	a4,8(s1)
    80003924:	4785                	li	a5,1
    80003926:	02f70363          	beq	a4,a5,8000394c <iput+0x48>
  ip->ref--;
    8000392a:	449c                	lw	a5,8(s1)
    8000392c:	37fd                	addiw	a5,a5,-1
    8000392e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003930:	0001b517          	auipc	a0,0x1b
    80003934:	77850513          	addi	a0,a0,1912 # 8001f0a8 <itable>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	366080e7          	jalr	870(ra) # 80000c9e <release>
}
    80003940:	60e2                	ld	ra,24(sp)
    80003942:	6442                	ld	s0,16(sp)
    80003944:	64a2                	ld	s1,8(sp)
    80003946:	6902                	ld	s2,0(sp)
    80003948:	6105                	addi	sp,sp,32
    8000394a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000394c:	40bc                	lw	a5,64(s1)
    8000394e:	dff1                	beqz	a5,8000392a <iput+0x26>
    80003950:	04a49783          	lh	a5,74(s1)
    80003954:	fbf9                	bnez	a5,8000392a <iput+0x26>
    acquiresleep(&ip->lock);
    80003956:	01048913          	addi	s2,s1,16
    8000395a:	854a                	mv	a0,s2
    8000395c:	00001097          	auipc	ra,0x1
    80003960:	aa8080e7          	jalr	-1368(ra) # 80004404 <acquiresleep>
    release(&itable.lock);
    80003964:	0001b517          	auipc	a0,0x1b
    80003968:	74450513          	addi	a0,a0,1860 # 8001f0a8 <itable>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	332080e7          	jalr	818(ra) # 80000c9e <release>
    itrunc(ip);
    80003974:	8526                	mv	a0,s1
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	ee2080e7          	jalr	-286(ra) # 80003858 <itrunc>
    ip->type = 0;
    8000397e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003982:	8526                	mv	a0,s1
    80003984:	00000097          	auipc	ra,0x0
    80003988:	cfc080e7          	jalr	-772(ra) # 80003680 <iupdate>
    ip->valid = 0;
    8000398c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003990:	854a                	mv	a0,s2
    80003992:	00001097          	auipc	ra,0x1
    80003996:	ac8080e7          	jalr	-1336(ra) # 8000445a <releasesleep>
    acquire(&itable.lock);
    8000399a:	0001b517          	auipc	a0,0x1b
    8000399e:	70e50513          	addi	a0,a0,1806 # 8001f0a8 <itable>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	248080e7          	jalr	584(ra) # 80000bea <acquire>
    800039aa:	b741                	j	8000392a <iput+0x26>

00000000800039ac <iunlockput>:
{
    800039ac:	1101                	addi	sp,sp,-32
    800039ae:	ec06                	sd	ra,24(sp)
    800039b0:	e822                	sd	s0,16(sp)
    800039b2:	e426                	sd	s1,8(sp)
    800039b4:	1000                	addi	s0,sp,32
    800039b6:	84aa                	mv	s1,a0
  iunlock(ip);
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	e54080e7          	jalr	-428(ra) # 8000380c <iunlock>
  iput(ip);
    800039c0:	8526                	mv	a0,s1
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	f42080e7          	jalr	-190(ra) # 80003904 <iput>
}
    800039ca:	60e2                	ld	ra,24(sp)
    800039cc:	6442                	ld	s0,16(sp)
    800039ce:	64a2                	ld	s1,8(sp)
    800039d0:	6105                	addi	sp,sp,32
    800039d2:	8082                	ret

00000000800039d4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039d4:	1141                	addi	sp,sp,-16
    800039d6:	e422                	sd	s0,8(sp)
    800039d8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039da:	411c                	lw	a5,0(a0)
    800039dc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039de:	415c                	lw	a5,4(a0)
    800039e0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039e2:	04451783          	lh	a5,68(a0)
    800039e6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039ea:	04a51783          	lh	a5,74(a0)
    800039ee:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039f2:	04c56783          	lwu	a5,76(a0)
    800039f6:	e99c                	sd	a5,16(a1)
}
    800039f8:	6422                	ld	s0,8(sp)
    800039fa:	0141                	addi	sp,sp,16
    800039fc:	8082                	ret

00000000800039fe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039fe:	457c                	lw	a5,76(a0)
    80003a00:	0ed7e963          	bltu	a5,a3,80003af2 <readi+0xf4>
{
    80003a04:	7159                	addi	sp,sp,-112
    80003a06:	f486                	sd	ra,104(sp)
    80003a08:	f0a2                	sd	s0,96(sp)
    80003a0a:	eca6                	sd	s1,88(sp)
    80003a0c:	e8ca                	sd	s2,80(sp)
    80003a0e:	e4ce                	sd	s3,72(sp)
    80003a10:	e0d2                	sd	s4,64(sp)
    80003a12:	fc56                	sd	s5,56(sp)
    80003a14:	f85a                	sd	s6,48(sp)
    80003a16:	f45e                	sd	s7,40(sp)
    80003a18:	f062                	sd	s8,32(sp)
    80003a1a:	ec66                	sd	s9,24(sp)
    80003a1c:	e86a                	sd	s10,16(sp)
    80003a1e:	e46e                	sd	s11,8(sp)
    80003a20:	1880                	addi	s0,sp,112
    80003a22:	8b2a                	mv	s6,a0
    80003a24:	8bae                	mv	s7,a1
    80003a26:	8a32                	mv	s4,a2
    80003a28:	84b6                	mv	s1,a3
    80003a2a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a2c:	9f35                	addw	a4,a4,a3
    return 0;
    80003a2e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a30:	0ad76063          	bltu	a4,a3,80003ad0 <readi+0xd2>
  if(off + n > ip->size)
    80003a34:	00e7f463          	bgeu	a5,a4,80003a3c <readi+0x3e>
    n = ip->size - off;
    80003a38:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3c:	0a0a8963          	beqz	s5,80003aee <readi+0xf0>
    80003a40:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a42:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a46:	5c7d                	li	s8,-1
    80003a48:	a82d                	j	80003a82 <readi+0x84>
    80003a4a:	020d1d93          	slli	s11,s10,0x20
    80003a4e:	020ddd93          	srli	s11,s11,0x20
    80003a52:	05890613          	addi	a2,s2,88
    80003a56:	86ee                	mv	a3,s11
    80003a58:	963a                	add	a2,a2,a4
    80003a5a:	85d2                	mv	a1,s4
    80003a5c:	855e                	mv	a0,s7
    80003a5e:	fffff097          	auipc	ra,0xfffff
    80003a62:	b00080e7          	jalr	-1280(ra) # 8000255e <either_copyout>
    80003a66:	05850d63          	beq	a0,s8,80003ac0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a6a:	854a                	mv	a0,s2
    80003a6c:	fffff097          	auipc	ra,0xfffff
    80003a70:	5f4080e7          	jalr	1524(ra) # 80003060 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a74:	013d09bb          	addw	s3,s10,s3
    80003a78:	009d04bb          	addw	s1,s10,s1
    80003a7c:	9a6e                	add	s4,s4,s11
    80003a7e:	0559f763          	bgeu	s3,s5,80003acc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a82:	00a4d59b          	srliw	a1,s1,0xa
    80003a86:	855a                	mv	a0,s6
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	8a2080e7          	jalr	-1886(ra) # 8000332a <bmap>
    80003a90:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a94:	cd85                	beqz	a1,80003acc <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a96:	000b2503          	lw	a0,0(s6)
    80003a9a:	fffff097          	auipc	ra,0xfffff
    80003a9e:	496080e7          	jalr	1174(ra) # 80002f30 <bread>
    80003aa2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa4:	3ff4f713          	andi	a4,s1,1023
    80003aa8:	40ec87bb          	subw	a5,s9,a4
    80003aac:	413a86bb          	subw	a3,s5,s3
    80003ab0:	8d3e                	mv	s10,a5
    80003ab2:	2781                	sext.w	a5,a5
    80003ab4:	0006861b          	sext.w	a2,a3
    80003ab8:	f8f679e3          	bgeu	a2,a5,80003a4a <readi+0x4c>
    80003abc:	8d36                	mv	s10,a3
    80003abe:	b771                	j	80003a4a <readi+0x4c>
      brelse(bp);
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	59e080e7          	jalr	1438(ra) # 80003060 <brelse>
      tot = -1;
    80003aca:	59fd                	li	s3,-1
  }
  return tot;
    80003acc:	0009851b          	sext.w	a0,s3
}
    80003ad0:	70a6                	ld	ra,104(sp)
    80003ad2:	7406                	ld	s0,96(sp)
    80003ad4:	64e6                	ld	s1,88(sp)
    80003ad6:	6946                	ld	s2,80(sp)
    80003ad8:	69a6                	ld	s3,72(sp)
    80003ada:	6a06                	ld	s4,64(sp)
    80003adc:	7ae2                	ld	s5,56(sp)
    80003ade:	7b42                	ld	s6,48(sp)
    80003ae0:	7ba2                	ld	s7,40(sp)
    80003ae2:	7c02                	ld	s8,32(sp)
    80003ae4:	6ce2                	ld	s9,24(sp)
    80003ae6:	6d42                	ld	s10,16(sp)
    80003ae8:	6da2                	ld	s11,8(sp)
    80003aea:	6165                	addi	sp,sp,112
    80003aec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aee:	89d6                	mv	s3,s5
    80003af0:	bff1                	j	80003acc <readi+0xce>
    return 0;
    80003af2:	4501                	li	a0,0
}
    80003af4:	8082                	ret

0000000080003af6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003af6:	457c                	lw	a5,76(a0)
    80003af8:	10d7e863          	bltu	a5,a3,80003c08 <writei+0x112>
{
    80003afc:	7159                	addi	sp,sp,-112
    80003afe:	f486                	sd	ra,104(sp)
    80003b00:	f0a2                	sd	s0,96(sp)
    80003b02:	eca6                	sd	s1,88(sp)
    80003b04:	e8ca                	sd	s2,80(sp)
    80003b06:	e4ce                	sd	s3,72(sp)
    80003b08:	e0d2                	sd	s4,64(sp)
    80003b0a:	fc56                	sd	s5,56(sp)
    80003b0c:	f85a                	sd	s6,48(sp)
    80003b0e:	f45e                	sd	s7,40(sp)
    80003b10:	f062                	sd	s8,32(sp)
    80003b12:	ec66                	sd	s9,24(sp)
    80003b14:	e86a                	sd	s10,16(sp)
    80003b16:	e46e                	sd	s11,8(sp)
    80003b18:	1880                	addi	s0,sp,112
    80003b1a:	8aaa                	mv	s5,a0
    80003b1c:	8bae                	mv	s7,a1
    80003b1e:	8a32                	mv	s4,a2
    80003b20:	8936                	mv	s2,a3
    80003b22:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b24:	00e687bb          	addw	a5,a3,a4
    80003b28:	0ed7e263          	bltu	a5,a3,80003c0c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b2c:	00043737          	lui	a4,0x43
    80003b30:	0ef76063          	bltu	a4,a5,80003c10 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b34:	0c0b0863          	beqz	s6,80003c04 <writei+0x10e>
    80003b38:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b3a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b3e:	5c7d                	li	s8,-1
    80003b40:	a091                	j	80003b84 <writei+0x8e>
    80003b42:	020d1d93          	slli	s11,s10,0x20
    80003b46:	020ddd93          	srli	s11,s11,0x20
    80003b4a:	05848513          	addi	a0,s1,88
    80003b4e:	86ee                	mv	a3,s11
    80003b50:	8652                	mv	a2,s4
    80003b52:	85de                	mv	a1,s7
    80003b54:	953a                	add	a0,a0,a4
    80003b56:	fffff097          	auipc	ra,0xfffff
    80003b5a:	a5e080e7          	jalr	-1442(ra) # 800025b4 <either_copyin>
    80003b5e:	07850263          	beq	a0,s8,80003bc2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b62:	8526                	mv	a0,s1
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	780080e7          	jalr	1920(ra) # 800042e4 <log_write>
    brelse(bp);
    80003b6c:	8526                	mv	a0,s1
    80003b6e:	fffff097          	auipc	ra,0xfffff
    80003b72:	4f2080e7          	jalr	1266(ra) # 80003060 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b76:	013d09bb          	addw	s3,s10,s3
    80003b7a:	012d093b          	addw	s2,s10,s2
    80003b7e:	9a6e                	add	s4,s4,s11
    80003b80:	0569f663          	bgeu	s3,s6,80003bcc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b84:	00a9559b          	srliw	a1,s2,0xa
    80003b88:	8556                	mv	a0,s5
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	7a0080e7          	jalr	1952(ra) # 8000332a <bmap>
    80003b92:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b96:	c99d                	beqz	a1,80003bcc <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b98:	000aa503          	lw	a0,0(s5)
    80003b9c:	fffff097          	auipc	ra,0xfffff
    80003ba0:	394080e7          	jalr	916(ra) # 80002f30 <bread>
    80003ba4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba6:	3ff97713          	andi	a4,s2,1023
    80003baa:	40ec87bb          	subw	a5,s9,a4
    80003bae:	413b06bb          	subw	a3,s6,s3
    80003bb2:	8d3e                	mv	s10,a5
    80003bb4:	2781                	sext.w	a5,a5
    80003bb6:	0006861b          	sext.w	a2,a3
    80003bba:	f8f674e3          	bgeu	a2,a5,80003b42 <writei+0x4c>
    80003bbe:	8d36                	mv	s10,a3
    80003bc0:	b749                	j	80003b42 <writei+0x4c>
      brelse(bp);
    80003bc2:	8526                	mv	a0,s1
    80003bc4:	fffff097          	auipc	ra,0xfffff
    80003bc8:	49c080e7          	jalr	1180(ra) # 80003060 <brelse>
  }

  if(off > ip->size)
    80003bcc:	04caa783          	lw	a5,76(s5)
    80003bd0:	0127f463          	bgeu	a5,s2,80003bd8 <writei+0xe2>
    ip->size = off;
    80003bd4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bd8:	8556                	mv	a0,s5
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	aa6080e7          	jalr	-1370(ra) # 80003680 <iupdate>

  return tot;
    80003be2:	0009851b          	sext.w	a0,s3
}
    80003be6:	70a6                	ld	ra,104(sp)
    80003be8:	7406                	ld	s0,96(sp)
    80003bea:	64e6                	ld	s1,88(sp)
    80003bec:	6946                	ld	s2,80(sp)
    80003bee:	69a6                	ld	s3,72(sp)
    80003bf0:	6a06                	ld	s4,64(sp)
    80003bf2:	7ae2                	ld	s5,56(sp)
    80003bf4:	7b42                	ld	s6,48(sp)
    80003bf6:	7ba2                	ld	s7,40(sp)
    80003bf8:	7c02                	ld	s8,32(sp)
    80003bfa:	6ce2                	ld	s9,24(sp)
    80003bfc:	6d42                	ld	s10,16(sp)
    80003bfe:	6da2                	ld	s11,8(sp)
    80003c00:	6165                	addi	sp,sp,112
    80003c02:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c04:	89da                	mv	s3,s6
    80003c06:	bfc9                	j	80003bd8 <writei+0xe2>
    return -1;
    80003c08:	557d                	li	a0,-1
}
    80003c0a:	8082                	ret
    return -1;
    80003c0c:	557d                	li	a0,-1
    80003c0e:	bfe1                	j	80003be6 <writei+0xf0>
    return -1;
    80003c10:	557d                	li	a0,-1
    80003c12:	bfd1                	j	80003be6 <writei+0xf0>

0000000080003c14 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c14:	1141                	addi	sp,sp,-16
    80003c16:	e406                	sd	ra,8(sp)
    80003c18:	e022                	sd	s0,0(sp)
    80003c1a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c1c:	4639                	li	a2,14
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	1a0080e7          	jalr	416(ra) # 80000dbe <strncmp>
}
    80003c26:	60a2                	ld	ra,8(sp)
    80003c28:	6402                	ld	s0,0(sp)
    80003c2a:	0141                	addi	sp,sp,16
    80003c2c:	8082                	ret

0000000080003c2e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c2e:	7139                	addi	sp,sp,-64
    80003c30:	fc06                	sd	ra,56(sp)
    80003c32:	f822                	sd	s0,48(sp)
    80003c34:	f426                	sd	s1,40(sp)
    80003c36:	f04a                	sd	s2,32(sp)
    80003c38:	ec4e                	sd	s3,24(sp)
    80003c3a:	e852                	sd	s4,16(sp)
    80003c3c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c3e:	04451703          	lh	a4,68(a0)
    80003c42:	4785                	li	a5,1
    80003c44:	00f71a63          	bne	a4,a5,80003c58 <dirlookup+0x2a>
    80003c48:	892a                	mv	s2,a0
    80003c4a:	89ae                	mv	s3,a1
    80003c4c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c4e:	457c                	lw	a5,76(a0)
    80003c50:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c52:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c54:	e79d                	bnez	a5,80003c82 <dirlookup+0x54>
    80003c56:	a8a5                	j	80003cce <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c58:	00005517          	auipc	a0,0x5
    80003c5c:	9c850513          	addi	a0,a0,-1592 # 80008620 <syscalls+0x1a0>
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	8e4080e7          	jalr	-1820(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003c68:	00005517          	auipc	a0,0x5
    80003c6c:	9d050513          	addi	a0,a0,-1584 # 80008638 <syscalls+0x1b8>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	8d4080e7          	jalr	-1836(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c78:	24c1                	addiw	s1,s1,16
    80003c7a:	04c92783          	lw	a5,76(s2)
    80003c7e:	04f4f763          	bgeu	s1,a5,80003ccc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c82:	4741                	li	a4,16
    80003c84:	86a6                	mv	a3,s1
    80003c86:	fc040613          	addi	a2,s0,-64
    80003c8a:	4581                	li	a1,0
    80003c8c:	854a                	mv	a0,s2
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	d70080e7          	jalr	-656(ra) # 800039fe <readi>
    80003c96:	47c1                	li	a5,16
    80003c98:	fcf518e3          	bne	a0,a5,80003c68 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c9c:	fc045783          	lhu	a5,-64(s0)
    80003ca0:	dfe1                	beqz	a5,80003c78 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ca2:	fc240593          	addi	a1,s0,-62
    80003ca6:	854e                	mv	a0,s3
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	f6c080e7          	jalr	-148(ra) # 80003c14 <namecmp>
    80003cb0:	f561                	bnez	a0,80003c78 <dirlookup+0x4a>
      if(poff)
    80003cb2:	000a0463          	beqz	s4,80003cba <dirlookup+0x8c>
        *poff = off;
    80003cb6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cba:	fc045583          	lhu	a1,-64(s0)
    80003cbe:	00092503          	lw	a0,0(s2)
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	750080e7          	jalr	1872(ra) # 80003412 <iget>
    80003cca:	a011                	j	80003cce <dirlookup+0xa0>
  return 0;
    80003ccc:	4501                	li	a0,0
}
    80003cce:	70e2                	ld	ra,56(sp)
    80003cd0:	7442                	ld	s0,48(sp)
    80003cd2:	74a2                	ld	s1,40(sp)
    80003cd4:	7902                	ld	s2,32(sp)
    80003cd6:	69e2                	ld	s3,24(sp)
    80003cd8:	6a42                	ld	s4,16(sp)
    80003cda:	6121                	addi	sp,sp,64
    80003cdc:	8082                	ret

0000000080003cde <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cde:	711d                	addi	sp,sp,-96
    80003ce0:	ec86                	sd	ra,88(sp)
    80003ce2:	e8a2                	sd	s0,80(sp)
    80003ce4:	e4a6                	sd	s1,72(sp)
    80003ce6:	e0ca                	sd	s2,64(sp)
    80003ce8:	fc4e                	sd	s3,56(sp)
    80003cea:	f852                	sd	s4,48(sp)
    80003cec:	f456                	sd	s5,40(sp)
    80003cee:	f05a                	sd	s6,32(sp)
    80003cf0:	ec5e                	sd	s7,24(sp)
    80003cf2:	e862                	sd	s8,16(sp)
    80003cf4:	e466                	sd	s9,8(sp)
    80003cf6:	1080                	addi	s0,sp,96
    80003cf8:	84aa                	mv	s1,a0
    80003cfa:	8b2e                	mv	s6,a1
    80003cfc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cfe:	00054703          	lbu	a4,0(a0)
    80003d02:	02f00793          	li	a5,47
    80003d06:	02f70363          	beq	a4,a5,80003d2c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d0a:	ffffe097          	auipc	ra,0xffffe
    80003d0e:	da8080e7          	jalr	-600(ra) # 80001ab2 <myproc>
    80003d12:	15053503          	ld	a0,336(a0)
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	9f6080e7          	jalr	-1546(ra) # 8000370c <idup>
    80003d1e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d20:	02f00913          	li	s2,47
  len = path - s;
    80003d24:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d26:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d28:	4c05                	li	s8,1
    80003d2a:	a865                	j	80003de2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d2c:	4585                	li	a1,1
    80003d2e:	4505                	li	a0,1
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	6e2080e7          	jalr	1762(ra) # 80003412 <iget>
    80003d38:	89aa                	mv	s3,a0
    80003d3a:	b7dd                	j	80003d20 <namex+0x42>
      iunlockput(ip);
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	c6e080e7          	jalr	-914(ra) # 800039ac <iunlockput>
      return 0;
    80003d46:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d48:	854e                	mv	a0,s3
    80003d4a:	60e6                	ld	ra,88(sp)
    80003d4c:	6446                	ld	s0,80(sp)
    80003d4e:	64a6                	ld	s1,72(sp)
    80003d50:	6906                	ld	s2,64(sp)
    80003d52:	79e2                	ld	s3,56(sp)
    80003d54:	7a42                	ld	s4,48(sp)
    80003d56:	7aa2                	ld	s5,40(sp)
    80003d58:	7b02                	ld	s6,32(sp)
    80003d5a:	6be2                	ld	s7,24(sp)
    80003d5c:	6c42                	ld	s8,16(sp)
    80003d5e:	6ca2                	ld	s9,8(sp)
    80003d60:	6125                	addi	sp,sp,96
    80003d62:	8082                	ret
      iunlock(ip);
    80003d64:	854e                	mv	a0,s3
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	aa6080e7          	jalr	-1370(ra) # 8000380c <iunlock>
      return ip;
    80003d6e:	bfe9                	j	80003d48 <namex+0x6a>
      iunlockput(ip);
    80003d70:	854e                	mv	a0,s3
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	c3a080e7          	jalr	-966(ra) # 800039ac <iunlockput>
      return 0;
    80003d7a:	89d2                	mv	s3,s4
    80003d7c:	b7f1                	j	80003d48 <namex+0x6a>
  len = path - s;
    80003d7e:	40b48633          	sub	a2,s1,a1
    80003d82:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d86:	094cd463          	bge	s9,s4,80003e0e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d8a:	4639                	li	a2,14
    80003d8c:	8556                	mv	a0,s5
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	fb8080e7          	jalr	-72(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003d96:	0004c783          	lbu	a5,0(s1)
    80003d9a:	01279763          	bne	a5,s2,80003da8 <namex+0xca>
    path++;
    80003d9e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003da0:	0004c783          	lbu	a5,0(s1)
    80003da4:	ff278de3          	beq	a5,s2,80003d9e <namex+0xc0>
    ilock(ip);
    80003da8:	854e                	mv	a0,s3
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	9a0080e7          	jalr	-1632(ra) # 8000374a <ilock>
    if(ip->type != T_DIR){
    80003db2:	04499783          	lh	a5,68(s3)
    80003db6:	f98793e3          	bne	a5,s8,80003d3c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dba:	000b0563          	beqz	s6,80003dc4 <namex+0xe6>
    80003dbe:	0004c783          	lbu	a5,0(s1)
    80003dc2:	d3cd                	beqz	a5,80003d64 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dc4:	865e                	mv	a2,s7
    80003dc6:	85d6                	mv	a1,s5
    80003dc8:	854e                	mv	a0,s3
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	e64080e7          	jalr	-412(ra) # 80003c2e <dirlookup>
    80003dd2:	8a2a                	mv	s4,a0
    80003dd4:	dd51                	beqz	a0,80003d70 <namex+0x92>
    iunlockput(ip);
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	bd4080e7          	jalr	-1068(ra) # 800039ac <iunlockput>
    ip = next;
    80003de0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003de2:	0004c783          	lbu	a5,0(s1)
    80003de6:	05279763          	bne	a5,s2,80003e34 <namex+0x156>
    path++;
    80003dea:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dec:	0004c783          	lbu	a5,0(s1)
    80003df0:	ff278de3          	beq	a5,s2,80003dea <namex+0x10c>
  if(*path == 0)
    80003df4:	c79d                	beqz	a5,80003e22 <namex+0x144>
    path++;
    80003df6:	85a6                	mv	a1,s1
  len = path - s;
    80003df8:	8a5e                	mv	s4,s7
    80003dfa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dfc:	01278963          	beq	a5,s2,80003e0e <namex+0x130>
    80003e00:	dfbd                	beqz	a5,80003d7e <namex+0xa0>
    path++;
    80003e02:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e04:	0004c783          	lbu	a5,0(s1)
    80003e08:	ff279ce3          	bne	a5,s2,80003e00 <namex+0x122>
    80003e0c:	bf8d                	j	80003d7e <namex+0xa0>
    memmove(name, s, len);
    80003e0e:	2601                	sext.w	a2,a2
    80003e10:	8556                	mv	a0,s5
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	f34080e7          	jalr	-204(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003e1a:	9a56                	add	s4,s4,s5
    80003e1c:	000a0023          	sb	zero,0(s4)
    80003e20:	bf9d                	j	80003d96 <namex+0xb8>
  if(nameiparent){
    80003e22:	f20b03e3          	beqz	s6,80003d48 <namex+0x6a>
    iput(ip);
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	adc080e7          	jalr	-1316(ra) # 80003904 <iput>
    return 0;
    80003e30:	4981                	li	s3,0
    80003e32:	bf19                	j	80003d48 <namex+0x6a>
  if(*path == 0)
    80003e34:	d7fd                	beqz	a5,80003e22 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e36:	0004c783          	lbu	a5,0(s1)
    80003e3a:	85a6                	mv	a1,s1
    80003e3c:	b7d1                	j	80003e00 <namex+0x122>

0000000080003e3e <dirlink>:
{
    80003e3e:	7139                	addi	sp,sp,-64
    80003e40:	fc06                	sd	ra,56(sp)
    80003e42:	f822                	sd	s0,48(sp)
    80003e44:	f426                	sd	s1,40(sp)
    80003e46:	f04a                	sd	s2,32(sp)
    80003e48:	ec4e                	sd	s3,24(sp)
    80003e4a:	e852                	sd	s4,16(sp)
    80003e4c:	0080                	addi	s0,sp,64
    80003e4e:	892a                	mv	s2,a0
    80003e50:	8a2e                	mv	s4,a1
    80003e52:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e54:	4601                	li	a2,0
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	dd8080e7          	jalr	-552(ra) # 80003c2e <dirlookup>
    80003e5e:	e93d                	bnez	a0,80003ed4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e60:	04c92483          	lw	s1,76(s2)
    80003e64:	c49d                	beqz	s1,80003e92 <dirlink+0x54>
    80003e66:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e68:	4741                	li	a4,16
    80003e6a:	86a6                	mv	a3,s1
    80003e6c:	fc040613          	addi	a2,s0,-64
    80003e70:	4581                	li	a1,0
    80003e72:	854a                	mv	a0,s2
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	b8a080e7          	jalr	-1142(ra) # 800039fe <readi>
    80003e7c:	47c1                	li	a5,16
    80003e7e:	06f51163          	bne	a0,a5,80003ee0 <dirlink+0xa2>
    if(de.inum == 0)
    80003e82:	fc045783          	lhu	a5,-64(s0)
    80003e86:	c791                	beqz	a5,80003e92 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e88:	24c1                	addiw	s1,s1,16
    80003e8a:	04c92783          	lw	a5,76(s2)
    80003e8e:	fcf4ede3          	bltu	s1,a5,80003e68 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e92:	4639                	li	a2,14
    80003e94:	85d2                	mv	a1,s4
    80003e96:	fc240513          	addi	a0,s0,-62
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	f60080e7          	jalr	-160(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003ea2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea6:	4741                	li	a4,16
    80003ea8:	86a6                	mv	a3,s1
    80003eaa:	fc040613          	addi	a2,s0,-64
    80003eae:	4581                	li	a1,0
    80003eb0:	854a                	mv	a0,s2
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	c44080e7          	jalr	-956(ra) # 80003af6 <writei>
    80003eba:	1541                	addi	a0,a0,-16
    80003ebc:	00a03533          	snez	a0,a0
    80003ec0:	40a00533          	neg	a0,a0
}
    80003ec4:	70e2                	ld	ra,56(sp)
    80003ec6:	7442                	ld	s0,48(sp)
    80003ec8:	74a2                	ld	s1,40(sp)
    80003eca:	7902                	ld	s2,32(sp)
    80003ecc:	69e2                	ld	s3,24(sp)
    80003ece:	6a42                	ld	s4,16(sp)
    80003ed0:	6121                	addi	sp,sp,64
    80003ed2:	8082                	ret
    iput(ip);
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	a30080e7          	jalr	-1488(ra) # 80003904 <iput>
    return -1;
    80003edc:	557d                	li	a0,-1
    80003ede:	b7dd                	j	80003ec4 <dirlink+0x86>
      panic("dirlink read");
    80003ee0:	00004517          	auipc	a0,0x4
    80003ee4:	76850513          	addi	a0,a0,1896 # 80008648 <syscalls+0x1c8>
    80003ee8:	ffffc097          	auipc	ra,0xffffc
    80003eec:	65c080e7          	jalr	1628(ra) # 80000544 <panic>

0000000080003ef0 <namei>:

struct inode*
namei(char *path)
{
    80003ef0:	1101                	addi	sp,sp,-32
    80003ef2:	ec06                	sd	ra,24(sp)
    80003ef4:	e822                	sd	s0,16(sp)
    80003ef6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ef8:	fe040613          	addi	a2,s0,-32
    80003efc:	4581                	li	a1,0
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	de0080e7          	jalr	-544(ra) # 80003cde <namex>
}
    80003f06:	60e2                	ld	ra,24(sp)
    80003f08:	6442                	ld	s0,16(sp)
    80003f0a:	6105                	addi	sp,sp,32
    80003f0c:	8082                	ret

0000000080003f0e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f0e:	1141                	addi	sp,sp,-16
    80003f10:	e406                	sd	ra,8(sp)
    80003f12:	e022                	sd	s0,0(sp)
    80003f14:	0800                	addi	s0,sp,16
    80003f16:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f18:	4585                	li	a1,1
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	dc4080e7          	jalr	-572(ra) # 80003cde <namex>
}
    80003f22:	60a2                	ld	ra,8(sp)
    80003f24:	6402                	ld	s0,0(sp)
    80003f26:	0141                	addi	sp,sp,16
    80003f28:	8082                	ret

0000000080003f2a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f2a:	1101                	addi	sp,sp,-32
    80003f2c:	ec06                	sd	ra,24(sp)
    80003f2e:	e822                	sd	s0,16(sp)
    80003f30:	e426                	sd	s1,8(sp)
    80003f32:	e04a                	sd	s2,0(sp)
    80003f34:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f36:	0001d917          	auipc	s2,0x1d
    80003f3a:	c1a90913          	addi	s2,s2,-998 # 80020b50 <log>
    80003f3e:	01892583          	lw	a1,24(s2)
    80003f42:	02892503          	lw	a0,40(s2)
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	fea080e7          	jalr	-22(ra) # 80002f30 <bread>
    80003f4e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f50:	02c92683          	lw	a3,44(s2)
    80003f54:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f56:	02d05763          	blez	a3,80003f84 <write_head+0x5a>
    80003f5a:	0001d797          	auipc	a5,0x1d
    80003f5e:	c2678793          	addi	a5,a5,-986 # 80020b80 <log+0x30>
    80003f62:	05c50713          	addi	a4,a0,92
    80003f66:	36fd                	addiw	a3,a3,-1
    80003f68:	1682                	slli	a3,a3,0x20
    80003f6a:	9281                	srli	a3,a3,0x20
    80003f6c:	068a                	slli	a3,a3,0x2
    80003f6e:	0001d617          	auipc	a2,0x1d
    80003f72:	c1660613          	addi	a2,a2,-1002 # 80020b84 <log+0x34>
    80003f76:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f78:	4390                	lw	a2,0(a5)
    80003f7a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f7c:	0791                	addi	a5,a5,4
    80003f7e:	0711                	addi	a4,a4,4
    80003f80:	fed79ce3          	bne	a5,a3,80003f78 <write_head+0x4e>
  }
  bwrite(buf);
    80003f84:	8526                	mv	a0,s1
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	09c080e7          	jalr	156(ra) # 80003022 <bwrite>
  brelse(buf);
    80003f8e:	8526                	mv	a0,s1
    80003f90:	fffff097          	auipc	ra,0xfffff
    80003f94:	0d0080e7          	jalr	208(ra) # 80003060 <brelse>
}
    80003f98:	60e2                	ld	ra,24(sp)
    80003f9a:	6442                	ld	s0,16(sp)
    80003f9c:	64a2                	ld	s1,8(sp)
    80003f9e:	6902                	ld	s2,0(sp)
    80003fa0:	6105                	addi	sp,sp,32
    80003fa2:	8082                	ret

0000000080003fa4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa4:	0001d797          	auipc	a5,0x1d
    80003fa8:	bd87a783          	lw	a5,-1064(a5) # 80020b7c <log+0x2c>
    80003fac:	0af05d63          	blez	a5,80004066 <install_trans+0xc2>
{
    80003fb0:	7139                	addi	sp,sp,-64
    80003fb2:	fc06                	sd	ra,56(sp)
    80003fb4:	f822                	sd	s0,48(sp)
    80003fb6:	f426                	sd	s1,40(sp)
    80003fb8:	f04a                	sd	s2,32(sp)
    80003fba:	ec4e                	sd	s3,24(sp)
    80003fbc:	e852                	sd	s4,16(sp)
    80003fbe:	e456                	sd	s5,8(sp)
    80003fc0:	e05a                	sd	s6,0(sp)
    80003fc2:	0080                	addi	s0,sp,64
    80003fc4:	8b2a                	mv	s6,a0
    80003fc6:	0001da97          	auipc	s5,0x1d
    80003fca:	bbaa8a93          	addi	s5,s5,-1094 # 80020b80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fce:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd0:	0001d997          	auipc	s3,0x1d
    80003fd4:	b8098993          	addi	s3,s3,-1152 # 80020b50 <log>
    80003fd8:	a035                	j	80004004 <install_trans+0x60>
      bunpin(dbuf);
    80003fda:	8526                	mv	a0,s1
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	15e080e7          	jalr	350(ra) # 8000313a <bunpin>
    brelse(lbuf);
    80003fe4:	854a                	mv	a0,s2
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	07a080e7          	jalr	122(ra) # 80003060 <brelse>
    brelse(dbuf);
    80003fee:	8526                	mv	a0,s1
    80003ff0:	fffff097          	auipc	ra,0xfffff
    80003ff4:	070080e7          	jalr	112(ra) # 80003060 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff8:	2a05                	addiw	s4,s4,1
    80003ffa:	0a91                	addi	s5,s5,4
    80003ffc:	02c9a783          	lw	a5,44(s3)
    80004000:	04fa5963          	bge	s4,a5,80004052 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004004:	0189a583          	lw	a1,24(s3)
    80004008:	014585bb          	addw	a1,a1,s4
    8000400c:	2585                	addiw	a1,a1,1
    8000400e:	0289a503          	lw	a0,40(s3)
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	f1e080e7          	jalr	-226(ra) # 80002f30 <bread>
    8000401a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000401c:	000aa583          	lw	a1,0(s5)
    80004020:	0289a503          	lw	a0,40(s3)
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	f0c080e7          	jalr	-244(ra) # 80002f30 <bread>
    8000402c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000402e:	40000613          	li	a2,1024
    80004032:	05890593          	addi	a1,s2,88
    80004036:	05850513          	addi	a0,a0,88
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	d0c080e7          	jalr	-756(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004042:	8526                	mv	a0,s1
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	fde080e7          	jalr	-34(ra) # 80003022 <bwrite>
    if(recovering == 0)
    8000404c:	f80b1ce3          	bnez	s6,80003fe4 <install_trans+0x40>
    80004050:	b769                	j	80003fda <install_trans+0x36>
}
    80004052:	70e2                	ld	ra,56(sp)
    80004054:	7442                	ld	s0,48(sp)
    80004056:	74a2                	ld	s1,40(sp)
    80004058:	7902                	ld	s2,32(sp)
    8000405a:	69e2                	ld	s3,24(sp)
    8000405c:	6a42                	ld	s4,16(sp)
    8000405e:	6aa2                	ld	s5,8(sp)
    80004060:	6b02                	ld	s6,0(sp)
    80004062:	6121                	addi	sp,sp,64
    80004064:	8082                	ret
    80004066:	8082                	ret

0000000080004068 <initlog>:
{
    80004068:	7179                	addi	sp,sp,-48
    8000406a:	f406                	sd	ra,40(sp)
    8000406c:	f022                	sd	s0,32(sp)
    8000406e:	ec26                	sd	s1,24(sp)
    80004070:	e84a                	sd	s2,16(sp)
    80004072:	e44e                	sd	s3,8(sp)
    80004074:	1800                	addi	s0,sp,48
    80004076:	892a                	mv	s2,a0
    80004078:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000407a:	0001d497          	auipc	s1,0x1d
    8000407e:	ad648493          	addi	s1,s1,-1322 # 80020b50 <log>
    80004082:	00004597          	auipc	a1,0x4
    80004086:	5d658593          	addi	a1,a1,1494 # 80008658 <syscalls+0x1d8>
    8000408a:	8526                	mv	a0,s1
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	ace080e7          	jalr	-1330(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004094:	0149a583          	lw	a1,20(s3)
    80004098:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000409a:	0109a783          	lw	a5,16(s3)
    8000409e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040a0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040a4:	854a                	mv	a0,s2
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	e8a080e7          	jalr	-374(ra) # 80002f30 <bread>
  log.lh.n = lh->n;
    800040ae:	4d3c                	lw	a5,88(a0)
    800040b0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040b2:	02f05563          	blez	a5,800040dc <initlog+0x74>
    800040b6:	05c50713          	addi	a4,a0,92
    800040ba:	0001d697          	auipc	a3,0x1d
    800040be:	ac668693          	addi	a3,a3,-1338 # 80020b80 <log+0x30>
    800040c2:	37fd                	addiw	a5,a5,-1
    800040c4:	1782                	slli	a5,a5,0x20
    800040c6:	9381                	srli	a5,a5,0x20
    800040c8:	078a                	slli	a5,a5,0x2
    800040ca:	06050613          	addi	a2,a0,96
    800040ce:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040d0:	4310                	lw	a2,0(a4)
    800040d2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040d4:	0711                	addi	a4,a4,4
    800040d6:	0691                	addi	a3,a3,4
    800040d8:	fef71ce3          	bne	a4,a5,800040d0 <initlog+0x68>
  brelse(buf);
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	f84080e7          	jalr	-124(ra) # 80003060 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040e4:	4505                	li	a0,1
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	ebe080e7          	jalr	-322(ra) # 80003fa4 <install_trans>
  log.lh.n = 0;
    800040ee:	0001d797          	auipc	a5,0x1d
    800040f2:	a807a723          	sw	zero,-1394(a5) # 80020b7c <log+0x2c>
  write_head(); // clear the log
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	e34080e7          	jalr	-460(ra) # 80003f2a <write_head>
}
    800040fe:	70a2                	ld	ra,40(sp)
    80004100:	7402                	ld	s0,32(sp)
    80004102:	64e2                	ld	s1,24(sp)
    80004104:	6942                	ld	s2,16(sp)
    80004106:	69a2                	ld	s3,8(sp)
    80004108:	6145                	addi	sp,sp,48
    8000410a:	8082                	ret

000000008000410c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000410c:	1101                	addi	sp,sp,-32
    8000410e:	ec06                	sd	ra,24(sp)
    80004110:	e822                	sd	s0,16(sp)
    80004112:	e426                	sd	s1,8(sp)
    80004114:	e04a                	sd	s2,0(sp)
    80004116:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004118:	0001d517          	auipc	a0,0x1d
    8000411c:	a3850513          	addi	a0,a0,-1480 # 80020b50 <log>
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	aca080e7          	jalr	-1334(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004128:	0001d497          	auipc	s1,0x1d
    8000412c:	a2848493          	addi	s1,s1,-1496 # 80020b50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004130:	4979                	li	s2,30
    80004132:	a039                	j	80004140 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004134:	85a6                	mv	a1,s1
    80004136:	8526                	mv	a0,s1
    80004138:	ffffe097          	auipc	ra,0xffffe
    8000413c:	01e080e7          	jalr	30(ra) # 80002156 <sleep>
    if(log.committing){
    80004140:	50dc                	lw	a5,36(s1)
    80004142:	fbed                	bnez	a5,80004134 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004144:	509c                	lw	a5,32(s1)
    80004146:	0017871b          	addiw	a4,a5,1
    8000414a:	0007069b          	sext.w	a3,a4
    8000414e:	0027179b          	slliw	a5,a4,0x2
    80004152:	9fb9                	addw	a5,a5,a4
    80004154:	0017979b          	slliw	a5,a5,0x1
    80004158:	54d8                	lw	a4,44(s1)
    8000415a:	9fb9                	addw	a5,a5,a4
    8000415c:	00f95963          	bge	s2,a5,8000416e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004160:	85a6                	mv	a1,s1
    80004162:	8526                	mv	a0,s1
    80004164:	ffffe097          	auipc	ra,0xffffe
    80004168:	ff2080e7          	jalr	-14(ra) # 80002156 <sleep>
    8000416c:	bfd1                	j	80004140 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000416e:	0001d517          	auipc	a0,0x1d
    80004172:	9e250513          	addi	a0,a0,-1566 # 80020b50 <log>
    80004176:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	b26080e7          	jalr	-1242(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004180:	60e2                	ld	ra,24(sp)
    80004182:	6442                	ld	s0,16(sp)
    80004184:	64a2                	ld	s1,8(sp)
    80004186:	6902                	ld	s2,0(sp)
    80004188:	6105                	addi	sp,sp,32
    8000418a:	8082                	ret

000000008000418c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000418c:	7139                	addi	sp,sp,-64
    8000418e:	fc06                	sd	ra,56(sp)
    80004190:	f822                	sd	s0,48(sp)
    80004192:	f426                	sd	s1,40(sp)
    80004194:	f04a                	sd	s2,32(sp)
    80004196:	ec4e                	sd	s3,24(sp)
    80004198:	e852                	sd	s4,16(sp)
    8000419a:	e456                	sd	s5,8(sp)
    8000419c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000419e:	0001d497          	auipc	s1,0x1d
    800041a2:	9b248493          	addi	s1,s1,-1614 # 80020b50 <log>
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	a42080e7          	jalr	-1470(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800041b0:	509c                	lw	a5,32(s1)
    800041b2:	37fd                	addiw	a5,a5,-1
    800041b4:	0007891b          	sext.w	s2,a5
    800041b8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041ba:	50dc                	lw	a5,36(s1)
    800041bc:	efb9                	bnez	a5,8000421a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041be:	06091663          	bnez	s2,8000422a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041c2:	0001d497          	auipc	s1,0x1d
    800041c6:	98e48493          	addi	s1,s1,-1650 # 80020b50 <log>
    800041ca:	4785                	li	a5,1
    800041cc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	ace080e7          	jalr	-1330(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041d8:	54dc                	lw	a5,44(s1)
    800041da:	06f04763          	bgtz	a5,80004248 <end_op+0xbc>
    acquire(&log.lock);
    800041de:	0001d497          	auipc	s1,0x1d
    800041e2:	97248493          	addi	s1,s1,-1678 # 80020b50 <log>
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	a02080e7          	jalr	-1534(ra) # 80000bea <acquire>
    log.committing = 0;
    800041f0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffe097          	auipc	ra,0xffffe
    800041fa:	fc4080e7          	jalr	-60(ra) # 800021ba <wakeup>
    release(&log.lock);
    800041fe:	8526                	mv	a0,s1
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	a9e080e7          	jalr	-1378(ra) # 80000c9e <release>
}
    80004208:	70e2                	ld	ra,56(sp)
    8000420a:	7442                	ld	s0,48(sp)
    8000420c:	74a2                	ld	s1,40(sp)
    8000420e:	7902                	ld	s2,32(sp)
    80004210:	69e2                	ld	s3,24(sp)
    80004212:	6a42                	ld	s4,16(sp)
    80004214:	6aa2                	ld	s5,8(sp)
    80004216:	6121                	addi	sp,sp,64
    80004218:	8082                	ret
    panic("log.committing");
    8000421a:	00004517          	auipc	a0,0x4
    8000421e:	44650513          	addi	a0,a0,1094 # 80008660 <syscalls+0x1e0>
    80004222:	ffffc097          	auipc	ra,0xffffc
    80004226:	322080e7          	jalr	802(ra) # 80000544 <panic>
    wakeup(&log);
    8000422a:	0001d497          	auipc	s1,0x1d
    8000422e:	92648493          	addi	s1,s1,-1754 # 80020b50 <log>
    80004232:	8526                	mv	a0,s1
    80004234:	ffffe097          	auipc	ra,0xffffe
    80004238:	f86080e7          	jalr	-122(ra) # 800021ba <wakeup>
  release(&log.lock);
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	a60080e7          	jalr	-1440(ra) # 80000c9e <release>
  if(do_commit){
    80004246:	b7c9                	j	80004208 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004248:	0001da97          	auipc	s5,0x1d
    8000424c:	938a8a93          	addi	s5,s5,-1736 # 80020b80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004250:	0001da17          	auipc	s4,0x1d
    80004254:	900a0a13          	addi	s4,s4,-1792 # 80020b50 <log>
    80004258:	018a2583          	lw	a1,24(s4)
    8000425c:	012585bb          	addw	a1,a1,s2
    80004260:	2585                	addiw	a1,a1,1
    80004262:	028a2503          	lw	a0,40(s4)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	cca080e7          	jalr	-822(ra) # 80002f30 <bread>
    8000426e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004270:	000aa583          	lw	a1,0(s5)
    80004274:	028a2503          	lw	a0,40(s4)
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	cb8080e7          	jalr	-840(ra) # 80002f30 <bread>
    80004280:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004282:	40000613          	li	a2,1024
    80004286:	05850593          	addi	a1,a0,88
    8000428a:	05848513          	addi	a0,s1,88
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	ab8080e7          	jalr	-1352(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004296:	8526                	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	d8a080e7          	jalr	-630(ra) # 80003022 <bwrite>
    brelse(from);
    800042a0:	854e                	mv	a0,s3
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	dbe080e7          	jalr	-578(ra) # 80003060 <brelse>
    brelse(to);
    800042aa:	8526                	mv	a0,s1
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	db4080e7          	jalr	-588(ra) # 80003060 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b4:	2905                	addiw	s2,s2,1
    800042b6:	0a91                	addi	s5,s5,4
    800042b8:	02ca2783          	lw	a5,44(s4)
    800042bc:	f8f94ee3          	blt	s2,a5,80004258 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	c6a080e7          	jalr	-918(ra) # 80003f2a <write_head>
    install_trans(0); // Now install writes to home locations
    800042c8:	4501                	li	a0,0
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	cda080e7          	jalr	-806(ra) # 80003fa4 <install_trans>
    log.lh.n = 0;
    800042d2:	0001d797          	auipc	a5,0x1d
    800042d6:	8a07a523          	sw	zero,-1878(a5) # 80020b7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042da:	00000097          	auipc	ra,0x0
    800042de:	c50080e7          	jalr	-944(ra) # 80003f2a <write_head>
    800042e2:	bdf5                	j	800041de <end_op+0x52>

00000000800042e4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042e4:	1101                	addi	sp,sp,-32
    800042e6:	ec06                	sd	ra,24(sp)
    800042e8:	e822                	sd	s0,16(sp)
    800042ea:	e426                	sd	s1,8(sp)
    800042ec:	e04a                	sd	s2,0(sp)
    800042ee:	1000                	addi	s0,sp,32
    800042f0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042f2:	0001d917          	auipc	s2,0x1d
    800042f6:	85e90913          	addi	s2,s2,-1954 # 80020b50 <log>
    800042fa:	854a                	mv	a0,s2
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	8ee080e7          	jalr	-1810(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004304:	02c92603          	lw	a2,44(s2)
    80004308:	47f5                	li	a5,29
    8000430a:	06c7c563          	blt	a5,a2,80004374 <log_write+0x90>
    8000430e:	0001d797          	auipc	a5,0x1d
    80004312:	85e7a783          	lw	a5,-1954(a5) # 80020b6c <log+0x1c>
    80004316:	37fd                	addiw	a5,a5,-1
    80004318:	04f65e63          	bge	a2,a5,80004374 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000431c:	0001d797          	auipc	a5,0x1d
    80004320:	8547a783          	lw	a5,-1964(a5) # 80020b70 <log+0x20>
    80004324:	06f05063          	blez	a5,80004384 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004328:	4781                	li	a5,0
    8000432a:	06c05563          	blez	a2,80004394 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000432e:	44cc                	lw	a1,12(s1)
    80004330:	0001d717          	auipc	a4,0x1d
    80004334:	85070713          	addi	a4,a4,-1968 # 80020b80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004338:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000433a:	4314                	lw	a3,0(a4)
    8000433c:	04b68c63          	beq	a3,a1,80004394 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004340:	2785                	addiw	a5,a5,1
    80004342:	0711                	addi	a4,a4,4
    80004344:	fef61be3          	bne	a2,a5,8000433a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004348:	0621                	addi	a2,a2,8
    8000434a:	060a                	slli	a2,a2,0x2
    8000434c:	0001d797          	auipc	a5,0x1d
    80004350:	80478793          	addi	a5,a5,-2044 # 80020b50 <log>
    80004354:	963e                	add	a2,a2,a5
    80004356:	44dc                	lw	a5,12(s1)
    80004358:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000435a:	8526                	mv	a0,s1
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	da2080e7          	jalr	-606(ra) # 800030fe <bpin>
    log.lh.n++;
    80004364:	0001c717          	auipc	a4,0x1c
    80004368:	7ec70713          	addi	a4,a4,2028 # 80020b50 <log>
    8000436c:	575c                	lw	a5,44(a4)
    8000436e:	2785                	addiw	a5,a5,1
    80004370:	d75c                	sw	a5,44(a4)
    80004372:	a835                	j	800043ae <log_write+0xca>
    panic("too big a transaction");
    80004374:	00004517          	auipc	a0,0x4
    80004378:	2fc50513          	addi	a0,a0,764 # 80008670 <syscalls+0x1f0>
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	1c8080e7          	jalr	456(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004384:	00004517          	auipc	a0,0x4
    80004388:	30450513          	addi	a0,a0,772 # 80008688 <syscalls+0x208>
    8000438c:	ffffc097          	auipc	ra,0xffffc
    80004390:	1b8080e7          	jalr	440(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004394:	00878713          	addi	a4,a5,8
    80004398:	00271693          	slli	a3,a4,0x2
    8000439c:	0001c717          	auipc	a4,0x1c
    800043a0:	7b470713          	addi	a4,a4,1972 # 80020b50 <log>
    800043a4:	9736                	add	a4,a4,a3
    800043a6:	44d4                	lw	a3,12(s1)
    800043a8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043aa:	faf608e3          	beq	a2,a5,8000435a <log_write+0x76>
  }
  release(&log.lock);
    800043ae:	0001c517          	auipc	a0,0x1c
    800043b2:	7a250513          	addi	a0,a0,1954 # 80020b50 <log>
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	8e8080e7          	jalr	-1816(ra) # 80000c9e <release>
}
    800043be:	60e2                	ld	ra,24(sp)
    800043c0:	6442                	ld	s0,16(sp)
    800043c2:	64a2                	ld	s1,8(sp)
    800043c4:	6902                	ld	s2,0(sp)
    800043c6:	6105                	addi	sp,sp,32
    800043c8:	8082                	ret

00000000800043ca <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043ca:	1101                	addi	sp,sp,-32
    800043cc:	ec06                	sd	ra,24(sp)
    800043ce:	e822                	sd	s0,16(sp)
    800043d0:	e426                	sd	s1,8(sp)
    800043d2:	e04a                	sd	s2,0(sp)
    800043d4:	1000                	addi	s0,sp,32
    800043d6:	84aa                	mv	s1,a0
    800043d8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043da:	00004597          	auipc	a1,0x4
    800043de:	2ce58593          	addi	a1,a1,718 # 800086a8 <syscalls+0x228>
    800043e2:	0521                	addi	a0,a0,8
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	776080e7          	jalr	1910(ra) # 80000b5a <initlock>
  lk->name = name;
    800043ec:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043f4:	0204a423          	sw	zero,40(s1)
}
    800043f8:	60e2                	ld	ra,24(sp)
    800043fa:	6442                	ld	s0,16(sp)
    800043fc:	64a2                	ld	s1,8(sp)
    800043fe:	6902                	ld	s2,0(sp)
    80004400:	6105                	addi	sp,sp,32
    80004402:	8082                	ret

0000000080004404 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004404:	1101                	addi	sp,sp,-32
    80004406:	ec06                	sd	ra,24(sp)
    80004408:	e822                	sd	s0,16(sp)
    8000440a:	e426                	sd	s1,8(sp)
    8000440c:	e04a                	sd	s2,0(sp)
    8000440e:	1000                	addi	s0,sp,32
    80004410:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004412:	00850913          	addi	s2,a0,8
    80004416:	854a                	mv	a0,s2
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	7d2080e7          	jalr	2002(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004420:	409c                	lw	a5,0(s1)
    80004422:	cb89                	beqz	a5,80004434 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004424:	85ca                	mv	a1,s2
    80004426:	8526                	mv	a0,s1
    80004428:	ffffe097          	auipc	ra,0xffffe
    8000442c:	d2e080e7          	jalr	-722(ra) # 80002156 <sleep>
  while (lk->locked) {
    80004430:	409c                	lw	a5,0(s1)
    80004432:	fbed                	bnez	a5,80004424 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004434:	4785                	li	a5,1
    80004436:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	67a080e7          	jalr	1658(ra) # 80001ab2 <myproc>
    80004440:	591c                	lw	a5,48(a0)
    80004442:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004444:	854a                	mv	a0,s2
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	858080e7          	jalr	-1960(ra) # 80000c9e <release>
}
    8000444e:	60e2                	ld	ra,24(sp)
    80004450:	6442                	ld	s0,16(sp)
    80004452:	64a2                	ld	s1,8(sp)
    80004454:	6902                	ld	s2,0(sp)
    80004456:	6105                	addi	sp,sp,32
    80004458:	8082                	ret

000000008000445a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000445a:	1101                	addi	sp,sp,-32
    8000445c:	ec06                	sd	ra,24(sp)
    8000445e:	e822                	sd	s0,16(sp)
    80004460:	e426                	sd	s1,8(sp)
    80004462:	e04a                	sd	s2,0(sp)
    80004464:	1000                	addi	s0,sp,32
    80004466:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004468:	00850913          	addi	s2,a0,8
    8000446c:	854a                	mv	a0,s2
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	77c080e7          	jalr	1916(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004476:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000447a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000447e:	8526                	mv	a0,s1
    80004480:	ffffe097          	auipc	ra,0xffffe
    80004484:	d3a080e7          	jalr	-710(ra) # 800021ba <wakeup>
  release(&lk->lk);
    80004488:	854a                	mv	a0,s2
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	814080e7          	jalr	-2028(ra) # 80000c9e <release>
}
    80004492:	60e2                	ld	ra,24(sp)
    80004494:	6442                	ld	s0,16(sp)
    80004496:	64a2                	ld	s1,8(sp)
    80004498:	6902                	ld	s2,0(sp)
    8000449a:	6105                	addi	sp,sp,32
    8000449c:	8082                	ret

000000008000449e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000449e:	7179                	addi	sp,sp,-48
    800044a0:	f406                	sd	ra,40(sp)
    800044a2:	f022                	sd	s0,32(sp)
    800044a4:	ec26                	sd	s1,24(sp)
    800044a6:	e84a                	sd	s2,16(sp)
    800044a8:	e44e                	sd	s3,8(sp)
    800044aa:	1800                	addi	s0,sp,48
    800044ac:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044ae:	00850913          	addi	s2,a0,8
    800044b2:	854a                	mv	a0,s2
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	736080e7          	jalr	1846(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044bc:	409c                	lw	a5,0(s1)
    800044be:	ef99                	bnez	a5,800044dc <holdingsleep+0x3e>
    800044c0:	4481                	li	s1,0
  release(&lk->lk);
    800044c2:	854a                	mv	a0,s2
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	7da080e7          	jalr	2010(ra) # 80000c9e <release>
  return r;
}
    800044cc:	8526                	mv	a0,s1
    800044ce:	70a2                	ld	ra,40(sp)
    800044d0:	7402                	ld	s0,32(sp)
    800044d2:	64e2                	ld	s1,24(sp)
    800044d4:	6942                	ld	s2,16(sp)
    800044d6:	69a2                	ld	s3,8(sp)
    800044d8:	6145                	addi	sp,sp,48
    800044da:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044dc:	0284a983          	lw	s3,40(s1)
    800044e0:	ffffd097          	auipc	ra,0xffffd
    800044e4:	5d2080e7          	jalr	1490(ra) # 80001ab2 <myproc>
    800044e8:	5904                	lw	s1,48(a0)
    800044ea:	413484b3          	sub	s1,s1,s3
    800044ee:	0014b493          	seqz	s1,s1
    800044f2:	bfc1                	j	800044c2 <holdingsleep+0x24>

00000000800044f4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044f4:	1141                	addi	sp,sp,-16
    800044f6:	e406                	sd	ra,8(sp)
    800044f8:	e022                	sd	s0,0(sp)
    800044fa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044fc:	00004597          	auipc	a1,0x4
    80004500:	1bc58593          	addi	a1,a1,444 # 800086b8 <syscalls+0x238>
    80004504:	0001c517          	auipc	a0,0x1c
    80004508:	79450513          	addi	a0,a0,1940 # 80020c98 <ftable>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	64e080e7          	jalr	1614(ra) # 80000b5a <initlock>
}
    80004514:	60a2                	ld	ra,8(sp)
    80004516:	6402                	ld	s0,0(sp)
    80004518:	0141                	addi	sp,sp,16
    8000451a:	8082                	ret

000000008000451c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000451c:	1101                	addi	sp,sp,-32
    8000451e:	ec06                	sd	ra,24(sp)
    80004520:	e822                	sd	s0,16(sp)
    80004522:	e426                	sd	s1,8(sp)
    80004524:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004526:	0001c517          	auipc	a0,0x1c
    8000452a:	77250513          	addi	a0,a0,1906 # 80020c98 <ftable>
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	6bc080e7          	jalr	1724(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004536:	0001c497          	auipc	s1,0x1c
    8000453a:	77a48493          	addi	s1,s1,1914 # 80020cb0 <ftable+0x18>
    8000453e:	0001d717          	auipc	a4,0x1d
    80004542:	71270713          	addi	a4,a4,1810 # 80021c50 <disk>
    if(f->ref == 0){
    80004546:	40dc                	lw	a5,4(s1)
    80004548:	cf99                	beqz	a5,80004566 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000454a:	02848493          	addi	s1,s1,40
    8000454e:	fee49ce3          	bne	s1,a4,80004546 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004552:	0001c517          	auipc	a0,0x1c
    80004556:	74650513          	addi	a0,a0,1862 # 80020c98 <ftable>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	744080e7          	jalr	1860(ra) # 80000c9e <release>
  return 0;
    80004562:	4481                	li	s1,0
    80004564:	a819                	j	8000457a <filealloc+0x5e>
      f->ref = 1;
    80004566:	4785                	li	a5,1
    80004568:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000456a:	0001c517          	auipc	a0,0x1c
    8000456e:	72e50513          	addi	a0,a0,1838 # 80020c98 <ftable>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	72c080e7          	jalr	1836(ra) # 80000c9e <release>
}
    8000457a:	8526                	mv	a0,s1
    8000457c:	60e2                	ld	ra,24(sp)
    8000457e:	6442                	ld	s0,16(sp)
    80004580:	64a2                	ld	s1,8(sp)
    80004582:	6105                	addi	sp,sp,32
    80004584:	8082                	ret

0000000080004586 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004586:	1101                	addi	sp,sp,-32
    80004588:	ec06                	sd	ra,24(sp)
    8000458a:	e822                	sd	s0,16(sp)
    8000458c:	e426                	sd	s1,8(sp)
    8000458e:	1000                	addi	s0,sp,32
    80004590:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004592:	0001c517          	auipc	a0,0x1c
    80004596:	70650513          	addi	a0,a0,1798 # 80020c98 <ftable>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	650080e7          	jalr	1616(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800045a2:	40dc                	lw	a5,4(s1)
    800045a4:	02f05263          	blez	a5,800045c8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045a8:	2785                	addiw	a5,a5,1
    800045aa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045ac:	0001c517          	auipc	a0,0x1c
    800045b0:	6ec50513          	addi	a0,a0,1772 # 80020c98 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	6ea080e7          	jalr	1770(ra) # 80000c9e <release>
  return f;
}
    800045bc:	8526                	mv	a0,s1
    800045be:	60e2                	ld	ra,24(sp)
    800045c0:	6442                	ld	s0,16(sp)
    800045c2:	64a2                	ld	s1,8(sp)
    800045c4:	6105                	addi	sp,sp,32
    800045c6:	8082                	ret
    panic("filedup");
    800045c8:	00004517          	auipc	a0,0x4
    800045cc:	0f850513          	addi	a0,a0,248 # 800086c0 <syscalls+0x240>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	f74080e7          	jalr	-140(ra) # 80000544 <panic>

00000000800045d8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045d8:	7139                	addi	sp,sp,-64
    800045da:	fc06                	sd	ra,56(sp)
    800045dc:	f822                	sd	s0,48(sp)
    800045de:	f426                	sd	s1,40(sp)
    800045e0:	f04a                	sd	s2,32(sp)
    800045e2:	ec4e                	sd	s3,24(sp)
    800045e4:	e852                	sd	s4,16(sp)
    800045e6:	e456                	sd	s5,8(sp)
    800045e8:	0080                	addi	s0,sp,64
    800045ea:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ec:	0001c517          	auipc	a0,0x1c
    800045f0:	6ac50513          	addi	a0,a0,1708 # 80020c98 <ftable>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	5f6080e7          	jalr	1526(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800045fc:	40dc                	lw	a5,4(s1)
    800045fe:	06f05163          	blez	a5,80004660 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004602:	37fd                	addiw	a5,a5,-1
    80004604:	0007871b          	sext.w	a4,a5
    80004608:	c0dc                	sw	a5,4(s1)
    8000460a:	06e04363          	bgtz	a4,80004670 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000460e:	0004a903          	lw	s2,0(s1)
    80004612:	0094ca83          	lbu	s5,9(s1)
    80004616:	0104ba03          	ld	s4,16(s1)
    8000461a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000461e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004622:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004626:	0001c517          	auipc	a0,0x1c
    8000462a:	67250513          	addi	a0,a0,1650 # 80020c98 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	670080e7          	jalr	1648(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004636:	4785                	li	a5,1
    80004638:	04f90d63          	beq	s2,a5,80004692 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000463c:	3979                	addiw	s2,s2,-2
    8000463e:	4785                	li	a5,1
    80004640:	0527e063          	bltu	a5,s2,80004680 <fileclose+0xa8>
    begin_op();
    80004644:	00000097          	auipc	ra,0x0
    80004648:	ac8080e7          	jalr	-1336(ra) # 8000410c <begin_op>
    iput(ff.ip);
    8000464c:	854e                	mv	a0,s3
    8000464e:	fffff097          	auipc	ra,0xfffff
    80004652:	2b6080e7          	jalr	694(ra) # 80003904 <iput>
    end_op();
    80004656:	00000097          	auipc	ra,0x0
    8000465a:	b36080e7          	jalr	-1226(ra) # 8000418c <end_op>
    8000465e:	a00d                	j	80004680 <fileclose+0xa8>
    panic("fileclose");
    80004660:	00004517          	auipc	a0,0x4
    80004664:	06850513          	addi	a0,a0,104 # 800086c8 <syscalls+0x248>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	edc080e7          	jalr	-292(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004670:	0001c517          	auipc	a0,0x1c
    80004674:	62850513          	addi	a0,a0,1576 # 80020c98 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	626080e7          	jalr	1574(ra) # 80000c9e <release>
  }
}
    80004680:	70e2                	ld	ra,56(sp)
    80004682:	7442                	ld	s0,48(sp)
    80004684:	74a2                	ld	s1,40(sp)
    80004686:	7902                	ld	s2,32(sp)
    80004688:	69e2                	ld	s3,24(sp)
    8000468a:	6a42                	ld	s4,16(sp)
    8000468c:	6aa2                	ld	s5,8(sp)
    8000468e:	6121                	addi	sp,sp,64
    80004690:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004692:	85d6                	mv	a1,s5
    80004694:	8552                	mv	a0,s4
    80004696:	00000097          	auipc	ra,0x0
    8000469a:	34c080e7          	jalr	844(ra) # 800049e2 <pipeclose>
    8000469e:	b7cd                	j	80004680 <fileclose+0xa8>

00000000800046a0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046a0:	715d                	addi	sp,sp,-80
    800046a2:	e486                	sd	ra,72(sp)
    800046a4:	e0a2                	sd	s0,64(sp)
    800046a6:	fc26                	sd	s1,56(sp)
    800046a8:	f84a                	sd	s2,48(sp)
    800046aa:	f44e                	sd	s3,40(sp)
    800046ac:	0880                	addi	s0,sp,80
    800046ae:	84aa                	mv	s1,a0
    800046b0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046b2:	ffffd097          	auipc	ra,0xffffd
    800046b6:	400080e7          	jalr	1024(ra) # 80001ab2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ba:	409c                	lw	a5,0(s1)
    800046bc:	37f9                	addiw	a5,a5,-2
    800046be:	4705                	li	a4,1
    800046c0:	04f76763          	bltu	a4,a5,8000470e <filestat+0x6e>
    800046c4:	892a                	mv	s2,a0
    ilock(f->ip);
    800046c6:	6c88                	ld	a0,24(s1)
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	082080e7          	jalr	130(ra) # 8000374a <ilock>
    stati(f->ip, &st);
    800046d0:	fb840593          	addi	a1,s0,-72
    800046d4:	6c88                	ld	a0,24(s1)
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	2fe080e7          	jalr	766(ra) # 800039d4 <stati>
    iunlock(f->ip);
    800046de:	6c88                	ld	a0,24(s1)
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	12c080e7          	jalr	300(ra) # 8000380c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046e8:	46e1                	li	a3,24
    800046ea:	fb840613          	addi	a2,s0,-72
    800046ee:	85ce                	mv	a1,s3
    800046f0:	05093503          	ld	a0,80(s2)
    800046f4:	ffffd097          	auipc	ra,0xffffd
    800046f8:	07c080e7          	jalr	124(ra) # 80001770 <copyout>
    800046fc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004700:	60a6                	ld	ra,72(sp)
    80004702:	6406                	ld	s0,64(sp)
    80004704:	74e2                	ld	s1,56(sp)
    80004706:	7942                	ld	s2,48(sp)
    80004708:	79a2                	ld	s3,40(sp)
    8000470a:	6161                	addi	sp,sp,80
    8000470c:	8082                	ret
  return -1;
    8000470e:	557d                	li	a0,-1
    80004710:	bfc5                	j	80004700 <filestat+0x60>

0000000080004712 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004712:	7179                	addi	sp,sp,-48
    80004714:	f406                	sd	ra,40(sp)
    80004716:	f022                	sd	s0,32(sp)
    80004718:	ec26                	sd	s1,24(sp)
    8000471a:	e84a                	sd	s2,16(sp)
    8000471c:	e44e                	sd	s3,8(sp)
    8000471e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004720:	00854783          	lbu	a5,8(a0)
    80004724:	c3d5                	beqz	a5,800047c8 <fileread+0xb6>
    80004726:	84aa                	mv	s1,a0
    80004728:	89ae                	mv	s3,a1
    8000472a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000472c:	411c                	lw	a5,0(a0)
    8000472e:	4705                	li	a4,1
    80004730:	04e78963          	beq	a5,a4,80004782 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004734:	470d                	li	a4,3
    80004736:	04e78d63          	beq	a5,a4,80004790 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000473a:	4709                	li	a4,2
    8000473c:	06e79e63          	bne	a5,a4,800047b8 <fileread+0xa6>
    ilock(f->ip);
    80004740:	6d08                	ld	a0,24(a0)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	008080e7          	jalr	8(ra) # 8000374a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000474a:	874a                	mv	a4,s2
    8000474c:	5094                	lw	a3,32(s1)
    8000474e:	864e                	mv	a2,s3
    80004750:	4585                	li	a1,1
    80004752:	6c88                	ld	a0,24(s1)
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	2aa080e7          	jalr	682(ra) # 800039fe <readi>
    8000475c:	892a                	mv	s2,a0
    8000475e:	00a05563          	blez	a0,80004768 <fileread+0x56>
      f->off += r;
    80004762:	509c                	lw	a5,32(s1)
    80004764:	9fa9                	addw	a5,a5,a0
    80004766:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004768:	6c88                	ld	a0,24(s1)
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	0a2080e7          	jalr	162(ra) # 8000380c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004772:	854a                	mv	a0,s2
    80004774:	70a2                	ld	ra,40(sp)
    80004776:	7402                	ld	s0,32(sp)
    80004778:	64e2                	ld	s1,24(sp)
    8000477a:	6942                	ld	s2,16(sp)
    8000477c:	69a2                	ld	s3,8(sp)
    8000477e:	6145                	addi	sp,sp,48
    80004780:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004782:	6908                	ld	a0,16(a0)
    80004784:	00000097          	auipc	ra,0x0
    80004788:	3ce080e7          	jalr	974(ra) # 80004b52 <piperead>
    8000478c:	892a                	mv	s2,a0
    8000478e:	b7d5                	j	80004772 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004790:	02451783          	lh	a5,36(a0)
    80004794:	03079693          	slli	a3,a5,0x30
    80004798:	92c1                	srli	a3,a3,0x30
    8000479a:	4725                	li	a4,9
    8000479c:	02d76863          	bltu	a4,a3,800047cc <fileread+0xba>
    800047a0:	0792                	slli	a5,a5,0x4
    800047a2:	0001c717          	auipc	a4,0x1c
    800047a6:	45670713          	addi	a4,a4,1110 # 80020bf8 <devsw>
    800047aa:	97ba                	add	a5,a5,a4
    800047ac:	639c                	ld	a5,0(a5)
    800047ae:	c38d                	beqz	a5,800047d0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047b0:	4505                	li	a0,1
    800047b2:	9782                	jalr	a5
    800047b4:	892a                	mv	s2,a0
    800047b6:	bf75                	j	80004772 <fileread+0x60>
    panic("fileread");
    800047b8:	00004517          	auipc	a0,0x4
    800047bc:	f2050513          	addi	a0,a0,-224 # 800086d8 <syscalls+0x258>
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	d84080e7          	jalr	-636(ra) # 80000544 <panic>
    return -1;
    800047c8:	597d                	li	s2,-1
    800047ca:	b765                	j	80004772 <fileread+0x60>
      return -1;
    800047cc:	597d                	li	s2,-1
    800047ce:	b755                	j	80004772 <fileread+0x60>
    800047d0:	597d                	li	s2,-1
    800047d2:	b745                	j	80004772 <fileread+0x60>

00000000800047d4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047d4:	715d                	addi	sp,sp,-80
    800047d6:	e486                	sd	ra,72(sp)
    800047d8:	e0a2                	sd	s0,64(sp)
    800047da:	fc26                	sd	s1,56(sp)
    800047dc:	f84a                	sd	s2,48(sp)
    800047de:	f44e                	sd	s3,40(sp)
    800047e0:	f052                	sd	s4,32(sp)
    800047e2:	ec56                	sd	s5,24(sp)
    800047e4:	e85a                	sd	s6,16(sp)
    800047e6:	e45e                	sd	s7,8(sp)
    800047e8:	e062                	sd	s8,0(sp)
    800047ea:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047ec:	00954783          	lbu	a5,9(a0)
    800047f0:	10078663          	beqz	a5,800048fc <filewrite+0x128>
    800047f4:	892a                	mv	s2,a0
    800047f6:	8aae                	mv	s5,a1
    800047f8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047fa:	411c                	lw	a5,0(a0)
    800047fc:	4705                	li	a4,1
    800047fe:	02e78263          	beq	a5,a4,80004822 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004802:	470d                	li	a4,3
    80004804:	02e78663          	beq	a5,a4,80004830 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004808:	4709                	li	a4,2
    8000480a:	0ee79163          	bne	a5,a4,800048ec <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000480e:	0ac05d63          	blez	a2,800048c8 <filewrite+0xf4>
    int i = 0;
    80004812:	4981                	li	s3,0
    80004814:	6b05                	lui	s6,0x1
    80004816:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000481a:	6b85                	lui	s7,0x1
    8000481c:	c00b8b9b          	addiw	s7,s7,-1024
    80004820:	a861                	j	800048b8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004822:	6908                	ld	a0,16(a0)
    80004824:	00000097          	auipc	ra,0x0
    80004828:	22e080e7          	jalr	558(ra) # 80004a52 <pipewrite>
    8000482c:	8a2a                	mv	s4,a0
    8000482e:	a045                	j	800048ce <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004830:	02451783          	lh	a5,36(a0)
    80004834:	03079693          	slli	a3,a5,0x30
    80004838:	92c1                	srli	a3,a3,0x30
    8000483a:	4725                	li	a4,9
    8000483c:	0cd76263          	bltu	a4,a3,80004900 <filewrite+0x12c>
    80004840:	0792                	slli	a5,a5,0x4
    80004842:	0001c717          	auipc	a4,0x1c
    80004846:	3b670713          	addi	a4,a4,950 # 80020bf8 <devsw>
    8000484a:	97ba                	add	a5,a5,a4
    8000484c:	679c                	ld	a5,8(a5)
    8000484e:	cbdd                	beqz	a5,80004904 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004850:	4505                	li	a0,1
    80004852:	9782                	jalr	a5
    80004854:	8a2a                	mv	s4,a0
    80004856:	a8a5                	j	800048ce <filewrite+0xfa>
    80004858:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	8b0080e7          	jalr	-1872(ra) # 8000410c <begin_op>
      ilock(f->ip);
    80004864:	01893503          	ld	a0,24(s2)
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	ee2080e7          	jalr	-286(ra) # 8000374a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004870:	8762                	mv	a4,s8
    80004872:	02092683          	lw	a3,32(s2)
    80004876:	01598633          	add	a2,s3,s5
    8000487a:	4585                	li	a1,1
    8000487c:	01893503          	ld	a0,24(s2)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	276080e7          	jalr	630(ra) # 80003af6 <writei>
    80004888:	84aa                	mv	s1,a0
    8000488a:	00a05763          	blez	a0,80004898 <filewrite+0xc4>
        f->off += r;
    8000488e:	02092783          	lw	a5,32(s2)
    80004892:	9fa9                	addw	a5,a5,a0
    80004894:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004898:	01893503          	ld	a0,24(s2)
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	f70080e7          	jalr	-144(ra) # 8000380c <iunlock>
      end_op();
    800048a4:	00000097          	auipc	ra,0x0
    800048a8:	8e8080e7          	jalr	-1816(ra) # 8000418c <end_op>

      if(r != n1){
    800048ac:	009c1f63          	bne	s8,s1,800048ca <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048b0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048b4:	0149db63          	bge	s3,s4,800048ca <filewrite+0xf6>
      int n1 = n - i;
    800048b8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048bc:	84be                	mv	s1,a5
    800048be:	2781                	sext.w	a5,a5
    800048c0:	f8fb5ce3          	bge	s6,a5,80004858 <filewrite+0x84>
    800048c4:	84de                	mv	s1,s7
    800048c6:	bf49                	j	80004858 <filewrite+0x84>
    int i = 0;
    800048c8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048ca:	013a1f63          	bne	s4,s3,800048e8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ce:	8552                	mv	a0,s4
    800048d0:	60a6                	ld	ra,72(sp)
    800048d2:	6406                	ld	s0,64(sp)
    800048d4:	74e2                	ld	s1,56(sp)
    800048d6:	7942                	ld	s2,48(sp)
    800048d8:	79a2                	ld	s3,40(sp)
    800048da:	7a02                	ld	s4,32(sp)
    800048dc:	6ae2                	ld	s5,24(sp)
    800048de:	6b42                	ld	s6,16(sp)
    800048e0:	6ba2                	ld	s7,8(sp)
    800048e2:	6c02                	ld	s8,0(sp)
    800048e4:	6161                	addi	sp,sp,80
    800048e6:	8082                	ret
    ret = (i == n ? n : -1);
    800048e8:	5a7d                	li	s4,-1
    800048ea:	b7d5                	j	800048ce <filewrite+0xfa>
    panic("filewrite");
    800048ec:	00004517          	auipc	a0,0x4
    800048f0:	dfc50513          	addi	a0,a0,-516 # 800086e8 <syscalls+0x268>
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	c50080e7          	jalr	-944(ra) # 80000544 <panic>
    return -1;
    800048fc:	5a7d                	li	s4,-1
    800048fe:	bfc1                	j	800048ce <filewrite+0xfa>
      return -1;
    80004900:	5a7d                	li	s4,-1
    80004902:	b7f1                	j	800048ce <filewrite+0xfa>
    80004904:	5a7d                	li	s4,-1
    80004906:	b7e1                	j	800048ce <filewrite+0xfa>

0000000080004908 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004908:	7179                	addi	sp,sp,-48
    8000490a:	f406                	sd	ra,40(sp)
    8000490c:	f022                	sd	s0,32(sp)
    8000490e:	ec26                	sd	s1,24(sp)
    80004910:	e84a                	sd	s2,16(sp)
    80004912:	e44e                	sd	s3,8(sp)
    80004914:	e052                	sd	s4,0(sp)
    80004916:	1800                	addi	s0,sp,48
    80004918:	84aa                	mv	s1,a0
    8000491a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000491c:	0005b023          	sd	zero,0(a1)
    80004920:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004924:	00000097          	auipc	ra,0x0
    80004928:	bf8080e7          	jalr	-1032(ra) # 8000451c <filealloc>
    8000492c:	e088                	sd	a0,0(s1)
    8000492e:	c551                	beqz	a0,800049ba <pipealloc+0xb2>
    80004930:	00000097          	auipc	ra,0x0
    80004934:	bec080e7          	jalr	-1044(ra) # 8000451c <filealloc>
    80004938:	00aa3023          	sd	a0,0(s4)
    8000493c:	c92d                	beqz	a0,800049ae <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	1bc080e7          	jalr	444(ra) # 80000afa <kalloc>
    80004946:	892a                	mv	s2,a0
    80004948:	c125                	beqz	a0,800049a8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000494a:	4985                	li	s3,1
    8000494c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004950:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004954:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004958:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000495c:	00004597          	auipc	a1,0x4
    80004960:	d9c58593          	addi	a1,a1,-612 # 800086f8 <syscalls+0x278>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	1f6080e7          	jalr	502(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    8000496c:	609c                	ld	a5,0(s1)
    8000496e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004972:	609c                	ld	a5,0(s1)
    80004974:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004978:	609c                	ld	a5,0(s1)
    8000497a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000497e:	609c                	ld	a5,0(s1)
    80004980:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004984:	000a3783          	ld	a5,0(s4)
    80004988:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000498c:	000a3783          	ld	a5,0(s4)
    80004990:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004994:	000a3783          	ld	a5,0(s4)
    80004998:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000499c:	000a3783          	ld	a5,0(s4)
    800049a0:	0127b823          	sd	s2,16(a5)
  return 0;
    800049a4:	4501                	li	a0,0
    800049a6:	a025                	j	800049ce <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049a8:	6088                	ld	a0,0(s1)
    800049aa:	e501                	bnez	a0,800049b2 <pipealloc+0xaa>
    800049ac:	a039                	j	800049ba <pipealloc+0xb2>
    800049ae:	6088                	ld	a0,0(s1)
    800049b0:	c51d                	beqz	a0,800049de <pipealloc+0xd6>
    fileclose(*f0);
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	c26080e7          	jalr	-986(ra) # 800045d8 <fileclose>
  if(*f1)
    800049ba:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049be:	557d                	li	a0,-1
  if(*f1)
    800049c0:	c799                	beqz	a5,800049ce <pipealloc+0xc6>
    fileclose(*f1);
    800049c2:	853e                	mv	a0,a5
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	c14080e7          	jalr	-1004(ra) # 800045d8 <fileclose>
  return -1;
    800049cc:	557d                	li	a0,-1
}
    800049ce:	70a2                	ld	ra,40(sp)
    800049d0:	7402                	ld	s0,32(sp)
    800049d2:	64e2                	ld	s1,24(sp)
    800049d4:	6942                	ld	s2,16(sp)
    800049d6:	69a2                	ld	s3,8(sp)
    800049d8:	6a02                	ld	s4,0(sp)
    800049da:	6145                	addi	sp,sp,48
    800049dc:	8082                	ret
  return -1;
    800049de:	557d                	li	a0,-1
    800049e0:	b7fd                	j	800049ce <pipealloc+0xc6>

00000000800049e2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049e2:	1101                	addi	sp,sp,-32
    800049e4:	ec06                	sd	ra,24(sp)
    800049e6:	e822                	sd	s0,16(sp)
    800049e8:	e426                	sd	s1,8(sp)
    800049ea:	e04a                	sd	s2,0(sp)
    800049ec:	1000                	addi	s0,sp,32
    800049ee:	84aa                	mv	s1,a0
    800049f0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	1f8080e7          	jalr	504(ra) # 80000bea <acquire>
  if(writable){
    800049fa:	02090d63          	beqz	s2,80004a34 <pipeclose+0x52>
    pi->writeopen = 0;
    800049fe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a02:	21848513          	addi	a0,s1,536
    80004a06:	ffffd097          	auipc	ra,0xffffd
    80004a0a:	7b4080e7          	jalr	1972(ra) # 800021ba <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a0e:	2204b783          	ld	a5,544(s1)
    80004a12:	eb95                	bnez	a5,80004a46 <pipeclose+0x64>
    release(&pi->lock);
    80004a14:	8526                	mv	a0,s1
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	288080e7          	jalr	648(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004a1e:	8526                	mv	a0,s1
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	fde080e7          	jalr	-34(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004a28:	60e2                	ld	ra,24(sp)
    80004a2a:	6442                	ld	s0,16(sp)
    80004a2c:	64a2                	ld	s1,8(sp)
    80004a2e:	6902                	ld	s2,0(sp)
    80004a30:	6105                	addi	sp,sp,32
    80004a32:	8082                	ret
    pi->readopen = 0;
    80004a34:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a38:	21c48513          	addi	a0,s1,540
    80004a3c:	ffffd097          	auipc	ra,0xffffd
    80004a40:	77e080e7          	jalr	1918(ra) # 800021ba <wakeup>
    80004a44:	b7e9                	j	80004a0e <pipeclose+0x2c>
    release(&pi->lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	256080e7          	jalr	598(ra) # 80000c9e <release>
}
    80004a50:	bfe1                	j	80004a28 <pipeclose+0x46>

0000000080004a52 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a52:	7159                	addi	sp,sp,-112
    80004a54:	f486                	sd	ra,104(sp)
    80004a56:	f0a2                	sd	s0,96(sp)
    80004a58:	eca6                	sd	s1,88(sp)
    80004a5a:	e8ca                	sd	s2,80(sp)
    80004a5c:	e4ce                	sd	s3,72(sp)
    80004a5e:	e0d2                	sd	s4,64(sp)
    80004a60:	fc56                	sd	s5,56(sp)
    80004a62:	f85a                	sd	s6,48(sp)
    80004a64:	f45e                	sd	s7,40(sp)
    80004a66:	f062                	sd	s8,32(sp)
    80004a68:	ec66                	sd	s9,24(sp)
    80004a6a:	1880                	addi	s0,sp,112
    80004a6c:	84aa                	mv	s1,a0
    80004a6e:	8aae                	mv	s5,a1
    80004a70:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a72:	ffffd097          	auipc	ra,0xffffd
    80004a76:	040080e7          	jalr	64(ra) # 80001ab2 <myproc>
    80004a7a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a7c:	8526                	mv	a0,s1
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	16c080e7          	jalr	364(ra) # 80000bea <acquire>
  while(i < n){
    80004a86:	0d405463          	blez	s4,80004b4e <pipewrite+0xfc>
    80004a8a:	8ba6                	mv	s7,s1
  int i = 0;
    80004a8c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a8e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a90:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a94:	21c48c13          	addi	s8,s1,540
    80004a98:	a08d                	j	80004afa <pipewrite+0xa8>
      release(&pi->lock);
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	202080e7          	jalr	514(ra) # 80000c9e <release>
      return -1;
    80004aa4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004aa6:	854a                	mv	a0,s2
    80004aa8:	70a6                	ld	ra,104(sp)
    80004aaa:	7406                	ld	s0,96(sp)
    80004aac:	64e6                	ld	s1,88(sp)
    80004aae:	6946                	ld	s2,80(sp)
    80004ab0:	69a6                	ld	s3,72(sp)
    80004ab2:	6a06                	ld	s4,64(sp)
    80004ab4:	7ae2                	ld	s5,56(sp)
    80004ab6:	7b42                	ld	s6,48(sp)
    80004ab8:	7ba2                	ld	s7,40(sp)
    80004aba:	7c02                	ld	s8,32(sp)
    80004abc:	6ce2                	ld	s9,24(sp)
    80004abe:	6165                	addi	sp,sp,112
    80004ac0:	8082                	ret
      wakeup(&pi->nread);
    80004ac2:	8566                	mv	a0,s9
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	6f6080e7          	jalr	1782(ra) # 800021ba <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004acc:	85de                	mv	a1,s7
    80004ace:	8562                	mv	a0,s8
    80004ad0:	ffffd097          	auipc	ra,0xffffd
    80004ad4:	686080e7          	jalr	1670(ra) # 80002156 <sleep>
    80004ad8:	a839                	j	80004af6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ada:	21c4a783          	lw	a5,540(s1)
    80004ade:	0017871b          	addiw	a4,a5,1
    80004ae2:	20e4ae23          	sw	a4,540(s1)
    80004ae6:	1ff7f793          	andi	a5,a5,511
    80004aea:	97a6                	add	a5,a5,s1
    80004aec:	f9f44703          	lbu	a4,-97(s0)
    80004af0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004af4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004af6:	05495063          	bge	s2,s4,80004b36 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004afa:	2204a783          	lw	a5,544(s1)
    80004afe:	dfd1                	beqz	a5,80004a9a <pipewrite+0x48>
    80004b00:	854e                	mv	a0,s3
    80004b02:	ffffe097          	auipc	ra,0xffffe
    80004b06:	8fc080e7          	jalr	-1796(ra) # 800023fe <killed>
    80004b0a:	f941                	bnez	a0,80004a9a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b0c:	2184a783          	lw	a5,536(s1)
    80004b10:	21c4a703          	lw	a4,540(s1)
    80004b14:	2007879b          	addiw	a5,a5,512
    80004b18:	faf705e3          	beq	a4,a5,80004ac2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b1c:	4685                	li	a3,1
    80004b1e:	01590633          	add	a2,s2,s5
    80004b22:	f9f40593          	addi	a1,s0,-97
    80004b26:	0509b503          	ld	a0,80(s3)
    80004b2a:	ffffd097          	auipc	ra,0xffffd
    80004b2e:	cd2080e7          	jalr	-814(ra) # 800017fc <copyin>
    80004b32:	fb6514e3          	bne	a0,s6,80004ada <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b36:	21848513          	addi	a0,s1,536
    80004b3a:	ffffd097          	auipc	ra,0xffffd
    80004b3e:	680080e7          	jalr	1664(ra) # 800021ba <wakeup>
  release(&pi->lock);
    80004b42:	8526                	mv	a0,s1
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	15a080e7          	jalr	346(ra) # 80000c9e <release>
  return i;
    80004b4c:	bfa9                	j	80004aa6 <pipewrite+0x54>
  int i = 0;
    80004b4e:	4901                	li	s2,0
    80004b50:	b7dd                	j	80004b36 <pipewrite+0xe4>

0000000080004b52 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b52:	715d                	addi	sp,sp,-80
    80004b54:	e486                	sd	ra,72(sp)
    80004b56:	e0a2                	sd	s0,64(sp)
    80004b58:	fc26                	sd	s1,56(sp)
    80004b5a:	f84a                	sd	s2,48(sp)
    80004b5c:	f44e                	sd	s3,40(sp)
    80004b5e:	f052                	sd	s4,32(sp)
    80004b60:	ec56                	sd	s5,24(sp)
    80004b62:	e85a                	sd	s6,16(sp)
    80004b64:	0880                	addi	s0,sp,80
    80004b66:	84aa                	mv	s1,a0
    80004b68:	892e                	mv	s2,a1
    80004b6a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b6c:	ffffd097          	auipc	ra,0xffffd
    80004b70:	f46080e7          	jalr	-186(ra) # 80001ab2 <myproc>
    80004b74:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b76:	8b26                	mv	s6,s1
    80004b78:	8526                	mv	a0,s1
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	070080e7          	jalr	112(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b82:	2184a703          	lw	a4,536(s1)
    80004b86:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b8a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b8e:	02f71763          	bne	a4,a5,80004bbc <piperead+0x6a>
    80004b92:	2244a783          	lw	a5,548(s1)
    80004b96:	c39d                	beqz	a5,80004bbc <piperead+0x6a>
    if(killed(pr)){
    80004b98:	8552                	mv	a0,s4
    80004b9a:	ffffe097          	auipc	ra,0xffffe
    80004b9e:	864080e7          	jalr	-1948(ra) # 800023fe <killed>
    80004ba2:	e941                	bnez	a0,80004c32 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ba4:	85da                	mv	a1,s6
    80004ba6:	854e                	mv	a0,s3
    80004ba8:	ffffd097          	auipc	ra,0xffffd
    80004bac:	5ae080e7          	jalr	1454(ra) # 80002156 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb0:	2184a703          	lw	a4,536(s1)
    80004bb4:	21c4a783          	lw	a5,540(s1)
    80004bb8:	fcf70de3          	beq	a4,a5,80004b92 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bbc:	09505263          	blez	s5,80004c40 <piperead+0xee>
    80004bc0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bc2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bc4:	2184a783          	lw	a5,536(s1)
    80004bc8:	21c4a703          	lw	a4,540(s1)
    80004bcc:	02f70d63          	beq	a4,a5,80004c06 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bd0:	0017871b          	addiw	a4,a5,1
    80004bd4:	20e4ac23          	sw	a4,536(s1)
    80004bd8:	1ff7f793          	andi	a5,a5,511
    80004bdc:	97a6                	add	a5,a5,s1
    80004bde:	0187c783          	lbu	a5,24(a5)
    80004be2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004be6:	4685                	li	a3,1
    80004be8:	fbf40613          	addi	a2,s0,-65
    80004bec:	85ca                	mv	a1,s2
    80004bee:	050a3503          	ld	a0,80(s4)
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	b7e080e7          	jalr	-1154(ra) # 80001770 <copyout>
    80004bfa:	01650663          	beq	a0,s6,80004c06 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bfe:	2985                	addiw	s3,s3,1
    80004c00:	0905                	addi	s2,s2,1
    80004c02:	fd3a91e3          	bne	s5,s3,80004bc4 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c06:	21c48513          	addi	a0,s1,540
    80004c0a:	ffffd097          	auipc	ra,0xffffd
    80004c0e:	5b0080e7          	jalr	1456(ra) # 800021ba <wakeup>
  release(&pi->lock);
    80004c12:	8526                	mv	a0,s1
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	08a080e7          	jalr	138(ra) # 80000c9e <release>
  return i;
}
    80004c1c:	854e                	mv	a0,s3
    80004c1e:	60a6                	ld	ra,72(sp)
    80004c20:	6406                	ld	s0,64(sp)
    80004c22:	74e2                	ld	s1,56(sp)
    80004c24:	7942                	ld	s2,48(sp)
    80004c26:	79a2                	ld	s3,40(sp)
    80004c28:	7a02                	ld	s4,32(sp)
    80004c2a:	6ae2                	ld	s5,24(sp)
    80004c2c:	6b42                	ld	s6,16(sp)
    80004c2e:	6161                	addi	sp,sp,80
    80004c30:	8082                	ret
      release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	06a080e7          	jalr	106(ra) # 80000c9e <release>
      return -1;
    80004c3c:	59fd                	li	s3,-1
    80004c3e:	bff9                	j	80004c1c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c40:	4981                	li	s3,0
    80004c42:	b7d1                	j	80004c06 <piperead+0xb4>

0000000080004c44 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c44:	1141                	addi	sp,sp,-16
    80004c46:	e422                	sd	s0,8(sp)
    80004c48:	0800                	addi	s0,sp,16
    80004c4a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c4c:	8905                	andi	a0,a0,1
    80004c4e:	c111                	beqz	a0,80004c52 <flags2perm+0xe>
      perm = PTE_X;
    80004c50:	4521                	li	a0,8
    if(flags & 0x2)
    80004c52:	8b89                	andi	a5,a5,2
    80004c54:	c399                	beqz	a5,80004c5a <flags2perm+0x16>
      perm |= PTE_W;
    80004c56:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c5a:	6422                	ld	s0,8(sp)
    80004c5c:	0141                	addi	sp,sp,16
    80004c5e:	8082                	ret

0000000080004c60 <exec>:

int
exec(char *path, char **argv)
{
    80004c60:	df010113          	addi	sp,sp,-528
    80004c64:	20113423          	sd	ra,520(sp)
    80004c68:	20813023          	sd	s0,512(sp)
    80004c6c:	ffa6                	sd	s1,504(sp)
    80004c6e:	fbca                	sd	s2,496(sp)
    80004c70:	f7ce                	sd	s3,488(sp)
    80004c72:	f3d2                	sd	s4,480(sp)
    80004c74:	efd6                	sd	s5,472(sp)
    80004c76:	ebda                	sd	s6,464(sp)
    80004c78:	e7de                	sd	s7,456(sp)
    80004c7a:	e3e2                	sd	s8,448(sp)
    80004c7c:	ff66                	sd	s9,440(sp)
    80004c7e:	fb6a                	sd	s10,432(sp)
    80004c80:	f76e                	sd	s11,424(sp)
    80004c82:	0c00                	addi	s0,sp,528
    80004c84:	84aa                	mv	s1,a0
    80004c86:	dea43c23          	sd	a0,-520(s0)
    80004c8a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	e24080e7          	jalr	-476(ra) # 80001ab2 <myproc>
    80004c96:	892a                	mv	s2,a0

  begin_op();
    80004c98:	fffff097          	auipc	ra,0xfffff
    80004c9c:	474080e7          	jalr	1140(ra) # 8000410c <begin_op>

  if((ip = namei(path)) == 0){
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	24e080e7          	jalr	590(ra) # 80003ef0 <namei>
    80004caa:	c92d                	beqz	a0,80004d1c <exec+0xbc>
    80004cac:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	a9c080e7          	jalr	-1380(ra) # 8000374a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cb6:	04000713          	li	a4,64
    80004cba:	4681                	li	a3,0
    80004cbc:	e5040613          	addi	a2,s0,-432
    80004cc0:	4581                	li	a1,0
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	d3a080e7          	jalr	-710(ra) # 800039fe <readi>
    80004ccc:	04000793          	li	a5,64
    80004cd0:	00f51a63          	bne	a0,a5,80004ce4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004cd4:	e5042703          	lw	a4,-432(s0)
    80004cd8:	464c47b7          	lui	a5,0x464c4
    80004cdc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ce0:	04f70463          	beq	a4,a5,80004d28 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ce4:	8526                	mv	a0,s1
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	cc6080e7          	jalr	-826(ra) # 800039ac <iunlockput>
    end_op();
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	49e080e7          	jalr	1182(ra) # 8000418c <end_op>
  }
  return -1;
    80004cf6:	557d                	li	a0,-1
}
    80004cf8:	20813083          	ld	ra,520(sp)
    80004cfc:	20013403          	ld	s0,512(sp)
    80004d00:	74fe                	ld	s1,504(sp)
    80004d02:	795e                	ld	s2,496(sp)
    80004d04:	79be                	ld	s3,488(sp)
    80004d06:	7a1e                	ld	s4,480(sp)
    80004d08:	6afe                	ld	s5,472(sp)
    80004d0a:	6b5e                	ld	s6,464(sp)
    80004d0c:	6bbe                	ld	s7,456(sp)
    80004d0e:	6c1e                	ld	s8,448(sp)
    80004d10:	7cfa                	ld	s9,440(sp)
    80004d12:	7d5a                	ld	s10,432(sp)
    80004d14:	7dba                	ld	s11,424(sp)
    80004d16:	21010113          	addi	sp,sp,528
    80004d1a:	8082                	ret
    end_op();
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	470080e7          	jalr	1136(ra) # 8000418c <end_op>
    return -1;
    80004d24:	557d                	li	a0,-1
    80004d26:	bfc9                	j	80004cf8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d28:	854a                	mv	a0,s2
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	e4c080e7          	jalr	-436(ra) # 80001b76 <proc_pagetable>
    80004d32:	8baa                	mv	s7,a0
    80004d34:	d945                	beqz	a0,80004ce4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d36:	e7042983          	lw	s3,-400(s0)
    80004d3a:	e8845783          	lhu	a5,-376(s0)
    80004d3e:	c7ad                	beqz	a5,80004da8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d40:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d42:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d44:	6c85                	lui	s9,0x1
    80004d46:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d4a:	def43823          	sd	a5,-528(s0)
    80004d4e:	ac35                	j	80004f8a <exec+0x32a>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d50:	00004517          	auipc	a0,0x4
    80004d54:	9b050513          	addi	a0,a0,-1616 # 80008700 <syscalls+0x280>
    80004d58:	ffffb097          	auipc	ra,0xffffb
    80004d5c:	7ec080e7          	jalr	2028(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d60:	8756                	mv	a4,s5
    80004d62:	012d86bb          	addw	a3,s11,s2
    80004d66:	4581                	li	a1,0
    80004d68:	8526                	mv	a0,s1
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	c94080e7          	jalr	-876(ra) # 800039fe <readi>
    80004d72:	2501                	sext.w	a0,a0
    80004d74:	1aaa9f63          	bne	s5,a0,80004f32 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d78:	6785                	lui	a5,0x1
    80004d7a:	0127893b          	addw	s2,a5,s2
    80004d7e:	77fd                	lui	a5,0xfffff
    80004d80:	01478a3b          	addw	s4,a5,s4
    80004d84:	1f897a63          	bgeu	s2,s8,80004f78 <exec+0x318>
    pa = walkaddr(pagetable, va + i);
    80004d88:	02091593          	slli	a1,s2,0x20
    80004d8c:	9181                	srli	a1,a1,0x20
    80004d8e:	95ea                	add	a1,a1,s10
    80004d90:	855e                	mv	a0,s7
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	3d2080e7          	jalr	978(ra) # 80001164 <walkaddr>
    80004d9a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d9c:	d955                	beqz	a0,80004d50 <exec+0xf0>
      n = PGSIZE;
    80004d9e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004da0:	fd9a70e3          	bgeu	s4,s9,80004d60 <exec+0x100>
      n = sz - i;
    80004da4:	8ad2                	mv	s5,s4
    80004da6:	bf6d                	j	80004d60 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004da8:	4a01                	li	s4,0
  iunlockput(ip);
    80004daa:	8526                	mv	a0,s1
    80004dac:	fffff097          	auipc	ra,0xfffff
    80004db0:	c00080e7          	jalr	-1024(ra) # 800039ac <iunlockput>
  end_op();
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	3d8080e7          	jalr	984(ra) # 8000418c <end_op>
  p = myproc();
    80004dbc:	ffffd097          	auipc	ra,0xffffd
    80004dc0:	cf6080e7          	jalr	-778(ra) # 80001ab2 <myproc>
    80004dc4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dc6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dca:	6785                	lui	a5,0x1
    80004dcc:	17fd                	addi	a5,a5,-1
    80004dce:	9a3e                	add	s4,s4,a5
    80004dd0:	757d                	lui	a0,0xfffff
    80004dd2:	00aa77b3          	and	a5,s4,a0
    80004dd6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004dda:	4691                	li	a3,4
    80004ddc:	6609                	lui	a2,0x2
    80004dde:	963e                	add	a2,a2,a5
    80004de0:	85be                	mv	a1,a5
    80004de2:	855e                	mv	a0,s7
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	734080e7          	jalr	1844(ra) # 80001518 <uvmalloc>
    80004dec:	8b2a                	mv	s6,a0
  ip = 0;
    80004dee:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004df0:	14050163          	beqz	a0,80004f32 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004df4:	75f9                	lui	a1,0xffffe
    80004df6:	95aa                	add	a1,a1,a0
    80004df8:	855e                	mv	a0,s7
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	944080e7          	jalr	-1724(ra) # 8000173e <uvmclear>
  stackbase = sp - PGSIZE;
    80004e02:	7c7d                	lui	s8,0xfffff
    80004e04:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e06:	e0043783          	ld	a5,-512(s0)
    80004e0a:	6388                	ld	a0,0(a5)
    80004e0c:	c535                	beqz	a0,80004e78 <exec+0x218>
    80004e0e:	e9040993          	addi	s3,s0,-368
    80004e12:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e16:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	052080e7          	jalr	82(ra) # 80000e6a <strlen>
    80004e20:	2505                	addiw	a0,a0,1
    80004e22:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e26:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e2a:	13896b63          	bltu	s2,s8,80004f60 <exec+0x300>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e2e:	e0043d83          	ld	s11,-512(s0)
    80004e32:	000dba03          	ld	s4,0(s11)
    80004e36:	8552                	mv	a0,s4
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	032080e7          	jalr	50(ra) # 80000e6a <strlen>
    80004e40:	0015069b          	addiw	a3,a0,1
    80004e44:	8652                	mv	a2,s4
    80004e46:	85ca                	mv	a1,s2
    80004e48:	855e                	mv	a0,s7
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	926080e7          	jalr	-1754(ra) # 80001770 <copyout>
    80004e52:	10054b63          	bltz	a0,80004f68 <exec+0x308>
    ustack[argc] = sp;
    80004e56:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e5a:	0485                	addi	s1,s1,1
    80004e5c:	008d8793          	addi	a5,s11,8
    80004e60:	e0f43023          	sd	a5,-512(s0)
    80004e64:	008db503          	ld	a0,8(s11)
    80004e68:	c911                	beqz	a0,80004e7c <exec+0x21c>
    if(argc >= MAXARG)
    80004e6a:	09a1                	addi	s3,s3,8
    80004e6c:	fb3c96e3          	bne	s9,s3,80004e18 <exec+0x1b8>
  sz = sz1;
    80004e70:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e74:	4481                	li	s1,0
    80004e76:	a875                	j	80004f32 <exec+0x2d2>
  sp = sz;
    80004e78:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e7a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e7c:	00349793          	slli	a5,s1,0x3
    80004e80:	f9040713          	addi	a4,s0,-112
    80004e84:	97ba                	add	a5,a5,a4
    80004e86:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e8a:	00148693          	addi	a3,s1,1
    80004e8e:	068e                	slli	a3,a3,0x3
    80004e90:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e94:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e98:	01897663          	bgeu	s2,s8,80004ea4 <exec+0x244>
  sz = sz1;
    80004e9c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea0:	4481                	li	s1,0
    80004ea2:	a841                	j	80004f32 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ea4:	e9040613          	addi	a2,s0,-368
    80004ea8:	85ca                	mv	a1,s2
    80004eaa:	855e                	mv	a0,s7
    80004eac:	ffffd097          	auipc	ra,0xffffd
    80004eb0:	8c4080e7          	jalr	-1852(ra) # 80001770 <copyout>
    80004eb4:	0a054e63          	bltz	a0,80004f70 <exec+0x310>
  p->trapframe->a1 = sp;
    80004eb8:	058ab783          	ld	a5,88(s5)
    80004ebc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ec0:	df843783          	ld	a5,-520(s0)
    80004ec4:	0007c703          	lbu	a4,0(a5)
    80004ec8:	cf11                	beqz	a4,80004ee4 <exec+0x284>
    80004eca:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ecc:	02f00693          	li	a3,47
    80004ed0:	a039                	j	80004ede <exec+0x27e>
      last = s+1;
    80004ed2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004ed6:	0785                	addi	a5,a5,1
    80004ed8:	fff7c703          	lbu	a4,-1(a5)
    80004edc:	c701                	beqz	a4,80004ee4 <exec+0x284>
    if(*s == '/')
    80004ede:	fed71ce3          	bne	a4,a3,80004ed6 <exec+0x276>
    80004ee2:	bfc5                	j	80004ed2 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ee4:	4641                	li	a2,16
    80004ee6:	df843583          	ld	a1,-520(s0)
    80004eea:	158a8513          	addi	a0,s5,344
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	f4a080e7          	jalr	-182(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ef6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004efa:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004efe:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f02:	058ab783          	ld	a5,88(s5)
    80004f06:	e6843703          	ld	a4,-408(s0)
    80004f0a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f0c:	058ab783          	ld	a5,88(s5)
    80004f10:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f14:	85ea                	mv	a1,s10
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	cfc080e7          	jalr	-772(ra) # 80001c12 <proc_freepagetable>
vmprint(pagetable);
    80004f1e:	855e                	mv	a0,s7
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	142080e7          	jalr	322(ra) # 80001062 <vmprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f28:	0004851b          	sext.w	a0,s1
    80004f2c:	b3f1                	j	80004cf8 <exec+0x98>
    80004f2e:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f32:	e0843583          	ld	a1,-504(s0)
    80004f36:	855e                	mv	a0,s7
    80004f38:	ffffd097          	auipc	ra,0xffffd
    80004f3c:	cda080e7          	jalr	-806(ra) # 80001c12 <proc_freepagetable>
  if(ip){
    80004f40:	da0492e3          	bnez	s1,80004ce4 <exec+0x84>
  return -1;
    80004f44:	557d                	li	a0,-1
    80004f46:	bb4d                	j	80004cf8 <exec+0x98>
    80004f48:	e1443423          	sd	s4,-504(s0)
    80004f4c:	b7dd                	j	80004f32 <exec+0x2d2>
    80004f4e:	e1443423          	sd	s4,-504(s0)
    80004f52:	b7c5                	j	80004f32 <exec+0x2d2>
    80004f54:	e1443423          	sd	s4,-504(s0)
    80004f58:	bfe9                	j	80004f32 <exec+0x2d2>
    80004f5a:	e1443423          	sd	s4,-504(s0)
    80004f5e:	bfd1                	j	80004f32 <exec+0x2d2>
  sz = sz1;
    80004f60:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f64:	4481                	li	s1,0
    80004f66:	b7f1                	j	80004f32 <exec+0x2d2>
  sz = sz1;
    80004f68:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f6c:	4481                	li	s1,0
    80004f6e:	b7d1                	j	80004f32 <exec+0x2d2>
  sz = sz1;
    80004f70:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f74:	4481                	li	s1,0
    80004f76:	bf75                	j	80004f32 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f78:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f7c:	2b05                	addiw	s6,s6,1
    80004f7e:	0389899b          	addiw	s3,s3,56
    80004f82:	e8845783          	lhu	a5,-376(s0)
    80004f86:	e2fb52e3          	bge	s6,a5,80004daa <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f8a:	2981                	sext.w	s3,s3
    80004f8c:	03800713          	li	a4,56
    80004f90:	86ce                	mv	a3,s3
    80004f92:	e1840613          	addi	a2,s0,-488
    80004f96:	4581                	li	a1,0
    80004f98:	8526                	mv	a0,s1
    80004f9a:	fffff097          	auipc	ra,0xfffff
    80004f9e:	a64080e7          	jalr	-1436(ra) # 800039fe <readi>
    80004fa2:	03800793          	li	a5,56
    80004fa6:	f8f514e3          	bne	a0,a5,80004f2e <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004faa:	e1842783          	lw	a5,-488(s0)
    80004fae:	4705                	li	a4,1
    80004fb0:	fce796e3          	bne	a5,a4,80004f7c <exec+0x31c>
    if(ph.memsz < ph.filesz)
    80004fb4:	e4043903          	ld	s2,-448(s0)
    80004fb8:	e3843783          	ld	a5,-456(s0)
    80004fbc:	f8f966e3          	bltu	s2,a5,80004f48 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fc0:	e2843783          	ld	a5,-472(s0)
    80004fc4:	993e                	add	s2,s2,a5
    80004fc6:	f8f964e3          	bltu	s2,a5,80004f4e <exec+0x2ee>
    if(ph.vaddr % PGSIZE != 0)
    80004fca:	df043703          	ld	a4,-528(s0)
    80004fce:	8ff9                	and	a5,a5,a4
    80004fd0:	f3d1                	bnez	a5,80004f54 <exec+0x2f4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fd2:	e1c42503          	lw	a0,-484(s0)
    80004fd6:	00000097          	auipc	ra,0x0
    80004fda:	c6e080e7          	jalr	-914(ra) # 80004c44 <flags2perm>
    80004fde:	86aa                	mv	a3,a0
    80004fe0:	864a                	mv	a2,s2
    80004fe2:	85d2                	mv	a1,s4
    80004fe4:	855e                	mv	a0,s7
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	532080e7          	jalr	1330(ra) # 80001518 <uvmalloc>
    80004fee:	e0a43423          	sd	a0,-504(s0)
    80004ff2:	d525                	beqz	a0,80004f5a <exec+0x2fa>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ff4:	e2843d03          	ld	s10,-472(s0)
    80004ff8:	e2042d83          	lw	s11,-480(s0)
    80004ffc:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005000:	f60c0ce3          	beqz	s8,80004f78 <exec+0x318>
    80005004:	8a62                	mv	s4,s8
    80005006:	4901                	li	s2,0
    80005008:	b341                	j	80004d88 <exec+0x128>

000000008000500a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000500a:	7179                	addi	sp,sp,-48
    8000500c:	f406                	sd	ra,40(sp)
    8000500e:	f022                	sd	s0,32(sp)
    80005010:	ec26                	sd	s1,24(sp)
    80005012:	e84a                	sd	s2,16(sp)
    80005014:	1800                	addi	s0,sp,48
    80005016:	892e                	mv	s2,a1
    80005018:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000501a:	fdc40593          	addi	a1,s0,-36
    8000501e:	ffffe097          	auipc	ra,0xffffe
    80005022:	ba4080e7          	jalr	-1116(ra) # 80002bc2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005026:	fdc42703          	lw	a4,-36(s0)
    8000502a:	47bd                	li	a5,15
    8000502c:	02e7eb63          	bltu	a5,a4,80005062 <argfd+0x58>
    80005030:	ffffd097          	auipc	ra,0xffffd
    80005034:	a82080e7          	jalr	-1406(ra) # 80001ab2 <myproc>
    80005038:	fdc42703          	lw	a4,-36(s0)
    8000503c:	01a70793          	addi	a5,a4,26
    80005040:	078e                	slli	a5,a5,0x3
    80005042:	953e                	add	a0,a0,a5
    80005044:	611c                	ld	a5,0(a0)
    80005046:	c385                	beqz	a5,80005066 <argfd+0x5c>
    return -1;
  if(pfd)
    80005048:	00090463          	beqz	s2,80005050 <argfd+0x46>
    *pfd = fd;
    8000504c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005050:	4501                	li	a0,0
  if(pf)
    80005052:	c091                	beqz	s1,80005056 <argfd+0x4c>
    *pf = f;
    80005054:	e09c                	sd	a5,0(s1)
}
    80005056:	70a2                	ld	ra,40(sp)
    80005058:	7402                	ld	s0,32(sp)
    8000505a:	64e2                	ld	s1,24(sp)
    8000505c:	6942                	ld	s2,16(sp)
    8000505e:	6145                	addi	sp,sp,48
    80005060:	8082                	ret
    return -1;
    80005062:	557d                	li	a0,-1
    80005064:	bfcd                	j	80005056 <argfd+0x4c>
    80005066:	557d                	li	a0,-1
    80005068:	b7fd                	j	80005056 <argfd+0x4c>

000000008000506a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000506a:	1101                	addi	sp,sp,-32
    8000506c:	ec06                	sd	ra,24(sp)
    8000506e:	e822                	sd	s0,16(sp)
    80005070:	e426                	sd	s1,8(sp)
    80005072:	1000                	addi	s0,sp,32
    80005074:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	a3c080e7          	jalr	-1476(ra) # 80001ab2 <myproc>
    8000507e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005080:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd340>
    80005084:	4501                	li	a0,0
    80005086:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005088:	6398                	ld	a4,0(a5)
    8000508a:	cb19                	beqz	a4,800050a0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000508c:	2505                	addiw	a0,a0,1
    8000508e:	07a1                	addi	a5,a5,8
    80005090:	fed51ce3          	bne	a0,a3,80005088 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005094:	557d                	li	a0,-1
}
    80005096:	60e2                	ld	ra,24(sp)
    80005098:	6442                	ld	s0,16(sp)
    8000509a:	64a2                	ld	s1,8(sp)
    8000509c:	6105                	addi	sp,sp,32
    8000509e:	8082                	ret
      p->ofile[fd] = f;
    800050a0:	01a50793          	addi	a5,a0,26
    800050a4:	078e                	slli	a5,a5,0x3
    800050a6:	963e                	add	a2,a2,a5
    800050a8:	e204                	sd	s1,0(a2)
      return fd;
    800050aa:	b7f5                	j	80005096 <fdalloc+0x2c>

00000000800050ac <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050ac:	715d                	addi	sp,sp,-80
    800050ae:	e486                	sd	ra,72(sp)
    800050b0:	e0a2                	sd	s0,64(sp)
    800050b2:	fc26                	sd	s1,56(sp)
    800050b4:	f84a                	sd	s2,48(sp)
    800050b6:	f44e                	sd	s3,40(sp)
    800050b8:	f052                	sd	s4,32(sp)
    800050ba:	ec56                	sd	s5,24(sp)
    800050bc:	e85a                	sd	s6,16(sp)
    800050be:	0880                	addi	s0,sp,80
    800050c0:	8b2e                	mv	s6,a1
    800050c2:	89b2                	mv	s3,a2
    800050c4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050c6:	fb040593          	addi	a1,s0,-80
    800050ca:	fffff097          	auipc	ra,0xfffff
    800050ce:	e44080e7          	jalr	-444(ra) # 80003f0e <nameiparent>
    800050d2:	84aa                	mv	s1,a0
    800050d4:	16050063          	beqz	a0,80005234 <create+0x188>
    return 0;

  ilock(dp);
    800050d8:	ffffe097          	auipc	ra,0xffffe
    800050dc:	672080e7          	jalr	1650(ra) # 8000374a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050e0:	4601                	li	a2,0
    800050e2:	fb040593          	addi	a1,s0,-80
    800050e6:	8526                	mv	a0,s1
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	b46080e7          	jalr	-1210(ra) # 80003c2e <dirlookup>
    800050f0:	8aaa                	mv	s5,a0
    800050f2:	c931                	beqz	a0,80005146 <create+0x9a>
    iunlockput(dp);
    800050f4:	8526                	mv	a0,s1
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	8b6080e7          	jalr	-1866(ra) # 800039ac <iunlockput>
    ilock(ip);
    800050fe:	8556                	mv	a0,s5
    80005100:	ffffe097          	auipc	ra,0xffffe
    80005104:	64a080e7          	jalr	1610(ra) # 8000374a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005108:	000b059b          	sext.w	a1,s6
    8000510c:	4789                	li	a5,2
    8000510e:	02f59563          	bne	a1,a5,80005138 <create+0x8c>
    80005112:	044ad783          	lhu	a5,68(s5)
    80005116:	37f9                	addiw	a5,a5,-2
    80005118:	17c2                	slli	a5,a5,0x30
    8000511a:	93c1                	srli	a5,a5,0x30
    8000511c:	4705                	li	a4,1
    8000511e:	00f76d63          	bltu	a4,a5,80005138 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005122:	8556                	mv	a0,s5
    80005124:	60a6                	ld	ra,72(sp)
    80005126:	6406                	ld	s0,64(sp)
    80005128:	74e2                	ld	s1,56(sp)
    8000512a:	7942                	ld	s2,48(sp)
    8000512c:	79a2                	ld	s3,40(sp)
    8000512e:	7a02                	ld	s4,32(sp)
    80005130:	6ae2                	ld	s5,24(sp)
    80005132:	6b42                	ld	s6,16(sp)
    80005134:	6161                	addi	sp,sp,80
    80005136:	8082                	ret
    iunlockput(ip);
    80005138:	8556                	mv	a0,s5
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	872080e7          	jalr	-1934(ra) # 800039ac <iunlockput>
    return 0;
    80005142:	4a81                	li	s5,0
    80005144:	bff9                	j	80005122 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005146:	85da                	mv	a1,s6
    80005148:	4088                	lw	a0,0(s1)
    8000514a:	ffffe097          	auipc	ra,0xffffe
    8000514e:	464080e7          	jalr	1124(ra) # 800035ae <ialloc>
    80005152:	8a2a                	mv	s4,a0
    80005154:	c921                	beqz	a0,800051a4 <create+0xf8>
  ilock(ip);
    80005156:	ffffe097          	auipc	ra,0xffffe
    8000515a:	5f4080e7          	jalr	1524(ra) # 8000374a <ilock>
  ip->major = major;
    8000515e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005162:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005166:	4785                	li	a5,1
    80005168:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    8000516c:	8552                	mv	a0,s4
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	512080e7          	jalr	1298(ra) # 80003680 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005176:	000b059b          	sext.w	a1,s6
    8000517a:	4785                	li	a5,1
    8000517c:	02f58b63          	beq	a1,a5,800051b2 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005180:	004a2603          	lw	a2,4(s4)
    80005184:	fb040593          	addi	a1,s0,-80
    80005188:	8526                	mv	a0,s1
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	cb4080e7          	jalr	-844(ra) # 80003e3e <dirlink>
    80005192:	06054f63          	bltz	a0,80005210 <create+0x164>
  iunlockput(dp);
    80005196:	8526                	mv	a0,s1
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	814080e7          	jalr	-2028(ra) # 800039ac <iunlockput>
  return ip;
    800051a0:	8ad2                	mv	s5,s4
    800051a2:	b741                	j	80005122 <create+0x76>
    iunlockput(dp);
    800051a4:	8526                	mv	a0,s1
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	806080e7          	jalr	-2042(ra) # 800039ac <iunlockput>
    return 0;
    800051ae:	8ad2                	mv	s5,s4
    800051b0:	bf8d                	j	80005122 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051b2:	004a2603          	lw	a2,4(s4)
    800051b6:	00003597          	auipc	a1,0x3
    800051ba:	56a58593          	addi	a1,a1,1386 # 80008720 <syscalls+0x2a0>
    800051be:	8552                	mv	a0,s4
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	c7e080e7          	jalr	-898(ra) # 80003e3e <dirlink>
    800051c8:	04054463          	bltz	a0,80005210 <create+0x164>
    800051cc:	40d0                	lw	a2,4(s1)
    800051ce:	00003597          	auipc	a1,0x3
    800051d2:	55a58593          	addi	a1,a1,1370 # 80008728 <syscalls+0x2a8>
    800051d6:	8552                	mv	a0,s4
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	c66080e7          	jalr	-922(ra) # 80003e3e <dirlink>
    800051e0:	02054863          	bltz	a0,80005210 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800051e4:	004a2603          	lw	a2,4(s4)
    800051e8:	fb040593          	addi	a1,s0,-80
    800051ec:	8526                	mv	a0,s1
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	c50080e7          	jalr	-944(ra) # 80003e3e <dirlink>
    800051f6:	00054d63          	bltz	a0,80005210 <create+0x164>
    dp->nlink++;  // for ".."
    800051fa:	04a4d783          	lhu	a5,74(s1)
    800051fe:	2785                	addiw	a5,a5,1
    80005200:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005204:	8526                	mv	a0,s1
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	47a080e7          	jalr	1146(ra) # 80003680 <iupdate>
    8000520e:	b761                	j	80005196 <create+0xea>
  ip->nlink = 0;
    80005210:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005214:	8552                	mv	a0,s4
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	46a080e7          	jalr	1130(ra) # 80003680 <iupdate>
  iunlockput(ip);
    8000521e:	8552                	mv	a0,s4
    80005220:	ffffe097          	auipc	ra,0xffffe
    80005224:	78c080e7          	jalr	1932(ra) # 800039ac <iunlockput>
  iunlockput(dp);
    80005228:	8526                	mv	a0,s1
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	782080e7          	jalr	1922(ra) # 800039ac <iunlockput>
  return 0;
    80005232:	bdc5                	j	80005122 <create+0x76>
    return 0;
    80005234:	8aaa                	mv	s5,a0
    80005236:	b5f5                	j	80005122 <create+0x76>

0000000080005238 <sys_dup>:
{
    80005238:	7179                	addi	sp,sp,-48
    8000523a:	f406                	sd	ra,40(sp)
    8000523c:	f022                	sd	s0,32(sp)
    8000523e:	ec26                	sd	s1,24(sp)
    80005240:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005242:	fd840613          	addi	a2,s0,-40
    80005246:	4581                	li	a1,0
    80005248:	4501                	li	a0,0
    8000524a:	00000097          	auipc	ra,0x0
    8000524e:	dc0080e7          	jalr	-576(ra) # 8000500a <argfd>
    return -1;
    80005252:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005254:	02054363          	bltz	a0,8000527a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005258:	fd843503          	ld	a0,-40(s0)
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	e0e080e7          	jalr	-498(ra) # 8000506a <fdalloc>
    80005264:	84aa                	mv	s1,a0
    return -1;
    80005266:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005268:	00054963          	bltz	a0,8000527a <sys_dup+0x42>
  filedup(f);
    8000526c:	fd843503          	ld	a0,-40(s0)
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	316080e7          	jalr	790(ra) # 80004586 <filedup>
  return fd;
    80005278:	87a6                	mv	a5,s1
}
    8000527a:	853e                	mv	a0,a5
    8000527c:	70a2                	ld	ra,40(sp)
    8000527e:	7402                	ld	s0,32(sp)
    80005280:	64e2                	ld	s1,24(sp)
    80005282:	6145                	addi	sp,sp,48
    80005284:	8082                	ret

0000000080005286 <sys_read>:
{
    80005286:	7179                	addi	sp,sp,-48
    80005288:	f406                	sd	ra,40(sp)
    8000528a:	f022                	sd	s0,32(sp)
    8000528c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000528e:	fd840593          	addi	a1,s0,-40
    80005292:	4505                	li	a0,1
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	94e080e7          	jalr	-1714(ra) # 80002be2 <argaddr>
  argint(2, &n);
    8000529c:	fe440593          	addi	a1,s0,-28
    800052a0:	4509                	li	a0,2
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	920080e7          	jalr	-1760(ra) # 80002bc2 <argint>
  if(argfd(0, 0, &f) < 0)
    800052aa:	fe840613          	addi	a2,s0,-24
    800052ae:	4581                	li	a1,0
    800052b0:	4501                	li	a0,0
    800052b2:	00000097          	auipc	ra,0x0
    800052b6:	d58080e7          	jalr	-680(ra) # 8000500a <argfd>
    800052ba:	87aa                	mv	a5,a0
    return -1;
    800052bc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052be:	0007cc63          	bltz	a5,800052d6 <sys_read+0x50>
  return fileread(f, p, n);
    800052c2:	fe442603          	lw	a2,-28(s0)
    800052c6:	fd843583          	ld	a1,-40(s0)
    800052ca:	fe843503          	ld	a0,-24(s0)
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	444080e7          	jalr	1092(ra) # 80004712 <fileread>
}
    800052d6:	70a2                	ld	ra,40(sp)
    800052d8:	7402                	ld	s0,32(sp)
    800052da:	6145                	addi	sp,sp,48
    800052dc:	8082                	ret

00000000800052de <sys_write>:
{
    800052de:	7179                	addi	sp,sp,-48
    800052e0:	f406                	sd	ra,40(sp)
    800052e2:	f022                	sd	s0,32(sp)
    800052e4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052e6:	fd840593          	addi	a1,s0,-40
    800052ea:	4505                	li	a0,1
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	8f6080e7          	jalr	-1802(ra) # 80002be2 <argaddr>
  argint(2, &n);
    800052f4:	fe440593          	addi	a1,s0,-28
    800052f8:	4509                	li	a0,2
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	8c8080e7          	jalr	-1848(ra) # 80002bc2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005302:	fe840613          	addi	a2,s0,-24
    80005306:	4581                	li	a1,0
    80005308:	4501                	li	a0,0
    8000530a:	00000097          	auipc	ra,0x0
    8000530e:	d00080e7          	jalr	-768(ra) # 8000500a <argfd>
    80005312:	87aa                	mv	a5,a0
    return -1;
    80005314:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005316:	0007cc63          	bltz	a5,8000532e <sys_write+0x50>
  return filewrite(f, p, n);
    8000531a:	fe442603          	lw	a2,-28(s0)
    8000531e:	fd843583          	ld	a1,-40(s0)
    80005322:	fe843503          	ld	a0,-24(s0)
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	4ae080e7          	jalr	1198(ra) # 800047d4 <filewrite>
}
    8000532e:	70a2                	ld	ra,40(sp)
    80005330:	7402                	ld	s0,32(sp)
    80005332:	6145                	addi	sp,sp,48
    80005334:	8082                	ret

0000000080005336 <sys_close>:
{
    80005336:	1101                	addi	sp,sp,-32
    80005338:	ec06                	sd	ra,24(sp)
    8000533a:	e822                	sd	s0,16(sp)
    8000533c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000533e:	fe040613          	addi	a2,s0,-32
    80005342:	fec40593          	addi	a1,s0,-20
    80005346:	4501                	li	a0,0
    80005348:	00000097          	auipc	ra,0x0
    8000534c:	cc2080e7          	jalr	-830(ra) # 8000500a <argfd>
    return -1;
    80005350:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005352:	02054463          	bltz	a0,8000537a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005356:	ffffc097          	auipc	ra,0xffffc
    8000535a:	75c080e7          	jalr	1884(ra) # 80001ab2 <myproc>
    8000535e:	fec42783          	lw	a5,-20(s0)
    80005362:	07e9                	addi	a5,a5,26
    80005364:	078e                	slli	a5,a5,0x3
    80005366:	97aa                	add	a5,a5,a0
    80005368:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000536c:	fe043503          	ld	a0,-32(s0)
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	268080e7          	jalr	616(ra) # 800045d8 <fileclose>
  return 0;
    80005378:	4781                	li	a5,0
}
    8000537a:	853e                	mv	a0,a5
    8000537c:	60e2                	ld	ra,24(sp)
    8000537e:	6442                	ld	s0,16(sp)
    80005380:	6105                	addi	sp,sp,32
    80005382:	8082                	ret

0000000080005384 <sys_fstat>:
{
    80005384:	1101                	addi	sp,sp,-32
    80005386:	ec06                	sd	ra,24(sp)
    80005388:	e822                	sd	s0,16(sp)
    8000538a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000538c:	fe040593          	addi	a1,s0,-32
    80005390:	4505                	li	a0,1
    80005392:	ffffe097          	auipc	ra,0xffffe
    80005396:	850080e7          	jalr	-1968(ra) # 80002be2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000539a:	fe840613          	addi	a2,s0,-24
    8000539e:	4581                	li	a1,0
    800053a0:	4501                	li	a0,0
    800053a2:	00000097          	auipc	ra,0x0
    800053a6:	c68080e7          	jalr	-920(ra) # 8000500a <argfd>
    800053aa:	87aa                	mv	a5,a0
    return -1;
    800053ac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053ae:	0007ca63          	bltz	a5,800053c2 <sys_fstat+0x3e>
  return filestat(f, st);
    800053b2:	fe043583          	ld	a1,-32(s0)
    800053b6:	fe843503          	ld	a0,-24(s0)
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	2e6080e7          	jalr	742(ra) # 800046a0 <filestat>
}
    800053c2:	60e2                	ld	ra,24(sp)
    800053c4:	6442                	ld	s0,16(sp)
    800053c6:	6105                	addi	sp,sp,32
    800053c8:	8082                	ret

00000000800053ca <sys_link>:
{
    800053ca:	7169                	addi	sp,sp,-304
    800053cc:	f606                	sd	ra,296(sp)
    800053ce:	f222                	sd	s0,288(sp)
    800053d0:	ee26                	sd	s1,280(sp)
    800053d2:	ea4a                	sd	s2,272(sp)
    800053d4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d6:	08000613          	li	a2,128
    800053da:	ed040593          	addi	a1,s0,-304
    800053de:	4501                	li	a0,0
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	822080e7          	jalr	-2014(ra) # 80002c02 <argstr>
    return -1;
    800053e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ea:	10054e63          	bltz	a0,80005506 <sys_link+0x13c>
    800053ee:	08000613          	li	a2,128
    800053f2:	f5040593          	addi	a1,s0,-176
    800053f6:	4505                	li	a0,1
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	80a080e7          	jalr	-2038(ra) # 80002c02 <argstr>
    return -1;
    80005400:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005402:	10054263          	bltz	a0,80005506 <sys_link+0x13c>
  begin_op();
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	d06080e7          	jalr	-762(ra) # 8000410c <begin_op>
  if((ip = namei(old)) == 0){
    8000540e:	ed040513          	addi	a0,s0,-304
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	ade080e7          	jalr	-1314(ra) # 80003ef0 <namei>
    8000541a:	84aa                	mv	s1,a0
    8000541c:	c551                	beqz	a0,800054a8 <sys_link+0xde>
  ilock(ip);
    8000541e:	ffffe097          	auipc	ra,0xffffe
    80005422:	32c080e7          	jalr	812(ra) # 8000374a <ilock>
  if(ip->type == T_DIR){
    80005426:	04449703          	lh	a4,68(s1)
    8000542a:	4785                	li	a5,1
    8000542c:	08f70463          	beq	a4,a5,800054b4 <sys_link+0xea>
  ip->nlink++;
    80005430:	04a4d783          	lhu	a5,74(s1)
    80005434:	2785                	addiw	a5,a5,1
    80005436:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	244080e7          	jalr	580(ra) # 80003680 <iupdate>
  iunlock(ip);
    80005444:	8526                	mv	a0,s1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	3c6080e7          	jalr	966(ra) # 8000380c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000544e:	fd040593          	addi	a1,s0,-48
    80005452:	f5040513          	addi	a0,s0,-176
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	ab8080e7          	jalr	-1352(ra) # 80003f0e <nameiparent>
    8000545e:	892a                	mv	s2,a0
    80005460:	c935                	beqz	a0,800054d4 <sys_link+0x10a>
  ilock(dp);
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	2e8080e7          	jalr	744(ra) # 8000374a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000546a:	00092703          	lw	a4,0(s2)
    8000546e:	409c                	lw	a5,0(s1)
    80005470:	04f71d63          	bne	a4,a5,800054ca <sys_link+0x100>
    80005474:	40d0                	lw	a2,4(s1)
    80005476:	fd040593          	addi	a1,s0,-48
    8000547a:	854a                	mv	a0,s2
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	9c2080e7          	jalr	-1598(ra) # 80003e3e <dirlink>
    80005484:	04054363          	bltz	a0,800054ca <sys_link+0x100>
  iunlockput(dp);
    80005488:	854a                	mv	a0,s2
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	522080e7          	jalr	1314(ra) # 800039ac <iunlockput>
  iput(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	470080e7          	jalr	1136(ra) # 80003904 <iput>
  end_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	cf0080e7          	jalr	-784(ra) # 8000418c <end_op>
  return 0;
    800054a4:	4781                	li	a5,0
    800054a6:	a085                	j	80005506 <sys_link+0x13c>
    end_op();
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	ce4080e7          	jalr	-796(ra) # 8000418c <end_op>
    return -1;
    800054b0:	57fd                	li	a5,-1
    800054b2:	a891                	j	80005506 <sys_link+0x13c>
    iunlockput(ip);
    800054b4:	8526                	mv	a0,s1
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	4f6080e7          	jalr	1270(ra) # 800039ac <iunlockput>
    end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	cce080e7          	jalr	-818(ra) # 8000418c <end_op>
    return -1;
    800054c6:	57fd                	li	a5,-1
    800054c8:	a83d                	j	80005506 <sys_link+0x13c>
    iunlockput(dp);
    800054ca:	854a                	mv	a0,s2
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	4e0080e7          	jalr	1248(ra) # 800039ac <iunlockput>
  ilock(ip);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	274080e7          	jalr	628(ra) # 8000374a <ilock>
  ip->nlink--;
    800054de:	04a4d783          	lhu	a5,74(s1)
    800054e2:	37fd                	addiw	a5,a5,-1
    800054e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	196080e7          	jalr	406(ra) # 80003680 <iupdate>
  iunlockput(ip);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	4b8080e7          	jalr	1208(ra) # 800039ac <iunlockput>
  end_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	c90080e7          	jalr	-880(ra) # 8000418c <end_op>
  return -1;
    80005504:	57fd                	li	a5,-1
}
    80005506:	853e                	mv	a0,a5
    80005508:	70b2                	ld	ra,296(sp)
    8000550a:	7412                	ld	s0,288(sp)
    8000550c:	64f2                	ld	s1,280(sp)
    8000550e:	6952                	ld	s2,272(sp)
    80005510:	6155                	addi	sp,sp,304
    80005512:	8082                	ret

0000000080005514 <sys_unlink>:
{
    80005514:	7151                	addi	sp,sp,-240
    80005516:	f586                	sd	ra,232(sp)
    80005518:	f1a2                	sd	s0,224(sp)
    8000551a:	eda6                	sd	s1,216(sp)
    8000551c:	e9ca                	sd	s2,208(sp)
    8000551e:	e5ce                	sd	s3,200(sp)
    80005520:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005522:	08000613          	li	a2,128
    80005526:	f3040593          	addi	a1,s0,-208
    8000552a:	4501                	li	a0,0
    8000552c:	ffffd097          	auipc	ra,0xffffd
    80005530:	6d6080e7          	jalr	1750(ra) # 80002c02 <argstr>
    80005534:	18054163          	bltz	a0,800056b6 <sys_unlink+0x1a2>
  begin_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	bd4080e7          	jalr	-1068(ra) # 8000410c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005540:	fb040593          	addi	a1,s0,-80
    80005544:	f3040513          	addi	a0,s0,-208
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	9c6080e7          	jalr	-1594(ra) # 80003f0e <nameiparent>
    80005550:	84aa                	mv	s1,a0
    80005552:	c979                	beqz	a0,80005628 <sys_unlink+0x114>
  ilock(dp);
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	1f6080e7          	jalr	502(ra) # 8000374a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000555c:	00003597          	auipc	a1,0x3
    80005560:	1c458593          	addi	a1,a1,452 # 80008720 <syscalls+0x2a0>
    80005564:	fb040513          	addi	a0,s0,-80
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	6ac080e7          	jalr	1708(ra) # 80003c14 <namecmp>
    80005570:	14050a63          	beqz	a0,800056c4 <sys_unlink+0x1b0>
    80005574:	00003597          	auipc	a1,0x3
    80005578:	1b458593          	addi	a1,a1,436 # 80008728 <syscalls+0x2a8>
    8000557c:	fb040513          	addi	a0,s0,-80
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	694080e7          	jalr	1684(ra) # 80003c14 <namecmp>
    80005588:	12050e63          	beqz	a0,800056c4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000558c:	f2c40613          	addi	a2,s0,-212
    80005590:	fb040593          	addi	a1,s0,-80
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	698080e7          	jalr	1688(ra) # 80003c2e <dirlookup>
    8000559e:	892a                	mv	s2,a0
    800055a0:	12050263          	beqz	a0,800056c4 <sys_unlink+0x1b0>
  ilock(ip);
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	1a6080e7          	jalr	422(ra) # 8000374a <ilock>
  if(ip->nlink < 1)
    800055ac:	04a91783          	lh	a5,74(s2)
    800055b0:	08f05263          	blez	a5,80005634 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055b4:	04491703          	lh	a4,68(s2)
    800055b8:	4785                	li	a5,1
    800055ba:	08f70563          	beq	a4,a5,80005644 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055be:	4641                	li	a2,16
    800055c0:	4581                	li	a1,0
    800055c2:	fc040513          	addi	a0,s0,-64
    800055c6:	ffffb097          	auipc	ra,0xffffb
    800055ca:	720080e7          	jalr	1824(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ce:	4741                	li	a4,16
    800055d0:	f2c42683          	lw	a3,-212(s0)
    800055d4:	fc040613          	addi	a2,s0,-64
    800055d8:	4581                	li	a1,0
    800055da:	8526                	mv	a0,s1
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	51a080e7          	jalr	1306(ra) # 80003af6 <writei>
    800055e4:	47c1                	li	a5,16
    800055e6:	0af51563          	bne	a0,a5,80005690 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055ea:	04491703          	lh	a4,68(s2)
    800055ee:	4785                	li	a5,1
    800055f0:	0af70863          	beq	a4,a5,800056a0 <sys_unlink+0x18c>
  iunlockput(dp);
    800055f4:	8526                	mv	a0,s1
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	3b6080e7          	jalr	950(ra) # 800039ac <iunlockput>
  ip->nlink--;
    800055fe:	04a95783          	lhu	a5,74(s2)
    80005602:	37fd                	addiw	a5,a5,-1
    80005604:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005608:	854a                	mv	a0,s2
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	076080e7          	jalr	118(ra) # 80003680 <iupdate>
  iunlockput(ip);
    80005612:	854a                	mv	a0,s2
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	398080e7          	jalr	920(ra) # 800039ac <iunlockput>
  end_op();
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	b70080e7          	jalr	-1168(ra) # 8000418c <end_op>
  return 0;
    80005624:	4501                	li	a0,0
    80005626:	a84d                	j	800056d8 <sys_unlink+0x1c4>
    end_op();
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	b64080e7          	jalr	-1180(ra) # 8000418c <end_op>
    return -1;
    80005630:	557d                	li	a0,-1
    80005632:	a05d                	j	800056d8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005634:	00003517          	auipc	a0,0x3
    80005638:	0fc50513          	addi	a0,a0,252 # 80008730 <syscalls+0x2b0>
    8000563c:	ffffb097          	auipc	ra,0xffffb
    80005640:	f08080e7          	jalr	-248(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005644:	04c92703          	lw	a4,76(s2)
    80005648:	02000793          	li	a5,32
    8000564c:	f6e7f9e3          	bgeu	a5,a4,800055be <sys_unlink+0xaa>
    80005650:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005654:	4741                	li	a4,16
    80005656:	86ce                	mv	a3,s3
    80005658:	f1840613          	addi	a2,s0,-232
    8000565c:	4581                	li	a1,0
    8000565e:	854a                	mv	a0,s2
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	39e080e7          	jalr	926(ra) # 800039fe <readi>
    80005668:	47c1                	li	a5,16
    8000566a:	00f51b63          	bne	a0,a5,80005680 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000566e:	f1845783          	lhu	a5,-232(s0)
    80005672:	e7a1                	bnez	a5,800056ba <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005674:	29c1                	addiw	s3,s3,16
    80005676:	04c92783          	lw	a5,76(s2)
    8000567a:	fcf9ede3          	bltu	s3,a5,80005654 <sys_unlink+0x140>
    8000567e:	b781                	j	800055be <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005680:	00003517          	auipc	a0,0x3
    80005684:	0c850513          	addi	a0,a0,200 # 80008748 <syscalls+0x2c8>
    80005688:	ffffb097          	auipc	ra,0xffffb
    8000568c:	ebc080e7          	jalr	-324(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005690:	00003517          	auipc	a0,0x3
    80005694:	0d050513          	addi	a0,a0,208 # 80008760 <syscalls+0x2e0>
    80005698:	ffffb097          	auipc	ra,0xffffb
    8000569c:	eac080e7          	jalr	-340(ra) # 80000544 <panic>
    dp->nlink--;
    800056a0:	04a4d783          	lhu	a5,74(s1)
    800056a4:	37fd                	addiw	a5,a5,-1
    800056a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	fd4080e7          	jalr	-44(ra) # 80003680 <iupdate>
    800056b4:	b781                	j	800055f4 <sys_unlink+0xe0>
    return -1;
    800056b6:	557d                	li	a0,-1
    800056b8:	a005                	j	800056d8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056ba:	854a                	mv	a0,s2
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	2f0080e7          	jalr	752(ra) # 800039ac <iunlockput>
  iunlockput(dp);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	2e6080e7          	jalr	742(ra) # 800039ac <iunlockput>
  end_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	abe080e7          	jalr	-1346(ra) # 8000418c <end_op>
  return -1;
    800056d6:	557d                	li	a0,-1
}
    800056d8:	70ae                	ld	ra,232(sp)
    800056da:	740e                	ld	s0,224(sp)
    800056dc:	64ee                	ld	s1,216(sp)
    800056de:	694e                	ld	s2,208(sp)
    800056e0:	69ae                	ld	s3,200(sp)
    800056e2:	616d                	addi	sp,sp,240
    800056e4:	8082                	ret

00000000800056e6 <sys_open>:

uint64
sys_open(void)
{
    800056e6:	7131                	addi	sp,sp,-192
    800056e8:	fd06                	sd	ra,184(sp)
    800056ea:	f922                	sd	s0,176(sp)
    800056ec:	f526                	sd	s1,168(sp)
    800056ee:	f14a                	sd	s2,160(sp)
    800056f0:	ed4e                	sd	s3,152(sp)
    800056f2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800056f4:	f4c40593          	addi	a1,s0,-180
    800056f8:	4505                	li	a0,1
    800056fa:	ffffd097          	auipc	ra,0xffffd
    800056fe:	4c8080e7          	jalr	1224(ra) # 80002bc2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005702:	08000613          	li	a2,128
    80005706:	f5040593          	addi	a1,s0,-176
    8000570a:	4501                	li	a0,0
    8000570c:	ffffd097          	auipc	ra,0xffffd
    80005710:	4f6080e7          	jalr	1270(ra) # 80002c02 <argstr>
    80005714:	87aa                	mv	a5,a0
    return -1;
    80005716:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005718:	0a07c963          	bltz	a5,800057ca <sys_open+0xe4>

  begin_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	9f0080e7          	jalr	-1552(ra) # 8000410c <begin_op>

  if(omode & O_CREATE){
    80005724:	f4c42783          	lw	a5,-180(s0)
    80005728:	2007f793          	andi	a5,a5,512
    8000572c:	cfc5                	beqz	a5,800057e4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000572e:	4681                	li	a3,0
    80005730:	4601                	li	a2,0
    80005732:	4589                	li	a1,2
    80005734:	f5040513          	addi	a0,s0,-176
    80005738:	00000097          	auipc	ra,0x0
    8000573c:	974080e7          	jalr	-1676(ra) # 800050ac <create>
    80005740:	84aa                	mv	s1,a0
    if(ip == 0){
    80005742:	c959                	beqz	a0,800057d8 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005744:	04449703          	lh	a4,68(s1)
    80005748:	478d                	li	a5,3
    8000574a:	00f71763          	bne	a4,a5,80005758 <sys_open+0x72>
    8000574e:	0464d703          	lhu	a4,70(s1)
    80005752:	47a5                	li	a5,9
    80005754:	0ce7ed63          	bltu	a5,a4,8000582e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005758:	fffff097          	auipc	ra,0xfffff
    8000575c:	dc4080e7          	jalr	-572(ra) # 8000451c <filealloc>
    80005760:	89aa                	mv	s3,a0
    80005762:	10050363          	beqz	a0,80005868 <sys_open+0x182>
    80005766:	00000097          	auipc	ra,0x0
    8000576a:	904080e7          	jalr	-1788(ra) # 8000506a <fdalloc>
    8000576e:	892a                	mv	s2,a0
    80005770:	0e054763          	bltz	a0,8000585e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005774:	04449703          	lh	a4,68(s1)
    80005778:	478d                	li	a5,3
    8000577a:	0cf70563          	beq	a4,a5,80005844 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000577e:	4789                	li	a5,2
    80005780:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005784:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005788:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000578c:	f4c42783          	lw	a5,-180(s0)
    80005790:	0017c713          	xori	a4,a5,1
    80005794:	8b05                	andi	a4,a4,1
    80005796:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000579a:	0037f713          	andi	a4,a5,3
    8000579e:	00e03733          	snez	a4,a4
    800057a2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057a6:	4007f793          	andi	a5,a5,1024
    800057aa:	c791                	beqz	a5,800057b6 <sys_open+0xd0>
    800057ac:	04449703          	lh	a4,68(s1)
    800057b0:	4789                	li	a5,2
    800057b2:	0af70063          	beq	a4,a5,80005852 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	054080e7          	jalr	84(ra) # 8000380c <iunlock>
  end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	9cc080e7          	jalr	-1588(ra) # 8000418c <end_op>

  return fd;
    800057c8:	854a                	mv	a0,s2
}
    800057ca:	70ea                	ld	ra,184(sp)
    800057cc:	744a                	ld	s0,176(sp)
    800057ce:	74aa                	ld	s1,168(sp)
    800057d0:	790a                	ld	s2,160(sp)
    800057d2:	69ea                	ld	s3,152(sp)
    800057d4:	6129                	addi	sp,sp,192
    800057d6:	8082                	ret
      end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	9b4080e7          	jalr	-1612(ra) # 8000418c <end_op>
      return -1;
    800057e0:	557d                	li	a0,-1
    800057e2:	b7e5                	j	800057ca <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057e4:	f5040513          	addi	a0,s0,-176
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	708080e7          	jalr	1800(ra) # 80003ef0 <namei>
    800057f0:	84aa                	mv	s1,a0
    800057f2:	c905                	beqz	a0,80005822 <sys_open+0x13c>
    ilock(ip);
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	f56080e7          	jalr	-170(ra) # 8000374a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057fc:	04449703          	lh	a4,68(s1)
    80005800:	4785                	li	a5,1
    80005802:	f4f711e3          	bne	a4,a5,80005744 <sys_open+0x5e>
    80005806:	f4c42783          	lw	a5,-180(s0)
    8000580a:	d7b9                	beqz	a5,80005758 <sys_open+0x72>
      iunlockput(ip);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	19e080e7          	jalr	414(ra) # 800039ac <iunlockput>
      end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	976080e7          	jalr	-1674(ra) # 8000418c <end_op>
      return -1;
    8000581e:	557d                	li	a0,-1
    80005820:	b76d                	j	800057ca <sys_open+0xe4>
      end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	96a080e7          	jalr	-1686(ra) # 8000418c <end_op>
      return -1;
    8000582a:	557d                	li	a0,-1
    8000582c:	bf79                	j	800057ca <sys_open+0xe4>
    iunlockput(ip);
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	17c080e7          	jalr	380(ra) # 800039ac <iunlockput>
    end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	954080e7          	jalr	-1708(ra) # 8000418c <end_op>
    return -1;
    80005840:	557d                	li	a0,-1
    80005842:	b761                	j	800057ca <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005844:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005848:	04649783          	lh	a5,70(s1)
    8000584c:	02f99223          	sh	a5,36(s3)
    80005850:	bf25                	j	80005788 <sys_open+0xa2>
    itrunc(ip);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	004080e7          	jalr	4(ra) # 80003858 <itrunc>
    8000585c:	bfa9                	j	800057b6 <sys_open+0xd0>
      fileclose(f);
    8000585e:	854e                	mv	a0,s3
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	d78080e7          	jalr	-648(ra) # 800045d8 <fileclose>
    iunlockput(ip);
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	142080e7          	jalr	322(ra) # 800039ac <iunlockput>
    end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	91a080e7          	jalr	-1766(ra) # 8000418c <end_op>
    return -1;
    8000587a:	557d                	li	a0,-1
    8000587c:	b7b9                	j	800057ca <sys_open+0xe4>

000000008000587e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000587e:	7175                	addi	sp,sp,-144
    80005880:	e506                	sd	ra,136(sp)
    80005882:	e122                	sd	s0,128(sp)
    80005884:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	886080e7          	jalr	-1914(ra) # 8000410c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000588e:	08000613          	li	a2,128
    80005892:	f7040593          	addi	a1,s0,-144
    80005896:	4501                	li	a0,0
    80005898:	ffffd097          	auipc	ra,0xffffd
    8000589c:	36a080e7          	jalr	874(ra) # 80002c02 <argstr>
    800058a0:	02054963          	bltz	a0,800058d2 <sys_mkdir+0x54>
    800058a4:	4681                	li	a3,0
    800058a6:	4601                	li	a2,0
    800058a8:	4585                	li	a1,1
    800058aa:	f7040513          	addi	a0,s0,-144
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	7fe080e7          	jalr	2046(ra) # 800050ac <create>
    800058b6:	cd11                	beqz	a0,800058d2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	0f4080e7          	jalr	244(ra) # 800039ac <iunlockput>
  end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	8cc080e7          	jalr	-1844(ra) # 8000418c <end_op>
  return 0;
    800058c8:	4501                	li	a0,0
}
    800058ca:	60aa                	ld	ra,136(sp)
    800058cc:	640a                	ld	s0,128(sp)
    800058ce:	6149                	addi	sp,sp,144
    800058d0:	8082                	ret
    end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	8ba080e7          	jalr	-1862(ra) # 8000418c <end_op>
    return -1;
    800058da:	557d                	li	a0,-1
    800058dc:	b7fd                	j	800058ca <sys_mkdir+0x4c>

00000000800058de <sys_mknod>:

uint64
sys_mknod(void)
{
    800058de:	7135                	addi	sp,sp,-160
    800058e0:	ed06                	sd	ra,152(sp)
    800058e2:	e922                	sd	s0,144(sp)
    800058e4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	826080e7          	jalr	-2010(ra) # 8000410c <begin_op>
  argint(1, &major);
    800058ee:	f6c40593          	addi	a1,s0,-148
    800058f2:	4505                	li	a0,1
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	2ce080e7          	jalr	718(ra) # 80002bc2 <argint>
  argint(2, &minor);
    800058fc:	f6840593          	addi	a1,s0,-152
    80005900:	4509                	li	a0,2
    80005902:	ffffd097          	auipc	ra,0xffffd
    80005906:	2c0080e7          	jalr	704(ra) # 80002bc2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000590a:	08000613          	li	a2,128
    8000590e:	f7040593          	addi	a1,s0,-144
    80005912:	4501                	li	a0,0
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	2ee080e7          	jalr	750(ra) # 80002c02 <argstr>
    8000591c:	02054b63          	bltz	a0,80005952 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005920:	f6841683          	lh	a3,-152(s0)
    80005924:	f6c41603          	lh	a2,-148(s0)
    80005928:	458d                	li	a1,3
    8000592a:	f7040513          	addi	a0,s0,-144
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	77e080e7          	jalr	1918(ra) # 800050ac <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005936:	cd11                	beqz	a0,80005952 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	074080e7          	jalr	116(ra) # 800039ac <iunlockput>
  end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	84c080e7          	jalr	-1972(ra) # 8000418c <end_op>
  return 0;
    80005948:	4501                	li	a0,0
}
    8000594a:	60ea                	ld	ra,152(sp)
    8000594c:	644a                	ld	s0,144(sp)
    8000594e:	610d                	addi	sp,sp,160
    80005950:	8082                	ret
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	83a080e7          	jalr	-1990(ra) # 8000418c <end_op>
    return -1;
    8000595a:	557d                	li	a0,-1
    8000595c:	b7fd                	j	8000594a <sys_mknod+0x6c>

000000008000595e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000595e:	7135                	addi	sp,sp,-160
    80005960:	ed06                	sd	ra,152(sp)
    80005962:	e922                	sd	s0,144(sp)
    80005964:	e526                	sd	s1,136(sp)
    80005966:	e14a                	sd	s2,128(sp)
    80005968:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000596a:	ffffc097          	auipc	ra,0xffffc
    8000596e:	148080e7          	jalr	328(ra) # 80001ab2 <myproc>
    80005972:	892a                	mv	s2,a0
  
  begin_op();
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	798080e7          	jalr	1944(ra) # 8000410c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000597c:	08000613          	li	a2,128
    80005980:	f6040593          	addi	a1,s0,-160
    80005984:	4501                	li	a0,0
    80005986:	ffffd097          	auipc	ra,0xffffd
    8000598a:	27c080e7          	jalr	636(ra) # 80002c02 <argstr>
    8000598e:	04054b63          	bltz	a0,800059e4 <sys_chdir+0x86>
    80005992:	f6040513          	addi	a0,s0,-160
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	55a080e7          	jalr	1370(ra) # 80003ef0 <namei>
    8000599e:	84aa                	mv	s1,a0
    800059a0:	c131                	beqz	a0,800059e4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	da8080e7          	jalr	-600(ra) # 8000374a <ilock>
  if(ip->type != T_DIR){
    800059aa:	04449703          	lh	a4,68(s1)
    800059ae:	4785                	li	a5,1
    800059b0:	04f71063          	bne	a4,a5,800059f0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059b4:	8526                	mv	a0,s1
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	e56080e7          	jalr	-426(ra) # 8000380c <iunlock>
  iput(p->cwd);
    800059be:	15093503          	ld	a0,336(s2)
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	f42080e7          	jalr	-190(ra) # 80003904 <iput>
  end_op();
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	7c2080e7          	jalr	1986(ra) # 8000418c <end_op>
  p->cwd = ip;
    800059d2:	14993823          	sd	s1,336(s2)
  return 0;
    800059d6:	4501                	li	a0,0
}
    800059d8:	60ea                	ld	ra,152(sp)
    800059da:	644a                	ld	s0,144(sp)
    800059dc:	64aa                	ld	s1,136(sp)
    800059de:	690a                	ld	s2,128(sp)
    800059e0:	610d                	addi	sp,sp,160
    800059e2:	8082                	ret
    end_op();
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	7a8080e7          	jalr	1960(ra) # 8000418c <end_op>
    return -1;
    800059ec:	557d                	li	a0,-1
    800059ee:	b7ed                	j	800059d8 <sys_chdir+0x7a>
    iunlockput(ip);
    800059f0:	8526                	mv	a0,s1
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	fba080e7          	jalr	-70(ra) # 800039ac <iunlockput>
    end_op();
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	792080e7          	jalr	1938(ra) # 8000418c <end_op>
    return -1;
    80005a02:	557d                	li	a0,-1
    80005a04:	bfd1                	j	800059d8 <sys_chdir+0x7a>

0000000080005a06 <sys_exec>:

uint64
sys_exec(void)
{
    80005a06:	7145                	addi	sp,sp,-464
    80005a08:	e786                	sd	ra,456(sp)
    80005a0a:	e3a2                	sd	s0,448(sp)
    80005a0c:	ff26                	sd	s1,440(sp)
    80005a0e:	fb4a                	sd	s2,432(sp)
    80005a10:	f74e                	sd	s3,424(sp)
    80005a12:	f352                	sd	s4,416(sp)
    80005a14:	ef56                	sd	s5,408(sp)
    80005a16:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a18:	e3840593          	addi	a1,s0,-456
    80005a1c:	4505                	li	a0,1
    80005a1e:	ffffd097          	auipc	ra,0xffffd
    80005a22:	1c4080e7          	jalr	452(ra) # 80002be2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a26:	08000613          	li	a2,128
    80005a2a:	f4040593          	addi	a1,s0,-192
    80005a2e:	4501                	li	a0,0
    80005a30:	ffffd097          	auipc	ra,0xffffd
    80005a34:	1d2080e7          	jalr	466(ra) # 80002c02 <argstr>
    80005a38:	87aa                	mv	a5,a0
    return -1;
    80005a3a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a3c:	0c07c263          	bltz	a5,80005b00 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a40:	10000613          	li	a2,256
    80005a44:	4581                	li	a1,0
    80005a46:	e4040513          	addi	a0,s0,-448
    80005a4a:	ffffb097          	auipc	ra,0xffffb
    80005a4e:	29c080e7          	jalr	668(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a52:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a56:	89a6                	mv	s3,s1
    80005a58:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a5a:	02000a13          	li	s4,32
    80005a5e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a62:	00391513          	slli	a0,s2,0x3
    80005a66:	e3040593          	addi	a1,s0,-464
    80005a6a:	e3843783          	ld	a5,-456(s0)
    80005a6e:	953e                	add	a0,a0,a5
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	0b4080e7          	jalr	180(ra) # 80002b24 <fetchaddr>
    80005a78:	02054a63          	bltz	a0,80005aac <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005a7c:	e3043783          	ld	a5,-464(s0)
    80005a80:	c3b9                	beqz	a5,80005ac6 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a82:	ffffb097          	auipc	ra,0xffffb
    80005a86:	078080e7          	jalr	120(ra) # 80000afa <kalloc>
    80005a8a:	85aa                	mv	a1,a0
    80005a8c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a90:	cd11                	beqz	a0,80005aac <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a92:	6605                	lui	a2,0x1
    80005a94:	e3043503          	ld	a0,-464(s0)
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	0de080e7          	jalr	222(ra) # 80002b76 <fetchstr>
    80005aa0:	00054663          	bltz	a0,80005aac <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005aa4:	0905                	addi	s2,s2,1
    80005aa6:	09a1                	addi	s3,s3,8
    80005aa8:	fb491be3          	bne	s2,s4,80005a5e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aac:	10048913          	addi	s2,s1,256
    80005ab0:	6088                	ld	a0,0(s1)
    80005ab2:	c531                	beqz	a0,80005afe <sys_exec+0xf8>
    kfree(argv[i]);
    80005ab4:	ffffb097          	auipc	ra,0xffffb
    80005ab8:	f4a080e7          	jalr	-182(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005abc:	04a1                	addi	s1,s1,8
    80005abe:	ff2499e3          	bne	s1,s2,80005ab0 <sys_exec+0xaa>
  return -1;
    80005ac2:	557d                	li	a0,-1
    80005ac4:	a835                	j	80005b00 <sys_exec+0xfa>
      argv[i] = 0;
    80005ac6:	0a8e                	slli	s5,s5,0x3
    80005ac8:	fc040793          	addi	a5,s0,-64
    80005acc:	9abe                	add	s5,s5,a5
    80005ace:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ad2:	e4040593          	addi	a1,s0,-448
    80005ad6:	f4040513          	addi	a0,s0,-192
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	186080e7          	jalr	390(ra) # 80004c60 <exec>
    80005ae2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae4:	10048993          	addi	s3,s1,256
    80005ae8:	6088                	ld	a0,0(s1)
    80005aea:	c901                	beqz	a0,80005afa <sys_exec+0xf4>
    kfree(argv[i]);
    80005aec:	ffffb097          	auipc	ra,0xffffb
    80005af0:	f12080e7          	jalr	-238(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af4:	04a1                	addi	s1,s1,8
    80005af6:	ff3499e3          	bne	s1,s3,80005ae8 <sys_exec+0xe2>
  return ret;
    80005afa:	854a                	mv	a0,s2
    80005afc:	a011                	j	80005b00 <sys_exec+0xfa>
  return -1;
    80005afe:	557d                	li	a0,-1
}
    80005b00:	60be                	ld	ra,456(sp)
    80005b02:	641e                	ld	s0,448(sp)
    80005b04:	74fa                	ld	s1,440(sp)
    80005b06:	795a                	ld	s2,432(sp)
    80005b08:	79ba                	ld	s3,424(sp)
    80005b0a:	7a1a                	ld	s4,416(sp)
    80005b0c:	6afa                	ld	s5,408(sp)
    80005b0e:	6179                	addi	sp,sp,464
    80005b10:	8082                	ret

0000000080005b12 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b12:	7139                	addi	sp,sp,-64
    80005b14:	fc06                	sd	ra,56(sp)
    80005b16:	f822                	sd	s0,48(sp)
    80005b18:	f426                	sd	s1,40(sp)
    80005b1a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b1c:	ffffc097          	auipc	ra,0xffffc
    80005b20:	f96080e7          	jalr	-106(ra) # 80001ab2 <myproc>
    80005b24:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b26:	fd840593          	addi	a1,s0,-40
    80005b2a:	4501                	li	a0,0
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	0b6080e7          	jalr	182(ra) # 80002be2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b34:	fc840593          	addi	a1,s0,-56
    80005b38:	fd040513          	addi	a0,s0,-48
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	dcc080e7          	jalr	-564(ra) # 80004908 <pipealloc>
    return -1;
    80005b44:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b46:	0c054463          	bltz	a0,80005c0e <sys_pipe+0xfc>
  fd0 = -1;
    80005b4a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b4e:	fd043503          	ld	a0,-48(s0)
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	518080e7          	jalr	1304(ra) # 8000506a <fdalloc>
    80005b5a:	fca42223          	sw	a0,-60(s0)
    80005b5e:	08054b63          	bltz	a0,80005bf4 <sys_pipe+0xe2>
    80005b62:	fc843503          	ld	a0,-56(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	504080e7          	jalr	1284(ra) # 8000506a <fdalloc>
    80005b6e:	fca42023          	sw	a0,-64(s0)
    80005b72:	06054863          	bltz	a0,80005be2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b76:	4691                	li	a3,4
    80005b78:	fc440613          	addi	a2,s0,-60
    80005b7c:	fd843583          	ld	a1,-40(s0)
    80005b80:	68a8                	ld	a0,80(s1)
    80005b82:	ffffc097          	auipc	ra,0xffffc
    80005b86:	bee080e7          	jalr	-1042(ra) # 80001770 <copyout>
    80005b8a:	02054063          	bltz	a0,80005baa <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b8e:	4691                	li	a3,4
    80005b90:	fc040613          	addi	a2,s0,-64
    80005b94:	fd843583          	ld	a1,-40(s0)
    80005b98:	0591                	addi	a1,a1,4
    80005b9a:	68a8                	ld	a0,80(s1)
    80005b9c:	ffffc097          	auipc	ra,0xffffc
    80005ba0:	bd4080e7          	jalr	-1068(ra) # 80001770 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ba4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ba6:	06055463          	bgez	a0,80005c0e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005baa:	fc442783          	lw	a5,-60(s0)
    80005bae:	07e9                	addi	a5,a5,26
    80005bb0:	078e                	slli	a5,a5,0x3
    80005bb2:	97a6                	add	a5,a5,s1
    80005bb4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bb8:	fc042503          	lw	a0,-64(s0)
    80005bbc:	0569                	addi	a0,a0,26
    80005bbe:	050e                	slli	a0,a0,0x3
    80005bc0:	94aa                	add	s1,s1,a0
    80005bc2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bc6:	fd043503          	ld	a0,-48(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	a0e080e7          	jalr	-1522(ra) # 800045d8 <fileclose>
    fileclose(wf);
    80005bd2:	fc843503          	ld	a0,-56(s0)
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	a02080e7          	jalr	-1534(ra) # 800045d8 <fileclose>
    return -1;
    80005bde:	57fd                	li	a5,-1
    80005be0:	a03d                	j	80005c0e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005be2:	fc442783          	lw	a5,-60(s0)
    80005be6:	0007c763          	bltz	a5,80005bf4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005bea:	07e9                	addi	a5,a5,26
    80005bec:	078e                	slli	a5,a5,0x3
    80005bee:	94be                	add	s1,s1,a5
    80005bf0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bf4:	fd043503          	ld	a0,-48(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	9e0080e7          	jalr	-1568(ra) # 800045d8 <fileclose>
    fileclose(wf);
    80005c00:	fc843503          	ld	a0,-56(s0)
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	9d4080e7          	jalr	-1580(ra) # 800045d8 <fileclose>
    return -1;
    80005c0c:	57fd                	li	a5,-1
}
    80005c0e:	853e                	mv	a0,a5
    80005c10:	70e2                	ld	ra,56(sp)
    80005c12:	7442                	ld	s0,48(sp)
    80005c14:	74a2                	ld	s1,40(sp)
    80005c16:	6121                	addi	sp,sp,64
    80005c18:	8082                	ret
    80005c1a:	0000                	unimp
    80005c1c:	0000                	unimp
	...

0000000080005c20 <kernelvec>:
    80005c20:	7111                	addi	sp,sp,-256
    80005c22:	e006                	sd	ra,0(sp)
    80005c24:	e40a                	sd	sp,8(sp)
    80005c26:	e80e                	sd	gp,16(sp)
    80005c28:	ec12                	sd	tp,24(sp)
    80005c2a:	f016                	sd	t0,32(sp)
    80005c2c:	f41a                	sd	t1,40(sp)
    80005c2e:	f81e                	sd	t2,48(sp)
    80005c30:	fc22                	sd	s0,56(sp)
    80005c32:	e0a6                	sd	s1,64(sp)
    80005c34:	e4aa                	sd	a0,72(sp)
    80005c36:	e8ae                	sd	a1,80(sp)
    80005c38:	ecb2                	sd	a2,88(sp)
    80005c3a:	f0b6                	sd	a3,96(sp)
    80005c3c:	f4ba                	sd	a4,104(sp)
    80005c3e:	f8be                	sd	a5,112(sp)
    80005c40:	fcc2                	sd	a6,120(sp)
    80005c42:	e146                	sd	a7,128(sp)
    80005c44:	e54a                	sd	s2,136(sp)
    80005c46:	e94e                	sd	s3,144(sp)
    80005c48:	ed52                	sd	s4,152(sp)
    80005c4a:	f156                	sd	s5,160(sp)
    80005c4c:	f55a                	sd	s6,168(sp)
    80005c4e:	f95e                	sd	s7,176(sp)
    80005c50:	fd62                	sd	s8,184(sp)
    80005c52:	e1e6                	sd	s9,192(sp)
    80005c54:	e5ea                	sd	s10,200(sp)
    80005c56:	e9ee                	sd	s11,208(sp)
    80005c58:	edf2                	sd	t3,216(sp)
    80005c5a:	f1f6                	sd	t4,224(sp)
    80005c5c:	f5fa                	sd	t5,232(sp)
    80005c5e:	f9fe                	sd	t6,240(sp)
    80005c60:	d91fc0ef          	jal	ra,800029f0 <kerneltrap>
    80005c64:	6082                	ld	ra,0(sp)
    80005c66:	6122                	ld	sp,8(sp)
    80005c68:	61c2                	ld	gp,16(sp)
    80005c6a:	7282                	ld	t0,32(sp)
    80005c6c:	7322                	ld	t1,40(sp)
    80005c6e:	73c2                	ld	t2,48(sp)
    80005c70:	7462                	ld	s0,56(sp)
    80005c72:	6486                	ld	s1,64(sp)
    80005c74:	6526                	ld	a0,72(sp)
    80005c76:	65c6                	ld	a1,80(sp)
    80005c78:	6666                	ld	a2,88(sp)
    80005c7a:	7686                	ld	a3,96(sp)
    80005c7c:	7726                	ld	a4,104(sp)
    80005c7e:	77c6                	ld	a5,112(sp)
    80005c80:	7866                	ld	a6,120(sp)
    80005c82:	688a                	ld	a7,128(sp)
    80005c84:	692a                	ld	s2,136(sp)
    80005c86:	69ca                	ld	s3,144(sp)
    80005c88:	6a6a                	ld	s4,152(sp)
    80005c8a:	7a8a                	ld	s5,160(sp)
    80005c8c:	7b2a                	ld	s6,168(sp)
    80005c8e:	7bca                	ld	s7,176(sp)
    80005c90:	7c6a                	ld	s8,184(sp)
    80005c92:	6c8e                	ld	s9,192(sp)
    80005c94:	6d2e                	ld	s10,200(sp)
    80005c96:	6dce                	ld	s11,208(sp)
    80005c98:	6e6e                	ld	t3,216(sp)
    80005c9a:	7e8e                	ld	t4,224(sp)
    80005c9c:	7f2e                	ld	t5,232(sp)
    80005c9e:	7fce                	ld	t6,240(sp)
    80005ca0:	6111                	addi	sp,sp,256
    80005ca2:	10200073          	sret
    80005ca6:	00000013          	nop
    80005caa:	00000013          	nop
    80005cae:	0001                	nop

0000000080005cb0 <timervec>:
    80005cb0:	34051573          	csrrw	a0,mscratch,a0
    80005cb4:	e10c                	sd	a1,0(a0)
    80005cb6:	e510                	sd	a2,8(a0)
    80005cb8:	e914                	sd	a3,16(a0)
    80005cba:	6d0c                	ld	a1,24(a0)
    80005cbc:	7110                	ld	a2,32(a0)
    80005cbe:	6194                	ld	a3,0(a1)
    80005cc0:	96b2                	add	a3,a3,a2
    80005cc2:	e194                	sd	a3,0(a1)
    80005cc4:	4589                	li	a1,2
    80005cc6:	14459073          	csrw	sip,a1
    80005cca:	6914                	ld	a3,16(a0)
    80005ccc:	6510                	ld	a2,8(a0)
    80005cce:	610c                	ld	a1,0(a0)
    80005cd0:	34051573          	csrrw	a0,mscratch,a0
    80005cd4:	30200073          	mret
	...

0000000080005cda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cda:	1141                	addi	sp,sp,-16
    80005cdc:	e422                	sd	s0,8(sp)
    80005cde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ce0:	0c0007b7          	lui	a5,0xc000
    80005ce4:	4705                	li	a4,1
    80005ce6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ce8:	c3d8                	sw	a4,4(a5)
}
    80005cea:	6422                	ld	s0,8(sp)
    80005cec:	0141                	addi	sp,sp,16
    80005cee:	8082                	ret

0000000080005cf0 <plicinithart>:

void
plicinithart(void)
{
    80005cf0:	1141                	addi	sp,sp,-16
    80005cf2:	e406                	sd	ra,8(sp)
    80005cf4:	e022                	sd	s0,0(sp)
    80005cf6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	d8e080e7          	jalr	-626(ra) # 80001a86 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d00:	0085171b          	slliw	a4,a0,0x8
    80005d04:	0c0027b7          	lui	a5,0xc002
    80005d08:	97ba                	add	a5,a5,a4
    80005d0a:	40200713          	li	a4,1026
    80005d0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d12:	00d5151b          	slliw	a0,a0,0xd
    80005d16:	0c2017b7          	lui	a5,0xc201
    80005d1a:	953e                	add	a0,a0,a5
    80005d1c:	00052023          	sw	zero,0(a0)
}
    80005d20:	60a2                	ld	ra,8(sp)
    80005d22:	6402                	ld	s0,0(sp)
    80005d24:	0141                	addi	sp,sp,16
    80005d26:	8082                	ret

0000000080005d28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d28:	1141                	addi	sp,sp,-16
    80005d2a:	e406                	sd	ra,8(sp)
    80005d2c:	e022                	sd	s0,0(sp)
    80005d2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d30:	ffffc097          	auipc	ra,0xffffc
    80005d34:	d56080e7          	jalr	-682(ra) # 80001a86 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d38:	00d5179b          	slliw	a5,a0,0xd
    80005d3c:	0c201537          	lui	a0,0xc201
    80005d40:	953e                	add	a0,a0,a5
  return irq;
}
    80005d42:	4148                	lw	a0,4(a0)
    80005d44:	60a2                	ld	ra,8(sp)
    80005d46:	6402                	ld	s0,0(sp)
    80005d48:	0141                	addi	sp,sp,16
    80005d4a:	8082                	ret

0000000080005d4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d4c:	1101                	addi	sp,sp,-32
    80005d4e:	ec06                	sd	ra,24(sp)
    80005d50:	e822                	sd	s0,16(sp)
    80005d52:	e426                	sd	s1,8(sp)
    80005d54:	1000                	addi	s0,sp,32
    80005d56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	d2e080e7          	jalr	-722(ra) # 80001a86 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d60:	00d5151b          	slliw	a0,a0,0xd
    80005d64:	0c2017b7          	lui	a5,0xc201
    80005d68:	97aa                	add	a5,a5,a0
    80005d6a:	c3c4                	sw	s1,4(a5)
}
    80005d6c:	60e2                	ld	ra,24(sp)
    80005d6e:	6442                	ld	s0,16(sp)
    80005d70:	64a2                	ld	s1,8(sp)
    80005d72:	6105                	addi	sp,sp,32
    80005d74:	8082                	ret

0000000080005d76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d76:	1141                	addi	sp,sp,-16
    80005d78:	e406                	sd	ra,8(sp)
    80005d7a:	e022                	sd	s0,0(sp)
    80005d7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d7e:	479d                	li	a5,7
    80005d80:	04a7cc63          	blt	a5,a0,80005dd8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d84:	0001c797          	auipc	a5,0x1c
    80005d88:	ecc78793          	addi	a5,a5,-308 # 80021c50 <disk>
    80005d8c:	97aa                	add	a5,a5,a0
    80005d8e:	0187c783          	lbu	a5,24(a5)
    80005d92:	ebb9                	bnez	a5,80005de8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d94:	00451613          	slli	a2,a0,0x4
    80005d98:	0001c797          	auipc	a5,0x1c
    80005d9c:	eb878793          	addi	a5,a5,-328 # 80021c50 <disk>
    80005da0:	6394                	ld	a3,0(a5)
    80005da2:	96b2                	add	a3,a3,a2
    80005da4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005da8:	6398                	ld	a4,0(a5)
    80005daa:	9732                	add	a4,a4,a2
    80005dac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005db0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005db4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005db8:	953e                	add	a0,a0,a5
    80005dba:	4785                	li	a5,1
    80005dbc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005dc0:	0001c517          	auipc	a0,0x1c
    80005dc4:	ea850513          	addi	a0,a0,-344 # 80021c68 <disk+0x18>
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	3f2080e7          	jalr	1010(ra) # 800021ba <wakeup>
}
    80005dd0:	60a2                	ld	ra,8(sp)
    80005dd2:	6402                	ld	s0,0(sp)
    80005dd4:	0141                	addi	sp,sp,16
    80005dd6:	8082                	ret
    panic("free_desc 1");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	99850513          	addi	a0,a0,-1640 # 80008770 <syscalls+0x2f0>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	764080e7          	jalr	1892(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005de8:	00003517          	auipc	a0,0x3
    80005dec:	99850513          	addi	a0,a0,-1640 # 80008780 <syscalls+0x300>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	754080e7          	jalr	1876(ra) # 80000544 <panic>

0000000080005df8 <virtio_disk_init>:
{
    80005df8:	1101                	addi	sp,sp,-32
    80005dfa:	ec06                	sd	ra,24(sp)
    80005dfc:	e822                	sd	s0,16(sp)
    80005dfe:	e426                	sd	s1,8(sp)
    80005e00:	e04a                	sd	s2,0(sp)
    80005e02:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e04:	00003597          	auipc	a1,0x3
    80005e08:	98c58593          	addi	a1,a1,-1652 # 80008790 <syscalls+0x310>
    80005e0c:	0001c517          	auipc	a0,0x1c
    80005e10:	f6c50513          	addi	a0,a0,-148 # 80021d78 <disk+0x128>
    80005e14:	ffffb097          	auipc	ra,0xffffb
    80005e18:	d46080e7          	jalr	-698(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e1c:	100017b7          	lui	a5,0x10001
    80005e20:	4398                	lw	a4,0(a5)
    80005e22:	2701                	sext.w	a4,a4
    80005e24:	747277b7          	lui	a5,0x74727
    80005e28:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e2c:	14f71e63          	bne	a4,a5,80005f88 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e30:	100017b7          	lui	a5,0x10001
    80005e34:	43dc                	lw	a5,4(a5)
    80005e36:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e38:	4709                	li	a4,2
    80005e3a:	14e79763          	bne	a5,a4,80005f88 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e3e:	100017b7          	lui	a5,0x10001
    80005e42:	479c                	lw	a5,8(a5)
    80005e44:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e46:	14e79163          	bne	a5,a4,80005f88 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e4a:	100017b7          	lui	a5,0x10001
    80005e4e:	47d8                	lw	a4,12(a5)
    80005e50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e52:	554d47b7          	lui	a5,0x554d4
    80005e56:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e5a:	12f71763          	bne	a4,a5,80005f88 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e66:	4705                	li	a4,1
    80005e68:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6a:	470d                	li	a4,3
    80005e6c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e6e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e70:	c7ffe737          	lui	a4,0xc7ffe
    80005e74:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9cf>
    80005e78:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e7a:	2701                	sext.w	a4,a4
    80005e7c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7e:	472d                	li	a4,11
    80005e80:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e82:	0707a903          	lw	s2,112(a5)
    80005e86:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e88:	00897793          	andi	a5,s2,8
    80005e8c:	10078663          	beqz	a5,80005f98 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e90:	100017b7          	lui	a5,0x10001
    80005e94:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e98:	43fc                	lw	a5,68(a5)
    80005e9a:	2781                	sext.w	a5,a5
    80005e9c:	10079663          	bnez	a5,80005fa8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ea0:	100017b7          	lui	a5,0x10001
    80005ea4:	5bdc                	lw	a5,52(a5)
    80005ea6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ea8:	10078863          	beqz	a5,80005fb8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005eac:	471d                	li	a4,7
    80005eae:	10f77d63          	bgeu	a4,a5,80005fc8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005eb2:	ffffb097          	auipc	ra,0xffffb
    80005eb6:	c48080e7          	jalr	-952(ra) # 80000afa <kalloc>
    80005eba:	0001c497          	auipc	s1,0x1c
    80005ebe:	d9648493          	addi	s1,s1,-618 # 80021c50 <disk>
    80005ec2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ec4:	ffffb097          	auipc	ra,0xffffb
    80005ec8:	c36080e7          	jalr	-970(ra) # 80000afa <kalloc>
    80005ecc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005ece:	ffffb097          	auipc	ra,0xffffb
    80005ed2:	c2c080e7          	jalr	-980(ra) # 80000afa <kalloc>
    80005ed6:	87aa                	mv	a5,a0
    80005ed8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005eda:	6088                	ld	a0,0(s1)
    80005edc:	cd75                	beqz	a0,80005fd8 <virtio_disk_init+0x1e0>
    80005ede:	0001c717          	auipc	a4,0x1c
    80005ee2:	d7a73703          	ld	a4,-646(a4) # 80021c58 <disk+0x8>
    80005ee6:	cb6d                	beqz	a4,80005fd8 <virtio_disk_init+0x1e0>
    80005ee8:	cbe5                	beqz	a5,80005fd8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005eea:	6605                	lui	a2,0x1
    80005eec:	4581                	li	a1,0
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	df8080e7          	jalr	-520(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ef6:	0001c497          	auipc	s1,0x1c
    80005efa:	d5a48493          	addi	s1,s1,-678 # 80021c50 <disk>
    80005efe:	6605                	lui	a2,0x1
    80005f00:	4581                	li	a1,0
    80005f02:	6488                	ld	a0,8(s1)
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	de2080e7          	jalr	-542(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f0c:	6605                	lui	a2,0x1
    80005f0e:	4581                	li	a1,0
    80005f10:	6888                	ld	a0,16(s1)
    80005f12:	ffffb097          	auipc	ra,0xffffb
    80005f16:	dd4080e7          	jalr	-556(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f1a:	100017b7          	lui	a5,0x10001
    80005f1e:	4721                	li	a4,8
    80005f20:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f22:	4098                	lw	a4,0(s1)
    80005f24:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f28:	40d8                	lw	a4,4(s1)
    80005f2a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f2e:	6498                	ld	a4,8(s1)
    80005f30:	0007069b          	sext.w	a3,a4
    80005f34:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f38:	9701                	srai	a4,a4,0x20
    80005f3a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f3e:	6898                	ld	a4,16(s1)
    80005f40:	0007069b          	sext.w	a3,a4
    80005f44:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f48:	9701                	srai	a4,a4,0x20
    80005f4a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f4e:	4685                	li	a3,1
    80005f50:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005f52:	4705                	li	a4,1
    80005f54:	00d48c23          	sb	a3,24(s1)
    80005f58:	00e48ca3          	sb	a4,25(s1)
    80005f5c:	00e48d23          	sb	a4,26(s1)
    80005f60:	00e48da3          	sb	a4,27(s1)
    80005f64:	00e48e23          	sb	a4,28(s1)
    80005f68:	00e48ea3          	sb	a4,29(s1)
    80005f6c:	00e48f23          	sb	a4,30(s1)
    80005f70:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f74:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f78:	0727a823          	sw	s2,112(a5)
}
    80005f7c:	60e2                	ld	ra,24(sp)
    80005f7e:	6442                	ld	s0,16(sp)
    80005f80:	64a2                	ld	s1,8(sp)
    80005f82:	6902                	ld	s2,0(sp)
    80005f84:	6105                	addi	sp,sp,32
    80005f86:	8082                	ret
    panic("could not find virtio disk");
    80005f88:	00003517          	auipc	a0,0x3
    80005f8c:	81850513          	addi	a0,a0,-2024 # 800087a0 <syscalls+0x320>
    80005f90:	ffffa097          	auipc	ra,0xffffa
    80005f94:	5b4080e7          	jalr	1460(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f98:	00003517          	auipc	a0,0x3
    80005f9c:	82850513          	addi	a0,a0,-2008 # 800087c0 <syscalls+0x340>
    80005fa0:	ffffa097          	auipc	ra,0xffffa
    80005fa4:	5a4080e7          	jalr	1444(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80005fa8:	00003517          	auipc	a0,0x3
    80005fac:	83850513          	addi	a0,a0,-1992 # 800087e0 <syscalls+0x360>
    80005fb0:	ffffa097          	auipc	ra,0xffffa
    80005fb4:	594080e7          	jalr	1428(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80005fb8:	00003517          	auipc	a0,0x3
    80005fbc:	84850513          	addi	a0,a0,-1976 # 80008800 <syscalls+0x380>
    80005fc0:	ffffa097          	auipc	ra,0xffffa
    80005fc4:	584080e7          	jalr	1412(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80005fc8:	00003517          	auipc	a0,0x3
    80005fcc:	85850513          	addi	a0,a0,-1960 # 80008820 <syscalls+0x3a0>
    80005fd0:	ffffa097          	auipc	ra,0xffffa
    80005fd4:	574080e7          	jalr	1396(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80005fd8:	00003517          	auipc	a0,0x3
    80005fdc:	86850513          	addi	a0,a0,-1944 # 80008840 <syscalls+0x3c0>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	564080e7          	jalr	1380(ra) # 80000544 <panic>

0000000080005fe8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fe8:	7159                	addi	sp,sp,-112
    80005fea:	f486                	sd	ra,104(sp)
    80005fec:	f0a2                	sd	s0,96(sp)
    80005fee:	eca6                	sd	s1,88(sp)
    80005ff0:	e8ca                	sd	s2,80(sp)
    80005ff2:	e4ce                	sd	s3,72(sp)
    80005ff4:	e0d2                	sd	s4,64(sp)
    80005ff6:	fc56                	sd	s5,56(sp)
    80005ff8:	f85a                	sd	s6,48(sp)
    80005ffa:	f45e                	sd	s7,40(sp)
    80005ffc:	f062                	sd	s8,32(sp)
    80005ffe:	ec66                	sd	s9,24(sp)
    80006000:	e86a                	sd	s10,16(sp)
    80006002:	1880                	addi	s0,sp,112
    80006004:	892a                	mv	s2,a0
    80006006:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006008:	00c52c83          	lw	s9,12(a0)
    8000600c:	001c9c9b          	slliw	s9,s9,0x1
    80006010:	1c82                	slli	s9,s9,0x20
    80006012:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006016:	0001c517          	auipc	a0,0x1c
    8000601a:	d6250513          	addi	a0,a0,-670 # 80021d78 <disk+0x128>
    8000601e:	ffffb097          	auipc	ra,0xffffb
    80006022:	bcc080e7          	jalr	-1076(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006026:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006028:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000602a:	0001cb17          	auipc	s6,0x1c
    8000602e:	c26b0b13          	addi	s6,s6,-986 # 80021c50 <disk>
  for(int i = 0; i < 3; i++){
    80006032:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006034:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006036:	0001cc17          	auipc	s8,0x1c
    8000603a:	d42c0c13          	addi	s8,s8,-702 # 80021d78 <disk+0x128>
    8000603e:	a8b5                	j	800060ba <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006040:	00fb06b3          	add	a3,s6,a5
    80006044:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006048:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000604a:	0207c563          	bltz	a5,80006074 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000604e:	2485                	addiw	s1,s1,1
    80006050:	0711                	addi	a4,a4,4
    80006052:	1f548a63          	beq	s1,s5,80006246 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006056:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006058:	0001c697          	auipc	a3,0x1c
    8000605c:	bf868693          	addi	a3,a3,-1032 # 80021c50 <disk>
    80006060:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006062:	0186c583          	lbu	a1,24(a3)
    80006066:	fde9                	bnez	a1,80006040 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006068:	2785                	addiw	a5,a5,1
    8000606a:	0685                	addi	a3,a3,1
    8000606c:	ff779be3          	bne	a5,s7,80006062 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006070:	57fd                	li	a5,-1
    80006072:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006074:	02905a63          	blez	s1,800060a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006078:	f9042503          	lw	a0,-112(s0)
    8000607c:	00000097          	auipc	ra,0x0
    80006080:	cfa080e7          	jalr	-774(ra) # 80005d76 <free_desc>
      for(int j = 0; j < i; j++)
    80006084:	4785                	li	a5,1
    80006086:	0297d163          	bge	a5,s1,800060a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000608a:	f9442503          	lw	a0,-108(s0)
    8000608e:	00000097          	auipc	ra,0x0
    80006092:	ce8080e7          	jalr	-792(ra) # 80005d76 <free_desc>
      for(int j = 0; j < i; j++)
    80006096:	4789                	li	a5,2
    80006098:	0097d863          	bge	a5,s1,800060a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000609c:	f9842503          	lw	a0,-104(s0)
    800060a0:	00000097          	auipc	ra,0x0
    800060a4:	cd6080e7          	jalr	-810(ra) # 80005d76 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060a8:	85e2                	mv	a1,s8
    800060aa:	0001c517          	auipc	a0,0x1c
    800060ae:	bbe50513          	addi	a0,a0,-1090 # 80021c68 <disk+0x18>
    800060b2:	ffffc097          	auipc	ra,0xffffc
    800060b6:	0a4080e7          	jalr	164(ra) # 80002156 <sleep>
  for(int i = 0; i < 3; i++){
    800060ba:	f9040713          	addi	a4,s0,-112
    800060be:	84ce                	mv	s1,s3
    800060c0:	bf59                	j	80006056 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800060c2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800060c6:	00479693          	slli	a3,a5,0x4
    800060ca:	0001c797          	auipc	a5,0x1c
    800060ce:	b8678793          	addi	a5,a5,-1146 # 80021c50 <disk>
    800060d2:	97b6                	add	a5,a5,a3
    800060d4:	4685                	li	a3,1
    800060d6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060d8:	0001c597          	auipc	a1,0x1c
    800060dc:	b7858593          	addi	a1,a1,-1160 # 80021c50 <disk>
    800060e0:	00a60793          	addi	a5,a2,10
    800060e4:	0792                	slli	a5,a5,0x4
    800060e6:	97ae                	add	a5,a5,a1
    800060e8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800060ec:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060f0:	f6070693          	addi	a3,a4,-160
    800060f4:	619c                	ld	a5,0(a1)
    800060f6:	97b6                	add	a5,a5,a3
    800060f8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060fa:	6188                	ld	a0,0(a1)
    800060fc:	96aa                	add	a3,a3,a0
    800060fe:	47c1                	li	a5,16
    80006100:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006102:	4785                	li	a5,1
    80006104:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006108:	f9442783          	lw	a5,-108(s0)
    8000610c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006110:	0792                	slli	a5,a5,0x4
    80006112:	953e                	add	a0,a0,a5
    80006114:	05890693          	addi	a3,s2,88
    80006118:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000611a:	6188                	ld	a0,0(a1)
    8000611c:	97aa                	add	a5,a5,a0
    8000611e:	40000693          	li	a3,1024
    80006122:	c794                	sw	a3,8(a5)
  if(write)
    80006124:	100d0d63          	beqz	s10,8000623e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006128:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000612c:	00c7d683          	lhu	a3,12(a5)
    80006130:	0016e693          	ori	a3,a3,1
    80006134:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006138:	f9842583          	lw	a1,-104(s0)
    8000613c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006140:	0001c697          	auipc	a3,0x1c
    80006144:	b1068693          	addi	a3,a3,-1264 # 80021c50 <disk>
    80006148:	00260793          	addi	a5,a2,2
    8000614c:	0792                	slli	a5,a5,0x4
    8000614e:	97b6                	add	a5,a5,a3
    80006150:	587d                	li	a6,-1
    80006152:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006156:	0592                	slli	a1,a1,0x4
    80006158:	952e                	add	a0,a0,a1
    8000615a:	f9070713          	addi	a4,a4,-112
    8000615e:	9736                	add	a4,a4,a3
    80006160:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006162:	6298                	ld	a4,0(a3)
    80006164:	972e                	add	a4,a4,a1
    80006166:	4585                	li	a1,1
    80006168:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000616a:	4509                	li	a0,2
    8000616c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006170:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006174:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006178:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000617c:	6698                	ld	a4,8(a3)
    8000617e:	00275783          	lhu	a5,2(a4)
    80006182:	8b9d                	andi	a5,a5,7
    80006184:	0786                	slli	a5,a5,0x1
    80006186:	97ba                	add	a5,a5,a4
    80006188:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000618c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006190:	6698                	ld	a4,8(a3)
    80006192:	00275783          	lhu	a5,2(a4)
    80006196:	2785                	addiw	a5,a5,1
    80006198:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000619c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061a0:	100017b7          	lui	a5,0x10001
    800061a4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061a8:	00492703          	lw	a4,4(s2)
    800061ac:	4785                	li	a5,1
    800061ae:	02f71163          	bne	a4,a5,800061d0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800061b2:	0001c997          	auipc	s3,0x1c
    800061b6:	bc698993          	addi	s3,s3,-1082 # 80021d78 <disk+0x128>
  while(b->disk == 1) {
    800061ba:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061bc:	85ce                	mv	a1,s3
    800061be:	854a                	mv	a0,s2
    800061c0:	ffffc097          	auipc	ra,0xffffc
    800061c4:	f96080e7          	jalr	-106(ra) # 80002156 <sleep>
  while(b->disk == 1) {
    800061c8:	00492783          	lw	a5,4(s2)
    800061cc:	fe9788e3          	beq	a5,s1,800061bc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800061d0:	f9042903          	lw	s2,-112(s0)
    800061d4:	00290793          	addi	a5,s2,2
    800061d8:	00479713          	slli	a4,a5,0x4
    800061dc:	0001c797          	auipc	a5,0x1c
    800061e0:	a7478793          	addi	a5,a5,-1420 # 80021c50 <disk>
    800061e4:	97ba                	add	a5,a5,a4
    800061e6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800061ea:	0001c997          	auipc	s3,0x1c
    800061ee:	a6698993          	addi	s3,s3,-1434 # 80021c50 <disk>
    800061f2:	00491713          	slli	a4,s2,0x4
    800061f6:	0009b783          	ld	a5,0(s3)
    800061fa:	97ba                	add	a5,a5,a4
    800061fc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006200:	854a                	mv	a0,s2
    80006202:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006206:	00000097          	auipc	ra,0x0
    8000620a:	b70080e7          	jalr	-1168(ra) # 80005d76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000620e:	8885                	andi	s1,s1,1
    80006210:	f0ed                	bnez	s1,800061f2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006212:	0001c517          	auipc	a0,0x1c
    80006216:	b6650513          	addi	a0,a0,-1178 # 80021d78 <disk+0x128>
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	a84080e7          	jalr	-1404(ra) # 80000c9e <release>
}
    80006222:	70a6                	ld	ra,104(sp)
    80006224:	7406                	ld	s0,96(sp)
    80006226:	64e6                	ld	s1,88(sp)
    80006228:	6946                	ld	s2,80(sp)
    8000622a:	69a6                	ld	s3,72(sp)
    8000622c:	6a06                	ld	s4,64(sp)
    8000622e:	7ae2                	ld	s5,56(sp)
    80006230:	7b42                	ld	s6,48(sp)
    80006232:	7ba2                	ld	s7,40(sp)
    80006234:	7c02                	ld	s8,32(sp)
    80006236:	6ce2                	ld	s9,24(sp)
    80006238:	6d42                	ld	s10,16(sp)
    8000623a:	6165                	addi	sp,sp,112
    8000623c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000623e:	4689                	li	a3,2
    80006240:	00d79623          	sh	a3,12(a5)
    80006244:	b5e5                	j	8000612c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006246:	f9042603          	lw	a2,-112(s0)
    8000624a:	00a60713          	addi	a4,a2,10
    8000624e:	0712                	slli	a4,a4,0x4
    80006250:	0001c517          	auipc	a0,0x1c
    80006254:	a0850513          	addi	a0,a0,-1528 # 80021c58 <disk+0x8>
    80006258:	953a                	add	a0,a0,a4
  if(write)
    8000625a:	e60d14e3          	bnez	s10,800060c2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000625e:	00a60793          	addi	a5,a2,10
    80006262:	00479693          	slli	a3,a5,0x4
    80006266:	0001c797          	auipc	a5,0x1c
    8000626a:	9ea78793          	addi	a5,a5,-1558 # 80021c50 <disk>
    8000626e:	97b6                	add	a5,a5,a3
    80006270:	0007a423          	sw	zero,8(a5)
    80006274:	b595                	j	800060d8 <virtio_disk_rw+0xf0>

0000000080006276 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006276:	1101                	addi	sp,sp,-32
    80006278:	ec06                	sd	ra,24(sp)
    8000627a:	e822                	sd	s0,16(sp)
    8000627c:	e426                	sd	s1,8(sp)
    8000627e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006280:	0001c497          	auipc	s1,0x1c
    80006284:	9d048493          	addi	s1,s1,-1584 # 80021c50 <disk>
    80006288:	0001c517          	auipc	a0,0x1c
    8000628c:	af050513          	addi	a0,a0,-1296 # 80021d78 <disk+0x128>
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	95a080e7          	jalr	-1702(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006298:	10001737          	lui	a4,0x10001
    8000629c:	533c                	lw	a5,96(a4)
    8000629e:	8b8d                	andi	a5,a5,3
    800062a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062a6:	689c                	ld	a5,16(s1)
    800062a8:	0204d703          	lhu	a4,32(s1)
    800062ac:	0027d783          	lhu	a5,2(a5)
    800062b0:	04f70863          	beq	a4,a5,80006300 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062b4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062b8:	6898                	ld	a4,16(s1)
    800062ba:	0204d783          	lhu	a5,32(s1)
    800062be:	8b9d                	andi	a5,a5,7
    800062c0:	078e                	slli	a5,a5,0x3
    800062c2:	97ba                	add	a5,a5,a4
    800062c4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062c6:	00278713          	addi	a4,a5,2
    800062ca:	0712                	slli	a4,a4,0x4
    800062cc:	9726                	add	a4,a4,s1
    800062ce:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062d2:	e721                	bnez	a4,8000631a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062d4:	0789                	addi	a5,a5,2
    800062d6:	0792                	slli	a5,a5,0x4
    800062d8:	97a6                	add	a5,a5,s1
    800062da:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062dc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062e0:	ffffc097          	auipc	ra,0xffffc
    800062e4:	eda080e7          	jalr	-294(ra) # 800021ba <wakeup>

    disk.used_idx += 1;
    800062e8:	0204d783          	lhu	a5,32(s1)
    800062ec:	2785                	addiw	a5,a5,1
    800062ee:	17c2                	slli	a5,a5,0x30
    800062f0:	93c1                	srli	a5,a5,0x30
    800062f2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062f6:	6898                	ld	a4,16(s1)
    800062f8:	00275703          	lhu	a4,2(a4)
    800062fc:	faf71ce3          	bne	a4,a5,800062b4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006300:	0001c517          	auipc	a0,0x1c
    80006304:	a7850513          	addi	a0,a0,-1416 # 80021d78 <disk+0x128>
    80006308:	ffffb097          	auipc	ra,0xffffb
    8000630c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80006310:	60e2                	ld	ra,24(sp)
    80006312:	6442                	ld	s0,16(sp)
    80006314:	64a2                	ld	s1,8(sp)
    80006316:	6105                	addi	sp,sp,32
    80006318:	8082                	ret
      panic("virtio_disk_intr status");
    8000631a:	00002517          	auipc	a0,0x2
    8000631e:	53e50513          	addi	a0,a0,1342 # 80008858 <syscalls+0x3d8>
    80006322:	ffffa097          	auipc	ra,0xffffa
    80006326:	222080e7          	jalr	546(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
