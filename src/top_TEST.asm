        CPU               1
        ORG               &1900

_LIST8_LIFE_ENGINE  = FALSE

_LIST42_LIFE_ENGINE = FALSE

_MATCHBOX           = FALSE

_USE_OSGBPB         = TRUE

SCRN_BASE           = &2000
BUFFER              = &4000
BUFFER_END          = &F800

RLE_BUF             = (BUFFER + BUFFER_END) DIV 2

include "constants.asm"
include "variables.asm"
include "macros_common.asm"
include "macros_ll.asm"

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

include "utils.asm"
include "rle_utils.asm"
include "rle_reader_ll.asm"

        ORG &2000

.breeder
        EQUS "404bo2bo341b$408bo340b$404bo3bo340b$405b4o340b$416b2o331b$402bo11bo4bo"
        EQUS "329b$400bobo17bo328b$342bobo46bo8bobo11bo5bo328b$342bobo44bo3bo21b6o5b"
        EQUS "6o317b$331bo10bob2o48bo30bo5bo317b$329bo3bo10b2o43bo4bo36bo317b$334bo"
        EQUS "6bo2bo45b5o30bo4bo318b$329bo4bo7b2o83b2o320b$330b5o50b2o362b$385b2o32b"
        EQUS "3o5b2o320b$385b2o2bo13bo13bo3bo4bob2o319b$368b2o12b2ob2o3bo11bobo12bo"
        EQUS "7b2obobo318b$355b2o10bo2bo8b2o2bobo4bo4b2o4bo9b2o4bo7bob2ob2o317b$355b"
        EQUS "2o11b2o9b2o2b3o3bo5b2o5bo8b2o5bo2bo3bo3b2o318b$419bobo5b3o319b2$419bob"
        EQUS "o5b3o319b$355b2o11b2o9b2o2b3o3bo5b2o5bo8b2o5bo2bo3bo3b2o318b$355b2o10b"
        EQUS "o2bo8b2o2bobo4bo4b2o4bo9b2o4bo7bob2ob2o317b$368b2o12b2ob2o3bo11bobo12b"
        EQUS "o7b2obobo318b$385b2o2bo13bo13bo3bo4bob2o319b$385b2o32b3o5b2o320b$330b"
        EQUS "5o50b2o362b$329bo4bo7b2o83b2o320b$334bo6bo2bo45b5o30bo4bo318b$329bo3bo"
        EQUS "10b2o43bo4bo36bo317b$331bo10bob2o48bo30bo5bo317b$342bobo44bo3bo21b6o5b"
        EQUS "6o317b$342bobo46bo8bobo11bo5bo328b$400b2o18bo328b$401bo12bo4bo329b$"
        EQUS "416b2o331b$477b2o270b$475b2ob2o269b$475b4o270b$476b2o271b$376bobo370b$"
        EQUS "376b2o111b2o258b$377bo107b4ob2o5b4o248b$485b6o5b6o247b$463b2o21b4o6b4o"
        EQUS "b2o246b$460b3ob2o34b2o247b$403b2o55b5o21bo262b$400b3ob2o46bo8b3o23bo"
        EQUS "261b$352bobo45b5o21b3o23bo32b4o260b$352b2o47b3o20bo2b2o54b2o3bob2o257b"
        EQUS "$353bo69bo3bobo26bo11b2o14bobobobo7b2o249b$421bo3bo9bobo13b4obo10bo2bo"
        EQUS "13bo3b3o2bo3bo2b2o247b$405b2o14bo3b2o11bo11bo2bob2o4b2o4bobo7b2o6bobo"
        EQUS "3bo4b3o2bo247b$405b2o14bo8bo3b2obo12bobo8b2o5bo8b2o7bo4b3o2bo4bo247b$"
        EQUS "422bo3bo3b3o3bo14bo44b5o248b2$328bobo91bo3bo3b3o3bo14bo44b5o248b$328b"
        EQUS "2o11b2o30b2o30b2o14bo8bo3b2obo12bobo8b2o5bo8b2o7bo4b3o2bo4bo247b$329bo"
        EQUS "11b2o30b2o30b2o14bo3b2o11bo11bo2bob2o4b2o4bobo7b2o6bobo3bo4b3o2bo247b$"
        EQUS "421bo3bo9bobo13b4obo10bo2bo13bo3b3o2bo3bo2b2o247b$423bo3bobo26bo11b2o"
        EQUS "14bobobobo7b2o249b$424bo2b2o54b2o3bob2o257b$426b3o23bo32b4o260b$452bo"
        EQUS "8b3o23bo261b$460b5o21bo262b$460b3ob2o34b2o89b2o156b$463b2o21b4o6b4ob2o"
        EQUS "87b4o155b$485b6o5b6o88b2ob2o154b$485b4ob2o5b4o91b2o155b$489b2o258b$"
        EQUS "464bo136b4o144b$464bobo133b6o143b$280bobo181b2o134b4ob2o142b$280b2o"
        EQUS "294b3o13b3o9b2o9b2o132b$281bo252bobo38b5o12bo18b4ob2o131b$516b3o14b2o"
        EQUS "2bo37b3ob2o12bo17b6o132b$515b5o12b3o2bo40b2o27bo4b4o133b$515b3ob2o10b"
        EQUS "3o72bo2bo139b$440bo77b2o11bobo2b2o59b3o149b$440bobo87b2ob3obo38b2o17b"
        EQUS "5o12b2o135b$440b2o89bo6bo37b2o16b3o14bo3bo133b$532bo4bo20b2o15bo2bo14b"
        EQUS "o3bo9bo3bo4bo132b$534b5o6b2o10bo2bo8b2o4bobo7b2o5b2o2bo4b2o5bobo5bo"
        EQUS "132b$538b2o5b2o11b2o9b2o5bo8b2o5bo6b3o9b2ob3o132b$538b2o53b8o148b2$"
        EQUS "538b2o53b8o148b$449b2o30b2o30b2o23b2o5b2o11b2o9b2o5bo8b2o5bo6b3o9b2ob"
        EQUS "3o81b2o49b$232bobo214b2o30b2o30b2o19b5o6b2o10bo2bo8b2o4bobo7b2o5b2o2bo"
        EQUS "4b2o5bobo5bo79b2ob2o48b$232b2o298bo4bo20b2o15bo2bo14bo3bo9bo3bo4bo79b"
        EQUS "4o49b$233bo297bo6bo37b2o16b3o14bo3bo81b2o50b$530b2ob3obo38b2o17b5o12b"
        EQUS "2o135b$531bobo2b2o59b3o110b2o37b$531b3o72bo2bo96b4ob2o5b4o27b$392bo"
        EQUS "139b3o2bo40b2o27bo4b4o90b6o5b6o26b$392bobo138b2o2bo37b3ob2o12bo17b6o"
        EQUS "67b2o21b4o6b4ob2o25b$392b2o140bobo38b5o12bo18b4ob2o63b3ob2o34b2o26b$"
        EQUS "576b3o13b3o9b2o9b2o7b2o55b5o21bo41b$600b4ob2o14b3ob2o46bo8b3o23bo40b$"
        EQUS "600b6o15b5o21b3o23bo32b4o39b$601b4o17b3o20bo2b2o54b2o3bob2o36b$644bo3b"
        EQUS "obo26bo11b2o14bobobobo7b2o28b$642bo3bo9bobo13b4obo10bo2bo13bo3b3o2bo3b"
        EQUS "o2b2o26b$569bo56b2o14bo3b2o11bo11bo2bob2o4b2o4bobo7b2o6bobo3bo4b3o2bo"
        EQUS "26b$184bobo381bo57b2o14bo8bo3b2obo12bobo8b2o5bo8b2o7bo4b3o2bo4bo26b$"
        EQUS "184b2o382b3o72bo3bo3b3o3bo14bo44b5o27b$185bo563b$643bo3bo3b3o3bo14bo"
        EQUS "44b5o27b$562b2o30b2o30b2o14bo8bo3b2obo12bobo8b2o5bo8b2o7bo4b3o2bo4bo"
        EQUS "26b$562b2o30b2o30b2o14bo3b2o11bo11bo2bob2o4b2o4bobo7b2o6bobo3bo4b3o2bo"
        EQUS "26b$344bo297bo3bo9bobo13b4obo10bo2bo13bo3b3o2bo3bo2b2o26b$344bobo198bo"
        EQUS "98bo3bobo26bo11b2o14bobobobo7b2o28b$344b2o198bo100bo2b2o54b2o3bob2o36b"
        EQUS "$544b3o100b3o23bo32b4o39b$673bo8b3o23bo40b$681b5o21bo41b$681b3ob2o34b"
        EQUS "2o26b$684b2o21b4o6b4ob2o25b$706b6o5b6o26b$706b4ob2o5b4o27b$136bobo571b"
        EQUS "2o37b$136b2o547bo63b$137bo547bobo61b$685b2o62b3$296bo452b$296bobo198bo"
        EQUS "251b$296b2o198bo252b$496b3o162bo55b2o30b$661bobo52b4o29b$661b2o53b2ob"
        EQUS "2o28b$718b2o29b2$727b4o18b$726b6o17b$88bobo635b4ob2o16b$88b2o547bo64b"
        EQUS "3o25b2o9b2o6b$89bo547bobo61b5o31b4ob2o5b$637b2o62b3ob2o16b2o12b6o6b$"
        EQUS "665b2o37b2o16bobo13b4o7b$664bo2bo53bo2bo12bo11b$248bo412b2obo61bo9bobo"
        EQUS "10b$248bobo198bo216b2o52bo15bobo10b$248b2o198bo212bo3b2o39b2o17bobobo"
        EQUS "10b2o7b$448b3o212bobo22b2o15bo2bo13bo2bobo2bo9bobo6b$643b2o30b2o10bo2b"
        EQUS "o4bo3b2o4bobo7b2o6b2o5bo2bo8bo6b$643b2o23b2o5b2o11b2o5bo3b2o5bo8b2o11b"
        EQUS "obobo2bo4b3o6b$668b2o55b2obo3bo2bo13b2$668b2o55b2obo3bo2bo13b$3b2o30b"
        EQUS "2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b"
        EQUS "2o30b2o30b2o30b2o30b2o30b2o23b2o5b2o11b2o5bo3b2o5bo8b2o11bobobo2bo4b3o"
        EQUS "6b$3b2o30b2o3bobo24b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b"
        EQUS "2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o10bo2bo4bo3b2o4bobo7b2o"
        EQUS "6b2o5bo2bo8bo6b$40b2o547bo73bobo22b2o15bo2bo13bo2bobo2bo9bobo6b$41bo"
        EQUS "547bobo69bo3b2o39b2o17bobobo10b2o7b$589b2o75b2o52bo15bobo10b$3bo657b2o"
        EQUS "bo61bo9bobo10b$2b3o659bo2bo53bo2bo12bo11b$bo3bo194bo464b2o37b2o16bobo"
        EQUS "13b4o7b$ob3obo193bobo198bo299b3ob2o16b2o12b6o6b$b5o194b2o198bo300b5o"
        EQUS "31b4ob2o5b$196b2o30b2o30b2o30b2o30b2o30b2o30b2o10b3o17b2o30b2o30b2o30b"
        EQUS "2o30b2o152b3o25b2o9b2o6b$35b2o30b2o30b2o30b2o30b2o30bo2bo28bo2bo28bo2b"
        EQUS "o28bo2bo28bo2bo28bo2bo28bo2bo28bo2bo28bo2bo28bo2bo28bo2bo28bo2bo175b4o"
        EQUS "b2o16b$35bobo29bobo29bobo29bobo29bobo29bo2bo28bo2bo28bo2bo28bo2bo28bo"
        EQUS "2bo28bo2bo28bo2bo28bo2bo28bo2bo28bo2bo28bo2bo28bo2bo175b6o17b$36b2o30b"
        EQUS "2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b"
        EQUS "2o30b2o177b4o18b$6b3o692bo47b$8bo691bo48b$7bo741b$701bobo45b$703bo45b$"
        EQUS "701bo47b$702bo46b2$38b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o"
        EQUS "30b2o371b4o14b$4b3o30bobo29bobo29bobo29bobo29bobo29bo2bo28bo2bo28bo2bo"
        EQUS "28bo2bo28bo2bo28bo2bo369b6o13b$3bo3bo29b2o30b2o30b2o30b2o30b2o30bo2bo"
        EQUS "28bo2bo28bo2bo28bo2bo28bo2bo28bo2bo229b2o138b4ob2o12b$2bo5bo189b2o30b"
        EQUS "2o30b2o30b2o30b2o30b2o229b2o115b3o25b2o9b2o2b$2b2obob2o193b2o387bo113b"
        EQUS "5o15b3o13b4ob2ob$202bobo461b2o37b3ob2o14bo15b6o2b$202bo464b2o39b2o18bo"
        EQUS "13b4o3b$5bo659bobo59bo12bo8b$4bobo657b3o71b2o9b$4bobo34b2o621bo2bo62bo"
        EQUS "8bo2bo6b$5bo35bobo356b2o262bob3o39b2o19b4o7b3ob2o3b$41bo357b2o264bo2bo"
        EQUS "21b2o15bo2bo21bo13bo2b$5b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b"
        EQUS "2o30b2o30b2o30b2o10bo19b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o19b2o9b2o"
        EQUS "10bo2bo8b2o4bobo7b2o5b4o2bob2o12bo2b$5b2o30b2o30b2o30b2o30b2o30b2o30b"
        EQUS "2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b2o30b"
        EQUS "2o23b2o5b2o11b2o9b2o5bo8b2o5bobobobo4b2o5bo2b2o2b$670b2o53b2o2bobo11b"
        EQUS "2o4b2$670b2o53b2o2bobo11b2o4b$422bo30b2o30b2o30b2o30b2o30b2o30b2o30b2o"
        EQUS "23b2o5b2o11b2o9b2o5bo8b2o5bobobobo4b2o5bo2b2o2b$422bo30b2o30b2o30b2o"
        EQUS "30b2o30b2o30b2o23b2o5b2o19b2o9b2o10bo2bo8b2o4bobo7b2o5b4o2bob2o12bo2b$"
        EQUS "424b2o211b2o26bo2bo21b2o15bo2bo21bo13bo2b$250b2o387bo24bob3o39b2o19b4o"
        EQUS "7b3ob2o3b$250bobo411bo2bo62bo8bo2bo6b$250bo413b3o71b2o9b$665bobo59bo"
        EQUS "12bo8b$667b2o39b2o18bo13b4o3b$89b2o575b2o37b3ob2o14bo15b6o2b$89bobo"
        EQUS "356b2o212b2o41b5o15b3o13b4ob2ob$89bo357b2o212b2o43b3o25b2o9b2o2b$449bo"
        EQUS "213bo66b4ob2o12b$730b6o13b$731b4o14b2$479b6o6b2o229b2o25b$478bo5bo4bo"
        EQUS "4bo225b2ob2o24b$472b2o10bo10bo190b2o32b4o25b$414b2o38b5o12b2o5bo4bo5bo"
        EQUS "5bo189b2o34b2o26b$298b2o113b3o37bo4bo14bo6b2o8b6o191bo61b$298bobo93b5o"
        EQUS "12b2o3bo41bo27bo262b$298bo94bo4bo12bo3bo37bo3bo28b3o260b$398bo11bo44bo"
        EQUS "21bo7bob2o2bo257b$393bo3bo12b3o2b2o59b3o8b3o2bo256b$137b2o256bo14bobob"
        EQUS "3o38b2o16b3o10b5o2bo255b$137bobo271b3ob2o20b2o15bo2bo14bo3bo3bo5b3obob"
        EQUS "3o215b2o37b$137bo275b2o9b2o10bo2bo8b2o4bobo7b2o5bo2bobo4bo9b2ob2o213b"
        EQUS "2o38b$417b2o5b2o11b2o9b2o5bo8b2o5bo8bo9b2ob2o216bo37b$417b2o53b8o252b"
        EQUS "6o6b2o3b$731bo5bo4bo4bob$417b2o53b8o257bo10bo$360b2o30b2o23b2o5b2o11b"
        EQUS "2o9b2o5bo8b2o5bo8bo9b2ob2o212b5o19bo4bo5bo5bo$360b2o30b2o19b2o9b2o10bo"
        EQUS "2bo8b2o4bobo7b2o5bo2bobo4bo9b2ob2o210bo4bo20bobo8b6o$411b3ob2o20b2o15b"
        EQUS "o2bo14bo3bo3bo5b3obob3o152b5o59bo37b$410bobob3o38b2o16b3o10b5o2bo152bo"
        EQUS "4bo21bo32bo3bo20bo2bo14b$346b2o62b3o2b2o59b3o8b3o2bo158bo20bobo33bo21b"
        EQUS "3ob2o13b$346bobo61bo44bo21bo7bob2o2bo154bo3bo24bo53b2o3bob2o11b$346bo"
        EQUS "64bo3bo37bo3bo28b3o159bo21bob2o24b2obo12b2o14bo3bo9b3o2b$411b2o3bo41bo"
        EQUS "27bo181bob2o25b4ob2o9bo2bo13bobobob2o4bo3b2ob$413b3o37bo4bo14bo6b2o8b"
        EQUS "6o155b2o13b3o2b2o7b2ob2o11bo4b2o4b2o4bobo7b2o6b5obobo2bobo2b2o$185b2o"
        EQUS "227b2o38b5o12b2o5bo4bo5bo5bo155b2o14b2o2b2o3bo4b3o12bobo8b2o5bo8b2o7bo"
        EQUS "4b2o2bo5bob$185bobo284b2o10bo10bo180b2o3b2o14bo40bo3b5o2b$185bo292bo5b"
        EQUS "o4bo4bo254b$370b2o107b6o6b2o183b2o3b2o14bo40bo3b5o2b$370bobo278b2o14b"
        EQUS "2o2b2o3bo4b3o12bobo8b2o5bo8b2o7bo4b2o2bo5bob$370bo97bo2bo179b2o13b3o2b"
        EQUS "2o7b2ob2o11bo4b2o4b2o4bobo7b2o6b5obobo2bobo2b2o$472bo195bob2o25b4ob2o"
        EQUS "9bo2bo13bobobob2o4bo3b2ob$468bo3bo175bo21bob2o24b2obo12b2o14bo3bo9b3o"
        EQUS "2b$469b4o173bo3bo24bo53b2o3bob2o11b$651bo20bobo33bo21b3ob2o13b$646bo4b"
        EQUS "o21bo32bo3bo20bo2bo14b$394b2o251b5o59bo37b$394bobo309bo4bo20bobo8b6o$"
        EQUS "394bo312b5o19bo4bo5bo5bo$737bo10bo$731bo5bo4bo4bob$233b2o497b6o6b2o3b$"
        EQUS "233bobo513b$233bo487bo2bo24b$418b2o305bo23b$418bobo300bo3bo23b$418bo"
        EQUS "303b4o23b6$442b2o305b$442bobo304b$442bo306b3$281b2o466b$281bobo465b$"
        EQUS "281bo467b$466b2o281b$466bobo280b$466bo282b$491b2o256b$487b4ob2o5b4o"
        EQUS "246b$487b6o5b6o245b$465b2o21b4o6b4ob2o244b$462b3ob2o34b2o245b$462b5o"
        EQUS "21bo260b$454bo8b3o23bo259b$428b3o23bo32b4o258b$426bo2b2o54b2o3bob2o"
        EQUS "255b$425bo3bobo26bo11b2o14bobobobo7b2o247b$329b2o92bo3bo9bobo13b4obo"
        EQUS "10bo2bo13bo3b3o2bo3bo2b2o245b$329bobo11b2o30b2o30b2o14bo3b2o11bo11bo2b"
        EQUS "ob2o4b2o4bobo7b2o6bobo3bo4b3o2bo245b$329bo13b2o30b2o30b2o14bo8bo3b2obo"
        EQUS "12bobo8b2o5bo8b2o7bo4b3o2bo4bo245b$424bo3bo3b3o3bo14bo44b5o246b2$424bo"
        EQUS "3bo3b3o3bo14bo44b5o246b$407b2o14bo8bo3b2obo12bobo8b2o5bo8b2o7bo4b3o2bo"
        EQUS "4bo245b$407b2o14bo3b2o11bo11bo2bob2o4b2o4bobo7b2o6bobo3bo4b3o2bo245b$"
        EQUS "353b2o68bo3bo9bobo13b4obo10bo2bo13bo3b3o2bo3bo2b2o245b$353bobo69bo3bob"
        EQUS "o26bo11b2o14bobobobo7b2o247b$353bo49b3o20bo2b2o54b2o3bob2o255b$402b5o"
        EQUS "21b3o23bo32b4o258b$402b3ob2o46bo8b3o23bo259b$405b2o55b5o21bo260b$462b"
        EQUS "3ob2o34b2o245b$465b2o21b4o6b4ob2o244b$377b2o108b6o5b6o245b$377bobo107b"
        EQUS "4ob2o5b4o246b$377bo113b2o256b2$478b2o269b$477b4o268b$477b2ob2o267b$"
        EQUS "479b2o268b$401b2o346b$401bobo16b2o327b$401bo14b4ob2o5b4o317b$416b6o5b"
        EQUS "6o316b$374bo19b2o21b4o6b4ob2o315b$372b2obo15b3ob2o34b2o316b$334b2o35bo"
        EQUS "3bo15b5o353b$331b3ob2o30b4obobo17b3o354b$331b5o30bobo3b2o12b2o33bo327b"
        EQUS "$332b3o20bo4b2o4bobo16bo2bo32b2o5b3o318b$354bobo2b2obo2b2ob2o18bo15bo"
        EQUS "14bo2bo3b2o321b$353bo3bo2b2ob3o2b4o11b2o5b2o11b2o12b3o6bo4b2o316b$340b"
        EQUS "2o12bo2bo4bo3b2obob2o17b2o4b2o4b3o7b2o4b2o5b2ob2o2bo316b$340b2o12b2ob"
        EQUS "2o9b2ob2o11bobo9b2o14b2o5bobo10bo316b$370bo14bo35bo7b3o317b2$370bo14bo"
        EQUS "35bo7b3o317b$340b2o12b2ob2o9b2ob2o11bobo9b2o14b2o5bobo10bo316b$340b2o"
        EQUS "12bo2bo4bo3b2obob2o17b2o4b2o4b3o7b2o4b2o5b2ob2o2bo316b$353bo3bo2b2ob3o"
        EQUS "2b4o11b2o5b2o11b2o12b3o6bo4b2o316b$354bobo2b2obo2b2ob2o18bo15bo14bo2bo"
        EQUS "3b2o321b$332b3o20bo4b2o4bobo16bo2bo32b2o5b3o318b$331b5o30bobo3b2o12b2o"
        EQUS "33bo327b$331b3ob2o30b4obobo17b3o354b$334b2o35bo3bo15b5o353b$372b2obo"
        EQUS "15b3ob2o34b2o316b$374bo19b2o21b4o6b4ob2o315b$416b6o5b6o316b$416b4ob2o"
        EQUS "5b4o317b$403b2o15b2o327b$402bo346b$407b2o340b$406b4o339b$406b2ob2o338b"
        EQUS "$408b2o!"

.end

SAVE "",start,end
