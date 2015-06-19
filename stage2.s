.code16
.global _start
_start:
	jmp main

.include "stdio.s"
.include "gdt.s"

loadingMsg:
	.string "Preparing to load opereating system...\r\n"


/* Second Stage Loader Entry Point */
main:
	/* set up segments and stack */
	cli
	xorw %ax, %ax
	movw %ax, %ds
	movw %ax, %es
	movw $0x9000, %ax
	movw %ax, %ss
	movw $0xffff, %sp
	sti

	call installGDT

	# enable A20
	movb $0xdd, %al
	outb %al, $0x64
	waitInput:
		inb $0x64, %al
		testb $2, %al
		jnz waitInput

	movw $loadingMsg, %si
	call print16


	# protect mode
	cli
	movl %cr0, %eax
	xorl $1, %eax
	movl %eax, %cr0

	ljmp $0x08, $stage3

/**
 * 上边的内存布局:
 * SS:SP = 0x9000:0xFFFF = 640K
 * CS:IP = 0x0050:0x0000 = 1.25K
 */

.code32
stage3:
	movw $16, %ax
	movw %ax, %ds
	movw %ax, %ss
	movw %ax, %es
	movl $0x90000, %esp

	call clearScreen32
	movl $msg, %ebx
	call puts32

stop:
	cli
	hlt

msg:
	.string "\n\n\n      <[ OS Development Series ]>\n\n    Basic 32 bit graphics demo in Assembly Language"

/**
 * 内存布局:
 * SS:SP = 0x10:0x90000 = 576K
 * CS:IP = 0x0050:0x0000 = 1.25K
 */
