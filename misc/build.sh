#!/bin/bash

#pattern=PATTERN_RPENTOMINO
#pattern=PATTERN_BUNNIES9
pattern=PATTERN_RLE

gcc -g -D${pattern} list8_life.c util.c -o list8_life
gcc -g -D${pattern}  list_life.c util.c -o  list_life
