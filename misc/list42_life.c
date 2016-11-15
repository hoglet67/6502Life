#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#include "util.h"

#define MAX_SIZE 1000000

#define MAX_GEN 50000

#define ORIGIN 0x4000;

int buffer1[MAX_SIZE];
int buffer2[MAX_SIZE];

static unsigned char bitcnt[256];

//#define DEBUG_KERNEL

//#define DEBUG_PATTERN

/*!
 * \file life.c
 *
 * \brief An implementation of the Game of Life
 *
 * The Life universe is represented by an array containing the co-ordinates
 * of the live cells, organized as a sequence of rows. Each row is a Y value
 * followed by a sequence of X values. X and Y are distinguished from each
 * other by their sign. The array is terminated by a Y value of 0.
 *
 * Y values have the same sign as the terminator, so they are positive and X
 * values are negative. Y values are all greater than the terminator, so they
 * decrease in order to make the terminator sort last. X values are all less
 * than Y values, so they increase in order to make the Y value following the
 * line sort after the line.
 *
 * $Copyright: (C) 2003 Tony Finch <dot@dotat.at> $
 *
 * $dotat: things/life.c,v 1.7 2003/12/04 17:06:27 fanf2 Exp $
 */

/*!
 * \brief Compute the next generation of the Game of Life.
 * \param this The current state of the known universe.
 * \param new Where to put the replacement universe.
 * \note \c new must have three times the space used by \c this.
 */

static void print_binary(int n, int start, int nbits) {
   int i;
   for (i = 0; i < nbits; i++) {
      if (n & (1 << (start - 2 * i))) {
         printf("o");
      } else {
         printf(".");
      }
   }
}

static int calculate_stats(int *ptr, int *size, int *pop) {
   int bitmap;
   *size = 0;
   *pop = 0;
   while (*ptr) {
      (*size) += 2; // coordinate is 2 bytes
      if (*ptr++ < 0) {
         bitmap = *ptr++;
         if (bitmap) {
            (*pop) += bitcnt[bitmap & 0xff];
            (*size) ++;
         }
      }
   }
}

int dump_list(int generation, int *list) {
   int *ptr = list;
   int x;
   int y;
   int x_left = INT_MAX;
   int x_right = INT_MIN;
   int y_bot = INT_MAX;
   int y_top = INT_MIN;
   int i;
   int x_size;
   int y_size;
   unsigned char *grid;
   unsigned char *gptr;

   printf("generation %5d\n", generation);

   // Find the range of x and y coordinates
   while (*ptr) {
      if (*ptr < 0) {
         if (*ptr < x_left) {
            x_left = *ptr;
         }
         if (*ptr > x_right) {
            x_right = *ptr;
         }
         ptr++; // skip BMP
      } else if (*ptr > 0) {
         if (*ptr < y_bot) {
            y_bot = *ptr;
         }
         if (*ptr > y_top) {
            y_top = *ptr;
         }
      }
      ptr++; // point to next coordinate
   }
   printf("x_left = %d, x_right = %d, y_bot = %d, y_top = %d\n", x_left, x_right, y_bot, y_top);

   x_size = 1 + (x_right - x_left) / 4;
   y_size = 1 + (y_top - y_bot) / 2;
   grid = (unsigned char *) malloc(x_size * y_size);

   gptr = &grid[0];
   for (i = 0; i < x_size * y_size; i++) {
      grid[i] = 0;
   }

   ptr = list;
   while (*ptr) {
      if (*ptr < 0) {
         x = *ptr++;
         grid[x_size * (y_top - y) / 2 + (x - x_left) / 4] = *ptr;
      } else {
         y = *ptr;
      }
      ptr++;  // Advance to next coordinate
   }

   for (y = 0; y < y_size; y++) {
      for (i = 0; i < 2; i++) {
         gptr = grid + y * x_size;
         for (x = 0; x < x_size; x++) {
            print_binary(*gptr++, 7 - i, 4);
         }
         printf("\n");
      }
   }

   free(grid);
}

static int shift_bit(int **pthis, int *x, int bit) {
   static int shift_reg = 1;
   shift_reg <<= 1;
   shift_reg |= bit;
   if (shift_reg & 16) {
      shift_reg &= 15;
      if (shift_reg) {
         *(*pthis)++ = *x;
         *(*pthis)++ = shift_reg;
      }
      (*x) += 4;
      shift_reg = 1;
      return 1;
   } else {
      return 0;
   }
}

static int merge (int upper, int lower) {
   return
      ((upper & 0x08) << 4) | // bit 7
      ((lower & 0x08) << 3) | // bit 6
      ((upper & 0x04) << 3) | // bit 5
      ((lower & 0x04) << 2) | // bit 4
      ((upper & 0x02) << 2) | // bit 3
      ((lower & 0x02) << 1) | // bit 2
      ((upper & 0x01) << 1) | // bit 1
      ((lower & 0x01) << 0);  // bit 0
}


/* Stage one build a list containing 4x1 blocks */
static void list_rle_reader_stage1(char *pattern, int *this) {
   int c;
   int count = 0;
   int y = ORIGIN;
   int x = -ORIGIN;

   // Skip lines starting with #
   while (*pattern == '#') {
      pattern = skipline(pattern);
   }
      // Skip next line with x, y etc
   if (*pattern == 'x') {
      pattern = skipline(pattern);
   }

   // Start with y
   *this++ = y;
   while (1) {
      c = *pattern++;
      if (c == 9 || c == 10 || c == 13 || c == 32) {
         continue;
      }
      if (c >= '0' && c <= '9') {
         count = count * 10 + (c - '0');
         continue;
      }
      if (c == 'b' || c == 'o') {
         int bit = c == 'o';
         if (count == 0) {
            count = 1;
         }
         while (count > 0) {
            shift_bit(&this, &x, bit);
            count--;
         }
         continue;
      }
      if (c == '$') {
         while (!shift_bit(&this, &x, 0)); // flush any buffered bits
         if (count == 0) {
            count = 1;
         }
         y -= count;
         *this++ = y;
         x = -ORIGIN;
         count = 0;
         continue;
      }
      if (c == '!') {
         while (!shift_bit(&this, &x, 0)); // flush buffered bits
         *this++ = 0;
         break;
      }
      printf("Illegal character %c in rle\n", c);
   }
}

// Stage 2: Mmerge adjacent lines containing 4x1 blocks into lines containin 4x2 blocs
//
// We can only merge odd lines into even lines:
//
//    even AAAA BBBB   ===>  even AAAA BBBB 
//    odd  AAAA BBBB              AAAA BBBB
//
// The other cases are handled by passing with zeros:
//
//                           even 0000 0000
//    odd  AAAA BBBB   ===>       AAAA BBBB
//    even AAAA BBBB         even AAAA BBBB
//                                0000 0000
//
// Algorithm maintain two pointers into the list:
//    prev ----> row (N)
//    this ----> row (N - 1)
//
// Case 1: merge "0000" and "prev" (y must be odd)
// Case 2: merge "prev" and "this" (y must be even)
// Case 3: merge "prev" and "0000" (y must be even)

void list_rle_reader_stage2(int *this, int *new) {
   int *prev;
   int upper;
   int lower;
   int x;
   int y;
   prev = this;
   while (1) {
      y = *prev;
      // Test for terminator
      if (y == 0) {
         *new = 0;
         return;
      }
      // We need to advance "this" to the next line to know what to do
      if ((prev == this) && (y & 1) == 0) {
         this++;
         while (*this < 0) {
            this += 2;
         }
         continue;
      }
      // Determine which rows to scan
      if (prev == this) {
         // Case 1: merge "0000" and "prev" (y must be odd)
         *new++ = y + 1;
         // At this point, both "prev" and "this" are pointing to the same row
         // and it turns out to be more convenient to advance "this" so that
         // a single form of the scan row code can cope with all three cases.
         this++;
      } else {
         *new++ = y;
         // In both these cases we can "prev"
         prev++;
         if (y == *this + 1) {
            // Case 2: merge "prev" and "this" (y must be even)
            this++;
         } else {
            // Case 3: merge "prev" and "0000" (y must be even)
         }
      }
      // Scan rows, merging 4x1 blocks into 4x2 blocks
      while (1) {
         x = *prev;
         if (x > *this) {
            x = *this;
         }
         if (x >= 0) {
            break;
         }
         upper = lower = 0;
         if(*prev == x) {
            upper = *(prev + 1);
            prev += 2;
         }
         if(*this == x) {
            lower = *(this + 1);
            this += 2;
         }
         *new++ = x;
         *new++ = merge(upper, lower);
      }
      // Advance prev, as we only process each row once
      prev = this;      
   }
}

void list_rle_reader(char *pattern, int *buff1, int *buff2) {
   list_rle_reader_stage1(pattern, buff1);
   list_rle_reader_stage2(buff1, buff2);
}

int do_life(cell, neighbours) {
   int count = 0;
   while (neighbours) {
      if (neighbours & 1) {
         count++;
      }
      neighbours >>= 1;
   }
   if (cell) {
      if (count == 2 || count == 3) {
         return 1;
      } else {
         return 0;
      }
   } else {
      if (count == 3) {
         return 1;
      } else {
         return 0;
      }
   }
}

// Index:
// A7 A6 A5 A4 A3 A2 A1 A0 B7 B6 B5 B4 B3 B2 B1 B0 C7 C6 C5 C4 D7 D6 D5 D4
//  1  1  1  *  1  1  0  0  1  0  1  0  1  0  0  0  0  0  0  0  0  0  0  0
//  0  1  0  1  0  1  0  0  1  1  *  1  1  1  0  0  0  0  0  0  0  0  0  0
//  0  0  1  1  1  *  1  1  0  0  1  0  1  0  1  0  0  0  0  0  0  0  0  0
//  0  0  0  1  0  1  0  1  0  0  1  1  *  1  1  1  0  0  0  0  0  0  0  0
//  0  0  0  0  1  1  1  *  0  0  0  0  1  0  1  0  1  1  0  0  1  0  0  0
//  0  0  0  0  0  1  0  1  0  0  0  0  1  1  *  1  0  1  0  0  1  1  0  0
//  0  0  0  0  0  0  1  1  0  0  0  0  0  0  1  0  1  *  1  1  1  0  1  0
//  0  0  0  0  0  0  0  1  0  0  0  0  0  0  1  1  0  1  0  1  *  1  1  1
#define CELLMASK7 0x100000
#define CELLMASK6 0x002000
#define CELLMASK5 0x040000
#define CELLMASK4 0x000800
#define CELLMASK3 0x010000
#define CELLMASK2 0x000200
#define CELLMASK1 0x000040
#define CELLMASK0 0x000008

#define NEIGHBOURMASK7 0xECA800
#define NEIGHBOURMASK6 0x54DC00
#define NEIGHBOURMASK5 0x3B2A00
#define NEIGHBOURMASK4 0x153700
#define NEIGHBOURMASK3 0x0E0AC8
#define NEIGHBOURMASK2 0x050D4C
#define NEIGHBOURMASK1 0x0302BA
#define NEIGHBOURMASK0 0x010357

static unsigned char table[1 << 24];

static int FNbits2(int x) {
   if (x < 2) {
      return x;
   } else {
      return (x & 1) + FNbits2(x >> 1);
   }
}

void init_table()
{
   int i;
   int bit7;
   int bit6;
   int bit5;
   int bit4;
   int bit3;
   int bit2;
   int bit1;
   int bit0;
   for (i = 0; i < (1 << 24); i++) {
      bit7 = do_life(i & CELLMASK7, i & NEIGHBOURMASK7);
      bit6 = do_life(i & CELLMASK6, i & NEIGHBOURMASK6);
      bit5 = do_life(i & CELLMASK5, i & NEIGHBOURMASK5);
      bit4 = do_life(i & CELLMASK4, i & NEIGHBOURMASK4);
      bit3 = do_life(i & CELLMASK3, i & NEIGHBOURMASK3);
      bit2 = do_life(i & CELLMASK2, i & NEIGHBOURMASK2);
      bit1 = do_life(i & CELLMASK1, i & NEIGHBOURMASK1);
      bit0 = do_life(i & CELLMASK0, i & NEIGHBOURMASK0);
      table[i] = (bit7 << 7) | (bit6 << 6) | (bit5 << 5) | (bit4 << 4) |
                 (bit3 << 3) | (bit2 << 2) | (bit1 << 1) | (bit0 << 0);
   }
   for (i = 0; i < 256; i++) {
      bitcnt[i] = FNbits2(i);
    }
}

int list_life(int *this, int *new)
{
	int *prev;
	int x, y;
   int ops = 0;
   unsigned char ul, ur, ll, lr;
   unsigned char newbmp;
   int index;

	prev = this;
	ul = ur = ll = lr = 0;
	*new = 0;
	for(;;) {
		/* did we write an X co-ordinate? */
		if(*new < 0)
			new+=2;
		if(prev == this) {
			/* start a new group of rows */
			if(*this == 0) {
				*new = 0;
				return ops;
			}
			y = *this++;
		} else {
			/* move to next row and work out which ones to scan */
			if(*prev == y)
				prev++;
         y-=2;
			if(*this == y)
				this++;
		}
      //printf("y=%d\n", y);
		/* write new row co-ordinate */
		*new = y + 1;
#ifdef DEBUG_KERNEL
      printf("new y = %d\n", y + 1);
#endif
		for(;;) {
			/* skip to the leftmost cell */
			x = *prev;
			if(x > *this)
				x = *this;
			/* end of line? */
			if(x >= 0)
				break;
         //printf("x=%d\n", x);

			for(;;) {
            ur = lr = 0;
				/* add a column to the bitmap */
				if(*prev == x) {
               ur = *(prev + 1);
					prev += 2;
            }
				if(*this == x) {
               lr = *(this + 1);
					this += 2;
				}
            if ((ul | ur | ll | lr) == 0) {
					break;
            }

#ifdef DEBUG_KERNEL
            printf("x = %d\n", x);
            print_binary(ul, 7, 4);
            print_binary(ur, 7, 2);
            printf("\n");
            print_binary(ul, 6, 4);
            print_binary(ur, 6, 2);
            printf("\n");
            print_binary(ll, 7, 4);
            print_binary(lr, 7, 2);
            printf("\n");
            print_binary(ll, 6, 4);
            print_binary(lr, 6, 2);
            printf("\n");
#endif
				/* what does this bitmap indicate? */
            ops++;
            /* big table lookup */
            index = (ul << 16) | (ll << 8) | (ur & 0xf0) | (lr >> 4);
            newbmp = table[index];
#ifdef DEBUG_KERNEL
            print_binary(newbmp, 7, 4);
            printf("\n");
            print_binary(newbmp, 6, 4);
            printf("\n");
#endif

            if (newbmp) {
#ifdef DEBUG_KERNEL
               printf("new x = %d\n", x - 1);
               printf("new bmp = %02x\n", newbmp);
#endif
               if (*new < 0) {
                  // last coordinate was an X 
                  new += 2;
               } else {
                  // last coordinate was a Y
                  new += 1;
               }
					*new = x - 3;
					*(new + 1) = newbmp;
            }
				/* move right */
            ul = ur;
            ll = lr;
				x += 4;
			}
		}
	}
}

int main(int argc, char **argv) {

   int i;
   int pop;
   int size;
   char *rle_pattern;
   int ops = 0;
   int cells = 0;

#if defined(PATTERN_RPENTOMINO)
   // r-pentomino
   // .**.
   // **..
   // .*..
   // ....

   int pattern[] = { 12, -11, 0x78, 10, -11, 0x20, 0};
#elif defined(PATTERN_BUNNIES)
   // bunnies 9
   // *.......
   // **.....*
   // ......*.
   // ......*.
   // .....*..
   // ....*...
   // ....*...
   int pattern[] = {12, -11, 0xD0, -7, 0x01, 10, -7, 0x0C, 8, -7, 0x60, 6, -7, 0x80, 0 };

#else
   int pattern[] = {0};
#endif
   
   int *tmp;
   int *ptr1 = &pattern[0];
   int *ptr2 = &buffer1[0];
   
   if (pattern[0] == 0) {
      if (argc < 2) {
         printf("No pattern defined, exiting\n");
         return;
      }
      if (rle_pattern = readfile(argv[1])) {
         list_rle_reader(rle_pattern, &buffer2[0], &buffer1[0]);
         free(rle_pattern);
      } else {
         printf("%s not found, exiting\n", argv[1]);
         return;
      }                 
   } else {
      // Copy the test pattern into the buffer 1
      int coord = 0;
      do {
         coord = *ptr1++;
         if (coord < 0) {
            *ptr2++ = coord - ORIGIN;
         } else if (coord > 0) {
            *ptr2++ = coord + ORIGIN;
         } else {
            *ptr2++ = coord;
         }
      } while (coord != 0);
   }

   int gen = 0;

   ptr1 = &buffer1[0];
   ptr2 = &buffer2[0];
   
   printf("Building table\n");
   init_table();
   printf("Building table done\n");

   do {
      calculate_stats(ptr1, &size, &pop);
      cells += pop;
      if ((gen % 100) == 0) {
         printf("gen %6d size %6d pop %6d efficiency (bytes / cell) %4.3f ops %8d\n", gen, size, pop, (double) size / (double) pop, ops);
      }
#ifdef DEBUG_PATTERN
      dump_list(gen, ptr1);
#endif
      ops += list_life(ptr1, ptr2);
      gen++;
      tmp = ptr1;
      ptr1 = ptr2;
      ptr2 = tmp;
   } while ((gen <= MAX_GEN) && (pop > 0));
   printf("Final ops = %8d\n", ops);
   printf("Final cells = %8d\n", cells);
   printf("Avergage cells/gen = %8.3f\n", (double) cells / (double) gen);
}
