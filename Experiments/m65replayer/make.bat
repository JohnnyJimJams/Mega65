java -jar ..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\m65replayer.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

..\Tools\m65.exe -l COM5 -r -F .\m65replayer.prg

"C:\Program Files\xemu\xmega65.exe" -prg .\m65replayer.prg