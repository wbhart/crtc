   DOSSEG
   .MODEL small
   .STACK 100h
   .DATA

   BANK1  DB 256 DUP(?)
   BANK2  DB 256 DUP(?)
   BANK3  DB 256 DUP(?)
   BANK4  DB 256 DUP(?)
   BANK5  DB 256 DUP(?)
   BANK6  DB 256 DUP(?)
   BANK7  DB 256 DUP(?)
   BANK8  DB 256 DUP(?)
   BANK9  DB 256 DUP(?)
   BANK10 DB 256 DUP(?)

   .CODE

   HORDISP_MAX EQU 0   ; start addr low initial value
   HORDISP_MIN EQU 1   ; what addr low is set to

   BIGDELAY    EQU 216 ; big delay used in main loop (x4 for cycles)
                       ; this can be reduced if there aren't enough
                       ; cycles in the main loop to insert the desired
                       ; register writes

fill1 macro
   local fill1_loop
   ; fill screen with pattern 12321232 on even lines
   ; blank odd lines
   mov ax, 0b800h
   mov es, ax
   mov cx, 1024
fill1_loop:
   mov ax, 4444h
   stosw
   mov ax, 08888h
   stosw
   mov ax, 0cccch
   stosw
   mov ax, 08888h
   stosw
   loop fill1_loop
   mov cx, 4096
   xor ax, ax
   rep stosw
   endm

fill2 macro
   local fill2_loop
   ; fill screen with pattern 12321232
   xor di, di
   mov ax, 0b800h
   mov es, ax
   mov cx, 2048
fill2_loop:
   mov ax, 5555h
   stosw
   mov ax, 0aaaah
   stosw
   mov ax, 0ffffh
   stosw
   mov ax, 0aaaah
   stosw
   loop fill2_loop
   mov di, 400
   mov bx, 19
   xor ax, ax
fill_loop2:
   mov cx, 40
   rep stosw
   add di, 320
   dec bx
   jnz fill_loop2
   endm

_refresh PROC
   DB 09ah         ; call far
   DW 0h, 0h
   DB 09ah         ; call far
   DW 100h, 1000h
   DB 09ah         ; call far
   DW 0h, 2000h
   DB 09ah         ; call far
   DW 100h, 3000h
   DB 09ah         ; call far
   DW 0h, 4000h
   DB 09ah         ; call far
   DW 100h, 5000h
   DB 09ah         ; call far
   DW 0h, 6000h
   DB 09ah         ; call far
   DW 100h, 7000h
   DB 09ah         ; call far
   DW 0h, 8000h
   DB 09ah         ; call far
   DW 100h, 9000h
   ret
_refresh ENDP

start:
   xor di, di
   fill1

   cli

   ; save 256 bytes out of each 64kb "bank"
   ; alternate 0, 256 mod 512 to handle 4164 and 41256 chips

   mov bx, @data
   mov es, bx
   xor bx, bx
   mov ds, bx

   mov di, offset BANK1
   xor si, si

   rept 10
   mov cx, 128
   rep movsw
   and si, 01ffh   ; mod 512
   add bx, 4096   ; 64kb / 16
   mov ds, bx
   endm
   
   xor bx, bx
   mov es, bx
   xor di, di

   ; write 255 NOPs and a RETF in each bank
   rept 10
   mov al, 90h    ; NOP
   mov cx, 255
   rep stosb
   mov al, 0cbh   ; RETF
   stosb
   and di, 01ffh  ; mod 512
   add bx, 4096   ; 64kb / 16
   mov es, bx
   endm

   ; disable individual interrupts
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
   mov ax, 0300h   ; horiz. total = 1(+1)
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

   mov cx, 512

   ; set timer for DRAM refresh every 2 PIT pulses
   mov al, 01100100b ; counter 1, LSB, mode 2, binary
   out 43h, al
   mov al, 2
   out 41h, al   ; LSB = 2
   
   rep lodsw
   
   ; turn off DRAM refresh
   mov al, 01100010b ; counter 1, LSB, mode 0, binary
   out 43h, al
   mov al, 01
   out 41h, al   ; LSB = 1

   ; Reenigne's lockstep

;   mov ax, 0b800h
;   mov es, ax
;   mov ds, ax
;   mov di, 03ffch
;   mov si, di
;   mov ax, 0303h
;   stosw
;   mov al, 0h
;   stosb

   mov dl, 0dah

   mov cl, 1

;   jmp clear_prefetch
;clear_prefetch:

;   mov al, 0
;   mul cl
;   lodsb
;   mul cl
;   nop
;   lodsb
;   mul cl
;   nop
;   lodsb
;   mul cl
   
   ; wait until we are in active lchar

   ; first clear prefetch so each iter. starts in same state
   ; loop is 144 cycles = 27 lchars = 3 mod 4
   mov ax, 1
   test al, 1
   jnz wait_active_lchar
wait_active_lchar:
   mov al, 1
   div cl

   rept 6
   nop
   endm
 
   in al, dx
   test al, 1
   jnz wait_active_lchar

   nop   ; ensure we are in an inactive lchar

   ; now step by 16 lchars - l cycle at a time
   jmp wait_inactive_lchar
wait_inactive_lchar:
   mov al, 4
   shl ax, cl
   nop
   nop
   nop
   nop
   in al, dx
   test al, 1
   jz lockstep
   jmp wait_inactive_lchar

lockstep:

   ; set hdot phase to 0, 1 or 2

hdot_phase:
   mov bx, 7

   jmp wait_phase
wait_phase:
   mov cl, 5
   shl ax, cl
   cwd
   jno waste_time
waste_time:
   dec bx
   jnz wait_phase

   mov al, 80h
   mul al

   ; back to CGA mode 4
   mov dx, 03d8h
   mov al, 0ah
   out dx, al

   mov dl, 0d4h
   mov ax, 3800h   ; horiz. total = 56(+1)
   out dx, ax

   mov ax, 2801h   ; horiz. disp. = 40
   out dx, ax

   mov ax, 2d02h   ; horiz. sync pos. = 45
   out dx, ax
   
   mov ax, 3f04h   ; vert. total = 63(+1)
   out dx, ax

   mov ax, 0305h   ; vert. total adj. = 3
   out dx, ax

   mov ax, 2206h   ; vert. disp. = 34
   out dx, ax

   mov ax, 2e07h   ; vert. sync pos. = 46
   out dx, ax

   mov ax, 0109h   ; max. scanline addr. = 1 (2 scanlines per char)
   out dx, ax

   call _refresh   ; refresh dram and align with start of next frame
   call _refresh
   call _refresh
   call _refresh
   call _refresh
   call _refresh
   call _refresh

scanline_count:
   mov bx, 9
scanline_loop:
   mov cl, 66
   shl ax, cl
   dec bx
   jnz scanline_loop

patch9:
   mov cl, 18
   shl ax, cl
patch7:
   mov al, 0c0h
   mul al
   mov dx, 03d9h

key_loop:

patcha:
   mov dl, 0d9h
patchb:
   mov al, 0ch
   out dx, al
patchc:
   mov dl, 0d9h
patchd:
   mov al, 08h
   out dx, al

   mov dl, 0d4h
   mov al, 07h
   out dx, al
   mov dl, 0d5h
   mov al, 07fh
   out dx, al

   mov dl, 0d4h
   mov al, 01h
   out dx, al
   mov dl, 0d5h
   mov al, 039h
   out dx, al

   mov cl, BIGDELAY

   call _refresh
   
   rept 10
   shl ax, cl
   endm

   call _refresh

   rept 9
   shl ax, cl
   endm

patch3:
   mov cl, 201
   shl ax, cl
patch1:
   mov al, 0f8h
   mul al

patche:
   mov dl, 0d9h
patchf:
   mov al, 0ch
   out dx, al
patchg:
   mov dl, 0d9h
patchh:
   mov al, 08h
   out dx, al

   mov dl, 0d4h
   mov al, 07h
   out dx, al
   mov dl, 0d5h
   mov al, 02eh
   out dx, al

   mov dl, 0d4h
   mov al, 01h
   out dx, al
   mov dl, 0d5h
   mov al, 028h
   out dx, al

   mov al, 0ah
   out 20h, al
   in al, 20h    ; get IRR
   test al, 02h  ; check if IRQ1
   jz no_key
   jmp key_pressed
no_key:

   mov cl, BIGDELAY
   
   call _refresh
   
   rept 10
   shl ax, cl
   endm

   call _refresh

   rept 9
   shl ax, cl
   endm

   mov cl, 178
   shl ax, cl
   mov al, 0f8h
   mul al

   jmp key_loop

key_pressed:

   call _refresh

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
   jnc no_release
   jmp release
no_release:
   shr dl, 1

   cmp dl, 16    ; q = quit
   jne no_exit
   jmp exit
no_exit:

   cmp dl, 17    ; w = pad main loop with additional cycle
   jne skip_inc1
   mov al, byte ptr cs:[patch2+1]
   inc al
   cmp al, 5
   jne patch2_noinc4
   mov al, 1
   inc byte ptr cs:[patch3+1]
patch2_noinc4:
   mov byte ptr cs:[patch2+1], al
   mov al, 080h
   nop
patch2:
   mov cl, 4
   sar al, cl
   mov byte ptr cs:[patch1+1], al
skip_inc1:

   cmp dl, 18    ; e = increment scanline
   jne skip_inc1a
   inc word ptr cs:[scanline_count+1]

skip_inc1a:
   cmp dl, 19    ; r = pad main loop with additional 4 cycles
   jne skip_inc2
   inc byte ptr cs:[patch3+1]

skip_inc2:

   cmp dl, 20   ; t = increment initial hdisp value
   jne skip_inc3
   inc byte ptr cs:[hichar+1]

   cmp byte ptr cs:[mode], 1
   je visual

skip_inc3:

   cmp dl, 21   ; y = move register write later by 1 hdot
   jne skip_inc5

   mov bl, byte ptr cs:[hdot_phase+1]
   dec bl
   cmp bl, 4
   jne no_reset_phase
   mov bl, 7
   mov al, byte ptr cs:[patch8+1]
   inc al
   cmp al, 5
   jne patch8_noinc4
   mov al, 1
   inc byte ptr cs:[patch9+1]
patch8_noinc4:
   mov byte ptr cs:[patch8+1], al
   mov al, 080h
   nop
patch8:
   mov cl, 1
   sar al, cl
   mov byte ptr cs:[patch7+1], al
no_reset_phase:
   mov byte ptr cs:[hdot_phase+1], bl


skip_inc5:
   cmp dl, 22   ; u = move register write later by 4 cycles
   jne skip_inc6
   inc byte ptr cs:[patch9+1]

skip_inc6:

   cmp dl, 24   ; o = increment value hdisp is set to
   jne skip_inc8

   inc byte ptr cs:[lochar+1]

   cmp byte ptr cs:[mode], 1
   je visual

skip_inc8:

   cmp dl, 23   ; i = switch to visual output
   jne skip_inc7

   mov byte ptr cs:[mode], 1    ; simply for keeping track of mode

visual:
   mov al, 0d4h
   mov byte ptr cs:[patcha+1], al
   mov byte ptr cs:[patche+1], al
   mov al, 0d5h
   mov byte ptr cs:[patchc+1], al
   mov byte ptr cs:[patchg+1], al
   mov al, 0dh
   mov byte ptr cs:[patchb+1], al
   mov byte ptr cs:[patchf+1], al
lochar:
   mov al, HORDISP_MIN
   mov byte ptr cs:[patchd+1], al
hichar:
   mov al, HORDISP_MAX
   mov byte ptr cs:[patchh+1], al

   fill2

skip_inc7:

   cmp dl, 25   ; p = move register write earlier by 1 cycle
   jne skip_inc9

   mov bl, byte ptr cs:[hdot_phase+1]
   inc bl
   cmp bl, 8
   jne no_reset_phase2
   mov bl, 5
   mov cl, byte ptr cs:[patch8+1]
   dec cl
   jnz patch8_nodec4
   mov cl, 4
   dec byte ptr cs:[patch9+1]
patch8_nodec4:
   mov byte ptr cs:[patch8+1], cl
   mov al, 080h
   sar al, cl
   mov byte ptr cs:[patch7+1], al
no_reset_phase2:
   mov byte ptr cs:[hdot_phase+1], bl

skip_inc9:
   cmp dl, 26   ; [ = move register write earlier by 4 cycles
   jne skip_inc10
   dec byte ptr cs:[patch9+1]

skip_inc10:

   cmp dl, 30   ; a = toggle fill pattern
   jne skip_inc12
   xor word ptr cs:[fill_addr+1], 2000h
   cmp byte ptr cs:[mode], 1
   je skip_inc12
   jmp fill_addr

skip_inc12:

   cmp dl, 27   ; ] = switch back to grid mode
   jne skip_inc11

   mov byte ptr cs:[mode], 0 ; keep track of mode

   mov al, 0d9h
   mov byte ptr cs:[patcha+1], al
   mov byte ptr cs:[patche+1], al
   mov byte ptr cs:[patchc+1], al
   mov byte ptr cs:[patchg+1], al
   mov al, 0ch
   mov byte ptr cs:[patchb+1], al
   mov byte ptr cs:[patchf+1], al
   mov al, 08h
   mov byte ptr cs:[patchd+1], al
   mov byte ptr cs:[patchh+1], al

fill_addr:
   mov di, 0000h
   fill1

skip_inc11:

release:

   jmp restart

exit:
   cli

   ; restore 256 bytes out of each 64kb "bank"
   ; alternate 0, 256 mod 512 to handle 4164 and 41256 chips

   mov ax, @data
   mov ds, ax
   xor ax, ax
   mov es, ax

   mov si, offset BANK1
   xor di, di

   rept 10
   mov cx, 128
   rep movsw
   and di, 01ffh   ; mod 512
   add ax, 4096   ; 64kb / 16
   mov es, ax
   endm

   ; turn on individual interrupts
   in al, 21h    ; get IMR
   and al, 0fch  ; enable IRQ1 amd IRQ0
   out 21h, al

   sti

   mov ax, 3     ; back to text mode
   int 10h

   mov ah, 4ch   ; exit to DOS
   int 21h

mode:
   DB 0

   END start
