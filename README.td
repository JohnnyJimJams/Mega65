==============================================
 Some general notes on Mega65 ASM programming
==============================================


Machine Specific Info
=====================

* Chip starts at 40Mhz by default at startup

* VIC IV registers enabled by default at startup

* Address Space of Mega65 000 0000 - FFF FFFF
    Mega65 has 384k Chip RAM installed so available mem is
        00000 - 5FFFF (BANKS 0-5)

* Additional 8MB of RAM starting at $8000000, referred to as ’ATTIC RAM’. DMA can access this

* Palette -> 256 colours looked up from RGB values at $d100, $d200 and $d300 (R,G and B are 4 bits wide so 0-15 on Xemu, but manual says 8 bits wide on hardware.)

* Default memory map has:
         - Text screen ram $0800-$1000
         - Default chars at $1000-$1800
         - BASIC Program starting at $2000


Kick Assembler Specific Info
============================

* Using a fancy version of KickAssembler(http://theweb.dk/KickAssembler/Main.html#frontpage) that allows 65CE02 code - https://gitlab.com/camelot/kickc/-/blob/master/repo/cml/kickass/kickassembler/5.24-65ce02.e/kickassembler-5.24-65ce02.e.jar

* Awesome Macro library to make life easier from https://github.com/smnjameson/M65_KickAsm_Macros/blob/master/m65macros.s

* Emulator -> https://github.lgb.hu/xemu/


Building the examples
=====================

Kick Assembler folder next to this Mega65 folder and the emulator in it's default install location at "C:\Program Files\xemu\xmega65.exe"

See the make.bat files for how to build the examples and how to run them in the emulator