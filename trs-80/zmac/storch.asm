;
; storch.z - stereo orchestra 85/90 organ
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
;  __|__S__|__D__|_____|__G__|__H__|__J__|_____|__L__|__;__|__ 
; |  c  |  d  |  e  |  f  |  g  |  a  |  b  | c'  | d'  | e'  |
; |__Z__|__X__|__C__|__V__|__B__|__N__|__M__|__,__|__.__|__/__|
;
; A switches left channel waveform (sine, square, triangle, saw)
;
; Up/Down arrows change left volume.
; Left/Right arrows change right volume.
; Volume goes from 1/16 to 16/16.
;
; Current sample output rate on each channel is:
;	Model 1		13,440 Hz (1774080 / sampcyc)
;	Model 3,4	15,360 Hz (2027520 / sampcyc)
;
; Requires 32K memory or 16K without volume control.
;
; Equate havevol to 0 for program without volume control.
;
; TODO:
;	model 4 high speed support with all wait state possibilities.
;	heartbeat line (maybe vaguely show output waveform)?
;		video waits might make it distorting on Model 4

havevol	equ	1

	org	$5200
stack:
splash:	ascii   "  Model x Orchestra 85 Organ by George Phillips, Dec. 18, 2024  "
   if havevol
	ascii   "  left volume ----------------------------------- right volume  "
   else
	ascii   " -------------------------------------------------------------- "
   endif
	ascii	"     ___      %         %         %          %                  "
	ascii	"    |_1_|    sine     square   triangle   sawtooth              "
	ascii   "    _____ _____     _____ _____ _____       _____ _____         "
	ascii   "   |*c'# |*d'#|    |*f'# |*g'# |*a'# |     |*c''#|*d''#|        "
	ascii   "  _|__2__|__3_|____|__5__|__6__|__7__|_____|__9__|__0__|_ ____  "
	ascii   " |*c'|* d' |*e' |*f' |* g' |* a' |* b' |*c'' |*d'' |*e'' |*f''| "
	ascii   " |_Q_|__W__|_E__|_R__|__T__|__Y__|__U__|__I__|__O__|__P__|__@_| "
	ascii   "     _____ _____       _____ _____ _____       _____ _____      "
	ascii	"    |* c# |* d# |     |* f# |* g# |* a# |     |*c'# |*d'# |     "
	ascii   "   _|__S__|__D__|_____|__G__|__H__|__J__|_____|__L__|__;__|_    "
	ascii   "  |*c |* d  |* e  |* f  |* g  |* a  |* b  |*c'  |*d'  |*e'  |   " 
	ascii	"  |_Z_|__X__|__C__|__V__|__B__|__N__|__M__|__,__|__.__|__/__|   "
	ascii	"       ___    sine     square   triangle   sawtooth             "
	ascii	"      |_A_|     %         %         %          %                "
	ascii	0

start:
	di
	ld	sp,stack	; only used during initialization

	xor	a
	out	($84),a		; Model 3 memory map for Model 4

; Detect Model 1, 3 or 4
	in	a,(0ffh)	; read OUTMOD latches
	ld	b,a		; save original settings
	ld	c,60h
	xor	c		; invert CPU Fast, DISWAIT
	out	(0ech),a	; set latches
	in	a,(0ffh)	; read latches
	xor	c		; flip to original value
	xor	b		; compare against original
	ld	c,0ech
	out	(c),b		; restore original settings
	rlca
	rlca
	jr	nc,.ism4	; CPU Fast unchanged, must be Model 4
	rlca
	ld	a,'3'
	jr	nc,.mdone	; DISWAIT same, Model III
	ld	a,'1'		; otherwise, it's a Model I
	jr	.mdone
.ism4:	ld	a,'4'
.mdone:

	ld	(splash+8),a
	cp	'1'
	jr	z,not34

	; Say we're for Orchestra 90
	ld	hl,'90'
	ld	(splash+20),hl

	; Don't skip the Model 3 patching
	ld	a,1		; "ld bc,nn" opcode
	ld	(patch_skip),a

not34:
	ld	hl,splash
	ld	de,$3c00
	xor	a
	ex	af,af'
	ld	iy,wave_ind
splp:	ld	a,(hl)		; eh, we'll assume first byte not special
	cp	'|'
barx:	jr	nobar		; by default we don't translate '|' -> '!'
	ld	a,'!'
	ld	(hl),a
nobar:	ld	(de),a
	ex	de,hl
	cp	(hl)
	jr	z,charok
	res	5,(hl)
	; no lower case; enable bar translation
	ld	a,$20		; "jr nz" opcode
	ld	(barx),a
charok:	ex	de,hl
	inc	hl
	inc	de
	ld	a,(hl)
	or	a
	jr	z,spdn
	cp	'*'
	jr	z,star
	cp	'%'
	jr	nz,splp

	ld	(hl),' '
	ld	(iy),e
	ld	(iy+1),d
	inc	iy
	inc	iy

	jr	splp

star:	ld	ix,param_tab-6
	ld	bc,6
	ex	af,af'
look:	add	ix,bc
	bit	7,(ix+5)
	jr	z,look
	cp	(ix+4)
	jr	nz,look
	inc	a
	ex	af,af'
	ld	(ix+4),e
	ld	(ix+5),d
	ld	(hl),' '
	jr	splp

spdn:	ex	de,hl
clr:	bit	6,h
	jr	nz,clrdn
	ld	(hl),' '
	inc	hl
	jr	clr
clrdn:

meter_l	equ	128+1+4+16
meter_r	equ	128+2+8+32

   if havevol
	; Draw initial volume indicators
	ld	ix,$3c00
	ld	b,16
	ld	de,64
vollp:	ld	(ix),meter_l
	ld	(ix+63),meter_r
	add	ix,de
	djnz	vollp

banksz	equ	4*256

vol_16	equ	wavebnk+0*banksz
vol_15	equ	wavebnk+1*banksz
vol_14	equ	wavebnk+2*banksz
vol_13	equ	wavebnk+3*banksz
vol_12	equ	wavebnk+4*banksz
vol_11	equ	wavebnk+5*banksz
vol_10	equ	wavebnk+6*banksz
vol_9	equ	wavebnk+7*banksz
vol_8	equ	wavebnk+8*banksz
vol_7	equ	wavebnk+9*banksz
vol_6	equ	wavebnk+10*banksz
vol_5	equ	wavebnk+11*banksz
vol_4	equ	wavebnk+12*banksz
vol_3	equ	wavebnk+13*banksz
vol_2	equ	wavebnk+14*banksz
vol_1	equ	wavebnk+15*banksz

	; Create other volume levels.
	; Wouldn't kill me to work out some loops here.
	ld	hl,vol_16
	ld	de,vol_8	; 1/2 volume
	call	div2

	ld	hl,vol_8
	ld	de,vol_4	; 1/4 volume
	call	div2

	ld	hl,vol_4
	ld	de,vol_2	; 1/8 volume
	call	div2

	ld	hl,vol_2
	ld	de,vol_1	; 1/16 volume
	call	div2

	ld	hl,vol_2
	ld	de,vol_1
	ld	ix,vol_3
	call	sum2

	ld	hl,vol_4
	ld	de,vol_1
	ld	ix,vol_5
	call	sum2

	ld	hl,vol_4
	ld	de,vol_2
	ld	ix,vol_6
	call	sum2

	ld	hl,vol_4
	ld	de,vol_3
	ld	ix,vol_7
	call	sum2

	ld	hl,vol_8
	ld	de,vol_1
	ld	ix,vol_9
	call	sum2

	ld	hl,vol_8
	ld	de,vol_2
	ld	ix,vol_10
	call	sum2

	ld	hl,vol_8
	ld	de,vol_3
	ld	ix,vol_11
	call	sum2

	ld	hl,vol_8
	ld	de,vol_4
	ld	ix,vol_12
	call	sum2

	ld	hl,vol_8
	ld	de,vol_5
	ld	ix,vol_12
	call	sum2

	ld	hl,vol_12
	ld	de,vol_1
	ld	ix,vol_13
	call	sum2

	ld	hl,vol_12
	ld	de,vol_2
	ld	ix,vol_14
	call	sum2

	ld	hl,vol_12
	ld	de,vol_3
	ld	ix,vol_15
	call	sum2

   endif

	in	a,($ff)
	or	a,$10		; enable extio
	and	a,~($20 | $40)	; M3 no video wait, M4 slow CPU
	out	($ec),a

dac_l	equ	$b9
dac_r	equ	$b5

dac90_l	equ	$79
dac90_r	equ	$75

patch_skip:
	jp	no_patch

	ld	bc,dn
	ld	sp,dac_patch
dpatch:	pop	hl
	ld	a,(hl)
	and	$f
	or	dac90_l & $f0
	ld	(hl),a
	dec	bc
	ld	a,b
	or	c
	jr	nz,dpatch

	ld	b,step3_size
	ld	sp,step3_tab
	ld	hl,param_tab
ppatch:	pop	de
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl

	inc	hl
	inc	hl
	inc	hl
	inc	hl

	ld	a,up3_ptr
	ld	(ptr1),a	; up arrow to '^'
	ld	(up_ptr_addr),a
	ld	a,down3_ptr
	ld	(ptr3),a	; down arrow to 'v'
	ld	(down_ptr_addr),a

	djnz	ppatch

no_patch:

; Ahem, lot of macros and such before the code continues.

sampcyc	equ	132

equval	macro	root,n,val
&root&n	=	val
	endm

; Get the step value for 32 notes as step_0 .. step_31

calc_steps macro
	octbase = 110 * 256
	hz = octbase
	nt = 0
	rept	32

	; Hz of entire 256 byte buffer at step 1 is: 
	;	cpu_hz / sampcyc / 256
	; (52.5 Hz at 1774080 Hz, 60 Hz at 2027520 Hz)
	; So target Hz over that is our step.
	; But we want 8.8 fixed point value.

	equval	step_,%nt,hz/(cpu_hz/sampcyc/256)

	hz *= 271 ; twelfth root 2 * 256
	hz /= 256
	nt++
	if nt % 12 == 0
		octbase *= 2
		hz = octbase
	endif

	endm

; Define these sensibly

st_c0	=	step_0
st_c0@	=	step_1
st_d0	=	step_2
st_d0@	=	step_3
st_e0	=	step_4
st_f0	=	step_5
st_f0@	=	step_6
st_g0	=	step_7
st_g0@	=	step_8
st_a0	=	step_9
st_a0@	=	step_10
st_b0	=	step_11

st_c1	=	step_12
st_c1@	=	step_13
st_d1	=	step_14
st_d1@	=	step_15
st_e1	=	step_16
st_f1	=	step_17
st_f1@	=	step_18
st_g1	=	step_19
st_g1@	=	step_20
st_a1	=	step_21
st_a1@	=	step_22
st_b1	=	step_23

st_c2	=	step_24
st_c2@	=	step_25
st_d2	=	step_26
st_d2@	=	step_27
st_e2	=	step_28
st_f2	=	step_29

st_null	=	0

	endm

dn = 0

samp_l	macro
	add	hl,de
	ld	c,h
	ld	a,(bc)
	out	(dac_l),a
	equval	dacp,%dn,$-1
	dn++
	endm

samp_r	macro
	exx
	add	hl,de
	ld	c,h
	ld	a,(bc)
	out	(dac_r),a
	equval	dacp,%dn,$-1
	dn++
	exx
	endm

; samp_r but leaves us in prime registers
samp_r_prime macro
	exx
	add	hl,de
	ld	c,h
	ld	a,(bc)
	out	(dac_r),a
	equval	dacp,%dn,$-1
	dn++
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

key	macro	id,addrmask,st,down
  if parkey == 0
param_&id:
  endif

  if parkey < 2
	defw	st_&st
  endif

  if parkey == 0
	defw	ret_&id
	defw	$ff00+id
  endif

  if parkey == 2
	cycle
	ld	sp,param_&id
	; Waste 7+4
	nop
	ld	a,0
	ld	a,0		; waste we can eliminate?
	ld	a,(addrmask >> 8)
	and	addrmask % $100
	jp	nz,down
ret_&id:
  endif
	endm

key_l	macro	id,addrmask,st
	key	id,addrmask,st,down_l
	endm

key_r	macro	id,addrmask,st
	key	id,addrmask,st,down_r
	endm

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

parkeys	macro	pk
	calc_steps

	parkey = pk

	key_l	25,k_Z,c0
	key_l	18,k_S,c0@
	key_l	26,k_X,d0
	key_l	19,k_D,d0@
	key_l	27,k_C,e0
	key_l	28,k_V,f0
	key_l	20,k_G,f0@
	key_l	29,k_B,g0
	key_l	21,k_H,g0@
	key_l	30,k_N,a0
	key_l	22,k_J,a0@
	key_l	31,k_M,b0
	key_l	32,k_comma,c1
	key_l	23,k_L,c1@
	key_l	33,k_dot,d1
	key_l	24,k_semi,d1@
	key_l	34,k_slash,e1

	key_r	07,k_Q,c1
	key_r	00,k_2,c1@
	key_r	08,k_W,d1
	key_r	01,k_3,d1@
	key_r	09,k_E,e1
	key_r	10,k_R,f1
	key_r	02,k_5,f1@
	key_r	11,k_T,g1
	key_r	03,k_6,g1@
	key_r	12,k_Y,a1
	key_r	04,k_7,a1@
	key_r	13,k_U,b1
	key_r	14,k_I,c2
	key_r	05,k_9,c2@
	key_r	15,k_O,d2
	key_r	06,k_0,d2@
	key_r	16,k_P,e2
	key_r	17,k_@,f2

	key	35,k_A,null,wave_down_l
	key	36,k_1,null,wave_down_r

   if havevol
	key	37,k_up,null,vol_up_down_l
	key	38,k_down,null,vol_down_down_l

	key	39,k_left,null,vol_up_down_r
	key	40,k_right,null,vol_down_down_r
   endif

	endm

down_ptr equ	'\'
up_ptr	equ	'['

down3_ptr equ	'v'
up3_ptr	equ	'^'

	exx
	ld	b,high(silence)
	ld	hl,(wave_ind_r)
	ld	(hl),down_ptr
down_ptr_addr equ $-1
	exx
	ld	b,high(silence)
	ld	hl,(wave_ind_l)
	ld	(hl),up_ptr
up_ptr_addr equ $-1

	sett	sampcyc		; hack to let first cycle pass
main:
	cpu_hz = 1774080
	parkeys	2

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
; jump but not stop the audio.

jp_nz	equ	$C2
jp_z	equ	$CA

; Handle note key down on left channel.
; IY is new Hz step for DE.
down_l:
	start_cycle
	pop	de
	pop	iy
	; waste 9
	scf
	ret	nc
	check_l
	samp_r

	ld	b,high(wavebnk)
	org	$-1
wf_l:	defb	high(wavebnk)
	; waste 14
	jp	$+3
	nop

	ld	(iy-3),jp_z
	ld	ix,3		; active down key
	org	$-2
active_l:	defw	3
	; waste 4
	nop

	cycle
	; Adjust active first in case it is us.
	ld	(ix-2),low(old_up_l)
	ld	(ix-1),high(old_up_l)
	ld	(active_l),iy	; we're the one to stop

	cycle
	ld	(iy-2),low(up_l)
	ld	(iy-1),high(up_l)	; previous will not stop audio
	; waste 20
	jp	$+3
	jp	$+3

	cycle
	pop	ix
	ld	(ix),'*'
	; waste 17
	ld	a,0
	jp	$+3

	jp	(iy)		; return to main key scan loop

up_l:
	start_cycle
	ld	b,high(silence)	; back to quiet
	inc	sp
	inc	sp	; skip stack top with 2 extra
	pop	iy
	check_l
	samp_r

	ld	(iy-3),jp_nz
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

	; waste 24
	jp	$+3
	jp	$+3
	nop

	cycle
	pop	ix
	ld	(ix),' '
	; waste 17
	ld	a,0
	jp	$+3

	jp	(iy)		; return

; A key has gone up but it is no longer in charge of the note.
old_up_l:
	cycle
	pop	af
	pop	iy
	ld	(iy-3),jp_nz
	; waste 15
	nop
	nop
	ld	a,0

	cycle
	ld	(iy-1),high(down_l)
	ld	(iy-2),low(down_l)
	; waste 20
	jp	$+3
	jp	$+3

	cycle
	pop	ix
	ld	(ix),' '
	; waste 17
	ld	a,0
	jp	$+3

	jp	(iy)		; return

; Handle note key down on right channel.
; Top of stack is new Hz step for DE.
; Next stack is return address.
; Next stack is screen address for key press on/off indicator.

down_r:
	start_cycle
	samp_l
	exx
	pop	de
	ld	b,high(wavebnk)
	org	$-1
wf_r:	defb	high(wavebnk)
	exx
	pop	iy		; to self-modify key-down check
	ld	(iy-3),jp_z
	ld	ix,3		; active down key
	org	$-2
active_r:	defw	3
	; waste 12
	jr	$+2
	; waste another 15
	nop
	nop
	ld	a,0

	cycle
	; Adjust active first in case it is us.
	ld	(ix-2),low(old_up_r)
	ld	(ix-1),high(old_up_r)
	ld	(active_r),iy	; we're the one to stop

	cycle
	ld	(iy-2),low(up_r)
	ld	(iy-1),high(up_r)	; previous will not stop audio
	; waste 20
	jp	$+3
	jp	$+3

	cycle
	pop	ix
	ld	(ix),'*'
	; waste 17
	ld	a,0
	jp	$+3

	jp	(iy)		; return to main key scan loop

up_r:
	start_cycle
	samp_l
	exx
	ld	b,high(silence)	; back to quiet
	exx
	pop	af
	pop	iy

	ld	(iy-3),jp_nz
	ld	(iy-2),low(down_r)
	; waste 22
	jr	$+2
	jp	$+3

	start_cycle
	samp_l
	ld	(iy-1),high(down_r)
	; waste 22
	nop
	nop
	nop
	jp	$+3

	; audio is off so active no longer matters
	ld	ix,3
	ld	(active_r),ix

	; waste 24
	jp	$+3
	jp	$+3
	nop

	cycle
	pop	ix
	ld	(ix),' '
	; waste 17
	ld	a,0
	jp	$+3

	jp	(iy)		; return

; A key has gone up but it is no longer in charge of the note.
old_up_r:
	cycle
	pop	af
	pop	iy
	ld	(iy-3),jp_nz
	; waste 15
	nop
	nop
	ld	a,0

	cycle
	ld	(iy-1),high(down_r)
	ld	(iy-2),low(down_r)
	; waste 20
	jp	$+3
	jp	$+3

	cycle
	pop	ix
	ld	(ix),' '
	; waste 17
	ld	a,0
	jp	$+3

	jp	(iy)		; return

	pn = 0
set_ind	macro	ind,tab,char
	local	ipos
	cycle
	ld	a,(ind)
	and	3
	add	a,a
	or	low(tab)
	ld	(ipos),a
	; waste 14
	ld	a,0
	ld	a,0

	cycle
	ld	iy,(tab)
	org	$-2
ipos	defw	tab
	ld	(iy),char
	equval	ptr,%pn,$-1
	pn++
	; waste 19
	jr	$+2
	ld	a,0

	endm

wave_down_l:
	set_ind	wf_l,wave_ind_l,' '

	cycle
	ld	a,(wf_l)
	inc	a
	and	3
	or	high(wavebnk)
	org	$-1
wb_l:	defb	high(wavebnk)
	ld	(wf_l),a
	pop	af
	; waste 4
	nop

	set_ind	wf_l,wave_ind_l,up_ptr

	cycle
	pop	iy
	ld	(iy-1),high(wave_up_l)
	ld	(iy-2),low(wave_up_l)
	; waste 6
	inc	sp		; yeah, it's OK

	cycle
	ld	(iy-3),jp_z
	; waste 10
	jp	$+3
	ld	a,b
	cp	high(silence)
	jp	z,jp_iy		; return if currently silent
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

kreset	macro	handler
	cycle

	pop	af
	pop	iy
	ld	(iy-3),jp_nz
	; waste 15
	nop
	nop
	ld	a,0

	cycle

	ld	(iy-2),low(handler)
	ld	(iy-1),high(handler)
	; waste 12
	jr	$+2
	jp	(iy)

	endm

wave_up_l:
	kreset	wave_down_l

wave_down_r:
	set_ind	wf_r,wave_ind_r,' '

	cycle
	ld	a,(wf_r)
	inc	a
	and	3
	or	high(wavebnk)	; self-mod for volume control
	org	$-1
wb_r:	defb	high(wavebnk)
	ld	(wf_r),a
	pop	af
	; waste 4
	nop

	set_ind	wf_r,wave_ind_r,down_ptr

	cycle
	pop	iy
	ld	(iy-1),high(wave_up_r)
	ld	(iy-2),low(wave_up_r)
	; waste 6
	inc	sp		; yeah, it's OK

	start_cycle
	samp_l
	samp_r_prime
	ld	(iy-3),jp_z
	; waste 10
	jp	$+3
	ld	a,b
	exx
	cp	high(silence)
	jp	z,jp_iy		; return if currently silent
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
	kreset	wave_down_r

dovol	macro	chan,direction,uphandler,prime
	local	wfv,svde,is_quiet,wfact

	cycle

	; Clean up all parameters and get return location into IY
	pop	af		
	pop	iy
	pop	af		; Oh, not necessary; oh well.
	ld	ix,(vl_m&chan)
	; waste 4
	nop

	cycle

	add	ix,ix
	add	ix,ix		; get "volume" bits in IX high byte
	ld	(voltmp),ix	; make accessible
	; waste 8
	nop
	nop

	cycle

	ld	ix,(vl_m&chan)
	ld	a,(voltmp+1)	; volume bits
   if direction > 0
	cp	$3f*4+3		; volume bits 15?
   else
	cp	$3c*4+0		; volume bits 0?
   endif
	jp	z,jp_iy		; return if volume at up/down limit
	nop			; balance
	nop			;   jp (iy)
	; lucky balance

	cycle

   if direction > 0
	ld	(ix),' '	; erase top of volume
   else
	jr	$+2
	or	a,0
   endif
	ld	(svde),de
	; waste 19
	jr	$+2
	or	a,0

	cycle

	ld	ix,(vl_m&chan);

	prime
	ld	a,b
	sub	high(silence)
	ld	(wfact),a
	prime
	; waste 6
	inc	sp

	cycle

	ld	de,64*direction
	add	ix,de		; move meter
	ld	de,0
	org	$-2
svde:	defw	0
   if direction > 0
	; waste 23
	jp	$+3
	nop
	scf
	ret	nc
   else
   	ld	(ix),meter&chan	; add to top of meter
	; waste 4
	nop
   endif

	cycle

	ld	(vl_m&chan),ix	; save volume position
	ld	a,(wf&chan)
	and	3		; clear volume from waveform
	ld	(wfv),a
	; waste 5
	ret	c

	cycle

	ld	a,(voltmp+1)	; previous volume bits
   if direction > 0
   	inc	a		; caught up to moved meter
   else
   	dec	a		; caught up to moved meter
   endif
	add	a,a
	add	a,a		; make way for waveform
	xor	(high(wavebnk)&$c0)^$c0	; magically fix up high bits
	or	0		; add waveform back in
	org	$-1
wfv:	defb	0
	ld	(wf&chan),a
	; waste 6
	inc	sp

	cycle

	; waste 4
	nop

	ld	a,(wf&chan)
	and	~3		; drop waveform
	ld	(wb&chan),a

	ld	a,0
	org	$-1
wfact:	defb	0
	or	a
	jp	z,is_quiet

	cycle
	ld	a,(wf&chan)
	prime
	ld	b,a
	prime
	; waste 33
	ld	a,(0)
	jp	$+3
	jp	$+3

is_quiet:
	cycle

	ld	(iy-1),high(uphandler)
	ld	(iy-2),low(uphandler)
	; waste 20
	jp	$+3
	jp	$+3

	cycle

	; waste 31
	jr	$+2
	jr	$+2
	or	a,0

	ld	(iy-3),jp_z
	jp	(iy)

	endm

   if havevol

vol_down_down_l:
	dovol	_l,1,vol_down_up_l,nop

vol_down_up_l:
	kreset	vol_down_down_l,nop

vol_up_down_l:
	dovol	_l,-1,vol_up_up_l,nop

vol_up_up_l:
	kreset	vol_up_down_l,nop

vol_down_down_r:
	dovol	_r,1,vol_down_up_r,exx

vol_down_up_r:
	kreset	vol_down_down_r,exx

vol_up_down_r:
	dovol	_r,-1,vol_up_up_r,exx

vol_up_up_r:
	kreset	vol_up_down_r,exx

	start_cycle		; just to check balance

vl_m_l:	defw	$3c00
vl_m_r:	defw	$3c00+63
voltmp:	defw	0

; Divide sample block at HL by 2 and put into DE.
div2:	ld	bc,4
d2lp:	ld	a,(hl)
	sra	a
	ld	(de),a
	inc	hl
	inc	de
	djnz	d2lp
	dec	c
	jr	nz,d2lp
	ret

; Add sample block at HL and DE and put into IX.
sum2:	ld	bc,4
s2lp:	ld	a,(de)
	add	a,(hl)
	ld	(ix),a
	inc	de
	inc	hl
	inc	ix
	djnz	s2lp
	dec	c
	jr	nz,s2lp
	ret

   endif

param_tab:
	cpu_hz = 1774080
	parkeys	0

step3_tab:
	cpu_hz = 2027520
	parkeys	1
step3_size equ	($-step3_tab)/2

	org	($+15)/16*16	; 16 byte align
; These must be together and have entries for exact number of wave selections.
wave_ind:
wave_ind_r:
	defs	4 * 2
wave_ind_l:
	defs	4 * 2

   if havevol
	org	($+16383)/16384*16384	; 16K align
   else
	org	($+1023)/1024*1024	; 1024 byte align
   endif

wavebnk:
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

   if havevol
	; space for 15 volume levels of each of the 4 waveforms.
	defs	15 * 4 * 256
   endif

	assert	$ % 256 == 0
silence:
	dc	256,0

wordval	macro	root,n
	defw	&root&n
	endm

; Table of addresses of DAC values.
dac_patch:
	n = 0
	rept	dn
		wordval	dacp,%n
		n++
	endm

	end	start
