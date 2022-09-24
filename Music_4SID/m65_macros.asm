.cpu _45gs02

// Toggles between read-only and read-write of the ROM at $20000-$3ffff
// When the machine starts, the ROM is read-only
.macro toggleReadOnlyROM() {
                lda #$70
                sta $d640
                nop
}

.macro BasicUpstart65(addr) {
                .pc = $2001 "Basic Start"
                .var addrStr = toIntString(addr)
                .byte $09,$20 //End of command marker (first byte after the 00 terminator)
                .byte $0a,$00 //10
                .byte $fe,$02,$30,$00 //BANK 0
                .byte <end, >end //End of command marker (first byte after the 00 terminator)
                .byte $14,$00 //20
                .byte $9e //SYS
                .text addrStr
                .byte $00
end:            .byte $00,$00	//End of basic terminators
                .text "BONZAI"
}

.macro enable40Mhz() {
                lda #$41
                sta $00 //40 Mhz mode
}

.macro DisableC65ROM() {
                lda #$70 // disable rom protection
                sta $d640
                eom
                lda #%11111000 // Unmap rom
                trb $d030
}

.macro mapMemory(source, target) { // Changes the mapping of a memory location to the target
                .var sourceMB = (source & $ff00000) >> 20
                .var sourceOffset = ((source & $00fff00) - target)
                .var sourceOffHi = sourceOffset >> 16
                .var sourceOffLo = (sourceOffset & $0ff00 ) >> 8
                .var bitLo = pow(2, (((target) & $ff00) >> 12) / 2) << 4
                .var bitHi = pow(2, (((target-$8000) & $ff00) >> 12) / 2) << 4
                
                .if(target<$8000) {
                    lda #sourceMB
                    ldx #$0f
                    ldy #$00
                    ldz #$00
                } else {
                    lda #$00
                    ldx #$00
                    ldy #sourceMB
                    ldz #$0f
                }
                map 

                //Set offset map
                .if(target<$8000) {
                    lda #sourceOffLo
                    ldx #[sourceOffHi + bitLo]
                    ldy #$00
                    ldz #$00
                } else {
                    lda #$00
                    ldx #$00
                    ldy #sourceOffLo
                    ldz #[sourceOffHi + bitHi]
                }   
                map 
                eom
}

// -------------------------------------------------------------
//   VIC-4
// -------------------------------------------------------------

.macro VIC4_EnableVIC4 () {
                lda #$00
                tax 
                tay 
                taz 
                map
                eom
                lda #$47	//Enable VIC IV
                sta $d02f
                lda #$53
                sta $d02f
}

.macro VIC4_SetResolution320x200() { // Change screen resolution to 320x200
                lda #$80 // clear bit 7
                trb $d031
}

.macro VIC4_SetLogicalCharsPerRow(addr) { // Set the length in number of chars per line
                lda #<addr
                sta $d058
                lda #>addr
                sta $d059
}

.macro VIC4_SetDisplayCharsPerRow(addr) { // Set the number of chars displayed per line 
                lda #addr
                sta $d05e
}


.macro VIC4_SetCharLocation(addr) { // Set the location of the charset in memory
                lda #[addr & $ff]
                sta $d068
                lda #[[addr & $ff00]>>8]
                sta $d069
                lda #[[addr & $ff0000]>>16]
                sta $d06a
}

.macro VIC4_SetScreenLocation(addr) { // Set the location of the screen in memory
                lda #[addr & $ff]
                sta $d060
                lda #[[addr & $ff00]>>8]
                sta $d061
                lda #[[addr & $ff0000]>>16]
                sta $d062
                lda #[[[addr & $ff0000]>>24] & $0f]
                sta $d063
}

.macro VIC4_SetColorLocation(addr) { // Set the location of the screen in memory
                lda #<addr
                sta $d064
                lda #>addr
                sta $d065
}

.macro VIC4_EnableSEAM() { // Enable Super-Extended Attribute Mode
                lda #%00000111
                tsb $d054
}

.macro enablePAL() { // Enable PAL (Ref. mega65-book,p703)
                lda #$80
                trb $d06f
}

.macro DisableBadlines() { // Disable badline emulation (Ref. mega65-book, p.704)
                lda #$01
                trb $d710
}

// -------------------------------------------------------------
//   DMA
// -------------------------------------------------------------

.macro RunDMAJob(JobPointer) {
        lda #[JobPointer >> 16]
        sta $d702
        sta $d704
        lda #>JobPointer
        sta $d701
        lda #<JobPointer
        sta $d705
}
.macro DMAHeader(SourceBank, DestBank) {
        .byte $0A // Request format is F018A
        .byte $80, SourceBank
        .byte $81, DestBank
}
.macro DMAStep(SourceStep, SourceStepFractional, DestStep, DestStepFractional) {
        .if(SourceStepFractional != 0) {
            .byte $82, SourceStepFractional
        }
        .if(SourceStep != 1) {
            .byte $83, SourceStep
        }
        .if(DestStepFractional != 0) {
            .byte $84, DestStepFractional
        }
        .if(DestStep != 1) {
            .byte $85, DestStep
        }       
}
.macro DMADisableTransparency() {
        .byte $06
}
.macro DMAEnableTransparency(TransparentByte) {
        .byte $07 
        .byte $86, TransparentByte
}
.macro DMACopyJob(Source, Destination, Length, Chain, Backwards) {
    .byte $00 //No more options
    .if(Chain) {
        .byte $04 //Copy and chain
    } else {
        .byte $00 //Copy and last request
    }   
    
    .var backByte = 0
    .if(Backwards) {
        .eval backByte = $40
        .eval Source = Source + Length - 1
        .eval Destination = Destination + Length - 1
    }
    .word Length //Size of Copy

    .word Source & $ffff
    .byte [Source >> 16] + backByte

    .word Destination & $ffff
    .byte [[Destination >> 16] & $0f]  + backByte
    .if(Chain) {
        .word $0000
    }
}


.macro DMAFillJob(SourceByte, Destination, Length, Chain) {
    .byte $00 //No more options
    .if(Chain) {
        .byte $07 //Fill and chain
    } else {
        .byte $03 //Fill and last request
    }   
    
    .word Length //Size of Copy
    .word SourceByte
    .byte $00
    .word Destination & $ffff
    .byte [[Destination >> 16] & $0f] 
    .if(Chain) {
        .word $0000
    }
}


.macro DMAMixJob(Source, Destination, Length, Chain, Backwards) {
    .byte $00 //No more options
    .if(Chain) {
        .byte $04 //Mix and chain
    } else {
        .byte $00 //Mix and last request
    }   
    
    .var backByte = 0
    .if(Backwards) {
        .eval backByte = $40
        .eval Source = Source + Length - 1
        .eval Destination = Destination + Length - 1
    }
    .word Length //Size of Copy
    .word Source & $ffff
    .byte [Source >> 16] + backByte
    .word Destination & $ffff
    .byte [[Destination >> 16] & $0f]  + backByte
    .if(Chain) {
        .word $0000
    }
}


// -------------------------------------------------------------
//   Core
// -------------------------------------------------------------

.macro BeginIRQ() {
                pha
                tya
                pha
                txa
                pha
                tza
                pha
                inc $d019
}

.macro EndIRQ() {
                pla
                taz
                pla
                tax
                pla
                tay
                pla
                rti
}

.macro NextIRQ(addr,raster) {
                lda #raster
                sta $d012
                lda #<addr
                sta $fffe
                lda #>addr
                sta $ffff
                EndIRQ()
}

// $d064-$d065 : ColorRAM pointer
// $d06c-$d06e : Sprite pointer adress ($d06e, only lowest 7 bits)
//               Set bit 7, $d06e = expect 2 bytes per sprite pointer
// Hot registers: $d011,$d016,$d018,$d031,$dd00
// Can be disabled by clearing bit 7 in $d05d

// $d076 : Enable native resolution for sprites
// $d055 : Enable variable height
// $d056 : variable height value
// $d057 : set sprite mode

