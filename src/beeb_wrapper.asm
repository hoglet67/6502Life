;; ************************************************************
;; Variables
;; ************************************************************

MODE = 4

X_START = &BFFF                 ; in the middle of the negative range
Y_START = &4000                 ; in the middle of the positive range
 
;; ************************************************************
;; Macros
;; ************************************************************

MACRO COPY_ROW from, to
{        
        LDA #<(scrn_base + from * bytes_per_row)
        STA scrn_tmp
        LDA #>(scrn_base + from * bytes_per_row)
        STA scrn_tmp + 1
        LDA #<(scrn_base + to * bytes_per_row)
        STA scrn
        LDA #>(scrn_base + to * bytes_per_row)
        STA scrn + 1
        LDY #bytes_per_row - 1
.copy_loop
        LDA (scrn_tmp), Y
        STA (scrn), Y
        DEY
        BPL copy_loop
}
ENDMACRO
        
MACRO COPY_COLUMN from, to
{
        LDA #<scrn_base
        STA scrn
        LDA #>scrn_base
        STA scrn + 1
        LDX #0
.loop
        LDY #(from DIV 8) 
        LDA (scrn), Y
        LDY #(to DIV 8) 
        AND #(&80 >> (from MOD 8))
        BEQ pixel_zero
.pixel_one        
        LDA (scrn), Y
        ORA #(&80 >> (to MOD 8))
        BNE store
.pixel_zero        
        LDA (scrn), Y
        AND #(&80 >> (to MOD 8)) EOR &FF
.store
        STA (scrn), Y
        CLC
        LDA scrn
        ADC #bytes_per_row
        STA scrn
        BCC nocarry
        INC scrn + 1
.nocarry        
        INX
        BNE loop
}
ENDMACRO


;; ************************************************************
;; Beeb Life Main Entry Point
;; ************************************************************

.beeb_life

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
        
IF _ATOM_LIFE_ENGINE

;; ************************************************************
;; ATOM LIFE ENGINE
;; ************************************************************

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

        LDA #<buffer1
        STA this
        LDA #>buffer1
        STA this + 1
        JSR list_life_load_buffer

        ;; Buffer 2 is empty
        LDA #0
        STA buffer2
        STA buffer2 + 1

        ;; Delta buffer pointer points to fixed delta_base        
        LDA #<delta_base
        STA delta
        LDA #>delta_base
        STA delta + 1
        
.generation_loop

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

        JMP generation_loop


.list_life_update_screen
{

        ;; Point xstart and y start 
        LDA #<X_START
        STA xstart
        LDA #>X_START
        STA xstart + 1
        
        LDA #<Y_START
        STA ystart
        LDA #>Y_START
        STA ystart + 1

        LDA #<buffer1
        STA this
        LDA #>buffer1
        STA this + 1       

        LDA #<buffer2
        STA new
        LDA #>buffer2
        STA new + 1       

        LDX #&20
        
.loop
        TXA
        PHA
        
        JSR clear_delta

        LDA this
        STA list
        LDA this + 1
        STA list + 1
        JSR list_life_update_delta
        LDA list
        STA this
        LDA list + 1
        STA this + 1

        LDA new
        STA list
        LDA new  + 1
        STA list + 1
        JSR list_life_update_delta
        LDA list
        STA new
        LDA list + 1
        STA new  + 1
        
        JSR send_delta

        LDA ystart
        SEC
        SBC #8
        STA ystart
        LDA ystart + 1
        SBC #0
        STA ystart + 1
        
        PLA
        TAX
        DEX
        BNE loop
        RTS
        
}

ENDIF
        
