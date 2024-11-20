@echo off

set option=-c -nWin32 -q -D_LZMA_PROB32 -D_WIN32
bcc32c.exe %option% .\C\*.c

set option=-c -q -D_LZMA_PROB32 -D_WIN64
bcc64.exe %option% .\C\*.c
move *.o Win64
goto :End

:End
set option=