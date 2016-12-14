#!/usr/bin/make -f
#
# Makefile for all controller test
# Copyright 2011-2016 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title = allpads
version = r9

# Space-separated list of assembly language files that make up the
# PRG ROM
objlist = \
  zappertest bg init main lowlevel serialwatch padnames \
  openbus identify padtest vaustest mousetest \
  pads ppuclear unpb53 bcd math
objlistnrom = \
  nrom fizzterhalves padgfx lowlevelhelp
objlist218 = \
  mapper218 mapper218halves

AS65 = ca65
LD65 = ld65
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
EMU := fceux
DEBUGEMU := ~/.wine/drive_c/Program\ Files/FCEUX/fceux.exe
# other options for EMU are start (Windows) or gnome-open (GNOME)

.PHONY: run debug dist zip clean all

run: $(title).nes
	$(EMU) $<
debug: $(title).nes
	$(DEBUGEMU) $<

# Rule to create or update the distribution zipfile by adding all
# files listed in zip.in.  Use files that most commonly change (the
# executable and key documentation) as the dependencies.
dist: zip
zip: $(title)-$(version).zip
$(title)-$(version).zip: zip.in all \
  README.md CHANGES.txt docs/methodology.md $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

# Build zip.in from the list of files in the Git tree
zip.in:
	git ls-files | grep -e "^[^.]" > $@
	echo zip.in >> $@

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here, but caulk goes where? > $@

clean:
	-rm $(objdir)/*.o $(objdir)/*.s $(objdir)/*.chr $(objdir)/*.pb53

all: $(title).nes $(title)218.nes

# Rules for PRG ROM

objlisto := $(foreach o,$(objlist) $(objlistnrom),$(objdir)/$(o).o)
objlisto218 := $(foreach o,$(objlist) $(objlist218),$(objdir)/$(o).o)

map.txt $(title).nes: nrom256.x $(objlisto)
	$(LD65) -o $(title).nes -m map.txt -C $^

map218.txt $(title)218.nes: mapper218_64.x $(objlisto218)
	$(LD65) -o $(title)218.nes -m map218.txt -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/nrom.o $(objdir)/mapper218.o: $(srcdir)/nes2header.inc

# Files that depend on .incbin'd files
$(objdir)/nrom.o: $(objdir)/fizzter.chr.pb53
$(objdir)/mapper218.o: $(objdir)/mapper218font.chr.pb53
$(objdir)/padtest.o: \
  $(objdir)/sprcircle16.chr.pb53 $(objdir)/halfcircle16.chr.pb53
$(objdir)/padgfx.o: \
  $(objdir)/controllerimages.chr.pb53

# Rules for CHR

$(objdir)/%.chr: $(imgdir)/%.png
	tools/pilbmp2nes.py $< $@

$(objdir)/%16.chr: $(imgdir)/%.png
	tools/pilbmp2nes.py -H 16 $< $@

$(objdir)/%.pb53: $(objdir)/%
	tools/pb53.py --raw $< $@

$(objdir)/fizzter.chr: $(imgdir)/fizztertiny.png
	tools/cvtfont.py $< $@ -o $(objdir)/fizzterhalves.s --prefix font_

$(objdir)/fizzterhalves.s: $(objdir)/fizzter.chr
	touch $@

$(objdir)/mapper218font.chr: $(imgdir)/mapper218font.png
	tools/cvtfont.py $< $@ -o $(objdir)/mapper218halves.s --prefix font_

$(objdir)/mapper218halves.s: $(objdir)/mapper218font.chr
	touch $@

$(objdir)/controllerimages.chr: $(imgdir)/controllerimages.png
	tools/pilbmp2nes.py -H 32 $< $@

$(objdir)/controllerimages.chr.pb53: $(objdir)/controllerimages.chr
	tools/pb53.py --block-size=32 --no-prev $< $@

#$(objdir)/%c16.chr: $(objdir)/%.chr
#	tools/dedupebin.py -c 16 --format u8 $(objdir)/controllerimages.chr controllerimagesu.chr controllerimagesmap.nam
#
#$(objdir)/%.nam: $(objdir)/%c16.chr
#	touch $@


