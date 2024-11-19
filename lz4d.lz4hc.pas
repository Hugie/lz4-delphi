unit lz4d.lz4hc;

interface

{$WARN UNSAFE_TYPE OFF}

{$I LZ4.inc}

uses
  lz4d.lz4,
  lz4d.Imports;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const
  LZ4HC_CLEVEL_MIN = 2;
  LZ4HC_CLEVEL_DEFAULT = 9;
  LZ4HC_CLEVEL_OPT_MIN = 10;
  LZ4HC_CLEVEL_MAX = 12;
  LZ4HC_DICTIONARY_LOGSIZE = 16;
  LZ4HC_MAXD = (1 shl LZ4HC_DICTIONARY_LOGSIZE);
  LZ4HC_MAXD_MASK = (LZ4HC_MAXD-1);
  LZ4HC_HASH_LOG = 15;
  LZ4HC_HASHTABLESIZE = (1 shl LZ4HC_HASH_LOG);
  LZ4HC_HASH_MASK = (LZ4HC_HASHTABLESIZE-1);
  LZ4_STREAMHC_MINSIZE = 262200;

type
  PLZ4HC_CCtx_internal = ^LZ4HC_CCtx_internal;
  LZ4HC_CCtx_internal = record
    hashTable: array [0..32767] of Cardinal;
    chainTable: array [0..65535] of Word;
    end_: PByte;
    prefixStart: PByte;
    dictStart: PByte;
    dictLimit: Cardinal;
    lowLimit: Cardinal;
    nextToUpdate: Cardinal;
    compressionLevel: Smallint;
    favorDecSpeed: ShortInt;
    dirty: ShortInt;
    dictCtx: PLZ4HC_CCtx_internal;
  end;

  LZ4_streamHC_t = record
    case Integer of
      0: (minStateSize: array [0..262199] of Byte);
      1: (internal_donotuse: LZ4HC_CCtx_internal);
  end;
  PLZ4_streamHC_t = ^LZ4_streamHC_t;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
(*! LZ4_compress_HC() :
 *  Compress data from `src` into `dst`, using the powerful but slower "HC" algorithm.
 * `dst` must be already allocated.
 *  Compression is guaranteed to succeed if `dstCapacity >= LZ4_compressBound(srcSize)` (see "lz4.h")
 *  Max supported `srcSize` value is LZ4_MAX_INPUT_SIZE (see "lz4.h")
 * `compressionLevel` : any value between 1 and LZ4HC_CLEVEL_MAX will work.
 *                      Values > LZ4HC_CLEVEL_MAX behave the same as LZ4HC_CLEVEL_MAX.
 * @return : the number of bytes written into 'dst'
 *           or 0 if compression fails.
 *)
function {$IFNDEF UNDERSCORE}LZ4_compress_HC{$ELSE}_LZ4_compress_HC{$ENDIF}(const ASource: Pointer; ADestination: Pointer; srcSize: Integer; dstCapacity: Integer; compressionLevel: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_HC'{$IFEND};

(*! LZ4_compress_HC_extStateHC() :
 *  Same as LZ4_compress_HC(), but using an externally allocated memory segment for `state`.
 * `state` size is provided by LZ4_sizeofStateHC().
 *  Memory segment must be aligned on 8-bytes boundaries (which a normal malloc() should do properly).
 *)
function {$IFNDEF UNDERSCORE}LZ4_sizeofStateHC{$ELSE}_LZ4_sizeofStateHC{$ENDIF}: Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_sizeofStateHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compress_HC_extStateHC{$ELSE}_LZ4_compress_HC_extStateHC{$ENDIF}(stateHC: Pointer; const ASource: Pointer; ADestination: Pointer; srcSize: Integer; maxDstSize: Integer; compressionLevel: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_HC_extStateHC'{$IFEND};

(*! LZ4_compress_HC_destSize() : v1.9.0+
 *  Will compress as much data as possible from `src`
 *  to fit into `targetDstSize` budget.
 *  Result is provided in 2 parts :
 * @return : the number of bytes written into 'dst' (necessarily <= targetDstSize)
 *           or 0 if compression fails.
 * `srcSizePtr` : on success, *srcSizePtr is updated to indicate how much bytes were read from `src`
 *)
function {$IFNDEF UNDERSCORE}LZ4_compress_HC_destSize{$ELSE}_LZ4_compress_HC_destSize{$ENDIF}(stateHC: Pointer; const ASource: Pointer; ADestination: Pointer; srcSizePtr: PInteger; targetDstSize: Integer; compressionLevel: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_HC_destSize'{$IFEND};

(*! LZ4_createStreamHC() and LZ4_freeStreamHC() :
 *  These functions create and release memory for LZ4 HC streaming state.
 *  Newly created states are automatically initialized.
 *  A same state can be used multiple times consecutively,
 *  starting with LZ4_resetStreamHC_fast() to start a new stream of blocks.
 *)
function {$IFNDEF UNDERSCORE}LZ4_createStreamHC{$ELSE}_LZ4_createStreamHC{$ENDIF}: PLZ4_streamHC_t; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_createStreamHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_freeStreamHC{$ELSE}_LZ4_freeStreamHC{$ENDIF}(streamHCPtr: PLZ4_streamHC_t): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_freeStreamHC'{$IFEND};

procedure {$IFNDEF UNDERSCORE}LZ4_resetStreamHC_fast{$ELSE}_LZ4_resetStreamHC_fast{$ENDIF}(streamHCPtr: PLZ4_streamHC_t; compressionLevel: Integer); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_resetStreamHC_fast'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_loadDictHC{$ELSE}_LZ4_loadDictHC{$ENDIF}(streamHCPtr: PLZ4_streamHC_t; const dictionary: PByte; dictSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_loadDictHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compress_HC_continue{$ELSE}_LZ4_compress_HC_continue{$ENDIF}(streamHCPtr: PLZ4_streamHC_t; const ASource: Pointer; ADestination: Pointer; srcSize: Integer; maxDstSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_HC_continue'{$IFEND};

(*! LZ4_compress_HC_continue_destSize() : v1.9.0+
 *  Similar to LZ4_compress_HC_continue(),
 *  but will read as much data as possible from `src`
 *  to fit into `targetDstSize` budget.
 *  Result is provided into 2 parts :
 * @return : the number of bytes written into 'dst' (necessarily <= targetDstSize)
 *           or 0 if compression fails.
 * `srcSizePtr` : on success, *srcSizePtr will be updated to indicate how much bytes were read from `src`.
 *           Note that this function may not consume the entire input.
 *)
function {$IFNDEF UNDERSCORE}LZ4_compress_HC_continue_destSize{$ELSE}_LZ4_compress_HC_continue_destSize{$ENDIF}(LZ4_streamHCPtr: PLZ4_streamHC_t; const ASource: Pointer; ADestination: Pointer; srcSizePtr: PInteger; targetDstSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_HC_continue_destSize'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_saveDictHC{$ELSE}_LZ4_saveDictHC{$ENDIF}(streamHCPtr: PLZ4_streamHC_t; safeBuffer: PByte; maxDictSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_saveDictHC'{$IFEND};

(*! LZ4_attach_HC_dictionary() : stable since v1.10.0
 *  This API allows for the efficient re-use of a static dictionary many times.
 *
 *  Rather than re-loading the dictionary buffer into a working context before
 *  each compression, or copying a pre-loaded dictionary's LZ4_streamHC_t into a
 *  working LZ4_streamHC_t, this function introduces a no-copy setup mechanism,
 *  in which the working stream references the dictionary stream in-place.
 *
 *  Several assumptions are made about the state of the dictionary stream.
 *  Currently, only streams which have been prepared by LZ4_loadDictHC() should
 *  be expected to work.
 *
 *  Alternatively, the provided dictionary stream pointer may be NULL, in which
 *  case any existing dictionary stream is unset.
 *
 *  A dictionary should only be attached to a stream without any history (i.e.,
 *  a stream that has just been reset).
 *
 *  The dictionary will remain attached to the working stream only for the
 *  current stream session. Calls to LZ4_resetStreamHC(_fast) will remove the
 *  dictionary context association from the working stream. The dictionary
 *  stream (and source buffer) must remain in-place / accessible / unchanged
 *  through the lifetime of the stream session.
 *)
procedure {$IFNDEF UNDERSCORE}LZ4_attach_HC_dictionary{$ELSE}_LZ4_attach_HC_dictionary{$ENDIF}(working_stream: PLZ4_streamHC_t; const dictionary_stream: PLZ4_streamHC_t); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_attach_HC_dictionary'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_initStreamHC{$ELSE}_LZ4_initStreamHC{$ENDIF}(buffer: Pointer; size: NativeUInt): PLZ4_streamHC_t; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_initStreamHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC{$ELSE}_LZ4_compressHC{$ENDIF}(const ASource: Pointer; ADestination: Pointer; inputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC_limitedOutput{$ELSE}_LZ4_compressHC_limitedOutput{$ENDIF}(const ASource: Pointer; ADestination: Pointer; inputSize: Integer; maxOutputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC_limitedOutput'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC2{$ELSE}_LZ4_compressHC2{$ENDIF}(const ASource: Pointer; ADestination: Pointer; inputSize: Integer; compressionLevel: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC2'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC2_limitedOutput{$ELSE}_LZ4_compressHC2_limitedOutput{$ENDIF}(const ASource: Pointer; ADestination: Pointer; inputSize: Integer; maxOutputSize: Integer; compressionLevel: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC2_limitedOutput'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC_withStateHC{$ELSE}_LZ4_compressHC_withStateHC{$ENDIF}(state: Pointer; const ASource: Pointer; ADestination: Pointer; inputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC_withStateHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC_limitedOutput_withStateHC{$ELSE}_LZ4_compressHC_limitedOutput_withStateHC{$ENDIF}(state: Pointer; const ASource: Pointer; ADestination: Pointer; inputSize: Integer; maxOutputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC_limitedOutput_withStateHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC2_withStateHC{$ELSE}_LZ4_compressHC2_withStateHC{$ENDIF}(state: Pointer; const ASource: Pointer; ADestination: Pointer; inputSize: Integer; compressionLevel: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC2_withStateHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC2_limitedOutput_withStateHC{$ELSE}_LZ4_compressHC2_limitedOutput_withStateHC{$ENDIF}(state: Pointer; const ASource: Pointer; ADestination: Pointer; inputSize: Integer; maxOutputSize: Integer; compressionLevel: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC2_limitedOutput_withStateHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC_continue{$ELSE}_LZ4_compressHC_continue{$ENDIF}(LZ4_streamHCPtr: PLZ4_streamHC_t; const ASource: Pointer; ADestination: Pointer; inputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC_continue'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC_limitedOutput_continue{$ELSE}_LZ4_compressHC_limitedOutput_continue{$ENDIF}(LZ4_streamHCPtr: PLZ4_streamHC_t; const ASource: Pointer; ADestination: Pointer; inputSize: Integer; maxOutputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC_limitedOutput_continue'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_createHC{$ELSE}_LZ4_createHC{$ENDIF}(const inputBuffer: PByte): Pointer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_createHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_freeHC{$ELSE}_LZ4_freeHC{$ENDIF}(LZ4HC_Data: Pointer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_freeHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_slideInputBufferHC{$ELSE}_LZ4_slideInputBufferHC{$ENDIF}(LZ4HC_Data: Pointer): PByte; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_slideInputBufferHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC2_continue{$ELSE}_LZ4_compressHC2_continue{$ENDIF}(LZ4HC_Data: Pointer; const ASource: Pointer; ADestination: Pointer; inputSize: Integer; compressionLevel: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC2_continue'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compressHC2_limitedOutput_continue{$ELSE}_LZ4_compressHC2_limitedOutput_continue{$ENDIF}(LZ4HC_Data: Pointer; const ASource: Pointer; ADestination: Pointer; inputSize: Integer; maxOutputSize: Integer; compressionLevel: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressHC2_limitedOutput_continue'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_sizeofStreamStateHC{$ELSE}_LZ4_sizeofStreamStateHC{$ENDIF}: Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_sizeofStreamStateHC'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_resetStreamStateHC{$ELSE}_LZ4_resetStreamStateHC{$ENDIF}(state: Pointer; inputBuffer: PByte): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_resetStreamStateHC'{$IFEND};

procedure {$IFNDEF UNDERSCORE}LZ4_resetStreamHC{$ELSE}_LZ4_resetStreamHC{$ENDIF}(streamHCPtr: PLZ4_streamHC_t; compressionLevel: Integer); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_resetStreamHC'{$IFEND};

(*! LZ4_setCompressionLevel() : v1.8.0+ (experimental)
 *  It's possible to change compression level
 *  between successive invocations of LZ4_compress_HC_continue*()
 *  for dynamic adaptation.
 *)
procedure {$IFNDEF UNDERSCORE}LZ4_setCompressionLevel{$ELSE}_LZ4_setCompressionLevel{$ENDIF}(LZ4_streamHCPtr : PLZ4_streamHC_t; compressionLevel : Integer); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_setCompressionLevel'{$IFEND};

(*! LZ4_favorDecompressionSpeed() : v1.8.2+ (experimental)
 *  Opt. Parser will favor decompression speed over compression ratio.
 *  Only applicable to levels >= LZ4HC_CLEVEL_OPT_MIN.
 *)
procedure {$IFNDEF UNDERSCORE}LZ4_favorDecompressionSpeed{$ELSE}_LZ4_favorDecompressionSpeed{$ENDIF}(LZ4_streamHCPtr : PLZ4_streamHC_t; favor : Integer); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_favorDecompressionSpeed'{$IFEND};

(*! LZ4_compress_HC_extStateHC_fastReset() :
 *  A variant of LZ4_compress_HC_extStateHC().
 *
 *  Using this variant avoids an expensive initialization step. It is only safe
 *  to call if the state buffer is known to be correctly initialized already
 *  (see above comment on LZ4_resetStreamHC_fast() for a definition of
 *  "correctly initialized"). From a high level, the difference is that this
 *  function initializes the provided state with a call to
 *  LZ4_resetStreamHC_fast() while LZ4_compress_HC_extStateHC() starts with a
 *  call to LZ4_resetStreamHC().
 *)
function {$IFNDEF UNDERSCORE}LZ4_compress_HC_extStateHC_fastReset{$ELSE}_LZ4_compress_HC_extStateHC_fastReset{$ENDIF}(state : Pointer; const src : PByte; const dst : PByte; srcSize : Integer; dstCapacity : Integer; compressionLevel : Integer) : Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_HC_extStateHC_fastReset'{$IFEND};

implementation

{$IFDEF Win64}
  {$L Win64\lz4hc.o}
{$ELSE}
  {$L Win32\lz4hc.o}
{$ENDIF}

end.
