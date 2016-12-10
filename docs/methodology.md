Open bus
--------
When a program running on an NES or Famicom reads a controller port
($4016 or $4017), the chipset connects an inverting buffer to some
lines of the data bus and leaves others disconnected.  But the
different models handle this slightly differently.

* The original NES (front-loading model NES-001) connects bits 0, 3,
  and 4 of both ports to the 7-pin connector on the front panel and
  bits 1 and 2 to ground.
* The top-loading NES (NES-101) connects bits 0, 3, and 4 the
  same way.  It does not connect bit 2 of port 1 ($4016) but
  grounds it on port 2 ($4017).
* The Family Computer (HVC-001) connects bit 0 of both ports to the
  hardwired controllers, bit 2 of port 1 to the _second_ controller's
  microphone (counterintuitively), and bit 1 of port 1 and
  bits 1-4 of port 2 to the DA15 expansion connector.

Nothing is connected to the Famicom's bits 3 and 4 or to
bits 5 through 7 on either system.  These unconnected bits produce an
effect called "open bus", where capacitance holds the previous value
on the data bus in place.  So we can detect which system we're on
through its open bus behavior.

To test for open bus, we have to arrange for particular values to be
on the data bus before reading the input ports.  Normally, the last
thing on the data bus when the CPU reads memory is the last byte of
the instruction, which is the upper byte of the address.  This limits
which bits we can control somewhat, as the upper byte will always be
$40 through normal means.

But we can use another quirk of the 6502 to control more bits.
Indexed addressing modes first try performing a partial 8-bit
addition, adding the low byte of the index register (X or Y) to the
low byte of the register modulo 256 and using the unchanged high
byte in the address that the CPU reads.  Often, the 8-bit addition
produces no carry (a value larger than 255), and reading this
partial result is correct.  But when this 8-bit addition produces a
carry, it has to add 1 to the high byte and perform the read again.
Any side effects of having performed the first read have already
taken effect.  One important side effect is that whatever is on the
data bus from the first read will carry over to the second.  The bits
are said to "ride the open bus" from the first address to the second.

The PPU doesn't handle open bus the same way as the APU.  It contains
a separate 8-bit data bus that is connected to the CPU data bus
whenever the CPU is accessing any of the eight ports.  ([Visual 2C02]
calls it `_io_db`, presumably for "input/output data bus".)  But when
the CPU isn't reading or writing a PPU port, these two buses are
disconnected, and the long traces running to various parts of the
PPU have capacitance that holds a value for a few thousand cycles.
It behaves like an 8-bit dynamic latch, which is why [FCEUX's PPU]
calls it `PPUGenLatch` and includes it in save states.

The CPU can write a byte to this latch through any PPU port, even
nominally read-only ports, and read it back from any write-only port
or from unused bits of `PPUSTATUS` ($2002).  For example, the CPU can
write a byte to `PPUSTATUS` and read it back from `PPUADDR` ($2006).
This lets a program arrange for _any_ value to be read from `PPUADDR`
or $3F16, a mirror of `PPUADDR`, which allows it to arrange for any
open bus value at $4016.  Reads from `PPUDATA` ($2007) both perform
VRAM data accesses and fill this latch.

However, we have to watch out for the clones.

* Some types of cartridge do not implement open bus.  PowerPak is one
  of them.  To fix a problem with OAM DMA (copying the sprite display
  list to the PPU), it has pull-up resistors on the data lines, which
  cause all unused bits to become 1.  It's like reading a byte that 
  contains $FF between CPU reads.  Controller reading in [Mindscape]
  games has a bug that causes it to rely on APU open bus, and
  Mindscape games failed on PowerPak at first.  So the test has to
  tolerate pull-ups.  The EverDrive N8 cartridge, on the other hand,
  implements open bus the same as a mask ROM or NOR flash cartridge.
* "Famiclones" are third-party consoles compatible with well-behaved
  NES and Famicom software.  Older famiclones using discrete CPU and
  PPU chips behave like a Famicom.  But some newer "NES on a chip"
  (NOAC) integrated circuits implement open bus or the PPU data latch
  wrong.  Some use actual open bus, where reads from $20xx produce
  $20 and reads from $3Fxx produce $3F.  Others, such as the FC Twin,
  have a fake latch that always returns $20 no matter the address and
  no matter what was last written.  The program can't do anything
  about fake latch, but at least for PPUs that use real open bus,
  the test can leave $3F in the latch so that the CPU reads the
  same values whether the PPU uses a latch or actual open bus.
* Emulators might fail at open bus or the PPU data latch.
  The test needs to take the same precautions as with famiclones.

There are eight important addresses for the open bus test.

* $3F06 and $3F16  
  All addresses from $2000 through $3FFF select the PPU, and the
  PPU sees only the low 3 bits of the address.  This means $3F06
  and $3F16 behave the same as `PPUADDR` ($2006).  `PPUADDR` is the
  write-only video memory address port, and reads produce latched
  data.  For example, writing $3F to $2002 and then reading one of
  these addresses will leave $3F on the data bus.
* $3F07 and $3F17  
  These behave as `PPUDATA` ($2007), the video memory data port.
  This port is readable, and we can arrange for reads of both $00
  and $FF values.
* $4006 and $4007  
  These are write-only ports associated with the second pulse wave
  tone generator.  Reading results in open bus: $40 from an absolute
  read or whatever the PPU left on the bus for an indexed read with
  a carry.
* $4016 and $4017
  These are the input ports.  Some bits are driven; others are open
  bus.  Bits 7-5 in particular are open bus on any system other than
  the coin-operated Vs. System.

Before any controller detection happens, it checks that the hardware
quirks on which open bus detection relies are present.  Some flash
carts and emulators are known to interfere with these quirks.
First it makes sure the CPU can read back $00 and $FF values in
the nametable through the PPU.  This is done through $2007 and its
mirrors $3F07 and $3F17.  Then it ensures that the PPU data latch
behavior is usable by reading $2006, $3F06, and $3F16.  A usable
value is either the value written to $2002 or the address high byte.
To confirm that the cartridge is not interfering with the open bus,
it looks for $40 in absolute reads from $4006 and $4007, as well as
a $3F byte from a $3F06-$4006 sequence.  Finally it looks for video
memory readback with a $3F07-$4007 sequence.  If all these pass, the
machine handles open bus well enough to test all bits of $4017 and
the low 7 bits of $4016.

This produces 16 bytes of results, which should ideally match
the following:

* PPU readback: 8 bytes
    * $2007: 00 FF
    * $3F07: 00 FF
    * $3F17: 00 FF
    * $3F07-$4007: 00 FF (varies based on cartridge open bus)
* PPU data latch: 5 bytes
    * $2006: 20
    * $3F06: 3F
    * $3F16: 3F
    * $3F16 after 64 reads: 3F
    * $3F16 after 35800+-cycle delay: 3F (varies by PPU revision)
* Open bus
    * $4006: 40
    * $4007: 40
    * $3F06-$4006: 3F

[Visual 2C02]: http://www.qmtpro.com/~nes/chipimages/visual2c02/
[FCEUX's PPU]: http://sourceforge.net/p/fceultra/code/HEAD/tree/fceu/trunk/src/ppu.cpp#l183
[Mindscape]: http://forums.nesdev.com/viewtopic.php?f=9&t=3698

Detecting controllers
---------------------
Several controllers are "parallel", meaning they produce separate
bits on separate wires.  Others, such as the standard gamepad, are
"serial", meaning the bits change on successive reads to indicate
separate input states.  Some are both, such as the Arkanoid
controller that has a button on one wire and a serial potentiometer
reading on the other.  Serial streams will end with a long string of
usually 1 bits, though some unlicensed NES controllers have used
0 bits instead.

So it reads each controller twice, taking two streams of 32 bits each
time, and separate the bits into four classes: bits that stay 1 the
whole time, bits that stay 0 the whole time, bits that vary within
a stream (probably serial), and bits that come from open bus.  The
first controller ($4016) is read once with absolute open bus ($40)
and once with an indexed read after loading $BF into the PPU latch.
The second controller ($4017) is read with PPU readback as the
indexed open bus source: once with $40 and once with VRAM filled with
$BF.  Famiclones using CPU open bus ($3F) for the PPU latch will
appear to drive $4016 D7 low, but that causes no serious problem.

The reading routine produces eight values, four for each
controller port:

* Minimum (bitwise AND) of 32 reads of $4016 with $40 open bus
* Minimum (bitwise AND) of 32 reads of $4016 with $BF open bus
* Maximum (bitwise OR) of 32 reads of $4016 with $40 open bus
* Maximum (bitwise OR) of 32 reads of $4016 with $BF open bus
* Minimum (bitwise AND) of 32 reads of $4017 with $40 open bus
* Minimum (bitwise AND) of 32 reads of $4017 with $BF open bus
* Maximum (bitwise OR) of 32 reads of $4017 with $40 open bus
* Maximum (bitwise OR) of 32 reads of $4017 with $BF open bus

These feed into four rules of thumb for bits 6-0 of each port:

* If the minimum and maximum with $40 open bus differ, that line
  is serial.
* If the minimum with $40 and $3F open bus differ, that line is
  open bus.
* If all four bits are 0, that line is driven to 0.
* If all four bits are 1, that line is driven to 1.  This is true,
  for example, of a Zapper that is not detecting light.

Results from several controllers on a front-loading NES:

    Empty port           40 A0 40 A0 (D0-D4 always 0)
    Controller           40 A0 41 A1 (D0 serial)
    Super NES Mouse      40 A0 41 A1
    Four Score           40 A0 41 A1
    Zapper               48 A8 48 A8
    Power Pad            40 A0 58 B8
    Arkanoid             40 A0 50 B0

Depending on which lines are serial, the program can narrow down
what specific device is connected.  With D0 serial:

* NES controller: Reads 9-16 are all 1
* Super NES controller: Reads 13-24 are 000011111111
* Super NES Mouse: Reads 13-16 are 0001, and it is possible to change
  the sensitivity by clocking while the strobe is on  
* Four Score: Reads 17-24 are 00010000 in $4016 and 00100000
  in $4017

Anything that can be D0 serial can also be D1 serial, as D1 is where
Famicom expansion controllers appear.  A Famicom with things plugged
into the expansion port will produce a denser result screen, with
up to five lines for controllers instead of only two.

With D3 and D4:

* Zapper has D3 (the photodiode) high when no light is received,
  such as 2000 cycles after vertical blanking, and D4 as the trigger.
* NES Power Pad has D3 and D4 serial.
* NES Arkanoid controller has D4 serial and D3 as the fire button.
