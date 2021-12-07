LD = i686-elf-ld
CC = i686-elf-gcc
ASM = nasm
CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra -fno-pic -fno-stack-protector
LDFLAGS = -nostdlib -nostartfiles -no-pie

all: kernel.i686-elf


kernel.i686-elf:
	$(CC) $(CFLAGS) -c ./kernel/kernel.c -o kernel.o
	$(ASM) ./boot/boot.asm -f bin -o bootsect.bin
#	$(ASM) ./boot/entry.asm -f elf -o entry.o
#	$(LD) -o kernel.bin -Ttext 0x1000 entry.o kernel.o --oformat binary
	
#	cat bootsect.bin kernel.bin > osImage.bin

