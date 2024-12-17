;; ************************************************************
;; Macros
;; ************************************************************

IF _MATCHBOX

MACRO M_INCREMENT_PTR_NOSWITCH zp
        INC zp
        INC zp
        BNE nocarry
        LDA zp + 1
        INC A
        BIT #&3F
        BNE not_16K
        SEC
        SBC #&40
.not_16K
        STA zp + 1
.nocarry
ENDMACRO

MACRO M_INCREMENT_PTR zp
        INC zp
        INC zp
        BNE nocarry
        LDA zp + 1                ; test if an 8K boundary has been crossed
        INC A
        BIT #&1F                  ; BIT immediate is a non-destructive AND
        BNE not_8K
        JSR cycle_banksel_buffers ; do the hard work in a subroutine
.not_8K
        STA zp + 1
.nocarry
ENDMACRO

ELSE

MACRO M_INCREMENT_PTR_NOSWITCH zp
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

MACRO M_INCREMENT_PTR zp
        M_INCREMENT_PTR_NOSWITCH zp
ENDMACRO

ENDIF

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
IF (ptr = next)
        M_INCREMENT_PTR ptr
ELSE
        M_INCREMENT_PTR_NOSWITCH ptr
ENDIF
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
