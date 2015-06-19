stage1:
	as -o stage1.o stage1.s
	ld --oformat binary -N -Ttext=0x0000 -o STAGE1 stage1.o
	dd if=STAGE1 of=floppy.img count=1 conv=notrunc		
stage2:
	as -o stage2.o stage2.s
	ld --oformat binary -N -Ttext=0x0500 -o STAGE2.SYS stage2.o
	sudo mount -t msdos -o loop,fat=12 floppy.img /mnt
	sudo cp STAGE2.SYS /mnt
	sudo umount /mnt
floppy:
	bximage -fd -size=1.44 -q floppy.img
	sudo losetup /dev/loop0 floppy.img
	sudo mkdosfs -F 12 -R 2 /dev/loop0
	sudo losetup -d /dev/loop0
run-floppy:
	bochs -q 'boot:floppy'
clean:
	rm *.o *.img test STAGE1 STAGE2.SYS
test: test.s
	as -o test.o test.s
	ld --oformat binary -N -Ttext=0x7c00 -o test test.o
	dd if=test of=floppy.img count=1 conv=notrunc
run-test:
	bochs -q 'boot:floppy'
