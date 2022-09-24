.cpu _45gs02

.var char_step = 80

.const COLOR_RAM        = $ff80000
.const SCREEN_MEMORY    = $0058000
.const CHAR_MEMORY      = $0040000

*= $2001 "UpStart"
BasicUpstart65(Start)

#import "..\includes\m65macros.asm"

*= $2016 "Program" // Note: Needed to add 1 byte here, because the imported library has one byte storage allocated
Start:
        sei
        
        lda yposLo
        sta $d04e
        lda yposHi
        sta $d04f

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

        jsr ClearColorRAM
        jsr ClearScreenRAM
        jsr SetupColorRAM
        jsr SetupScreenRAM
        
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
        LoadFile(CHAR_MEMORY-2, "DATA")

MainLoop:
        lda $d012
        taz

        clc
        adc waveCounter
        tay

        tza
        clc
        adc waveCounter + 1
        tax

        clc
        lda SinTable1Lo,y
        adc SinTable2Lo,x
        sta wacc
        lda SinTable1Hi,y
        adc SinTable2Hi,x
        sta wacc+1

        tza
        clc
        adc waveCounter + 2
        tay

        clc
        lda wacc
        adc SinTable3Lo,y
        taz
        lda wacc+1
        adc SinTable3Hi,y

        ldx $d012
    !loop:
        cpx $d012
        beq !loop-

        stz $d04c // Low x offset
        sta $d04d // Low x offset

        cpx #$ff
        bne !notPerFrame+
    
        // do per frame stuff here
        inc waveCounter+2
        inc waveCounter
        lda waveCounter
        and #$01
        bne !skip+
        inc waveCounter+1
    !skip:

        lda ypos
        cmp #63
        beq !cont+

        inc ypos
        ldy ypos
        lda yposLo,y
        sta $d04e
        lda yposHi,y
        sta $d04f
    !cont:

    !notPerFrame:
        jmp MainLoop

ClearColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$ff)
        DMAFillJob(%00000001, COLOR_RAM, 1000*2, false)
}

ClearScreenRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$00)
        DMAFillJob(1, SCREEN_MEMORY, 1000*2, false)
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

#import "..\includes\Fast_Loader_KickAss.asm"

SCREEN_SRC:
    .fillword 1000, i+(CHAR_MEMORY/64)
COLOR_SRC:
    .fillword 25*40, $ff00
waveCounter:
    .byte 0
    .byte 0
    .byte 0
wacc:
    .word 0
ypos:
    .byte 0

.align $100
SinTable1Lo:
    .fill 256, <(80.0 + 29.0 * sin(i/128*3.14159))
SinTable1Hi:
    .fill 256, >(80.0 + 29.0 * sin(i/128*3.14159))
SinTable2Lo:
    .fill 256, <(15.0 * sin((i+32)/64*3.14159))
SinTable2Hi:
    .fill 256, >(15.0 * sin((i+32)/64*3.14159))
SinTable3Lo:
    .fill 256, <(9.0 * sin(i/32*3.14159))
SinTable3Hi:
    .fill 256, >(9.0 * sin(i/32*3.14159))
yposLo:
    .fill 64, <(101 + (504-i*8))
yposHi:
    .fill 64, >(101 + (504-i*8))

.align $100
CHAR_SRC:
*= * "Image Data"
.var colsHT = Hashtable()
.var colIndex = 1
.var graflogo = LoadPicture("3d-graffiti.png")
.for (var y1=0; y1<25; y1++)
    .for (var x1=0;x1<40; x1++)
        .for (var y=0; y<8; y++)
            .for (var x=0;x<8; x++)
            {
                .var c = graflogo.getPixel(x1*8+x, y1*8+y)
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