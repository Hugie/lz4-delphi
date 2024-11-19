unit lz4d.lz4;

interface

{$WARN UNSAFE_TYPE OFF}

{$I LZ4.inc}

uses
  lz4d.Imports;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const
  LZ4_VERSION_MAJOR = 1;
  LZ4_VERSION_MINOR = 10;
  LZ4_VERSION_RELEASE = 0;
  LZ4_VERSION_NUMBER = (LZ4_VERSION_MAJOR*100*100+LZ4_VERSION_MINOR*100+LZ4_VERSION_RELEASE);

{
 * LZ4_MEMORY_USAGE :
 * Memory usage formula : N->2^N Bytes (examples : 10 -> 1KB; 12 -> 4KB ; 16 -> 64KB; 20 -> 1MB; etc.)
 * Increasing memory usage improves compression ratio
 * Reduced memory usage can improve speed, due to cache effect
 * Default value is 14, for 16KB, which nicely fits into Intel x86 L1 cache
}
  LZ4_MEMORY_USAGE_DEFAULT = 14;
  LZ4_MEMORY_USAGE = LZ4_MEMORY_USAGE_DEFAULT;
  LZ4_MEMORY_USAGE_MIN = 10;
  LZ4_MEMORY_USAGE_MAX = 20;
  LZ4_MAX_INPUT_SIZE = $7E000000;

  LZ4_HASHLOG = (LZ4_MEMORY_USAGE-2);
  LZ4_HASHTABLESIZE = (1 shl LZ4_MEMORY_USAGE);
  LZ4_HASH_SIZE_U32 = (1 shl LZ4_HASHLOG);
  LZ4_STREAM_MINSIZE = ((1 shl (LZ4_MEMORY_USAGE))+32);
  LZ4_STREAMDECODE_MINSIZE = 32;

type
  PLZ4_stream_t_internal = ^LZ4_stream_t_internal;
  LZ4_stream_t_internal = record
    hashTable: array [0..4095] of Cardinal;
    dictionary: PByte;
    dictCtx: PLZ4_stream_t_internal;
    currentOffset: Cardinal;
    tableType: Cardinal;
    dictSize: Cardinal;
  end;

  LZ4_stream_t = record
    case Integer of
      0: (minStateSize: array [0..16415] of Byte);
      1: (internal_donotuse: LZ4_stream_t_internal);
  end;
  PLZ4_stream_t = ^LZ4_stream_t;

  (*! LZ4_streamDecode_t :
   *  Never ever use below internal definitions directly !
   *  These definitions are not API/ABI safe, and may change in future versions.
   *  If you need static allocation, declare or allocate an LZ4_streamDecode_t object.
   **)
  PLZ4_streamDecode_t_internal = ^LZ4_streamDecode_t_internal;
  LZ4_streamDecode_t_internal = record
    externalDict: PByte;
    prefixEnd: PByte;
    extDictSize: NativeUInt;
    prefixSize: NativeUInt;
  end;

  LZ4_streamDecode_t = record
    case Integer of
      0: (minStateSize: array [0..31] of Byte);
      1: (internal_donotuse: LZ4_streamDecode_t_internal);
  end;
  PLZ4_streamDecode_t = ^LZ4_streamDecode_t;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function {$IFNDEF UNDERSCORE}LZ4_versionNumber {$ELSE}_LZ4_versionNumber{$ENDIF}: Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_versionNumber'{$IFEND};
function {$IFNDEF UNDERSCORE}LZ4_versionString {$ELSE}_LZ4_versionString{$ENDIF}: PAnsiChar; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_versionString'{$IFEND};

(*! LZ4_compress_default() :
 *  Compresses 'srcSize' bytes from buffer 'src'
 *  into already allocated 'dst' buffer of size 'dstCapacity'.
 *  Compression is guaranteed to succeed if 'dstCapacity' >= LZ4_compressBound(srcSize).
 *  It also runs faster, so it's a recommended setting.
 *  If the function cannot compress 'src' into a more limited 'dst' budget,
 *  compression stops *immediately*, and the function result is zero.
 *  In which case, 'dst' content is undefined (invalid).
 *      srcSize : max supported value is LZ4_MAX_INPUT_SIZE.
 *      dstCapacity : size of buffer 'dst' (which must be already allocated)
 *     @return  : the number of bytes written into buffer 'dst' (necessarily <= dstCapacity)
 *                or 0 if compression fails
 * Note : This function is protected against buffer overflow scenarios (never writes outside 'dst' buffer, nor read outside 'source' buffer).
 *)
function {$IFNDEF UNDERSCORE}LZ4_compress_default{$ELSE}_LZ4_compress_default{$ENDIF}(const ASource: Pointer; ADestination: Pointer; srcSize: Integer; dstCapacity: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_default'{$IFEND};

(*! LZ4_decompress_safe() :
 * @compressedSize : is the exact complete size of the compressed block.
 * @dstCapacity : is the size of destination buffer (which must be already allocated),
 *                presumed an upper bound of decompressed size.
 * @return : the number of bytes decompressed into destination buffer (necessarily <= dstCapacity)
 *           If destination buffer is not large enough, decoding will stop and output an error code (negative value).
 *           If the source stream is detected malformed, the function will stop decoding and return a negative result.
 * Note 1 : This function is protected against malicious data packets :
 *          it will never writes outside 'dst' buffer, nor read outside 'source' buffer,
 *          even if the compressed block is maliciously modified to order the decoder to do these actions.
 *          In such case, the decoder stops immediately, and considers the compressed block malformed.
 * Note 2 : compressedSize and dstCapacity must be provided to the function, the compressed block does not contain them.
 *          The implementation is free to send / store / derive this information in whichever way is most beneficial.
 *          If there is a need for a different format which bundles together both compressed data and its metadata, consider looking at lz4frame.h instead.
 *)
function {$IFNDEF UNDERSCORE}LZ4_decompress_safe{$ELSE}_LZ4_decompress_safe{$ENDIF}(const ASource: Pointer; ADestination: Pointer; compressedSize: Integer; dstCapacity: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_safe'{$IFEND};

(*! LZ4_compressBound() :
    Provides the maximum size that LZ4 compression may output in a "worst case" scenario (input data not compressible)
    This function is primarily useful for memory allocation purposes (destination buffer size).
    Macro LZ4_COMPRESSBOUND() is also provided for compilation-time evaluation (stack memory allocation for example).
    Note that LZ4_compress_default() compresses faster when dstCapacity is >= LZ4_compressBound(srcSize)
        inputSize  : max supported value is LZ4_MAX_INPUT_SIZE
        return : maximum output size in a "worst case" scenario
              or 0, if input size is incorrect (too large or negative)
 *)
function {$IFNDEF UNDERSCORE}LZ4_compressBound{$ELSE}_LZ4_compressBound{$ENDIF}(inputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compressBound'{$IFEND};

(*! LZ4_compress_fast() :
    Same as LZ4_compress_default(), but allows selection of "acceleration" factor.
    The larger the acceleration value, the faster the algorithm, but also the lesser the compression.
    It's a trade-off. It can be fine tuned, with each successive value providing roughly +~3% to speed.
    An acceleration value of "1" is the same as regular LZ4_compress_default()
    Values <= 0 will be replaced by LZ4_ACCELERATION_DEFAULT (currently == 1, see lz4.c).
    Values > LZ4_ACCELERATION_MAX will be replaced by LZ4_ACCELERATION_MAX (currently == 65537, see lz4.c).
 *)
function {$IFNDEF UNDERSCORE}LZ4_compress_fast{$ELSE}_LZ4_compress_fast{$ENDIF}(const ASource: Pointer; ADestination: Pointer; srcSize: Integer; dstCapacity: Integer; acceleration: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_fast'{$IFEND};

(*! LZ4_compress_fast_extState() :
 *  Same as LZ4_compress_fast(), using an externally allocated memory space for its state.
 *  Use LZ4_sizeofState() to know how much memory must be allocated,
 *  and allocate it on 8-bytes boundaries (using `malloc()` typically).
 *  Then, provide this buffer as `void* state` to compression function.
 *)
function {$IFNDEF UNDERSCORE}LZ4_sizeofState{$ELSE}_LZ4_sizeofState{$ENDIF} : Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_sizeofState'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compress_fast_extState{$ELSE}_LZ4_compress_fast_extState{$ENDIF}(state: Pointer; const ASource: Pointer; ADestination: Pointer; srcSize: Integer; dstCapacity: Integer; acceleration: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_fast_extState'{$IFEND};

(*! LZ4_compress_fast_extState_fastReset() :
 *  A variant of LZ4_compress_fast_extState().
 *
 *  Using this variant avoids an expensive initialization step.
 *  It is only safe to call if the state buffer is known to be correctly initialized already
 *  (see above comment on LZ4_resetStream_fast() for a definition of "correctly initialized").
 *  From a high level, the difference is that
 *  this function initializes the provided state with a call to something like LZ4_resetStream_fast()
 *  while LZ4_compress_fast_extState() starts with a call to LZ4_resetStream().
 *)
function {$IFNDEF UNDERSCORE}LZ4_compress_fast_extState_fastReset{$ELSE}_LZ4_compress_fast_extState_fastReset{$ENDIF}(state: Pointer; const ASource: Pointer; ADestination: Pointer; srcSize: Integer; dstCapacity: Integer; acceleration: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_fast_extState_fastReset'{$IFEND};

(*! LZ4_compress_destSize() :
 *  Reverse the logic : compresses as much data as possible from 'src' buffer
 *  into already allocated buffer 'dst', of size >= 'dstCapacity'.
 *  This function either compresses the entire 'src' content into 'dst' if it's large enough,
 *  or fill 'dst' buffer completely with as much data as possible from 'src'.
 *  note: acceleration parameter is fixed to "default".
 *
 * *srcSizePtr : in+out parameter. Initially contains size of input.
 *               Will be modified to indicate how many bytes where read from 'src' to fill 'dst'.
 *               New value is necessarily <= input value.
 * @return : Nb bytes written into 'dst' (necessarily <= dstCapacity)
 *           or 0 if compression fails.
 *
 * Note : from v1.8.2 to v1.9.1, this function had a bug (fixed in v1.9.2+):
 *        the produced compressed content could, in specific circumstances,
 *        require to be decompressed into a destination buffer larger
 *        by at least 1 byte than the content to decompress.
 *        If an application uses `LZ4_compress_destSize()`,
 *        it's highly recommended to update liblz4 to v1.9.2 or better.
 *        If this can't be done or ensured,
 *        the receiving decompression function should provide
 *        a dstCapacity which is > decompressedSize, by at least 1 byte.
 *        See https://github.com/lz4/lz4/issues/859 for details
 *)
function {$IFNDEF UNDERSCORE}LZ4_compress_destSize{$ELSE}_LZ4_compress_destSize{$ENDIF}(const ASource: Pointer; ADestination: Pointer; srcSizePtr: PInteger; targetDstSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_destSize'{$IFEND};

(*! LZ4_decompress_safe_partial() :
 *  Decompress an LZ4 compressed block, of size 'srcSize' at position 'src',
 *  into destination buffer 'dst' of size 'dstCapacity'.
 *  Up to 'targetOutputSize' bytes will be decoded.
 *  The function stops decoding on reaching this objective.
 *  This can be useful to boost performance
 *  whenever only the beginning of a block is required.
 *
 * @return : the number of bytes decoded in `dst` (necessarily <= targetOutputSize)
 *           If source stream is detected malformed, function returns a negative result.
 *
 *  Note 1 : @return can be < targetOutputSize, if compressed block contains less data.
 *
 *  Note 2 : targetOutputSize must be <= dstCapacity
 *
 *  Note 3 : this function effectively stops decoding on reaching targetOutputSize,
 *           so dstCapacity is kind of redundant.
 *           This is because in older versions of this function,
 *           decoding operation would still write complete sequences.
 *           Therefore, there was no guarantee that it would stop writing at exactly targetOutputSize,
 *           it could write more bytes, though only up to dstCapacity.
 *           Some "margin" used to be required for this operation to work properly.
 *           Thankfully, this is no longer necessary.
 *           The function nonetheless keeps the same signature, in an effort to preserve API compatibility.
 *
 *  Note 4 : If srcSize is the exact size of the block,
 *           then targetOutputSize can be any value,
 *           including larger than the block's decompressed size.
 *           The function will, at most, generate block's decompressed size.
 *
 *  Note 5 : If srcSize is _larger_ than block's compressed size,
 *           then targetOutputSize **MUST** be <= block's decompressed size.
 *           Otherwise, *silent corruption will occur*.
 *)
function {$IFNDEF UNDERSCORE}LZ4_decompress_safe_partial{$ELSE}_LZ4_decompress_safe_partial{$ENDIF}(const ASource: Pointer; ADestination: Pointer; srcSize: Integer; targetOutputSize: Integer; dstCapacity: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_safe_partial'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_createStream{$ELSE}_LZ4_createStream{$ENDIF} : PLZ4_stream_t; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_createStream'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_freeStream{$ELSE}_LZ4_freeStream{$ENDIF}(streamPtr: PLZ4_stream_t): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_freeStream'{$IFEND};

(*! LZ4_resetStream_fast() : v1.9.0+
 *  Use this to prepare an LZ4_stream_t for a new chain of dependent blocks
 *  (e.g., LZ4_compress_fast_continue()).
 *
 *  An LZ4_stream_t must be initialized once before usage.
 *  This is automatically done when created by LZ4_createStream().
 *  However, should the LZ4_stream_t be simply declared on stack (for example),
 *  it's necessary to initialize it first, using LZ4_initStream().
 *
 *  After init, start any new stream with LZ4_resetStream_fast().
 *  A same LZ4_stream_t can be re-used multiple times consecutively
 *  and compress multiple streams,
 *  provided that it starts each new stream with LZ4_resetStream_fast().
 *
 *  LZ4_resetStream_fast() is much faster than LZ4_initStream(),
 *  but is not compatible with memory regions containing garbage data.
 *
 *  Note: it's only useful to call LZ4_resetStream_fast()
 *        in the context of streaming compression.
 *        The *extState* functions perform their own resets.
 *        Invoking LZ4_resetStream_fast() before is redundant, and even counterproductive.
 *)
procedure {$IFNDEF UNDERSCORE}LZ4_resetStream_fast{$ELSE}_LZ4_resetStream_fast{$ENDIF}(streamPtr: PLZ4_stream_t); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_resetStream_fast'{$IFEND};

(*! LZ4_loadDict() :
 *  Use this function to reference a static dictionary into LZ4_stream_t.
 *  The dictionary must remain available during compression.
 *  LZ4_loadDict() triggers a reset, so any previous data will be forgotten.
 *  The same dictionary will have to be loaded on decompression side for successful decoding.
 *  Dictionary are useful for better compression of small data (KB range).
 *  While LZ4 itself accepts any input as dictionary, dictionary efficiency is also a topic.
 *  When in doubt, employ the Zstandard's Dictionary Builder.
 *  Loading a size of 0 is allowed, and is the same as reset.
 * @return : loaded dictionary size, in bytes (note: only the last 64 KB are loaded)
 *)
function {$IFNDEF UNDERSCORE}LZ4_loadDict{$ELSE}_LZ4_loadDict{$ENDIF}(streamPtr: PLZ4_stream_t; const dictionary: PByte; dictSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_loadDict'{$IFEND};

(*! LZ4_loadDictSlow() : v1.10.0+
 *  Same as LZ4_loadDict(),
 *  but uses a bit more cpu to reference the dictionary content more thoroughly.
 *  This is expected to slightly improve compression ratio.
 *  The extra-cpu cost is likely worth it if the dictionary is re-used across multiple sessions.
 * @return : loaded dictionary size, in bytes (note: only the last 64 KB are loaded)
 *)
function {$IFNDEF UNDERSCORE}LZ4_loadDictSlow{$ELSE}_LZ4_loadDictSlow{$ENDIF}(streamPtr: PLZ4_stream_t; const dictionary: PByte; dictSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_loadDictSlow'{$IFEND};

(*! LZ4_attach_dictionary() : stable since v1.10.0
 *
 *  This allows efficient re-use of a static dictionary multiple times.
 *
 *  Rather than re-loading the dictionary buffer into a working context before
 *  each compression, or copying a pre-loaded dictionary's LZ4_stream_t into a
 *  working LZ4_stream_t, this function introduces a no-copy setup mechanism,
 *  in which the working stream references @dictionaryStream in-place.
 *
 *  Several assumptions are made about the state of @dictionaryStream.
 *  Currently, only states which have been prepared by LZ4_loadDict() or
 *  LZ4_loadDictSlow() should be expected to work.
 *
 *  Alternatively, the provided @dictionaryStream may be NULL,
 *  in which case any existing dictionary stream is unset.
 *
 *  If a dictionary is provided, it replaces any pre-existing stream history.
 *  The dictionary contents are the only history that can be referenced and
 *  logically immediately precede the data compressed in the first subsequent
 *  compression call.
 *
 *  The dictionary will only remain attached to the working stream through the
 *  first compression call, at the end of which it is cleared.
 * @dictionaryStream stream (and source buffer) must remain in-place / accessible / unchanged
 *  through the completion of the compression session.
 *
 *  Note: there is no equivalent LZ4_attach_*() method on the decompression side
 *  because there is no initialization cost, hence no need to share the cost across multiple sessions.
 *  To decompress LZ4 blocks using dictionary, attached or not,
 *  just employ the regular LZ4_setStreamDecode() for streaming,
 *  or the stateless LZ4_decompress_safe_usingDict() for one-shot decompression.
 *)
procedure {$IFNDEF UNDERSCORE}LZ4_attach_dictionary{$ELSE}_LZ4_attach_dictionary{$ENDIF}(workingStream: PLZ4_stream_t; const dictionaryStream: PLZ4_stream_t); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_attach_dictionary'{$IFEND};

(*! LZ4_compress_fast_continue() :
 *  Compress 'src' content using data from previously compressed blocks, for better compression ratio.
 * 'dst' buffer must be already allocated.
 *  If dstCapacity >= LZ4_compressBound(srcSize), compression is guaranteed to succeed, and runs faster.
 *
 * @return : size of compressed block
 *           or 0 if there is an error (typically, cannot fit into 'dst').
 *
 *  Note 1 : Each invocation to LZ4_compress_fast_continue() generates a new block.
 *           Each block has precise boundaries.
 *           Each block must be decompressed separately, calling LZ4_decompress_*() with relevant metadata.
 *           It's not possible to append blocks together and expect a single invocation of LZ4_decompress_*() to decompress them together.
 *
 *  Note 2 : The previous 64KB of source data is __assumed__ to remain present, unmodified, at same address in memory !
 *
 *  Note 3 : When input is structured as a double-buffer, each buffer can have any size, including < 64 KB.
 *           Make sure that buffers are separated, by at least one byte.
 *           This construction ensures that each block only depends on previous block.
 *
 *  Note 4 : If input buffer is a ring-buffer, it can have any size, including < 64 KB.
 *
 *  Note 5 : After an error, the stream status is undefined (invalid), it can only be reset or freed.
 *)
function {$IFNDEF UNDERSCORE}LZ4_compress_fast_continue{$ELSE}_LZ4_compress_fast_continue{$ENDIF}(streamPtr: PLZ4_stream_t; const ASource: Pointer; ADestination: Pointer; srcSize: Integer; dstCapacity: Integer; acceleration: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_fast_continue'{$IFEND};

(*! LZ4_saveDict() :
 *  If last 64KB data cannot be guaranteed to remain available at its current memory location,
 *  save it into a safer place (char* safeBuffer).
 *  This is schematically equivalent to a memcpy() followed by LZ4_loadDict(),
 *  but is much faster, because LZ4_saveDict() doesn't need to rebuild tables.
 * @return : saved dictionary size in bytes (necessarily <= maxDictSize), or 0 if error.
 *)
function {$IFNDEF UNDERSCORE}LZ4_saveDict{$ELSE}_LZ4_saveDict{$ENDIF}(streamPtr: PLZ4_stream_t; safeBuffer: PByte; maxDictSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_saveDict'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_createStreamDecode{$ELSE}_LZ4_createStreamDecode{$ENDIF} : PLZ4_streamDecode_t; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_createStreamDecode'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_freeStreamDecode{$ELSE}_LZ4_freeStreamDecode{$ENDIF}(LZ4_stream: PLZ4_streamDecode_t): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_freeStreamDecode'{$IFEND};

(*! LZ4_setStreamDecode() :
 *  An LZ4_streamDecode_t context can be allocated once and re-used multiple times.
 *  Use this function to start decompression of a new stream of blocks.
 *  A dictionary can optionally be set. Use NULL or size 0 for a reset order.
 *  Dictionary is presumed stable : it must remain accessible and unmodified during next decompression.
 * @return : 1 if OK, 0 if error
 *)
function {$IFNDEF UNDERSCORE}LZ4_setStreamDecode{$ELSE}_LZ4_setStreamDecode{$ENDIF}(LZ4_streamDecode: PLZ4_streamDecode_t; const dictionary: PByte; dictSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_setStreamDecode'{$IFEND};

(*! LZ4_decoderRingBufferSize() : v1.8.2+
 *  Note : in a ring buffer scenario (optional),
 *  blocks are presumed decompressed next to each other
 *  up to the moment there is not enough remaining space for next block (remainingSize < maxBlockSize),
 *  at which stage it resumes from beginning of ring buffer.
 *  When setting such a ring buffer for streaming decompression,
 *  provides the minimum size of this ring buffer
 *  to be compatible with any source respecting maxBlockSize condition.
 * @return : minimum ring buffer size,
 *           or 0 if there is an error (invalid maxBlockSize).
 *)
function {$IFNDEF UNDERSCORE}LZ4_decoderRingBufferSize{$ELSE}_LZ4_decoderRingBufferSize{$ENDIF}(maxBlockSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decoderRingBufferSize'{$IFEND};

(*! LZ4_decompress_safe_continue() :
 *  This decoding function allows decompression of consecutive blocks in "streaming" mode.
 *  The difference with the usual independent blocks is that
 *  new blocks are allowed to find references into former blocks.
 *  A block is an unsplittable entity, and must be presented entirely to the decompression function.
 *  LZ4_decompress_safe_continue() only accepts one block at a time.
 *  It's modeled after `LZ4_decompress_safe()` and behaves similarly.
 *
 * @LZ4_streamDecode : decompression state, tracking the position in memory of past data
 * @compressedSize : exact complete size of one compressed block.
 * @dstCapacity : size of destination buffer (which must be already allocated),
 *                must be an upper bound of decompressed size.
 * @return : number of bytes decompressed into destination buffer (necessarily <= dstCapacity)
 *           If destination buffer is not large enough, decoding will stop and output an error code (negative value).
 *           If the source stream is detected malformed, the function will stop decoding and return a negative result.
 *
 *  The last 64KB of previously decoded data *must* remain available and unmodified
 *  at the memory position where they were previously decoded.
 *  If less than 64KB of data has been decoded, all the data must be present.
 *
 *  Special : if decompression side sets a ring buffer, it must respect one of the following conditions :
 *  - Decompression buffer size is _at least_ LZ4_decoderRingBufferSize(maxBlockSize).
 *    maxBlockSize is the maximum size of any single block. It can have any value > 16 bytes.
 *    In which case, encoding and decoding buffers do not need to be synchronized.
 *    Actually, data can be produced by any source compliant with LZ4 format specification, and respecting maxBlockSize.
 *  - Synchronized mode :
 *    Decompression buffer size is _exactly_ the same as compression buffer size,
 *    and follows exactly same update rule (block boundaries at same positions),
 *    and decoding function is provided with exact decompressed size of each block (exception for last block of the stream),
 *    _then_ decoding & encoding ring buffer can have any size, including small ones ( < 64 KB).
 *  - Decompression buffer is larger than encoding buffer, by a minimum of maxBlockSize more bytes.
 *    In which case, encoding and decoding buffers do not need to be synchronized,
 *    and encoding ring buffer can have any size, including small ones ( < 64 KB).
 *
 *  Whenever these conditions are not possible,
 *  save the last 64KB of decoded data into a safe buffer where it can't be modified during decompression,
 *  then indicate where this data is saved using LZ4_setStreamDecode(), before decompressing next block.
 *)
function {$IFNDEF UNDERSCORE}LZ4_decompress_safe_continue{$ELSE}_LZ4_decompress_safe_continue{$ENDIF}(LZ4_streamDecode: PLZ4_streamDecode_t; const ASource: Pointer; ADestination: Pointer; srcSize: Integer; dstCapacity: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_safe_continue'{$IFEND};

(*! LZ4_decompress_safe_usingDict() :
 *  Works the same as
 *  a combination of LZ4_setStreamDecode() followed by LZ4_decompress_safe_continue()
 *  However, it's stateless: it doesn't need any LZ4_streamDecode_t state.
 *  Dictionary is presumed stable : it must remain accessible and unmodified during decompression.
 *  Performance tip : Decompression speed can be substantially increased
 *                    when dst == dictStart + dictSize.
 *)
function {$IFNDEF UNDERSCORE}LZ4_decompress_safe_usingDict{$ELSE}_LZ4_decompress_safe_usingDict{$ENDIF}(const ASource: Pointer; ADestination: Pointer; srcSize: Integer; dstCapacity: Integer; const dictStart: PByte; dictSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_safe_usingDict'{$IFEND};

(*! LZ4_decompress_safe_partial_usingDict() :
 *  Behaves the same as LZ4_decompress_safe_partial()
 *  with the added ability to specify a memory segment for past data.
 *  Performance tip : Decompression speed can be substantially increased
 *                    when dst == dictStart + dictSize.
 *)
function {$IFNDEF UNDERSCORE}LZ4_decompress_safe_partial_usingDict{$ELSE}_LZ4_decompress_safe_partial_usingDict{$ENDIF}(const ASource: Pointer; ADestination: Pointer; compressedSize: Integer; targetOutputSize: Integer; maxOutputSize: Integer; const dictStart: PByte; dictSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_safe_partial_usingDict'{$IFEND};

(*! LZ4_initStream() : v1.9.0+
 *  An LZ4_stream_t structure must be initialized at least once.
 *  This is automatically done when invoking LZ4_createStream(),
 *  but it's not when the structure is simply declared on stack (for example).
 *
 *  Use LZ4_initStream() to properly initialize a newly declared LZ4_stream_t.
 *  It can also initialize any arbitrary buffer of sufficient size,
 *  and will @return a pointer of proper type upon initialization.
 *
 *  Note : initialization fails if size and alignment conditions are not respected.
 *         In which case, the function will @return NULL.
 *  Note2: An LZ4_stream_t structure guarantees correct alignment and size.
 *  Note3: Before v1.9.0, use LZ4_resetStream() instead
 **)
function {$IFNDEF UNDERSCORE}LZ4_initStream{$ELSE}_LZ4_initStream{$ENDIF}(stateBuffer: Pointer; size: NativeUInt): PLZ4_stream_t; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_initStream'{$IFEND};

(*! Obsolete compression functions (since v1.7.3) *)
function {$IFNDEF UNDERSCORE}LZ4_compress{$ELSE}_LZ4_compress{$ENDIF}(const ASource: Pointer; ADestination: Pointer; srcSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compress_limitedOutput{$ELSE}_LZ4_compress_limitedOutput{$ENDIF}(const ASource: Pointer; ADestination: Pointer; srcSize: Integer; maxOutputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_limitedOutput'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compress_withState{$ELSE}_LZ4_compress_withState{$ENDIF}(state: Pointer; const ASource: Pointer; ADestination: Pointer; inputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_withState'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compress_limitedOutput_withState{$ELSE}_LZ4_compress_limitedOutput_withState{$ENDIF}(state: Pointer; const ASource: Pointer; ADestination: Pointer; inputSize: Integer; maxOutputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_limitedOutput_withState'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compress_continue{$ELSE}_LZ4_compress_continue{$ENDIF}(LZ4_streamPtr: PLZ4_stream_t; const ASource: Pointer; ADestination: Pointer; inputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_continue'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_compress_limitedOutput_continue{$ELSE}_LZ4_compress_limitedOutput_continue{$ENDIF}(LZ4_streamPtr: PLZ4_stream_t; const ASource: Pointer; ADestination: Pointer; inputSize: Integer; maxOutputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_compress_limitedOutput_continue'{$IFEND};

(*! Obsolete decompression functions (since v1.8.0) *)
function {$IFNDEF UNDERSCORE}LZ4_uncompress{$ELSE}_LZ4_uncompress{$ENDIF}(const ASource: Pointer; ADestination: Pointer; outputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_uncompress'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_uncompress_unknownOutputSize{$ELSE}_LZ4_uncompress_unknownOutputSize{$ENDIF}(const ASource: Pointer; ADestination: Pointer; isize: Integer; maxOutputSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_uncompress_unknownOutputSize'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_create{$ELSE}_LZ4_create{$ENDIF}(inputBuffer: PByte): Pointer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_create'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_sizeofStreamState{$ELSE}_LZ4_sizeofStreamState{$ENDIF} : Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_sizeofStreamState'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_resetStreamState{$ELSE}_LZ4_resetStreamState{$ENDIF}(state: Pointer; inputBuffer: PByte): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_resetStreamState'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_slideInputBuffer{$ELSE}_LZ4_slideInputBuffer{$ENDIF}(state: Pointer): PByte; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_slideInputBuffer'{$IFEND};

(*! Obsolete streaming decoding functions (since v1.7.0) *)
function {$IFNDEF UNDERSCORE}LZ4_decompress_safe_withPrefix64k{$ELSE}_LZ4_decompress_safe_withPrefix64k{$ENDIF}(const ASource: Pointer; ADestination: Pointer; compressedSize: Integer; maxDstSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_safe_withPrefix64k'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_decompress_fast_withPrefix64k{$ELSE}_LZ4_decompress_fast_withPrefix64k{$ENDIF}(const ASource: Pointer; ADestination: Pointer; originalSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_fast_withPrefix64k'{$IFEND};

(*! Obsolete LZ4_decompress_fast variants (since v1.9.0) :
 *  These functions used to be faster than LZ4_decompress_safe(),
 *  but this is no longer the case. They are now slower.
 *  This is because LZ4_decompress_fast() doesn't know the input size,
 *  and therefore must progress more cautiously into the input buffer to not read beyond the end of block.
 *  On top of that `LZ4_decompress_fast()` is not protected vs malformed or malicious inputs, making it a security liability.
 *  As a consequence, LZ4_decompress_fast() is strongly discouraged, and deprecated.
 *
 *  The last remaining LZ4_decompress_fast() specificity is that
 *  it can decompress a block without knowing its compressed size.
 *  Such functionality can be achieved in a more secure manner
 *  by employing LZ4_decompress_safe_partial().
 *
 *  Parameters:
 *  originalSize : is the uncompressed size to regenerate.
 *                 `dst` must be already allocated, its size must be >= 'originalSize' bytes.
 * @return : number of bytes read from source buffer (== compressed size).
 *           The function expects to finish at block's end exactly.
 *           If the source stream is detected malformed, the function stops decoding and returns a negative result.
 *  note : LZ4_decompress_fast*() requires originalSize. Thanks to this information, it never writes past the output buffer.
 *         However, since it doesn't know its 'src' size, it may read an unknown amount of input, past input buffer bounds.
 *         Also, since match offsets are not validated, match reads from 'src' may underflow too.
 *         These issues never happen if input (compressed) data is correct.
 *         But they may happen if input data is invalid (error or intentional tampering).
 *         As a consequence, use these functions in trusted environments with trusted data **only**.
 *)
function {$IFNDEF UNDERSCORE}LZ4_decompress_fast{$ELSE}_LZ4_decompress_fast{$ENDIF}(const ASource: Pointer; ADestination: Pointer; originalSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_fast'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_decompress_fast_continue{$ELSE}_LZ4_decompress_fast_continue{$ENDIF}(LZ4_streamDecode: PLZ4_streamDecode_t; const ASource: Pointer; ADestination: Pointer; originalSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_fast_continue'{$IFEND};

function {$IFNDEF UNDERSCORE}LZ4_decompress_fast_usingDict{$ELSE}_LZ4_decompress_fast_usingDict{$ENDIF}(const ASource: Pointer; ADestination: Pointer; originalSize: Integer; const dictStart: PByte; dictSize: Integer): Integer; cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_decompress_fast_usingDict'{$IFEND};

(*! LZ4_resetStream() :
 *  An LZ4_stream_t structure must be initialized at least once.
 *  This is done with LZ4_initStream(), or LZ4_resetStream().
 *  Consider switching to LZ4_initStream(),
 *  invoking LZ4_resetStream() will trigger deprecation warnings in the future.
 *)
procedure {$IFNDEF UNDERSCORE}LZ4_resetStream{$ELSE}_LZ4_resetStream{$ENDIF}(streamPtr: PLZ4_stream_t); cdecl; external {$IF CompilerVersion > 22}name _PU + 'LZ4_resetStream'{$IFEND};

implementation

{$IFDEF Win64}
  {$L Win64\lz4.o}
{$ELSE}
  {$L Win32\lz4.o}
{$ENDIF}

end.
