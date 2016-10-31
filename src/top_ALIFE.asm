_ATOM           = TRUE
        
scrn_base       = &8000         ; base address of screen memory

wkspc0          = &3400         ; workspace 1 (temp copy of a screen row)
wkspc1          = &3421         ; workspace 2 (temp copy of a screen row)
wkspc2          = &3442         ; workspace 3 (temp copy of a screen row)

sum             = &3463         ; pixel accumulator

gen_lo          = &0324         ; generation counter
gen_hi          = &0340         ; the C integer variable on the Atom
                                ; &340 should be &33F (bug in the original code)
step            = &032A         ; if zero, then just calculate one generation then return
                                ; the I integer variable on the Atom

pia2            = &B002         ; 8255 on the Atom, for detecting the REPT key
pia1            = &B001         ; 8255 on the Atom, for detecting the SHIFT and CTRL keys

rows_per_screen = &BE           ; Y resolytion on the Atom in CLEAR 4 is 192

org               &2980         ; base address of the code on the Atom

include "variables.asm"
        
.start

include "atom_life.asm"

.end

SAVE "",start,end
