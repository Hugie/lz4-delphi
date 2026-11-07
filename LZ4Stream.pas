unit LZ4Stream;

// Stream compression based on the LZ4 frame format (lz4frame, self describing,
// magic $184D2204). Output is a standard lz4 frame, optionally prefixed with a
// 'LZ4' marker - compatible with the lz4 command line tools when no marker is used.

interface

{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}

{$I LZ4.inc}

uses
  Classes, types,
  lz4d.Imports,
  lz4d.lz4hc,
  lz4d.lz4frame;

type
  {$IF NOT Declared( TBytes )}
  TBytes = TByteDynArray;
  {$IFEND}

  TLZ4EncoderStream = class( TStream )
  private
    FStream           : TStream;
    FContext          : PLZ4F_cctx;
    FPrefs            : LZ4F_preferences_t;
    FOutBuffer        : TBytes;
    fHeader           : Boolean;
    fFinished         : Boolean;
    fError            : Integer;
    fCompressionLevel : Byte;
    fCompressedSize   : Int64;
    function WriteOut( Len : NativeUInt ) : Boolean;
  public
    constructor Create( const Stream: TStream; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_DEFAULT ); reintroduce;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function Read( var Buffer; Count: Longint ): Longint; override;
    function Write( const Buffer; Count: Longint ): Longint; override;
    // finalizes the frame (endmark + checksum), no more writes afterwards
    // - called automatically on destruction
    function Finish : Boolean;
    function Compress( InStream: TStream ) : Int64;
    property Error : Integer read fError;
    property CompressedSize : Int64 read fCompressedSize;
  end;

  TLZ4DecoderStream = class( TStream )
  private
    FStream         : TStream;
    FContext        : PLZ4F_dctx;
    FInBuffer       : TBytes;
    FInPos          : Longint;
    FInLen          : Longint;
    fFinished       : Boolean;
    fError          : Integer;
    FDecompressSize : Int64;
  public
    constructor Create( const Stream: TStream ); reintroduce;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function Read( var Buffer; Count: Longint ): Longint; override;
    function Write( const Buffer; Count: Longint ): Longint; override;
    function Decompress( OutStream: TStream ) : Int64;
    property Error : Integer read fError;
    property DecompressedSize : Int64 read FDecompressSize;
  end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CompressStreamLZ4( InStream : TStream; OutStream: TStream; Header : boolean = False ) : Int64; overload;
function CompressStreamLZ4( Source : PByte ; Len : Cardinal; OutStream: TStream; Header : boolean = False ) : Int64; overload;
function ExtractStreamLZ4( InStream : TStream; OutStream: TStream ) : Int64;

{$IFDEF TESTCASE}
function TestLZ4Stream( FileName : string; Header : boolean = False; SaveDebugFiles : Boolean = False ) : Int64;
{$ENDIF TESTCASE}

implementation

{$IFDEF TESTCASE}
uses
  SysUtils, Dialogs;
{$ENDIF TESTCASE}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const
  HEADER_ = AnsiString( 'LZ4' );
  HEADER_LEN_ = Length( HEADER_ );
type
  tHeader = Array [ 0..HEADER_LEN_-1 ] of AnsiChar;
  pHeader = ^tHeader;

const
  BufferSizeIn_  = $10000; // chunk size fed into the compressor / read from source
  BufferSizeOut_ = $10000; // chunk size for decompressed output

  // error codes ( on top of the negated LZ4F_errorCodes )
  ERROR_WRITE_    = -101;
  ERROR_FINISHED_ = -102;

function LZ4FIsError( Code : NativeUInt ) : Boolean;
begin
  result := {$IFDEF UNDERSCORE}_LZ4F_isError{$ELSE}LZ4F_isError{$ENDIF}( Code ) <> 0;
end;

// maps a LZ4F error to a negative error code, e.g. LZ4F_ERROR_decompressionFailed -> -16
function LZ4FErrorCode( Code : NativeUInt ) : Integer;
begin
  result := -Ord( {$IFDEF UNDERSCORE}_LZ4F_getErrorCode{$ELSE}LZ4F_getErrorCode{$ENDIF}( Code ) );
  if ( result >= 0 ) then
    result := -Ord( LZ4F_ERROR_GENERIC );
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Encoder
constructor TLZ4EncoderStream.Create( const Stream: TStream; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_DEFAULT );
begin
  inherited Create;
  FStream := Stream;
  FContext := nil;
  fError := 0;
  fHeader := Header;
  fFinished := False;
  fCompressionLevel := CompressionLevel;
  fCompressedSize := 0;
end;

procedure TLZ4EncoderStream.AfterConstruction;
var
  Res : NativeUInt;
begin
  inherited;

  Res := {$IFDEF UNDERSCORE}_LZ4F_createCompressionContext{$ELSE}LZ4F_createCompressionContext{$ENDIF}( @FContext, LZ4F_VERSION );
  if LZ4FIsError( Res ) then
    begin
    FContext := nil;
    fError := LZ4FErrorCode( Res );
    Exit;
    end;

  FillChar( FPrefs, SizeOf( FPrefs ), 0 );
  FPrefs.compressionLevel := fCompressionLevel;
  FPrefs.frameInfo.contentChecksumFlag := LZ4F_contentChecksumEnabled;

  SetLength( FOutBuffer, {$IFDEF UNDERSCORE}_LZ4F_compressBound{$ELSE}LZ4F_compressBound{$ENDIF}( BufferSizeIn_, @FPrefs ) );

  if fHeader then
    begin
    if ( FStream.Write( HEADER_[ 1 ], HEADER_LEN_ ) <> HEADER_LEN_ ) then
      begin
      fError := ERROR_WRITE_;
      Exit;
      end;
    Inc( fCompressedSize, HEADER_LEN_ );
    end;

  // frame header
  Res := {$IFDEF UNDERSCORE}_LZ4F_compressBegin{$ELSE}LZ4F_compressBegin{$ENDIF}( FContext, @FOutBuffer[ 0 ], Length( FOutBuffer ), @FPrefs );
  if LZ4FIsError( Res ) then
    fError := LZ4FErrorCode( Res )
  else
    WriteOut( Res );
end;

procedure TLZ4EncoderStream.BeforeDestruction;
begin
  if ( FContext <> nil ) then
    begin
    Finish;
    {$IFDEF UNDERSCORE}_LZ4F_freeCompressionContext{$ELSE}LZ4F_freeCompressionContext{$ENDIF}( FContext );
    FContext := nil;
    end;
  SetLength( FOutBuffer, 0 );
  inherited;
end;

function TLZ4EncoderStream.WriteOut( Len : NativeUInt ) : Boolean;
begin
  result := ( Len = 0 ) OR ( FStream.Write( FOutBuffer[ 0 ], Len ) = Longint( Len ) );
  if result then
    Inc( fCompressedSize, Len )
  else
    fError := ERROR_WRITE_;
end;

function TLZ4EncoderStream.Read( var Buffer; Count: Longint ): Longint;
begin
  result := FStream.Read( Buffer, Count );
end;

function TLZ4EncoderStream.Write( const Buffer; Count: Longint ): Longint;
var
  Src   : PByte;
  Chunk : Longint;
  Res   : NativeUInt;
begin
  if ( fError < 0 ) then
    begin
    result := fError;
    Exit;
    end;
  if fFinished then
    begin
    fError := ERROR_FINISHED_;
    result := fError;
    Exit;
    end;

  Src := @Buffer;
  result := 0;
  while ( result < Count ) do
    begin
    Chunk := Count-result;
    if ( Chunk > BufferSizeIn_ ) then
      Chunk := BufferSizeIn_;

    Res := {$IFDEF UNDERSCORE}_LZ4F_compressUpdate{$ELSE}LZ4F_compressUpdate{$ENDIF}( FContext, @FOutBuffer[ 0 ], Length( FOutBuffer ), Src, Chunk, nil );
    if LZ4FIsError( Res ) then
      begin
      fError := LZ4FErrorCode( Res );
      result := fError;
      Exit;
      end;
    if NOT WriteOut( Res ) then
      begin
      result := fError;
      Exit;
      end;

    Inc( Src, Chunk );
    Inc( result, Chunk );
    end;
end;

function TLZ4EncoderStream.Finish : Boolean;
var
  Res : NativeUInt;
begin
  if fFinished then
    begin
    result := ( fError = 0 );
    Exit;
    end;
  result := False;
  if ( FContext = nil ) OR ( fError < 0 ) then
    Exit;
  fFinished := True;

  // flush pending data and write endmark + content checksum
  Res := {$IFDEF UNDERSCORE}_LZ4F_compressEnd{$ELSE}LZ4F_compressEnd{$ENDIF}( FContext, @FOutBuffer[ 0 ], Length( FOutBuffer ), nil );
  if LZ4FIsError( Res ) then
    fError := LZ4FErrorCode( Res )
  else
    result := WriteOut( Res );
end;

function TLZ4EncoderStream.Compress( InStream: TStream ) : Int64;
var
  InBuf : TBytes;
  Bytes : Longint;
begin
  if ( fError < 0 ) then
    begin
    result := fError;
    Exit;
    end;
  if ( InStream.Position = InStream.Size ) then
    InStream.Position := 0;

  SetLength( InBuf, BufferSizeIn_ );
  repeat
    Bytes := InStream.Read( InBuf[ 0 ], BufferSizeIn_ );
    if ( Bytes <= 0 ) then
      break;
    if ( Write( InBuf[ 0 ], Bytes ) <> Bytes ) then
      begin
      result := fError;
      Exit;
      end;
  until False;

  if NOT Finish then
    begin
    result := fError;
    Exit;
    end;
  result := fCompressedSize;
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Decoder
constructor TLZ4DecoderStream.Create( const Stream: TStream );
begin
  inherited Create;
  FStream := Stream;
  FContext := nil;
  fError := 0;
  fFinished := False;
  FDecompressSize := 0;
  FInPos := 0;
  FInLen := 0;
end;

procedure TLZ4DecoderStream.AfterConstruction;
var
  Res   : NativeUInt;
  Head  : tHeader;
  Bytes : Longint;
begin
  inherited;

  Res := {$IFDEF UNDERSCORE}_LZ4F_createDecompressionContext{$ELSE}LZ4F_createDecompressionContext{$ENDIF}( @FContext, LZ4F_VERSION );
  if LZ4FIsError( Res ) then
    begin
    FContext := nil;
    fError := LZ4FErrorCode( Res );
    Exit;
    end;

  // skip the optional 'LZ4' marker
  Bytes := FStream.Read( Head[ 0 ], HEADER_LEN_ );
  if ( Bytes <> HEADER_LEN_ ) OR ( Head <> HEADER_ ) then
    FStream.Position := FStream.Position-Bytes;

  SetLength( FInBuffer, BufferSizeIn_ );
end;

procedure TLZ4DecoderStream.BeforeDestruction;
begin
  if ( FContext <> nil ) then
    begin
    {$IFDEF UNDERSCORE}_LZ4F_freeDecompressionContext{$ELSE}LZ4F_freeDecompressionContext{$ENDIF}( FContext );
    FContext := nil;
    end;
  SetLength( FInBuffer, 0 );
  inherited;
end;

function TLZ4DecoderStream.Read( var Buffer; Count: Longint ): Longint;
var
  Dst            : PByte;
  DstLen, SrcLen : NativeUInt;
  Res            : NativeUInt;
begin
  if ( fError < 0 ) then
    begin
    result := fError;
    Exit;
    end;

  Dst := @Buffer;
  result := 0;
  while ( result < Count ) AND NOT fFinished do
    begin
    if ( FInPos = FInLen ) then
      begin
      FInLen := FStream.Read( FInBuffer[ 0 ], BufferSizeIn_ );
      FInPos := 0;
      if ( FInLen <= 0 ) then
        break; // end of input, frame incomplete
      end;

    DstLen := Count-result;
    SrcLen := FInLen-FInPos;
    Res := {$IFDEF UNDERSCORE}_LZ4F_decompress{$ELSE}LZ4F_decompress{$ENDIF}( FContext, Dst, @DstLen, @FInBuffer[ FInPos ], @SrcLen, nil );
    if LZ4FIsError( Res ) then
      begin
      fError := LZ4FErrorCode( Res );
      result := fError;
      Exit;
      end;

    Inc( FInPos, SrcLen );
    Inc( Dst, DstLen );
    Inc( result, DstLen );
    Inc( FDecompressSize, DstLen );

    if ( Res = 0 ) then
      begin
      // frame complete - reposition the source right behind the frame
      fFinished := True;
      FStream.Position := FStream.Position-( FInLen-FInPos );
      FInPos := FInLen;
      end
    else if ( DstLen = 0 ) AND ( SrcLen = 0 ) then
      break; // no progress possible
    end;
end;

function TLZ4DecoderStream.Write( const Buffer; Count: Longint ): Longint;
begin
  result := -1;
end;

function TLZ4DecoderStream.Decompress( OutStream: TStream ) : Int64;
var
  Buffer : TBytes;
  Bytes  : Longint;
begin
  if ( fError < 0 ) then
    begin
    result := fError;
    Exit;
    end;

  result := 0;
  SetLength( Buffer, BufferSizeOut_ );
  repeat
    Bytes := Read( Buffer[ 0 ], BufferSizeOut_ );
    if ( Bytes < 0 ) then
      begin
      result := Bytes;
      Exit;
      end;
    if ( Bytes = 0 ) then
      break;
    if ( OutStream.Write( Buffer[ 0 ], Bytes ) <> Bytes ) then
      begin
      fError := ERROR_WRITE_;
      result := fError;
      Exit;
      end;
    Inc( result, Bytes );
  until False;
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CompressStreamLZ4( InStream : TStream; OutStream: TStream; Header : boolean = False ) : Int64;
var
  Encoder  : TLZ4EncoderStream;
  ToSource : Boolean;
begin
  result := -100;
  if ( InStream = nil ) then
    Exit;
  if ( InStream = OutStream ) OR ( OutStream = nil ) then
    begin
    ToSource := True;
    OutStream := TMemoryStream.Create;
    end
  else
    ToSource := False;

  Encoder := TLZ4EncoderStream.Create( OutStream, Header );
  try
    result := Encoder.Compress( InStream );
  finally
    Encoder.Free;
  end;

  if ToSource then
    begin
    if ( result > 0 ) then
      begin
      InStream.Position  := 0;
      InStream.Size      := 0;
      OutStream.Position := 0;
      InStream.CopyFrom( OutStream, OutStream.Size );
      end;
    OutStream.free;
    end;
end;

function CompressStreamLZ4( Source : PByte ; Len : Cardinal; OutStream: TStream; Header : boolean = False ) : Int64;
var
  Encoder   : TLZ4EncoderStream;
  Chunk     : Longint;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  if ( OutStream = nil ) then
    Exit;

  Encoder := TLZ4EncoderStream.Create( OutStream, Header );
  try
    while ( Len > 0 ) AND ( Encoder.Error = 0 ) do
      begin
      if ( Len > BufferSizeIn_ ) then
        Chunk := BufferSizeIn_
      else
        Chunk := Len;
      if ( Encoder.Write( Source^, Chunk ) <> Chunk ) then
        break;
      Inc( Source, Chunk );
      Dec( Len, Chunk );
      end;

    if ( Encoder.Error < 0 ) then
      result := Encoder.Error
    else if Encoder.Finish then
      result := Encoder.CompressedSize
    else
      result := Encoder.Error;
  finally
    Encoder.Free;
  end;
end;

function ExtractStreamLZ4( InStream : TStream; OutStream: TStream ) : Int64;
var
  Decoder  : TLZ4DecoderStream;
  ToSource : Boolean;
begin
  result := -200;
  if ( InStream = nil ) then
    Exit;
  if ( InStream = OutStream ) OR ( OutStream = nil ) then
    begin
    ToSource := True;
    OutStream := TMemoryStream.Create;
    end
  else
    ToSource := False;

  Decoder := TLZ4DecoderStream.Create( InStream );
  try
    result := Decoder.Decompress( OutStream );
  finally
    Decoder.Free;
  end;

  if ToSource then
    begin
    if ( result > 0 ) then
      begin
      InStream.Position  := 0;
      InStream.Size      := 0;
      OutStream.Position := 0;
      InStream.CopyFrom( OutStream, OutStream.Size );
      end;
    OutStream.free;
    end;
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{$IFDEF TESTCASE}
function TestLZ4Stream( FileName : string; Header : boolean = False; SaveDebugFiles : Boolean = False ) : Int64;
var
  sIn : TMemoryStream;

  function PointerToStream : Int64;
  var
    sCompress, sOut : TMemoryStream;
  begin
    sCompress := TMemoryStream.Create;
    result := CompressStreamLZ4( sIn.Memory, sIn.Size, sCompress, Header );
    if ( result <= 0 ) then
      begin
      sCompress.free;
      result := -3;
      Exit;
      end;
    if SaveDebugFiles then
      sCompress.SaveToFile( ChangeFileExt( FileName, '.LZ42' ) );

    sOut := TMemoryStream.Create;
    sCompress.Position := 0;
    result := ExtractStreamLZ4( sCompress, sOut );
    if ( result <= 0 ) then
      begin
      sOut.free;
      sCompress.free;
      result := -2;
      Exit;
      end;

    if ( sIn.Size <> sOut.Size ) OR NOT CompareMem( sIn.Memory, sOut.Memory, sIn.Size ) then
      result := -1;
    if SaveDebugFiles then
      sOut.SaveToFile( ChangeFileExt( FileName, '.extract' ) );

    sOut.free;
    sCompress.free;
  end;

  function StreamToStream : Int64;
  var
    sCompress, sOut : TMemoryStream;
  begin
    sCompress := TMemoryStream.Create;
    result := CompressStreamLZ4( sIn, sCompress, Header );
    if ( result <= 0 ) then
      begin
      sCompress.free;
      result := -3;
      Exit;
      end;
    if SaveDebugFiles then
      sCompress.SaveToFile( ChangeFileExt( FileName, '.LZ4' ) );

    sOut := TMemoryStream.Create;
    sCompress.Position := 0;
    result := ExtractStreamLZ4( sCompress, sOut );
    if ( result <= 0 ) then
      begin
      sOut.free;
      sCompress.free;
      result := -2;
      Exit;
      end;

    if ( sIn.Size <> sOut.Size ) OR NOT CompareMem( sIn.Memory, sOut.Memory, sIn.Size ) then
      result := -1;
    if SaveDebugFiles then
      sOut.SaveToFile( ChangeFileExt( FileName, '.extract' ) );

    sOut.free;
    sCompress.free;
  end;

  function StreamToStreamClass : Int64;
    function CompressStreamLZ4( InStream, OutStream: TStream; Header : boolean = False ) : Int64;
    var
      Encoder: TLZ4EncoderStream;
    begin
      Encoder := TLZ4EncoderStream.Create( OutStream, Header );
      try
        result := Encoder.Compress( InStream );
      finally
        Encoder.Free;
      end;
    end;

    function ExtractStreamLZ4( InStream, OutStream: TStream ) : Int64;
    var
      Decoder: TLZ4DecoderStream;
    begin
      Decoder := TLZ4DecoderStream.Create( InStream );
      try
        result := Decoder.Decompress( OutStream );
      finally
        Decoder.Free;
      end;
    end;
  var
    sCompress, sOut : TMemoryStream;
  begin
    sCompress := TMemoryStream.Create;
    result := CompressStreamLZ4( sIn, sCompress, Header );
    if ( result <= 0 ) then
      begin
      sCompress.free;
      result := -3;
      Exit;
      end;
    if SaveDebugFiles then
      sCompress.SaveToFile( ChangeFileExt( FileName, '.LZ4' ) );

    sOut := TMemoryStream.Create;
    sCompress.Position := 0;
    result := ExtractStreamLZ4( sCompress, sOut );
    if ( result <= 0 ) then
      begin
      sOut.free;
      sCompress.free;
      result := -2;
      Exit;
      end;

    if ( sIn.Size <> sOut.Size ) OR NOT CompareMem( sIn.Memory, sOut.Memory, sIn.Size ) then
      result := -1;
    if SaveDebugFiles then
      sOut.SaveToFile( ChangeFileExt( FileName, '.extract' ) );

    sOut.free;
    sCompress.free;
  end;
begin
  result := -999;
  if NOT FileExists( FileName ) then
    Exit;

  sIn := TMemoryStream.Create;
  sIn.LoadFromFile( FileName );
  sIn.Position := 0;

  result := PointerToStream;
  case result of
  -999 : ShowMessage( 'PointerToStream: Invalid File' );
    -3 : ShowMessage( 'PointerToStream: Failed compress' );
    -2 : ShowMessage( 'PointerToStream: Failed decompress' );
    -1 : ShowMessage( 'PointerToStream: Size invalid or CompareMem failed' );
     0 : ShowMessage( 'PointerToStream: Failed to Extract' );
//    else
//       ShowMessage( 'PointerToStream: OK' );
  end;
  if ( result < 0 ) then
    begin
    sIn.Free;
    Exit;
    end;

  result := StreamToStream;
  case result of
  -999 : ShowMessage( 'StreamToStream: Invalid File' );
    -3 : ShowMessage( 'StreamToStream: Failed compress' );
    -2 : ShowMessage( 'StreamToStream: Failed decompress' );
    -1 : ShowMessage( 'StreamToStream: Size invalid or CompareMem failed' );
     0 : ShowMessage( 'StreamToStream: Failed to Extract' );
//    else
//       ShowMessage( 'StreamToStream: OK' );
  end;
  if ( result < 0 ) then
    begin
    sIn.Free;
    Exit;
    end;

  result := StreamToStreamClass;
  case result of
  -999 : ShowMessage( 'StreamToStreamClass: Invalid File' );
    -3 : ShowMessage( 'StreamToStreamClass: Failed compress' );
    -2 : ShowMessage( 'StreamToStreamClass: Failed decompress' );
    -1 : ShowMessage( 'StreamToStreamClass: Size invalid or CompareMem failed' );
     0 : ShowMessage( 'StreamToStreamClass: Failed to Extract' );
//    else
//       ShowMessage( 'StreamToStreamClass: OK' );
  end;
  if ( result < 0 ) then
    begin
    sIn.Free;
    Exit;
    end;
  sIn.free;
end;

//initialization
//  TestLZ4Stream( ParamStr( 0 ) + '_', True, True );
{$ENDIF TESTCASE}

end.
