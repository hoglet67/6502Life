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

RLE_DST         = SCRN_BASE

GUARD             SCRN_BASE - 1

ELSE

DELTA_BASE      = &F600         ; 8 row buffer for accumulating delta

IF _MATCHBOX

BUFFER          = BUFFER1
BUFFER_END      = BUFFER2
RLE_BUF         = &E000
RLE_DST         = BUFFER1
SCRN_BASE       = &C000         ; base address of screen memory

GUARD             BUFFER1 - 1

ELSE
BUFFER          = &5000
BUFFER_END      = &F400         ; a multiple of &200 or RLE reader breaks
RLE_BUF         = (BUFFER + BUFFER_END) DIV 2
RLE_DST         = BUFFER
SCRN_BASE       = &3000         ; base address of screen memory

GUARD             SCRN_BASE - 1

ENDIF

ENDIF

ORG               &0400         ; base address of the code on the Beeb

include "constants.asm"

include "variables.asm"

include "macros_common.asm"

.start

JMP beeb_life

IF _MATCHBOX
include "banksel.asm"
ENDIF

include "utils.asm"

include "rle_utils.asm"

include "patterns.asm"

IF _ATOM_LIFE_ENGINE

include "macros_al.asm"
include "atom_life.asm"
include "rle_reader_al.asm"

ELIF _LIST8_LIFE_ENGINE

include "macros_l8.asm"
include "list8_life.asm"
include "rle_reader_l8.asm"

ELIF _LIST42_LIFE_ENGINE

include "macros_l42.asm"
include "list42_life.asm"
include "rle_reader_l42.asm"

ELSE

include "macros_ll.asm"
include "list_life.asm"
include "rle_reader_ll.asm"

ENDIF

include "beeb_wrapper.asm"

include "vdu_driver.asm"

.end

SAVE "",start, end
