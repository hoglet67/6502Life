;; ************************************************************
;; Macros
;; ************************************************************

MACRO M_INCREMENT_BY_N n, zp
        LDA zp
        CLC
        ADC #n
        STA zp
        BCC nocarry
        INC zp + 1
        LDA zp + 1
        CMP #(BUFFER_END DIV 256)
        BNE nowrap
        LDA #(BUFFER MOD 256)
        STA zp
        LDA #(BUFFER DIV 256)
        STA zp + 1
.nowrap        
.nocarry
ENDMACRO
        
MACRO M_INCREMENT_BY_2 zp
        M_INCREMENT_BY_N 2, zp
ENDMACRO

MACRO M_INCREMENT_BY_3 zp
        M_INCREMENT_BY_N 3, zp
ENDMACRO

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
        M_INCREMENT_BY_3 ptr
.skip_inc
ENDMACRO
        
