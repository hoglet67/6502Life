CPU 1

;; .... THE LIFE ROUTINE ....
;; The routine which takes a grid and
;; calculates the next state.

;; ************************************************************
;; Constants
;; ************************************************************

softzp  =   &00
hardzp  =   &60
hardmem =  &300

;; This is the address in the SNACKO binare
code    = &A850

;; .... ERROR CODES ....

topbnd  = &00
btmbnd  = &01
lftbnd  = &02
rtbnd   = &03
noroom  = &04
range   = &05                  ; currently unused

;; ************************************************************
;; Macros
;; ************************************************************

MACRO FNLD a, b
        LDA b
        STA a
        LDA b + 1
        STA a+1
ENDMACRO

MACRO FNswap a, b
        LDA b
        LDX a
        STA a
        STX b
        LDA b + 1
        LDX a + 1
        STA a + 1
        STX b + 1
ENDMACRO

MACRO FNI b
        INC b
        BNE nocarry
        INC b + 1
.nocarry
ENDMACRO

MACRO FNgap n
        SKIP n
ENDMACRO

MACRO FNB
        SKIP 1
ENDMACRO

;; ************************************************************
;; Variables
;; ************************************************************

;; DMB - all unused variables have been pruned, but the below
;; addresses remain the same, to facilitate binary comparison

ORG softzp

;; newframe variables
.pt_0         FNgap(2)
.offset_0     FNB
.xaddr_0      FNB
.pt_1         FNgap(2)
.offset_1     FNB
.xaddr_1      FNB
.pt_2         FNgap(2)
.offset_2     FNB
.xaddr_2      FNB
.count        FNB      ; dec ctr. becomes zero when the pending row is ready for use
.newcellcount FNgap(2) ; num of cells in new grid
.segfirst     FNB      ; start of segment
.segnext      FNB      ; current end of segment
.outcome      FNB      ; temp for segment
.mask         FNB      ; temp for segment
.t            FNB      ; temp for segment
.danger       FNB
.room         FNB

SKIP 12

;; general use variables
.stackpt      FNB      ; saves stack pointer for error handling
.rownum       FNgap(2) ; number of current row
.rowpt        FNgap(2) ; pointer to data for the 'pending' row
.prevpt       FNgap(2) ; DMB *** currently unused ***
.outpt        FNgap(2) ; where the next row of the new grid is to go
.outoffset    FNB      ; offset to outpt
.ptr          FNB      ; temp storage for addrow, segment and view
.temp         FNgap(3) ; DMB *** currently unused ***
.change       FNB      ; this is zeroed when a change occurs in addrow
.byte         FNB
.byteoffset   FNB
.byteaddr     FNB
.lastwaszero  FNB      ; if -ve the last byte to output was zero

;; ... HARD MEMORY ...

ORG hardmem

SKIP 141

softmem = P%

;; ... SOFT MEMORY ...

ORG softmem

.locnt        FNgap(128)
.hicnt        FNgap(128)

;; ... HARD ZERO PAGE ...

ORG hardzp

.ingrid       FNgap(2)
.ingridtop    FNgap(2)
.outgrid      FNgap(2)
.outgridtop   FNgap(2)
.gridstart    FNgap(2)
.nextfree     FNgap(2)
.cellcount    FNgap(2) ; num of cells in grid

;; ************************************************************
;; Code
;; ************************************************************

ORG code

.save_start

;;.... NEWFRAME ....

;;This is the top level of the main routine
;;On exit C=0 if newgrid ok, C=1 if error encountered
;;and error code is in A.

.newframe
        TSX
        STX stackpt             ; Preserve stack
        STZ newcellcount
        STZ newcellcount+1      ; Zero the cell count
        FNLD rowpt,gridstart
        FNLD outpt,outgrid
        STZ pt_1+1
        STZ pt_2+1
        LDA #1
        STA count
        LDA (rowpt)
        LDY #1
        ORA (rowpt),Y
        BNE nxtrow

        ; Overflow at top boundary
        LDA #topbnd
        JMP badend

.nxtrow

        FNLD pt_0,pt_1
        FNLD pt_1,pt_2
        DEC count
        BEQ S23
        STZ pt_2+1
        FNI rownum
        LDA rownum+1
        CMP #4
        BCS S21 ; Out of bounds
        JSR newrow
        BRA nxtrow

.S21
        ; Have reached bottom boundary
        LDA #btmbnd
        JMP badend

.S23
        SEC
        LDA (rowpt)
        SBC #1
        STA rownum
        LDY #1
        LDA (rowpt),Y
        SBC #0
        STA rownum+1
        BMI S25 ; Done!

        CLC
        LDA #4
        ADC rowpt
        STA pt_2
        LDA #0
        ADC rowpt+1
        STA pt_2+1

        INY
        LDA (rowpt),Y
        TAX
        INY
        LDA (rowpt),Y
        STX rowpt
        STA rowpt+1

        CLC ; sic
        LDA (rowpt)
        SBC rownum
        TAX
        LDY #1
        LDA (rowpt),Y
        SBC rownum+1
        BEQ skip1
        LDX #3
.skip1
        CPX #4
        BCC skip2
        LDX #3
.skip2
        STX count
        JSR newrow
        BRA nxtrow

.S25
        ; Have now processed all rows correctly
        LDY #0
        LDA #&FF
        STA (outpt),Y
        INY
        STA (outpt),Y
        CLC
        LDA outpt
        ADC #2
        STA nextfree
        LDA outpt+1
        ADC #0
        STA nextfree+1

        ; Switch in and out grids and cellcounts
        LDA outgrid
        LDX ingrid
        STA ingrid
        STA gridstart
        STX outgrid
        LDA outgrid+1
        LDX ingrid+1
        STA ingrid+1
        STA gridstart+1
        STX outgrid+1
        FNswap ingridtop,outgridtop
        FNLD cellcount,newcellcount


        CLC
        RTS



        ; .... BADEND ....

        ; This gets called if one of various types of error
        ; is encountered while computing the new grid.
        ; We exit with an error code, and hopefully, the old grid
        ; intact.

.badend
        LDX stackpt
        TXS  ; Stack is now as it was at start of newframe
        SEC
        RTS





        ; .... NEWROW ....

        ; This works out the newrow


.newrow

        ; Do the room checks
        SEC
        LDA outgridtop
        SBC outpt
        TAX
        LDA outgridtop+1
        SBC outpt+1
        BCS S27

.S26
        ; No room
        LDA #noroom
        JMP badend

.S27
        CMP #0
        BEQ S28
        STZ danger
        BRA S29

.S28
        LDA #255
        STA danger
        CPX #8
        BCC S26
        DEX
        DEX
        DEX
        DEX
        STX room

.S29
        ; Set up xaddr(), offset() and lastwaszero

        LDA #&FF
        STA lastwaszero

MACRO SETUP_ROW pt_n, xaddr_n, offset_n
        LDA pt_n+1
        BNE S6
        ; The row is empty
        LDA #128
        STA xaddr_n
        BRA S7
.S6
        ; The row is not empty
        LDA (pt_n)
        BEQ skip3
        JMP S45 ; Out of bounds
.skip3
        LDY #1
        LDA (pt_n),Y
        STA xaddr_n
        CMP #1
        BNE skip4
        STZ lastwaszero
.skip4
        INY
        STY offset_n
.S7
ENDMACRO


        SETUP_ROW pt_0, xaddr_0, offset_0
        SETUP_ROW pt_1, xaddr_1, offset_1
        SETUP_ROW pt_2, xaddr_2, offset_2


        LDA xaddr_1
        STA byteaddr
        LDY offset_1
        STY byteoffset
        LDA (pt_1),Y
        STA byte
        LDA #4
        STA outoffset

.S31
        LDA xaddr_0
        CMP xaddr_1
        BCC skip5
        LDA xaddr_1
.skip5
        CMP xaddr_2
        BCC skip6
        LDA xaddr_2
.skip6
        CMP #128
        BCS S41 ; Finished

        STA segfirst
        STA segnext

.label1
        LDA #&FF
        STA change
        JSR addrow_0
        JSR addrow_1
        JSR addrow_2
        LDA change
        BEQ label1

        ; No changes have been made, so we have a complete segment

        JSR segment ; Do the hard stuff!
        BRA S31 ; Next segment

.S41
        ; Nothing left to do, so tidy up

        LDY outoffset
        CPY #4
        BEQ S42 ; The row is empty, so just return!
        ; Otherwise I have to tidy up the row entry
        LDA #0
        STA (outpt),Y
        INY
        LDA #128
        STA (outpt),Y
        INY
        TYA
        LDY #2
        CLC
        ADC outpt
        STA (outpt),Y
        PHA
        INY
        LDA outpt+1
        ADC #0
        STA (outpt),Y
        PHA
        LDA rownum
        STA (outpt)
        LDY #1
        LDA rownum+1
        STA (outpt),Y
        PLA
        STA outpt+1
        PLA
        STA outpt

.S42
        RTS


.S45
        ; Out of bounds to the left
        LDA #lftbnd
        JMP badend

        ; .... SEGMENT ....

        ; This does the hard work

.segment

        LDY segnext
        LDA #0
        STA hicnt,Y
        LDY segfirst
        DEY
        STA locnt,Y
        STY ptr

        ; Left hand end
        LDA hicnt+1,Y
        AND #&C0
        TAY
        LDA rtsum,Y
        JSR outbyte

        INC ptr
        LDY ptr

.S63
        CPY byteaddr
        BCC S66
        JSR nonzerobyte
        LDY byteoffset
        INY
        LDA (pt_1),Y
        BEQ S64
        STA byte
        INC byteaddr
        STY byteoffset
        BRA S67

.S64
        INY
        LDA (pt_1),Y
        STA byteaddr
        INY
        LDA (pt_1),Y
        STA byte
        STY byteoffset
        BRA S67

.S66
        ; 'byte' is zero
        JSRzerobyte

.S67
        INC ptr
        LDY ptr
        CPY segnext
        BCC S63

        ; Right hand end
        LDA locnt-1,Y
        AND #3
        TAX
        LDA ltsum,X
        ASL A
        ASL A
        ASL A
        ASL A
        JMP outbyte



.nonzerobyte

        ; Generic non-zero entry
        ; On entry Y must hold ptr

        LDA hicnt,Y
        AND #&FC
        STA t
        LDA locnt-1,Y
        AND #3
        ORA t
        TAX
        LDA locnt,Y
        AND #&C0
        STA t
        LDA hicnt,Y
        AND #&3F
        ORA t
        TAY

        LDA ltsum,X
        ORA rtsum,Y
        ASL A
        ASL A
        ASL A
        ASL A
        STA outcome
        LDA ltmsk,X
        ORA rtmsk,Y
        ASL A
        ASL A
        ASL A
        ASL A
        STA mask

        LDY ptr
        LDA hicnt,Y
        AND #3
        STA t
        LDA locnt,Y
        AND #&FC
        ORA t
        TAX
        LDA locnt,Y
        AND #&3F
        STA t
        LDA hicnt+1,Y
        AND #&C0
        ORA t
        TAY

        LDA ltsum,X
        ORA rtsum,Y
        ORA outcome
        STA outcome
        LDA ltmsk,X
        ORA rtmsk,Y
        ORA mask

        AND byte
        ORA outcome
        JMP outbyte



.zerobyte

        ; Generic zero entry
        ; On entry Y must hold ptr

        LDA hicnt,Y
        AND #&FC
        STA t
        LDA locnt-1,Y
        AND #3
        ORA t
        TAX
        LDA locnt,Y
        AND #&C0
        STA t
        LDA hicnt,Y
        AND #&3F
        ORA t
        TAY

        LDA ltsum,X
        ORA rtsum,Y
        ASL A
        ASL A
        ASL A
        ASL A
        STA outcome

        LDY ptr
        LDA hicnt,Y
        AND #3
        STA t
        LDA locnt,Y
        AND #&FC
        ORA t
        TAX
        LDA locnt,Y
        AND #&3F
        STA t
        LDA hicnt+1,Y
        AND #&C0
        ORA t
        TAY

        LDA ltsum,X
        ORA rtsum,Y
        ORA outcome


.outbyte

        ; put the output byte in its rightful place
        ; and adjust cell count

        CMP #0
        BNE S71
        DEC A
        STA lastwaszero
        RTS

.S71
        LDY outoffset
        BIT lastwaszero
        BMI S75
        STA (outpt),Y
        TAX
        LDA bitcnt,X
        CLC
        ADC newcellcount
        STA newcellcount
        BCC skip7
        INC newcellcount+1
.skip7
        INC outoffset
        BIT danger
        BMI S77 ; May have run out of room
        RTS

.S75
        TAX
        LDA #0
        STA (outpt),Y
        INY
        LDA ptr
        STA (outpt),Y
        INY
        TXA
        STA (outpt),Y
        LDA bitcnt,X
        CLC
        ADC newcellcount
        STA newcellcount
        BCC skip8
        INC newcellcount+1
.skip8
        INY
        STY outoffset
        STZ lastwaszero
        BIT danger
        BMI S78
        RTS

.S77
        ; Check room
        LDX room
        DEX
        CPX #4
        BCC S79
        STX room
        RTS

.S78
        ; Check room
        LDA room
        SEC
        SBC #3
        CMP #4
        BCC S79
        STA room
        RTS

.S79
        LDA #noroom
        JMP badend



        ; .... ADDROW(J%) ....

        ; This adds the considered row into the current segment data.

        ; Segfirst points to the first byte in the segment
        ; Segnext points to the next byte of the segment to be treated

MACRO ADD_ROW pt_n, xaddr_n, offset_n

        LDX xaddr_n
        BMI quit1
        LDY offset_n
        CPX segnext
        BCC S1
        BEQ S2
        DEX
        CPX segnext
        BEQ S3
.quit1 RTS


.S1
        ; We're < segnext so add in the row
        ; C must be 0 on entry

        STX ptr
        LDA (pt_n),Y
        BEQ S4 ; Got a zero in the row
        TAX
        LDA lo,X
        PHA
        LDA hi,X
        LDX ptr
        ADC hicnt,X
        STA hicnt,X
        PLA
        ADC locnt,X
        STA locnt,X
        INY
        INX
        CPX segnext
        BCC S1


.S2
        ; We're at segnext so store in the row

        STX ptr
        LDA (pt_n),Y
        BEQ S5 ; Got a zero in the row
        TAX
        LDA lo,X
        PHA
        LDA hi,X
        LDX ptr
        STA hicnt,X
        PLA
        STA locnt,X
        INY
        INX
        BPL S2
        ; Now we've reached the end of the row
        LDA #rtbnd
        JMP badend


.S3
        ; We're at segnext+1
        STZ hicnt,X
        STZ locnt,X
        INX
        BRA S2


.S4
        ; Got zero while < segnext
        INY
        LDA (pt_n),Y
        BMI quit2 ; We've run off the end
        INY
        TAX
        CPX segnext
        BCC S1
        BEQ S2
        DEX
        CPX segnext
        BEQ S3
        STY offset_n

.quit2
        STA xaddr_n
        STZ change
        RTS


.S5
        ; Got zero while >= segnext
        STX segnext ; Update segnext
        INY
        LDA (pt_n),Y
        BMI quit3
        INY
        TAX
        DEX
        CPX segnext
        BEQ S3
        STY offset_n

.quit3
        STA xaddr_n
        STZ change
        RTS

ENDMACRO

.addrow_0
        ADD_ROW pt_0, xaddr_0, offset_0
.addrow_1
        ADD_ROW pt_1, xaddr_1, offset_1
.addrow_2
        ADD_ROW pt_2, xaddr_2, offset_2

.save_end


ORG &B032

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

SAVE "x", save_start, save_end





