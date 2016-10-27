; ==================================================
; Acornsoft Atom LIFE Machine Code Program
; ==================================================

; MAIN ENTRY POINT is #2A5B

; first call:
; 87/88=&3421 (row 1 initially set to workspace 1)
; 89/8A=&3463 (pixel accumulator)
; 8D/8E=&3400 (row 0 initially set to workspace 0)
; 8F/90=&3442 (row 2 initially set to workspace 2, not yet populated)
; 91/92=&8000 (screen row 1)


org &2980

.start
        
.L2980
        LDA &91      ; save screen row to 8B/8C and set 91/92 to next screen row
        STA &8B
        CLC
        ADC #&20     ; Patched depending on MODE
        STA &91
        LDA &92
        STA &8C
        BCC L2991
        INC &92
.L2991
        JSR L2AAE    ; copy screen row 2 into workspace row 2 into and accumulate pixels

        LDY #&FF     ; Patched depending on MODE
        STY &82
        LDY #&1F     ; Patched depending on MODE
.L299A        
        STY &83

        LDA (&87),Y  ; initially workspace row 1 (the one being re-calculated)
        STA &80
        ORA (&8D),Y  ; initially workspace row 0
        ORA (&8F),Y  ; initially workspace row 2
        DEY
        ORA (&87),Y  ; initially workspace row 1 8px/1-byte left
        INY
        INY
        ORA (&87),Y  ; initially workspace row 1 8px/1-byte right
        BNE L29BB    ; test if any pixels present? If so, then need to compute neighbour counds

        SEC          ; move to next byte of 8 pixels
        LDA &82
        SBC #&08
        STA &82
        LDY &83
        DEY
        BPL L299A
        BMI L29F9
.L29BB
        LDX #&07     ; compute neighbour counts for 8 cells
        LDY &82
.L29BF
        INY
        LDA &3463,Y  ; three rows have already been added together
        CLC
        DEY
        ADC &3463,Y
        DEY
        ADC &3463,Y  ; A is now a neighbour count including self
        STY &82
        ROL &84      ; carry = previously stashed cell
        ROR &80      ; carry = current cell from screen memory byte read earlier
        BCC L29E1    ; branch if current cell is dead
        CMP #&05     ; test if cell count (inc self) is 5 or more
        BCS L29E5    ; branch if current cell needs to dies
        CMP #&03     ; cell count (inc self) is 3 or 4, cell lives, otherwise dies
        ROR &84      ; stash newly calculated cell
        DEX          ; move onto next of 8 cells
        BPL L29BF    ; more to process?
        BMI L29EB    ; no
.L29E1
        CMP #&03     ; new cell is born if count exactly 3
        BEQ L29E6
.L29E5
        CLC          ; otherwise cell stays off
.L29E6
        ROR &84      ; stash newly calculated cell
        DEX          ; move to next of 8 pixels
        BPL L29BF    ; more to process?

.L29EB
        STY &82      ; done with processing 8 cells
        ROL &84      ; carry = previously stashed cell
        LDA &80
        ROR A
        LDY &83
        STA (&8B),Y  ; save byte back to real screen memory
        DEY          ; decrement index within row
        BPL L299A    ; test if row is done, loop back if not

.L29F9        
        LDX #&FF     ; Patched depending on MODE
        LDY #&1F     ; Patched depending on MODE
.L29FD
        LDA (&8D),Y  ; 8D initially points to row 0
        BNE L2A0B
        TXA
        SEC
        SBC #&08     ; this block of code almost identical to
        TAX          ; subroutine at 2AAE, except it subtracts
        DEY          ; from the pixel accumulator
        BPL L29FD
        BMI L2A1E
.L2A0B        
        STY &83
        LDY #&07
.L2A0F        
        ROR A
        BCC L2A15
        DEC &3463,X  ; subtract the row from the pixel accumulator
.L2A15
        DEX
        DEY
        BPL L2A0F
        LDY &83
        DEY
        BPL L29FD
.L2A1E
        LDX &87      ; stash old row 1 pointer in X and Y
        LDY &88

        LDA &8F      ; copy 8F/90 to 87/88
        STA &87      ; i.e. point row 1 to old row 2
        LDA &90
        STA &88

        LDA &8D      ; copy 8D/8E to 8F/90
        STA &8F      ; i.e. point row 2 to old row 0 (that old data will be overwritten with next row)
        LDA &8E
        STA &90

        STX &8D      ; copy 87/88 to 8D/8E
        STY &8E      ; i.e. point row 0 to old row 1

        DEC &85      ; decrment the row counter
        BEQ L2A3D
        JMP L2980    ; loop back for more rows
.L2A3D
        INC &0324    ; increment generation count (LSB of variable C)
        BNE L2A45
        INC &0340    ; increment generation count (LSB of variable D - BUG!!! should be 033F)
.L2A45
        LDA &B002    ; Test for REPT key (display generations)
        AND #&40
        BEQ L2A5A    ; yes, exit to BASIC to render generation count
        LDA &032A
        BEQ L2A5A
        LDA &B001    ; Test for SHIFT or CTRL key (exit to editor)
        AND #&C0
        CMP #&C0
        BEQ L2A5B    ; no, then lets do the next generation
.L2A5A
        RTS          ; Return to BASIC

;; Main entry point
;; Continuously loop updating display with new generations
.exec
.L2A5B
        LDY #&FF     ; Patched depending on MODE
        LDA #&00
.L2A5F
        STA &3463,Y  ; clear pixel accumulator
        DEY
        BNE L2A5F
        LDA #&00     ; Point 90/91 to start of display memory
        STA &91
        LDA #&80
        STA &92
        LDA #&00     ; 8F/90=&3400 (workspace row 0)
        STA &8F
        LDA #&34
        STA &90
        JSR L2AAE    ; copy screen row 0 into workspace row 0 and accumulate pixels
        LDA #&20     ; Patched depending on MODE
        STA &91
        LDA #&21     ; 8F/90=&3421 (workspace row 1)
        STA &8F
        LDA #&34
        STA &90
        JSR L2AAE    ; copy screen row 1 into workspace row 1 into and accumulate pixels
        LDA #&BE     ; Patched depending on MODE (number ot rows - 2)
        STA &85
        LDA #&21     ; 87/88=&3421 (workspace row 1)
        STA &87
        LDA #&34
        STA &88
        LDA #&63     ; 89/8A=&3463 (pixel accumulator)
        STA &89
        LDA #&34
        STA &8A
        LDA #&00     ; 8D/8E=&3400 (workspace row 0)
        STA &8D
        LDA #&34
        STA &8E
        LDA #&42     ; 8F/90=&3442 (workspace row 2)
        STA &8F
        LDA #&34
        STA &90
        JMP L2980    ; compute row?

; Copy screen row into temp workspace
; 91/92 point into screen memory
; 8F/90 point into one of three workspace row buffers (3400, 3421 or 3442)
; expand each pixel into value of 0 or 1 and accumulate these in 3463

.L2AAE
        LDX #&FF     ; Patched depending on MODE
        LDY #&1F     ; Patched depending on MODE
.L2AB2
        LDA (&91),Y
        STA (&8F),Y
        BNE L2AC1
        TXA
        SEC
        SBC #&08
        TAX
        DEY
        BPL L2AB2
        RTS
.L2AC1
        STY &83
        LDY #&07
.L2AC5
        ROR A
        BCC L2ACB
        INC &3463,X
.L2ACB
        DEX
        DEY
        BPL L2AC5
        LDY &83
        DEY
        BPL L2AB2
        RTS
        
.end

SAVE "",start,end, exec
