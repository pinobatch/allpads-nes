;
; Low-level display of bus probing results
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
.import lowlevel_page1, lowlevel_page2, lowlevel_page3, lowlevel_page4

.code
.proc lowlevel_display
  jsr lowlevel_load_palette
  lda #>results_msg
  ldy #<results_msg
  jsr cls_puts_multiline
  jsr lowlevel_display_results
  lda #KEY_A|KEY_SELECT|KEY_START
  jsr press_keys
  and #KEY_SELECT
  beq display_help
    jmp serial_watch
  display_help:
  lda #>lowlevel_page1
  ldy #<lowlevel_page1
  jsr cls_puts_multiline
  jsr press_A
  lda #>lowlevel_page2
  ldy #<lowlevel_page2
  jsr cls_puts_multiline
  jsr press_A
  lda #>lowlevel_page3
  ldy #<lowlevel_page3
  jsr cls_puts_multiline
  jsr press_A
  lda #>lowlevel_page4
  ldy #<lowlevel_page4
  jsr cls_puts_multiline
  jmp press_A
.endproc

.proc lowlevel_load_palette
  ; seek to the start of palette memory ($3F00-$3F1F)
  ldx #$3F
  stx PPUADDR
  ldx #$00
  stx PPUADDR
copypalloop:
  lda initial_palette,x
  sta PPUDATA
  inx
  cpx #initial_palette_end-initial_palette
  bcc copypalloop
  rts
.endproc

PPU_READBACK_DEST = NTXY(7, 5)
PPU_READBACK_LEN = $08
PPU_LATCHTEST_DEST = NTXY(16, 6)
PPU_LATCHTEST_LEN = $05
APU_OPENBUS_DEST = NTXY(22, 7)
APU_OPENBUS_LEN = $03
HEX_P1_DEST = NTXY(9, 10)
HEX_P2_DEST = NTXY(9, 11)
RESULTS_LEN = $04

.proc lowlevel_display_results
  lda #>ppu_readback_values
  sta $05
  lda #<ppu_readback_values
  sta $04
  lda #>PPU_READBACK_DEST
  ldx #<PPU_READBACK_DEST
  ldy #PPU_READBACK_LEN
  jsr hexdump8
  lda #>ppu_latchtest_values
  sta $05
  lda #<ppu_latchtest_values
  sta $04
  lda #>PPU_LATCHTEST_DEST
  ldx #<PPU_LATCHTEST_DEST
  ldy #PPU_LATCHTEST_LEN
  jsr hexdump8
  lda #>open_bus_values
  sta $05
  lda #<open_bus_values
  sta $04
  lda #>APU_OPENBUS_DEST
  ldx #<APU_OPENBUS_DEST
  ldy #APU_OPENBUS_LEN
  jsr hexdump8
  lda #>cbits_p1
  sta $05
  lda #<cbits_p1
  sta $04
  lda #>HEX_P1_DEST
  ldx #<HEX_P1_DEST
  jsr write_results_line
  lda #>cbits_p2
  sta $05
  lda #<cbits_p2
  sta $04
  lda #>HEX_P2_DEST
  ldx #<HEX_P2_DEST
  jsr write_results_line
  rts
.endproc

;;
; @param AAXX nametable destination
; @param $0004-$0005 pointer to four bytes in order 4L 3L 4H 3H
.proc write_results_line

  ; Write hex part
  ldy #RESULTS_LEN
  jsr hexdump8

discipline = $07
src = $04
serialbits = $00
ncbits = $01
minbits = $0F

  ; Form a string listing line disciplines (0, 1, serial, or NC)
  ; in $0007-$000F
  ldy #0
  lda (src),y
  sta minbits
  iny
  eor (src),y
  sta ncbits      ; 4L ^ 3L are NC
  iny
  lda (src),y
  eor minbits
  sta serialbits  ; 4L ^ 4H are serial
  ldy #7
  bitloop:
    lda #0
    lsr serialbits
    rol a
    lsr ncbits
    rol a
    lsr minbits
    rol a
    cmp #4
    bcc :+
      lda #4
    :
    tax
    lda line_discipline_codes,x
    sta discipline,y
    dey
    bpl bitloop
  iny
  sty discipline+8

  ; And write it after the hex result (which ends at the nametable
  ; address in $02)
  sty $01
  lda #<discipline
  sta $00
  lda $03
  ldx $02
  inx
  jmp puts_16
.endproc

.segment "RODATA"
initial_palette:
  .byt $17,$27,$20,$37
initial_palette_end:

line_discipline_codes:  .byte "01..S"

results_msg:
  .byte "Low-level probing results",10
  .byte "Select: Watch serial line;",10
  .byte "Start: Help; Reset: Exit",10
  .byte "",10
  .byte "PPU readback",10
  .byte "",10
  .byte "PPU latch",10
  .byte "APU open bus",10
  .byte "",10
  .byte "       4L 3L 4H 3H D76543210",10
  .byte "1P:",10
  .byte "2P:",0


