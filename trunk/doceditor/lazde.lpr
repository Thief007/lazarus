program lazde;

{$mode objfpc}{$H+}

uses
  interfaces, // this includes the LCL widgetset
  forms, frmmain, frmOptions, frmNewNode, frmmakeskel,
  frmLink, frmTable, frmabout, pkeditor, eleditor, fpdeutil, frmexample,
  frmbuild, fmmakeskel, frmsource, lazdemsg, lazdeopts, pgeditor;

begin
  Application.Title:='Lazarus Documentation Editor';
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

