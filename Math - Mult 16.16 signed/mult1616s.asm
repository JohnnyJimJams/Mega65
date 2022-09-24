.cpu _45gs02
#import "..\includes\m65macros.asm"

*= $2001 "UpStart"
BasicUpstart65(Start)


// fpval1 * fpval2 = 422.479375
// 

*= $2015 "Program"
Start:
    lda #$00
    sta $d020


    // Test unsigned 
.const fpval1 = 25.625
.const fpval2 = 16.487
    LDIU_MULTINA(fpval1)
    LDIU_MULTINB(fpval2)
    LDQU_1616()

    // Test signed 
.const fpval1 = -25.625
.const fpval2 = 16.487
    LDIS_MULTINA(fpval1)
    LDIS_MULTINB(fpval2)
    LDQS_1616()

    // result should be immediately available in MULTOUT
    // result in RAM here is correct \o/
    // m 800d778 (that shows the whole 64 bit result)
    // m 800d77a (these 4 bytes are the 16.16 fixed point result)  

    brk // to monitor