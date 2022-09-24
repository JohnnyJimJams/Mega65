;===========================================================
;Peppito MOD Playback Driver
;
;Version 0.14A
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

;-----------------------------------------------------------
TBL_PPTO_JUMP:
	JMP	peppitoInit				;+0
	JMP	peppitoPlay				;+3
	JMP	peppitoNOP				;+6
	JMP	peppitoPrepare			;+9
	JMP	peppitoStop				;+C


ptrPepTmpA	=	$A0
ptrPepChan	=	$A2

ptrPepModF	=	$B0
ptrPepMSeq	=	$B4
ptrPepPtrn	=	$B8
ptrPepSmpD	=	$BC


VAL_FAC_AMIGARATEL	=	$AB6F
VAL_FAC_AMIGARATEH	=	$000D


;This is "logical" but may be slightly off?
; 2^16   *  40500000 / 2 / 28800 / 428
;VAL_FAC_M65RATERTL	=	$A490
;VAL_FAC_M65RATERTH	=	$0001

;I read somewhere about 28837 being the actual rate on Amiga
;VAL_FAC_M65RATERTL	=	$A406
;VAL_FAC_M65RATERTH	=	$0001

;From testing
VAL_FAC_M65RATERTL	=	$A3A0
VAL_FAC_M65RATERTH	=	$0001

;experiment
;VAL_FAC_M65RATERTL	=	$8C00
;VAL_FAC_M65RATERTH	=	$0001





	.struct	PEP_INSMHDR
		strName		.res	22
		bewSampLen	.res	2
		sbyFineTune	.byte
		sbyVolume	.byte
		bewLoopStrt	.res	2
		bewLoopLen	.res	2
	.endstruct

	.struct	PEP_INSDATA
		ptrHdr		.res	4
		valVol		.byte
		valFTune	.byte
		valSLen		.word
		valLStrt	.word
		valLLen		.word
		ptrSmpD		.res	4
	.endstruct

	.struct	PEP_NOTDATA
		valKey		.word
		valIns		.byte
		valEff		.byte
		valPrm		.byte
	.endstruct

	.struct	PEP_CHNDATA
		recNote		.tag	PEP_NOTDATA
		valVol		.byte
		valFTune	.byte
		valAssIns	.byte
		valSelIns	.byte
		valSmpOffs	.word
		valPeriod	.word
		valPrtPer	.word
		valPrtSpd	.byte
		valVtPhs	.byte
		valVibAdd	.byte
		valVibSpd	.byte
		valVibDep	.byte
		valFxCnt	.byte
		valPtnLRow	.byte
	.endstruct

	.assert	.sizeof(PEP_CHNDATA) < 256, error, "Channel data too large!"


adrPepMODL:
	.word	$0000
adrPepMODH:
	.word	$0000

cntPepTick:
	.byte	$00
cntPepPRow:
	.byte	$00
cntPepSeqP:
	.byte	$00

valPepSped:
	.byte	$06
valPepPBrk:
	.byte	$00
valPepNRow:
	.byte	$00
valPepSLen:
	.byte	$7F
valPepSRst:
	.byte	$00
valPepChan:
	.byte	$00

valPepMaxI:
	.byte	$00
valPepMaxP:
	.byte	$00

cntPepPtnL:
	.byte	$FF
valPepPLCh:
	.byte	$00

valPepTmp0:
	.word	$0000
valPepTmp1:
	.word	$0000
valPepTmp2:
	.word	$0000
valPepTmp3:
	.word	$0000
valPepTmp4:
	.word	$0000

adrPepPtn0:
	.repeat	128
	.word	$0000
	.word	$0000
	.endrepeat

recPepIns0:
	.repeat	32
	.res	.sizeOf(PEP_INSDATA)
	.endrepeat

idxPepIns0:
	.repeat	32, ins
	.byte	<(recPepIns0 + (.sizeOf(PEP_INSDATA) * ins))
	.byte	>(recPepIns0 + (.sizeOf(PEP_INSDATA) * ins))
	.endrepeat

recPepChn0:
	.repeat	4
	.res	.sizeOf(PEP_CHNDATA)
	.endrepeat

idxPepChn0:
	.repeat	4, chn
	.byte	<(recPepChn0 + (.sizeof(PEP_CHNDATA) * chn))
	.byte	>(recPepChn0 + (.sizeof(PEP_CHNDATA) * chn))
	.endrepeat

valPepMRg0:
	.res	8, $00

valPepSig0:
	.byte	$4D, $2E, $4B, $2E
	.byte	$4D, $21, $4B, $21
	.byte	$46, $4C, $54, $34
	.byte	$46, $4C, $54, $38

valPepSin0:
	.byte	0,  24,  49,  74,  97, 120, 141, 161
	.byte	180, 197, 212, 224, 235, 244, 250, 253
	.byte	255, 253, 250, 244, 235, 224, 212, 197
	.byte	180, 161, 141, 120,  97,  74,  49,  24

valPepFTn0:
	.word	4340, 4308, 4277, 4247, 4216, 4186, 4156, 4126
	.word	4096, 4067, 4037, 4008, 3979, 3951, 3922, 3894


	.macro	__PEP_SET_MODF_OFFS	ptr, offs
		CLC
		LDA	adrPepMODL
		ADC	#<offs
		STA	ptr
		LDA	adrPepMODL + 1
		ADC	#>offs
		STA	ptr + 1
		LDA	#$00
		ADC	adrPepMODH
		STA	ptr + 2
		LDA	#$00
		ADC	adrPepMODH + 1
		STA	ptr + 3
	.endmacro

	.macro	__PEP_ADD_PTR32_IMM16	ptr, offs
		CLC
		LDA	#<offs
		ADC	ptr
		STA	ptr
		LDA	#>offs
		ADC	ptr + 1
		STA	ptr + 1
		LDA	#$00
		ADC	ptr + 2
		STA	ptr + 2
		LDA	#$00
		ADC	ptr + 3
		STA	ptr + 3
	.endmacro

	.macro	__PEP_ADD_PTR32_MEM16	ptr, mem
		CLC
		LDA	mem
		ADC	ptr
		STA	ptr
		LDA	mem + 1
		ADC	ptr + 1
		STA	ptr + 1
		LDA	#$00
		ADC	ptr + 2
		STA	ptr + 2
		LDA	#$00
		ADC	ptr + 3
		STA	ptr + 3
	.endmacro

	.macro	__PEP_ADD_PTR16_MEM16	ptr, mem
		CLC
		LDA	mem
		ADC	ptr
		STA	ptr
		LDA	mem + 1
		ADC	ptr + 1
		STA	ptr + 1
	.endmacro

	.macro	__PEP_ADD_PTR16_IMM16	ptr, offs
		CLC
		LDA	#<offs
		ADC	ptr
		STA	ptr
		LDA	#>offs
		ADC	ptr + 1
		STA	ptr + 1
	.endmacro

	.macro	__PEP_ASL_MEM16	mem
		CLC
		LDA	mem
		ASL
		STA	mem
		LDA	mem + 1
		ROL
		STA	mem + 1
	.endmacro

	.macro	__PEP_LSR_MEM16	mem
		CLC
		LDA	mem + 1
		LSR
		STA	mem + 1
		LDA	mem
		ROR
		STA	mem
	.endmacro

	.macro	__PEP_MOV_PTR32_IND32 ptr, ind
		LDA	ptr
		STA	(ind), Y
		INY
		LDA	ptr + 1
		STA	(ind), Y
		INY
		LDA	ptr + 2
		STA	(ind), Y
		INY
		LDA	ptr + 3
		STA	(ind), Y
		INY
	.endmacro

	.macro	__PEP_MUL_MEM8_MEM8 mem0, mem1
		LDA	mem0
		STA	$D770
		LDA	#$00
		STA	$D771
		STA	$D772
		STA	$D773

		LDA	mem1
		STA	$D774
		LDA	#$00
		STA	$D775
		STA	$D776
		STA	$D777

;	Result in $D77A-
	.endmacro

	.macro	__PEP_MUL_MEM16_MEM16 mem0, mem1
		LDA	mem0
		STA	$D770
		LDA	mem0 + 1
		STA	$D771
		LDA	#$00
		STA	$D772
		STA	$D773

		LDA	mem1
		STA	$D774
		LDA	mem1 + 1
		STA	$D775
		LDA	#$00
		STA	$D776
		STA	$D777

;	Result in $D77A-
	.endmacro


	.macro	__PEP_DIV_MEM16_IMM16 mem, imm
		LDA	mem
		STA	$D770
		LDA	mem + 1
		STA	$D771
		LDA	#$00
		STA	$D772
		STA	$D773

		LDA	#<imm
		STA	$D774
		LDA	#>imm
		STA	$D775
		LDA	#$00
		STA	$D776
		STA	$D777

		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020

;	Result in $D76C-
	.endmacro

	.macro	__PEP_DIV_MEM32_IMM16 mem, imm
		LDA	mem
		STA	$D770
		LDA	mem + 1
		STA	$D771
		LDA	mem + 2
		STA	$D772
		LDA	mem + 3
		STA	$D773

		LDA	#<imm
		STA	$D774
		LDA	#>imm
		STA	$D775
		LDA	#$00
		STA	$D776
		STA	$D777

		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020

;	Result in $D76C-
	.endmacro


;-----------------------------------------------------------
peppitoNOP:
;-----------------------------------------------------------
		RTS

;-----------------------------------------------------------
peppitoInit:
;-----------------------------------------------------------
;@halt:
;		INC	$D020
;		JMP	@halt

		LDA	#$00
		STA	valPepPBrk
		STA	valPepNRow

		STA	cntPepSeqP

		LDA	#$01
		STA	cntPepTick
		
		LDA	#$06
		STA	valPepSped

		LDA	#$00
		STA	valPepMaxP

		LDA	#$FF
		STA	cntPepPtnL
		STA	valPepPLCh

		__PEP_SET_MODF_OFFS ptrPepModF, $0438
		LDZ	#$00
		NOP	
		LDA	(ptrPepModF), Z
		STA	valPepTmp0
		INZ
		NOP	
		LDA	(ptrPepModF), Z
		STA	valPepTmp0 + 1
		INZ
		NOP	
		LDA	(ptrPepModF), Z
		STA	valPepTmp0 + 2
		INZ
		NOP	
		LDA	(ptrPepModF), Z
		STA	valPepTmp0 + 3

		LDA	#$10
		STA	valPepMaxI

		LDZ	#$00
@loop1:
		LDY	#$00
		
		TZA
		ASL
		ASL
		TAX

@loop2:
		LDA	valPepSig0, X
		CMP	valPepTmp0, Y
		BNE	@next1

		INX
		INY
		CPY	#$04
		BNE	@loop2

		LDA	#$20
		STA	valPepMaxI
		JMP	@cont1

@next1:
		INZ
		CPZ	#$04
		BNE	@loop1

@cont1:
		LDA	valPepMaxI
		CMP	#$10
		BNE	@ins320

		__PEP_SET_MODF_OFFS ptrPepModF, $01D6
		JMP	@cont2

@ins320:
		__PEP_SET_MODF_OFFS ptrPepModF, $03B6

@cont2:
		LDZ	#$00
		NOP
		LDA	(ptrPepModF), Z

		AND	#$7F
		STA	valPepSLen

		INZ

		NOP
		LDA	(ptrPepModF), Z

		AND	#$7F
		STA	valPepSRst

		LDA	valPepSLen
		CMP	valPepSRst
		BCS	@cont0

		LDA	#$00
		STA	valPepSRst

@cont0:
		LDA	valPepMaxI
		CMP	#$10
		BNE	@ins321

		__PEP_SET_MODF_OFFS ptrPepModF, $01D8
		JMP	@cont3

@ins321:
		__PEP_SET_MODF_OFFS ptrPepMSeq, $03B8

@cont3:
		LDZ	#$00
@loop0:
		NOP
		LDA	(ptrPepMSeq), Z

		CMP	valPepMaxP
		BCC	@next0

		STA	valPepMaxP

@next0:
		INZ
		CPZ	#$80
		BNE	@loop0

		INC	valPepMaxP

		JSR	peppitoReadSeq

		JSR	peppitoReadIns

		JSR	peppitoClearChans

		RTS


;-----------------------------------------------------------
peppitoPlay:
;-----------------------------------------------------------
		JSR	peppitoSaveState

		DEC	cntPepTick
		BNE	@procTick

		LDA	valPepSped
		STA	cntPepTick

		JSR	peppitoPerformRow
		JMP	@exit

@procTick:
		JSR	pepptioPerformTick

@exit:
		JSR	peppitoRestoreState

		RTS


;-----------------------------------------------------------
peppitoPrepare:
;-----------------------------------------------------------
		RTS


;-----------------------------------------------------------
peppitoStop:
;-----------------------------------------------------------
;	Disable DMA audio
		LDA	#$00
		STA	$D711

		LDA	#$01
		STA	cntPepTick

		RTS


;-----------------------------------------------------------
peppitoClearChans:
;-----------------------------------------------------------
		LDX	#$00
@loop0:
		PHX
		TXA
		ASL
		TAX

		LDA	idxPepChn0, X
		STA	ptrPepTmpA
		LDA	idxPepChn0 + 1, X
		STA	ptrPepTmpA + 1

		LDY	#$00
		LDA	#$00
@loop1:
		STA	(ptrPepTmpA), Y
		INY

		CPY	#.sizeOf(PEP_CHNDATA)
		BNE	@loop1

		PLX
		INX	
		CPX	#$04
		BNE	@loop0

		LDA	#$00
		STA	$D720
		STA	$D730
		STA	$D740
		STA	$D750

		RTS


;-----------------------------------------------------------
peppitoSaveState:
;-----------------------------------------------------------
		LDX	#$00

@loop0:
		LDA	$D770, X
		STA	valPepMRg0, X

		INX
		CPX	#$08
		BNE	@loop0

		RTS


;-----------------------------------------------------------
peppitoRestoreState:
;-----------------------------------------------------------
		LDX	#$00

@loop0:
		LDA	valPepMRg0, X
		STA	$D770, X

		INX
		CPX	#$08
		BNE	@loop0
		
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020

		RTS


;-----------------------------------------------------------
peppitoReadIns:
;-----------------------------------------------------------
		__PEP_SET_MODF_OFFS ptrPepModF, $0014

		LDX	#$01
@loop:

;@halt:
;		INC	$D020
;		JMP	@halt

		TXA
		ASL
		TAY
		LDA	idxPepIns0, Y
		STA	ptrPepTmpA
		INY
		LDA	idxPepIns0, Y
		STA	ptrPepTmpA + 1

		LDY	#PEP_INSDATA::ptrHdr
		__PEP_MOV_PTR32_IND32 ptrPepModF, ptrPepTmpA

;	Sample length
		LDZ	#$16

		NOP
		LDA	(ptrPepModF), Z
		STA	valPepTmp0 + 1
		INZ
		
		NOP
		LDA	(ptrPepModF), Z
		STA	valPepTmp0 

		__PEP_ASL_MEM16 valPepTmp0

		LDY	#PEP_INSDATA::valSLen
		LDA	valPepTmp0
		STA	valPepTmp4
		STA	(ptrPepTmpA), Y
		INY
		LDA	valPepTmp0 + 1
		STA	valPepTmp4 + 1
		STA	(ptrPepTmpA), Y


;	Sample data
		LDY	#PEP_INSDATA::ptrSmpD
		__PEP_MOV_PTR32_IND32 ptrPepSmpD, ptrPepTmpA

		__PEP_ADD_PTR32_MEM16 ptrPepSmpD, valPepTmp0

;	Loop start
		LDZ	#$1A

		NOP
		LDA	(ptrPepModF), Z
		STA	valPepTmp0 + 1
		STA	valPepTmp2 + 1
		INZ
		
		NOP
		LDA	(ptrPepModF), Z
		STA	valPepTmp0
		STA	valPepTmp2
		INZ

		__PEP_ASL_MEM16 valPepTmp0

;	Loop length
		NOP
		LDA	(ptrPepModF), Z
		STA	valPepTmp1 + 1
		INZ
		
		NOP
		LDA	(ptrPepModF), Z
		STA	valPepTmp1
		INZ

		__PEP_ASL_MEM16 valPepTmp1

;	Check if module stores loop start in bytes

;	If loop start + loop length > sample length
;		valPepTmp3 > valPepTmp4
		CLC
		LDA	valPepTmp0			;start
		ADC	valPepTmp1			;length
		STA	valPepTmp3
		LDA	valPepTmp0 + 1
		ADC	valPepTmp1 + 1
		STA	valPepTmp3 + 1

;	branches to @bytes0 if valPepTmp4 < valPepTmp3
		LDA	valPepTmp4 + 1
		CMP	valPepTmp3 + 1
		BCC	@bytes0
		BNE	@skip0
		LDA	valPepTmp4
		CMP	valPepTmp3
		BCC	@bytes0

		JMP	@skip0

@bytes0:
;	If (loop start / 2) + loop length <= sample length
;		slen < lstrt / 2 + llen
		CLC
		LDA	valPepTmp2			;start / 2
		ADC	valPepTmp1			;length
		STA	valPepTmp3
		LDA	valPepTmp2 + 1
		ADC	valPepTmp1 + 1
		STA	valPepTmp3 + 1

;	branches to @less0 if valPepTmp4 < valPepTmp3
		LDA	valPepTmp4 + 1
		CMP	valPepTmp3 + 1
		BCC	@less0
		BNE	@bytes1
		LDA	valPepTmp4
		CMP	valPepTmp3
		BCC	@less0

@bytes1:
;	loop len:= sample len - loop start
		SEC
		LDA	valPepTmp4
		SBC	valPepTmp0
		STA	valPepTmp1
		LDA	valPepTmp4 + 1
		SBC	valPepTmp0 + 1
		STA	valPepTmp1 + 1

		JMP	@skip0

@less0:
;	loop start:= loop start / 2
		LDA	valPepTmp2
		STA	valPepTmp0
		LDA	valPepTmp2 + 1
		STA	valPepTmp0 + 1

@skip0:
;	if LoopLength < 4 then
;		LoopStart := SampleLength - LoopLength;
		LDA	valPepTmp1 + 1
		BNE	@cont1
		LDA	valPepTmp1 
		CMP	#04
		BCS	@cont1

		SEC
		LDA	valPepTmp4
		SBC	valPepTmp1
		STA	valPepTmp0
		LDA	valPepTmp4 + 1
		SBC	valPepTmp1 + 1
		STA	valPepTmp0 + 1

@cont1:
;	Store loop start and loop length
		LDY	#PEP_INSDATA::valLStrt
		LDA	valPepTmp0
		STA	(ptrPepTmpA), Y
		INY
		LDA	valPepTmp0 + 1
		STA	(ptrPepTmpA), Y
		INY

		LDA	valPepTmp1
		STA	(ptrPepTmpA), Y
		INY
		LDA	valPepTmp1 + 1
		STA	(ptrPepTmpA), Y


;	Fine tune
		LDZ	#$18

		NOP
		LDA	(ptrPepModF), Z
		AND	#$0F
		STA	valPepTmp0
		INZ

		AND	#$08
		STA	valPepTmp0 + 1

;	(FineTune and $07) - (FineTune and $08) + 8;
		SEC
		LDA	valPepTmp0
		AND	#$07
		SBC	valPepTmp0 + 1
		STA	valPepTmp0

		CLC
;		LDA	valPepTmp0
		ADC	#$08
;		STA	valPepTmp0

		LDY	#PEP_INSDATA::valFTune
		STA	(ptrPepTmpA), Y

;	Volume
		NOP
		LDA	(ptrPepModF), Z
		AND	#$7F
;		STA	valPepTmp0

		CMP	#$40
		BCC	@skip1

		LDA	#$40
;		STA	valPepTmp0

@skip1:
		LDY	#PEP_INSDATA::valVol
;		LDA	valPepTmp0
		STA	(ptrPepTmpA), Y


;	Next
		__PEP_ADD_PTR32_IMM16 ptrPepModF, $001E

		INX
		CPX	valPepMaxI
		LBNE	@loop


		RTS


;-----------------------------------------------------------
peppitoReadSeq:
;-----------------------------------------------------------
		LDA	#<adrPepPtn0
		STA	ptrPepTmpA
		LDA	#>adrPepPtn0
		STA	ptrPepTmpA + 1

		LDA	valPepMaxI
		CMP	#$10
		BNE	@ins320

		__PEP_SET_MODF_OFFS ptrPepModF, $0258
		JMP	@cont0

@ins320:
		__PEP_SET_MODF_OFFS ptrPepModF, $043C

@cont0:
		LDZ	#$00
@loop0:
		LDY	#$00
		LDA	ptrPepModF
		STA	(ptrPepTmpA), Y
		INY
		LDA	ptrPepModF + 1
		STA	(ptrPepTmpA), Y
		INY
		LDA	ptrPepModF + 2
		STA	(ptrPepTmpA), Y
		INY
		LDA	ptrPepModF + 3
		STA	(ptrPepTmpA), Y
;		INY

		__PEP_ADD_PTR16_IMM16 ptrPepTmpA, $04
		__PEP_ADD_PTR32_IMM16 ptrPepModF, $0400

		INZ
		CPZ	valPepMaxP
		BNE	@loop0


		LDA	ptrPepModF
		STA	ptrPepSmpD
		LDA	ptrPepModF + 1
		STA	ptrPepSmpD + 1
		LDA	ptrPepModF + 2
		STA	ptrPepSmpD + 2
		LDA	ptrPepModF + 3
		STA	ptrPepSmpD + 3

		RTS


;-----------------------------------------------------------
peppitoChanPorta:
;-----------------------------------------------------------
		LDY	#PEP_CHNDATA::valPeriod
		LDA	(ptrPepChan), Y
		STA	valPepTmp1
		INY
		LDA	(ptrPepChan), Y
		STA	valPepTmp1 + 1

		LDY	#PEP_CHNDATA::valPrtPer
		LDA	(ptrPepChan), Y
		STA	valPepTmp2
		INY
		LDA	(ptrPepChan), Y
		STA	valPepTmp2 + 1

		LDA	valPepTmp1 + 1
		CMP	valPepTmp2 + 1
		BCC	@less0
		BNE	@cont0
		LDA	valPepTmp1
		CMP	valPepTmp2
		BCC	@less0

		JMP	@cont0

@less0:
		CLC
		LDY	#PEP_CHNDATA::valPrtSpd
		LDA	valPepTmp1
		ADC	(ptrPepChan), Y
		STA	valPepTmp1
		LDA	valPepTmp1 + 1
		ADC	#$00
		STA	valPepTmp1 + 1

		LDA	valPepTmp2 + 1
		CMP	valPepTmp1 + 1
		BCC	@less1
		BNE	@cont0
		LDA	valPepTmp2
		CMP	valPepTmp1
		BCC	@less1

		JMP	@cont0

@less1:
		LDA	valPepTmp2
		STA	valPepTmp1
		LDA	valPepTmp2 + 1
		STA	valPepTmp1 + 1

@cont0:
		LDA	valPepTmp2 + 1
		CMP	valPepTmp1 + 1
		BCC	@less2
		BNE	@cont1
		LDA	valPepTmp2
		CMP	valPepTmp1
		BCC	@less2

		JMP	@cont1

@less2:
		SEC
		LDY	#PEP_CHNDATA::valPrtSpd
		LDA	valPepTmp1
		SBC	(ptrPepChan), Y
		STA	valPepTmp1
		LDA	valPepTmp1 + 1
		SBC	#$00
		STA	valPepTmp1 + 1

		LDA	valPepTmp1 + 1
		CMP	valPepTmp2 + 1
		BCC	@less3
		BNE	@cont1
		LDA	valPepTmp1
		CMP	valPepTmp2
		BCC	@less3

		JMP	@cont1

@less3:
		LDA	valPepTmp2
		STA	valPepTmp1
		LDA	valPepTmp2 + 1
		STA	valPepTmp1 + 1

@cont1:
		LDY	#PEP_CHNDATA::valPeriod
		LDA	valPepTmp1
		STA	(ptrPepChan), Y
		INY
		LDA	valPepTmp1 + 1
		STA	(ptrPepChan), Y

		RTS


;-----------------------------------------------------------
peppitoChanVibrato:
;-----------------------------------------------------------
		LDY	#PEP_CHNDATA::valVtPhs
		LDA	(ptrPepChan), Y
		STA	valPepTmp1

		LDY	#PEP_CHNDATA::valVibSpd
		LDA	(ptrPepChan), Y
		STA	valPepTmp1 + 1

		__PEP_MUL_MEM8_MEM8 valPepTmp1, valPepTmp1 + 1

		LDA	$D77A
		STA	valPepTmp1
		LDA	$D77B
		STA	valPepTmp1 + 1

		LDA	valPepTmp1
		AND	#$1F
		TAX

		LDA	valPepSin0, X
		STA	valPepTmp2

		LDY	#PEP_CHNDATA::valVibDep
		LDA	(ptrPepChan), Y

		STA	valPepTmp2 + 1

		__PEP_MUL_MEM8_MEM8 valPepTmp2, valPepTmp2 + 1

		LDA	$D77A
		STA	valPepTmp2
		LDA	$D77B
		STA	valPepTmp2 + 1

		__PEP_DIV_MEM16_IMM16 valPepTmp2, 128

		LDA	$D76C
		STA	valPepTmp2

		LDA	valPepTmp1
		AND	#$20
		BEQ	@update

		SEC
		LDA	#$01
		SBC	valPepTmp2
		STA	valPepTmp2

@update:
		LDY	#PEP_CHNDATA::valVibAdd
		LDA	valPepTmp2
		STA	(ptrPepChan), Y

		RTS


;-----------------------------------------------------------
peppitoChanVolSlide:
;-----------------------------------------------------------
		LDA	valPepTmp0 + 1
		AND	#$0F
		STA	valPepTmp1

		LDA	valPepTmp0 + 1
		LSR
		LSR
		LSR
		LSR

		SEC	
		SBC	valPepTmp1
		STA	valPepTmp1

		LDY	#PEP_CHNDATA::valVol
		CLC
		LDA (ptrPepChan), Y
		ADC	valPepTmp1

		BMI	@setzero

		CMP	#$40
		BCC	@update

		LDA	#$40
@update:
		STA	(ptrPepChan), Y
		RTS

@setzero:
		LDA	#$00
		JMP	@update


;-----------------------------------------------------------
peppitoChanVolUp:
;-----------------------------------------------------------
		LDY	#PEP_CHNDATA::valVol
		CLC
		LDA (ptrPepChan), Y
		ADC	valPepTmp0 + 1

		CMP	#$40
		BCC	@update

		LDA	#$40
@update:
		STA	(ptrPepChan), Y

		RTS


;-----------------------------------------------------------
peppitoChanVolDown:
;-----------------------------------------------------------
		LDY	#PEP_CHNDATA::valVol
		SEC
		LDA (ptrPepChan), Y
		SBC	valPepTmp0 + 1

		BPL	@update

		LDA	#$00
@update:
		STA	(ptrPepChan), Y

		RTS


;-----------------------------------------------------------
peppitoChanPortaUp:
;-----------------------------------------------------------
		LDY	#PEP_CHNDATA::valPeriod
		SEC
		LDA	(ptrPepChan), Y
		SBC	valPepTmp0 + 1
		STA	(ptrPepChan), Y
		INY
		LDA	(ptrPepChan), Y
		SBC	#$00
		STA	(ptrPepChan), Y

		BMI	@setzero

		RTS

@setzero:
		DEY
		LDA	#$00
		STA	(ptrPepChan), Y
		INY
		STA	(ptrPepChan), Y

		RTS


;-----------------------------------------------------------
peppitoChanPortaDown:
;-----------------------------------------------------------
		LDY	#PEP_CHNDATA::valPeriod
		CLC
		LDA	(ptrPepChan), Y
		ADC	valPepTmp0 + 1
		STA	(ptrPepChan), Y
		INY
		LDA	(ptrPepChan), Y
		ADC	#$00
		STA	(ptrPepChan), Y

		BMI	@setmax

		RTS

@setmax:
		DEY
		LDA	#$FF
		STA	(ptrPepChan), Y
		INY
		LDA	#$7F
		STA	(ptrPepChan), Y

		RTS


;-----------------------------------------------------------
peppitoChanTick:
;-----------------------------------------------------------
		LDY	#PEP_CHNDATA::valVtPhs
		LDA	(ptrPepChan), Y
		TAX
		INX
		TXA
		STA	(ptrPepChan), Y

		LDY	#PEP_CHNDATA::valFxCnt
		LDA	(ptrPepChan), Y
		TAX
		INX
		TXA
		STA	(ptrPepChan), Y

		LDY	#PEP_NOTDATA::valEff
		
		LDA	(ptrPepChan), Y
		STA	valPepTmp0
		INY

		LDA	(ptrPepChan), Y
		STA	valPepTmp0 + 1


		LDA	valPepTmp0
		CMP	#$0A
		BNE	@tstnext0

;	Volume slide -------------------------------------------
		JSR	peppitoChanVolSlide
		JSR	peppitoChanUpdVol
		RTS

@tstnext0:
		CMP	#$01
		BNE	@tstnext1

;	Portamento up ------------------------------------------
		JSR	peppitoChanPortaUp
		JSR	peppitoChanUpdFreq
		RTS

@tstnext1:
		CMP	#$02
		BNE	@tstnext2

;	Portamento down ----------------------------------------
		JSR	peppitoChanPortaDown
		JSR	peppitoChanUpdFreq
		RTS

@tstnext2:
		CMP	#$04
		BNE	@tstnext3

;	Vibrato ------------------------------------------------

		JSR	peppitoChanVibrato
		JSR	peppitoChanUpdFreq
		RTS

@tstnext3:
		CMP	#$06
		BNE	@tstnext4

;	Vibrato + Volume Slide ---------------------------------

		JSR	peppitoChanVibrato
		JSR	peppitoChanVolSlide

		JSR	peppitoChanUpdFreq
		JSR	peppitoChanUpdVol

		RTS

@tstnext4:
		CMP	#$03
		BNE	@tstnext5

;	Tone Portamento
		JSR	peppitoChanPorta
		JSR	peppitoChanUpdFreq

		RTS

@tstnext5:
		CMP	#$05
		BNE	@tstnext6

;	Tone Portamento + Volume Slide
		JSR	peppitoChanPorta
		JSR	peppitoChanVolSlide

		JSR	peppitoChanUpdFreq
		JSR	peppitoChanUpdVol

		RTS

@tstnext6:
		CMP	#$19
		BNE	@tstnext7

;	Retrigger ----------------------------------------------
		LDY	#PEP_CHNDATA::valFxCnt
		LDA	(ptrPepChan), Y
		CMP	valPepTmp0 + 1
		BCS	@retrig0

		RTS

@retrig0:
		LDY	#PEP_CHNDATA::valFxCnt
		LDA	#$00
		STA	(ptrPepChan), Y

		JSR	peppitoChanNoteOn
		RTS

@tstnext7:
		CMP	#$1D
		BNE	@tstnext8

;	Note Delay ---------------------------------------------

		LDY	#PEP_CHNDATA::valFxCnt
		LDA	(ptrPepChan), Y
		CMP	valPepTmp0 + 1
		BEQ	@dely0

		RTS

@dely0:
		JSR	peppitoChanTrigger
		RTS


@tstnext8:
		CMP	#$1C
		BNE	@tstnext9

;	Note Cut -----------------------------------------------
		LDY	#PEP_CHNDATA::valFxCnt
		LDA	(ptrPepChan), Y
		CMP	valPepTmp0 + 1
		BEQ	@ntct0

		RTS

@ntct0:
		LDY	#PEP_CHNDATA::valVol
		LDA	#$00
		STA	(ptrPepChan), Y

		JSR	peppitoChanUpdVol
		RTS

@tstnext9:

		RTS

;-----------------------------------------------------------
pepptioPerformTick:
;-----------------------------------------------------------
		LDX	#$00
@loop1:
;		CPX	#$01
;		BEQ	@next
;		CPX	#$02
;		BEQ	@next

		PHX

		STX	valPepChan

		TXA
		ASL
		TAY

		LDA	idxPepChn0, Y
		STA	ptrPepChan
		LDA	idxPepChn0 + 1, Y
		STA	ptrPepChan + 1

		JSR	peppitoChanTick

		PLX
@next:
		INX
		CPX	#$04
		BNE	@loop1

		RTS


;-----------------------------------------------------------
peppitoClearChanPLRow:
;-----------------------------------------------------------
		LDX	#$00
@loop1:
;		PHX

		STX	valPepChan

		TXA
		ASL
		TAY

		LDA	idxPepChn0, Y
		STA	ptrPepChan
		LDA	idxPepChn0 + 1, Y
		STA	ptrPepChan + 1

		LDY	#PEP_CHNDATA::valPtnLRow
		LDA	#$00
		STA	(ptrPepChan), Y

;		PLX
@next:
		INX
		CPX	#$04
		BNE	@loop1

		RTS


;-----------------------------------------------------------
peppitoPerformRow:
;-----------------------------------------------------------
		LDA	valPepNRow
		BPL	@cont0

		LDX	cntPepSeqP
		INX
		STX	valPepPBrk

		LDA	#$00
		STA	valPepNRow

@cont0:
		LDA	valPepPBrk
		BMI	@cont1

		CMP	valPepSLen
		BCC	@more0

		LDA	#$00
		STA	valPepPBrk
		STA	valPepNRow

@more0:
		LDA	valPepPBrk
		BMI	@restart

		CMP	cntPepSeqP
		BCC	@restart

		JMP	@skip0

@restart:

;***FIXME:
;	Do we restart or do we end??

		LDA	valPepSRst
		STA	valPepPBrk

@skip0:
		LDA	valPepPBrk
		STA	cntPepSeqP

		JSR	peppitoClearChanPLRow

		LDA	#$FF
		STA	valPepPBrk

@cont1:
		LDA	valPepNRow
		STA	cntPepPRow

		INC	valPepNRow
		LDA	#$C0
		AND	valPepNRow
		BEQ	@update

		LDA	#$FF
		STA	valPepNRow

@update:
		LDZ	cntPepSeqP
		
		NOP
		LDA	(ptrPepMSeq), Z

		ASL
		ASL
		TAX

		LDA	adrPepPtn0, X
		STA	ptrPepPtrn
		LDA	adrPepPtn0 + 1, X
		STA	ptrPepPtrn + 1
		LDA	adrPepPtn0 + 2, X
		STA	ptrPepPtrn + 2
		LDA	adrPepPtn0 + 3, X
		STA	ptrPepPtrn + 3

		LDA	cntPepPRow
		STA	valPepTmp0
		LDA	#$00
		STA	valPepTmp0 + 1

		__PEP_ASL_MEM16 valPepTmp0
		__PEP_ASL_MEM16 valPepTmp0
		__PEP_ASL_MEM16 valPepTmp0
		__PEP_ASL_MEM16 valPepTmp0

		__PEP_ADD_PTR32_MEM16 ptrPepPtrn, valPepTmp0

		LDZ	#$00
		LDX	#$00
@loop0:
		TXA
		ASL
		TAY

;@halt:
;		INC	$D020
;		JMP	@halt

		LDA	idxPepChn0, Y
		STA	ptrPepTmpA
		LDA	idxPepChn0 + 1, Y
		STA	ptrPepTmpA + 1

;	Note period (key)
		NOP
		LDA	(ptrPepPtrn), Z
		INZ

		STA	valPepTmp0

		AND	#$0F

		LDY	#PEP_NOTDATA::valKey + 1
		STA	(ptrPepTmpA), Y
		DEY

		NOP
		LDA	(ptrPepPtrn), Z
		INZ

		STA	(ptrPepTmpA), Y

;	Note instrument
		LDA	valPepTmp0
		AND	#$10
		STA	valPepTmp0

		NOP
		LDA	(ptrPepPtrn), Z
		INZ

		STA	valPepTmp0 + 1

		AND	#$F0
		LSR
		LSR
		LSR
		LSR
		ORA	valPepTmp0

		LDY	#PEP_NOTDATA::valIns
		STA	(ptrPepTmpA), Y

;	Effect
		LDA	valPepTmp0 + 1
		AND	#$0F
		STA	valPepTmp1

;	Param
		NOP
		LDA	(ptrPepPtrn), Z
		INZ
		STA	valPepTmp1 + 1

		LDA	valPepTmp1
		CMP	#$0E
		BNE	@cont2

		LDA	valPepTmp1 + 1
		LSR
		LSR
		LSR
		LSR
		ORA	#$10
		STA	valPepTmp1

		LDA	valPepTmp1 + 1
		AND	#$0F
		STA	valPepTmp1 + 1

@cont2:
		LDA	valPepTmp1
		BNE	@cont3

		LDA	valPepTmp1 + 1
		BMI	@cont3
		BEQ	@cont3

		LDA	#$0E
		STA	valPepTmp1

@cont3:
		LDY	#PEP_NOTDATA::valEff
		LDA	valPepTmp1
		STA	(ptrPepTmpA), Y

		LDY	#PEP_NOTDATA::valPrm
		LDA	valPepTmp1 + 1
		STA	(ptrPepTmpA), Y

		INX
		CPX	#$04
		LBNE	@loop0


		LDX	#$00
@loop1:
;		CPX	#$01
;		BEQ	@next
;		CPX	#$02
;		BEQ	@next

		PHX

		STX	valPepChan

		TXA
		ASL
		TAY

		LDA	idxPepChn0, Y
		STA	ptrPepChan
		LDA	idxPepChn0 + 1, Y
		STA	ptrPepChan + 1

		JSR	peppitoChanRow

		PLX
@next:
		INX
		CPX	#$04
		BNE	@loop1

;	Enable DMA audio
		LDA	#$80
		STA	$D711


		RTS


;-----------------------------------------------------------
peppitoChanRow:
;-----------------------------------------------------------
;@halt:
;		INC	$D020
;		JMP	@halt
		LDY	#PEP_NOTDATA::valEff
		
		LDA	(ptrPepChan), Y
		STA	valPepTmp0
		INY

		LDA	(ptrPepChan), Y
		STA	valPepTmp0 + 1

		LDA	valPepTmp0
		CMP	#$1D
		BNE	@trigger

		LDA	valPepTmp0 + 1
		BEQ	@trigger

		JMP	@update

@trigger:
		JSR	peppitoChanTrigger

@update:
		JSR	peppitoChanTrigEffect

		RTS


;-----------------------------------------------------------
peppitoMULT10:
;-----------------------------------------------------------
		ASL					;multiply by 2
		STA valPepTmp4		;temp store in TEMP
		ASL					;again multiply by 2 (*4)
		ASL					;again multiply by 2 (*8)
		CLC
		ADC	valPepTmp4		;as result, A = x*8 + x*2
		RTS

;-----------------------------------------------------------
peppitoChanTrigEffect:
;-----------------------------------------------------------
		LDY	#PEP_CHNDATA::valVibAdd
		LDA	#$00
		STA	(ptrPepChan), Y
		LDY	#PEP_CHNDATA::valFxCnt
		STA	(ptrPepChan), Y

		LDY	#PEP_NOTDATA::valEff
		
		LDA	(ptrPepChan), Y
		STA	valPepTmp0
		INY
		LDA	(ptrPepChan), Y
		STA	valPepTmp0 + 1

		LDA	valPepTmp0

		CMP	#$0D
		BNE	@tstnxt0

;	Pattern break-------------------------------------------
		LDA	cntPepPtnL
		BMI	@pbrk0

		JMP	@exit

@pbrk0:
		LDA	valPepPBrk
		BPL	@pbrk1

		LDX	cntPepSeqP
		INX
		STX	valPepPBrk

@pbrk1:
		LDA	valPepTmp0 + 1
		LSR
		LSR
		LSR
		LSR
		JSR	peppitoMULT10
		STA	valPepTmp1

		LDA	valPepTmp0 + 1
		AND	#$0F

		CLC
		ADC	valPepTmp1
		STA	valPepNRow

		CMP	#$40
		LBCC	@exit

		LDA	#$00
		STA	valPepNRow

		JMP	@exit

@tstnxt0:
		CMP	#$0F
		BNE	@tstnxt1

;	Set Speed ----------------------------------------------

		LDA	valPepTmp0 + 1
		LBEQ	@exit

		CMP	#$20
		BCS	@spdch0

		STA	valPepSped
		STA	cntPepTick

		JMP	@exit

@spdch0:
;***FIXME:
;		Tempo := Param
		JMP	@exit

@tstnxt1:
		CMP	#$0C
		BNE	@tstnxt2

;	Set volume ---------------------------------------------
		LDA	valPepTmp0 + 1
		CMP	#$40
		BCC	@svol0

		LDA	#$40

@svol0:
		LDY	#PEP_CHNDATA::valVol
		STA	(ptrPepChan), Y

		JSR	peppitoChanUpdVol
		
		JMP	@exit

@tstnxt2:
		CMP	#$11
		BNE	@tstnxt3

;	Fine Portamento Up -------------------------------------
		JSR	peppitoChanPortaUp
		JSR	peppitoChanUpdFreq

		JMP	@exit

@tstnxt3:
		CMP	#$12
		BNE	@tstnxt4

;	Fine Portamento Down -----------------------------------
		JSR	peppitoChanPortaDown
		JSR	peppitoChanUpdFreq

		JMP	@exit

@tstnxt4:
		CMP	#$1A
		BNE	@tstnxt5

;	Fine Volume Up -----------------------------------------
		JSR	peppitoChanVolUp
		JSR	peppitoChanUpdVol

		JMP	@exit

@tstnxt5:
		CMP	#$1B
		BNE	@tstnxt6

;	Fine Volume Down
		JSR	peppitoChanVolDown
		JSR	peppitoChanUpdVol

		JMP	@exit

@tstnxt6:
		CMP	#$04
		BNE	@tstnxt7

;	Vibrato ------------------------------------------------

		LDA	valPepTmp0 + 1
		LSR
		LSR
		LSR
		LSR

		BNE	@vibspd0

		JMP	@vibcont0

@vibspd0:
		LDY	#PEP_CHNDATA::valVibSpd
		STA	(ptrPepChan), Y

@vibcont0:
		LDA	valPepTmp0 + 1
		AND	#$0F

		BNE	@vibdep0

		JMP	@vibcont1

@vibdep0:
		LDY	#PEP_CHNDATA::valVibDep
		STA	(ptrPepChan), Y

@vibcont1:
		JSR	peppitoChanVibrato
		JSR	peppitoChanUpdFreq

		JMP	@exit

@tstnxt7:
		CMP	#$06
		BNE	@tstnxt8

;	Vibrato + Volume Slide ---------------------------------
		JSR	peppitoChanVibrato
		JSR	peppitoChanUpdFreq

		JMP	@exit

@tstnxt8:
		CMP	#$03
		BNE	@tstnxt9

;	Tone Portamento ----------------------------------------

		LDA	valPepTmp0 + 1
		BNE	@tport0

		JMP	@exit

@tport0:
		LDY	#PEP_CHNDATA::valPrtSpd
		STA	(ptrPepChan), Y

		JSR	peppitoChanUpdFreq
		JMP	@exit

@tstnxt9:
		CMP	#$0B
		BNE	@tstnxta

;	Pattern Jump -------------------------------------------

		LDA	cntPepPtnL
		BPL	@exit

		LDA	valPepTmp0 + 1
		STA	valPepPBrk
		LDA	#$00
		STA	valPepNRow

		JMP	@exit

@tstnxta:
		CMP	#$16
		BNE	@tstnxtb

;	Pattern Loop -------------------------------------------

		LDY	#PEP_CHNDATA::valPtnLRow

		LDA	valPepTmp0 + 1
		BNE	@ptnl0

		LDA	cntPepPRow
		STA	(ptrPepChan), Y

@ptnl0:
		LDA	(ptrPepChan), Y
		CMP	cntPepPRow
		BCS	@exit

		LDA	valPepPBrk
		BPL	@exit

		LDA	cntPepPtnL
		BPL	@ptnl1

		LDA	valPepTmp0 + 1
		STA	cntPepPtnL

		LDA	valPepChan
		STA	valPepPLCh

@ptnl1:
		LDA	valPepChan
		CMP	valPepPLCh
		BNE	@exit

		LDA	cntPepPtnL
		BNE	@ptnl2

		LDX	cntPepPRow
		INX
		TXA
		STA	(ptrPepChan), Y

		JMP	@ptnl3

@ptnl2:
		LDA	(ptrPepChan), Y
		STA	valPepNRow

@ptnl3:
		DEC	cntPepPtnL

		JMP	@exit

@tstnxtb:
		CMP	#$1C
		BNE	@exit

;	Note Cut -----------------------------------------------

		LDA	valPepTmp0 + 1
		BMI	@ntct0
		BEQ	@ntct0

		JMP	@exit

@ntct0:
		LDY	#PEP_CHNDATA::valVol
		LDA	#$00
		STA	(ptrPepChan), Y

		JSR	peppitoChanUpdVol
		JMP	@exit

@exit:
		RTS


;-----------------------------------------------------------
peppitoChanUpdFreq:
;-----------------------------------------------------------
		JSR	peppitoChanCalcFreq

		LDA	valPepChan
		ASL
		ASL
		ASL
		ASL
		TAX

;	Rate
		LDA	$D77A
		STA	$D724, X
		LDA	$D77B
		STA	$D725, X
		LDA	#$00
		STA	$D726, X

		RTS

;-----------------------------------------------------------
peppitoChanUpdVol:
;-----------------------------------------------------------
		LDA	valPepChan
		ASL
		ASL
		ASL
		ASL
		TAX

		LDY	#PEP_CHNDATA::valVol
		LDA	(ptrPepChan), Y

		STA	$D729, X
		LDA	#$00
		LDX	valPepChan
		STA	$D71C, X

		RTS


;-----------------------------------------------------------
peppitoChanTrigger:
;-----------------------------------------------------------
;@halt:
;		INC	$D020
;		JMP	@halt

		LDY	#PEP_NOTDATA::valIns
		LDA	(ptrPepChan), Y
		STA	valPepTmp0

		BEQ	@cont0

		LDY	#PEP_CHNDATA::valAssIns
		STA	(ptrPepChan), Y

		ASL
		TAX
		LDA	idxPepIns0, X
		STA	ptrPepTmpA
		LDA	idxPepIns0 + 1, X
		STA	ptrPepTmpA + 1

		LDY	#PEP_CHNDATA::valSmpOffs
		LDA	#$00
		STA	(ptrPepChan), Y
		INY
		STA	(ptrPepChan), Y

		LDY	#PEP_CHNDATA::valFTune
		LDZ	#PEP_INSDATA::valFTune

		LDA	(ptrPepTmpA), Z
		STA	(ptrPepChan), Y

		LDY	#PEP_CHNDATA::valVol
		LDZ	#PEP_INSDATA::valVol

		LDA	(ptrPepTmpA), Z
		STA	(ptrPepChan), Y

;	If (Instruments[ Ins ].LoopLength > 0) And ( Channel.Instrument > 0 ) Then
		LDY	#PEP_INSDATA::valLLen
		LDA	(ptrPepTmpA), Y
		INY
		ORA (ptrPepTmpA), Y
		BEQ	@cont0

		LDY	#PEP_CHNDATA::valSelIns
		LDA	(ptrPepChan), Y
		BEQ	@cont0

		LDY	#PEP_CHNDATA::valSelIns
		LDA	valPepTmp0
		STA	(ptrPepChan), Y

@cont0:
;***FIXME:
;	If Channel.Note.Effect = $9 Then Begin
;		Channel.SampleOffset := ( Channel.Note.Param And $FF ) Shl 8;
;	End Else If Channel.Note.Effect = $15 Then Begin
;		Channel.FineTune := Channel.Note.Param;
;	End;

		LDY	#PEP_NOTDATA::valKey
		LDA	(ptrPepChan), Y
		STA	valPepTmp0
		INY
		ORA	(ptrPepChan), Y
		LBEQ	@done

;@halt:
;		INC	$D020
;		JMP	@halt

		LDA	(ptrPepChan), Y
		STA	valPepTmp0 + 1

;		Period := ( Channel.Note.Key * FineTuning[ Channel.FineTune And $F ] ) Shr 11;
		LDY	#PEP_CHNDATA::valFTune
		LDA	(ptrPepChan), Y
		AND	#$0F
		ASL
		TAX
		LDA	valPepFTn0, X
		STA	valPepTmp2
		LDA	valPepFTn0 + 1, X
		STA	valPepTmp2 + 1

		__PEP_MUL_MEM16_MEM16 valPepTmp0, valPepTmp2

		LDA	$D778
		STA	valPepTmp1
		LDA	$D779
		STA	valPepTmp1 + 1
		LDA	$D77A
		STA	valPepTmp1 + 2
		LDA	$D77B
		STA	valPepTmp1 + 3

		__PEP_DIV_MEM32_IMM16 valPepTmp1, 2048

		LDA	$D76C
		STA	valPepTmp0
		LDA	$D76D
		STA	valPepTmp0 + 1


;		Channel.PortaPeriod := ( Period Shr 1 ) + ( Period And 1 );
		LDA	valPepTmp0
		STA	valPepTmp1
		LDA	valPepTmp0 + 1
		STA	valPepTmp1 + 1

		__PEP_LSR_MEM16 valPepTmp1

		CLC
		LDA	valPepTmp0
		AND	#$01
		ADC	valPepTmp1
		STA	valPepTmp1
		LDA	#$00
		ADC	valPepTmp1 + 1
		STA	valPepTmp1 + 1

		LDY	#PEP_CHNDATA::valPrtPer
		LDA	valPepTmp1
		STA	(ptrPepChan), Y
		INY
		LDA	valPepTmp1 + 1
		STA	(ptrPepChan), Y

		LDY	#PEP_NOTDATA::valEff
		LDA	(ptrPepChan), Y
		CMP	#$03
		BEQ	@done
		CMP	#$05
		BEQ	@done

		LDY	#PEP_CHNDATA::valAssIns
		LDA	(ptrPepChan), Y
		LDY	#PEP_CHNDATA::valSelIns
		STA	(ptrPepChan), Y

;		Channel.Period:= Channel.PortaPeriod
		LDY	#PEP_CHNDATA::valPeriod
		LDA	valPepTmp1
		STA	(ptrPepChan), Y
		INY
		LDA	valPepTmp1 + 1
		STA	(ptrPepChan), Y

		LDY	#PEP_CHNDATA::valVtPhs
		LDA	#$00
		STA	(ptrPepChan), Y

		JSR	peppitoChanNoteOn

@done:
		RTS


;-----------------------------------------------------------
peppitoChanCalcFreq:
;-----------------------------------------------------------
		LDY	#PEP_CHNDATA::valVibAdd
		LDA	(ptrPepChan), Y
		STA	valPepTmp1

		BPL	@pos

		LDA	#$FF
		STA	valPepTmp1 + 1

		JMP	@cont0

@pos:
		LDA	#$00
		STA	valPepTmp1 + 1

@cont0:
		LDY	#PEP_CHNDATA::valPeriod
		CLC
		LDA	(ptrPepChan), Y
		ADC	valPepTmp1
		STA	valPepTmp1
		INY
		LDA	(ptrPepChan), Y
		ADC	valPepTmp1 + 1
		STA	valPepTmp1 + 1

		BNE	@cont1

		LDA	valPepTmp1
		CMP	#$0E
		BCS	@cont1

		LDA	#<6848
		STA	valPepTmp1
		LDA	#>6848
		STA	valPepTmp1 + 1

@cont1:
;	Amiga frequency
		LDA	#<VAL_FAC_AMIGARATEL
		STA	$D770
		LDA	#>VAL_FAC_AMIGARATEL
		STA	$D771
		LDA	#<VAL_FAC_AMIGARATEH
		STA	$D772
		LDA	#>VAL_FAC_AMIGARATEH
		STA	$D773

		LDA	valPepTmp1
		STA	$D774
		LDA	valPepTmp1 + 1
		STA	$D775
		LDA	#$00
		STA	$D776
		STA	$D777
		
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020
		LDA	$D020
		STA	$D020

		LDA	$D76C
		STA	valPepTmp0
		LDA	$D76D
		STA	valPepTmp0 + 1
		LDA	$D76E
		STA	valPepTmp0 + 2
		LDA	$D76F
		STA	valPepTmp0 + 3

;	M65 frequency
		LDA	#<VAL_FAC_M65RATERTL
		STA	$D770
		LDA	#>VAL_FAC_M65RATERTL
		STA	$D771
		LDA	#<VAL_FAC_M65RATERTH
		STA	$D772
		LDA	#>VAL_FAC_M65RATERTH
		STA	$D773

		LDA	valPepTmp0
		STA	$D774
		LDA	valPepTmp0 + 1
		STA	$D775
		LDA	valPepTmp0 + 2
		STA	$D776
		LDA	valPepTmp0 + 3
		STA	$D777

		RTS


;-----------------------------------------------------------
peppitoChanNoteOn:
;-----------------------------------------------------------
		LDA	valPepChan
;		CMP	#$02
;		BNE	@start
;
;@halt:
;		INC	$D020
;		JMP	@halt
;
;@start:

		ASL
		ASL
		ASL
		ASL
		STA	valPepTmp2

		JSR	peppitoChanCalcFreq

		LDX	valPepTmp2

;	Silence
		LDA	#$00
		STA	$D720, X

		LDY	#PEP_CHNDATA::valSelIns
		LDA	(ptrPepChan), Y

		ASL
		TAY

		LDA	idxPepIns0, Y
		STA	ptrPepTmpA
		LDA	idxPepIns0 + 1, Y
		STA	ptrPepTmpA + 1

;	Rate
		LDA	$D77A
		STA	$D724, X
		LDA	$D77B
		STA	$D725, X
		LDA	#$00
		STA	$D726, X


;	Sample data, is it looping?
		LDY	#PEP_INSDATA::valLLen
		LDA	(ptrPepTmpA), Y
		INY
		ORA	(ptrPepTmpA), Y
		BEQ	@noloop

;	Sample start
		LDY	#PEP_INSDATA::valLStrt
		LDA	(ptrPepTmpA), Y
		STA	valPepTmp0
		INY
		LDA	(ptrPepTmpA), Y
		STA	valPepTmp0 + 1

		LDY	#PEP_INSDATA::ptrSmpD
		CLC
		LDA	(ptrPepTmpA), Y
		ADC	valPepTmp0
		STA	valPepTmp3
		STA	$D721, X
		INY
		LDA	(ptrPepTmpA), Y
		ADC	valPepTmp0 + 1
		STA	valPepTmp3 + 1
		STA	$D722, X
		INY
		LDA	(ptrPepTmpA), Y
		ADC	#$00
		STA	valPepTmp3 + 2
		STA	$D723, X
;		INY

;	Sample play offset
;***FIXME:
;	Should include PEP_CHNDATA::valSmpOffs

		LDY	#PEP_INSDATA::ptrSmpD
		LDA	(ptrPepTmpA), Y
		STA	$D72A, X
		INY
		LDA	(ptrPepTmpA), Y
		STA	$D72B, X
		INY
		LDA	(ptrPepTmpA), Y
		STA	$D72C, X

;	Sample end
		SEC
		LDA	valPepTmp3
		SBC	#$01
		STA	valPepTmp3
		LDA	valPepTmp3 + 1
		SBC	#$00
		STA	valPepTmp3 + 1

		LDY	#PEP_INSDATA::valLLen
		CLC
		LDA	(ptrPepTmpA), Y
		ADC	valPepTmp3
		STA	$D727, X
		INY
		LDA	(ptrPepTmpA), Y
		ADC	valPepTmp3 + 1
		STA	$D728, X

;	Enable DMA channel loop
		LDA	#$C2
		STA	$D720, X

		JMP	@finish

@noloop:
;	Sample start
		LDY	#PEP_INSDATA::ptrSmpD
		LDA	(ptrPepTmpA), Y
		STA	valPepTmp3
		STA	$D721, X
		INY
		LDA	(ptrPepTmpA), Y
		STA	valPepTmp3 + 1
		STA	$D722, X
		INY
		LDA	(ptrPepTmpA), Y
		STA	valPepTmp3 + 2
		STA	$D723, X
		INY

;	Sample play offset
		LDY	#PEP_CHNDATA::valSmpOffs
		CLC
		LDA	(ptrPepChan), Y
		ADC	valPepTmp3
		STA	$D72A, X
		INY
		LDA (ptrPepChan), Y
		ADC	valPepTmp3 + 1
		STA	$D72B, X
		LDA	#$00
		ADC	valPepTmp3 + 2
		STA	$D72C, X

;	Sample end
		LDY	#PEP_INSDATA::valSLen
		CLC
		LDA	(ptrPepTmpA), Y
		ADC	valPepTmp3
		STA	$D727, X
		INY
		LDA	(ptrPepTmpA), Y
		ADC	valPepTmp3 + 1
		STA	$D728, X

;	Enable DMA channel no loop
		LDA	#$82
		STA	$D720, X

@finish:
;	Volume
		LDY	#PEP_CHNDATA::valVol
		LDA	(ptrPepChan), Y
		STA	$D729, X
		LDA	#$00
		LDX	valPepChan
		STA	$D71C, X

		RTS

