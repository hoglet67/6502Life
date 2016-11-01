;; ************************************************************
;; Code
;; ************************************************************

.draw_pattern

        CMP #PATTERN_BASE
        BCC type_random
        CMP #PATTERN_BASE + 16
        BCS type_random

        SEC
        SBC #PATTERN_BASE
        
        ASL A
        TAX
        LDA pattern_table, X    ; find pattern definition
        STA src
        LDA pattern_table + 1, X
        STA src + 1

        BEQ type_random         ; pattern not defined

        LDY #&00
        LDA (src), Y            ; pattern depth

        JSR inc_src             ; skip the pattern type 
        JSR inc_src             ; skip pointer to pattern name
        
        CMP #TYPE_PATTERN
        BEQ type_pattern

        CMP #TYPE_RLE
        BEQ type_rle

.type_random        
        JMP random_pattern
        
.type_pattern        
        LDA (src), Y            ; pattern depth
        STA pat_depth
        JSR inc_src             ; pattern width

        LDA (src), Y            ; pattern width in bytes
        STA pat_width
        JSR inc_src

        LDA #<(SCRN_BASE + 128 * BYTES_PER_ROW + BYTES_PER_ROW / 2)
        STA dst
        LDA #>(SCRN_BASE + 128 * BYTES_PER_ROW + BYTES_PER_ROW / 2)
        STA dst + 1

.pattern_loop1
        LDX pat_width
        LDY #0
.pattern_loop2
        LDA (src), Y
        STA (dst), Y
        INY
        DEX
        BNE pattern_loop2
        CLC
        LDA dst
        ADC #BYTES_PER_ROW
        STA dst
        LDA dst + 1
        ADC #0
        STA dst + 1
        CLC
        LDA src
        ADC pat_width
        STA src
        LDA src + 1
        ADC #0
        STA src + 1
        DEC pat_depth
        BNE pattern_loop1

        LDA #TYPE_PATTERN        
        RTS

.type_rle
        LDA src
        STA osfile_block
        LDA src + 1
        STA osfile_block + 1
        
        LDA #&FF
        LDX #<osfile_block
        LDY #>osfile_block
        JSR OSFILE

        LDA #<((BUFFER + BUFFER_END) DIV 2)
        STA new
        LDA #>((BUFFER + BUFFER_END) DIV 2)
        STA new + 1
        LDA #<BUFFER
        STA this
        LDA #>BUFFER
        STA this + 1
        JSR rle_reader

        LDA #TYPE_RLE
        RTS

.osfile_block
        EQUW 0
        EQUD ((BUFFER + BUFFER_END) DIV 2)
        EQUB 0
        EQUD 0
        EQUD 0
        EQUD 0
        
.random_pattern
{

        ;; Seed by reading system VIA T1C (&FE44)

        LDX #4
.seed_loop
        TXA
        PHA
        LDA #&96
        LDX #&44
        JSR OSBYTE
        TYA
        STA seed, X
        PLA
        TAX
        DEX
        BPL seed_loop
        
        LDA #<SCRN_BASE
        STA dst
        LDA #>SCRN_BASE
        STA dst + 1
        LDX #&20
        LDY #0
.random_loop
        LDA #&FF
        STA (dst), Y
        JSR random
        AND (dst), Y
        STA (dst), Y
        JSR random
        AND (dst), Y
        STA (dst), Y
        JSR random
        AND (dst), Y
        STA (dst), Y
        INY
        BNE random_loop
        INC dst + 1
        DEX
        BNE random_loop
        LDY #BYTES_PER_ROW - 1
        LDA #0
.clear_loop
        STA SCRN_BASE, Y         ; blank the top row
        STA SCRN_BASE + &1FE0, Y ; blank the bottom row
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


.inc_src
{
        INC src
        BNE nocarry
        INC src + 1
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
        STA src
        LDA pattern_table + 1, Y
        STA src + 1
        BEQ list_done

        TXA
        CLC
        ADC #PATTERN_BASE
        JSR OSWRCH
        LDA #' '
        JSR OSWRCH

        LDY #1
        LDA (src), Y
        TAY
.name_loop
        LDA (src), Y
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
        TXA
        ADC #PATTERN_BASE - 1
        RTS
}

.seed
        EQUB &11, &22, &33, &44, &55

.pattern_table
        EQUW patternA
        EQUW patternB
        EQUW patternC
        EQUW patternD
        EQUW patternE
        EQUW patternF
        EQUW patternG
        EQUW patternH
        EQUW patternI
        EQUW patternJ
        EQUW patternK
        EQUW patternL
        EQUW patternM
        EQUW 0
        EQUW 0
        EQUW 0
        EQUW 0

.patternA
        EQUB TYPE_PATTERN
        EQUB patternA_name - patternA
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %01100000
        EQUB %11000000
        EQUB %01000000        
.patternA_name
        EQUS "R-Pentomino", 0

.patternB
        EQUB TYPE_PATTERN
        EQUB patternB_name - patternB
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %01000000
        EQUB %00010000
        EQUB %11001110
.patternB_name
        EQUS "Acorn", 0

.patternC
        EQUB TYPE_PATTERN
        EQUB patternC_name - patternC
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %00000010
        EQUB %11000000
        EQUB %01000111
.patternC_name
        EQUS "Diehard", 0


.patternD
        EQUB TYPE_PATTERN
        EQUB patternD_name - patternD
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %10001110
        EQUB %11100100
        EQUB %01000000
.patternD_name
        EQUS "Rabbits", 0

.patternE
        EQUB TYPE_PATTERN
        EQUB patternE_name - patternE
        EQUB 7                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %10000000
        EQUB %10100000
        EQUB %01010000
        EQUB %01001000
        EQUB %01010000
        EQUB %10100000
        EQUB %10000000
.patternE_name
        EQUS "Queen Bee", 0

.patternF
        EQUB TYPE_PATTERN
        EQUB patternF_name - patternF
        EQUB 7                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %01000000
        EQUB %11000001
        EQUB %00000010
        EQUB %00000010
        EQUB %00000100
        EQUB %00001000
        EQUB %00001000
.patternF_name
        EQUS "Bunnies 9", 0

.patternG
        EQUB TYPE_PATTERN
        EQUB patternG_name - patternG
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
.patternG_name
        EQUS "Suppressed Puffer", 0

.patternH
        EQUB TYPE_PATTERN
        EQUB patternH_name - patternH
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
.patternH_name
        EQUS "Spaceship", 0

.patternI
        EQUB TYPE_PATTERN
        EQUB patternI_name - patternI
        EQUB 3                  ; pattern depth in rows
        EQUB 1                  ; pattern width in bytes
        EQUB %11100000
        EQUB %10000000
        EQUB %01000000
.patternI_name
        EQUS "Glider", 0

.patternJ
        EQUB TYPE_RLE
        EQUB patternJ_name - patternJ
        EQUS "R.BREEDER", 13
.patternJ_name
        EQUS "Gosper Breeder 1", 0

.patternK
        EQUB TYPE_RLE
        EQUB patternK_name - patternK
        EQUS "R.BLSHIP1", 13
.patternK_name
        EQUS "Blinker Ship 1", 0

.patternL
        EQUB TYPE_RLE
        EQUB patternL_name - patternL
        EQUS "R.FLYWING", 13
.patternL_name
        EQUS "Flying Wing", 0

.patternM
        EQUB TYPE_RLE
        EQUB patternM_name - patternM
        EQUS "R.PISHIP1", 13
.patternM_name
        EQUS "Pi Ship 1", 0
        
