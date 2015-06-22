.code16

.equ driveNumber, 0x00
.equ bytesPerSector, 512
.equ sectorsPerCluster, 1
.equ sectorsPerTrack, 18
.equ headsPerCylinder, 2
.equ rootEntries, 224
.equ numberOfFATs, 2
.equ sectorsPerFAT, 9
.equ reservedSectors, 2

FATSectors: .byte 0

datasector: .word 0
cluster:	.word 0

absoluteSector: .byte 0
absoluteHead:	.byte 0
absoluteTrack:	.byte 0

/**
 * %ax: the cluster
 * LBA = (cluster - 2) * sectors per cluster
 * %cx = datasector
 */
ClusterLBA:
	push %cx
	sub $2, %ax
	mov $sectorsPerCluster, %cx
	mul %cx
	pop %cx
	add %cx, %ax
	ret

/**
 * %ax: the LBA
 * absoluteSector = (LBA % sectorsPerTrack) + 1
 * absoulteHead   = (LBA / sectorsPerTrack) % headsPerCylinder
 * absoluteTrack  = LBA / (sectorsPerTrack * headsPerCylinder) = LBA / sectorsPerTrack / headsPerCylinder
 */
LBACHS:
	xor %dx, %dx
	mov $sectorsPerTrack, %cx
	div %cx
	inc %dl
	mov %dl, absoluteSector
	xor %dx, %dx
	mov $headsPerCylinder, %cx
	div %cx
	mov %dl, absoluteHead
	mov %al, absoluteTrack
	ret

/**
 * %cx: number of sectors to read
 * %ax: starting sector
 * %es:%bx buffer
 */
ReadSectors:
	RS_MAIN:
		mov $5, %di
	RS_SECTORLOOP:
		push %ax
		push %bx
		push %cx
		call LBACHS
		mov $0x02, %ah
		mov $0x01, %al
		movb absoluteTrack, %ch
		movb absoluteSector, %cl
		movb absoluteHead, %dh
		movb $driveNumber, %dl
		int $0x13
		jnc RS_SUCCESS
		mov $0x00, %ax
		int $0x13
		pop %cx
		pop %bx
		pop %ax
		dec %di
		jnz RS_SECTORLOOP
		int $0x18
	RS_SUCCESS:
		pop %cx
		pop %bx
		pop %ax
		add $bytesPerSector, %bx
		inc %ax
		loop RS_MAIN
		ret
/**
 * FindFile
 * %ds:%si filename
 * %es:%di root table start
 * %ax -1 if not found
 * %es:%di file entry
 */
FindFile:
	mov $rootEntries, %cx

	FF_LOOP:
		push %cx
		push %si
		push %di
		mov $11, %cx
		rep cmpsb
		pop %di
		pop %si
		je FF_FOUND
		pop %cx
		add $32, %di
		loop FF_LOOP
	FF_NOT_FOUND:
		mov $-1, %ax
		ret
	FF_FOUND:
		pop %ax
		ret
/**
 * LoadFile
 * %ds:%di file entry
 * %ds:%si FAT
 * %es:%bx buffer
 * %cx datasector
 */
LoadFile:
	mov 26(%di), %ax
	mov %ax, cluster

	LF_RS:
		mov cluster, %ax
		call ClusterLBA
		push %cx
		mov $sectorsPerCluster, %cx
		call ReadSectors

		# next cluster: cluster * 1.5 = cluster + cluster / 2 
		mov cluster, %ax
		mov %ax, %dx
		mov %ax, %cx
		shr $1, %dx
		add %dx, %ax
		push %si
		add %ax, %si
		mov (%si), %ax
		pop %si
		test $1, %cx
		jz LF_evenCluster
		shr $4, %ax
		jmp LF_RS_DONE
	LF_evenCluster:
		and $0b0000111111111111, %ax
	LF_RS_DONE:
		pop %cx
		mov %ax, cluster
		cmp $0x0FF0, %ax
		jb LF_RS
		ret
