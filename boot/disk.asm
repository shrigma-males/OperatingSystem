diskLoad:
    mov ah, 0x42
    mov dl, BOOT_DRIVE
    mov si, diskAddressPacket
    int 0x13
    jc diskError

    popa
    ret





diskError:
    mov bx, DISK_ERR
    call print16
    call print16nl
    mov dh, ah
    call print16hex
    jmp diskLoop

sectorError:
    mov bx, SECTOR_ERR
    call print16

diskLoop:
    jmp $

DISK_ERR: db "Disk read error", 0
SECTOR_ERR: db "Incorrect sectors read", 0






diskAddressPacket:
    db 0x10
    db 0
    dw KERNEL_SIZE
    dw 0
    dw KERNEL_OFFSET
    dq 1