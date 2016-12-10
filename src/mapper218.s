;
; Mapper 218 (PRG ROM only) header, stubs for unused functionality,
; and condensed open bus interpretation instructions
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

; set this to nonzero to build for AxROM, an approximation of
; mapper 218 for popular emulators that don't support mapper 218
AOTEST = 0

.segment "INESHDR"
.include "nes2header.inc"
nes2prg 16384
nes2chrram 1024
.if AOTEST
  nes2mapper 7
.else
  nes2mirror 218
  nes2mapper 218
.endif
nes2tv 'N','P'
nes2end

.segment "VECTORS"
.import nmi_handler, reset_handler, irq_handler
.addr nmi_handler, reset_handler, irq_handler

.rodata
.export font_chr
.exportzp FONT_NUM_TILES
font_chr: .incbin "obj/nes/mapper218font.chr.pb53"
FONT_NUM_TILES = 64

; Stubs for omitted features ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Because of limited ROM and video RAM, some features are omitted
; from the 64 kbit mapper 218 build:
; Frames in 1P/2P layout
; Controller icons
; Controller palettes
; Detailed explanation of open bus

.export load_controller_tiles, load_controller_palette, load_frame_tiles
.export draw_one_controller

.code
load_controller_tiles:
load_frame_tiles:
load_controller_palette:
draw_one_controller:
  rts

.rodata
.export lowlevel_page1, lowlevel_page2, lowlevel_page3, lowlevel_page4

LF = $0A
lowlevel_page1:
  .byte "TO LIST CONNECTED",LF
  .byte "CONTROLLERS, A PROGRAM CAN",LF
  .byte "USE OPEN BUS TO TELL WHICH",LF
  .byte "BITS ARE ALWAYS OFF OR ON,",LF
  .byte "SERIAL, OR NOT CONNECTED.",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "(1/4)",0

lowlevel_page2:
  .byte "OPEN BUS HAPPENS WHEN NO",LF
  .byte "CHIP CHANGES THE VOLTAGE ON",LF
  .byte "THE DATA BUS, CAUSING THE",LF
  .byte "LAST VALUE TO STICK AROUND.",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "(2/4)",0

lowlevel_page3:
  .byte "BUT THE POWERPAK AND SOME",LF
  .byte "FAMICLONES DIFFER IN THEIR",LF
  .byte "OPEN BUS BEHAVIOR FROM A",LF
  .byte "NORMAL NES CONTROL DECK AND",LF
  .byte "GAME PAK.",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "(3/4)",0

lowlevel_page4:
  .byte "PPU READBACK:",LF
  .byte "    EXPECT ALTERNATING 00 FF",LF
  .byte "PPU LATCH:",LF
  .byte "     MOSTLY 3F (LAST VARIES)",LF
  .byte "APU OPEN BUS:EXPECT 40 40 3F",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "",LF
  .byte "(4/4) START: RESULTS",0


