java -jar ..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\raster5.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

"C:\Program Files\xemu\xmega65.exe" -prg .\raster5.prg