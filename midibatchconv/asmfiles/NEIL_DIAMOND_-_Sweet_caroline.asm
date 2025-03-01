
 org $5200 

@DSPLY		equ	$4467
@EXIT		equ	$402d
@KBD    	equ 	$002b 
@DSP    	equ 	$0033
@KEY    	equ 	$0049 

k_Q		equ	$380402

ETX     equ 	$03 
ENTER	equ	$0d ; @DSPLY with newline
SPACE   equ 	$20 
NULL    equ 	$0 

lastbyte 	defb 	0

timer0delta	defb 	0

curcount 	defb 	0
curcounth 	defb 	0
	
midiadr 	defb 	0
midiadrh 	defb 	0     

timer0	 	defb 	0
timer	 	defb 	0
timerh	 	defb 	0


title0		defb  ENTER 
title1		defb  '*** MIDI/80 Playback from TRS-80 RAM - (C) 2024 LambdaMikel ***', ENTER
title2          defb  '    SONGNAME: NEIL_DIAMOND_-_Sweet_caroline', ENTER
title3		defb  ENTER
title4		defb  'Enter playback speed (Model 3/4 = 4, Model 1 = 6)? ', ENTER 
title5		defb  'Playing... (Q for quit)', ENTER

endm0		defb  ENTER
endm1		defb  'Thanks for listening!', ENTER
endm2		defb  ENTER
endm3		defb  'Making your own songs is easy:', ENTER
endm4 		defb  'https://github.com/lambdamikel/MIDI-80', ENTER
endm5 		defb  ENTER

dispbuf 	defb 'RAM: ',0,0,0,0,'-',0,0,0,0,ENTER 

start:

	ld hl,title0
	call @DSPLY
	ld hl,title1
	call @DSPLY
	ld hl,title2
	call @DSPLY
	ld hl,title3
	call @DSPLY

	;;  show start
	ld bc,mididata
	push bc 
	ld c,b 
	call byte2ascii
	ld hl,dispbuf+5
	ld (hl),d
	inc hl
	ld (hl),e
	inc hl
	pop bc
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e

	inc hl
	inc hl
	;;  show end
	ld bc,midiend
	push bc 
	ld c,b 
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e
	inc hl
	pop bc
	call byte2ascii
	ld (hl),d
	inc hl
	ld (hl),e

	;;  show buffer
	ld hl,dispbuf 
	call @DSPLY
	
	;;  ask for playback speed
	;; ld hl,title4
	;; call @DSPLY ; Show Enter playback speed message

	call allnotesoff

        ;; Enter a key for playback speed
	;call @KEY    
	;sub 48 ; "0" = 48

        ;; Optional use a constant value for playback speed
        ;; normal speed = 5
        ld a, 5 ; Playback speed

	ld (timer0delta), a
	ld (timer0), a

	ld hl,title5
	call @DSPLY

	;; M3 - turn off display waitstates
	;; not necessary

	;in  a,($ff)
	;or  a,$10
	;and a,~$20
	;out ($ec),a

	;; play 

	ld hl,midiadr ; write mididata start adress $6000 into pointer reg.
	ld (hl),mididata mod 256
	inc hl
	ld (hl),mididata / 256 
	ld hl,(midiadr)

	ld e,(hl) ; store first time delta into curcount 
	ld d,0
	ld (curcount),de

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
	call @EXIT
	; ret

outa:	
	ld a,(lastbyte)
outa1:
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
	
mididata equ 	$
	
	incbin 'midibin/NEIL_DIAMOND_-_Sweet_caroline0.bin'
	incbin 'midibin/NEIL_DIAMOND_-_Sweet_caroline1.bin'

endbytes	defb 	$ff, $ff, $ff

midiend equ 	$

 end start

