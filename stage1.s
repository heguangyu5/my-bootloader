.code16
.global _start
_start:
	jmp main
	nop			# BPB begins 3 bytes from start, jmp is 2 byte, so add a nop

/* OEM Parameter block */
bpbOEM:					.ascii "My OS   "
bpbBytesPerSector:		.word 512
bpbSectorsPerCluster: 	.byte 1
bpbReservedSectors:		.word 1
bpbNumberOfFATs:		.byte 2
bpbRootEntries:			.word 224
bpbTotalSectors:		.word 2880
bpbMedia:				.byte 0xF0 /* single sided, 9 sectors per FAT, 80 tracks, movable disk */
bpbSectorsPerFAT:		.word 9
bpbSectorsPerTrack:		.word 18
bpbHeadsPerCylinder:	.word 2
bpbHiddenSecotrs:		.int  0
bpbTotalSectorsBig:		.int  0
bsDriveNumber:			.byte 0
bsUnused:				.byte 0
bsExtBootSignature:		.byte 0x29
bsSerialNumber:			.int  0xa0a1a2a3
bsVolumeLabel:			.ascii "MOS FLOPPY "
bsFileSystem:			.ascii "FAT12   "

/**
 * print string
 * %ds:%si
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

/**
 * read sectors
 * %cx number of secotrs to read
 * %ax starting sector
 * %es:%bx buffer
 */
readSectors:
	readStart:
		movw $5, %di	# 5 retries for error
	sectorLoop:
		push %ax
		push %bx
		push %cx
		call LBACHS

/**
 * convert LBA to CHS
 * %ax LBA address to convert
 * sector = (LBA % sectors per track) + 1
 * head   = (LBA / sectors per track) % number of heads
 * track  = LBA / (sectors per track * number of heads)
 */
LBACHS:
	xorw %dx, %dx
	divw $bpbSectorsPerTrack

/* Bootloader Entry Point */
main:

.reset:
	movb $0x00, %ah
	movb $0x00, %dl
	int $0x13
	jc .reset

	movw $0x1000, %ax
	movw %ax, %es
	xorw %bx, %bx  # %es:%bx = buffer, 0x1000:0 = 64K, this is the esp, is it OK?

	movb $0x02, %ah # read
	movb $1, %al 	# read 1 sector
	movb $1, %ch	# track 1
	movb $2, %cl	# read the 2th secotr
	movb $0, %dh	# head 0
	movb $0, %dl	# drive number, floppy is 0
	int $0x13

	jmp 0x10000
	
	.org 510
	.word 0xaa55
