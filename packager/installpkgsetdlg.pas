{  $Id$  }
{
 /***************************************************************************
                         installpkgsetdlg.pas
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
    Dialog to edit the package set installed in the IDE.
}
unit InstallPkgSetDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, FileUtil,
  {$IFNDEF VER1_0}AVL_Tree{$ELSE}OldAvLTree{$ENDIF}, Laz_XMLCfg,
  LazarusIDEStrConsts, EnvironmentOpts, InputHistory, LazConf, IDEProcs,
  PackageDefs, PackageSystem;

type
  TOnCheckInstallPackageList =
                            procedure(PkgIDs: TList; var Ok: boolean) of object;

  { TInstallPkgSetDialog }

  TInstallPkgSetDialog = class(TForm)
    AddToInstallButton: TButton;
    AvailableListBox: TListBox;
    AvailablePkgGroupBox: TGroupBox;
    CancelButton: TButton;
    ExportButton: TButton;
    ImportButton: TButton;
    SaveAndRebuildButton: TButton;
    InstallListBox: TListBox;
    InstallPkgGroupBox: TGroupBox;
    SaveAndExitButton: TButton;
    UninstallButton: TButton;
    procedure AddToInstallButtonClick(Sender: TObject);
    procedure AvailableListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure ExportButtonClick(Sender: TObject);
    procedure ImportButtonClick(Sender: TObject);
    procedure InstallButtonClick(Sender: TObject);
    procedure InstallListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure InstallPkgSetDialogCreate(Sender: TObject);
    procedure InstallPkgSetDialogDestroy(Sender: TObject);
    procedure InstallPkgSetDialogResize(Sender: TObject);
    procedure SaveAndExitButtonClick(Sender: TObject);
    procedure UninstallButtonClick(Sender: TObject);
  private
    FNewInstalledPackages: TList;
    FOldInstalledPackages: TPkgDependency;
    FOnCheckInstallPackageList: TOnCheckInstallPackageList;
    fPackages: TAVLTree;// tree of TLazPackageID (all available packages and links)
    FRebuildIDE: boolean;
    procedure SetOldInstalledPackages(const AValue: TPkgDependency);
    procedure AssignOldInstalledPackagesToList;
    procedure UpdateAvailablePackages;
    procedure UpdateNewInstalledPackages;
    procedure OnIteratePackages(APackageID: TLazPackageID);
    function DependencyToStr(Dependency: TPkgDependency): string;
    procedure ClearNewInstalledPackages;
    function CheckSelection: boolean;
    procedure UpdateButtonStates;
    function NewInstalledPackagesContains(APackageID: TLazPackageID): boolean;
    function IndexOfNewInstalledPackageID(APackageID: TLazPackageID): integer;
    function IndexOfNewInstalledPkgByName(const APackageName: string): integer;
    procedure SavePackageListToFile(const AFilename: string);
    procedure LoadPackageListFromFile(const AFilename: string);
  public
    function GetNewInstalledPackages: TList;
    property OldInstalledPackages: TPkgDependency read FOldInstalledPackages
                                                  write SetOldInstalledPackages;
    property NewInstalledPackages: TList read FNewInstalledPackages;
    property RebuildIDE: boolean read FRebuildIDE write FRebuildIDE;
    property OnCheckInstallPackageList: TOnCheckInstallPackageList
               read FOnCheckInstallPackageList write FOnCheckInstallPackageList;
  end;

function ShowEditInstallPkgsDialog(OldInstalledPackages: TPkgDependency;
  CheckInstallPackageList: TOnCheckInstallPackageList;
  var NewInstalledPackages: TList; // list of TLazPackageID (must be freed)
  var RebuildIDE: boolean): TModalResult;

implementation

function ShowEditInstallPkgsDialog(OldInstalledPackages: TPkgDependency;
  CheckInstallPackageList: TOnCheckInstallPackageList;
  var NewInstalledPackages: TList; // list of TLazPackageID
  var RebuildIDE: boolean): TModalResult;
var
  InstallPkgSetDialog: TInstallPkgSetDialog;
begin
  InstallPkgSetDialog:=TInstallPkgSetDialog.Create(nil);
  try
    InstallPkgSetDialog.OldInstalledPackages:=OldInstalledPackages;
    InstallPkgSetDialog.UpdateAvailablePackages;
    InstallPkgSetDialog.UpdateButtonStates;
    InstallPkgSetDialog.OnCheckInstallPackageList:=CheckInstallPackageList;
    Result:=InstallPkgSetDialog.ShowModal;
    NewInstalledPackages:=InstallPkgSetDialog.GetNewInstalledPackages;
  finally
    InstallPkgSetDialog.Free;
  end;
end;

{ TInstallPkgSetDialog }

procedure TInstallPkgSetDialog.InstallPkgSetDialogCreate(Sender: TObject);
begin
  Caption:=lisInstalledPackages;
  AvailablePkgGroupBox.Caption:=lisAvailablePackages;
  ExportButton.Caption:=lisExportList;
  ImportButton.Caption:=lisImportList;
  UninstallButton.Caption:=lisUninstallSelection;
  InstallPkgGroupBox.Caption:=lisPackagesToInstallInTheIDE;
  AddToInstallButton.Caption:=lisInstallSelection;
  SaveAndRebuildButton.Caption:=lisSaveAndRebuildIDE;
  SaveAndExitButton.Caption:=lisSaveAndExitDialog;
  CancelButton.Caption:=dlgCancel;

  fPackages:=TAVLTree.Create(@CompareLazPackageIDNames);
  FNewInstalledPackages:=TList.Create;
end;

procedure TInstallPkgSetDialog.InstallButtonClick(Sender: TObject);
begin
  if not CheckSelection then exit;
  RebuildIDE:=true;
  ModalResult:=mrOk;
end;

procedure TInstallPkgSetDialog.AvailableListBoxSelectionChange(Sender: TObject;
  User: boolean);
begin
  UpdateButtonStates;
end;

procedure TInstallPkgSetDialog.ExportButtonClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  AFilename: string;
begin
  SaveDialog:=TSaveDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(SaveDialog);
    SaveDialog.InitialDir:=GetPrimaryConfigPath;
    SaveDialog.Title:='Export package list (*.xml)';
    SaveDialog.Options:=SaveDialog.Options+[ofPathMustExist];
    if SaveDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(SaveDialog.Filename);
      if ExtractFileExt(AFilename)='' then
        AFilename:=AFilename+'.xml';
      SavePackageListToFile(AFilename);
    end;
    InputHistories.StoreFileDialogSettings(SaveDialog);
  finally
    SaveDialog.Free;
  end;
end;

procedure TInstallPkgSetDialog.ImportButtonClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  AFilename: string;
begin
  OpenDialog:=TSaveDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.InitialDir:=GetPrimaryConfigPath;
    OpenDialog.Title:='Import package list (*.xml)';
    OpenDialog.Options:=OpenDialog.Options+[ofPathMustExist,ofFileMustExist];
    if OpenDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(OpenDialog.Filename);
      LoadPackageListFromFile(AFilename);
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TInstallPkgSetDialog.AddToInstallButtonClick(Sender: TObject);
var
  i: Integer;
  NewPackageID: TLazPackageID;
  j: LongInt;
  APackage: TLazPackage;
  Additions: TList;
begin
  Additions:=TList.Create;
  NewPackageID:=TLazPackageID.Create;
  try
    for i:=0 to AvailableListBox.Items.Count-1 do begin
      if not AvailableListBox.Selected[i] then continue;
      // check string
      if not NewPackageID.StringToID(AvailableListBox.Items[i]) then begin
        AvailableListBox.Selected[i]:=false;
        debugln('TInstallPkgSetDialog.AddToInstallButtonClick invalid ID: ',
                AvailableListBox.Items[i]);
        continue;
      end;
      // check if already in list
      if NewInstalledPackagesContains(NewPackageID) then begin
        MessageDlg('Double',
          'The package '+NewPackageID.Name+' is already in the list',mtError,
          [mbCancel],0);
        AvailableListBox.Selected[i]:=false;
        exit;
      end;
      // check if a package with same name is already in the list
      j:=IndexOfNewInstalledPkgByName(NewPackageID.Name);
      if j>=0 then begin
        MessageDlg('Conflict',
          'There is already a package '+NewPackageID.Name+' in the list',
          mtError,[mbCancel],0);
        AvailableListBox.Selected[i]:=false;
        exit;
      end;
      // check if package is loaded and has some attributes that prevents
      // installation in the IDE
      APackage:=PackageGraph.FindPackageWithID(NewPackageID);
      if APackage<>nil then begin
        if APackage.PackageType=lptRunTime then begin
          MessageDlg('Not a designtime package',
            'The package '+APackage.IDAsString+' is not a design time package.'
            +' It can not be installed in the IDE',mtError,
            [mbCancel],0);
          AvailableListBox.Selected[i]:=false;
          exit;
        end;
      end;
      // ok => add to list
      Additions.Add(NewPackageID);
      NewPackageID:=TLazPackageID.Create;
    end;
    AvailableListBox.ItemIndex:=-1;
    // all ok => add to list
    for i:=0 to Additions.Count-1 do
      FNewInstalledPackages.Add(Additions[i]);
    Additions.Clear;
    UpdateNewInstalledPackages;
    UpdateButtonStates;
  finally
    // clean up
    NewPackageID.Free;
    for i:=0 to Additions.Count-1 do
      TObject(Additions[i]).Free;
    Additions.Free;
  end;
end;

procedure TInstallPkgSetDialog.InstallListBoxSelectionChange(Sender: TObject;
  User: boolean);
begin
  UpdateButtonStates;
end;

procedure TInstallPkgSetDialog.InstallPkgSetDialogDestroy(Sender: TObject);
begin
  ClearNewInstalledPackages;
  FNewInstalledPackages.Free;
  fPackages.Free;
end;

procedure TInstallPkgSetDialog.InstallPkgSetDialogResize(Sender: TObject);
var
  x: Integer;
  w: Integer;
begin
  x:=10;
  w:=(ClientWidth-3*x) div 2;
  with InstallPkgGroupBox do
    SetBounds(x,Top,w,Height);
  with AvailablePkgGroupBox do
    SetBounds(x+w+x,Top,w,Height);
end;

procedure TInstallPkgSetDialog.SaveAndExitButtonClick(Sender: TObject);
begin
  if not CheckSelection then exit;
  RebuildIDE:=false;
  ModalResult:=mrOk;
end;

procedure TInstallPkgSetDialog.UninstallButtonClick(Sender: TObject);
var
  i: Integer;
  OldPackageID: TLazPackageID;
  APackage: TLazPackage;
  Deletions: TList;
begin
  Deletions:=TList.Create;
  try
    for i:=0 to InstallListBox.Items.Count-1 do begin
      if not InstallListBox.Selected[i] then continue;
      OldPackageID:=TLazPackageID(FNewInstalledPackages[i]);
      // get package
      APackage:=PackageGraph.FindPackageWithID(OldPackageID);
      if APackage<>nil then begin
        // check if package is a base package
        if APackage.AutoCreated then begin
          InstallListBox.Selected[i]:=false;
          MessageDlg('Uninstall impossible',
            'The package '+APackage.Name+' can not be uninstalled, because it '
            +'is needed by the IDE itself.',mtError,[mbCancel],0);
          exit;
        end;
      end;
      // ok => add to deletions
      Deletions.Add(OldPackageID);
    end;
    // ok => remove from list
    InstallListBox.ItemIndex:=-1;
    for i:=0 to Deletions.Count-1 do begin
      OldPackageID:=TLazPackageID(Deletions[i]);
      FNewInstalledPackages.Remove(OldPackageID);
      OldPackageID.Free;
    end;
    UpdateNewInstalledPackages;
    UpdateButtonStates;
  finally
    Deletions.Free;
  end;
end;

procedure TInstallPkgSetDialog.SetOldInstalledPackages(
  const AValue: TPkgDependency);
begin
  if FOldInstalledPackages=AValue then exit;
  FOldInstalledPackages:=AValue;
  AssignOldInstalledPackagesToList;
end;

procedure TInstallPkgSetDialog.AssignOldInstalledPackagesToList;
var
  Dependency: TPkgDependency;
  Cnt: Integer;
  NewPackageID: TLazPackageID;
begin
  ClearNewInstalledPackages;
  Cnt:=0;
  Dependency:=OldInstalledPackages;
  while Dependency<>nil do begin
    NewPackageID:=TLazPackageID.Create;
    if (Dependency.LoadPackageResult=lprSuccess)
    and (Dependency.RequiredPackage<>nil) then begin
      NewPackageID.AssignID(Dependency.RequiredPackage);
    end else begin
      NewPackageID.Name:=Dependency.PackageName;
    end;
    FNewInstalledPackages.Add(NewPackageID);
    Dependency:=Dependency.NextRequiresDependency;
    inc(Cnt);
  end;
  UpdateNewInstalledPackages;
end;

procedure TInstallPkgSetDialog.UpdateAvailablePackages;
var
  ANode: TAVLTreeNode;
  sl: TStringList;
  PkgName: String;
  Pkg: TLazPackageID;
begin
  fPackages.Clear;
  // TODO: only distinct files
  PackageGraph.IteratePackages(fpfSearchAllExisting,@OnIteratePackages);
  sl:=TStringList.Create;
  ANode:=fPackages.FindLowest;
  while ANode<>nil do begin
    Pkg:=TLazPackageID(ANode.Data);
    PkgName:=Pkg.IDAsString;
    if (sl.IndexOf(PkgName)<0) then
      sl.Add(PkgName);
    ANode:=fPackages.FindSuccessor(ANode);
  end;
  AvailableListBox.Items.Assign(sl);
  sl.Free;
end;

procedure TInstallPkgSetDialog.UpdateNewInstalledPackages;
var
  s: String;
  NewPackageID: TLazPackageID;
  i: Integer;
begin
  InstallListBox.Items.BeginUpdate;
  for i:=0 to FNewInstalledPackages.Count-1 do begin
    NewPackageID:=TLazPackageID(FNewInstalledPackages[i]);
    s:=NewPackageID.IDAsString;
    if InstallListBox.Items.Count>i then
      InstallListBox.Items[i]:=s
    else
      InstallListBox.Items.Add(s);
  end;
  while InstallListBox.Items.Count>FNewInstalledPackages.Count do
    InstallListBox.Items.Delete(InstallListBox.Items.Count-1);
  InstallListBox.Items.EndUpdate;
end;

procedure TInstallPkgSetDialog.OnIteratePackages(APackageID: TLazPackageID);
begin
  if (fPackages.Find(APackageID)=nil) then
    fPackages.Add(APackageID);
end;

function TInstallPkgSetDialog.DependencyToStr(Dependency: TPkgDependency
  ): string;
begin
  Result:='';
  if Dependency=nil then exit;
  if (Dependency.LoadPackageResult=lprSuccess)
  and (Dependency.RequiredPackage<>nil) then
    Result:=Dependency.RequiredPackage.IDAsString
  else
    Result:=Dependency.PackageName;
end;

procedure TInstallPkgSetDialog.ClearNewInstalledPackages;
var
  i: Integer;
begin
  for i:=0 to FNewInstalledPackages.Count-1 do
    TObject(FNewInstalledPackages[i]).Free;
end;

function TInstallPkgSetDialog.CheckSelection: boolean;
begin
  OnCheckInstallPackageList(FNewInstalledPackages,Result);
end;

procedure TInstallPkgSetDialog.UpdateButtonStates;
var
  Cnt: Integer;
  Dependency: TPkgDependency;
  s: String;
  ListChanged: Boolean;
begin
  UninstallButton.Enabled:=InstallListBox.ItemIndex>=0;
  AddToInstallButton.Enabled:=AvailableListBox.ItemIndex>=0;
  // check for changes
  ListChanged:=false;
  Cnt:=0;
  Dependency:=OldInstalledPackages;
  while Dependency<>nil do begin
    s:=DependencyToStr(Dependency);
    if InstallListBox.Items.IndexOf(s)<0 then begin
      ListChanged:=true;
      break;
    end;
    Dependency:=Dependency.NextRequiresDependency;
    inc(Cnt);
  end;
  if InstallListBox.Items.Count<>Cnt then
    ListChanged:=true;
  SaveAndExitButton.Enabled:=ListChanged;
  SaveAndRebuildButton.Enabled:=ListChanged;
end;

function TInstallPkgSetDialog.NewInstalledPackagesContains(
  APackageID: TLazPackageID): boolean;
begin
  Result:=IndexOfNewInstalledPackageID(APackageID)>=0;
end;

function TInstallPkgSetDialog.IndexOfNewInstalledPackageID(
  APackageID: TLazPackageID): integer;
begin
  Result:=FNewInstalledPackages.Count-1;
  while (Result>=0)
  and (TLazPackageID(FNewInstalledPackages[Result]).Compare(APackageID)<>0) do
    dec(Result);
end;

function TInstallPkgSetDialog.IndexOfNewInstalledPkgByName(
  const APackageName: string): integer;
begin
  Result:=FNewInstalledPackages.Count-1;
  while (Result>=0)
  and (CompareText(TLazPackageID(FNewInstalledPackages[Result]).Name,
       APackageName)<>0)
  do
    dec(Result);
end;

procedure TInstallPkgSetDialog.SavePackageListToFile(const AFilename: string);
var
  XMLConfig: TXMLConfig;
  i: Integer;
  LazPackageID: TLazPackageID;
begin
  try
    XMLConfig:=TXMLConfig.CreateClean(AFilename);
    try
      XMLConfig.SetDeleteValue('Packages/Count',FNewInstalledPackages.Count,0);
      for i:=0 to FNewInstalledPackages.Count-1 do begin
        LazPackageID:=TLazPackageID(FNewInstalledPackages[i]);
        XMLConfig.SetDeleteValue('Packages/Item'+IntToStr(i)+'/ID',
                                 LazPackageID.IDAsString,'');
      end;
      InvalidateFileStateCache;
      XMLConfig.Flush;
    finally
      XMLConfig.Free;
    end;
  except
    on E: Exception do begin
      MessageDlg(lisCodeToolsDefsWriteError,
        Format(lisErrorWritingPackageListToFile, [#13, AFilename, #13, E.Message
          ]), mtError, [mbCancel], 0);
    end;
  end;
end;

procedure TInstallPkgSetDialog.LoadPackageListFromFile(const AFilename: string
  );
  
  function PkgNameExists(List: TList; ID: TLazPackageID): boolean;
  var
    i: Integer;
    LazPackageID: TLazPackageID;
  begin
    for i:=0 to List.Count-1 do begin
      LazPackageID:=TLazPackageID(List[i]);
      if CompareText(LazPackageID.Name,ID.Name)=0 then begin
        Result:=true;
        exit;
      end;
    end;
    Result:=false;
  end;
  
var
  XMLConfig: TXMLConfig;
  i: Integer;
  LazPackageID: TLazPackageID;
  NewCount: LongInt;
  NewList: TList;
  ID: String;
begin
  NewList:=nil;
  LazPackageID:=nil;
  try
    XMLConfig:=TXMLConfig.Create(AFilename);
    try
      NewCount:=XMLConfig.GetValue('Packages/Count',0);
      LazPackageID:=TLazPackageID.Create;
      for i:=0 to NewCount-1 do begin
        // get ID
        ID:=XMLConfig.GetValue('Packages/Item'+IntToStr(i)+'/ID','');
        if ID='' then continue;
        // parse ID
        if not LazPackageID.StringToID(ID) then continue;
        // ignore doubles
        if PkgNameExists(NewList,LazPackageID) then continue;
        // add
        if NewList=nil then NewList:=TList.Create;
        NewList.Add(LazPackageID);
        LazPackageID:=TLazPackageID.Create;
      end;
      // clean up old list
      for i:=0 to FNewInstalledPackages.Count-1 do
        TObject(FNewInstalledPackages[i]).Free;
      FNewInstalledPackages.Clear;
      // assign new list
      FNewInstalledPackages:=NewList;
      NewList:=nil;
    finally
      XMLConfig.Free;
      LazPackageID.Free;
      if NewList<>nil then begin
        for i:=0 to NewList.Count-1 do TObject(NewList[i]).Free;
        NewList.Free;
      end;
    end;
  except
    on E: Exception do begin
      MessageDlg(lisCodeToolsDefsReadError,
        Format(lisErrorReadingPackageListFromFile, [#13, AFilename, #13,
          E.Message]), mtError, [mbCancel], 0);
    end;
  end;
end;

function TInstallPkgSetDialog.GetNewInstalledPackages: TList;
var
  i: Integer;
  NewPackageID: TLazPackageID;
begin
  Result:=TList.Create;
  for i:=0 to FNewInstalledPackages.Count-1 do begin
    NewPackageID:=TLazPackageID.Create;
    NewPackageID.AssignID(TLazPackageID(FNewInstalledPackages[i]));
    Result.Add(NewPackageID);
  end;
end;

initialization
  {$I installpkgsetdlg.lrs}

end.

