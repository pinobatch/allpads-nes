;
; Test for Super NES Mouse controller
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

mouse_screen:
  .byte "Mouse on  P D",LF
  .byte "",LF
  .byte "Position",LF
  .byte "Sensitivity",LF
  .byte "Velocity",LF
  .byte "Speed",LF
  .byte "",LF
  .byte "Acceleration",LF
  .byte "Accel Magnitude",LF
  .byte "",LF
  .byte "",LF
  .byte "Reset: Exit",0

mouse_buttoncircles:
  .byte 216, 23, 200, 23  ; buttons
  .byte 216, 71, 200, 71, 184, 71  ; sensitivity markers
  .byte 216, 71  ; mouse pointer
  
  .byte  60,119  ; speed marker
  .byte  60,167  ; accel magnitude marker
  .byte  56,119  ; speed minimum
  .byte  56,167  ; accel magnitude minimum
  .byte  64,119  ; speed maximum
  .byte  64,167  ; accel magnitude minimum
  .byte 255

.code

mouse_pos_dst = NTXY(20,2)
mouse_vel_dst = NTXY(20,4)
mouse_speed_dst = NTXY(20,5)
mouse_acc_dst = NTXY(20,7)
mouse_accmag_dst = NTXY(20,8)
mouse_x = padtestdata+4
mouse_y = padtestdata+5
mouse_dx = padtestdata+6
mouse_dy = padtestdata+7
mouse_d = padtestdata+8
mouse_dmax = padtestdata+9
mouse_dtime = padtestdata+10
mouse_d2x = padtestdata+11
mouse_d2y = padtestdata+12
mouse_d2 = padtestdata+13
mouse_d2max = padtestdata+14
mouse_d2time = padtestdata+15

.proc mouse_test
  ldx #4
  lda #>mouse_screen
  ldy #<mouse_screen
  jsr cls_puts_multiline_x
  lda #>mouse_buttoncircles
  ldy #<mouse_buttoncircles
  jsr draw_buttoncircles_chr_palette
  jsr load_halfcircle_chr
  ldy #$0D
  jsr draw_port_number
  ldy #$11
  jsr draw_bit_number
  lda #128
  sta mouse_x
  lsr a
  sta mouse_y
  jsr clear_padtestdata

  ; Set up range markers
  lda #$C8
  sta OAM+33
  sta OAM+37
  sta OAM+41
  sta OAM+45
  lda #$40
  sta OAM+42
  sta OAM+46

loop:
  lda #1
  sta $4016
  lsr a
  sta $4016

  ; Save previous buttons
  lda padtestdata+1
  pha

  ; Read the mouse
  jsr get_selected_portnum_mask_d0ord1
  ldx #4
  jsr read_serial_bytes
  pla
  sta padtestdata+0
  

  ; Differentiate and integrate the X and Y coordinates
  lda padtestdata+3
  ldx #0
  jsr add_one_coord
  lda padtestdata+2
  inx
  jsr add_one_coord
  cmp #191
  bcc :+
    lda #191
    sta mouse_y
  :

  ; Calculate magnitude
  ldx #0
  jsr update_magnitude
  ldx #5
  jsr update_magnitude

  ; If speed line is clicked, change speed
  lda padtestdata+0
  eor #$FF
  and padtestdata+1
  and #KEY_B
  beq not_clicked
  lda mouse_y
  sec
  sbc #48
  cmp #16
  bcs not_clicked
    jsr get_selected_portnum_mask_d0ord1
    lda #1
    sta $4016
    lda $4016,y
    lda #0
    sta $4016
  not_clicked:

  lda #>mouse_pos_dst
  sta $03
  lda #<mouse_pos_dst
  sta $02
  lda mouse_x
  ldy #' '
  jsr copydigits_add
  lda #<mouse_pos_dst+4
  sta $02
  lda mouse_y
  ldy #','
  jsr copydigits_add

  lda #>mouse_vel_dst
  sta $03
  lda #<mouse_vel_dst
  sta $02
  lda mouse_dx
  jsr copydigits_add_2s
  lda #<mouse_vel_dst+4
  sta $02
  lda mouse_dy
  jsr copydigits_add_2s

  lda #>mouse_speed_dst
  sta $03
  lda #<mouse_speed_dst
  sta $02
  lda mouse_d
  ldy #' '
  jsr copydigits_add
  lda #<mouse_speed_dst+4
  sta $02
  lda mouse_dmax
  ldy #'/'
  jsr copydigits_add

  lda #>mouse_acc_dst
  sta $03
  lda #<mouse_acc_dst
  sta $02
  lda mouse_d2x
  jsr copydigits_add_2s
  lda #<mouse_acc_dst+4
  sta $02
  lda mouse_d2y
  jsr copydigits_add_2s

  lda #>mouse_accmag_dst
  sta $03
  lda #<mouse_accmag_dst
  sta $02
  lda mouse_d2
  ldy #' '
  jsr copydigits_add
  lda #<mouse_accmag_dst+4
  sta $02
  lda mouse_d2max
  ldy #'/'
  jsr copydigits_add
  
  ; Convert buttons.  If speed (bits 5-4) is 0, set bit 3.
  lda padtestdata+1
  and #$30
  cmp #1
  lda padtestdata+1
  bcs :+
    ora #$08
  :
  ora #$03  ; light up range markers
  sta padtestdata+0
  ldy #8
  jsr color_buttoncircles
  
  ; Draw mouse pointer
  lda mouse_x
  sec
  sbc #4
  bcs :+
    lda #0
  :
  sta OAM+23
  lda mouse_y
  clc
  adc #15
  sta OAM+20
  
  ; Draw range markers
  clc
  lda mouse_d
  adc #60
  sta OAM+27
  clc
  lda mouse_d2
  adc #60
  sta OAM+31
  clc
  lda mouse_dmax
  adc #64
  sta OAM+43
  clc
  lda mouse_d2max
  adc #64
  sta OAM+47
  
  
  jsr present
  jmp loop
.endproc

.proc add_one_coord
  ; Convert from signed magnitude to 2's complement
  cmp #$80
  bcc :+
    eor #$7F
    adc #0
  :
  tay
  sec
  sbc mouse_dx,x
  sta mouse_d2x,x
  tya
  sta mouse_dx,x

  ; Add coordinate with clamping
  lda mouse_x,x
  clc
  eor #$80
  adc mouse_dx,x
  eor #$80
  bvc no_ovf
  bcc cc_ovf
    lda #$00
    beq no_ovf
  cc_ovf:
    lda #$FF
  no_ovf:
  sta mouse_x,x
  rts
.endproc

.proc update_magnitude
prodlo = $00
prodhi = $01
xsquared = $02
xsave = $04
sqrtroot = $02
sqrtremainder = $03

  ; Pythagorean theorem: r^2 = x^2+y^2
  lda mouse_dx,x
  jsr abs_and_square
  sta xsquared+1
  lda prodlo
  sta xsquared+0

  lda mouse_dy,x
  jsr abs_and_square
  sta prodhi
  lda prodlo
  clc
  adc xsquared+0
  sta prodlo
  lda prodhi
  adc xsquared+1
  sta prodhi

  ; now take the square root
  stx xsave
  jsr sqrt16
  ldx xsave

  ; If remainder is greater than root, add 1 to root
  bcs roundrootup
  lda sqrtroot
  cmp sqrtremainder
  bcs roundrootdown
  roundrootup:
    clc
    adc #1
  roundrootdown:
  sta mouse_d,x

  cmp mouse_dmax,x
  bcc no_increase_dmax
    sta mouse_dmax,x
    lda #30
    sta mouse_dtime,x
    rts
  no_increase_dmax:
  lda mouse_dtime,x
  beq dtime_is_zero
    dec mouse_dtime,x
    rts
  dtime_is_zero:
  lda mouse_dmax,x
  beq :+
    dec mouse_dmax,x
  :
  rts

abs_and_square:
  bpl :+
    eor #$FF
    clc
    adc #1
  :
  tay
  jmp mul8
.endproc

