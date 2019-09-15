# Makefile for boot

# Programs, flags, etc.
ASM 			= nasm
ASMFLAGS		= -I include/

# For this program
TARGET			= boot.bin loader.bin a.img

.PHONY : everything clean all

# Default starting position
everything : $(TARGET)

clean :
	rm -f $(TARGET)

all : clean everything

# Command for targets
a.img : boot.bin loader.bin
	bximage
	dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc
	sudo mount a.img /mnt/ostest
	sudo cp loader.bin /mnt/ostest/loader.bin
	sudo umount /mnt/ostest

boot.bin : boot.asm include/fat12bpb.inc
	$(ASM) $(ASMFLAGS) -o $@ $<

loader.bin : loader.asm include/fat12bpb.inc
	$(ASM) $(ASMFLAGS) -o $@ $<
