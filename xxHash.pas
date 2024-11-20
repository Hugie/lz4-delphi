unit xxHash;

interface

{$WARN UNSAFE_TYPE OFF}

{$I LZ4.inc}

uses
  lz4d.Imports;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const
  XXHASH_H_5627135585666179 = 1;
  XXH_VERSION_MAJOR = 0;
  XXH_VERSION_MINOR = 6;
  XXH_VERSION_RELEASE = 5;
  XXH_VERSION_NUMBER = (XXH_VERSION_MAJOR*100*100+XXH_VERSION_MINOR*100+XXH_VERSION_RELEASE);

{$MINENUMSIZE 4}
type
  {$IF NOT Declared( PUInt64 )}
  PUInt64 = ^UInt64;
  {$IFEND}

  XXH_errorcode = (
    XXH_OK    = 0,
    XXH_ERROR = 1
  );

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function {$IFNDEF UNDERSCORE}XXH_versionNumber{$ELSE}_XXH_versionNumber{$ENDIF}: Cardinal; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH_versionNumber'{$IFEND};

(*! XXH32() :
    Calculate the 32-bit hash of sequence "length" bytes stored at memory address "input".
    The memory between input & input+length must be valid (allocated and read-accessible).
    "seed" can be used to alter the result predictably.
    Speed on Core 2 Duo @ 3 GHz (single thread, SMHasher benchmark) : 5.4 GB/s *)
function {$IFNDEF UNDERSCORE}XXH32{$ELSE}_XXH32{$ENDIF}(const input: Pointer; length: NativeUInt; seed: Cardinal): Cardinal; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH32'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH32_createState{$ELSE}_XXH32_createState{$ENDIF}: Pointer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH32_createState'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH32_freeState{$ELSE}_XXH32_freeState{$ENDIF}(statePtr: Pointer): XXH_errorcode; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH32_freeState'{$IFEND};

procedure {$IFNDEF UNDERSCORE}XXH32_copyState{$ELSE}_XXH32_copyState{$ENDIF}(dst_state: Pointer; const src_state: Pointer); cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH32_copyState'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH32_reset{$ELSE}_XXH32_reset{$ENDIF}(statePtr: Pointer; seed: Cardinal): XXH_errorcode; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH32_reset'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH32_update{$ELSE}_XXH32_update{$ENDIF}(statePtr: Pointer; const input: Pointer; length: NativeUInt): XXH_errorcode; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH32_update'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH32_digest{$ELSE}_XXH32_digest{$ENDIF}(const statePtr: Pointer): Cardinal; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH32_digest'{$IFEND};

procedure {$IFNDEF UNDERSCORE}XXH32_canonicalFromHash{$ELSE}_XXH32_canonicalFromHash{$ENDIF}(dst: PCardinal; hash: Cardinal); cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH32_canonicalFromHash'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH32_hashFromCanonical{$ELSE}_XXH32_hashFromCanonical{$ENDIF}(const src: PCardinal): Cardinal; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH32_hashFromCanonical'{$IFEND};

(*! XXH64() :
    Calculate the 64-bit hash of sequence of length "len" stored at memory address "input".
    "seed" can be used to alter the result predictably.
    This function runs faster on 64-bit systems, but slower on 32-bit systems (see benchmark).
 *)
function {$IFNDEF UNDERSCORE}XXH64{$ELSE}_XXH64{$ENDIF}(const input: Pointer; length: NativeUInt; seed: UInt64): UInt64; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH64'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH64_createState{$ELSE}_XXH64_createState{$ENDIF}: Pointer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH64_createState'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH64_freeState{$ELSE}_XXH64_freeState{$ENDIF}(statePtr: Pointer): XXH_errorcode; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH64_freeState'{$IFEND};

procedure {$IFNDEF UNDERSCORE}XXH64_copyState{$ELSE}_XXH64_copyState{$ENDIF}(dst_state: Pointer; const src_state: Pointer); cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH64_copyState'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH64_reset{$ELSE}_XXH64_reset{$ENDIF}(statePtr: Pointer; seed: UInt64): XXH_errorcode; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH64_reset'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH64_update{$ELSE}_XXH64_update{$ENDIF}(statePtr: Pointer; const input: Pointer; length: NativeUInt): XXH_errorcode; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH64_update'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH64_digest{$ELSE}_XXH64_digest{$ENDIF}(const statePtr: Pointer): UInt64; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH64_digest'{$IFEND};

procedure {$IFNDEF UNDERSCORE}XXH64_canonicalFromHash{$ELSE}_XXH64_canonicalFromHash{$ENDIF}(dst: PUInt64; hash: UInt64); cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH64_canonicalFromHash'{$IFEND};

function {$IFNDEF UNDERSCORE}XXH64_hashFromCanonical{$ELSE}_XXH64_hashFromCanonical{$ENDIF}(const src: PUInt64): UInt64; cdecl; external {$IF CompilerVersion > 22}name _PU + 'XXH64_hashFromCanonical'{$IFEND};

implementation

{$IFDEF Win64}
  {$L Win64\xxhash.o}
{$ELSE}
  {$L Win32\xxhash.o}
{$ENDIF}

end.
