
	org $8000 

MySafeStack	equ $a000 	

	
;; Model I/III addresses
@fspec  equ 441ch
@init   equ 4420h
@open   equ 4424h
@close  equ 4428h
@read   equ 4436h
@write  equ 4439h
@error  equ 4409h
@abort  equ 4030h       

@DSPLY		equ	$4467
@EXIT		equ	$402d
@KBD    	equ 	$002b 
@KEY    	equ 	$0049 
@DSP    	equ 	$0033

XMEML		equ 	65	; use upper 16 KB page mode C000 - FFFF 
XMEMH		equ 	66	; use upper 16 KB page mode C000 - FFFF 

errorm:	ascii   '***** DISK ERROR! ANY KEY *****', ENTER
	
ENTER	equ	$0d ; @DSPLY with newline

lrlerr:		equ 42

filename:	ascii "SONG"
filenamenr:	ascii "?/MID", ENTER
maxpage:	defb 1

emptyline	ascii  ENTER
title1		ascii  '*** MIDI/80 X-MEM/80 PLAYBACK - (C) 2025 LambdaMikel ***', ENTER
title2		ascii  '    SONG?/MID', ENTER
title3		ascii  'Enter max. page number A...Z (SONGA/MID-SONGZ/MID): ', ENTER
title4		ascii  'Enter playback speed (Model 3/4 = 4, Model 1 = 6)? ', ENTER 

showloading	ascii  'Now loading: ', ENTER
showplaying	ascii  'Selecting: ', ENTER

endm0		ascii  ENTER
endm1		ascii  'Thanks for listening!', ENTER
endm2		ascii  ENTER
endm3		ascii  'Making your own songs is easy:', ENTER
endm4 		ascii  'https://github.com/lambdamikel/MIDI-80', ENTER
endm5 		ascii  ENTER

lastbyte 	defb 	0

timer0delta	defb 	0

curcount 	defb 	0
curcounth 	defb 	0
	
midiadr 	defb 	0
midiadrh 	defb 	0     

timer0	 	defb 	0 
timer	 	defb 	0
timerh	 	defb 	0

dcb:		defs 48			; 48 for Model III TRSDOS 1.3   
iobuf:		defs 256

main:

	di 
	ld a, 0
	out (XMEML), a
	
	ld a, 4
	out (XMEMH), a
	ei
	
	LD    SP,MySafeStack

	ld hl,title1
	call @DSPLY
	ld hl,title2
	call @DSPLY
 	ld hl,emptyline
	call @DSPLY
	ld hl,title3
	call @DSPLY

	call @KEY
	ld (maxpage), a
	call @DSP
	ld a, 'A' 
	ld (filenamenr), a

	ld hl,emptyline
	call @DSPLY

load_page:
		
	ld hl,emptyline
	call @DSPLY

	ld hl,showloading
	call @DSPLY
	
	ld hl, filename
	call @DSPLY

	call selectmempage
	call loaddisk

	ld a, (maxpage)
	ld b, a
	ld a, (filenamenr)
	cp b
	jr z, startplayback

	ld hl, filenamenr
	inc (hl)
 
	jr load_page 
	

startplayback:

	ld a, 'A' 
	ld (filenamenr), a

	call selectmempage 
	call newbank

	;;  ask for playback speed
 	ld hl,emptyline
	call @DSPLY

	ld hl,title4
	call @DSPLY

	call allnotesoff

	call @KEY    
	sub 48 ; "0" = 48

	ld (timer0delta), a
	ld (timer0), a

	;; M3 - turn off display waitstates
	;; not necessary

	;in  a,($ff)
	;or  a,$10
	;and a,~$20
	;out ($ec),a

	;; play 

	call newbank 

next:

	;ld	a,(k_Q >> 8)
	;and	k_Q % $100
	;call	nz, endofsong

	call @KBD
	cp 81 ; Q = quit 
	jp z, endofsong


midiavail:	

	call avail
	cp 1
	jr z, process
	cp 2  ; 2 = end of data
	jp z, endofsong
	jr next

	
process:
	
	call outa
	jr next     

avail:
	
	call get_timer ; get timer -> HL 
	ld de,(curcount)
	ld d,0
	sbc hl,de  
	jr c,notyet ; current ticker (HL) smaller than MIDI next counter (DE)

	ld hl,(midiadr) ; load MIDI data for current block 
	inc hl ; advance to read MIDI data for the match    
	ld b,(hl) ; read MIDI data for current block 
	inc hl ; pointer points to next MIDI block, pre-load curcounter
	ld a,h
	or l
	call z,nextbank
	push hl ; save current pointer, preload counter

	ld e,(hl) 
	ld d,0
	ld (curcount),de ; store next counter for fast access during playback
	ld a,e
	cp 255
	jr z,endofsong
	ld hl,lastbyte
	ld (hl), b ; store MIDI byte there     
	pop de ; get saved pointer	
	ld hl,midiadr
	ld (hl),e ; update pointer
	inc hl
	ld (hl),d
	ld a,1 ; signal byte is available
	ret

notyet:	

	ld a,0 ; signal no byte available
	ret

endofsong:

	ld hl,endm0
	call @DSPLY
	ld hl,endm1
	call @DSPLY
	ld hl,endm2
	call @DSPLY
	ld hl,endm3
	call @DSPLY
	ld hl,endm4
	call @DSPLY
	ld hl,endm5
	call @DSPLY

	; ld a,"@"
	; call @DSP 

	call allnotesoff
	ei
	call @EXIT
	; ret

	nextbank:
	ld a, (maxpage)
	ld b, a
	
	ld hl, filenamenr
	ld a,(hl) 

	cp b

	jp z, endofsong 
	
	inc (hl)
	call selectmempage 
	call newbank

	ret
	
outa:

	ld a,(lastbyte)
	out (8),a

	ld de,0 ; clear ticker 
	ld hl,0
	ld (timer),hl
	
	ret
	 
short_delay:
	ld de,$0090
loop: 
	dec de
	ld a,d
	or e
	jp nz,loop
	ret 

get_timer:
	ld hl, (timer)
	ld a, (timer0)
	dec a
	ld (timer0), a
	cp 0 ; zero ?
	ret nz 

	ld a, (timer0delta) 
	ld (timer0), a

	ld hl, (timer)	
	inc hl
	ld (timer), hl
	
	ret 

allnotesoff:

	;; doesn't work

	;;  Proteus mode: F0 7E 00 09 02 F7

	; ld a,$f0 
	; call outa1
	; call short_delay

	; ld a,$7e
	; call outa1
	; call short_delay

	; ld a,$00
	; call outa1
	; call short_delay

	; ld a,$09
	; call outa1
	; call short_delay

	; ld a,$02
	; call outa1
	; call short_delay

	; ld a,$f7
	; call outa1
	; call short_delay

	
	
	; ;; send all notes off: 10110000 = 176, 123, 0
	; ld a,176 ; CC 
	; call outa1
	; call short_delay

	; ld a,124 		; OMNI MODE ON also clears notes! 
	; call outa1
	; call short_delay

	; ld a,0 
	; call outa1
	; call short_delay

	; ld a,176 ; CC 
	; call outa1
	; call short_delay

	; ld a,123 		; OMNI MODE ON also clears notes! 
	; call outa1
	; call short_delay

	; ld a,0 
	; call outa1
	; call short_delay

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
	ld b, 64 		; 256 * 64 = 16384 = 16 KB /MID files 
	ld c, 0

	ld de, mididata
	
rloop:  push de

	ld de, dcb
	ld hl, iobuf 
	call @read              ; read file

	pop de
	
        ;; jr z, rok               ; got a full 256 bytes
        
        ;; ld c, a
        ;; jp diskerror          ; oops, i/o error
        ;; ret
       
rok:    ld	hl,iobuf	; source hl; de = datastart + page offset
	push bc 		; save pagecounter 
	ld	bc,256 		; # bytes to copy
	push de			; save de

	di 
	ldir 			; hl -> de / bc bytes
	ei 
	pop de			; restore de 
	pop bc			; restore pagecounter
	
	inc d			; inc. page offset 
	djnz rloop

        ld de, dcb
        call @close              ; close the TRS-80 file
        jr z, diskreadok
        
        ;; ld c, a
        ;; jp diskerror           ; oops, i/o error
        
diskreadok: ret 

diskerror:
	ld	hl,errorm
	call @DSPLY
	call @KEY
	ret

selectmempage:	
	;; select 32 KB page
	;; push af
	;; push hl
	;; push de
	;; push bc
	ld a, (filenamenr)	
 	sub 'A'
	add 4
	di
				; cause 16 KB page 0 is used for the program!
	out (XMEMH), a 		; upper 16 KB
	ei 

	;; ld hl,showplaying 
	;; call @DSPLY
	
	;; ld hl, filename
	;; call @DSPLY
	
	;; pop bc
	;; pop de 
	;; pop hl
	;; pop af
	
	ret 

newbank:
	ld hl,midiadr ; write mididata start adress &4000 into pointer reg.
	ld (hl),mididata mod 256
	inc hl  
	ld (hl),mididata / 256   
	ld hl,(midiadr) ; load first time delta from data   
	ld e,(hl) ; store first time delta into curcount    
	ld d,0   
	ld (curcount),de   

	ret

	
	org $c000
	
mididata:

	end main 

	

