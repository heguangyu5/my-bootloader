.code16
print16:
	pusha
print16Loop:
	lodsb
	orb %al, %al
	jz print16Done
	movb $0x0e, %ah
	int $0x10
	jmp print16Loop
print16Done:
	popa
	ret

.code32
.equ VIDMEM, 0xB8000
.equ COLS, 80
.equ LINES,	25
.equ CHAR_ARRT,	63

curX: .byte 0
curY: .byte 0

putc32:
	pusha
	movl $VIDMEM, %edi
	xorl %eax, %eax
	movl $COLS * 2, %ecx
	movb curY, %al
	mull %ecx
	pushl %eax

	movb curX, %al
	movb $2, %cl
	mulb %cl
	popl %ecx
	add %ecx, %eax

	xorl %ecx, %ecx
	add %eax, %edi

	cmpb $0x0a, %bl
	je nextRow

	movb %bl, %dl
	movb $CHAR_ARRT, %dh
	movw %dx, (%edi)

	incb curX
	cmpb $COLS, curX
	je nextRow
	jmp putc32Done

nextRow:
	movb $0, curX
	incb curY
putc32Done:
	popa
	ret

puts32:
	pusha
	pushl %ebx
	popl %edi

putcLoop:
	movb (%edi), %bl
	cmpb $0, %bl
	je puts32Done
	call putc32
	incl %edi
	jmp putcLoop

puts32Done:
	movb curY, %bh
	movb curX, %bl
	call movCur

	popa
	ret

movCur:
	pusha

	xorl %eax, %eax
	movl $COLS, %ecx
	movb %bh, %al
	mull %ecx
	addb %bl, %al
	movl %eax, %ebx

	movb $0x0f, %al
	movw $0x03d4, %dx
	outb %al, %dx
	
	movb %bl, %al
	movw $0x03d5, %dx
	outb %al, %dx

	movb $0x0e, %al
	movw $0x03d4, %dx
	outb %al, %dx

	movb %bh, %al
	movw $0x03d5, %dx
	outb %al, %dx

	popa
	ret

clearScreen32:
	pusha
	cld
	movl $VIDMEM, %edi
	movl $2000, %ecx
	movb $CHAR_ARRT, %ah
	movb $' ', %al
	rep stosw

	movb $0, curX
	movb $0, curY
	
	popa
	ret

gotoXY:
	pusha
	movb %al, curX
	movb %ah, curY
	popa
	ret
