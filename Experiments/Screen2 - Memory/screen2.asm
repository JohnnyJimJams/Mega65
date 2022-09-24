/*
    The docs say that the visible area on PAL units are 720 x 576 pixels.  Let's test that 
*/

.cpu _45gs02
#import "..\includes\m65macros.asm"

.var bottom_border_pos = 623    // Why do I need to set this to 624 lines high when the docs say the visible area is 576 high?  
                                // 624 is all raster lines!  Does the emu show all lines?

.var side_border_width = 0

.var char_step = 200

.const COLOR_RAM        = $ff80000
.const SCREEN_MEMORY    = $0010000

*= $2001 "UpStart"
BasicUpstart65(Start)

*= $2015 "Program"
Start:
        sei
        
        lda #$35
        sta $01

        lda #$00
        sta $d021

        // resolution H640 and V400
        lda $d031
        ora #%11101000
        sta $d031
        
        enable40Mhz()
        enableVIC4Registers()
        disableCIAandIRQ()
        disableC65ROM()
        VIC4_SetScreenLocation(SCREEN_MEMORY)

        // borders
        lda #$00
        sta $d048       // Top Border Pos
        lda $d049
        and #%11110000
        sta $d049

        lda #<bottom_border_pos
        sta $d04a       // Bottom Border Pos
        lda $d04b
        and #%11110000
        ora #>bottom_border_pos
        sta $d04b

        lda #<side_border_width // side borders
        sta $d05c
        lda $d05d        
        and #%11000000
        ora #>side_border_width
        sta $d05d

        // Screen position

        // TEXTXPOS (Screen left side position)
        lda #$01        // note position 0 doesn't work on real hardware!  need to set minimum of 1
        sta $d04c
        lda $d04d
        and #%11110000
        sta $d04d

        // TEXTYPOS (Screen top position)
        lda #$01        // note position 0 doesn't work on real hardware!  need to set minimum of 1
        sta $d04e
        lda $d04f
        and #%11110000
        sta $d04f

        // display rows
        lda #77     // (624 / 8) - 1
        sta $d07b

        // char count (Physical columns across screen to show)
        lda #100        // 800 pixels wide with no borders and H640 set
        sta $d05e

        // char step (Logical columns across the screen to process in byte count)
        lda #<char_step
        sta $d058
        lda #>char_step
        sta $d059
        
        // Clear color RAM
        jsr ClearColorRAM
        jsr ClearScreenRAM
        jsr SetupColorRAM
        jsr SetupScreenRAM
        cli

        // Super Extended Attribute Mode
        lda #%00000111
        sta $d054

        jmp *

ClearColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$ff)
        DMAFillJob(%00000001, COLOR_RAM, 7800*2, false)
}

ClearScreenRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(1,$00)
        DMAFillJob(1, SCREEN_MEMORY, 7800*2, false)
}

SetupColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$ff)
        DMACopyJob(COLOR_SRC, COLOR_RAM, 16, false, false)
}

SetupScreenRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC, SCREEN_MEMORY, 16, false, false)
}


SCREEN_SRC:
    .byte $01, $00, $02, $00, $03, $00, $04, $00, $05, $00, $06, $00, $07, $00, $08, $00
COLOR_SRC:
    .byte $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01
    

