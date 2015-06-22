.code32
.equ VIDMEM, 0xB8000
.equ COLS, 80
.equ LINES,	25
.equ CHAR_ARRT,	63 # 0x3F = 0x0011 1111 = 001(fg) 1 111(bg) 1 = 

curX: .byte 0
curY: .byte 0

/**
 * %bl the char to print
 */
putc32:
	pusha

	# (curY * COLS + x) * 2
	xor %eax, %eax
	movb curY, %al
	mov $COLS, %ecx
	mul %ecx
	xor %ecx, %ecx
	movb curX, %cl
	add %ecx, %eax
	mov $2, %ecx
	mul %ecx

	movl $VIDMEM, %edi
	add %eax, %edi

	cmpb $0x0a, %bl
	je nextRow

	movb $CHAR_ARRT, %bh
	movw %bx, (%edi)

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

/**
 * %ebx string start address
 */
puts32:
	pusha

	mov %ebx, %edi
putcLoop:
	mov (%edi), %bl
	cmp $0, %bl
	je puts32Done
	call putc32
	inc %edi
	jmp putcLoop
puts32Done:
	movb curY, %bh
	movb curX, %bl
	call movCur

	popa
	ret
/**
 * %bh: Y
 * %bl: X
 */
movCur:
	pusha

	# cursor location = Y * COLS + x
	xor %eax, %eax
	mov %bh, %al
	mov $COLS, %ecx
	mul %ecx
	mov %eax, %ebx
	xor %ecx, %ecx
	mov %bl, %cl
	add %ecx, %ebx

	# cursor location low byte
	xor %ax, %ax
	mov $0x0f, %al
	mov $0x03d4, %dx # Index Register
	out %ax, %dx
	
	mov %bl, %al
	mov $0x03d5, %dx # Data Register
	out %ax, %dx

	# cursor location high byte
	mov $0x0e, %al
	mov $0x03d4, %dx # Index Register
	out %ax, %dx

	mov %bh, %al
	mov $0x03d5, %dx # Data Register
	out %ax, %dx

	popa
	ret

clearScreen32:
	pusha
	cld

	mov $VIDMEM, %edi
	mov $2000, %ecx     # 80 * 25 = 2000 chars
	mov $CHAR_ARRT, %ah
	mov $' ', %al
	rep stosw

	movb $0, curX
	movb $0, curY
	
	popa
	ret

/**
 * %ah = Y
 * %al = X
 */
gotoXY:
	pusha

	movb %ah, curY
	movb %al, curX

	popa
	ret
