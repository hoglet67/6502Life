;; ************************************************************
;; Beeb Life Main Entry Point
;; ************************************************************

.beeb_life

        ;; Install the fast VDU driver for delta update
        JSR install_vdu_driver

        ;; Configure the default UI update
        LDA #(DEFAULT_SHOW)
        STA ui_show
        LDA #(DEFAULT_RATE)
        STA ui_rate
        LDA #(DEFAULT_MODE)
        STA ui_mode
        
.warm_boot

        LDX #&FF
        TXS

        LDA #&FE                ; send the VDU command to reset the generation count
        JSR OSWRCH

        ;; Install Event Handler
        LDA #<event_handler
        STA EVNTV
        LDA #>event_handler
        STA EVNTV + 1

        ;; Disable cursor editing, so cursors return ascii codes &88-&8B
        LDA #&04
        LDX #&01
        JSR OSBYTE

        ;; Treat escape key as a normal ascii key
        LDA #&E5
        LDX #&01
        LDY #&00
        JSR OSBYTE

        ;; Enable character entering buffer event
        LDA #&0E
        LDX #&02
        JSR OSBYTE
        
        JSR print_string

        EQUB 22, MODE
        EQUS "Conway Life for the 6502 Co Processor", 10, 10, 13
IF _ATOM_LIFE_ENGINE
        EQUS "Using the Atom Life Engine", 10, 10, 13
ELIF _LIST8_LIFE_ENGINE
        EQUS "Using the List8 Life Engine", 10, 10, 13
ELSE
        EQUS "Using the List Life Engine", 10, 10, 13
ENDIF
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

        ;; Clear the generation count
        LDX #(gen_count - count_base)
        JSR clear_count
        
        JSR refresh_panel
        
;;;  Initialize interaction counters
        STZ ui_count
        STZ key_pressed

        ;; Whenever we hit generation_loop:
        ;; "this" should point to the start of the list
        ;; "new" should point to free buffer space

.generation_loop

        ;; Determine if a UI update is due
        BIT ui_mode
        BMI force_update        ; force an update in single step mode
        INC ui_count
        LDA ui_count
        LDX ui_rate
        CMP ui_rate_table, X
        BCC skip_update
.force_update
        ;; Render the "this" buffer ("this" is unmodified)
        JSR list_life_update_screen
        STZ ui_count
.skip_update

        ;; Determine if a keyboard scan is due
        BIT ui_mode             ; Are we in single step mode?
        BMI read_keyboard       ; yes, then always wait for a key press
        LDA key_pressed         ; Has a key press event been received?
        BEQ skip_read_keyboard  ; no, then nothing further to do
.read_keyboard
        JSR OSRDCH              ; wait for key pressed
        TAX
        JSR process_key_press
        STZ key_pressed         ; clear the key pressed flag
.skip_read_keyboard

.new_generation
        ;; Just to be safe, add a terminator to the new pointer
        LDY #0
        TYA
        STA (new), Y
        INY
        STA (new), Y

        ;; Save the "new" pointer
        M_COPY new, stash

        ;; Calculate the next generation from "this" to "new"
        ;; (both "this" and "new" are updated)
        JSR list_life

        ;; Cycle the pointers
        M_COPY stash, this

        ;; Increment the generation counter
        LDX #gen_count - count_base
        LDA #1
        JSR add_to_count

        ;; Update the viewpoint position
        M_UPDATE_COORD_ZP xstart, pan_x
        M_UPDATE_COORD_ZP ystart, pan_y

        BRA generation_loop
        
.ui_rate_table
        EQUB 1, 2, 3, 4, 5, 10, 20, 50, 100, 200
.ui_rate_table_end

.process_key_press
{
        ;; &88 = Left, &89 = Right, &8A = Up, &8B = Down
        CPX #&1B
        BNE not_escape
        JMP warm_boot
.not_escape
        CPX #&0D
        BNE not_return
        JSR reset_pan
        BRA refresh
.not_return
        CPX #&87
        BNE not_copy
        JSR reset_viewpoint
        BRA refresh
.not_copy
        CPX #&88
        BNE not_left
        M_UPDATE_COORD pan_x, PAN_NEG
        BRA refresh
.not_left
        CPX #&89
        BNE not_right
        M_UPDATE_COORD pan_x, PAN_POS
        BRA refresh
.not_right
        CPX #&8A
        BNE not_up
        M_UPDATE_COORD pan_y, PAN_NEG
        BRA refresh
.not_up
        CPX #&8B
        BNE not_down
        M_UPDATE_COORD pan_y, PAN_POS
        BRA refresh
.not_down
        CPX #'R'
        BNE not_R
        LDA ui_rate
        CLC
        ADC #1
        CMP #ui_rate_table_end - ui_rate_table
        BCC store_rate
        LDA #0
.store_rate        
        STA ui_rate
        BRA refresh
.not_R
        CPX #'S'
        BNE not_S
        INC ui_show
        BRA refresh
.not_S
        CPX #&09
        BNE not_tab
        LDA ui_mode
        EOR #MODE_SINGLE_STEP
        STA ui_mode

.refresh
        JMP refresh_panel
 
.not_tab
        RTS
}

.refresh_panel
{
        JSR print_string
        EQUB 30        
        EQUS "Gen:", 10, 13
        EQUS "        ", 10, 10, 13
        EQUS "Cells:", 10, 13
        EQUS "        ", 10, 10, 13
        EQUS "X-Ref:", 10, 13
        EQUS "        ", 10, 10, 13
        EQUS "Y-Ref:", 10, 13
        EQUS "        ", 10, 10, 13
        
        EQUS "Rate:", 10, 13
        NOP
        LDX ui_rate
        LDA ui_rate_table, X
        STA tmp
        STZ tmp + 1
        LDX #tmp
        JSR print_as_unsigned
        
        JSR print_string
        EQUS 10, 10, 13, "X-Pan:", 10, 13
        NOP

        LDX #pan_x
        JSR print_as_signed
        
        JSR print_string
        EQUS " ", 10, 10, 13, "Y-Pan:", 10, 13
        NOP
        LDX #pan_y
        JSR print_as_signed

        BIT ui_mode
        BMI single_step
        JSR print_string
        EQUS " ", 10, 10, 13, "Running"
        NOP
        RTS
.single_step        
        JSR print_string
        EQUS " ", 10, 10, 13, "Stopped"
        NOP
        RTS
        
}
        
.list_life_update_screen
{
        LDA ui_show
        BIT ui_mode
        BPL not_single
        LDA #SHOW_GEN + SHOW_CELLS + SHOW_REF
.not_single
        PHA
        AND #SHOW_GEN
        BEQ skip_show_gen
        JSR show_gen
.skip_show_gen
        PLA
        PHA
        AND #SHOW_CELLS
        BEQ skip_show_cells
        JSR show_cells
.skip_show_cells
        PLA
        AND #SHOW_REF
        BEQ skip_show_ref
        JSR show_ref
.skip_show_ref

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

.show_gen
{
        LDX #1
        JSR goto_row
        LDX #(gen_count - count_base)
        JSR print_count
        RTS
}

.show_cells
{
        LDX #4
        JSR goto_row
        M_COPY this, list
        JSR list_life_count_cells
        LDX #(cell_count - count_base)
        JSR print_count
        RTS
}

.show_ref
{
        LDX #7
        JSR goto_row
        LDX #xstart
        JSR print_coord
        LDX #10
        JSR goto_row
        LDX #ystart
        JSR print_coord
        RTS
}

.print_coord
{
        ;; -Y is 0000 to 3FFF (00) ->10  C000 to FFFF
        ;; +Y is 4000 to 7FFF (01) ->00  0000 to 3FFF
        ;; -X is 8000 to BFFF (10) ->10  C000 to FFFF
        ;; +X is C000 to FFFF (11) ->00  0000 to 3FFF
        ;; Copy bit 14 (coord sign bit) to bit 15 and clear bit 14
        
        LDA 0, X
        STA tmp
        LDA 1, X
        AND #&7F
        CLC
        ADC #&C0
        STA tmp + 1
        LDX #tmp
        JMP print_as_signed
}

.goto_row
{
        LDA #31
        JSR OSWRCH
        LDA #0
        JSR OSWRCH
        TXA
        JMP OSWRCH
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
        
.event_handler
{
        PHP
        CMP #&02                ; test for char entering input buffer
        BNE return
        STY key_pressed
.return
        PLP
        RTS
}
