**Bochs**

    sudo apt-get install libsdl1.2-dev
    ./configure --enable-debugger --enable-debugger-gui --enable-disasm --with-sdl

**Run**

    make floppy
    make stage1
    make stage2
    make stage3
	make run-floppy

![KRNL.SYS](http://git.oschina.net/heguangyu5/my-bootloader/raw/master/bochs-screenshot.png)

**参考资料**

- http://www.kerneltravel.net/?page_id=21
- https://en.wikibooks.org/wiki/X86_Assembly
- Programming from the Ground Up
- asm64-handout.pdf
- GRUB源码分析
- p4-boot, Writing a Bootloader from Scratch
- http://www.brokenthorn.com/Resources/OSDevIndex.html 
- http://www.win.tue.nl/~aeb/linux/fs/fat/fat-1.html
