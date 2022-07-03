/*
    Sets $d011 invalid for border only screen mode
    Sets V400 for more vertical resolution in FNRASTERLSB (raster y position)
    draw some rasters with custom colours in busy loop
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

        // Setup palette
        ldx #$00
        txa
    !loop:
        lda Palette_Red,x
        sta $d100,x
        lda Palette_Green,x
        sta $d200,x
        lda Palette_Blue,x
        sta $d300,x
        inx
        bne !loop-

MainLoop:
        lda $d052       // hires raster pos
        clc
        adc YRot
        sta $d020
        inc YRot+1
        inc YRot+1
        inc YRot+1
        inc YRot+1
        bne MainLoop
        inc YRot+2
        bne MainLoop
        inc YRot        // slowly increment YPos for scrolling
        bra MainLoop

Data:
    YRot: 
        .byte 0,0,0

.align $100
    Palette:    // custom palette with varying frequencies across R,G and B channels
    Palette_Red:
        .fill 256, 8 + 7.5*sin(toRadians(i*360/32))
    Palette_Green:
        .fill 256, 8 + 7.5*sin(toRadians(i*360/64))
    Palette_Blue:
        .fill 256, 8 + 7.5*sin(toRadians(i*360/128))
