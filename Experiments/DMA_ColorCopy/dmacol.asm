.cpu _45gs02

.const COLOR_RAM        = $ff80000

*= $2001 "UpStart"
BasicUpstart65(Start)

#import "..\..\includes\m65macros.asm"

*= $2016 "Program" // Note: Needed to add 1 byte here, because the imported library has one byte storage allocated
Start:
        // using 32 bit addressing nop: lda ($f0),z works
        lda #(COLOR_RAM >> 0) & $ff
        sta $f0
        lda #(COLOR_RAM >> 8) & $ff
        sta $f1
        lda #(COLOR_RAM >> 16) & $ff
        sta $f2
        lda #(COLOR_RAM >> 24) & $ff
        sta $f3
        ldz #$00
        nop
        lda ($f0),z
        ldz #80
        nop
        sta ($f0),z

        jsr DMACopyColorRAM
        
        rts

DMACopyColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM, COLOR_RAM+160, 30, false, false)
}
