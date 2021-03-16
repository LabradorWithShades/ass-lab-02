use16
org 0x100

; Forbid all interrupts
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

; Load GDTR register
lgdt fword[GDTR]

; Save real mode IDTR register
sidt fword[REAL_IDTR]

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
  dw GDT_SIZE
  dd 0x0
  
use32
GP_handler:
  pop eax ; get error code
  pusha
  ; write handler
  popa
iretd

MY_handler:
  ;no error code
  pusha
  popa
iretd

IDT:
  dq 0x0 ; 0
  dq 0x0 ; 1
  dq 0x0 ; 2
  dq 0x0 ; 3
  dq 0x0 ; 4
  dq 0x0 ; 5
  dq 0x0 ; 6
  dq 0x0 ; 7
  dq 0x0 ; 8
  dq 0x0 ; 9
  dq 0x0 ; 10
  dq 0x0 ; 11
  dq 0x0 ; 12
    ; handler    seg   PprZDtypRRRrrrrr   
  dw GP_handler, 0x08, 1000111000000000b, shr GP_handler 16; 13
  dq 0x0 ; 14
  dq 0x0 ; 15
  dq 0x0 ; 16
  dq 0x0 ; 17
  dq 0x0 ; 18
  dq 0x0 ; 19
  dq 0x0 ; 20
  dq 0x0 ; 21
  dq 0x0 ; 22
  dq 0x0 ; 23
  dq 0x0 ; 24
  dq 0x0 ; 25
  dq 0x0 ; 26
  dq 0x0 ; 27
  dq 0x0 ; 28
  dq 0x0 ; 29
  dq 0x0 ; 30
  dq 0x0 ; 31
  dq 0x0 ; 32
  dq 0x0 ; 33
IDT_SIZE: equ $ - IDT

REAL_IDTR:
  dw 0x0
  dd 0x0

IDTR:
  dw IDT_SIZE
  dd 0x0

use32
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

mov esi, 0xFFFFFFF0
xor edi, edi

mov ecx, 0x10
print_loop:
	mov al, byte[ds:esi]
	shr al, 0x04
	and al, 0x0f
	cmp al, 0x0a
	jl out_1
	add al, 0x07
	out_1:
	add al, 0x30
	mov byte[es:edi], al
	inc edi
	mov byte[es:edi], 0x02
	inc edi	

	; Print 2nd digit
	mov al, byte[ds:esi]
	and al, 0x0f
	cmp al, 0x0a
	jl out_2
	add al, 0x07
	out_2:
	add al, 0x30
	mov byte[es:edi], al
	inc edi
	mov byte[es:edi], 0x02
	
	add edi, 0x3
	inc esi
loop print_loop

; Jump to 16-bit code
jmp 0x20:next
next:
use16
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
; Restore idtr register
lidt fword[REAL_IDTR]

; Allow all interrupts
sti

in  al  , 0x70
and al  , 0x7F
out 0x70, al

; Wait for input
mov ah, 0x0
int 0x16

; Go back to DOS
int 0x20
