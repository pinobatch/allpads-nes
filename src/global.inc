;
; Header for controller test
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
.ifndef GLOBAL_INC
.define GLOBAL_INC

; init.s
.global reset_handler

; main.s
.global main, nmi_handler, irq_handler, press_A, press_keys, present
.global OAM
.globalzp cur_keys, new_keys, oam_used, nmis

; lowlevel.s
.global lowlevel_display

; serialwatch.s
.global serial_watch

; padgfx.s
.global load_controller_tiles, load_controller_palette
.global draw_one_controller, load_frame_tiles

; padnames.s
; order must correspond to tilesets/controllerimages.png
TYPE_NES_PAD = 0
TYPE_NES_DOGBONE = 1
TYPE_FC_1P = 2
TYPE_FC_2P = 3
TYPE_FOUR_SCORE = 4
TYPE_ZAPPER = 5
TYPE_NES_ARKANOID = 6
TYPE_POWER_PAD = 7
TYPE_SNES_PAD = 8
TYPE_SNES_MOUSE = 9
NUM_PADNAMES = 10

.global draw_controller_name, draw_controller_bits

; bg.s
.global load_font, puts_16, puts_multiline_16, puts_multiline_16_01
.global cls_puts_multiline, cls_puts_multiline_x
.global seek_nt_line_y, seek_nt_line_a, draw_1_char
.global hexdump8, hexdump8_02
.global copydigits, copydigits_add_2s, copydigits_add
.global copydigits_add_4chars
.global copydigits_used
LF = $0A
.define NTXY(tx,ty) ((tx) | ((ty) * 64) | $2000)

; ppuclear.s
.global ppu_clear_nt, ppu_clear_oam, ppu_screen_on

; pads.s
.global read_pads

; identify.s
.global ident_count, ident_type, ident_bits
.global one_shl_x
.global identify_controllers

; padtest.s
.global pads_check_first_button
.global nes_controller_test, fc_mic_controller_test
.global power_pad_test, four_score_test, snes_controller_test
SIZEOF_PADTESTDATA = 16
.global selected_pad, padtestdata

; The Arkanoid controller and the mouse are also serial
.global get_selected_portnum_mask_d0ord1, clear_padtestdata
.global read_serial_bytes, read_power_pad
.global draw_buttoncircles_chr_palette, color_buttoncircles
.global load_halfcircle_chr
.global draw_bit_number, draw_port_number

; mousetest.s
.global mouse_test

; vaustest.s
.global nes_paddle_test

; zappertest.s
.global zapper_test

; openbus.s
.globalzp cbits_p1, cbits_p2
.globalzp min4016, max4016, min3F16, min4017, max4017, min3F17
.global ppu_readback_values, ppu_latchtest_values, open_bus_values
.global ensure_open_bus_ok, detect_controller_wires, wait36k

; math.s
.global mul8, sqrt16

; bcd.s
.global bcd8bit

; unpb53.s
.globalzp ciSrc, ciDst
.global PB53_outbuf
.global unpb53_xtiles

.endif
