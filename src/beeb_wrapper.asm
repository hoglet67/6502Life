        
.beeb_life

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


;; Plot initial pattern roughtly in the middle

;;        .oo..... = 0x60
;;        oo...... = 0xC0
;;        .o...... = 0x40

        LDA #&60
        STA scrn_base + 127 * bytes_per_row + bytes_per_row / 2
        LDA #&C0
        STA scrn_base + 128 * bytes_per_row + bytes_per_row / 2
        LDA #&40
        STA scrn_base + 129 * bytes_per_row + bytes_per_row / 2


.generation_loop
        
        LDA #<scrn_base
        STA ptr
        LDA #>scrn_base
        STA ptr + 1
        LDX #&20
.send_blocks
        JSR send_block
        INC ptr + 1
        DEX
        BNE send_blocks

        JSR update_screen
        
        JMP generation_loop


;; Send one one strip 8 pixels heigh x 256 pixels wide to VDU driver
;; Converting from row linear atom" to character striped "beeb" screen format on the fly
;; And compressing zeros

.send_block

;; X is the index in beeb format

        TXA
        PHA
        
        LDX #0

;; always send the data for X=0
        LDY #0
        LDA (ptr), Y

.wait_for_space1        
        BIT &FEF8
        BVC wait_for_space1
        STA &FEF9               ; send data

.skip_blank        
        INX
        BEQ wait_for_space2
                
        LDA char_to_linear_map, X
        TAY
        LDA (ptr), Y

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
