{ Copyright (C) 2011,

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

  Original version by Juha Manninen
  Icons added by Marcelo B Paula
}
unit UseProjUnitDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, StdCtrls, ExtCtrls, Buttons,
  ButtonPanel, Dialogs, LCLProc, FileProcs, Graphics, LCLType,
  SourceEditor, LazIDEIntf, IDEImagesIntf, LazarusIDEStrConsts,
  ProjectIntf, Project, CodeCache, CodeToolManager, IdentCompletionTool;

type

  { TUseUnitDialog }

  TUseUnitDialog = class(TForm)
    ButtonPanel1: TButtonPanel;
    AllUnitsCheckBox: TCheckBox;
    UnitnameEdit: TEdit;
    UnitsListBox: TListBox;
    SectionRadioGroup: TRadioGroup;
    procedure AllUnitsCheckBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure UnitnameEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UnitnameEditKeyPress(Sender: TObject; var Key: char);
    procedure UnitsListBoxClick(Sender: TObject);
    procedure UnitsListBoxDblClick(Sender: TObject);
    procedure UnitsListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
  private
    UnitImgInd: Integer;
    FOtherUnits: TStringList;
    procedure AddItems(AItems: TStrings);
    procedure AddOtherUnits;
    procedure RemoveOtherUnits;
    procedure CreateOtherUnitsList;
    function SelectedUnit: string;
    function InterfaceSelected: Boolean;
    procedure EnableOnlyInterface;
    procedure SearchList(StartIndex: Integer = -1);
    procedure UpdateUnitName(Index: Integer);
    function UnitExists(AUnitName: string): Boolean;
  public

  end; 

function GetProjAvailableUnits(SrcEdit: TSourceEditor; out CurrentUnitName: String;
                           IgnoreErrors: boolean): TStringList;
function ShowUseUnitDialog: TModalResult;

implementation

uses StrUtils, math;

{$R *.lfm}

type
  { TUnitsListBoxObject }

  TUnitsListBoxObject = class
  public
    IdentList: TIdentifierList;
    IdentItem: TIdentifierListItem;
    Handled: Boolean;
    constructor Create(AIdentList: TIdentifierList; AIdentItem: TIdentifierListItem);
  end;

function FindUnitName(f: TUnitsListBoxObject): string;
var
  CodeBuf: TCodeBuffer;
begin
  Result := f.IdentItem.Identifier;
  CodeBuf := CodeToolBoss.FindUnitSource(f.IdentList.StartContextPos.Code, Result, '');
  if CodeBuf = nil then Exit;
  Result := CodeToolBoss.GetSourceName(CodeBuf, True);
  if Result = '' then
    Result := f.IdentItem.Identifier;
end;

function GetProjAvailableUnits(SrcEdit: TSourceEditor; out CurrentUnitName: String;
  IgnoreErrors: boolean): TStringList;
var
  MainUsedUnits, ImplUsedUnits: TStrings;
  ProjFile: TUnitInfo;
  s: String;
begin
  MainUsedUnits:=nil;
  ImplUsedUnits:=nil;
  Result:=nil;
  try
    if SrcEdit=nil then exit;
    Assert(Assigned(SrcEdit.CodeBuffer));
    if not CodeToolBoss.FindUsedUnitNames(SrcEdit.CodeBuffer,
                                          MainUsedUnits,ImplUsedUnits)
    then begin
      if not IgnoreErrors then
      begin
        DebugLn(['ShowUseProjUnitDialog CodeToolBoss.FindUsedUnitNames failed']);
        LazarusIDE.DoJumpToCodeToolBossError;
      end;
      exit;
    end;
    Result:=TStringList.Create;  // Result TStringList must be freed by caller.
    TStringList(MainUsedUnits).CaseSensitive:=False;
    TStringList(ImplUsedUnits).CaseSensitive:=False;
    // Debug message will be cleaned soon!!!
    if SrcEdit.GetProjectFile is TUnitInfo then
      CurrentUnitName:=TUnitInfo(SrcEdit.GetProjectFile).Unit_Name
    else
      CurrentUnitName:='';
    //DebugLn('ShowUseProjUnitDialog: CurrentUnitName before loop = '+CurrentUnitName);
    // Add available unit names to Result.
    ProjFile:=Project1.FirstPartOfProject;
    while ProjFile<>nil do begin
      s:=ProjFile.Unit_Name;
      if s=CurrentUnitName then begin      // current unit
        {if SrcEdit.GetProjectFile is TUnitInfo then   // Debug!
          DebugLn('ShowUseProjUnitDialog: CurrentUnitName in loop = ' +
                      TUnitInfo(SrcEdit.GetProjectFile).Unit_Name);}
        s:='';
      end;
      if (ProjFile<>Project1.MainUnitInfo) and (s<>'') then
        if (MainUsedUnits.IndexOf(s)<0) and (ImplUsedUnits.IndexOf(s)<0) then
          Result.Add(s);
      ProjFile:=ProjFile.NextPartOfProject;
    end;
  finally
    ImplUsedUnits.Free;
    MainUsedUnits.Free;
  end;
end;

function ShowUseUnitDialog: TModalResult;
var
  UseProjUnitDlg: TUseUnitDialog;
  SrcEdit: TSourceEditor;
  AvailUnits: TStringList;
  CurrentUnitName, s: String;
  CTRes: Boolean;
begin
  Result:=mrOk;
  if not LazarusIDE.BeginCodeTools then exit;
  // get cursor position
  SrcEdit:=SourceEditorManager.ActiveEditor;
  try
    AvailUnits:=GetProjAvailableUnits(SrcEdit, CurrentUnitName, false);
    // Show the dialog.
    AvailUnits.Sorted:=True;
    UseProjUnitDlg:=TUseUnitDialog.Create(nil);
    try
      if Assigned(AvailUnits) then UseProjUnitDlg.AddItems(AvailUnits);
      if UseProjUnitDlg.UnitsListBox.Count = 0 then
      begin
        UseProjUnitDlg.AllUnitsCheckBox.Checked := True;
        if UseProjUnitDlg.UnitsListBox.Count = 0 then Exit(mrCancel);
      end;
      // there is only main uses section in program/library/package
      if SrcEdit.GetProjectFile=Project1.MainUnitInfo then
        UseProjUnitDlg.EnableOnlyInterface;
      if UseProjUnitDlg.ShowModal=mrOk then begin
        s:=UseProjUnitDlg.SelectedUnit;
        if s <> '' then begin
          if not UseProjUnitDlg.UnitExists(s) and
            (MessageDlg(Format('Unit "%s" seems not to be exist. Do you still want to add it?', [s]),
              mtConfirmation, mbYesNo, 0) = mrNo) then Exit(mrCancel);
          if UseProjUnitDlg.InterfaceSelected then
            CTRes:=CodeToolBoss.AddUnitToMainUsesSection(SrcEdit.CodeBuffer, s, '')
          else
            CTRes:=CodeToolBoss.AddUnitToImplementationUsesSection(SrcEdit.CodeBuffer, s, '');
          if not CTRes then begin
            LazarusIDE.DoJumpToCodeToolBossError;
            exit(mrCancel);
          end;
        end;
      end;
    finally
      UseProjUnitDlg.Free;
    end;
  finally
    CodeToolBoss.SourceCache.ClearAllSourceLogEntries;
    AvailUnits.Free;
  end;
end;

{ TUnitsListBoxObject }

constructor TUnitsListBoxObject.Create(AIdentList: TIdentifierList;
  AIdentItem: TIdentifierListItem);
begin
  inherited Create;
  IdentList := AIdentList;
  IdentItem := AIdentItem;
end;

{ TUseUnitDialog }

procedure TUseUnitDialog.FormCreate(Sender: TObject);
begin
  // Internationalization
  Caption := dlgUseUnitCaption;
  SectionRadioGroup.Caption := dlgInsertSection;
  SectionRadioGroup.Items.Clear;
  SectionRadioGroup.Items.Add(dlgInsertInterface);
  SectionRadioGroup.Items.Add(dlgInsertImplementation);
  SectionRadioGroup.ItemIndex:=1;
  ButtonPanel1.OKButton.Caption:=lisOk;
  ButtonPanel1.CancelButton.Caption:=dlgCancel;
  UnitImgInd := IDEImages.LoadImage(16, 'item_unit');
end;

procedure TUseUnitDialog.AllUnitsCheckBoxChange(Sender: TObject);
begin
  if AllUnitsCheckBox.Checked then
    AddOtherUnits
  else
    RemoveOtherUnits;
  if Visible then UnitnameEdit.SetFocus;
end;

procedure TUseUnitDialog.FormDestroy(Sender: TObject);
var i: Integer;
begin
  if Assigned(FOtherUnits) then
    for i := 0 to FOtherUnits.Count - 1 do
      FOtherUnits.Objects[i].Free;
  FOtherUnits.Free;
end;

procedure TUseUnitDialog.UnitnameEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_UP then
  begin
    if UnitsListBox.ItemIndex > 0 then
      UnitsListBox.ItemIndex := UnitsListBox.ItemIndex - 1;
    UpdateUnitName(UnitsListBox.ItemIndex);
    UnitsListBoxClick(nil);
    Key := 0;
  end else
  if Key = VK_DOWN then
  begin
    if UnitsListBox.ItemIndex < UnitsListBox.Count - 1 then
      UnitsListBox.ItemIndex := UnitsListBox.ItemIndex + 1;
    UpdateUnitName(UnitsListBox.ItemIndex);
    UnitsListBoxClick(nil);
    Key := 0;
  end;
end;

procedure TUseUnitDialog.UnitnameEditKeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in ['a'..'z', 'A'..'Z', '_', '0'..'9']) then Exit;
  UnitnameEdit.SelText := Key;
  SearchList;
  Key := #0;
end;

procedure TUseUnitDialog.UnitsListBoxClick(Sender: TObject);
begin
  with UnitsListBox do
    if ItemIndex >= 0 then
    begin
      UpdateUnitName(ItemIndex);
      UnitnameEdit.Text := Items[ItemIndex];
      if Visible then UnitnameEdit.SetFocus;
      UnitnameEdit.SelectAll;
    end;
end;

procedure TUseUnitDialog.UnitsListBoxDblClick(Sender: TObject);
begin
  with UnitsListBox do
    if ItemIndex >= 0 then
    begin
      UpdateUnitName(ItemIndex);
      UnitnameEdit.Text := Items[ItemIndex];
      ModalResult := mrOK;
    end;
end;

procedure TUseUnitDialog.UnitsListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
  if Index < 0 then Exit;
  UnitsListBox.Canvas.FillRect(ARect);
  if Assigned(UnitsListBox.Items.Objects[Index]) then
  begin
    if not (odSelected in State) then
      UnitsListBox.Canvas.Font.Color := clGreen;
    IDEImages.Images_16.Draw(UnitsListBox.Canvas, 1, ARect.Top, UnitImgInd, False);
  end else
    IDEImages.Images_16.Draw(UnitsListBox.Canvas, 1, ARect.Top, UnitImgInd);
  UnitsListBox.Canvas.TextRect(ARect, ARect.Left + 20,ARect.Top,
                                UnitsListBox.Items[Index]);
end;

procedure TUseUnitDialog.AddItems(AItems: TStrings);
begin
  UnitsListBox.Items.Assign(AItems);
end;

procedure TUseUnitDialog.AddOtherUnits;
begin
  if not Assigned(FOtherUnits) then CreateOtherUnitsList;
  UnitsListBox.Items.AddStrings(FOtherUnits);
end;

procedure TUseUnitDialog.RemoveOtherUnits;
var i: Integer;
begin
  with UnitsListBox.Items do
  begin
    BeginUpdate;
    try
      for i := Count - 1 downto 0 do
        if Assigned(Objects[i]) then Delete(i);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TUseUnitDialog.CreateOtherUnitsList;
var
  i: Integer; curUnit: string;
  SrcEdit: TSourceEditor;
  MainUsedUnits, ImplUsedUnits: TStrings;
begin
  if Assigned(FOtherUnits) then Exit;
  FOtherUnits := TStringList.Create;
  SrcEdit := SourceEditorManager.ActiveEditor;
  MainUsedUnits := nil; ImplUsedUnits := nil;
  CodeToolBoss.FindUsedUnitNames(SrcEdit.CodeBuffer, MainUsedUnits, ImplUsedUnits);
  try
    if CodeToolBoss.GatherUnitNames(SrcEdit.CodeBuffer) then
      with CodeToolBoss.IdentifierList, FOtherUnits do
      begin
        Prefix := '';
        for i := 0 to GetFilteredCount - 1 do
        begin
          curUnit := FilteredItems[i].Identifier;
          if (MainUsedUnits.IndexOf(curUnit) < 0)
            and (ImplUsedUnits.IndexOf(curUnit) < 0)
            and (IndexOf(curUnit) < 0) then
              AddObject(FilteredItems[i].Identifier,
                TUnitsListBoxObject.Create(CodeToolBoss.IdentifierList, FilteredItems[i]));
        end;
      end;
    FOtherUnits.Sort;
  finally
    MainUsedUnits.Free;
    ImplUsedUnits.Free;
  end;
end;

function TUseUnitDialog.SelectedUnit: string;
begin
  Result := Trim(UnitnameEdit.Text);
end;

function TUseUnitDialog.InterfaceSelected: Boolean;
begin
  Result:=SectionRadioGroup.ItemIndex=0;
end;

procedure TUseUnitDialog.EnableOnlyInterface;
begin
  SectionRadioGroup.ItemIndex := 0;
  SectionRadioGroup.Enabled := False;
end;

function SearchItem(Items: TStrings; Text: String; StartIndex: Integer = -1): Integer;
var
  i: integer;
begin
  // Items can be unsorted => use simple traverse
  Result := -1;
  Text := AnsiLowerCase(Text);
  for i := StartIndex + 1 to Items.Count - 1 do
    if AnsiStartsText(Text, Items[i]) then
    begin
      Result := i;
      Break;
    end;
end;

procedure TUseUnitDialog.SearchList(StartIndex: Integer);
var
  Index, Len: Integer;
begin
  Index := SearchItem(UnitsListBox.Items, UnitnameEdit.Text, StartIndex);
  if Index >= 0 then
  begin
    UpdateUnitName(Index);
    UnitsListBox.ItemIndex := Index;
    UnitsListBox.MakeCurrentVisible;
    Len := Length(UnitnameEdit.Text);
    UnitnameEdit.Text := UnitsListBox.Items[Index];
    UnitnameEdit.SelStart := Len;
    UnitnameEdit.SelLength := Length(UnitnameEdit.Text) - Len;
  end;
end;

procedure TUseUnitDialog.UpdateUnitName(Index: Integer);
var
  f: TUnitsListBoxObject;
begin
  f := TUnitsListBoxObject(UnitsListBox.Items.Objects[Index]);
  if Assigned(f) and not f.Handled then
  begin
    f.Handled := True;
    UnitsListBox.Items[Index] := FindUnitName(f);
  end;
end;

function TUseUnitDialog.UnitExists(AUnitName: string): Boolean;
begin
  Result := UnitsListBox.Items.IndexOf(AUnitName) >= 0;
  if Result then Exit;
  if not AllUnitsCheckBox.Checked then
  begin
    if not Assigned(FOtherUnits) then CreateOtherUnitsList;
    Result := FOtherUnits.IndexOf(AUnitName) >= 0;
  end;
end;


end.

