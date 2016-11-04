#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#include "util.h"

#define MAX_SIZE 1000000

#define MAX_GEN 50000

#define ORIGIN 0x4000

#define MAX_LINE 10000

// #define DEBUG_KERNEL


static int buffer1[MAX_SIZE];
static int buffer2[MAX_SIZE];

static unsigned char lo[256];
static unsigned char hi[256];
static unsigned char ltsum[256];
static unsigned char rtsum[256];
static unsigned char ltmsk[256];
static unsigned char rtmsk[256];
static unsigned char bitcnt[256];

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

static int FNbits(int x) {
   if (x < 4) {
      return x;
   } else {
      return (x & 3) + FNbits(x >> 2);
   }
}

static int FNstretch(int x) {
   if (x < 2) {
      return x;
   } else {
      return (x & 1) + 4 * FNstretch(x >> 1);
   }
}

static int FNbits2(int x) {
   if (x < 2) {
      return x;
   } else {
      return (x & 1) + FNbits2(x >> 1);
   }
}

static void dump_table(char *name, unsigned char *table) {
   int i;
   printf(".%s\n", name);
   for (i = 0; i < 256; i++) {
      if ((i % 16) == 0) {
         printf(" EQUB ");
      }
      printf("&%02x", table[i]);
      if ((i % 16) < 15) {
         printf(",");
      } else {
         printf("\n");
      }
   }
   printf("\n");
}

static void dump_tables() {
   dump_table("ltsum", ltsum);
   dump_table("rtsum", rtsum);
   dump_table("ltmsk", ltmsk);
   dump_table("rtmsk", rtmsk);
   dump_table("lo", lo);
   dump_table("hi", hi);
   dump_table("bitcnt", bitcnt);
}

static void print_binary(int n) {
   int i;
   for (i = 7; i >= 0; i--) {
      if (n & (1 << i)) {
         printf("o");
      } else {
         printf(".");
      }
   }
}

int dump_list(int generation, int *list) {
   int *ptr = list;
   int x;
   int y;
   int x_left = INT_MAX;
   int x_right = INT_MIN;
   int i;
   printf("generation %5d\n", generation);

   // Find the range of x coordinates
   while (*ptr) {
      if (*ptr < 0) {
         if (*ptr < x_left) {
            x_left = *ptr;
         }
         if (*ptr > x_right) {
            x_right = *ptr;
         }
         ptr++; // skip BMP
      }
      ptr++; // point to next coordinate
   }
   x_right++;
   printf("x_left = %d, x_right = %d", x_left, x_right);

   ptr = list;
   x = x_right;
   y = *ptr;             
   while (*ptr) {
      if (*ptr < 0) {
         // X Coordinate
         // Add any necessary padding
         while (x < *ptr) {
            print_binary(0);
            x++;
         }
         ptr++; // Advance to bitmap
         print_binary(*ptr);
         x++;
      } else {
         // Complete the current line
         while (x < x_right) {
            print_binary(0);
            x++;
         }
         printf("\n");
         // Skip any blank lines
         while (y > *ptr) {
            printf("%5d ", y);
            x = x_left;
            while (x < x_right) {
               print_binary(0);
               x++;
            }         
            printf("\n");
            y--;
         } 
         // Start the next line
         printf("%5d ", y);
         x = x_left;
         y--;
      }
      ptr++;  // Advance to next coordinate
   }
   // Pad the last line
   while (x < x_right) {
      print_binary(0);
      x++;
   }
   printf("\n");
}

static int calculate_stats(int *ptr, int *size, int *pop) {
   *size = 0;
   *pop = 0;
   while (*ptr) {
      (*size)++;
      if (*ptr++ < 0) {
         (*pop) += bitcnt[*ptr++];
      }
   }
}

void list_rle_reader(char *pattern, int *ptr) {
   int c;
   int count = 0;
   int y = ORIGIN;
   int x = 0;
   char line[MAX_LINE];
   int i;
   int j;
   int len;
   int bitmap;

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
         while (count--) {
            line[x++] = 0;
         }
         count = 0;
         continue;
      }
      if (c == 'o') {
         if (count == 0) {
            count = 1;
         }
         while (count--) {
            line[x++] = 1;
         }
         count = 0;
         continue;
      }
      if ((c == '$')  || (c == '!')) {
         // Pad line to a multiple of 8
         while (x % 8) {
            line[x++] = 0;
         }
         // Compress the line into blocks
         len = x;
         x = 0;
         for (i = 0; i < len; i += 8) {
            bitmap = 0;
            for (j = i; j < i + 8; j++) {
               bitmap = (bitmap << 1) | line[j];
            }
            if (bitmap) {
               *ptr++ = -ORIGIN + x;
               *ptr++ = bitmap;
            }
            x++;
         }
         if (c == '!') {
            *ptr++ = 0;
            break;
         } else {
            if (count == 0) {
               count = 1;
            }
            y -= count;
            *ptr++ = y;
            x = 0;
            count = 0;
            continue;
         }
      }
      printf("Illegal character %c in rle\n", c);
   }
}

void list8_life_init() {
   int y;
   int a;
   int b;
   for (y = 0; y < 256; y++) {
      a = FNbits((y & 0x03) | ((y & 0xf0) >> 2));
      b = FNbits(y >> 2);
      ltsum[y] = ((a == 3) ? 8 : 0) + ((b == 3) ? 4 : 0);
      ltmsk[y] = ((a == 4) ? 8 : 0) + ((b == 4) ? 4 : 0);
      a = FNbits((y & 0x0f) | ((y & 0xc0) >> 2));
      b = FNbits(y & 0x3f);
      rtsum[y] = ((a == 3) ? 1 : 0) + ((b == 3) ? 2 : 0);
      rtmsk[y] = ((a == 4) ? 1 : 0) + ((b == 4) ? 2 : 0);
      lo[y] = FNstretch(y & 0x0f);
      hi[y] = FNstretch(y >> 4);
      bitcnt[y] = FNbits2(y);
   }
}

void list8_life(int *this, int *new)
{
	int *next, *prev;
	int x, y;

   unsigned char rearprev, middprev, foreprev;
   unsigned char rearthis, middthis, forethis;
   unsigned char rearnext, middnext, forenext;
   unsigned char locnt_r, hicnt_m, locnt_m, hicnt_f, outcome, mask, newbmp;

	prev = next = this;

   rearprev = middprev = foreprev = 0;
   rearthis = middthis = forethis = 0;
   rearnext = middnext = forenext = 0;

	*new = 0;

	for(;;) {
		/* did we write an X co-ordinate? */
		if(*new < 0)
			new += 2;
		if(prev == next) {
			/* start a new group of rows */
			if(*next == 0) {
				*new = 0;
				return;
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
#ifdef DEBUG_KERNEL
      printf("new y = %d\n", y);
#endif
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
            foreprev = 0;
            forethis = 0;
            forenext = 0;
				if(*prev == x) {
               foreprev = *++prev;
					prev++;
				}
				if(*this == x) {
               forethis = *++this;
					this++;
				}
				if(*next == x) {
               forenext = *++next;
					next++;
				}
            /* life88 kernel */

#ifdef DEBUG_KERNEL
            printf("x = %d\n", x);
            print_binary(rearprev);
            printf(" ");
            print_binary(middprev);
            printf(" ");
            print_binary(foreprev);
            printf("\n");
            print_binary(rearthis);
            printf(" ");
            print_binary(middthis);
            printf(" ");
            print_binary(forethis);
            printf("\n");
            print_binary(rearnext);
            printf(" ");
            print_binary(middnext);
            printf(" ");
            print_binary(forenext);
            printf("\n");
#endif

            locnt_r = lo[rearprev];
            hicnt_m = hi[middprev];
            locnt_m = lo[middprev];
            hicnt_f = hi[foreprev];

            locnt_r += lo[rearthis];
            hicnt_m += hi[middthis];
            locnt_m += lo[middthis];
            hicnt_f += hi[forethis];

            locnt_r += lo[rearnext];
            hicnt_m += hi[middnext];
            locnt_m += lo[middnext];
            hicnt_f += hi[forenext];

            outcome =
               (ltsum[(hicnt_m & 0xfc) | (locnt_r & 0x03)] << 4) |
               (rtsum[(locnt_m & 0xc0) | (hicnt_m & 0x3f)] << 4) |
               (ltsum[(locnt_m & 0xfc) | (hicnt_m & 0x03)]     ) |
               (rtsum[(hicnt_f & 0xc0) | (locnt_m & 0x3f)]     );

            mask =
               (ltmsk[(hicnt_m & 0xfc) | (locnt_r & 0x03)] << 4) |
               (rtmsk[(locnt_m & 0xc0) | (hicnt_m & 0x3f)] << 4) |
               (ltmsk[(locnt_m & 0xfc) | (hicnt_m & 0x03)]     ) |
               (rtmsk[(hicnt_f & 0xc0) | (locnt_m & 0x3f)]     );
               
            newbmp = (middthis & mask) | outcome;

#ifdef DEBUG_KERNEL
            print_binary(newbmp);
            printf("\n");
#endif

				/* what does this bitmap indicate? */
				if(newbmp) {
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
					*new = x - 1;
					*(new + 1) = newbmp;
            }
            else if(middprev==0 && middthis==0 && middnext==0
                    && foreprev==0 && forethis==0 && forenext==0) break;
				/* move right */
            rearprev = middprev; middprev = foreprev;
            rearthis = middthis; middthis = forethis;
            rearnext = middnext; middnext = forenext;
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

   list8_life_init();
   // dump_tables();

#if defined(PATTERN_RPENTOMINO)
   // r-pentomino
   // .**
   // **.
   // .*.
   int pattern[] = { 12, -8, 0x60, 11, -8, 0xc0, 10, -8, 0x40, 0}; 
#elif defined(PATTERN_BUNNIES)
   // bunnies 9
   // *.......
   // **.....*
   // ......*.
   // ......*.
   // .....*..
   // ....*...
   // ....*...
   int pattern[] = {
      12, -8, 0x80,
      11, -8, 0xc1,
      10, -8, 0x02,
      9, -8, 0x02,
      8, -8, 0x04,
      7, -8, 0x08,
      6, -8, 0x08,
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
      // Copy the pattern into the buffer 1
      int coord = 0;
      do {
         coord = *ptr1++;
         if (coord < 0) {
            *ptr2++ = coord - ORIGIN;    // x-coord
            *ptr2++ = *ptr1++;           // bitmap
         } else if (coord > 0) {
            *ptr2++ = coord + ORIGIN;    // y-coord
         } else {
            *ptr2++ = coord;             // terminator
         }
      } while (coord != 0);
   }

   int gen = 0;

   ptr1 = &buffer1[0];
   ptr2 = &buffer2[0];

   do {
      calculate_stats(ptr1, &size, &pop);
      //dump_list(gen, ptr1);
      if ((gen % 100) == 0) {
         printf("gen %6d size %6d pop %6d efficiency %4.3f\n", gen, size, pop, (double) pop / (double) size);
      }
      list8_life(ptr1, ptr2);
      gen++;
      tmp = ptr1;
      ptr1 = ptr2;
      ptr2 = tmp;

   } while ((gen <= MAX_GEN) && (pop > 0));
}
