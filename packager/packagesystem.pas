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
  Classes, SysUtils, OldAvLTree, Laz_XMLCfg, FileUtil, LCLProc, Forms, Controls,
  Dialogs, LazarusIDEStrConsts, IDEProcs, LazConf, CompilerOptions,
  PackageLinks, PackageDefs, LazarusPackageIntf, ComponentReg, RegisterFCL,
  RegisterLCL, RegisterSynEdit, RegisterIDEIntf;
  
type
  TFindPackageFlag = (
    fpfSearchInInstalledPckgs,
    fpfSearchInAutoInstallPckgs,
    fpfSearchInPckgsWithEditor,
    fpfSearchInLoadedPkgs,
    fpfSearchInPkgLinks,
    fpfPkgLinkMustExist,  // check if .pkg file exists
    fpfIgnoreVersion
    );
  TFindPackageFlags = set of TFindPackageFlag;
  
const
  fpfSearchEverywhere =
    [fpfSearchInInstalledPckgs,fpfSearchInAutoInstallPckgs,
     fpfSearchInPckgsWithEditor,fpfSearchInPkgLinks,fpfSearchInLoadedPkgs];
  fpfSearchAllExisting = fpfSearchEverywhere+[fpfPkgLinkMustExist];

type
  TPkgAddedEvent = procedure(APackage: TLazPackage) of object;
  TPkgDeleteEvent = procedure(APackage: TLazPackage) of object;
  TDependencyModifiedEvent = procedure(ADependency: TPkgDependency) of object;
  TEndUpdateEvent = procedure(Sender: TObject; GraphChanged: boolean) of object;
  TFindFPCUnitEvent = procedure(const UnitName, Directory: string;
                                var Filename: string) of object;

  TLazPackageGraph = class
  private
    FAbortRegistration: boolean;
    fChanged: boolean;
    FDefaultPackage: TLazPackage;
    FErrorMsg: string;
    FFCLPackage: TLazPackage;
    FIDEIntfPackage: TLazPackage;
    FItems: TList;   // unsorted list of TLazPackage
    FLazarusBasePackages: TList;
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
    function CreateIDEIntfPackage: TLazPackage;
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
    function FindBrokenDependencyPath(APackage: TLazPackage;
                                      FirstDependency: TPkgDependency): TList;
    function FindAllBrokenDependencies(APackage: TLazPackage;
                                        FirstDependency: TPkgDependency): TList;
    function FindCircleDependencyPath(APackage: TLazPackage;
                                      FirstDependency: TPkgDependency): TList;
    function FindUnsavedDependencyPath(APackage: TLazPackage;
                                       FirstDependency: TPkgDependency): TList;
    function FindNotInstalledRegisterUnits(APackage: TLazPackage;
                                        FirstDependency: TPkgDependency): TList;
    function FindAutoInstallDependencyPath(ChildPackage: TLazPackage): TList;
    function FindAmbigiousUnits(APackage: TLazPackage;
                                FirstDependency: TPkgDependency;
                                var File1, File2: TPkgFile;
                                var ConflictPkg: TLazPackage): boolean;
    function FindFPCConflictUnit(APackage: TLazPackage;
                                FirstDependency: TPkgDependency;
                                const Directory: string;
                                OnFindFPCUnit: TFindFPCUnitEvent;
                                var File1: TPkgFile;
                                var ConflictPkg: TLazPackage): boolean;
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
    function PackageCanBeReplaced(OldPackage, NewPackage: TLazPackage): boolean;
    function PackageIsNeeded(APackage: TLazPackage): boolean;
    function PackageNameExists(const PkgName: string;
                               IgnorePackage: TLazPackage): boolean;
    procedure GetAllRequiredPackages(FirstDependency: TPkgDependency;
                                     var List: TList);
    procedure GetConnectionsTree(FirstDependency: TPkgDependency;
                                 var PkgList: TList; var Tree: TPkgPairTree);
    function GetAutoCompilationOrder(APackage: TLazPackage;
                                     FirstDependency: TPkgDependency;
                                     Policies: TPackageUpdatePolicies): TList;
    function GetBrokenDependenciesWhenChangingPkgID(APackage: TLazPackage;
                         const NewName: string; NewVersion: TPkgVersion): TList;
    procedure IterateAllComponentClasses(Event: TIterateComponentClassesEvent);
    procedure IterateComponentClasses(APackage: TLazPackage;
                               Event: TIterateComponentClassesEvent;
                               WithUsedPackages, WithRequiredPackages: boolean);
    procedure IteratePackages(Flags: TFindPackageFlags;
                              Event: TIteratePackagesEvent);
    procedure IteratePackagesSorted(Flags: TFindPackageFlags;
                                    Event: TIteratePackagesEvent);
    procedure MarkAllPackagesAsNotVisited;
    procedure MarkAllRequiredPackages(FirstDependency: TPkgDependency);
    procedure MarkNeededPackages;
    procedure ConsistencyCheck;
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
    procedure RegisterStaticBasePackages;
    procedure RegisterStaticPackage(APackage: TLazPackage;
                                    RegisterProc: TRegisterProc);
    procedure RegisterDefaultPackageComponent(const Page, UnitName: ShortString;
                                              ComponentClass: TComponentClass);
    procedure CallRegisterProc(RegisterProc: TRegisterProc);
  public
    // dependency handling
    procedure AddDependencyToPackage(APackage: TLazPackage;
                                     Dependency: TPkgDependency);
    procedure AddDependencyToPackage(APackage, RequiredPackage: TLazPackage);
    procedure RemoveDependencyFromPackage(APackage: TLazPackage;
                         Dependency: TPkgDependency; AddToRemovedList: boolean);
    procedure ChangeDependency(Dependency, NewDependency: TPkgDependency);
    function OpenDependency(Dependency: TPkgDependency): TLoadPackageResult;
    procedure OpenInstalledDependency(Dependency: TPkgDependency;
                                      InstallType: TPackageInstallType);
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
    property IDEIntfPackage: TLazPackage read FIDEIntfPackage;
    property LazarusBasePackages: TList read FLazarusBasePackages;
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
  LazarusPackageIntf.RegisterUnitProc:=@RegisterUnitHandler;
  RegisterComponentsProc:=@RegisterComponentsGlobalHandler;
  RegisterNoIconProc:=@RegisterNoIconGlobalHandler;
end;

procedure TLazPackageGraph.UpdateBrokenDependenciesToPackage(
  APackage: TLazPackage);
var
  ANode: TAVLTreeNode;
  Dependency: TPkgDependency;
begin
  BeginUpdate(false);
  ANode:=FindLowestPkgDependencyNodeWithName(APackage.Name);
  while ANode<>nil do begin
    Dependency:=TPkgDependency(ANode.Data);
    if (Dependency.LoadPackageResult<>lprSuccess)
    and Dependency.IsCompatible(APackage) then begin
      Dependency.LoadPackageResult:=lprUndefined;
      OpenDependency(Dependency);
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
  NewPackage:=nil;
  BeginUpdate(false);
  try
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
        DebugLn('unable to read file "'+AFilename+'" ',E.Message);
        exit;
      end;
    end;
    if not NewPackage.MakeSense then exit;
    if PkgLink.Compare(NewPackage)<>0 then exit;
    // ok
    Result:=true;
    AddPackage(NewPackage);
  finally
    if not Result then
      NewPackage.Free;
    EndUpdate;
  end;
end;

constructor TLazPackageGraph.Create;
begin
  OnGetAllRequiredPackages:=@GetAllRequiredPackages;
  FTree:=TAVLTree.Create(@CompareLazPackageID);
  FItems:=TList.Create;
  FLazarusBasePackages:=TList.Create;
end;

destructor TLazPackageGraph.Destroy;
begin
  if LazarusPackageIntf.RegisterUnitProc=@RegisterUnitHandler then
    LazarusPackageIntf.RegisterUnitProc:=nil;
  if RegisterComponentsProc=@RegisterComponentsGlobalHandler then
    RegisterComponentsProc:=nil;
  if RegisterNoIconProc=@RegisterNoIconGlobalHandler then
    RegisterNoIconProc:=nil;
  if OnGetAllRequiredPackages=@GetAllRequiredPackages then
    OnGetAllRequiredPackages:=nil;
  Clear;
  FLazarusBasePackages.Free;
  FItems.Free;
  FTree.Free;
  inherited Destroy;
end;

procedure TLazPackageGraph.Clear;
var
  i: Integer;
begin
  FLazarusBasePackages.Clear;
  for i:=FItems.Count-1 downto 0 do Delete(i);
end;

procedure TLazPackageGraph.Delete(Index: integer);
var
  CurPkg: TLazPackage;
begin
  BeginUpdate(true);
  CurPkg:=Packages[Index];
  CurPkg.Flags:=CurPkg.Flags+[lpfDestroying];
  CurPkg.DefineTemplates.Active:=false;
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
  Result.Name:=CreateUniquePkgName(lisPkgMangNewPackage, nil);
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
      RegistrationError(Format(lisPkgSysInvalidUnitname, [FRegistrationUnitName]
        ));
      exit;
    end;
    // check unit file
    FRegistrationFile:=FRegistrationPackage.FindUnit(FRegistrationUnitName,true);
    if FRegistrationFile=nil then begin
      FRegistrationFile:=
        FRegistrationPackage.FindUnit(FRegistrationUnitName,false);
      if FRegistrationFile=nil then begin
        RegistrationError(Format(lisPkgSysUnitNotFound, ['"',
          FRegistrationUnitName, '"']));
      end else begin
        if not (pffReportedAsRemoved in FRegistrationFile.Flags) then begin
          RegistrationError(
            Format(lisPkgSysUnitWasRemovedFromPackage, ['"',
              FRegistrationUnitName, '"']));
          FRegistrationFile.Flags:=
                                 FRegistrationFile.Flags+[pffReportedAsRemoved];
        end;
      end;
      exit;
    end;
    CallRegisterProc(RegisterProc);
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
    RegistrationError(lisPkgSysCanNotRegisterComponentsWithoutUnit);
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
        RegistrationError(lisPkgSysInvalidComponentClass);
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
        Format(lisPkgSysComponentClassAlreadyDefined, ['"',
          CurComponent.ClassName, '"']));
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
    ErrorMsg:=lisPkgSysRegisterUnitWasCalledButNoPackageIsRegistering;
  end else begin
    ErrorMsg:='Package: "'+FRegistrationPackage.IDAsString+'"';
    // current unitname
    if FRegistrationUnitName<>'' then
      ErrorMsg:=Format(lisPkgSysUnitName, [ErrorMsg, #13, '"',
        FRegistrationUnitName, '"']);
    // current file
    if FRegistrationFile<>nil then
      ErrorMsg:=Format(lisPkgSysFileName, [ErrorMsg, #13, '"',
        FRegistrationFile.Filename, '"']);
  end;
  // append message
  if Msg<>'' then
    ErrorMsg:=ErrorMsg+#13#13+Msg;
  // tell user
  DlgResult:=MessageDlg(lisPkgSysRegistrationError,
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
    Filename:=SetDirSeparators('$(FPCSrcDir)/fcl/');
    Version.SetValues(1,0,0,0);
    Author:='FPC team';
    License:='LGPL-2';
    AutoInstall:=pitStatic;
    AutoUpdate:=pupManually;
    Description:=lisPkgSysTheFCLFreePascalComponentLibraryProvidesTheBase;
    PackageType:=lptDesignTime;
    Installed:=pitStatic;
    CompilerOptions.UnitOutputDirectory:='';
    
    // add lazarus registration unit path
    UsageOptions.UnitPath:=SetDirSeparators(
      '$(LazarusDir)/packager/units/$(TargetCPU)/$(TargetOS)');

    // add registering units
    AddFile(SetDirSeparators('db/db.pp'),'DB',pftUnit,
            [pffHasRegisterProc],cpBase);
    AddFile(SetDirSeparators('inc/process.pp'),'Process',pftUnit,
            [pffHasRegisterProc],cpBase);

    // use the packager/units/lazaruspackageintf.o file as indicator,
    // if FCL has been recompiled
    OutputStateFile:=SetDirSeparators(
      '$(LazarusDir)/packager/units/$(TargetCPU)/$(TargetOS)/lazaruspackageintf.o');

    Modified:=false;
  end;
end;

function TLazPackageGraph.CreateLCLPackage: TLazPackage;

  procedure AddLCLLinkPaths(UsageOptions: TAdditionalCompilerOptions);
  var
    NewPath: string;
    OldLibPath: String;
  begin
    NewPath:=GetDefaultLCLLibPaths('','',';');
    OldLibPath:=UsageOptions.LibraryPath;
    if OldLibPath<>'' then OldLibPath:=OldLibPath+';';
    OldLibPath:=OldLibPath+NewPath;
    UsageOptions.LibraryPath:=NewPath;
  end;

var
  i: Integer;
begin
  Result:=TLazPackage.Create;
  with Result do begin
    AutoCreated:=true;
    Name:='LCL';
    Filename:=SetDirSeparators('$(LazarusDir)/lcl/');
    Version.SetValues(1,0,0,0);
    Author:='Lazarus';
    License:='LGPL-2';
    AutoInstall:=pitStatic;
    AutoUpdate:=pupManually;
    Description:=lisPkgSysTheLCLLazarusComponentLibraryContainsAllBase;
    PackageType:=lptDesignTime;
    Installed:=pitStatic;
    CompilerOptions.UnitOutputDirectory:='';

    // add requirements
    AddRequiredDependency(FCLPackage.CreateDependencyForThisPkg(Result));

    // add registering units
    AddFile('menus.pp','Menus',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('buttons.pp','Buttons',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('stdctrls.pp','StdCtrls',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('extctrls.pp','ExtCtrls',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('comctrls.pp','ComCtrls',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('maskedit.pp','MaskEdit',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('checklst.pas','CheckLst',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('forms.pp','Forms',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('graphics.pp','Graphics',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('grids.pas','Grids',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('controls.pp','Controls',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('dialogs.pp','Dialogs',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('spin.pp','Spin',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('arrow.pp','Arrow',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('calendar.pp','Calendar',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('pairsplitter.pas','PairSplitter',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('extdlgs.pas','ExtDlgs',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('dbctrls.pp','DBCtrls',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('dbgrids.pas','DBGrids',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('editbtn.pas','EditBtn',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('actnlist.pas','ActnList',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('filectrl.pas','FileCtrl',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('xmlpropstorage.pas','XMLPropStorage',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('inipropstorage.pas','IniPropStorage',pftUnit,[pffHasRegisterProc],cpBase);
    AddFile('chart.pp','Chart',pftUnit,[pffHasRegisterProc],cpBase);
    // increase priority by one, so that the LCL components are inserted to the
    // left in the palette
    for i:=0 to FileCount-1 do
      inc(Files[i].ComponentPriority.Level);

    // add unit paths
    UsageOptions.UnitPath:=SetDirSeparators(
       '$(LazarusDir)/lcl/units/$(TargetCPU)/$(TargetOS);'
      +'$(LazarusDir)/lcl/units/$(TargetCPU)/$(TargetOS)/$(LCLWidgetType)');
    UsageOptions.CustomOptions:='-dLCL';
    // add include path
    CompilerOptions.IncludeFiles:=SetDirSeparators(
      '$(LazarusDir)/lcl/include;$(LazarusDir)/lcl/interfaces/$(LCLWidgetType)');
    AddLCLLinkPaths(UsageOptions);

    // use the lcl/units/$(TargetCPU)/$(TargetOS)/alllclunits.o
    // file as indicator, if LCL has been recompiled
    OutputStateFile:=SetDirSeparators(
      '$(LazarusDir)/lcl/units/$(TargetCPU)/$(TargetOS)/alllclunits.o');

    Modified:=false;
  end;
end;

function TLazPackageGraph.CreateSynEditPackage: TLazPackage;
begin
  Result:=TLazPackage.Create;
  with Result do begin
    AutoCreated:=true;
    Name:='SynEdit';
    Filename:=SetDirSeparators('$(LazarusDir)/components/synedit/');
    Version.SetValues(1,0,0,0);
    Author:='SynEdit - http://sourceforge.net/projects/synedit/';
    License:='LGPL-2';
    AutoInstall:=pitStatic;
    AutoUpdate:=pupManually;
    Description:=lisPkgSysSynEditTheEditorComponentUsedByLazarus;
    PackageType:=lptDesignTime;
    Installed:=pitStatic;
    CompilerOptions.UnitOutputDirectory:='';

    // add requirements
    AddRequiredDependency(LCLPackage.CreateDependencyForThisPkg(Result));

    // add units
    AddFile('synedit.pp','SynEdit',pftUnit,[],cpBase);
    AddFile('syneditlazdsgn.pas','SynEditLazDsgn',pftUnit,[],cpBase);
    AddFile('syncompletion.pas','SynCompletion',pftUnit,[],cpBase);
    AddFile('synexporthtml.pas','SynExportHTML',pftUnit,[],cpBase);
    AddFile('synmacrorecorder.pas','SynMacroRecorder',pftUnit,[],cpBase);
    AddFile('synmemo.pas','SynMemo',pftUnit,[],cpBase);
    AddFile('synhighlighterpas.pp','SynHighlighterPas',pftUnit,[],cpBase);
    AddFile('synhighlightercpp.pp','SynHighlighterCPP',pftUnit,[],cpBase);
    AddFile('synhighlighterjava.pas','SynHighlighterJava',pftUnit,[],cpBase);
    AddFile('synhighlighterperl.pas','SynHighlighterPerl',pftUnit,[],cpBase);
    AddFile('synhighlighterhtml.pp','SynHighlighterHTML',pftUnit,[],cpBase);
    AddFile('synhighlighterxml.pas','SynHighlighterXML',pftUnit,[],cpBase);
    AddFile('synhighlighterlfm.pas','SynHighlighterLFM',pftUnit,[],cpBase);
    AddFile('synhighlighterunixshellscript.pas','SynHighlighterUNIXShellScript',
                                                             pftUnit,[],cpBase);
    AddFile('synhighlightermulti.pas','SynHighlighterMulti',pftUnit,[],cpBase);
    AddFile('synhighlightercss.pas','SynHighlighterCss',pftUnit,[],cpBase);
    AddFile('synhighlighterphp.pas','SynHighlighterPHP',pftUnit,[],cpBase);
    AddFile('synhighlightertex.pas','SynHighlighterTeX',pftUnit,[],cpBase);
    AddFile('synhighlightersql.pas','SynHighlighterSQL',pftUnit,[],cpBase);
    AddFile('synhighlighterpython.pas','SynHighlighterPython',pftUnit,[],cpBase);

    // add unit paths
    UsageOptions.UnitPath:=SetDirSeparators(
                     '$(LazarusDir)/components/units/$(TargetCPU)/$(TargetOS)');

    // use the components/units/..../allsyneditunits.o file as indicator,
    // if synedit has been recompiled
    OutputStateFile:=SetDirSeparators(
      '$(LazarusDir)/components/units/$(TargetCPU)/$(TargetOS)/allsyneditunits.o');

    Modified:=false;
  end;
end;

function TLazPackageGraph.CreateIDEIntfPackage: TLazPackage;
begin
  Result:=TLazPackage.Create;
  with Result do begin
    AutoCreated:=true;
    Name:='IDEIntf';
    Filename:=SetDirSeparators('$(LazarusDir)/ideintf/');
    Version.SetValues(1,0,0,0);
    Author:='Lazarus';
    License:='GPL-2';
    AutoInstall:=pitStatic;
    AutoUpdate:=pupManually;
    Description:='IDEIntf - the interface units for the IDE';
    PackageType:=lptDesignTime;
    Installed:=pitStatic;
    CompilerOptions.UnitOutputDirectory:='';

    // add requirements
    AddRequiredDependency(LCLPackage.CreateDependencyForThisPkg(Result));

    // add units
    AddFile('actionseditor.pas','ActionsEditor',pftUnit,[],cpBase);
    AddFile('columndlg.pp','ColumnDlg',pftUnit,[],cpBase);
    AddFile('componenteditors.pas','ComponentEditors',pftUnit,[],cpBase);
    AddFile('componentreg.pas','ComponentReg',pftUnit,[],cpBase);
    AddFile('componenttreeview.pas','ComponentTreeview',pftUnit,[],cpBase);
    AddFile('formeditingintf.pas','FormEditingIntf',pftUnit,[],cpBase);
    AddFile('graphpropedits.pas','GraphPropEdits',pftUnit,[],cpBase);
    AddFile('idecommands.pas','IDECommands',pftUnit,[],cpBase);
    AddFile('imagelisteditor.pp','ImageListEditor',pftUnit,[],cpBase);
    AddFile('listviewpropedit.pp','ListViewPropEdit',pftUnit,[],cpBase);
    AddFile('objectinspector.pp','ObjectInspector',pftUnit,[],cpBase);
    AddFile('objinspstrconsts.pas','ObjInspStrConsts',pftUnit,[],cpBase);
    AddFile('packageintf.pas','PackageIntf',pftUnit,[],cpBase);
    AddFile('propedits.pp','PropEdits',pftUnit,[],cpBase);
    AddFile('srceditorintf.pas','SrcEditorIntf',pftUnit,[],cpBase);
    AddFile('texttools.pas','TextTools',pftUnit,[],cpBase);

    // add unit paths
    UsageOptions.UnitPath:=SetDirSeparators(
      '$(LazarusDir)/ideintf/units/$(TargetCPU)/$(TargetOS)'
      +';$(LazarusDir)/components/units/$(TargetCPU)/$(TargetOS)');

    // use the ideintf/units/$(TargetCPU)/$(TargetOS)/allideintf.o file
    // as indicator, if ideintf has been recompiled
    OutputStateFile:=SetDirSeparators(
      '$(LazarusDir)/ideintf/units/$(TargetCPU)/$(TargetOS)/allideintf.o');

    Modified:=false;
  end;
end;

function TLazPackageGraph.CreateDefaultPackage: TLazPackage;
begin
  Result:=TLazPackage.Create;
  with Result do begin
    AutoCreated:=true;
    Name:='DefaultPackage';
    Filename:=SetDirSeparators('$(LazarusDir)/components/custom/');
    Version.SetValues(1,0,1,1);
    Author:='Anonymous';
    AutoInstall:=pitStatic;
    AutoUpdate:=pupManually;
    Description:=lisPkgSysThisIsTheDefaultPackageUsedOnlyForComponents;
    PackageType:=lptDesignTime;
    Installed:=pitStatic;
    CompilerOptions.UnitOutputDirectory:='';

    // add unit paths
    UsageOptions.UnitPath:=SetDirSeparators('$(LazarusDir)/components/custom');

    // add requirements
    AddRequiredDependency(LCLPackage.CreateDependencyForThisPkg(Result));
    AddRequiredDependency(SynEditPackage.CreateDependencyForThisPkg(Result));

    Modified:=false;
  end;
end;

procedure TLazPackageGraph.AddPackage(APackage: TLazPackage);
var
  Dependency: TPkgDependency;
begin
  BeginUpdate(true);
  FTree.Add(APackage);
  FItems.Add(APackage);

  // open all required dependencies
  Dependency:=APackage.FirstRequiredDependency;
  while Dependency<>nil do begin
    OpenDependency(Dependency);
    Dependency:=Dependency.NextRequiresDependency;
  end;
  
  // update all missing dependencies
  UpdateBrokenDependenciesToPackage(APackage);
  
  // activate define templates
  APackage.DefineTemplates.Active:=true;

  if Assigned(OnAddPackage) then OnAddPackage(APackage);
  EndUpdate;
end;

procedure TLazPackageGraph.ReplacePackage(OldPackage, NewPackage: TLazPackage);

  procedure MoveInstalledComponents(OldPkgFile: TPkgFile);
  var
    NewPkgFile: TPkgFile;
    OldUnitName: String;
    PkgComponent: TPkgComponent;
  begin
    if (OldPkgFile.ComponentCount>0) then begin
      OldUnitName:=OldPkgFile.UnitName;
      if OldUnitName='' then RaiseException('MoveInstalledComponents');
      NewPkgFile:=NewPackage.FindUnit(OldUnitName,false);
      if NewPkgFile=nil then begin
        NewPkgFile:=NewPackage.AddRemovedFile(OldPkgFile.Filename,OldUnitName,
                                        OldPkgFile.FileType,OldPkgFile.Flags,
                                        OldPkgFile.ComponentPriority.Category);
      end;
      while OldPkgFile.ComponentCount>0 do begin
        PkgComponent:=OldPkgFile.Components[0];
        PkgComponent.PkgFile:=NewPkgFile;
      end;
    end;
  end;

var
  OldInstalled: TPackageInstallType;
  OldAutoInstall: TPackageInstallType;
  OldEditor: TBasePackageEditor;
  i: Integer;
begin
  BeginUpdate(true);
  // save flags
  OldInstalled:=OldPackage.Installed;
  OldAutoInstall:=OldPackage.AutoInstall;
  OldEditor:=OldPackage.Editor;
  if OldEditor<>nil then begin
    OldEditor.LazPackage:=nil;
  end;
  // migrate components
  for i:=0 to OldPackage.FileCount-1 do
    MoveInstalledComponents(OldPackage.Files[i]);
  for i:=0 to OldPackage.RemovedFilesCount-1 do
    MoveInstalledComponents(OldPackage.RemovedFiles[i]);
  // delete old package
  Delete(fItems.IndexOf(OldPackage));
  // restore flags
  NewPackage.Installed:=OldInstalled;
  NewPackage.AutoInstall:=OldAutoInstall;
  // add package to graph
  AddPackage(NewPackage);
  if OldEditor<>nil then begin
    OldEditor.LazPackage:=NewPackage;
  end;
  EndUpdate;
end;

procedure TLazPackageGraph.AddStaticBasePackages;

  procedure AddStaticBasePackage(NewPackage: TLazPackage;
    var PackageVariable: TLazPackage);
  begin
    PackageVariable:=NewPackage;
    AddPackage(NewPackage);
    FLazarusBasePackages.Add(NewPackage);
  end;

begin
  AddStaticBasePackage(CreateFCLPackage,FFCLPackage);
  AddStaticBasePackage(CreateLCLPackage,FLCLPackage);
  AddStaticBasePackage(CreateSynEditPackage,FSynEditPackage);
  AddStaticBasePackage(CreateIDEIntfPackage,FIDEIntfPackage);
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

function TLazPackageGraph.FindBrokenDependencyPath(APackage: TLazPackage;
  FirstDependency: TPkgDependency): TList;
// returns the first broken dependency
// the first irems are TLazPackage, the last item is a TPkgDependency
  
  procedure FindBroken(Dependency: TPkgDependency; var PathList: TList);
  var
    RequiredPackage: TLazPackage;
  begin
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        // dependency ok
        RequiredPackage:=Dependency.RequiredPackage;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfVisited];
          FindBroken(RequiredPackage.FirstRequiredDependency,PathList);
          if PathList<>nil then begin
            // broken dependency found
            // -> add current package to list
            PathList.Insert(0,RequiredPackage);
            exit;
          end;
        end;
      end else begin
        // broken dependency found
        PathList:=TList.Create;
        PathList.Add(Dependency);
        exit;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;
  
begin
  Result:=nil;
  if (Count=0) then exit;
  MarkAllPackagesAsNotVisited;
  if APackage<>nil then begin
    APackage.Flags:=APackage.Flags+[lpfVisited];
    FirstDependency:=APackage.FirstRequiredDependency;
  end;
  FindBroken(FirstDependency,Result);
  if (Result<>nil) and (APackage<>nil) then
    Result.Insert(0,APackage);
end;

function TLazPackageGraph.FindAllBrokenDependencies(APackage: TLazPackage;
  FirstDependency: TPkgDependency): TList;
// returns the list of broken dependencies (TPkgDependency)

  procedure FindBroken(Dependency: TPkgDependency; var DepList: TList);
  var
    RequiredPackage: TLazPackage;
  begin
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        // dependency ok
        RequiredPackage:=Dependency.RequiredPackage;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfVisited];
          FindBroken(RequiredPackage.FirstRequiredDependency,DepList);
        end;
      end else begin
        // broken dependency found
        if (DepList=nil) or (DepList.IndexOf(Dependency)<0) then begin
          if DepList=nil then
            DepList:=TList.Create;
          DepList.Add(Dependency);
        end;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;

begin
  Result:=nil;
  if (Count=0) then exit;
  MarkAllPackagesAsNotVisited;
  if APackage<>nil then begin
    APackage.Flags:=APackage.Flags+[lpfVisited];
    FirstDependency:=APackage.FirstRequiredDependency;
  end;
  FindBroken(FirstDependency,Result);
end;

function TLazPackageGraph.FindCircleDependencyPath(APackage: TLazPackage;
  FirstDependency: TPkgDependency): TList;

  procedure FindCircle(Dependency: TPkgDependency; var PathList: TList);
  var
    RequiredPackage: TLazPackage;
  begin
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        // dependency ok
        RequiredPackage:=Dependency.RequiredPackage;
        if lpfCircle in RequiredPackage.Flags then begin
          // circle detected
          PathList:=TList.Create;
          PathList.Add(RequiredPackage);
          exit;
        end;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfVisited,lpfCircle];
          FindCircle(RequiredPackage.FirstRequiredDependency,PathList);
          if PathList<>nil then begin
            // circle detected
            // -> add current package to list
            PathList.Insert(0,RequiredPackage);
            exit;
          end;
          RequiredPackage.Flags:=RequiredPackage.Flags-[lpfCircle];
        end;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;

var
  i: Integer;
  Pkg: TLazPackage;
begin
  Result:=nil;
  if (Count=0) then exit;
  // mark all packages as not visited and circle free
  for i:=FItems.Count-1 downto 0 do begin
    Pkg:=TLazPackage(FItems[i]);
    Pkg.Flags:=Pkg.Flags-[lpfVisited,lpfCircle];
  end;
  if APackage<>nil then begin
    APackage.Flags:=APackage.Flags+[lpfVisited];
    FirstDependency:=APackage.FirstRequiredDependency;
  end;
  FindCircle(FirstDependency,Result);
  if (Result<>nil) and (APackage<>nil) then
    Result.Insert(0,APackage);
end;

function TLazPackageGraph.FindUnsavedDependencyPath(APackage: TLazPackage;
  FirstDependency: TPkgDependency): TList;

  procedure FindUnsaved(Dependency: TPkgDependency; var PathList: TList);
  var
    RequiredPackage: TLazPackage;
  begin
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        // dependency ok
        RequiredPackage:=Dependency.RequiredPackage;
        if RequiredPackage.Modified then begin
          // unsaved package detected
          PathList:=TList.Create;
          PathList.Add(RequiredPackage);
          exit;
        end;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfVisited];
          FindUnsaved(RequiredPackage.FirstRequiredDependency,PathList);
          if PathList<>nil then begin
            // unsaved package detected
            // -> add current package to list
            PathList.Insert(0,RequiredPackage);
            exit;
          end;
        end;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;

begin
  Result:=nil;
  if (Count=0) or (APackage=nil) then exit;
  MarkAllPackagesAsNotVisited;
  if APackage<>nil then begin
    APackage.Flags:=APackage.Flags+[lpfVisited];
    FirstDependency:=APackage.FirstRequiredDependency;
  end;
  FindUnsaved(FirstDependency,Result);
  if (Result<>nil) and (APackage<>nil) then
    Result.Insert(0,APackage);
end;

function TLazPackageGraph.FindNotInstalledRegisterUnits(
  APackage: TLazPackage; FirstDependency: TPkgDependency): TList;
// returns the list of required units (TPkgFile) with a Register procedure,
// that are not installed in the IDE

  procedure FindNotInstalledRegisterUnit(Dependency: TPkgDependency;
    var UnitList: TList);
  var
    RequiredPackage: TLazPackage;
    i: Integer;
    APkgFile: TPkgFile;
  begin
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        // dependency ok
        RequiredPackage:=Dependency.RequiredPackage;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          if RequiredPackage.Installed=pitNope then begin
            // package not installed
            for i:=0 to RequiredPackage.FileCount-1 do begin
              APkgFile:=RequiredPackage.Files[i];
              if APkgFile.HasRegisterProc then begin
                // unit with register procedure -> add
                if UnitList=nil then
                  UnitList:=TList.Create;
                UnitList.Add(APkgFile);
              end;
            end;
          end;
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfVisited];
          FindNotInstalledRegisterUnit(RequiredPackage.FirstRequiredDependency,UnitList);
        end;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;

begin
  Result:=nil;
  if (Count=0) then exit;
  MarkAllPackagesAsNotVisited;
  if APackage<>nil then begin
    APackage.Flags:=APackage.Flags+[lpfVisited];
    FirstDependency:=APackage.FirstRequiredDependency;
  end;
  FindNotInstalledRegisterUnit(FirstDependency,Result);
end;

function TLazPackageGraph.FindAutoInstallDependencyPath(
  ChildPackage: TLazPackage): TList;
  
  procedure FindAutoInstallParent(APackage: TLazPackage);
  var
    ParentPackage: TLazPackage;
    Dependency: TPkgDependency;
  begin
    Dependency:=APackage.FirstUsedByDependency;
    while Dependency<>nil do begin
      if Dependency.Owner is TLazPackage then begin
        ParentPackage:=TLazPackage(Dependency.Owner);
        if not (lpfVisited in ParentPackage.Flags) then begin
          ParentPackage.Flags:=ParentPackage.Flags+[lpfVisited];
          if ParentPackage.AutoInstall<>pitNope then begin
            // auto install parent found
            if Result=nil then Result:=TList.Create;
            Result.Add(ParentPackage);
            Result.Add(APackage);
            exit;
          end;
          FindAutoInstallParent(ParentPackage);
          if Result<>nil then begin
            // build path
            Result.Add(APackage);
            exit;
          end;
        end;
      end;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;

begin
  Result:=nil;
  MarkAllPackagesAsNotVisited;
  ChildPackage.Flags:=ChildPackage.Flags+[lpfVisited];
  FindAutoInstallParent(ChildPackage);
end;

function TLazPackageGraph.FindAmbigiousUnits(APackage: TLazPackage;
  FirstDependency: TPkgDependency; var File1, File2: TPkgFile;
  var ConflictPkg: TLazPackage): boolean;
// check if two connected packages have units with the same name
// Connected means here: a Package1 is directly required by a Package2
// or: a Package1 and a Package2 are directly required by a Package3
// returns true, if ambigious units found
// There can either be a conflict between two files (File1,File2)
// or between a file and a package (File1,ConflictPkg)
const
  FileTypes = PkgFileUnitTypes-[pftVirtualUnit];
var
  PackageTreeOfUnitTrees: TAVLTree; // tree of TPkgUnitsTree
  
  function GetUnitsTreeOfPackage(Pkg: TLazPackage): TPkgUnitsTree;
  var
    ANode: TAVLTreeNode;
    PkgFile: TPkgFile;
    i: Integer;
  begin
    // for first time: create PackageTreeOfUnitTrees
    if PackageTreeOfUnitTrees=nil then
      PackageTreeOfUnitTrees:=TAVLTree.Create(TListSortCompare(@CompareUnitsTree));
    // search UnitsTree for package
    ANode:=PackageTreeOfUnitTrees.FindKey(Pkg, TListSortCompare(@ComparePackageWithUnitsTree));
    if ANode<>nil then begin
      Result:=TPkgUnitsTree(ANode.Data);
      exit;
    end;
    // first time: create tree of units for Pkg
    Result:=TPkgUnitsTree.Create(Pkg);
    PackageTreeOfUnitTrees.Add(Result);
    for i:=0 to Pkg.FileCount-1 do begin
      PkgFile:=Pkg.Files[i];
      if (PkgFile.FileType in FileTypes) and (PkgFile.UnitName<>'') then
        Result.Add(PkgFile);
    end;
  end;
  
  function FindAmbigiousUnitsBetween2Packages(Pkg1,Pkg2: TLazPackage): boolean;
  var
    i: Integer;
    PkgFile1: TPkgFile;
    PkgFile2: TPkgFile;
    UnitsTreeOfPkg2: TPkgUnitsTree;
  begin
    Result:=false;
    if Pkg1=Pkg2 then exit;
    if (Pkg1.FileCount=0) or (Pkg2.FileCount=0) then exit;
    UnitsTreeOfPkg2:=GetUnitsTreeOfPackage(Pkg2);
    // check if a unit of Pkg2 has the same name as Pkg1
    PkgFile2:=UnitsTreeOfPkg2.FindPkgFileWithUnitName(Pkg1.Name);
    if PkgFile2<>nil then begin
      File1:=PkgFile2;
      ConflictPkg:=Pkg1;
      Result:=true;
      exit;
    end;
    for i:=0 to Pkg1.FileCount-1 do begin
      PkgFile1:=Pkg1.Files[i];
      if (PkgFile1.FileType in FileTypes)
      and (PkgFile1.UnitName<>'') then begin
        // check if a unit of Pkg1 exists in Pkg2
        PkgFile2:=UnitsTreeOfPkg2.FindPkgFileWithUnitName(PkgFile1.UnitName);
        if PkgFile2<>nil then begin
          File1:=PkgFile1;
          File2:=PkgFile2;
          Result:=true;
          exit;
        end;
        // check if a unit of Pkg1 has the same name as Pkg2
        if AnsiCompareText(PkgFile1.UnitName,Pkg2.Name)=0 then begin
          File1:=PkgFile1;
          ConflictPkg:=Pkg2;
          Result:=true;
          exit;
        end;
      end;
    end;
  end;

var
  PkgList: TList;
  ConnectionsTree: TPkgPairTree;
  ANode: TAVLTreeNode;
  Pair: TPkgPair;
begin
  Result:=false;
  if APackage<>nil then begin
    FirstDependency:=APackage.FirstRequiredDependency;
  end;
  File1:=nil;
  File2:=nil;
  ConflictPkg:=nil;
  ConnectionsTree:=nil;
  PkgList:=nil;
  PackageTreeOfUnitTrees:=nil;
  GetConnectionsTree(FirstDependency,PkgList,ConnectionsTree);
  try
    if ConnectionsTree=nil then exit;
    ANode:=ConnectionsTree.FindLowest;
    while ANode<>nil do begin
      Pair:=TPkgPair(ANode.Data);
      Result:=FindAmbigiousUnitsBetween2Packages(Pair.Package1,Pair.Package2);
      if Result then exit;
      ANode:=ConnectionsTree.FindSuccessor(ANode);
    end;
  finally
    if PackageTreeOfUnitTrees<>nil then begin
      PackageTreeOfUnitTrees.FreeAndClear;
      PackageTreeOfUnitTrees.Free;
    end;
    ConnectionsTree.Free;
    PkgList.Free;
  end;
  Result:=false;
end;

function TLazPackageGraph.FindFPCConflictUnit(APackage: TLazPackage;
  FirstDependency: TPkgDependency; const Directory: string;
  OnFindFPCUnit: TFindFPCUnitEvent;
  var File1: TPkgFile; var ConflictPkg: TLazPackage): boolean;
  
  function CheckUnitName(const AnUnitName: string): boolean;
  var Filename: string;
  begin
    Result:=false;
    if AnUnitName='' then exit;
    OnFindFPCUnit(AnUnitName,Directory,Filename);
    Result:=Filename<>'';
  end;
  
  function CheckDependencyList(ADependency: TPkgDependency): boolean; forward;

  function CheckPackage(Pkg1: TLazPackage): boolean;
  var
    Cnt: Integer;
    i: Integer;
    CurFile: TPkgFile;
  begin
    Result:=false;
    if (Pkg1=nil) or (lpfVisited in Pkg1.Flags)
    or (Pkg1=FFCLPackage) or (Pkg1=FLCLPackage) then exit;
    Pkg1.Flags:=Pkg1.Flags+[lpfVisited];
    Result:=CheckUnitName(Pkg1.Name);
    if Result then begin
      ConflictPkg:=Pkg1;
      exit;
    end;
    Cnt:=Pkg1.FileCount;
    for i:=0 to Cnt-1 do begin
      CurFile:=Pkg1.Files[i];
      if CurFile.FileType in (PkgFileUnitTypes-[pftVirtualUnit]) then begin
        Result:=CheckUnitName(CurFile.UnitName);
        if Result then begin
          File1:=CurFile;
          exit;
        end;
      end;
    end;
    Result:=CheckDependencyList(Pkg1.FirstRequiredDependency);
  end;
  
  function CheckDependencyList(ADependency: TPkgDependency): boolean;
  begin
    Result:=false;
    while ADependency<>nil do begin
      Result:=CheckPackage(ADependency.RequiredPackage);
      if Result then exit;
      ADependency:=ADependency.NextDependency[pdlRequires];
    end;
  end;

begin
  Result:=false;
  File1:=nil;
  ConflictPkg:=nil;
  MarkAllPackagesAsNotVisited;
  if APackage<>nil then
    Result:=CheckPackage(APackage)
  else
    Result:=CheckDependencyList(FirstDependency);
end;

function TLazPackageGraph.GetAutoCompilationOrder(APackage: TLazPackage;
  FirstDependency: TPkgDependency; Policies: TPackageUpdatePolicies): TList;
// Returns all required auto update packages, including indirect requirements.
// The packages will be in topological order, with the package that should be
// compiled first at the end.

  procedure GetTopologicalOrder(Dependency: TPkgDependency);
  var
    RequiredPackage: TLazPackage;
  begin
    while Dependency<>nil do begin
      if Dependency.LoadPackageResult=lprSuccess then begin
        RequiredPackage:=Dependency.RequiredPackage;
        if not (lpfVisited in RequiredPackage.Flags) then begin
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfVisited];
          if RequiredPackage.AutoUpdate in Policies then begin
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
  if APackage<>nil then begin
    APackage.Flags:=APackage.Flags+[lpfVisited];
    FirstDependency:=APackage.FirstRequiredDependency;
  end;
  GetTopologicalOrder(FirstDependency);
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

procedure TLazPackageGraph.MarkAllRequiredPackages(
  FirstDependency: TPkgDependency);
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
        MarkAllRequiredPackages(RequiredPackage.FirstRequiredDependency);
      end;
    end;
    Dependency:=Dependency.NextRequiresDependency;
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
begin
  if AnsiCompareText(OldPackage.Name,NewPackage.Name)<>0 then
    RaiseException('TLazPackageGraph.PackageCanBeReplaced');

  Result:=true;
end;

procedure TLazPackageGraph.RegisterStaticBasePackages;
begin
  BeginUpdate(true);
  
  // register IDE built-in packages
  RegisterStaticPackage(FCLPackage,@RegisterFCL.Register);
  RegisterStaticPackage(LCLPackage,@RegisterLCL.Register);
  RegisterStaticPackage(SynEditPackage,@RegisterSynEdit.Register);
  RegisterStaticPackage(IDEIntfPackage,@RegisterIDEIntf.Register);

  // register custom IDE components
  RegistrationPackage:=DefaultPackage;
  if IDEComponentPalette<>nil then
    IDEComponentPalette.RegisterCustomIDEComponents(@RegisterCustomIDEComponent);
  if DefaultPackage.FileCount=0 then begin
    FreeThenNil(FDefaultPackage);
  end else begin
    DefaultPackage.Name:=CreateUniquePkgName('DefaultPackage',DefaultPackage);
    AddPackage(DefaultPackage);
  end;
  RegistrationPackage:=nil;

  EndUpdate;
end;

procedure TLazPackageGraph.RegisterStaticPackage(APackage: TLazPackage;
  RegisterProc: TRegisterProc);
begin
  if AbortRegistration then exit;
  RegistrationPackage:=APackage;
  CallRegisterProc(RegisterProc);
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

procedure TLazPackageGraph.CallRegisterProc(RegisterProc: TRegisterProc);
begin
  if AbortRegistration then exit;

  // check registration procedure
  if RegisterProc=nil then begin
    RegistrationError(lisPkgSysRegisterProcedureIsNil);
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
end;

procedure TLazPackageGraph.AddDependencyToPackage(APackage: TLazPackage;
  Dependency: TPkgDependency);
begin
  BeginUpdate(true);
  APackage.AddRequiredDependency(Dependency);
  Dependency.LoadPackageResult:=lprUndefined;
  OpenDependency(Dependency);
  EndUpdate;
end;

procedure TLazPackageGraph.AddDependencyToPackage(APackage,
  RequiredPackage: TLazPackage);
var
  NewDependency: TPkgDependency;
begin
  NewDependency:=TPkgDependency.Create;
  NewDependency.PackageName:=RequiredPackage.Name;
  AddDependencyToPackage(APackage,NewDependency);
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
begin
  if Dependency.Compare(NewDependency)=0 then exit;
  BeginUpdate(true);
  Dependency.Assign(NewDependency);
  Dependency.LoadPackageResult:=lprUndefined;
  OpenDependency(Dependency);
  DoDependencyChanged(Dependency);
  EndUpdate;
end;

function TLazPackageGraph.OpenDependency(Dependency: TPkgDependency
  ): TLoadPackageResult;
var
  ANode: TAVLTreeNode;
  PkgLink: TPackageLink;
begin
  if Dependency.LoadPackageResult=lprUndefined then begin
    BeginUpdate(false);
    // search compatible package in opened packages
    ANode:=FindNodeOfDependency(Dependency,fpfSearchEverywhere);
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
  Result:=Dependency.LoadPackageResult;
end;

procedure TLazPackageGraph.OpenInstalledDependency(Dependency: TPkgDependency;
  InstallType: TPackageInstallType);
var
  BrokenPackage: TLazPackage;
begin
  OpenDependency(Dependency);
  if Dependency.LoadPackageResult<>lprSuccess then begin
    // a valid lpk file of the installed package can not be found
    // -> create a broken package
    BrokenPackage:=TLazPackage.Create;
    with BrokenPackage do begin
      BeginUpdate;
      Missing:=true;
      AutoCreated:=true;
      Name:=Dependency.PackageName;
      Filename:='';
      Version.SetValues(0,0,0,0);
      Author:='?';
      License:='?';
      AutoUpdate:=pupManually;
      Description:=lisPkgSysThisPackageIsInstalledButTheLpkFileWasNotFound;
      PackageType:=lptDesignTime;
      Installed:=pitStatic;
      CompilerOptions.UnitOutputDirectory:='';

      // add lazarus registration unit path
      UsageOptions.UnitPath:='';

      Modified:=false;
      EndUpdate;
    end;
    AddPackage(BrokenPackage);

    // tell the user
    MessageDlg(lisPkgSysPackageFileNotFound,
      Format(lisPkgSysThePackageIsInstalledButNoValidPackageFileWasFound, ['"',
        BrokenPackage.Name, '"', #13]),
      mtError,[mbOk],0);

    // open it
    if OpenDependency(Dependency)<>lprSuccess then
      RaiseException('TLazPackageGraph.OpenInstalledDependency');
  end;
  Dependency.RequiredPackage.Installed:=InstallType;
end;

procedure TLazPackageGraph.OpenRequiredDependencyList(
  FirstDependency: TPkgDependency);
var
  Dependency: TPkgDependency;
begin
  Dependency:=FirstDependency;
  while Dependency<>nil do begin
    OpenDependency(Dependency);
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
    PkgLinks.IteratePackages(fpfPkgLinkMustExist in Flags,Event);
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
// returns packages in topological order, beginning with the top level package

  procedure GetTopologicalOrder(CurDependency: TPkgDependency);
  var
    RequiredPackage: TLazPackage;
  begin
    while CurDependency<>nil do begin
      if CurDependency.LoadPackageResult=lprSuccess then begin
        RequiredPackage:=CurDependency.RequiredPackage;
        if (not (lpfVisited in RequiredPackage.Flags)) then begin
          RequiredPackage.Flags:=RequiredPackage.Flags+[lpfVisited];
          GetTopologicalOrder(RequiredPackage.FirstRequiredDependency);
          // add package to list
          if List=nil then List:=TList.Create;
          List.Add(RequiredPackage);
        end;
      end;
      CurDependency:=CurDependency.NextRequiresDependency;
    end;
  end;

var
  i: Integer;
  j: Integer;
begin
  List:=nil;
  MarkAllPackagesAsNotVisited;
  // create topological list, beginning with the leaves
  GetTopologicalOrder(FirstDependency);
  // reverse list order
  if List<>nil then begin
    i:=0;
    j:=List.Count-1;
    while i<j do begin
      List.Exchange(i,j);
      inc(i);
      dec(j);
    end;
  end;
end;

procedure TLazPackageGraph.GetConnectionsTree(FirstDependency: TPkgDependency;
  var PkgList: TList; var Tree: TPkgPairTree);
  
  procedure AddConnection(Pkg1, Pkg2: TLazPackage);
  begin
    if Pkg1=Pkg2 then exit;
    if Tree=nil then
      Tree:=TPkgPairTree.Create;
    Tree.AddPairIfNotExists(Pkg1,Pkg2);
  end;
  
  procedure AddConnections(StartDependency: TPkgDependency);
  // add every connection between owner and required package
  // and between two childs
  var
    OwnerPackage: TLazPackage;
    Dependency1: TPkgDependency;
    Dependency2: TPkgDependency;
    Pkg1: TLazPackage;
    Pkg2: TLazPackage;
  begin
    if StartDependency=nil then exit;
    if (StartDependency.Owner is TLazPackage) then
      OwnerPackage:=TLazPackage(StartDependency.Owner)
    else
      OwnerPackage:=nil;
    Dependency1:=StartDependency;
    while Dependency1<>nil do begin
      Pkg1:=Dependency1.RequiredPackage;
      if Pkg1<>nil then begin
        // add connection between owner and required package
        if OwnerPackage<>nil then
          AddConnection(OwnerPackage,Pkg1);
        // add connections between any two direct required packages
        Dependency2:=StartDependency;
        while Dependency2<>nil do begin
          Pkg2:=Dependency2.RequiredPackage;
          if Pkg2<>nil then
            AddConnection(Pkg1,Pkg2);
          Dependency2:=Dependency2.NextDependency[pdlRequires];
        end;
      end;
      Dependency1:=Dependency1.NextDependency[pdlRequires];
    end;
  end;
  
var
  i: Integer;
  Pkg: TLazPackage;
begin
  if Tree<>nil then Tree.FreeAndClear;
  GetAllRequiredPackages(FirstDependency,PkgList);
  if PkgList=nil then exit;
  AddConnections(FirstDependency);
  for i:=0 to PkgList.Count-1 do begin
    Pkg:=TLazPackage(PkgList[i]);
    AddConnections(Pkg.FirstRequiredDependency);
  end;
end;

initialization
  PackageGraph:=nil;

end.


