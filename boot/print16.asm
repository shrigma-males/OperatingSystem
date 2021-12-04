PRINT16HEXOUT: db '0x0000', 0

print16:
    pusha


print16loop:
    mov al, [bx]
    cmp al, 0
    je print16done

    mov ah, 0x0e
    int 0x10

    add bx, 1
    jmp print16loop

print16done:
    popa
    ret

print16nl:
    pusha

    mov ah, 0x0e
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
    int 0x10

    popa
    ret

print16hex:
    pusha

    mov cx, 0

print16hexloop:
    cmp cx, 4
    je print16nl

    mov ax, dx
    and ax, 0x000f
    add al, 0x30
    cmp al, 0x39

    jle print16hex2
    add al, 7

print16hex2:
    mov bx, PRINT16HEXOUT + 5
    sub bx, cx
    mov [bx], al
    ror dx, 4

    add cx, 1
    jmp print16hexloop

print16hexend:
    mov bx, PRINT16HEXOUT
    call print16

    popa
    ret