{  $Id$  }
{
 /***************************************************************************
                            packagedefs.pas
                            ---------------


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

  What is a package:
  A lazarus package is a collection of units and components, containing
  information how they can be compiled and how they can be used by projects or
  other packages or the IDE. In contrary to Delphi, packages are not limited
  to libraries and they can be OS independent.
  (Delphi: a package is a specially compiled library used by applications,
  the IDE or both. Delphi packages require compiler magic, which fpc is not
  capable of at the moment and of course this magic is not OS independent.)

}
unit PackageDefs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Graphics, Laz_XMLCfg, AVL_Tree,
  DefineTemplates, CodeToolManager, EditDefineTree, CompilerOptions, Forms,
  FileCtrl, LazarusIDEStrConsts, IDEProcs, ComponentReg, TransferMacros,
  FileReferenceList;

type
  TLazPackage = class;
  TLazPackageID = class;
  TPkgFile = class;
  TBasePackageEditor = class;
  TPkgDependency = class;

  TIteratePackagesEvent =
    procedure(APackage: TLazPackageID) of object;
  TGetAllRequiredPackagesEvent =
    procedure(FirstDependency: TPkgDependency; var List: TList) of object;
  TGetDependencyOwnerDescription =
    procedure(Dependency: TPkgDependency; var Description: string) of object;


  { TPkgComponent }
  
  TPkgComponent = class(TRegisteredComponent)
  private
    FPkgFile: TPkgFile;
    FIcon: TBitmap;
    FIconLoaded: boolean;
    procedure SetPkgFile(const AValue: TPkgFile);
  public
    constructor Create(ThePkgFile: TPkgFile; TheComponentClass: TComponentClass;
                       const ThePageName: string);
    destructor Destroy; override;
    function GetUnitName: string; override;
    function GetPriority: TComponentPriority; override;
    procedure ConsistencyCheck; override;
    function Icon: TBitmap;
    function GetIconCopy: TBitmap;
    function HasIcon: boolean;
    function CanBeCreatedInDesigner: boolean; override;
  public
    property PkgFile: TPkgFile read FPkgFile write SetPkgFile;
  end;


  { TPkgVersion }

  TPkgVersion = class
  public
    Major: integer;
    Minor: integer;
    Release: integer;
    Build: integer;
    OnChange: TNotifyEvent;
    procedure Clear;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
      FileVersion: integer);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    function Compare(Version2: TPkgVersion): integer;
    procedure Assign(Source: TPkgVersion);
    function AsString: string;
    function ReadString(const s: string): boolean;
    procedure SetValues(NewMajor, NewMinor, NewRelease, NewBuild: integer);
    function VersionBound(v: integer): integer;
  end;
  
  
  { TPkgFile }

  TPkgFileType = (
    pftUnit,    // file is pascal unit
    pftLFM,     // lazarus form text file
    pftLRS,     // lazarus resource file
    pftInclude, // include file
    pftText,    // file is text (e.g. copyright or install notes)
    pftBinary   // file is something else
    );
  TPkgFileTypes = set of TPkgFileType;

  TPkgFileFlag = (
    pffHasRegisterProc,  // file is unit and has a 'register' procedure
    pffReportedAsRemoved // file has been reported as removed
    );
  TPkgFileFlags = set of TPkgFileFlag;
  
  TPkgFile = class
  private
    FComponentPriority: TComponentPriority;
    FComponents: TList; // list of TPkgComponent
    FDirectory: string;
    FRemoved: boolean;
    FFilename: string;
    FFileType: TPkgFileType;
    FFlags: TPkgFileFlags;
    FPackage: TLazPackage;
    FUnitName: string;
    function GetComponents(Index: integer): TPkgComponent;
    function GetHasRegisterProc: boolean;
    procedure SetRemoved(const AValue: boolean);
    procedure SetFilename(const AValue: string);
    procedure SetFileType(const AValue: TPkgFileType);
    procedure SetFlags(const AValue: TPkgFileFlags);
    procedure SetHasRegisterProc(const AValue: boolean);
    procedure UpdateUnitName;
    function GetComponentList: TList;
  public
    constructor Create(ThePackage: TLazPackage);
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
      FileVersion: integer);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure ConsistencyCheck;
    function IsVirtual: boolean;
    function GetShortFilename: string;
    function ComponentCount: integer;
    procedure AddPkgComponent(APkgComponent: TPkgComponent);
    procedure RemovePkgComponent(APkgComponent: TPkgComponent);
    function GetResolvedFilename: string;
    function HasRegisteredPlugins: boolean;
  public
    property Removed: boolean read FRemoved write SetRemoved;
    property Directory: string read FDirectory;
    property Filename: string read FFilename write SetFilename;
    property FileType: TPkgFileType read FFileType write SetFileType;
    property Flags: TPkgFileFlags read FFlags write SetFlags;
    property HasRegisterProc: boolean
      read GetHasRegisterProc write SetHasRegisterProc;
    property LazPackage: TLazPackage read FPackage;
    property UnitName: string read FUnitName write FUnitName;
    property ComponentPriority: TComponentPriority read FComponentPriority
                                                   write FComponentPriority;
    property Components[Index: integer]: TPkgComponent read GetComponents;
  end;
  
  
  { TPkgDependency }
  
  TPkgDependencyFlag = (
    pdfMinVersion, // >= MinVersion
    pdfMaxVersion // <= MaxVersion
    );
  TPkgDependencyFlags = set of TPkgDependencyFlag;
  
  TLoadPackageResult = (
    lprUndefined,
    lprSuccess,
    lprNotFound,
    lprLoadError
    );

  TPkgDependencyList = (
    pdlUsedBy,
    pdlRequires
    );
  
  TPkgDependency = class
  private
    FFlags: TPkgDependencyFlags;
    FHoldPackage: boolean;
    FLoadPackageResult: TLoadPackageResult;
    FOwner: TObject;
    FMaxVersion: TPkgVersion;
    FMinVersion: TPkgVersion;
    FPackageName: string;
    FRemoved: boolean;
    FRequiredPackage: TLazPackage;
    procedure SetFlags(const AValue: TPkgDependencyFlags);
    procedure SetHoldPackage(const AValue: boolean);
    procedure SetLoadPackageResult(const AValue: TLoadPackageResult);
    procedure SetMaxVersion(const AValue: TPkgVersion);
    procedure SetMinVersion(const AValue: TPkgVersion);
    procedure SetPackageName(const AValue: string);
    procedure SetRemoved(const AValue: boolean);
    procedure SetRequiredPackage(const AValue: TLazPackage);
  public
    NextDependency, PrevDependency: array[TPkgDependencyList] of TPkgDependency;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
      FileVersion: integer);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    function MakeSense: boolean;
    function IsCompatible(const Version: TPkgVersion): boolean;
    function IsCompatible(const PkgName: string;
      const Version: TPkgVersion): boolean;
    function Compare(Dependency2: TPkgDependency): integer;
    procedure Assign(Source: TPkgDependency);
    procedure ConsistencyCheck;
    function IsCompatible(Pkg: TLazPackageID): boolean;
    procedure MakeCompatible(const PkgName: string; const Version: TPkgVersion);
    function AsString: string;
    function NextUsedByDependency: TPkgDependency;
    function PrevUsedByDependency: TPkgDependency;
    function NextRequiresDependency: TPkgDependency;
    function PrevRequiresDependency: TPkgDependency;
    procedure AddToList(var FirstDependency: TPkgDependency;
      ListType: TPkgDependencyList);
    procedure RemoveFromList(var FirstDependency: TPkgDependency;
      ListType: TPkgDependencyList);
    procedure MoveUpInList(var FirstDependency: TPkgDependency;
      ListType: TPkgDependencyList);
    procedure MoveDownInList(var FirstDependency: TPkgDependency;
      ListType: TPkgDependencyList);
  public
    property PackageName: string read FPackageName write SetPackageName;
    property Flags: TPkgDependencyFlags read FFlags write SetFlags;
    property MinVersion: TPkgVersion read FMinVersion write SetMinVersion;
    property MaxVersion: TPkgVersion read FMaxVersion write SetMaxVersion;
    property Removed: boolean read FRemoved write SetRemoved;
    property Owner: TObject read FOwner write FOwner;
    property RequiredPackage: TLazPackage read FRequiredPackage write SetRequiredPackage;
    property LoadPackageResult: TLoadPackageResult read FLoadPackageResult write SetLoadPackageResult;
    property HoldPackage: boolean read FHoldPackage write SetHoldPackage;
  end;
  PPkgDependency = ^TPkgDependency;
  
  
  { TPkgCompilerOptions }
  
  TPkgCompilerOptions = class(TBaseCompilerOptions)
  private
    FLazPackage: TLazPackage;
  protected
    procedure SetLazPackage(const AValue: TLazPackage);
    procedure SetModified(const NewValue: boolean); override;
    procedure SetCustomOptions(const AValue: string); override;
    procedure SetIncludeFiles(const AValue: string); override;
    procedure SetLibraries(const AValue: string); override;
    procedure SetLinkerOptions(const AValue: string); override;
    procedure SetObjectPath(const AValue: string); override;
    procedure SetSrcPath(const AValue: string); override;
    procedure SetOtherUnitFiles(const AValue: string); override;
    procedure SetUnitOutputDir(const AValue: string); override;
  public
    constructor Create(ThePackage: TLazPackage);
    procedure Clear; override;
    procedure GetInheritedCompilerOptions(var OptionsList: TList); override;
    function GetOwnerName: string; override;
    procedure InvalidateOptions;
    function GetDefaultMainSourceFileName: string; override;
    function CreateTargetFilename(const MainSourceFileName: string): string; override;
  public
    property LazPackage: TLazPackage read FLazPackage write SetLazPackage;
  end;
  
  
  { TPkgAdditionalCompilerOptions }
  
  TPkgAdditionalCompilerOptions = class(TAdditionalCompilerOptions)
  private
    FLazPackage: TLazPackage;
    procedure SetLazPackage(const AValue: TLazPackage);
  protected
    procedure SetCustomOptions(const AValue: string); override;
    procedure SetIncludePath(const AValue: string); override;
    procedure SetLibraryPath(const AValue: string); override;
    procedure SetLinkerOptions(const AValue: string); override;
    procedure SetObjectPath(const AValue: string); override;
    procedure SetUnitPath(const AValue: string); override;
  public
    constructor Create(ThePackage: TLazPackage);
    function GetOwnerName: string; override;
  public
    property LazPackage: TLazPackage read FLazPackage write SetLazPackage;
  end;
  
  
  { TLazPackageID }
  
  TLazPackageID = class
  protected
    FName: string;
    FVersion: TPkgVersion;
    FIDAsString: string;
    procedure SetName(const AValue: string); virtual;
    procedure UpdateIDAsString;
    procedure VersionChanged(Sender: TObject); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function StringToID(const s: string): boolean;
    function Compare(PackageID2: TLazPackageID): integer;
    procedure AssignID(Source: TLazPackageID); virtual;
  public
    property Name: string read FName write SetName;
    property Version: TPkgVersion read FVersion;
    property IDAsString: string read FIDAsString;
  end;
  
  
  { TLazPackageDefineTemplates }
  
  TLazPkgDefineTemplatesFlag = (
    pdtIDChanged,
    pdtSourceDirsChanged,
    pdtOutputDirChanged
    );
  TLazPkgDefineTemplatesFlags = set of TLazPkgDefineTemplatesFlag;
  
  TLazPackageDefineTemplates = class
  private
    FFlags: TLazPkgDefineTemplatesFlags;
    fLastOutputDirSrcPathIDAsString: string;
    fLastSourceDirectories: TStringList;
    fLastSourceDirStamp: integer;
    fLastSourceDirsIDAsString: string;
    FLazPackage: TLazPackage;
    FMain: TDefineTemplate;
    FOutputDir: TDefineTemplate;
    FOutPutSrcPath: TDefineTemplate;
    FUpdateLock: integer;
    procedure UpdateMain;
    procedure UpdateDefinesForOutputDirectory;
    procedure UpdateDefinesForSourceDirectories;
  public
    constructor Create(OwnerPackage: TLazPackage);
    destructor Destroy; override;
    procedure Clear;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure PackageIDChanged;
    procedure SourceDirectoriesChanged;
    procedure OutputDirectoryChanged;
    procedure AllChanged;
  public
    property LazPackage: TLazPackage read FLazPackage;
    property Main: TDefineTemplate read FMain;
    property OutputDir: TDefineTemplate read FOutputDir;
    property OutPutSrcPath: TDefineTemplate read FOutPutSrcPath;
  end;
  

  { TLazPackage }
  
  TLazPackageType = (
    lptRunTime,         // RunTime packages can't register anything in the IDE.
    lptDesignTime,      // DesignTime packages can register anything in the IDE
                        // and should not be compiled into projects.
                        // The IDE calls the 'register' procedures of each unit.
    lptRunAndDesignTime // RunAndDesignTime packages can do anything.
    );
    
  TLazPackageFlag = (
    lpfAutoIncrementVersionOnBuild, // increment version before
    lpfModified,       // package needs saving
    lpfAutoUpdate,     // auto compile, if this package
                       // or any required package has been modified
    lpfNeeded,         // Set by PackageGraph, if package is in use
                       //   (for example because it is Installed or an Installed
                       //    package requires this package)
    lpfVisited,        // Used by the PackageGraph to avoid double checking
    lpfDestroying,     // set during destruction
    lpfLoading,        // set during loading
    lpfSkipSaving,     // Used by PkgBoss to skip saving
    lpfCircle,         // Used by the PackageGraph to mark circles
    lpfStateFileLoaded // state file data valid
    );
  TLazPackageFlags = set of TLazPackageFlag;
  
  TIterateComponentClassesEvent =
    procedure(PkgComponent: TPkgComponent) of object;

  TPackageInstallType = (
    pitNope,
    pitStatic,
    pitDynamic
    );
    
  TPkgChangeNameEvent = procedure(Pkg: TLazPackage;
                                  const OldName: string) of object;
    
  TLazPackage = class(TLazPackageID)
  private
    FAuthor: string;
    FAutoCreated: boolean;
    FAutoInstall: TPackageInstallType;
    FBroken: boolean;
    FCompilerOptions: TPkgCompilerOptions;
    FComponents: TList; // TList of TPkgComponent
    FDefineTemplates: TLazPackageDefineTemplates;
    FDescription: string;
    FDirectory: string;
    FFilename: string;
    FFiles: TList; // TList of TPkgFile
    FFirstRemovedDependency: TPkgDependency;
    FFirstRequiredDependency: TPkgDependency;
    FFirstUsedByDependency: TPkgDependency;
    FFlags: TLazPackageFlags;
    FHoldPackageCount: integer;
    FIconFile: string;
    FInstalled: TPackageInstallType;
    FLastCompilerFileDate: integer;
    FLastCompilerFilename: string;
    FLastCompilerParams: string;
    FLicense: string;
    FMacros: TTransferMacroList;
    FModifiedLock: integer;
    FOutputStateFile: string;
    FPackageEditor: TBasePackageEditor;
    FPackageType: TLazPackageType;
    FReadOnly: boolean;
    FRemovedFiles: TList; // TList of TPkgFile
    FRegistered: boolean;
    FSourceDirectories: TFileReferenceList;
    FStateFileDate: longint;
    FUpdateLock: integer;
    FUsageOptions: TPkgAdditionalCompilerOptions;
    function GetAutoIncrementVersionOnBuild: boolean;
    function GetAutoUpdate: boolean;
    function GetComponentCount: integer;
    function GetComponents(Index: integer): TPkgComponent;
    function GetRemovedCount: integer;
    function GetRemovedFiles(Index: integer): TPkgFile;
    function GetFileCount: integer;
    function GetFiles(Index: integer): TPkgFile;
    function GetModified: boolean;
    procedure SetAuthor(const AValue: string);
    procedure SetAutoCreated(const AValue: boolean);
    procedure SetAutoIncrementVersionOnBuild(const AValue: boolean);
    procedure SetAutoInstall(const AValue: TPackageInstallType);
    procedure SetAutoUpdate(const AValue: boolean);
    procedure SetDescription(const AValue: string);
    procedure SetFilename(const AValue: string);
    procedure SetFlags(const AValue: TLazPackageFlags);
    procedure SetIconFile(const AValue: string);
    procedure SetInstalled(const AValue: TPackageInstallType);
    procedure SetLicense(const AValue: string);
    procedure SetOutputStateFile(const AValue: string);
    procedure SetRegistered(const AValue: boolean);
    procedure SetModified(const AValue: boolean);
    procedure SetName(const AValue: string); override;
    procedure SetPackageEditor(const AValue: TBasePackageEditor);
    procedure SetPackageType(const AValue: TLazPackageType);
    procedure SetReadOnly(const AValue: boolean);
    procedure OnMacroListSubstitution(TheMacro: TTransferMacro; var s: string;
      var Handled, Abort: boolean);
    function SubstitutePkgMacro(const s: string): string;
    procedure Clear;
    procedure UpdateSourceDirectories;
    procedure VersionChanged(Sender: TObject); override;
    procedure SourceDirectoriesChanged(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure LockModified;
    procedure UnlockModified;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    function IsVirtual: boolean;
    function HasDirectory: boolean;
    procedure CheckInnerDependencies;
    function MakeSense: boolean;
    procedure ShortenFilename(var ExpandedFilename: string);
    procedure LongenFilename(var AFilename: string);
    function GetResolvedFilename: string;
    procedure ConsistencyCheck;
    procedure GetInheritedCompilerOptions(var OptionsList: TList);
    function GetCompileSourceFilename: string;
    function GetOutputDirectory: string;
    function GetStateFilename: string;
    function GetSrcFilename: string;
    function GetCompilerFilename: string;
    function GetUnitPath(RelativeToBaseDir: boolean): string;
    function GetIncludePath(RelativeToBaseDir: boolean): string;
    function NeedsDefineTemplates: boolean;
    // files
    function FindPkgFile(const AFilename: string;
                         ResolveLinks, IgnoreRemoved: boolean): TPkgFile;
    function FindUnit(const TheUnitName: string; IgnoreRemoved: boolean): TPkgFile;
    function FindRemovedPkgFile(const AFilename: string): TPkgFile;
    function AddFile(const NewFilename, NewUnitName: string;
                     NewFileType: TPkgFileType; NewFlags: TPkgFileFlags;
                     CompPriorityCat: TComponentPriorityCategory): TPkgFile;
    procedure RemoveFile(PkgFile: TPkgFile);
    procedure UnremovePkgFile(PkgFile: TPkgFile);
    // required dependencies (plus removed required dependencies)
    function FindDependencyByName(const PkgName: string): TPkgDependency;
    function RequiredDepByIndex(Index: integer): TPkgDependency;
    function RemovedDepByIndex(Index: integer): TPkgDependency;
    procedure AddRequiredDependency(Dependency: TPkgDependency);
    procedure RemoveRequiredDependency(Dependency: TPkgDependency);
    procedure DeleteRequiredDependency(Dependency: TPkgDependency);
    procedure DeleteRemovedDependency(Dependency: TPkgDependency);
    procedure RemoveRemovedDependency(Dependency: TPkgDependency);
    procedure MoveRequiredDependencyUp(Dependency: TPkgDependency);
    procedure MoveRequiredDependencyDown(Dependency: TPkgDependency);
    function CreateDependencyForThisPkg: TPkgDependency;
    function Requires(APackage: TLazPackage): boolean;
    procedure GetAllRequiredPackages(var List: TList);
    // components
    function IndexOfPkgComponent(PkgComponent: TPkgComponent): integer;
    function AddComponent(PkgFile: TPkgFile; const Page: string;
                          TheComponentClass: TComponentClass): TPkgComponent;
    procedure AddPkgComponent(APkgComponent: TPkgComponent);
    procedure RemovePkgComponent(APkgComponent: TPkgComponent);
    procedure IterateComponentClasses(Event: TIterateComponentClassesEvent;
                                      WithUsedPackages: boolean);
    // used by dependencies
    procedure AddUsedByDependency(Dependency: TPkgDependency);
    procedure RemoveUsedByDependency(Dependency: TPkgDependency);
    function UsedByDepByIndex(Index: integer): TPkgDependency;
    // ID
    procedure ChangeID(const NewName: string; NewVersion: TPkgVersion);
  public
    property Author: string read FAuthor write SetAuthor;
    property AutoCreated: boolean read FAutoCreated write SetAutoCreated;
    property AutoIncrementVersionOnBuild: boolean
       read GetAutoIncrementVersionOnBuild write SetAutoIncrementVersionOnBuild;
    property AutoInstall: TPackageInstallType read FAutoInstall
                                              write SetAutoInstall;
    property AutoUpdate: boolean read GetAutoUpdate write SetAutoUpdate;
    property Broken: boolean read FBroken write FBroken;
    property CompilerOptions: TPkgCompilerOptions read FCompilerOptions;
    property ComponentCount: integer read GetComponentCount;
    property Components[Index: integer]: TPkgComponent read GetComponents;
    property DefineTemplates: TLazPackageDefineTemplates read FDefineTemplates
                                                         write FDefineTemplates;
    property Description: string read FDescription write SetDescription;
    property Directory: string read FDirectory; // the path of the .lpk file
    property Editor: TBasePackageEditor read FPackageEditor
                                        write SetPackageEditor;
    property FileCount: integer read GetFileCount;
    property Filename: string read FFilename write SetFilename;//the .lpk filename
    property Files[Index: integer]: TPkgFile read GetFiles;
    property FirstRemovedDependency: TPkgDependency
                                                   read FFirstRemovedDependency;
    property FirstRequiredDependency: TPkgDependency
                                                  read FFirstRequiredDependency;
    property FirstUsedByDependency: TPkgDependency read FFirstUsedByDependency;
    property Flags: TLazPackageFlags read FFlags write SetFlags;
    property HoldPackageCount: integer read FHoldPackageCount;
    property IconFile: string read FIconFile write SetIconFile;
    property Installed: TPackageInstallType read FInstalled write SetInstalled;
    property LastCompilerFilename: string read FLastCompilerFilename
                                          write FLastCompilerFilename;
    property LastCompilerFileDate: integer read FLastCompilerFileDate
                                          write FLastCompilerFileDate;
    property LastCompilerParams: string read FLastCompilerParams
                                        write FLastCompilerParams;
    property License: string read FLicense write SetLicense;
    property Macros: TTransferMacroList read FMacros;
    property Modified: boolean read GetModified write SetModified;
    property OutputStateFile: string read FOutputStateFile write SetOutputStateFile;
    property PackageType: TLazPackageType read FPackageType
                                          write SetPackageType;
    property ReadOnly: boolean read FReadOnly write SetReadOnly;
    property Registered: boolean read FRegistered write SetRegistered;
    property RemovedFilesCount: integer read GetRemovedCount;
    property RemovedFiles[Index: integer]: TPkgFile read GetRemovedFiles;
    property SourceDirectories: TFileReferenceList read FSourceDirectories;
    property StateFileDate: longint read FStateFileDate write FStateFileDate;
    property UsageOptions: TPkgAdditionalCompilerOptions read FUsageOptions;
  end;
  
  PLazPackage = ^TLazPackage;
  
  
  { TBasePackageEditor }
  
  TBasePackageEditor = class(TForm)
  public
    procedure UpdateAll; virtual; abstract;
  end;
  

const
  LazPkgXMLFileVersion = 1;
  
  PkgFileTypeNames: array[TPkgFileType] of string = (
    'pftUnit', 'pftLFM', 'pftLRS', 'pftInclude', 'pftText', 'pftBinary');
  PkgFileTypeIdents: array[TPkgFileType] of string = (
    'Unit', 'LFM', 'LRS', 'Include', 'Text', 'Binary');
  PkgFileFlag: array[TPkgFileFlag] of string = (
    'pffHasRegisterProc', 'pffReportedAsRemoved');
  PkgDependencyFlagNames: array[TPkgDependencyFlag] of string = (
    'pdfMinVersion', 'pdfMaxVersion');
  LazPackageTypeNames: array[TLazPackageType] of string = (
    'lptRunTime', 'lptDesignTime', 'lptRunAndDesignTime');
  LazPackageTypeIdents: array[TLazPackageType] of string = (
    'RunTime', 'DesignTime', 'RunAndDesignTime');
  LazPackageFlagNames: array[TLazPackageFlag] of string = (
    'lpfAutoIncrementVersionOnBuild', 'lpfModified', 'lpfAutoUpdate',
    'lpfNeeded', 'lpfVisited', 'lpfDestroying', 'lpfLoading', 'lpfSkipSaving',
    'lpfCircle', 'lpfStateFileLoaded');
    
var
  // All TPkgDependency are added to this AVL tree (sorted for names, not version!)
  PackageDependencies: TAVLTree; // tree of TPkgDependency

  OnGetAllRequiredPackages: TGetAllRequiredPackagesEvent;
  OnGetDependencyOwnerDescription: TGetDependencyOwnerDescription;

function CompareLazPackageID(Data1, Data2: Pointer): integer;
function CompareNameWithPackageID(Key, Data: Pointer): integer;
function CompareLazPackageIDNames(Data1, Data2: Pointer): integer;
function CompareNameWithPkgDependency(Key, Data: Pointer): integer;
function ComparePkgDependencyNames(Data1, Data2: Pointer): integer;

function GetUsageOptionsList(PackageList: TList): TList;

function PkgFileTypeIdentToType(const s: string): TPkgFileType;
function LazPackageTypeIdentToType(const s: string): TLazPackageType;
function GetPkgFileTypeLocalizedName(FileType: TPkgFileType): string;

procedure SortDependencyList(Dependencies: TList);
procedure LoadPkgDependencyList(XMLConfig: TXMLConfig; const ThePath: string;
  var First: TPkgDependency; ListType: TPkgDependencyList; Owner: TObject;
  HoldPackages: boolean);
procedure SavePkgDependencyList(XMLConfig: TXMLConfig; const ThePath: string;
  First: TPkgDependency; ListType: TPkgDependencyList);

function FindDependencyByNameInList(First: TPkgDependency;
  ListType: TPkgDependencyList; const Name: string): TPkgDependency;
function FindCompatibleDependencyInList(First: TPkgDependency;
  ListType: TPkgDependencyList; ComparePackage: TLazPackageID): TPkgDependency;
function GetDependencyWithIndex(First: TPkgDependency;
  ListType: TPkgDependencyList; Index: integer): TPkgDependency;
function IndexOfDependencyInList(First: TPkgDependency;
  ListType: TPkgDependencyList; FindDependency: TPkgDependency): integer;

function FindLowestPkgDependencyWithName(const PkgName: string): TPkgDependency;
function FindLowestPkgDependencyNodeWithName(const PkgName: string): TAVLTreeNode;
function FindNextPkgDependecyNodeWithSameName(Node: TAVLTreeNode): TAVLTreeNode;

function GetDependencyOwnerAsString(Dependency: TPkgDependency): string;

function PackageFileNameIsValid(const AFilename: string): boolean;



implementation


function PkgFileTypeIdentToType(const s: string): TPkgFileType;
begin
  for Result:=Low(TPkgFileType) to High(TPkgFileType) do
    if AnsiCompareText(s,PkgFileTypeIdents[Result])=0 then exit;
  Result:=pftUnit;
end;

function LazPackageTypeIdentToType(const s: string): TLazPackageType;
begin
  for Result:=Low(TLazPackageType) to High(TLazPackageType) do
    if AnsiCompareText(s,LazPackageTypeIdents[Result])=0 then exit;
  Result:=lptRunTime;
end;

function GetPkgFileTypeLocalizedName(FileType: TPkgFileType): string;
begin
  case FileType of
  pftUnit: Result:=lisPkgFileTypeUnit;
  pftLFM: Result:=lisPkgFileTypeLFM;
  pftLRS: Result:=lisPkgFileTypeLRS;
  pftInclude: Result:=lisPkgFileTypeInclude;
  pftText: Result:=lisPkgFileTypeText;
  pftBinary: Result:=lisPkgFileTypeBinary;
  else
    Result:='Unknown';
  end;
end;

procedure LoadPkgDependencyList(XMLConfig: TXMLConfig; const ThePath: string;
  var First: TPkgDependency; ListType: TPkgDependencyList; Owner: TObject;
  HoldPackages: boolean);
var
  i: Integer;
  PkgDependency: TPkgDependency;
  NewCount: Integer;
  List: TList;
  FileVersion: Integer;
begin
  FileVersion:=XMLConfig.GetValue(ThePath+'Version',0);
  NewCount:=XMLConfig.GetValue(ThePath+'Count',0);
  List:=TList.Create;
  for i:=0 to NewCount-1 do begin
    PkgDependency:=TPkgDependency.Create;
    PkgDependency.LoadFromXMLConfig(XMLConfig,ThePath+'Item'+IntToStr(i+1)+'/',
                                    FileVersion);
    PkgDependency.HoldPackage:=HoldPackages;
    if PkgDependency.MakeSense then
      List.Add(PkgDependency)
    else
      PkgDependency.Free;
  end;
  SortDependencyList(List);
  for i:=0 to List.Count-1 do begin
    TPkgDependency(List[i]).AddToList(First,ListType);
    TPkgDependency(List[i]).Owner:=Owner;
  end;
  List.Free;
end;

procedure SavePkgDependencyList(XMLConfig: TXMLConfig; const ThePath: string;
  First: TPkgDependency; ListType: TPkgDependencyList);
var
  i: Integer;
  Dependency: TPkgDependency;
begin
  i:=0;
  Dependency:=First;
  while Dependency<>nil do begin
    inc(i);
    Dependency.SaveToXMLConfig(XMLConfig,ThePath+'Item'+IntToStr(i)+'/');
    Dependency:=Dependency.NextDependency[ListType];
  end;
  XMLConfig.SetDeleteValue(ThePath+'Count',i,0);
end;

procedure SortDependencyList(Dependencies: TList);
var
  Count: Integer;
  i, j: Integer;
  Dependency1: TPkgDependency;
  Dependency2: TPkgDependency;
  Sorted: Boolean;
begin
  if (Dependencies=nil) or (Dependencies.Count<2) then exit;
  // check if already sorted
  Count:=Dependencies.Count;
  Sorted:=true;
  for i:=0 to Count-2 do begin
    Dependency1:=TPkgDependency(Dependencies[i]);
    Dependency2:=TPkgDependency(Dependencies[i+1]);
    if Dependency1.Compare(Dependency2)>0 then begin
      Sorted:=false;
      break;
    end;
  end;
  if Sorted then exit;
  // bubble sort (slow, but dependency lists are normally sorted)
  for i:=0 to Count-2 do begin
    Dependency1:=TPkgDependency(Dependencies[i]);
    for j:=i+1 to Count-1 do begin
      Dependency2:=TPkgDependency(Dependencies[j]);
      if Dependency1.Compare(Dependency2)>0 then begin
        Dependencies.Exchange(i,j);
        Dependency1:=TPkgDependency(Dependencies[i]);
      end;
    end;
  end;
end;

function CompareLazPackageID(Data1, Data2: Pointer): integer;
var
  Pkg1: TLazPackageID;
  Pkg2: TLazPackageID;
begin
  Pkg1:=TLazPackageID(Data1);
  Pkg2:=TLazPackageID(Data2);
  Result:=Pkg1.Compare(Pkg2);
end;

function CompareNameWithPackageID(Key, Data: Pointer): integer;
var
  Name: String;
  Pkg: TLazPackageID;
begin
  if Key<>nil then begin
    Name:=AnsiString(Key);
    Pkg:=TLazPackageID(Data);
    Result:=AnsiCompareText(Name,Pkg.Name);
  end else
    Result:=-1;
end;

function CompareLazPackageIDNames(Data1, Data2: Pointer): integer;
var
  Pkg1: TLazPackageID;
  Pkg2: TLazPackageID;
begin
  Pkg1:=TLazPackageID(Data1);
  Pkg2:=TLazPackageID(Data2);
  Result:=AnsiCompareText(Pkg1.Name,Pkg2.Name);
end;

function CompareNameWithPkgDependency(Key, Data: Pointer): integer;
var
  PkgName: String;
  Dependency: TPkgDependency;
begin
  PkgName:=String(Key);
  Dependency:=TPkgDependency(Data);
  Result:=AnsiCompareText(PkgName,Dependency.PackageName);
end;

function ComparePkgDependencyNames(Data1, Data2: Pointer): integer;
var
  Dependency1: TPkgDependency;
  Dependency2: TPkgDependency;
begin
  Dependency1:=TPkgDependency(Data1);
  Dependency2:=TPkgDependency(Data2);
  Result:=AnsiCompareText(Dependency1.PackageName,Dependency2.PackageName);
end;

function GetUsageOptionsList(PackageList: TList): TList;
var
  Cnt: Integer;
  i: Integer;
begin
  if PackageList<>nil then begin
    Result:=TList.Create;
    Cnt:=PackageList.Count;
    for i:=0 to Cnt-1 do begin
      Result.Add(TLazPackage(PackageList[i]).UsageOptions);
    end;
  end else begin
    Result:=nil;
  end;
end;

function FindDependencyByNameInList(First: TPkgDependency;
  ListType: TPkgDependencyList; const Name: string): TPkgDependency;
begin
  Result:=First;
  while Result<>nil do begin
    if AnsiCompareText(Result.PackageName,Name)=0 then exit;
    Result:=Result.NextDependency[ListType];
  end;
end;

function FindCompatibleDependencyInList(First: TPkgDependency;
  ListType: TPkgDependencyList; ComparePackage: TLazPackageID): TPkgDependency;
begin
  Result:=First;
  while Result<>nil do begin
    if Result.IsCompatible(ComparePackage) then exit;
    Result:=Result.NextDependency[ListType];
  end;
end;

function GetDependencyWithIndex(First: TPkgDependency;
  ListType: TPkgDependencyList; Index: integer): TPkgDependency;
begin
  if Index<0 then RaiseException('GetDependencyWithIndex');
  Result:=First;
  while (Result<>nil) and (Index>0) do begin
    Result:=Result.NextDependency[ListType];
    dec(Index);
  end;
end;

function FindLowestPkgDependencyNodeWithName(const PkgName: string
  ): TAVLTreeNode;
var
  PrecNode: TAVLTreeNode;
begin
  Result:=nil;
  if PackageDependencies=nil then exit;
  Result:=
    PackageDependencies.FindKey(PChar(PkgName),@CompareNameWithPkgDependency);
  if Result=nil then exit;
  while true do begin
    PrecNode:=PackageDependencies.FindPrecessor(Result);
    if (PrecNode=nil)
    or (AnsiCompareText(PkgName,TPkgDependency(PrecNode.Data).PackageName)<>0)
    then
      break;
    Result:=PrecNode;
  end;
end;

function FindNextPkgDependecyNodeWithSameName(Node: TAVLTreeNode): TAVLTreeNode;
begin
  Result:=nil;
  if (Node=nil) or (PackageDependencies=nil) then exit;
  Result:=PackageDependencies.FindSuccessor(Node);
  if (Result<>nil)
  and (AnsiCompareText(TPkgDependency(Node.Data).PackageName,
                     TPkgDependency(Result.Data).PackageName)<>0)
  then
    Result:=nil;
end;

function GetDependencyOwnerAsString(Dependency: TPkgDependency): string;
begin
  OnGetDependencyOwnerDescription(Dependency,Result)
end;

function PackageFileNameIsValid(const AFilename: string): boolean;
var
  PkgName: String;
begin
  Result:=false;
  if CompareFileExt(AFilename,'.lpk',false)<>0 then exit;
  PkgName:=ExtractFileNameOnly(AFilename);
  if (PkgName='') or (not IsValidIdent(PkgName)) then exit;
  Result:=true;
end;

function IndexOfDependencyInList(First: TPkgDependency;
  ListType: TPkgDependencyList; FindDependency: TPkgDependency): integer;
var
  Dependency: TPkgDependency;
begin
  Result:=-1;
  Dependency:=First;
  while Dependency<>nil do begin
    inc(Result);
    if Dependency=FindDependency then exit;
    Dependency:=Dependency.NextDependency[ListType];
  end;
  Result:=-1;
end;

function FindLowestPkgDependencyWithName(const PkgName: string): TPkgDependency;
var
  ANode: TAVLTreeNode;
begin
  ANode:=FindLowestPkgDependencyNodeWithName(PkgName);
  if ANode<>nil then
    Result:=TPkgDependency(ANode.Data)
  else
    Result:=nil;
end;

{ TPkgFile }

procedure TPkgFile.SetFilename(const AValue: string);
var
  NewFilename: String;
  OldDirectory: String;
begin
  NewFilename:=AValue;
  DoDirSeparators(NewFilename);
  LazPackage.LongenFilename(NewFilename);
  if FFilename=NewFilename then exit;
  FFilename:=NewFilename;
  OldDirectory:=FDirectory;
  FDirectory:=ExtractFilePath(fFilename);
  if OldDirectory<>FDirectory then begin
    LazPackage.SourceDirectories.RemoveFilename(OldDirectory);
    LazPackage.SourceDirectories.AddFilename(FDirectory);
  end;
  UpdateUnitName;
end;

function TPkgFile.GetHasRegisterProc: boolean;
begin
  Result:=pffHasRegisterProc in FFlags;
end;

procedure TPkgFile.SetRemoved(const AValue: boolean);
begin
  if FRemoved=AValue then exit;
  FRemoved:=AValue;
  if FRemoved then
    LazPackage.SourceDirectories.RemoveFilename(FDirectory)
  else
    LazPackage.SourceDirectories.AddFilename(FDirectory);
end;

function TPkgFile.GetComponents(Index: integer): TPkgComponent;
begin
  Result:=TPkgComponent(FComponents[Index]);
end;

procedure TPkgFile.SetFileType(const AValue: TPkgFileType);
begin
  if FFileType=AValue then exit;
  FFileType:=AValue;
end;

procedure TPkgFile.SetFlags(const AValue: TPkgFileFlags);
begin
  if FFlags=AValue then exit;
  FFlags:=AValue;
end;

procedure TPkgFile.SetHasRegisterProc(const AValue: boolean);
begin
  if HasRegisterProc=AValue then exit;
  if AValue then
    Include(FFlags,pffHasRegisterProc)
  else
    Exclude(FFlags,pffHasRegisterProc);
end;

procedure TPkgFile.UpdateUnitName;
var
  NewUnitName: String;
begin
  if FilenameIsPascalUnit(FFilename) then begin
    NewUnitName:=ExtractFileNameOnly(FFilename);
    if AnsiCompareText(NewUnitName,FUnitName)<>0 then
      FUnitName:=NewUnitName;
  end else
    FUnitName:='';
end;

function TPkgFile.GetComponentList: TList;
begin
  if FComponents=nil then FComponents:=TList.Create;
  Result:=FComponents;
end;

function TPkgFile.HasRegisteredPlugins: boolean;
begin
  Result:=ComponentCount>0;
end;

constructor TPkgFile.Create(ThePackage: TLazPackage);
begin
  Clear;
  FPackage:=ThePackage;
  FComponentPriority:=ComponentPriorityNormal;
end;

destructor TPkgFile.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TPkgFile.Clear;
begin
  FRemoved:=false;
  FFilename:='';
  FFlags:=[];
  FFileType:=pftUnit;
  FreeThenNil(FComponents);
end;

procedure TPkgFile.LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
  FileVersion: integer);
var
  AFilename: String;
begin
  if FileVersion=1 then ;
  Clear;
  AFilename:=XMLConfig.GetValue(Path+'Filename/Value','');
  FPackage.LongenFilename(AFilename);
  Filename:=AFilename;
  FileType:=PkgFileTypeIdentToType(XMLConfig.GetValue(Path+'Type/Value',''));
  HasRegisterProc:=XMLConfig.GetValue(Path+'HasRegisterProc/Value',false);
  fUnitName:=XMLConfig.GetValue(Path+'UnitName/Value','');
end;

procedure TPkgFile.SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
var
  TmpFilename: String;
begin
  TmpFilename:=Filename;
  FPackage.ShortenFilename(TmpFilename);
  XMLConfig.SetDeleteValue(Path+'Filename/Value',TmpFilename,'');
  XMLConfig.SetDeleteValue(Path+'HasRegisterProc/Value',HasRegisterProc,
                           false);
  XMLConfig.SetDeleteValue(Path+'Type/Value',PkgFileTypeIdents[FileType],
                           PkgFileTypeIdents[pftUnit]);
  XMLConfig.SetDeleteValue(Path+'UnitName/Value',FUnitName,'');
end;

procedure TPkgFile.ConsistencyCheck;
begin
  if FPackage=nil then
    RaiseGDBException('TPkgFile.ConsistencyCheck FPackage=nil');
  if FFilename='' then
    RaiseGDBException('TPkgFile.ConsistencyCheck FFilename=""');
end;

function TPkgFile.IsVirtual: boolean;
begin
  Result:=FilenameIsAbsolute(FFilename);
end;

function TPkgFile.GetShortFilename: string;
begin
  Result:=FFilename;
  LazPackage.ShortenFilename(Result);
end;

function TPkgFile.ComponentCount: integer;
begin
  if FComponents<>nil then
    Result:=FComponents.Count
  else
    Result:=0;
end;

procedure TPkgFile.AddPkgComponent(APkgComponent: TPkgComponent);
begin
  if FComponents=nil then FComponents:=TList.Create;
  FComponents.Add(APkgComponent);
  if LazPackage<>nil then
    LazPackage.AddPkgComponent(APkgComponent);
end;

procedure TPkgFile.RemovePkgComponent(APkgComponent: TPkgComponent);
begin
  if FComponents<>nil then
    FComponents.Remove(APkgComponent);
  if LazPackage<>nil then
    LazPackage.RemovePkgComponent(APkgComponent);
end;

function TPkgFile.GetResolvedFilename: string;
begin
  Result:=ReadAllLinks(Filename,false);
  if Result='' then Result:=Filename;
end;

{ TPkgDependency }

procedure TPkgDependency.SetFlags(const AValue: TPkgDependencyFlags);
begin
  if FFlags=AValue then exit;
  FFlags:=AValue;
end;

procedure TPkgDependency.SetHoldPackage(const AValue: boolean);
begin
  if FHoldPackage=AValue then exit;
  FHoldPackage:=AValue;
  if RequiredPackage<>nil then begin
    if FHoldPackage then
      inc(RequiredPackage.FHoldPackageCount)
    else
      dec(RequiredPackage.FHoldPackageCount);
  end;
end;

procedure TPkgDependency.SetLoadPackageResult(const AValue: TLoadPackageResult
  );
begin
  if FLoadPackageResult=AValue then exit;
  FLoadPackageResult:=AValue;
end;

procedure TPkgDependency.SetMaxVersion(const AValue: TPkgVersion);
begin
  if FMaxVersion=AValue then exit;
  FMaxVersion:=AValue;
end;

procedure TPkgDependency.SetMinVersion(const AValue: TPkgVersion);
begin
  if FMinVersion=AValue then exit;
  FMinVersion:=AValue;
end;

procedure TPkgDependency.SetPackageName(const AValue: string);
begin
  if FPackageName=AValue then exit;
  if (PackageDependencies<>nil) and (FPackageName<>'') then
    PackageDependencies.RemovePointer(Self);
  FPackageName:=AValue;
  if (PackageDependencies<>nil) and (FPackageName<>'') then
    PackageDependencies.Add(Self);
end;

procedure TPkgDependency.SetRemoved(const AValue: boolean);
begin
  if FRemoved=AValue then exit;
  FRemoved:=AValue;
end;

procedure TPkgDependency.SetRequiredPackage(const AValue: TLazPackage);
begin
  if FRequiredPackage=AValue then exit;
  if FRequiredPackage<>nil then
    FRequiredPackage.RemoveUsedByDependency(Self);
  fLoadPackageResult:=lprUndefined;
  FRequiredPackage:=AValue;
  if FRequiredPackage<>nil then
    FRequiredPackage.AddUsedByDependency(Self);
end;

constructor TPkgDependency.Create;
begin
  MinVersion:=TPkgVersion.Create;
  MaxVersion:=TPkgVersion.Create;
  Clear;
end;

destructor TPkgDependency.Destroy;
begin
  RequiredPackage:=nil;
  PackageName:='';
  FreeAndNil(fMinVersion);
  FreeAndNil(fMaxVersion);
  inherited Destroy;
end;

procedure TPkgDependency.Clear;
begin
  RequiredPackage:=nil;
  PackageName:='';
  FRemoved:=false;
  FFlags:=[];
  FMaxVersion.Clear;
  FMinVersion.Clear;
end;

procedure TPkgDependency.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; FileVersion: integer);
begin
  if FileVersion=1 then ;
  Clear;
  PackageName:=XMLConfig.GetValue(Path+'PackageName/Value','');
  MaxVersion.LoadFromXMLConfig(XMLConfig,Path+'MaxVersion/',FileVersion);
  MinVersion.LoadFromXMLConfig(XMLConfig,Path+'MinVersion/',FileVersion);
  if XMLConfig.GetValue(Path+'MaxVersion/Valid',false) then
    Include(FFlags,pdfMaxVersion);
  if XMLConfig.GetValue(Path+'MinVersion/Valid',false) then
    Include(FFlags,pdfMinVersion);
end;

procedure TPkgDependency.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  XMLConfig.SetDeleteValue(Path+'PackageName/Value',PackageName,'');
  MaxVersion.SaveToXMLConfig(XMLConfig,Path+'MaxVersion/');
  MinVersion.SaveToXMLConfig(XMLConfig,Path+'MinVersion/');
  XMLConfig.SetDeleteValue(Path+'MaxVersion/Valid',pdfMaxVersion in FFlags,false);
  XMLConfig.SetDeleteValue(Path+'MinVersion/Valid',pdfMinVersion in FFlags,false);
end;

function TPkgDependency.MakeSense: boolean;
begin
  Result:=IsValidIdent(PackageName);
  if Result
  and (pdfMinVersion in FFlags) and (pdfMaxVersion in FFlags)
  and (MinVersion.Compare(MaxVersion)>0) then
    Result:=false;
end;

function TPkgDependency.IsCompatible(const Version: TPkgVersion): boolean;
begin
  if ((pdfMinVersion in FFlags) and (MinVersion.Compare(Version)>0))
  or ((pdfMaxVersion in FFlags) and (MaxVersion.Compare(Version)<0)) then
    Result:=false
  else
    Result:=true;
end;

function TPkgDependency.IsCompatible(const PkgName: string;
  const Version: TPkgVersion): boolean;
begin
  Result:=(AnsiCompareText(PkgName,PackageName)=0) and IsCompatible(Version);
end;

function TPkgDependency.Compare(Dependency2: TPkgDependency): integer;
begin
  Result:=AnsiCompareText(PackageName,Dependency2.PackageName);
  if Result<>0 then exit;
  Result:=MinVersion.Compare(Dependency2.MinVersion);
  if Result<>0 then exit;
  Result:=CompareBoolean(pdfMinVersion in Flags,
                         pdfMinVersion in Dependency2.Flags);
  if Result<>0 then exit;
  Result:=MaxVersion.Compare(Dependency2.MaxVersion);
  if Result<>0 then exit;
  Result:=CompareBoolean(pdfMaxVersion in Flags,
                         pdfMaxVersion in Dependency2.Flags);
end;

procedure TPkgDependency.Assign(Source: TPkgDependency);
begin
  PackageName:=Source.PackageName;
  Flags:=Source.Flags;
  MinVersion.Assign(Source.MinVersion);
  MaxVersion.Assign(Source.MaxVersion);
end;

procedure TPkgDependency.ConsistencyCheck;
begin

end;

function TPkgDependency.IsCompatible(Pkg: TLazPackageID): boolean;
begin
  Result:=IsCompatible(Pkg.Name,Pkg.Version);
end;

procedure TPkgDependency.MakeCompatible(const PkgName: string;
  const Version: TPkgVersion);
begin
  PackageName:=PkgName;
  if MinVersion.Compare(Version)>0 then MinVersion.Assign(Version);
  if MaxVersion.Compare(Version)<0 then MaxVersion.Assign(Version);
end;

function TPkgDependency.AsString: string;
begin
  Result:=FPackageName;
  if pdfMinVersion in FFlags then
    Result:=Result+' (>='+MinVersion.AsString+')';
  if pdfMaxVersion in FFlags then
    Result:=Result+' (<='+MaxVersion.AsString+')';
end;

function TPkgDependency.NextUsedByDependency: TPkgDependency;
begin
  Result:=NextDependency[pdlUsedBy];
end;

function TPkgDependency.PrevUsedByDependency: TPkgDependency;
begin
  Result:=PrevDependency[pdlUsedBy];
end;

function TPkgDependency.NextRequiresDependency: TPkgDependency;
begin
  Result:=NextDependency[pdlRequires];
end;

function TPkgDependency.PrevRequiresDependency: TPkgDependency;
begin
  Result:=PrevDependency[pdlRequires];
end;

procedure TPkgDependency.AddToList(var FirstDependency: TPkgDependency;
  ListType: TPkgDependencyList);
begin
  NextDependency[ListType]:=FirstDependency;
  FirstDependency:=Self;
  PrevDependency[ListType]:=nil;
  if NextDependency[ListType]<>nil then
    NextDependency[ListType].PrevDependency[ListType]:=Self;
end;

procedure TPkgDependency.RemoveFromList(var FirstDependency: TPkgDependency;
  ListType: TPkgDependencyList);
begin
  if FirstDependency=Self then FirstDependency:=NextDependency[ListType];
  if NextDependency[ListType]<>nil then
    NextDependency[ListType].PrevDependency[ListType]:=PrevDependency[ListType];
  if PrevDependency[ListType]<>nil then
    PrevDependency[ListType].NextDependency[ListType]:=NextDependency[ListType];
  NextDependency[ListType]:=nil;
  PrevDependency[ListType]:=nil;
end;

procedure TPkgDependency.MoveUpInList(var FirstDependency: TPkgDependency;
  ListType: TPkgDependencyList);
var
  OldPrev: TPkgDependency;
begin
  if (FirstDependency=Self) or (PrevDependency[ListType]=nil) then exit;
  OldPrev:=PrevDependency[ListType];
  if OldPrev.PrevDependency[ListType]<>nil then
    OldPrev.PrevDependency[ListType].NextDependency[ListType]:=Self;
  if NextDependency[ListType]<>nil then
    NextDependency[ListType].PrevDependency[ListType]:=OldPrev;
  OldPrev.NextDependency[ListType]:=NextDependency[ListType];
  PrevDependency[ListType]:=OldPrev.PrevDependency[ListType];
  NextDependency[ListType]:=OldPrev;
  OldPrev.PrevDependency[ListType]:=Self;
  if FirstDependency=OldPrev then FirstDependency:=Self;
end;

procedure TPkgDependency.MoveDownInList(var FirstDependency: TPkgDependency;
  ListType: TPkgDependencyList);
var
  OldNext: TPkgDependency;
begin
  if (NextDependency[ListType]=nil) then exit;
  OldNext:=NextDependency[ListType];
  if OldNext.NextDependency[ListType]<>nil then
    OldNext.NextDependency[ListType].PrevDependency[ListType]:=Self;
  if PrevDependency[ListType]<>nil then
    PrevDependency[ListType].NextDependency[ListType]:=OldNext;
  OldNext.PrevDependency[ListType]:=PrevDependency[ListType];
  NextDependency[ListType]:=OldNext.NextDependency[ListType];
  PrevDependency[ListType]:=OldNext;
  OldNext.NextDependency[ListType]:=Self;
  if FirstDependency=Self then FirstDependency:=OldNext;
end;

{ TPkgVersion }

procedure TPkgVersion.Clear;
begin
  SetValues(0,0,0,0);
end;

procedure TPkgVersion.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; FileVersion: integer);
var
  NewMajor: Integer;
  NewMinor: Integer;
  NewRelease: Integer;
  NewBuild: Integer;
begin
  if FileVersion=1 then ;
  NewMajor:=VersionBound(XMLConfig.GetValue(Path+'Major',0));
  NewMinor:=VersionBound(XMLConfig.GetValue(Path+'Minor',0));
  NewRelease:=VersionBound(XMLConfig.GetValue(Path+'Release',0));
  NewBuild:=VersionBound(XMLConfig.GetValue(Path+'Build',0));
  SetValues(NewMajor,NewMinor,NewRelease,NewBuild);
end;

procedure TPkgVersion.SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string
  );
begin
  XMLConfig.SetDeleteValue(Path+'Major',Major,0);
  XMLConfig.SetDeleteValue(Path+'Minor',Minor,0);
  XMLConfig.SetDeleteValue(Path+'Release',Release,0);
  XMLConfig.SetDeleteValue(Path+'Build',Build,0);
end;

function TPkgVersion.Compare(Version2: TPkgVersion): integer;
begin
  Result:=Major-Version2.Major;
  if Result<>0 then exit;
  Result:=Minor-Version2.Minor;
  if Result<>0 then exit;
  Result:=Release-Version2.Release;
  if Result<>0 then exit;
  Result:=Build-Version2.Build;
end;

procedure TPkgVersion.Assign(Source: TPkgVersion);
begin
  SetValues(Source.Major,Source.Minor,Source.Release,Source.Build);
end;

function TPkgVersion.AsString: string;
begin
  Result:=IntToStr(Major)+'.'+IntToStr(Minor);
  if (Build<>0) then
    Result:=Result+'.'+IntToStr(Release)+'.'+IntToStr(Build)
  else if (Release<>0) then
    Result:=Result+'.'+IntToStr(Release)
end;

function TPkgVersion.ReadString(const s: string): boolean;
var
  ints: array[1..4] of integer;
  i: integer;
  CurPos: Integer;
  StartPos: Integer;
begin
  Result:=false;
  CurPos:=1;
  for i:=Low(ints) to High(ints) do begin
    ints[i]:=0;
    if CurPos<length(s) then begin
      if i>Low(ints) then begin
        // read point
        if s[CurPos]<>'.' then exit;
        inc(CurPos);
      end;
      // read int
      StartPos:=CurPos;
      while (CurPos<=length(s)) and (i<=9999)
      and (s[CurPos] in ['0'..'9']) do begin
        ints[i]:=ints[i]*10+ord(s[CurPos])-ord('0');
        inc(CurPos);
      end;
      if (StartPos=CurPos) then exit;
    end;
  end;
  if CurPos<=length(s) then exit;
  SetValues(ints[1],ints[2],ints[3],ints[4]);

  Result:=true;
end;

procedure TPkgVersion.SetValues(NewMajor, NewMinor, NewRelease,
  NewBuild: integer);
begin
  NewMajor:=VersionBound(NewMajor);
  NewMinor:=VersionBound(NewMinor);
  NewRelease:=VersionBound(NewRelease);
  NewBuild:=VersionBound(NewBuild);
  if (NewMajor=Major) and (NewMinor=Minor) and (NewRelease=Release)
  and (NewBuild=Build) then exit;
  Major:=NewMajor;
  Minor:=NewMinor;
  Release:=NewRelease;
  Build:=NewBuild;
  if Assigned(OnChange) then OnChange(Self);
end;

function TPkgVersion.VersionBound(v: integer): integer;
begin
  if v>9999 then
    Result:=9999
  else if v<0 then
    Result:=0
  else
    Result:=v;
end;

{ TLazPackage }

procedure TLazPackage.OnMacroListSubstitution(TheMacro: TTransferMacro;
  var s: string; var Handled, Abort: boolean);
begin
  if AnsiCompareText(s,'PkgOutDir')=0 then begin
    Handled:=true;
    s:=CompilerOptions.ParsedOpts.GetParsedValue(pcosOutputDir);
  end
  else if AnsiCompareText(s,'PkgDir')=0 then begin
    Handled:=true;
    s:=FDirectory;
  end;
end;

function TLazPackage.SubstitutePkgMacro(const s: string): string;
begin
  Result:=s;
  FMacros.SubstituteStr(Result);
end;

function TLazPackage.GetAutoIncrementVersionOnBuild: boolean;
begin
  Result:=lpfAutoIncrementVersionOnBuild in FFlags;
end;

function TLazPackage.GetAutoUpdate: boolean;
begin
  Result:=lpfAutoUpdate in FFlags;
end;

function TLazPackage.GetComponentCount: integer;
begin
  Result:=FComponents.Count;
end;

function TLazPackage.GetComponents(Index: integer): TPkgComponent;
begin
  Result:=TPkgComponent(FComponents[Index]);
end;

function TLazPackage.GetRemovedCount: integer;
begin
  Result:=FRemovedFiles.Count;
end;

function TLazPackage.GetRemovedFiles(Index: integer): TPkgFile;
begin
  Result:=TPkgFile(FRemovedFiles[Index]);
end;

function TLazPackage.GetFileCount: integer;
begin
  Result:=FFiles.Count;
end;

function TLazPackage.GetFiles(Index: integer): TPkgFile;
begin
  Result:=TPkgFile(FFiles[Index]);
end;

function TLazPackage.GetModified: boolean;
begin
  Result:=lpfModified in FFlags;
end;

procedure TLazPackage.SetAuthor(const AValue: string);
begin
  if FAuthor=AValue then exit;
  FAuthor:=AValue;
  Modified:=true;
end;

procedure TLazPackage.SetAutoCreated(const AValue: boolean);
begin
  if FAutoCreated=AValue then exit;
  FAutoCreated:=AValue;
  if AutoCreated then ReadOnly:=true;
end;

procedure TLazPackage.SetAutoIncrementVersionOnBuild(const AValue: boolean);
begin
  if AutoIncrementVersionOnBuild=AValue then exit;
  if AValue then
    Include(FFlags,lpfAutoIncrementVersionOnBuild)
  else
    Exclude(FFlags,lpfAutoIncrementVersionOnBuild);
  Modified:=true;
end;

procedure TLazPackage.SetAutoInstall(const AValue: TPackageInstallType);
begin
  if FAutoInstall=AValue then exit;
  FAutoInstall:=AValue;
end;

procedure TLazPackage.SetAutoUpdate(const AValue: boolean);
begin
  if AValue=AutoUpdate then exit;
  if AValue then
    Include(FFlags,lpfAutoUpdate)
  else
    Exclude(FFlags,lpfAutoUpdate);
  Modified:=true;
end;

procedure TLazPackage.SetDescription(const AValue: string);
begin
  if FDescription=AValue then exit;
  FDescription:=AValue;
  Modified:=true;
end;

procedure TLazPackage.SetFilename(const AValue: string);
var
  NewFilename: String;
begin
  NewFilename:=AValue;
  DoDirSeparators(NewFilename);
  if FFilename=NewFilename then exit;
  FFilename:=NewFilename;
  if (FFilename<>'') and (FFilename[length(FFilename)]=PathDelim) then
    FDirectory:=FFilename
  else
    FDirectory:=ExtractFilePath(FFilename);
  FUsageOptions.BaseDirectory:=FDirectory;
  FCompilerOptions.BaseDirectory:=FDirectory;
  Modified:=true;
end;

procedure TLazPackage.SetFlags(const AValue: TLazPackageFlags);
var
  ChangedFlags: TLazPackageFlags;
begin
  if FFlags=AValue then exit;
  ChangedFlags:=FFlags+AValue-(FFlags*AValue);
  FFlags:=AValue;
  if ChangedFlags*[lpfAutoIncrementVersionOnBuild,lpfAutoUpdate]<>[] then
    Modified:=true;
end;

procedure TLazPackage.SetIconFile(const AValue: string);
begin
  if FIconFile=AValue then exit;
  FIconFile:=AValue;
  Modified:=true;
end;

procedure TLazPackage.SetInstalled(const AValue: TPackageInstallType);
begin
  if FInstalled=AValue then exit;
  FInstalled:=AValue;
end;

procedure TLazPackage.SetLicense(const AValue: string);
begin
  if FLicense=AValue then exit;
  FLicense:=AValue;
  Modified:=true;
end;

procedure TLazPackage.SetOutputStateFile(const AValue: string);
begin
  if FOutputStateFile=AValue then exit;
  FOutputStateFile:=AValue;
end;

procedure TLazPackage.SetRegistered(const AValue: boolean);
begin
  if FRegistered=AValue then exit;
  FRegistered:=AValue;
end;

procedure TLazPackage.SetModified(const AValue: boolean);
begin
  if AValue and (FModifiedLock>0) then exit;
  if AValue then
    Include(FFlags,lpfModified)
  else
    Exclude(FFlags,lpfModified);
  Exclude(FFlags,lpfSkipSaving);
end;

procedure TLazPackage.SetName(const AValue: string);
begin
  if FName=AValue then exit;
  inherited SetName(AValue);
  FDefineTemplates.PackageIDChanged;
  Modified:=true;
end;

procedure TLazPackage.SetPackageEditor(const AValue: TBasePackageEditor);
begin
  if FPackageEditor=AValue then exit;
  FPackageEditor:=AValue;
end;

procedure TLazPackage.SetPackageType(const AValue: TLazPackageType);
begin
  if FPackageType=AValue then exit;
  FPackageType:=AValue;
  Modified:=true;
end;

procedure TLazPackage.SetReadOnly(const AValue: boolean);
begin
  if FReadOnly=AValue then exit;
  FReadOnly:=AValue;
end;

constructor TLazPackage.Create;
begin
  inherited Create;
  FComponents:=TList.Create;
  FSourceDirectories:=TFileReferenceList.Create;
  FSourceDirectories.OnChanged:=@SourceDirectoriesChanged;
  FFiles:=TList.Create;
  FRemovedFiles:=TList.Create;
  FMacros:=TTransferMacroList.Create;
  FMacros.MarkUnhandledMacros:=false;
  FMacros.OnSubstitution:=@OnMacroListSubstitution;
  FCompilerOptions:=TPkgCompilerOptions.Create(Self);
  FCompilerOptions.ParsedOpts.OnLocalSubstitute:=@SubstitutePkgMacro;
  FCompilerOptions.ParsedOpts.InvalidateGraphOnChange:=true;
  FCompilerOptions.DefaultMakeOptionsFlags:=[ccloNoLinkerOpts];
  FUsageOptions:=TPkgAdditionalCompilerOptions.Create(Self);
  FUsageOptions.ParsedOpts.OnLocalSubstitute:=@SubstitutePkgMacro;
  FDefineTemplates:=TLazPackageDefineTemplates.Create(Self);
  Clear;
end;

destructor TLazPackage.Destroy;
begin
  Include(FFlags,lpfDestroying);
  Clear;
  FreeAndNil(FDefineTemplates);
  FreeAndNil(FRemovedFiles);
  FreeAndNil(FFiles);
  FreeAndNil(FComponents);
  FreeAndNil(FCompilerOptions);
  FreeAndNil(FUsageOptions);
  FreeAndNil(FMacros);
  FreeAndNil(FSourceDirectories);
  inherited Destroy;
end;

procedure TLazPackage.BeginUpdate;
begin
  inc(FUpdateLock);
  FDefineTemplates.BeginUpdate;
  FSourceDirectories.BeginUpdate;
end;

procedure TLazPackage.EndUpdate;
begin
  if FUpdateLock=0 then RaiseException('TLazPackage.EndUpdate');
  dec(FUpdateLock);
  FDefineTemplates.EndUpdate;
  FSourceDirectories.EndUpdate;
end;

procedure TLazPackage.Clear;
var
  i: Integer;
begin
  // break used-by dependencies
  while FFirstUsedByDependency<>nil do
    FFirstUsedByDependency.RequiredPackage:=nil;
  // break and free removed dependencies
  while FFirstRemovedDependency<>nil do
    DeleteRemovedDependency(FFirstRemovedDependency);
  // break and free required dependencies
  while FFirstRequiredDependency<>nil do
    DeleteRequiredDependency(FFirstRequiredDependency);
  FAuthor:='';
  FAutoInstall:=pitNope;
  for i:=FComponents.Count-1 downto 0 do Components[i].Free;
  FComponents.Clear;
  FCompilerOptions.Clear;
  FDescription:='';
  FDirectory:='';
  FVersion.Clear;
  FFilename:='';
  for i:=FRemovedFiles.Count-1 downto 0 do RemovedFiles[i].Free;
  FRemovedFiles.Clear;
  for i:=FFiles.Count-1 downto 0 do Files[i].Free;
  FFiles.Clear;
  FIconFile:='';
  FInstalled:=pitNope;
  FName:='';
  FPackageType:=lptRunAndDesignTime;
  FRegistered:=false;
  FUsageOptions.Clear;
  UpdateSourceDirectories;
  // set some nice start values
  if not (lpfDestroying in FFlags) then begin
    FFlags:=[lpfAutoIncrementVersionOnBuild,lpfAutoUpdate];
    fCompilerOptions.UnitOutputDirectory:='lib'+PathDelim;
    FUsageOptions.UnitPath:='$(PkgOutDir)';
  end else begin
    FFlags:=[lpfDestroying];
  end;
end;

procedure TLazPackage.UpdateSourceDirectories;
var
  Cnt: Integer;
  i: Integer;
begin
  fSourceDirectories.Clear;
  Cnt:=FFiles.Count;
  for i:=0 to Cnt-1 do
    fSourceDirectories.AddFilename(Files[i].Directory);
end;

procedure TLazPackage.VersionChanged(Sender: TObject);
begin
  inherited VersionChanged(Sender);
  FDefineTemplates.PackageIDChanged;
  Modified:=true;
end;

procedure TLazPackage.SourceDirectoriesChanged(Sender: TObject);
begin
  FDefineTemplates.SourceDirectoriesChanged;
end;

procedure TLazPackage.LockModified;
begin
  inc(FModifiedLock);
end;

procedure TLazPackage.UnlockModified;
begin
  if FModifiedLock<=0 then
    RaiseException('TLazPackage.UnlockModified');
  dec(FModifiedLock);
end;

procedure TLazPackage.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var
  FileVersion: integer;
  OldFilename: String;

  procedure LoadFiles(const ThePath: string; List: TList);
  var
    i: Integer;
    NewCount: Integer;
    PkgFile: TPkgFile;
  begin
    NewCount:=XMLConfig.GetValue(ThePath+'Count',0);
    for i:=0 to NewCount-1 do begin
      PkgFile:=TPkgFile.Create(Self);
      PkgFile.LoadFromXMLConfig(XMLConfig,ThePath+'Item'+IntToStr(i+1)+'/',
                                FileVersion);
      List.Add(PkgFile);
    end;
  end;
  
  procedure LoadFlags(const ThePath: string);
  begin
    if XMLConfig.GetValue(ThePath+'AutoIncrementVersionOnBuild/Value',true) then
      Include(FFlags,lpfAutoIncrementVersionOnBuild)
    else
      Exclude(FFlags,lpfAutoIncrementVersionOnBuild);
    if XMLConfig.GetValue(ThePath+'AutoUpdate/Value',true) then
      Include(FFlags,lpfAutoUpdate)
    else
      Exclude(FFlags,lpfAutoUpdate);
  end;
  
begin
  Flags:=Flags+[lpfLoading];
  FileVersion:=XMLConfig.GetValue(Path+'Version',0);
  if FileVersion=1 then ;
  OldFilename:=Filename;
  BeginUpdate;
  Clear;
  Filename:=OldFilename;
  LockModified;
  Name:=XMLConfig.GetValue(Path+'Name/Value','');
  FAuthor:=XMLConfig.GetValue(Path+'Author/Value','');
  FCompilerOptions.LoadFromXMLConfig(XMLConfig,Path+'CompilerOptions/');
  FDescription:=XMLConfig.GetValue(Path+'Description/Value','');
  FLicense:=XMLConfig.GetValue(Path+'License/Value','');
  FVersion.LoadFromXMLConfig(XMLConfig,Path+'Version/',FileVersion);
  LoadFiles(Path+'Files/',FFiles);
  LoadFlags(Path);
  FIconFile:=XMLConfig.GetValue(Path+'IconFile/Value','');
  FName:=XMLConfig.GetValue(Path+'Name/Value','');
  OutputStateFile:=XMLConfig.GetValue(Path+'OutputStateFile/Value','');
  FPackageType:=LazPackageTypeIdentToType(XMLConfig.GetValue(Path+'Type/Value',
                                          LazPackageTypeIdents[lptRunTime]));
  LoadPkgDependencyList(XMLConfig,Path+'RequiredPkgs/',
                        FFirstRequiredDependency,pdlRequires,Self,false);
  FUsageOptions.LoadFromXMLConfig(XMLConfig,Path+'UsageOptions/');
  EndUpdate;
  Modified:=false;
  UnlockModified;
  Flags:=Flags-[lpfLoading];
end;

procedure TLazPackage.SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string
  );
  
  procedure SaveFiles(const ThePath: string; List: TList);
  var
    i: Integer;
    PkgFile: TPkgFile;
  begin
    XMLConfig.SetDeleteValue(ThePath+'Count',List.Count,0);
    for i:=0 to List.Count-1 do begin
      PkgFile:=TPkgFile(List[i]);
      PkgFile.SaveToXMLConfig(XMLConfig,ThePath+'Item'+IntToStr(i+1)+'/');
    end;
  end;
  
  procedure SaveFlags(const ThePath: string);
  begin
    XMLConfig.SetDeleteValue(ThePath+'AutoIncrementVersionOnBuild/Value',
      AutoIncrementVersionOnBuild,true);
    XMLConfig.SetDeleteValue(ThePath+'AutoUpdate/Value',AutoUpdate,true);
  end;

begin
  XMLConfig.SetDeleteValue(Path+'Name/Value',FName,'');
  XMLConfig.SetDeleteValue(Path+'Author/Value',FAuthor,'');
  FCompilerOptions.SaveToXMLConfig(XMLConfig,Path+'CompilerOptions/');
  XMLConfig.SetDeleteValue(Path+'Description/Value',FDescription,'');
  XMLConfig.SetDeleteValue(Path+'License/Value',FLicense,'');
  FVersion.SaveToXMLConfig(XMLConfig,Path+'Version/');
  SaveFiles(Path+'Files/',FFiles);
  SaveFlags(Path);
  XMLConfig.SetDeleteValue(Path+'IconFile/Value',FIconFile,'');
  XMLConfig.SetDeleteValue(Path+'Name/Value',FName,'');
  XMLConfig.SetDeleteValue(Path+'OutputStateFile/Value',OutputStateFile,'');
  XMLConfig.SetDeleteValue(Path+'Type/Value',LazPackageTypeIdents[FPackageType],
                           LazPackageTypeIdents[lptRunTime]);
  SavePkgDependencyList(XMLConfig,Path+'RequiredPkgs/',
                        FFirstRequiredDependency,pdlRequires);
  FUsageOptions.SaveToXMLConfig(XMLConfig,Path+'UsageOptions/');
  Modified:=false;
end;

function TLazPackage.IsVirtual: boolean;
begin
  Result:=(not FilenameIsAbsolute(Filename));
end;

function TLazPackage.HasDirectory: boolean;
begin
  Result:=(FDirectory<>'') and (FDirectory[length(FDirectory)]=PathDelim);
end;

procedure TLazPackage.CheckInnerDependencies;
begin
  // ToDo: make some checks like deactivating double requirements
end;

function TLazPackage.MakeSense: boolean;
begin
  Result:=false;
  if (Name='') or (not IsValidIdent(Name)) then exit;

  Result:=true;
end;

procedure TLazPackage.ShortenFilename(var ExpandedFilename: string);
var
  PkgDir: String;
  CurPath: String;
begin
  if not HasDirectory then exit;
  PkgDir:=FDirectory;
  CurPath:=copy(ExtractFilePath(ExpandedFilename),1,length(PkgDir));
  if CompareFilenames(PkgDir,CurPath)=0 then begin
    ExpandedFilename:=copy(ExpandedFilename,length(CurPath)+1,
                           length(ExpandedFilename)-length(CurPath));
  end;
end;

procedure TLazPackage.LongenFilename(var AFilename: string);
begin
  if not HasDirectory then exit;
  if not FilenameIsAbsolute(AFilename) then
    AFilename:=TrimFilename(Directory+AFilename);
end;

function TLazPackage.GetResolvedFilename: string;
begin
  Result:=ReadAllLinks(FFilename,false);
  if Result='' then Result:=FFilename;
end;

procedure TLazPackage.IterateComponentClasses(
  Event: TIterateComponentClassesEvent;
  WithUsedPackages: boolean);
var
  Cnt: Integer;
  i: Integer;
  Dependency: TPkgDependency;
begin
  // iterate through components in this package
  Cnt:=ComponentCount;
  for i:=0 to Cnt-1 do Event(Components[i]);
  // iterate through all used/required packages
  if WithUsedPackages then begin
    Dependency:=FirstRequiredDependency;
    while Dependency<>nil do begin
      if Dependency.RequiredPackage<>nil then
        Dependency.RequiredPackage.IterateComponentClasses(Event,false);
      Dependency:=Dependency.NextRequiresDependency;
    end;
  end;
end;

procedure TLazPackage.ConsistencyCheck;
begin
  CheckList(FRemovedFiles,true,true,true);
  CheckList(FFiles,true,true,true);
  CheckList(FComponents,true,true,true);
end;

function TLazPackage.IndexOfPkgComponent(PkgComponent: TPkgComponent): integer;
begin
  Result:=FComponents.IndexOf(PkgComponent);
end;

function TLazPackage.FindPkgFile(const AFilename: string;
  ResolveLinks, IgnoreRemoved: boolean): TPkgFile;
var
  TheFilename: String;
  Cnt: Integer;
  i: Integer;
begin
  Result:=nil;
  TheFilename:=AFilename;
  if ResolveLinks then begin
    TheFilename:=ReadAllLinks(TheFilename,false);
    if TheFilename='' then TheFilename:=AFilename;
  end;
  Cnt:=FileCount;
  for i:=0 to Cnt-1 do begin
    Result:=Files[i];
    if ResolveLinks then begin
      if CompareFilenames(Result.GetResolvedFilename,TheFilename)=0 then
        exit;
    end else begin
      if CompareFilenames(Result.Filename,TheFilename)=0 then
        exit;
    end;
  end;
  if not IgnoreRemoved then begin
    Cnt:=RemovedFilesCount;
    for i:=0 to Cnt-1 do begin
      Result:=RemovedFiles[i];
      if ResolveLinks then begin
        if CompareFilenames(Result.GetResolvedFilename,TheFilename)=0 then
          exit;
      end else begin
        if CompareFilenames(Result.Filename,TheFilename)=0 then
          exit;
      end;
    end;
  end;
  Result:=nil;
end;

function TLazPackage.FindUnit(const TheUnitName: string;
  IgnoreRemoved: boolean): TPkgFile;
var
  Cnt: Integer;
  i: Integer;
begin
  if TheUnitName<>'' then begin
    Cnt:=FileCount;
    for i:=0 to Cnt-1 do begin
      Result:=Files[i];
      if AnsiCompareText(Result.UnitName,TheUnitName)=0 then exit;
    end;
    if not IgnoreRemoved then begin
      Cnt:=RemovedFilesCount;
      for i:=0 to Cnt-1 do begin
        Result:=RemovedFiles[i];
        if AnsiCompareText(Result.UnitName,TheUnitName)=0 then exit;
      end;
    end;
  end;
  Result:=nil;
end;

function TLazPackage.FindRemovedPkgFile(const AFilename: string): TPkgFile;
var
  Cnt: Integer;
  i: Integer;
begin
  Cnt:=RemovedFilesCount;
  for i:=0 to Cnt-1 do begin
    Result:=RemovedFiles[i];
    if CompareFilenames(Result.Filename,AFilename)=0 then exit;
  end;
  Result:=nil;
end;

function TLazPackage.FindDependencyByName(const PkgName: string
  ): TPkgDependency;
begin
  Result:=FindDependencyByNameInList(FFirstRequiredDependency,pdlRequires,
                                     PkgName);
end;

function TLazPackage.RequiredDepByIndex(Index: integer): TPkgDependency;
begin
  Result:=GetDependencyWithIndex(FFirstRequiredDependency,pdlRequires,Index);
end;

function TLazPackage.RemovedDepByIndex(Index: integer): TPkgDependency;
begin
  Result:=GetDependencyWithIndex(FFirstRemovedDependency,pdlRequires,Index);
end;

function TLazPackage.UsedByDepByIndex(Index: integer): TPkgDependency;
begin
  Result:=GetDependencyWithIndex(FFirstUsedByDependency,pdlUsedBy,Index);
end;

function TLazPackage.AddFile(const NewFilename, NewUnitName: string;
  NewFileType: TPkgFileType; NewFlags: TPkgFileFlags;
  CompPriorityCat: TComponentPriorityCategory): TPkgFile;
begin
  Result:=FindRemovedPkgFile(NewFilename);
  if Result=nil then
    Result:=TPkgFile.Create(Self)
  else begin
    FRemovedFiles.Remove(Result);
    Result.Removed:=false;
  end;
  with Result do begin
    Filename:=NewFilename;
    UnitName:=NewUnitName;
    FileType:=NewFileType;
    Flags:=NewFlags;
    ComponentPriority:=ComponentPriorityNormal;
    ComponentPriority.Category:=CompPriorityCat;
  end;
  FFiles.Add(Result);
end;

procedure TLazPackage.RemoveFile(PkgFile: TPkgFile);
begin
  FFiles.Remove(PkgFile);
  FRemovedFiles.Add(PkgFile);
  PkgFile.Removed:=true;
  Modified:=true;
end;

procedure TLazPackage.UnremovePkgFile(PkgFile: TPkgFile);
begin
  FFiles.Add(PkgFile);
  FRemovedFiles.Remove(PkgFile);
  PkgFile.Removed:=false;
end;

procedure TLazPackage.RemoveRemovedDependency(Dependency: TPkgDependency);
begin
  Dependency.RemoveFromList(FFirstRemovedDependency,pdlRequires);
  Dependency.Removed:=false;
end;

procedure TLazPackage.AddRequiredDependency(Dependency: TPkgDependency);
begin
  Dependency.AddToList(FFirstRequiredDependency,pdlRequires);
  Dependency.Owner:=Self;
  Modified:=true;
end;

procedure TLazPackage.RemoveRequiredDependency(Dependency: TPkgDependency);
begin
  Dependency.RemoveFromList(FFirstRequiredDependency,pdlRequires);
  Dependency.RequiredPackage:=nil;
  Dependency.AddToList(FFirstRemovedDependency,pdlRequires);
  Dependency.Removed:=true;
  Modified:=true;
end;

procedure TLazPackage.DeleteRequiredDependency(Dependency: TPkgDependency);
begin
  Dependency.RequiredPackage:=nil;
  Dependency.RemoveFromList(FFirstRequiredDependency,pdlRequires);
  Dependency.Free;
end;

procedure TLazPackage.DeleteRemovedDependency(Dependency: TPkgDependency);
begin
  Dependency.RequiredPackage:=nil;
  Dependency.RemoveFromList(FFirstRemovedDependency,pdlRequires);
  Dependency.Free;
end;

procedure TLazPackage.MoveRequiredDependencyUp(Dependency: TPkgDependency);
begin
  Dependency.MoveUpInList(FFirstRequiredDependency,pdlRequires);
end;

procedure TLazPackage.MoveRequiredDependencyDown(Dependency: TPkgDependency);
begin
  Dependency.MoveDownInList(FFirstRequiredDependency,pdlRequires);
end;

function TLazPackage.CreateDependencyForThisPkg: TPkgDependency;
begin
  Result:=TPkgDependency.Create;
  with Result do begin
    PackageName:=Self.Name;
    MinVersion.Assign(Version);
    Flags:=[pdfMinVersion];
  end;
end;

function TLazPackage.AddComponent(PkgFile: TPkgFile; const Page: string;
  TheComponentClass: TComponentClass): TPkgComponent;
begin
  Result:=TPkgComponent.Create(PkgFile,TheComponentClass,Page);
end;

procedure TLazPackage.AddPkgComponent(APkgComponent: TPkgComponent);
begin
  FComponents.Add(APkgComponent);
end;

procedure TLazPackage.RemovePkgComponent(APkgComponent: TPkgComponent);
begin
  FComponents.Remove(APkgComponent);
end;

function TLazPackage.Requires(APackage: TLazPackage): boolean;
begin
  Result:=FindCompatibleDependencyInList(FFirstRequiredDependency,pdlRequires,
                  APackage)<>nil;
end;

procedure TLazPackage.AddUsedByDependency(Dependency: TPkgDependency);
begin
  Dependency.AddToList(FFirstUsedByDependency,pdlUsedBy);
  if Dependency.HoldPackage then
    inc(FHoldPackageCount);
end;

procedure TLazPackage.RemoveUsedByDependency(Dependency: TPkgDependency);
begin
  Dependency.RemoveFromList(FFirstUsedByDependency,pdlUsedBy);
  if Dependency.HoldPackage then
    dec(FHoldPackageCount);
end;

procedure TLazPackage.ChangeID(const NewName: string; NewVersion: TPkgVersion);
begin
  Version.Assign(NewVersion);
  Name:=NewName;
end;

procedure TLazPackage.GetAllRequiredPackages(var List: TList);
begin
  if Assigned(OnGetAllRequiredPackages) then
    OnGetAllRequiredPackages(FirstRequiredDependency,List);
end;

procedure TLazPackage.GetInheritedCompilerOptions(var OptionsList: TList);
var
  PkgList: TList; // list of TLazPackage
begin
  PkgList:=nil;
  GetAllRequiredPackages(PkgList);
  OptionsList:=GetUsageOptionsList(PkgList);
  PkgList.Free;
end;

function TLazPackage.GetCompileSourceFilename: string;
begin
  Result:=ChangeFileExt(ExtractFilename(Filename),'.pas');
end;

function TLazPackage.GetOutputDirectory: string;
begin
  if HasDirectory then begin
    Result:=CompilerOptions.ParsedOpts.GetParsedValue(pcosOutputDir);
  end else
    Result:='';
end;

function TLazPackage.GetStateFilename: string;
begin
  Result:=GetOutputDirectory
          +ChangeFileExt(GetCompileSourceFilename,'.compiled');
end;

function TLazPackage.GetSrcFilename: string;
begin
  Result:=FDirectory+GetCompileSourceFilename;
end;

function TLazPackage.GetCompilerFilename: string;
begin
  Result:=CompilerOptions.ParsedOpts.GetParsedValue(pcosCompilerPath);
end;

function TLazPackage.GetUnitPath(RelativeToBaseDir: boolean): string;
begin
  Result:=CompilerOptions.GetUnitPath(RelativeToBaseDir);
end;

function TLazPackage.GetIncludePath(RelativeToBaseDir: boolean): string;
begin
  Result:=CompilerOptions.GetIncludePath(RelativeToBaseDir);
end;

function TLazPackage.NeedsDefineTemplates: boolean;
begin
  if IsVirtual or AutoCreated or (lpfDestroying in Flags) or (Name='') then
    Result:=false
  else
    Result:=true;
end;

{ TPkgComponent }

procedure TPkgComponent.SetPkgFile(const AValue: TPkgFile);
begin
  if FPkgFile=AValue then exit;
  if (FPkgFile<>nil) then PkgFile.RemovePkgComponent(Self);
  FPkgFile:=AValue;
  if (FPkgFile<>nil) then PkgFile.AddPkgComponent(Self);
end;

constructor TPkgComponent.Create(ThePkgFile: TPkgFile;
  TheComponentClass: TComponentClass; const ThePageName: string);
begin
  inherited Create(TheComponentClass,ThePageName);
  PkgFile:=ThePkgFile;
end;

destructor TPkgComponent.Destroy;
begin
  PkgFile:=nil;
  if fIconLoaded then FIcon.Free;
  inherited Destroy;
end;

function TPkgComponent.GetUnitName: string;
begin
  Result:=PkgFile.UnitName;
end;

function TPkgComponent.GetPriority: TComponentPriority;
begin
  Result:=PkgFile.ComponentPriority;
end;

procedure TPkgComponent.ConsistencyCheck;
begin
  inherited ConsistencyCheck;
  if FPkgFile=nil then
    RaiseGDBException('TIDEComponent.ConsistencyCheck FPkgFile=nil');
  if FPkgFile.LazPackage=nil then
    RaiseGDBException('TIDEComponent.ConsistencyCheck FPkgFile.LazPackage=nil');
  if FPkgFile.LazPackage.IndexOfPkgComponent(Self)<0 then
    RaiseGDBException('TIDEComponent.ConsistencyCheck FPkgFile.LazPackage.IndexOfPkgComponent(Self)<0');
  if PkgFile.FComponents=nil then
    RaiseGDBException('TIDEComponent.ConsistencyCheck PkgFile.FComponents=nil');
  if PkgFile.FComponents.IndexOf(Self)<0 then
    RaiseGDBException('TIDEComponent.ConsistencyCheck PkgFile.FComponents.IndexOf(Self)<0');
end;

function TPkgComponent.Icon: TBitmap;
begin
  if not fIconLoaded then begin
    fIcon:=GetIconCopy;
    fIconLoaded:=true;
  end;
  Result:=FIcon;
end;

function TPkgComponent.GetIconCopy: TBitMap;
var
  ResName: string;
  res: TLResource;
begin
  Result:=TPixmap.Create;
  Result.TransparentColor:=clWhite;
  ResName:=ComponentClass.ClassName;
  res:=LazarusResources.Find(ResName);
  if (res<>nil) and (res.Value<>'') and (res.ValueType='XPM') then begin
    Result.LoadFromLazarusResource(ResName);
  end else begin
    Result.LoadFromLazarusResource('default');
  end;
end;

function TPkgComponent.HasIcon: boolean;
begin
  Result:=Page.PageName<>'';
end;

function TPkgComponent.CanBeCreatedInDesigner: boolean;
begin
  Result:=(not PkgFile.Removed);
end;

{ TLazPackageID }

procedure TLazPackageID.SetName(const AValue: string);
begin
  if FName=AValue then exit;
  FName:=AValue;
  UpdateIDAsString;
end;

constructor TLazPackageID.Create;
begin
  FVersion:=TPkgVersion.Create;
  FVersion.OnChange:=@VersionChanged;
end;

destructor TLazPackageID.Destroy;
begin
  FreeThenNil(FVersion);
  inherited Destroy;
end;

procedure TLazPackageID.UpdateIDAsString;
begin
  FIDAsString:=Version.AsString;
  if FIDAsString<>'' then
    FIDAsString:=Name+' '+FIDAsString
  else
    FIDAsString:=FIDAsString;
end;

procedure TLazPackageID.VersionChanged(Sender: TObject);
begin
  UpdateIDAsString;
end;

function TLazPackageID.StringToID(const s: string): boolean;
var
  IdentEndPos: Integer;
  StartPos: Integer;
begin
  Result:=false;
  IdentEndPos:=1;
  while (IdentEndPos<=length(s))
  and (s[IdentEndPos] in ['a'..'z','A'..'Z','0'..'9'])
  do
    inc(IdentEndPos);
  if IdentEndPos=1 then exit;
  StartPos:=IdentEndPos;
  while (StartPos<=length(s)) and (s[StartPos]=' ') do inc(StartPos);
  if StartPos=IdentEndPos then exit;
  if not Version.ReadString(copy(s,StartPos,length(s))) then exit;
  Name:=copy(s,1,IdentEndPos-1);
  Result:=true;
end;

function TLazPackageID.Compare(PackageID2: TLazPackageID): integer;
begin
  Result:=AnsiCompareText(Name,PackageID2.Name);
  if Result<>0 then exit;
  Result:=Version.Compare(PackageID2.Version);
end;

procedure TLazPackageID.AssignID(Source: TLazPackageID);
begin
  Name:=Source.Name;
  Version.Assign(Source.Version);
end;

{ TPkgCompilerOptions }

procedure TPkgCompilerOptions.SetLazPackage(const AValue: TLazPackage);
begin
  if FLazPackage=AValue then exit;
  FLazPackage:=AValue;
end;

procedure TPkgCompilerOptions.SetModified(const NewValue: boolean);
begin
  inherited SetModified(NewValue);
  if Modified and (LazPackage<>nil) then LazPackage.Modified:=true;
end;

procedure TPkgCompilerOptions.SetCustomOptions(const AValue: string);
begin
  if CustomOptions=AValue then exit;
  InvalidateOptions;
  inherited SetCustomOptions(AValue);
end;

procedure TPkgCompilerOptions.SetIncludeFiles(const AValue: string);
begin
  if IncludeFiles=AValue then exit;
  InvalidateOptions;
  inherited SetIncludeFiles(AValue);
end;

procedure TPkgCompilerOptions.SetLibraries(const AValue: string);
begin
  if Libraries=AValue then exit;
  InvalidateOptions;
  inherited SetLibraries(AValue);
end;

procedure TPkgCompilerOptions.SetLinkerOptions(const AValue: string);
begin
  if LinkerOptions=AValue then exit;
  InvalidateOptions;
  inherited SetLinkerOptions(AValue);
end;

procedure TPkgCompilerOptions.SetObjectPath(const AValue: string);
begin
  if ObjectPath=AValue then exit;
  InvalidateOptions;
  inherited SetObjectPath(AValue);
end;

procedure TPkgCompilerOptions.SetSrcPath(const AValue: string);
begin
  if SrcPath=AValue then exit;
  InvalidateOptions;
  inherited SetSrcPath(AValue);
end;

procedure TPkgCompilerOptions.SetOtherUnitFiles(const AValue: string);
begin
  if OtherUnitFiles=AValue then exit;
  InvalidateOptions;
  inherited SetOtherUnitFiles(AValue);
end;

procedure TPkgCompilerOptions.SetUnitOutputDir(const AValue: string);
begin
  if UnitOutputDirectory=AValue then exit;
  InvalidateOptions;
  inherited SetUnitOutputDir(AValue);
  LazPackage.DefineTemplates.OutputDirectoryChanged;
end;

constructor TPkgCompilerOptions.Create(ThePackage: TLazPackage);
begin
  inherited Create(ThePackage);
  fLazPackage:=ThePackage;
end;

procedure TPkgCompilerOptions.Clear;
begin
  inherited Clear;
end;

procedure TPkgCompilerOptions.GetInheritedCompilerOptions(var OptionsList: TList
  );
begin
  LazPackage.GetInheritedCompilerOptions(OptionsList);
end;

function TPkgCompilerOptions.GetOwnerName: string;
begin
  Result:=LazPackage.IDAsString;
end;

procedure TPkgCompilerOptions.InvalidateOptions;
begin
  LazPackage.UsageOptions.ParsedOpts.InvalidateAll;
end;

function TPkgCompilerOptions.GetDefaultMainSourceFileName: string;
begin
  Result:=LazPackage.GetCompileSourceFilename;
  if Result='' then
    Result:=inherited GetDefaultMainSourceFileName;
end;

function TPkgCompilerOptions.CreateTargetFilename(
  const MainSourceFileName: string): string;
begin
  Result:='';
end;

{ TPkgAdditionalCompilerOptions }

procedure TPkgAdditionalCompilerOptions.SetLazPackage(const AValue: TLazPackage
  );
begin
  if FLazPackage=AValue then exit;
  FLazPackage:=AValue;
end;

procedure TPkgAdditionalCompilerOptions.SetCustomOptions(const AValue: string);
begin
  if AValue=CustomOptions then exit;
  inherited SetCustomOptions(AValue);
  LazPackage.Modified:=true;
end;

procedure TPkgAdditionalCompilerOptions.SetIncludePath(const AValue: string);
begin
  if AValue=IncludePath then exit;
  inherited SetIncludePath(AValue);
  LazPackage.Modified:=true;
end;

procedure TPkgAdditionalCompilerOptions.SetLibraryPath(const AValue: string);
begin
  if AValue=LibraryPath then exit;
  inherited SetLibraryPath(AValue);
  LazPackage.Modified:=true;
end;

procedure TPkgAdditionalCompilerOptions.SetLinkerOptions(const AValue: string);
begin
  if AValue=LinkerOptions then exit;
  inherited SetLinkerOptions(AValue);
  LazPackage.Modified:=true;
end;

procedure TPkgAdditionalCompilerOptions.SetObjectPath(const AValue: string);
begin
  if AValue=ObjectPath then exit;
  inherited SetObjectPath(AValue);
  LazPackage.Modified:=true;
end;

procedure TPkgAdditionalCompilerOptions.SetUnitPath(const AValue: string);
begin
  if AValue=UnitPath then exit;
  inherited SetUnitPath(AValue);
  LazPackage.Modified:=true;
end;

constructor TPkgAdditionalCompilerOptions.Create(ThePackage: TLazPackage);
begin
  inherited Create(ThePackage);
  FLazPackage:=ThePackage;
end;

function TPkgAdditionalCompilerOptions.GetOwnerName: string;
begin
  Result:=LazPackage.IDAsString;
end;

{ TLazPackageDefineTemplates }

constructor TLazPackageDefineTemplates.Create(OwnerPackage: TLazPackage);
begin
  FLazPackage:=OwnerPackage;
end;

destructor TLazPackageDefineTemplates.Destroy;
begin
  Clear;
  fLastSourceDirectories.Free;
  inherited Destroy;
end;

procedure TLazPackageDefineTemplates.Clear;
begin
  if FMain<>nil then begin
    fLastSourceDirectories.Clear;
    CodeToolBoss.DefineTree.RemoveDefineTemplate(FMain);
    FMain:=nil;
    FOutputDir:=nil;
    FOutPutSrcPath:=nil;
    fLastOutputDirSrcPathIDAsString:='';
    FFlags:=FFlags+[pdtIDChanged,pdtOutputDirChanged,pdtSourceDirsChanged];
  end;
end;

procedure TLazPackageDefineTemplates.BeginUpdate;
begin
  inc(FUpdateLock);
end;

procedure TLazPackageDefineTemplates.EndUpdate;
begin
  if FUpdateLock=0 then RaiseException('TLazPackageDefineTemplates.EndUpdate');
  dec(FUpdateLock);
  if FUpdateLock=0 then begin
    if pdtIDChanged in FFlags then PackageIDChanged;
    if pdtSourceDirsChanged in FFlags then SourceDirectoriesChanged;
    if pdtOutputDirChanged in FFlags then OutputDirectoryChanged;
  end;
end;

procedure TLazPackageDefineTemplates.PackageIDChanged;
begin
  if FUpdateLock>0 then begin
    Include(FFlags,pdtIDChanged);
    exit;
  end;
  Exclude(FFlags,pdtIDChanged);
  UpdateMain;
  UpdateDefinesForOutputDirectory;
  UpdateDefinesForSourceDirectories;
end;

procedure TLazPackageDefineTemplates.SourceDirectoriesChanged;
begin
  if FUpdateLock>0 then begin
    Include(FFlags,pdtSourceDirsChanged);
    exit;
  end;
  Exclude(FFlags,pdtSourceDirsChanged);
  UpdateDefinesForSourceDirectories;
  CodeToolBoss.DefineTree.ClearCache;
end;

procedure TLazPackageDefineTemplates.OutputDirectoryChanged;
begin
  if FUpdateLock>0 then begin
    Include(FFlags,pdtOutputDirChanged);
    exit;
  end;
  Exclude(FFlags,pdtOutputDirChanged);
  UpdateDefinesForOutputDirectory;
  CodeToolBoss.DefineTree.ClearCache;
end;

procedure TLazPackageDefineTemplates.AllChanged;
begin
  PackageIDChanged;
  SourceDirectoriesChanged;
  OutputDirectoryChanged;
end;

procedure TLazPackageDefineTemplates.UpdateMain;
begin
  if not LazPackage.NeedsDefineTemplates then exit;
  // update the package block define template (the container for all other
  // define templates of the package)
  if FMain=nil then begin
    FMain:=CreatePackageTemplateWithID(LazPackage.IDAsString);
    FMain.SetDefineOwner(LazPackage,false);
    FMain.SetFlags([dtfAutoGenerated],[],false);
  end else
    FMain.Name:=LazPackage.IDAsString;
  // ClearCache is here unnessary, because it is only a block
end;

procedure TLazPackageDefineTemplates.UpdateDefinesForOutputDirectory;
begin
  if not LazPackage.NeedsDefineTemplates then exit;
  if FMain=nil then UpdateMain;

  if FOutputDir=nil then begin
    FOutputDir:=TDefineTemplate.Create(PkgOutputDirDefTemplName,
      'Output directory','',LazPackage.GetOutputDirectory,da_Directory);
    FOutputDir.SetDefineOwner(LazPackage,false);
    FOutputDir.SetFlags([dtfAutoGenerated],[],false);
    FMain.AddChild(FOutputDir);
  end;

  if (FOutPutSrcPath=nil)
  or (fLastOutputDirSrcPathIDAsString<>LazPackage.IDAsString) then begin
    fLastOutputDirSrcPathIDAsString:=LazPackage.IDAsString;
    FOutputSrcPath:=TDefineTemplate.Create('CompiledSrcPath',
      'CompiledSrcPath addition',CompiledSrcPathMacroName,
      '$PkgSrcPath('+fLastOutputDirSrcPathIDAsString+');'
        +'$('+CompiledSrcPathMacroName+')',
      da_Define);
    FOutputSrcPath.SetDefineOwner(LazPackage,false);
    FOutputSrcPath.SetFlags([dtfAutoGenerated],[],false);
    CodeToolBoss.DefineTree.ReplaceChild(FOutputDir,FOutputSrcPath,
      FOutputSrcPath.Name);
  end;
end;

procedure TLazPackageDefineTemplates.UpdateDefinesForSourceDirectories;
var
  NewSourceDirs: TStringList;
  i: Integer;
  SrcDirDefTempl: TDefineTemplate;
  UnitPathDefTempl: TDefineTemplate;
  IncPathDefTempl: TDefineTemplate;
  IDHasChanged: Boolean;
begin
  if not LazPackage.NeedsDefineTemplates then exit;

  // quick check if something has changed
  IDHasChanged:=fLastSourceDirsIDAsString<>LazPackage.IDAsString;
  if (fLastSourceDirectories<>nil)
  and (fLastSourceDirStamp=LazPackage.SourceDirectories.TimeStamp)
  and (not IDHasChanged) then
    exit;
  fLastSourceDirStamp:=LazPackage.SourceDirectories.TimeStamp;
  fLastSourceDirsIDAsString:=LazPackage.IDAsString;

  NewSourceDirs:=LazPackage.SourceDirectories.CreateFileList;
  try
    // real check if something has changed
    if (fLastSourceDirectories<>nil)
    and (NewSourceDirs.Count=fLastSourceDirectories.Count)
    and (not IDHasChanged) then begin
      i:=NewSourceDirs.Count-1;
      while (i>=0)
      and (CompareFilenames(NewSourceDirs[i],fLastSourceDirectories[i])=0) do
        dec(i);
      if i<0 then exit;
    end;
    
    // clear old define templates
    if fLastSourceDirectories<>nil then begin
      for i:=0 to fLastSourceDirectories.Count-1 do begin
        SrcDirDefTempl:=TDefineTemplate(fLastSourceDirectories.Objects[i]);
        SrcDirDefTempl.Unbind;
        SrcDirDefTempl.Free;
      end;
      fLastSourceDirectories.Clear;
    end else
      fLastSourceDirectories:=TStringList.Create;
      
    // build source directory define templates
    fLastSourceDirectories.Assign(NewSourceDirs);
    if (FMain=nil) and (fLastSourceDirectories.Count>0) then UpdateMain;
    for i:=0 to fLastSourceDirectories.Count-1 do begin
      // create directory template
      SrcDirDefTempl:=TDefineTemplate.Create('Source Directory '+IntToStr(i+1),
        fLastSourceDirectories[i],'',fLastSourceDirectories[i],da_Directory);
      fLastSourceDirectories.Objects[i]:=SrcDirDefTempl;
      // create unit path template for this directory
      UnitPathDefTempl:=TDefineTemplate.Create('UnitPath','Unit Path',
        '#UnitPath','$(#UnitPath);$PkgUnitPath('+LazPackage.IDAsString+')',
        da_Define);
      SrcDirDefTempl.AddChild(UnitPathDefTempl);
      // create include path template for this directory
      IncPathDefTempl:=TDefineTemplate.Create('IncPath','Include Path',
        '#IncPath','$(#IncPath);$PkgIncPath('+LazPackage.IDAsString+')',
        da_Define);
      SrcDirDefTempl.AddChild(IncPathDefTempl);
      SrcDirDefTempl.SetDefineOwner(LazPackage,false);
      SrcDirDefTempl.SetFlags([dtfAutoGenerated],[],false);
      // add directory
      FMain.AddChild(SrcDirDefTempl);
    end;
    CodeToolBoss.DefineTree.ClearCache;

  finally
    NewSourceDirs.Free;
  end;
end;

initialization
  PackageDependencies:=TAVLTree.Create(@ComparePkgDependencyNames);

finalization
  FreeThenNil(PackageDependencies);

end.

