;
; Names of supported controllers
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
.include "global.inc"
.export draw_controller_name

.rodata
; order must correspond to TYPE_* constants in global.inc
controller_names:
  .addr nes_name, dogbone_name
  .addr fc_i_name, fc_ii_name
  .addr fourscore_name, zapper_name
  .addr nesvaus_name, powerpad_name
  .addr snes_name, mouse_name

.assert * = controller_names + 2 * NUM_PADNAMES, error, "wrong short description count for NUM_PADNAMES"

; Each controller has 3 lines of text, each up to 13 characters.
; Lines 1 and 2 describe the controller; line 3 asks to press
; a button to test that controller.
nes_name:       .byte "NES",LF,"Controller",LF,"Press A",0
dogbone_name:   .byte "NES Dogbone",LF,"Controller",LF,"Press A",0
fc_i_name:      .byte "Famicom",LF,"Controller",LF,"Press A",0
fc_ii_name:     .byte "Famicom Mic",LF,"Controller",LF,"Press A",0
fourscore_name: .byte "Four Score/",LF,"Satellite",LF,"Press 1:A",0
zapper_name:    .byte "Zapper",LF,LF,"Pull trigger",0
nesvaus_name:   .byte "NES Arkanoid",LF,"Controller",LF,"Press Fire",0
powerpad_name:  .byte "Power Pad",LF,LF,"Press 4",0
snes_name:      .byte "Super NES",LF,"Controller",LF,"Press B",0
mouse_name:     .byte "Super NES",LF,"Mouse",LF,"Press Left",0

.code
CONTROLLER_NAME_X = 144

;;
; @param A controller type
; @param Y vertical position in 16-pixel increments
; @param $04 number of text lines to draw (2 or 3)
.proc draw_controller_name
dstlo = $02
numlines = $04
  asl a
  tax
  jsr seek_nt_line_y
  ora #CONTROLLER_NAME_X >> 3
  sta dstlo
  lda controller_names+1,x
  ldy controller_names+0,x
  jmp puts_multiline_16
.endproc

BITS_NAME_X = 16
;;
; @param A controller bits
; @param Y vertical position in 16-pixel increments
.proc draw_controller_bits
controller_bits = $00
dstlo = $02
numlines = $04
  sta controller_bits
  jsr seek_nt_line_y
  ora #BITS_NAME_X >> 3
  sta dstlo
  lda #2
  sta numlines
  lsr a
  and controller_bits
  adc #'1'
  ldx #0
  sta PB53_outbuf,x

  ; port bits 10 means both ports 1 and 2
  lda controller_bits
  and #$02
  beq not_1and2
    inx
    lda #'-'
    sta PB53_outbuf,x
    inx
    lda #'2'
    sta PB53_outbuf,x
  not_1and2:
  
  lda #'P'
  sta PB53_outbuf+1,x
  lda #LF
  sta PB53_outbuf+2,x
  lda #' '
  sta PB53_outbuf+3,x

  ; Draw highest bit number
  lda #'D'
  sta PB53_outbuf+4,x
  lda controller_bits
  and #$E0
  asl a
  rol a
  rol a
  rol a
  ora #'0'
  sta PB53_outbuf+5,x

  ; Draw lowest bit number only if it differs
  lda controller_bits
  asl a
  asl a
  asl a
  eor controller_bits
  and #$E0
  beq not_range
    inx
    lda #'-'
    sta PB53_outbuf+5,x
    inx
    lda controller_bits
    and #$1C
    lsr a
    lsr a
    ora #'0'
    sta PB53_outbuf+5,x
  not_range:
  lda #0
  sta PB53_outbuf+6,x

  lda #>PB53_outbuf
  ldy #<PB53_outbuf
  jmp puts_multiline_16
  rts
.endproc
