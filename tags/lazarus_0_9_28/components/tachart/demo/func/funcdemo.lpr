program funcdemo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms
  { you can add units after this }, main, TAChartLazarusPkg;

{$IFDEF WINDOWS}{$R funcdemo.rc}{$ENDIF}

begin
  Application.Title := 'TAChart function series demo';
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

