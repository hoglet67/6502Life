ptr           = &80
escflag       = &FF
mode4_base    = &5800
mode4_linelen = 320

.vdu_driver_start
        
        PHA
        TXA
        PHA
        TYA
        PHA
.screen
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
        BIT escflag
        BPL screen
        LDA oldwrcvec
        STA wrcvec
        LDA oldwrcvec+1
        STA wrcvec + 1
        PLA
        TAY
        PLA
        TAX
        PLA
        RTS

.oldwrcvec
        EQUW &E0A4

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
        BNE nocarry
        INC ptr + 1
.nocarry
        LDA ptr
        CMP #<vdu_driver_end
        BNE copy_vdu_loop
        LDA ptr + 1
        CMP #>vdu_driver_end
        BNE copy_vdu_loop

;; Read old OSWRCH vector        
        LDA #22
        JSR OSWRCH
        LDA #4
        JSR OSWRCH

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
        
