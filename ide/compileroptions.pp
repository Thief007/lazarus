{ /***************************************************************************
                      compileroptions.pp  -  Lazarus IDE unit
                      ---------------------------------------
                   Compiler options sets the switches for the project
                   file for the FPC compiler.


                   Initial Revision  : Sat May 10 23:15:32 CST 1999


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
}
unit CompilerOptions;

{$mode objfpc}
{$H+}

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}

interface

uses
  Classes, SysUtils, FileUtil, LCLProc,
  Laz_XMLCfg, ProjectIntf,
  IDEProcs, LazConf, TransferMacros;

type

  { TGlobalCompilerOptions - compiler options overrides }

  TGlobalCompilerOptions = class
  private
    FTargetCPU: string;
    FTargetOS: string;
    procedure SetTargetCPU(const AValue: string);
    procedure SetTargetOS(const AValue: string);
  public
    property TargetCPU: string read FTargetCPU write SetTargetCPU;
    property TargetOS: string read FTargetOS write SetTargetOS;
  end;


type
  TInheritedCompilerOption = (
    icoUnitPath,
    icoIncludePath,
    icoObjectPath,
    icoLibraryPath,
    icoSrcPath,
    icoLinkerOptions,
    icoCustomOptions
    );
  TInheritedCompilerOptions = set of TInheritedCompilerOption;
  
  TInheritedCompOptsStrings = array[TInheritedCompilerOption] of string;

const
  icoAllSearchPaths = [icoUnitPath,icoIncludePath,icoObjectPath,icoLibraryPath,
                       icoSrcPath];
  
type
  { TParsedCompilerOptions }
  
  TParsedCompilerOptString = (
    pcosBaseDir,      // the base directory for the relative paths
    pcosUnitPath,     // search path for pascal units
    pcosIncludePath,  // search path for pascal include files
    pcosObjectPath,   // search path for .o files
    pcosLibraryPath,  // search path for libraries
    pcosSrcPath,      // additional search path for pascal source files
    pcosLinkerOptions,// additional linker options
    pcosCustomOptions,// additional options
    pcosOutputDir,    // the output directory
    pcosCompilerPath, // the filename of the compiler
    pcosDebugPath     // additional debug search path
    );
  TParsedCompilerOptStrings = set of TParsedCompilerOptString;
  

const
  ParsedCompilerSearchPaths = [pcosUnitPath,pcosIncludePath,pcosObjectPath,
                               pcosLibraryPath,pcosSrcPath,pcosDebugPath];
  ParsedCompilerFilenames = [pcosCompilerPath];
  ParsedCompilerDirectories = [pcosOutputDir];
  ParsedCompilerFiles =
    ParsedCompilerSearchPaths+ParsedCompilerFilenames+ParsedCompilerDirectories;

type
  TLocalSubstitutionEvent = function(const s: string): string of object;

  TParsedCompilerOptions = class
  private
    FInvalidateGraphOnChange: boolean;
    FOnLocalSubstitute: TLocalSubstitutionEvent;
  public
    UnparsedValues: array[TParsedCompilerOptString] of string;
    ParsedValues: array[TParsedCompilerOptString] of string;
    ParsedStamp: array[TParsedCompilerOptString] of integer;
    constructor Create;
    function GetParsedValue(Option: TParsedCompilerOptString): string;
    procedure SetUnparsedValue(Option: TParsedCompilerOptString;
                               const NewValue: string);
    procedure Clear;
    procedure InvalidateAll;
    procedure InvalidateFiles;
  public
    property OnLocalSubstitute: TLocalSubstitutionEvent read FOnLocalSubstitute
                                                       write FOnLocalSubstitute;
    property InvalidateGraphOnChange: boolean read FInvalidateGraphOnChange
                                              write FInvalidateGraphOnChange;
  end;

  TParseStringEvent =
    function(Options: TParsedCompilerOptions;
             const UnparsedValue: string): string of object;


  { TBaseCompilerOptions }
  
  TCompilerCmdLineOption = (
    ccloNoLinkerOpts,  // exclude linker options
    ccloAddVerboseAll,  // add -va
    ccloDoNotAppendOutFileOption // do not add -o option
    );
  TCompilerCmdLineOptions = set of TCompilerCmdLineOption;
  
  TCompileReason = (crCompile, crBuild, crRun);
  TCompileReasons = set of TCompileReason;
const
  crAll = [crCompile, crBuild, crRun];
  
type
  TCompilationTool = class
  public
    Command: string;
    ScanForFPCMessages: boolean;
    ScanForMakeMessages: boolean;
    ShowAllMessages: boolean;
    procedure Clear; virtual;
    function IsEqual(Params: TCompilationTool): boolean; virtual;
    procedure Assign(Src: TCompilationTool); virtual;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                                DoSwitchPathDelims: boolean); virtual;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string); virtual;
  end;
  TCompilationToolClass = class of TCompilationTool;

  TBaseCompilerOptionsClass = class of TBaseCompilerOptions;
  TBaseCompilerOptions = class(TLazCompilerOptions)
  private
    FBaseDirectory: string;
    FDefaultMakeOptionsFlags: TCompilerCmdLineOptions;
    fInheritedOptions: TInheritedCompOptsStrings;
    fInheritedOptParseStamps: integer;
    fInheritedOptGraphStamps: integer;
    fLoaded: Boolean;
    fOptionsString: String;
    FParsedOpts: TParsedCompilerOptions;
    fTargetFilename: string;
    fXMLFile: String;
    FXMLConfig: TXMLConfig;

    // Compilation
    fCompilerPath: String;
    fExecuteBefore: TCompilationTool;
    fExecuteAfter: TCompilationTool;
  protected
    procedure SetBaseDirectory(const AValue: string); override;
    procedure SetCompilerPath(const AValue: String); override;
    procedure SetCustomOptions(const AValue: string); override;
    procedure SetIncludeFiles(const AValue: String); override;
    procedure SetLibraries(const AValue: String); override;
    procedure SetLinkerOptions(const AValue: String); override;
    procedure SetOtherUnitFiles(const AValue: String); override;
    procedure SetUnitOutputDir(const AValue: string); override;
    procedure SetObjectPath(const AValue: string); override;
    procedure SetSrcPath(const AValue: string); override;
    procedure SetDebugPath(const AValue: string); override;
    procedure SetTargetCPU(const AValue: string); override;
    procedure SetTargetProc(const AValue: Integer); override;
    procedure SetTargetOS(const AValue: string); override;
    procedure SetModified(const AValue: boolean); override;
  protected
    procedure LoadTheCompilerOptions(const Path: string); virtual;
    procedure SaveTheCompilerOptions(const Path: string); virtual;
    procedure ClearInheritedOptions;
    procedure SetDefaultMakeOptionsFlags(const AValue: TCompilerCmdLineOptions);
  public
    constructor Create(const AOwner: TObject); override;
    constructor Create(const AOwner: TObject; const AToolClass: TCompilationToolClass);
    destructor Destroy; override;
    procedure Clear; virtual;

    procedure LoadFromXMLConfig(AXMLConfig: TXMLConfig; const Path: string);
    procedure SaveToXMLConfig(AXMLConfig: TXMLConfig; const Path: string);
    
    procedure LoadCompilerOptions(UseExistingFile: Boolean);
    procedure SaveCompilerOptions(UseExistingFile: Boolean);
    procedure Assign(Source: TPersistent); override;
    function IsEqual(CompOpts: TBaseCompilerOptions): boolean; virtual;
    
    function MakeOptionsString(Globals: TGlobalCompilerOptions;
                               Flags: TCompilerCmdLineOptions): String;
    function MakeOptionsString(const MainSourceFileName: string;
                               Globals: TGlobalCompilerOptions;
                               Flags: TCompilerCmdLineOptions): String; virtual;
    function GetXMLConfigPath: String; virtual;
    function CreateTargetFilename(const MainSourceFileName: string): string; virtual;
    procedure GetInheritedCompilerOptions(var OptionsList: TList); virtual;
    function GetOwnerName: string; virtual;
    function GetInheritedOption(Option: TInheritedCompilerOption;
                                RelativeToBaseDir: boolean): string; virtual;
    function GetDefaultMainSourceFileName: string; virtual;
    function NeedsLinkerOpts: boolean;
    function GetUnitPath(RelativeToBaseDir: boolean): string;
    function GetIncludePath(RelativeToBaseDir: boolean): string;
    function GetSrcPath(RelativeToBaseDir: boolean): string;
    function GetLibraryPath(RelativeToBaseDir: boolean): string;
    function GetUnitOutPath(RelativeToBaseDir: boolean): string;
    function GetParsedPath(Option: TParsedCompilerOptString;
                           InheritedOption: TInheritedCompilerOption;
                           RelativeToBaseDir: boolean): string;
    function ShortenPath(const SearchPath: string;
                               MakeAlwaysRelative: boolean): string;
    function GetCustomOptions: string;
    function GetEffectiveLCLWidgetType: string;
  public
    { Properties }
    property ParsedOpts: TParsedCompilerOptions read FParsedOpts;
    property BaseDirectory: string read FBaseDirectory write SetBaseDirectory;
    property TargetFilename: String read fTargetFilename write fTargetFilename;
    property DefaultMakeOptionsFlags: TCompilerCmdLineOptions
                 read FDefaultMakeOptionsFlags write SetDefaultMakeOptionsFlags;

    property XMLFile: String read fXMLFile write fXMLFile;
    property XMLConfigFile: TXMLConfig read FXMLConfig write FXMLConfig;
    property Loaded: Boolean read fLoaded write fLoaded;

   { // search paths:
    property IncludeFiles: String read fIncludeFiles write SetIncludeFiles;
    property Libraries: String read fLibraries write SetLibraries;
    property OtherUnitFiles: String read fOtherUnitFiles write SetOtherUnitFiles;
    property ObjectPath: string read FObjectPath write SetObjectPath;
    property SrcPath: string read FSrcPath write SetSrcPath;
    property UnitOutputDirectory: string read fUnitOutputDir write SetUnitOutputDir;
    property DebugPath: string read FDebugPath write SetDebugPath;
    property LCLWidgetType: string read fLCLWidgetType write fLCLWidgetType;

    // parsing:
    property AssemblerStyle: Integer read fAssemblerStyle write fAssemblerStyle;
    property D2Extensions: Boolean read fD2Ext write fD2Ext;
    property CStyleOperators: Boolean read fCStyleOp write fCStyleOp;
    property IncludeAssertionCode: Boolean 
                         read fIncludeAssertionCode write fIncludeAssertionCode;
    property DelphiCompat: Boolean read fDelphiCompat write fDelphiCompat;
    property AllowLabel: Boolean read fAllowLabel write fAllowLabel;
    property UseAnsiStrings: Boolean read fUseAnsiStr write fUseAnsiStr;
    property CPPInline: Boolean read fCPPInline write fCPPInline;
    property CStyleMacros: Boolean read fCMacros write fCMacros;
    property TPCompatible: Boolean read fTPCompat write fTPCompat;
    property GPCCompat: Boolean read fGPCCompat write fGPCCompat;
    property InitConstructor: Boolean read fInitConst write fInitConst;
    property StaticKeyword: Boolean read fStaticKwd write fStaticKwd;

    // code generation:
    property UnitStyle: Integer read fUnitStyle write fUnitStyle;
    property IOChecks: Boolean read fIOChecks write fIOChecks;
    property RangeChecks: Boolean read fRangeChecks write fRangeChecks;
    property OverflowChecks: Boolean read fOverflowChecks write fOverflowChecks;
    property StackChecks: Boolean read fStackChecks write fStackChecks;
    property EmulatedFloatOpcodes: boolean read FEmulatedFloatOpcodes
                                           write FEmulatedFloatOpcodes;
    property HeapSize: Integer read fHeapSize write fHeapSize;
    property VerifyObjMethodCall: boolean read FEmulatedFloatOpcodes
                                          write FEmulatedFloatOpcodes;
    property Generate: TCompilationGenerateCode read fGenerate write fGenerate;
    property TargetCPU: string read fTargetCPU write SetTargetCPU; // general type
    property TargetProcessor: Integer read fTargetProc write SetTargetProc; // specific
    property TargetOS: string read fTargetOS write SetTargetOS;
    property VariablesInRegisters: Boolean read fVarsInReg write fVarsInReg;
    property UncertainOptimizations: Boolean read fUncertainOpt write fUncertainOpt;
    property OptimizationLevel: Integer read fOptLevel write fOptLevel;

    // linking:
    property GenerateDebugInfo: Boolean read fGenDebugInfo write fGenDebugInfo;
    property GenerateDebugDBX: Boolean read fGenDebugDBX write fGenDebugDBX;
    property UseLineInfoUnit: Boolean read fUseLineInfoUnit write fUseLineInfoUnit;
    property UseHeaptrc: Boolean read fUseHeaptrc write fUseHeaptrc;
    property UseValgrind: Boolean read fUseValgrind write fUseValgrind;
    property GenGProfCode: Boolean read fGenGProfCode write fGenGProfCode;
    property StripSymbols: Boolean read fStripSymbols write fStripSymbols;
    property LinkStyle: Integer read fLinkStyle write fLinkStyle;
    property PassLinkerOptions: Boolean read fPassLinkerOpt write fPassLinkerOpt;
    property LinkerOptions: String read fLinkerOptions write SetLinkerOptions;
    property Win32GraphicApp: boolean read FWin32GraphicApp write FWin32GraphicApp;

    // messages:
    property ShowErrors: Boolean read fShowErrors write fShowErrors;
    property ShowWarn: Boolean read fShowWarn write fShowWarn;
    property ShowNotes: Boolean read fShowNotes write fShowNotes;
    property ShowHints: Boolean read fShowHints write fShowHints;
    property ShowGenInfo: Boolean read fShowGenInfo write fShowGenInfo;
    property ShowLineNum: Boolean read fShowLineNum write fShowLineNum;
    property ShowAll: Boolean read fShowAll write fShowAll;
    property ShowAllProcsOnError: Boolean
      read fShowAllProcsOnError write fShowAllProcsOnError;
    property ShowDebugInfo: Boolean read fShowDebugInfo write fShowDebugInfo;
    property ShowUsedFiles: Boolean read fShowUsedFiles write fShowUsedFiles;
    property ShowTriedFiles: Boolean read fShowTriedFiles write fShowTriedFiles;
    property ShowDefMacros: Boolean read fShowDefMacros write fShowDefMacros;
    property ShowCompProc: Boolean read fShowCompProc write fShowCompProc;
    property ShowCond: Boolean read fShowCond write fShowCond;
    property ShowNothing: Boolean read fShowNothing write fShowNothing;
    property ShowHintsForUnusedUnitsInMainSrc: Boolean
      read fShowHintsForUnusedUnitsInMainSrc write fShowHintsForUnusedUnitsInMainSrc;
    property WriteFPCLogo: Boolean read fWriteFPCLogo write fWriteFPCLogo;
    property StopAfterErrCount: integer
      read fStopAfterErrCount write fStopAfterErrCount;

    // other
    property DontUseConfigFile: Boolean read fDontUseConfigFile
                                        write fDontUseConfigFile;
    property AdditionalConfigFile: Boolean read fAdditionalConfigFile
                                           write fAdditionalConfigFile;
    property ConfigFilePath: String read fConfigFilePath write fConfigFilePath;
    property CustomOptions: string read fCustomOptions write SetCustomOptions;}

    // compilation
    property CompilerPath: String read fCompilerPath write SetCompilerPath;
    property ExecuteBefore: TCompilationTool read fExecuteBefore;
    property ExecuteAfter: TCompilationTool read fExecuteAfter;
  end;
  
  
  { TAdditionalCompilerOptions
  
    Additional Compiler options are used by packages to define, what a project
    or a package or the IDE needs to use the package.
  }
  
  TAdditionalCompilerOptions = class
  private
    FBaseDirectory: string;
    FCustomOptions: string;
    FIncludePath: string;
    FLibraryPath: string;
    FLinkerOptions: string;
    FObjectPath: string;
    fOwner: TObject;
    FParsedOpts: TParsedCompilerOptions;
    FUnitPath: string;
  protected
    procedure SetBaseDirectory(const AValue: string); virtual;
    procedure SetCustomOptions(const AValue: string); virtual;
    procedure SetIncludePath(const AValue: string); virtual;
    procedure SetLibraryPath(const AValue: string); virtual;
    procedure SetLinkerOptions(const AValue: string); virtual;
    procedure SetObjectPath(const AValue: string); virtual;
    procedure SetUnitPath(const AValue: string); virtual;
  public
    constructor Create(TheOwner: TObject);
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                                AdjustPathDelims: boolean);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    function GetOwnerName: string; virtual;
  public
    property Owner: TObject read fOwner;
    property UnitPath: string read FUnitPath write SetUnitPath;
    property IncludePath: string read FIncludePath write SetIncludePath;
    property ObjectPath: string read FObjectPath write SetObjectPath;
    property LibraryPath: string read FLibraryPath write SetLibraryPath;
    property LinkerOptions: string read FLinkerOptions write SetLinkerOptions;
    property CustomOptions: string read FCustomOptions write SetCustomOptions;
    property BaseDirectory: string read FBaseDirectory write SetBaseDirectory;
    property ParsedOpts: TParsedCompilerOptions read FParsedOpts;
  end;


//  { TCompilerOptions }

  TCompilerOptions = TBaseCompilerOptions;
//  TCompilerOptions = class(TBaseCompilerOptions)
//  public
//    procedure Clear; override;
//  end;
  
  
const
  CompilationGenerateCodeNames: array [TCompilationGenerateCode] of string = (
    'Normal', 'Faster', 'Smaller');

type
  TCompilerGraphStampIncreasedEvent = procedure of object;

var
  CompilerParseStamp: integer;
  CompilerGraphStamp: integer;
  OnParseString: TParseStringEvent;
  CompilerGraphStampIncreased: TCompilerGraphStampIncreasedEvent;

procedure IncreaseCompilerParseStamp;
procedure IncreaseCompilerGraphStamp;
function ParseString(Options: TParsedCompilerOptions;
                     const UnparsedValue: string): string;
                     
procedure GatherInheritedOptions(AddOptionsList: TList;
  var InheritedOptionStrings: TInheritedCompOptsStrings);
function InheritedOptionsToCompilerParameters(
  var InheritedOptionStrings: TInheritedCompOptsStrings;
  Flags: TCompilerCmdLineOptions): string;
function MergeLinkerOptions(const OldOptions, AddOptions: string): string;
function MergeCustomOptions(const OldOptions, AddOptions: string): string;
function ConvertSearchPathToCmdLine(const switch, paths: String): String;
function ConvertOptionsToCmdLine(const Delim, Switch, OptionStr: string): string;

function CompilationGenerateCodeNameToType(
  const Name: string): TCompilationGenerateCode;

function LoadXMLCompileReasons(const AConfig: TXMLConfig;
  const APath: String; const DefaultReasons: TCompileReasons): TCompileReasons;
procedure SaveXMLCompileReasons(const AConfig: TXMLConfig; const APath: String;
  const AFlags, DefaultFlags: TCompileReasons);

implementation

const
  CompilerOptionsVersion = 2;
  Config_Filename = 'compileroptions.xml';
  MaxParseStamp = $7fffffff;
  MinParseStamp = -$7fffffff;
  InvalidParseStamp = MinParseStamp-1;

procedure IncreaseCompilerParseStamp;
begin
  if CompilerParseStamp<MaxParseStamp then
    inc(CompilerParseStamp)
  else
    CompilerParseStamp:=MinParseStamp;
end;

procedure IncreaseCompilerGraphStamp;
begin
  if CompilerGraphStamp<MaxParseStamp then
    inc(CompilerGraphStamp)
  else
    CompilerGraphStamp:=MinParseStamp;
  if Assigned(CompilerGraphStampIncreased) then
    CompilerGraphStampIncreased();
end;

function ParseString(Options: TParsedCompilerOptions;
                     const UnparsedValue: string): string;
begin
  Result:=OnParseString(Options,UnparsedValue);
end;

procedure GatherInheritedOptions(AddOptionsList: TList;
  var InheritedOptionStrings: TInheritedCompOptsStrings);
var
  i: Integer;
  AddOptions: TAdditionalCompilerOptions;
begin
  if AddOptionsList<>nil then begin
    for i:=0 to AddOptionsList.Count-1 do begin
      AddOptions:=TAdditionalCompilerOptions(AddOptionsList[i]);
      if (not (AddOptions is TAdditionalCompilerOptions)) then continue;

      // unit search path
      InheritedOptionStrings[icoUnitPath]:=
        MergeSearchPaths(InheritedOptionStrings[icoUnitPath],
                     AddOptions.ParsedOpts.GetParsedValue(pcosUnitPath));
      // include search path
      InheritedOptionStrings[icoIncludePath]:=
        MergeSearchPaths(InheritedOptionStrings[icoIncludePath],
                     AddOptions.ParsedOpts.GetParsedValue(pcosIncludePath));
      // src search path
      InheritedOptionStrings[icoSrcPath]:=
        MergeSearchPaths(InheritedOptionStrings[icoSrcPath],
                     AddOptions.ParsedOpts.GetParsedValue(pcosSrcPath));
      // object search path
      InheritedOptionStrings[icoObjectPath]:=
        MergeSearchPaths(InheritedOptionStrings[icoObjectPath],
                     AddOptions.ParsedOpts.GetParsedValue(pcosObjectPath));
      // library search path
      InheritedOptionStrings[icoLibraryPath]:=
        MergeSearchPaths(InheritedOptionStrings[icoLibraryPath],
                     AddOptions.ParsedOpts.GetParsedValue(pcosLibraryPath));
      // linker options
      InheritedOptionStrings[icoLinkerOptions]:=
        MergeLinkerOptions(InheritedOptionStrings[icoLinkerOptions],
                     AddOptions.ParsedOpts.GetParsedValue(pcosLinkerOptions));
      // custom options
      InheritedOptionStrings[icoCustomOptions]:=
        MergeCustomOptions(InheritedOptionStrings[icoCustomOptions],
                     AddOptions.ParsedOpts.GetParsedValue(pcosCustomOptions));
    end;
  end;
end;

function InheritedOptionsToCompilerParameters(
  var InheritedOptionStrings: TInheritedCompOptsStrings;
  Flags: TCompilerCmdLineOptions): string;
var
  CurLinkerOpts: String;
  CurIncludePath: String;
  CurLibraryPath: String;
  CurObjectPath: String;
  CurUnitPath: String;
  CurCustomOptions: String;
begin
  Result:='';
  
  // inherited Linker options
  if (not (ccloNoLinkerOpts in Flags)) then begin
    CurLinkerOpts:=InheritedOptionStrings[icoLinkerOptions];
    if CurLinkerOpts<>'' then
      Result := Result + ' ' + ConvertOptionsToCmdLine(' ','-k', CurLinkerOpts);
  end;

  // include path
  CurIncludePath:=InheritedOptionStrings[icoIncludePath];
  if (CurIncludePath <> '') then
    Result := Result + ' ' + ConvertSearchPathToCmdLine('-Fi', CurIncludePath);

  // library path
  if (not (ccloNoLinkerOpts in Flags)) then begin
    CurLibraryPath:=InheritedOptionStrings[icoLibraryPath];
    if (CurLibraryPath <> '') then
      Result := Result + ' ' + ConvertSearchPathToCmdLine('-Fl', CurLibraryPath);
  end;

  // object path
  CurObjectPath:=InheritedOptionStrings[icoObjectPath];
  if (CurObjectPath <> '') then
    Result := Result + ' ' + ConvertSearchPathToCmdLine('-Fo', CurObjectPath);

  // unit path
  CurUnitPath:=InheritedOptionStrings[icoUnitPath];
  // always add the current directory to the unit path, so that the compiler
  // checks for changed files in the directory
  CurUnitPath:=CurUnitPath+';.';
  Result := Result + ' ' + ConvertSearchPathToCmdLine('-Fu', CurUnitPath);

  // custom options
  CurCustomOptions:=InheritedOptionStrings[icoCustomOptions];
  if CurCustomOptions<>'' then
    Result := Result + ' ' +  SpecialCharsToSpaces(CurCustomOptions);
end;

function MergeLinkerOptions(const OldOptions, AddOptions: string): string;
begin
  Result:=OldOptions;
  if AddOptions='' then exit;
  if (OldOptions<>'') and (OldOptions[length(OldOptions)]<>' ')
  and (AddOptions[1]<>' ') then
    Result:=Result+' '+AddOptions
  else
    Result:=Result+AddOptions;
end;

function MergeCustomOptions(const OldOptions, AddOptions: string): string;
begin
  Result:=OldOptions;
  if AddOptions='' then exit;
  if (OldOptions<>'') and (OldOptions[length(OldOptions)]<>' ')
  and (AddOptions[1]<>' ') then
    Result:=Result+' '+AddOptions
  else
    Result:=Result+AddOptions;
end;

function ConvertSearchPathToCmdLine(
  const switch, paths: String): String;
var
  tempsw, SS, Delim: String;
  M: Integer;
begin
  Delim := ';';

  if (switch = '') or (paths = '') then
  begin
    Result := '';
    Exit;
  end;

  tempsw := '';
  SS := paths;

  repeat
    M := Pos (Delim, SS);

    if (M = 0) then
    begin
      if (tempsw <> '') then
        tempsw := tempsw + ' ';
      tempsw := tempsw + PrepareCmdLineOption(switch + SS);
      Break;
    end
    else if (M = 1) then
    begin
      SS := Copy (SS, M + 1, Length(SS));
      Continue;
    end
    else
    begin
      if (tempsw <> '') then
        tempsw := tempsw + ' ';
      tempsw := tempsw + PrepareCmdLineOption(switch + Copy (SS, 1, M - 1));
      SS := Copy (SS, M + 1, Length(SS));
    end;
  until (SS = '') or (M = 0);

  Result := tempsw;
end;

function ConvertOptionsToCmdLine(const Delim, Switch,
  OptionStr: string): string;
var Startpos, EndPos: integer;
begin
  Result:='';
  StartPos:=1;
  while StartPos<=length(OptionStr) do begin
    EndPos:=StartPos;
    while (EndPos<=length(OptionStr)) and (pos(OptionStr[EndPos],Delim)=0) do
      inc(EndPos);
    if EndPos>StartPos then begin
      Result:=Result+' '+Switch+copy(OptionStr,StartPos,EndPos-StartPos);
    end;
    StartPos:=EndPos+1;
  end;
end;

function CompilationGenerateCodeNameToType(
  const Name: string): TCompilationGenerateCode;
begin
  for Result:=Low(TCompilationGenerateCode) to High(TCompilationGenerateCode) do
    if AnsiCompareText(Name,CompilationGenerateCodeNames[Result])=0 then exit;
  Result:=cgcNormalCode;
end;

function LoadXMLCompileReasons(const AConfig: TXMLConfig; const APath: String;
  const DefaultReasons: TCompileReasons): TCompileReasons;
begin
  Result := [];
  if AConfig.GetValue(APath+'Compile',crCompile in DefaultReasons)
  then Include(Result, crCompile);
  if AConfig.GetValue(APath+'Build',crBuild in DefaultReasons)
  then Include(Result, crBuild);
  if AConfig.GetValue(APath+'Run',crRun in DefaultReasons)
  then Include(Result, crRun);
end;

procedure SaveXMLCompileReasons(const AConfig: TXMLConfig; const APath: String;
  const AFlags, DefaultFlags: TCompileReasons);
begin
  AConfig.SetDeleteValue(APath+'Compile', crCompile in AFlags, crCompile in DefaultFlags);
  AConfig.SetDeleteValue(APath+'Build', crBuild in AFlags, crBuild in DefaultFlags);
  AConfig.SetDeleteValue(APath+'Run', crRun in AFlags, crRun in DefaultFlags);
end;


{ TBaseCompilerOptions }

{------------------------------------------------------------------------------
  TBaseCompilerOptions Constructor
------------------------------------------------------------------------------}
constructor TBaseCompilerOptions.Create(const AOwner: TObject;
  const AToolClass: TCompilationToolClass);
begin
  inherited Create(AOwner);
  FParsedOpts := TParsedCompilerOptions.Create;
  FExecuteBefore := AToolClass.Create;
  FExecuteAfter := AToolClass.Create;
  Clear;
end;

constructor TBaseCompilerOptions.Create(const AOwner: TObject);
begin
  Create(AOwner, TCompilationTool);
end;

{------------------------------------------------------------------------------
  TBaseCompilerOptions Destructor
------------------------------------------------------------------------------}
destructor TBaseCompilerOptions.Destroy;
begin
  FreeThenNil(fExecuteBefore);
  FreeThenNil(fExecuteAfter);
  FreeThenNil(FParsedOpts);
  inherited Destroy;
end;

{------------------------------------------------------------------------------
  procedure TBaseCompilerOptions.LoadFromXMLConfig(AXMLConfig: TXMLConfig;
    const Path: string);
------------------------------------------------------------------------------}
procedure TBaseCompilerOptions.LoadFromXMLConfig(AXMLConfig: TXMLConfig;
  const Path: string);
begin
  XMLConfigFile := AXMLConfig;
  LoadTheCompilerOptions(Path);
end;

{------------------------------------------------------------------------------
  procedure TBaseCompilerOptions.SaveToXMLConfig(XMLConfig: TXMLConfig;
    const Path: string);
------------------------------------------------------------------------------}
procedure TBaseCompilerOptions.SaveToXMLConfig(AXMLConfig: TXMLConfig;
  const Path: string);
begin
  XMLConfigFile := AXMLConfig;
  SaveTheCompilerOptions(Path);
end;

{------------------------------------------------------------------------------
  TfrmCompilerOptions LoadCompilerOptions
------------------------------------------------------------------------------}
procedure TBaseCompilerOptions.LoadCompilerOptions(UseExistingFile: Boolean);
var
  confPath: String;
begin
  if (UseExistingFile and (XMLConfigFile <> nil)) then
  begin
    LoadTheCompilerOptions('CompilerOptions');
  end
  else
  begin
    confPath := GetXMLConfigPath;
    try
      XMLConfigFile := TXMLConfig.Create(SetDirSeparators(confPath));
      LoadTheCompilerOptions('CompilerOptions');
      XMLConfigFile.Free;
      XMLConfigFile := nil;
    except
      on E: Exception do begin
        DebugLn('TBaseCompilerOptions.LoadCompilerOptions '+Classname+' '+E.Message);
      end;
    end;
  end;
  fLoaded := true;
end;

{------------------------------------------------------------------------------
  procedure TBaseCompilerOptions.SetIncludeFiles(const AValue: String);
------------------------------------------------------------------------------}
procedure TBaseCompilerOptions.SetIncludeFiles(const AValue: String);
var
  NewValue: String;
begin
  NewValue:=ShortenPath(AValue,false);
  if NewValue<>AValue then
  if fIncludeFiles=NewValue then exit;
  fIncludeFiles:=NewValue;
  ParsedOpts.SetUnparsedValue(pcosIncludePath,fIncludeFiles);
end;

procedure TBaseCompilerOptions.SetCompilerPath(const AValue: String);
begin
  if fCompilerPath=AValue then exit;
  fCompilerPath:=AValue;
  ParsedOpts.SetUnparsedValue(pcosCompilerPath,fCompilerPath);
end;

procedure TBaseCompilerOptions.SetDefaultMakeOptionsFlags(
  const AValue: TCompilerCmdLineOptions);
begin
  if FDefaultMakeOptionsFlags=AValue then exit;
  FDefaultMakeOptionsFlags:=AValue;
end;

procedure TBaseCompilerOptions.SetSrcPath(const AValue: string);
var
  NewValue: String;
begin
  NewValue:=ShortenPath(AValue,false);
  if FSrcPath=NewValue then exit;
  FSrcPath:=NewValue;
  ParsedOpts.SetUnparsedValue(pcosSrcPath,FSrcPath);
end;

procedure TBaseCompilerOptions.SetDebugPath(const AValue: string);
var
  NewValue: String;
begin
  NewValue:=ShortenPath(AValue,false);
  if fDebugPath=NewValue then exit;
  fDebugPath:=NewValue;
  ParsedOpts.SetUnparsedValue(pcosDebugPath,fDebugPath);
end;

procedure TBaseCompilerOptions.SetTargetCPU(const AValue: string);
begin
  if fTargetCPU=AValue then exit;
  fTargetCPU:=AValue;
  IncreaseCompilerParseStamp;
end;

procedure TBaseCompilerOptions.SetTargetProc(const AValue: Integer);
begin
  if fTargetProc=AValue then exit;
  fTargetProc:=AValue;
  IncreaseCompilerParseStamp;
end;

procedure TBaseCompilerOptions.SetTargetOS(const AValue: string);
begin
  if fTargetOS=AValue then exit;
  fTargetOS:=AValue;
  IncreaseCompilerParseStamp;
end;

procedure TBaseCompilerOptions.SetBaseDirectory(const AValue: string);
begin
  if FBaseDirectory=AValue then exit;
  FBaseDirectory:=AValue;
  ParsedOpts.SetUnparsedValue(pcosBaseDir,FBaseDirectory);
end;

procedure TBaseCompilerOptions.SetCustomOptions(const AValue: string);
begin
  if fCustomOptions=AValue then exit;
  fCustomOptions:=AValue;
  ParsedOpts.SetUnparsedValue(pcosCustomOptions,fCustomOptions);
end;

procedure TBaseCompilerOptions.SetLibraries(const AValue: String);
var
  NewValue: String;
begin
  NewValue:=ShortenPath(AValue,false);
  if fLibraries=NewValue then exit;
  fLibraries:=NewValue;
  ParsedOpts.SetUnparsedValue(pcosLibraryPath,fLibraries);
end;

procedure TBaseCompilerOptions.SetLinkerOptions(const AValue: String);
begin
  if fLinkerOptions=AValue then exit;
  fLinkerOptions:=AValue;
  ParsedOpts.SetUnparsedValue(pcosLinkerOptions,fLinkerOptions);
end;

procedure TBaseCompilerOptions.SetOtherUnitFiles(const AValue: String);
var
  NewValue: String;
begin
  NewValue:=ShortenPath(AValue,false);
  if fOtherUnitFiles=NewValue then exit;
  fOtherUnitFiles:=NewValue;
  ParsedOpts.SetUnparsedValue(pcosUnitPath,fOtherUnitFiles);
end;

procedure TBaseCompilerOptions.SetUnitOutputDir(const AValue: string);
begin
  if fUnitOutputDir=AValue then exit;
  fUnitOutputDir:=AValue;
  ParsedOpts.SetUnparsedValue(pcosOutputDir,fUnitOutputDir);
end;

procedure TBaseCompilerOptions.SetObjectPath(const AValue: string);
var
  NewValue: String;
begin
  NewValue:=ShortenPath(AValue,false);
  if FObjectPath=NewValue then exit;
  FObjectPath:=NewValue;
  ParsedOpts.SetUnparsedValue(pcosObjectPath,FObjectPath);
end;

{------------------------------------------------------------------------------
  TfrmCompilerOptions LoadTheCompilerOptions
------------------------------------------------------------------------------}
procedure TBaseCompilerOptions.LoadTheCompilerOptions(const Path: string);
var
  p: String;
  PathDelimChanged: boolean;
  FileVersion: Integer;
  
  function f(const Filename: string): string;
  begin
    Result:=SwitchPathDelims(Filename,PathDelimChanged);
  end;
  
  procedure ReadGenerate;
  var
    i: Integer;
  begin
    if FileVersion<2 then begin
      i:=XMLConfigFile.GetValue(p+'Generate/Value', 1);
      if i=1 then
        Generate:=cgcFasterCode
      else
        Generate:=cgcSmallerCode
    end else begin
      Generate:=CompilationGenerateCodeNameToType(
                  XMLConfigFile.GetValue(p+'Generate/Value',
                                  CompilationGenerateCodeNames[cgcNormalCode]));
    end;
  end;

begin
  { Load the compiler options from the XML file }
  p:=Path;
  PathDelimChanged:=XMLConfigFile.GetValue(p+'PathDelim/Value', '/')<>PathDelim;
  FileVersion:=XMLConfigFile.GetValue(p+'Version/Value', 0);

  { Target }
  p:=Path+'Target/';
  TargetFilename := XMLConfigFile.GetValue(p+'Filename/Value', '');

  { SearchPaths }
  p:=Path+'SearchPaths/';
  IncludeFiles := f(XMLConfigFile.GetValue(p+'IncludeFiles/Value', ''));
  Libraries := f(XMLConfigFile.GetValue(p+'Libraries/Value', ''));
  OtherUnitFiles := f(XMLConfigFile.GetValue(p+'OtherUnitFiles/Value', ''));
  UnitOutputDirectory := f(XMLConfigFile.GetValue(p+'UnitOutputDirectory/Value', ''));
  LCLWidgetType := XMLConfigFile.GetValue(p+'LCLWidgetType/Value', '');
  ObjectPath := f(XMLConfigFile.GetValue(p+'ObjectPath/Value', ''));
  SrcPath := f(XMLConfigFile.GetValue(p+'SrcPath/Value', ''));

  { Parsing }
  p:=Path+'Parsing/';
  AssemblerStyle := XMLConfigFile.GetValue(p+'Style/Value', 0);
  D2Extensions := XMLConfigFile.GetValue(p+'SymantecChecking/D2Extensions/Value', true);
  CStyleOperators := XMLConfigFile.GetValue(p+'SymantecChecking/CStyleOperator/Value', true);
  IncludeAssertionCode := XMLConfigFile.GetValue(p+'SymantecChecking/IncludeAssertionCode/Value', false);
  AllowLabel := XMLConfigFile.GetValue(p+'SymantecChecking/AllowLabel/Value', true);
  CPPInline := XMLConfigFile.GetValue(p+'SymantecChecking/CPPInline/Value', true);
  CStyleMacros := XMLConfigFile.GetValue(p+'SymantecChecking/CStyleMacros/Value', false);
  TPCompatible := XMLConfigFile.GetValue(p+'SymantecChecking/TPCompatible/Value', false);
  InitConstructor := XMLConfigFile.GetValue(p+'SymantecChecking/InitConstructor/Value', false);
  StaticKeyword := XMLConfigFile.GetValue(p+'SymantecChecking/StaticKeyword/Value', false);
  DelphiCompat := XMLConfigFile.GetValue(p+'SymantecChecking/DelphiCompat/Value', false);
  UseAnsiStrings := XMLConfigFile.GetValue(p+'SymantecChecking/UseAnsiStrings/Value', false);
  GPCCompat := XMLConfigFile.GetValue(p+'SymantecChecking/GPCCompat/Value', false);

  { CodeGeneration }
  p:=Path+'CodeGeneration/';
  UnitStyle := XMLConfigFile.GetValue(p+'UnitStyle/Value', 1);
  IOChecks := XMLConfigFile.GetValue(p+'Checks/IOChecks/Value', false);
  RangeChecks := XMLConfigFile.GetValue(p+'Checks/RangeChecks/Value', false);
  OverflowChecks := XMLConfigFile.GetValue(p+'Checks/OverflowChecks/Value', false);
  StackChecks := XMLConfigFile.GetValue(p+'Checks/StackChecks/Value', false);
  EmulatedFloatOpcodes := XMLConfigFile.GetValue(p+'EmulateFloatingPointOpCodes/Value', false);
  HeapSize := XMLConfigFile.GetValue(p+'HeapSize/Value', 0);
  VerifyObjMethodCall := XMLConfigFile.GetValue(p+'VerifyObjMethodCallValidity/Value', false);
  ReadGenerate;
  TargetProcessor := XMLConfigFile.GetValue(p+'TargetProcessor/Value', 0);
  TargetCPU := XMLConfigFile.GetValue(p+'TargetCPU/Value', '');
  VariablesInRegisters := XMLConfigFile.GetValue(p+'Optimizations/VariablesInRegisters/Value', false);
  UncertainOptimizations := XMLConfigFile.GetValue(p+'Optimizations/UncertainOptimizations/Value', false);
  OptimizationLevel := XMLConfigFile.GetValue(p+'Optimizations/OptimizationLevel/Value', 1);
  TargetOS := XMLConfigFile.GetValue(p+'TargetOS/Value', '');

  { Linking }
  p:=Path+'Linking/';
  GenerateDebugInfo := XMLConfigFile.GetValue(p+'Debugging/GenerateDebugInfo/Value', false);
  GenerateDebugDBX := XMLConfigFile.GetValue(p+'Debugging/GenerateDebugDBX/Value', false);
  UseLineInfoUnit := XMLConfigFile.GetValue(p+'Debugging/UseLineInfoUnit/Value', true);
  UseHeaptrc := XMLConfigFile.GetValue(p+'Debugging/UseHeaptrc/Value', false);
  UseValgrind := XMLConfigFile.GetValue(p+'Debugging/UseValgrind/Value', false);
  GenGProfCode := XMLConfigFile.GetValue(p+'Debugging/GenGProfCode/Value', false);
  StripSymbols := XMLConfigFile.GetValue(p+'Debugging/StripSymbols/Value', false);
  LinkStyle := XMLConfigFile.GetValue(p+'LinkStyle/Value', 1);
  PassLinkerOptions := XMLConfigFile.GetValue(p+'Options/PassLinkerOptions/Value', false);
  LinkerOptions := f(XMLConfigFile.GetValue(p+'Options/LinkerOptions/Value', ''));
  Win32GraphicApp := XMLConfigFile.GetValue(p+'Options/Win32/GraphicApplication/Value', false);

  { Messages }
  p:=Path+'Other/';
  ShowErrors := XMLConfigFile.GetValue(p+'Verbosity/ShowErrors/Value', true);
  ShowWarn := XMLConfigFile.GetValue(p+'Verbosity/ShowWarn/Value', true);
  ShowNotes := XMLConfigFile.GetValue(p+'Verbosity/ShowNotes/Value', true);
  ShowHints := XMLConfigFile.GetValue(p+'Verbosity/ShowHints/Value', true);
  ShowGenInfo := XMLConfigFile.GetValue(p+'Verbosity/ShowGenInfo/Value', true);
  ShowLineNum := XMLConfigFile.GetValue(p+'Verbosity/ShoLineNum/Value', false);
  ShowAll := XMLConfigFile.GetValue(p+'Verbosity/ShowAll/Value', false);
  ShowAllProcsOnError := XMLConfigFile.GetValue(p+'Verbosity/ShowAllProcsOnError/Value', false);
  ShowDebugInfo := XMLConfigFile.GetValue(p+'Verbosity/ShowDebugInfo/Value', false);
  ShowUsedFiles := XMLConfigFile.GetValue(p+'Verbosity/ShowUsedFiles/Value', false);
  ShowTriedFiles := XMLConfigFile.GetValue(p+'Verbosity/ShowTriedFiles/Value', false);
  ShowDefMacros := XMLConfigFile.GetValue(p+'Verbosity/ShowDefMacros/Value', false);
  ShowCompProc := XMLConfigFile.GetValue(p+'Verbosity/ShowCompProc/Value', false);
  ShowCond := XMLConfigFile.GetValue(p+'Verbosity/ShowCond/Value', false);
  ShowNothing := XMLConfigFile.GetValue(p+'Verbosity/ShowNothing/Value', false);
  ShowHintsForUnusedUnitsInMainSrc := XMLConfigFile.GetValue(p+'Verbosity/ShowHintsForUnusedUnitsInMainSrc/Value', false);
  WriteFPCLogo := XMLConfigFile.GetValue(p+'WriteFPCLogo/Value', true);
  StopAfterErrCount := XMLConfigFile.GetValue(p+'ConfigFile/StopAfterErrCount/Value', 1);

  { Other }
  p:=Path+'Other/';
  DontUseConfigFile := XMLConfigFile.GetValue(p+'ConfigFile/DontUseConfigFile/Value', false);
  AdditionalConfigFile := XMLConfigFile.GetValue(p+'ConfigFile/AdditionalConfigFile/Value', false);
  ConfigFilePath := f(XMLConfigFile.GetValue(p+'ConfigFile/ConfigFilePath/Value', './fpc.cfg'));
  CustomOptions := XMLConfigFile.GetValue(p+'CustomOptions/Value', '');

  { Compilation }
  CompilerPath := f(XMLConfigFile.GetValue(p+'CompilerPath/Value','$(CompPath)'));

  ExecuteBefore.LoadFromXMLConfig(XMLConfigFile,p+'ExecuteBefore/',PathDelimChanged);
  ExecuteAfter.LoadFromXMLConfig(XMLConfigFile,p+'ExecuteAfter/',PathDelimChanged);
end;

{------------------------------------------------------------------------------}
{  TfrmCompilerOptions SaveCompilerOptions                                     }
{------------------------------------------------------------------------------}
procedure TBaseCompilerOptions.SaveCompilerOptions(UseExistingFile: Boolean);
var
  confPath: String;
begin
  if ((UseExistingFile) and (XMLConfigFile <> nil)) then
  begin
    SaveTheCompilerOptions('CompilerOptions');
  end
  else
  begin
    confPath := GetXMLConfigPath;
    try
      XMLConfigFile := TXMLConfig.Create(SetDirSeparators(confPath));
      SaveTheCompilerOptions('CompilerOptions');
      XMLConfigFile.Free;
      XMLConfigFile := nil;
    except
      on E: Exception do begin
        DebugLn('TBaseCompilerOptions.LoadCompilerOptions '+Classname+' '+E.Message);
      end;
    end;
  end;
  fModified:=false;
end;

{------------------------------------------------------------------------------}
{  TfrmCompilerOptions SaveTheCompilerOptions                                  }
{------------------------------------------------------------------------------}
procedure TBaseCompilerOptions.SaveTheCompilerOptions(const Path: string);
var
  P: string;
begin
  { Save the compiler options to the XML file }
  p:=Path;
  XMLConfigFile.SetValue(p+'Version/Value', CompilerOptionsVersion);
  XMLConfigFile.SetDeleteValue(p+'PathDelim/Value', PathDelim, '/');

  { Target }
  p:=Path+'Target/';
  XMLConfigFile.SetDeleteValue(p+'Filename/Value', TargetFilename,'');

  { SearchPaths }
  p:=Path+'SearchPaths/';
  XMLConfigFile.SetDeleteValue(p+'IncludeFiles/Value', IncludeFiles,'');
  XMLConfigFile.SetDeleteValue(p+'Libraries/Value', Libraries,'');
  XMLConfigFile.SetDeleteValue(p+'OtherUnitFiles/Value', OtherUnitFiles,'');
  XMLConfigFile.SetDeleteValue(p+'UnitOutputDirectory/Value', UnitOutputDirectory,'');
  XMLConfigFile.SetDeleteValue(p+'LCLWidgetType/Value', LCLWidgetType,'');
  XMLConfigFile.SetDeleteValue(p+'ObjectPath/Value', ObjectPath,'');
  XMLConfigFile.SetDeleteValue(p+'SrcPath/Value', SrcPath,'');

  { Parsing }
  p:=Path+'Parsing/';
  XMLConfigFile.SetDeleteValue(p+'Style/Value', AssemblerStyle,0);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/D2Extensions/Value', D2Extensions,true);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/CStyleOperator/Value', CStyleOperators,true);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/IncludeAssertionCode/Value', IncludeAssertionCode,false);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/AllowLabel/Value', AllowLabel,true);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/CPPInline/Value', CPPInline,true);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/CStyleMacros/Value', CStyleMacros,false);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/TPCompatible/Value', TPCompatible,false);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/InitConstructor/Value', InitConstructor,false);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/StaticKeyword/Value', StaticKeyword,false);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/DelphiCompat/Value', DelphiCompat,false);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/UseAnsiStrings/Value', UseAnsiStrings,false);
  XMLConfigFile.SetDeleteValue(p+'SymantecChecking/GPCCompat/Value', GPCCompat,false);
  
  { CodeGeneration }
  p:=Path+'CodeGeneration/';
  XMLConfigFile.SetDeleteValue(p+'UnitStyle/Value', UnitStyle,1);
  XMLConfigFile.SetDeleteValue(p+'Checks/IOChecks/Value', IOChecks,false);
  XMLConfigFile.SetDeleteValue(p+'Checks/RangeChecks/Value', RangeChecks,false);
  XMLConfigFile.SetDeleteValue(p+'Checks/OverflowChecks/Value', OverflowChecks,false);
  XMLConfigFile.SetDeleteValue(p+'Checks/StackChecks/Value', StackChecks,false);
  XMLConfigFile.SetDeleteValue(p+'EmulateFloatingPointOpCodes/Value', EmulatedFloatOpcodes,false);
  XMLConfigFile.SetDeleteValue(p+'HeapSize/Value', HeapSize,0);
  XMLConfigFile.SetDeleteValue(p+'VerifyObjMethodCallValidity/Value', VerifyObjMethodCall,false);
  XMLConfigFile.SetDeleteValue(p+'Generate/Value', CompilationGenerateCodeNames[Generate],CompilationGenerateCodeNames[cgcNormalCode]);
  XMLConfigFile.SetDeleteValue(p+'TargetProcessor/Value', TargetProcessor,0);
  XMLConfigFile.SetDeleteValue(p+'TargetCPU/Value', TargetCPU,'');
  XMLConfigFile.SetDeleteValue(p+'Optimizations/VariablesInRegisters/Value', VariablesInRegisters,false);
  XMLConfigFile.SetDeleteValue(p+'Optimizations/UncertainOptimizations/Value', UncertainOptimizations,false);
  XMLConfigFile.SetDeleteValue(p+'Optimizations/OptimizationLevel/Value', OptimizationLevel,1);
  XMLConfigFile.SetDeleteValue(p+'TargetOS/Value', TargetOS,'');

  { Linking }
  p:=Path+'Linking/';
  XMLConfigFile.SetDeleteValue(p+'Debugging/GenerateDebugInfo/Value', GenerateDebugInfo,false);
  XMLConfigFile.SetDeleteValue(p+'Debugging/GenerateDebugDBX/Value', GenerateDebugDBX,false);
  XMLConfigFile.SetDeleteValue(p+'Debugging/UseLineInfoUnit/Value', UseLineInfoUnit,true);
  XMLConfigFile.SetDeleteValue(p+'Debugging/UseHeaptrc/Value', UseHeaptrc,false);
  XMLConfigFile.SetDeleteValue(p+'Debugging/UseValgrind/Value', UseValgrind,false);
  XMLConfigFile.SetDeleteValue(p+'Debugging/GenGProfCode/Value', GenGProfCode,false);
  XMLConfigFile.SetDeleteValue(p+'Debugging/StripSymbols/Value', StripSymbols,false);
  XMLConfigFile.SetDeleteValue(p+'LinkStyle/Value', LinkStyle,1);
  XMLConfigFile.SetDeleteValue(p+'Options/PassLinkerOptions/Value', PassLinkerOptions,false);
  XMLConfigFile.SetDeleteValue(p+'Options/LinkerOptions/Value', LinkerOptions,'');
  XMLConfigFile.SetDeleteValue(p+'Options/Win32/GraphicApplication/Value', Win32GraphicApp,false);

  { Messages }
  p:=Path+'Other/';
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowErrors/Value', ShowErrors,true);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowWarn/Value', ShowWarn,true);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowNotes/Value', ShowNotes,true);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowHints/Value', ShowHints,true);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowGenInfo/Value', ShowGenInfo,true);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShoLineNum/Value', ShowLineNum,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowAll/Value', ShowAll,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowAllProcsOnError/Value', ShowAllProcsOnError,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowDebugInfo/Value', ShowDebugInfo,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowUsedFiles/Value', ShowUsedFiles,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowTriedFiles/Value', ShowTriedFiles,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowDefMacros/Value', ShowDefMacros,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowCompProc/Value', ShowCompProc,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowCond/Value', ShowCond,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowNothing/Value', ShowNothing,false);
  XMLConfigFile.SetDeleteValue(p+'Verbosity/ShowHintsForUnusedUnitsInMainSrc/Value', ShowHintsForUnusedUnitsInMainSrc,false);
  XMLConfigFile.SetDeleteValue(p+'WriteFPCLogo/Value', WriteFPCLogo,true);
  XMLConfigFile.SetDeleteValue(p+'ConfigFile/StopAfterErrCount/Value', StopAfterErrCount,1);

  { Other }
  p:=Path+'Other/';
  XMLConfigFile.SetDeleteValue(p+'ConfigFile/DontUseConfigFile/Value', DontUseConfigFile,false);
  XMLConfigFile.SetDeleteValue(p+'ConfigFile/AdditionalConfigFile/Value', AdditionalConfigFile,false);
  XMLConfigFile.SetDeleteValue(p+'ConfigFile/ConfigFilePath/Value', ConfigFilePath,'./fpc.cfg');
  XMLConfigFile.SetDeleteValue(p+'CustomOptions/Value', CustomOptions,'');

  { Compilation }
  XMLConfigFile.SetDeleteValue(p+'CompilerPath/Value', CompilerPath,'');
  ExecuteBefore.SaveToXMLConfig(XMLConfigFile,p+'ExecuteBefore/');
  ExecuteAfter.SaveToXMLConfig(XMLConfigFile,p+'ExecuteAfter/');

  // write
  XMLConfigFile.Flush;
end;

procedure TBaseCompilerOptions.SetModified(const AValue: boolean);
begin
  if FModified=AValue then exit;
  FModified:=AValue;
  if Assigned(OnModified) then
    OnModified(Self);
end;

procedure TBaseCompilerOptions.ClearInheritedOptions;
var
  i: TInheritedCompilerOption;
begin
  fInheritedOptParseStamps:=InvalidParseStamp;
  fInheritedOptGraphStamps:=InvalidParseStamp;
  for i:=Low(TInheritedCompilerOption) to High(TInheritedCompilerOption) do
    fInheritedOptions[i]:='';
end;

{------------------------------------------------------------------------------
  TBaseCompilerOptions CreateTargetFilename
------------------------------------------------------------------------------}
function TBaseCompilerOptions.CreateTargetFilename(
  const MainSourceFileName: string): string;
  
  procedure AppendDefaultExt;
  var
    Ext: String;
  begin
    if (ExtractFileName(Result)='') or (ExtractFileExt(Result)<>'') then exit;
    if AnsiCompareText(fTargetOS, 'win32') = 0 then begin
      Result:=Result+'.exe';
      exit;
    end;
    Ext:=GetDefaultExecutableExt;
    if Ext<>'' then begin
      Result:=Result+Ext;
      exit;
    end;
  end;
  
var
  UnitOutDir: String;
  OutFilename: String;
begin
  if (TargetFilename<>'') and FilenameIsAbsolute(TargetFilename) then begin
    // fully specified target filename
    Result:=TargetFilename;
  end else begin
    // calculate output directory
    UnitOutDir:=GetUnitOutPath(false);
    if UnitOutDir='' then
      UnitOutDir:=ExtractFilePath(MainSourceFileName);
    // fpc creates lowercase executables as default
    if TargetFilename<>'' then
      OutFilename:=TargetFilename
    else
      OutFilename:=lowercase(ExtractFileNameOnly(MainSourceFileName));
    Result:=AppendPathDelim(UnitOutDir)+OutFilename;
  end;
  Result:=TrimFilename(Result);
  AppendDefaultExt;
end;

procedure TBaseCompilerOptions.GetInheritedCompilerOptions(
  var OptionsList: TList);
begin
  OptionsList:=nil;
end;

function TBaseCompilerOptions.GetOwnerName: string;
begin
  if Owner<>nil then
    Result:=Owner.ClassName
  else
    Result:='This compiler options object has no owner';
end;

{------------------------------------------------------------------------------
  function TBaseCompilerOptions.GetInheritedOption(
    Option: TInheritedCompilerOption; RelativeToBaseDir: boolean): string;
------------------------------------------------------------------------------}
function TBaseCompilerOptions.GetInheritedOption(
  Option: TInheritedCompilerOption; RelativeToBaseDir: boolean): string;
var
  OptionsList: TList;
begin
  if (fInheritedOptParseStamps<>CompilerParseStamp)
  or (fInheritedOptGraphStamps<>CompilerGraphStamp)
  then begin
    // update inherited options
    ClearInheritedOptions;
    OptionsList:=nil;
    GetInheritedCompilerOptions(OptionsList);
    if OptionsList<>nil then begin
      GatherInheritedOptions(OptionsList,fInheritedOptions);
      OptionsList.Free;
    end;
    fInheritedOptParseStamps:=CompilerParseStamp;
    fInheritedOptGraphStamps:=CompilerGraphStamp;
  end;
  Result:=fInheritedOptions[Option];
  if RelativeToBaseDir then begin
    if Option in [icoUnitPath,icoIncludePath,icoObjectPath,icoLibraryPath] then
      Result:=CreateRelativeSearchPath(Result,BaseDirectory);
  end;
end;

function TBaseCompilerOptions.GetDefaultMainSourceFileName: string;
begin
  Result:='';
end;

function TBaseCompilerOptions.NeedsLinkerOpts: boolean;
begin
  Result:=not (ccloNoLinkerOpts in fDefaultMakeOptionsFlags);
end;

function TBaseCompilerOptions.GetUnitPath(RelativeToBaseDir: boolean): string;
begin
  Result:=GetParsedPath(pcosUnitPath,icoUnitPath,RelativeToBaseDir);
end;

function TBaseCompilerOptions.GetIncludePath(RelativeToBaseDir: boolean
  ): string;
begin
  Result:=GetParsedPath(pcosIncludePath,icoIncludePath,RelativeToBaseDir);
end;

function TBaseCompilerOptions.GetSrcPath(RelativeToBaseDir: boolean): string;
begin
  Result:=GetParsedPath(pcosSrcPath,icoSrcPath,RelativeToBaseDir);
end;

function TBaseCompilerOptions.GetLibraryPath(RelativeToBaseDir: boolean
  ): string;
begin
  Result:=GetParsedPath(pcosLibraryPath,icoLibraryPath,RelativeToBaseDir);
end;

function TBaseCompilerOptions.GetUnitOutPath(RelativeToBaseDir: boolean
  ): string;
begin
  Result:=ParsedOpts.GetParsedValue(pcosOutputDir);
  if (not RelativeToBaseDir) then
    CreateAbsolutePath(Result,BaseDirectory);
end;

function TBaseCompilerOptions.GetParsedPath(Option: TParsedCompilerOptString;
  InheritedOption: TInheritedCompilerOption;
  RelativeToBaseDir: boolean): string;
var
  CurrentPath: String;
  InheritedPath: String;
begin
  // current path
  CurrentPath:=ParsedOpts.GetParsedValue(Option);
  if (not RelativeToBaseDir) then
    CreateAbsolutePath(CurrentPath,BaseDirectory);

  // inherited path
  InheritedPath:=GetInheritedOption(InheritedOption,RelativeToBaseDir);

  Result:=MergeSearchPaths(CurrentPath,InheritedPath);
end;

function TBaseCompilerOptions.GetCustomOptions: string;
var
  CurCustomOptions: String;
  InhCustomOptions: String;
begin
  // custom options
  CurCustomOptions:=ParsedOpts.GetParsedValue(pcosCustomOptions);
  // inherited custom options
  InhCustomOptions:=GetInheritedOption(icoCustomOptions,true);
  // concatenate
  if CurCustomOptions<>'' then
    Result:=CurCustomOptions+' '+InhCustomOptions
  else
    Result:=InhCustomOptions;
  if Result='' then exit;
  
  // eliminate line breaks
  Result:=SpecialCharsToSpaces(Result);
end;

function TBaseCompilerOptions.GetEffectiveLCLWidgetType: string;
begin
  Result:=LCLWidgetType;
  if (Result='') or (Result='default') then
    Result:=GetDefaultLCLWidgetType;
end;

function TBaseCompilerOptions.ShortenPath(const SearchPath: string;
  MakeAlwaysRelative: boolean): string;
begin
  Result:=TrimSearchPath(SearchPath,'');
  if MakeAlwaysRelative then
    Result:=CreateRelativeSearchPath(Result,BaseDirectory)
  else
    Result:=ShortenSearchPath(Result,BaseDirectory,BaseDirectory);
end;

{------------------------------------------------------------------------------
  TBaseCompilerOptions MakeOptionsString
------------------------------------------------------------------------------}
function TBaseCompilerOptions.MakeOptionsString(Globals: TGlobalCompilerOptions;
  Flags: TCompilerCmdLineOptions): String;
begin
  Result:=MakeOptionsString(GetDefaultMainSourceFileName,Globals,Flags);
end;

{------------------------------------------------------------------------------
  function TBaseCompilerOptions.MakeOptionsString(
    const MainSourceFilename: string;
    Globals: TGlobalCompilerOptions;
    Flags: TCompilerCmdLineOptions): String;
------------------------------------------------------------------------------}
function TBaseCompilerOptions.MakeOptionsString(
  const MainSourceFilename: string; Globals: TGlobalCompilerOptions;
  Flags: TCompilerCmdLineOptions): String;
var
  switches, tempsw: String;
  InhLinkerOpts: String;
  NewTargetFilename: String;
  CurIncludePath: String;
  CurLibraryPath: String;
  CurUnitPath: String;
  CurOutputDir: String;
  CurLinkerOptions: String;
  InhObjectPath: String;
  CurObjectPath: String;
  CurMainSrcFile: String;
  CurCustomOptions: String;
  OptimizeSwitches: String;
begin
  CurMainSrcFile:=MainSourceFileName;
  if CurMainSrcFile='' then
    CurMainSrcFile:=GetDefaultMainSourceFileName;

  switches := '';

  { Get all the options and create a string that can be passed to the compiler }
  
  { options of fpc 1.1 :

  put + after a boolean switch option to enable it, - to disable it
  -a     the compiler doesn't delete the generated assembler file
      -al        list sourcecode lines in assembler file
      -ar        list register allocation/release info in assembler file
      -at        list temp allocation/release info in assembler file
  -b     generate browser info
      -bl        generate local symbol info
  -B     build all modules
  -C<x>  code generation options:
      -CD        create also dynamic library (not supported)
      -Ce        Compilation with emulated floating point opcodes
      -Ch<n>     <n> bytes heap (between 1023 and 67107840)
      -Ci        IO-checking
      -Cn        omit linking stage
      -Co        check overflow of integer operations
      -Cr        range checking
      -CR        verify object method call validity
      -Cs<n>     set stack size to <n>
      -Ct        stack checking
      -CX        create also smartlinked library
  -d<x>  defines the symbol <x>
  -e<x>  set path to executable
  -E     same as -Cn
  -F<x>  set file names and paths:
      -FD<x>     sets the directory where to search for compiler utilities
      -Fe<x>     redirect error output to <x>
      -FE<x>     set exe/unit output path to <x>
      -Fi<x>     adds <x> to include path
      -Fl<x>     adds <x> to library path
      -FL<x>     uses <x> as dynamic linker
      -Fo<x>     adds <x> to object path
      -Fr<x>     load error message file <x>
      -Fu<x>     adds <x> to unit path
      -FU<x>     set unit output path to <x>, overrides -FE
  -g     generate debugger information:
      -gg        use gsym
      -gd        use dbx
      -gh        use heap trace unit (for memory leak debugging)
      -gl        use line info unit to show more info for backtraces
      -gc        generate checks for pointers
  -i     information
      -iD        return compiler date
      -iV        return compiler version
      -iSO       return compiler OS
      -iSP       return compiler processor
      -iTO       return target OS
      -iTP       return target processor
  -I<x>  adds <x> to include path
  -k<x>  Pass <x> to the linker
  -l     write logo
  -n     don't read the default config file
  -o<x>  change the name of the executable produced to <x>
  -pg    generate profile code for gprof (defines FPC_PROFILE)
  -P     use pipes instead of creating temporary assembler files
  -S<x>  syntax options:
      -S2        switch some Delphi 2 extensions on
      -Sc        supports operators like C (*=,+=,/= and -=)
      -Sa        include assertion code.
      -Sd        tries to be Delphi compatible
      -Se<x>     compiler stops after the <x> errors (default is 1)
      -Sg        allow LABEL and GOTO
      -Sh        Use ansistrings
      -Si        support C++ styled INLINE
      -Sm        support macros like C (global)
      -So        tries to be TP/BP 7.0 compatible
      -Sp        tries to be gpc compatible
      -Ss        constructor name must be init (destructor must be done)
      -St        allow static keyword in objects
  -s     don't call assembler and linker (only with -a)
      -st        Generate script to link on target
      -sh        Generate script to link on host
  -u<x>  undefines the symbol <x>
  -U     unit options:
      -Un        don't check the unit name
      -Ur        generate release unit files
      -Us        compile a system unit
  -v<x>  Be verbose. <x> is a combination of the following letters:
      e : Show errors (default)       d : Show debug info
      w : Show warnings               u : Show unit info
      n : Show notes                  t : Show tried/used files
      h : Show hints                  m : Show defined macros
      i : Show general info           p : Show compiled procedures
      l : Show linenumbers            c : Show conditionals
      a : Show everything             0 : Show nothing (except errors)
      b : Show all procedure          r : Rhide/GCC compatibility mode
          declarations if an error    x : Executable info (Win32 only)
          occurs
  -V     write fpcdebug.txt file with lots of debugging info
  -X     executable options:
      -Xc        link with the c library
      -Xs        strip all symbols from executable
      -XD        try to link dynamic          (defines FPC_LINK_DYNAMIC)
      -XS        try to link static (default) (defines FPC_LINK_STATIC)
      -XX        try to link smart            (defines FPC_LINK_SMART)

Processor specific options:
  -A<x>  output format:
      -Aas       assemble using GNU AS
      -Anasmcoff coff (Go32v2) file using Nasm
      -Anasmelf  elf32 (Linux) file using Nasm
      -Anasmobj  obj file using Nasm
      -Amasm     obj file using Masm (Microsoft)
      -Atasm     obj file using Tasm (Borland)
      -Acoff     coff (Go32v2) using internal writer
      -Apecoff   pecoff (Win32) using internal writer
  -R<x>  assembler reading style:
      -Ratt      read AT&T style assembler
      -Rintel    read Intel style assembler
      -Rdirect   copy assembler text directly to assembler file
  -O<x>  optimizations:
      -Og        generate smaller code
      -OG        generate faster code (default)
      -Or        keep certain variables in registers
      -Ou        enable uncertain optimizations (see docs)
      -O1        level 1 optimizations (quick optimizations)
      -O2        level 2 optimizations (-O1 + slower optimizations)
      -O3        level 3 optimizations (-O2 repeatedly, max 5 times)
      -Op<x>     target processor:
         -Op1  set target processor to 386/486
         -Op2  set target processor to Pentium/PentiumMMX (tm)
         -Op3  set target processor to PPro/PII/c6x86/K6 (tm)
  -T<x>  Target operating system:
      -TGO32V2   version 2 of DJ Delorie DOS extender
      -          3*2TWDOSX DOS 32 Bit Extender
      -TLINUX    Linux
      -Tnetware  Novell Netware Module (experimental)
      -TOS2      OS/2 2.x
      -TSUNOS    SunOS/Solaris
      -TWin32    Windows 32 Bit
  -W<x>  Win32 target options
      -WB<x>     Set Image base to Hexadecimal <x> value
      -WC        Specify console type application
      -WD        Use DEFFILE to export functions of DLL or EXE
      -WF        Specify full-screen type application (OS/2 only)
      -WG        Specify graphic type application
      -WN        Do not generate relocation code (necessary for debugging)
      -WR        Generate relocation code
  }
  
  

  { --------------- Parsing Tab ------------------- }

  { Assembler reading style  -Ratt = AT&T    -Rintel = Intel  -Rdirect = direct }
  case AssemblerStyle of
    1: switches := switches + '-Rintel';
    2: switches := switches + '-Ratt';
    3: switches := switches + '-Rdirect';
  end;
  
  { Symantec Checking
  
    -S<x>  syntax options:
      -S2        switch some Delphi 2 extensions on
      -Sc        supports operators like C (*=,+=,/= and -=)
      -sa        include assertion code.
      -Sd        tries to be Delphi compatible
      -Se<x>     compiler stops after the <x> errors (default is 1)
      -Sg        allow LABEL and GOTO
      -Sh        Use ansistrings
      -Si        support C++ styled INLINE
      -Sm        support macros like C (global)
      -So        tries to be TP/BP 7.0 compatible
      -Sp        tries to be gpc compatible
      -Ss        constructor name must be init (destructor must be done)
      -St        allow static keyword in objects

  }
  tempsw := '';

  if (D2Extensions) then
    tempsw := tempsw + '2';
  if (CStyleOperators) then
    tempsw := tempsw + 'c';
  if (IncludeAssertionCode) then
    tempsw := tempsw + 'a';
  if (DelphiCompat) then
    tempsw := tempsw + 'd';
  if (AllowLabel) then
    tempsw := tempsw + 'g';
  if (UseAnsiStrings) then
    tempsw := tempsw + 'h';
  if (CPPInline) then
    tempsw := tempsw + 'i';
  if (CStyleMacros) then
    tempsw := tempsw + 'm';
  if (TPCompatible) then
    tempsw := tempsw + 'o';
  if (GPCCompat) then
    tempsw := tempsw + 'p';
  if (InitConstructor) then
    tempsw := tempsw + 's';
  if (StaticKeyword) then
    tempsw := tempsw + 't';

  if (tempsw <> '') then begin
    tempsw := '-S' + tempsw;
    switches := switches + ' ' + tempsw;
  end;

  { TODO: Implement the following switches. They need to be added
          to the dialog. }
{
  -Un = Do not check the unit name
  -Us = Compile a system unit
}

  { ----------- Code Generation Tab --------------- }

  { UnitStyle   '' = Static     'D' = Dynamic   'X' = smart linked }
  case (UnitStyle) of
    0: ;
    1: switches := switches + ' -CD';
    2: switches := switches + ' -CX';
  end;

  { Checks }
  tempsw := '';

  if IOChecks then
    tempsw := tempsw + 'i';
  if RangeChecks then
    tempsw := tempsw + 'r';
  if OverflowChecks then
    tempsw := tempsw + 'o';
  if StackChecks then
    tempsw := tempsw + 't';
  if EmulatedFloatOpcodes then
    tempsw := tempsw + 'e';
  if VerifyObjMethodCall then
    tempsw := tempsw + 'R';

  if (tempsw <> '') then begin
    switches := switches + ' -C' + tempsw;
  end;

  { Heap Size }
  if (HeapSize > 0) then
    switches := switches + ' ' + '-Ch' + IntToStr(HeapSize);


  { TODO: Implement the following switches. They need to be added
          to the dialog. }
{
  n = Omit linking stage
  sxxx = Set stack size to xxx
}

  OptimizeSwitches:='';

  { Generate    G = faster g = smaller  }
  case (Generate) of
    cgcNormalCode: ;
    cgcFasterCode:  OptimizeSwitches := OptimizeSwitches + 'G';
    cgcSmallerCode:  OptimizeSwitches := OptimizeSwitches + 'g';
  end;

  { OptimizationLevel     1 = Level 1    2 = Level 2    3 = Level 3 }
  case (OptimizationLevel) of
    1:  OptimizeSwitches := OptimizeSwitches + '1';
    2:  OptimizeSwitches := OptimizeSwitches + '2';
    3:  OptimizeSwitches := OptimizeSwitches + '3';
  end;

  if (VariablesInRegisters) then
    OptimizeSwitches := OptimizeSwitches + 'r';
  if (UncertainOptimizations) then
    OptimizeSwitches := OptimizeSwitches + 'u';

  { TargetProcessor }
  case (TargetProcessor) of
    0:                            ; // use default
    1:  OptimizeSwitches := OptimizeSwitches + 'p1';  // 386/486
    2:  OptimizeSwitches := OptimizeSwitches + 'p2';  // Pentium/Pentium MMX
    3:  OptimizeSwitches := OptimizeSwitches + 'p3';  // PentiumPro/PII/K6
  end;

  if OptimizeSwitches<>'' then
    switches := switches + ' -O'+OptimizeSwitches;

  { Target OS
       GO32V1 = DOS and version 1 of the DJ DELORIE extender (no longer maintained).
       GO32V2 = DOS and version 2 of the DJ DELORIE extender.
       LINUX = LINUX.
       OS2 = OS/2 (2.x) using the EMX extender.
       WIN32 = Windows 32 bit.
       ... }
  { Target OS }
  if (Globals<>nil) and (Globals.TargetOS<>'') then
    switches := switches + ' -T' + Globals.TargetOS
  else if (TargetOS<>'') then
    switches := switches + ' -T' + TargetOS;
  { --------------- Linking Tab ------------------- }
  
  { Debugging }
  { Debug Info for GDB }
  if (GenerateDebugInfo) then
    switches := switches + ' -g';

  { Debug Info for DBX }
  if (GenerateDebugDBX) then
    switches := switches + ' -gd';

  { Line Numbers in Run-time Error Backtraces - Use LineInfo Unit }
  if (UseLineInfoUnit) then
    switches := switches + ' -gl';

  { Use Heaptrc Unit }
  if (UseHeaptrc) and (not (ccloNoLinkerOpts in Flags)) then
    switches := switches + ' -gh';

  { Generate code for Valgrind }
  if (UseValgrind) and (not (ccloNoLinkerOpts in Flags)) then
    switches := switches + ' -gv';

  { Generate code gprof }
  if (GenGProfCode) then
    switches := switches + ' -pg';

  { Strip Symbols }
  if (StripSymbols) and (not (ccloNoLinkerOpts in Flags)) then
    switches := switches + ' -Xs';

  { Link Style
     -XD = Link with dynamic libraries
     -XS = Link with static libraries 
     -XX = Link smart
  }
  if (not (ccloNoLinkerOpts in Flags)) then
    case (LinkStyle) of
      1:  switches := switches + ' -XD'; // dynamic
      2:  switches := switches + ' -XS'; // static
      3:  switches := switches + ' -XX -CX'; // smart
    end;

  // additional Linker options
  if PassLinkerOptions and (not (ccloNoLinkerOpts in Flags)) then begin
    CurLinkerOptions:=ParsedOpts.GetParsedValue(pcosLinkerOptions);
    if (CurLinkerOptions<>'') then
      switches := switches + ' ' + ConvertOptionsToCmdLine(' ','-k', CurLinkerOptions);
  end;

  // inherited Linker options
  if (not (ccloNoLinkerOpts in Flags)) then begin
    InhLinkerOpts:=GetInheritedOption(icoLinkerOptions,true);
    if InhLinkerOpts<>'' then
      switches := switches + ' ' + ConvertOptionsToCmdLine(' ','-k', InhLinkerOpts);
  end;
  
  if Win32GraphicApp then
    switches := switches + ' -WG';

  { ---------------- Other Tab -------------------- }

  { Verbosity }
  { The following switches will not be needed by the IDE
      x = Output some executable info (Win32 only)
      r = Rhide/GCC compatibility mode
  }
  tempsw := '';
    
  if (ShowErrors) then
    tempsw := tempsw + 'e';
  if (ShowWarn) then
    tempsw := tempsw + 'w';
  if (ShowNotes) then
    tempsw := tempsw + 'n';
  if (ShowHints) then
    tempsw := tempsw + 'h';
  if (ShowGenInfo) then
    tempsw := tempsw + 'i';
  if (ShowLineNum) then
    tempsw := tempsw + 'l';
  if (ShowAllProcsOnError) then
    tempsw := tempsw + 'b';
  if (ShowDebugInfo) then
    tempsw := tempsw + 'd';
  if (ShowUsedFiles) then
    tempsw := tempsw + 'u';
  if (ShowTriedFiles) then
    tempsw := tempsw + 't';
  if (ShowDefMacros) then
    tempsw := tempsw + 'm';
  if (ShowCompProc) then
    tempsw := tempsw + 'p';
  if (ShowCond) then
    tempsw := tempsw + 'c';

  if ShowNothing then
    tempsw := '0';

  if ShowAll or (ccloAddVerboseAll in Flags) then
    tempsw := 'a';

  if (tempsw <> '') then begin
    tempsw := '-v' + tempsw;
    switches := switches + ' ' + tempsw;
  end;

  if (StopAfterErrCount>1) then
    tempsw := tempsw + ' -Se'+IntToStr(StopAfterErrCount);


  { Write an FPC logo }
  if (WriteFPCLogo) then
    switches := switches + ' -l';

  { Ignore Config File }
  if DontUseConfigFile then
    switches := switches + ' -n';

  { Use Additional Config File     @ = yes and path }
  if (AdditionalConfigFile) and (ConfigFilePath<>'') then
    switches := switches + ' ' + PrepareCmdLineOption('@' + ConfigFilePath);


  { ------------- Search Paths ---------------- }
  
  // include path
  CurIncludePath:=GetIncludePath(true);
  if (CurIncludePath <> '') then
    switches := switches + ' ' + ConvertSearchPathToCmdLine('-Fi', CurIncludePath);

  // library path
  if (not (ccloNoLinkerOpts in Flags)) then begin
    CurLibraryPath:=GetLibraryPath(true);
    if (CurLibraryPath <> '') then
      switches := switches + ' ' + ConvertSearchPathToCmdLine('-Fl', CurLibraryPath);
  end;

  // object path
  CurObjectPath:=ParsedOpts.GetParsedValue(pcosObjectPath);
  if (CurObjectPath <> '') then
    switches := switches + ' ' + ConvertSearchPathToCmdLine('-Fo', CurObjectPath);

  // inherited object path
  InhObjectPath:=GetInheritedOption(icoObjectPath,true);
  if (InhObjectPath <> '') then
    switches := switches + ' ' + ConvertSearchPathToCmdLine('-Fo', InhObjectPath);

  // unit path
  CurUnitPath:=GetUnitPath(true);
  // always add the current directory to the unit path, so that the compiler
  // checks for changed files in the directory
  CurUnitPath:=CurUnitPath+';.';
  switches := switches + ' ' + ConvertSearchPathToCmdLine('-Fu', CurUnitPath);

  { CompilerPath - Nothing needs to be done with this one }
  
  { Unit output directory }
  if UnitOutputDirectory<>'' then
    CurOutputDir:=CreateRelativePath(ParsedOpts.GetParsedValue(pcosOutputDir),
                                     BaseDirectory)
  else
    CurOutputDir:='';
  if CurOutputDir<>'' then
    switches := switches + ' '+PrepareCmdLineOption('-FE'+CurOutputDir);

  { TODO: Implement the following switches. They need to be added
          to the dialog. }
{
     exxx = Errors file
     Lxxx = Use xxx as dynamic linker (LINUX only)
     oxxx = Object files
     rxxx = Compiler messages file
}

  { ----------------------------------------------- }

  { TODO: The following switches need to be implemented. They need to
          be added to the dialog. }
{
  -P = Use pipes instead of files when assembling
      

  -a = Delete generated assembler files
  -al = Include source code lines in assembler files as comments
  -ar = List register allocation in assembler files
  -at = List temporary allocations and deallocations in assembler files
  -Axxx = Assembler type
       o = unix coff object file using GNU assembler as
       nasmcoff = coff file using nasm assembler
       nasmonj = obj file using nasm assembler
       masm = obj file using Microsoft masm assembler
       tasm = obj file using Borland tasm assembler
       
  -B = Recompile all units even if they didn't change  ->  implemented by compiler.pp
  -b = Generate browser info
  -bl = Generate browser info, including local variables, types and procedures

  -dxxx = Define symbol name xxx (Used for conditional compiles)
  -uxxx = Undefine symbol name xxx
  
  -Ce        Compilation with emulated floating point opcodes
  -CR        verify object method call validity

  -s = Do not call assembler or linker. Write ppas.bat/ppas.sh script.
  -st        Generate script to link on target
  -sh        Generate script to link on host
  -V     write fpcdebug.txt file with lots of debugging info

  -Xc = Link with C library (LINUX only)
       
}
  // append -o Option if neccessary
  if not (ccloDoNotAppendOutFileOption in Flags)
  and ((TargetFilename<>'') or (CurMainSrcFile<>'') or (CurOutputDir<>'')) then
  begin
    NewTargetFilename:=CreateTargetFilename(CurMainSrcFile);
    if (NewTargetFilename<>'')
    and ((CompareFileNames(NewTargetFilename,ChangeFileExt(CurMainSrcFile,''))<>0)
     or (CurOutputDir<>'')) then
      switches := switches + ' '+PrepareCmdLineOption('-o' + NewTargetFilename);
  end;

  // custom options
  CurCustomOptions:=GetCustomOptions;
  if CurCustomOptions<>'' then
    switches := switches+' '+CurCustomOptions;


  fOptionsString := switches;
  Result := fOptionsString;
end;

{------------------------------------------------------------------------------
  TBaseCompilerOptions GetXMLConfigPath
 ------------------------------------------------------------------------------}
function TBaseCompilerOptions.GetXMLConfigPath: String;
var
  fn: String;
begin
  // Setup the filename to write to
  fn := XMLFile;
  if (fn = '') then
    fn := Config_Filename;
  Result := GetPrimaryConfigPath + '/' + fn;
  CopySecondaryConfigFile(fn);
end;

{------------------------------------------------------------------------------
  TBaseCompilerOptions Clear
------------------------------------------------------------------------------}
procedure TBaseCompilerOptions.Clear;
begin
  fOptionsString := '';
  fLoaded := false;
  FModified := false;

  // search paths
  IncludeFiles := '';
  Libraries := '';
  OtherUnitFiles := '';
  UnitOutputDirectory := '';
  ObjectPath:='';
  SrcPath:='';
  DebugPath:='';
  fLCLWidgetType := '';
  
  // parsing
  fAssemblerStyle := 0;
  fD2Ext := true;
  fCStyleOp := true;
  fIncludeAssertionCode := false;
  fAllowLabel := true;
  fCPPInline := true;
  fCMacros := false;
  fTPCompat := false;
  fInitConst := false;
  fStaticKwd := false;
  fDelphiCompat := false;
  fUseAnsiStr := false;
  fGPCCompat := false;
    
  // code generation
  fUnitStyle := 1;
  fIOChecks := false;
  fRangeChecks := false;
  fOverflowChecks := false;
  fStackChecks := false;
  fHeapSize := 0;
  fGenerate := cgcFasterCode;
  fTargetProc := 0;
  fTargetCPU := '';
  fVarsInReg := false;
  fUncertainOpt := false;
  fOptLevel := 1;
  fTargetOS := '';
    
  // linking
  fGenDebugInfo := false;
  fGenDebugDBX := false;
  fUseLineInfoUnit := true;
  fUseHeaptrc := false;
  fUseValgrind := false;
  fGenGProfCode := false;
  fStripSymbols := false;
  fLinkStyle := 1;
  fPassLinkerOpt := false;
  LinkerOptions := '';
  Win32GraphicApp := false;
    
  // messages
  fShowErrors := true;
  fShowWarn := true;
  fShowNotes := true;
  fShowHints := true;
  fShowGenInfo := true;
  fShowLineNum := false;
  fShowAll := false;
  fShowAllProcsOnError := false;
  fShowDebugInfo := false;
  fShowUsedFiles := false;
  fShowTriedFiles := false;
  fShowDefMacros := false;
  fShowCompProc := false;
  fShowCond := false;
  fShowNothing := false;
  fShowHintsForUnusedUnitsInMainSrc := false;
  fWriteFPCLogo := true;
  fStopAfterErrCount := 1;

  // other
  fDontUseConfigFile := false;
  fAdditionalConfigFile := false;
  fConfigFilePath := './fpc.cfg';
  CustomOptions := '';
  
  // inherited
  ClearInheritedOptions;

  // compilation
  CompilerPath := '$(CompPath)';
  fExecuteBefore.Clear;
  fExecuteAfter.Clear;
end;

procedure TBaseCompilerOptions.Assign(Source: TPersistent);
var
  CompOpts: TBaseCompilerOptions;
begin
  if not (Source is TBaseCompilerOptions) then begin
    inherited Assign(Source);
    exit;
  end;
  CompOpts:=TBaseCompilerOptions(Source);
  fOptionsString := CompOpts.fOptionsString;
  fLoaded := CompOpts.fLoaded;

  // Search Paths
  IncludeFiles := CompOpts.fIncludeFiles;
  Libraries := CompOpts.fLibraries;
  OtherUnitFiles := CompOpts.fOtherUnitFiles;
  UnitOutputDirectory := CompOpts.fUnitOutputDir;
  fLCLWidgetType := CompOpts.fLCLWidgetType;
  ObjectPath := CompOpts.FObjectPath;
  SrcPath := CompOpts.SrcPath;
  DebugPath := CompOpts.DebugPath;

  // Parsing
  fAssemblerStyle := CompOpts.fAssemblerStyle;
  fD2Ext := CompOpts.fD2Ext;
  fCStyleOp := CompOpts.fCStyleOp;
  fIncludeAssertionCode := CompOpts.fIncludeAssertionCode;
  fAllowLabel := CompOpts.fAllowLabel;
  fCPPInline := CompOpts.fCPPInline;
  fCMacros := CompOpts.fCMacros;
  fTPCompat := CompOpts.fTPCompat;
  fInitConst := CompOpts.fInitConst;
  fStaticKwd := CompOpts.fStaticKwd;
  fDelphiCompat := CompOpts.fDelphiCompat;
  fUseAnsiStr := CompOpts.fUseAnsiStr;
  fGPCCompat := CompOpts.fGPCCompat;

  // Code Generation
  fUnitStyle := CompOpts.fUnitStyle;
  fIOChecks := CompOpts.fIOChecks;
  fRangeChecks := CompOpts.fRangeChecks;
  fOverflowChecks := CompOpts.fOverflowChecks;
  fStackChecks := CompOpts.fStackChecks;
  FEmulatedFloatOpcodes := CompOpts.fEmulatedFloatOpcodes;
  fHeapSize := CompOpts.fHeapSize;
  fEmulatedFloatOpcodes := CompOpts.fEmulatedFloatOpcodes;
  fGenerate := CompOpts.fGenerate;
  fTargetProc := CompOpts.fTargetProc;
  fTargetCPU := CompOpts.fTargetCPU;
  fVarsInReg := CompOpts.fVarsInReg;
  fUncertainOpt := CompOpts.fUncertainOpt;
  fOptLevel := CompOpts.fOptLevel;
  fTargetOS := CompOpts.fTargetOS;

  // Linking
  fGenDebugInfo := CompOpts.fGenDebugInfo;
  fGenDebugDBX := CompOpts.fGenDebugDBX;
  fUseLineInfoUnit := CompOpts.fUseLineInfoUnit;
  fUseHeaptrc := CompOpts.fUseHeaptrc;
  fUseValgrind := CompOpts.fUseValgrind;
  fGenGProfCode := CompOpts.fGenGProfCode;
  fStripSymbols := CompOpts.fStripSymbols;
  fLinkStyle := CompOpts.fLinkStyle;
  fPassLinkerOpt := CompOpts.fPassLinkerOpt;
  LinkerOptions := CompOpts.fLinkerOptions;
  Win32GraphicApp := CompOpts.Win32GraphicApp;

  // Messages
  fShowErrors := CompOpts.fShowErrors;
  fShowWarn := CompOpts.fShowWarn;
  fShowNotes := CompOpts.fShowNotes;
  fShowHints := CompOpts.fShowHints;
  fShowGenInfo := CompOpts.fShowGenInfo;
  fShowLineNum := CompOpts.fShowLineNum;
  fShowAll := CompOpts.fShowAll;
  fShowAllProcsOnError := CompOpts.fShowAllProcsOnError;
  fShowDebugInfo := CompOpts.fShowDebugInfo;
  fShowUsedFiles := CompOpts.fShowUsedFiles;
  fShowTriedFiles := CompOpts.fShowTriedFiles;
  fShowDefMacros := CompOpts.fShowDefMacros;
  fShowCompProc := CompOpts.fShowCompProc;
  fShowCond := CompOpts.fShowCond;
  fShowNothing := CompOpts.fShowNothing;
  fShowHintsForUnusedUnitsInMainSrc := CompOpts.fShowHintsForUnusedUnitsInMainSrc;
  fWriteFPCLogo := CompOpts.fWriteFPCLogo;
  fStopAfterErrCount := CompOpts.fStopAfterErrCount;

  // Other
  fDontUseConfigFile := CompOpts.fDontUseConfigFile;
  fAdditionalConfigFile := CompOpts.fAdditionalConfigFile;
  fConfigFilePath := CompOpts.fConfigFilePath;
  CustomOptions := CompOpts.fCustomOptions;

  // compilation
  CompilerPath := CompOpts.fCompilerPath;
  ExecuteBefore.Assign(CompOpts.ExecuteBefore);
  ExecuteAfter.Assign(CompOpts.ExecuteAfter);
end;

function TBaseCompilerOptions.IsEqual(CompOpts: TBaseCompilerOptions): boolean;
begin
  Result:=
    // search paths
        (fIncludeFiles = CompOpts.fIncludeFiles)
    and (fLibraries = CompOpts.fLibraries)
    and (fOtherUnitFiles = CompOpts.fOtherUnitFiles)
    and (fUnitOutputDir = CompOpts.fUnitOutputDir)
    and (FObjectPath = CompOpts.FObjectPath)
    and (FSrcPath = CompOpts.FSrcPath)
    and (fDebugPath = CompOpts.fDebugPath)

    and (fLCLWidgetType = CompOpts.fLCLWidgetType)

    // parsing
    and (fAssemblerStyle = CompOpts.fAssemblerStyle)
    and (fD2Ext = CompOpts.fD2Ext)
    and (fCStyleOp = CompOpts.fCStyleOp)
    and (fIncludeAssertionCode = CompOpts.fIncludeAssertionCode)
    and (fAllowLabel = CompOpts.fAllowLabel)
    and (fCPPInline = CompOpts.fCPPInline)
    and (fCMacros = CompOpts.fCMacros)
    and (fTPCompat = CompOpts.fTPCompat)
    and (fInitConst = CompOpts.fInitConst)
    and (fStaticKwd = CompOpts.fStaticKwd)
    and (fDelphiCompat = CompOpts.fDelphiCompat)
    and (fUseAnsiStr = CompOpts.fUseAnsiStr)
    and (fGPCCompat = CompOpts.fGPCCompat)

    // code generation
    and (fUnitStyle = CompOpts.fUnitStyle)
    and (fIOChecks = CompOpts.fIOChecks)
    and (fRangeChecks = CompOpts.fRangeChecks)
    and (fOverflowChecks = CompOpts.fOverflowChecks)
    and (fStackChecks = CompOpts.fStackChecks)
    and (FEmulatedFloatOpcodes = CompOpts.FEmulatedFloatOpcodes)
    and (fHeapSize = CompOpts.fHeapSize)
    and (fEmulatedFloatOpcodes = CompOpts.fEmulatedFloatOpcodes)
    and (fGenerate = CompOpts.fGenerate)
    and (fTargetProc = CompOpts.fTargetProc)
    and (fTargetCPU = CompOpts.fTargetCPU)
    and (fVarsInReg = CompOpts.fVarsInReg)
    and (fUncertainOpt = CompOpts.fUncertainOpt)
    and (fOptLevel = CompOpts.fOptLevel)
    and (fTargetOS = CompOpts.fTargetOS)

    // linking
    and (fGenDebugInfo = CompOpts.fGenDebugInfo)
    and (fGenDebugDBX = CompOpts.fGenDebugDBX)
    and (fUseLineInfoUnit = CompOpts.fUseLineInfoUnit)
    and (fUseHeaptrc = CompOpts.fUseHeaptrc)
    and (fUseValgrind = CompOpts.fUseValgrind)
    and (fGenGProfCode = CompOpts.fGenGProfCode)
    and (fStripSymbols = CompOpts.fStripSymbols)
    and (fLinkStyle = CompOpts.fLinkStyle)
    and (fPassLinkerOpt = CompOpts.fPassLinkerOpt)
    and (fLinkerOptions = CompOpts.fLinkerOptions)
    and (FWin32GraphicApp = CompOpts.FWin32GraphicApp)

    // messages
    and (fShowErrors = CompOpts.fShowErrors)
    and (fShowWarn = CompOpts.fShowWarn)
    and (fShowNotes = CompOpts.fShowNotes)
    and (fShowHints = CompOpts.fShowHints)
    and (fShowGenInfo = CompOpts.fShowGenInfo)
    and (fShowLineNum = CompOpts.fShowLineNum)
    and (fShowAll = CompOpts.fShowAll)
    and (fShowAllProcsOnError = CompOpts.fShowAllProcsOnError)
    and (fShowDebugInfo = CompOpts.fShowDebugInfo)
    and (fShowUsedFiles = CompOpts.fShowUsedFiles)
    and (fShowTriedFiles = CompOpts.fShowTriedFiles)
    and (fShowDefMacros = CompOpts.fShowDefMacros)
    and (fShowCompProc = CompOpts.fShowCompProc)
    and (fShowCond = CompOpts.fShowCond)
    and (fShowNothing = CompOpts.fShowNothing)
    and (fShowHintsForUnusedUnitsInMainSrc = CompOpts.fShowHintsForUnusedUnitsInMainSrc)
    and (fWriteFPCLogo = CompOpts.fWriteFPCLogo)
    
    // other
    and (fDontUseConfigFile = CompOpts.fDontUseConfigFile)
    and (fAdditionalConfigFile = CompOpts.fAdditionalConfigFile)
    and (fConfigFilePath = CompOpts.fConfigFilePath)
    and (fStopAfterErrCount = CompOpts.fStopAfterErrCount)
    and (fCustomOptions = CompOpts.fCustomOptions)

    // compilation
    and (fCompilerPath = CompOpts.fCompilerPath)
    and ExecuteBefore.IsEqual(CompOpts.ExecuteBefore)
    and ExecuteAfter.IsEqual(CompOpts.ExecuteAfter)
   ;
end;


{ TAdditionalCompilerOptions }

procedure TAdditionalCompilerOptions.SetCustomOptions(const AValue: string);
begin
  if FCustomOptions=AValue then exit;
  FCustomOptions:=AValue;
  ParsedOpts.SetUnparsedValue(pcosCustomOptions,fCustomOptions);
end;

procedure TAdditionalCompilerOptions.SetBaseDirectory(const AValue: string);
begin
  if FBaseDirectory=AValue then exit;
  FBaseDirectory:=AValue;
  ParsedOpts.SetUnparsedValue(pcosBaseDir,FBaseDirectory);
end;

procedure TAdditionalCompilerOptions.SetIncludePath(const AValue: string);
begin
  if FIncludePath=AValue then exit;
  FIncludePath:=AValue;
  ParsedOpts.SetUnparsedValue(pcosIncludePath,FIncludePath);
end;

procedure TAdditionalCompilerOptions.SetLibraryPath(const AValue: string);
begin
  if FLibraryPath=AValue then exit;
  FLibraryPath:=AValue;
  ParsedOpts.SetUnparsedValue(pcosLibraryPath,FLibraryPath);
end;

procedure TAdditionalCompilerOptions.SetLinkerOptions(const AValue: string);
begin
  if FLinkerOptions=AValue then exit;
  FLinkerOptions:=AValue;
  ParsedOpts.SetUnparsedValue(pcosLinkerOptions,fLinkerOptions);
end;

procedure TAdditionalCompilerOptions.SetObjectPath(const AValue: string);
begin
  if FObjectPath=AValue then exit;
  FObjectPath:=AValue;
  ParsedOpts.SetUnparsedValue(pcosObjectPath,FObjectPath);
end;

procedure TAdditionalCompilerOptions.SetUnitPath(const AValue: string);
begin
  if FUnitPath=AValue then exit;
  FUnitPath:=AValue;
  ParsedOpts.SetUnparsedValue(pcosUnitPath,FUnitPath);
end;

constructor TAdditionalCompilerOptions.Create(TheOwner: TObject);
begin
  fOwner:=TheOwner;
  FParsedOpts:=TParsedCompilerOptions.Create;
  Clear;
end;

destructor TAdditionalCompilerOptions.Destroy;
begin
  FreeThenNil(FParsedOpts);
  inherited Destroy;
end;

procedure TAdditionalCompilerOptions.Clear;
begin
  FCustomOptions:='';
  FIncludePath:='';
  FLibraryPath:='';
  FLinkerOptions:='';
  FObjectPath:='';
  FUnitPath:='';
end;

procedure TAdditionalCompilerOptions.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; AdjustPathDelims: boolean);
  
  function f(const Filename: string): string;
  begin
    Result:=SwitchPathDelims(Filename,AdjustPathDelims);
  end;
  
begin
  Clear;
  CustomOptions:=f(XMLConfig.GetValue(Path+'CustomOptions/Value',''));
  IncludePath:=f(XMLConfig.GetValue(Path+'IncludePath/Value',''));
  LibraryPath:=f(XMLConfig.GetValue(Path+'LibraryPath/Value',''));
  LinkerOptions:=f(XMLConfig.GetValue(Path+'LinkerOptions/Value',''));
  ObjectPath:=f(XMLConfig.GetValue(Path+'ObjectPath/Value',''));
  UnitPath:=f(XMLConfig.GetValue(Path+'UnitPath/Value',''));
end;

procedure TAdditionalCompilerOptions.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  XMLConfig.SetDeleteValue(Path+'CustomOptions/Value',fCustomOptions,'');
  XMLConfig.SetDeleteValue(Path+'IncludePath/Value',FIncludePath,'');
  XMLConfig.SetDeleteValue(Path+'LibraryPath/Value',FLibraryPath,'');
  XMLConfig.SetDeleteValue(Path+'LinkerOptions/Value',fLinkerOptions,'');
  XMLConfig.SetDeleteValue(Path+'ObjectPath/Value',FObjectPath,'');
  XMLConfig.SetDeleteValue(Path+'UnitPath/Value',FUnitPath,'');
end;

function TAdditionalCompilerOptions.GetOwnerName: string;
begin
  if fOwner<>nil then
    Result:=fOwner.Classname
  else
    Result:='Has no owner';
end;

{ TParsedCompilerOptions }

constructor TParsedCompilerOptions.Create;
begin
  Clear;
end;

function TParsedCompilerOptions.GetParsedValue(Option: TParsedCompilerOptString
  ): string;
var
  BaseDirectory: String;
  s: String;
begin
  if ParsedStamp[Option]<>CompilerParseStamp then begin
    s:=UnparsedValues[Option];
    // parse locally
    if Assigned(OnLocalSubstitute) then s:=OnLocalSubstitute(s);
    // parse globally
    s:=ParseString(Self,s);
    // improve
    if Option=pcosBaseDir then
      // base directory (append path)
      s:=AppendPathDelim(TrimFilename(s))
    else if Option in ParsedCompilerFilenames then begin
      // make filename absolute
      s:=TrimFilename(s);
      if (s<>'') and (not FilenameIsAbsolute(s)) then begin
        BaseDirectory:=GetParsedValue(pcosBaseDir);
        if (BaseDirectory<>'') then s:=BaseDirectory+s;
      end;
    end
    else if Option in ParsedCompilerDirectories then begin
      // make directory absolute
      s:=TrimFilename(s);
      if (s='') or (not FilenameIsAbsolute(s)) then begin
        BaseDirectory:=GetParsedValue(pcosBaseDir);
        if (BaseDirectory<>'') then s:=BaseDirectory+s;
      end;
      s:=AppendPathDelim(s);
    end
    else if Option in ParsedCompilerSearchPaths then begin
      // make search paths absolute
      BaseDirectory:=GetParsedValue(pcosBaseDir);
      s:=TrimSearchPath(s,BaseDirectory);
    end;
    ParsedValues[Option]:=s;
    ParsedStamp[Option]:=CompilerParseStamp;
  end;
  Result:=ParsedValues[Option];
end;

procedure TParsedCompilerOptions.SetUnparsedValue(
  Option: TParsedCompilerOptString; const NewValue: string);
begin
  if NewValue=UnparsedValues[Option] then exit;
  if InvalidateGraphOnChange then IncreaseCompilerGraphStamp;
  if Option=pcosBaseDir then
    InvalidateFiles
  else
    ParsedStamp[Option]:=InvalidParseStamp;
  UnparsedValues[Option]:=NewValue;
end;

procedure TParsedCompilerOptions.Clear;
var
  Option: TParsedCompilerOptString;
begin
  InvalidateAll;
  for Option:=Low(TParsedCompilerOptString) to High(TParsedCompilerOptString) do
  begin
    ParsedValues[Option]:='';
    UnparsedValues[Option]:='';
  end;
end;

procedure TParsedCompilerOptions.InvalidateAll;
var
  Option: TParsedCompilerOptString;
begin
  for Option:=Low(TParsedCompilerOptString) to High(TParsedCompilerOptString) do
    ParsedStamp[Option]:=InvalidParseStamp;
end;

procedure TParsedCompilerOptions.InvalidateFiles;
var
  Option: TParsedCompilerOptString;
begin
  for Option:=Low(TParsedCompilerOptString) to High(TParsedCompilerOptString) do
    if (Option in ParsedCompilerFiles) then
      ParsedStamp[Option]:=InvalidParseStamp;
end;

//{ TCompilerOptions }

//procedure TCompilerOptions.Clear;
//begin
//  inherited Clear; // DUH!
//end;

{ TCompilationTool }

procedure TCompilationTool.Clear;
begin
  Command:='';
  ScanForFPCMessages:=false;
  ScanForMakeMessages:=false;
  ShowAllMessages:=false;
end;

function TCompilationTool.IsEqual(Params: TCompilationTool
  ): boolean;
begin
  Result:=  (Command=Params.Command)
        and (ScanForFPCMessages=Params.ScanForFPCMessages)
        and (ScanForMakeMessages=Params.ScanForMakeMessages)
        and (ShowAllMessages=Params.ShowAllMessages)
        ;
end;

procedure TCompilationTool.Assign(Src: TCompilationTool);
begin
  Command:=Src.Command;
  ScanForFPCMessages:=Src.ScanForFPCMessages;
  ScanForMakeMessages:=Src.ScanForMakeMessages;
  ShowAllMessages:=Src.ShowAllMessages;
end;

procedure TCompilationTool.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; DoSwitchPathDelims: boolean);
begin
  Command:=SwitchPathDelims(XMLConfig.GetValue(Path+'Command/Value',''),
                            DoSwitchPathDelims);
  ScanForFPCMessages:=XMLConfig.GetValue(Path+'ScanForFPCMsgs/Value',false);
  ScanForMakeMessages:=XMLConfig.GetValue(Path+'ScanForMakeMsgs/Value',false);
  ShowAllMessages:=XMLConfig.GetValue(Path+'ShowAllMessages/Value',false);
end;

procedure TCompilationTool.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  XMLConfig.SetDeleteValue(Path+'Command/Value',Command,'');
  XMLConfig.SetDeleteValue(Path+'ScanForFPCMsgs/Value',
                           ScanForFPCMessages,false);
  XMLConfig.SetDeleteValue(Path+'ScanForMakeMsgs/Value',
                           ScanForMakeMessages,false);
  XMLConfig.SetDeleteValue(Path+'ShowAllMessages/Value',
                           ShowAllMessages,false);
end;

{ TGlobalCompilerOptions }

procedure TGlobalCompilerOptions.SetTargetCPU(const AValue: string);
begin
  if FTargetCPU=AValue then exit;
  FTargetCPU:=AValue;
end;

procedure TGlobalCompilerOptions.SetTargetOS(const AValue: string);
begin
  if FTargetOS=AValue then exit;
  FTargetOS:=AValue;
end;

initialization
  CompilerParseStamp:=1;
  CompilerGraphStamp:=1;
  CompilerGraphStampIncreased:=nil;

end.

