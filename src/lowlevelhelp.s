;
; Instructions for interpretation of low-level display of
; bus probing results
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
.export lowlevel_page1, lowlevel_page2, lowlevel_page3, lowlevel_page4

lowlevel_page1:
  .byte "To list controllers plugged",10
  .byte "into a Famicom or NES",10
  .byte "Control Deck, a program can",10
  .byte "use differences in open bus",10
  .byte "behavior to tell which input",10
  .byte "bits are always off, always",10
  .byte "on, serial, or not connected",10
  .byte "at all (NC).",10
  .byte "4L xor 4H are serial;",10
  .byte "4L xor 3L are NC.",10
  .byte "",10
  .byte "[1/4]",0

lowlevel_page2:
  .byte "Open bus occurs when nothing",10
  .byte "puts a 0 or 1 on a bit of",10
  .byte "the data bus during a read.",10
  .byte "Capacitance holds the old",10
  .byte "voltage in place for the CPU",10
  .byte "to use as the bit's value.",10
  .byte "Reading nonexistent memory,",10
  .byte "for example, usually leaves",10
  .byte "the instruction's last byte",10
  .byte "on the bus, which on 6502 is",10
  .byte "the address's high byte.",10
  .byte "[2/4]",0

lowlevel_page3:
  .byte "But the PowerPak has",10
  .byte "interfered with open bus",10
  .byte "before.  Pull-up resistors",10
  .byte "added to solve a DMA problem",10
  .byte "made NC bits look always on.",10
  .byte "Mindscape games failed to",10
  .byte "see presses because they",10
  .byte "expected open bus on unused",10
  .byte "controller port bits.",10
  .byte "Some NES-on-a-chip clones",10
  .byte "also handle open bus wrong.",10
  .byte "[3/4]",0

lowlevel_page4:
  .byte 34,"PPU readback",34," tests reading",10
  .byte "VRAM through $2007, $3F07,",10
  .byte "$3F17, and $3F07 carried",10
  .byte "across open bus to $4007.",10
  .byte "It should alternate 00 FF.",10
  .byte 34,"PPU latch",34," tests a separate",10
  .byte "data bus inside the PPU.",10
  .byte "First 4 are 3F; last varies.",10
  .byte 34,"APU open bus",34," reads the",10
  .byte "write-only Pulse 2 period.",10
  .byte "These should be 40 40 3F.",10
  .byte "[4/4]Press Start for results",0

