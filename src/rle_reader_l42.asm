;; ************************************************************
;; rle_reader()
;; ************************************************************
;;
;; This version outputs in list8_life format
;;
;; params
;; - src = pointer to raw RLE data
;; - this = pointer to output buffer
;;
;; uses
;; - src
;; - this
;; - temp
;; - xx
;; - count
;; - bitmap
.rle_reader
{
        ;; Save the original buffer pointer
        M_COPY this, new

        ;; Increment this by 4K
        LDA new + 1
        CLC
        ADC #&10
        STA this + 1

        ;; Load the RLE file into (this), the original buffer plus 4KB
        ;; (new) is unused, so remains unchanged
        JSR rle_reader_stage1

        ;; Restore original buffer pointer        
        M_COPY new, this

        ;; Increment this by 4K
        LDA new + 1
        CLC
        ADC #&10
        STA this + 1

        ;; Reprocess the data structure from (this) back to (new), the original buffer
        JSR rle_reader_stage2

        ;; Leave (this) pointing at the first byte of free memory
        M_COPY new, this

        RTS
}
        

.rle_reader_stage1
{
        JSR parse_rle_header
        JSR offset_pattern

        LDY #1
        JSR init_yy
        JSR init_xx
        JSR zero_count
        JSR insert_y
.loop
        LDA byte
        BEQ done
        CMP #'!'
        BEQ done
        CMP #' '                ; skip over white space
        BEQ continue
        CMP #10                 ; skip over <NL>
        BEQ continue
        CMP #13                 ; skip over <CR>
        BEQ continue
        CMP #'0'                ; RLE count
        BCC not_digit
        CMP #'9'+1
        BCC digit
.not_digit
        CMP #'b'                ; dead cell
        BEQ jmp_insert_blanks
        CMP #'o'                ; live cell
        BEQ jmp_insert_cells
        CMP #'$'                ; end of line
        BEQ jmp_insert_eols

        ;; probably an error, but continue anyway....

.continue
        JSR rle_next_byte
        BRA loop

.done
        CLC
        JSR shift_bit           ; flush any remaining cells
        BCC done
        LDA #0
        STA (this)
        STA (this),Y
        M_INCREMENT_BY_2 this
        RTS

.jmp_insert_blanks
        JMP insert_blanks

.jmp_insert_cells
        JMP insert_cells

.jmp_insert_eols
        JMP insert_eols

.digit
        AND #&0F
        TAX
        JSR count_times_10      ; othewise multiply by 10
        TXA
        CLC
        ADC count               ; and add the digit
        STA count
        LDA count + 1
        ADC #0
        STA count + 1
        BRA continue

.insert_cells
        JSR default_count
.cells_loop
        LDA count
        ORA count + 1
        BEQ continue
        SEC
        JSR shift_bit
        M_DECREMENT count
        BRA cells_loop

.insert_blanks
        JSR default_count
.blanks_loop
        LDA count
        ORA count + 1
        BEQ continue
        CLC
        JSR shift_bit
        M_DECREMENT count
        BRA blanks_loop

.insert_eols
        CLC
        JSR shift_bit           ; flush any remaining cells
        BCC insert_eols

        JSR default_count
        LDA yy
        SEC
        SBC count
        STA yy
        LDA yy + 1
        SBC count + 1
        STA yy + 1
        JSR insert_y
        JSR init_xx
        JSR zero_count
        JMP continue
}

.shift_bit
{
        ROL bitmap              ; after 4 shifts a "marker" will pop out
        BCC not_yet
        LDA bitmap
        BEQ blank               ; blank chunks are simply ignored
        INY
        STA (this), Y
        DEY
        LDA xx + 1
        STA (this), Y
        LDA xx
        STA (this)
        M_INCREMENT_BY_3 this
.blank
        M_INCREMENT xx
        LDA #&10                ; pre-load the "4 shift" marker bit
        STA bitmap
        SEC                     ; c=1 on exit indicates the last byte was flushed
.not_yet
        RTS
}


.insert_y
{
        LDA yy
        STA (this)
        LDA yy + 1
        STA (this),Y
        M_INCREMENT_BY_2 this
        RTS
}

.init_xx
{
        LDA #&10                ; pre-load the "4 shift" marker bit
        STA bitmap
        LDA pat_width           ; pat_width holds the x coord to load at
        STA xx
        LDA pat_width + 1
        STA xx + 1
        RTS
}

.init_yy
{
        LDA pat_depth           ; pat_depth holds the y coord to load at
        STA yy
        LDA pat_depth + 1
        STA yy + 1
        RTS
}

.zero_count
{
        STZ count
        STZ count + 1
        RTS
}

.default_count
{
        LDA count               ; test if count still zero
        ORA count + 1
        BNE return
        LDA #1                  ; if so, default to 1
        STA count
.return
        RTS
}

.offset_pattern
{
        LSR pat_width + 1       ; divide the pattern size in half
        ROR pat_width
        LSR pat_depth + 1
        ROR pat_depth

        LSR pat_width + 1       ; divide the width by another 8, as xx is in bytes not pixels
        ROR pat_width
        LSR pat_width + 1
        ROR pat_width
        LSR pat_width + 1
        ROR pat_width

        LDA #<X_ORIGIN          ; on exit pat_width contains the X coord to load the pattern at
        SEC
        SBC pat_width
        STA pat_width
        LDA #>X_ORIGIN
        SBC pat_width + 1
        STA pat_width + 1
        LDA #<Y_ORIGIN          ; on exit pat_depyj contains the Y coord to load the pattern at
        CLC
        ADC pat_depth
        STA pat_depth
        LDA #>Y_ORIGIN
        ADC pat_depth + 1
        STA pat_depth + 1
        RTS
}

;;void list_rle_reader_stage2(int *this, int *new) {
;;   int *prev;
;;   int upper;
;;   int lower;
;;   int x;
;;   int y;

.rle_reader_stage2
{
;;   prev = this;

      M_COPY this, prev

      LDY #1

;;   while (1) {

.level1

;;      y = *prev;

        LDA (prev)
        STA yy
        LDA (prev), Y
        STA yy + 1

;;      // Test for terminator
;;      if (y == 0) {
;;         *new = 0;
;;         return;
;;      }

        ORA yy
        BNE not_return
        LDA #0
        STA (new)
        STA (new), Y
        M_INCREMENT_BY_2 new
        RTS
.not_return

;;      // We need to advance "this" to the next line to know what to do
;;      if ((prev == this) && (y & 1) == 0) {
;;         this++;
;;         while (*this < 0) {
;;            this += 2;
;;         }
;;         continue;
;;      }

        LDA this
        CMP prev
        BNE not_continue
        LDA this + 1
        CMP prev + 1
        BNE not_continue
        LDA yy
        AND #&01
        BNE not_continue
        M_INCREMENT_BY_2 this
.advance_loop
        LDA (this), Y
        BPL level1
        M_INCREMENT_BY_3 this
        BRA advance_loop
.not_continue

;;      // Determine which rows to scan
;;      if (prev == this) {
;;         // Case 1: merge "0000" and "prev" (y must be odd)
;;         *new = y + 1;
;;         // At this point, both "prev" and "this" are pointing to the same row
;;         // and it turns out to be more convenient to advance "this" so that
;;         // a single form of the scan row code can cope with all three cases.
;;         this++;

        LDA prev
        CMP this
        BNE else1
        LDA prev + 1
        CMP this + 1
        BNE else1
        LDA yy
        CLC
        ADC #1
        STA (new)
        LDA yy + 1
        ADC #0
        STA (new), Y
        M_INCREMENT_BY_2 this
        BRA endif1

;;      } else {
;;         *new = y;
;;         // In both these cases we can "prev"
;;         prev++;
;;         if (y == *this + 1) {
;;            // Case 2: merge "prev" and "this" (y must be even)
;;            this++;
;;         } else {
;;            // Case 3: merge "prev" and "0000" (y must be even)
;;         }
;;      }

.else1
        LDA yy
        STA (new)
        LDA yy + 1
        STA (new), Y
        M_INCREMENT_BY_2 prev
        LDA yy
        SEC
        SBC #1
        CMP (this)
        BNE else2
        LDA yy + 1
        SBC #0
        CMP (this), Y
        BNE else2
        M_INCREMENT_BY_2 this
.else2
.endif2

.endif1
;;      new++

        M_INCREMENT_BY_2 new

;;      // Scan rows, merging 4x1 blocks into 4x2 blocks
;;      while (1) {

.level2

;;       x = *prev;

        LDA (prev)
        STA xx
        LDA (prev), Y
        STA xx + 1

;;       if(x > *this)
;;          x = *this;

        M_ASSIGN_IF_GREATER xx, this

;;       if(x >= 0)
;;          break;

        LDA xx + 1
        BMI x_negative
        JMP level2_break
.x_negative

;;         upper = lower = 0;
        STZ upper
        STZ lower

;;         if(*prev == x) {
;;            upper = *(prev + 1);
;;            prev += 2;
;;         }

        M_UPDATE_CHUNK_IF_EQUAL_TO_X prev, upper

;;         if(*this == x) {
;;            lower = *(this + 1);
;;            this += 2;
;;         }

        M_UPDATE_CHUNK_IF_EQUAL_TO_X this, lower

;;         *new++ = x;
;;         *new++ = merge(upper, lower);

        LDA xx
        STA (new)
        LDA xx + 1
        STA (new), Y
        INY
        LDA upper
        ASL A
        ASL A
        ASL A
        ASL A
        ORA lower
        STA (new), Y
        DEY
        M_INCREMENT_BY_3 new

;;      }

        JMP level2

.level2_break
;;      // Advance prev, as we only process each row once
;;      prev = this;      
;;   }
;;}
        M_COPY this, prev
        JMP level1
}
        
