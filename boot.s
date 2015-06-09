.section .text
.global _start;
_start:
	nop
	.org 510
	.byte 0x55
	.byte 0xaa
