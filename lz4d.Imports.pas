unit lz4d.Imports;

interface

{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_TYPE OFF}

{$I LZ4.inc}

uses
  Classes;
  
{$IF CompilerVersion <= 20}
type
  NativeUInt = Cardinal;
  PNativeUInt = ^NativeUInt;
{$IFEND}
  
const
{$IFDEF UNDERSCORE}
  _PU = '_';
{$ELSE}
  _PU = '';
{$ENDIF}  

function  {$IFNDEF UNDERSCORE}calloc{$ELSE}_calloc{$ENDIF}(count, size: NativeUInt): Pointer; cdecl;
procedure {$IFNDEF UNDERSCORE}free{$ELSE}_free{$ENDIF}(P: Pointer); cdecl;

function  {$IFNDEF UNDERSCORE}malloc{$ELSE}_malloc{$ENDIF}(size: NativeUInt): Pointer; cdecl;
procedure {$IFNDEF UNDERSCORE}memcpy{$ELSE}_memcpy{$ENDIF}(dest, source: Pointer; count: NativeUInt); cdecl;
function  {$IFNDEF UNDERSCORE}memset{$ELSE}_memset{$ENDIF}(P: Pointer; B: Integer; count: NativeUInt): pointer; cdecl;

procedure {$IFNDEF UNDERSCORE}_Assert{$ELSE}__Assert{$ENDIF}(const Message, Filename: string; LineNumber: Integer); cdecl;

procedure {$IFNDEF UNDERSCORE}memmove{$ELSE}_memmove{$ENDIF}; external 'msvcrt.dll' name 'memmove';

{$IFDEF Win64}
procedure __chkstk;
{$ELSE}
procedure __chkstk_noalloc;
//procedure __chkstk_ms;
{$ENDIF}

// lz4file
function {$IFNDEF UNDERSCORE}fread{$ELSE}_fread{$ENDIF}(var buf; recsize, reccount: Integer; S: TStream): Integer;
function {$IFNDEF UNDERSCORE}fwrite{$ELSE}_fwrite{$ENDIF}(const buf; recsize, reccount: Integer; S: TStream): Integer;

implementation

function {$IFNDEF UNDERSCORE}calloc{$ELSE}_calloc{$ENDIF}(count, size: NativeUInt): Pointer; cdecl;
begin
  GetMem(   Result,   count*size);
  FillChar( Result^,  count*size, 0);
end;

procedure {$IFDEF Win64}free{$ELSE}_free{$ENDIF}(P: Pointer); cdecl;
begin
  FreeMem(P);
end;

function {$IFNDEF UNDERSCORE}malloc{$ELSE}_malloc{$ENDIF}(size: NativeUInt): Pointer; cdecl;
begin
  GetMem(Result, size);
end;

function {$IFNDEF UNDERSCORE}memset{$ELSE}_memset{$ENDIF}(P: Pointer; B: Integer; count: NativeUInt): pointer; cdecl;
begin
  result := P;
  FillChar(P^, count, B);
end;

procedure {$IFNDEF UNDERSCORE}memcpy{$ELSE}_memcpy{$ENDIF}(dest, source: Pointer; count: NativeUInt); cdecl;
begin
  Move(source^, dest^, count);
end;

procedure {$IFNDEF UNDERSCORE}_Assert{$ELSE}__Assert{$ENDIF}(const Message, Filename: string; LineNumber: Integer); cdecl;
asm
  jmp System.@Assert;
end;

{$IFDEF WIN32}
procedure __chkstk_noalloc;
//procedure __chkstk_ms;
asm
  push ecx
  push eax
  cmp eax,$00001000
  lea ecx,[esp+$0c]
  jb @@2
@@1:
  sub ecx,$00001000
  or dword ptr [ecx],$00
  sub eax,$00001000
  cmp eax,$00001000
  jnbe @@1
@@2:
  sub ecx,eax
  or dword ptr [ecx],$00
  pop eax
  pop ecx
  ret
end;
{$ENDIF WIN32}

{$IFDEF Win64}
procedure __chkstk;
asm
  .NOFRAME
  sub rsp, $10
  mov [rsp], r10
  mov [rsp+8], r11
  xor r11,r11
  lea r10, [rsp+$18]
  sub r10,rax
  cmovb r10,r11
  mov r11, qword ptr gs:[$10]
  cmp r10,r11
  db $f2
  jae @@L1
  and r10w,$F000
@@L2:
  lea r11, [r11-$1000]
  mov byte [r11],0
  cmp r10,r11
  db $f2
  jne @@L2
@@L1:
  mov r10, [rsp]
  mov r11, [rsp+8]
  add rsp, $10
  db $f2
  ret
end;
{$ENDIF}

function {$IFNDEF UNDERSCORE}fread{$ELSE}_fread{$ENDIF}(var buf; recsize, reccount: Integer; S: TStream): Integer;
begin
  Result := S.Read(buf, recsize * reccount);
end;

function {$IFNDEF UNDERSCORE}fwrite{$ELSE}_fwrite{$ENDIF}(const buf; recsize, reccount: Integer; S: TStream): Integer;
begin
  Result := S.Write(buf, recsize * reccount);
end;

end.
