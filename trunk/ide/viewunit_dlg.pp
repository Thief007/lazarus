{  $Id$  }
{
 /***************************************************************************
                          ViewUnit_dlg.pp
                        -------------------
   TViewUnit is the application dialog for displaying all units in a project.


   Initial Revision  : Sat Feb 19 17:42 CST 1999


 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
}
unit ViewUnit_Dlg;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Controls, Forms, Dialogs, LResources, Buttons, StdCtrls;

type
  TViewUnitsEntry = class
  public
    Name: string;
    ID: integer;
    Selected: boolean;
    constructor Create(AName: string; AnID: integer; ASelected: boolean);
  end;

  TViewUnits = class(TForm)
    ListBox: TListBox;
    btnOK : TButton;
    btnCancel : TButton;
    Procedure btnOKClick(Sender : TOBject);
    Procedure btnCancelClick(Sender : TOBject);
  public
    constructor Create(AOwner: TComponent); override;	
  end;


function ShowViewUnitsDlg(Entries: TList; MultiSelect: boolean): TModalResult;
   // Entries is a list of TViewUnitsEntry(s)


implementation


function ShowViewUnitsDlg(Entries: TList;
  MultiSelect: boolean): TModalResult;
var ViewUnits: TViewUnits;
  i: integer;
begin
  ViewUnits:=TViewUnits.Create(Application);
  try
    ViewUnits.ListBox.Visible:=false;
    ViewUnits.ListBox.MultiSelect:=MultiSelect;
    with ViewUnits.ListBox.Items do begin
      BeginUpdate;
      Clear;
      for i:=0 to Entries.Count-1 do
        Add(TViewUnitsEntry(Entries[i]).Name);
      EndUpdate;
    end;
    for i:=0 to Entries.Count-1 do
      ViewUnits.ListBox.Selected[i]:=TViewUnitsEntry(Entries[i]).Selected;
    ViewUnits.ListBox.Visible:=true;
    Result:=ViewUnits.ShowModal;
    if Result=mrOk then begin
      for i:=0 to Entries.Count-1 do
        TViewUnitsEntry(Entries[i]).Selected:=ViewUnits.ListBox.Selected[i];
    end;
  finally
    ViewUnits.Free;
  end;
end;

{ TViewUnitsEntry }

constructor TViewUnitsEntry.Create(AName: string; AnID: integer;
  ASelected: boolean);
begin
  inherited Create;
  Name:=AName;
  ID:=AnID;
  Selected:=ASelected;
end;

{ TViewUnits }

constructor TViewUnits.Create(AOwner: TComponent);	
var  Pad : Integer;
begin
  inherited Create(AOwner);

  if LazarusResources.Find(Classname)=nil then begin
    Caption := 'View Project Units';
    SetBounds((Screen.Width-345) div 2, (Screen.Height-220) div 2, 325, 200);
    Pad := 10;
    Position := poScreenCenter;

    btnOK := TButton.Create(Self);
    with btnOk do begin
      Parent := Self;
      Left := Self.Width - 90;
      Top := pad;
      Width := 75;
      Height := 25;
      Caption := 'OK';
      Visible := True;
      OnClick := @btnOKClick;
      Name := 'btnOK';
    end;

    btnCancel := TButton.Create(Self);
    with btnCancel do begin
      Parent := Self;
      Left := Self.Width - 90;
      Top := btnOK.Top + btnOK.Height + pad;
      Width := 75;
      Height := 25;
      Caption := 'Cancel';
      Visible := True;
      Name := 'btnCancel';
      OnClick := @btnCancelClick;
    end;

    Listbox:= TListBox.Create(Self);
    with Listbox do begin
      Parent:= Self;
      Top:= Pad;
      Left:= Pad;
      Width:= Self.Width - (Self.Width - btnOK.Left) - (2*pad);
      Height:= Self.Height - Top - Pad;
      Visible:= true;
      MultiSelect:= false;
      Name := 'Listbox';
    end;
  end;
end;


Procedure TViewUnits.btnOKClick(Sender : TOBject);
Begin
  ModalResult := mrOK;
End;


Procedure TViewUnits.btnCancelClick(Sender : TOBject);
Begin
  ModalResult := mrCancel;
end;


initialization
{ $I viewunits1.lrs}


end.
{
  $Log$
  Revision 1.7  2001/03/08 15:59:06  lazarus
  IDE bugfixes and viewunit/forms functionality

  Revision 1.6  2001/01/16 23:30:45  lazarus
  trying to determine what's crashing LAzarus on load.
  Shane

  Revision 1.4  2001/01/14 03:56:57  lazarus
  Shane

  Revision 1.3  2001/01/13 06:11:07  lazarus
  Minor fixes
  Shane

  Revision 1.2  2001/01/05 17:44:37  lazarus
  ViewUnits1, ViewForms1 and MessageDlg are all loaded from their resources and all controls are auto-created on them.
  There are still a few problems with some controls so I haven't converted all forms.
  Shane

  Revision 1.1  2000/07/13 10:27:48  michael
  + Initial import

  Revision 1.8  2000/05/10 02:34:43  lazarus
  Changed writelns to Asserts except for ERROR and WARNING messages.   CAW

  Revision 1.7  2000/03/24 14:40:41  lazarus
  A little polishing and bug fixing.

  Revision 1.6  2000/03/19 03:52:08  lazarus
  Added onclick events for the speedbuttons.
  Shane

  Revision 1.5  2000/03/03 20:22:02  lazarus
  Trying to add TBitBtn
  Shane

  Revision 1.4  2000/02/24 09:10:12  lazarus
  TListBox.Selected bug fixed.

  Revision 1.3  2000/02/22 21:29:42  lazarus
  Added a few more options in the editor like closeing a unit.  Also am keeping track of what page , if any, they are currently on.
  Shane

  Revision 1.2  2000/02/21 21:08:29  lazarus
  Bug fix in GetCaption.  Added the line to check if a handle is allocated for a csEdit.   Otherwise when creating it, it check's it's caption.  It then sends a LM_GETTEXT and the edit isn't created, so it calls LM_CREATE which in turn checks the caption again, etc.
  Shane

  Revision 1.1  2000/02/21 17:38:04  lazarus
  Added modalresult to TCustomForm
  Added a View Units dialog box
  Added a View Forms dialog box
  Added a New Unit menu selection
  Added a New Form menu selection
  Shane


}


























































