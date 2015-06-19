.code16

installGDT:
	cli
	pusha
	lgdt toc
	sti
	popa
	ret

gdt_data:
	.quad 0
# gdt_code
	.word 0xFFFF
	.word 0
	.byte 0
	.byte 0b10011010
	.byte 0b11001111
	.byte 0
# gdt_data
	.word 0xFFFF
	.word 0
	.byte 0
	.byte 0b10010010
	.byte 0b11001111
	.byte 0
end_of_gdt:
toc:
	.word end_of_gdt - gdt_data - 1
	.long gdt_data
