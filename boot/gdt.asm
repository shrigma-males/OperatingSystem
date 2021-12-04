GDT_START:
    dd 0x0
    dd 0x0


GDT_CODE:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10011010b
    db 11001111b
    db 0x0
GDT_DATA:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0
GDT_END:
GDT_DESCRIPTOR:
    dw GDT_END - GDT_START - 1
    dd GDT_START

CODE_SEG equ GDT_CODE - GDT_START
DATA_SEG equ GDT_DATA - GDT_START



[bits 16]
switchto32bit:
    cli
    lgdt [GDT_DESCRIPTOR]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:init32bit


[bits 32]
init32bit:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000
    mov esp, ebp

    call begin32bit