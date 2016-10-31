;; ************************************************************
;; Beeb Life Main Entry Point
;; ************************************************************

.beeb_life

        ;; Disable cursor editing, so cursors return ascii codes &88-&8B
        LDA #&04
        LDX #&01
        JSR OSBYTE
        
        JSR print_string
        
        EQUB 22, MODE
        EQUS "Pattern selection", 10, 10, 13
        NOP
        
        JSR list_patterns
        DEX
        TXA
        ORA #&30
        PHA
        
        JSR print_string
        EQUB 10, 13
        EQUS "Press key 0-"        
        NOP
        
        PLA
        JSR OSWRCH

        JSR print_string
        EQUS " for pattern, ", 10, 13
        EQUS "anything else for random: "
        NOP
        
        JSR OSRDCH
        JSR OSWRCH
        
        PHA

        JSR print_string        
        EQUB 22, MODE
        EQUB 23, 1, 0, 0, 0, 0, 0, 0, 0, 0
        NOP

;; Clear screen
        LDA #<scrn_base
        STA scrn
        LDA #>scrn_base
        STA scrn + 1
        LDX #&20
        LDY #0
        TYA
.clear_loop        
        STA (scrn), Y
        INY
        BNE clear_loop
        INC scrn + 1
        DEX
        BNE clear_loop

        PLA                     ; create initial pattern
        JSR draw_pattern

        JSR install_vdu_driver

        LDA #&FE                ; send the VDU command to reset the generation count
        JSR OSWRCH
        
IF _ATOM_LIFE_ENGINE

;; ************************************************************
;; ATOM LIFE ENGINE
;; ************************************************************

        LDA #&FF                ; send the VDU command to expect a new display
        JSR OSWRCH

        LDA #<scrn_base
        STA delta
        LDA #>scrn_base
        STA delta + 1
        LDX #&20
.send_loop
        JSR send_delta
        INC delta + 1
        DEX
        BNE send_loop

        LDA #<delta_base
        STA delta
        LDA #>delta_base
        STA delta + 1

        JSR clear_delta
        
        LDA #&20                ; start at line 1, as line 0 is skipped by generation code
        STA delta

        LDA #&FF                ; fill workspace buffers with 0xFF
        LDY #&00                ; so work-skipping optimization will be pessimistic
.init_ws_loop
        STA wkspc0, Y           ; a better solution would be to add correct
        STA wkspc1, Y           ; wrapping to work-skipping optimization in
        STA wkspc2, Y           ; atom_life engine
        INY
        BNE init_ws_loop
                
.generation_loop

        LDA #&FF                ; send the VDU command to expect a new display
        JSR OSWRCH

        JSR next_generation

        JSR mirror_edges
  
        JMP generation_loop
        

;; For some reason an extra pixel of padding is needed on left/right
;; probably due to an edge condition with atom life engine
extra = 1
        
.mirror_edges
        ;; Copy row 1 to row 255
        COPY_ROW 1, 255
        ;; Copy row 254 to row 0
        COPY_ROW 254, 0

        ;; Copying columns is not actually necessary, as the atom life engine mirrors l/r
        
        ;; Copy col 1 to col 255
        ;; COPY_COLUMN 1 + extra, 255 - extra        
        ;; Copy col 254 to col 0
        ;; COPY_COLUMN 254 - extra, 0 + extra
        RTS
        
ELSE

;; ************************************************************
;; LIST_LIFE_ENGINE
;; ************************************************************

        ;; Initialize buffers
        ;; Initial pattern is in buffer 1

IF _BREEDER
        LDA #<breeder
        STA this
        LDA #>breeder
        STA this + 1
        LDA #<buffer1
        STA new
        LDA #>buffer1
        STA new + 1        
        JSR rle_reader
ELSE        
        LDA #<buffer1
        STA this
        LDA #>buffer1
        STA this + 1        
        JSR list_life_load_buffer
ENDIF
        
        ;; Buffer 2 is empty
        LDA #0
        STA buffer2
        STA buffer2 + 1

        ;; Delta buffer pointer points to fixed delta_base        
        LDA #<delta_base
        STA delta
        LDA #>delta_base
        STA delta + 1

        ;; Configure the initial viewpoint
        LDA #<X_START
        STA old_xstart
        LDA #>X_START
        STA old_xstart + 1
        LDA #<Y_START
        STA old_ystart
        LDA #>Y_START
        STA old_ystart + 1

        LDA #0
        STA count
        
.generation_loop

        ;; Erase buffer 2, draw buffer 1
        LDA #<buffer2
        STA this
        LDA #>buffer2
        STA this + 1
        LDA #<buffer1
        STA new
        LDA #>buffer1
        STA new + 1
        JSR list_life_update_screen

        ;; Generate buffer 1 -> buffer 2
        LDA #<buffer1
        STA this
        LDA #>buffer1
        STA this + 1
        LDA #<buffer2
        STA new
        LDA #>buffer2
        STA new + 1
        JSR list_life

        INC count
        
        ;; Erase buffer 1, draw buffer 2
        LDA #<buffer1
        STA this
        LDA #>buffer1
        STA this + 1
        LDA #<buffer2
        STA new
        LDA #>buffer2
        STA new + 1        
        JSR list_life_update_screen

        ;; Generate buffer 2 -> buffer 1
        LDA #<buffer2
        STA this
        LDA #>buffer2
        STA this + 1
        LDA #<buffer1
        STA new
        LDA #>buffer1
        STA new + 1
        JSR list_life

        INC count
        
        JMP generation_loop


MACRO M_COPY from, to
        LDA from
        STA to
        LDA from + 1
        STA to + 1        
ENDMACRO

MACRO M_UPDATE_COORD coord, d
        LDA coord
        CLC
        ADC #<d
        STA coord
        LDA coord + 1
        ADC #>d
        STA coord + 1
.skip_update        
ENDMACRO
        
.list_life_update_screen
{

;; Every 8 generations scan the keyboard update the cell count

        M_COPY old_xstart, new_xstart
        M_COPY old_ystart, new_ystart

        LDA count
        AND #&07
        BNE continue

        LDA #<buffer1
        STA list
        LDA #>buffer1
        STA list + 1        
        JSR list_life_count_cells        
        
        LDA #&81
        LDX #&00
        LDY #&00
        JSR OSBYTE
        BCS continue
        
        ;; &88 = Left, &89 = Right, &8A = Up, &8B = Down
        
        CPX #&88
        BNE not_left
        M_UPDATE_COORD new_xstart, PAN_NEG
        JMP continue
.not_left        
        CPX #&89
        BNE not_right
        M_UPDATE_COORD new_xstart, PAN_POS
        JMP continue
.not_right        
        CPX #&8A
        BNE not_up
        M_UPDATE_COORD new_ystart, PAN_NEG
        JMP continue
.not_up        
        CPX #&8B
        BNE not_down
        M_UPDATE_COORD new_ystart, PAN_POS
.not_down

.continue

        
        LDA #&FF                ; send the VDU command to expect a new display
        JSR OSWRCH
        
        LDX #&20
        
.loop
        TXA
        PHA
        
        JSR clear_delta

        ;; Erase the old strip        
        M_COPY old_xstart, xstart
        M_COPY old_ystart, ystart
        M_COPY this, list
        JSR list_life_update_delta
        M_COPY list, this

        ;; Draw the new strip
        M_COPY new_xstart, xstart                
        M_COPY new_ystart, ystart
        M_COPY new, list
        JSR list_life_update_delta 
        M_COPY list, new

        JSR send_delta

        ;; Move the strip down 8 pixels
        M_UPDATE_COORD old_ystart, &FFF8
        M_UPDATE_COORD new_ystart, &FFF8
        
        PLA
        TAX
        DEX
        BNE loop

        ;; Move the strip up 256 pixels
        M_UPDATE_COORD old_ystart, &0100
        M_UPDATE_COORD new_ystart, &0100

        ;; Now make new permemany
        M_COPY new_xstart, old_xstart
        M_COPY new_ystart, old_ystart
        
        RTS
}

ENDIF
        
