java -jar ..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\screen1.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

"C:\Program Files\xemu\xmega65.exe" -prg .\screen1.prg