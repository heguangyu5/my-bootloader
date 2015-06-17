.code16
.global _start
_start:
	cli

	movw $10, %ax
	divb num_three

	hlt

num_three:
	.byte 3

	.org 510
	.word 0xaa55
