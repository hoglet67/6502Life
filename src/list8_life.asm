;; ************************************************************
;; list_life()
;; ************************************************************

;; Args are (this) and (new)

.list_life
;;  keep Y as the constant 1 for efficient access of the high byte of a short
        LDY #1

;; prev = next = this;
        LDA this
        STA prev
        STA next
        LDA this + 1
        STA prev + 1
        STA next + 1
        
;; rearprev = middprev = foreprev = 0;
;; rearthis = middthis = forethis = 0;
;; rearnext = middnext = forenext = 0;
        STZ forethis
        STZ middthis

;; hicnt_r = locnt_r = hicnt_m = locnt_m = hicnt_f = locnt_f = 0
        STZ hicnt_r
        STZ locnt_r
        STZ hicnt_m
        STZ locnt_m
        STZ hicnt_f
        STZ locnt_f

;; *new = 0;
        LDA #0
        STA (new)
        STA (new), Y

;; for(;;) {

.level1

;;    /* did we write an X co-ordinate? */
;;    if(*new < 0)
;;       new += 2;

{
        LDA (new), Y
        BPL skip_inc
        M_INCREMENT_BY_3 new    ; an X values is a two byte coordinate and a one-byte bitmap
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
        M_INCREMENT_BY_2 new
        ;; return;
        RTS

.next_not_zero
        ;; y = *next++ + 1;
        LDA (next)
        CLC
        ADC #1
        STA yy
        LDA (next), Y
        ADC #0
        STA yy + 1
        M_INCREMENT_BY_2 next

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
        M_INCREMENT_BY_2 prev
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
        M_INCREMENT_BY_2 this
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
        M_INCREMENT_BY_2 next
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
{
;;          /* add a column to the bitmap */
;;          foreprev = 0;
;;          forethis = 0;
;;          forenext = 0;
;;          locnt_f = 0;
;;          hicnt_f = 0;
         STZ forethis
         STZ locnt_f
         STZ hicnt_f

;;          if(*prev == x) {
;;             foreprev = *++prev;
;;             prev++;
;;          }

        M_UPDATE_CHUNK_IF_EQUAL_TO_X prev, 0

;;          if(*this == x) {
;;             forethis = *++this;
;;             this++;
;;          }

        M_UPDATE_CHUNK_IF_EQUAL_TO_X this, forethis

;;          if(*next == x) {
;;             forenext = *++next;
;;             next++;
;;          }

        M_UPDATE_CHUNK_IF_EQUAL_TO_X next, 0

;;          outcome =
;;             (ltsum[(hicnt_m & 0xfc) | (locnt_r & 0x03)] << 4) |
;;             (rtsum[(locnt_m & 0xc0) | (hicnt_m & 0x3f)] << 4) |
;;             (ltsum[(locnt_m & 0xfc) | (hicnt_m & 0x03)]     ) |
;;             (rtsum[(hicnt_f & 0xc0) | (locnt_m & 0x3f)]     );
;;          mask =
;;             (ltmsk[(hicnt_m & 0xfc) | (locnt_r & 0x03)] << 4) |
;;             (rtmsk[(locnt_m & 0xc0) | (hicnt_m & 0x3f)] << 4) |
;;             (ltmsk[(locnt_m & 0xfc) | (hicnt_m & 0x03)]     ) |
;;             (rtmsk[(hicnt_f & 0xc0) | (locnt_m & 0x3f)]     );
;;          newbmp = (middthis & mask) | outcome;

        LDA middthis
        BEQ oldbmp_zero
        
        LDA hicnt_m
        AND #&FC
        STA t
        LDA locnt_r
        AND #&03
        ORA t
        TAX
        LDA locnt_m
        AND #&C0
        STA t
        LDA hicnt_m
        AND #&3F
        ORA t
        TAY

        LDA ltsum, X
        ORA rtsum, Y
        ASL A
        ASL A
        ASL A
        ASL A
        STA outcome
        LDA ltmsk, X
        ORA rtmsk, Y
        ASL A
        ASL A
        ASL A
        ASL A
        STA mask

        LDA locnt_m
        AND #&FC
        STA t
        LDA hicnt_m
        AND #&03
        ORA t
        TAX
        LDA hicnt_f
        AND #&C0
        STA t
        LDA locnt_m
        AND #&3F
        ORA t
        TAY

        LDA ltsum, X
        ORA rtsum, Y
        ORA outcome
        STA outcome
        LDA ltmsk, X
        ORA rtmsk, Y
        ORA mask
        AND middthis
        LDY #1                  ;; restore the Y constant value of 1
        ORA outcome
        BRA newbmp_ready

.oldbmp_zero
        
        LDA hicnt_m
        AND #&FC
        STA t
        LDA locnt_r
        AND #&03
        ORA t
        TAX
        LDA locnt_m
        AND #&C0
        STA t
        LDA hicnt_m
        AND #&3F
        ORA t
        TAY

        LDA ltsum, X
        ORA rtsum, Y
        ASL A
        ASL A
        ASL A
        ASL A
        STA outcome
        
        LDA locnt_m
        AND #&FC
        STA t
        LDA hicnt_m
        AND #&03
        ORA t
        TAX
        LDA hicnt_f
        AND #&C0
        STA t
        LDA locnt_m
        AND #&3F
        ORA t
        TAY

        LDA ltsum, X
        ORA rtsum, Y
        LDY #1                  ;; restore the Y constant value of 1        
        ORA outcome
        
.newbmp_ready
        
        ;; A now holds the new chunk

;;          if(newbmp) {
;;             if (*new < 0) {
;;                // last coordinate was an X 
;;                new += 2;
;;             } else {
;;                // last coordinate was a Y
;;                new += 1;
;;             }
;;					*new = x - 1;
;;					*(new + 1) = newbmp;
;;          }

        BEQ else

        STA outcome
        LDA (new), Y
        BMI last_was_x
        M_INCREMENT_BY_2 new
        BRA store_x
.last_was_x
        M_INCREMENT_BY_3 new
.store_x
        LDA xx
        SEC
        SBC #1
        STA (new)
        LDA xx + 1
        SBC #0
        STA (new), Y
        INY
        LDA outcome
        STA (new), Y
        DEY

        JMP endif

;;          else if(middprev==0 && middthis==0 && middnext==0
;;                 && foreprev==0 && forethis==0 && forenext==0) break;
.else
        LDA locnt_m
        BNE endif
        LDA hicnt_m
        BNE endif
        LDA locnt_f
        BNE endif
        LDA hicnt_f
        BNE endif

        JMP level2

.endif

;;				/* move right */
;;          rearprev = middprev; middprev = foreprev;
;;          rearthis = middthis; middthis = forethis;
;;          rearnext = middnext; middnext = forenext;
;;          locnt_r = locnt_m; locnt_m = locnt_f;
;;          hicnt_r = hicnt_m; hicnt_m = hicnt_f;

        LDA forethis
        STA middthis
        LDA locnt_m
        STA locnt_r
        LDA locnt_f
        STA locnt_m
        LDA hicnt_m
        STA hicnt_r
        LDA hicnt_f
        STA hicnt_m
        
;;				x += 1;

        M_INCREMENT xx

        JMP level3

}

;;       }
;;    }
;; }

;; ************************************************************
;; counts the cells (in BCD)
;; ************************************************************

;; (list) points to the cell list to count
;;
.list_life_count_cells
{
        LDA #0
        STA cell_count
        STA cell_count + 1
        STA cell_count + 2
        LDY #1
.loop
        LDA (list), Y           ; the sign bit indicates X vs Y coordinates
        BPL y_or_termiator
        INY
        LDA (list), Y           ; read the bitmap
        DEY
        TAX
        SED
        LDA bitcnt, X
        CLC
        ADC cell_count
        STA cell_count
        BCC inc_by_3
        LDA cell_count + 1
        ADC #0
        STA cell_count + 1
        BCC inc_by_3
        LDA cell_count + 2
        ADC #0
        STA cell_count + 2
.inc_by_3
        CLD
        M_INCREMENT_BY_3 list
        BRA loop
.y_or_termiator
        ORA (list)
        BEQ exit
.inc_by_2
        M_INCREMENT_BY_2 list
        BRA loop
.exit
        LDA #30
        JSR OSWRCH
        LDA #10
        JSR OSWRCH
        JSR OSWRCH

        LDX #2
.ll_print_loop        
        LDA cell_count, X
        JSR ll_print_bcd
        DEX
        BPL ll_print_loop
        RTS
        
.ll_print_bcd        
        PHA
        LSR A
        LSR A
        LSR A
        LSR A
        JSR ll_print_bcd_digit
        PLA
.ll_print_bcd_digit
        AND #&0F
        ORA #&30
        JMP OSWRCH

.cell_count
        EQUB 0,0,0
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

        
        ;; write the terminating zero
        LDY #1
        LDA #0
        STA (this)
        STA (this), Y
        M_INCREMENT_BY_2 this

        RTS

.row_not_blank

        ;; Start the row by writing the positive Y value
        LDY #1
        LDA yy
        STA (this)
        LDA yy + 1
        STA (this), Y
        M_INCREMENT_BY_2 this

        ;; x is negative and increasing as you go right across the screen
        LDA #<X_START
        STA xx
        LDA #>X_START
        STA xx + 1

        LDY #&00
.byte_loop
        LDA (scrn), Y
        BEQ skip_zero

        PHY
        LDY #2
        STA (this), Y
        DEY
        LDA xx + 1
        STA (this), Y
        LDA xx
        STA (this)
        M_INCREMENT_BY_3 this
        PLY

.skip_zero
        M_INCREMENT xx
        INY
        CPY #&20
        BNE byte_loop

        JMP next_row

}

;; ************************************************************
;; list_life_update_delta()
;; ************************************************************

;; (list) points to the cell list

;; NOTE: this won't actually work in C, as the list offsets are butchered
;; TODO: add suitable casts so it will with list being char *
        
;; xend = xstart + 32;
;; yend = ystart - 8;
;; while (1) {
;;     yy = *list;
;;     if (ystart < yy) {
;;         list += 2
;;         // Skip over x-coordinates
;;         while (*list < 0) {
;;            list += 3;
;;         }
;;     } else if (yend < yy) {
;;         list += 2
;;         temp = 32 * (ystart - yy);
;;         while (1);
;;            xx = *list;
;;            // Test if we have read a y coordinate
;;            if (xx >= 0) {
;;                break;
;;            }
;;            bmp = *(list + 2);
;;            list += 3;
;;            if (xx >= xstart && xx < xend) {
;;              X_reg = temp + xx - xstart
;;              *(delta_base + X_reg) ^= bmp;
;;            }
;;         }
;;     } else {
;;         return;
;;     }
;; }


.list_life_update_delta
{


;; xend = xstart + 32;  // X-coordinates are chunks

        LDA xstart
        CLC
        ADC #32
        STA xend
        LDA xstart + 1
        ADC #0
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

;;         list += 2
        M_INCREMENT_BY_2 list  ;; skip over y
        
;;         // Skip over x-coordinates
;;         while (*list < 0) {
;;            list += 3;
;;         }

        LDY #1
.skip_over_x
        LDA (list), Y
        BPL while_level1
        M_INCREMENT_BY_3 list
        BRA skip_over_x


;;     } else if (yend < yy) {

.else1

        ;; yy and yend can only be positive (or zero), so we can use 16-bit unsigned comparison
        LDA yend
        CMP yy
        LDA yend + 1
        SBC yy + 1

        BCS else2

;;         list += 2
        M_INCREMENT_BY_2 list  ;; skip over y        
        
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

;;            xx = *list;

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
        BMI less_than_zero
        JMP while_level1
.less_than_zero
        
;;            bmp = *(list + 2);
;;            list += 3;

        INY
        LDA (list), Y        
        STA bitmap
        
        M_INCREMENT_BY_3 list

        
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

;;              X_reg = temp + xx - xstart
;;              *(delta_base + X_reg) ^= bmp;
                
        LDA xx
        SEC
        SBC xstart
        CLC
        ADC temp
        TAX
        LDA bitmap
        EOR DELTA_BASE, X
        STA DELTA_BASE, X

        JMP while_level2

;;     } else {
;;         return;
;;     }
;; }


.else2
        RTS

}


ALIGN 256
        
;;         .... LOOK-UP TABLES ....

.ltsum
;; FOR Y%=0 TO 255
;; A%=FNbits((Y%AND3)OR((Y%AND&F0)DIV4))
;; B%=FNbits(Y%DIV4)
;; [OPT I%
;; EQUB -8*(A%=3)-4*(B%=3)
;; ]
;; NEXT
 EQUB &00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00,&08,&04,&04,&04,&0c
 EQUB &00,&00,&08,&00,&00,&00,&08,&00,&04,&04,&0c,&04,&00,&00,&08,&00
 EQUB &00,&08,&00,&00,&04,&0c,&04,&04,&00,&08,&00,&00,&00,&08,&00,&00
 EQUB &0c,&04,&04,&04,&08,&00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00
 EQUB &00,&00,&08,&00,&00,&00,&08,&00,&04,&04,&0c,&04,&00,&00,&08,&00
 EQUB &00,&08,&00,&00,&04,&0c,&04,&04,&00,&08,&00,&00,&00,&08,&00,&00
 EQUB &0c,&04,&04,&04,&08,&00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&08,&00,&00,&04,&0c,&04,&04,&00,&08,&00,&00,&00,&08,&00,&00
 EQUB &0c,&04,&04,&04,&08,&00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &0c,&04,&04,&04,&08,&00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00

.rtsum
;; FOR Y%=0 TO 255
;; A%=FNbits((Y%AND&F)OR((Y%AND&C0)DIV4))
;; B%=FNbits(Y%AND&3F)
;; [OPT I%
;; EQUB -(A%&=3)-2*(B%=3)
;; ]
;; NEXT
 EQUB &00,&00,&00,&03,&00,&00,&03,&00,&00,&03,&00,&00,&03,&00,&00,&00
 EQUB &00,&00,&02,&01,&00,&02,&01,&00,&02,&01,&00,&00,&01,&00,&00,&00
 EQUB &00,&02,&00,&01,&02,&00,&01,&00,&00,&01,&00,&00,&01,&00,&00,&00
 EQUB &02,&00,&00,&01,&00,&00,&01,&00,&00,&01,&00,&00,&01,&00,&00,&00
 EQUB &00,&00,&01,&02,&00,&01,&02,&00,&01,&02,&00,&00,&02,&00,&00,&00
 EQUB &00,&00,&03,&00,&00,&03,&00,&00,&03,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&02,&01,&00,&02,&01,&00,&00,&01,&00,&00,&00,&00,&00,&00,&00
 EQUB &02,&00,&01,&00,&00,&01,&00,&00,&01,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&01,&00,&02,&01,&00,&02,&00,&00,&02,&00,&00,&02,&00,&00,&00
 EQUB &00,&01,&02,&00,&01,&02,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&03,&00,&00,&03,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &02,&01,&00,&00,&01,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &01,&00,&00,&02,&00,&00,&02,&00,&00,&02,&00,&00,&02,&00,&00,&00
 EQUB &01,&00,&02,&00,&00,&02,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00
 EQUB &01,&02,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &03,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00


.ltmsk
;; FOR Y%=0 TO 255
;; A%=FNbits((Y%AND3)OR((Y%AND&F0)DIV4))
;; B%=FNbits(Y%DIV4)
;; [OPT I%
;; EQUB -8*(&A%=4)-4*(B%=4)
;; ]
;; NEXT
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00,&08,&04,&04,&04,&0c
 EQUB &00,&00,&08,&00,&00,&00,&08,&00,&04,&04,&0c,&04,&00,&00,&08,&00
 EQUB &00,&08,&00,&00,&04,&0c,&04,&04,&00,&08,&00,&00,&00,&08,&00,&00
 EQUB &00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00,&08,&04,&04,&04,&0c
 EQUB &00,&00,&08,&00,&00,&00,&08,&00,&04,&04,&0c,&04,&00,&00,&08,&00
 EQUB &00,&08,&00,&00,&04,&0c,&04,&04,&00,&08,&00,&00,&00,&08,&00,&00
 EQUB &0c,&04,&04,&04,&08,&00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00
 EQUB &00,&00,&08,&00,&00,&00,&08,&00,&04,&04,&0c,&04,&00,&00,&08,&00
 EQUB &00,&08,&00,&00,&04,&0c,&04,&04,&00,&08,&00,&00,&00,&08,&00,&00
 EQUB &0c,&04,&04,&04,&08,&00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&08,&00,&00,&04,&0c,&04,&04,&00,&08,&00,&00,&00,&08,&00,&00
 EQUB &0c,&04,&04,&04,&08,&00,&00,&00,&08,&00,&00,&00,&08,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00


.rtmsk
;; FOR Y%=0 TO 255
;; A%=FNbits((Y%AND&F)OR((Y%AND&C0)DIV4))
;; B%=FNbits(Y%AND&3F)
;; [OPT I%
;; EQUB -(A%&=4)-2*(B%=4)
;; ]
;; NEXT
 EQUB &00,&00,&00,&00,&00,&00,&00,&03,&00,&00,&03,&00,&00,&03,&00,&00
 EQUB &00,&00,&00,&02,&00,&00,&02,&01,&00,&02,&01,&00,&02,&01,&00,&00
 EQUB &00,&00,&02,&00,&00,&02,&00,&01,&02,&00,&01,&00,&00,&01,&00,&00
 EQUB &00,&02,&00,&00,&02,&00,&00,&01,&00,&00,&01,&00,&00,&01,&00,&00
 EQUB &00,&00,&00,&01,&00,&00,&01,&02,&00,&01,&02,&00,&01,&02,&00,&00
 EQUB &00,&00,&00,&03,&00,&00,&03,&00,&00,&03,&00,&00,&03,&00,&00,&00
 EQUB &00,&00,&02,&01,&00,&02,&01,&00,&02,&01,&00,&00,&01,&00,&00,&00
 EQUB &00,&02,&00,&01,&02,&00,&01,&00,&00,&01,&00,&00,&01,&00,&00,&00
 EQUB &00,&00,&01,&00,&00,&01,&00,&02,&01,&00,&02,&00,&00,&02,&00,&00
 EQUB &00,&00,&01,&02,&00,&01,&02,&00,&01,&02,&00,&00,&02,&00,&00,&00
 EQUB &00,&00,&03,&00,&00,&03,&00,&00,&03,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&02,&01,&00,&02,&01,&00,&00,&01,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&01,&00,&00,&01,&00,&00,&02,&00,&00,&02,&00,&00,&02,&00,&00
 EQUB &00,&01,&00,&02,&01,&00,&02,&00,&00,&02,&00,&00,&02,&00,&00,&00
 EQUB &00,&01,&02,&00,&01,&02,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00
 EQUB &00,&03,&00,&00,&03,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00

.lo
;; FOR Y%=0 TO 255
;; [OPT I%
;; EQUB FNst&retch(Y%AND&F)
;; ]
;; NEXT
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55
 EQUB &00,&01,&04,&05,&10,&11,&14,&15,&40,&41,&44,&45,&50,&51,&54,&55

.hi
;; FOR Y%=0 TO 255
;; [OPT I%
;; EQUB FNst&retch(Y%DIV&10)
;; ]
;; NEXT
 EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
 EQUB &01,&01,&01,&01,&01,&01,&01,&01,&01,&01,&01,&01,&01,&01,&01,&01
 EQUB &04,&04,&04,&04,&04,&04,&04,&04,&04,&04,&04,&04,&04,&04,&04,&04
 EQUB &05,&05,&05,&05,&05,&05,&05,&05,&05,&05,&05,&05,&05,&05,&05,&05
 EQUB &10,&10,&10,&10,&10,&10,&10,&10,&10,&10,&10,&10,&10,&10,&10,&10
 EQUB &11,&11,&11,&11,&11,&11,&11,&11,&11,&11,&11,&11,&11,&11,&11,&11
 EQUB &14,&14,&14,&14,&14,&14,&14,&14,&14,&14,&14,&14,&14,&14,&14,&14
 EQUB &15,&15,&15,&15,&15,&15,&15,&15,&15,&15,&15,&15,&15,&15,&15,&15
 EQUB &40,&40,&40,&40,&40,&40,&40,&40,&40,&40,&40,&40,&40,&40,&40,&40
 EQUB &41,&41,&41,&41,&41,&41,&41,&41,&41,&41,&41,&41,&41,&41,&41,&41
 EQUB &44,&44,&44,&44,&44,&44,&44,&44,&44,&44,&44,&44,&44,&44,&44,&44
 EQUB &45,&45,&45,&45,&45,&45,&45,&45,&45,&45,&45,&45,&45,&45,&45,&45
 EQUB &50,&50,&50,&50,&50,&50,&50,&50,&50,&50,&50,&50,&50,&50,&50,&50
 EQUB &51,&51,&51,&51,&51,&51,&51,&51,&51,&51,&51,&51,&51,&51,&51,&51
 EQUB &54,&54,&54,&54,&54,&54,&54,&54,&54,&54,&54,&54,&54,&54,&54,&54
 EQUB &55,&55,&55,&55,&55,&55,&55,&55,&55,&55,&55,&55,&55,&55,&55,&55

.bitcnt
;; FOR Y%=0 TO 255
;; [OPT I%
;; EQUB FNbi&ts2(Y%)
;; ]
;; NEXT
 EQUB &00,&01,&01,&02,&01,&02,&02,&03,&01,&02,&02,&03,&02,&03,&03,&04
 EQUB &01,&02,&02,&03,&02,&03,&03,&04,&02,&03,&03,&04,&03,&04,&04,&05
 EQUB &01,&02,&02,&03,&02,&03,&03,&04,&02,&03,&03,&04,&03,&04,&04,&05
 EQUB &02,&03,&03,&04,&03,&04,&04,&05,&03,&04,&04,&05,&04,&05,&05,&06
 EQUB &01,&02,&02,&03,&02,&03,&03,&04,&02,&03,&03,&04,&03,&04,&04,&05
 EQUB &02,&03,&03,&04,&03,&04,&04,&05,&03,&04,&04,&05,&04,&05,&05,&06
 EQUB &02,&03,&03,&04,&03,&04,&04,&05,&03,&04,&04,&05,&04,&05,&05,&06
 EQUB &03,&04,&04,&05,&04,&05,&05,&06,&04,&05,&05,&06,&05,&06,&06,&07
 EQUB &01,&02,&02,&03,&02,&03,&03,&04,&02,&03,&03,&04,&03,&04,&04,&05
 EQUB &02,&03,&03,&04,&03,&04,&04,&05,&03,&04,&04,&05,&04,&05,&05,&06
 EQUB &02,&03,&03,&04,&03,&04,&04,&05,&03,&04,&04,&05,&04,&05,&05,&06
 EQUB &03,&04,&04,&05,&04,&05,&05,&06,&04,&05,&05,&06,&05,&06,&06,&07
 EQUB &02,&03,&03,&04,&03,&04,&04,&05,&03,&04,&04,&05,&04,&05,&05,&06
 EQUB &03,&04,&04,&05,&04,&05,&05,&06,&04,&05,&05,&06,&05,&06,&06,&07
 EQUB &03,&04,&04,&05,&04,&05,&05,&06,&04,&05,&05,&06,&05,&06,&06,&07
 EQUB &04,&05,&05,&06,&05,&06,&06,&07,&05,&06,&06,&07,&06,&07,&07,&08

;; DEFFNbits(X%)
;; IF X%<4  =X%
;; =(X%AND3)+FNbits(X% DIV4)
;;
;;
;; DEFFNstretch(X%)
;; IF X%<2 =X%
;; =(X%AND1) + 4*FNstretch(X%DIV2)
;;
;;
;; DEFFNbits2(X%)
;; IF X%<2 =X%
;; =(X%AND1) +FNbits2(X%DIV2)
        
