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
unit editor_codefolding_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, StdCtrls, ExtCtrls, Graphics,
  LCLType, EditorOptions, LazarusIDEStrConsts, IDEOptionsIntf, Controls,
  SynEditHighlighter, Spin, ComCtrls, ColorBox;

type

  { TEditorCodefoldingOptionsFrame }

  TEditorCodefoldingOptionsFrame = class(TAbstractIDEOptionsEditor)
    Bevel1: TBevel;
    TopLvlPanel: TPanel;
    TopLvlColorCheckBox: TCheckBox;
    NestLvlColorCheckBox: TCheckBox;
    TopLvlColorBox: TColorBox;
    NestLvlColorBox: TColorBox;
    DividerOnOffCheckBox: TCheckBox;
    chkCodeFoldingEnabled: TCheckBox;
    DividerSpinLabel: TLabel;
    TopLvlColorLabel: TLabel;
    NestLvlColorLabel: TLabel;
    LanguageComboBox: TComboBox;
    LanguageLabel: TLabel;
    FoldConfigListBox: TListBox;
    DividerConfPanel: TPanel;
    DividerSpinPanel: TPanel;
    DividerBoolPanel: TPanel;
    DividerSpinEdit: TSpinEdit;
    NestLvlPanel: TPanel;
    procedure DividerOnOffCheckBoxChange(Sender: TObject);
    procedure DividerSpinEditChange(Sender: TObject);
    procedure FoldConfigListBoxClick(Sender: TObject);
    procedure FoldConfigListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure LanguageComboBoxChange(Sender: TObject);
    procedure LanguageComboBoxExit(Sender: TObject);
    procedure LanguageComboBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NestLvlColorBoxChange(Sender: TObject);
    procedure NestLvlColorCheckBoxChange(Sender: TObject);
    procedure TopLvlColorBoxChange(Sender: TObject);
    procedure TopLvlColorCheckBoxChange(Sender: TObject);
  private
    { private declarations }
    FHighlighters: array[TLazSyntaxHighlighter] of TSrcIDEHighlighter;
    FCurHighlighter: TSrcIDEHighlighter;
    FCurDividerConf: TSynDividerDrawConfig;
    FCurInfo: TEditorOptionsDividerRecord;
  protected
    function GetHighlighter(SynType: TLazSyntaxHighlighter;
      CreateIfNotExists: Boolean): TSrcIDEHighlighter;
    procedure ClearHighlighters;
  public
    destructor Destroy; override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TEditorCodefoldingOptionsFrame }

procedure TEditorCodefoldingOptionsFrame.LanguageComboBoxChange(Sender: TObject);
var
  ComboBox: TComboBox absolute Sender;
begin
  if ComboBox.Items.IndexOf(ComboBox.Text) >= 0 then
    LanguageComboBoxExit(Sender);
end;

procedure TEditorCodefoldingOptionsFrame.LanguageComboBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = VK_S) then
    LanguageComboBoxExit(Sender);
end;

procedure TEditorCodefoldingOptionsFrame.LanguageComboBoxExit(Sender: TObject);
var
  ComboBox: TComboBox absolute Sender;
  i: Integer;
  tp: TLazSyntaxHighlighter;
begin
  tp := EditorOpts.HighlighterList
          [EditorOpts.HighlighterList.FindByName(ComboBox.Text)].TheType;
  FCurHighlighter := GetHighlighter(tp, True);
  FCurInfo := EditorOptionsDividerDefaults[tp];
  FoldConfigListBox.Clear;
  for i := 0 to FCurInfo.Count - 1 do
    FoldConfigListBox.Items.add(FCurInfo.Info^[i].Name);
  FoldConfigListBox.ItemIndex := 0;
  FoldConfigListBoxSelectionChange(Sender, True);
end;

procedure TEditorCodefoldingOptionsFrame.FoldConfigListBoxClick(Sender: TObject);
begin
  FoldConfigListBoxSelectionChange(Sender, True);
end;

procedure TEditorCodefoldingOptionsFrame.FoldConfigListBoxSelectionChange(Sender: TObject; User: boolean);
var
  ListBox: TListBox absolute Sender;
  i: LongInt;
  NewDiv: TSynDividerDrawConfig;
  b: Boolean;
begin
  if not assigned(FCurHighlighter) then exit;
  i := ListBox.ItemIndex;
  if (i < 0) or (i >= FCurInfo.Count) then exit;
  NewDiv := FCurHighlighter.DividerDrawConfig[i];
  FCurDividerConf := nil;

  b := FCurInfo.Info^[i].BoolOpt;
  DividerBoolPanel.Visible := b;
  DividerSpinPanel.Visible := not b;
  NestLvlPanel.Visible := not b;
  DividerOnOffCheckBox.Checked := NewDiv.MaxDrawDepth > 0;
  DividerSpinEdit.Value := NewDiv.MaxDrawDepth;

  TopLvlColorBox.Selected := NewDiv.TopColor;
  TopLvlColorBox.Tag := TopLvlColorBox.Selected;
  TopLvlColorCheckBox.Checked := NewDiv.TopColor = clDefault;
  TopLvlPanel.Enabled := NewDiv.MaxDrawDepth > 0;

  NestLvlColorBox.Selected := NewDiv.NestColor;
  NestLvlColorBox.Tag := NestLvlColorBox.Selected;
  NestLvlColorCheckBox.Checked := NewDiv.NestColor = clDefault;
  NestLvlPanel.Enabled := NewDiv.MaxDrawDepth > 1;

  FCurDividerConf := NewDiv;
end;

procedure TEditorCodefoldingOptionsFrame.DividerOnOffCheckBoxChange(Sender: TObject);
var
  Box: TCheckBox absolute Sender;
begin
  if not assigned(FCurDividerConf) then exit;
  if Box.Checked then
    FCurDividerConf.MaxDrawDepth := 1
  else
    FCurDividerConf.MaxDrawDepth := 0;
  TopLvlPanel.Enabled := FCurDividerConf.MaxDrawDepth > 0;
end;

procedure TEditorCodefoldingOptionsFrame.DividerSpinEditChange(Sender: TObject);
var
  Spin: TSpinEdit absolute Sender;
begin
  if not assigned(FCurDividerConf) then exit;
  FCurDividerConf.MaxDrawDepth := Spin.Value;
  TopLvlPanel.Enabled := FCurDividerConf.MaxDrawDepth > 0;
  NestLvlPanel.Enabled := FCurDividerConf.MaxDrawDepth > 1;
end;

procedure TEditorCodefoldingOptionsFrame.NestLvlColorBoxChange(Sender: TObject);
begin
  if not assigned(FCurDividerConf) then exit;
  FCurDividerConf.NestColor := NestLvlColorBox.Selected;
  if NestLvlColorBox.Selected <> clDefault then
    NestLvlColorBox.Tag := NestLvlColorBox.Selected;
  NestLvlColorCheckBox.Checked := NestLvlColorBox.Selected = clDefault;
end;

procedure TEditorCodefoldingOptionsFrame.NestLvlColorCheckBoxChange(Sender: TObject);
begin
  if not assigned(FCurDividerConf) then exit;
  if NestLvlColorCheckBox.Checked then begin
    FCurDividerConf.NestColor := clDefault;
    if NestLvlColorBox.Selected <> clDefault then
      NestLvlColorBox.Selected := clDefault;
  end else begin
    FCurDividerConf.NestColor := NestLvlColorBox.Tag;
    if NestLvlColorBox.Selected <> NestLvlColorBox.Tag then
      NestLvlColorBox.Selected := NestLvlColorBox.Tag;
  end;
end;

procedure TEditorCodefoldingOptionsFrame.TopLvlColorBoxChange(Sender: TObject);
begin
  if not assigned(FCurDividerConf) then exit;
  FCurDividerConf.TopColor := TopLvlColorBox.Selected;
  if TopLvlColorBox.Selected <> clDefault then
    TopLvlColorBox.Tag := TopLvlColorBox.Selected;
  TopLvlColorCheckBox.Checked := TopLvlColorBox.Selected = clDefault;
end;

procedure TEditorCodefoldingOptionsFrame.TopLvlColorCheckBoxChange(Sender: TObject);
begin
  if not assigned(FCurDividerConf) then exit;
  if TopLvlColorCheckBox.Checked then begin
    FCurDividerConf.TopColor := clDefault;
    if TopLvlColorBox.Selected <> clDefault then
      TopLvlColorBox.Selected := clDefault;
  end else begin
    FCurDividerConf.TopColor := TopLvlColorBox.Tag;
    if TopLvlColorBox.Selected <> TopLvlColorBox.Tag then
      TopLvlColorBox.Selected := TopLvlColorBox.Tag;
  end;
end;

function TEditorCodefoldingOptionsFrame.GetHighlighter(SynType: TLazSyntaxHighlighter;
  CreateIfNotExists: Boolean): TSrcIDEHighlighter;
var
  SynClass: TCustomSynClass;
  i: Integer;
begin
  Result := FHighlighters[SynType];
  if (Result <> nil) or not(CreateIfNotExists) then exit;

  SynClass := LazSyntaxHighlighterClasses[SynType];
  Result := SynClass.Create(nil);
  FHighlighters[SynType] := Result;
  EditorOpts.ReadHighlighterFoldSettings(Result);
end;

procedure TEditorCodefoldingOptionsFrame.ClearHighlighters;
var
  i: TLazSyntaxHighlighter;
begin
  for i := low(TLazSyntaxHighlighter) to high(TLazSyntaxHighlighter) do
    FreeAndNil(FHighlighters[i]);
end;

destructor TEditorCodefoldingOptionsFrame.Destroy;
begin
  ClearHighlighters;
  inherited Destroy;
end;

function TEditorCodefoldingOptionsFrame.GetTitle: String;
begin
  Result := dlgUseCodeFolding;
end;

procedure TEditorCodefoldingOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  chkCodeFoldingEnabled.Caption := dlgUseCodeFolding;
  LanguageLabel.Caption := dlgLang;
  DividerSpinLabel.Caption := dlgDividerDrawDepth;
  DividerOnOffCheckBox.Caption := dlgDividerOnOff;
  TopLvlColorLabel.Caption := dlgDividerTopColor;
  TopLvlColorCheckBox.Caption := dlgDividerTopColorDefault;
  NestLvlColorLabel.Caption := dlgDividerNestColor;
  NestLvlColorCheckBox.Caption := dlgDividerNestColorDefault;
end;

procedure TEditorCodefoldingOptionsFrame.ReadSettings(
  AOptions: TAbstractIDEOptions);
var
  i: Integer;
  r: TEditorOptionsDividerRecord;
begin
  with AOptions as TEditorOptions do
  begin
    chkCodeFoldingEnabled.Checked := UseCodeFolding;

    with LanguageComboBox.Items do begin
      BeginUpdate;
      for i := 0 to EditorOpts.HighlighterList.Count - 1 do begin
        r := EditorOptionsDividerDefaults[HighlighterList[i].TheType];
        if r.Count > 0 then
          Add(HighlighterList[i].SynClass.GetLanguageName);
      end;
      EndUpdate;
    end;
    LanguageComboBox.ItemIndex := 0;
    LanguageComboBoxExit(LanguageComboBox);
  end;
end;

procedure TEditorCodefoldingOptionsFrame.WriteSettings(
  AOptions: TAbstractIDEOptions);
var
  i: TLazSyntaxHighlighter;
begin
  with AOptions as TEditorOptions do
  begin
    UseCodeFolding := chkCodeFoldingEnabled.Checked;
    for i := low(TLazSyntaxHighlighter) to high(TLazSyntaxHighlighter) do begin
      if assigned(FHighlighters[i]) then
         WriteHighlighterFoldSettings(FHighlighters[i]);
    end;
  end;
end;

class function TEditorCodefoldingOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEditorOptions;
end;

initialization
  {$I editor_codefolding_options.lrs}
  RegisterIDEOptionsEditor(GroupEditor, TEditorCodefoldingOptionsFrame, EdtOptionsCodeFolding);
end.

