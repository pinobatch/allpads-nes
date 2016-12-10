;
; NES PPU and controller port bus probing
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

.segment "BSS"
ppu_readback_values:  .res 8
ppu_latchtest_values: .res 5
open_bus_values:      .res 3

.segment "ZEROPAGE"
cbits_p1:
  min4016: .res 1  ; Bitwise minimum of $4016 values over 32 reads
  min3F16: .res 1  ; Bitwise minimum of $3F16-$4016 values over 32 reads
  max4016: .res 1  ; Bitwise maximum of $4016 values over 32 reads
  max3F16: .res 1  ; Bitwise maximum of $3F16-$4016 values over 32 reads
cbits_p2:
  min4017: .res 1  ; Bitwise minimum of $4017 values over 32 reads
  min3F17: .res 1  ; Bitwise minimum of $3F17-$4016 values over 32 reads
  max4017: .res 1  ; Bitwise maximum of $4017 values over 32 reads
  max3F17: .res 1  ; Bitwise maximum of $3F17-$4017 values over 32 reads

.segment "CODE"

OPEN_BUS_CONTRAST_VALUE = $BF

.proc ensure_open_bus_ok
  ; Write 00 FF to the first nametable, so that reads
  ; from $2007 return xx 00 FF
  ldx #$20
  lda #$00
  sta PPUCTRL  ; disable NMI; set VRAM increment to +1 (not +32)
  sta PPUMASK  ; disable rendering
  bit PPUSTATUS
  ldy #$FF
  stx PPUADDR
  sta PPUADDR
  sta PPUDATA  ; $2000 = $00
  sty PPUDATA  ; $2001 = $FF

  ; Basic readback through $2007
  stx PPUADDR
  sta PPUADDR
  bit PPUDATA  ; priming read
  ldy PPUDATA
  sty ppu_readback_values+0
  ldy PPUDATA
  sty ppu_readback_values+1
  
  ; And through mirrors of $2007
  stx PPUADDR
  sta PPUADDR
  bit PPUDATA  ; priming read
  ldy $3F07
  sty ppu_readback_values+2
  ldy $3F07
  sty ppu_readback_values+3
  stx PPUADDR
  sta PPUADDR
  bit PPUDATA  ; priming read
  ldy $3F17
  sty ppu_readback_values+4
  ldy $3F17
  sty ppu_readback_values+5
  
  ; And through open bus primed by a mirror of $2007
  stx PPUADDR
  sta PPUADDR
  bit PPUDATA  ; priming read
  ldy $4007-$20,x
  sty ppu_readback_values+6
  ldy $4007-$20,x
  sty ppu_readback_values+7

  ; Fill video memory with $3F for the next tests
  ldx #$20
  lda #$3F
  tay
  jsr ppu_clear_nt
  
  ; Fill the data latch
  ldy #$3F
  sty PPUSTATUS
  lda $2006
  sta ppu_latchtest_values+0
  sty PPUSTATUS
  lda $3F06
  sta ppu_latchtest_values+1
  sty PPUSTATUS
  lda $3F16
  sta ppu_latchtest_values+2
readendurance1:
  lda $3F16
  dey
  bne readendurance1
  lda $3F16
  sta ppu_latchtest_values+3
  ldy #$3F
  sty PPUSTATUS
  jsr wait36k
  lda $3F16
  sta ppu_latchtest_values+4

  lda $4006
  sta open_bus_values+0
  lda $4007
  sta open_bus_values+1
  ldy #$3F
  sty PPUSTATUS
  ldx #$20
  lda $4006-$20,x
  sta open_bus_values+2
  lda #0
  rts 
.endproc

.proc detect_controller_wires

  ; Fill $23C0-$23FF with the open bus contrast value
  ; and point the PPU there
  ldx #$20
  lda #$00
  ldy #OPEN_BUS_CONTRAST_VALUE
  jsr ppu_clear_nt
  lda #$23
  sta PPUADDR
  lda #$C0
  sta PPUADDR
  bit PPUDATA  ; priming read

  lda #$FF
  sta min4016
  sta min3F16
  sta min4017
  sta min3F17
  lda #$00
  sta max4016
  sta max3F16
  sta max4017
  sta max3F17

  ; Read directly from $401x
  lda #1
  sta $4016
  ldy #32  ; allow up to 32 bits of serial
  lsr a
  sta $4016
loop401x:
  lda $4016
  pha
  and min4016
  sta min4016
  pla
  ora max4016
  sta max4016
  lda $4017
  pha
  and min4017
  sta min4017
  pla
  ora max4017
  sta max4017
  dey
  bne loop401x

  ; Arkanoid controllers don't like to be immediately reread
  jsr wait36k

  ; Read from $3F1x followed by $401x
  lda #1
  sta $4016
  ldy #32   ; allow up to 32 bits of serial
  ldx #$20  ; index to get page crossing
  lsr a
  sta $4016
loop3F1x:
  ; $3F16 comes from PPU data latch
  lda #OPEN_BUS_CONTRAST_VALUE
  sta $2002
  lda $4016 - $20,x
  pha
  and min3F16
  sta min3F16
  pla
  ora max3F16
  sta max3F16
  ; $3F17 comes from VRAM readback
  lda $4017 - $20,x
  pha
  and min3F17
  sta min3F17
  pla
  ora max3F17
  sta max3F17
  dey
  bne loop3F1x

  rts
.endproc

.align 16
.proc wait36k
  ldx #28
  ldy #0
waitloop:
  dey
  bne waitloop
  dex
  bne waitloop
  rts
.endproc
