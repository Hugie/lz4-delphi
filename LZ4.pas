unit LZ4;

interface

{$I LZ4.inc}

{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}

uses
  types,
  lz4d.lz4hc;

function CompressLZ4( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False ) : Int64; overload;
function CompressLZ4( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False ) : Int64; overload;

function CompressLZ4_HC( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64; overload;
function CompressLZ4_HC( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64; overload;

function CompressLZ4_Frame( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64; overload;
function CompressLZ4_Frame( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64; overload;

function ExtractLZ4( Source : PByte; Len : Cardinal; var Decompressed : TByteDynArray ) : Int64; overload;
function ExtractLZ4( Source : PByte; Len : Cardinal; var Decompressed : Pointer ) : Int64; overload;
function ExtractLZ4_Frame( Source : PByte; Len : Cardinal; var Decompressed : TByteDynArray ) : Int64; overload;
function ExtractLZ4_Frame( Source : PByte; Len : Cardinal; var Decompressed : Pointer ) : Int64; overload;

{$IFDEF TESTCASE}
function TestLZ4( FileName : string; Mode : Byte = 0; Header : boolean = False; SaveDebugFiles : Boolean = False ) : Int64;
{$ENDIF TESTCASE}

implementation

uses
{$IFDEF TESTCASE}
  Classes, SysUtils, Dialogs,
{$ENDIF TESTCASE}
  lz4d.lz4, lz4d.lz4frame;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const
  HEADER_ = AnsiString( 'lz4' );
  HEADER_LEN_ = Length( HEADER_ );
  HEADER_HC_ = AnsiString( 'lz4hc' );
  HEADER_HC_LEN_ = Length( HEADER_HC_ );
  HEADER_FRAME_ = AnsiString( 'lz4f' );
  HEADER_FRAME_LEN_ = Length( HEADER_FRAME_ );
type
  tHeader = Array [ 0..HEADER_LEN_-1 ] of AnsiChar;
  pHeader = ^tHeader;
  tHeaderHC = Array [ 0..HEADER_HC_LEN_-1 ] of AnsiChar;
  pHeaderHC = ^tHeaderHC;
  tHeaderFrame = Array [ 0..HEADER_FRAME_LEN_-1 ] of AnsiChar;
  pHeaderFrame = ^tHeaderHC;

function CompressLZ4( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False ) : Int64;
var
  OutSize : Integer;
  Offset  : Byte;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  SetLength( Compressed, 0 );

  OutSize := {$IFDEF UNDERSCORE}_LZ4_compressBound{$ELSE}LZ4_compressBound{$ENDIF}( Len );
  if Header then
    Offset := SizeOf( Len )+HEADER_LEN_
  else
    Offset := SizeOf( Len );
  SetLength( Compressed, OutSize+Offset );

  if Header then
    begin
    Move( HEADER_[ 1 ], Compressed[ 0 ], HEADER_LEN_ );
    Move( Len, Compressed[ HEADER_LEN_ ], SizeOf( Len ) );
    end
  else
    Move( Len, Compressed[ 0 ], SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4_compress_default{$ELSE}LZ4_compress_default{$ENDIF}( Source, @Compressed[ Offset ], Len, OutSize );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );

    if ( Result <> OutSize+Offset ) then
      SetLength( Compressed, Result );
    end
  else
    SetLength( Compressed, 0 );
end;

function CompressLZ4( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False ) : Int64;
var
  bCompressed : PByte;
  OutSize     : Integer;
  Offset      : Byte;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  if ( Compressed <> nil ) then
    ReallocMem( Compressed, 0 );

  OutSize := {$IFDEF UNDERSCORE}_LZ4_compressBound{$ELSE}LZ4_compressBound{$ENDIF}( Len );
  if Header then
    Offset := SizeOf( Len )+HEADER_LEN_
  else
    Offset := SizeOf( Len );
  ReallocMem( Compressed, OutSize+Offset );

  bCompressed := Compressed;

  if Header then
    begin
    Move( HEADER_[ 1 ], bCompressed^, HEADER_LEN_ );
    Inc( bCompressed, HEADER_LEN_ );
    end;
  Move( Len, bCompressed^, SizeOf( Len ) );
  Inc( bCompressed, SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4_compress_default{$ELSE}LZ4_compress_default{$ENDIF}( Source, bCompressed, Len, OutSize );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );
    if ( Result <> OutSize+Offset ) then
      ReallocMem( Compressed, Result );
    end
  else
    ReallocMem( Compressed, 0 );
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CompressLZ4_HC( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64;
var
  OutSize : Integer;
  Offset  : Byte;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  SetLength( Compressed, 0 );

  OutSize := {$IFDEF UNDERSCORE}_LZ4_compressBound{$ELSE}LZ4_compressBound{$ENDIF}( Len );
  if Header then
    Offset := SizeOf( Len )+HEADER_HC_LEN_
  else
    Offset := SizeOf( Len );
  SetLength( Compressed, OutSize+Offset );

  if Header then
    begin
    Move( HEADER_HC_[ 1 ], Compressed[ 0 ], HEADER_HC_LEN_ );
    Move( Len, Compressed[ HEADER_HC_LEN_ ], SizeOf( Len ) );
    end
  else
    Move( Len, Compressed[ 0 ], SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4_compress_HC{$ELSE}LZ4_compress_HC{$ENDIF}( Source, @Compressed[ Offset ], Len, OutSize, CompressionLevel );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );

    if ( Result <> OutSize+Offset ) then
      SetLength( Compressed, Result );
    end
  else
    SetLength( Compressed, 0 );
end;

function CompressLZ4_HC( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64;
var
  bCompressed : PByte;
  OutSize     : Integer;
  Offset      : Byte;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  if ( Compressed <> nil ) then
    ReallocMem( Compressed, 0 );

  OutSize := {$IFDEF UNDERSCORE}_LZ4_compressBound{$ELSE}LZ4_compressBound{$ENDIF}( Len );
  if Header then
    Offset := SizeOf( Len )+HEADER_HC_LEN_
  else
    Offset := SizeOf( Len );
  ReallocMem( Compressed, OutSize+Offset );

  bCompressed := Compressed;

  if Header then
    begin
    Move( HEADER_HC_[ 1 ], bCompressed^, HEADER_HC_LEN_ );
    Inc( bCompressed, HEADER_HC_LEN_ );
    end;
  Move( Len, bCompressed^, SizeOf( Len ) );
  Inc( bCompressed, SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4_compress_HC{$ELSE}LZ4_compress_HC{$ENDIF}( Source, bCompressed, Len, OutSize, CompressionLevel );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );
    if ( Result <> OutSize+Offset ) then
      ReallocMem( Compressed, Result );
    end
  else
    ReallocMem( Compressed, 0 );
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CompressLZ4_Frame( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64;
var
  OutSize : Integer;
  Offset  : Byte;
  Prefs   : LZ4F_preferences_t;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  SetLength( Compressed, 0 );

  FillChar( Prefs, SizeOf( Prefs ), 0 );
  Prefs.compressionLevel := CompressionLevel;
  OutSize := {$IFDEF UNDERSCORE}_LZ4F_compressFrameBound{$ELSE}LZ4F_compressFrameBound{$ENDIF}( Len, @Prefs );
  if Header then
    Offset := SizeOf( Len )+HEADER_FRAME_LEN_
  else
    Offset := SizeOf( Len );
  SetLength( Compressed, OutSize+Offset );

  if Header then
    begin
    Move( HEADER_FRAME_[ 1 ], Compressed[ 0 ], HEADER_FRAME_LEN_ );
    Move( Len, Compressed[ HEADER_FRAME_LEN_ ], SizeOf( Len ) );
    end
  else
    Move( Len, Compressed[ 0 ], SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4F_compressFrame{$ELSE}LZ4F_compressFrame{$ENDIF}( @Compressed[ Offset ], OutSize, Source, Len, @Prefs );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );

    if ( Result <> OutSize+Offset ) then
      SetLength( Compressed, Result );
    end
  else
    begin
    SetLength( Compressed, 0 );
    result := {$IFDEF UNDERSCORE}_LZ4F_isError{$ELSE}LZ4F_isError{$ENDIF}( result );
    end;
end;

function CompressLZ4_Frame( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64;
var
  bCompressed : PByte;
  OutSize     : Integer;
  Offset      : Byte;
  Prefs   : LZ4F_preferences_t;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  if ( Compressed <> nil ) then
    ReallocMem( Compressed, 0 );

  FillChar( Prefs, SizeOf( Prefs ), 0 );
  Prefs.compressionLevel := CompressionLevel;
  OutSize := {$IFDEF UNDERSCORE}_LZ4F_compressFrameBound{$ELSE}LZ4F_compressFrameBound{$ENDIF}( Len, @Prefs );
  if Header then
    Offset := SizeOf( Len )+HEADER_FRAME_LEN_
  else
    Offset := SizeOf( Len );
  ReallocMem( Compressed, OutSize+Offset );

  bCompressed := Compressed;

  if Header then
    begin
    Move( HEADER_FRAME_[ 1 ], bCompressed^, HEADER_FRAME_LEN_ );
    Inc( bCompressed, HEADER_FRAME_LEN_ );
    end;
  Move( Len, bCompressed^, SizeOf( Len ) );
  Inc( bCompressed, SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4F_compressFrame{$ELSE}LZ4F_compressFrame{$ENDIF}( bCompressed, OutSize, Source, Len, @Prefs );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );
    if ( Result <> OutSize+Offset ) then
      ReallocMem( Compressed, Result );
    end
  else
    begin
    ReallocMem( Compressed, 0 );
    result := {$IFDEF UNDERSCORE}_LZ4F_isError{$ELSE}LZ4F_isError{$ENDIF}( result );
    end;
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ExtractLZ4( Source : PByte; Len : Cardinal; var Decompressed : TByteDynArray ) : Int64;
var
  OutSize : Cardinal;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  SetLength( Decompressed, 0 );

  if ( pHeaderHC( Source )^ = HEADER_HC_ ) then
    begin
    Inc( Source, HEADER_HC_LEN_ );
    Dec( Len, HEADER_HC_LEN_ );
    end
  else if ( pHeaderFrame( Source )^ = HEADER_FRAME_ ) then
    begin
    result := ExtractLZ4( Source, Len, Decompressed );
    Exit;
    end
  else if ( pHeader( Source )^ = HEADER_ ) then
    begin
    Inc( Source, HEADER_LEN_ );
    Dec( Len, HEADER_LEN_ );
    end;

  OutSize := PCardinal( Source )^; // Len*4;
  Inc( Source, SizeOf( OutSize ) );
  Dec( Len, SizeOf( OutSize ) );
  SetLength( Decompressed, OutSize );

  result := {$IFDEF UNDERSCORE}_LZ4_decompress_safe{$ELSE}LZ4_decompress_safe{$ENDIF}( Source, @Decompressed[ 0 ], Len, OutSize );
  // decompress_fast returns the amount of READ bytes - not the output size
//  result := {$IFDEF UNDERSCORE}_LZ4_decompress_fast{$ELSE}LZ4_decompress_fast{$ENDIF}( Source, @Decompressed[ 0 ], OutSize );
  if ( result <= 0 ) then
    begin
    SetLength( Decompressed, 0 );
    Exit;
    end;

//  result  := OutSize;
end;

function ExtractLZ4( Source : PByte; Len : Cardinal; var Decompressed : Pointer ) : Int64;
var
  OutSize : Cardinal;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  if ( Decompressed <> nil ) then
    ReallocMem( Decompressed, 0 );

  if ( pHeaderHC( Source )^ = HEADER_HC_ ) then
    begin
    Inc( Source, HEADER_HC_LEN_ );
    Dec( Len, HEADER_HC_LEN_ );
    end
  else if ( pHeaderFrame( Source )^ = HEADER_FRAME_ ) then
    begin
    result := ExtractLZ4_Frame( Source, Len, Decompressed );
    Exit;
    end
  else if ( pHeader( Source )^ = HEADER_ ) then
    begin
    Inc( Source, HEADER_LEN_ );
    Dec( Len, HEADER_LEN_ );
    end;

  OutSize := PCardinal( Source )^; // Len*4;
  Inc( Source, SizeOf( OutSize ) );
  Dec( Len, SizeOf( OutSize ) );  
  GetMem( Decompressed, OutSize );

  result := {$IFDEF UNDERSCORE}_LZ4_decompress_safe{$ELSE}LZ4_decompress_safe{$ENDIF}( Source, Decompressed, Len, OutSize );
  // decompress_fast returns the amount of READ bytes - not the output size
//  result := {$IFDEF UNDERSCORE}_LZ4_decompress_fast{$ELSE}LZ4_decompress_fast{$ENDIF}( Source, Decompressed, OutSize );                 
  if ( result <= 0 ) then
    begin
    ReallocMem( Decompressed, 0 );
    Exit;
    end;

//  result  := OutSize;
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ExtractLZ4_Frame( Source : PByte; Len : Cardinal; var Decompressed : TByteDynArray ) : Int64;
var
  OutSize : Cardinal;
  ctx     : PLZ4F_dctx;
  Opts    : LZ4F_decompressOptions_t;  
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  SetLength( Decompressed, 0 );

  if ( pHeaderHC( Source )^ = HEADER_HC_ ) then
    begin
    result := ExtractLZ4( Source, Len, Decompressed );
    Exit;
    end
  else if ( pHeaderFrame( Source )^ = HEADER_FRAME_ ) then
    begin
    Inc( Source, HEADER_FRAME_LEN_ );
    Dec( Len, HEADER_FRAME_LEN_ );
    end    
  else if ( pHeader( Source )^ = HEADER_ ) then
    begin
    result := ExtractLZ4( Source, Len, Decompressed );
    Exit;
    end;

  OutSize := PCardinal( Source )^; // Len*4;
  Inc( Source, SizeOf( OutSize ) );
  Dec( Len, SizeOf( OutSize ) );

  result := {$IFNDEF UNDERSCORE}LZ4F_createDecompressionContext{$ELSE}_LZ4F_createDecompressionContext{$ENDIF}( @ctx, LZ4F_VERSION );
  result := {$IFNDEF UNDERSCORE}LZ4F_isError{$ELSE}_LZ4F_isError{$ENDIF}( result );
  if ( result <> Cardinal( LZ4F_OK_NoError ) ) then
    Exit;  
    
  SetLength( Decompressed, OutSize );    

  FillChar( Opts, SizeOf( Opts ), 0 );
  result := {$IFDEF UNDERSCORE}_LZ4F_decompress{$ELSE}LZ4F_decompress{$ENDIF}( ctx, @Decompressed[ 0 ], @OutSize, Source, @Len, @Opts );
  if ( result > 0 ) then
    SetLength( Decompressed, 0 )
  else
    result := OutSize;
    
  {result := }{$IFNDEF UNDERSCORE}LZ4F_freeDecompressionContext{$ELSE}_LZ4F_freeDecompressionContext{$ENDIF}( ctx );
end;

function ExtractLZ4_Frame( Source : PByte; Len : Cardinal; var Decompressed : Pointer ) : Int64;
var
  OutSize : Cardinal;
  ctx     : PLZ4F_dctx;  
  Opts    : LZ4F_decompressOptions_t;
begin
  result := -200;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  if ( Decompressed <> nil ) then
    ReallocMem( Decompressed, 0 );

  if ( pHeaderHC( Source )^ = HEADER_HC_ ) then
    begin
    Inc( Source, HEADER_HC_LEN_ );
    Dec( Len, HEADER_HC_LEN_ );
    end
  else if ( pHeaderFrame( Source )^ = HEADER_FRAME_ ) then
    begin
    Inc( Source, HEADER_FRAME_LEN_ );
    Dec( Len, HEADER_FRAME_LEN_ );
    end
  else if ( pHeader( Source )^ = HEADER_ ) then
    begin
    Inc( Source, HEADER_LEN_ );
    Dec( Len, HEADER_LEN_ );
    end;

  OutSize := PCardinal( Source )^; // Len*4;
  Inc( Source, SizeOf( OutSize ) );
  Dec( Len, SizeOf( OutSize ) );  
  
  result := {$IFNDEF UNDERSCORE}LZ4F_createDecompressionContext{$ELSE}_LZ4F_createDecompressionContext{$ENDIF}( @ctx, LZ4F_VERSION );
  result := {$IFNDEF UNDERSCORE}LZ4F_isError{$ELSE}_LZ4F_isError{$ENDIF}( result );
  if ( result <> Cardinal( LZ4F_OK_NoError ) ) then  
    Exit;    
  
  GetMem( Decompressed, OutSize );

  FillChar( Opts, SizeOf( Opts ), 0 );
  result := {$IFDEF UNDERSCORE}_LZ4F_decompress{$ELSE}LZ4F_decompress{$ENDIF}( ctx, Decompressed, @OutSize, Source, @Len, @Opts );
  // decompress_fast returns the amount of READ bytes - not the output size
//  result := {$IFDEF UNDERSCORE}_LZ4_decompress_fast{$ELSE}LZ4_decompress_fast{$ENDIF}( Source, Decompressed, OutSize );                 
  if ( result > 0 ) then
    ReallocMem( Decompressed, 0 )
  else
    result := OutSize;    
    
  {result := }{$IFNDEF UNDERSCORE}LZ4F_freeDecompressionContext{$ELSE}_LZ4F_freeDecompressionContext{$ENDIF}( ctx );    
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{$IFDEF TESTCASE}
function TestLZ4( FileName : string; Mode : Byte = 0; Header : boolean = False; SaveDebugFiles : Boolean = False ) : Int64;
var
  sIn : TMemoryStream;

  function PointerToArray : Int64;
  var
    sCompress, sOut : TMemoryStream;
    aDecompressed : TByteDynArray;
    S : String;
  begin
    SetLength( aDecompressed, 0 );

    sCompress := TMemoryStream.Create;
    if ( Mode = 1 ) then
      result := CompressLZ4_HC( sIn.Memory, sIn.Size, aDecompressed, Header )
    else if ( Mode = 2 ) then
      result := CompressLZ4_Frame( sIn.Memory, sIn.Size, aDecompressed, Header )
    else
      result := CompressLZ4( sIn.Memory, sIn.Size, aDecompressed, Header );
    if ( result <= 0 ) then
      begin
      sCompress.free;
      result := -3;
      Exit;
      end;

    sCompress.Write( aDecompressed[ 0 ], Length( aDecompressed ) );
    SetLength( aDecompressed, 0 );
    if SaveDebugFiles then
      begin
      if ( Mode = 2 ) then
        S := ChangeFileExt( FileName, '.LZ4F' )
      else if ( Mode = 1 ) then
        S := ChangeFileExt( FileName, '.LZ4HC' )
      else
        S := ChangeFileExt( FileName, '.LZ4' );
      sCompress.SaveToFile( S );
      end;

    sOut := TMemoryStream.Create;
    sCompress.Position := 0;
    SetLength( aDecompressed, 0 );
    if ( Mode = 2 ) then
      result := ExtractLZ4_Frame( sCompress.Memory, sCompress.Size, aDecompressed )
    else
      result := ExtractLZ4( sCompress.Memory, sCompress.Size, aDecompressed );
    if ( result <= 0 ) then
      begin
      sOut.free;
      sCompress.free;
      result := -2;
      Exit;
      end;
    sOut.Write( aDecompressed[ 0 ], Length( aDecompressed ) );
    SetLength( aDecompressed, 0 );

    if ( sIn.Size <> sOut.Size ) OR NOT CompareMem( sIn.Memory, sOut.Memory, sIn.Size ) then
      result := -1;
    if SaveDebugFiles then
      sOut.SaveToFile( ChangeFileExt( FileName, '.extract' ) );

    sOut.free;
    sCompress.free;
  end;

  function PointerToPointer : Int64;
  var
    sCompress, sOut : TMemoryStream;
    pDecompressed : Pointer;
    S : String;
  begin
    pDecompressed := nil;

    sCompress := TMemoryStream.Create;
    if ( Mode = 1 ) then
      result := CompressLZ4_HC( sIn.Memory, sIn.Size, pDecompressed, Header )
    else if ( Mode = 2 ) then
      result := CompressLZ4_Frame( sIn.Memory, sIn.Size, pDecompressed, Header )
    else
      result := CompressLZ4( sIn.Memory, sIn.Size, pDecompressed, Header );
    if ( result <= 0 ) then
      begin
      sCompress.free;
      result := -3;
      Exit;
      end;

    sCompress.Write( pDecompressed^, result );
    ReallocMem( pDecompressed, 0 );
    if SaveDebugFiles then
      begin
      if ( Mode = 2 ) then
        S := ChangeFileExt( FileName, '.LZ4F' )
      else if ( Mode = 1 ) then
        S := ChangeFileExt( FileName, '.LZ4HC' )
      else
        S := ChangeFileExt( FileName, '.LZ4' );
      sCompress.SaveToFile( S );
      end;

    sOut := TMemoryStream.Create;
    sCompress.Position := 0;
    pDecompressed := nil;
    if ( Mode = 2 ) then
      result := ExtractLZ4_Frame( sCompress.Memory, sCompress.Size, pDecompressed )
    else
      result := ExtractLZ4( sCompress.Memory, sCompress.Size, pDecompressed );
    if ( result <= 0 ) then
      begin
      sOut.free;
      sCompress.free;
      result := -2;
      Exit;
      end;
    sOut.Write( PByte( pDecompressed )^, result );
    ReallocMem( pDecompressed, 0 );

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

  result := PointerToArray;
  case result of
  -999 : ShowMessage( 'PointerToArray: Invalid File' );
    -3 : ShowMessage( 'PointerToArray: Failed compress' );
    -2 : ShowMessage( 'PointerToArray: Failed decompress' );
    -1 : ShowMessage( 'PointerToArray: Size invalid or CompareMem failed' );
     0 : ShowMessage( 'PointerToArray: Failed to Extract' );
//    else
//       ShowMessage( 'PointerToArray: OK' );
  end;
  if ( result < 0 ) then
    begin
    sIn.Free;
    Exit;
    end;

  result := PointerToPointer;
  case result of
  -999 : ShowMessage( 'PointerToPointer: Invalid File' );
    -3 : ShowMessage( 'PointerToPointer: Failed compress' );
    -2 : ShowMessage( 'PointerToPointer: Failed decompress' );
    -1 : ShowMessage( 'PointerToPointer: Size invalid or CompareMem failed' );
     0 : ShowMessage( 'PointerToPointer: Failed to Extract' );
//    else
//       ShowMessage( 'PointerToPointer: OK' );
  end;
  if ( result < 0 ) then
    begin
    sIn.Free;
    Exit;
    end;
  sIn.free;
end;
{$ENDIF TESTCASE}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

initialization
  TestLZ4( ParamStr( 0 ) + '_', 2, True, True );

end.
