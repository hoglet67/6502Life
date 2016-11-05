;; ************************************************************
;; Macros
;; ************************************************************

MACRO M_COPY from, to
        LDA from
        STA to
        LDA from + 1
        STA to + 1
ENDMACRO

MACRO M_UPDATE_COORD coord, d
        LDA coord
        CLC
        ADC #<d
        STA coord
        LDA coord + 1
        ADC #>d
        STA coord + 1
.skip_update
ENDMACRO

MACRO M_UPDATE_COORD_ZP coord, zp
        LDA coord
        CLC
        ADC zp
        STA coord
        LDA coord + 1
        ADC zp + 1
        STA coord + 1
.skip_update
ENDMACRO
        
MACRO M_INCREMENT zp
        INC zp
        BNE nocarry
        INC zp + 1
.nocarry
ENDMACRO

MACRO M_DECREMENT zp
        LDA zp
        BNE nocarry
        DEC zp + 1
.nocarry
        DEC zp
ENDMACRO

        
;;       if(x > *this)
;;          x = *this;

MACRO M_ASSIGN_IF_GREATER val, ptr
        LDA val
        CMP (ptr)
        LDA val + 1
        SBC (ptr), Y
        BVC label
        EOR #&80
.label
        BMI skip_assign_val
        LDA (ptr)
        STA val
        LDA (ptr), Y
        STA val + 1
.skip_assign_val
ENDMACRO


MACRO COPY_ROW from, to
{        
        LDA #<(SCRN_BASE + from * BYTES_PER_ROW)
        STA scrn_tmp
        LDA #>(SCRN_BASE + from * BYTES_PER_ROW)
        STA scrn_tmp + 1
        LDA #<(SCRN_BASE + to * BYTES_PER_ROW)
        STA scrn
        LDA #>(SCRN_BASE + to * BYTES_PER_ROW)
        STA scrn + 1
        LDY #BYTES_PER_ROW - 1
.copy_loop
        LDA (scrn_tmp), Y
        STA (scrn), Y
        DEY
        BPL copy_loop
}
ENDMACRO
        
MACRO COPY_COLUMN from, to
{
        LDA #<SCRN_BASE
        STA scrn
        LDA #>SCRN_BASE
        STA scrn + 1
        LDX #0
.loop
        LDY #(from DIV 8) 
        LDA (scrn), Y
        LDY #(to DIV 8) 
        AND #(&80 >> (from MOD 8))
        BEQ pixel_zero
.pixel_one        
        LDA (scrn), Y
        ORA #(&80 >> (to MOD 8))
        BNE store
.pixel_zero        
        LDA (scrn), Y
        AND #(&80 >> (to MOD 8)) EOR &FF
.store
        STA (scrn), Y
        CLC
        LDA scrn
        ADC #BYTES_PER_ROW
        STA scrn
        BCC nocarry
        INC scrn + 1
.nocarry        
        INX
        BNE loop
}
ENDMACRO
