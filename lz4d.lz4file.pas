unit lz4d.lz4file;

interface

{$WARN UNSAFE_TYPE OFF}

{$I LZ4.inc}

uses
  lz4d.lz4frame,
  lz4d.Imports;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
type
  PLZ4_readFile_t = Pointer;
  PPLZ4_readFile_t = ^PLZ4_readFile_t;
  PLZ4_writeFile_t = Pointer;
  PPLZ4_writeFile_t = ^PLZ4_writeFile_t;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
(*! LZ4F_readOpen() :
 * Set read lz4file handle.
 * `lz4f` will set a lz4file handle.
 * `fp` must be the return value of the lz4 file opened by fopen.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_readOpen{$ELSE}_LZ4F_readOpen{$ENDIF}(lz4fRead: PPLZ4_readFile_t; fp: PPointer): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_readOpen'{$IFEND};

(*! LZ4F_read() :
 * Read lz4file content to buffer.
 * `lz4f` must use LZ4_readOpen to set first.
 * `buf` read data buffer.
 * `size` read data buffer size.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_read{$ELSE}_LZ4F_read{$ENDIF}(lz4fRead: PLZ4_readFile_t; buf: Pointer; size: NativeUInt): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_read'{$IFEND};

(*! LZ4F_readClose() :
 * Close lz4file handle.
 * `lz4f` must use LZ4_readOpen to set first.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_readClose{$ELSE}_LZ4F_readClose{$ENDIF}(lz4fRead: PLZ4_readFile_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_readClose'{$IFEND};

(*! LZ4F_writeOpen() :
 * Set write lz4file handle.
 * `lz4f` will set a lz4file handle.
 * `fp` must be the return value of the lz4 file opened by fopen.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_writeOpen{$ELSE}_LZ4F_writeOpen{$ENDIF}(lz4fWrite: PPLZ4_writeFile_t; fp: PPointer; const prefsPtr: PLZ4F_preferences_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_writeOpen'{$IFEND};

(*! LZ4F_write() :
 * Write buffer to lz4file.
 * `lz4f` must use LZ4F_writeOpen to set first.
 * `buf` write data buffer.
 * `size` write data buffer size.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_write{$ELSE}_LZ4F_write{$ENDIF}(lz4fWrite: PLZ4_writeFile_t; const buf: Pointer; size: NativeUInt): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_write'{$IFEND};

(*! LZ4F_writeClose() :
 * Close lz4file handle.
 * `lz4f` must use LZ4F_writeOpen to set first.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_writeClose{$ELSE}_LZ4F_writeClose{$ENDIF}(lz4fWrite: PLZ4_writeFile_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_writeClose'{$IFEND};

implementation

{$IFDEF Win64}
  {$L Win64\lz4file.o}
{$ELSE}
  {$L Win32\lz4file.o}
{$ENDIF}

end.