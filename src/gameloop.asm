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

  lda #1
  sta VSYNC_FLAG

	bra waitForVsync

doInput:
 
  jsr JOYSTICK_GET
  bit #JOY_UP
  bne .testDown
  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  dec ZP_HEAD_CELL_Y
  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  lda ZP_CURRENT_DIRECTION
  and #3
  asl
  asl
  ora #DIR_UP
  +qBack ZP_QUEUE_D_INDEX
  sta (ZP_QUEUE_D), y
  lda #DIR_UP << 2 | DIR_UP
  sta ZP_CURRENT_DIRECTION
  +qPush ZP_QUEUE_D_INDEX
  rts
.testDown:
  bit #JOY_DOWN
  bne .testRight
  
  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  inc ZP_HEAD_CELL_Y
  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  lda ZP_CURRENT_DIRECTION
  and #3
  asl
  asl
  ora #DIR_DOWN
  +qBack ZP_QUEUE_D_INDEX
  sta (ZP_QUEUE_D), y
  lda #DIR_DOWN << 2 | DIR_DOWN
  sta ZP_CURRENT_DIRECTION
  +qPush ZP_QUEUE_D_INDEX
  rts
.testRight:
  bit #JOY_RIGHT
  bne .testLeft
  inc ZP_HEAD_CELL_X
  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  lda ZP_CURRENT_DIRECTION
  and #3
  asl
  asl
  ora #DIR_RIGHT
  +qBack ZP_QUEUE_D_INDEX
  sta (ZP_QUEUE_D), y
  lda #DIR_RIGHT << 2 | DIR_RIGHT
  sta ZP_CURRENT_DIRECTION
  +qPush ZP_QUEUE_D_INDEX
  rts
.testLeft:
  bit #JOY_LEFT
  bne .doneTests
  dec ZP_HEAD_CELL_X
  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  lda ZP_CURRENT_DIRECTION
  and #3
  asl
  asl
  ora #DIR_LEFT
  +qBack ZP_QUEUE_D_INDEX
  sta (ZP_QUEUE_D), y
  lda #DIR_LEFT << 2 | DIR_LEFT
  sta ZP_CURRENT_DIRECTION
  +qPush ZP_QUEUE_D_INDEX
  rts
.doneTests:
;  inc ZP_HEAD_CELL_X
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

  jsr doInput

  ldx ZP_QUEUE_X_INDEX
  jsr qSize
  pha
  jsr qIterate
  plx  ; here, x i size, y is starting offset, a is queue msb

  lda (ZP_QUEUE_X), y
  sta ZP_CURRENT_CELL_X
  lda (ZP_QUEUE_Y), y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  +ldaTileId tileBlank
  jsr outputTile
  iny
  dex

  lda (ZP_QUEUE_X), y
  sta ZP_CURRENT_CELL_X
  lda (ZP_QUEUE_Y), y
  sta ZP_CURRENT_CELL_Y
  jsr setCellVram
  lda (ZP_QUEUE_D), y
  and #$03  ; tail
  ora #$10
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
  cpx #1   
  bne +
  eor #$08  ; head
+
  jsr outputTile

  iny
  dex
  bne --  


  +qPop ZP_QUEUE_X_INDEX
  +qPop ZP_QUEUE_Y_INDEX
  +qPop ZP_QUEUE_D_INDEX

  lda #8
  sta ZP_ANIM_INDEX

  rts
