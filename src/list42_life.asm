;; ************************************************************
;; list_life()
;; ************************************************************


;; prev = this;
;; ul = ur = ll = lr = 0;
;; *new = 0;
;; for(;;) {
;;    /* did we write an X co-ordinate? */
;;    if(*new < 0)
;;       new+=2;
;;    if(prev == this) {
;;       /* start a new group of rows */
;;       if(*this == 0) {
;;          *new = 0;
;;          return;
;;       }
;;       y = *this++;
;;    } else {
;;       /* move to next row and work out which ones to scan */
;;       if(*prev == y)
;;          prev++;
;;         y-=2;
;;       if(*this == y)
;;          this++;
;;    }
;;    /* write new row co-ordinate */
;;    *new = y + 1;
;;    for(;;) {
;;       /* skip to the leftmost cell */
;;       x = *prev;
;;       if(x > *this)
;;          x = *this;
;;       /* end of line? */
;;       if(x >= 0)
;;          break;
;;       for(;;) {
;;          ur = lr = 0;
;;          /* add a column to the bitmap */
;;          if(*prev == x) {
;;             ur = *(prev + 1);
;;             prev += 2;
;;          }
;;          if(*this == x) {
;;             lr = *(this + 1);
;;             this += 2;
;;          }
;;          if ((ul | ur | ll | lr) == 0) {
;;             break;
;;          }
;;          /* UL table lookup, produces bits 7 and 6 */
;;          page = ll >> 4;               
;;          index = ul;
;;          outcome = table[(page << 8) | index] & 0xC0;
;;          /* LL table lookup, produces bits 3 and 2 */
;;          page = ul & 0x0F;
;;          index = ll;
;;          outcome |= table[(page << 8) | index] & 0x0C;
;;          /* UR table lookup, produces bits 5 and 4 */
;;          page = ((lr & 0xC0) | (ll & 0x30)) >> 4;
;;          index = (ur & 0xCC) | (ul & 0x33);
;;          outcome |= table[(page << 8) | index] & 0x30;
;;          /* LR table lookup, produces bits 1 and 0 */
;;          page = (ur & 0x0C) | (ul & 0x03);
;;          index = (lr & 0xCC) | (ll & 0x33);
;;          outcome |= table[(page << 8) | index] & 0x03;
;;          if (outcome) {
;;             if (*new < 0) {
;;                // last coordinate was an X 
;;                new += 2;
;;             } else {
;;                // last coordinate was a Y
;;                new += 1;
;;             }
;;             *new = x - 3;
;;             *(new + 1) = outcome;
;;          }
;;          /* move right */
;;          ul = ur;
;;          ll = lr;
;;          x += 4;
;;       }
;;    }
;;  }
;;}
;;
        
;; Args are (this) and (new)

.list_life
;;  keep Y as the constant 1 for efficient access of the high byte of a short
        LDY #1

;;	prev = this;
        LDA this
        STA prev
        LDA this + 1
        STA prev + 1
        
;;	ul = ur = ll = lr = 0;
        STZ ul
        STZ ur
        STZ ll
        STZ lr

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

;;		if(prev == this) {
;;			/* start a new group of rows */
;;			if(*this == 0) {
;;				*new = 0;
;;				return;
;;			}
;;			y = *this++;
;;		} else {
;;			/* move to next row and work out which ones to scan */
;;			if(*prev == y)
;;				prev++;
;;         y-=2;
;;			if(*this == y)
;;				this++;
;;		}

{
;;		if(prev == this) {
        LDA prev
        CMP this
        BNE else
        LDA prev + 1
        CMP this + 1
        BNE else

        ;; if(*this == 0) {
        LDA (this)
        ORA (this), Y
        BNE this_not_zero

        ;; *new = 0;
        LDA #0
        STA (new)
        STA (new), Y
        M_INCREMENT_BY_2 new
        ;; return;
        RTS

.this_not_zero
        ;; y = *this++;
        LDA (this)
        STA yy
        LDA (this), Y
        STA yy + 1
        M_INCREMENT_BY_2 this

        BRA endif

.else

;;			if(*prev == y)
;;				prev++;
        LDA (prev)
        CMP yy
        BNE skip_inc_prev
        LDA (prev), Y
        CMP yy + 1
        BNE skip_inc_prev
        M_INCREMENT_BY_2 prev
.skip_inc_prev

;;         y-=2;
        
        LDA yy
        SEC
        SBC #2
        STA yy
        BCS no_carry
        DEC yy + 1
.no_carry        

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

.endif
}

;;		/* write new row co-ordinate */
;;		*new = y + 1;

        LDA yy
        CLC
        ADC #1
        STA (new)
        LDA yy + 1
        ADC #0
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
;;				/* add a column to the bitmap */
;;          ur = lr = 0;
         STZ ur
         STZ lr

;;				if(*prev == x) {
;;             ur = *(prev + 1);
;;					prev += 2;
;;          }

        M_UPDATE_CHUNK_IF_EQUAL_TO_X prev, ur

;;				if(*this == x) {
;;             lr = *(this + 1);
;;					this += 2;
;;				}
        M_UPDATE_CHUNK_IF_EQUAL_TO_X this, lr


;;            if ((ul | ur | ll | lr) == 0) {
;;					break;
;;            }
        LDA ul
        ORA ur
        ORA ll
        ORA lr
        BNE not_break
        JMP level2        
.not_break
        

        ; inputs for first bitpair
        ; AAAA ....
        ; AaaA ....
        ; BBBB ....
        ; .... ....
        
;;          /* UL table lookup, produces bits 7 and 6 */
;;          page = ll >> 4;               
;;          index = ul;
;;          outcome = table[(page << 8) | index] & 0xC0;

        STZ outcome
        
        LDA ul
        ORA ll
        BEQ left_zero

        LDX ll                  ; 3 - read a nibble for the first bitpair
        LDA bp1_convert, X      ; 4 - convert nibble to high pointer
        STA bp1_table + 2       ; 4
        LDY ul                  ; 3 - read a byte
        .bp1_table              ;
        LDA table_base, Y       ; 4 - get the first bitpair of the result
        AND #&C0                ; 2
        ORA outcome
        STA outcome             ; 3 - store our work in progress
                                ; 27 cycles so far
        
        ; inputs for second bitpair
        ; .... ....
        ; AAAA ....
        ; BbbB ....
        ; BBBB ....
        
;;          /* LL table lookup, produces bits 3 and 2 */
;;          page = ul & 0x0F;
;;          index = ll;
;;          outcome |= table[(page << 8) | index] & 0x0C;

        LDA bp2_convert, Y      ; 4 - convert nibble to high pointer
        STA bp2_table + 2       ; 4
        .bp2_table              ;
        LDA table_base, X       ; 4 - get the second bitpair of the result
        AND #&0C                ; 2
        ORA outcome             ; 3 - combine
        STA outcome             ; 3 - and store
                                ; 27+30 cycles so far
.left_zero
        
        ; inputs for third bitpair
        ; ..AA CC..
        ; ..Aa cC..
        ; ..BB DD..
        ; .... ....
        
;;          /* UR table lookup, produces bits 5 and 4 */
;;          page = ((lr & 0xC0) | (ll & 0x30)) >> 4;
;;          index = (ur & 0xCC) | (ul & 0x33);
;;          outcome |= table[(page << 8) | index] & 0x30;

        LDA ll                  ; 3 - read first half nibble for the third bitpair
        AND #&30                ; 2
        STA t                   ; 3
        LDA lr                  ; 3 - read second half nibble
        AND #&C0                ; 2
        ORA t                   ; 3
        TAX                     ; 2 - read the nibble index for the third bitpair
        LDA bp3_convert, X      ; 4 - convert nibble to high pointer
        STA bp3_table + 2       ; 4
        
        LDA ul                  ; 3 - read a half byte
        AND #&33                ; 2
        STA t                   ; 3
        LDA ur                  ; 3 - read a half byte
        AND #&CC                ; 2
        ORA t                   ; 3 - combine to make the byte
        TAX                     ; 2
        
        .bp3_table              ;
        LDA table_base, X       ; 4 - get the third bitpair of the result
        AND #&30                ; 2
        ORA outcome             ; 3 - combine
        STA outcome             ; 3 - and store
                                ; 27+30+62 cycles so far
        
        ; inputs for fourth bitpair
        ; .... ....
        ; ..AA CC..
        ; ..Bb dD..
        ; ..BB DD..
        
;;          /* LR table lookup, produces bits 1 and 0 */
;;          page = (ur & 0x0C) | (ul & 0x03);
;;          index = (lr & 0xCC) | (ll & 0x33);
;;          outcome |= table[(page << 8) | index] & 0x03;
        
        LDA ul                  ; 3 - read first half nibble for the fourth bitpair
        AND #&03                ; 2
        STA t                   ; 3
        LDA ur                  ; 3 - read second half nibble
        AND #&0C                ; 2
        ORA t                   ; 3
        CLC                     ; 2 - read the nibble index for the fourth bitpair
        ADC #>table_base        ; 2 - convert nibble to high pointer 
        STA bp4_table + 2       ; 4
        
        LDA ll                  ; 3 - read a half byte
        AND #&33                ; 2
        STA t                   ; 3
        LDA lr                  ; 3 - read a half byte
        AND #&CC                ; 2
        ORA t                   ; 3 - combine to make the byte
        TAX                     ; 2
        
        .bp4_table              ;
        LDA table_base, X       ; 4 - get the fourth bitpair of the result
        AND #&03                ; 2

        LDY #1                  ; restore constant Y value
        
        ORA outcome             ; 3 - combine - result is in A
                                ; 148
        
        ;; A now holds the new chunk

;;          if (outcome) {
;;             if (*new < 0) {
;;                // last coordinate was an X 
;;                new += 2;
;;             } else {
;;                // last coordinate was a Y
;;                new += 1;
;;             }
;;             *new = x - 3;
;;             *(new + 1) = outcome;
;;          }


        BEQ endif

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
        SBC #3
        STA (new)
        LDA xx + 1
        SBC #0
        STA (new), Y
        INY
        LDA outcome
        STA (new), Y
        DEY

.endif

;;          /* move right */
;;          ul = ur;
;;          ll = lr;

        LDA ur
        STA ul
        LDA lr
        STA ll

;;          x += 4;

        LDA xx
        CLC
        ADC #4
        STA xx
        BCC jmp_level3
        INC xx + 1
.jmp_level3        
        JMP level3
}

;;       }
;;    }
;; }

;; ************************************************************
;; moves the x/y start to the top left corner
;; ************************************************************
;;
;; as list8 life doesn't support zooming, the offset is fixed 
.list_life_offset_top_left
        LDA xstart
        SEC
        SBC #&20
        STA xstart
        LDA xstart + 1
        SBC #0
        STA xstart + 1
        LDA ystart
        CLC
        ADC #&40
        STA ystart
        LDA ystart + 1
        ADC #0
        STA ystart + 1        
        RTS
        
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
        LDA (list), Y           ; the sign bit indicates X vs Y coordinates
        BPL y_or_termiator
        INY
        LDA (list), Y           ; read the bitmap
        DEY
        TAX
        LDA bitcnt, X
        LDX #cell_count - count_base
        JSR add_to_count
        M_INCREMENT_BY_3 list
        BRA loop
.y_or_termiator
        ORA (list)
        BEQ exit
.inc_by_2
        M_INCREMENT_BY_2 list
        BRA loop
.exit
        RTS
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
        
;; xend = xstart + 256;
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
;;              X_reg = temp + (xx - xstart) >> 3;
;;              ;; a chunk is 4 bits wide, and can align with a byte in 8 possible ways
;;              *(delta_base + X_reg) ^= bmp;
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
        CLC
        ADC #0
        STA xend
        LDA xstart + 1
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

;; ************************ TODO ******************************

        RTS

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

.bitcnt
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

.bp1_convert
.bp3_convert
FOR i, 0, 255
    EQUB (>table_base) + (i >> 4)
NEXT

.bp2_convert
.bp4_convert
FOR i, 0, 255
    EQUB (>table_base) + (i AND &0F)
NEXT

;; A7  A6  A5  A4  C7  C6 
;; A3  A2  A1  A0  C3  C2
;; B7  B6  B5  B4  D7  D6
;; B3  B2  B1  B0  D3  D2
;;
;; 4K lookup table, broken into page and index:
;;
;; X11 X10 X9 X8 <<< Page
;;  X7  X6 X5 X4 <<< Index 
;;  X3  X2 X1 X0 <<< Index
;;
;; Upper Left  - produces bits (7) and [6]
;;   B7  B6  B5  B4
;;   A7  A4  A5  A4
;;   A3 (A2)[A1] A0
;;
;; Upper Right - produces bits (5) and [4]
;;   D7  D6  B5  B4
;;   C7  C6  A5  A4
;;  [C3] C2  A1 (A0)
;;
;; Lower Left  - produces bits (3) and [2]
;;   A3  A2  A1  A0
;;   B7 (B6)[B5] B4
;;   B3  B2  B1  B0
;;
;; Lower Right - produces bits (1) and [0]
;;   C3  C2  A1  A0
;;  [D7] D6  B5 (B4)
;;   D3  D2  B1  B0
;; 
;; Data created by code in misc/list42_life.c

.table_base
        EQUB &00,&00,&00,&00,&00,&00,&00,&44,&00,&00,&00,&22,&00,&11,&88,&ff
        EQUB &00,&00,&00,&66,&00,&55,&44,&73,&00,&33,&22,&77,&11,&76,&ff,&fa
        EQUB &00,&00,&00,&66,&00,&44,&cc,&ee,&00,&22,&aa,&ec,&88,&ff,&e6,&f5
        EQUB &00,&66,&66,&66,&44,&37,&ee,&bb,&22,&77,&ce,&dd,&ff,&be,&d7,&90
        EQUB &00,&00,&00,&44,&00,&55,&cc,&d9,&00,&11,&88,&ff,&99,&dc,&dd,&fa
        EQUB &00,&55,&44,&73,&55,&00,&d9,&aa,&11,&76,&ff,&fa,&dc,&aa,&fa,&aa
        EQUB &00,&44,&cc,&ee,&cc,&9d,&cc,&bb,&88,&ff,&6e,&7d,&dd,&be,&77,&30
        EQUB &44,&37,&ee,&bb,&9d,&aa,&bb,&aa,&ff,&be,&5f,&18,&be,&aa,&12,&00
        EQUB &00,&00,&00,&22,&00,&11,&88,&ff,&00,&33,&aa,&b9,&99,&bb,&b3,&f5
        EQUB &00,&33,&22,&77,&11,&67,&ff,&eb,&33,&33,&9b,&dd,&bb,&ee,&d7,&c0
        EQUB &00,&22,&aa,&ec,&88,&ff,&e6,&f5,&aa,&b9,&00,&55,&b3,&f5,&55,&55
        EQUB &22,&77,&ce,&dd,&ff,&af,&d7,&81,&9b,&dd,&55,&55,&d7,&84,&55,&00
        EQUB &00,&11,&88,&ff,&99,&cd,&dd,&eb,&99,&bb,&3b,&7d,&99,&ee,&77,&60
        EQUB &11,&67,&ff,&eb,&cd,&aa,&eb,&aa,&bb,&ee,&5f,&48,&ee,&aa,&42,&00
        EQUB &88,&ff,&6e,&7d,&dd,&af,&77,&21,&3b,&7d,&55,&55,&77,&24,&55,&00
        EQUB &ff,&af,&5f,&09,&af,&aa,&03,&00,&5f,&0c,&55,&00,&06,&00,&00,&00
        EQUB &00,&00,&00,&66,&00,&55,&44,&73,&00,&33,&22,&75,&11,&76,&ff,&f8
        EQUB &00,&77,&66,&73,&55,&22,&73,&22,&33,&76,&57,&50,&76,&22,&da,&88
        EQUB &00,&66,&66,&64,&44,&37,&ee,&b9,&22,&75,&cc,&dd,&ff,&bc,&d5,&90
        EQUB &66,&37,&46,&11,&37,&22,&9b,&88,&57,&14,&dd,&98,&9e,&88,&90,&80
        EQUB &00,&55,&44,&73,&55,&00,&d9,&aa,&11,&76,&ff,&f8,&dc,&aa,&fa,&a8
        EQUB &55,&22,&73,&22,&00,&22,&aa,&aa,&76,&22,&da,&88,&aa,&aa,&8a,&88
        EQUB &44,&37,&ee,&b9,&9d,&aa,&bb,&a8,&ff,&bc,&5d,&18,&be,&a8,&10,&00
        EQUB &37,&22,&9b,&88,&aa,&aa,&8a,&88,&9e,&88,&18,&08,&8a,&88,&00,&00
        EQUB &00,&33,&22,&75,&11,&67,&ff,&e9,&33,&31,&99,&dd,&bb,&ec,&d5,&c0
        EQUB &33,&67,&57,&41,&67,&22,&cb,&88,&13,&44,&dd,&c8,&ce,&88,&c0,&80
        EQUB &22,&75,&cc,&dd,&ff,&ad,&d5,&81,&99,&dd,&55,&55,&d5,&84,&55,&00
        EQUB &57,&05,&dd,&89,&8f,&88,&81,&80,&dd,&8c,&55,&00,&84,&80,&00,&00
        EQUB &11,&67,&ff,&e9,&cd,&aa,&eb,&a8,&bb,&ec,&5d,&48,&ee,&a8,&40,&00
        EQUB &67,&22,&cb,&88,&aa,&aa,&8a,&88,&ce,&88,&48,&08,&8a,&88,&00,&00
        EQUB &ff,&ad,&5d,&09,&af,&a8,&01,&00,&5d,&0c,&55,&00,&04,&00,&00,&00
        EQUB &8f,&88,&09,&08,&8a,&88,&00,&00,&0c,&08,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&66,&00,&44,&cc,&ea,&00,&22,&aa,&ec,&88,&ff,&e6,&f1
        EQUB &00,&66,&66,&62,&44,&33,&ea,&bb,&22,&77,&ce,&d9,&ff,&ba,&d3,&90
        EQUB &00,&66,&ee,&ec,&cc,&ae,&e6,&a0,&aa,&ec,&44,&44,&e6,&b5,&44,&11
        EQUB &66,&26,&ce,&88,&ae,&bb,&82,&91,&ce,&9d,&44,&11,&97,&90,&11,&10
        EQUB &00,&44,&cc,&ea,&cc,&99,&c8,&bb,&88,&ff,&6e,&79,&dd,&ba,&73,&30
        EQUB &44,&33,&ea,&bb,&99,&aa,&bb,&aa,&ff,&ba,&5b,&18,&ba,&aa,&12,&00
        EQUB &cc,&ae,&6e,&28,&8c,&bb,&22,&31,&6e,&3d,&44,&11,&37,&30,&11,&10
        EQUB &ae,&bb,&0a,&19,&bb,&aa,&13,&00,&1f,&18,&11,&10,&12,&00,&10,&00
        EQUB &00,&22,&aa,&ec,&88,&ff,&e6,&f1,&aa,&b9,&00,&55,&b3,&f5,&55,&51
        EQUB &22,&77,&ce,&d9,&ff,&ab,&d3,&81,&9b,&dd,&55,&51,&d7,&80,&51,&00
        EQUB &aa,&ec,&44,&44,&e6,&b5,&44,&11,&00,&55,&44,&55,&55,&15,&55,&11
        EQUB &ce,&9d,&44,&11,&97,&81,&11,&01,&55,&15,&55,&11,&15,&00,&11,&00
        EQUB &88,&ff,&6e,&79,&dd,&ab,&73,&21,&3b,&7d,&55,&51,&77,&20,&51,&00
        EQUB &ff,&ab,&5b,&09,&ab,&aa,&03,&00,&5f,&08,&51,&00,&02,&00,&00,&00
        EQUB &6e,&3d,&44,&11,&37,&21,&11,&01,&55,&15,&55,&11,&15,&00,&11,&00
        EQUB &1f,&09,&11,&01,&03,&00,&01,&00,&15,&00,&11,&00,&00,&00,&00,&00
        EQUB &00,&66,&66,&60,&44,&33,&ea,&b9,&22,&75,&cc,&d9,&ff,&b8,&d1,&90
        EQUB &66,&33,&42,&11,&33,&22,&9b,&88,&57,&10,&d9,&98,&9a,&88,&90,&80
        EQUB &66,&24,&cc,&88,&ae,&b9,&80,&91,&cc,&9d,&44,&11,&95,&90,&11,&10
        EQUB &06,&11,&88,&99,&9b,&88,&91,&80,&9d,&98,&11,&10,&90,&80,&10,&00
        EQUB &44,&33,&ea,&b9,&99,&aa,&bb,&a8,&ff,&b8,&59,&18,&ba,&a8,&10,&00
        EQUB &33,&22,&9b,&88,&aa,&aa,&8a,&88,&9a,&88,&18,&08,&8a,&88,&00,&00
        EQUB &ae,&b9,&08,&19,&bb,&a8,&11,&00,&1d,&18,&11,&10,&10,&00,&10,&00
        EQUB &9b,&88,&19,&08,&8a,&88,&00,&00,&18,&08,&10,&00,&00,&00,&00,&00
        EQUB &22,&75,&cc,&d9,&ff,&a9,&d1,&81,&99,&dd,&55,&51,&d5,&80,&51,&00
        EQUB &57,&01,&d9,&89,&8b,&88,&81,&80,&dd,&88,&51,&00,&80,&80,&00,&00
        EQUB &cc,&9d,&44,&11,&95,&81,&11,&01,&55,&15,&55,&11,&15,&00,&11,&00
        EQUB &9d,&89,&11,&01,&81,&80,&01,&00,&15,&00,&11,&00,&00,&00,&00,&00
        EQUB &ff,&a9,&59,&09,&ab,&a8,&01,&00,&5d,&08,&51,&00,&00,&00,&00,&00
        EQUB &8b,&88,&09,&08,&8a,&88,&00,&00,&08,&08,&00,&00,&00,&00,&00,&00
        EQUB &1d,&09,&11,&01,&01,&00,&01,&00,&15,&00,&11,&00,&00,&00,&00,&00
        EQUB &09,&08,&01,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&44,&00,&55,&cc,&d9,&00,&11,&88,&ff,&99,&dc,&d5,&f2
        EQUB &00,&55,&44,&73,&55,&00,&d9,&aa,&11,&76,&ff,&fa,&dc,&aa,&f2,&a2
        EQUB &00,&44,&cc,&ee,&cc,&9d,&c4,&b3,&88,&ff,&66,&75,&d5,&b6,&77,&30
        EQUB &44,&37,&ee,&bb,&9d,&aa,&b3,&a2,&ff,&be,&57,&10,&b6,&a2,&12,&00
        EQUB &00,&55,&cc,&d9,&dd,&88,&d9,&88,&99,&dc,&5d,&7a,&dc,&88,&50,&22
        EQUB &55,&00,&d9,&aa,&88,&88,&88,&aa,&dc,&aa,&7a,&2a,&88,&aa,&22,&22
        EQUB &cc,&9d,&4c,&3b,&9d,&88,&11,&22,&5d,&3e,&77,&30,&14,&22,&32,&20
        EQUB &9d,&aa,&3b,&2a,&88,&aa,&22,&22,&3e,&2a,&12,&00,&22,&22,&02,&00
        EQUB &00,&11,&88,&ff,&99,&cd,&d5,&e3,&99,&bb,&33,&75,&91,&e6,&77,&60
        EQUB &11,&67,&ff,&eb,&cd,&aa,&e3,&a2,&bb,&ee,&57,&40,&e6,&a2,&42,&00
        EQUB &88,&ff,&66,&75,&d5,&a7,&77,&21,&33,&75,&55,&55,&77,&24,&55,&00
        EQUB &ff,&af,&57,&01,&a7,&a2,&03,&00,&57,&04,&55,&00,&06,&00,&00,&00
        EQUB &99,&cd,&5d,&6b,&cd,&88,&41,&22,&19,&6e,&77,&60,&44,&22,&62,&20
        EQUB &cd,&aa,&6b,&2a,&88,&aa,&22,&22,&6e,&2a,&42,&00,&22,&22,&02,&00
        EQUB &5d,&2f,&77,&21,&05,&22,&23,&20,&77,&24,&55,&00,&26,&20,&00,&00
        EQUB &2f,&2a,&03,&00,&22,&22,&02,&00,&06,&00,&00,&00,&02,&00,&00,&00
        EQUB &00,&55,&44,&73,&55,&00,&d9,&aa,&11,&76,&ff,&f8,&dc,&aa,&f2,&a0
        EQUB &55,&22,&73,&22,&00,&22,&aa,&aa,&76,&22,&da,&88,&aa,&aa,&82,&80
        EQUB &44,&37,&ee,&b9,&9d,&aa,&b3,&a0,&ff,&bc,&55,&10,&b6,&a0,&10,&00
        EQUB &37,&22,&9b,&88,&aa,&aa,&82,&80,&9e,&88,&10,&00,&82,&80,&00,&00
        EQUB &55,&00,&d9,&aa,&88,&88,&88,&aa,&dc,&aa,&7a,&28,&88,&aa,&22,&20
        EQUB &00,&22,&aa,&aa,&88,&aa,&aa,&aa,&aa,&aa,&0a,&08,&aa,&aa,&02,&00
        EQUB &9d,&aa,&3b,&28,&88,&aa,&22,&20,&3e,&28,&10,&00,&22,&20,&00,&00
        EQUB &aa,&aa,&0a,&08,&aa,&aa,&02,&00,&0a,&08,&00,&00,&02,&00,&00,&00
        EQUB &11,&67,&ff,&e9,&cd,&aa,&e3,&a0,&bb,&ec,&55,&40,&e6,&a0,&40,&00
        EQUB &67,&22,&cb,&88,&aa,&aa,&82,&80,&ce,&88,&40,&00,&82,&80,&00,&00
        EQUB &ff,&ad,&55,&01,&a7,&a0,&01,&00,&55,&04,&55,&00,&04,&00,&00,&00
        EQUB &8f,&88,&01,&00,&82,&80,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &cd,&aa,&6b,&28,&88,&aa,&22,&20,&6e,&28,&40,&00,&22,&20,&00,&00
        EQUB &aa,&aa,&0a,&08,&aa,&aa,&02,&00,&0a,&08,&00,&00,&02,&00,&00,&00
        EQUB &2f,&28,&01,&00,&22,&20,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &0a,&08,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&44,&cc,&ea,&cc,&99,&c0,&b3,&88,&ff,&66,&71,&d5,&b2,&73,&30
        EQUB &44,&33,&ea,&bb,&99,&aa,&b3,&a2,&ff,&ba,&53,&10,&b2,&a2,&12,&00
        EQUB &cc,&ae,&66,&20,&84,&b3,&22,&31,&66,&35,&44,&11,&37,&30,&11,&10
        EQUB &ae,&bb,&02,&11,&b3,&a2,&13,&00,&17,&10,&11,&10,&12,&00,&10,&00
        EQUB &cc,&99,&48,&3b,&99,&88,&11,&22,&5d,&3a,&73,&30,&10,&22,&32,&20
        EQUB &99,&aa,&3b,&2a,&88,&aa,&22,&22,&3a,&2a,&12,&00,&22,&22,&02,&00
        EQUB &0c,&3b,&22,&31,&11,&22,&33,&20,&37,&30,&11,&10,&32,&20,&10,&00
        EQUB &3b,&2a,&13,&00,&22,&22,&02,&00,&12,&00,&10,&00,&02,&00,&00,&00
        EQUB &88,&ff,&66,&71,&d5,&a3,&73,&21,&33,&75,&55,&51,&77,&20,&51,&00
        EQUB &ff,&ab,&53,&01,&a3,&a2,&03,&00,&57,&00,&51,&00,&02,&00,&00,&00
        EQUB &66,&35,&44,&11,&37,&21,&11,&01,&55,&15,&55,&11,&15,&00,&11,&00
        EQUB &17,&01,&11,&01,&03,&00,&01,&00,&15,&00,&11,&00,&00,&00,&00,&00
        EQUB &5d,&2b,&73,&21,&01,&22,&23,&20,&77,&20,&51,&00,&22,&20,&00,&00
        EQUB &2b,&2a,&03,&00,&22,&22,&02,&00,&02,&00,&00,&00,&02,&00,&00,&00
        EQUB &37,&21,&11,&01,&23,&20,&01,&00,&15,&00,&11,&00,&00,&00,&00,&00
        EQUB &03,&00,&01,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &44,&33,&ea,&b9,&99,&aa,&b3,&a0,&ff,&b8,&51,&10,&b2,&a0,&10,&00
        EQUB &33,&22,&9b,&88,&aa,&aa,&82,&80,&9a,&88,&10,&00,&82,&80,&00,&00
        EQUB &ae,&b9,&00,&11,&b3,&a0,&11,&00,&15,&10,&11,&10,&10,&00,&10,&00
        EQUB &9b,&88,&11,&00,&82,&80,&00,&00,&10,&00,&10,&00,&00,&00,&00,&00
        EQUB &99,&aa,&3b,&28,&88,&aa,&22,&20,&3a,&28,&10,&00,&22,&20,&00,&00
        EQUB &aa,&aa,&0a,&08,&aa,&aa,&02,&00,&0a,&08,&00,&00,&02,&00,&00,&00
        EQUB &3b,&28,&11,&00,&22,&20,&00,&00,&10,&00,&10,&00,&00,&00,&00,&00
        EQUB &0a,&08,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &ff,&a9,&51,&01,&a3,&a0,&01,&00,&55,&00,&51,&00,&00,&00,&00,&00
        EQUB &8b,&88,&01,&00,&82,&80,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &15,&01,&11,&01,&01,&00,&01,&00,&15,&00,&11,&00,&00,&00,&00,&00
        EQUB &01,&00,&01,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &2b,&28,&01,&00,&22,&20,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &0a,&08,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &01,&00,&01,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&22,&00,&11,&88,&ff,&00,&33,&aa,&b9,&99,&ba,&b3,&f4
        EQUB &00,&33,&22,&77,&11,&66,&ff,&ea,&33,&32,&9b,&dc,&ba,&ee,&d6,&c0
        EQUB &00,&22,&aa,&ec,&88,&ff,&e6,&f5,&aa,&b9,&00,&55,&b3,&f4,&55,&54
        EQUB &22,&77,&ce,&dd,&ff,&ae,&d7,&80,&9b,&dc,&55,&54,&d6,&84,&54,&00
        EQUB &00,&11,&88,&ff,&99,&cc,&dd,&ea,&99,&ba,&3b,&7c,&98,&ee,&76,&60
        EQUB &11,&66,&ff,&ea,&cc,&aa,&ea,&aa,&ba,&ee,&5e,&48,&ee,&aa,&42,&00
        EQUB &88,&ff,&6e,&7d,&dd,&ae,&77,&20,&3b,&7c,&55,&54,&76,&24,&54,&00
        EQUB &ff,&ae,&5f,&08,&ae,&aa,&02,&00,&5e,&0c,&54,&00,&06,&00,&00,&00
        EQUB &00,&33,&aa,&b9,&99,&ab,&b3,&e5,&bb,&b9,&11,&11,&b3,&a0,&11,&44
        EQUB &33,&23,&9b,&cd,&ab,&ee,&c7,&c0,&9b,&88,&11,&44,&82,&c4,&44,&40
        EQUB &aa,&b9,&00,&55,&b3,&e5,&55,&45,&11,&11,&11,&55,&11,&44,&55,&44
        EQUB &9b,&cd,&55,&45,&c7,&84,&45,&00,&11,&44,&55,&44,&44,&04,&44,&00
        EQUB &99,&ab,&3b,&6d,&89,&ee,&67,&60,&3b,&28,&11,&44,&22,&64,&44,&40
        EQUB &ab,&ee,&4f,&48,&ee,&aa,&42,&00,&0a,&4c,&44,&40,&46,&00,&40,&00
        EQUB &3b,&6d,&55,&45,&67,&24,&45,&00,&11,&44,&55,&44,&44,&04,&44,&00
        EQUB &4f,&0c,&45,&00,&06,&00,&00,&00,&44,&04,&44,&00,&04,&00,&00,&00
        EQUB &00,&33,&22,&75,&11,&66,&ff,&e8,&33,&30,&99,&dc,&ba,&ec,&d4,&c0
        EQUB &33,&66,&57,&40,&66,&22,&ca,&88,&12,&44,&dc,&c8,&ce,&88,&c0,&80
        EQUB &22,&75,&cc,&dd,&ff,&ac,&d5,&80,&99,&dc,&55,&54,&d4,&84,&54,&00
        EQUB &57,&04,&dd,&88,&8e,&88,&80,&80,&dc,&8c,&54,&00,&84,&80,&00,&00
        EQUB &11,&66,&ff,&e8,&cc,&aa,&ea,&a8,&ba,&ec,&5c,&48,&ee,&a8,&40,&00
        EQUB &66,&22,&ca,&88,&aa,&aa,&8a,&88,&ce,&88,&48,&08,&8a,&88,&00,&00
        EQUB &ff,&ac,&5d,&08,&ae,&a8,&00,&00,&5c,&0c,&54,&00,&04,&00,&00,&00
        EQUB &8e,&88,&08,&08,&8a,&88,&00,&00,&0c,&08,&00,&00,&00,&00,&00,&00
        EQUB &33,&21,&99,&cd,&ab,&ec,&c5,&c0,&99,&88,&11,&44,&80,&c4,&44,&40
        EQUB &03,&44,&cd,&c8,&ce,&88,&c0,&80,&88,&cc,&44,&40,&c4,&80,&40,&00
        EQUB &99,&cd,&55,&45,&c5,&84,&45,&00,&11,&44,&55,&44,&44,&04,&44,&00
        EQUB &cd,&8c,&45,&00,&84,&80,&00,&00,&44,&04,&44,&00,&04,&00,&00,&00
        EQUB &ab,&ec,&4d,&48,&ee,&a8,&40,&00,&08,&4c,&44,&40,&44,&00,&40,&00
        EQUB &ce,&88,&48,&08,&8a,&88,&00,&00,&4c,&08,&40,&00,&00,&00,&00,&00
        EQUB &4d,&0c,&45,&00,&04,&00,&00,&00,&44,&04,&44,&00,&04,&00,&00,&00
        EQUB &0c,&08,&00,&00,&00,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&22,&aa,&ec,&88,&ff,&e6,&f1,&aa,&b9,&00,&55,&b3,&f4,&55,&50
        EQUB &22,&77,&ce,&d9,&ff,&aa,&d3,&80,&9b,&dc,&55,&50,&d6,&80,&50,&00
        EQUB &aa,&ec,&44,&44,&e6,&b5,&44,&11,&00,&55,&44,&55,&55,&14,&55,&10
        EQUB &ce,&9d,&44,&11,&97,&80,&11,&00,&55,&14,&55,&10,&14,&00,&10,&00
        EQUB &88,&ff,&6e,&79,&dd,&aa,&73,&20,&3b,&7c,&55,&50,&76,&20,&50,&00
        EQUB &ff,&aa,&5b,&08,&aa,&aa,&02,&00,&5e,&08,&50,&00,&02,&00,&00,&00
        EQUB &6e,&3d,&44,&11,&37,&20,&11,&00,&55,&14,&55,&10,&14,&00,&10,&00
        EQUB &1f,&08,&11,&00,&02,&00,&00,&00,&14,&00,&10,&00,&00,&00,&00,&00
        EQUB &aa,&b9,&00,&55,&b3,&e5,&55,&41,&11,&11,&11,&55,&11,&44,&55,&40
        EQUB &9b,&cd,&55,&41,&c7,&80,&41,&00,&11,&44,&55,&40,&44,&00,&40,&00
        EQUB &00,&55,&44,&55,&55,&05,&55,&01,&11,&55,&55,&55,&55,&04,&55,&00
        EQUB &55,&05,&55,&01,&05,&00,&01,&00,&55,&04,&55,&00,&04,&00,&00,&00
        EQUB &3b,&6d,&55,&41,&67,&20,&41,&00,&11,&44,&55,&40,&44,&00,&40,&00
        EQUB &4f,&08,&41,&00,&02,&00,&00,&00,&44,&00,&40,&00,&00,&00,&00,&00
        EQUB &55,&05,&55,&01,&05,&00,&01,&00,&55,&04,&55,&00,&04,&00,&00,&00
        EQUB &05,&00,&01,&00,&00,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &22,&75,&cc,&d9,&ff,&a8,&d1,&80,&99,&dc,&55,&50,&d4,&80,&50,&00
        EQUB &57,&00,&d9,&88,&8a,&88,&80,&80,&dc,&88,&50,&00,&80,&80,&00,&00
        EQUB &cc,&9d,&44,&11,&95,&80,&11,&00,&55,&14,&55,&10,&14,&00,&10,&00
        EQUB &9d,&88,&11,&00,&80,&80,&00,&00,&14,&00,&10,&00,&00,&00,&00,&00
        EQUB &ff,&a8,&59,&08,&aa,&a8,&00,&00,&5c,&08,&50,&00,&00,&00,&00,&00
        EQUB &8a,&88,&08,&08,&8a,&88,&00,&00,&08,&08,&00,&00,&00,&00,&00,&00
        EQUB &1d,&08,&11,&00,&00,&00,&00,&00,&14,&00,&10,&00,&00,&00,&00,&00
        EQUB &08,&08,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &99,&cd,&55,&41,&c5,&80,&41,&00,&11,&44,&55,&40,&44,&00,&40,&00
        EQUB &cd,&88,&41,&00,&80,&80,&00,&00,&44,&00,&40,&00,&00,&00,&00,&00
        EQUB &55,&05,&55,&01,&05,&00,&01,&00,&55,&04,&55,&00,&04,&00,&00,&00
        EQUB &05,&00,&01,&00,&00,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &4d,&08,&41,&00,&00,&00,&00,&00,&44,&00,&40,&00,&00,&00,&00,&00
        EQUB &08,&08,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &05,&00,&01,&00,&00,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&11,&88,&ff,&99,&cc,&d5,&e2,&99,&ba,&33,&74,&90,&e6,&76,&60
        EQUB &11,&66,&ff,&ea,&cc,&aa,&e2,&a2,&ba,&ee,&56,&40,&e6,&a2,&42,&00
        EQUB &88,&ff,&66,&75,&d5,&a6,&77,&20,&33,&74,&55,&54,&76,&24,&54,&00
        EQUB &ff,&ae,&57,&00,&a6,&a2,&02,&00,&56,&04,&54,&00,&06,&00,&00,&00
        EQUB &99,&cc,&5d,&6a,&cc,&88,&40,&22,&18,&6e,&76,&60,&44,&22,&62,&20
        EQUB &cc,&aa,&6a,&2a,&88,&aa,&22,&22,&6e,&2a,&42,&00,&22,&22,&02,&00
        EQUB &5d,&2e,&77,&20,&04,&22,&22,&20,&76,&24,&54,&00,&26,&20,&00,&00
        EQUB &2e,&2a,&02,&00,&22,&22,&02,&00,&06,&00,&00,&00,&02,&00,&00,&00
        EQUB &99,&ab,&33,&65,&81,&e6,&67,&60,&33,&20,&11,&44,&22,&64,&44,&40
        EQUB &ab,&ee,&47,&40,&e6,&a2,&42,&00,&02,&44,&44,&40,&46,&00,&40,&00
        EQUB &33,&65,&55,&45,&67,&24,&45,&00,&11,&44,&55,&44,&44,&04,&44,&00
        EQUB &47,&04,&45,&00,&06,&00,&00,&00,&44,&04,&44,&00,&04,&00,&00,&00
        EQUB &09,&6e,&67,&60,&44,&22,&62,&20,&22,&64,&44,&40,&66,&20,&40,&00
        EQUB &6e,&2a,&42,&00,&22,&22,&02,&00,&46,&00,&40,&00,&02,&00,&00,&00
        EQUB &67,&24,&45,&00,&26,&20,&00,&00,&44,&04,&44,&00,&04,&00,&00,&00
        EQUB &06,&00,&00,&00,&02,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &11,&66,&ff,&e8,&cc,&aa,&e2,&a0,&ba,&ec,&54,&40,&e6,&a0,&40,&00
        EQUB &66,&22,&ca,&88,&aa,&aa,&82,&80,&ce,&88,&40,&00,&82,&80,&00,&00
        EQUB &ff,&ac,&55,&00,&a6,&a0,&00,&00,&54,&04,&54,&00,&04,&00,&00,&00
        EQUB &8e,&88,&00,&00,&82,&80,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &cc,&aa,&6a,&28,&88,&aa,&22,&20,&6e,&28,&40,&00,&22,&20,&00,&00
        EQUB &aa,&aa,&0a,&08,&aa,&aa,&02,&00,&0a,&08,&00,&00,&02,&00,&00,&00
        EQUB &2e,&28,&00,&00,&22,&20,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &0a,&08,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &ab,&ec,&45,&40,&e6,&a0,&40,&00,&00,&44,&44,&40,&44,&00,&40,&00
        EQUB &ce,&88,&40,&00,&82,&80,&00,&00,&44,&00,&40,&00,&00,&00,&00,&00
        EQUB &45,&04,&45,&00,&04,&00,&00,&00,&44,&04,&44,&00,&04,&00,&00,&00
        EQUB &04,&00,&00,&00,&00,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &6e,&28,&40,&00,&22,&20,&00,&00,&44,&00,&40,&00,&00,&00,&00,&00
        EQUB &0a,&08,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &04,&00,&00,&00,&00,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &88,&ff,&66,&71,&d5,&a2,&73,&20,&33,&74,&55,&50,&76,&20,&50,&00
        EQUB &ff,&aa,&53,&00,&a2,&a2,&02,&00,&56,&00,&50,&00,&02,&00,&00,&00
        EQUB &66,&35,&44,&11,&37,&20,&11,&00,&55,&14,&55,&10,&14,&00,&10,&00
        EQUB &17,&00,&11,&00,&02,&00,&00,&00,&14,&00,&10,&00,&00,&00,&00,&00
        EQUB &5d,&2a,&73,&20,&00,&22,&22,&20,&76,&20,&50,&00,&22,&20,&00,&00
        EQUB &2a,&2a,&02,&00,&22,&22,&02,&00,&02,&00,&00,&00,&02,&00,&00,&00
        EQUB &37,&20,&11,&00,&22,&20,&00,&00,&14,&00,&10,&00,&00,&00,&00,&00
        EQUB &02,&00,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &33,&65,&55,&41,&67,&20,&41,&00,&11,&44,&55,&40,&44,&00,&40,&00
        EQUB &47,&00,&41,&00,&02,&00,&00,&00,&44,&00,&40,&00,&00,&00,&00,&00
        EQUB &55,&05,&55,&01,&05,&00,&01,&00,&55,&04,&55,&00,&04,&00,&00,&00
        EQUB &05,&00,&01,&00,&00,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &67,&20,&41,&00,&22,&20,&00,&00,&44,&00,&40,&00,&00,&00,&00,&00
        EQUB &02,&00,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &05,&00,&01,&00,&00,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &ff,&a8,&51,&00,&a2,&a0,&00,&00,&54,&00,&50,&00,&00,&00,&00,&00
        EQUB &8a,&88,&00,&00,&82,&80,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &15,&00,&11,&00,&00,&00,&00,&00,&14,&00,&10,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &2a,&28,&00,&00,&22,&20,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &0a,&08,&00,&00,&02,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &45,&00,&41,&00,&00,&00,&00,&00,&44,&00,&40,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &05,&00,&01,&00,&00,&00,&00,&00,&04,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
