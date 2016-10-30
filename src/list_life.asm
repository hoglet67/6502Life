;; ************************************************************
;; Variables
;; ************************************************************

buffer1 = &9C00                 ; 9C00-F7FF = 23K
buffer2 = &4000                 ; 4000-9BFF = 23K

DEAD = 0
LIVE = 1

this   = &70                    ; used by both
new    = &72                    ; used by both

prev   = &74                    ; used by list_life()
next   = &76                    ; used by list_life()
bitmap = &78                    ; used by list_life()

list   = &74                    ; used by list_life_update_delta()
xstart = &76                    ; used by list_life_update_delta()
ystart = &78                    ; used by list_life_update_delta()
        
temp   = &7A                    ; used by both
xx     = &7C                    ; used by both
yy     = &7E                    ; used by both
        
xend   = &80                    ; used by list_life_update_delta()
yend   = &82                    ; used by list_life_update_delta()
        
;; ************************************************************
;; Macros
;; ************************************************************

MACRO M_INCREMENT zp
        INC zp
        BNE nocarry
        INC zp + 1
.nocarry
ENDMACRO

MACRO M_DECREMENT zp
        LDA zp
        BNE nocarry
        DEC zp + 1
.nocarry
        DEC zp
ENDMACRO

MACRO M_INCREMENT_PTR zp
        INC zp
        INC zp
        BNE nocarry
        INC zp + 1
.nocarry
ENDMACRO

;;       if(x > *this)
;;          x = *this;

MACRO M_ASSIGN_IF_GREATER val, ptr
        LDY #0
        LDA val
        CMP (ptr), Y
        INY
        LDA val + 1
        SBC (ptr), Y
        BVC label
        EOR #&80
.label
        BMI skip_assign_val
        LDA (ptr), Y
        STA val + 1
        DEY
        LDA (ptr), Y
        STA val
.skip_assign_val
ENDMACRO

;;          if(*prev == x) {
;;             bitmap |= 0100;
;;             prev++;
;;          }

MACRO M_UPDATE_BITMAP_IF_EQUAL_TO_X ptr, bmaddr, bmmask
        LDY #0
        LDA (ptr), Y
        CMP xx
        BNE skip_inc
        INY
        LDA (ptr), Y
        CMP xx + 1
        BNE skip_inc
        LDA bmaddr
        ORA #bmmask
        STA bmaddr
        M_INCREMENT_PTR ptr
.skip_inc
ENDMACRO

MACRO M_WRITE ptr, val
        TYA
        PHA
        LDY #0
        LDA val
        STA (ptr), Y
        INY
        LDA val + 1
        STA (ptr), Y
        INC ptr
        INC ptr
        BNE nocarry
        INC ptr + 1
.nocarry
        PLA
        TAY
ENDMACRO

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

;; prev = next = this;
        LDA this
        STA prev
        STA next
        LDA this + 1
        STA prev + 1
        STA next + 1

;; bitmap = 0;
        LDA #0
        STA bitmap
        STA bitmap + 1

;; *new = 0;
        LDY #0
        TYA
        STA (new), Y
        INY
        STA (new), Y

;; for(;;) {

.level1

;;    /* did we write an X co-ordinate? */
;;    if(*new < 0)
;;       new++;

{
        LDY #1
        LDA (new), Y
        BPL skip_inc
        M_INCREMENT_PTR new
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
        LDY #0
        LDA (next), Y
        INY
        ORA (next), Y
        BNE next_not_zero

        ;; *new = 0;
        LDY #0
        TYA
        STA (new), Y
        INY
        STA (new), Y
        ;; return;
        RTS

.next_not_zero
        ;; y = *next++ + 1;
        LDY #0
        LDA (next), Y
        CLC
        ADC #1
        STA yy
        INY
        LDA (next), Y
        ADC #0
        STA yy + 1
        M_INCREMENT_PTR next

        JMP endif

.else

;;       if(*prev == y--)
;;          prev++;

        LDY #0
        LDA (prev), Y
        CMP yy
        BNE skip_inc_prev
        INY
        LDA (prev), Y
        CMP yy + 1
        BNE skip_inc_prev
        M_INCREMENT_PTR prev
.skip_inc_prev
        M_DECREMENT yy

;;       if(*this == y)
;;          this++;
        LDY #0
        LDA (this), Y
        CMP yy
        BNE skip_inc_this
        INY
        LDA (this), Y
        CMP yy + 1
        BNE skip_inc_this
        M_INCREMENT_PTR this
.skip_inc_this

;;       if(*next == y-1)
;;          next++;
        LDY #0
        LDA (next), Y
        CLC
        ADC #1
        TAX
        INY
        LDA (next), Y
        ADC #0
        CMP yy + 1
        BNE skip_inc_next
        CPX yy
        BNE skip_inc_next
        M_INCREMENT_PTR next
.skip_inc_next

.endif
}

;;    /* write new row co-ordinate */
;;    *new = y;

        LDY #0
        LDA yy
        STA (new), Y
        INY
        LDA yy + 1
        STA (new), Y

;;    for(;;) {

.level2

;;       /* skip to the leftmost cell */
;;       x = *prev;

        LDY #0
        LDA (prev), Y
        STA xx
        INY
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
        M_INCREMENT_PTR new
        LDY #0
        LDA xx
        SEC
        SBC #1
        STA (new), Y
        INY
        LDA xx + 1
        SBC #0
        STA (new), Y
        JMP endif

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

        LSR bitmap + 1
        ROR bitmap
        LSR bitmap + 1
        ROR bitmap
        LSR bitmap + 1
        ROR bitmap

;;          x += 1;

        M_INCREMENT xx

        JMP level3

;;       }
;;    }
;; }

;; ************************************************************
;; list_life_load_buffer()
;; ************************************************************

;; Initializes the (this) buffer from the 256x256 screen_base
;;

.list_life_load_buffer
{

        LDA #<scrn_base
        STA scrn
        LDA #>scrn_base
        STA scrn + 1

        ;; y is positive and decreasing as you go down the screen
        ;; 256 ... 1
        LDA #<Y_START
        STA yy
        LDA #>Y_START
        STA yy + 1

.row_loop

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

       ORA yy
       BNE row_loop

       ;; write the terminating zero
       M_WRITE this, yy

       RTS

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


.list_life_update_delta
{

;; xend = xstart + 256;

        LDA xstart
        STA xend
        LDA xstart + 1
        CLC
        ADC #1
        STA xend + 1

;; yend = ystart - 8;

        LDA ystart
        SEC
        SBC #8
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
        M_INCREMENT_PTR list
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

        BCS else2

;;         temp = 32 * (ystart - yy);

        ;; 8 bits is sufficient here, as the Y strip is 8 pixels high
        LDA ystart
        SEC
        SBC yy
        ASL A
        ASL A
        ASL A
        ASL A
        ASL A
        STA temp

;;         while(1) {

.while_level2

;;            xx = *++list;

        M_INCREMENT_PTR list

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

        LDA xend
        CMP xx
        LDA xend + 1
        SBC xx + 1
        BCC while_level2

;;              X_reg = temp + (xx - xstart) >> 3;
;;              *(delta_base + X_reg) ^= mask[(xx - xstart) & 7];

        LDA xx
        SEC
        SBC xstart
        TAY

        LSR A
        LSR A
        LSR A
        CLC
        ADC temp
        TAX

        TYA
        AND #&07
        TAY

        LDA delta_base, X
        EOR pixel_mask, Y
        STA delta_base, X

        JMP while_level2

;;     } else {
;;         return;
;;     }
;; }


.else2
        RTS

}

.pixel_mask
        EQUB &80, &40, &20, &10, &08, &04, &02, &01

;; ************************************************************
;; list_life_update_screen_vdu()
;; ************************************************************

;; (list) points to the cell list

;; for now we wll just emit plot commands

.list_life_update_screen_vdu
{

.next_yy
        LDY #0
        LDA (list), Y
        STA yy
        INY
        LDA (list), Y
        STA yy + 1

        M_INCREMENT_PTR list

        ORA yy
        BNE next_xx
        RTS

.next_xx

        LDY #0
        LDA (list), Y
        STA xx
        INY
        LDA (list), Y
        STA xx + 1

        ;; If list is positive, then we have a new Y
        BPL next_yy

        M_INCREMENT_PTR list

        ;; plot a point

        LDA #25
        JSR OSWRCH
        LDA #69
        JSR OSWRCH

        LDA xx
        CLC
        ADC #0
        STA temp
        LDA xx + 1
        ADC #&01
        STA temp + 1

        ASL temp
        ROL temp + 1
        ASL temp
        ROL temp + 1

        LDA temp
        JSR OSWRCH
        LDA temp + 1
        JSR OSWRCH

        LDA yy
        CLC
        STA temp
        LDA yy + 1
        STA temp + 1

        ASL temp
        ROL temp + 1
        ASL temp
        ROL temp + 1

        LDA temp
        JSR OSWRCH
        LDA temp + 1
        JSR OSWRCH

        JMP next_xx
}