.code16
.global _start
_start:
	cli
	xorw %ax, %ax
	movw %ax, %ds
	movw %ax, %es
	/* create stack */
	xorw %ax, %ax
	movw %ax, %ss
	movw $0xFFFF, %sp # 64K

	jmp main

# Video 0x10
# setVideoMode(u8 mode)
setVideoMode:
	xor %ah, %ah
	mov 2(%esp), %al
	int $0x10
	cmp %al, %al
	jne 1f
0:
	xor %ax, %ax
1:
	ret

# puts(char *s)
puts:
	mov 2(%esp), %si
putc:
	lodsb
	or %al, %al
	jz puts_done
	mov $0x0e, %ah
	mov $0x0007, %bx
	int $0x10
	jmp putc
puts_done:
	ret	

# start_newline(void)
start_newline:
	push $msg_newline
	call puts
	add $2, %sp
	ret

main:
	push $0x20
	call setVideoMode
	add $2, %sp
	cmp $0, %ax
	jne end
0:
	call start_newline	
	push $msg_video_mode	
	call puts
	add $2, %sp
	push $msg_ok
	call puts
	add $2, %sp

end:
	hlt

msg_newline: .string "\r\n"
msg_ok: .string " => ok\r\n"
msg_failed: .string " => failed\r\n"
msg_video_mode: .string "set video mode to 20h"
