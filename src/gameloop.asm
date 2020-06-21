; Snake - Commander X16
;
; Game loop
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/cx16-snake
;
;


SNAKE_GAMELOOP_ASM_ = 1


; -----------------------------------------------------------------------------
; loop to wait for vsync
; -----------------------------------------------------------------------------
waitForVsync:
  !byte $CB  ; WAI instruction
  lda VSYNC_FLAG
  bne waitForVsync

  ; flow on through to the.... 

; -----------------------------------------------------------------------------
; main game loop
; -----------------------------------------------------------------------------
gameLoop:

  dec ZP_ANIM_INDEX
  bne +
  jsr updateFrame
+
  jsr JOYSTICK_GET
  adc ZP_RANDOM
  sta ZP_RANDOM

  lda #1
  sta VSYNC_FLAG

	bra waitForVsync

doInput:
 
  jsr JOYSTICK_GET
  bit #JOY_UP
  bne .testDown

  lda ZP_CURRENT_DIRECTION
  and #3
  cmp #DIR_DOWN 
  beq .testDown
  asl
  asl
  ora #DIR_UP
  +qBack ZP_QUEUE_D_INDEX
  sta (ZP_QUEUE_D), y
  lda #DIR_UP << 2 | DIR_UP
  sta ZP_CURRENT_DIRECTION
  +qPush ZP_QUEUE_D_INDEX

  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  dec ZP_HEAD_CELL_Y
  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  rts
.testDown:
  bit #JOY_DOWN
  bne .testRight

  lda ZP_CURRENT_DIRECTION
  and #3
  cmp #DIR_UP
  beq .testRight
  asl
  asl
  ora #DIR_DOWN
  +qBack ZP_QUEUE_D_INDEX
  sta (ZP_QUEUE_D), y
  lda #DIR_DOWN << 2 | DIR_DOWN
  sta ZP_CURRENT_DIRECTION
  +qPush ZP_QUEUE_D_INDEX

  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  inc ZP_HEAD_CELL_Y
  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  rts
.testRight:
  bit #JOY_RIGHT
  bne .testLeft

  lda ZP_CURRENT_DIRECTION
  and #3
  cmp #DIR_LEFT
  beq .testLeft
  asl
  asl
  ora #DIR_RIGHT
  +qBack ZP_QUEUE_D_INDEX
  sta (ZP_QUEUE_D), y
  lda #DIR_RIGHT << 2 | DIR_RIGHT
  sta ZP_CURRENT_DIRECTION
  +qPush ZP_QUEUE_D_INDEX
  
  inc ZP_HEAD_CELL_X
  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  rts
.testLeft:
  bit #JOY_LEFT
  bne .doneTests

  lda ZP_CURRENT_DIRECTION
  and #3
  cmp #DIR_RIGHT
  beq .doneTests
  asl
  asl
  ora #DIR_LEFT
  +qBack ZP_QUEUE_D_INDEX
  sta (ZP_QUEUE_D), y
  lda #DIR_LEFT << 2 | DIR_LEFT
  sta ZP_CURRENT_DIRECTION
  +qPush ZP_QUEUE_D_INDEX
  
  dec ZP_HEAD_CELL_X
  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  rts
.doneTests:

  lda ZP_CURRENT_DIRECTION
  and #3
  cmp #DIR_UP
  bne +
  dec ZP_HEAD_CELL_Y
  bra .doneMove
+
  cmp #DIR_DOWN
  bne +
  inc ZP_HEAD_CELL_Y
  bra .doneMove
+
  cmp #DIR_LEFT
  bne +
  dec ZP_HEAD_CELL_X
  bra .doneMove
+
  cmp #DIR_RIGHT
  bne +
  inc ZP_HEAD_CELL_X
  bra .doneMove
+

.doneMove:
  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  lda ZP_CURRENT_DIRECTION
  and #3
  sta ZP_CURRENT_DIRECTION
  asl
  asl
  ora ZP_CURRENT_DIRECTION
  sta ZP_CURRENT_DIRECTION
  +qPush ZP_QUEUE_D_INDEX
  rts


updateFrame:
  lda ZP_FRAME_INDEX
  and #1
  bne +

  jsr doInput
  
  lda ZP_APPLE_CELL_X
  sta ZP_CURRENT_CELL_X
  lda ZP_APPLE_CELL_Y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  +ldaTileId tileApple
  jsr outputTile

  ldx ZP_QUEUE_X_INDEX
  jsr qSize
  pha
  jsr qIterate
  plx  ; here, x i size, y is starting offset, a is queue msb

  jsr doStep0

  bra doneStep
+
  ldx ZP_QUEUE_X_INDEX
  jsr qSize
  pha
  jsr qIterate
  plx  ; here, x i size, y is starting offset, a is queue msb

  jsr doStep1

doneStep:  

  +dbgBreak

  inc ZP_FRAME_INDEX

  lda #4
  sta ZP_ANIM_INDEX

  rts


doStep0:
  lda (ZP_QUEUE_X), y
  sta ZP_CURRENT_CELL_X
  lda (ZP_QUEUE_Y), y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda #0
  jsr outputTile
  iny
  dex


  lda (ZP_QUEUE_X), y
  sta ZP_CURRENT_CELL_X
  lda (ZP_QUEUE_Y), y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda (ZP_QUEUE_D), y
  ora #$30  ; tail
  phy
  tay
  lda snakeTileMap, y
  ply
  jsr outputTile
  iny
  dex


--
  lda (ZP_QUEUE_X), y
  sta ZP_CURRENT_CELL_X
  lda (ZP_QUEUE_Y), y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda (ZP_QUEUE_D), y
  cpx #2
  bne +
  ora #$10 ; head
  bra .doOutput0
+
  cpx #1
  beq +
  ora #$20  ; body
  bra .doOutput0
+

.doOutput0:
  phy
  tay
  lda snakeTileMap, y
  ply
  jsr outputTile

  iny
  dex
  bne --

  rts

doStep1:
  lda (ZP_QUEUE_X), y
  sta ZP_CURRENT_CELL_X
  lda (ZP_QUEUE_Y), y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda #0
  jsr outputTile
  iny
  dex


  lda (ZP_QUEUE_X), y
  sta ZP_CURRENT_CELL_X
  lda (ZP_QUEUE_Y), y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda (ZP_QUEUE_D), y
  ora #$70  ; tip
  phy
  tay
  lda snakeTileMap, y
  ply
  jsr outputTile
  iny
  dex

  lda (ZP_QUEUE_X), y
  sta ZP_CURRENT_CELL_X
  lda (ZP_QUEUE_Y), y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda (ZP_QUEUE_D), y
  ora #$60  ; tail
  phy
  tay
  lda snakeTileMap, y
  ply
  jsr outputTile
  iny
  dex


--
  lda (ZP_QUEUE_X), y
  sta ZP_CURRENT_CELL_X
  lda (ZP_QUEUE_Y), y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda (ZP_QUEUE_D), y
  
  ora #$40 ; tip or body
  cpx #1   
  beq +
  ora #$10 ; body
+
  phy
  tay
  lda snakeTileMap, y
  ply
  jsr outputTile

  iny
  dex
  bne --


  lda ZP_HEAD_CELL_X 
  cmp ZP_APPLE_CELL_X
  bne .doPop
  lda ZP_HEAD_CELL_Y 
  cmp ZP_APPLE_CELL_Y
  bne .doPop

  lda ZP_APPLE_CELL_X
  adc ZP_RANDOM
  and #15
  sta ZP_APPLE_CELL_X

  lda ZP_APPLE_CELL_Y
  adc ZP_RANDOM
  and #14
  sta ZP_APPLE_CELL_Y


  bra .noPop

.doPop:
  +qPop ZP_QUEUE_X_INDEX
  +qPop ZP_QUEUE_Y_INDEX
  +qPop ZP_QUEUE_D_INDEX

.noPop:

  rts