unit lz4d.lz4frame;

interface

{$WARN UNSAFE_TYPE OFF}

{$I LZ4.inc}

uses
  lz4d.lz4,
  lz4d.lz4hc,
  xxHash,
  lz4d.Imports;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const
  LZ4F_VERSION = 100;
  LZ4F_HEADER_SIZE_MIN = 7;
  LZ4F_HEADER_SIZE_MAX = 19;
  LZ4F_BLOCK_HEADER_SIZE = 4;
  LZ4F_BLOCK_CHECKSUM_SIZE = 4;
  LZ4F_CONTENT_CHECKSUM_SIZE = 4;
  LZ4F_ENDMARK_SIZE = 4;
  LZ4F_MAGICNUMBER = $184D2204;
  LZ4F_MAGIC_SKIPPABLE_START = $184D2A50;
  LZ4F_MIN_SIZE_TO_KNOW_HEADER_LENGTH = 5;

{$MINENUMSIZE 4}
type
  LZ4F_errorCodes = (
    LZ4F_OK_NoError = 0,
    LZ4F_ERROR_GENERIC = 1,
    LZ4F_ERROR_maxBlockSize_invalid = 2,
    LZ4F_ERROR_blockMode_invalid = 3,
    LZ4F_ERROR_parameter_invalid = 4,
    LZ4F_ERROR_compressionLevel_invalid = 5,
    LZ4F_ERROR_headerVersion_wrong = 6,
    LZ4F_ERROR_blockChecksum_invalid = 7,
    LZ4F_ERROR_reservedFlag_set = 8,
    LZ4F_ERROR_allocation_failed = 9,
    LZ4F_ERROR_srcSize_tooLarge = 10,
    LZ4F_ERROR_dstMaxSize_tooSmall = 11,
    LZ4F_ERROR_frameHeader_incomplete = 12,
    LZ4F_ERROR_frameType_unknown = 13,
    LZ4F_ERROR_frameSize_wrong = 14,
    LZ4F_ERROR_srcPtr_wrong = 15,
    LZ4F_ERROR_decompressionFailed = 16,
    LZ4F_ERROR_headerChecksum_invalid = 17,
    LZ4F_ERROR_contentChecksum_invalid = 18,
    LZ4F_ERROR_frameDecoding_alreadyStarted = 19,
    LZ4F_ERROR_compressionState_uninitialized = 20,
    LZ4F_ERROR_parameter_null = 21,
    LZ4F_ERROR_io_write = 22,
    LZ4F_ERROR_io_read = 23,
    LZ4F_ERROR_maxCode = 24
  );

  LZ4F_blockSizeID_t = (
    LZ4F_default = 0,
    LZ4F_max64KB = 4,
    LZ4F_max256KB = 5,
    LZ4F_max1MB = 6,
    LZ4F_max4MB = 7
  );

  LZ4F_blockMode_t = (
    LZ4F_blockLinked = 0,
    LZ4F_blockIndependent = 1
  );

  LZ4F_contentChecksum_t = (
    LZ4F_noContentChecksum = 0,
    LZ4F_contentChecksumEnabled = 1
  );

  LZ4F_blockChecksum_t = (
    LZ4F_noBlockChecksum = 0,
    LZ4F_blockChecksumEnabled = 1
  );

  LZ4F_frameType_t = (
    LZ4F_frame = 0,
    LZ4F_skippableFrame = 1
  );

  (*! LZ4F_frameInfo_t :
   *  makes it possible to set or read frame parameters.
   *  Structure must be first init to 0, using memset() or LZ4F_INIT_FRAMEINFO,
   *  setting all parameters to default.
   *  It's then possible to update selectively some parameters *)
  LZ4F_frameInfo_t = record
    blockSizeID: LZ4F_blockSizeID_t;
    blockMode: LZ4F_blockMode_t;
    contentChecksumFlag: LZ4F_contentChecksum_t;
    frameType: LZ4F_frameType_t;
    contentSize: UInt64;
    dictID: Cardinal;
    blockChecksumFlag: LZ4F_blockChecksum_t;
  end;
  PLZ4F_frameInfo_t = ^LZ4F_frameInfo_t;

  (*! LZ4F_preferences_t :
   *  makes it possible to supply advanced compression instructions to streaming interface.
   *  Structure must be first init to 0, using memset() or LZ4F_INIT_PREFERENCES,
   *  setting all parameters to default.
   *  All reserved fields must be set to zero. *)
  LZ4F_preferences_t = record
    frameInfo: LZ4F_frameInfo_t;
    compressionLevel: Integer;
    autoFlush: Cardinal;
    favorDecSpeed: Cardinal;
    reserved: array [0..2] of Cardinal;
  end;
  PLZ4F_preferences_t = ^LZ4F_preferences_t;

  PLZ4F_cctx = Pointer;
  PPLZ4F_cctx = ^PLZ4F_cctx;

  LZ4F_compressOptions_t = record
    stableSrc: Cardinal;
    reserved: array [0..2] of Cardinal;
  end;
  PLZ4F_compressOptions_t = ^LZ4F_compressOptions_t;

  PLZ4F_dctx = Pointer;
  PPLZ4F_dctx = ^PLZ4F_dctx;
  LZ4F_decompressionContext_t = Pointer;
  PLZ4F_decompressionContext_t = ^LZ4F_decompressionContext_t;

  LZ4F_decompressOptions_t = record
    stableDst: Cardinal;
    skipChecksums: Cardinal;
    reserved1: Cardinal;
    reserved0: Cardinal;
  end;
  PLZ4F_decompressOptions_t = ^LZ4F_decompressOptions_t;

  PLZ4F_CDict = Pointer;

  (*! Custom memory allocation : v1.9.4+
   *  These prototypes make it possible to pass custom allocation/free functions.
   *  LZ4F_customMem is provided at state creation time, using LZ4F_create*_advanced() listed below.
   *  All allocation/free operations will be completed using these custom variants instead of regular <stdlib.h> ones.
   *)
  LZ4F_AllocFunction = function(opaqueState: Pointer; size: NativeUInt): Pointer; cdecl;

  LZ4F_CallocFunction = function(opaqueState: Pointer; size: NativeUInt): Pointer; cdecl;

  LZ4F_FreeFunction = procedure(opaqueState: Pointer; address: Pointer); cdecl;

  LZ4F_CustomMem = record
    customAlloc: LZ4F_AllocFunction;
    customCalloc: LZ4F_CallocFunction;
    customFree: LZ4F_FreeFunction;
    opaqueState: Pointer;
  end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function {$IFNDEF UNDERSCORE}LZ4F_isError{$ELSE}_LZ4F_isError{$ENDIF}(code: NativeUInt): Cardinal; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_isError'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4F_getErrorName{$ELSE}_LZ4F_getErrorName{$ENDIF}(code: NativeUInt): PAnsiChar; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_getErrorName'{$IFEND};

(*! LZ4F_compressFrame() :
 *  Compress srcBuffer content into an LZ4-compressed frame.
 *  It's a one shot operation, all input content is consumed, and all output is generated.
 *
 *  Note : it's a stateless operation (no LZ4F_cctx state needed).
 *  In order to reduce load on the allocator, LZ4F_compressFrame(), by default,
 *  uses the stack to allocate space for the compression state and some table.
 *  If this usage of the stack is too much for your application,
 *  consider compiling `lz4frame.c` with compile-time macro LZ4F_HEAPMODE set to 1 instead.
 *  All state allocations will use the Heap.
 *  It also means each invocation of LZ4F_compressFrame() will trigger several internal alloc/free invocations.
 *
 * @dstCapacity MUST be >= LZ4F_compressFrameBound(srcSize, preferencesPtr).
 * @preferencesPtr is optional : one can provide NULL, in which case all preferences are set to default.
 * @return : number of bytes written into dstBuffer.
 *           or an error code if it fails (can be tested using LZ4F_isError())
 *)
function {$IFNDEF UNDERSCORE}LZ4F_compressFrame{$ELSE}_LZ4F_compressFrame{$ENDIF}(dstBuffer: Pointer; dstCapacity: NativeUInt; const srcBuffer: Pointer; srcSize: NativeUInt; const preferencesPtr: PLZ4F_preferences_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressFrame'{$IFEND};

(*! LZ4F_compressFrameBound() :
 *  Returns the maximum possible compressed size with LZ4F_compressFrame() given srcSize and preferences.
 * `preferencesPtr` is optional. It can be replaced by NULL, in which case, the function will assume default preferences.
 *  Note : this result is only usable with LZ4F_compressFrame().
 *         It may also be relevant to LZ4F_compressUpdate() _only if_ no flush() operation is ever performed.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_compressFrameBound{$ELSE}_LZ4F_compressFrameBound{$ENDIF}(srcSize: NativeUInt; const preferencesPtr: PLZ4F_preferences_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressFrameBound'{$IFEND};

(*! LZ4F_compressionLevel_max() :
 * @return maximum allowed compression level (currently: 12)
 *)
function {$IFNDEF UNDERSCORE}LZ4F_compressionLevel_max{$ELSE}_LZ4F_compressionLevel_max{$ENDIF}: Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressionLevel_max'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4F_getVersion{$ELSE}_LZ4F_getVersion{$ENDIF}: Cardinal; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_getVersion'{$IFEND};

(*! LZ4F_createCompressionContext() :
 *  The first thing to do is to create a compressionContext object,
 *  which will keep track of operation state during streaming compression.
 *  This is achieved using LZ4F_createCompressionContext(), which takes as argument a version,
 *  and a pointer to LZ4F_cctx*, to write the resulting pointer into.
 *  @version provided MUST be LZ4F_VERSION. It is intended to track potential version mismatch, notably when using DLL.
 *  The function provides a pointer to a fully allocated LZ4F_cctx object.
 *  @cctxPtr MUST be != NULL.
 *  If @return != zero, context creation failed.
 *  A created compression context can be employed multiple times for consecutive streaming operations.
 *  Once all streaming compression jobs are completed,
 *  the state object can be released using LZ4F_freeCompressionContext().
 *  Note1 : LZ4F_freeCompressionContext() is always successful. Its return value can be ignored.
 *  Note2 : LZ4F_freeCompressionContext() works fine with NULL input pointers (do nothing).
 **)
function {$IFNDEF UNDERSCORE}LZ4F_createCompressionContext{$ELSE}_LZ4F_createCompressionContext{$ENDIF}(cctxPtr: PPLZ4F_cctx; version: Cardinal): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_createCompressionContext'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4F_freeCompressionContext{$ELSE}_LZ4F_freeCompressionContext{$ENDIF}(cctx: PLZ4F_cctx): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_freeCompressionContext'{$IFEND};

(*! LZ4F_compressBegin() :
 *  will write the frame header into dstBuffer.
 *  dstCapacity must be >= LZ4F_HEADER_SIZE_MAX bytes.
 * `prefsPtr` is optional : NULL can be provided to set all preferences to default.
 * @return : number of bytes written into dstBuffer for the header
 *           or an error code (which can be tested using LZ4F_isError())
 *)
function {$IFNDEF UNDERSCORE}LZ4F_compressBegin{$ELSE}_LZ4F_compressBegin{$ENDIF}(cctx: PLZ4F_cctx; dstBuffer: Pointer; dstCapacity: NativeUInt; const prefsPtr: PLZ4F_preferences_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressBegin'{$IFEND};

(*! LZ4F_compressBound() :
 *  Provides minimum dstCapacity required to guarantee success of
 *  LZ4F_compressUpdate(), given a srcSize and preferences, for a worst case scenario.
 *  When srcSize==0, LZ4F_compressBound() provides an upper bound for LZ4F_flush() and LZ4F_compressEnd() instead.
 *  Note that the result is only valid for a single invocation of LZ4F_compressUpdate().
 *  When invoking LZ4F_compressUpdate() multiple times,
 *  if the output buffer is gradually filled up instead of emptied and re-used from its start,
 *  one must check if there is enough remaining capacity before each invocation, using LZ4F_compressBound().
 * @return is always the same for a srcSize and prefsPtr.
 *  prefsPtr is optional : when NULL is provided, preferences will be set to cover worst case scenario.
 *  tech details :
 * @return if automatic flushing is not enabled, includes the possibility that internal buffer might already be filled by up to (blockSize-1) bytes.
 *  It also includes frame footer (ending + checksum), since it might be generated by LZ4F_compressEnd().
 * @return doesn't include frame header, as it was already generated by LZ4F_compressBegin().
 *)
function {$IFNDEF UNDERSCORE}LZ4F_compressBound{$ELSE}_LZ4F_compressBound{$ENDIF}(srcSize: NativeUInt; const prefsPtr: PLZ4F_preferences_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressBound'{$IFEND};

(*! LZ4F_compressUpdate() :
 *  LZ4F_compressUpdate() can be called repetitively to compress as much data as necessary.
 *  Important rule: dstCapacity MUST be large enough to ensure operation success even in worst case situations.
 *  This value is provided by LZ4F_compressBound().
 *  If this condition is not respected, LZ4F_compress() will fail (result is an errorCode).
 *  After an error, the state is left in a UB state, and must be re-initialized or freed.
 *  If previously an uncompressed block was written, buffered data is flushed
 *  before appending compressed data is continued.
 * `cOptPtr` is optional : NULL can be provided, in which case all options are set to default.
 * @return : number of bytes written into `dstBuffer` (it can be zero, meaning input data was just buffered).
 *           or an error code if it fails (which can be tested using LZ4F_isError())
 *)
function {$IFNDEF UNDERSCORE}LZ4F_compressUpdate{$ELSE}_LZ4F_compressUpdate{$ENDIF}(cctx: PLZ4F_cctx; dstBuffer: Pointer; dstCapacity: NativeUInt; const srcBuffer: Pointer; srcSize: NativeUInt; const cOptPtr: PLZ4F_compressOptions_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressUpdate'{$IFEND};

(*! LZ4F_flush() :
 *  When data must be generated and sent immediately, without waiting for a block to be completely filled,
 *  it's possible to call LZ4_flush(). It will immediately compress any data buffered within cctx.
 * `dstCapacity` must be large enough to ensure the operation will be successful.
 * `cOptPtr` is optional : it's possible to provide NULL, all options will be set to default.
 * @return : nb of bytes written into dstBuffer (can be zero, when there is no data stored within cctx)
 *           or an error code if it fails (which can be tested using LZ4F_isError())
 *  Note : LZ4F_flush() is guaranteed to be successful when dstCapacity >= LZ4F_compressBound(0, prefsPtr).
 *)
function {$IFNDEF UNDERSCORE}LZ4F_flush{$ELSE}_LZ4F_flush{$ENDIF}(cctx: PLZ4F_cctx; dstBuffer: Pointer; dstCapacity: NativeUInt; const cOptPtr: PLZ4F_compressOptions_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_flush'{$IFEND};

(*! LZ4F_compressEnd() :
 *  To properly finish an LZ4 frame, invoke LZ4F_compressEnd().
 *  It will flush whatever data remained within `cctx` (like LZ4_flush())
 *  and properly finalize the frame, with an endMark and a checksum.
 * `cOptPtr` is optional : NULL can be provided, in which case all options will be set to default.
 * @return : nb of bytes written into dstBuffer, necessarily >= 4 (endMark),
 *           or an error code if it fails (which can be tested using LZ4F_isError())
 *  Note : LZ4F_compressEnd() is guaranteed to be successful when dstCapacity >= LZ4F_compressBound(0, prefsPtr).
 *  A successful call to LZ4F_compressEnd() makes `cctx` available again for another compression task.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_compressEnd{$ELSE}_LZ4F_compressEnd{$ENDIF}(cctx: PLZ4F_cctx; dstBuffer: Pointer; dstCapacity: NativeUInt; const cOptPtr: PLZ4F_compressOptions_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressEnd'{$IFEND};

(*! LZ4F_createDecompressionContext() :
 *  Create an LZ4F_dctx object, to track all decompression operations.
 *  @version provided MUST be LZ4F_VERSION.
 *  @dctxPtr MUST be valid.
 *  The function fills @dctxPtr with the value of a pointer to an allocated and initialized LZ4F_dctx object.
 *  The @return is an errorCode, which can be tested using LZ4F_isError().
 *  dctx memory can be released using LZ4F_freeDecompressionContext();
 *  Result of LZ4F_freeDecompressionContext() indicates current state of decompressionContext when being released.
 *  That is, it should be == 0 if decompression has been completed fully and correctly.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_createDecompressionContext{$ELSE}_LZ4F_createDecompressionContext{$ENDIF}(dctxPtr: PPLZ4F_dctx; version: Cardinal): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_createDecompressionContext'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4F_freeDecompressionContext{$ELSE}_LZ4F_freeDecompressionContext{$ENDIF}(dctx: PLZ4F_dctx): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_freeDecompressionContext'{$IFEND};

(*! LZ4F_headerSize() : v1.9.0+
 *  Provide the header size of a frame starting at `src`.
 * `srcSize` must be >= LZ4F_MIN_SIZE_TO_KNOW_HEADER_LENGTH,
 *  which is enough to decode the header length.
 * @return : size of frame header
 *           or an error code, which can be tested using LZ4F_isError()
 *  note : Frame header size is variable, but is guaranteed to be
 *         >= LZ4F_HEADER_SIZE_MIN bytes, and <= LZ4F_HEADER_SIZE_MAX bytes.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_headerSize{$ELSE}_LZ4F_headerSize{$ENDIF}(const src: Pointer; srcSize: NativeUInt): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_headerSize'{$IFEND};

(*! LZ4F_getFrameInfo() :
 *  This function extracts frame parameters (max blockSize, dictID, etc.).
 *  Its usage is optional: user can also invoke LZ4F_decompress() directly.
 *
 *  Extracted information will fill an existing LZ4F_frameInfo_t structure.
 *  This can be useful for allocation and dictionary identification purposes.
 *
 *  LZ4F_getFrameInfo() can work in the following situations :
 *
 *  1) At the beginning of a new frame, before any invocation of LZ4F_decompress().
 *     It will decode header from `srcBuffer`,
 *     consuming the header and starting the decoding process.
 *
 *     Input size must be large enough to contain the full frame header.
 *     Frame header size can be known beforehand by LZ4F_headerSize().
 *     Frame header size is variable, but is guaranteed to be >= LZ4F_HEADER_SIZE_MIN bytes,
 *     and not more than <= LZ4F_HEADER_SIZE_MAX bytes.
 *     Hence, blindly providing LZ4F_HEADER_SIZE_MAX bytes or more will always work.
 *     It's allowed to provide more input data than the header size,
 *     LZ4F_getFrameInfo() will only consume the header.
 *
 *     If input size is not large enough,
 *     aka if it's smaller than header size,
 *     function will fail and return an error code.
 *
 *  2) After decoding has been started,
 *     it's possible to invoke LZ4F_getFrameInfo() anytime
 *     to extract already decoded frame parameters stored within dctx.
 *
 *     Note that, if decoding has barely started,
 *     and not yet read enough information to decode the header,
 *     LZ4F_getFrameInfo() will fail.
 *
 *  The number of bytes consumed from srcBuffer will be updated in *srcSizePtr (necessarily <= original value).
 *  LZ4F_getFrameInfo() only consumes bytes when decoding has not yet started,
 *  and when decoding the header has been successful.
 *  Decompression must then resume from (srcBuffer + *srcSizePtr).
 *
 * @return : a hint about how many srcSize bytes LZ4F_decompress() expects for next call,
 *           or an error code which can be tested using LZ4F_isError().
 *  note 1 : in case of error, dctx is not modified. Decoding operation can resume from beginning safely.
 *  note 2 : frame parameters are *copied into* an already allocated LZ4F_frameInfo_t structure.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_getFrameInfo{$ELSE}_LZ4F_getFrameInfo{$ENDIF}(dctx: PLZ4F_dctx; frameInfoPtr: PLZ4F_frameInfo_t; const srcBuffer: Pointer; srcSizePtr: PNativeUInt): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_getFrameInfo'{$IFEND};

(*! LZ4F_decompress() :
 *  Call this function repetitively to regenerate data compressed in `srcBuffer`.
 *
 *  The function requires a valid dctx state.
 *  It will read up to *srcSizePtr bytes from srcBuffer,
 *  and decompress data into dstBuffer, of capacity *dstSizePtr.
 *
 *  The nb of bytes consumed from srcBuffer will be written into *srcSizePtr (necessarily <= original value).
 *  The nb of bytes decompressed into dstBuffer will be written into *dstSizePtr (necessarily <= original value).
 *
 *  The function does not necessarily read all input bytes, so always check value in *srcSizePtr.
 *  Unconsumed source data must be presented again in subsequent invocations.
 *
 * `dstBuffer` can freely change between each consecutive function invocation.
 * `dstBuffer` content will be overwritten.
 *
 *  Note: if `LZ4F_getFrameInfo()` is called before `LZ4F_decompress()`, srcBuffer must be updated to reflect
 *  the number of bytes consumed after reading the frame header. Failure to update srcBuffer before calling
 *  `LZ4F_decompress()` will cause decompression failure or, even worse, successful but incorrect decompression.
 *  See the `LZ4F_getFrameInfo()` docs for details.
 *
 * @return : an hint of how many `srcSize` bytes LZ4F_decompress() expects for next call.
 *  Schematically, it's the size of the current (or remaining) compressed block + header of next block.
 *  Respecting the hint provides some small speed benefit, because it skips intermediate buffers.
 *  This is just a hint though, it's always possible to provide any srcSize.
 *
 *  When a frame is fully decoded, @return will be 0 (no more data expected).
 *  When provided with more bytes than necessary to decode a frame,
 *  LZ4F_decompress() will stop reading exactly at end of current frame, and @return 0.
 *
 *  If decompression failed, @return is an error code, which can be tested using LZ4F_isError().
 *  After a decompression error, the `dctx` context is not resumable.
 *  Use LZ4F_resetDecompressionContext() to return to clean state.
 *
 *  After a frame is fully decoded, dctx can be used again to decompress another frame.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_decompress{$ELSE}_LZ4F_decompress{$ENDIF}(dctx: PLZ4F_dctx; dstBuffer: Pointer; dstSizePtr: PNativeUInt; const srcBuffer: Pointer; srcSizePtr: PNativeUInt; const dOptPtr: PLZ4F_decompressOptions_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_decompress'{$IFEND};

(*! LZ4F_resetDecompressionContext() : added in v1.8.0
 *  In case of an error, the context is left in "undefined" state.
 *  In which case, it's necessary to reset it, before re-using it.
 *  This method can also be used to abruptly stop any unfinished decompression,
 *  and start a new one using same context resources. *)
procedure {$IFNDEF UNDERSCORE}LZ4F_resetDecompressionContext{$ELSE}_LZ4F_resetDecompressionContext{$ENDIF}(dctx: PLZ4F_dctx); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_resetDecompressionContext'{$IFEND};

(*! LZ4F_compressBegin_usingDict() : stable since v1.10
 *  Inits dictionary compression streaming, and writes the frame header into dstBuffer.
 * @dstCapacity must be >= LZ4F_HEADER_SIZE_MAX bytes.
 * @prefsPtr is optional : one may provide NULL as argument,
 *  however, it's the only way to provide dictID in the frame header.
 * @dictBuffer must outlive the compression session.
 * @return : number of bytes written into dstBuffer for the header,
 *           or an error code (which can be tested using LZ4F_isError())
 *  NOTE: The LZ4Frame spec allows each independent block to be compressed with the dictionary,
 *        but this entry supports a more limited scenario, where only the first block uses the dictionary.
 *        This is still useful for small data, which only need one block anyway.
 *        For larger inputs, one may be more interested in LZ4F_compressFrame_usingCDict() below.
 *)
function {$IFNDEF UNDERSCORE}LZ4F_compressBegin_usingDict{$ELSE}_LZ4F_compressBegin_usingDict{$ENDIF}(cctx: PLZ4F_cctx; dstBuffer: Pointer; dstCapacity: NativeUInt; const dictBuffer: Pointer; dictSize: NativeUInt; const prefsPtr: PLZ4F_preferences_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressBegin_usingDict'{$IFEND};

(*! LZ4F_decompress_usingDict() : stable since v1.10
 *  Same as LZ4F_decompress(), using a predefined dictionary.
 *  Dictionary is used "in place", without any preprocessing.
 **  It must remain accessible throughout the entire frame decoding. *)
function {$IFNDEF UNDERSCORE}LZ4F_decompress_usingDict{$ELSE}_LZ4F_decompress_usingDict{$ENDIF}(dctxPtr: PLZ4F_dctx; dstBuffer: Pointer; dstSizePtr: PNativeUInt; const srcBuffer: Pointer; srcSizePtr: PNativeUInt; const dict: Pointer; dictSize: NativeUInt; const decompressOptionsPtr: PLZ4F_decompressOptions_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_decompress_usingDict'{$IFEND};

(*! LZ4_createCDict() : stable since v1.10
 *  When compressing multiple messages / blocks using the same dictionary, it's recommended to initialize it just once.
 *  LZ4_createCDict() will create a digested dictionary, ready to start future compression operations without startup delay.
 *  LZ4_CDict can be created once and shared by multiple threads concurrently, since its usage is read-only.
 * @dictBuffer can be released after LZ4_CDict creation, since its content is copied within CDict. *)
function {$IFNDEF UNDERSCORE}LZ4F_createCDict{$ELSE}_LZ4F_createCDict{$ENDIF}(const dictBuffer: Pointer; dictSize: NativeUInt): PLZ4F_CDict; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_createCDict'{$IFEND};

procedure {$IFNDEF UNDERSCORE}LZ4F_freeCDict{$ELSE}_LZ4F_freeCDict{$ENDIF}(CDict: PLZ4F_CDict); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_freeCDict'{$IFEND};

(*! LZ4_compressFrame_usingCDict() : stable since v1.10
 *  Compress an entire srcBuffer into a valid LZ4 frame using a digested Dictionary.
 * @cctx must point to a context created by LZ4F_createCompressionContext().
 *  If @cdict==NULL, compress without a dictionary.
 * @dstBuffer MUST be >= LZ4F_compressFrameBound(srcSize, preferencesPtr).
 *  If this condition is not respected, function will fail (@return an errorCode).
 *  The LZ4F_preferences_t structure is optional : one may provide NULL as argument,
 *  but it's not recommended, as it's the only way to provide @dictID in the frame header.
 * @return : number of bytes written into dstBuffer.
 *           or an error code if it fails (can be tested using LZ4F_isError())
 *  Note: for larger inputs generating multiple independent blocks,
 *        this entry point uses the dictionary for each block. *)
function {$IFNDEF UNDERSCORE}LZ4F_compressFrame_usingCDict{$ELSE}_LZ4F_compressFrame_usingCDict{$ENDIF}(cctx: PLZ4F_cctx; dst: Pointer; dstCapacity: NativeUInt; const src: Pointer; srcSize: NativeUInt; const cdict: PLZ4F_CDict; const preferencesPtr: PLZ4F_preferences_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressFrame_usingCDict'{$IFEND};

(*! LZ4F_compressBegin_usingCDict() : stable since v1.10
 *  Inits streaming dictionary compression, and writes the frame header into dstBuffer.
 * @dstCapacity must be >= LZ4F_HEADER_SIZE_MAX bytes.
 * @prefsPtr is optional : one may provide NULL as argument,
 *  note however that it's the only way to insert a @dictID in the frame header.
 * @cdict must outlive the compression session.
 * @return : number of bytes written into dstBuffer for the header,
 *           or an error code, which can be tested using LZ4F_isError(). *)
function {$IFNDEF UNDERSCORE}LZ4F_compressBegin_usingCDict{$ELSE}_LZ4F_compressBegin_usingCDict{$ENDIF}(cctx: PLZ4F_cctx; dstBuffer: Pointer; dstCapacity: NativeUInt; const cdict: PLZ4F_CDict; const prefsPtr: PLZ4F_preferences_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_compressBegin_usingCDict'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4F_getErrorCode{$ELSE}_LZ4F_getErrorCode{$ENDIF}(functionResult: NativeUInt): LZ4F_errorCodes; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_getErrorCode'{$IFEND};

(*! LZ4F_getBlockSize() :
 * @return, in scalar format (size_t),
 *          the maximum block size associated with @blockSizeID,
 *          or an error code (can be tested using LZ4F_isError()) if @blockSizeID is invalid.
 **)
function {$IFNDEF UNDERSCORE}LZ4F_getBlockSize{$ELSE}_LZ4F_getBlockSize{$ENDIF}(blockSizeID: LZ4F_blockSizeID_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_getBlockSize'{$IFEND};

(*! LZ4F_uncompressedUpdate() :
 *  LZ4F_uncompressedUpdate() can be called repetitively to add data stored as uncompressed blocks.
 *  Important rule: dstCapacity MUST be large enough to store the entire source buffer as
 *  no compression is done for this operation
 *  If this condition is not respected, LZ4F_uncompressedUpdate() will fail (result is an errorCode).
 *  After an error, the state is left in a UB state, and must be re-initialized or freed.
 *  If previously a compressed block was written, buffered data is flushed first,
 *  before appending uncompressed data is continued.
 *  This operation is only supported when LZ4F_blockIndependent is used.
 * `cOptPtr` is optional : NULL can be provided, in which case all options are set to default.
 * @return : number of bytes written into `dstBuffer` (it can be zero, meaning input data was just buffered).
 *           or an error code if it fails (which can be tested using LZ4F_isError())
 *)
function {$IFNDEF UNDERSCORE}LZ4F_uncompressedUpdate{$ELSE}_LZ4F_uncompressedUpdate{$ENDIF}(cctx: PLZ4F_cctx; dstBuffer: Pointer; dstCapacity: NativeUInt; const srcBuffer: Pointer; srcSize: NativeUInt; const cOptPtr: PLZ4F_compressOptions_t): NativeUInt; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_uncompressedUpdate'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4F_createCompressionContext_advanced{$ELSE}_LZ4F_createCompressionContext_advanced{$ENDIF}(customMem: LZ4F_CustomMem; version: Cardinal): PLZ4F_cctx; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_createCompressionContext_advanced'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4F_createDecompressionContext_advanced{$ELSE}_LZ4F_createDecompressionContext_advanced{$ENDIF}(customMem: LZ4F_CustomMem; version: Cardinal): PLZ4F_dctx; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_createDecompressionContext_advanced'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4F_createCDict_advanced{$ELSE}_LZ4F_createCDict_advanced{$ENDIF}(customMem: LZ4F_CustomMem; const dictBuffer: Pointer; dictSize: NativeUInt): PLZ4F_CDict; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4F_createCDict_advanced'{$IFEND};

implementation

{$IFDEF Win64}
  {$L Win64\lz4frame.o}
{$ELSE}
  {$L Win32\lz4frame.o}
{$ENDIF}

end.
