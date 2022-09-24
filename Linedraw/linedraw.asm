/*
    From the manual:

    The DMAgic supports an advanced internal address calculator that allows it to draw
    scaled textures and draw lines with arbitrary slopes on VIC-IV FCM video displays.

    So, step 1) Setup FCM

    ==============================

    For line drawing, the DMA controller needs to know the screen layout, specifically,
    what number must be added to the address of a rightmost pixel in one column of FCM
    characters in order to calculate the address of the pixel appearing immediately to its
    right. 
    
    Similarly, it must also know how much must be added to the address of a bottom
    most pixel in one row of FCM characters in order to calculate the address of the pixel
    appearing immediately below it. 
    
    This allows for flexible screen layout options, and arbitrary screen sizes. 
    
    You must then also specify the slope of the line, and whether the line has the X or Y as its major axis, 
    and whether the slope is positive or negative

    The file test_290.c in the https://github.com/mega65/mega65-tools repository
    provides an example of using these facilities to implement hardware accelerated line
    drawing. This is very fast, as it draws lines at the full DMA fill speed, i.e., approximately
    40,500,000 pixels per second.

    * Johns discoveries:
        -   Manual suggests that you don't need vertically setup up screen chars for line draw (only for texture functions).  I think that's incorrect. 
            I could only get line drawing working properly with the screen chars setup like the manual suggests for texture operations
        -   Must prep a general line using the following rules
        -   if (x-major) draw left to right
        -   if (y-major) draw top to bottom
*/

.cpu _45gs02

.var char_step = 80

.const COLOR_RAM        = $ff80000
.const SCREEN_MEMORY    = $0058000
.const CHAR_MEMORY      = $0040000

.macro drawline(ax1, ay1, ax2, ay2, acol) {
        lda #<ax1
        sta x1_lo
        lda #>ax1
        sta x1_hi
        lda #ay1
        sta y1

        lda #<ax2
        sta x2_lo
        lda #>ax2
        sta x2_hi
        lda #ay2
        sta y2

        lda #acol
        sta DrawLine.j_source_col
        jsr DrawLine
}

*= $2001 "UpStart"
BasicUpstart65(Start)

#import "..\includes\m65macros.asm"

*= $2016 "Program" // Note: Needed to add 1 byte here, because the imported library has one byte storage allocated
Start:
        sei

        lda #$35
        sta $01

        lda #$00
        sta $d020
        sta $d021

        lda $d016
        and #$ff-$07 // remove any scroll
        sta $d016

        // enable C64 MCM to access 256 colours
        lda $d016
        ora #$10
        sta $d016

        // resolution 320 x 200
        lda #$20  // Enable extended attributes and 8 bit colour entries
        sta $d031
        
        enable40Mhz()
        enableVIC4Registers()
        disableCIAandIRQ()
        disableC65ROM()
        VIC4_SetScreenLocation(SCREEN_MEMORY)
        VIC4_SetCharLocation(CHAR_MEMORY)

        // char count (Physical columns across screen to show)
        lda #40        
        sta $d05e 

        // char step (Logical columns across the screen to process in byte count)
        lda #<char_step
        sta $d058
        lda #>char_step
        sta $d059
        
        // Super Extended Attribute Mode (and FCLRHI and LO)
        lda #%00000111
        sta $d054

        jsr SetupColorRAM
        jsr SetupScreenRAM
        jsr ClearChars
        cli



MainLoop:
        lda #$ff
    !loop:
        cmp $d012
        bne !loop-

        inc $d020

        // Perform line draws
        drawline(149, 99, 219, 191, 9)
        drawline(159, 99, 219, 191, 2)
        drawline(149, 99, 119, 191, 3)
        drawline(119, 191, 139, 99, 4)

        drawline(159, 99, 319, 89, 5)
        drawline(159, 79, 319, 89, 6)

        drawline(139, 99, 0, 89, 7)
        drawline(139, 79, 0, 89, 8)

        // plot endpoints
        drawline(0, 89, 0, 89, 1)
        drawline(139, 99, 139, 99, 1)
        drawline(139, 79, 139, 79, 1)
        
        drawline(319, 89, 319, 89, 1)
        drawline(159, 99, 159, 99, 1)
        drawline(159, 79, 159, 79, 1)
        
        drawline(159, 99, 159, 99, 1)
        drawline(219, 191, 219, 191, 1)
        drawline(119, 191, 119, 191, 1)

        dec $d020

        jmp MainLoop

DrawLine: {
        // prep line
        
        // check if trying to render a single point, if so just plot.
        lda x1_lo
        cmp x2_lo
        bne !cont+
        lda x1_hi
        cmp x2_hi
        bne !cont+
        lda y1
        cmp y2
        bne !cont+
        
        // set $45-48 will mem for x1, y1
        clc
        lda y1
        sta $45
        lda #$00
        sta $46
        sta $47
        asl $45
        rol $46
        asl $45
        rol $46
        asl $45
        rol $46
        clc
        lda $45
        adc #(CHAR_MEMORY >> 0) & $ff
        sta $45
        lda $46
        adc #(CHAR_MEMORY >> 8) & $ff
        sta $46
        lda $47
        adc #(CHAR_MEMORY >> 16) & $ff
        sta $47
        ldx x1_lo
        lsr x1_hi
        ror x1_lo
        lsr x1_lo
        lsr x1_lo
        ldy x1_lo
        clc
        lda $45
        adc colOffsetLo,y
        sta $45
        lda $46
        adc colOffsetHi,y
        sta $46
        lda $47
        adc #0  // in case of overflow
        sta $47
        txa
        and #$07
        clc
        adc $45
        sta $45
        ldz #$00
        stz $48
        // plot pixel
        lda j_source_col
        nop
        sta ($45),z
        rts
    
    !cont:
    
        // prep hardware divider by zeroing out unused registers (high bytes of MULA and MULB)
        lda #$00
        sta $d771
        sta $d772
        sta $d773
        sta $d775
        sta $d776
        sta $d777

        // setup dx, dy
        sec
        lda x2_lo
        sbc x1_lo
        sta dx_lo
        lda x2_hi
        sbc x1_hi
        sta dx_hi   // this will be #$ff when the whole number is negative
        bpl !cont+
        clc
        lda dx_lo
        eor #$ff
        adc #$01
        sta dx_lo
        lda dx_hi
        eor #$ff
        adc #$00
        sta dx_hi
    !cont:
        sec
        lda y2
        sbc y1
        sta dy
        bpl !cont+
        neg
        sta dy
    !cont:

        // check major axis
        // bigger from dx and dy is major axis
        lda dx_hi
        beq !cont+
        jmp xMajor
    !cont:
        lda dy
        cmp dx_lo
        bcs yMajor
        jmp xMajor
    yMajor: ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // always top down for y-major lines
        lda y2
        cmp y1
        bcs !cont+
        ldy y1
        sta y1  // swap em
        sty y2
        lda x1_lo
        ldy x2_lo
        sta x2_lo
        sty x1_lo
        lda x1_hi
        ldy x2_hi
        sta x2_hi
        sty x1_hi
    !cont:

        // Use hardware divider to get the slope (dx/dy for y-major)
        lda dx_lo
        sta $d770
        lda dx_hi
        sta $d771
        lda dy
        sta $d774

        // setup control (y major and check for neg slope)
        ldx #%11000000
        lda x1_hi
        cmp x2_hi
        bcc !cont+ 
        lda x2_lo
        cmp x1_lo
        bcs !cont+
        ldx #%11100000
    !cont:
        stx j_control+1

        // need to wait 16 cycles till divide is ready, use that time to prep starting addr to draw from
        // ((CHAR_MEMORY + (CENTER_Y << 3) + (CENTER_X & 7) + (CENTER_X >> 3) * 64 * 25) >> 0) & $ff
        clc
        lda y1
        sta j_dest_mem
        lda #$00
        sta j_dest_mem + 1
        sta j_dest_mem + 2
        asl j_dest_mem
        rol j_dest_mem + 1
        asl j_dest_mem
        rol j_dest_mem + 1
        asl j_dest_mem
        rol j_dest_mem + 1
        clc
        lda j_dest_mem
        adc #(CHAR_MEMORY >> 0) & $ff
        sta j_dest_mem
        lda j_dest_mem + 1
        adc #(CHAR_MEMORY >> 8) & $ff
        sta j_dest_mem + 1
        lda j_dest_mem + 2
        adc #(CHAR_MEMORY >> 16) & $ff
        sta j_dest_mem + 2
        ldx x1_lo
        lsr x1_hi
        ror x1_lo
        lsr x1_lo
        lsr x1_lo
        ldy x1_lo
        clc
        lda j_dest_mem
        adc colOffsetLo,y
        sta j_dest_mem
        lda j_dest_mem + 1
        adc colOffsetHi,y
        sta j_dest_mem + 1
        lda j_dest_mem + 2
        adc #0  // in case of overflow
        sta j_dest_mem + 2
        txa
        and #$07
        clc
        adc j_dest_mem
        sta j_dest_mem

        // Update the line slope
        lda $d76a
        sta j_slope + 1
        lda $d76b
        sta j_slope + 3

        // Update the line length
        clc
        lda dy
        adc #$02
        sta j_length
        lda #$00
        adc #$00
        sta j_length + 1

        // draw it
        RunDMAJob(job)
        rts

    xMajor: ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // always left to right for x-major lines
        lda x1_hi
        cmp x2_hi
        bcc !cont+
        lda x2_lo
        cmp x1_lo
        bcs !cont+
        ldy x1_lo
        sta x1_lo
        sty x2_lo
        lda x1_hi
        ldy x2_hi
        sta x2_hi
        sty x1_hi
        lda y2
        ldy y1
        sta y1  // swap em
        sty y2
    !cont:

        // Use hardware divider to get the slope (dy/dx for x-major)
        lda dy
        sta $d770
        lda dx_lo
        sta $d774
        lda dx_hi
        sta $d775

        // setup control (x major and check for neg slope)
        ldx #%10000000
        lda y2
        cmp y1
        bcs !cont+ 
        ldx #%10100000
    !cont:
        stx j_control+1

        // need to wait 16 cycles till divide is ready, use that time to prep starting addr to draw from
        // ((CHAR_MEMORY + (Y << 3) + (X & 7) + (X >> 3) * 64 * 25) >> 0) & $ff
        clc
        lda y1
        sta j_dest_mem
        lda #$00
        sta j_dest_mem + 1
        sta j_dest_mem + 2
        asl j_dest_mem
        rol j_dest_mem + 1
        asl j_dest_mem
        rol j_dest_mem + 1
        asl j_dest_mem
        rol j_dest_mem + 1
        clc
        lda j_dest_mem
        adc #(CHAR_MEMORY >> 0) & $ff
        sta j_dest_mem
        lda j_dest_mem + 1
        adc #(CHAR_MEMORY >> 8) & $ff
        sta j_dest_mem + 1
        lda j_dest_mem + 2
        adc #(CHAR_MEMORY >> 16) & $ff
        sta j_dest_mem + 2
        ldx x1_lo
        lsr x1_hi
        ror x1_lo
        lsr x1_lo
        lsr x1_lo
        ldy x1_lo
        clc
        lda j_dest_mem
        adc colOffsetLo,y
        sta j_dest_mem
        lda j_dest_mem + 1
        adc colOffsetHi,y
        sta j_dest_mem + 1
        lda j_dest_mem + 2
        adc #0  // in case of overflow
        sta j_dest_mem + 2
        txa
        and #$07
        clc
        adc j_dest_mem
        sta j_dest_mem

        // Update the line slope
        lda $d76a
        sta j_slope + 1
        lda $d76b
        sta j_slope + 3

        // Update the line length
        clc
        lda dx_lo
        adc #$02
        sta j_length
        lda dx_hi
        adc #$00
        sta j_length + 1

        // draw it
        RunDMAJob(job)
        rts

    job:
        // DMA Options
        // could be - 8 instead of - 7
        .byte $87, <(1600 - 8) // Set X column bytes (LSB) for line drawing destination address
        .byte $88, >(1600 - 8) // Set X column bytes (MSB) for line drawing destination address

        //.byte $89, <($0) // Set Y row bytes (LSB) for line drawing destination address
        //.byte $8a, >($0) // Set Y row bytes (MSB) for line drawing destination address
    j_slope:
        .byte $8b, 0 //  Slope (LSB) for line drawing destination address
        .byte $8c, 0 //  Slope (MSB) for line drawing destination address
    //j_init_fraction:
        .byte $8d, $00 // Slope accumulator initial fraction (LSB) for line drawing destination address
        .byte $8e, $80 // Slope accumulator initial fraction (MSB) for line drawing destination address

        //  Line Drawing Mode enable and options for destination address (set
        //  in argument byte): Bit 7 = enable line mode, Bit 6 = select X or Y
        //  direction, Bit 5 = slope is negative.
    j_control:
        .byte $8f, %11000000     
        
        .byte $0a       // F018A list format
        .byte $00       // end of options

        // Fill Job
        .byte $03   // Fill and last request
    j_length:    
        .word 102     // length (need to add 2 to this value)
    j_source_col:
        .word 1     // Source - colour
        .byte $00
    j_dest_mem:   
.const StartX = 159
.const StartY = 99 
        .byte ((CHAR_MEMORY + (StartY << 3) + (StartX & 7) + (StartX >> 3) * 64 * 25) >> 0) & $ff
        .byte ((CHAR_MEMORY + (StartY << 3) + (StartX & 7) + (StartX >> 3) * 64 * 25) >> 8) & $ff
        .byte ((CHAR_MEMORY + (StartY << 3) + (StartX & 7) + (StartX >> 3) * 64 * 25) >> 16) & $ff
}


SetupColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$ff)
        DMACopyJob(COLOR_SRC, COLOR_RAM, 1000*2, false, false)
}

SetupScreenRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC, SCREEN_MEMORY, 1000*2, false, false)
}

ClearChars: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$00)
        DMAFillJob(0, CHAR_MEMORY, 1000*64, false)
}

x1_lo:  .byte 0
x1_hi:  .byte 0
y1:     .byte 0
x2_lo:  .byte 0
x2_hi:  .byte 0
y2:     .byte 0
dx_lo:  .byte 0
dx_hi:  .byte 0
dy:     .byte 0

colOffsetLo:
    .fill 40, <(i * 64 * 25)
colOffsetHi:
    .fill 40, >(i * 64 * 25)

SCREEN_SRC:
    //.fillword 1000, i+(CHAR_MEMORY/64)
    .fillword 40, 0 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 1 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 2 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 3 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 4 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 5 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 6 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 7 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 8 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 9 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 10 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 11 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 12 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 13 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 14 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 15 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 16 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 17 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 18 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 19 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 20 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 21 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 22 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 23 + i * 25 +(CHAR_MEMORY/64)
    .fillword 40, 24 + i * 25 +(CHAR_MEMORY/64)
COLOR_SRC:
    .fillword 25*40, $ff00