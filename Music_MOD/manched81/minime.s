;===========================================================
;miniME simplified DOS replacement for MEGA65
;
;Version 0.12A
;Written by Daniel England of Ecclestial Solutions.
;
;Copyright 2021, Daniel England. All Rights Reserved.
;
;-----------------------------------------------------------
;
;A simple DOS replacement library.  Use miniSetFileName
;and miniSetFileType to describe your file and miniOpenFile
;to open it.
;
;Supports only character reads but block reads will be added
;in the future.  Read a byte with miniReadByte.
;
;-----------------------------------------------------------
;
;I want to release this under the LGPL.  I'll make the 
;commitment and include the licensing infomation soon.
;
;===========================================================

ptrMiniOffs 	= 	$DE
ptrFileName		=	$E2

VAL_DOSFTYPE_DEL = 0
VAL_DOSFTYPE_SEQ = 1
VAL_DOSFTYPE_PRG = 2
VAL_DOSFTYPE_USR = 3
VAL_DOSFTYPE_REL = 4
VAL_DOSFTYPE_CBM = 5


;-----------------------------------------------------------
miniSetFileName:
;	.A		IN	File Name Length
;	.X		IN	File Name Addr Lo
;	.Y		IN	File Name Addr Hi
;-----------------------------------------------------------
;***Do error checking 'cause this is the interface

		JSR	_miniSetFN
	
		RTS

;-----------------------------------------------------------
miniSetFileType:
;	.A		IN	File Type
;-----------------------------------------------------------
;***Do error checking 'cause this is the interface

		JSR	_miniSetFT
	
		RTS


;-----------------------------------------------------------
miniOpenFile:
;	.A		IN	Handle - 0
;	.ST_C	OUT	Set if error
;-----------------------------------------------------------
;***Do error checking 'cause this is the interface

		JSR	_miniInit
		JSR	_miniFindFile
		BCS	@exit
		
		LDA	datEntryTrk
		STA	datNextTrk
		LDA	datEntrySec
		STA	datNextSec
		
		JSR	_miniReadNextSector
		BCS	@exit
		
		JSR	_miniChainSector
		CLC
		
@exit:
		RTS


;-----------------------------------------------------------
miniCloseFile:
;-----------------------------------------------------------
		JSR	_miniInit
		RTS


;-----------------------------------------------------------
miniReadByte:
;	.A		OUT	Data
;	.ST_C	OUT	Set if error
;-----------------------------------------------------------
;***Do more error checking 'cause this is the interface
		PHX
		PHY
		PHZ

		LDA	datCurrLen
		CMP	#$FF
		BEQ	@error

		JSR	_miniReadByte
	
		LDX	offsCurrIdx
		CPX	datCurrLen
		BEQ	@nextsec
		
		CLC
		JMP	@exit
		
@nextsec:
		LDX	datNextTrk
		BEQ	@eof
		
		LDX	flagCurrSec
		BNE	@loadsec
		
		LDX	datCurrTrk
		CPX	datNextTrk
		BNE	@loadsec
		
		LDX	datCurrSec
		INX
		CPX	datNextSec
		BNE	@loadsec
		
		PHA
		
		JSR	_miniSwapSector
		JSR	_miniChainSector
		
		PLA
		CLC
		
		JMP	@exit

@loadsec:
		PHA
		
		JSR	_miniReadNextSector
		BCS	@error1
		
		JSR	_miniChainSector
		
		PLA
		CLC
		
		JMP	@exit
		
@eof:
		LDX	#$FF
		STX	datCurrLen
		
		CLC
		JMP	@exit

@error1:
		PLA
@error:
		SEC

@exit:
		PLZ
		PLY
		PLX
		
		RTS

;===========================================================


lenFileName:
	.byte	$00
datFileType:
	.byte	$00
;datFileMode:
;	.byte	$00

arrFileName:
	.repeat	$10
	.byte	$00
	.endrepeat

offsCurrIdx:
	.byte	$00
flagCurrSec:
	.byte	$00
	
datNextTrk:
	.byte	$00
datNextSec:
	.byte	$00
	
datCurrTrk:
	.byte	$00
datCurrSec:
	.byte	$00

datCurrLen:
	.byte	$00

;datReqSec:
;	.byte	$00

arrEntryBuf:
	.repeat	$20
	.byte	$00
	.endrepeat

datEntryCntr:
	.byte	$00

datEntryType:
	.byte	$00
datEntryTrk:
	.byte	$00
datEntrySec:
	.byte	$00
	
datTempByte:
	.byte	$00


;-----------------------------------------------------------
_miniSetFN:
;-----------------------------------------------------------
		STA	lenFileName
		STX	ptrFileName
		STY	ptrFileName + 1

		LDZ	#$00
		LDX	#$00
@loop:
		CPZ	lenFileName
		BCC	@fetch
		
		LDA	#$A0
		JMP	@fill
		
@fetch:
		LDA	(ptrFileName), Z
		
@fill:
		STA	arrFileName, X
		
		INX
		INZ
		CPZ	#$10
		BNE	@loop

		RTS
	
;-----------------------------------------------------------
_miniSetFT:
;-----------------------------------------------------------
		STA	datFileType
	
		RTS
	
	
;-----------------------------------------------------------
_miniInit:
;-----------------------------------------------------------
		LDA	#$00
		STA	offsCurrIdx
		STA	flagCurrSec
		STA	datNextTrk
		STA	datNextSec
		STA	datCurrTrk
		STA	datCurrSec
		
		STA	ptrMiniOffs
		LDA	#$6C
		STA	ptrMiniOffs + 1
		LDA	#$FD
		STA	ptrMiniOffs + 2
		LDA	#$0F
		STA	ptrMiniOffs + 3

		LDA	#$00
		STA	$D080
		
		RTS
		
		
;-----------------------------------------------------------
_miniReadNextSector:
;-----------------------------------------------------------
;	Turn on motor + led (which causes led to light solid)
		LDA	#$60
		STA	$D080
		
;	Wait for ready
		LDA	#$20
		STA	$D081

;	Track (start at 0)
		LDX	datNextTrk
		STX	datCurrTrk
		DEX
		STX	$D084
		
;	Sector (only side 0 ones)
		LDA	datNextSec
		LSR
;		STA	datReqSec
		STA	datCurrSec
		
;	Sectors start at 1
		TAX
		INX
		
		STX	$D085
;	Side
		LDA	#$00
		STA	$D086
		
;	Flag which side we need
		ADC	#$00
		STA	flagCurrSec
		
;	Read
		LDA	#$41
		STA	$D081
		
;	Wait while busy
@wait0:
		LDA	$D082
		BMI	@wait0
		
;	Check for error
		LDA	$D082
		AND	#$18
		BEQ	@succeed
		
;	Turn on just the LED, this causes to blink
		LDA	#$40
		STA	$D080

		SEC
		RTS
		
@succeed:
;	Make sure we can see the data
		LDA	#$80
		TRB	$D689

		CLC
		
		LDA	#$00
		STA	offsCurrIdx

		LDA	flagCurrSec
		BEQ	@upper
	
		LDA	#$6D
		STA	ptrMiniOffs + 1
	
		RTS
	
@upper:
		LDA	#$6C
		STA	ptrMiniOffs + 1
		RTS


;-----------------------------------------------------------
_miniSwapSector:
;-----------------------------------------------------------
		LDX	#$6D
		STX	ptrMiniOffs + 1
		
		LDX	#$00
		STX	offsCurrIdx
		
		LDA	#$01
		STA	flagCurrSec
		
		RTS


;-----------------------------------------------------------
_miniChainSector:
;-----------------------------------------------------------
		JSR	_miniReadByte
		STA	datNextTrk
		CMP	#$00
		BNE	@link
		
		STA	datNextSec
		
		JSR	_miniReadByte
		STA	datCurrLen
		INC	datCurrLen

;dengland This is not required because the value is one
;	greater than the number used
;		INC	datCurrLen
		
		JMP	@exit
		
@link:
		JSR	_miniReadByte
		STA	datNextSec
		
		LDA	#$00
		STA	datCurrLen
		
@exit:
		RTS
		

;readDMAT:	
;       .byte $0A  				; Request format is F018A
;      	.byte $80,$FF 			; Source MB 
;       .byte $81,$00 			; Destination MB 
;        .byte $00  				; No more options
;F018A DMA list
;       .byte $00 				; copy + last request in chain
;reasdCnt:		
;       .word $0001 			; size of copy
;readSrc:		
;       .word $6C00 			; starting at
;       .byte $0D   			; of bank
;readDst:		
;		.word datTempByte		; destination addr
;       .byte $00   			; of bank
;		.word $0000				; modulo
		
;-----------------------------------------------------------
_miniReadByte:
;-----------------------------------------------------------
;@halt:
;		INC	$D020
;		JMP	@halt
		
;		LDA	offsCurrIdx
;		STA	readSrc
;		LDA	ptrMiniOffs + 1
;		STA	readSrc + 1
;
;		LDA #$00
;		STA $D702
;		LDA #>readDMAT
;		STA	$D701
;		LDA	#<readDMAT
;		STA	$D705	
;
;		LDA	datTempByte
;
;		INC	offsCurrIdx
		
		LDZ	offsCurrIdx

		NOP
		LDA	(ptrMiniOffs), Z
		
		INC	offsCurrIdx
		
		RTS
		
;-----------------------------------------------------------
_miniGetFileEntry:
;-----------------------------------------------------------
		LDX	#$00
@loop0:
		JSR	_miniReadByte
		STA	arrEntryBuf, X
		
		INX
		CPX	#$20
		BNE	@loop0

		RTS
		
;-----------------------------------------------------------
_miniFindFile:
;-----------------------------------------------------------
		LDA	#$28							;|OPENDIR
		STA	datNextTrk						;|
		LDA	#$00							;|
		STA	datNextSec						;|
											;|
		JSR	_miniReadNextSector				;|
		BCS	@error							;|
											;|
		JSR	_miniReadByte					;|
		STA	datNextTrk						;|
											;|
		JSR	_miniReadByte					;|
		STA	datNextSec						;|


@loop0:										;|FINDNEXTDIRTRK
;	Get directory list sector				;|
		JSR	_miniReadNextSector				;|
		BCS	@error							;|
											;|
		LDX	#$00							;|
		STX	datNextTrk						;|
		STX	datNextSec						;|
											;|
		STX	datEntryCntr					;|


@loop1:										;|READDIR
		JSR	_miniGetFileEntry				;|

		LDY	#$00
		LDA	arrEntryBuf, Y
		BEQ	@skipt
		
		STA	datNextTrk
		
@skipt:
		INY
		
		LDA	arrEntryBuf, Y
		BEQ	@skips

		STA	datNextSec

@skips:
		INY
		
;	File type
		LDA	arrEntryBuf, Y
		STA	datEntryType
		
		INY
	
;	File track/sector
		LDA	arrEntryBuf, Y
		BEQ	@error
		
		STA	datEntryTrk
		INY
		
		LDA	arrEntryBuf, Y
		STA	datEntrySec
		INY

		LDA	datEntryType
		AND	#$0F
		CMP	datFileType
		BNE	@next1

;	File name
		LDX	#$00
@name:
		LDA	arrEntryBuf, Y
		CMP	arrFileName, X
		BNE	@next1
		
		INX
		INY
		CPX	#$10
		BNE	@name
		
		JMP	@found

@next1:
		INC	datEntryCntr
		LDA	datEntryCntr
		CMP	#$08
		LBNE @loop1							;|Normal exit
		
		LDA	datNextTrk						;|Call FINDNEXTDIRTRK
		BNE	@loop0
		
@error:
;	Turn on just the LED, this causes to blink
		LDA	#$40
		STA	$D080

		SEC

		RTS
		
@found:
		CLC
	
		RTS