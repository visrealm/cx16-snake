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

updateFrame:

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

  inc ZP_HEAD_CELL_X
  lda ZP_HEAD_CELL_X
  +qPush ZP_QUEUE_X_INDEX

  lda ZP_HEAD_CELL_Y
  +qPush ZP_QUEUE_Y_INDEX

  lda #DIR_RIGHT << 2 | DIR_RIGHT
  +qPush ZP_QUEUE_D_INDEX

  lda #8
  sta ZP_ANIM_INDEX

  rts
