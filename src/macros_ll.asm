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

;;          if(*prev == x) {
;;             bitmap |= 0100;
;;             prev++;
;;          }

MACRO M_UPDATE_BITMAP_IF_EQUAL_TO_X ptr, bmaddr, bmmask
        LDA (ptr)
        CMP xx
        BNE skip_inc
        LDA (ptr), Y
        CMP xx + 1
        BNE skip_inc
        LDA bmaddr
        ORA #bmmask
        STA bmaddr
        M_INCREMENT_PTR ptr
.skip_inc
ENDMACRO

MACRO M_WRITE ptr, val
        PHY
        LDY #0
        LDA val
        STA (ptr), Y
        INY
        LDA val + 1
        STA (ptr), Y
        M_INCREMENT_PTR ptr
        PLY
ENDMACRO
        
