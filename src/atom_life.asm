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

pixels          = &80
sum_idx         = &82
tmpY            = &83
tmpC            = &84
numrows         = &85
row1            = &87
sum_ptr         = &89
scrn_tmp        = &8B
row0            = &8D
row2            = &8F
scrn            = &91

scrn_base       = &8000

wkspc0          = &3400
wkspc1          = &3421
wkspc2          = &3442
sum             = &3463

gen_lo          = &0324          ; variable C on the Atom
gen_hi          = &0340
step            = &032A          ; variable I on the Atom
pia2            = &B002
pia1            = &B001

cells_per_byte  = &08
bytes_per_row   = &20
rows_per_screen = &BE

org               &2980

.start

.update_row
        LDA scrn                ; save screen row to 8B/8C and set 91/92 to next screen row
        STA scrn_tmp
        CLC
        ADC #bytes_per_row
        STA scrn
        LDA scrn + 1
        STA scrn_tmp + 1
        BCC no_scrn_carry
        INC scrn + 1
.no_scrn_carry
        JSR insert_row          ; copy screen row 2 into workspace row 2 into and accumulate pixels

        LDY #bytes_per_row * cells_per_byte - 1
        STY sum_idx
        LDY #bytes_per_row - 1

.update_loop:
        STY tmpY

        LDA (row1), Y           ; initially workspace row 1 (the one being re-calculated)
        STA pixels
        ORA (row0), Y           ; initially workspace row 0
        ORA (row2), Y           ; initially workspace row 2
        DEY
        ORA (row1), Y           ; initially workspace row 1 8px/1-byte left
        INY
        INY
        ORA (row1), Y           ; initially workspace row 1 8px/1-byte right
        BNE work_to_do          ; test if any pixels present? If so, then need to compute neighbour counds

        SEC                     ; move to next byte of 8 pixels
        LDA sum_idx
        SBC #cells_per_byte
        STA sum_idx
        LDY tmpY
        DEY
        BPL update_loop
        BMI delete_row

.work_to_do
        LDX #cells_per_byte - 1 ; compute neighbour counts for 8 cells
        LDY sum_idx
.cell_loop
        INY
        LDA sum, Y              ; three rows have already been added together
        CLC
        DEY
        ADC sum, Y
        DEY
        ADC sum, Y              ; A is now a neighbour count including self
        STY sum_idx
        ROL tmpC                ; carry = previously stashed cell
        ROR pixels              ; carry = current cell from screen memory byte read earlier
        BCC cell_is_off         ; branch if current cell is dead
.cell_is_on
        CMP #&05                ; test if cell count (inc self) is 5 or more
        BCS cell_dies           ; branch if current cell needs to dies
        CMP #&03                ; cell count (inc self) is 3 or 4, cell lives, otherwise dies
        ROR tmpC                ; stash newly calculated cell
        DEX                     ; move onto next of 8 cells
        BPL cell_loop           ; more to process?
        BMI write_screen        ; no
.cell_is_off
        CMP #&03                ; new cell is born if count exactly 3
        BEQ cell_lives
.cell_dies:
        CLC                     ; otherwise cell stays off
.cell_lives
        ROR tmpC                ; stash newly calculated cell
        DEX                     ; move to next of 8 pixels
        BPL cell_loop           ; more to process?

.write_screen
        STY sum_idx             ; done with processing 8 cells
        ROL tmpC                ; carry = previously stashed cell
        LDA pixels
        ROR A
        LDY tmpY
        STA (scrn_tmp), Y       ; save byte back to real screen memory
        DEY                     ; decrement index within row
        BPL update_loop         ; test if row is done, loop back if not

.delete_row
        LDX #bytes_per_row * cells_per_byte - 1
        LDY #bytes_per_row - 1
.delete_loop
        LDA (row0), Y           ; 8D initially points to row 0
        BNE decrement_counts
        TXA
        SEC
        SBC #cells_per_byte     ; this block of code almost identical to
        TAX                     ; subroutine at 2AAE, except it subtracts
        DEY                     ; from the pixel accumulator
        BPL delete_loop
        BMI rotate_buffers
.decrement_counts
        STY tmpY
        LDY #cells_per_byte - 1
.delete_loop2
        ROR A
        BCC skip_decrement
        DEC sum, X              ; subtract the row from the pixel accumulator
.skip_decrement
        DEX
        DEY
        BPL delete_loop2
        LDY tmpY
        DEY
        BPL delete_loop

.rotate_buffers
        LDX row1                ; stash old row 1 pointer in X and Y
        LDY row1 + 1

        LDA row2                ; copy 8F/90 to 87/88
        STA row1                ; i.e. point row 1 to old row 2
        LDA row2 + 1
        STA row1 + 1

        LDA row0                ; copy 8D/8E to 8F/90
        STA row2                ; i.e. point row 2 to old row 0 (that old data will be overwritten with next row)
        LDA row0 + 1
        STA row2 + 1

        STX row0                ; copy 87/88 to 8D/8E
        STY row0 + 1            ; i.e. point row 0 to old row 1

        DEC numrows             ; decrment the row counter
        BEQ gen_complete
        JMP update_row          ; loop back for more rows
.gen_complete
        INC gen_lo              ; increment generation count (LSB of variable C)
        BNE gen_no_carry
        INC gen_hi              ; increment generation count (LSB of variable D - BUG!!! should be 033F)
.gen_no_carry
        LDA pia2                ; Test for REPT key (display generations)
        AND #&40
        BEQ return              ; yes, exit to BASIC to render generation count
        LDA &032A
        BEQ return
        LDA pia1                ; Test for SHIFT or CTRL key (exit to editor)
        AND #&C0
        CMP #&C0
        BEQ update_screen       ; no, then lets do the next generation
.return
        RTS                     ; Return to BASIC

;; Main entry point
;; Continuously loop updating display with new generations
.update_screen
        LDY #bytes_per_row * cells_per_byte - 1
        LDA #&00
.clear_sum_loop
        STA sum, Y              ; clear pixel accumulator
        DEY
        BNE clear_sum_loop
        LDA #<scrn_base         ; Point 90/91 to start of display memory
        STA scrn
        LDA #>scrn_base
        STA scrn + 1
        LDA #<wkspc0            ; 8F/90=&3400 (workspace row 0)
        STA row2
        LDA #>wkspc0
        STA row2 + 1
        JSR insert_row   ; copy screen row 0 into workspace row 0 and accumulate pixels
        LDA #bytes_per_row
        STA scrn
        LDA #<wkspc1            ; 8F/90=&3421 (workspace row 1)
        STA row2
        LDA #>wkspc1
        STA row2 + 1
        JSR insert_row          ; copy screen row 1 into workspace row 1 into and accumulate pixels
        LDA #rows_per_screen
        STA numrows
        LDA #<wkspc1            ; 87/88=&3421 (workspace row 1)
        STA row1
        LDA #>wkspc1
        STA row1 + 1
        LDA #<sum               ; 89/8A=&3463 (pixel accumulator)
        STA sum_ptr             ; THIS IS UNUSED
        LDA #>sum
        STA sum_ptr + 1         ; THIS IS UNUSED
        LDA #<wkspc0            ; 8D/8E=&3400 (workspace row 0)
        STA row0
        LDA #>wkspc0
        STA row0 + 1
        LDA #<wkspc2            ; 8F/90=&3442 (workspace row 2)
        STA row2
        LDA #>wkspc2
        STA row2 + 1
        JMP update_row          ; update the screen rows

; Copy screen row into temp workspace
; 91/92 point into screen memory
; 8F/90 point into one of three workspace buffers (3400, 3421 or 3442)
; expand each pixel into value of 0 or 1 and accumulate these in 3463

.insert_row
{
        LDX #bytes_per_row * cells_per_byte - 1
        LDY #bytes_per_row - 1
.copy_loop
        LDA (scrn), Y
        STA (row2), Y
        BNE increment_counts
        TXA
        SEC
        SBC #cells_per_byte
        TAX
        DEY
        BPL copy_loop
        RTS
.increment_counts
        STY tmpY
        LDY #cells_per_byte - 1
.copy_loop2
        ROR A
        BCC skip_increment
        INC sum, X
.skip_increment
        DEX
        DEY
        BPL copy_loop2
        LDY tmpY
        DEY
        BPL copy_loop
}
        RTS

.end

SAVE "",start,end, update_screen
