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

;; Clear entire screen
.clear_screen
{
        LDA #<SCRN_BASE
        STA scrn
        LDA #>SCRN_BASE
        STA scrn + 1
        LDX #&20
        LDY #0
        TYA
.clear_loop
        STA (scrn), Y
        INY
        BNE clear_loop
        INC scrn + 1
        DEX
        BNE clear_loop
        RTS
}

.eor_screen_to_delta
{
        LDY #0
.loop
        LDA (delta), Y
        EOR (scrn), Y
        STA (delta), Y
        INY
        BNE loop
        RTS
}

.eor_delta_to_screen
{
        LDY #0
.loop
        LDA (scrn), Y
        EOR (delta), Y
        STA (scrn), Y
        INY
        BNE loop
        RTS

}

.send_screen_delta
        LDA #&FF                ; send the VDU command to expect a new display
        JSR OSWRCH

        LDA #<SCRN_BASE
        STA delta
        LDA #>SCRN_BASE
        STA delta + 1
        LDX #&20
.send_loop
        JSR send_delta
        INC delta + 1
        DEX
        BNE send_loop
        RTS

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
        LDA (scrn), Y

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

        LDA (scrn), Y

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


.count_base

.gen_count
        EQUB 0, 0, 0, 0

.cell_count
        EQUB 0, 0, 0, 0

.bcd_count
        EQUB 0, 0, 0, 0

.clear_count
{
FOR i, 0, COUNT_PRECISION - 1
        STZ count_base + i, X
NEXT
        RTS
}

.add_to_count
{
        SED
        CLC
        ADC count_base, X
        STA count_base, X
FOR i, 1, COUNT_PRECISION - 1
        BCC done
        LDA count_base + i, X
        ADC #0
        STA count_base + i, X
NEXT
.done
        CLD
        RTS
}

.print_as_signed
        BIT 1, X
        BPL print_as_unsigned
        LDA #'-'
        JSR OSWRCH
        LDA #0
        SEC
        SBC 0, X
        STA tmp
        LDA #0
        SBC 1, X
        STA tmp + 1
        BRA print_tmp

.print_as_unsigned
        LDA 0, X
        STA tmp
        LDA 1, X
        STA tmp + 1
        ;; fall through to print_tmp

.print_tmp
{
        JSR bin_to_bcd
        LDX #bcd_count - count_base + 2
        LDY #2
        BRA print_count_inner
}

.print_count
        LDY #COUNT_PRECISION - 1
FOR i, 1, COUNT_PRECISION - 1
        INX
NEXT
.print_count_inner
{
.loop
        LDA count_base, X
        JSR print_bcd
        DEX
        DEY
        BPL loop
        RTS
.print_bcd
        PHA
        LSR A
        LSR A
        LSR A
        LSR A
        JSR print_bcd_digit
        PLA
.print_bcd_digit
        AND #&0F
        ORA #&30
        JMP OSWRCH
}

.bin_to_bcd
{
        SED                 ; Switch to decimal mode
        STZ bcd_count + 0
        STZ bcd_count + 1
        STZ bcd_count + 2
        LDX #16             ; The number of source bits
.CNVBIT
        ASL tmp + 0         ; Shift out one bit
        ROL tmp + 1
        LDA bcd_count + 0   ; And add into result
        ADC bcd_count + 0
        STA bcd_count + 0
        LDA bcd_count + 1   ; propagating any carry
        ADC bcd_count + 1
        STA bcd_count + 1
        LDA bcd_count + 2   ; ... thru whole result
        ADC bcd_count + 2
        STA bcd_count + 2
        DEX                 ; And repeat for next bit
        BNE CNVBIT
        CLD                 ; Back to binary
        RTS
}
