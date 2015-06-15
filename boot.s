.code16
.section .text
.global _start
_start:
	movb $0x00, %ah
	movb $0x0e, %al
	int $0x10

	movw $msg_check_ext, %si
	call print_msg
	movb $0x41, %ah
	movw $0x55aa, %bx
	int $0x13
	jc ext_not_present
	cmpw $0xaa55, %bx
	je ext_present
	jmp ext_not_present

ext_not_present:
	movw  $msg_ext_not_present, %si
	call print_msg
	call reset_disk
	xorw %ax, %ax
	movw %ax, %es
	movw $0x7e00, %bx # 0x7c00 + 512 + 1
	movb $0x02, %ah
	movb $2, %al
	movb $0, %ch
	movb $2, %cl
	movb $0, %dh
	int $0x13
	cmpb $0, %ah
	jne error
	movw $0x7e00, %si
	call print_msg
	jmp end

ext_present:
	movw $msg_ext_present, %si
	call print_msg
	call reset_disk
	xorw %ax, %ax
	movw %ax, %ds
	xorw $0x7e00, %si
	movb $0x42, %ah
	movb $16, (%si)
	movb $0, 1(%si)
	movw $2, 2(%si)
	movl $0x00007e10, 4(%si)
	movl $1, 8(%si)
	movl $0, 12(%si)
	int $0x13
	jc error
	movw $0x7e10, %si
	call print_msg
	jmp end

reset_disk:
	movb $0x00, %ah
	int $0x13
	jc error
	ret

error:
	movw $msg_error, %si
	call print_msg
	jmp end

print_msg:
	movb $0x0e, %ah
	movb $0x05, %bl
	print_char:
		lodsb
		cmpb $0, %al
		je print_msg_end
		int $0x10
		jmp print_char
	print_msg_end:
		ret

msg_check_ext:
	.string "check ext\r\n"
msg_ext_not_present:
	.string "ext not present, use CHS read\r\n"
msg_ext_present:
	.string "ext present, use LBA read\r\n"
msg_error:
	.string "error occured"

end:
	hlt


	.org 510
	.byte 0x55
	.byte 0xaa
