#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#include "util.h"

#define MAX_SIZE 1000000

#ifndef MAX_GEN
#define MAX_GEN 17400
#endif

#define ORIGIN 0x40000;

int buffer1[MAX_SIZE];
int buffer2[MAX_SIZE];

static unsigned char bitcnt[256*256];

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

/*
 * Tony Finch's list life maintains a list of ordinates, with one live cell each.
 *    It computes the future using a 3x3 neighbourhood of cells
 *    using a 512-value lookup table (512 bytes)
 *
 * life42 maintains a list of bytes, with 8 cells each, in a 4x2 patch
 *    It computes the future using a 2x2 neighbourhood of patches
 *    by arranging that the next is offset by (1,1)
 *    and using a 4k lookup table, 4 times, each time delivering a bitpair
 *
 * life44 maintains a list of byte pairs, with 16 cells each, in two 4x2 patches
 *    It computes the future using a 2x3 neighbourhood of patches
 *    by arranging that the next is offset by (1,1)
 *    and using a 4k lookup table, 6 times, each lookup giving one or two bitpairs
 *
 */

static void print_binary(int n, int start, int nbits) {
   int i;
   for (i = 0; i < nbits; i++) {
      if (n & (1 << (start - i))) {
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
            (*pop) += bitcnt[bitmap & 0xffff];
            (*size) += 2; /* two bytes at each ordinate in life44 */
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
   y_size = 1 + (y_top - y_bot) / 4;
   grid = (unsigned char *) malloc(x_size * y_size);

   gptr = &grid[0];
   for (i = 0; i < x_size * y_size; i++) {
      grid[i] = 0;
   }

   ptr = list;
   while (*ptr) {
      if (*ptr < 0) {
         x = *ptr++;
         grid[x_size * (y_top - y) / 4 + (x - x_left) / 4] = *ptr;
      } else {
         y = *ptr;
      }
      ptr++;  // Advance to next coordinate
   }

   for (y = 0; y < y_size; y++) {
      for (i = 0; i < 2; i++) {
         gptr = grid + y * x_size;
         for (x = 0; x < x_size; x++) {
            print_binary(*gptr++, 7 - 4 * i, 4);
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
   return ((upper & 0x0F) << 4) | ((lower & 0x0F) << 0);
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

int do_life(int cell, int neighbours) {
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

/*
 * Here's what a 3x2 neighbourhood of bytes looks like:
 *
 *   A7  A6  A5  A4   C7  C6
 *   A3  A2  A1  A0   C3  C2
 *
 *   B7  B6  B5  B4   D7  D6
 *   B3  B2  B1  B0   D3  D2
 *
 *   G7  G6  G5  G4   H7  H6
 *   G3  G2  G1  G0   H3  H2
 *
 * Note that we don't need to read both bytes of all neighbours.
 * Bytes A and B are from our upper left,
 * C and D from upper right
 * G from lower left
 * H from lower right
 *
 * For the first byte of output, we proceed as life42 does.
 * For the second byte, we go around again with 4 more lookups
 * But we note that two of those lookups use the same indices
 * and use different parts of the result byte.
 *
 */

// A7  A6  A5  A4  C7  C6
// A3  A2  A1  A0  C3  C2
// B7  B6  B5  B4  D7  D6
// B3  B2  B1  B0  D3  D2
//
// 4K lookup table, broken into page and index:
//
// X11 X10 X9 X8 <<< Page
//  X7  X6 X5 X4 <<< Index
//  X3  X2 X1 X0 <<< Index
//
// Upper Left  - produces bits (7) and [6]
//   B7  B6  B5  B4
//   A7  A4  A5  A4
//   A3 (A2)[A1] A0
//
// Upper Right - produces bits (5) and [4]
//   D7  D6  B5  B4
//   C7  C6  A5  A4
//  [C3] C2  A1 (A0)
//
// Lower Left  - produces bits (3) and [2]
//   A3  A2  A1  A0
//   B7 (B6)[B5] B4
//   B3  B2  B1  B0
//
// Lower Right - produces bits (1) and [0]
//   C3  C2  A1  A0
//  [D7] D6  B5 (B4)
//   D3  D2  B1  B0

#define CELLMASK7 0x004
#define CELLMASK6 0x002
#define CELLMASK5 0x001
#define CELLMASK4 0x008
#define CELLMASK3 0x040
#define CELLMASK2 0x020
#define CELLMASK1 0x010
#define CELLMASK0 0x080

#define NEIGHBOURMASK7 0xEEA
#define NEIGHBOURMASK6 0x775
#define NEIGHBOURMASK5 0xBBA
#define NEIGHBOURMASK4 0xDD5
#define NEIGHBOURMASK3 0xEAE
#define NEIGHBOURMASK2 0x757
#define NEIGHBOURMASK1 0xBAB
#define NEIGHBOURMASK0 0xD5D

static unsigned char table[1 << 12];

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
   for (i = 0; i < (1 << 12); i++) {
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

   for (i = 0; i < (1<<12); i++) {
      if ((i & 15) == 0) {
         printf("        EQUB ");
      }
      printf("&%02x", table[i]);
      if ((i & 15) == 15) {
         printf("\n");
      } else {
         printf(",");
      }
   }
   for (i = 0; i < 256*256; i++) {
      bitcnt[i] = FNbits2(i);
    }
}

int list_life(int *this, int *new)
{
   int *prev;
   int x, y;
   int ops = 0;
   unsigned short int ul, ur, ll, lr; /* hmm, better to model the whole tile or just each patch?? */
   unsigned short int newbmp;
   int page;
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
         y-=4;
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
            unsigned char ul0, ur0;
            unsigned char ul1, ur1;
            unsigned char ll0, lr0;
            unsigned char ll1, lr1;
            ul0 = ul & 0xff;
            ul1 = (ul>>8) & 0xff;
            ur0 = ur & 0xff;
            ur1 = (ur>>8) & 0xff;
            ll0 = ll & 0xff;
            ll1 = (ll>>8) & 0xff;
            lr0 = lr & 0xff;
            lr1 = (lr>>8) & 0xff;

#ifdef DEBUG_KERNEL
            printf("x = %d\n", x);
            printf("old neighbourhood:\n");
            print_binary(ul0, 7, 4);
            printf(" ");
            print_binary(ur0, 7, 2);
            printf("\n");
            print_binary(ul0, 3, 4);
            printf(" ");
            print_binary(ur0, 3, 2);
            printf("\n");

            print_binary(ul1, 7, 4);
            printf(" ");
            print_binary(ur1, 7, 2);
            printf("\n");
            print_binary(ul1, 3, 4);
            printf(" ");
            print_binary(ur1, 3, 2);
            printf("\n");

            print_binary(ll0, 7, 4);
            printf(" ");
            print_binary(lr0, 7, 2);
            printf("\n");
            print_binary(ll0, 3, 4);
            printf(" ");
            print_binary(lr0, 3, 2);
            printf("\n");
#endif

            /* what does this bitmap indicate? */
            ops++;

            /* first we process the upper patch, the first byte of the pair
             * the world looks like this:
             *   ul0  ur0   (vs the canonical ul ur
             *   ul1  ur1                     ll lr)
             */
            unsigned char newbmp0;
            newbmp0 = 0;
            /* UL table lookup, produces bits 7 and 6 */
            page = ul1 >> 4;
            index = ul0;
            newbmp0 |= table[(page << 8) | index] & 0xC0;
            /* LL table lookup, produces bits 3 and 2 */
            page = ul0 & 0x0F;
            index = ul1;
            newbmp0 |= table[(page << 8) | index] & 0x0C;
            /* UR table lookup, produces bits 5 and 4 */
            page = ((ur1 & 0xC0) | (ul1 & 0x30)) >> 4;
            index = (ur0 & 0xCC) | (ul0 & 0x33);
            newbmp0 |= table[(page << 8) | index] & 0x30;
            /* LR table lookup, produces bits 1 and 0 */
            page = (ur0 & 0x0C) | (ul0 & 0x03);
            index = (ur1 & 0xCC) | (ul1 & 0x33);
            newbmp0 |= table[(page << 8) | index] & 0x03;

            /* now we process the lower patch, the second byte of the pair
             * the world looks like this:
             *   ul1  ur1   (vs the canonical ul ur
             *   ll0  lr0                     ll lr)
             */
            unsigned char newbmp1;
            newbmp1 = 0;
            /* UL table lookup, produces bits 7 and 6 */
            page = ll0 >> 4;
            index = ul1;
            newbmp1 |= table[(page << 8) | index] & 0xC0;
            /* LL table lookup, produces bits 3 and 2 */
            page = ul1 & 0x0F;
            index = ll0;
            newbmp1 |= table[(page << 8) | index] & 0x0C;
            /* UR table lookup, produces bits 5 and 4 */
            page = ((lr0 & 0xC0) | (ll0 & 0x30)) >> 4;
            index = (ur1 & 0xCC) | (ul1 & 0x33);
            newbmp1 |= table[(page << 8) | index] & 0x30;
            /* LR table lookup, produces bits 1 and 0 */
            page = (ur1 & 0x0C) | (ul1 & 0x03);
            index = (lr0 & 0xCC) | (ll0 & 0x33);
            newbmp1 |= table[(page << 8) | index] & 0x03;

            newbmp = (newbmp1 << 8) | newbmp0;

#ifdef DEBUG_KERNEL
            printf("new bitmap:\n");
            print_binary(newbmp0, 7, 4);
            printf("\n");
            print_binary(newbmp0, 3, 4);
            printf("\n");
            print_binary(newbmp1, 7, 4);
            printf("\n");
            print_binary(newbmp1, 3, 4);
            printf("\n");
#endif

            if (newbmp) {
#ifdef DEBUG_KERNEL
               printf("new x = %d\n", x - 1);
               printf("new bmp = %04x\n", newbmp);
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

void main(int argc, char **argv) {

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

   int pattern[] = { 12, -11, 0x406C, 0};
#elif defined(PATTERN_BUNNIES)
   // bunnies 9
   // *... ....
   // **.. ...*
   // .... ..*.
   // .... ..*.
   // .... .*..
   // .... *...
   // .... *...
   // .... ....
   int pattern[] = {12, -11, 0x8C, -7, 0x2201,
                     8,            -7, 0x8048, 0};

#elif defined(PATTERN_MULTUM)
   // multum in parvo
   // .... ***.
   // ...* ..*.
   // ..*. ....
   // .*.. ....
   int pattern[] = {12, -11, 0x2401, -7, 0x00E2,
                     0};

#elif defined(PATTERN_DOOMED)
   // agar doomed by a virus
   // .**. **.* *.** .**. **.* *.**
   // .**. **.* *.** .**. **.* *.**
   // .... .... .... .... .... ....
   // .**. **.* *.** .**. **.* *.**

   // .**. **.* *.** .**. **.* *.**
   // .... .... .... .... .... ....
   // .**. **.* *.** ***. **.* *.**
   // .**. **.* *.** .**. **.* *.**

   // .... .... .... .... .... ....
   // .**. **.* *.** .**. **.* *.**
   // .**. **.* *.** .**. **.* *.**
   // .... .... .... .... .... ....

   int pattern[] = {20, -30, 0x0666, -26, 0x0DDD, -22, 0x0BBB, -18, 0x0666, -14, 0x0DDD, -10, 0x0BBB,
                    16, -30, 0x6660, -26, 0xDDD0, -22, 0xBBB0, -18, 0xE660, -14, 0xDDD0, -10, 0xBBB0,
                    12, -30, 0x6006, -26, 0xD00D, -22, 0xB00B, -18, 0x6006, -14, 0xD00D, -10, 0xB00B,
                     0};

#elif defined(PATTERN_ACORN)
   // acorn
   // ..*. ....
   // .... *...
   // .**. .***
   // .... ....
   int pattern[] = {12, -11, 0x6020, -7, 0x7008,
                     0};

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
