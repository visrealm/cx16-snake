; Snake - Commander X16
;
; Zero page addresses
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/supaplex-x16
;
;


; Available locations
; https://github.com/commanderx16/x16-docs/blob/master/Commander%20X16%20Programmer%27s%20Reference%20Guide.md#ram-contents
;
;   $00 - $7F (128 bytes) user zero page   
;   $A9 - $FF (87 bytes)  if BASIC or FLOAT functions not used
; 
; Not available:
;   $80 - $A8 (41 bytes)

; -----------------------------------------------------------------------------

; $00 - $01 ??
; $02 - $21 Virtual registers (R0 -> R15)

; -----------------------------------------------------------------------------

;
; $22 - $2f unused
;

ZP_CURRENT_CELL_X        = $30
ZP_CURRENT_CELL_Y        = $31

ZP_CURRENT_PALETTE       = $32

ZP_CURRENT_DIRECTION     = $33

ZP_HEAD_CELL_X           = $34
ZP_HEAD_CELL_Y           = $35

ZP_ANIM_INDEX            = $36

ZP_QUEUE_X_INDEX         = $40
ZP_QUEUE_X               = $41
ZP_QUEUE_X_LSB           = ZP_QUEUE_X
ZP_QUEUE_X_MSB           = ZP_QUEUE_X + 1

ZP_QUEUE_Y_INDEX         = $43
ZP_QUEUE_Y               = $44
ZP_QUEUE_Y_LSB           = ZP_QUEUE_Y
ZP_QUEUE_Y_MSB           = ZP_QUEUE_Y + 1

ZP_QUEUE_D_INDEX         = $46
ZP_QUEUE_D               = $47
ZP_QUEUE_D_LSB           = ZP_QUEUE_D
ZP_QUEUE_D_MSB           = ZP_QUEUE_D + 1


;
; $35 - $7f unused
;

; -----------------------------------------------------------------------------
; \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \
;  \ \ \ \ \ \ \ \ \ \ \ \ $80 - $A8: not available  \ \ \ \ \ \ \ \ \ \ \ \ \
; \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \
; -----------------------------------------------------------------------------


;
; $a9 - $ff unused
;
