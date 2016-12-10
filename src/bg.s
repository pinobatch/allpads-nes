;
; Background routines for controller test using 8x16 pixel font
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

.import font_tophalves, font_bottomhalves

srclo = $0000
srchi = $0001
dstlo = $0002
dsthi = $0003
numlines = $0004

.bss
copydigits_used: .res 1
.code

TOPLEFT = $2002

.segment "CODE"
.proc cls_puts_multiline
  ldx #<TOPLEFT
.endproc
.proc cls_puts_multiline_x
  stx dstlo
  pha
  sty srclo

  ; Start by clearing the first nametable
  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  sta PPUMASK

  ldx #$20
  ;lda #$00
  tay
  jsr ppu_clear_nt

  lda #>TOPLEFT
  sta dsthi
  lda #13
  sta numlines
  ldy srclo
  pla
  ; fall through to puts_multiline_16
.endproc

;;
; Writes the string at (AAYY) to lines starting at 2 and 3.
; At finish, 0 and 1 points to start of last line, and Y is the
; length of the last line.
; @param AAYY pointer to text
; @param $02-$03 nametable destination pointer
; @param $04 maximum number of lines to write
.proc puts_multiline_16
  sta srchi
  sty srclo
.endproc
.proc puts_multiline_16_0
lineloop:
  lda dsthi
  ldx dstlo
  jsr puts_16
  lda dstlo
  clc
  adc #64
  sta dstlo
  bcc :+
  inc dsthi
:
  lda (srclo),y
  beq done
  dec numlines
  beq done
  tya
  sec  ; +1: also skip newline
  adc srclo
  sta srclo
  bcc lineloop
  inc srchi
  bcs lineloop
done:
  rts
.endproc

;;
; Writes the string at (0) to the nametable at AAXX.
; Does not write to memory.
.proc puts_16
  sta PPUADDR
  stx PPUADDR
  pha
  txa
  pha
  ldy #0
copyloop1:
  lda (0),y
  cmp #' '
  bcc after_copyloop1
  tax
  lda font_tophalves-' ',x
  sta PPUDATA
  iny
  bne copyloop1
after_copyloop1:
  
  pla
  clc
  adc #32
  tax
  pla
  adc #0
  sta PPUADDR
  stx PPUADDR
  ldy #0
copyloop2:
  lda (0),y
  cmp #' '
  bcc after_copyloop2
  tax
  lda font_bottomhalves-' ',x
  sta PPUDATA
  iny
  bne copyloop2
after_copyloop2:
  rts
.endproc

;;
; Writes spaced hex bytes (e.g. 09 F9 ) to the nametable.
; @param AAXX nametable destination
; @param Y number of bytes to dump (up to 8)
; @param $0004 pointer to start of bytes to dump
; @return $0002-$0003: nametable address at end of hex dump;
; $0004-$0005: unchanged; $0006-$000A: overwritten
.proc hexdump8
dstlo = 2
dsthi = 3
  stx dstlo
  sta dsthi
  ; falls through
.endproc

;;
; Writes spaced hex bytes (e.g. 09 F9 ) to the nametable.
; @param $0002 nametable destination (16-bit)
; @param Y number of bytes to dump (up to 8)
; @param $0004 pointer to start of bytes to dump
; @return $0002-$0003: nametable address at end of hex dump;
; $0004-$0005: unchanged; $0006-$000A: overwritten
.proc hexdump8_02
strlo = 0
strhi = 1
dstlo = hexdump8::dstlo
dsthi = hexdump8::dsthi
hexsrc = 4
hexoffset = 6
hexbuf = 7
bytesleft = 10
  sty bytesleft
  lda #0
  sta hexbuf+2
  sta strhi
  sta hexoffset
  lda #<hexbuf
  sta strlo
  ldy hexoffset
loop:
  lda (hexsrc),y
  lsr a
  lsr a
  lsr a
  lsr a
  jsr hdig
  sta hexbuf+0
  lda (hexsrc),y
  iny
  sty hexoffset
  and #$0F
  jsr hdig
  sta hexbuf+1
  
  lda dstlo
  tax
  clc
  adc #3
  sta dstlo
  lda dsthi
  jsr puts_16
  ldy hexoffset
  cpy bytesleft
  bne loop
  rts
hdig:
  cmp #10
  bcc :+
  adc #'A'-'0'-11
:
  adc #'0'
  rts
.endproc

;;
; Draws the glyph for character X at address AAYY.
.proc draw_1_char
  sta PPUADDR
  sty PPUADDR
  lda #VBLANK_NMI|VRAM_DOWN
  sta PPUCTRL
  lda font_tophalves-' ',x
  sta PPUDATA
  lda font_bottomhalves-' ',x
  sta PPUDATA
  rts
.endproc


;;
; Calculates the nametable address of a line of text on the screen.
; @param A vertical position in 16-pixel increments
; @return high byte in $03, low byte in A
.proc seek_nt_line_y
  tya
.endproc
.proc seek_nt_line_a
dsthi = $03
  ora #$20 << 2
  lsr a
  sta dsthi
  lda #0
  ror a
  lsr dsthi
  ror a
  rts
.endproc
.import font_chr
.importzp FONT_NUM_TILES
.proc load_font
  lda #VBLANK_NMI
  sta PPUCTRL
  asl a
  sta PPUMASK
  sta PPUADDR
  sta PPUADDR
  lda #<font_chr
  sta ciSrc
  lda #>font_chr
  sta ciSrc+1
  ldx #FONT_NUM_TILES
  jmp unpb53_xtiles
.endproc

;
; copydigits stream is a list of 10-byte packets,
; each of which represents four glyphs at an x,y location.
; VRAM address high, low, top four tiles, bottom four tiles
; 116 cycles per group
;
.proc copydigits
  lda #VBLANK_NMI
  sta PPUCTRL
  ldx #0
  clc
loop:
  ; 16
  ldy PB53_outbuf+0,x
  lda PB53_outbuf+1,x
  sty PPUADDR
  sta PPUADDR
  ; 32
  .repeat 4, I
    lda PB53_outbuf+2+I,x
    sta PPUDATA
  .endrepeat
  ; 17
  lda PB53_outbuf+1,x
  adc #32
  bcc :+
    iny
    clc
  :
  sty PPUADDR
  sta PPUADDR
  ; 32
  .repeat 4, I
    lda PB53_outbuf+6+I,x
    sta PPUDATA
  .endrepeat

  ; 16
  txa
  adc #10
  tax
  cpx copydigits_used
  bcc loop
  ldx #0
  stx copydigits_used
  rts
.endproc

.assert >* = >copydigits, warning, "copydigits crosses bank boundary"


;;
; Adds a 2's complement number to the copydigits buffer.
; @param A number (-128 to 127)
; @param $02-$03 destination address
.proc copydigits_add_2s
  ldy #'+'
  cmp #$80
  bcc :+
    eor #$FF
    adc #$00
    ldy #'-'
  :
  ; fall through to copydigits_add
.endproc

;;
; Adds a 3-digit number to the copydigits buffer.
; @param A number (0 to 255)
; @param Y bit 7: use leading zeroes; bits 6-0: prefix character
; @param $02-$03 destination address
.proc copydigits_add
highDigits = $00
leadingzero = $01
dstlo = $02
dsthi = $03
  ldx copydigits_used
  pha
  
  ; Load address
  lda dsthi
  sta PB53_outbuf+0,x
  lda dstlo
  sta PB53_outbuf+1,x

  tya
  and #$80
  beq :+
    tya
    and #$7F
    tay
    lda #$10
  :
  sta leadingzero
  lda font_tophalves-' ',y
  sta PB53_outbuf+2,x
  lda font_bottomhalves-' ',y
  sta PB53_outbuf+6,x

  ; Convert 3-digit number
  pla
  jsr bcd8bit
  
  ; Last digit
  tay
  lda font_tophalves+'0'-' ',y
  sta PB53_outbuf+5,x
  lda font_bottomhalves+'0'-' ',y
  sta PB53_outbuf+9,x

  ; First digit
  lda highDigits
  lsr a
  lsr a
  lsr a
  lsr a
  beq :+
    ldy #$10
    sty leadingzero
  :
  ora leadingzero
  tay
  lda font_tophalves,y
  sta PB53_outbuf+3,x
  lda font_bottomhalves,y
  sta PB53_outbuf+7,x

  ; Middle digit
  lda highDigits
  and #$0F
  beq :+
    ora #$10
  :
  ora leadingzero
  tay
  lda font_tophalves,y
  sta PB53_outbuf+4,x
  lda font_bottomhalves,y
  sta PB53_outbuf+8,x
  txa
  clc
  adc #10
  sta copydigits_used
  rts
.endproc
