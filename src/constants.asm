;; ************************************************************
;; Constants
;; ************************************************************

MODE            = 4

WRCVEC          = &020E
EVNTV           = &0220        

OSFIND          = &FFCE
OSBGET          = &FFD7
OSRDCH          = &FFE0
OSASCI          = &FFE3
OSWRCH          = &FFEE
OSWORD          = &FFF1
OSBYTE          = &FFF4

;; X/Y_ORIGIN is the centre of the coordinate system
;; RLE patterns are centred here
;; And this is also the centre of the viewport at the start
X_ORIGIN         = &C000         ; in the middle of the negative range
Y_ORIGIN         = &4000         ; in the middle of the positive range

;; X/Y_START is only used list_life_load_buffer() for old style patterns
;; Ideally we should get rid of this
IF _LIST8_LIFE_ENGINE        
X_START        = X_ORIGIN-&10   ; offset by half the screen width in bytes
ELSE 
X_START        = X_ORIGIN-&80   ; offset by half the screen width in pixels
ENDIF
Y_START        = Y_ORIGIN+&80   ; offset by half the screen width

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

MAX_ZOOM        = &06
DEFAULT_ZOOM    = &03
        
MODE_CONTINUOUS  = &00
MODE_SINGLE_STEP = &80        
DEFAULT_MODE = MODE_CONTINUOUS

COUNT_PRECISION = 3
        
