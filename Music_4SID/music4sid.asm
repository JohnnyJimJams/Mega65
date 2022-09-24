.cpu _45gs02

//--------------------------------------------------------------

.var SID1 = LoadSid("cadence-4-sid.sid")
.var SID2 = LoadSid("cadence-4-sid-2.sid")
//.var SID1 = LoadSid("Music\test.sid")
//.var SID2 = LoadSid("Music\test-2.sid")

// -------------------------------------------------------------

*= $2001 "UpStart"
BasicUpstart65(Start)

#import "..\includes\m65macros.asm"

*= $2016 "Program" // Note: Needed to add 1 byte here, because the imported library has one byte storage allocated
Start:
    sei
    lda #$35
    sta $01
    enable40Mhz()
    enableVIC4Registers()
    disableCIAandIRQ()
    disableC65ROM()

//                    lda $d031
  //                  and #%10111111
    //                sta $d031
      //              lda $d054
        //            and #%10111111
          //          sta $d054
            //        lda #$40
              //      sta $00
					// Clear screen

					ldx #0
ClrScr:				lda #$20
					sta $0800,x
					sta $0900,x
					sta $0a00,x
					sta $0b00,x
					sta $0c00,x
					sta $0d00,x
					sta $0e00,x
					sta $0f00,x
					lda #1
					sta $d800,x
					sta $d900,x
					sta $da00,x
					sta $db00,x
					inx
					bne ClrScr

					ldx #0
WriteText:			lda textline1,x
					sta $0800+(0*80),x
					lda textline2,x
					sta $0800+(2*80),x
					lda textline3,x
					sta $0800+(4*80),x
					inx
					cpx #$50
					bne WriteText

					// Link .SID files together so they can share global tempo changes

					lda #$ff  // Get .SID Tempo Info
					jsr SID1.init // Returns x = TempLo Addr, y = Tempo Hi Addr
					lda #$fe  // link .SID file > .SID2 file
					jsr SID2.init

					lda #$ff  // Repeat for SID2 (so any global temp changes made on Song1 will be sent to Song0
					jsr SID2.init
					lda #$fe
					jsr SID1.init // link .SID2 file > .SID file

					lda #0
					jsr SID1.init // init song0 (SIDS 1+2)
					lda #1
					jsr SID2.init // init song1 (SIDs 3+4

                    lda #$7f
                    sta $dc0d
                    sta $dd0d
                    lda #0
                    sta $d01a
                    lda #1
                    sta $d019
                    sta $d01a
                    lda #64
                    sta $d012
                    lda #<irq1
                    sta $fffe 
                    lda #>irq1
                    sta $ffff
					cli

					lda $d63c
					and #1
                    beq SID6581
                    jmp SID8580
                    
loop:				lda $d610
					cmp #$20
					beq switch
					sta $d610
					jmp loop
switch:				sta $d610

					// Switch personality of all 4 SID's
					lda $d63c
					eor #$0f
					sta $d63c
					inc scrcol+1 // ack spacebar
					lda $d63c
					and #1
                    beq SID6581
SID8580:            ldx #3
!:                  lda s8580text,x
                    sta $0800+(5*80)-4,x
                    dex
                    bpl !-
                    jmp loop
SID6581:            ldx #3
!:                  lda s6581text,x
                    sta $0800+(5*80)-4,x
                    dex
                    bpl !-
                    jmp loop

s6581text:			.text "6581"
s8580text:			.text "8580"

textline1:			.text "v2        1st ever attempt at fully utilizing the 4 sid's of the mega65!        "
textline2:			.text "code by jason page - music by shogoon ... and a few mega65 lines of code by trap"
textline3:			.text "hit space to switch sid personality                                     sid:    "

// ---------------------------------------------------------------------

irq1:		 	    BeginIRQ()
scrcol:             lda #0
                    sta $d020
                    lda #0
                    sta $d021
                    inc $d020
                    jsr SID1.play
                    dec $d020
                    NextIRQ(irq2,192)

irq2:		 	    BeginIRQ()
                    inc $d020
                    jsr SID2.play
                    dec $d020
                    NextIRQ(irq1,64)

// ---------------------------------------------------------------------

                    .pc = SID1.location "SID 1"
                    .fill SID1.size, SID1.getData(i)

                    .pc = SID2.location "SID 2"
                    .fill SID2.size, SID2.getData(i)

//--------------------------------------------------------------
