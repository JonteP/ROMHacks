;todo
;
;player should only face right (boss behavior) in Wolfin? - needs confirmation
;use games own routine to print strings?

;notes
;
;writing $01 to $c005 loads next stage
;writing $02 to $c004 loads boss
 
;==Sega mapper==
.MEMORYMAP
SLOTSIZE $4000
SLOT 0 $0000
SLOT 1 $4000
SLOT 2 $8000
DEFAULTSLOT 2
.ENDME

.ROMBANKMAP
BANKSTOTAL 17
BANKSIZE $4000
BANKS 17
.ENDRO

.COMPUTESMSCHECKSUM

.BACKGROUND "Fantasy Zone II (USA, Europe, Brazil).sms"

;variables:
.DEFINE _RAM_GAME_CONTROL_1 $c004
.DEFINE _RAM_DEMO_STAGE     $c014
.DEFINE _RAM_HELD_BTNS      $c030
.DEFINE _RAM_PRESSED_BTNS   $c031
.DEFINE _RAM_GAME_PLAY_FLAG $c045
.DEFINE _RAM_CURRENT_STAGE1 $c0a0
.DEFINE _RAM_CURRENT_ZONE   $c0a1
.DEFINE _RAM_CURRENT_STAGE2 $c0a2
.DEFINE _RAM_PALETTE1       $c0c0
.DEFINE _RAM_PALETTE2       $c0d0
.DEFINE _RAM_GAME_PAUSED    $c10a
.DEFINE _RAM_LOCK_DIRECTION $c125
.DEFINE _MAPPER_SLOT2       $ffff

.DEFINE _RAM_C010_          $c010


;memory offsets:

;RAM
.DEFINE _OBJECT_RAM         $db00
;VRAM
.DEFINE _TILEMAP_START      $3800
.DEFINE _TITLE_OFFSET       $3890
.DEFINE _STAGE_LIST_OFFSET  $3990
.DEFINE _POINTER_OFFSET     $3988

;functions:
.DEFINE _WAIT_FOR_IRQ       $0018
.DEFINE _LABEL_12D_         $012d
.DEFINE _LABEL_614_         $0614
.DEFINE _FADE_OUT           $0606
.DEFINE _START_GAME_OR_DEMO $1ce5
.DEFINE _LABEL_213E_        $213e
.DEFINE _LABEL_7969_        $7969
.DEFINE _INTRO_MODE         $7edd

;constants:
.DEFINE EXTRA_BANK          $10
.DEFINE TITLE_ROWS          $01
.DEFINE LIST_ROWS           $08
.DEFINE LIST_SPACING        $80 ;double spacing
.DEFINE PALETTE_SIZE        $0f
.DEFINE END_SPRITE_LIST     $d0
.DEFINE END_OF_STRING       $ff
.DEFINE VDP_WRITE_VRAM      $40
.DEFINE VDP_WRITE_REG       $80
.DEFINE TILEMAP_SIZE        $0700
.DEFINE BLANK_TILE          $08
.DEFINE POINTER_TILE        $20
.DEFINE FIRST_STAGE         $00
.DEFINE LAST_STAGE          $07

;registers:
.DEFINE Port_VDPData        $be
.DEFINE Port_VDPAddress     $bf
.DEFINE Port_PSG            $7f
.DEFINE Port_FMAddress      $f0
.DEFINE Port_FMData         $f1

;===========================================================

.BANK 0 SLOT 0
    
;Intercept code in main loop right after return from Title Screen subroutine:

.org $011f

;This part is moved to _STAGE_SELECT_HACK:
    ;ld a, (_RAM_DEMO_STAGE)
    ;ld b, a
    ;ld a, (_RAM_GAME_PLAY_FLAG)
    ;or b
    ;jp z, _INTRO_MODE
    
    call _START_GAME_OR_DEMO ;call this before select screen
    call $213e  ;make sure correct graphics are loaded for wolfin
    ld a, EXTRA_BANK
    rst $30
    call _STAGE_SELECT_HACK
    nop
    nop

;Jumps back here after stage select:
    ;call $1d60
        
;===========================================================
/*
; Insert stage select between stages:
.BANK 1 SLOT 1

.org $395c
    ld a, EXTRA_BANK
    ld (_MAPPER_SLOT2), a
    call _STAGE_SELECT_HACK
    nop
    nop
    nop
    nop
    nop
*/
;===========================================================

.BANK 16
.org 0
    
_STAGE_SELECT_HACK:
    ld a, (_RAM_DEMO_STAGE)
    ld b, a
    ld a, (_RAM_GAME_PLAY_FLAG)
    or b
    jp nz, +
    pop hl
    jp _INTRO_MODE
+:
    ld a, (_RAM_GAME_CONTROL_1)
    bit 5, a    ;check if demo mode
    jp nz, _RETURN_FROM_HACK
    
;disable display:
    ld a, $30
    out (Port_VDPAddress), a
    ld a, VDP_WRITE_REG | $01
    out (Port_VDPAddress), a
        
    call _CLEAR_TILEMAP
        
;draw title:        
    ld hl, _DATA_SELECT_ROUND
    ld de, _TITLE_OFFSET
    ld bc, TITLE_ROWS << 8
    call _DRAW_STRINGS
        
;draw list of stages:
    ld hl, _DATA_STAGES
    ld de, _STAGE_LIST_OFFSET
    ld bc, (LIST_ROWS << 8) | LIST_SPACING
    call _DRAW_STRINGS
    
    
    call _LABEL_614_
    call _SET_PALETTE
    xor a
    ld (_RAM_C010_), a
-:  
    rst _WAIT_FOR_IRQ   
    call _DRAW_POINTER
    ld a, (_RAM_PRESSED_BTNS)
    ld b, a
    and $30     ;button 1/2
    jp nz, _RETURN_FROM_HACK
    bit 0, b    ;button up
    jr z, +
    ld a, (_RAM_CURRENT_STAGE1)
    ld b, a
    dec a
    cp FIRST_STAGE - 1
    jr nz, ++
    ld a, LAST_STAGE
    jr ++
+:  
    bit 1, b
    jr z, -
    ld a, (_RAM_CURRENT_STAGE1)
    ld b, a
    inc a
    cp LAST_STAGE + 1
    jr c, ++
    ld a, FIRST_STAGE
++: 
    ld (_RAM_CURRENT_STAGE1), a
    ld (_RAM_CURRENT_STAGE2), a
    jr -

_RETURN_FROM_HACK:
    jp $795c
    
_CLEAR_TILEMAP:
    ld a, _TILEMAP_START & $00ff
    out (Port_VDPAddress), a
    ld a, VDP_WRITE_VRAM | (_TILEMAP_START >> 8)
    out (Port_VDPAddress), a
    ld bc, TILEMAP_SIZE
-:  
    ld a, BLANK_TILE
    out (Port_VDPData), a
    dec bc
    ld a, b
    or c
    jp nz, -
    ret
    
;===========================================================

_SET_PALETTE:   
    ld de, _RAM_PALETTE1 + 1        ;keep bg color
    ld hl, _DATA_PALETTE
    ld bc, PALETTE_SIZE - 1
    ldir
    ld a, (_RAM_PALETTE2)           ;get bg color from pal. 2
    ld (_RAM_PALETTE1), a
        
;write to CRAM:
    ld a, $00
    out (Port_VDPAddress), a
    ld a, $C0
    out (Port_VDPAddress), a
        
    ld hl, _RAM_PALETTE1
    ld b, PALETTE_SIZE
-:  
    ld a, (hl)
    inc hl
    out (Port_VDPData), a
    ld a, b
    dec a
    ld b, a
    jr nz, -
    ret

;===========================================================        
            
_DRAW_STRINGS:  
    ld a, e
    out (Port_VDPAddress), a
    ld a, d
    or VDP_WRITE_VRAM
    out (Port_VDPAddress), a
-:  
    ld a, (hl)
    inc hl
    cp END_OF_STRING
    jp z, +
    out (Port_VDPData), a
    ld a, $00
    out (Port_VDPData), a
    jr -
+:  
    ld a, e
    add a, c
    ld e, a
    ld a, d
    adc a, $00
    ld d, a
    ld a, b
    dec a
    ld b, a
    cp $00
    jr nz, _DRAW_STRINGS
    ret

_DATA_SELECT_ROUND: 
    .db $33 $25 $2C $25 $23 $34 $00 $32 $2F $35 $2E $24 $FF
    
_DATA_STAGES:   
    .db $11 $0E $00 $30 $21 $33 $34 $21 $32 $29 $21 $FF 
    .db $12 $0E $00 $33 $21 $32 $23 $21 $2E $24 $FF 
    .db $13 $0E $00 $28 $29 $39 $21 $32 $29 $2B $21 $FF 
    .db $14 $0E $00 $22 $2F $37 $00 $22 $2F $37 $FF 
    .db $15 $0E $00 $23 $28 $21 $30 $32 $35 $2E $FF 
    .db $16 $0E $00 $26 $35 $37 $21 $32 $25 $21 $2B $FF 
    .db $17 $0E $00 $33 $22 $21 $32 $24 $29 $21 $2E $FF 
    .db $18 $0E $00 $37 $2F $2C $26 $29 $2E $FF
    
;===========================================================

_DATA_PALETTE:  
    .db $3F $00 $03 $02 $08 $0C $0F $0B $3C $38 $30 $3E $20 $38 $00
    
;===========================================================
    
_DRAW_POINTER:  
    call ++
    ld de, $0000
    call +
    ld a, (_RAM_CURRENT_STAGE1)
    ld b, a
    call ++
    ld de, POINTER_TILE << 8
    call +
    ret
+:  
    ld a, l
    out (Port_VDPAddress), a
    ld a, h
    or VDP_WRITE_VRAM
    out (Port_VDPAddress), a
    ld a, d
    out (Port_VDPData), a
    ld a, e
    out (Port_VDPData), a
    ret
++: 
    ld hl, _POINTER_OFFSET
    ld de, LIST_SPACING
-:  
    dec b
    ret m
    add hl, de
    jr -
    ret     ;never reached?