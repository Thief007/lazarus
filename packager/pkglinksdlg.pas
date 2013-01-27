{
 /***************************************************************************
                            pkgmanager.pas
                            --------------


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
    Dialog showing the package links of the IDE package systems.
}
unit PkgLinksDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, Grids, ExtCtrls, AvgLvlTree,
  FileProcs, PackageIntf,
  LazarusIDEStrConsts, PackageDefs, PackageLinks, LPKCache;

type

  { TPkgLinkInfo }

  TPkgLinkInfo = class(TPackageLink)
  private
    FLPKInfo: TLPKInfo;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    property Origin;
    property LPKInfo: TLPKInfo read FLPKInfo;
  end;

  { TPackageLinksDialog }

  TPackageLinksDialog = class(TForm)
    BtnPanel: TPanel;
    CloseBitBtn: TBitBtn;
    LPKParsingTimer: TTimer;
    ShowUserLinksCheckBox: TCheckBox;
    ShowGlobalLinksCheckBox: TCheckBox;
    ScopeGroupBox: TGroupBox;
    PkgStringGrid: TStringGrid;
    UpdateGlobalLinksButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LPKParsingTimerTimer(Sender: TObject);
    procedure OnAllLPKParsed(Sender: TObject);
    procedure ShowGlobalLinksCheckBoxChange(Sender: TObject);
    procedure ShowUserLinksCheckBoxChange(Sender: TObject);
    procedure UpdateGlobalLinksButtonClick(Sender: TObject);
  private
    FLinks: TAvglVLTree;// tree of TPkgLinkInfo sorted for names
    FCollectingOrigin: TPkgLinkOrigin;
    procedure UpdatePackageList;
    procedure ClearLinks;
    procedure IteratePackages(APackage: TLazPackageID);
  public
  end;

function ShowPackageLinks: TModalResult;

implementation

{$R *.lfm}

function ShowPackageLinks: TModalResult;
var
  PackageLinksDialog: TPackageLinksDialog;
begin
  PackageLinksDialog:=TPackageLinksDialog.Create(nil);
  try
    Result:=PackageLinksDialog.ShowModal;
  finally
    PackageLinksDialog.Free;
  end;
end;

{ TPackageLinksDialog }

procedure TPackageLinksDialog.FormCreate(Sender: TObject);
begin
  Caption:=lisPLDPackageLinks;
  ScopeGroupBox.Caption:=dlgScope;
  ShowGlobalLinksCheckBox.Caption:=lisPLDShowGlobalLinks
                                 +' ('+PkgLinks.GetGlobalLinkDirectory+'*.lpl)';
  ShowUserLinksCheckBox.Caption:=lisPLDShowUserLinks
                                      +' ('+PkgLinks.GetUserLinkFile+')';
  UpdateGlobalLinksButton.Caption:=lrsReadLplFiles;
  CloseBitBtn.Caption:=lisClose;

  LPKInfoCache.StartLPKReaderWithAllAvailable;
  LPKInfoCache.AddOnQueueEmpty(@OnAllLPKParsed);

  UpdatePackageList;
end;

procedure TPackageLinksDialog.FormDestroy(Sender: TObject);
begin
  LPKInfoCache.EndLPKReader;
  ClearLinks;
end;

procedure TPackageLinksDialog.LPKParsingTimerTimer(Sender: TObject);
begin
  UpdatePackageList;
end;

procedure TPackageLinksDialog.OnAllLPKParsed(Sender: TObject);
begin
  LPKParsingTimer.Enabled:=false;
  UpdatePackageList;
end;

procedure TPackageLinksDialog.ShowGlobalLinksCheckBoxChange(Sender: TObject);
begin
  UpdatePackageList;
end;

procedure TPackageLinksDialog.ShowUserLinksCheckBoxChange(Sender: TObject);
begin
  UpdatePackageList;
end;

procedure TPackageLinksDialog.UpdateGlobalLinksButtonClick(Sender: TObject);
begin
  PkgLinks.ClearGlobalLinks;
  PkgLinks.UpdateGlobalLinks;
  UpdatePackageList;
end;

procedure TPackageLinksDialog.UpdatePackageList;
var
  Node: TAvgLvlTreeNode;
  Link: TPkgLinkInfo;
  i: Integer;
  OriginStr: String;
  Info: TLPKInfo;
begin
  // collect links
  ClearLinks;

  if FLinks=nil then
    FLinks:=TAvgLvlTree.Create(@ComparePackageLinks);
  if ShowGlobalLinksCheckBox.Checked then begin
    FCollectingOrigin:=ploGlobal;
    PkgLinks.IteratePackages(false,@IteratePackages,[ploGlobal]);
  end;
  if ShowUserLinksCheckBox.Checked then begin
    FCollectingOrigin:=ploUser;
    PkgLinks.IteratePackages(false,@IteratePackages,[ploUser]);
  end;

  // query additional information from lpk files
  LPKInfoCache.EnterCritSection;
  try
    Node:=FLinks.FindLowest;
    while Node<>nil do begin
      Link:=TPkgLinkInfo(Node.Data);
      Info:=LPKInfoCache.FindPkgInfoWithFilename(Link.GetEffectiveFilename);
      if Info<>nil then
        Link.LPKInfo.Assign(Info);
      Node:=Node.Successor;
    end;
  finally
    LPKInfoCache.LeaveCritSection;
  end;

  // fill/update grid
  PkgStringGrid.ColCount:=5;
  PkgStringGrid.RowCount:=FLinks.Count+1;
  PkgStringGrid.Cells[0, 0]:=lisName;
  PkgStringGrid.Cells[1, 0]:=lisVersion;
  PkgStringGrid.Cells[2, 0]:=dlgPLDPackageGroup;
  PkgStringGrid.Cells[3, 0]:=lisPLDExists;
  PkgStringGrid.Cells[4, 0]:=lisA2PFilename2;

  i:=1;
  Node:=FLinks.FindLowest;
  while Node<>nil do begin
    Link:=TPkgLinkInfo(Node.Data);
    PkgStringGrid.Cells[0,i]:=Link.Name;
    PkgStringGrid.Cells[1,i]:=Link.Version.AsString;
    if Link.Origin=ploGlobal then
      OriginStr:=lisPLDGlobal
    else
      OriginStr:=lisPLDUser;
    PkgStringGrid.Cells[2,i]:=OriginStr;
    PkgStringGrid.Cells[3,i]:=dbgs(FileExistsCached(Link.GetEffectiveFilename));
    PkgStringGrid.Cells[4,i]:=Link.GetEffectiveFilename;
    inc(i);
    Node:=Node.Successor;
  end;
  
  PkgStringGrid.AutoAdjustColumns;
end;

procedure TPackageLinksDialog.ClearLinks;
begin
  if FLinks<>nil then begin
    FLinks.FreeAndClear;
    FreeAndNil(FLinks);
  end;
end;

procedure TPackageLinksDialog.IteratePackages(APackage: TLazPackageID);
var
  NewLink: TPkgLinkInfo;
begin
  NewLink:=TPkgLinkInfo.Create;
  NewLink.Assign(APackage);
  NewLink.Origin:=FCollectingOrigin;
  FLinks.Add(NewLink);
end;

{ TPkgLinkInfo }

constructor TPkgLinkInfo.Create;
begin
  inherited Create;
  FLPKInfo:=TLPKInfo.Create(TLazPackageID.Create,false);
end;

destructor TPkgLinkInfo.Destroy;
begin
  FreeAndNil(FLPKInfo);
  inherited Destroy;
end;

procedure TPkgLinkInfo.Assign(Source: TPersistent);
var
  Link: TPackageLink;
begin
  if Source is TLazPackageID then begin
    AssignID(TLazPackageID(Source));
    LPKInfo.Assign(Source);
    if Source is TPackageLink then begin
      Link:=TPackageLink(Source);
      Origin:=Link.Origin;
      LPKFilename:=Link.LPKFilename;
      LPLFilename:=Link.LPLFilename;
      AutoCheckExists:=Link.AutoCheckExists;
      NotFoundCount:=Link.NotFoundCount;
      LastCheckValid:=Link.LastCheckValid;
      LastCheck:=Link.LastCheck;
      FileDateValid:=Link.FileDateValid;
      FileDate:=Link.FileDate;
    end;
  end else
    inherited Assign(Source);
end;

end.

