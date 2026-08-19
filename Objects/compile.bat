@echo off
rem ============================================================================
rem LZ4 v1.10.0 - object build for the Delphi include (sync 2026-08-10)
rem
rem Win32: OMF via bcc32c (portable C++Builder command-line tools 12.2)
rem        -> links with dcc32 from Delphi 7 upwards (OMF)
rem Win64: COFF via MSVC cl (VS 2026 Community)
rem        -> dcc64 links COFF since XE2; ONE set covers Win64 AND Win64x
rem
rem Pascal-side particularity for Win64/COFF: lz4.obj references the
rem vcruntime dispatch variable __isa_available - provided in
rem lz4d.Imports.pas as an interface variable (0 = SSE2 baseline).
rem After EVERY rebuild: run ..\Source\Tests\build_run.ps1 (layout+roundtrip, -D7)!
rem ============================================================================

set FILES=lz4.c lz4hc.c lz4frame.c lz4file.c xxhash.c
set DEFS=-DNDEBUG

rem --- adjust paths if needed ---
set BCC=D:\Delphi\___Claude Workspace\uTLH\BorlandComandlineCompiler
set VCVARS=C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat

echo ######## Win32 (OMF, bcc32c) ########
pushd "%~dp0"
for %%F in (%FILES%) do (
  "%BCC%\bin\bcc32c.exe" -c -q %DEFS% -D_WIN32 -I"%BCC%\include\windows\crtl" -I"%BCC%\include\windows\sdk" ".\C\%%F"
)
rem include convention: Win32 objects are named .o as well
for %%F in (*.obj) do move /Y "%%F" "Win32\%%~nF.o" >nul
popd

echo ######## Win64 (COFF, MSVC cl) ########
call "%VCVARS%" >nul 2>&1
pushd "%~dp0"
for %%F in (%FILES%) do (
  cl -c -nologo -O2 -wd4273 -wd4099 -GS- %DEFS% -D_WIN64 ".\C\%%F"
)
for %%F in (*.obj) do move /Y "%%F" "Win64\%%~nF.o" >nul
popd

echo.
echo Done. Copy the objects to ..\Source\Win32 and ..\Source\Win64 and run
echo ..\Source\Tests\build_run.ps1. Check the file SIZES afterwards - a
echo 0-byte object means the compiler aborted silently!
