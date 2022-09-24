java -jar ..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\music4sid.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

REM ..\Tools\exomizer.exe sfx basic -t 65 music4sid.prg -o music4sid_x.prg

@if %errorlevel% neq 0 exit /b %errorlevel%

..\Tools\m65.exe -l COM5 -r -F .\music4sid.prg

@REM "C:\Program Files\xemu\xmega65.exe" -prg .\music4sid.prg