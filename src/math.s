;
; 8x8 multiply and 16-to-8 square root, used for hypot() function
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


;;
; Multiplies two 8-bit factors to produce a 16-bit product
; in about 153 cycles.
; @param A one factor
; @param Y another factor
; @return high 8 bits in A; low 8 bits in $0000
;         Y and $0001 are trashed; X is untouched
.proc mul8
factor2 = 1
prodlo = 0

  ; Factor 1 is stored in the lower bits of prodlo; the low byte of
  ; the product is stored in the upper bits.
  lsr a  ; prime the carry bit for the loop
  sta prodlo
  sty factor2
  lda #0
  ldy #8
loop:
  ; At the start of the loop, one bit of prodlo has already been
  ; shifted out into the carry.
  bcc noadd
  clc
  adc factor2
noadd:
  ror a
  ror prodlo  ; pull another bit out for the next iteration
  dey         ; inc/dec don't modify carry; only shifts and adds do
  bne loop
  rts
.endproc


;;
; Takes the square root and remainder of a 16-bit integer.
; Per http://6502org.wikidot.com/software-math-sqrt
; @param $00 16-bit number
; @return root in $02; remainder in $03;
;         high bit of remainder in carry
.proc sqrt16
numLo = $00
numHi = $01
root = $02
remainder = $03

  ldx #0
  stx root
  stx remainder
  ldx #8
loop:
  sec
  lda numHi
  sbc #$40
  tay
  lda remainder
  sbc root
  bcc no_store
  sty numHi
  sta remainder
no_store:
  rol root
  asl numLo
  rol numHi
  rol remainder
  asl numLo
  rol numHi
  rol remainder
  dex
  bne loop
  rts
.endproc
