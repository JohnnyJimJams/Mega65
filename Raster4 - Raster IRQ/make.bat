java -jar ..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\raster4.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

"C:\Program Files\xemu\xmega65.exe" -prg .\raster4.prg