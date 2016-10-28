.draw_pattern

        CMP #'0'
        BCC random_pattern
        CMP #'9' + 1
        BCS random_pattern

        AND #&0F
        ASL A
        TAX
        LDA pattern_table, X    ; find pattern definition
        STA pixels
        LDA pattern_table + 1, X
        STA pixels + 1

        BEQ random_pattern      ; pattern not defined

        JSR inc_pixels          ; skip pointer to pattern name

        LDY #&00
        LDA (pixels), Y         ; pattern depth
        STA tmpY
        JSR inc_pixels

        LDA (pixels), Y         ; pattern width in bytes
        STA tmpC
        JSR inc_pixels

        LDA #<(scrn_base + 128 * bytes_per_row + bytes_per_row / 2)
        STA scrn
        LDA #>(scrn_base + 128 * bytes_per_row + bytes_per_row / 2)
        STA scrn + 1

.pattern_loop1
        LDX tmpC                ; pattern width
        LDY #0
.pattern_loop2
        LDA (pixels), Y
        STA (scrn), Y
        INY
        DEX
        BNE pattern_loop2
        CLC
        LDA scrn
        ADC #bytes_per_row
        STA scrn
        LDA scrn + 1
        ADC #0
        STA scrn + 1
        CLC
        LDA pixels
        ADC tmpC
        STA pixels
        LDA pixels + 1
        ADC #0
        STA pixels + 1
        DEC tmpY
        BNE pattern_loop1
        RTS

.random_pattern
{
        LDA #<scrn_base
        STA scrn
        LDA #>scrn_base
        STA scrn + 1
        LDX #&20
        LDY #0
.random_loop
        JSR random
        STA (scrn), Y
        INY
        BNE random_loop
        INC scrn + 1
        DEX
        BNE random_loop
        LDY #bytes_per_row - 1
        LDA #0
.clear_loop
        STA scrn_base, Y         ; blank the top row
        STA scrn_base + &1FE0, Y ; blank the bottom row
        DEY
        BPL clear_loop        
        RTS
}

.random
{
        TXA
        PHA
        LDX #8
.loop
        LDA seed + 2
        LSR A
        LSR A
        LSR A
        EOR seed + 4
        ROR A
        ROL seed
        ROL seed + 1
        ROL seed + 2
        ROL seed + 3
        ROL seed + 4
        DEX
        BNE loop
        PLA
        TAX
        LDA seed
        RTS
}


.inc_pixels
{
        INC pixels
        BNE nocarry
        INC pixels + 1
.nocarry
        RTS
}

.list_patterns
{
        LDX #0
.pattern_loop

        TXA
        ASL A
        TAY
        LDA pattern_table, Y    ; find pattern definition
        STA pixels
        LDA pattern_table + 1, Y
        STA pixels + 1
        BEQ list_done

        TXA
        ORA #&30
        JSR OSWRCH
        LDA #' '
        JSR OSWRCH

        LDY #0
        LDA (pixels), Y
        TAY
.name_loop
        LDA (pixels), Y
        BEQ name_done
        JSR OSWRCH
        INY
        BNE name_loop

.name_done
        LDA #10
        JSR OSWRCH
        LDA #13
        JSR OSWRCH

        INX
        BNE pattern_loop

.list_done
        RTS
}

.seed
        EQUB &11, &22, &33, &44, &55

.pattern_table
        EQUW pattern0
        EQUW pattern1
        EQUW pattern2
        EQUW pattern3
        EQUW pattern4
        EQUW pattern5
        EQUW pattern6
        EQUW pattern7
        EQUW pattern8
        EQUW 0  ; pattern9
        EQUW 0

.pattern0
        EQUB pattern0_name - pattern0
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %01100000
        EQUB %11000000
        EQUB %01000000
.pattern0_name
        EQUS "R-Pentomino", 0

.pattern1
        EQUB pattern1_name - pattern1
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %01000000
        EQUB %00010000
        EQUB %11001110
.pattern1_name
        EQUS "Acorn", 0

.pattern2
        EQUB pattern2_name - pattern2
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %00000010
        EQUB %11000000
        EQUB %01000111
.pattern2_name
        EQUS "Diehard", 0


.pattern3
        EQUB pattern3_name - pattern3
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %10001110
        EQUB %11100100
        EQUB %01000000
.pattern3_name
        EQUS "Rabbits", 0

.pattern4
        EQUB pattern4_name - pattern4
        EQUB 7                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %10000000
        EQUB %10100000
        EQUB %01010000
        EQUB %01001000
        EQUB %01010000
        EQUB %10100000
        EQUB %10000000
.pattern4_name
        EQUS "Queen Bee", 0

.pattern5
        EQUB pattern5_name - pattern5
        EQUB 7                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %01000000
        EQUB %11000001
        EQUB %00000010
        EQUB %00000010
        EQUB %00000100
        EQUB %00001000
        EQUB %00001000
.pattern5_name
        EQUS "Bunnies 9", 0

.pattern6
        EQUB pattern6_name - pattern6
        EQUB 25                 ; pattern depth in rows
        EQUB 5                  ; pattern width in bytes
        EQUB %0,%00000000,%00010000,%00000000,%00000000
        EQUB %0,%00000000,%01101000,%00000000,%00000000
        EQUB %0,%00000000,%01100010,%00000000,%00000000
        EQUB %0,%00000001,%00011010,%00001000,%00000000
        EQUB %0,%00000001,%11101100,%01111000,%00001010
        EQUB %0,%00000100,%00001000,%01110000,%01010010
        EQUB %0,%00000111,%11110001,%00010000,%10010000
        EQUB %0,%00101000,%00011001,%00010101,%10000100
        EQUB %0,%01111111,%11000001,%00110000,%00001000
        EQUB %0,%11000000,%00000000,%10110111,%10001001
        EQUB %1,%10000110,%10000000,%00010001,%00101000
        EQUB %0,%11000010,%00000001,%11000000,%10101001
        EQUB %0,%00000000,%10000001,%10000001,%00001100
        EQUB %0,%11000010,%00000001,%11000000,%10101001
        EQUB %1,%10000110,%10000000,%00010001,%00101000
        EQUB %0,%11000000,%00000000,%10110111,%10001001
        EQUB %0,%01111111,%11000001,%00110000,%00001000
        EQUB %0,%00101000,%00011001,%00010101,%10000100
        EQUB %0,%00000111,%11110001,%00010000,%10010000
        EQUB %0,%00000100,%00001000,%01110000,%01010010
        EQUB %0,%00000001,%11101100,%01111000,%00001010
        EQUB %0,%00000001,%00011010,%00001000,%00000000
        EQUB %0,%00000000,%01100010,%00000000,%00000000
        EQUB %0,%00000000,%01101000,%00000000,%00000000
        EQUB %0,%00000000,%00010000,%00000000,%00000000
.pattern6_name
        EQUS "Suppressed Puffer", 0

.pattern7
        EQUB pattern7_name - pattern7
        EQUB 23                 ; pattern depth in rows
        EQUB 5                  ; pattern width in bytes
        EQUB %00000000,%00000000,%00000000,%00000100,%00000001
        EQUB %00000000,%00101000,%00000000,%00011100,%00000111
        EQUB %00000000,%01001000,%00000000,%00110000,%00001100
        EQUB %00000000,%11000000,%00000000,%00100000,%00001000
        EQUB %00000001,%00000000,%10000000,%10100000,%00101000
        EQUB %00000011,%11110111,%10000011,%10000000,%11100000
        EQUB %00011000,%00001101,%00000110,%10000001,%10100000
        EQUB %00100011,%10110001,%00000101,%01100001,%01011000
        EQUB %01000100,%00110001,%10000110,%01100001,%10011000
        EQUB %01000001,%00011000,%11100100,%00011001,%00000110
        EQUB %01110001,%11101000,%00100110,%01101001,%10011010
        EQUB %00000000,%00000000,%00000110,%10000001,%10100000
        EQUB %01110001,%11101000,%00100110,%01101001,%10011010
        EQUB %01000001,%00011000,%11100100,%00011001,%00000110
        EQUB %01000100,%00110001,%10000110,%01100001,%10011000
        EQUB %00100011,%10110001,%00000101,%01100001,%01011000
        EQUB %00011000,%00001101,%00000110,%10000001,%10100000
        EQUB %00000011,%11110111,%10000011,%10000000,%11100000
        EQUB %00000001,%00000000,%10000000,%10100000,%00101000
        EQUB %00000000,%11000000,%00000000,%00100000,%00001000
        EQUB %00000000,%01001000,%00000000,%00110000,%00001100
        EQUB %00000000,%00101000,%00000000,%00011100,%00000111
        EQUB %00000000,%00000000,%00000000,%00000100,%00000001
.pattern7_name
        EQUS "Spaceship", 0

.pattern8
        EQUB pattern8_name - pattern8
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %11100000
        EQUB %10000000
        EQUB %01000000
.pattern8_name
        EQUS "Glider", 0

.pattern9
        EQUB pattern9_name - pattern9
        EQUB 1                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %00000000
.pattern9_name
        EQUS "Undefined", 0
