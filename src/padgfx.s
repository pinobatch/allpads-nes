;
; Controller graphics drawing
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
times85: .byte $00, $55, $AA, $FF

; order must correspond to TYPE_* constants in global.inc

controller_color1:  .byte $00,$00, $00,$00, $00,$06, $00,$11, $00,$00
controller_color2:  .byte $10,$10, $28,$28, $10,$10, $10,$10, $10,$10
controller_color3:  .byte $16,$16, $16,$16, $16,$16, $20,$16, $13,$13

.assert * = controller_color1 + 3 * NUM_PADNAMES, error, "wrong palette count for NUM_PADNAMES"

controllerimages_pb53:
  .dbyt 0
  .incbin "obj/nes/controllerimages.chr.pb53", 2
controllerimagesdata = controllerimages_pb53 + 2 * NUM_PADNAMES

.code

;;
; Loads a controller's tiles into controller image slot 1-7
; ($0A00, $0C00, ..., $1600).
; @param A controller image slot
; @param X controller image ID
; Overwrites $0000-$0002 and ciSrc.
.proc load_controller_tiles
  asl a
  adc #8
  sta PPUADDR
  lda #0
  sta PPUADDR

  txa
  asl a
  tax  ; X = 2 * controller image id

  ; controllerimages_pb53 begins with a set of big-endian offsets
  ; into controllerimages_pb53, one for each pic
  ; clc  ; carry cleared by ASL
  lda #<controllerimagesdata
  adc controllerimages_pb53+1,x
  sta ciSrc+0
  lda #>controllerimagesdata
  adc controllerimages_pb53+0,x
  sta ciSrc+1
  ldx #32
  jmp unpb53_xtiles
.endproc

;;
; Loads a controller's palette into slot 1-7
; ($3F05, $3F09, ..., $3F1D).
; @param A controller palette slot
; @param X controller image ID
.proc load_controller_palette
  asl a
  sec
  rol a
  pha
  lda #$3F
  sta PPUADDR
  pla
  sta PPUADDR
  lda controller_color1,x
  sta PPUDATA
  lda controller_color2,x
  sta PPUDATA
  lda controller_color3,x
  sta PPUDATA
  rts
.endproc

CONTROLLER_ICON_X = 64
;;
; Draws a controller icon whose tiles and palette are loaded.
; @param A controller slot (1-3: bg; 4-7: sprite)
; @param Y vertical position in 16-pixel units
; Overwrites $0000-$0003.
.proc draw_one_controller
dstlo = $02
dsthi = $03
dstnt = $00
base_tilenum = $01

  cmp #4
  bcc :+
    jmp draw_one_controller_as_sprites
  :
  pha
  lsr a
  ror a
  ror a
  sec
  ror a
  sta base_tilenum

  ; Calculate destination addresses
  tya
  asl a
  asl a
  ora #$C0 | (CONTROLLER_ICON_X >> 5)
  sta dstnt
  jsr seek_nt_line_y
  ora #CONTROLLER_ICON_X >> 3
  sta dstlo

  ntrowloop:
    lda dsthi
    sta PPUADDR
    lda dstlo
    sta PPUADDR
    clc
    adc #32
    sta dstlo
    bcc :+
      inc dsthi
      clc
    :
    ldx #8
    lda base_tilenum
    inc base_tilenum
    nttileloop:
      sta PPUDATA
      adc #4
      dex
      bne nttileloop
    lda base_tilenum
    and #$03
    bne ntrowloop

  pla
  tax
  lda times85,x
  sta base_tilenum

  ldx dstnt
  txa
  and #%00000100
  bne notbytealigned
  lda #$FF
  jmp do1ntrow
notbytealigned:

  ; Do top half
  eor dstnt
  tax
  lda #$F0
  jsr do1ntrow

  ; Do bottom half
  clc
  lda #4
  adc dstnt
  tax
  lda #$0F
do1ntrow:
  and base_tilenum
  ldy #$23
  sty PPUADDR
  stx PPUADDR
  sta PPUDATA
  sta PPUDATA
  rts
.endproc

.proc draw_one_controller_as_sprites
objy    = $00
objattr = $01
objx    = $02

  and #$03
  sta objattr
  lsr a
  ror a
  ror a
  tax
  tya
  .repeat 4
    asl a
  .endrepeat
  adc #23
  sta objy
  lda #CONTROLLER_ICON_X
  sta objx
  clc
  objloop:
    lda objy
    sta OAM+0,x
    adc #16
    sta OAM+4,x
    txa
    lsr a
    ora #$01
    sta OAM+1,x
    ora #$02
    sta OAM+5,x
    lda objattr
    sta OAM+2,x
    sta OAM+6,x
    lda objx
    sta OAM+3,x
    sta OAM+7,x
    clc
    adc #8
    sta objx
    txa
    adc #8
    tax
    lda objx
    cmp #CONTROLLER_ICON_X + 64
    bcc objloop
  rts
.endproc

