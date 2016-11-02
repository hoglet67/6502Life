;; ************************************************************
;; Constants
;; ************************************************************

MODE            = 4

WRCVEC          = &020E
        
OSFILE          = &FFDD        
OSRDCH          = &FFE0
OSWRCH          = &FFEE
OSWORD          = &FFF1
OSBYTE          = &FFF4

X_START         = &BFFF         ; in the middle of the negative range
Y_START         = &4000         ; in the middle of the positive range

PAN_POS         = &0001
PAN_NEG         = &10000 - PAN_POS

PATTERN_BASE    = 'A'
        
TYPE_PATTERN    = 1
TYPE_RLE        = 2
TYPE_RANDOM     = 3

CELLS_PER_BYTE  = &08           ; bits per cell, also bits per byte, do not change!
BYTES_PER_ROW   = &20           ; X resolution on the atom in CLEAR 4 is 256

        
