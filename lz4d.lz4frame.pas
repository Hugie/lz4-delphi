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

unit lz4d.lz4frame;

{$I lz4d.defines.inc}

interface

//WIP - throwing errors due to bad _XXH32 include

//// bind necessary object files
//
//// * MinGW * //
//{$IfDef MinGW_LIB}
//  {$L lib/win32_mingw/lz4frame.o}
//  {$L lib/win32_mingw/lz4.o}
//  {$L lib/win32_mingw/xxhash.o}
//{$EndIf}
//
//// * Visual Studio * //
//{$IfDef VS_LIB}
//  {$L lib/win32_vs/lz4frame.obj}
//  {$L lib/win32_mingw/lz4.obj}
//  {$L lib/win32_vs/xxhash.obj}
//{$EndIf}
//
//
///// Linking lz4 object files and adding dependencies
///// - linking the object files produces additional dependencies
/////    which would be usaly provided by the object file linker
/////  - see dependency units for more informations
//
//uses
//{$IfDef ResolveMissingDependencies}
//  lz4d.dependencies;
//{$Else}
//  ;
//{$Endif}
//
//
//
/////**************************************
/////Version
/////**************************************/
/////
/////
//{$Define LZ4F_VERSION 100}
//
//
/////**************************************
////   Error management
////**************************************/
//
//type
//  LZ4F_errorCode = NativeUInt;
//
//function LZ4F_isError(      code: LZ4F_errorCode ): Integer;    cdecl; external name '_LZ4F_isError';
//function LZ4F_getErrorName( code: LZ4F_errorCode ): PAnsiChar;  cdecl; external name '_LZ4F_getErrorName';



implementation


end.
