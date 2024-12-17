#!/bin/bash

#pattern=PATTERN_RPENTOMINO
#pattern=PATTERN_BUNNIES
pattern=PATTERN_RLE

CFLAGS=-O3

max=1000

gcc ${CFLAGS} -DMAX_GEN=${max} -D${pattern}  list_life.c util.c -o  list_life
gcc ${CFLAGS} -DMAX_GEN=${max} -D${pattern} list8_life.c util.c -o list8_life
gcc ${CFLAGS} -DMAX_GEN=${max} -D${pattern} list42_life.c util.c -o list42_life
gcc ${CFLAGS} -DMAX_GEN=${max} -D${pattern} list44_life.c util.c -o list44_life
gcc ${CFLAGS} -DMAX_GEN=${max} -DWIDTH16 -D${pattern} list8_life.c util.c -o list16_life
