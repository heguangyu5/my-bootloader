.code16

initdatasector:
	# calc root size
	xor %dx, %dx
	mov $32, %ax
	mov $rootEntries, %cx
	mul %cx
	mov $bytesPerSector, %cx
	div %cx
	mov %ax, %bx

	mov $numberOfFATs, %ax
	mov $sectorsPerFAT, %cx
	mul %cx
	add $reservedSectors, %ax
	mov %ax, datasector
	add %bx, datasector
	ret

