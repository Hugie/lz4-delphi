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

unit lz4d.lz4s;

{
This is a temporary implementation of the lz4s library until Yann Collet will provide lz4s as part of the lz4 library
 => it supports only parts of the LZ4 Streaming Format 1.4, the default settings
 => Following Flags are used: BlockIndependence=1, StreamChecksum=1, BlockMaximumSize=[4-7],
}

interface


const MAGICNUMBER_SIZE    = 4;
const LZ4S_MAGICNUMBER    = $184D2204;
const LZ4S_SKIPPABLE0     = $184D2A50;
const LZ4S_SKIPPABLEMASK  = $FFFFFFF0;
const LEGACY_MAGICNUMBER  = $184C2102;

const LZ4S_BLOCKSIZEID_DEFAULT  = 7;
const LZ4S_CHECKSUM_SEED        = 0;
const LZ4S_EOS                  = 0;
const LZ4S_MAXHEADERSIZE        = (MAGICNUMBER_SIZE+2+8+4+1);
const LZ4S_CACHELINE            = 64;


type
  TLZ4SFlag = (
    fVersion              = $40, // 01000000 b, Version 01
    fBlockIndependence    = $20, // 00100000 b,
    fBlockCheckSum        = $10, // 00010000 b,
    fStreamSize           = $08, // 00001000 b,
    fStreamChecksum       = $04, // 00000100 b,
    fReserved             = $02, // 00000010 b,
    fPresetDictionary     = $01  // 00000001 b
    );

  //Standard encoding flags
 const CLZ4S_Enc_Default    = (Byte(fVersion) or Byte(fBlockIndependence) or Byte(fStreamChecksum)); // = 100 Dezimal
 const CLZ4S_Enc_NoChecksum = (Byte(fVersion) or Byte(fBlockIndependence));

 //additional allowed decoding flags
 const CLZ4S_Dec_Depend         = (Byte(fVersion) or Byte(fStreamChecksum));
 const CLZ4S_Dec_Dep_NoChecksum = (Byte(fVersion));

 const CLZ4SEncFlags = [CLZ4S_Enc_Default, CLZ4S_Enc_NoChecksum];
 const CLZ4SDecFlags = [CLZ4S_Enc_Default, CLZ4S_Enc_NoChecksum, CLZ4S_Dec_Depend, CLZ4S_Dec_Dep_NoChecksum];

type
  TLZ4BlockSize = (
    bs_4                  = $40, // 01000000 b, 64  KB
    bs_5                  = $50, // 01010000 b, 256 KB
    bs_6                  = $60, // 01100000 b, 1   MB
    bs_7                  = $70  // 01010000 b, 4   MB
  );

type
  TLZ4StreamDescriptor = packed record
    Flags:          Byte;
    BlockMaxSize:   Byte;
    StreamSize:     UInt64;   //not used
    DictionaryID:   Cardinal; //not used
    HeaderChecksum: Byte;     //not used
    StreamData:     Pointer;  //lz4 Create Stream Result
    ChecksumState:  Pointer;  //XXH32 Stream Checksum State
    function UsesStreamChecksum(): Boolean; inline;
  end;


//data buffers for writing and reading:
// - size of input buffer should be ActiveBlockSizeIDInBytes ( 2 ^ ( 8 + 2*bs_n ) )
// -> e.g. bs_4 (2 ^ ( 8 + 2*4 ) ) = 64 KB
// - worst case output data size is MaxBlockSize+4

// attention: algorithm is block dependent, so the last input block contains the dictionary
// -> use a ring buffer (e.g. double buffer) for input data
// -> or use lz4_saveDict to store the dictionary at a specific position (will be stored inside StreamDescriptor)


//////////// * Encoding Functionality * ////////////////

function  lz4s_Encode_CreateDescriptor(const AFlags, ABlockSize: Byte): TLZ4StreamDescriptor;
procedure lz4s_FreeDescriptor( var AStreamDescriptor: TLZ4StreamDescriptor );


//write stream header - initializes stream hash
// magic number, flags, etc
function  lz4s_Encode_Header( var   AStreamDescriptor:  TLZ4StreamDescriptor;
                                    ATargetPtr: Pointer;
                                    ATargetSize:   Cardinal): Cardinal;

//Write block data until it returns 0
// It will return the number of bytes of new block data
// for each call, we suspect the old output data to be still in place (e.g. double buffer)
function  lz4s_Encode_Continue( var   AStreamDescriptor:  TLZ4StreamDescriptor;
                                const ASourcePtr: Pointer;
                                      ATargetPtr: Pointer;
                                      ASourceSize, ATargetSize: Cardinal): Cardinal;

//write stream footer
function  lz4s_Encode_Footer( var   AStreamDescriptor:  TLZ4StreamDescriptor;
                                    ATargetPtr: Pointer;
                                    ATargetSize:   Cardinal): Cardinal;


//////////// * Decoding Functionality * ////////////////

function  lz4s_Decode_CreateDescriptor() : TLZ4StreamDescriptor;

//throws exceptions on bad header
// returns the amount of bytes read from source
function  lz4s_Decode_Stream_Header  (var     AStreamDescriptor:    TLZ4StreamDescriptor;
                                      const   ASourcePtr:           PByte;
                                              ASourceSize:          Cardinal ): Cardinal;

//returns the next stream block datachunk  size - so you will know how much needs to be read
// - for determining the block size, 4 bytes of the next block should have been read
// - returns 0 on End of Stream !!! and (ASourcePtr^ = 0)
function  lz4s_Decode_Get_Block_Size( var     AStreamDescriptor:    TLZ4StreamDescriptor;
                                      const   ASourcePtr:           PCardinal;
                                              ASourceSize:          Cardinal ): Cardinal;



//throws exception on failed reading, bad blocks or bad checksum
//returns bytes written to target ptr
function  lz4s_Decode_Block(    var    AStreamDescriptor:         TLZ4StreamDescriptor;
                                const  ASourcePtr:                PByte;
                                const  ATargetPtr:                PByte;
                                const  ASourceSize, ATargetSize:  Cardinal): Cardinal;

//throws exception if stream hash is wrong
//returns true on success - throws error if not
function  lz4s_Decode_Stream_Footer(    var    AStreamDescriptor:         TLZ4StreamDescriptor;
                                        const  ASourcePtr:                PByte;
                                        const  ASourceSize:  Cardinal): Boolean;

//////////// * Helper Functions * ////////////////

//block size is input data size
// - read this amount of data for each encoding step
// - expect this amount of data as max output from each decoding step
function lz4s_size_block_max(  ABlocksize: TLZ4BlockSize ): Cardinal; inline;

//stream block size is output data size
// - returns the max size of possible output data for each encoding step
// - read this amount of data as max input size for the decoding step
function lz4s_size_stream_block_max( ABlocksize: TLZ4BlockSize ): Cardinal;  inline;



implementation

  uses
    System.SysUtils,
    System.Math,
    lz4d.lz4,
    xxHash;

function lz4s_size_block_max(  ABlocksize: TLZ4BlockSize ): Cardinal;
begin
  // 4 - 64 kb
  // 5 - 256 kb
  // 6 - 1 MB
  // 7 - 4 MB
  Result := 1 shl (((Byte(ABlocksize) shr 4) * 2) + 8);
end;

function lz4s_size_stream_block_max(  ABlocksize: TLZ4BlockSize ): Cardinal;
begin
  Result := lz4s_size_block_max( ABlocksize ) + LZ4S_CACHELINE;
end;


/// Make sure only the supported settings are used
function CheckSettings( const AFlags, ABlockSize: Byte; var VError: String; AEncoding: Boolean ): Boolean;
begin
  VError := '';
  Result := True;

  if not (( AEncoding and (AFlags in CLZ4SEncFlags)) or (not AEncoding and (AFlags in CLZ4SDecFlags))) then
  begin
    VError := 'Unsupported stream description flags. Only "Default Mode" with or without Stream Hash is supported.';
    Result := False;
  end;

  if not InRange( ABlockSize, Byte(Low(TLZ4BlockSize)), Byte(High(TLZ4BlockSize)) ) then
  begin
    VError := 'Unsupported block size. Only Mode 4-7 supported.';
    Result := False;
  end;
end;

function lz4s_Encode_CreateDescriptor(const AFlags, ABlockSize: Byte): TLZ4StreamDescriptor;
var
  LError: String;
begin
  //First thing: Verify Settings
  if not CheckSettings( AFlags, ABlockSize, LError, True ) then
    raise Exception.Create('LZ4S: Invalid stream header: ' + LError);

  Result.Flags          := AFlags;
  Result.BlockMaxSize   := ABlockSize;
  Result.StreamSize     := 0;
  Result.HeaderChecksum := 0;
  Result.StreamData     := LZ4_createStream();

  if (Result.StreamData = nil) then
    raise Exception.Create('LZ4S: Could not create Stream data. LZ4_createStream failed');
end;


procedure lz4s_FreeDescriptor( var AStreamDescriptor: TLZ4StreamDescriptor );
begin
  if (AStreamDescriptor.StreamData <> nil) then
    LZ4_free( AStreamDescriptor.StreamData );

  FillChar( AStreamDescriptor, SizeOf(TLZ4StreamDescriptor), 0 );
end;

function  lz4s_Encode_Header(
  var   AStreamDescriptor:  TLZ4StreamDescriptor;
        ATargetPtr: Pointer;
        ATargetSize:   Cardinal)
        : Cardinal;
var
  L4BytePtr:  PCardinal;
  L1BytePtr:  PByte;
  LHash:      Cardinal;
begin
  //check size
  if (ATargetSize < 7) then
    raise Exception.Create('LZ4S: Could not write Stream Header. Not enough space.');

  //first 4 bytes does contain the magic number
  L4BytePtr   :=  ATargetPtr;
  L4BytePtr^  :=  LZ4S_MAGICNUMBER;

  //followed by 1 byte flags
  L1BytePtr   :=  ATargetPtr;
  L1BytePtr[4]:=  AStreamDescriptor.Flags;
  L1BytePtr[5]:=  AStreamDescriptor.BlockMaxSize;

  //prepare header hash
  // - hash only flags and blocksize

  // => since onle line hash is not available at the moment (compiler error) we need to use the 3 line version
  AStreamDescriptor.ChecksumState := XXH32_init( LZ4S_CHECKSUM_SEED );
  XXH32_update( AStreamDescriptor.ChecksumState, L1BytePtr+4, 2 );
  LHash := XXH32_digest( AStreamDescriptor.ChecksumState );

  //header gets only the second byte of the 4 byte header hash
  L1BytePtr[6]:= Byte((LHash shr 8) and $FF);

  //reset checksum state - if used for stream
  if (AStreamDescriptor.UsesStreamChecksum) then
    AStreamDescriptor.ChecksumState := XXH32_init(LZ4S_CHECKSUM_SEED );

  //we prepared 7 bits to write
  Result := 7;

  //start stream size
  AStreamDescriptor.StreamSize := 7;
end;

function  lz4s_Encode_Continue(
  var   AStreamDescriptor:  TLZ4StreamDescriptor;
  const ASourcePtr:       Pointer;
        ATargetPtr:       Pointer;
        ASourceSize,
        ATargetSize:      Cardinal)
        : Cardinal;
var
  LOutBytes:  Integer;
  LBytePtr:   PByte;
begin
  Result := 0;

  if (ASourceSize <= 0) then Exit();

  if (ATargetSize < ASourceSize+4) then
    raise Exception.Create('LZ4S: Not enough Target memory for max block write length.');

  //update hash for next block - if configured
  if (AStreamDescriptor.UsesStreamChecksum) then
    XXH32_update(AStreamDescriptor.ChecksumState, ASourcePtr, ASourceSize);

  //compress next block
  // - first 4 bytes contains the Compressed/Uncompressed Flag + Block size
  // - write compressed data to the follow up bytes
  LBytePtr  := ATargetPtr;
  LOutBytes := LZ4_compress_continue( AStreamDescriptor.StreamData, ASourcePtr, LBytePtr+4, ASourceSize );

  //<=0 means no compression happend - store it uncompressed
  if (LOutBytes > 0) then
  begin
    //compression successfull
    PCardinal(LBytePtr)^ := LOutBytes and $7FFFFFFF; //highes bit = 0 = compressed
    //inc stream size
    AStreamDescriptor.StreamSize := LOutBytes + AStreamDescriptor.StreamSize;
    //byte written
    Result := LOutBytes + 4;
  end else
  begin
    //compression unsuccessfull
    PCardinal(LBytePtr)^ := ASourceSize or $80000000;  //highest bit = 1 = uncompressed block
    //inc stream size
    AStreamDescriptor.StreamSize := ASourceSize + AStreamDescriptor.StreamSize;
    //byte written
    Result := ASourceSize + 4;
  end;
end;

function  lz4s_Encode_Footer(
  var   AStreamDescriptor:  TLZ4StreamDescriptor;
        ATargetPtr: Pointer;
        ATargetSize:   Cardinal)
        : Cardinal;
var
  L4BytePtr: PCardinal;
begin
  Result    := 0;
  L4BytePtr := ATargetPtr;

  if (ATargetSize < 4) then
    raise Exception.Create('LZ4S: Not enough Target memory for stream footer.');

  //Write eof symbol
  L4BytePtr^ := LZ4S_EOS;
  Inc(L4BytePtr, 1);
  Result := 4;

  if (AStreamDescriptor.UsesStreamChecksum) then
  begin
    if (ATargetSize < 8) then
      raise Exception.Create('LZ4S: Not enough Target memory for stream footer.');

    L4BytePtr^ := XXH32_digest( AStreamDescriptor.ChecksumState );
    Result := 8;
  end;
end;


function  lz4s_Decode_CreateDescriptor(): TLZ4StreamDescriptor;
begin
  //init necessary structures
  FillChar( Result, sizeof(TLZ4StreamDescriptor), 0 );
  Result.StreamData     := LZ4_createStreamDecode;
  Result.ChecksumState  := XXH32_init( LZ4S_CHECKSUM_SEED );
end;


function  lz4s_Decode_Stream_Header(
  var     AStreamDescriptor:    TLZ4StreamDescriptor;
  const   ASourcePtr:           PByte;
          ASourceSize:          Cardinal)
          : Cardinal;
var
  LMagicNumber: Cardinal;
  LHash: Cardinal;
  LError : String;
begin
  Result := 0;

  if (ASourceSize < 7)  then
    raise Exception.Create('LZ4S: Decoding Data too small for default header informations.');

  LMagicNumber := PCardinal(ASourcePtr)^;

  if (LMagicNumber <> LZ4S_MAGICNUMBER ) then
    raise Exception.Create('LZ4S: Unsupported or unrecognized file format. Only default lz4s format is supported.');

  AStreamDescriptor.Flags           := (ASourcePtr+4)^;
  AStreamDescriptor.BlockMaxSize    := (ASourcePtr+5)^;
  AStreamDescriptor.HeaderChecksum  := (ASourcePtr+6)^;

  // => since onle line hash is not available at the moment (compiler error) we need to use the 3 line version
  XXH32_update( AStreamDescriptor.ChecksumState, (ASourcePtr+4), 2 );
  LHash := XXH32_digest( AStreamDescriptor.ChecksumState );

  //header gets only the second byte of the 4 byte header hash
  LHash:= Byte((LHash shr 8) and $FF);

  //header gets only the second byte of the 4 byte header hash
  if (AStreamDescriptor.HeaderChecksum <> LHash) then
    raise Exception.Create('LZ4S: Header Checksum differs. Corrupt Header.');

  //check for supported header modes
  if not CheckSettings( AStreamDescriptor.Flags, AStreamDescriptor.BlockMaxSize, LError, False) then
    raise Exception.Create('LZ4S: Invalid stream header: ' + LError);

    //reinit XXH32 stuff - if necessary
  if (AStreamDescriptor.UsesStreamChecksum) then
    AStreamDescriptor.ChecksumState  := XXH32_init( LZ4S_CHECKSUM_SEED );

  Result := 7;
end;


//throws exception if stream hash is wrong
//returns 0 on success - throws error if not
function  lz4s_Decode_Stream_Footer(
  var    AStreamDescriptor:         TLZ4StreamDescriptor;
  const  ASourcePtr:                PByte;
  const  ASourceSize:  Cardinal)
  : Boolean;
var
  LStreamHash, LHash: Cardinal;
begin
  Result := True;

  //if no stream checksums are given, ignore the footer
  if (not AStreamDescriptor.UsesStreamChecksum) then Exit();

  if (ASourceSize < 4)  then
    raise Exception.Create('LZ4S: Decoding Data too small for default footer informations.');

  Move( ASourcePtr^, LStreamHash, 4 );

  LHash := XXH32_digest( AStreamDescriptor.ChecksumState );

  if (LStreamHash <> LHash) then
    raise Exception.Create('LZ4S: Stream Data is corrupt. Stream and result hash differs.');
end;


function  lz4s_Decode_Get_Block_Size(
  var     AStreamDescriptor:    TLZ4StreamDescriptor;
  const   ASourcePtr:           PCardinal;
          ASourceSize:          Cardinal )
          : Cardinal;
begin
  if (ASourceSize < 4) then
    raise Exception.Create('LZ4S: 4 Bytes necessary to decode block size. Less is given.');

  Result := (ASourcePtr^ and $7FFFFFFF);
end;




function  lz4s_Decode_Block(
  var     AStreamDescriptor:        TLZ4StreamDescriptor;
  const   ASourcePtr:               PByte;
  const   ATargetPtr:               PByte;
  const   ASourceSize, ATargetSize: Cardinal)
          : Cardinal;
var
  LCompressed:  Boolean;
  LBlockSize:   Cardinal;
  LDecompBytes: Integer;
begin
  Result := 0;

  //first - read block header
  LBlockSize := PCardinal( ASourcePtr )^;

  //check for EOS
  if (LBlockSize = LZ4S_EOS) then
  begin
    Result          := 0;
    Exit();
  end;

  //highest bit = 0 => uncompressed block
  LCompressed := (LBlockSize and $80000000) = 0;
  LBlockSize  := (LBlockSize and $7FFFFFFF);

  if (ASourceSize < LBlockSize+4) then
    raise Exception.Create('LZ4S: Block decode error. Given Block data is incomplete.');

  // if highes bit of blocksize is 0, then the block is compressed
  if (LCompressed) then
  begin
    // * compressed block * //
    LDecompBytes := LZ4_decompress_safe_continue( AStreamDescriptor.StreamData, (ASourcePtr+4), ATargetPtr, LBlockSize, ATargetSize );
    Result := LDecompBytes;
  end
  else
  begin
    Result := LBlockSize;
    Move( (ASourcePtr+4)^, ATargetPtr^, LBlockSize );
  end;

  //finaly, update hash of decompressed material
  if (AStreamDescriptor.UsesStreamChecksum) then
    XXH32_update( AStreamDescriptor.ChecksumState, ATargetPtr, Result );
end;

{ TLZ4StreamDescriptor }

function TLZ4StreamDescriptor.UsesStreamChecksum: Boolean;
begin
  Result := Boolean(Flags and Byte(fStreamChecksum));
end;

Initialization

Finalization
end.
