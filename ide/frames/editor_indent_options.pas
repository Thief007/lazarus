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
unit editor_indent_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LCLType, StdCtrls, Controls, ExtCtrls, Graphics, Forms,
  EditorOptions, LazarusIDEStrConsts, IDEProcs, KeyMapping, editor_keymapping_options,
  IDEOptionsIntf, SynEdit, SynBeautifier, SynHighlighterPas, SynEditKeyCmds, DividerBevel;

type
  TPreviewEditor = TSynEdit;
  { TEditorIndentOptionsFrame }

  TEditorIndentOptionsFrame = class(TAbstractIDEOptionsEditor)
    BlockIndentLink: TLabel;
    BlockIndentComboBox: TComboBox;
    BlockTabIndentComboBox: TComboBox;
    BlockTabIndentLabel: TLabel;
    BlockIndentTypeComboBox: TComboBox;
    BlockIndentLabel: TLabel;
    AutoIndentCheckBox: TCheckBox;
    AutoIndentTypeLabel: TLabel;
    lblBlockIndentShortcut: TLabel;
    TabsGroupDivider: TDividerBevel;
    AutoIndentLink: TLabel;
    CenterLabel:TLabel;
    IndentsGroupDivider: TDividerBevel;
    lblBlockIndentKeys: TLabel;
    TabIndentBlocksCheckBox: TCheckBox;
    SmartTabsCheckBox: TCheckBox;
    TabsToSpacesCheckBox: TCheckBox;
    TabWidthsComboBox: TComboBox;
    TabWidthsLabel: TLabel;
    procedure AutoIndentCheckBoxChange(Sender: TObject);
    procedure AutoIndentLinkClick(Sender: TObject);
    procedure AutoIndentLinkMouseEnter(Sender: TObject);
    procedure AutoIndentLinkMouseLeave(Sender: TObject);
    procedure BlockIndentLinkClick(Sender: TObject);
    procedure ComboboxOnChange(Sender: TObject);
    procedure ComboboxOnKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ComboBoxOnExit(Sender: TObject);
    procedure SmartTabsCheckBoxChange(Sender: TObject);
    procedure TabIndentBlocksCheckBoxChange(Sender: TObject);
    procedure TabsToSpacesCheckBoxChange(Sender: TObject);
  private
    FDefaultBookmarkImages: TImageList;
    FDialog: TAbstractOptionsEditorDialog;
    FPasExtendedKeywordsMode: Boolean;
    FPasStringKeywordMode: TSynPasStringMode;
    function DefaultBookmarkImages: TImageList;
    procedure SetExtendedKeywordsMode(const AValue: Boolean);
    procedure SetStringKeywordMode(const AValue: TSynPasStringMode);
  public
    PreviewEdits: array of TPreviewEditor;
    procedure AddPreviewEdit(AEditor: TPreviewEditor);
    procedure SetPreviewOption(AValue: Boolean; AnOption: TSynEditorOption); overload;
    procedure SetPreviewOption(AValue: Boolean; AnOption: TSynEditorOption2); overload;
    procedure UpdatePrevieEdits;

    constructor Create(AOwner: TComponent); override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
    // current previewmode
    property PasExtendedKeywordsMode: Boolean
             read FPasExtendedKeywordsMode write SetExtendedKeywordsMode default False;
    property PasStringKeywordMode: TSynPasStringMode
             read FPasStringKeywordMode write SetStringKeywordMode default spsmDefault;
  end;

implementation

{$R *.lfm}

{ TEditorIndentOptionsFrame }

function TEditorIndentOptionsFrame.GetTitle: String;
begin
  Result := dlgEdTabIndent;
end;

procedure TEditorIndentOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  FDialog := ADialog;

  // tabs
  TabsGroupDivider.Caption := dlgIndentsTabsGroupOptions;
  TabsToSpacesCheckBox.Caption := dlgTabsToSpaces;
  TabWidthsLabel.Caption := dlgTabWidths;
  SmartTabsCheckBox.Caption := dlgSmartTabs;

  // indents
  IndentsGroupDivider.Caption := dlgIndentsIndentGroupOptions;
  AutoIndentCheckBox.Caption := dlgAutoIndent;
  AutoIndentTypeLabel.Caption := dlgAutoIndentType;

  lblBlockIndentKeys.Caption := dlgBlockIndentKeys;
  lblBlockIndentShortcut.Caption := '';
  BlockIndentLink.Caption := dlgBlockIndentLink;
  BlockIndentLabel.Caption := dlgBlockIndent;
  BlockTabIndentLabel.Caption := dlgBlockTabIndent;

  BlockIndentTypeComboBox.Items.Add(dlgBlockIndentTypeSpace);
  BlockIndentTypeComboBox.Items.Add(dlgBlockIndentTypeCopy);
  BlockIndentTypeComboBox.Items.Add(dlgBlockIndentTypePos);

  TabIndentBlocksCheckBox.Caption := dlgTabIndent;
  AutoIndentLink.Caption := dlgAutoIndentLink;

end;

procedure TEditorIndentOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  i: integer;
  K: TKeyCommandRelation;
begin
  with AOptions as TEditorOptions do
  begin
    SetComboBoxText(BlockIndentComboBox, IntToStr(BlockIndent), cstCaseInsensitive);
    SetComboBoxText(BlockTabIndentComboBox, IntToStr(BlockTabIndent), cstCaseInsensitive);
    SetComboBoxText(TabWidthsComboBox, IntToStr(TabWidth), cstCaseInsensitive);
    BlockIndentTypeComboBox.ItemIndex := ord(BlockIndentType);

    // tabs, indents
    AutoIndentCheckBox.Checked := eoAutoIndent in SynEditOptions;
    TabIndentBlocksCheckBox.Checked := eoTabIndent in SynEditOptions;
    SmartTabsCheckBox.Checked := eoSmartTabs in SynEditOptions;
    TabsToSpacesCheckBox.Checked := eoTabsToSpaces in SynEditOptions;

    for i := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[i] <> nil then
        GetSynEditPreviewSettings(PreviewEdits[i]);

    lblBlockIndentShortcut.Caption := '';
    K := KeyMap.FindByCommand(ecBlockIndent);
    if k <> nil then
      lblBlockIndentShortcut.Caption := lblBlockIndentShortcut.Caption +
        KeyAndShiftStateToEditorKeyString(k.ShortcutA)+ ' / ';
    K := KeyMap.FindByCommand(ecBlockUnindent);
    if k <> nil then
      lblBlockIndentShortcut.Caption := lblBlockIndentShortcut.Caption +
        KeyAndShiftStateToEditorKeyString(k.ShortcutA);
  end;
end;

procedure TEditorIndentOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);

  procedure UpdateOptionFromBool(AValue: Boolean; AnOption: TSynEditorOption); overload;
  begin
    if AValue then
      TEditorOptions(AOptions).SynEditOptions := TEditorOptions(AOptions).SynEditOptions + [AnOption]
    else
      TEditorOptions(AOptions).SynEditOptions := TEditorOptions(AOptions).SynEditOptions - [AnOption];
  end;

  procedure UpdateOptionFromBool(AValue: Boolean; AnOption: TSynEditorOption2); overload;
  begin
    if AValue then
      TEditorOptions(AOptions).SynEditOptions2 := TEditorOptions(AOptions).SynEditOptions2 + [AnOption]
    else
      TEditorOptions(AOptions).SynEditOptions2 := TEditorOptions(AOptions).SynEditOptions2 - [AnOption];
  end;

var
  i: integer;
begin
  with AOptions as TEditorOptions do
  begin
    // tabs, indents
    UpdateOptionFromBool(AutoIndentCheckBox.Checked, eoAutoIndent);
    UpdateOptionFromBool(TabIndentBlocksCheckBox.Checked, eoTabIndent);
    UpdateOptionFromBool(SmartTabsCheckBox.Checked, eoSmartTabs);
    UpdateOptionFromBool(TabsToSpacesCheckBox.Checked, eoTabsToSpaces);

    i := StrToIntDef(TabWidthsComboBox.Text, 2);
    if i < 1 then
      i := 1;
    if i > 20 then
      i := 20;
    TabWidth := i;

    i := StrToIntDef(BlockIndentComboBox.Text, 2);
    if i < 0 then
      i := 0;
    if i > 20 then
      i := 20;
    BlockIndent := i;

    i := StrToIntDef(BlockTabIndentComboBox.Text, 0);
    if i < 0 then
      i := 0;
    if i > 20 then
      i := 20;
    BlockTabIndent := i;

    BlockIndentType := TSynBeautifierIndentType(BlockIndentTypeComboBox.ItemIndex);
  end;
end;

class function TEditorIndentOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEditorOptions;
end;

procedure TEditorIndentOptionsFrame.SetPreviewOption(AValue: Boolean; AnOption: TSynEditorOption);
var
  a: Integer;
begin
  for a := Low(PreviewEdits) to High(PreviewEdits) do
  begin
    if PreviewEdits[a] <> nil then
      if AValue then
        PreviewEdits[a].Options := PreviewEdits[a].Options + [AnOption]
      else
        PreviewEdits[a].Options := PreviewEdits[a].Options - [AnOption];
  end;
end;

procedure TEditorIndentOptionsFrame.SetPreviewOption(AValue: Boolean; AnOption: TSynEditorOption2);
var
  a: Integer;
begin
  for a := Low(PreviewEdits) to High(PreviewEdits) do
  begin
    if PreviewEdits[a] <> nil then
      if AValue then
        PreviewEdits[a].Options2 := PreviewEdits[a].Options2 + [AnOption]
      else
        PreviewEdits[a].Options2 := PreviewEdits[a].Options2 - [AnOption];
  end;
end;

procedure TEditorIndentOptionsFrame.UpdatePrevieEdits;
var
  a: Integer;
begin
  for a := Low(PreviewEdits) to High(PreviewEdits) do
    if PreviewEdits[a].Highlighter is TSynPasSyn then begin
      TSynPasSyn(PreviewEdits[a].Highlighter).ExtendedKeywordsMode := PasExtendedKeywordsMode;
      TSynPasSyn(PreviewEdits[a].Highlighter).StringKeywordMode := PasStringKeywordMode;
    end;
end;

procedure TEditorIndentOptionsFrame.ComboboxOnChange(Sender: TObject);
var
  ComboBox: TComboBox absolute Sender;
begin
  if ComboBox.Items.IndexOf(ComboBox.Text) >= 0 then
    ComboBoxOnExit(Sender);
end;

procedure TEditorIndentOptionsFrame.AutoIndentCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(AutoIndentCheckBox.Checked, eoAutoIndent);
end;

procedure TEditorIndentOptionsFrame.AutoIndentLinkClick(Sender: TObject);
begin
  FDialog.OpenEditor(GroupCodetools,CdtOptionsGeneral);
end;

procedure TEditorIndentOptionsFrame.AutoIndentLinkMouseEnter(Sender: TObject);
begin
  (Sender as TLabel).Font.Underline := True;
  (Sender as TLabel).Font.Color := clRed;
end;

procedure TEditorIndentOptionsFrame.AutoIndentLinkMouseLeave(Sender: TObject);
begin
  (Sender as TLabel).Font.Underline := False;
  (Sender as TLabel).Font.Color := clBlue;
end;

procedure TEditorIndentOptionsFrame.BlockIndentLinkClick(Sender: TObject);
var
  col: TEditorKeymappingOptionsFrame;
begin
  col := TEditorKeymappingOptionsFrame(FDialog.FindEditor(TEditorKeymappingOptionsFrame));
  if col = nil then exit;
  FDialog.OpenEditor(TEditorKeymappingOptionsFrame);
  col.SelectByIdeCommand(ecBlockIndent);
end;

procedure TEditorIndentOptionsFrame.ComboboxOnKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = VK_S) then
    ComboBoxOnExit(Sender);
end;

procedure TEditorIndentOptionsFrame.ComboBoxOnExit(Sender: TObject);
var
  NewVal, a: Integer;
begin
  if Sender = BlockIndentComboBox then
  begin
    NewVal := StrToIntDef(BlockIndentComboBox.Text, PreviewEdits[1].BlockIndent);
    // Todo: min/max
    SetComboBoxText(BlockIndentComboBox, IntToStr(NewVal), cstCaseInsensitive);
    for a := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[a] <> nil then
        PreviewEdits[a].BlockIndent := NewVal;
  end
  else
  if Sender = BlockTabIndentComboBox then
  begin
    NewVal := StrToIntDef(BlockTabIndentComboBox.Text, PreviewEdits[1].BlockTabIndent);
    // Todo: min/max
    SetComboBoxText(BlockTabIndentComboBox, IntToStr(NewVal), cstCaseInsensitive);
    for a := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[a] <> nil then
        PreviewEdits[a].BlockTabIndent := NewVal;
  end
  else
  if Sender = TabWidthsComboBox then
  begin
    NewVal := StrToIntDef(TabWidthsComboBox.Text, PreviewEdits[1].TabWidth);
    SetComboBoxText(TabWidthsComboBox, IntToStr(NewVal), cstCaseInsensitive);
    for a := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[a] <> nil then
        PreviewEdits[a].TabWidth := NewVal;
  end
end;

procedure TEditorIndentOptionsFrame.SmartTabsCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(SmartTabsCheckBox.Checked, eoSmartTabs);
end;

procedure TEditorIndentOptionsFrame.TabIndentBlocksCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(TabIndentBlocksCheckBox.Checked, eoTabIndent);
end;

procedure TEditorIndentOptionsFrame.TabsToSpacesCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(TabsToSpacesCheckBox.Checked, eoTabsToSpaces);
end;

function TEditorIndentOptionsFrame.DefaultBookmarkImages: TImageList;
var
  i: integer;
begin
  if FDefaultBookmarkImages = nil then
  begin
    FDefaultBookmarkImages := TImageList.Create(Self);
    FDefaultBookmarkImages.Width := 11;
    FDefaultBookmarkImages.Height := 11;
    for i := 0 to 9 do
      FDefaultBookmarkImages.AddLazarusResource('bookmark' + IntToStr(i));
  end;
  Result := FDefaultBookmarkImages;
end;

procedure TEditorIndentOptionsFrame.SetExtendedKeywordsMode(const AValue: Boolean);
begin
  if FPasExtendedKeywordsMode = AValue then exit;
  FPasExtendedKeywordsMode := AValue;
  UpdatePrevieEdits;
end;

procedure TEditorIndentOptionsFrame.SetStringKeywordMode(const AValue: TSynPasStringMode);
begin
  if FPasStringKeywordMode = AValue then exit;
  FPasStringKeywordMode := AValue;
  UpdatePrevieEdits;
end;

procedure TEditorIndentOptionsFrame.AddPreviewEdit(AEditor: TPreviewEditor);
begin
  SetLength(PreviewEdits, Length(PreviewEdits) + 1);
  PreviewEdits[Length(PreviewEdits)-1] := AEditor;
  if AEditor.BookMarkOptions.BookmarkImages = nil then
    AEditor.BookMarkOptions.BookmarkImages := DefaultBookmarkImages;
end;

constructor TEditorIndentOptionsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PreviewEdits := nil;
  if EditorOpts <> nil then begin
    FPasExtendedKeywordsMode := EditorOpts.PasExtendedKeywordsMode;
    FPasStringKeywordMode := EditorOpts.PasStringKeywordMode;
  end;
end;

initialization
  RegisterIDEOptionsEditor(GroupEditor, TEditorIndentOptionsFrame, EdtOptionsIndent, EdtOptionsGeneral);
end.

