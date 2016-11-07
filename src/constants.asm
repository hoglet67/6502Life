;; ************************************************************
;; Constants
;; ************************************************************

MODE            = 4

WRCVEC          = &020E
EVNTV           = &0220        

OSFILE          = &FFDD        
OSRDCH          = &FFE0
OSWRCH          = &FFEE
OSWORD          = &FFF1
OSBYTE          = &FFF4

X_START         = &C000         ; in the middle of the negative range
Y_START         = &4000         ; in the middle of the positive range

IF _LIST8_LIFE_ENGINE        
X_ORIGIN        = X_START+&10   ; offset by half the screen width in bytes
ELSE 
X_ORIGIN        = X_START+&80   ; offset by half the screen width in pixels
ENDIF

Y_ORIGIN        = Y_START-&80  ; offset by half the screen width

PAN_POS         = &0001
PAN_NEG         = &10000 - PAN_POS

PATTERN_BASE    = 'A'
        
TYPE_PATTERN    = 1
TYPE_RLE        = 2
TYPE_RANDOM     = 3

CELLS_PER_BYTE  = &08           ; bits per cell, also bits per byte, do not change!
BYTES_PER_ROW   = &20           ; X resolution on the atom in CLEAR 4 is 256

SHOW_GEN        = &01
SHOW_CELLS      = &02
SHOW_REF        = &04
SHOW_MASK       = &07        
DEFAULT_SHOW    = SHOW_GEN + SHOW_CELLS + SHOW_REF

DEFAULT_RATE    = 0

MODE_CONTINUOUS  = &00
MODE_SINGLE_STEP = &80        
DEFAULT_MODE = MODE_CONTINUOUS

COUNT_PRECISION = 3
        
