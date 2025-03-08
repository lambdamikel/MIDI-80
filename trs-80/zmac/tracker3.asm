; TRACKER Version 1.6
; to do: mute tracks, patterns + song mode, save, load

	org $8000

DISPMIDINOTEOFFSET equ $61 ; 0 -> 'a' 

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

waitt:	ascii   '***** MIDI/80 TRACKER V1.60 - (C) 2024-2025 BY LAMBDAMIKEL *****'
	ascii   'PAT:A SF | TRACK:1 SPEED:-- | B:8 S:04 | C:0 I:01 N:24 V:7F G:04'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	ascii	'WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT WAIT'
	
title:	ascii   '***** MIDI/80 TRACKER V1.53 - (C) 2024-2025 BY LAMBDAMIKEL *****'
	ascii   'PAT:A SF | TRACK:1 SPEED:-- | B:8 S:04 | C:0 I:01 N:24 V:7F G:04'
	ascii	'1===-===+===-===2===-===+===-===3===-===+===-===4===-===+===-===' 
data:	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii	'5===-===+===-===6===-===+===-===7===-===+===-===8===-===+===-===' 
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'
	ascii   '!...-...+...-...!...-...+...-...!...-...+...-...!...-...+...-...'

helpt:	ascii   '************************** HELP PAGE ***************************'
	ascii   'CURSOR MOVEMENT, FINE             : A D W X, Z C                '
	ascii   'CHANGE BAR COUNT, JUMP TO BAR POS : B, 1 2 3 4 5 6 7 8          '
	ascii   'NEXT / PREV GRID POS, CHANGE GRID : ARROW-UP ARROW-DOWN, G      '
	ascii   'SET GRID, SOUND, CLEAR            : SPACE, ENTER, CLEAR         '
	ascii   'PLAY & STOP                       : P                           '
	ascii   'ALL NOTES OFF (MIDI PANIC)        : !                           '
	ascii   'TOGGLE TRACKING                   : T                           '
	ascii   'CHANGE PLAYBACK SPEED             : N M , .                     '
	ascii   'CHANGE CUR TRACK MIDI CHANNEL     : + -                         '
	ascii   'CHANGE CUR TRACK MIDI INSTRUMENT  : U I                         '
	ascii   'CHANGE CUR TRACK MIDI VELOCITY    : J K                         '
	ascii   'CHANGE CUR TRACK DRUM, LAST MIDI  : ARROW-LEFT ARROW-RIGHT, @   ' 
	ascii   'CHANGE CUR TRACK GATE LENGTH      : *                           '
	ascii   'HELP, QUIT, LOAD & SAVE           : H Q L S                     '
	ascii   'PAT +/-, CLEAR PAT, COPY PAT, SONG: / ?, =, ", &                '

;; global variables

instrumenttracks 	byte 1, 2, 3, 4, 5, 1 

lastcur	     byte	'.'
lastcurpos   word 	$3c00+3*64 

memcursorx byte 	0
memcursory byte 	0
	
cursorx	byte 	0
cursory	byte 	3
blink   byte    0
status  byte    0
track	byte    0

trackpos   byte  0
qtrackpos  byte  0

midicount     byte  0
curnote       byte  0
curvelocity   byte  0

tracksoff1 	defs    6*64 		
tracksoff2 	defs    6*64

song		ascii	'..........................'
curpat		ascii   'A'
frompat		ascii   'A'

;; page-specific variables

pagestart:

delayc 	byte	0
tempo   byte	10
numbars byte	8
numticks byte	8*16 
gridres byte  	4
quantpat   byte  11111100b

drumnostracks		byte 36, 38, 40, 51, 44, 46 
channeltracks 		byte 0, 1, 2, 3, 4, 9
;; these will be global; too much overhead to change instruments with each page
;; instrumenttracks 	byte 1, 2, 3, 4, 5, 1 
velocitytracks	 	byte 127, 127, 127, 127, 127, 127
gatetracks	 	byte 8,8,8,8,8,8

tracks1 	defs    6*64 		
tracks2 	defs    6*64

pagelen 	equ $-pagestart

pages:		defs 26*pagelen	; pages A-Z


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

	ld	hl,waitt
	ld	de,$3c00
	ld	bc,1024
	ldir

	call initmem 

	in  a,($ff)
	or  a,$10 		; enable IO on Model III 
	; and a,~$20 		; disable video wait states M III 
	and a,~$40 		; slode mode M4 
	out ($ec),a


main2:

	ld	hl,title+2*64
	ld	de,$3c00+2*64
	ld	bc,1024-2*64 
	ldir

	call screenupdate
	call showcursor
	call showplaycursor
	call showtempo

	ld hl, 	$3c00 ; glitch out last cusor pos
	ld (hl), '*'

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

	or a
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

	call midiin
	or a
	jr z, keyscan

	;; else, we got a note in the buffer: just treat this as setgridandsoundmidi for now
	jp setgridandsoundmidi

keyscan:	 

	call @KBD
	or a
	jp z,loop

        cp ' ' ; space
	jp z,setgridkey 

	cp 13 ; enter
	jp z,setgridandsoundkey

	cp 31 ; clear 
	jp z,erasegrid

	jr scancont1

scancont:

	call midiin
	or a
	jr z, keyscan1 

	;; else, we got a note in the buffer: just treat this as setgridandsound for now
	jp setgridandsoundmidi

keyscan1:	 

	call @KBD
	or a
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
	jp z,drumnodown

	cp KCURRIGHT
	jp z,drumnoup 

	cp '@'
	jp z,drumnocurrent 

	cp '+'
	jp z,channelup

	cp '-'
	jp z,channeldown

	cp 'U'
	jp z,instrumentdown

	cp 'I'
	jp z,instrumentup

	cp 'J'
	jp z,velocitydown

	cp 'K'
	jp z,velocityup

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

	cp '!'
	jp z,midipanic

	cp '*'
	jp z,chggatelength

	cp '/'
	jp z,uppat

	cp '?'
	jp z,downpat 

	cp '=' 
	call z,clrpat

	cp '"' 
	jp z,copypat

	cp '&' 
	jp z,songpage

	jp loop 
	
	;;  do a screen update after keypress and continue 
cont:
	call screenupdate	
	call showtrack
	call showtrackdrum
	call showtrackchannel
	call showtrackinstrument
	call showtrackvelocity 
	call showgridres
	call showbars
	call showgate
	call showpat
	
	jp loop


uppat:
	ld a,(curpat)
	cp 'Z'
	jp z,cont

	call putpat

	ld a,(curpat)
	inc a
	ld (curpat), a

	call getpat
	
	jp cont 

downpat:
	ld a,(curpat)
	cp 'A'
	jp z,cont

	call putpat

	ld a,(curpat)
	dec a
	ld (curpat), a

	call getpat	
	
	jp cont

getpatadr:
	ld a,(curpat)
getpatadr1:
	sub 'A'-1
	ld b, a
	ld de, pagelen
	ld hl, pages-pagelen
getpatadr2:
	add hl, de
	djnz getpatadr2

	ret

putpat:
	call getpatadr
	push hl
	pop de 
	ld	hl,pagestart
	ld	bc,pagelen 
	ldir
	
	ret

getpat:
	call getpatadr
	ld	de,pagestart
	ld	bc,pagelen 
	ldir

	ret

initmem:

	ld (hl), 'A'

initmem1:
	ld hl, curpat

	call clrpat1
	call putpat 

	ld hl, curpat
	ld a, (hl)
	inc a
	ld (hl), a
	cp 'Z'	

	jr nz, initmem1 
	
	ld hl, curpat
	ld (hl), 'A'
	
	ret 

clrpat:
	ld	hl,data 
	ld	de,tracks1
	ld	bc,6*64 
	ldir

	ld	hl,data 
	ld	de,tracksoff1
	ld	bc,6*64 
	ldir

	ld	hl,data 
	ld	de,tracks2 
	ld	bc,6*64 
	ldir

	ld	hl,data 
	ld	de,tracksoff2
	ld	bc,6*64 
	ldir

	call midipanicr 
	call long_delay

	call setmiditrackinstruments
	call screenupdate	

	ret 

clrpat1:
	ld	hl,data 
	ld	de,tracks1
	ld	bc,6*64 
	ldir

	ld	hl,data 
	ld	de,tracks2 
	ld	bc,6*64 
	ldir

	ret 

copypat:

	ld hl, curpat
	ld a, (hl)
	ld hl, frompat 
	ld (hl), a 

copypat1: 

	ld hl,$3c00+64+5
	ld (hl), '<'
	inc hl
	ld (hl), '-'
	inc hl
	ld de, frompat
	ld a, (de) 
	ld (hl), a
	inc hl
	ld (hl), '?'

	call @KEY
	cp ENTER
	jp z, copypat2 

	ld hl, frompat
	ld (hl), a 

	jr copypat1

copypat2:

	call long_delay 
	ld hl, frompat
	ld a, (hl)
	cp 'A'
	jr c, copypat1 
	cp 'Z'+1
	jr nc, copypat1

	ld b, a 
	ld a, (curpat)
	cp b
	jr z, copycleanup

	ld a, (frompat)
	call getpatadr1
	ld	de,pagestart
	ld	bc,pagelen 
	ldir

copycleanup:
	ld hl,$3c00+64+5
	ld (hl), ' '
	inc hl 
	ld a,(stopped)
	ld (hl), a
	inc hl
	ld a,(tracked)
	ld (hl), a
	inc hl
	ld (hl), ' '
	
	jp main2  

songpage:
	jp cont 


chggatelength:
	call gettrackgate
	sla a 
	and $1f
	jr nz,chggatelength1
	ld a,1
	
chggatelength1:
	ld (hl), a
	jp cont
	
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
	inc a
	and $07
	ld (numbars),a

	ld b,a
	ld a,0
countticks:	
	add 16 
	djnz countticks

	ld (numticks),a
	jp cont

midiin:

	in a,(9)
	or a
	ret z

	;;  byte available

	in a,(8)
	bit 7,a
	jr nz, midicommand
	
	ld b, a 
	;; MIDI data byte
	ld a, (midicount)
	or a 
	ret z

	;; note byte?
	cp 1
	jr nz, velcheck

	ld a, b 
	ld (curnote), a
	ld a, 2 
	ld (midicount), a

	ld a, 0 

	ret

velcheck:
	; ld a, b			
	; ld (curvelocity), a
	; use velocity from settings instead of MIDI message!

	call gettrackvelocity
	ld (curvelocity), a  

	; signal message complete -> note / vel available
	ld a, 1

	ret 

midicommand:	 

	ld b, a 
	ld a, 0 
	ld (midicount), a

	ld a, b
	;; note on? 
	cp $90 
	jr z, midinoteon

	ld a, 0
	ret 

midinoteon:	 

	;;  note on!
	ld a, 1
	ld (midicount), a

	ld a, 0
	
	ret	


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

	ld a,'*'

	ld	hl,title
	ld	de,$3c00
	ld	bc,1024
	ldir

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

	call gettrackchannel

	add $90 
	out (8),a
  
	call short_delay
	ld a,(curnote)
	out (8),a
  
	call short_delay
	ld a,(curvelocity)
	out (8),a

	endm 

midipanic:

	ld b, $10 

channeloff:

	ld a, b
	dec a
	add $b0	
	out (8),a  		; MIDI CC for Channel in a 
	call short_delay

	ld a,123
	out (8),a  		; MIDI NOTE OFF 
	call short_delay

	ld a,0
	out (8),a  		; Don't Care 
	call short_delay
	
	;;  repeat for all 16 Channels 
	djnz channeloff
	
	jp cont


midipanicr:

	ld b, $10 

channeloffr:

	ld a, b
	dec a
	add $b0	
	out (8),a  		; MIDI CC for Channel in a 
	call short_delay

	ld a,123
	out (8),a  		; MIDI NOTE OFF 
	call short_delay

	ld a,0
	out (8),a  		; Don't Care 
	call short_delay
	
	;;  repeat for all 16 Channels 
	djnz channeloffr
	
	ret 

drumnocurrent:
	call gettrackdrum
	ld a, (curnote)
	and $7f
	ld (hl), a
	jp cont 
	
drumnoup:
	call gettrackdrum
	inc a 
	and $7f
	ld (hl), a
	jp cont 

drumnodown:
	call gettrackdrum
	dec a 
	and $7f
	ld (hl), a
	jp cont

channelup:
	call gettrackchannel 
	inc a 
	and $0f
	ld (hl), a
	
	call gettracknr
	dec a
	call setinstrument

	jp cont 

channeldown:
	call gettrackchannel
	dec a 
	and $0f 
	ld (hl), a

	call gettracknr
	dec a
	call setinstrument

	jp cont

instrumentup:
	call gettrackinstrument
	inc a 
	and $7f
	ld (hl), a

	call gettracknr
	dec a
	call setinstrument
	
	jp cont 

instrumentdown:	
	call gettrackinstrument
	dec a 
	and $7f
	ld (hl), a

	call gettracknr
	dec a
	call setinstrument
	
	jp cont

velocityup:
	call gettrackvelocity
	inc a 
	and $7f
	ld (hl), a
	
	call gettracknr
	dec a
	call setinstrument
	
	jp cont 

velocitydown:	
	call gettrackvelocity
	dec a 
	and $7f
	ld (hl), a

	call gettracknr
	dec a
	call setinstrument

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
	call memcursor
	; ld (hl),SETSYM
	ld a, (curnote)
	add DISPMIDINOTEOFFSET 

	ld (hl), a 
	ld hl,lastcur
	; ld (hl),SETSYM
	ld (hl), a
	endm 

erasegridx macro
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
	ld hl,drumnostracks
	ld d,0
	ld e,a
	add hl, de 
	ld a,(hl)
	endm

gettrackchannelx macro 
	call gettracknr
	dec a
	ld hl,channeltracks
	ld d,0
	ld e,a
	add hl, de 
	ld a,(hl)
	endm

gettrackinstrumentx macro 
	call gettracknr
	dec a
	ld hl,instrumenttracks
	ld d,0
	ld e,a
	add hl, de 
	ld a,(hl)
	endm

gettrackgatex macro 
	call gettracknr
	dec a
	ld hl,gatetracks
	ld d,0
	ld e,a
	add hl, de 
	ld a,(hl)
	endm

gettrackvelocityx macro 
	call gettracknr
	dec a
	ld hl,velocitytracks 
	ld d,0
	ld e,a
	add hl, de 
	ld a,(hl)
	endm

setgridandsoundmidi:

	testsoundx
	setgridx 

	jp cont 

setgridandsoundkey:
	
	call gettrackdrum
	ld (curnote), a 

	call gettrackvelocity
	ld (curvelocity), a  

	testsoundx
	setgridx 

	jp cont 

setgridandsoundr:
	
	testsoundx
	setgridx 

	ret

setgridandsoundkeyr:
	
	call gettrackdrum
	ld (curnote), a 

	call gettrackvelocity
	ld (curvelocity), a  

	testsoundx
	setgridx 

	ret

setgrid:
	
	setgridx 
	jp cont

setgridkey:
	
	call gettrackdrum
	ld (curnote), a 

	call gettrackvelocity
	ld (curvelocity), a  
	
	setgridx 
	jp cont

setgridr:

	setgridx 
	ret

setgridkeyr:

	call gettrackdrum
	ld (curnote), a 

	call gettrackvelocity
	ld (curvelocity), a  
	
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

showstartstop:
	ld hl,$3c00 + 64 + 6
	ld a,(stopped)
	ld (hl), a
	jp cont
	
showplay:

	call midipanicr
	call long_delay

	call gettrackchannel 
	inc a 
	and $0f
	ld (hl), a
	
	call gettracknr
	dec a
	call setinstrument

	call setmiditrackinstruments
	call long_delay

	ld hl,$3c00 + 64 + 6
	ld a,(playing) 
	ld (hl), a
	
	call long_delay

	call playnotes

	jp cont 

trackstatus:
	ld a,(track)
	xor 1
	ld (track), a
	or a
	jr nz, showtrackstatus
	
	ld hl,$3c00 + 64 + 7
	ld a,(free)
	ld (hl), a
	
	jp cont
	
showtrackstatus:	
	ld hl,$3c00 + 64 + 7
	ld a,(tracked)
	ld (hl), a
	
	jp cont 


left:	
	ld a,(cursorx)
	or a
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

	;; call setinstrument
	
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

	;; call setinstrument

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

	call midiin		
	cp 1 
	call z,setgridandsoundr

	keydown k_enter 
	call nz,setgridandsoundkeyr

nextnote1:

	;; sample keyboard

	keydown k_space 
	call nz,setgridkeyr

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
	ld hl,$3c00+64+25
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

gettrackchannel:
	gettrackchannelx
	ret

gettrackinstrument:	
	gettrackinstrumentx 
	ret

gettrackgate:	
	gettrackgatex 
	ret

gettrackvelocity:	
	gettrackvelocityx
	ret

gettrackdrumreg: ; input: e register, starting at 0
	ld hl,drumnostracks
	ld d,0
	add hl, de 
	ld b,(hl)
	ret

gettrackchannelreg: ; input: e register, starting at 0
	ld hl,channeltracks
	ld d,0
	add hl, de 
	ld b,(hl)
	ret

showtrackdrum:
	call gettrackdrum
	ld c, a
	ld hl,$3c00+64+52
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e
	ret

showtrackchannel:
	call gettrackchannel 
	ld c, a
	ld hl,$3c00+64+43
	call convnibble 
	ld (hl),e
	ret

showtrackinstrument:
	call gettrackinstrument
	ld c, a
	ld hl,$3c00+64+47
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e
	ret

showtrackvelocity:
	call gettrackvelocity
	ld c, a
	ld hl,$3c00+64+57
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e
	ret

showtrack:
	call gettracknr 
	ld c,a 
	ld hl,$3c00+64+17
	call convnibble 
	ld (hl),e
	ret

setinstrument: 			; a has track number 

	push af 
	ld ix,channeltracks 	; retrieve MIDI channel for track a
	ld c,a
	ld b,0
	add ix,bc
	ld a,(ix) 		; MIDI channel for track a is now in a 
	
	ld b,$c0		; add $c0 for change instrument for MIDI channel in a 
	add a, b
	out (8),a  		; change instrument for channel in a 
	call short_delay
	call short_delay

	pop af 
	ld ix,instrumenttracks	; retrieve instrument for track a 
	ld c,a
	ld b,0
	add ix,bc
	ld a,(ix) 		; MIDI instrument for track a is now in a 

	out (8),a		; change MIDI instrument to a 
	call short_delay
	call short_delay
 
	ret

setmiditrackinstruments:

	ld a, 5
	call setinstrument 

	ld a, 4
	call setinstrument 
	
	ld a, 3
	call setinstrument 
	
	ld a, 2
	call setinstrument 
	
	ld a, 1
	call setinstrument 
	
	ld a, 0
	call setinstrument 

	ret
	
playnotes:
	ld a,(qtrackpos)
	
	bit 6,a
	jr nz,playhightracks ; > 64  

	ld hl,tracksoff1	
	call stoptracks

	ld a,(qtrackpos)
	ld hl,tracks1
	ld ix,tracksoff1 
	call playtracks

	ret
	
playhightracks:

	ld hl,tracksoff2
	call stoptracks

	ld a,(qtrackpos)
	ld hl,tracks2
	ld ix,tracksoff2 
	call playtracks

	ret

	
stoptracks: 
	; add track index
	; clear bit 6
	res 6,a
	ld e,a
	ld d,0
	add hl,de
	ld bc,64

	push hl
	push bc
	
	ld c,(hl) ; -> c is note off
	ld d,0
	ld e,0 ; e is track number 
	call stopnote

	pop bc
	pop hl
	
	add hl,bc

	push hl
	push bc

	ld c,(hl)
	ld d,0
	ld e,1 
	call stopnote

	pop bc
	pop hl

	add hl,bc

	push hl
	push bc
	
	ld c,(hl) 
	ld d,0
	ld e,2
	call stopnote

	pop bc
	pop hl

	add hl,bc

	push hl
	push bc

	ld c,(hl) 
	ld d,0
	ld e,3 
	call stopnote

	pop bc
	pop hl

	add hl,bc

	push hl
	push bc

	ld c,(hl) 
	ld d,0
	ld e,4 
	call stopnote

	pop bc
	pop hl
	
	add hl,bc

	push hl
	push bc

	ld c,(hl) 
	ld d,0
	ld e,5 
	call stopnote

	pop bc	
	pop hl
	
	ret
	
playtracks: 
	; add track index
	; clear bit 6
	res 6,a
	ld e,a
	ld d,0

	add hl,de
	add ix,de 
	
	ld bc,64

	push hl
	push bc
	push ix 
	
	ld c,(hl) ; -> c is note on	
	ld d,0
	ld e,0 ; e is track number 
	call playnote

	pop ix 
	pop bc
	pop hl
	
	add hl,bc
	add ix,bc

	push hl
	push bc
	push ix
	
	ld c,(hl)
	ld d,0
	ld e,1 
	call playnote

	pop ix 
	pop bc
	pop hl

	add hl,bc
	add ix,bc

	push hl	
	push bc
	push ix 
	
	ld c,(hl) 
	ld d,0
	ld e,2
	call playnote

	pop ix 
	pop bc
	pop hl

	add hl,bc
	add ix,bc

	push hl
	push bc
	push ix 

	ld c,(hl) 
	ld d,0
	ld e,3 
	call playnote

	pop ix 
	pop bc
	pop hl

	add hl,bc
	add ix,bc

	push hl
	push bc
	push ix 

	ld c,(hl) 
	ld d,0
	ld e,4 
	call playnote

	pop ix 
	pop bc
	pop hl
	
	add hl,bc
	add ix,bc

	push hl
	push bc
	push ix

	ld c,(hl) 
	ld d,0
	ld e,5 
	call playnote

	pop ix 
	pop bc	
	pop hl
	
	ret
	
	
playnote: ; input note on in c; track number 0..5 in e

        ld a, c 		; note on <> 0? no; return 
	cp DISPMIDINOTEOFFSET+1
	jr nc, playnote1

	call short_delay
	call short_delay
	ret 

playnote1:

	push bc
	push hl			; note pointer 
	
	ld hl,channeltracks 	; determine MIDI channel for track in e 
	;; ld d,0
	;; ld e,e 
	add hl, de 
	ld a,(hl) 		; MIDI channel for track in e

	add $90			; MIDI NOTE ON for MIDI channel in a 
	out (8),a

	push de
	call short_delay
	pop de

	ld a,c			; c has the note number -> MIDI out 
	sub DISPMIDINOTEOFFSET		
	out (8),a
	
	push de
	call short_delay
	pop de
	
	ld hl,gatetracks
	;; ld d,0
	;; ld e,e		; track number
	add hl, de 
	ld a,(hl)		; gate duration for track  

	pop hl 			; get note off pointer + gate duration to ... 
	push de
	
	;ld de, 12*64		; ... determine note off position in notes off grid 
	;add hl, de
	;ld d, 0
	;ld e, a
	;add hl, de

	push ix	 		; note off pointer in IX
	pop hl 			; hl <- ix
	ld d, 0
	ld e, a
	add hl, de		; add gate duration

	pop de
	pop bc 

	ld a, c			; get note number which was stored in c 
	ld (hl), a 		; store note in note off grid

	ld hl,velocitytracks 	; determine MIDI velocity for track in e  
	;; ld d,0
	;; ld e,e 
	add hl, de 
	ld a,(hl) 		; MIDI velocity for track in e 
	out (8),a
	
	ret 

stopnote: ; input note off in c; track number 0..5 in e 

        ld a, c 		; note on <> 0? no; return
	or a 
	jr nz, stopnote1
	call short_delay
	call short_delay

	ret
	
stopnote1:

	ld (hl), 0 		; hl = note pointer; erase note for now, will be rescheduled when played again!	

	push bc
	
	ld hl,channeltracks 	; determine MIDI channel for track in e 
	;; ld d,0
	;; ld e,e 
	add hl, de 
	ld a,(hl) 		; MIDI channel for track in e

	add $80			; MIDI NOTE ON for MIDI channel in a 
	out (8),a

	push de
	call short_delay
	pop de

	ld a,c			; c has the note number -> MIDI out 
	sub DISPMIDINOTEOFFSET		
	out (8),a

	push de
	call short_delay
	pop de 
	
	pop bc

	ld hl,velocitytracks 	; determine MIDI velocity for track in e  
	;; ld d,0
	;; ld e,e 
	add hl, de 
	ld a,(hl) 		; MIDI velocity for track in e 
	out (8),a
	
	ret 

showgridres:
	ld a,(gridres)
	ld c, a
	ld hl,$3c00+64+36
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e
	ret

showpat:
	ld a,(curpat)
	ld hl,$3c00+64+4
	ld (hl),a 
	ret
	

showgate:
	call gettrackgate
	ld c, a
	ld hl,$3c00+64+62
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e
	ret
	
showbars:
	ld a,(numbars)
	ld c, a
	ld hl,$3c00+64+32
	call convnibble
	ld (hl),e
	ret

long_delay:
    ld de,$1000 
delloop1: 
    dec de
    ld a,d
    or e
    jp nz,delloop1 
    ret 

short_delay:
    ld de,$003f
delloop: 
    dec de
    ld a,d
    or e
    jp nz,delloop
    ret 

	end main 

	
