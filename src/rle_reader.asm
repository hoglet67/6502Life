;; ************************************************************
;; rle_reader()
;; ************************************************************

;; params
;; - this = pointer to output buffer for list life format pattern
;; - new = pointer to raw RLE data
;;
;; uses
;; - this  &50
;; - new   &52
;; - temp  &54
;; - xx    &56
;; - yy    &58
;; - count &74
        

.rle_reader
{
        JSR init_yy
        JSR init_xx
        JSR zero_count
        JSR insert_y
        LDY #1
.loop        
        LDA (new)
        BEQ done
        CMP #'!'
        BEQ done
        CMP #' '                ; skip over white space
        BEQ continue
        CMP #10                 ; skip over <NL>
        BEQ continue
        CMP #13                 ; skip over <CR>
        BEQ continue        
        CMP #'0'                ; RLE count
        BCC not_digit
        CMP #'9'+1
        BCC digit
.not_digit
        CMP #'b'                ; dead cell
        BEQ insert_blanks
        CMP #'o'                ; live cell
        BEQ insert_cells
        CMP #'$'                ; end of line
        BEQ insert_eols
         
        ;; probably an error, but continue anyway....

.continue
        M_INCREMENT new
        BRA loop
                
.done
        LDA #0
        STA (this)
        STA (this),Y
        M_INCREMENT_PTR this
        RTS        
        
.digit
        AND #&0F
        TAX
        JSR count_times_10      ; othewise multiply by 10
        TXA
        CLC
        ADC count               ; and add the digit
        STA count
        LDA count + 1
        ADC #0
        STA count + 1
        JMP continue
        
.insert_cells
        JSR default_count
.cells_loop        
        LDA count
        ORA count + 1
        BEQ continue        
        LDA xx
        STA (this)
        LDA xx + 1
        STA (this),Y        
        M_INCREMENT_PTR this
        M_INCREMENT xx        
        M_DECREMENT count
        BRA cells_loop
        
.insert_blanks
        JSR default_count
        LDA xx
        CLC
        ADC count
        STA xx
        LDA xx + 1
        ADC count + 1
        STA xx + 1
        JSR zero_count
        JMP continue
        
.insert_eols
        JSR default_count
        LDA yy
        SEC
        SBC count
        STA yy
        LDA yy + 1
        SBC count + 1
        STA yy + 1
        JSR insert_y
        JSR init_xx
        JSR zero_count
        JMP continue
}        

.insert_y
{        
        LDA yy
        STA (this)
        LDA yy + 1
        STA (this),Y
        M_INCREMENT_PTR this
        RTS
}        

.init_xx
{        
        LDA #<X_START
        STA xx
        LDA #>X_START
        STA xx + 1
        RTS
}
.init_yy
{        
        LDA #<Y_START
        STA yy
        LDA #>Y_START
        STA yy + 1
        RTS
}
        
.zero_count
{
        STZ count
        STZ count + 1
        RTS
}

.default_count
{        
        LDA count               ; test if count still zero
        ORA count + 1
        BNE return
        LDA #1                  ; if so, default to 1
        STA count
.return
        RTS
}
        
.count_times_10
{

        ASL count               ; count *= 2
        ROL count + 1

        LDA count               ; tmp = count
        STA temp                                
        LDA count + 1
        STA temp + 1

        ASL count               ; count *= 4
        ROL count + 1
        ASL count
        ROL count + 1
        
        LDA count               ; count += tmp
        CLC
        ADC temp
        STA count
        LDA count + 1
        ADC temp + 1
        STA count + 1
        RTS
}
