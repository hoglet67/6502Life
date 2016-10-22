; THE FOLLOWING IS AN ADAPTATION
; OF JOHN CONWAYS GAME OF 'LIFE'
; THE RULES ARE SIMPLE:
; THE SCREEN IS DIVIDED IN CELLS.
; A CELL IS EITHER DEAD OR ALIVE.
; IF A CELL HAS EITHER 2 OR 3
; NEIGHBORS, IT WILL LIVE IN THE
; NEXT GENERATION.
; A DEAD CELL WILL REINCARNATE IF
; IT HAS EXACTLY 3 NEIGHBORS.
; ANY OTHER NUMBER OF NEIGHBORS
; WILL MEAN THAT CELL IS DEAD IN
; THE NEXT GENERATION.
;---------------------------------
; MOST IMPLEMENTATIONS USE A TWO
; BUFFER SYSTEM: ONE FOR THE
; CURRENT GENERATION, AND ONE FOR
; THE NEXT GENERATION. THIS
; VERSION USES ONE BUFFER FOR THE
; CURRENT GENERATION AND KEEPS
; A LIST OF CELLS THAT HAVE
; CHANGED. THIS SAVES TIME AND
; MEMORY. SINCE DEATH AND BIRTH
; ARE A BINARY PROCESS THE CELL
; DRAWING/ERASE ROUTINES ARE ONE
; AND THE SAME. THIS IS DONE VIA
; EXCLUSIVE-OR DRAWING.
;---------------------------------
; IMPLEMENTAION FOR APPLE II
; SERIES COMPUTERS BY
; STEPHEN HAWLEY   9/85
;---------------------------------

ORG &800

.codestart

.LASTV   EQUB &00
.LASTH   EQUB &00
.STAT    EQUB &00
.LEFT    EQUB &02
.RIGHT   EQUB &88 
.TOP     EQUB &09
.BOT     EQUB &BA

.VERT    EQUB &00
.HORZ    EQUB &00
.BYTE1   EQUB &07,&1C,&70,&40,&00,&00,&00
.BYTE2   EQUB &00,&00,&00,&03,&0E,&38,&60
.BYTE3   EQUB &00,&00,&00,&00,&00,&00,&01

.VDAT    EQUB &08,&11,&22,&44
.HDAT    EQUB &77,&6E,&5D,&3B
.GRD     EQUB &00       

.CV      EQUB &00
.CH      EQUB &00
.CSTAT   EQUB &00
.CCNT    EQUB &00

; CELL EXCLUSIVE-OR'S A CELL AT
; THE LOCATION INDICATED BY
; VERT AND HORZ. EXCL-OR ALLOWS
; THE SAME ROUTINE TO PLACE A
; CELL AND REMOVE ONE.
.CELL
{
         LDX VERT
         LDA &6000,X  ; SET UP PTRS 
         STA &01      ; TO SCREEN
         LDA &6100,X  ; FOR 1ST LINE
         STA &00
         LDA &6001,X  ; SET UP PTRS
         STA &03      ; TO SCREEN
         LDA &6101,X  ; FOR 2ND LINE
         STA &02
         LDY HORZ
         LDA &6300,Y  ; GET SHAPE #
         TAX
         LDA BYTE1,X  ; GET 1ST BYTE
         STA &04
         LDA BYTE2,X  ; GET 2ND BYTE
         STA &05
         LDA BYTE3,X  ; GET 3RD BYTE
         STA &06
         LDA &6200,Y  ; GET HORZ SCRN
         TAY          ; INDEX
         LDA &04
         EOR (&00),Y  ; STORE 1ST
         STA (&00),Y  ; BYTE AT VERT
         LDA &04    
         EOR (&02),Y  ; STORE 1ST
         STA (&02),Y  ; BYTE @ VERT+1
         INY        
         CPY #&28     ; EXIT IF PAST
         BEQ L1       ; FAR RIGHT
         LDA &05
         EOR (&00),Y  ; STORE 2ND
         STA (&00),Y  ; BYTE AT VERT
         LDA &05    
         EOR (&02),Y  ; STORE 2ND
         STA (&02),Y  ; BYTE @ VERT+1
         INY
         CPY #&28     ; EXIT IF PAST
         BEQ L1       ; FAR RIGHT
         LDA &06
         EOR (&00),Y  ; STORE 3RD
         STA (&00),Y  ; BYTE AT VERT
         LDA &06
         EOR (&02),Y  ; STORE 3RD
         STA (&02),Y  ; BYTE @ VERT+1
.L1      RTS
}
;---------------------------------
; SRCN WILL TEST TO SEE IF THERE
; IS A CELL AT (VERT,HORZ). IT
; RETURNS A RESULT IN THE A REG
; IF A = 0, THERE IS NO CELL
.SCRN
{
         LDA #&00
         STA RESULT   ; CLEAR RESULT
         LDX VERT
         LDA &6000,X  ; SET SCRN PTRS
         STA &01
         LDA &6100,X
         STA &00
         LDY HORZ
         LDA &6300,Y
         TAX
         LDA BYTE1,X  ; ONLY NEED TO
         STA &04      ; TEST 2 BYTES
         LDA BYTE2,X
         STA &05
         LDA &6200,Y
         TAY          ; TEST 1ST BYTE
         LDA (&00),Y  ; GET SCRN AND
         AND &04      ; ISOLATE CELL
         BEQ L1       ; 0=NO MATCH
         INC RESULT   ; ADD 1 TO RSLT
.L1      INY          ; TEST 2ND BYTE
         LDA (&00),Y  ; GET SCRN AND
         AND &05      ; ISOLATE CELL
         BEQ L2       ; 0=NO MATCH
         INC RESULT   ; ADD 1 TO RSLT
.L2      LDA RESULT   ; PUT RESULT IN
         RTS          ; A REGISTER.
.RESULT  EQUB &00
}
;------  ---------------------------
; CELLCH SAVES THE COORDINATES OF
; OF THE CELL TO BE CHANGED IN A
; TABLE FROM &4000 ON UP IN PAIRS
; OF VERTICAL AND HORIZONTAL
; COORDINATES.
.CELLCH
         LDA VERT
.C1      STA &4000    ; STORE VERT
         LDA HORZ 
.C2      STA &4001    ; STORE HORZ
         INC C2+1     ; INC ADDRS
         INC C2+1
         INC C1+1     ; SELFMODIFYING
         INC C1+1     ; CODE IS UGLY
         LDA C1+1     ; BUT FAST.
         BNE C3  
         INC C2+2
         INC C1+2
.C3      RTS
;---------------------------------
; GENER WILL DO THE CALCULATIONS
; FOR THE NEXT GENERATION. ALL
; CHANGED CELLS HAVE THEIR COORDS
; STORED FROM &4000 ON UP. GENER
; USES A FUNCTION CALLED SCAN TO
; DETERMINE THE NUMBER OF LIVE 
; NEIGHBORS AROUND A GIVEN CELL
;---------------------------------
.GENER
{
         LDA #&40     ; SETS UP PTS
         STA C1+2     ; TO LIST OF 
         STA C2+2     ; CHANGED CELLS
         LDA #&00
         STA C1+1
         LDA #&01
         STA C2+1
         LDA TOP      ; SET TOP OF
         SEC          ; SEARCH AREA
         SBC #&03
         STA VERT 
         LDA BOT      ; SET BOTTOM OF
         CLC          ; SEARCH AREA
         ADC #&06
         STA LASTV
         LDX RIGHT    ; SET RIGHT OF
         INX          ; SEARCH AREA  
         INX
         STX LASTH
.LOOP2   LDX LEFT     ; SET AND RESET
         DEX          ; LEFT OF  
         DEX          ; SEARCH AREA 
         STX HORZ
.LOOP1   JSR SCRN     ; GET STATUS 
         STA STAT     ; OF CURR CELL
         JSR SCAN     ; SCAN AROUND
         CMP #&02
         BEQ NEXTC    ; IF 3       
         CMP #&03     ; NBORS BRANCH
         BEQ GOTONE
         LDA STAT     ; KILL CELL IF
         BEQ NEXTC    ; ALIVE.
         JSR CELLCH
         JMP NEXTC    ; LOOP BACK.
.GOTONE  LDA STAT  
         BNE NEXTC 
         JSR CELLCH
.NEXTC   INC HORZ     ; CHANGE CELL
         INC HORZ     ; HORZ POINTER
         LDA HORZ
         CMP LASTH    ; IF NOT OUT OF
         BNE LOOP1    ; BOUNDS, LOOP.
         LDA VERT     ; CHANGE CELL
         CLC          ; VERT POINTER
         ADC #&03 
         STA VERT
         CMP LASTV    ; IF NOT OUT OF
         BNE LOOP2    ; BOUNDS, LOOP.
         RTS          ; ELSE DONE.
}
;---------------------------------
; SCAN COUNTS THE NUMBER OF
; LIVING CELLS AROUND THE CELL
; POINTED TO BY VERT AND HORZ AND
; RETURNS THAT NUMBER IN THE
; ACCUMULATOR.
; THE SCAN PATTERN IS:
;          812
;          7 3
;          654
.SCAN
{
         LDA #&00     ; CLEAR COUNTER
         STA TEMP     ; OF CELLS.
; NOTE THAT TO CHANGE A VERTICAL
; COORD, IT MUST BE INCREMENTED
; OR DECREMENTED BY 3. WHILE 3
; INC OR DEC STATEMENTS ARE MORE
; COMPACT THAN THE PROCESS OF
; DOING AN ADD OR SUBTRACT, I
; CHOSE TO USE THE ADDING FOR
; VERTICAL COORDINATES SINCE IT
; TAKES 12 CYCLES, WHILE THE 3
; INC'S OR DEC'S TAKE 18. I AM
; USING INC'S AND DEC'S FOR THE
; HORIZONTAL COORDINATES SINCE
; ONLY 2 ARE NEEDED WHICH IS 12
; CYCLES -THE SAME TIME NEEDED
; FOR THE ADD
         SEC      
         LDA VERT
         SBC #&03
         STA VERT
         JSR SCRN     ; CHECK POS 1.
         BEQ L1       ; INC COUNTER
         INC TEMP     ; IS THERE'S A
.L1      INC HORZ     ; CELL.
         INC HORZ
         JSR SCRN     ; CHECK POS 2
         BEQ L2                   
         INC TEMP               
.L2      LDA VERT            
         CLC     
         ADC #&03
         STA VERT
         JSR SCRN     ; CHECK POS 3
         BEQ L3  
         INC TEMP
.L3      LDA VERT
         CLC     
         ADC #&03
         STA VERT
         JSR SCRN     ; CHECK POS 4
         BEQ L4   
         INC TEMP
.L4      DEC HORZ
         DEC HORZ
         JSR SCRN     ; CHECK POS 5
         BEQ L5   
         INC TEMP
.L5      DEC HORZ
         DEC HORZ
         JSR SCRN     ; CHECK POS 6
         BEQ L6  
         INC TEMP
.L6      LDA VERT
         SEC     
         SBC #&03
         STA VERT
         JSR SCRN     ; CHECK POS 7
         BEQ L7  
         INC TEMP
.L7      LDA VERT
         SEC      
         SBC #&03
         STA VERT
         JSR SCRN     ; CHECK POS 8
         BEQ L8   
         INC TEMP
.L8      INC HORZ     ; RESET VERT
         INC HORZ     ; AND HORZ TO
         LDA VERT     ; ORIGINAL 
         CLC          ; VALUES.
         ADC #&03
         STA VERT
         LDA TEMP     ; GET TALLY.
         RTS          ; EXIT.
.TEMP    EQUB &00
}
;---------------------------------
; DISPL WILL DISPLAY ALL
; CHANGES MADE BY CELLCH. AS A
; SIDE NOTE, CALLING DISPL TWICE
; IS EQUIVALENT TO AN UNDO. I MAY
; MAY OR MAY NOT IMPLEMENT THIS.
.DISPL
{
         LDA #&40     ; RESET PTS TO
         STA D2+2     ; CELL LIST.
         STA D1+2
         LDA #&00
         STA D1+1
         LDA #&01
         STA D2+1
.D4      LDA C2+2     ; CHECK TO SEE
         CMP D2+2     ; IF THERE ARE
         BNE D1       ; ANY CHANGES
         LDA C2+1     ; LEFT TO MAKE.
         CMP D2+1
         BEQ D3       ; EXIT IF NOT.
.D1      LDA &4000    ; GET VERTICAL
         STA VERT 
.D2      LDA &4001    ; GET HORZ.
         STA HORZ 
         JSR CELL     ; PLOT CELL.
         INC D2+1     ; GET ADDRESS
         INC D2+1     ; OF NEXT CELL.
         INC D1+1
         INC D1+1
         LDA D1+1
         BNE D4   
         INC D2+2  
         INC D1+2
         JMP D4       ; LOOP BACK.
.D3      RTS
}
;---------------------------------
.OPTMV
{
         LDA #&B7
         STA BOT 
         LDX #&09 
         STX TOP
.L1      LDA &6000,X
         STA &01
         LDA &6100,X
         STA &00
         LDY #&00
.L2      LDA (&00),Y
         BNE L3      
         INY    
         CPY #&28
         BNE L2  
         INX    
         INX  
         INX  
         CPX BOT
         BNE L1  
         RTS
.L3      STX TOP
         LDX BOT
.L4      LDA &6000,X
         STA &01     
         LDA &6100,X
         STA &00     
         LDY #&00
.L5      LDA (&00),Y
         BNE L6      
         INY        
         CPY #&28
         BNE L5   
         DEX    
         DEX   
         DEX    
         CPX TOP
         BNE L4   
.L6      STX BOT
         RTS
}
;---------------------------------
.VLINES
{
         LDX #&06
.L1      STX &02  
         LDA &6000,X
         STA &01     
         LDA &6100,X
         STA &00    
         LDX #&00 
         LDY #&00 
.L2      LDA VDAT,X 
         EOR (&00),Y
         STA (&00),Y
         INX         
         TXA
         AND #&03
         TAX      
         INY 
         CPY #&28
         BNE L2   
         LDX &02
         INX     
         CPX #&BC
         BNE L1   
         RTS
}   
.HLINES
{
         LDX #&08
.L1      STX &02 
         LDA &6000,X
         STA &01     
         LDA &6100,X
         STA &00    
         LDX #&00
         LDY #&00
.L2      LDA HDAT,X
         EOR (&00),Y
         STA (&00),Y
         INX         
         TXA
         AND #&03
         TAX      
         INY      
         CPY #&28
         BNE L2   
         LDX &02
         INX     
         INX
         INX
         CPX #&BC
         BCC L1   
         RTS
}
.GRID
{
         LDA GRD
         EOR #&80
         STA GRD 
         JSR HLINES
         JMP VLINES
} 
;---------------------------------
.CLR
{
         BIT &C052
         BIT &C057
         BIT &C050
         LDX #&00 
.L1      LDA &6000,X
         STA &01    
         LDA &6100,X
         STA &00     
         LDA #&00 
         TAY     
.L2      STA (&00),Y
         INY        
         CPY #&28
         BNE L2   
         INX     
         CPX #&C0
         BNE L1  
         RTS
}
;---------------------------------
.MAIN
{
         JSR CLR 
         LDA #&00
         STA GRD 
         LDA #&06
         STA CV  
         LDA #&00
         STA CH   
.START   LDA CH
         STA HORZ
         LDA CV   
         STA VERT
         LDA #&00
         STA CSTAT
.ST1     BIT &C010
.L1      DEC CCNT 
         BNE L2
         LDA CSTAT 
         EOR #&80 
         STA CSTAT
         JSR CELL 
.L2      LDA &C000 
         BPL L1   
         CMP #&C1
         BNE L3   
         LDA VERT
         CMP #&06
         BEQ ST1
         LDX CSTAT
         BEQ L21
         JSR CELL  
.L21     LDA VERT  
         SEC     
         SBC #&03
         STA VERT
         LDX CSTAT
         BEQ ST1 
         JSR CELL
.L22     JMP ST1  
.L3      CMP #&DA
         BNE L4
         LDA VERT
         CMP #&BA
         BEQ L22 
         LDX CSTAT
         BEQ L31
         JSR CELL
.L31     LDA VERT  
         CLC     
         ADC #&03
         STA VERT  
         LDX CSTAT
         BEQ L22
         JSR CELL
.L32     JMP ST1   
.L4      CMP #&88
         BNE L5   
         LDA HORZ
         BEQ L32
         LDX CSTAT
         BEQ L41
         JSR CELL
.L41     DEC HORZ  
         DEC HORZ
         LDX CSTAT
         BEQ L32 
         JSR CELL
.L42     JMP ST1   
.L5      CMP #&95
         BNE L6   
         LDA HORZ
         CMP #&8A
         BEQ L42
         LDX CSTAT
         BEQ L51
         JSR CELL
.L51     INC HORZ 
         INC HORZ
         LDX CSTAT
         BEQ L42
         JSR CELL
.L52     JMP ST1  
.L6      CMP #&C7
         BNE L7  
         JSR GRID
.L62     JMP ST1 
.L7      CMP #&A0
         BNE L8   
         JSR CELL
.L72     JMP ST1  
.L8      CMP #&8D
         BNE L72
         LDA CSTAT
         BEQ L9    
         LDA #&00
         STA CSTAT
         JSR CELL  
.L9      LDA GRD  
         BEQ L10 
         JSR GRID
.L10     BIT &C010
         LDA VERT 
         STA CV
         LDA HORZ
         STA CH
.L11     JSR OPTMV
         JSR GENER
         JSR DISPL
         LDA &C000
         BPL L11   
         JMP START
}

.codeend

SAVE "LIFE", codestart, codeend, MAIN
