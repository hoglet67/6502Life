ptr            = &80
mode4_base     = &5800 + 8 * 8   ; offset by 8 characters to make space for gen count
mode4_linelen  = 320


.vdu_driver_start

        ;; Hijack &&FF - this will break plot commands!

        CMP #&FF
        BEQ update_display

        JMP (oldwrcvec)

.update_display
{
        PHA
        TXA
        PHA
        TYA
        PHA

        LDY #<mode4_base
        STY ptr
        LDA #>mode4_base
        STA ptr + 1
        LDY #0

.idle1
.*elk1  BIT &FEE0    ; patched for electron if necessary
        BPL idle1
.*elk2  LDA &FEE1    ; patched for electron if necessary
        STA (ptr),Y
.idle2
.*elk3  BIT &FEE0    ; patched for electron if necessary
        BPL idle2
.*elk4  LDY &FEE1    ; patched for electron if necessary
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

.oldwrcvec
        EQUW &E0A4

.vdu_driver_end

.install_vdu_driver

;; Test for electron
        LDA #&00
        LDX #&FF
        JSR OSBYTE
        CPX #&00     ; &00 = Electron/Communicator (OS 1.0)
        BNE not_electron
        LDA #&FC     ; Patch MSB of tube address to &FCxx
        STA elk1+2
        STA elk2+2
        STA elk3+2
        STA elk4+2

.not_electron

;; Read old OSWRCH vector
        LDA #<WRCVEC
        STA param
        LDA #>WRCVEC
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
        LDA #<WRCVEC
        STA param
        LDA #>WRCVEC
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
