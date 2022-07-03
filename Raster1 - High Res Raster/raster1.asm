/*
    Sets $d011 invalid for border only screen mode
    Sets V400 for more vertical resolution in FNRASTERLSB (raster y position)
    draw some rasters with default colours in busy loop
*/

.cpu _45gs02

#import "..\includes\m65macros.asm"

*= $2001 "UpStart"
BasicUpstart65(Start)

*= $2015 "Program"
Start:
        lda #$00
        sta $d011       // Screen off, border only

        lda $d031
        ora #%00001000  // V400
        sta $d031

    !loop:
        lda $d052       // hires raster pos
        clc
        adc YRot
        and #%00111111  // just keep 0-63 cause some of the higher colours are black by default
        sta $d020
        inc YRot+1
        inc YRot+1
        inc YRot+1
        inc YRot+1
        bne !loop-
        inc YRot+2
        bne !loop-
        inc YRot        // slowly increment YPos for scrolling
        bra !loop-

YRot: .byte 0,0,0