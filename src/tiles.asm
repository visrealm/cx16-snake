; Snake - Commander X16
;
; Tile definitions
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/supaplex-x16
;
;


TILE_SIZE         = 16
HALF_TILE_SIZE    = TILE_SIZE / 2
TILE_SIZE_BYTES   = 16 * 16 / 2  ; 16 x 16 x 4bpp

snakePcx:   !text "snake.pcx",0
applePcx:   !text "apple.pcx",0

; -----------------------------------------------------------------------------
; tileset addresses
; -----------------------------------------------------------------------------
SNAKE_ADDR = VRADDR_TILE_BASE
APPLE_ADDR = SNAKE_ADDR + (16 * 256)

; -----------------------------------------------------------------------------
; palette indexes
; -----------------------------------------------------------------------------
SNAKE_PAL_ODD    = 2
SNAKE_PAL_EVEN   = 3
APPLE_PAL_ODD    = 4
APPLE_PAL_EVEN   = 5

SNAKE_PAL = SNAKE_PAL_ODD
APPLE_PAL = APPLE_PAL_ODD

; -----------------------------------------------------------------------------
; tile flags
; -----------------------------------------------------------------------------
TILE_FLIP_H = $04
TILE_FLIP_V = $08


!macro ldaTileId tileAddress { lda #(tileAddress - tileTable) >> 3 }
!macro cmpTileId tileAddress { cmp #(tileAddress - tileTable) >> 3 }
!macro byteTileId tileAddress { !byte (tileAddress - tileTable) >> 3 }

; -----------------------------------------------------------------------------
; load the tiles from disk into vram
; -----------------------------------------------------------------------------
loadTiles:
  +setRamBank RAM_BANK_SCRATCH
  +vLoadPcx snakePcx,  SNAKE_ADDR, SNAKE_PAL_ODD
  +vLoadPcx snakePcx,  SNAKE_ADDR, SNAKE_PAL_EVEN
  +vLoadPcx applePcx,  APPLE_ADDR, APPLE_PAL_ODD
  +vLoadPcx applePcx,  APPLE_ADDR, APPLE_PAL_EVEN
  
  +vset VERA_PALETTE + (SNAKE_PAL_EVEN << 5) + 30
  lda #$d3
  sta VERA_DATA0
  lda #$08
  sta VERA_DATA0

  +vset VERA_PALETTE + (APPLE_PAL_EVEN << 5) + 30
  lda #$d3
  sta VERA_DATA0
  lda #$08
  sta VERA_DATA0

  +vset VRADDR_MAP_BASE

  ldy #31
--
  ldx #63
-
  stx ZP_CURRENT_CELL_X
  sty ZP_CURRENT_CELL_Y
  jsr setCellVram
  +ldaTileId tileBlank
  jsr outputTile
  dex
  bpl -
  dey
  bpl --

  stz ZP_QUEUE_X_LSB
  +qCreate ZP_QUEUE_X_INDEX, ZP_QUEUE_X_MSB
  stz ZP_QUEUE_Y_LSB
  +qCreate ZP_QUEUE_Y_INDEX, ZP_QUEUE_Y_MSB
  stz ZP_QUEUE_D_LSB
  +qCreate ZP_QUEUE_D_INDEX, ZP_QUEUE_D_MSB

  lda #0
  +qPush ZP_QUEUE_X_INDEX
  inc
  +qPush ZP_QUEUE_X_INDEX
  inc
  +qPush ZP_QUEUE_X_INDEX
  inc
  +qPush ZP_QUEUE_X_INDEX
  sta ZP_HEAD_CELL_X

  lda #7
  +qPush ZP_QUEUE_Y_INDEX
  +qPush ZP_QUEUE_Y_INDEX
  +qPush ZP_QUEUE_Y_INDEX
  +qPush ZP_QUEUE_Y_INDEX
  sta ZP_HEAD_CELL_Y

  lda #DIR_RIGHT << 2 | DIR_RIGHT
  +ldaTileId tileBodyRight
  +qPush ZP_QUEUE_D_INDEX
  +qPush ZP_QUEUE_D_INDEX
  +qPush ZP_QUEUE_D_INDEX
  +qPush ZP_QUEUE_D_INDEX

  lda #13
  sta ZP_APPLE_CELL_X
  lda #4
  sta ZP_APPLE_CELL_Y


  lda #DIR_RIGHT
  sta ZP_CURRENT_DIRECTION

  lda #1
  sta ZP_ANIM_INDEX

  rts


setCellVram:
  lda ZP_CURRENT_CELL_X
  asl
  asl
	sta VERA_ADDRx_L

	lda #<(VRADDR_MAP_BASE >> 8)
  clc
  adc ZP_CURRENT_CELL_Y
	sta VERA_ADDRx_M

  clc
  stz ZP_CURRENT_PALETTE
  lda ZP_CURRENT_CELL_X
  adc ZP_CURRENT_CELL_Y
  bit #1
  beq +
  lda #16
  sta ZP_CURRENT_PALETTE
+

  rts



!macro outputTile startOffset {
  lda startOffset, y
  sta VERA_DATA0  
  lda startOffset + 1, y  
  ora ZP_CURRENT_PALETTE
  sta VERA_DATA0
  lda startOffset + 2, y
  sta VERA_DATA0  
  lda startOffset + 3, y
  ora ZP_CURRENT_PALETTE
  sta VERA_DATA0
  clc
  lda VERA_ADDRx_L
  adc #124
  sta VERA_ADDRx_L
  lda startOffset + 4, y
  sta VERA_DATA0  
  lda startOffset + 5, y
  ora ZP_CURRENT_PALETTE
  sta VERA_DATA0
  lda startOffset + 6, y
  sta VERA_DATA0  
  lda startOffset + 7, y
  ora ZP_CURRENT_PALETTE
  sta VERA_DATA0
}


DIR_UP    = $0
DIR_LEFT  = $1
DIR_DOWN  = $2
DIR_RIGHT = $3


; -----------------------------------------------------------------------------
; outputTile
; -----------------------------------------------------------------------------
; Inputs:
;  a: tileId
;
; Prerequisites:
;  VERA address already set
; -----------------------------------------------------------------------------
outputTile:
  phy
  asl ; 2x
  asl ; 4x
  asl ; 8x
  tay

  bcc .firstHalf

  +outputTile tileTable + $100
  ply
  rts

.firstHalf:
  +outputTile tileTable
  ply
  rts
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; tile definitions
; -----------------------------------------------------------------------------
; two bytes per tile in the VERA tile format:
;
; Offset	Bit 7	Bit 6	Bit 5	Bit 4	Bit 3	Bit 2	Bit 1	Bit 0
; 0	        [ Tile index (7:0)                                            ]
; 1	        [ Palette offset              ][V-flip][H-flip][Tile index 9:8]
;
; -----------------------------------------------------------------------------
!macro tileDef index, tilesetAddr, tileOffset, tilePalette, tileFlags {
    
    .tilesetOffset = (tilesetAddr - VRADDR_TILE_BASE) / TILE_SIZE_BYTES

    ; tile offset
    .tileOffset    = .tilesetOffset + tileOffset

    ; tile index (7:0)
    !byte .tileOffset & $ff

    ; palette offset (7:4), flags, tile offset (9:8)
    !byte (tilePalette << 4) | tileFlags | (.tileOffset >> 8)
}

!align 255,0
tileTable:
tileBodyUp:       +tileDef    0, SNAKE_ADDR, 2,  SNAKE_PAL, 0
                  +tileDef    0, SNAKE_ADDR, 18, SNAKE_PAL, 0
                  +tileDef    0, SNAKE_ADDR, 2,  SNAKE_PAL, 0                  
                  +tileDef    0, SNAKE_ADDR, 18, SNAKE_PAL, 0                  
tileBodyUpLeft:   +tileDef    1, SNAKE_ADDR, 27, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef    1, SNAKE_ADDR, 11, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef    1, SNAKE_ADDR, 26, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef    1, SNAKE_ADDR, 10, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileHeadDown:     +tileDef    2, SNAKE_ADDR, 17, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef    2, SNAKE_ADDR, 1,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef    2, SNAKE_ADDR, 16, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef    2, SNAKE_ADDR, 0,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileBodyUpRight:  +tileDef    3, SNAKE_ADDR, 11, SNAKE_PAL, TILE_FLIP_V
                  +tileDef    3, SNAKE_ADDR, 27, SNAKE_PAL, TILE_FLIP_V
                  +tileDef    3, SNAKE_ADDR, 10, SNAKE_PAL, TILE_FLIP_V
                  +tileDef    3, SNAKE_ADDR, 26, SNAKE_PAL, TILE_FLIP_V
tileBodyLeftUp:   +tileDef    4, SNAKE_ADDR, 9,  SNAKE_PAL, TILE_FLIP_V
                  +tileDef    4, SNAKE_ADDR, 25, SNAKE_PAL, TILE_FLIP_V
                  +tileDef    4, SNAKE_ADDR, 8,  SNAKE_PAL, TILE_FLIP_V
                  +tileDef    4, SNAKE_ADDR, 24, SNAKE_PAL, TILE_FLIP_V
tileBodyLeft      +tileDef    5, SNAKE_ADDR, 19, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef    5, SNAKE_ADDR, 19, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef    5, SNAKE_ADDR, 3,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef    5, SNAKE_ADDR, 3,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileBodyLeftDown: +tileDef    6, SNAKE_ADDR, 8,  SNAKE_PAL, 0
                  +tileDef    6, SNAKE_ADDR, 24, SNAKE_PAL, 0
                  +tileDef    6, SNAKE_ADDR, 9,  SNAKE_PAL, 0
                  +tileDef    6, SNAKE_ADDR, 25, SNAKE_PAL, 0
tileHeadRight     +tileDef    7, SNAKE_ADDR, 12, SNAKE_PAL, 0
                  +tileDef    7, SNAKE_ADDR, 28, SNAKE_PAL, 0
                  +tileDef    7, SNAKE_ADDR, 13, SNAKE_PAL, 0
                  +tileDef    7, SNAKE_ADDR, 29, SNAKE_PAL, 0
tileHeadUp:       +tileDef    8, SNAKE_ADDR, 0,  SNAKE_PAL, 0
                  +tileDef    8, SNAKE_ADDR, 16, SNAKE_PAL, 0
                  +tileDef    8, SNAKE_ADDR, 1,  SNAKE_PAL, 0                  
                  +tileDef    8, SNAKE_ADDR, 17, SNAKE_PAL, 0                  
tileBodyDownLeft: +tileDef    9, SNAKE_ADDR, 26, SNAKE_PAL, TILE_FLIP_H
                  +tileDef    9, SNAKE_ADDR, 10, SNAKE_PAL, TILE_FLIP_H
                  +tileDef    9, SNAKE_ADDR, 27, SNAKE_PAL, TILE_FLIP_H
                  +tileDef    9, SNAKE_ADDR, 11, SNAKE_PAL, TILE_FLIP_H
tileBodyDown:     +tileDef   10, SNAKE_ADDR, 18, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   10, SNAKE_ADDR, 2,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   10, SNAKE_ADDR, 18, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   10, SNAKE_ADDR, 2,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileBodyDownRight:+tileDef   11, SNAKE_ADDR, 10, SNAKE_PAL, 0
                  +tileDef   11, SNAKE_ADDR, 26, SNAKE_PAL, 0
                  +tileDef   11, SNAKE_ADDR, 11, SNAKE_PAL, 0
                  +tileDef   11, SNAKE_ADDR, 27, SNAKE_PAL, 0
tileBodyRightUp:  +tileDef   12, SNAKE_ADDR, 25, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   12, SNAKE_ADDR, 9,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   12, SNAKE_ADDR, 24, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   12, SNAKE_ADDR, 8,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileHeadLeft:     +tileDef   13, SNAKE_ADDR, 29, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   13, SNAKE_ADDR, 13, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   13, SNAKE_ADDR, 28, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   13, SNAKE_ADDR, 12, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileBodyRightDown:+tileDef   14, SNAKE_ADDR, 24, SNAKE_PAL, TILE_FLIP_H
                  +tileDef   14, SNAKE_ADDR, 8,  SNAKE_PAL, TILE_FLIP_H
                  +tileDef   14, SNAKE_ADDR, 25, SNAKE_PAL, TILE_FLIP_H
                  +tileDef   14, SNAKE_ADDR, 9,  SNAKE_PAL, TILE_FLIP_H
tileBodyRight     +tileDef   15, SNAKE_ADDR, 3,  SNAKE_PAL, 0
                  +tileDef   15, SNAKE_ADDR, 3,  SNAKE_PAL, 0
                  +tileDef   15, SNAKE_ADDR, 19, SNAKE_PAL, 0
                  +tileDef   15, SNAKE_ADDR, 19, SNAKE_PAL, 0
tileTailUp:       +tileDef   16, SNAKE_ADDR, 4,  SNAKE_PAL, 0
                  +tileDef   16, SNAKE_ADDR, 20, SNAKE_PAL, 0
                  +tileDef   16, SNAKE_ADDR, 5,  SNAKE_PAL, 0                  
                  +tileDef   16, SNAKE_ADDR, 21, SNAKE_PAL, 0                  
tileTailLeft      +tileDef   17, SNAKE_ADDR, 31, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   17, SNAKE_ADDR, 15, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   17, SNAKE_ADDR, 30, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   17, SNAKE_ADDR, 14, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileTailDown:     +tileDef   18, SNAKE_ADDR, 21, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   18, SNAKE_ADDR, 5,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   18, SNAKE_ADDR, 20, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   18, SNAKE_ADDR, 4,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileTailRight:    +tileDef   19, SNAKE_ADDR, 14, SNAKE_PAL, 0
                  +tileDef   19, SNAKE_ADDR, 30, SNAKE_PAL, 0
                  +tileDef   19, SNAKE_ADDR, 15, SNAKE_PAL, 0
                  +tileDef   19, SNAKE_ADDR, 31, SNAKE_PAL, 0
tileHeadUpLeft:   +tileDef   20, SNAKE_ADDR, 6,  SNAKE_PAL, 0
                  +tileDef   20, SNAKE_ADDR, 6,  SNAKE_PAL, 0
                  +tileDef   20, SNAKE_ADDR, 6,  SNAKE_PAL, 0                  
                  +tileDef   20, SNAKE_ADDR, 6,  SNAKE_PAL, 0


tileBlank:        +tileDef   20, SNAKE_ADDR, 6,  SNAKE_PAL, 0
                  +tileDef   20, SNAKE_ADDR, 6,  SNAKE_PAL, 0
                  +tileDef   20, SNAKE_ADDR, 6,  SNAKE_PAL, 0                  
                  +tileDef   20, SNAKE_ADDR, 6,  SNAKE_PAL, 0



tileApple:        +tileDef   21, APPLE_ADDR, 0,  APPLE_PAL, 0
                  +tileDef   21, APPLE_ADDR, 2,  APPLE_PAL, 0
                  +tileDef   21, APPLE_ADDR, 1,  APPLE_PAL, 0                  
                  +tileDef   21, APPLE_ADDR, 3,  APPLE_PAL, 0                  
