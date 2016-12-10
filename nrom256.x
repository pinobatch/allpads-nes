#
# Linker script for Concentration Room (lite version)
# Copyright 2010 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#
MEMORY {
  ZP:     start = $10, size = $f0, type = rw;
  # use first $10 zeropage locations as locals
  HEADER: start = 0, size = $0010, type = ro, file = %O, fill=yes, fillval=$00;
  RAM:    start = $0300, size = $0500, type = rw;
  ROM0:   start = $8000, size = $2000, type = ro, file = %O, fill=yes, fillval=$FF;
  ROM1:   start = $A000, size = $2000, type = ro, file = %O, fill=yes, fillval=$FF;
  ROM2:   start = $C000, size = $2000, type = ro, file = %O, fill=yes, fillval=$FF;
  ROM3:   start = $E000, size = $2000, type = ro, file = %O, fill=yes, fillval=$FF;
}

SEGMENTS {
  ZEROPAGE: load=ZP, type=zp;
  BSS:      load=RAM, type=bss, define=yes, align=$100;
  INESHDR:  load=HEADER, type=ro, align=$10;
  RODATA:   load=ROM2, type=ro, align=$10;
  PB53CODE: load=ROM2, type=ro, align=1, optional=yes;
  DMC:      load=ROM3, type=ro, align=64, optional=yes;
  CODE:     load=ROM3, type=ro, align=$100;
  VECTORS:  load=ROM3, type=ro, start=$FFFA;
}

FILES {
  %O: format = bin;
}

