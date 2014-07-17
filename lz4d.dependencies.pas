{
LZ4 for Delphi - Delphi bindings for lz4
Copyright (C) 2014, Hanno Hugenberg
BSD 2-Clause License (http://www.opensource.org/licenses/bsd-license.php)

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Project repository: https://github.com/Hugie/lz4-delphi

Lz4 and xxHash by Yann Collet: https://github.com/Cyan4973
}

unit lz4d.dependencies;

{$I lz4d.defines.inc}


interface

///Since we link .o object files directly, there may be some referenced functions missing
///  - solution: reimplement these functions or deliver object files for them

{$IfDef MinGW_LIB}
  // * MinGW * //

  //object files were build with lz4s make file
  //mingw 4.8.1

  ////"___chkstk_ms" needed
  ///  bind via object file
  ///  -> extracted from MinGW\lib\gcc\mingw32\4.8.1\libgcc.a
  {$L lib/win32_mingw/chkstk_ms.o}
  procedure ___chkstk_ms; cdecl; external;

{$Else}

  {$IfDef VS_LIB}
  // * Visual Studio * //

    ////"__chkstk" function needed
    ///
    ///  Due to licence restrictions (and problems avoidance) we do NOT deliver the necessary object file
    ///  with these lz4 bindings.
    ///  You need to copy the necessary files by yourself.
    ///  In the test case of Visual Studio 11, it is located at:
    ///  "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\lib\chkstk.obj"
    ///
    ///  Copy the files to
    ///
    {$L lib/win32_vs/chkstk.obj}
    procedure __chkstk; cdecl; external;
  {$EndIf}

{$EndIf}

///"_memcpy, _memset, _calloc, _free" needed

{$IfDef VS_LIB}
  ///Visual studio uses different function names
  function  __imp__calloc(count, size: cardinal): Pointer; cdecl;
  procedure __imp__free(P: Pointer); cdecl;
{$Else}
  function  _calloc(count, size: cardinal): Pointer; cdecl;
  procedure _free(P: Pointer); cdecl;
{$EndIf}

function  _malloc(size: cardinal): Pointer; cdecl;
procedure _memcpy(dest, source: Pointer; count: Integer); cdecl;
function  _memset(P: Pointer; B: Integer; count: Integer): pointer; cdecl;


implementation

{$IfDef VS_LIB}
  function  __imp__calloc(count, size: cardinal): Pointer; cdecl;
{$Else}
  function  _calloc(count, size: cardinal): Pointer; cdecl;
{$EndIf}
begin
  GetMem(   Result,   count*size);
  FillChar( Result^,  count*size, 0);
end;

{$IfDef VS_LIB}
  procedure __imp__free(P: Pointer); cdecl;
{$Else}
  procedure _free(P: Pointer); cdecl;
{$EndIf}
begin
  FreeMem(P);
end;

function  _malloc(size: cardinal): Pointer; cdecl;
begin
  GetMem(Result, size);
end;

function _memset(P: Pointer; B: Integer; count: Integer): pointer; cdecl;
begin
  result := P;
  FillChar(P^, count, B);
end;

procedure _memcpy(dest, source: Pointer; count: Integer); cdecl;
begin
  Move(source^, dest^, count);
end;

end.
