
 org $5200 

@DSPLY		equ	$4467
@EXIT		equ	$402d
@KBD    	equ 	$002b 
@DSP    	equ 	$0033

TIMER0DELTA	equ 	$04

mididata	equ 	$6000 

ETX     equ 	$03 
ENTER	equ	$0d ; @DSPLY with newline
SPACE   equ 	$20 
NULL    equ 	$0 

lastbyte 	defb 	0

curcount 	defb 	0
curcounth 	defb 	0
	
midiadr 	defb 	0
midiadrh 	defb 	0     

timer0	 	defb 	TIMER0DELTA
timer	 	defb 	0
timerh	 	defb 	0     
	
start:	
	
	in  a,($ff)
	or  a,$10
	and a,~$20
	out ($ec),a
	
	ld hl,midiadr ; write mididata start adress $6000 into pointer reg.
	ld (hl),mididata mod 256
	inc hl
	ld (hl),mididata / 256 
	ld hl,(midiadr)

	ld e,(hl) ; store first time delta into curcount 
	ld d,0
	ld (curcount),de

next:

	call @KBD
	cp 0 ; not keypress? 
	jr z,midiavail
	cp 113 ; q = quit 
	ret z 

midiavail:	

	call avail
	cp 1
	jr z,process
	cp 2  ; 2 = end of data
	ret z
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
	
	ld a,"@"
	call @DSP 
;	pop af ; clean up stack for return...
;	ld a,2 ; signal end of song data
	;;
	call @EXIT
;	ret

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

	ld hl, timer0
	ld (hl), TIMER0DELTA
	ld hl, (timer)	
	inc hl
	ld (timer), hl
	ret 
	
	
 org $6000
	
	incbin "./MAMA.BIN"

 end start

