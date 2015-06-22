.code32
.global _start
_start:

	mov $0x10, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss
	mov $0x90000, %esp

	call clearScreen32
	mov $msg, %ebx
	call puts32

	cli
	hlt
	
msg: 
	.ascii	"\n\n          - OS Development Series -"
	.string	"\n\n         MOS 32 Bit Kernel Executing\n"

.include "stdio.s"
