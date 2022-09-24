java -jar ..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\screen_col.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

..\Tools\m65.exe -l COM5 -r -F .\screen_col.prg

"C:\Program Files\xemu\xmega65.exe" -prg .\screen_col.prg