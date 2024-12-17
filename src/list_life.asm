;; ************************************************************
;; Variables
;; ************************************************************

DEAD = 0
LIVE = 1

;; ************************************************************
;; State lookup table
;; ************************************************************

;; for(bitmap = 0; bitmap < 1<<9; bitmap++) {
;;    for(x = y = 0; y < 9; y++)
;;       if(bitmap & 1<<y)
;;          x += 1;
;;    if(bitmap & 020) {
;;       if(x == 2 || x == 3)
;;          state[bitmap] = LIVE;
;;       else
;;          state[bitmap] = DEAD;
;;    } else {
;;       if(x == 3)
;;          state[bitmap] = LIVE;
;;       else
;;          state[bitmap] = DEAD;
;;    }
;; }

ALIGN 256

.state
FOR bm, %000000000, %111111111
    ; in BeebASM false = 0 and true = -1, hence the 9 at the start
    x = 9 + ((bm AND &001) = 0) + ((bm AND &002) = 0) + ((bm AND &004) = 0) + ((bm AND &008) = 0) + ((bm AND &010) = 0) + ((bm AND &020) = 0) + ((bm AND &040) = 0) + ((bm AND &080) = 0) + ((bm AND &100) = 0)
    IF ((bm AND &10) <> 0)
        IF ((x = 3) OR (x = 4))
            EQUB LIVE
        ELSE
            EQUB DEAD
        ENDIF
    ELSE
        IF (x = 3)
            EQUB LIVE
        ELSE
            EQUB DEAD
        ENDIF
    ENDIF
NEXT

;; ************************************************************
;; list_life()
;; ************************************************************

;; Args are (this) and (new)

.list_life
;;  keep Y as the constant 1 if efficient access of the high byte in a list
        LDY #1

;; prev = next = this;
        LDA this
        STA prev
        STA next
        LDA this + 1
        STA prev + 1
        STA next + 1

        LDA #0

;; bitmap = 0;
        STA bitmap
        STA bitmap + 1

;; *new = 0;
        STA (new)
        STA (new), Y

;; for(;;) {

.level1

;;    /* did we write an X co-ordinate? */
;;    if(*new < 0)
;;       new++;

{
        LDA (new), Y
        BPL skip_inc
        M_INCREMENT_PTR_BS new
.skip_inc
}



;;    if(prev == next) {
;;       /* start a new group of rows */
;;       if(*next == 0) {
;;          *new = 0;
;;          return;
;;       }
;;       y = *next++ + 1;
;;    } else {
;;       /* move to next row and work out which ones to scan */
;;       if(*prev == y--)
;;          prev++;
;;       if(*this == y)
;;          this++;
;;       if(*next == y-1)
;;          next++;
;;    }

{
        ;; if(prev == next) {
        LDA prev
        CMP next
        BNE else
        LDA prev + 1
        CMP next + 1
        BNE else

        ;; if(*next == 0) {
        LDA (next)
        ORA (next), Y
        BNE next_not_zero

        ;; *new = 0;
        LDA #0
        STA (new)
        STA (new), Y
        M_INCREMENT_PTR_BS new
        ;; return;
IF _MATCHBOX
        JMP reset_banksel_buffers
ELSE
        RTS
ENDIF

.next_not_zero
        ;; y = *next++ + 1;
        LDA (next)
        CLC
        ADC #1
        STA yy
        LDA (next), Y
        ADC #0
        STA yy + 1
        M_INCREMENT_PTR_BS next

        BRA endif

.else

;;       if(*prev == y--)
;;          prev++;

        LDA (prev)
        CMP yy
        BNE skip_inc_prev
        LDA (prev), Y
        CMP yy + 1
        BNE skip_inc_prev
        M_INCREMENT_PTR prev
.skip_inc_prev
        M_DECREMENT yy

;;       if(*this == y)
;;          this++;
        LDA (this)
        CMP yy
        BNE skip_inc_this
        LDA (this), Y
        CMP yy + 1
        BNE skip_inc_this
        M_INCREMENT_PTR this
.skip_inc_this

;;       if(*next == y-1)
;;          next++;
        LDA (next)
        CLC
        ADC #1
        TAX
        LDA (next), Y
        ADC #0
        CMP yy + 1
        BNE skip_inc_next
        CPX yy
        BNE skip_inc_next
        M_INCREMENT_PTR_BS next
.skip_inc_next

.endif
}

;;    /* write new row co-ordinate */
;;    *new = y;

        LDA yy
        STA (new)
        LDA yy + 1
        STA (new), Y

;;    for(;;) {

.level2

;;       /* skip to the leftmost cell */
;;       x = *prev;

        LDA (prev)
        STA xx
        LDA (prev), Y
        STA xx + 1

;;       if(x > *this)
;;          x = *this;

        M_ASSIGN_IF_GREATER xx, this

;;       if(x > *next)
;;          x = *next;

        M_ASSIGN_IF_GREATER xx, next

;;       /* end of line? */
;;       if(x >= 0)
;;          break;

        LDA xx + 1
        BMI x_negative
        JMP level1
.x_negative

;;       for(;;) {

.level3

;;          /* add a column to the bitmap */
;;          if(*prev == x) {
;;             bitmap |= 0100;
;;             prev++;
;;          }

        M_UPDATE_BITMAP_IF_EQUAL_TO_X prev, bitmap, &40

;;          if(*this == x) {
;;             bitmap |= 0200;
;;             this++;
;;          }

        M_UPDATE_BITMAP_IF_EQUAL_TO_X this, bitmap, &80

;;          if(*next == x) {
;;             bitmap |= 0400;
;;             next++;
;;          }

        M_UPDATE_BITMAP_IF_EQUAL_TO_X next, bitmap + 1, &01


;;          /* what does this bitmap indicate? */
;;          if(state[bitmap] == LIVE)
;;             *++new = x - 1;

{
        LDX bitmap
        LDA bitmap + 1
        BNE upper_half
        LDA state, X
        BEQ else
        BNE is_live
.upper_half
        LDA state + &100, X
        BEQ else
.is_live
        M_INCREMENT_PTR_BS new
        LDA xx
        SEC
        SBC #1
        STA (new)
        LDA xx + 1
        SBC #0
        STA (new), Y
        BRA endif

.else

;;          else if(bitmap == 000)
;;             break;

        LDA bitmap + 1
        ORA bitmap
        BNE endif

        JMP level2

.endif
 }

;;          /* move right */
;;          bitmap >>= 3;

        LDA bitmap + 1
        LSR A
        ROR bitmap
        LSR A
        ROR bitmap
        LSR A
        ROR bitmap
        STA bitmap + 1

;;          x += 1;

        M_INCREMENT xx

        JMP level3

;;       }
;;    }
;; }

;; ************************************************************
;; moves the x/y start to the top left corner
;; ************************************************************
.list_life_offset_top_left
        LDX ui_zoom
        LDA xstart
        SEC
        SBC zoom_correction_lo, X
        STA xstart
        LDA xstart + 1
        SBC zoom_correction_hi, X
        STA xstart + 1
        LDA ystart
        CLC
        ADC zoom_correction_lo, X
        STA ystart
        LDA ystart + 1
        ADC zoom_correction_hi, X
        STA ystart + 1
        RTS

.zoom_correction_lo
        EQUB &00, &00, &00, &80, &40, &20, &10

.zoom_correction_hi
        EQUB &04, &02, &01, &00, &00, &00, &00

;; ************************************************************
;; counts the cells (in BCD)
;; ************************************************************

;; (list) points to the cell list to count
;;
.list_life_count_cells
{
        LDX #cell_count - count_base
        JSR clear_count
        LDY #1
.loop
        M_INCREMENT_PTR_BS list
        LDA (list), Y           ; the sign bit indicates X vs Y coordinates
        BPL y_or_termiator
        LDA #1
        JSR add_to_count
        BRA loop
.y_or_termiator
        ORA (list)
        BNE loop
IF _MATCHBOX
        JMP reset_banksel_buffers
ELSE
        RTS
ENDIF
}

;; ************************************************************
;; prune the universe
;; ************************************************************

;; (this) points to the source list
;; (new) points to the destination list

.list_life_prune_cells
{
        LDY #1
.loop
        LDA (this), Y           ; is it an X or a Y coordinate?
        BPL is_y_or_terminator
        CMP #&80                ; at the left edge?
        BEQ skip_copy_x
        CMP #&FF                ; at the right edge?
        BEQ skip_copy_x
.copy
        STA (new), Y            ; copy the coord
        LDA (this)
        STA (new)
        M_INCREMENT_PTR_BS new
.skip_copy_x
        M_INCREMENT_PTR_BS this
        BRA loop

.is_y_or_terminator
        TAX                     ; test for the terminating 0000
        ORA (this)
        BEQ terminator
        TXA
        CMP #&7F                ; at the top edge?
        BEQ skip_row            ; yes, skip the whole row
        CMP #&00                ; at the bottom edge?
        BNE copy                ; no, copy the y coord and continue processing x coords

.skip_row
        M_INCREMENT_PTR_BS this
        LDA (this), Y           ; is it an X or a Y coordinate?
        BMI skip_row
        BPL is_y_or_terminator

.terminator
        LDA #0
        STA (new)
        STA (new), Y
        M_INCREMENT_PTR_BS new
IF _MATCHBOX
        JMP reset_banksel_buffers
ELSE
        RTS
ENDIF
}

;; ************************************************************
;; list_life_load_buffer()
;; ************************************************************

;; Initializes the (this) buffer from the 256x256 screen_base
;;

.list_life_load_buffer
{

        LDA #<SCRN_BASE
        STA scrn
        LDA #>SCRN_BASE
        STA scrn + 1

        ;; y is positive and decreasing as you go down the screen
        ;; e.g. 1256 ... 1001
        LDA #<Y_START
        STA yy
        LDA #>Y_START
        STA yy + 1

        LDX #0

.row_loop
        TXA
        PHA

        LDY #&1F
.test_blank_loop
        LDA (scrn), Y
        BNE row_not_blank
        DEY
        BPL test_blank_loop

.next_row

        LDA scrn
        CLC
        ADC #&20
        STA scrn
        LDA scrn + 1
        ADC #0
        STA scrn + 1

        LDA yy
        SEC
        SBC #1
        STA yy
        LDA yy + 1
        SBC #0
        STA yy + 1

        PLA
        TAX
        DEX
        BNE row_loop

        LDA #0
        STA yy
        STA yy + 1

        ;; write the terminating zero
        M_WRITE this, yy

IF _MATCHBOX
        JMP reset_banksel_buffers
ELSE
        RTS
ENDIF

.row_not_blank

        ;; Start the row by writing the positive Y value
        M_WRITE this, yy

        ;; x is negative and increasing as you go right across the screen
        LDA #<X_START
        STA xx
        LDA #>X_START
        STA xx + 1

        LDY #&00
.byte_loop
        LDA (scrn), Y
        PHA
        LDX #&07
.bit_loop
        PLA
        ASL A
        PHA
        BCC pixel_zero
        M_WRITE this, xx
.pixel_zero
        M_INCREMENT xx
        DEX
        BPL bit_loop
        PLA
        INY
        CPY #&20
        BNE byte_loop

        JMP next_row

}

;; ************************************************************
;; list_life_update_delta()
;; ************************************************************

;; (list) points to the cell list

;; xend = xstart + 256;
;; yend = ystart - 8;
;; while (1) {
;;     yy = *list;
;;     if (ystart < yy) {
;;         // Skip over x-coordinates
;;         do {
;;            list++;
;;         } while (*list < 0);
;;     } else if (yend < yy) {
;;         temp = 32 * (ystart - yy);
;;         while (1);
;;            xx = *++list;
;;            // Test if we have read a y coordinate
;;            if (xx >= 0) {
;;                break;
;;            }
;;            if (xx >= xstart && xx < xend) {
;;              X_reg = temp + (xx - xstart) >> 3;
;;              *(delta_base + X_reg) ^= mask[(xx - xstart) & 7];
;;            }
;;         }
;;     } else {
;;         return;
;;     }
;; }

MACRO M_LIST_LIFE_UPDATE_DELTA zoom
{

;; xend = xstart + 256;

        CLC
        LDA xstart
        ADC #<(2048 DIV (2^zoom))
        STA xend
        LDA xstart + 1
        ADC #>(2048 DIV (2^zoom))
        STA xend + 1

;; yend = ystart - 8;

        LDA ystart
        SEC
        SBC #(64 DIV (2^zoom))
        STA yend
        LDA ystart + 1
        SBC #0
        STA yend + 1;

;; while (1) {


.while_level1

;;     yy = *list;

        LDY #0
        LDA (list), Y
        STA yy
        INY
        LDA (list), Y
        STA yy + 1

;;     if (ystart < yy) {

        ;; yy and ystart can only be positive (or zero), so we can use 16-bit unsigned comparison
        LDA ystart
        CMP yy
        LDA ystart + 1
        SBC yy + 1

        BCS else1

;;         // Skip over x-coordinates
;;         do {
;;            list++;
;;         } while (*list < 0);

        LDY #1
.skip_over_x
        M_INCREMENT_PTR_BS list
        LDA (list), Y
        BMI skip_over_x

        BPL while_level1

;;     } else if (yend < yy) {

.else1
        ;; yy and yend can only be positive (or zero), so we can use 16-bit unsigned comparison
        LDA yend
        CMP yy
        LDA yend + 1
        SBC yy + 1

        BCC not_else2
        RTS

.not_else2
;;         temp = 32 * (ystart - yy);

;; 8 bits is sufficient here, as the Y strip is 8 pixels high
;; 0 1/8  4
;; 1 1/4  8
;; 2 1/2  16
;; 3 1    32
;; 4 2    64
;; 5 4    128
;; 6 8    256

        LDA ystart
        SEC
        SBC yy
FOR i,1,zoom + 2
        ASL A
NEXT
IF zoom < 3
        AND #&E0
ENDIF
        STA temp

;;         while(1) {

.while_level2

;;            xx = *++list;

        M_INCREMENT_PTR_BS list

        LDY #0
        LDA (list), Y
        STA xx
        INY
        LDA (list), Y
        STA xx + 1

;;            // Test if we have read a y coordinate
;;            if (xx >= 0) {
;;                break;
;;            }
        BPL while_level1

;;            if (xx >= xstart && xx < xend) {

        ;; xx and xstart and xend can only be negative, so we can use 16-bit unsigned comparison
        LDA xx
        CMP xstart
        LDA xx + 1
        SBC xstart + 1
        BCC while_level2

        LDA xx
        CMP xend
        LDA xx + 1
        SBC xend + 1
        BCS while_level2

;;              X_reg = temp + (xx - xstart) >> 3;
;;              *(delta_base + X_reg) ^= mask[(xx - xstart) & 7];

;; if zoom < 3 prescale (xx - xstart)
;; 0 1/8  >>3 then >>3
;; 1 1/4  >>2 then >>3
;; 2 1/2  >>1 then >>3
;; 3 1    >>0 then >>3
;; 4 2    >>0 then >>2
;; 5 4    >>0 then >>1
;; 6 8    >>0 then >>0
        LDA xx
        SEC
        SBC xstart
;; If zoom < 3 then xx - xstart can be > 256
;; so first pre-scale
IF (zoom < 3)
        STA tmplsb
        LDA xx + 1
        SBC xstart + 1
        FOR i, 1, 3-zoom
                LSR A
                ROR tmplsb
        NEXT
        LDA tmplsb
        TAY
        LSR A
        LSR A
        LSR A
ELSE
        TAY
        IF (zoom < 6)
                FOR i, 1, 6-zoom
                        LSR A
                NEXT
        ENDIF
ENDIF
;; The result in A should always be in the range 0.31
        CLC
        ADC temp
        TAX
;; 0 1/8  6x AND #&07
;; 1 1/4  5x AND #&07
;; 2 1/2  4x AND #&07
;; 3 1    3x AND #&07
;; 4 2    2x AND #&03
;; 5 4    1x AND #&01
;; 6 8    0x AND #&00
        TYA
IF (zoom <= 3)
        AND #&07
ELSE
        AND #(&07 >> (zoom - 3))
ENDIF
        TAY

FOR i, 0, 2^(zoom - 3) - 1
        LDA DELTA_BASE + 32 * i, X
        ORA pixel_mask, Y
        STA DELTA_BASE + 32 * i, X
NEXT

        JMP while_level2

;;     } else {
;;         return;
;;     }
;; }

}

.pixel_mask
IF zoom = 6
        EQUB &FF
ELIF zoom = 5
        EQUB &F0, &0F
ELIF zoom = 4
        EQUB &C0, &30, &0C, &03
ELSE
        EQUB &80, &40, &20, &10, &08, &04, &02, &01
ENDIF

ENDMACRO

.list_life_update_delta
        ASL A
        TAX
        JMP (zoom_table, X)

.zoom_table
        EQUW list_life_update_delta_1_8x
        EQUW list_life_update_delta_1_4x
        EQUW list_life_update_delta_1_2x
        EQUW list_life_update_delta_1x
        EQUW list_life_update_delta_2x
        EQUW list_life_update_delta_4x
        EQUW list_life_update_delta_8x

.list_life_update_delta_1_8x
M_LIST_LIFE_UPDATE_DELTA 0

.list_life_update_delta_1_4x
M_LIST_LIFE_UPDATE_DELTA 1

.list_life_update_delta_1_2x
M_LIST_LIFE_UPDATE_DELTA 2

.list_life_update_delta_1x
M_LIST_LIFE_UPDATE_DELTA 3

.list_life_update_delta_2x
M_LIST_LIFE_UPDATE_DELTA 4

.list_life_update_delta_4x
M_LIST_LIFE_UPDATE_DELTA 5

.list_life_update_delta_8x
M_LIST_LIFE_UPDATE_DELTA 6
