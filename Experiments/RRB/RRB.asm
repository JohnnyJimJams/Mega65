.cpu _45gs02

.const COLOR_RAM        = $ff80000
.const SCREEN_MEMORY    = $0008000

*= $2001 "UpStart"
BasicUpstart65(Start)

#import "..\..\includes\m65macros.asm"

.var ROWSIZE = (40 + 4)
.var LOGICAL_ROWSIZE = ROWSIZE * 2

*= $2016 "Program" // Note: Needed to add 1 byte here, because the imported library has one byte storage allocated
Start:
        sei

        lda #$35
        sta $01

        lda #$00
        sta $d020
        sta $d021

        // lda $d016
        // and #$ff-$07 // remove any scroll
        // sta $d016

        // resolution and extended attribs
        lda #%00100000  // Enable extended attributes for 8 bit colour entries and hires 640 x 400
        tsb $d031
        lda #%10001000
        trb $d031

        enable40Mhz()
        enableVIC4Registers()
        disableCIAandIRQ()
        disableC65ROM()
        VIC4_SetScreenLocation(SCREEN_MEMORY)

        lda #%11111000
        trb $d030

        // char count (Physical columns across screen to show)
        lda #ROWSIZE
        sta $d05e 

        // char step (Logical columns across the screen to process in byte count)
        lda #<LOGICAL_ROWSIZE
        sta $d058
        lda #>LOGICAL_ROWSIZE
        sta $d059
        
        // Super Extended Attribute Mode 
        lda #%00000101
        tsb $d054

        jsr SetupColorRAM
        jsr SetupScreenRAM
        
        cli 

MainLoop:
        lda #$ff
    !:
        cmp $d012
        bne !-

    !:
        cmp $d012
        beq !-

        inc $d020

        inc yOffset
        lda yOffset
        and #$07
        sta yOffset
        asl
        asl
        asl
        asl
        asl
        sta SCREEN_MEMORY + 80 + 1        

        jmp MainLoop

yOffset:
    .byte 0

SetupColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$ff)
        DMACopyJob(COLOR_SRC, COLOR_RAM, LOGICAL_ROWSIZE * 25, false, false)
}

SetupScreenRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC, SCREEN_MEMORY, LOGICAL_ROWSIZE * 25, false, false)
}

SCREEN_SRC:
    .for (var y=0; y<25; y++)
    {
        .fillword 40, i
        .word $00a0     // xpos for layer 1
        .word $101         // layer 1
        .word 320       // last x pos
        .word 0         // final character
    }
COLOR_SRC:
    .for (var y=0; y<25; y++)
    {
        .fillword 40, $0100
        .word $0090         // goto set, transp
        .word $0308         // layer 1 colour (hi), ncm (lo bit 3)
        .word $0010         // goto set, no transp, last x pos
        .word $0300         // final character color
    }
