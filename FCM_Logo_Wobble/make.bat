java -jar ..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\fcmwobble.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

REM ..\Tools\exomizer.exe sfx basic -t 65 fcmwobble.prg -o fcmwobble_x.prg

@if %errorlevel% neq 0 exit /b %errorlevel%

..\Tools\m65.exe -l COM5 -r -F .\fcmwobble.prg

@REM "C:\Program Files\xemu\xmega65.exe" -prg .\fcmwobble.prg