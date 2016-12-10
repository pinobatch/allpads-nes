;
; Binary to decimal conversion for 8-bit numbers
; Copyright 2012 Damian Yerrick
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
.export bcd8bit

; This file contains functions to convert binary numbers (base 2)
; to decimal representation (base 10).  Most of the hex to decimal
; routines on 6502.org rely on the MOS Technology 6502's decimal
; mode for ADC and SBC, which was removed from the Ricoh parts.
; These do not use decimal mode.

; The 8-bit routine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.macro bcd8bit_iter value
  .local skip
  cmp value
  bcc skip
  sbc value
skip:
  rol highDigits
.endmacro

;;
; Converts a decimal number to two or three BCD digits
; in no more than 80 cycles.
; @param a the number to change
; @return a: low digit; 0: upper digits as nibbles
; No other memory or register is touched.
.proc bcd8bit
highDigits = 0

  ; First clear out two bits of highDigits.  (The conversion will
  ; fill in the other six.)
  asl highDigits
  asl highDigits

  ; Each iteration takes 11 if subtraction occurs or 10 if not.
  ; But if 80 is subtracted, 40 and 20 aren't, and if 200 is
  ; subtracted, 80 is not, and at least one of 40 and 20 is not.
  ; So this part takes up to 6*11-2 cycles.
  bcd8bit_iter #200
  bcd8bit_iter #100
  bcd8bit_iter #80
  bcd8bit_iter #40
  bcd8bit_iter #20
  bcd8bit_iter #10
  rts
.endproc


