
.beeb_life

        JSR print_string
        
        EQUB 22, 4
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
        EQUB 22, 4
        EQUB 23, 1, 0, 0, 0, 0, 0, 0, 0, 0
        NOP
        
        JSR install_vdu_driver

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
        
.clear_delta
        LDY #&00
        TYA
.clear_delta_loop
        STA (delta), Y
        DEY
        BNE clear_delta_loop
        RTS

;; Send one one strip 8 pixels heigh x 256 pixels wide to VDU driver
;; Converting from row linear atom" to character striped "beeb" screen format on the fly
;; And compressing zeros

.send_delta

;; X is the index in beeb format

        TXA
        PHA
        
        LDX #0

;; always send the data for X=0
        LDY #0
        LDA (delta), Y

.wait_for_space1        
        BIT &FEF8
        BVC wait_for_space1
        STA &FEF9               ; send data

.skip_blank        
        INX
        BEQ wait_for_space2
                
        LDA char_to_linear_map, X
        TAY
        LDA (delta), Y

        BEQ skip_blank        
        
.wait_for_space2        
        BIT &FEF8
        BVC wait_for_space2
        STX &FEF9               ; send index
        
        CPX #0
        BNE wait_for_space1

        PLA
        TAX
        
        RTS

.char_to_linear_map
FOR x, 0, 31
  FOR y, 0, 7
     EQUB y * &20 + x
  NEXT
NEXT
