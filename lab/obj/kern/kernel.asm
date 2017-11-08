
obj/kern/kernel：     文件格式 elf32-i386


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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 40 19 10 f0       	push   $0xf0101940
f0100050:	e8 7c 09 00 00       	call   f01009d1 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 26 07 00 00       	call   f01007a1 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 5c 19 10 f0       	push   $0xf010195c
f0100087:	e8 45 09 00 00       	call   f01009d1 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 e4 13 00 00       	call   f0101495 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 d0 04 00 00       	call   f0100586 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 77 19 10 f0       	push   $0xf0101977
f01000c3:	e8 09 09 00 00       	call   f01009d1 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 70 07 00 00       	call   f0100851 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 92 19 10 f0       	push   $0xf0101992
f0100110:	e8 bc 08 00 00       	call   f01009d1 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 8c 08 00 00       	call   f01009ab <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f0100126:	e8 a6 08 00 00       	call   f01009d1 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 19 07 00 00       	call   f0100851 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 aa 19 10 f0       	push   $0xf01019aa
f0100152:	e8 7a 08 00 00       	call   f01009d1 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 48 08 00 00       	call   f01009ab <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f010016a:	e8 62 08 00 00       	call   f01009d1 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f8 00 00 00    	je     f01002df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 f6 00 00 00    	jne    f01002e5 <kbd_proc_data+0x10c>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100208:	55                   	push   %ebp
f0100209:	89 e5                	mov    %esp,%ebp
f010020b:	53                   	push   %ebx
f010020c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010020f:	84 c0                	test   %al,%al
f0100211:	79 36                	jns    f0100249 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100213:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100219:	89 cb                	mov    %ecx,%ebx
f010021b:	83 e3 40             	and    $0x40,%ebx
f010021e:	83 e0 7f             	and    $0x7f,%eax
f0100221:	85 db                	test   %ebx,%ebx
f0100223:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100226:	0f b6 d2             	movzbl %dl,%edx
f0100229:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
f0100230:	83 c8 40             	or     $0x40,%eax
f0100233:	0f b6 c0             	movzbl %al,%eax
f0100236:	f7 d0                	not    %eax
f0100238:	21 c8                	and    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010023f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100244:	e9 a4 00 00 00       	jmp    f01002ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100249:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010024f:	f6 c1 40             	test   $0x40,%cl
f0100252:	74 0e                	je     f0100262 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100254:	83 c8 80             	or     $0xffffff80,%eax
f0100257:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100259:	83 e1 bf             	and    $0xffffffbf,%ecx
f010025c:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100262:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
f010026c:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100272:	0f b6 8a 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%ecx
f0100279:	31 c8                	xor    %ecx,%eax
f010027b:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100280:	89 c1                	mov    %eax,%ecx
f0100282:	83 e1 03             	and    $0x3,%ecx
f0100285:	8b 0c 8d 00 1a 10 f0 	mov    -0xfefe600(,%ecx,4),%ecx
f010028c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100290:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100293:	a8 08                	test   $0x8,%al
f0100295:	74 1b                	je     f01002b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100297:	89 da                	mov    %ebx,%edx
f0100299:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010029c:	83 f9 19             	cmp    $0x19,%ecx
f010029f:	77 05                	ja     f01002a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002a1:	83 eb 20             	sub    $0x20,%ebx
f01002a4:	eb 0c                	jmp    f01002b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ac:	83 fa 19             	cmp    $0x19,%edx
f01002af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b2:	f7 d0                	not    %eax
f01002b4:	a8 06                	test   $0x6,%al
f01002b6:	75 33                	jne    f01002eb <kbd_proc_data+0x112>
f01002b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002be:	75 2b                	jne    f01002eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002c0:	83 ec 0c             	sub    $0xc,%esp
f01002c3:	68 c4 19 10 f0       	push   $0xf01019c4
f01002c8:	e8 04 07 00 00       	call   f01009d1 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d7:	ee                   	out    %al,(%dx)
f01002d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
f01002dd:	eb 0e                	jmp    f01002ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002eb:	89 d8                	mov    %ebx,%eax
}
f01002ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002f0:	c9                   	leave  
f01002f1:	c3                   	ret    

f01002f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f2:	55                   	push   %ebp
f01002f3:	89 e5                	mov    %esp,%ebp
f01002f5:	57                   	push   %edi
f01002f6:	56                   	push   %esi
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 1c             	sub    $0x1c,%esp
f01002fb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100302:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100307:	b9 84 00 00 00       	mov    $0x84,%ecx
f010030c:	eb 09                	jmp    f0100317 <cons_putc+0x25>
f010030e:	89 ca                	mov    %ecx,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	ec                   	in     (%dx),%al
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100314:	83 c3 01             	add    $0x1,%ebx
f0100317:	89 f2                	mov    %esi,%edx
f0100319:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 08                	jne    f0100326 <cons_putc+0x34>
f010031e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100324:	7e e8                	jle    f010030e <cons_putc+0x1c>
f0100326:	89 f8                	mov    %edi,%eax
f0100328:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100330:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100331:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100336:	be 79 03 00 00       	mov    $0x379,%esi
f010033b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100340:	eb 09                	jmp    f010034b <cons_putc+0x59>
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	83 c3 01             	add    $0x1,%ebx
f010034b:	89 f2                	mov    %esi,%edx
f010034d:	ec                   	in     (%dx),%al
f010034e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100354:	7f 04                	jg     f010035a <cons_putc+0x68>
f0100356:	84 c0                	test   %al,%al
f0100358:	79 e8                	jns    f0100342 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010035a:	ba 78 03 00 00       	mov    $0x378,%edx
f010035f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100363:	ee                   	out    %al,(%dx)
f0100364:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100369:	b8 0d 00 00 00       	mov    $0xd,%eax
f010036e:	ee                   	out    %al,(%dx)
f010036f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100374:	ee                   	out    %al,(%dx)
cga_putc(int c)
{
	
	// if no attribute given, then use black on white
	
	if (!(c & ~0xFF)) {
f0100375:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f010037b:	75 3d                	jne    f01003ba <cons_putc+0xc8>
    char ch = c & 0xFF;
    if (ch > 47 && ch < 58) {
f010037d:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100381:	83 e8 30             	sub    $0x30,%eax
f0100384:	3c 09                	cmp    $0x9,%al
f0100386:	77 08                	ja     f0100390 <cons_putc+0x9e>
        c |= 0x0700;
f0100388:	81 cf 00 07 00 00    	or     $0x700,%edi
f010038e:	eb 2a                	jmp    f01003ba <cons_putc+0xc8>
    } else if (ch > 64 && ch < 91) {
f0100390:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100394:	83 e8 41             	sub    $0x41,%eax
f0100397:	3c 19                	cmp    $0x19,%al
f0100399:	77 08                	ja     f01003a3 <cons_putc+0xb1>
        c |= 0x0200;
f010039b:	81 cf 00 02 00 00    	or     $0x200,%edi
f01003a1:	eb 17                	jmp    f01003ba <cons_putc+0xc8>
    } else if (ch > 96 && ch < 123) {
f01003a3:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01003a7:	83 e8 61             	sub    $0x61,%eax
        c |= 0x0300;
f01003aa:	89 fa                	mov    %edi,%edx
f01003ac:	80 ce 03             	or     $0x3,%dh
f01003af:	81 cf 00 04 00 00    	or     $0x400,%edi
f01003b5:	3c 19                	cmp    $0x19,%al
f01003b7:	0f 46 fa             	cmovbe %edx,%edi
    } else {
        c |= 0x0400;
    }
}

	switch (c & 0xff) {
f01003ba:	89 f8                	mov    %edi,%eax
f01003bc:	0f b6 c0             	movzbl %al,%eax
f01003bf:	83 f8 09             	cmp    $0x9,%eax
f01003c2:	74 74                	je     f0100438 <cons_putc+0x146>
f01003c4:	83 f8 09             	cmp    $0x9,%eax
f01003c7:	7f 0a                	jg     f01003d3 <cons_putc+0xe1>
f01003c9:	83 f8 08             	cmp    $0x8,%eax
f01003cc:	74 14                	je     f01003e2 <cons_putc+0xf0>
f01003ce:	e9 99 00 00 00       	jmp    f010046c <cons_putc+0x17a>
f01003d3:	83 f8 0a             	cmp    $0xa,%eax
f01003d6:	74 3a                	je     f0100412 <cons_putc+0x120>
f01003d8:	83 f8 0d             	cmp    $0xd,%eax
f01003db:	74 3d                	je     f010041a <cons_putc+0x128>
f01003dd:	e9 8a 00 00 00       	jmp    f010046c <cons_putc+0x17a>
	case '\b':
		if (crt_pos > 0) {
f01003e2:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e9:	66 85 c0             	test   %ax,%ax
f01003ec:	0f 84 e6 00 00 00    	je     f01004d8 <cons_putc+0x1e6>
			crt_pos--;
f01003f2:	83 e8 01             	sub    $0x1,%eax
f01003f5:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003fb:	0f b7 c0             	movzwl %ax,%eax
f01003fe:	66 81 e7 00 ff       	and    $0xff00,%di
f0100403:	83 cf 20             	or     $0x20,%edi
f0100406:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f010040c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100410:	eb 78                	jmp    f010048a <cons_putc+0x198>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100412:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100419:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010041a:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100421:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100427:	c1 e8 16             	shr    $0x16,%eax
f010042a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010042d:	c1 e0 04             	shl    $0x4,%eax
f0100430:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100436:	eb 52                	jmp    f010048a <cons_putc+0x198>
		break;
	case '\t':
		cons_putc(' ');
f0100438:	b8 20 00 00 00       	mov    $0x20,%eax
f010043d:	e8 b0 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100442:	b8 20 00 00 00       	mov    $0x20,%eax
f0100447:	e8 a6 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010044c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100451:	e8 9c fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100456:	b8 20 00 00 00       	mov    $0x20,%eax
f010045b:	e8 92 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100460:	b8 20 00 00 00       	mov    $0x20,%eax
f0100465:	e8 88 fe ff ff       	call   f01002f2 <cons_putc>
f010046a:	eb 1e                	jmp    f010048a <cons_putc+0x198>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010046c:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100473:	8d 50 01             	lea    0x1(%eax),%edx
f0100476:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010047d:	0f b7 c0             	movzwl %ax,%eax
f0100480:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100486:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010048a:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100491:	cf 07 
f0100493:	76 43                	jbe    f01004d8 <cons_putc+0x1e6>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100495:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f010049a:	83 ec 04             	sub    $0x4,%esp
f010049d:	68 00 0f 00 00       	push   $0xf00
f01004a2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004a8:	52                   	push   %edx
f01004a9:	50                   	push   %eax
f01004aa:	e8 33 10 00 00       	call   f01014e2 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004af:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01004b5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004bb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004c1:	83 c4 10             	add    $0x10,%esp
f01004c4:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004c9:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004cc:	39 d0                	cmp    %edx,%eax
f01004ce:	75 f4                	jne    f01004c4 <cons_putc+0x1d2>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004d0:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004d7:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004d8:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004de:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004e3:	89 ca                	mov    %ecx,%edx
f01004e5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004e6:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ed:	8d 71 01             	lea    0x1(%ecx),%esi
f01004f0:	89 d8                	mov    %ebx,%eax
f01004f2:	66 c1 e8 08          	shr    $0x8,%ax
f01004f6:	89 f2                	mov    %esi,%edx
f01004f8:	ee                   	out    %al,(%dx)
f01004f9:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004fe:	89 ca                	mov    %ecx,%edx
f0100500:	ee                   	out    %al,(%dx)
f0100501:	89 d8                	mov    %ebx,%eax
f0100503:	89 f2                	mov    %esi,%edx
f0100505:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100506:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100509:	5b                   	pop    %ebx
f010050a:	5e                   	pop    %esi
f010050b:	5f                   	pop    %edi
f010050c:	5d                   	pop    %ebp
f010050d:	c3                   	ret    

f010050e <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f010050e:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f0100515:	74 11                	je     f0100528 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100517:	55                   	push   %ebp
f0100518:	89 e5                	mov    %esp,%ebp
f010051a:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010051d:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f0100522:	e8 6f fc ff ff       	call   f0100196 <cons_intr>
}
f0100527:	c9                   	leave  
f0100528:	f3 c3                	repz ret 

f010052a <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010052a:	55                   	push   %ebp
f010052b:	89 e5                	mov    %esp,%ebp
f010052d:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100530:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100535:	e8 5c fc ff ff       	call   f0100196 <cons_intr>
}
f010053a:	c9                   	leave  
f010053b:	c3                   	ret    

f010053c <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010053c:	55                   	push   %ebp
f010053d:	89 e5                	mov    %esp,%ebp
f010053f:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100542:	e8 c7 ff ff ff       	call   f010050e <serial_intr>
	kbd_intr();
f0100547:	e8 de ff ff ff       	call   f010052a <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010054c:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100551:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100557:	74 26                	je     f010057f <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100559:	8d 50 01             	lea    0x1(%eax),%edx
f010055c:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100562:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100569:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010056b:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100571:	75 11                	jne    f0100584 <cons_getc+0x48>
			cons.rpos = 0;
f0100573:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f010057a:	00 00 00 
f010057d:	eb 05                	jmp    f0100584 <cons_getc+0x48>
		return c;
	}
	return 0;
f010057f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100584:	c9                   	leave  
f0100585:	c3                   	ret    

f0100586 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100586:	55                   	push   %ebp
f0100587:	89 e5                	mov    %esp,%ebp
f0100589:	57                   	push   %edi
f010058a:	56                   	push   %esi
f010058b:	53                   	push   %ebx
f010058c:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010058f:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100596:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010059d:	5a a5 
	if (*cp != 0xA55A) {
f010059f:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005a6:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005aa:	74 11                	je     f01005bd <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005ac:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f01005b3:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005b6:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01005bb:	eb 16                	jmp    f01005d3 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005bd:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005c4:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005cb:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005ce:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005d3:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005d9:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005de:	89 fa                	mov    %edi,%edx
f01005e0:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005e1:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e4:	89 da                	mov    %ebx,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	0f b6 c8             	movzbl %al,%ecx
f01005ea:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ed:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005f2:	89 fa                	mov    %edi,%edx
f01005f4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f5:	89 da                	mov    %ebx,%edx
f01005f7:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005f8:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005fe:	0f b6 c0             	movzbl %al,%eax
f0100601:	09 c8                	or     %ecx,%eax
f0100603:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100609:	be fa 03 00 00       	mov    $0x3fa,%esi
f010060e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100613:	89 f2                	mov    %esi,%edx
f0100615:	ee                   	out    %al,(%dx)
f0100616:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010061b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100620:	ee                   	out    %al,(%dx)
f0100621:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100626:	b8 0c 00 00 00       	mov    $0xc,%eax
f010062b:	89 da                	mov    %ebx,%edx
f010062d:	ee                   	out    %al,(%dx)
f010062e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100633:	b8 00 00 00 00       	mov    $0x0,%eax
f0100638:	ee                   	out    %al,(%dx)
f0100639:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010063e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100643:	ee                   	out    %al,(%dx)
f0100644:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100649:	b8 00 00 00 00       	mov    $0x0,%eax
f010064e:	ee                   	out    %al,(%dx)
f010064f:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100654:	b8 01 00 00 00       	mov    $0x1,%eax
f0100659:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010065a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010065f:	ec                   	in     (%dx),%al
f0100660:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100662:	3c ff                	cmp    $0xff,%al
f0100664:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010066b:	89 f2                	mov    %esi,%edx
f010066d:	ec                   	in     (%dx),%al
f010066e:	89 da                	mov    %ebx,%edx
f0100670:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100671:	80 f9 ff             	cmp    $0xff,%cl
f0100674:	75 10                	jne    f0100686 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100676:	83 ec 0c             	sub    $0xc,%esp
f0100679:	68 d0 19 10 f0       	push   $0xf01019d0
f010067e:	e8 4e 03 00 00       	call   f01009d1 <cprintf>
f0100683:	83 c4 10             	add    $0x10,%esp
}
f0100686:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100689:	5b                   	pop    %ebx
f010068a:	5e                   	pop    %esi
f010068b:	5f                   	pop    %edi
f010068c:	5d                   	pop    %ebp
f010068d:	c3                   	ret    

f010068e <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010068e:	55                   	push   %ebp
f010068f:	89 e5                	mov    %esp,%ebp
f0100691:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100694:	8b 45 08             	mov    0x8(%ebp),%eax
f0100697:	e8 56 fc ff ff       	call   f01002f2 <cons_putc>
}
f010069c:	c9                   	leave  
f010069d:	c3                   	ret    

f010069e <getchar>:

int
getchar(void)
{
f010069e:	55                   	push   %ebp
f010069f:	89 e5                	mov    %esp,%ebp
f01006a1:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006a4:	e8 93 fe ff ff       	call   f010053c <cons_getc>
f01006a9:	85 c0                	test   %eax,%eax
f01006ab:	74 f7                	je     f01006a4 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006ad:	c9                   	leave  
f01006ae:	c3                   	ret    

f01006af <iscons>:

int
iscons(int fdnum)
{
f01006af:	55                   	push   %ebp
f01006b0:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006b2:	b8 01 00 00 00       	mov    $0x1,%eax
f01006b7:	5d                   	pop    %ebp
f01006b8:	c3                   	ret    

f01006b9 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006b9:	55                   	push   %ebp
f01006ba:	89 e5                	mov    %esp,%ebp
f01006bc:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006bf:	68 20 1c 10 f0       	push   $0xf0101c20
f01006c4:	68 3e 1c 10 f0       	push   $0xf0101c3e
f01006c9:	68 43 1c 10 f0       	push   $0xf0101c43
f01006ce:	e8 fe 02 00 00       	call   f01009d1 <cprintf>
f01006d3:	83 c4 0c             	add    $0xc,%esp
f01006d6:	68 d4 1c 10 f0       	push   $0xf0101cd4
f01006db:	68 4c 1c 10 f0       	push   $0xf0101c4c
f01006e0:	68 43 1c 10 f0       	push   $0xf0101c43
f01006e5:	e8 e7 02 00 00       	call   f01009d1 <cprintf>
	return 0;
}
f01006ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ef:	c9                   	leave  
f01006f0:	c3                   	ret    

f01006f1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006f1:	55                   	push   %ebp
f01006f2:	89 e5                	mov    %esp,%ebp
f01006f4:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f7:	68 55 1c 10 f0       	push   $0xf0101c55
f01006fc:	e8 d0 02 00 00       	call   f01009d1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100701:	83 c4 08             	add    $0x8,%esp
f0100704:	68 0c 00 10 00       	push   $0x10000c
f0100709:	68 fc 1c 10 f0       	push   $0xf0101cfc
f010070e:	e8 be 02 00 00       	call   f01009d1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100713:	83 c4 0c             	add    $0xc,%esp
f0100716:	68 0c 00 10 00       	push   $0x10000c
f010071b:	68 0c 00 10 f0       	push   $0xf010000c
f0100720:	68 24 1d 10 f0       	push   $0xf0101d24
f0100725:	e8 a7 02 00 00       	call   f01009d1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010072a:	83 c4 0c             	add    $0xc,%esp
f010072d:	68 21 19 10 00       	push   $0x101921
f0100732:	68 21 19 10 f0       	push   $0xf0101921
f0100737:	68 48 1d 10 f0       	push   $0xf0101d48
f010073c:	e8 90 02 00 00       	call   f01009d1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100741:	83 c4 0c             	add    $0xc,%esp
f0100744:	68 00 23 11 00       	push   $0x112300
f0100749:	68 00 23 11 f0       	push   $0xf0112300
f010074e:	68 6c 1d 10 f0       	push   $0xf0101d6c
f0100753:	e8 79 02 00 00       	call   f01009d1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100758:	83 c4 0c             	add    $0xc,%esp
f010075b:	68 44 29 11 00       	push   $0x112944
f0100760:	68 44 29 11 f0       	push   $0xf0112944
f0100765:	68 90 1d 10 f0       	push   $0xf0101d90
f010076a:	e8 62 02 00 00       	call   f01009d1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010076f:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100774:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100779:	83 c4 08             	add    $0x8,%esp
f010077c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100781:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100787:	85 c0                	test   %eax,%eax
f0100789:	0f 48 c2             	cmovs  %edx,%eax
f010078c:	c1 f8 0a             	sar    $0xa,%eax
f010078f:	50                   	push   %eax
f0100790:	68 b4 1d 10 f0       	push   $0xf0101db4
f0100795:	e8 37 02 00 00       	call   f01009d1 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010079a:	b8 00 00 00 00       	mov    $0x0,%eax
f010079f:	c9                   	leave  
f01007a0:	c3                   	ret    

f01007a1 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007a1:	55                   	push   %ebp
f01007a2:	89 e5                	mov    %esp,%ebp
f01007a4:	57                   	push   %edi
f01007a5:	56                   	push   %esi
f01007a6:	53                   	push   %ebx
f01007a7:	83 ec 48             	sub    $0x48,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01007aa:	89 e8                	mov    %ebp,%eax
	// Your code here.
	uint32_t *ebp,*eip;
	uint32_t arg0,arg1,arg2,arg3,arg4;
	ebp=(uint32_t*)read_ebp();
f01007ac:	89 c3                	mov    %eax,%ebx
	eip=(uint32_t*)ebp[1];
f01007ae:	8b 78 04             	mov    0x4(%eax),%edi
	arg0=ebp[2];
f01007b1:	8b 50 08             	mov    0x8(%eax),%edx
f01007b4:	89 55 c0             	mov    %edx,-0x40(%ebp)
	arg1=ebp[3];
f01007b7:	8b 48 0c             	mov    0xc(%eax),%ecx
f01007ba:	89 4d bc             	mov    %ecx,-0x44(%ebp)
	arg2=ebp[4];
f01007bd:	8b 70 10             	mov    0x10(%eax),%esi
f01007c0:	89 75 b8             	mov    %esi,-0x48(%ebp)
	arg3=ebp[5];
f01007c3:	8b 70 14             	mov    0x14(%eax),%esi
f01007c6:	89 75 c4             	mov    %esi,-0x3c(%ebp)
	arg4=ebp[6];
f01007c9:	8b 70 18             	mov    0x18(%eax),%esi

	cprintf("Stack_backtrace:\n");
f01007cc:	68 6e 1c 10 f0       	push   $0xf0101c6e
f01007d1:	e8 fb 01 00 00       	call   f01009d1 <cprintf>
	while(ebp!=0){
f01007d6:	83 c4 10             	add    $0x10,%esp
f01007d9:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01007dc:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01007df:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01007e2:	eb 5c                	jmp    f0100840 <mon_backtrace+0x9f>
		cprintf("  ebp %08x eip %08x  args %08x %08x %08x %08x %08x\n",ebp,eip,arg0,arg1,arg2,arg3,arg4);
f01007e4:	56                   	push   %esi
f01007e5:	ff 75 c4             	pushl  -0x3c(%ebp)
f01007e8:	51                   	push   %ecx
f01007e9:	52                   	push   %edx
f01007ea:	50                   	push   %eax
f01007eb:	57                   	push   %edi
f01007ec:	53                   	push   %ebx
f01007ed:	68 e0 1d 10 f0       	push   $0xf0101de0
f01007f2:	e8 da 01 00 00       	call   f01009d1 <cprintf>

		struct Eipdebuginfo info;
		debuginfo_eip(ebp[1], &info);
f01007f7:	83 c4 18             	add    $0x18,%esp
f01007fa:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007fd:	50                   	push   %eax
f01007fe:	ff 73 04             	pushl  0x4(%ebx)
f0100801:	e8 d5 02 00 00       	call   f0100adb <debuginfo_eip>
   		cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
f0100806:	83 c4 08             	add    $0x8,%esp
f0100809:	8b 43 04             	mov    0x4(%ebx),%eax
f010080c:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010080f:	50                   	push   %eax
f0100810:	ff 75 d8             	pushl  -0x28(%ebp)
f0100813:	ff 75 dc             	pushl  -0x24(%ebp)
f0100816:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100819:	ff 75 d0             	pushl  -0x30(%ebp)
f010081c:	68 80 1c 10 f0       	push   $0xf0101c80
f0100821:	e8 ab 01 00 00       	call   f01009d1 <cprintf>
    		ebp = (uint32_t*)ebp[0];
f0100826:	8b 1b                	mov    (%ebx),%ebx
		eip=(uint32_t*)ebp[1];
f0100828:	8b 7b 04             	mov    0x4(%ebx),%edi
		arg0=ebp[2];
f010082b:	8b 43 08             	mov    0x8(%ebx),%eax
		arg1=ebp[3];
f010082e:	8b 53 0c             	mov    0xc(%ebx),%edx
		arg2=ebp[4];
f0100831:	8b 4b 10             	mov    0x10(%ebx),%ecx
		arg3=ebp[5];	
f0100834:	8b 73 14             	mov    0x14(%ebx),%esi
f0100837:	89 75 c4             	mov    %esi,-0x3c(%ebp)
		arg4=ebp[6];
f010083a:	8b 73 18             	mov    0x18(%ebx),%esi
f010083d:	83 c4 20             	add    $0x20,%esp
	arg2=ebp[4];
	arg3=ebp[5];
	arg4=ebp[6];

	cprintf("Stack_backtrace:\n");
	while(ebp!=0){
f0100840:	85 db                	test   %ebx,%ebx
f0100842:	75 a0                	jne    f01007e4 <mon_backtrace+0x43>
		arg2=ebp[4];
		arg3=ebp[5];	
		arg4=ebp[6];
	}
	return 0;
}
f0100844:	b8 00 00 00 00       	mov    $0x0,%eax
f0100849:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010084c:	5b                   	pop    %ebx
f010084d:	5e                   	pop    %esi
f010084e:	5f                   	pop    %edi
f010084f:	5d                   	pop    %ebp
f0100850:	c3                   	ret    

f0100851 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100851:	55                   	push   %ebp
f0100852:	89 e5                	mov    %esp,%ebp
f0100854:	57                   	push   %edi
f0100855:	56                   	push   %esi
f0100856:	53                   	push   %ebx
f0100857:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010085a:	68 14 1e 10 f0       	push   $0xf0101e14
f010085f:	e8 6d 01 00 00       	call   f01009d1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100864:	c7 04 24 38 1e 10 f0 	movl   $0xf0101e38,(%esp)
f010086b:	e8 61 01 00 00       	call   f01009d1 <cprintf>
f0100870:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100873:	83 ec 0c             	sub    $0xc,%esp
f0100876:	68 96 1c 10 f0       	push   $0xf0101c96
f010087b:	e8 be 09 00 00       	call   f010123e <readline>
f0100880:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100882:	83 c4 10             	add    $0x10,%esp
f0100885:	85 c0                	test   %eax,%eax
f0100887:	74 ea                	je     f0100873 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100889:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100890:	be 00 00 00 00       	mov    $0x0,%esi
f0100895:	eb 0a                	jmp    f01008a1 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100897:	c6 03 00             	movb   $0x0,(%ebx)
f010089a:	89 f7                	mov    %esi,%edi
f010089c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010089f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008a1:	0f b6 03             	movzbl (%ebx),%eax
f01008a4:	84 c0                	test   %al,%al
f01008a6:	74 63                	je     f010090b <monitor+0xba>
f01008a8:	83 ec 08             	sub    $0x8,%esp
f01008ab:	0f be c0             	movsbl %al,%eax
f01008ae:	50                   	push   %eax
f01008af:	68 9a 1c 10 f0       	push   $0xf0101c9a
f01008b4:	e8 9f 0b 00 00       	call   f0101458 <strchr>
f01008b9:	83 c4 10             	add    $0x10,%esp
f01008bc:	85 c0                	test   %eax,%eax
f01008be:	75 d7                	jne    f0100897 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01008c0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008c3:	74 46                	je     f010090b <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008c5:	83 fe 0f             	cmp    $0xf,%esi
f01008c8:	75 14                	jne    f01008de <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008ca:	83 ec 08             	sub    $0x8,%esp
f01008cd:	6a 10                	push   $0x10
f01008cf:	68 9f 1c 10 f0       	push   $0xf0101c9f
f01008d4:	e8 f8 00 00 00       	call   f01009d1 <cprintf>
f01008d9:	83 c4 10             	add    $0x10,%esp
f01008dc:	eb 95                	jmp    f0100873 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01008de:	8d 7e 01             	lea    0x1(%esi),%edi
f01008e1:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008e5:	eb 03                	jmp    f01008ea <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008e7:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ea:	0f b6 03             	movzbl (%ebx),%eax
f01008ed:	84 c0                	test   %al,%al
f01008ef:	74 ae                	je     f010089f <monitor+0x4e>
f01008f1:	83 ec 08             	sub    $0x8,%esp
f01008f4:	0f be c0             	movsbl %al,%eax
f01008f7:	50                   	push   %eax
f01008f8:	68 9a 1c 10 f0       	push   $0xf0101c9a
f01008fd:	e8 56 0b 00 00       	call   f0101458 <strchr>
f0100902:	83 c4 10             	add    $0x10,%esp
f0100905:	85 c0                	test   %eax,%eax
f0100907:	74 de                	je     f01008e7 <monitor+0x96>
f0100909:	eb 94                	jmp    f010089f <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f010090b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100912:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100913:	85 f6                	test   %esi,%esi
f0100915:	0f 84 58 ff ff ff    	je     f0100873 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010091b:	83 ec 08             	sub    $0x8,%esp
f010091e:	68 3e 1c 10 f0       	push   $0xf0101c3e
f0100923:	ff 75 a8             	pushl  -0x58(%ebp)
f0100926:	e8 cf 0a 00 00       	call   f01013fa <strcmp>
f010092b:	83 c4 10             	add    $0x10,%esp
f010092e:	85 c0                	test   %eax,%eax
f0100930:	74 1e                	je     f0100950 <monitor+0xff>
f0100932:	83 ec 08             	sub    $0x8,%esp
f0100935:	68 4c 1c 10 f0       	push   $0xf0101c4c
f010093a:	ff 75 a8             	pushl  -0x58(%ebp)
f010093d:	e8 b8 0a 00 00       	call   f01013fa <strcmp>
f0100942:	83 c4 10             	add    $0x10,%esp
f0100945:	85 c0                	test   %eax,%eax
f0100947:	75 2f                	jne    f0100978 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100949:	b8 01 00 00 00       	mov    $0x1,%eax
f010094e:	eb 05                	jmp    f0100955 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100950:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100955:	83 ec 04             	sub    $0x4,%esp
f0100958:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010095b:	01 d0                	add    %edx,%eax
f010095d:	ff 75 08             	pushl  0x8(%ebp)
f0100960:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100963:	51                   	push   %ecx
f0100964:	56                   	push   %esi
f0100965:	ff 14 85 68 1e 10 f0 	call   *-0xfefe198(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010096c:	83 c4 10             	add    $0x10,%esp
f010096f:	85 c0                	test   %eax,%eax
f0100971:	78 1d                	js     f0100990 <monitor+0x13f>
f0100973:	e9 fb fe ff ff       	jmp    f0100873 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100978:	83 ec 08             	sub    $0x8,%esp
f010097b:	ff 75 a8             	pushl  -0x58(%ebp)
f010097e:	68 bc 1c 10 f0       	push   $0xf0101cbc
f0100983:	e8 49 00 00 00       	call   f01009d1 <cprintf>
f0100988:	83 c4 10             	add    $0x10,%esp
f010098b:	e9 e3 fe ff ff       	jmp    f0100873 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100990:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100993:	5b                   	pop    %ebx
f0100994:	5e                   	pop    %esi
f0100995:	5f                   	pop    %edi
f0100996:	5d                   	pop    %ebp
f0100997:	c3                   	ret    

f0100998 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100998:	55                   	push   %ebp
f0100999:	89 e5                	mov    %esp,%ebp
f010099b:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010099e:	ff 75 08             	pushl  0x8(%ebp)
f01009a1:	e8 e8 fc ff ff       	call   f010068e <cputchar>
	*cnt++;
}
f01009a6:	83 c4 10             	add    $0x10,%esp
f01009a9:	c9                   	leave  
f01009aa:	c3                   	ret    

f01009ab <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009ab:	55                   	push   %ebp
f01009ac:	89 e5                	mov    %esp,%ebp
f01009ae:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01009b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009b8:	ff 75 0c             	pushl  0xc(%ebp)
f01009bb:	ff 75 08             	pushl  0x8(%ebp)
f01009be:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009c1:	50                   	push   %eax
f01009c2:	68 98 09 10 f0       	push   $0xf0100998
f01009c7:	e8 5d 04 00 00       	call   f0100e29 <vprintfmt>
	return cnt;
}
f01009cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009cf:	c9                   	leave  
f01009d0:	c3                   	ret    

f01009d1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009d1:	55                   	push   %ebp
f01009d2:	89 e5                	mov    %esp,%ebp
f01009d4:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009d7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009da:	50                   	push   %eax
f01009db:	ff 75 08             	pushl  0x8(%ebp)
f01009de:	e8 c8 ff ff ff       	call   f01009ab <vcprintf>
	va_end(ap);

	return cnt;
}
f01009e3:	c9                   	leave  
f01009e4:	c3                   	ret    

f01009e5 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009e5:	55                   	push   %ebp
f01009e6:	89 e5                	mov    %esp,%ebp
f01009e8:	57                   	push   %edi
f01009e9:	56                   	push   %esi
f01009ea:	53                   	push   %ebx
f01009eb:	83 ec 14             	sub    $0x14,%esp
f01009ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009f1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009f4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009f7:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009fa:	8b 1a                	mov    (%edx),%ebx
f01009fc:	8b 01                	mov    (%ecx),%eax
f01009fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a01:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a08:	eb 7f                	jmp    f0100a89 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0100a0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a0d:	01 d8                	add    %ebx,%eax
f0100a0f:	89 c6                	mov    %eax,%esi
f0100a11:	c1 ee 1f             	shr    $0x1f,%esi
f0100a14:	01 c6                	add    %eax,%esi
f0100a16:	d1 fe                	sar    %esi
f0100a18:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100a1b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a1e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100a21:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a23:	eb 03                	jmp    f0100a28 <stab_binsearch+0x43>
			m--;
f0100a25:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a28:	39 c3                	cmp    %eax,%ebx
f0100a2a:	7f 0d                	jg     f0100a39 <stab_binsearch+0x54>
f0100a2c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100a30:	83 ea 0c             	sub    $0xc,%edx
f0100a33:	39 f9                	cmp    %edi,%ecx
f0100a35:	75 ee                	jne    f0100a25 <stab_binsearch+0x40>
f0100a37:	eb 05                	jmp    f0100a3e <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a39:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a3c:	eb 4b                	jmp    f0100a89 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a3e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a41:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a44:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a48:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a4b:	76 11                	jbe    f0100a5e <stab_binsearch+0x79>
			*region_left = m;
f0100a4d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a50:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a52:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a55:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a5c:	eb 2b                	jmp    f0100a89 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a5e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a61:	73 14                	jae    f0100a77 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a63:	83 e8 01             	sub    $0x1,%eax
f0100a66:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a69:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a6c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a6e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a75:	eb 12                	jmp    f0100a89 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a77:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a7a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a7c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a80:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a82:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a89:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a8c:	0f 8e 78 ff ff ff    	jle    f0100a0a <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a92:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a96:	75 0f                	jne    f0100aa7 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a98:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a9b:	8b 00                	mov    (%eax),%eax
f0100a9d:	83 e8 01             	sub    $0x1,%eax
f0100aa0:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100aa3:	89 06                	mov    %eax,(%esi)
f0100aa5:	eb 2c                	jmp    f0100ad3 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aa7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aaa:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100aac:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100aaf:	8b 0e                	mov    (%esi),%ecx
f0100ab1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ab4:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100ab7:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aba:	eb 03                	jmp    f0100abf <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100abc:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100abf:	39 c8                	cmp    %ecx,%eax
f0100ac1:	7e 0b                	jle    f0100ace <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100ac3:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100ac7:	83 ea 0c             	sub    $0xc,%edx
f0100aca:	39 df                	cmp    %ebx,%edi
f0100acc:	75 ee                	jne    f0100abc <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ace:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ad1:	89 06                	mov    %eax,(%esi)
	}
}
f0100ad3:	83 c4 14             	add    $0x14,%esp
f0100ad6:	5b                   	pop    %ebx
f0100ad7:	5e                   	pop    %esi
f0100ad8:	5f                   	pop    %edi
f0100ad9:	5d                   	pop    %ebp
f0100ada:	c3                   	ret    

f0100adb <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100adb:	55                   	push   %ebp
f0100adc:	89 e5                	mov    %esp,%ebp
f0100ade:	57                   	push   %edi
f0100adf:	56                   	push   %esi
f0100ae0:	53                   	push   %ebx
f0100ae1:	83 ec 3c             	sub    $0x3c,%esp
f0100ae4:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ae7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aea:	c7 03 78 1e 10 f0    	movl   $0xf0101e78,(%ebx)
	info->eip_line = 0;
f0100af0:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100af7:	c7 43 08 78 1e 10 f0 	movl   $0xf0101e78,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100afe:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b05:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b08:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b0f:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b15:	76 11                	jbe    f0100b28 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b17:	b8 5b 74 10 f0       	mov    $0xf010745b,%eax
f0100b1c:	3d 25 5b 10 f0       	cmp    $0xf0105b25,%eax
f0100b21:	77 19                	ja     f0100b3c <debuginfo_eip+0x61>
f0100b23:	e9 b5 01 00 00       	jmp    f0100cdd <debuginfo_eip+0x202>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b28:	83 ec 04             	sub    $0x4,%esp
f0100b2b:	68 82 1e 10 f0       	push   $0xf0101e82
f0100b30:	6a 7f                	push   $0x7f
f0100b32:	68 8f 1e 10 f0       	push   $0xf0101e8f
f0100b37:	e8 aa f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b3c:	80 3d 5a 74 10 f0 00 	cmpb   $0x0,0xf010745a
f0100b43:	0f 85 9b 01 00 00    	jne    f0100ce4 <debuginfo_eip+0x209>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b49:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b50:	b8 24 5b 10 f0       	mov    $0xf0105b24,%eax
f0100b55:	2d b0 20 10 f0       	sub    $0xf01020b0,%eax
f0100b5a:	c1 f8 02             	sar    $0x2,%eax
f0100b5d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b63:	83 e8 01             	sub    $0x1,%eax
f0100b66:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b69:	83 ec 08             	sub    $0x8,%esp
f0100b6c:	56                   	push   %esi
f0100b6d:	6a 64                	push   $0x64
f0100b6f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b72:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b75:	b8 b0 20 10 f0       	mov    $0xf01020b0,%eax
f0100b7a:	e8 66 fe ff ff       	call   f01009e5 <stab_binsearch>
	if (lfile == 0)
f0100b7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b82:	83 c4 10             	add    $0x10,%esp
f0100b85:	85 c0                	test   %eax,%eax
f0100b87:	0f 84 5e 01 00 00    	je     f0100ceb <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b8d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b90:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b93:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b96:	83 ec 08             	sub    $0x8,%esp
f0100b99:	56                   	push   %esi
f0100b9a:	6a 24                	push   $0x24
f0100b9c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b9f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ba2:	b8 b0 20 10 f0       	mov    $0xf01020b0,%eax
f0100ba7:	e8 39 fe ff ff       	call   f01009e5 <stab_binsearch>

	if (lfun <= rfun) {
f0100bac:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100baf:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bb2:	83 c4 10             	add    $0x10,%esp
f0100bb5:	39 d0                	cmp    %edx,%eax
f0100bb7:	7f 40                	jg     f0100bf9 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bb9:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100bbc:	c1 e1 02             	shl    $0x2,%ecx
f0100bbf:	8d b9 b0 20 10 f0    	lea    -0xfefdf50(%ecx),%edi
f0100bc5:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bc8:	8b b9 b0 20 10 f0    	mov    -0xfefdf50(%ecx),%edi
f0100bce:	b9 5b 74 10 f0       	mov    $0xf010745b,%ecx
f0100bd3:	81 e9 25 5b 10 f0    	sub    $0xf0105b25,%ecx
f0100bd9:	39 cf                	cmp    %ecx,%edi
f0100bdb:	73 09                	jae    f0100be6 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bdd:	81 c7 25 5b 10 f0    	add    $0xf0105b25,%edi
f0100be3:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100be6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100be9:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bec:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bef:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bf1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bf4:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bf7:	eb 0f                	jmp    f0100c08 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bf9:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bfc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c02:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c05:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c08:	83 ec 08             	sub    $0x8,%esp
f0100c0b:	6a 3a                	push   $0x3a
f0100c0d:	ff 73 08             	pushl  0x8(%ebx)
f0100c10:	e8 64 08 00 00       	call   f0101479 <strfind>
f0100c15:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c18:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c1b:	83 c4 08             	add    $0x8,%esp
f0100c1e:	56                   	push   %esi
f0100c1f:	6a 44                	push   $0x44
f0100c21:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c24:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c27:	b8 b0 20 10 f0       	mov    $0xf01020b0,%eax
f0100c2c:	e8 b4 fd ff ff       	call   f01009e5 <stab_binsearch>
	if (lline > rline) {
f0100c31:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c34:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100c37:	83 c4 10             	add    $0x10,%esp
f0100c3a:	39 d0                	cmp    %edx,%eax
f0100c3c:	0f 8f b0 00 00 00    	jg     f0100cf2 <debuginfo_eip+0x217>
    		return -1;
	} else {
		info->eip_line = stabs[rline].n_desc;
f0100c42:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c45:	0f b7 14 95 b6 20 10 	movzwl -0xfefdf4a(,%edx,4),%edx
f0100c4c:	f0 
f0100c4d:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c50:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c53:	89 c2                	mov    %eax,%edx
f0100c55:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100c58:	8d 04 85 b0 20 10 f0 	lea    -0xfefdf50(,%eax,4),%eax
f0100c5f:	eb 06                	jmp    f0100c67 <debuginfo_eip+0x18c>
f0100c61:	83 ea 01             	sub    $0x1,%edx
f0100c64:	83 e8 0c             	sub    $0xc,%eax
f0100c67:	39 d7                	cmp    %edx,%edi
f0100c69:	7f 34                	jg     f0100c9f <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f0100c6b:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c6f:	80 f9 84             	cmp    $0x84,%cl
f0100c72:	74 0b                	je     f0100c7f <debuginfo_eip+0x1a4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c74:	80 f9 64             	cmp    $0x64,%cl
f0100c77:	75 e8                	jne    f0100c61 <debuginfo_eip+0x186>
f0100c79:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c7d:	74 e2                	je     f0100c61 <debuginfo_eip+0x186>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c7f:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c82:	8b 14 85 b0 20 10 f0 	mov    -0xfefdf50(,%eax,4),%edx
f0100c89:	b8 5b 74 10 f0       	mov    $0xf010745b,%eax
f0100c8e:	2d 25 5b 10 f0       	sub    $0xf0105b25,%eax
f0100c93:	39 c2                	cmp    %eax,%edx
f0100c95:	73 08                	jae    f0100c9f <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c97:	81 c2 25 5b 10 f0    	add    $0xf0105b25,%edx
f0100c9d:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c9f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ca2:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ca5:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100caa:	39 f2                	cmp    %esi,%edx
f0100cac:	7d 50                	jge    f0100cfe <debuginfo_eip+0x223>
		for (lline = lfun + 1;
f0100cae:	83 c2 01             	add    $0x1,%edx
f0100cb1:	89 d0                	mov    %edx,%eax
f0100cb3:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100cb6:	8d 14 95 b0 20 10 f0 	lea    -0xfefdf50(,%edx,4),%edx
f0100cbd:	eb 04                	jmp    f0100cc3 <debuginfo_eip+0x1e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100cbf:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cc3:	39 c6                	cmp    %eax,%esi
f0100cc5:	7e 32                	jle    f0100cf9 <debuginfo_eip+0x21e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cc7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100ccb:	83 c0 01             	add    $0x1,%eax
f0100cce:	83 c2 0c             	add    $0xc,%edx
f0100cd1:	80 f9 a0             	cmp    $0xa0,%cl
f0100cd4:	74 e9                	je     f0100cbf <debuginfo_eip+0x1e4>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cd6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cdb:	eb 21                	jmp    f0100cfe <debuginfo_eip+0x223>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ce2:	eb 1a                	jmp    f0100cfe <debuginfo_eip+0x223>
f0100ce4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ce9:	eb 13                	jmp    f0100cfe <debuginfo_eip+0x223>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ceb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cf0:	eb 0c                	jmp    f0100cfe <debuginfo_eip+0x223>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline > rline) {
    		return -1;
f0100cf2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cf7:	eb 05                	jmp    f0100cfe <debuginfo_eip+0x223>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cf9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cfe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d01:	5b                   	pop    %ebx
f0100d02:	5e                   	pop    %esi
f0100d03:	5f                   	pop    %edi
f0100d04:	5d                   	pop    %ebp
f0100d05:	c3                   	ret    

f0100d06 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d06:	55                   	push   %ebp
f0100d07:	89 e5                	mov    %esp,%ebp
f0100d09:	57                   	push   %edi
f0100d0a:	56                   	push   %esi
f0100d0b:	53                   	push   %ebx
f0100d0c:	83 ec 1c             	sub    $0x1c,%esp
f0100d0f:	89 c7                	mov    %eax,%edi
f0100d11:	89 d6                	mov    %edx,%esi
f0100d13:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d16:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d19:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d1c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d1f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100d22:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d27:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100d2a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100d2d:	39 d3                	cmp    %edx,%ebx
f0100d2f:	72 05                	jb     f0100d36 <printnum+0x30>
f0100d31:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100d34:	77 45                	ja     f0100d7b <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d36:	83 ec 0c             	sub    $0xc,%esp
f0100d39:	ff 75 18             	pushl  0x18(%ebp)
f0100d3c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d3f:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100d42:	53                   	push   %ebx
f0100d43:	ff 75 10             	pushl  0x10(%ebp)
f0100d46:	83 ec 08             	sub    $0x8,%esp
f0100d49:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d4c:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d4f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d52:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d55:	e8 46 09 00 00       	call   f01016a0 <__udivdi3>
f0100d5a:	83 c4 18             	add    $0x18,%esp
f0100d5d:	52                   	push   %edx
f0100d5e:	50                   	push   %eax
f0100d5f:	89 f2                	mov    %esi,%edx
f0100d61:	89 f8                	mov    %edi,%eax
f0100d63:	e8 9e ff ff ff       	call   f0100d06 <printnum>
f0100d68:	83 c4 20             	add    $0x20,%esp
f0100d6b:	eb 18                	jmp    f0100d85 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d6d:	83 ec 08             	sub    $0x8,%esp
f0100d70:	56                   	push   %esi
f0100d71:	ff 75 18             	pushl  0x18(%ebp)
f0100d74:	ff d7                	call   *%edi
f0100d76:	83 c4 10             	add    $0x10,%esp
f0100d79:	eb 03                	jmp    f0100d7e <printnum+0x78>
f0100d7b:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d7e:	83 eb 01             	sub    $0x1,%ebx
f0100d81:	85 db                	test   %ebx,%ebx
f0100d83:	7f e8                	jg     f0100d6d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d85:	83 ec 08             	sub    $0x8,%esp
f0100d88:	56                   	push   %esi
f0100d89:	83 ec 04             	sub    $0x4,%esp
f0100d8c:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d8f:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d92:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d95:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d98:	e8 33 0a 00 00       	call   f01017d0 <__umoddi3>
f0100d9d:	83 c4 14             	add    $0x14,%esp
f0100da0:	0f be 80 9d 1e 10 f0 	movsbl -0xfefe163(%eax),%eax
f0100da7:	50                   	push   %eax
f0100da8:	ff d7                	call   *%edi
}
f0100daa:	83 c4 10             	add    $0x10,%esp
f0100dad:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100db0:	5b                   	pop    %ebx
f0100db1:	5e                   	pop    %esi
f0100db2:	5f                   	pop    %edi
f0100db3:	5d                   	pop    %ebp
f0100db4:	c3                   	ret    

f0100db5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100db5:	55                   	push   %ebp
f0100db6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100db8:	83 fa 01             	cmp    $0x1,%edx
f0100dbb:	7e 0e                	jle    f0100dcb <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100dbd:	8b 10                	mov    (%eax),%edx
f0100dbf:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100dc2:	89 08                	mov    %ecx,(%eax)
f0100dc4:	8b 02                	mov    (%edx),%eax
f0100dc6:	8b 52 04             	mov    0x4(%edx),%edx
f0100dc9:	eb 22                	jmp    f0100ded <getuint+0x38>
	else if (lflag)
f0100dcb:	85 d2                	test   %edx,%edx
f0100dcd:	74 10                	je     f0100ddf <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100dcf:	8b 10                	mov    (%eax),%edx
f0100dd1:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dd4:	89 08                	mov    %ecx,(%eax)
f0100dd6:	8b 02                	mov    (%edx),%eax
f0100dd8:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ddd:	eb 0e                	jmp    f0100ded <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100ddf:	8b 10                	mov    (%eax),%edx
f0100de1:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100de4:	89 08                	mov    %ecx,(%eax)
f0100de6:	8b 02                	mov    (%edx),%eax
f0100de8:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100ded:	5d                   	pop    %ebp
f0100dee:	c3                   	ret    

f0100def <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100def:	55                   	push   %ebp
f0100df0:	89 e5                	mov    %esp,%ebp
f0100df2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100df5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100df9:	8b 10                	mov    (%eax),%edx
f0100dfb:	3b 50 04             	cmp    0x4(%eax),%edx
f0100dfe:	73 0a                	jae    f0100e0a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e00:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e03:	89 08                	mov    %ecx,(%eax)
f0100e05:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e08:	88 02                	mov    %al,(%edx)
}
f0100e0a:	5d                   	pop    %ebp
f0100e0b:	c3                   	ret    

f0100e0c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e0c:	55                   	push   %ebp
f0100e0d:	89 e5                	mov    %esp,%ebp
f0100e0f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e12:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e15:	50                   	push   %eax
f0100e16:	ff 75 10             	pushl  0x10(%ebp)
f0100e19:	ff 75 0c             	pushl  0xc(%ebp)
f0100e1c:	ff 75 08             	pushl  0x8(%ebp)
f0100e1f:	e8 05 00 00 00       	call   f0100e29 <vprintfmt>
	va_end(ap);
}
f0100e24:	83 c4 10             	add    $0x10,%esp
f0100e27:	c9                   	leave  
f0100e28:	c3                   	ret    

f0100e29 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e29:	55                   	push   %ebp
f0100e2a:	89 e5                	mov    %esp,%ebp
f0100e2c:	57                   	push   %edi
f0100e2d:	56                   	push   %esi
f0100e2e:	53                   	push   %ebx
f0100e2f:	83 ec 2c             	sub    $0x2c,%esp
f0100e32:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e35:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e38:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e3b:	eb 12                	jmp    f0100e4f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e3d:	85 c0                	test   %eax,%eax
f0100e3f:	0f 84 89 03 00 00    	je     f01011ce <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100e45:	83 ec 08             	sub    $0x8,%esp
f0100e48:	53                   	push   %ebx
f0100e49:	50                   	push   %eax
f0100e4a:	ff d6                	call   *%esi
f0100e4c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e4f:	83 c7 01             	add    $0x1,%edi
f0100e52:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e56:	83 f8 25             	cmp    $0x25,%eax
f0100e59:	75 e2                	jne    f0100e3d <vprintfmt+0x14>
f0100e5b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e5f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e66:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e6d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e74:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e79:	eb 07                	jmp    f0100e82 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e7e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e82:	8d 47 01             	lea    0x1(%edi),%eax
f0100e85:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e88:	0f b6 07             	movzbl (%edi),%eax
f0100e8b:	0f b6 c8             	movzbl %al,%ecx
f0100e8e:	83 e8 23             	sub    $0x23,%eax
f0100e91:	3c 55                	cmp    $0x55,%al
f0100e93:	0f 87 1a 03 00 00    	ja     f01011b3 <vprintfmt+0x38a>
f0100e99:	0f b6 c0             	movzbl %al,%eax
f0100e9c:	ff 24 85 2c 1f 10 f0 	jmp    *-0xfefe0d4(,%eax,4)
f0100ea3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ea6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100eaa:	eb d6                	jmp    f0100e82 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eaf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eb4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100eb7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100eba:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100ebe:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100ec1:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100ec4:	83 fa 09             	cmp    $0x9,%edx
f0100ec7:	77 39                	ja     f0100f02 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100ec9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100ecc:	eb e9                	jmp    f0100eb7 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ece:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ed1:	8d 48 04             	lea    0x4(%eax),%ecx
f0100ed4:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100ed7:	8b 00                	mov    (%eax),%eax
f0100ed9:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100edc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100edf:	eb 27                	jmp    f0100f08 <vprintfmt+0xdf>
f0100ee1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ee4:	85 c0                	test   %eax,%eax
f0100ee6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100eeb:	0f 49 c8             	cmovns %eax,%ecx
f0100eee:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ef4:	eb 8c                	jmp    f0100e82 <vprintfmt+0x59>
f0100ef6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ef9:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f00:	eb 80                	jmp    f0100e82 <vprintfmt+0x59>
f0100f02:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100f05:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100f08:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f0c:	0f 89 70 ff ff ff    	jns    f0100e82 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100f12:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f15:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f18:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f1f:	e9 5e ff ff ff       	jmp    f0100e82 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f24:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f27:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f2a:	e9 53 ff ff ff       	jmp    f0100e82 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f2f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f32:	8d 50 04             	lea    0x4(%eax),%edx
f0100f35:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f38:	83 ec 08             	sub    $0x8,%esp
f0100f3b:	53                   	push   %ebx
f0100f3c:	ff 30                	pushl  (%eax)
f0100f3e:	ff d6                	call   *%esi
			break;
f0100f40:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f43:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f46:	e9 04 ff ff ff       	jmp    f0100e4f <vprintfmt+0x26>

		

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f4e:	8d 50 04             	lea    0x4(%eax),%edx
f0100f51:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f54:	8b 00                	mov    (%eax),%eax
f0100f56:	99                   	cltd   
f0100f57:	31 d0                	xor    %edx,%eax
f0100f59:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f5b:	83 f8 06             	cmp    $0x6,%eax
f0100f5e:	7f 0b                	jg     f0100f6b <vprintfmt+0x142>
f0100f60:	8b 14 85 84 20 10 f0 	mov    -0xfefdf7c(,%eax,4),%edx
f0100f67:	85 d2                	test   %edx,%edx
f0100f69:	75 18                	jne    f0100f83 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100f6b:	50                   	push   %eax
f0100f6c:	68 b5 1e 10 f0       	push   $0xf0101eb5
f0100f71:	53                   	push   %ebx
f0100f72:	56                   	push   %esi
f0100f73:	e8 94 fe ff ff       	call   f0100e0c <printfmt>
f0100f78:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f7b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f7e:	e9 cc fe ff ff       	jmp    f0100e4f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f83:	52                   	push   %edx
f0100f84:	68 be 1e 10 f0       	push   $0xf0101ebe
f0100f89:	53                   	push   %ebx
f0100f8a:	56                   	push   %esi
f0100f8b:	e8 7c fe ff ff       	call   f0100e0c <printfmt>
f0100f90:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f96:	e9 b4 fe ff ff       	jmp    f0100e4f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f9e:	8d 50 04             	lea    0x4(%eax),%edx
f0100fa1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fa4:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100fa6:	85 ff                	test   %edi,%edi
f0100fa8:	b8 ae 1e 10 f0       	mov    $0xf0101eae,%eax
f0100fad:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100fb0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fb4:	0f 8e 94 00 00 00    	jle    f010104e <vprintfmt+0x225>
f0100fba:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100fbe:	0f 84 98 00 00 00    	je     f010105c <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fc4:	83 ec 08             	sub    $0x8,%esp
f0100fc7:	ff 75 d0             	pushl  -0x30(%ebp)
f0100fca:	57                   	push   %edi
f0100fcb:	e8 5f 03 00 00       	call   f010132f <strnlen>
f0100fd0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100fd3:	29 c1                	sub    %eax,%ecx
f0100fd5:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100fd8:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100fdb:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100fdf:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fe2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100fe5:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fe7:	eb 0f                	jmp    f0100ff8 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100fe9:	83 ec 08             	sub    $0x8,%esp
f0100fec:	53                   	push   %ebx
f0100fed:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ff0:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ff2:	83 ef 01             	sub    $0x1,%edi
f0100ff5:	83 c4 10             	add    $0x10,%esp
f0100ff8:	85 ff                	test   %edi,%edi
f0100ffa:	7f ed                	jg     f0100fe9 <vprintfmt+0x1c0>
f0100ffc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fff:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101002:	85 c9                	test   %ecx,%ecx
f0101004:	b8 00 00 00 00       	mov    $0x0,%eax
f0101009:	0f 49 c1             	cmovns %ecx,%eax
f010100c:	29 c1                	sub    %eax,%ecx
f010100e:	89 75 08             	mov    %esi,0x8(%ebp)
f0101011:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101014:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101017:	89 cb                	mov    %ecx,%ebx
f0101019:	eb 4d                	jmp    f0101068 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010101b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010101f:	74 1b                	je     f010103c <vprintfmt+0x213>
f0101021:	0f be c0             	movsbl %al,%eax
f0101024:	83 e8 20             	sub    $0x20,%eax
f0101027:	83 f8 5e             	cmp    $0x5e,%eax
f010102a:	76 10                	jbe    f010103c <vprintfmt+0x213>
					putch('?', putdat);
f010102c:	83 ec 08             	sub    $0x8,%esp
f010102f:	ff 75 0c             	pushl  0xc(%ebp)
f0101032:	6a 3f                	push   $0x3f
f0101034:	ff 55 08             	call   *0x8(%ebp)
f0101037:	83 c4 10             	add    $0x10,%esp
f010103a:	eb 0d                	jmp    f0101049 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f010103c:	83 ec 08             	sub    $0x8,%esp
f010103f:	ff 75 0c             	pushl  0xc(%ebp)
f0101042:	52                   	push   %edx
f0101043:	ff 55 08             	call   *0x8(%ebp)
f0101046:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101049:	83 eb 01             	sub    $0x1,%ebx
f010104c:	eb 1a                	jmp    f0101068 <vprintfmt+0x23f>
f010104e:	89 75 08             	mov    %esi,0x8(%ebp)
f0101051:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101054:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101057:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010105a:	eb 0c                	jmp    f0101068 <vprintfmt+0x23f>
f010105c:	89 75 08             	mov    %esi,0x8(%ebp)
f010105f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101062:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101065:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101068:	83 c7 01             	add    $0x1,%edi
f010106b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010106f:	0f be d0             	movsbl %al,%edx
f0101072:	85 d2                	test   %edx,%edx
f0101074:	74 23                	je     f0101099 <vprintfmt+0x270>
f0101076:	85 f6                	test   %esi,%esi
f0101078:	78 a1                	js     f010101b <vprintfmt+0x1f2>
f010107a:	83 ee 01             	sub    $0x1,%esi
f010107d:	79 9c                	jns    f010101b <vprintfmt+0x1f2>
f010107f:	89 df                	mov    %ebx,%edi
f0101081:	8b 75 08             	mov    0x8(%ebp),%esi
f0101084:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101087:	eb 18                	jmp    f01010a1 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101089:	83 ec 08             	sub    $0x8,%esp
f010108c:	53                   	push   %ebx
f010108d:	6a 20                	push   $0x20
f010108f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101091:	83 ef 01             	sub    $0x1,%edi
f0101094:	83 c4 10             	add    $0x10,%esp
f0101097:	eb 08                	jmp    f01010a1 <vprintfmt+0x278>
f0101099:	89 df                	mov    %ebx,%edi
f010109b:	8b 75 08             	mov    0x8(%ebp),%esi
f010109e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010a1:	85 ff                	test   %edi,%edi
f01010a3:	7f e4                	jg     f0101089 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010a5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010a8:	e9 a2 fd ff ff       	jmp    f0100e4f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010ad:	83 fa 01             	cmp    $0x1,%edx
f01010b0:	7e 16                	jle    f01010c8 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01010b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b5:	8d 50 08             	lea    0x8(%eax),%edx
f01010b8:	89 55 14             	mov    %edx,0x14(%ebp)
f01010bb:	8b 50 04             	mov    0x4(%eax),%edx
f01010be:	8b 00                	mov    (%eax),%eax
f01010c0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010c3:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010c6:	eb 32                	jmp    f01010fa <vprintfmt+0x2d1>
	else if (lflag)
f01010c8:	85 d2                	test   %edx,%edx
f01010ca:	74 18                	je     f01010e4 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01010cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01010cf:	8d 50 04             	lea    0x4(%eax),%edx
f01010d2:	89 55 14             	mov    %edx,0x14(%ebp)
f01010d5:	8b 00                	mov    (%eax),%eax
f01010d7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010da:	89 c1                	mov    %eax,%ecx
f01010dc:	c1 f9 1f             	sar    $0x1f,%ecx
f01010df:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010e2:	eb 16                	jmp    f01010fa <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f01010e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e7:	8d 50 04             	lea    0x4(%eax),%edx
f01010ea:	89 55 14             	mov    %edx,0x14(%ebp)
f01010ed:	8b 00                	mov    (%eax),%eax
f01010ef:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010f2:	89 c1                	mov    %eax,%ecx
f01010f4:	c1 f9 1f             	sar    $0x1f,%ecx
f01010f7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010fa:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010fd:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101100:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101105:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101109:	79 74                	jns    f010117f <vprintfmt+0x356>
				putch('-', putdat);
f010110b:	83 ec 08             	sub    $0x8,%esp
f010110e:	53                   	push   %ebx
f010110f:	6a 2d                	push   $0x2d
f0101111:	ff d6                	call   *%esi
				num = -(long long) num;
f0101113:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101116:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101119:	f7 d8                	neg    %eax
f010111b:	83 d2 00             	adc    $0x0,%edx
f010111e:	f7 da                	neg    %edx
f0101120:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101123:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101128:	eb 55                	jmp    f010117f <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010112a:	8d 45 14             	lea    0x14(%ebp),%eax
f010112d:	e8 83 fc ff ff       	call   f0100db5 <getuint>
			base = 10;
f0101132:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101137:	eb 46                	jmp    f010117f <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap,lflag);
f0101139:	8d 45 14             	lea    0x14(%ebp),%eax
f010113c:	e8 74 fc ff ff       	call   f0100db5 <getuint>
			base =8;
f0101141:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101146:	eb 37                	jmp    f010117f <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0101148:	83 ec 08             	sub    $0x8,%esp
f010114b:	53                   	push   %ebx
f010114c:	6a 30                	push   $0x30
f010114e:	ff d6                	call   *%esi
			putch('x', putdat);
f0101150:	83 c4 08             	add    $0x8,%esp
f0101153:	53                   	push   %ebx
f0101154:	6a 78                	push   $0x78
f0101156:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101158:	8b 45 14             	mov    0x14(%ebp),%eax
f010115b:	8d 50 04             	lea    0x4(%eax),%edx
f010115e:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101161:	8b 00                	mov    (%eax),%eax
f0101163:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101168:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010116b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101170:	eb 0d                	jmp    f010117f <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101172:	8d 45 14             	lea    0x14(%ebp),%eax
f0101175:	e8 3b fc ff ff       	call   f0100db5 <getuint>
			base = 16;
f010117a:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010117f:	83 ec 0c             	sub    $0xc,%esp
f0101182:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101186:	57                   	push   %edi
f0101187:	ff 75 e0             	pushl  -0x20(%ebp)
f010118a:	51                   	push   %ecx
f010118b:	52                   	push   %edx
f010118c:	50                   	push   %eax
f010118d:	89 da                	mov    %ebx,%edx
f010118f:	89 f0                	mov    %esi,%eax
f0101191:	e8 70 fb ff ff       	call   f0100d06 <printnum>
			break;
f0101196:	83 c4 20             	add    $0x20,%esp
f0101199:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010119c:	e9 ae fc ff ff       	jmp    f0100e4f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011a1:	83 ec 08             	sub    $0x8,%esp
f01011a4:	53                   	push   %ebx
f01011a5:	51                   	push   %ecx
f01011a6:	ff d6                	call   *%esi
			break;
f01011a8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011ae:	e9 9c fc ff ff       	jmp    f0100e4f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011b3:	83 ec 08             	sub    $0x8,%esp
f01011b6:	53                   	push   %ebx
f01011b7:	6a 25                	push   $0x25
f01011b9:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011bb:	83 c4 10             	add    $0x10,%esp
f01011be:	eb 03                	jmp    f01011c3 <vprintfmt+0x39a>
f01011c0:	83 ef 01             	sub    $0x1,%edi
f01011c3:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011c7:	75 f7                	jne    f01011c0 <vprintfmt+0x397>
f01011c9:	e9 81 fc ff ff       	jmp    f0100e4f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01011ce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011d1:	5b                   	pop    %ebx
f01011d2:	5e                   	pop    %esi
f01011d3:	5f                   	pop    %edi
f01011d4:	5d                   	pop    %ebp
f01011d5:	c3                   	ret    

f01011d6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011d6:	55                   	push   %ebp
f01011d7:	89 e5                	mov    %esp,%ebp
f01011d9:	83 ec 18             	sub    $0x18,%esp
f01011dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01011df:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011e5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011e9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011ec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011f3:	85 c0                	test   %eax,%eax
f01011f5:	74 26                	je     f010121d <vsnprintf+0x47>
f01011f7:	85 d2                	test   %edx,%edx
f01011f9:	7e 22                	jle    f010121d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011fb:	ff 75 14             	pushl  0x14(%ebp)
f01011fe:	ff 75 10             	pushl  0x10(%ebp)
f0101201:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101204:	50                   	push   %eax
f0101205:	68 ef 0d 10 f0       	push   $0xf0100def
f010120a:	e8 1a fc ff ff       	call   f0100e29 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010120f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101212:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101215:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101218:	83 c4 10             	add    $0x10,%esp
f010121b:	eb 05                	jmp    f0101222 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010121d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101222:	c9                   	leave  
f0101223:	c3                   	ret    

f0101224 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101224:	55                   	push   %ebp
f0101225:	89 e5                	mov    %esp,%ebp
f0101227:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010122a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010122d:	50                   	push   %eax
f010122e:	ff 75 10             	pushl  0x10(%ebp)
f0101231:	ff 75 0c             	pushl  0xc(%ebp)
f0101234:	ff 75 08             	pushl  0x8(%ebp)
f0101237:	e8 9a ff ff ff       	call   f01011d6 <vsnprintf>
	va_end(ap);

	return rc;
}
f010123c:	c9                   	leave  
f010123d:	c3                   	ret    

f010123e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010123e:	55                   	push   %ebp
f010123f:	89 e5                	mov    %esp,%ebp
f0101241:	57                   	push   %edi
f0101242:	56                   	push   %esi
f0101243:	53                   	push   %ebx
f0101244:	83 ec 0c             	sub    $0xc,%esp
f0101247:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010124a:	85 c0                	test   %eax,%eax
f010124c:	74 11                	je     f010125f <readline+0x21>
		cprintf("%s", prompt);
f010124e:	83 ec 08             	sub    $0x8,%esp
f0101251:	50                   	push   %eax
f0101252:	68 be 1e 10 f0       	push   $0xf0101ebe
f0101257:	e8 75 f7 ff ff       	call   f01009d1 <cprintf>
f010125c:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010125f:	83 ec 0c             	sub    $0xc,%esp
f0101262:	6a 00                	push   $0x0
f0101264:	e8 46 f4 ff ff       	call   f01006af <iscons>
f0101269:	89 c7                	mov    %eax,%edi
f010126b:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010126e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101273:	e8 26 f4 ff ff       	call   f010069e <getchar>
f0101278:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010127a:	85 c0                	test   %eax,%eax
f010127c:	79 18                	jns    f0101296 <readline+0x58>
			cprintf("read error: %e\n", c);
f010127e:	83 ec 08             	sub    $0x8,%esp
f0101281:	50                   	push   %eax
f0101282:	68 a0 20 10 f0       	push   $0xf01020a0
f0101287:	e8 45 f7 ff ff       	call   f01009d1 <cprintf>
			return NULL;
f010128c:	83 c4 10             	add    $0x10,%esp
f010128f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101294:	eb 79                	jmp    f010130f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101296:	83 f8 08             	cmp    $0x8,%eax
f0101299:	0f 94 c2             	sete   %dl
f010129c:	83 f8 7f             	cmp    $0x7f,%eax
f010129f:	0f 94 c0             	sete   %al
f01012a2:	08 c2                	or     %al,%dl
f01012a4:	74 1a                	je     f01012c0 <readline+0x82>
f01012a6:	85 f6                	test   %esi,%esi
f01012a8:	7e 16                	jle    f01012c0 <readline+0x82>
			if (echoing)
f01012aa:	85 ff                	test   %edi,%edi
f01012ac:	74 0d                	je     f01012bb <readline+0x7d>
				cputchar('\b');
f01012ae:	83 ec 0c             	sub    $0xc,%esp
f01012b1:	6a 08                	push   $0x8
f01012b3:	e8 d6 f3 ff ff       	call   f010068e <cputchar>
f01012b8:	83 c4 10             	add    $0x10,%esp
			i--;
f01012bb:	83 ee 01             	sub    $0x1,%esi
f01012be:	eb b3                	jmp    f0101273 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012c0:	83 fb 1f             	cmp    $0x1f,%ebx
f01012c3:	7e 23                	jle    f01012e8 <readline+0xaa>
f01012c5:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012cb:	7f 1b                	jg     f01012e8 <readline+0xaa>
			if (echoing)
f01012cd:	85 ff                	test   %edi,%edi
f01012cf:	74 0c                	je     f01012dd <readline+0x9f>
				cputchar(c);
f01012d1:	83 ec 0c             	sub    $0xc,%esp
f01012d4:	53                   	push   %ebx
f01012d5:	e8 b4 f3 ff ff       	call   f010068e <cputchar>
f01012da:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012dd:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012e3:	8d 76 01             	lea    0x1(%esi),%esi
f01012e6:	eb 8b                	jmp    f0101273 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012e8:	83 fb 0a             	cmp    $0xa,%ebx
f01012eb:	74 05                	je     f01012f2 <readline+0xb4>
f01012ed:	83 fb 0d             	cmp    $0xd,%ebx
f01012f0:	75 81                	jne    f0101273 <readline+0x35>
			if (echoing)
f01012f2:	85 ff                	test   %edi,%edi
f01012f4:	74 0d                	je     f0101303 <readline+0xc5>
				cputchar('\n');
f01012f6:	83 ec 0c             	sub    $0xc,%esp
f01012f9:	6a 0a                	push   $0xa
f01012fb:	e8 8e f3 ff ff       	call   f010068e <cputchar>
f0101300:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101303:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010130a:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f010130f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101312:	5b                   	pop    %ebx
f0101313:	5e                   	pop    %esi
f0101314:	5f                   	pop    %edi
f0101315:	5d                   	pop    %ebp
f0101316:	c3                   	ret    

f0101317 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101317:	55                   	push   %ebp
f0101318:	89 e5                	mov    %esp,%ebp
f010131a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010131d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101322:	eb 03                	jmp    f0101327 <strlen+0x10>
		n++;
f0101324:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101327:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010132b:	75 f7                	jne    f0101324 <strlen+0xd>
		n++;
	return n;
}
f010132d:	5d                   	pop    %ebp
f010132e:	c3                   	ret    

f010132f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010132f:	55                   	push   %ebp
f0101330:	89 e5                	mov    %esp,%ebp
f0101332:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101335:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101338:	ba 00 00 00 00       	mov    $0x0,%edx
f010133d:	eb 03                	jmp    f0101342 <strnlen+0x13>
		n++;
f010133f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101342:	39 c2                	cmp    %eax,%edx
f0101344:	74 08                	je     f010134e <strnlen+0x1f>
f0101346:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010134a:	75 f3                	jne    f010133f <strnlen+0x10>
f010134c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010134e:	5d                   	pop    %ebp
f010134f:	c3                   	ret    

f0101350 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101350:	55                   	push   %ebp
f0101351:	89 e5                	mov    %esp,%ebp
f0101353:	53                   	push   %ebx
f0101354:	8b 45 08             	mov    0x8(%ebp),%eax
f0101357:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010135a:	89 c2                	mov    %eax,%edx
f010135c:	83 c2 01             	add    $0x1,%edx
f010135f:	83 c1 01             	add    $0x1,%ecx
f0101362:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101366:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101369:	84 db                	test   %bl,%bl
f010136b:	75 ef                	jne    f010135c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010136d:	5b                   	pop    %ebx
f010136e:	5d                   	pop    %ebp
f010136f:	c3                   	ret    

f0101370 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101370:	55                   	push   %ebp
f0101371:	89 e5                	mov    %esp,%ebp
f0101373:	53                   	push   %ebx
f0101374:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101377:	53                   	push   %ebx
f0101378:	e8 9a ff ff ff       	call   f0101317 <strlen>
f010137d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101380:	ff 75 0c             	pushl  0xc(%ebp)
f0101383:	01 d8                	add    %ebx,%eax
f0101385:	50                   	push   %eax
f0101386:	e8 c5 ff ff ff       	call   f0101350 <strcpy>
	return dst;
}
f010138b:	89 d8                	mov    %ebx,%eax
f010138d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101390:	c9                   	leave  
f0101391:	c3                   	ret    

f0101392 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101392:	55                   	push   %ebp
f0101393:	89 e5                	mov    %esp,%ebp
f0101395:	56                   	push   %esi
f0101396:	53                   	push   %ebx
f0101397:	8b 75 08             	mov    0x8(%ebp),%esi
f010139a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010139d:	89 f3                	mov    %esi,%ebx
f010139f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013a2:	89 f2                	mov    %esi,%edx
f01013a4:	eb 0f                	jmp    f01013b5 <strncpy+0x23>
		*dst++ = *src;
f01013a6:	83 c2 01             	add    $0x1,%edx
f01013a9:	0f b6 01             	movzbl (%ecx),%eax
f01013ac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013af:	80 39 01             	cmpb   $0x1,(%ecx)
f01013b2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013b5:	39 da                	cmp    %ebx,%edx
f01013b7:	75 ed                	jne    f01013a6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013b9:	89 f0                	mov    %esi,%eax
f01013bb:	5b                   	pop    %ebx
f01013bc:	5e                   	pop    %esi
f01013bd:	5d                   	pop    %ebp
f01013be:	c3                   	ret    

f01013bf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013bf:	55                   	push   %ebp
f01013c0:	89 e5                	mov    %esp,%ebp
f01013c2:	56                   	push   %esi
f01013c3:	53                   	push   %ebx
f01013c4:	8b 75 08             	mov    0x8(%ebp),%esi
f01013c7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013ca:	8b 55 10             	mov    0x10(%ebp),%edx
f01013cd:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013cf:	85 d2                	test   %edx,%edx
f01013d1:	74 21                	je     f01013f4 <strlcpy+0x35>
f01013d3:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013d7:	89 f2                	mov    %esi,%edx
f01013d9:	eb 09                	jmp    f01013e4 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013db:	83 c2 01             	add    $0x1,%edx
f01013de:	83 c1 01             	add    $0x1,%ecx
f01013e1:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013e4:	39 c2                	cmp    %eax,%edx
f01013e6:	74 09                	je     f01013f1 <strlcpy+0x32>
f01013e8:	0f b6 19             	movzbl (%ecx),%ebx
f01013eb:	84 db                	test   %bl,%bl
f01013ed:	75 ec                	jne    f01013db <strlcpy+0x1c>
f01013ef:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013f1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013f4:	29 f0                	sub    %esi,%eax
}
f01013f6:	5b                   	pop    %ebx
f01013f7:	5e                   	pop    %esi
f01013f8:	5d                   	pop    %ebp
f01013f9:	c3                   	ret    

f01013fa <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013fa:	55                   	push   %ebp
f01013fb:	89 e5                	mov    %esp,%ebp
f01013fd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101400:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101403:	eb 06                	jmp    f010140b <strcmp+0x11>
		p++, q++;
f0101405:	83 c1 01             	add    $0x1,%ecx
f0101408:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010140b:	0f b6 01             	movzbl (%ecx),%eax
f010140e:	84 c0                	test   %al,%al
f0101410:	74 04                	je     f0101416 <strcmp+0x1c>
f0101412:	3a 02                	cmp    (%edx),%al
f0101414:	74 ef                	je     f0101405 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101416:	0f b6 c0             	movzbl %al,%eax
f0101419:	0f b6 12             	movzbl (%edx),%edx
f010141c:	29 d0                	sub    %edx,%eax
}
f010141e:	5d                   	pop    %ebp
f010141f:	c3                   	ret    

f0101420 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101420:	55                   	push   %ebp
f0101421:	89 e5                	mov    %esp,%ebp
f0101423:	53                   	push   %ebx
f0101424:	8b 45 08             	mov    0x8(%ebp),%eax
f0101427:	8b 55 0c             	mov    0xc(%ebp),%edx
f010142a:	89 c3                	mov    %eax,%ebx
f010142c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010142f:	eb 06                	jmp    f0101437 <strncmp+0x17>
		n--, p++, q++;
f0101431:	83 c0 01             	add    $0x1,%eax
f0101434:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101437:	39 d8                	cmp    %ebx,%eax
f0101439:	74 15                	je     f0101450 <strncmp+0x30>
f010143b:	0f b6 08             	movzbl (%eax),%ecx
f010143e:	84 c9                	test   %cl,%cl
f0101440:	74 04                	je     f0101446 <strncmp+0x26>
f0101442:	3a 0a                	cmp    (%edx),%cl
f0101444:	74 eb                	je     f0101431 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101446:	0f b6 00             	movzbl (%eax),%eax
f0101449:	0f b6 12             	movzbl (%edx),%edx
f010144c:	29 d0                	sub    %edx,%eax
f010144e:	eb 05                	jmp    f0101455 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101450:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101455:	5b                   	pop    %ebx
f0101456:	5d                   	pop    %ebp
f0101457:	c3                   	ret    

f0101458 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101458:	55                   	push   %ebp
f0101459:	89 e5                	mov    %esp,%ebp
f010145b:	8b 45 08             	mov    0x8(%ebp),%eax
f010145e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101462:	eb 07                	jmp    f010146b <strchr+0x13>
		if (*s == c)
f0101464:	38 ca                	cmp    %cl,%dl
f0101466:	74 0f                	je     f0101477 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101468:	83 c0 01             	add    $0x1,%eax
f010146b:	0f b6 10             	movzbl (%eax),%edx
f010146e:	84 d2                	test   %dl,%dl
f0101470:	75 f2                	jne    f0101464 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101472:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101477:	5d                   	pop    %ebp
f0101478:	c3                   	ret    

f0101479 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101479:	55                   	push   %ebp
f010147a:	89 e5                	mov    %esp,%ebp
f010147c:	8b 45 08             	mov    0x8(%ebp),%eax
f010147f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101483:	eb 03                	jmp    f0101488 <strfind+0xf>
f0101485:	83 c0 01             	add    $0x1,%eax
f0101488:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010148b:	38 ca                	cmp    %cl,%dl
f010148d:	74 04                	je     f0101493 <strfind+0x1a>
f010148f:	84 d2                	test   %dl,%dl
f0101491:	75 f2                	jne    f0101485 <strfind+0xc>
			break;
	return (char *) s;
}
f0101493:	5d                   	pop    %ebp
f0101494:	c3                   	ret    

f0101495 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101495:	55                   	push   %ebp
f0101496:	89 e5                	mov    %esp,%ebp
f0101498:	57                   	push   %edi
f0101499:	56                   	push   %esi
f010149a:	53                   	push   %ebx
f010149b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010149e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014a1:	85 c9                	test   %ecx,%ecx
f01014a3:	74 36                	je     f01014db <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014a5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014ab:	75 28                	jne    f01014d5 <memset+0x40>
f01014ad:	f6 c1 03             	test   $0x3,%cl
f01014b0:	75 23                	jne    f01014d5 <memset+0x40>
		c &= 0xFF;
f01014b2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014b6:	89 d3                	mov    %edx,%ebx
f01014b8:	c1 e3 08             	shl    $0x8,%ebx
f01014bb:	89 d6                	mov    %edx,%esi
f01014bd:	c1 e6 18             	shl    $0x18,%esi
f01014c0:	89 d0                	mov    %edx,%eax
f01014c2:	c1 e0 10             	shl    $0x10,%eax
f01014c5:	09 f0                	or     %esi,%eax
f01014c7:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01014c9:	89 d8                	mov    %ebx,%eax
f01014cb:	09 d0                	or     %edx,%eax
f01014cd:	c1 e9 02             	shr    $0x2,%ecx
f01014d0:	fc                   	cld    
f01014d1:	f3 ab                	rep stos %eax,%es:(%edi)
f01014d3:	eb 06                	jmp    f01014db <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014d8:	fc                   	cld    
f01014d9:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014db:	89 f8                	mov    %edi,%eax
f01014dd:	5b                   	pop    %ebx
f01014de:	5e                   	pop    %esi
f01014df:	5f                   	pop    %edi
f01014e0:	5d                   	pop    %ebp
f01014e1:	c3                   	ret    

f01014e2 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014e2:	55                   	push   %ebp
f01014e3:	89 e5                	mov    %esp,%ebp
f01014e5:	57                   	push   %edi
f01014e6:	56                   	push   %esi
f01014e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ea:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014ed:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014f0:	39 c6                	cmp    %eax,%esi
f01014f2:	73 35                	jae    f0101529 <memmove+0x47>
f01014f4:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014f7:	39 d0                	cmp    %edx,%eax
f01014f9:	73 2e                	jae    f0101529 <memmove+0x47>
		s += n;
		d += n;
f01014fb:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014fe:	89 d6                	mov    %edx,%esi
f0101500:	09 fe                	or     %edi,%esi
f0101502:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101508:	75 13                	jne    f010151d <memmove+0x3b>
f010150a:	f6 c1 03             	test   $0x3,%cl
f010150d:	75 0e                	jne    f010151d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010150f:	83 ef 04             	sub    $0x4,%edi
f0101512:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101515:	c1 e9 02             	shr    $0x2,%ecx
f0101518:	fd                   	std    
f0101519:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010151b:	eb 09                	jmp    f0101526 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010151d:	83 ef 01             	sub    $0x1,%edi
f0101520:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101523:	fd                   	std    
f0101524:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101526:	fc                   	cld    
f0101527:	eb 1d                	jmp    f0101546 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101529:	89 f2                	mov    %esi,%edx
f010152b:	09 c2                	or     %eax,%edx
f010152d:	f6 c2 03             	test   $0x3,%dl
f0101530:	75 0f                	jne    f0101541 <memmove+0x5f>
f0101532:	f6 c1 03             	test   $0x3,%cl
f0101535:	75 0a                	jne    f0101541 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0101537:	c1 e9 02             	shr    $0x2,%ecx
f010153a:	89 c7                	mov    %eax,%edi
f010153c:	fc                   	cld    
f010153d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010153f:	eb 05                	jmp    f0101546 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101541:	89 c7                	mov    %eax,%edi
f0101543:	fc                   	cld    
f0101544:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101546:	5e                   	pop    %esi
f0101547:	5f                   	pop    %edi
f0101548:	5d                   	pop    %ebp
f0101549:	c3                   	ret    

f010154a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010154a:	55                   	push   %ebp
f010154b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010154d:	ff 75 10             	pushl  0x10(%ebp)
f0101550:	ff 75 0c             	pushl  0xc(%ebp)
f0101553:	ff 75 08             	pushl  0x8(%ebp)
f0101556:	e8 87 ff ff ff       	call   f01014e2 <memmove>
}
f010155b:	c9                   	leave  
f010155c:	c3                   	ret    

f010155d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010155d:	55                   	push   %ebp
f010155e:	89 e5                	mov    %esp,%ebp
f0101560:	56                   	push   %esi
f0101561:	53                   	push   %ebx
f0101562:	8b 45 08             	mov    0x8(%ebp),%eax
f0101565:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101568:	89 c6                	mov    %eax,%esi
f010156a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010156d:	eb 1a                	jmp    f0101589 <memcmp+0x2c>
		if (*s1 != *s2)
f010156f:	0f b6 08             	movzbl (%eax),%ecx
f0101572:	0f b6 1a             	movzbl (%edx),%ebx
f0101575:	38 d9                	cmp    %bl,%cl
f0101577:	74 0a                	je     f0101583 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101579:	0f b6 c1             	movzbl %cl,%eax
f010157c:	0f b6 db             	movzbl %bl,%ebx
f010157f:	29 d8                	sub    %ebx,%eax
f0101581:	eb 0f                	jmp    f0101592 <memcmp+0x35>
		s1++, s2++;
f0101583:	83 c0 01             	add    $0x1,%eax
f0101586:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101589:	39 f0                	cmp    %esi,%eax
f010158b:	75 e2                	jne    f010156f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010158d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101592:	5b                   	pop    %ebx
f0101593:	5e                   	pop    %esi
f0101594:	5d                   	pop    %ebp
f0101595:	c3                   	ret    

f0101596 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101596:	55                   	push   %ebp
f0101597:	89 e5                	mov    %esp,%ebp
f0101599:	53                   	push   %ebx
f010159a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010159d:	89 c1                	mov    %eax,%ecx
f010159f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01015a2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015a6:	eb 0a                	jmp    f01015b2 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015a8:	0f b6 10             	movzbl (%eax),%edx
f01015ab:	39 da                	cmp    %ebx,%edx
f01015ad:	74 07                	je     f01015b6 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015af:	83 c0 01             	add    $0x1,%eax
f01015b2:	39 c8                	cmp    %ecx,%eax
f01015b4:	72 f2                	jb     f01015a8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015b6:	5b                   	pop    %ebx
f01015b7:	5d                   	pop    %ebp
f01015b8:	c3                   	ret    

f01015b9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015b9:	55                   	push   %ebp
f01015ba:	89 e5                	mov    %esp,%ebp
f01015bc:	57                   	push   %edi
f01015bd:	56                   	push   %esi
f01015be:	53                   	push   %ebx
f01015bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015c2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015c5:	eb 03                	jmp    f01015ca <strtol+0x11>
		s++;
f01015c7:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015ca:	0f b6 01             	movzbl (%ecx),%eax
f01015cd:	3c 20                	cmp    $0x20,%al
f01015cf:	74 f6                	je     f01015c7 <strtol+0xe>
f01015d1:	3c 09                	cmp    $0x9,%al
f01015d3:	74 f2                	je     f01015c7 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015d5:	3c 2b                	cmp    $0x2b,%al
f01015d7:	75 0a                	jne    f01015e3 <strtol+0x2a>
		s++;
f01015d9:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015dc:	bf 00 00 00 00       	mov    $0x0,%edi
f01015e1:	eb 11                	jmp    f01015f4 <strtol+0x3b>
f01015e3:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015e8:	3c 2d                	cmp    $0x2d,%al
f01015ea:	75 08                	jne    f01015f4 <strtol+0x3b>
		s++, neg = 1;
f01015ec:	83 c1 01             	add    $0x1,%ecx
f01015ef:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015f4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015fa:	75 15                	jne    f0101611 <strtol+0x58>
f01015fc:	80 39 30             	cmpb   $0x30,(%ecx)
f01015ff:	75 10                	jne    f0101611 <strtol+0x58>
f0101601:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101605:	75 7c                	jne    f0101683 <strtol+0xca>
		s += 2, base = 16;
f0101607:	83 c1 02             	add    $0x2,%ecx
f010160a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010160f:	eb 16                	jmp    f0101627 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101611:	85 db                	test   %ebx,%ebx
f0101613:	75 12                	jne    f0101627 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101615:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010161a:	80 39 30             	cmpb   $0x30,(%ecx)
f010161d:	75 08                	jne    f0101627 <strtol+0x6e>
		s++, base = 8;
f010161f:	83 c1 01             	add    $0x1,%ecx
f0101622:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101627:	b8 00 00 00 00       	mov    $0x0,%eax
f010162c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010162f:	0f b6 11             	movzbl (%ecx),%edx
f0101632:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101635:	89 f3                	mov    %esi,%ebx
f0101637:	80 fb 09             	cmp    $0x9,%bl
f010163a:	77 08                	ja     f0101644 <strtol+0x8b>
			dig = *s - '0';
f010163c:	0f be d2             	movsbl %dl,%edx
f010163f:	83 ea 30             	sub    $0x30,%edx
f0101642:	eb 22                	jmp    f0101666 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101644:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101647:	89 f3                	mov    %esi,%ebx
f0101649:	80 fb 19             	cmp    $0x19,%bl
f010164c:	77 08                	ja     f0101656 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010164e:	0f be d2             	movsbl %dl,%edx
f0101651:	83 ea 57             	sub    $0x57,%edx
f0101654:	eb 10                	jmp    f0101666 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101656:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101659:	89 f3                	mov    %esi,%ebx
f010165b:	80 fb 19             	cmp    $0x19,%bl
f010165e:	77 16                	ja     f0101676 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101660:	0f be d2             	movsbl %dl,%edx
f0101663:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101666:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101669:	7d 0b                	jge    f0101676 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010166b:	83 c1 01             	add    $0x1,%ecx
f010166e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101672:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101674:	eb b9                	jmp    f010162f <strtol+0x76>

	if (endptr)
f0101676:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010167a:	74 0d                	je     f0101689 <strtol+0xd0>
		*endptr = (char *) s;
f010167c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010167f:	89 0e                	mov    %ecx,(%esi)
f0101681:	eb 06                	jmp    f0101689 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101683:	85 db                	test   %ebx,%ebx
f0101685:	74 98                	je     f010161f <strtol+0x66>
f0101687:	eb 9e                	jmp    f0101627 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101689:	89 c2                	mov    %eax,%edx
f010168b:	f7 da                	neg    %edx
f010168d:	85 ff                	test   %edi,%edi
f010168f:	0f 45 c2             	cmovne %edx,%eax
}
f0101692:	5b                   	pop    %ebx
f0101693:	5e                   	pop    %esi
f0101694:	5f                   	pop    %edi
f0101695:	5d                   	pop    %ebp
f0101696:	c3                   	ret    
f0101697:	66 90                	xchg   %ax,%ax
f0101699:	66 90                	xchg   %ax,%ax
f010169b:	66 90                	xchg   %ax,%ax
f010169d:	66 90                	xchg   %ax,%ax
f010169f:	90                   	nop

f01016a0 <__udivdi3>:
f01016a0:	55                   	push   %ebp
f01016a1:	57                   	push   %edi
f01016a2:	56                   	push   %esi
f01016a3:	53                   	push   %ebx
f01016a4:	83 ec 1c             	sub    $0x1c,%esp
f01016a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01016ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01016af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01016b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01016b7:	85 f6                	test   %esi,%esi
f01016b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01016bd:	89 ca                	mov    %ecx,%edx
f01016bf:	89 f8                	mov    %edi,%eax
f01016c1:	75 3d                	jne    f0101700 <__udivdi3+0x60>
f01016c3:	39 cf                	cmp    %ecx,%edi
f01016c5:	0f 87 c5 00 00 00    	ja     f0101790 <__udivdi3+0xf0>
f01016cb:	85 ff                	test   %edi,%edi
f01016cd:	89 fd                	mov    %edi,%ebp
f01016cf:	75 0b                	jne    f01016dc <__udivdi3+0x3c>
f01016d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016d6:	31 d2                	xor    %edx,%edx
f01016d8:	f7 f7                	div    %edi
f01016da:	89 c5                	mov    %eax,%ebp
f01016dc:	89 c8                	mov    %ecx,%eax
f01016de:	31 d2                	xor    %edx,%edx
f01016e0:	f7 f5                	div    %ebp
f01016e2:	89 c1                	mov    %eax,%ecx
f01016e4:	89 d8                	mov    %ebx,%eax
f01016e6:	89 cf                	mov    %ecx,%edi
f01016e8:	f7 f5                	div    %ebp
f01016ea:	89 c3                	mov    %eax,%ebx
f01016ec:	89 d8                	mov    %ebx,%eax
f01016ee:	89 fa                	mov    %edi,%edx
f01016f0:	83 c4 1c             	add    $0x1c,%esp
f01016f3:	5b                   	pop    %ebx
f01016f4:	5e                   	pop    %esi
f01016f5:	5f                   	pop    %edi
f01016f6:	5d                   	pop    %ebp
f01016f7:	c3                   	ret    
f01016f8:	90                   	nop
f01016f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101700:	39 ce                	cmp    %ecx,%esi
f0101702:	77 74                	ja     f0101778 <__udivdi3+0xd8>
f0101704:	0f bd fe             	bsr    %esi,%edi
f0101707:	83 f7 1f             	xor    $0x1f,%edi
f010170a:	0f 84 98 00 00 00    	je     f01017a8 <__udivdi3+0x108>
f0101710:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101715:	89 f9                	mov    %edi,%ecx
f0101717:	89 c5                	mov    %eax,%ebp
f0101719:	29 fb                	sub    %edi,%ebx
f010171b:	d3 e6                	shl    %cl,%esi
f010171d:	89 d9                	mov    %ebx,%ecx
f010171f:	d3 ed                	shr    %cl,%ebp
f0101721:	89 f9                	mov    %edi,%ecx
f0101723:	d3 e0                	shl    %cl,%eax
f0101725:	09 ee                	or     %ebp,%esi
f0101727:	89 d9                	mov    %ebx,%ecx
f0101729:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010172d:	89 d5                	mov    %edx,%ebp
f010172f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101733:	d3 ed                	shr    %cl,%ebp
f0101735:	89 f9                	mov    %edi,%ecx
f0101737:	d3 e2                	shl    %cl,%edx
f0101739:	89 d9                	mov    %ebx,%ecx
f010173b:	d3 e8                	shr    %cl,%eax
f010173d:	09 c2                	or     %eax,%edx
f010173f:	89 d0                	mov    %edx,%eax
f0101741:	89 ea                	mov    %ebp,%edx
f0101743:	f7 f6                	div    %esi
f0101745:	89 d5                	mov    %edx,%ebp
f0101747:	89 c3                	mov    %eax,%ebx
f0101749:	f7 64 24 0c          	mull   0xc(%esp)
f010174d:	39 d5                	cmp    %edx,%ebp
f010174f:	72 10                	jb     f0101761 <__udivdi3+0xc1>
f0101751:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101755:	89 f9                	mov    %edi,%ecx
f0101757:	d3 e6                	shl    %cl,%esi
f0101759:	39 c6                	cmp    %eax,%esi
f010175b:	73 07                	jae    f0101764 <__udivdi3+0xc4>
f010175d:	39 d5                	cmp    %edx,%ebp
f010175f:	75 03                	jne    f0101764 <__udivdi3+0xc4>
f0101761:	83 eb 01             	sub    $0x1,%ebx
f0101764:	31 ff                	xor    %edi,%edi
f0101766:	89 d8                	mov    %ebx,%eax
f0101768:	89 fa                	mov    %edi,%edx
f010176a:	83 c4 1c             	add    $0x1c,%esp
f010176d:	5b                   	pop    %ebx
f010176e:	5e                   	pop    %esi
f010176f:	5f                   	pop    %edi
f0101770:	5d                   	pop    %ebp
f0101771:	c3                   	ret    
f0101772:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101778:	31 ff                	xor    %edi,%edi
f010177a:	31 db                	xor    %ebx,%ebx
f010177c:	89 d8                	mov    %ebx,%eax
f010177e:	89 fa                	mov    %edi,%edx
f0101780:	83 c4 1c             	add    $0x1c,%esp
f0101783:	5b                   	pop    %ebx
f0101784:	5e                   	pop    %esi
f0101785:	5f                   	pop    %edi
f0101786:	5d                   	pop    %ebp
f0101787:	c3                   	ret    
f0101788:	90                   	nop
f0101789:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101790:	89 d8                	mov    %ebx,%eax
f0101792:	f7 f7                	div    %edi
f0101794:	31 ff                	xor    %edi,%edi
f0101796:	89 c3                	mov    %eax,%ebx
f0101798:	89 d8                	mov    %ebx,%eax
f010179a:	89 fa                	mov    %edi,%edx
f010179c:	83 c4 1c             	add    $0x1c,%esp
f010179f:	5b                   	pop    %ebx
f01017a0:	5e                   	pop    %esi
f01017a1:	5f                   	pop    %edi
f01017a2:	5d                   	pop    %ebp
f01017a3:	c3                   	ret    
f01017a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017a8:	39 ce                	cmp    %ecx,%esi
f01017aa:	72 0c                	jb     f01017b8 <__udivdi3+0x118>
f01017ac:	31 db                	xor    %ebx,%ebx
f01017ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01017b2:	0f 87 34 ff ff ff    	ja     f01016ec <__udivdi3+0x4c>
f01017b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01017bd:	e9 2a ff ff ff       	jmp    f01016ec <__udivdi3+0x4c>
f01017c2:	66 90                	xchg   %ax,%ax
f01017c4:	66 90                	xchg   %ax,%ax
f01017c6:	66 90                	xchg   %ax,%ax
f01017c8:	66 90                	xchg   %ax,%ax
f01017ca:	66 90                	xchg   %ax,%ax
f01017cc:	66 90                	xchg   %ax,%ax
f01017ce:	66 90                	xchg   %ax,%ax

f01017d0 <__umoddi3>:
f01017d0:	55                   	push   %ebp
f01017d1:	57                   	push   %edi
f01017d2:	56                   	push   %esi
f01017d3:	53                   	push   %ebx
f01017d4:	83 ec 1c             	sub    $0x1c,%esp
f01017d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017e7:	85 d2                	test   %edx,%edx
f01017e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01017ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017f1:	89 f3                	mov    %esi,%ebx
f01017f3:	89 3c 24             	mov    %edi,(%esp)
f01017f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017fa:	75 1c                	jne    f0101818 <__umoddi3+0x48>
f01017fc:	39 f7                	cmp    %esi,%edi
f01017fe:	76 50                	jbe    f0101850 <__umoddi3+0x80>
f0101800:	89 c8                	mov    %ecx,%eax
f0101802:	89 f2                	mov    %esi,%edx
f0101804:	f7 f7                	div    %edi
f0101806:	89 d0                	mov    %edx,%eax
f0101808:	31 d2                	xor    %edx,%edx
f010180a:	83 c4 1c             	add    $0x1c,%esp
f010180d:	5b                   	pop    %ebx
f010180e:	5e                   	pop    %esi
f010180f:	5f                   	pop    %edi
f0101810:	5d                   	pop    %ebp
f0101811:	c3                   	ret    
f0101812:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101818:	39 f2                	cmp    %esi,%edx
f010181a:	89 d0                	mov    %edx,%eax
f010181c:	77 52                	ja     f0101870 <__umoddi3+0xa0>
f010181e:	0f bd ea             	bsr    %edx,%ebp
f0101821:	83 f5 1f             	xor    $0x1f,%ebp
f0101824:	75 5a                	jne    f0101880 <__umoddi3+0xb0>
f0101826:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010182a:	0f 82 e0 00 00 00    	jb     f0101910 <__umoddi3+0x140>
f0101830:	39 0c 24             	cmp    %ecx,(%esp)
f0101833:	0f 86 d7 00 00 00    	jbe    f0101910 <__umoddi3+0x140>
f0101839:	8b 44 24 08          	mov    0x8(%esp),%eax
f010183d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101841:	83 c4 1c             	add    $0x1c,%esp
f0101844:	5b                   	pop    %ebx
f0101845:	5e                   	pop    %esi
f0101846:	5f                   	pop    %edi
f0101847:	5d                   	pop    %ebp
f0101848:	c3                   	ret    
f0101849:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101850:	85 ff                	test   %edi,%edi
f0101852:	89 fd                	mov    %edi,%ebp
f0101854:	75 0b                	jne    f0101861 <__umoddi3+0x91>
f0101856:	b8 01 00 00 00       	mov    $0x1,%eax
f010185b:	31 d2                	xor    %edx,%edx
f010185d:	f7 f7                	div    %edi
f010185f:	89 c5                	mov    %eax,%ebp
f0101861:	89 f0                	mov    %esi,%eax
f0101863:	31 d2                	xor    %edx,%edx
f0101865:	f7 f5                	div    %ebp
f0101867:	89 c8                	mov    %ecx,%eax
f0101869:	f7 f5                	div    %ebp
f010186b:	89 d0                	mov    %edx,%eax
f010186d:	eb 99                	jmp    f0101808 <__umoddi3+0x38>
f010186f:	90                   	nop
f0101870:	89 c8                	mov    %ecx,%eax
f0101872:	89 f2                	mov    %esi,%edx
f0101874:	83 c4 1c             	add    $0x1c,%esp
f0101877:	5b                   	pop    %ebx
f0101878:	5e                   	pop    %esi
f0101879:	5f                   	pop    %edi
f010187a:	5d                   	pop    %ebp
f010187b:	c3                   	ret    
f010187c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101880:	8b 34 24             	mov    (%esp),%esi
f0101883:	bf 20 00 00 00       	mov    $0x20,%edi
f0101888:	89 e9                	mov    %ebp,%ecx
f010188a:	29 ef                	sub    %ebp,%edi
f010188c:	d3 e0                	shl    %cl,%eax
f010188e:	89 f9                	mov    %edi,%ecx
f0101890:	89 f2                	mov    %esi,%edx
f0101892:	d3 ea                	shr    %cl,%edx
f0101894:	89 e9                	mov    %ebp,%ecx
f0101896:	09 c2                	or     %eax,%edx
f0101898:	89 d8                	mov    %ebx,%eax
f010189a:	89 14 24             	mov    %edx,(%esp)
f010189d:	89 f2                	mov    %esi,%edx
f010189f:	d3 e2                	shl    %cl,%edx
f01018a1:	89 f9                	mov    %edi,%ecx
f01018a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01018a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018ab:	d3 e8                	shr    %cl,%eax
f01018ad:	89 e9                	mov    %ebp,%ecx
f01018af:	89 c6                	mov    %eax,%esi
f01018b1:	d3 e3                	shl    %cl,%ebx
f01018b3:	89 f9                	mov    %edi,%ecx
f01018b5:	89 d0                	mov    %edx,%eax
f01018b7:	d3 e8                	shr    %cl,%eax
f01018b9:	89 e9                	mov    %ebp,%ecx
f01018bb:	09 d8                	or     %ebx,%eax
f01018bd:	89 d3                	mov    %edx,%ebx
f01018bf:	89 f2                	mov    %esi,%edx
f01018c1:	f7 34 24             	divl   (%esp)
f01018c4:	89 d6                	mov    %edx,%esi
f01018c6:	d3 e3                	shl    %cl,%ebx
f01018c8:	f7 64 24 04          	mull   0x4(%esp)
f01018cc:	39 d6                	cmp    %edx,%esi
f01018ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018d2:	89 d1                	mov    %edx,%ecx
f01018d4:	89 c3                	mov    %eax,%ebx
f01018d6:	72 08                	jb     f01018e0 <__umoddi3+0x110>
f01018d8:	75 11                	jne    f01018eb <__umoddi3+0x11b>
f01018da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018de:	73 0b                	jae    f01018eb <__umoddi3+0x11b>
f01018e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018e4:	1b 14 24             	sbb    (%esp),%edx
f01018e7:	89 d1                	mov    %edx,%ecx
f01018e9:	89 c3                	mov    %eax,%ebx
f01018eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01018ef:	29 da                	sub    %ebx,%edx
f01018f1:	19 ce                	sbb    %ecx,%esi
f01018f3:	89 f9                	mov    %edi,%ecx
f01018f5:	89 f0                	mov    %esi,%eax
f01018f7:	d3 e0                	shl    %cl,%eax
f01018f9:	89 e9                	mov    %ebp,%ecx
f01018fb:	d3 ea                	shr    %cl,%edx
f01018fd:	89 e9                	mov    %ebp,%ecx
f01018ff:	d3 ee                	shr    %cl,%esi
f0101901:	09 d0                	or     %edx,%eax
f0101903:	89 f2                	mov    %esi,%edx
f0101905:	83 c4 1c             	add    $0x1c,%esp
f0101908:	5b                   	pop    %ebx
f0101909:	5e                   	pop    %esi
f010190a:	5f                   	pop    %edi
f010190b:	5d                   	pop    %ebp
f010190c:	c3                   	ret    
f010190d:	8d 76 00             	lea    0x0(%esi),%esi
f0101910:	29 f9                	sub    %edi,%ecx
f0101912:	19 d6                	sbb    %edx,%esi
f0101914:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101918:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010191c:	e9 18 ff ff ff       	jmp    f0101839 <__umoddi3+0x69>
