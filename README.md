# 6502Life
Various 6502 machine code programs to experiment with Conway's Game of Life on the Acorn Atom, BBC Micro and Electron.

Use build.sh to build the programs and a disk image.

We're interested in different tactics to store the state, and to compute the next generation. We're interested in speed and in capacity. We're interested in running on a coprocessor, which is fast and has lots of RAM, and so we need efficient ways to update the display on the host machine.

There are numerous patterns to try here, as well as several programs, using one of three engines:
* ALIFE for the Acorn Atom, written by Laurence Hardwick and published by Acornsoft. Using a three-line buffer and with fast handling of zero bytes. One byte per 8 cells, plus overhead. A small universe, with the usual toroidal wrapping.
* BLIFEA for the BBC Micro, using the ALIFE algorithm.
* BLIFE for the BBC Micro, using a List Life algorithm derived from Tony Finch's code. Two bytes per live cell, plus overhead. Universe is 32k by 32k cells, with the edge cells emptied every 256 generations - no wrapping.
* BLIFE8 for the BBC Micro, using a List Life algorithm derived from an anonymous 1988 version. One byte per 8 cells, plus overhead, with zeros suppressed. Universe is 32k by 32k cells.
* MLIFE for a 1MByte 6502 second processor, using the BLIFE algorithm.
* Apple Life by Stephen Hawley aka plinth666, 1985, for reference only. Uses Change Lists.

The main development here is on a fast and large life, running on a 6502 second processor connected to an Acorn host machine. In the case of MLIFE, the second processor must offer banked memory. The user interface is as follows:
* Escape key - return to pattern-selection menu.
* Return - run a single generation
* Z - zoom in
* X - zoom out
* Cursor keys - increase or decrease panning speed
* Copy - reset pan speed to zero
* Tab - pan immediately to center of universe
* R - increase the rate (more generations for each screen update) cycling from 1x to 100x in ten steps and back to 1x.
* S - show or hide the user interface
* Space - toggle single-step/pause mode

The patterns available are at present:
* [R-Pentomino](http://conwaylife.com/wiki/R-pentomino)
* [Acorn](http://conwaylife.com/wiki/Acorn)
* [Diehard](http://conwaylife.com/wiki/Die_hard)
* [Rabbits](http://conwaylife.com/wiki/Rabbits)
* [Queen Bee](http://conwaylife.com/wiki/Queen_bee)
* [Bunnies 9](http://conwaylife.com/wiki/Bunnies_9)
* [Puff Suppressor](https://bitstorm.org/gameoflife/lexicon/#t3)
* [Spaceship](http://members.tip.net.au/~dbell/articles/life2.zip)
* [Glider](http://conwaylife.com/wiki/Glider)
* [Gosper Breeder 1](http://conwaylife.com/wiki/Breeder_1)
* [Blinker Ship 1](http://conwaylife.com/wiki/Blinker_ship_1)
* [Flying Wing](http://conwaylife.com/wiki/Flying_wing)
* [Pi Ship 1](http://conwaylife.com/wiki/Pi_ship_1)
* [Edna](http://conwaylife.com/wiki/Edna)
* [23334M](http://conwaylife.com/wiki/23334M)
* [40514M](http://conwaylife.com/wiki/40514M)
* [Half Max](http://conwaylife.com/wiki/Half_Max)
* [Stargate](http://conwaylife.com/wiki/Stargate)
* [Noah's Ark](http://conwaylife.com/wiki/Noah%27s_ark)
* [Turing Machine (35,149 cells)](http://conwaylife.com/wiki/Turing_machine)
* Random fill (three densities)

For more information, programs, discussion, and support, see the forum thread at
http://stardot.org.uk/forums/viewtopic.php?t=12010
