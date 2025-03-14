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

@DSPLY  equ     $4467

dcb:    defs 48         
iobuf:  defs 256

ernldos: defb 1

ENTER   equ     $0d 

disp1           defb  "fspec", ENTER
disp2           defb  "init", ENTER
disp3           defb  "write", ENTER
disp4           defb  "close", ENTER

writedata       defb "0123456789ABCDEF", ENTER
filename        defb "test", 0 

main:

        ld hl, filename 

trs80:  ld de, dcb              ; ready to get TRS-80 filename from (HL)
        call @fspec
        jp nz, @error 

        ld hl, disp1
        call @DSPLY
        
openok: ld hl, writedata
        ld de, dcb
        ld b, 0
        call @init               ; open the file
        jr z, writefile 
        ld c, a                  ; error code 
        call @error
        jp @abort
        
writefile:

        ld hl, disp2
        call @DSPLY

        ld hl, writedata
        ld de, dcb
        
wloop:  ld hl, writedata
        ld (dcb+3), hl
        call @write              ; write 256 bytes to file
        jr z, wrok
        ld c, a
        call @error              ; oops, i/o error
        jp @abort
        
wrok:   ld hl, disp3
        call @DSPLY

closok: ld a, $10               ; record length 
        ld (dcb+8), a           ; set EOF offset if last block of 256 written
        call setern             ; set ERN (in case shortening file)
        ld de, dcb
        call @close              ; close the TRS-80 file
        jr z, cls2ok
        ld c, a
        call @error              ; oops, i/o error
        jp @abort
        
cls2ok: ld hl, disp4
        call @DSPLY
        ld hl, 0                ; all is well
        jp @exit


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
        ld hl, (dcb+10)         ; current record number
        ld a, (ernldos)         ; get ERN convention
        or a
        jr nz, noadj            ; go if TRSDOS 2.3/LDOS convention
adj:    or c                    ; length multiple of 256 bytes?
        jr z, noadj             ; go if so
        dec hl                  ; no, # of records - 1
noadj:  ld (dcb+12), hl
        ret     

        end main
