{  $Id$  }
{
 /***************************************************************************
                          ViewUnit_dlg.pp
                          ---------------
   TViewUnit is the application dialog for displaying all units in a project.
   It gets used for the "View Units", "View Forms" and "Remove from Project"
   menu items.


   Initial Revision  : Sat Feb 19 17:42 CST 1999


 ***************************************************************************/

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
unit ViewUnit_Dlg;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math, Controls, Forms, Dialogs, LResources, Buttons, StdCtrls,
  LazarusIdeStrConsts, LCLType, LCLIntf, LMessages, IDEWindowIntf, IDEContextHelpEdit;

type
  TViewUnitsEntry = class
  public
    Name: string;
    ID: integer;
    Selected: boolean;
    constructor Create(const AName: string; AnID: integer; ASelected: boolean);
  end;

  { TViewUnitDialog }

  TViewUnitDialog = class(TForm)
    HelpButton: TBitBtn;
    Edit: TEdit;
    ListBox: TListBox;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    MultiSelectCheckBox: TCheckBox;
    procedure EditChange(Sender: TObject);
    procedure EditEnter(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HelpButtonClick(Sender: TObject);
    Procedure btnOKClick(Sender :TObject);
    Procedure btnCancelClick(Sender :TObject);
    procedure ListboxClick(Sender: TObject);
    procedure ListboxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MultiselectCheckBoxClick(Sender :TObject);
  private
    procedure LM_USER1(var Message: TLMessage); message LM_USER + 1;
  public
    constructor Create(TheOwner: TComponent); override;
  end;

function ShowViewUnitsDlg(Entries: TStringList; MultiSelect: boolean;
  const Caption: string): TModalResult;
  // Entries is a list of TViewUnitsEntry(s)

implementation

function ShowViewUnitsDlg(Entries: TStringList; MultiSelect: boolean;
  const Caption: string): TModalResult;
var
  ViewUnitDialog: TViewUnitDialog;
  i: integer;
begin
  ViewUnitDialog:=TViewUnitDialog.Create(nil);
  try
    ViewUnitDialog.Caption:=Caption;
    ViewUnitDialog.MultiselectCheckBox.Enabled:=MultiSelect;
    ViewUnitDialog.MultiselectCheckBox.Checked:=MultiSelect;
    ViewUnitDialog.ListBox.Multiselect:=ViewUnitDialog.MultiselectCheckBox.Checked;
    with ViewUnitDialog.ListBox.Items do begin
      BeginUpdate;
      Clear;
      for i:=0 to Entries.Count-1 do
        Add(TViewUnitsEntry(Entries.Objects[i]).Name);
      EndUpdate;
    end;
    for i:=0 to Entries.Count-1 do
      ViewUnitDialog.ListBox.Selected[i]:=TViewUnitsEntry(Entries.Objects[i]).Selected;
    Result:=ViewUnitDialog.ShowModal;
    if Result=mrOk then begin
      for i:=0 to Entries.Count-1 do begin
        TViewUnitsEntry(Entries.Objects[i]).Selected:=ViewUnitDialog.ListBox.Selected[i];
      end;
    end;
  finally
    ViewUnitDialog.Free;
  end;
end;

function SearchItem(Items: TStrings; Text: String): Integer;
var
  i: integer;
begin
  // Items can be unsorted => use simple traverse
  Result := -1;
  Text := LowerCase(Text);
  for i := 0 to Items.Count - 1 do
    if Pos(Text, LowerCase(Items[i])) = 1 then
    begin
      Result := i;
      break;
    end;
end;

{ TViewUnitsEntry }

constructor TViewUnitsEntry.Create(const AName: string; AnID: integer;
  ASelected: boolean);
begin
  inherited Create;
  Name := AName;
  ID := AnID;
  Selected := ASelected;
end;

{ TViewUnitDialog }

constructor TViewUnitDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  IDEDialogLayoutList.ApplyLayout(Self,450,300);
  btnOK.Caption               := lisOkBtn;
  btnOk.Left                  := ClientWidth-btnOk.Width-5;
  btnCancel.Caption           := dlgCancel;
  btnCancel.Left              := btnOk.Left;
  CancelControl               := btnCancel;
  MultiSelectCheckBox.Caption := dlgMultiSelect;
  MultiSelectCheckBox.Left    := btnOk.Left;
end;

Procedure TViewUnitDialog.btnOKClick(Sender : TOBject);
Begin
  IDEDialogLayoutList.SaveLayout(Self);
  ModalResult := mrOK;
End;

procedure TViewUnitDialog.HelpButtonClick(Sender: TObject);
begin
  ShowContextHelpForIDE(Self);
end;

procedure TViewUnitDialog.EditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  
  procedure MoveItemIndex(d: integer); inline;
  var
    NewIndex: Integer;
  begin
    NewIndex := Min(ListBox.Items.Count - 1, Max(0, ListBox.ItemIndex + D));
    ListBox.ItemIndex := NewIndex;
    ListBoxClick(nil);
  end;

  function PageCount: Integer;
  begin
    if ListBox.ItemHeight > 0 then
      Result := ListBox.Height div ListBox.ItemHeight
    else
      Result := 0;
  end;
  
begin
  case Key of
    VK_UP: MoveItemIndex(-1);
    VK_DOWN: MoveItemIndex(1);
    VK_NEXT: MoveItemIndex(PageCount);
    VK_PRIOR: MoveItemIndex(-PageCount);
    VK_RETURN: btnOKClick(nil);
  end;
end;

procedure TViewUnitDialog.EditChange(Sender: TObject);
var
  Index: Integer;
begin
  Index := SearchItem(ListBox.Items, Edit.Text);
  ListBox.ItemIndex := Index;

  if ListBox.MultiSelect then
  begin
    ListBox.ClearSelection;
    if Index <> -1 then
      ListBox.Selected[Index] := True;
  end;
end;

procedure TViewUnitDialog.EditEnter(Sender: TObject);
begin
  PostMessage(Handle, LM_USER + 1, 0, 0);
end;

Procedure TViewUnitDialog.btnCancelClick(Sender : TOBject);
Begin
  IDEDialogLayoutList.SaveLayout(Self);
  ModalResult := mrCancel;
end;

procedure TViewUnitDialog.ListboxClick(Sender: TObject);
begin
  if ListBox.ItemIndex <> -1 then
    Edit.Text := ListBox.Items[ListBox.ItemIndex];
  PostMessage(Handle, LM_USER + 1, 0, 0);
end;

procedure TViewUnitDialog.ListboxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    btnOKClick(nil);
end;

procedure TViewUnitDialog.MultiselectCheckBoxClick(Sender :TObject);
begin
  ListBox.Multiselect := MultiselectCheckBox.Checked;
end;

procedure TViewUnitDialog.LM_USER1(var Message: TLMessage);
begin
  Edit.SelectAll;
  Edit.SetFocus;
end;


initialization
 {$I viewunit_dlg.lrs}

end.

