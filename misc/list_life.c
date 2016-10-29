#include <stdio.h>

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
void
life(int *this, int *new)
{
	unsigned bitmap;
	int *next, *prev;
	int x, y;
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


int main() {

   int i;

   int this[] = { 12, -11, -10, 11, -12, -11, 10, -11, 0 };


   int new[100];


   life(this, new);

   i = -1;
   do {
      i++;
      printf("%d\n", new[i]);
   } while (new[i] != 0);

}
