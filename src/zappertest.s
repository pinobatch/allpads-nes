;
; Zapper test program, corresponding to "Y COORD 1 GUN" and
; "TRIGGER TIME" activities in Zap Ruder
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

.align 128
.code
;;
; @param Y total number of lines to wait
; @param X which port to read (0 or 1)
; @return $0000=number of lines off, $0001=number of lines on
.proc zapkernel_yonoff_ntsc
off_lines = 0
on_lines = 1
subcycle = 2
DEBUG_THIS = 0
  lda #0
  sta off_lines
  sta on_lines
  sta subcycle

; Wait for photosensor to turn ON
lineloop_on:
  ; 8
  lda #$08
  and $4016,x
  beq hit_on

  ; 72
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12

  ; 11
  lda off_lines
  and #LIGHTGRAY
  ora #BG_ON|OBJ_ON
.if DEBUG_THIS
  sta PPUMASK
.else
  bit $0100
.endif

  ; 12.67
  clc
  lda subcycle
  adc #$AA
  sta subcycle
  bcs :+
:

  ; 10
  inc off_lines
  dey
  bne lineloop_on
  jmp bail

; Wait for photosensor to turn ON
lineloop_off:
  ; 8
  lda #$08
  and $4016,x
  bne hit_off

hit_on:
  ; 72
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12
  jsr waste_12

  ; 11
  lda off_lines
  and #LIGHTGRAY
  ora #BG_ON|OBJ_ON
.if DEBUG_THIS
  sta PPUMASK
.else
  bit $0100
.endif

  ; 12.67
  clc
  lda subcycle
  adc #$AA
  sta subcycle
  bcs :+
:

  ; 10
  inc on_lines
  dey
  bne lineloop_off

hit_off:
bail:
waste_12:
  rts
.endproc

.rodata

zapper_screen:
  .byte "Zapper",LF
  .byte "on  P",LF
  .byte "",LF
  .byte "Light Y",LF
  .byte "",LF
  .byte "Height",LF
  .byte "",LF
  .byte "PullTime",LF
  .byte "",LF
  .byte "",LF
  .byte "Reset:",LF
  .byte "    Exit",0
  
zapper_buttoncircles:
  .byte ZAPPER_S0_X, 7
  .byte 216, 20
  .byte 216, 40
  .byte 255

circlepal_on_white:
  .byte $32,$10,$20,$20,$10,$00,$16
.code

ZAPPER_S0_X = 128
light_y = padtestdata+1
light_height = padtestdata+2
pulled_last_frame = padtestdata+3
pull_time = padtestdata+4

light_y_dest      = NTXY( 6,  4)
light_height_dest = NTXY( 6,  6)
pull_time_dest    = NTXY( 6,  8)

.proc zapper_test
  ldx #2
  lda #>zapper_screen
  ldy #<zapper_screen
  jsr cls_puts_multiline_x
  lda #>zapper_buttoncircles
  ldy #<zapper_buttoncircles
  jsr draw_buttoncircles_chr_palette

  ; Load sprite 0 tiles
  lda #$0F
  sta PPUADDR
  lda #$C0
  sta PPUADDR
  ldy #30
  lda #0
  sta pull_time
  :
    sta PPUDATA
    dey
    bpl :-
  sty PPUDATA

  ; Write background trigger for sprite 0
  lda #$2B
  sta PPUADDR
  lda #$A0 | (ZAPPER_S0_X / 8)
  sta PPUADDR
  lda #$FD
  sta PPUDATA

  ; Load sprite 0
  lda #$FC
  sta OAM+1

  ; Zapper needs a light background
  ldy #$3F
  sty PPUADDR
  ldx #$00
  stx PPUADDR
  lda #$20
  sta PPUDATA
  lsr a
  sta PPUDATA
  stx PPUDATA
  sty PPUADDR
  lda #$11
  sta PPUADDR
  palloop:
    lda circlepal_on_white,x
    sta PPUDATA
    inx
    cpx #7
    bcc palloop

  ldy #$45
  jsr draw_port_number

forever:
  jsr present

  ; First wait for sprite 0 to be clear (pre-render line)
  waits0off:
    bit PPUSTATUS
    bvs waits0off
  
  ; Read the Zapper's trigger
  ldx selected_pad
  lda #$01
  and ident_bits,x
  tax
  lda #$10
  and $4016,x
  beq have_pulled_last_frame
    ldy pulled_last_frame
    bne not_new_pull
      sty pull_time
    not_new_pull:
    inc pull_time
  have_pulled_last_frame:
  sta pulled_last_frame
  
  ; With the port number still in X, wait for either sprite 0 to be
  ; set or a flat out miss
  lda #$C0
  tay
  sty light_height
  s0loop:
    bit PPUSTATUS
    beq s0loop
    bmi not_s0

  ; If no miss, wait up to 192 lines
  jsr zapkernel_yonoff_ntsc
  lda $00
  sta light_y
  lda $01
  sta light_height
not_s0:
  
  lda #<light_y_dest
  sta $02
  lda #>light_y_dest
  sta $03
  lda light_y
  ldy #'Y'
  jsr copydigits_add
  
  lda #<light_height_dest
  sta $02
  lda #>light_height_dest
  sta $03
  lda light_height
  ldy #'Y'
  jsr copydigits_add
  
  lda #<pull_time_dest
  sta $02
  lda #>pull_time_dest
  sta $03
  lda pull_time
  ldy #'Y'
  jsr copydigits_add

  ; Draw light position as sprites  
  lda #16
  clc
  adc light_y
  sta OAM+4
  clc
  adc light_height
  sta OAM+8
  lda #%11000000
  sta padtestdata+0
  ldy #2
  jsr color_buttoncircles
  jmp forever
.endproc

