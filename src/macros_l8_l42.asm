;; ************************************************************
;; Macros
;; ************************************************************

IF _MATCHBOX

MACRO M_INCREMENT_BY_N n, zp, switch
        LDA zp       ; increment the LSB
        CLC
        ADC #n
        STA zp
        BCC l3       ; done if 256b boundary not crossed

        LDA zp + 1
        ADC #&01     ; C=1 so this actually adds 2 which allows the last 256b page in each 8K to be skipped
        BIT #&1F
        BNE l2

IF switch
        JSR cycle_banksel_buffers ; do the hard work in a subroutine
ELSE
        BIT #&3F
        BNE nowrap
        SEC
        SBC #&40
.nowrap
ENDIF
        INC A
.l2
        DEC A
        STA zp + 1
.l3
ENDMACRO

ELSE

MACRO M_INCREMENT_BY_N n, zp, switch
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

ENDIF

MACRO M_INCREMENT_BY_2 zp
        M_INCREMENT_BY_N 2, zp, TRUE
ENDMACRO

MACRO M_INCREMENT_BY_3 zp
        M_INCREMENT_BY_N 3, zp, TRUE
ENDMACRO

MACRO M_INCREMENT_BY_2_NOSWITCH zp
        M_INCREMENT_BY_N 2, zp, FALSE
ENDMACRO

MACRO M_INCREMENT_BY_3_NOSWITCH zp
        M_INCREMENT_BY_N 3, zp, FALSE
ENDMACRO
