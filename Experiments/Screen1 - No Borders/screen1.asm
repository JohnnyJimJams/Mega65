/*
    The docs say that the visible area on PAL units are 720 x 576 pixels.  Let's test that 
*/

.cpu _45gs02
#import "..\includes\m65macros.asm"

.var bottom_border_pos = 623    // Why do I need to set this to 624 lines high when the docs say the visible area is 576 high?  
                                // 624 is all raster lines!  Does the emu show all lines?

.var side_border_width = 0

.var char_step = 100

*= $2001 "UpStart"
BasicUpstart65(Start)

*= $2015 "Program"
Start:
        lda #$0f
        sta $d020       // White border to see what's what

        lda $d031
        ora #%10001000
        sta $d031

        // borders

        lda #$00
        sta $d048       // Top Border Pos
        lda $d049
        and #%11110000
        sta $d049

        lda #<bottom_border_pos
        sta $d04a       // Bottom Border Pos
        lda $d04b
        and #%11110000
        ora #>bottom_border_pos
        sta $d04b

        lda #<side_border_width // side borders
        sta $d05c
        lda $d05d        
        and #%11000000
        ora #>side_border_width
        sta $d05d

        // Screen position

        // TEXTXPOS (Screen left side position)
        lda #$01        // note position 0 doesn't work on real hardware!  need to set minimum of 1
        sta $d04c
        lda $d04d
        and #%11110000
        sta $d04d

        // TEXTYPOS (Screen top position)
        lda #$01        // note position 0 doesn't work on real hardware!  need to set minimum of 1
        sta $d04e
        lda $d04f
        and #%11110000
        sta $d04f

        // display rows
        lda #77     // (624 / 8) - 1
        sta $d07b

        // char count (Physical columns across screen to show)
        lda #100        // 800 pixels wide with no borders and H640 set
        sta $d05e

        // char step (Logical columns across the screen to process in byte count)
        lda #<char_step
        sta $d058
        lda #>char_step
        sta $d059

        rts

