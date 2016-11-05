;; ************************************************************
;; Macros
;; ************************************************************

MACRO M_INCREMENT_PTR zp
        INC zp
        INC zp
        BNE nocarry
        INC zp + 1
        LDA zp + 1
        CMP #(BUFFER_END DIV 256)
        BNE nowrap
        LDA #(BUFFER DIV 256)
        STA zp + 1
.nowrap        
.nocarry
ENDMACRO
