program TestGdbmi;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, TestException, CompileHelpers, TestBase, Testwatches;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

