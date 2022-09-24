.cpu _45gs02

.var char_step = 160

.const COLOR_RAM        = $ff80000
.const SCREEN_MEMORY    = $0018000
.const CHAR_MEMORY      = $0020000

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

        // resolution and extended attribs
        lda #10101000  // Enable extended attributes for 8 bit colour entries and hires 640 x 400
        tsb $d031
        
        enable40Mhz()
        enableVIC4Registers()
        disableCIAandIRQ()
        disableC65ROM()
        VIC4_SetScreenLocation(SCREEN_MEMORY)
        VIC4_SetCharLocation(CHAR_MEMORY)

        // char count (Physical columns across screen to show)
        lda #80        
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
        LoadFile(CHAR_MEMORY-2, "DATAH")

MainLoop:
        //inc $d020

        jmp MainLoop

ClearColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$ff)
        DMAFillJob(%00000001, COLOR_RAM, 4000*2, false)
}

ClearScreenRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$00)
        DMAFillJob(1, SCREEN_MEMORY, 4000*2, false)
}

SetupColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$ff)
        DMACopyJob(COLOR_SRC, COLOR_RAM, 4000*2, false, false)
}

SetupScreenRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC, SCREEN_MEMORY, 4000*2, false, false)
}

#import "..\includes\Fast_Loader_KickAss.asm"

SCREEN_SRC:
    .for (var y=0; y<50; y++)
    {
        .fillword 80, y + i * 50 +(CHAR_MEMORY/64)
    }
COLOR_SRC:
    .fillword 80*50, $ff00

.align $100
*= * "Image Data"
.var colsHT = Hashtable()
.var colIndex = 1
.var graflogo = LoadPicture("assets/logo1_640_296_q255.png")
.for (var x1=0;x1<80; x1++)
    .for (var y=0; y<400; y++)
        .for (var x=0;x<8; x++)
        {
            .var c = 0
            .if (y<296)
            {
                .eval c = graflogo.getPixel(x1*8+x, y)
            }
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