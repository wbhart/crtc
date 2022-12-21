   DOSSEG
   .MODEL small
   .STACK 100h
   .CODE

start:
   cli
   in al, 21h    ; get IMR
   or al, 03h    ; disable IRQ1 and IRQ0
   out 21h, al

   mov dx, 03d8h
   xor al, al    ; mode 0 = blank screen
   out dx, al

   mov dl, 0dah
wait_no_vert_sync:
   in al, dx
   test al, 8
   jnz wait_no_vert_sync

wait_vert_sync:
   in al, dx
   test al, 8
   jz wait_vert_sync

wait_disp_enable:
   in al, dx
   test al, 1
   jz wait_disp_enable

   ; set up CRTC for 2 scanlines of 2 chars = 4 lchars
   ; active inactive inactive inactive
   ; this is the smallest frame the MC6845 allows
   mov dl, 0d4h
   mov ax, 0100h   ; horiz. total = 1(+1)
   out dx, ax

   mov ax, 0101h   ; horiz. disp. = 1
   out dx, ax

   mov ax, 0104h   ; vert. total = 1(+1)
   out dx, ax

   mov ax, 0005h   ; vert. total adj. = 0
   out dx, ax

   mov ax, 0106h   ; vert. disp. = 1
   out dx, ax

   mov ax, 0009h   ; max. scanline addr. = 0 (1 scanline per char)
   out dx, ax

   ; turn off DRAM refresh temporarily
   mov al, 01110000b ; counter 1, LSB/MSB, mode 0, binary
   out 43h, al
   mov al, 01
   out 41h, al   ; LSB = 1
   xor al, al
   out 41h, al   ; MSB = 0

   ; now wait until we are in active lchar

   ; first clear prefetch so each iter. starts in same state
   ; loop is 144 cycles = 27 lchars = 3 mod 4
   mov dl, 0dah
   mov cl, 1
   jmp wait_active_lchar
wait_active_lchar:
   mov al, 1
   div cl
   nop
   nop
   nop
   nop
   nop
   nop
   in al, dx
   test al, 1
   jnz wait_active_lchar

   nop   ; ensure we are in an inactive lchar

   ; now step by 24 lchars - l cycle at a time
   jmp wait_inactive_lchar
wait_inactive_lchar:
   mov al, 1
   mul al
   stc
   nop
   nop
   in al, dx
   test al, 1
   jz lockstep
   jmp wait_inactive_lchar

lockstep:

   ; back to CGA mode 4
   mov dl, 0d8h
   mov al, 0ah
   out dx, al

   mov dl, 0d4h
   mov ax, 3800h   ; horiz. total = 56(+1)
   out dx, ax

   mov ax, 2801h   ; horiz. disp. = 40
   out dx, ax

   mov ax, 2d02h   ; horiz. sync pos. = 45
   out dx, ax
   
   mov ax, 7f04h   ; vert. total = 127(+1)
   out dx, ax

   mov ax, 0605h   ; vert. total adj. = 6
   out dx, ax

   mov ax, 6406h   ; vert. disp. = 100
   out dx, ax

   mov ax, 7007h   ; vert. sync pos. = 112
   out dx, ax

   mov ax, 0109h   ; max. scanline addr. = 1 (2 scanlines per char)
   out dx, ax

   ; set timer for DRAM refresh every scanline = 76 PIT pulses
   mov al, 01110100b ; counter 1, LSB/MSB, mode 2, binary
   out 43h, al
   mov al, 76
   out 41h, al   ; LSB = 76
   xor al, al
   out 41h, al   ; MSB = 0
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

   ; set timer for DRAM refresh every scanline = 16 PIT pulses
   mov al, 01110100b ; counter 1, LSB/MSB, mode 2, binary
   out 43h, al
   mov al, 16
   out 41h, al   ; LSB = 76
   xor al, al
   out 41h, al   ; MSB = 0
   sti

   mov ax, 3     ; back to text mode
   int 10h

   mov ah, 4ch   ; exit to DOS
   int 21h

   END start