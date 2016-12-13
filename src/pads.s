;
; NES controller reading code (used by lowlevel and serialwatch only)
;
; Copyright 2009-2011 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;

;
; 2011-07: Damian Yerrick added labels for the local variables and
;          copious comments and made USE_DAS a compile-time option
; 2016-12: Removed unused parts (Famicom D1, player 2, DPCM glitch
;          compensation, and autorepeat) that make little sense in
;          the context of lowlevel and serialwatch
;

.export read_pads
.importzp cur_keys, new_keys

JOY1      = $4016

.segment "CODE"
.proc read_pads
thisRead = $00
lastFrameKeys = $04

  ; Bits from the controllers are shifted into thisRead and
  ; thisRead.  In addition, thisRead serves as the loop counter:
  ; once the $01 gets shifted left eight times, the 1 bit will
  ; end up in carry, terminating the loop.
  lda #$01
  sta thisRead

  ; Write 1 then 0 to JOY1 to send a latch signal, telling the
  ; controllers to copy button states into a shift register
  sta JOY1
  lsr a
  sta JOY1
  sta new_keys+1
  sta cur_keys+1

  ; For serialwatch, we want to read only D0, not D1 which might
  ; not be something standard controller-shaped.
  loop:
    lda JOY1       ; read player 1's controller
    lsr a
    rol thisRead   ; put one bit in the register
    bcc loop       ; once $01 has been shifted 8 times, we're done

  lda cur_keys+0   ; A = keys that were down last frame
  eor #$FF         ; A = keys that were up last frame
  and thisRead     ; A = keys down now and up last frame
  sta new_keys+0
  lda thisRead
  sta cur_keys
  rts
.endproc

