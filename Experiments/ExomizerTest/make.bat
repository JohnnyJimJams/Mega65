java -jar ..\..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\extest.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

REM ..\..\Tools\exomizer.exe sfx basic -t 65 extest.prg -o extest_x.prg

@if %errorlevel% neq 0 exit /b %errorlevel%

..\..\Tools\m65.exe -l COM5 -r -F .\extest.prg

@REM "C:\Program Files\xemu\xmega65.exe" -prg .\extest.prg