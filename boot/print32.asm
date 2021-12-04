[bits 32]

VIDEO_MEMORY equ 0xb8000
VIDEO_BLACK_ON_WHITE equ 0x0f


print32:
    pusha
    mov edx, VIDEO_MEMORY

print32loop:
    mov al, [ebx]
    mov ah, VIDEO_BLACK_ON_WHITE

    cmp al, 0
    je print32done

    mov [edx], ax
    add ebx, 1
    add edx, 2

    jmp print32loop

print32done:
    popa
    ret