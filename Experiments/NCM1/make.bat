
python ..\..\Tools\tilemizer.py -m=4000 -b4 -o=data\layer0 -t=data\layer0.png
python ..\..\Tools\tilemizer.py -m=6e40 -b4 -o=data\layer1 -t=data\layer1.png

@if %errorlevel% neq 0 exit /b %errorlevel%

java -jar ..\..\..\KickAss\kickassembler-5.24-65ce02.e.jar .\NCM1.asm

@if %errorlevel% neq 0 exit /b %errorlevel%

@REM ..\..\Tools\exomizer.exe sfx basic -t 65 NCM1.prg -o NCM1_x.prg

@if %errorlevel% neq 0 exit /b %errorlevel%

..\..\Tools\m65.exe -l COM5 -r -F .\NCM1.prg

@REM "C:\Program Files\xemu\xmega65.exe" -prg .\NCM1.prg