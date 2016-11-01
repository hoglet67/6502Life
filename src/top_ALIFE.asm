_ATOM           = TRUE
        
SCRN_BASE       = &8000         ; base address of screen memory

WKSPC0          = &3400         ; workspace 1 (temp copy of a screen row)
WKSPC1          = &3421         ; workspace 2 (temp copy of a screen row)
WKSPC2          = &3442         ; workspace 3 (temp copy of a screen row)

SUM             = &3463         ; pixel accumulator

GEN_LO          = &0324         ; generation counter
GEN_HI          = &0340         ; the C integer variable on the Atom
                                ; &340 should be &33F (bug in the original code)
STEP            = &032A         ; if zero, then just calculate one generation then return
                                ; the I integer variable on the Atom

PIA2            = &B002         ; 8255 on the Atom, for detecting the REPT key
PIA1            = &B001         ; 8255 on the Atom, for detecting the SHIFT and CTRL keys

ROWS_PER_SCREEN = &BE           ; Y resolytion on the Atom in CLEAR 4 is 192

org               &2980         ; base address of the code on the Atom

include "constants.asm"
include "variables.asm"
        
.start

include "atom_life.asm"

.end

SAVE "",start,end
