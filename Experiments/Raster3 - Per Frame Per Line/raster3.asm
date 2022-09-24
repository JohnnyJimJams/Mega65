/*
    Sets $d011 invalid for border only screen mode
    Sets V400 for more vertical resolution in FNRASTERLSB (raster y position)
    draw some rasters with custom colours in busy loop
    instead of just running at 100%, base effect on per frame timing.  ie. wait for start of frame, draw something until finished and repeat
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
        bne !loop-      // only handle bottom half of palette to break things up
        // black in the last palette slot
        lda #$00
        sta $d1ff
        sta $d2ff
        sta $d3ff
        sta YRot


MainLoop:
        // Wait for specific raster pos
    !loop:
        ldx YRot
    !innerLoop:
        lda $d053       // hires raster pos MSB
        cpx $d052       // hires raster pos LSB
        bne !innerLoop-
        and #111        // only lowest 3 bits matter
        bne !loop-

        // draw loop
        ldy #0
    !loop:
        sty $d020
        iny
        
        // wait for end of scan line
        lda $d052
    !innerLoop:
        cmp $d052
        beq !innerLoop-

        cpy #110
        bne !loop-

        lda #$ff
        sta $d020

        inc YRot
        bra MainLoop

Data:
    YRot: 
        .byte 0

.align $100
    Palette:    // custom palette with varying frequencies across R,G and B channels
    Palette_Red:
        .fill 256, 8 + 7.5*sin(toRadians(i*360/32))
    Palette_Green:
        .fill 256, 8 + 7.5*sin(toRadians(i*360/64))
    Palette_Blue:
        .fill 256, 8 + 7.5*sin(toRadians(i*360/128))