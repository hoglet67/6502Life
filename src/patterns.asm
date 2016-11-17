;; ************************************************************
;; Code
;; ************************************************************

.draw_pattern

        CMP #PATTERN_BASE
        BCC default_random
        CMP #PATTERN_BASE + ((pattern_table_terminator - pattern_table) DIV 2)
        BCS default_random

        SEC
        SBC #PATTERN_BASE

        ASL A
        TAX
        LDA pattern_table, X    ; find pattern definition
        STA src
        LDA pattern_table + 1, X
        STA src + 1

        LDY #&00
        LDA (src), Y            ; pattern type

        JSR inc_src             ; skip the pattern type
        JSR inc_src             ; skip pointer to pattern name

        CMP #TYPE_PATTERN
        BEQ type_pattern

        CMP #TYPE_L42
        BEQ type_l42
        
        CMP #TYPE_RLE
        BEQ type_rle

.type_random
        LDA (src), Y            ; pattern density
        JMP random_pattern

.type_l42
        JMP l42_pattern

.default_random
        LDA #2
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

.not_found_error
        JSR print_string
        EQUS "Not found: "
        LDY #&FF
.name_loop
        INY
        LDA (src), Y
        JSR OSASCI
        CMP #&0D
        BNE name_loop
        RTS
        
.type_rle
        LDA #<RLE_DST
        STA this
        LDA #>RLE_DST
        STA this + 1
        LDA #&40                ; open for input only
        LDX src
        LDY src + 1             ; X/Y point to filename
        JSR OSFIND
        CMP #&00                ; returns file handle in A, or 0 if not found
        BEQ not_found_error
        STA handle              ; save the file handle
        JSR rle_next_byte       ; rle_reader expects first byte of file read 
        JSR rle_reader
        LDA #&00                ; close the file
        LDY handle
        JSR OSFIND
        LDA #TYPE_RLE
        RTS
        
.l42_pattern
        LDA #<RLE_DST
        STA this
        LDA #>RLE_DST
        STA this + 1
        LDY #1
.l42_copy
        LDA (src), Y            ; test the MSB of the coordinate
        PHA
        BPL l42_copy_y
        LDA (src)
        STA (this)
        M_INCREMENT src
        M_INCREMENT this        
.l42_copy_y
        LDA (src)
        STA (this)
        M_INCREMENT src
        M_INCREMENT this        
        LDA (src)
        STA (this)
        M_INCREMENT src
        M_INCREMENT this        
        PLA
        BNE l42_copy
        LDA #TYPE_RLE
        RTS
        
.random_pattern
{

        PHA                    ; stack the pattern density 1-3

        ;; Seed by reading system VIA T1C (&FE44)

        LDX #4
.seed_loop
        PHX
        LDA #&96
        LDX #&44
        JSR OSBYTE
        TYA
        STA seed, X
        PLX
        DEX
        BPL seed_loop

        PLX                     ; restore the pattern density

        LDA #<SCRN_BASE
        STA dst
        LDA #>SCRN_BASE
        STA dst + 1
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
        CPX #3
        BCS random_next
        JSR random
        AND (dst), Y
        STA (dst), Y
        CPX #2
        BCS random_next
        JSR random
        AND (dst), Y
        STA (dst), Y
.random_next
        INY
        BNE random_loop
        INC dst + 1
        LDA dst + 1
        CMP #>SCRN_BASE + &20
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

;; ************************************************************
;; Code
;; ************************************************************

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
        EQUW patternN
        EQUW patternO
        EQUW patternP
        EQUW patternQ
        EQUW patternR
        EQUW patternS
        EQUW patternT
        EQUW patternU
        EQUW patternV
        EQUW patternW
.pattern_table_terminator
        EQUW 0

.patternA
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.RPENTO", 13
.name
        EQUS "R-Pentomino", 0
}
        
.patternB
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.ACORN", 13
.name
        EQUS "Acorn", 0
}

.patternC
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.DIEHARD", 13
.name
        EQUS "Diehard", 0
}

.patternD
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.RABBITS", 13
.name
        EQUS "Rabbits", 0
}

.patternE
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.QUEENB", 13
.name
        EQUS "Queen Bee", 0
}

.patternF
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.BUNN9", 13
.name
        EQUS "Bunnies 9", 0
}

.patternG
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.PUFF", 13
.name
        EQUS "Puff Suppressor", 0
}

.patternH
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.SPACE", 13
.name
        EQUS "Spaceship", 0
}

.patternI
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.GLIDER", 13
.name
        EQUS "Glider", 0
}

.patternJ
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.BREEDER", 13
.name
        EQUS "Gosper Breeder 1", 0
}

.patternK
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.BLSHIP1", 13
.name
        EQUS "Blinker Ship 1", 0
}

.patternL
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.FLYWING", 13
.name
        EQUS "Flying Wing", 0
}

.patternM
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.PISHIP1", 13
.name
        EQUS "Pi Ship 1", 0
}

.patternN
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.EDNA", 13
.name
        EQUS "Edna", 0
}

.patternO
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.23334M", 13
.name
        EQUS "23334M", 0
}

.patternP
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.40514M", 13
.name
        EQUS "40514M", 0
}
        
.patternQ
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.HALFMAX", 13
.name
        EQUS "Half Max", 0
}

.patternR
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.STARGTE", 13
.name
        EQUS "Stargate", 0
}

.patternS
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.NOAHARK", 13
.name
        EQUS "Noah's Ark", 0
}

.patternT
{
.start
        EQUB TYPE_RLE
        EQUB name - start
        EQUS "R.TURING", 13
.name
        EQUS "Turing Machine (35,149 cells)", 0
}

.patternU
{
.start
        EQUB TYPE_RANDOM
        EQUB name - start
        EQUB 1
.name
        EQUS "Random (Density 1)", 0
}

.patternV
{
.start
        EQUB TYPE_RANDOM
        EQUB name - start
        EQUB 2
.name
        EQUS "Random (Density 2)", 0
}

.patternW
{
.start
        EQUB TYPE_RANDOM
        EQUB name - start
        EQUB 3
.name
        EQUS "Random (Density 3)", 0
}

