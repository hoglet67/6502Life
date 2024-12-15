# Algorithm

The List Life algorithm is a direct translation to 6502 assembler of
a 2003 C implementation by Tony Finch:

https://dotat.at/prog/life/life.html

https://github.com/hoglet67/6502Life/blob/master/misc/list_life.c

# Data Structures

The Life universe is represented by an array containing the
coordinates of the live cells, organized as a sequence of rows. Each
row is a Y value followed by a sequence of X values. X and Y are
distinguished from each other by their sign. The array is terminated
by a Y value of 0.
```
<Y> <X> <X> <X> ...
...
<Y> <X> <X> <X> ...
<0>
```
Y values have the same sign as the terminator, so they are positive
and X values are negative. Y values are all greater than the
terminator, so they decrease in order to make the terminator sort
last. X values are all less than Y values, so they increase in order
to make the Y value following the line sort after the line.

<X> is in the range -32768 to -1 (left to right)

<Y> is in the range 32767 to 1 (top to bottom)

Both X and Y are stored as 16-bit twos-complement integers, stored in
little endian order with the LSB at an even address. Consequently a
coordianate will never straddle a page boundary.

The list data structures are generally traversed sequentially
(i.e. left to right, top to bottom)

# Memory usage

The implementation uses two logical buffers:
- one for the current generation that is read sequentially
- one for the new generation that is written sequentially

There are three pointers into the current generation (prev, this and
next) that point to three successive <X> coordinates in a row.

There is just one pointer into the new generation, tracking the end of
the list. New cells are only ever appended to the end.

## BLIFE Memory Layout

The BLIFE program uses a single block of memory from &5000-&F5FF
(BUFFER and BUFFER_END in common_BLIFE.asm). This works as a circular
buffer, so pointers wrap from the end back to the beginning again.

The initial pattern is loaded into the start of this buffer. The new
generation is then constructed immediately following this

Once the new generation is complete, it becomes the current
generation and the process continues.

Wrapping is at the end of the buffer happens transparently (by the
macro which increments a pointer).

Patterns of approx 20,000 cells are possible with this layout.

There is not currently any detection of overflow.

## MLIFE Memory Layout

The MLIFE program uses banked memory provided by some 6502 Co
Processor implementations (specifically the Matchbox FPGA and
PiTubeDirect) to support much larger patterns.

Note, this banked memory is not currently implemented by any of the
software emulators, so you can only run MLIFE on real hardware.

The banked memory operates in 8K pages:

The implemenation uses two buffers in logical memory:
- BUFFER1: &4000-&7FFF (two 8K pages)
- BUFFER2: &8000-&BFFF (two 8K pages)

The initial pattern (generation 1) is loaded into BUFFER1 and new
generation (generaton 2) is constructed in BUFFER2.  Once complete,
BUFFER2 becomes current generation, and the new generation (generation
3) is constructed in BUFFER1. This process continues,

Although BUFFER1 and BUFFER2 each occupy 16KB of logical memory, are
in fact backed by a much larger amount of physical memory:

- BUFFER1 is backed by 64x 8K pages (512KB total, physical pages 0x80-0xBF)
- BUFFER2 is backed by 64x 8K pages (512KB total, physical pages 0xC0-0xFF)

[ this allocation may soon change to BUFFER1 = even, BUFFER2 = odd pages ]

A 512KB buffer allows patterns of approx 250,000 cells.

There is not currently any detection of overflow, though this would be
trivial to add.

The scheme for remapping the pages as the data structures are
traversed is surprisingly simple and relies on the sequential access
pattern of list life.

The List Life implementation (src/list_life.asm) operates within the
16KB circular buffers and has no awareness of bank switching. Whenever
a pointer is incremented and an 8K page boundary is crossed, a call is
made from list_life to a function called cycle_banksel_buffers
(src/banksel.asm). This function does two things:

1. It ensures the pointer wraps with the 16KB logical buffer.

2. It updates the appropriate bank select register to page in the next
seqential page.

There is one further subtlty here. Recall there are three pointers
into the current generation (called prev/this/next) and one pointer
into the new generation (called new).

When traversing the current generation data structure, the "next"
pointer is always the first to cross an 8K page boundary. It's
important that only the "next" (and "new") pointers trigger the page
swapping behaviour. Further, the "prev" and "this" pointers must still
access the the previous page. This is achieved by making the BUFFER1/2
16KB (two pages) rather than 8KB (one page).



