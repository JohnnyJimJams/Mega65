;===========================================================
;Manche MOD Replayer
;
;Version 0.40A
;Written by Daniel England of Ecclestial Solutions.
;
;Copyright 2021, Daniel England. All Rights Reserved.
;
;-----------------------------------------------------------
;
;
;-----------------------------------------------------------
;
;I want to release this under the LGPL.  I'll make the 
;commitment and include the licensing infomation soon.
;
;===========================================================

	.setcpu		"4510"

	.feature	leading_dot_in_identifiers, loose_string_term

;	Determine whether MOD loading is from D81 or SDC.
	.define		DEF_MNCH_USEMINI	1


ptrScreenB		=	$80
valScrOffs		=	$82
valScrCntr		=	$83
valScrChar		=	$84
valScrLPix		=	$86

numConvLEAD0	=	$C2
numConvDIGIT	=	$C3
numConvVALUE	=	$C4
numConvHeapPtr	=	$C6

ptrScreen		=	$C8
ptrModule		=	$CC

ptrTempA		=	$F0
ptrTempB		=	$F2
ptrTempC		=	$F4
ptrTempD		=	$F6
valTempA		=	$F8

ADDR_SCREEN		=	$4000

ADDR_TEXTURE	=	$5000

AD32_MODFILE	=	$00010000
AD32_COLOUR		=	$0FF80800

ADDR_DATABUF	=	$C000
ADDR_INPBUF		=	$0300

ADDR_DIRFPTRS	=	$8000
ADDR_DIRFNAMS	=	$8400
ADDR_DIRFNTOP	=	$C000
ADDR_SHUFPTRS	=	$C400

COLR_HIGHLT	=	$01
COLR_CONTLT	=	$0C
COLR_HOLDLT	=	$0F


	.macro	.defPStr Arg
	.byte	.strlen(Arg), Arg
	.endmacro

	.macro	__MNCH_ASL_MEM16	mem
		CLC
		LDA	mem
		ASL
		STA	mem
		LDA	mem + 1
		ROL
		STA	mem + 1
	.endmacro

	.macro	__MNCH_LSR_MEM16	mem
		CLC
		LDA	mem + 1
		LSR
		STA	mem + 1
		LDA	mem
		ROR
		STA	mem
	.endmacro


;-----------------------------------------------------------
;BASIC interface
;-----------------------------------------------------------
	.code
;start 2 before load address so
;we can inject it into the binary
	.org		$07FF			
						
	.byte		$01, $08		;load address
	
;BASIC next addr and this line #
	.word		_basNext, $000A		
	.byte		$9E			;SYS command
	.asciiz		"2061"			;2061 and line end
_basNext:
	.word		$0000			;BASIC prog terminator
	.assert		* = $080D, error, "BASIC Loader incorrect!"
;-----------------------------------------------------------

	.define KEY_ASC_A	$41
	.define KEY_ASC_B	$42
	.define KEY_ASC_C	$43
	.define KEY_ASC_D	$44
	.define KEY_ASC_E	$45
	.define KEY_ASC_F	$46
	.define KEY_ASC_L_A	$61
	.define KEY_ASC_L_B	$62
	.define KEY_ASC_L_C	$63
	.define KEY_ASC_L_D	$64
	.define KEY_ASC_L_E	$65
	.define KEY_ASC_L_F	$66
	.define KEY_ASC_BSLASH	$5C		;!!Needs screen code xlat
	.define KEY_ASC_CARET	$5E		;!!Needs screen code xlat
	.define KEY_ASC_USCORE	$5F		;!!Needs screen code xlat
	.define KEY_ASC_BQUOTE	$60		;!!Needs screen code xlat. !!Not C64
	.define KEY_ASC_OCRLYB	$7B		;!!Needs screen code xlat. !!Not C64
	.define KEY_ASC_LCRLYB	$7B		;Alternate
	.define KEY_ASC_PIPE	$7C		;!!Needs screen code xlat
	.define KEY_ASC_CCRLYB	$7D		;!!Needs screen code xlat. !!Not C64
	.define KEY_ASC_RCRLYB	$7D		;Alternate
	.define KEY_ASC_TILDE	$7E		;!!Needs screen code xlat

bootstrap:
		JMP	init


PEPPITO:
	.include	"peppito.s"


filename:
;	.defPStr	""
	.byte		$00
	.res		64, $20
	.byte		$00

dirname:
;	.defPStr	""
	.byte		$00
	.res		64, $20
	.byte		$00


errStr:
	.defPStr	"ERROR OPENING FILE!"


flgMnchDirty:
	.byte		$00
flgMnchPlay:
	.byte		$00
flgMnchLoad:
	.byte		$00

cntMnchTick:
	.word		$0000
cntMnchNTSC:
	.byte		$00

valMnchInst:
	.byte		$01

valMnchMsVol:
	.word		$FFDC
valMnchLLVol:
	.word		$9984
valMnchLRVol:
	.word		$2661
valMnchRLVol:
	.word		$2661
valMnchRRVol:
	.word		$9984

valMnchMsVPc:
	.byte		100
valMnchRRVPc:
	.byte		60
valMnchRLVPc:
	.byte		15

valMnchChVIt:
	.byte		$01, $01, $01, $01
valMnchChVFd:
	.byte		$00, $00, $00, $00


flgMnchJukeB:
	.byte		$00
flgMnchJNext:
	.byte		$00
flgMnchDirDn:
	.byte		$00
valMnchJFIdx:
	.word		$0000
valMnchJFCnt:
	.word		$0000


valMnchDummy:
	.byte		$00

valMnchTemp0:
	.dword		$00000000


valHexDigit0:
		.byte	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
		.byte	KEY_ASC_A, KEY_ASC_B, KEY_ASC_C
		.byte	KEY_ASC_D, KEY_ASC_E, KEY_ASC_F

valVolSteps0:
		.byte	4, 4, 4, 4, 5, 5, 5, 10, 10, 12, 1

valMixSteps0:
		.byte	18, 9, 9, 9, 9, 9, 9, 9, 9, 9, 1

valVolColrs0:
		.byte	5, 5, 5, 5, 7, 7, 7, 8, 8, 10, 4



screenASCIIXLAT:
	.byte	KEY_ASC_BSLASH, KEY_ASC_CARET, KEY_ASC_USCORE, KEY_ASC_BQUOTE
	.byte	KEY_ASC_OCRLYB, KEY_ASC_PIPE, KEY_ASC_CCRLYB, KEY_ASC_TILDE, $00
screenASCIIXLATSub:
	.byte	$4D, $71, $64, $4A ,$55, $5D, $49, $45, $00
screenTemp0:
	.byte	$00


;lstDMATest:
;	.byte $0A				; Request format is F018A
;	.byte $80,$00			; Source MB 
;	.byte $81,$00			; Destination MB 
;	.byte $00				; No more options
;	.byte $00				; copy +  chained
;	.word $8000				; size of copy
;	.word $0000
;	.byte $01 				; source bank
;	.word $0000
;	.byte $01				; dest bank
;	.word $0000				; modulo


;-----------------------------------------------------------
init:
;-----------------------------------------------------------
;	disable standard CIA irqs
		LDA	#$7F			
		STA	$DC0D		;CIA IRQ control
		
;	No decimal mode, no interrupts
		CLD
		SEI

;	Setup Mega65 features and speed
		JSR	initM65IOFast

;	Disable ROM write-protect
		LDA	#$70
		STA	$D640
;	This is required as part of the hypervisor interface
		NOP

;	Clear the input buffer
		LDX	#$00
@loop0:
		LDA	$D610
		STX	$D610
		BNE	@loop0

	.if	.not	DEF_MNCH_USEMINI
		LDA	#>ADDR_DATABUF
		STA	Z:ptrBigglesBufHi
		LDA	#>ADDR_INPBUF
		STA	Z:ptrBigglesXfrHi

		JSR	changeDirectory
	.endif

		JSR	initState

		JSR	initMemory

		JSR	initTexture
		JSR	initScreen

		JSR	initAudio

		JSR	initIRQ

		SEI
		LDA	#$01
		STA	flgMnchDirty
		CLI

main:
;		LDA	#$03
;		STA	$D020
;
;		LDA #>lstDMATest
;		STA $D701
;		LDA #<lstDMATest
;		STA $D705
;
;		LDA	#$00
;		STA	$D020
		LDA	flgMnchJukeB
		BEQ	@getinput

		SEI
		LDA	flgMnchJNext
		CLI

		BEQ	@getinput

		SEI
		LDA	#$00
		STA	flgMnchJNext
		CLI

		JSR	jukeboxPlayNext

@getinput:
		LDA	$D610
		BEQ	main

		LDX	#$00
		STX	$D610

		CMP	#$F7
		BNE	@tstInsDn

		INC	valMnchInst
		LDA	valMnchInst
		CMP	valPepMaxI
		LBNE	@update

		LDX	valMnchInst
		DEX
		STX valMnchInst

		JMP	@update

@tstInsDn:
		CMP	#$F8
		BNE	@testf1

		DEC	valMnchInst
		LDA	valMnchInst
		CMP	#$00
		LBNE	@update

		LDA	#$01
		STA	valMnchInst
		JMP	@update

@testf1:
		CMP	#$F1
		BNE	@testf2

		LDA	#$00
		STA	flgMnchJukeB

		JSR	inputModule

		JSR	testModule
		LBCS	@update

@doload:
		JSR	loadModule

		JMP	@update

@testf2:
		CMP	#$F2
		BNE	@testspc

	.if	.not	DEF_MNCH_USEMINI
		LDA	#$00
		STA	flgMnchJukeB
		STA	flgMnchDirDn

		JSR	inputModule
		JSR	loadDirectory

		JMP	@update
	.else
		JMP	@next0
	.endif

@testspc:
		CMP	#' '
		BNE	@tstf3

		LDA	flgMnchLoad
		BEQ	@next0

		SEI
		LDA	flgMnchPlay
		EOR	#$01
		STA	flgMnchPlay
		CLI

		JMP	@update

@tstf3:
		CMP	#$F3
		BNE	@tstf4

	.if	.not	DEF_MNCH_USEMINI
		JSR	jukeboxStartDefault
		JMP	@update
	.else
		JMP	@next0
	.endif

@tstf4:
		CMP	#$F4
		BNE	@tstf5

	.if	.not	DEF_MNCH_USEMINI
		JSR	jukeboxStartShuffle
		JMP	@update
	.else
		JMP	@next0
	.endif

@tstf5:
		CMP	#$F5
		BNE	@tstf9

		LDA	flgMnchJukeB
		BEQ	@next0

		JSR	jukeboxPlayNext
		JMP	@update

@tstf9:
		CMP	#$F9
		BNE	@tstf10

		JSR	mixerIncMaster
		JMP	@update

@tstf10:
		CMP	#$FA
		BNE	@tstf11

		JSR	mixerDecMaster
		JMP	@update

@tstf11:
		CMP	#$FB
		BNE	@tstf12

		JSR	mixerIncLeftLeft
		JSR	mixerIncRightRight
		JMP	@update

@tstf12:
		CMP	#$FC
		BNE	@tstf13

		JSR	mixerDecLeftLeft
		JSR	mixerDecRightRight
		JMP	@update

@tstf13:
		CMP	#$FD
		BNE	@tstf14

		JSR	mixerIncLeftRight
		JSR	mixerIncRightLeft
		JMP	@update

@tstf14:
		CMP	#$FE
		BNE	@next0

		JSR	mixerDecLeftRight
		JSR	mixerDecRightLeft
;		JMP	@update

@update:
		SEI
		LDA	#$01
		STA	flgMnchDirty
		CLI

@next0:
		JMP	main



;-----------------------------------------------------------
jukeboxPlayNext:
;-----------------------------------------------------------

		SEI
		LDA	#$00
		STA	flgMnchLoad

		LDA	flgMnchPlay
		BEQ	@cont0

		JSR	PEPPITO + $0C

@cont0:
		LDA	#$00
		STA	flgMnchPlay

		CLI


		LDA	valMnchJFIdx + 1
		CMP	valMnchJFCnt + 1
		BCC	@begin
		BEQ	@tstlo0

		JMP	@fail

@tstlo0:
		LDA	valMnchJFIdx
		CMP	valMnchJFCnt
		BCC	@begin

		JMP	@fail


@begin:


;@halt0:
;		INC	$D020
;		JMP	@halt0

		LDA	valMnchJFIdx
		STA	valMnchTemp0
		LDA	valMnchJFIdx + 1
		STA	valMnchTemp0 + 1

		__MNCH_ASL_MEM16	valMnchTemp0

		LDA	flgMnchJukeB
		BMI	@shuffle

		CLC
		LDA	valMnchTemp0
		ADC	#<ADDR_DIRFPTRS
		STA	ptrTempB
		LDA	valMnchTemp0 + 1
		ADC	#>ADDR_DIRFPTRS
		STA	ptrTempB + 1

		JMP	@copyfn

@shuffle:
		CLC
		LDA	valMnchTemp0
		ADC	#<ADDR_SHUFPTRS
		STA	ptrTempB
		LDA	valMnchTemp0 + 1
		ADC	#>ADDR_SHUFPTRS
		STA	ptrTempB + 1

@copyfn:
		LDY	#$00
		LDA	(ptrTempB), Y
		STA	ptrTempC
		INY
		LDA	(ptrTempB), Y
		STA	ptrTempC + 1

		LDA	#$00
		STA	filename

		LDX	#$01
		LDY	#$00
@loop0:
		LDA	(ptrTempC), Y
		BEQ	@done0

		STA	filename, X
		INY
		INX
		JMP	@loop0

@done0:
		DEX
		STX	filename

		CLC
		LDA	valMnchJFIdx
		ADC	#$01
		STA	valMnchJFIdx
		LDA	valMnchJFIdx + 1
		ADC	#$00
		STA	valMnchJFIdx + 1

		JSR	loadModule

		LDA	flgMnchLoad
		BEQ	@fail

		SEI
;		LDA	flgMnchPlay
		LDA	#$01
		STA	flgMnchPlay
		CLI

		RTS

@fail:
		LDA	#$00
		STA	flgMnchJukeB

		RTS


	.if	.not	DEF_MNCH_USEMINI
;-----------------------------------------------------------
jukeboxStartShuffle:
;-----------------------------------------------------------
		LDA	flgMnchJukeB
		BEQ	@begin
		BPL	@begin

@nostart:
		RTS

@begin:
		LDA	flgMnchDirDn
		BNE	@cont0

		JSR	dirListLoad

@cont0:
		LDA	#$00
		STA	valMnchJFIdx
		STA	valMnchJFIdx + 1

		LDA	valMnchJFCnt
		ORA	valMnchJFCnt + 1
		BEQ	@nostart

		JSR	jukeboxRandomise

		LDA	#$81
		STA	flgMnchJukeB

		JSR	jukeboxPlayNext

		RTS


;-----------------------------------------------------------
getRandomByte:
;-----------------------------------------------------------
;	get parity of 256 reads of lowest bit of FPGA temperature
;	for each bit. Then add to raster number.
;	Should probably have more than enough entropy, even if the
;	temperature is biased, as we are looking only at parity of
;	a large number of reads.
;	(Whether it is cryptographically secure is a separate issue.
;	but it should be good enough for random MAC address generation).
		LDA #$00
		LDX #8
		LDY #0
@bitLoop:
		EOR $D6DE
		DEY
		BNE @bitLoop
;	low bit into C
		LSR
;	then into A
		ROR
		DEX
		BPL @bitLoop
		CLC
		ADC $D012

		RTS


;-----------------------------------------------------------
jukeboxRandomise:
;-----------------------------------------------------------
		LDA	#<ADDR_DIRFPTRS
		STA	ptrTempB
		LDA	#>ADDR_DIRFPTRS
		STA	ptrTempB + 1

		LDA	#<ADDR_SHUFPTRS
		STA	ptrTempC
		LDA	#>ADDR_SHUFPTRS
		STA	ptrTempC + 1

		LDA	valMnchJFCnt
		STA	valTempA
		LDA	valMnchJFCnt + 1
		STA	valTempA + 1

		__MNCH_ASL_MEM16 valTempA

		LDY	#$00
@loop0:
		LDA	(ptrTempB), Y
		STA	(ptrTempC), Y

		INW	ptrTempB
		INW	ptrTempC

		DEW	valTempA

		LDA	valTempA + 1
		CMP	#$FF
		BNE	@loop0


		LDA	valMnchJFCnt
		STA	valTempA
		STA	valMnchTemp0 + 2
		LDA	valMnchJFCnt + 1
		STA	valTempA + 1
		STA	valMnchTemp0 + 3

		SEC
		LDA	valMnchTemp0 + 2
		SBC	#$01
		STA	valMnchTemp0 + 2
		LDA	valMnchTemp0 + 3
		SBC	#$00
		STA	valMnchTemp0 + 3

		LDA	#<ADDR_SHUFPTRS
		STA	ptrTempC
		LDA	#>ADDR_SHUFPTRS
		STA	ptrTempC + 1

@loop1:

;	Get low byte of swap pos
@loop2:
		JSR	getRandomByte
		STA	ptrTempB
		LDA valMnchTemp0 + 2
		CMP	ptrTempB
		BCC	@loop2

;	Skip high byte if not so many
		LDA	#$00
		STA	ptrTempB + 1
		LDA	valMnchTemp0 + 3
		BEQ	@cont0

;	Get high byte of swap pos
@loop3:
		JSR	getRandomByte
		AND	#$03
		STA	ptrTempB + 1
		LDA	valMnchTemp0 + 3
		CMP	ptrTempB + 1
		BCC	@loop3

@cont0:
		__MNCH_ASL_MEM16 ptrTempB

		CLC
		LDA	ptrTempB
		ADC	#<ADDR_SHUFPTRS
		STA	ptrTempB
		LDA	ptrTempB + 1
		ADC	#>ADDR_SHUFPTRS
		STA	ptrTempB + 1

		LDY	#$00

		LDA	(ptrTempB), Y
		STA	valMnchTemp0
		LDA	(ptrTempC), Y
		STA	(ptrTempB), Y
		LDA	valMnchTemp0
		STA	(ptrTempC), Y

		INY

		LDA	(ptrTempB), Y
		STA	valMnchTemp0
		LDA	(ptrTempC), Y
		STA	(ptrTempB), Y
		LDA	valMnchTemp0
		STA	(ptrTempC), Y

		INW	ptrTempC
		INW	ptrTempC

		DEW	valTempA
		BNE	@loop1

		RTS


;-----------------------------------------------------------
jukeboxStartDefault:
;-----------------------------------------------------------
		LDA	flgMnchJukeB
		BEQ	@begin
		BMI	@begin

@nostart:
		RTS

@begin:
		LDA	flgMnchDirDn
		BNE	@cont0

		JSR	dirListLoad

@cont0:
		LDA	#$00
		STA	valMnchJFIdx
		STA	valMnchJFIdx + 1

		LDA	valMnchJFCnt
		ORA	valMnchJFCnt + 1

		BEQ	@nostart

		LDA	#$01
		STA	flgMnchJukeB

		JSR	jukeboxPlayNext

		RTS


;sdcounter:
;		.dword		$00000000

;;-------------------------------------------------------------------------------
;sdwaitawhile:
;;-------------------------------------------------------------------------------
;		JSR	sdtimeoutreset
;
;@sw1:
;		INC	sdcounter + 0
;		BNE	@sw1
;		INC	sdcounter + 1
;		BNE	@sw1
;		INC	sdcounter + 2
;		BNE @sw1
;
;		RTS
;
;;-------------------------------------------------------------------------------
;sdtimeoutreset:
;;-------------------------------------------------------------------------------
;;	count to timeout value when trying to read from SD card
;;	(if it is too short, the SD card won't reset)
;
;		LDA	#$00
;		STA	sdcounter + 0
;		STA	sdcounter + 1
;		LDA	#$F3
;		STA	sdcounter + 2
;
;		RTS

;-----------------------------------------------------------
dirListLoad:
;-----------------------------------------------------------
;		LDA	#$81
;		STA	$D680
;
;		JSR	sdwaitawhile
;
;;	Work out if we are using primary or secondard SD card
;
;;	First try resetting card 1 (external)
;;	so that if you have an external card, it will be used in preference
;		LDA	#$C0
;		STA	$D680
;		LDA	#$00
;		STA	$D680
;		LDA	#$01
;		STA	$D680
;
;		JSR	sdwaitawhile

;		JSR	changeDirectory

;*******************************************************************************

		LDA	#$00
		STA	valMnchJFCnt
		STA	valMnchJFCnt + 1

		STA	ptrTempB
		STA	ptrTempC
		STA	ptrTempD

		LDA	#>ADDR_DATABUF
		STA	ptrTempB + 1

		LDA	#>ADDR_DIRFNAMS
		STA	ptrTempC + 1

		LDA	#>ADDR_DIRFPTRS
		STA	ptrTempD + 1

		LDA	#$01
		STA	flgMnchDirDn

		JSR	bigglesOpenDir
		BCS	@begin

;	Assume this means failure
@fail:
		LDA	#$02
		STA	$D020

		RTS

@begin:
		STA	valMnchDummy

;		LDA	#$38
;		STA	$D640
;		NOP
;
;		CMP	#$00
;		BEQ	@cont
;
;		PHA
;
;		LDA	#$0E
;		STA	$D020
;
;		PLA
;		SEI
;
;@halt:
;		JMP	@halt
;
;		JMP	@fail
;
;@cont:
;		LDA	valMnchDummy
		
@loop:
		JSR	bigglesReadDir
		BCS	@done

;	Not directories
		AND	#$10
		BNE	@next

		JSR	dirMatchFile
		BCC	@add

@next:
		LDA	valMnchDummy
		JMP	@loop

@add:
		JSR	dirAddFile
		JMP	@next

@done:
		LDA	valMnchDummy
		JSR	bigglesCloseDir

;@wait0:
;		INC	$D020
;		LDA	$D610
;		BEQ	@wait0
;		LDA	#$00
;		STA	$D610

		RTS


extBytes0:
		.byte	'd', 'o', 'm', '.'
extBytes4:
		.byte	'D', 'O', 'M', '.'

;-----------------------------------------------------------
dirMatchFile:
;-----------------------------------------------------------
		LDY	#$FF
@loop0:
		INY
		CPY	#64
		BEQ	@fail

		LDA	(ptrTempB), Y
		BNE	@loop0

;		CPY	#$00
;		BEQ	@fail
		CPY	#$06
		BCC	@fail

		DEY
		LDX	#$00
@loop1:
		LDA	(ptrTempB), Y
		CMP	extBytes0, X
		BEQ	@next1

		CMP	extBytes4, X
		BEQ	@next1

		JMP	@fail

@next1:
		DEY
		INX
		CPX	#$04
		BNE	@loop1

		CLC
		RTS

@fail:
		SEC
		RTS


;-----------------------------------------------------------
dirAddFile:
;-----------------------------------------------------------
		LDA	ptrTempD + 1
		CMP	#>ADDR_DIRFNAMS
		BNE	@cont

		RTS

@cont:
		LDA	ptrTempC + 1
		CMP	#>ADDR_DIRFNTOP
		BNE	@begin

		RTS

@begin:
		LDY	#$00
		LDA	ptrTempC
		STA	(ptrTempD), Y
		INY
		LDA	ptrTempC + 1
		STA	(ptrTempD), Y

		LDY	#$00
		LDZ	#$00
@loop:
		LDA	(ptrTempB), Y
		STA	(ptrTempC), Z

		PHA

		INW	ptrTempC
		INY

		LDA	ptrTempC + 1
		CMP	#>ADDR_DIRFNTOP
		BNE	@next

		PLA
		RTS

@next:
		PLA
		BNE	@loop

		INW	ptrTempD
		INW	ptrTempD

		CLC
		LDA	valMnchJFCnt
		ADC	#$01
		STA	valMnchJFCnt
		LDA	valMnchJFCnt + 1
		ADC	#$00
		STA	valMnchJFCnt + 1


		RTS


	.endif


;-----------------------------------------------------------
mixerIncRightRight:
;-----------------------------------------------------------
		INC	valMnchRRVPc

		CLC
		LDA	valMnchRRVol
		ADC	#$8F
		STA	valMnchRRVol
		LDA	valMnchRRVol + 1
		ADC	#$02
		STA	valMnchRRVol + 1
		LDA	#$00
		ADC	#$00

		BNE	@max

		LDA	valMnchRRVol + 1
		CMP	#$FF
		BCC	@exit
		BNE	@max
		LDA	valMnchRRVol
		CMP	#$DC
		BCC	@exit
@max:
		LDA	#$DC
		STA	valMnchRRVol
		LDA	#$FF
		STA	valMnchRRVol + 1

		LDA	#100
		STA	valMnchRRVPc

@exit:
		JSR	setRightRVolume

		RTS


;-----------------------------------------------------------
mixerDecRightRight:
;-----------------------------------------------------------
		DEC	valMnchRRVPc

		SEC
		LDA	valMnchRRVol
		SBC	#$8F
		STA	valMnchRRVol
		LDA	valMnchRRVol + 1
		SBC	#$02
		STA	valMnchRRVol + 1
		LDA	#$00
		SBC	#$00

		BPL	@exit

		LDA	#$00
		STA	valMnchRRVol
		STA	valMnchRRVol + 1

		STA	valMnchRRVPc

@exit:
		JSR	setRightRVolume

		RTS


;-----------------------------------------------------------
mixerIncRightLeft:
;-----------------------------------------------------------
		INC	valMnchRLVPc

		CLC
		LDA	valMnchRLVol
		ADC	#$8F
		STA	valMnchRLVol
		LDA	valMnchRLVol + 1
		ADC	#$02
		STA	valMnchRLVol + 1
		LDA	#$00
		ADC	#$00

		BNE	@max

		LDA	valMnchRLVol + 1
		CMP	#$FF
		BCC	@exit
		BNE	@max
		LDA	valMnchRLVol
		CMP	#$DC
		BCC	@exit
@max:
		LDA	#$DC
		STA	valMnchRLVol
		LDA	#$FF
		STA	valMnchRLVol + 1

		LDA	#100
		STA	valMnchRLVPc

@exit:
		JSR	setRightLVolume

		RTS


;-----------------------------------------------------------
mixerDecRightLeft:
;-----------------------------------------------------------
		DEC	valMnchRLVPc

		SEC
		LDA	valMnchRLVol
		SBC	#$8F
		STA	valMnchRLVol
		LDA	valMnchRLVol + 1
		SBC	#$02
		STA	valMnchRLVol + 1
		LDA	#$00
		SBC	#$00

		BPL	@exit

		LDA	#$00
		STA	valMnchRLVol
		STA	valMnchRLVol + 1

		STA	valMnchRLVPc


@exit:
		JSR	setRightLVolume

		RTS


;-----------------------------------------------------------
mixerIncLeftRight:
;-----------------------------------------------------------
		LDA	$D629
		AND	#$40
		BEQ	@nonnexys

		RTS
		
@nonnexys:
		CLC
		LDA	valMnchLRVol
		ADC	#$8F
		STA	valMnchLRVol
		LDA	valMnchLRVol + 1
		ADC	#$02
		STA	valMnchLRVol + 1
		LDA	#$00
		ADC	#$00

		BNE	@max

		LDA	valMnchLRVol + 1
		CMP	#$FF
		BCC	@exit
		BNE	@max
		LDA	valMnchLRVol
		CMP	#$DC
		BCC	@exit
@max:
		LDA	#$DC
		STA	valMnchLRVol
		LDA	#$FF
		STA	valMnchLRVol + 1

@exit:
		JSR	setLeftRVolume

		RTS


;-----------------------------------------------------------
mixerDecLeftRight:
;-----------------------------------------------------------
		LDA	$D629
		AND	#$40
		BEQ	@nonnexys

		RTS
		
@nonnexys:
		SEC
		LDA	valMnchLRVol
		SBC	#$8F
		STA	valMnchLRVol
		LDA	valMnchLRVol + 1
		SBC	#$02
		STA	valMnchLRVol + 1
		LDA	#$00
		SBC	#$00

		BPL	@exit

		LDA	#$00
		STA	valMnchLRVol
		STA	valMnchLRVol + 1

@exit:
		JSR	setLeftRVolume

		RTS


;-----------------------------------------------------------
mixerIncLeftLeft:
;-----------------------------------------------------------
		LDA	$D629
		AND	#$40
		BEQ	@nonnexys

		RTS
		
@nonnexys:
		CLC
		LDA	valMnchLLVol
		ADC	#$8F
		STA	valMnchLLVol
		LDA	valMnchLLVol + 1
		ADC	#$02
		STA	valMnchLLVol + 1
		LDA	#$00
		ADC	#$00

		BNE	@max

		LDA	valMnchLLVol + 1
		CMP	#$FF
		BCC	@exit
		BNE	@max
		LDA	valMnchLLVol
		CMP	#$DC
		BCC	@exit
@max:
		LDA	#$DC
		STA	valMnchLLVol
		LDA	#$FF
		STA	valMnchLLVol + 1

@exit:
		JSR	setLeftLVolume

		RTS


;-----------------------------------------------------------
mixerDecLeftLeft:
;-----------------------------------------------------------
		LDA	$D629
		AND	#$40
		BEQ	@nonnexys

		RTS
		
@nonnexys:
		SEC
		LDA	valMnchLLVol
		SBC	#$8F
		STA	valMnchLLVol
		LDA	valMnchLLVol + 1
		SBC	#$02
		STA	valMnchLLVol + 1
		LDA	#$00
		SBC	#$00

		BPL	@exit

		LDA	#$00
		STA	valMnchLLVol
		STA	valMnchLLVol + 1

@exit:
		JSR	setLeftLVolume

		RTS


;-----------------------------------------------------------
mixerIncMaster:
;-----------------------------------------------------------
		INC	valMnchMsVPc

		CLC
		LDA	valMnchMsVol
		ADC	#$8F
		STA	valMnchMsVol
		LDA	valMnchMsVol + 1
		ADC	#$02
		STA	valMnchMsVol + 1
		LDA	#$00
		ADC	#$00

		BNE	@max

		LDA	valMnchMsVol + 1
		CMP	#$FF
		BCC	@exit
		BNE	@max
		LDA	valMnchMsVol
		CMP	#$DC
		BCC	@exit
@max:
		LDA	#100
		STA	valMnchMsVPc

		LDA	#$DC
		STA	valMnchMsVol
		LDA	#$FF
		STA	valMnchMsVol + 1

@exit:
		JSR	setMasterVolume

		RTS


;-----------------------------------------------------------
mixerDecMaster:
;-----------------------------------------------------------
		DEC	valMnchMsVPc

		SEC
		LDA	valMnchMsVol
		SBC	#$8F
		STA	valMnchMsVol
		LDA	valMnchMsVol + 1
		SBC	#$02
		STA	valMnchMsVol + 1
		LDA	#$00
		SBC	#$00

		BPL	@exit

		LDA	#$00
		STA	valMnchMsVol
		STA	valMnchMsVol + 1

		STA	valMnchMsVPc

@exit:
		JSR	setMasterVolume

		RTS


;-----------------------------------------------------------
displayMixerInfo:
;-----------------------------------------------------------
		LDA	#<(ADDR_SCREEN + (14 * 160) + 0)
		STA	ptrScreen
		LDA	#>(ADDR_SCREEN + (14 * 160) + 0)
		STA	ptrScreen + 1

		LDA	#$00
		STA	valMnchDummy

		LDX	#$00
@loop0:
		PHX

		LDA	valMnchMsVPc, X
		STA	ptrTempA
		LDA	#$00
		STA	ptrTempA + 1

		LDY	valMnchDummy
		LDZ	#$00
		LDA	#$20
@loop1:
		STA	(ptrScreen), Y
		INY
		INY
		INZ
		CPZ	#$0B
		BNE	@loop1

		LDY	valMnchDummy
		LDX	#$00

		LDA	ptrTempA + 1
@loop2:
		BMI	@next0

		LDA	ptrTempA
		BEQ	@next0

		TAZ
		LDA	#$A0
		STA	(ptrScreen), Y
		INY
		INY
		TZA

		SEC
		LDA	ptrTempA
		SBC	valMixSteps0, X
		STA	ptrTempA
		LDA	ptrTempA + 1
		SBC	#$00
		STA	ptrTempA + 1
		
		PHA
		INX
		PLA

		JMP	@loop2

@next0:
		CLC
		LDA	valMnchDummy
		ADC	#$18
		STA	valMnchDummy

		PLX
		INX
		CPX	#$03
		BNE	@loop0

		LDA	#<(ADDR_SCREEN + (15 * 160) + 12)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (15 * 160) + 12)
		STA	numConvHeapPtr + 1

		LDA	valMnchMsVPc
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		LDA	#<(ADDR_SCREEN + (15 * 160) + 36)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (15 * 160) + 36)
		STA	numConvHeapPtr + 1

		LDA	valMnchRRVPc
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		LDA	#<(ADDR_SCREEN + (15 * 160) + 60)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (15 * 160) + 60)
		STA	numConvHeapPtr + 1

		LDA	valMnchRLVPc
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		RTS


;-----------------------------------------------------------
displayInstInfo:
;-----------------------------------------------------------
		LDA	#<(ADDR_SCREEN + (2 * 160) + 140)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (2 * 160) + 140)
		STA	numConvHeapPtr + 1

		LDA	valMnchInst
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		LDA	valMnchInst
		ASL
		TAX

		LDA	idxPepIns0, X
		STA	ptrTempA
		LDA	idxPepIns0 + 1, X
		STA	ptrTempA + 1

		LDY	#PEP_INSDATA::ptrHdr
		LDA	(ptrTempA), Y
		STA	ptrModule
		INY
		LDA	(ptrTempA), Y
		STA	ptrModule + 1
		INY
		LDA	(ptrTempA), Y
		STA	ptrModule + 2
		INY
		LDA	(ptrTempA), Y
		STA	ptrModule + 3
		
		LDA	#<(ADDR_SCREEN + (2 * 160) + 100)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (2 * 160) + 100)
		STA	numConvHeapPtr + 1

		LDZ	#$00
		LDY	#$00
@loop:
		NOP
		LDA	(ptrModule), Z

		JSR	screenASCIIToScreen

		STA	(numConvHeapPtr), Y
		INY
		INY
		INZ

		CPZ	#$16
		BNE	@loop

		LDA	#<(ADDR_SCREEN + (3 * 160) + 120)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (3 * 160) + 120)
		STA	numConvHeapPtr + 1

		LDY	#PEP_INSDATA::valVol
		LDA	(ptrTempA), Y
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1

		JSR	numConvPRTINT

		LDA	#<(ADDR_SCREEN + (3 * 160) + 140)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (3 * 160) + 140)
		STA	numConvHeapPtr + 1

		LDY	#PEP_INSDATA::valFTune
		LDA	(ptrTempA), Y
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1

		JSR	numConvPRTINT

		LDA	#<(ADDR_SCREEN + (4 * 160) + 140)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (4 * 160) + 140)
		STA	numConvHeapPtr + 1

		LDY	#PEP_INSDATA::valSLen
		LDA	(ptrTempA), Y
		STA	numConvVALUE
		INY
		LDA	(ptrTempA), Y
		STA	numConvVALUE + 1

		JSR	numConvPRTINT

		LDA	#<(ADDR_SCREEN + (5 * 160) + 140)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (5 * 160) + 140)
		STA	numConvHeapPtr + 1

		LDY	#PEP_INSDATA::valLStrt
		LDA	(ptrTempA), Y
		STA	numConvVALUE
		INY
		LDA	(ptrTempA), Y
		STA	numConvVALUE + 1

		JSR	numConvPRTINT

		LDA	#<(ADDR_SCREEN + (6 * 160) + 140)
		STA	numConvHeapPtr
		LDA	#>(ADDR_SCREEN + (6 * 160) + 140)
		STA	numConvHeapPtr + 1

		LDY	#PEP_INSDATA::valLLen
		LDA	(ptrTempA), Y
		STA	numConvVALUE
		INY
		LDA	(ptrTempA), Y
		STA	numConvVALUE + 1

		JSR	numConvPRTINT

		RTS


;-----------------------------------------------------------
displaySongInfo:
;-----------------------------------------------------------
		LDA	#<(ADDR_SCREEN + 2 * 160)
		STA	ptrScreen
		LDA	#>(ADDR_SCREEN + 2 * 160)
		STA	ptrScreen + 1

		LDA	#<.loword(AD32_MODFILE)
		STA	ptrModule
		LDA	#>.loword(AD32_MODFILE)
		STA	ptrModule + 1
		LDA	#<.hiword(AD32_MODFILE)
		STA	ptrModule + 2
		LDA	#>.hiword(AD32_MODFILE)
		STA	ptrModule + 3

		LDZ	#$00
		LDY	#$00
@loop:
		NOP
		LDA	(ptrModule) , Z

		JSR	screenASCIIToScreen

		STA	(ptrScreen), Y

		INY
		INY
		INZ

		CPZ	#$14
		BNE	@loop

		RTS


;-----------------------------------------------------------
displayCurrVol:
;-----------------------------------------------------------
		LDA	#<(ADDR_SCREEN + (6 * 160) + 0)
		STA	ptrScreen
		LDA	#>(ADDR_SCREEN + (6 * 160) + 0)
		STA	ptrScreen + 1

		LDA	#$00
		STA	valMnchDummy

		LDX	#$00
@loop0:
		PHX

		TXA
		ASL
		TAX

		LDA	idxPepChn0, X
		STA	ptrTempA
		LDA	idxPepChn0 + 1, X
		STA	ptrTempA + 1

		LDY	valMnchDummy
		LDZ	#$00
		LDA	#$20
@loop1:
		STA	(ptrScreen), Y
		INY
		INY

		INZ
		CPZ	#$0C
		BNE	@loop1

		PLX
		PHX

		TXA
		ASL
		TAX

		LDA	valDACCtrlR0, X
		STA	valScrLPix
		LDA	valDACCtrlR0 + 1, X
		STA	valScrLPix + 1

		PLX
		PHX

		LDY	#$00
		LDA	(valScrLPix), Y
		STA	valScrChar

		AND	#$80
		BEQ	@zeroout

		LDA	valScrChar
		AND	#$08
		BEQ	@tstkey

@zeroout:
		LDA	#$00
		STA	valMnchChVFd, X
		LDA	valMnchChVIt, X

		JMP	@cont1

@tstkey:
		LDY	#PEP_NOTDATA::valKey
		LDA	(ptrTempA), Y
		INY
		ORA	(ptrTempA), Y

		BNE	@cont0

		LDA	#$02
		STA	valMnchChVIt, X

		LDY	#PEP_CHNDATA::valVol
		LDA	(ptrTempA), Y

;		LSR
		STA	valMnchChVFd, X

		JMP	@cont1

@cont0:
		LDY	#PEP_CHNDATA::valVol
		LDA	(ptrTempA), Y
		STA	valMnchChVFd, X

		LDA	valMnchChVIt, X
		BEQ	@cont1

		SEC
		LDA	valMnchChVIt, X
		SBC	#$01
		STA	valMnchChVIt, X

		LDA	valMnchChVFd, X
		LSR
		STA	valMnchChVFd, X

;		JMP	@next0

@cont1:
;		LDY	#PEP_CHNDATA::valVol
;		LDA	(ptrTempA), Y
		LDA	valMnchChVFd, X

		PHA
		LDY	valMnchDummy
		LDX	#$00
		PLA
@loop2:
		BEQ	@next0
		BMI	@next0

		TAZ
		LDA	#$A0
		STA	(ptrScreen), Y
		INY
		INY

		TZA
		SEC
		SBC	valVolSteps0, X
		
		PHA
		INX
		PLA

		JMP	@loop2

@next0:
		CLC
		LDA	valMnchDummy
		ADC	#$18
		STA	valMnchDummy

		PLX
		INX
		CPX	#$04
		LBNE	@loop0

		RTS


;-----------------------------------------------------------
displayCurrRow:
;	Only call when IRQ can't be called (eg from IRQ handler)
;-----------------------------------------------------------
		LDA	#<(ADDR_SCREEN + (8 * 160) + 0)
		STA	ptrScreen
		LDA	#>(ADDR_SCREEN + (8 * 160) + 0)
		STA	ptrScreen + 1

		LDA	#$00
		STA	valMnchDummy

		LDX	#$00
@loop0:
		PHX

		TXA
		ASL
		TAX

		LDA	idxPepChn0, X
		STA	ptrTempA
		LDA	idxPepChn0 + 1, X
		STA	ptrTempA + 1

;	Note key
		LDY	#PEP_NOTDATA::valKey
		LDA	(ptrTempA), Y
		INY
		STA	numConvVALUE

		LDA	(ptrTempA), Y
		STA	numConvVALUE + 1

		LDY	valMnchDummy
		LDA	numConvVALUE + 1
		AND	#$0F
		JSR	outputHexNybble

		LDA	numConvVALUE
		JSR	outputHexByte

		LDA	#':'
		STA	(ptrScreen), Y
		INY
		INY

		STY	valMnchDummy

;	Note instrument
		LDY	#PEP_NOTDATA::valIns
		LDA	(ptrTempA), Y
		STA	numConvVALUE

		LDY	valMnchDummy
		LDA	numConvVALUE
		JSR	outputHexByte

		LDA	#':'
		STA	(ptrScreen), Y
		INY
		INY

		STY	valMnchDummy

;	Note effect
		LDY	#PEP_NOTDATA::valEff
		LDA	(ptrTempA), Y
		STA	numConvVALUE

		LDY	valMnchDummy
		LDA	numConvVALUE
		JSR	outputHexByte

		STY	valMnchDummy

;	Note param
		LDY	#PEP_NOTDATA::valPrm
		LDA	(ptrTempA), Y
		STA	numConvVALUE

		LDY	valMnchDummy
		LDA	numConvVALUE
		JSR	outputHexByte

		INY
		INY
		STY	valMnchDummy

		PLX
		INX
		CPX	#$04
		LBNE	@loop0


		RTS


;-----------------------------------------------------------
displayPString:
;-----------------------------------------------------------
		LDY	#$00
		LDZ	#$00

		LDA	(ptrTempA), Y
		TAX
		BEQ	@exit

		INY

@loop0:
		LDA	(ptrTempA), Y
		STA	(ptrScreen), Z

		INY
		INZ
		INZ

		DEX
		BNE	@loop0

@exit:
		RTS


;-----------------------------------------------------------
error:
;-----------------------------------------------------------
		LDA	#<(ADDR_SCREEN + 2 * 160)
		STA	ptrScreen
		LDA	#>(ADDR_SCREEN + 2 * 160)
		STA	ptrScreen + 1

		LDA	#<errStr
		STA	ptrTempA
		LDA	#>errStr
		STA	ptrTempA + 1

		JSR	displayPString

;@halt:
;		JMP	@halt

		RTS


;-----------------------------------------------------------
inputModule:
;-----------------------------------------------------------
		SEI
		LDA	#$00
		STA	flgMnchLoad

		LDA	flgMnchPlay
		BEQ	@cont0

		JSR	PEPPITO + $0C

@cont0:
		LDA	#$00
		STA	flgMnchPlay

;		CLI

		LDA	#$01
		STA	valMnchInst

		LDA	filename
		STA	valMnchDummy

		LDA	#$14
		STA	filename

		LDA	#<(ADDR_SCREEN + 2 * 160)
		STA	ptrScreen
		LDA	#>(ADDR_SCREEN + 2 * 160)
		STA	ptrScreen + 1

		LDA	#<filename
		STA	ptrTempA
		LDA	#>filename
		STA	ptrTempA + 1

@loop0:
		JSR	displayPString

		LDA	valMnchDummy
		ASL
		TAZ
		LDA	#$A0
		STA	(ptrScreen), Z

@loop1:
		LDA	$D610
		BEQ	@loop1

		CMP	#$14
		BEQ	@delkey

		CMP	#$0D
		BEQ	@retkey

		CMP	#$20
		BCC	@next1

		CMP	#$7B
		BCC	@acceptkey

@next1:
		LDA	#$00
		STA	$D610
		JMP	@loop1

@acceptkey:
		LDY	valMnchDummy
		CPY	#$10
		BCC	@append0

		JMP	@next1

@append0:
		CMP	#$61
		BCC	@append1

		CMP	#$7B
		BCC	@append2

@append1:
		LDY	valMnchDummy
		INY
		STA	filename, Y
		STY	valMnchDummy

		JMP	@next0

@append2:
		SEC
		SBC	#$20
		JMP	@append1

@delkey:
		LDY	valMnchDummy
		BEQ	@next1

		LDA	#$20
		STA	filename, Y
		DEY
		STY	valMnchDummy

		JMP	@next0

@retkey:
		LDY	valMnchDummy
		BEQ	@next1

		STY	filename
		LDA	#$00
		STA	$D610

		JMP	@load0

@next0:
		LDA	#$00
		STA	$D610
		JMP	@loop0


@load0:
		CLI
		RTS


	.if	.not DEF_MNCH_USEMINI
;-----------------------------------------------------------
loadDirectory:
;-----------------------------------------------------------
		SEI

		LDX	#65
@loop:
		LDA	filename, X
		STA	dirname, X
		DEX
		BPL	@loop

		LDX	dirname
		INX
		LDA	#$00
		STA	dirname, X

		JSR	changeDirectory

		CLI

		RTS

;-----------------------------------------------------------
changeDirectory:
;-----------------------------------------------------------
		JSR	bigglesCloseFile
;***********************************************************
;***FIXME These calls need to be put in bigglesworth
;***********************************************************
;	Close dir
		LDA	#$16
		STA	$D640
		NOP

;	Get default drive/partition
		LDA	#$02
		STA	$D640
		NOP

;	Set drive/partition
		TAX
		LDA	#$06
		STA	$D640
		NOP

;	Change to root directory
		LDA #$3C
		STA $D640
		NOP

		LDA	dirname
		BEQ	@root

		LDX	#<(dirname + 1)
		LDY	#>(dirname + 1)

		JSR	bigglesSetFileName

		JSR	bigglesChangeDir
		BCC	@exit

		JSR	error
		RTS

@root:

@exit:

		RTS
	.endif


;-----------------------------------------------------------
loadModule:
;-----------------------------------------------------------
		SEI
;@halt:
;		INC	$D020
;		JMP	@halt
;
;		LDA	filename			;Set the file name
;		LDX	#<(filename + 1)
;		LDY	#>(filename + 1)

	.if	DEF_MNCH_USEMINI
		LDA	filename
		LDX	#<(filename + 1)
		LDY	#>(filename + 1)

		JSR	miniSetFileName

		LDA	#VAL_DOSFTYPE_SEQ 
		JSR	miniSetFileType

		JSR	miniOpenFile
	.else
		LDY	filename
		INY
		LDA	#$00
		STA	filename, Y

		LDX	#<(filename + 1)
		LDY	#>(filename + 1)

		JSR	bigglesSetFileName
		
		LDY	filename
		INY
		LDA	#$20
		STA	filename, Y

		JSR	bigglesOpenFile
	.endif

		BCC	@cont1

		JSR	error
		RTS

@cont1:
		LDA	#<.loword(AD32_MODFILE)
		STA	ptrScreen
		STA	adrPepMODL
		STA	ptrModule
		LDA	#>.loword(AD32_MODFILE)
		STA	ptrScreen + 1
		STA	adrPepMODL + 1
		STA	ptrModule + 1
		LDA	#<.hiword(AD32_MODFILE)
		STA	ptrScreen + 2
		STA	adrPepMODL + 2
		STA	ptrModule + 2
		LDA	#>.hiword(AD32_MODFILE)
		STA	ptrScreen + 3
		STA	ptrModule + 3
		STA	adrPepMODL + 3

		LDZ	#$00
@loop:
	.if	DEF_MNCH_USEMINI
		JSR	miniReadByte
	.else
		JSR	bigglesReadByte
	.endif
		BCS	@done

		NOP
		STA	(ptrScreen), Z

		STA	$D020

		INZ
		BNE	@loop

		CLC
		LDA	#$00
		ADC	ptrScreen
		STA	ptrScreen
		LDA	#$01
		ADC	ptrScreen + 1
		STA	ptrScreen + 1
		LDA	#$00
		ADC	ptrScreen + 2
		STA	ptrScreen + 2
		LDA	#$00
		ADC	ptrScreen + 3
		STA	ptrScreen + 3

		LDA	ptrScreen + 2
		CMP	#$05
		BEQ	@done

		JMP	@loop

@done:
	.if	DEF_MNCH_USEMINI
		JSR	miniCloseFile
	.else
		JSR	bigglesCloseFile
	.endif

		LDA	#$10
		STA	$D020

		JSR	PEPPITO

		LDA	#$01
		STA	flgMnchLoad
		STA	flgMnchDirty
		CLI

		RTS

;-----------------------------------------------------------
testModule:
;-----------------------------------------------------------
		LDA	filename
		BEQ	@decline

		CMP	#$06
		BNE	@accept

		LDX	#$00
@loop:
		LDA	strSurprise0, X
		CMP	filename + 1, X
		BNE	@accept
		INX
		CPX	#$06
		BNE	@loop

		LDA	$D015
		ORA	#$FF
		STA	$D015

@decline:
		SEC
		RTS

@accept:
		CLC
		RTS



;-----------------------------------------------------------
plyrNOP:
;-----------------------------------------------------------
		RTI


;-----------------------------------------------------------
plyrIRQ:
;-----------------------------------------------------------
		PHP				;save the initial state
		PHA
		TXA				
		PHA
		TYA
		PHA

		CLD
		
;	Is the VIC-II needing service?
		LDA	$D019		;IRQ regs
		AND	#$01
		BNE	@proc
		
;	Some other interrupt source??  Peculiar...  And a real problem!  How
;	do I acknowledge it if its not a BRK when I don't know what it would be?
		LDA	#$02
		STA	$D020

		JMP	@done
		
@proc:
		LDA	#$06
		STA	$D020

		ASL	$D019

		LDA	#<ADDR_SCREEN
		STA	numConvHeapPtr
		LDA	#>ADDR_SCREEN
		STA	numConvHeapPtr + 1

		LDA	cntMnchTick
		STA	numConvVALUE
		LDA	cntMnchTick + 1
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		CLC
		LDA	#$01
		ADC	cntMnchTick
		STA	cntMnchTick
		LDA	#$00
		ADC	cntMnchTick + 1
		STA	cntMnchTick + 1


		LDA	flgMnchPlay
		AND	#$7F
		BNE	@chkNTSC

		LDA	flgMnchPlay
		BPL	@skip0

		JSR	PEPPITO + $0C

		LDA	#$00
		STA	flgMnchPlay
		JMP	@skip0

@chkNTSC:
		ORA	#$80
		STA	flgMnchPlay

		LDA	$D06F
		AND	#$80
		BEQ	@play1

		LDA	cntMnchNTSC
		CMP	#$05
		BCC	@play0

		LDA	#$00
		STA	cntMnchNTSC
		JMP	@skip0

@play0:
		INC	cntMnchNTSC

@play1:
		JSR	PEPPITO + 3

		LDA	flgPepRsrt
		BEQ	@skip0

		LDA	#$00
		STA	flgPepRsrt

		LDA	flgMnchJukeB
		BEQ	@skip0

		LDA	#$01
		STA	flgMnchJNext

@skip0:
;		LDA	#$03
;		STA	$D020
;
;		LDA #>lstDMATest
;		STA $D701
;		LDA #<lstDMATest
;		STA $D705
;
;		LDA	#$00
;		STA	$D020


		LDA	#<ADDR_SCREEN + 16
		STA	numConvHeapPtr 
		LDA	#>ADDR_SCREEN
		STA	numConvHeapPtr + 1

		LDA	cntPepTick
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		LDA	#<ADDR_SCREEN  + 32
		STA	numConvHeapPtr
		LDA	#>ADDR_SCREEN
		STA	numConvHeapPtr + 1

		LDA	cntPepPRow
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		LDA	#<ADDR_SCREEN + 48
		STA	numConvHeapPtr 
		LDA	#>ADDR_SCREEN
		STA	numConvHeapPtr + 1

		LDA	cntPepSeqP
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		LDA	flgMnchDirty
		BEQ	@skip1

		JSR	displayMixerInfo

@skip1:
		LDA	flgMnchLoad
		BEQ	@finish

		LDA	#<ADDR_SCREEN + 64
		STA	numConvHeapPtr 
		LDA	#>ADDR_SCREEN
		STA	numConvHeapPtr + 1

		LDA	valPepSLen
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		LDA	#<ADDR_SCREEN + 80
		STA	numConvHeapPtr 
		LDA	#>ADDR_SCREEN
		STA	numConvHeapPtr + 1

		LDA	valPepMaxP
		STA	numConvVALUE
		LDA	#$00
		STA	numConvVALUE + 1
		
		JSR	numConvPRTINT

		JSR	displayCurrVol
		JSR	displayCurrRow

		LDA	flgMnchDirty
		BEQ	@finish
		
		JSR	displayInstInfo
		JSR	displaySongInfo

@finish:
		LDA	#$03
		STA	$D020

		JSR	checkLastNotes
		JSR	plotEqualiser
		JSR	plotWaveform
		JSR	plotTexture
		JSR	scrollTexture

		LDA	#$0C
		STA	$D020
		JSR	animBall

		LDA	#$10
		STA	$D020

		LDA	#$00
		STA	flgMnchDirty

		LDA	#$19
		STA	$D012		;Raster pos

@done:
		PLA
		TAY
		PLA
		TAX
		PLA
		PLP

		RTI


valLastClrs0:
		.word	COLR_HIGHLT
		.word	COLR_HIGHLT
		.word	COLR_HIGHLT
		.word	COLR_HIGHLT

valLastWavs0:
		.byte	$00
		.byte	$00
		.byte	$00
		.byte	$00




valLastNots0:
		.word	$0000
valLastNots1:
		.word	$0000
valLastNots2:
		.word	$0000
valLastNots3:
		.word	$0000

valPushNots0:
		.word	$0000
valPushNots1:
		.word	$0000
valPushNots2:
		.word	$0000
valPushNots3:
		.word	$0000


valDACCtrlR0:
		.word	$D720
		.word	$D730
		.word	$D740
		.word	$D750

valCharOffs0:
		.word	ADDR_TEXTURE + (1 * 12 * 64) - 8
		.word	ADDR_TEXTURE + (2 * 12 * 64) - 8
		.word	ADDR_TEXTURE + (3 * 12 * 64) - 8
valCharOffs1:
		.word	ADDR_TEXTURE + (4 * 12 * 64) - 8
		.word	ADDR_TEXTURE + (5 * 12 * 64) - 8
		.word	ADDR_TEXTURE + (6 * 12 * 64) - 8
valCharOffs2:
		.word	ADDR_TEXTURE + (7 * 12 * 64) - 8
		.word	ADDR_TEXTURE + (8 * 12 * 64) - 8
		.word	ADDR_TEXTURE + (9 * 12 * 64) - 8
valCharOffs3:
		.word	ADDR_TEXTURE + (10 * 12 * 64) - 8
		.word	ADDR_TEXTURE + (11 * 12 * 64) - 8
		.word	ADDR_TEXTURE + (12 * 12 * 64) - 8

ptrCharOffs0:
		.word	valCharOffs0
		.word	valCharOffs1
		.word	valCharOffs2
		.word	valCharOffs3


;-----------------------------------------------------------
plotWaveform:
;-----------------------------------------------------------
;	DAC	0
		LDY	#$00

		LDA	$D720
		AND	#$80
		BEQ	@fill0

		LDA	$D720
		AND	#$08
		BNE	@fill0

		LDA	$D72A
		STA	ptrTempA
		LDA	$D72B
		STA	ptrTempA + 1
		LDA	$D72C
		STA	ptrTempA + 2
		LDA	#$00
		STA	ptrTempA + 3

		LDZ	#$00
		NOP
		LDA	(ptrTempA), Z

		STA	valScrChar + 1

		CLC
		ADC	#$80
		AND	#$7F
		LSR
		CLC
		ADC	#$10
		TAY

@fill0:
		STY	valScrChar

		CPY	valLastWavs0
		BNE	@cont0

;		CPY	#$08
;		BCC	@cont0

;		LDA	valScrChar + 1
;		AND	#$80
;		BEQ	@cont0

;		TYA
;		SEC
;		SBC	#$08
;		TAY
		TYA
		ASL
		TAY

@cont0:
		STY	valLastWavs0

		LDX	#$02
@loop0a:
		LDA	valCharOffs0, X
		STA	ptrTempA
		LDA	valCharOffs0 + 1, X
		STA	ptrTempA + 1

		LDY	#$00
		LDA	valScrChar
@loop0b:
		STA	(ptrTempA), Y
		INY
		CPY	#$08
		BNE	@loop0b

		INX
		INX
		CPX	#$06
		BNE	@loop0a

;	DAC 1
		LDY	#$00

		LDA	$D730
		AND	#$80
		BEQ	@fill1

		LDA	$D730
		AND	#$08
		BNE	@fill1

		LDA	$D73A
		STA	ptrTempA
		LDA	$D73B
		STA	ptrTempA + 1
		LDA	$D73C
		STA	ptrTempA + 2
		LDA	#$00
		STA	ptrTempA + 3

		LDZ	#$00
		NOP
		LDA	(ptrTempA), Z

		STA	valScrChar + 1

		CLC
		ADC	#$80
		AND	#$7F
		LSR
		CLC
		ADC	#$10
		TAY

@fill1:
		STY	valScrChar

		CPY	valLastWavs0 + 1
		BNE	@cont1

;		CPY	#$08
;		BCC	@cont1

;		LDA	valScrChar + 1
;		AND	#$80
;		BEQ	@cont1

;		TYA
;		SEC
;		SBC	#$08
;		TAY
		TYA
		ASL
		TAY

@cont1:
		STY	valLastWavs0 + 1

		LDX	#$02
@loop1a:
		LDA	valCharOffs1, X
		STA	ptrTempA
		LDA	valCharOffs1 + 1, X
		STA	ptrTempA + 1

		LDY	#$00
		LDA	valScrChar
@loop1b:
		STA	(ptrTempA), Y
		INY
		CPY	#$08
		BNE	@loop1b

		INX
		INX
		CPX	#$06
		BNE	@loop1a


;	DAC	2
		LDY	#$00

		LDA	$D740
		AND	#$80
		BEQ	@fill2

		LDA	$D740
		AND	#$08
		BNE	@fill2

		LDA	$D74A
		STA	ptrTempA
		LDA	$D74B
		STA	ptrTempA + 1
		LDA	$D74C
		STA	ptrTempA + 2
		LDA	#$00
		STA	ptrTempA + 3

		LDZ	#$00
		NOP
		LDA	(ptrTempA), Z

		STA	valScrChar + 1

		CLC
		ADC	#$80
		AND	#$7F
		LSR
		CLC
		ADC	#$10
		TAY

@fill2:
		STY	valScrChar

		CPY	valLastWavs0 + 2
		BNE	@cont2

;		CPY	#$08
;		BCC	@cont2

;		LDA	valScrChar + 1
;		AND	#$80
;		BEQ	@cont2

;		TYA
;		SEC
;		SBC	#$08
;		TAY
		TYA
		ASL
		TAY

@cont2:
		STY	valLastWavs0 + 2

		LDX	#$02
@loop2a:
		LDA	valCharOffs2, X
		STA	ptrTempA
		LDA	valCharOffs2 + 1, X
		STA	ptrTempA + 1

		LDY	#$00
		LDA	valScrChar
@loop2b:
		STA	(ptrTempA), Y
		INY
		CPY	#$08
		BNE	@loop2b

		INX
		INX
		CPX	#$06
		BNE	@loop2a

;	DAC	3
		LDY	#$00

		LDA	$D750
		AND	#$80
		BEQ	@fill3

		LDA	$D750
		AND	#$08
		BNE	@fill3

		LDA	$D75A
		STA	ptrTempA
		LDA	$D75B
		STA	ptrTempA + 1
		LDA	$D75C
		STA	ptrTempA + 2
		LDA	#$00
		STA	ptrTempA + 3

		LDZ	#$00
		NOP
		LDA	(ptrTempA), Z

		STA	valScrChar + 1

		CLC
		ADC	#$80
		AND	#$7F
		LSR
		CLC
		ADC	#$10
		TAY

@fill3:
		STY	valScrChar

		CPY	valLastWavs0 + 3
		BNE	@cont3

;		CPY	#$08
;		BCC	@cont3

;		LDA	valScrChar + 1
;		AND	#$80
;		BEQ	@cont3

;		TYA
;		SEC
;		SBC	#$08
;		TAY
		TYA
		ASL
		TAY

@cont3:
		STY	valLastWavs0 + 3

		LDX	#$02
@loop3a:
		LDA	valCharOffs3, X
		STA	ptrTempA
		LDA	valCharOffs3 + 1, X
		STA	ptrTempA + 1

		LDY	#$00
		LDA	valScrChar
@loop3b:
		STA	(ptrTempA), Y
		INY
		CPY	#$08
		BNE	@loop3b

		INX
		INX
		CPX	#$06
		BNE	@loop3a

		RTS


;-----------------------------------------------------------
checkLastNotes:
;-----------------------------------------------------------
		LDA	flgMnchPlay
		BNE	@begin

		JMP	@clearall

@begin:
		LDX	#$00
@loop0:

		LDA	idxPepChn0, X
		STA	ptrTempA
		LDA	idxPepChn0 + 1, X
		STA	ptrTempA + 1

		LDY	#PEP_NOTDATA::valKey
		LDA	(ptrTempA), Y
		STA	valScrLPix
		INY
		LDA	(ptrTempA), Y
		AND	#$0F
		STA	valScrLPix + 1

		ORA	valScrLPix
		BEQ	@chkregs0

@test0:
		LDA	valScrLPix
		CMP	valLastNots0, X
		BNE	@push0

		LDA	valScrLPix + 1
		CMP	valLastNots0 + 1, X
		BNE	@push0

		LDA	valScrLPix
		STA	valLastNots0, X
		LDA	valScrLPix + 1
		STA	valLastNots0 + 1, X

		JMP	@next0

@push0:
		LDA	valScrLPix
		STA	valPushNots0, X
		LDA	valScrLPix + 1
		STA	valPushNots0 + 1, X

		LDA	#$00
		STA	valLastNots0, X
		STA	valLastNots0 + 1, X

		JMP	@next0

@chkregs0:
		LDA	#COLR_HIGHLT
		STA	valLastClrs0, X

		LDA	valPushNots0, X
		ORA	valPushNots0 + 1, X
		BNE	@regscont0

		LDA	#COLR_CONTLT
		STA	valLastClrs0, X

@regscont0:
		LDA	valDACCtrlR0, X
		STA	ptrTempA
		LDA	valDACCtrlR0 + 1, X
		STA	ptrTempA + 1

		LDY	#$00
		LDA	(ptrTempA), Y
		AND	#$80
		BNE	@next0

		LDA	(ptrTempA), Y
		AND	#$08
		BEQ	@next0

		LDA	#$00
		STA	valLastNots0, X
		STA	valLastNots0 + 1, X
		STA	valPushNots0, X
		STA	valPushNots0 + 1, X

@next0:
		INX
		INX

		CPX	#$08
		LBNE	@loop0

		RTS

@clearall:
		LDA	#$00
		STA	valLastNots0
		STA	valLastNots0 + 1
		STA	valLastNots0 + 2
		STA	valLastNots0 + 3
		STA	valLastNots0 + 4
		STA	valLastNots0 + 5
		STA	valLastNots0 + 6
		STA	valLastNots0 + 7
		STA	valPushNots0
		STA	valPushNots0 + 1
		STA	valPushNots0 + 2
		STA	valPushNots0 + 3
		STA	valPushNots0 + 4
		STA	valPushNots0 + 5
		STA	valPushNots0 + 6
		STA	valPushNots0 + 7

		RTS


valEqPlots0:
	.repeat	48
	.byte	$00
	.endrepeat

valEqBands0:
	.repeat	48
	.word	$0000
	.endrepeat

adrScreenRow24:
	.word	ADDR_SCREEN + (160 * 24)
	.word	ADDR_SCREEN + (160 * 23)
	.word	ADDR_SCREEN + (160 * 22)
	.word	ADDR_SCREEN + (160 * 21)
	.word	ADDR_SCREEN + (160 * 20)
	.word	ADDR_SCREEN + (160 * 19)
	.word	ADDR_SCREEN + (160 * 18)
	.word	ADDR_SCREEN + (160 * 17)


;-----------------------------------------------------------
doEqPlotBands:
;-----------------------------------------------------------
		STA	valScrChar

		LDZ	#$00
		LDY	#$00
		LDX	#$00
@loop:
		LDA	valEqPlots0, X
		CMP	#$08
		BCC	@cont

		LDA	#$07

@cont:
		ASL
		TAY
		LDA	adrScreenRow24, Y
		STA	ptrTempA
		LDA	adrScreenRow24 + 1, Y
		STA	ptrTempA + 1

		TXA
		ASL
		TAY

		LDA	valScrChar
		STA	(ptrTempA), Y

		INX
		CPX	#$30
		BNE	@loop

		RTS


;-----------------------------------------------------------
doEqClearBands:
;-----------------------------------------------------------
		LDX	#$00
		LDA	#$00
@loop:
		STA	valEqBands0, X
		STA	valEqBands0 + 1, X

		INX
		INX
		CPX	#$60
		BNE	@loop

		RTS


;-----------------------------------------------------------
doEqAddToBand:
;-----------------------------------------------------------
		LDY	valScrLPix + 1

		CLC
		LDA	valScrLPix
		ADC	valEqBands0, Y
		STA	valEqBands0, Y
		LDA	#$00
		ADC	valEqBands0 + 1, Y
		STA	valEqBands0 + 1, Y

		LDA	valScrLPix
		STA	valScrOffs

@loop0:
		INY
		INY
		CPY	#$60
		BCS	@done0

		LDA	valScrOffs
		LSR
		BEQ	@done0

		STA	valScrOffs

		CLC
		ADC	valEqBands0, Y
		STA	valEqBands0, Y
		LDA	#$00
		ADC	valEqBands0 + 1, Y
		STA	valEqBands0 + 1, Y

		JMP	@loop0

@done0:
		LDA	valScrLPix
		STA	valScrOffs

		LDY	valScrLPix + 1
		BEQ	@done1

@loop1:
		DEY
		DEY
		BEQ	@done1

		LDA	valScrOffs
		LSR
		BEQ	@done1

		STA	valScrOffs

		CLC
		ADC	valEqBands0, Y
		STA	valEqBands0, Y
		LDA	#$00
		ADC	valEqBands0 + 1, Y
		STA	valEqBands0 + 1, Y

		JMP	@loop1

@done1:
		RTS


;-----------------------------------------------------------
doEqCalcBands:
;-----------------------------------------------------------
		JSR	doEqClearBands

		LDX	#$00
		LDY	#$00
@loop:
		STX	valScrChar

		TXA
		ASL
		TAX

		LDA	valLastNots0, X
		STA	valScrLPix
		LDA	valLastNots0 + 1, X
		STA	valScrLPix + 1

		ORA	valScrLPix
		LBEQ	@next

		LDA	valScrLPix + 1
		CMP	#$1E
		BCC @tst0

		JMP	@cap0

@tst0:
		CMP	#$03
		BCC	@calc0

		CMP	#$06
		BCC	@shift0

		__MNCH_LSR_MEM16	valScrLPix
		__MNCH_LSR_MEM16	valScrLPix

@shift0:
		__MNCH_LSR_MEM16	valScrLPix
;		__MNCH_LSR_MEM16	valScrLPix

@calc0:
		__MNCH_LSR_MEM16	valScrLPix
		__MNCH_LSR_MEM16	valScrLPix
		__MNCH_LSR_MEM16	valScrLPix
		__MNCH_LSR_MEM16	valScrLPix
;		__MNCH_LSR_MEM16	valScrLPix
;		__MNCH_LSR_MEM16	valScrLPix

		LDA	valScrLPix
		AND	#$3F
		CMP	#$30
		BCC	@cont0

@cap0:
		LDA	#$2F

@cont0:
		ASL
		TAY

		LDX	valScrChar

;		SEI
;@halt:
;		INC	$D020
;		JMP	@halt

		LDA	valMnchChVFd, X
		STA	valScrLPix

		LDA	valEqBands0 + 1, Y
		BNE	@cont1

		LDA	valEqBands0, Y
		CMP	#$40
		BCS	@cont1

		LDA	valScrLPix
		ASL
		STA	valScrLPix

@cont1:
		STY	valScrLPix + 1

		JSR	doEqAddToBand

@next:
		LDX	valScrChar

		INX
		CPX	#$04
		LBNE	@loop

		RTS


;-----------------------------------------------------------
doEqCalcOffs:
;-----------------------------------------------------------
		LDX	#$00
		LDY	#$00
@loop:
		LDA	valEqBands0, X
		STA	valScrLPix
		LDA	valEqBands0 + 1, X
		STA	valScrLPix + 1

		__MNCH_LSR_MEM16	valScrLPix
		__MNCH_LSR_MEM16	valScrLPix
		__MNCH_LSR_MEM16	valScrLPix
		__MNCH_LSR_MEM16	valScrLPix
		__MNCH_LSR_MEM16	valScrLPix

		LDA	valScrLPix
		STA	valEqPlots0, Y

		INX
		INX
		INY
		CPY	#$30
		BNE	@loop

		RTS


;-----------------------------------------------------------
plotEqualiser:
;-----------------------------------------------------------
		LDA	#$20
		JSR	doEqPlotBands

		JSR	doEqCalcBands
		JSR	doEqCalcOffs

		LDA	#'-'
		JSR	doEqPlotBands

		RTS

;-----------------------------------------------------------
plotTexture:
;-----------------------------------------------------------

		LDA	flgMnchPlay
		BNE	@begin

		RTS

@begin:
		LDX	#$00
@loop1:
		LDA	valLastNots0, X
		STA	valScrLPix
		LDA	valLastNots0 + 1, X
		STA	valScrLPix + 1

		ORA	valScrLPix
		BEQ	@next1

		LDA	ptrCharOffs0, X
		STA	valScrOffs
		LDA	ptrCharOffs0 + 1, X
		STA	valScrOffs + 1

		LDY	#$05
@loop2:
		__MNCH_LSR_MEM16 valScrLPix
		DEY
		BPL	@loop2

		LDA	valScrLPix
		AND	#$30
		BEQ	@lower0

@upper0:
		LDA	valScrLPix
		LSR
		AND	#$07
		STA	valScrLPix

		LDA	#$02
		STA	valScrLPix + 1

		JMP	@update

@lower0:
		LDA	valScrLPix
		PHA

		LSR
		LSR
		LSR
		STA	valScrLPix + 1

		PLA
		AND	#$07
		STA	valScrLPix

@update:
		LDA	valScrLPix + 1
		ASL
		CLC
		ADC	valScrOffs
		STA	valScrOffs
		LDA	valScrOffs + 1
		ADC	#$00
		STA	valScrOffs + 1

		LDY	#$00
		LDA	(valScrOffs), Y
		STA	ptrTempA
		INY
		LDA	(valScrOffs), Y
		STA	ptrTempA + 1

		LDY	valScrLPix
;		LDA	#$FF

		LDA	valLastClrs0, X
		STA	(ptrTempA), Y

		LDA	#COLR_HOLDLT
		STA	valLastClrs0, X

@next1:
		INX
		INX
		CPX	#$08
		BNE	@loop1


		LDX	#$00
@loop3:
		LDA	valPushNots0, X
		ORA	valPushNots0 + 1, X

		BEQ	@next3

		LDA	valPushNots0, X
		STA	valLastNots0, X
		STA	valScrLPix
		LDA	valPushNots0 + 1, X
		STA	valLastNots0 + 1, X

		ORA	valScrLPix
		BEQ	@skip3

		LDA	#COLR_HIGHLT
		STA	valLastClrs0, X

@skip3:
		LDA	#$00
		STA	valPushNots0, X
		STA	valPushNots0 + 1, X

@next3:
		INX
		INX
		CPX	#$08
		BNE	@loop3

		RTS


		
dmaTexScrlList0:
	.byte	$0B					; Request format is F018B
	.byte	$80,$00 			; Source MB 
	.byte	$81,$00 			; Destination MB 
	.byte	$00  				; No more options
		
	.byte	$00					;Command LSB
	.word	(12 * 64) - 8				;Count LSB Count MSB
dmaTexScrlSrcA:
	.word	ADDR_TEXTURE + $08	;Source Address LSB Source Address MSB
	.byte	$00					;Source Address BANK and FLAGS
dmaTexScrlDstA:
	.word	ADDR_TEXTURE		;Destination Address LSB Destination Address MSB
	.byte	$00					;Destination Address BANK and FLAGS
	.byte	$00					;Command MSB
	.word	$0000				;Modulo LSB / Mode Modulo MSB / Mode

;-----------------------------------------------------------
scrollTexture:
;-----------------------------------------------------------
;		JMP	@clear

		LDA	#<ADDR_TEXTURE
		STA	dmaTexScrlSrcA
		STA	dmaTexScrlDstA
		LDA	#>ADDR_TEXTURE
		STA	dmaTexScrlSrcA + 1
		STA	dmaTexScrlDstA + 1

		CLC
		LDA	dmaTexScrlSrcA
		ADC	#$08
		STA	dmaTexScrlSrcA
		LDA	dmaTexScrlSrcA + 1
		ADC	#$00
		STA	dmaTexScrlSrcA + 1

		LDX	#$00
@loop0:
		LDA #$00
		STA $D702
		LDA #>dmaTexScrlList0
		STA	$D701
		LDA	#<dmaTexScrlList0
		STA	$D705

		CLC
		LDA	dmaTexScrlSrcA
		ADC	#$00
		STA	dmaTexScrlSrcA
		LDA	dmaTexScrlSrcA + 1
		ADC	#$03
		STA	dmaTexScrlSrcA + 1

		CLC
		LDA	dmaTexScrlDstA
		ADC	#$00
		STA	dmaTexScrlDstA
		LDA	dmaTexScrlDstA + 1
		ADC	#$03
		STA	dmaTexScrlDstA + 1

		INX

		CPX	#$0C
		BNE	@loop0

@clear:

		LDX	#$00
@loop1:
		LDA	valCharOffs0, X
		STA	ptrScreenB
		LDA	valCharOffs0 + 1, X
		STA	ptrScreenB + 1

		LDA	#$00
		LDY	#$00
@loop2:
		STA	(ptrScreenB), Y
		INY
		CPY	#$08
		BNE	@loop2

		INX
		INX

		CPX	#$18
		BNE	@loop1

		RTS


;-----------------------------------------------------------
screenASCIIToScreen:
;-----------------------------------------------------------
		CMP	#$00
		BNE	@cont0

		LDA	#$20
		RTS

@cont0:
		PHY

		STA	screenTemp0
		LDY	#$07
@loop:
		LDA	screenASCIIXLAT, Y
		CMP	screenTemp0
		BEQ	@subst
		DEY
		BPL	@loop

		LDA	screenTemp0
		
		CMP	#$20
		BCS	@regular

@irregular:
		LDA	#$66
		
		PLY
		RTS

@regular:
		CMP	#$7F
		BCS	@irregular

		CMP	#$40
		BCC	@exit
	
		CMP	#$60
		BCC	@upper
	
		SEC
		SBC	#$60
		
		PLY
		RTS

@upper:
;		SEC
;		SBC	#$40
		
@exit:
		PLY
		RTS

@subst:
		LDA	screenASCIIXLATSub, Y
		PLY
		RTS


;-----------------------------------------------------------
outputHexNybble:
;-----------------------------------------------------------
		PHX
		TAX
		LDA	valHexDigit0, X
		JSR	screenASCIIToScreen

		STA	(ptrScreen), Y
		INY
		INY

		PLX

		RTS


;-----------------------------------------------------------
outputHexByte:
;-----------------------------------------------------------
		PHA
		
		LSR
		LSR
		LSR
		LSR

		JSR	outputHexNybble

		PLA
		AND	#$0F

		JSR	outputHexNybble

		RTS


;-----------------------------------------------------------
numConvPRTINT:  
;-----------------------------------------------------------
		PHA
		PHX
		PHY
		
		LDY	#$00

                LDX 	#$4         		;OUTPUT UP TO 5 DIGITS

;de	I'm pretty sure we have a problem below and this will help fix it
;		STX 	numConvLEAD0       	;INIT LEAD0 TO NON-NEG
		LDA	#%10000000
		STA	numConvLEAD0
		
;
@PRTI1:
		LDA 	#'0'        		;INIT DIGIT COUNTER
                STA 	numConvDIGIT
;
@PRTI2:
		SEC            	 		;BEGIN SUBTRACTION PROCESS
        LDA 	numConvVALUE
        SBC 	numConvT10L, X      	;SUBTRACT LOW ORDER BYTE
        PHA             		;AND SAVE.
        LDA 	numConvVALUE + $1    	;GET H.O BYTE
        SBC 	numConvT10H, X      	;AND SUBTRACT H.O TBL OF 10
        BCC 	@PRTI3       		;IF LESS THAN, BRANCH
;
        STA 	numConvVALUE + $1    	;IF NOT LESS THAN, SAVE IN
        PLA             		;VALUE.
        STA 	numConvVALUE
        INC 	numConvDIGIT       	;INCREMENT DIGIT COUNTER
        JMP 	@PRTI2
;
;
@PRTI3:
		PLA             		;FIX THE STACK
        LDA 	numConvDIGIT       	;GET CHARACTER TO OUTPUT
                
		CPX 	#$0         		;LAST DIGIT TO OUTPUT?
        BEQ 	@PRTI5       		;IF SO, OUTPUT REGARDLESS

		CMP 	#'0'        		;A ZERO?

;de	#$31+ is not negative so this wouldn't work??
;       BEQ 	@PRTI4       		;IF SO, SEE IF A LEADING ZERO
;		STA 	numConvLEAD0       	;FORCE LEAD0 TO NEG.
;de 	We'll do this instead
		BNE	@PRTI5
@PRTI4:   	
		BIT 	numConvLEAD0       	;SEE IF ZERO VALUES OUTPUT
;de	I need to this as well
;       BPL 	@PRTI6       		;YET.
;		BPL 	@space			;de I want spaces.
		BMI	@space

@PRTI5:
;		JSR 	numConvCOUT
;de	And this too (only l6bit here)
		CLC
		ROR	numConvLEAD0

		STA	(numConvHeapPtr), Y
		INY
		INY
		
		JMP	@PRTI6			;de This messes the routine but
						;I need spaces

@space:
		LDA	#' '
		STA	(numConvHeapPtr), Y
		INY
		INY
		
@PRTI6:
		DEX             		;THROUGH YET?
		BPL 	@PRTI1


		PLY
		PLX
		PLA
		
		RTS

numConvT10L:
	.byte 		<1
	.byte 		<10
	.byte		<100
	.byte		<1000
	.byte		<10000

numConvT10H:		
	.byte		>1
	.byte		>10
	.byte		>100
	.byte		>1000
	.byte		>10000


VEC_CPU_IRQ		= $FFFE
VEC_CPU_RESET	= $FFFC
VEC_CPU_NMI 	= $FFFA


;-----------------------------------------------------------
initIRQ:
;-----------------------------------------------------------
		LDA	#<plyrIRQ		;install our handler
		STA	VEC_CPU_IRQ
		LDA	#>plyrIRQ
		STA	VEC_CPU_IRQ + 1

		LDA	#<plyrNOP		;install our handler
		STA	VEC_CPU_RESET
		LDA	#>plyrNOP
		STA	VEC_CPU_RESET + 1

		LDA	#<plyrNOP		;install our handler
		STA	VEC_CPU_NMI
		LDA	#>plyrNOP
		STA	VEC_CPU_NMI + 1

;	make sure that the IO port is set to output
		LDA	$00
		ORA	#$07
		STA	$00
		
;	Now, exclude BASIC + KERNAL from the memory map 
		LDA	#$1D
		STA	$01

		LDA	#%01111111		;We'll always want rasters
		AND	$D011		;    less than $0100
		STA	$D011
		
		LDA	#$19
		STA	$D012
		
		LDA	#$01			;Enable raster irqs
		STA	$D01A

		CLI

		RTS


;-----------------------------------------------------------
initState:
;-----------------------------------------------------------
;	lower case
		LDA	#$16
		STA	$D018

;	Normal text mode
;		LDA	#$00
		LDA	#$80
		STA	$D054

;	Prevent VIC-II compatibility changes
		LDA	#$80
		TRB	$D05D		
		
		LDA	#$10
		STA	$D020
		LDA	#$00
		STA	$D021

;	Set the location of screen RAM
		LDA	#<ADDR_SCREEN
		STA	$D060
		LDA	#>ADDR_SCREEN
		STA	$D061
		LDA	#$00
		STA	$D062
		STA	$D063

;	Use PALETTE RAM entries for colours 0 - 15
		LDA	$D030
		ORA	#$04
		STA	$D030
	
;	Set VIC to use 80 column mode display for 640x200 (bit 7)
		LDA	#$E0
		STA	$D031

; 	and 160 bytes (80 16-bit characters) per row
		LDA #<$A0
		STA $D058
		LDA #>$A0
		STA $D059

;	80 cell lines
		LDA	#$50
		STA	$D05E

;	Enable 16 bit char numbers (bit0) and 
;	full color for chars>$ff (bit2)
;		LDA	#$05
		LDA	#$85
		STA	$D054

		LDA	#$00
		STA	$D064
		LDA	#$08
		STA	$D065

;	Enable Rewrite double buffering to prevent 
;	clipping in FCM (bit 7)
		LDA #$80
		TRB $D051

;	Adjust D04C TEXTXPOS
		LDA	#$50
		STA	$D04C

		LDA	$D04D
		AND	#$F0
		STA	$D04D

		RTS


;-----------------------------------------------------------
setCoefficient:
;-----------------------------------------------------------
		STX	$D6F4

		STX	$D6F4
		STX	$D6F4
		STX	$D6F4
		STX	$D6F4

		STA	$D6F5

		RTS


;-----------------------------------------------------------
setMasterVolume:
;-----------------------------------------------------------
;	Check if on Nexys - need the amplifier on (bit 0)
		LDA	$D629
		AND	#$40
		BEQ	@nonnexys

		LDA	#$01
		STA	valMnchDummy
		JMP	@cont0

@nonnexys:
		LDA	#$00
		STA	valMnchDummy
		
@cont0:
		LDX	#$1E				;Speaker Left master 
		LDA	valMnchMsVol
		ORA	valMnchDummy

		JSR	setCoefficient

		LDX	#$1F
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		LDX	#$3E				;Speaker right master
		LDA	valMnchMsVol
		ORA	valMnchDummy

		JSR	setCoefficient

		LDX	#$3F
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		LDX	#$DE				;Headphones right? master
		LDA	valMnchMsVol
		ORA	valMnchDummy

		JSR	setCoefficient

		LDX	#$DF
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		LDX	#$FE				;Headphones left? master
		LDA	valMnchMsVol
		ORA	valMnchDummy

		JSR	setCoefficient

		LDX	#$FF
		LDA	valMnchMsVol + 1
		JSR	setCoefficient

		RTS

;-----------------------------------------------------------
setLeftLVolume:
;-----------------------------------------------------------
		LDX	#$10				;Speaker left digi left
		LDA	valMnchLLVol
		JSR	setCoefficient

		LDX	#$11
		LDA	valMnchLLVol + 1
		JSR	setCoefficient

		LDX	#$F0				;Headphones left? digi left
		LDA	valMnchLLVol
		JSR	setCoefficient

		LDX	#$F1
		LDA	valMnchLLVol + 1
		JSR	setCoefficient
		
		RTS


;-----------------------------------------------------------
setLeftRVolume:
;-----------------------------------------------------------
		LDX	#$12				;Speaker left, digi right
		LDA	valMnchLRVol
		JSR	setCoefficient

		LDX	#$13
		LDA	valMnchLRVol + 1
		JSR	setCoefficient

		LDX	#$F2				;Headphone left?, digi right
		LDA	valMnchLRVol
		JSR	setCoefficient

		LDX	#$F3
		LDA	valMnchLRVol + 1
		JSR	setCoefficient
		
		RTS


;-----------------------------------------------------------
setRightRVolume:
;-----------------------------------------------------------
		LDX	#$32				;Speaker right, digi right
		LDA	valMnchRRVol
		JSR	setCoefficient

		LDX	#$33
		LDA	valMnchRRVol + 1
		JSR	setCoefficient

		LDX	#$D2				;Headphone right?, digi right
		LDA	valMnchRRVol
		JSR	setCoefficient

		LDX	#$D3
		LDA	valMnchRRVol + 1
		JSR	setCoefficient
		
		RTS

;-----------------------------------------------------------
setRightLVolume:
;-----------------------------------------------------------
		LDX	#$30				;Speaker right, digi left
		LDA	valMnchRLVol
		JSR	setCoefficient

		LDX	#$31
		LDA	valMnchRLVol + 1
		JSR	setCoefficient

		LDX	#$D0				;Headphone right?, digi left
		LDA	valMnchRLVol
		JSR	setCoefficient

		LDX	#$D1
		LDA	valMnchRLVol + 1
		JSR	setCoefficient

		RTS


;-----------------------------------------------------------
initAudio:
;-----------------------------------------------------------
		LDX	#$00
		LDA	#$00
@loop:
		JSR	setCoefficient

		INX
		BNE	@loop

;	Check if on Nexys - mono to right side although appears
;	on left.
		LDA	$D629
		AND	#$40
		BEQ	@cont0

		LDA	#$00
		STA	valMnchLLVol
		STA	valMnchLRVol
		STA	valMnchLLVol + 1
		STA	valMnchLRVol + 1

		LDA	#$EE
		STA	valMnchRLVol
		STA	valMnchRRVol
		LDA	#$7F
		STA	valMnchRLVol + 1
		STA	valMnchRRVol + 1

@cont0:
		JSR	setMasterVolume
		JSR	setLeftLVolume
		JSR	setLeftRVolume
		JSR	setRightRVolume
		JSR	setRightLVolume

		RTS


;		LDX	#$C2
;		LDA	#$15
;		JSR	setCoefficient
;
;		LDX	#$C3
;		LDA	#$80
;		JSR	setCoefficient
;
;		LDX	#$D0
;		LDA	#$16
;		JSR	setCoefficient
;
;		LDX	#$D1
;		LDA	#$40
;		JSR	setCoefficient
;
;		LDX	#$E2
;		LDA	#$16
;		JSR	setCoefficient
;
;		LDX	#$e3
;		LDA	#$40
;		JSR	setCoefficient
;
;		LDX	#$f0
;		LDA	#$57
;		JSR	setCoefficient
;
;		LDX	#$F1
;		LDA	#$A1
;		JSR	setCoefficient
;
;		LDX	#$F2
;		LDA	#$15
;		JSR	setCoefficient
;
;		LDX	#$F3
;		LDA	#$80
;		JSR	setCoefficient
;
;		RTS


offsX		=	24
offsY		=	50

VIC     	= 	$D000         		; VIC REGISTERS
VICXPOS    	= 	VIC + $00      		; LOW ORDER X POSITION
VICYPOS    	= 	VIC + $01      		; Y POSITION
VICXPOSMSB 	=	VIC + $10      		; BIT 0 IS HIGH ORDER X POSITION

OFFS_SPRPAL	= $10
OFFS_SPRDAT	= ($10 * $04)
SIZE_SPRDAT = $08 * $40 * $04

ADDR_SPRITE0 = $D000

ADDR_SPRPTRS = $4FA0


XPos:           
	.word    	155               	; Current mouse position, X
YPos:           
	.word    	80               	; Current mouse position, Y
	
tempValue:	
	.word		0
strSurprise0:
		.asciiz	"BOING!"
	
;-------------------------------------------------------------------------------
CMOVEX:
;-------------------------------------------------------------------------------
		CLC
		LDA	XPos
		ADC	#offsX
		STA	tempValue
		LDA	XPos + 1
		ADC	#$00
		STA	tempValue + 1
	
		LDA	tempValue
		STA	VICXPOS
		LDA	tempValue + 1
		CMP	#$00
		BEQ	@unset0
	
		LDA	VICXPOSMSB
		ORA	#$01
		STA	VICXPOSMSB
		
		JMP	@next1
	
@unset0:
		LDA	VICXPOSMSB
		AND	#$FE
		STA	VICXPOSMSB
		
@next1:
		CLC
		LDA	XPos
		ADC	#offsX + 16
		STA	tempValue
		LDA	XPos + 1
		ADC	#$00
		STA	tempValue + 1
	
		LDA	tempValue
		STA	VICXPOS + 2
		LDA	tempValue + 1
		CMP	#$00
		BEQ	@unset1
	
		LDA	VICXPOSMSB
		ORA	#$02
		STA	VICXPOSMSB
		
		JMP	@next2
	
@unset1:
		LDA	VICXPOSMSB
		AND	#$FD
		STA	VICXPOSMSB

@next2:
		CLC
		LDA	XPos
		ADC	#offsX + 32
		STA	tempValue
		LDA	XPos + 1
		ADC	#$00
		STA	tempValue + 1
	
		LDA	tempValue
		STA	VICXPOS + 4
		LDA	tempValue + 1
		CMP	#$00
		BEQ	@unset2
	
		LDA	VICXPOSMSB
		ORA	#$04
		STA	VICXPOSMSB
		
		JMP	@next3
	
@unset2:
		LDA	VICXPOSMSB
		AND	#$FB
		STA	VICXPOSMSB

@next3:
		CLC
		LDA	XPos
		ADC	#offsX + 48
		STA	tempValue
		LDA	XPos + 1
		ADC	#$00
		STA	tempValue + 1
	
		LDA	tempValue
		STA	VICXPOS + 6
		LDA	tempValue + 1
		CMP	#$00
		BEQ	@unset3
	
		LDA	VICXPOSMSB
		ORA	#$08
		STA	VICXPOSMSB
		
		RTS
	
@unset3:
		LDA	VICXPOSMSB
		AND	#$F7
		STA	VICXPOSMSB
		
		RTS
	
;-------------------------------------------------------------------------------
CMOVEY:
;-------------------------------------------------------------------------------
		CLC
		LDA	YPos
		ADC	#offsY
		STA	tempValue
		LDA	YPos + 1
		ADC	#$00
		STA	tempValue + 1
	
		LDA	tempValue
		STA	VICYPOS
		STA	VICYPOS + 2
		STA	VICYPOS + 4
		STA	VICYPOS + 6
	
		RTS



dmaSprInitLst:	
	.byte		$0B
	.byte		$00
	
	.byte 		$00
dmaSprCnt:		
	.word 		SIZE_SPRDAT
dmaSprSrc:		
	.word 		$0000
	.byte 		$00
dmaSprDst:		
	.word 		ADDR_SPRITE0
	.byte 		$00
	.byte		$00
	.word 		$0000


dmaPalAnimRLst:	
;	.byte		$0B
;	.byte		$00
;	.byte 		$04
;	.word 		$000C
;	.word 		palAnimR0 + 2
;	.byte 		$00
;	.word 		palAnimR0 + 1
;	.byte 		$00
;	.byte		$00
;	.word 		$0000

dmaPalAnimAGLst:	
	.byte		$0B
	.byte		$00
	.byte 		$00
	.word 		$000C
	.word 		palAnimG0 + 2
	.byte 		$00
	.word 		palAnimG0 + 1
	.byte 		$00
	.byte		$00
	.word 		$0000

dmaPalAnimABLst:	
	.byte		$0B
	.byte		$00
	.byte 		$00
	.word 		$000C
	.word 		palAnimB0 + 2
	.byte 		$00
	.word 		palAnimB0 + 1
	.byte 		$00
	.byte		$00
	.word 		$0000


dmaPalAnimBGLst:	
	.byte		$0B
	.byte		$00
	.byte 		$00
	.word 		$000C
	.word 		palAnimG0 + $0C
	.byte 		$40
	.word 		palAnimG0 + $0D
	.byte 		$40
	.byte		$00
	.word 		$0000

dmaPalAnimBBLst:	
	.byte		$0B
	.byte		$00
	.byte 		$00
	.word 		$000C
	.word 		palAnimB0 + $0C
	.byte 		$40
	.word 		palAnimB0 + $0D
	.byte 		$40
	.byte		$00
	.word 		$0000


cntMove0:
	.byte		$02
cntAnim0:
	.byte		$06

valTmpG0:
	.byte		$00
valTmpB0:
	.byte		$00

valDeltaX:
	.word		$01
valDeltaY:
	.word		$FFFE

palAnimR0:
	.byte		$00, $EF, $EF, $EF, $EF, $EF, $EF, $EF, $EF, $EF, $EF, $EF, $EF, $00
palAnimG0:
	.byte		$00, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00
palAnimB0:
	.byte		$00, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00



;-------------------------------------------------------------------------------
animBall:
;-------------------------------------------------------------------------------
		LDX	cntMove0
		DEX
		BEQ	@begin

		STX	cntMove0
		JMP	@pal

@begin:
		LDA	YPos
		CMP	#$25
		BCS	@medium

		CMP	#$55
		BCS	@fast

		LDA	#$03
		STA	cntMove0
		JMP	@update

@medium:
		LDA	#$02
		STA	cntMove0
		JMP	@update

@fast:
		LDA	#$01
		STA	cntMove0

@update:
		LDA	XPos
		ORA	XPos + 1

		BEQ	@revx

		LDA	XPos + 1
		CMP	#>255
		BNE	@movx

		LDA	XPos
		CMP	#<255
		BCC	@movx

		BEQ	@fwdx

@movx:
		CLC
		LDA	XPos
		ADC	valDeltaX
		STA	XPos
		LDA	XPos + 1
		ADC	valDeltaX + 1
		STA	XPos + 1

		JMP	@tsty

@revx:
		LDA	#$01
		STA	valDeltaX
		LDA	#$00
		STA	valDeltaX + 1
		JMP	@movx

@fwdx:
		LDA	#<-1
		STA	valDeltaX
		LDA	#>-1
		STA	valDeltaX + 1
		JMP	@movx

@tsty:
		LDA	YPos
		ORA	YPos + 1
		BEQ	@revy

		LDA	YPos 
		CMP	#135
		BCS	@fwdy

@movy:
		CLC
		LDA	YPos
		ADC	valDeltaY
		STA	YPos
		LDA	YPos + 1
		ADC	valDeltaY + 1
		STA	YPos + 1

		JMP	@tstpal

@revy:
		LDA	#$02
		STA	valDeltaY
		LDA	#$00
		STA	valDeltaY + 1
		JMP	@movy

@fwdy:
		LDA	#<-1
		STA	valDeltaY
		LDA	#>-1
		STA	valDeltaY + 1
		JMP	@movy
		
@tstpal:
		JSR	CMOVEX
		JSR	CMOVEY

@pal:
		LDA	valDeltaX
		BMI	@pala

		JSR	animPaletteB
		RTS

@pala:
		JSR	animPaletteA
		RTS


;-------------------------------------------------------------------------------
animPaletteB:
;-------------------------------------------------------------------------------
		LDX	cntAnim0
		DEX
		BEQ	@begin

		STX	cntAnim0
		RTS

@begin:
		LDA	valDeltaY + 1
		BEQ	@fast

		LDA	#$03
		STA	cntAnim0
		JMP	@update

@fast:
		LDA	#$01
		STA	cntAnim0

@update:
;		LDA	palAnimR0 + $01
;		STA	palAnimR0 + $0D

		LDA	palAnimG0 + $0C
		STA	valTmpG0

		LDA	palAnimB0 + $0C
		STA	valTmpB0

		LDX	#$0B
@loop:
		LDA	palAnimG0, X
		STA	palAnimG0 + 1, X

		LDA	palAnimB0, X
		STA	palAnimB0 + 1, X

		DEX
		BNE	@loop

;		LDA #$00
;		STA $D702
;		LDA #>dmaPalAnimBGLst
;		STA	$D701
;		LDA	#<dmaPalAnimBGLst
;		STA	$D705
;
;		LDA #$00
;		STA $D702
;		LDA #>dmaPalAnimBBLst
;		STA	$D701
;		LDA	#<dmaPalAnimBBLst
;		STA	$D705
;
		LDA	valTmpG0
		STA	palAnimG0 + 1

		LDA	valTmpB0
		STA	palAnimB0 + 1


		JSR	loadPalette

		RTS


;-------------------------------------------------------------------------------
animPaletteA:
;-------------------------------------------------------------------------------
		LDX	cntAnim0
		DEX
		BEQ	@begin

		STX	cntAnim0
		RTS

@begin:
		LDA	valDeltaY + 1
		BEQ	@fast

		LDA	#$03
		STA	cntAnim0
		JMP	@update

@fast:
		LDA	#$01
		STA	cntAnim0

@update:
;		LDA	palAnimR0 + $01
;		STA	palAnimR0 + $0D

		LDA	palAnimG0 + $01
		STA	palAnimG0 + $0D

		LDA	palAnimB0 + $01
		STA	palAnimB0 + $0D

		LDA #$00
		STA $D702
		LDA #>dmaPalAnimAGLst
		STA	$D701
		LDA	#<dmaPalAnimAGLst
		STA	$D705

		LDA #$00
		STA $D702
		LDA #>dmaPalAnimABLst
		STA	$D701
		LDA	#<dmaPalAnimABLst
		STA	$D705


		JSR	loadPalette

		RTS


;-------------------------------------------------------------------------------
loadPalette:
;-------------------------------------------------------------------------------
		LDA	$D070
		AND #$3F
		ORA	#$C0
		STA	$D070

		LDX	#$4F
		LDZ	#$FC
@loop8:
		CPZ	#$40
		BCS	@pal0

		TZA
		AND	#$F0
		LSR
		LSR
		LSR
		LSR
		LSR
		STA	$D200, X

		JMP	@pal1

@pal0:
		LDA	#$04
		STA	$D200, X

@pal1:
		TZA
		AND	#$F0
		LSR
		LSR
		LSR
		LSR
		STA	valScrLPix

		TZA
		AND	#$0F
		ASL
		ASL
		ASL
		ASL
		ORA	valScrLPix

		STA	$D300, X

		TZA
		LSR
		CLC
		ADC	#$08
		AND	#$F0

		ORA	#$10

		LSR
		LSR
		LSR
		LSR
		STA	valScrLPix

		TZA
		LSR
		CLC
		ADC	#$08
		AND	#$0F
		ASL
		ASL
		ASL
		ASL
		ORA	valScrLPix

		STA	$D100, X

		TZA
		SEC
		SBC	#$08
		TAZ

		DEX
		CPX	#$10
		BNE	@loop8

		LDA	#$03
		STA	$D310
		LDA	#$02
		STA	$D110
		STA	$D210


		LDA	$D070
		AND #$33
		ORA	#$44
		STA	$D070

		LDX	#$00
@loop:
		LDA	palAnimR0, X
		STA	$D100, X
		STA	$D110, X
		STA	$D120, X
		STA	$D130, X
		STA	$D140, X
		STA	$D150, X
		STA	$D160, X
		STA	$D170, X

		LDA	palAnimG0, X
		STA	$D200, X
		STA	$D210, X
		STA	$D220, X
		STA	$D230, X
		STA	$D240, X
		STA	$D250, X
		STA	$D260, X
		STA	$D270, X

		LDA	palAnimB0, X
		STA	$D300, X
		STA	$D310, X
		STA	$D320, X
		STA	$D330, X
		STA	$D340, X
		STA	$D350, X
		STA	$D360, X
		STA	$D370, X

		INX
		CPX	#$0E
		BNE	@loop

		RTS


;-----------------------------------------------------------
initMemory:
;-----------------------------------------------------------
;	Make the memory area pretty for debugging
		LDA	#$00
		LDX	#$00
@loop1:
		STA	ADDR_DIRFPTRS, X
		STA	ADDR_DIRFPTRS + $0100, X
		STA	ADDR_DIRFPTRS + $0200, X
		STA	ADDR_DIRFPTRS + $0300, X
		STA	ADDR_DIRFPTRS + $0400, X
		STA	ADDR_DIRFPTRS + $0500, X
		STA	ADDR_DIRFPTRS + $0600, X
		INX
		BNE	@loop1

		LDA	$D070
		AND #$33
		ORA	#$44
		STA	$D070


		JSR	loadPalette

		CLC
		LDA	#<BIN_SPRITES
		ADC #<OFFS_SPRDAT
		STA	dmaSprSrc
		LDA	#>BIN_SPRITES
		ADC #>OFFS_SPRDAT
		STA	dmaSprSrc + 1
		
		LDA #$00
		STA $D702
		LDA #>dmaSprInitLst
		STA	$D701
		LDA	#<dmaSprInitLst
		STA	$D705	
		
		LDA	#$00
		STA	$D027
		STA	$D027 + 1
		STA	$D027 + 2
		STA	$D027 + 3
		STA	$D027 + 4
		STA	$D027 + 5
		STA	$D027 + 6
	
		LDA	#<ADDR_SPRPTRS
		STA	$D06C
		LDA	#>ADDR_SPRPTRS
		STA	$D06D

		LDA	#$80
		STA	$D06E
		
		LDA	#<(ADDR_SPRITE0 / 64)
		STA	ADDR_SPRPTRS
		LDA	#>(ADDR_SPRITE0 / 64)
		STA	ADDR_SPRPTRS + 1

;		LDA	#$00
;		STA	ADDR_SPRPTRS + 2
;		STA	ADDR_SPRPTRS + 3

		LDA	#<((ADDR_SPRITE0 + $200) / 64)
		STA	ADDR_SPRPTRS + 2
		LDA	#>((ADDR_SPRITE0 + $200) / 64)
		STA	ADDR_SPRPTRS + 3

;		LDA	#$00
;		STA	ADDR_SPRPTRS + 6
;		STA	ADDR_SPRPTRS + 7

		LDA	#<((ADDR_SPRITE0 + $400) / 64)
		STA	ADDR_SPRPTRS + 4
		LDA	#>((ADDR_SPRITE0 + $400) / 64)
		STA	ADDR_SPRPTRS + 5

;		LDA	#$00
;		STA	ADDR_SPRPTRS + 10
;		STA	ADDR_SPRPTRS + 11

		LDA	#<((ADDR_SPRITE0 + $600) / 64)
		STA	ADDR_SPRPTRS + 6
		LDA	#>((ADDR_SPRITE0 + $600) / 64)
		STA	ADDR_SPRPTRS + 7

;Palette control for sprites
;		LDA	$D049
;		ORA	#$F0
;		AND	#$0F
;		STA	$D049
		
;		LDA	$D04B
;		ORA	#$F0
;		AND	#$0F
;		STA $D04B

;Enable 16colour sprite 0		
		LDA #$FF                    
		STA $D06B		

		LDA	#$FF
		STA	$D055

		LDA	#$40
		STA	$D056

;	Set to behind characters
;		LDA	#$FF
;		STA	$D01B

;		STA	$D074


		JSR	CMOVEX
		JSR	CMOVEY

		RTS


dmaTexInitList:
	.byte	$0B  				; Request format is F018B
	.byte	$80,$00 			; Source MB 
	.byte	$81,$00 			; Destination MB 
	.byte	$00  				; No more options
		
	.byte	$03					;Command LSB
	.word	$3000				;Count LSB Count MSB
	.word	$0000				;Source Address LSB Source Address MSB
	.byte	$00					;Source Address BANK and FLAGS
	.word	ADDR_TEXTURE		;Destination Address LSB Destination Address MSB
	.byte	$00					;Destination Address BANK and FLAGS
	.byte	$00					;Command MSB
	.word	$0000				;Modulo LSB / Mode Modulo MSB / Mode


;-----------------------------------------------------------
initTexture:
;-----------------------------------------------------------
;	12x12 chars starting at ADDR_TEXTURE
		LDA #$00
		STA $D702
		LDA #>dmaTexInitList
		STA	$D701
		LDA	#<dmaTexInitList
		STA	$D705	
		
		RTS


dmaScnInitList:
	.byte	$0B  				; Request format is F018B
	.byte	$80,$00 			; Source MB 
	.byte	$81,$00 			; Destination MB 
	.byte	$00  				; No more options
		
	.byte	$00					;Command LSB
	.word	$0FA0 - 2			;Count LSB Count MSB
	.word	ADDR_SCREEN			;Source Address LSB Source Address MSB
	.byte	$00					;Source Address BANK and FLAGS
	.word	ADDR_SCREEN + 2		;Destination Address LSB Destination Address MSB
	.byte	$00					;Destination Address BANK and FLAGS
	.byte	$00					;Command MSB
	.word	$0000				;Modulo LSB / Mode Modulo MSB / Mode

dmaClrInitList0:
	.byte	$0B  				; Request format is F018B
	.byte	$80,$00 			; Source MB 
	.byte	$81,$FF 			; Destination MB 
	.byte	$00  				; No more options
		
	.byte	$07					;Command LSB
	.word	$0FA0				;Count LSB Count MSB
	.word	$0000				;Source Address LSB Source Address MSB
	.byte	$00					;Source Address BANK and FLAGS
	.word	$0800				;Destination Address LSB Destination Address MSB
	.byte	$08					;Destination Address BANK and FLAGS
	.byte	$00					;Command MSB
	.word	$0000				;Modulo LSB / Mode Modulo MSB / Mode

dmaClrInitList1:
	.byte	$0B  				; Request format is F018B
	.byte	$80,$00 			; Source MB 
	.byte	$81,$FF 			; Destination MB 
	.byte	$85,$02
	.byte	$00  				; No more options
		
	.byte	$03					;Command LSB
	.word	$0FA0				;Count LSB Count MSB
	.word	$000F				;Source Address LSB Source Address MSB
	.byte	$00					;Source Address BANK and FLAGS
	.word	$0801				;Destination Address LSB Destination Address MSB
	.byte	$08					;Destination Address BANK and FLAGS
	.byte	$00					;Command MSB
	.word	$0000				;Modulo LSB / Mode Modulo MSB / Mode

;-----------------------------------------------------------
initScreen:
;-----------------------------------------------------------
		LDA	#$20
		STA	ADDR_SCREEN
		LDA	#$00
		STA	ADDR_SCREEN + 1

		LDA #$00
		STA $D702
		LDA #>dmaScnInitList
		STA	$D701
		LDA	#<dmaScnInitList
		STA	$D705	
		
		LDA #$00
		STA $D702
		LDA #>dmaClrInitList0
		STA	$D701
		LDA	#<dmaClrInitList0
		STA	$D705	

		LDA	#$00
		STA	valScrOffs
		STA	valScrCntr

@loop0:
		CLC
		LDA	#<(ADDR_SCREEN + (13 * 160) + 120)
		ADC	valScrOffs
		STA	ptrScreenB
		LDA	#>(ADDR_SCREEN + (13 * 160) + 120)
		ADC	#$00
		STA	ptrScreenB + 1

		CLC
		LDA	#<(ADDR_TEXTURE / 64)
		ADC	valScrCntr
		STA	valScrChar
		LDA	#>(ADDR_TEXTURE / 64)
		ADC	#$00
		STA	valScrChar + 1

		LDX	#$00
@loop1:
		LDY	#$00
		LDA	valScrChar
		STA	(ptrScreenB), Y
		INY
		LDA	valScrChar + 1
		STA	(ptrScreenB), Y

		CLC
		LDA	ptrScreenB
		ADC	#<160
		STA	ptrScreenB
		LDA	ptrScreenB + 1
		ADC	#>160
		STA	ptrScreenB + 1

		INW	valScrChar

		INX
		CPX	#$0C
		BNE	@loop1

		CLC
		LDA	valScrCntr
		ADC	#$0C
		STA	valScrCntr

		INC	valScrOffs
		INC	valScrOffs

		LDA	valScrOffs
		CMP	#$18
		BNE	@loop0

;		LDA	#<ADDR_SCREEN
;		STA	ptrScreen
;		LDA	#>ADDR_SCREEN
;		STA	ptrScreen + 1
;	
;		LDX	#$18
;@loop0:
;		LDZ	#$00
;		LDA	#$20
;@loop1:
;		STA	(ptrScreen), Z
;		INZ
;		
;		CPZ	#$50
;		BNE	@loop1
;		
;		CLC
;		LDA	#$50
;		ADC	ptrScreen
;		STA	ptrScreen
;		LDA	#$00
;		ADC	ptrScreen + 1
;		STA	ptrScreen + 1
;		
;		DEX
;		BPL	@loop0
;
;		LDA	#<.loword(AD32_COLOUR)
;		STA	ptrScreen
;		LDA	#>.loword(AD32_COLOUR)
;		STA	ptrScreen + 1
;		LDA	#<.hiword(AD32_COLOUR)
;		STA	ptrScreen + 2
;		LDA	#>.hiword(AD32_COLOUR)
;		STA	ptrScreen + 3
;
;		LDX	#$18
;@loop2:
;		LDZ	#$00
;		LDA	#$0F
;@loop3:
;		NOP
;		STA	(ptrScreen), Z
;		INZ
;
;		CPZ	#$50
;		BNE	@loop3
;		
;		CLC
;		LDA	#$50
;		ADC	ptrScreen
;		STA	ptrScreen
;		LDA	#$00
;		ADC	ptrScreen + 1
;		STA	ptrScreen + 1
;		
;		DEX
;		BPL	@loop2

		LDA	#<(.loword(AD32_COLOUR) + (6 * 160))
		STA	ptrScreen
		LDA	#>(.loword(AD32_COLOUR) + (6 * 160))
		STA	ptrScreen + 1
		LDA	#<.hiword(AD32_COLOUR)
		STA	ptrScreen + 2
		LDA	#>.hiword(AD32_COLOUR)
		STA	ptrScreen + 3

		LDZ	#$00
		LDY	#$00
@loop4:
		LDX	#$00
@loop5:
		LDA	valVolColrs0, X
		INZ
		NOP
		STA	(ptrScreen), Z
		INZ
		INX
		CPX	#$0B
		BNE	@loop5

		INZ
		INZ
		INY
		CPY	#$04
		BNE	@loop4

		LDA	#<(.loword(AD32_COLOUR) + (14 * 160))
		STA	ptrScreen
		LDA	#>(.loword(AD32_COLOUR) + (14 * 160))
		STA	ptrScreen + 1
		LDA	#<.hiword(AD32_COLOUR)
		STA	ptrScreen + 2
		LDA	#>.hiword(AD32_COLOUR)
		STA	ptrScreen + 3

		LDZ	#$00
		LDY	#$00
@loop6:
		LDX	#$00
@loop7:
		LDA	valVolColrs0, X
		INZ
		NOP
		STA	(ptrScreen), Z
		INZ
		INX
		CPX	#$0B
		BNE	@loop7

		INZ
		INZ
		INY
		CPY	#$03
		BNE	@loop6

		RTS

;-----------------------------------------------------------
initM65IOFast:
;-----------------------------------------------------------
;	Go fast, first attempt
		LDA	#65
		STA	$00

;	Enable M65 enhanced registers
		LDA	#$47
		STA	$D02F
		LDA	#$53
		STA	$D02F
;	Switch to fast mode, be sure
; 	1. C65 fast-mode enable
		LDA 	$D031
		ORA 	#$40
		STA 	$D031
; 	2. MEGA65 40.5MHz enable (requires C65 or C128 fast mode to truly enable, 
;	hence the above)
;		LDA 	#$40
		LDA 	#$C0
		TSB 	$D054
		
		RTS

	.if	DEF_MNCH_USEMINI
	.include	"minime.s"
	.else
	.include	"bigglesworth.s"
	.endif

BIN_SPRITES:
	.incbin	"amiga2.bin"