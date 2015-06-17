.code16
.global _start
_start:
	jmp main

/**
 * print a string
 * DS:SI C null terminated string
 */
print:
	lodsb
	orb %al, %al
	jz printDone
	movb $0x0e, %ah
	int $0x10
	jmp print
printDone:
	ret

/* Second Stage Loader Entry Point */

main:
	cli
	pushw %cs
	popw %ds
	movw $msg, %si
	call print
	
	hlt

/* Data Section */
msg:
	.string "Preparing to load opereating system...\r\n"
	
