.macro BasicUpstart65(addr) {
	* = $2001
		.var addrStr = toIntString(addr)

		.byte $09,$20 //End of command marker (first byte after the 00 terminator)
		.byte $0a,$00 //10
		.byte $fe,$02,$30,$00 //BANK 0
		.byte <end, >end //End of command marker (first byte after the 00 terminator)
		.byte $14,$00 //20
		.byte $9e //SYS
		.text addrStr
		.byte $00
	end:
		.byte $00,$00	//End of basic terminators
}

.macro enable40Mhz() {
		lda #$41
		sta $00 //40 Mhz mode
}

.macro enableVIC3Registers () {
		lda #$00
		tax 
		tay 
		taz 
		map
		eom

		lda #$A5	//Enable VIC III
		sta $d02f
		lda #$96
		sta $d02f
}

.macro enableVIC4Registers () {
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

.macro disableCIAandIRQ() {
    	lda #$7f
        sta $DC0D 
        sta $DD0D 

        lda #$00
        sta $D01A

        lda #$70
        sta $D640
        nop
}

.macro disableC65ROM() {
		// lda #$70
		// sta $d640
		// eom
		// lda #$70
		// sta $D640
		// nop
		lda #$02
		sta $D641
		clv
}

.macro mapMemory(source, target) {
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

.macro VIC4_SetCharLocation(addr) {
	lda #[addr & $ff]
	sta $d068
	lda #[[addr & $ff00]>>8]
	sta $d069
	lda #[[addr & $ff0000]>>16]
	sta $d06a
}

.macro VIC4_SetScreenLocation(addr) {
	lda #[addr & $ff]
	sta $d060
	lda #[[addr & $ff00]>>8]
	sta $d061
	lda #[[addr & $ff0000]>>16]
	sta $d062
	lda #[[[addr & $ff0000]>>24] & $0f]
	sta $d063
}

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
	.byte [Source >> 16] + backByte //+$80

	.word Destination & $ffff
	.byte [[Destination >> 16] & $0f]  + backByte//+$80
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

.label MULTINA = $d770  // 32 bit ($8000d770 in monitor)
.label MULTINB = $d774  // 32 bit
.label MULTOUT = $d778  // 64 bit (8 bytes)

// Load Immediate Unsigned into 4 byte MULTINA
.macro LDIU_MULTINA(fpval)
{
    lda #>floor(fpval)
    sta MULTINA+3
    lda #<floor(fpval)
    sta MULTINA+2
    lda #>floor((fpval - floor(fpval)) * 65536)
    sta MULTINA+1
    lda #<floor((fpval - floor(fpval)) * 65536)
    sta MULTINA+0
}

// Load Immediate Unsigned into 4 byte MULTINB
.macro LDIU_MULTINB(fpval)
{
    lda #>floor(fpval)
    sta MULTINB+3
    lda #<floor(fpval)
    sta MULTINB+2
    lda #>floor((fpval - floor(fpval)) * 65536)
    sta MULTINB+1
    lda #<floor((fpval - floor(fpval)) * 65536)
    sta MULTINB+0
}

// Load pseudo reg Q with 4 byte multiply result
.macro LDQU_1616()
{
	ldq MULTOUT+2
}

// Load Immediate Unsigned into 4 byte MULTINA
.macro LDIS_MULTINA(fpval)
{
	lda #$00
	sta MULTSIGN
    lda #>floor(fpval)
	bpl !skip+
!skip:
    sta MULTINA+3
    lda #<floor(fpval)
    sta MULTINA+2
    lda #>floor((fpval - floor(fpval)) * 65536)
    sta MULTINA+1
    lda #<floor((fpval - floor(fpval)) * 65536)
    sta MULTINA+0
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

MULTSIGN:
	.byte 0   // can't do this in an include (at least not before BasicUpstart) 
