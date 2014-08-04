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

{
  17.07.14
  Version 1.1 - bugfix on calloc implementation. If lz4 with Heapmode=1 is used, lib crashed
              - update lz4 to r119 due to a win32 related security fix

  16.07.14
  Version 1.0 - Initial release
}

unit lz4d;

interface

uses
  System.Classes;


type
  //Wrapped functions for easier usage
  TLZ4 = class
  public
    /// Stream block size is the data chunk size used for each compression step/block
    ///  User friendly version
    type TStreamBlockSize = ( sbs64K, sbs256K, sbs1MB, sbs4MB );


    /// * memory function * ///
    ///  - data needs to be given in full as memory pointer

    //calculate the maximum worst case output size, if the data is not compressible
    // - maximum of $7FFFFFFF Bytes should not be exceeded - returns 0 on that case
    class function CompressionBound( const ASourceSize: Int64 ): Int64;


    //classic raw encoding function
    // - returns encoded byte size
    // - returns 0 on errors
    class function Encode( const ASourcePtr, ATargetPtr: PByte; const ASourceSize, ATargetSize: Int64 ): Int64;
    //classic raw decoding function
    // - returns decoded byte size
    // - target size = decoded data size
    // - returns negative values as error codes on failure
    class function Decode( const ASourcePtr, ATargetPtr: PByte; const ASourceSize, ATargetSize: Int64 ): Int64;

    /// * stream function * ///
    ///  - data will be read and written from/to streams, only a part will be held in memory

    //stream encoding
    // - returns encoded byte size
    // - throws error if input is invalid or output size is too small
    // - reads from stream from current position until end of stream
    class function Stream_Encode( const ASourceStream, ATargetStream: TStream; ABlockSize: TStreamBlockSize = sbs4MB; AUseHash: Boolean = True ): Int64; overload;

    //stream encoding in memory
    class function Stream_Encode( const ASource, ATarget: PByte; const ASourceSize, ATargetSize: Int64; ABlockSize: TStreamBlockSize = sbs4MB; AUseHash: Boolean = True ): Int64; overload;

    //stream decoding
    // - returns decoded byte size
    // - throws error if input is invalid or output size is too small
    // - reads from stream from current position until lz4_stream structure has ended or throws an error if stream finishes too early
    class function Stream_Decode( const ASourceStream, ATargetStream: TStream ): Int64; overload;

    //stream decoding in memory
    class function Stream_Decode( const ASource, ATarget: PByte; const ASourceSize, ATargetSize: Int64 ): Int64; overload;

  end;

implementation

uses
  System.SysUtils,
  lz4d.lz4,
  lz4d.lz4s,
  xxHash;

const
  CDictSize     = 64 * 1024; //64 kb max dict
  CCacheLine    = 64; //try to allocate cache line optimized data blocks
  CHeaderSize   = 7;  //default header - header varies usualy between 7-15 bytes
  CBlockHeader  = 4;
  CFooterSize   = 4;  //includes the stream hash checksum

{ TLZ4 }

class function TLZ4.CompressionBound(const ASourceSize: Int64): Int64;
begin
  Result := LZ4_compressBound( ASourceSize );
end;

class function TLZ4.Encode(
  const ASourcePtr,
        ATargetPtr:   PByte;
  const ASourceSize,
        ATargetSize:  Int64)
  : Int64;
begin
  Result := LZ4_compress( ASourcePtr, ATargetPtr, ASourceSize );
end;

class function TLZ4.Decode(
  const ASourcePtr,
        ATargetPtr:   PByte;
  const ASourceSize,
        ATargetSize:  Int64)
  : Int64;
var
  LResult: Integer;
begin
  Result  := LZ4_decompress_safe( ASourcePtr, ATargetPtr, ASourceSize, ATargetSize );

// decompress_fast returns the amount of READ bytes - not the output size
//  LResult := LZ4_decompress_fast( ASourcePtr, ATargetPtr, ATargetSize );
//  Result  := ATargetSize;
end;


class function TLZ4.Stream_Encode(
  const ASourceStream,
        ATargetStream:  TStream;
        ABlockSize:     TStreamBlockSize;
        AUseHash:       Boolean )
  : Int64;
var
  //temp mapping variable for correct block size
  LBlockID:   TLZ4BlockSize;
  //stream data storage
  LSD:        TLZ4StreamDescriptor;
  //bytes read from source
  LRead:      Integer;
  //bytes available for writing
  LBytes:     Integer;

  //ring buffer for input data
  LDict:      PByte;
  LBlock:     PByte;
  LBlockSize: Cardinal;

  //temp output data
  LChunk:     PByte;
  LChunkSize: Cardinal;
begin
  // * Prepare Encoding * //
  Result := 0;

  //map block size
  case ABlockSize of
    sbs64K:   LBlockID := TLZ4BlockSize.bs_4;
    sbs256K:  LBlockID := TLZ4BlockSize.bs_5;
    sbs1MB:   LBlockID := TLZ4BlockSize.bs_6;
    sbs4MB:   LBlockID := TLZ4BlockSize.bs_7;
    else      LBlockID := TLZ4BlockSize.bs_7;
  end;

  try
    LRead := 0;
    //allocate (heap - slow) temp encoding data buffer
    // - block (ring) data is input data
    LBlockSize  := lz4s_size_block_max( LBlockID );
    // - chunk data is output data
    LChunkSize  := lz4s_size_stream_block_max( LBlockID );

    //allocate dictionary
    GetMem( LDict,  CDictSize );
    //allocate input data
    GetMem( LBlock, LBlockSize );

    //LBlocks temp source data field
    GetMem( LChunk, LChunkSize);

    // * Start Encoding * //

    //create the basis stream descriptor
    if (AUseHash) then
      LSD := lz4s_Encode_CreateDescriptor( CLZ4S_Enc_Default, Byte(LBlockID) )
    else
      LSD := lz4s_Encode_CreateDescriptor( CLZ4S_Enc_NoChecksum, Byte(LBlockID) );

    //Try to encode the header
    LBytes  := lz4s_Encode_Header( LSD, LChunk, LChunkSize );

    //write data to stream
    ATargetStream.Write( LChunk^, LBytes );
    Inc(Result, LBytes);

    //process blocks of data until no data is left
    while (LBytes > 0) do
    begin
      //read next data block
      // - bytes available may be < then LBlockSize
      LRead := ASourceStream.Read( LBlock^, LBlockSize );

      //no bytes given - we are done
      if (LRead <= 0) then break;

      //encode next block
      LBytes := lz4s_Encode_Continue( LSD, LBlock, LChunk, LRead, LChunkSize);

      //write data to stream
      ATargetStream.Write( LChunk^, LBytes );
      Inc(Result, LBytes);

      //save dictionary - and store location pointer of dict inside stream struct
      LZ4_saveDict( LSD.StreamData, LDict, CDictSize);
    end;

    //write footer
    LBytes := lz4s_Encode_Footer( LSD, LChunk, LChunkSize );

    //write data to stream
    ATargetStream.Write( LChunk^, LBytes );
    Inc(Result, LBytes);

  finally
    //cleanup
    lz4s_FreeDescriptor( LSD );
    FreeMem( LDict );
    FreeMem( LBlock );
    FreeMem( LChunk );
  end;
end;

class function TLZ4.Stream_Decode(
  const ASourceStream,
        ATargetStream: TStream)
  : Int64;
var
  //stream data storage
  LSD:          TLZ4StreamDescriptor;
  //Header buffer
  LHeader:      array[0..CCacheLine-1] of Byte;
  //bytes available for writing
  LBytes:       Integer;
  //buffer for encoded source data
  LBuffer:      PByte;
  LBufferSize:  Cardinal;
  //decoded data
  LBlock:       PByte;
  LBlockSize:   Cardinal;
  //overflow - amount of stream bytes still available, e.g. already next block data
  LOverflow:    Cardinal;
  LChunkSize:   Cardinal;
begin
  Result := 0;
  try
    // * Prepare Decoding * //

    //allocate (heap - slow) temp encoding data buffer

    //first, try to parse the header - extract block size from it
    LSD := lz4s_Decode_CreateDescriptor();

    //header size is at least 7 bytes - read first chunk
    LBytes := ASourceStream.Read( LHeader, CHeaderSize );

    //check for a full header
    if (LBytes <> CHeaderSize) then
      raise Exception.Create('LZ4S::Stream_Decode: Corrupt LZ4S Stream.');

    //Try to encode the header - calc how much bytes are left of buffer
    lz4s_Decode_Stream_Header( LSD, @LHeader, LBytes );

    // - allocate once and share the data - uses memory locality and only one GetMem Call
    // - ring data is output data
    LBufferSize   := lz4s_size_stream_block_max( TLZ4BlockSize(LSD.BlockMaxSize) );
    // - block data is input data
    LBlockSize    := lz4s_size_block_max( TLZ4BlockSize(LSD.BlockMaxSize) );

    //allocate source data buffer
    GetMem( LBuffer, LBufferSize + LBlockSize );
    //seperate decoded data block
    LBlock        := (LBuffer + LBufferSize);

    //we start with 0 overflow of bytes
    LOverflow   := 0;

    // * Start Decoding * //

    //process blocks of data until no data is left
    while (LBytes > 0) do
    begin
      //read next compressed data block - we need the block size header - thats 4 bytes
      LBytes := ASourceStream.Read( LBuffer^, CBlockHeader );

      //get actual next block size
      LChunkSize := lz4s_Decode_Get_Block_Size( LSD, PCardinal(LBuffer), LBytes );

      //safety check
      if (LChunkSize+CBlockHeader) > LBufferSize then
        raise Exception.Create('LZ4D: corrupt block header! Block data exceeds max stream block size');

      //read necessary chunk bytes - available bytes for decoding is chunk+header
      LBytes := ASourceStream.Read( (LBuffer+CBlockHeader)^, LChunkSize ) + CBlockHeader;

      if (LBytes < (LChunkSize + CBlockHeader)) then
        raise Exception.Create('LZ4D: not enough stream data available to decode block.');

      //decode next block
      LBytes := lz4s_Decode_Block( LSD, LBuffer, LBlock, LBytes, LBlockSize);

      //write data to stream
      ATargetStream.WriteBuffer( LBlock^, LBytes );
      Inc(Result, LBytes);
    end;

    //read footer - its 4 bytes
    LBytes := ASourceStream.Read( LBuffer^, CFooterSize );

    //check agains stream hash - throws exception if it fails
    lz4s_Decode_Stream_Footer( LSD, LBuffer, LBytes );
  finally
    //cleanup
    lz4s_FreeDescriptor( LSD );
    FreeMem( LBuffer );
  end;
end;


class function TLZ4.Stream_Decode(
  const ASource,
        ATarget: PByte;
  const ASourceSize,
        ATargetSize: Int64)
        : Int64;
const
  CCacheLine  = 64;
  CHeaderSize = 7;
  CBlockHeadSize = 4;
var
  //stream data storage
  LSD:          TLZ4StreamDescriptor;
  //bytes available for writing
  LBytes:       Integer;
  //current working positions
  LInPos, LOutPos:  Int64;
  LBytesLeft:       Cardinal;
  //stream block data element size
  LChunkSize:       Cardinal;
begin
  Result := 0;
  try
    // * Prepare Decoding * //

    //allocate (heap - slow) temp encoding data buffer

    //first, try to parse the header - extract block size from it
    LSD := lz4s_Decode_CreateDescriptor();

    //check for a full header
    if (ASourceSize < CHeaderSize) then
      raise Exception.Create('LZ4S::Stream_Decode: Corrupt LZ4S Stream.');

    //Try to decode the header
    LBytes := lz4s_Decode_Stream_Header( LSD, ASource, LBytes );

    //update position
    LInPos  := LBytes;
    LOutPos := 0;

    // * Start Decoding * //

    //process blocks of data until no data is left
    while (LBytes > 0) and (ASourceSize-LInPos > 0) do
    begin
      //calc chunk data size (block size - block header size)
      LBytesLeft := lz4s_Decode_Get_Block_Size( LSD, PCardinal(ASource+LInPos), ASourceSize-LInPos );

      //decode next block
      LBytes := lz4s_Decode_Block( LSD, (ASource+LInPos), (ATarget+LOutPos), LBytesLeft+CBlockHeadSize, ATargetSize-LOutPos);

      //update position
      Inc(LInPos,   LBytesLeft+CBlockHeadSize);
      Inc(LOutPos,  LBytes);
    end;

    //read stream footer
    lz4s_Decode_Stream_Footer( LSD, ASource+LInPos, ASourceSize-LInPos );

    Result := LOutPos;
  finally
    //cleanup
    lz4s_FreeDescriptor( LSD );
  end;

end;

class function TLZ4.Stream_Encode(
  const ASource,
        ATarget:      PByte;
  const ASourceSize,
        ATargetSize:  Int64;
        ABlockSize:   TStreamBlockSize;
        AUseHash:     Boolean)
        : Int64;
var
  //temp mapping variable for correct block size
  LBlockID:   TLZ4BlockSize;
  //stream data storage
  LSD:        TLZ4StreamDescriptor;

  //current working positions
  LInPos, LOutPos:  Int64;
  LBytesLeft:       Int64;

  //sizes
  LBlockSize: Cardinal;
  LChunkSize: Cardinal;

  //bytes processed
  LBytes:     Cardinal;
begin
  // * Prepare Encoding * //
  Result := 0;

  //map block size
  case ABlockSize of
    sbs64K:   LBlockID := TLZ4BlockSize.bs_4;
    sbs256K:  LBlockID := TLZ4BlockSize.bs_5;
    sbs1MB:   LBlockID := TLZ4BlockSize.bs_6;
    sbs4MB:   LBlockID := TLZ4BlockSize.bs_7;
    else      LBlockID := TLZ4BlockSize.bs_7;
  end;

  try
    //allocate (heap - slow) temp encoding data buffer
    // - block (ring) data is input data
    LBlockSize  := lz4s_size_block_max( LBlockID );
    // - chunk data is output data
    LChunkSize  := lz4s_size_stream_block_max( LBlockID );

    LInPos  := 0;
    LOutPos := 0;

    // * Start Encoding * //

    //create the basis stream descriptor
    if (AUseHash) then
      LSD := lz4s_Encode_CreateDescriptor( CLZ4S_Enc_Default, Byte(LBlockID) )
    else
      LSD := lz4s_Encode_CreateDescriptor( CLZ4S_Enc_NoChecksum, Byte(LBlockID) );

    //Try to encode the header
    LBytes  := lz4s_Encode_Header( LSD, ATarget+LOutPos, LChunkSize );

    //write data to stream
    Inc(LOutPos,  LBytes);

    //process blocks of data until no data is left
    while (LBytes > 0) do
    begin
      //Bytes still available for input
      LBytesLeft := ASourceSize - LInPos;
      if (LBytesLeft > LBlockSize) then LBytesLeft := LBlockSize;

      //encode next block
      LBytes := lz4s_Encode_Continue( LSD, ASource+LInPos, ATarget+LOutPos, LBytesLeft, ATargetSize - LOutPos );

      //write data to "stream"
      Inc(LInPos,   LBytesLeft);
      Inc(LOutPos,  LBytes);
    end;

    //write footer
    LBytes := lz4s_Encode_Footer( LSD, ATarget+LOutPos, LChunkSize );
    Inc(LOutPos,  LBytes);

    Result := LOutPos;
  finally
    //cleanup
    lz4s_FreeDescriptor( LSD );
  end;
end;

end.
