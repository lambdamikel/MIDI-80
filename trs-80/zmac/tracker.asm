; TRACKER Version 1.3

	org $8000

POSMARKSYM equ	$aa
SETSYM 	equ	$8f
CURSYM 	equ	'X'
ENTER	equ	$0d ; @DSPLY with newline

KCURLEFT	equ 8
KCURRIGHT	equ 9
KCURUP		equ 91
KCURDOWN	equ 10

@DSPLY		equ	$4467
@EXIT		equ	$402d
@KBD    	equ 	$002b 
@KEY    	equ 	$0049 
@DSP    	equ 	$0033

stopped: ascii   'S'
playing: ascii   'P'
free: 	 ascii   'F'
tracked: ascii   'T'


title:	ascii   '***** MIDI/80 DRUM TRACKER V1.3 -- (C) 2024 BY LAMBDAMIKEL *****'
	ascii   'TRACK: 1 SPEED: -- VOL: 7F NOTE: 24 BARS: 8 STEP: 01 PAT: A S-F '
	ascii	'1===-===+===-===2===-===+===-===3===-===+===-===4===-===+===-===' 
data:	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii	'5===-===+===-===6===-===+===-===7===-===+===-===8===-===+===-===' 
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'
	ascii   '|...-...+...-...|...-...+...-...|...-...+...-...|...-...+...-...'

helpt:	ascii   '************************** HELP PAGE ***************************'
	ascii   'CURSOR MOVEMENT       : A D W X                                 '
	ascii   'X CURSOR MOVEMENT FINE: Z C                                     '
	ascii   'JUMP TO BAR POS       : 1 2 3 4 5 6 7 8                         '
	ascii   'CHANGE BAR COUNT      : B                                       '
	ascii   'NEXT / PREV GRID POS  : ARROW-UP ARROW-DOWN                     '
	ascii   'CLEAR GRID POS        : CLEAR                                   '
	ascii   'SET   GRID POS        : SPACE                                   '
	ascii   'SET   GRID POS & SOUND: ENTER                                   '
	ascii   'PLAY & STOP           : P                                       '
	ascii   'TOGGLE TRACKING       : T                                       '
	ascii   'CHANGE PLAYBACK SPEED : N M , .                                 '
	ascii   'CHANGE CUR TRACK DRUM : ARROW-LEFT ARROW-RIGHT                  '
	ascii   'CHANGE GRID STEP      : G                                       '
	ascii   'LOAD & SAVE           : L S                                     '
	ascii   'HELP                  : H                                       '
	ascii   'QUIT                  : Q                                       '	


lastcur	     byte	'.'
lastcurpos   word 	$3c00+3*64 

cursorx	byte 	0
cursory	byte 	3
blink   byte    0
status  byte    0
track	byte    0
delayc 	byte	0
tempo   byte	10
numbars byte	8
numticks byte	8*16 
gridres byte  	4 
quantpat  byte  11111100b
tracks1 defs    6*64 		
tracks2 defs    6*64

instracks byte 36, 38, 40, 51, 44, 46 

memcursorx byte 	0
memcursory byte 	0
	
trackpos    byte        0
qtrackpos   byte 	0



keydown macro key
	ld	a,(key >> 8)
	and	key % $100
	endm 

k_@	equ	$380101
k_A	equ	$380102
k_B	equ	$380104
k_C	equ	$380108
k_D	equ	$380110
k_E	equ	$380120
k_F	equ	$380140
k_G	equ	$380180

k_H	equ	$380201
k_I	equ	$380202
k_J	equ	$380204
k_K	equ	$380208
k_L	equ	$380210
k_M	equ	$380220
k_N	equ	$380240
k_O	equ	$380280

k_P	equ	$380401
k_Q	equ	$380402
k_R	equ	$380404
k_S	equ	$380408
k_T	equ	$380410
k_U	equ	$380420
k_V	equ	$380440
k_W	equ	$380480

k_X	equ	$380801
k_Y	equ	$380802
k_Z	equ	$380804

k_0	equ	$381001
k_1	equ	$381002
k_2	equ	$381004
k_3	equ	$381008
k_4	equ	$381010
k_5	equ	$381020
k_6	equ	$381040
k_7	equ	$381080

k_8	equ	$382001
k_9	equ	$382002
k_colon	equ	$382004
k_semi	equ	$382008
k_comma	equ	$382010
k_dash	equ	$382020
k_dot	equ	$382040
k_slash	equ	$382080

k_enter	equ	$384001
k_clear	equ	$384002
k_break	equ	$384004
k_up	equ	$384008
k_down	equ	$384010
k_left	equ	$384020
k_right	equ	$384040
k_space	equ	$384080

k_shift	equ	$388001


main:

	in  a,($ff)
	or  a,$10 		; enable IO on Model III 
	; and a,~$20 		; disable video wait states M III 
	and a,~$40 		; slode mode M4 
	out ($ec),a

	ld	hl,data 
	ld	de,tracks1
	ld	bc,6*64 
	ldir

	ld	hl,data 
	ld	de,tracks2 
	ld	bc,6*64 
	ldir

main2:

	ld	hl,$3c00
	ld	de,$3c00+1
	ld	bc,1024-1
	ld	(hl),' '
	ldir

	ld	hl,title
	ld	de,$3c00
	ld	bc,1024
	ldir


	call screenupdate
	call showcursor
	call showplaycursor
	call showtempo

loop:
	ld a, (status) ; stopped ? 
	or a
	jp z, nostep
	
	ld a, (delayc)
	inc a
	ld hl,delayc
	ld (hl), a
	ld b, a
	ld a, (tempo) 
	cp b
	jp nz, nostep
	
	;;  inc note pointer
	call nextnote
	call showplaycursor
	call playnotes

	ld a,0
	ld (delayc),a

	ld a,(track)
	or a
	jp z, nostep

	;; tracked - set screen cursor x to playcursor x

	ld a,(trackpos)
	bit 6,a
	jr nz,trackcury ; > 64 inc y

	res 6,a
	ld (cursorx),a
	ld (memcursorx),a
	
	ld a,(cursory)
	cp 10
	jr c, showtrackcur

	
	sub 7
	ld (cursory), a
	ld a,(memcursory)
	sub 6
	ld (memcursory),a
	
	jr showtrackcur	

trackcury:
	res 6,a	
	
	ld (cursorx),a
	ld (memcursorx),a

	ld a,(cursory)
	cp 10
	jr nc,showtrackcur
	
	add 7	
	ld (cursory),a
	ld a,(memcursory)
	add 6 
	ld (memcursory),a
	

showtrackcur:
	ld hl, blink
	ld (hl), 127

	call showcursor

	jr scan 
	
nostep:

	ld a,(blink)
	inc a
	ld (blink), a

	cp 0
	jp nz, cur1
	call showcursor

cur1:	 
	cp 127
	jp nz, scan  
	call showcursor
		
scan:
	
	ld a, (status) 
	or a
	jr nz,scancont

	;; here we only sample if the tracking is stopped!

	call @KBD
	cp 0
	jp z,loop

        cp ' ' ; space
	jp z,setgrid 

	cp 13 ; enter
	jp z,setgridandsound

	cp 31 ; clear 
	jp z,erasegrid

	jr scancont1

scancont:

	call @KBD
	cp 0
	jp z,loop

scancont1:

	cp 'Z' 
	jp z,left
	cp 'Y' 
	jp z,left
	cp 'A' 
	jp z,prevbar
	cp 'C'
	jp z,right
	cp 'D'
	jp z,nextbar
	cp 'W'
	jp z,up
	cp 'X' 
	jp z,down

	cp ',' 
	jp z,faster	
	cp '.'
	jp z,slower 
	cp 'N' 
	jp z,faster1
	cp 'M' 
	jp z,slower1 
		
	cp 'P' 
	jp z,startstop

	cp 'T'
	jp z,trackstatus
	
	cp KCURLEFT
	jp z,instrdown

	cp KCURRIGHT
	jp z,instrup 

	cp KCURUP 
	jp z,nextbar

	cp KCURDOWN 
	jp z,prevbar

	cp '1'
	jp z,bar1

	cp '2'
	jp z,bar2

	cp '3'
	jp z,bar3

	cp '4'
	jp z,bar4

	cp '5'
	jp z,bar5

	cp '6'
	jp z,bar6

	cp '7'
	jp z,bar7

	cp '8'
	jp z,bar8

	cp 'Q'
	jp z,quit

	cp 'H'
	jp z,help

	cp 'L'
	jp z,load

	cp 'S'
	jp z,save

	cp 'G'
	jp z,chgridres

	cp 'B'
	jp z,chgnumbars 

	jp loop 
	
	;;  do a screen update after keypress and continue 
cont:
	call screenupdate
	call showtrack
	call showtrackdrum
	call showgridres
	call showbars
	
	jp loop

chgridres:
	ld a,(gridres)
	sla a 
	and $1f
	jr nz,chgridres1
	ld a,1
	
chgridres1: 
	ld (gridres),a
	
	cp a,1
	jr nz, gridres2
	ld a,11111111b
	ld (quantpat), a	
	jp cont
	
gridres2:
	cp a,2
	jr nz, gridres4
	ld a,11111110b
	ld (quantpat), a	
	jp cont

gridres4:
	cp a,4
	jr nz, gridres8
	ld a,11111100b
	ld (quantpat), a	
	jp cont

gridres8:
	cp a,8
	jr nz, gridres16
	ld a,11111000b
	ld (quantpat), a	
	jp cont

gridres16:
	cp a,16
	jr nz, gridres32
	ld a,11110000b
	ld (quantpat), a	
	jp cont

gridres32:
	cp a,32
	jp nz, cont 
	ld a,11100000b
	ld (quantpat), a	
	jp cont


chgnumbars:
	ld a,(numbars)
	dec a 
	inc a
	and $07
	inc a	
	ld (numbars),a

	ld b,a
	ld a,0
countticks:	
	add 16 
	djnz countticks

	ld (numticks),a
	jp cont 

help:

	ld	hl,$3c00
	ld	de,$3c00+1
	ld	bc,1024-1
	ld	(hl),' '
	ldir

	ld	hl,helpt
	ld	de,$3c00
	ld	bc,1024 
	ldir

	call @KEY
	
	jp main2

load:
	jp loop 

save:
	jp loop 
	
quit:
	call @EXIT
	
nextbar:
	ld a,(cursorx)
	ld hl,gridres
	ld b,(hl)
	add a,b
	cp 64
	jp nc, cont
	ld (cursorx),a
	ld hl,memcursorx 
	ld (hl),a
	jp cont

prevbar:
	ld a,(cursorx)
	ld hl,gridres
	ld b,(hl)
	sub a,b
	jp c, cont
	ld (cursorx),a
	ld hl,memcursorx 
	ld (hl),a
	jp cont

setbar1x macro
	ld (cursorx), a
	ld hl,memcursorx 
	ld (hl),a

	ld a, (cursory)
	cp 9
	jp c,cont
	; else change y cursor 
	sub 7 
	ld (cursory),a
	
	ld a,(memcursory) 
	sub 6
	ld (memcursory),a

	jp cont
	endm


setbar2x macro
	ld (cursorx), a
	ld hl,memcursorx 
	ld (hl),a

	ld a, (cursory)
	cp 10
	jp nc,cont
	; else change y cursor 
	add 7 
	ld (cursory),a
	
	ld a,(memcursory) 
	add 6
	ld (memcursory),a

	jp cont
	endm 

bar1:
	ld a,0
	setbar1x 
	
bar2:	
	ld a,16
	setbar1x 

bar3:
	ld a,32
	setbar1x 

bar4:
	ld a,48
	setbar1x 

bar5:
	ld a,0
	setbar2x 

bar6:
	ld a,16
	setbar2x
	
bar7:
	ld a,32
	setbar2x
	
bar8:
	ld a,48
	setbar2x 

faster:
	ld a,(tempo)
	cp 1 
	jp z,cont
	
	dec a
	ld c,a
	ld (tempo),a
	ld a,0
	ld hl,delayc
	ld (hl),0
	call showtempo
	jp cont

faster1:
	ld a,(tempo)
	cp $11
	jp c,cont
	
	sub $10
	ld c,a
	ld (tempo),a
	ld a,0
	ld hl,delayc
	ld (hl),0
	call showtempo
	jp cont
	
slower:
	ld a,(tempo)
	cp a,255
	jp z,cont
	
	inc a
	ld c,a
	ld (tempo),a
	ld a,0
	ld hl,delayc
	ld (hl),0

	call showtempo
	jp cont	

slower1:
	ld a,(tempo)
	cp a,$f0
	jp nc,cont
	
	add $10
	ld c,a
	ld (tempo),a
	ld a,0
	ld hl,delayc
	ld (hl),0

	call showtempo
	jp cont	

testsoundx macro 
	call gettrackdrum
	ld b,a
	
	ld a,$90+9
	out (8),a
  
	call short_delay

	ld a,b
	out (8),a 
  
	call short_delay  
  
	ld a,127
	out (8),a
  
	endm 

instrup:
	call gettrackdrum
	inc a 
	ld (hl), a
	jp cont 

instrdown:
	call gettrackdrum
	dec a 
	ld (hl), a
	jp cont

restorecellx macro 
	ld a,(memcursorx)
	
	ld hl,data
	ld d,0
	ld e,a
	add hl,de	
	ld a,(hl)
	endm 

setgridx macro
        local setpos1
	call memcursor
	ld (hl),SETSYM 
	ld hl,lastcur
	ld (hl),SETSYM 
	endm 

erasegridx macro
        local setpos1
	call memcursor
	ld a, (hl)
	;;  erase
	push hl
	restorecellx 
	pop hl
	ld (hl),a
	ld hl,lastcur
	ld (hl),a 
	endm 

gettrackdrumx macro 
	call gettracknr
	dec a
	ld hl,instracks
	ld d,0
	ld e,a
	add hl, de 
	ld a,(hl)
	endm


setgridandsound:
	
	testsoundx
	setgridx 

	jp cont 

setgridandsoundr:
	
	testsoundx
	setgridx 

	ret
	
setgrid:
	
	setgridx 
	jp cont

setgridr:
	
	setgridx 
	ret

erasegrid:
	
	erasegridx 
	jp cont

erasegridr:
	
	erasegridx 
	ret 

startstop:
	ld a,(status)
	xor 1
	ld (status), a
	or a
	jr nz, showplay
	
	ld de,$3c00 + 64 + 60
	ld hl,stopped 
	ld bc,1 
	ldir
	jp cont 
showplay:
	ld de,$3c00 + 64 + 60
	ld hl,playing  
	ld bc,1
	ldir
	jp cont 

trackstatus:
	ld a,(track)
	xor 1
	ld (track), a
	or a
	jr nz, showtrackstatus
	
	ld de,$3c00 + 64 + 62
	ld hl,free 
	ld bc,1
	ldir
	jp cont
	
showtrackstatus:	
	ld de,$3c00 + 64 + 62
	ld hl,tracked   
	ld bc,1
	ldir
	jp cont 


left:	
	ld a,(cursorx)
	cp 0
	jp z, cont
	dec a	
	ld (cursorx),a
	ld hl,memcursorx 
	ld (hl),a
	jp cont
right:
	ld a,(cursorx)
	cp 63
	jp z, cont
	inc a
	ld (cursorx),a
	ld hl,memcursorx 
	ld (hl),a
	jp cont
up:
	ld a,(cursory)
	cp 3
	jp z, cont
	cp 10
	jr nz,up1
	ld a,8
	jr up2
up1:	 
	dec a

up2:	
	ld (cursory),a

	ld hl,memcursory
	ld a,(hl)
	dec a
	ld (hl),a 
	jp cont

down:
	ld a,(cursory)
	cp 15
	jp z, cont
	cp 8
	jr nz,down1
	ld a,10
	jr down2
down1:	
	inc a
down2:	 
	ld (cursory),a
	
	ld hl,memcursory 
	ld a,(hl)
	inc a
	ld (hl),a
	jp cont

	
cursor:
	ld a,(blink)
	inc a
	ld (blink),a
	ld hl,$3c00
	ld a,(cursorx)
	or a
	jr z, moveyup
	ld b,a
movex:	
	inc hl 
	djnz movex
moveyup:	
	ld a,(cursory)
	or a
	ret z
	ld b,a
	ld de,64
movey:
	add hl,de 
	djnz movey
	ret 

memcursor:
	ld hl,tracks1
	ld a,(memcursorx)
	or a
	jr z, mmoveyup
	ld b,a
mmovex:	
	inc hl 
	djnz mmovex
mmoveyup:	
	ld a,(memcursory)
	or a
	ret z
	ld b,a
	ld de,64
mmovey:
	add hl,de 
	djnz mmovey
	ret 

	
dly.01:	ld	bc,d10000th
	sett	0
dly:	dec	bc
	ld	a,b
	or	c
	jp	nz,dly
	ret


nextnote:

	ld a,(qtrackpos)
	inc a
	ld b,a
	
	ld a,(numticks)
	cp b
	ld a,b
	jr nz,nextnote0

	; max tick number reached, set to 0
	ld a, 0

nextnote0:
	ld (qtrackpos),a

	ld b, a
	ld a, (quantpat)
	and b
	ld (trackpos),a

	cp b
	jr z, nextnote1

	;; ENTER sample keyboard; this one makes noise,
	;; ONLY sample when (qtrackpos) = (trackpos)

	keydown k_enter 
	call nz,setgridandsoundr

nextnote1:

	;; sample keyboard

	keydown k_space 
	call nz,setgridr

	keydown k_clear
	call nz,erasegridr

	ld a, (trackpos)

	bit 7,a
	ret z
	
	ld a,0
	ld (qtrackpos),a
	ld (trackpos),a
	
	ret

showplaycursor:
	
	ld	hl,title+2*64 
	ld	de,$3c00+2*64 
	ld	bc,64 
	ldir

	ld	hl,title+9*64 
	ld	de,$3c00+9*64 
	ld	bc,64 
	ldir

	ld a,(qtrackpos)
	
	ld hl,$3c00+2*64
	ld e,a
	ld d,0 
	add hl,de

	bit 6,a
	jr nz,showcurtrack2
	
	ld (hl),POSMARKSYM
	ret
showcurtrack2:
	ld de,6*64
	add hl,de
	ld (hl),POSMARKSYM
	ret
	
	
d10000th	equ	1774080 / t($) / 10000

	  
screenupdate:
	
	;;  swap in track 1 
	ld	hl,tracks1	
	ld	de,$3c00+3*64 
	ld	bc,6*64
	ldir

	;;  swap in track 1 
	ld	hl,tracks2 
	ld	de,$3c00+10*64 
	ld	bc,6*64
	ldir

	ret

showcursor:

	ld hl,(lastcurpos)
	ld a,(lastcur)
	ld (hl),a
	call cursor
	ld (lastcurpos),hl
	ld a,(hl)
	ld (lastcur),a
	
	ld a,(blink)
	cp a,127
	jr c,cur2
	ld (hl), CURSYM 
	ret 

cur2:
	push hl
	restorecellx
	pop hl 
	ret
	
	
byte2ascii: 			; input c, output de ASCII 
   ld a, c
   rra
   rra
   rra
   rra
   call convnibble 
   ld d, a	
   ld  a,c
convnibble:
   and  $0F
   add  a,$90
   daa
   adc  a,$40
   daa
   ld e, a	
   ret

showtempo:
	ld a,(tempo)
	ld c,a 
	ld hl,$3c00+64+16
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e
	ret

gettracknr:
	ld a,(memcursory)
	add 1
	cp 7
	ret c
	sub 6
	ret



gettrackdrum:
	gettrackdrumx
	ret

gettrackdrumreg: ; input: e register, starting at 0
	ld hl,instracks
	ld d,0
	add hl, de 
	ld b,(hl)
	ret

showtrackdrum:
	call gettrackdrum
	ld c, a
	ld hl,$3c00+64+33
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e
	ret

showtrack:
	call gettracknr 
	ld c,a 
	ld hl,$3c00+64+7
	call convnibble 
	ld (hl),e
	ret

playnotes:
	ld a,(qtrackpos)
	
	bit 6,a
	jr nz,playhightracks ; > 64  
	
	ld hl,tracks1
	
	jr playtracks

playhightracks:

	ld hl,tracks2

playtracks: 
	; add note index
	; clear bit 6
	res 6,a
	ld e,a
	ld d,0
	add hl,de
	ld bc,64

	push hl
	push bc
	ld c,(hl) ; -> c is on or off
	ld d,0
	ld e,0 ; e is track number 
	call gettrackdrumreg ; -> b is drum note 
	call playnote

	pop bc
	pop hl
	
	add hl,bc

	push hl
	push bc

	ld c,(hl)
	ld d,0
	ld e,1 
	call gettrackdrumreg 
	call playnote

	pop bc
	pop hl

	add hl,bc

	push hl
	push bc
	
	ld c,(hl) 
	ld d,0
	ld e,2
	call gettrackdrumreg 
	call playnote

	pop bc
	pop hl

	add hl,bc

	push hl
	push bc

	ld c,(hl) 
	ld d,0
	ld e,3 
	call gettrackdrumreg 
	call playnote

	pop bc
	pop hl

	add hl,bc

	push hl
	push bc

	ld c,(hl) 
	ld d,0
	ld e,4 
	call gettrackdrumreg 
	call playnote

	pop bc
	pop hl
	
	add hl,bc

	push hl
	push bc

	ld c,(hl) 
	ld d,0
	ld e,5 
	call gettrackdrumreg 
	call playnote

	pop bc	
	pop hl
	
	ret
	
	
playnote: ; input note on / off in c, instrument in b 

	ld a, c
	cp SETSYM
	ret nz
	
	ld a,$90+9
	out (8),a
  
	call short_delay

	ld a,b
	out (8),a 
  
	call short_delay  
  
	ld a,127
	out (8),a
  
	ret 
	
showgridres:
	ld a,(gridres)
	ld c, a
	ld hl,$3c00+64+50
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e
	ret

showbars:
	ld a,(numbars)
	ld c, a
	ld hl,$3c00+64+42
	call convnibble
	ld (hl),e
	ret


short_delay:
    ld de,$00ff
delloop: 
    dec de
    ld a,d
    or e
    jp nz,delloop
    ret 

	end main 

	
