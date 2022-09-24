/*
    The docs say that the visible area on PAL units are 720 x 576 pixels.  Let's test that 
*/
.cpu _45gs02


.var char_step = 80

.const COLOR_RAM        = $ff80000
.const SCREEN_MEMORY    = $0010000
.const CHAR_MEMORY      = $0018000

*= $2001 "UpStart"
BasicUpstart65(Start)

#import "..\includes\m65macros.asm"

*= $2016 "Program" // Note: Needed to add 1 byte here, because the imported library has one byte storage allocated
Start:
       sei
        
        lda #$35
        sta $01

        lda #$00
        sta $d021

        lda $d016
        ora #$10
        sta $d016

        // resolution 320 x 200
        lda #$20
        sta $d031
        
        enable40Mhz()
        enableVIC4Registers()
        disableCIAandIRQ()
        disableC65ROM()
        VIC4_SetScreenLocation(SCREEN_MEMORY)
        VIC4_SetCharLocation(CHAR_MEMORY)

        // char count (Physical columns across screen to show)
        lda #40        // 800 pixels wide with no borders and H640 set
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
        jsr SetupCharRAM
        cli

        // Super Extended Attribute Mode
        lda #%00000001
        sta $d054

        jmp *

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
        DMAHeader(1,$00)
        DMAFillJob(1, SCREEN_MEMORY, 1000*2, false)
}

SetupColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$ff)
        DMACopyJob(COLOR_SRC, COLOR_RAM, 32, false, false)
}

SetupScreenRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC, SCREEN_MEMORY, 32, false, false)
}

SetupCharRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,0)
        DMAFillJob(%11111111, CHAR_MEMORY, 8192, false)
}

SCREEN_SRC:
    .word $0201, $0202, $0203, $0004, $0005, $0006, $0007, $0008
    .word $0009, $000a, $000b, $000c, $000d, $000e, $000f, $0010
COLOR_SRC:
    .word $1100, $1200, $1300, $1400, $1500, $1600, $1700, $1800
    .word $0900, $0a00, $0b00, $0c00, $0d00, $0e00, $0f00, $1200