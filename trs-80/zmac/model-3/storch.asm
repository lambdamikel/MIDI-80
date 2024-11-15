;
; storch.z - stereo orchestra 85 organ
;
; Upper two keyboard rows are the right channel:
;     _____ _____       _____ _____ _____       _____ _____
;    | c'# | d'# |     | f'# | g'# | a'# |     | c''#| d''#|
;  __|__2__|__3__|_____|__5__|__6__|__7__|_____|__9__|__0__|__ _____
; |  c' |  d' |  e' |  f' |  g' |  a' |  b' | c'' | d'' | e'' | f'' |
; |__Q__|__W__|__E__|__R__|__T__|__Y__|__U__|__I__|__O__|__P__|__@__|
;
; 1 switches right channel waveform (sine, square, triangle, saw)
;
; Lower two keyboard rows are the left channel:
;     _____ _____       _____ _____ _____       _____ _____
;    |  c# |  d# |     |  f# |  g# |  a# |     | c'# | d'# |
;  __|__S__|__D__|_____|__G__|__H__|__J__|_____|__L__|__;__|__ _____
; |  c  |  d  |  e  |  f  |  g  |  a  |  b  | c'  | d'  | e'  | f'  |
; |__Z__|__X__|__C__|__V__|__B__|__N__|__M__|__,__|__.__|__.__|__/__|
;
; A switches left channel waveform (sine, square, triangle, saw)
;
; Current sample output rate is 13,440 Hz on each channel (2027520 / sampcyc).

	org	$8000
stack:
start:
	di
	ld	sp,stack

	ld	hl,$3c00
	ld	de,$3c00+1
	ld	bc,1024-1
	ld	(hl),' '
	ldir

	in  a,($ff)
	or  a,$10
	and a,~($20 | $40) ; disable video wait states M3, and SLOW mode M4
	out ($ec),a

sampcyc	equ	132

defstep	macro	n,stp
step_&n	equ	stp
	endm

; Get the step value for 32 notes as step_0 .. step_31

	octbase = 110 * 256
	hz = octbase
	nt = 0
	rept	32

	; Hz of buffer at step 1 is: (78.75 Hz)
	; 2027520 / sampcyc / 256
	; So target Hz over that is our step.
	; But we want 8.8 fixed point value.

	defstep	%nt,hz/(2027520/sampcyc/256)

	hz *= 271 ; twelfth root 2 * 256
	hz /= 256
	nt++
	if nt % 12 == 0
		octbase *= 2
		hz = octbase
	endif

	endm

; Define these sensibly

st_c0	equ	step_0
st_c0@	equ	step_1
st_d0	equ	step_2
st_d0@	equ	step_3
st_e0	equ	step_4
st_f0	equ	step_5
st_f0@	equ	step_6
st_g0	equ	step_7
st_g0@	equ	step_8
st_a0	equ	step_9
st_a0@	equ	step_10
st_b0	equ	step_11

st_c1	equ	step_12
st_c1@	equ	step_13
st_d1	equ	step_14
st_d1@	equ	step_15
st_e1	equ	step_16
st_f1	equ	step_17
st_f1@	equ	step_18
st_g1	equ	step_19
st_g1@	equ	step_20
st_a1	equ	step_21
st_a1@	equ	step_22
st_b1	equ	step_23

st_c2	equ	step_24
st_c2@	equ	step_25
st_d2	equ	step_26
st_d2@	equ	step_27
st_e2	equ	step_28
st_f2	equ	step_29

dac_l	equ	$79
dac_r	equ	$75

samp_l	macro
	add	hl,de
	ld	c,h
	ld	a,(bc)
	out	(dac_l),a
	endm

samp_r	macro
	exx
	add	hl,de
	ld	c,h
	ld	a,(bc)
	out	(dac_r),a
	exx
	endm

; samp_r but leaves us in prime registers
samp_r_prime macro
	exx
	add	hl,de
	ld	c,h
	ld	a,(bc)
	out	(dac_r),a
	endm

start_cycle macro
diff	defl	sampcyc-t($)
	assert	t($) == sampcyc
	sett	0
	endm

; Check we're at the correct amount for left sample
check_l	macro
ldiff	defl	33-t($)
	assert	t($) == 11+4+7+11 ; cycles used in samp_l
	endm

; Check we're at the correct amount for right sample
; I suppose this is unnecessary since you can do whatever you
; like with the rest of the sample time.
check_r	macro
rdiff	defl	74-t($)
	assert	t($) == 74 ; cycles used in samp_l and samp_r
	endm

cycle	macro
	start_cycle
	samp_l
	samp_r
	endm

key	macro	addrmask,st,down
	cycle
	ld	iy,st
	; Waste 7
	ld	a,0
	ld	a,(addrmask >> 8)
	and	addrmask % $100
	call	nz,down
	ld	a,0		; careful balance
	endm

key_l	macro	addrmask,st
	key	addrmask,st,down_l
	endm

key_r	macro	addrmask,st
	key	addrmask,st,down_r
	endm

	exx
	ld	b,high(silence)
	exx
	ld	b,high(silence)

; Model 1 keyboard matrix.
;        1   2   4   8  16  32  64  128
; $3801	 @   A   B   C   D   E   F   G
; $3802	 H   I   J   K   L   M   N   O
; $3804	 P   Q   R   S   T   U   V   W
; $3808	 X   Y   Z
; $3810	 0   1   2   3   4   5   6   7
; $3820	 8   9   :   ;   ,   -   .   /
; $3840	ENT CLR BRK UP   DN  LT  RT SPC
; $3880	SFT

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

	sett	sampcyc		; hack to let first cycle pass
main:	
	key_l	k_Z,st_c0
	key_l	k_S,st_c0@
	key_l	k_X,st_d0
	key_l	k_D,st_d0@
	key_l	k_C,st_e0
	key_l	k_V,st_f0
	key_l	k_G,st_f0@
	key_l	k_B,st_g0
	key_l	k_H,st_g0@
	key_l	k_N,st_a0
	key_l	k_J,st_a0@
	key_l	k_M,st_b0
	key_l	k_comma,st_c1
	key_l	k_L,st_c1@
	key_l	k_dot,st_d1
	key_l	k_semi,st_d1@
	key_l	k_slash,st_e1

	key_r	k_Q,st_c1
	key_r	k_2,st_c1@
	key_r	k_W,st_d1
	key_r	k_3,st_d1@
	key_r	k_E,st_e1
	key_r	k_R,st_f1
	key_r	k_5,st_f1@
	key_r	k_T,st_g1
	key_r	k_6,st_g1@
	key_r	k_Y,st_a1
	key_r	k_7,st_a1@
	key_r	k_U,st_b1
	key_r	k_I,st_c2
	key_r	k_9,st_c2@
	key_r	k_O,st_d2
	key_r	k_0,st_d2@
	key_r	k_P,st_e2
	key_r	k_@,st_f2

	key	k_A,0,wave_down_l
	key	k_1,0,wave_down_r

	cycle

	; waste 48
	jp	$+3
	jp	$+3
	jp	$+3
	jp	$+3
	nop
	nop

	jp	main

; In the simple case a key goes down, it self modifies so that when it goes
; up it turns off the audio for that channel.  But if a key goes down and
; then another does then that first one should not key off the sound.  How
; can it know?  On key down we need to set the key up handler to reset the
; call but not stop the audio.

call_nz	equ	$C4
call_z	equ	$CC

; Handle note key down on left channel.
; IY is new Hz step for DE.
down_l:
	start_cycle
	push	iy
	pop	de
	nop
	nop
	check_l
	samp_r

	ld	b,high(sine)
wf_l	equ	$-1
	pop	iy		; to self-modify key-down check
	ld	(iy-3),call_z
	; waste 4
	ld	ix,3		; active down key
	org	$-2
active_l:	defw	3
	nop

	cycle
	; Adjust active first in case it is us.
	ld	(ix-2),low(old_up_l)
	ld	(ix-1),high(old_up_l)
	ld	(active_l),iy	; we're the one to stop

	cycle
	ld	(iy-2),low(up_l)
	ld	(iy-1),high(up_l)	; previous will not stop audio
	; waste 12
	jr	$+2
; XXX - return balance is a bit off as it'll hit 7 cycles
	jp	(iy)		; return to main key scan loop

up_l:
	start_cycle
	ld	b,high(silence)	; back to quiet
	pop	iy
	; waste 12
	nop
	nop
	nop
	check_l
	samp_r

	ld	(iy-3),call_nz
	ld	(iy-2),low(down_l)
	; waste 20
	jp	$+3
	jp	$+3

	start_cycle
	ld	(iy-1),high(down_l)
	; waste 14
	nop
	jp	$+3
	check_l
	samp_r
	; audio is off so active no longer matters
	ld	ix,3
	ld	(active_l),ix

	; waste 16
	nop
	nop
	nop
	nop

	endm

; XXX - return balance is a bit off as it'll hit 7 cycles
	jp	(iy)		; return

; A key has gone up but it is no longer in charge of the note.
old_up_l:
	cycle
	pop	iy
	ld	(iy-3),call_nz
	; waste 25
	jp	$+3
	nop
	nop
	ld	a,0

	cycle
	ld	(iy-1),high(down_l)
	ld	(iy-2),low(down_l)
	; waste 12
	jr	$+2
; XXX - return balance is a bit off as it'll hit 7 cycles
	jp	(iy)		; return


; Handle note key down on right channel.
; IY is new Hz step for DE.
down_r:
	start_cycle
	samp_l
	exx
	push	iy
	pop	de
	ld	b,high(sine)
wf_r	equ	$-1
	exx
	pop	iy		; to self-modify key-down check
	ld	(iy-3),call_z
	ld	ix,3		; active down key
	org	$-2
active_r:	defw	3
	; waste 12
	jr	$+2

	cycle
	; Adjust active first in case it is us.
	ld	(ix-2),low(old_up_r)
	ld	(ix-1),high(old_up_r)
	ld	(active_r),iy	; we're the one to stop

	cycle
	ld	(iy-2),low(up_r)
	ld	(iy-1),high(up_r)	; previous will not stop audio
	; waste 12
	jr	$+2
; XXX - return balance is a bit off as it'll hit 7 cycles
	jp	(iy)		; return to main key scan loop

up_r:
	start_cycle
	samp_l
	exx
	ld	b,high(silence)	; back to quiet
	exx
	pop	iy
	; waste 12
	nop
	nop
	nop
	check_r

	ld	(iy-3),call_nz
	ld	(iy-2),low(down_r)
	; waste 20
	jp	$+3
	jp	$+3

	start_cycle
	samp_l
	ld	(iy-1),high(down_r)
	; waste 22
	nop
	nop
	nop
	jp	$+3
	check_r
	; audio is off so active no longer matters
	ld	ix,3
	ld	(active_r),ix

	; waste 16
	nop
	nop
	nop
	nop

	endm

; XXX - return balance is a bit off as it'll hit 7 cycles
	jp	(iy)		; return

; A key has gone up but it is no longer in charge of the note.
old_up_r:
	cycle
	pop	iy
	ld	(iy-3),call_nz
	; waste 25
	jp	$+3
	nop
	nop
	ld	a,0

	cycle
	ld	(iy-1),high(down_r)
	ld	(iy-2),low(down_r)
	; waste 12
	jr	$+2
; XXX - return balance is a bit off as it'll hit 7 cycles
	jp	(iy)		; return

wave_down_l:
	cycle
	ld	a,(wf_l)
	inc	a
	and	3
	or	high(sine)
	ld	(wf_l),a
	pop	iy
	; lucky balance!

	cycle
	ld	(iy-1),high(wave_up_l)
	ld	(iy-2),low(wave_up_l)
	; waste 20
	jp	$+3
	jp	$+3

	cycle
	ld	(iy-3),call_z
	; waste 10
	jp	$+3
	ld	a,b
	cp	high(silence)
	jp	z,jp_iy		; return if silence
	nop			; balance out
	nop			; jp (iy)

	cycle
	ld	a,(wf_l)
	ld	b,a
	; waste 33
	ld	a,(0)
	jp	$+3
	jp	$+3
jp_iy:	jp	(iy)

wave_up_l:
	cycle
	pop	iy
	ld	(iy-3),call_nz
	; waste 25
	jp	$+3
	nop
	nop
	ld	a,0

	cycle

	ld	(iy-2),low(wave_down_l)
	ld	(iy-1),high(wave_down_l)
	; waste 12
	jr	$+2
; XXX - return balance is a bit off as it'll hit 7 cycles
	jp	(iy)

wave_down_r:
	cycle
	ld	a,(wf_r)
	inc	a
	and	3
	or	high(sine)
	ld	(wf_r),a
	pop	iy
	; lucky balance!

	cycle
	ld	(iy-1),high(wave_up_r)
	ld	(iy-2),low(wave_up_r)
	; waste 20
	jp	$+3
	jp	$+3

	start_cycle
	samp_l
	samp_r_prime
	ld	(iy-3),call_z
	; waste 10
	jp	$+3
	ld	a,b
	exx
	cp	high(silence)
	jp	z,jp_iy		; return if silence
	nop			; balance out
	nop			; jp (iy)

	cycle
	ld	a,(wf_r)
	exx
	ld	b,a
	exx
	; waste 25
	jp	$+3
	ld	a,0
	nop
	nop
	jp	(iy)

wave_up_r:
	cycle
	pop	iy
	ld	(iy-3),call_nz
	; waste 25
	jp	$+3
	nop
	nop
	ld	a,0

	cycle

	ld	(iy-2),low(wave_down_r)
	ld	(iy-1),high(wave_down_r)
	; waste 12
	jr	$+2
; XXX - return balance is a bit off as it'll hit 7 cycles
	jp	(iy)

	start_cycle		; just to check balance

	org	($+1023)/1024*1024	; 1024 byte align
	include	sine.inc
	assert	$ % 256 == 0
square:
	dc	128,127
	dc	128,$81		; zmac fails if -127; buggy?

	assert	$ % 256 == 0
triangle:
	smp = -128
	rept	127
		defb	smp
		smp += 2
	endm

	smp++
	defb	smp

	rept	127
		defb	smp
		smp -= 2
	endm
	defb	-128

	assert	$ % 256 == 0
saw:	
	smp = 0
	rept 	256
		defb	smp
		smp++
	endm

	assert	$ % 256 == 0
silence:
	dc	256,0

	end	start
