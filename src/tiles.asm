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

; -----------------------------------------------------------------------------
; tileset addresses
; -----------------------------------------------------------------------------
SNAKE_ADDR = VRADDR_TILE_BASE

; -----------------------------------------------------------------------------
; palette indexes
; -----------------------------------------------------------------------------
SNAKE_PAL_ODD    = 2
SNAKE_PAL_EVEN   = 3

SNAKE_PAL = SNAKE_PAL_ODD

; -----------------------------------------------------------------------------
; tile flags
; -----------------------------------------------------------------------------
TILE_FLIP_H = $04
TILE_FLIP_V = $08


!macro ldaTileId tileAddress { lda #(tileAddress - tileTable) >> 1 }
!macro cmpTileId tileAddress { cmp #(tileAddress - tileTable) >> 1 }
!macro byteTileId tileAddress { !byte (tileAddress - tileTable) >> 1 }

; -----------------------------------------------------------------------------
; load the tiles from disk into vram
; -----------------------------------------------------------------------------
loadTiles:
  +setRamBank RAM_BANK_SCRATCH
  +vLoadPcx snakePcx,  SNAKE_ADDR, SNAKE_PAL_ODD
  +vLoadPcx snakePcx,  SNAKE_ADDR, SNAKE_PAL_EVEN

  +vset VRADDR_MAP_BASE

  stz ZP_CURRENT_CELL_X
  stz ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda #0
  jsr outputTile

  inc ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda #1
  jsr outputTile

  inc ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda #2
  jsr outputTile


  inc ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda #3
  jsr outputTile

  inc ZP_CURRENT_CELL_X
  jsr setCellVram
  lda #4
  jsr outputTile

  inc ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda #5
  jsr outputTile

  inc ZP_CURRENT_CELL_X
  jsr setCellVram
  lda #6
  jsr outputTile


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
  asl ; 2x
  asl ; 4x
  asl ; 8x
  tay

  bcc .firstHalf

  +outputTile tileTable + $100
  rts

.firstHalf:
  +outputTile tileTable
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
tileBlank:        +tileDef   0, SNAKE_ADDR, 6,  SNAKE_PAL, 0
                  +tileDef   0, SNAKE_ADDR, 6,  SNAKE_PAL, 0
                  +tileDef   0, SNAKE_ADDR, 6,  SNAKE_PAL, 0                  
                  +tileDef   0, SNAKE_ADDR, 6,  SNAKE_PAL, 0                  
tileHeadUp:       +tileDef   1, SNAKE_ADDR, 0,  SNAKE_PAL, 0
                  +tileDef   1, SNAKE_ADDR, 16, SNAKE_PAL, 0
                  +tileDef   1, SNAKE_ADDR, 1,  SNAKE_PAL, 0                  
                  +tileDef   1, SNAKE_ADDR, 17, SNAKE_PAL, 0                  
tileHeadLeft:     +tileDef   2, SNAKE_ADDR, 29, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   2, SNAKE_ADDR, 13, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   2, SNAKE_ADDR, 28, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   2, SNAKE_ADDR, 12, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileHeadDown:     +tileDef   3, SNAKE_ADDR, 17, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   3, SNAKE_ADDR, 1,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   3, SNAKE_ADDR, 16, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   3, SNAKE_ADDR, 0,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileHeadRight     +tileDef   4, SNAKE_ADDR, 12, SNAKE_PAL, 0
                  +tileDef   4, SNAKE_ADDR, 28, SNAKE_PAL, 0
                  +tileDef   4, SNAKE_ADDR, 13, SNAKE_PAL, 0
                  +tileDef   4, SNAKE_ADDR, 29, SNAKE_PAL, 0
tileBodyUp:       +tileDef   5, SNAKE_ADDR, 2,  SNAKE_PAL, 0
                  +tileDef   5, SNAKE_ADDR, 18, SNAKE_PAL, 0
                  +tileDef   5, SNAKE_ADDR, 2,  SNAKE_PAL, 0                  
                  +tileDef   5, SNAKE_ADDR, 18, SNAKE_PAL, 0                  
tileBodyLeft      +tileDef   6, SNAKE_ADDR, 19, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   6, SNAKE_ADDR, 19, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   6, SNAKE_ADDR, 3,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   6, SNAKE_ADDR, 3,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileBodyDown:     +tileDef   7, SNAKE_ADDR, 18, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   7, SNAKE_ADDR, 2,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   7, SNAKE_ADDR, 18, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   7, SNAKE_ADDR, 2,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileBodyRight     +tileDef   8, SNAKE_ADDR, 3,  SNAKE_PAL, 0
                  +tileDef   8, SNAKE_ADDR, 3,  SNAKE_PAL, 0
                  +tileDef   8, SNAKE_ADDR, 19, SNAKE_PAL, 0
                  +tileDef   8, SNAKE_ADDR, 19, SNAKE_PAL, 0
tileTailUp:       +tileDef   9, SNAKE_ADDR, 4,  SNAKE_PAL, 0
                  +tileDef   9, SNAKE_ADDR, 20, SNAKE_PAL, 0
                  +tileDef   9, SNAKE_ADDR, 5,  SNAKE_PAL, 0                  
                  +tileDef   9, SNAKE_ADDR, 21, SNAKE_PAL, 0                  
tileTailLeft      +tileDef   10, SNAKE_ADDR, 31, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   10, SNAKE_ADDR, 15, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   10, SNAKE_ADDR, 30, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   10, SNAKE_ADDR, 14, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileTailDown:     +tileDef   11, SNAKE_ADDR, 21, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   11, SNAKE_ADDR, 5,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   11, SNAKE_ADDR, 20, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   11, SNAKE_ADDR, 4,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileTailRight     +tileDef   12, SNAKE_ADDR, 14, SNAKE_PAL, 0
                  +tileDef   12, SNAKE_ADDR, 30, SNAKE_PAL, 0
                  +tileDef   12, SNAKE_ADDR, 15, SNAKE_PAL, 0
                  +tileDef   12, SNAKE_ADDR, 31, SNAKE_PAL, 0
tileBodyUpLeft:   +tileDef   13, SNAKE_ADDR, 27, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   13, SNAKE_ADDR, 11, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   13, SNAKE_ADDR, 26, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   13, SNAKE_ADDR, 10, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileBodyLeftDown: +tileDef   14, SNAKE_ADDR, 8,  SNAKE_PAL, 0
                  +tileDef   14, SNAKE_ADDR, 24, SNAKE_PAL, 0
                  +tileDef   14, SNAKE_ADDR, 9,  SNAKE_PAL, 0
                  +tileDef   14, SNAKE_ADDR, 25, SNAKE_PAL, 0
tileBodyDownRight:+tileDef   15, SNAKE_ADDR, 10, SNAKE_PAL, 0
                  +tileDef   15, SNAKE_ADDR, 26, SNAKE_PAL, 0
                  +tileDef   15, SNAKE_ADDR, 11, SNAKE_PAL, 0
                  +tileDef   15, SNAKE_ADDR, 27, SNAKE_PAL, 0
tileBodyRightUp:  +tileDef   16, SNAKE_ADDR, 25, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   16, SNAKE_ADDR, 9,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   16, SNAKE_ADDR, 24, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
                  +tileDef   16, SNAKE_ADDR, 8,  SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
tileBodyLeftUp:   +tileDef   17, SNAKE_ADDR, 9,  SNAKE_PAL, TILE_FLIP_V
                  +tileDef   17, SNAKE_ADDR, 25, SNAKE_PAL, TILE_FLIP_V
                  +tileDef   17, SNAKE_ADDR, 8,  SNAKE_PAL, TILE_FLIP_V
                  +tileDef   17, SNAKE_ADDR, 24, SNAKE_PAL, TILE_FLIP_V
tileBodyDownLeft: +tileDef   18, SNAKE_ADDR, 26, SNAKE_PAL, TILE_FLIP_H
                  +tileDef   18, SNAKE_ADDR, 10, SNAKE_PAL, TILE_FLIP_H
                  +tileDef   18, SNAKE_ADDR, 27, SNAKE_PAL, TILE_FLIP_H
                  +tileDef   18, SNAKE_ADDR, 11, SNAKE_PAL, TILE_FLIP_H
tileBodyRightDown:+tileDef   19, SNAKE_ADDR, 24, SNAKE_PAL, TILE_FLIP_H
                  +tileDef   19, SNAKE_ADDR, 8,  SNAKE_PAL, TILE_FLIP_H
                  +tileDef   19, SNAKE_ADDR, 25, SNAKE_PAL, TILE_FLIP_H
                  +tileDef   19, SNAKE_ADDR, 9,  SNAKE_PAL, TILE_FLIP_H
tileBodyUpRight:  +tileDef   20, SNAKE_ADDR, 11, SNAKE_PAL, TILE_FLIP_V
                  +tileDef   20, SNAKE_ADDR, 27, SNAKE_PAL, TILE_FLIP_V
                  +tileDef   20, SNAKE_ADDR, 10, SNAKE_PAL, TILE_FLIP_V
                  +tileDef   20, SNAKE_ADDR, 26, SNAKE_PAL, TILE_FLIP_V
