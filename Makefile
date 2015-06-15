all:
	as -o boot.o boot.s
	ld --oformat binary -N -Ttext=0x7c00 -o boot boot.o
clean:
	rm boot.o boot *.img
floppy:
	bximage -fd -size=1.44 -q floppy.img
	dd if=800-chars.txt of=floppy.img seek=1 count=2 conv=notrunc
disk:
	bximage -hd  -mode=flat -size=10 -q disk.img
	dd if=800-chars.txt of=disk.img seek=1 count=2 conv=notrunc
run-floppy:
	dd if=boot of=floppy.img count=1 conv=notrunc		
	bochs 'boot:floppy'
run-disk:
	dd if=boot of=disk.img count=1 conv=notrunc
	bochs 'boot:disk'

