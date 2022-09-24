.cpu _45gs02
#import "..\includes\m65macros.asm"

.const SRC_RAM     = $8000000
.const DEST_MEM    = $0010000

*= $2001 "UpStart"
BasicUpstart65(Start)

*= $2015 "Program"
Start:
        sei
        
        lda #$35
        sta $01
        enable40Mhz()
        enableVIC4Registers()
        disableCIAandIRQ()
        disableC65ROM()
        cli
Main:
        lda #60
    !loop:
        cmp $d012
        bne !loop-
        inc $d020
        jsr CopyAtticToFast
        dec $d020
        jmp Main

CopyAtticToFast: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader($80,$00)
        DMACopyJob(SRC_RAM, DEST_MEM, 16384, false, false)
}