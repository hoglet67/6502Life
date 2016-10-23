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


BASE = &6000

ZP1 = &00
ZP2 = &02
B1  = &04
B2  = &05
B3  = &06


; Apple 2 was 280 x 192
; each row was 40 bytes, with bits 6..0 bits determining the pixel state and bit 7 determining the colours
ROWLEN = &28

CLIST = &4000

ORG BASE-4
        
.codestart
        EQUW BASE
        EQUW MAIN
        
.SCANLINEHI
FOR i, 0, 191
       EQUB >(&2000 + (i MOD 8) * &400 + ((i DIV 8) MOD 8) * &80 + (i DIV 64) * ROWLEN)
NEXT

ORG BASE + &100
.SCANLINELO
FOR i, 0, 191 
       EQUB <(&2000 + (i MOD 8) * &400 + ((i DIV 8) MOD 8) * &80 + (i DIV 64) * ROWLEN)
NEXT

ORG BASE + &200
.EVEN7S
FOR i, 0, 139
       EQUB 2 * (i DIV 7)
NEXT

ORG BASE + &300 
.SEVENS
FOR i, 0, 139
       EQUB (i MOD 7)
NEXT

ORG BASE + &400

      JMP MAIN
        
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
         LDA SCANLINEHI,X  ; SET UP PTRS 
         STA ZP1+1    ; TO SCREEN
         LDA SCANLINELO,X  ; FOR 1ST LINE
         STA ZP1
         LDA SCANLINEHI+1,X; SET UP PTRS
         STA ZP2+1    ; TO SCREEN
         LDA SCANLINELO+1,X; FOR 2ND LINE
         STA ZP2
         LDY HORZ
         LDA SEVENS,Y  ; GET SHAPE #
         TAX
         LDA BYTE1,X  ; GET 1ST BYTE
         STA B1 
         LDA BYTE2,X  ; GET 2ND BYTE
         STA B2 
         LDA BYTE3,X  ; GET 3RD BYTE
         STA B3 
         LDA EVEN7S,Y  ; GET HORZ SCRN
         TAY          ; INDEX
         LDA B1 
         EOR (ZP1),Y  ; STORE 1ST
         STA (ZP1),Y  ; BYTE AT VERT
         LDA B1     
         EOR (ZP2),Y  ; STORE 1ST
         STA (ZP2),Y  ; BYTE @ VERT+1
         INY        
         CPY #ROWLEN  ; EXIT IF PAST
         BEQ L1       ; FAR RIGHT
         LDA B2 
         EOR (ZP1),Y  ; STORE 2ND
         STA (ZP1),Y  ; BYTE AT VERT
         LDA B2     
         EOR (ZP2),Y  ; STORE 2ND
         STA (ZP2),Y  ; BYTE @ VERT+1
         INY
         CPY #ROWLEN  ; EXIT IF PAST
         BEQ L1       ; FAR RIGHT
         LDA B3 
         EOR (ZP1),Y  ; STORE 3RD
         STA (ZP1),Y  ; BYTE AT VERT
         LDA B3 
         EOR (ZP2),Y  ; STORE 3RD
         STA (ZP2),Y  ; BYTE @ VERT+1
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
         LDA SCANLINEHI,X  ; SET SCRN PTRS
         STA ZP1+1
         LDA SCANLINELO,X
         STA ZP1 
         LDY HORZ
         LDA SEVENS,Y
         TAX
         LDA BYTE1,X  ; ONLY NEED TO
         STA B1       ; TEST 2 BYTES
         LDA BYTE2,X
         STA B2 
         LDA EVEN7S,Y
         TAY          ; TEST 1ST BYTE
         LDA (ZP1),Y  ; GET SCRN AND
         AND B1       ; ISOLATE CELL
         BEQ L1       ; 0=NO MATCH
         INC RESULT   ; ADD 1 TO RSLT
.L1      INY          ; TEST 2ND BYTE
         LDA (ZP1),Y  ; GET SCRN AND
         AND B2       ; ISOLATE CELL
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
.C1      STA CLIST    ; STORE VERT
         LDA HORZ 
.C2      STA CLIST+1  ; STORE HORZ
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
         LDA #>CLIST  ; SETS UP PTS
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
         LDA #>CLIST  ; RESET PTS TO
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
.D1      LDA CLIST    ; GET VERTICAL
         STA VERT 
.D2      LDA CLIST+1  ; GET HORZ.
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
.L1      LDA SCANLINEHI,X
         STA ZP1+1
         LDA SCANLINELO,X
         STA ZP1
         LDY #&00
.L2      LDA (ZP1),Y
         BNE L3      
         INY    
         CPY #ROWLEN
         BNE L2  
         INX    
         INX  
         INX  
         CPX BOT
         BNE L1  
         RTS
.L3      STX TOP
         LDX BOT
.L4      LDA SCANLINEHI,X
         STA ZP1+1     
         LDA SCANLINELO,X
         STA ZP1     
         LDY #&00
.L5      LDA (ZP1),Y
         BNE L6      
         INY        
         CPY #ROWLEN
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
.L1      STX ZP2  
         LDA SCANLINEHI,X
         STA ZP1+1     
         LDA SCANLINELO,X
         STA ZP1    
         LDX #&00 
         LDY #&00 
.L2      LDA VDAT,X 
         EOR (ZP1),Y
         STA (ZP1),Y
         INX         
         TXA
         AND #&03
         TAX      
         INY 
         CPY #ROWLEN
         BNE L2   
         LDX ZP2
         INX     
         CPX #&BC
         BNE L1   
         RTS
}   
.HLINES
{
         LDX #&08
.L1      STX ZP2 
         LDA SCANLINEHI,X
         STA ZP1+1     
         LDA SCANLINELO,X
         STA ZP1    
         LDX #&00
         LDY #&00
.L2      LDA HDAT,X
         EOR (ZP1),Y
         STA (ZP1),Y
         INX         
         TXA
         AND #&03
         TAX      
         INY      
         CPY #ROWLEN
         BNE L2   
         LDX ZP2
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
         BIT &C052      ; CLRMIXED
         BIT &C057      ; SETHIRES
         BIT &C050      ; CLRTEXT
         LDX #&00 
.L1      LDA SCANLINEHI,X
         STA ZP1+1    
         LDA SCANLINELO,X
         STA ZP1     
         LDA #&00 
         TAY     
.L2      STA (ZP1),Y
         INY        
         CPY #ROWLEN
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
.ST1     BIT &C010      ; STROBE unlatched keyboard data
.L1      DEC CCNT 
         BNE L2
         LDA CSTAT 
         EOR #&80 
         STA CSTAT
         JSR CELL 
.L2      LDA &C000      ; KEYBOARD 
         BPL L1         ; nothing pressed
         CMP #&C1       ; ascii 41 = A = move cursor up
         BNE L3   
         LDA VERT
         CMP #&06       ; top limit = 6
         BEQ ST1
         LDX CSTAT
         BEQ L21
         JSR CELL  
.L21     LDA VERT       ; decrement VERT by 3
         SEC     
         SBC #&03
         STA VERT
         LDX CSTAT
         BEQ ST1 
         JSR CELL
.L22     JMP ST1  
.L3      CMP #&DA       ; ascii 5A = Z = move cursor down
         BNE L4
         LDA VERT
         CMP #&BA       ; bottom limit = BA = 186 (6,9,12,...,183,186 gives 61 vertical positions)
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
.L4      CMP #&88       ; ascii 08 = cursor left
         BNE L5   
         LDA HORZ       ; left limit = 0
         BEQ L32
         LDX CSTAT
         BEQ L41
         JSR CELL
.L41     DEC HORZ       ; decrement HORZ by 2
         DEC HORZ
         LDX CSTAT
         BEQ L32 
         JSR CELL
.L42     JMP ST1   
.L5      CMP #&95       ; ascii 15 = cursor right
         BNE L6   
         LDA HORZ
         CMP #&8A       ; right limit = 138 (0,2,4,...,136,138 gives 70 horizontal positions)
         BEQ L42
         LDX CSTAT
         BEQ L51
         JSR CELL
.L51     INC HORZ       ; increment HORZ by  2
         INC HORZ
         LDX CSTAT
         BEQ L42
         JSR CELL
.L52     JMP ST1  
.L6      CMP #&C7       ; ascii 47 = G, toggle grid
         BNE L7  
         JSR GRID
.L62     JMP ST1 
.L7      CMP #&A0       ; ascii 20 = space, toggle cell
         BNE L8   
         JSR CELL
.L72     JMP ST1  
.L8      CMP #&8D       ; ascii 0D = return, start computing generations
         BNE L72
         LDA CSTAT
         BEQ L9    
         LDA #&00
         STA CSTAT
         JSR CELL  
.L9      LDA GRD  
         BEQ L10 
         JSR GRID
.L10     BIT &C010      ; STROBE unlatched keyboard data
         LDA VERT 
         STA CV
         LDA HORZ
         STA CH
.L11     JSR OPTMV
         JSR GENER
         JSR DISPL
         LDA &C000     ; read KEYBOARD 
         BPL L11       ; loop back if no key pressed
         JMP START
}
        
.codeend

SAVE "LIFE", codestart, codeend
