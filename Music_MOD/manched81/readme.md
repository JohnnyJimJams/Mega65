
# Manche 0.14A Beta
Copyright 2021, Daniel England.  All Rights Reserved.

## Introduction
Welcome to the Manche readme!  

Manche is a front-end for the Peppito MOD player and allows you to play (or "replay" in the original parlance) MOD files on your MEGA65.

Manche and Peppito have advanced in functionaliy and now support most of the intended features.

Please read the other sections for updated information!


## License
Manche and Peppito are released under the terms of the LGPL.

## Requirements
Manche and Peppito rely on a very recent (03JAN2021 or later) bitstream in order to play properly.

Manche currently supports NTSC playback adjustments and provides alternate mixing controls for the Nexys based machines. 


## Display
At the very top is shown the current tick values for Manche and Peppito (including row and sequence counters).

At the very bottom, the current mixer levels are shown.  The levels shown are dependent upon the board type.  For Nexys boards, the levels are Master, Right and Left.  For other boards, the levels are Master, Digi Left/Right and Stereo Mix.

The middle area is blank until you load a MOD.  This area is divided into two main columns, with the instrument information on the right and MOD and playback information on the left.

## Controls
To load a MOD file, press F1 and enter the name of the file to load.  Press Return to accept the file name and load the MOD file.  MOD files will be loaded either from the SD Card or floppy disk depending upon the version of Manche you are using.

For the SD Card version of Manche, you can now change the directory that the MOD files are loaded from.  Press F2 to change directories. Enter the directory name to enter or ".." to navigate to the previous directory.

To play or stop the loaded MOD file, press Space.

To browse the instruments in the MOD file, use F7 and F8.

To control the master volume, use F9 and F10.

To control the volume of the standard left/right outputs (or just right on the Nexys) use F11/F12.

To control the mix level of the alternate left/rights outputs for changing the "stereo width" (or just the left channel level on the Nexys) use F13/F14. 

Manche for the SDC (as opposed to the FDC/D81 version) now supports jukebox mode!  Instead of simply loading a file, you can press F3 to load a directory listing of MOD files from your SD card and play them in the order given there.  Alternatively, you can press F4 to start jukebox shuffle mode where the order of files is randomised.

In jukebox mode, you may press F5 to skip to the next track.


## Limitations
The MOD files must be no larger than 320kB (327,680 bytes).  Increased now from the previous versions and will perhaps be the limit for now.

The MOD files must be the original M.K. or M!K! types.

The MOD files must not have instruments with sample lengths greater than 65535 bytes long.

The MOD files must be 31 instrument types.  Support for 15 instrument types is being investigated.

## Peppito's Performance
Peppito supports the following effects:
  - Pattern Break
  - Set Volume
  - Set Speed
  - Volume Slide
  - Portamento Up
  - Portamento Down
  - Fine Portamento Up
  - Fine Portamento Down
  - Fine Volume Up
  - Fine Volume Down
  - Vibrato
  - Vibrato + Volume Slide
  - Tone Portamento
  - Tone Portamento + Volume Slide
  - Retrigger
  - Note Delay
  - Pattern Jump
  - Pattern Loop
  - Note Cut

Fine Tune of instruments is fully supported.

Only the fine speed adjustment is supported, not coarse "Tempo" adjustments.  It is unlikely that this will be supported until after other more important enhancements have been made since it requires very specific playback handling.

## Future Development
It is vital that more testing be done on Manche and Peppito.

If you can find MODs that don't play well but you think they should, I would love to hear from you.  Also, if you specifically know that certain effect types are being used and not supported in the MODs you like to play, please contact me.

## Contact
For further information or to discuss issues with Manche, please contact me at the following address:

	mewpokemon {you know} hotmail {and here} com

Please include the title "Manche" in the subject line or your e-mail might get lost.