{  $Id$  }
{
 /***************************************************************************
                          addtoprojectdlg.pas
                          -------------------


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
unit AddToProjectDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Buttons, ComCtrls,
  StdCtrls, ExtCtrls, Menus, Dialogs, Graphics, FileCtrl, AVL_Tree,
  LazarusIDEStrConsts, IDEProcs, IDEOptionDefs, EnvironmentOpts,
  Project, PackageDefs, PackageSystem;
  
type
  TAddToProjectType = (
    a2pFiles,
    a2pRequiredPkg
    );

  TAddToProjectResult = class
  public
    AddType: TAddToProjectType;
    Dependency: TPkgDependency;
    Files: TList; // list of TUnitInfo
    destructor Destroy; override;
  end;

  TAddToProjectDialog = class(TForm)
    // notebook
    NoteBook: TNoteBook;
    AddFilePage: TPage;
    NewDependPage: TPage;
    // add file page
    AddFileLabel: TLabel;
    AddFileListBox: TListBox;
    AddFileButton: TButton;
    CancelAddFileButton: TButton;
    // new required package
    DependPkgNameLabel: TLabel;
    DependPkgNameComboBox: TComboBox;
    DependMinVersionLabel: TLabel;
    DependMinVersionEdit: TEdit;
    DependMaxVersionLabel: TLabel;
    DependMaxVersionEdit: TEdit;
    NewDependButton: TButton;
    CancelDependButton: TButton;
    procedure AddFileButtonClick(Sender: TObject);
    procedure AddFilePageResize(Sender: TObject);
    procedure AddToProjectDialogClose(Sender: TObject; var Action: TCloseAction
      );
    procedure NewDependButtonClick(Sender: TObject);
    procedure NewDependPageResize(Sender: TObject);
  private
    fPackages: TAVLTree;// tree of  TLazPackage or TPackageLink
    procedure SetupComponents;
    procedure OnIteratePackages(APackageID: TLazPackageID);
  public
    AddResult: TAddToProjectResult;
    TheProject: TProject;
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdateAvailableDependencyNames;
    procedure UpdateAvailableFiles;
  end;
  
function ShowAddToProjectDlg(AProject: TProject;
  var AddResult: TAddToProjectResult): TModalResult;
function CheckAddingDependency(LazProject: TProject;
  NewDependency: TPkgDependency): boolean;


implementation


uses
  Math;
  
function ShowAddToProjectDlg(AProject: TProject;
  var AddResult: TAddToProjectResult): TModalResult;
var
  AddToProjectDialog: TAddToProjectDialog;
begin
  AddToProjectDialog:=TAddToProjectDialog.Create(Application);
  AddToProjectDialog.TheProject:=AProject;
  AddToProjectDialog.UpdateAvailableFiles;
  AddToProjectDialog.UpdateAvailableDependencyNames;
  Result:=AddToProjectDialog.ShowModal;
  if Result=mrOk then begin
    AddResult:=AddToProjectDialog.AddResult;
    AddToProjectDialog.AddResult:=nil;
  end else begin
    AddResult:=nil;
  end;
  AddToProjectDialog.Free;
end;

function CheckAddingDependency(LazProject: TProject;
  NewDependency: TPkgDependency): boolean;
var
  NewPkgName: String;
begin
  Result:=false;
  
  NewPkgName:=NewDependency.PackageName;

  // check Max-Min version
  if (pdfMinVersion in NewDependency.Flags)
  and (pdfMaxVersion in NewDependency.Flags)
  and (NewDependency.MaxVersion.Compare(NewDependency.MinVersion)<0) then
  begin
    MessageDlg('Invalid Min-Max version',
      'The Maximum Version is lower than the Minimim Version.',
      mtError,[mbCancel],0);
    exit;
  end;

  // check packagename
  if (NewPkgName='') or (not IsValidIdent(NewPkgName)) then begin
    MessageDlg('Invalid packagename',
      'The package name "'+NewPkgName+'" is invalid.'#13
      +'Plase choose an existing package.',
      mtError,[mbCancel],0);
    exit;
  end;

  // check if package is already required
  if LazProject.FindDependencyByName(NewPkgName)<>nil then begin
    MessageDlg('Dependency already exists',
      'The project has already a dependency for the package "'+NewPkgName+'".',
      mtError,[mbCancel],0);
    exit;
  end;

  // check if required package exists
  if not PackageGraph.DependencyExists(NewDependency,fpfSearchPackageEverywhere)
  then begin
    MessageDlg('Package not found',
      'The dependency "'+NewDependency.AsString+'" was not found.'#13
      +'Please choose an existing package.',
      mtError,[mbCancel],0);
    exit;
  end;

  Result:=true;
end;

{ TAddToProjectDialog }

procedure TAddToProjectDialog.AddFilePageResize(Sender: TObject);
var
  y: Integer;
  x: Integer;
  w: Integer;
begin
  with AddFileLabel do
    SetBounds(3,3,Parent.ClientWidth-6,22);
    
  y:=AddFileLabel.Top+AddFileLabel.Height+4;
  with AddFileListBox do
    SetBounds(0,y,Max(Parent.ClientWidth-90,10),Parent.ClientHeight-y);
    
  x:=ClientWidth-80;
  y:=AddFileListBox.Top+10;
  w:=70;
  with AddFileButton do
    SetBounds(x,y,w,Height);
  inc(y,AddFileButton.Height+10);

  with CancelAddFileButton do
    SetBounds(x,y,w,Height);
end;

procedure TAddToProjectDialog.AddToProjectDialogClose(Sender: TObject;
  var Action: TCloseAction);
begin
  IDEDialogLayoutList.SaveLayout(Self);
end;

procedure TAddToProjectDialog.NewDependButtonClick(Sender: TObject);
var
  NewDependency: TPkgDependency;
begin
  NewDependency:=TPkgDependency.Create;
  try
    // check minimum version
    if DependMinVersionEdit.Text<>'' then begin
      if not NewDependency.MinVersion.ReadString(DependMinVersionEdit.Text) then
      begin
        MessageDlg('Invalid version',
          'The Minimum Version "'+DependMinVersionEdit.Text+'" is invalid.'#13
          +'Please use the format major.minor.release.build'#13
          +'For exmaple: 1.0.20.10',
          mtError,[mbCancel],0);
        exit;
      end;
      NewDependency.Flags:=NewDependency.Flags+[pdfMinVersion];
    end;
    // check maximum version
    if DependMaxVersionEdit.Text<>'' then begin
      if not NewDependency.MaxVersion.ReadString(DependMaxVersionEdit.Text) then
      begin
        MessageDlg('Invalid version',
          'The Maximum Version "'+DependMaxVersionEdit.Text+'" is invalid.'#13
          +'Please use the format major.minor.release.build'#13
          +'For exmaple: 1.0.20.10',
          mtError,[mbCancel],0);
        exit;
      end;
      NewDependency.Flags:=NewDependency.Flags+[pdfMaxVersion];
    end;

    NewDependency.PackageName:=DependPkgNameComboBox.Text;
    if not CheckAddingDependency(TheProject,NewDependency) then exit;

    // ok
    AddResult:=TAddToProjectResult.Create;
    AddResult.Dependency:=NewDependency;
    NewDependency:=nil;
    AddResult.AddType:=a2pRequiredPkg;

    ModalResult:=mrOk;
  finally
    NewDependency.Free;
  end;
end;

procedure TAddToProjectDialog.AddFileButtonClick(Sender: TObject);
var
  i: Integer;
  NewFilename: string;
  NewUnitName: String;
  NewFiles: TList;
  NewFile: TUnitInfo;
  j: Integer;
  OtherFile: TUnitInfo;
  OtherUnitName: String;
  ConflictFile: TUnitInfo;
begin
  try
    NewFiles:=TList.Create;
    for i:=0 to AddFileListBox.Items.Count-1 do begin
      if not AddFileListBox.Selected[i] then continue;
      NewFilename:=AddFileListBox.Items[i];
      // expand filename
      if not FilenameIsAbsolute(NewFilename) then
        NewFilename:=
          TrimFilename(TheProject.ProjectDirectory+PathDelim+NewFilename);
      NewFile:=TheProject.UnitInfoWithFilename(NewFilename);
      if NewFile=nil then continue;
      // check unit name
      if FilenameIsPascalUnit(NewFilename) then begin
        // check unitname is valid pascal identifier
        NewUnitName:=ExtractFileNameOnly(NewFilename);
        if (NewUnitName='') or not (IsValidIdent(NewUnitName)) then begin
          MessageDlg('Invalid pascal unit name',
            'The unit name "'+NewUnitName+'" is not a valid pascal identifier.',
            mtWarning,[mbIgnore,mbCancel],0);
          exit;
        end;
        // check if unitname already exists in project
        ConflictFile:=TheProject.UnitWithUnitname(NewUnitName);
        if ConflictFile<>nil then begin
          MessageDlg('Unit name already exists',
            'The unit name "'+NewUnitName+'" already exists in the project'#13
            +'with file: "'+ConflictFile.Filename+'".',
            mtWarning,[mbCancel],0);
          exit;
        end;
        // check if unitname already exists in selection
        for j:=0 to NewFiles.Count-1 do begin
          OtherFile:=TUnitInfo(NewFiles[j]);
          if FilenameIsPascalUnit(OtherFile.Filename) then begin
            OtherUnitName:=ExtractFileNameOnly(OtherFile.Filename);
            if AnsiCompareText(OtherUnitName,NewUnitName)=0 then begin
              MessageDlg('Unit name already exists',
                'The unit name "'+NewUnitName+'" already exists in the selection'#13
                +'with file: "'+OtherFile.Filename+'".',
                mtWarning,[mbCancel],0);
              exit;
            end;
          end;
        end;
      end;
      NewFiles.Add(NewFile);
    end;
    // everything ok
    AddResult:=TAddToProjectResult.Create;
    AddResult.AddType:=a2pFiles;
    AddResult.Files:=NewFiles;
    NewFiles:=nil;
  finally
    NewFiles.Free;
  end;
  ModalResult:=mrOk;
end;

procedure TAddToProjectDialog.NewDependPageResize(Sender: TObject);
var
  x: Integer;
  y: Integer;
begin
  x:=5;
  y:=5;

  with DependPkgNameLabel do
    SetBounds(x,y+3,110,Height);

  with DependPkgNameComboBox do
    SetBounds(x+DependPkgNameLabel.Width+5,y,150,Height);
  inc(y,DependPkgNameComboBox.Height+5);

  with DependMinVersionLabel do
    SetBounds(x,y+3,170,Height);

  with DependMinVersionEdit do
    SetBounds(x+DependMinVersionLabel.Width+5,y,100,Height);
  inc(y,DependMinVersionEdit.Height+5);

  with DependMaxVersionLabel do
    SetBounds(x,y+3,DependMinVersionLabel.Width,Height);

  with DependMaxVersionEdit do
    SetBounds(x+DependMaxVersionLabel.Width+5,y,
              DependMinVersionEdit.Width,Height);
  inc(y,DependMaxVersionEdit.Height+20);

  with NewDependButton do
    SetBounds(x,y,80,Height);

  with CancelDependButton do
    SetBounds(x+NewDependButton.Width+10,y,80,Height);
end;

procedure TAddToProjectDialog.SetupComponents;
begin
  NoteBook:=TNoteBook.Create(Self);
  with NoteBook do begin
    Name:='NoteBook';
    Parent:=Self;
    Pages.Add('Add File');
    AddFilePage:=Page[0];
    Pages.Add('New Requirement');
    NewDependPage:=Page[1];
    PageIndex:=0;
    Align:=alClient;
  end;

  AddFilePage.OnResize:=@AddFilePageResize;
  NewDependPage.OnResize:=@NewDependPageResize;
  
  AddFileLabel:=TLabel.Create(Self);
  with AddFileLabel do begin
    Name:='AddFileLabel';
    Parent:=AddFilePage;
    Caption:='Add file to project:';
  end;

  AddFileListBox:=TListBox.Create(Self);
  with AddFileListBox do begin
    Name:='AddFileListBox';
    Parent:=AddFilePage;
    MultiSelect:=true;
  end;

  AddFileButton:=TButton.Create(Self);
  with AddFileButton do begin
    Name:='AddFileButton';
    Parent:=AddFilePage;
    Caption:='Ok';
    OnClick:=@AddFileButtonClick;
  end;

  CancelAddFileButton:=TButton.Create(Self);
  with CancelAddFileButton do begin
    Name:='CancelAddFileButton';
    Parent:=AddFilePage;
    Caption:='Cancel';
    ModalResult:=mrCancel;
  end;


  // add required package

  DependPkgNameLabel:=TLabel.Create(Self);
  with DependPkgNameLabel do begin
    Name:='DependPkgNameLabel';
    Parent:=NewDependPage;
    Caption:='Package Name:';
  end;

  DependPkgNameComboBox:=TComboBox.Create(Self);
  with DependPkgNameComboBox do begin
    Name:='DependPkgNameComboBox';
    Parent:=NewDependPage;
    Text:='';
  end;

  DependMinVersionLabel:=TLabel.Create(Self);
  with DependMinVersionLabel do begin
    Name:='DependMinVersionLabel';
    Parent:=NewDependPage;
    Caption:='Minimum Version (optional):';
  end;

  DependMinVersionEdit:=TEdit.Create(Self);
  with DependMinVersionEdit do begin
    Name:='DependMinVersionEdit';
    Parent:=NewDependPage;
    Text:='';
  end;

  DependMaxVersionLabel:=TLabel.Create(Self);
  with DependMaxVersionLabel do begin
    Name:='DependMaxVersionLabel';
    Parent:=NewDependPage;
    Caption:='Maximum Version (optional):';
  end;

  DependMaxVersionEdit:=TEdit.Create(Self);
  with DependMaxVersionEdit do begin
    Name:='DependMaxVersionEdit';
    Parent:=NewDependPage;
    Text:='';
  end;

  NewDependButton:=TButton.Create(Self);
  with NewDependButton do begin
    Name:='NewDependButton';
    Parent:=NewDependPage;
    Caption:='Ok';
    OnClick:=@NewDependButtonClick;
  end;

  CancelDependButton:=TButton.Create(Self);
  with CancelDependButton do begin
    Name:='CancelDependButton';
    Parent:=NewDependPage;
    Caption:='Cancel';
    ModalResult:=mrCancel;
  end;
end;

procedure TAddToProjectDialog.OnIteratePackages(APackageID: TLazPackageID);
begin
  if (fPackages.Find(APackageID)=nil) then
    fPackages.Add(APackageID);
end;

constructor TAddToProjectDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Name:='AddToProjectDialog';
  fPackages:=TAVLTree.Create(@CompareLazPackageID);
  Position:=poScreenCenter;
  IDEDialogLayoutList.ApplyLayout(Self,500,300);
  SetupComponents;
  OnClose:=@AddToProjectDialogClose;
end;

destructor TAddToProjectDialog.Destroy;
begin
  FreeAndNil(fPackages);
  inherited Destroy;
end;

procedure TAddToProjectDialog.UpdateAvailableDependencyNames;
var
  ANode: TAVLTreeNode;
  sl: TStringList;
begin
  fPackages.Clear;
  PackageGraph.IteratePackages(fpfSearchPackageEverywhere,@OnIteratePackages);
  sl:=TStringList.Create;
  ANode:=fPackages.FindLowest;
  while ANode<>nil do begin
    sl.Add(TLazPackageID(ANode.Data).Name);
    ANode:=fPackages.FindSuccessor(ANode);
  end;
  DependPkgNameComboBox.Items.Assign(sl);
  sl.Free;
end;

procedure TAddToProjectDialog.UpdateAvailableFiles;
var
  Index: Integer;
  CurFile: TUnitInfo;
  NewFilename: String;
begin
  AddFileListBox.Items.BeginUpdate;
  if TheProject<>nil then begin
    Index:=0;
    CurFile:=TheProject.FirstUnitWithEditorIndex;
    while CurFile<>nil do begin
      if (not CurFile.IsPartOfProject) and (not CurFile.IsVirtual) then begin
        NewFilename:=
          CreateRelativePath(CurFile.Filename,TheProject.ProjectDirectory);
        if Index<AddFileListBox.Items.Count then
          AddFileListBox.Items[Index]:=NewFilename
        else
          AddFileListBox.Items.Add(NewFilename);
        inc(Index);
      end;
      CurFile:=CurFile.NextUnitWithEditorIndex;
    end;
    while AddFileListBox.Items.Count>Index do
      AddFileListBox.Items.Delete(AddFileListBox.Items.Count-1);
  end else begin
    AddFileListBox.Items.Clear;
  end;
  AddFileListBox.Items.EndUpdate;
end;

{ TAddToProjectResult }

destructor TAddToProjectResult.Destroy;
begin
  Files.Free;
  inherited Destroy;
end;

end.

