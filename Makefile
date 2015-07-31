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
stage3:
	as -o stage3.o stage3.s
	ld --oformat binary -N -Ttext=0x0000 -o KRNL.SYS stage3.o
	sudo mount -t msdos -o loop,fat=12 floppy.img /mnt
	sudo cp KRNL.SYS /mnt
	sudo umount /mnt
floppy:
	bximage -fd -size=1.44 -q floppy.img
	sudo losetup /dev/loop0 floppy.img
	sudo mkdosfs -F 12 -R 2 /dev/loop0
	sudo losetup -d /dev/loop0
run-floppy:
	bochs -q 'boot:floppy'
clean:
	rm *.o *.img *.SYS STAGE1 test
test: test.s
	as -o test.o test.s
	ld --oformat binary -N -Ttext=0x7c00 -o test test.o
	dd if=test of=floppy.img count=1 conv=notrunc
run-test:
	bochs -q 'boot:floppy'
bios-call: bios-call.s
	as -o bios-call.o bios-call.s
	ld --oformat binary -N -Ttext=0x0500 -o BIOS.SYS bios-call.o
	sudo mount -t msdos -o loop,fat=12 floppy.img /mnt
	sudo cp BIOS.SYS /mnt/STAGE2.SYS
	sudo umount /mnt
