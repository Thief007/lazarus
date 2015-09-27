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

  Author: Mattias Gaertner

  Abstract:
    IDE option frame for Messages window.
}
unit MsgWnd_Options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LazLoggerBase, SynEdit, Forms,
  Controls, Graphics, Dialogs, StdCtrls, ColorBox, ExtCtrls, Spin, ComCtrls,
  IDEOptionsIntf, IDEExternToolIntf,
  LazarusIDEStrConsts, EnvironmentOpts, editor_general_options, EditorOptions;

type

  { TMsgWndOptionsFrame }

  TMsgWndOptionsFrame = class(TAbstractIDEOptionsEditor)
    MsgColorBox: TColorBox;
    MsgColorListBox: TColorListBox;
    MsgColorGroupBox: TGroupBox;
    MWAlwaysDrawFocusedCheckBox: TCheckBox;
    MWFocusCheckBox: TCheckBox;
    MWSetPastelColorsButton: TButton;
    MWShowFPCMsgLinesCompiledCheckBox: TCheckBox;
    MWShowIconsCheckBox: TCheckBox;
    MWMaxProcsLabel: TLabel;
    MWMaxProcsSpinEdit: TSpinEdit;
    MWOptsLeftBevel: TBevel;
    MWColorBox: TColorBox;
    MWColorListBox: TColorListBox;
    MWColorsGroupBox: TGroupBox;
    MWOptionsLabel: TLabel;
    MWOptsRightBevel: TBevel;
    MWSetDefaultColorsButton: TButton;
    MWSetEditorColorsButton: TButton;
    MWSpeedSetColorsGroupBox: TGroupBox;
    Notebook1: TNotebook;
    PageHeader: TPage;
    PageMsg: TPage;
    ToolBar1: TToolBar;
    BtnHeaderColor: TToolButton;
    BtnMsgColor: TToolButton;
    procedure BtnHeaderColorClick(Sender: TObject);
    procedure BtnMsgColorClick(Sender: TObject);
    procedure MsgColorBoxChange(Sender: TObject);
    procedure MsgColorListBoxGetColors(Sender: TCustomColorListBox; Items: TStrings);
    procedure MsgColorListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure MWColorBoxChange(Sender: TObject);
    procedure MWColorListBoxGetColors(Sender: TCustomColorListBox;
      Items: TStrings);
    procedure MWColorListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure MWSetDefaultColorsButtonClick(Sender: TObject);
    procedure MWSetEditorColorsButtonClick(Sender: TObject);
    procedure MWSetPastelColorsButtonClick(Sender: TObject);
  private
    fReady: boolean;
    FDialog: TAbstractOptionsEditorDialog;
    function GeneralPage: TEditorGeneralOptionsFrame;
  public
    constructor Create(AOwner: TComponent); override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

var
  MsgWndOptionsFrame: TMsgWndOptionsFrame;

implementation

{$R *.lfm}

{ TMsgWndOptionsFrame }

procedure TMsgWndOptionsFrame.MWColorListBoxGetColors(
  Sender: TCustomColorListBox; Items: TStrings);
begin
  Items.Add(dlgBackColor);
  Items.Add(lisToolHeaderRunning);
  Items.Add(lisToolHeaderSuccess);
  Items.Add(lisToolHeaderFailed);
  Items.Add(lisToolHeaderScrolledUp);
  Items.Add(dlfMouseSimpleTextSect);
end;

procedure TMsgWndOptionsFrame.MWColorBoxChange(Sender: TObject);
var
  i: Integer;
begin
  i:=MWColorListBox.ItemIndex;
  if not fReady or (i < 0) then
    exit;
  MWColorListBox.Colors[i]:=MWColorBox.Selected;
end;

procedure TMsgWndOptionsFrame.BtnHeaderColorClick(Sender: TObject);
begin
  Notebook1.PageIndex := 0;
end;

procedure TMsgWndOptionsFrame.BtnMsgColorClick(Sender: TObject);
begin
  Notebook1.PageIndex := 1;
end;

procedure TMsgWndOptionsFrame.MsgColorBoxChange(Sender: TObject);
var
  i: Integer;
begin
  i:=MsgColorListBox.ItemIndex;
  if not fReady or (i < 0) then
    exit;
  MsgColorListBox.Colors[i]:=MsgColorBox.Selected;
end;

procedure TMsgWndOptionsFrame.MsgColorListBoxGetColors(Sender: TCustomColorListBox;
  Items: TStrings);
begin
(*
    mluNone,
    mluProgress,  // time and statistics about the run
    mluDebug,     // extreme verbosity, only useful for tool authors
    mluVerbose3,  // all infos
    mluVerbose2,  // almost all infos
    mluVerbose,   // extra infos
    mluHint,      // tool found something unusual
    mluNote,      // maybe wrong or unnecessary
    mluWarning,   // probably something is wrong
    mluImportant, // message has no urgency level, but should be shown
    mluError,     // tool could not finish, some tools can still continue
    mluFatal,     // critical error in input, tool had to abort
    mluPanic      // bug in tool
*)

  Items.Add(dlgMsgWinColorUrgentNone);
  Items.Add(dlgMsgWinColorUrgentProgress);
  Items.Add(dlgMsgWinColorUrgentDebug);
  Items.Add(dlgMsgWinColorUrgentVerbose3);
  Items.Add(dlgMsgWinColorUrgentVerbose2);
  Items.Add(dlgMsgWinColorUrgentVerbose);
  Items.Add(dlgMsgWinColorUrgentHint);
  Items.Add(dlgMsgWinColorUrgentNote);
  Items.Add(dlgMsgWinColorUrgentWarning);
  Items.Add(dlgMsgWinColorUrgentImportant);
  Items.Add(dlgMsgWinColorUrgentError);
  Items.Add(dlgMsgWinColorUrgentFatal);
  Items.Add(dlgMsgWinColorUrgentPanic);
end;

procedure TMsgWndOptionsFrame.MsgColorListBoxSelectionChange(Sender: TObject; User: boolean);
begin
  if not (fReady and User) then
    Exit;
  MsgColorBox.Selected := MsgColorListBox.Selected;
end;

procedure TMsgWndOptionsFrame.MWColorListBoxSelectionChange(Sender: TObject;
  User: boolean);
begin
  if not (fReady and User) then
    Exit;
  MWColorBox.Selected := MWColorListBox.Selected;
end;

procedure TMsgWndOptionsFrame.MWSetDefaultColorsButtonClick(Sender: TObject);
var
  c: TMsgWndColor;
begin
  for c in TMsgWndColor do
    MWColorListBox.Colors[ord(c)]:=MsgWndDefaultColors[c];
  MWColorBox.Selected := MWColorListBox.Selected;
end;

procedure TMsgWndOptionsFrame.MWSetEditorColorsButtonClick(Sender: TObject);
var
  Page: TEditorGeneralOptionsFrame;
begin
  Page:=GeneralPage;
  if Page=nil then exit;

  {MWColorListBox.Colors[mwBackground]:=aSynEdit.Color;
  MWColorListBox.Colors[mwRunning]:=aSynEdit.
  MWColorListBox.Colors[mwSuccess]:=aSynEdit.
  MWColorListBox.Colors[mwFailed]:=aSynEdit.
  MWColorListBox.Colors[mwAutoHeader]:=aSynEdit.}

  MWColorBox.Selected := MWColorListBox.Selected;
end;

procedure TMsgWndOptionsFrame.MWSetPastelColorsButtonClick(Sender: TObject);
begin
  MWColorListBox.Colors[ord(mwBackground)]:=clWindow;
  MWColorListBox.Colors[ord(mwRunning)]   :=TColor($00CBF3FF); // harmonic pastel yellow
  MWColorListBox.Colors[ord(mwSuccess)]   :=TColor($00BEEFC3); // harmonic pastel green
  MWColorListBox.Colors[ord(mwFailed)]    :=TColor($00CCCBFF); // harmonic pastel rose
  MWColorListBox.Colors[ord(mwAutoHeader)]:=TColor($00EEC3BD); // harmonic pastel blue
  MWColorBox.Selected := MWColorListBox.Selected;
end;

function TMsgWndOptionsFrame.GeneralPage: TEditorGeneralOptionsFrame;
begin
  Result:=nil;
  if FDialog<>nil then
    Result := TEditorGeneralOptionsFrame(FDialog.FindEditor(TEditorGeneralOptionsFrame));
end;

constructor TMsgWndOptionsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  MWOptionsLabel.Caption:=lisOptions;
  BtnHeaderColor.Caption := lisHeaderColors;
  BtnMsgColor.Caption := lisMsgColors;
  MWColorsGroupBox.Caption:=dlgColors;
  MsgColorGroupBox.Caption:=dlgColors;
  MWSpeedSetColorsGroupBox.Caption:=lisSetAllColors;
  MWSetDefaultColorsButton.Caption:=lisLazarusDefault;
  MWSetPastelColorsButton.Caption:=lisPastelColors;
  MWSetEditorColorsButton.Caption:=lisEditorColors;
  MWShowIconsCheckBox.Caption:=dlgShowMessagesIcons;
  MWShowIconsCheckBox.Hint:=dlgAnIconForErrorWarningHintIsShown;
  MWAlwaysDrawFocusedCheckBox.Caption:=lisAlwaysDrawSelectedItemsFocused;
  MWAlwaysDrawFocusedCheckBox.Hint:=lisDrawTheSelectionFocusedEvenIfTheMessagesWindowHasN;
  MWFocusCheckBox.Caption:=dlgEOFocusMessagesAfterCompilation;
  MWMaxProcsLabel.Caption:=Format(lisMaximumParallelProcesses0MeansDefault, [
    IntToStr(DefaultMaxProcessCount)]);
  MWShowFPCMsgLinesCompiledCheckBox.Caption:='Show FPC message "lines compiled"';
  MWShowFPCMsgLinesCompiledCheckBox.Hint:='Elevate the message priority to always show it (by default it has low priority "verbose")';
  Notebook1.PageIndex := 0;
end;

function TMsgWndOptionsFrame.GetTitle: String;
begin
  Result:=lisMessagesWindow;
end;

procedure TMsgWndOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  fReady:=false;
  FDialog := ADialog;
  MWSetEditorColorsButton.Visible:=false;
end;

procedure TMsgWndOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  o: TEnvironmentOptions;
  c: TMsgWndColor;
  u: TMessageLineUrgency;
begin
  o:=(AOptions as TEnvironmentOptions);
  for c in TMsgWndColor do
    MWColorListBox.Colors[ord(c)] := o.MsgViewColors[c];
  for u in TMessageLineUrgency do
    MsgColorListBox.Colors[ord(u)] := o.MsgColors[u];
  MWShowIconsCheckBox.Checked := o.ShowMessagesIcons;
  MWAlwaysDrawFocusedCheckBox.Checked := o.MsgViewAlwaysDrawFocused;
  MWFocusCheckBox.Checked := o.MsgViewFocus;
  MWMaxProcsSpinEdit.Value := o.MaxExtToolsInParallel;
  MWShowFPCMsgLinesCompiledCheckBox.Checked := o.MsgViewShowFPCMsgLinesCompiled;
  fReady:=true;
end;

procedure TMsgWndOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
var
  o: TEnvironmentOptions;
  c: TMsgWndColor;
  u: TMessageLineUrgency;
begin
  o:=(AOptions as TEnvironmentOptions);
  for c in TMsgWndColor do
    o.MsgViewColors[c] := MWColorListBox.Colors[ord(c)];
  for u in TMessageLineUrgency do
    o.MsgColors[u] := MsgColorListBox.Colors[ord(u)];
  o.ShowMessagesIcons := MWShowIconsCheckBox.Checked;
  o.MsgViewAlwaysDrawFocused := MWAlwaysDrawFocusedCheckBox.Checked;
  o.MsgViewFocus := MWFocusCheckBox.Checked;
  o.MaxExtToolsInParallel := MWMaxProcsSpinEdit.Value;
  o.MsgViewShowFPCMsgLinesCompiled := MWShowFPCMsgLinesCompiledCheckBox.Checked;
end;

class function TMsgWndOptionsFrame.
  SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEnvironmentOptions;
end;

initialization
  RegisterIDEOptionsEditor(GroupEnvironment, TMsgWndOptionsFrame, EnvOptionsMessages);
end.

