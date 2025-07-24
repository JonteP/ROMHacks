;todo
;
;possible to skip intro with button?
;set Game Over start point to current level?
;remove save feature?

;==LoRom==                
.MEMORYMAP                      ; Begin describing the system architecture.
  SLOTSIZE $8000                ; The slot is $8000 bytes in size.
  DEFAULTSLOT 0                 ; There's only 1 slot in SNES
  SLOT 0 $8000                  ; Define's Slot 0's starting address.
.ENDME                          ; End MemoryMap definition
 
.ROMBANKSIZE $8000              ; Every ROM bank is 32 KBytes in size
.ROMBANKS 16                    ; 4 Mbits

.SNESHEADER
  ID "SNES"                     ; 1-4 letter string, just leave it as "SNES"
 
  NAME "SNES Program Name    "  ; Program Title - can't be over 21 bytes,
  ;    "123456789012345678901"  ; $7fc0-7fd4
 
  SLOWROM						; 7fd5
  LOROM							; 7fd5
 
  CARTRIDGETYPE $02             ; 7fd6 (ROM + save RAM)
  ROMSIZE $09                   ; 7fd7 (4 Mbit)
  SRAMSIZE $01                  ; 7fd8 (16 kbit)
  COUNTRY $00                   ; 7fd9 (japan)
  LICENSEECODE $01              ; 7fda (??)
  VERSION $00                   ; 7fdb (v 1.00)
.ENDSNES

.BACKGROUND "Super Mario World - Super Mario Bros. 4 (Japan).sfc"


;write $0f to all map nodes to allow any direction for mario
.bank 0 slot 0
.org $1eac

	ldx #$5f					; fixed table offset (direction restriction)
	lda #$0f					; RAM location		 (direction restriction)
mapwrite:
	sta $1f49,x					; load table value
	dex
	nop 
	nop 
	nop	
	nop
	nop
	BPL mapwrite


;skip routines that manipulate the map:
.bank 4 slot 0
.org $5a63   ;ignore routine that draws obstacles(?)
.db $ea,$ea

.org $5a9f   ;ignore routine that draws broken castles etc. - game start
.db $ea,$ea,$ea

.org $646b   ;always draw all roads
.db $ea

.org $6648   ;ignore routine that draws broken castles etc. - level clear
.db $ea,$ea,$ea

.org $6bf0
.db $ea,$ea ;ignore routine that explodes castle and replaces with ruin