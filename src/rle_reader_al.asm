;; ************************************************************
;; rle_reader()
;; ************************************************************
;; 
;; This version outputs to a atom_life 256x256 screen bitmap
;; 
;; params
;; - src = pointer to raw RLE data
;; - this = pointer to output buffer
;;
;; uses
;; - src
;; - this
;; - temp
;; - xx
;; - count


.rle_reader
{
        JSR init_xx
        JSR zero_count
        JSR clear_screen
.loop
        LDA (src)
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
        M_INCREMENT src
        BRA loop

.done
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
        LDA xx + 1              ; byte offset in row = xx DIV 8
        STA temp
        LDA xx
        LSR temp
        ROR A
        LSR temp
        ROR A
        LSR temp
        ROR A
        TAY
        LDA xx                  ; bit number within byte = xx MOD 8
        AND #&07
        TAX
        LDA pixelmask, X
        EOR (this), Y
        STA (this), Y
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
        LDA count
        ASL A                 ; move (this) forward count screen rows
        ROL count + 1
        ASL A
        ROL count + 1
        ASL A
        ROL count + 1
        ASL A
        ROL count + 1
        ASL A
        ROL count + 1
        CLC
        ADC this
        STA this
        LDA count + 1
        ADC this + 1
        STA this + 1
        JSR init_xx
        JSR zero_count
        JMP continue
}

.init_xx
{
        STZ xx
        STZ xx + 1
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

.pixelmask
        EQUB &80, &40, &20, &10, &08, &04, &02, &01
