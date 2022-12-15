   DOSSEG
   .MODEL small
   .STACK 100h
   .CODE

start:
   cli
   in al, 21h    ; get IMR
   or al, 03h    ; disable IRQ1 and IRQ0
   out 21h, al
   sti

key_loop:
   mov al, 0ah
   out 20h, al
   in al, 20h    ; get IRR
   test al, 0fch ; if some other interrupt fires, quit
   jnz exit
   test al, 02h  ; check if IRQ1
   jz key_loop

   in al, 60h    ; read keyboard buffer
   mov dl, al

   in al, 61h    ; get system crtl port
   mov ah, al
   or al, 80h    ; reset keyboard
   out 61h, al
   mov al, ah    ; rewrite original byte
   out 61h, al

   mov al, 20h
   out 20h, al   ; EOI

   shl dl, 1     ; ignore key release
   jc release
   shr dl, 1

   cmp dl, 16    ; q = quit
   je exit

   mov ah, 02h   ; print char
   int 21h

release:

   jmp key_loop

exit:
   cli
   in al, 21h    ; get IMR
   and al, 0fch  ; enable IRQ1 amd IRQ0
   out 21h, al
   sti

   mov ah, 4ch   ; exit to DOS
   int 21h

   END start