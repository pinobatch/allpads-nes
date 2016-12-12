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
  jsr adjust_speed

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
    ldx cur_bit
    lda one_shl_x,x
    ldy cur_port
    ldx #4
    jsr read_serial_bytes
    jsr prepare_serial_report
    jmp display_complete
  not_poll:
    jsr prepare_speed_line
    lda #0
    sta speed_dirty
  display_complete:

  jsr present
  jmp forever
.endproc

.proc prepare_serial_report
  rts
.endproc

.proc prepare_speed_line
  rts
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
  bne not_right
    lda #1
    sta cur_port
    inc speed_dirty
    rts
  not_right:

  lsr a
  bne not_left
    lda #0
    sta cur_port
    inc speed_dirty
    rts
  not_left:

  lsr a
  bne not_down
    lda #7
    bne add_bit_number
  not_down:

  lsr a
  bne not_up
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
