c:\cx16\acme\acme.exe -f cbm -DDEBUG=1 -DSANITY=1 -r snake.rpt -o bin\snake.prg src\snake.asm

IF NOT ERRORLEVEL 1 call run
