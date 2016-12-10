;
; NES Arkanoid paddle test
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

.rodata

paddle_screen:
  .byte "Paddle on  P",LF
  .byte "",LF
  .byte "Displacement",LF
  .byte "",LF
  .byte "Range",LF
  .byte "Center Offset",LF
  .byte "",LF
  .byte "Velocity",LF
  .byte "",LF
  .byte "Acceleration",LF
  .byte "",LF
  .byte "Reset: Exit",0

paddle_buttoncircles:
  .byte 124, 71, 120, 71, 128, 71
  .byte 124,119, 120,119, 128,119
  .byte 124,151, 120,151, 128,151
  .byte 124,183, 120,183, 128,183
  .byte 255

displacement_dst = NTXY(24, 2)
rangemin_dst     = NTXY(20, 4)
rangemax_dst     = NTXY(24, 4)
offset_dst       = NTXY(24, 5)
velocity_dst     = NTXY(20, 7)
velmax_dst       = NTXY(24, 7)
accel_dst        = NTXY(20, 9)
accelmax_dst     = NTXY(24, 9)

paddle_xtm2   = padtestdata+4  ; x[t - 2]
paddle_xtm1   = padtestdata+5  ; x[t - 1]
paddle_x      = padtestdata+6
paddle_xc     = padtestdata+7  ; x - (xmin + xmax) / 2
paddle_xmin   = padtestdata+8
paddle_xmax   = padtestdata+9
paddle_d      = padtestdata+10
paddle_dmax   = padtestdata+11
paddle_dtime  = padtestdata+12
paddle_d2     = padtestdata+13
paddle_d2max  = padtestdata+14
paddle_d2time = padtestdata+15

.code
.proc nes_paddle_test
  ldx #4
  lda #>paddle_screen
  ldy #<paddle_screen
  jsr cls_puts_multiline_x
  lda #>paddle_buttoncircles
  ldy #<paddle_buttoncircles
  jsr draw_buttoncircles_chr_palette
  jsr load_halfcircle_chr
  ldy #$0E
  jsr draw_port_number

  ; Draw halfcircles at range sides
  lda #36
  rangetilesloop:
    tax
    lda #$C8
    sta OAM+5,x
    sta OAM+9,x
    lda #$40
    sta OAM+10,x
    txa
    sec
    sbc #12
    bcs rangetilesloop
  
  jsr clear_padtestdata
  lda #$FF
  sta paddle_xmin
  lsr a
  sta paddle_x
  sta paddle_xtm1
  
forever:

  lda #1
  sta $4016
  lsr a
  sta $4016
  
  ; Read the paddle
  jsr get_selected_portnum_mask_d0ord1
  jsr read_power_pad
  
  lda paddle_xtm1
  sta paddle_xtm2
  lda paddle_x
  sta paddle_xtm1
  lda padtestdata+1
  eor #$FF
  sta paddle_x
  sta OAM+3

  ; Adjust sides of range
  cmp paddle_xmin
  bcs :+
    sta paddle_xmin
  :
  cmp paddle_xmax
  bcc :+
    sta paddle_xmax
  :

  ; Calculate relative to center of range
  clc
  lda paddle_xmin
  adc paddle_xmax
  ror a
  eor #$FF
  pha
  sec
  adc paddle_x
  sta paddle_xc
  eor #$80
  sta OAM+15
  pla
  pha
  sec
  adc paddle_xmin
  clc
  adc #124
  sta OAM+19
  pla
  sec
  adc paddle_xmax
  clc
  adc #132
  sta OAM+23

  ; Take derivatives
  ; Velocity = (x[t] - x[t - 2]) / 2
  lda paddle_x
  sec
  sbc paddle_xtm2
  ror a     ; Divide by 2 with sign extension (carry = inverted sign)
  cmp #$80  ; to compensate for taking velocity over 2 frames
  eor #$80
  ldx #0
  jsr derivative_decay

  ; Acceleration = (x[t] + x[t - 2]) / 2 - x[t - 1]
  lda paddle_x
  clc
  adc paddle_xtm2
  ror a
  sec
  sbc paddle_xtm1
  ldx #3
  jsr derivative_decay

  ; Display everything as sprites
  lda paddle_d
  eor #$80
  sta OAM+27
  lda #124
  sec
  sbc paddle_dmax
  sta OAM+31
  lda #132
  clc
  adc paddle_dmax
  sta OAM+35
  lda paddle_d2
  eor #$80
  sta OAM+39
  lda #124
  sec
  sbc paddle_d2max
  sta OAM+43
  lda #132
  clc
  adc paddle_d2max
  sta OAM+47
  lda paddle_xmin
  clc
  adc #<-4
  sta OAM+7
  lda paddle_xmax
  clc
  adc #4
  sta OAM+11

  ; Draw everything as digits
  lda #<displacement_dst
  sta $02
  lda #>displacement_dst
  sta $03
  lda paddle_x
  ldy #' '
  jsr copydigits_add

  lda #<rangemin_dst
  sta $02
  lda #>rangemin_dst
  sta $03
  lda paddle_xmin
  ldy #' '
  jsr copydigits_add
  lda #<rangemax_dst
  sta $02
  lda paddle_xmax
  ldy #'-'
  jsr copydigits_add

  lda #<offset_dst
  sta $02
  lda #>offset_dst
  sta $03
  lda paddle_xc
  jsr copydigits_add_2s

  lda #<velocity_dst
  sta $02
  lda #>velocity_dst
  sta $03
  lda paddle_d
  jsr copydigits_add_2s
  lda #<velmax_dst
  sta $02
  lda paddle_dmax
  ldy #'/'
  jsr copydigits_add

  lda #<accel_dst
  sta $02
  lda #>accel_dst
  sta $03
  lda paddle_d2
  jsr copydigits_add_2s
  lda #<accelmax_dst
  sta $02
  lda paddle_d2max
  ldy #'/'
  jsr copydigits_add

  ldy #1
  jsr color_buttoncircles

  jsr present
  jmp forever
.endproc

.proc derivative_decay
  sta paddle_d,x
  bcs :+
    eor #$FF
    adc #0
  :
  cmp paddle_dmax,x
  bcc no_increase_dmax
    sta paddle_dmax,x
    lda #30
    sta paddle_dtime,x
    rts
  no_increase_dmax:
  lda paddle_dtime,x
  beq dtime_is_zero
    dec paddle_dtime,x
    rts
  dtime_is_zero:
  lda paddle_dmax,x
  beq :+
    dec paddle_dmax,x
  :
  rts
.endproc
