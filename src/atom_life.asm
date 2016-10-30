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

; md5sum of the original Atom code is afda749173d62159e28003243b098c95
        
pixels          = &80           ; block of 8 pixels (cells) being updates
sum_idx         = &82           ; index into the pixel accumulator
tmpY            = &83           ; temp storage for Y register
tmpC            = &84           ; temp storage for carry flag
numrows         = &85           ; row counter, decrements down to zer0
row1            = &87           ; pointer to row1 in the workspace (the one being updated)
sum_ptr         = &89           ; set but not UNUSED
scrn_tmp        = &8B           ; pointer to the current row in screen memory
row0            = &8D           ; pointer to row0 in the workspace (the row above)
row2            = &8F           ; pointer to row0 in the workspace (the row beloe)
scrn            = &91           ; pointer to the next row in screen memory
        
cells_per_byte  = &08           ; bits per cell, also bits per byte, do not change!
bytes_per_row   = &20           ; X resolution on the atom in CLEAR 4 is 256


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
IF not(_ATOM)
        EOR (scrn_tmp), Y       ; calculate delta
        STA (delta),Y
        EOR (scrn_tmp), Y       ; undo calculate delta        
ENDIF        
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

IF not(_ATOM)
        LDA delta               ; point delta to the next line
        CLC
        ADC #bytes_per_row      ; we assume delta buffer is page aligned
        STA delta               ; so when it wraps to zero, it is full (8 rows)
        BNE skip_send           ; full? send across to the Host
        JSR send_delta          ; delta is now page aligned again
        JSR clear_delta         ; clear the delta buffer
        
.skip_send        
ENDIF
        DEC numrows             ; decrment the row counter
        BEQ gen_complete
        JMP update_row          ; loop back for more rows
.gen_complete
        INC gen_lo              ; increment generation count (LSB of variable C)
        BNE gen_no_carry
        INC gen_hi              ; increment generation count (LSB of variable D - BUG!!! should be 033F)
.gen_no_carry
IF _ATOM
        LDA pia2                ; Test for REPT key (display generations)
        AND #&40
        BEQ return              ; yes, exit to BASIC to render generation count
        LDA step
        BEQ return
        LDA pia1                ; Test for SHIFT or CTRL key (exit to editor)
        AND #&C0
        CMP #&C0
        BEQ next_generation     ; no, then lets do the next generation
.return
ELSE
        LDA #&00
        STA delta
        JSR send_delta          ; delta is now page aligned again
        JSR clear_delta         ; clear the delta buffer
        LDA #&20
        STA delta
ENDIF
        RTS                     ; Return to BASIC

;; Main entry point
;; Continuously loop updating display with new generations
.next_generation
        LDY #(bytes_per_row * cells_per_byte MOD 256)
        LDA #&00
.clear_sum_loop
        DEY
        STA sum, Y              ; clear pixel accumulator
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

