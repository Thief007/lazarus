{  $Id$  }
{
 /***************************************************************************
                            addtopackagedlg.pas
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
    TAddToPackageDlg is the form for adding files to an open package.
}
unit AddToPackageDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Buttons, StdCtrls, ExtCtrls,
  Dialogs, LazarusIDEStrConsts, IDEOptionDefs, InputHistory, FileCtrl, AVL_Tree,
  CodeToolManager, IDEDefs, IDEProcs, EnvironmentOpts, PackageSystem,
  PackageDefs, ComponentReg;
  
type
  TAddToPkgType = (
    d2ptUnit,
    d2ptNewComponent,
    d2ptRequiredPkg,
    d2ptFile
    );
    
  TAddToPkgResult = record
    AddType: TAddToPkgType;
    Dependency: TPkgDependency;
    UnitFilename: string;
    UnitName: string;
    AncestorType: string;
    ClassName: string;
    PageName: string;
    FileType: TPkgFileType;
    PkgFileFlags: TPkgFileFlags;
    UsedUnitname: string;
    AutoAddLFMFile: boolean;
    AutoAddLRSFile: boolean;
  end;
  
  TOnGetUnitRegisterInfo = procedure(Sender: TObject; const AFilename: string;
    var TheUnitName: string; var HasRegisterProc: boolean) of object;

  TAddToPackageDlg = class(TForm)
    // notebook
    NoteBook: TNoteBook;
    AddUnitPage: TPage;
    AddFilePage: TPage;
    NewComponentPage: TPage;
    NewDependPage: TPage;
    // add unit page
    AddUnitFilenameLabel: TLabel;
    AddUnitFilenameEdit: TEdit;
    AddUnitFileBrowseButton: TButton;
    AddUnitSrcNameLabel: TLabel;
    AddUnitSrcNameEdit: TEdit;
    AddUnitHasRegisterCheckBox: TCheckBox;
    AddSecondaryFilesCheckBox: TCheckBox;
    AddUnitUpdateButton: TButton;
    AddUnitButton: TButton;
    CancelAddUnitButton: TButton;
    // new component page
    AncestorTypeLabel: TLabel;
    AncestorComboBox: TComboBox;
    AncestorShowAllCheckBox: TCheckBox;
    ClassNameLabel: TLabel;
    ClassNameEdit: TEdit;
    PalettePageLabel: TLabel;
    PalettePageCombobox: TCombobox;
    ComponentUnitFileLabel: TLabel;
    ComponentUnitFileEdit: TEdit;
    ComponentUnitFileButton: TButton;
    ComponentUnitNameLabel: TLabel;
    ComponentUnitNameEdit: TEdit;
    NewComponentButton: TButton;
    CancelNewComponentButton: TButton;
    // new required package
    DependPkgNameLabel: TLabel;
    DependPkgNameComboBox: TComboBox;
    DependMinVersionLabel: TLabel;
    DependMinVersionEdit: TEdit;
    DependMaxVersionLabel: TLabel;
    DependMaxVersionEdit: TEdit;
    NewDependButton: TButton;
    CancelDependButton: TButton;
    // add file page
    AddFilenameLabel: TLabel;
    AddFilenameEdit: TEdit;
    AddFileBrowseButton: TButton;
    AddFileTypeRadioGroup: TRadioGroup;
    AddFileButton: TButton;
    CancelAddFileButton: TButton;
    procedure AddFileBrowseButtonClick(Sender: TObject);
    procedure AddFileButtonClick(Sender: TObject);
    procedure AddFilePageResize(Sender: TObject);
    procedure AddToPackageDlgClose(Sender: TObject; var Action: TCloseAction);
    procedure AddUnitButtonClick(Sender: TObject);
    procedure AddUnitFileBrowseButtonClick(Sender: TObject);
    procedure AddUnitPageResize(Sender: TObject);
    procedure AddUnitUpdateButtonClick(Sender: TObject);
    procedure AncestorComboBoxCloseUp(Sender: TObject);
    procedure AncestorShowAllCheckBoxClick(Sender: TObject);
    procedure CancelAddFileButtonClick(Sender: TObject);
    procedure CancelAddUnitButtonClick(Sender: TObject);
    procedure CancelNewComponentButtonClick(Sender: TObject);
    procedure ClassNameEditChange(Sender: TObject);
    procedure ComponentUnitFileButtonClick(Sender: TObject);
    procedure NewComponentButtonClick(Sender: TObject);
    procedure NewComponentPageResize(Sender: TObject);
    procedure NewDependButtonClick(Sender: TObject);
    procedure NewDependPageResize(Sender: TObject);
  private
    fLastNewComponentAncestorType: string;
    fLastNewComponentClassName: string;
    FLazPackage: TLazPackage;
    FOnGetIDEFileInfo: TGetIDEFileStateEvent;
    FOnGetUnitRegisterInfo: TOnGetUnitRegisterInfo;
    fPkgComponents: TAVLTree;// tree of TPkgComponent
    fPackages: TAVLTree;// tree of  TLazPackage or TPackageLink
    procedure SetLazPackage(const AValue: TLazPackage);
    procedure SetupComponents;
    procedure OnIterateComponentClasses(PkgComponent: TPkgComponent);
    procedure OnIteratePackages(APackageID: TLazPackageID);
    procedure AutoCompleteNewComponent;
    procedure AutoCompleteNewComponentUnitName;
    procedure UpdateAddUnitInfo;
    procedure UpdateAddFileInfo;
  public
    Params: TAddToPkgResult;
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdateAvailableAncestorTypes;
    procedure UpdateAvailablePageNames;
    procedure UpdateAvailableDependencyNames;
  public
    property LazPackage: TLazPackage read FLazPackage write SetLazPackage;
    property OnGetIDEFileInfo: TGetIDEFileStateEvent read FOnGetIDEFileInfo
                                                     write FOnGetIDEFileInfo;
    property OnGetUnitRegisterInfo: TOnGetUnitRegisterInfo
                       read FOnGetUnitRegisterInfo write FOnGetUnitRegisterInfo;
  end;
  
function ShowAddToPackageDlg(Pkg: TLazPackage; var Params: TAddToPkgResult;
  OnGetIDEFileInfo: TGetIDEFileStateEvent;
  OnGetUnitRegisterInfo: TOnGetUnitRegisterInfo): TModalResult;
function CheckAddingUnitFilename(LazPackage: TLazPackage;
  AddFileType: TAddToPkgType; OnGetIDEFileInfo: TGetIDEFileStateEvent;
  var AFilename: string): boolean;
function CheckAddingDependency(LazPackage: TLazPackage;
  NewDependency: TPkgDependency): boolean;


implementation


function ShowAddToPackageDlg(Pkg: TLazPackage; var Params: TAddToPkgResult;
  OnGetIDEFileInfo: TGetIDEFileStateEvent;
  OnGetUnitRegisterInfo: TOnGetUnitRegisterInfo): TModalResult;
var
  AddDlg: TAddToPackageDlg;
begin
  AddDlg:=TAddToPackageDlg.Create(Application);
  AddDlg.LazPackage:=Pkg;
  AddDlg.OnGetIDEFileInfo:=OnGetIDEFileInfo;
  AddDlg.OnGetUnitRegisterInfo:=OnGetUnitRegisterInfo;
  Result:=AddDlg.ShowModal;
  if Result=mrOk then
    Params:=AddDlg.Params;
  AddDlg.Free;
end;

function CheckAddingUnitFilename(LazPackage: TLazPackage;
  AddFileType: TAddToPkgType; OnGetIDEFileInfo: TGetIDEFileStateEvent;
  var AFilename: string): boolean;
var
  AnUnitName: String;
  PkgFile: TPkgFile;
  Msg: String;
  IDEFileFlags: TIDEFileStateFlags;
begin
  Result:=false;

  // normalize filename
  AFilename:=TrimFilename(AFilename);
  if (not FilenameIsAbsolute(AFilename)) then begin
    if LazPackage.HasDirectory then
      AFilename:=LazPackage.Directory+AFilename
    else begin
      MessageDlg('Invalid filename',
        'The filename "'+AFilename+'" is ambigious.'#13
        +'Please specifiy a filename with full path.',
        mtError,[mbCancel],0);
      exit;
    end;
  end;

  // check if file exists
  if not FileExists(AFilename) then begin
    if AddFileType=d2ptUnit then begin
      MessageDlg('File not found',
        'File "'+AFilename+'" not found.',mtError,[mbCancel],0);
      exit;
    end;
  end;

  // check file extension
  if AddFileType in [d2ptUnit,d2ptNewComponent] then begin
    if not FilenameIsPascalUnit(AFilename) then begin
      MessageDlg('File not unit',
        'Pascal units must have the extension .pp or .pas',
        mtWarning,[mbCancel],0);
      exit;
    end;
  end;

  // check unitname
  if AddFileType in [d2ptUnit,d2ptNewComponent] then begin
    AnUnitName:=ExtractFileNameOnly(AFilename);
    if not IsValidIdent(AnUnitName) then begin
      MessageDlg('File not unit',
        +'"'+AnUnitName+'" is not a valid unit name.',
        mtWarning,[mbCancel],0);
      exit;
    end;

    // check if unitname already exists in package
    PkgFile:=PackageGraph.FindUnit(LazPackage,AnUnitName,true,true);
    if PkgFile<>nil then begin
      if PkgFile.LazPackage=LazPackage then begin
        MessageDlg('Unitname already exists',
          'The unitname "'+AnUnitName+'" already exists in this package.',
          mtError,[mbCancel],0);
        exit;
      end else begin
        if MessageDlg('Unitname already exists',
          'The unitname "'+AnUnitName+'" already exists in the package:'#13
          +PkgFile.LazPackage.IDAsString,
          mtWarning,[mbCancel,mbIgnore],0)<>mrIgnore then exit;
      end;
    end;

    // check if unitname is a componentclass
    if IDEComponentPalette.FindComponent(AnUnitName)<>nil then begin
      if MessageDlg('Ambigious Unit Name',
        'The unit name "'+AnUnitName+'" is the same as an registered component.'#13
        +'Using this can cause strange error messages.',
        mtWarning,[mbCancel,mbIgnore],0)<>mrIgnore
      then
        exit;
    end;
  end else begin
    AnUnitName:='';
  end;

  // check if file already exists in package
  PkgFile:=LazPackage.FindPkgFile(AFilename,true,true);
  if PkgFile<>nil then begin
    Msg:='File "'+AFilename+'" already exists in the project.';
    if PkgFile.Filename<>AFilename then
      Msg:=#13+'Existing file: "'+PkgFile.Filename+'"';
    MessageDlg('File already exists',Msg,mtError,[mbCancel],0);
    exit;
  end;

  // check if file is part of project
  if Assigned(OnGetIDEFileInfo) then begin
    IDEFileFlags:=[];
    OnGetIDEFileInfo(nil,AFilename,[ifsPartOfProject{,ifsReadOnly}],
                     IDEFileFlags);
    if (ifsPartOfProject in IDEFileFlags) then begin
      MessageDlg('File is used',
        'The file "'+AFilename+'" is part of the current project.'#13
        +'It is a bad idea to share files between projects and packages.',
        mtError,[mbCancel],0);
      exit;
    end;
    {if (ifsReadOnly in IDEFileFlags) then begin
      MessageDlg('File is readonly',
        'The file "'+AFilename+'" is marked as readonly.',
        mtError,[mbCancel],0);
      exit;
    end;}
  end;

  // ok
  Result:=true;
end;

function CheckAddingDependency(LazPackage: TLazPackage;
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
  if LazPackage.FindDependencyByName(NewPkgName)<>nil then begin
    MessageDlg('Dependency already exists',
      'The package has already a dependency for the package "'+NewPkgName+'".',
      mtError,[mbCancel],0);
    exit;
  end;

  // check if required package exists
  if not PackageGraph.DependencyExists(NewDependency,fpfSearchPackageEverywhere)
  then begin
    MessageDlg('Package not found',
      'No package found for dependency "'+NewDependency.AsString+'".'#13
      +'Please choose an existing package.',
      mtError,[mbCancel],0);
    exit;
  end;
  
  Result:=true;
end;


{ TAddToPackageDlg }

procedure TAddToPackageDlg.AddUnitButtonClick(Sender: TObject);
begin
  FillChar(Params,SizeOf(Params),0);
  Params.AddType:=d2ptUnit;

  Params.UnitFilename:=AddUnitFilenameEdit.Text;
  Params.UnitName:=AddUnitSrcNameEdit.Text;
  Params.FileType:=pftUnit;
  Params.PkgFileFlags:=[];
  Params.AutoAddLFMFile:=AddSecondaryFilesCheckBox.Checked;
  Params.AutoAddLRSFile:=AddSecondaryFilesCheckBox.Checked;
  if AddUnitHasRegisterCheckBox.Checked then
    Include(Params.PkgFileFlags,pffHasRegisterProc);

  // check filename
  if not CheckAddingUnitFilename(LazPackage,Params.AddType,
    OnGetIDEFileInfo,Params.UnitFilename) then exit;

  // check unitname
  if AnsiCompareText(Params.UnitName,ExtractFileNameOnly(Params.UnitFilename))<>0
  then begin
    MessageDlg('Invalid Unit Name',
      'The unit name "'+Params.UnitName+'" and filename differ.',
      mtError,[mbCancel],0);
    exit;
  end;

  // add it ...
  ModalResult:=mrOk;
end;

procedure TAddToPackageDlg.AddToPackageDlgClose(Sender: TObject;
  var Action: TCloseAction);
begin
  IDEDialogLayoutList.SaveLayout(Self);
end;

procedure TAddToPackageDlg.AddFilePageResize(Sender: TObject);
var
  x: Integer;
  y: Integer;
begin
  x:=5;
  y:=5;
  with AddFilenameLabel do
    SetBounds(x,y+2,100,Height);
  inc(x,AddFilenameLabel.Width+5);

  with AddFilenameEdit do
    SetBounds(x,y,Parent.ClientWidth-x-30,Height);
  inc(x,AddFilenameEdit.Width+2);

  with AddFileBrowseButton do
    SetBounds(x,y,AddFilenameEdit.Height,AddFilenameEdit.Height);
  x:=5;
  y:=AddFilenameEdit.Top+AddFilenameEdit.Height+5;

  with AddFileTypeRadioGroup do begin
    SetBounds(x,y,Parent.ClientWidth-2*x,140);
    inc(y,Height+20);
  end;

  with AddFileButton do
    SetBounds(x,y,80,Height);
  inc(x,AddFileButton.Width+10);

  with CancelAddFileButton do
    SetBounds(x,y,80,Height);
end;

procedure TAddToPackageDlg.AddFileBrowseButtonClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  AFilename: string;
begin
  OpenDialog:=TOpenDialog.Create(Application);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Title:=lisOpenFile;
    OpenDialog.Options:=OpenDialog.Options+[ofFileMustExist,ofPathMustExist];
    if OpenDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(OpenDialog.Filename);
      if FileExists(AFilename) then begin
        LazPackage.ShortenFilename(AFilename);
        AddFilenameEdit.Text:=AFilename;
        UpdateAddFileInfo;
      end;
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TAddToPackageDlg.AddFileButtonClick(Sender: TObject);
var
  i: Integer;
  CurPFT: TPkgFileType;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.AddType:=d2ptUnit;
  Params.UnitFilename:=AddFilenameEdit.Text;
  Params.FileType:=pftText;
  Params.UnitName:='';
  Params.PkgFileFlags:=[];
  
  if not FileExists(Params.UnitFilename) then begin
    MessageDlg('File not found',
      'File "'+Params.UnitFilename+'" not found.',
      mtError,[mbCancel],0);
    exit;
  end;
  if LazPackage.FindPkgFile(Params.UnitFilename,true,true)<>nil then begin
    MessageDlg('File already in package',
      'The file "'+Params.UnitFilename+'" is already in the package.',
      mtError,[mbCancel],0);
    exit;
  end;
  
  i:=0;
  for CurPFT:=Low(TPkgFileType) to High(TPkgFileType) do begin
    if CurPFT=pftUnit then continue;
    if i=AddFileTypeRadioGroup.ItemIndex then begin
      Params.FileType:=CurPFT;
    end;
    inc(i);
  end;

  ModalResult:=mrOk;
end;

procedure TAddToPackageDlg.AddUnitFileBrowseButtonClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  AFilename: string;
begin
  OpenDialog:=TOpenDialog.Create(Application);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Title:=lisOpenFile;
    OpenDialog.Options:=OpenDialog.Options+[ofFileMustExist,ofPathMustExist];
    if OpenDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(OpenDialog.Filename);
      if FileExists(AFilename) then begin
        LazPackage.ShortenFilename(AFilename);
        AddUnitFilenameEdit.Text:=AFilename;
        UpdateAddUnitInfo;
      end;
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TAddToPackageDlg.AddUnitPageResize(Sender: TObject);
var
  x: Integer;
  y: Integer;
begin
  x:=5;
  y:=5;
  with AddUnitFilenameLabel do
    SetBounds(x,y+2,100,Height);
  inc(x,AddUnitFilenameLabel.Width+5);

  with AddUnitFilenameEdit do
    SetBounds(x,y,Parent.ClientWidth-x-30,Height);
  inc(x,AddUnitFilenameEdit.Width+2);

  with AddUnitFileBrowseButton do
    SetBounds(x,y,AddUnitFilenameEdit.Height,AddUnitFilenameEdit.Height);
  x:=5;
  y:=AddUnitFilenameEdit.Top+AddUnitFilenameEdit.Height+5;

  with AddUnitSrcNameLabel do
    SetBounds(x,y+2,100,Height);
  inc(x,AddUnitSrcNameLabel.Width+5);

  with AddUnitSrcNameEdit do
    SetBounds(x,y,100,Height);
  inc(y,AddUnitSrcNameEdit.Height+5);
  x:=5;

  with AddUnitHasRegisterCheckBox do
    SetBounds(x,y,Parent.ClientWidth-2*x,Height);
  inc(y,AddUnitHasRegisterCheckBox.Height+5);

  with AddSecondaryFilesCheckBox do
    SetBounds(x,y,Parent.ClientWidth-2*x,Height);
  inc(y,AddSecondaryFilesCheckBox.Height+5);

  with AddUnitUpdateButton do
    SetBounds(x,y,300,Height);
  inc(y,AddUnitUpdateButton.Height+25);

  with AddUnitButton do
    SetBounds(x,y,80,Height);
  inc(x,AddUnitButton.Width+10);

  with CancelAddUnitButton do
    SetBounds(x,y,80,Height);
end;

procedure TAddToPackageDlg.AddUnitUpdateButtonClick(Sender: TObject);
begin
  UpdateAddUnitInfo;
end;

procedure TAddToPackageDlg.AncestorComboBoxCloseUp(Sender: TObject);
begin
  if fLastNewComponentAncestorType<>AncestorComboBox.Text then
    AutoCompleteNewComponent;
end;

procedure TAddToPackageDlg.AncestorShowAllCheckBoxClick(Sender: TObject);
begin
  UpdateAvailableAncestorTypes;
end;

procedure TAddToPackageDlg.CancelAddFileButtonClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TAddToPackageDlg.CancelAddUnitButtonClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TAddToPackageDlg.CancelNewComponentButtonClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TAddToPackageDlg.ClassNameEditChange(Sender: TObject);
begin
  AutoCompleteNewComponentUnitName;
end;

procedure TAddToPackageDlg.ComponentUnitFileButtonClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  AFilename: string;
begin
  OpenDialog:=TOpenDialog.Create(Application);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Title:=lisOpenFile;
    OpenDialog.Options:=OpenDialog.Options+[ofPathMustExist];
    if OpenDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(OpenDialog.Filename);
      if FilenameIsPascalUnit(AFilename) then begin
        LazPackage.ShortenFilename(AFilename);
        ComponentUnitFileEdit.Text:=AFilename;
      end else begin
        MessageDlg('Invalid file',
         'A pascal unit must have the extension .pp or .pas',
         mtError,[mbCancel],0);
      end;
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TAddToPackageDlg.NewComponentButtonClick(Sender: TObject);
var
  PkgFile: TPkgFile;
  PkgComponent: TPkgComponent;
  ARequiredPackage: TLazPackage;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.AddType:=d2ptNewComponent;
  Params.FileType:=pftUnit;
  Params.PkgFileFlags:=[pffHasRegisterProc];
  Params.AncestorType:=AncestorComboBox.Text;
  Params.ClassName:=ClassNameEdit.Text;
  Params.PageName:=PalettePageCombobox.Text;
  Params.UnitName:=ComponentUnitNameEdit.Text;
  Params.UnitFilename:=ComponentUnitFileEdit.Text;
  Params.UsedUnitname:='';

  // check Ancestor Type
  if not IsValidIdent(Params.AncestorType) then begin
    MessageDlg('Invalid Ancestor Type',
      'The ancestor type "'+Params.AncestorType+'"'
      +' is not a valid pascal identifier.',
      mtError,[mbCancel],0);
    exit;
  end;

  // check pagename
  if length(Params.PageName)>100 then begin
    MessageDlg('Page Name too long',
      'The page name "'+Params.PageName+'" is too long (max 100 chars).',
      mtError,[mbCancel],0);
    exit;
  end;

  // check unitname - filename redundancy
  if AnsiCompareText(Params.Unitname,ExtractFileNameOnly(Params.UnitFilename))<>0
  then begin
    MessageDlg('Unit Name Invalid',
      'The unit name "'+Params.UnitName+'" does not correspond to the filename.',
      mtError,[mbCancel],0);
    exit;
  end;

  // check classname
  if not IsValidIdent(Params.ClassName) then begin
    MessageDlg('Invalid Class Name',
      'The class name "'+Params.ClassName+'" is not a valid pascal identifier.',
      mtError,[mbCancel],0);
    exit;
  end;

  // check classname<>ancestortype
  if AnsiCompareText(Params.ClassName,Params.AncestorType)=0 then begin
    MessageDlg('Invalid Circle',
      'The class name "'+Params.ClassName+'" and ancestor type "'
      +Params.AncestorType+'" are the same.',
      mtError,[mbCancel],0);
    exit;
  end;

  // check ancestor type is not unitname
  PkgFile:=PackageGraph.FindUnit(LazPackage,Params.AncestorType,true,true);
  if PkgFile<>nil then begin
    if MessageDlg('Ambigious Ancestor Type',
      'The ancestor type "'+Params.AncestorType+'" has the same name as'#13
      +'the unit "'+PkgFile.Filename+'".',
      mtError,[mbCancel,mbIgnore],0)<>mrIgnore
    then
      exit;
  end;

  // check classname does not interfere with an existing unitname
  PkgFile:=PackageGraph.FindUnit(LazPackage,Params.ClassName,true,true);
  if PkgFile<>nil then begin
    if MessageDlg('Ambigious Class Name',
      'The class name "'+Params.AncestorType+'" has the same name as'#13
      +'the unit "'+PkgFile.Filename+'".',
      mtError,[mbCancel,mbIgnore],0)<>mrIgnore
    then
      exit;
  end;

  // check if classname already exists
  PkgComponent:=
    TPkgComponent(IDEComponentPalette.FindComponent(Params.Classname));
  if PkgComponent<>nil then begin
    if MessageDlg('Class Name already exists',
      'The class name "'+Params.ClassName+'" exists already in'#13
      +'Package '+PkgComponent.PkgFile.LazPackage.IDAsString+#13
      +'File: "'+PkgComponent.PkgFile.Filename+'"',
      mtError,[mbCancel,mbIgnore],0)<>mrIgnore
    then
      exit;
  end;

  // check filename
  if not CheckAddingUnitFilename(LazPackage,Params.AddType,
    OnGetIDEFileInfo,Params.UnitFilename) then exit;

  // create dependency if needed
  PkgComponent:=
    TPkgComponent(IDEComponentPalette.FindComponent(Params.AncestorType));
  if PkgComponent<>nil then begin
    Params.UsedUnitname:=PkgComponent.GetUnitName;
    ARequiredPackage:=PkgComponent.PkgFile.LazPackage;
    if (LazPackage<>ARequiredPackage)
    and (not LazPackage.Requires(PkgComponent.PkgFile.LazPackage))
    then
      Params.Dependency:=ARequiredPackage.CreateDependencyForThisPkg;
  end;

  ModalResult:=mrOk;
end;

procedure TAddToPackageDlg.NewComponentPageResize(Sender: TObject);
var
  x: Integer;
  y: Integer;
begin
  x:=5;
  y:=5;
  
  with AncestorTypeLabel do
    SetBounds(x,y+2,100,Height);
  inc(x,AncestorTypeLabel.Width+5);

  with AncestorComboBox do
    SetBounds(x,y,200,Height);
  inc(x,AncestorComboBox.Width+5);
    
  with AncestorShowAllCheckBox do
    SetBounds(x,y,100,Height);
  x:=5;
  inc(y,AncestorComboBox.Height+5);

  with ClassNameLabel do
    SetBounds(x,y+2,100,Height);
  inc(x,ClassNameLabel.Width+5);

  with ClassNameEdit do
    SetBounds(x,y,200,Height);
  x:=5;
  inc(y,ClassNameEdit.Height+5);

  with PalettePageLabel do
    SetBounds(x,y+2,100,Height);
  inc(x,PalettePageLabel.Width+5);

  with PalettePageCombobox do
    SetBounds(x,y,200,Height);
  x:=5;
  inc(y,PalettePageCombobox.Height+5);

  with ComponentUnitFileLabel do
    SetBounds(x,y+2,100,Height);
  inc(x,ComponentUnitFileLabel.Width+5);

  with ComponentUnitFileEdit do
    SetBounds(x,y,Parent.ClientWidth-x-Height-5,Height);
  inc(x,ComponentUnitFileEdit.Width+2);

  with ComponentUnitFileButton do
    SetBounds(x,y,ComponentUnitFileEdit.Height,ComponentUnitFileEdit.Height);
  x:=5;
  inc(y,ComponentUnitFileEdit.Height+5);

  with ComponentUnitNameLabel do
    SetBounds(x,y+2,100,Height);
  inc(x,ComponentUnitNameLabel.Width+5);

  with ComponentUnitNameEdit do
    SetBounds(x,y,100,Height);
  inc(y,ComponentUnitNameEdit.Height+15);
  x:=5;

  with NewComponentButton do
    SetBounds(x,y,80,Height);
  inc(x,NewComponentButton.Width+10);

  with CancelNewComponentButton do
    SetBounds(x,y,80,Height);
end;

procedure TAddToPackageDlg.NewDependButtonClick(Sender: TObject);
var
  NewDependency: TPkgDependency;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.AddType:=d2ptRequiredPkg;
  
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
    if not CheckAddingDependency(LazPackage,NewDependency) then exit;

    // ok
    Params.Dependency:=NewDependency;
    NewDependency:=nil;

    ModalResult:=mrOk;
  finally
    NewDependency.Free;
  end;
end;

procedure TAddToPackageDlg.NewDependPageResize(Sender: TObject);
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

procedure TAddToPackageDlg.SetLazPackage(const AValue: TLazPackage);
begin
  if FLazPackage=AValue then exit;
  FLazPackage:=AValue;
  UpdateAvailableAncestorTypes;
  UpdateAvailablePageNames;
  UpdateAvailableDependencyNames;
end;

procedure TAddToPackageDlg.SetupComponents;
var
  pft: TPkgFileType;
begin
  NoteBook:=TNoteBook.Create(Self);
  with NoteBook do begin
    Name:='NoteBook';
    Parent:=Self;
    Pages.Add('Add Unit');
    AddUnitPage:=Page[0];
    Pages.Add('New Component');
    NewComponentPage:=Page[1];
    Pages.Add('New Requirement');
    NewDependPage:=Page[2];
    Pages.Add('Add File');
    AddFilePage:=Page[3];
    PageIndex:=0;
    Align:=alClient;
  end;
  
  // add unit
  
  AddUnitPage.OnResize:=@AddUnitPageResize;
  NewComponentPage.OnResize:=@NewComponentPageResize;
  NewDependPage.OnResize:=@NewDependPageResize;
  AddFilePage.OnResize:=@AddFilePageResize;

  AddUnitFilenameLabel:=TLabel.Create(Self);
  with AddUnitFilenameLabel do begin
    Name:='AddUnitFilenameLabel';
    Parent:=AddUnitPage;
    Caption:='Unit file name:';
  end;
  
  AddUnitFilenameEdit:=TEdit.Create(Self);
  with AddUnitFilenameEdit do begin
    Name:='AddUnitFilenameEdit';
    Parent:=AddUnitPage;
    Text:='<choose an existing file>';
  end;

  AddUnitFileBrowseButton:=TButton.Create(Self);
  with AddUnitFileBrowseButton do begin
    Name:='AddUnitFileBrowseButton';
    Parent:=AddUnitPage;
    Caption:='...';
    OnClick:=@AddUnitFileBrowseButtonClick;
  end;

  AddUnitSrcNameLabel:=TLabel.Create(Self);
  with AddUnitSrcNameLabel do begin
    Name:='AddUnitSrcNameLabel';
    Parent:=AddUnitPage;
    Caption:='Unit Name: ';
  end;
  
  AddUnitSrcNameEdit:=TEdit.Create(Self);
  with AddUnitSrcNameEdit do begin
    Name:='AddUnitSrcNameEdit';
    Parent:=AddUnitPage;
    Text:='';
  end;

  AddUnitHasRegisterCheckBox:=TCheckBox.Create(Self);
  with AddUnitHasRegisterCheckBox do begin
    Name:='AddUnitHasRegisterCheckBox';
    Parent:=AddUnitPage;
    Caption:='Has Register procedure';
  end;

  AddSecondaryFilesCheckBox:=TCheckBox.Create(Self);
  with AddSecondaryFilesCheckBox do begin
    Name:='AddSecondaryFilesCheckBox';
    Parent:=AddUnitPage;
    Caption:='Add LFM, LRS files, if they exist';
    Checked:=true;
  end;

  AddUnitUpdateButton:=TButton.Create(Self);
  with AddUnitUpdateButton do begin
    Name:='AddUnitUpdateButton';
    Parent:=AddUnitPage;
    Caption:='Update Unit Name and Has Register procedure';
    OnClick:=@AddUnitUpdateButtonClick;
  end;

  AddUnitButton:=TButton.Create(Self);
  with AddUnitButton do begin
    Name:='AddUnitButton';
    Parent:=AddUnitPage;
    Caption:='Ok';
    OnClick:=@AddUnitButtonClick;
  end;

  CancelAddUnitButton:=TButton.Create(Self);
  with CancelAddUnitButton do begin
    Name:='CancelAddUnitButton';
    Parent:=AddUnitPage;
    Caption:='Cancel';
    OnClick:=@CancelAddUnitButtonClick;
  end;
  

  // add new component unit

  AncestorTypeLabel:=TLabel.Create(Self);
  with AncestorTypeLabel do begin
    Name:='AncestorTypeLabel';
    Parent:=NewComponentPage;
    Caption:='Ancestor Type';
  end;

  AncestorComboBox:=TComboBox.Create(Self);
  with AncestorComboBox do begin
    Name:='AncestorComboBox';
    Parent:=NewComponentPage;
    Text:='';
    OnCloseUp:=@AncestorComboBoxCloseUp;
  end;

  AncestorShowAllCheckBox:=TCheckBox.Create(Self);
  with AncestorShowAllCheckBox do begin
    Name:='AncestorShowAllCheckBox';
    Parent:=NewComponentPage;
    Text:='Show all';
    Checked:=true;
    OnClick:=@AncestorShowAllCheckBoxClick;
  end;

  ClassNameLabel:=TLabel.Create(Self);
  with ClassNameLabel do begin
    Name:='ClassNameLabel';
    Parent:=NewComponentPage;
    Caption:='New class name:';
  end;

  ClassNameEdit:=TEdit.Create(Self);
  with ClassNameEdit do begin
    Name:='ClassNameEdit';
    Parent:=NewComponentPage;
    Text:='';
    OnChange:=@ClassNameEditChange;
  end;

  PalettePageLabel:=TLabel.Create(Self);
  with PalettePageLabel do begin
    Name:='PalettePageLabel';
    Parent:=NewComponentPage;
    Caption:='Palette Page:';
  end;

  PalettePageCombobox:=TCombobox.Create(Self);
  with PalettePageCombobox do begin
    Name:='PalettePageCombobox';
    Parent:=NewComponentPage;
    Text:='';
  end;

  ComponentUnitFileLabel:=TLabel.Create(Self);
  with ComponentUnitFileLabel do begin
    Name:='ComponentUnitFileLabel';
    Parent:=NewComponentPage;
    Caption:='Unit File Name:';
  end;

  ComponentUnitFileEdit:=TEdit.Create(Self);
  with ComponentUnitFileEdit do begin
    Name:='ComponentUnitFileEdit';
    Parent:=NewComponentPage;
    Text:='';
  end;

  ComponentUnitFileButton:=TButton.Create(Self);
  with ComponentUnitFileButton do begin
    Name:='ComponentUnitFileButton';
    Parent:=NewComponentPage;
    Caption:='...';
    OnClick:=@ComponentUnitFileButtonClick;
  end;

  ComponentUnitNameLabel:=TLabel.Create(Self);
  with ComponentUnitNameLabel do begin
    Name:='ComponentUnitNameLabel';
    Parent:=NewComponentPage;
    Caption:='Unit Name:';
  end;

  ComponentUnitNameEdit:=TEdit.Create(Self);
  with ComponentUnitNameEdit do begin
    Name:='ComponentUnitNameEdit';
    Parent:=NewComponentPage;
    Text:='';
  end;

  NewComponentButton:=TButton.Create(Self);
  with NewComponentButton do begin
    Name:='NewComponentButton';
    Parent:=NewComponentPage;
    Caption:='Ok';
    OnClick:=@NewComponentButtonClick;
  end;

  CancelNewComponentButton:=TButton.Create(Self);
  with CancelNewComponentButton do begin
    Name:='CancelNewComponentButton';
    Parent:=NewComponentPage;
    Caption:='Cancel';
    OnClick:=@CancelNewComponentButtonClick;
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


  // add file
  AddFilenameLabel:=TLabel.Create(Self);
  with AddFilenameLabel do begin
    Name:='AddFilenameLabel';
    Parent:=AddFilePage;
    Caption:='File name:';
  end;

  AddFilenameEdit:=TEdit.Create(Self);
  with AddFilenameEdit do begin
    Name:='AddFilenameEdit';
    Parent:=AddFilePage;
    Text:='<choose an existing file>';
  end;

  AddFileBrowseButton:=TButton.Create(Self);
  with AddFileBrowseButton do begin
    Name:='AddFileBrowseButton';
    Parent:=AddFilePage;
    Caption:='...';
    OnClick:=@AddFileBrowseButtonClick;
  end;

  AddFileTypeRadioGroup:=TRadioGroup.Create(Self);
  with AddFileTypeRadioGroup do begin
    Name:='AddFileTypeRadioGroup';
    Parent:=AddFilePage;
    Caption:='File Type';
    with Items do begin
      BeginUpdate;
      for pft:=Low(TPkgFileType) to High(TPkgFileType) do begin
        if pft=pftUnit then continue;
        Add(GetPkgFileTypeLocalizedName(pft));
      end;
      EndUpdate;
    end;
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
    OnClick:=@CancelAddFileButtonClick;
  end;
end;

procedure TAddToPackageDlg.OnIterateComponentClasses(PkgComponent: TPkgComponent
  );
begin
  if fPkgComponents.Find(PkgComponent)=nil then
    fPkgComponents.Add(PkgComponent);
end;

procedure TAddToPackageDlg.OnIteratePackages(APackageID: TLazPackageID);
begin
  if (APackageID<>LazPackage) and (fPackages.Find(APackageID)=nil) then
    fPackages.Add(APackageID);
end;

procedure TAddToPackageDlg.AutoCompleteNewComponent;
var
  PkgComponent: TPkgComponent;
begin
  fLastNewComponentAncestorType:=AncestorComboBox.Text;
  if not IsValidIdent(fLastNewComponentAncestorType) then exit;
  PkgComponent:=TPkgComponent(
    IDEComponentPalette.FindComponent(fLastNewComponentAncestorType));
  if PkgComponent=nil then exit;
  
  // create unique classname
  ClassNameEdit.Text:=IDEComponentPalette.CreateNewClassName(
                                                 fLastNewComponentAncestorType);
  // choose the same page name
  PalettePageCombobox.Text:=PkgComponent.Page.PageName;
  // filename
  AutoCompleteNewComponentUnitName;
end;

procedure TAddToPackageDlg.AutoCompleteNewComponentUnitName;
var
  CurClassName: String;
  NewUnitName: String;
  NewFileName: String;
begin
  // check if update needed
  CurClassName:=ClassNameEdit.Text;
  if fLastNewComponentClassName=CurClassName then exit;
  fLastNewComponentClassName:=CurClassName;

  // check classname
  if not IsValidIdent(CurClassName) then exit;

  // create unitname
  NewUnitName:=CurClassName;
  if NewUnitName[1]='T' then
    NewUnitName:=copy(NewUnitName,2,length(NewUnitName)-1);
  NewUnitName:=PackageGraph.CreateUniqueUnitName(NewUnitName);
  ComponentUnitNameEdit.Text:=NewUnitName;

  // create filename
  NewFileName:=NewUnitName;
  if EnvironmentOptions.PascalFileAutoLowerCase
  or EnvironmentOptions.PascalFileAskLowerCase then
    NewFileName:=lowercase(NewFileName);
  // append pascal file extension
  NewFileName:=NewFileName+
       +EnvironmentOpts.PascalExtension[EnvironmentOptions.PascalFileExtension];
  // prepend path
  if LazPackage.HasDirectory then
    NewFileName:=LazPackage.Directory+NewFileName;
  ComponentUnitFileEdit.Text:=NewFileName;
end;

procedure TAddToPackageDlg.UpdateAddUnitInfo;
var
  AnUnitName: string;
  HasRegisterProc: boolean;
begin
  if Assigned(OnGetUnitRegisterInfo) then begin
    OnGetUnitRegisterInfo(Self,AddUnitFilenameEdit.Text,
                          AnUnitName,HasRegisterProc);
    AddUnitSrcNameEdit.Text:=AnUnitName;
    AddUnitHasRegisterCheckBox.Checked:=HasRegisterProc;
  end;
end;

procedure TAddToPackageDlg.UpdateAddFileInfo;
var
  CurFilename: String;
  NewPFT: TPkgFileType;
  CurPFT: TPkgFileType;
  i: Integer;
begin
  CurFilename:=AddFilenameEdit.Text;
  if CompareFileExt(CurFilename,'.lfm',true)=0 then
    NewPFT:=pftLFM
  else if CompareFileExt(CurFilename,'.lrs',true)=0 then
    NewPFT:=pftLRS
  else if CompareFileExt(CurFilename,'.inc',true)=0 then
    NewPFT:=pftInclude
  else if FileIsText(CurFilename) then
    NewPFT:=pftText
  else
    NewPFT:=pftBinary;
  i:=0;
  for CurPFT:=Low(TPkgFileType) to High(TPkgFileType) do begin
    if CurPFT=pftUnit then continue;
    if CurPFT=NewPFT then break;
    inc(i);
  end;
  AddFileTypeRadioGroup.ItemIndex:=i;
end;

constructor TAddToPackageDlg.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Name:='AddToPackageDlg';
  fPkgComponents:=TAVLTree.Create(@CompareIDEComponentByClassName);
  fPackages:=TAVLTree.Create(@CompareLazPackageID);
  Position:=poScreenCenter;
  IDEDialogLayoutList.ApplyLayout(Self,500,300);
  SetupComponents;
  OnClose:=@AddToPackageDlgClose;
end;

destructor TAddToPackageDlg.Destroy;
begin
  FreeAndNil(fPkgComponents);
  FreeAndNil(fPackages);
  inherited Destroy;
end;

procedure TAddToPackageDlg.UpdateAvailableAncestorTypes;
var
  ANode: TAVLTreeNode;
  sl: TStringList;
  OldAncestorType: String;
begin
  // get all available registered components
  fPkgComponents.Clear;
  if AncestorShowAllCheckBox.Checked then begin
    PackageGraph.IterateAllComponentClasses(@OnIterateComponentClasses);
  end else begin
    PackageGraph.IterateComponentClasses(LazPackage,@OnIterateComponentClasses,
                                         true,true);
  end;
  // put them into the combobox
  sl:=TStringList.Create;
  ANode:=fPkgComponents.FindLowest;
  while ANode<>nil do begin
    sl.Add(TPkgComponent(ANode.Data).ComponentClass.ClassName);
    ANode:=fPkgComponents.FindSuccessor(ANode);
  end;
  OldAncestorType:=AncestorComboBox.Text;
  AncestorComboBox.Items.Assign(sl);
  AncestorComboBox.Text:=OldAncestorType;
  sl.Free;
end;

procedure TAddToPackageDlg.UpdateAvailablePageNames;
var
  i: Integer;
  APageName: String;
  sl: TStringList;
begin
  // get all current pagenames (excluding the hidden page)
  sl:=TStringList.Create;
  for i:=0 to IDEComponentPalette.Count-1 do begin
    APageName:=IDEComponentPalette[i].PageName;
    if APageName<>'' then
      sl.Add(APageName);
  end;
  sl.Sort;
  PalettePageCombobox.Items.Assign(sl);
  sl.Free;
end;

procedure TAddToPackageDlg.UpdateAvailableDependencyNames;
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

end.

