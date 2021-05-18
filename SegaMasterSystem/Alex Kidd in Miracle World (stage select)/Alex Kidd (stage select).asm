;todo
;
;ability to set money amount (otherwise shops are unusable when skipping level)

;==Sega mapper==
.MEMORYMAP
SLOTSIZE $4000
SLOT 0 $0000
SLOT 1 $4000
SLOT 2 $8000
DEFAULTSLOT 2
.ENDME

.ROMBANKMAP
BANKSTOTAL 8
BANKSIZE $4000
BANKS 8
.ENDRO

.COMPUTESMSCHECKSUM

.BACKGROUND "Alex Kidd in Miracle World (USA, Europe).sms"

.define _PRESSED_BUTTONS 	$c007
.define _CURRENT_STAGE		$c023
.define _OBJ_ARROW			$c300
.define _TBL_ARROW_POSITION	$1ba5
.define FIRST_STAGE			$01
.define LAST_STAGE			$11

.BANK 0 SLOT 0

;===========================================================
.org $19b3

;Make castle always visible on map

;this would skip drawing castle if stage < $10:
	;ld a, (_CURRENT_STAGE)
	;cp $10
	;jp c, $19cb
	
;replace with nop:
	nop 
	nop
	nop
	nop
	nop
	nop
	nop
	nop

;===========================================================
.org $19d8

;disable map counter...:
	;ld hl, $c03f
	;dec (hl)
		
;...and replace with a call to stage select subroutine:
	call _STAGE_SELECT
	nop

;===========================================================

;Swap inputs to match standard

;button 1 -> button 2:
.org $2af8
	bit 5, a
.org $2b8a
	bit 5, a
.org $2d0e
	bit 5, a
.org $2fc1
	bit 5, a
.org $303e
	bit 5, a
.org $30b1
	bit 5, a
.org $3124
	bit 5, a
.org $353b
	bit 5, a
.org $354c
	bit 5, a
.org $36fa
	and $20
.org $37f0
	and $20
.org $3857
	and $20
.org $3889
	and $20

;button 2 -> button 1:
.org $2af3
	bit 4, a
.org $2b7c
	bit 4, a
.org $33a7
	bit 4, a
.org $2cff
	and $10
.org $30a9
	and $10
.org $3116
	and $10
.org $3518
	and $10
.org $371c
	and $10
	
.BANK 1 SLOT 1
.org $2e2b
	and $10

;==============================================================

.BANK 2
.org $3e88

_STAGE_SELECT:		;New subroutine to select stage at map
	ld a, (_PRESSED_BUTTONS)
	ld b, a
	and $30 
	jp nz, $19df	;start level if button 1/2 pressed
	ld a, (_CURRENT_STAGE)
	
;d-pad up = increase level
	bit 0, b
	jr z, +
	res 0, b
	inc a

;d-pad down = decrease level	
+:	
	bit 1, b
	jr z, +
	res 1, b
	dec a
	
;level overflow
+:	
	cp LAST_STAGE + 1
	jr nz, +
	ld a, FIRST_STAGE
	
;level underflow
+:	
	cp FIRST_STAGE - 1
	jr nz, +
	ld a, LAST_STAGE
	
;store stage and update map indicator
+:	
	ld (_CURRENT_STAGE), a
	ld ix, _OBJ_ARROW
	add a, a
	ld c, a
	ld b, $00
	ld hl, _TBL_ARROW_POSITION
	add hl, bc		;current stage offset
	ld a, (hl)
	ld (ix+12), a
	inc hl
	ld a, (hl)
	ld (ix+14), a
	ret