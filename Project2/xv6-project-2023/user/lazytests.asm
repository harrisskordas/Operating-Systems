
user/_lazytests:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <sparse_memory>:

#define REGION_SZ (1024 * 1024 * 1024)

void
sparse_memory(char *s)
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  char *i, *prev_end, *new_end;
  
  prev_end = sbrk(REGION_SZ);
   8:	40000537          	lui	a0,0x40000
   c:	00000097          	auipc	ra,0x0
  10:	61e080e7          	jalr	1566(ra) # 62a <sbrk>
  if (prev_end == (char*)0xffffffffffffffffL) {
  14:	57fd                	li	a5,-1
  16:	02f50b63          	beq	a0,a5,4c <sparse_memory+0x4c>
    printf("sbrk() failed\n");
    exit(1);
  }
  new_end = prev_end + REGION_SZ;

  for (i = prev_end + PGSIZE; i < new_end; i += 64 * PGSIZE)
  1a:	6605                	lui	a2,0x1
  1c:	962a                	add	a2,a2,a0
  1e:	40001737          	lui	a4,0x40001
  22:	972a                	add	a4,a4,a0
  24:	87b2                	mv	a5,a2
  26:	000406b7          	lui	a3,0x40
    *(char **)i = i;
  2a:	e39c                	sd	a5,0(a5)
  for (i = prev_end + PGSIZE; i < new_end; i += 64 * PGSIZE)
  2c:	97b6                	add	a5,a5,a3
  2e:	fee79ee3          	bne	a5,a4,2a <sparse_memory+0x2a>

  for (i = prev_end + PGSIZE; i < new_end; i += 64 * PGSIZE) {
  32:	000406b7          	lui	a3,0x40
    if (*(char **)i != i) {
  36:	621c                	ld	a5,0(a2)
  38:	02c79763          	bne	a5,a2,66 <sparse_memory+0x66>
  for (i = prev_end + PGSIZE; i < new_end; i += 64 * PGSIZE) {
  3c:	9636                	add	a2,a2,a3
  3e:	fee61ce3          	bne	a2,a4,36 <sparse_memory+0x36>
      printf("failed to read value from memory\n");
      exit(1);
    }
  }

  exit(0);
  42:	4501                	li	a0,0
  44:	00000097          	auipc	ra,0x0
  48:	55e080e7          	jalr	1374(ra) # 5a2 <exit>
    printf("sbrk() failed\n");
  4c:	00001517          	auipc	a0,0x1
  50:	aa450513          	addi	a0,a0,-1372 # af0 <malloc+0x118>
  54:	00001097          	auipc	ra,0x1
  58:	8c6080e7          	jalr	-1850(ra) # 91a <printf>
    exit(1);
  5c:	4505                	li	a0,1
  5e:	00000097          	auipc	ra,0x0
  62:	544080e7          	jalr	1348(ra) # 5a2 <exit>
      printf("failed to read value from memory\n");
  66:	00001517          	auipc	a0,0x1
  6a:	a9a50513          	addi	a0,a0,-1382 # b00 <malloc+0x128>
  6e:	00001097          	auipc	ra,0x1
  72:	8ac080e7          	jalr	-1876(ra) # 91a <printf>
      exit(1);
  76:	4505                	li	a0,1
  78:	00000097          	auipc	ra,0x0
  7c:	52a080e7          	jalr	1322(ra) # 5a2 <exit>

0000000000000080 <sparse_memory_unmap>:
}

void
sparse_memory_unmap(char *s)
{
  80:	7139                	addi	sp,sp,-64
  82:	fc06                	sd	ra,56(sp)
  84:	f822                	sd	s0,48(sp)
  86:	f426                	sd	s1,40(sp)
  88:	f04a                	sd	s2,32(sp)
  8a:	ec4e                	sd	s3,24(sp)
  8c:	0080                	addi	s0,sp,64
  int pid;
  char *i, *prev_end, *new_end;

  prev_end = sbrk(REGION_SZ);
  8e:	40000537          	lui	a0,0x40000
  92:	00000097          	auipc	ra,0x0
  96:	598080e7          	jalr	1432(ra) # 62a <sbrk>
  if (prev_end == (char*)0xffffffffffffffffL) {
  9a:	57fd                	li	a5,-1
  9c:	04f50863          	beq	a0,a5,ec <sparse_memory_unmap+0x6c>
    printf("sbrk() failed\n");
    exit(1);
  }
  new_end = prev_end + REGION_SZ;

  for (i = prev_end + PGSIZE; i < new_end; i += PGSIZE * PGSIZE)
  a0:	6905                	lui	s2,0x1
  a2:	992a                	add	s2,s2,a0
  a4:	400014b7          	lui	s1,0x40001
  a8:	94aa                	add	s1,s1,a0
  aa:	87ca                	mv	a5,s2
  ac:	01000737          	lui	a4,0x1000
    *(char **)i = i;
  b0:	e39c                	sd	a5,0(a5)
  for (i = prev_end + PGSIZE; i < new_end; i += PGSIZE * PGSIZE)
  b2:	97ba                	add	a5,a5,a4
  b4:	fef49ee3          	bne	s1,a5,b0 <sparse_memory_unmap+0x30>

  for (i = prev_end + PGSIZE; i < new_end; i += PGSIZE * PGSIZE) {
  b8:	010009b7          	lui	s3,0x1000
    pid = fork();
  bc:	00000097          	auipc	ra,0x0
  c0:	4de080e7          	jalr	1246(ra) # 59a <fork>
    if (pid < 0) {
  c4:	04054163          	bltz	a0,106 <sparse_memory_unmap+0x86>
      printf("error forking\n");
      exit(1);
    } else if (pid == 0) {
  c8:	cd21                	beqz	a0,120 <sparse_memory_unmap+0xa0>
      sbrk(-1L * REGION_SZ);
      *(char **)i = i;
      exit(0);
    } else {
      int status;
      wait(&status);
  ca:	fcc40513          	addi	a0,s0,-52
  ce:	00000097          	auipc	ra,0x0
  d2:	4dc080e7          	jalr	1244(ra) # 5aa <wait>
      if (status == 0) {
  d6:	fcc42783          	lw	a5,-52(s0)
  da:	c3a5                	beqz	a5,13a <sparse_memory_unmap+0xba>
  for (i = prev_end + PGSIZE; i < new_end; i += PGSIZE * PGSIZE) {
  dc:	994e                	add	s2,s2,s3
  de:	fd249fe3          	bne	s1,s2,bc <sparse_memory_unmap+0x3c>
        exit(1);
      }
    }
  }

  exit(0);
  e2:	4501                	li	a0,0
  e4:	00000097          	auipc	ra,0x0
  e8:	4be080e7          	jalr	1214(ra) # 5a2 <exit>
    printf("sbrk() failed\n");
  ec:	00001517          	auipc	a0,0x1
  f0:	a0450513          	addi	a0,a0,-1532 # af0 <malloc+0x118>
  f4:	00001097          	auipc	ra,0x1
  f8:	826080e7          	jalr	-2010(ra) # 91a <printf>
    exit(1);
  fc:	4505                	li	a0,1
  fe:	00000097          	auipc	ra,0x0
 102:	4a4080e7          	jalr	1188(ra) # 5a2 <exit>
      printf("error forking\n");
 106:	00001517          	auipc	a0,0x1
 10a:	a2250513          	addi	a0,a0,-1502 # b28 <malloc+0x150>
 10e:	00001097          	auipc	ra,0x1
 112:	80c080e7          	jalr	-2036(ra) # 91a <printf>
      exit(1);
 116:	4505                	li	a0,1
 118:	00000097          	auipc	ra,0x0
 11c:	48a080e7          	jalr	1162(ra) # 5a2 <exit>
      sbrk(-1L * REGION_SZ);
 120:	c0000537          	lui	a0,0xc0000
 124:	00000097          	auipc	ra,0x0
 128:	506080e7          	jalr	1286(ra) # 62a <sbrk>
      *(char **)i = i;
 12c:	01293023          	sd	s2,0(s2) # 1000 <freep>
      exit(0);
 130:	4501                	li	a0,0
 132:	00000097          	auipc	ra,0x0
 136:	470080e7          	jalr	1136(ra) # 5a2 <exit>
        printf("memory not unmapped\n");
 13a:	00001517          	auipc	a0,0x1
 13e:	9fe50513          	addi	a0,a0,-1538 # b38 <malloc+0x160>
 142:	00000097          	auipc	ra,0x0
 146:	7d8080e7          	jalr	2008(ra) # 91a <printf>
        exit(1);
 14a:	4505                	li	a0,1
 14c:	00000097          	auipc	ra,0x0
 150:	456080e7          	jalr	1110(ra) # 5a2 <exit>

0000000000000154 <oom>:
}

void
oom(char *s)
{
 154:	7179                	addi	sp,sp,-48
 156:	f406                	sd	ra,40(sp)
 158:	f022                	sd	s0,32(sp)
 15a:	ec26                	sd	s1,24(sp)
 15c:	1800                	addi	s0,sp,48
  void *m1, *m2;
  int pid;

  if((pid = fork()) == 0){
 15e:	00000097          	auipc	ra,0x0
 162:	43c080e7          	jalr	1084(ra) # 59a <fork>
    m1 = 0;
 166:	4481                	li	s1,0
  if((pid = fork()) == 0){
 168:	c10d                	beqz	a0,18a <oom+0x36>
      m1 = m2;
    }
    exit(0);
  } else {
    int xstatus;
    wait(&xstatus);
 16a:	fdc40513          	addi	a0,s0,-36
 16e:	00000097          	auipc	ra,0x0
 172:	43c080e7          	jalr	1084(ra) # 5aa <wait>
    exit(xstatus == 0);
 176:	fdc42503          	lw	a0,-36(s0)
 17a:	00153513          	seqz	a0,a0
 17e:	00000097          	auipc	ra,0x0
 182:	424080e7          	jalr	1060(ra) # 5a2 <exit>
      *(char**)m2 = m1;
 186:	e104                	sd	s1,0(a0)
      m1 = m2;
 188:	84aa                	mv	s1,a0
    while((m2 = malloc(4096*4096)) != 0){
 18a:	01000537          	lui	a0,0x1000
 18e:	00001097          	auipc	ra,0x1
 192:	84a080e7          	jalr	-1974(ra) # 9d8 <malloc>
 196:	f965                	bnez	a0,186 <oom+0x32>
    exit(0);
 198:	00000097          	auipc	ra,0x0
 19c:	40a080e7          	jalr	1034(ra) # 5a2 <exit>

00000000000001a0 <run>:
}

// run each test in its own process. run returns 1 if child's exit()
// indicates success.
int
run(void f(char *), char *s) {
 1a0:	7179                	addi	sp,sp,-48
 1a2:	f406                	sd	ra,40(sp)
 1a4:	f022                	sd	s0,32(sp)
 1a6:	ec26                	sd	s1,24(sp)
 1a8:	e84a                	sd	s2,16(sp)
 1aa:	1800                	addi	s0,sp,48
 1ac:	892a                	mv	s2,a0
 1ae:	84ae                	mv	s1,a1
  int pid;
  int xstatus;
  
  printf("running test %s\n", s);
 1b0:	00001517          	auipc	a0,0x1
 1b4:	9a050513          	addi	a0,a0,-1632 # b50 <malloc+0x178>
 1b8:	00000097          	auipc	ra,0x0
 1bc:	762080e7          	jalr	1890(ra) # 91a <printf>
  if((pid = fork()) < 0) {
 1c0:	00000097          	auipc	ra,0x0
 1c4:	3da080e7          	jalr	986(ra) # 59a <fork>
 1c8:	02054f63          	bltz	a0,206 <run+0x66>
    printf("runtest: fork error\n");
    exit(1);
  }
  if(pid == 0) {
 1cc:	c931                	beqz	a0,220 <run+0x80>
    f(s);
    exit(0);
  } else {
    wait(&xstatus);
 1ce:	fdc40513          	addi	a0,s0,-36
 1d2:	00000097          	auipc	ra,0x0
 1d6:	3d8080e7          	jalr	984(ra) # 5aa <wait>
    if(xstatus != 0) 
 1da:	fdc42783          	lw	a5,-36(s0)
 1de:	cba1                	beqz	a5,22e <run+0x8e>
      printf("test %s: FAILED\n", s);
 1e0:	85a6                	mv	a1,s1
 1e2:	00001517          	auipc	a0,0x1
 1e6:	99e50513          	addi	a0,a0,-1634 # b80 <malloc+0x1a8>
 1ea:	00000097          	auipc	ra,0x0
 1ee:	730080e7          	jalr	1840(ra) # 91a <printf>
    else
      printf("test %s: OK\n", s);
    return xstatus == 0;
 1f2:	fdc42503          	lw	a0,-36(s0)
  }
}
 1f6:	00153513          	seqz	a0,a0
 1fa:	70a2                	ld	ra,40(sp)
 1fc:	7402                	ld	s0,32(sp)
 1fe:	64e2                	ld	s1,24(sp)
 200:	6942                	ld	s2,16(sp)
 202:	6145                	addi	sp,sp,48
 204:	8082                	ret
    printf("runtest: fork error\n");
 206:	00001517          	auipc	a0,0x1
 20a:	96250513          	addi	a0,a0,-1694 # b68 <malloc+0x190>
 20e:	00000097          	auipc	ra,0x0
 212:	70c080e7          	jalr	1804(ra) # 91a <printf>
    exit(1);
 216:	4505                	li	a0,1
 218:	00000097          	auipc	ra,0x0
 21c:	38a080e7          	jalr	906(ra) # 5a2 <exit>
    f(s);
 220:	8526                	mv	a0,s1
 222:	9902                	jalr	s2
    exit(0);
 224:	4501                	li	a0,0
 226:	00000097          	auipc	ra,0x0
 22a:	37c080e7          	jalr	892(ra) # 5a2 <exit>
      printf("test %s: OK\n", s);
 22e:	85a6                	mv	a1,s1
 230:	00001517          	auipc	a0,0x1
 234:	96850513          	addi	a0,a0,-1688 # b98 <malloc+0x1c0>
 238:	00000097          	auipc	ra,0x0
 23c:	6e2080e7          	jalr	1762(ra) # 91a <printf>
 240:	bf4d                	j	1f2 <run+0x52>

0000000000000242 <main>:

int
main(int argc, char *argv[])
{
 242:	7159                	addi	sp,sp,-112
 244:	f486                	sd	ra,104(sp)
 246:	f0a2                	sd	s0,96(sp)
 248:	eca6                	sd	s1,88(sp)
 24a:	e8ca                	sd	s2,80(sp)
 24c:	e4ce                	sd	s3,72(sp)
 24e:	e0d2                	sd	s4,64(sp)
 250:	1880                	addi	s0,sp,112
  char *n = 0;
  if(argc > 1) {
 252:	4785                	li	a5,1
  char *n = 0;
 254:	4901                	li	s2,0
  if(argc > 1) {
 256:	00a7d463          	bge	a5,a0,25e <main+0x1c>
    n = argv[1];
 25a:	0085b903          	ld	s2,8(a1)
  }
  
  struct test {
    void (*f)(char *);
    char *s;
  } tests[] = {
 25e:	00001797          	auipc	a5,0x1
 262:	99278793          	addi	a5,a5,-1646 # bf0 <malloc+0x218>
 266:	0007b883          	ld	a7,0(a5)
 26a:	0087b803          	ld	a6,8(a5)
 26e:	6b88                	ld	a0,16(a5)
 270:	6f8c                	ld	a1,24(a5)
 272:	7390                	ld	a2,32(a5)
 274:	7794                	ld	a3,40(a5)
 276:	7b98                	ld	a4,48(a5)
 278:	7f9c                	ld	a5,56(a5)
 27a:	f9143823          	sd	a7,-112(s0)
 27e:	f9043c23          	sd	a6,-104(s0)
 282:	faa43023          	sd	a0,-96(s0)
 286:	fab43423          	sd	a1,-88(s0)
 28a:	fac43823          	sd	a2,-80(s0)
 28e:	fad43c23          	sd	a3,-72(s0)
 292:	fce43023          	sd	a4,-64(s0)
 296:	fcf43423          	sd	a5,-56(s0)
    { sparse_memory_unmap, "lazy unmap"},
    { oom, "out of memory"},
    { 0, 0},
  };
    
  printf("lazytests starting\n");
 29a:	00001517          	auipc	a0,0x1
 29e:	90e50513          	addi	a0,a0,-1778 # ba8 <malloc+0x1d0>
 2a2:	00000097          	auipc	ra,0x0
 2a6:	678080e7          	jalr	1656(ra) # 91a <printf>

  int fail = 0;
  for (struct test *t = tests; t->s != 0; t++) {
 2aa:	f9843503          	ld	a0,-104(s0)
 2ae:	c529                	beqz	a0,2f8 <main+0xb6>
 2b0:	f9040493          	addi	s1,s0,-112
  int fail = 0;
 2b4:	4981                	li	s3,0
    if((n == 0) || strcmp(t->s, n) == 0) {
      if(!run(t->f, t->s))
        fail = 1;
 2b6:	4a05                	li	s4,1
 2b8:	a021                	j	2c0 <main+0x7e>
  for (struct test *t = tests; t->s != 0; t++) {
 2ba:	04c1                	addi	s1,s1,16
 2bc:	6488                	ld	a0,8(s1)
 2be:	c115                	beqz	a0,2e2 <main+0xa0>
    if((n == 0) || strcmp(t->s, n) == 0) {
 2c0:	00090863          	beqz	s2,2d0 <main+0x8e>
 2c4:	85ca                	mv	a1,s2
 2c6:	00000097          	auipc	ra,0x0
 2ca:	082080e7          	jalr	130(ra) # 348 <strcmp>
 2ce:	f575                	bnez	a0,2ba <main+0x78>
      if(!run(t->f, t->s))
 2d0:	648c                	ld	a1,8(s1)
 2d2:	6088                	ld	a0,0(s1)
 2d4:	00000097          	auipc	ra,0x0
 2d8:	ecc080e7          	jalr	-308(ra) # 1a0 <run>
 2dc:	fd79                	bnez	a0,2ba <main+0x78>
        fail = 1;
 2de:	89d2                	mv	s3,s4
 2e0:	bfe9                	j	2ba <main+0x78>
    }
  }
  if(!fail)
 2e2:	00098b63          	beqz	s3,2f8 <main+0xb6>
    printf("ALL TESTS PASSED\n");
  else
    printf("SOME TESTS FAILED\n");
 2e6:	00001517          	auipc	a0,0x1
 2ea:	8f250513          	addi	a0,a0,-1806 # bd8 <malloc+0x200>
 2ee:	00000097          	auipc	ra,0x0
 2f2:	62c080e7          	jalr	1580(ra) # 91a <printf>
 2f6:	a809                	j	308 <main+0xc6>
    printf("ALL TESTS PASSED\n");
 2f8:	00001517          	auipc	a0,0x1
 2fc:	8c850513          	addi	a0,a0,-1848 # bc0 <malloc+0x1e8>
 300:	00000097          	auipc	ra,0x0
 304:	61a080e7          	jalr	1562(ra) # 91a <printf>
  exit(1);   // not reached.
 308:	4505                	li	a0,1
 30a:	00000097          	auipc	ra,0x0
 30e:	298080e7          	jalr	664(ra) # 5a2 <exit>

0000000000000312 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 312:	1141                	addi	sp,sp,-16
 314:	e406                	sd	ra,8(sp)
 316:	e022                	sd	s0,0(sp)
 318:	0800                	addi	s0,sp,16
  extern int main();
  main();
 31a:	00000097          	auipc	ra,0x0
 31e:	f28080e7          	jalr	-216(ra) # 242 <main>
  exit(0);
 322:	4501                	li	a0,0
 324:	00000097          	auipc	ra,0x0
 328:	27e080e7          	jalr	638(ra) # 5a2 <exit>

000000000000032c <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 32c:	1141                	addi	sp,sp,-16
 32e:	e422                	sd	s0,8(sp)
 330:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 332:	87aa                	mv	a5,a0
 334:	0585                	addi	a1,a1,1
 336:	0785                	addi	a5,a5,1
 338:	fff5c703          	lbu	a4,-1(a1)
 33c:	fee78fa3          	sb	a4,-1(a5)
 340:	fb75                	bnez	a4,334 <strcpy+0x8>
    ;
  return os;
}
 342:	6422                	ld	s0,8(sp)
 344:	0141                	addi	sp,sp,16
 346:	8082                	ret

0000000000000348 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 348:	1141                	addi	sp,sp,-16
 34a:	e422                	sd	s0,8(sp)
 34c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 34e:	00054783          	lbu	a5,0(a0)
 352:	cb91                	beqz	a5,366 <strcmp+0x1e>
 354:	0005c703          	lbu	a4,0(a1)
 358:	00f71763          	bne	a4,a5,366 <strcmp+0x1e>
    p++, q++;
 35c:	0505                	addi	a0,a0,1
 35e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 360:	00054783          	lbu	a5,0(a0)
 364:	fbe5                	bnez	a5,354 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 366:	0005c503          	lbu	a0,0(a1)
}
 36a:	40a7853b          	subw	a0,a5,a0
 36e:	6422                	ld	s0,8(sp)
 370:	0141                	addi	sp,sp,16
 372:	8082                	ret

0000000000000374 <strlen>:

uint
strlen(const char *s)
{
 374:	1141                	addi	sp,sp,-16
 376:	e422                	sd	s0,8(sp)
 378:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 37a:	00054783          	lbu	a5,0(a0)
 37e:	cf91                	beqz	a5,39a <strlen+0x26>
 380:	0505                	addi	a0,a0,1
 382:	87aa                	mv	a5,a0
 384:	4685                	li	a3,1
 386:	9e89                	subw	a3,a3,a0
 388:	00f6853b          	addw	a0,a3,a5
 38c:	0785                	addi	a5,a5,1
 38e:	fff7c703          	lbu	a4,-1(a5)
 392:	fb7d                	bnez	a4,388 <strlen+0x14>
    ;
  return n;
}
 394:	6422                	ld	s0,8(sp)
 396:	0141                	addi	sp,sp,16
 398:	8082                	ret
  for(n = 0; s[n]; n++)
 39a:	4501                	li	a0,0
 39c:	bfe5                	j	394 <strlen+0x20>

000000000000039e <memset>:

void*
memset(void *dst, int c, uint n)
{
 39e:	1141                	addi	sp,sp,-16
 3a0:	e422                	sd	s0,8(sp)
 3a2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3a4:	ce09                	beqz	a2,3be <memset+0x20>
 3a6:	87aa                	mv	a5,a0
 3a8:	fff6071b          	addiw	a4,a2,-1
 3ac:	1702                	slli	a4,a4,0x20
 3ae:	9301                	srli	a4,a4,0x20
 3b0:	0705                	addi	a4,a4,1
 3b2:	972a                	add	a4,a4,a0
    cdst[i] = c;
 3b4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3b8:	0785                	addi	a5,a5,1
 3ba:	fee79de3          	bne	a5,a4,3b4 <memset+0x16>
  }
  return dst;
}
 3be:	6422                	ld	s0,8(sp)
 3c0:	0141                	addi	sp,sp,16
 3c2:	8082                	ret

00000000000003c4 <strchr>:

char*
strchr(const char *s, char c)
{
 3c4:	1141                	addi	sp,sp,-16
 3c6:	e422                	sd	s0,8(sp)
 3c8:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3ca:	00054783          	lbu	a5,0(a0)
 3ce:	cb99                	beqz	a5,3e4 <strchr+0x20>
    if(*s == c)
 3d0:	00f58763          	beq	a1,a5,3de <strchr+0x1a>
  for(; *s; s++)
 3d4:	0505                	addi	a0,a0,1
 3d6:	00054783          	lbu	a5,0(a0)
 3da:	fbfd                	bnez	a5,3d0 <strchr+0xc>
      return (char*)s;
  return 0;
 3dc:	4501                	li	a0,0
}
 3de:	6422                	ld	s0,8(sp)
 3e0:	0141                	addi	sp,sp,16
 3e2:	8082                	ret
  return 0;
 3e4:	4501                	li	a0,0
 3e6:	bfe5                	j	3de <strchr+0x1a>

00000000000003e8 <gets>:

char*
gets(char *buf, int max)
{
 3e8:	711d                	addi	sp,sp,-96
 3ea:	ec86                	sd	ra,88(sp)
 3ec:	e8a2                	sd	s0,80(sp)
 3ee:	e4a6                	sd	s1,72(sp)
 3f0:	e0ca                	sd	s2,64(sp)
 3f2:	fc4e                	sd	s3,56(sp)
 3f4:	f852                	sd	s4,48(sp)
 3f6:	f456                	sd	s5,40(sp)
 3f8:	f05a                	sd	s6,32(sp)
 3fa:	ec5e                	sd	s7,24(sp)
 3fc:	1080                	addi	s0,sp,96
 3fe:	8baa                	mv	s7,a0
 400:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 402:	892a                	mv	s2,a0
 404:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 406:	4aa9                	li	s5,10
 408:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 40a:	89a6                	mv	s3,s1
 40c:	2485                	addiw	s1,s1,1
 40e:	0344d863          	bge	s1,s4,43e <gets+0x56>
    cc = read(0, &c, 1);
 412:	4605                	li	a2,1
 414:	faf40593          	addi	a1,s0,-81
 418:	4501                	li	a0,0
 41a:	00000097          	auipc	ra,0x0
 41e:	1a0080e7          	jalr	416(ra) # 5ba <read>
    if(cc < 1)
 422:	00a05e63          	blez	a0,43e <gets+0x56>
    buf[i++] = c;
 426:	faf44783          	lbu	a5,-81(s0)
 42a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 42e:	01578763          	beq	a5,s5,43c <gets+0x54>
 432:	0905                	addi	s2,s2,1
 434:	fd679be3          	bne	a5,s6,40a <gets+0x22>
  for(i=0; i+1 < max; ){
 438:	89a6                	mv	s3,s1
 43a:	a011                	j	43e <gets+0x56>
 43c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 43e:	99de                	add	s3,s3,s7
 440:	00098023          	sb	zero,0(s3) # 1000000 <base+0xffeff0>
  return buf;
}
 444:	855e                	mv	a0,s7
 446:	60e6                	ld	ra,88(sp)
 448:	6446                	ld	s0,80(sp)
 44a:	64a6                	ld	s1,72(sp)
 44c:	6906                	ld	s2,64(sp)
 44e:	79e2                	ld	s3,56(sp)
 450:	7a42                	ld	s4,48(sp)
 452:	7aa2                	ld	s5,40(sp)
 454:	7b02                	ld	s6,32(sp)
 456:	6be2                	ld	s7,24(sp)
 458:	6125                	addi	sp,sp,96
 45a:	8082                	ret

000000000000045c <stat>:

int
stat(const char *n, struct stat *st)
{
 45c:	1101                	addi	sp,sp,-32
 45e:	ec06                	sd	ra,24(sp)
 460:	e822                	sd	s0,16(sp)
 462:	e426                	sd	s1,8(sp)
 464:	e04a                	sd	s2,0(sp)
 466:	1000                	addi	s0,sp,32
 468:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 46a:	4581                	li	a1,0
 46c:	00000097          	auipc	ra,0x0
 470:	176080e7          	jalr	374(ra) # 5e2 <open>
  if(fd < 0)
 474:	02054563          	bltz	a0,49e <stat+0x42>
 478:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 47a:	85ca                	mv	a1,s2
 47c:	00000097          	auipc	ra,0x0
 480:	17e080e7          	jalr	382(ra) # 5fa <fstat>
 484:	892a                	mv	s2,a0
  close(fd);
 486:	8526                	mv	a0,s1
 488:	00000097          	auipc	ra,0x0
 48c:	142080e7          	jalr	322(ra) # 5ca <close>
  return r;
}
 490:	854a                	mv	a0,s2
 492:	60e2                	ld	ra,24(sp)
 494:	6442                	ld	s0,16(sp)
 496:	64a2                	ld	s1,8(sp)
 498:	6902                	ld	s2,0(sp)
 49a:	6105                	addi	sp,sp,32
 49c:	8082                	ret
    return -1;
 49e:	597d                	li	s2,-1
 4a0:	bfc5                	j	490 <stat+0x34>

00000000000004a2 <atoi>:

int
atoi(const char *s)
{
 4a2:	1141                	addi	sp,sp,-16
 4a4:	e422                	sd	s0,8(sp)
 4a6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4a8:	00054603          	lbu	a2,0(a0)
 4ac:	fd06079b          	addiw	a5,a2,-48
 4b0:	0ff7f793          	andi	a5,a5,255
 4b4:	4725                	li	a4,9
 4b6:	02f76963          	bltu	a4,a5,4e8 <atoi+0x46>
 4ba:	86aa                	mv	a3,a0
  n = 0;
 4bc:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 4be:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 4c0:	0685                	addi	a3,a3,1
 4c2:	0025179b          	slliw	a5,a0,0x2
 4c6:	9fa9                	addw	a5,a5,a0
 4c8:	0017979b          	slliw	a5,a5,0x1
 4cc:	9fb1                	addw	a5,a5,a2
 4ce:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4d2:	0006c603          	lbu	a2,0(a3) # 40000 <base+0x3eff0>
 4d6:	fd06071b          	addiw	a4,a2,-48
 4da:	0ff77713          	andi	a4,a4,255
 4de:	fee5f1e3          	bgeu	a1,a4,4c0 <atoi+0x1e>
  return n;
}
 4e2:	6422                	ld	s0,8(sp)
 4e4:	0141                	addi	sp,sp,16
 4e6:	8082                	ret
  n = 0;
 4e8:	4501                	li	a0,0
 4ea:	bfe5                	j	4e2 <atoi+0x40>

00000000000004ec <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4ec:	1141                	addi	sp,sp,-16
 4ee:	e422                	sd	s0,8(sp)
 4f0:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4f2:	02b57663          	bgeu	a0,a1,51e <memmove+0x32>
    while(n-- > 0)
 4f6:	02c05163          	blez	a2,518 <memmove+0x2c>
 4fa:	fff6079b          	addiw	a5,a2,-1
 4fe:	1782                	slli	a5,a5,0x20
 500:	9381                	srli	a5,a5,0x20
 502:	0785                	addi	a5,a5,1
 504:	97aa                	add	a5,a5,a0
  dst = vdst;
 506:	872a                	mv	a4,a0
      *dst++ = *src++;
 508:	0585                	addi	a1,a1,1
 50a:	0705                	addi	a4,a4,1
 50c:	fff5c683          	lbu	a3,-1(a1)
 510:	fed70fa3          	sb	a3,-1(a4) # ffffff <base+0xffefef>
    while(n-- > 0)
 514:	fee79ae3          	bne	a5,a4,508 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 518:	6422                	ld	s0,8(sp)
 51a:	0141                	addi	sp,sp,16
 51c:	8082                	ret
    dst += n;
 51e:	00c50733          	add	a4,a0,a2
    src += n;
 522:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 524:	fec05ae3          	blez	a2,518 <memmove+0x2c>
 528:	fff6079b          	addiw	a5,a2,-1
 52c:	1782                	slli	a5,a5,0x20
 52e:	9381                	srli	a5,a5,0x20
 530:	fff7c793          	not	a5,a5
 534:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 536:	15fd                	addi	a1,a1,-1
 538:	177d                	addi	a4,a4,-1
 53a:	0005c683          	lbu	a3,0(a1)
 53e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 542:	fee79ae3          	bne	a5,a4,536 <memmove+0x4a>
 546:	bfc9                	j	518 <memmove+0x2c>

0000000000000548 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 548:	1141                	addi	sp,sp,-16
 54a:	e422                	sd	s0,8(sp)
 54c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 54e:	ca05                	beqz	a2,57e <memcmp+0x36>
 550:	fff6069b          	addiw	a3,a2,-1
 554:	1682                	slli	a3,a3,0x20
 556:	9281                	srli	a3,a3,0x20
 558:	0685                	addi	a3,a3,1
 55a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 55c:	00054783          	lbu	a5,0(a0)
 560:	0005c703          	lbu	a4,0(a1)
 564:	00e79863          	bne	a5,a4,574 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 568:	0505                	addi	a0,a0,1
    p2++;
 56a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 56c:	fed518e3          	bne	a0,a3,55c <memcmp+0x14>
  }
  return 0;
 570:	4501                	li	a0,0
 572:	a019                	j	578 <memcmp+0x30>
      return *p1 - *p2;
 574:	40e7853b          	subw	a0,a5,a4
}
 578:	6422                	ld	s0,8(sp)
 57a:	0141                	addi	sp,sp,16
 57c:	8082                	ret
  return 0;
 57e:	4501                	li	a0,0
 580:	bfe5                	j	578 <memcmp+0x30>

0000000000000582 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 582:	1141                	addi	sp,sp,-16
 584:	e406                	sd	ra,8(sp)
 586:	e022                	sd	s0,0(sp)
 588:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 58a:	00000097          	auipc	ra,0x0
 58e:	f62080e7          	jalr	-158(ra) # 4ec <memmove>
}
 592:	60a2                	ld	ra,8(sp)
 594:	6402                	ld	s0,0(sp)
 596:	0141                	addi	sp,sp,16
 598:	8082                	ret

000000000000059a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 59a:	4885                	li	a7,1
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 5a2:	4889                	li	a7,2
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <wait>:
.global wait
wait:
 li a7, SYS_wait
 5aa:	488d                	li	a7,3
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 5b2:	4891                	li	a7,4
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <read>:
.global read
read:
 li a7, SYS_read
 5ba:	4895                	li	a7,5
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <write>:
.global write
write:
 li a7, SYS_write
 5c2:	48c1                	li	a7,16
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <close>:
.global close
close:
 li a7, SYS_close
 5ca:	48d5                	li	a7,21
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5d2:	4899                	li	a7,6
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <exec>:
.global exec
exec:
 li a7, SYS_exec
 5da:	489d                	li	a7,7
 ecall
 5dc:	00000073          	ecall
 ret
 5e0:	8082                	ret

00000000000005e2 <open>:
.global open
open:
 li a7, SYS_open
 5e2:	48bd                	li	a7,15
 ecall
 5e4:	00000073          	ecall
 ret
 5e8:	8082                	ret

00000000000005ea <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5ea:	48c5                	li	a7,17
 ecall
 5ec:	00000073          	ecall
 ret
 5f0:	8082                	ret

00000000000005f2 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5f2:	48c9                	li	a7,18
 ecall
 5f4:	00000073          	ecall
 ret
 5f8:	8082                	ret

00000000000005fa <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5fa:	48a1                	li	a7,8
 ecall
 5fc:	00000073          	ecall
 ret
 600:	8082                	ret

0000000000000602 <link>:
.global link
link:
 li a7, SYS_link
 602:	48cd                	li	a7,19
 ecall
 604:	00000073          	ecall
 ret
 608:	8082                	ret

000000000000060a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 60a:	48d1                	li	a7,20
 ecall
 60c:	00000073          	ecall
 ret
 610:	8082                	ret

0000000000000612 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 612:	48a5                	li	a7,9
 ecall
 614:	00000073          	ecall
 ret
 618:	8082                	ret

000000000000061a <dup>:
.global dup
dup:
 li a7, SYS_dup
 61a:	48a9                	li	a7,10
 ecall
 61c:	00000073          	ecall
 ret
 620:	8082                	ret

0000000000000622 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 622:	48ad                	li	a7,11
 ecall
 624:	00000073          	ecall
 ret
 628:	8082                	ret

000000000000062a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 62a:	48b1                	li	a7,12
 ecall
 62c:	00000073          	ecall
 ret
 630:	8082                	ret

0000000000000632 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 632:	48b5                	li	a7,13
 ecall
 634:	00000073          	ecall
 ret
 638:	8082                	ret

000000000000063a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 63a:	48b9                	li	a7,14
 ecall
 63c:	00000073          	ecall
 ret
 640:	8082                	ret

0000000000000642 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 642:	1101                	addi	sp,sp,-32
 644:	ec06                	sd	ra,24(sp)
 646:	e822                	sd	s0,16(sp)
 648:	1000                	addi	s0,sp,32
 64a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 64e:	4605                	li	a2,1
 650:	fef40593          	addi	a1,s0,-17
 654:	00000097          	auipc	ra,0x0
 658:	f6e080e7          	jalr	-146(ra) # 5c2 <write>
}
 65c:	60e2                	ld	ra,24(sp)
 65e:	6442                	ld	s0,16(sp)
 660:	6105                	addi	sp,sp,32
 662:	8082                	ret

0000000000000664 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 664:	7139                	addi	sp,sp,-64
 666:	fc06                	sd	ra,56(sp)
 668:	f822                	sd	s0,48(sp)
 66a:	f426                	sd	s1,40(sp)
 66c:	f04a                	sd	s2,32(sp)
 66e:	ec4e                	sd	s3,24(sp)
 670:	0080                	addi	s0,sp,64
 672:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 674:	c299                	beqz	a3,67a <printint+0x16>
 676:	0805c863          	bltz	a1,706 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 67a:	2581                	sext.w	a1,a1
  neg = 0;
 67c:	4881                	li	a7,0
 67e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 682:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 684:	2601                	sext.w	a2,a2
 686:	00000517          	auipc	a0,0x0
 68a:	5b250513          	addi	a0,a0,1458 # c38 <digits>
 68e:	883a                	mv	a6,a4
 690:	2705                	addiw	a4,a4,1
 692:	02c5f7bb          	remuw	a5,a1,a2
 696:	1782                	slli	a5,a5,0x20
 698:	9381                	srli	a5,a5,0x20
 69a:	97aa                	add	a5,a5,a0
 69c:	0007c783          	lbu	a5,0(a5)
 6a0:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6a4:	0005879b          	sext.w	a5,a1
 6a8:	02c5d5bb          	divuw	a1,a1,a2
 6ac:	0685                	addi	a3,a3,1
 6ae:	fec7f0e3          	bgeu	a5,a2,68e <printint+0x2a>
  if(neg)
 6b2:	00088b63          	beqz	a7,6c8 <printint+0x64>
    buf[i++] = '-';
 6b6:	fd040793          	addi	a5,s0,-48
 6ba:	973e                	add	a4,a4,a5
 6bc:	02d00793          	li	a5,45
 6c0:	fef70823          	sb	a5,-16(a4)
 6c4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6c8:	02e05863          	blez	a4,6f8 <printint+0x94>
 6cc:	fc040793          	addi	a5,s0,-64
 6d0:	00e78933          	add	s2,a5,a4
 6d4:	fff78993          	addi	s3,a5,-1
 6d8:	99ba                	add	s3,s3,a4
 6da:	377d                	addiw	a4,a4,-1
 6dc:	1702                	slli	a4,a4,0x20
 6de:	9301                	srli	a4,a4,0x20
 6e0:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6e4:	fff94583          	lbu	a1,-1(s2)
 6e8:	8526                	mv	a0,s1
 6ea:	00000097          	auipc	ra,0x0
 6ee:	f58080e7          	jalr	-168(ra) # 642 <putc>
  while(--i >= 0)
 6f2:	197d                	addi	s2,s2,-1
 6f4:	ff3918e3          	bne	s2,s3,6e4 <printint+0x80>
}
 6f8:	70e2                	ld	ra,56(sp)
 6fa:	7442                	ld	s0,48(sp)
 6fc:	74a2                	ld	s1,40(sp)
 6fe:	7902                	ld	s2,32(sp)
 700:	69e2                	ld	s3,24(sp)
 702:	6121                	addi	sp,sp,64
 704:	8082                	ret
    x = -xx;
 706:	40b005bb          	negw	a1,a1
    neg = 1;
 70a:	4885                	li	a7,1
    x = -xx;
 70c:	bf8d                	j	67e <printint+0x1a>

000000000000070e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 70e:	7119                	addi	sp,sp,-128
 710:	fc86                	sd	ra,120(sp)
 712:	f8a2                	sd	s0,112(sp)
 714:	f4a6                	sd	s1,104(sp)
 716:	f0ca                	sd	s2,96(sp)
 718:	ecce                	sd	s3,88(sp)
 71a:	e8d2                	sd	s4,80(sp)
 71c:	e4d6                	sd	s5,72(sp)
 71e:	e0da                	sd	s6,64(sp)
 720:	fc5e                	sd	s7,56(sp)
 722:	f862                	sd	s8,48(sp)
 724:	f466                	sd	s9,40(sp)
 726:	f06a                	sd	s10,32(sp)
 728:	ec6e                	sd	s11,24(sp)
 72a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 72c:	0005c903          	lbu	s2,0(a1)
 730:	18090f63          	beqz	s2,8ce <vprintf+0x1c0>
 734:	8aaa                	mv	s5,a0
 736:	8b32                	mv	s6,a2
 738:	00158493          	addi	s1,a1,1
  state = 0;
 73c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 73e:	02500a13          	li	s4,37
      if(c == 'd'){
 742:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 746:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 74a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 74e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 752:	00000b97          	auipc	s7,0x0
 756:	4e6b8b93          	addi	s7,s7,1254 # c38 <digits>
 75a:	a839                	j	778 <vprintf+0x6a>
        putc(fd, c);
 75c:	85ca                	mv	a1,s2
 75e:	8556                	mv	a0,s5
 760:	00000097          	auipc	ra,0x0
 764:	ee2080e7          	jalr	-286(ra) # 642 <putc>
 768:	a019                	j	76e <vprintf+0x60>
    } else if(state == '%'){
 76a:	01498f63          	beq	s3,s4,788 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 76e:	0485                	addi	s1,s1,1
 770:	fff4c903          	lbu	s2,-1(s1) # 40000fff <base+0x3fffffef>
 774:	14090d63          	beqz	s2,8ce <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 778:	0009079b          	sext.w	a5,s2
    if(state == 0){
 77c:	fe0997e3          	bnez	s3,76a <vprintf+0x5c>
      if(c == '%'){
 780:	fd479ee3          	bne	a5,s4,75c <vprintf+0x4e>
        state = '%';
 784:	89be                	mv	s3,a5
 786:	b7e5                	j	76e <vprintf+0x60>
      if(c == 'd'){
 788:	05878063          	beq	a5,s8,7c8 <vprintf+0xba>
      } else if(c == 'l') {
 78c:	05978c63          	beq	a5,s9,7e4 <vprintf+0xd6>
      } else if(c == 'x') {
 790:	07a78863          	beq	a5,s10,800 <vprintf+0xf2>
      } else if(c == 'p') {
 794:	09b78463          	beq	a5,s11,81c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 798:	07300713          	li	a4,115
 79c:	0ce78663          	beq	a5,a4,868 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 7a0:	06300713          	li	a4,99
 7a4:	0ee78e63          	beq	a5,a4,8a0 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 7a8:	11478863          	beq	a5,s4,8b8 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 7ac:	85d2                	mv	a1,s4
 7ae:	8556                	mv	a0,s5
 7b0:	00000097          	auipc	ra,0x0
 7b4:	e92080e7          	jalr	-366(ra) # 642 <putc>
        putc(fd, c);
 7b8:	85ca                	mv	a1,s2
 7ba:	8556                	mv	a0,s5
 7bc:	00000097          	auipc	ra,0x0
 7c0:	e86080e7          	jalr	-378(ra) # 642 <putc>
      }
      state = 0;
 7c4:	4981                	li	s3,0
 7c6:	b765                	j	76e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 7c8:	008b0913          	addi	s2,s6,8
 7cc:	4685                	li	a3,1
 7ce:	4629                	li	a2,10
 7d0:	000b2583          	lw	a1,0(s6)
 7d4:	8556                	mv	a0,s5
 7d6:	00000097          	auipc	ra,0x0
 7da:	e8e080e7          	jalr	-370(ra) # 664 <printint>
 7de:	8b4a                	mv	s6,s2
      state = 0;
 7e0:	4981                	li	s3,0
 7e2:	b771                	j	76e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7e4:	008b0913          	addi	s2,s6,8
 7e8:	4681                	li	a3,0
 7ea:	4629                	li	a2,10
 7ec:	000b2583          	lw	a1,0(s6)
 7f0:	8556                	mv	a0,s5
 7f2:	00000097          	auipc	ra,0x0
 7f6:	e72080e7          	jalr	-398(ra) # 664 <printint>
 7fa:	8b4a                	mv	s6,s2
      state = 0;
 7fc:	4981                	li	s3,0
 7fe:	bf85                	j	76e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 800:	008b0913          	addi	s2,s6,8
 804:	4681                	li	a3,0
 806:	4641                	li	a2,16
 808:	000b2583          	lw	a1,0(s6)
 80c:	8556                	mv	a0,s5
 80e:	00000097          	auipc	ra,0x0
 812:	e56080e7          	jalr	-426(ra) # 664 <printint>
 816:	8b4a                	mv	s6,s2
      state = 0;
 818:	4981                	li	s3,0
 81a:	bf91                	j	76e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 81c:	008b0793          	addi	a5,s6,8
 820:	f8f43423          	sd	a5,-120(s0)
 824:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 828:	03000593          	li	a1,48
 82c:	8556                	mv	a0,s5
 82e:	00000097          	auipc	ra,0x0
 832:	e14080e7          	jalr	-492(ra) # 642 <putc>
  putc(fd, 'x');
 836:	85ea                	mv	a1,s10
 838:	8556                	mv	a0,s5
 83a:	00000097          	auipc	ra,0x0
 83e:	e08080e7          	jalr	-504(ra) # 642 <putc>
 842:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 844:	03c9d793          	srli	a5,s3,0x3c
 848:	97de                	add	a5,a5,s7
 84a:	0007c583          	lbu	a1,0(a5)
 84e:	8556                	mv	a0,s5
 850:	00000097          	auipc	ra,0x0
 854:	df2080e7          	jalr	-526(ra) # 642 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 858:	0992                	slli	s3,s3,0x4
 85a:	397d                	addiw	s2,s2,-1
 85c:	fe0914e3          	bnez	s2,844 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 860:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 864:	4981                	li	s3,0
 866:	b721                	j	76e <vprintf+0x60>
        s = va_arg(ap, char*);
 868:	008b0993          	addi	s3,s6,8
 86c:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 870:	02090163          	beqz	s2,892 <vprintf+0x184>
        while(*s != 0){
 874:	00094583          	lbu	a1,0(s2)
 878:	c9a1                	beqz	a1,8c8 <vprintf+0x1ba>
          putc(fd, *s);
 87a:	8556                	mv	a0,s5
 87c:	00000097          	auipc	ra,0x0
 880:	dc6080e7          	jalr	-570(ra) # 642 <putc>
          s++;
 884:	0905                	addi	s2,s2,1
        while(*s != 0){
 886:	00094583          	lbu	a1,0(s2)
 88a:	f9e5                	bnez	a1,87a <vprintf+0x16c>
        s = va_arg(ap, char*);
 88c:	8b4e                	mv	s6,s3
      state = 0;
 88e:	4981                	li	s3,0
 890:	bdf9                	j	76e <vprintf+0x60>
          s = "(null)";
 892:	00000917          	auipc	s2,0x0
 896:	39e90913          	addi	s2,s2,926 # c30 <malloc+0x258>
        while(*s != 0){
 89a:	02800593          	li	a1,40
 89e:	bff1                	j	87a <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 8a0:	008b0913          	addi	s2,s6,8
 8a4:	000b4583          	lbu	a1,0(s6)
 8a8:	8556                	mv	a0,s5
 8aa:	00000097          	auipc	ra,0x0
 8ae:	d98080e7          	jalr	-616(ra) # 642 <putc>
 8b2:	8b4a                	mv	s6,s2
      state = 0;
 8b4:	4981                	li	s3,0
 8b6:	bd65                	j	76e <vprintf+0x60>
        putc(fd, c);
 8b8:	85d2                	mv	a1,s4
 8ba:	8556                	mv	a0,s5
 8bc:	00000097          	auipc	ra,0x0
 8c0:	d86080e7          	jalr	-634(ra) # 642 <putc>
      state = 0;
 8c4:	4981                	li	s3,0
 8c6:	b565                	j	76e <vprintf+0x60>
        s = va_arg(ap, char*);
 8c8:	8b4e                	mv	s6,s3
      state = 0;
 8ca:	4981                	li	s3,0
 8cc:	b54d                	j	76e <vprintf+0x60>
    }
  }
}
 8ce:	70e6                	ld	ra,120(sp)
 8d0:	7446                	ld	s0,112(sp)
 8d2:	74a6                	ld	s1,104(sp)
 8d4:	7906                	ld	s2,96(sp)
 8d6:	69e6                	ld	s3,88(sp)
 8d8:	6a46                	ld	s4,80(sp)
 8da:	6aa6                	ld	s5,72(sp)
 8dc:	6b06                	ld	s6,64(sp)
 8de:	7be2                	ld	s7,56(sp)
 8e0:	7c42                	ld	s8,48(sp)
 8e2:	7ca2                	ld	s9,40(sp)
 8e4:	7d02                	ld	s10,32(sp)
 8e6:	6de2                	ld	s11,24(sp)
 8e8:	6109                	addi	sp,sp,128
 8ea:	8082                	ret

00000000000008ec <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8ec:	715d                	addi	sp,sp,-80
 8ee:	ec06                	sd	ra,24(sp)
 8f0:	e822                	sd	s0,16(sp)
 8f2:	1000                	addi	s0,sp,32
 8f4:	e010                	sd	a2,0(s0)
 8f6:	e414                	sd	a3,8(s0)
 8f8:	e818                	sd	a4,16(s0)
 8fa:	ec1c                	sd	a5,24(s0)
 8fc:	03043023          	sd	a6,32(s0)
 900:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 904:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 908:	8622                	mv	a2,s0
 90a:	00000097          	auipc	ra,0x0
 90e:	e04080e7          	jalr	-508(ra) # 70e <vprintf>
}
 912:	60e2                	ld	ra,24(sp)
 914:	6442                	ld	s0,16(sp)
 916:	6161                	addi	sp,sp,80
 918:	8082                	ret

000000000000091a <printf>:

void
printf(const char *fmt, ...)
{
 91a:	711d                	addi	sp,sp,-96
 91c:	ec06                	sd	ra,24(sp)
 91e:	e822                	sd	s0,16(sp)
 920:	1000                	addi	s0,sp,32
 922:	e40c                	sd	a1,8(s0)
 924:	e810                	sd	a2,16(s0)
 926:	ec14                	sd	a3,24(s0)
 928:	f018                	sd	a4,32(s0)
 92a:	f41c                	sd	a5,40(s0)
 92c:	03043823          	sd	a6,48(s0)
 930:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 934:	00840613          	addi	a2,s0,8
 938:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 93c:	85aa                	mv	a1,a0
 93e:	4505                	li	a0,1
 940:	00000097          	auipc	ra,0x0
 944:	dce080e7          	jalr	-562(ra) # 70e <vprintf>
}
 948:	60e2                	ld	ra,24(sp)
 94a:	6442                	ld	s0,16(sp)
 94c:	6125                	addi	sp,sp,96
 94e:	8082                	ret

0000000000000950 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 950:	1141                	addi	sp,sp,-16
 952:	e422                	sd	s0,8(sp)
 954:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 956:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 95a:	00000797          	auipc	a5,0x0
 95e:	6a67b783          	ld	a5,1702(a5) # 1000 <freep>
 962:	a805                	j	992 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 964:	4618                	lw	a4,8(a2)
 966:	9db9                	addw	a1,a1,a4
 968:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 96c:	6398                	ld	a4,0(a5)
 96e:	6318                	ld	a4,0(a4)
 970:	fee53823          	sd	a4,-16(a0)
 974:	a091                	j	9b8 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 976:	ff852703          	lw	a4,-8(a0)
 97a:	9e39                	addw	a2,a2,a4
 97c:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 97e:	ff053703          	ld	a4,-16(a0)
 982:	e398                	sd	a4,0(a5)
 984:	a099                	j	9ca <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 986:	6398                	ld	a4,0(a5)
 988:	00e7e463          	bltu	a5,a4,990 <free+0x40>
 98c:	00e6ea63          	bltu	a3,a4,9a0 <free+0x50>
{
 990:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 992:	fed7fae3          	bgeu	a5,a3,986 <free+0x36>
 996:	6398                	ld	a4,0(a5)
 998:	00e6e463          	bltu	a3,a4,9a0 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 99c:	fee7eae3          	bltu	a5,a4,990 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 9a0:	ff852583          	lw	a1,-8(a0)
 9a4:	6390                	ld	a2,0(a5)
 9a6:	02059713          	slli	a4,a1,0x20
 9aa:	9301                	srli	a4,a4,0x20
 9ac:	0712                	slli	a4,a4,0x4
 9ae:	9736                	add	a4,a4,a3
 9b0:	fae60ae3          	beq	a2,a4,964 <free+0x14>
    bp->s.ptr = p->s.ptr;
 9b4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9b8:	4790                	lw	a2,8(a5)
 9ba:	02061713          	slli	a4,a2,0x20
 9be:	9301                	srli	a4,a4,0x20
 9c0:	0712                	slli	a4,a4,0x4
 9c2:	973e                	add	a4,a4,a5
 9c4:	fae689e3          	beq	a3,a4,976 <free+0x26>
  } else
    p->s.ptr = bp;
 9c8:	e394                	sd	a3,0(a5)
  freep = p;
 9ca:	00000717          	auipc	a4,0x0
 9ce:	62f73b23          	sd	a5,1590(a4) # 1000 <freep>
}
 9d2:	6422                	ld	s0,8(sp)
 9d4:	0141                	addi	sp,sp,16
 9d6:	8082                	ret

00000000000009d8 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9d8:	7139                	addi	sp,sp,-64
 9da:	fc06                	sd	ra,56(sp)
 9dc:	f822                	sd	s0,48(sp)
 9de:	f426                	sd	s1,40(sp)
 9e0:	f04a                	sd	s2,32(sp)
 9e2:	ec4e                	sd	s3,24(sp)
 9e4:	e852                	sd	s4,16(sp)
 9e6:	e456                	sd	s5,8(sp)
 9e8:	e05a                	sd	s6,0(sp)
 9ea:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9ec:	02051493          	slli	s1,a0,0x20
 9f0:	9081                	srli	s1,s1,0x20
 9f2:	04bd                	addi	s1,s1,15
 9f4:	8091                	srli	s1,s1,0x4
 9f6:	0014899b          	addiw	s3,s1,1
 9fa:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9fc:	00000517          	auipc	a0,0x0
 a00:	60453503          	ld	a0,1540(a0) # 1000 <freep>
 a04:	c515                	beqz	a0,a30 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a06:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a08:	4798                	lw	a4,8(a5)
 a0a:	02977f63          	bgeu	a4,s1,a48 <malloc+0x70>
 a0e:	8a4e                	mv	s4,s3
 a10:	0009871b          	sext.w	a4,s3
 a14:	6685                	lui	a3,0x1
 a16:	00d77363          	bgeu	a4,a3,a1c <malloc+0x44>
 a1a:	6a05                	lui	s4,0x1
 a1c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a20:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a24:	00000917          	auipc	s2,0x0
 a28:	5dc90913          	addi	s2,s2,1500 # 1000 <freep>
  if(p == (char*)-1)
 a2c:	5afd                	li	s5,-1
 a2e:	a88d                	j	aa0 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 a30:	00000797          	auipc	a5,0x0
 a34:	5e078793          	addi	a5,a5,1504 # 1010 <base>
 a38:	00000717          	auipc	a4,0x0
 a3c:	5cf73423          	sd	a5,1480(a4) # 1000 <freep>
 a40:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a42:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a46:	b7e1                	j	a0e <malloc+0x36>
      if(p->s.size == nunits)
 a48:	02e48b63          	beq	s1,a4,a7e <malloc+0xa6>
        p->s.size -= nunits;
 a4c:	4137073b          	subw	a4,a4,s3
 a50:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a52:	1702                	slli	a4,a4,0x20
 a54:	9301                	srli	a4,a4,0x20
 a56:	0712                	slli	a4,a4,0x4
 a58:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a5a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a5e:	00000717          	auipc	a4,0x0
 a62:	5aa73123          	sd	a0,1442(a4) # 1000 <freep>
      return (void*)(p + 1);
 a66:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a6a:	70e2                	ld	ra,56(sp)
 a6c:	7442                	ld	s0,48(sp)
 a6e:	74a2                	ld	s1,40(sp)
 a70:	7902                	ld	s2,32(sp)
 a72:	69e2                	ld	s3,24(sp)
 a74:	6a42                	ld	s4,16(sp)
 a76:	6aa2                	ld	s5,8(sp)
 a78:	6b02                	ld	s6,0(sp)
 a7a:	6121                	addi	sp,sp,64
 a7c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a7e:	6398                	ld	a4,0(a5)
 a80:	e118                	sd	a4,0(a0)
 a82:	bff1                	j	a5e <malloc+0x86>
  hp->s.size = nu;
 a84:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a88:	0541                	addi	a0,a0,16
 a8a:	00000097          	auipc	ra,0x0
 a8e:	ec6080e7          	jalr	-314(ra) # 950 <free>
  return freep;
 a92:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a96:	d971                	beqz	a0,a6a <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a98:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a9a:	4798                	lw	a4,8(a5)
 a9c:	fa9776e3          	bgeu	a4,s1,a48 <malloc+0x70>
    if(p == freep)
 aa0:	00093703          	ld	a4,0(s2)
 aa4:	853e                	mv	a0,a5
 aa6:	fef719e3          	bne	a4,a5,a98 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 aaa:	8552                	mv	a0,s4
 aac:	00000097          	auipc	ra,0x0
 ab0:	b7e080e7          	jalr	-1154(ra) # 62a <sbrk>
  if(p == (char*)-1)
 ab4:	fd5518e3          	bne	a0,s5,a84 <malloc+0xac>
        return 0;
 ab8:	4501                	li	a0,0
 aba:	bf45                	j	a6a <malloc+0x92>
