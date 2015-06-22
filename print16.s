.code16
/**
 * %ds:%si the string to print
 */
print16:
	lodsb
	or %al, %al
	jz print16Done
	mov $0x0e, %ah
	int $0x10
	jmp print16
print16Done:
	ret
