;; ************************************************************
;; Memory Map
;; ************************************************************
;; 0800 - 2000 code (VDU driver at the end)

CPU 1                           ; allow 65C02 opcodes

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

IF _LIST8_LIFE_ENGINE

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
