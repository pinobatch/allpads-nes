;
; Real-time serial display for controller test
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

cur_port = padtestdata+4
cur_bit  = padtestdata+5
cur_speed = padtestdata+6
speed_dirty = padtestdata+7

serial_watch_msg:
  .byte "Serial watch",LF
  .byte "Control Pad: Port/bit",LF
  .byte "A: Poll rate",LF
  .byte "Reset: Exit",LF
  .byte LF
  .byte LF  ; "1P D0 Fast"
  .byte " 1-16:",LF
  .byte "17-32:",0

speed_names:  .byte "FastMed.Slow"
speed_masks:  .byte $00, $0F, $FF
NUM_SPEEDS = 3

.proc serial_watch
  ldy #<serial_watch_msg
  lda #>serial_watch_msg
  jsr cls_puts_multiline
  lda #1
  sta speed_dirty
  lsr a
  sta cur_port
  sta cur_bit
  sta cur_speed

  ; TODO: Display speed names and speedmasks

forever:

  ; At fast speed, skip polling only if the "1P D0 Fast" line
  ; needs 
  ldx cur_speed
  lda speed_masks,x
  bne not_check_dirty_status_line
    lda speed_dirty
    bne not_poll
  not_check_dirty_status_line:
  and nmis
  bne not_poll
  yes_poll:
    lda #1
    sta $4016
    ldx cur_bit
    ldy cur_port
    lsr a
    sta $4016
    lda one_shl_x,x
    ldx #4
    jsr read_serial_bytes
    jsr prepare_serial_report
    jmp display_complete
  not_poll:
    jsr prepare_speed_line
    lda #0
    sta speed_dirty
  display_complete:

  ; To minimize the unavoidable problem of the Super NES Mouse and
  ; Arkanoid Controller not tolerating rereads very well,
  ; reread the controller and adjust speed after reading the report.
  jsr adjust_speed
  jsr present
  jmp forever
.endproc

REPORT_NTADDR = NTXY(9, 6)

.proc prepare_serial_report
dstlo = $02
dsthi = $03
chars = $04
bytebits = $08
byteindex = $09

  lda #0
  sta byteindex
  lda #<REPORT_NTADDR
  sta dstlo
  lda #>REPORT_NTADDR
  sta dsthi
  jsr do_one_line
  lda #<REPORT_NTADDR + 64
  sta dstlo
do_one_line:
  jsr do_one_byte
do_one_byte:
  ldy byteindex
  inc byteindex
  lda padtestdata,y
  sta bytebits
  jsr do_one_nibble
do_one_nibble:
  ldx #0
  bitloop:
    asl bytebits
    lda #'0' >> 1
    rol a
    sta chars,x
    inx
    cpx #4
    bcc bitloop
  jsr copydigits_add_4chars
  lda #5
  clc
  adc dstlo
  sta dstlo
  rts
.endproc

PORT_NTADDR = NTXY(2, 5)
BIT_NTADDR = NTXY(5, 5)
SPEED_NTADDR = NTXY(8, 5)

.proc prepare_speed_line
dstlo = $02
dsthi = $03
chars = $04
  lda #' '
  sta chars+2
  sta chars+3
  lda #<PORT_NTADDR
  sta dstlo
  lda #>PORT_NTADDR
  sta dsthi
  clc
  lda cur_port
  adc #'1'
  sta chars+0
  lda #'P'
  sta chars+1
  jsr copydigits_add_4chars

  lda #<BIT_NTADDR
  sta dstlo
  lda #'D'
  sta chars+0
  lda cur_bit
  ora #'0'
  sta chars+1
  jsr copydigits_add_4chars

  lda cur_speed
  asl a
  asl a
  ora #3
  tay
  ldx #3
  :
    lda speed_names,y
    sta chars,x
    dey
    dex
    bpl :-
  lda #<SPEED_NTADDR
  sta dstlo
  jmp copydigits_add_4chars
.endproc

.proc adjust_speed
  jsr read_pads
  lda new_keys+0
  bpl not_change_speed
    ldx cur_speed
    inx
    cpx #NUM_SPEEDS
    bcc :+
      ldx #0
    :
    stx cur_speed
    inc speed_dirty
    rts
  not_change_speed:

  lsr a
  bcc not_right
    lda #1
    sta cur_port
    inc speed_dirty
    rts
  not_right:

  lsr a
  bcc not_left
    lda #0
    sta cur_port
    inc speed_dirty
    rts
  not_left:

  lsr a
  bcc not_down
    lda #7
    bne add_bit_number
  not_down:

  lsr a
  bcc not_up
    lda #1
  add_bit_number:
    clc
    adc cur_bit
    and #$07
    sta cur_bit
    inc speed_dirty
  not_up:

  rts
.endproc
