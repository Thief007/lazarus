program Docking1;

{$mode objfpc}{$H+}

uses
  Interfaces, // this includes the LCL widgetset
  Forms
  { add your units here }, DockForm1Unit, DockForm2Unit;

begin
  Application.Initialize;
  Application.CreateForm(TDockForm1, DockForm1);
  Application.Run;
end.

