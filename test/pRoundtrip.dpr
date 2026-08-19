program pRoundtrip;
// Functional roundtrip for the LZ4 include (v1.10.0):
// 1) buffer API   CompressLZ4/ExtractLZ4             (block codec)
// 2) buffer API   CompressLZ4_HC/ExtractLZ4          (HC encoder)
// 3) buffer API   CompressLZ4_Frame/ExtractLZ4_Frame (frame API + xxHash)
// 4) stream API   CompressStreamLZ4/ExtractStreamLZ4 (LZ4Stream wrapper)
// Plus an LZ4_versionString check as sync anchor.
{$APPTYPE CONSOLE}

{$IFNDEF Win64} // like LZ4.inc
  {$DEFINE UNDERSCORE}
{$ENDIF}

uses
  SysUtils, Classes, Types,
  lz4d.Imports in '..\lz4d.Imports.pas',
  lz4d.lz4 in '..\lz4d.lz4.pas',
  lz4d.lz4hc in '..\lz4d.lz4hc.pas',
  lz4d.lz4frame in '..\lz4d.lz4frame.pas',
  lz4d.lz4file in '..\lz4d.lz4file.pas',
  xxHash in '..\xxHash.pas',
  lz4d.lz4s in '..\lz4d.lz4s.pas',
  lz4d in '..\lz4d.pas',
  LZ4 in '..\LZ4.pas',
  LZ4Stream in '..\LZ4Stream.pas';

var
  Data, Back: TByteDynArray;
  Comp: TByteDynArray;
  i: Integer;
  n: Int64;
  Fails: Integer = 0;
  InS, OutS, BackS: TMemoryStream;
  Ver: AnsiString;

procedure Check(const aName: string; Cond: Boolean);
begin
  if Cond then
    Writeln('  [ok]   ', aName)
  else
  begin
    Writeln('  [FAIL] ', aName);
    Inc(Fails);
  end;
end;

begin
  try
    Ver := {$IFNDEF UNDERSCORE}LZ4_versionString{$ELSE}_LZ4_versionString{$ENDIF};
    Check('LZ4_versionString = 1.10.0', Ver = '1.10.0');

    // test data: 1 MB, half compressible (pattern), half pseudo-random
    SetLength(Data, 1024 * 1024);
    for i := 0 to High(Data) div 2 do
      Data[i] := Byte(i div 251);
    RandSeed := 42;
    for i := (High(Data) div 2) + 1 to High(Data) do
      Data[i] := Byte(Random(256));

    // --- 1) block API ---
    Comp := nil;
    n := CompressLZ4(@Data[0], Length(Data), Comp, True{Header});
    Check('CompressLZ4 > 0', n > 0);
    if n > 0 then
    begin
      SetLength(Comp, n);
      Back := nil;
      n := ExtractLZ4(@Comp[0], Length(Comp), Back);
      Check('LZ4 roundtrip byte-identical',
        (n = Length(Data)) and CompareMem(@Data[0], @Back[0], Length(Data)));
    end;

    // --- 2) HC API ---
    Comp := nil;
    n := CompressLZ4_HC(@Data[0], Length(Data), Comp, True{Header});
    Check('CompressLZ4_HC > 0', n > 0);
    if n > 0 then
    begin
      SetLength(Comp, n);
      Back := nil;
      n := ExtractLZ4(@Comp[0], Length(Comp), Back);
      Check('LZ4-HC roundtrip byte-identical',
        (n = Length(Data)) and CompareMem(@Data[0], @Back[0], Length(Data)));
    end;

    // --- 3) frame API (incl. xxHash checksums) ---
    Comp := nil;
    n := CompressLZ4_Frame(@Data[0], Length(Data), Comp, True{Header});
    Check('CompressLZ4_Frame > 0', n > 0);
    if n > 0 then
    begin
      SetLength(Comp, n);
      Back := nil;
      n := ExtractLZ4_Frame(@Comp[0], Length(Comp), Back);
      Check('LZ4-Frame roundtrip byte-identical',
        (n = Length(Data)) and CompareMem(@Data[0], @Back[0], Length(Data)));
    end;

    // --- 4) stream API ---
    InS := TMemoryStream.Create;
    OutS := TMemoryStream.Create;
    BackS := TMemoryStream.Create;
    try
      InS.WriteBuffer(Data[0], Length(Data));
      InS.Position := 0;
      n := CompressStreamLZ4(InS, OutS, True{Header});
      Check('CompressStreamLZ4 > 0', n > 0);
      OutS.Position := 0;
      n := ExtractStreamLZ4(OutS, BackS);
      Check('LZ4Stream roundtrip byte-identical',
        (n = Length(Data)) and CompareMem(@Data[0], BackS.Memory, Length(Data)));
    finally
      BackS.Free;
      OutS.Free;
      InS.Free;
    end;

    if Fails = 0 then
      Writeln('ALL OK')
    else
      Writeln(Fails, ' FAILURES');
    ExitCode := Fails;
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
      ExitCode := 99;
    end;
  end;
end.
