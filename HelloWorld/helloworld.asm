.cpu _45gs02

#import "..\includes\m65macros.asm"

*= $2001 "UpStart"
BasicUpstart65(Start)

*= $2015 "Program"
Start:
        lda #$00
        sta $d020  

        rts
