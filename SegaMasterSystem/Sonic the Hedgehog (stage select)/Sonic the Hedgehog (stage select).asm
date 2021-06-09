;==Sega mapper==
.MEMORYMAP
SLOTSIZE $4000
SLOT 0 $0000
SLOT 1 $4000
SLOT 2 $8000
DEFAULTSLOT 2
.ENDME

.ROMBANKMAP
BANKSTOTAL 18
BANKSIZE $4000
BANKS 18
.ENDRO

.COMPUTESMSCHECKSUM

.BACKGROUND "Sonic The Hedgehog (USA, Europe, Brazil).sms"

.define RAM_TILE_ATTRIBUTE  $d20e
.define RAM_MAP_SECTION     $d216
.define RAM_VDP_REG1        $d219
.define RAM_BANK1           $d235
.define RAM_CURRENT_STAGE   $d23e
.define RAM_XSCROLL         $d251
.define RAM_YSCROLL         $d252
.define RAM_HELD_BUTTONS    $db01 ;custom?
.define RAM_PRESSED_BUTTONS $db02 ;custom?
.define MAPPER_BANK1        $fffe
.define MAPPER_BANK2        $ffff

.define FirstStage          $00
.define LastStage           $11
.define LowerMap            $01
.define UpperMap            $02

.define LoadMusic           $0018
.define WaitForIRQ          $031c
.define LoadPatternsToVRAM  $0405
.define DataToTilemap       $0501
.define StringToTilemap     $05af
.define StageStringTable    $1209

.define Port_IOPort1        $dc

;===========================================================

;stages ($d23e):
;   $00-$02 Green Hill zone
;   $03-$05 Bridge zone
;   $06-$08 Jungle zone
;   $09-$0B Labyrinth zone
;   $0C-$0E Scrap Brain zone
;   $0F-$11 Sky Base zone
;   $12     Ending
;   $13     Credits
;   $14-$1B Scrap Brain teleport positions
;   $1C-$23 Special stage 1-8

.bank 0 slot 0
.org $0c52

_LABEL_C52_:	

;moved to start of function (shifting original code down):
;is this to avoid jingle playing when switching between stages?
		ld a, $07
		rst LoadMusic
        
;shifted original code:
		xor a
		ld (RAM_XSCROLL), a
		ld (RAM_YSCROLL), a
		ld a, $FF   ;undefined map section?
		ld (RAM_MAP_SECTION), a
		ld c, LowerMap
		ld a, (RAM_CURRENT_STAGE)
		cp LastStage + 1
		ret nc
		cp $09
		jr c, +
		ld c, UpperMap
+:	
		ld a, (RAM_MAP_SECTION)
		cp c
        jp z, _LABEL_D3F_   ;jump if map section already loaded
		ld a, c
		ld (RAM_MAP_SECTION), a
		dec a
		jr nz, LoadUpperMap

LoadLowerMap:
		ld a, (RAM_VDP_REG1)
		and $BF
		ld (RAM_VDP_REG1), a
		res 0, (iy+0)
		call WaitForIRQ
		ld hl, $0000
		ld de, $0000
		ld a, $0C
		call LoadPatternsToVRAM
		ld hl, $526B
		ld de, $2000
		ld a, $09
		call LoadPatternsToVRAM
        ld hl, $B92E
		ld de, $3000
		ld a, $09
		call LoadPatternsToVRAM
		ld a, $05
		ld (MAPPER_BANK1), a
		ld (RAM_BANK1), a
		ld hl, $627e
		ld bc, $0178
		ld de, $3800
		ld a, $10
		ld (RAM_TILE_ATTRIBUTE), a
		call DataToTilemap
		ld hl, $63f6
		ld bc, $0145
		ld de, $3800
		ld a, $00
		ld (RAM_TILE_ATTRIBUTE), a
        call DataToTilemap
		ld hl, $F0E
		call $B50
		jr _LABEL_D3F_
	
LoadUpperMap:	
		ld a, (RAM_VDP_REG1)
		and $BF
		ld (RAM_VDP_REG1), a
		res 0, (iy+0)
		call WaitForIRQ
		ld hl, $1801
		ld de, $0000
		ld a, $0C
		call LoadPatternsToVRAM
		ld hl, $5942
		ld de, $2000
		ld a, $09
        call LoadPatternsToVRAM
		ld hl, $B92E
		ld de, $3000
		ld a, $09
		call LoadPatternsToVRAM
		ld a, $05
		ld (MAPPER_BANK1), a
		ld (RAM_BANK1), a
		ld hl, $653B
		ld bc, $0170
		ld de, $3800
		ld a, $10
		ld (RAM_TILE_ATTRIBUTE), a
		call DataToTilemap
		ld hl, $66AB
		ld bc, $0153
		ld de, $3800
		ld a, $00
        ld (RAM_TILE_ATTRIBUTE), a
		call DataToTilemap
		ld hl, $F2E
		call $B50
        
;moved code from here to start of function...

_LABEL_D3F_:	
		call $E86
        
;insert custom stage string printing code here:
		ld a, (MAPPER_BANK2)
		ld ($DB00), a
		ld a, $11
		ld (MAPPER_BANK2), a
		call PrintStageString
		ld a, ($DB00)
		ld (MAPPER_BANK2), a
		nop
		nop
		nop
        
		ld a, (RAM_CURRENT_STAGE)
		ld c, a
        add a, a
		add a, c
		ld e, a
		ld d, $00
		ld hl, $F4E
		add hl, de
		ld e, (hl)
		inc hl
		ld d, (hl)
		inc hl
		ld ($D210), de
		ld a, (hl)
		xor a
		jr z, _LABEL_D80_
		dec a
		add a, a
		ld e, a
		ld d, $00
        ld hl, $1201
		add hl, de
		ld a, (hl)
		inc hl
		ld h, (hl)
		ld l, a
		jp (hl)
	
_LABEL_D80_:	
		ld a, $01
		ld (RAM_TILE_ATTRIBUTE), a
		ld bc, $012C
		push bc
		call $E86
        
;changed code here:
		ld a, (MAPPER_BANK2)
		ld ($DB00), a
		ld a, $11
		ld (MAPPER_BANK2), a
		call $8000
        ld a, ($DB00)
		ld (MAPPER_BANK2), a
		jp (ix)
	
	; Data from DA2 to DD8 (55 bytes)
	.db $2A $14 $D2 $E5 $5C $26 $00 $54 $ED $4B $12 $D2 $CD $0F $35 $E1
	.db $22 $14 $D2 $C1 $3A $05 $D2 $FE $02 $C2 $CF $0D $0B $78 $B1 $C8
	.dsb 13, $00
	.db $FD $CB $03 $6E $C2 $88 $0D $C0 $37 $C9
	
;===========================================================

.bank 17
.org 0

_LABEL_44000_:	
	di
	push af
	push bc
	push de
	push hl
	ei
	ld a, (RAM_TILE_ATTRIBUTE)
	dec a
	ld (RAM_TILE_ATTRIBUTE), a
	jr nz, ++
	ld hl, ($D210)
-:	
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld c, (hl)
	inc hl
    ld b, (hl)
	inc hl
	ld ($D214), bc
	ld a, (hl)
	inc hl
	and a
	jr nz, +
	ex de, hl
	jp -
	
+:	
	ld (RAM_TILE_ATTRIBUTE), a
	ld ($D210), hl
	ld ($D212), de
++:	
	ld a, ($D205)
	cp $02
	jp z, ReadInputs
    ld a, (RAM_PRESSED_BUTTONS)
	bit 0, a
	jr z, +

;Pressed up - increase stage:
	ld a, (RAM_CURRENT_STAGE)
	inc a
	cp $12
	jr c, ++
	ld a, $00
	jr ++
	
+:	
	bit 1, a
	jr z, ReadInputs
        
;Pressed down - decrease stage:
	ld a, (RAM_CURRENT_STAGE)
	dec a
	cp FirstStage - 1
	jr nz, ++
	ld a, LastStage
        
++:	
	ld (RAM_CURRENT_STAGE), a
	ld ix, $0D42
	ld a, (RAM_MAP_SECTION)
	cp $01
	jr nz, +
	ld a, (RAM_CURRENT_STAGE)
	cp $09
	jr c, ++
	ld a, $02
	ld (RAM_MAP_SECTION), a
	ld ix, $0CDF
	jr ++
	
+:	
	ld a, (RAM_CURRENT_STAGE)
	cp $09
	jr nc, ++
    ld a, $01
	ld (RAM_MAP_SECTION), a
	ld ix, $0C7D
	jr ++
	
ReadInputs:	
	ld ix, $0DA2
++:	
	in a, (Port_IOPort1)
	cpl
	ld hl, RAM_HELD_BUTTONS
	ld c, a
	xor (hl)
	ld (hl), c
	and c
	inc hl
	ld (hl), a
	di
    pop hl
	pop de
	pop bc
	pop af
	ei
	ret
	
PrintStageString: ;replaces code at $d42-$d58
	ld a, (RAM_CURRENT_STAGE)
	cp LastStage
	jr z, +
	add a, a
	ld c, a
	ld b, $00
	ld hl, StageStringTable
	add hl, bc
	ld a, (hl)
	inc hl
    ld h, (hl)
	ld l, a
	jr ++
+:	
	ld hl, FinalBossString
++:	
	ld a, $10
	ld (RAM_TILE_ATTRIBUTE), a
	call StringToTilemap
	ret
	
FinalBossString:	
	.db $10 $13 $3F $5E $7F $1E $6F $EB $1F $8E $AE $AE $FF
    
;blank string
	.db $EB $EB $EB $EB $EB $EB $EB $EB $EB $EB $EB $EB $FF
