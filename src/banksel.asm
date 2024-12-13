CPU 1                           ; allow 65C02 opcodes

banksel  = &FEE0

B0_PAGE  = &80
B1_PAGE  = &C0

BUFSIZE  = B1_PAGE - B0_PAGE
OR_MASK  = BUFSIZE - 1          ; used to get to last page in buffer
AND_MASK = B0_PAGE OR B1_PAGE   ; used to get to first page in buffer
EOR_MASK = B0_PAGE EOR B1_PAGE  ; used to swap between buffers

;; Cycle to the next sequential buffer
;;
;; On entry:
;;      A = MSB of 6502 address of the buffer to cycle
;; On exit:
;;      A = MSB of new 6502 address, updated if the buffer wrapped at 16K

.cycle_banksel_buffers
{
        BIT #&3F                ; Detect wrapping at the 16K boundary
        BNE not_16K
        SEC                     ; and correct
        SBC #&40
.not_16K
        PHA                     ; Save A, so we can return it to the macro
        PHX                     ; Save X, so we don't mess up any calling code
        LSR A                   ; locate the bank selection register
        LSR A                   ; which is the 6502 address DIV 8K
        LSR A
        LSR A
        LSR A
        TAX
        LDA banksel_shadow, X   ; increment the bank select register by two pages
        INC A
        INC A
        BIT #(BUFSIZE - 2)      ; DMB: 13/12/24: this test seems wrong!!!
        BNE not_wrapped
        SEC
        SBC #BUFSIZE
.not_wrapped
        STA banksel_shadow, X
        STA banksel, X          ; the back select register is write only
.exit
        PLX
        PLA
        RTS
}

;; Initialize the bank select register with the following mapping
;;
;; 0x0000 - unchanged (should be 0x00)
;; 0x2000 - unchanged (should be 0x01)
;; 0x4000 - 0x80
;; 0x6000 - 0xBF
;; 0x8000 - 0xC0
;; 0xA000 - 0xFF
;; 0xC000 - unchanged (should be 0x06)
;; 0xE000 - unchanged (should be 0x07)

.init_banksel_buffers
{
        LDA #B0_PAGE
        STA banksel_shadow + 2  ; 0x4000 -> 0x80
        STA banksel        + 2
        ORA #OR_MASK
        STA banksel_shadow + 3  ; 0x6000 -> 0xBF
        STA banksel        + 3
        LDA #B1_PAGE
        STA banksel_shadow + 4  ; 0x8000 -> 0xC0
        STA banksel        + 4
        ORA #OR_MASK
        STA banksel_shadow + 5  ; 0xA000 -> 0xFF
        STA banksel        + 5
        RTS
}

;; Swap over the pages of the two buffers
;;
.swap_banksel_buffers
{
        LDA banksel_shadow + 2
        AND #AND_MASK
        EOR #EOR_MASK
        STA banksel_shadow + 2  ; 0x4000
        STA banksel        + 2
        ORA #OR_MASK
        STA banksel_shadow + 3  ; 0x6000
        STA banksel        + 3
        LDA banksel_shadow + 4
        AND #AND_MASK
        EOR #EOR_MASK
        STA banksel_shadow + 4  ; 0x8000
        STA banksel        + 4
        ORA #OR_MASK
        STA banksel_shadow + 5  ; 0xA000
        STA banksel        + 5
        RTS
}

;; Reset the banksel buffers (but don't swap)
;;
.reset_banksel_buffers
{
        LDA banksel_shadow + 2
        AND #AND_MASK
        STA banksel_shadow + 2  ; 0x4000
        STA banksel        + 2
        ORA #OR_MASK
        STA banksel_shadow + 3  ; 0x6000
        STA banksel        + 3
        LDA banksel_shadow + 4
        AND #AND_MASK
        STA banksel_shadow + 4  ; 0x8000
        STA banksel        + 4
        ORA #OR_MASK
        STA banksel_shadow + 5  ; 0xA000
        STA banksel        + 5
        RTS
}

.banksel_shadow
        EQUB &00
        EQUB &01
        EQUB &02
        EQUB &03
        EQUB &04
        EQUB &05
        EQUB &06
        EQUB &07

