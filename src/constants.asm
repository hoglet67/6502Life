;; ************************************************************
;; Constants
;; ************************************************************

MODE = 4

wrcvec          = &020E
        
OSWORD          = &FFF1
OSBYTE          = &FFF4
OSWRCH          = &FFEE
OSRDCH          = &FFE0

X_START = &BFFF                 ; in the middle of the negative range
Y_START = &4000                 ; in the middle of the positive range

PAN_POS = &0008

PAN_NEG = &10000 - PAN_POS
