#define include_stub
#if include_stub 
{
	* = $2001
	
	.byte $16,$20			//End of command marker (first byte after the 00 terminator)
	.byte $0a,$00			//10
	.byte $fe,$02,$30,$3a	//BANK 0:
	.byte $9e				//SYS
	.text "$202C"
	.byte $3a, $8f			//:REM
	.fill 21, $14
	.text "BAS"
	.byte $00
	.byte $00,$00			//End of basic terminators
	
stub:
	sei
	
	lda #65
	sta $00
	
	lda #$00
	sta $d030
	
	//lda #$00
	tax
	tay
	taz
	map
	eom

	lda #%00110111
	sta $00
	lda #%00110110
	sta $01
	
	lda #%10000000
	trb $d06f
	
	lda #%01111111
	sta $dc0d
	sta $dd0d
	
	lda $dc0d
	lda $dd0d
	
	jsr interface
	
	lda #$00
	sta $d020
	sta $d021
here:
	lda #$40
	ldx #$01
loop:
	cmp $d012
	bne !loop
	stx $d020
	stx $d021
	jsr interface+3
	ldx #$00
	stx $d020
	stx $d021
	
	lda #$40
loop2:
	cmp $d012
	beq loop
	
	bra here
}

	* = $3000
	
.const zp	= $02
.const zp2	= $04
.const sidzp	= $06

interface:
	jmp init
	jmp play
	
.scr "- ", title
.scr " by ", author, " -"

init:
#if ghost_registers 
{
	lda zp
	sta ghost
	lda zp+1
	sta ghost+1
}

	ldx #$0f
	stx $d418
	stx $d438
	stx $d458
	stx $d478

.ifndef ghost_registers {
	lda #$d4
	sta sidzp+1
}

	// reset the song position and
	// set the pointers to the current 
	// patterns' starts
	// 
	// this pointer doubles as the 
	// cursor as well, the pointer is
	// where the updated index is stored
	// also.
	ldz #$00
-	lda list_ptrs_lo, x
	sta zp
	lda list_ptrs_hi, x
	sta zp+1
	
	lda (zp), z
	tay
	lda pattern_lookup_lo, y
	sta current_patterns_lo, x
	lda pattern_lookup_hi, y
	sta current_patterns_hi, x
	
	// set SIDs to 6581
	// The 8580 is the preferred sound chip, but at this time, it is not working
	// properly on real hardware.  If you are still seeing this after the fix is
	// in, you can change the value to $0f to switch to 8580s and remind me to
	// fix it in the exporter.
	lda #$00
	tsb $d63c
	
	lda #$01
	sta pattern_delays, x
	//sta hard_restarting, x
	
	lsr
	
	sta pattern_indices, x
	sta current_note, x
	
	dex
	lbpl -
	
#if ghost_registers 
{
	lda ghost
	sta zp
	lda ghost+1
	sta zp+1
}

	rts
	
play:

#if ghost_registers 
{
	lda zp
	sta ghost
	lda zp+1
	sta ghost+1
	lda zp2
	sta ghost+2
	lda zp2+1
	sta ghost+3
	lda sidzp
	sta ghost+4
	lda sidzp+1
	sta ghost+5
	
	lda #$d4
	sta sidzp+1
}

	ldx #$0f

pattern_loop:
	dec pattern_delays, x
	beq +
	
	dex
	bpl pattern_loop
	
	jmp update
	
+	
	lda current_patterns_lo, x
	sta zp
	lda current_patterns_hi, x
	sta zp+1
	lda sid_lookup, x
	sta sidzp

cmd_byte:
	// read command byte
	ldz #$00
	lda (zp), z
	sta current_command
#if command_word 
{
	sta current_command_word
}
	inz

#if command_word 
{
	lda (zp), z
	sta current_command_word+1
	inz
	lda current_command
}
	cmp #$ff
	bne ++
	
next_pat:
	// next pattern
	lda list_ptrs_lo, x
	sta zp2
	lda list_ptrs_hi, x
	sta zp2+1

	ldy pattern_indices, x
	iny
	lda (zp2), y
	cmp #$ff
	bne +

#if looping 
{
	iny
	lda (zp2), y
	sec
	sbc #$01
	sta pattern_indices, x
	bra next_pat
}

.ifndef looping 
{	
	lda #$ff
	sta pattern_delays, x
	dex
	bpl pattern_loop
	
	jmp update
}
	
+	inc pattern_indices, x
	tay
	lda pattern_lookup_lo, y
	sta current_patterns_lo, x
	sta zp
	lda pattern_lookup_hi, y
	sta current_patterns_hi, x
	sta zp+1
	
	bra cmd_byte

++
#if uses_res_routing 
{
res_routing:
	// voice filter toggle
	bit cmd_resonance_routing
	beq +

	lda (zp), z
	ldy #$17
	sta (sidzp), y
	
	inz
	lda current_command
+
}
#if uses_cutoff 
{
cutoff:
	// cutoff
	bit cmd_cutoff
	beq +
	
	lda (zp), z
	ldy #$16
	sta (sidzp), y
	
	inz
	lda current_command
+
}
#if uses_fmode_volume 
{
fmode_volume:
	// filter type
	bit cmd_fmode_volume
	beq +
	
	lda (zp), z
	ldy #$18
	sta (sidzp), y
	
	inz
	lda current_command
+
}
program:
	// program change
	bit cmd_programchange
	beq +

	// lookup the new instrument
	lda (zp), z
	tay
	
	lda program_ad, y
	sta current_ad, x
	lda program_sr, y
	sta current_sr, x

#if uses_finetune 
{
	lda program_finetune_lo, y
	sta current_finetune_lo, x
	lda program_finetune_hi, y
	sta current_finetune_hi, x
}
	
	lda wt_lookup_lo, y
	sta wt_ptr_lo, x
	lda wt_lookup_hi, y
	sta wt_ptr_hi, x
	
	lda nt_lookup_lo, y
	sta nt_ptr_lo, x
	lda nt_lookup_hi, y
	sta nt_ptr_hi, x
	
	lda pt_lookup_lo, y
	sta pt_ptr_lo, x
	lda pt_lookup_hi, y
	sta pt_ptr_hi, x
	
	lda vt_lookup_lo, y
	sta vt_ptr_lo, x
	lda vt_lookup_hi, y
	sta vt_ptr_hi, x
	lda program_vibrato_delay, y
	sta vt_start_delay, x
	
#if uses_pulsewidth 
{
	lda program_default_pw_lo, y
	sta current_pw_lo, x
	lda program_default_pw_hi, y
	sta current_pw_hi, x
}
	
	lda #$01
	sta ad_changed, x
	sta sr_changed, x
	
#if uses_pitchbend 
{
	lsr
	
	sta current_pb_lo, x
	sta current_pb_hi, x
}
	
	inz
	lda current_command
	
+
note_on:
	// note on
	bit cmd_noteon
	beq +++
	
	// load the arp length
+	lda (zp), z
	bne +
	
	// zero length - release note
	inz
	lda #$00
	sta sustaining, x
	beq ++

+
	lda sustaining, x
	bne +
	
	lda #$01
	sta vt_indices, x
	
	lsr
	
	sta hard_restarting, x
	sta nt_indices, x
	sta pt_indices, x
	sta wt_indices, x
	
	lda vt_start_delay, x
	sta vt_current_delay, x

+
	// point to the arp
	tza
	clc
	adc zp
	sta arp_ptr_lo, x
	lda #$00
	adc zp+1
	sta arp_ptr_hi, x
	
	tza
	clc
	adc (zp), z
	taz
	inz
	
	lda #$01
	sta sustaining, x

++
	lda current_command
+++

hardrestart:
	bit cmd_hardrestart
	beq +
	
	ldy #$06
	lda #$00
-	sta (sidzp), y
	dey
	cpy #$04
	bpl -
	
	lda #$01
	sta hard_restarting, x
	sta ad_changed, x
	sta sr_changed, x
	
	lda current_command
+

#if uses_pitchbend 
{
pitchbend:
	bit cmd_pitchbend
	beq +
	
	lda (zp), z
	sta current_pb_lo, x
	inz
	lda (zp), z
	sta current_pb_hi, x
	inz
	
.if changeover .= "pulsewidth" 
{
	lda current_command
}
	
+
}

.if changeover = "pulsewidth" 
{
	lda current_command_word+1
	sta current_command
}

#if uses_pulsewidth 
{
	bit cmd_pulsewidth
	beq +
	
	lda (zp), z
	sta current_pw_lo, x
	inz
	lda (zp), z
	sta current_pw_hi, x
	inz

.if changeover .= "attackdecay" 
{	
	lda current_command
}

+
}

.if changeover = "attackdecay" 
{
	lda current_command_word+1
	sta current_command
}

#if uses_attackdecay 
{
	bit cmd_attackdecay
	beq +
	
	lda (zp), z
	inz
	sta current_ad, x
	
	lda #$01
	sta ad_changed, x
	
.if changeover .= "sustainrelease" 
{	
	lda current_command
}
+
}

.if changeover = "sustainrelease" 
{
	lda current_command_word+1
	sta current_command
}

#if uses_sustainrelease 
{
	bit cmd_sustainrelease
	beq +
	
	lda (zp), z
	inz
	sta current_sr, x
	
	lda #$01
	sta sr_changed, x
	
.if changeover .= "vibratotable" 
{	
	lda current_command
}
+
}

.if changeover = "vibratotable" 
{
	lda current_command_word+1
	sta current_command
}

#if uses_vibratotable 
{
vibrato_table:
	bit cmd_vibratotable
	beq +
	
	tza
	clc
	adc zp
	sta vt_ptr_lo, x
	lda #$00
	adc zp+1
	sta vt_ptr_hi, x

	tza
	clc
	adc (zp), y
	taz
	inz
	
.if changeover .= "vibratodelay" 
{	
	lda current_command
}
+
}

.if changeover = "vibratodelay" 
{
	lda current_command_word+1
	sta current_command
}

#if uses_vibratodelay 
{
	bit cmd_vibratodelay
	beq +
	
	lda (zp), z
	sta vt_start_delay, x
	inz
	
.ifndef command_word 
{
	lda current_command
}
+
}
#if command_word 
{
	lda current_command_word
}

delay:
	// delay
	// delay needs to execute last as 
	// it is the last byte in the row
	// of data
	bit cmd_delay
	beq +
	
	lda (zp), z
	inz
	bne ++
	
+	// There will ALWAYS be a delay of
	// 1, so if the bit is not set, then
	// it is assumed to be 1, since
	// frequently updated data needs to
	// be smaller.
	lda #$01

++	sta pattern_delays, x

	// update the pattern pointer for 
	// this column
	tza
	
	clc
	adc current_patterns_lo, x
	sta current_patterns_lo, x
	lda #$00
	adc current_patterns_hi, x
	sta current_patterns_hi, x
	
	dex
	lbpl pattern_loop
	
update:
	ldx #$0f
update_loop:
	lda skip_update, x
	bne +
	
	lda hard_restarting, x
	beq ++

+
	dex
	bne update_loop
	rts
	
++
	lda sid_lookup, x
	sta sidzp
	
note_table:
	lda nt_ptr_lo, x
	sta zp2
	lda nt_ptr_hi, x
	sta zp2+1
	
	ldy nt_indices, x
-
	lda (zp2), y
	
	// command
	bit bit_20
	beq absolute
	
.if nt_uses_susto 
{
nt_susto:	
	// sustain to
	cmp #$23
	bne ++
	
	iny
	
	lda sustaining, x
	beq +
	// sustaining, loop back
	lda (zp2), y
	tay
	lda mul_3, y
	sta nt_indices, x
	tay
	bra -
	
+
	// not sustaining, fall through
	iny
	iny
	tya
	sta nt_indices, x
	bra -
++
}

.if nt_uses_goto 
{
goto:
	// goto
	cmp #$22
	bne +
	
	iny
	lda (zp2), y
	tay
	lda mul_3, y
	tay
	sta nt_indices, x
	bra -

+	
}

#if nt_uses_end 
{
nt_end:
	// end
	dey
	dey
	dey
	tya
	sta nt_indices, x
	bra -
}

absolute:
	// absolute
	cmp #$01
	bne +
	
	iny
	lda (zp2), y

#if uses_finetune 
{
	clc
	adc current_finetune_lo, x
}

	pha
	
	iny
	lda (zp2), y
	
#if uses_finetune 
{
	adc current_finetune_hi, x
}
	
	pha
	
	iny
	tya
	sta nt_indices, x
	
	ldy #$01
	pla
	sta (sidzp), y
	dey
	pla
	sta (sidzp), y
	jmp pulse_table
	
+
nt_reltv:
	// relative
	iny
	lda (zp2), y
	sta current_note, x
	tya
	adc #$02
	sta nt_indices, x

arp_table:
	// update arp table
	lda arp_ptr_hi, x
	lbeq pulse_table
	sta zp2+1
	lda arp_ptr_lo, x
	sta zp2
	
	ldy #$00
	lda (zp2), y

	cmp arp_indices, x
	bmi +
	bne ++
	
+	lda #$00
	sta arp_indices, x

++	inc arp_indices, x
	ldy arp_indices, x
	
	lda (zp2), y
	clc
	adc current_note, x
	tay
	
	lda freq_lo, y
	sta tword
	lda freq_hi, y
	sta tword+1

vibratotable:
	// update vibrato
	lda vt_current_delay, x
	bne +++
	
	lda vt_ptr_hi, x
	beq ++++
	sta zp+1
	lda vt_ptr_lo, x
	sta zp
	
	ldy #$00
	lda (zp), y
	beq ++++
	
	cmp vt_indices, x
	bmi +
	bne ++
	
+	lda #$01
	sta vt_indices, x
	
++	ldy vt_indices, x
	
	lda (zp), y
	clc
	adc tword
	sta tword
	iny
	lda (zp), y
	adc tword+1
	sta tword+1
	iny
	
	tya
	sta vt_indices, x
	bra ++++
	
+++	dec vt_current_delay, x

++++

#if uses_finetune 
{
	clc
	lda current_finetune_lo, x
	adc tword
	sta tword
	lda current_finetune_hi, x
	adc tword+1
	sta tword+1
}

#if uses_pitchbend 
{
	clc
	lda current_pb_lo, x
	adc tword
	sta tword
	lda current_pb_hi, x
	adc tword+1
	sta tword+1
}

	ldy #$00
	lda tword
	sta (sidzp), y
	iny
	lda tword+1
	sta (sidzp), y
	
pulse_table:
	// pulse table
	lda pt_ptr_lo, x
	sta zp2
	lda pt_ptr_hi, x
	sta zp2+1
	
	ldy pt_indices, x
-
	lda (zp2), y
	
	// command
	bit bit_20
	beq pulse_value

#if pt_uses_susto 
{	
pt_susto:
	// sustain to
	cmp #$23
	bne ++
	
	iny
	
	lda sustaining, x
	beq +
	// sustaining, loop back
	lda (zp2), y
	asl
	sta pt_indices, x
	tay
	bra -
	
+
	// not sustaining, fall through
	iny
	tya
	sta pt_indices, x
	bra -
++	
}

#if pt_uses_goto 
{
pulse_goto:
	// goto
	cmp #$22
	bne +
	
	iny
	lda (zp2), y
	asl
	sta pt_indices, x
	tay
	bra -

+	
}

#if pt_uses_end 
{
pt_end:
	// end
	dey
	dey
	tya
	sta pt_indices, x
	bra -
}

pulse_value:
	pha
	iny
	lda (zp2), y
	pha
	
	iny
	tya
	sta pt_indices, x
	
	ldy #$02
	pla
#if uses_pulsewidth 
{
	clc
	adc current_pw_lo, x
}
	sta (sidzp), y
	iny
	pla
#if uses_pulsewidth 
{
	adc current_pw_hi, x
}
	sta (sidzp), y
	
wavetable:
	// wavetable
	lda wt_ptr_lo, x
	sta zp2
	lda wt_ptr_hi, x
	sta zp2+1
	
	ldy wt_indices, x
-
	lda (zp2), y
	
	// command
	beq wave_value

#if wt_uses_susto 
{	
wt_susto:
	// sustain to
	cmp #$23
	bne ++
	
	iny
	
	lda sustaining, x
	beq +
	// sustaining, loop back
	lda (zp2), y
	asl
	sta wt_indices, x
	tay
	bra -
	
+
	// not sustaining, fall through
	iny
	tya
	sta wt_indices, x
	bra -
++	
}

#if wt_uses_goto 
{
wave_goto:
	// goto
	cmp #$22
	bne +
	
	iny
	lda (zp2), y
	asl
	sta wt_indices, x
	tay
	bra -

+	
}

#if wt_uses_end 
{
wt_end:
	// end
	dey
	dey
	tya
	sta wt_indices, x
	bra -
}

wave_value:
	iny
	lda (zp2), y
	ldz sustaining, x
	bne +
	and #$fe

+
	taz
	iny
	tya
	sta wt_indices, x
	
	ldy #$06
	lda sr_changed, x
	beq +
	lda current_sr, x
	sta (sidzp), y
	lda #$00
	sta sr_changed, x
+
	dey
	lda ad_changed, x
	beq +
	lda current_ad, x
	sta (sidzp), y
	lda #$00
	sta ad_changed, x
	
+
	dey
	tza
	sta (sidzp), y
	
	dex
	lbne update_loop
	
+

#if ghost_registers 
{
	lda ghost
	sta zp
	lda ghost+1
	sta zp+1
	lda ghost+2
	sta zp2
	lda ghost+3
	sta zp2+1
	lda ghost+4
	sta sidzp
	lda ghost+5
	sta sidzp+1
}

	rts
	
sid_lookup:
	.byte $00, $00, $07, $0e, $20, $20, $27, $2e
	.byte $40, $40, $47, $4e, $60, $60, $67, $6e
	
skip_update:
	.byte $01, $00, $00, $00
	.byte $01, $00, $00, $00
	.byte $01, $00, $00, $00
	.byte $01, $00, $00, $00

bit_01:
	.byte %00000001
bit_02:
	.byte %00000010
bit_04:
	.byte %00000100
bit_08:
	.byte %00001000
bit_10:
	.byte %00010000
bit_20:
	.byte %00100000
bit_40:
	.byte %01000000
bit_80:
	.byte %10000000
	
freq_lo:
	.byte $93, $9C, $A6, $AF, $BA, $C5, $D1, $DD, $EA, $F8, $07
	.byte $09, $19, $2A, $3B, $4E, $62, $77, $8D
	.byte $A5, $BE, $D9, $F5, $12, $32, $53, $77 
	.byte $9C, $C4, $EE, $1B, $4A, $7C, $B1, $E9 
	.byte $25, $64, $A7, $ED, $38, $88, $DC, $35 
	.byte $94, $F8, $62, $D2, $4A, $C8, $4D, $DB 
	.byte $71, $10, $B8, $6B, $28, $F0, $C4, $A5 
	.byte $93, $8F, $9B, $B6, $E2, $20, $71, $D5 
	.byte $4F, $E0, $88, $4A, $26, $1F, $35, $6C 
	.byte $C4, $40, $E1, $AB, $9F, $C0, $10, $94 
	.byte $4C, $3D, $6B, $D7, $88, $7F, $C2, $55 
	.byte $3E, $80, $21, $27, $98, $7B, $D5, $AF 
	.byte $0F, $FE, $84, $AB, $7B, $FF, $42, $4E

freq_hi:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte $01, $01, $01, $01, $01, $01, $01, $01 
	.byte $01, $01, $01, $01, $02, $02, $02, $02 
	.byte $02, $02, $02, $03, $03, $03, $03, $03 
	.byte $04, $04, $04, $04, $05, $05, $05, $06 
	.byte $06, $06, $07, $07, $08, $08, $09, $09 
	.byte $0A, $0B, $0B, $0C, $0D, $0D, $0E, $0F 
	.byte $10, $11, $12, $13, $14, $16, $17, $18 
	.byte $1A, $1B, $1D, $1F, $21, $23, $25, $27 
	.byte $29, $2C, $2E, $31, $34, $37, $3B, $3E 
	.byte $42, $46, $4A, $4E, $53, $58, $5D, $63 
	.byte $69, $6F, $76, $7D, $84, $8C, $94, $9D 
	.byte $A7, $B0, $BB, $C6, $D2, $DE, $EC, $FA

.if nt_uses_susto | nt_uses_goto {
mul_3:
	.byte $01, $03, $06, $09, $0c, $0f, $12, $15
	.byte $18, $1B, $1E, $21, $24, $27, $2A, $2D
	.byte $34, $33, $36, $39, $3c, $3f, $45, $45
	.byte $48, $4B, $4E, $54, $54, $57, $5A, $5D
	.byte $67, $63, $66, $69, $6c, $6f, $78, $75
	.byte $78, $7B, $7E, $87, $84, $87, $8A, $8D
	.byte $9A, $93, $96, $99, $9c, $9f, $AB, $A5
	.byte $A8, $AB, $AE, $BA, $B4, $B7, $BA, $BD
	.byte $CD, $C3, $C6, $C9, $Cc, $Cf, $DE, $D5
	.byte $D8, $DB, $DE, $ED, $E4, $E7, $EA, $ED
	.byte $F1, $F3, $F6, $F9, $Fc, $Ff
}

pattern_indices:
	.fill $10
	
pattern_delays:
	.fill $10

current_patterns_lo:
	.fill $10
current_patterns_hi:
	.fill $10
	
current_command:
	.byte $00
#if command_word 
{
current_command_word:
	.word $00
}

current_note:
	.fill $10
sustaining:
	.fill $10

hard_restarting:
	.fill $10
current_ad:
	.fill $10
ad_changed:
	.fill $10
current_sr:
	.fill $10
sr_changed:
	.fill $10

#if uses_finetune 
{
current_finetune_lo:
	.fill $10
current_finetune_hi:
	.fill $10
}

#if uses_pulsewidth 
{	
current_pw_lo:
	.fill $10
current_pw_hi:
	.fill $10
}

#if uses_pitchbend 
{
current_pb_lo:
	.fill $10
current_pb_hi:
	.fill $10
}

arp_indices:
	.fill $10

arp_ptr_lo:
	.fill $10
arp_ptr_hi:
	.fill $10

wt_indices:
	.fill $10
wt_ptr_lo:
	.fill $10
wt_ptr_hi:
	.fill $10
	
nt_indices:
	.fill $10
nt_ptr_lo:
	.fill $10
nt_ptr_hi:
	.fill $10
pt_indices:
	.fill $10
pt_ptr_lo:
	.fill $10
pt_ptr_hi:
	.fill $10
vt_start_delay:
	.fill $10
vt_current_delay:
	.fill $10
vt_indices:
	.fill $10
vt_ptr_lo:
	.fill $10
vt_ptr_hi:
	.fill $10

temp:
	.byte $00
tword:
	.word $0000

#if ghost_registers 
{
ghost:
	.fill $06
}

list_ptrs_lo:
	.byte <s0_global_pattern_list,   <s0_voice_00_pattern_list 
	.byte <s0_voice_01_pattern_list, <s0_voice_02_pattern_list
	.byte <s1_global_pattern_list,   <s1_voice_00_pattern_list 
	.byte <s1_voice_01_pattern_list, <s1_voice_02_pattern_list
	.byte <s2_global_pattern_list,   <s2_voice_00_pattern_list 
	.byte <s2_voice_01_pattern_list, <s2_voice_02_pattern_list
	.byte <s3_global_pattern_list,   <s3_voice_00_pattern_list 
	.byte <s3_voice_01_pattern_list, <s3_voice_02_pattern_list
list_ptrs_hi:
	.byte >s0_global_pattern_list,   >s0_voice_00_pattern_list 
	.byte >s0_voice_01_pattern_list, >s0_voice_02_pattern_list
	.byte >s1_global_pattern_list,   >s1_voice_00_pattern_list 
	.byte >s1_voice_01_pattern_list, >s1_voice_02_pattern_list
	.byte >s2_global_pattern_list,   >s2_voice_00_pattern_list 
	.byte >s2_voice_01_pattern_list, >s2_voice_02_pattern_list
	.byte >s3_global_pattern_list,   >s3_voice_00_pattern_list 
	.byte >s3_voice_01_pattern_list, >s3_voice_02_pattern_list
