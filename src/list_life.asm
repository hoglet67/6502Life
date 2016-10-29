buffer1 = &6000                 ; 6000-9FFF = 16K
buffer2 = &A000                 ; A000-DFFF = 16K

DEAD = 0
LIVE = 1

this   = &70
new    = &72
prev   = &74
next   = &76
xx     = &78
yy     = &7A
bitmap = &7C        
temp   = &7E

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
        BPL skipinc
        INC new        ;; new cannot be odd word aligned
        INC new
        BNE skipinc
        INC new + 1
        .skipinc         
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
        BNE next_not_zero
        INY
        LDA (next), Y
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
        INC next
        INC next
        BNE nocarry_next
        INC next + 1
.nocarry_next

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
        INC prev
        INC prev
        BNE skip_inc_prev
        INC prev + 1
.skip_inc_prev
        INC yy
        BNE nocarry_y
        INC yy + 1
.nocarry_y
            
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
        INC this
        INC this
        BNE skip_inc_this
        INC this + 1
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
        TXA
        CMP yy
        BNE skip_inc_next
        INC next
        INC next
        BNE skip_inc_next
        INC next + 1
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
        LDA (new), Y

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

{
        LDY #0
        LDA xx
        CMP (this), Y
        INY
        LDA xx + 1
        SBC (this), Y
        BVC label
        EOR #&80
.label
        BPL skip_assign_x
        LDA (this), Y
        STA xx + 1
        DEY
        LDA (this), Y
        STA xx         
.skip_assign_x
}

;;       if(x > *next)
;;          x = *next;

{
        LDY #0
        LDA xx
        CMP (next), Y
        INY
        LDA xx + 1
        SBC (next), Y
        BVC label
        EOR #&80
.label
        BPL skip_assign_x
        LDA (next), Y
        STA xx + 1
        DEY
        LDA (next), Y
        STA xx         
.skip_assign_x
}

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

{
        LDY #0
        LDA (prev), Y
        CMP xx
        BNE skip_inc_prev
        INY
        LDA (prev), Y
        CMP xx + 1
        BNE skip_inc_prev
        LDA bitmap
        ORA #&40
        STA bitmap
        INC prev
        INC prev
        BNE skip_inc_prev
        INC prev + 1
.skip_inc_prev
}
        
;;          if(*this == x) {
;;             bitmap |= 0200;
;;             this++;
;;          }

{
        LDY #0
        LDA (this), Y
        CMP xx
        BNE skip_inc_this
        INY
        LDA (this), Y
        CMP xx + 1
        BNE skip_inc_this
        LDA bitmap
        ORA #&80
        STA bitmap
        INC this
        INC this
        BNE skip_inc_this
        INC this + 1
.skip_inc_this
}

;;          if(*next == x) {
;;             bitmap |= 0400;
;;             next++;
;;          }

{
        LDY #0
        LDA (next), Y
        CMP xx
        BNE skip_inc_next
        INY
        LDA (next), Y
        CMP xx + 1
        BNE skip_inc_next
        LDA bitmap + 1
        ORA #&01
        STA bitmap + 1
        INC next
        INC next
        BNE skip_inc_next
        INC next + 1
.skip_inc_next
}

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
        INC new
        INC new
        BNE nocarry_new
        INC new + 1
.nocarry_new
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

        INC xx
        BNE nocarry_x
        INC xx + 1
.nocarry_x          

;;       }
;;    }
;; }

        JMP level3























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
    IF ((bm AND &20) = 0)
        IF x = 2 OR x = 3
            EQUB LIVE
        ELSE
            EQUB DEAD
        ENDIF
    ELSE
        IF x = 3 
            EQUB LIVE
        ELSE
            EQUB DEAD
        ENDIF
    ENDIF
NEXT
