/*
    * Johns discoveries:
    -   Manual suggests that you don't need vertically setup up screen chars for line draw (only for texture functions).  I think that's incorrect. 
        I could only get line drawing working properly with the screen chars setup like the manual suggests for texture operations
    -   Must prep a general line using the following rules
    -   if (x-major) draw left to right
    -   if (y-major) draw top to bottom
    -   need to add a value of 2 to the length for the line draw to make it all the way to the endpoint
*/

.cpu _45gs02

.var char_step = 80

.const COLOR_RAM        = $ff80000
.const SCREEN_MEMORY    = $0058000
.const CHAR_MEMORY      = $0040000
.const TEXTURE_MEMORY   = $0030000
.const LINEAR_BUFFER    = $0020000

.macro srcdrawline(ady, asx1, asy1, asx2, asy2) {
        lda #ady
        sta y1

        lda #<asx1
        sta sx1_lo
        lda #>asx1
        sta sx1_hi
        lda #asy1
        sta sy1

        lda #<asx2
        sta sx2_lo
        lda #>asx2
        sta sx2_hi
        lda #asy2
        sta sy2

        jsr DrawLine
        jsr DrawLinearBufferToScreen
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

        ldx #$00
    !loop:
        lda PAL_SRC,x
        tay
        lda PAL_SRC+$100,x
        sta $d100,y
        lda PAL_SRC+$200,x
        sta $d200,y
        lda PAL_SRC+$300,x
        sta $d300,y
        dex
        bne !loop-
        lda #$00
        sta $d100
        sta $d200
        sta $d300
        LoadFile(TEXTURE_MEMORY-2, "DATAV")

MainLoop:
        lda #$ff
    !loop:
        cmp $d012
        bne !loop-

        inc $d020
    
        // Perform line draws
        .for (var y=0;y<200; y++)
        {
           srcdrawline(y, 0, y*2, 640, y*2)
        }

        dec $d020

        jmp MainLoop

DrawLine: {
        // prep line
        // y1 describes the horizontal destination line
        
        // check if trying to render a single point, if so skip
        lda sx1_lo
        cmp sx2_lo
        bne !cont+
        lda sx1_hi
        cmp sx2_hi
        bne !cont+
        lda sy1
        cmp sy2
        bne !cont+
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
        lda sx2_lo
        sbc sx1_lo
        sta sdx_lo
        lda sx2_hi
        sbc sx1_hi
        sta sdx_hi   // this will be #$ff when the whole number is negative
        bpl !cont+
        clc
        lda sdx_lo
        eor #$ff
        adc #$01
        sta sdx_lo
        lda sdx_hi
        eor #$ff
        adc #$00
        sta sdx_hi
    !cont:
        sec
        lda sy2
        sbc sy1
        sta sdy
        bpl !cont+
        neg
        sta sdy
    !cont:

        // check major axis
        // bigger from dx and dy is major axis
        lda sdx_hi
        beq !cont+
        jmp xMajor
    !cont:
        lda sdy
        cmp sdx_lo
        bcs yMajor
        jmp xMajor
    yMajor: ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // always top down for y-major lines
        lda sy2
        cmp sy1
        bcs !cont+
        ldy sy1
        sta sy1  // swap em
        sty sy2
        lda sx1_lo
        ldy sx2_lo
        sta sx2_lo
        sty sx1_lo
        lda sx1_hi
        ldy sx2_hi
        sta sx2_hi
        sty sx1_hi
    !cont:

        // Use hardware divider to get the slope (dx/dy for y-major)
        lda sdx_lo
        sta $d770
        lda sdx_hi
        sta $d771
        lda sdy
        sta $d774

        // setup control (y major and check for neg slope)
        ldx #%11000000
        lda sx1_hi
        cmp sx2_hi
        bcc !cont+ 
        lda sx2_lo
        cmp sx1_lo
        bcs !cont+
        ldx #%11100000
    !cont:
        stx sj_control+1

        // need to wait 16 cycles till divide is ready, use that time to prep starting addr to draw from
        // ((CHAR_MEMORY + (CENTER_Y << 3) + (CENTER_X & 7) + (CENTER_X >> 3) * 64 * 25) >> 0) & $ff
        clc
        lda sy1
        sta j_source_mem
        lda #$00
        sta j_source_mem + 1
        sta j_source_mem + 2
        asl j_source_mem
        rol j_source_mem + 1
        asl j_source_mem
        rol j_source_mem + 1
        asl j_source_mem
        rol j_source_mem + 1
        clc
        lda j_source_mem
        adc #(TEXTURE_MEMORY >> 0) & $ff
        sta j_source_mem
        lda j_source_mem + 1
        adc #(TEXTURE_MEMORY >> 8) & $ff
        sta j_source_mem + 1
        lda j_source_mem + 2
        adc #(TEXTURE_MEMORY >> 16) & $ff
        sta j_source_mem + 2
        ldx sx1_lo
        lsr sx1_hi
        ror sx1_lo
        lsr sx1_lo
        lsr sx1_lo
        ldy sx1_lo
        clc
        lda j_source_mem
        adc colOffsetLo,y
        sta j_source_mem
        lda j_source_mem + 1
        adc colOffsetHi,y
        sta j_source_mem + 1
        lda j_source_mem + 2
        adc #0  // in case of overflow
        sta j_source_mem + 2
        txa
        and #$07
        clc
        adc j_source_mem
        sta j_source_mem

        // Update the line slope
        lda $d76a
        sta sj_slope + 1
        lda $d76b
        sta sj_slope + 3

        // Update the line length
        clc
        lda sdy
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
        lda sx1_hi
        cmp sx2_hi
        bcc !cont+
        lda sx2_lo
        cmp sx1_lo
        bcs !cont+
        ldy sx1_lo
        sta sx1_lo
        sty sx2_lo
        lda sx1_hi
        ldy sx2_hi
        sta sx2_hi
        sty sx1_hi
        lda sy2
        ldy sy1
        sta sy1  // swap em
        sty sy2
    !cont:

        // Use hardware divider to get the slope (dy/dx for x-major)
        lda sdy
        sta $d770
        lda sdx_lo
        sta $d774
        lda sdx_hi
        sta $d775

        // setup control (x major and check for neg slope)
        ldx #%10000000
        lda sy2
        cmp sy1
        bcs !cont+ 
        ldx #%10100000
    !cont:
        stx sj_control+1

        // need to wait 16 cycles till divide is ready, use that time to prep starting addr to draw from
        // ((CHAR_MEMORY + (Y << 3) + (X & 7) + (X >> 3) * 64 * 25) >> 0) & $ff
        clc
        lda sy1
        sta j_source_mem
        lda #$00
        sta j_source_mem + 1
        sta j_source_mem + 2
        asl j_source_mem
        rol j_source_mem + 1
        asl j_source_mem
        rol j_source_mem + 1
        asl j_source_mem
        rol j_source_mem + 1
        clc
        lda j_source_mem
        adc #(TEXTURE_MEMORY >> 0) & $ff
        sta j_source_mem
        lda j_source_mem + 1
        adc #(TEXTURE_MEMORY >> 8) & $ff
        sta j_source_mem + 1
        lda j_source_mem + 2
        adc #(TEXTURE_MEMORY >> 16) & $ff
        sta j_source_mem + 2
        ldx sx1_lo
        lsr sx1_hi
        ror sx1_lo
        lsr sx1_lo
        lsr sx1_lo
        ldy sx1_lo
        clc
        lda j_source_mem
        adc colOffsetLo,y
        sta j_source_mem
        lda j_source_mem + 1
        adc colOffsetHi,y
        sta j_source_mem + 1
        lda j_source_mem + 2
        adc #0  // in case of overflow
        sta j_source_mem + 2
        txa
        and #$07
        clc
        adc j_source_mem
        sta j_source_mem

        // Update the line slope
        lda $d76a
        sta sj_slope + 1
        lda $d76b
        sta sj_slope + 3

        // Update the line length
        clc
        lda sdx_lo
        adc #$02
        sta j_length
        lda sdx_hi
        adc #$00
        sta j_length + 1

        // draw it
        RunDMAJob(job)
        rts

    job:
        // DMA Options
        //.byte $87, <(1600 - 8) // Set X column bytes (LSB) for line drawing destination address
        //.byte $88, >(1600 - 8) // Set X column bytes (MSB) for line drawing destination address
        //.byte $89, <($0) // Set Y row bytes (LSB) for line drawing destination address
        //.byte $8a, >($0) // Set Y row bytes (MSB) for line drawing destination address
        .byte $97, <(1600 - 8) // Set X column bytes (LSB) for line drawing destination address
        .byte $98, >(1600 - 8) // Set X column bytes (MSB) for line drawing destination address
        //.byte $89, <($0) // Set Y row bytes (LSB) for line drawing destination address
        //.byte $8a, >($0) // Set Y row bytes (MSB) for line drawing destination address
    j_slope:
        .byte $8b, 0 //  Slope (LSB) for line drawing destination address
        .byte $8c, 0 //  Slope (MSB) for line drawing destination address
    sj_slope:
        .byte $9b, 0 //  Slope (LSB) for line drawing destination address
        .byte $9c, 0 //  Slope (MSB) for line drawing destination address

        //  Line Drawing Mode enable and options for destination address (set
        //  in argument byte): Bit 7 = enable line mode, Bit 6 = select X or Y
        //  direction, Bit 5 = slope is negative.
    j_control:
        .byte $8f, %10100000
    sj_control:     
        .byte $9f, %11000000     

    // j_skip_rates:
    //     .byte $82, $ff //Source skip rate (256ths of bytes)
    //     .byte $83, $ff //Source skip rate (whole bytes)
    //     .byte $84, $ff //Destination skip rate (256ths of bytes)
    //     .byte $85, $ff //Destination skip rate (whole bytes)

        .byte $0a       // F018A list format
        .byte $00       // end of options

        // Copy Job
        .byte $00   // Copy and last request
    j_length:    
        .word 320     // length (need to add 2 to this value)
    j_source_mem:
        .byte ((TEXTURE_MEMORY) >> 0) & $ff
        .byte ((TEXTURE_MEMORY) >> 8) & $ff
        .byte ((TEXTURE_MEMORY) >> 16) & $ff
    j_dest_mem:   
        .byte ((LINEAR_BUFFER) >> 0) & $ff
        .byte ((LINEAR_BUFFER) >> 8) & $ff
        .byte ((LINEAR_BUFFER) >> 16) & $ff
}

DrawLinearBufferToScreen: {
        // prep dest mem
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
        
        // draw it
        RunDMAJob(job)
        rts

    job:
        // DMA Options
        .byte $87, <(1600 - 8) // Set X column bytes (LSB) for line drawing destination address
        .byte $88, >(1600 - 8) // Set X column bytes (MSB) for line drawing destination address
        //.byte $89, <($8) // Set Y row bytes (LSB) for line drawing destination address
        //.byte $8a, >($8) // Set Y row bytes (MSB) for line drawing destination address
        //.byte $97, <(1600 - 8) // Set X column bytes (LSB) for line drawing destination address
        //.byte $98, >(1600 - 8) // Set X column bytes (MSB) for line drawing destination address

        //  Line Drawing Mode enable and options for destination address (set
        //  in argument byte): Bit 7 = enable line mode, Bit 6 = select X or Y
        //  direction, Bit 5 = slope is negative.
        .byte $82, $00 //Source skip rate (256ths of bytes)
        .byte $83, $02 //Source skip rate (whole bytes)
        .byte $89, $00
        .byte $8a, $00
        .byte $8b, $00
        .byte $8c, $00
        .byte $8d, $00
        .byte $8e, $00
        .byte $8f, %10000000

        .byte $0a       // F018A list format
        .byte $00       // end of options

        // Copy Job
        .byte $00   // Copy and last request
    j_length:    
        .word 320     // length (need to add 2 to this value)
    j_source_mem:
        .byte ((LINEAR_BUFFER) >> 0) & $ff
        .byte ((LINEAR_BUFFER) >> 8) & $ff
        .byte ((LINEAR_BUFFER) >> 16) & $ff
    j_dest_mem:   
        .byte ((CHAR_MEMORY) >> 0) & $ff
        .byte ((CHAR_MEMORY) >> 8) & $ff
        .byte ((CHAR_MEMORY) >> 16) & $ff        
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

// line draw variables
y1:     .byte 0

sx1_lo:  .byte 0
sx1_hi:  .byte 0
sy1:     .byte 0

sx2_lo:  .byte 0
sx2_hi:  .byte 0
sy2:     .byte 0

sdx_lo:  .byte 0
sdx_hi:  .byte 0
sdy:     .byte 0

// column offsets for line draw
colOffsetLo:
    .fill 40, <(i * 64 * 25)
colOffsetHi:
    .fill 40, >(i * 64 * 25)

// vertical 
SCREEN_SRC:
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

#import "..\includes\Fast_Loader_KickAss.asm"

.align $100
CHAR_SRC:
*= * "Image Data"
.var colsHT = Hashtable()
.var colIndex = 1
.var graflogo = LoadPicture("3d-graffiti.png")
.for (var x1=0;x1<40; x1++)
    .for (var y=0; y<200; y++)
        .for (var x=0;x<8; x++)
        {
            .var c = graflogo.getPixel(x1*8+x, y)
            .if (colsHT.containsKey(c))
            {
                //.byte colsHT.get(c)
            }
            else
            {
                //.byte colIndex
                .eval colsHT.put(c, colIndex)
                .eval colIndex = colIndex + 1
            }
        }

.print "------"
.print colIndex
.print "------"
.align $100
PAL_SRC:
.var colKeys = colsHT.keys()
* = * "Palette Data"
.for (var i=0; i<colKeys.size(); i++) 
{
    .byte colsHT.get(colKeys.get(i))
}
.align $100

.for (var i=0; i<colKeys.size(); i++) 
{
    .var c = colKeys.get(i).asNumber()
    .var r = ((c >> 16) & $0000ff) >> 4
    .byte r
}

.align $100
.for (var i=0; i<colKeys.size(); i++) 
{
    .var c = colKeys.get(i).asNumber() 
    .byte ((c >> 8) & $0000ff) >> 4
}
.align $100
.for (var i=0; i<colKeys.size(); i++) 
{
    .var c = colKeys.get(i).asNumber() 
    .byte (c & $0000ff) >> 4
}