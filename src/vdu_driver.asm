ptr            = &80
escflag        = &FF
mode4_base     = &5800 + 6 * 8   ; offset by 8 characters to make space for gen count
mode4_linelen  = 320

gen_count_size = 3               ; size, in bytes, of the generatiomn count
        
.vdu_driver_start

        ;; Hijack &FE and &FF - this will break plot commands!
        
        CMP #&FE
        BEQ clear_gen_count

        CMP #&FF
        BEQ update_display

        JMP (oldwrcvec)

.clear_gen_count
{
        PHA
        TXA
        PHA
        
        LDA #&00
        LDX #gen_count_size - 2
.loop
        STA gen_count, X
        DEX
        BPL loop

        PLA
        TAX
        PLA
        RTS
}        
        
        
.update_display
{
        PHA
        TXA
        PHA
        TYA
        PHA
                
        JSR display_count
        
        LDY #<mode4_base
        STY ptr
        LDA #>mode4_base
        STA ptr + 1
.idle1
        BIT &FEE0
        BPL idle1
        LDA &FEE1
        EOR (ptr),Y
        STA (ptr),Y
.idle2
        BIT &FEE0
        BPL idle2
        LDY &FEE1
        BNE idle1
.zero
        CLC
        LDA ptr
        ADC #<mode4_linelen
        STA ptr
        LDA ptr + 1
        ADC #>mode4_linelen
        STA ptr + 1
        BPL idle1
        
        PLA
        TAY
        PLA
        TAX
        PLA
        RTS
}
        
.display_count
        LDA #30
        JSR oldoswrch
        LDX #gen_count_size - 1
        LDY #0
.display_count_loop
        LDA gen_count, Y
        JSR print_bcd
        INY
        DEX
        BPL display_count_loop

        SED
        SEC
        LDX #gen_count_size - 1
.inc_count_loop        
        LDA gen_count, X
        ADC #&00
        STA gen_count, X
        DEX
        BPL inc_count_loop
        CLD
        
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

.oldoswrch
        JMP (oldwrcvec)
        
.oldwrcvec
        EQUW &E0A4

        
.gen_count
FOR i, 0, gen_count_size - 1        
        EQUB 0
NEXT
        
.vdu_driver_end
                
.install_vdu_driver

;; Read old OSWRCH vector
        LDA #<wrcvec
        STA param
        LDA #>wrcvec
        STA param + 1
        JSR osword_05
        STA oldwrcvec        
        JSR osword_05
        STA oldwrcvec + 1

;; Copy code across
        LDA #<vdu_driver_start
        STA ptr
        STA param
        LDA #>vdu_driver_start
        STA ptr + 1
        STA param + 1
.copy_vdu_loop
        LDY #0
        LDA (ptr), Y
        JSR osword_06        
        INC ptr
        BNE copy_vdu_nocarry
        INC ptr + 1
.copy_vdu_nocarry
        LDA ptr
        CMP #<vdu_driver_end
        BNE copy_vdu_loop
        LDA ptr + 1
        CMP #>vdu_driver_end
        BNE copy_vdu_loop

;; Write OSWRCH vector
        LDA #<wrcvec
        STA param
        LDA #>wrcvec
        STA param + 1
        LDA #<vdu_driver_start
        JSR osword_06
        LDA #>vdu_driver_start
        JSR osword_06

;; Start the new VDU driver
        
        LDA #0
        JMP OSWRCH

;; Read a byte from host memory
.osword_05
        LDA #&05
        BNE osword_param

;; Write a byte to host memory
.osword_06
        STA param + 4
        LDA #&06

.osword_param
{
        LDX #<param
        LDY #>param
        JSR OSWORD
        INC param
        BNE nocarry
        INC param + 1
.nocarry        
        LDA param + 4
        RTS
}

.param
        EQUB 0,0,0,0,0
        
