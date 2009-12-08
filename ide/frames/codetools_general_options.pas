{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************
}
unit codetools_general_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, StdCtrls, Buttons,
  Dialogs,
  IDEDialogs, PathEditorDlg,
  CodeToolsOptions, LazarusIDEStrConsts, IDEOptionsIntf;

type

  { TCodetoolsGeneralOptionsFrame }

  TCodetoolsGeneralOptionsFrame = class(TAbstractIDEOptionsEditor)
    AdjustTopLineDueToCommentCheckBox: TCheckBox;
    IndentOnPasteCheckBox: TCheckBox;
    IndentOnLineBreakCheckBox: TCheckBox;
    IndentContextSensitiveCheckBox: TCheckBox;
    IndentFileButton: TButton;
    CursorBeyondEOLCheckBox: TCheckBox;
    IndentFileEdit: TEdit;
    IndentationGroupBox: TGroupBox;
    JumpCenteredCheckBox: TCheckBox;
    JumpingGroupBox: TGroupBox;
    IndentFileLabel: TLabel;
    SkipForwardDeclarationsCheckBox: TCheckBox;
    SrcPathButton: TSpeedButton;
    SrcPathEdit: TEdit;
    SrcPathGroupBox: TGroupBox;
    procedure IndentOnLineBreakCheckBoxChange(Sender: TObject);
    procedure IndentFileButtonClick(Sender: TObject);
    procedure IndentOnPasteCheckBoxChange(Sender: TObject);
    procedure SrcPathButtonClick(Sender: TObject);
  private
    procedure VisualizeIndentEnabled;
  public
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TCodetoolsGeneralOptionsFrame }

procedure TCodetoolsGeneralOptionsFrame.IndentFileButtonClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    InitIDEFileDialog(OpenDialog);
    OpenDialog.Title:=lisChooseAPascalFileForIndentationExamples;
    OpenDialog.Options:=OpenDialog.Options+[ofFileMustExist];
    if OpenDialog.Execute then
      IndentFileEdit.Text:=OpenDialog.FileName;
  finally
    OpenDialog.Free;
  end;
end;

procedure TCodetoolsGeneralOptionsFrame.IndentOnPasteCheckBoxChange(
  Sender: TObject);
begin
  VisualizeIndentEnabled;
end;

procedure TCodetoolsGeneralOptionsFrame.SrcPathButtonClick(Sender: TObject);
begin
  with TPathEditorDialog.Create(Self) do
  try
    Path := SrcPathEdit.Text;
    Templates:=SetDirSeparators(
        '/home/username/buggypackage'
      );
    if (ShowModal = mrOK) then
      SrcPathEdit.Text := Path;
  finally
    Free;
  end;
end;

procedure TCodetoolsGeneralOptionsFrame.VisualizeIndentEnabled;
var
  e: Boolean;
begin
  e:=IndentOnLineBreakCheckBox.Checked or IndentOnPasteCheckBox.Checked;
  IndentFileLabel.Enabled:=e;
  IndentFileEdit.Enabled:=e;
  IndentFileButton.Enabled:=e;
  IndentContextSensitiveCheckBox.Enabled:=e;
end;

procedure TCodetoolsGeneralOptionsFrame.IndentOnLineBreakCheckBoxChange(
  Sender: TObject);
begin
  VisualizeIndentEnabled;
end;

function TCodetoolsGeneralOptionsFrame.GetTitle: String;
begin
  Result := lisMenuInsertGeneral;
end;

procedure TCodetoolsGeneralOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  with SrcPathGroupBox do
    Caption:=dlgAdditionalSrcPath;

  with JumpingGroupBox do
    Caption:=dlgJumpingETC;

  with AdjustTopLineDueToCommentCheckBox do
    Caption:=dlgAdjustTopLine;

  with JumpCenteredCheckBox do
    Caption:=dlgcentercursorline;

  with CursorBeyondEOLCheckBox do
    Caption:=dlgcursorbeyondeol;

  SkipForwardDeclarationsCheckBox.Caption:=dlgSkipForwardDeclarations;

  IndentationGroupBox.Caption:=lisIndentation;
  IndentOnLineBreakCheckBox.Caption:=lisOnBreakLineIEReturnOrEnterKey;
  IndentOnPasteCheckBox.Caption:=lisOnPasteFromClipboard;
  IndentFileLabel.Caption:=lisExampleFile;
  IndentFileButton.Caption:=lisPathEditBrowse;
  IndentContextSensitiveCheckBox.Caption:=lisContextSensitive;
  IndentContextSensitiveCheckBox.ShowHint:=true;
  IndentContextSensitiveCheckBox.Hint:=
    lisImitateIndentationOfCurrentUnitProjectOrPackage;
end;

procedure TCodetoolsGeneralOptionsFrame.ReadSettings(
  AOptions: TAbstractIDEOptions);
begin
  with AOptions as TCodeToolsOptions do
  begin
    SrcPathEdit.Text := SrcPath;
    AdjustTopLineDueToCommentCheckBox.Checked := AdjustTopLineDueToComment;
    JumpCenteredCheckBox.Checked := JumpCentered;
    CursorBeyondEOLCheckBox.Checked := CursorBeyondEOL;
    SkipForwardDeclarationsCheckBox.Checked := SkipForwardDeclarations;
    IndentOnLineBreakCheckBox.Checked:=IndentOnLineBreak;
    IndentOnPasteCheckBox.Checked:=IndentOnPaste;
    IndentFileEdit.Text:=IndentationFileName;
    IndentContextSensitiveCheckBox.Checked:=IndentContextSensitive;
  end;
  VisualizeIndentEnabled;
end;

procedure TCodetoolsGeneralOptionsFrame.WriteSettings(
  AOptions: TAbstractIDEOptions);
begin
  with AOptions as TCodeToolsOptions do
  begin
    SrcPath := SrcPathEdit.Text;
    AdjustTopLineDueToComment := AdjustTopLineDueToCommentCheckBox.Checked;
    JumpCentered := JumpCenteredCheckBox.Checked;
    CursorBeyondEOL := CursorBeyondEOLCheckBox.Checked;
    SkipForwardDeclarations := SkipForwardDeclarationsCheckBox.Checked;
    IndentOnLineBreak:=IndentOnLineBreakCheckBox.Checked;
    IndentOnPaste:=IndentOnPasteCheckBox.Checked;
    IndentationFileName:=IndentFileEdit.Text;
    IndentContextSensitive:=IndentContextSensitiveCheckBox.Checked;
  end;
end;

class function TCodetoolsGeneralOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TCodeToolsOptions;
end;

initialization
  {$I codetools_general_options.lrs}
  RegisterIDEOptionsEditor(GroupCodetools, TCodetoolsGeneralOptionsFrame, CdtOptionsGeneral);
end.

