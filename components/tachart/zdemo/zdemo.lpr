program zdemo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms
  { you can add units after this }, main, LResources, TAChartLazarusPkg;

{$IFDEF WINDOWS}{$R zdemo.rc}{$ENDIF}

begin
  Application.Title := 'TAChart 3D look demo';
  {$I zdemo.lrs}
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

