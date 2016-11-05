;; ************************************************************
;; Memory Map
;; ************************************************************
;; 0800 - 2000 code (VDU driver at the end)

CPU 1                           ; allow 65C02 opcodes

_ATOM           = FALSE

IF _ATOM_LIFE_ENGINE

ROWS_PER_SCREEN = &FE           ; Y resolution

WKSPC0          = &3400         ; workspace 1 (temp copy of a screen row)
WKSPC1          = &3500         ; workspace 2 (temp copy of a screen row)
WKSPC2          = &3600         ; workspace 3 (temp copy of a screen row)
SUM             = &3700         ; pixel accumulator
DELTA_BASE      = &3800         ; 8 row buffer for accumulating delta
GEN_LO          = &3F00         ; generation counter
GEN_HI          = &3F01         ; the C% integer variable on the Beeb
SCRN_BASE       = &4000         ; base address of screen memory

BUFFER          = &6000
BUFFER_END      = &F800
        
ELSE

DELTA_BASE      = &0700         ; 8 row buffer for accumulating delta
SCRN_BASE       = &2000         ; base address of screen memory

BUFFER          = &4000
BUFFER_END      = &F800

ENDIF

ORG               &0800         ; base address of the code on the Beeb
GUARD             &1E7F

include "constants.asm"

include "variables.asm"

include "macros_common.asm"

.start

JMP beeb_life

include "utils.asm"

include "patterns.asm"

IF _ATOM_LIFE_ENGINE

include "macros_al.asm"
include "atom_life.asm"
include "rle_reader_al.asm"

ELIF _LIST8_LIFE_ENGINE

include "macros_l8.asm"
include "list8_life.asm"
include "rle_reader_l8.asm"

ELSE        

include "macros_ll.asm"
include "list_life.asm"
include "rle_reader_ll.asm"

ENDIF

include "beeb_wrapper.asm"

ORG               &1E80
GUARD             &1FFF

include "vdu_driver.asm"

.end

SAVE "",start, end
