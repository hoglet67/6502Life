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
        

;; Additional locations used by list8 life
forethis        = &41
middthis        = &44
hicnt_f         = &49
locnt_f         = &4A
hicnt_m         = &4B
locnt_m         = &4C
hicnt_r         = &4D
locnt_r         = &4E
t               = &4F
mask            = &50
outcome         = &51        
        
;; Utils

tmp             = &70
delta           = &72           ; pointer to 8-line block storing
                                ; difference between this and next

;; Patterns

src             = &40
dst             = &42
pat_width       = &44           ; aliases with new_xstart
pat_depth       = &46           ; aliases with new_ystart
count           = &48
handle          = &4A
byte            = &4B
        
;; Beeb Wrapper

ui_show         = &74
ui_rate         = &75
ui_mode         = &76
ui_count        = &77
ui_zoom         = &78        
key_pressed     = &79
step_pressed    = &7A
pan_count       = &7B
stash           = &7C
old_ystart      = &7E  

        
        
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

        
