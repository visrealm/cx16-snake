; Snake - Commander X16
;
; Title screen
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/supaplex-x16
;
;


letterS:
!byte 4, 2, 5
!byte 3, 2, 5
!byte 2, 2, 6
!byte 2, 3, 10
!byte 2, 4, 11
!byte 3, 4, 15
!byte 4, 4, 14
!byte 4, 5, 10
!byte 4, 6, 9
!byte 3, 6, 5
!byte 2, 6, 5
!byte 0

letterN:
!byte 7, 6, 0
!byte 7, 5, 0
!byte 7, 4, 1
!byte 6, 4, 5
!byte 5, 4, 6
!byte 5, 5, 10
!byte 5, 6, 10
!byte 0

letterA:
!byte 9, 6, 5
!byte 8, 6, 4
!byte 8, 5, 0
!byte 8, 4, 3
!byte 9, 4, 15
!byte 10, 4, 14
!byte 10, 5, 10
!byte 10, 6, 10
!byte 0

letterK1:
!byte 11, 2, 10
!byte 11, 3, 10
!byte 11, 4, 10
!byte 11, 5, 10
!byte 11, 6, 10
!byte 0

letterK2:
!byte 13, 6, 4
!byte 13, 5, 1
!byte 12, 5, 4
!byte 12, 4, 3
!byte 13, 4, 12
!byte 0

letterE:
!byte 16, 6, 13
!byte 15, 6, 5
!byte 14, 6, 4
!byte 14, 5, 0
!byte 14, 4, 3
!byte 15, 4, 15
!byte 16, 4, 14
!byte 16, 5, 9
!byte 15, 5, 5
!byte 0

letterExcl:
!byte 17, 2, 10
!byte 17, 3, 10
!byte 17, 4, 10
!byte 17, 5, 10
!byte 0

titleQueueIndexes:
!byte 0, 0, 0, 0, 0, 0, 0

titleQueueMsbs:
!byte 0, 0, 0, 0, 0, 0, 0

letters:
!word letterS, letterN, letterA, letterK1, letterL2, letterE, letterExcl

initTitle:

  ldy #6
-
  jsr qCreate
  sta titleQueueMsbs, y
  txa
  sta titleQueueIndexes, y
  dey
  bnn -

  ldx #13
  lda letters, x
  sta ZP_TITLE_TEMP_MSB
  dex
  lda letters, x
  sta ZP_TITLE_TEMP_LSB
  phx

  ldy #0
  lda ZP_TITLE_TEMP, y