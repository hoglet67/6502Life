;; ************************************************************
;; Macros
;; ************************************************************

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

MACRO M_INCREMENT_PTR zp
        INC zp
        INC zp
        BNE nocarry
        INC zp + 1
.nocarry
ENDMACRO

;;       if(x > *this)
;;          x = *this;

MACRO M_ASSIGN_IF_GREATER val, ptr
        LDY #0
        LDA val
        CMP (ptr), Y
        INY
        LDA val + 1
        SBC (ptr), Y
        BVC label
        EOR #&80
.label
        BMI skip_assign_val
        LDA (ptr), Y
        STA val + 1
        DEY
        LDA (ptr), Y
        STA val
.skip_assign_val
ENDMACRO

;;          if(*prev == x) {
;;             bitmap |= 0100;
;;             prev++;
;;          }

MACRO M_UPDATE_BITMAP_IF_EQUAL_TO_X ptr, bmaddr, bmmask
        LDY #0
        LDA (ptr), Y
        CMP xx
        BNE skip_inc
        INY
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
        TYA
        PHA
        LDY #0
        LDA val
        STA (ptr), Y
        INY
        LDA val + 1
        STA (ptr), Y
        INC ptr
        INC ptr
        BNE nocarry
        INC ptr + 1
.nocarry
        PLA
        TAY
ENDMACRO

MACRO COPY_ROW from, to
{        
        LDA #<(scrn_base + from * bytes_per_row)
        STA scrn_tmp
        LDA #>(scrn_base + from * bytes_per_row)
        STA scrn_tmp + 1
        LDA #<(scrn_base + to * bytes_per_row)
        STA scrn
        LDA #>(scrn_base + to * bytes_per_row)
        STA scrn + 1
        LDY #bytes_per_row - 1
.copy_loop
        LDA (scrn_tmp), Y
        STA (scrn), Y
        DEY
        BPL copy_loop
}
ENDMACRO
        
MACRO COPY_COLUMN from, to
{
        LDA #<scrn_base
        STA scrn
        LDA #>scrn_base
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
        ADC #bytes_per_row
        STA scrn
        BCC nocarry
        INC scrn + 1
.nocarry        
        INX
        BNE loop
}
ENDMACRO
