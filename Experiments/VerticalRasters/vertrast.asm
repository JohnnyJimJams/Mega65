/*
    Directly ported from the mega manual
*/

.cpu _45gs02
#import "..\includes\m65macros.asm"

*= $2001 "UpStart"
BasicUpstart65(Start)

*= $2015 "Program"
//// Actual code begining at $080d = 2061
Start:
        sei
        lda #$47 // enable MEGA65 I/O
        sta $D02f
        lda #$53
        sta $d02f
        lda #65 // Set CPU speed to fast
        sta 0
        lda #0 // disable screen to show only the border
        sta $d011

        lda $d012 // Wait until start of the next raster
    raster_sync: // before beginning loop for horizontal alignment
        cmp $d012
        beq raster_sync
        //// The following loop takes exactly one raster line at 40.5MHz in PAL
    
    loop:
        jsr triggerdma
        jmp loop
    
    triggerdma:
        lda #0 // make sure F018 list format
        sta $d703
        lda #0 // dma list bank
        sta $d702
        lda #>rasterdmalist
        sta $d701
        lda #<rasterdmalist
        sta $d705
        rts

rasterdmalist:
    .byte $81,$ff,$00
    .byte $00 // COPY
    .word 619 // DMA transfer is 619 bytes long
    .word rastercolours // source address
    .byte $00 // source bank
    .word $0020 // destination address
    .byte $1d // destination bank + HOLD
    //// unused modulo field
    .word $0000

rastercolours:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,11,11,11,12,12,12,15,15,15,1,1,1,15,15,15,12,12,12,11,11,11,0,0,0
    .byte 0,0,0,6,6,6,4,4,4,14,14,14,3,3,3,1,1,1,3,3,3,14,14,14,4,4,4,6,6,6,0,0,0
    .byte 0,0,0,11,11,11,12,12,12,15,15,15,1,1,1,15,15,15,12,12,12,11,11,11,0,0,0
    .byte 0,0,0,6,6,6,4,4,4,14,14,14,3,3,3,1,1,1,3,3,3,14,14,14,4,4,4,6,6,6,0,0,0
    .byte 0,0,0,11,11,11,12,12,12,15,15,15,1,1,1,15,15,15,12,12,12,11,11,11,0,0,0
    .byte 0,0,0,6,6,6,4,4,4,14,14,14,3,3,3,1,1,1,3,3,3,14,14,14,4,4,4,6,6,6,0,0,0
    .byte 0,0,0,11,11,11,12,12,12,15,15,15,1,1,1,15,15,15,12,12,12,11,11,11,0,0,0
    .byte 0,0,0,6,6,6,4,4,4,14,14,14,3,3,3,1,1,1,3,3,3,14,14,14,4,4,4,6,6,6,0,0,0
    .byte 0,0,0,11,11,11,12,12,12,15,15,15,1,1,1,15,15,15,12,12,12,11,11,11,0,0,0
    .byte 0,0,0,6,6,6,4,4,4,14,14,14,3,3,3,1,1,1,3,3,3,14,14,14,4,4,4,6,6,6,0,0,0
    .byte 0,0,0,11,11,11,12,12,12,15,15,15,1,1,1,15,15,15,12,12,12,11,11,11,0,0,0
    .byte 0,0,0,6,6,6,4,4,4,14,14,14,3,3,3,1,1,1,3,3,3,14,14,14,4,4,4,6,6,6,0,0,0
    .byte 0,0,0,11,11,11,12,12,12,15,15,15,1,1,1,15,15,15,12,12,12,11,11,11,0,0,0
    .byte 0,0,0,6,6,6,4,4,4,14,14,14,3,3,3,1,1,1,3,3,3,14,14,14,4,4,4,6,6,6,0,0,0
    .byte 0,0,0,11,11,11,12,12,12,15,15,15,1,1,1,15,15,15,12,12,12,11,11,11,0,0,0
    .byte 0,0,0,6,6,6,4,4,4,14,14,14,3,3,3,1,1,1,3,3,3,14,14,14,4,4,4,6,6,6,0,0,0
    .byte 0,0,0,11,11,11,12,12,12,15,15,15,1,1,1,15,15,15,12,12,12,11,11,11,0,0,0
    .byte 0,0,0,6,6,6,4,4,4,14,14,14,3,3,3,1,1,1,3,3,3,14,14,14,4,4,4,6,6,6,0,0,0