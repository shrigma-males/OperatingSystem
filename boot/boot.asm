extern                      kernel                      ;Make it so that we can call the kernel function

section                     .boot                       ;This is the boot section
bits                        16                          ;Set the bootloader to be 16 bits
VIDEO_MEMORY                equ 0xb8000                 ;Video memory for 32bits
WHITE_ON_BLACK              equ 0x0f                    ;Color data for 32 bit printing
global                      boot                        ;Make boot global for linking


boot:                       jmp loader                  ;Jump to the bootloader

bpbOEM                      db "My OS   "               ;Name of OS. Replaces TIMES directive
bpbBytesPerSector:          dw 512                      ;512 bytes per sector
bpbSectorsPerCluster:       db 1                        ;1 sector for each cluster
bpbReservedSectors:         dw 1                        ;First sector is reserved for bootloader
bpbNumberOfFats:            db 2                        ;Use FAT12
bpbRootEntries              dw 224                      ;Number of root entries
bpbTotalSectors             dw 1406                     ;Use 720k for both bootloader and kernel
bpbMedia:                   db 0xF0                     ;Media descriptor byte
bpbSectorsPerFat:           dw 9                        ;9 sectors (need to be this for media descriptor byte)
bpbSectorsPerTrack:         dw 18                       ;18 sectors per fat
bpbHeadsPerCylinder:        dw 2                        ;Number of heads per cylinder
bpbHiddenSectors:           dd 0                        ;Number of hidden sectors
bpbTotalSectorsBig:         dd 0                        ;Number of big sectors
bsDriveNumber:              db 0                        ;Set drive number to 0
bsUnused:                   db 0                        ;This is unused
bsExtBootSignature:         db 0x29                     ;Specify that this is a MS/PC-DOS version 4.0 BPB
bsSerialNumber:             dd 0xDEADC0                 ;Serial number (this should be unique)
bsVolumeLabel:              db "MOS FLOPPY "            ;set volume to MOS floppy
bsFileSystem:               db "FAT12   "               ;use the FAT12 file system

BootMsg:                    db "loading os", 0          ;Message on boot
gdtMsg:                     db "loading GDT", 0         ;Message called after loading the GDT
rstErr:                     db "dsk reset err",0        ;Message for reseting the disk error
readErr:                    db "dsk read err",0         ;Message for reading the disk error

print:                                                  ;16 bit print function
    lodsb                                               ;Load the next byte from SI to AL
    or                      al, al                      ;Check if AL is 0
    jz                      printDone                   ;Jump to printDone if we reach \0
    mov                     ah, 0eh                     ;Otherwise, print the character
    int                     0x10                        ;Call the interrupt for displaying text onto the screen
    jmp                     print                       ;Continue to the next character

printDone:                                              ;Called when the a null terminator is reached
    ret                                                 ;Return from the function

printNL:
    pusha                                               ;Push everything

    mov                     ah, 0x0e                    ;
    mov                     al, 0x0a                    ;Newline character
    int                     0x10                        ;Call video interrupt

    popa                                                ;Pop everything 
    ret                                                 ;Return from the function

print32:                                                ;32 bit printing after we load the GDT
    pusha                                               ;push everything onto the stack
    mov                     edx, VIDEO_MEMORY           ;EDX will contain the video memory
print32loop:                                            ;Main loop for printing
    mov                     al, [ebx]                   ;Set AL to contain the address of the character
    mov                     ah, WHITE_ON_BLACK          ;Set Ah to contain the color of the character
    cmp                     al, 0                       ;Check for a newline
    je                      print32Done                 ;Jump if printing is finished

    mov                     [edx], ax                   ;Store the character + color attribute
    add                     ebx, 1                      ;Go to the next character
    add                     edx, 2                      ;Next video memory character
    jmp                     print32loop                 ;Loop until we're finished

print32Done:                                            ;Finish printing everything
    popa                                                ;Pop everything
    ret                                                 ;Return from the function

readKernel:                                             ;Read disk for kernel
.reset:                                                 ;Reset disk
    mov                     ah, 0                       ;Set ah to reset function
    mov                     dl, 0                       ;Set drive to 0
    int                     0x13                        ;Call the interrupt for the disk
    jc                      .resetError                 ;If theres a error, print error and try again
.read:                                                  ;Read disk
    mov                     ah, 0x2                     ;Read disk function
    mov                     al, 150                     ;Number of sectors to read (~70 kilobytes)
    mov                     ch, 1                       ;Sector to read
    mov                     dh, 0                       ;head number
    mov                     dl, 0                       ;drive number
    mov                     cl, 2                       ;Sector IDX
    mov                     bx, copyTarget              ;Target pointer
    int                     0x13                        ;Call the read disk function again
    jc                      .readError                  ;Try again if theres a error

    jmp                     0x1000:0x0                  ;Jump to 0x1000, where the kernel is located    

.resetError:                                            ;Error if we're going to reset the disk
    mov                     si, rstErr                  ;Set SI to reset error
    call                    print                       ;print the message
    call                    printNL                     ;Pinrt a newline character
    jmp                     .reset                      ;if error, print error and try again
.readError:                                             ;Error if reading from the disk fails
    mov                     si, readErr                 ;Set SI to read error
    call                    print                       ;call the print error
    call                    printNL                     ;Print a newline character
    jmp                     .read                       ;jump back to the read funciton

gdtStart:                                               ;Null segment of the GDT
    dq                      0x0                         ;
gdtCode:                                                ;Code segment of the GDT
    dw                      0xFFFF                      ;Segment length
    dw                      0x0                         ;Segment base
    db                      0x0                         ;Segment base
    db                      10011010b                   ;8 bit flags
    db                      11001111b                   ;4 bit flags + segment length
    db                      0x0                         ;Segment base
gdtData:                                                ;Data segment of the GDT
    dw                      0xFFFF                      ;Segment length
    dw                      0x0                         ;Segment base
    db                      0x0                         ;Segment base
    db                      10010010b                   ;8 bit flags
    db                      11001111b                   ;4 bit flags
    db                      0x0                         ;Segment base
gdtEnd:                                                 ;End of the GDT
gdtDescriptor:                                          ;Descriptor segment of the GDT
    dw gdtEnd - gdtStart - 1                            ;size of gdt in 16 bits
    dd gdtStart                                         ;address in 32 bits


bits                        16                          ;The following function is 16 bit
switch32bit:                                            ;switch to 32bit function
    cli                                                 ;Disable interrupts
    lgdt                    [gdtDescriptor]             ;Load the GDT descriptor
    mov                     eax, cr0                    ;
    or                      eax, 0x1                    ;enable protected mode
    mov                     cr0, eax                    ;
    jmp                     CODE_SEG:init32bit          ;Init 32 bits

bits                        32                          ;The function below is 32 bits
init32bit:
    mov                     ax, DATA_SEG                ;Update segment registers
    mov                     ds, ax                      ;ditto
    mov                     ss, ax                      ;ditto
    mov                     es, ax                      ;ditto
    mov                     fs, ax                      ;ditto
    mov                     gs, ax                      ;ditto

    mov                     ebp, 0x9000                 ;Set up the stack
    mov                     esp, ebp                    ;Continue setting up the stack

    ret                                                 ;Exit from this function



CODE_SEG equ gdtCode - gdtStart                         ;Code Segment
DATA_SEG equ gdtData - gdtStart                         ;Data segment

bits                        16
loader:                                                 ;Bootloader entry point
    xor                     ax, ax                      ;Setup segments to ensure they are 0
    mov                     ds, ax                      ;ditto
    mov                     es, ax                      ;ditto


    mov                     si, BootMsg                 ;Load the message 
    call                    print                       ;Call the print function
    call                    printNL                     ;Need a newline right after this

    mov                     si, gdtMsg                  ;Load the message
    call                    print                       ;Call the print function
    call                    printNL                     ;Need a newline right after this

    call                    init32bit                   ;Load the GDT and get 4gb of memory
    call                    readKernel                  ;Go to the second sector and load the kernel




times 510 - ($-$$) db 0                                 ;Pad the remining bytes with 0's
dw 0xAA55                                               ;Boot signature

copyTarget:                                             ;Disk loads this and everything below
bits                        32                          ;GDT is loaded. Everything has to be 32 bits now


loadKernel:                                             ;Load kernel label
    mov                     esp, kernel_stack_top       ;Set the ESP register for the stack
    call                    kernel                      ;Call the kernel function and load the bootloader

halt:                                                   ;Halt label
    cli                                                 ;Clear all interrupts
    hlt                                                 ;Halt the CPU

kernel_stack_bottom:        equ $                       ;Bottom of the stack
	resb                    16384                       ;Load 16 kilobytes for the stack
kernel_stack_top:                                       ;Top of the stack