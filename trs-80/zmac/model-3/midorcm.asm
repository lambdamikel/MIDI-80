;
; midorch.z - play notes on orchestra 80 as read from midi80 device.
;
; See orchan.z for theory of operation on keeping the sound updated while
; waiting for midi key off.

midstat	equ	9
middata	equ	8

	org	$8000
stack:
title:	ascii	'MIDORCH VERSION 3.'
title_len equ $-title
start:
	di
	ld	sp,stack

	ld	hl,$3c00
	ld	de,$3c00+1
	ld	bc,1024-1
	ld	(hl),' '
	ldir

	ld	hl,title
	ld	de,$3c00
	ld	bc,title_len
	ldir
	
	;in  a,($ff)
	;or  a,$10 
	;out ($ec),a	
	
	in  a,($ff)
	or  a,$10
	and a,~$20
	out ($ec),a

; Status report but already in prime registers
statusx	macro	state
	ld	(hl),state
	inc	l
	endm

; Status report
status	macro	state
	exx
	statusx	state
	exx
	endm

; Status cursor
cursor	macro
	exx
	ld	(hl),191
	exx
	endm

; Status report with extra 6 cycle delay.
status6	macro	state
	exx
	inc	de
	statusx	state
	exx
	endm

	exx
	ld	hl,$3d00
	exx

	; Wait for note on ($90) from midi.
geton:	call	dly.01
	status	'.'
	cursor
	in	a,(midstat)
	rra
	jr	nc,geton	; data not available
	in	a,(middata)	; get data
	status	a
	cp	$90
	jr	nz,geton

getnote:
	call	dly.01		; maybe delay not so necessary?
	status	'!'
	cursor
	in	a,(midstat)
	rra
	jr	nc,getnote
	in	a,(middata)
	sub	24		; can handle note 0 .. 23
	cp	27		; and only have 27 notes
	jr	nc,geton	; note   of range, start over

	ld	d,0
	ld	e,a
	ld	hl,steptab
	add	hl,de
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	b,high(sine)
	ld	hl,0

	add	a,'@'		; indicate note
	status	a

sampcyc	equ	86		; cycles per sample output

; After outputting a sample the code checks if a MIDI byte is ready.
; It not it loops back to sampout1 where 28 cycles are wasted to
; balance the loop out to 86 cycles.
; If there is a MIDI byte it gets the byte and checks for note off ($80).
; If it isn't that it loops back to sampout2 which works out to
; 86 cycles for that loop.
;
; To be friendlier to the midi80 we only check it every 0.01 seconds.

sample	macro
	add	hl,de
	ld	c,h
	ld	a,(bc)
	out	($79),a
	endm

; Output one sample and initialize our 0.01 second delay count.
	sett	0
samplp:
	sample
	exx
	ld	bc,2027520/sampcyc/10000
	exx
	status	'I'
	; waste 13
	ld	a,(0)

ti	equ	t($)
	assert	ti == sampcyc

; Output samples for 1/10000th of a second.
	sett	0
sampdly:
	sample
	exx
	statusx	'S'
	dec	bc
	ld	a,b
	or	c
	exx
	; waste 7
	ld	a,0

	jp	nz,sampdly
td	equ	t($)
	assert	td == sampcyc

; Output one sample and check for MIDI data.
	sett	0
	sample
	status6	'C'
	in	a,(midstat)
	rra
	jp	nc,samplp	; no data
tc	equ	t($)
	assert	tc == sampcyc

; Output one sample; read data byte and decide what to to.
	sett	0
	sample
	in	a,(middata)

	; Special purpose status.
	status6	a

	cp	$80		; note off command
	jp	nz,samplp
tdat	equ	t($)
	assert	tdat == sampcyc

	jp	geton		; got stop, go look for new start.

dly.01:	ld	bc,d10000th
	sett	0
dly:	dec	bc
	ld	a,b
	or	c
	jp	nz,dly
	ret
d10000th	equ	2027520 / t($) / 10000

steptab:
	octbase = 220 * 256
	hz = octbase
	nt = 0
	rept	27

	; Hz of buffer at step 1 is: (78.75 Hz)
	; 2027520 / sampcyc / 256
	; So target Hz over that is our step.
	; But we want 8.8 fixed point value.

	defw	hz / (2027520 / sampcyc / 256)

	hz *= 271 ; twelfth root 2 * 256
	hz /= 256
	nt++
	if nt == 12
		nt = 0
		octbase *= 2
		hz = octbase
	endif

	endm

	org	high($+255)*256	; 256 byte align
	include	sine.inc

	end	start
