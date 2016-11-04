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

;;          if(*prev == x) {
;;             foreprev = *++prev;
;;             prev++;
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
        M_INCREMENT_BY_3 ptr
.skip_inc
ENDMACRO

;;          locnt_r = lo[rearprev];
;;          locnt_r += lo[rearthis];
;;          locnt_r += lo[rearnext];
MACRO M_ACCUMULATE_COLUMN cnt, table, prev, this, next
        CLC
        LDX prev
        LDA table, X
        LDX this
        ADC table, X
        LDX next
        ADC table, X
        STA cnt
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
