program lz4d_test;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  lz4d      in 'lz4d.pas',
  lz4d.lz4  in 'lz4d.lz4.pas',
  lz4d.lz4s in 'lz4d.lz4s.pas',
  lz4d.test in 'lz4d.test.pas';


var
  LFileStream:  TFileStream;
  LMemStream:   TMemoryStream;

  LDummy:       String;

begin
  //preperations
  // - we want 16byte block alignement
  SetMinimumBlockAlignment(mba16Byte);


  Writeln('LZ4 Delphi Binding Library Test');

  if (System.ParamCount < 1) then
  begin
    Writeln('Source file needed for test.');
    writeln('Usage: pmLZ4Test.exe testfile');
    Exit();
  end;

  if not FileExists(System.ParamStr(1)) then
  begin
    Writeln('File not found. Please use valid test file.');
    Exit();
  end;

  //file access via stream
  try
    try
      //create file stream of test data
      LFileStream := TFileStream.Create(System.ParamStr(1), fmOpenRead);

      //read data into memory
      LMemStream  := TMemoryStream.Create();
      LMemStream.CopyFrom( LFileStream, 0 );

      LFileStream.Free;

      //work the memory
      lz4dtest( LMemStream );

      //cleanup
      LMemStream.Free;
    except
      on E: Exception do
        Writeln('Exception on testing: ' + E.ToString());
    end;
  finally

  end;

  System.Writeln(' Press Return to Exit ');
  System.Readln(LDummy);
end.
