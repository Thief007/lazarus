program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, EasyDockMgr, LResources, fEditorSite, fEditBook;

{$IFDEF WINDOWS}{$R SiteTest.rc}{$ENDIF}

begin
  {$I SiteTest.lrs}
  Application.Initialize;
  Application.CreateForm(TEditorSite, EditorSite);
  Application.Run;
end.

