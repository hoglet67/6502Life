;; ************************************************************
;; Beeb Life Main Entry Point
;; ************************************************************

.beeb_life
        
        ;; Install the fast VDU driver for delta update
        JSR install_vdu_driver

.warm_boot

        LDX #&FF
        TXS

        LDA #&FE                ; send the VDU command to reset the generation count
        JSR OSWRCH

        ;; Disable cursor editing, so cursors return ascii codes &88-&8B
        LDA #&04
        LDX #&01
        JSR OSBYTE

        ;; Treat escape key as a normal ascii key
        LDA #&E5
        LDX #&01
        LDY #&00
        JSR OSBYTE
        
        JSR print_string

        EQUB 22, MODE
        EQUS "Conway Life for the 6502 Co Processor", 10, 10, 13
        NOP

        JSR list_patterns
        PHA

        JSR print_string
        EQUB 10, 13
        EQUS "Press key A-"
        NOP

        PLA
        JSR OSWRCH

        JSR print_string
        EQUS " for initial pattern:"
        NOP

        JSR OSRDCH
        JSR OSWRCH

        PHA

        JSR print_string
        EQUB 22, MODE
        EQUB 23, 1, 0, 0, 0, 0, 0, 0, 0, 0
        NOP

        JSR clear_screen

        PLA                     ; create initial pattern
        JSR draw_pattern

IF not(_ATOM_LIFE_ENGINE)

;; ************************************************************
;; LIST_LIFE_ENGINE
;; ************************************************************

        CMP #TYPE_RLE
        BEQ skip_load_buffer

        ;; If the initial pattern was not RLE, a bit of extra work is needed
        ;; to convert the screen to a list
        LDA #<BUFFER            ; convert other types to list structure
        STA this
        LDA #>BUFFER
        STA this + 1
        JSR list_life_load_buffer
        JSR clear_screen        ; so we are in sync with the host
.skip_load_buffer

        ;; The "this" pointer is now pointing to free memory after the loaded pattern

        ;; Update the "new" pointer to this free memory
        M_COPY this, new

        ;; Reset the "this" pointer back to the start again
        LDA #<BUFFER
        STA this
        LDA #>BUFFER
        STA this + 1

        ;; Configure the initial viewpoint
        JSR reset_viewpoint

        STZ count

        ;; Whenever we hit generation_loop:
        ;; "this" should point to the start of the list
        ;; "new" should point to free buffer space

.generation_loop

        ;; Just to be safe, add a terminator to the new pointer
        LDY #0
        TYA
        STA (new), Y
        INY
        STA (new), Y

        ;; Render the "this" buffer ("this" is unmodified)
        JSR list_life_update_screen

        ;; Save the "new" pointer
        M_COPY new, stash

        ;; Calculate the next generation from "this" to "new"
        ;; (both "this" and "new" are updated)
        JSR list_life

        ;; Cycle the pointers
        M_COPY stash, this

        INC count

        BRA generation_loop

.list_life_update_screen
{

;; Every 8 generations scan the keyboard update the cell count

        LDA count
        AND #&07
        BNE continue

        ;; Set the list to be counted
        M_COPY this, list
        JSR list_life_count_cells

        LDA #&81
        LDX #&00
        LDY #&00
        JSR OSBYTE
        BCS continue

        ;; &88 = Left, &89 = Right, &8A = Up, &8B = Down

        CPX #&1B
        BNE not_escape
        JMP warm_boot
.not_escape        
        CPX #&0D
        BNE not_return
        JSR reset_pan
        BRA continue
.not_return
        CPX #&87
        BNE not_copy
        JSR reset_viewpoint
        BRA continue
.not_copy
        CPX #&88
        BNE not_left
        M_UPDATE_COORD pan_x, PAN_NEG
        BRA continue
.not_left
        CPX #&89
        BNE not_right
        M_UPDATE_COORD pan_x, PAN_POS
        BRA continue
.not_right
        CPX #&8A
        BNE not_up
        M_UPDATE_COORD pan_y, PAN_NEG
        BRA continue
.not_up
        CPX #&8B
        BNE not_down
        M_UPDATE_COORD pan_y, PAN_POS
.not_down
        
.continue

        LDA count
        AND #&01
        BNE skip_pan
        M_UPDATE_COORD_ZP xstart, pan_x
        M_UPDATE_COORD_ZP ystart, pan_y
.skip_pan
        
        ;; Set the list to be rendered
        M_COPY this, list

        LDA #<DELTA_BASE
        STA delta
        LDA #>DELTA_BASE
        STA delta + 1

        LDA #<SCRN_BASE
        STA scrn
        LDA #>SCRN_BASE
        STA scrn + 1

        LDA #&FF                ; send the VDU command to expect a new display
        JSR OSWRCH

        LDX #&20

.loop
        TXA
        PHA

        ;; initialize the delta with the current screen
        JSR copy_screen_to_delta

        ;; EOR render the new strip into the delta
        JSR list_life_update_delta

        ;; delta is now the difference between the previous and current screens
        JSR send_delta

        ;; EOR the delta back into the local copy of the screen
        JSR eor_delta_to_screen

        ;; Move the strip down 8 pixels
        M_UPDATE_COORD ystart, &FFF8

        ;; Point to the next strip of screen
        INC scrn + 1

        PLA
        TAX
        DEX
        BNE loop

        ;; Move the strip up 256 pixels
        M_UPDATE_COORD ystart, &0100

        RTS
}

.reset_viewpoint
{
        LDA #<X_START
        STA xstart
        LDA #>X_START
        STA xstart + 1
        LDA #<Y_START
        STA ystart
        LDA #>Y_START
        STA ystart + 1
        ;; fall through to
}

.reset_pan
{
        STZ pan_x
        STZ pan_x + 1
        STZ pan_y
        STZ pan_y + 1
        RTS
}

ELSE

;; ************************************************************
;; ATOM LIFE ENGINE
;; ************************************************************

;; This code won't be around for much longer

        JSR send_screen_delta

        LDA #<DELTA_BASE
        STA delta
        LDA #>DELTA_BASE
        STA delta + 1

        JSR clear_delta

        LDA #&20                ; start at line 1, as line 0 is skipped by generation code
        STA delta

        LDA #&FF                ; fill workspace buffers with 0xFF
        LDY #&00                ; so work-skipping optimization will be pessimistic
.init_ws_loop
        STA WKSPC0, Y           ; a better solution would be to add correct
        STA WKSPC1, Y           ; wrapping to work-skipping optimization in
        STA WKSPC2, Y           ; atom_life engine
        INY
        BNE init_ws_loop

.generation_loop

        LDA #&FF                ; send the VDU command to expect a new display
        JSR OSWRCH

        JSR next_generation

        JSR mirror_edges

        BRA generation_loop


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

ENDIF
