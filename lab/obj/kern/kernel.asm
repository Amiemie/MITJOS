
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 cc 17 f0       	mov    $0xf017cc50,%eax
f010004b:	2d 26 bd 17 f0       	sub    $0xf017bd26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 bd 17 f0       	push   $0xf017bd26
f0100058:	e8 1b 42 00 00       	call   f0104278 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 20 47 10 f0       	push   $0xf0104720
f010006f:	e8 fe 2e 00 00       	call   f0102f72 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 cf 0f 00 00       	call   f0101048 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 34 29 00 00       	call   f01029b2 <env_init>
	trap_init();
f010007e:	e8 60 2f 00 00       	call   f0102fe3 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 c6 0b 13 f0       	push   $0xf0130bc6
f010008d:	e8 eb 2a 00 00       	call   f0102b7d <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 8c bf 17 f0    	pushl  0xf017bf8c
f010009b:	e8 09 2e 00 00       	call   f0102ea9 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 cc 17 f0 00 	cmpl   $0x0,0xf017cc40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 cc 17 f0    	mov    %esi,0xf017cc40

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 3b 47 10 f0       	push   $0xf010473b
f01000ca:	e8 a3 2e 00 00       	call   f0102f72 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 73 2e 00 00       	call   f0102f4c <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 09 4f 10 f0 	movl   $0xf0104f09,(%esp)
f01000e0:	e8 8d 2e 00 00       	call   f0102f72 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 ea 06 00 00       	call   f01007dc <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 53 47 10 f0       	push   $0xf0104753
f010010c:	e8 61 2e 00 00       	call   f0102f72 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 2f 2e 00 00       	call   f0102f4c <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 09 4f 10 f0 	movl   $0xf0104f09,(%esp)
f0100124:	e8 49 2e 00 00       	call   f0102f72 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 bf 17 f0    	mov    0xf017bf64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 bf 17 f0    	mov    %edx,0xf017bf64
f010016e:	88 81 60 bd 17 f0    	mov    %al,-0xfe842a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 bf 17 f0 00 	movl   $0x0,0xf017bf64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f0 00 00 00    	je     f0100291 <kbd_proc_data+0xfe>
f01001a1:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a9:	3c e0                	cmp    $0xe0,%al
f01001ab:	75 0d                	jne    f01001ba <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001ad:	83 0d 40 bd 17 f0 40 	orl    $0x40,0xf017bd40
		return 0;
f01001b4:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b9:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c1:	84 c0                	test   %al,%al
f01001c3:	79 36                	jns    f01001fb <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c5:	8b 0d 40 bd 17 f0    	mov    0xf017bd40,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 c0 48 10 f0 	movzbl -0xfefb740(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 40 bd 17 f0       	mov    %eax,0xf017bd40
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 40 bd 17 f0    	mov    0xf017bd40,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 40 bd 17 f0    	mov    %ecx,0xf017bd40
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 c0 48 10 f0 	movzbl -0xfefb740(%edx),%eax
f010021e:	0b 05 40 bd 17 f0    	or     0xf017bd40,%eax
f0100224:	0f b6 8a c0 47 10 f0 	movzbl -0xfefb840(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 40 bd 17 f0       	mov    %eax,0xf017bd40

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d a0 47 10 f0 	mov    -0xfefb860(,%ecx,4),%ecx
f010023e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100242:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100245:	a8 08                	test   $0x8,%al
f0100247:	74 1b                	je     f0100264 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100249:	89 da                	mov    %ebx,%edx
f010024b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024e:	83 f9 19             	cmp    $0x19,%ecx
f0100251:	77 05                	ja     f0100258 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100253:	83 eb 20             	sub    $0x20,%ebx
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100258:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010025b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100264:	f7 d0                	not    %eax
f0100266:	a8 06                	test   $0x6,%al
f0100268:	75 2d                	jne    f0100297 <kbd_proc_data+0x104>
f010026a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100270:	75 25                	jne    f0100297 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100272:	83 ec 0c             	sub    $0xc,%esp
f0100275:	68 6d 47 10 f0       	push   $0xf010476d
f010027a:	e8 f3 2c 00 00       	call   f0102f72 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027f:	ba 92 00 00 00       	mov    $0x92,%edx
f0100284:	b8 03 00 00 00       	mov    $0x3,%eax
f0100289:	ee                   	out    %al,(%dx)
f010028a:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028d:	89 d8                	mov    %ebx,%eax
f010028f:	eb 08                	jmp    f0100299 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100296:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100297:	89 d8                	mov    %ebx,%eax
}
f0100299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029c:	c9                   	leave  
f010029d:	c3                   	ret    

f010029e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	57                   	push   %edi
f01002a2:	56                   	push   %esi
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 1c             	sub    $0x1c,%esp
f01002a7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ae:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b8:	eb 09                	jmp    f01002c3 <cons_putc+0x25>
f01002ba:	89 ca                	mov    %ecx,%edx
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c0:	83 c3 01             	add    $0x1,%ebx
f01002c3:	89 f2                	mov    %esi,%edx
f01002c5:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c6:	a8 20                	test   $0x20,%al
f01002c8:	75 08                	jne    f01002d2 <cons_putc+0x34>
f01002ca:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d0:	7e e8                	jle    f01002ba <cons_putc+0x1c>
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x59>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100300:	7f 04                	jg     f0100306 <cons_putc+0x68>
f0100302:	84 c0                	test   %al,%al
f0100304:	79 e8                	jns    f01002ee <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100321:	89 fa                	mov    %edi,%edx
f0100323:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100329:	89 f8                	mov    %edi,%eax
f010032b:	80 cc 07             	or     $0x7,%ah
f010032e:	85 d2                	test   %edx,%edx
f0100330:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100333:	89 f8                	mov    %edi,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	74 74                	je     f01003b1 <cons_putc+0x113>
f010033d:	83 f8 09             	cmp    $0x9,%eax
f0100340:	7f 0a                	jg     f010034c <cons_putc+0xae>
f0100342:	83 f8 08             	cmp    $0x8,%eax
f0100345:	74 14                	je     f010035b <cons_putc+0xbd>
f0100347:	e9 99 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
f010034c:	83 f8 0a             	cmp    $0xa,%eax
f010034f:	74 3a                	je     f010038b <cons_putc+0xed>
f0100351:	83 f8 0d             	cmp    $0xd,%eax
f0100354:	74 3d                	je     f0100393 <cons_putc+0xf5>
f0100356:	e9 8a 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010035b:	0f b7 05 68 bf 17 f0 	movzwl 0xf017bf68,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 68 bf 17 f0    	mov    %ax,0xf017bf68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 6c bf 17 f0    	mov    0xf017bf6c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 68 bf 17 f0 	addw   $0x50,0xf017bf68
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 68 bf 17 f0 	movzwl 0xf017bf68,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 68 bf 17 f0    	mov    %ax,0xf017bf68
f01003af:	eb 52                	jmp    f0100403 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b6:	e8 e3 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003bb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c0:	e8 d9 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003c5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ca:	e8 cf fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d4:	e8 c5 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003de:	e8 bb fe ff ff       	call   f010029e <cons_putc>
f01003e3:	eb 1e                	jmp    f0100403 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e5:	0f b7 05 68 bf 17 f0 	movzwl 0xf017bf68,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 68 bf 17 f0 	mov    %dx,0xf017bf68
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 6c bf 17 f0    	mov    0xf017bf6c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 68 bf 17 f0 	cmpw   $0x7cf,0xf017bf68
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 6c bf 17 f0       	mov    0xf017bf6c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 9d 3e 00 00       	call   f01042c5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 6c bf 17 f0    	mov    0xf017bf6c,%edx
f010042e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100434:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010043a:	83 c4 10             	add    $0x10,%esp
f010043d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100442:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100445:	39 d0                	cmp    %edx,%eax
f0100447:	75 f4                	jne    f010043d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 68 bf 17 f0 	subw   $0x50,0xf017bf68
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 70 bf 17 f0    	mov    0xf017bf70,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 68 bf 17 f0 	movzwl 0xf017bf68,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 74 bf 17 f0 00 	cmpb   $0x0,0xf017bf74
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f010049b:	e8 b0 fc ff ff       	call   f0100150 <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004ae:	e8 9d fc ff ff       	call   f0100150 <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 60 bf 17 f0       	mov    0xf017bf60,%eax
f01004ca:	3b 05 64 bf 17 f0    	cmp    0xf017bf64,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 60 bf 17 f0    	mov    %edx,0xf017bf60
f01004db:	0f b6 88 60 bd 17 f0 	movzbl -0xfe842a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 60 bf 17 f0 00 	movl   $0x0,0xf017bf60
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 70 bf 17 f0 b4 	movl   $0x3b4,0xf017bf70
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 70 bf 17 f0 d4 	movl   $0x3d4,0xf017bf70
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 3d 70 bf 17 f0    	mov    0xf017bf70,%edi
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 fa                	mov    %edi,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 c8             	movzbl %al,%ecx
f0100563:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 fa                	mov    %edi,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 35 6c bf 17 f0    	mov    %esi,0xf017bf6c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 68 bf 17 f0    	mov    %ax,0xf017bf68
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100587:	b8 00 00 00 00       	mov    $0x0,%eax
f010058c:	89 f2                	mov    %esi,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100594:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100599:	ee                   	out    %al,(%dx)
f010059a:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059f:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a4:	89 da                	mov    %ebx,%edx
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d8:	ec                   	in     (%dx),%al
f01005d9:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005db:	3c ff                	cmp    $0xff,%al
f01005dd:	0f 95 05 74 bf 17 f0 	setne  0xf017bf74
f01005e4:	89 f2                	mov    %esi,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005ea:	80 f9 ff             	cmp    $0xff,%cl
f01005ed:	75 10                	jne    f01005ff <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005ef:	83 ec 0c             	sub    $0xc,%esp
f01005f2:	68 79 47 10 f0       	push   $0xf0104779
f01005f7:	e8 76 29 00 00       	call   f0102f72 <cprintf>
f01005fc:	83 c4 10             	add    $0x10,%esp
}
f01005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100607:	55                   	push   %ebp
f0100608:	89 e5                	mov    %esp,%ebp
f010060a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010060d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100610:	e8 89 fc ff ff       	call   f010029e <cons_putc>
}
f0100615:	c9                   	leave  
f0100616:	c3                   	ret    

f0100617 <getchar>:

int
getchar(void)
{
f0100617:	55                   	push   %ebp
f0100618:	89 e5                	mov    %esp,%ebp
f010061a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010061d:	e8 93 fe ff ff       	call   f01004b5 <cons_getc>
f0100622:	85 c0                	test   %eax,%eax
f0100624:	74 f7                	je     f010061d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100626:	c9                   	leave  
f0100627:	c3                   	ret    

f0100628 <iscons>:

int
iscons(int fdnum)
{
f0100628:	55                   	push   %ebp
f0100629:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100630:	5d                   	pop    %ebp
f0100631:	c3                   	ret    

f0100632 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
f0100635:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100638:	68 c0 49 10 f0       	push   $0xf01049c0
f010063d:	68 de 49 10 f0       	push   $0xf01049de
f0100642:	68 e3 49 10 f0       	push   $0xf01049e3
f0100647:	e8 26 29 00 00       	call   f0102f72 <cprintf>
f010064c:	83 c4 0c             	add    $0xc,%esp
f010064f:	68 84 4a 10 f0       	push   $0xf0104a84
f0100654:	68 ec 49 10 f0       	push   $0xf01049ec
f0100659:	68 e3 49 10 f0       	push   $0xf01049e3
f010065e:	e8 0f 29 00 00       	call   f0102f72 <cprintf>
f0100663:	83 c4 0c             	add    $0xc,%esp
f0100666:	68 ac 4a 10 f0       	push   $0xf0104aac
f010066b:	68 f5 49 10 f0       	push   $0xf01049f5
f0100670:	68 e3 49 10 f0       	push   $0xf01049e3
f0100675:	e8 f8 28 00 00       	call   f0102f72 <cprintf>
	return 0;
}
f010067a:	b8 00 00 00 00       	mov    $0x0,%eax
f010067f:	c9                   	leave  
f0100680:	c3                   	ret    

f0100681 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100687:	68 ff 49 10 f0       	push   $0xf01049ff
f010068c:	e8 e1 28 00 00       	call   f0102f72 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100691:	83 c4 08             	add    $0x8,%esp
f0100694:	68 0c 00 10 00       	push   $0x10000c
f0100699:	68 d0 4a 10 f0       	push   $0xf0104ad0
f010069e:	e8 cf 28 00 00       	call   f0102f72 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 0c 00 10 00       	push   $0x10000c
f01006ab:	68 0c 00 10 f0       	push   $0xf010000c
f01006b0:	68 f8 4a 10 f0       	push   $0xf0104af8
f01006b5:	e8 b8 28 00 00       	call   f0102f72 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 01 47 10 00       	push   $0x104701
f01006c2:	68 01 47 10 f0       	push   $0xf0104701
f01006c7:	68 1c 4b 10 f0       	push   $0xf0104b1c
f01006cc:	e8 a1 28 00 00       	call   f0102f72 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 26 bd 17 00       	push   $0x17bd26
f01006d9:	68 26 bd 17 f0       	push   $0xf017bd26
f01006de:	68 40 4b 10 f0       	push   $0xf0104b40
f01006e3:	e8 8a 28 00 00       	call   f0102f72 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e8:	83 c4 0c             	add    $0xc,%esp
f01006eb:	68 50 cc 17 00       	push   $0x17cc50
f01006f0:	68 50 cc 17 f0       	push   $0xf017cc50
f01006f5:	68 64 4b 10 f0       	push   $0xf0104b64
f01006fa:	e8 73 28 00 00       	call   f0102f72 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006ff:	b8 4f d0 17 f0       	mov    $0xf017d04f,%eax
f0100704:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100709:	83 c4 08             	add    $0x8,%esp
f010070c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100711:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100717:	85 c0                	test   %eax,%eax
f0100719:	0f 48 c2             	cmovs  %edx,%eax
f010071c:	c1 f8 0a             	sar    $0xa,%eax
f010071f:	50                   	push   %eax
f0100720:	68 88 4b 10 f0       	push   $0xf0104b88
f0100725:	e8 48 28 00 00       	call   f0102f72 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010072a:	b8 00 00 00 00       	mov    $0x0,%eax
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100731:	55                   	push   %ebp
f0100732:	89 e5                	mov    %esp,%ebp
f0100734:	53                   	push   %ebx
f0100735:	83 ec 10             	sub    $0x10,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100738:	89 e8                	mov    %ebp,%eax
	//The ebp value of the program, which calls the mon_backtrace
	int regebp = read_ebp();
	regebp = *((int *)regebp);
	int *ebp = (int *)regebp;
f010073a:	8b 18                	mov    (%eax),%ebx
	
	cprintf("Stack backtrace:\n");
f010073c:	68 18 4a 10 f0       	push   $0xf0104a18
f0100741:	e8 2c 28 00 00       	call   f0102f72 <cprintf>
	//If only we haven't pass the stack frame of i386_init
	while((int)ebp != 0x0) {
f0100746:	83 c4 10             	add    $0x10,%esp
f0100749:	eb 7f                	jmp    f01007ca <mon_backtrace+0x99>
		cprintf("  ebp %08x", (int)ebp);
f010074b:	83 ec 08             	sub    $0x8,%esp
f010074e:	53                   	push   %ebx
f010074f:	68 2a 4a 10 f0       	push   $0xf0104a2a
f0100754:	e8 19 28 00 00       	call   f0102f72 <cprintf>
		cprintf("  eip %08x", *(ebp+1));
f0100759:	83 c4 08             	add    $0x8,%esp
f010075c:	ff 73 04             	pushl  0x4(%ebx)
f010075f:	68 35 4a 10 f0       	push   $0xf0104a35
f0100764:	e8 09 28 00 00       	call   f0102f72 <cprintf>
		cprintf("  args");
f0100769:	c7 04 24 40 4a 10 f0 	movl   $0xf0104a40,(%esp)
f0100770:	e8 fd 27 00 00       	call   f0102f72 <cprintf>
		cprintf(" %08x", *(ebp+2));
f0100775:	83 c4 08             	add    $0x8,%esp
f0100778:	ff 73 08             	pushl  0x8(%ebx)
f010077b:	68 2f 4a 10 f0       	push   $0xf0104a2f
f0100780:	e8 ed 27 00 00       	call   f0102f72 <cprintf>
		cprintf(" %08x", *(ebp+3));
f0100785:	83 c4 08             	add    $0x8,%esp
f0100788:	ff 73 0c             	pushl  0xc(%ebx)
f010078b:	68 2f 4a 10 f0       	push   $0xf0104a2f
f0100790:	e8 dd 27 00 00       	call   f0102f72 <cprintf>
		cprintf(" %08x", *(ebp+4));
f0100795:	83 c4 08             	add    $0x8,%esp
f0100798:	ff 73 10             	pushl  0x10(%ebx)
f010079b:	68 2f 4a 10 f0       	push   $0xf0104a2f
f01007a0:	e8 cd 27 00 00       	call   f0102f72 <cprintf>
		cprintf(" %08x", *(ebp+5));
f01007a5:	83 c4 08             	add    $0x8,%esp
f01007a8:	ff 73 14             	pushl  0x14(%ebx)
f01007ab:	68 2f 4a 10 f0       	push   $0xf0104a2f
f01007b0:	e8 bd 27 00 00       	call   f0102f72 <cprintf>
		cprintf(" %08x\n", *(ebp+6));
f01007b5:	83 c4 08             	add    $0x8,%esp
f01007b8:	ff 73 18             	pushl  0x18(%ebx)
f01007bb:	68 21 5c 10 f0       	push   $0xf0105c21
f01007c0:	e8 ad 27 00 00       	call   f0102f72 <cprintf>
		ebp = (int *)(*ebp);
f01007c5:	8b 1b                	mov    (%ebx),%ebx
f01007c7:	83 c4 10             	add    $0x10,%esp
	regebp = *((int *)regebp);
	int *ebp = (int *)regebp;
	
	cprintf("Stack backtrace:\n");
	//If only we haven't pass the stack frame of i386_init
	while((int)ebp != 0x0) {
f01007ca:	85 db                	test   %ebx,%ebx
f01007cc:	0f 85 79 ff ff ff    	jne    f010074b <mon_backtrace+0x1a>
		cprintf(" %08x", *(ebp+5));
		cprintf(" %08x\n", *(ebp+6));
		ebp = (int *)(*ebp);
	}
	return 0;
}
f01007d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01007da:	c9                   	leave  
f01007db:	c3                   	ret    

f01007dc <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007dc:	55                   	push   %ebp
f01007dd:	89 e5                	mov    %esp,%ebp
f01007df:	57                   	push   %edi
f01007e0:	56                   	push   %esi
f01007e1:	53                   	push   %ebx
f01007e2:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007e5:	68 b4 4b 10 f0       	push   $0xf0104bb4
f01007ea:	e8 83 27 00 00       	call   f0102f72 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007ef:	c7 04 24 d8 4b 10 f0 	movl   $0xf0104bd8,(%esp)
f01007f6:	e8 77 27 00 00       	call   f0102f72 <cprintf>

	if (tf != NULL)
f01007fb:	83 c4 10             	add    $0x10,%esp
f01007fe:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100802:	74 0e                	je     f0100812 <monitor+0x36>
		print_trapframe(tf);
f0100804:	83 ec 0c             	sub    $0xc,%esp
f0100807:	ff 75 08             	pushl  0x8(%ebp)
f010080a:	e8 9d 2b 00 00       	call   f01033ac <print_trapframe>
f010080f:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100812:	83 ec 0c             	sub    $0xc,%esp
f0100815:	68 47 4a 10 f0       	push   $0xf0104a47
f010081a:	e8 02 38 00 00       	call   f0104021 <readline>
f010081f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100821:	83 c4 10             	add    $0x10,%esp
f0100824:	85 c0                	test   %eax,%eax
f0100826:	74 ea                	je     f0100812 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100828:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010082f:	be 00 00 00 00       	mov    $0x0,%esi
f0100834:	eb 0a                	jmp    f0100840 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100836:	c6 03 00             	movb   $0x0,(%ebx)
f0100839:	89 f7                	mov    %esi,%edi
f010083b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010083e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100840:	0f b6 03             	movzbl (%ebx),%eax
f0100843:	84 c0                	test   %al,%al
f0100845:	74 63                	je     f01008aa <monitor+0xce>
f0100847:	83 ec 08             	sub    $0x8,%esp
f010084a:	0f be c0             	movsbl %al,%eax
f010084d:	50                   	push   %eax
f010084e:	68 4b 4a 10 f0       	push   $0xf0104a4b
f0100853:	e8 e3 39 00 00       	call   f010423b <strchr>
f0100858:	83 c4 10             	add    $0x10,%esp
f010085b:	85 c0                	test   %eax,%eax
f010085d:	75 d7                	jne    f0100836 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010085f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100862:	74 46                	je     f01008aa <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100864:	83 fe 0f             	cmp    $0xf,%esi
f0100867:	75 14                	jne    f010087d <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100869:	83 ec 08             	sub    $0x8,%esp
f010086c:	6a 10                	push   $0x10
f010086e:	68 50 4a 10 f0       	push   $0xf0104a50
f0100873:	e8 fa 26 00 00       	call   f0102f72 <cprintf>
f0100878:	83 c4 10             	add    $0x10,%esp
f010087b:	eb 95                	jmp    f0100812 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010087d:	8d 7e 01             	lea    0x1(%esi),%edi
f0100880:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100884:	eb 03                	jmp    f0100889 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100886:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100889:	0f b6 03             	movzbl (%ebx),%eax
f010088c:	84 c0                	test   %al,%al
f010088e:	74 ae                	je     f010083e <monitor+0x62>
f0100890:	83 ec 08             	sub    $0x8,%esp
f0100893:	0f be c0             	movsbl %al,%eax
f0100896:	50                   	push   %eax
f0100897:	68 4b 4a 10 f0       	push   $0xf0104a4b
f010089c:	e8 9a 39 00 00       	call   f010423b <strchr>
f01008a1:	83 c4 10             	add    $0x10,%esp
f01008a4:	85 c0                	test   %eax,%eax
f01008a6:	74 de                	je     f0100886 <monitor+0xaa>
f01008a8:	eb 94                	jmp    f010083e <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01008aa:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008b1:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b2:	85 f6                	test   %esi,%esi
f01008b4:	0f 84 58 ff ff ff    	je     f0100812 <monitor+0x36>
f01008ba:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008bf:	83 ec 08             	sub    $0x8,%esp
f01008c2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c5:	ff 34 85 00 4c 10 f0 	pushl  -0xfefb400(,%eax,4)
f01008cc:	ff 75 a8             	pushl  -0x58(%ebp)
f01008cf:	e8 09 39 00 00       	call   f01041dd <strcmp>
f01008d4:	83 c4 10             	add    $0x10,%esp
f01008d7:	85 c0                	test   %eax,%eax
f01008d9:	75 21                	jne    f01008fc <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01008db:	83 ec 04             	sub    $0x4,%esp
f01008de:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008e1:	ff 75 08             	pushl  0x8(%ebp)
f01008e4:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008e7:	52                   	push   %edx
f01008e8:	56                   	push   %esi
f01008e9:	ff 14 85 08 4c 10 f0 	call   *-0xfefb3f8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008f0:	83 c4 10             	add    $0x10,%esp
f01008f3:	85 c0                	test   %eax,%eax
f01008f5:	78 25                	js     f010091c <monitor+0x140>
f01008f7:	e9 16 ff ff ff       	jmp    f0100812 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008fc:	83 c3 01             	add    $0x1,%ebx
f01008ff:	83 fb 03             	cmp    $0x3,%ebx
f0100902:	75 bb                	jne    f01008bf <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100904:	83 ec 08             	sub    $0x8,%esp
f0100907:	ff 75 a8             	pushl  -0x58(%ebp)
f010090a:	68 6d 4a 10 f0       	push   $0xf0104a6d
f010090f:	e8 5e 26 00 00       	call   f0102f72 <cprintf>
f0100914:	83 c4 10             	add    $0x10,%esp
f0100917:	e9 f6 fe ff ff       	jmp    f0100812 <monitor+0x36>
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}

}
f010091c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010091f:	5b                   	pop    %ebx
f0100920:	5e                   	pop    %esi
f0100921:	5f                   	pop    %edi
f0100922:	5d                   	pop    %ebp
f0100923:	c3                   	ret    

f0100924 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100924:	55                   	push   %ebp
f0100925:	89 e5                	mov    %esp,%ebp
f0100927:	53                   	push   %ebx
f0100928:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010092b:	83 3d 78 bf 17 f0 00 	cmpl   $0x0,0xf017bf78
f0100932:	75 11                	jne    f0100945 <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100934:	ba 4f dc 17 f0       	mov    $0xf017dc4f,%edx
f0100939:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010093f:	89 15 78 bf 17 f0    	mov    %edx,0xf017bf78
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100945:	8b 1d 78 bf 17 f0    	mov    0xf017bf78,%ebx
	nextfree = ROUNDUP(nextfree+n, PGSIZE);
f010094b:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f0100952:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100958:	89 15 78 bf 17 f0    	mov    %edx,0xf017bf78
	if((uint32_t)nextfree-KERNBASE > (npages * PGSIZE)) {
f010095e:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100964:	8b 0d 44 cc 17 f0    	mov    0xf017cc44,%ecx
f010096a:	c1 e1 0c             	shl    $0xc,%ecx
f010096d:	39 ca                	cmp    %ecx,%edx
f010096f:	76 14                	jbe    f0100985 <boot_alloc+0x61>
		panic("Out of memory!\n");
f0100971:	83 ec 04             	sub    $0x4,%esp
f0100974:	68 24 4c 10 f0       	push   $0xf0104c24
f0100979:	6a 69                	push   $0x69
f010097b:	68 34 4c 10 f0       	push   $0xf0104c34
f0100980:	e8 1b f7 ff ff       	call   f01000a0 <_panic>
	}
	return result;
}
f0100985:	89 d8                	mov    %ebx,%eax
f0100987:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010098a:	c9                   	leave  
f010098b:	c3                   	ret    

f010098c <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010098c:	89 d1                	mov    %edx,%ecx
f010098e:	c1 e9 16             	shr    $0x16,%ecx
f0100991:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100994:	a8 01                	test   $0x1,%al
f0100996:	74 52                	je     f01009ea <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100998:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010099d:	89 c1                	mov    %eax,%ecx
f010099f:	c1 e9 0c             	shr    $0xc,%ecx
f01009a2:	3b 0d 44 cc 17 f0    	cmp    0xf017cc44,%ecx
f01009a8:	72 1b                	jb     f01009c5 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009aa:	55                   	push   %ebp
f01009ab:	89 e5                	mov    %esp,%ebp
f01009ad:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009b0:	50                   	push   %eax
f01009b1:	68 3c 4f 10 f0       	push   $0xf0104f3c
f01009b6:	68 39 03 00 00       	push   $0x339
f01009bb:	68 34 4c 10 f0       	push   $0xf0104c34
f01009c0:	e8 db f6 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009c5:	c1 ea 0c             	shr    $0xc,%edx
f01009c8:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009ce:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009d5:	89 c2                	mov    %eax,%edx
f01009d7:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009da:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009df:	85 d2                	test   %edx,%edx
f01009e1:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009e6:	0f 44 c2             	cmove  %edx,%eax
f01009e9:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009ef:	c3                   	ret    

f01009f0 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009f0:	55                   	push   %ebp
f01009f1:	89 e5                	mov    %esp,%ebp
f01009f3:	57                   	push   %edi
f01009f4:	56                   	push   %esi
f01009f5:	53                   	push   %ebx
f01009f6:	83 ec 2c             	sub    $0x2c,%esp
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009f9:	84 c0                	test   %al,%al
f01009fb:	0f 85 72 02 00 00    	jne    f0100c73 <check_page_free_list+0x283>
f0100a01:	e9 7f 02 00 00       	jmp    f0100c85 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a06:	83 ec 04             	sub    $0x4,%esp
f0100a09:	68 60 4f 10 f0       	push   $0xf0104f60
f0100a0e:	68 74 02 00 00       	push   $0x274
f0100a13:	68 34 4c 10 f0       	push   $0xf0104c34
f0100a18:	e8 83 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a1d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a20:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a23:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a26:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a29:	89 c2                	mov    %eax,%edx
f0100a2b:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f0100a31:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a37:	0f 95 c2             	setne  %dl
f0100a3a:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a3d:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a41:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a43:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a47:	8b 00                	mov    (%eax),%eax
f0100a49:	85 c0                	test   %eax,%eax
f0100a4b:	75 dc                	jne    f0100a29 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a50:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a56:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a59:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a5c:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a5e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a61:	a3 80 bf 17 f0       	mov    %eax,0xf017bf80
check_page_free_list(bool only_low_memory)
{
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a66:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a6b:	8b 1d 80 bf 17 f0    	mov    0xf017bf80,%ebx
f0100a71:	eb 53                	jmp    f0100ac6 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a73:	89 d8                	mov    %ebx,%eax
f0100a75:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0100a7b:	c1 f8 03             	sar    $0x3,%eax
f0100a7e:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a81:	89 c2                	mov    %eax,%edx
f0100a83:	c1 ea 16             	shr    $0x16,%edx
f0100a86:	39 f2                	cmp    %esi,%edx
f0100a88:	73 3a                	jae    f0100ac4 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a8a:	89 c2                	mov    %eax,%edx
f0100a8c:	c1 ea 0c             	shr    $0xc,%edx
f0100a8f:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0100a95:	72 12                	jb     f0100aa9 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a97:	50                   	push   %eax
f0100a98:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0100a9d:	6a 56                	push   $0x56
f0100a9f:	68 40 4c 10 f0       	push   $0xf0104c40
f0100aa4:	e8 f7 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aa9:	83 ec 04             	sub    $0x4,%esp
f0100aac:	68 80 00 00 00       	push   $0x80
f0100ab1:	68 97 00 00 00       	push   $0x97
f0100ab6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100abb:	50                   	push   %eax
f0100abc:	e8 b7 37 00 00       	call   f0104278 <memset>
f0100ac1:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ac4:	8b 1b                	mov    (%ebx),%ebx
f0100ac6:	85 db                	test   %ebx,%ebx
f0100ac8:	75 a9                	jne    f0100a73 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100aca:	b8 00 00 00 00       	mov    $0x0,%eax
f0100acf:	e8 50 fe ff ff       	call   f0100924 <boot_alloc>
f0100ad4:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ad7:	8b 15 80 bf 17 f0    	mov    0xf017bf80,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100add:	8b 0d 4c cc 17 f0    	mov    0xf017cc4c,%ecx
		assert(pp < pages + npages);
f0100ae3:	a1 44 cc 17 f0       	mov    0xf017cc44,%eax
f0100ae8:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100aeb:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aee:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
{
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100af1:	be 00 00 00 00       	mov    $0x0,%esi
f0100af6:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100af9:	e9 30 01 00 00       	jmp    f0100c2e <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100afe:	39 ca                	cmp    %ecx,%edx
f0100b00:	73 19                	jae    f0100b1b <check_page_free_list+0x12b>
f0100b02:	68 4e 4c 10 f0       	push   $0xf0104c4e
f0100b07:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100b0c:	68 91 02 00 00       	push   $0x291
f0100b11:	68 34 4c 10 f0       	push   $0xf0104c34
f0100b16:	e8 85 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b1b:	39 fa                	cmp    %edi,%edx
f0100b1d:	72 19                	jb     f0100b38 <check_page_free_list+0x148>
f0100b1f:	68 6f 4c 10 f0       	push   $0xf0104c6f
f0100b24:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100b29:	68 92 02 00 00       	push   $0x292
f0100b2e:	68 34 4c 10 f0       	push   $0xf0104c34
f0100b33:	e8 68 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b38:	89 d0                	mov    %edx,%eax
f0100b3a:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b3d:	a8 07                	test   $0x7,%al
f0100b3f:	74 19                	je     f0100b5a <check_page_free_list+0x16a>
f0100b41:	68 84 4f 10 f0       	push   $0xf0104f84
f0100b46:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100b4b:	68 93 02 00 00       	push   $0x293
f0100b50:	68 34 4c 10 f0       	push   $0xf0104c34
f0100b55:	e8 46 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b5a:	c1 f8 03             	sar    $0x3,%eax
f0100b5d:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b60:	85 c0                	test   %eax,%eax
f0100b62:	75 19                	jne    f0100b7d <check_page_free_list+0x18d>
f0100b64:	68 83 4c 10 f0       	push   $0xf0104c83
f0100b69:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100b6e:	68 96 02 00 00       	push   $0x296
f0100b73:	68 34 4c 10 f0       	push   $0xf0104c34
f0100b78:	e8 23 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b7d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b82:	75 19                	jne    f0100b9d <check_page_free_list+0x1ad>
f0100b84:	68 94 4c 10 f0       	push   $0xf0104c94
f0100b89:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100b8e:	68 97 02 00 00       	push   $0x297
f0100b93:	68 34 4c 10 f0       	push   $0xf0104c34
f0100b98:	e8 03 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b9d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ba2:	75 19                	jne    f0100bbd <check_page_free_list+0x1cd>
f0100ba4:	68 b8 4f 10 f0       	push   $0xf0104fb8
f0100ba9:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100bae:	68 98 02 00 00       	push   $0x298
f0100bb3:	68 34 4c 10 f0       	push   $0xf0104c34
f0100bb8:	e8 e3 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bbd:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bc2:	75 19                	jne    f0100bdd <check_page_free_list+0x1ed>
f0100bc4:	68 ad 4c 10 f0       	push   $0xf0104cad
f0100bc9:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100bce:	68 99 02 00 00       	push   $0x299
f0100bd3:	68 34 4c 10 f0       	push   $0xf0104c34
f0100bd8:	e8 c3 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bdd:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100be2:	76 3f                	jbe    f0100c23 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100be4:	89 c3                	mov    %eax,%ebx
f0100be6:	c1 eb 0c             	shr    $0xc,%ebx
f0100be9:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bec:	77 12                	ja     f0100c00 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bee:	50                   	push   %eax
f0100bef:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0100bf4:	6a 56                	push   $0x56
f0100bf6:	68 40 4c 10 f0       	push   $0xf0104c40
f0100bfb:	e8 a0 f4 ff ff       	call   f01000a0 <_panic>
f0100c00:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c05:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c08:	76 1e                	jbe    f0100c28 <check_page_free_list+0x238>
f0100c0a:	68 dc 4f 10 f0       	push   $0xf0104fdc
f0100c0f:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100c14:	68 9a 02 00 00       	push   $0x29a
f0100c19:	68 34 4c 10 f0       	push   $0xf0104c34
f0100c1e:	e8 7d f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c23:	83 c6 01             	add    $0x1,%esi
f0100c26:	eb 04                	jmp    f0100c2c <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c28:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c2c:	8b 12                	mov    (%edx),%edx
f0100c2e:	85 d2                	test   %edx,%edx
f0100c30:	0f 85 c8 fe ff ff    	jne    f0100afe <check_page_free_list+0x10e>
f0100c36:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c39:	85 f6                	test   %esi,%esi
f0100c3b:	7f 19                	jg     f0100c56 <check_page_free_list+0x266>
f0100c3d:	68 c7 4c 10 f0       	push   $0xf0104cc7
f0100c42:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100c47:	68 a2 02 00 00       	push   $0x2a2
f0100c4c:	68 34 4c 10 f0       	push   $0xf0104c34
f0100c51:	e8 4a f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c56:	85 db                	test   %ebx,%ebx
f0100c58:	7f 42                	jg     f0100c9c <check_page_free_list+0x2ac>
f0100c5a:	68 d9 4c 10 f0       	push   $0xf0104cd9
f0100c5f:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100c64:	68 a3 02 00 00       	push   $0x2a3
f0100c69:	68 34 4c 10 f0       	push   $0xf0104c34
f0100c6e:	e8 2d f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c73:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f0100c78:	85 c0                	test   %eax,%eax
f0100c7a:	0f 85 9d fd ff ff    	jne    f0100a1d <check_page_free_list+0x2d>
f0100c80:	e9 81 fd ff ff       	jmp    f0100a06 <check_page_free_list+0x16>
f0100c85:	83 3d 80 bf 17 f0 00 	cmpl   $0x0,0xf017bf80
f0100c8c:	0f 84 74 fd ff ff    	je     f0100a06 <check_page_free_list+0x16>
check_page_free_list(bool only_low_memory)
{
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c92:	be 00 04 00 00       	mov    $0x400,%esi
f0100c97:	e9 cf fd ff ff       	jmp    f0100a6b <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c9c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c9f:	5b                   	pop    %ebx
f0100ca0:	5e                   	pop    %esi
f0100ca1:	5f                   	pop    %edi
f0100ca2:	5d                   	pop    %ebp
f0100ca3:	c3                   	ret    

f0100ca4 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ca4:	55                   	push   %ebp
f0100ca5:	89 e5                	mov    %esp,%ebp
f0100ca7:	57                   	push   %edi
f0100ca8:	56                   	push   %esi
f0100ca9:	53                   	push   %ebx
f0100caa:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f0100cad:	c7 05 80 bf 17 f0 00 	movl   $0x0,0xf017bf80
f0100cb4:	00 00 00 
//	cprintf("kern_pgdir locates at %p\n", kern_pgdir);
//	cprintf("pages locates at %p\n", pages);
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
f0100cb7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cbc:	e8 63 fc ff ff       	call   f0100924 <boot_alloc>
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
		if(i == 0){       //Physical page 0 is in use.
			pages[i].pp_ref = 1;
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f0100cc1:	8b 35 84 bf 17 f0    	mov    0xf017bf84,%esi
f0100cc7:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ccc:	c1 e8 0c             	shr    $0xc,%eax
f0100ccf:	8d 7c 06 60          	lea    0x60(%esi,%eax,1),%edi
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
	int num_iohole = 96;
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
f0100cd3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100cd8:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cdd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ce2:	eb 50                	jmp    f0100d34 <page_init+0x90>
		if(i == 0){       //Physical page 0 is in use.
f0100ce4:	85 c0                	test   %eax,%eax
f0100ce6:	75 0e                	jne    f0100cf6 <page_init+0x52>
			pages[i].pp_ref = 1;
f0100ce8:	8b 15 4c cc 17 f0    	mov    0xf017cc4c,%edx
f0100cee:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
f0100cf4:	eb 3b                	jmp    f0100d31 <page_init+0x8d>
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f0100cf6:	39 f0                	cmp    %esi,%eax
f0100cf8:	72 13                	jb     f0100d0d <page_init+0x69>
f0100cfa:	39 f8                	cmp    %edi,%eax
f0100cfc:	73 0f                	jae    f0100d0d <page_init+0x69>
			pages[i].pp_ref = 1;
f0100cfe:	8b 15 4c cc 17 f0    	mov    0xf017cc4c,%edx
f0100d04:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
f0100d0b:	eb 24                	jmp    f0100d31 <page_init+0x8d>
f0100d0d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		}
		else {
			pages[i].pp_ref = 0;
f0100d14:	89 d1                	mov    %edx,%ecx
f0100d16:	03 0d 4c cc 17 f0    	add    0xf017cc4c,%ecx
f0100d1c:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0100d22:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0100d24:	89 d3                	mov    %edx,%ebx
f0100d26:	03 1d 4c cc 17 f0    	add    0xf017cc4c,%ebx
f0100d2c:	b9 01 00 00 00       	mov    $0x1,%ecx
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
	int num_iohole = 96;
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
f0100d31:	83 c0 01             	add    $0x1,%eax
f0100d34:	3b 05 44 cc 17 f0    	cmp    0xf017cc44,%eax
f0100d3a:	72 a8                	jb     f0100ce4 <page_init+0x40>
f0100d3c:	84 c9                	test   %cl,%cl
f0100d3e:	74 06                	je     f0100d46 <page_init+0xa2>
f0100d40:	89 1d 80 bf 17 f0    	mov    %ebx,0xf017bf80
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d46:	83 c4 0c             	add    $0xc,%esp
f0100d49:	5b                   	pop    %ebx
f0100d4a:	5e                   	pop    %esi
f0100d4b:	5f                   	pop    %edi
f0100d4c:	5d                   	pop    %ebp
f0100d4d:	c3                   	ret    

f0100d4e <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d4e:	55                   	push   %ebp
f0100d4f:	89 e5                	mov    %esp,%ebp
f0100d51:	53                   	push   %ebx
f0100d52:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo * result = page_free_list;
f0100d55:	8b 1d 80 bf 17 f0    	mov    0xf017bf80,%ebx
	if(page_free_list == NULL)
f0100d5b:	85 db                	test   %ebx,%ebx
f0100d5d:	74 5c                	je     f0100dbb <page_alloc+0x6d>
		return NULL;
	page_free_list = page_free_list->pp_link;
f0100d5f:	8b 03                	mov    (%ebx),%eax
f0100d61:	a3 80 bf 17 f0       	mov    %eax,0xf017bf80

	result->pp_link = NULL;
f0100d66:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
		memset(page2kva(result), 0, PGSIZE);
	return result;
f0100d6c:	89 d8                	mov    %ebx,%eax
	if(page_free_list == NULL)
		return NULL;
	page_free_list = page_free_list->pp_link;

	result->pp_link = NULL;
	if(alloc_flags & ALLOC_ZERO)
f0100d6e:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d72:	74 4c                	je     f0100dc0 <page_alloc+0x72>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d74:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0100d7a:	c1 f8 03             	sar    $0x3,%eax
f0100d7d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d80:	89 c2                	mov    %eax,%edx
f0100d82:	c1 ea 0c             	shr    $0xc,%edx
f0100d85:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0100d8b:	72 12                	jb     f0100d9f <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d8d:	50                   	push   %eax
f0100d8e:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0100d93:	6a 56                	push   $0x56
f0100d95:	68 40 4c 10 f0       	push   $0xf0104c40
f0100d9a:	e8 01 f3 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(result), 0, PGSIZE);
f0100d9f:	83 ec 04             	sub    $0x4,%esp
f0100da2:	68 00 10 00 00       	push   $0x1000
f0100da7:	6a 00                	push   $0x0
f0100da9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dae:	50                   	push   %eax
f0100daf:	e8 c4 34 00 00       	call   f0104278 <memset>
f0100db4:	83 c4 10             	add    $0x10,%esp
	return result;
f0100db7:	89 d8                	mov    %ebx,%eax
f0100db9:	eb 05                	jmp    f0100dc0 <page_alloc+0x72>
page_alloc(int alloc_flags)
{
	// Fill this function in
	struct PageInfo * result = page_free_list;
	if(page_free_list == NULL)
		return NULL;
f0100dbb:	b8 00 00 00 00       	mov    $0x0,%eax

	result->pp_link = NULL;
	if(alloc_flags & ALLOC_ZERO)
		memset(page2kva(result), 0, PGSIZE);
	return result;
}
f0100dc0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dc3:	c9                   	leave  
f0100dc4:	c3                   	ret    

f0100dc5 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100dc5:	55                   	push   %ebp
f0100dc6:	89 e5                	mov    %esp,%ebp
f0100dc8:	83 ec 08             	sub    $0x8,%esp
f0100dcb:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp->pp_ref == 0);
f0100dce:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100dd3:	74 19                	je     f0100dee <page_free+0x29>
f0100dd5:	68 ea 4c 10 f0       	push   $0xf0104cea
f0100dda:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100ddf:	68 51 01 00 00       	push   $0x151
f0100de4:	68 34 4c 10 f0       	push   $0xf0104c34
f0100de9:	e8 b2 f2 ff ff       	call   f01000a0 <_panic>
	assert(pp->pp_link == NULL);
f0100dee:	83 38 00             	cmpl   $0x0,(%eax)
f0100df1:	74 19                	je     f0100e0c <page_free+0x47>
f0100df3:	68 fa 4c 10 f0       	push   $0xf0104cfa
f0100df8:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0100dfd:	68 52 01 00 00       	push   $0x152
f0100e02:	68 34 4c 10 f0       	push   $0xf0104c34
f0100e07:	e8 94 f2 ff ff       	call   f01000a0 <_panic>

	pp->pp_link = page_free_list;
f0100e0c:	8b 15 80 bf 17 f0    	mov    0xf017bf80,%edx
f0100e12:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e14:	a3 80 bf 17 f0       	mov    %eax,0xf017bf80
}
f0100e19:	c9                   	leave  
f0100e1a:	c3                   	ret    

f0100e1b <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e1b:	55                   	push   %ebp
f0100e1c:	89 e5                	mov    %esp,%ebp
f0100e1e:	83 ec 08             	sub    $0x8,%esp
f0100e21:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e24:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e28:	83 e8 01             	sub    $0x1,%eax
f0100e2b:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e2f:	66 85 c0             	test   %ax,%ax
f0100e32:	75 0c                	jne    f0100e40 <page_decref+0x25>
		page_free(pp);
f0100e34:	83 ec 0c             	sub    $0xc,%esp
f0100e37:	52                   	push   %edx
f0100e38:	e8 88 ff ff ff       	call   f0100dc5 <page_free>
f0100e3d:	83 c4 10             	add    $0x10,%esp
}
f0100e40:	c9                   	leave  
f0100e41:	c3                   	ret    

f0100e42 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e42:	55                   	push   %ebp
f0100e43:	89 e5                	mov    %esp,%ebp
f0100e45:	56                   	push   %esi
f0100e46:	53                   	push   %ebx
f0100e47:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	unsigned int page_off;
	pte_t *page_base = NULL;
	struct PageInfo* new_page = NULL;
	unsigned int dic_off = PDX(va); 						 //The page directory index of this page table page.
	pde_t *dic_entry_ptr = pgdir + dic_off;        //The page directory entry of this page table page.
f0100e4a:	89 f3                	mov    %esi,%ebx
f0100e4c:	c1 eb 16             	shr    $0x16,%ebx
f0100e4f:	c1 e3 02             	shl    $0x2,%ebx
f0100e52:	03 5d 08             	add    0x8(%ebp),%ebx
	if( !(*dic_entry_ptr) & PTE_P )                        //If this page table page exists.
f0100e55:	83 3b 00             	cmpl   $0x0,(%ebx)
f0100e58:	75 2d                	jne    f0100e87 <pgdir_walk+0x45>
	{
		if(create)								 //If create is true, then create a new page table page.
f0100e5a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e5e:	74 62                	je     f0100ec2 <pgdir_walk+0x80>
		{
			new_page = page_alloc(1);
f0100e60:	83 ec 0c             	sub    $0xc,%esp
f0100e63:	6a 01                	push   $0x1
f0100e65:	e8 e4 fe ff ff       	call   f0100d4e <page_alloc>
			if(new_page == NULL) return NULL;    //Allocation failed.
f0100e6a:	83 c4 10             	add    $0x10,%esp
f0100e6d:	85 c0                	test   %eax,%eax
f0100e6f:	74 58                	je     f0100ec9 <pgdir_walk+0x87>
			new_page->pp_ref++;
f0100e71:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
f0100e76:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0100e7c:	c1 f8 03             	sar    $0x3,%eax
f0100e7f:	c1 e0 0c             	shl    $0xc,%eax
f0100e82:	83 c8 07             	or     $0x7,%eax
f0100e85:	89 03                	mov    %eax,(%ebx)
		}
		else
			return NULL; 
	}	
	page_off = PTX(va);						 //The page table index of this page.
f0100e87:	c1 ee 0c             	shr    $0xc,%esi
f0100e8a:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0100e90:	8b 03                	mov    (%ebx),%eax
f0100e92:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e97:	89 c2                	mov    %eax,%edx
f0100e99:	c1 ea 0c             	shr    $0xc,%edx
f0100e9c:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0100ea2:	72 15                	jb     f0100eb9 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ea4:	50                   	push   %eax
f0100ea5:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0100eaa:	68 8f 01 00 00       	push   $0x18f
f0100eaf:	68 34 4c 10 f0       	push   $0xf0104c34
f0100eb4:	e8 e7 f1 ff ff       	call   f01000a0 <_panic>
	return &page_base[page_off];
f0100eb9:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100ec0:	eb 0c                	jmp    f0100ece <pgdir_walk+0x8c>
			if(new_page == NULL) return NULL;    //Allocation failed.
			new_page->pp_ref++;
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
		}
		else
			return NULL; 
f0100ec2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ec7:	eb 05                	jmp    f0100ece <pgdir_walk+0x8c>
	if( !(*dic_entry_ptr) & PTE_P )                        //If this page table page exists.
	{
		if(create)								 //If create is true, then create a new page table page.
		{
			new_page = page_alloc(1);
			if(new_page == NULL) return NULL;    //Allocation failed.
f0100ec9:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL; 
	}	
	page_off = PTX(va);						 //The page table index of this page.
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
	return &page_base[page_off];
}
f0100ece:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ed1:	5b                   	pop    %ebx
f0100ed2:	5e                   	pop    %esi
f0100ed3:	5d                   	pop    %ebp
f0100ed4:	c3                   	ret    

f0100ed5 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ed5:	55                   	push   %ebp
f0100ed6:	89 e5                	mov    %esp,%ebp
f0100ed8:	57                   	push   %edi
f0100ed9:	56                   	push   %esi
f0100eda:	53                   	push   %ebx
f0100edb:	83 ec 1c             	sub    $0x1c,%esp
f0100ede:	89 c7                	mov    %eax,%edi
f0100ee0:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ee3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100ee6:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
		*entry = (pa | perm | PTE_P);
f0100eeb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eee:	83 c8 01             	or     $0x1,%eax
f0100ef1:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100ef4:	eb 1f                	jmp    f0100f15 <boot_map_region+0x40>
	{
		entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
f0100ef6:	83 ec 04             	sub    $0x4,%esp
f0100ef9:	6a 01                	push   $0x1
f0100efb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100efe:	01 d8                	add    %ebx,%eax
f0100f00:	50                   	push   %eax
f0100f01:	57                   	push   %edi
f0100f02:	e8 3b ff ff ff       	call   f0100e42 <pgdir_walk>
		*entry = (pa | perm | PTE_P);
f0100f07:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100f0a:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100f0c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f12:	83 c4 10             	add    $0x10,%esp
f0100f15:	89 de                	mov    %ebx,%esi
f0100f17:	03 75 08             	add    0x8(%ebp),%esi
f0100f1a:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100f1d:	77 d7                	ja     f0100ef6 <boot_map_region+0x21>
		
		pa += PGSIZE;
		va += PGSIZE;
		
	}
}
f0100f1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f22:	5b                   	pop    %ebx
f0100f23:	5e                   	pop    %esi
f0100f24:	5f                   	pop    %edi
f0100f25:	5d                   	pop    %ebp
f0100f26:	c3                   	ret    

f0100f27 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f27:	55                   	push   %ebp
f0100f28:	89 e5                	mov    %esp,%ebp
f0100f2a:	53                   	push   %ebx
f0100f2b:	83 ec 08             	sub    $0x8,%esp
f0100f2e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;

	entry = pgdir_walk(pgdir, va, 0);
f0100f31:	6a 00                	push   $0x0
f0100f33:	ff 75 0c             	pushl  0xc(%ebp)
f0100f36:	ff 75 08             	pushl  0x8(%ebp)
f0100f39:	e8 04 ff ff ff       	call   f0100e42 <pgdir_walk>
	if(entry == NULL)
f0100f3e:	83 c4 10             	add    $0x10,%esp
f0100f41:	85 c0                	test   %eax,%eax
f0100f43:	74 38                	je     f0100f7d <page_lookup+0x56>
f0100f45:	89 c1                	mov    %eax,%ecx
		return NULL;
	if(!(*entry & PTE_P))
f0100f47:	8b 10                	mov    (%eax),%edx
f0100f49:	f6 c2 01             	test   $0x1,%dl
f0100f4c:	74 36                	je     f0100f84 <page_lookup+0x5d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f4e:	c1 ea 0c             	shr    $0xc,%edx
f0100f51:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0100f57:	72 14                	jb     f0100f6d <page_lookup+0x46>
		panic("pa2page called with invalid pa");
f0100f59:	83 ec 04             	sub    $0x4,%esp
f0100f5c:	68 24 50 10 f0       	push   $0xf0105024
f0100f61:	6a 4f                	push   $0x4f
f0100f63:	68 40 4c 10 f0       	push   $0xf0104c40
f0100f68:	e8 33 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f6d:	a1 4c cc 17 f0       	mov    0xf017cc4c,%eax
f0100f72:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		return NULL;
	
	ret = pa2page(PTE_ADDR(*entry));
	if(pte_store != NULL)
f0100f75:	85 db                	test   %ebx,%ebx
f0100f77:	74 10                	je     f0100f89 <page_lookup+0x62>
	{
		*pte_store = entry;
f0100f79:	89 0b                	mov    %ecx,(%ebx)
f0100f7b:	eb 0c                	jmp    f0100f89 <page_lookup+0x62>
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;

	entry = pgdir_walk(pgdir, va, 0);
	if(entry == NULL)
		return NULL;
f0100f7d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f82:	eb 05                	jmp    f0100f89 <page_lookup+0x62>
	if(!(*entry & PTE_P))
		return NULL;
f0100f84:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store != NULL)
	{
		*pte_store = entry;
	}
	return ret;
}
f0100f89:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f8c:	c9                   	leave  
f0100f8d:	c3                   	ret    

f0100f8e <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f8e:	55                   	push   %ebp
f0100f8f:	89 e5                	mov    %esp,%ebp
f0100f91:	53                   	push   %ebx
f0100f92:	83 ec 18             	sub    $0x18,%esp
f0100f95:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte = NULL;
f0100f98:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &pte);
f0100f9f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fa2:	50                   	push   %eax
f0100fa3:	53                   	push   %ebx
f0100fa4:	ff 75 08             	pushl  0x8(%ebp)
f0100fa7:	e8 7b ff ff ff       	call   f0100f27 <page_lookup>
	if(page == NULL) return ;	
f0100fac:	83 c4 10             	add    $0x10,%esp
f0100faf:	85 c0                	test   %eax,%eax
f0100fb1:	74 18                	je     f0100fcb <page_remove+0x3d>
	
	page_decref(page);
f0100fb3:	83 ec 0c             	sub    $0xc,%esp
f0100fb6:	50                   	push   %eax
f0100fb7:	e8 5f fe ff ff       	call   f0100e1b <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fbc:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
	*pte = 0;
f0100fbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fc2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100fc8:	83 c4 10             	add    $0x10,%esp
}
f0100fcb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fce:	c9                   	leave  
f0100fcf:	c3                   	ret    

f0100fd0 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fd0:	55                   	push   %ebp
f0100fd1:	89 e5                	mov    %esp,%ebp
f0100fd3:	57                   	push   %edi
f0100fd4:	56                   	push   %esi
f0100fd5:	53                   	push   %ebx
f0100fd6:	83 ec 10             	sub    $0x10,%esp
f0100fd9:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fdc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *entry = NULL;
	entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
f0100fdf:	6a 01                	push   $0x1
f0100fe1:	ff 75 10             	pushl  0x10(%ebp)
f0100fe4:	56                   	push   %esi
f0100fe5:	e8 58 fe ff ff       	call   f0100e42 <pgdir_walk>
	if(entry == NULL) return -E_NO_MEM;
f0100fea:	83 c4 10             	add    $0x10,%esp
f0100fed:	85 c0                	test   %eax,%eax
f0100fef:	74 4a                	je     f010103b <page_insert+0x6b>
f0100ff1:	89 c7                	mov    %eax,%edi

	pp->pp_ref++;
f0100ff3:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*entry) & PTE_P) 	        //If this virtual address is already mapped.
f0100ff8:	f6 00 01             	testb  $0x1,(%eax)
f0100ffb:	74 15                	je     f0101012 <page_insert+0x42>
f0100ffd:	8b 45 10             	mov    0x10(%ebp),%eax
f0101000:	0f 01 38             	invlpg (%eax)
	{
		tlb_invalidate(pgdir, va);
		page_remove(pgdir, va);
f0101003:	83 ec 08             	sub    $0x8,%esp
f0101006:	ff 75 10             	pushl  0x10(%ebp)
f0101009:	56                   	push   %esi
f010100a:	e8 7f ff ff ff       	call   f0100f8e <page_remove>
f010100f:	83 c4 10             	add    $0x10,%esp
	}
	*entry = (page2pa(pp) | perm | PTE_P);
f0101012:	2b 1d 4c cc 17 f0    	sub    0xf017cc4c,%ebx
f0101018:	c1 fb 03             	sar    $0x3,%ebx
f010101b:	c1 e3 0c             	shl    $0xc,%ebx
f010101e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101021:	83 c8 01             	or     $0x1,%eax
f0101024:	09 c3                	or     %eax,%ebx
f0101026:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)] |= perm;			      //Remember this step!
f0101028:	8b 45 10             	mov    0x10(%ebp),%eax
f010102b:	c1 e8 16             	shr    $0x16,%eax
f010102e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101031:	09 14 86             	or     %edx,(%esi,%eax,4)
		
	return 0;
f0101034:	b8 00 00 00 00       	mov    $0x0,%eax
f0101039:	eb 05                	jmp    f0101040 <page_insert+0x70>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *entry = NULL;
	entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
	if(entry == NULL) return -E_NO_MEM;
f010103b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*entry = (page2pa(pp) | perm | PTE_P);
	pgdir[PDX(va)] |= perm;			      //Remember this step!
		
	return 0;
}
f0101040:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101043:	5b                   	pop    %ebx
f0101044:	5e                   	pop    %esi
f0101045:	5f                   	pop    %edi
f0101046:	5d                   	pop    %ebp
f0101047:	c3                   	ret    

f0101048 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101048:	55                   	push   %ebp
f0101049:	89 e5                	mov    %esp,%ebp
f010104b:	57                   	push   %edi
f010104c:	56                   	push   %esi
f010104d:	53                   	push   %ebx
f010104e:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101051:	6a 15                	push   $0x15
f0101053:	e8 b3 1e 00 00       	call   f0102f0b <mc146818_read>
f0101058:	89 c3                	mov    %eax,%ebx
f010105a:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101061:	e8 a5 1e 00 00       	call   f0102f0b <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101066:	c1 e0 08             	shl    $0x8,%eax
f0101069:	09 d8                	or     %ebx,%eax
f010106b:	c1 e0 0a             	shl    $0xa,%eax
f010106e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101074:	85 c0                	test   %eax,%eax
f0101076:	0f 48 c2             	cmovs  %edx,%eax
f0101079:	c1 f8 0c             	sar    $0xc,%eax
f010107c:	a3 84 bf 17 f0       	mov    %eax,0xf017bf84
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101081:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101088:	e8 7e 1e 00 00       	call   f0102f0b <mc146818_read>
f010108d:	89 c3                	mov    %eax,%ebx
f010108f:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101096:	e8 70 1e 00 00       	call   f0102f0b <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010109b:	c1 e0 08             	shl    $0x8,%eax
f010109e:	09 d8                	or     %ebx,%eax
f01010a0:	c1 e0 0a             	shl    $0xa,%eax
f01010a3:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010a9:	83 c4 10             	add    $0x10,%esp
f01010ac:	85 c0                	test   %eax,%eax
f01010ae:	0f 48 c2             	cmovs  %edx,%eax
f01010b1:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01010b4:	85 c0                	test   %eax,%eax
f01010b6:	74 0e                	je     f01010c6 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01010b8:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01010be:	89 15 44 cc 17 f0    	mov    %edx,0xf017cc44
f01010c4:	eb 0c                	jmp    f01010d2 <mem_init+0x8a>
	else
		npages = npages_basemem;
f01010c6:	8b 15 84 bf 17 f0    	mov    0xf017bf84,%edx
f01010cc:	89 15 44 cc 17 f0    	mov    %edx,0xf017cc44

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010d2:	c1 e0 0c             	shl    $0xc,%eax
f01010d5:	c1 e8 0a             	shr    $0xa,%eax
f01010d8:	50                   	push   %eax
f01010d9:	a1 84 bf 17 f0       	mov    0xf017bf84,%eax
f01010de:	c1 e0 0c             	shl    $0xc,%eax
f01010e1:	c1 e8 0a             	shr    $0xa,%eax
f01010e4:	50                   	push   %eax
f01010e5:	a1 44 cc 17 f0       	mov    0xf017cc44,%eax
f01010ea:	c1 e0 0c             	shl    $0xc,%eax
f01010ed:	c1 e8 0a             	shr    $0xa,%eax
f01010f0:	50                   	push   %eax
f01010f1:	68 44 50 10 f0       	push   $0xf0105044
f01010f6:	e8 77 1e 00 00       	call   f0102f72 <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010fb:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101100:	e8 1f f8 ff ff       	call   f0100924 <boot_alloc>
f0101105:	a3 48 cc 17 f0       	mov    %eax,0xf017cc48
	memset(kern_pgdir, 0, PGSIZE);
f010110a:	83 c4 0c             	add    $0xc,%esp
f010110d:	68 00 10 00 00       	push   $0x1000
f0101112:	6a 00                	push   $0x0
f0101114:	50                   	push   %eax
f0101115:	e8 5e 31 00 00       	call   f0104278 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010111a:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010111f:	83 c4 10             	add    $0x10,%esp
f0101122:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101127:	77 15                	ja     f010113e <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101129:	50                   	push   %eax
f010112a:	68 80 50 10 f0       	push   $0xf0105080
f010112f:	68 90 00 00 00       	push   $0x90
f0101134:	68 34 4c 10 f0       	push   $0xf0104c34
f0101139:	e8 62 ef ff ff       	call   f01000a0 <_panic>
f010113e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101144:	83 ca 05             	or     $0x5,%edx
f0101147:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f010114d:	a1 44 cc 17 f0       	mov    0xf017cc44,%eax
f0101152:	c1 e0 03             	shl    $0x3,%eax
f0101155:	e8 ca f7 ff ff       	call   f0100924 <boot_alloc>
f010115a:	a3 4c cc 17 f0       	mov    %eax,0xf017cc4c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010115f:	83 ec 04             	sub    $0x4,%esp
f0101162:	8b 3d 44 cc 17 f0    	mov    0xf017cc44,%edi
f0101168:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f010116f:	52                   	push   %edx
f0101170:	6a 00                	push   $0x0
f0101172:	50                   	push   %eax
f0101173:	e8 00 31 00 00       	call   f0104278 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f0101178:	b8 00 80 01 00       	mov    $0x18000,%eax
f010117d:	e8 a2 f7 ff ff       	call   f0100924 <boot_alloc>
f0101182:	a3 8c bf 17 f0       	mov    %eax,0xf017bf8c
	memset(envs, 0, NENV * sizeof(struct Env));
f0101187:	83 c4 0c             	add    $0xc,%esp
f010118a:	68 00 80 01 00       	push   $0x18000
f010118f:	6a 00                	push   $0x0
f0101191:	50                   	push   %eax
f0101192:	e8 e1 30 00 00       	call   f0104278 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101197:	e8 08 fb ff ff       	call   f0100ca4 <page_init>

	check_page_free_list(1);
f010119c:	b8 01 00 00 00       	mov    $0x1,%eax
f01011a1:	e8 4a f8 ff ff       	call   f01009f0 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011a6:	83 c4 10             	add    $0x10,%esp
f01011a9:	83 3d 4c cc 17 f0 00 	cmpl   $0x0,0xf017cc4c
f01011b0:	75 17                	jne    f01011c9 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f01011b2:	83 ec 04             	sub    $0x4,%esp
f01011b5:	68 0e 4d 10 f0       	push   $0xf0104d0e
f01011ba:	68 b4 02 00 00       	push   $0x2b4
f01011bf:	68 34 4c 10 f0       	push   $0xf0104c34
f01011c4:	e8 d7 ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011c9:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f01011ce:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011d3:	eb 05                	jmp    f01011da <mem_init+0x192>
		++nfree;
f01011d5:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011d8:	8b 00                	mov    (%eax),%eax
f01011da:	85 c0                	test   %eax,%eax
f01011dc:	75 f7                	jne    f01011d5 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011de:	83 ec 0c             	sub    $0xc,%esp
f01011e1:	6a 00                	push   $0x0
f01011e3:	e8 66 fb ff ff       	call   f0100d4e <page_alloc>
f01011e8:	89 c7                	mov    %eax,%edi
f01011ea:	83 c4 10             	add    $0x10,%esp
f01011ed:	85 c0                	test   %eax,%eax
f01011ef:	75 19                	jne    f010120a <mem_init+0x1c2>
f01011f1:	68 29 4d 10 f0       	push   $0xf0104d29
f01011f6:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01011fb:	68 bc 02 00 00       	push   $0x2bc
f0101200:	68 34 4c 10 f0       	push   $0xf0104c34
f0101205:	e8 96 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010120a:	83 ec 0c             	sub    $0xc,%esp
f010120d:	6a 00                	push   $0x0
f010120f:	e8 3a fb ff ff       	call   f0100d4e <page_alloc>
f0101214:	89 c6                	mov    %eax,%esi
f0101216:	83 c4 10             	add    $0x10,%esp
f0101219:	85 c0                	test   %eax,%eax
f010121b:	75 19                	jne    f0101236 <mem_init+0x1ee>
f010121d:	68 3f 4d 10 f0       	push   $0xf0104d3f
f0101222:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101227:	68 bd 02 00 00       	push   $0x2bd
f010122c:	68 34 4c 10 f0       	push   $0xf0104c34
f0101231:	e8 6a ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101236:	83 ec 0c             	sub    $0xc,%esp
f0101239:	6a 00                	push   $0x0
f010123b:	e8 0e fb ff ff       	call   f0100d4e <page_alloc>
f0101240:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101243:	83 c4 10             	add    $0x10,%esp
f0101246:	85 c0                	test   %eax,%eax
f0101248:	75 19                	jne    f0101263 <mem_init+0x21b>
f010124a:	68 55 4d 10 f0       	push   $0xf0104d55
f010124f:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101254:	68 be 02 00 00       	push   $0x2be
f0101259:	68 34 4c 10 f0       	push   $0xf0104c34
f010125e:	e8 3d ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101263:	39 f7                	cmp    %esi,%edi
f0101265:	75 19                	jne    f0101280 <mem_init+0x238>
f0101267:	68 6b 4d 10 f0       	push   $0xf0104d6b
f010126c:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101271:	68 c1 02 00 00       	push   $0x2c1
f0101276:	68 34 4c 10 f0       	push   $0xf0104c34
f010127b:	e8 20 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101280:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101283:	39 c6                	cmp    %eax,%esi
f0101285:	74 04                	je     f010128b <mem_init+0x243>
f0101287:	39 c7                	cmp    %eax,%edi
f0101289:	75 19                	jne    f01012a4 <mem_init+0x25c>
f010128b:	68 a4 50 10 f0       	push   $0xf01050a4
f0101290:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101295:	68 c2 02 00 00       	push   $0x2c2
f010129a:	68 34 4c 10 f0       	push   $0xf0104c34
f010129f:	e8 fc ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012a4:	8b 0d 4c cc 17 f0    	mov    0xf017cc4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012aa:	8b 15 44 cc 17 f0    	mov    0xf017cc44,%edx
f01012b0:	c1 e2 0c             	shl    $0xc,%edx
f01012b3:	89 f8                	mov    %edi,%eax
f01012b5:	29 c8                	sub    %ecx,%eax
f01012b7:	c1 f8 03             	sar    $0x3,%eax
f01012ba:	c1 e0 0c             	shl    $0xc,%eax
f01012bd:	39 d0                	cmp    %edx,%eax
f01012bf:	72 19                	jb     f01012da <mem_init+0x292>
f01012c1:	68 7d 4d 10 f0       	push   $0xf0104d7d
f01012c6:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01012cb:	68 c3 02 00 00       	push   $0x2c3
f01012d0:	68 34 4c 10 f0       	push   $0xf0104c34
f01012d5:	e8 c6 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012da:	89 f0                	mov    %esi,%eax
f01012dc:	29 c8                	sub    %ecx,%eax
f01012de:	c1 f8 03             	sar    $0x3,%eax
f01012e1:	c1 e0 0c             	shl    $0xc,%eax
f01012e4:	39 c2                	cmp    %eax,%edx
f01012e6:	77 19                	ja     f0101301 <mem_init+0x2b9>
f01012e8:	68 9a 4d 10 f0       	push   $0xf0104d9a
f01012ed:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01012f2:	68 c4 02 00 00       	push   $0x2c4
f01012f7:	68 34 4c 10 f0       	push   $0xf0104c34
f01012fc:	e8 9f ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101301:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101304:	29 c8                	sub    %ecx,%eax
f0101306:	c1 f8 03             	sar    $0x3,%eax
f0101309:	c1 e0 0c             	shl    $0xc,%eax
f010130c:	39 c2                	cmp    %eax,%edx
f010130e:	77 19                	ja     f0101329 <mem_init+0x2e1>
f0101310:	68 b7 4d 10 f0       	push   $0xf0104db7
f0101315:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010131a:	68 c5 02 00 00       	push   $0x2c5
f010131f:	68 34 4c 10 f0       	push   $0xf0104c34
f0101324:	e8 77 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101329:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f010132e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101331:	c7 05 80 bf 17 f0 00 	movl   $0x0,0xf017bf80
f0101338:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010133b:	83 ec 0c             	sub    $0xc,%esp
f010133e:	6a 00                	push   $0x0
f0101340:	e8 09 fa ff ff       	call   f0100d4e <page_alloc>
f0101345:	83 c4 10             	add    $0x10,%esp
f0101348:	85 c0                	test   %eax,%eax
f010134a:	74 19                	je     f0101365 <mem_init+0x31d>
f010134c:	68 d4 4d 10 f0       	push   $0xf0104dd4
f0101351:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101356:	68 cc 02 00 00       	push   $0x2cc
f010135b:	68 34 4c 10 f0       	push   $0xf0104c34
f0101360:	e8 3b ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101365:	83 ec 0c             	sub    $0xc,%esp
f0101368:	57                   	push   %edi
f0101369:	e8 57 fa ff ff       	call   f0100dc5 <page_free>
	page_free(pp1);
f010136e:	89 34 24             	mov    %esi,(%esp)
f0101371:	e8 4f fa ff ff       	call   f0100dc5 <page_free>
	page_free(pp2);
f0101376:	83 c4 04             	add    $0x4,%esp
f0101379:	ff 75 d4             	pushl  -0x2c(%ebp)
f010137c:	e8 44 fa ff ff       	call   f0100dc5 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101381:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101388:	e8 c1 f9 ff ff       	call   f0100d4e <page_alloc>
f010138d:	89 c6                	mov    %eax,%esi
f010138f:	83 c4 10             	add    $0x10,%esp
f0101392:	85 c0                	test   %eax,%eax
f0101394:	75 19                	jne    f01013af <mem_init+0x367>
f0101396:	68 29 4d 10 f0       	push   $0xf0104d29
f010139b:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01013a0:	68 d3 02 00 00       	push   $0x2d3
f01013a5:	68 34 4c 10 f0       	push   $0xf0104c34
f01013aa:	e8 f1 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01013af:	83 ec 0c             	sub    $0xc,%esp
f01013b2:	6a 00                	push   $0x0
f01013b4:	e8 95 f9 ff ff       	call   f0100d4e <page_alloc>
f01013b9:	89 c7                	mov    %eax,%edi
f01013bb:	83 c4 10             	add    $0x10,%esp
f01013be:	85 c0                	test   %eax,%eax
f01013c0:	75 19                	jne    f01013db <mem_init+0x393>
f01013c2:	68 3f 4d 10 f0       	push   $0xf0104d3f
f01013c7:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01013cc:	68 d4 02 00 00       	push   $0x2d4
f01013d1:	68 34 4c 10 f0       	push   $0xf0104c34
f01013d6:	e8 c5 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013db:	83 ec 0c             	sub    $0xc,%esp
f01013de:	6a 00                	push   $0x0
f01013e0:	e8 69 f9 ff ff       	call   f0100d4e <page_alloc>
f01013e5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013e8:	83 c4 10             	add    $0x10,%esp
f01013eb:	85 c0                	test   %eax,%eax
f01013ed:	75 19                	jne    f0101408 <mem_init+0x3c0>
f01013ef:	68 55 4d 10 f0       	push   $0xf0104d55
f01013f4:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01013f9:	68 d5 02 00 00       	push   $0x2d5
f01013fe:	68 34 4c 10 f0       	push   $0xf0104c34
f0101403:	e8 98 ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101408:	39 fe                	cmp    %edi,%esi
f010140a:	75 19                	jne    f0101425 <mem_init+0x3dd>
f010140c:	68 6b 4d 10 f0       	push   $0xf0104d6b
f0101411:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101416:	68 d7 02 00 00       	push   $0x2d7
f010141b:	68 34 4c 10 f0       	push   $0xf0104c34
f0101420:	e8 7b ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101425:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101428:	39 c7                	cmp    %eax,%edi
f010142a:	74 04                	je     f0101430 <mem_init+0x3e8>
f010142c:	39 c6                	cmp    %eax,%esi
f010142e:	75 19                	jne    f0101449 <mem_init+0x401>
f0101430:	68 a4 50 10 f0       	push   $0xf01050a4
f0101435:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010143a:	68 d8 02 00 00       	push   $0x2d8
f010143f:	68 34 4c 10 f0       	push   $0xf0104c34
f0101444:	e8 57 ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101449:	83 ec 0c             	sub    $0xc,%esp
f010144c:	6a 00                	push   $0x0
f010144e:	e8 fb f8 ff ff       	call   f0100d4e <page_alloc>
f0101453:	83 c4 10             	add    $0x10,%esp
f0101456:	85 c0                	test   %eax,%eax
f0101458:	74 19                	je     f0101473 <mem_init+0x42b>
f010145a:	68 d4 4d 10 f0       	push   $0xf0104dd4
f010145f:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101464:	68 d9 02 00 00       	push   $0x2d9
f0101469:	68 34 4c 10 f0       	push   $0xf0104c34
f010146e:	e8 2d ec ff ff       	call   f01000a0 <_panic>
f0101473:	89 f0                	mov    %esi,%eax
f0101475:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f010147b:	c1 f8 03             	sar    $0x3,%eax
f010147e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101481:	89 c2                	mov    %eax,%edx
f0101483:	c1 ea 0c             	shr    $0xc,%edx
f0101486:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f010148c:	72 12                	jb     f01014a0 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010148e:	50                   	push   %eax
f010148f:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0101494:	6a 56                	push   $0x56
f0101496:	68 40 4c 10 f0       	push   $0xf0104c40
f010149b:	e8 00 ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014a0:	83 ec 04             	sub    $0x4,%esp
f01014a3:	68 00 10 00 00       	push   $0x1000
f01014a8:	6a 01                	push   $0x1
f01014aa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014af:	50                   	push   %eax
f01014b0:	e8 c3 2d 00 00       	call   f0104278 <memset>
	page_free(pp0);
f01014b5:	89 34 24             	mov    %esi,(%esp)
f01014b8:	e8 08 f9 ff ff       	call   f0100dc5 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014bd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014c4:	e8 85 f8 ff ff       	call   f0100d4e <page_alloc>
f01014c9:	83 c4 10             	add    $0x10,%esp
f01014cc:	85 c0                	test   %eax,%eax
f01014ce:	75 19                	jne    f01014e9 <mem_init+0x4a1>
f01014d0:	68 e3 4d 10 f0       	push   $0xf0104de3
f01014d5:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01014da:	68 de 02 00 00       	push   $0x2de
f01014df:	68 34 4c 10 f0       	push   $0xf0104c34
f01014e4:	e8 b7 eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01014e9:	39 c6                	cmp    %eax,%esi
f01014eb:	74 19                	je     f0101506 <mem_init+0x4be>
f01014ed:	68 01 4e 10 f0       	push   $0xf0104e01
f01014f2:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01014f7:	68 df 02 00 00       	push   $0x2df
f01014fc:	68 34 4c 10 f0       	push   $0xf0104c34
f0101501:	e8 9a eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101506:	89 f0                	mov    %esi,%eax
f0101508:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f010150e:	c1 f8 03             	sar    $0x3,%eax
f0101511:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101514:	89 c2                	mov    %eax,%edx
f0101516:	c1 ea 0c             	shr    $0xc,%edx
f0101519:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f010151f:	72 12                	jb     f0101533 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101521:	50                   	push   %eax
f0101522:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0101527:	6a 56                	push   $0x56
f0101529:	68 40 4c 10 f0       	push   $0xf0104c40
f010152e:	e8 6d eb ff ff       	call   f01000a0 <_panic>
f0101533:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101539:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010153f:	80 38 00             	cmpb   $0x0,(%eax)
f0101542:	74 19                	je     f010155d <mem_init+0x515>
f0101544:	68 11 4e 10 f0       	push   $0xf0104e11
f0101549:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010154e:	68 e2 02 00 00       	push   $0x2e2
f0101553:	68 34 4c 10 f0       	push   $0xf0104c34
f0101558:	e8 43 eb ff ff       	call   f01000a0 <_panic>
f010155d:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101560:	39 d0                	cmp    %edx,%eax
f0101562:	75 db                	jne    f010153f <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101564:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101567:	a3 80 bf 17 f0       	mov    %eax,0xf017bf80

	// free the pages we took
	page_free(pp0);
f010156c:	83 ec 0c             	sub    $0xc,%esp
f010156f:	56                   	push   %esi
f0101570:	e8 50 f8 ff ff       	call   f0100dc5 <page_free>
	page_free(pp1);
f0101575:	89 3c 24             	mov    %edi,(%esp)
f0101578:	e8 48 f8 ff ff       	call   f0100dc5 <page_free>
	page_free(pp2);
f010157d:	83 c4 04             	add    $0x4,%esp
f0101580:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101583:	e8 3d f8 ff ff       	call   f0100dc5 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101588:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f010158d:	83 c4 10             	add    $0x10,%esp
f0101590:	eb 05                	jmp    f0101597 <mem_init+0x54f>
		--nfree;
f0101592:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101595:	8b 00                	mov    (%eax),%eax
f0101597:	85 c0                	test   %eax,%eax
f0101599:	75 f7                	jne    f0101592 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f010159b:	85 db                	test   %ebx,%ebx
f010159d:	74 19                	je     f01015b8 <mem_init+0x570>
f010159f:	68 1b 4e 10 f0       	push   $0xf0104e1b
f01015a4:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01015a9:	68 ef 02 00 00       	push   $0x2ef
f01015ae:	68 34 4c 10 f0       	push   $0xf0104c34
f01015b3:	e8 e8 ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015b8:	83 ec 0c             	sub    $0xc,%esp
f01015bb:	68 c4 50 10 f0       	push   $0xf01050c4
f01015c0:	e8 ad 19 00 00       	call   f0102f72 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015cc:	e8 7d f7 ff ff       	call   f0100d4e <page_alloc>
f01015d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015d4:	83 c4 10             	add    $0x10,%esp
f01015d7:	85 c0                	test   %eax,%eax
f01015d9:	75 19                	jne    f01015f4 <mem_init+0x5ac>
f01015db:	68 29 4d 10 f0       	push   $0xf0104d29
f01015e0:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01015e5:	68 4d 03 00 00       	push   $0x34d
f01015ea:	68 34 4c 10 f0       	push   $0xf0104c34
f01015ef:	e8 ac ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01015f4:	83 ec 0c             	sub    $0xc,%esp
f01015f7:	6a 00                	push   $0x0
f01015f9:	e8 50 f7 ff ff       	call   f0100d4e <page_alloc>
f01015fe:	89 c3                	mov    %eax,%ebx
f0101600:	83 c4 10             	add    $0x10,%esp
f0101603:	85 c0                	test   %eax,%eax
f0101605:	75 19                	jne    f0101620 <mem_init+0x5d8>
f0101607:	68 3f 4d 10 f0       	push   $0xf0104d3f
f010160c:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101611:	68 4e 03 00 00       	push   $0x34e
f0101616:	68 34 4c 10 f0       	push   $0xf0104c34
f010161b:	e8 80 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101620:	83 ec 0c             	sub    $0xc,%esp
f0101623:	6a 00                	push   $0x0
f0101625:	e8 24 f7 ff ff       	call   f0100d4e <page_alloc>
f010162a:	89 c6                	mov    %eax,%esi
f010162c:	83 c4 10             	add    $0x10,%esp
f010162f:	85 c0                	test   %eax,%eax
f0101631:	75 19                	jne    f010164c <mem_init+0x604>
f0101633:	68 55 4d 10 f0       	push   $0xf0104d55
f0101638:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010163d:	68 4f 03 00 00       	push   $0x34f
f0101642:	68 34 4c 10 f0       	push   $0xf0104c34
f0101647:	e8 54 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010164c:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010164f:	75 19                	jne    f010166a <mem_init+0x622>
f0101651:	68 6b 4d 10 f0       	push   $0xf0104d6b
f0101656:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010165b:	68 52 03 00 00       	push   $0x352
f0101660:	68 34 4c 10 f0       	push   $0xf0104c34
f0101665:	e8 36 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010166a:	39 c3                	cmp    %eax,%ebx
f010166c:	74 05                	je     f0101673 <mem_init+0x62b>
f010166e:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101671:	75 19                	jne    f010168c <mem_init+0x644>
f0101673:	68 a4 50 10 f0       	push   $0xf01050a4
f0101678:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010167d:	68 53 03 00 00       	push   $0x353
f0101682:	68 34 4c 10 f0       	push   $0xf0104c34
f0101687:	e8 14 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010168c:	a1 80 bf 17 f0       	mov    0xf017bf80,%eax
f0101691:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101694:	c7 05 80 bf 17 f0 00 	movl   $0x0,0xf017bf80
f010169b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010169e:	83 ec 0c             	sub    $0xc,%esp
f01016a1:	6a 00                	push   $0x0
f01016a3:	e8 a6 f6 ff ff       	call   f0100d4e <page_alloc>
f01016a8:	83 c4 10             	add    $0x10,%esp
f01016ab:	85 c0                	test   %eax,%eax
f01016ad:	74 19                	je     f01016c8 <mem_init+0x680>
f01016af:	68 d4 4d 10 f0       	push   $0xf0104dd4
f01016b4:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01016b9:	68 5a 03 00 00       	push   $0x35a
f01016be:	68 34 4c 10 f0       	push   $0xf0104c34
f01016c3:	e8 d8 e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016c8:	83 ec 04             	sub    $0x4,%esp
f01016cb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016ce:	50                   	push   %eax
f01016cf:	6a 00                	push   $0x0
f01016d1:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f01016d7:	e8 4b f8 ff ff       	call   f0100f27 <page_lookup>
f01016dc:	83 c4 10             	add    $0x10,%esp
f01016df:	85 c0                	test   %eax,%eax
f01016e1:	74 19                	je     f01016fc <mem_init+0x6b4>
f01016e3:	68 e4 50 10 f0       	push   $0xf01050e4
f01016e8:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01016ed:	68 5d 03 00 00       	push   $0x35d
f01016f2:	68 34 4c 10 f0       	push   $0xf0104c34
f01016f7:	e8 a4 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016fc:	6a 02                	push   $0x2
f01016fe:	6a 00                	push   $0x0
f0101700:	53                   	push   %ebx
f0101701:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101707:	e8 c4 f8 ff ff       	call   f0100fd0 <page_insert>
f010170c:	83 c4 10             	add    $0x10,%esp
f010170f:	85 c0                	test   %eax,%eax
f0101711:	78 19                	js     f010172c <mem_init+0x6e4>
f0101713:	68 1c 51 10 f0       	push   $0xf010511c
f0101718:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010171d:	68 60 03 00 00       	push   $0x360
f0101722:	68 34 4c 10 f0       	push   $0xf0104c34
f0101727:	e8 74 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010172c:	83 ec 0c             	sub    $0xc,%esp
f010172f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101732:	e8 8e f6 ff ff       	call   f0100dc5 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101737:	6a 02                	push   $0x2
f0101739:	6a 00                	push   $0x0
f010173b:	53                   	push   %ebx
f010173c:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101742:	e8 89 f8 ff ff       	call   f0100fd0 <page_insert>
f0101747:	83 c4 20             	add    $0x20,%esp
f010174a:	85 c0                	test   %eax,%eax
f010174c:	74 19                	je     f0101767 <mem_init+0x71f>
f010174e:	68 4c 51 10 f0       	push   $0xf010514c
f0101753:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101758:	68 64 03 00 00       	push   $0x364
f010175d:	68 34 4c 10 f0       	push   $0xf0104c34
f0101762:	e8 39 e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101767:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010176d:	a1 4c cc 17 f0       	mov    0xf017cc4c,%eax
f0101772:	89 c1                	mov    %eax,%ecx
f0101774:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101777:	8b 17                	mov    (%edi),%edx
f0101779:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010177f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101782:	29 c8                	sub    %ecx,%eax
f0101784:	c1 f8 03             	sar    $0x3,%eax
f0101787:	c1 e0 0c             	shl    $0xc,%eax
f010178a:	39 c2                	cmp    %eax,%edx
f010178c:	74 19                	je     f01017a7 <mem_init+0x75f>
f010178e:	68 7c 51 10 f0       	push   $0xf010517c
f0101793:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101798:	68 65 03 00 00       	push   $0x365
f010179d:	68 34 4c 10 f0       	push   $0xf0104c34
f01017a2:	e8 f9 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017a7:	ba 00 00 00 00       	mov    $0x0,%edx
f01017ac:	89 f8                	mov    %edi,%eax
f01017ae:	e8 d9 f1 ff ff       	call   f010098c <check_va2pa>
f01017b3:	89 da                	mov    %ebx,%edx
f01017b5:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017b8:	c1 fa 03             	sar    $0x3,%edx
f01017bb:	c1 e2 0c             	shl    $0xc,%edx
f01017be:	39 d0                	cmp    %edx,%eax
f01017c0:	74 19                	je     f01017db <mem_init+0x793>
f01017c2:	68 a4 51 10 f0       	push   $0xf01051a4
f01017c7:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01017cc:	68 66 03 00 00       	push   $0x366
f01017d1:	68 34 4c 10 f0       	push   $0xf0104c34
f01017d6:	e8 c5 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01017db:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017e0:	74 19                	je     f01017fb <mem_init+0x7b3>
f01017e2:	68 26 4e 10 f0       	push   $0xf0104e26
f01017e7:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01017ec:	68 67 03 00 00       	push   $0x367
f01017f1:	68 34 4c 10 f0       	push   $0xf0104c34
f01017f6:	e8 a5 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01017fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017fe:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101803:	74 19                	je     f010181e <mem_init+0x7d6>
f0101805:	68 37 4e 10 f0       	push   $0xf0104e37
f010180a:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010180f:	68 68 03 00 00       	push   $0x368
f0101814:	68 34 4c 10 f0       	push   $0xf0104c34
f0101819:	e8 82 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010181e:	6a 02                	push   $0x2
f0101820:	68 00 10 00 00       	push   $0x1000
f0101825:	56                   	push   %esi
f0101826:	57                   	push   %edi
f0101827:	e8 a4 f7 ff ff       	call   f0100fd0 <page_insert>
f010182c:	83 c4 10             	add    $0x10,%esp
f010182f:	85 c0                	test   %eax,%eax
f0101831:	74 19                	je     f010184c <mem_init+0x804>
f0101833:	68 d4 51 10 f0       	push   $0xf01051d4
f0101838:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010183d:	68 6b 03 00 00       	push   $0x36b
f0101842:	68 34 4c 10 f0       	push   $0xf0104c34
f0101847:	e8 54 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010184c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101851:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f0101856:	e8 31 f1 ff ff       	call   f010098c <check_va2pa>
f010185b:	89 f2                	mov    %esi,%edx
f010185d:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f0101863:	c1 fa 03             	sar    $0x3,%edx
f0101866:	c1 e2 0c             	shl    $0xc,%edx
f0101869:	39 d0                	cmp    %edx,%eax
f010186b:	74 19                	je     f0101886 <mem_init+0x83e>
f010186d:	68 10 52 10 f0       	push   $0xf0105210
f0101872:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101877:	68 6c 03 00 00       	push   $0x36c
f010187c:	68 34 4c 10 f0       	push   $0xf0104c34
f0101881:	e8 1a e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101886:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010188b:	74 19                	je     f01018a6 <mem_init+0x85e>
f010188d:	68 48 4e 10 f0       	push   $0xf0104e48
f0101892:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101897:	68 6d 03 00 00       	push   $0x36d
f010189c:	68 34 4c 10 f0       	push   $0xf0104c34
f01018a1:	e8 fa e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018a6:	83 ec 0c             	sub    $0xc,%esp
f01018a9:	6a 00                	push   $0x0
f01018ab:	e8 9e f4 ff ff       	call   f0100d4e <page_alloc>
f01018b0:	83 c4 10             	add    $0x10,%esp
f01018b3:	85 c0                	test   %eax,%eax
f01018b5:	74 19                	je     f01018d0 <mem_init+0x888>
f01018b7:	68 d4 4d 10 f0       	push   $0xf0104dd4
f01018bc:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01018c1:	68 70 03 00 00       	push   $0x370
f01018c6:	68 34 4c 10 f0       	push   $0xf0104c34
f01018cb:	e8 d0 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018d0:	6a 02                	push   $0x2
f01018d2:	68 00 10 00 00       	push   $0x1000
f01018d7:	56                   	push   %esi
f01018d8:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f01018de:	e8 ed f6 ff ff       	call   f0100fd0 <page_insert>
f01018e3:	83 c4 10             	add    $0x10,%esp
f01018e6:	85 c0                	test   %eax,%eax
f01018e8:	74 19                	je     f0101903 <mem_init+0x8bb>
f01018ea:	68 d4 51 10 f0       	push   $0xf01051d4
f01018ef:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01018f4:	68 73 03 00 00       	push   $0x373
f01018f9:	68 34 4c 10 f0       	push   $0xf0104c34
f01018fe:	e8 9d e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101903:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101908:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f010190d:	e8 7a f0 ff ff       	call   f010098c <check_va2pa>
f0101912:	89 f2                	mov    %esi,%edx
f0101914:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f010191a:	c1 fa 03             	sar    $0x3,%edx
f010191d:	c1 e2 0c             	shl    $0xc,%edx
f0101920:	39 d0                	cmp    %edx,%eax
f0101922:	74 19                	je     f010193d <mem_init+0x8f5>
f0101924:	68 10 52 10 f0       	push   $0xf0105210
f0101929:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010192e:	68 74 03 00 00       	push   $0x374
f0101933:	68 34 4c 10 f0       	push   $0xf0104c34
f0101938:	e8 63 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010193d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101942:	74 19                	je     f010195d <mem_init+0x915>
f0101944:	68 48 4e 10 f0       	push   $0xf0104e48
f0101949:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010194e:	68 75 03 00 00       	push   $0x375
f0101953:	68 34 4c 10 f0       	push   $0xf0104c34
f0101958:	e8 43 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010195d:	83 ec 0c             	sub    $0xc,%esp
f0101960:	6a 00                	push   $0x0
f0101962:	e8 e7 f3 ff ff       	call   f0100d4e <page_alloc>
f0101967:	83 c4 10             	add    $0x10,%esp
f010196a:	85 c0                	test   %eax,%eax
f010196c:	74 19                	je     f0101987 <mem_init+0x93f>
f010196e:	68 d4 4d 10 f0       	push   $0xf0104dd4
f0101973:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101978:	68 79 03 00 00       	push   $0x379
f010197d:	68 34 4c 10 f0       	push   $0xf0104c34
f0101982:	e8 19 e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101987:	8b 15 48 cc 17 f0    	mov    0xf017cc48,%edx
f010198d:	8b 02                	mov    (%edx),%eax
f010198f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101994:	89 c1                	mov    %eax,%ecx
f0101996:	c1 e9 0c             	shr    $0xc,%ecx
f0101999:	3b 0d 44 cc 17 f0    	cmp    0xf017cc44,%ecx
f010199f:	72 15                	jb     f01019b6 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019a1:	50                   	push   %eax
f01019a2:	68 3c 4f 10 f0       	push   $0xf0104f3c
f01019a7:	68 7c 03 00 00       	push   $0x37c
f01019ac:	68 34 4c 10 f0       	push   $0xf0104c34
f01019b1:	e8 ea e6 ff ff       	call   f01000a0 <_panic>
f01019b6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019be:	83 ec 04             	sub    $0x4,%esp
f01019c1:	6a 00                	push   $0x0
f01019c3:	68 00 10 00 00       	push   $0x1000
f01019c8:	52                   	push   %edx
f01019c9:	e8 74 f4 ff ff       	call   f0100e42 <pgdir_walk>
f01019ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019d1:	8d 57 04             	lea    0x4(%edi),%edx
f01019d4:	83 c4 10             	add    $0x10,%esp
f01019d7:	39 d0                	cmp    %edx,%eax
f01019d9:	74 19                	je     f01019f4 <mem_init+0x9ac>
f01019db:	68 40 52 10 f0       	push   $0xf0105240
f01019e0:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01019e5:	68 7d 03 00 00       	push   $0x37d
f01019ea:	68 34 4c 10 f0       	push   $0xf0104c34
f01019ef:	e8 ac e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019f4:	6a 06                	push   $0x6
f01019f6:	68 00 10 00 00       	push   $0x1000
f01019fb:	56                   	push   %esi
f01019fc:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101a02:	e8 c9 f5 ff ff       	call   f0100fd0 <page_insert>
f0101a07:	83 c4 10             	add    $0x10,%esp
f0101a0a:	85 c0                	test   %eax,%eax
f0101a0c:	74 19                	je     f0101a27 <mem_init+0x9df>
f0101a0e:	68 80 52 10 f0       	push   $0xf0105280
f0101a13:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101a18:	68 80 03 00 00       	push   $0x380
f0101a1d:	68 34 4c 10 f0       	push   $0xf0104c34
f0101a22:	e8 79 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a27:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
f0101a2d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a32:	89 f8                	mov    %edi,%eax
f0101a34:	e8 53 ef ff ff       	call   f010098c <check_va2pa>
f0101a39:	89 f2                	mov    %esi,%edx
f0101a3b:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f0101a41:	c1 fa 03             	sar    $0x3,%edx
f0101a44:	c1 e2 0c             	shl    $0xc,%edx
f0101a47:	39 d0                	cmp    %edx,%eax
f0101a49:	74 19                	je     f0101a64 <mem_init+0xa1c>
f0101a4b:	68 10 52 10 f0       	push   $0xf0105210
f0101a50:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101a55:	68 81 03 00 00       	push   $0x381
f0101a5a:	68 34 4c 10 f0       	push   $0xf0104c34
f0101a5f:	e8 3c e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a64:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a69:	74 19                	je     f0101a84 <mem_init+0xa3c>
f0101a6b:	68 48 4e 10 f0       	push   $0xf0104e48
f0101a70:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101a75:	68 82 03 00 00       	push   $0x382
f0101a7a:	68 34 4c 10 f0       	push   $0xf0104c34
f0101a7f:	e8 1c e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a84:	83 ec 04             	sub    $0x4,%esp
f0101a87:	6a 00                	push   $0x0
f0101a89:	68 00 10 00 00       	push   $0x1000
f0101a8e:	57                   	push   %edi
f0101a8f:	e8 ae f3 ff ff       	call   f0100e42 <pgdir_walk>
f0101a94:	83 c4 10             	add    $0x10,%esp
f0101a97:	f6 00 04             	testb  $0x4,(%eax)
f0101a9a:	75 19                	jne    f0101ab5 <mem_init+0xa6d>
f0101a9c:	68 c0 52 10 f0       	push   $0xf01052c0
f0101aa1:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101aa6:	68 83 03 00 00       	push   $0x383
f0101aab:	68 34 4c 10 f0       	push   $0xf0104c34
f0101ab0:	e8 eb e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ab5:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f0101aba:	f6 00 04             	testb  $0x4,(%eax)
f0101abd:	75 19                	jne    f0101ad8 <mem_init+0xa90>
f0101abf:	68 59 4e 10 f0       	push   $0xf0104e59
f0101ac4:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101ac9:	68 84 03 00 00       	push   $0x384
f0101ace:	68 34 4c 10 f0       	push   $0xf0104c34
f0101ad3:	e8 c8 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad8:	6a 02                	push   $0x2
f0101ada:	68 00 10 00 00       	push   $0x1000
f0101adf:	56                   	push   %esi
f0101ae0:	50                   	push   %eax
f0101ae1:	e8 ea f4 ff ff       	call   f0100fd0 <page_insert>
f0101ae6:	83 c4 10             	add    $0x10,%esp
f0101ae9:	85 c0                	test   %eax,%eax
f0101aeb:	74 19                	je     f0101b06 <mem_init+0xabe>
f0101aed:	68 d4 51 10 f0       	push   $0xf01051d4
f0101af2:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101af7:	68 87 03 00 00       	push   $0x387
f0101afc:	68 34 4c 10 f0       	push   $0xf0104c34
f0101b01:	e8 9a e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b06:	83 ec 04             	sub    $0x4,%esp
f0101b09:	6a 00                	push   $0x0
f0101b0b:	68 00 10 00 00       	push   $0x1000
f0101b10:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101b16:	e8 27 f3 ff ff       	call   f0100e42 <pgdir_walk>
f0101b1b:	83 c4 10             	add    $0x10,%esp
f0101b1e:	f6 00 02             	testb  $0x2,(%eax)
f0101b21:	75 19                	jne    f0101b3c <mem_init+0xaf4>
f0101b23:	68 f4 52 10 f0       	push   $0xf01052f4
f0101b28:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101b2d:	68 88 03 00 00       	push   $0x388
f0101b32:	68 34 4c 10 f0       	push   $0xf0104c34
f0101b37:	e8 64 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b3c:	83 ec 04             	sub    $0x4,%esp
f0101b3f:	6a 00                	push   $0x0
f0101b41:	68 00 10 00 00       	push   $0x1000
f0101b46:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101b4c:	e8 f1 f2 ff ff       	call   f0100e42 <pgdir_walk>
f0101b51:	83 c4 10             	add    $0x10,%esp
f0101b54:	f6 00 04             	testb  $0x4,(%eax)
f0101b57:	74 19                	je     f0101b72 <mem_init+0xb2a>
f0101b59:	68 28 53 10 f0       	push   $0xf0105328
f0101b5e:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101b63:	68 89 03 00 00       	push   $0x389
f0101b68:	68 34 4c 10 f0       	push   $0xf0104c34
f0101b6d:	e8 2e e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b72:	6a 02                	push   $0x2
f0101b74:	68 00 00 40 00       	push   $0x400000
f0101b79:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b7c:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101b82:	e8 49 f4 ff ff       	call   f0100fd0 <page_insert>
f0101b87:	83 c4 10             	add    $0x10,%esp
f0101b8a:	85 c0                	test   %eax,%eax
f0101b8c:	78 19                	js     f0101ba7 <mem_init+0xb5f>
f0101b8e:	68 60 53 10 f0       	push   $0xf0105360
f0101b93:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101b98:	68 8c 03 00 00       	push   $0x38c
f0101b9d:	68 34 4c 10 f0       	push   $0xf0104c34
f0101ba2:	e8 f9 e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ba7:	6a 02                	push   $0x2
f0101ba9:	68 00 10 00 00       	push   $0x1000
f0101bae:	53                   	push   %ebx
f0101baf:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101bb5:	e8 16 f4 ff ff       	call   f0100fd0 <page_insert>
f0101bba:	83 c4 10             	add    $0x10,%esp
f0101bbd:	85 c0                	test   %eax,%eax
f0101bbf:	74 19                	je     f0101bda <mem_init+0xb92>
f0101bc1:	68 98 53 10 f0       	push   $0xf0105398
f0101bc6:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101bcb:	68 8f 03 00 00       	push   $0x38f
f0101bd0:	68 34 4c 10 f0       	push   $0xf0104c34
f0101bd5:	e8 c6 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bda:	83 ec 04             	sub    $0x4,%esp
f0101bdd:	6a 00                	push   $0x0
f0101bdf:	68 00 10 00 00       	push   $0x1000
f0101be4:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101bea:	e8 53 f2 ff ff       	call   f0100e42 <pgdir_walk>
f0101bef:	83 c4 10             	add    $0x10,%esp
f0101bf2:	f6 00 04             	testb  $0x4,(%eax)
f0101bf5:	74 19                	je     f0101c10 <mem_init+0xbc8>
f0101bf7:	68 28 53 10 f0       	push   $0xf0105328
f0101bfc:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101c01:	68 90 03 00 00       	push   $0x390
f0101c06:	68 34 4c 10 f0       	push   $0xf0104c34
f0101c0b:	e8 90 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c10:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
f0101c16:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c1b:	89 f8                	mov    %edi,%eax
f0101c1d:	e8 6a ed ff ff       	call   f010098c <check_va2pa>
f0101c22:	89 c1                	mov    %eax,%ecx
f0101c24:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c27:	89 d8                	mov    %ebx,%eax
f0101c29:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0101c2f:	c1 f8 03             	sar    $0x3,%eax
f0101c32:	c1 e0 0c             	shl    $0xc,%eax
f0101c35:	39 c1                	cmp    %eax,%ecx
f0101c37:	74 19                	je     f0101c52 <mem_init+0xc0a>
f0101c39:	68 d4 53 10 f0       	push   $0xf01053d4
f0101c3e:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101c43:	68 93 03 00 00       	push   $0x393
f0101c48:	68 34 4c 10 f0       	push   $0xf0104c34
f0101c4d:	e8 4e e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c52:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c57:	89 f8                	mov    %edi,%eax
f0101c59:	e8 2e ed ff ff       	call   f010098c <check_va2pa>
f0101c5e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c61:	74 19                	je     f0101c7c <mem_init+0xc34>
f0101c63:	68 00 54 10 f0       	push   $0xf0105400
f0101c68:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101c6d:	68 94 03 00 00       	push   $0x394
f0101c72:	68 34 4c 10 f0       	push   $0xf0104c34
f0101c77:	e8 24 e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c7c:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c81:	74 19                	je     f0101c9c <mem_init+0xc54>
f0101c83:	68 6f 4e 10 f0       	push   $0xf0104e6f
f0101c88:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101c8d:	68 96 03 00 00       	push   $0x396
f0101c92:	68 34 4c 10 f0       	push   $0xf0104c34
f0101c97:	e8 04 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c9c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ca1:	74 19                	je     f0101cbc <mem_init+0xc74>
f0101ca3:	68 80 4e 10 f0       	push   $0xf0104e80
f0101ca8:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101cad:	68 97 03 00 00       	push   $0x397
f0101cb2:	68 34 4c 10 f0       	push   $0xf0104c34
f0101cb7:	e8 e4 e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cbc:	83 ec 0c             	sub    $0xc,%esp
f0101cbf:	6a 00                	push   $0x0
f0101cc1:	e8 88 f0 ff ff       	call   f0100d4e <page_alloc>
f0101cc6:	83 c4 10             	add    $0x10,%esp
f0101cc9:	85 c0                	test   %eax,%eax
f0101ccb:	74 04                	je     f0101cd1 <mem_init+0xc89>
f0101ccd:	39 c6                	cmp    %eax,%esi
f0101ccf:	74 19                	je     f0101cea <mem_init+0xca2>
f0101cd1:	68 30 54 10 f0       	push   $0xf0105430
f0101cd6:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101cdb:	68 9a 03 00 00       	push   $0x39a
f0101ce0:	68 34 4c 10 f0       	push   $0xf0104c34
f0101ce5:	e8 b6 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cea:	83 ec 08             	sub    $0x8,%esp
f0101ced:	6a 00                	push   $0x0
f0101cef:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101cf5:	e8 94 f2 ff ff       	call   f0100f8e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cfa:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
f0101d00:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d05:	89 f8                	mov    %edi,%eax
f0101d07:	e8 80 ec ff ff       	call   f010098c <check_va2pa>
f0101d0c:	83 c4 10             	add    $0x10,%esp
f0101d0f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d12:	74 19                	je     f0101d2d <mem_init+0xce5>
f0101d14:	68 54 54 10 f0       	push   $0xf0105454
f0101d19:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101d1e:	68 9e 03 00 00       	push   $0x39e
f0101d23:	68 34 4c 10 f0       	push   $0xf0104c34
f0101d28:	e8 73 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d2d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d32:	89 f8                	mov    %edi,%eax
f0101d34:	e8 53 ec ff ff       	call   f010098c <check_va2pa>
f0101d39:	89 da                	mov    %ebx,%edx
f0101d3b:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f0101d41:	c1 fa 03             	sar    $0x3,%edx
f0101d44:	c1 e2 0c             	shl    $0xc,%edx
f0101d47:	39 d0                	cmp    %edx,%eax
f0101d49:	74 19                	je     f0101d64 <mem_init+0xd1c>
f0101d4b:	68 00 54 10 f0       	push   $0xf0105400
f0101d50:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101d55:	68 9f 03 00 00       	push   $0x39f
f0101d5a:	68 34 4c 10 f0       	push   $0xf0104c34
f0101d5f:	e8 3c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d64:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d69:	74 19                	je     f0101d84 <mem_init+0xd3c>
f0101d6b:	68 26 4e 10 f0       	push   $0xf0104e26
f0101d70:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101d75:	68 a0 03 00 00       	push   $0x3a0
f0101d7a:	68 34 4c 10 f0       	push   $0xf0104c34
f0101d7f:	e8 1c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d84:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d89:	74 19                	je     f0101da4 <mem_init+0xd5c>
f0101d8b:	68 80 4e 10 f0       	push   $0xf0104e80
f0101d90:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101d95:	68 a1 03 00 00       	push   $0x3a1
f0101d9a:	68 34 4c 10 f0       	push   $0xf0104c34
f0101d9f:	e8 fc e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101da4:	6a 00                	push   $0x0
f0101da6:	68 00 10 00 00       	push   $0x1000
f0101dab:	53                   	push   %ebx
f0101dac:	57                   	push   %edi
f0101dad:	e8 1e f2 ff ff       	call   f0100fd0 <page_insert>
f0101db2:	83 c4 10             	add    $0x10,%esp
f0101db5:	85 c0                	test   %eax,%eax
f0101db7:	74 19                	je     f0101dd2 <mem_init+0xd8a>
f0101db9:	68 78 54 10 f0       	push   $0xf0105478
f0101dbe:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101dc3:	68 a4 03 00 00       	push   $0x3a4
f0101dc8:	68 34 4c 10 f0       	push   $0xf0104c34
f0101dcd:	e8 ce e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101dd2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dd7:	75 19                	jne    f0101df2 <mem_init+0xdaa>
f0101dd9:	68 91 4e 10 f0       	push   $0xf0104e91
f0101dde:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101de3:	68 a5 03 00 00       	push   $0x3a5
f0101de8:	68 34 4c 10 f0       	push   $0xf0104c34
f0101ded:	e8 ae e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101df2:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101df5:	74 19                	je     f0101e10 <mem_init+0xdc8>
f0101df7:	68 9d 4e 10 f0       	push   $0xf0104e9d
f0101dfc:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101e01:	68 a6 03 00 00       	push   $0x3a6
f0101e06:	68 34 4c 10 f0       	push   $0xf0104c34
f0101e0b:	e8 90 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e10:	83 ec 08             	sub    $0x8,%esp
f0101e13:	68 00 10 00 00       	push   $0x1000
f0101e18:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101e1e:	e8 6b f1 ff ff       	call   f0100f8e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e23:	8b 3d 48 cc 17 f0    	mov    0xf017cc48,%edi
f0101e29:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e2e:	89 f8                	mov    %edi,%eax
f0101e30:	e8 57 eb ff ff       	call   f010098c <check_va2pa>
f0101e35:	83 c4 10             	add    $0x10,%esp
f0101e38:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e3b:	74 19                	je     f0101e56 <mem_init+0xe0e>
f0101e3d:	68 54 54 10 f0       	push   $0xf0105454
f0101e42:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101e47:	68 aa 03 00 00       	push   $0x3aa
f0101e4c:	68 34 4c 10 f0       	push   $0xf0104c34
f0101e51:	e8 4a e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e56:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e5b:	89 f8                	mov    %edi,%eax
f0101e5d:	e8 2a eb ff ff       	call   f010098c <check_va2pa>
f0101e62:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e65:	74 19                	je     f0101e80 <mem_init+0xe38>
f0101e67:	68 b0 54 10 f0       	push   $0xf01054b0
f0101e6c:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101e71:	68 ab 03 00 00       	push   $0x3ab
f0101e76:	68 34 4c 10 f0       	push   $0xf0104c34
f0101e7b:	e8 20 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e80:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e85:	74 19                	je     f0101ea0 <mem_init+0xe58>
f0101e87:	68 b2 4e 10 f0       	push   $0xf0104eb2
f0101e8c:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101e91:	68 ac 03 00 00       	push   $0x3ac
f0101e96:	68 34 4c 10 f0       	push   $0xf0104c34
f0101e9b:	e8 00 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ea0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ea5:	74 19                	je     f0101ec0 <mem_init+0xe78>
f0101ea7:	68 80 4e 10 f0       	push   $0xf0104e80
f0101eac:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101eb1:	68 ad 03 00 00       	push   $0x3ad
f0101eb6:	68 34 4c 10 f0       	push   $0xf0104c34
f0101ebb:	e8 e0 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ec0:	83 ec 0c             	sub    $0xc,%esp
f0101ec3:	6a 00                	push   $0x0
f0101ec5:	e8 84 ee ff ff       	call   f0100d4e <page_alloc>
f0101eca:	83 c4 10             	add    $0x10,%esp
f0101ecd:	39 c3                	cmp    %eax,%ebx
f0101ecf:	75 04                	jne    f0101ed5 <mem_init+0xe8d>
f0101ed1:	85 c0                	test   %eax,%eax
f0101ed3:	75 19                	jne    f0101eee <mem_init+0xea6>
f0101ed5:	68 d8 54 10 f0       	push   $0xf01054d8
f0101eda:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101edf:	68 b0 03 00 00       	push   $0x3b0
f0101ee4:	68 34 4c 10 f0       	push   $0xf0104c34
f0101ee9:	e8 b2 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101eee:	83 ec 0c             	sub    $0xc,%esp
f0101ef1:	6a 00                	push   $0x0
f0101ef3:	e8 56 ee ff ff       	call   f0100d4e <page_alloc>
f0101ef8:	83 c4 10             	add    $0x10,%esp
f0101efb:	85 c0                	test   %eax,%eax
f0101efd:	74 19                	je     f0101f18 <mem_init+0xed0>
f0101eff:	68 d4 4d 10 f0       	push   $0xf0104dd4
f0101f04:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101f09:	68 b3 03 00 00       	push   $0x3b3
f0101f0e:	68 34 4c 10 f0       	push   $0xf0104c34
f0101f13:	e8 88 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f18:	8b 0d 48 cc 17 f0    	mov    0xf017cc48,%ecx
f0101f1e:	8b 11                	mov    (%ecx),%edx
f0101f20:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f26:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f29:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0101f2f:	c1 f8 03             	sar    $0x3,%eax
f0101f32:	c1 e0 0c             	shl    $0xc,%eax
f0101f35:	39 c2                	cmp    %eax,%edx
f0101f37:	74 19                	je     f0101f52 <mem_init+0xf0a>
f0101f39:	68 7c 51 10 f0       	push   $0xf010517c
f0101f3e:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101f43:	68 b6 03 00 00       	push   $0x3b6
f0101f48:	68 34 4c 10 f0       	push   $0xf0104c34
f0101f4d:	e8 4e e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f52:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f5b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f60:	74 19                	je     f0101f7b <mem_init+0xf33>
f0101f62:	68 37 4e 10 f0       	push   $0xf0104e37
f0101f67:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101f6c:	68 b8 03 00 00       	push   $0x3b8
f0101f71:	68 34 4c 10 f0       	push   $0xf0104c34
f0101f76:	e8 25 e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f7b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f7e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f84:	83 ec 0c             	sub    $0xc,%esp
f0101f87:	50                   	push   %eax
f0101f88:	e8 38 ee ff ff       	call   f0100dc5 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f8d:	83 c4 0c             	add    $0xc,%esp
f0101f90:	6a 01                	push   $0x1
f0101f92:	68 00 10 40 00       	push   $0x401000
f0101f97:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0101f9d:	e8 a0 ee ff ff       	call   f0100e42 <pgdir_walk>
f0101fa2:	89 c7                	mov    %eax,%edi
f0101fa4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fa7:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f0101fac:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101faf:	8b 40 04             	mov    0x4(%eax),%eax
f0101fb2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fb7:	8b 0d 44 cc 17 f0    	mov    0xf017cc44,%ecx
f0101fbd:	89 c2                	mov    %eax,%edx
f0101fbf:	c1 ea 0c             	shr    $0xc,%edx
f0101fc2:	83 c4 10             	add    $0x10,%esp
f0101fc5:	39 ca                	cmp    %ecx,%edx
f0101fc7:	72 15                	jb     f0101fde <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fc9:	50                   	push   %eax
f0101fca:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0101fcf:	68 bf 03 00 00       	push   $0x3bf
f0101fd4:	68 34 4c 10 f0       	push   $0xf0104c34
f0101fd9:	e8 c2 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fde:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fe3:	39 c7                	cmp    %eax,%edi
f0101fe5:	74 19                	je     f0102000 <mem_init+0xfb8>
f0101fe7:	68 c3 4e 10 f0       	push   $0xf0104ec3
f0101fec:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0101ff1:	68 c0 03 00 00       	push   $0x3c0
f0101ff6:	68 34 4c 10 f0       	push   $0xf0104c34
f0101ffb:	e8 a0 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102000:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102003:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010200a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010200d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102013:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0102019:	c1 f8 03             	sar    $0x3,%eax
f010201c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010201f:	89 c2                	mov    %eax,%edx
f0102021:	c1 ea 0c             	shr    $0xc,%edx
f0102024:	39 d1                	cmp    %edx,%ecx
f0102026:	77 12                	ja     f010203a <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102028:	50                   	push   %eax
f0102029:	68 3c 4f 10 f0       	push   $0xf0104f3c
f010202e:	6a 56                	push   $0x56
f0102030:	68 40 4c 10 f0       	push   $0xf0104c40
f0102035:	e8 66 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010203a:	83 ec 04             	sub    $0x4,%esp
f010203d:	68 00 10 00 00       	push   $0x1000
f0102042:	68 ff 00 00 00       	push   $0xff
f0102047:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010204c:	50                   	push   %eax
f010204d:	e8 26 22 00 00       	call   f0104278 <memset>
	page_free(pp0);
f0102052:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102055:	89 3c 24             	mov    %edi,(%esp)
f0102058:	e8 68 ed ff ff       	call   f0100dc5 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010205d:	83 c4 0c             	add    $0xc,%esp
f0102060:	6a 01                	push   $0x1
f0102062:	6a 00                	push   $0x0
f0102064:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f010206a:	e8 d3 ed ff ff       	call   f0100e42 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010206f:	89 fa                	mov    %edi,%edx
f0102071:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f0102077:	c1 fa 03             	sar    $0x3,%edx
f010207a:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010207d:	89 d0                	mov    %edx,%eax
f010207f:	c1 e8 0c             	shr    $0xc,%eax
f0102082:	83 c4 10             	add    $0x10,%esp
f0102085:	3b 05 44 cc 17 f0    	cmp    0xf017cc44,%eax
f010208b:	72 12                	jb     f010209f <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010208d:	52                   	push   %edx
f010208e:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0102093:	6a 56                	push   $0x56
f0102095:	68 40 4c 10 f0       	push   $0xf0104c40
f010209a:	e8 01 e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f010209f:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020a5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020a8:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020ae:	f6 00 01             	testb  $0x1,(%eax)
f01020b1:	74 19                	je     f01020cc <mem_init+0x1084>
f01020b3:	68 db 4e 10 f0       	push   $0xf0104edb
f01020b8:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01020bd:	68 ca 03 00 00       	push   $0x3ca
f01020c2:	68 34 4c 10 f0       	push   $0xf0104c34
f01020c7:	e8 d4 df ff ff       	call   f01000a0 <_panic>
f01020cc:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020cf:	39 c2                	cmp    %eax,%edx
f01020d1:	75 db                	jne    f01020ae <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020d3:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f01020d8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020de:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020e7:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01020ea:	89 3d 80 bf 17 f0    	mov    %edi,0xf017bf80

	// free the pages we took
	page_free(pp0);
f01020f0:	83 ec 0c             	sub    $0xc,%esp
f01020f3:	50                   	push   %eax
f01020f4:	e8 cc ec ff ff       	call   f0100dc5 <page_free>
	page_free(pp1);
f01020f9:	89 1c 24             	mov    %ebx,(%esp)
f01020fc:	e8 c4 ec ff ff       	call   f0100dc5 <page_free>
	page_free(pp2);
f0102101:	89 34 24             	mov    %esi,(%esp)
f0102104:	e8 bc ec ff ff       	call   f0100dc5 <page_free>

	cprintf("check_page() succeeded!\n");
f0102109:	c7 04 24 f2 4e 10 f0 	movl   $0xf0104ef2,(%esp)
f0102110:	e8 5d 0e 00 00       	call   f0102f72 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102115:	a1 4c cc 17 f0       	mov    0xf017cc4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010211a:	83 c4 10             	add    $0x10,%esp
f010211d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102122:	77 15                	ja     f0102139 <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102124:	50                   	push   %eax
f0102125:	68 80 50 10 f0       	push   $0xf0105080
f010212a:	68 b8 00 00 00       	push   $0xb8
f010212f:	68 34 4c 10 f0       	push   $0xf0104c34
f0102134:	e8 67 df ff ff       	call   f01000a0 <_panic>
f0102139:	83 ec 08             	sub    $0x8,%esp
f010213c:	6a 04                	push   $0x4
f010213e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102143:	50                   	push   %eax
f0102144:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102149:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010214e:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f0102153:	e8 7d ed ff ff       	call   f0100ed5 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);	
f0102158:	a1 8c bf 17 f0       	mov    0xf017bf8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010215d:	83 c4 10             	add    $0x10,%esp
f0102160:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102165:	77 15                	ja     f010217c <mem_init+0x1134>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102167:	50                   	push   %eax
f0102168:	68 80 50 10 f0       	push   $0xf0105080
f010216d:	68 c1 00 00 00       	push   $0xc1
f0102172:	68 34 4c 10 f0       	push   $0xf0104c34
f0102177:	e8 24 df ff ff       	call   f01000a0 <_panic>
f010217c:	83 ec 08             	sub    $0x8,%esp
f010217f:	6a 04                	push   $0x4
f0102181:	05 00 00 00 10       	add    $0x10000000,%eax
f0102186:	50                   	push   %eax
f0102187:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010218c:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102191:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f0102196:	e8 3a ed ff ff       	call   f0100ed5 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010219b:	83 c4 10             	add    $0x10,%esp
f010219e:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f01021a3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021a8:	77 15                	ja     f01021bf <mem_init+0x1177>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021aa:	50                   	push   %eax
f01021ab:	68 80 50 10 f0       	push   $0xf0105080
f01021b0:	68 ce 00 00 00       	push   $0xce
f01021b5:	68 34 4c 10 f0       	push   $0xf0104c34
f01021ba:	e8 e1 de ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01021bf:	83 ec 08             	sub    $0x8,%esp
f01021c2:	6a 02                	push   $0x2
f01021c4:	68 00 00 11 00       	push   $0x110000
f01021c9:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021ce:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021d3:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f01021d8:	e8 f8 ec ff ff       	call   f0100ed5 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f01021dd:	83 c4 08             	add    $0x8,%esp
f01021e0:	6a 02                	push   $0x2
f01021e2:	6a 00                	push   $0x0
f01021e4:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021e9:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021ee:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
f01021f3:	e8 dd ec ff ff       	call   f0100ed5 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021f8:	8b 1d 48 cc 17 f0    	mov    0xf017cc48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021fe:	a1 44 cc 17 f0       	mov    0xf017cc44,%eax
f0102203:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102206:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010220d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102212:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102215:	8b 3d 4c cc 17 f0    	mov    0xf017cc4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010221b:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010221e:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102221:	be 00 00 00 00       	mov    $0x0,%esi
f0102226:	eb 55                	jmp    f010227d <mem_init+0x1235>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102228:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010222e:	89 d8                	mov    %ebx,%eax
f0102230:	e8 57 e7 ff ff       	call   f010098c <check_va2pa>
f0102235:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010223c:	77 15                	ja     f0102253 <mem_init+0x120b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010223e:	57                   	push   %edi
f010223f:	68 80 50 10 f0       	push   $0xf0105080
f0102244:	68 07 03 00 00       	push   $0x307
f0102249:	68 34 4c 10 f0       	push   $0xf0104c34
f010224e:	e8 4d de ff ff       	call   f01000a0 <_panic>
f0102253:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f010225a:	39 d0                	cmp    %edx,%eax
f010225c:	74 19                	je     f0102277 <mem_init+0x122f>
f010225e:	68 fc 54 10 f0       	push   $0xf01054fc
f0102263:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102268:	68 07 03 00 00       	push   $0x307
f010226d:	68 34 4c 10 f0       	push   $0xf0104c34
f0102272:	e8 29 de ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102277:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010227d:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102280:	77 a6                	ja     f0102228 <mem_init+0x11e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102282:	8b 3d 8c bf 17 f0    	mov    0xf017bf8c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102288:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010228b:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102290:	89 f2                	mov    %esi,%edx
f0102292:	89 d8                	mov    %ebx,%eax
f0102294:	e8 f3 e6 ff ff       	call   f010098c <check_va2pa>
f0102299:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01022a0:	77 15                	ja     f01022b7 <mem_init+0x126f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022a2:	57                   	push   %edi
f01022a3:	68 80 50 10 f0       	push   $0xf0105080
f01022a8:	68 0c 03 00 00       	push   $0x30c
f01022ad:	68 34 4c 10 f0       	push   $0xf0104c34
f01022b2:	e8 e9 dd ff ff       	call   f01000a0 <_panic>
f01022b7:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01022be:	39 c2                	cmp    %eax,%edx
f01022c0:	74 19                	je     f01022db <mem_init+0x1293>
f01022c2:	68 30 55 10 f0       	push   $0xf0105530
f01022c7:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01022cc:	68 0c 03 00 00       	push   $0x30c
f01022d1:	68 34 4c 10 f0       	push   $0xf0104c34
f01022d6:	e8 c5 dd ff ff       	call   f01000a0 <_panic>
f01022db:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022e1:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01022e7:	75 a7                	jne    f0102290 <mem_init+0x1248>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022e9:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01022ec:	c1 e7 0c             	shl    $0xc,%edi
f01022ef:	be 00 00 00 00       	mov    $0x0,%esi
f01022f4:	eb 30                	jmp    f0102326 <mem_init+0x12de>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01022f6:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01022fc:	89 d8                	mov    %ebx,%eax
f01022fe:	e8 89 e6 ff ff       	call   f010098c <check_va2pa>
f0102303:	39 c6                	cmp    %eax,%esi
f0102305:	74 19                	je     f0102320 <mem_init+0x12d8>
f0102307:	68 64 55 10 f0       	push   $0xf0105564
f010230c:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102311:	68 10 03 00 00       	push   $0x310
f0102316:	68 34 4c 10 f0       	push   $0xf0104c34
f010231b:	e8 80 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102320:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102326:	39 fe                	cmp    %edi,%esi
f0102328:	72 cc                	jb     f01022f6 <mem_init+0x12ae>
f010232a:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010232f:	89 f2                	mov    %esi,%edx
f0102331:	89 d8                	mov    %ebx,%eax
f0102333:	e8 54 e6 ff ff       	call   f010098c <check_va2pa>
f0102338:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f010233e:	39 c2                	cmp    %eax,%edx
f0102340:	74 19                	je     f010235b <mem_init+0x1313>
f0102342:	68 8c 55 10 f0       	push   $0xf010558c
f0102347:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010234c:	68 14 03 00 00       	push   $0x314
f0102351:	68 34 4c 10 f0       	push   $0xf0104c34
f0102356:	e8 45 dd ff ff       	call   f01000a0 <_panic>
f010235b:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102361:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102367:	75 c6                	jne    f010232f <mem_init+0x12e7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102369:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010236e:	89 d8                	mov    %ebx,%eax
f0102370:	e8 17 e6 ff ff       	call   f010098c <check_va2pa>
f0102375:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102378:	74 51                	je     f01023cb <mem_init+0x1383>
f010237a:	68 d4 55 10 f0       	push   $0xf01055d4
f010237f:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102384:	68 15 03 00 00       	push   $0x315
f0102389:	68 34 4c 10 f0       	push   $0xf0104c34
f010238e:	e8 0d dd ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102393:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102398:	72 36                	jb     f01023d0 <mem_init+0x1388>
f010239a:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010239f:	76 07                	jbe    f01023a8 <mem_init+0x1360>
f01023a1:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023a6:	75 28                	jne    f01023d0 <mem_init+0x1388>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01023a8:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01023ac:	0f 85 83 00 00 00    	jne    f0102435 <mem_init+0x13ed>
f01023b2:	68 0b 4f 10 f0       	push   $0xf0104f0b
f01023b7:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01023bc:	68 1e 03 00 00       	push   $0x31e
f01023c1:	68 34 4c 10 f0       	push   $0xf0104c34
f01023c6:	e8 d5 dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023cb:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01023d0:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023d5:	76 3f                	jbe    f0102416 <mem_init+0x13ce>
				assert(pgdir[i] & PTE_P);
f01023d7:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01023da:	f6 c2 01             	test   $0x1,%dl
f01023dd:	75 19                	jne    f01023f8 <mem_init+0x13b0>
f01023df:	68 0b 4f 10 f0       	push   $0xf0104f0b
f01023e4:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01023e9:	68 22 03 00 00       	push   $0x322
f01023ee:	68 34 4c 10 f0       	push   $0xf0104c34
f01023f3:	e8 a8 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01023f8:	f6 c2 02             	test   $0x2,%dl
f01023fb:	75 38                	jne    f0102435 <mem_init+0x13ed>
f01023fd:	68 1c 4f 10 f0       	push   $0xf0104f1c
f0102402:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102407:	68 23 03 00 00       	push   $0x323
f010240c:	68 34 4c 10 f0       	push   $0xf0104c34
f0102411:	e8 8a dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102416:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010241a:	74 19                	je     f0102435 <mem_init+0x13ed>
f010241c:	68 2d 4f 10 f0       	push   $0xf0104f2d
f0102421:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102426:	68 25 03 00 00       	push   $0x325
f010242b:	68 34 4c 10 f0       	push   $0xf0104c34
f0102430:	e8 6b dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102435:	83 c0 01             	add    $0x1,%eax
f0102438:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010243d:	0f 86 50 ff ff ff    	jbe    f0102393 <mem_init+0x134b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102443:	83 ec 0c             	sub    $0xc,%esp
f0102446:	68 04 56 10 f0       	push   $0xf0105604
f010244b:	e8 22 0b 00 00       	call   f0102f72 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102450:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102455:	83 c4 10             	add    $0x10,%esp
f0102458:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010245d:	77 15                	ja     f0102474 <mem_init+0x142c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010245f:	50                   	push   %eax
f0102460:	68 80 50 10 f0       	push   $0xf0105080
f0102465:	68 e5 00 00 00       	push   $0xe5
f010246a:	68 34 4c 10 f0       	push   $0xf0104c34
f010246f:	e8 2c dc ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102474:	05 00 00 00 10       	add    $0x10000000,%eax
f0102479:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010247c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102481:	e8 6a e5 ff ff       	call   f01009f0 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102486:	0f 20 c0             	mov    %cr0,%eax
f0102489:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010248c:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102491:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102494:	83 ec 0c             	sub    $0xc,%esp
f0102497:	6a 00                	push   $0x0
f0102499:	e8 b0 e8 ff ff       	call   f0100d4e <page_alloc>
f010249e:	89 c3                	mov    %eax,%ebx
f01024a0:	83 c4 10             	add    $0x10,%esp
f01024a3:	85 c0                	test   %eax,%eax
f01024a5:	75 19                	jne    f01024c0 <mem_init+0x1478>
f01024a7:	68 29 4d 10 f0       	push   $0xf0104d29
f01024ac:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01024b1:	68 e5 03 00 00       	push   $0x3e5
f01024b6:	68 34 4c 10 f0       	push   $0xf0104c34
f01024bb:	e8 e0 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01024c0:	83 ec 0c             	sub    $0xc,%esp
f01024c3:	6a 00                	push   $0x0
f01024c5:	e8 84 e8 ff ff       	call   f0100d4e <page_alloc>
f01024ca:	89 c7                	mov    %eax,%edi
f01024cc:	83 c4 10             	add    $0x10,%esp
f01024cf:	85 c0                	test   %eax,%eax
f01024d1:	75 19                	jne    f01024ec <mem_init+0x14a4>
f01024d3:	68 3f 4d 10 f0       	push   $0xf0104d3f
f01024d8:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01024dd:	68 e6 03 00 00       	push   $0x3e6
f01024e2:	68 34 4c 10 f0       	push   $0xf0104c34
f01024e7:	e8 b4 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01024ec:	83 ec 0c             	sub    $0xc,%esp
f01024ef:	6a 00                	push   $0x0
f01024f1:	e8 58 e8 ff ff       	call   f0100d4e <page_alloc>
f01024f6:	89 c6                	mov    %eax,%esi
f01024f8:	83 c4 10             	add    $0x10,%esp
f01024fb:	85 c0                	test   %eax,%eax
f01024fd:	75 19                	jne    f0102518 <mem_init+0x14d0>
f01024ff:	68 55 4d 10 f0       	push   $0xf0104d55
f0102504:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102509:	68 e7 03 00 00       	push   $0x3e7
f010250e:	68 34 4c 10 f0       	push   $0xf0104c34
f0102513:	e8 88 db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102518:	83 ec 0c             	sub    $0xc,%esp
f010251b:	53                   	push   %ebx
f010251c:	e8 a4 e8 ff ff       	call   f0100dc5 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102521:	89 f8                	mov    %edi,%eax
f0102523:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0102529:	c1 f8 03             	sar    $0x3,%eax
f010252c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010252f:	89 c2                	mov    %eax,%edx
f0102531:	c1 ea 0c             	shr    $0xc,%edx
f0102534:	83 c4 10             	add    $0x10,%esp
f0102537:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f010253d:	72 12                	jb     f0102551 <mem_init+0x1509>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010253f:	50                   	push   %eax
f0102540:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0102545:	6a 56                	push   $0x56
f0102547:	68 40 4c 10 f0       	push   $0xf0104c40
f010254c:	e8 4f db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102551:	83 ec 04             	sub    $0x4,%esp
f0102554:	68 00 10 00 00       	push   $0x1000
f0102559:	6a 01                	push   $0x1
f010255b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102560:	50                   	push   %eax
f0102561:	e8 12 1d 00 00       	call   f0104278 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102566:	89 f0                	mov    %esi,%eax
f0102568:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f010256e:	c1 f8 03             	sar    $0x3,%eax
f0102571:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102574:	89 c2                	mov    %eax,%edx
f0102576:	c1 ea 0c             	shr    $0xc,%edx
f0102579:	83 c4 10             	add    $0x10,%esp
f010257c:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f0102582:	72 12                	jb     f0102596 <mem_init+0x154e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102584:	50                   	push   %eax
f0102585:	68 3c 4f 10 f0       	push   $0xf0104f3c
f010258a:	6a 56                	push   $0x56
f010258c:	68 40 4c 10 f0       	push   $0xf0104c40
f0102591:	e8 0a db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102596:	83 ec 04             	sub    $0x4,%esp
f0102599:	68 00 10 00 00       	push   $0x1000
f010259e:	6a 02                	push   $0x2
f01025a0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025a5:	50                   	push   %eax
f01025a6:	e8 cd 1c 00 00       	call   f0104278 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01025ab:	6a 02                	push   $0x2
f01025ad:	68 00 10 00 00       	push   $0x1000
f01025b2:	57                   	push   %edi
f01025b3:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f01025b9:	e8 12 ea ff ff       	call   f0100fd0 <page_insert>
	assert(pp1->pp_ref == 1);
f01025be:	83 c4 20             	add    $0x20,%esp
f01025c1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01025c6:	74 19                	je     f01025e1 <mem_init+0x1599>
f01025c8:	68 26 4e 10 f0       	push   $0xf0104e26
f01025cd:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01025d2:	68 ec 03 00 00       	push   $0x3ec
f01025d7:	68 34 4c 10 f0       	push   $0xf0104c34
f01025dc:	e8 bf da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01025e1:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01025e8:	01 01 01 
f01025eb:	74 19                	je     f0102606 <mem_init+0x15be>
f01025ed:	68 24 56 10 f0       	push   $0xf0105624
f01025f2:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01025f7:	68 ed 03 00 00       	push   $0x3ed
f01025fc:	68 34 4c 10 f0       	push   $0xf0104c34
f0102601:	e8 9a da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102606:	6a 02                	push   $0x2
f0102608:	68 00 10 00 00       	push   $0x1000
f010260d:	56                   	push   %esi
f010260e:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f0102614:	e8 b7 e9 ff ff       	call   f0100fd0 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102619:	83 c4 10             	add    $0x10,%esp
f010261c:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102623:	02 02 02 
f0102626:	74 19                	je     f0102641 <mem_init+0x15f9>
f0102628:	68 48 56 10 f0       	push   $0xf0105648
f010262d:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102632:	68 ef 03 00 00       	push   $0x3ef
f0102637:	68 34 4c 10 f0       	push   $0xf0104c34
f010263c:	e8 5f da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0102641:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102646:	74 19                	je     f0102661 <mem_init+0x1619>
f0102648:	68 48 4e 10 f0       	push   $0xf0104e48
f010264d:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102652:	68 f0 03 00 00       	push   $0x3f0
f0102657:	68 34 4c 10 f0       	push   $0xf0104c34
f010265c:	e8 3f da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0102661:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102666:	74 19                	je     f0102681 <mem_init+0x1639>
f0102668:	68 b2 4e 10 f0       	push   $0xf0104eb2
f010266d:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102672:	68 f1 03 00 00       	push   $0x3f1
f0102677:	68 34 4c 10 f0       	push   $0xf0104c34
f010267c:	e8 1f da ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102681:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102688:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010268b:	89 f0                	mov    %esi,%eax
f010268d:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0102693:	c1 f8 03             	sar    $0x3,%eax
f0102696:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102699:	89 c2                	mov    %eax,%edx
f010269b:	c1 ea 0c             	shr    $0xc,%edx
f010269e:	3b 15 44 cc 17 f0    	cmp    0xf017cc44,%edx
f01026a4:	72 12                	jb     f01026b8 <mem_init+0x1670>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026a6:	50                   	push   %eax
f01026a7:	68 3c 4f 10 f0       	push   $0xf0104f3c
f01026ac:	6a 56                	push   $0x56
f01026ae:	68 40 4c 10 f0       	push   $0xf0104c40
f01026b3:	e8 e8 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01026b8:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01026bf:	03 03 03 
f01026c2:	74 19                	je     f01026dd <mem_init+0x1695>
f01026c4:	68 6c 56 10 f0       	push   $0xf010566c
f01026c9:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01026ce:	68 f3 03 00 00       	push   $0x3f3
f01026d3:	68 34 4c 10 f0       	push   $0xf0104c34
f01026d8:	e8 c3 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01026dd:	83 ec 08             	sub    $0x8,%esp
f01026e0:	68 00 10 00 00       	push   $0x1000
f01026e5:	ff 35 48 cc 17 f0    	pushl  0xf017cc48
f01026eb:	e8 9e e8 ff ff       	call   f0100f8e <page_remove>
	assert(pp2->pp_ref == 0);
f01026f0:	83 c4 10             	add    $0x10,%esp
f01026f3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026f8:	74 19                	je     f0102713 <mem_init+0x16cb>
f01026fa:	68 80 4e 10 f0       	push   $0xf0104e80
f01026ff:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102704:	68 f5 03 00 00       	push   $0x3f5
f0102709:	68 34 4c 10 f0       	push   $0xf0104c34
f010270e:	e8 8d d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102713:	8b 0d 48 cc 17 f0    	mov    0xf017cc48,%ecx
f0102719:	8b 11                	mov    (%ecx),%edx
f010271b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102721:	89 d8                	mov    %ebx,%eax
f0102723:	2b 05 4c cc 17 f0    	sub    0xf017cc4c,%eax
f0102729:	c1 f8 03             	sar    $0x3,%eax
f010272c:	c1 e0 0c             	shl    $0xc,%eax
f010272f:	39 c2                	cmp    %eax,%edx
f0102731:	74 19                	je     f010274c <mem_init+0x1704>
f0102733:	68 7c 51 10 f0       	push   $0xf010517c
f0102738:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010273d:	68 f8 03 00 00       	push   $0x3f8
f0102742:	68 34 4c 10 f0       	push   $0xf0104c34
f0102747:	e8 54 d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f010274c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102752:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102757:	74 19                	je     f0102772 <mem_init+0x172a>
f0102759:	68 37 4e 10 f0       	push   $0xf0104e37
f010275e:	68 5a 4c 10 f0       	push   $0xf0104c5a
f0102763:	68 fa 03 00 00       	push   $0x3fa
f0102768:	68 34 4c 10 f0       	push   $0xf0104c34
f010276d:	e8 2e d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102772:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102778:	83 ec 0c             	sub    $0xc,%esp
f010277b:	53                   	push   %ebx
f010277c:	e8 44 e6 ff ff       	call   f0100dc5 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102781:	c7 04 24 98 56 10 f0 	movl   $0xf0105698,(%esp)
f0102788:	e8 e5 07 00 00       	call   f0102f72 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010278d:	83 c4 10             	add    $0x10,%esp
f0102790:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102793:	5b                   	pop    %ebx
f0102794:	5e                   	pop    %esi
f0102795:	5f                   	pop    %edi
f0102796:	5d                   	pop    %ebp
f0102797:	c3                   	ret    

f0102798 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102798:	55                   	push   %ebp
f0102799:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010279b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010279e:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01027a1:	5d                   	pop    %ebp
f01027a2:	c3                   	ret    

f01027a3 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01027a3:	55                   	push   %ebp
f01027a4:	89 e5                	mov    %esp,%ebp
f01027a6:	57                   	push   %edi
f01027a7:	56                   	push   %esi
f01027a8:	53                   	push   %ebx
f01027a9:	83 ec 1c             	sub    $0x1c,%esp
f01027ac:	8b 7d 08             	mov    0x8(%ebp),%edi
f01027af:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	char * end = NULL;
	char * start = NULL;
	start = ROUNDDOWN((char *)va, PGSIZE); 
f01027b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027b5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027ba:	89 c3                	mov    %eax,%ebx
f01027bc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	end = ROUNDUP((char *)(va + len), PGSIZE);
f01027bf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027c2:	03 45 10             	add    0x10(%ebp),%eax
f01027c5:	05 ff 0f 00 00       	add    $0xfff,%eax
f01027ca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027cf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t *cur = NULL;

	for(; start < end; start += PGSIZE) {
f01027d2:	eb 4e                	jmp    f0102822 <user_mem_check+0x7f>
		cur = pgdir_walk(env->env_pgdir, (void *)start, 0);
f01027d4:	83 ec 04             	sub    $0x4,%esp
f01027d7:	6a 00                	push   $0x0
f01027d9:	53                   	push   %ebx
f01027da:	ff 77 5c             	pushl  0x5c(%edi)
f01027dd:	e8 60 e6 ff ff       	call   f0100e42 <pgdir_walk>
		if((int)start > ULIM || cur == NULL || ((uint32_t)(*cur) & perm) != perm) {
f01027e2:	89 da                	mov    %ebx,%edx
f01027e4:	83 c4 10             	add    $0x10,%esp
f01027e7:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f01027ed:	77 0c                	ja     f01027fb <user_mem_check+0x58>
f01027ef:	85 c0                	test   %eax,%eax
f01027f1:	74 08                	je     f01027fb <user_mem_check+0x58>
f01027f3:	89 f1                	mov    %esi,%ecx
f01027f5:	23 08                	and    (%eax),%ecx
f01027f7:	39 ce                	cmp    %ecx,%esi
f01027f9:	74 21                	je     f010281c <user_mem_check+0x79>
			  if(start == ROUNDDOWN((char *)va, PGSIZE)) {
f01027fb:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f01027fe:	75 0f                	jne    f010280f <user_mem_check+0x6c>
					user_mem_check_addr = (uintptr_t)va;
f0102800:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102803:	a3 7c bf 17 f0       	mov    %eax,0xf017bf7c
			  }
			  else {
			  		user_mem_check_addr = (uintptr_t)start;
			  }
			  return -E_FAULT;
f0102808:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010280d:	eb 1d                	jmp    f010282c <user_mem_check+0x89>
		if((int)start > ULIM || cur == NULL || ((uint32_t)(*cur) & perm) != perm) {
			  if(start == ROUNDDOWN((char *)va, PGSIZE)) {
					user_mem_check_addr = (uintptr_t)va;
			  }
			  else {
			  		user_mem_check_addr = (uintptr_t)start;
f010280f:	89 15 7c bf 17 f0    	mov    %edx,0xf017bf7c
			  }
			  return -E_FAULT;
f0102815:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010281a:	eb 10                	jmp    f010282c <user_mem_check+0x89>
	char * start = NULL;
	start = ROUNDDOWN((char *)va, PGSIZE); 
	end = ROUNDUP((char *)(va + len), PGSIZE);
	pte_t *cur = NULL;

	for(; start < end; start += PGSIZE) {
f010281c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102822:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102825:	72 ad                	jb     f01027d4 <user_mem_check+0x31>
			  return -E_FAULT;
		}
		
	}
		
	return 0;
f0102827:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010282c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010282f:	5b                   	pop    %ebx
f0102830:	5e                   	pop    %esi
f0102831:	5f                   	pop    %edi
f0102832:	5d                   	pop    %ebp
f0102833:	c3                   	ret    

f0102834 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102834:	55                   	push   %ebp
f0102835:	89 e5                	mov    %esp,%ebp
f0102837:	53                   	push   %ebx
f0102838:	83 ec 04             	sub    $0x4,%esp
f010283b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f010283e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102841:	83 c8 04             	or     $0x4,%eax
f0102844:	50                   	push   %eax
f0102845:	ff 75 10             	pushl  0x10(%ebp)
f0102848:	ff 75 0c             	pushl  0xc(%ebp)
f010284b:	53                   	push   %ebx
f010284c:	e8 52 ff ff ff       	call   f01027a3 <user_mem_check>
f0102851:	83 c4 10             	add    $0x10,%esp
f0102854:	85 c0                	test   %eax,%eax
f0102856:	79 21                	jns    f0102879 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102858:	83 ec 04             	sub    $0x4,%esp
f010285b:	ff 35 7c bf 17 f0    	pushl  0xf017bf7c
f0102861:	ff 73 48             	pushl  0x48(%ebx)
f0102864:	68 c4 56 10 f0       	push   $0xf01056c4
f0102869:	e8 04 07 00 00       	call   f0102f72 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f010286e:	89 1c 24             	mov    %ebx,(%esp)
f0102871:	e8 e3 05 00 00       	call   f0102e59 <env_destroy>
f0102876:	83 c4 10             	add    $0x10,%esp
	}
}
f0102879:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010287c:	c9                   	leave  
f010287d:	c3                   	ret    

f010287e <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010287e:	55                   	push   %ebp
f010287f:	89 e5                	mov    %esp,%ebp
f0102881:	57                   	push   %edi
f0102882:	56                   	push   %esi
f0102883:	53                   	push   %ebx
f0102884:	83 ec 0c             	sub    $0xc,%esp
f0102887:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
f0102889:	89 d3                	mov    %edx,%ebx
f010288b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
f0102891:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102898:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE){
f010289e:	eb 58                	jmp    f01028f8 <region_alloc+0x7a>
		p = page_alloc(0);
f01028a0:	83 ec 0c             	sub    $0xc,%esp
f01028a3:	6a 00                	push   $0x0
f01028a5:	e8 a4 e4 ff ff       	call   f0100d4e <page_alloc>
		if(p == NULL)
f01028aa:	83 c4 10             	add    $0x10,%esp
f01028ad:	85 c0                	test   %eax,%eax
f01028af:	75 17                	jne    f01028c8 <region_alloc+0x4a>
			panic(" region alloc, allocation failed.");
f01028b1:	83 ec 04             	sub    $0x4,%esp
f01028b4:	68 fc 56 10 f0       	push   $0xf01056fc
f01028b9:	68 24 01 00 00       	push   $0x124
f01028be:	68 e6 57 10 f0       	push   $0xf01057e6
f01028c3:	e8 d8 d7 ff ff       	call   f01000a0 <_panic>

		r = page_insert(e->env_pgdir, p, i, PTE_W | PTE_U);
f01028c8:	6a 06                	push   $0x6
f01028ca:	53                   	push   %ebx
f01028cb:	50                   	push   %eax
f01028cc:	ff 77 5c             	pushl  0x5c(%edi)
f01028cf:	e8 fc e6 ff ff       	call   f0100fd0 <page_insert>
		if(r != 0) {
f01028d4:	83 c4 10             	add    $0x10,%esp
f01028d7:	85 c0                	test   %eax,%eax
f01028d9:	74 17                	je     f01028f2 <region_alloc+0x74>
			panic("region alloc error");
f01028db:	83 ec 04             	sub    $0x4,%esp
f01028de:	68 f1 57 10 f0       	push   $0xf01057f1
f01028e3:	68 28 01 00 00       	push   $0x128
f01028e8:	68 e6 57 10 f0       	push   $0xf01057e6
f01028ed:	e8 ae d7 ff ff       	call   f01000a0 <_panic>
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE){
f01028f2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028f8:	39 f3                	cmp    %esi,%ebx
f01028fa:	72 a4                	jb     f01028a0 <region_alloc+0x22>
	}
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f01028fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028ff:	5b                   	pop    %ebx
f0102900:	5e                   	pop    %esi
f0102901:	5f                   	pop    %edi
f0102902:	5d                   	pop    %ebp
f0102903:	c3                   	ret    

f0102904 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102904:	55                   	push   %ebp
f0102905:	89 e5                	mov    %esp,%ebp
f0102907:	8b 55 08             	mov    0x8(%ebp),%edx
f010290a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010290d:	85 d2                	test   %edx,%edx
f010290f:	75 11                	jne    f0102922 <envid2env+0x1e>
		*env_store = curenv;
f0102911:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f0102916:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102919:	89 01                	mov    %eax,(%ecx)
		return 0;
f010291b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102920:	eb 5e                	jmp    f0102980 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102922:	89 d0                	mov    %edx,%eax
f0102924:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102929:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010292c:	c1 e0 05             	shl    $0x5,%eax
f010292f:	03 05 8c bf 17 f0    	add    0xf017bf8c,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102935:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102939:	74 05                	je     f0102940 <envid2env+0x3c>
f010293b:	3b 50 48             	cmp    0x48(%eax),%edx
f010293e:	74 10                	je     f0102950 <envid2env+0x4c>
		*env_store = 0;
f0102940:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102943:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102949:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010294e:	eb 30                	jmp    f0102980 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102950:	84 c9                	test   %cl,%cl
f0102952:	74 22                	je     f0102976 <envid2env+0x72>
f0102954:	8b 15 88 bf 17 f0    	mov    0xf017bf88,%edx
f010295a:	39 d0                	cmp    %edx,%eax
f010295c:	74 18                	je     f0102976 <envid2env+0x72>
f010295e:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102961:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102964:	74 10                	je     f0102976 <envid2env+0x72>
		*env_store = 0;
f0102966:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102969:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010296f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102974:	eb 0a                	jmp    f0102980 <envid2env+0x7c>
	}

	*env_store = e;
f0102976:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102979:	89 01                	mov    %eax,(%ecx)
	return 0;
f010297b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102980:	5d                   	pop    %ebp
f0102981:	c3                   	ret    

f0102982 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102982:	55                   	push   %ebp
f0102983:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102985:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f010298a:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f010298d:	b8 23 00 00 00       	mov    $0x23,%eax
f0102992:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102994:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102996:	b8 10 00 00 00       	mov    $0x10,%eax
f010299b:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f010299d:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f010299f:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01029a1:	ea a8 29 10 f0 08 00 	ljmp   $0x8,$0xf01029a8
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01029a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01029ad:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01029b0:	5d                   	pop    %ebp
f01029b1:	c3                   	ret    

f01029b2 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01029b2:	55                   	push   %ebp
f01029b3:	89 e5                	mov    %esp,%ebp
f01029b5:	56                   	push   %esi
f01029b6:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--){
		envs[i].env_id = 0;
f01029b7:	8b 35 8c bf 17 f0    	mov    0xf017bf8c,%esi
f01029bd:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01029c3:	8d 5e a0             	lea    -0x60(%esi),%ebx
f01029c6:	ba 00 00 00 00       	mov    $0x0,%edx
f01029cb:	89 c1                	mov    %eax,%ecx
f01029cd:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f01029d4:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f01029db:	89 50 44             	mov    %edx,0x44(%eax)
f01029de:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f01029e1:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--){
f01029e3:	39 d8                	cmp    %ebx,%eax
f01029e5:	75 e4                	jne    f01029cb <env_init+0x19>
f01029e7:	89 35 90 bf 17 f0    	mov    %esi,0xf017bf90
		envs[i].env_status = ENV_FREE;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f01029ed:	e8 90 ff ff ff       	call   f0102982 <env_init_percpu>
}
f01029f2:	5b                   	pop    %ebx
f01029f3:	5e                   	pop    %esi
f01029f4:	5d                   	pop    %ebp
f01029f5:	c3                   	ret    

f01029f6 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01029f6:	55                   	push   %ebp
f01029f7:	89 e5                	mov    %esp,%ebp
f01029f9:	53                   	push   %ebx
f01029fa:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01029fd:	8b 1d 90 bf 17 f0    	mov    0xf017bf90,%ebx
f0102a03:	85 db                	test   %ebx,%ebx
f0102a05:	0f 84 61 01 00 00    	je     f0102b6c <env_alloc+0x176>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102a0b:	83 ec 0c             	sub    $0xc,%esp
f0102a0e:	6a 01                	push   $0x1
f0102a10:	e8 39 e3 ff ff       	call   f0100d4e <page_alloc>
f0102a15:	83 c4 10             	add    $0x10,%esp
f0102a18:	85 c0                	test   %eax,%eax
f0102a1a:	0f 84 53 01 00 00    	je     f0102b73 <env_alloc+0x17d>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a20:	89 c2                	mov    %eax,%edx
f0102a22:	2b 15 4c cc 17 f0    	sub    0xf017cc4c,%edx
f0102a28:	c1 fa 03             	sar    $0x3,%edx
f0102a2b:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a2e:	89 d1                	mov    %edx,%ecx
f0102a30:	c1 e9 0c             	shr    $0xc,%ecx
f0102a33:	3b 0d 44 cc 17 f0    	cmp    0xf017cc44,%ecx
f0102a39:	72 12                	jb     f0102a4d <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a3b:	52                   	push   %edx
f0102a3c:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0102a41:	6a 56                	push   $0x56
f0102a43:	68 40 4c 10 f0       	push   $0xf0104c40
f0102a48:	e8 53 d6 ff ff       	call   f01000a0 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
f0102a4d:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102a53:	89 53 5c             	mov    %edx,0x5c(%ebx)
	p->pp_ref++;
f0102a56:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0102a5b:	b8 00 00 00 00       	mov    $0x0,%eax

	//Map the directory below UTOP.
	for(i = 0; i < PDX(UTOP); i++) {
		e->env_pgdir[i] = 0;		
f0102a60:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0102a63:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0102a6a:	83 c0 04             	add    $0x4,%eax
	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;

	//Map the directory below UTOP.
	for(i = 0; i < PDX(UTOP); i++) {
f0102a6d:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0102a72:	75 ec                	jne    f0102a60 <env_alloc+0x6a>
		e->env_pgdir[i] = 0;		
	}

	//Map the directory above UTOP
	for(i = PDX(UTOP); i < NPDENTRIES; i++) {
		e->env_pgdir[i] = kern_pgdir[i];
f0102a74:	8b 15 48 cc 17 f0    	mov    0xf017cc48,%edx
f0102a7a:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102a7d:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0102a80:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102a83:	83 c0 04             	add    $0x4,%eax
	for(i = 0; i < PDX(UTOP); i++) {
		e->env_pgdir[i] = 0;		
	}

	//Map the directory above UTOP
	for(i = PDX(UTOP); i < NPDENTRIES; i++) {
f0102a86:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102a8b:	75 e7                	jne    f0102a74 <env_alloc+0x7e>
		e->env_pgdir[i] = kern_pgdir[i];
	}
		
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102a8d:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a90:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a95:	77 15                	ja     f0102aac <env_alloc+0xb6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a97:	50                   	push   %eax
f0102a98:	68 80 50 10 f0       	push   $0xf0105080
f0102a9d:	68 cc 00 00 00       	push   $0xcc
f0102aa2:	68 e6 57 10 f0       	push   $0xf01057e6
f0102aa7:	e8 f4 d5 ff ff       	call   f01000a0 <_panic>
f0102aac:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102ab2:	83 ca 05             	or     $0x5,%edx
f0102ab5:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102abb:	8b 43 48             	mov    0x48(%ebx),%eax
f0102abe:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102ac3:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102ac8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102acd:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102ad0:	89 da                	mov    %ebx,%edx
f0102ad2:	2b 15 8c bf 17 f0    	sub    0xf017bf8c,%edx
f0102ad8:	c1 fa 05             	sar    $0x5,%edx
f0102adb:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102ae1:	09 d0                	or     %edx,%eax
f0102ae3:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102ae6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ae9:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102aec:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102af3:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102afa:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102b01:	83 ec 04             	sub    $0x4,%esp
f0102b04:	6a 44                	push   $0x44
f0102b06:	6a 00                	push   $0x0
f0102b08:	53                   	push   %ebx
f0102b09:	e8 6a 17 00 00       	call   f0104278 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102b0e:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102b14:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102b1a:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102b20:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102b27:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102b2d:	8b 43 44             	mov    0x44(%ebx),%eax
f0102b30:	a3 90 bf 17 f0       	mov    %eax,0xf017bf90
	*newenv_store = e;
f0102b35:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b38:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102b3a:	8b 53 48             	mov    0x48(%ebx),%edx
f0102b3d:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f0102b42:	83 c4 10             	add    $0x10,%esp
f0102b45:	85 c0                	test   %eax,%eax
f0102b47:	74 05                	je     f0102b4e <env_alloc+0x158>
f0102b49:	8b 40 48             	mov    0x48(%eax),%eax
f0102b4c:	eb 05                	jmp    f0102b53 <env_alloc+0x15d>
f0102b4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b53:	83 ec 04             	sub    $0x4,%esp
f0102b56:	52                   	push   %edx
f0102b57:	50                   	push   %eax
f0102b58:	68 04 58 10 f0       	push   $0xf0105804
f0102b5d:	e8 10 04 00 00       	call   f0102f72 <cprintf>
	return 0;
f0102b62:	83 c4 10             	add    $0x10,%esp
f0102b65:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b6a:	eb 0c                	jmp    f0102b78 <env_alloc+0x182>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102b6c:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102b71:	eb 05                	jmp    f0102b78 <env_alloc+0x182>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102b73:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102b78:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102b7b:	c9                   	leave  
f0102b7c:	c3                   	ret    

f0102b7d <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102b7d:	55                   	push   %ebp
f0102b7e:	89 e5                	mov    %esp,%ebp
f0102b80:	57                   	push   %edi
f0102b81:	56                   	push   %esi
f0102b82:	53                   	push   %ebx
f0102b83:	83 ec 34             	sub    $0x34,%esp
f0102b86:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int rc;
	if((rc = env_alloc(&e, 0)) != 0) {
f0102b89:	6a 00                	push   $0x0
f0102b8b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102b8e:	50                   	push   %eax
f0102b8f:	e8 62 fe ff ff       	call   f01029f6 <env_alloc>
f0102b94:	83 c4 10             	add    $0x10,%esp
f0102b97:	85 c0                	test   %eax,%eax
f0102b99:	74 17                	je     f0102bb2 <env_create+0x35>
		panic("env_create failed: env_alloc failed.\n");
f0102b9b:	83 ec 04             	sub    $0x4,%esp
f0102b9e:	68 20 57 10 f0       	push   $0xf0105720
f0102ba3:	68 98 01 00 00       	push   $0x198
f0102ba8:	68 e6 57 10 f0       	push   $0xf01057e6
f0102bad:	e8 ee d4 ff ff       	call   f01000a0 <_panic>
	}

	load_icode(e, binary);
f0102bb2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102bb5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf* header = (struct Elf*)binary;
	
	if(header->e_magic != ELF_MAGIC) {
f0102bb8:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102bbe:	74 17                	je     f0102bd7 <env_create+0x5a>
		panic("load_icode failed: The binary we load is not elf.\n");
f0102bc0:	83 ec 04             	sub    $0x4,%esp
f0102bc3:	68 48 57 10 f0       	push   $0xf0105748
f0102bc8:	68 6a 01 00 00       	push   $0x16a
f0102bcd:	68 e6 57 10 f0       	push   $0xf01057e6
f0102bd2:	e8 c9 d4 ff ff       	call   f01000a0 <_panic>
	}

	if(header->e_entry == 0){
f0102bd7:	8b 47 18             	mov    0x18(%edi),%eax
f0102bda:	85 c0                	test   %eax,%eax
f0102bdc:	75 17                	jne    f0102bf5 <env_create+0x78>
		panic("load_icode failed: The elf file can't be excuterd.\n");
f0102bde:	83 ec 04             	sub    $0x4,%esp
f0102be1:	68 7c 57 10 f0       	push   $0xf010577c
f0102be6:	68 6e 01 00 00       	push   $0x16e
f0102beb:	68 e6 57 10 f0       	push   $0xf01057e6
f0102bf0:	e8 ab d4 ff ff       	call   f01000a0 <_panic>
	}

	e->env_tf.tf_eip = header->e_entry;
f0102bf5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102bf8:	89 41 30             	mov    %eax,0x30(%ecx)

	lcr3(PADDR(e->env_pgdir));   //?????
f0102bfb:	8b 41 5c             	mov    0x5c(%ecx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bfe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c03:	77 15                	ja     f0102c1a <env_create+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c05:	50                   	push   %eax
f0102c06:	68 80 50 10 f0       	push   $0xf0105080
f0102c0b:	68 73 01 00 00       	push   $0x173
f0102c10:	68 e6 57 10 f0       	push   $0xf01057e6
f0102c15:	e8 86 d4 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102c1a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c1f:	0f 22 d8             	mov    %eax,%cr3

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
f0102c22:	89 fb                	mov    %edi,%ebx
f0102c24:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + header->e_phnum;
f0102c27:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102c2b:	c1 e6 05             	shl    $0x5,%esi
f0102c2e:	01 de                	add    %ebx,%esi
f0102c30:	eb 44                	jmp    f0102c76 <env_create+0xf9>
	for(; ph < eph; ph++) {
		if(ph->p_type == ELF_PROG_LOAD) {
f0102c32:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102c35:	75 3c                	jne    f0102c73 <env_create+0xf6>
			if(ph->p_memsz - ph->p_filesz < 0) {
				panic("load icode failed : p_memsz < p_filesz.\n");
			}

			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102c37:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102c3a:	8b 53 08             	mov    0x8(%ebx),%edx
f0102c3d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c40:	e8 39 fc ff ff       	call   f010287e <region_alloc>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102c45:	83 ec 04             	sub    $0x4,%esp
f0102c48:	ff 73 10             	pushl  0x10(%ebx)
f0102c4b:	89 f8                	mov    %edi,%eax
f0102c4d:	03 43 04             	add    0x4(%ebx),%eax
f0102c50:	50                   	push   %eax
f0102c51:	ff 73 08             	pushl  0x8(%ebx)
f0102c54:	e8 6c 16 00 00       	call   f01042c5 <memmove>
			memset((void *)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f0102c59:	8b 43 10             	mov    0x10(%ebx),%eax
f0102c5c:	83 c4 0c             	add    $0xc,%esp
f0102c5f:	8b 53 14             	mov    0x14(%ebx),%edx
f0102c62:	29 c2                	sub    %eax,%edx
f0102c64:	52                   	push   %edx
f0102c65:	6a 00                	push   $0x0
f0102c67:	03 43 08             	add    0x8(%ebx),%eax
f0102c6a:	50                   	push   %eax
f0102c6b:	e8 08 16 00 00       	call   f0104278 <memset>
f0102c70:	83 c4 10             	add    $0x10,%esp
	lcr3(PADDR(e->env_pgdir));   //?????

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
	eph = ph + header->e_phnum;
	for(; ph < eph; ph++) {
f0102c73:	83 c3 20             	add    $0x20,%ebx
f0102c76:	39 de                	cmp    %ebx,%esi
f0102c78:	77 b8                	ja     f0102c32 <env_create+0xb5>
		}
	} 
	 
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	region_alloc(e,(void *)(USTACKTOP-PGSIZE), PGSIZE);
f0102c7a:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102c7f:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102c84:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c87:	e8 f2 fb ff ff       	call   f010287e <region_alloc>
	if((rc = env_alloc(&e, 0)) != 0) {
		panic("env_create failed: env_alloc failed.\n");
	}

	load_icode(e, binary);
	e->env_type = type;
f0102c8c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c8f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c92:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102c95:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c98:	5b                   	pop    %ebx
f0102c99:	5e                   	pop    %esi
f0102c9a:	5f                   	pop    %edi
f0102c9b:	5d                   	pop    %ebp
f0102c9c:	c3                   	ret    

f0102c9d <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102c9d:	55                   	push   %ebp
f0102c9e:	89 e5                	mov    %esp,%ebp
f0102ca0:	57                   	push   %edi
f0102ca1:	56                   	push   %esi
f0102ca2:	53                   	push   %ebx
f0102ca3:	83 ec 1c             	sub    $0x1c,%esp
f0102ca6:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102ca9:	8b 15 88 bf 17 f0    	mov    0xf017bf88,%edx
f0102caf:	39 fa                	cmp    %edi,%edx
f0102cb1:	75 29                	jne    f0102cdc <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102cb3:	a1 48 cc 17 f0       	mov    0xf017cc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cb8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102cbd:	77 15                	ja     f0102cd4 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cbf:	50                   	push   %eax
f0102cc0:	68 80 50 10 f0       	push   $0xf0105080
f0102cc5:	68 ad 01 00 00       	push   $0x1ad
f0102cca:	68 e6 57 10 f0       	push   $0xf01057e6
f0102ccf:	e8 cc d3 ff ff       	call   f01000a0 <_panic>
f0102cd4:	05 00 00 00 10       	add    $0x10000000,%eax
f0102cd9:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102cdc:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102cdf:	85 d2                	test   %edx,%edx
f0102ce1:	74 05                	je     f0102ce8 <env_free+0x4b>
f0102ce3:	8b 42 48             	mov    0x48(%edx),%eax
f0102ce6:	eb 05                	jmp    f0102ced <env_free+0x50>
f0102ce8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ced:	83 ec 04             	sub    $0x4,%esp
f0102cf0:	51                   	push   %ecx
f0102cf1:	50                   	push   %eax
f0102cf2:	68 19 58 10 f0       	push   $0xf0105819
f0102cf7:	e8 76 02 00 00       	call   f0102f72 <cprintf>
f0102cfc:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102cff:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102d06:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102d09:	89 d0                	mov    %edx,%eax
f0102d0b:	c1 e0 02             	shl    $0x2,%eax
f0102d0e:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102d11:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d14:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102d17:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102d1d:	0f 84 a8 00 00 00    	je     f0102dcb <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102d23:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d29:	89 f0                	mov    %esi,%eax
f0102d2b:	c1 e8 0c             	shr    $0xc,%eax
f0102d2e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d31:	39 05 44 cc 17 f0    	cmp    %eax,0xf017cc44
f0102d37:	77 15                	ja     f0102d4e <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d39:	56                   	push   %esi
f0102d3a:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0102d3f:	68 bc 01 00 00       	push   $0x1bc
f0102d44:	68 e6 57 10 f0       	push   $0xf01057e6
f0102d49:	e8 52 d3 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d51:	c1 e0 16             	shl    $0x16,%eax
f0102d54:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d57:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102d5c:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102d63:	01 
f0102d64:	74 17                	je     f0102d7d <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d66:	83 ec 08             	sub    $0x8,%esp
f0102d69:	89 d8                	mov    %ebx,%eax
f0102d6b:	c1 e0 0c             	shl    $0xc,%eax
f0102d6e:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102d71:	50                   	push   %eax
f0102d72:	ff 77 5c             	pushl  0x5c(%edi)
f0102d75:	e8 14 e2 ff ff       	call   f0100f8e <page_remove>
f0102d7a:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d7d:	83 c3 01             	add    $0x1,%ebx
f0102d80:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102d86:	75 d4                	jne    f0102d5c <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102d88:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d8b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d8e:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d95:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d98:	3b 05 44 cc 17 f0    	cmp    0xf017cc44,%eax
f0102d9e:	72 14                	jb     f0102db4 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102da0:	83 ec 04             	sub    $0x4,%esp
f0102da3:	68 24 50 10 f0       	push   $0xf0105024
f0102da8:	6a 4f                	push   $0x4f
f0102daa:	68 40 4c 10 f0       	push   $0xf0104c40
f0102daf:	e8 ec d2 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102db4:	83 ec 0c             	sub    $0xc,%esp
f0102db7:	a1 4c cc 17 f0       	mov    0xf017cc4c,%eax
f0102dbc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102dbf:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102dc2:	50                   	push   %eax
f0102dc3:	e8 53 e0 ff ff       	call   f0100e1b <page_decref>
f0102dc8:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102dcb:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102dcf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102dd2:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102dd7:	0f 85 29 ff ff ff    	jne    f0102d06 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102ddd:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102de0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102de5:	77 15                	ja     f0102dfc <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102de7:	50                   	push   %eax
f0102de8:	68 80 50 10 f0       	push   $0xf0105080
f0102ded:	68 ca 01 00 00       	push   $0x1ca
f0102df2:	68 e6 57 10 f0       	push   $0xf01057e6
f0102df7:	e8 a4 d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102dfc:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e03:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e08:	c1 e8 0c             	shr    $0xc,%eax
f0102e0b:	3b 05 44 cc 17 f0    	cmp    0xf017cc44,%eax
f0102e11:	72 14                	jb     f0102e27 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102e13:	83 ec 04             	sub    $0x4,%esp
f0102e16:	68 24 50 10 f0       	push   $0xf0105024
f0102e1b:	6a 4f                	push   $0x4f
f0102e1d:	68 40 4c 10 f0       	push   $0xf0104c40
f0102e22:	e8 79 d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102e27:	83 ec 0c             	sub    $0xc,%esp
f0102e2a:	8b 15 4c cc 17 f0    	mov    0xf017cc4c,%edx
f0102e30:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102e33:	50                   	push   %eax
f0102e34:	e8 e2 df ff ff       	call   f0100e1b <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102e39:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102e40:	a1 90 bf 17 f0       	mov    0xf017bf90,%eax
f0102e45:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102e48:	89 3d 90 bf 17 f0    	mov    %edi,0xf017bf90
}
f0102e4e:	83 c4 10             	add    $0x10,%esp
f0102e51:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e54:	5b                   	pop    %ebx
f0102e55:	5e                   	pop    %esi
f0102e56:	5f                   	pop    %edi
f0102e57:	5d                   	pop    %ebp
f0102e58:	c3                   	ret    

f0102e59 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102e59:	55                   	push   %ebp
f0102e5a:	89 e5                	mov    %esp,%ebp
f0102e5c:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102e5f:	ff 75 08             	pushl  0x8(%ebp)
f0102e62:	e8 36 fe ff ff       	call   f0102c9d <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102e67:	c7 04 24 b0 57 10 f0 	movl   $0xf01057b0,(%esp)
f0102e6e:	e8 ff 00 00 00       	call   f0102f72 <cprintf>
f0102e73:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102e76:	83 ec 0c             	sub    $0xc,%esp
f0102e79:	6a 00                	push   $0x0
f0102e7b:	e8 5c d9 ff ff       	call   f01007dc <monitor>
f0102e80:	83 c4 10             	add    $0x10,%esp
f0102e83:	eb f1                	jmp    f0102e76 <env_destroy+0x1d>

f0102e85 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102e85:	55                   	push   %ebp
f0102e86:	89 e5                	mov    %esp,%ebp
f0102e88:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102e8b:	8b 65 08             	mov    0x8(%ebp),%esp
f0102e8e:	61                   	popa   
f0102e8f:	07                   	pop    %es
f0102e90:	1f                   	pop    %ds
f0102e91:	83 c4 08             	add    $0x8,%esp
f0102e94:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102e95:	68 2f 58 10 f0       	push   $0xf010582f
f0102e9a:	68 f2 01 00 00       	push   $0x1f2
f0102e9f:	68 e6 57 10 f0       	push   $0xf01057e6
f0102ea4:	e8 f7 d1 ff ff       	call   f01000a0 <_panic>

f0102ea9 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102ea9:	55                   	push   %ebp
f0102eaa:	89 e5                	mov    %esp,%ebp
f0102eac:	83 ec 08             	sub    $0x8,%esp
f0102eaf:	8b 45 08             	mov    0x8(%ebp),%eax
	//	   4. Update its 'env_runs' counter,
	//	   5. Use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.
	if(curenv != NULL && curenv->env_status == ENV_RUNNING) {
f0102eb2:	8b 15 88 bf 17 f0    	mov    0xf017bf88,%edx
f0102eb8:	85 d2                	test   %edx,%edx
f0102eba:	74 0d                	je     f0102ec9 <env_run+0x20>
f0102ebc:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102ec0:	75 07                	jne    f0102ec9 <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f0102ec2:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}

	curenv = e;
f0102ec9:	a3 88 bf 17 f0       	mov    %eax,0xf017bf88
	curenv->env_status = ENV_RUNNING;
f0102ece:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0102ed5:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f0102ed9:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102edc:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102ee2:	77 15                	ja     f0102ef9 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ee4:	52                   	push   %edx
f0102ee5:	68 80 50 10 f0       	push   $0xf0105080
f0102eea:	68 10 02 00 00       	push   $0x210
f0102eef:	68 e6 57 10 f0       	push   $0xf01057e6
f0102ef4:	e8 a7 d1 ff ff       	call   f01000a0 <_panic>
f0102ef9:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102eff:	0f 22 da             	mov    %edx,%cr3
	// Hint: This function loads the new environment's state from
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	env_pop_tf(&curenv->env_tf);
f0102f02:	83 ec 0c             	sub    $0xc,%esp
f0102f05:	50                   	push   %eax
f0102f06:	e8 7a ff ff ff       	call   f0102e85 <env_pop_tf>

f0102f0b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f0b:	55                   	push   %ebp
f0102f0c:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f0e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f13:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f16:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f17:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f1c:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f1d:	0f b6 c0             	movzbl %al,%eax
}
f0102f20:	5d                   	pop    %ebp
f0102f21:	c3                   	ret    

f0102f22 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f22:	55                   	push   %ebp
f0102f23:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f25:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f2d:	ee                   	out    %al,(%dx)
f0102f2e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f33:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f36:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f37:	5d                   	pop    %ebp
f0102f38:	c3                   	ret    

f0102f39 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f39:	55                   	push   %ebp
f0102f3a:	89 e5                	mov    %esp,%ebp
f0102f3c:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102f3f:	ff 75 08             	pushl  0x8(%ebp)
f0102f42:	e8 c0 d6 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102f47:	83 c4 10             	add    $0x10,%esp
f0102f4a:	c9                   	leave  
f0102f4b:	c3                   	ret    

f0102f4c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f4c:	55                   	push   %ebp
f0102f4d:	89 e5                	mov    %esp,%ebp
f0102f4f:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102f52:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f59:	ff 75 0c             	pushl  0xc(%ebp)
f0102f5c:	ff 75 08             	pushl  0x8(%ebp)
f0102f5f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f62:	50                   	push   %eax
f0102f63:	68 39 2f 10 f0       	push   $0xf0102f39
f0102f68:	e8 81 0c 00 00       	call   f0103bee <vprintfmt>
	return cnt;
}
f0102f6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f70:	c9                   	leave  
f0102f71:	c3                   	ret    

f0102f72 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f72:	55                   	push   %ebp
f0102f73:	89 e5                	mov    %esp,%ebp
f0102f75:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f78:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f7b:	50                   	push   %eax
f0102f7c:	ff 75 08             	pushl  0x8(%ebp)
f0102f7f:	e8 c8 ff ff ff       	call   f0102f4c <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f84:	c9                   	leave  
f0102f85:	c3                   	ret    

f0102f86 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102f86:	55                   	push   %ebp
f0102f87:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102f89:	b8 c0 c7 17 f0       	mov    $0xf017c7c0,%eax
f0102f8e:	c7 05 c4 c7 17 f0 00 	movl   $0xf0000000,0xf017c7c4
f0102f95:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102f98:	66 c7 05 c8 c7 17 f0 	movw   $0x10,0xf017c7c8
f0102f9f:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102fa1:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102fa8:	67 00 
f0102faa:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102fb0:	89 c2                	mov    %eax,%edx
f0102fb2:	c1 ea 10             	shr    $0x10,%edx
f0102fb5:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102fbb:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102fc2:	c1 e8 18             	shr    $0x18,%eax
f0102fc5:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102fca:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0102fd1:	b8 28 00 00 00       	mov    $0x28,%eax
f0102fd6:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0102fd9:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102fde:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102fe1:	5d                   	pop    %ebp
f0102fe2:	c3                   	ret    

f0102fe3 <trap_init>:
}


void
trap_init(void)
{
f0102fe3:	55                   	push   %ebp
f0102fe4:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0102fe6:	b8 c0 36 10 f0       	mov    $0xf01036c0,%eax
f0102feb:	66 a3 a0 bf 17 f0    	mov    %ax,0xf017bfa0
f0102ff1:	66 c7 05 a2 bf 17 f0 	movw   $0x8,0xf017bfa2
f0102ff8:	08 00 
f0102ffa:	c6 05 a4 bf 17 f0 00 	movb   $0x0,0xf017bfa4
f0103001:	c6 05 a5 bf 17 f0 8e 	movb   $0x8e,0xf017bfa5
f0103008:	c1 e8 10             	shr    $0x10,%eax
f010300b:	66 a3 a6 bf 17 f0    	mov    %ax,0xf017bfa6
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0103011:	b8 c6 36 10 f0       	mov    $0xf01036c6,%eax
f0103016:	66 a3 a8 bf 17 f0    	mov    %ax,0xf017bfa8
f010301c:	66 c7 05 aa bf 17 f0 	movw   $0x8,0xf017bfaa
f0103023:	08 00 
f0103025:	c6 05 ac bf 17 f0 00 	movb   $0x0,0xf017bfac
f010302c:	c6 05 ad bf 17 f0 8e 	movb   $0x8e,0xf017bfad
f0103033:	c1 e8 10             	shr    $0x10,%eax
f0103036:	66 a3 ae bf 17 f0    	mov    %ax,0xf017bfae
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f010303c:	b8 cc 36 10 f0       	mov    $0xf01036cc,%eax
f0103041:	66 a3 b0 bf 17 f0    	mov    %ax,0xf017bfb0
f0103047:	66 c7 05 b2 bf 17 f0 	movw   $0x8,0xf017bfb2
f010304e:	08 00 
f0103050:	c6 05 b4 bf 17 f0 00 	movb   $0x0,0xf017bfb4
f0103057:	c6 05 b5 bf 17 f0 8e 	movb   $0x8e,0xf017bfb5
f010305e:	c1 e8 10             	shr    $0x10,%eax
f0103061:	66 a3 b6 bf 17 f0    	mov    %ax,0xf017bfb6
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f0103067:	b8 d2 36 10 f0       	mov    $0xf01036d2,%eax
f010306c:	66 a3 b8 bf 17 f0    	mov    %ax,0xf017bfb8
f0103072:	66 c7 05 ba bf 17 f0 	movw   $0x8,0xf017bfba
f0103079:	08 00 
f010307b:	c6 05 bc bf 17 f0 00 	movb   $0x0,0xf017bfbc
f0103082:	c6 05 bd bf 17 f0 ee 	movb   $0xee,0xf017bfbd
f0103089:	c1 e8 10             	shr    $0x10,%eax
f010308c:	66 a3 be bf 17 f0    	mov    %ax,0xf017bfbe
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f0103092:	b8 d8 36 10 f0       	mov    $0xf01036d8,%eax
f0103097:	66 a3 c0 bf 17 f0    	mov    %ax,0xf017bfc0
f010309d:	66 c7 05 c2 bf 17 f0 	movw   $0x8,0xf017bfc2
f01030a4:	08 00 
f01030a6:	c6 05 c4 bf 17 f0 00 	movb   $0x0,0xf017bfc4
f01030ad:	c6 05 c5 bf 17 f0 8e 	movb   $0x8e,0xf017bfc5
f01030b4:	c1 e8 10             	shr    $0x10,%eax
f01030b7:	66 a3 c6 bf 17 f0    	mov    %ax,0xf017bfc6
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f01030bd:	b8 de 36 10 f0       	mov    $0xf01036de,%eax
f01030c2:	66 a3 c8 bf 17 f0    	mov    %ax,0xf017bfc8
f01030c8:	66 c7 05 ca bf 17 f0 	movw   $0x8,0xf017bfca
f01030cf:	08 00 
f01030d1:	c6 05 cc bf 17 f0 00 	movb   $0x0,0xf017bfcc
f01030d8:	c6 05 cd bf 17 f0 8e 	movb   $0x8e,0xf017bfcd
f01030df:	c1 e8 10             	shr    $0x10,%eax
f01030e2:	66 a3 ce bf 17 f0    	mov    %ax,0xf017bfce
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f01030e8:	b8 e4 36 10 f0       	mov    $0xf01036e4,%eax
f01030ed:	66 a3 d0 bf 17 f0    	mov    %ax,0xf017bfd0
f01030f3:	66 c7 05 d2 bf 17 f0 	movw   $0x8,0xf017bfd2
f01030fa:	08 00 
f01030fc:	c6 05 d4 bf 17 f0 00 	movb   $0x0,0xf017bfd4
f0103103:	c6 05 d5 bf 17 f0 8e 	movb   $0x8e,0xf017bfd5
f010310a:	c1 e8 10             	shr    $0x10,%eax
f010310d:	66 a3 d6 bf 17 f0    	mov    %ax,0xf017bfd6
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f0103113:	b8 ea 36 10 f0       	mov    $0xf01036ea,%eax
f0103118:	66 a3 d8 bf 17 f0    	mov    %ax,0xf017bfd8
f010311e:	66 c7 05 da bf 17 f0 	movw   $0x8,0xf017bfda
f0103125:	08 00 
f0103127:	c6 05 dc bf 17 f0 00 	movb   $0x0,0xf017bfdc
f010312e:	c6 05 dd bf 17 f0 8e 	movb   $0x8e,0xf017bfdd
f0103135:	c1 e8 10             	shr    $0x10,%eax
f0103138:	66 a3 de bf 17 f0    	mov    %ax,0xf017bfde
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f010313e:	b8 f0 36 10 f0       	mov    $0xf01036f0,%eax
f0103143:	66 a3 e0 bf 17 f0    	mov    %ax,0xf017bfe0
f0103149:	66 c7 05 e2 bf 17 f0 	movw   $0x8,0xf017bfe2
f0103150:	08 00 
f0103152:	c6 05 e4 bf 17 f0 00 	movb   $0x0,0xf017bfe4
f0103159:	c6 05 e5 bf 17 f0 8e 	movb   $0x8e,0xf017bfe5
f0103160:	c1 e8 10             	shr    $0x10,%eax
f0103163:	66 a3 e6 bf 17 f0    	mov    %ax,0xf017bfe6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f0103169:	b8 f4 36 10 f0       	mov    $0xf01036f4,%eax
f010316e:	66 a3 f0 bf 17 f0    	mov    %ax,0xf017bff0
f0103174:	66 c7 05 f2 bf 17 f0 	movw   $0x8,0xf017bff2
f010317b:	08 00 
f010317d:	c6 05 f4 bf 17 f0 00 	movb   $0x0,0xf017bff4
f0103184:	c6 05 f5 bf 17 f0 8e 	movb   $0x8e,0xf017bff5
f010318b:	c1 e8 10             	shr    $0x10,%eax
f010318e:	66 a3 f6 bf 17 f0    	mov    %ax,0xf017bff6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f0103194:	b8 f8 36 10 f0       	mov    $0xf01036f8,%eax
f0103199:	66 a3 f8 bf 17 f0    	mov    %ax,0xf017bff8
f010319f:	66 c7 05 fa bf 17 f0 	movw   $0x8,0xf017bffa
f01031a6:	08 00 
f01031a8:	c6 05 fc bf 17 f0 00 	movb   $0x0,0xf017bffc
f01031af:	c6 05 fd bf 17 f0 8e 	movb   $0x8e,0xf017bffd
f01031b6:	c1 e8 10             	shr    $0x10,%eax
f01031b9:	66 a3 fe bf 17 f0    	mov    %ax,0xf017bffe
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f01031bf:	b8 fc 36 10 f0       	mov    $0xf01036fc,%eax
f01031c4:	66 a3 00 c0 17 f0    	mov    %ax,0xf017c000
f01031ca:	66 c7 05 02 c0 17 f0 	movw   $0x8,0xf017c002
f01031d1:	08 00 
f01031d3:	c6 05 04 c0 17 f0 00 	movb   $0x0,0xf017c004
f01031da:	c6 05 05 c0 17 f0 8e 	movb   $0x8e,0xf017c005
f01031e1:	c1 e8 10             	shr    $0x10,%eax
f01031e4:	66 a3 06 c0 17 f0    	mov    %ax,0xf017c006
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f01031ea:	b8 00 37 10 f0       	mov    $0xf0103700,%eax
f01031ef:	66 a3 08 c0 17 f0    	mov    %ax,0xf017c008
f01031f5:	66 c7 05 0a c0 17 f0 	movw   $0x8,0xf017c00a
f01031fc:	08 00 
f01031fe:	c6 05 0c c0 17 f0 00 	movb   $0x0,0xf017c00c
f0103205:	c6 05 0d c0 17 f0 8e 	movb   $0x8e,0xf017c00d
f010320c:	c1 e8 10             	shr    $0x10,%eax
f010320f:	66 a3 0e c0 17 f0    	mov    %ax,0xf017c00e
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103215:	b8 04 37 10 f0       	mov    $0xf0103704,%eax
f010321a:	66 a3 10 c0 17 f0    	mov    %ax,0xf017c010
f0103220:	66 c7 05 12 c0 17 f0 	movw   $0x8,0xf017c012
f0103227:	08 00 
f0103229:	c6 05 14 c0 17 f0 00 	movb   $0x0,0xf017c014
f0103230:	c6 05 15 c0 17 f0 8e 	movb   $0x8e,0xf017c015
f0103237:	c1 e8 10             	shr    $0x10,%eax
f010323a:	66 a3 16 c0 17 f0    	mov    %ax,0xf017c016
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f0103240:	b8 08 37 10 f0       	mov    $0xf0103708,%eax
f0103245:	66 a3 20 c0 17 f0    	mov    %ax,0xf017c020
f010324b:	66 c7 05 22 c0 17 f0 	movw   $0x8,0xf017c022
f0103252:	08 00 
f0103254:	c6 05 24 c0 17 f0 00 	movb   $0x0,0xf017c024
f010325b:	c6 05 25 c0 17 f0 8e 	movb   $0x8e,0xf017c025
f0103262:	c1 e8 10             	shr    $0x10,%eax
f0103265:	66 a3 26 c0 17 f0    	mov    %ax,0xf017c026
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f010326b:	b8 0e 37 10 f0       	mov    $0xf010370e,%eax
f0103270:	66 a3 28 c0 17 f0    	mov    %ax,0xf017c028
f0103276:	66 c7 05 2a c0 17 f0 	movw   $0x8,0xf017c02a
f010327d:	08 00 
f010327f:	c6 05 2c c0 17 f0 00 	movb   $0x0,0xf017c02c
f0103286:	c6 05 2d c0 17 f0 8e 	movb   $0x8e,0xf017c02d
f010328d:	c1 e8 10             	shr    $0x10,%eax
f0103290:	66 a3 2e c0 17 f0    	mov    %ax,0xf017c02e
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f0103296:	b8 12 37 10 f0       	mov    $0xf0103712,%eax
f010329b:	66 a3 30 c0 17 f0    	mov    %ax,0xf017c030
f01032a1:	66 c7 05 32 c0 17 f0 	movw   $0x8,0xf017c032
f01032a8:	08 00 
f01032aa:	c6 05 34 c0 17 f0 00 	movb   $0x0,0xf017c034
f01032b1:	c6 05 35 c0 17 f0 8e 	movb   $0x8e,0xf017c035
f01032b8:	c1 e8 10             	shr    $0x10,%eax
f01032bb:	66 a3 36 c0 17 f0    	mov    %ax,0xf017c036
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f01032c1:	b8 18 37 10 f0       	mov    $0xf0103718,%eax
f01032c6:	66 a3 38 c0 17 f0    	mov    %ax,0xf017c038
f01032cc:	66 c7 05 3a c0 17 f0 	movw   $0x8,0xf017c03a
f01032d3:	08 00 
f01032d5:	c6 05 3c c0 17 f0 00 	movb   $0x0,0xf017c03c
f01032dc:	c6 05 3d c0 17 f0 8e 	movb   $0x8e,0xf017c03d
f01032e3:	c1 e8 10             	shr    $0x10,%eax
f01032e6:	66 a3 3e c0 17 f0    	mov    %ax,0xf017c03e
	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f01032ec:	b8 1e 37 10 f0       	mov    $0xf010371e,%eax
f01032f1:	66 a3 20 c1 17 f0    	mov    %ax,0xf017c120
f01032f7:	66 c7 05 22 c1 17 f0 	movw   $0x8,0xf017c122
f01032fe:	08 00 
f0103300:	c6 05 24 c1 17 f0 00 	movb   $0x0,0xf017c124
f0103307:	c6 05 25 c1 17 f0 ee 	movb   $0xee,0xf017c125
f010330e:	c1 e8 10             	shr    $0x10,%eax
f0103311:	66 a3 26 c1 17 f0    	mov    %ax,0xf017c126
	// Per-CPU setup 
	trap_init_percpu();
f0103317:	e8 6a fc ff ff       	call   f0102f86 <trap_init_percpu>
}
f010331c:	5d                   	pop    %ebp
f010331d:	c3                   	ret    

f010331e <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010331e:	55                   	push   %ebp
f010331f:	89 e5                	mov    %esp,%ebp
f0103321:	53                   	push   %ebx
f0103322:	83 ec 0c             	sub    $0xc,%esp
f0103325:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103328:	ff 33                	pushl  (%ebx)
f010332a:	68 3b 58 10 f0       	push   $0xf010583b
f010332f:	e8 3e fc ff ff       	call   f0102f72 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103334:	83 c4 08             	add    $0x8,%esp
f0103337:	ff 73 04             	pushl  0x4(%ebx)
f010333a:	68 4a 58 10 f0       	push   $0xf010584a
f010333f:	e8 2e fc ff ff       	call   f0102f72 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103344:	83 c4 08             	add    $0x8,%esp
f0103347:	ff 73 08             	pushl  0x8(%ebx)
f010334a:	68 59 58 10 f0       	push   $0xf0105859
f010334f:	e8 1e fc ff ff       	call   f0102f72 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103354:	83 c4 08             	add    $0x8,%esp
f0103357:	ff 73 0c             	pushl  0xc(%ebx)
f010335a:	68 68 58 10 f0       	push   $0xf0105868
f010335f:	e8 0e fc ff ff       	call   f0102f72 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103364:	83 c4 08             	add    $0x8,%esp
f0103367:	ff 73 10             	pushl  0x10(%ebx)
f010336a:	68 77 58 10 f0       	push   $0xf0105877
f010336f:	e8 fe fb ff ff       	call   f0102f72 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103374:	83 c4 08             	add    $0x8,%esp
f0103377:	ff 73 14             	pushl  0x14(%ebx)
f010337a:	68 86 58 10 f0       	push   $0xf0105886
f010337f:	e8 ee fb ff ff       	call   f0102f72 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103384:	83 c4 08             	add    $0x8,%esp
f0103387:	ff 73 18             	pushl  0x18(%ebx)
f010338a:	68 95 58 10 f0       	push   $0xf0105895
f010338f:	e8 de fb ff ff       	call   f0102f72 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103394:	83 c4 08             	add    $0x8,%esp
f0103397:	ff 73 1c             	pushl  0x1c(%ebx)
f010339a:	68 a4 58 10 f0       	push   $0xf01058a4
f010339f:	e8 ce fb ff ff       	call   f0102f72 <cprintf>
}
f01033a4:	83 c4 10             	add    $0x10,%esp
f01033a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033aa:	c9                   	leave  
f01033ab:	c3                   	ret    

f01033ac <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01033ac:	55                   	push   %ebp
f01033ad:	89 e5                	mov    %esp,%ebp
f01033af:	56                   	push   %esi
f01033b0:	53                   	push   %ebx
f01033b1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f01033b4:	83 ec 08             	sub    $0x8,%esp
f01033b7:	53                   	push   %ebx
f01033b8:	68 da 59 10 f0       	push   $0xf01059da
f01033bd:	e8 b0 fb ff ff       	call   f0102f72 <cprintf>
	print_regs(&tf->tf_regs);
f01033c2:	89 1c 24             	mov    %ebx,(%esp)
f01033c5:	e8 54 ff ff ff       	call   f010331e <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01033ca:	83 c4 08             	add    $0x8,%esp
f01033cd:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01033d1:	50                   	push   %eax
f01033d2:	68 f5 58 10 f0       	push   $0xf01058f5
f01033d7:	e8 96 fb ff ff       	call   f0102f72 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01033dc:	83 c4 08             	add    $0x8,%esp
f01033df:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01033e3:	50                   	push   %eax
f01033e4:	68 08 59 10 f0       	push   $0xf0105908
f01033e9:	e8 84 fb ff ff       	call   f0102f72 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01033ee:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01033f1:	83 c4 10             	add    $0x10,%esp
f01033f4:	83 f8 13             	cmp    $0x13,%eax
f01033f7:	77 09                	ja     f0103402 <print_trapframe+0x56>
		return excnames[trapno];
f01033f9:	8b 14 85 a0 5b 10 f0 	mov    -0xfefa460(,%eax,4),%edx
f0103400:	eb 10                	jmp    f0103412 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103402:	83 f8 30             	cmp    $0x30,%eax
f0103405:	b9 bf 58 10 f0       	mov    $0xf01058bf,%ecx
f010340a:	ba b3 58 10 f0       	mov    $0xf01058b3,%edx
f010340f:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103412:	83 ec 04             	sub    $0x4,%esp
f0103415:	52                   	push   %edx
f0103416:	50                   	push   %eax
f0103417:	68 1b 59 10 f0       	push   $0xf010591b
f010341c:	e8 51 fb ff ff       	call   f0102f72 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103421:	83 c4 10             	add    $0x10,%esp
f0103424:	3b 1d a0 c7 17 f0    	cmp    0xf017c7a0,%ebx
f010342a:	75 1a                	jne    f0103446 <print_trapframe+0x9a>
f010342c:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103430:	75 14                	jne    f0103446 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103432:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103435:	83 ec 08             	sub    $0x8,%esp
f0103438:	50                   	push   %eax
f0103439:	68 2d 59 10 f0       	push   $0xf010592d
f010343e:	e8 2f fb ff ff       	call   f0102f72 <cprintf>
f0103443:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103446:	83 ec 08             	sub    $0x8,%esp
f0103449:	ff 73 2c             	pushl  0x2c(%ebx)
f010344c:	68 3c 59 10 f0       	push   $0xf010593c
f0103451:	e8 1c fb ff ff       	call   f0102f72 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103456:	83 c4 10             	add    $0x10,%esp
f0103459:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010345d:	75 49                	jne    f01034a8 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010345f:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103462:	89 c2                	mov    %eax,%edx
f0103464:	83 e2 01             	and    $0x1,%edx
f0103467:	ba d9 58 10 f0       	mov    $0xf01058d9,%edx
f010346c:	b9 ce 58 10 f0       	mov    $0xf01058ce,%ecx
f0103471:	0f 44 ca             	cmove  %edx,%ecx
f0103474:	89 c2                	mov    %eax,%edx
f0103476:	83 e2 02             	and    $0x2,%edx
f0103479:	ba eb 58 10 f0       	mov    $0xf01058eb,%edx
f010347e:	be e5 58 10 f0       	mov    $0xf01058e5,%esi
f0103483:	0f 45 d6             	cmovne %esi,%edx
f0103486:	83 e0 04             	and    $0x4,%eax
f0103489:	be 05 5a 10 f0       	mov    $0xf0105a05,%esi
f010348e:	b8 f0 58 10 f0       	mov    $0xf01058f0,%eax
f0103493:	0f 44 c6             	cmove  %esi,%eax
f0103496:	51                   	push   %ecx
f0103497:	52                   	push   %edx
f0103498:	50                   	push   %eax
f0103499:	68 4a 59 10 f0       	push   $0xf010594a
f010349e:	e8 cf fa ff ff       	call   f0102f72 <cprintf>
f01034a3:	83 c4 10             	add    $0x10,%esp
f01034a6:	eb 10                	jmp    f01034b8 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01034a8:	83 ec 0c             	sub    $0xc,%esp
f01034ab:	68 09 4f 10 f0       	push   $0xf0104f09
f01034b0:	e8 bd fa ff ff       	call   f0102f72 <cprintf>
f01034b5:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01034b8:	83 ec 08             	sub    $0x8,%esp
f01034bb:	ff 73 30             	pushl  0x30(%ebx)
f01034be:	68 59 59 10 f0       	push   $0xf0105959
f01034c3:	e8 aa fa ff ff       	call   f0102f72 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01034c8:	83 c4 08             	add    $0x8,%esp
f01034cb:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01034cf:	50                   	push   %eax
f01034d0:	68 68 59 10 f0       	push   $0xf0105968
f01034d5:	e8 98 fa ff ff       	call   f0102f72 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01034da:	83 c4 08             	add    $0x8,%esp
f01034dd:	ff 73 38             	pushl  0x38(%ebx)
f01034e0:	68 7b 59 10 f0       	push   $0xf010597b
f01034e5:	e8 88 fa ff ff       	call   f0102f72 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01034ea:	83 c4 10             	add    $0x10,%esp
f01034ed:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01034f1:	74 25                	je     f0103518 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01034f3:	83 ec 08             	sub    $0x8,%esp
f01034f6:	ff 73 3c             	pushl  0x3c(%ebx)
f01034f9:	68 8a 59 10 f0       	push   $0xf010598a
f01034fe:	e8 6f fa ff ff       	call   f0102f72 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103503:	83 c4 08             	add    $0x8,%esp
f0103506:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010350a:	50                   	push   %eax
f010350b:	68 99 59 10 f0       	push   $0xf0105999
f0103510:	e8 5d fa ff ff       	call   f0102f72 <cprintf>
f0103515:	83 c4 10             	add    $0x10,%esp
	}
}
f0103518:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010351b:	5b                   	pop    %ebx
f010351c:	5e                   	pop    %esi
f010351d:	5d                   	pop    %ebp
f010351e:	c3                   	ret    

f010351f <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010351f:	55                   	push   %ebp
f0103520:	89 e5                	mov    %esp,%ebp
f0103522:	53                   	push   %ebx
f0103523:	83 ec 04             	sub    $0x4,%esp
f0103526:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103529:	0f 20 d0             	mov    %cr2,%eax
	
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010352c:	ff 73 30             	pushl  0x30(%ebx)
f010352f:	50                   	push   %eax
f0103530:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f0103535:	ff 70 48             	pushl  0x48(%eax)
f0103538:	68 50 5b 10 f0       	push   $0xf0105b50
f010353d:	e8 30 fa ff ff       	call   f0102f72 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103542:	89 1c 24             	mov    %ebx,(%esp)
f0103545:	e8 62 fe ff ff       	call   f01033ac <print_trapframe>
	env_destroy(curenv);
f010354a:	83 c4 04             	add    $0x4,%esp
f010354d:	ff 35 88 bf 17 f0    	pushl  0xf017bf88
f0103553:	e8 01 f9 ff ff       	call   f0102e59 <env_destroy>
}
f0103558:	83 c4 10             	add    $0x10,%esp
f010355b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010355e:	c9                   	leave  
f010355f:	c3                   	ret    

f0103560 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103560:	55                   	push   %ebp
f0103561:	89 e5                	mov    %esp,%ebp
f0103563:	57                   	push   %edi
f0103564:	56                   	push   %esi
f0103565:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103568:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103569:	9c                   	pushf  
f010356a:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010356b:	f6 c4 02             	test   $0x2,%ah
f010356e:	74 19                	je     f0103589 <trap+0x29>
f0103570:	68 ac 59 10 f0       	push   $0xf01059ac
f0103575:	68 5a 4c 10 f0       	push   $0xf0104c5a
f010357a:	68 e5 00 00 00       	push   $0xe5
f010357f:	68 c5 59 10 f0       	push   $0xf01059c5
f0103584:	e8 17 cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103589:	83 ec 08             	sub    $0x8,%esp
f010358c:	56                   	push   %esi
f010358d:	68 d1 59 10 f0       	push   $0xf01059d1
f0103592:	e8 db f9 ff ff       	call   f0102f72 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103597:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010359b:	83 e0 03             	and    $0x3,%eax
f010359e:	83 c4 10             	add    $0x10,%esp
f01035a1:	66 83 f8 03          	cmp    $0x3,%ax
f01035a5:	75 31                	jne    f01035d8 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f01035a7:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f01035ac:	85 c0                	test   %eax,%eax
f01035ae:	75 19                	jne    f01035c9 <trap+0x69>
f01035b0:	68 ec 59 10 f0       	push   $0xf01059ec
f01035b5:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01035ba:	68 eb 00 00 00       	push   $0xeb
f01035bf:	68 c5 59 10 f0       	push   $0xf01059c5
f01035c4:	e8 d7 ca ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01035c9:	b9 11 00 00 00       	mov    $0x11,%ecx
f01035ce:	89 c7                	mov    %eax,%edi
f01035d0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01035d2:	8b 35 88 bf 17 f0    	mov    0xf017bf88,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01035d8:	89 35 a0 c7 17 f0    	mov    %esi,0xf017c7a0
trap_dispatch(struct Trapframe *tf)
{
	int32_t ret_code;
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno) {
f01035de:	8b 46 28             	mov    0x28(%esi),%eax
f01035e1:	83 f8 03             	cmp    $0x3,%eax
f01035e4:	74 29                	je     f010360f <trap+0xaf>
f01035e6:	83 f8 03             	cmp    $0x3,%eax
f01035e9:	77 07                	ja     f01035f2 <trap+0x92>
f01035eb:	83 f8 01             	cmp    $0x1,%eax
f01035ee:	74 35                	je     f0103625 <trap+0xc5>
f01035f0:	eb 62                	jmp    f0103654 <trap+0xf4>
f01035f2:	83 f8 0e             	cmp    $0xe,%eax
f01035f5:	74 07                	je     f01035fe <trap+0x9e>
f01035f7:	83 f8 30             	cmp    $0x30,%eax
f01035fa:	74 37                	je     f0103633 <trap+0xd3>
f01035fc:	eb 56                	jmp    f0103654 <trap+0xf4>
		case (T_PGFLT):
			page_fault_handler(tf);
f01035fe:	83 ec 0c             	sub    $0xc,%esp
f0103601:	56                   	push   %esi
f0103602:	e8 18 ff ff ff       	call   f010351f <page_fault_handler>
f0103607:	83 c4 10             	add    $0x10,%esp
f010360a:	e9 80 00 00 00       	jmp    f010368f <trap+0x12f>
			break; 
		case (T_BRKPT):
			print_trapframe(tf);
f010360f:	83 ec 0c             	sub    $0xc,%esp
f0103612:	56                   	push   %esi
f0103613:	e8 94 fd ff ff       	call   f01033ac <print_trapframe>
			monitor(tf);		
f0103618:	89 34 24             	mov    %esi,(%esp)
f010361b:	e8 bc d1 ff ff       	call   f01007dc <monitor>
f0103620:	83 c4 10             	add    $0x10,%esp
f0103623:	eb 6a                	jmp    f010368f <trap+0x12f>
			break;
		case (T_DEBUG):
			monitor(tf);
f0103625:	83 ec 0c             	sub    $0xc,%esp
f0103628:	56                   	push   %esi
f0103629:	e8 ae d1 ff ff       	call   f01007dc <monitor>
f010362e:	83 c4 10             	add    $0x10,%esp
f0103631:	eb 5c                	jmp    f010368f <trap+0x12f>
			break;
		case (T_SYSCALL):
	//		print_trapframe(tf);
			ret_code = syscall(
f0103633:	83 ec 08             	sub    $0x8,%esp
f0103636:	ff 76 04             	pushl  0x4(%esi)
f0103639:	ff 36                	pushl  (%esi)
f010363b:	ff 76 10             	pushl  0x10(%esi)
f010363e:	ff 76 18             	pushl  0x18(%esi)
f0103641:	ff 76 14             	pushl  0x14(%esi)
f0103644:	ff 76 1c             	pushl  0x1c(%esi)
f0103647:	e8 ea 00 00 00       	call   f0103736 <syscall>
					tf->tf_regs.reg_edx,
					tf->tf_regs.reg_ecx,
					tf->tf_regs.reg_ebx,
					tf->tf_regs.reg_edi,
					tf->tf_regs.reg_esi);
			tf->tf_regs.reg_eax = ret_code;
f010364c:	89 46 1c             	mov    %eax,0x1c(%esi)
f010364f:	83 c4 20             	add    $0x20,%esp
f0103652:	eb 3b                	jmp    f010368f <trap+0x12f>
			break;
 		default:
			// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f0103654:	83 ec 0c             	sub    $0xc,%esp
f0103657:	56                   	push   %esi
f0103658:	e8 4f fd ff ff       	call   f01033ac <print_trapframe>
			if (tf->tf_cs == GD_KT)
f010365d:	83 c4 10             	add    $0x10,%esp
f0103660:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103665:	75 17                	jne    f010367e <trap+0x11e>
				panic("unhandled trap in kernel");
f0103667:	83 ec 04             	sub    $0x4,%esp
f010366a:	68 f3 59 10 f0       	push   $0xf01059f3
f010366f:	68 d3 00 00 00       	push   $0xd3
f0103674:	68 c5 59 10 f0       	push   $0xf01059c5
f0103679:	e8 22 ca ff ff       	call   f01000a0 <_panic>
			else {
				env_destroy(curenv);
f010367e:	83 ec 0c             	sub    $0xc,%esp
f0103681:	ff 35 88 bf 17 f0    	pushl  0xf017bf88
f0103687:	e8 cd f7 ff ff       	call   f0102e59 <env_destroy>
f010368c:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f010368f:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f0103694:	85 c0                	test   %eax,%eax
f0103696:	74 06                	je     f010369e <trap+0x13e>
f0103698:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010369c:	74 19                	je     f01036b7 <trap+0x157>
f010369e:	68 74 5b 10 f0       	push   $0xf0105b74
f01036a3:	68 5a 4c 10 f0       	push   $0xf0104c5a
f01036a8:	68 fd 00 00 00       	push   $0xfd
f01036ad:	68 c5 59 10 f0       	push   $0xf01059c5
f01036b2:	e8 e9 c9 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01036b7:	83 ec 0c             	sub    $0xc,%esp
f01036ba:	50                   	push   %eax
f01036bb:	e8 e9 f7 ff ff       	call   f0102ea9 <env_run>

f01036c0 <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f01036c0:	6a 00                	push   $0x0
f01036c2:	6a 00                	push   $0x0
f01036c4:	eb 5e                	jmp    f0103724 <_alltraps>

f01036c6 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f01036c6:	6a 00                	push   $0x0
f01036c8:	6a 01                	push   $0x1
f01036ca:	eb 58                	jmp    f0103724 <_alltraps>

f01036cc <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f01036cc:	6a 00                	push   $0x0
f01036ce:	6a 02                	push   $0x2
f01036d0:	eb 52                	jmp    f0103724 <_alltraps>

f01036d2 <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f01036d2:	6a 00                	push   $0x0
f01036d4:	6a 03                	push   $0x3
f01036d6:	eb 4c                	jmp    f0103724 <_alltraps>

f01036d8 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f01036d8:	6a 00                	push   $0x0
f01036da:	6a 04                	push   $0x4
f01036dc:	eb 46                	jmp    f0103724 <_alltraps>

f01036de <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f01036de:	6a 00                	push   $0x0
f01036e0:	6a 05                	push   $0x5
f01036e2:	eb 40                	jmp    f0103724 <_alltraps>

f01036e4 <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f01036e4:	6a 00                	push   $0x0
f01036e6:	6a 06                	push   $0x6
f01036e8:	eb 3a                	jmp    f0103724 <_alltraps>

f01036ea <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f01036ea:	6a 00                	push   $0x0
f01036ec:	6a 07                	push   $0x7
f01036ee:	eb 34                	jmp    f0103724 <_alltraps>

f01036f0 <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f01036f0:	6a 08                	push   $0x8
f01036f2:	eb 30                	jmp    f0103724 <_alltraps>

f01036f4 <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f01036f4:	6a 0a                	push   $0xa
f01036f6:	eb 2c                	jmp    f0103724 <_alltraps>

f01036f8 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f01036f8:	6a 0b                	push   $0xb
f01036fa:	eb 28                	jmp    f0103724 <_alltraps>

f01036fc <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f01036fc:	6a 0c                	push   $0xc
f01036fe:	eb 24                	jmp    f0103724 <_alltraps>

f0103700 <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f0103700:	6a 0d                	push   $0xd
f0103702:	eb 20                	jmp    f0103724 <_alltraps>

f0103704 <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f0103704:	6a 0e                	push   $0xe
f0103706:	eb 1c                	jmp    f0103724 <_alltraps>

f0103708 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f0103708:	6a 00                	push   $0x0
f010370a:	6a 10                	push   $0x10
f010370c:	eb 16                	jmp    f0103724 <_alltraps>

f010370e <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f010370e:	6a 11                	push   $0x11
f0103710:	eb 12                	jmp    f0103724 <_alltraps>

f0103712 <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f0103712:	6a 00                	push   $0x0
f0103714:	6a 12                	push   $0x12
f0103716:	eb 0c                	jmp    f0103724 <_alltraps>

f0103718 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f0103718:	6a 00                	push   $0x0
f010371a:	6a 13                	push   $0x13
f010371c:	eb 06                	jmp    f0103724 <_alltraps>

f010371e <t_syscall>:

TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f010371e:	6a 00                	push   $0x0
f0103720:	6a 30                	push   $0x30
f0103722:	eb 00                	jmp    f0103724 <_alltraps>

f0103724 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103724:	1e                   	push   %ds
	pushl %es
f0103725:	06                   	push   %es
	pushal 
f0103726:	60                   	pusha  

	movl $GD_KD, %eax
f0103727:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax, %ds
f010372c:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f010372e:	8e c0                	mov    %eax,%es

	push %esp
f0103730:	54                   	push   %esp
	call trap	
f0103731:	e8 2a fe ff ff       	call   f0103560 <trap>

f0103736 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103736:	55                   	push   %ebp
f0103737:	89 e5                	mov    %esp,%ebp
f0103739:	83 ec 18             	sub    $0x18,%esp
f010373c:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//	panic("syscall not implemented");

	switch (syscallno) {
f010373f:	83 f8 01             	cmp    $0x1,%eax
f0103742:	74 44                	je     f0103788 <syscall+0x52>
f0103744:	83 f8 01             	cmp    $0x1,%eax
f0103747:	72 0f                	jb     f0103758 <syscall+0x22>
f0103749:	83 f8 02             	cmp    $0x2,%eax
f010374c:	74 41                	je     f010378f <syscall+0x59>
f010374e:	83 f8 03             	cmp    $0x3,%eax
f0103751:	74 46                	je     f0103799 <syscall+0x63>
f0103753:	e9 a6 00 00 00       	jmp    f01037fe <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not:.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, 0);
f0103758:	6a 00                	push   $0x0
f010375a:	ff 75 10             	pushl  0x10(%ebp)
f010375d:	ff 75 0c             	pushl  0xc(%ebp)
f0103760:	ff 35 88 bf 17 f0    	pushl  0xf017bf88
f0103766:	e8 c9 f0 ff ff       	call   f0102834 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010376b:	83 c4 0c             	add    $0xc,%esp
f010376e:	ff 75 0c             	pushl  0xc(%ebp)
f0103771:	ff 75 10             	pushl  0x10(%ebp)
f0103774:	68 f0 5b 10 f0       	push   $0xf0105bf0
f0103779:	e8 f4 f7 ff ff       	call   f0102f72 <cprintf>
f010377e:	83 c4 10             	add    $0x10,%esp
	//	panic("syscall not implemented");

	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
f0103781:	b8 00 00 00 00       	mov    $0x0,%eax
f0103786:	eb 7b                	jmp    f0103803 <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103788:	e8 28 cd ff ff       	call   f01004b5 <cons_getc>
	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
f010378d:	eb 74                	jmp    f0103803 <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010378f:	a1 88 bf 17 f0       	mov    0xf017bf88,%eax
f0103794:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
		case (SYS_getenvid):
			return sys_getenvid();
f0103797:	eb 6a                	jmp    f0103803 <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103799:	83 ec 04             	sub    $0x4,%esp
f010379c:	6a 01                	push   $0x1
f010379e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01037a1:	50                   	push   %eax
f01037a2:	ff 75 0c             	pushl  0xc(%ebp)
f01037a5:	e8 5a f1 ff ff       	call   f0102904 <envid2env>
f01037aa:	83 c4 10             	add    $0x10,%esp
f01037ad:	85 c0                	test   %eax,%eax
f01037af:	78 52                	js     f0103803 <syscall+0xcd>
		return r;
	if (e == curenv)
f01037b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037b4:	8b 15 88 bf 17 f0    	mov    0xf017bf88,%edx
f01037ba:	39 d0                	cmp    %edx,%eax
f01037bc:	75 15                	jne    f01037d3 <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01037be:	83 ec 08             	sub    $0x8,%esp
f01037c1:	ff 70 48             	pushl  0x48(%eax)
f01037c4:	68 f5 5b 10 f0       	push   $0xf0105bf5
f01037c9:	e8 a4 f7 ff ff       	call   f0102f72 <cprintf>
f01037ce:	83 c4 10             	add    $0x10,%esp
f01037d1:	eb 16                	jmp    f01037e9 <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01037d3:	83 ec 04             	sub    $0x4,%esp
f01037d6:	ff 70 48             	pushl  0x48(%eax)
f01037d9:	ff 72 48             	pushl  0x48(%edx)
f01037dc:	68 10 5c 10 f0       	push   $0xf0105c10
f01037e1:	e8 8c f7 ff ff       	call   f0102f72 <cprintf>
f01037e6:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01037e9:	83 ec 0c             	sub    $0xc,%esp
f01037ec:	ff 75 f4             	pushl  -0xc(%ebp)
f01037ef:	e8 65 f6 ff ff       	call   f0102e59 <env_destroy>
f01037f4:	83 c4 10             	add    $0x10,%esp
	return 0;
f01037f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01037fc:	eb 05                	jmp    f0103803 <syscall+0xcd>
		case (SYS_getenvid):
			return sys_getenvid();
		case (SYS_env_destroy):
			return sys_env_destroy(a1);
		default:
			return -E_INVAL;
f01037fe:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0103803:	c9                   	leave  
f0103804:	c3                   	ret    

f0103805 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103805:	55                   	push   %ebp
f0103806:	89 e5                	mov    %esp,%ebp
f0103808:	57                   	push   %edi
f0103809:	56                   	push   %esi
f010380a:	53                   	push   %ebx
f010380b:	83 ec 14             	sub    $0x14,%esp
f010380e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103811:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103814:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103817:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010381a:	8b 1a                	mov    (%edx),%ebx
f010381c:	8b 01                	mov    (%ecx),%eax
f010381e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103821:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103828:	eb 7f                	jmp    f01038a9 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010382a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010382d:	01 d8                	add    %ebx,%eax
f010382f:	89 c6                	mov    %eax,%esi
f0103831:	c1 ee 1f             	shr    $0x1f,%esi
f0103834:	01 c6                	add    %eax,%esi
f0103836:	d1 fe                	sar    %esi
f0103838:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010383b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010383e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103841:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103843:	eb 03                	jmp    f0103848 <stab_binsearch+0x43>
			m--;
f0103845:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103848:	39 c3                	cmp    %eax,%ebx
f010384a:	7f 0d                	jg     f0103859 <stab_binsearch+0x54>
f010384c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103850:	83 ea 0c             	sub    $0xc,%edx
f0103853:	39 f9                	cmp    %edi,%ecx
f0103855:	75 ee                	jne    f0103845 <stab_binsearch+0x40>
f0103857:	eb 05                	jmp    f010385e <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103859:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010385c:	eb 4b                	jmp    f01038a9 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010385e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103861:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103864:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103868:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010386b:	76 11                	jbe    f010387e <stab_binsearch+0x79>
			*region_left = m;
f010386d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103870:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103872:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103875:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010387c:	eb 2b                	jmp    f01038a9 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010387e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103881:	73 14                	jae    f0103897 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103883:	83 e8 01             	sub    $0x1,%eax
f0103886:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103889:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010388c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010388e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103895:	eb 12                	jmp    f01038a9 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103897:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010389a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010389c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01038a0:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038a2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01038a9:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01038ac:	0f 8e 78 ff ff ff    	jle    f010382a <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01038b2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01038b6:	75 0f                	jne    f01038c7 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01038b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038bb:	8b 00                	mov    (%eax),%eax
f01038bd:	83 e8 01             	sub    $0x1,%eax
f01038c0:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01038c3:	89 06                	mov    %eax,(%esi)
f01038c5:	eb 2c                	jmp    f01038f3 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01038c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01038ca:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01038cc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01038cf:	8b 0e                	mov    (%esi),%ecx
f01038d1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01038d4:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01038d7:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01038da:	eb 03                	jmp    f01038df <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01038dc:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01038df:	39 c8                	cmp    %ecx,%eax
f01038e1:	7e 0b                	jle    f01038ee <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01038e3:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01038e7:	83 ea 0c             	sub    $0xc,%edx
f01038ea:	39 df                	cmp    %ebx,%edi
f01038ec:	75 ee                	jne    f01038dc <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01038ee:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01038f1:	89 06                	mov    %eax,(%esi)
	}
}
f01038f3:	83 c4 14             	add    $0x14,%esp
f01038f6:	5b                   	pop    %ebx
f01038f7:	5e                   	pop    %esi
f01038f8:	5f                   	pop    %edi
f01038f9:	5d                   	pop    %ebp
f01038fa:	c3                   	ret    

f01038fb <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01038fb:	55                   	push   %ebp
f01038fc:	89 e5                	mov    %esp,%ebp
f01038fe:	57                   	push   %edi
f01038ff:	56                   	push   %esi
f0103900:	53                   	push   %ebx
f0103901:	83 ec 2c             	sub    $0x2c,%esp
f0103904:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103907:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010390a:	c7 06 28 5c 10 f0    	movl   $0xf0105c28,(%esi)
	info->eip_line = 0;
f0103910:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103917:	c7 46 08 28 5c 10 f0 	movl   $0xf0105c28,0x8(%esi)
	info->eip_fn_namelen = 9;
f010391e:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103925:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103928:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010392f:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103935:	77 21                	ja     f0103958 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103937:	a1 00 00 20 00       	mov    0x200000,%eax
f010393c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f010393f:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103944:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f010394a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f010394d:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f0103953:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0103956:	eb 1a                	jmp    f0103972 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103958:	c7 45 d0 d7 ff 10 f0 	movl   $0xf010ffd7,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010395f:	c7 45 cc 6d d5 10 f0 	movl   $0xf010d56d,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103966:	b8 6c d5 10 f0       	mov    $0xf010d56c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010396b:	c7 45 d4 50 5e 10 f0 	movl   $0xf0105e50,-0x2c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103972:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103975:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f0103978:	0f 83 2b 01 00 00    	jae    f0103aa9 <debuginfo_eip+0x1ae>
f010397e:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0103982:	0f 85 28 01 00 00    	jne    f0103ab0 <debuginfo_eip+0x1b5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103988:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010398f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103992:	29 d8                	sub    %ebx,%eax
f0103994:	c1 f8 02             	sar    $0x2,%eax
f0103997:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010399d:	83 e8 01             	sub    $0x1,%eax
f01039a0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01039a3:	57                   	push   %edi
f01039a4:	6a 64                	push   $0x64
f01039a6:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01039a9:	89 c1                	mov    %eax,%ecx
f01039ab:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01039ae:	89 d8                	mov    %ebx,%eax
f01039b0:	e8 50 fe ff ff       	call   f0103805 <stab_binsearch>
	if (lfile == 0)
f01039b5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039b8:	83 c4 08             	add    $0x8,%esp
f01039bb:	85 c0                	test   %eax,%eax
f01039bd:	0f 84 f4 00 00 00    	je     f0103ab7 <debuginfo_eip+0x1bc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01039c3:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01039c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039c9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01039cc:	57                   	push   %edi
f01039cd:	6a 24                	push   $0x24
f01039cf:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01039d2:	89 c1                	mov    %eax,%ecx
f01039d4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01039d7:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01039da:	89 d8                	mov    %ebx,%eax
f01039dc:	e8 24 fe ff ff       	call   f0103805 <stab_binsearch>

	if (lfun <= rfun) {
f01039e1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01039e4:	83 c4 08             	add    $0x8,%esp
f01039e7:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01039ea:	7f 24                	jg     f0103a10 <debuginfo_eip+0x115>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01039ec:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01039ef:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01039f2:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01039f5:	8b 02                	mov    (%edx),%eax
f01039f7:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01039fa:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01039fd:	29 f9                	sub    %edi,%ecx
f01039ff:	39 c8                	cmp    %ecx,%eax
f0103a01:	73 05                	jae    f0103a08 <debuginfo_eip+0x10d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103a03:	01 f8                	add    %edi,%eax
f0103a05:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103a08:	8b 42 08             	mov    0x8(%edx),%eax
f0103a0b:	89 46 10             	mov    %eax,0x10(%esi)
f0103a0e:	eb 06                	jmp    f0103a16 <debuginfo_eip+0x11b>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103a10:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103a13:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103a16:	83 ec 08             	sub    $0x8,%esp
f0103a19:	6a 3a                	push   $0x3a
f0103a1b:	ff 76 08             	pushl  0x8(%esi)
f0103a1e:	e8 39 08 00 00       	call   f010425c <strfind>
f0103a23:	2b 46 08             	sub    0x8(%esi),%eax
f0103a26:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a29:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a2c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103a2f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103a32:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0103a35:	83 c4 10             	add    $0x10,%esp
f0103a38:	eb 06                	jmp    f0103a40 <debuginfo_eip+0x145>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103a3a:	83 eb 01             	sub    $0x1,%ebx
f0103a3d:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a40:	39 fb                	cmp    %edi,%ebx
f0103a42:	7c 2d                	jl     f0103a71 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0103a44:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0103a48:	80 fa 84             	cmp    $0x84,%dl
f0103a4b:	74 0b                	je     f0103a58 <debuginfo_eip+0x15d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103a4d:	80 fa 64             	cmp    $0x64,%dl
f0103a50:	75 e8                	jne    f0103a3a <debuginfo_eip+0x13f>
f0103a52:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103a56:	74 e2                	je     f0103a3a <debuginfo_eip+0x13f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103a58:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103a5b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103a5e:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103a61:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103a64:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103a67:	29 f8                	sub    %edi,%eax
f0103a69:	39 c2                	cmp    %eax,%edx
f0103a6b:	73 04                	jae    f0103a71 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103a6d:	01 fa                	add    %edi,%edx
f0103a6f:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103a71:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103a74:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103a77:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103a7c:	39 cb                	cmp    %ecx,%ebx
f0103a7e:	7d 43                	jge    f0103ac3 <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
f0103a80:	8d 53 01             	lea    0x1(%ebx),%edx
f0103a83:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103a86:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103a89:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0103a8c:	eb 07                	jmp    f0103a95 <debuginfo_eip+0x19a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103a8e:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103a92:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103a95:	39 ca                	cmp    %ecx,%edx
f0103a97:	74 25                	je     f0103abe <debuginfo_eip+0x1c3>
f0103a99:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103a9c:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0103aa0:	74 ec                	je     f0103a8e <debuginfo_eip+0x193>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103aa2:	b8 00 00 00 00       	mov    $0x0,%eax
f0103aa7:	eb 1a                	jmp    f0103ac3 <debuginfo_eip+0x1c8>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103aa9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103aae:	eb 13                	jmp    f0103ac3 <debuginfo_eip+0x1c8>
f0103ab0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ab5:	eb 0c                	jmp    f0103ac3 <debuginfo_eip+0x1c8>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103ab7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103abc:	eb 05                	jmp    f0103ac3 <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103abe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ac3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ac6:	5b                   	pop    %ebx
f0103ac7:	5e                   	pop    %esi
f0103ac8:	5f                   	pop    %edi
f0103ac9:	5d                   	pop    %ebp
f0103aca:	c3                   	ret    

f0103acb <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103acb:	55                   	push   %ebp
f0103acc:	89 e5                	mov    %esp,%ebp
f0103ace:	57                   	push   %edi
f0103acf:	56                   	push   %esi
f0103ad0:	53                   	push   %ebx
f0103ad1:	83 ec 1c             	sub    $0x1c,%esp
f0103ad4:	89 c7                	mov    %eax,%edi
f0103ad6:	89 d6                	mov    %edx,%esi
f0103ad8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103adb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ade:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ae1:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103ae4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103ae7:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103aec:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103aef:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103af2:	39 d3                	cmp    %edx,%ebx
f0103af4:	72 05                	jb     f0103afb <printnum+0x30>
f0103af6:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103af9:	77 45                	ja     f0103b40 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103afb:	83 ec 0c             	sub    $0xc,%esp
f0103afe:	ff 75 18             	pushl  0x18(%ebp)
f0103b01:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b04:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103b07:	53                   	push   %ebx
f0103b08:	ff 75 10             	pushl  0x10(%ebp)
f0103b0b:	83 ec 08             	sub    $0x8,%esp
f0103b0e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b11:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b14:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b17:	ff 75 d8             	pushl  -0x28(%ebp)
f0103b1a:	e8 61 09 00 00       	call   f0104480 <__udivdi3>
f0103b1f:	83 c4 18             	add    $0x18,%esp
f0103b22:	52                   	push   %edx
f0103b23:	50                   	push   %eax
f0103b24:	89 f2                	mov    %esi,%edx
f0103b26:	89 f8                	mov    %edi,%eax
f0103b28:	e8 9e ff ff ff       	call   f0103acb <printnum>
f0103b2d:	83 c4 20             	add    $0x20,%esp
f0103b30:	eb 18                	jmp    f0103b4a <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103b32:	83 ec 08             	sub    $0x8,%esp
f0103b35:	56                   	push   %esi
f0103b36:	ff 75 18             	pushl  0x18(%ebp)
f0103b39:	ff d7                	call   *%edi
f0103b3b:	83 c4 10             	add    $0x10,%esp
f0103b3e:	eb 03                	jmp    f0103b43 <printnum+0x78>
f0103b40:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103b43:	83 eb 01             	sub    $0x1,%ebx
f0103b46:	85 db                	test   %ebx,%ebx
f0103b48:	7f e8                	jg     f0103b32 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103b4a:	83 ec 08             	sub    $0x8,%esp
f0103b4d:	56                   	push   %esi
f0103b4e:	83 ec 04             	sub    $0x4,%esp
f0103b51:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b54:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b57:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b5a:	ff 75 d8             	pushl  -0x28(%ebp)
f0103b5d:	e8 4e 0a 00 00       	call   f01045b0 <__umoddi3>
f0103b62:	83 c4 14             	add    $0x14,%esp
f0103b65:	0f be 80 32 5c 10 f0 	movsbl -0xfefa3ce(%eax),%eax
f0103b6c:	50                   	push   %eax
f0103b6d:	ff d7                	call   *%edi
}
f0103b6f:	83 c4 10             	add    $0x10,%esp
f0103b72:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b75:	5b                   	pop    %ebx
f0103b76:	5e                   	pop    %esi
f0103b77:	5f                   	pop    %edi
f0103b78:	5d                   	pop    %ebp
f0103b79:	c3                   	ret    

f0103b7a <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103b7a:	55                   	push   %ebp
f0103b7b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103b7d:	83 fa 01             	cmp    $0x1,%edx
f0103b80:	7e 0e                	jle    f0103b90 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103b82:	8b 10                	mov    (%eax),%edx
f0103b84:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103b87:	89 08                	mov    %ecx,(%eax)
f0103b89:	8b 02                	mov    (%edx),%eax
f0103b8b:	8b 52 04             	mov    0x4(%edx),%edx
f0103b8e:	eb 22                	jmp    f0103bb2 <getuint+0x38>
	else if (lflag)
f0103b90:	85 d2                	test   %edx,%edx
f0103b92:	74 10                	je     f0103ba4 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103b94:	8b 10                	mov    (%eax),%edx
f0103b96:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103b99:	89 08                	mov    %ecx,(%eax)
f0103b9b:	8b 02                	mov    (%edx),%eax
f0103b9d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103ba2:	eb 0e                	jmp    f0103bb2 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103ba4:	8b 10                	mov    (%eax),%edx
f0103ba6:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103ba9:	89 08                	mov    %ecx,(%eax)
f0103bab:	8b 02                	mov    (%edx),%eax
f0103bad:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103bb2:	5d                   	pop    %ebp
f0103bb3:	c3                   	ret    

f0103bb4 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103bb4:	55                   	push   %ebp
f0103bb5:	89 e5                	mov    %esp,%ebp
f0103bb7:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103bba:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103bbe:	8b 10                	mov    (%eax),%edx
f0103bc0:	3b 50 04             	cmp    0x4(%eax),%edx
f0103bc3:	73 0a                	jae    f0103bcf <sprintputch+0x1b>
		*b->buf++ = ch;
f0103bc5:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103bc8:	89 08                	mov    %ecx,(%eax)
f0103bca:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bcd:	88 02                	mov    %al,(%edx)
}
f0103bcf:	5d                   	pop    %ebp
f0103bd0:	c3                   	ret    

f0103bd1 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103bd1:	55                   	push   %ebp
f0103bd2:	89 e5                	mov    %esp,%ebp
f0103bd4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103bd7:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103bda:	50                   	push   %eax
f0103bdb:	ff 75 10             	pushl  0x10(%ebp)
f0103bde:	ff 75 0c             	pushl  0xc(%ebp)
f0103be1:	ff 75 08             	pushl  0x8(%ebp)
f0103be4:	e8 05 00 00 00       	call   f0103bee <vprintfmt>
	va_end(ap);
}
f0103be9:	83 c4 10             	add    $0x10,%esp
f0103bec:	c9                   	leave  
f0103bed:	c3                   	ret    

f0103bee <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103bee:	55                   	push   %ebp
f0103bef:	89 e5                	mov    %esp,%ebp
f0103bf1:	57                   	push   %edi
f0103bf2:	56                   	push   %esi
f0103bf3:	53                   	push   %ebx
f0103bf4:	83 ec 2c             	sub    $0x2c,%esp
f0103bf7:	8b 75 08             	mov    0x8(%ebp),%esi
f0103bfa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103bfd:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103c00:	eb 12                	jmp    f0103c14 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')									//当然中间如果遇到'\0'，代表这个字符串的访问结束
f0103c02:	85 c0                	test   %eax,%eax
f0103c04:	0f 84 a7 03 00 00    	je     f0103fb1 <vprintfmt+0x3c3>
				return;
			putch(ch, putdat);								//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
f0103c0a:	83 ec 08             	sub    $0x8,%esp
f0103c0d:	53                   	push   %ebx
f0103c0e:	50                   	push   %eax
f0103c0f:	ff d6                	call   *%esi
f0103c11:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
f0103c14:	83 c7 01             	add    $0x1,%edi
f0103c17:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103c1b:	83 f8 25             	cmp    $0x25,%eax
f0103c1e:	75 e2                	jne    f0103c02 <vprintfmt+0x14>
f0103c20:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103c24:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103c2b:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0103c32:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103c39:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0103c40:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103c45:	eb 07                	jmp    f0103c4e <vprintfmt+0x60>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103c47:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':											//%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
f0103c4a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103c4e:	8d 47 01             	lea    0x1(%edi),%eax
f0103c51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103c54:	0f b6 07             	movzbl (%edi),%eax
f0103c57:	0f b6 d0             	movzbl %al,%edx
f0103c5a:	83 e8 23             	sub    $0x23,%eax
f0103c5d:	3c 55                	cmp    $0x55,%al
f0103c5f:	0f 87 31 03 00 00    	ja     f0103f96 <vprintfmt+0x3a8>
f0103c65:	0f b6 c0             	movzbl %al,%eax
f0103c68:	ff 24 85 c0 5c 10 f0 	jmp    *-0xfefa340(,%eax,4)
f0103c6f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;									//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0':											//0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';										//对其方式标志位变为0
f0103c72:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103c76:	eb d6                	jmp    f0103c4e <vprintfmt+0x60>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103c78:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c7b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c80:	89 75 08             	mov    %esi,0x8(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
f0103c83:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103c86:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103c8a:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103c8d:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103c90:	83 fe 09             	cmp    $0x9,%esi
f0103c93:	77 34                	ja     f0103cc9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
f0103c95:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103c98:	eb e9                	jmp    f0103c83 <vprintfmt+0x95>
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
f0103c9a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c9d:	8d 50 04             	lea    0x4(%eax),%edx
f0103ca0:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ca3:	8b 00                	mov    (%eax),%eax
f0103ca5:	89 45 cc             	mov    %eax,-0x34(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103ca8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
f0103cab:	eb 22                	jmp    f0103ccf <vprintfmt+0xe1>
f0103cad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103cb0:	85 c0                	test   %eax,%eax
f0103cb2:	0f 48 c1             	cmovs  %ecx,%eax
f0103cb5:	89 45 e0             	mov    %eax,-0x20(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103cb8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103cbb:	eb 91                	jmp    f0103c4e <vprintfmt+0x60>
f0103cbd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)									//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;			
			goto reswitch;

		case '#':
			altflag = 1;
f0103cc0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103cc7:	eb 85                	jmp    f0103c4e <vprintfmt+0x60>
f0103cc9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103ccc:	8b 75 08             	mov    0x8(%ebp),%esi

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
f0103ccf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103cd3:	0f 89 75 ff ff ff    	jns    f0103c4e <vprintfmt+0x60>
				width = precision, precision = -1;
f0103cd9:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103cdc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103cdf:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0103ce6:	e9 63 ff ff ff       	jmp    f0103c4e <vprintfmt+0x60>
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
f0103ceb:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103cef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
			goto reswitch;
f0103cf2:	e9 57 ff ff ff       	jmp    f0103c4e <vprintfmt+0x60>

		// character
		case 'c':											//如果是'c'代表显示一个字符
			putch(va_arg(ap, int), putdat);					//调用输出一个字符到内存的函数putch
f0103cf7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cfa:	8d 50 04             	lea    0x4(%eax),%edx
f0103cfd:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d00:	83 ec 08             	sub    $0x8,%esp
f0103d03:	53                   	push   %ebx
f0103d04:	ff 30                	pushl  (%eax)
f0103d06:	ff d6                	call   *%esi
			break;
f0103d08:	83 c4 10             	add    $0x10,%esp
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103d0b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':											//如果是'c'代表显示一个字符
			putch(va_arg(ap, int), putdat);					//调用输出一个字符到内存的函数putch
			break;
f0103d0e:	e9 01 ff ff ff       	jmp    f0103c14 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d13:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d16:	8d 50 04             	lea    0x4(%eax),%edx
f0103d19:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d1c:	8b 00                	mov    (%eax),%eax
f0103d1e:	99                   	cltd   
f0103d1f:	31 d0                	xor    %edx,%eax
f0103d21:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103d23:	83 f8 07             	cmp    $0x7,%eax
f0103d26:	7f 0b                	jg     f0103d33 <vprintfmt+0x145>
f0103d28:	8b 14 85 20 5e 10 f0 	mov    -0xfefa1e0(,%eax,4),%edx
f0103d2f:	85 d2                	test   %edx,%edx
f0103d31:	75 18                	jne    f0103d4b <vprintfmt+0x15d>
				printfmt(putch, putdat, "error %d", err);
f0103d33:	50                   	push   %eax
f0103d34:	68 4a 5c 10 f0       	push   $0xf0105c4a
f0103d39:	53                   	push   %ebx
f0103d3a:	56                   	push   %esi
f0103d3b:	e8 91 fe ff ff       	call   f0103bd1 <printfmt>
f0103d40:	83 c4 10             	add    $0x10,%esp
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103d43:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103d46:	e9 c9 fe ff ff       	jmp    f0103c14 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103d4b:	52                   	push   %edx
f0103d4c:	68 6c 4c 10 f0       	push   $0xf0104c6c
f0103d51:	53                   	push   %ebx
f0103d52:	56                   	push   %esi
f0103d53:	e8 79 fe ff ff       	call   f0103bd1 <printfmt>
f0103d58:	83 c4 10             	add    $0x10,%esp
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103d5b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d5e:	e9 b1 fe ff ff       	jmp    f0103c14 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103d63:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d66:	8d 50 04             	lea    0x4(%eax),%edx
f0103d69:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d6c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103d6e:	85 ff                	test   %edi,%edi
f0103d70:	b8 43 5c 10 f0       	mov    $0xf0105c43,%eax
f0103d75:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103d78:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d7c:	0f 8e 94 00 00 00    	jle    f0103e16 <vprintfmt+0x228>
f0103d82:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103d86:	0f 84 98 00 00 00    	je     f0103e24 <vprintfmt+0x236>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103d8c:	83 ec 08             	sub    $0x8,%esp
f0103d8f:	ff 75 cc             	pushl  -0x34(%ebp)
f0103d92:	57                   	push   %edi
f0103d93:	e8 7a 03 00 00       	call   f0104112 <strnlen>
f0103d98:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103d9b:	29 c1                	sub    %eax,%ecx
f0103d9d:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0103da0:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103da3:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103da7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103daa:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103dad:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103daf:	eb 0f                	jmp    f0103dc0 <vprintfmt+0x1d2>
					putch(padc, putdat);
f0103db1:	83 ec 08             	sub    $0x8,%esp
f0103db4:	53                   	push   %ebx
f0103db5:	ff 75 e0             	pushl  -0x20(%ebp)
f0103db8:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103dba:	83 ef 01             	sub    $0x1,%edi
f0103dbd:	83 c4 10             	add    $0x10,%esp
f0103dc0:	85 ff                	test   %edi,%edi
f0103dc2:	7f ed                	jg     f0103db1 <vprintfmt+0x1c3>
f0103dc4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103dc7:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103dca:	85 c9                	test   %ecx,%ecx
f0103dcc:	b8 00 00 00 00       	mov    $0x0,%eax
f0103dd1:	0f 49 c1             	cmovns %ecx,%eax
f0103dd4:	29 c1                	sub    %eax,%ecx
f0103dd6:	89 75 08             	mov    %esi,0x8(%ebp)
f0103dd9:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103ddc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103ddf:	89 cb                	mov    %ecx,%ebx
f0103de1:	eb 4d                	jmp    f0103e30 <vprintfmt+0x242>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103de3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103de7:	74 1b                	je     f0103e04 <vprintfmt+0x216>
f0103de9:	0f be c0             	movsbl %al,%eax
f0103dec:	83 e8 20             	sub    $0x20,%eax
f0103def:	83 f8 5e             	cmp    $0x5e,%eax
f0103df2:	76 10                	jbe    f0103e04 <vprintfmt+0x216>
					putch('?', putdat);
f0103df4:	83 ec 08             	sub    $0x8,%esp
f0103df7:	ff 75 0c             	pushl  0xc(%ebp)
f0103dfa:	6a 3f                	push   $0x3f
f0103dfc:	ff 55 08             	call   *0x8(%ebp)
f0103dff:	83 c4 10             	add    $0x10,%esp
f0103e02:	eb 0d                	jmp    f0103e11 <vprintfmt+0x223>
				else
					putch(ch, putdat);
f0103e04:	83 ec 08             	sub    $0x8,%esp
f0103e07:	ff 75 0c             	pushl  0xc(%ebp)
f0103e0a:	52                   	push   %edx
f0103e0b:	ff 55 08             	call   *0x8(%ebp)
f0103e0e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103e11:	83 eb 01             	sub    $0x1,%ebx
f0103e14:	eb 1a                	jmp    f0103e30 <vprintfmt+0x242>
f0103e16:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e19:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103e1c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e1f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e22:	eb 0c                	jmp    f0103e30 <vprintfmt+0x242>
f0103e24:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e27:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103e2a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e2d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e30:	83 c7 01             	add    $0x1,%edi
f0103e33:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103e37:	0f be d0             	movsbl %al,%edx
f0103e3a:	85 d2                	test   %edx,%edx
f0103e3c:	74 23                	je     f0103e61 <vprintfmt+0x273>
f0103e3e:	85 f6                	test   %esi,%esi
f0103e40:	78 a1                	js     f0103de3 <vprintfmt+0x1f5>
f0103e42:	83 ee 01             	sub    $0x1,%esi
f0103e45:	79 9c                	jns    f0103de3 <vprintfmt+0x1f5>
f0103e47:	89 df                	mov    %ebx,%edi
f0103e49:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e4c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e4f:	eb 18                	jmp    f0103e69 <vprintfmt+0x27b>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103e51:	83 ec 08             	sub    $0x8,%esp
f0103e54:	53                   	push   %ebx
f0103e55:	6a 20                	push   $0x20
f0103e57:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103e59:	83 ef 01             	sub    $0x1,%edi
f0103e5c:	83 c4 10             	add    $0x10,%esp
f0103e5f:	eb 08                	jmp    f0103e69 <vprintfmt+0x27b>
f0103e61:	89 df                	mov    %ebx,%edi
f0103e63:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e66:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e69:	85 ff                	test   %edi,%edi
f0103e6b:	7f e4                	jg     f0103e51 <vprintfmt+0x263>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103e6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e70:	e9 9f fd ff ff       	jmp    f0103c14 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103e75:	83 7d d0 01          	cmpl   $0x1,-0x30(%ebp)
f0103e79:	7e 16                	jle    f0103e91 <vprintfmt+0x2a3>
		return va_arg(*ap, long long);
f0103e7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e7e:	8d 50 08             	lea    0x8(%eax),%edx
f0103e81:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e84:	8b 50 04             	mov    0x4(%eax),%edx
f0103e87:	8b 00                	mov    (%eax),%eax
f0103e89:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103e8c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103e8f:	eb 34                	jmp    f0103ec5 <vprintfmt+0x2d7>
	else if (lflag)
f0103e91:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103e95:	74 18                	je     f0103eaf <vprintfmt+0x2c1>
		return va_arg(*ap, long);
f0103e97:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e9a:	8d 50 04             	lea    0x4(%eax),%edx
f0103e9d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ea0:	8b 00                	mov    (%eax),%eax
f0103ea2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ea5:	89 c1                	mov    %eax,%ecx
f0103ea7:	c1 f9 1f             	sar    $0x1f,%ecx
f0103eaa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103ead:	eb 16                	jmp    f0103ec5 <vprintfmt+0x2d7>
	else
		return va_arg(*ap, int);
f0103eaf:	8b 45 14             	mov    0x14(%ebp),%eax
f0103eb2:	8d 50 04             	lea    0x4(%eax),%edx
f0103eb5:	89 55 14             	mov    %edx,0x14(%ebp)
f0103eb8:	8b 00                	mov    (%eax),%eax
f0103eba:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ebd:	89 c1                	mov    %eax,%ecx
f0103ebf:	c1 f9 1f             	sar    $0x1f,%ecx
f0103ec2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103ec5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103ec8:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103ecb:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103ed0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103ed4:	0f 89 88 00 00 00    	jns    f0103f62 <vprintfmt+0x374>
				putch('-', putdat);
f0103eda:	83 ec 08             	sub    $0x8,%esp
f0103edd:	53                   	push   %ebx
f0103ede:	6a 2d                	push   $0x2d
f0103ee0:	ff d6                	call   *%esi
				num = -(long long) num;
f0103ee2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103ee5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103ee8:	f7 d8                	neg    %eax
f0103eea:	83 d2 00             	adc    $0x0,%edx
f0103eed:	f7 da                	neg    %edx
f0103eef:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103ef2:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103ef7:	eb 69                	jmp    f0103f62 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103ef9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103efc:	8d 45 14             	lea    0x14(%ebp),%eax
f0103eff:	e8 76 fc ff ff       	call   f0103b7a <getuint>
			base = 10;
f0103f04:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103f09:	eb 57                	jmp    f0103f62 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('0', putdat);
f0103f0b:	83 ec 08             	sub    $0x8,%esp
f0103f0e:	53                   	push   %ebx
f0103f0f:	6a 30                	push   $0x30
f0103f11:	ff d6                	call   *%esi
			num = getuint(&ap, lflag);
f0103f13:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103f16:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f19:	e8 5c fc ff ff       	call   f0103b7a <getuint>
			base = 8;
			goto number;
f0103f1e:	83 c4 10             	add    $0x10,%esp
		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('0', putdat);
			num = getuint(&ap, lflag);
			base = 8;
f0103f21:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103f26:	eb 3a                	jmp    f0103f62 <vprintfmt+0x374>
		// pointer
		case 'p':
			putch('0', putdat);
f0103f28:	83 ec 08             	sub    $0x8,%esp
f0103f2b:	53                   	push   %ebx
f0103f2c:	6a 30                	push   $0x30
f0103f2e:	ff d6                	call   *%esi
			putch('x', putdat);
f0103f30:	83 c4 08             	add    $0x8,%esp
f0103f33:	53                   	push   %ebx
f0103f34:	6a 78                	push   $0x78
f0103f36:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103f38:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f3b:	8d 50 04             	lea    0x4(%eax),%edx
f0103f3e:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103f41:	8b 00                	mov    (%eax),%eax
f0103f43:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103f48:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103f4b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103f50:	eb 10                	jmp    f0103f62 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103f52:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103f55:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f58:	e8 1d fc ff ff       	call   f0103b7a <getuint>
			base = 16;
f0103f5d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103f62:	83 ec 0c             	sub    $0xc,%esp
f0103f65:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103f69:	57                   	push   %edi
f0103f6a:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f6d:	51                   	push   %ecx
f0103f6e:	52                   	push   %edx
f0103f6f:	50                   	push   %eax
f0103f70:	89 da                	mov    %ebx,%edx
f0103f72:	89 f0                	mov    %esi,%eax
f0103f74:	e8 52 fb ff ff       	call   f0103acb <printnum>
			break;
f0103f79:	83 c4 20             	add    $0x20,%esp
f0103f7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f7f:	e9 90 fc ff ff       	jmp    f0103c14 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103f84:	83 ec 08             	sub    $0x8,%esp
f0103f87:	53                   	push   %ebx
f0103f88:	52                   	push   %edx
f0103f89:	ff d6                	call   *%esi
			break;
f0103f8b:	83 c4 10             	add    $0x10,%esp
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0103f8e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103f91:	e9 7e fc ff ff       	jmp    f0103c14 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103f96:	83 ec 08             	sub    $0x8,%esp
f0103f99:	53                   	push   %ebx
f0103f9a:	6a 25                	push   $0x25
f0103f9c:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103f9e:	83 c4 10             	add    $0x10,%esp
f0103fa1:	eb 03                	jmp    f0103fa6 <vprintfmt+0x3b8>
f0103fa3:	83 ef 01             	sub    $0x1,%edi
f0103fa6:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103faa:	75 f7                	jne    f0103fa3 <vprintfmt+0x3b5>
f0103fac:	e9 63 fc ff ff       	jmp    f0103c14 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103fb1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103fb4:	5b                   	pop    %ebx
f0103fb5:	5e                   	pop    %esi
f0103fb6:	5f                   	pop    %edi
f0103fb7:	5d                   	pop    %ebp
f0103fb8:	c3                   	ret    

f0103fb9 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103fb9:	55                   	push   %ebp
f0103fba:	89 e5                	mov    %esp,%ebp
f0103fbc:	83 ec 18             	sub    $0x18,%esp
f0103fbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fc2:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103fc5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103fc8:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103fcc:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103fcf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103fd6:	85 c0                	test   %eax,%eax
f0103fd8:	74 26                	je     f0104000 <vsnprintf+0x47>
f0103fda:	85 d2                	test   %edx,%edx
f0103fdc:	7e 22                	jle    f0104000 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103fde:	ff 75 14             	pushl  0x14(%ebp)
f0103fe1:	ff 75 10             	pushl  0x10(%ebp)
f0103fe4:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103fe7:	50                   	push   %eax
f0103fe8:	68 b4 3b 10 f0       	push   $0xf0103bb4
f0103fed:	e8 fc fb ff ff       	call   f0103bee <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103ff2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103ff5:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103ff8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103ffb:	83 c4 10             	add    $0x10,%esp
f0103ffe:	eb 05                	jmp    f0104005 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104000:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104005:	c9                   	leave  
f0104006:	c3                   	ret    

f0104007 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104007:	55                   	push   %ebp
f0104008:	89 e5                	mov    %esp,%ebp
f010400a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010400d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104010:	50                   	push   %eax
f0104011:	ff 75 10             	pushl  0x10(%ebp)
f0104014:	ff 75 0c             	pushl  0xc(%ebp)
f0104017:	ff 75 08             	pushl  0x8(%ebp)
f010401a:	e8 9a ff ff ff       	call   f0103fb9 <vsnprintf>
	va_end(ap);

	return rc;
}
f010401f:	c9                   	leave  
f0104020:	c3                   	ret    

f0104021 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104021:	55                   	push   %ebp
f0104022:	89 e5                	mov    %esp,%ebp
f0104024:	57                   	push   %edi
f0104025:	56                   	push   %esi
f0104026:	53                   	push   %ebx
f0104027:	83 ec 0c             	sub    $0xc,%esp
f010402a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010402d:	85 c0                	test   %eax,%eax
f010402f:	74 11                	je     f0104042 <readline+0x21>
		cprintf("%s", prompt);
f0104031:	83 ec 08             	sub    $0x8,%esp
f0104034:	50                   	push   %eax
f0104035:	68 6c 4c 10 f0       	push   $0xf0104c6c
f010403a:	e8 33 ef ff ff       	call   f0102f72 <cprintf>
f010403f:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104042:	83 ec 0c             	sub    $0xc,%esp
f0104045:	6a 00                	push   $0x0
f0104047:	e8 dc c5 ff ff       	call   f0100628 <iscons>
f010404c:	89 c7                	mov    %eax,%edi
f010404e:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104051:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104056:	e8 bc c5 ff ff       	call   f0100617 <getchar>
f010405b:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010405d:	85 c0                	test   %eax,%eax
f010405f:	79 18                	jns    f0104079 <readline+0x58>
			cprintf("read error: %e\n", c);
f0104061:	83 ec 08             	sub    $0x8,%esp
f0104064:	50                   	push   %eax
f0104065:	68 40 5e 10 f0       	push   $0xf0105e40
f010406a:	e8 03 ef ff ff       	call   f0102f72 <cprintf>
			return NULL;
f010406f:	83 c4 10             	add    $0x10,%esp
f0104072:	b8 00 00 00 00       	mov    $0x0,%eax
f0104077:	eb 79                	jmp    f01040f2 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104079:	83 f8 08             	cmp    $0x8,%eax
f010407c:	0f 94 c2             	sete   %dl
f010407f:	83 f8 7f             	cmp    $0x7f,%eax
f0104082:	0f 94 c0             	sete   %al
f0104085:	08 c2                	or     %al,%dl
f0104087:	74 1a                	je     f01040a3 <readline+0x82>
f0104089:	85 f6                	test   %esi,%esi
f010408b:	7e 16                	jle    f01040a3 <readline+0x82>
			if (echoing)
f010408d:	85 ff                	test   %edi,%edi
f010408f:	74 0d                	je     f010409e <readline+0x7d>
				cputchar('\b');
f0104091:	83 ec 0c             	sub    $0xc,%esp
f0104094:	6a 08                	push   $0x8
f0104096:	e8 6c c5 ff ff       	call   f0100607 <cputchar>
f010409b:	83 c4 10             	add    $0x10,%esp
			i--;
f010409e:	83 ee 01             	sub    $0x1,%esi
f01040a1:	eb b3                	jmp    f0104056 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01040a3:	83 fb 1f             	cmp    $0x1f,%ebx
f01040a6:	7e 23                	jle    f01040cb <readline+0xaa>
f01040a8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01040ae:	7f 1b                	jg     f01040cb <readline+0xaa>
			if (echoing)
f01040b0:	85 ff                	test   %edi,%edi
f01040b2:	74 0c                	je     f01040c0 <readline+0x9f>
				cputchar(c);
f01040b4:	83 ec 0c             	sub    $0xc,%esp
f01040b7:	53                   	push   %ebx
f01040b8:	e8 4a c5 ff ff       	call   f0100607 <cputchar>
f01040bd:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01040c0:	88 9e 40 c8 17 f0    	mov    %bl,-0xfe837c0(%esi)
f01040c6:	8d 76 01             	lea    0x1(%esi),%esi
f01040c9:	eb 8b                	jmp    f0104056 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01040cb:	83 fb 0a             	cmp    $0xa,%ebx
f01040ce:	74 05                	je     f01040d5 <readline+0xb4>
f01040d0:	83 fb 0d             	cmp    $0xd,%ebx
f01040d3:	75 81                	jne    f0104056 <readline+0x35>
			if (echoing)
f01040d5:	85 ff                	test   %edi,%edi
f01040d7:	74 0d                	je     f01040e6 <readline+0xc5>
				cputchar('\n');
f01040d9:	83 ec 0c             	sub    $0xc,%esp
f01040dc:	6a 0a                	push   $0xa
f01040de:	e8 24 c5 ff ff       	call   f0100607 <cputchar>
f01040e3:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01040e6:	c6 86 40 c8 17 f0 00 	movb   $0x0,-0xfe837c0(%esi)
			return buf;
f01040ed:	b8 40 c8 17 f0       	mov    $0xf017c840,%eax
		}
	}
}
f01040f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040f5:	5b                   	pop    %ebx
f01040f6:	5e                   	pop    %esi
f01040f7:	5f                   	pop    %edi
f01040f8:	5d                   	pop    %ebp
f01040f9:	c3                   	ret    

f01040fa <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01040fa:	55                   	push   %ebp
f01040fb:	89 e5                	mov    %esp,%ebp
f01040fd:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104100:	b8 00 00 00 00       	mov    $0x0,%eax
f0104105:	eb 03                	jmp    f010410a <strlen+0x10>
		n++;
f0104107:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010410a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010410e:	75 f7                	jne    f0104107 <strlen+0xd>
		n++;
	return n;
}
f0104110:	5d                   	pop    %ebp
f0104111:	c3                   	ret    

f0104112 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104112:	55                   	push   %ebp
f0104113:	89 e5                	mov    %esp,%ebp
f0104115:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104118:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010411b:	ba 00 00 00 00       	mov    $0x0,%edx
f0104120:	eb 03                	jmp    f0104125 <strnlen+0x13>
		n++;
f0104122:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104125:	39 c2                	cmp    %eax,%edx
f0104127:	74 08                	je     f0104131 <strnlen+0x1f>
f0104129:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010412d:	75 f3                	jne    f0104122 <strnlen+0x10>
f010412f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104131:	5d                   	pop    %ebp
f0104132:	c3                   	ret    

f0104133 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104133:	55                   	push   %ebp
f0104134:	89 e5                	mov    %esp,%ebp
f0104136:	53                   	push   %ebx
f0104137:	8b 45 08             	mov    0x8(%ebp),%eax
f010413a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010413d:	89 c2                	mov    %eax,%edx
f010413f:	83 c2 01             	add    $0x1,%edx
f0104142:	83 c1 01             	add    $0x1,%ecx
f0104145:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104149:	88 5a ff             	mov    %bl,-0x1(%edx)
f010414c:	84 db                	test   %bl,%bl
f010414e:	75 ef                	jne    f010413f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104150:	5b                   	pop    %ebx
f0104151:	5d                   	pop    %ebp
f0104152:	c3                   	ret    

f0104153 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104153:	55                   	push   %ebp
f0104154:	89 e5                	mov    %esp,%ebp
f0104156:	53                   	push   %ebx
f0104157:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010415a:	53                   	push   %ebx
f010415b:	e8 9a ff ff ff       	call   f01040fa <strlen>
f0104160:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104163:	ff 75 0c             	pushl  0xc(%ebp)
f0104166:	01 d8                	add    %ebx,%eax
f0104168:	50                   	push   %eax
f0104169:	e8 c5 ff ff ff       	call   f0104133 <strcpy>
	return dst;
}
f010416e:	89 d8                	mov    %ebx,%eax
f0104170:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104173:	c9                   	leave  
f0104174:	c3                   	ret    

f0104175 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104175:	55                   	push   %ebp
f0104176:	89 e5                	mov    %esp,%ebp
f0104178:	56                   	push   %esi
f0104179:	53                   	push   %ebx
f010417a:	8b 75 08             	mov    0x8(%ebp),%esi
f010417d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104180:	89 f3                	mov    %esi,%ebx
f0104182:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104185:	89 f2                	mov    %esi,%edx
f0104187:	eb 0f                	jmp    f0104198 <strncpy+0x23>
		*dst++ = *src;
f0104189:	83 c2 01             	add    $0x1,%edx
f010418c:	0f b6 01             	movzbl (%ecx),%eax
f010418f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104192:	80 39 01             	cmpb   $0x1,(%ecx)
f0104195:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104198:	39 da                	cmp    %ebx,%edx
f010419a:	75 ed                	jne    f0104189 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010419c:	89 f0                	mov    %esi,%eax
f010419e:	5b                   	pop    %ebx
f010419f:	5e                   	pop    %esi
f01041a0:	5d                   	pop    %ebp
f01041a1:	c3                   	ret    

f01041a2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01041a2:	55                   	push   %ebp
f01041a3:	89 e5                	mov    %esp,%ebp
f01041a5:	56                   	push   %esi
f01041a6:	53                   	push   %ebx
f01041a7:	8b 75 08             	mov    0x8(%ebp),%esi
f01041aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01041ad:	8b 55 10             	mov    0x10(%ebp),%edx
f01041b0:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01041b2:	85 d2                	test   %edx,%edx
f01041b4:	74 21                	je     f01041d7 <strlcpy+0x35>
f01041b6:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01041ba:	89 f2                	mov    %esi,%edx
f01041bc:	eb 09                	jmp    f01041c7 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01041be:	83 c2 01             	add    $0x1,%edx
f01041c1:	83 c1 01             	add    $0x1,%ecx
f01041c4:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01041c7:	39 c2                	cmp    %eax,%edx
f01041c9:	74 09                	je     f01041d4 <strlcpy+0x32>
f01041cb:	0f b6 19             	movzbl (%ecx),%ebx
f01041ce:	84 db                	test   %bl,%bl
f01041d0:	75 ec                	jne    f01041be <strlcpy+0x1c>
f01041d2:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01041d4:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01041d7:	29 f0                	sub    %esi,%eax
}
f01041d9:	5b                   	pop    %ebx
f01041da:	5e                   	pop    %esi
f01041db:	5d                   	pop    %ebp
f01041dc:	c3                   	ret    

f01041dd <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01041dd:	55                   	push   %ebp
f01041de:	89 e5                	mov    %esp,%ebp
f01041e0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01041e3:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01041e6:	eb 06                	jmp    f01041ee <strcmp+0x11>
		p++, q++;
f01041e8:	83 c1 01             	add    $0x1,%ecx
f01041eb:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01041ee:	0f b6 01             	movzbl (%ecx),%eax
f01041f1:	84 c0                	test   %al,%al
f01041f3:	74 04                	je     f01041f9 <strcmp+0x1c>
f01041f5:	3a 02                	cmp    (%edx),%al
f01041f7:	74 ef                	je     f01041e8 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01041f9:	0f b6 c0             	movzbl %al,%eax
f01041fc:	0f b6 12             	movzbl (%edx),%edx
f01041ff:	29 d0                	sub    %edx,%eax
}
f0104201:	5d                   	pop    %ebp
f0104202:	c3                   	ret    

f0104203 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104203:	55                   	push   %ebp
f0104204:	89 e5                	mov    %esp,%ebp
f0104206:	53                   	push   %ebx
f0104207:	8b 45 08             	mov    0x8(%ebp),%eax
f010420a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010420d:	89 c3                	mov    %eax,%ebx
f010420f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104212:	eb 06                	jmp    f010421a <strncmp+0x17>
		n--, p++, q++;
f0104214:	83 c0 01             	add    $0x1,%eax
f0104217:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010421a:	39 d8                	cmp    %ebx,%eax
f010421c:	74 15                	je     f0104233 <strncmp+0x30>
f010421e:	0f b6 08             	movzbl (%eax),%ecx
f0104221:	84 c9                	test   %cl,%cl
f0104223:	74 04                	je     f0104229 <strncmp+0x26>
f0104225:	3a 0a                	cmp    (%edx),%cl
f0104227:	74 eb                	je     f0104214 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104229:	0f b6 00             	movzbl (%eax),%eax
f010422c:	0f b6 12             	movzbl (%edx),%edx
f010422f:	29 d0                	sub    %edx,%eax
f0104231:	eb 05                	jmp    f0104238 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104233:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104238:	5b                   	pop    %ebx
f0104239:	5d                   	pop    %ebp
f010423a:	c3                   	ret    

f010423b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010423b:	55                   	push   %ebp
f010423c:	89 e5                	mov    %esp,%ebp
f010423e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104241:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104245:	eb 07                	jmp    f010424e <strchr+0x13>
		if (*s == c)
f0104247:	38 ca                	cmp    %cl,%dl
f0104249:	74 0f                	je     f010425a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010424b:	83 c0 01             	add    $0x1,%eax
f010424e:	0f b6 10             	movzbl (%eax),%edx
f0104251:	84 d2                	test   %dl,%dl
f0104253:	75 f2                	jne    f0104247 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104255:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010425a:	5d                   	pop    %ebp
f010425b:	c3                   	ret    

f010425c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010425c:	55                   	push   %ebp
f010425d:	89 e5                	mov    %esp,%ebp
f010425f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104262:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104266:	eb 03                	jmp    f010426b <strfind+0xf>
f0104268:	83 c0 01             	add    $0x1,%eax
f010426b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010426e:	38 ca                	cmp    %cl,%dl
f0104270:	74 04                	je     f0104276 <strfind+0x1a>
f0104272:	84 d2                	test   %dl,%dl
f0104274:	75 f2                	jne    f0104268 <strfind+0xc>
			break;
	return (char *) s;
}
f0104276:	5d                   	pop    %ebp
f0104277:	c3                   	ret    

f0104278 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104278:	55                   	push   %ebp
f0104279:	89 e5                	mov    %esp,%ebp
f010427b:	57                   	push   %edi
f010427c:	56                   	push   %esi
f010427d:	53                   	push   %ebx
f010427e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104281:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104284:	85 c9                	test   %ecx,%ecx
f0104286:	74 36                	je     f01042be <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104288:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010428e:	75 28                	jne    f01042b8 <memset+0x40>
f0104290:	f6 c1 03             	test   $0x3,%cl
f0104293:	75 23                	jne    f01042b8 <memset+0x40>
		c &= 0xFF;
f0104295:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104299:	89 d3                	mov    %edx,%ebx
f010429b:	c1 e3 08             	shl    $0x8,%ebx
f010429e:	89 d6                	mov    %edx,%esi
f01042a0:	c1 e6 18             	shl    $0x18,%esi
f01042a3:	89 d0                	mov    %edx,%eax
f01042a5:	c1 e0 10             	shl    $0x10,%eax
f01042a8:	09 f0                	or     %esi,%eax
f01042aa:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01042ac:	89 d8                	mov    %ebx,%eax
f01042ae:	09 d0                	or     %edx,%eax
f01042b0:	c1 e9 02             	shr    $0x2,%ecx
f01042b3:	fc                   	cld    
f01042b4:	f3 ab                	rep stos %eax,%es:(%edi)
f01042b6:	eb 06                	jmp    f01042be <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01042b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01042bb:	fc                   	cld    
f01042bc:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01042be:	89 f8                	mov    %edi,%eax
f01042c0:	5b                   	pop    %ebx
f01042c1:	5e                   	pop    %esi
f01042c2:	5f                   	pop    %edi
f01042c3:	5d                   	pop    %ebp
f01042c4:	c3                   	ret    

f01042c5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01042c5:	55                   	push   %ebp
f01042c6:	89 e5                	mov    %esp,%ebp
f01042c8:	57                   	push   %edi
f01042c9:	56                   	push   %esi
f01042ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01042cd:	8b 75 0c             	mov    0xc(%ebp),%esi
f01042d0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01042d3:	39 c6                	cmp    %eax,%esi
f01042d5:	73 35                	jae    f010430c <memmove+0x47>
f01042d7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01042da:	39 d0                	cmp    %edx,%eax
f01042dc:	73 2e                	jae    f010430c <memmove+0x47>
		s += n;
		d += n;
f01042de:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01042e1:	89 d6                	mov    %edx,%esi
f01042e3:	09 fe                	or     %edi,%esi
f01042e5:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01042eb:	75 13                	jne    f0104300 <memmove+0x3b>
f01042ed:	f6 c1 03             	test   $0x3,%cl
f01042f0:	75 0e                	jne    f0104300 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01042f2:	83 ef 04             	sub    $0x4,%edi
f01042f5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01042f8:	c1 e9 02             	shr    $0x2,%ecx
f01042fb:	fd                   	std    
f01042fc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01042fe:	eb 09                	jmp    f0104309 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104300:	83 ef 01             	sub    $0x1,%edi
f0104303:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104306:	fd                   	std    
f0104307:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104309:	fc                   	cld    
f010430a:	eb 1d                	jmp    f0104329 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010430c:	89 f2                	mov    %esi,%edx
f010430e:	09 c2                	or     %eax,%edx
f0104310:	f6 c2 03             	test   $0x3,%dl
f0104313:	75 0f                	jne    f0104324 <memmove+0x5f>
f0104315:	f6 c1 03             	test   $0x3,%cl
f0104318:	75 0a                	jne    f0104324 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010431a:	c1 e9 02             	shr    $0x2,%ecx
f010431d:	89 c7                	mov    %eax,%edi
f010431f:	fc                   	cld    
f0104320:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104322:	eb 05                	jmp    f0104329 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104324:	89 c7                	mov    %eax,%edi
f0104326:	fc                   	cld    
f0104327:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104329:	5e                   	pop    %esi
f010432a:	5f                   	pop    %edi
f010432b:	5d                   	pop    %ebp
f010432c:	c3                   	ret    

f010432d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010432d:	55                   	push   %ebp
f010432e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104330:	ff 75 10             	pushl  0x10(%ebp)
f0104333:	ff 75 0c             	pushl  0xc(%ebp)
f0104336:	ff 75 08             	pushl  0x8(%ebp)
f0104339:	e8 87 ff ff ff       	call   f01042c5 <memmove>
}
f010433e:	c9                   	leave  
f010433f:	c3                   	ret    

f0104340 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104340:	55                   	push   %ebp
f0104341:	89 e5                	mov    %esp,%ebp
f0104343:	56                   	push   %esi
f0104344:	53                   	push   %ebx
f0104345:	8b 45 08             	mov    0x8(%ebp),%eax
f0104348:	8b 55 0c             	mov    0xc(%ebp),%edx
f010434b:	89 c6                	mov    %eax,%esi
f010434d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104350:	eb 1a                	jmp    f010436c <memcmp+0x2c>
		if (*s1 != *s2)
f0104352:	0f b6 08             	movzbl (%eax),%ecx
f0104355:	0f b6 1a             	movzbl (%edx),%ebx
f0104358:	38 d9                	cmp    %bl,%cl
f010435a:	74 0a                	je     f0104366 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010435c:	0f b6 c1             	movzbl %cl,%eax
f010435f:	0f b6 db             	movzbl %bl,%ebx
f0104362:	29 d8                	sub    %ebx,%eax
f0104364:	eb 0f                	jmp    f0104375 <memcmp+0x35>
		s1++, s2++;
f0104366:	83 c0 01             	add    $0x1,%eax
f0104369:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010436c:	39 f0                	cmp    %esi,%eax
f010436e:	75 e2                	jne    f0104352 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104370:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104375:	5b                   	pop    %ebx
f0104376:	5e                   	pop    %esi
f0104377:	5d                   	pop    %ebp
f0104378:	c3                   	ret    

f0104379 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104379:	55                   	push   %ebp
f010437a:	89 e5                	mov    %esp,%ebp
f010437c:	53                   	push   %ebx
f010437d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104380:	89 c1                	mov    %eax,%ecx
f0104382:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104385:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104389:	eb 0a                	jmp    f0104395 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010438b:	0f b6 10             	movzbl (%eax),%edx
f010438e:	39 da                	cmp    %ebx,%edx
f0104390:	74 07                	je     f0104399 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104392:	83 c0 01             	add    $0x1,%eax
f0104395:	39 c8                	cmp    %ecx,%eax
f0104397:	72 f2                	jb     f010438b <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104399:	5b                   	pop    %ebx
f010439a:	5d                   	pop    %ebp
f010439b:	c3                   	ret    

f010439c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010439c:	55                   	push   %ebp
f010439d:	89 e5                	mov    %esp,%ebp
f010439f:	57                   	push   %edi
f01043a0:	56                   	push   %esi
f01043a1:	53                   	push   %ebx
f01043a2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01043a5:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01043a8:	eb 03                	jmp    f01043ad <strtol+0x11>
		s++;
f01043aa:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01043ad:	0f b6 01             	movzbl (%ecx),%eax
f01043b0:	3c 20                	cmp    $0x20,%al
f01043b2:	74 f6                	je     f01043aa <strtol+0xe>
f01043b4:	3c 09                	cmp    $0x9,%al
f01043b6:	74 f2                	je     f01043aa <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01043b8:	3c 2b                	cmp    $0x2b,%al
f01043ba:	75 0a                	jne    f01043c6 <strtol+0x2a>
		s++;
f01043bc:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01043bf:	bf 00 00 00 00       	mov    $0x0,%edi
f01043c4:	eb 11                	jmp    f01043d7 <strtol+0x3b>
f01043c6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01043cb:	3c 2d                	cmp    $0x2d,%al
f01043cd:	75 08                	jne    f01043d7 <strtol+0x3b>
		s++, neg = 1;
f01043cf:	83 c1 01             	add    $0x1,%ecx
f01043d2:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01043d7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01043dd:	75 15                	jne    f01043f4 <strtol+0x58>
f01043df:	80 39 30             	cmpb   $0x30,(%ecx)
f01043e2:	75 10                	jne    f01043f4 <strtol+0x58>
f01043e4:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01043e8:	75 7c                	jne    f0104466 <strtol+0xca>
		s += 2, base = 16;
f01043ea:	83 c1 02             	add    $0x2,%ecx
f01043ed:	bb 10 00 00 00       	mov    $0x10,%ebx
f01043f2:	eb 16                	jmp    f010440a <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01043f4:	85 db                	test   %ebx,%ebx
f01043f6:	75 12                	jne    f010440a <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01043f8:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01043fd:	80 39 30             	cmpb   $0x30,(%ecx)
f0104400:	75 08                	jne    f010440a <strtol+0x6e>
		s++, base = 8;
f0104402:	83 c1 01             	add    $0x1,%ecx
f0104405:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010440a:	b8 00 00 00 00       	mov    $0x0,%eax
f010440f:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104412:	0f b6 11             	movzbl (%ecx),%edx
f0104415:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104418:	89 f3                	mov    %esi,%ebx
f010441a:	80 fb 09             	cmp    $0x9,%bl
f010441d:	77 08                	ja     f0104427 <strtol+0x8b>
			dig = *s - '0';
f010441f:	0f be d2             	movsbl %dl,%edx
f0104422:	83 ea 30             	sub    $0x30,%edx
f0104425:	eb 22                	jmp    f0104449 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104427:	8d 72 9f             	lea    -0x61(%edx),%esi
f010442a:	89 f3                	mov    %esi,%ebx
f010442c:	80 fb 19             	cmp    $0x19,%bl
f010442f:	77 08                	ja     f0104439 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104431:	0f be d2             	movsbl %dl,%edx
f0104434:	83 ea 57             	sub    $0x57,%edx
f0104437:	eb 10                	jmp    f0104449 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104439:	8d 72 bf             	lea    -0x41(%edx),%esi
f010443c:	89 f3                	mov    %esi,%ebx
f010443e:	80 fb 19             	cmp    $0x19,%bl
f0104441:	77 16                	ja     f0104459 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104443:	0f be d2             	movsbl %dl,%edx
f0104446:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104449:	3b 55 10             	cmp    0x10(%ebp),%edx
f010444c:	7d 0b                	jge    f0104459 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010444e:	83 c1 01             	add    $0x1,%ecx
f0104451:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104455:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104457:	eb b9                	jmp    f0104412 <strtol+0x76>

	if (endptr)
f0104459:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010445d:	74 0d                	je     f010446c <strtol+0xd0>
		*endptr = (char *) s;
f010445f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104462:	89 0e                	mov    %ecx,(%esi)
f0104464:	eb 06                	jmp    f010446c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104466:	85 db                	test   %ebx,%ebx
f0104468:	74 98                	je     f0104402 <strtol+0x66>
f010446a:	eb 9e                	jmp    f010440a <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010446c:	89 c2                	mov    %eax,%edx
f010446e:	f7 da                	neg    %edx
f0104470:	85 ff                	test   %edi,%edi
f0104472:	0f 45 c2             	cmovne %edx,%eax
}
f0104475:	5b                   	pop    %ebx
f0104476:	5e                   	pop    %esi
f0104477:	5f                   	pop    %edi
f0104478:	5d                   	pop    %ebp
f0104479:	c3                   	ret    
f010447a:	66 90                	xchg   %ax,%ax
f010447c:	66 90                	xchg   %ax,%ax
f010447e:	66 90                	xchg   %ax,%ax

f0104480 <__udivdi3>:
f0104480:	55                   	push   %ebp
f0104481:	57                   	push   %edi
f0104482:	56                   	push   %esi
f0104483:	53                   	push   %ebx
f0104484:	83 ec 1c             	sub    $0x1c,%esp
f0104487:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010448b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010448f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104493:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104497:	85 f6                	test   %esi,%esi
f0104499:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010449d:	89 ca                	mov    %ecx,%edx
f010449f:	89 f8                	mov    %edi,%eax
f01044a1:	75 3d                	jne    f01044e0 <__udivdi3+0x60>
f01044a3:	39 cf                	cmp    %ecx,%edi
f01044a5:	0f 87 c5 00 00 00    	ja     f0104570 <__udivdi3+0xf0>
f01044ab:	85 ff                	test   %edi,%edi
f01044ad:	89 fd                	mov    %edi,%ebp
f01044af:	75 0b                	jne    f01044bc <__udivdi3+0x3c>
f01044b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01044b6:	31 d2                	xor    %edx,%edx
f01044b8:	f7 f7                	div    %edi
f01044ba:	89 c5                	mov    %eax,%ebp
f01044bc:	89 c8                	mov    %ecx,%eax
f01044be:	31 d2                	xor    %edx,%edx
f01044c0:	f7 f5                	div    %ebp
f01044c2:	89 c1                	mov    %eax,%ecx
f01044c4:	89 d8                	mov    %ebx,%eax
f01044c6:	89 cf                	mov    %ecx,%edi
f01044c8:	f7 f5                	div    %ebp
f01044ca:	89 c3                	mov    %eax,%ebx
f01044cc:	89 d8                	mov    %ebx,%eax
f01044ce:	89 fa                	mov    %edi,%edx
f01044d0:	83 c4 1c             	add    $0x1c,%esp
f01044d3:	5b                   	pop    %ebx
f01044d4:	5e                   	pop    %esi
f01044d5:	5f                   	pop    %edi
f01044d6:	5d                   	pop    %ebp
f01044d7:	c3                   	ret    
f01044d8:	90                   	nop
f01044d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01044e0:	39 ce                	cmp    %ecx,%esi
f01044e2:	77 74                	ja     f0104558 <__udivdi3+0xd8>
f01044e4:	0f bd fe             	bsr    %esi,%edi
f01044e7:	83 f7 1f             	xor    $0x1f,%edi
f01044ea:	0f 84 98 00 00 00    	je     f0104588 <__udivdi3+0x108>
f01044f0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01044f5:	89 f9                	mov    %edi,%ecx
f01044f7:	89 c5                	mov    %eax,%ebp
f01044f9:	29 fb                	sub    %edi,%ebx
f01044fb:	d3 e6                	shl    %cl,%esi
f01044fd:	89 d9                	mov    %ebx,%ecx
f01044ff:	d3 ed                	shr    %cl,%ebp
f0104501:	89 f9                	mov    %edi,%ecx
f0104503:	d3 e0                	shl    %cl,%eax
f0104505:	09 ee                	or     %ebp,%esi
f0104507:	89 d9                	mov    %ebx,%ecx
f0104509:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010450d:	89 d5                	mov    %edx,%ebp
f010450f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104513:	d3 ed                	shr    %cl,%ebp
f0104515:	89 f9                	mov    %edi,%ecx
f0104517:	d3 e2                	shl    %cl,%edx
f0104519:	89 d9                	mov    %ebx,%ecx
f010451b:	d3 e8                	shr    %cl,%eax
f010451d:	09 c2                	or     %eax,%edx
f010451f:	89 d0                	mov    %edx,%eax
f0104521:	89 ea                	mov    %ebp,%edx
f0104523:	f7 f6                	div    %esi
f0104525:	89 d5                	mov    %edx,%ebp
f0104527:	89 c3                	mov    %eax,%ebx
f0104529:	f7 64 24 0c          	mull   0xc(%esp)
f010452d:	39 d5                	cmp    %edx,%ebp
f010452f:	72 10                	jb     f0104541 <__udivdi3+0xc1>
f0104531:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104535:	89 f9                	mov    %edi,%ecx
f0104537:	d3 e6                	shl    %cl,%esi
f0104539:	39 c6                	cmp    %eax,%esi
f010453b:	73 07                	jae    f0104544 <__udivdi3+0xc4>
f010453d:	39 d5                	cmp    %edx,%ebp
f010453f:	75 03                	jne    f0104544 <__udivdi3+0xc4>
f0104541:	83 eb 01             	sub    $0x1,%ebx
f0104544:	31 ff                	xor    %edi,%edi
f0104546:	89 d8                	mov    %ebx,%eax
f0104548:	89 fa                	mov    %edi,%edx
f010454a:	83 c4 1c             	add    $0x1c,%esp
f010454d:	5b                   	pop    %ebx
f010454e:	5e                   	pop    %esi
f010454f:	5f                   	pop    %edi
f0104550:	5d                   	pop    %ebp
f0104551:	c3                   	ret    
f0104552:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104558:	31 ff                	xor    %edi,%edi
f010455a:	31 db                	xor    %ebx,%ebx
f010455c:	89 d8                	mov    %ebx,%eax
f010455e:	89 fa                	mov    %edi,%edx
f0104560:	83 c4 1c             	add    $0x1c,%esp
f0104563:	5b                   	pop    %ebx
f0104564:	5e                   	pop    %esi
f0104565:	5f                   	pop    %edi
f0104566:	5d                   	pop    %ebp
f0104567:	c3                   	ret    
f0104568:	90                   	nop
f0104569:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104570:	89 d8                	mov    %ebx,%eax
f0104572:	f7 f7                	div    %edi
f0104574:	31 ff                	xor    %edi,%edi
f0104576:	89 c3                	mov    %eax,%ebx
f0104578:	89 d8                	mov    %ebx,%eax
f010457a:	89 fa                	mov    %edi,%edx
f010457c:	83 c4 1c             	add    $0x1c,%esp
f010457f:	5b                   	pop    %ebx
f0104580:	5e                   	pop    %esi
f0104581:	5f                   	pop    %edi
f0104582:	5d                   	pop    %ebp
f0104583:	c3                   	ret    
f0104584:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104588:	39 ce                	cmp    %ecx,%esi
f010458a:	72 0c                	jb     f0104598 <__udivdi3+0x118>
f010458c:	31 db                	xor    %ebx,%ebx
f010458e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104592:	0f 87 34 ff ff ff    	ja     f01044cc <__udivdi3+0x4c>
f0104598:	bb 01 00 00 00       	mov    $0x1,%ebx
f010459d:	e9 2a ff ff ff       	jmp    f01044cc <__udivdi3+0x4c>
f01045a2:	66 90                	xchg   %ax,%ax
f01045a4:	66 90                	xchg   %ax,%ax
f01045a6:	66 90                	xchg   %ax,%ax
f01045a8:	66 90                	xchg   %ax,%ax
f01045aa:	66 90                	xchg   %ax,%ax
f01045ac:	66 90                	xchg   %ax,%ax
f01045ae:	66 90                	xchg   %ax,%ax

f01045b0 <__umoddi3>:
f01045b0:	55                   	push   %ebp
f01045b1:	57                   	push   %edi
f01045b2:	56                   	push   %esi
f01045b3:	53                   	push   %ebx
f01045b4:	83 ec 1c             	sub    $0x1c,%esp
f01045b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01045bb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01045bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01045c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01045c7:	85 d2                	test   %edx,%edx
f01045c9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01045cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01045d1:	89 f3                	mov    %esi,%ebx
f01045d3:	89 3c 24             	mov    %edi,(%esp)
f01045d6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01045da:	75 1c                	jne    f01045f8 <__umoddi3+0x48>
f01045dc:	39 f7                	cmp    %esi,%edi
f01045de:	76 50                	jbe    f0104630 <__umoddi3+0x80>
f01045e0:	89 c8                	mov    %ecx,%eax
f01045e2:	89 f2                	mov    %esi,%edx
f01045e4:	f7 f7                	div    %edi
f01045e6:	89 d0                	mov    %edx,%eax
f01045e8:	31 d2                	xor    %edx,%edx
f01045ea:	83 c4 1c             	add    $0x1c,%esp
f01045ed:	5b                   	pop    %ebx
f01045ee:	5e                   	pop    %esi
f01045ef:	5f                   	pop    %edi
f01045f0:	5d                   	pop    %ebp
f01045f1:	c3                   	ret    
f01045f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01045f8:	39 f2                	cmp    %esi,%edx
f01045fa:	89 d0                	mov    %edx,%eax
f01045fc:	77 52                	ja     f0104650 <__umoddi3+0xa0>
f01045fe:	0f bd ea             	bsr    %edx,%ebp
f0104601:	83 f5 1f             	xor    $0x1f,%ebp
f0104604:	75 5a                	jne    f0104660 <__umoddi3+0xb0>
f0104606:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010460a:	0f 82 e0 00 00 00    	jb     f01046f0 <__umoddi3+0x140>
f0104610:	39 0c 24             	cmp    %ecx,(%esp)
f0104613:	0f 86 d7 00 00 00    	jbe    f01046f0 <__umoddi3+0x140>
f0104619:	8b 44 24 08          	mov    0x8(%esp),%eax
f010461d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104621:	83 c4 1c             	add    $0x1c,%esp
f0104624:	5b                   	pop    %ebx
f0104625:	5e                   	pop    %esi
f0104626:	5f                   	pop    %edi
f0104627:	5d                   	pop    %ebp
f0104628:	c3                   	ret    
f0104629:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104630:	85 ff                	test   %edi,%edi
f0104632:	89 fd                	mov    %edi,%ebp
f0104634:	75 0b                	jne    f0104641 <__umoddi3+0x91>
f0104636:	b8 01 00 00 00       	mov    $0x1,%eax
f010463b:	31 d2                	xor    %edx,%edx
f010463d:	f7 f7                	div    %edi
f010463f:	89 c5                	mov    %eax,%ebp
f0104641:	89 f0                	mov    %esi,%eax
f0104643:	31 d2                	xor    %edx,%edx
f0104645:	f7 f5                	div    %ebp
f0104647:	89 c8                	mov    %ecx,%eax
f0104649:	f7 f5                	div    %ebp
f010464b:	89 d0                	mov    %edx,%eax
f010464d:	eb 99                	jmp    f01045e8 <__umoddi3+0x38>
f010464f:	90                   	nop
f0104650:	89 c8                	mov    %ecx,%eax
f0104652:	89 f2                	mov    %esi,%edx
f0104654:	83 c4 1c             	add    $0x1c,%esp
f0104657:	5b                   	pop    %ebx
f0104658:	5e                   	pop    %esi
f0104659:	5f                   	pop    %edi
f010465a:	5d                   	pop    %ebp
f010465b:	c3                   	ret    
f010465c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104660:	8b 34 24             	mov    (%esp),%esi
f0104663:	bf 20 00 00 00       	mov    $0x20,%edi
f0104668:	89 e9                	mov    %ebp,%ecx
f010466a:	29 ef                	sub    %ebp,%edi
f010466c:	d3 e0                	shl    %cl,%eax
f010466e:	89 f9                	mov    %edi,%ecx
f0104670:	89 f2                	mov    %esi,%edx
f0104672:	d3 ea                	shr    %cl,%edx
f0104674:	89 e9                	mov    %ebp,%ecx
f0104676:	09 c2                	or     %eax,%edx
f0104678:	89 d8                	mov    %ebx,%eax
f010467a:	89 14 24             	mov    %edx,(%esp)
f010467d:	89 f2                	mov    %esi,%edx
f010467f:	d3 e2                	shl    %cl,%edx
f0104681:	89 f9                	mov    %edi,%ecx
f0104683:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104687:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010468b:	d3 e8                	shr    %cl,%eax
f010468d:	89 e9                	mov    %ebp,%ecx
f010468f:	89 c6                	mov    %eax,%esi
f0104691:	d3 e3                	shl    %cl,%ebx
f0104693:	89 f9                	mov    %edi,%ecx
f0104695:	89 d0                	mov    %edx,%eax
f0104697:	d3 e8                	shr    %cl,%eax
f0104699:	89 e9                	mov    %ebp,%ecx
f010469b:	09 d8                	or     %ebx,%eax
f010469d:	89 d3                	mov    %edx,%ebx
f010469f:	89 f2                	mov    %esi,%edx
f01046a1:	f7 34 24             	divl   (%esp)
f01046a4:	89 d6                	mov    %edx,%esi
f01046a6:	d3 e3                	shl    %cl,%ebx
f01046a8:	f7 64 24 04          	mull   0x4(%esp)
f01046ac:	39 d6                	cmp    %edx,%esi
f01046ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01046b2:	89 d1                	mov    %edx,%ecx
f01046b4:	89 c3                	mov    %eax,%ebx
f01046b6:	72 08                	jb     f01046c0 <__umoddi3+0x110>
f01046b8:	75 11                	jne    f01046cb <__umoddi3+0x11b>
f01046ba:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01046be:	73 0b                	jae    f01046cb <__umoddi3+0x11b>
f01046c0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01046c4:	1b 14 24             	sbb    (%esp),%edx
f01046c7:	89 d1                	mov    %edx,%ecx
f01046c9:	89 c3                	mov    %eax,%ebx
f01046cb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01046cf:	29 da                	sub    %ebx,%edx
f01046d1:	19 ce                	sbb    %ecx,%esi
f01046d3:	89 f9                	mov    %edi,%ecx
f01046d5:	89 f0                	mov    %esi,%eax
f01046d7:	d3 e0                	shl    %cl,%eax
f01046d9:	89 e9                	mov    %ebp,%ecx
f01046db:	d3 ea                	shr    %cl,%edx
f01046dd:	89 e9                	mov    %ebp,%ecx
f01046df:	d3 ee                	shr    %cl,%esi
f01046e1:	09 d0                	or     %edx,%eax
f01046e3:	89 f2                	mov    %esi,%edx
f01046e5:	83 c4 1c             	add    $0x1c,%esp
f01046e8:	5b                   	pop    %ebx
f01046e9:	5e                   	pop    %esi
f01046ea:	5f                   	pop    %edi
f01046eb:	5d                   	pop    %ebp
f01046ec:	c3                   	ret    
f01046ed:	8d 76 00             	lea    0x0(%esi),%esi
f01046f0:	29 f9                	sub    %edi,%ecx
f01046f2:	19 d6                	sbb    %edx,%esi
f01046f4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01046f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01046fc:	e9 18 ff ff ff       	jmp    f0104619 <__umoddi3+0x69>
