tmp = pixels
        
.print_string
{
        PLA
        STA tmp
        PLA
        STA tmp + 1

        LDY #0
.loop        
        INC tmp
        BNE nocarry
        INC tmp + 1
.nocarry
        LDA (tmp), Y
        BMI done
        JSR OSWRCH
        JMP loop
.done
        JMP (tmp)
}
