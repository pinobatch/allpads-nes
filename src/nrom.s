;
; NROM header for controller test
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
.segment "INESHDR"
.include "nes2header.inc"
nes2prg 32768
nes2chrram 8192
nes2mapper 0
nes2mirror 'V'
nes2tv 'N','P'
nes2end

.segment "VECTORS"
.import nmi_handler, reset_handler, irq_handler
.addr nmi_handler, reset_handler, irq_handler


; The NROM version's font is fancier than the mapper 218 version's
.rodata
.export font_chr
.exportzp FONT_NUM_TILES
font_chr: .incbin "obj/nes/fizzter.chr.pb53"
FONT_NUM_TILES = 160
