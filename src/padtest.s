;
; Tests for digital controllers (NES/FC, SNES, Four Score, Power Pad)
;
; Copyright 2016 Damian Yerrick
;
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;
.include "nes.inc"
.include "global.inc"

.bss
selected_pad: .res 1
padtestdata: .res SIZEOF_PADTESTDATA

; Press A (or B or 4 or whatever) to start test ;;;;;;;;;;;;;;;;;;;;;

.code
;;
; Return nonzero iff the primary button (A on NES controller, 1:A on
; Four Score, B on Super NES controller, or LMB of a Super NES Mouse)
; is held.
; @param X index in ident array
; @return $00=Y=port ID (0 or 1), $01=X=input X,
; A=nonzero iff pressed, Z=0 (NE) iff pressed
.proc pads_check_first_button
portnum  = $00
padindex = $01

  stx padindex

  lda #1
  sta $4016
  lsr a
  sta $4016
  
  ; Calculate the port number
  lda ident_bits,x
  and #$01
  sta portnum

  ; All controllers other than the Super NES Mouse return pressed
  ; status on the first read.  The mouse returns it on the tenth.
  ldy ident_type,x
  cpy #TYPE_SNES_MOUSE
  bne not_mouse
    ldx #9
    ldy portnum
    seek_to_lmb_loop:
      lda $4016,y
      dex
      bne seek_to_lmb_loop
    ldx padindex
  not_mouse:

  ; Calculate the mask for the button:
  ; Either D0 or the non-D0 bit associated with this controller type
  lda ident_bits,x
  and #$1C
  beq is_d0
    ldy ident_type,x
    lda non_d0_button_mask,y
    bne have_mask
  is_d0:
    lda #1
  have_mask:

  ; Read the first bit from that port
  ldy portnum
  and $4016,y
  rts
.endproc


.rodata
non_d0_button_mask:
  .byte 1<<1, 1<<1
  .byte 1<<1, 1<<1
  .byte 1<<1, 1<<4  ; Four Score (1:A), Zapper (trigger)
  .byte 1<<3, 1<<4  ; Arkanoid (fire), Power Pad (4)
  .byte 1<<1, 1<<1  ; Super NES Controller, Super NES Mouse

; Backgrounds ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
; @param selected_pad which controller's port
; @param Y destination address in top 4 rows of nametable
; ($02-$1D, $42-$5D, $82-$9D, $C2-$DD)
.proc draw_port_number
  ldx selected_pad
  lda ident_bits,x
  and #$01
  clc
  adc #'1'
  tax
  lda #$20
  jmp draw_1_char
.endproc

;;
; @param selected_pad which controller's port
; @param Y destination address in top 4 rows of nametable
; ($02-$1D, $42-$5D, $82-$9D, $C2-$DD)
.proc draw_bit_number
  ldx selected_pad
  lda ident_bits,x
  and #$1C
  lsr a
  lsr a
  ora #'0'
  tax
  lda #$20
  jmp draw_1_char
.endproc

.rodata
nes_pad_screen:
  .byte "NES Controller",LF
  .byte "on  P D",LF
  .byte "",LF
  .byte "  Up        A",LF
  .byte "  Down      B",LF
  .byte "  Left      Select",LF
  .byte "  Right     Start",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "Reset: Exit",0

fc_mic_pad_screen:
  .byte "Famicom Mic Controller",LF
  .byte "on 2P D0 and 1P D2",LF
  .byte "",LF
  .byte "  Up        A",LF
  .byte "  Down      B",LF
  .byte "  Left      Mic",LF
  .byte "  Right",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "Reset: Exit",0

snes_pad_screen:
  .byte "Super NES Controller",LF
  .byte "on  P D",LF
  .byte "",LF
  .byte "  L         R",LF
  .byte "  Up        X",LF
  .byte "  Down      B",LF
  .byte "  Left      Y",LF
  .byte "  Right     A",LF
  .byte "  Select    Start",LF
  .byte "",LF
  .byte "",LF
  .byte "Reset: Exit",0

four_score_screen:
  .byte "Four Score on 1-2P D",LF
  .byte "         1P  2P  3P  4P",LF
  .byte "A",LF
  .byte "B",LF
  .byte "Select",LF
  .byte "Start",LF
  .byte "Up",LF
  .byte "Down",LF
  .byte "Left",LF
  .byte "Right",LF
  .byte "",LF
  .byte "Reset: Exit",0

power_pad_screen:
  .byte "Power Pad on  P",LF
  .byte "",LF
  .byte "  1   2   3   4",LF
  .byte "  5   6   7   8",LF
  .byte "  9   10  11  12",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "Reset: Exit",0

; Light circles for pressed buttons ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.code

;;
; 
.proc draw_buttoncircles
src = $00
  sta src+1
  sty src
  ldx #0
  jsr ppu_clear_oam
  ldy #0
  loop:
    lda (src),y
    cmp #248
    bcs done
    sta OAM+3,x
    iny
    lda (src),y
    iny
    sta OAM+0,x
    lda #$FE
    sta OAM+1,x
    lda #$00
    sta OAM+2,x
    txa
    adc #4
    tax
    bne loop
  done:
  rts
.endproc

.proc draw_buttoncircles_chr_palette
  jsr draw_buttoncircles

  ; Load dot palette
  lda #$3F
  sta PPUADDR
  ldx #$11
  stx PPUADDR
  ldx #0
  :
    lda sprcircle_palette,x
    sta PPUDATA
    inx
    cpx #7
    bcc :-

  ; Load dot sprite
  lda #$0F
  sta PPUADDR
  lda #$E0
  sta PPUADDR
  lda #>sprcircle16_chr_pb53
  sta ciSrc+1
  lda #<sprcircle16_chr_pb53
  sta ciSrc+0
  ldx #2
  jmp unpb53_xtiles
.endproc

.proc load_halfcircle_chr
  ; Load dot sprite
  lda #$0C
  sta PPUADDR
  lda #$80
  sta PPUADDR
  lda #>halfcircle16_chr_pb53
  sta ciSrc+1
  lda #<halfcircle16_chr_pb53
  sta ciSrc+0
  ldx #2
  jmp unpb53_xtiles
.endproc

;;
; @param Y number of half circles to color
.proc color_buttoncircles
buttoncircles_left = $00

  sty buttoncircles_left
  lda #$80  ; A: bits left
  ldx #$00  ; X: index into OAM
  ldy #$00  ; Y: index into padtestdata
  hcloop:
    asl a
    bne :+
      lda padtestdata,y
      iny
      rol a
    :
    pha
    lda #0
    rol a
    sta OAM+2,x
    inx
    inx
    inx
    inx
    pla
    dec buttoncircles_left
    bne hcloop
  rts
  
.endproc

.rodata
sprcircle16_chr_pb53: .incbin "obj/nes/sprcircle16.chr.pb53"
halfcircle16_chr_pb53: .incbin "obj/nes/halfcircle16.chr.pb53"
sprcircle_palette: .byte $08,$00,$0F,$0F,$00,$10,$16

nes_pad_buttoncircles:
  .byte 112, 71, 112, 87, 112,103, 112,119
  .byte  32, 71,  32, 87,  32,103,  32,119
  .byte 255
fc_mic_pad_buttoncircles:
  .byte 112, 71, 112, 87, 240,240, 240,240
  .byte  32, 71,  32, 87,  32,103,  32,119
  .byte 112,103, 255
snes_pad_buttoncircles:
  .byte 112,103, 112,119,  32,151, 112,151
  .byte  32, 87,  32,103,  32,119,  32,135
  .byte 112,135, 112, 87,  32, 73, 112, 73
  .byte 255
four_score_buttoncircles:
  .byte 112, 55, 112, 71, 112, 87, 112,103
  .byte 112,119, 112,135, 112,151, 112,167
  .byte 176, 55, 176, 71, 176, 87, 176,103
  .byte 176,119, 176,135, 176,151, 176,167
  .byte 240,240, 240,240, 240,240, 112,183
  .byte 240,240, 240,240, 240,240, 240,240
  .byte 144, 55, 144, 71, 144, 87, 144,103
  .byte 144,119, 144,135, 144,151, 144,167
  .byte 208, 55, 208, 71, 208, 87, 208,103
  .byte 208,119, 208,135, 208,151, 208,167
  .byte 240,240, 240,240, 144,183, 240,240
  .byte 255
power_pad_buttoncircles:
  ; order: 2, 1, 5, 9, 6, 10, 11, 7, 4, 3, 12, 8
  .byte  70, 55,  38, 55,  38, 71,  38, 87
  .byte  70, 71,  70, 87, 102, 87, 102, 71
  .byte 134, 55, 102, 55, 134, 87, 134, 71
  .byte 255

; Controller kernel ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.code
;;
; Gets the port number and mask of a D0/D1 device.
; @param selected_pad the index into ident_*
; @return Y: the index ($00 or $01); A: the mask ($01 or $02)
.proc get_selected_portnum_mask_d0ord1
  ldy selected_pad
  lda ident_bits,y
  cmp #$04
  and #$01
  tay
  lda #1
  adc #0
  rts
.endproc

;;
; Reads bytes from one serial line.
; (Not suitable for Power Pad which returns 2 bits per read.)
; @param A mask bit
; @param Y port number
; @param X number of bytes
.proc read_serial_bytes
num_bytes = $00
mask_bit  = $01

  stx num_bytes
  sta mask_bit
  ; Clear out bytes first
  lda #1
  clearloop:
    sta padtestdata-1,x
    dex
    bne clearloop

  readloop:
    lda mask_bit
    and $4016,y
    cmp #1
    rol padtestdata,x
    bcc readloop
    inx
    cpx num_bytes
    bne readloop
  rts
.endproc

;;
; Reads bytes from one Power Pad or NES Arkanoid Controller
; (Not suitable for Power Pad which returns 2 bits per read.)
; @param Y port number
; @return padtestdata+0: bit 3; padtestdata+1: bit 4
.proc read_power_pad
mask_bit  = $01
  lda #1
  sta padtestdata+1
  loop:
    lda $4016,y
    lsr a
    lsr a
    lsr a
    lsr a
    rol padtestdata+0  ; 2, 1, 5, 9, 6, 10, 11, 7
    lsr a
    rol padtestdata+1  ; 4, 3, 12, 8, H, H, H, H
    bcc loop
  rts
.endproc

; Standard controller test ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.code


.proc snes_controller_test
  ldx #4
  lda #>snes_pad_screen
  ldy #<snes_pad_screen
  jsr cls_puts_multiline_x
  lda #>snes_pad_buttoncircles
  ldy #<snes_pad_buttoncircles
  jsr draw_buttoncircles_chr_palette
  ldy #$47
  jsr draw_port_number
  ldy #$4B
  jsr draw_bit_number

forever:
  lda #1
  sta $4016
  lsr a
  sta $4016

  ; Get the mask (D0 or D1)
  jsr get_selected_portnum_mask_d0ord1
  ldx #2
  jsr read_serial_bytes
  ldy #12
  jsr color_buttoncircles
  jsr present

  jmp forever
.endproc

.proc nes_controller_test
  ldx #4
  lda #>nes_pad_screen
  ldy #<nes_pad_screen
  jsr cls_puts_multiline_x
  lda #>nes_pad_buttoncircles
  ldy #<nes_pad_buttoncircles
  jsr draw_buttoncircles_chr_palette
  ldy #$47
  jsr draw_port_number
  ldy #$4B
  jsr draw_bit_number
  

forever:
  lda #1
  sta $4016
  lsr a
  sta $4016

  ; Get the mask (D0 or D1)
  jsr get_selected_portnum_mask_d0ord1
  ldx #1
  jsr read_serial_bytes
  ldy #8
  jsr color_buttoncircles
  jsr present

  jmp forever
.endproc

.proc fc_mic_controller_test
  ldx #4
  lda #>fc_mic_pad_screen
  ldy #<fc_mic_pad_screen
  jsr cls_puts_multiline_x
  lda #>fc_mic_pad_buttoncircles
  ldy #<fc_mic_pad_buttoncircles
  jsr draw_buttoncircles_chr_palette
  ldy #$47
  jsr draw_port_number
  ldy #$4B
  jsr draw_bit_number

forever:
  lda #1
  sta $4016
  lsr a
  sta $4016

  ; Get the mask (D0 or D1)
  jsr get_selected_portnum_mask_d0ord1
  ldx #1
  jsr read_serial_bytes

  ; If this is an AV Famicom, the player will be able to press
  ; Select or Start, so switch to the test screen for the dogbone.
  lda padtestdata+0
  and #KEY_SELECT|KEY_START
  beq select_start_not_pressed
    jmp nes_controller_test
  select_start_not_pressed:

  ; Otherwise, read the mic
  lda $4016
  and #$04
  cmp #$01
  ror padtestdata+1
  ldy #9
  jsr color_buttoncircles
  jsr present

  jmp forever
.endproc

.proc four_score_test
  ldx #4
  lda #>four_score_screen
  ldy #<four_score_screen
  jsr cls_puts_multiline_x
  lda #>four_score_buttoncircles
  ldy #<four_score_buttoncircles
  jsr draw_buttoncircles_chr_palette
  ldy #$18
  jsr draw_bit_number

forever:
  lda #1
  sta $4016
  lsr a
  sta $4016

  ; read controller 2 and 4
  jsr get_selected_portnum_mask_d0ord1
  ldx #3
  ldy #1
  jsr read_serial_bytes
  ldx #2
  :
    lda padtestdata,x
    sta padtestdata+3,x
    dex
    bpl :-

  ; read controller 1 and 3
  jsr get_selected_portnum_mask_d0ord1
  ldx #3
  jsr read_serial_bytes
  
  ldy #44
  jsr color_buttoncircles
  jsr present

  jmp forever
.endproc

.proc power_pad_test
  ldx #4
  lda #>power_pad_screen
  ldy #<power_pad_screen
  jsr cls_puts_multiline_x
  lda #>power_pad_buttoncircles
  ldy #<power_pad_buttoncircles
  jsr draw_buttoncircles_chr_palette
  ldy #$11
  jsr draw_port_number

forever:
  lda #1
  sta $4016
  lsr a
  sta $4016

  ; Get the mask (D0 or D1)
  jsr get_selected_portnum_mask_d0ord1
  jsr read_power_pad

  lda padtestdata+0
  sta $5555
  ldy #12
  jsr color_buttoncircles
  jsr present

  jmp forever
.endproc

.proc clear_padtestdata
  ldx #15
  lda #0
  :
    sta padtestdata,x
    dex
    bpl :-
  rts
.endproc
