use16
org 0x100

; Save real mode IDTR
sidt fword[REAL_IDTR]

; Disable all interrupts
cli

in  al  , 0x70
or  al  , 0x80
out 0x70, al

; Open A20 gate
in  al  , 0x92
or  al  , 0x02
out 0x92, al

; Set up code bases to be CS
xor eax, eax
mov ax , cs
shl eax, 0x04
mov [D_CODE+2], al
mov [D_CODE16+2], al
shr eax, 0x08
mov [D_CODE+3], al
mov [D_CODE16+3], al
mov [D_CODE+4], ah
mov [D_CODE16+4], ah

; Calculate GDT linear address
xor eax, eax
mov ax , cs
shl eax, 0x04
add ax , GDT

; Put GDT address in variable
mov dword[GDTR+2], eax

; Calculate IDT linear address
xor eax, eax
mov ax , cs
shl eax, 0x04
add ax , IDT

; Put IDT address in variable
mov dword[IDTR+2], eax

; Load GDTR register
lgdt fword[GDTR]

; Load IDTR register
lidt fword[IDTR]

; Switch to protected mode
mov eax, cr0
or  al , 0x01
mov cr0, eax

jmp far fword[PROT_MODE_PTR]

PROT_MODE_PTR:
PROT_MODE_LA: dd PROT_MODE
              dw 0x8 ; SELECTOR

GDT:
  D_NULL   db 8 dup(0)
  D_CODE   db 0xFF, 0xFF, 0x00, 0x00, 0x00, 10011010b, 11001111b, 0x00
  D_DATA   db 0xFF, 0xFF, 0x00, 0x00, 0x00, 10010010b, 11001111b, 0x00
  D_VIDEO  db 0xFF, 0xFF, 0x40, 0x81, 0x0B, 10010010b, 01000000b, 0x00
  D_CODE16 db 0xFF, 0xFF, 0x00, 0x00, 0x00, 10011010b, 00001111b, 0x00
  GDT_SIZE equ $ - GDT

GDTR:
  dw GDT_SIZE - 1
  dd 0x0

IDT:
  dq 0 ; 0
  dq 0 ; 1
  dq 0 ; 2
  dq 0 ; 3
  dq 0 ; 4
  dq 0 ; 5
  dq 0 ; 6
  dq 0 ; 7
  dq 0 ; 8
  dq 0 ; 9
  dq 0 ; 10
  dq 0 ; 11
  dq 0 ; 12
  dw GP_handler and 0xFFFF, 0x08, 1000111000000000b, GP_handler shr 16; 13
  dq 0 ; 14
  dq 0 ; 15
  dq 0 ; 16
  dq 0 ; 17
  dq 0 ; 18
  dq 0 ; 19
  dq 0 ; 20
  dq 0 ; 21
  dq 0 ; 22
  dq 0 ; 23
  dq 0 ; 24
  dq 0 ; 25
  dq 0 ; 26
  dq 0 ; 27
  dq 0 ; 28
  dq 0 ; 29
  dq 0 ; 30
  dq 0 ; 31
  dq 0 ; 32
  dq 0 ; 33
  dq 0 ; 34
  dw MY_handler and 0xFFFF, 0x08, 1000111000000000b, MY_handler shr 16 ; 35
  dq 0 ; 36
IDT_SIZE equ $ - IDT

IDTR:
  dw IDT_SIZE - 1
  dd 0x0
  
REAL_IDTR:
  dw 0x0
  dd 0x0

use32

GP_handler:
  pop eax ; get error code
iretd

MY_handler:
  pusha

  mov ax , 0x18
  mov es , ax
  mov edi, 0x02

  mov word[es:edi], 0x2030
  add edi, 0x02
  mov word[es:edi], 0x2078
  add edi, 0x02  
  mov word[es:edi], 0x2032
  add edi, 0x02  
  mov word[es:edi], 0x2033 

  popa
iretd

PROT_MODE:
; Save real mode data/code segment to bx
mov bx, ds
mov word[REAL_MODE_PTR+2], bx

; Set data register to data selector
mov ax, 0x10
mov ds, ax

; Set extra data register to video selector
mov ax, 0x18
mov es, ax

; Enable all interrupts
sti

in  al  , 0x70
and al  , 0x7F
out 0x70, al

int 0x23

; Disable all interrupts
cli

in  al  , 0x70
or  al  , 0x80
out 0x70, al

; Jump to 16-bit code
jmp 0x20:next
next:
use16

; Restore IDTR
lidt fword[cs:REAL_IDTR]

; Switch back to real mode
mov eax, cr0
and al, 11111110b
mov cr0, eax

jmp dword[cs:REAL_MODE_PTR]

REAL_MODE_PTR:
dw REAL_MODE
dw 0x00 ; SELECTOR

use16
REAL_MODE:
; Enable all interrupts
sti

in  al  , 0x70
and al  , 0x7F
out 0x70, al

; Wait for input
mov ah, 0x0
int 0x16

; Go back to DOS
int 0x20
