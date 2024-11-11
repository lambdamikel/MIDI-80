
 org $5200 

@DSPLY		equ	$4467
@EXIT		equ	$402d
@KBD    	equ 	$002b 
@KEY    	equ 	$0049 
@DSP    	equ 	$0033

TIMER0DELTA	equ 	$06

mididata	equ 	$6000 

ETX     equ 	$03 
ENTER	equ	$0d 
LF	equ	$0a  
SPACE   equ 	$20 
NULL    equ 	$0 

mode 		defb	0 ; playback or record 
lastbyte 	defb 	0

counter 	byte 	0
counterh	byte 	0

curcount 	defb 	0
curcounth 	defb 	0

midiadr 	defb 	0
midiadrh 	defb 	0     

midiend 	defb	0    
midiendh 	defb	0     

timer0	 	defb 	TIMER0DELTA
timer	 	defb 	0
timerh	 	defb 	0

sep		defb  ' ', ENTER

text0		defb  'Press <1> to record,', ENTER
text1 		defb  '      <2> for playback,', ENTER 
text2		defb  '      <x> = end record / playback,', ENTER
text3		defb  '      <q> = exit to LDOS.', ENTER
bye		defb  'Bye!', ENTER
main:

	in  a,($ff)
	or  a,$10
	and a,~$20
	out ($ec),a
	
	ld hl,counter
	ld (hl),0
	
	inc hl
	ld (hl),0   

	ld hl,midiadr ; write mididata start adress $6000 into pointer reg.
	ld (hl),mididata mod 256
	inc hl
	ld (hl),mididata / 256 
	ld hl,(midiadr)

	ld e,(hl) ; store first time delta into curcount
	inc hl
	ld d,(hl)
	ld (curcount),de

	; output menu
	
	ld hl,sep
	call @DSPLY
	ld hl,text0
	call @DSPLY
	ld hl,text1
	call @DSPLY
	ld hl,text2
	call @DSPLY
	ld hl,text3
	call @DSPLY

textdone:

; scan for input playback, record, quit  

	call @KEY     
	sub 49 ; "1" = 49, "2" = 50
	ld (mode),a
	cp 32 ; "Q" - 49 = 32 = quit 
	call z, exit 

	ld a,'!'
	call @DSP

	call next ; so we can return properly
	jp main 

next:

; scan for "X" during record

       call @KBD
       cp 0

       jr z,midiavail
       
       cp 88 ; 'X' = end record
       jr nz,midiavail

       call enddata
       ; jr main
ret    ; to 'jp main' after 'call @NEXT' 


midiavail:	

	call avail ; return from avail via 'ret'!
	cp 1
	jr z,process
	cp 2  ; 2 = end of data
	jr z,main
	jr next
	
process:
	
	call outa
	jr next     

avail:

	ld hl,(counter) ; load counter and increment 
	inc hl
	push hl
	pop de
	ld hl,counter ; store incremented counter back
	ld (hl),e
	inc hl
	ld (hl),d

	ld a,(mode)
	cp 0
	jr nz,playback 

record:

	in a,(9)
	cp 1
	jr z,stcount ; new byte available?
ret	; from call avail

stcount:
	ld hl,(midiadr) ; dereference pointer to MIDI data in RAM
	ld de,(counter)
	ld (hl),e ; store current counter to RAM 
	inc hl
	ld (hl),d 
	inc hl ; advance pointer

	in a,(8) 
	ld (hl),a ; store current MIDI DATA to RAM
	inc hl ; pointer for next record triple (counterl, counterh, byte)
	push hl ; save pointer 
	ld hl,lastbyte
	ld (hl),a ; also store last MIDI byte here
	pop de ; restore saved HL pointer to DE
	ld hl,midiadr ; now store the update (+3) pointer in midiadr
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	call clrcount ; clear the time delta counter 
	ld a,1
ret	; from call avail

playback:

	ld de,(curcount)   

; compare stored counter with current counter

  	  ld hl,(counter)
	  sbc hl,de
	  jr nz,unequal

equal:

	ld hl,(midiadr) ; load MIDI data for current block 
	inc hl
	inc hl ; advance to read MIDI data for the match
	ld a,(hl) ; read MIDI data for current block
	inc hl ; pointer points to next MIDI block, pre-load curcounter
	push hl ; save current pointer, preload counter
	ld e,(hl) 
	inc hl
	ld d,(hl)
	ld (curcount),de ; store next counter for fast access during playback
	ld hl,lastbyte
	ld (hl), a ; store MIDI byte there
	call clrcount ; clear counter for delta time tick next stored MIDI note
	pop de ; get saved pointer 
	ld hl,midiadr
	ld (hl),e ; update pointer
	inc hl
	ld (hl),d
	ld a,1 ; signal byte is available
ret	; from call avail 

unequal: 

	ld hl,$0000 ; check if end of song data     
	sbc hl,de   
	jr z,endofsong
	ld a,0 ; signal no byte available
ret	; from call avail

endofsong:
	ld a,'@' 
	call @DSP           
	ld a,2 ; signal end of song data
ret	; from call endofsong

clrcount:

	ld hl,counter
	ld (hl),0
	inc hl
	ld (hl),0  
ret	; from call clrcount

enddata:

	ld hl,(midiadr)
	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	ld (hl),00 ; doesnt matter, MIDI data is 0 
	inc hl
	ld (midiend), hl ; end of MIDI data register
	ld a,'@'
	call @DSP    
ret	; from call enddata

outa:
	ld a,(lastbyte)
	out (8),a
ret	; from call outa

exit:
	ld hl,sep
	call @DSPLY
	ld hl,bye
	call @DSPLY
	call @EXIT

	end main 
