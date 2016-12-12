Controller test
===============
This NES program detects which console model you have and which
controllers are connected by reading the controller ports.

Start the program, and it'll briefly display whether you have an
NES-001, NES-101, or Family Computer while scanning for controllers.
It looks for D0 controllers (Controller, Four Score, Mouse) on both
D0 and D1 so that they'll work on the Famicom through a pin adapter
to its DA15 expansion port.

Once it completes, it displays names and pictures of connected
controllers.  From here, press a controller's primary fire button to
begin an input test.  (This is A on NES controllers, B on the Super
NES Controller, the left mouse button, the Zapper's trigger, or 4 on
a Power Pad side B.)

Detection and input testing work for these:

* NES Controller (original NES-004 and dogbone NES-039)
* Famicom hardwired controllers (1P and 2P with microphone)
* NES Power Pad (NES-028)
* NES Four Score (NES-034)
* Super NES Controller (SNS-005) through pin adapter
* Zapper (NES-005)
* Arkanoid Controller
* Super NES Mouse (SNS-016) through pin adapter

Some flash cart menus cannot be navigated with anything but an NES
or Super NES controller.  You can work around this by starting the
program, hot-swapping to the desired controllers, and then pressing
the Reset button on the Control Deck to rescan the ports.

Press Reset before the scan finishes to display low-level data about
which lines are always off, always on, serial, or not connected
at all.  (See docs/methodology.md for how this works under the hood.)
Then, if you have a standard controller in port 1 or are using the
Famicom's hardwired controllers, press Select to begin watching a
report of up to 32 bits on any serial line.

Limits
------
The PowerPak by retrousb.com has pull-up resistors on the data bus
that may interfere with console type detection.  The EverDrive,
Infinite NES Lives boards, and donor carts do not have this problem.

The NES dogbone controller and Famicom hardwired controller behave
exactly the same as the original NES controller.  So it guesses that
the controller used is the one that the console shipped with.  Nor
can it distinguish the original Famicom (HVC-001), with one hardwired
controller with Select and Start buttons and one hardwired controller
with a microphone, from the AV Famicom (HVC-101) with two controllers
plugged in.  If it mis-detects an AV Famicom as an original Famicom,
press A on controller 2 to start the test, then Start to switch from
the mic controller to the standard controller.

Versions of the Power Pad and Arkanoid Controller for the Famicom
use a different protocol that is not yet supported, though the NES
versions of those work through a pin adapter that passes D3 and D4
to the DA15 port.  Nor does it support U-Force, Power Glove, Miracle
Piano, or other hen's teeth.

Rescanning requires Reset primarily because hot-swapping can
occasionally cause a power sag that freezes the CPU.

Serial watch doesn't work correctly on controllers where the act of
reading a report itself has side effects.  These include the Arkanoid
controller, which resets a 555-family timer, and the Super NES Mouse,
which clears accumulated movement.  Reading controller 1 to choose a
port and bit also causes the other controller to be read.

Contact
-------
Let me know what you get.  My nick on the [EFnet] IRC network is
pino_p and I'm often seen in the #nesdev channel.  There is also a
topic for this test on NESdev BBS, titled [Riding the open bus].

[EFnet]: http://www.efnet.org/
[Riding the open bus]: https://forums.nesdev.com/viewtopic.php?f=2&t=12549

Legal
-----
The test program and its manual are distributed under the zlib license:

Copyright 2016 Damian Yerrick

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
