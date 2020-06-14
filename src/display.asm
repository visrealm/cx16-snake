; Snake - Commander X16
;
; Display routines
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/cx16-snake
;
;


SNAKE_DISPLAY_ASM_ = 1

DISPLAY_SIZE_X  = 640
DISPLAY_SIZE_Y  = 480

DISPLAY_BYTES_PER_ROW = DISPLAY_SIZE_X / 2

BOTTOM_PANEL_SIZE_Y  = 24
VISIBLE_AREA_X       = DISPLAY_SIZE_X
VISIBLE_AREA_Y       = DISPLAY_SIZE_Y - BOTTOM_PANEL_SIZE_Y
VISIBLE_AREA_CX      = VISIBLE_AREA_X / 2
VISIBLE_AREA_CY      = VISIBLE_AREA_Y / 2

BORDER_SIZE  = 8 ; edge tiles are only 8px
MAX_SCROLL_X = MAP_PIXELS_X - VISIBLE_AREA_X - BORDER_SIZE
MAX_SCROLL_Y = MAP_PIXELS_Y - VISIBLE_AREA_Y - BORDER_SIZE

; -----------------------------------------------------------------------------
; disable the display
; -----------------------------------------------------------------------------
disableDisplay:
  +vreg VERA_DC_VIDEO, VERA_VIDEO_OUTPUT_VGA
  rts

; -----------------------------------------------------------------------------
; configure the display
; -----------------------------------------------------------------------------
configDisplay:

  ; set up layer 0 to hold our map tiles
  +vreg VERA_L0_MAPBASE, VRADDR_MAP_BASE_ODD >> 9
  +vreg VERA_L0_TILEBASE, (VRADDR_TILE_BASE >> 9) | VERA_TILE_WIDTH_16 | VERA_TILE_HEIGHT_16
  +vreg VERA_L0_CONFIG, VERA_CONFIG_MAP_WIDTH_64 | VERA_CONFIG_MAP_HEIGHT_32 | VERA_CONFIG_4BPP
  +vreg VERA_L0_HSCROLL_H, 1

  ; layer 1 to hold our hud/ui
  +vreg VERA_L1_TILEBASE, (VRADDR_OVERLAY >> 9)
  +vreg VERA_L1_CONFIG, VERA_CONFIG_BITMAP_MODE | VERA_CONFIG_4BPP
  +vreg VERA_L1_HSCROLL_H, OVERLAY_PAL

  ; other display settings
  +vreg VERA_DC_VIDEO, VERA_VIDEO_LAYER0_ENABLED | VERA_VIDEO_LAYER1_ENABLED | VERA_VIDEO_OUTPUT_VGA
  +vreg VERA_DC_HSCALE, VERA_SCALE_1x
  +vreg VERA_DC_VSCALE, VERA_SCALE_1x
  +vreg VERA_IEN, VERA_IEN_VSYNC
  +vreg VERA_ISR, VERA_IEN_VSYNC
  
  rts
  
  ; -----------------------------------------------------------------------------
