; Snake - Commander X16
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/cx16-snake
;
;

!cpu 65c02

!source "src/common/bootstrap.asm"
!source "src/common/kernal/constants.asm"

; -----------------------------------------------------------------------------
; constants
; -----------------------------------------------------------------------------
ADDR_QUEUE_HEADERS = $6000 ; 4KB


; -----------------------------------------------------------------------------
; program entry
; -----------------------------------------------------------------------------

  sei

  ; turn off the display while we're setting things up
  jsr disableDisplay

  ; initialise queues
  jsr qInit

  jsr loadTiles

  ; set up and enable the display
  jsr configDisplay

  ; register the vsync interrupt handler
  jsr registerVsyncIrq

  cli

  ; enter the game loop
  jmp waitForVsync

  rts


!source "src/common/util.asm"
!source "src/common/file.asm"
!source "src/common/memory.asm"
!source "src/common/queue.asm"
!source "src/common/string.asm"

!source "src/common/vera/constants.asm"
!source "src/common/vera/macros.asm"
!source "src/common/vera/vera.asm"
!source "src/common/vera/pcx.asm"
!source "src/common/vera/text.asm"
!source "src/common/vera/vsync.asm"


!source "src/rambank.asm"
!source "src/vram.asm"
!source "src/zeropage.asm"
!source "src/display.asm"
!source "src/tiles.asm"
!source "src/gameloop.asm"
