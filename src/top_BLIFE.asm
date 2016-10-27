_ATOM           = FALSE
        
rows_per_screen = &FE           ; Y resolution

scrn_base       = &4000         ; base address of screen memory

wkspc0          = &3400         ; workspace 1 (temp copy of a screen row)
wkspc1          = &3421         ; workspace 2 (temp copy of a screen row)
wkspc2          = &3442         ; workspace 3 (temp copy of a screen row)

sum             = &3463         ; pixel accumulator

gen_lo          = &1FFE         ; generation counter
gen_hi          = &1FFF         ; the C% integer variable on the Beeb

org               &2000         ; base address of the code on the Beeb

.start

include "atom_life.asm"

.end

SAVE "",start,end, update_screen
        
        
