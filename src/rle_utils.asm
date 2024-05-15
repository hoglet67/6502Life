.skip_line
{
        LDA byte
        CMP #10
        BEQ skip_whitespace
        CMP #13
        BEQ skip_whitespace
        JSR rle_next_byte
        BRA skip_line
}

.skip_whitespace
{
        LDA byte
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
        JSR rle_next_byte
        BRA skip_whitespace
}

.parse_rle_header
{
        JSR skip_whitespace
.skip_comments
        LDA byte
        CMP #'#'
        BNE process
        JSR skip_line
        BRA skip_comments

.process
        JSR skip_whitespace
        LDA byte
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
        JSR rle_next_byte
        JSR skip_whitespace
        LDA byte
        CMP #'='
        BNE return
        JSR rle_next_byte
        JSR skip_whitespace
.digit_loop
        LDA byte
        CMP #'0'
        BCC return
        CMP #'9' + 1
        BCS return
        JSR rle_next_byte
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

.rle_open_file
{
        LDA #&40                ; open for input only
        LDX src
        LDY src + 1             ; X/Y point to filename
        JSR OSFIND
        CMP #&00                ; returns file handle in A, or 0 if not found
        BEQ not_found
        STA handle              ; save the file handle
        LDA #&FF
        STA src
        STA src + 1
        CLC
        RTS
.not_found
        SEC
        RTS
}

.rle_close_file
{
        LDA #&00                ; close the file
        LDY handle
        JMP OSFIND
}
        
IF _USE_OSGBPB

BLOCK_LEN = &2000
        
.rle_next_byte
{
        PHA
        LDA src + 1
        CMP #>(RLE_BUF + BLOCK_LEN)
        BCC skip_read_block

        ;;  Attempt to read 8K into a buffer
        LDA handle
        STA file_handle
        LDA #<RLE_BUF
        STA address
        LDA #>RLE_BUF
        STA address + 1
        LDA #<BLOCK_LEN
        STA length
        LDA #>BLOCK_LEN
        STA length + 1
        PHX
        PHY
        LDA #&04                ; Read bytes ignoring pointer
        LDX #<control_block
        LDY #>control_block
        JSR OSGBPB
        LDA address
        STA src
        LDA address + 1
        STA src + 1
        LDA #0
        STA (src)
        LDA #<RLE_BUF
        STA src
        LDA #>RLE_BUF
        STA src + 1
        PLY
        PLX
        
.skip_read_block        
        LDA (src)
        STA byte
        BEQ skip_increment
        M_INCREMENT src
.skip_increment
        PLA
        RTS
        
.control_block
.file_handle
        EQUB 0
.address
        EQUD 0
.length
        EQUD 0
.ptr
        EQUD 0
}
        
ELSE
       
.rle_next_byte
{
        PHA
        PHY
        LDY handle
        JSR OSBGET
        BCC not_eof
        LDA #&00
.not_eof        
        STA byte
        PLY
        PLA
        RTS
}

ENDIF
