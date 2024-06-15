program lz4d_test;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  lz4d in '..\..\lz4d.pas',
  lz4d.lz4 in '..\..\lz4d.lz4.pas',
  lz4d.lz4s in '..\..\lz4d.lz4s.pas',
  lz4d.test in '..\lz4d.test.pas';

begin
  Main;
end.
