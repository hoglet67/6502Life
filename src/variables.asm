;; TODO - tidy up these allocations
        
;; List Life Engine

this            = &80           ; used by both
new             = &82           ; used by both
temp            = &84           ; used by both
xx              = &86           ; used by both
yy              = &88           ; used by both        
prev            = &8A           ; used by list_life()
next            = &8C           ; used by list_life()
bitmap          = &8E           ; used by list_life()
list            = &60           ; used by list_life_update_delta()
xstart          = &62           ; used by list_life_update_delta()
ystart          = &64           ; used by list_life_update_delta()
xend            = &66           ; used by list_life_update_delta()
yend            = &68           ; used by list_life_update_delta()        
pan_x           = &6A
pan_y           = &6C
tmplsb          = &6E        

;; Additional locations used by list8 life
forethis        = &40
middthis        = &41
hicnt_f         = &42
locnt_f         = &43
hicnt_m         = &44
locnt_m         = &45
hicnt_r         = &46
locnt_r         = &47
t               = &48
mask            = &49
outcome         = &4A        
        
;; Utils

tmp             = &70
delta           = &72           ; pointer to 8-line block storing
                                ; difference between this and next

;; Patterns

src             = &40
dst             = &42
pat_width       = &44
pat_depth       = &46
count           = &48
handle          = &4A
byte            = &4B
        
;; Beeb Wrapper

ui_show         = &50
ui_rate         = &51
ui_mode         = &52
ui_count        = &53
ui_zoom         = &54        
key_pressed     = &55
step_pressed    = &56
pan_count       = &57
stash           = &58
old_xstart      = &5A  
old_ystart      = &5C  
        
;; Atom Life Engine

pixels          = &80           ; block of 8 pixels (cells) being updates
sum_idx         = &82           ; index into the pixel accumulator
tmpY            = &83           ; temp storage for Y register
tmpC            = &84           ; temp storage for carry flag
numrows         = &85           ; row counter, decrements down to zer0
row1            = &87           ; pointer to row1 in the workspace (the one being updated)
sum_ptr         = &89           ; set but not UNUSED
scrn_tmp        = &8B           ; pointer to the current row in screen memory
row0            = &8D           ; pointer to row0 in the workspace (the row above)
row2            = &8F           ; pointer to row0 in the workspace (the row beloe)

;; Atom Life Engine and other stuff

scrn            = &91           ; pointer to the next row in screen memory

        
