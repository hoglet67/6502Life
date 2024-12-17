;; ************************************************************
;; Macros
;; ************************************************************

include "macros_l8_l42.asm"

;;				if(*ptr == x) {
;;             chunk = *(ptr + 1);
;;					ptr += 2;
;;          }

MACRO M_UPDATE_CHUNK_IF_EQUAL_TO_X ptr, chunk
        LDA (ptr)
        CMP xx
        BNE skip_inc
        LDA (ptr), Y
        CMP xx + 1
        BNE skip_inc
        INY
        LDA (ptr), Y
        STA chunk
        DEY
IF (ptr = this)
        M_INCREMENT_BY_3 ptr
ELSE
        M_INCREMENT_BY_3_NOSWITCH ptr
ENDIF
.skip_inc
ENDMACRO
