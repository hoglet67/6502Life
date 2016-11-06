#include <stdio.h>
#include <stdlib.h>

#include "util.h"

#define MAX_SIZE 1000000

#define MAX_GEN 17400

#define ORIGIN 0x4000;

int buffer1[MAX_SIZE];
int buffer2[MAX_SIZE];


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

static int calculate_stats(int *ptr, int *size, int *pop) {
   *size = 0;
   *pop = 0;
   while (*ptr) {
      (*size) += 2; // coordinate is 2 bytes
      if (*ptr++ < 0) {
         (*pop)++;
      }
   }
}

void list_rle_reader(char *pattern, int *ptr) {
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
   *ptr++ = y;
   while (1) {
      c = *pattern++;
      if (c == 9 || c == 10 || c == 13 || c == 32) {
         continue;
      }
      if (c >= '0' && c <= '9') {
         count = count * 10 + (c - '0');
         continue;
      }
      if (c == 'b') {
         if (count == 0) {
            count = 1;
         }
         x += count;
         count = 0;
         continue;
      }
      if (c == 'o') {
         if (count == 0) {
            count = 1;
         }
         while (count--) {
            *ptr++ = x++;
         }
         count = 0;
         continue;
      }
      if (c == '$') {
         if (count == 0) {
            count = 1;
         }
         y -= count;
         *ptr++ = y;
         x = -ORIGIN;
         count = 0;
         continue;
      }
      if (c == '!') {
         *ptr++ = 0;
         break;
      }
      printf("Illegal character %c in rle\n", c);
   }
}

int list_life(int *this, int *new)
{
	unsigned bitmap;
	int *next, *prev;
	int x, y;
   int ops = 0;
	static enum {
		DEAD, LIVE
	} state[1 << 9];

	if(state[007] == 0) {
		for(bitmap = 0; bitmap < 1<<9; bitmap++) {
			for(x = y = 0; y < 9; y++)
				if(bitmap & 1<<y)
					x += 1;
			if(bitmap & 020) {
				if(x == 3 || x == 4)
					state[bitmap] = LIVE;
				else
					state[bitmap] = DEAD;
			} else {
				if(x == 3)
					state[bitmap] = LIVE;
				else
					state[bitmap] = DEAD;
			}
		}
}

	prev = next = this;
	bitmap = 0;
	*new = 0;
	for(;;) {
		/* did we write an X co-ordinate? */
		if(*new < 0)
			new++;
		if(prev == next) {
			/* start a new group of rows */
			if(*next == 0) {
				*new = 0;
				return ops;
			}
			y = *next++ + 1;
		} else {
			/* move to next row and work out which ones to scan */
			if(*prev == y--)
				prev++;
			if(*this == y)
				this++;
			if(*next == y-1)
				next++;
		}
		/* write new row co-ordinate */
		*new = y;
		for(;;) {
			/* skip to the leftmost cell */
			x = *prev;
			if(x > *this)
				x = *this;
			if(x > *next)
				x = *next;
			/* end of line? */
			if(x >= 0)
				break;
			for(;;) {
				/* add a column to the bitmap */
				if(*prev == x) {
					bitmap |= 0100;
					prev++;
				}
				if(*this == x) {
					bitmap |= 0200;
					this++;
				}
				if(*next == x) {
					bitmap |= 0400;
					next++;
				}
				/* what does this bitmap indicate? */
            ops++;
				if(state[bitmap] == LIVE)
					*++new = x - 1;
				else if(bitmap == 000)
					break;
				/* move right */
				bitmap >>= 3;
				x += 1;
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
   // .**
   // **.
   // .*.
   int pattern[] = { 12, -11, -10, 11, -12, -11, 10, -11, 0 };
#elif defined(PATTERN_BUNNIES)
   // bunnies 9
   // *.......
   // **.....*
   // ......*.
   // ......*.
   // .....*..
   // ....*...
   // ....*...
   int pattern[] = { 12, -12,
                  11, -12, -11, -5,
                  10, -6,
                   9, -6,
                   8, -7,
                   7, -8,
                   6, -8,
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
         list_rle_reader(rle_pattern, &buffer1[0]);
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

   do {
      calculate_stats(ptr1, &size, &pop);
      cells += pop;
      if ((gen % 100) == 0) {
         printf("gen %6d size %6d pop %6d efficiency (bytes / cell) %4.3f ops %8d\n", gen, size, pop, (double) size / (double) pop, ops);
      }
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
