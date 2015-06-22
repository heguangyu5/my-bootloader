.code16
.global _start
_start:
	jmp main

.include "print16.s"
.include "floppy16.s"
.include "gdt.s"
.include "initdatasector.s"

kernelName: .ascii "KRNL    SYS"
kernelSize: .int 0
loadingMsg: .string "\r\nSearching for Opereating System...\r\n"
msgFailure: .string "*** FATAL: MISSING OR CURRUPT KRNL.SYS. Press Any Key to Reboot\r\n"

/* Second Stage Loader Entry Point */
main:
	/* set up segments and stack */
	cli
	xor %ax, %ax
	mov %ax, %ds
	mov  $0x07C0, %ax
	mov %ax, %es
	mov $0x9000, %ax
	mov %ax, %ss
	mov $0xffff, %sp
	sti
	/* init datasector */
	call initdatasector

	call installGDT

	# enable A20
	mov $0xdd, %al
	out %al, $0x64
	waitInput:
		in $0x64, %al
		test $2, %al
		jnz waitInput

FindKernel:
	mov $loadingMsg, %si
	call print16
	mov $kernelName, %si
	mov $0x0200, %di
	call FindFile
	cmp $-1, %ax
	je KernelNotFound
	mov datasector, %cx
	mov $0x07C0, %ax
	mov %ax, %ds
	mov $0x1E00, %si
	mov $0x0300, %ax
	mov %ax, %es
	xor %bx, %bx
	movl 28(%di), %eax
	push %ds
	push $0
	pop %ds
	movl %eax, kernelSize
	pop %ds
	call LoadFile
	jmp EnterStage3
KernelNotFound:
	mov $msgFailure, %si
	call print16
	xor %ah, %ah
	int $0x16
	int $0x19
	cli
	hlt
	
EnterStage3:
	# protect mode
	cli
	movl %cr0, %eax
	xorl $1, %eax
	movl %eax, %cr0

	ljmp $0x08, $stage3

/**
 * 上边的内存布局:
 * Stack 		= 0x9000:0xFFFF = 640K
 * FAT			= 0x9A00 = 38.5K (9K) offset = 0x1E00
 * Root 		= 0x7E00 = 31.5K (7K) offset = 0x0200
 * Boot Sector 	= 0x7C00 = 31K (0.5K)
 * Kernel		= 0x3000 = 12K
 * This STAGE2	= 0x0500 = 1.25K
 */
.include "stdio.s"

.code32
stage3:
	movw $16, %ax
	movw %ax, %ds
	movw %ax, %ss
	movw %ax, %es
	movl $0x90000, %esp

	# copy kernel to 1MB
CopyKernel:
	xor %edx, %edx
	mov kernelSize, %eax	
	mov $4, %ebx
	div %ebx
	cld
	mov $0x3000, %esi
	mov $0x100000, %edi
	mov %eax, %ecx
	rep movsd

	ljmp $0x08, $0x100000


	cli
	hlt

/**
 * 内存布局:
 * KRNL.SYS	   = 0x100000	  = 1M
 * Stack SS:SP = 0x10:0x90000 = 576K
 * KRNL.SYS	   = 0x3000		  = 12K
 */
