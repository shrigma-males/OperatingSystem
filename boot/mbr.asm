[org 0x7c00]
mov [BOOT_DRIVE], dl
mov bx, MSG_16BITMODE
call print16
call print16nl

call loadKernel
call switchto32bit

jmp $

%include "./boot/print16.asm"
%include "./boot/print32.asm"
%include "./boot/disk.asm"
%include "./boot/gdt.asm"
%include "./boot/idt.asm"


KERNEL_OFFSET equ 0x1000
KERNEL_SIZE equ 0x88
BOOT_DRIVE db 0
MSG_LOADKERNEL db "Loading kernel into system memory",0
MSG_32BITMODE db "Starting in 32-bit protected mode",0
MSG_16BITMODE db "Starting in 16-bit real mode",0


[bits 16]
loadKernel:
    mov bx, MSG_LOADKERNEL
    call print16
    call print16nl


    call diskLoad
    ret

[bits 32]
begin32bit:
    mov ebx, MSG_32BITMODE
    call print32
    call KERNEL_OFFSET
    jmp $



times 510 - ($-$$) db 0
dw 0xAA55