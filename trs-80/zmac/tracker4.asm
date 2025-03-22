;; TRACKER Version 1.95
;; to do:
;; - mute tracks
;; - MIDI start/stop different trackers 
;; - MIDI sync different trackers 
;; - record NOTE OFF messages, too? (new mode with GATE = *)
;; ... 

	org $6000

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

;; Model I/III addresses
@fspec  equ 441ch
@init   equ 4420h
@open   equ 4424h
@close  equ 4428h
@read   equ 4436h
@write  equ 4439h
@error  equ 4409h
@abort  equ 4030h       

stoppeds:  equ  'H'
playings:  equ  'P'
songs: 	   equ  'S'
records:   equ  '*'
playbacks: equ  ' '
	
frees: 	  equ   'F'
trackeds: equ   'T'

dcb:		defs 48			; 48 for Model III TRSDOS 1.3   
iobuf:		defs 256
lrlerr:		equ 42
filename:	ascii  "dump", 0


ernldos:	db 1


errorm:	ascii   '***** DISK ERROR! DISK FULL / PROTECTED / NO DUMP? ANY KEY *****'

line: 	ascii	'SONG EDITOR:  USE LEFT/RIGHT, ENTER, A-Z=PATTERN, .=STOP, *=LOOP'

quitm:  ascii	'***** QUIT TRACKER - REALLY QUIT? SAVED YOUR WORK? Y/N: _  *****'

clearm: ascii	'***** CLEAR PATTERN - ARE YOU SURE? REALLY CLEAR? Y/N: _   *****'

savem:  ascii	'**** SAVE STATE - OVERWRITE EXISTING CORE DUMP FILE? Y/N: _ ****'

loadm:  ascii	'***** LOAD STATE - LOAD CORE DUMP FILE INTO MEMORY? Y/N: _ *****'

waitt:	ascii   '***** MIDI/80 TRACKER V1.95 - (C) 2024-2025 BY LAMBDAMIKEL *****'
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
	
title:	ascii   '***** MIDI/80 TRACKER V1.95 - (C) 2024-2025 BY LAMBDAMIKEL *****'
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
	ascii   'CURSOR MOVEMENT, FINE CONTROL        : A D W X, Z C             '
	ascii   'CHANGE BAR COUNT, JUMP TO BAR POS    : B, 1 2 3 4 5 6 7 8       '
	ascii   'NEXT / PREV GRID POS, CHANGE GRID    : ARROW-UP ARROW-DOWN, G   '
	ascii   'SET GRID, SOUND, CLEAR               : SPACE, ENTER, CLEAR      '
	ascii   'TOGGLE PAT/SONG PLAY / RECORD+PLAY   : P !                      '
	ascii   'ALL NOTES OFF (MIDI PANIC)           : 0                        '
	ascii   'TOGGLE RECORD, TOGGLE TRACKING       : #, T                     ' 
	ascii   'PAT +/-, PAT CLEAR, COPY, SONG EDITOR: / ?, =, ", &             '
	ascii   'HELP, QUIT, LOAD & SAVE              : H Q L S                  '
	ascii   'GLOBAL CHANGE CUR TRACK MIDI INSTR.  : U I                      '
	ascii   'PAGE CHANGE PLAYBACK SPEED           : N M , .                  '
	ascii   'PAGE CHANGE CUR TRACK MIDI CHANNEL   : + -                      '
	ascii   'PAGE CHANGE CUR TRACK MIDI VELOCITY  : J K                      '
	ascii   'PAGE CHANGE CUR TRACK DRUM, LAST MIDI: ARROW-LEFT ARROW-RIGHT, @' 
	ascii   'PAGE CHANGE CUR TRACK GATE LENGTH    : *                        '

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

running: 

	ld hl, delayc
	inc (hl)
	ld a, (hl) 
	 	
	ld b, a
	ld a, (tempo) 
	cp b
	jp nz, nostep

nextstep:
	
	;;  inc note pointer
	call nextnote
	call showplaycursor
	call playnotes

	ld a,0
	ld (delayc),a

	ld a,(track)
	or a
	jp z, nostep

tracking_enabled: 
		  
	;; tracked - set screen cursor x to playcursor x

	ld a,(trackpos)
	bit 6,a
	jr nz,trackcury ; >= 64 inc y

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

	;; cursor updates complete, now scan the keyboard
	
	jr scan 
	
nostep:
	
	;; sample keyboard during recording and MIDI

	keydown k_space 
	jr z,nostep_scan1

	ld hl, space_registered
	ld (hl), 1

nostep_scan1:

	;; sample keyboard CLEAR and queue 

	keydown k_clear
	jr z,nostep_scan2

	ld hl, clear_registered
	ld (hl), 1

nostep_scan2:

	keydown k_enter 
	jr z,nostep_scan3

	ld hl, enter_registered 
	ld (hl), 1

nostep_scan3:
	
	;; sample MIDI and queue if in RECORD mode only 

	ld a,(record)
	or a
	jr z, cur0

	call MIDIIN
	or a
	jr z, cur0

	;; MIDI available: 

	ld hl, midi_registered
	ld (hl), 1

cur0:

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
	jr nz, keyscan

	;; not in play mode; tracker is stopped: 
	;; here we only react to MIDI and keyboard input if stopped! 
	;; else we react in "nextnote" 

        ld hl, midi_registered
	ld a, (hl)
	ld (hl), 0
	or a
	jp nz,setgridandsoundmidi

        ld hl, clear_registered
	ld a, (hl)
	ld (hl), 0
	or a
	jp nz,erasegrid

        ld hl, enter_registered
	ld a, (hl)
	ld (hl), 0
	or a
	jp nz,setgridandsoundkey

        ld hl, space_registered 
	ld a, (hl)
	ld (hl), 0
	or a
	jp nz,setgridkey

keyscan:	 

	call @KBD
	or a
	jp z,loop
	
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

	cp '!' 
	jp z,startstopsong

	cp '#' 
	jp z,recordstatus

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

	cp '0'
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
	call showtempo 
	
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

	ret

getpat0:
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
	cp 'Z'+1

	jr nz, initmem1 
	
	ld hl, curpat
	ld (hl), 'A'
	
	ret 

clrpat:

	ld hl, clearm 
	call yesnoprompt
	ret nz

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
	call savestatus
	call putpat

	ld hl, curpat
	ld a, (hl)
	ld hl, topat 
	ld (hl), a 

copypat1: 

	ld hl,$3c00+64+5
	ld (hl), '<'
	inc hl
	ld (hl), '-'
	inc hl
	ld de, topat
	ld a, (de) 
	ld (hl), a
	inc hl
	ld (hl), '?'

	call @KEY
	cp ENTER
	jp z, copypat2 

	ld hl, topat
	ld (hl), a 

	jr copypat1

copypat2:

	call long_delay 
	ld hl, topat
	ld a, (hl)
	cp 'A'
	jr c, copypat1 
	cp 'Z'+1
	jr nc, copypat1

	ld b, a 
	ld a, (curpat)
	cp b
	jr z, copycleanup

	ld a, (topat)
	call getpatadr1
	push hl
	pop de 
	ld	hl,pagestart
	ld	bc,pagelen 
	ldir

copycleanup:
	call restorestatus

	jp main2  

songpage:

	;;  call stopallplayr
	call putpat

	call savestatus
	
	ld	hl,songdata 
	ld	de,$3c00+64 
	ld	bc,64 
	ldir

	ld	hl,line 
	ld	de,$3c00+128
	ld	bc,64 
	ldir

	ld hl, songcur
	ld (hl), 0

keyscan2:	 

	call @KBD

	or a
	jp z,noscansonged 

scancont2:

	cp KCURLEFT
	jp z,songcurleft

	cp KCURRIGHT
	jp z,songcurright

	cp ENTER
	jr z,quitsongeditor

	cp '*'	; loop song 
	jr z, acceptmarker

	cp '.'	; empty 
	jr z, acceptmarker

	cp 'A'
	jr c, keyscan2
	cp 'Z'+1
	jr nc, keyscan2

	ld (curpat), a
	call getpat

	ld	hl,songdata 
	ld	de,$3c00+64 
	ld	bc,64 
	ldir

acceptmarker: 
	push af 
	ld hl, $3c00+64
	ld a, (songcur)
	ld d, 0
	ld e, a
	add hl, de
	ld (hl), a

	pop af
	ld hl, songdata
	add hl, de
	ld (hl), a	

	jp keyscan2

noscansonged:
	ld a,(blink)
	inc a
	ld (blink), a

	ld hl, $3c00+64
	ld a, (songcur)
	ld d, 0
	ld e, a
	add hl, de
	
	ld a,(blink)
	cp a,127
	jr c,cur3
	ld (hl), POSMARKSYM

	jp keyscan2

cur3:
	push hl
	ld hl, songdata
	ld a, (songcur)
	ld d, 0
	ld e, a
	add hl, de
	ld a, (hl)
	pop hl
	ld (hl), a 

	jp keyscan2


quitsongeditor:
	call restorestatus

	jp cont

songcurleft:
	ld a, (songcur)
	or a 
	jp z, keyscan2
	dec a
	ld (songcur), a
		
	ld	hl,songdata 
	ld	de,$3c00+64 
	ld	bc,64 
	ldir
	
	jp keyscan2

songcurright:
	ld a, (songcur)
	cp 63 
	jp nc, keyscan2
	inc a
	ld (songcur), a
		
	ld	hl,songdata 
	ld	de,$3c00+64 
	ld	bc,64 
	ldir

	jp keyscan2

restorestatus:
	ld	de, $3c00+64 
	ld 	hl, statusbuffer
	ld 	bc, 2*64
	ldir
	ret

savestatus:
	ld	hl, $3c00+64 
	ld 	de, statusbuffer
	ld 	bc, 2*64
	ldir
	ret 
	
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
	cp 8
	jr nz, chgnumbars1
	ld a, 0 
chgnumbars1:
	inc a 
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
	call putpat

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
	call putpat

	ld hl, loadm  
	call yesnoprompt
	jp nz, cont 
	call loaddisk
	jp cont 

save:
	call putpat

	ld hl, savem  
	call yesnoprompt
	jp nz, cont 
	call savedisk 
	jp cont 
	
quit:
	call putpat

	ld hl, quitm 
	call yesnoprompt
	jp nz, cont 
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

	ld a,(status)
	cp 1 ; pattern play mode?
	jr nz, bar1a

	;; else, change the current pattern to A after current bar
	ld a, 'A' 
	ld (nextpat), a
	jp cont 

bar1a:

	ld a,0
	setbar1x 
	
bar2:

	ld a,(status)
	cp 1 ; pattern play mode?
	jr nz, bar2a

	;; else, change the current pattern to B after current bar
	ld a, 'B' 
	ld (nextpat), a
	jp cont
	
bar2a: 
	ld a,16
	setbar1x 

bar3:
	ld a,(status)
	cp 1 ; pattern play mode?
	jr nz, bar3a

	;; else, change the current pattern to B after current bar
	ld a, 'C' 
	ld (nextpat), a
	jp cont

bar3a: 
	ld a,32
	setbar1x 

bar4:
	ld a,(status)
	cp 1 ; pattern play mode?
	jr nz, bar4a

	;; else, change the current pattern to B after current bar
	ld a, 'C' 
	ld (nextpat), a
	jp cont


bar4a:
	ld a,48
	setbar1x 

bar5:
	ld a,(status)
	cp 1 ; pattern play mode?
	jr nz, bar5a

	;; else, change the current pattern to B after current bar
	ld a, 'D'  
	ld (nextpat), a
	jp cont


bar5a:
	ld a,0
	setbar2x 

bar6:

	ld a,(status)
	cp 1 ; pattern play mode?
	jr nz, bar6a

	;; else, change the current pattern to B after current bar
	ld a, 'E' 
	ld (nextpat), a
	jp cont

bar6a:
	ld a,16
	setbar2x
	
bar7:
	ld a,(status)
	cp 1 ; pattern play mode?
	jr nz, bar7a

	;; else, change the current pattern to B after current bar
	ld a, 'F' 
	ld (nextpat), a
	jp cont

bar7a:
	ld a,32
	setbar2x
	
bar8:

	ld a,(status)
	cp 1 ; pattern play mode?
	jr nz, bar8a

	;; else, change the current pattern to B after current bar
	ld a, 'G' 
	ld (nextpat), a
	jp cont

bar8a: 
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

testsoundx macro n 
	;; first, turn of previously played note
	;; ONLY if in record mode!

	call gettrackchannel
	ld b, a

	ld a,(record)
	or a
	jr z, playnoteon_&n

	;; turn off currently held note

	ld a, b
	add $80 
	out (8),a
  
	call short_delay
	ld a,(lastcurnote)
	out (8),a
  
	call short_delay
	ld a,(lastcurvelocity)
	out (8),a

	call short_delay
	call short_delay

playnoteon_&n:

	ld a, b
	add $90 
	out (8),a
  
	call short_delay
	ld a,(curnote)
	out (8),a
	ld (lastcurnote), a
  
	call short_delay
	ld a,(curvelocity)
	out (8),a
	ld (lastcurvelocity), a

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

	testsoundx 1
	setgridx 

	jp cont 

setgridandsoundkey:
	
	call gettrackdrum
	ld (curnote), a 

	call gettrackvelocity
	ld (curvelocity), a  

	testsoundx 2
	setgridx 

	jp cont 

setgridandsoundr:
	
	testsoundx 3
	setgridx 

	ret

setgridandsoundkeyr:
	
	call gettrackdrum
	ld (curnote), a 

	call gettrackvelocity
	ld (curvelocity), a  

	testsoundx 4
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

stopallplayr:
	ld a, 0 
	ld (status), a
	ret

startstop:
	ld a,(status)
	xor 1
	and 1 
	ld (status), a
	or a
	jr nz, showplay

showstartstop:
	ld hl,$3c00 + 64 + 6
	ld a,stoppeds
	ld (hl), a
	jp cont
	
showplay:

	;; store current pattern in case user modified it before switching
	call putpat

	ld hl, qtrackpos
	ld (hl), 0
	
	call midipanicr
	call long_delay

	call setmiditrackinstruments
	call long_delay

	ld hl,$3c00 + 64 + 6
	ld a, playings 
	ld (hl), a
	
	call playnotes

	jp cont 


startstopsong:
	ld a,(status)
	xor 2
	and 2
	ld (status), a
	or a
	jr nz, showplaysong
	jr showstartstop

getsongpat:
	
	ld hl, songdata 	; load song pattern at song index pos 
	ld a, (songpos)
	ld d, 0
	ld e, a
	add hl, de
	ld a, (hl) 		; a has pattern

	cp '.' 			; empty? stop
	jr z, stopsong 

	cp '*' 			; repeat?
	jr z, repeatsong

	cp 'A'
	ret c 
	cp 'Z'+1
	ret nc

	;; load next patter from song 
	ld hl, curpat		
	ld (hl), a

	call getpat0 
	
	ret

repeatsong:
	ld hl, songpos
	ld (hl), 0
	jr getsongpat 

stopsong:

	ld hl, status
	ld (hl), 0
	ld hl,$3c00 + 64 + 6
	ld a,stoppeds
	ld (hl), a

	ret

contsong:	 

	
showplaysong:
	
	;; store current pattern in case user modified it before switching
	call putpat

	ld hl, songpos
	ld (hl), 0
	call getsongpat

	ld hl, qtrackpos
	ld (hl), 0
	
	call midipanicr
	call long_delay

	call setmiditrackinstruments
	call long_delay

	ld hl,$3c00 + 64 + 6
	ld a, songs
	ld (hl), a
	
	call playnotes

	jp cont 



recordstatus:
	ld a,(record)
	xor 1
	ld (record), a
	or a
	jr nz, showrecordstatus
	
	ld hl,$3c00 + 64 + 8
	ld a, playbacks 
	ld (hl), a
	
	jp cont
	
showrecordstatus:	
	ld hl,$3c00 + 64 + 8
	ld a, records
	ld (hl), a
	
	jp cont 


trackstatus:
	ld a,(track)
	xor 1
	ld (track), a
	or a
	jr nz, showtrackstatus
	
	ld hl,$3c00 + 64 + 7
	ld a, frees
	ld (hl), a
	
	jp cont
	
showtrackstatus:	
	ld hl,$3c00 + 64 + 7
	ld a, trackeds
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
	;;ld a,(blink)
	;;inc a
	;;ld (blink),a
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
	
	jr nz,nextnotew

	;; page end - 
	;; check if song mode?

	ld a, (status)
	cp 2

	jr nz, nosongmode

	;;  in song mode, load next patter from song

	;; store current pattern in case user modified it before switching

	ld a, (record)
	or a 

	call nz, putpat 	; only store if recording active (optimization to prevent lag during playback)

	ld hl, songpos
	inc (hl) 
	call getsongpat

	call screenupdate	
	call showpat
	call showtempo 
	call showgridres
	call showbars
	
	;;call showtrack
	;;call showtrackdrum
	;;call showtrackchannel
	;;call showtrackinstrument
	;;call showtrackvelocity 
	;;call showgridres
	;;call showbars
	;;call showgate

nosongmode:	 

	;; max tick number reached, set to 0

	ld a, 0
	jr nextnote0

nextnotew:

	;; no song-based page switch, check for requested page switch
	ld b, a 
	ld a, (nextpat)
	or a
	ld a, b
	jr z, nextnotecontpat ; no requested pattern switch

	;; else, switch to requested pattern at end of current bar

	ld a, (qtrackpos)
	inc a
	and 00001111b
	or a
	jr nz, nextnotecontpat

	;; else, switch in requested next pattern

	ld hl, curpat
	ld a, (nextpat) 
	ld (hl), a
	call getpat0 
	call screenupdate	
	call showpat
	call showtempo 
	call showgridres
	call showbars

	ld a, 0 
	ld (nextpat), a 

	jr nextnote0 
	

nextnotecontpat:

 	;; next note, no page switch
	ld a, (qtrackpos)
	inc a

	push af 
	ld hl, 16800
	call wHL
	pop af
	
nextnote0:

	;; update cursors, quantize tracking cursor
	
	ld (qtrackpos),a

	ld b, a
	ld a, (quantpat)
	and b
	ld (trackpos),a
	

nextnote_continue:

	ld a, (qtrackpos)
	ld b, a
	ld a, (trackpos)

	cp b
	jr nz, nextnote2

	ld a, (record)		; don't sample if not in record mode 
	or a
	jr z, nextnote2

	;; check registered keypresses and
	;; take action when (qtrackpos) = (trackpos) 


nextnote_check_registered: 

        ld hl, clear_registered
	ld a, (hl)
	ld (hl), 0
	or a
	call nz,erasegridr 	

        ld hl, enter_registered
	ld a, (hl)
	ld (hl), 0
	or a
	call nz,setgridandsoundkeyr 

        ld hl, space_registered 
	ld a, (hl)
	ld (hl), 0
	or a
	call nz,setgridkeyr

        ld hl, midi_registered
	ld a, (hl)
	ld (hl), 0
	or a
	call nz,setgridandsoundr 


nextnote2:
	
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

	pop af 
	ld ix,instrumenttracks	; retrieve instrument for track a 
	ld c,a
	ld b,0
	add ix,bc
	ld a,(ix) 		; MIDI instrument for track a is now in a 

	out (8),a		; change MIDI instrument to a 
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
	jr nz,playhightracks ; >= 64  

playlowtracks:

	ld hl,tracksoff1	
	call stoptracks

	ld a,(qtrackpos)
	ld hl,tracks1
	
	ld ix,tracksoff1
	ld iy,tracksoff2

	call playtracks

	ret
	
playhightracks:

	ld hl,tracksoff2
	call stoptracks

	ld a,(qtrackpos)
	ld hl,tracks2

	ld ix,tracksoff1
	ld iy,tracksoff2

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

	push hl
	push ix
	push iy
	
	ld d,0
	ld e,0 ; e is track number 
	call playnote

	pop iy 
	pop ix 
	pop hl
	
	ld bc,64
	add hl,bc
	add ix,bc
	add iy,bc

	push hl
	push ix
	push iy 
	
	ld d,0
	ld e,1 
	call playnote

	pop iy
	pop ix 
	pop hl
	
	ld bc,64
	add hl,bc
	add ix,bc
	add iy,bc

	push hl	
	push ix 
	push iy 
	
	ld d,0
	ld e,2
	call playnote

	pop iy 
	pop ix 
	pop hl

	ld bc,64
	add hl,bc
	add ix,bc
	add iy,bc

	push hl
	push ix
	push iy

	ld d,0
	ld e,3 
	call playnote

	pop iy 
	pop ix 
	pop hl

	ld bc,64
	add hl,bc
	add ix,bc
	add iy,bc

	push hl
	push ix 
	push iy 
	
	ld d,0
	ld e,4 
	call playnote

	pop iy 
	pop ix 
	pop hl
	
	ld bc,64
	add hl,bc
	add ix,bc
	add iy,bc

	push hl
	push ix
	push iy 
	
	ld d,0
	ld e,5 
	call playnote

	pop iy 
	pop ix 
	pop hl
	
	ret
	
	
playnote: ; input note on in c; track number 0..5 in e; hl track start, ix note of track start 

	ld a, (qtrackpos)	; add note index offset
	res 6, a		; reset high tracks bit 

	ld b, a			; save note index to b 

	push de			; save track number in e 
	ld d, 0			; compute note pointer 
	ld e, a
	add hl, de
	pop de 
	
        ld a, (hl) 		; get note; note on, <> 0? no -> return 
	cp DISPMIDINOTEOFFSET+1
	jr nc, playnote1

	;; else, waste some time!

	call short_delay
	call short_delay

	ret 

playnote1:

	; note index in b, note to play in a,
	; e track number, hl note pointer,
	; ix start of note off low  tracks
	; iy start of note off high tracks

	push	af	        ; save note in a	
	
	ld hl,channeltracks 	; determine MIDI channel for track in e 
	add hl, de 
	ld a,(hl) 		; MIDI channel for track  

	add $90			; MIDI NOTE ON for MIDI channel in a 
	out (8),a

	push de			; protect track number in e 
	call short_delay
	pop de

	pop af			; output note number
	push af			
	sub DISPMIDINOTEOFFSET		
	out (8), a
	
	push de			; protect track number in e 
	call short_delay
	pop de

	ld hl,velocitytracks 	; determine MIDI velocity for track in e  
	add hl, de 
	ld a,(hl) 		; MIDI velocity for track in e 
	out (8),a

	;; compute and set note off in noteoff tracks 

	ld hl,gatetracks
	add hl, de 		; gate duration index 
	ld c, (hl)		; gate duration for track 	

	ld a, (qtrackpos) 	; load note index, with bit 6 set if >= 64
	add c 			; add gate duration 
	
	ld hl, numticks
	ld c, (hl)
	cp c			; a > numticks? wrap around! use iy as basis 
	jr c, nowrap

	; else, we need to wrap around, sub 64; c has note position + gate duration offset
	; a has numticks 

	sub c

nowrap: ; a has note position + gate duration offset, wrapped around - check if high or low tracks 

	bit 6,a
	jr nz, storenoteoffhigh  ; >= 64, high off tracks
	
	bit 7,a
	jr nz, storenoteoffhigh2  ; >= 128, low off tracks

storenoteofflow:

	push ix	 ; low off tracks 
	pop hl

	jr storenoteoff
	
storenoteoffhigh:

	res 6,a	; -> low tracks 

	push iy  ; high off tracks 
	pop hl

	jr storenoteoff

storenoteoffhigh2:

	res 7,a	; -> low tracks (wrap around at end track 6, > 127!) 

	push ix  ; low off tracks 
	pop hl

	jr storenoteoff

storenoteoff: 

	ld d, 0
	ld e, a
	add hl, de		; hl has high or low note pos in off tracks 

	pop af			; restore note to play / turn off
	ld (hl), a 		; store note in note off grid

	ret 


stopnote: ; input note off in c; track number 0..5 in e 

        ld a, c 		; note on <> 0? no; return
	or a 
	jr nz, stopnote1

	;; else, waste some time!

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

	add $80			; MIDI NOTE OFF for MIDI channel in a 
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

cost1   equ     t($)-t(stopnote1)

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
    ld de,$0020
delloop: 
    dec de
    ld a,d
    or e
    jp nz,delloop
    ret 

loaddisk:

	ld hl, filename
	
	ld de, dcb              ; ready to get TRS-80 filename from (HL)
        call @fspec
        jp nz, diskerror 
        
	ld hl, iobuf
        ld de, dcb
        ld b, 0
        call @open               ; open the file
        jr z, readfile
        
        ld c, a                  ; error code 
        jp diskerror
        
readfile:

        ; call getern
	ld b, 88
	ld c, 0

	ld de, datastart
	
rloop:  push de

	ld de, dcb
	ld hl, iobuf 
	call @read              ; read file

	pop de
	
        jr z, rok               ; got a full 256 bytes
        
        ld c, a
        jp diskerror          ; oops, i/o error
        ret
       
rok:    ld	hl,iobuf	; source hl; de = datastart + page offset
	push bc 		; save pagecounter 
	ld	bc,256 		; # bytes to copy
	push de			; save de 
	ldir 			; hl -> de / bc bytes
	pop de			; restore de 
	pop bc			; restore pagecounter
	
	inc d			; inc. page offset 
	djnz rloop

        ld de, dcb
        call @close              ; close the TRS-80 file
        jr z, diskreadok
        
        ld c, a
        jp diskerror           ; oops, i/o error
        
diskreadok: ret 

	
savedisk:

        ld hl, filename 

	ld de, dcb              ; ready to get TRS-80 filename from (HL)
        call @fspec
        jp nz, diskerror 

	ld hl, datastart
        ld de, dcb
        ld b, 0
        call @init               ; open the file
        jr z, writefile
	
        ld c, a                  ; error code 
        jp diskerror
        ret 
        
writefile:

        ld hl, datastart 
        ld de, dcb
        ld bc, datalength
	inc b
	
wloop:	ld (dcb+3), hl
        call @write             ; write 256 bytes to file
        jr z, wrok
        ld c, a
        jp diskerror          ; oops, i/o error
	ret
        
wrok:   inc h
	djnz wloop		; write next block unitl b = 0; remainder in c 

	ld a, c			; remainder of last record 
        ld (dcb+8), a
	
	;; ld (dcb+3), hl
        call setern             ; set ERN (in case shortening file)
	
        ld de, dcb
        call @close              ; close the TRS-80 file
        jr z, disksaveok

	ld c, a
        jp diskerror              ; oops, i/o error
	ret
        
disksaveok: ret

diskerror:
	ld	hl,errorm 
	ld	de,$3c00+64
	ld	bc,64
	ldir
	call @KEY
	call restorestatus
	ret

yesnoprompt:
	push hl 
	call savestatus
	pop hl
	ld	de,$3c00+64
	ld	bc,64
	ldir
	call @KEY
	cp 'Y'
	call restorestatus
	ret
;;
;; setern by Frederic Vecoven and Tim Mann
;; https://github.com/veco/FreHDv1/blob/main/sw/z80/utils/import2.z80
;;

;; EOF handling differs between TRS-80 DOSes:
;;  For TRSDOS 2.3 and LDOS, word (dcb+12) contains the number of
;;  256 byte records in the file, byte (dcb+8) contains the EOF
;;  offset in the last record (0=256).
;;  For NEWDOS/80 and TRSDOS 1.3, byte (dcb+8) and word (dcb+12) 
;;  form a 24 bit number containing the relative byte address of EOF.
;;  Thus (dcb+12) differs by one if the file length is not a
;;  multiple of 256 bytes.  DOSPLUS also uses this convention,
;;  and NEWDOS 2.1 probably does too (not checked).

; Set ending record number of file to current position
; EOF offset in C; destroys A, HL
setern:
	ld hl, (dcb+10)		; current record number
	ld a, (ernldos)         ; get ERN convention
	or a
	jr nz, noadj            ; go if TRSDOS 2.3/LDOS convention
adj:	or c			; length multiple of 256 bytes?
	jr z, noadj             ; go if so
	dec hl			; no, # of records - 1
noadj:	ld (dcb+12), hl
	ret	
;;
;; getern by Frederic Vecoven and Tim Mann
;; https://github.com/veco/FreHDv1/blob/main/sw/z80/utils/export2.z80
;;

;; EOF handling differs between TRS-80 DOSes:
;;  For TRSDOS 2.3 and LDOS, word (dcb+12) contains the number of
;;  256 byte records in the file, byte (dcb+8) contains the EOF
;;  offset in the last record (0=256).
;;  For NEWDOS/80 and TRSDOS 1.3, byte (dcb+8) and word (dcb+12) 
;;  form a 24 bit number containing the relative byte address of EOF.
;;  Thus (dcb+12) differs by one if the file length is not a
;;  multiple of 256 bytes.  DOSPLUS also uses this convention,
;;  and NEWDOS 2.1 probably does too (not checked).

; Returns number of (partial or full) records in BC, destroys A
getern:
        ld bc, (dcb+12)
        ld a, (ernldos)         ; get ERN convention
        and a
        ret nz                  ; done if TRSDOS 2.3/LDOS convention
        ld a, (dcb+8)           ; length multiple of 256 bytes?
        and a
        ret z                   ; done if so
        inc bc                  ; no, # of records = last full record + 1
        ret     


;; 
;; Cycle Wasting Routines by G. Phillips 
;; http://48k.ca/beamhack3.html
;;

; wHL -- Waste HL + 100 T states. Only uses A, HL.

wHL256:
        dec     h               ;<0>  | <4>
        ld      a,256-4-4-12-4-7-17-81       ; 81 is wA overhead
                                ;<0>  | <7>
        call    wA              ;<0>  | <17+A>
wHL:    inc     h               ;<4>  | <4>
        dec     h               ;<4>  | <4>
        jr      nz,wHL256       ;<7>  | <12>
        ld      a,l             ;<4>
wA:     rrca                    ;<4>
        jr      c,wHL_0s        ;<7>  | <12> 1 extra cycle if bit 0 set
        nop                     ;<4>  | <0>
wHL_0s: rrca                    ;<4>
        jr      nc,wHL_1c       ;<12> | <7>  2 extra cycles if bit 1 set
        jr      nc,wHL_1c       ;<0>  | <7>
wHL_1c: rrca                    ;<4>
        jr      nc,wHL_2c       ;<12> | <7>  4 extra cycles if bit 2 set
        ret     nc              ;<0>  | <5>
        nop                     ;<0>  | <4>
wHL_2c: rrca                    ;<4>
        jr      nc,wHL_3c       ;<12> | <7>  8 extra cycles if bit 3 set
        ld      (0),a           ;<0>  | <13>
wHL_3c: and     a,0fh           ;<7>
        ret     z               ;<11> | <5>  done if no other bits set
wHL_16: dec     a               ;<0>  | <4>  loop away 16 for remaining count
        jr      nz,wHL_16       ;<0>  | <12>
        ret     z               ;<0>  | <11>
; Last jr was 7, but the extra 5 from "ret z" keeps us at 16 * A.
; The "ret z" cost balances the previous "ret z" in the 0 case.

;;
;; data region 
;; 
	
	org $8000

datastart

startmarker 	ascii 'START-OF-FILE-MARKER'

statusbuffer		defs	2*64

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
record  byte    0

trackpos   byte  0
qtrackpos  byte  0

midicount         byte  0
curnote           byte  0
curvelocity       byte  0
lastcurnote       byte  0
lastcurvelocity   byte  0

clear_registered byte 0 
space_registered byte 0 
enter_registered byte 0 
midi_registered  byte 0 

tracksoff1 	defs    6*64 		
tracksoff2 	defs    6*64

; there is some bug in the code from tracksoff that messes with the songdata! double check at some point... for now, put a hack in here to protect song data:

buffer 	defs    64	

songdata	ascii	'A...............................................................'
songcur		byte 	0
songpos		byte 	0

curpat		ascii   'A'
topat		ascii   'A'
nextpat		byte	 0 

;; page-specific variables


pagestart

delayc 	byte	0
tempo   byte	$2a
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

pages		defs 26*pagelen	; pages A-Z

endmarker 	ascii 'END-OF-FILE-MARKER'

dataend 	equ $
datalength 	equ $-datastart

	
	end main 

	
