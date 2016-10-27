   10  REM Experimental Custom VDU Driver for Life
   20  host%=&2800
   30  DIM parasite% 1000 
   40  DIM xy% 10
   50  FOR I%=4 TO 6 STEP 2
   60  P%=host%
   70  O%=parasite%
   80 [OPT I%
   90  .start
  100  PHA
  110  TXA
  120  PHA
  130  TYA
  140  PHA
  145  .screen
  150  LDY #&00
  160  STY &80
  170  LDA #&58
  180  STA &81
  190  .idle1
  200  BIT &FEE0
  210  BPL idle1
  220  LDA &FEE1
  230  EOR (&80),Y
  240  STA (&80),Y
  250  .idle2
  260  BIT &FEE0
  270  BPL idle2
  280  LDY &FEE1
  290  BNE idle1
  300  .zero
  310  CLC
  320  LDA &80
  330  ADC #(320 MOD 256)
  340  STA &80
  350  LDA &81
  360  ADC #(320 DIV 256)
  370  STA &81
  380  BPL idle1
  390  BIT &FF
  400  BPL screen
  410  LDA oldoswrch
  420  STA &20E
  430  LDA oldoswrch+1
  440  STA &20F
  450  PLA
  460  TAY
  470  PLA
  480  TAX
  490  PLA
  500  RTS
  510  .oldoswrch
  520  EQUW &E0A4
  530  .end
  540 ]
  550  NEXT
  560  A%=6
  570  X%=xy% MOD 256
  580  Y%=xy% DIV 256
  590  FOR I%=0 TO end-start
  600  !xy%=host%+I%
  610  xy%?4=parasite%?I%
  620  CALL &FFF1
  630  NEXT
  640  MODE 4
  650  PRINT "Hello World"
  660  !xy%=&20E
  670  xy%?4=start MOD 256
  680  CALL &FFF1
  690  !xy%=&20F
  700  xy%?4=start DIV 256
  710  CALL &FFF1
  720  VDU 0
  730  FOR S%=0 TO 1000
  740  FOR R%=0 TO 31
  750  Y%=0
  760  REPEAT
  770  VDU RND
  780  Y%=Y%+RND(20)
  790  IF Y%>255 Y%=0
  800  VDU Y%
  810  UNTIL Y%=0
  820  NEXT
  830  NEXT
  840  REPEAT UNTIL FALSE

