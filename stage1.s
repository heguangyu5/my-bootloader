.code16
.global _start
_start:
	jmp main    # main 不应该距离太远,不然生成的指令就不是2个字节了
	nop			# BPB begins 3 bytes from start, jmp is 2 byte, so add a nop

/* OEM Parameter block */
bpbOEM:					.ascii "My OS   "
bpbBytesPerSector:		.word 512
bpbSectorsPerCluster: 	.byte 1
bpbReservedSectors:		.word 2
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

/* Bootloader Entry Point */
main:

	cli
	movw $0x07C0, %ax
	movw %ax, %ds
	movw %ax, %es
	/* create stack */
	xorw %ax, %ax
	movw %ax, %ss
	movw $0xFFFF, %sp # 64K
	sti

/**
 * 内存布局:
 * Stack 		= 0xFFFF = 64K
 * FAT			= 0x9A00 = 38.5K (9K) offset = 0x1E00
 * Root 		= 0x7E00 = 31.5K (7K) offset = 0x0200
 * Boot Sector 	= 0x7C00 = 31K (0.5K)
 * STAGE2		= 0x0500 = 1.25K
 */
LoadRoot:
	movw $msgLoadRoot, %si
	call print16
	# calc root size and store in %cx
	xor %dx, %dx
	mov $32, %ax
	mulw bpbRootEntries
	divw bpbBytesPerSector
	mov %ax, %cx

	# calc root LBA and store in %ax
	movb bpbNumberOfFATs, %al
	mulw bpbSectorsPerFAT 
	mov %ax, FATSectors
	add bpbReservedSectors, %ax

	mov %ax, datasector
	add %cx, datasector

	# read root into 0x7e00
	mov $0x0200, %bx
	call ReadSectors

FindStage2:
	mov $msgFindStage2, %si
	call print16
	mov $imageName, %si
	mov $0x0200, %di
	call FindFile
	cmp $-1, %ax
	je FAILURE
	push %di

LoadFAT:
	mov $msgLoadFAT, %si
	call print16
	movb FATSectors, %cl
	mov bpbReservedSectors, %ax
	call ReadSectors

LoadStage2:
	mov $msgLoadStage2, %si
	call print16
	mov $0x1E00, %si
	pushw $0x0050
	pop %es
	xor %bx, %bx
	pop %di
	mov datasector, %cx
	call LoadFile
	cmp $-1, %ax
	je  FAILURE
	ljmp $0x0050, $0x0000

FAILURE:
	movw $msgFailure, %si
	call print16
	xorb %ah, %ah
	int $0x16		# await keypress
	int $0x19		# warm boot computer

msgLoadRoot:	.string "Load Root."
msgFindStage2:	.string "Find STAGE2.SYS."
msgLoadFAT:		.string "Load FAT."
imageName:		.ascii "STAGE2  SYS"
msgLoadStage2:	.string "Load STAGE2.SYS."
msgFailure: 	.string "Error: Press Any Key to Reboot\r\n"

.include "print16.s"
.include "floppy16.s"

	.org 510
	.word 0xaa55
