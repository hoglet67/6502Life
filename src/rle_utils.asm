.skip_line
{
        LDA (src)
        CMP #10
        BEQ skip_whitespace
        CMP #13
        BEQ skip_whitespace
        M_INCREMENT src
        BRA skip_line
}

.skip_whitespace
{
        LDA (src)
        CMP #9
        BEQ skip
        CMP #10
        BEQ skip
        CMP #13
        BEQ skip
        CMP #32
        BEQ skip
        CMP #','                ; not strictly whitespace, but not important in rle header
        BEQ skip
        RTS
.skip
        M_INCREMENT src
        BRA skip_whitespace
}

.parse_rle_header
{
        JSR skip_whitespace
.skip_comments
        LDA (src)
        CMP #'#'
        BNE process
        JSR skip_line
        BRA skip_comments

.process
        JSR skip_whitespace
        LDA (src)
        CMP #'x'
        BNE not_x
        JSR parse_size
        STX pat_width
        STY pat_width + 1
        BRA process

.not_x
        CMP #'y'
        BNE not_y
        JSR parse_size
        STX pat_depth
        STY pat_depth + 1
        BRA process


.not_y
        JMP skip_line
}


.parse_size
{
        STZ count
        STZ count + 1
        M_INCREMENT src
        JSR skip_whitespace
        LDA (src)
        CMP #'='
        BNE return
        M_INCREMENT src
        JSR skip_whitespace
.digit_loop
        LDA (src)
        CMP #'0'
        BCC return
        CMP #'9' + 1
        BCS return
        M_INCREMENT src
        TAX
        JSR count_times_10
        TXA
        AND #&0F
        CLC
        ADC count
        STA count
        BCC digit_loop
        INC count + 1
        BRA digit_loop
.return
        LDX count
        LDY count + 1
        RTS
}

.count_times_10
{

        ASL count               ; count *= 2
        ROL count + 1

        LDA count               ; tmp = count
        STA temp
        LDA count + 1
        STA temp + 1

        ASL count               ; count *= 4
        ROL count + 1
        ASL count
        ROL count + 1

        LDA count               ; count += tmp
        CLC
        ADC temp
        STA count
        LDA count + 1
        ADC temp + 1
        STA count + 1
        RTS
}
