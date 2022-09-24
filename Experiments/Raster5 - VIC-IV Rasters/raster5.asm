/*
    Sets $d011 invalid for border only screen mode
    Sets V400 for more vertical resolution in FNRASTERLSB (raster y position)
    draw some rasters with custom colours in busy loop (within an IRQ)
    raster IRQ to handle top of raster and per frame timing
    Try to use fine grained raster y compare values (looks like the emu doesn't support)
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

SetupIRQ:
        sei
        lda #$01
        sta $d01a
        lda #$7f
        sta $dc0d
        sta $dd0d
        lda #<IRQ
        sta $0314
        lda #>IRQ
        sta $0315

        lda #$40
        sta $d079       // hires ras compare
        lda $d07a
        and #%01111000
        sta $d07a
        lda $d053       // hires raster compare
        and #%01111111
        sta $d053

        cli

MainLoop:
        jmp MainLoop


IRQ:
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

        inc YPos
        ldy YPos
        lda SinTable,y
        sta $d079   // scroll the raster IRQ Y trigger value

        dec $d019
        // note the specific IRQ exit code below for mega65
        pla
        tab
        plz
        ply
        plx
        pla
        rti

Data:
    YPos:
        .byte 0

.align $100
    Palette:    // custom palette with varying frequencies across R,G and B channels
    Palette_Red:
        .fill 256, 7.5 + 7.5*sin(toRadians(i*360/112))
    Palette_Green:
        .fill 256, 7.5 + 7.5*sin(toRadians(i*360/120))
    Palette_Blue:
        .fill 256, 7.5 + 7.5*sin(toRadians(i*360/128))

    SinTable:
        .fill 256, 127.5 + 127.5*sin(toRadians(i*360/256))