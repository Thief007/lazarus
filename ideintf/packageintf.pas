{  $Id$  }
{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Mattias Gaertner

  Abstract:
    Methods and Types to access the IDE packages.
}
unit PackageIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, NewItemIntf;
  
const
  PkgDescGroupName = 'Package';
  PkgDescNameStandard = 'Standard Package';
  
type
  TPkgSaveFlag = (
    psfSaveAs,
    psfAskBeforeSaving
    );
  TPkgSaveFlags = set of TPkgSaveFlag;

  TPkgOpenFlag = (
    pofAddToRecent,
    pofRevert
    );
  TPkgOpenFlags = set of TPkgOpenFlag;

  TPkgCompileFlag = (
    pcfCleanCompile,  // append -B to the compiler options
    pcfDoNotCompileDependencies,
    pcfDoNotCompilePackage,
    pcfCompileDependenciesClean,
    pcfOnlyIfNeeded,
    pcfDoNotSaveEditorFiles,
    pcfCreateMakefile
    );
  TPkgCompileFlags = set of TPkgCompileFlag;

  { TPackageEditingInterface }

  TPackageEditingInterface = class(TComponent)
  public
    function DoOpenPackageFile(AFilename: string;
                         Flags: TPkgOpenFlags): TModalResult; virtual; abstract;
    function DoSaveAllPackages(Flags: TPkgSaveFlags): TModalResult; virtual; abstract;

    function AddUnitDependenciesForComponentClasses(const UnitFilename: string;
                         ComponentClassnames: TStrings): TModalResult; virtual; abstract;
    function GetOwnersOfUnit(const UnitFilename: string): TList; virtual; abstract;
    procedure ExtendOwnerListWithUsedByOwners(OwnerList: TList); virtual; abstract;
    function GetSourceFilesOfOwners(OwnerList: TList): TStrings; virtual; abstract;
  end;
  
var
  PackageEditingInterface: TPackageEditingInterface; // will be set by the IDE


type
  { TPackageDescriptor }
  
  TPackageDescriptor = class(TPersistent)
  private
    FName: string;
    FReferenceCount: integer;
    FVisibleInNewDialog: boolean;
  protected
    procedure SetName(const AValue: string); virtual;
  public
    constructor Create; virtual;
    function GetLocalizedName: string; virtual;
    function GetLocalizedDescription: string; virtual;
    procedure Release;
    procedure Reference;
    // TODO: procedure InitPackage(APackage: TLazPackage); virtual;
    // TODO: procedure CreateStartFiles(APackage: TLazPackage); virtual;
  public
    property Name: string read FName write SetName;
    property VisibleInNewDialog: boolean read FVisibleInNewDialog write FVisibleInNewDialog;
  end;
  TPackageDescriptorClass = class of TPackageDescriptor;


  { TNewItemPackage - a new item for package descriptors }

  TNewItemPackage = class(TNewIDEItemTemplate)
  private
    FDescriptor: TPackageDescriptor;
  public
    function LocalizedName: string; override;
    function Description: string; override;
    procedure Assign(Source: TPersistent); override;
  public
    property Descriptor: TPackageDescriptor read FDescriptor write FDescriptor;
  end;


  { TPackageDescriptors }

  TPackageDescriptors = class(TPersistent)
  protected
    function GetItems(Index: integer): TPackageDescriptor; virtual; abstract;
  public
    function Count: integer; virtual; abstract;
    function GetUniqueName(const Name: string): string; virtual; abstract;
    function IndexOf(const Name: string): integer; virtual; abstract;
    function FindByName(const Name: string): TPackageDescriptor; virtual; abstract;
    procedure RegisterDescriptor(Descriptor: TPackageDescriptor); virtual; abstract;
    procedure UnregisterDescriptor(Descriptor: TPackageDescriptor); virtual; abstract;
  public
    property Items[Index: integer]: TPackageDescriptor read GetItems; default;
  end;

var
  PackageDescriptors: TPackageDescriptors; // will be set by the IDE


procedure RegisterPackageDescriptor(PkgDesc: TPackageDescriptor);
function PackageDescriptorStd: TPackageDescriptor;


implementation


procedure RegisterPackageDescriptor(PkgDesc: TPackageDescriptor);
var
  NewItemPkg: TNewItemPackage;
begin
  PackageDescriptors.RegisterDescriptor(PkgDesc);
  if PkgDesc.VisibleInNewDialog then begin
    NewItemPkg:=TNewItemPackage.Create(PkgDesc.Name,niifCopy,[niifCopy]);
    NewItemPkg.Descriptor:=PkgDesc;
    RegisterNewDialogItem(PkgDescGroupName,NewItemPkg);
  end;
end;

function PackageDescriptorStd: TPackageDescriptor;
begin
  Result:=PackageDescriptors.FindByName(PkgDescNameStandard);
end;

{ TPackageDescriptor }

procedure TPackageDescriptor.SetName(const AValue: string);
begin
  if FName=AValue then exit;
  FName:=AValue;
end;

constructor TPackageDescriptor.Create;
begin
  FReferenceCount:=1;
  fVisibleInNewDialog:=true;
end;

function TPackageDescriptor.GetLocalizedName: string;
begin
  Result:=Name;
end;

function TPackageDescriptor.GetLocalizedDescription: string;
begin
  Result:=GetLocalizedName;
end;

procedure TPackageDescriptor.Release;
begin
  //debugln('TPackageDescriptor.Release A ',Name,' ',dbgs(FReferenceCount));
  if FReferenceCount=0 then
    raise Exception.Create('');
  dec(FReferenceCount);
  if FReferenceCount=0 then Free;
end;

procedure TPackageDescriptor.Reference;
begin
  inc(FReferenceCount);
end;

{ TNewItemPackage }

function TNewItemPackage.LocalizedName: string;
begin
  Result:=Descriptor.GetLocalizedName;
end;

function TNewItemPackage.Description: string;
begin
  Result:=Descriptor.GetLocalizedDescription;
end;

procedure TNewItemPackage.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if Source is TNewItemPackage then
    FDescriptor:=TNewItemPackage(Source).Descriptor;
end;

initialization
  PackageEditingInterface:=nil;

end.

