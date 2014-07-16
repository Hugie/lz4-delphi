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

unit lz4d.lz4;

{$I lz4d.defines.inc}

interface

// bind necessary object files

// * MinGW * //
{$IfDef MinGW_LIB}
  {$L lib/win32_mingw/lz4.o}
  {$L lib/win32_mingw/lz4hc.o}
{$Else}

// * Visual Studio * //
  {$IfDef VS_LIB}
    {$L lib/win32_vs/lz4.obj}
    {$L lib/win32_vs/lz4hc.obj}
  {$EndIf}

{$EndIf}

/// Linking lz4 object files and adding dependencies
/// - linking the object files produces additional dependencies
///    which would be usaly provided by the object file linker
///  - see dependency units for more informations

uses
{$IfDef ResolveMissingDependencies}
  lz4d.dependencies;
{$Else}
  ;
{$Endif}



///**************************************
///Version
///**************************************/
///
///
const LZ4_VERSION_MAJOR   = 1; // for major interface/format changes
const LZ4_VERSION_MINOR   = 2; // for minor interface/format changes
const LZ4_VERSION_RELEASE = 0; // for tweaks, bug-fixes, or development


///**************************************
//Tuning parameter
//**************************************/
///*
//* LZ4_MEMORY_USAGE :
//* Memory usage formula : N->2^N Bytes (examples : 10 -> 1KB; 12 -> 4KB ; 16 -> 64KB; 20 -> 1MB; etc.)
//* Increasing memory usage improves compression ratio
//* Reduced memory usage can improve speed, due to cache effect
//* Default value is 14, for 16KB, which nicely fits into Intel x86 L1 cache
//*/

/// * DO NOT CHANGE - binary .o files are bound to this * ///
const LZ4_MEMORY_USAGE = 14;


///**************************************
//Simple Functions
//**************************************/

function LZ4_compress        (const ASource: Pointer; ADestination: Pointer; AInputSize: Integer): Integer;                     cdecl; external name '_LZ4_compress';
function LZ4_decompress_safe (const ASource: Pointer; ADestination: Pointer; ACompressedSize,AMaxOutputSize: Integer): Integer; cdecl; external name '_LZ4_decompress_safe';

///*
//LZ4_compress() :
//Compresses 'inputSize' bytes from 'source' into 'dest'.
//Destination buffer must be already allocated,
//and must be sized to handle worst cases situations (input data not compressible)
//Worst case size evaluation is provided by function LZ4_compressBound()
//inputSize : Max supported value is LZ4_MAX_INPUT_VALUE
//return : the number of bytes written in buffer dest
//or 0 if the compression fails
//
//LZ4_decompress_safe() :
//compressedSize : is obviously the source size
//maxOutputSize : is the size of the destination buffer, which must be already allocated.
//return : the number of bytes decoded in the destination buffer (necessarily <= maxOutputSize)
//If the destination buffer is not large enough, decoding will stop and output an error code (<0).
//If the source stream is detected malformed, the function will stop decoding and return a negative result.
//This function is protected against buffer overflow exploits :
//it never writes outside of output buffer, and never reads outside of input buffer.
//Therefore, it is protected against malicious data packets.
//*/

///*
//Note :
//Should you prefer to explicitly allocate compression-table memory using your own allocation method,
//use the streaming functions provided below, simply reset the memory area between each call to LZ4_compress_continue()
//*/


///**************************************
//Advanced Functions
//**************************************/
//const LZ4_MAX_INPUT_SIZE = $7E000000; // /* 2 113 929 216 bytes */
//const LZ4_COMPRESSBOUND(isize) ((unsigned int)(isize) > (unsigned int)LZ4_MAX_INPUT_SIZE ? 0 : (isize) + ((isize)/255) + 16)


///*
//LZ4_compressBound() :
//Provides the maximum size that LZ4 may output in a "worst case" scenario (input data not compressible)
//primarily useful for memory allocation of output buffer.
//macro is also provided when result needs to be evaluated at compilation (such as stack memory allocation).
//
//isize : is the input size. Max supported value is LZ4_MAX_INPUT_SIZE
//return : maximum output size in a "worst case" scenario
//or 0, if input size is too large ( > LZ4_MAX_INPUT_SIZE)
//*/

function LZ4_compressBound(ASize: Integer): Integer; cdecl; external name '_LZ4_compressBound';

//
//
///*
//LZ4_compress_limitedOutput() :
//Compress 'inputSize' bytes from 'source' into an output buffer 'dest' of maximum size 'maxOutputSize'.
//If it cannot achieve it, compression will stop, and result of the function will be zero.
//This function never writes outside of provided output buffer.
//
//inputSize : Max supported value is LZ4_MAX_INPUT_VALUE
//maxOutputSize : is the size of the destination buffer (which must be already allocated)
//return : the number of bytes written in buffer 'dest'
//or 0 if the compression fails
//*/

function LZ4_compress_limitedOutput (const ASource: Pointer; ADestination: Pointer; AInputSize, AMaxOutputSize: Integer): Integer; cdecl; external name '_LZ4_compress_limitedOutput';

///*
//LZ4_decompress_fast() :
//originalSize : is the original and therefore uncompressed size
//return : the number of bytes read from the source buffer (in other words, the compressed size)
//If the source stream is malformed, the function will stop decoding and return a negative result.
//Destination buffer must be already allocated. Its size must be a minimum of 'originalSize' bytes.
//note : This function is a bit faster than LZ4_decompress_safe()
//It provides fast decompression and fully respect memory boundaries for properly formed compressed data.
//It does not provide full protection against intentionnally modified data stream.
//Use this function in a trusted environment (data to decode comes from a trusted source).
//*/
function LZ4_decompress_fast (const ASource: Pointer; ADestination: Pointer; AOriginalSize: Integer): Integer; cdecl; external name '_LZ4_decompress_fast';


///*
//LZ4_decompress_safe_partial() :
//This function decompress a compressed block of size 'compressedSize' at position 'source'
//into output buffer 'dest' of size 'maxOutputSize'.
//The function tries to stop decompressing operation as soon as 'targetOutputSize' has been reached,
//reducing decompression time.
//return : the number of bytes decoded in the destination buffer (necessarily <= maxOutputSize)
//Note : this number can be < 'targetOutputSize' should the compressed block to decode be smaller.
//Always control how many bytes were decoded.
//If the source stream is detected malformed, the function will stop decoding and return a negative result.
//This function never writes outside of output buffer, and never reads outside of input buffer. It is therefore protected against malicious data packets
//*/

function LZ4_decompress_safe_partial (const ASource: Pointer; ADestination: Pointer; ACompressedSize, ATargetOutputSize, AMaxOutputSize: Integer): Integer; cdecl; external name '_LZ4_decompress_safe_partial';

///***********************************************
//Experimental Streaming Compression Functions
//***********************************************/
//
const LZ4_STREAMSIZE_U32 = ((1 shl (LZ4_MEMORY_USAGE-2)) + 8);
const LZ4_STREAMSIZE     = (LZ4_STREAMSIZE_U32 * sizeof(Cardinal));

///*
//* LZ4_stream_t
//* information structure to track an LZ4 stream.
//* important : set this structure content to zero before first use !
//*/

type LZ4_stream_t = record
    Values: Array[0..LZ4_STREAMSIZE_U32-1] of Cardinal;
  end;

///*
//* If you prefer dynamic allocation methods,
//* LZ4_createStream
//* provides a pointer (void*) towards an initialized LZ4_stream_t structure.
//* LZ4_free just frees it.
//*/
function LZ4_createStream(): Pointer;             cdecl; external name '_LZ4_createStream';
function LZ4_free(ALZ4_Stream: Pointer): Integer; cdecl; external name '_LZ4_free';

///*
//* LZ4_loadDict
//* Use this function to load a static dictionary into LZ4_stream.
//* Any previous data will be forgotten, only 'dictionary' will remain in memory.
//* Loading a size of 0 is allowed (same effect as init).
//* Return : 1 if OK, 0 if error
//*/
function LZ4_loadDict(ALZ4_Stream: Pointer; const ADictionary: Pointer; ADictSize: Integer): Integer; cdecl; external name '_LZ4_loadDict';

///*
//* LZ4_compress_continue
//* Compress data block 'source', using blocks compressed before as dictionary to improve compression ratio
//* Previous data blocks are assumed to still be present at their previous location.
//*/
function LZ4_compress_continue(ALZ4_Stream: Pointer; const ASource: Pointer; ADestination: Pointer; AInputSize: Integer): Integer; cdecl; external name '_LZ4_compress_continue';

///*
//* LZ4_compress_limitedOutput_continue
//* Same as before, but also specify a maximum target compressed size (maxOutputSize)
//* If objective cannot be met, compression exits, and returns a zero.
//*/
function LZ4_compress_limitedOutput_continue(ALZ4_Stream: Pointer; const ASource: Pointer; ADestination: Pointer; AInputSize, AMaxOutputSize: Integer): Integer; cdecl; external name '_LZ4_compress_limitedOutput_continue';

///*
//* LZ4_saveDict
//* If previously compressed data block is not guaranteed to remain at its previous memory location
//* save it into a safe place (char* safeBuffer)
//* Note : you don't need to call LZ4_loadDict() afterwards,
//* dictionary is immediately usable, you can therefore call again LZ4_compress_continue()
//* Return : 1 if OK, 0 if error
//* Note : any dictSize > 64 KB will be interpreted as 64KB.
//*/
function LZ4_saveDict(ALZ4_stream: Pointer; ASafeBuffer: Pointer; ADictSize: Integer): Integer; cdecl; external name '_LZ4_saveDict';

///************************************************
//Experimental Streaming Decompression Functions
//************************************************/

const LZ4_STREAMDECODESIZE_U32 = 4;
const LZ4_STREAMDECODESIZE = (LZ4_STREAMDECODESIZE_U32 * sizeof(Cardinal));

///*
//* LZ4_streamDecode_t
//* information structure to track an LZ4 stream.
//* important : set this structure content to zero before first use !
//*/
type LZ4_streamDecode_t = record
    Values: Array[0..LZ4_STREAMDECODESIZE_U32-1] of Cardinal;
  end;

///*
//* If you prefer dynamic allocation methods,
//* LZ4_createStreamDecode()
//* provides a pointer (void*) towards an initialized LZ4_streamDecode_t structure.
//* LZ4_free just frees it.
//*/

function LZ4_createStreamDecode(): Pointer;       cdecl; external name '_LZ4_createStreamDecode';

//int LZ4_free (void* LZ4_stream); /* yes, it's the same one as for compression */
//function LZ4_free(ALZ4_Stream: Pointer): Integer; cdecl; external name '_LZ4_free';


//*_continue() :
//These decoding functions allow decompression of multiple blocks in "streaming" mode.
//Previously decoded blocks must still be available at the memory position where they were decoded.
//If it's not possible, save the relevant part of decoded data into a safe buffer,
//and indicate where it stands using LZ4_setDictDecode()
//*/

function LZ4_decompress_safe_continue (ALZ4_streamDecode: Pointer; const ASource: Pointer; ADestination: Pointer; ACompressedSize, AMaxOutputSize: Integer): Integer; cdecl; external name '_LZ4_decompress_safe_continue';
function LZ4_decompress_fast_continue (ALZ4_streamDecode: Pointer; const ASource: Pointer; ADestination: Pointer; AOriginalSize: Integer): Integer;                   cdecl; external name '_LZ4_decompress_fast_continue';

///*
//* LZ4_setDictDecode
//* Use this function to instruct where to find the dictionary.
//* This function can be used to specify a static dictionary,
//* or to instruct where to find some previously decoded data saved into a different memory space.
//* Setting a size of 0 is allowed (same effect as no dictionary).
//* Return : 1 if OK, 0 if error
//*/
function LZ4_setDictDecode (ALZ4_streamDecode: Pointer; const ADictionary: Pointer; ADictSize: Pointer): Integer; cdecl; external name '_LZ4_setDictDecode';

///*
//Advanced decoding functions :
//*_usingDict() :
//These decoding functions work the same as
//a combination of LZ4_setDictDecode() followed by LZ4_decompress_x_continue()
//all together into a single function call.
//It doesn't use nor update an LZ4_streamDecode_t structure.
//*/


function LZ4_decompress_safe_usingDict (const ASource: Pointer; ADestination: Pointer; ACompressedSize, AMaxOutputSize: Integer; const ADictStart: Pointer; ADictSize: Integer): Integer; cdecl; external name '_LZ4_decompress_safe_usingDict';
function LZ4_decompress_fast_usingDict (const ASource: Pointer; ADestination: Pointer; AOriginalSize: Integer; const ADictStart: Pointer; ADictSize: Integer): Integer; cdecl; external name '_LZ4_decompress_fast_usingDict';

///**************************************
//Obsolete Functions
//**************************************/

//Obsolete functions are not bound since they are obsolete
// - if you need them: feel free and write a patch

///*
//Obsolete decompression functions
//These function names are deprecated and should no longer be used.
//They are only provided here for compatibility with older user programs.
//- LZ4_uncompress is the same as LZ4_decompress_fast
//- LZ4_uncompress_unknownOutputSize is the same as LZ4_decompress_safe
//*/
//int LZ4_uncompress (const char* source, char* dest, int outputSize);
//int LZ4_uncompress_unknownOutputSize (const char* source, char* dest, int isize, int maxOutputSize);
//
///* Obsolete functions for externally allocated state; use streaming interface instead */
//int LZ4_sizeofState(void);
//int LZ4_compress_withState (void* state, const char* source, char* dest, int inputSize);
//int LZ4_compress_limitedOutput_withState (void* state, const char* source, char* dest, int inputSize, int maxOutputSize);
//
///* Obsolete streaming functions; use new streaming interface whenever possible */
//void* LZ4_create (const char* inputBuffer);
//int LZ4_sizeofStreamState(void);
//int LZ4_resetStreamState(void* state, const char* inputBuffer);
//char* LZ4_slideInputBuffer (void* state);
//
///* Obsolete streaming decoding functions */
//int LZ4_decompress_safe_withPrefix64k (const char* source, char* dest, int compressedSize, int maxOutputSize);
//int LZ4_decompress_fast_withPrefix64k (const char* source, char* dest, int originalSize);
//
//
//#if defined (__cplusplus)
//}
//#endif



implementation

end.
