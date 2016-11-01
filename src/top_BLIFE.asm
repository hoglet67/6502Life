;; ************************************************************
;; Memory Map
;; ************************************************************
;; 0800 - 2000 code (VDU driver at the end)
        
        
        
CPU 1                           ; allow 65C02 opcodes

_ATOM           = FALSE

_ATOM_LIFE_ENGINE = FALSE

IF _ATOM_LIFE_ENGINE
        
ROWS_PER_SCREEN = &FE           ; Y resolution

wkspc0          = &3400         ; workspace 1 (temp copy of a screen row)
wkspc1          = &3500         ; workspace 2 (temp copy of a screen row)
wkspc2          = &3600         ; workspace 3 (temp copy of a screen row)
sum             = &3700         ; pixel accumulator
delta_base      = &3800         ; 8 row buffer for accumulating delta
gen_lo          = &3F00         ; generation counter
gen_hi          = &3F01         ; the C% integer variable on the Beeb
scrn_base       = &4000         ; base address of screen memory
        
ELSE

delta_base      = &0700         ; 8 row buffer for accumulating delta        
scrn_base       = &2000         ; base address of screen memory        
buffer2         = &2000         ; 2000-8BFF = 27K
buffer1         = &8C00         ; 8C00-F7FF = 27K        

ENDIF        

ORG               &0800         ; base address of the code on the Beeb
GUARD             &1E7F
        
include "constants.asm"
        
include "variables.asm"

include "macros.asm"
        
.start

JMP beeb_life        
                
include "utils.asm"

include "patterns.asm"

IF _ATOM_LIFE_ENGINE
include "atom_life.asm"
ELSE
include "list_life.asm"
include "rle_reader.asm"
ENDIF
        
include "beeb_wrapper.asm"

ORG               &1E80
GUARD             &1FFF

include "vdu_driver.asm"
        
.end

SAVE "",start, end
        
