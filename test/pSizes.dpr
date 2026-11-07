program pSizes;
// Struct layout guard for the LZ4 include (v1.10.0).
// Expected values come from sizeof() measurements of the C structs (MSVC cl,
// identical on x86+x64 since these are char-array unions) - same pattern as
// the LZMA include (finding LZMA1).
// On an LZ4 update: re-measure the C side and update the constants.
{$APPTYPE CONSOLE}

uses
  lz4d.Imports in '..\lz4d.Imports.pas',
  lz4d.lz4 in '..\lz4d.lz4.pas',
  lz4d.lz4hc in '..\lz4d.lz4hc.pas',
  xxHash in '..\xxHash.pas',
  lz4d.lz4frame in '..\lz4d.lz4frame.pas';

var
  Fails: Integer = 0;

procedure Check(const aName: string; Actual, Expected: Integer);
begin
  if Actual = Expected then
    Writeln('  [ok]   ', aName, ' = ', Actual)
  else
  begin
    Writeln('  [FAIL] ', aName, ' = ', Actual, ', expected ', Expected);
    Inc(Fails);
  end;
end;

begin
  Check('SizeOf(LZ4_stream_t)',            SizeOf(LZ4_stream_t),            16416);
  Check('SizeOf(LZ4_streamDecode_t)',      SizeOf(LZ4_streamDecode_t),      32);
  Check('SizeOf(LZ4_streamHC_t)',          SizeOf(LZ4_streamHC_t),          262200);
  Check('SizeOf(LZ4F_frameInfo_t)',        SizeOf(LZ4F_frameInfo_t),        32);
  Check('SizeOf(LZ4F_preferences_t)',      SizeOf(LZ4F_preferences_t),      56);
  Check('SizeOf(LZ4F_compressOptions_t)',  SizeOf(LZ4F_compressOptions_t),  16);
  Check('SizeOf(LZ4F_decompressOptions_t)', SizeOf(LZ4F_decompressOptions_t), 16);

  if Fails = 0 then
    Writeln('ALL OK')
  else
    Writeln(Fails, ' FAILURES');
  ExitCode := Fails;
end.
