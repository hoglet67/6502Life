org               &1900

include "constants.asm"
        
include "variables.asm"
        
include "macros.asm"

.start
        SEI
        
        LDA #<breeder
        STA this
        LDA #>breeder
        STA this + 1
        
        LDA #&00
        STA new
        LDA #&50
        STA new + 1

        JSR rle_reader
        
        LDA #'A'
        JSR OSWRCH

        CLI
        RTS

include "rle_reader.asm"

org &2000
        
include "breeder.asm"
                
.end

SAVE "",start,end
