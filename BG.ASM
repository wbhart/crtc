   DOSSEG
   .MODEL small
   .STACK 100h
   .CODE

start:
   cli
   in al, 21h    ; get IMR
   or al, 03h    ; disable IRQ1 and IRQ0
   out 21h, al

restart:

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

   ; refresh everything

   cld
   xor ax, ax
   mov ds, ax
   mov si, ax

   mov cx, 256

   ; set timer for DRAM refresh every 2 PIT pulses
   mov al, 01100100b ; counter 1, LSB, mode 2, binary
   out 43h, al
   mov al, 2
   out 41h, al   ; LSB = 2
   
   rep lodsw
   
   ; turn off DRAM refresh temporarily
   mov al, 01100000b ; counter 1, LSB, mode 0, binary
   out 43h, al
   mov al, 01
   out 41h, al   ; LSB = 1

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

   ; set timer for DRAM refresh every half scanline = 38 PIT pulses
   mov al, 01100100b ; counter 1, LSB, mode 2, binary
   out 43h, al
   mov al, 38
   out 41h, al   ; LSB = 38
   sti

patch9:
   mov cl, 1
   shl ax, cl
patch7:
   mov al, 080h
   mul al

key_loop:

   mov dx, 03d9h
   mov al, 4
   out dx, al
   xor al, al
   out dx, al

   mov cl, 226
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
patch3:
   mov cl, 1
   shl ax, cl
patch1:
   mov al, 080h
   mul al
   stc
   stc

   mov al, 0ah
   out 20h, al
   in al, 20h    ; get IRR
   test al, 02h  ; check if IRQ1
   jnz key_pressed

no_key:

   mov cl, 226
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
   shl ax, cl
patch6:
   mov cl, 223
   shl ax, cl
patch4:
   mov al, 0feh
   mul al

   jmp key_loop

key_pressed:

   ; set timer for DRAM refresh every scanline = 18 PIT pulses
   mov al, 01100100b ; counter 1, LSB, mode 2, binary
   out 43h, al
   mov al, 18
   out 41h, al   ; LSB = 18

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

   cmp dl, 17
   jne skip_inc1
patch2:
   mov cl, 1
   add byte ptr cs:[patch2+1], 1
   mov al, 080h
   sar al, cl
   mov byte ptr cs:[patch1+1], al

skip_inc1:

   cmp dl, 18
   jne skip_inc2
patch5:
   mov cl, 1
   add byte ptr cs:[patch5+1], 1
   mov al, 0feh
   shl al, cl
   mov byte ptr cs:[patch4+1], al

skip_inc2:

   cmp dl, 19
   jne skip_inc3
   add byte ptr cs:[patch3+1], 1

skip_inc3:
   cmp dl, 20
   jne skip_inc4
   sub byte ptr cs:[patch6+1], 1

skip_inc4:

   cmp dl, 21
   jne skip_inc5
patch8:
   mov cl, 1
   add byte ptr cs:[patch8+1], 1
   mov al, 080h
   sar al, cl
   mov byte ptr cs:[patch7+1], al

skip_inc5:
   cmp dl, 22
   jne skip_inc6
   add byte ptr cs:[patch9+1], 1

skip_inc6:

release:

   jmp restart

exit:
   cli

   in al, 21h    ; get IMR
   and al, 0fch  ; enable IRQ1 amd IRQ0
   out 21h, al

   sti

   mov ax, 3     ; back to text mode
   int 10h

   mov ah, 4ch   ; exit to DOS
   int 21h

   END start