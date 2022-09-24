;===========================================================
;biggleswoth simplified SD card DOS replacement for MEGA65
;
;Version 0.14A
;Written by Daniel England of Ecclestial Solutions.
;
;Copyright 2021, Daniel England. All Rights Reserved.
;
;-----------------------------------------------------------
;
;A simple DOS replacement library.  Use bigglesSetFileName
;to describe your file and bigglesOpenFile to open it.
;
;You must put the pages to use for the disk read buffer and
;file name transfer buffer into ptrBigglesBufHi and 
;ptrBigglesXfrHi, respectively.
;
;Supports only character reads but block reads will be added
;in the future.  Read a byte with bigglesReadByte.
;
;-----------------------------------------------------------
;
;I want to release this under the LGPL.  I'll make the 
;commitment and include the licensing infomation soon.
;
;===========================================================


ptrBigglesBufHi	=	$DE

ptrBigglesFNmHi	=	$DF		;deprecated
ptrBigglesXfrHi	=	$DF


ptrBigglesBufOff=	$E2
ptrBigglesBufDir=	$E4
ptrBigglesBufFNm=	$E6
valBigglesFType =	$E8


;-----------------------------------------------------------
bigglesSetFileName:
;	.X		IN	File Name Addr Lo
;	.Y		IN	File Name Addr Hi
;
;	.C		OUT	Set if error
;-----------------------------------------------------------
;***Do error checking 'cause this is the interface

		PHX
		PHY

		JSR	_bigglesCloseAll

		PLY
		PLX

		STX	ptrBigglesBufOff
		STY	ptrBigglesBufOff + 1

		LDA	ptrBigglesXfrHi
		STA	@nmsta + 2

		LDY	#$00
@NameCopyLoop:
		LDA	(ptrBigglesBufOff), Y
@nmsta:
		STA	$0300, Y
		INY
		CMP	#$00
		BNE	@NameCopyLoop

		LDX	#$00
		LDY	ptrBigglesXfrHi

		JSR	_bigglesSetFN

		RTS


;-----------------------------------------------------------
bigglesOpenFile:
;-----------------------------------------------------------
		LDA	flgBigglesErr
		BNE	@err

		JSR	_bigglesOpenFile

		RTS

@err:
		SEC
		RTS


;-----------------------------------------------------------
bigglesCloseFile:
;-----------------------------------------------------------
		JSR	_bigglesCloseAll

		RTS


;-----------------------------------------------------------
bigglesReadByte:
;	.A		OUT	Data
;	.ST_C	OUT	Set if error
;-----------------------------------------------------------
;***Do more error checking 'cause this is the interface
		PHX
		PHY
		PHZ

		JSR	_bigglesReadByte

		PLZ
		PLY
		PLX

		RTS



	;; closedir takes file descriptor as argument (appears in A)
;-----------------------------------------------------------
bigglesCloseDir:
;-----------------------------------------------------------
		PHX

		TAX
		LDA	#$16
		STA	$D640
		NOP

;		LDX	#$00
		PLX

		RTS
	
	;; Opendir takes no arguments and returns File descriptor in A
;-----------------------------------------------------------
bigglesOpenDir:
;-----------------------------------------------------------
;		LDX	#$00
;		LDY	#$00
;		LDZ	#$00
;
;		LDY	ptrBigglesBufHi
;		LDX	#$00

		LDA	#$12
		STA	$D640
		NOP

;		LDX	#$00
		
		RTS


	;; readdir takes the file descriptor returned by opendir as argument
	;; and gets a pointer to a MEGA65 DOS dirent structure.
	;; Again, the annoyance of the MEGA65 Hypervisor requiring a page aligned
	;; transfer area is a nuisance here. We will use $0400-$04FF, and then
	;; copy the result into a regular C dirent structure
	;;
	;; d_ino = first cluster of file
	;; d_off = offset of directory entry in cluster
	;; d_reclen = size of the dirent on disk (32 bytes)
	;; d_type = file/directory type
	;; d_name = name of file
;-----------------------------------------------------------
bigglesReadDir:
;-----------------------------------------------------------
		PHX
		PHY
		PHZ

		PHA
	
;;	FIRST, CLEAR OUT THE DIRENT
;		LDX	#0
;		TXA
;@l1:
;		STA	_readdir_dirent, X
;		DEX
;		BNE	@l1

;@halt0:
;		LDA	#$0E
;		STA	$D020
;		JMP	@halt0
;		LDA	#$00
;		STA	$D020

;	Third, call the hypervisor trap
;	File descriptor gets passed in in X.
;	Result gets written to transfer area we setup 
		PLX
		LDY	ptrBigglesXfrHi
		LDA	#$14
		STA	$D640
		NOP

		BCS	@readDirSuccess

;	Return end of directory
;		LDA #$00
;		LDX #$00

		PLZ
		PLY
		PLX

		SEC

		RTS

@readDirSuccess:
		LDA	#$00
		STA	ptrBigglesBufDir
		LDA	ptrBigglesXfrHi
		STA	ptrBigglesBufDir + 1

		LDA	#$00
		STA	ptrBigglesBufFNm
		LDA	ptrBigglesBufHi
		STA	ptrBigglesBufFNm + 1

;	Copy file name
		LDY	#$3F
@l2:
		LDA	(ptrBigglesBufDir), Y
		STA	(ptrBigglesBufFNm), Y

		DEY
		BPL	@l2


;	make sure it is null terminated
;	ldx $0400+64
;	lda #$00
;	sta _readdir_dirent+4+2+4+2,x
		LDY	#64
		LDA	(ptrBigglesBufDir), Y
		TAY
		LDA	#$00
		STA	(ptrBigglesBufFNm), Y


;	;; Inode = cluster from offset 64+1+12 = 77
;	ldx #$03
;@l3:	
;	lda $0477,x
;	sta _readdir_dirent+0,x
;	dex
;	bpl @l3
;
;	;; d_off stays zero as it is not meaningful here
;	
;	;; d_reclen we preload with the length of the file (this saves calling stat() on the MEGA65)
;	ldx #3
;@l4:	
;	lda $0400+64+1+12+4,x
;	sta _readdir_dirent+4+2,x
;	dex
;	bpl @l4

;	File type and attributes
;	lda $0400+64+1+12+4+4
;	sta _readdir_dirent+4+2+4

		LDY	#64 + 1 + 12 + 4 + 4
		LDA	(ptrBigglesBufDir), Y
		STA	valBigglesFType


;	Return address of dirent structure
;	lda #<_readdir_dirent
;	ldx #>_readdir_dirent
	
		PLZ
		PLY
		PLX

		CLC

		RTS


;-----------------------------------------------------------
bigglesChangeDir:
;-----------------------------------------------------------
		PHA
		PHX
		PHY
		PHZ

		LDA	#$34
		STA	$D640
		NOP
		BCC	@fail

		LDA	#$0C
		STA	$D640
		NOP
		BCC	@fail

		PLZ
		PLY
		PLX
		PLA

		CLC

		RTS

@fail:
		PLZ
		PLY
		PLX
		PLA

		SEC

		RTS


;===========================================================
;===========================================================
;===========================================================

flgBigglesErr:
		.byte	$01
sizBigglesBuf:
		.word	$0000
adrBigglesFN:
		.word	$0000


lstBigglesDMA:
	;; Copy $FFD6E00 - $FFD6FFF down to low memory 
	;; MEGA65 Enhanced DMA options
        .byte $0A  ;; Request format is F018A
        .byte $80,$FF ;; Source is $FFxxxxx
        .byte $81,$00 ;; Destination is $FF
        .byte $00  ;; No more options
        ;; F018A DMA list
        ;; (MB offsets get set in routine)
        .byte $00 ;; copy + last request in chain
        .word $0200 ;; size of copy is 512 bytes
        .word $6E00 ;; starting at $6E00
        .byte $0D   ;; of bank $D
adrBigglesDest:
        .word $8000 ;; destination address is $8000
        .byte $00   ;; of bank $0
        .word $0000 ;; modulo (unused)



;-----------------------------------------------------------
_bigglesOpenFile:
;-----------------------------------------------------------
;		JSR	_bigglesCloseAll

		LDX	adrBigglesFN
		LDY	adrBigglesFN + 1

;		JSR	_bigglesSetFN

		LDA	#$34
		STA	$D640
		NOP
		BCC	@fail

		LDA	#$00
		STA	$D640
		NOP

		LDA	#$18
		STA	$D640
		NOP

		LDA	#$00
		STA	flgBigglesErr
		STA	sizBigglesBuf
		STA	sizBigglesBuf + 1

		CLC

		RTS

@fail:
		LDA	#$01
		STA	flgBigglesErr

		SEC
		RTS

;-----------------------------------------------------------
_bigglesReadByte:
;-----------------------------------------------------------
		LDA	flgBigglesErr
		BEQ	@begin

		SEC
		RTS

@begin:
		LDA	sizBigglesBuf
		ORA	sizBigglesBuf + 1

		BNE	@cont0

		JSR	_bigglesReadSect

		LDA	sizBigglesBuf
		ORA	sizBigglesBuf + 1

		BNE	@cont0

		LDA	#$01
		STA	flgBigglesErr

		SEC
		RTS

@cont0:
		LDY	#$00
		LDA	(ptrBigglesBufOff), Y

		PHA

		CLC
		LDA	ptrBigglesBufOff
		ADC	#$01
		STA	ptrBigglesBufOff
		LDA	ptrBigglesBufOff + 1
		ADC	#$00
		STA	ptrBigglesBufOff + 1

		SEC
		LDA	sizBigglesBuf
		SBC	#$01
		STA	sizBigglesBuf
		LDA	sizBigglesBuf + 1
		SBC	#$00
		STA	sizBigglesBuf + 1

		PLA

		CLC
		RTS


;-----------------------------------------------------------
_bigglesReadSect:
;-----------------------------------------------------------
		LDA	#$00
		STA	ptrBigglesBufOff

		LDA	ptrBigglesBufHi
		STA	ptrBigglesBufOff +1
		STA	adrBigglesDest + 1

		LDA	#$1A
		STA	$D640
		NOP

;@halt:
;		INC	$D020
;		JMP	@halt


		STX	sizBigglesBuf
		STY	sizBigglesBuf + 1

		LDA	sizBigglesBuf
		ORA	sizBigglesBuf + 1

		BEQ	@exit


		LDA	#$80
		TSB	$D689

		LDA	#$00
		STA	$D702
		STA	$D704
		LDA	#>lstBigglesDMA
		STA	$D701
		LDA	#<lstBigglesDMA
		STA	$D705

@exit:
		RTS


;-----------------------------------------------------------
_bigglesSetFN:
;-----------------------------------------------------------
		STX	adrBigglesFN
		STY	adrBigglesFN + 1

		LDA	#$2E				; dos_setname Hypervisor trap
		STA	$D640				; Do hypervisor trap
		NOP
		BCS	@ok

		LDA	#$01
		STA	flgBigglesErr

		SEC
		RTS

@ok:
		LDA	#$00
		STA	flgBigglesErr

		CLC
		RTS


;-----------------------------------------------------------
_bigglesCloseAll:
;-----------------------------------------------------------
		LDA	#$22
		STA	$D640
		NOP

		LDA	#$00
		STA	flgBigglesErr

		RTS