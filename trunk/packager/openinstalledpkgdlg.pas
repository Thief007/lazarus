{  $Id$  }
{
 /***************************************************************************
                            openinstalledpkgdlg.pas
                            -----------------------


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

  Author: Mattias Gaertner

  Abstract:
    Defines TOpenInstalledPackagesDlg - The dialog let the user choose one of
    the installed packages.
}
unit OpenInstalledPkgDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Buttons, ComCtrls, StdCtrls, ExtCtrls,
  FileCtrl, LResources, Dialogs, LCLProc,
  IDEProcs, PackageDefs, LazarusIDEStrConsts, IDEOptionDefs, PackageSystem;

type
  TOpenInstalledPackagesDlg = class(TCustomForm)
    PkgListView: TListView;
    HintMemo: TMemo;
    OpenButton: TButton;
    CancelButton: TButton;
    procedure OpenButtonClick(Sender: TObject);
    procedure OpenInstalledPackagesDlgResize(Sender: TObject);
    procedure PkgListViewSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    procedure SetupComponents;
    function PkgStateToString(APackage: TLazPackage): string;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdateSelection;
    procedure UpdatePackageList;
    function GetSelectedPackage: TLazPackage;
  end;
  
function ShowOpenInstalledPkgDlg(var OpenPackage: TLazPackage): TModalResult;

implementation

function ShowOpenInstalledPkgDlg(var OpenPackage: TLazPackage): TModalResult;
var
  OpenInstalledPackagesDlg: TOpenInstalledPackagesDlg;
begin
  OpenInstalledPackagesDlg:=TOpenInstalledPackagesDlg.Create(Application);
  OpenInstalledPackagesDlg.UpdatePackageList;
  OpenInstalledPackagesDlg.UpdateSelection;
  Result:=OpenInstalledPackagesDlg.ShowModal;
  OpenPackage:=OpenInstalledPackagesDlg.GetSelectedPackage;
  OpenInstalledPackagesDlg.Free;
end;

{ TOpenInstalledPackagesDlg }

procedure TOpenInstalledPackagesDlg.OpenInstalledPackagesDlgResize(
  Sender: TObject);
var
  x: Integer;
  y: Integer;
  w: Integer;
begin
  x:=5;
  y:=5;
  w:=ClientWidth-2*x;
  with PkgListView do
    SetBounds(x,y,w,Parent.ClientHeight-130);
  inc(y,PkgListView.Height+5);

  with HintMemo do
    SetBounds(x,y,w,Parent.ClientHeight-y-40);

  with OpenButton do
    SetBounds(Parent.ClientWidth-180,Parent.ClientHeight-Height-5,80,Height);
  
  with CancelButton do
    SetBounds(Parent.ClientWidth-90,Parent.ClientHeight-Height-5,80,Height);
end;

procedure TOpenInstalledPackagesDlg.PkgListViewSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  UpdateSelection;
end;

procedure TOpenInstalledPackagesDlg.UpdateSelection;
var
  CurPkg: TLazPackage;
  LI: TListItem;
  HintStr: String;
begin
  LI:=PkgListView.Selected;
  if LI<>nil then begin
    CurPkg:=TLazPackage(LI.Data);
    HintStr:=
       'Filename:  '+CurPkg.Filename;
    if CurPkg.AutoCreated then
      HintStr:=HintStr+EndOfLine+'This package was automatically created';
    if CurPkg.Missing then
      HintStr:=HintStr+EndOfLine+'This package is installed, '
                                +'but the lpk file was not found';
    HintStr:=HintStr+EndOfLine+'Description:  '
                    +BreakString(CurPkg.Description,60,length('Description:  '));
    HintMemo.Text:=HintStr;
  end else begin
    HintMemo.Text:='Please select a package';
  end;
end;

procedure TOpenInstalledPackagesDlg.OpenButtonClick(Sender: TObject);
begin
  if PkgListView.Selected=nil then begin
    MessageDlg('No package selected',
      'Please select a package to open',
      mtInformation,[mbCancel],0);
    exit;
  end;
  ModalResult:=mrOk;
end;

procedure TOpenInstalledPackagesDlg.SetupComponents;
var
  NewColumn: TListColumn;
begin
  PkgListView:=TListView.Create(Self);
  with PkgListView do begin
    Name:='PkgListView';
    Parent:=Self;
    ViewStyle:=vsReport;
    NewColumn:=Columns.Add;
    NewColumn.Caption:='Package Name';
    NewColumn.Width:=150;
    NewColumn:=Columns.Add;
    NewColumn.Caption:='Version';
    NewColumn.Width:=80;
    NewColumn:=Columns.Add;
    NewColumn.Caption:='State';
    NewColumn.Width:=300;
    OnSelectItem:=@PkgListViewSelectItem;
  end;
  
  HintMemo:=TMemo.Create(Self);
  with HintMemo do begin
    Name:='HintMemo';
    Parent:=Self;
    WordWrap:=true;
    ReadOnly:=true;
    ScrollBars:=ssAutoBoth;
  end;
  
  OpenButton:=TButton.Create(Self);
  with OpenButton do begin
    Name:='OpenButton';
    Parent:=Self;
    Caption:='Open';
    OnClick:=@OpenButtonClick;
  end;
  
  CancelButton:=TButton.Create(Self);
  with CancelButton do begin
    Name:='CancelButton';
    Parent:=Self;
    Caption:='Cancel';
    ModalResult:=mrCancel;
  end;
end;

function TOpenInstalledPackagesDlg.PkgStateToString(APackage: TLazPackage
  ): string;
  
  procedure AddState(const s: string);
  begin
    if Result='' then
      Result:=Result+s
    else
      Result:=Result+', '+s;
  end;
  
begin
  Result:='';
  case APackage.Installed of
  pitStatic: AddState('installed static');
  pitDynamic: AddState('installed dynamic');
  end;
  case APackage.AutoInstall of
  pitStatic: AddState('auto install static');
  pitDynamic: AddState('auto install dynamic');
  end;
end;

constructor TOpenInstalledPackagesDlg.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Name:='OpenInstalledPackagesDlg';
  Caption:='Open loaded package';
  SetupComponents;
  OnResize:=@OpenInstalledPackagesDlgResize;
  Position:=poScreenCenter;
  IDEDialogLayoutList.ApplyLayout(Self,500,350);
  OnResize(Self);
end;

destructor TOpenInstalledPackagesDlg.Destroy;
begin
  inherited Destroy;
end;

procedure TOpenInstalledPackagesDlg.UpdatePackageList;
var
  Cnt: Integer;
  i: Integer;
  CurPkg: TLazPackage;
  CurListItem: TListItem;
begin
  PkgListView.BeginUpdate;
  Cnt:=PackageGraph.Count;
  for i:=0 to Cnt-1 do begin
    CurPkg:=PackageGraph[i];
    //if not (CurPkg.Installed in [pitStatic,pitDynamic]) then continue;
    if PkgListView.Items.Count>i then begin
      CurListItem:=PkgListView.Items[i];
      CurListItem.SubItems[0]:=CurPkg.Version.AsString;
      CurListItem.SubItems[1]:=PkgStateToString(CurPkg);
    end else begin
      CurListItem:=PkgListView.Items.Add;
      CurListItem.SubItems.Add(CurPkg.Version.AsString);
      CurListItem.SubItems.Add(PkgStateToString(CurPkg));
    end;
    CurListItem.Caption:=CurPkg.Name;
    CurListItem.Data:=CurPkg;
  end;
  PkgListView.EndUpdate;
end;

function TOpenInstalledPackagesDlg.GetSelectedPackage: TLazPackage;
var
  LI: TListItem;
begin
  Result:=nil;
  LI:=PkgListView.Selected;
  if LI=nil then exit;
  Result:=TLazPackage(LI.Data);
end;

end.

