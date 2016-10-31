;; ************************************************************
;; Code
;; ************************************************************
        
.print_string
{
        PLA
        STA tmp
        PLA
        STA tmp + 1

        LDY #0
.loop        
        INC tmp
        BNE nocarry
        INC tmp + 1
.nocarry
        LDA (tmp), Y
        BMI done
        JSR OSWRCH
        JMP loop
.done
        JMP (tmp)
}

.clear_delta
{
        LDY #&00
        TYA
.clear_delta_loop
        STA (delta), Y
        DEY
        BNE clear_delta_loop
        RTS
}
        
;; Send one one strip 8 pixels heigh x 256 pixels wide to VDU driver
;; Converting from row linear atom" to character striped "beeb" screen format on the fly
;; And compressing zeros

.send_delta
{
;; X is the index in beeb format

        TXA
        PHA
        
        LDX #0

;; always send the data for X=0
        LDY #0
        LDA (delta), Y

.wait_for_space1        
        BIT &FEF8
        BVC wait_for_space1
        STA &FEF9               ; send data

.skip_blank        
        INX
        BEQ wait_for_space2
                
        LDA char_to_linear_map, X
        TAY
        LDA (delta), Y

        BEQ skip_blank        
        
.wait_for_space2        
        BIT &FEF8
        BVC wait_for_space2
        STX &FEF9               ; send index
        
        CPX #0
        BNE wait_for_space1

        PLA
        TAX
        
        RTS
}
        
.char_to_linear_map
FOR x, 0, 31
  FOR y, 0, 7
     EQUB y * &20 + x
  NEXT
NEXT
