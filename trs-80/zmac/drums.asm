; hello_ldos5
;   The TRS-80 says hello using the screen
; Reference Document:
;   LDOS Version 5.1: The TRS-80 Operating System Model I and III
;
; zmac hello_ldos5.asm
; trs80gp -ld zout/hello_ldos5.cmd
  org $7000

@DSPLY	equ	$4467 ; pg 6-66
@EXIT	equ	$402d ; pg 6-60
@KBD    equ $002b 

ETX     equ $03 
ENTER	equ	$0d ; @DSPLY with newline
SPACE   equ $20 
NULL    equ $0 

byte	defb	0, SPACE, ETX 

main:

  in  a,($ff)
  or  a,$10
  and a,~$20
  out ($ec),a

mloop:	
  call @KBD
  cp 0
  jr z,loop 
  
  ld hl, byte
  ld (hl), a 
  
  ; note on 
  
  ld a,$90+9
  out (8),a
  
  call short_delay
  
  ld a,(hl)
  out (8),a
  
  call short_delay  
  
  ld a,127
  out (8),a  
  
  ld hl,byte 
  call @DSPLY 
   
  jp mloop
  
 
short_delay:
    ld de,$0010
loop: 
    dec de
    ld a,d
    or e
    jp nz,loop
    ret 
   

  ;call @EXIT
  end main
