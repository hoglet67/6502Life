;; ************************************************************
;; Macros
;; ************************************************************

include "macros_l8_l42.asm"

MACRO M_UPDATE_CHUNK_IF_EQUAL_TO_X ptr, chunk
        LDA (ptr)
        CMP xx
        BNE skip_inc
        LDA (ptr), Y
        CMP xx + 1
        BNE skip_inc
        INY
        LDA (ptr), Y
IF (chunk <> 0)
        STA chunk
ENDIF
        BEQ skip_add
        TAX
        CLC
        LDA lo, X
        ADC locnt_f
        STA locnt_f
        LDA hi, X
        ADC hicnt_f
        STA hicnt_f
.skip_add
        DEY
IF (ptr = next)
        M_INCREMENT_BY_3 ptr
ELSE
        M_INCREMENT_BY_3_NOSWITCH ptr
ENDIF
.skip_inc
ENDMACRO
