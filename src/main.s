;
; Controller port test for NES
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

OAM = $0200
MAX_WRAM_BANKS = 16

.zeropage
nmis:           .res 1
cur_keys:       .res 2
new_keys:       .res 2

.bss
WARMBOOTSIGVALUE = $F01E
warmbootsiglo:  .res 1
warmbootsighi:  .res 1

COLDBOOTTIME = 240
WARMBOOTTIME = 120
bootuptimer:    .res 1

.code
;;
; This NMI handler is good enough for a simple "has NMI occurred?"
; vblank-detect loop.
.proc nmi_handler
  inc nmis
  rti
.endproc
.proc irq_handler
  rti
.endproc

.proc main
  jsr load_font
  jsr ensure_open_bus_ok
  jsr detect_controller_wires
  lda #0
  sta copydigits_used

  ; Cold boot shows the title screen.
  lda #>WARMBOOTSIGVALUE
  ldx #<WARMBOOTSIGVALUE
  cpx warmbootsiglo
  bne iscoldboot
  cmp warmbootsighi
  beq iswarmboot
iscoldboot:
  stx warmbootsiglo
  sta warmbootsighi
  lda #COLDBOOTTIME
  bne have_bootuptimer

iswarmboot:  
  ; Warm reset during bootup shows the low-level results
  lda bootuptimer
  beq not_lowlevel
  lda #0
  sta bootuptimer
lowlevelloop:
  jsr lowlevel_display
  jmp lowlevelloop
not_lowlevel:
  lda #WARMBOOTTIME
have_bootuptimer:
  sta bootuptimer

  ; Load palette
  lda #$80
  sta PPUCTRL
  asl a
  sta PPUMASK
  bit PPUSTATUS
  ldx #$3F
  stx PPUADDR
  sta PPUADDR
  stx PPUDATA
  sta PPUDATA
  lda #$10
  sta PPUDATA

  ; Display initial screen
  lda #>copr_screen
  ldy #<copr_screen
  jsr cls_puts_multiline
  
  ; Discern console model
  ldx #open_bus_to_name_len - 2
  lda min3F16
  eor min4016
  discern_loop:
    cmp open_bus_to_name,x
    bne nomatch
      lda open_bus_to_name+1,x
      bne have_model_name_offset
    nomatch:
    dex
    dex
    bpl discern_loop
  lda #0
have_model_name_offset:
  clc
  adc #<unknown_console_name
  sta $00
  lda #0
  adc #>unknown_console_name
  sta $01
  lda #>MODEL_NAME_NTADDR
  ldx #<MODEL_NAME_NTADDR
  jsr puts_16

  jsr present
  jsr identify_controllers

  titleloop:
    jsr present
    dec bootuptimer
    bne titleloop

  jsr draw_all_controllers

waitforpressloop:
  jsr present
  
  ldx ident_count
  beq waitforpressloop
  dex
  chkloop:
    jsr pads_check_first_button
    bne done
    dex
    bpl chkloop
  bmi waitforpressloop

done:
  stx selected_pad
  lda ident_type,x
  asl a
  tay
  lda test_procs+1,y
  pha
  lda test_procs+0,y
  pha
  rts
.endproc

.rodata
test_procs:
  .addr nes_controller_test-1
  .addr nes_controller_test-1
  .addr nes_controller_test-1
  .addr fc_mic_controller_test-1
  .addr four_score_test-1
  .addr zapper_test-1
  .addr nes_paddle_test-1
  .addr power_pad_test-1
  .addr snes_controller_test-1
  .addr mouse_test-1

.code
.proc test_coming_soon
  lda #>test_coming_soon_msg
  ldy #<test_coming_soon_msg
  jsr cls_puts_multiline
:
  jsr present
  jmp :-
.endproc



.proc present
  ; Wait for a vertical blank
  lda nmis
vw3:
  cmp nmis
  beq vw3
  lda #0
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA
  lda copydigits_used
  beq :+
    jsr copydigits
  :
  
  ; Turn the screen on
  ldx #0
  ldy #240-24
  lda #VBLANK_NMI|BG_0000|OBJ_8X16|2
  sec
  jmp ppu_screen_on
.endproc

.proc press_A
  jsr present
  ; Does player want to quit?
  jsr read_pads
  lda new_keys
  and #KEY_A|KEY_START
  beq press_A
  rts
.endproc

.proc draw_all_controllers
cur_controller = $0005
cur_ypos = $0006

  ldy ident_count
  bne controllers_exist
    lda #>no_controllers_msg
    ldy #<no_controllers_msg
    jmp cls_puts_multiline
  controllers_exist:

  lda #>probe_result_screen
  ldy #<probe_result_screen
  jsr cls_puts_multiline
  
  ldy ident_count
  lda ident_layout_topy,y
  sta cur_ypos
  cmp #2
  bcc no_heading
    lda #>probe_result_heading
    sta $01
    lda #<probe_result_heading
    sta $00
    RESULT_HEADING_ADDR = $2005
    lda #>RESULT_HEADING_ADDR
    ldx #<RESULT_HEADING_ADDR
    jsr puts_16
  no_heading:

  ldy #0
  controllerloop:
    ; some unit testing
    sty cur_controller
    ldx ident_type,y
    iny
    tya
    jsr load_controller_tiles
    ldy cur_controller
    ldx ident_type,y
    iny
    tya
    jsr load_controller_palette
    ldy cur_controller
    iny
    tya
    ldy cur_ypos
    jsr draw_one_controller
    ldy ident_count
    lda ident_layout_height,y
    sta $0004
    ldy cur_controller
    lda ident_type,y
    ldy cur_ypos
    jsr draw_controller_name
    ldy cur_controller
    lda ident_bits,y
    ldy cur_ypos
    jsr draw_controller_bits

    ldy ident_count
    lda ident_layout_height,y
    clc
    adc cur_ypos
    sta cur_ypos
    ldy cur_controller
    iny
    cpy ident_count
    bcc controllerloop

  rts
.endproc


.rodata
COPR = 127
copr_screen:
  .byte "",LF
  .byte "",LF
  .byte "Controller Test r8",LF
  .byte COPR," 2016 Damian Yerrick",LF
  .byte "",LF
  .byte "Probing...",LF
  .byte "",LF
  .byte "",LF
  .byte "Press Reset for",LF
  .byte "low-level probing results",0

probe_result_heading:
  .byte "Connected Controllers",0

probe_result_screen:
  .byte LF, LF, LF, LF, LF, LF, LF, LF, LF, LF
  .byte "  To probe again, plug in",LF
  .byte "controllers and press Reset.",0

no_controllers_msg:
  .byte LF,LF,LF,LF
  .byte "No controllers are connected",LF
  .byte "to your Control Deck.  Plug",LF
  .byte "some in and press Reset.",0

MODEL_NAME_NTADDR = $2000 + 64 * 6 + 4
open_bus_to_name:
  .byte %11100000, nes001_name-unknown_console_name
  .byte %11100100, nes101_name-unknown_console_name
  .byte %11111000, hvc_name-unknown_console_name
open_bus_to_name_len = * - open_bus_to_name

unknown_console_name: .byte "Unknown console",0
nes001_name: .byte "NES-001",0
nes101_name: .byte "NES-101",0
hvc_name: .byte "Family Computer",0

ident_layout_topy = * - 1
  .byte 2, 2, 0, 0, 0
ident_layout_height = * - 1
  .byte 4, 4, 3, 2, 2

test_coming_soon_msg:
  .byte LF, LF, LF, LF
  .byte "This test is coming soon.",LF
  .byte LF
  .byte "Reset: rescan",0
