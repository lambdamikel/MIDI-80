        org 5200h

@fspec  equ 441ch
@init   equ 4420h
@open   equ 4424h
@close  equ 4428h
@read   equ 4436h
@write  equ 4439h
@error  equ 4409h
@exit   equ 402dh
@abort  equ 4030h       
@put    equ 001bh

@KEY    equ     $0049 
@DSPLY  equ     $4467
ENTER   equ     $0d 


ernldos defb 1

disp1           defb  "fspec", ENTER
disp2           defb  "open", ENTER
disp3           defb  "read", ENTER
disp4           defb  "close", ENTER

dcb             defs 48         
readdata        defs 255, ENTER
filename        defb "test", 0 

main:

        ld hl, disp1
        call @DSPLY

        ld hl, filename

trs80:  ld de, dcb              ; ready to get TRS-80 filename from (HL)
        call @fspec
        jp nz, @error 

        ld hl, disp2 
        call @DSPLY
        
openok: ld hl, readdata
        ld de, dcb
        ld b, 0
        call @open               ; open the file
        jr z, readfile
        
        ld c, a                  ; error code 
        call @error
        ret
        
readfile:

        call getern

        ld hl, disp3
        call @DSPLY
        
rloop:  ld de, dcb
        ld hl, readdata
        call @read              ; read file
        jr z, rok               ; got a full 256 bytes
        
        ld c, a
        call @error              ; oops, i/o error
        ret
       
rok:    ld hl, disp4
        call @DSPLY

        ld de, dcb
        call @close              ; close the TRS-80 file
        jr z, cls2ok
        
        ld c, a
        call @error              ; oops, i/o error
        ret 
        
cls2ok: ld hl, readdata
        call @DSPLY

        ld hl, 0                ; all is well
        ret 


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


        end main
