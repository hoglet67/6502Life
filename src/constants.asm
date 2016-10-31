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

PAN_POS         = &0008
PAN_NEG         = &10000 - PAN_POS

PATTERN_BASE    = 'A'
        
TYPE_PATTERN    = 1
TYPE_RLE        = 2
