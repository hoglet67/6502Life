ptr            = &80
mode4_base     = &5800 + 8 * 8   ; offset by 8 characters to make space for gen count
mode4_linelen  = 320

emptyrow      = &2000
        
.vdu_driver_start

        ;; Hijack &&FF - this will break plot commands!
        
        CMP #&FF
        BEQ update_display

IF _DELTA_VDU

        JMP (oldwrcvec)

ELSE
        
        CMP #&FE
        BEQ clear_display

.old_oswrch        
        JMP (oldwrcvec)

.clear_display
        
        PHA
        TXA
        PHA
        TYA
        PHA

        LDX #0
        TAX
.clear_loop
        STA emptyrow, X
        INX
        BNE clear_loop
        
        LDA #12
        JSR old_oswrch
        JMP vdu_done
        
ENDIF

.update_display
{
        PHA
        TXA
        PHA
        TYA
        PHA

        LDA #<mode4_base
        STA ptr
        LDA #>mode4_base
        STA ptr + 1

IF _DELTA_VDU

        LDY #0
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
ELSE
        
        LDY #0
        LDX #0
        CLC
.idle1
        BIT &FEE0
        BPL idle1
        LDA &FEE1               ; a blank row is indicated by a single 00
        BNE non_empty_row       ; anything else means the row contains cells

        ;; Empty row
        LDA emptyrow, X         ; test if the screen row is already empty
        BEQ next_row            ; if so, move onto the next row
        
        LDA #0                  ; mark the row as blank
        STA emptyrow, X
.clear_row                      ; and then actually blank out the row
        LDA #0
        STA (ptr), Y
        TYA
        ADC #8                  ; stepping 8 because of the way the graphics
        TAY                     ; modes on the beeb are laid out
        BCC clear_row
        BCS next_row

        ;; Non-empty row
.non_empty_row
        LDA #255                ; mark the row as non-empty
        STA emptyrow, X
.idle2
        BIT &FEE0               ; and then fill the row with 32 bytes
        BPL idle2
        LDA &FEE1
        STA (ptr),Y
        TYA
        ADC #8
        TAY
        BCC idle2

.next_row
        INY
        CPY #8
        BCC inc_row
        LDY #0
        CLC
        LDA ptr
        ADC #<mode4_linelen
        STA ptr
        LDA ptr + 1
        ADC #>mode4_linelen
        STA ptr + 1
.inc_row
        INX                     ; after 256 rows we are done
        BNE idle1

ENDIF
}
        
.vdu_done

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
        
