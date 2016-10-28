
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
        
.generation_loop
        
        JSR next_generation

        JMP generation_loop

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
