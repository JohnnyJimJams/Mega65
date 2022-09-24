.cpu _45gs02

.const COLOR_RAM        = $ff80000

*= $2001 "UpStart"
BasicUpstart65(Start)

#import "..\..\includes\m65macros.asm"

.var ROWSIZE = 54 
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
        // ora #$10    // enable C64 MCM to access 256 colours
        // sta $d016
        
        // resolution and extended attribs
        lda #%00100000  // Enable extended attributes for 8 bit colour entries and hires 640 x 400
        trb $d031
        lda #%10001000  // Resolution 320x200
        trb $d031

        enable40Mhz()
        enableVIC4Registers()
        disableCIAandIRQ()
        disableC65ROM()
        VIC4_SetScreenLocation(SCREEN_SRC)

        lda #%11111000  // disable roms
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
        lda #%00000111
        tsb $d054

        jsr SetupColorRAM
        
        cli 

        ldx #$1f
    !loop:
        lda PALETTER,x
        sta $d100,x
        lda PALETTEG,x
        sta $d200,x
        lda PALETTEB,x
        sta $d300,x
        dex
        bpl !loop-

MainLoop:
        lda #$ff
    !:
        cmp $d012
        bne !-

    !:
        cmp $d012
        beq !-

        // scroll layers
        dec layer1X
        lda layer1X
        cmp #$f0
        bne !skip+
        lda #$00
        sta layer1X
        jsr HardScrollLayer1
    !skip:
        lda layer1X
        and #$01
        bne !skip+
        dec layer0X
        lda layer0X
        cmp #$f0
        bne !skip+
        lda #$00
        sta layer0X
        jsr HardScrollLayer0
    !skip:

        ldx #0
    !loop:
        lda Layer0XPtrLo,x
        sta $f0
        lda Layer0XPtrHi,x
        sta $f1
        ldy #$00
        lda layer0X
        sta ($f0),y
        tya
        iny
        sta ($f0),y
        lda layer0X
        bpl !skip+
        lda #$03
        sta ($f0),y
    !skip:    
        inx
        cpx #25
        bne !loop-

        ldx #24
    !loop:
        lda Layer1XPtrLo,x
        sta $f0
        lda Layer1XPtrHi,x
        sta $f1
        ldy #$00
        lda layer1X
        sta ($f0),y
        tya
        iny
        sta ($f0),y
        lda layer1X
        bpl !skip+
        lda #$03
        sta ($f0),y
    !skip:    
        dex
        bpl !loop-

        jmp MainLoop

HardScrollLayer0:
        {
        RunDMAJob(s00)
        RunDMAJob(c00)
        RunDMAJob(s01)
        RunDMAJob(c01)
        RunDMAJob(s02)
        RunDMAJob(c02)
        RunDMAJob(s03)
        RunDMAJob(c03)
        RunDMAJob(s04)
        RunDMAJob(c04)
        RunDMAJob(s05)
        RunDMAJob(c05)
        RunDMAJob(s06)
        RunDMAJob(c06)
        RunDMAJob(s07)
        RunDMAJob(c07)
        RunDMAJob(s08)
        RunDMAJob(c08)
        RunDMAJob(s09)
        RunDMAJob(c09)
        RunDMAJob(s10)
        RunDMAJob(c10)
        RunDMAJob(s11)
        RunDMAJob(c11)
        RunDMAJob(s12)
        RunDMAJob(c12)
        RunDMAJob(s13)
        RunDMAJob(c13)
        RunDMAJob(s14)
        RunDMAJob(c14)
        RunDMAJob(s15)
        RunDMAJob(c15)
        RunDMAJob(s16)
        RunDMAJob(c16) 
        RunDMAJob(s17)
        RunDMAJob(c17)
        RunDMAJob(s18)
        RunDMAJob(c18)
        RunDMAJob(s19)
        RunDMAJob(c19)
        RunDMAJob(s20)
        RunDMAJob(c20)
        RunDMAJob(s21)
        RunDMAJob(c21)
        RunDMAJob(s22)
        RunDMAJob(c22)
        RunDMAJob(s23)
        RunDMAJob(c23)

        rts

    s00:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 0, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 0, 48, false, false)
    c00:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 0, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 0, 48, false, false)
    s01:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 1, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 1, 48, false, false)
    c01:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 1, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 1, 48, false, false)
    s02:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 2, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 2, 48, false, false)
    c02:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 2, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 2, 48, false, false)
    s03:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 3, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 3, 48, false, false)
    c03:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 3, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 3, 48, false, false)
    s04:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 4, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 4, 48, false, false)
    c04:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 4, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 4, 48, false, false)
    s05:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 5, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 5, 48, false, false)
    c05:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 5, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 5, 48, false, false)
    s06:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 6, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 6, 48, false, false)
    c06:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 6, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 6, 48, false, false)
    s07:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 7, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 7, 48, false, false)
    c07:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 7, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 7, 48, false, false)      
    s08:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 8, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 8, 48, false, false)
    c08:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 8, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 8, 48, false, false)
    s09:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 9, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 9, 48, false, false)
    c09:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 9, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 9, 48, false, false)
    s10:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 10, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 10, 48, false, false)
    c10:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 10, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 10, 48, false, false)
    s11:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 11, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 11, 48, false, false)
    c11:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 11, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 11, 48, false, false)
    s12:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 12, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 12, 48, false, false)
    c12:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 12, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 12, 48, false, false)
    s13:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 13, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 13, 48, false, false)
    c13:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 13, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 13, 48, false, false)
    s14:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 14, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 14, 48, false, false)
    c14:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 14, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 14, 48, false, false)
    s15:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 15, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 15, 48, false, false)
    c15:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 15, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 15, 48, false, false) 
    s16:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 16, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 16, 48, false, false)
    c16:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 16, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 16, 48, false, false)
    s17:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 17, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 17, 48, false, false)
    c17:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 17, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 17, 48, false, false)
    s18:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 18, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 18, 48, false, false)
    c18:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 18, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 18, 48, false, false)
    s19:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 19, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 19, 48, false, false)
    c19:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 19, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 19, 48, false, false)
    s20:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 20, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 20, 48, false, false)
    c20:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 20, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 20, 48, false, false)
    s21:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 21, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 21, 48, false, false)
    c21:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 21, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 21, 48, false, false)
    s22:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 22, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 22, 48, false, false)
    c22:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 22, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 22, 48, false, false)
    s23:  DMAHeader(0,0)
        DMACopyJob(SCREEN_SRC + 4 + LOGICAL_ROWSIZE * 23, SCREEN_SRC + 2 + LOGICAL_ROWSIZE * 23, 48, false, false)
    c23:   DMAHeader($ff,$ff)
        DMACopyJob(COLOR_RAM + 4 + LOGICAL_ROWSIZE * 23, COLOR_RAM + 2 + LOGICAL_ROWSIZE * 23, 48, false, false)   
        }

HardScrollLayer1:
        ldx #$00
        stx $f2
        stx $f3
        stx $f6
        stx $f7
    !loop:
        // prep source
        clc
        lda Layer1XPtrLo,x
        adc #$04
        sta $f0
        lda Layer1XPtrHi,x
        adc #$00
        sta $f1

        // prep dest
        clc
        lda Layer1XPtrLo,x
        adc #$02
        sta $f4
        lda Layer1XPtrHi,x
        adc #$00
        sta $f5

        // save first 2 bytes
        ldz #$01
        nop
        lda ($f4),z
        sta $f9
        dez
        nop
        lda ($f4),z
        sta $f8
        dez

        // inner copy
    !innerLoop:
        nop
        lda ($f0),z
        nop
        sta ($f4),z
        inz
        cpz #48
        bne !innerLoop-

        // copy first to bytes to end of line
        lda $f8
        nop
        sta ($f4),z
        inz
        lda $f9
        nop
        sta ($f4),z

        inx
        cpx #25
        bne !loop-
        rts


layer0X: .byte $00
layer1X: .byte $00

SetupColorRAM: {
        RunDMAJob(job)
        rts

    job:
        DMAHeader(0,$ff)
        DMACopyJob(COLOR_SRC, COLOR_RAM, LOGICAL_ROWSIZE * 25, false, false)
}

    .var ncmchr0 = LoadBinary("data\layer0.chrs")
    .var ncmchr1 = LoadBinary("data\layer1.chrs")

    .var ncmmap0 = LoadBinary("data\layer0.map")
    .var ncmmap1 = LoadBinary("data\layer1.map")
SCREEN_SRC:
    .for (var y=0; y<25; y++)
    {
        .word $0000     // xpos for layer 0, and y offset
        .fill 50, ncmmap0.get(mod(i+8,50)+y*50)
        .word $0000     // xpos for layer 1, and y offset
        .fill 50, ncmmap1.get(i+y*50)
        .word 320       // last x pos
        .word 0         // final character
    }
    
    .var ncmatr0 = LoadBinary("data\layer0.atr")
    .var ncmatr1 = LoadBinary("data\layer1.atr")
COLOR_SRC:
    .for (var y=0; y<25; y++)
    {
        .word $0010         // goto set, no transp
        .fill 50, ncmatr0.get(mod(i+8,50)+y*50)
        .word $0090         // goto set, transp
        .fill 50, ncmatr1.get(i+y*50) + mod(i, 2)
        .word $0010         // goto set, no transp, last x pos
        .word $0300         // final character color
    }

    .var ncmpal0 = LoadBinary("data\layer0.clut")
    .var ncmpal1 = LoadBinary("data\layer1.clut")
PALETTER:
    .fill 16, ncmpal0.get(i+$000)
    .fill 16, ncmpal1.get(i+$000)
PALETTEG:
    .fill 16, ncmpal0.get(i+$100)
    .fill 16, ncmpal1.get(i+$100)
PALETTEB:
    .fill 16, ncmpal0.get(i+$200)
    .fill 16, ncmpal1.get(i+$200)

Layer0XPtrLo:
    .fill 25, <(SCREEN_SRC + LOGICAL_ROWSIZE * i)
Layer0XPtrHi:
    .fill 25, >(SCREEN_SRC + LOGICAL_ROWSIZE * i)
Layer1XPtrLo:
    .fill 25, <(SCREEN_SRC + LOGICAL_ROWSIZE * i + 52)
Layer1XPtrHi:
    .fill 25, >(SCREEN_SRC + LOGICAL_ROWSIZE * i + 52)

* = $4000 "Char DATA - Layer0"

CHAR_MEM:
    .fill ncmchr0.getSize(), ncmchr0.get(i)
* = * "Char DATA - Layer1"
    .fill ncmchr1.getSize(), ncmchr1.get(i)