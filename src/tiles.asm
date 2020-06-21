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
APPLE_ADDR = SNAKE_ADDR + (96 * 128)

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

  stz ZP_FRAME_INDEX

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
  bcc .firstHalf
  asl ; 8x
  tay
; 512+
  +outputTile tileTable + $200
  ply
  rts

.firstHalf:
  asl ; 8x
  tay
  bcc .firstQuarter
  +outputTile tileTable + $100
  ply
  rts

.firstQuarter
  +outputTile tileTable
  ply
  rts
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; tile definitions (32 x 32 tiles built from 16 x 16 bitmaps)
; -----------------------------------------------------------------------------
; 8 bytes per tile in the VERA tile format:
;
; Offset	Bit 7	Bit 6	Bit 5	Bit 4	Bit 3	Bit 2	Bit 1	Bit 0
; 0	        [ Tile index (7:0)                                            ]
; 1	        [ Palette offset              ][V-flip][H-flip][Tile index 9:8]
;
; -----------------------------------------------------------------------------
!macro tileDef index, tilesetAddr, tileOffsetUL, tileOffsetUR, tileOffsetBL, tileOffsetBR, tilePalette, tileFlags {
    
    .tilesetOffset = (tilesetAddr - VRADDR_TILE_BASE) / TILE_SIZE_BYTES

    ; tile offset
    .tileOffsetUL    = .tilesetOffset + tileOffsetUL
    .tileOffsetUR    = .tilesetOffset + tileOffsetUR
    .tileOffsetBL    = .tilesetOffset + tileOffsetBL
    .tileOffsetBR    = .tilesetOffset + tileOffsetBR

    ; tile index (7:0)
    !byte .tileOffsetUL & $ff
    ; palette offset (7:4), flags, tile offset (9:8)
    !byte (tilePalette << 4) | tileFlags | (.tileOffsetUL >> 8)

    !byte .tileOffsetUR & $ff
    !byte (tilePalette << 4) | tileFlags | (.tileOffsetUR >> 8)
    !byte .tileOffsetBL & $ff
    !byte (tilePalette << 4) | tileFlags | (.tileOffsetBL >> 8)
    !byte .tileOffsetBR & $ff
    !byte (tilePalette << 4) | tileFlags | (.tileOffsetBR >> 8)
}

!align 255,0
tileTable:
tileBlank:  +tileDef  0, SNAKE_ADDR, 16, 16, 16, 16, SNAKE_PAL, 0
tileApple:  +tileDef  1, APPLE_ADDR, 0,  2,  1,  3,  APPLE_PAL, 0              

+tileDef  2, SNAKE_ADDR, 16, 16, 16, 16, SNAKE_PAL, 0
+tileDef  3, SNAKE_ADDR, 16, 16, 16, 16, SNAKE_PAL, 0
+tileDef  4, SNAKE_ADDR, 16, 16, 16, 16, SNAKE_PAL, 0
+tileDef  5, SNAKE_ADDR, 16, 16, 16, 16, SNAKE_PAL, 0
+tileDef  6, SNAKE_ADDR, 16, 16, 16, 16, SNAKE_PAL, 0
+tileDef  7, SNAKE_ADDR, 16, 16, 16, 16, SNAKE_PAL, 0

+tileDef  8, SNAKE_ADDR, 52, 53, 54, 55, SNAKE_PAL, 0
+tileDef  9, SNAKE_ADDR, 54, 55, 52, 53, SNAKE_PAL, 0
+tileDef  10, SNAKE_ADDR, 78, 79, 76, 77, SNAKE_PAL, TILE_FLIP_V
+tileDef  11, SNAKE_ADDR, 28, 29, 30, 31, SNAKE_PAL, 0
+tileDef  12, SNAKE_ADDR, 79, 78, 77, 76, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  13, SNAKE_ADDR, 29, 28, 31, 30, SNAKE_PAL, TILE_FLIP_H
+tileDef  14, SNAKE_ADDR, 4, 5, 6, 7, SNAKE_PAL, 0
+tileDef  15, SNAKE_ADDR, 5, 4, 7, 6, SNAKE_PAL, 0
+tileDef  16, SNAKE_ADDR, 31, 30, 29, 28, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  17, SNAKE_ADDR, 77, 76, 79, 78, SNAKE_PAL, TILE_FLIP_H
+tileDef  18, SNAKE_ADDR, 29, 28, 31, 30, SNAKE_PAL, TILE_FLIP_H
+tileDef  19, SNAKE_ADDR, 79, 78, 77, 76, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  20, SNAKE_ADDR, 7, 6, 5, 4, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  21, SNAKE_ADDR, 5, 4, 7, 6, SNAKE_PAL, 0
+tileDef  22, SNAKE_ADDR, 30, 31, 28, 29, SNAKE_PAL, TILE_FLIP_V
+tileDef  23, SNAKE_ADDR, 76, 77, 78, 79, SNAKE_PAL, 0
+tileDef  24, SNAKE_ADDR, 28, 29, 30, 31, SNAKE_PAL, 0
+tileDef  25, SNAKE_ADDR, 78, 79, 76, 77, SNAKE_PAL, TILE_FLIP_V
+tileDef  26, SNAKE_ADDR, 55, 54, 53, 52, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  27, SNAKE_ADDR, 54, 55, 52, 53, SNAKE_PAL, 0
+tileDef  28, SNAKE_ADDR, 76, 77, 78, 79, SNAKE_PAL, 0
+tileDef  29, SNAKE_ADDR, 30, 31, 28, 29, SNAKE_PAL, TILE_FLIP_V
+tileDef  30, SNAKE_ADDR, 77, 76, 79, 78, SNAKE_PAL, TILE_FLIP_H
+tileDef  31, SNAKE_ADDR, 31, 30, 29, 28, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V

+tileDef  32, SNAKE_ADDR, 54, 55, 48, 49, SNAKE_PAL, 0
+tileDef  33, SNAKE_ADDR, 48, 49, 50, 51, SNAKE_PAL, 0
+tileDef  34, SNAKE_ADDR, 22, 23, 20, 21, SNAKE_PAL, TILE_FLIP_V
+tileDef  35, SNAKE_ADDR, 14, 15, 12, 13, SNAKE_PAL, TILE_FLIP_V
+tileDef  36, SNAKE_ADDR, 23, 22, 21, 20, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  37, SNAKE_ADDR, 15, 14, 13, 12, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  38, SNAKE_ADDR, 1, 4, 3, 6, SNAKE_PAL, 0
+tileDef  39, SNAKE_ADDR, 0, 1, 2, 3, SNAKE_PAL, 0
+tileDef  40, SNAKE_ADDR, 68, 69, 70, 71, SNAKE_PAL, 0
+tileDef  41, SNAKE_ADDR, 60, 61, 62, 63, SNAKE_PAL, 0
+tileDef  42, SNAKE_ADDR, 70, 71, 68, 69, SNAKE_PAL, TILE_FLIP_V
+tileDef  43, SNAKE_ADDR, 62, 63, 60, 61, SNAKE_PAL, TILE_FLIP_V
+tileDef  44, SNAKE_ADDR, 7, 3, 5, 1, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  45, SNAKE_ADDR, 3, 2, 1, 0, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  46, SNAKE_ADDR, 69, 68, 71, 70, SNAKE_PAL, TILE_FLIP_H
+tileDef  47, SNAKE_ADDR, 61, 60, 63, 62, SNAKE_PAL, TILE_FLIP_H
+tileDef  48, SNAKE_ADDR, 71, 70, 69, 68, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  49, SNAKE_ADDR, 63, 62, 61, 60, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  50, SNAKE_ADDR, 49, 48, 53, 52, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  51, SNAKE_ADDR, 51, 50, 49, 48, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  52, SNAKE_ADDR, 20, 21, 22, 23, SNAKE_PAL, 0
+tileDef  53, SNAKE_ADDR, 12, 13, 14, 15, SNAKE_PAL, 0
+tileDef  54, SNAKE_ADDR, 21, 20, 23, 22, SNAKE_PAL, TILE_FLIP_H
+tileDef  55, SNAKE_ADDR, 13, 12, 15, 14, SNAKE_PAL, TILE_FLIP_H
+tileDef  56, SNAKE_ADDR, 50, 51, 16, 16, SNAKE_PAL, 0
+tileDef  57, SNAKE_ADDR, 16, 0, 16, 2, SNAKE_PAL, 0
+tileDef  58, SNAKE_ADDR, 2, 16, 0, 16, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  59, SNAKE_ADDR, 16, 16, 51, 50, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  60, SNAKE_ADDR, 56, 57, 58, 59, SNAKE_PAL, 0
+tileDef  61, SNAKE_ADDR, 58, 59, 54, 55, SNAKE_PAL, 0
+tileDef  62, SNAKE_ADDR, 25, 24, 27, 26, SNAKE_PAL, TILE_FLIP_H
+tileDef  63, SNAKE_ADDR, 86, 87, 84, 85, SNAKE_PAL, TILE_FLIP_V
+tileDef  64, SNAKE_ADDR, 24, 25, 26, 27, SNAKE_PAL, 0
+tileDef  65, SNAKE_ADDR, 87, 86, 85, 84, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  66, SNAKE_ADDR, 8, 9, 10, 11, SNAKE_PAL, 0
+tileDef  67, SNAKE_ADDR, 5, 8, 7, 10, SNAKE_PAL, 0
+tileDef  68, SNAKE_ADDR, 75, 74, 73, 72, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  69, SNAKE_ADDR, 39, 38, 37, 36, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  70, SNAKE_ADDR, 73, 72, 75, 74, SNAKE_PAL, TILE_FLIP_H
+tileDef  71, SNAKE_ADDR, 37, 36, 39, 38, SNAKE_PAL, TILE_FLIP_H
+tileDef  72, SNAKE_ADDR, 11, 10, 9, 8, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  73, SNAKE_ADDR, 10, 7, 8, 5, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  74, SNAKE_ADDR, 74, 75, 72, 73, SNAKE_PAL, TILE_FLIP_V
+tileDef  75, SNAKE_ADDR, 38, 39, 36, 37, SNAKE_PAL, TILE_FLIP_V
+tileDef  76, SNAKE_ADDR, 72, 73, 74, 75, SNAKE_PAL, 0
+tileDef  77, SNAKE_ADDR, 36, 37, 38, 39, SNAKE_PAL, 0
+tileDef  78, SNAKE_ADDR, 59, 58, 57, 56, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  79, SNAKE_ADDR, 55, 54, 59, 58, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  80, SNAKE_ADDR, 27, 26, 25, 24, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  81, SNAKE_ADDR, 84, 85, 86, 87, SNAKE_PAL, 0
+tileDef  82, SNAKE_ADDR, 26, 27, 24, 25, SNAKE_PAL, TILE_FLIP_V
+tileDef  83, SNAKE_ADDR, 85, 84, 87, 86, SNAKE_PAL, TILE_FLIP_H
+tileDef  84, SNAKE_ADDR, 16, 16, 56, 57, SNAKE_PAL, 0
+tileDef  85, SNAKE_ADDR, 33, 32, 35, 34, SNAKE_PAL, TILE_FLIP_H
+tileDef  86, SNAKE_ADDR, 32, 33, 34, 35, SNAKE_PAL, 0
+tileDef  87, SNAKE_ADDR, 9, 16, 11, 16, SNAKE_PAL, 0
+tileDef  88, SNAKE_ADDR, 83, 82, 81, 80, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  89, SNAKE_ADDR, 81, 80, 83, 82, SNAKE_PAL, TILE_FLIP_H
+tileDef  90, SNAKE_ADDR, 16, 11, 16, 9, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  91, SNAKE_ADDR, 82, 83, 80, 81, SNAKE_PAL, TILE_FLIP_V
+tileDef  92, SNAKE_ADDR, 80, 81, 82, 83, SNAKE_PAL, 0
+tileDef  93, SNAKE_ADDR, 57, 56, 16, 16, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  94, SNAKE_ADDR, 35, 34, 33, 32, SNAKE_PAL, TILE_FLIP_H | TILE_FLIP_V
+tileDef  95, SNAKE_ADDR, 34, 35, 32, 33, SNAKE_PAL, TILE_FLIP_V


; Map snake segments to tile ids
;
; Snake segment ids consist of the segment type, from direction and to direction
; 
;
; [ segment ][  from  ][  to   ]
; [ 6  -  4 ][ 3 - 2  ][ 1 - 0 ];
;
; segments:
;  0: Step 0 - Nose
;  1: Step 0 - Head
;  2: Step 0 - Body
;  3: Step 0 - Tail
;  4: Step 1 - Head
;  5: Step 1 - Body
;  6: Step 1 - Tail
;  7: Step 1 - Tip
;
; from and to:
;  0: Up
;  1: Left
;  2: Down
;  3: Right
;

!align 255,0
snakeTileMap:
!byte 59; Nose_Up_0
!byte 0
!byte 0
!byte 0
!byte 0
!byte 57; Nose_Left_0
!byte 0
!byte 0
!byte 0
!byte 0
!byte 56; Nose_Down_0
!byte 0
!byte 0
!byte 0
!byte 0
!byte 58; Nose_Right_0
!byte 50; Head_Up_0
!byte 52; Head_UpLeft_0
!byte 0
!byte 54; Head_UpRight_0
!byte 42; Head_LeftUp_0
!byte 38; Head_Left_0
!byte 40; Head_LeftDown_0
!byte 0
!byte 0
!byte 34; Head_DownLeft_0
!byte 32; Head_Down_0
!byte 36; Head_DownRight_0
!byte 48; Head_RightUp_0
!byte 0
!byte 46; Head_RightDown_0
!byte 44; Head_Right_0
!byte 26; Body_Up_0
!byte 28; Body_UpLeft_0
!byte 0
!byte 30; Body_UpRight_0
!byte 18; Body_LeftUp_0
!byte 14; Body_Left_0
!byte 16; Body_LeftDown_0
!byte 0
!byte 0
!byte 10; Body_DownLeft_0
!byte 8; Body_Down_0
!byte 12; Body_DownRight_0
!byte 24; Body_RightUp_0
!byte 0
!byte 22; Body_RightDown_0
!byte 20; Body_Right_0
!byte 78; Tail_Up_0
!byte 80; Tail_UpLeft_0
!byte 0
!byte 82; Tail_UpRight_0
!byte 70; Tail_LeftUp_0
!byte 66; Tail_Left_0
!byte 68; Tail_LeftDown_0
!byte 0
!byte 0
!byte 62; Tail_DownLeft_0
!byte 60; Tail_Down_0
!byte 64; Tail_DownRight_0
!byte 76; Tail_RightUp_0
!byte 0
!byte 74; Tail_RightDown_0
!byte 72; Tail_Right_0
!byte 51; Head_Up_1
!byte 53; Head_UpLeft_1
!byte 0
!byte 55; Head_UpRight_1
!byte 43; Head_LeftUp_1
!byte 39; Head_Left_1
!byte 41; Head_LeftDown_1
!byte 0
!byte 0
!byte 35; Head_DownLeft_1
!byte 33; Head_Down_1
!byte 37; Head_DownRight_1
!byte 49; Head_RightUp_1
!byte 0
!byte 47; Head_RightDown_1
!byte 45; Head_Right_1
!byte 27; Body_Up_1
!byte 29; Body_UpLeft_1
!byte 0
!byte 31; Body_UpRight_1
!byte 19; Body_LeftUp_1
!byte 15; Body_Left_1
!byte 17; Body_LeftDown_1
!byte 0
!byte 0
!byte 11; Body_DownLeft_1
!byte 9; Body_Down_1
!byte 13; Body_DownRight_1
!byte 25; Body_RightUp_1
!byte 0
!byte 23; Body_RightDown_1
!byte 21; Body_Right_1
!byte 79; Tail_Up_1
!byte 81; Tail_UpLeft_1
!byte 0
!byte 83; Tail_UpRight_1
!byte 71; Tail_LeftUp_1
!byte 67; Tail_Left_1
!byte 69; Tail_LeftDown_1
!byte 0
!byte 0
!byte 63; Tail_DownLeft_1
!byte 61; Tail_Down_1
!byte 65; Tail_DownRight_1
!byte 77; Tail_RightUp_1
!byte 0
!byte 75; Tail_RightDown_1
!byte 73; Tail_Right_1
!byte 93; Tip_Up_1
!byte 94; Tip_UpLeft_1
!byte 0
!byte 95; Tip_UpRight_1
!byte 89; Tip_LeftUp_1
!byte 87; Tip_Left_1
!byte 88; Tip_LeftDown_1
!byte 0
!byte 0
!byte 85; Tip_DownLeft_1
!byte 84; Tip_Down_1
!byte 86; Tip_DownRight_1
!byte 92; Tip_RightUp_1
!byte 0
!byte 91; Tip_RightDown_1
!byte 90; Tip_Right_1
