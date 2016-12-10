;
; Identify controllers based on which lines are 0, 1, or serial
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

.bss
MAX_IDENT = 5
ident_count:    .res 1
ident_type:     .res MAX_IDENT
ident_bits:     .res MAX_IDENT

; ident_bits layout
; 7654 3210
; |||| || +- 0: $4016; 1: $4017
; |||+-++--- lowest bit number
; +++------- highest bit number

.rodata
one_shl_x: .byte $01, $02, $04, $08, $10, $20, $40, $80

.code

.proc identify_controllers
  lda #0
  sta ident_count

  ldx #0
  lda min4016
  eor max4016
  and #$01
  jsr do_one_serial

  ldx #0
  lda min4016
  eor max4016
  and #$02
  jsr do_one_serial

  ldx #0
  lda min4016
  eor max4016
  tay
  lda min4016
  eor min3F16
  jsr do_one_d3d4

  ldx #1
  lda min4017
  eor max4017
  and #$01
  jsr do_one_serial

  ldx #1
  lda min4017
  eor max4017
  and #$02
  jsr do_one_serial

  ldx #1
  lda min4017
  eor max4017
  tay
  lda min4017
  eor min3F17
  jsr do_one_d3d4

  jmp convert_dogbones

do_one_serial:
  beq notadding
    pha
    jsr ident_serial
    tay
    pla
    cpy #$80
    bcs notadding

    ; At this point we have a serial device with
    ; type=Y, port=X, bits=A ($01 or $02)
    ; Convert port and bits to ident_bits
    cmp #$02
    txa
    bcc store_type_y_bits_a
      ora #%00100100
    store_type_y_bits_a:
    cpy #TYPE_FOUR_SCORE
    bne not_four_score
      ora #%00000010
    not_four_score:
    ldx ident_count
    cpx #MAX_IDENT
    bcs notadding
    inc ident_count
    sta ident_bits,x
    tya
    sta ident_type,x
notadding:
  rts

store_type_y_d3d4:
  txa
  ora #%10001100
  bne store_type_y_bits_a

do_one_d3d4:
  ; X = port ID, Y = serial, A = open bus
  and #$18
  bne notadding
  tya
  and #$18
  cmp #$18  ; Power Pad is serial on both bytes
  bne not_powerpad
    ldy #TYPE_POWER_PAD
    bne store_type_y_d3d4
  not_powerpad:

  cmp #$10
  bne not_nes_arkanoid
    ldy #TYPE_NES_ARKANOID
    bne store_type_y_d3d4
  not_nes_arkanoid:

  ; Wait for approx. 2000 cycles after start of vertical blanking
  lda nmis
  :
    cmp nmis
    beq :-
  ldy #0
  :
    bit $00
    dey
    bne :-

  ; ...after which the photodiode should stop receiving light.
  ; (Bit 3 is 1 when the photodiode is off.)
  lda $4016,x
  and #$08
  beq not_zapper
    ldy #TYPE_ZAPPER
    bne store_type_y_d3d4
  not_zapper:

  rts
.endproc



;;
; Identifies what serial controller is on D0 or D1 of a port
; through reads 9-24.
; @param X port ID (0: $4016; 1: $4017)
; @param A bit mask ($01: D0; $02: D1)
.proc ident_serial
portid = $00
bitmask = $01
reads9to16 = $02
reads17to24 = $03
  stx portid
  sta bitmask
  jsr wait36k
  ldx portid

  ; Strobe while setting up ring counters
  lda #1
  sta $4016
  sta reads9to16
  sta reads17to24
  lsr a
  sta $4016
  
  ; Skip first 8 reads
  ldy #8
  loop1to8:
    lda $4016,x
    dey
    bne loop1to8

  ; Save next 8 reads
  loop9to16:
    lda bitmask
    and $4016,x
    cmp #1
    rol reads9to16
    bcc loop9to16

  ; Some controller types do not need reads 17 to 24.
  ; 9-16 = $FF: Famicom, NES, or NES dogbone controller
  lda reads9to16
  cmp #$FF
  bne not_nes_pad
    lda #TYPE_NES_PAD
    rts
  not_nes_pad:

  loop17to24:
    lda bitmask
    and $4016,x
    cmp #1
    rol reads17to24
    bcc loop17to24

  ; 9-16 and $0F = $01 and responds to speed changes: Super NES Mouse
  lda reads9to16
  and #$0F
  cmp #$01
  bne not_snes_mouse
    lda bitmask
    jsr ident_mouse
    ora #$00
    bpl have_pad_1
  not_snes_mouse:

  ; 9-16 and $0F = $00 and 17-24 = $FF: Super NES controller
  ; 17-24 = $10 << portid: Four Score
  lda reads17to24
  cmp one_shl_x+4,x
  bne not_four_score
  cpx #0
  bne pad_is_unknown
    lda #TYPE_FOUR_SCORE
  have_pad_1:
    rts
  not_four_score:
  cmp #$FF
  bne not_snes_pad
    lda #$0F
    and reads9to16
    bne pad_is_unknown
    lda #TYPE_SNES_PAD
    rts
  not_snes_pad:

pad_is_unknown:
  lda #$FF
  rts
.endproc

;;
; Ensures the Super NES Mouse's sensitivity (report bits 11 and 12)
; can be set to 1 then 0.
.proc ident_mouse
portid = $00
bitmask = $01
targetspeed = $04
triesleft = $05
  stx portid
  sta bitmask
  lda #1
  sta targetspeed
  
  targetloop:
    lda #4
    sta triesleft

    tryloop:
      ; To change the speed, send a clock while strobe is on, 
      ldy #1
      sty $4016
      lda $4016,x
      dey
      sty $4016
    
      ; Wait and strobe the mouse normally, then skip bits 1-10
      jsr wait36k
      ldx portid
      ldy #1
      sty $4016
      dey
      sty $4016
      ldy #10
      skip10loop:
        lda $4016,x
        dey
        bne skip10loop

      ; Now read bits 11 and 12
      ldy #0
      lda $4016,x
      and bitmask
      beq :+
        ldy #2
      :
      lda $4016,x
      and bitmask
      beq :+
        iny
      :
      cpy targetspeed
      beq try_success
      dec triesleft
      bne tryloop
    lda #$FF
    rts

  try_success:
    dec targetspeed
    bpl targetloop

  ; Setting to both 0 and 1 was successful.
  lda #TYPE_SNES_MOUSE
  rts
.endproc

;;
; Guesses what variant of the standard NES controller is in use by
; the $4016 open bus behavior of the console it probably came with.
; D2 open bus: NES-101 (toploader); use NES-039 (dogbone) controller
; D3-4 open bus, and two standard controllers are on D0: HVC-001 (RF)
; D3-4 open bus otherwise: HVC-101 (AV); use NES-039
; Neither: NES-001 (frontloader); use NES-004
.proc convert_dogbones
replacements = $00
num_d0pads = $02

  ldx ident_count
  beq nope

  ; You're likely to have dogbones if you have an HVC-101 or NES-101.
  ; Reject NES-001.
  lda min4016
  eor min3F16
  and #%00011100
  beq nope
  ldy #TYPE_NES_DOGBONE
  sty replacements+0
  sty replacements+1

  ; D2 open bus means guaranteed NES-101
  and #%00000100
  bne is_101

  ; Attempt to distinguish HVC-001 (which uses hardwired controllers)
  ; from HVC-101 (which uses NES dogbones with a shorter cord
  ; intended to reach the coffee table) by counting how many
  ; standard NES controllers on D0 are connected.  If only the mic
  ; on $4016 D2 were more sensitive...
  sta num_d0pads
  dex
  count_d0pads:
    lda ident_bits,x
    lsr a
    bne count_notd0pad  ; Ignore non-D0 controllers
    lda ident_type,x
    .if ::TYPE_NES_PAD <> 0
      cmp #TYPE_NES_PAD
    .endif
    bne is_101  ; A single non-basic D0 controller disqualifies
      inc num_d0pads
    count_notd0pad:
    dex
    bpl count_d0pads

  ; If both standard controllers on D0 aren't there, it isn't
  ; possible for it to be an HVC-001.  But if there are 2 basic
  ; controllers and no non-basic controllers, HVC-001 is possible.
  lda num_d0pads
  cmp #2
  bne is_101
  lda #TYPE_FC_1P
  sta replacements+0
  lda #TYPE_FC_2P
  sta replacements+1

is_101:
  ldy ident_count
  dey
  change_d0pads:
    ldx ident_bits,y
    cpx #2
    bcs change_notd0pad  ; Ignore non-D0 controllers
    lda ident_type,y
    .if ::TYPE_NES_PAD <> 0
      cmp #TYPE_NES_PAD
    .endif
    bne change_notd0pad  ; Ignore non-basic D0 controller
      lda replacements,x
      sta ident_type,y
    change_notd0pad:
    dey
    bpl change_d0pads

nope:
  rts
.endproc
  

