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
		pushw %ax
		pushw %bx
		pushw %cx
		call LBACHS
		movb $0x02, %ah
		movb $0x01, %al
		movb absoluteTrack, %ch
		movb absoluteSector, %cl
		movb absoluteHead, %dh
		movb bsDriveNumber, %dl
		int $0x13
		jnc success
		xorw %ax, %ax
		int $0x13
		decw %di
		popw %cx
		popw %bx
		popw %ax
		jnz sectorLoop
		int $0x18
	success:
		movw $msgProgress, %si
		call print
		popw %cx
		popw %bx
		popw %ax
		addw bpbBytesPerSector, %bx
		incw %ax
		loop readStart
		ret

/**
 * convert CHS to LBA
 * LBA = (cluster - 2) * sectors per cluster
 */
clusterLBA:
	subw $2, %ax
	xorw %cx, %cx
	movb bpbSectorsPerCluster, %cl
	mulw %cx
	addw datasector, %ax
	ret

/**
 * convert LBA to CHS
 * %ax LBA address to convert
 */
LBACHS:
	xorw %dx, %dx
	divw bpbSectorsPerTrack
	incb %dl
	movb %dl, absoluteSector
	xorw %dx, %dx
	divw bpbHeadsPerCylinder
	movb %dl, absoluteHead
	movb %al, absoluteTrack
	ret

/* Bootloader Entry Point */
main:

	cli
	movw $0x07C0, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %gs

	/* create stack */
	xorw %ax, %ax
	movw %ax, %ss
	movw $0xFFFF, %sp # 64K
	sti

	/* print loading msg */
	movw $msgLoading, %si
	call print

	/* load root direcotry table */
	loadRoot:
		xorw %cx, %cx
		xorw %dx, %dx
		movw $32, %ax
		mulw bpbRootEntries
		divw bpbBytesPerSector
		xchgw %cx, %ax				# %cx (root dir table sectors) now should be 14 = 32B * 224 / 512B

		movb bpbNumberOfFATs, %al
		mulb bpbSectorsPerFAT
		addw bpbReservedSectors, %ax
		incw %ax
		movw %ax, datasector
		addw %cx, datasector

		# read root dir table into memory (0x07C0:0200)
		movw $0x0200, %bx
		call readSectors

	/* find stage 2 */
		movw bpbRootEntries, %cx
		movw $0x0200, %di
		findStart:
			pushw %cx
			movw $11, %cx
			movw $imageName, %si
			pushw %di
			rep cmpsb
			popw %di
			je loadFAT
			popw %cx
			addw $32, %di
			loop findStart
			jmp FAILURE

	/* load FAT */
	/* @see http://www.win.tue.nl/~aeb/linux/fs/fat/fat-1.html for more about FAT */
	loadFAT:
		movw $msgCRLF, %si
		call print
		movw 26(%di), %dx
		movw %dx, cluster

		xorw %ax, %ax
		movb bpbNumberOfFATs, %al
		mulw bpbSectorsPerFAT
		movw %ax, %cx

		movw bpbReservedSectors, %ax
		incw %ax

		# read FAT into memory (0x07C0:0200)
		movw $0x0200, %bx
		call readSectors

		# read image file into memory (0x0500:0000)
		movw $msgCRLF, %si
		call print
		movw $0x0050, %ax
		movw %ax, %es
		xorw %bx, %bx
		pushw %bx

	/* load stage 2 */
	loadImage:
		movw cluster, %ax
		popw %bx
		call clusterLBA
		xorw %cx, %cx
		movb bpbSectorsPerCluster, %cl
		call readSectors
		pushw %bx

		# next cluster
		movw cluster, %ax
		movw %ax, %cx
		movw %ax, %dx
		shrw $1, %dx
		addw %dx, %cx
		movw $0x0200, %bx
		addw %cx, %bx
		movw (%bx), %dx
		test $1, %ax
		jnz oddCluster
	evenCluster:
		andw $0b0000111111111111, %dx
		jmp done
	oddCluster:
		shr $4, %dx
	done:
		movw %dx, cluster
		cmpw $0x0FF0, %dx
		jb loadImage

		movw $msgCRLF, %si
		call print
		ljmp $0x0050, $0x0000

	FAILURE:
		movw $msgFailure, %si
		call print
		xorb %ah, %ah
		int $0x16		# await keypress
		int $0x19		# warm boot computer

absoluteSector: .byte 0
absoluteHead:	.byte 0
absoluteTrack:	.byte 0

datasector: 	.word 0
cluster:		.word 0
imageName:		.ascii "STAGE2  SYS"
msgLoading:		.string "\r\nLoading Boot Image\r\n"
msgCRLF: 		.string "\r\n"
msgProgress: 	.string "."
msgFailure: 	.string "\r\nError: Press Any Key to Reboot\r\n"

	.org 510
	.word 0xaa55

/**
 * 内存布局:
 * DS = ES = 0x07C0
 * SS:SP = 0x0000:0xFFFF = 64K
 * Root Direcotry Table (7K) then FAT (9K)  = 38.5K  then = 40.5K
 * boot sector 0x7DFF	 = 31.5K
 * CS:IP = 0x0000:0x7C00 = 31K
 * STAGE2 = 0x0500 = 1.25K
 */
