{  $Id$  }
{
 /***************************************************************************
                            pkgoptionsdlg.pas
                            -----------------


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
    TPackageOptionsDialog is the form for the general options of a package.
}
unit PkgOptionsDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Buttons, LResources, ExtCtrls, StdCtrls,
  Spin, Dialogs, PathEditorDlg, IDEProcs, IDEOptionDefs,
  PackageDefs, PackageSystem;
  
type
  TPackageOptionsDialog = class(TForm)
    Notebook: TNotebook;
    // Description page
    DescriptionPage: TPage;
    DescriptionGroupBox: TGroupBox;
    DescriptionMemo: TMemo;
    AuthorGroupBox: TGroupBox;
    AuthorEdit: TEdit;
    VersionGroupBox: TGroupBox;
    VersionMajorLabel: TLabel;
    VersionMajorSpinEdit: TSpinEdit;
    VersionMinorLabel: TLabel;
    VersionMinorSpinEdit: TSpinEdit;
    VersionReleaseLabel: TLabel;
    VersionReleaseSpinEdit: TSpinEdit;
    VersionBuildLabel: TLabel;
    VersionBuildSpinEdit: TSpinEdit;
    AutoIncrementOnBuildCheckBox: TCheckBox;
    // Usage page
    UsagePage: TPage;
    PkgTypeRadioGroup: TRadioGroup;
    UpdateRadioGroup: TRadioGroup;
    AddPathsGroupBox: TGroupBox;
    UnitPathLabel: TLabel;
    UnitPathEdit: TEdit;
    UnitPathButton: TPathEditorButton;
    IncludePathLabel: TLabel;
    IncludePathEdit: TEdit;
    IncludePathButton: TPathEditorButton;
    ObjectPathLabel: TLabel;
    ObjectPathEdit: TEdit;
    ObjectPathButton: TPathEditorButton;
    LibraryPathLabel: TLabel;
    LibraryPathEdit: TEdit;
    LibraryPathButton: TPathEditorButton;
    AddOptionsGroupBox: TGroupBox;
    LinkerOptionsLabel: TLabel;
    LinkerOptionsMemo: TMemo;
    CustomOptionsLabel: TLabel;
    CustomOptionsMemo: TMemo;
    // buttons
    OkButton: TButton;
    CancelButton: TButton;
    procedure AddOptionsGroupBoxResize(Sender: TObject);
    procedure AddPathsGroupBoxResize(Sender: TObject);
    procedure DescriptionPageResize(Sender: TObject);
    procedure PackageOptionsDialogResize(Sender: TObject);
    procedure PathEditBtnClick(Sender: TObject);
    procedure PathEditBtnExecuted(Sender: TObject);
    procedure PkgTypeRadioGroupClick(Sender: TObject);
    procedure UsagePageResize(Sender: TObject);
    procedure VersionGroupBoxResize(Sender: TObject);
  private
    FLazPackage: TLazPackage;
    procedure SetLazPackage(const AValue: TLazPackage);
    procedure SetupComponents;
    procedure SetupDescriptionPage(PageIndex: integer);
    procedure SetupUsagePage(PageIndex: integer);
    procedure ReadOptionsFromPackage;
    procedure ReadPkgTypeFromPackage;
    function GetEditForPathButton(AButton: TPathEditorButton): TEdit;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  public
    property LazPackage: TLazPackage read FLazPackage write SetLazPackage;
  end;
  
function ShowPackageOptionsDlg(APackage: TLazPackage): TModalResult;


implementation


uses Math;

function ShowPackageOptionsDlg(APackage: TLazPackage): TModalResult;
var
  PkgOptsDlg: TPackageOptionsDialog;
begin
  PkgOptsDlg:=TPackageOptionsDialog.Create(Application);
  PkgOptsDlg.LazPackage:=APackage;
  Result:=PkgOptsDlg.ShowModal;
  PkgOptsDlg.Free;
end;

{ TPackageOptionsDialog }

procedure TPackageOptionsDialog.PackageOptionsDialogResize(Sender: TObject);
begin
  with Notebook do
    SetBounds(0,0,Parent.ClientWidth,Parent.ClientHeight-40);
    
  with OkButton do
    SetBounds(Parent.ClientWidth-200,Parent.ClientHeight-30,80,Height);
    
  with CancelButton do
    SetBounds(OkButton.Left+OkButton.Width+20,OkButton.Top,
              OkButton.Width,OkButton.Height);
end;

procedure TPackageOptionsDialog.PathEditBtnClick(Sender: TObject);
var
  AButton: TPathEditorButton;
  OldPath: String;
  AnEdit: TEdit;
  Templates: String;
begin
  if not (Sender is TPathEditorButton) then exit;
  AButton:=TPathEditorButton(Sender);
  AnEdit:=GetEditForPathButton(AButton);
  OldPath:=AnEdit.Text;
  if AButton=UnitPathButton then begin
    Templates:=
          '$(LazarusDir)/lcl/units'
        +';$(LazarusDir)/lcl/units/$(LCLWidgetType)'
        +';$(LazarusDir)/components/units'
        +';$(LazarusDir)/components/custom';
  end;
  if AButton=IncludePathButton then begin
    Templates:='include';
  end else
  if AButton=ObjectPathButton then begin
    Templates:='objects';
  end else
  if AButton=LibraryPathButton then begin
    Templates:='';
  end;
  AButton.CurrentPathEditor.Path:=OldPath;
  AButton.CurrentPathEditor.Templates:=SetDirSeparators(Templates);
end;

procedure TPackageOptionsDialog.PathEditBtnExecuted(Sender: TObject);
var
  AButton: TPathEditorButton;
  NewPath: String;
  AnEdit: TEdit;
begin
  if not (Sender is TPathEditorButton) then exit;
  AButton:=TPathEditorButton(Sender);
  if AButton.CurrentPathEditor.ModalResult<>mrOk then exit;
  NewPath:=AButton.CurrentPathEditor.Path;
  AnEdit:=GetEditForPathButton(AButton);
  AnEdit.Text:=NewPath;
end;

procedure TPackageOptionsDialog.PkgTypeRadioGroupClick(Sender: TObject);
begin
  if LazPackage=nil then exit;
  if (PkgTypeRadioGroup.ItemIndex=1) and (LazPackage.PackageType<>lptRunTime)
  then begin
    // user sets to runtime only
    if (LazPackage.AutoInstall<>pitNope) then begin
      MessageDlg('Invalid package type',
        'The package "'+LazPackage.IDAsString+'" has the auto install flag.'#13
        +'This means it will be installed in the IDE. Installation packages'#13
        +'must be designtime Packages.',
        mtError,[mbCancel],0);
      ReadPkgTypeFromPackage;
    end;
  end;
end;

procedure TPackageOptionsDialog.UsagePageResize(Sender: TObject);
var
  x: Integer;
  y: Integer;
  w: Integer;
  h: Integer;
begin
  x:=3;
  y:=3;
  w:=(UsagePage.ClientWidth-3*x) div 2;
  h:=75;
  with PkgTypeRadioGroup do
    SetBounds(x,y,w,h);

  with UpdateRadioGroup do
    SetBounds(x+w+x,y,w,h);
    
  inc(y,h+5);
  w:=UsagePage.ClientWidth-2*x;
  h:=130;
  with AddPathsGroupBox do
    SetBounds(x,y,w,h);
  inc(y,h+3);

  h:=Max(70,UsagePage.ClientHeight-y);
  with AddOptionsGroupBox do
    SetBounds(x,y,w,h);
end;

procedure TPackageOptionsDialog.VersionGroupBoxResize(Sender: TObject);
var
  x: Integer;
  y: Integer;
  w: Integer;
begin
  x:=2;
  y:=22;
  w:=VersionGroupBox.ClientWidth div 4;

  with VersionMajorLabel do
    SetBounds(x,3,w,Height);
  with VersionMajorSpinEdit do
    SetBounds(x,y,Max(10,w-5),Height);
  inc(x,w);
    
  with VersionMinorLabel do
    SetBounds(x,3,w,Height);
  with VersionMinorSpinEdit do
    SetBounds(x,y,Max(10,w-5),Height);
  inc(x,w);

  with VersionReleaseLabel do
    SetBounds(x,3,w,Height);
  with VersionReleaseSpinEdit do
    SetBounds(x,y,Max(10,w-5),Height);
  inc(x,w);

  with VersionBuildLabel do
    SetBounds(x,3,w,Height);
  with VersionBuildSpinEdit do
    SetBounds(x,y,Max(10,w-5),Height);

  inc(y,VersionMinorSpinEdit.Height+5);
  with AutoIncrementOnBuildCheckBox do
    SetBounds(0,y,Parent.ClientWidth,Height);
end;

procedure TPackageOptionsDialog.DescriptionPageResize(Sender: TObject);
var
  x: Integer;
  y: Integer;
  w: Integer;
begin
  x:=3;
  y:=3;
  w:=DescriptionPage.ClientWidth-2*x;
  with DescriptionGroupBox do begin
    SetBounds(x,y,w,80);
    inc(y,Height+5);
  end;

  with AuthorGroupBox do begin
    SetBounds(x,y+3,w,50);
    inc(y,Height+5);
  end;
    
  with VersionGroupBox do
    SetBounds(x,y,w,90);
end;

procedure TPackageOptionsDialog.AddPathsGroupBoxResize(Sender: TObject);
var
  LabelLeft: Integer;
  LabelWidth: Integer;
  ButtonWidth: Integer;
  EditLeft: Integer;
  EditWidth: Integer;
  ButtonLeft: Integer;
  EditHeight: Integer;
  y: Integer;
begin
  LabelLeft:=3;
  LabelWidth:=70;
  ButtonWidth:=25;
  EditLeft:=LabelWidth+LabelLeft;
  EditWidth:=AddPathsGroupBox.ClientWidth-2*LabelLeft-LabelWidth-ButtonWidth;
  ButtonLeft:=EditLeft+EditWidth;
  EditHeight:=UnitPathEdit.Height;
  y:=0;
  
  UnitPathLabel.SetBounds(LabelLeft,y+3,LabelWidth,Height);
  UnitPathEdit.SetBounds(EditLeft,y,EditWidth,EditHeight);
  UnitPathButton.SetBounds(ButtonLeft,y,ButtonWidth,EditHeight);
  inc(y,EditHeight+3);
  
  IncludePathLabel.SetBounds(LabelLeft,y+3,LabelWidth,Height);
  IncludePathEdit.SetBounds(EditLeft,y,EditWidth,EditHeight);
  IncludePathButton.SetBounds(ButtonLeft,y,ButtonWidth,EditHeight);
  inc(y,EditHeight+3);

  ObjectPathLabel.SetBounds(LabelLeft,y+3,LabelWidth,Height);
  ObjectPathEdit.SetBounds(EditLeft,y,EditWidth,EditHeight);
  ObjectPathButton.SetBounds(ButtonLeft,y,ButtonWidth,EditHeight);
  inc(y,EditHeight+3);

  LibraryPathLabel.SetBounds(LabelLeft,y+3,LabelWidth,Height);
  LibraryPathEdit.SetBounds(EditLeft,y,EditWidth,EditHeight);
  LibraryPathButton.SetBounds(ButtonLeft,y,ButtonWidth,EditHeight);
end;

procedure TPackageOptionsDialog.AddOptionsGroupBoxResize(Sender: TObject);
var
  LabelLeft: Integer;
  LabelWidth: Integer;
  MemoLeft: Integer;
  MemoWidth: Integer;
  MemoHeight: Integer;
  y: Integer;
begin
  y:=3;
  LabelLeft:=3;
  LabelWidth:=70;
  MemoLeft:=LabelLeft+LabelWidth;
  MemoWidth:=AddOptionsGroupBox.ClientWidth-LabelLeft-MemoLeft;
  MemoHeight:=(AddOptionsGroupBox.ClientHeight-3*y) div 2;
  
  LinkerOptionsLabel.SetBounds(LabelLeft,y+3,LabelWidth,Height);
  LinkerOptionsMemo.SetBounds(MemoLeft,y,MemoWidth,MemoHeight);
  inc(y,y+MemoHeight);
  CustomOptionsLabel.SetBounds(LabelLeft,y+3,LabelWidth,Height);
  CustomOptionsMemo.SetBounds(MemoLeft,y,MemoWidth,MemoHeight);
end;

procedure TPackageOptionsDialog.SetLazPackage(const AValue: TLazPackage);
begin
  if FLazPackage=AValue then exit;
  FLazPackage:=AValue;
  ReadOptionsFromPackage;
end;

procedure TPackageOptionsDialog.SetupComponents;
begin
  Notebook:=TNotebook.Create(Self);
  with Notebook do begin
    Name:='Notebook';
    Parent:=Self;
    Pages.Add('Description');
    Pages.Add('Usage');
    PageIndex:=0;
  end;
  
  SetupDescriptionPage(0);
  SetupUsagePage(1);

  OkButton:=TButton.Create(Self);
  with OkButton do begin
    Name:='OkButton';
    Caption:='Ok';
    Parent:=Self;
  end;
  
  CancelButton:=TButton.Create(Self);
  with CancelButton do begin
    Name:='CancelButton';
    Parent:=Self;
    Caption:='Cancel';
    ModalResult:=mrCancel;
  end;
end;

procedure TPackageOptionsDialog.SetupDescriptionPage(PageIndex: integer);
begin
  // Description page
  DescriptionPage:=Notebook.Page[PageIndex];
  DescriptionPage.OnResize:=@DescriptionPageResize;

  DescriptionGroupBox:=TGroupBox.Create(Self);
  with DescriptionGroupBox do begin
    Name:='DescriptionGroupBox';
    Parent:=DescriptionPage;
    Caption:='Description/Abstract';
  end;
  
  DescriptionMemo:=TMemo.Create(Self);
  with DescriptionMemo do begin
    Name:='DescriptionMemo';
    Parent:=DescriptionGroupBox;
    Align:=alClient;
  end;

  AuthorGroupBox:=TGroupBox.Create(Self);
  with AuthorGroupBox do begin
    Name:='AuthorGroupBox';
    Parent:=DescriptionPage;
    Caption:='Author:';
  end;

  AuthorEdit:=TEdit.Create(Self);
  with AuthorEdit do begin
    Name:='AuthorEdit';
    Parent:=AuthorGroupBox;
    Align:=alTop;
    Text:='';
  end;

  VersionGroupBox:=TGroupBox.Create(Self);
  with VersionGroupBox do begin
    Name:='VersionGroupBox';
    Parent:=DescriptionPage;
    Caption:='Version';
    OnResize:=@VersionGroupBoxResize;
  end;

  VersionMajorLabel:=TLabel.Create(Self);
  with VersionMajorLabel do begin
    Name:='VersionMajorLabel';
    Parent:=VersionGroupBox;
    Caption:='Major';
  end;

  VersionMajorSpinEdit:=TSpinEdit.Create(Self);
  with VersionMajorSpinEdit do begin
    Name:='VersionMajorSpinEdit';
    Parent:=VersionGroupBox;
    Decimal_Places:=0;
    MinValue:=0;
    MaxValue:=9999;
  end;

  VersionMinorLabel:=TLabel.Create(Self);
  with VersionMinorLabel do begin
    Name:='VersionMinorLabel';
    Parent:=VersionGroupBox;
    Caption:='Minor';
  end;

  VersionMinorSpinEdit:=TSpinEdit.Create(Self);
  with VersionMinorSpinEdit do begin
    Name:='VersionMinorSpinEdit';
    Parent:=VersionGroupBox;
    Decimal_Places:=0;
    MinValue:=0;
    MaxValue:=9999;
  end;

  VersionReleaseLabel:=TLabel.Create(Self);
  with VersionReleaseLabel do begin
    Name:='VersionReleaseLabel';
    Parent:=VersionGroupBox;
    Caption:='Release';
  end;

  VersionReleaseSpinEdit:=TSpinEdit.Create(Self);
  with VersionReleaseSpinEdit do begin
    Name:='VersionReleaseSpinEdit';
    Parent:=VersionGroupBox;
    Decimal_Places:=0;
    MinValue:=0;
    MaxValue:=9999;
  end;

  VersionBuildLabel:=TLabel.Create(Self);
  with VersionBuildLabel do begin
    Name:='VersionBuildLabel';
    Parent:=VersionGroupBox;
    Caption:='Build';
  end;

  VersionBuildSpinEdit:=TSpinEdit.Create(Self);
  with VersionBuildSpinEdit do begin
    Name:='VersionBuildSpinEdit';
    Parent:=VersionGroupBox;
    Caption:='Build';
    Decimal_Places:=0;
    MinValue:=0;
    MaxValue:=9999;
  end;

  AutoIncrementOnBuildCheckBox:=TCheckBox.Create(Self);
  with AutoIncrementOnBuildCheckBox do begin
    Name:='AutoIncrementOnBuildCheckBox';
    Parent:=VersionGroupBox;
    Caption:='Automatically increment version on build';
  end;
end;

procedure TPackageOptionsDialog.SetupUsagePage(PageIndex: integer);
begin
  // Usage page
  UsagePage:=Notebook.Page[PageIndex];
  UsagePage.OnResize:=@UsagePageResize;
  
  PkgTypeRadioGroup:=TRadioGroup.Create(Self);
  with PkgTypeRadioGroup do begin
    Name:='UsageRadioGroup';
    Parent:=UsagePage;
    Caption:='PackageType';
    with Items do begin
      BeginUpdate;
      Add('Designtime only');
      Add('Runtime only');
      Add('Designtime and Runtime');
      EndUpdate;
    end;
    ItemIndex:=2;
    OnClick:=@PkgTypeRadioGroupClick;
  end;

  UpdateRadioGroup:=TRadioGroup.Create(Self);
  with UpdateRadioGroup do begin
    Name:='UpdateRadioGroup';
    Parent:=UsagePage;
    Caption:='Update/Rebuild';
    with Items do begin
      BeginUpdate;
      Add('Automatically re-compile');
      Add('Manual compilation');
      EndUpdate;
    end;
    ItemIndex:=0;
  end;

  AddPathsGroupBox:=TGroupBox.Create(Self);
  with AddPathsGroupBox do begin
    Name:='AddPathsGroupBox';
    Parent:=UsagePage;
    Caption:='Add paths to dependent packages/projects';
    OnResize:=@AddPathsGroupBoxResize;
  end;

  UnitPathLabel:=TLabel.Create(Self);
  with UnitPathLabel do begin
    Name:='UnitPathLabel';
    Parent:=AddPathsGroupBox;
    Caption:='Unit';
  end;

  UnitPathEdit:=TEdit.Create(Self);
  with UnitPathEdit do begin
    Name:='UnitPathEdit';
    Parent:=AddPathsGroupBox;
    Text:='';
  end;

  UnitPathButton:=TPathEditorButton.Create(Self);
  with UnitPathButton do begin
    Name:='UnitPathButton';
    Parent:=AddPathsGroupBox;
    Caption:='...';
    OnClick:=@PathEditBtnClick;
    OnExecuted:=@PathEditBtnExecuted;
  end;

  IncludePathLabel:=TLabel.Create(Self);
  with IncludePathLabel do begin
    Name:='IncludePathLabel';
    Parent:=AddPathsGroupBox;
    Caption:='Include';
  end;

  IncludePathEdit:=TEdit.Create(Self);
  with IncludePathEdit do begin
    Name:='IncludePathEdit';
    Parent:=AddPathsGroupBox;
    Text:='';
  end;

  IncludePathButton:=TPathEditorButton.Create(Self);
  with IncludePathButton do begin
    Name:='IncludePathButton';
    Parent:=AddPathsGroupBox;
    Caption:='...';
    OnClick:=@PathEditBtnClick;
    OnExecuted:=@PathEditBtnExecuted;
  end;

  ObjectPathLabel:=TLabel.Create(Self);
  with ObjectPathLabel do begin
    Name:='ObjectPathLabel';
    Parent:=AddPathsGroupBox;
    Caption:='Object';
  end;

  ObjectPathEdit:=TEdit.Create(Self);
  with ObjectPathEdit do begin
    Name:='ObjectPathEdit';
    Parent:=AddPathsGroupBox;
    Text:='';
  end;

  ObjectPathButton:=TPathEditorButton.Create(Self);
  with ObjectPathButton do begin
    Name:='ObjectPathButton';
    Parent:=AddPathsGroupBox;
    Caption:='...';
    OnClick:=@PathEditBtnClick;
    OnExecuted:=@PathEditBtnExecuted;
  end;

  LibraryPathLabel:=TLabel.Create(Self);
  with LibraryPathLabel do begin
    Name:='LibraryPathLabel';
    Parent:=AddPathsGroupBox;
    Caption:='Library';
  end;

  LibraryPathEdit:=TEdit.Create(Self);
  with LibraryPathEdit do begin
    Name:='LibraryPathEdit';
    Parent:=AddPathsGroupBox;
    Text:='';
  end;

  LibraryPathButton:=TPathEditorButton.Create(Self);
  with LibraryPathButton do begin
    Name:='LibraryPathButton';
    Parent:=AddPathsGroupBox;
    Caption:='...';
    OnClick:=@PathEditBtnClick;
    OnExecuted:=@PathEditBtnExecuted;
  end;

  AddOptionsGroupBox:=TGroupBox.Create(Self);
  with AddOptionsGroupBox do begin
    Name:='AddOptionsGroupBox';
    Parent:=UsagePage;
    Caption:='Add options to dependent packages and projects';
    OnResize:=@AddOptionsGroupBoxResize;
  end;

  LinkerOptionsLabel:=TLabel.Create(Self);
  with LinkerOptionsLabel do begin
    Name:='LinkerOptionsLabel';
    Parent:=AddOptionsGroupBox;
    Caption:='Linker';
  end;

  LinkerOptionsMemo:=TMemo.Create(Self);
  with LinkerOptionsMemo do begin
    Name:='LinkerOptionsMemo';
    Parent:=AddOptionsGroupBox;
    ScrollBar:=ssAutoVertical;
  end;

  CustomOptionsLabel:=TLabel.Create(Self);
  with CustomOptionsLabel do begin
    Name:='CustomOptionsLabel';
    Parent:=AddOptionsGroupBox;
    Caption:='Custom';
  end;

  CustomOptionsMemo:=TMemo.Create(Self);
  with CustomOptionsMemo do begin
    Name:='CustomOptionsMemo';
    Parent:=AddOptionsGroupBox;
    ScrollBar:=ssAutoVertical;
  end;
end;

procedure TPackageOptionsDialog.ReadOptionsFromPackage;
begin
  if LazPackage=nil then exit;

  // Description page
  DescriptionMemo.Text:=LazPackage.Description;
  AuthorEdit.Text:=LazPackage.Author;
  
  VersionMajorSpinEdit.Value:=LazPackage.Version.Major;
  VersionMinorSpinEdit.Value:=LazPackage.Version.Minor;
  VersionReleaseSpinEdit.Value:=LazPackage.Version.Release;
  VersionBuildSpinEdit.Value:=LazPackage.Version.Build;
  AutoIncrementOnBuildCheckBox.Checked:=LazPackage.AutoIncrementVersionOnBuild;

  // Usage page
  ReadPkgTypeFromPackage;

  if LazPackage.AutoUpdate then
    UpdateRadioGroup.ItemIndex:=0
  else
    UpdateRadioGroup.ItemIndex:=1;
    
  UnitPathEdit.Text:=LazPackage.AddDependCompilerOptions.UnitPath;
  IncludePathEdit.Text:=LazPackage.AddDependCompilerOptions.IncludePath;
  ObjectPathEdit.Text:=LazPackage.AddDependCompilerOptions.ObjectPath;
  LibraryPathEdit.Text:=LazPackage.AddDependCompilerOptions.LibraryPath;
  LinkerOptionsMemo.Text:=LazPackage.AddDependCompilerOptions.LinkerOptions;
  CustomOptionsMemo.Text:=LazPackage.AddDependCompilerOptions.CustomOptions;
end;

procedure TPackageOptionsDialog.ReadPkgTypeFromPackage;
begin
  case LazPackage.PackageType of
  lptDesignTime: PkgTypeRadioGroup.ItemIndex:=0;
  lptRunTime:    PkgTypeRadioGroup.ItemIndex:=1;
  else           PkgTypeRadioGroup.ItemIndex:=2;
  end;
end;

function TPackageOptionsDialog.GetEditForPathButton(AButton: TPathEditorButton
  ): TEdit;
begin
  if AButton=UnitPathButton then
    Result:=UnitPathEdit
  else if AButton=IncludePathButton then
    Result:=IncludePathEdit
  else if AButton=ObjectPathButton then
    Result:=ObjectPathEdit
  else if AButton=LibraryPathButton then
    Result:=LibraryPathEdit
  else
    Result:=nil;
end;

constructor TPackageOptionsDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Name:='PackageOptionsDialog';
  Caption:='Package Options';
  SetupComponents;
  OnResize:=@PackageOptionsDialogResize;
  Position:=poScreenCenter;
  IDEDialogLayoutList.ApplyLayout(Self,450,400);
  OnResize(Self);
end;

destructor TPackageOptionsDialog.Destroy;
begin
  inherited Destroy;
end;

end.

