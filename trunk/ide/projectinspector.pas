{  $Id$  }
{
 /***************************************************************************
                          projectinspector.pas
                          --------------------


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
    TProjectInspectorForm is the form of the project inspector.
}
unit ProjectInspector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Buttons, ComCtrls,
  StdCtrls, ExtCtrls, Menus, Dialogs, Graphics, FileCtrl,
  LazarusIDEStrConsts, IDEProcs, IDEOptionDefs, EnvironmentOpts,
  Project, AddToProjectDlg, PackageSystem, PackageDefs;
  
type
  TOnAddUnitToProject =
    function(Sender: TObject; AnUnitInfo: TUnitInfo): TModalresult of object;

  TProjectInspectorFlag = (
    pifItemsChanged,
    pifButtonsChanged,
    pifTitleChanged
    );
  TProjectInspectorFlags = set of TProjectInspectorFlag;

  TProjectInspectorForm = class(TForm)
    OpenBitBtn: TBitBtn;
    AddBitBtn: TBitBtn;
    RemoveBitBtn: TBitBtn;
    OptionsBitBtn: TBitBtn;
    ItemsTreeView: TTreeView;
    ImageList: TImageList;
    ItemsPopupMenu: TPopupMenu;
    procedure AddBitBtnClick(Sender: TObject);
    procedure ItemsPopupMenuPopup(Sender: TObject);
    procedure ItemsTreeViewDblClick(Sender: TObject);
    procedure ItemsTreeViewSelectionChanged(Sender: TObject);
    procedure OpenBitBtnClick(Sender: TObject);
    procedure OptionsBitBtnClick(Sender: TObject);
    procedure ProjectInspectorFormResize(Sender: TObject);
    procedure ProjectInspectorFormShow(Sender: TObject);
    procedure RemoveBitBtnClick(Sender: TObject);
  private
    FOnAddUnitToProject: TOnAddUnitToProject;
    FOnOpen: TNotifyEvent;
    FOnShowOptions: TNotifyEvent;
    FUpdateLock: integer;
    FLazProject: TProject;
    FilesNode: TTreeNode;
    DependenciesNode: TTreeNode;
    RemovedDependenciesNode: TTreeNode;
    ImageIndexFiles: integer;
    ImageIndexRequired: integer;
    ImageIndexConflict: integer;
    ImageIndexRemovedRequired: integer;
    ImageIndexProject: integer;
    ImageIndexUnit: integer;
    ImageIndexRegisterUnit: integer;
    ImageIndexText: integer;
    ImageIndexBinary: integer;
    FFlags: TProjectInspectorFlags;
    procedure SetLazProject(const AValue: TProject);
    procedure SetupComponents;
    procedure UpdateProjectItems;
    procedure UpdateRequiredPackages;
    procedure UpdateRemovedRequiredPackages;
    function GetImageIndexOfFile(AFile: TUnitInfo): integer;
    procedure OnProjectBeginUpdate(Sender: TObject);
    procedure OnProjectEndUpdate(Sender: TObject; ProjectChanged: boolean);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    function IsUpdating: boolean;
    procedure UpdateAll;
    procedure UpdateTitle;
    procedure UpdateButtons;
    procedure UpdateItems;
    function GetSelectedFile: TUnitInfo;
    function GetSelectedDependency: TPkgDependency;
  public
    property LazProject: TProject read FLazProject write SetLazProject;
    property OnOpen: TNotifyEvent read FOnOpen write FOnOpen;
    property OnShowOptions: TNotifyEvent read FOnShowOptions write FOnShowOptions;
    property OnAddUnitToProject: TOnAddUnitToProject read FOnAddUnitToProject
                                                     write FOnAddUnitToProject;
  end;
  
var
  ProjInspector: TProjectInspectorForm;


implementation

{ TProjectInspectorForm }

procedure TProjectInspectorForm.ProjectInspectorFormResize(Sender: TObject);
var
  x: Integer;
  y: Integer;
  w: Integer;
  h: Integer;
begin
  x:=0;
  y:=0;
  w:=(ClientWidth div 4);
  h:=25;
  with OptionsBitBtn do
    SetBounds(x,y,w,h);
  inc(x,w);
  
  with OpenBitBtn do
    SetBounds(x,y,w,h);
  inc(x,w);

  with AddBitBtn do
    SetBounds(x,y,w,h);
  inc(x,w);

  w:=ClientWidth-x;
  with RemoveBitBtn do
    SetBounds(x,y,w,h);
  inc(x,w);

  x:=0;
  inc(y,h);
  with ItemsTreeView do
    SetBounds(x,y,Parent.ClientWidth,Parent.ClientHeight-y);
end;

procedure TProjectInspectorForm.ItemsTreeViewDblClick(Sender: TObject);
begin
  OpenBitBtnClick(Self);
end;

procedure TProjectInspectorForm.ItemsTreeViewSelectionChanged(Sender: TObject);
begin
  UpdateButtons;
end;

procedure TProjectInspectorForm.AddBitBtnClick(Sender: TObject);
var
  AddResult: TAddToProjectResult;
  NewFile: TUnitInfo;
  i: Integer;
  RequiredPackage: TLazPackage;
begin
  if ShowAddToProjectDlg(LazProject,AddResult)<>mrOk then exit;
  
  case AddResult.AddType of
  a2pFiles:
    begin
      BeginUpdate;
      for i:=0 to AddResult.Files.Count-1 do begin
        NewFile:=TUnitInfo(AddResult.Files[i]);
        NewFile.IsPartOfProject:=true;
        if Assigned(OnAddUnitToProject) then begin
          if OnAddUnitToProject(Self,NewFile)<>mrOk then break;
        end;
      end;
      UpdateAll;
      EndUpdate;
    end;
  
  a2pRequiredPkg:
    begin
      BeginUpdate;
      LazProject.AddRequiredDependency(AddResult.Dependency);
      PackageGraph.OpenDependency(AddResult.Dependency,RequiredPackage);
      UpdateItems;
      EndUpdate;
    end;
  
  end;
  
  AddResult.Free;
end;

procedure TProjectInspectorForm.ItemsPopupMenuPopup(Sender: TObject);
begin

end;

procedure TProjectInspectorForm.OpenBitBtnClick(Sender: TObject);
begin
  if Assigned(OnOpen) then OnOpen(Self);
end;

procedure TProjectInspectorForm.OptionsBitBtnClick(Sender: TObject);
begin
  if Assigned(OnShowOptions) then OnShowOptions(Self);
end;

procedure TProjectInspectorForm.ProjectInspectorFormShow(Sender: TObject);
begin
  UpdateAll;
end;

procedure TProjectInspectorForm.RemoveBitBtnClick(Sender: TObject);
begin

end;

procedure TProjectInspectorForm.SetLazProject(const AValue: TProject);
begin
  if FLazProject=AValue then exit;
  if FLazProject<>nil then begin
    FLazProject.OnBeginUpdate:=nil;
    FLazProject.OnEndUpdate:=nil;
  end;
  FLazProject:=AValue;
  if FLazProject<>nil then begin
    FLazProject.OnBeginUpdate:=@OnProjectBeginUpdate;
    FLazProject.OnEndUpdate:=@OnProjectEndUpdate;
  end;
  UpdateAll;
end;

procedure TProjectInspectorForm.SetupComponents;

  procedure AddResImg(const ResName: string);
  var Pixmap: TPixmap;
  begin
    Pixmap:=TPixmap.Create;
    Pixmap.TransparentColor:=clWhite;
    Pixmap.LoadFromLazarusResource(ResName);
    ImageList.Add(Pixmap,nil)
  end;

begin
  ImageList:=TImageList.Create(Self);
  with ImageList do begin
    Width:=17;
    Height:=17;
    Name:='ImageList';
    ImageIndexFiles:=Count;
    AddResImg('pkg_files');
    ImageIndexRequired:=Count;
    AddResImg('pkg_required');
    ImageIndexConflict:=Count;
    AddResImg('pkg_conflict');
    ImageIndexRemovedRequired:=Count;
    AddResImg('pkg_removedrequired');
    ImageIndexProject:=Count;
    AddResImg('pkg_project');
    ImageIndexUnit:=Count;
    AddResImg('pkg_unit');
    ImageIndexRegisterUnit:=Count;
    AddResImg('pkg_registerunit');
    ImageIndexText:=Count;
    AddResImg('pkg_text');
    ImageIndexBinary:=Count;
    AddResImg('pkg_binary');
  end;

  ItemsPopupMenu:=TPopupMenu.Create(Self);
  with ItemsPopupMenu do begin
    OnPopup:=@ItemsPopupMenuPopup;
  end;

  OpenBitBtn:=TBitBtn.Create(Self);
  with OpenBitBtn do begin
    Name:='OpenBitBtn';
    Parent:=Self;
    Caption:='Open';
    OnClick:=@OpenBitBtnClick;
  end;

  AddBitBtn:=TBitBtn.Create(Self);
  with AddBitBtn do begin
    Name:='AddBitBtn';
    Parent:=Self;
    Caption:='Add';
    OnClick:=@AddBitBtnClick;
  end;

  OptionsBitBtn:=TBitBtn.Create(Self);
  with OptionsBitBtn do begin
    Name:='OptionsBitBtn';
    Parent:=Self;
    Caption:='Options';
    OnClick:=@OptionsBitBtnClick;
  end;

  RemoveBitBtn:=TBitBtn.Create(Self);
  with RemoveBitBtn do begin
    Name:='RemoveBitBtn';
    Parent:=Self;
    Caption:='Remove';
    OnClick:=@RemoveBitBtnClick;
  end;

  ItemsTreeView:=TTreeView.Create(Self);
  with ItemsTreeView do begin
    Name:='ItemsTreeView';
    Parent:=Self;
    Images:=ImageList;
    Options:=Options+[tvoRightClickSelect];
    OnSelectionChanged:=@ItemsTreeViewSelectionChanged;
    OnDblClick:=@ItemsTreeViewDblClick;
    FilesNode:=Items.Add(nil,'Files');
    FilesNode.ImageIndex:=ImageIndexFiles;
    FilesNode.SelectedIndex:=FilesNode.ImageIndex;
    DependenciesNode:=Items.Add(nil,'Required Packages');
    DependenciesNode.ImageIndex:=ImageIndexRequired;
    DependenciesNode.SelectedIndex:=DependenciesNode.ImageIndex;
    PopupMenu:=ItemsPopupMenu;
  end;
end;

procedure TProjectInspectorForm.UpdateProjectItems;
var
  CurFile: TUnitInfo;
  CurNode: TTreeNode;
  NodeText: String;
  NextNode: TTreeNode;
begin
  ItemsTreeView.BeginUpdate;
  if LazProject<>nil then begin
    CurFile:=LazProject.FirstPartOfProject;
    CurNode:=FilesNode.GetFirstChild;
    while CurFile<>nil do begin
      NodeText:=
        CreateRelativePath(CurFile.Filename,LazProject.ProjectDirectory);
      if CurNode=nil then
        CurNode:=ItemsTreeView.Items.AddChild(FilesNode,NodeText)
      else
        CurNode.Text:=NodeText;
      CurNode.ImageIndex:=GetImageIndexOfFile(CurFile);
      CurNode.SelectedIndex:=CurNode.ImageIndex;
      CurFile:=CurFile.NextPartOfProject;
      CurNode:=CurNode.GetNextSibling;
    end;
    while CurNode<>nil do begin
      NextNode:=CurNode.GetNextSibling;
      CurNode.Free;
      CurNode:=NextNode;
    end;
    FilesNode.Expanded:=true;
  end else begin
    // delete file nodes
    FilesNode.HasChildren:=false;
  end;
  ItemsTreeView.EndUpdate;
end;

procedure TProjectInspectorForm.UpdateRequiredPackages;
var
  Dependency: TPkgDependency;
  NodeText: String;
  CurNode: TTreeNode;
  NextNode: TTreeNode;
begin
  ItemsTreeView.BeginUpdate;
  if LazProject<>nil then begin
    Dependency:=LazProject.FirstRequiredDependency;
    CurNode:=DependenciesNode.GetFirstChild;
    while Dependency<>nil do begin
      NodeText:=Dependency.AsString;
      if CurNode=nil then
        CurNode:=ItemsTreeView.Items.AddChild(DependenciesNode,NodeText)
      else
        CurNode.Text:=NodeText;
      if Dependency.LoadPackageResult=lprSuccess then
        CurNode.ImageIndex:=ImageIndexRequired
      else
        CurNode.ImageIndex:=ImageIndexConflict;
      CurNode.SelectedIndex:=CurNode.ImageIndex;
      Dependency:=Dependency.NextRequiresDependency;
      CurNode:=CurNode.GetNextSibling;
    end;
    while CurNode<>nil do begin
      NextNode:=CurNode.GetNextSibling;
      CurNode.Free;
      CurNode:=NextNode;
    end;
    DependenciesNode.Expanded:=true;
  end else begin
    // delete dependency nodes
    DependenciesNode.HasChildren:=false;
  end;
  ItemsTreeView.EndUpdate;
end;

procedure TProjectInspectorForm.UpdateRemovedRequiredPackages;
var
  Dependency: TPkgDependency;
  NodeText: String;
  CurNode: TTreeNode;
  NextNode: TTreeNode;
begin
  ItemsTreeView.BeginUpdate;
  if (LazProject<>nil) and (LazProject.FirstRemovedDependency<>nil) then begin
    Dependency:=LazProject.FirstRemovedDependency;
    if RemovedDependenciesNode=nil then begin
      RemovedDependenciesNode:=
        ItemsTreeView.Items.Add(DependenciesNode,'Removed required packages');
      RemovedDependenciesNode.ImageIndex:=ImageIndexRemovedRequired;
      RemovedDependenciesNode.SelectedIndex:=RemovedDependenciesNode.ImageIndex;
    end;
    CurNode:=RemovedDependenciesNode.GetFirstChild;
    while Dependency<>nil do begin
      NodeText:=Dependency.AsString;
      if CurNode=nil then
        CurNode:=ItemsTreeView.Items.AddChild(RemovedDependenciesNode,NodeText)
      else
        CurNode.Text:=NodeText;
      CurNode.ImageIndex:=RemovedDependenciesNode.ImageIndex;
      CurNode.SelectedIndex:=CurNode.ImageIndex;
      Dependency:=Dependency.NextRequiresDependency;
      CurNode:=CurNode.GetNextSibling;
    end;
    while CurNode<>nil do begin
      NextNode:=CurNode.GetNextSibling;
      CurNode.Free;
      CurNode:=NextNode;
    end;
    DependenciesNode.Expanded:=true;
  end else begin
    // delete removed dependency nodes
    if RemovedDependenciesNode<>nil then
      FreeThenNil(RemovedDependenciesNode);
  end;
  ItemsTreeView.EndUpdate;
end;

function TProjectInspectorForm.GetImageIndexOfFile(AFile: TUnitInfo): integer;
begin
  if FilenameIsPascalUnit(AFile.Filename) then
    Result:=ImageIndexUnit
  else if (LazProject<>nil) and (LazProject.MainUnitinfo=AFile) then
    Result:=ImageIndexProject
  else
    Result:=ImageIndexText;
end;

procedure TProjectInspectorForm.OnProjectBeginUpdate(Sender: TObject);
begin
  BeginUpdate;
end;

procedure TProjectInspectorForm.OnProjectEndUpdate(Sender: TObject;
  ProjectChanged: boolean);
begin
  UpdateAll;
  EndUpdate;
end;

function TProjectInspectorForm.GetSelectedFile: TUnitInfo;
var
  CurNode: TTreeNode;
  NodeIndex: Integer;
begin
  Result:=nil;
  if LazProject=nil then exit;
  CurNode:=ItemsTreeView.Selected;
  if (CurNode=nil) or (CurNode.Parent<>FilesNode) then exit;
  NodeIndex:=CurNode.Index;
  Result:=LazProject.FirstPartOfProject;
  while (NodeIndex>0) and (Result<>nil) do begin
    Result:=Result.NextPartOfProject;
    dec(NodeIndex);
  end;
end;

function TProjectInspectorForm.GetSelectedDependency: TPkgDependency;
var
  CurNode: TTreeNode;
  NodeIndex: Integer;
begin
  Result:=nil;
  if LazProject=nil then exit;
  CurNode:=ItemsTreeView.Selected;
  if (CurNode=nil) then exit;
  NodeIndex:=CurNode.Index;
  if (CurNode.Parent=DependenciesNode) then begin
    Result:=GetDependencyWithIndex(LazProject.FirstRequiredDependency,
                                   pdlRequires,NodeIndex);
  end;
  if (CurNode.Parent=RemovedDependenciesNode) then begin
    Result:=GetDependencyWithIndex(LazProject.FirstRemovedDependency,
                                   pdlRequires,NodeIndex);
  end;
end;

constructor TProjectInspectorForm.Create(TheOwner: TComponent);
var
  ALayout: TIDEWindowLayout;
begin
  inherited Create(TheOwner);
  Name:=NonModalIDEWindowNames[nmiwProjectInspector];
  Caption:='Project Inspector';

  ALayout:=EnvironmentOptions.IDEWindowLayoutList.ItemByFormID(Name);
  ALayout.Form:=TForm(Self);
  ALayout.Apply;

  SetupComponents;
  OnResize:=@ProjectInspectorFormResize;
  OnResize(Self);
  OnShow:=@ProjectInspectorFormShow;
end;

destructor TProjectInspectorForm.Destroy;
begin
  BeginUpdate;
  LazProject:=nil;
  inherited Destroy;
end;

procedure TProjectInspectorForm.BeginUpdate;
begin
  inc(FUpdateLock);
end;

procedure TProjectInspectorForm.EndUpdate;
begin
  if FUpdateLock=0 then RaiseException('TProjectInspectorForm.EndUpdate');
  dec(FUpdateLock);
  if FUpdateLock=0 then begin
    if pifTitleChanged in FFlags then UpdateTitle;
    if pifButtonsChanged in FFlags then UpdateButtons;
    if pifItemsChanged in FFlags then UpdateItems;
  end;
end;

function TProjectInspectorForm.IsUpdating: boolean;
begin
  Result:=FUpdateLock>0;
end;

procedure TProjectInspectorForm.UpdateAll;
begin
  UpdateTitle;
  UpdateButtons;
  UpdateItems;
end;

procedure TProjectInspectorForm.UpdateTitle;
var
  NewCaption: String;
begin
  if (FUpdateLock>0) or (not Visible) then begin
    Include(FFlags,pifTitleChanged);
    exit;
  end;
  Exclude(FFlags,pifTitleChanged);
  if LazProject=nil then
    Caption:='Project Inspector'
  else begin
    NewCaption:=LazProject.Title;
    if NewCaption='' then
      NewCaption:=ExtractFilenameOnly(LazProject.ProjectInfoFile);
    Caption:='Project Inspector - '+NewCaption;
  end;
end;

procedure TProjectInspectorForm.UpdateButtons;
var
  CurFile: TUnitInfo;
begin
  if (FUpdateLock>0) or (not Visible) then begin
    Include(FFlags,pifButtonsChanged);
    exit;
  end;
  Exclude(FFlags,pifButtonsChanged);
  if LazProject<>nil then begin
    AddBitBtn.Enabled:=true;
    CurFile:=GetSelectedFile;
    RemoveBitBtn.Enabled:=(CurFile<>nil) and (CurFile<>LazProject.MainUnitInfo);
    OpenBitBtn.Enabled:=(CurFile<>nil);
    OptionsBitBtn.Enabled:=true;
  end else begin
    AddBitBtn.Enabled:=false;
    RemoveBitBtn.Enabled:=false;
    OpenBitBtn.Enabled:=false;
    OptionsBitBtn.Enabled:=false;
  end;
end;

procedure TProjectInspectorForm.UpdateItems;
begin
  if (FUpdateLock>0) or (not Visible) then begin
    Include(FFlags,pifItemsChanged);
    exit;
  end;
  Exclude(FFlags,pifItemsChanged);
  ItemsTreeView.BeginUpdate;
  UpdateProjectItems;
  UpdateRequiredPackages;
  UpdateRemovedRequiredPackages;
  ItemsTreeView.EndUpdate;
end;


initialization
  ProjInspector:=nil;

end.

