all:
	as -o boot.o boot.s
	ld --oformat binary -o boot boot.o
clean:
	rm boot.o boot
floppy:
	mkfs.msdos -C floppy.img 1440
run:
	dd if=boot of=floppy.img count=1 conv=notrunc		
	bochs
