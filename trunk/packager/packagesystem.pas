{  $Id$  }
{
 /***************************************************************************
                            packagesystem.pas
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
    The package registration.
}
unit PackageSystem;

{$mode objfpc}{$H+}

interface

{off $DEFINE IDE_MEM_CHECK}

{$DEFINE StopOnRegError}

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  Classes, SysUtils, AVL_Tree, Laz_XMLCfg, FileCtrl, Forms, Controls, Dialogs,
  LazarusIDEStrConsts, IDEProcs, PackageLinks, PackageDefs, LazarusPackageIntf,
  ComponentReg, RegisterFCL, RegisterLCL, RegisterSynEdit;
  
type
  TFindPackageFlag = (
    fpfSearchInInstalledPckgs,
    fpfSearchInAutoInstallPckgs,
    fpfSearchInPckgsWithEditor,
    fpfSearchInLoadedPkgs,
    fpfSearchInPkgLinks,
    fpfIgnoreVersion
    );
  TFindPackageFlags = set of TFindPackageFlag;
  
const
  fpfSearchPackageEverywhere =
    [fpfSearchInInstalledPckgs,fpfSearchInAutoInstallPckgs,
     fpfSearchInPckgsWithEditor,fpfSearchInPkgLinks,fpfSearchInLoadedPkgs];

type
  TPkgAddedEvent = procedure(APackage: TLazPackage) of object;
  TPkgDeleteEvent = procedure(APackage: TLazPackage) of object;
  TDependencyModifiedEvent = procedure(ADependency: TPkgDependency) of object;
  TEndUpdateEvent = procedure(Sender: TObject; GraphChanged: boolean) of object;

  TLazPackageGraph = class
  private
    FAbortRegistration: boolean;
    fChanged: boolean;
    FDefaultPackage: TLazPackage;
    FErrorMsg: string;
    FFCLPackage: TLazPackage;
    FItems: TList;   // unsorted list of TLazPackage
    FLCLPackage: TLazPackage;
    FOnAddPackage: TPkgAddedEvent;
    FOnBeginUpdate: TNotifyEvent;
    FOnChangePackageName: TPkgChangeNameEvent;
    FOnDeletePackage: TPkgDeleteEvent;
    FOnDependencyModified: TDependencyModifiedEvent;
    FOnEndUpdate: TEndUpdateEvent;
    FRegistrationFile: TPkgFile;
    FRegistrationPackage: TLazPackage;
    FRegistrationUnitName: string;
    FSynEditPackage: TLazPackage;
    FTree: TAVLTree; // sorted tree of TLazPackage
    FUpdateLock: integer;
    function CreateFCLPackage: TLazPackage;
    function CreateLCLPackage: TLazPackage;
    function CreateSynEditPackage: TLazPackage;
    function CreateDefaultPackage: TLazPackage;
    function GetPackages(Index: integer): TLazPackage;
    procedure DoDependencyChanged(Dependency: TPkgDependency);
    procedure SetAbortRegistration(const AValue: boolean);
    procedure SetRegistrationPackage(const AValue: TLazPackage);
    procedure UpdateBrokenDependenciesToPackage(APackage: TLazPackage);
    function OpenDependencyWithPackageLink(Dependency: TPkgDependency;
                                           PkgLink: TPackageLink): boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Delete(Index: integer);
    function Count: integer;
    procedure BeginUpdate(Change: boolean);
    procedure EndUpdate;
    function Updating: boolean;
  public
    // searching
    function CheckIfPackageCanBeClosed(APackage: TLazPackage): boolean;
    function CreateUniquePkgName(const Prefix: string;
                                 IgnorePackage: TLazPackage): string;
    function CreateUniqueUnitName(const Prefix: string): string;
    function DependencyExists(Dependency: TPkgDependency;
                              Flags: TFindPackageFlags): boolean;
    function FindAPackageWithName(const PkgName: string;
                                  IgnorePackage: TLazPackage): TLazPackage;
    function FindBrokenDependencyPath(APackage: TLazPackage): TList;
    function FindCircleDependencyPath(APackage: TLazPackage): TList;
    function FindUnsavedDependencyPath(APackage: TLazPackage): TList;
    function FindFileInAllPackages(const TheFilename: string;
                                ResolveLinks, IgnoreDeleted: boolean): TPkgFile;
    function FindLowestPkgNodeByName(const PkgName: string): TAVLTreeNode;
    function FindNextSameName(ANode: TAVLTreeNode): TAVLTreeNode;
    function FindNodeOfDependency(Dependency: TPkgDependency;
                                  Flags: TFindPackageFlags): TAVLTreeNode;
    function FindOpenPackage(Dependency: TPkgDependency;
                             Flags: TFindPackageFlags): TLazPackage;
    function FindPackageWithFilename(const TheFilename: string;
                                     ResolveLinks: boolean): TLazPackage;
    function FindPackageWithID(PkgID: TLazPackageID): TLazPackage;
    function FindUnit(StartPackage: TLazPackage; const TheUnitName: string;
                      WithRequiredPackages, IgnoreDeleted: boolean): TPkgFile;
    function FindUnitInAllPackages(const TheUnitName: string;
                                   IgnoreDeleted: boolean): TPkgFile;
    function GetAutoCompilationOrder(APackage: TLazPackage): TList;
    function GetBrokenDependenciesWhenChangingPkgID(APackage: TLazPackage;
                         const NewName: string; NewVersion: TPkgVersion): TList;
    function PackageCanBeReplaced(OldPackage, NewPackage: TLazPackage): boolean;
    function PackageIsNeeded(APackage: TLazPackage): boolean;
    function PackageNameExists(const PkgName: string;
                               IgnorePackage: TLazPackage): boolean;
    procedure ConsistencyCheck;
    procedure GetAllRequiredPackages(FirstDependency: TPkgDependency;
                                     var List: TList);
    procedure IterateAllComponentClasses(Event: TIterateComponentClassesEvent);
    procedure IterateComponentClasses(APackage: TLazPackage;
                               Event: TIterateComponentClassesEvent;
                               WithUsedPackages, WithRequiredPackages: boolean);
    procedure IteratePackages(Flags: TFindPackageFlags;
                              Event: TIteratePackagesEvent);
    procedure IteratePackagesSorted(Flags: TFindPackageFlags;
                                    Event: TIteratePackagesEvent);
    procedure MarkAllPackagesAsNotVisited;
    procedure MarkNeededPackages;
  public
    // packages handling
    function CreateNewPackage(const Prefix: string): TLazPackage;
    procedure AddPackage(APackage: TLazPackage);
    procedure ReplacePackage(OldPackage, NewPackage: TLazPackage);
    procedure AddStaticBasePackages;
    procedure ClosePackage(APackage: TLazPackage);
    procedure CloseUnneededPackages;
    procedure ChangePackageID(APackage: TLazPackage;
                              const NewName: string; NewVersion: TPkgVersion;
                              RenameDependencies: boolean);
  public
    // registration
    procedure RegisterUnitHandler(const TheUnitName: string;
                                  RegisterProc: TRegisterProc);
    procedure RegisterComponentsHandler(const Page: string;
                                    ComponentClasses: array of TComponentClass);
    procedure RegistrationError(const Msg: string);
    procedure RegisterStaticPackages;
    procedure RegisterStaticPackage(APackage: TLazPackage;
                                    RegisterProc: TRegisterProc);
    procedure RegisterDefaultPackageComponent(const Page, UnitName: ShortString;
                                              ComponentClass: TComponentClass);
  public
    // dependency handling
    procedure AddDependencyToPackage(APackage: TLazPackage;
                                     Dependency: TPkgDependency);
    procedure RemoveDependencyFromPackage(APackage: TLazPackage;
                         Dependency: TPkgDependency; AddToRemovedList: boolean);
    procedure ChangeDependency(Dependency, NewDependency: TPkgDependency);
    function OpenDependency(Dependency: TPkgDependency;
                            var APackage: TLazPackage): TLoadPackageResult;
    procedure OpenRequiredDependencyList(FirstDependency: TPkgDependency);
    procedure MoveRequiredDependencyUp(ADependency: TPkgDependency);
    procedure MoveRequiredDependencyDown(ADependency: TPkgDependency);
  public
    // properties
    property AbortRegistration: boolean read FAbortRegistration
                                        write SetAbortRegistration;
    property ErrorMsg: string read FErrorMsg write FErrorMsg;
    property FCLPackage: TLazPackage read FFCLPackage;
    property LCLPackage: TLazPackage read FLCLPackage;
    property SynEditPackage: TLazPackage read FSynEditPackage;
    property DefaultPackage: TLazPackage read FDefaultPackage;
    property OnAddPackage: TPkgAddedEvent read FOnAddPackage write FOnAddPackage;
    property OnBeginUpdate: TNotifyEvent read FOnBeginUpdate write FOnBeginUpdate;
    property OnChangePackageName: TPkgChangeNameEvent read FOnChangePackageName
                                                     write FOnChangePackageName;
    property OnDependencyModified: TDependencyModifiedEvent
                         read FOnDependencyModified write FOnDependencyModified;
    property OnDeletePackage: TPkgDeleteEvent read FOnDeletePackage
                                              write FOnDeletePackage;
    property OnEndUpdate: TEndUpdateEvent read FOnEndUpdate write FOnEndUpdate;
    property Packages[Index: integer]: TLazPackage read GetPackages; default;
    property RegistrationFile: TPkgFile read FRegistrationFile;
    property RegistrationPackage: TLazPackage read FRegistrationPackage
                                              write SetRegistrationPackage;
    property RegistrationUnitName: string read FRegistrationUnitName;
    property UpdateLock: integer read FUpdateLock;
  end;
  
var
  PackageGraph: TLazPackageGraph;

implementation

procedure RegisterCustomIDEComponent(const Page, UnitName: ShortString;
  ComponentClass: TComponentClass);
begin
  PackageGraph.RegisterDefaultPackageComponent(Page,UnitName,ComponentClass);
end;

procedure RegisterComponentsGlobalHandler(const Page: string;
  ComponentClasses: array of TComponentClass);
begin
  PackageGraph.RegisterComponentsHandler(Page,ComponentClasses);
end;

procedure RegisterNoIconGlobalHandler(
  ComponentClasses: array of TComponentClass);
begin
  PackageGraph.RegisterComponentsHandler('',ComponentClasses);
end;

{ TLazPackageGraph }

procedure TLazPackageGraph.DoDependencyChanged(Dependency: TPkgDependency);
begin
  fChanged:=true;
  if Assigned(OnDependencyModified) then OnDependencyModified(Dependency);
end;

function TLazPackageGraph.GetPackages(Index: integer): TLazPackage;
begin
  Result:=TLazPackage(FItems[Index]);
end;

procedure TLazPackageGraph.SetAbortRegistration(const AValue: boolean);
begin
  if FAbortRegistration=AValue then exit;
  FAbortRegistration:=AValue;
end;

procedure TLazPackageGraph.SetRegistrationPackage(const AValue: TLazPackage);
begin
  if FRegistrationPackage=AValue then exit;
  FRegistrationPackage:=AValue;
  AbortRegistration:=false;
  LazarusPackageIntf.RegisterUnit:=@RegisterUnitHandler;
  RegisterComponentsProc:=@RegisterComponentsGlobalHandler;
  RegisterNoIconProc:=@RegisterNoIconGlobalHandler;
end;

procedure TLazPackageGraph.UpdateBrokenDependenciesToPackage(
  APackage: TLazPackage);
var
  ANode: TAVLTreeNode;
  Dependency: TPkgDependency;
  RequiredPackage: TLazPackage;
begin
  BeginUpdate(false);
  ANode:=FindLowestPkgDependencyNodeWithName(APackage.Name);
  while ANode<>nil do begin
    Dependency:=TPkgDependency(ANode.Data);
    if (Dependency.LoadPackageResult<>lprSuccess)
    and Dependency.IsCompatible(APackage) then begin
      Dependency.LoadPackageResult:=lprUndefined;
      OpenDependency(Dependency,RequiredPackage);
    end;
    ANode:=FindNextPkgDependecyNodeWithSameName(ANode);
  end;
  EndUpdate;
end;

function TLazPackageGraph.OpenDependencyWithPackageLink(
  Dependency: TPkgDependency; PkgLink: TPackageLink): boolean;
var
  AFilename: String;
  NewPackage: TLazPackage;
  XMLConfig: TXMLConfig;
begin
  Result:=false;
  BeginUpdate(false);
  AFilename:=PkgLink.Filename;
  if not FileExists(AFilename) then exit;
  try
    XMLConfig:=TXMLConfig.Create(AFilename);
    NewPackage:=TLazPackage.Create;
    NewPackage.Filename:=AFilename;
    NewPackage.LoadFromXMLConfig(XMLConfig,'Package/');
    XMLConfig.Free;
  except
    on E: Exception do begin
      writeln('unable to read file "'+AFilename+'" ',E.Message);
      exit;
    end;
  end;
  if not NewPackage.MakeSense then exit;
  if PkgLink.Compare(NewPackage)<>0 then exit;
  // ok
  AddPackage(NewPackage);
  EndUpdate;
  Result:=true;
end;

constructor TLazPackageGraph.Create;
begin
  OnGetAllRequiredPackages:=@GetAllRequiredPackages;
  FTree:=TAVLTree.Create(@CompareLazPackageID);
  FItems:=TList.Create;
end;

destructor TLazPackageGraph.Destroy;
begin
  if LazarusPackageIntf.RegisterUnit=@RegisterUnitHandler then
    LazarusPackageIntf.RegisterUnit:=nil;
  if RegisterComponentsProc=@RegisterComponentsGlobalHandler then
    RegisterComponentsProc:=nil;
  if RegisterNoIconProc=@RegisterNoIconGlobalHandler then
    RegisterNoIconProc:=nil;
  if OnGetAllRequiredPackages=@GetAllRequiredPackages then
    OnGetAllRequiredPackages:=nil;
  Clear;
  FItems.Free;
  FTree.Free;
  inherited Destroy;
end;

procedure TLazPackageGraph.Clear;
var
  i: Integer;
begin
  for i:=FItems.Count-1 downto 0 do Delete(i);
end;

procedure TLazPackageGraph.Delete(Index: integer);
var
  CurPkg: TLazPackage;
begin
  BeginUpdate(true);
  CurPkg:=Packages[Index];
  CurPkg.Flags:=CurPkg.Flags+[lpfDestroying];
  if Assigned(OnDeletePackage) then OnDeletePackage(CurPkg);
  FItems.Delete(Index);
  FTree.Remove(CurPkg);
  CurPkg.Free;
  EndUpdate;
end;

function TLazPackageGraph.Count: integer;
begin
  Result:=FItems.Count;
end;

procedure TLazPackageGraph.BeginUpdate(Change: boolean);
begin
  inc(FUpdateLock);
  if FUpdateLock=1 then begin
    fChanged:=Change;
    if Assigned(OnBeginUpdate) then OnBeginUpdate(Self);
  end else
    fChanged:=fChanged or Change;
end;

procedure TLazPackageGraph.EndUpdate;
begin
  if FUpdateLock<=0 then RaiseException('TLazPackageGraph.EndUpdate');
  dec(FUpdateLock);
  if FUpdateLock=0 then begin
    if Assigned(OnEndUpdate) then OnEndUpdate(Self,fChanged);
  end;
end;

function TLazPackageGraph.Updating: boolean;
begin
  Result:=FUpdateLock>0;
end;

function TLazPackageGraph.FindLowestPkgNodeByName(const PkgName: string
  ): TAVLTreeNode;
var
  PriorNode: TAVLTreeNode;
begin
  Result:=nil;
  if PkgName='' then exit;
  Result:=FTree.FindKey(PChar(PkgName),@CompareNameWithPackageID);
  while Result<>nil do begin
    PriorNode:=FTree.FindPrecessor(Result);
    if (PriorNode=nil)
    or (AnsiCompareText(PkgName,TLazPackage(PriorNode.Data).Name)<>0) then
      break;
    Result:=PriorNode;
  end;
end;

function TLazPackageGraph.FindNextSameName(ANode: TAVLTreeNode): TAVLTreeNode;
var
  NextNode: TAVLTreeNode;
begin
  Result:=nil;
  if ANode=nil then exit;
  NextNode:=FTree.FindSuccessor(ANode);
  if (NextNode=nil)
  or (AnsiCompareText(TLazPackage(ANode.Data).Name,
                      TLazPackage(NextNode.Data).Name)<>0)
  then exit;
  Result:=NextNode;
end;

function TLazPackageGraph.FindNodeOfDependency(Dependency: TPkgDependency;
  Flags: TFindPackageFlags): TAVLTreeNode;
var
  CurPkg: TLazPackage;
begin
  // search in all packages with the same name
  Result:=FindLowestPkgNodeByName(Dependency.PackageName);
  while Result<>nil do begin
    CurPkg:=TLazPackage(Result.Data);
    // check version
    if (not (fpfIgnoreVersion in Flags))
    and (not Dependency.IsCompatible(CurPkg)) then begin
      Result:=FindNextSameName(Result);
      continue;
    end;
    // check loaded packages
    if (fpfSearchInLoadedPkgs in Flags) then exit;
    // check installed packages
    if (fpfSearchInInstalledPckgs in Flags)
    and (CurPkg.Installed<>pitNope) then exit;
    // check autoinstall packages
    if (fpfSearchInAutoInstallPckgs in Flags)
    and (CurPkg.AutoInstall<>pitNope) then exit;
    // check packages with opened editor
    if (fpfSearchInPckgsWithEditor in Flags) and (CurPkg.Editor<>nil) then exit;
    // search next package node with same name
    Result:=FindNextSameName(Result);
  end;
end;

function TLazPackageGraph.FindOpenPackage(Dependency: TPkgDependency;
  Flags: TFindPackageFlags): TLazPackage;
var
  ANode: TAVLTreeNode;
begin
  ANode:=FindNodeOfDependency(Dependency,Flags);
  if ANode<>nil then
    Result:=TLazPackage(ANode.Data)
  else
    Result:=nil;
end;

function TLazPackageGraph.FindAPackageWithName(const PkgName: string;
  IgnorePackage: TLazPackage): TLazPackage;
var
  ANode: TAVLTreeNode;
begin
  Result:=nil;
  ANode:=FindLowestPkgNodeByName(PkgName);
  if ANode<>nil then begin
    Result:=TLazPackage(ANode.Data);
    if Result=IgnorePackage then begin
      Result:=nil;
      ANode:=FindNextSameName(ANode);
      if ANode<>nil then
        Result:=TLazPackage(ANode.Data);
    end;
  end;
end;

function TLazPackageGraph.FindPackageWithID(PkgID: TLazPackageID): TLazPackage;
var
  ANode: TAVLTreeNode;
begin
  ANode:=FTree.Find(PkgID);
  if ANode<>nil then
    Result:=TLazPackage(ANode.Data)
  else
    Result:=nil;
end;

function TLazPackageGraph.FindUnit(StartPackage: TLazPackage;
  const TheUnitName: string;
  WithRequiredPackages, IgnoreDeleted: boolean): TPkgFile;
var
  ADependency: TPkgDependency;
  ARequiredPackage: TLazPackage;
begin
  Result:=StartPackage.FindUnit(TheUnitName,IgnoreDeleted);
  if Result<>nil then exit;
  // search also in all required packages
  if WithRequiredPackages then begin
    ADependency:=StartPackage.FirstRequiredDependency;
    while ADependency<>nil do begin
      ARequiredPackage:=FindOpenPackage(ADependency,[fpfSearchInInstalledPckgs]);
      if ARequiredPackage<>nil then begin
        Result:=ARequiredPackage.FindUnit(TheUnitName,IgnoreDeleted);
        if Result<>nil then exit;
      end;
      ADependency:=ADependency.NextRequiresDependency;
    end;
  end;
end;

function TLazPackageGraph.FindUnitInAllPackages(
  const TheUnitName: string; IgnoreDeleted: boolean): TPkgFile;
var
  Cnt: Integer;
  i: Integer;
begin
  Cnt:=Count;
  for i:=0 to Cnt-1 do begin
    Result:=FindUnit(Packages[i],TheUnitName,false,IgnoreDeleted);
    if Result<>nil then exit;
  end;
  Result:=nil;
end;

function TLazPackageGraph.FindFileInAllPackages(const TheFilename: string;
  ResolveLinks, IgnoreDeleted: boolean): TPkgFile;
var
  Cnt: Integer;
  i: Integer;
begin
  Cnt:=Count;
  for i:=0 to Cnt-1 do begin
    Result:=Packages[i].FindPkgFile(TheFilename,ResolveLinks,IgnoreDeleted);
    if Result<>nil then exit;
  end;
  Result:=nil;
end;

function TLazPackageGraph.FindPackageWithFilename(const TheFilename: string;
  ResolveLinks: boolean): TLazPackage;
var
  Cnt: Integer;
  i: Integer;
  AFilename: string;
begin
  Cnt:=Count;
  AFilename:=TheFilename;
  if ResolveLinks then begin
    AFilename:=ReadAllLinks(TheFilename,false);
    if AFilename='' then AFilename:=TheFilename;
  end;
  for i:=0 to Cnt-1 do begin
    Result:=Packages[i];
    if Result.IsVirtual then continue;
    if ResolveLinks then begin
      if CompareFilenames(TheFilename,Result.GetResolvedFilename)=0 then
        exit;
    end else begin
      if CompareFilenames(TheFilename,Result.Filename)=0 then
        exit;
    end;
  end;
  Result:=nil;
end;

function TLazPackageGraph.CreateUniqueUnitName(const Prefix: string): string;
var
  i: Integer;
begin
  if FindUnitInAllPackages(Prefix,false)=nil then
    Result:=Prefix
  else begin
    i:=1;
    repeat
      Result:=Prefix+IntToStr(i);
    until FindUnitInAllPackages(Result,false)=nil;
  end;
end;

function TLazPackageGraph.PackageNameExists(const PkgName: string;
  IgnorePackage: TLazPackage): boolean;
var
  ANode: TAVLTreeNode;
begin
  Result:=false;
  if PkgName<>'' then begin
    ANode:=FindLowestPkgNodeByName(PkgName);
    if (ANode<>nil) and (IgnorePackage=TLazPackage(ANode.Data)) then
      ANode:=FindNextSameName(ANode);
    Result:=ANode<>nil;
  end;
end;

function TLazPackageGraph.DependencyExists(Dependency: TPkgDependency;
  Flags: TFindPackageFlags): boolean;
begin
  Result:=true;
  if FindNodeOfDependency(Dependency,Flags)<>nil then exit;
  if FindAPackageWithName(Dependency.PackageName,nil)=nil then begin
    // no package with same name open
    // -> try package links
    if fpfSearchInPkgLinks in Flags then
      if PkgLinks.FindLinkWithDependency(Dependency)<>nil then exit;
  end else begin
    // there is already a package with this name open, but the wrong version
  end;
  Result:=false;
end;

function TLazPackageGraph.CreateUniquePkgName(const Prefix: string;
  IgnorePackage: TLazPackage): string;
var
  i: Integer;
begin
  // try Prefix alone
  if not PackageNameExists(Prefix,IgnorePackage) then begin
    Result:=Prefix;
  end else begin
    // try Prefix + number
    i:=1;
    while PackageNameExists(Prefix+IntToStr(i),IgnorePackage) do inc(i);
    Result:=Prefix+IntToStr(i);
  end;
end;

function TLazPackageGraph.CreateNewPackage(const Prefix: string): TLazPackage;
begin
  BeginUpdate(true);
  Result:=TLazPackage.Create;
  Result.Name:=CreateUniquePkgName('NewPackage',nil);
  AddPackage(Result);
  EndUpdate;
end;

procedure TLazPackageGraph.ConsistencyCheck;
begin
  CheckList(FItems,true,true,true);
end;

procedure TLazPackageGraph.RegisterUnitHandler(const TheUnitName: string;
  RegisterProc: TRegisterProc);
begin
  if AbortRegistration then exit;

  ErrorMsg:='';
  FRegistrationFile:=nil;
  FRegistrationUnitName:='';

  // check package
  if FRegistrationPackage=nil then begin
    RegistrationError('');
    exit;
  end;
  try
    // check unitname
    FRegistrationUnitName:=TheUnitName;
    if not IsValidIdent(FRegistrationUnitName) then begin
      RegistrationError('Invalid Unitname: '+FRegistrationUnitName);
      exit;
    end;
    // check unit file
    FRegistrationFile:=FRegistrationPackage.FindUnit(FRegistrationUnitName,true);
    if FRegistrationFile=nil then begin
      FRegistrationFile:=
        FRegistrationPackage.FindUnit(FRegistrationUnitName,false);
      if FRegistrationFile=nil then begin
        RegistrationError('Unit not found: "'+FRegistrationUnitName+'"');
      end else begin
        RegistrationError(
          'Unit "'+FRegistrationUnitName+'" was deleted from package');
      end;
      exit;
    end;
    // check registration procedure
    if RegisterProc=nil then begin
      RegistrationError('Register procedure is nil');
      exit;
    end;
    {$IFNDEF StopOnRegError}
    try
    {$ENDIF}
      // call the registration procedure
      RegisterProc();
    {$IFNDEF StopOnRegError}
    except
      on E: Exception do begin
        RegistrationError(E.Message);
      end;
    end;
    {$ENDIF}
    // clean up
  finally
    FRegistrationUnitName:='';
    FRegistrationFile:=nil;
  end;
end;

procedure TLazPackageGraph.RegisterComponentsHandler(const Page: string;
  ComponentClasses: array of TComponentClass);
var
  i: integer;
  CurComponent: TComponentClass;
  NewPkgComponent: TPkgComponent;
  CurClassname: string;
begin
  {$IFDEF IDE_MEM_CHECK}
  CheckHeap('TLazPackageGraph.RegisterComponentsHandler Page='+Page);
  {$ENDIF}
  if AbortRegistration or (Low(ComponentClasses)>High(ComponentClasses)) then
    exit;

  ErrorMsg:='';

  // check package
  if FRegistrationPackage=nil then begin
    RegistrationError('');
    exit;
  end;
  // check unit file
  if FRegistrationFile=nil then begin
    RegistrationError('Can not register components without unit');
    exit;
  end;
  // register components
  for i:=Low(ComponentClasses) to High(ComponentClasses) do begin
    CurComponent:=ComponentClasses[i];
    if (CurComponent=nil) then continue;
    {$IFNDEF StopOnRegError}
    try
    {$ENDIF}
      CurClassname:=CurComponent.Classname;
      if not IsValidIdent(CurClassname) then begin
        RegistrationError('Invalid component class');
        continue;
      end;
    {$IFNDEF StopOnRegError}
    except
      on E: Exception do begin
        RegistrationError(E.Message);
        continue;
      end;
    end;
    {$ENDIF}
    if IDEComponentPalette.FindComponent(CurClassname)<>nil then begin
      RegistrationError(
        'Component Class "'+CurComponent.ClassName+'" already defined');
    end;
    if AbortRegistration then exit;
    NewPkgComponent:=
      FRegistrationPackage.AddComponent(FRegistrationFile,Page,CurComponent);
    IDEComponentPalette.AddComponent(NewPkgComponent);
  end;
end;

procedure TLazPackageGraph.RegistrationError(const Msg: string);
var
  DlgResult: Integer;
begin
  // create nice and useful error message

  // current registration package
  if FRegistrationPackage=nil then begin
    ErrorMsg:='RegisterUnit was called, but no package is registering.';
  end else begin
    ErrorMsg:='Package: "'+FRegistrationPackage.IDAsString+'"';
    // current unitname
    if FRegistrationUnitName<>'' then
      ErrorMsg:=ErrorMsg+#13+'Unit Name: "'+FRegistrationUnitName+'"';
    // current file
    if FRegistrationFile<>nil then
      ErrorMsg:=ErrorMsg+#13+'File Name: "'+FRegistrationFile.Filename+'"';
  end;
  // append message
  if Msg<>'' then
    ErrorMsg:=ErrorMsg+#13#13+Msg;
  // tell user
  DlgResult:=MessageDlg('Registration Error',
                        ErrorMsg,mtError,[mbIgnore,mbAbort],0);
  if DlgResult=mrAbort then
    AbortRegistration:=true;
end;

function TLazPackageGraph.CreateFCLPackage: TLazPackage;
begin
  Result:=TLazPackage.Create;
  with Result do begin
    AutoCreated:=true;
    Name:='FCL';
    Filename:='$(FPCSrcDir)/fcl/';
    Version.SetValues(1,0,1,1);
    Author:='FPC team';
    AutoInstall:=pitStatic;
    AutoUpdate:=false;
    Description:='The FCL - FreePascal Component Library '
                 +'provides the base classes for object pascal.';
    PackageType:=lptDesignTime;
    Installed:=pitStatic;
    CompilerOptions.UnitOutputDirectory:='';
    
    // add lazarus registration unit path
    UsageOptions.UnitPath:='$(LazarusDir)/packager/units';

    // add registering units
    AddFile('inc/process.pp','Process',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('db/db.pp','DB',pftUnit,[pffHasRegisterProc],cpBase);

    Modified:=false;
  end;
end;

function TLazPackageGraph.CreateLCLPackage: TLazPackage;
var
  i: Integer;
begin
  Result:=TLazPackage.Create;
  with Result do begin
    AutoCreated:=true;
    Name:='LCL';
    Filename:='$(LazarusDir)/lcl/';
    Version.SetValues(1,0,1,1);
    Author:='Lazarus';
    AutoInstall:=pitStatic;
    AutoUpdate:=false;
    Description:='The LCL - Lazarus Component Library '
                 +'contains all base components for form editing.';
    PackageType:=lptDesignTime;
    Installed:=pitStatic;
    CompilerOptions.UnitOutputDirectory:='';

    // add registering units
    AddFile('menus.pp','Menus',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('buttons.pp','Buttons',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('stdctrls.pp','StdCtrls',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('extctrls.pp','ExtCtrls',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('comctrls.pp','ComCtrls',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('maskedit.pp','MaskEdit',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('forms.pp','Forms',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('grids.pas','Grids',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('controls.pp','Controls',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('dialogs.pp','Dialogs',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('spin.pp','Spin',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('arrow.pp','Arrow',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('calendar.pp','Calendar',pftUnit,[pffHasRegisterProc],cpBase);
    // increase priority by one, so that the LCL components are inserted to the
    // left in the palette
    for i:=0 to FileCount-1 do
      inc(Files[i].ComponentPriority.Level);

    // add unit paths
    UsageOptions.UnitPath:=
      '$(LazarusDir)/lcl/units;$(LazarusDir)/lcl/units/$(LCLWidgetType)';

    // add requirements
    AddRequiredDependency(FCLPackage.CreateDependencyForThisPkg);
    
    Modified:=false;
  end;
end;

function TLazPackageGraph.CreateSynEditPackage: TLazPackage;
begin
  Result:=TLazPackage.Create;
  with Result do begin
    AutoCreated:=true;
    Name:='SynEdit';
    Filename:='$(LazarusDir)/components/synedit/';
    Version.SetValues(1,0,1,1);
    Author:='SynEdit - http://sourceforge.net/projects/synedit/';
    AutoInstall:=pitStatic;
    AutoUpdate:=false;
    Description:='SynEdit - the editor component used by Lazarus. '
                +'http://sourceforge.net/projects/synedit/';
    PackageType:=lptDesignTime;
    Installed:=pitStatic;
    CompilerOptions.UnitOutputDirectory:='';

    // add units
    AddFile('synedit.pp','SynEdit',pftUnit,[],cpBase);
    AddFile('syneditlazdsgn.pas','SynEditLazDsgn',pftUnit,[],cpBase);
    AddFile('syncompletion.pas','SynCompletion',pftUnit,[],cpBase);
    AddFile('synexporthtml.pas','SynExportHTML',pftUnit,[],cpBase);
    AddFile('synmacrorecorder.pas','SynMacroRecorder',pftUnit,[],cpBase);
    AddFile('synmemo.pas','SynMemo',pftUnit,[],cpBase);
    AddFile('synhighlighterpas.pas','SynHighlighterPas',pftUnit,[],cpBase);
    AddFile('synhighlightercpp.pp','SynHighlighterCPP',pftUnit,[],cpBase);
    AddFile('synhighlighterjava.pas','SynHighlighterJava',pftUnit,[],cpBase);
    AddFile('synhighlighterperl.pas','SynHighlighterPerl',pftUnit,[],cpBase);
    AddFile('synhighlighterhtml.pp','SynHighlighterHTML',pftUnit,[],cpBase);
    AddFile('synhighlighterxml.pas','SynHighlighterXML',pftUnit,[],cpBase);
    AddFile('synhighlighterlfm.pas','SynHighlighterLFM',pftUnit,[],cpBase);
    AddFile('synhighlightermulti.pas','SynHighlighterMulti',pftUnit,[],cpBase);

    // add unit paths
    UsageOptions.UnitPath:='$(LazarusDir)/components/units';

    // add requirements
    AddRequiredDependency(LCLPackage.CreateDependencyForThisPkg);

    Modified:=false;
  end;
end;

function TLazPackageGraph.CreateDefaultPackage: TLazPackage;
begin
  Result:=TLazPackage.Create;
  with Result do begin
    AutoCreated:=true;
    Name:='DefaultPackage';
    Filename:='$(LazarusDir)/components/custom/';
    Version.SetValues(1,0,1,1);
    Author:='Anonymous';
    AutoInstall:=pitStatic;
    AutoUpdate:=false;
    Description:='This is the default package. '
                +'Used only for components without a package. '
                +'These components are outdated.';
    PackageType:=lptDesignTime;
    Installed:=pitStatic;
    CompilerOptions.UnitOutputDirectory:='';

    // add unit paths
    UsageOptions.UnitPath:='$(LazarusDir)/components/custom';

    // add requirements
    AddRequiredDependency(LCLPackage.CreateDependencyForThisPkg);
    AddRequiredDependency(SynEditPackage.CreateDependencyForThisPkg);

    Modified:=false;
  end;
end;

procedure TLazPackageGraph.AddPackage(APackage: TLazPackage);
var
  RequiredPackage: TLazPackage;
  Dependency: TPkgDependency;
begin
  BeginUpdate(true);
  FTree.Add(APackage);
  FItems.Add(APackage);

  // open all required dependencies
  Dependency:=APackage.FirstRequiredDependency;
  while Dependency<>nil do begin
    OpenDependency(Dependency,RequiredPackage);
    Dependency:=Dependency.NextRequiresDependency;
  end;
  
  // update all missing dependencies
  UpdateBrokenDependenciesToPackage(APackage);

  if Assigned(OnAddPackage) then OnAddPackage(APackage);
  EndUpdate;
end;

procedure TLazPackageGraph.ReplacePackage(OldPackage, NewPackage: TLazPackage);
begin
  BeginUpdate(true);
  Delete(fItems.IndexOf(OldPackage));
  AddPackage(NewPackage);
  EndUpdate;
end;

procedure TLazPackageGraph.AddStaticBasePackages;
begin
  // FCL
  FFCLPackage:=CreateFCLPackage;
  AddPackage(FFCLPackage);
  // LCL
  FLCLPackage:=CreateLCLPackage;
  AddPackage(FLCLPackage);
  // SynEdit
  FSynEditPackage:=CreateSynEditPackage;
  AddPackage(FSynEditPackage);
  // the default package will be added on demand
  FDefaultPackage:=CreateDefaultPackage;
end;

procedure TLazPackageGraph.ClosePackage(APackage: TLazPackage);
begin
  if (lpfDestroying in APackage.Flags) or PackageIsNeeded(APackage) then exit;
  CloseUnneededPackages;
end;

procedure TLazPackageGraph.MarkNeededPackages;
var
  i: Integer;
  Pkg: TLazPackage;
  PkgStack: PLazPackage;
  StackPtr: Integer;
  RequiredPackage: TLazPackage;
  Dependency: TPkgDependency;
begin
  if Count=0 then exit;
  // mark all packages as unneeded
  for i:=0 to FItems.Count-1 do begin
    Pkg:=TLazPackage(FItems[i]);
    Pkg.Flags:=Pkg.Flags-[lpfNeeded];
  end;
  // create stack
  GetMem(PkgStack,SizeOf(Pointer)*Count);
  StackPtr:=0;
  // put all needed packages on stack
  for i:=0 to FItems.Count-1 do begin
    Pkg:=TLazPackage(FItems[i]);
    if PackageIsNeeded(Pkg)
    and (not (lpfNeeded in Pkg.Flags)) then begin
      Pkg.Flags:=Pkg.Flags+[lpfNeeded];
      PkgStack[StackPtr]:=Pkg;
      inc(StackPtr);
    end;
  end;
  // mark all needed packages
  while StackPtr>0 do begin
    // get needed package from stack
    dec(StackPtr);
    Pkg:=PkgStack[StackPtr];
    // put all required packages on stack
    Dependency:=Pkg.FirstRequiredDependency;
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        RequiredPackage:=Dependency.RequiredPackage;
        if (not (lpfNeeded in RequiredPackage.Flags)) then begin
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfNeeded];
          PkgStack[StackPtr]:=RequiredPackage;
          inc(StackPtr);
        end;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;
  // clean up
  FreeMem(PkgStack);
end;

function TLazPackageGraph.FindBrokenDependencyPath(APackage: TLazPackage
  ): TList;
  
  procedure FindBroken(CurPackage: TLazPackage; var PathList: TList);
  var
    Dependency: TPkgDependency;
    RequiredPackage: TLazPackage;
  begin
    CurPackage.Flags:=CurPackage.Flags+[lpfVisited];
    Dependency:=CurPackage.FirstRequiredDependency;
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        // dependency ok
        RequiredPackage:=Dependency.RequiredPackage;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          FindBroken(RequiredPackage,PathList);
          if PathList<>nil then begin
            // broken dependency found
            // -> add current package to list
            PathList.Insert(0,CurPackage);
            exit;
          end;
        end;
      end else begin
        // broken dependency found
        PathList:=TList.Create;
        PathList.Add(CurPackage);
        PathList.Add(Dependency);
        exit;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;
  
begin
  Result:=nil;
  if (Count=0) or (APackage=nil) then exit;
  MarkAllPackagesAsNotVisited;
  FindBroken(APackage,Result);
end;

function TLazPackageGraph.FindCircleDependencyPath(APackage: TLazPackage
  ): TList;

  procedure FindCircle(CurPackage: TLazPackage; var PathList: TList);
  var
    Dependency: TPkgDependency;
    RequiredPackage: TLazPackage;
  begin
    CurPackage.Flags:=CurPackage.Flags+[lpfVisited,lpfCircle];
    Dependency:=CurPackage.FirstRequiredDependency;
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        // dependency ok
        RequiredPackage:=Dependency.RequiredPackage;
        if lpfCircle in RequiredPackage.Flags then begin
          // circle detected
          PathList:=TList.Create;
          PathList.Add(CurPackage);
          PathList.Add(RequiredPackage);
          exit;
        end;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          FindCircle(RequiredPackage,PathList);
          if PathList<>nil then begin
            // circle detected
            // -> add current package to list
            PathList.Insert(0,CurPackage);
            exit;
          end;
        end;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
    CurPackage.Flags:=CurPackage.Flags-[lpfCircle];
  end;

var
  i: Integer;
  Pkg: TLazPackage;
begin
  Result:=nil;
  if (Count=0) or (APackage=nil) then exit;
  // mark all packages as not visited and circle free
  for i:=FItems.Count-1 downto 0 do begin
    Pkg:=TLazPackage(FItems[i]);
    Pkg.Flags:=Pkg.Flags-[lpfVisited,lpfCircle];
  end;
  FindCircle(APackage,Result);
end;

function TLazPackageGraph.FindUnsavedDependencyPath(APackage: TLazPackage
  ): TList;

  procedure FindUnsaved(CurPackage: TLazPackage; var PathList: TList);
  var
    Dependency: TPkgDependency;
    RequiredPackage: TLazPackage;
  begin
    CurPackage.Flags:=CurPackage.Flags+[lpfVisited];
    Dependency:=CurPackage.FirstRequiredDependency;
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        // dependency ok
        RequiredPackage:=Dependency.RequiredPackage;
        if RequiredPackage.Modified then begin
          // unsaved package detected
          PathList:=TList.Create;
          PathList.Add(CurPackage);
          PathList.Add(RequiredPackage);
          exit;
        end;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          FindUnsaved(RequiredPackage,PathList);
          if PathList<>nil then begin
            // unsaved package detected
            // -> add current package to list
            PathList.Insert(0,CurPackage);
            exit;
          end;
        end;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
    CurPackage.Flags:=CurPackage.Flags-[lpfCircle];
  end;

var
  i: Integer;
  Pkg: TLazPackage;
begin
  Result:=nil;
  if (Count=0) or (APackage=nil) then exit;
  // mark all packages as not visited
  for i:=FItems.Count-1 downto 0 do begin
    Pkg:=TLazPackage(FItems[i]);
    Pkg.Flags:=Pkg.Flags-[lpfVisited];
  end;
  FindUnsaved(APackage,Result);
end;

function TLazPackageGraph.GetAutoCompilationOrder(APackage: TLazPackage
  ): TList;
  
  procedure GetTopologicalOrder(const FirstDependency: TPkgDependency);
  var
    Dependency: TPkgDependency;
    RequiredPackage: TLazPackage;
  begin
    Dependency:=FirstDependency;
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        RequiredPackage:=Dependency.RequiredPackage;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfVisited];
          if RequiredPackage.AutoUpdate then begin
            // add first all needed packages
            GetTopologicalOrder(RequiredPackage.FirstRequiredDependency);
            // then add this package
            if Result=nil then Result:=TList.Create;
            Result.Add(RequiredPackage);
          end;
        end;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;
  
begin
  Result:=nil;
  MarkAllPackagesAsNotVisited;
  APackage.Flags:=APackage.Flags+[lpfVisited];
  GetTopologicalOrder(APackage.FirstRequiredDependency);
end;

procedure TLazPackageGraph.MarkAllPackagesAsNotVisited;
var
  i: Integer;
  Pkg: TLazPackage;
begin
  // mark all packages as not visited
  for i:=FItems.Count-1 downto 0 do begin
    Pkg:=TLazPackage(FItems[i]);
    Pkg.Flags:=Pkg.Flags-[lpfVisited];
  end;
end;

procedure TLazPackageGraph.CloseUnneededPackages;
var
  i: Integer;
begin
  BeginUpdate(false);
  MarkNeededPackages;
  for i:=FItems.Count-1 downto 0 do begin
    if not (lpfNeeded in Packages[i].Flags) then Delete(i);
  end;
  EndUpdate;
end;

procedure TLazPackageGraph.ChangePackageID(APackage: TLazPackage;
  const NewName: string; NewVersion: TPkgVersion; RenameDependencies: boolean);
var
  Dependency: TPkgDependency;
  NextDependency: TPkgDependency;
  OldPkgName: String;
begin
  OldPkgName:=APackage.Name;
  if (AnsiCompareText(OldPkgName,NewName)=0)
  and (APackage.Version.Compare(NewVersion)=0) then begin
    // ID does not change
    // -> just rename
    APackage.Name:=NewName;
    fChanged:=true;
    exit;
  end;

  // ID changed

  BeginUpdate(true);

  // cut or fix all dependencies, that became incompatible
  Dependency:=APackage.FirstUsedByDependency;
  while Dependency<>nil do begin
    NextDependency:=Dependency.NextUsedByDependency;
    if not Dependency.IsCompatible(NewName,NewVersion) then begin
      if RenameDependencies then begin
        Dependency.MakeCompatible(NewName,NewVersion);
        if Assigned(OnDependencyModified) then OnDependencyModified(Dependency);
      end else begin
        // remove dependency from the used-by list of the required package
        Dependency.RequiredPackage:=nil;
      end;
    end;
    Dependency:=NextDependency;
  end;
  
  // change ID
  FTree.Remove(APackage);
  APackage.ChangeID(NewName,NewVersion);
  FTree.Add(APackage);

  // update old broken dependencies
  UpdateBrokenDependenciesToPackage(APackage);

  if Assigned(OnChangePackageName) then
    OnChangePackageName(APackage,OldPkgName);
  EndUpdate;
end;

function TLazPackageGraph.GetBrokenDependenciesWhenChangingPkgID(
  APackage: TLazPackage; const NewName: string; NewVersion: TPkgVersion
    ): TList;
var
  Dependency: TPkgDependency;
begin
  Result:=TList.Create;
  // find all dependencies, that will become incompatible
  Dependency:=APackage.FirstUsedByDependency;
  while Dependency<>nil do begin
    if not Dependency.IsCompatible(NewName,NewVersion) then
      Result.Add(Dependency);
    Dependency:=Dependency.NextUsedByDependency;
  end;
end;

function TLazPackageGraph.CheckIfPackageCanBeClosed(APackage: TLazPackage
  ): boolean;
begin
  MarkNeededPackages;
  Result:=lpfNeeded in APackage.FLags;
end;

function TLazPackageGraph.PackageIsNeeded(APackage: TLazPackage): boolean;
// check if package is currently in use (installed, autoinstall, editor open,
// or used by a needed dependency)
// !!! it does not check if any needed package needs this package
begin
  Result:=true;
  // check if package is open, installed or will be installed
  if (APackage.Installed<>pitNope) or (APackage.AutoInstall<>pitNope)
  or ((APackage.Editor<>nil) and (APackage.Editor.Visible))
  or (APackage.HoldPackageCount>0) then
  begin
    exit;
  end;
  Result:=false;
end;

function TLazPackageGraph.PackageCanBeReplaced(
  OldPackage, NewPackage: TLazPackage): boolean;
var
  Dependency: TPkgDependency;
begin
  Result:=false;
  if PackageIsNeeded(OldPackage) then exit;

  // check all used-by dependencies
  Dependency:=OldPackage.FirstUsedByDependency;
  if Dependency<>nil then begin
    MarkNeededPackages;
    while Dependency<>nil do begin
      if (not Dependency.IsCompatible(NewPackage)) then begin
        // replacing will break this dependency
        // -> check if Owner is needed
        if (Dependency.Owner=nil) then begin
          // dependency has no owner -> can be broken
        end else if (Dependency.Owner is TLazPackage) then begin
          if lpfNeeded in TLazPackage(Dependency.Owner).Flags then begin
            // a needed package needs old package -> can no be broken
            exit;
          end else begin
            // an unneeded package needs old package -> can be broken
          end;
        end else begin
          // an other thing (e.g. a project) needs old package -> can not be broken
          exit;
        end;
      end;
      Dependency:=Dependency.NextUsedByDependency;
    end;
  end;
  Result:=true;
end;

procedure TLazPackageGraph.RegisterStaticPackages;
begin
  BeginUpdate(true);
  // IDE built-in packages
  RegisterStaticPackage(FCLPackage,@RegisterFCL.Register);
  RegisterStaticPackage(LCLPackage,@RegisterLCL.Register);
  RegisterStaticPackage(SynEditPackage,@RegisterSynEdit.Register);

  // custom IDE components
  RegistrationPackage:=DefaultPackage;
  ComponentReg.RegisterCustomIDEComponents(@RegisterCustomIDEComponent);
  if DefaultPackage.FileCount=0 then begin
    FreeThenNil(FDefaultPackage);
  end else begin
    DefaultPackage.Name:=CreateUniquePkgName('DefaultPackage',DefaultPackage);
    AddPackage(DefaultPackage);
  end;
  RegistrationPackage:=nil;

  // installed packages
  // ToDo

  EndUpdate;
end;

procedure TLazPackageGraph.RegisterStaticPackage(APackage: TLazPackage;
  RegisterProc: TRegisterProc);
begin
  RegistrationPackage:=APackage;
  RegisterProc();
  APackage.Registered:=true;
  RegistrationPackage:=nil;
end;

procedure TLazPackageGraph.RegisterDefaultPackageComponent(const Page,
  UnitName: ShortString; ComponentClass: TComponentClass);
var
  PkgFile: TPkgFile;
  NewPkgFilename: String;
begin
  PkgFile:=FDefaultPackage.FindUnit(UnitName,true);
  if PkgFile=nil then begin
    NewPkgFilename:=UnitName+'.pas';
    PkgFile:=FDefaultPackage.AddFile(NewPkgFilename,UnitName,pftUnit,[],
                                     cpOptional);
  end;
  FRegistrationFile:=PkgFile;
  RegisterComponentsHandler(Page,[ComponentClass]);
end;

procedure TLazPackageGraph.AddDependencyToPackage(APackage: TLazPackage;
  Dependency: TPkgDependency);
var
  RequiredPackage: TLazPackage;
begin
  BeginUpdate(true);
  APackage.AddRequiredDependency(Dependency);
  Dependency.LoadPackageResult:=lprUndefined;
  OpenDependency(Dependency,RequiredPackage);
  EndUpdate;
end;

procedure TLazPackageGraph.RemoveDependencyFromPackage(APackage: TLazPackage;
  Dependency: TPkgDependency; AddToRemovedList: boolean);
begin
  BeginUpdate(true);
  if AddToRemovedList then
    APackage.RemoveRequiredDependency(Dependency)
  else
    APackage.DeleteRequiredDependency(Dependency);
  EndUpdate;
end;

procedure TLazPackageGraph.ChangeDependency(Dependency,
  NewDependency: TPkgDependency);
var
  RequiredPackage: TLazPackage;
begin
  if Dependency.Compare(NewDependency)=0 then exit;
  BeginUpdate(true);
  Dependency.Assign(NewDependency);
  Dependency.LoadPackageResult:=lprUndefined;
  OpenDependency(Dependency,RequiredPackage);
  DoDependencyChanged(Dependency);
  EndUpdate;
end;

function TLazPackageGraph.OpenDependency(Dependency: TPkgDependency;
  var APackage: TLazPackage): TLoadPackageResult;
var
  ANode: TAVLTreeNode;
  PkgLink: TPackageLink;
begin
  if Dependency.LoadPackageResult=lprUndefined then begin
    BeginUpdate(false);
    // search compatible package in opened packages
    ANode:=FindNodeOfDependency(Dependency,fpfSearchPackageEverywhere);
    if (ANode<>nil) then begin
      Dependency.RequiredPackage:=TLazPackage(ANode.Data);
      Dependency.LoadPackageResult:=lprSuccess;
    end;
    if Dependency.LoadPackageResult=lprUndefined then begin
      // compatible package not yet open
      Dependency.RequiredPackage:=nil;
      Dependency.LoadPackageResult:=lprNotFound;
      if FindAPackageWithName(Dependency.PackageName,nil)=nil then begin
        // no package with same name open
        // -> try package links
        repeat
          PkgLink:=PkgLinks.FindLinkWithDependency(Dependency);
          if (PkgLink=nil) then break;
          if OpenDependencyWithPackageLink(Dependency,PkgLink) then break;
          PkgLinks.RemoveLink(PkgLink);
        until false;
      end else begin
        // there is already a package with this name open
      end;
    end;
    fChanged:=true;
    EndUpdate;
  end;
  APackage:=Dependency.RequiredPackage;
  Result:=Dependency.LoadPackageResult;
end;

procedure TLazPackageGraph.OpenRequiredDependencyList(
  FirstDependency: TPkgDependency);
var
  Dependency: TPkgDependency;
  RequiredPackage: TLazPackage;
begin
  Dependency:=FirstDependency;
  while Dependency<>nil do begin
    OpenDependency(Dependency,RequiredPackage);
    Dependency:=Dependency.NextRequiresDependency;
  end;
end;

procedure TLazPackageGraph.MoveRequiredDependencyUp(
  ADependency: TPkgDependency);
begin
  if (ADependency=nil) or (ADependency.Removed) or (ADependency.Owner=nil)
  or (ADependency.PrevRequiresDependency=nil)
  or (not (ADependency.Owner is TLazPackage))
  then exit;
  BeginUpdate(true);
  TLazPackage(ADependency.Owner).MoveRequiredDependencyUp(ADependency);
  EndUpdate;
end;

procedure TLazPackageGraph.MoveRequiredDependencyDown(
  ADependency: TPkgDependency);
begin
  if (ADependency=nil) or (ADependency.Removed) or (ADependency.Owner=nil)
  or (ADependency.NextRequiresDependency=nil)
  or (not (ADependency.Owner is TLazPackage))
  then exit;
  BeginUpdate(true);
  TLazPackage(ADependency.Owner).MoveRequiredDependencyDown(ADependency);
  EndUpdate;
end;

procedure TLazPackageGraph.IterateComponentClasses(APackage: TLazPackage;
  Event: TIterateComponentClassesEvent; WithUsedPackages,
  WithRequiredPackages: boolean);
var
  ARequiredPackage: TLazPackage;
  ADependency: TPkgDependency;
begin
  APackage.IterateComponentClasses(Event,WithUsedPackages);
  // iterate through all required packages
  if WithRequiredPackages then begin
    ADependency:=APackage.FirstRequiredDependency;
    while ADependency<>nil do begin
      ARequiredPackage:=FindOpenPackage(ADependency,[fpfSearchInInstalledPckgs]);
      if ARequiredPackage<>nil then begin
        ARequiredPackage.IterateComponentClasses(Event,false);
      end;
      ADependency:=ADependency.NextRequiresDependency;
    end;
  end;
end;

procedure TLazPackageGraph.IterateAllComponentClasses(
  Event: TIterateComponentClassesEvent);
var
  Cnt: Integer;
  i: Integer;
begin
  Cnt:=Count;
  for i:=0 to Cnt-1 do
    IterateComponentClasses(Packages[i],Event,false,false);
end;

procedure TLazPackageGraph.IteratePackages(Flags: TFindPackageFlags;
  Event: TIteratePackagesEvent);
var
  CurPkg: TLazPackage;
  i: Integer;
begin
  // iterate opened packages
  for i:=0 to FItems.Count-1 do begin
    CurPkg:=Packages[i];
    // check installed packages
    if ((fpfSearchInInstalledPckgs in Flags) and (CurPkg.Installed<>pitNope))
    // check autoinstall packages
    or ((fpfSearchInAutoInstallPckgs in Flags) and (CurPkg.AutoInstall<>pitNope))
    // check packages with opened editor
    or ((fpfSearchInPckgsWithEditor in Flags) and (CurPkg.Editor<>nil))
    then
      Event(CurPkg);
  end;
  // iterate in package links
  if (fpfSearchInPkgLinks in Flags) then begin
    PkgLinks.IteratePackages(Event);
  end;
end;

procedure TLazPackageGraph.IteratePackagesSorted(Flags: TFindPackageFlags;
  Event: TIteratePackagesEvent);
var
  ANode: TAVLTreeNode;
  CurPkg: TLazPackage;
begin
  ANode:=FTree.FindLowest;
  while ANode<>nil do begin
    CurPkg:=TLazPackage(ANode.Data);
    // check installed packages
    if ((fpfSearchInInstalledPckgs in Flags) and (CurPkg.Installed<>pitNope))
    // check autoinstall packages
    or ((fpfSearchInAutoInstallPckgs in Flags) and (CurPkg.AutoInstall<>pitNope))
    // check packages with opened editor
    or ((fpfSearchInPckgsWithEditor in Flags) and (CurPkg.Editor<>nil))
    then
      Event(CurPkg);
    ANode:=FTree.FindSuccessor(ANode);
  end;
end;

procedure TLazPackageGraph.GetAllRequiredPackages(
  FirstDependency: TPkgDependency; var List: TList);
var
  Pkg: TLazPackage;
  PkgStack: PLazPackage;
  StackPtr: Integer;

  procedure PutPackagesFromDependencyListOnStack(CurDependency: TPkgDependency);
  var
    RequiredPackage: TLazPackage;
  begin
    while CurDependency<>nil do begin
      if CurDependency.LoadPackageResult=lprSuccess then begin
        RequiredPackage:=CurDependency.RequiredPackage;
        if (not (lpfVisited in RequiredPackage.Flags)) then begin
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfVisited];
          PkgStack[StackPtr]:=RequiredPackage;
          inc(StackPtr);
          // add package to list
          if List=nil then List:=TList.Create;
          List.Add(RequiredPackage);
        end;
      end;
      CurDependency:=CurDependency.NextRequiresDependency;
    end;
  end;

begin
  // initialize
  MarkAllPackagesAsNotVisited;
  // create stack
  GetMem(PkgStack,SizeOf(Pointer)*Count);
  StackPtr:=0;
  // put dependency list on stack
  PutPackagesFromDependencyListOnStack(FirstDependency);
  // mark all required packages
  while StackPtr>0 do begin
    // get required package from stack
    dec(StackPtr);
    Pkg:=PkgStack[StackPtr];
    // put all required packages on stack
    PutPackagesFromDependencyListOnStack(Pkg.FirstRequiredDependency);
  end;
  // clean up
  FreeMem(PkgStack);
end;

initialization
  PackageGraph:=nil;

end.

