
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 32 31 00 00       	call   f010318f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 36 10 f0       	push   $0xf0103640
f010006f:	e8 32 26 00 00       	call   f01026a6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 0a 0f 00 00       	call   f0100f83 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 97 06 00 00       	call   f010071d <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 5b 36 10 f0       	push   $0xf010365b
f01000b5:	e8 ec 25 00 00       	call   f01026a6 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 bc 25 00 00       	call   f0102680 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 1c 45 10 f0 	movl   $0xf010451c,(%esp)
f01000cb:	e8 d6 25 00 00       	call   f01026a6 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 40 06 00 00       	call   f010071d <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 73 36 10 f0       	push   $0xf0103673
f01000f7:	e8 aa 25 00 00       	call   f01026a6 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 78 25 00 00       	call   f0102680 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 1c 45 10 f0 	movl   $0xf010451c,(%esp)
f010010f:	e8 92 25 00 00       	call   f01026a6 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 e0 37 10 f0 	movzbl -0xfefc820(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 e0 37 10 f0 	movzbl -0xfefc820(%edx),%eax
f0100211:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f0100217:	0f b6 8a e0 36 10 f0 	movzbl -0xfefc920(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d c0 36 10 f0 	mov    -0xfefc940(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 8d 36 10 f0       	push   $0xf010368d
f010026d:	e8 34 24 00 00       	call   f01026a6 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 bb 2d 00 00       	call   f01031dc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004c3:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004d4:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 99 36 10 f0       	push   $0xf0103699
f01005f0:	e8 b1 20 00 00       	call   f01026a6 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 e0 38 10 f0       	push   $0xf01038e0
f0100636:	68 fe 38 10 f0       	push   $0xf01038fe
f010063b:	68 03 39 10 f0       	push   $0xf0103903
f0100640:	e8 61 20 00 00       	call   f01026a6 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 6c 39 10 f0       	push   $0xf010396c
f010064d:	68 0c 39 10 f0       	push   $0xf010390c
f0100652:	68 03 39 10 f0       	push   $0xf0103903
f0100657:	e8 4a 20 00 00       	call   f01026a6 <cprintf>
	return 0;
}
f010065c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100661:	c9                   	leave  
f0100662:	c3                   	ret    

f0100663 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100663:	55                   	push   %ebp
f0100664:	89 e5                	mov    %esp,%ebp
f0100666:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100669:	68 15 39 10 f0       	push   $0xf0103915
f010066e:	e8 33 20 00 00       	call   f01026a6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 94 39 10 f0       	push   $0xf0103994
f0100680:	e8 21 20 00 00       	call   f01026a6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 bc 39 10 f0       	push   $0xf01039bc
f0100697:	e8 0a 20 00 00       	call   f01026a6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 21 36 10 00       	push   $0x103621
f01006a4:	68 21 36 10 f0       	push   $0xf0103621
f01006a9:	68 e0 39 10 f0       	push   $0xf01039e0
f01006ae:	e8 f3 1f 00 00       	call   f01026a6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 63 11 00       	push   $0x116300
f01006bb:	68 00 63 11 f0       	push   $0xf0116300
f01006c0:	68 04 3a 10 f0       	push   $0xf0103a04
f01006c5:	e8 dc 1f 00 00       	call   f01026a6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 70 69 11 00       	push   $0x116970
f01006d2:	68 70 69 11 f0       	push   $0xf0116970
f01006d7:	68 28 3a 10 f0       	push   $0xf0103a28
f01006dc:	e8 c5 1f 00 00       	call   f01026a6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
f01006e6:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006eb:	83 c4 08             	add    $0x8,%esp
f01006ee:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	0f 48 c2             	cmovs  %edx,%eax
f01006fe:	c1 f8 0a             	sar    $0xa,%eax
f0100701:	50                   	push   %eax
f0100702:	68 4c 3a 10 f0       	push   $0xf0103a4c
f0100707:	e8 9a 1f 00 00       	call   f01026a6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100716:	b8 00 00 00 00       	mov    $0x0,%eax
f010071b:	5d                   	pop    %ebp
f010071c:	c3                   	ret    

f010071d <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010071d:	55                   	push   %ebp
f010071e:	89 e5                	mov    %esp,%ebp
f0100720:	57                   	push   %edi
f0100721:	56                   	push   %esi
f0100722:	53                   	push   %ebx
f0100723:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100726:	68 78 3a 10 f0       	push   $0xf0103a78
f010072b:	e8 76 1f 00 00       	call   f01026a6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100730:	c7 04 24 9c 3a 10 f0 	movl   $0xf0103a9c,(%esp)
f0100737:	e8 6a 1f 00 00       	call   f01026a6 <cprintf>
f010073c:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010073f:	83 ec 0c             	sub    $0xc,%esp
f0100742:	68 2e 39 10 f0       	push   $0xf010392e
f0100747:	e8 ec 27 00 00       	call   f0102f38 <readline>
f010074c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010074e:	83 c4 10             	add    $0x10,%esp
f0100751:	85 c0                	test   %eax,%eax
f0100753:	74 ea                	je     f010073f <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100755:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010075c:	be 00 00 00 00       	mov    $0x0,%esi
f0100761:	eb 0a                	jmp    f010076d <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100763:	c6 03 00             	movb   $0x0,(%ebx)
f0100766:	89 f7                	mov    %esi,%edi
f0100768:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010076b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010076d:	0f b6 03             	movzbl (%ebx),%eax
f0100770:	84 c0                	test   %al,%al
f0100772:	74 63                	je     f01007d7 <monitor+0xba>
f0100774:	83 ec 08             	sub    $0x8,%esp
f0100777:	0f be c0             	movsbl %al,%eax
f010077a:	50                   	push   %eax
f010077b:	68 32 39 10 f0       	push   $0xf0103932
f0100780:	e8 cd 29 00 00       	call   f0103152 <strchr>
f0100785:	83 c4 10             	add    $0x10,%esp
f0100788:	85 c0                	test   %eax,%eax
f010078a:	75 d7                	jne    f0100763 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010078c:	80 3b 00             	cmpb   $0x0,(%ebx)
f010078f:	74 46                	je     f01007d7 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100791:	83 fe 0f             	cmp    $0xf,%esi
f0100794:	75 14                	jne    f01007aa <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100796:	83 ec 08             	sub    $0x8,%esp
f0100799:	6a 10                	push   $0x10
f010079b:	68 37 39 10 f0       	push   $0xf0103937
f01007a0:	e8 01 1f 00 00       	call   f01026a6 <cprintf>
f01007a5:	83 c4 10             	add    $0x10,%esp
f01007a8:	eb 95                	jmp    f010073f <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007aa:	8d 7e 01             	lea    0x1(%esi),%edi
f01007ad:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007b1:	eb 03                	jmp    f01007b6 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007b3:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007b6:	0f b6 03             	movzbl (%ebx),%eax
f01007b9:	84 c0                	test   %al,%al
f01007bb:	74 ae                	je     f010076b <monitor+0x4e>
f01007bd:	83 ec 08             	sub    $0x8,%esp
f01007c0:	0f be c0             	movsbl %al,%eax
f01007c3:	50                   	push   %eax
f01007c4:	68 32 39 10 f0       	push   $0xf0103932
f01007c9:	e8 84 29 00 00       	call   f0103152 <strchr>
f01007ce:	83 c4 10             	add    $0x10,%esp
f01007d1:	85 c0                	test   %eax,%eax
f01007d3:	74 de                	je     f01007b3 <monitor+0x96>
f01007d5:	eb 94                	jmp    f010076b <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01007d7:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007de:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007df:	85 f6                	test   %esi,%esi
f01007e1:	0f 84 58 ff ff ff    	je     f010073f <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007e7:	83 ec 08             	sub    $0x8,%esp
f01007ea:	68 fe 38 10 f0       	push   $0xf01038fe
f01007ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01007f2:	e8 fd 28 00 00       	call   f01030f4 <strcmp>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 1e                	je     f010081c <monitor+0xff>
f01007fe:	83 ec 08             	sub    $0x8,%esp
f0100801:	68 0c 39 10 f0       	push   $0xf010390c
f0100806:	ff 75 a8             	pushl  -0x58(%ebp)
f0100809:	e8 e6 28 00 00       	call   f01030f4 <strcmp>
f010080e:	83 c4 10             	add    $0x10,%esp
f0100811:	85 c0                	test   %eax,%eax
f0100813:	75 2f                	jne    f0100844 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100815:	b8 01 00 00 00       	mov    $0x1,%eax
f010081a:	eb 05                	jmp    f0100821 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f010081c:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100821:	83 ec 04             	sub    $0x4,%esp
f0100824:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100827:	01 d0                	add    %edx,%eax
f0100829:	ff 75 08             	pushl  0x8(%ebp)
f010082c:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010082f:	51                   	push   %ecx
f0100830:	56                   	push   %esi
f0100831:	ff 14 85 cc 3a 10 f0 	call   *-0xfefc534(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100838:	83 c4 10             	add    $0x10,%esp
f010083b:	85 c0                	test   %eax,%eax
f010083d:	78 1d                	js     f010085c <monitor+0x13f>
f010083f:	e9 fb fe ff ff       	jmp    f010073f <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100844:	83 ec 08             	sub    $0x8,%esp
f0100847:	ff 75 a8             	pushl  -0x58(%ebp)
f010084a:	68 54 39 10 f0       	push   $0xf0103954
f010084f:	e8 52 1e 00 00       	call   f01026a6 <cprintf>
f0100854:	83 c4 10             	add    $0x10,%esp
f0100857:	e9 e3 fe ff ff       	jmp    f010073f <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010085c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010085f:	5b                   	pop    %ebx
f0100860:	5e                   	pop    %esi
f0100861:	5f                   	pop    %edi
f0100862:	5d                   	pop    %ebp
f0100863:	c3                   	ret    

f0100864 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *  
boot_alloc(uint32_t n)  
{  
f0100864:	55                   	push   %ebp
f0100865:	89 e5                	mov    %esp,%ebp
    static char *nextfree;  // virtual address of next byte of free memory  
    char *result;  
  
    if (!nextfree) {  
f0100867:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f010086e:	75 11                	jne    f0100881 <boot_alloc+0x1d>
        extern char end[];//end points to the end of the kernel's bss segment:  
        nextfree = ROUNDUP((char *) end, PGSIZE);  
f0100870:	ba 6f 79 11 f0       	mov    $0xf011796f,%edx
f0100875:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010087b:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
    }  
    if(n==0)  
f0100881:	85 c0                	test   %eax,%eax
f0100883:	75 07                	jne    f010088c <boot_alloc+0x28>
        return nextfree;  
f0100885:	a1 38 65 11 f0       	mov    0xf0116538,%eax
f010088a:	eb 19                	jmp    f01008a5 <boot_alloc+0x41>
    result = nextfree;  
f010088c:	8b 15 38 65 11 f0    	mov    0xf0116538,%edx
    nextfree += n;  
    nextfree = ROUNDUP( (char*)nextfree, PGSIZE);  
f0100892:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100899:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010089e:	a3 38 65 11 f0       	mov    %eax,0xf0116538
    return result;  
f01008a3:	89 d0                	mov    %edx,%eax
}
f01008a5:	5d                   	pop    %ebp
f01008a6:	c3                   	ret    

f01008a7 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008a7:	55                   	push   %ebp
f01008a8:	89 e5                	mov    %esp,%ebp
f01008aa:	56                   	push   %esi
f01008ab:	53                   	push   %ebx
f01008ac:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008ae:	83 ec 0c             	sub    $0xc,%esp
f01008b1:	50                   	push   %eax
f01008b2:	e8 88 1d 00 00       	call   f010263f <mc146818_read>
f01008b7:	89 c6                	mov    %eax,%esi
f01008b9:	83 c3 01             	add    $0x1,%ebx
f01008bc:	89 1c 24             	mov    %ebx,(%esp)
f01008bf:	e8 7b 1d 00 00       	call   f010263f <mc146818_read>
f01008c4:	c1 e0 08             	shl    $0x8,%eax
f01008c7:	09 f0                	or     %esi,%eax
}
f01008c9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008cc:	5b                   	pop    %ebx
f01008cd:	5e                   	pop    %esi
f01008ce:	5d                   	pop    %ebp
f01008cf:	c3                   	ret    

f01008d0 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01008d0:	89 d1                	mov    %edx,%ecx
f01008d2:	c1 e9 16             	shr    $0x16,%ecx
f01008d5:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01008d8:	a8 01                	test   $0x1,%al
f01008da:	74 52                	je     f010092e <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01008dc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008e1:	89 c1                	mov    %eax,%ecx
f01008e3:	c1 e9 0c             	shr    $0xc,%ecx
f01008e6:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f01008ec:	72 1b                	jb     f0100909 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01008ee:	55                   	push   %ebp
f01008ef:	89 e5                	mov    %esp,%ebp
f01008f1:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01008f4:	50                   	push   %eax
f01008f5:	68 dc 3a 10 f0       	push   $0xf0103adc
f01008fa:	68 c8 02 00 00       	push   $0x2c8
f01008ff:	68 54 42 10 f0       	push   $0xf0104254
f0100904:	e8 82 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100909:	c1 ea 0c             	shr    $0xc,%edx
f010090c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100912:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100919:	89 c2                	mov    %eax,%edx
f010091b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010091e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100923:	85 d2                	test   %edx,%edx
f0100925:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010092a:	0f 44 c2             	cmove  %edx,%eax
f010092d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f010092e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100933:	c3                   	ret    

f0100934 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100934:	55                   	push   %ebp
f0100935:	89 e5                	mov    %esp,%ebp
f0100937:	57                   	push   %edi
f0100938:	56                   	push   %esi
f0100939:	53                   	push   %ebx
f010093a:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010093d:	84 c0                	test   %al,%al
f010093f:	0f 85 81 02 00 00    	jne    f0100bc6 <check_page_free_list+0x292>
f0100945:	e9 8e 02 00 00       	jmp    f0100bd8 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f010094a:	83 ec 04             	sub    $0x4,%esp
f010094d:	68 00 3b 10 f0       	push   $0xf0103b00
f0100952:	68 09 02 00 00       	push   $0x209
f0100957:	68 54 42 10 f0       	push   $0xf0104254
f010095c:	e8 2a f7 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100961:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100964:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100967:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010096a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f010096d:	89 c2                	mov    %eax,%edx
f010096f:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0100975:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f010097b:	0f 95 c2             	setne  %dl
f010097e:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100981:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100985:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100987:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f010098b:	8b 00                	mov    (%eax),%eax
f010098d:	85 c0                	test   %eax,%eax
f010098f:	75 dc                	jne    f010096d <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100991:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100994:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f010099a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010099d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009a0:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009a2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009a5:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009aa:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009af:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f01009b5:	eb 53                	jmp    f0100a0a <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009b7:	89 d8                	mov    %ebx,%eax
f01009b9:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01009bf:	c1 f8 03             	sar    $0x3,%eax
f01009c2:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01009c5:	89 c2                	mov    %eax,%edx
f01009c7:	c1 ea 16             	shr    $0x16,%edx
f01009ca:	39 f2                	cmp    %esi,%edx
f01009cc:	73 3a                	jae    f0100a08 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009ce:	89 c2                	mov    %eax,%edx
f01009d0:	c1 ea 0c             	shr    $0xc,%edx
f01009d3:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01009d9:	72 12                	jb     f01009ed <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009db:	50                   	push   %eax
f01009dc:	68 dc 3a 10 f0       	push   $0xf0103adc
f01009e1:	6a 52                	push   $0x52
f01009e3:	68 60 42 10 f0       	push   $0xf0104260
f01009e8:	e8 9e f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f01009ed:	83 ec 04             	sub    $0x4,%esp
f01009f0:	68 80 00 00 00       	push   $0x80
f01009f5:	68 97 00 00 00       	push   $0x97
f01009fa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01009ff:	50                   	push   %eax
f0100a00:	e8 8a 27 00 00       	call   f010318f <memset>
f0100a05:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a08:	8b 1b                	mov    (%ebx),%ebx
f0100a0a:	85 db                	test   %ebx,%ebx
f0100a0c:	75 a9                	jne    f01009b7 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a0e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a13:	e8 4c fe ff ff       	call   f0100864 <boot_alloc>
f0100a18:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a1b:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a21:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f0100a27:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0100a2c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a2f:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a32:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a35:	be 00 00 00 00       	mov    $0x0,%esi
f0100a3a:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a3d:	e9 30 01 00 00       	jmp    f0100b72 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a42:	39 ca                	cmp    %ecx,%edx
f0100a44:	73 19                	jae    f0100a5f <check_page_free_list+0x12b>
f0100a46:	68 6e 42 10 f0       	push   $0xf010426e
f0100a4b:	68 7a 42 10 f0       	push   $0xf010427a
f0100a50:	68 23 02 00 00       	push   $0x223
f0100a55:	68 54 42 10 f0       	push   $0xf0104254
f0100a5a:	e8 2c f6 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100a5f:	39 fa                	cmp    %edi,%edx
f0100a61:	72 19                	jb     f0100a7c <check_page_free_list+0x148>
f0100a63:	68 8f 42 10 f0       	push   $0xf010428f
f0100a68:	68 7a 42 10 f0       	push   $0xf010427a
f0100a6d:	68 24 02 00 00       	push   $0x224
f0100a72:	68 54 42 10 f0       	push   $0xf0104254
f0100a77:	e8 0f f6 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a7c:	89 d0                	mov    %edx,%eax
f0100a7e:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a81:	a8 07                	test   $0x7,%al
f0100a83:	74 19                	je     f0100a9e <check_page_free_list+0x16a>
f0100a85:	68 24 3b 10 f0       	push   $0xf0103b24
f0100a8a:	68 7a 42 10 f0       	push   $0xf010427a
f0100a8f:	68 25 02 00 00       	push   $0x225
f0100a94:	68 54 42 10 f0       	push   $0xf0104254
f0100a99:	e8 ed f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a9e:	c1 f8 03             	sar    $0x3,%eax
f0100aa1:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100aa4:	85 c0                	test   %eax,%eax
f0100aa6:	75 19                	jne    f0100ac1 <check_page_free_list+0x18d>
f0100aa8:	68 a3 42 10 f0       	push   $0xf01042a3
f0100aad:	68 7a 42 10 f0       	push   $0xf010427a
f0100ab2:	68 28 02 00 00       	push   $0x228
f0100ab7:	68 54 42 10 f0       	push   $0xf0104254
f0100abc:	e8 ca f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ac1:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ac6:	75 19                	jne    f0100ae1 <check_page_free_list+0x1ad>
f0100ac8:	68 b4 42 10 f0       	push   $0xf01042b4
f0100acd:	68 7a 42 10 f0       	push   $0xf010427a
f0100ad2:	68 29 02 00 00       	push   $0x229
f0100ad7:	68 54 42 10 f0       	push   $0xf0104254
f0100adc:	e8 aa f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ae1:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ae6:	75 19                	jne    f0100b01 <check_page_free_list+0x1cd>
f0100ae8:	68 58 3b 10 f0       	push   $0xf0103b58
f0100aed:	68 7a 42 10 f0       	push   $0xf010427a
f0100af2:	68 2a 02 00 00       	push   $0x22a
f0100af7:	68 54 42 10 f0       	push   $0xf0104254
f0100afc:	e8 8a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b01:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b06:	75 19                	jne    f0100b21 <check_page_free_list+0x1ed>
f0100b08:	68 cd 42 10 f0       	push   $0xf01042cd
f0100b0d:	68 7a 42 10 f0       	push   $0xf010427a
f0100b12:	68 2b 02 00 00       	push   $0x22b
f0100b17:	68 54 42 10 f0       	push   $0xf0104254
f0100b1c:	e8 6a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b21:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b26:	76 3f                	jbe    f0100b67 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b28:	89 c3                	mov    %eax,%ebx
f0100b2a:	c1 eb 0c             	shr    $0xc,%ebx
f0100b2d:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b30:	77 12                	ja     f0100b44 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b32:	50                   	push   %eax
f0100b33:	68 dc 3a 10 f0       	push   $0xf0103adc
f0100b38:	6a 52                	push   $0x52
f0100b3a:	68 60 42 10 f0       	push   $0xf0104260
f0100b3f:	e8 47 f5 ff ff       	call   f010008b <_panic>
f0100b44:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b49:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b4c:	76 1e                	jbe    f0100b6c <check_page_free_list+0x238>
f0100b4e:	68 7c 3b 10 f0       	push   $0xf0103b7c
f0100b53:	68 7a 42 10 f0       	push   $0xf010427a
f0100b58:	68 2c 02 00 00       	push   $0x22c
f0100b5d:	68 54 42 10 f0       	push   $0xf0104254
f0100b62:	e8 24 f5 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100b67:	83 c6 01             	add    $0x1,%esi
f0100b6a:	eb 04                	jmp    f0100b70 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100b6c:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b70:	8b 12                	mov    (%edx),%edx
f0100b72:	85 d2                	test   %edx,%edx
f0100b74:	0f 85 c8 fe ff ff    	jne    f0100a42 <check_page_free_list+0x10e>
f0100b7a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100b7d:	85 f6                	test   %esi,%esi
f0100b7f:	7f 19                	jg     f0100b9a <check_page_free_list+0x266>
f0100b81:	68 e7 42 10 f0       	push   $0xf01042e7
f0100b86:	68 7a 42 10 f0       	push   $0xf010427a
f0100b8b:	68 34 02 00 00       	push   $0x234
f0100b90:	68 54 42 10 f0       	push   $0xf0104254
f0100b95:	e8 f1 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100b9a:	85 db                	test   %ebx,%ebx
f0100b9c:	7f 19                	jg     f0100bb7 <check_page_free_list+0x283>
f0100b9e:	68 f9 42 10 f0       	push   $0xf01042f9
f0100ba3:	68 7a 42 10 f0       	push   $0xf010427a
f0100ba8:	68 35 02 00 00       	push   $0x235
f0100bad:	68 54 42 10 f0       	push   $0xf0104254
f0100bb2:	e8 d4 f4 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100bb7:	83 ec 0c             	sub    $0xc,%esp
f0100bba:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0100bbf:	e8 e2 1a 00 00       	call   f01026a6 <cprintf>
}
f0100bc4:	eb 29                	jmp    f0100bef <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bc6:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100bcb:	85 c0                	test   %eax,%eax
f0100bcd:	0f 85 8e fd ff ff    	jne    f0100961 <check_page_free_list+0x2d>
f0100bd3:	e9 72 fd ff ff       	jmp    f010094a <check_page_free_list+0x16>
f0100bd8:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100bdf:	0f 84 65 fd ff ff    	je     f010094a <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100be5:	be 00 04 00 00       	mov    $0x400,%esi
f0100bea:	e9 c0 fd ff ff       	jmp    f01009af <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100bef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bf2:	5b                   	pop    %ebx
f0100bf3:	5e                   	pop    %esi
f0100bf4:	5f                   	pop    %edi
f0100bf5:	5d                   	pop    %ebp
f0100bf6:	c3                   	ret    

f0100bf7 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void  
page_init(void)  
{  
f0100bf7:	55                   	push   %ebp
f0100bf8:	89 e5                	mov    %esp,%ebp
f0100bfa:	56                   	push   %esi
f0100bfb:	53                   	push   %ebx
      
    size_t i;  
    for (i = 0; i < npages; i++) {  
f0100bfc:	be 00 00 00 00       	mov    $0x0,%esi
f0100c01:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c06:	e9 c5 00 00 00       	jmp    f0100cd0 <page_init+0xd9>
        if(i == 0)  
f0100c0b:	85 db                	test   %ebx,%ebx
f0100c0d:	75 16                	jne    f0100c25 <page_init+0x2e>
            {   pages[i].pp_ref = 1;  
f0100c0f:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100c14:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
                pages[i].pp_link = NULL;  
f0100c1a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100c20:	e9 a5 00 00 00       	jmp    f0100cca <page_init+0xd3>
            }  
        else if(i>=1 && i<npages_basemem)  
f0100c25:	3b 1d 40 65 11 f0    	cmp    0xf0116540,%ebx
f0100c2b:	73 25                	jae    f0100c52 <page_init+0x5b>
        {  
            pages[i].pp_ref = 0;  
f0100c2d:	89 f0                	mov    %esi,%eax
f0100c2f:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100c35:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
            pages[i].pp_link = page_free_list;   
f0100c3b:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100c41:	89 10                	mov    %edx,(%eax)
            page_free_list = &pages[i];  
f0100c43:	89 f0                	mov    %esi,%eax
f0100c45:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100c4b:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
f0100c50:	eb 78                	jmp    f0100cca <page_init+0xd3>
        }  
        else if(i>=IOPHYSMEM/PGSIZE && i< EXTPHYSMEM/PGSIZE )  
f0100c52:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100c58:	83 f8 5f             	cmp    $0x5f,%eax
f0100c5b:	77 16                	ja     f0100c73 <page_init+0x7c>
        {  
            pages[i].pp_ref = 1;  
f0100c5d:	89 f0                	mov    %esi,%eax
f0100c5f:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100c65:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
            pages[i].pp_link = NULL;  
f0100c6b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100c71:	eb 57                	jmp    f0100cca <page_init+0xd3>
        }  
      
        else if( i >= EXTPHYSMEM / PGSIZE &&   
f0100c73:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100c79:	76 2c                	jbe    f0100ca7 <page_init+0xb0>
                i < ( (int)(boot_alloc(0)) - KERNBASE)/PGSIZE)  
f0100c7b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c80:	e8 df fb ff ff       	call   f0100864 <boot_alloc>
        {  
            pages[i].pp_ref = 1;  
            pages[i].pp_link = NULL;  
        }  
      
        else if( i >= EXTPHYSMEM / PGSIZE &&   
f0100c85:	05 00 00 00 10       	add    $0x10000000,%eax
f0100c8a:	c1 e8 0c             	shr    $0xc,%eax
f0100c8d:	39 c3                	cmp    %eax,%ebx
f0100c8f:	73 16                	jae    f0100ca7 <page_init+0xb0>
                i < ( (int)(boot_alloc(0)) - KERNBASE)/PGSIZE)  
        {  
            pages[i].pp_ref = 1;  
f0100c91:	89 f0                	mov    %esi,%eax
f0100c93:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100c99:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
            pages[i].pp_link =NULL;  
f0100c9f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100ca5:	eb 23                	jmp    f0100cca <page_init+0xd3>
        }  
        else  
        {  
            pages[i].pp_ref = 0;  
f0100ca7:	89 f0                	mov    %esi,%eax
f0100ca9:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100caf:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
            pages[i].pp_link = page_free_list;  
f0100cb5:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100cbb:	89 10                	mov    %edx,(%eax)
            page_free_list = &pages[i];  
f0100cbd:	89 f0                	mov    %esi,%eax
f0100cbf:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100cc5:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
void  
page_init(void)  
{  
      
    size_t i;  
    for (i = 0; i < npages; i++) {  
f0100cca:	83 c3 01             	add    $0x1,%ebx
f0100ccd:	83 c6 08             	add    $0x8,%esi
f0100cd0:	3b 1d 64 69 11 f0    	cmp    0xf0116964,%ebx
f0100cd6:	0f 82 2f ff ff ff    	jb     f0100c0b <page_init+0x14>
            pages[i].pp_link = page_free_list;  
            page_free_list = &pages[i];  
        }  
  
    }  
} 
f0100cdc:	5b                   	pop    %ebx
f0100cdd:	5e                   	pop    %esi
f0100cde:	5d                   	pop    %ebp
f0100cdf:	c3                   	ret    

f0100ce0 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *  
page_alloc(int alloc_flags)  
{   if(page_free_list == NULL)  
f0100ce0:	55                   	push   %ebp
f0100ce1:	89 e5                	mov    %esp,%ebp
f0100ce3:	53                   	push   %ebx
f0100ce4:	83 ec 04             	sub    $0x4,%esp
f0100ce7:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100ced:	85 db                	test   %ebx,%ebx
f0100cef:	74 58                	je     f0100d49 <page_alloc+0x69>
        return NULL;  
  
    struct PageInfo* page = page_free_list;  
    page_free_list = page->pp_link;  
f0100cf1:	8b 03                	mov    (%ebx),%eax
f0100cf3:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
    page->pp_link = 0;  
f0100cf8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    if(alloc_flags & ALLOC_ZERO)  
f0100cfe:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d02:	74 45                	je     f0100d49 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d04:	89 d8                	mov    %ebx,%eax
f0100d06:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100d0c:	c1 f8 03             	sar    $0x3,%eax
f0100d0f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d12:	89 c2                	mov    %eax,%edx
f0100d14:	c1 ea 0c             	shr    $0xc,%edx
f0100d17:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100d1d:	72 12                	jb     f0100d31 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d1f:	50                   	push   %eax
f0100d20:	68 dc 3a 10 f0       	push   $0xf0103adc
f0100d25:	6a 52                	push   $0x52
f0100d27:	68 60 42 10 f0       	push   $0xf0104260
f0100d2c:	e8 5a f3 ff ff       	call   f010008b <_panic>
        memset(page2kva(page), 0, PGSIZE);  
f0100d31:	83 ec 04             	sub    $0x4,%esp
f0100d34:	68 00 10 00 00       	push   $0x1000
f0100d39:	6a 00                	push   $0x0
f0100d3b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d40:	50                   	push   %eax
f0100d41:	e8 49 24 00 00       	call   f010318f <memset>
f0100d46:	83 c4 10             	add    $0x10,%esp
    return page;  
} 
f0100d49:	89 d8                	mov    %ebx,%eax
f0100d4b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d4e:	c9                   	leave  
f0100d4f:	c3                   	ret    

f0100d50 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void  
page_free(struct PageInfo *pp)  
{  
f0100d50:	55                   	push   %ebp
f0100d51:	89 e5                	mov    %esp,%ebp
f0100d53:	83 ec 08             	sub    $0x8,%esp
f0100d56:	8b 45 08             	mov    0x8(%ebp),%eax
      
    if(pp->pp_link != 0  || pp->pp_ref != 0)  
f0100d59:	83 38 00             	cmpl   $0x0,(%eax)
f0100d5c:	75 07                	jne    f0100d65 <page_free+0x15>
f0100d5e:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d63:	74 17                	je     f0100d7c <page_free+0x2c>
        panic("page_free is not right");  
f0100d65:	83 ec 04             	sub    $0x4,%esp
f0100d68:	68 0a 43 10 f0       	push   $0xf010430a
f0100d6d:	68 36 01 00 00       	push   $0x136
f0100d72:	68 54 42 10 f0       	push   $0xf0104254
f0100d77:	e8 0f f3 ff ff       	call   f010008b <_panic>
    pp->pp_link = page_free_list;  
f0100d7c:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100d82:	89 10                	mov    %edx,(%eax)
    page_free_list = pp;  
f0100d84:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
    return;   
}  
f0100d89:	c9                   	leave  
f0100d8a:	c3                   	ret    

f0100d8b <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d8b:	55                   	push   %ebp
f0100d8c:	89 e5                	mov    %esp,%ebp
f0100d8e:	83 ec 08             	sub    $0x8,%esp
f0100d91:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d94:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d98:	83 e8 01             	sub    $0x1,%eax
f0100d9b:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d9f:	66 85 c0             	test   %ax,%ax
f0100da2:	75 0c                	jne    f0100db0 <page_decref+0x25>
		page_free(pp);
f0100da4:	83 ec 0c             	sub    $0xc,%esp
f0100da7:	52                   	push   %edx
f0100da8:	e8 a3 ff ff ff       	call   f0100d50 <page_free>
f0100dad:	83 c4 10             	add    $0x10,%esp
}
f0100db0:	c9                   	leave  
f0100db1:	c3                   	ret    

f0100db2 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *  
pgdir_walk(pde_t *pgdir, const void *va, int create)  
{  
f0100db2:	55                   	push   %ebp
f0100db3:	89 e5                	mov    %esp,%ebp
f0100db5:	56                   	push   %esi
f0100db6:	53                   	push   %ebx
f0100db7:	8b 75 0c             	mov    0xc(%ebp),%esi
    // Fill this function in  
    int pdeIndex = (unsigned int)va >>22;  
    if(pgdir[pdeIndex] == 0 && create == 0)  
f0100dba:	89 f3                	mov    %esi,%ebx
f0100dbc:	c1 eb 16             	shr    $0x16,%ebx
f0100dbf:	c1 e3 02             	shl    $0x2,%ebx
f0100dc2:	03 5d 08             	add    0x8(%ebp),%ebx
f0100dc5:	8b 03                	mov    (%ebx),%eax
f0100dc7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100dcb:	75 04                	jne    f0100dd1 <pgdir_walk+0x1f>
f0100dcd:	85 c0                	test   %eax,%eax
f0100dcf:	74 68                	je     f0100e39 <pgdir_walk+0x87>
        return NULL;  
    if(pgdir[pdeIndex] == 0){  
f0100dd1:	85 c0                	test   %eax,%eax
f0100dd3:	75 27                	jne    f0100dfc <pgdir_walk+0x4a>
        struct PageInfo* page = page_alloc(1);  
f0100dd5:	83 ec 0c             	sub    $0xc,%esp
f0100dd8:	6a 01                	push   $0x1
f0100dda:	e8 01 ff ff ff       	call   f0100ce0 <page_alloc>
        if(page == NULL)  
f0100ddf:	83 c4 10             	add    $0x10,%esp
f0100de2:	85 c0                	test   %eax,%eax
f0100de4:	74 5a                	je     f0100e40 <pgdir_walk+0x8e>
            return NULL;  
        page->pp_ref++;  
f0100de6:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
        pte_t pgAddress = page2pa(page);  
        pgAddress |= PTE_U;  
        pgAddress |= PTE_P;  
        pgAddress |= PTE_W;  
        pgdir[pdeIndex] = pgAddress;  
f0100deb:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100df1:	c1 f8 03             	sar    $0x3,%eax
f0100df4:	c1 e0 0c             	shl    $0xc,%eax
f0100df7:	83 c8 07             	or     $0x7,%eax
f0100dfa:	89 03                	mov    %eax,(%ebx)
    }  
    pte_t pgAdd = pgdir[pdeIndex];  
f0100dfc:	8b 13                	mov    (%ebx),%edx
    pgAdd = pgAdd>>12<<12;  
    int pteIndex =(pte_t)va >>12 & 0x3ff;  
    pte_t * pte =(pte_t*) pgAdd + pteIndex;  
f0100dfe:	c1 ee 0a             	shr    $0xa,%esi
f0100e01:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100e07:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100e0d:	8d 04 16             	lea    (%esi,%edx,1),%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e10:	89 c2                	mov    %eax,%edx
f0100e12:	c1 ea 0c             	shr    $0xc,%edx
f0100e15:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100e1b:	72 15                	jb     f0100e32 <pgdir_walk+0x80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e1d:	50                   	push   %eax
f0100e1e:	68 dc 3a 10 f0       	push   $0xf0103adc
f0100e23:	68 73 01 00 00       	push   $0x173
f0100e28:	68 54 42 10 f0       	push   $0xf0104254
f0100e2d:	e8 59 f2 ff ff       	call   f010008b <_panic>
    return KADDR( (pte_t) pte );//一定要返回虚拟地址，物理地址会引发错误。  
f0100e32:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e37:	eb 0c                	jmp    f0100e45 <pgdir_walk+0x93>
pgdir_walk(pde_t *pgdir, const void *va, int create)  
{  
    // Fill this function in  
    int pdeIndex = (unsigned int)va >>22;  
    if(pgdir[pdeIndex] == 0 && create == 0)  
        return NULL;  
f0100e39:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e3e:	eb 05                	jmp    f0100e45 <pgdir_walk+0x93>
    if(pgdir[pdeIndex] == 0){  
        struct PageInfo* page = page_alloc(1);  
        if(page == NULL)  
            return NULL;  
f0100e40:	b8 00 00 00 00       	mov    $0x0,%eax
    pte_t pgAdd = pgdir[pdeIndex];  
    pgAdd = pgAdd>>12<<12;  
    int pteIndex =(pte_t)va >>12 & 0x3ff;  
    pte_t * pte =(pte_t*) pgAdd + pteIndex;  
    return KADDR( (pte_t) pte );//一定要返回虚拟地址，物理地址会引发错误。  
}  
f0100e45:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e48:	5b                   	pop    %ebx
f0100e49:	5e                   	pop    %esi
f0100e4a:	5d                   	pop    %ebp
f0100e4b:	c3                   	ret    

f0100e4c <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *  
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)  
{   pte_t* pte = pgdir_walk(pgdir, va, 0);  
f0100e4c:	55                   	push   %ebp
f0100e4d:	89 e5                	mov    %esp,%ebp
f0100e4f:	53                   	push   %ebx
f0100e50:	83 ec 08             	sub    $0x8,%esp
f0100e53:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e56:	6a 00                	push   $0x0
f0100e58:	ff 75 0c             	pushl  0xc(%ebp)
f0100e5b:	ff 75 08             	pushl  0x8(%ebp)
f0100e5e:	e8 4f ff ff ff       	call   f0100db2 <pgdir_walk>
    if(pte == NULL)  
f0100e63:	83 c4 10             	add    $0x10,%esp
f0100e66:	85 c0                	test   %eax,%eax
f0100e68:	74 3a                	je     f0100ea4 <page_lookup+0x58>
        return NULL;  
    pte_t pa =  *pte>>12<<12;  
f0100e6a:	8b 10                	mov    (%eax),%edx
f0100e6c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
    if(pte_store != 0)  
f0100e72:	85 db                	test   %ebx,%ebx
f0100e74:	74 02                	je     f0100e78 <page_lookup+0x2c>
        *pte_store = pte ;  
f0100e76:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e78:	89 d0                	mov    %edx,%eax
f0100e7a:	c1 e8 0c             	shr    $0xc,%eax
f0100e7d:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100e83:	72 14                	jb     f0100e99 <page_lookup+0x4d>
		panic("pa2page called with invalid pa");
f0100e85:	83 ec 04             	sub    $0x4,%esp
f0100e88:	68 e8 3b 10 f0       	push   $0xf0103be8
f0100e8d:	6a 4b                	push   $0x4b
f0100e8f:	68 60 42 10 f0       	push   $0xf0104260
f0100e94:	e8 f2 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100e99:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100e9f:	8d 04 c2             	lea    (%edx,%eax,8),%eax
    return pa2page(pa);   
f0100ea2:	eb 05                	jmp    f0100ea9 <page_lookup+0x5d>
//
struct PageInfo *  
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)  
{   pte_t* pte = pgdir_walk(pgdir, va, 0);  
    if(pte == NULL)  
        return NULL;  
f0100ea4:	b8 00 00 00 00       	mov    $0x0,%eax
    pte_t pa =  *pte>>12<<12;  
    if(pte_store != 0)  
        *pte_store = pte ;  
    return pa2page(pa);   
}  
f0100ea9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100eac:	c9                   	leave  
f0100ead:	c3                   	ret    

f0100eae <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void  
page_remove(pde_t *pgdir, void *va)  
{   pte_t* pte;  
f0100eae:	55                   	push   %ebp
f0100eaf:	89 e5                	mov    %esp,%ebp
f0100eb1:	53                   	push   %ebx
f0100eb2:	83 ec 18             	sub    $0x18,%esp
f0100eb5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    struct PageInfo* page = page_lookup(pgdir, va, &pte);  
f0100eb8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ebb:	50                   	push   %eax
f0100ebc:	53                   	push   %ebx
f0100ebd:	ff 75 08             	pushl  0x8(%ebp)
f0100ec0:	e8 87 ff ff ff       	call   f0100e4c <page_lookup>
    if(page == 0)  
f0100ec5:	83 c4 10             	add    $0x10,%esp
f0100ec8:	85 c0                	test   %eax,%eax
f0100eca:	74 28                	je     f0100ef4 <page_remove+0x46>
        return;  
    *pte = 0;  
f0100ecc:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100ecf:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
    page->pp_ref--;  
f0100ed5:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100ed9:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100edc:	66 89 50 04          	mov    %dx,0x4(%eax)
    if(page->pp_ref ==0)  
f0100ee0:	66 85 d2             	test   %dx,%dx
f0100ee3:	75 0c                	jne    f0100ef1 <page_remove+0x43>
        page_free(page);  
f0100ee5:	83 ec 0c             	sub    $0xc,%esp
f0100ee8:	50                   	push   %eax
f0100ee9:	e8 62 fe ff ff       	call   f0100d50 <page_free>
f0100eee:	83 c4 10             	add    $0x10,%esp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100ef1:	0f 01 3b             	invlpg (%ebx)
    tlb_invalidate(pgdir, va);  
}  
f0100ef4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ef7:	c9                   	leave  
f0100ef8:	c3                   	ret    

f0100ef9 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int  
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)  
{  
f0100ef9:	55                   	push   %ebp
f0100efa:	89 e5                	mov    %esp,%ebp
f0100efc:	57                   	push   %edi
f0100efd:	56                   	push   %esi
f0100efe:	53                   	push   %ebx
f0100eff:	83 ec 10             	sub    $0x10,%esp
f0100f02:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f05:	8b 7d 10             	mov    0x10(%ebp),%edi
  
    pte_t* pte = pgdir_walk(pgdir, va, 1);  
f0100f08:	6a 01                	push   $0x1
f0100f0a:	57                   	push   %edi
f0100f0b:	ff 75 08             	pushl  0x8(%ebp)
f0100f0e:	e8 9f fe ff ff       	call   f0100db2 <pgdir_walk>
    if(pte == NULL)  
f0100f13:	83 c4 10             	add    $0x10,%esp
f0100f16:	85 c0                	test   %eax,%eax
f0100f18:	74 5c                	je     f0100f76 <page_insert+0x7d>
f0100f1a:	89 c6                	mov    %eax,%esi
        return -E_NO_MEM;  
    if( (pte[0] &  ~0xfff) == page2pa(pp))  
f0100f1c:	8b 10                	mov    (%eax),%edx
f0100f1e:	89 d1                	mov    %edx,%ecx
f0100f20:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100f26:	89 d8                	mov    %ebx,%eax
f0100f28:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100f2e:	c1 f8 03             	sar    $0x3,%eax
f0100f31:	c1 e0 0c             	shl    $0xc,%eax
f0100f34:	39 c1                	cmp    %eax,%ecx
f0100f36:	75 07                	jne    f0100f3f <page_insert+0x46>
        pp->pp_ref--;  
f0100f38:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f0100f3d:	eb 13                	jmp    f0100f52 <page_insert+0x59>
    else if(*pte != 0)  
f0100f3f:	85 d2                	test   %edx,%edx
f0100f41:	74 0f                	je     f0100f52 <page_insert+0x59>
        page_remove(pgdir, va);  
f0100f43:	83 ec 08             	sub    $0x8,%esp
f0100f46:	57                   	push   %edi
f0100f47:	ff 75 08             	pushl  0x8(%ebp)
f0100f4a:	e8 5f ff ff ff       	call   f0100eae <page_remove>
f0100f4f:	83 c4 10             	add    $0x10,%esp
  
    *pte = (page2pa(pp) & ~0xfff) | perm | PTE_P;  
f0100f52:	89 d8                	mov    %ebx,%eax
f0100f54:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100f5a:	c1 f8 03             	sar    $0x3,%eax
f0100f5d:	c1 e0 0c             	shl    $0xc,%eax
f0100f60:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f63:	83 ca 01             	or     $0x1,%edx
f0100f66:	09 d0                	or     %edx,%eax
f0100f68:	89 06                	mov    %eax,(%esi)
    pp->pp_ref++;  
f0100f6a:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
    return 0;  
f0100f6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f74:	eb 05                	jmp    f0100f7b <page_insert+0x82>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)  
{  
  
    pte_t* pte = pgdir_walk(pgdir, va, 1);  
    if(pte == NULL)  
        return -E_NO_MEM;  
f0100f76:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
        page_remove(pgdir, va);  
  
    *pte = (page2pa(pp) & ~0xfff) | perm | PTE_P;  
    pp->pp_ref++;  
    return 0;  
}
f0100f7b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f7e:	5b                   	pop    %ebx
f0100f7f:	5e                   	pop    %esi
f0100f80:	5f                   	pop    %edi
f0100f81:	5d                   	pop    %ebp
f0100f82:	c3                   	ret    

f0100f83 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100f83:	55                   	push   %ebp
f0100f84:	89 e5                	mov    %esp,%ebp
f0100f86:	57                   	push   %edi
f0100f87:	56                   	push   %esi
f0100f88:	53                   	push   %ebx
f0100f89:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100f8c:	b8 15 00 00 00       	mov    $0x15,%eax
f0100f91:	e8 11 f9 ff ff       	call   f01008a7 <nvram_read>
f0100f96:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100f98:	b8 17 00 00 00       	mov    $0x17,%eax
f0100f9d:	e8 05 f9 ff ff       	call   f01008a7 <nvram_read>
f0100fa2:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100fa4:	b8 34 00 00 00       	mov    $0x34,%eax
f0100fa9:	e8 f9 f8 ff ff       	call   f01008a7 <nvram_read>
f0100fae:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100fb1:	85 c0                	test   %eax,%eax
f0100fb3:	74 07                	je     f0100fbc <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100fb5:	05 00 40 00 00       	add    $0x4000,%eax
f0100fba:	eb 0b                	jmp    f0100fc7 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100fbc:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100fc2:	85 f6                	test   %esi,%esi
f0100fc4:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100fc7:	89 c2                	mov    %eax,%edx
f0100fc9:	c1 ea 02             	shr    $0x2,%edx
f0100fcc:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
	npages_basemem = basemem / (PGSIZE / 1024);
f0100fd2:	89 da                	mov    %ebx,%edx
f0100fd4:	c1 ea 02             	shr    $0x2,%edx
f0100fd7:	89 15 40 65 11 f0    	mov    %edx,0xf0116540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100fdd:	89 c2                	mov    %eax,%edx
f0100fdf:	29 da                	sub    %ebx,%edx
f0100fe1:	52                   	push   %edx
f0100fe2:	53                   	push   %ebx
f0100fe3:	50                   	push   %eax
f0100fe4:	68 08 3c 10 f0       	push   $0xf0103c08
f0100fe9:	e8 b8 16 00 00       	call   f01026a6 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100fee:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100ff3:	e8 6c f8 ff ff       	call   f0100864 <boot_alloc>
f0100ff8:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f0100ffd:	83 c4 0c             	add    $0xc,%esp
f0101000:	68 00 10 00 00       	push   $0x1000
f0101005:	6a 00                	push   $0x0
f0101007:	50                   	push   %eax
f0101008:	e8 82 21 00 00       	call   f010318f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010100d:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101012:	83 c4 10             	add    $0x10,%esp
f0101015:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010101a:	77 15                	ja     f0101031 <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010101c:	50                   	push   %eax
f010101d:	68 44 3c 10 f0       	push   $0xf0103c44
f0101022:	68 87 00 00 00       	push   $0x87
f0101027:	68 54 42 10 f0       	push   $0xf0104254
f010102c:	e8 5a f0 ff ff       	call   f010008b <_panic>
f0101031:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101037:	83 ca 05             	or     $0x5,%edx
f010103a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = boot_alloc(npages * sizeof (struct PageInfo));  
f0101040:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101045:	c1 e0 03             	shl    $0x3,%eax
f0101048:	e8 17 f8 ff ff       	call   f0100864 <boot_alloc>
f010104d:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
memset(pages, 0, npages*sizeof(struct PageInfo));  
f0101052:	83 ec 04             	sub    $0x4,%esp
f0101055:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f010105b:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101062:	52                   	push   %edx
f0101063:	6a 00                	push   $0x0
f0101065:	50                   	push   %eax
f0101066:	e8 24 21 00 00       	call   f010318f <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010106b:	e8 87 fb ff ff       	call   f0100bf7 <page_init>

	check_page_free_list(1);
f0101070:	b8 01 00 00 00       	mov    $0x1,%eax
f0101075:	e8 ba f8 ff ff       	call   f0100934 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010107a:	83 c4 10             	add    $0x10,%esp
f010107d:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f0101084:	75 17                	jne    f010109d <mem_init+0x11a>
		panic("'pages' is a null pointer!");
f0101086:	83 ec 04             	sub    $0x4,%esp
f0101089:	68 21 43 10 f0       	push   $0xf0104321
f010108e:	68 48 02 00 00       	push   $0x248
f0101093:	68 54 42 10 f0       	push   $0xf0104254
f0101098:	e8 ee ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010109d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01010a2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01010a7:	eb 05                	jmp    f01010ae <mem_init+0x12b>
		++nfree;
f01010a9:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010ac:	8b 00                	mov    (%eax),%eax
f01010ae:	85 c0                	test   %eax,%eax
f01010b0:	75 f7                	jne    f01010a9 <mem_init+0x126>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01010b2:	83 ec 0c             	sub    $0xc,%esp
f01010b5:	6a 00                	push   $0x0
f01010b7:	e8 24 fc ff ff       	call   f0100ce0 <page_alloc>
f01010bc:	89 c7                	mov    %eax,%edi
f01010be:	83 c4 10             	add    $0x10,%esp
f01010c1:	85 c0                	test   %eax,%eax
f01010c3:	75 19                	jne    f01010de <mem_init+0x15b>
f01010c5:	68 3c 43 10 f0       	push   $0xf010433c
f01010ca:	68 7a 42 10 f0       	push   $0xf010427a
f01010cf:	68 50 02 00 00       	push   $0x250
f01010d4:	68 54 42 10 f0       	push   $0xf0104254
f01010d9:	e8 ad ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01010de:	83 ec 0c             	sub    $0xc,%esp
f01010e1:	6a 00                	push   $0x0
f01010e3:	e8 f8 fb ff ff       	call   f0100ce0 <page_alloc>
f01010e8:	89 c6                	mov    %eax,%esi
f01010ea:	83 c4 10             	add    $0x10,%esp
f01010ed:	85 c0                	test   %eax,%eax
f01010ef:	75 19                	jne    f010110a <mem_init+0x187>
f01010f1:	68 52 43 10 f0       	push   $0xf0104352
f01010f6:	68 7a 42 10 f0       	push   $0xf010427a
f01010fb:	68 51 02 00 00       	push   $0x251
f0101100:	68 54 42 10 f0       	push   $0xf0104254
f0101105:	e8 81 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010110a:	83 ec 0c             	sub    $0xc,%esp
f010110d:	6a 00                	push   $0x0
f010110f:	e8 cc fb ff ff       	call   f0100ce0 <page_alloc>
f0101114:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101117:	83 c4 10             	add    $0x10,%esp
f010111a:	85 c0                	test   %eax,%eax
f010111c:	75 19                	jne    f0101137 <mem_init+0x1b4>
f010111e:	68 68 43 10 f0       	push   $0xf0104368
f0101123:	68 7a 42 10 f0       	push   $0xf010427a
f0101128:	68 52 02 00 00       	push   $0x252
f010112d:	68 54 42 10 f0       	push   $0xf0104254
f0101132:	e8 54 ef ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101137:	39 f7                	cmp    %esi,%edi
f0101139:	75 19                	jne    f0101154 <mem_init+0x1d1>
f010113b:	68 7e 43 10 f0       	push   $0xf010437e
f0101140:	68 7a 42 10 f0       	push   $0xf010427a
f0101145:	68 55 02 00 00       	push   $0x255
f010114a:	68 54 42 10 f0       	push   $0xf0104254
f010114f:	e8 37 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101154:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101157:	39 c6                	cmp    %eax,%esi
f0101159:	74 04                	je     f010115f <mem_init+0x1dc>
f010115b:	39 c7                	cmp    %eax,%edi
f010115d:	75 19                	jne    f0101178 <mem_init+0x1f5>
f010115f:	68 68 3c 10 f0       	push   $0xf0103c68
f0101164:	68 7a 42 10 f0       	push   $0xf010427a
f0101169:	68 56 02 00 00       	push   $0x256
f010116e:	68 54 42 10 f0       	push   $0xf0104254
f0101173:	e8 13 ef ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101178:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010117e:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f0101184:	c1 e2 0c             	shl    $0xc,%edx
f0101187:	89 f8                	mov    %edi,%eax
f0101189:	29 c8                	sub    %ecx,%eax
f010118b:	c1 f8 03             	sar    $0x3,%eax
f010118e:	c1 e0 0c             	shl    $0xc,%eax
f0101191:	39 d0                	cmp    %edx,%eax
f0101193:	72 19                	jb     f01011ae <mem_init+0x22b>
f0101195:	68 90 43 10 f0       	push   $0xf0104390
f010119a:	68 7a 42 10 f0       	push   $0xf010427a
f010119f:	68 57 02 00 00       	push   $0x257
f01011a4:	68 54 42 10 f0       	push   $0xf0104254
f01011a9:	e8 dd ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01011ae:	89 f0                	mov    %esi,%eax
f01011b0:	29 c8                	sub    %ecx,%eax
f01011b2:	c1 f8 03             	sar    $0x3,%eax
f01011b5:	c1 e0 0c             	shl    $0xc,%eax
f01011b8:	39 c2                	cmp    %eax,%edx
f01011ba:	77 19                	ja     f01011d5 <mem_init+0x252>
f01011bc:	68 ad 43 10 f0       	push   $0xf01043ad
f01011c1:	68 7a 42 10 f0       	push   $0xf010427a
f01011c6:	68 58 02 00 00       	push   $0x258
f01011cb:	68 54 42 10 f0       	push   $0xf0104254
f01011d0:	e8 b6 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01011d5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011d8:	29 c8                	sub    %ecx,%eax
f01011da:	c1 f8 03             	sar    $0x3,%eax
f01011dd:	c1 e0 0c             	shl    $0xc,%eax
f01011e0:	39 c2                	cmp    %eax,%edx
f01011e2:	77 19                	ja     f01011fd <mem_init+0x27a>
f01011e4:	68 ca 43 10 f0       	push   $0xf01043ca
f01011e9:	68 7a 42 10 f0       	push   $0xf010427a
f01011ee:	68 59 02 00 00       	push   $0x259
f01011f3:	68 54 42 10 f0       	push   $0xf0104254
f01011f8:	e8 8e ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01011fd:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101202:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101205:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010120c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010120f:	83 ec 0c             	sub    $0xc,%esp
f0101212:	6a 00                	push   $0x0
f0101214:	e8 c7 fa ff ff       	call   f0100ce0 <page_alloc>
f0101219:	83 c4 10             	add    $0x10,%esp
f010121c:	85 c0                	test   %eax,%eax
f010121e:	74 19                	je     f0101239 <mem_init+0x2b6>
f0101220:	68 e7 43 10 f0       	push   $0xf01043e7
f0101225:	68 7a 42 10 f0       	push   $0xf010427a
f010122a:	68 60 02 00 00       	push   $0x260
f010122f:	68 54 42 10 f0       	push   $0xf0104254
f0101234:	e8 52 ee ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101239:	83 ec 0c             	sub    $0xc,%esp
f010123c:	57                   	push   %edi
f010123d:	e8 0e fb ff ff       	call   f0100d50 <page_free>
	page_free(pp1);
f0101242:	89 34 24             	mov    %esi,(%esp)
f0101245:	e8 06 fb ff ff       	call   f0100d50 <page_free>
	page_free(pp2);
f010124a:	83 c4 04             	add    $0x4,%esp
f010124d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101250:	e8 fb fa ff ff       	call   f0100d50 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101255:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010125c:	e8 7f fa ff ff       	call   f0100ce0 <page_alloc>
f0101261:	89 c6                	mov    %eax,%esi
f0101263:	83 c4 10             	add    $0x10,%esp
f0101266:	85 c0                	test   %eax,%eax
f0101268:	75 19                	jne    f0101283 <mem_init+0x300>
f010126a:	68 3c 43 10 f0       	push   $0xf010433c
f010126f:	68 7a 42 10 f0       	push   $0xf010427a
f0101274:	68 67 02 00 00       	push   $0x267
f0101279:	68 54 42 10 f0       	push   $0xf0104254
f010127e:	e8 08 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101283:	83 ec 0c             	sub    $0xc,%esp
f0101286:	6a 00                	push   $0x0
f0101288:	e8 53 fa ff ff       	call   f0100ce0 <page_alloc>
f010128d:	89 c7                	mov    %eax,%edi
f010128f:	83 c4 10             	add    $0x10,%esp
f0101292:	85 c0                	test   %eax,%eax
f0101294:	75 19                	jne    f01012af <mem_init+0x32c>
f0101296:	68 52 43 10 f0       	push   $0xf0104352
f010129b:	68 7a 42 10 f0       	push   $0xf010427a
f01012a0:	68 68 02 00 00       	push   $0x268
f01012a5:	68 54 42 10 f0       	push   $0xf0104254
f01012aa:	e8 dc ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01012af:	83 ec 0c             	sub    $0xc,%esp
f01012b2:	6a 00                	push   $0x0
f01012b4:	e8 27 fa ff ff       	call   f0100ce0 <page_alloc>
f01012b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012bc:	83 c4 10             	add    $0x10,%esp
f01012bf:	85 c0                	test   %eax,%eax
f01012c1:	75 19                	jne    f01012dc <mem_init+0x359>
f01012c3:	68 68 43 10 f0       	push   $0xf0104368
f01012c8:	68 7a 42 10 f0       	push   $0xf010427a
f01012cd:	68 69 02 00 00       	push   $0x269
f01012d2:	68 54 42 10 f0       	push   $0xf0104254
f01012d7:	e8 af ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012dc:	39 fe                	cmp    %edi,%esi
f01012de:	75 19                	jne    f01012f9 <mem_init+0x376>
f01012e0:	68 7e 43 10 f0       	push   $0xf010437e
f01012e5:	68 7a 42 10 f0       	push   $0xf010427a
f01012ea:	68 6b 02 00 00       	push   $0x26b
f01012ef:	68 54 42 10 f0       	push   $0xf0104254
f01012f4:	e8 92 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012fc:	39 c7                	cmp    %eax,%edi
f01012fe:	74 04                	je     f0101304 <mem_init+0x381>
f0101300:	39 c6                	cmp    %eax,%esi
f0101302:	75 19                	jne    f010131d <mem_init+0x39a>
f0101304:	68 68 3c 10 f0       	push   $0xf0103c68
f0101309:	68 7a 42 10 f0       	push   $0xf010427a
f010130e:	68 6c 02 00 00       	push   $0x26c
f0101313:	68 54 42 10 f0       	push   $0xf0104254
f0101318:	e8 6e ed ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010131d:	83 ec 0c             	sub    $0xc,%esp
f0101320:	6a 00                	push   $0x0
f0101322:	e8 b9 f9 ff ff       	call   f0100ce0 <page_alloc>
f0101327:	83 c4 10             	add    $0x10,%esp
f010132a:	85 c0                	test   %eax,%eax
f010132c:	74 19                	je     f0101347 <mem_init+0x3c4>
f010132e:	68 e7 43 10 f0       	push   $0xf01043e7
f0101333:	68 7a 42 10 f0       	push   $0xf010427a
f0101338:	68 6d 02 00 00       	push   $0x26d
f010133d:	68 54 42 10 f0       	push   $0xf0104254
f0101342:	e8 44 ed ff ff       	call   f010008b <_panic>
f0101347:	89 f0                	mov    %esi,%eax
f0101349:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010134f:	c1 f8 03             	sar    $0x3,%eax
f0101352:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101355:	89 c2                	mov    %eax,%edx
f0101357:	c1 ea 0c             	shr    $0xc,%edx
f010135a:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101360:	72 12                	jb     f0101374 <mem_init+0x3f1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101362:	50                   	push   %eax
f0101363:	68 dc 3a 10 f0       	push   $0xf0103adc
f0101368:	6a 52                	push   $0x52
f010136a:	68 60 42 10 f0       	push   $0xf0104260
f010136f:	e8 17 ed ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101374:	83 ec 04             	sub    $0x4,%esp
f0101377:	68 00 10 00 00       	push   $0x1000
f010137c:	6a 01                	push   $0x1
f010137e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101383:	50                   	push   %eax
f0101384:	e8 06 1e 00 00       	call   f010318f <memset>
	page_free(pp0);
f0101389:	89 34 24             	mov    %esi,(%esp)
f010138c:	e8 bf f9 ff ff       	call   f0100d50 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101391:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101398:	e8 43 f9 ff ff       	call   f0100ce0 <page_alloc>
f010139d:	83 c4 10             	add    $0x10,%esp
f01013a0:	85 c0                	test   %eax,%eax
f01013a2:	75 19                	jne    f01013bd <mem_init+0x43a>
f01013a4:	68 f6 43 10 f0       	push   $0xf01043f6
f01013a9:	68 7a 42 10 f0       	push   $0xf010427a
f01013ae:	68 72 02 00 00       	push   $0x272
f01013b3:	68 54 42 10 f0       	push   $0xf0104254
f01013b8:	e8 ce ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01013bd:	39 c6                	cmp    %eax,%esi
f01013bf:	74 19                	je     f01013da <mem_init+0x457>
f01013c1:	68 14 44 10 f0       	push   $0xf0104414
f01013c6:	68 7a 42 10 f0       	push   $0xf010427a
f01013cb:	68 73 02 00 00       	push   $0x273
f01013d0:	68 54 42 10 f0       	push   $0xf0104254
f01013d5:	e8 b1 ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013da:	89 f0                	mov    %esi,%eax
f01013dc:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01013e2:	c1 f8 03             	sar    $0x3,%eax
f01013e5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013e8:	89 c2                	mov    %eax,%edx
f01013ea:	c1 ea 0c             	shr    $0xc,%edx
f01013ed:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01013f3:	72 12                	jb     f0101407 <mem_init+0x484>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013f5:	50                   	push   %eax
f01013f6:	68 dc 3a 10 f0       	push   $0xf0103adc
f01013fb:	6a 52                	push   $0x52
f01013fd:	68 60 42 10 f0       	push   $0xf0104260
f0101402:	e8 84 ec ff ff       	call   f010008b <_panic>
f0101407:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010140d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101413:	80 38 00             	cmpb   $0x0,(%eax)
f0101416:	74 19                	je     f0101431 <mem_init+0x4ae>
f0101418:	68 24 44 10 f0       	push   $0xf0104424
f010141d:	68 7a 42 10 f0       	push   $0xf010427a
f0101422:	68 76 02 00 00       	push   $0x276
f0101427:	68 54 42 10 f0       	push   $0xf0104254
f010142c:	e8 5a ec ff ff       	call   f010008b <_panic>
f0101431:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101434:	39 d0                	cmp    %edx,%eax
f0101436:	75 db                	jne    f0101413 <mem_init+0x490>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101438:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010143b:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101440:	83 ec 0c             	sub    $0xc,%esp
f0101443:	56                   	push   %esi
f0101444:	e8 07 f9 ff ff       	call   f0100d50 <page_free>
	page_free(pp1);
f0101449:	89 3c 24             	mov    %edi,(%esp)
f010144c:	e8 ff f8 ff ff       	call   f0100d50 <page_free>
	page_free(pp2);
f0101451:	83 c4 04             	add    $0x4,%esp
f0101454:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101457:	e8 f4 f8 ff ff       	call   f0100d50 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010145c:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101461:	83 c4 10             	add    $0x10,%esp
f0101464:	eb 05                	jmp    f010146b <mem_init+0x4e8>
		--nfree;
f0101466:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101469:	8b 00                	mov    (%eax),%eax
f010146b:	85 c0                	test   %eax,%eax
f010146d:	75 f7                	jne    f0101466 <mem_init+0x4e3>
		--nfree;
	assert(nfree == 0);
f010146f:	85 db                	test   %ebx,%ebx
f0101471:	74 19                	je     f010148c <mem_init+0x509>
f0101473:	68 2e 44 10 f0       	push   $0xf010442e
f0101478:	68 7a 42 10 f0       	push   $0xf010427a
f010147d:	68 83 02 00 00       	push   $0x283
f0101482:	68 54 42 10 f0       	push   $0xf0104254
f0101487:	e8 ff eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010148c:	83 ec 0c             	sub    $0xc,%esp
f010148f:	68 88 3c 10 f0       	push   $0xf0103c88
f0101494:	e8 0d 12 00 00       	call   f01026a6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101499:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014a0:	e8 3b f8 ff ff       	call   f0100ce0 <page_alloc>
f01014a5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014a8:	83 c4 10             	add    $0x10,%esp
f01014ab:	85 c0                	test   %eax,%eax
f01014ad:	75 19                	jne    f01014c8 <mem_init+0x545>
f01014af:	68 3c 43 10 f0       	push   $0xf010433c
f01014b4:	68 7a 42 10 f0       	push   $0xf010427a
f01014b9:	68 dc 02 00 00       	push   $0x2dc
f01014be:	68 54 42 10 f0       	push   $0xf0104254
f01014c3:	e8 c3 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01014c8:	83 ec 0c             	sub    $0xc,%esp
f01014cb:	6a 00                	push   $0x0
f01014cd:	e8 0e f8 ff ff       	call   f0100ce0 <page_alloc>
f01014d2:	89 c3                	mov    %eax,%ebx
f01014d4:	83 c4 10             	add    $0x10,%esp
f01014d7:	85 c0                	test   %eax,%eax
f01014d9:	75 19                	jne    f01014f4 <mem_init+0x571>
f01014db:	68 52 43 10 f0       	push   $0xf0104352
f01014e0:	68 7a 42 10 f0       	push   $0xf010427a
f01014e5:	68 dd 02 00 00       	push   $0x2dd
f01014ea:	68 54 42 10 f0       	push   $0xf0104254
f01014ef:	e8 97 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01014f4:	83 ec 0c             	sub    $0xc,%esp
f01014f7:	6a 00                	push   $0x0
f01014f9:	e8 e2 f7 ff ff       	call   f0100ce0 <page_alloc>
f01014fe:	89 c6                	mov    %eax,%esi
f0101500:	83 c4 10             	add    $0x10,%esp
f0101503:	85 c0                	test   %eax,%eax
f0101505:	75 19                	jne    f0101520 <mem_init+0x59d>
f0101507:	68 68 43 10 f0       	push   $0xf0104368
f010150c:	68 7a 42 10 f0       	push   $0xf010427a
f0101511:	68 de 02 00 00       	push   $0x2de
f0101516:	68 54 42 10 f0       	push   $0xf0104254
f010151b:	e8 6b eb ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101520:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101523:	75 19                	jne    f010153e <mem_init+0x5bb>
f0101525:	68 7e 43 10 f0       	push   $0xf010437e
f010152a:	68 7a 42 10 f0       	push   $0xf010427a
f010152f:	68 e1 02 00 00       	push   $0x2e1
f0101534:	68 54 42 10 f0       	push   $0xf0104254
f0101539:	e8 4d eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010153e:	39 c3                	cmp    %eax,%ebx
f0101540:	74 05                	je     f0101547 <mem_init+0x5c4>
f0101542:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101545:	75 19                	jne    f0101560 <mem_init+0x5dd>
f0101547:	68 68 3c 10 f0       	push   $0xf0103c68
f010154c:	68 7a 42 10 f0       	push   $0xf010427a
f0101551:	68 e2 02 00 00       	push   $0x2e2
f0101556:	68 54 42 10 f0       	push   $0xf0104254
f010155b:	e8 2b eb ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101560:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101565:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101568:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010156f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101572:	83 ec 0c             	sub    $0xc,%esp
f0101575:	6a 00                	push   $0x0
f0101577:	e8 64 f7 ff ff       	call   f0100ce0 <page_alloc>
f010157c:	83 c4 10             	add    $0x10,%esp
f010157f:	85 c0                	test   %eax,%eax
f0101581:	74 19                	je     f010159c <mem_init+0x619>
f0101583:	68 e7 43 10 f0       	push   $0xf01043e7
f0101588:	68 7a 42 10 f0       	push   $0xf010427a
f010158d:	68 e9 02 00 00       	push   $0x2e9
f0101592:	68 54 42 10 f0       	push   $0xf0104254
f0101597:	e8 ef ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010159c:	83 ec 04             	sub    $0x4,%esp
f010159f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01015a2:	50                   	push   %eax
f01015a3:	6a 00                	push   $0x0
f01015a5:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01015ab:	e8 9c f8 ff ff       	call   f0100e4c <page_lookup>
f01015b0:	83 c4 10             	add    $0x10,%esp
f01015b3:	85 c0                	test   %eax,%eax
f01015b5:	74 19                	je     f01015d0 <mem_init+0x64d>
f01015b7:	68 a8 3c 10 f0       	push   $0xf0103ca8
f01015bc:	68 7a 42 10 f0       	push   $0xf010427a
f01015c1:	68 ec 02 00 00       	push   $0x2ec
f01015c6:	68 54 42 10 f0       	push   $0xf0104254
f01015cb:	e8 bb ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01015d0:	6a 02                	push   $0x2
f01015d2:	6a 00                	push   $0x0
f01015d4:	53                   	push   %ebx
f01015d5:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01015db:	e8 19 f9 ff ff       	call   f0100ef9 <page_insert>
f01015e0:	83 c4 10             	add    $0x10,%esp
f01015e3:	85 c0                	test   %eax,%eax
f01015e5:	78 19                	js     f0101600 <mem_init+0x67d>
f01015e7:	68 e0 3c 10 f0       	push   $0xf0103ce0
f01015ec:	68 7a 42 10 f0       	push   $0xf010427a
f01015f1:	68 ef 02 00 00       	push   $0x2ef
f01015f6:	68 54 42 10 f0       	push   $0xf0104254
f01015fb:	e8 8b ea ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101600:	83 ec 0c             	sub    $0xc,%esp
f0101603:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101606:	e8 45 f7 ff ff       	call   f0100d50 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010160b:	6a 02                	push   $0x2
f010160d:	6a 00                	push   $0x0
f010160f:	53                   	push   %ebx
f0101610:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101616:	e8 de f8 ff ff       	call   f0100ef9 <page_insert>
f010161b:	83 c4 20             	add    $0x20,%esp
f010161e:	85 c0                	test   %eax,%eax
f0101620:	74 19                	je     f010163b <mem_init+0x6b8>
f0101622:	68 10 3d 10 f0       	push   $0xf0103d10
f0101627:	68 7a 42 10 f0       	push   $0xf010427a
f010162c:	68 f3 02 00 00       	push   $0x2f3
f0101631:	68 54 42 10 f0       	push   $0xf0104254
f0101636:	e8 50 ea ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010163b:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101641:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101646:	89 c1                	mov    %eax,%ecx
f0101648:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010164b:	8b 17                	mov    (%edi),%edx
f010164d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101653:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101656:	29 c8                	sub    %ecx,%eax
f0101658:	c1 f8 03             	sar    $0x3,%eax
f010165b:	c1 e0 0c             	shl    $0xc,%eax
f010165e:	39 c2                	cmp    %eax,%edx
f0101660:	74 19                	je     f010167b <mem_init+0x6f8>
f0101662:	68 40 3d 10 f0       	push   $0xf0103d40
f0101667:	68 7a 42 10 f0       	push   $0xf010427a
f010166c:	68 f4 02 00 00       	push   $0x2f4
f0101671:	68 54 42 10 f0       	push   $0xf0104254
f0101676:	e8 10 ea ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010167b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101680:	89 f8                	mov    %edi,%eax
f0101682:	e8 49 f2 ff ff       	call   f01008d0 <check_va2pa>
f0101687:	89 da                	mov    %ebx,%edx
f0101689:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010168c:	c1 fa 03             	sar    $0x3,%edx
f010168f:	c1 e2 0c             	shl    $0xc,%edx
f0101692:	39 d0                	cmp    %edx,%eax
f0101694:	74 19                	je     f01016af <mem_init+0x72c>
f0101696:	68 68 3d 10 f0       	push   $0xf0103d68
f010169b:	68 7a 42 10 f0       	push   $0xf010427a
f01016a0:	68 f5 02 00 00       	push   $0x2f5
f01016a5:	68 54 42 10 f0       	push   $0xf0104254
f01016aa:	e8 dc e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01016af:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01016b4:	74 19                	je     f01016cf <mem_init+0x74c>
f01016b6:	68 39 44 10 f0       	push   $0xf0104439
f01016bb:	68 7a 42 10 f0       	push   $0xf010427a
f01016c0:	68 f6 02 00 00       	push   $0x2f6
f01016c5:	68 54 42 10 f0       	push   $0xf0104254
f01016ca:	e8 bc e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01016cf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016d2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01016d7:	74 19                	je     f01016f2 <mem_init+0x76f>
f01016d9:	68 4a 44 10 f0       	push   $0xf010444a
f01016de:	68 7a 42 10 f0       	push   $0xf010427a
f01016e3:	68 f7 02 00 00       	push   $0x2f7
f01016e8:	68 54 42 10 f0       	push   $0xf0104254
f01016ed:	e8 99 e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01016f2:	6a 02                	push   $0x2
f01016f4:	68 00 10 00 00       	push   $0x1000
f01016f9:	56                   	push   %esi
f01016fa:	57                   	push   %edi
f01016fb:	e8 f9 f7 ff ff       	call   f0100ef9 <page_insert>
f0101700:	83 c4 10             	add    $0x10,%esp
f0101703:	85 c0                	test   %eax,%eax
f0101705:	74 19                	je     f0101720 <mem_init+0x79d>
f0101707:	68 98 3d 10 f0       	push   $0xf0103d98
f010170c:	68 7a 42 10 f0       	push   $0xf010427a
f0101711:	68 fa 02 00 00       	push   $0x2fa
f0101716:	68 54 42 10 f0       	push   $0xf0104254
f010171b:	e8 6b e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101720:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101725:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010172a:	e8 a1 f1 ff ff       	call   f01008d0 <check_va2pa>
f010172f:	89 f2                	mov    %esi,%edx
f0101731:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101737:	c1 fa 03             	sar    $0x3,%edx
f010173a:	c1 e2 0c             	shl    $0xc,%edx
f010173d:	39 d0                	cmp    %edx,%eax
f010173f:	74 19                	je     f010175a <mem_init+0x7d7>
f0101741:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101746:	68 7a 42 10 f0       	push   $0xf010427a
f010174b:	68 fb 02 00 00       	push   $0x2fb
f0101750:	68 54 42 10 f0       	push   $0xf0104254
f0101755:	e8 31 e9 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010175a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010175f:	74 19                	je     f010177a <mem_init+0x7f7>
f0101761:	68 5b 44 10 f0       	push   $0xf010445b
f0101766:	68 7a 42 10 f0       	push   $0xf010427a
f010176b:	68 fc 02 00 00       	push   $0x2fc
f0101770:	68 54 42 10 f0       	push   $0xf0104254
f0101775:	e8 11 e9 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010177a:	83 ec 0c             	sub    $0xc,%esp
f010177d:	6a 00                	push   $0x0
f010177f:	e8 5c f5 ff ff       	call   f0100ce0 <page_alloc>
f0101784:	83 c4 10             	add    $0x10,%esp
f0101787:	85 c0                	test   %eax,%eax
f0101789:	74 19                	je     f01017a4 <mem_init+0x821>
f010178b:	68 e7 43 10 f0       	push   $0xf01043e7
f0101790:	68 7a 42 10 f0       	push   $0xf010427a
f0101795:	68 ff 02 00 00       	push   $0x2ff
f010179a:	68 54 42 10 f0       	push   $0xf0104254
f010179f:	e8 e7 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017a4:	6a 02                	push   $0x2
f01017a6:	68 00 10 00 00       	push   $0x1000
f01017ab:	56                   	push   %esi
f01017ac:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01017b2:	e8 42 f7 ff ff       	call   f0100ef9 <page_insert>
f01017b7:	83 c4 10             	add    $0x10,%esp
f01017ba:	85 c0                	test   %eax,%eax
f01017bc:	74 19                	je     f01017d7 <mem_init+0x854>
f01017be:	68 98 3d 10 f0       	push   $0xf0103d98
f01017c3:	68 7a 42 10 f0       	push   $0xf010427a
f01017c8:	68 02 03 00 00       	push   $0x302
f01017cd:	68 54 42 10 f0       	push   $0xf0104254
f01017d2:	e8 b4 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017d7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017dc:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01017e1:	e8 ea f0 ff ff       	call   f01008d0 <check_va2pa>
f01017e6:	89 f2                	mov    %esi,%edx
f01017e8:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01017ee:	c1 fa 03             	sar    $0x3,%edx
f01017f1:	c1 e2 0c             	shl    $0xc,%edx
f01017f4:	39 d0                	cmp    %edx,%eax
f01017f6:	74 19                	je     f0101811 <mem_init+0x88e>
f01017f8:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01017fd:	68 7a 42 10 f0       	push   $0xf010427a
f0101802:	68 03 03 00 00       	push   $0x303
f0101807:	68 54 42 10 f0       	push   $0xf0104254
f010180c:	e8 7a e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101811:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101816:	74 19                	je     f0101831 <mem_init+0x8ae>
f0101818:	68 5b 44 10 f0       	push   $0xf010445b
f010181d:	68 7a 42 10 f0       	push   $0xf010427a
f0101822:	68 04 03 00 00       	push   $0x304
f0101827:	68 54 42 10 f0       	push   $0xf0104254
f010182c:	e8 5a e8 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101831:	83 ec 0c             	sub    $0xc,%esp
f0101834:	6a 00                	push   $0x0
f0101836:	e8 a5 f4 ff ff       	call   f0100ce0 <page_alloc>
f010183b:	83 c4 10             	add    $0x10,%esp
f010183e:	85 c0                	test   %eax,%eax
f0101840:	74 19                	je     f010185b <mem_init+0x8d8>
f0101842:	68 e7 43 10 f0       	push   $0xf01043e7
f0101847:	68 7a 42 10 f0       	push   $0xf010427a
f010184c:	68 08 03 00 00       	push   $0x308
f0101851:	68 54 42 10 f0       	push   $0xf0104254
f0101856:	e8 30 e8 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010185b:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f0101861:	8b 02                	mov    (%edx),%eax
f0101863:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101868:	89 c1                	mov    %eax,%ecx
f010186a:	c1 e9 0c             	shr    $0xc,%ecx
f010186d:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0101873:	72 15                	jb     f010188a <mem_init+0x907>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101875:	50                   	push   %eax
f0101876:	68 dc 3a 10 f0       	push   $0xf0103adc
f010187b:	68 0b 03 00 00       	push   $0x30b
f0101880:	68 54 42 10 f0       	push   $0xf0104254
f0101885:	e8 01 e8 ff ff       	call   f010008b <_panic>
f010188a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010188f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101892:	83 ec 04             	sub    $0x4,%esp
f0101895:	6a 00                	push   $0x0
f0101897:	68 00 10 00 00       	push   $0x1000
f010189c:	52                   	push   %edx
f010189d:	e8 10 f5 ff ff       	call   f0100db2 <pgdir_walk>
f01018a2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01018a5:	8d 57 04             	lea    0x4(%edi),%edx
f01018a8:	83 c4 10             	add    $0x10,%esp
f01018ab:	39 d0                	cmp    %edx,%eax
f01018ad:	74 19                	je     f01018c8 <mem_init+0x945>
f01018af:	68 04 3e 10 f0       	push   $0xf0103e04
f01018b4:	68 7a 42 10 f0       	push   $0xf010427a
f01018b9:	68 0c 03 00 00       	push   $0x30c
f01018be:	68 54 42 10 f0       	push   $0xf0104254
f01018c3:	e8 c3 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01018c8:	6a 06                	push   $0x6
f01018ca:	68 00 10 00 00       	push   $0x1000
f01018cf:	56                   	push   %esi
f01018d0:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01018d6:	e8 1e f6 ff ff       	call   f0100ef9 <page_insert>
f01018db:	83 c4 10             	add    $0x10,%esp
f01018de:	85 c0                	test   %eax,%eax
f01018e0:	74 19                	je     f01018fb <mem_init+0x978>
f01018e2:	68 44 3e 10 f0       	push   $0xf0103e44
f01018e7:	68 7a 42 10 f0       	push   $0xf010427a
f01018ec:	68 0f 03 00 00       	push   $0x30f
f01018f1:	68 54 42 10 f0       	push   $0xf0104254
f01018f6:	e8 90 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018fb:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101901:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101906:	89 f8                	mov    %edi,%eax
f0101908:	e8 c3 ef ff ff       	call   f01008d0 <check_va2pa>
f010190d:	89 f2                	mov    %esi,%edx
f010190f:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101915:	c1 fa 03             	sar    $0x3,%edx
f0101918:	c1 e2 0c             	shl    $0xc,%edx
f010191b:	39 d0                	cmp    %edx,%eax
f010191d:	74 19                	je     f0101938 <mem_init+0x9b5>
f010191f:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101924:	68 7a 42 10 f0       	push   $0xf010427a
f0101929:	68 10 03 00 00       	push   $0x310
f010192e:	68 54 42 10 f0       	push   $0xf0104254
f0101933:	e8 53 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101938:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010193d:	74 19                	je     f0101958 <mem_init+0x9d5>
f010193f:	68 5b 44 10 f0       	push   $0xf010445b
f0101944:	68 7a 42 10 f0       	push   $0xf010427a
f0101949:	68 11 03 00 00       	push   $0x311
f010194e:	68 54 42 10 f0       	push   $0xf0104254
f0101953:	e8 33 e7 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101958:	83 ec 04             	sub    $0x4,%esp
f010195b:	6a 00                	push   $0x0
f010195d:	68 00 10 00 00       	push   $0x1000
f0101962:	57                   	push   %edi
f0101963:	e8 4a f4 ff ff       	call   f0100db2 <pgdir_walk>
f0101968:	83 c4 10             	add    $0x10,%esp
f010196b:	f6 00 04             	testb  $0x4,(%eax)
f010196e:	75 19                	jne    f0101989 <mem_init+0xa06>
f0101970:	68 84 3e 10 f0       	push   $0xf0103e84
f0101975:	68 7a 42 10 f0       	push   $0xf010427a
f010197a:	68 12 03 00 00       	push   $0x312
f010197f:	68 54 42 10 f0       	push   $0xf0104254
f0101984:	e8 02 e7 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101989:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010198e:	f6 00 04             	testb  $0x4,(%eax)
f0101991:	75 19                	jne    f01019ac <mem_init+0xa29>
f0101993:	68 6c 44 10 f0       	push   $0xf010446c
f0101998:	68 7a 42 10 f0       	push   $0xf010427a
f010199d:	68 13 03 00 00       	push   $0x313
f01019a2:	68 54 42 10 f0       	push   $0xf0104254
f01019a7:	e8 df e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019ac:	6a 02                	push   $0x2
f01019ae:	68 00 10 00 00       	push   $0x1000
f01019b3:	56                   	push   %esi
f01019b4:	50                   	push   %eax
f01019b5:	e8 3f f5 ff ff       	call   f0100ef9 <page_insert>
f01019ba:	83 c4 10             	add    $0x10,%esp
f01019bd:	85 c0                	test   %eax,%eax
f01019bf:	74 19                	je     f01019da <mem_init+0xa57>
f01019c1:	68 98 3d 10 f0       	push   $0xf0103d98
f01019c6:	68 7a 42 10 f0       	push   $0xf010427a
f01019cb:	68 16 03 00 00       	push   $0x316
f01019d0:	68 54 42 10 f0       	push   $0xf0104254
f01019d5:	e8 b1 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01019da:	83 ec 04             	sub    $0x4,%esp
f01019dd:	6a 00                	push   $0x0
f01019df:	68 00 10 00 00       	push   $0x1000
f01019e4:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01019ea:	e8 c3 f3 ff ff       	call   f0100db2 <pgdir_walk>
f01019ef:	83 c4 10             	add    $0x10,%esp
f01019f2:	f6 00 02             	testb  $0x2,(%eax)
f01019f5:	75 19                	jne    f0101a10 <mem_init+0xa8d>
f01019f7:	68 b8 3e 10 f0       	push   $0xf0103eb8
f01019fc:	68 7a 42 10 f0       	push   $0xf010427a
f0101a01:	68 17 03 00 00       	push   $0x317
f0101a06:	68 54 42 10 f0       	push   $0xf0104254
f0101a0b:	e8 7b e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a10:	83 ec 04             	sub    $0x4,%esp
f0101a13:	6a 00                	push   $0x0
f0101a15:	68 00 10 00 00       	push   $0x1000
f0101a1a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101a20:	e8 8d f3 ff ff       	call   f0100db2 <pgdir_walk>
f0101a25:	83 c4 10             	add    $0x10,%esp
f0101a28:	f6 00 04             	testb  $0x4,(%eax)
f0101a2b:	74 19                	je     f0101a46 <mem_init+0xac3>
f0101a2d:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101a32:	68 7a 42 10 f0       	push   $0xf010427a
f0101a37:	68 18 03 00 00       	push   $0x318
f0101a3c:	68 54 42 10 f0       	push   $0xf0104254
f0101a41:	e8 45 e6 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101a46:	6a 02                	push   $0x2
f0101a48:	68 00 00 40 00       	push   $0x400000
f0101a4d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a50:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101a56:	e8 9e f4 ff ff       	call   f0100ef9 <page_insert>
f0101a5b:	83 c4 10             	add    $0x10,%esp
f0101a5e:	85 c0                	test   %eax,%eax
f0101a60:	78 19                	js     f0101a7b <mem_init+0xaf8>
f0101a62:	68 24 3f 10 f0       	push   $0xf0103f24
f0101a67:	68 7a 42 10 f0       	push   $0xf010427a
f0101a6c:	68 1b 03 00 00       	push   $0x31b
f0101a71:	68 54 42 10 f0       	push   $0xf0104254
f0101a76:	e8 10 e6 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101a7b:	6a 02                	push   $0x2
f0101a7d:	68 00 10 00 00       	push   $0x1000
f0101a82:	53                   	push   %ebx
f0101a83:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101a89:	e8 6b f4 ff ff       	call   f0100ef9 <page_insert>
f0101a8e:	83 c4 10             	add    $0x10,%esp
f0101a91:	85 c0                	test   %eax,%eax
f0101a93:	74 19                	je     f0101aae <mem_init+0xb2b>
f0101a95:	68 5c 3f 10 f0       	push   $0xf0103f5c
f0101a9a:	68 7a 42 10 f0       	push   $0xf010427a
f0101a9f:	68 1e 03 00 00       	push   $0x31e
f0101aa4:	68 54 42 10 f0       	push   $0xf0104254
f0101aa9:	e8 dd e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101aae:	83 ec 04             	sub    $0x4,%esp
f0101ab1:	6a 00                	push   $0x0
f0101ab3:	68 00 10 00 00       	push   $0x1000
f0101ab8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101abe:	e8 ef f2 ff ff       	call   f0100db2 <pgdir_walk>
f0101ac3:	83 c4 10             	add    $0x10,%esp
f0101ac6:	f6 00 04             	testb  $0x4,(%eax)
f0101ac9:	74 19                	je     f0101ae4 <mem_init+0xb61>
f0101acb:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101ad0:	68 7a 42 10 f0       	push   $0xf010427a
f0101ad5:	68 1f 03 00 00       	push   $0x31f
f0101ada:	68 54 42 10 f0       	push   $0xf0104254
f0101adf:	e8 a7 e5 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ae4:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101aea:	ba 00 00 00 00       	mov    $0x0,%edx
f0101aef:	89 f8                	mov    %edi,%eax
f0101af1:	e8 da ed ff ff       	call   f01008d0 <check_va2pa>
f0101af6:	89 c1                	mov    %eax,%ecx
f0101af8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101afb:	89 d8                	mov    %ebx,%eax
f0101afd:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101b03:	c1 f8 03             	sar    $0x3,%eax
f0101b06:	c1 e0 0c             	shl    $0xc,%eax
f0101b09:	39 c1                	cmp    %eax,%ecx
f0101b0b:	74 19                	je     f0101b26 <mem_init+0xba3>
f0101b0d:	68 98 3f 10 f0       	push   $0xf0103f98
f0101b12:	68 7a 42 10 f0       	push   $0xf010427a
f0101b17:	68 22 03 00 00       	push   $0x322
f0101b1c:	68 54 42 10 f0       	push   $0xf0104254
f0101b21:	e8 65 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101b26:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b2b:	89 f8                	mov    %edi,%eax
f0101b2d:	e8 9e ed ff ff       	call   f01008d0 <check_va2pa>
f0101b32:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101b35:	74 19                	je     f0101b50 <mem_init+0xbcd>
f0101b37:	68 c4 3f 10 f0       	push   $0xf0103fc4
f0101b3c:	68 7a 42 10 f0       	push   $0xf010427a
f0101b41:	68 23 03 00 00       	push   $0x323
f0101b46:	68 54 42 10 f0       	push   $0xf0104254
f0101b4b:	e8 3b e5 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101b50:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101b55:	74 19                	je     f0101b70 <mem_init+0xbed>
f0101b57:	68 82 44 10 f0       	push   $0xf0104482
f0101b5c:	68 7a 42 10 f0       	push   $0xf010427a
f0101b61:	68 25 03 00 00       	push   $0x325
f0101b66:	68 54 42 10 f0       	push   $0xf0104254
f0101b6b:	e8 1b e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101b70:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101b75:	74 19                	je     f0101b90 <mem_init+0xc0d>
f0101b77:	68 93 44 10 f0       	push   $0xf0104493
f0101b7c:	68 7a 42 10 f0       	push   $0xf010427a
f0101b81:	68 26 03 00 00       	push   $0x326
f0101b86:	68 54 42 10 f0       	push   $0xf0104254
f0101b8b:	e8 fb e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101b90:	83 ec 0c             	sub    $0xc,%esp
f0101b93:	6a 00                	push   $0x0
f0101b95:	e8 46 f1 ff ff       	call   f0100ce0 <page_alloc>
f0101b9a:	83 c4 10             	add    $0x10,%esp
f0101b9d:	39 c6                	cmp    %eax,%esi
f0101b9f:	75 04                	jne    f0101ba5 <mem_init+0xc22>
f0101ba1:	85 c0                	test   %eax,%eax
f0101ba3:	75 19                	jne    f0101bbe <mem_init+0xc3b>
f0101ba5:	68 f4 3f 10 f0       	push   $0xf0103ff4
f0101baa:	68 7a 42 10 f0       	push   $0xf010427a
f0101baf:	68 29 03 00 00       	push   $0x329
f0101bb4:	68 54 42 10 f0       	push   $0xf0104254
f0101bb9:	e8 cd e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101bbe:	83 ec 08             	sub    $0x8,%esp
f0101bc1:	6a 00                	push   $0x0
f0101bc3:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101bc9:	e8 e0 f2 ff ff       	call   f0100eae <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101bce:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101bd4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bd9:	89 f8                	mov    %edi,%eax
f0101bdb:	e8 f0 ec ff ff       	call   f01008d0 <check_va2pa>
f0101be0:	83 c4 10             	add    $0x10,%esp
f0101be3:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101be6:	74 19                	je     f0101c01 <mem_init+0xc7e>
f0101be8:	68 18 40 10 f0       	push   $0xf0104018
f0101bed:	68 7a 42 10 f0       	push   $0xf010427a
f0101bf2:	68 2d 03 00 00       	push   $0x32d
f0101bf7:	68 54 42 10 f0       	push   $0xf0104254
f0101bfc:	e8 8a e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c01:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c06:	89 f8                	mov    %edi,%eax
f0101c08:	e8 c3 ec ff ff       	call   f01008d0 <check_va2pa>
f0101c0d:	89 da                	mov    %ebx,%edx
f0101c0f:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101c15:	c1 fa 03             	sar    $0x3,%edx
f0101c18:	c1 e2 0c             	shl    $0xc,%edx
f0101c1b:	39 d0                	cmp    %edx,%eax
f0101c1d:	74 19                	je     f0101c38 <mem_init+0xcb5>
f0101c1f:	68 c4 3f 10 f0       	push   $0xf0103fc4
f0101c24:	68 7a 42 10 f0       	push   $0xf010427a
f0101c29:	68 2e 03 00 00       	push   $0x32e
f0101c2e:	68 54 42 10 f0       	push   $0xf0104254
f0101c33:	e8 53 e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101c38:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c3d:	74 19                	je     f0101c58 <mem_init+0xcd5>
f0101c3f:	68 39 44 10 f0       	push   $0xf0104439
f0101c44:	68 7a 42 10 f0       	push   $0xf010427a
f0101c49:	68 2f 03 00 00       	push   $0x32f
f0101c4e:	68 54 42 10 f0       	push   $0xf0104254
f0101c53:	e8 33 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c58:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c5d:	74 19                	je     f0101c78 <mem_init+0xcf5>
f0101c5f:	68 93 44 10 f0       	push   $0xf0104493
f0101c64:	68 7a 42 10 f0       	push   $0xf010427a
f0101c69:	68 30 03 00 00       	push   $0x330
f0101c6e:	68 54 42 10 f0       	push   $0xf0104254
f0101c73:	e8 13 e4 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101c78:	6a 00                	push   $0x0
f0101c7a:	68 00 10 00 00       	push   $0x1000
f0101c7f:	53                   	push   %ebx
f0101c80:	57                   	push   %edi
f0101c81:	e8 73 f2 ff ff       	call   f0100ef9 <page_insert>
f0101c86:	83 c4 10             	add    $0x10,%esp
f0101c89:	85 c0                	test   %eax,%eax
f0101c8b:	74 19                	je     f0101ca6 <mem_init+0xd23>
f0101c8d:	68 3c 40 10 f0       	push   $0xf010403c
f0101c92:	68 7a 42 10 f0       	push   $0xf010427a
f0101c97:	68 33 03 00 00       	push   $0x333
f0101c9c:	68 54 42 10 f0       	push   $0xf0104254
f0101ca1:	e8 e5 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101ca6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101cab:	75 19                	jne    f0101cc6 <mem_init+0xd43>
f0101cad:	68 a4 44 10 f0       	push   $0xf01044a4
f0101cb2:	68 7a 42 10 f0       	push   $0xf010427a
f0101cb7:	68 34 03 00 00       	push   $0x334
f0101cbc:	68 54 42 10 f0       	push   $0xf0104254
f0101cc1:	e8 c5 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101cc6:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101cc9:	74 19                	je     f0101ce4 <mem_init+0xd61>
f0101ccb:	68 b0 44 10 f0       	push   $0xf01044b0
f0101cd0:	68 7a 42 10 f0       	push   $0xf010427a
f0101cd5:	68 35 03 00 00       	push   $0x335
f0101cda:	68 54 42 10 f0       	push   $0xf0104254
f0101cdf:	e8 a7 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ce4:	83 ec 08             	sub    $0x8,%esp
f0101ce7:	68 00 10 00 00       	push   $0x1000
f0101cec:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101cf2:	e8 b7 f1 ff ff       	call   f0100eae <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cf7:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101cfd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d02:	89 f8                	mov    %edi,%eax
f0101d04:	e8 c7 eb ff ff       	call   f01008d0 <check_va2pa>
f0101d09:	83 c4 10             	add    $0x10,%esp
f0101d0c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d0f:	74 19                	je     f0101d2a <mem_init+0xda7>
f0101d11:	68 18 40 10 f0       	push   $0xf0104018
f0101d16:	68 7a 42 10 f0       	push   $0xf010427a
f0101d1b:	68 39 03 00 00       	push   $0x339
f0101d20:	68 54 42 10 f0       	push   $0xf0104254
f0101d25:	e8 61 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d2a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d2f:	89 f8                	mov    %edi,%eax
f0101d31:	e8 9a eb ff ff       	call   f01008d0 <check_va2pa>
f0101d36:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d39:	74 19                	je     f0101d54 <mem_init+0xdd1>
f0101d3b:	68 74 40 10 f0       	push   $0xf0104074
f0101d40:	68 7a 42 10 f0       	push   $0xf010427a
f0101d45:	68 3a 03 00 00       	push   $0x33a
f0101d4a:	68 54 42 10 f0       	push   $0xf0104254
f0101d4f:	e8 37 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101d54:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d59:	74 19                	je     f0101d74 <mem_init+0xdf1>
f0101d5b:	68 c5 44 10 f0       	push   $0xf01044c5
f0101d60:	68 7a 42 10 f0       	push   $0xf010427a
f0101d65:	68 3b 03 00 00       	push   $0x33b
f0101d6a:	68 54 42 10 f0       	push   $0xf0104254
f0101d6f:	e8 17 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d74:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d79:	74 19                	je     f0101d94 <mem_init+0xe11>
f0101d7b:	68 93 44 10 f0       	push   $0xf0104493
f0101d80:	68 7a 42 10 f0       	push   $0xf010427a
f0101d85:	68 3c 03 00 00       	push   $0x33c
f0101d8a:	68 54 42 10 f0       	push   $0xf0104254
f0101d8f:	e8 f7 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101d94:	83 ec 0c             	sub    $0xc,%esp
f0101d97:	6a 00                	push   $0x0
f0101d99:	e8 42 ef ff ff       	call   f0100ce0 <page_alloc>
f0101d9e:	83 c4 10             	add    $0x10,%esp
f0101da1:	85 c0                	test   %eax,%eax
f0101da3:	74 04                	je     f0101da9 <mem_init+0xe26>
f0101da5:	39 c3                	cmp    %eax,%ebx
f0101da7:	74 19                	je     f0101dc2 <mem_init+0xe3f>
f0101da9:	68 9c 40 10 f0       	push   $0xf010409c
f0101dae:	68 7a 42 10 f0       	push   $0xf010427a
f0101db3:	68 3f 03 00 00       	push   $0x33f
f0101db8:	68 54 42 10 f0       	push   $0xf0104254
f0101dbd:	e8 c9 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101dc2:	83 ec 0c             	sub    $0xc,%esp
f0101dc5:	6a 00                	push   $0x0
f0101dc7:	e8 14 ef ff ff       	call   f0100ce0 <page_alloc>
f0101dcc:	83 c4 10             	add    $0x10,%esp
f0101dcf:	85 c0                	test   %eax,%eax
f0101dd1:	74 19                	je     f0101dec <mem_init+0xe69>
f0101dd3:	68 e7 43 10 f0       	push   $0xf01043e7
f0101dd8:	68 7a 42 10 f0       	push   $0xf010427a
f0101ddd:	68 42 03 00 00       	push   $0x342
f0101de2:	68 54 42 10 f0       	push   $0xf0104254
f0101de7:	e8 9f e2 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101dec:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101df2:	8b 11                	mov    (%ecx),%edx
f0101df4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101dfa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dfd:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101e03:	c1 f8 03             	sar    $0x3,%eax
f0101e06:	c1 e0 0c             	shl    $0xc,%eax
f0101e09:	39 c2                	cmp    %eax,%edx
f0101e0b:	74 19                	je     f0101e26 <mem_init+0xea3>
f0101e0d:	68 40 3d 10 f0       	push   $0xf0103d40
f0101e12:	68 7a 42 10 f0       	push   $0xf010427a
f0101e17:	68 45 03 00 00       	push   $0x345
f0101e1c:	68 54 42 10 f0       	push   $0xf0104254
f0101e21:	e8 65 e2 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101e26:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e2c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e2f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e34:	74 19                	je     f0101e4f <mem_init+0xecc>
f0101e36:	68 4a 44 10 f0       	push   $0xf010444a
f0101e3b:	68 7a 42 10 f0       	push   $0xf010427a
f0101e40:	68 47 03 00 00       	push   $0x347
f0101e45:	68 54 42 10 f0       	push   $0xf0104254
f0101e4a:	e8 3c e2 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101e4f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e52:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e58:	83 ec 0c             	sub    $0xc,%esp
f0101e5b:	50                   	push   %eax
f0101e5c:	e8 ef ee ff ff       	call   f0100d50 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e61:	83 c4 0c             	add    $0xc,%esp
f0101e64:	6a 01                	push   $0x1
f0101e66:	68 00 10 40 00       	push   $0x401000
f0101e6b:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101e71:	e8 3c ef ff ff       	call   f0100db2 <pgdir_walk>
f0101e76:	89 c7                	mov    %eax,%edi
f0101e78:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e7b:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101e80:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e83:	8b 40 04             	mov    0x4(%eax),%eax
f0101e86:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e8b:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101e91:	89 c2                	mov    %eax,%edx
f0101e93:	c1 ea 0c             	shr    $0xc,%edx
f0101e96:	83 c4 10             	add    $0x10,%esp
f0101e99:	39 ca                	cmp    %ecx,%edx
f0101e9b:	72 15                	jb     f0101eb2 <mem_init+0xf2f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e9d:	50                   	push   %eax
f0101e9e:	68 dc 3a 10 f0       	push   $0xf0103adc
f0101ea3:	68 4e 03 00 00       	push   $0x34e
f0101ea8:	68 54 42 10 f0       	push   $0xf0104254
f0101ead:	e8 d9 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101eb2:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101eb7:	39 c7                	cmp    %eax,%edi
f0101eb9:	74 19                	je     f0101ed4 <mem_init+0xf51>
f0101ebb:	68 d6 44 10 f0       	push   $0xf01044d6
f0101ec0:	68 7a 42 10 f0       	push   $0xf010427a
f0101ec5:	68 4f 03 00 00       	push   $0x34f
f0101eca:	68 54 42 10 f0       	push   $0xf0104254
f0101ecf:	e8 b7 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101ed4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ed7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101ede:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ee7:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101eed:	c1 f8 03             	sar    $0x3,%eax
f0101ef0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ef3:	89 c2                	mov    %eax,%edx
f0101ef5:	c1 ea 0c             	shr    $0xc,%edx
f0101ef8:	39 d1                	cmp    %edx,%ecx
f0101efa:	77 12                	ja     f0101f0e <mem_init+0xf8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101efc:	50                   	push   %eax
f0101efd:	68 dc 3a 10 f0       	push   $0xf0103adc
f0101f02:	6a 52                	push   $0x52
f0101f04:	68 60 42 10 f0       	push   $0xf0104260
f0101f09:	e8 7d e1 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f0e:	83 ec 04             	sub    $0x4,%esp
f0101f11:	68 00 10 00 00       	push   $0x1000
f0101f16:	68 ff 00 00 00       	push   $0xff
f0101f1b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f20:	50                   	push   %eax
f0101f21:	e8 69 12 00 00       	call   f010318f <memset>
	page_free(pp0);
f0101f26:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101f29:	89 3c 24             	mov    %edi,(%esp)
f0101f2c:	e8 1f ee ff ff       	call   f0100d50 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f31:	83 c4 0c             	add    $0xc,%esp
f0101f34:	6a 01                	push   $0x1
f0101f36:	6a 00                	push   $0x0
f0101f38:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f3e:	e8 6f ee ff ff       	call   f0100db2 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f43:	89 fa                	mov    %edi,%edx
f0101f45:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101f4b:	c1 fa 03             	sar    $0x3,%edx
f0101f4e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f51:	89 d0                	mov    %edx,%eax
f0101f53:	c1 e8 0c             	shr    $0xc,%eax
f0101f56:	83 c4 10             	add    $0x10,%esp
f0101f59:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0101f5f:	72 12                	jb     f0101f73 <mem_init+0xff0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f61:	52                   	push   %edx
f0101f62:	68 dc 3a 10 f0       	push   $0xf0103adc
f0101f67:	6a 52                	push   $0x52
f0101f69:	68 60 42 10 f0       	push   $0xf0104260
f0101f6e:	e8 18 e1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0101f73:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f7c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f82:	f6 00 01             	testb  $0x1,(%eax)
f0101f85:	74 19                	je     f0101fa0 <mem_init+0x101d>
f0101f87:	68 ee 44 10 f0       	push   $0xf01044ee
f0101f8c:	68 7a 42 10 f0       	push   $0xf010427a
f0101f91:	68 59 03 00 00       	push   $0x359
f0101f96:	68 54 42 10 f0       	push   $0xf0104254
f0101f9b:	e8 eb e0 ff ff       	call   f010008b <_panic>
f0101fa0:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101fa3:	39 c2                	cmp    %eax,%edx
f0101fa5:	75 db                	jne    f0101f82 <mem_init+0xfff>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101fa7:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101fac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101fb2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fb5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101fbb:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101fbe:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101fc4:	83 ec 0c             	sub    $0xc,%esp
f0101fc7:	50                   	push   %eax
f0101fc8:	e8 83 ed ff ff       	call   f0100d50 <page_free>
	page_free(pp1);
f0101fcd:	89 1c 24             	mov    %ebx,(%esp)
f0101fd0:	e8 7b ed ff ff       	call   f0100d50 <page_free>
	page_free(pp2);
f0101fd5:	89 34 24             	mov    %esi,(%esp)
f0101fd8:	e8 73 ed ff ff       	call   f0100d50 <page_free>

	cprintf("check_page() succeeded!\n");
f0101fdd:	c7 04 24 05 45 10 f0 	movl   $0xf0104505,(%esp)
f0101fe4:	e8 bd 06 00 00       	call   f01026a6 <cprintf>
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
int perm = PTE_U | PTE_P;  
    int i=0;  
     n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);  
f0101fe9:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101fee:	8d 34 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%esi
f0101ff5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    for(i=0; i<n; i= i+PGSIZE)  
f0101ffb:	83 c4 10             	add    $0x10,%esp
f0101ffe:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102003:	eb 6a                	jmp    f010206f <mem_init+0x10ec>
f0102005:	8d 8b 00 00 00 ef    	lea    -0x11000000(%ebx),%ecx
        page_insert(kern_pgdir, pa2page(PADDR(pages) + i), (void *) (UPAGES +i), perm);  
f010200b:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102011:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102017:	77 15                	ja     f010202e <mem_init+0x10ab>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102019:	52                   	push   %edx
f010201a:	68 44 3c 10 f0       	push   $0xf0103c44
f010201f:	68 ad 00 00 00       	push   $0xad
f0102024:	68 54 42 10 f0       	push   $0xf0104254
f0102029:	e8 5d e0 ff ff       	call   f010008b <_panic>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010202e:	8d 84 02 00 00 00 10 	lea    0x10000000(%edx,%eax,1),%eax
f0102035:	c1 e8 0c             	shr    $0xc,%eax
f0102038:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f010203e:	72 14                	jb     f0102054 <mem_init+0x10d1>
		panic("pa2page called with invalid pa");
f0102040:	83 ec 04             	sub    $0x4,%esp
f0102043:	68 e8 3b 10 f0       	push   $0xf0103be8
f0102048:	6a 4b                	push   $0x4b
f010204a:	68 60 42 10 f0       	push   $0xf0104260
f010204f:	e8 37 e0 ff ff       	call   f010008b <_panic>
f0102054:	6a 05                	push   $0x5
f0102056:	51                   	push   %ecx
f0102057:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010205a:	50                   	push   %eax
f010205b:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102061:	e8 93 ee ff ff       	call   f0100ef9 <page_insert>
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
int perm = PTE_U | PTE_P;  
    int i=0;  
     n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);  
    for(i=0; i<n; i= i+PGSIZE)  
f0102066:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010206c:	83 c4 10             	add    $0x10,%esp
f010206f:	89 d8                	mov    %ebx,%eax
f0102071:	39 de                	cmp    %ebx,%esi
f0102073:	77 90                	ja     f0102005 <mem_init+0x1082>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102075:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f010207a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010207f:	77 15                	ja     f0102096 <mem_init+0x1113>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102081:	50                   	push   %eax
f0102082:	68 44 3c 10 f0       	push   $0xf0103c44
f0102087:	68 bb 00 00 00       	push   $0xbb
f010208c:	68 54 42 10 f0       	push   $0xf0104254
f0102091:	e8 f5 df ff ff       	call   f010008b <_panic>
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
perm =0;  
perm = PTE_P |PTE_W;  
boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, ROUNDUP(KSTKSIZE, PGSIZE), PADDR(bootstack), perm);  
f0102096:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f010209c:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
f01020a1:	8d b3 00 40 11 10    	lea    0x10114000(%ebx),%esi
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)  
{  
      
    while(size)  
    {  
        pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);  
f01020a7:	83 ec 04             	sub    $0x4,%esp
f01020aa:	6a 01                	push   $0x1
f01020ac:	53                   	push   %ebx
f01020ad:	57                   	push   %edi
f01020ae:	e8 ff ec ff ff       	call   f0100db2 <pgdir_walk>
        if(pte == NULL)  
f01020b3:	83 c4 10             	add    $0x10,%esp
f01020b6:	85 c0                	test   %eax,%eax
f01020b8:	74 13                	je     f01020cd <mem_init+0x114a>
            return;  
        *pte= pa |perm|PTE_P;  
f01020ba:	83 ce 03             	or     $0x3,%esi
f01020bd:	89 30                	mov    %esi,(%eax)
          
        size -= PGSIZE;  
        pa  += PGSIZE;  
        va  += PGSIZE;  
f01020bf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
// Hint: the TA solution uses pgdir_walk
static void  
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)  
{  
      
    while(size)  
f01020c5:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01020cb:	75 d4                	jne    f01020a1 <mem_init+0x111e>
int size = ~0;  
size = size - KERNBASE +1;  
size = ROUNDUP(size, PGSIZE);  
perm = 0;  
perm = PTE_P | PTE_W;  
boot_map_region(kern_pgdir, KERNBASE, size, 0, perm );  
f01020cd:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f01020d3:	bb 00 00 00 f0       	mov    $0xf0000000,%ebx
f01020d8:	8d b3 00 00 00 10    	lea    0x10000000(%ebx),%esi
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)  
{  
      
    while(size)  
    {  
        pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);  
f01020de:	83 ec 04             	sub    $0x4,%esp
f01020e1:	6a 01                	push   $0x1
f01020e3:	53                   	push   %ebx
f01020e4:	57                   	push   %edi
f01020e5:	e8 c8 ec ff ff       	call   f0100db2 <pgdir_walk>
        if(pte == NULL)  
f01020ea:	83 c4 10             	add    $0x10,%esp
f01020ed:	85 c0                	test   %eax,%eax
f01020ef:	74 0d                	je     f01020fe <mem_init+0x117b>
            return;  
        *pte= pa |perm|PTE_P;  
f01020f1:	83 ce 03             	or     $0x3,%esi
f01020f4:	89 30                	mov    %esi,(%eax)
// Hint: the TA solution uses pgdir_walk
static void  
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)  
{  
      
    while(size)  
f01020f6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01020fc:	75 da                	jne    f01020d8 <mem_init+0x1155>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01020fe:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102104:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0102109:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010210c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102113:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102118:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010211b:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102121:	89 7d d0             	mov    %edi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102124:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102129:	eb 55                	jmp    f0102180 <mem_init+0x11fd>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010212b:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102131:	89 f0                	mov    %esi,%eax
f0102133:	e8 98 e7 ff ff       	call   f01008d0 <check_va2pa>
f0102138:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010213f:	77 15                	ja     f0102156 <mem_init+0x11d3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102141:	57                   	push   %edi
f0102142:	68 44 3c 10 f0       	push   $0xf0103c44
f0102147:	68 9b 02 00 00       	push   $0x29b
f010214c:	68 54 42 10 f0       	push   $0xf0104254
f0102151:	e8 35 df ff ff       	call   f010008b <_panic>
f0102156:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010215d:	39 c2                	cmp    %eax,%edx
f010215f:	74 19                	je     f010217a <mem_init+0x11f7>
f0102161:	68 c0 40 10 f0       	push   $0xf01040c0
f0102166:	68 7a 42 10 f0       	push   $0xf010427a
f010216b:	68 9b 02 00 00       	push   $0x29b
f0102170:	68 54 42 10 f0       	push   $0xf0104254
f0102175:	e8 11 df ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010217a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102180:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102183:	77 a6                	ja     f010212b <mem_init+0x11a8>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102185:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102188:	c1 e7 0c             	shl    $0xc,%edi
f010218b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102190:	eb 30                	jmp    f01021c2 <mem_init+0x123f>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102192:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102198:	89 f0                	mov    %esi,%eax
f010219a:	e8 31 e7 ff ff       	call   f01008d0 <check_va2pa>
f010219f:	39 c3                	cmp    %eax,%ebx
f01021a1:	74 19                	je     f01021bc <mem_init+0x1239>
f01021a3:	68 f4 40 10 f0       	push   $0xf01040f4
f01021a8:	68 7a 42 10 f0       	push   $0xf010427a
f01021ad:	68 a0 02 00 00       	push   $0x2a0
f01021b2:	68 54 42 10 f0       	push   $0xf0104254
f01021b7:	e8 cf de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021bc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021c2:	39 fb                	cmp    %edi,%ebx
f01021c4:	72 cc                	jb     f0102192 <mem_init+0x120f>
f01021c6:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01021cb:	89 da                	mov    %ebx,%edx
f01021cd:	89 f0                	mov    %esi,%eax
f01021cf:	e8 fc e6 ff ff       	call   f01008d0 <check_va2pa>
f01021d4:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f01021da:	39 c2                	cmp    %eax,%edx
f01021dc:	74 19                	je     f01021f7 <mem_init+0x1274>
f01021de:	68 1c 41 10 f0       	push   $0xf010411c
f01021e3:	68 7a 42 10 f0       	push   $0xf010427a
f01021e8:	68 a4 02 00 00       	push   $0x2a4
f01021ed:	68 54 42 10 f0       	push   $0xf0104254
f01021f2:	e8 94 de ff ff       	call   f010008b <_panic>
f01021f7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01021fd:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102203:	75 c6                	jne    f01021cb <mem_init+0x1248>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102205:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010220a:	89 f0                	mov    %esi,%eax
f010220c:	e8 bf e6 ff ff       	call   f01008d0 <check_va2pa>
f0102211:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102214:	74 51                	je     f0102267 <mem_init+0x12e4>
f0102216:	68 64 41 10 f0       	push   $0xf0104164
f010221b:	68 7a 42 10 f0       	push   $0xf010427a
f0102220:	68 a5 02 00 00       	push   $0x2a5
f0102225:	68 54 42 10 f0       	push   $0xf0104254
f010222a:	e8 5c de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010222f:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102234:	72 36                	jb     f010226c <mem_init+0x12e9>
f0102236:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010223b:	76 07                	jbe    f0102244 <mem_init+0x12c1>
f010223d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102242:	75 28                	jne    f010226c <mem_init+0x12e9>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102244:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102248:	0f 85 83 00 00 00    	jne    f01022d1 <mem_init+0x134e>
f010224e:	68 1e 45 10 f0       	push   $0xf010451e
f0102253:	68 7a 42 10 f0       	push   $0xf010427a
f0102258:	68 ad 02 00 00       	push   $0x2ad
f010225d:	68 54 42 10 f0       	push   $0xf0104254
f0102262:	e8 24 de ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102267:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010226c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102271:	76 3f                	jbe    f01022b2 <mem_init+0x132f>
				assert(pgdir[i] & PTE_P);
f0102273:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102276:	f6 c2 01             	test   $0x1,%dl
f0102279:	75 19                	jne    f0102294 <mem_init+0x1311>
f010227b:	68 1e 45 10 f0       	push   $0xf010451e
f0102280:	68 7a 42 10 f0       	push   $0xf010427a
f0102285:	68 b1 02 00 00       	push   $0x2b1
f010228a:	68 54 42 10 f0       	push   $0xf0104254
f010228f:	e8 f7 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102294:	f6 c2 02             	test   $0x2,%dl
f0102297:	75 38                	jne    f01022d1 <mem_init+0x134e>
f0102299:	68 2f 45 10 f0       	push   $0xf010452f
f010229e:	68 7a 42 10 f0       	push   $0xf010427a
f01022a3:	68 b2 02 00 00       	push   $0x2b2
f01022a8:	68 54 42 10 f0       	push   $0xf0104254
f01022ad:	e8 d9 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f01022b2:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f01022b6:	74 19                	je     f01022d1 <mem_init+0x134e>
f01022b8:	68 40 45 10 f0       	push   $0xf0104540
f01022bd:	68 7a 42 10 f0       	push   $0xf010427a
f01022c2:	68 b4 02 00 00       	push   $0x2b4
f01022c7:	68 54 42 10 f0       	push   $0xf0104254
f01022cc:	e8 ba dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01022d1:	83 c0 01             	add    $0x1,%eax
f01022d4:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01022d9:	0f 86 50 ff ff ff    	jbe    f010222f <mem_init+0x12ac>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01022df:	83 ec 0c             	sub    $0xc,%esp
f01022e2:	68 94 41 10 f0       	push   $0xf0104194
f01022e7:	e8 ba 03 00 00       	call   f01026a6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01022ec:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022f1:	83 c4 10             	add    $0x10,%esp
f01022f4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01022f9:	77 15                	ja     f0102310 <mem_init+0x138d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022fb:	50                   	push   %eax
f01022fc:	68 44 3c 10 f0       	push   $0xf0103c44
f0102301:	68 d4 00 00 00       	push   $0xd4
f0102306:	68 54 42 10 f0       	push   $0xf0104254
f010230b:	e8 7b dd ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102310:	05 00 00 00 10       	add    $0x10000000,%eax
f0102315:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102318:	b8 00 00 00 00       	mov    $0x0,%eax
f010231d:	e8 12 e6 ff ff       	call   f0100934 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102322:	0f 20 c0             	mov    %cr0,%eax
f0102325:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102328:	0d 23 00 05 80       	or     $0x80050023,%eax
f010232d:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102330:	83 ec 0c             	sub    $0xc,%esp
f0102333:	6a 00                	push   $0x0
f0102335:	e8 a6 e9 ff ff       	call   f0100ce0 <page_alloc>
f010233a:	89 c3                	mov    %eax,%ebx
f010233c:	83 c4 10             	add    $0x10,%esp
f010233f:	85 c0                	test   %eax,%eax
f0102341:	75 19                	jne    f010235c <mem_init+0x13d9>
f0102343:	68 3c 43 10 f0       	push   $0xf010433c
f0102348:	68 7a 42 10 f0       	push   $0xf010427a
f010234d:	68 74 03 00 00       	push   $0x374
f0102352:	68 54 42 10 f0       	push   $0xf0104254
f0102357:	e8 2f dd ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010235c:	83 ec 0c             	sub    $0xc,%esp
f010235f:	6a 00                	push   $0x0
f0102361:	e8 7a e9 ff ff       	call   f0100ce0 <page_alloc>
f0102366:	89 c7                	mov    %eax,%edi
f0102368:	83 c4 10             	add    $0x10,%esp
f010236b:	85 c0                	test   %eax,%eax
f010236d:	75 19                	jne    f0102388 <mem_init+0x1405>
f010236f:	68 52 43 10 f0       	push   $0xf0104352
f0102374:	68 7a 42 10 f0       	push   $0xf010427a
f0102379:	68 75 03 00 00       	push   $0x375
f010237e:	68 54 42 10 f0       	push   $0xf0104254
f0102383:	e8 03 dd ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102388:	83 ec 0c             	sub    $0xc,%esp
f010238b:	6a 00                	push   $0x0
f010238d:	e8 4e e9 ff ff       	call   f0100ce0 <page_alloc>
f0102392:	89 c6                	mov    %eax,%esi
f0102394:	83 c4 10             	add    $0x10,%esp
f0102397:	85 c0                	test   %eax,%eax
f0102399:	75 19                	jne    f01023b4 <mem_init+0x1431>
f010239b:	68 68 43 10 f0       	push   $0xf0104368
f01023a0:	68 7a 42 10 f0       	push   $0xf010427a
f01023a5:	68 76 03 00 00       	push   $0x376
f01023aa:	68 54 42 10 f0       	push   $0xf0104254
f01023af:	e8 d7 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f01023b4:	83 ec 0c             	sub    $0xc,%esp
f01023b7:	53                   	push   %ebx
f01023b8:	e8 93 e9 ff ff       	call   f0100d50 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023bd:	89 f8                	mov    %edi,%eax
f01023bf:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01023c5:	c1 f8 03             	sar    $0x3,%eax
f01023c8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023cb:	89 c2                	mov    %eax,%edx
f01023cd:	c1 ea 0c             	shr    $0xc,%edx
f01023d0:	83 c4 10             	add    $0x10,%esp
f01023d3:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01023d9:	72 12                	jb     f01023ed <mem_init+0x146a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023db:	50                   	push   %eax
f01023dc:	68 dc 3a 10 f0       	push   $0xf0103adc
f01023e1:	6a 52                	push   $0x52
f01023e3:	68 60 42 10 f0       	push   $0xf0104260
f01023e8:	e8 9e dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01023ed:	83 ec 04             	sub    $0x4,%esp
f01023f0:	68 00 10 00 00       	push   $0x1000
f01023f5:	6a 01                	push   $0x1
f01023f7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023fc:	50                   	push   %eax
f01023fd:	e8 8d 0d 00 00       	call   f010318f <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102402:	89 f0                	mov    %esi,%eax
f0102404:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010240a:	c1 f8 03             	sar    $0x3,%eax
f010240d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102410:	89 c2                	mov    %eax,%edx
f0102412:	c1 ea 0c             	shr    $0xc,%edx
f0102415:	83 c4 10             	add    $0x10,%esp
f0102418:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010241e:	72 12                	jb     f0102432 <mem_init+0x14af>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102420:	50                   	push   %eax
f0102421:	68 dc 3a 10 f0       	push   $0xf0103adc
f0102426:	6a 52                	push   $0x52
f0102428:	68 60 42 10 f0       	push   $0xf0104260
f010242d:	e8 59 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102432:	83 ec 04             	sub    $0x4,%esp
f0102435:	68 00 10 00 00       	push   $0x1000
f010243a:	6a 02                	push   $0x2
f010243c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102441:	50                   	push   %eax
f0102442:	e8 48 0d 00 00       	call   f010318f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102447:	6a 02                	push   $0x2
f0102449:	68 00 10 00 00       	push   $0x1000
f010244e:	57                   	push   %edi
f010244f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102455:	e8 9f ea ff ff       	call   f0100ef9 <page_insert>
	assert(pp1->pp_ref == 1);
f010245a:	83 c4 20             	add    $0x20,%esp
f010245d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102462:	74 19                	je     f010247d <mem_init+0x14fa>
f0102464:	68 39 44 10 f0       	push   $0xf0104439
f0102469:	68 7a 42 10 f0       	push   $0xf010427a
f010246e:	68 7b 03 00 00       	push   $0x37b
f0102473:	68 54 42 10 f0       	push   $0xf0104254
f0102478:	e8 0e dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010247d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102484:	01 01 01 
f0102487:	74 19                	je     f01024a2 <mem_init+0x151f>
f0102489:	68 b4 41 10 f0       	push   $0xf01041b4
f010248e:	68 7a 42 10 f0       	push   $0xf010427a
f0102493:	68 7c 03 00 00       	push   $0x37c
f0102498:	68 54 42 10 f0       	push   $0xf0104254
f010249d:	e8 e9 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01024a2:	6a 02                	push   $0x2
f01024a4:	68 00 10 00 00       	push   $0x1000
f01024a9:	56                   	push   %esi
f01024aa:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024b0:	e8 44 ea ff ff       	call   f0100ef9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01024b5:	83 c4 10             	add    $0x10,%esp
f01024b8:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01024bf:	02 02 02 
f01024c2:	74 19                	je     f01024dd <mem_init+0x155a>
f01024c4:	68 d8 41 10 f0       	push   $0xf01041d8
f01024c9:	68 7a 42 10 f0       	push   $0xf010427a
f01024ce:	68 7e 03 00 00       	push   $0x37e
f01024d3:	68 54 42 10 f0       	push   $0xf0104254
f01024d8:	e8 ae db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01024dd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01024e2:	74 19                	je     f01024fd <mem_init+0x157a>
f01024e4:	68 5b 44 10 f0       	push   $0xf010445b
f01024e9:	68 7a 42 10 f0       	push   $0xf010427a
f01024ee:	68 7f 03 00 00       	push   $0x37f
f01024f3:	68 54 42 10 f0       	push   $0xf0104254
f01024f8:	e8 8e db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01024fd:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102502:	74 19                	je     f010251d <mem_init+0x159a>
f0102504:	68 c5 44 10 f0       	push   $0xf01044c5
f0102509:	68 7a 42 10 f0       	push   $0xf010427a
f010250e:	68 80 03 00 00       	push   $0x380
f0102513:	68 54 42 10 f0       	push   $0xf0104254
f0102518:	e8 6e db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010251d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102524:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102527:	89 f0                	mov    %esi,%eax
f0102529:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010252f:	c1 f8 03             	sar    $0x3,%eax
f0102532:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102535:	89 c2                	mov    %eax,%edx
f0102537:	c1 ea 0c             	shr    $0xc,%edx
f010253a:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102540:	72 12                	jb     f0102554 <mem_init+0x15d1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102542:	50                   	push   %eax
f0102543:	68 dc 3a 10 f0       	push   $0xf0103adc
f0102548:	6a 52                	push   $0x52
f010254a:	68 60 42 10 f0       	push   $0xf0104260
f010254f:	e8 37 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102554:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010255b:	03 03 03 
f010255e:	74 19                	je     f0102579 <mem_init+0x15f6>
f0102560:	68 fc 41 10 f0       	push   $0xf01041fc
f0102565:	68 7a 42 10 f0       	push   $0xf010427a
f010256a:	68 82 03 00 00       	push   $0x382
f010256f:	68 54 42 10 f0       	push   $0xf0104254
f0102574:	e8 12 db ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102579:	83 ec 08             	sub    $0x8,%esp
f010257c:	68 00 10 00 00       	push   $0x1000
f0102581:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102587:	e8 22 e9 ff ff       	call   f0100eae <page_remove>
	assert(pp2->pp_ref == 0);
f010258c:	83 c4 10             	add    $0x10,%esp
f010258f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102594:	74 19                	je     f01025af <mem_init+0x162c>
f0102596:	68 93 44 10 f0       	push   $0xf0104493
f010259b:	68 7a 42 10 f0       	push   $0xf010427a
f01025a0:	68 84 03 00 00       	push   $0x384
f01025a5:	68 54 42 10 f0       	push   $0xf0104254
f01025aa:	e8 dc da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025af:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f01025b5:	8b 11                	mov    (%ecx),%edx
f01025b7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01025bd:	89 d8                	mov    %ebx,%eax
f01025bf:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01025c5:	c1 f8 03             	sar    $0x3,%eax
f01025c8:	c1 e0 0c             	shl    $0xc,%eax
f01025cb:	39 c2                	cmp    %eax,%edx
f01025cd:	74 19                	je     f01025e8 <mem_init+0x1665>
f01025cf:	68 40 3d 10 f0       	push   $0xf0103d40
f01025d4:	68 7a 42 10 f0       	push   $0xf010427a
f01025d9:	68 87 03 00 00       	push   $0x387
f01025de:	68 54 42 10 f0       	push   $0xf0104254
f01025e3:	e8 a3 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01025e8:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01025ee:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01025f3:	74 19                	je     f010260e <mem_init+0x168b>
f01025f5:	68 4a 44 10 f0       	push   $0xf010444a
f01025fa:	68 7a 42 10 f0       	push   $0xf010427a
f01025ff:	68 89 03 00 00       	push   $0x389
f0102604:	68 54 42 10 f0       	push   $0xf0104254
f0102609:	e8 7d da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010260e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102614:	83 ec 0c             	sub    $0xc,%esp
f0102617:	53                   	push   %ebx
f0102618:	e8 33 e7 ff ff       	call   f0100d50 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010261d:	c7 04 24 28 42 10 f0 	movl   $0xf0104228,(%esp)
f0102624:	e8 7d 00 00 00       	call   f01026a6 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102629:	83 c4 10             	add    $0x10,%esp
f010262c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010262f:	5b                   	pop    %ebx
f0102630:	5e                   	pop    %esi
f0102631:	5f                   	pop    %edi
f0102632:	5d                   	pop    %ebp
f0102633:	c3                   	ret    

f0102634 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102634:	55                   	push   %ebp
f0102635:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102637:	8b 45 0c             	mov    0xc(%ebp),%eax
f010263a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010263d:	5d                   	pop    %ebp
f010263e:	c3                   	ret    

f010263f <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010263f:	55                   	push   %ebp
f0102640:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102642:	ba 70 00 00 00       	mov    $0x70,%edx
f0102647:	8b 45 08             	mov    0x8(%ebp),%eax
f010264a:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010264b:	ba 71 00 00 00       	mov    $0x71,%edx
f0102650:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102651:	0f b6 c0             	movzbl %al,%eax
}
f0102654:	5d                   	pop    %ebp
f0102655:	c3                   	ret    

f0102656 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102656:	55                   	push   %ebp
f0102657:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102659:	ba 70 00 00 00       	mov    $0x70,%edx
f010265e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102661:	ee                   	out    %al,(%dx)
f0102662:	ba 71 00 00 00       	mov    $0x71,%edx
f0102667:	8b 45 0c             	mov    0xc(%ebp),%eax
f010266a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010266b:	5d                   	pop    %ebp
f010266c:	c3                   	ret    

f010266d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010266d:	55                   	push   %ebp
f010266e:	89 e5                	mov    %esp,%ebp
f0102670:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102673:	ff 75 08             	pushl  0x8(%ebp)
f0102676:	e8 85 df ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f010267b:	83 c4 10             	add    $0x10,%esp
f010267e:	c9                   	leave  
f010267f:	c3                   	ret    

f0102680 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102680:	55                   	push   %ebp
f0102681:	89 e5                	mov    %esp,%ebp
f0102683:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102686:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010268d:	ff 75 0c             	pushl  0xc(%ebp)
f0102690:	ff 75 08             	pushl  0x8(%ebp)
f0102693:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102696:	50                   	push   %eax
f0102697:	68 6d 26 10 f0       	push   $0xf010266d
f010269c:	e8 c9 03 00 00       	call   f0102a6a <vprintfmt>
	return cnt;
}
f01026a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026a4:	c9                   	leave  
f01026a5:	c3                   	ret    

f01026a6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01026a6:	55                   	push   %ebp
f01026a7:	89 e5                	mov    %esp,%ebp
f01026a9:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01026ac:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01026af:	50                   	push   %eax
f01026b0:	ff 75 08             	pushl  0x8(%ebp)
f01026b3:	e8 c8 ff ff ff       	call   f0102680 <vcprintf>
	va_end(ap);

	return cnt;
}
f01026b8:	c9                   	leave  
f01026b9:	c3                   	ret    

f01026ba <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01026ba:	55                   	push   %ebp
f01026bb:	89 e5                	mov    %esp,%ebp
f01026bd:	57                   	push   %edi
f01026be:	56                   	push   %esi
f01026bf:	53                   	push   %ebx
f01026c0:	83 ec 14             	sub    $0x14,%esp
f01026c3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01026c6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01026c9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01026cc:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01026cf:	8b 1a                	mov    (%edx),%ebx
f01026d1:	8b 01                	mov    (%ecx),%eax
f01026d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01026d6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01026dd:	eb 7f                	jmp    f010275e <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01026df:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01026e2:	01 d8                	add    %ebx,%eax
f01026e4:	89 c6                	mov    %eax,%esi
f01026e6:	c1 ee 1f             	shr    $0x1f,%esi
f01026e9:	01 c6                	add    %eax,%esi
f01026eb:	d1 fe                	sar    %esi
f01026ed:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01026f0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01026f3:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01026f6:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01026f8:	eb 03                	jmp    f01026fd <stab_binsearch+0x43>
			m--;
f01026fa:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01026fd:	39 c3                	cmp    %eax,%ebx
f01026ff:	7f 0d                	jg     f010270e <stab_binsearch+0x54>
f0102701:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102705:	83 ea 0c             	sub    $0xc,%edx
f0102708:	39 f9                	cmp    %edi,%ecx
f010270a:	75 ee                	jne    f01026fa <stab_binsearch+0x40>
f010270c:	eb 05                	jmp    f0102713 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010270e:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102711:	eb 4b                	jmp    f010275e <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102713:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102716:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102719:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010271d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102720:	76 11                	jbe    f0102733 <stab_binsearch+0x79>
			*region_left = m;
f0102722:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102725:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102727:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010272a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102731:	eb 2b                	jmp    f010275e <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102733:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102736:	73 14                	jae    f010274c <stab_binsearch+0x92>
			*region_right = m - 1;
f0102738:	83 e8 01             	sub    $0x1,%eax
f010273b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010273e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102741:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102743:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010274a:	eb 12                	jmp    f010275e <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010274c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010274f:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102751:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102755:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102757:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010275e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102761:	0f 8e 78 ff ff ff    	jle    f01026df <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102767:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010276b:	75 0f                	jne    f010277c <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010276d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102770:	8b 00                	mov    (%eax),%eax
f0102772:	83 e8 01             	sub    $0x1,%eax
f0102775:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102778:	89 06                	mov    %eax,(%esi)
f010277a:	eb 2c                	jmp    f01027a8 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010277c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010277f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102781:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102784:	8b 0e                	mov    (%esi),%ecx
f0102786:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102789:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010278c:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010278f:	eb 03                	jmp    f0102794 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102791:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102794:	39 c8                	cmp    %ecx,%eax
f0102796:	7e 0b                	jle    f01027a3 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102798:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010279c:	83 ea 0c             	sub    $0xc,%edx
f010279f:	39 df                	cmp    %ebx,%edi
f01027a1:	75 ee                	jne    f0102791 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01027a3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027a6:	89 06                	mov    %eax,(%esi)
	}
}
f01027a8:	83 c4 14             	add    $0x14,%esp
f01027ab:	5b                   	pop    %ebx
f01027ac:	5e                   	pop    %esi
f01027ad:	5f                   	pop    %edi
f01027ae:	5d                   	pop    %ebp
f01027af:	c3                   	ret    

f01027b0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01027b0:	55                   	push   %ebp
f01027b1:	89 e5                	mov    %esp,%ebp
f01027b3:	57                   	push   %edi
f01027b4:	56                   	push   %esi
f01027b5:	53                   	push   %ebx
f01027b6:	83 ec 1c             	sub    $0x1c,%esp
f01027b9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01027bc:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01027bf:	c7 06 4e 45 10 f0    	movl   $0xf010454e,(%esi)
	info->eip_line = 0;
f01027c5:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01027cc:	c7 46 08 4e 45 10 f0 	movl   $0xf010454e,0x8(%esi)
	info->eip_fn_namelen = 9;
f01027d3:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01027da:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01027dd:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01027e4:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01027ea:	76 11                	jbe    f01027fd <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01027ec:	b8 a5 bd 10 f0       	mov    $0xf010bda5,%eax
f01027f1:	3d 71 a0 10 f0       	cmp    $0xf010a071,%eax
f01027f6:	77 19                	ja     f0102811 <debuginfo_eip+0x61>
f01027f8:	e9 62 01 00 00       	jmp    f010295f <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01027fd:	83 ec 04             	sub    $0x4,%esp
f0102800:	68 58 45 10 f0       	push   $0xf0104558
f0102805:	6a 7f                	push   $0x7f
f0102807:	68 65 45 10 f0       	push   $0xf0104565
f010280c:	e8 7a d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102811:	80 3d a4 bd 10 f0 00 	cmpb   $0x0,0xf010bda4
f0102818:	0f 85 48 01 00 00    	jne    f0102966 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010281e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102825:	b8 70 a0 10 f0       	mov    $0xf010a070,%eax
f010282a:	2d 84 47 10 f0       	sub    $0xf0104784,%eax
f010282f:	c1 f8 02             	sar    $0x2,%eax
f0102832:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102838:	83 e8 01             	sub    $0x1,%eax
f010283b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010283e:	83 ec 08             	sub    $0x8,%esp
f0102841:	57                   	push   %edi
f0102842:	6a 64                	push   $0x64
f0102844:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102847:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010284a:	b8 84 47 10 f0       	mov    $0xf0104784,%eax
f010284f:	e8 66 fe ff ff       	call   f01026ba <stab_binsearch>
	if (lfile == 0)
f0102854:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102857:	83 c4 10             	add    $0x10,%esp
f010285a:	85 c0                	test   %eax,%eax
f010285c:	0f 84 0b 01 00 00    	je     f010296d <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102862:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102865:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102868:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010286b:	83 ec 08             	sub    $0x8,%esp
f010286e:	57                   	push   %edi
f010286f:	6a 24                	push   $0x24
f0102871:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102874:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102877:	b8 84 47 10 f0       	mov    $0xf0104784,%eax
f010287c:	e8 39 fe ff ff       	call   f01026ba <stab_binsearch>

	if (lfun <= rfun) {
f0102881:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102884:	83 c4 10             	add    $0x10,%esp
f0102887:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010288a:	7f 31                	jg     f01028bd <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010288c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010288f:	c1 e0 02             	shl    $0x2,%eax
f0102892:	8d 90 84 47 10 f0    	lea    -0xfefb87c(%eax),%edx
f0102898:	8b 88 84 47 10 f0    	mov    -0xfefb87c(%eax),%ecx
f010289e:	b8 a5 bd 10 f0       	mov    $0xf010bda5,%eax
f01028a3:	2d 71 a0 10 f0       	sub    $0xf010a071,%eax
f01028a8:	39 c1                	cmp    %eax,%ecx
f01028aa:	73 09                	jae    f01028b5 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01028ac:	81 c1 71 a0 10 f0    	add    $0xf010a071,%ecx
f01028b2:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01028b5:	8b 42 08             	mov    0x8(%edx),%eax
f01028b8:	89 46 10             	mov    %eax,0x10(%esi)
f01028bb:	eb 06                	jmp    f01028c3 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01028bd:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01028c0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01028c3:	83 ec 08             	sub    $0x8,%esp
f01028c6:	6a 3a                	push   $0x3a
f01028c8:	ff 76 08             	pushl  0x8(%esi)
f01028cb:	e8 a3 08 00 00       	call   f0103173 <strfind>
f01028d0:	2b 46 08             	sub    0x8(%esi),%eax
f01028d3:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01028d6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01028d9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028dc:	8d 04 85 84 47 10 f0 	lea    -0xfefb87c(,%eax,4),%eax
f01028e3:	83 c4 10             	add    $0x10,%esp
f01028e6:	eb 06                	jmp    f01028ee <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01028e8:	83 eb 01             	sub    $0x1,%ebx
f01028eb:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01028ee:	39 fb                	cmp    %edi,%ebx
f01028f0:	7c 34                	jl     f0102926 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f01028f2:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01028f6:	80 fa 84             	cmp    $0x84,%dl
f01028f9:	74 0b                	je     f0102906 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01028fb:	80 fa 64             	cmp    $0x64,%dl
f01028fe:	75 e8                	jne    f01028e8 <debuginfo_eip+0x138>
f0102900:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102904:	74 e2                	je     f01028e8 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102906:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102909:	8b 14 85 84 47 10 f0 	mov    -0xfefb87c(,%eax,4),%edx
f0102910:	b8 a5 bd 10 f0       	mov    $0xf010bda5,%eax
f0102915:	2d 71 a0 10 f0       	sub    $0xf010a071,%eax
f010291a:	39 c2                	cmp    %eax,%edx
f010291c:	73 08                	jae    f0102926 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010291e:	81 c2 71 a0 10 f0    	add    $0xf010a071,%edx
f0102924:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102926:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102929:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010292c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102931:	39 cb                	cmp    %ecx,%ebx
f0102933:	7d 44                	jge    f0102979 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0102935:	8d 53 01             	lea    0x1(%ebx),%edx
f0102938:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010293b:	8d 04 85 84 47 10 f0 	lea    -0xfefb87c(,%eax,4),%eax
f0102942:	eb 07                	jmp    f010294b <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102944:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102948:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010294b:	39 ca                	cmp    %ecx,%edx
f010294d:	74 25                	je     f0102974 <debuginfo_eip+0x1c4>
f010294f:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102952:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0102956:	74 ec                	je     f0102944 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102958:	b8 00 00 00 00       	mov    $0x0,%eax
f010295d:	eb 1a                	jmp    f0102979 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010295f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102964:	eb 13                	jmp    f0102979 <debuginfo_eip+0x1c9>
f0102966:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010296b:	eb 0c                	jmp    f0102979 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010296d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102972:	eb 05                	jmp    f0102979 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102974:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102979:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010297c:	5b                   	pop    %ebx
f010297d:	5e                   	pop    %esi
f010297e:	5f                   	pop    %edi
f010297f:	5d                   	pop    %ebp
f0102980:	c3                   	ret    

f0102981 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102981:	55                   	push   %ebp
f0102982:	89 e5                	mov    %esp,%ebp
f0102984:	57                   	push   %edi
f0102985:	56                   	push   %esi
f0102986:	53                   	push   %ebx
f0102987:	83 ec 1c             	sub    $0x1c,%esp
f010298a:	89 c7                	mov    %eax,%edi
f010298c:	89 d6                	mov    %edx,%esi
f010298e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102991:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102994:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102997:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010299a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010299d:	bb 00 00 00 00       	mov    $0x0,%ebx
f01029a2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01029a5:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01029a8:	39 d3                	cmp    %edx,%ebx
f01029aa:	72 05                	jb     f01029b1 <printnum+0x30>
f01029ac:	39 45 10             	cmp    %eax,0x10(%ebp)
f01029af:	77 45                	ja     f01029f6 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01029b1:	83 ec 0c             	sub    $0xc,%esp
f01029b4:	ff 75 18             	pushl  0x18(%ebp)
f01029b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01029ba:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01029bd:	53                   	push   %ebx
f01029be:	ff 75 10             	pushl  0x10(%ebp)
f01029c1:	83 ec 08             	sub    $0x8,%esp
f01029c4:	ff 75 e4             	pushl  -0x1c(%ebp)
f01029c7:	ff 75 e0             	pushl  -0x20(%ebp)
f01029ca:	ff 75 dc             	pushl  -0x24(%ebp)
f01029cd:	ff 75 d8             	pushl  -0x28(%ebp)
f01029d0:	e8 cb 09 00 00       	call   f01033a0 <__udivdi3>
f01029d5:	83 c4 18             	add    $0x18,%esp
f01029d8:	52                   	push   %edx
f01029d9:	50                   	push   %eax
f01029da:	89 f2                	mov    %esi,%edx
f01029dc:	89 f8                	mov    %edi,%eax
f01029de:	e8 9e ff ff ff       	call   f0102981 <printnum>
f01029e3:	83 c4 20             	add    $0x20,%esp
f01029e6:	eb 18                	jmp    f0102a00 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01029e8:	83 ec 08             	sub    $0x8,%esp
f01029eb:	56                   	push   %esi
f01029ec:	ff 75 18             	pushl  0x18(%ebp)
f01029ef:	ff d7                	call   *%edi
f01029f1:	83 c4 10             	add    $0x10,%esp
f01029f4:	eb 03                	jmp    f01029f9 <printnum+0x78>
f01029f6:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01029f9:	83 eb 01             	sub    $0x1,%ebx
f01029fc:	85 db                	test   %ebx,%ebx
f01029fe:	7f e8                	jg     f01029e8 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102a00:	83 ec 08             	sub    $0x8,%esp
f0102a03:	56                   	push   %esi
f0102a04:	83 ec 04             	sub    $0x4,%esp
f0102a07:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a0a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a0d:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a10:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a13:	e8 b8 0a 00 00       	call   f01034d0 <__umoddi3>
f0102a18:	83 c4 14             	add    $0x14,%esp
f0102a1b:	0f be 80 73 45 10 f0 	movsbl -0xfefba8d(%eax),%eax
f0102a22:	50                   	push   %eax
f0102a23:	ff d7                	call   *%edi
}
f0102a25:	83 c4 10             	add    $0x10,%esp
f0102a28:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a2b:	5b                   	pop    %ebx
f0102a2c:	5e                   	pop    %esi
f0102a2d:	5f                   	pop    %edi
f0102a2e:	5d                   	pop    %ebp
f0102a2f:	c3                   	ret    

f0102a30 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102a30:	55                   	push   %ebp
f0102a31:	89 e5                	mov    %esp,%ebp
f0102a33:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102a36:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102a3a:	8b 10                	mov    (%eax),%edx
f0102a3c:	3b 50 04             	cmp    0x4(%eax),%edx
f0102a3f:	73 0a                	jae    f0102a4b <sprintputch+0x1b>
		*b->buf++ = ch;
f0102a41:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102a44:	89 08                	mov    %ecx,(%eax)
f0102a46:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a49:	88 02                	mov    %al,(%edx)
}
f0102a4b:	5d                   	pop    %ebp
f0102a4c:	c3                   	ret    

f0102a4d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102a4d:	55                   	push   %ebp
f0102a4e:	89 e5                	mov    %esp,%ebp
f0102a50:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102a53:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102a56:	50                   	push   %eax
f0102a57:	ff 75 10             	pushl  0x10(%ebp)
f0102a5a:	ff 75 0c             	pushl  0xc(%ebp)
f0102a5d:	ff 75 08             	pushl  0x8(%ebp)
f0102a60:	e8 05 00 00 00       	call   f0102a6a <vprintfmt>
	va_end(ap);
}
f0102a65:	83 c4 10             	add    $0x10,%esp
f0102a68:	c9                   	leave  
f0102a69:	c3                   	ret    

f0102a6a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102a6a:	55                   	push   %ebp
f0102a6b:	89 e5                	mov    %esp,%ebp
f0102a6d:	57                   	push   %edi
f0102a6e:	56                   	push   %esi
f0102a6f:	53                   	push   %ebx
f0102a70:	83 ec 2c             	sub    $0x2c,%esp
f0102a73:	8b 75 08             	mov    0x8(%ebp),%esi
f0102a76:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102a79:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102a7c:	eb 12                	jmp    f0102a90 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102a7e:	85 c0                	test   %eax,%eax
f0102a80:	0f 84 42 04 00 00    	je     f0102ec8 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0102a86:	83 ec 08             	sub    $0x8,%esp
f0102a89:	53                   	push   %ebx
f0102a8a:	50                   	push   %eax
f0102a8b:	ff d6                	call   *%esi
f0102a8d:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102a90:	83 c7 01             	add    $0x1,%edi
f0102a93:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102a97:	83 f8 25             	cmp    $0x25,%eax
f0102a9a:	75 e2                	jne    f0102a7e <vprintfmt+0x14>
f0102a9c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102aa0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102aa7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102aae:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102ab5:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102aba:	eb 07                	jmp    f0102ac3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102abc:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102abf:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ac3:	8d 47 01             	lea    0x1(%edi),%eax
f0102ac6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102ac9:	0f b6 07             	movzbl (%edi),%eax
f0102acc:	0f b6 d0             	movzbl %al,%edx
f0102acf:	83 e8 23             	sub    $0x23,%eax
f0102ad2:	3c 55                	cmp    $0x55,%al
f0102ad4:	0f 87 d3 03 00 00    	ja     f0102ead <vprintfmt+0x443>
f0102ada:	0f b6 c0             	movzbl %al,%eax
f0102add:	ff 24 85 00 46 10 f0 	jmp    *-0xfefba00(,%eax,4)
f0102ae4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102ae7:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102aeb:	eb d6                	jmp    f0102ac3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102aed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102af0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102af5:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102af8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102afb:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102aff:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102b02:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102b05:	83 f9 09             	cmp    $0x9,%ecx
f0102b08:	77 3f                	ja     f0102b49 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102b0a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102b0d:	eb e9                	jmp    f0102af8 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102b0f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b12:	8b 00                	mov    (%eax),%eax
f0102b14:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102b17:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b1a:	8d 40 04             	lea    0x4(%eax),%eax
f0102b1d:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b20:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102b23:	eb 2a                	jmp    f0102b4f <vprintfmt+0xe5>
f0102b25:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b28:	85 c0                	test   %eax,%eax
f0102b2a:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b2f:	0f 49 d0             	cmovns %eax,%edx
f0102b32:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b38:	eb 89                	jmp    f0102ac3 <vprintfmt+0x59>
f0102b3a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102b3d:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102b44:	e9 7a ff ff ff       	jmp    f0102ac3 <vprintfmt+0x59>
f0102b49:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102b4c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102b4f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102b53:	0f 89 6a ff ff ff    	jns    f0102ac3 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102b59:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b5c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102b5f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b66:	e9 58 ff ff ff       	jmp    f0102ac3 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102b6b:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102b71:	e9 4d ff ff ff       	jmp    f0102ac3 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102b76:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b79:	8d 78 04             	lea    0x4(%eax),%edi
f0102b7c:	83 ec 08             	sub    $0x8,%esp
f0102b7f:	53                   	push   %ebx
f0102b80:	ff 30                	pushl  (%eax)
f0102b82:	ff d6                	call   *%esi
			break;
f0102b84:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102b87:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b8a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102b8d:	e9 fe fe ff ff       	jmp    f0102a90 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b92:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b95:	8d 78 04             	lea    0x4(%eax),%edi
f0102b98:	8b 00                	mov    (%eax),%eax
f0102b9a:	99                   	cltd   
f0102b9b:	31 d0                	xor    %edx,%eax
f0102b9d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102b9f:	83 f8 06             	cmp    $0x6,%eax
f0102ba2:	7f 0b                	jg     f0102baf <vprintfmt+0x145>
f0102ba4:	8b 14 85 58 47 10 f0 	mov    -0xfefb8a8(,%eax,4),%edx
f0102bab:	85 d2                	test   %edx,%edx
f0102bad:	75 1b                	jne    f0102bca <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102baf:	50                   	push   %eax
f0102bb0:	68 8b 45 10 f0       	push   $0xf010458b
f0102bb5:	53                   	push   %ebx
f0102bb6:	56                   	push   %esi
f0102bb7:	e8 91 fe ff ff       	call   f0102a4d <printfmt>
f0102bbc:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102bbf:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bc2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102bc5:	e9 c6 fe ff ff       	jmp    f0102a90 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102bca:	52                   	push   %edx
f0102bcb:	68 8c 42 10 f0       	push   $0xf010428c
f0102bd0:	53                   	push   %ebx
f0102bd1:	56                   	push   %esi
f0102bd2:	e8 76 fe ff ff       	call   f0102a4d <printfmt>
f0102bd7:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102bda:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bdd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102be0:	e9 ab fe ff ff       	jmp    f0102a90 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102be5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102be8:	83 c0 04             	add    $0x4,%eax
f0102beb:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102bee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bf1:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102bf3:	85 ff                	test   %edi,%edi
f0102bf5:	b8 84 45 10 f0       	mov    $0xf0104584,%eax
f0102bfa:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102bfd:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c01:	0f 8e 94 00 00 00    	jle    f0102c9b <vprintfmt+0x231>
f0102c07:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102c0b:	0f 84 98 00 00 00    	je     f0102ca9 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c11:	83 ec 08             	sub    $0x8,%esp
f0102c14:	ff 75 d0             	pushl  -0x30(%ebp)
f0102c17:	57                   	push   %edi
f0102c18:	e8 0c 04 00 00       	call   f0103029 <strnlen>
f0102c1d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102c20:	29 c1                	sub    %eax,%ecx
f0102c22:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102c25:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102c28:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102c2c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c2f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102c32:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c34:	eb 0f                	jmp    f0102c45 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102c36:	83 ec 08             	sub    $0x8,%esp
f0102c39:	53                   	push   %ebx
f0102c3a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c3d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c3f:	83 ef 01             	sub    $0x1,%edi
f0102c42:	83 c4 10             	add    $0x10,%esp
f0102c45:	85 ff                	test   %edi,%edi
f0102c47:	7f ed                	jg     f0102c36 <vprintfmt+0x1cc>
f0102c49:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c4c:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102c4f:	85 c9                	test   %ecx,%ecx
f0102c51:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c56:	0f 49 c1             	cmovns %ecx,%eax
f0102c59:	29 c1                	sub    %eax,%ecx
f0102c5b:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c5e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c61:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c64:	89 cb                	mov    %ecx,%ebx
f0102c66:	eb 4d                	jmp    f0102cb5 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102c68:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102c6c:	74 1b                	je     f0102c89 <vprintfmt+0x21f>
f0102c6e:	0f be c0             	movsbl %al,%eax
f0102c71:	83 e8 20             	sub    $0x20,%eax
f0102c74:	83 f8 5e             	cmp    $0x5e,%eax
f0102c77:	76 10                	jbe    f0102c89 <vprintfmt+0x21f>
					putch('?', putdat);
f0102c79:	83 ec 08             	sub    $0x8,%esp
f0102c7c:	ff 75 0c             	pushl  0xc(%ebp)
f0102c7f:	6a 3f                	push   $0x3f
f0102c81:	ff 55 08             	call   *0x8(%ebp)
f0102c84:	83 c4 10             	add    $0x10,%esp
f0102c87:	eb 0d                	jmp    f0102c96 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102c89:	83 ec 08             	sub    $0x8,%esp
f0102c8c:	ff 75 0c             	pushl  0xc(%ebp)
f0102c8f:	52                   	push   %edx
f0102c90:	ff 55 08             	call   *0x8(%ebp)
f0102c93:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102c96:	83 eb 01             	sub    $0x1,%ebx
f0102c99:	eb 1a                	jmp    f0102cb5 <vprintfmt+0x24b>
f0102c9b:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c9e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102ca1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102ca4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102ca7:	eb 0c                	jmp    f0102cb5 <vprintfmt+0x24b>
f0102ca9:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cac:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102caf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cb2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102cb5:	83 c7 01             	add    $0x1,%edi
f0102cb8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102cbc:	0f be d0             	movsbl %al,%edx
f0102cbf:	85 d2                	test   %edx,%edx
f0102cc1:	74 23                	je     f0102ce6 <vprintfmt+0x27c>
f0102cc3:	85 f6                	test   %esi,%esi
f0102cc5:	78 a1                	js     f0102c68 <vprintfmt+0x1fe>
f0102cc7:	83 ee 01             	sub    $0x1,%esi
f0102cca:	79 9c                	jns    f0102c68 <vprintfmt+0x1fe>
f0102ccc:	89 df                	mov    %ebx,%edi
f0102cce:	8b 75 08             	mov    0x8(%ebp),%esi
f0102cd1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102cd4:	eb 18                	jmp    f0102cee <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102cd6:	83 ec 08             	sub    $0x8,%esp
f0102cd9:	53                   	push   %ebx
f0102cda:	6a 20                	push   $0x20
f0102cdc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102cde:	83 ef 01             	sub    $0x1,%edi
f0102ce1:	83 c4 10             	add    $0x10,%esp
f0102ce4:	eb 08                	jmp    f0102cee <vprintfmt+0x284>
f0102ce6:	89 df                	mov    %ebx,%edi
f0102ce8:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ceb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102cee:	85 ff                	test   %edi,%edi
f0102cf0:	7f e4                	jg     f0102cd6 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cf2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102cf5:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cf8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cfb:	e9 90 fd ff ff       	jmp    f0102a90 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d00:	83 f9 01             	cmp    $0x1,%ecx
f0102d03:	7e 19                	jle    f0102d1e <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102d05:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d08:	8b 50 04             	mov    0x4(%eax),%edx
f0102d0b:	8b 00                	mov    (%eax),%eax
f0102d0d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d10:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102d13:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d16:	8d 40 08             	lea    0x8(%eax),%eax
f0102d19:	89 45 14             	mov    %eax,0x14(%ebp)
f0102d1c:	eb 38                	jmp    f0102d56 <vprintfmt+0x2ec>
	else if (lflag)
f0102d1e:	85 c9                	test   %ecx,%ecx
f0102d20:	74 1b                	je     f0102d3d <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102d22:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d25:	8b 00                	mov    (%eax),%eax
f0102d27:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d2a:	89 c1                	mov    %eax,%ecx
f0102d2c:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d2f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102d32:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d35:	8d 40 04             	lea    0x4(%eax),%eax
f0102d38:	89 45 14             	mov    %eax,0x14(%ebp)
f0102d3b:	eb 19                	jmp    f0102d56 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102d3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d40:	8b 00                	mov    (%eax),%eax
f0102d42:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d45:	89 c1                	mov    %eax,%ecx
f0102d47:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d4a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102d4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d50:	8d 40 04             	lea    0x4(%eax),%eax
f0102d53:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102d56:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d59:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102d5c:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102d61:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102d65:	0f 89 0e 01 00 00    	jns    f0102e79 <vprintfmt+0x40f>
				putch('-', putdat);
f0102d6b:	83 ec 08             	sub    $0x8,%esp
f0102d6e:	53                   	push   %ebx
f0102d6f:	6a 2d                	push   $0x2d
f0102d71:	ff d6                	call   *%esi
				num = -(long long) num;
f0102d73:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d76:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102d79:	f7 da                	neg    %edx
f0102d7b:	83 d1 00             	adc    $0x0,%ecx
f0102d7e:	f7 d9                	neg    %ecx
f0102d80:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102d83:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d88:	e9 ec 00 00 00       	jmp    f0102e79 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d8d:	83 f9 01             	cmp    $0x1,%ecx
f0102d90:	7e 18                	jle    f0102daa <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102d92:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d95:	8b 10                	mov    (%eax),%edx
f0102d97:	8b 48 04             	mov    0x4(%eax),%ecx
f0102d9a:	8d 40 08             	lea    0x8(%eax),%eax
f0102d9d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102da0:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102da5:	e9 cf 00 00 00       	jmp    f0102e79 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102daa:	85 c9                	test   %ecx,%ecx
f0102dac:	74 1a                	je     f0102dc8 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102dae:	8b 45 14             	mov    0x14(%ebp),%eax
f0102db1:	8b 10                	mov    (%eax),%edx
f0102db3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102db8:	8d 40 04             	lea    0x4(%eax),%eax
f0102dbb:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102dbe:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102dc3:	e9 b1 00 00 00       	jmp    f0102e79 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102dc8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dcb:	8b 10                	mov    (%eax),%edx
f0102dcd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102dd2:	8d 40 04             	lea    0x4(%eax),%eax
f0102dd5:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102dd8:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ddd:	e9 97 00 00 00       	jmp    f0102e79 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102de2:	83 ec 08             	sub    $0x8,%esp
f0102de5:	53                   	push   %ebx
f0102de6:	6a 58                	push   $0x58
f0102de8:	ff d6                	call   *%esi
			putch('X', putdat);
f0102dea:	83 c4 08             	add    $0x8,%esp
f0102ded:	53                   	push   %ebx
f0102dee:	6a 58                	push   $0x58
f0102df0:	ff d6                	call   *%esi
			putch('X', putdat);
f0102df2:	83 c4 08             	add    $0x8,%esp
f0102df5:	53                   	push   %ebx
f0102df6:	6a 58                	push   $0x58
f0102df8:	ff d6                	call   *%esi
			break;
f0102dfa:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dfd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0102e00:	e9 8b fc ff ff       	jmp    f0102a90 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e05:	83 ec 08             	sub    $0x8,%esp
f0102e08:	53                   	push   %ebx
f0102e09:	6a 30                	push   $0x30
f0102e0b:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e0d:	83 c4 08             	add    $0x8,%esp
f0102e10:	53                   	push   %ebx
f0102e11:	6a 78                	push   $0x78
f0102e13:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102e15:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e18:	8b 10                	mov    (%eax),%edx
f0102e1a:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e1f:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e22:	8d 40 04             	lea    0x4(%eax),%eax
f0102e25:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102e28:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102e2d:	eb 4a                	jmp    f0102e79 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e2f:	83 f9 01             	cmp    $0x1,%ecx
f0102e32:	7e 15                	jle    f0102e49 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0102e34:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e37:	8b 10                	mov    (%eax),%edx
f0102e39:	8b 48 04             	mov    0x4(%eax),%ecx
f0102e3c:	8d 40 08             	lea    0x8(%eax),%eax
f0102e3f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102e42:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e47:	eb 30                	jmp    f0102e79 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102e49:	85 c9                	test   %ecx,%ecx
f0102e4b:	74 17                	je     f0102e64 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0102e4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e50:	8b 10                	mov    (%eax),%edx
f0102e52:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e57:	8d 40 04             	lea    0x4(%eax),%eax
f0102e5a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102e5d:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e62:	eb 15                	jmp    f0102e79 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102e64:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e67:	8b 10                	mov    (%eax),%edx
f0102e69:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e6e:	8d 40 04             	lea    0x4(%eax),%eax
f0102e71:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102e74:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102e79:	83 ec 0c             	sub    $0xc,%esp
f0102e7c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102e80:	57                   	push   %edi
f0102e81:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e84:	50                   	push   %eax
f0102e85:	51                   	push   %ecx
f0102e86:	52                   	push   %edx
f0102e87:	89 da                	mov    %ebx,%edx
f0102e89:	89 f0                	mov    %esi,%eax
f0102e8b:	e8 f1 fa ff ff       	call   f0102981 <printnum>
			break;
f0102e90:	83 c4 20             	add    $0x20,%esp
f0102e93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e96:	e9 f5 fb ff ff       	jmp    f0102a90 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102e9b:	83 ec 08             	sub    $0x8,%esp
f0102e9e:	53                   	push   %ebx
f0102e9f:	52                   	push   %edx
f0102ea0:	ff d6                	call   *%esi
			break;
f0102ea2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ea5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102ea8:	e9 e3 fb ff ff       	jmp    f0102a90 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102ead:	83 ec 08             	sub    $0x8,%esp
f0102eb0:	53                   	push   %ebx
f0102eb1:	6a 25                	push   $0x25
f0102eb3:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102eb5:	83 c4 10             	add    $0x10,%esp
f0102eb8:	eb 03                	jmp    f0102ebd <vprintfmt+0x453>
f0102eba:	83 ef 01             	sub    $0x1,%edi
f0102ebd:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ec1:	75 f7                	jne    f0102eba <vprintfmt+0x450>
f0102ec3:	e9 c8 fb ff ff       	jmp    f0102a90 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102ec8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ecb:	5b                   	pop    %ebx
f0102ecc:	5e                   	pop    %esi
f0102ecd:	5f                   	pop    %edi
f0102ece:	5d                   	pop    %ebp
f0102ecf:	c3                   	ret    

f0102ed0 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102ed0:	55                   	push   %ebp
f0102ed1:	89 e5                	mov    %esp,%ebp
f0102ed3:	83 ec 18             	sub    $0x18,%esp
f0102ed6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ed9:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102edc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102edf:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102ee3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102ee6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102eed:	85 c0                	test   %eax,%eax
f0102eef:	74 26                	je     f0102f17 <vsnprintf+0x47>
f0102ef1:	85 d2                	test   %edx,%edx
f0102ef3:	7e 22                	jle    f0102f17 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102ef5:	ff 75 14             	pushl  0x14(%ebp)
f0102ef8:	ff 75 10             	pushl  0x10(%ebp)
f0102efb:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102efe:	50                   	push   %eax
f0102eff:	68 30 2a 10 f0       	push   $0xf0102a30
f0102f04:	e8 61 fb ff ff       	call   f0102a6a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f09:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f0c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f12:	83 c4 10             	add    $0x10,%esp
f0102f15:	eb 05                	jmp    f0102f1c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f17:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f1c:	c9                   	leave  
f0102f1d:	c3                   	ret    

f0102f1e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f1e:	55                   	push   %ebp
f0102f1f:	89 e5                	mov    %esp,%ebp
f0102f21:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f24:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f27:	50                   	push   %eax
f0102f28:	ff 75 10             	pushl  0x10(%ebp)
f0102f2b:	ff 75 0c             	pushl  0xc(%ebp)
f0102f2e:	ff 75 08             	pushl  0x8(%ebp)
f0102f31:	e8 9a ff ff ff       	call   f0102ed0 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f36:	c9                   	leave  
f0102f37:	c3                   	ret    

f0102f38 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f38:	55                   	push   %ebp
f0102f39:	89 e5                	mov    %esp,%ebp
f0102f3b:	57                   	push   %edi
f0102f3c:	56                   	push   %esi
f0102f3d:	53                   	push   %ebx
f0102f3e:	83 ec 0c             	sub    $0xc,%esp
f0102f41:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f44:	85 c0                	test   %eax,%eax
f0102f46:	74 11                	je     f0102f59 <readline+0x21>
		cprintf("%s", prompt);
f0102f48:	83 ec 08             	sub    $0x8,%esp
f0102f4b:	50                   	push   %eax
f0102f4c:	68 8c 42 10 f0       	push   $0xf010428c
f0102f51:	e8 50 f7 ff ff       	call   f01026a6 <cprintf>
f0102f56:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f59:	83 ec 0c             	sub    $0xc,%esp
f0102f5c:	6a 00                	push   $0x0
f0102f5e:	e8 be d6 ff ff       	call   f0100621 <iscons>
f0102f63:	89 c7                	mov    %eax,%edi
f0102f65:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f68:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f6d:	e8 9e d6 ff ff       	call   f0100610 <getchar>
f0102f72:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102f74:	85 c0                	test   %eax,%eax
f0102f76:	79 18                	jns    f0102f90 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102f78:	83 ec 08             	sub    $0x8,%esp
f0102f7b:	50                   	push   %eax
f0102f7c:	68 74 47 10 f0       	push   $0xf0104774
f0102f81:	e8 20 f7 ff ff       	call   f01026a6 <cprintf>
			return NULL;
f0102f86:	83 c4 10             	add    $0x10,%esp
f0102f89:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f8e:	eb 79                	jmp    f0103009 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102f90:	83 f8 08             	cmp    $0x8,%eax
f0102f93:	0f 94 c2             	sete   %dl
f0102f96:	83 f8 7f             	cmp    $0x7f,%eax
f0102f99:	0f 94 c0             	sete   %al
f0102f9c:	08 c2                	or     %al,%dl
f0102f9e:	74 1a                	je     f0102fba <readline+0x82>
f0102fa0:	85 f6                	test   %esi,%esi
f0102fa2:	7e 16                	jle    f0102fba <readline+0x82>
			if (echoing)
f0102fa4:	85 ff                	test   %edi,%edi
f0102fa6:	74 0d                	je     f0102fb5 <readline+0x7d>
				cputchar('\b');
f0102fa8:	83 ec 0c             	sub    $0xc,%esp
f0102fab:	6a 08                	push   $0x8
f0102fad:	e8 4e d6 ff ff       	call   f0100600 <cputchar>
f0102fb2:	83 c4 10             	add    $0x10,%esp
			i--;
f0102fb5:	83 ee 01             	sub    $0x1,%esi
f0102fb8:	eb b3                	jmp    f0102f6d <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102fba:	83 fb 1f             	cmp    $0x1f,%ebx
f0102fbd:	7e 23                	jle    f0102fe2 <readline+0xaa>
f0102fbf:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102fc5:	7f 1b                	jg     f0102fe2 <readline+0xaa>
			if (echoing)
f0102fc7:	85 ff                	test   %edi,%edi
f0102fc9:	74 0c                	je     f0102fd7 <readline+0x9f>
				cputchar(c);
f0102fcb:	83 ec 0c             	sub    $0xc,%esp
f0102fce:	53                   	push   %ebx
f0102fcf:	e8 2c d6 ff ff       	call   f0100600 <cputchar>
f0102fd4:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102fd7:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f0102fdd:	8d 76 01             	lea    0x1(%esi),%esi
f0102fe0:	eb 8b                	jmp    f0102f6d <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102fe2:	83 fb 0a             	cmp    $0xa,%ebx
f0102fe5:	74 05                	je     f0102fec <readline+0xb4>
f0102fe7:	83 fb 0d             	cmp    $0xd,%ebx
f0102fea:	75 81                	jne    f0102f6d <readline+0x35>
			if (echoing)
f0102fec:	85 ff                	test   %edi,%edi
f0102fee:	74 0d                	je     f0102ffd <readline+0xc5>
				cputchar('\n');
f0102ff0:	83 ec 0c             	sub    $0xc,%esp
f0102ff3:	6a 0a                	push   $0xa
f0102ff5:	e8 06 d6 ff ff       	call   f0100600 <cputchar>
f0102ffa:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102ffd:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0103004:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0103009:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010300c:	5b                   	pop    %ebx
f010300d:	5e                   	pop    %esi
f010300e:	5f                   	pop    %edi
f010300f:	5d                   	pop    %ebp
f0103010:	c3                   	ret    

f0103011 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103011:	55                   	push   %ebp
f0103012:	89 e5                	mov    %esp,%ebp
f0103014:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103017:	b8 00 00 00 00       	mov    $0x0,%eax
f010301c:	eb 03                	jmp    f0103021 <strlen+0x10>
		n++;
f010301e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103021:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103025:	75 f7                	jne    f010301e <strlen+0xd>
		n++;
	return n;
}
f0103027:	5d                   	pop    %ebp
f0103028:	c3                   	ret    

f0103029 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103029:	55                   	push   %ebp
f010302a:	89 e5                	mov    %esp,%ebp
f010302c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010302f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103032:	ba 00 00 00 00       	mov    $0x0,%edx
f0103037:	eb 03                	jmp    f010303c <strnlen+0x13>
		n++;
f0103039:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010303c:	39 c2                	cmp    %eax,%edx
f010303e:	74 08                	je     f0103048 <strnlen+0x1f>
f0103040:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103044:	75 f3                	jne    f0103039 <strnlen+0x10>
f0103046:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103048:	5d                   	pop    %ebp
f0103049:	c3                   	ret    

f010304a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010304a:	55                   	push   %ebp
f010304b:	89 e5                	mov    %esp,%ebp
f010304d:	53                   	push   %ebx
f010304e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103051:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103054:	89 c2                	mov    %eax,%edx
f0103056:	83 c2 01             	add    $0x1,%edx
f0103059:	83 c1 01             	add    $0x1,%ecx
f010305c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103060:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103063:	84 db                	test   %bl,%bl
f0103065:	75 ef                	jne    f0103056 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103067:	5b                   	pop    %ebx
f0103068:	5d                   	pop    %ebp
f0103069:	c3                   	ret    

f010306a <strcat>:

char *
strcat(char *dst, const char *src)
{
f010306a:	55                   	push   %ebp
f010306b:	89 e5                	mov    %esp,%ebp
f010306d:	53                   	push   %ebx
f010306e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103071:	53                   	push   %ebx
f0103072:	e8 9a ff ff ff       	call   f0103011 <strlen>
f0103077:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010307a:	ff 75 0c             	pushl  0xc(%ebp)
f010307d:	01 d8                	add    %ebx,%eax
f010307f:	50                   	push   %eax
f0103080:	e8 c5 ff ff ff       	call   f010304a <strcpy>
	return dst;
}
f0103085:	89 d8                	mov    %ebx,%eax
f0103087:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010308a:	c9                   	leave  
f010308b:	c3                   	ret    

f010308c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010308c:	55                   	push   %ebp
f010308d:	89 e5                	mov    %esp,%ebp
f010308f:	56                   	push   %esi
f0103090:	53                   	push   %ebx
f0103091:	8b 75 08             	mov    0x8(%ebp),%esi
f0103094:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103097:	89 f3                	mov    %esi,%ebx
f0103099:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010309c:	89 f2                	mov    %esi,%edx
f010309e:	eb 0f                	jmp    f01030af <strncpy+0x23>
		*dst++ = *src;
f01030a0:	83 c2 01             	add    $0x1,%edx
f01030a3:	0f b6 01             	movzbl (%ecx),%eax
f01030a6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030a9:	80 39 01             	cmpb   $0x1,(%ecx)
f01030ac:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030af:	39 da                	cmp    %ebx,%edx
f01030b1:	75 ed                	jne    f01030a0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01030b3:	89 f0                	mov    %esi,%eax
f01030b5:	5b                   	pop    %ebx
f01030b6:	5e                   	pop    %esi
f01030b7:	5d                   	pop    %ebp
f01030b8:	c3                   	ret    

f01030b9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01030b9:	55                   	push   %ebp
f01030ba:	89 e5                	mov    %esp,%ebp
f01030bc:	56                   	push   %esi
f01030bd:	53                   	push   %ebx
f01030be:	8b 75 08             	mov    0x8(%ebp),%esi
f01030c1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030c4:	8b 55 10             	mov    0x10(%ebp),%edx
f01030c7:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01030c9:	85 d2                	test   %edx,%edx
f01030cb:	74 21                	je     f01030ee <strlcpy+0x35>
f01030cd:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01030d1:	89 f2                	mov    %esi,%edx
f01030d3:	eb 09                	jmp    f01030de <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01030d5:	83 c2 01             	add    $0x1,%edx
f01030d8:	83 c1 01             	add    $0x1,%ecx
f01030db:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01030de:	39 c2                	cmp    %eax,%edx
f01030e0:	74 09                	je     f01030eb <strlcpy+0x32>
f01030e2:	0f b6 19             	movzbl (%ecx),%ebx
f01030e5:	84 db                	test   %bl,%bl
f01030e7:	75 ec                	jne    f01030d5 <strlcpy+0x1c>
f01030e9:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01030eb:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01030ee:	29 f0                	sub    %esi,%eax
}
f01030f0:	5b                   	pop    %ebx
f01030f1:	5e                   	pop    %esi
f01030f2:	5d                   	pop    %ebp
f01030f3:	c3                   	ret    

f01030f4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01030f4:	55                   	push   %ebp
f01030f5:	89 e5                	mov    %esp,%ebp
f01030f7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030fa:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01030fd:	eb 06                	jmp    f0103105 <strcmp+0x11>
		p++, q++;
f01030ff:	83 c1 01             	add    $0x1,%ecx
f0103102:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103105:	0f b6 01             	movzbl (%ecx),%eax
f0103108:	84 c0                	test   %al,%al
f010310a:	74 04                	je     f0103110 <strcmp+0x1c>
f010310c:	3a 02                	cmp    (%edx),%al
f010310e:	74 ef                	je     f01030ff <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103110:	0f b6 c0             	movzbl %al,%eax
f0103113:	0f b6 12             	movzbl (%edx),%edx
f0103116:	29 d0                	sub    %edx,%eax
}
f0103118:	5d                   	pop    %ebp
f0103119:	c3                   	ret    

f010311a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010311a:	55                   	push   %ebp
f010311b:	89 e5                	mov    %esp,%ebp
f010311d:	53                   	push   %ebx
f010311e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103121:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103124:	89 c3                	mov    %eax,%ebx
f0103126:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103129:	eb 06                	jmp    f0103131 <strncmp+0x17>
		n--, p++, q++;
f010312b:	83 c0 01             	add    $0x1,%eax
f010312e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103131:	39 d8                	cmp    %ebx,%eax
f0103133:	74 15                	je     f010314a <strncmp+0x30>
f0103135:	0f b6 08             	movzbl (%eax),%ecx
f0103138:	84 c9                	test   %cl,%cl
f010313a:	74 04                	je     f0103140 <strncmp+0x26>
f010313c:	3a 0a                	cmp    (%edx),%cl
f010313e:	74 eb                	je     f010312b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103140:	0f b6 00             	movzbl (%eax),%eax
f0103143:	0f b6 12             	movzbl (%edx),%edx
f0103146:	29 d0                	sub    %edx,%eax
f0103148:	eb 05                	jmp    f010314f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010314a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010314f:	5b                   	pop    %ebx
f0103150:	5d                   	pop    %ebp
f0103151:	c3                   	ret    

f0103152 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103152:	55                   	push   %ebp
f0103153:	89 e5                	mov    %esp,%ebp
f0103155:	8b 45 08             	mov    0x8(%ebp),%eax
f0103158:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010315c:	eb 07                	jmp    f0103165 <strchr+0x13>
		if (*s == c)
f010315e:	38 ca                	cmp    %cl,%dl
f0103160:	74 0f                	je     f0103171 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103162:	83 c0 01             	add    $0x1,%eax
f0103165:	0f b6 10             	movzbl (%eax),%edx
f0103168:	84 d2                	test   %dl,%dl
f010316a:	75 f2                	jne    f010315e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010316c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103171:	5d                   	pop    %ebp
f0103172:	c3                   	ret    

f0103173 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103173:	55                   	push   %ebp
f0103174:	89 e5                	mov    %esp,%ebp
f0103176:	8b 45 08             	mov    0x8(%ebp),%eax
f0103179:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010317d:	eb 03                	jmp    f0103182 <strfind+0xf>
f010317f:	83 c0 01             	add    $0x1,%eax
f0103182:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103185:	38 ca                	cmp    %cl,%dl
f0103187:	74 04                	je     f010318d <strfind+0x1a>
f0103189:	84 d2                	test   %dl,%dl
f010318b:	75 f2                	jne    f010317f <strfind+0xc>
			break;
	return (char *) s;
}
f010318d:	5d                   	pop    %ebp
f010318e:	c3                   	ret    

f010318f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010318f:	55                   	push   %ebp
f0103190:	89 e5                	mov    %esp,%ebp
f0103192:	57                   	push   %edi
f0103193:	56                   	push   %esi
f0103194:	53                   	push   %ebx
f0103195:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103198:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010319b:	85 c9                	test   %ecx,%ecx
f010319d:	74 36                	je     f01031d5 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010319f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031a5:	75 28                	jne    f01031cf <memset+0x40>
f01031a7:	f6 c1 03             	test   $0x3,%cl
f01031aa:	75 23                	jne    f01031cf <memset+0x40>
		c &= 0xFF;
f01031ac:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01031b0:	89 d3                	mov    %edx,%ebx
f01031b2:	c1 e3 08             	shl    $0x8,%ebx
f01031b5:	89 d6                	mov    %edx,%esi
f01031b7:	c1 e6 18             	shl    $0x18,%esi
f01031ba:	89 d0                	mov    %edx,%eax
f01031bc:	c1 e0 10             	shl    $0x10,%eax
f01031bf:	09 f0                	or     %esi,%eax
f01031c1:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01031c3:	89 d8                	mov    %ebx,%eax
f01031c5:	09 d0                	or     %edx,%eax
f01031c7:	c1 e9 02             	shr    $0x2,%ecx
f01031ca:	fc                   	cld    
f01031cb:	f3 ab                	rep stos %eax,%es:(%edi)
f01031cd:	eb 06                	jmp    f01031d5 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01031cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031d2:	fc                   	cld    
f01031d3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01031d5:	89 f8                	mov    %edi,%eax
f01031d7:	5b                   	pop    %ebx
f01031d8:	5e                   	pop    %esi
f01031d9:	5f                   	pop    %edi
f01031da:	5d                   	pop    %ebp
f01031db:	c3                   	ret    

f01031dc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01031dc:	55                   	push   %ebp
f01031dd:	89 e5                	mov    %esp,%ebp
f01031df:	57                   	push   %edi
f01031e0:	56                   	push   %esi
f01031e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01031e4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01031e7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01031ea:	39 c6                	cmp    %eax,%esi
f01031ec:	73 35                	jae    f0103223 <memmove+0x47>
f01031ee:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01031f1:	39 d0                	cmp    %edx,%eax
f01031f3:	73 2e                	jae    f0103223 <memmove+0x47>
		s += n;
		d += n;
f01031f5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01031f8:	89 d6                	mov    %edx,%esi
f01031fa:	09 fe                	or     %edi,%esi
f01031fc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103202:	75 13                	jne    f0103217 <memmove+0x3b>
f0103204:	f6 c1 03             	test   $0x3,%cl
f0103207:	75 0e                	jne    f0103217 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103209:	83 ef 04             	sub    $0x4,%edi
f010320c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010320f:	c1 e9 02             	shr    $0x2,%ecx
f0103212:	fd                   	std    
f0103213:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103215:	eb 09                	jmp    f0103220 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103217:	83 ef 01             	sub    $0x1,%edi
f010321a:	8d 72 ff             	lea    -0x1(%edx),%esi
f010321d:	fd                   	std    
f010321e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103220:	fc                   	cld    
f0103221:	eb 1d                	jmp    f0103240 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103223:	89 f2                	mov    %esi,%edx
f0103225:	09 c2                	or     %eax,%edx
f0103227:	f6 c2 03             	test   $0x3,%dl
f010322a:	75 0f                	jne    f010323b <memmove+0x5f>
f010322c:	f6 c1 03             	test   $0x3,%cl
f010322f:	75 0a                	jne    f010323b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103231:	c1 e9 02             	shr    $0x2,%ecx
f0103234:	89 c7                	mov    %eax,%edi
f0103236:	fc                   	cld    
f0103237:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103239:	eb 05                	jmp    f0103240 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010323b:	89 c7                	mov    %eax,%edi
f010323d:	fc                   	cld    
f010323e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103240:	5e                   	pop    %esi
f0103241:	5f                   	pop    %edi
f0103242:	5d                   	pop    %ebp
f0103243:	c3                   	ret    

f0103244 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103244:	55                   	push   %ebp
f0103245:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103247:	ff 75 10             	pushl  0x10(%ebp)
f010324a:	ff 75 0c             	pushl  0xc(%ebp)
f010324d:	ff 75 08             	pushl  0x8(%ebp)
f0103250:	e8 87 ff ff ff       	call   f01031dc <memmove>
}
f0103255:	c9                   	leave  
f0103256:	c3                   	ret    

f0103257 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103257:	55                   	push   %ebp
f0103258:	89 e5                	mov    %esp,%ebp
f010325a:	56                   	push   %esi
f010325b:	53                   	push   %ebx
f010325c:	8b 45 08             	mov    0x8(%ebp),%eax
f010325f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103262:	89 c6                	mov    %eax,%esi
f0103264:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103267:	eb 1a                	jmp    f0103283 <memcmp+0x2c>
		if (*s1 != *s2)
f0103269:	0f b6 08             	movzbl (%eax),%ecx
f010326c:	0f b6 1a             	movzbl (%edx),%ebx
f010326f:	38 d9                	cmp    %bl,%cl
f0103271:	74 0a                	je     f010327d <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103273:	0f b6 c1             	movzbl %cl,%eax
f0103276:	0f b6 db             	movzbl %bl,%ebx
f0103279:	29 d8                	sub    %ebx,%eax
f010327b:	eb 0f                	jmp    f010328c <memcmp+0x35>
		s1++, s2++;
f010327d:	83 c0 01             	add    $0x1,%eax
f0103280:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103283:	39 f0                	cmp    %esi,%eax
f0103285:	75 e2                	jne    f0103269 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103287:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010328c:	5b                   	pop    %ebx
f010328d:	5e                   	pop    %esi
f010328e:	5d                   	pop    %ebp
f010328f:	c3                   	ret    

f0103290 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103290:	55                   	push   %ebp
f0103291:	89 e5                	mov    %esp,%ebp
f0103293:	53                   	push   %ebx
f0103294:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103297:	89 c1                	mov    %eax,%ecx
f0103299:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010329c:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032a0:	eb 0a                	jmp    f01032ac <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032a2:	0f b6 10             	movzbl (%eax),%edx
f01032a5:	39 da                	cmp    %ebx,%edx
f01032a7:	74 07                	je     f01032b0 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032a9:	83 c0 01             	add    $0x1,%eax
f01032ac:	39 c8                	cmp    %ecx,%eax
f01032ae:	72 f2                	jb     f01032a2 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01032b0:	5b                   	pop    %ebx
f01032b1:	5d                   	pop    %ebp
f01032b2:	c3                   	ret    

f01032b3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01032b3:	55                   	push   %ebp
f01032b4:	89 e5                	mov    %esp,%ebp
f01032b6:	57                   	push   %edi
f01032b7:	56                   	push   %esi
f01032b8:	53                   	push   %ebx
f01032b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032bc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032bf:	eb 03                	jmp    f01032c4 <strtol+0x11>
		s++;
f01032c1:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032c4:	0f b6 01             	movzbl (%ecx),%eax
f01032c7:	3c 20                	cmp    $0x20,%al
f01032c9:	74 f6                	je     f01032c1 <strtol+0xe>
f01032cb:	3c 09                	cmp    $0x9,%al
f01032cd:	74 f2                	je     f01032c1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01032cf:	3c 2b                	cmp    $0x2b,%al
f01032d1:	75 0a                	jne    f01032dd <strtol+0x2a>
		s++;
f01032d3:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01032d6:	bf 00 00 00 00       	mov    $0x0,%edi
f01032db:	eb 11                	jmp    f01032ee <strtol+0x3b>
f01032dd:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01032e2:	3c 2d                	cmp    $0x2d,%al
f01032e4:	75 08                	jne    f01032ee <strtol+0x3b>
		s++, neg = 1;
f01032e6:	83 c1 01             	add    $0x1,%ecx
f01032e9:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01032ee:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01032f4:	75 15                	jne    f010330b <strtol+0x58>
f01032f6:	80 39 30             	cmpb   $0x30,(%ecx)
f01032f9:	75 10                	jne    f010330b <strtol+0x58>
f01032fb:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01032ff:	75 7c                	jne    f010337d <strtol+0xca>
		s += 2, base = 16;
f0103301:	83 c1 02             	add    $0x2,%ecx
f0103304:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103309:	eb 16                	jmp    f0103321 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010330b:	85 db                	test   %ebx,%ebx
f010330d:	75 12                	jne    f0103321 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010330f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103314:	80 39 30             	cmpb   $0x30,(%ecx)
f0103317:	75 08                	jne    f0103321 <strtol+0x6e>
		s++, base = 8;
f0103319:	83 c1 01             	add    $0x1,%ecx
f010331c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103321:	b8 00 00 00 00       	mov    $0x0,%eax
f0103326:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103329:	0f b6 11             	movzbl (%ecx),%edx
f010332c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010332f:	89 f3                	mov    %esi,%ebx
f0103331:	80 fb 09             	cmp    $0x9,%bl
f0103334:	77 08                	ja     f010333e <strtol+0x8b>
			dig = *s - '0';
f0103336:	0f be d2             	movsbl %dl,%edx
f0103339:	83 ea 30             	sub    $0x30,%edx
f010333c:	eb 22                	jmp    f0103360 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010333e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103341:	89 f3                	mov    %esi,%ebx
f0103343:	80 fb 19             	cmp    $0x19,%bl
f0103346:	77 08                	ja     f0103350 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103348:	0f be d2             	movsbl %dl,%edx
f010334b:	83 ea 57             	sub    $0x57,%edx
f010334e:	eb 10                	jmp    f0103360 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103350:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103353:	89 f3                	mov    %esi,%ebx
f0103355:	80 fb 19             	cmp    $0x19,%bl
f0103358:	77 16                	ja     f0103370 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010335a:	0f be d2             	movsbl %dl,%edx
f010335d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103360:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103363:	7d 0b                	jge    f0103370 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103365:	83 c1 01             	add    $0x1,%ecx
f0103368:	0f af 45 10          	imul   0x10(%ebp),%eax
f010336c:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010336e:	eb b9                	jmp    f0103329 <strtol+0x76>

	if (endptr)
f0103370:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103374:	74 0d                	je     f0103383 <strtol+0xd0>
		*endptr = (char *) s;
f0103376:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103379:	89 0e                	mov    %ecx,(%esi)
f010337b:	eb 06                	jmp    f0103383 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010337d:	85 db                	test   %ebx,%ebx
f010337f:	74 98                	je     f0103319 <strtol+0x66>
f0103381:	eb 9e                	jmp    f0103321 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103383:	89 c2                	mov    %eax,%edx
f0103385:	f7 da                	neg    %edx
f0103387:	85 ff                	test   %edi,%edi
f0103389:	0f 45 c2             	cmovne %edx,%eax
}
f010338c:	5b                   	pop    %ebx
f010338d:	5e                   	pop    %esi
f010338e:	5f                   	pop    %edi
f010338f:	5d                   	pop    %ebp
f0103390:	c3                   	ret    
f0103391:	66 90                	xchg   %ax,%ax
f0103393:	66 90                	xchg   %ax,%ax
f0103395:	66 90                	xchg   %ax,%ax
f0103397:	66 90                	xchg   %ax,%ax
f0103399:	66 90                	xchg   %ax,%ax
f010339b:	66 90                	xchg   %ax,%ax
f010339d:	66 90                	xchg   %ax,%ax
f010339f:	90                   	nop

f01033a0 <__udivdi3>:
f01033a0:	55                   	push   %ebp
f01033a1:	57                   	push   %edi
f01033a2:	56                   	push   %esi
f01033a3:	53                   	push   %ebx
f01033a4:	83 ec 1c             	sub    $0x1c,%esp
f01033a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01033b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033b7:	85 f6                	test   %esi,%esi
f01033b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01033bd:	89 ca                	mov    %ecx,%edx
f01033bf:	89 f8                	mov    %edi,%eax
f01033c1:	75 3d                	jne    f0103400 <__udivdi3+0x60>
f01033c3:	39 cf                	cmp    %ecx,%edi
f01033c5:	0f 87 c5 00 00 00    	ja     f0103490 <__udivdi3+0xf0>
f01033cb:	85 ff                	test   %edi,%edi
f01033cd:	89 fd                	mov    %edi,%ebp
f01033cf:	75 0b                	jne    f01033dc <__udivdi3+0x3c>
f01033d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01033d6:	31 d2                	xor    %edx,%edx
f01033d8:	f7 f7                	div    %edi
f01033da:	89 c5                	mov    %eax,%ebp
f01033dc:	89 c8                	mov    %ecx,%eax
f01033de:	31 d2                	xor    %edx,%edx
f01033e0:	f7 f5                	div    %ebp
f01033e2:	89 c1                	mov    %eax,%ecx
f01033e4:	89 d8                	mov    %ebx,%eax
f01033e6:	89 cf                	mov    %ecx,%edi
f01033e8:	f7 f5                	div    %ebp
f01033ea:	89 c3                	mov    %eax,%ebx
f01033ec:	89 d8                	mov    %ebx,%eax
f01033ee:	89 fa                	mov    %edi,%edx
f01033f0:	83 c4 1c             	add    $0x1c,%esp
f01033f3:	5b                   	pop    %ebx
f01033f4:	5e                   	pop    %esi
f01033f5:	5f                   	pop    %edi
f01033f6:	5d                   	pop    %ebp
f01033f7:	c3                   	ret    
f01033f8:	90                   	nop
f01033f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103400:	39 ce                	cmp    %ecx,%esi
f0103402:	77 74                	ja     f0103478 <__udivdi3+0xd8>
f0103404:	0f bd fe             	bsr    %esi,%edi
f0103407:	83 f7 1f             	xor    $0x1f,%edi
f010340a:	0f 84 98 00 00 00    	je     f01034a8 <__udivdi3+0x108>
f0103410:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103415:	89 f9                	mov    %edi,%ecx
f0103417:	89 c5                	mov    %eax,%ebp
f0103419:	29 fb                	sub    %edi,%ebx
f010341b:	d3 e6                	shl    %cl,%esi
f010341d:	89 d9                	mov    %ebx,%ecx
f010341f:	d3 ed                	shr    %cl,%ebp
f0103421:	89 f9                	mov    %edi,%ecx
f0103423:	d3 e0                	shl    %cl,%eax
f0103425:	09 ee                	or     %ebp,%esi
f0103427:	89 d9                	mov    %ebx,%ecx
f0103429:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010342d:	89 d5                	mov    %edx,%ebp
f010342f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103433:	d3 ed                	shr    %cl,%ebp
f0103435:	89 f9                	mov    %edi,%ecx
f0103437:	d3 e2                	shl    %cl,%edx
f0103439:	89 d9                	mov    %ebx,%ecx
f010343b:	d3 e8                	shr    %cl,%eax
f010343d:	09 c2                	or     %eax,%edx
f010343f:	89 d0                	mov    %edx,%eax
f0103441:	89 ea                	mov    %ebp,%edx
f0103443:	f7 f6                	div    %esi
f0103445:	89 d5                	mov    %edx,%ebp
f0103447:	89 c3                	mov    %eax,%ebx
f0103449:	f7 64 24 0c          	mull   0xc(%esp)
f010344d:	39 d5                	cmp    %edx,%ebp
f010344f:	72 10                	jb     f0103461 <__udivdi3+0xc1>
f0103451:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103455:	89 f9                	mov    %edi,%ecx
f0103457:	d3 e6                	shl    %cl,%esi
f0103459:	39 c6                	cmp    %eax,%esi
f010345b:	73 07                	jae    f0103464 <__udivdi3+0xc4>
f010345d:	39 d5                	cmp    %edx,%ebp
f010345f:	75 03                	jne    f0103464 <__udivdi3+0xc4>
f0103461:	83 eb 01             	sub    $0x1,%ebx
f0103464:	31 ff                	xor    %edi,%edi
f0103466:	89 d8                	mov    %ebx,%eax
f0103468:	89 fa                	mov    %edi,%edx
f010346a:	83 c4 1c             	add    $0x1c,%esp
f010346d:	5b                   	pop    %ebx
f010346e:	5e                   	pop    %esi
f010346f:	5f                   	pop    %edi
f0103470:	5d                   	pop    %ebp
f0103471:	c3                   	ret    
f0103472:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103478:	31 ff                	xor    %edi,%edi
f010347a:	31 db                	xor    %ebx,%ebx
f010347c:	89 d8                	mov    %ebx,%eax
f010347e:	89 fa                	mov    %edi,%edx
f0103480:	83 c4 1c             	add    $0x1c,%esp
f0103483:	5b                   	pop    %ebx
f0103484:	5e                   	pop    %esi
f0103485:	5f                   	pop    %edi
f0103486:	5d                   	pop    %ebp
f0103487:	c3                   	ret    
f0103488:	90                   	nop
f0103489:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103490:	89 d8                	mov    %ebx,%eax
f0103492:	f7 f7                	div    %edi
f0103494:	31 ff                	xor    %edi,%edi
f0103496:	89 c3                	mov    %eax,%ebx
f0103498:	89 d8                	mov    %ebx,%eax
f010349a:	89 fa                	mov    %edi,%edx
f010349c:	83 c4 1c             	add    $0x1c,%esp
f010349f:	5b                   	pop    %ebx
f01034a0:	5e                   	pop    %esi
f01034a1:	5f                   	pop    %edi
f01034a2:	5d                   	pop    %ebp
f01034a3:	c3                   	ret    
f01034a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034a8:	39 ce                	cmp    %ecx,%esi
f01034aa:	72 0c                	jb     f01034b8 <__udivdi3+0x118>
f01034ac:	31 db                	xor    %ebx,%ebx
f01034ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01034b2:	0f 87 34 ff ff ff    	ja     f01033ec <__udivdi3+0x4c>
f01034b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01034bd:	e9 2a ff ff ff       	jmp    f01033ec <__udivdi3+0x4c>
f01034c2:	66 90                	xchg   %ax,%ax
f01034c4:	66 90                	xchg   %ax,%ax
f01034c6:	66 90                	xchg   %ax,%ax
f01034c8:	66 90                	xchg   %ax,%ax
f01034ca:	66 90                	xchg   %ax,%ax
f01034cc:	66 90                	xchg   %ax,%ax
f01034ce:	66 90                	xchg   %ax,%ax

f01034d0 <__umoddi3>:
f01034d0:	55                   	push   %ebp
f01034d1:	57                   	push   %edi
f01034d2:	56                   	push   %esi
f01034d3:	53                   	push   %ebx
f01034d4:	83 ec 1c             	sub    $0x1c,%esp
f01034d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01034db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01034df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01034e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034e7:	85 d2                	test   %edx,%edx
f01034e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01034ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01034f1:	89 f3                	mov    %esi,%ebx
f01034f3:	89 3c 24             	mov    %edi,(%esp)
f01034f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034fa:	75 1c                	jne    f0103518 <__umoddi3+0x48>
f01034fc:	39 f7                	cmp    %esi,%edi
f01034fe:	76 50                	jbe    f0103550 <__umoddi3+0x80>
f0103500:	89 c8                	mov    %ecx,%eax
f0103502:	89 f2                	mov    %esi,%edx
f0103504:	f7 f7                	div    %edi
f0103506:	89 d0                	mov    %edx,%eax
f0103508:	31 d2                	xor    %edx,%edx
f010350a:	83 c4 1c             	add    $0x1c,%esp
f010350d:	5b                   	pop    %ebx
f010350e:	5e                   	pop    %esi
f010350f:	5f                   	pop    %edi
f0103510:	5d                   	pop    %ebp
f0103511:	c3                   	ret    
f0103512:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103518:	39 f2                	cmp    %esi,%edx
f010351a:	89 d0                	mov    %edx,%eax
f010351c:	77 52                	ja     f0103570 <__umoddi3+0xa0>
f010351e:	0f bd ea             	bsr    %edx,%ebp
f0103521:	83 f5 1f             	xor    $0x1f,%ebp
f0103524:	75 5a                	jne    f0103580 <__umoddi3+0xb0>
f0103526:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010352a:	0f 82 e0 00 00 00    	jb     f0103610 <__umoddi3+0x140>
f0103530:	39 0c 24             	cmp    %ecx,(%esp)
f0103533:	0f 86 d7 00 00 00    	jbe    f0103610 <__umoddi3+0x140>
f0103539:	8b 44 24 08          	mov    0x8(%esp),%eax
f010353d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103541:	83 c4 1c             	add    $0x1c,%esp
f0103544:	5b                   	pop    %ebx
f0103545:	5e                   	pop    %esi
f0103546:	5f                   	pop    %edi
f0103547:	5d                   	pop    %ebp
f0103548:	c3                   	ret    
f0103549:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103550:	85 ff                	test   %edi,%edi
f0103552:	89 fd                	mov    %edi,%ebp
f0103554:	75 0b                	jne    f0103561 <__umoddi3+0x91>
f0103556:	b8 01 00 00 00       	mov    $0x1,%eax
f010355b:	31 d2                	xor    %edx,%edx
f010355d:	f7 f7                	div    %edi
f010355f:	89 c5                	mov    %eax,%ebp
f0103561:	89 f0                	mov    %esi,%eax
f0103563:	31 d2                	xor    %edx,%edx
f0103565:	f7 f5                	div    %ebp
f0103567:	89 c8                	mov    %ecx,%eax
f0103569:	f7 f5                	div    %ebp
f010356b:	89 d0                	mov    %edx,%eax
f010356d:	eb 99                	jmp    f0103508 <__umoddi3+0x38>
f010356f:	90                   	nop
f0103570:	89 c8                	mov    %ecx,%eax
f0103572:	89 f2                	mov    %esi,%edx
f0103574:	83 c4 1c             	add    $0x1c,%esp
f0103577:	5b                   	pop    %ebx
f0103578:	5e                   	pop    %esi
f0103579:	5f                   	pop    %edi
f010357a:	5d                   	pop    %ebp
f010357b:	c3                   	ret    
f010357c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103580:	8b 34 24             	mov    (%esp),%esi
f0103583:	bf 20 00 00 00       	mov    $0x20,%edi
f0103588:	89 e9                	mov    %ebp,%ecx
f010358a:	29 ef                	sub    %ebp,%edi
f010358c:	d3 e0                	shl    %cl,%eax
f010358e:	89 f9                	mov    %edi,%ecx
f0103590:	89 f2                	mov    %esi,%edx
f0103592:	d3 ea                	shr    %cl,%edx
f0103594:	89 e9                	mov    %ebp,%ecx
f0103596:	09 c2                	or     %eax,%edx
f0103598:	89 d8                	mov    %ebx,%eax
f010359a:	89 14 24             	mov    %edx,(%esp)
f010359d:	89 f2                	mov    %esi,%edx
f010359f:	d3 e2                	shl    %cl,%edx
f01035a1:	89 f9                	mov    %edi,%ecx
f01035a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035ab:	d3 e8                	shr    %cl,%eax
f01035ad:	89 e9                	mov    %ebp,%ecx
f01035af:	89 c6                	mov    %eax,%esi
f01035b1:	d3 e3                	shl    %cl,%ebx
f01035b3:	89 f9                	mov    %edi,%ecx
f01035b5:	89 d0                	mov    %edx,%eax
f01035b7:	d3 e8                	shr    %cl,%eax
f01035b9:	89 e9                	mov    %ebp,%ecx
f01035bb:	09 d8                	or     %ebx,%eax
f01035bd:	89 d3                	mov    %edx,%ebx
f01035bf:	89 f2                	mov    %esi,%edx
f01035c1:	f7 34 24             	divl   (%esp)
f01035c4:	89 d6                	mov    %edx,%esi
f01035c6:	d3 e3                	shl    %cl,%ebx
f01035c8:	f7 64 24 04          	mull   0x4(%esp)
f01035cc:	39 d6                	cmp    %edx,%esi
f01035ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035d2:	89 d1                	mov    %edx,%ecx
f01035d4:	89 c3                	mov    %eax,%ebx
f01035d6:	72 08                	jb     f01035e0 <__umoddi3+0x110>
f01035d8:	75 11                	jne    f01035eb <__umoddi3+0x11b>
f01035da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01035de:	73 0b                	jae    f01035eb <__umoddi3+0x11b>
f01035e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01035e4:	1b 14 24             	sbb    (%esp),%edx
f01035e7:	89 d1                	mov    %edx,%ecx
f01035e9:	89 c3                	mov    %eax,%ebx
f01035eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01035ef:	29 da                	sub    %ebx,%edx
f01035f1:	19 ce                	sbb    %ecx,%esi
f01035f3:	89 f9                	mov    %edi,%ecx
f01035f5:	89 f0                	mov    %esi,%eax
f01035f7:	d3 e0                	shl    %cl,%eax
f01035f9:	89 e9                	mov    %ebp,%ecx
f01035fb:	d3 ea                	shr    %cl,%edx
f01035fd:	89 e9                	mov    %ebp,%ecx
f01035ff:	d3 ee                	shr    %cl,%esi
f0103601:	09 d0                	or     %edx,%eax
f0103603:	89 f2                	mov    %esi,%edx
f0103605:	83 c4 1c             	add    $0x1c,%esp
f0103608:	5b                   	pop    %ebx
f0103609:	5e                   	pop    %esi
f010360a:	5f                   	pop    %edi
f010360b:	5d                   	pop    %ebp
f010360c:	c3                   	ret    
f010360d:	8d 76 00             	lea    0x0(%esi),%esi
f0103610:	29 f9                	sub    %edi,%ecx
f0103612:	19 d6                	sbb    %edx,%esi
f0103614:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103618:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010361c:	e9 18 ff ff ff       	jmp    f0103539 <__umoddi3+0x69>
