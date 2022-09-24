java -jar ..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\linedraw.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

REM ..\Tools\exomizer.exe sfx basic -t 65 linedraw.prg -o linedraw_x.prg

@if %errorlevel% neq 0 exit /b %errorlevel%

..\Tools\m65.exe -l COM5 -r -F .\linedraw.prg

@REM "C:\Program Files\xemu\xmega65.exe" -prg .\linedraw.prg

@REM ..\Tools\m65dbg.exe -l \\.\COM5