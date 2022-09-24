java -jar ..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\vertrast.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

"C:\Program Files\xemu\xmega65.exe" -prg .\vertrast.prg