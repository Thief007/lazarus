{
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
    This unit is a support unit for the code tools. It manages compilation
    information, which is not stored in the source, like Makefile information
    and compiler command line options. This information is needed to
    successfully find the right units, include files, predefined variables,
    etc..
    
    The information is stored in a TDefineTree, which contains nodes of type
    TDefineTemplate. Each TDefineTemplate is a tree of defines, undefines,
    definerecurses, ifdefs, ifndefs, elses, elseifs, directories ... .
    
    Simply give a TDefineTree a directory and it will return all predefined
    variables for that directory. These values can be used to parse a unit in
    the directory.
    
    TDefineTree can be saved to and loaded from a XML file.
    
    The TDefinePool contains a list of TDefineTemplate trees, and can generate
    some default templates for Lazarus and FPC sources.
    
  ToDo:
    Error handling for DefinePool
}
unit DefineTemplates;

{$ifdef FPC} {$mode objfpc} {$endif}{$H+}

{ $Define VerboseDefineCache}

interface

uses
  Classes, SysUtils, CodeToolsStrConsts, ExprEval
  {$ifdef FPC}, Laz_XMLCfg{$endif}, AVL_Tree, Process,
  KeywordFuncLists, FileProcs;

const
  ExternalMacroStart = ExprEval.ExternalMacroStart;

  // Standard Template Names (do not translate them)
  StdDefTemplFPC            = 'Free Pascal Compiler';
  StdDefTemplFPCSrc         = 'Free Pascal Sources';
  StdDefTemplLazarusSources = 'Lazarus Sources';
  StdDefTemplLazarusSrcDir  = 'Lazarus Source Directory';
  StdDefTemplLazarusBuildOpts = 'Build options';
  StdDefTemplLCLProject     = 'LCL Project';

  // Standard macros
  DefinePathMacroName      = ExternalMacroStart+'DefinePath';
  UnitPathMacroName        = ExternalMacroStart+'UnitPath';
  IncludePathMacroName     = ExternalMacroStart+'IncPath';
  SrcPathMacroName         = ExternalMacroStart+'SrcPath';
  PPUSrcPathMacroName      = ExternalMacroStart+'PPUSrcPath';
  PPWSrcPathMacroName      = ExternalMacroStart+'PPWSrcPath';
  DCUSrcPathMacroName      = ExternalMacroStart+'DCUSrcPath';
  CompiledSrcPathMacroName = ExternalMacroStart+'CompiledSrcPath';

  // virtual directory
  VirtualDirectory='VIRTUALDIRECTORY';
  
  // FPC operating systems and processor types
  FPCOperatingSystemNames: array[1..11] of shortstring =(
      'linux', 'freebsd', 'win32', 'go32v1', 'go32v2', 'beos', 'os2', 'amiga',
      'atari', 'sunos', 'palmos'
    );
  FPCOperatingSystemAlternativeNames: array[1..1] of shortstring =(
      'unix'
    );
  FPCProcessorNames: array[1..3] of shortstring =(
      'i386', 'powerpc', 'm68k'
    );

type
  //---------------------------------------------------------------------------
  // TDefineTemplate stores a define action, the variablename and the value
  TDefineAction = (
     da_None,
     da_Block,
     da_Define,
     da_DefineRecurse,
     da_Undefine,
     da_UndefineRecurse,
     da_UndefineAll,
     da_If,
     da_IfDef,
     da_IfNDef,
     da_ElseIf,
     da_Else,
     da_Directory
     );

const
  DefineActionBlocks = [da_Block, da_Directory, da_If, da_IfDef, da_IfNDef,
                        da_ElseIf, da_Else];
  DefineActionDefines = [da_Define,da_DefineRecurse,da_Undefine,
                         da_UndefineRecurse,da_UndefineAll];
  DefineActionNames: array[TDefineAction] of string = (
      'None', 'Block', 'Define', 'DefineRecurse', 'Undefine', 'UndefineRecurse',
      'UndefineAll', 'If', 'IfDef', 'IfNDef', 'ElseIf', 'Else', 'Directory'
    );

type
  TDefineTree = class;
  TDefineTemplateFlag = (
    dtfAutoGenerated
    );
  TDefineTemplateFlags = set of TDefineTemplateFlag;
  
  TDefineTemplate = class
  private
    FChildCount: integer;
    FFirstChild: TDefineTemplate;
    FLastChild: TDefineTemplate;
    FMarked: boolean;
    FMergeNameBehind: string;
    FMergeNameInFront: string;
    FNext: TDefineTemplate;
    FParent: TDefineTemplate;
    FPrior: TDefineTemplate;
  public
    Name: string;
    Description: string;
    Variable: string;
    Value: string;
    Action: TDefineAction;
    Flags: TDefineTemplateFlags;
    Owner: TObject;
    class procedure MergeTemplates(ParentDefTempl: TDefineTemplate;
                  var FirstSibling, LastSibling:TDefineTemplate;
                  SourceTemplate: TDefineTemplate; WithSiblings: boolean;
                  const NewNamePrefix: string);
    class procedure MergeXMLConfig(ParentDefTempl: TDefineTemplate;
                  var FirstSibling, LastSibling:TDefineTemplate;
                  XMLConfig: TXMLConfig; const Path, NewNamePrefix: string);
    constructor Create(const AName, ADescription, AVariable, AValue: string;
                       AnAction: TDefineAction);
    constructor Create;
    destructor Destroy; override;
    function  ConsistencyCheck: integer; // 0 = ok
    function  CreateCopy(OnlyMarked, WithSiblings, WithChilds: boolean): TDefineTemplate;
    function  CreateMergeCopy: TDefineTemplate;
    function  FindByName(const AName: string;
                     WithSubChilds, WithNextSiblings: boolean): TDefineTemplate;
    function  FindChildByName(const AName: string): TDefineTemplate;
    function  FindRoot: TDefineTemplate;
    function  FindUniqueName(const Prefix: string): string;
    function  GetFirstSibling: TDefineTemplate;
    function  HasDefines(OnlyMarked, WithSiblings: boolean): boolean;
    function  IsAutoGenerated: boolean;
    function  IsEqual(ADefineTemplate: TDefineTemplate;
                      CheckSubNodes, CheckNextSiblings: boolean): boolean;
    function  Level: integer;
    function  LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                                ClearOldSiblings, WithMergeInfo: boolean): boolean;
    function  SelfOrParentContainsFlag(AFlag: TDefineTemplateFlag): boolean;
    procedure AddChild(ADefineTemplate: TDefineTemplate);
    procedure ReplaceChild(ADefineTemplate: TDefineTemplate);
    procedure DeleteChild(const AName: string);
    procedure Assign(ADefineTemplate: TDefineTemplate; WithSubNodes,
                     WithNextSiblings, ClearOldSiblings: boolean); virtual;
    procedure AssignValues(ADefineTemplate: TDefineTemplate);
    procedure Clear(WithSiblings: boolean);
    procedure CreateMergeInfo(WithSiblings, OnlyMarked: boolean);
    procedure InheritMarks(WithSiblings, WithChilds, Down, Up: boolean);
    procedure InsertBehind(APrior: TDefineTemplate);
    procedure InsertInFront(ANext: TDefineTemplate);
    procedure LoadValuesFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                                      WithMergeInfo: boolean);
    procedure MarkFlags(const MustFlags, NotFlags: TDefineTemplateFlags;
                        WithSiblings, WithChilds: boolean);
    procedure MarkNodes(WithSiblings, WithChilds: boolean);
    procedure MarkOwnedBy(TheOwner: TObject;
                          const MustFlags, NotFlags: TDefineTemplateFlags;
                          WithSiblings, WithChilds: boolean);
    procedure RemoveFlags(TheFlags: TDefineTemplateFlags);
    procedure RemoveLeaves(TheOwner: TObject; const MustFlags,
                           NotFlags: TDefineTemplateFlags;
                           WithSiblings: boolean;
                           var FirstDefTemplate: TDefineTemplate);
    procedure RemoveMarked(WithSiblings: boolean;
                           var FirstDefTemplate: TDefineTemplate);
    procedure RemoveOwner(TheOwner: TObject; WithSiblings: boolean);
    procedure ReverseMarks(WithSiblings, WithChilds: boolean);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                              WithSiblings, OnlyMarked,
                              WithMergeInfo, UpdateMergeInfo: boolean);
    procedure SaveValuesToXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                                    WithMergeInfo: boolean);
    procedure SetDefineOwner(NewOwner: TObject; WithSiblings: boolean);
    procedure SetFlags(AddFlags, SubFlags: TDefineTemplateFlags;
                       WithSiblings: boolean);
    procedure Unbind;
    procedure UnmarkNodes(WithSiblings, WithChilds: boolean);
    procedure WriteDebugReport(OnlyMarked: boolean);
  public
    property ChildCount: integer read FChildCount;
    property FirstChild: TDefineTemplate read FFirstChild;
    property LastChild: TDefineTemplate read FLastChild;
    property Marked: boolean read FMarked write FMarked;
    property Next: TDefineTemplate read FNext;
    property Parent: TDefineTemplate read FParent;
    property Prior: TDefineTemplate read FPrior;
    property MergeNameInFront: string read FMergeNameInFront write FMergeNameInFront;
    property MergeNameBehind: string read FMergeNameBehind write FMergeNameBehind;
  end;

  //---------------------------------------------------------------------------
  //
  TDirectoryDefines = class
  public
    Path: string;
    Values: TExpressionEvaluator;
    constructor Create;
    destructor Destroy; override;
  end;
  
  TOnGetVirtualDirectoryDefines = procedure(Sender: TDefineTree;
    Defines: TDirectoryDefines) of object;

  //---------------------------------------------------------------------------
  // TDefineTree caches the define values for directories
  TOnReadValue = procedure(Sender: TObject; const VariableName: string;
                          var Value: string; var Handled: boolean) of object;

  TOnGetVirtualDirectoryAlias = procedure(Sender: TObject;
    var RealDir: string) of object;
    
  TReadFunctionData = record
    Param: string;
    Result: string;
  end;
  PReadFunctionData = ^TReadFunctionData;

  TDefineTree = class
  private
    FFirstDefineTemplate: TDefineTemplate;
    FCache: TAVLTree; // tree of TDirectoryDefines
    FChangeStep: integer;
    FErrorDescription: string;
    FErrorTemplate: TDefineTemplate;
    FMacroFunctions: TKeyWordFunctionList;
    FMacroVariables: TKeyWordFunctionList;
    FOnGetVirtualDirectoryAlias: TOnGetVirtualDirectoryAlias;
    FOnGetVirtualDirectoryDefines: TOnGetVirtualDirectoryDefines;
    FOnReadValue: TOnReadValue;
    FVirtualDirCache: TDirectoryDefines;
    function Calculate(DirDef: TDirectoryDefines): boolean;
    procedure IncreaseChangeStep;
  protected
    function FindDirectoryInCache(const Path: string): TDirectoryDefines;
    function MacroFuncExtractFileExt(Data: Pointer): boolean;
    function MacroFuncExtractFilePath(Data: Pointer): boolean;
    function MacroFuncExtractFileName(Data: Pointer): boolean;
    function MacroFuncExtractFileNameOnly(Data: Pointer): boolean;
    procedure DoClearCache;
  public
    property RootTemplate: TDefineTemplate
                           read FFirstDefineTemplate write FFirstDefineTemplate;
    property ChangeStep: integer read FChangeStep;
    property ErrorTemplate: TDefineTemplate read FErrorTemplate;
    property ErrorDescription: string read FErrorDescription;
    property OnGetVirtualDirectoryAlias: TOnGetVirtualDirectoryAlias
             read FOnGetVirtualDirectoryAlias write FOnGetVirtualDirectoryAlias;
    property OnGetVirtualDirectoryDefines: TOnGetVirtualDirectoryDefines
         read FOnGetVirtualDirectoryDefines write FOnGetVirtualDirectoryDefines;
    property OnReadValue: TOnReadValue read FOnReadValue write FOnReadValue;
    property MacroFunctions: TKeyWordFunctionList read FMacroFunctions;
    property MacroVariables: TKeyWordFunctionList read FMacroVariables;
  public
    constructor Create;
    destructor Destroy; override;
    function  ConsistencyCheck: integer; // 0 = ok
    function  ExtractNonAutoCreated: TDefineTemplate;
    function  ExtractTemplatesOwnedBy(TheOwner: TObject; const MustFlags,
                               NotFlags: TDefineTemplateFlags): TDefineTemplate;
    function  FindDefineTemplateByName(const AName: string;
                                       OnlyRoots: boolean): TDefineTemplate;
    function  GetCompiledSrcPathForDirectory(const Directory: string): string;
    function  GetDCUSrcPathForDirectory(const Directory: string): string;
    function  GetDefinesForDirectory(const Path: string;
                                 WithVirtualDir: boolean): TExpressionEvaluator;
    function  GetDefinesForVirtualDirectory: TExpressionEvaluator;
    function  GetIncludePathForDirectory(const Directory: string): string;
    function  GetLastRootTemplate: TDefineTemplate;
    function  GetPPUSrcPathForDirectory(const Directory: string): string;
    function  GetPPWSrcPathForDirectory(const Directory: string): string;
    function  GetSrcPathForDirectory(const Directory: string): string;
    function  GetUnitPathForDirectory(const Directory: string): string;
    function  IsEqual(SrcDefineTree: TDefineTree): boolean;
    procedure Add(ADefineTemplate: TDefineTemplate);
    procedure AddChild(ParentTemplate, NewDefineTemplate: TDefineTemplate);
    procedure AddFirst(ADefineTemplate: TDefineTemplate);
    procedure Assign(SrcDefineTree: TDefineTree);
    procedure AssignNonAutoCreated(SrcDefineTree: TDefineTree);
    procedure Clear;
    procedure ClearCache;
    procedure MarkNonAutoCreated;
    procedure MarkTemplatesOwnedBy(TheOwner: TObject;
                               const MustFlags, NotFlags: TDefineTemplateFlags);
    procedure MergeDefineTemplates(SourceTemplate: TDefineTemplate;
                                   const NewNamePrefix: string);
    procedure MergeTemplates(SourceTemplate: TDefineTemplate;
                             const NewNamePrefix: string);
    procedure ReadValue(const DirDef: TDirectoryDefines;
                   const PreValue, CurDefinePath: string; var NewValue: string);
    procedure RemoveDefineTemplate(ADefTempl: TDefineTemplate);
    procedure RemoveMarked;
    procedure RemoveRootDefineTemplateByName(const AName: string);
    procedure RemoveTemplatesOwnedBy(TheOwner: TObject;
                               const MustFlags, NotFlags: TDefineTemplateFlags);
    procedure ReplaceChild(ParentTemplate, NewDefineTemplate: TDefineTemplate;
                           const ChildName: string);
    procedure ReplaceRootSameName(ADefineTemplate: TDefineTemplate);
    procedure ReplaceRootSameName(const Name: string;
                                  ADefineTemplate: TDefineTemplate);
    procedure ReplaceRootSameNameAddFirst(ADefineTemplate: TDefineTemplate);
    procedure WriteDebugReport;
  end;

  //---------------------------------------------------------------------------
  TDefinePool = class
  private
    FEnglishErrorMsgFilename: string;
    FItems: TList; // list of TDefineTemplate;
    function GetItems(Index: integer): TDefineTemplate;
    procedure SetEnglishErrorMsgFilename(const AValue: string);
  public
    property Items[Index: integer]: TDefineTemplate read GetItems; default;
    function Count: integer;
    procedure Add(ADefineTemplate: TDefineTemplate);
    procedure Insert(Index: integer; ADefineTemplate: TDefineTemplate);
    procedure Delete(Index: integer);
    procedure Move(SrcIndex, DestIndex: integer);
    property EnglishErrorMsgFilename: string
        read FEnglishErrorMsgFilename write SetEnglishErrorMsgFilename;
    function CreateFPCTemplate(const PPC386Path, PPCOptions,
                               TestPascalFile: string;
                               var UnitSearchPath: string;
                               Owner: TObject): TDefineTemplate;
    function CreateFPCSrcTemplate(const FPCSrcDir, UnitSearchPath, PPUExt: string;
                          UnitLinkListValid: boolean; var UnitLinkList: string;
                          Owner: TObject): TDefineTemplate;
    function CreateLazarusSrcTemplate(
                          const LazarusSrcDir, WidgetType, ExtraOptions: string;
                          Owner: TObject): TDefineTemplate;
    function CreateLCLProjectTemplate(const LazarusSrcDir, WidgetType,
                          ProjectDir: string; Owner: TObject): TDefineTemplate;
    function CreateDelphiSrcPath(DelphiVersion: integer;
                                 const PathPrefix: string): string;
    function CreateDelphiCompilerDefinesTemplate(DelphiVersion: integer;
                          Owner: TObject): TDefineTemplate;
    function CreateDelphiDirectoryTemplate(const DelphiDirectory: string;
                       DelphiVersion: integer; Owner: TObject): TDefineTemplate;
    function CreateDelphiProjectTemplate(const ProjectDir,
                                 DelphiDirectory: string; DelphiVersion: integer;
                                 Owner: TObject): TDefineTemplate;
    function CreateFPCCommandLineDefines(const Name, CmdLine: string;
                                         RecursiveDefines: boolean;
                                         Owner: TObject): TDefineTemplate;
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
    function ConsistencyCheck: integer; // 0 = ok
    procedure WriteDebugReport;
  end;
  
const
  DefineTemplateFlagNames: array[TDefineTemplateFlag] of shortstring = (
      'AutoGenerated'
    );
  
function DefineActionNameToAction(const s: string): TDefineAction;
function DefineTemplateFlagsToString(Flags: TDefineTemplateFlags): string;
function SearchUnitInUnitLinks(const UnitLinks, TheUnitName: string;
  var UnitLinkStart, UnitLinkEnd: integer; var Filename: string): boolean;


implementation


type
  TUnitNameLink = class
  public
    UnitName: string;
    Filename: string;
  end;

// some useful functions

function DefineActionNameToAction(const s: string): TDefineAction;
begin
  for Result:=Low(TDefineAction) to High(TDefineAction) do
    if AnsiCompareText(s,DefineActionNames[Result])=0 then exit;
  Result:=da_None;
end;

function DefineTemplateFlagsToString(Flags: TDefineTemplateFlags): string;
var f: TDefineTemplateFlag;
begin
  Result:='';
  for f:=Low(TDefineTemplateFlag) to High(TDefineTemplateFlag) do begin
    if f in Flags then begin
      if Result<>'' then Result:=Result+',';
      Result:=Result+DefineTemplateFlagNames[f];
    end;
  end;
end;

function CompareUnitLinkNodes(NodeData1, NodeData2: pointer): integer;
var Link1, Link2: TUnitNameLink;
begin
  Link1:=TUnitNameLink(NodeData1);
  Link2:=TUnitNameLink(NodeData2);
  Result:=AnsiCompareText(Link1.UnitName,Link2.UnitName);
end;

function CompareDirectoryDefines(NodeData1, NodeData2: pointer): integer;
var DirDef1, DirDef2: TDirectoryDefines;
begin
  DirDef1:=TDirectoryDefines(NodeData1);
  DirDef2:=TDirectoryDefines(NodeData2);
  Result:=CompareFilenames(DirDef1.Path,DirDef2.Path);
end;

function SearchUnitInUnitLinks(const UnitLinks, TheUnitName: string;
  var UnitLinkStart, UnitLinkEnd: integer; var Filename: string): boolean;
var
  UnitLinkLen: integer;
begin
  Result:=false;
  Filename:='';
  if TheUnitName='' then exit;
  {$IFDEF ShowTriedFiles}
  writeln('TFindDeclarationTool.FindUnitSource.SearchUnitInUnitLinks length(UnitLinks)=',length(UnitLinks));
  {$ENDIF}
  if UnitLinkStart<1 then
    UnitLinkStart:=1;
  while UnitLinkStart<=length(UnitLinks) do begin
    while (UnitLinkStart<=length(UnitLinks))
    and (UnitLinks[UnitLinkStart] in [#10,#13]) do
      inc(UnitLinkStart);
    UnitLinkEnd:=UnitLinkStart;
    while (UnitLinkEnd<=length(UnitLinks)) and (UnitLinks[UnitLinkEnd]<>' ')
    do
      inc(UnitLinkEnd);
    UnitLinkLen:=UnitLinkEnd-UnitLinkStart;
    if UnitLinkLen>0 then begin
      {$IFDEF ShowTriedFiles}
      writeln('  unit "',copy(UnitLinks,UnitLinkStart,UnitLinkEnd-UnitLinkStart),'" ',CompareSubStrings(TheUnitName,UnitLinks,1,
        UnitLinkStart,UnitLinkLen,false));
      {$ENDIF}
      if (UnitLinkLen=length(TheUnitName))
      and (AnsiStrLIComp(PChar(TheUnitName),@UnitLinks[UnitLinkStart],
           UnitLinkLen)=0)
      then begin
        // unit found -> parse filename
        UnitLinkStart:=UnitLinkEnd+1;
        UnitLinkEnd:=UnitLinkStart;
        while (UnitLinkEnd<=length(UnitLinks))
        and (not (UnitLinks[UnitLinkEnd] in [#10,#13])) do
          inc(UnitLinkEnd);
        if UnitLinkEnd>UnitLinkStart then begin
          Filename:=copy(UnitLinks,UnitLinkStart,UnitLinkEnd-UnitLinkStart);
          if FileExists(Filename) then begin
            Result:=true;
            exit;
          end;
          // try also different extensions
          if CompareFileExt(Filename,'.pp',false)=0 then
            Filename:=ChangeFileExt(Filename,'.pas')
          else
            Filename:=ChangeFileExt(Filename,'.pp');
          if FileExists(Filename) then begin
            Result:=true;
            exit;
          end;
        end;
      end else begin
        UnitLinkStart:=UnitLinkEnd+1;
        while (UnitLinkStart<=length(UnitLinks))
        and (not (UnitLinks[UnitLinkStart] in [#10,#13])) do
          inc(UnitLinkStart);
      end;
    end else
      break;
  end;
end;

{ TDefineTemplate }

procedure TDefineTemplate.MarkFlags(
  const MustFlags, NotFlags: TDefineTemplateFlags;
  WithSiblings, WithChilds: boolean);
var
  ANode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    ANode.FMarked:=ANode.FMarked
                   or (((ANode.Flags*MustFlags)=MustFlags)
                   and (ANode.Flags*NotFlags=[]));
    if (ANode.FirstChild<>nil) and WithChilds then
      ANode.FirstChild.MarkFlags(MustFlags,NotFlags,true,true);
    if not WithSiblings then break;
    ANode:=ANode.Next;
  end;
end;

procedure TDefineTemplate.MarkOwnedBy(TheOwner: TObject;
  const MustFlags, NotFlags: TDefineTemplateFlags;
  WithSiblings, WithChilds: boolean);
var
  ANode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    ANode.FMarked:=ANode.FMarked
                   or ((ANode.Owner=TheOwner)
                       and ((ANode.Flags*MustFlags)=MustFlags)
                       and (ANode.Flags*NotFlags=[]));
    if (ANode.FirstChild<>nil) and WithChilds then
      ANode.FirstChild.MarkOwnedBy(TheOwner,MustFlags,NotFlags,true,true);
    if not WithSiblings then break;
    ANode:=ANode.Next;
  end;
end;

procedure TDefineTemplate.MarkNodes(WithSiblings, WithChilds: boolean);
var
  ANode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    ANode.FMarked:=true;
    if (ANode.FirstChild<>nil) and WithChilds then
      ANode.FirstChild.MarkNodes(true,true);
    if not WithSiblings then break;
    ANode:=ANode.Next;
  end;
end;

procedure TDefineTemplate.ReverseMarks(WithSiblings, WithChilds: boolean);
var
  ANode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    ANode.FMarked:=not ANode.FMarked;
    if (ANode.FirstChild<>nil) and WithChilds then
      ANode.FirstChild.MarkNodes(true,true);
    if not WithSiblings then break;
    ANode:=ANode.Next;
  end;
end;

procedure TDefineTemplate.InheritMarks(WithSiblings, WithChilds, Down,
  Up: boolean);
var
  ANode: TDefineTemplate;
  ChildNode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    if WithChilds then begin
      ChildNode:=ANode.FirstChild;
      while ChildNode<>nil do begin
        if Down and ANode.FMarked then
          ChildNode.FMarked:=true;
        ChildNode.InheritMarks(false,true,Down,Up);
        if Up and ChildNode.FMarked then
          ANode.FMarked:=true;
        ChildNode:=ChildNode.Next;
      end;
    end;
    if not WithSiblings then break;
    ANode:=ANode.Next;
  end;
end;

procedure TDefineTemplate.UnmarkNodes(WithSiblings, WithChilds: boolean);
var
  ANode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    ANode.FMarked:=false;
    if (ANode.FirstChild<>nil) and WithChilds then
      ANode.FirstChild.UnmarkNodes(true,true);
    if not WithSiblings then break;
    ANode:=ANode.Next;
  end;
end;

procedure TDefineTemplate.RemoveMarked(WithSiblings: boolean;
  var FirstDefTemplate: TDefineTemplate);
var ANode, NextNode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    NextNode:=ANode.Next;
    if ANode.FirstChild<>nil then begin
      ANode.FirstChild.RemoveMarked(true,FirstDefTemplate);
    end;
    if ANode.FMarked and (ANode.FirstChild=nil) then begin
      if ANode=FirstDefTemplate then FirstDefTemplate:=ANode.Next;
      ANode.Unbind;
      ANode.Free;
    end;
    if not WithSiblings then break;
    ANode:=NextNode;
  end;
end;

procedure TDefineTemplate.RemoveOwner(TheOwner: TObject; WithSiblings: boolean);
var
  ANode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    if ANode.FFirstChild<>nil then
      ANode.FFirstChild.RemoveOwner(TheOwner,true);
    if ANode.Owner=TheOwner then ANode.Owner:=nil;
    if not WithSiblings then break;
    ANode:=ANode.Next;
  end;
end;

procedure TDefineTemplate.RemoveLeaves(TheOwner: TObject; const MustFlags,
  NotFlags: TDefineTemplateFlags; WithSiblings: boolean;
  var FirstDefTemplate: TDefineTemplate);
var ANode, NextNode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    NextNode:=ANode.Next;
    if ANode.FirstChild<>nil then
      ANode.FirstChild.RemoveLeaves(TheOwner,MustFlags,NotFlags,true,
                                    FirstDefTemplate);
    if ANode.FirstChild=nil then begin
      // this is a leaf
      if ((ANode.Owner=TheOwner)
      and ((ANode.Flags*MustFlags)=MustFlags)
      and (ANode.Flags*NotFlags=[]))
      then begin
        if ANode=FirstDefTemplate then
          FirstDefTemplate:=ANode.Next;
        ANode.Unbind;
        ANode.Free;
      end;
    end;
    if not WithSiblings then break;
    ANode:=NextNode;
  end;
end;

procedure TDefineTemplate.AddChild(ADefineTemplate: TDefineTemplate);
// add as last child
begin
  if ADefineTemplate=nil then exit;
  if LastChild=nil then begin
    while ADefineTemplate<>nil do begin
      ADefineTemplate.fParent:=Self;
      if ADefineTemplate.Prior=nil then FFirstChild:=ADefineTemplate;
      if ADefineTemplate.Next=nil then FLastChild:=ADefineTemplate;
      inc(FChildCount);
      ADefineTemplate:=ADefineTemplate.Next;
    end;
  end else begin
    ADefineTemplate.InsertBehind(LastChild);
  end;
end;

procedure TDefineTemplate.ReplaceChild(ADefineTemplate: TDefineTemplate);
var
  OldTempl: TDefineTemplate;
begin
  OldTempl:=FindChildByName(ADefineTemplate.Name);
  if OldTempl<>nil then begin
    ADefineTemplate.InsertInFront(OldTempl);
    OldTempl.UnBind;
    OldTempl.Free;
  end else
    AddChild(ADefineTemplate);
end;

procedure TDefineTemplate.DeleteChild(const AName: string);
var
  OldTempl: TDefineTemplate;
begin
  OldTempl:=FindChildByName(AName);
  if OldTempl<>nil then begin
    OldTempl.Unbind;
    OldTempl.Free;
  end;
end;

procedure TDefineTemplate.InsertBehind(APrior: TDefineTemplate);
// insert this and all next siblings behind APrior
var ANode, LastSibling, NewParent: TDefineTemplate;
begin
  if APrior=nil then exit;
  NewParent:=APrior.Parent;
  if Parent<>nil then begin
    ANode:=Self;
    while ANode<>nil do begin
      if ANode=APrior then
        raise Exception.Create('internal error: '
          +'TDefineTemplate.InsertBehind: APrior=ANode');
      dec(Parent.FChildCount);
      ANode.FParent:=nil;
      ANode:=ANode.Next;
    end;
  end;
  LastSibling:=Self;
  while LastSibling.Next<>nil do LastSibling:=LastSibling.Next;
  FParent:=NewParent;
  if Parent<>nil then begin
    ANode:=Self;
    while (ANode<>nil) do begin
      ANode.FParent:=Parent;
      inc(Parent.FChildCount);
      ANode:=ANode.Next;
    end;
    if Parent.LastChild=APrior then Parent.FLastChild:=LastSibling;
  end;
  FPrior:=APrior;
  LastSibling.FNext:=APrior.Next;
  APrior.FNext:=Self;
  if LastSibling.Next<>nil then LastSibling.Next.FPrior:=LastSibling;
end;

procedure TDefineTemplate.InsertInFront(ANext: TDefineTemplate);
// insert this and all next siblings in front of ANext
var ANode, LastSibling: TDefineTemplate;
begin
  if ANext=nil then exit;
  if FParent<>nil then begin
    ANode:=Self;
    while ANode<>nil do begin
      if ANode=ANext then
        raise Exception.Create('internal error: '
          +'TDefineTemplate.InsertInFront: ANext=ANode');
      dec(FParent.FChildCount);
      ANode.FParent:=nil;
      ANode:=ANode.Next;
    end;
  end;
  LastSibling:=Self;
  while LastSibling.Next<>nil do LastSibling:=LastSibling.Next;
  FParent:=ANext.Parent;
  if Parent<>nil then begin
    ANode:=Self;
    while ANode<>nil do begin
      ANode.FParent:=Parent;
      inc(Parent.FChildCount);
      ANode:=ANode.Next;
    end;
    if Parent.FirstChild=ANext then Parent.FFirstChild:=Self;
  end;
  FPrior:=ANext.Prior;
  if Prior<>nil then Prior.FNext:=Self;
  LastSibling.FNext:=ANext;
  ANext.FPrior:=LastSibling;
end;

procedure TDefineTemplate.Assign(ADefineTemplate: TDefineTemplate;
  WithSubNodes, WithNextSiblings, ClearOldSiblings: boolean);
var ChildTemplate, CopyTemplate, NextTemplate: TDefineTemplate;
begin
  Clear(ClearOldSiblings);
  if ADefineTemplate=nil then exit;
  AssignValues(ADefineTemplate);
  if WithSubNodes then begin
    ChildTemplate:=ADefineTemplate.FirstChild;
    if ChildTemplate<>nil then begin
      CopyTemplate:=TDefineTemplate.Create;
      AddChild(CopyTemplate);
      CopyTemplate.Assign(ChildTemplate,true,true,false);
    end;
  end;
  if WithNextSiblings then begin
    NextTemplate:=ADefineTemplate.Next;
    if NextTemplate<>nil then begin
      CopyTemplate:=TDefineTemplate.Create;
      CopyTemplate.InsertBehind(Self);
      CopyTemplate.Assign(NextTemplate,WithSubNodes,true,false);
    end;
  end;
end;

procedure TDefineTemplate.AssignValues(ADefineTemplate: TDefineTemplate);
begin
  Name:=ADefineTemplate.Name;
  Description:=ADefineTemplate.Description;
  Variable:=ADefineTemplate.Variable;
  Value:=ADefineTemplate.Value;
  Action:=ADefineTemplate.Action;
  Flags:=ADefineTemplate.Flags;
  MergeNameInFront:=ADefineTemplate.MergeNameInFront;
  MergeNameBehind:=ADefineTemplate.MergeNameBehind;
  Owner:=ADefineTemplate.Owner;
end;

procedure TDefineTemplate.Unbind;
begin
  if FPrior<>nil then FPrior.FNext:=FNext;
  if FNext<>nil then FNext.FPrior:=FPrior;
  if FParent<>nil then begin
    if FParent.FFirstChild=Self then FParent.FFirstChild:=FNext;
    if FParent.FLastChild=Self then FParent.FLastChild:=FPrior;
    dec(FParent.FChildCount);
  end;
  FNext:=nil;
  FPrior:=nil;
  FParent:=nil;
end;

procedure TDefineTemplate.Clear(WithSiblings: boolean);
begin
  while FFirstChild<>nil do FFirstChild.Free;
  if WithSiblings then
    while FNext<>nil do FNext.Free;
  Name:='';
  Description:='';
  Value:='';
  Variable:='';
  Flags:=[];
end;

constructor TDefineTemplate.Create;
begin
  inherited Create;
end;

constructor TDefineTemplate.Create(const AName, ADescription, AVariable,
  AValue: string; AnAction: TDefineAction);
begin
  inherited Create;
  Name:=AName;
  Description:=ADescription;
  Variable:=AVariable;
  Value:=AValue;
  Action:=AnAction;
end;

function TDefineTemplate.CreateCopy(OnlyMarked,
  WithSiblings, WithChilds: boolean): TDefineTemplate;
var LastNewNode, NewNode, ANode: TDefineTemplate;
begin
  Result:=nil;
  LastNewNode:=nil;
  ANode:=Self;
  while ANode<>nil do begin
    if (not OnlyMarked) or (ANode.FMarked) then begin
      // copy node
      NewNode:=TDefineTemplate.Create;
      NewNode.Assign(ANode,false,false,false);
      if LastNewNode<>nil then
        NewNode.InsertBehind(LastNewNode)
      else
        Result:=NewNode;
      LastNewNode:=NewNode;
      // copy childs
      if WithChilds and (ANode.FirstChild<>nil) then begin
        NewNode:=ANode.FirstChild.CreateCopy(OnlyMarked,true,true);
        if NewNode<>nil then
          LastNewNode.AddChild(NewNode);
      end;
    end;
    if not WithSiblings then break;
    ANode:=ANode.Next;
  end;
end;

function TDefineTemplate.CreateMergeCopy: TDefineTemplate;
begin
  CreateMergeInfo(false,false);
  Result:=TDefineTemplate.Create;
  Result.Assign(Self,true,false,false);
end;

function TDefineTemplate.FindRoot: TDefineTemplate;
begin
  Result:=Self;
  repeat
    if Result.Parent<>nil then
      Result:=Result.Parent
    else if Result.Prior<>nil then
      Result:=Result.Prior
    else
      break;
  until false;
end;

procedure RaiseCatchableException(const Msg: string);
begin
  { Raises an exception.
    gdb does not catch fpc Exception objects, therefore this procedure raises
    a standard AV which is catched by gdb. }
  writeln('ERROR in CodeTools: ',Msg);
  // creates an exception, that gdb catches:
  writeln('Creating gdb catchable error:');
  if (length(Msg) div (length(Msg) div 10000))=0 then ;
end;

destructor TDefineTemplate.Destroy;
begin
  Clear(false);
  Unbind;
  inherited Destroy;
end;

function TDefineTemplate.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; ClearOldSiblings, WithMergeInfo: boolean): boolean;
var IndexedPath: string;
  i, LvlCount: integer;
  DefTempl, LastDefTempl: TDefineTemplate;
  NewChild: TDefineTemplate;
begin
  Clear(ClearOldSiblings);
  LvlCount:=XMLConfig.GetValue(Path+'Count/Value',0);
  DefTempl:=nil;
  for i:=1 to LvlCount do begin
    if i=1 then begin
      DefTempl:=Self;
      LastDefTempl:=Prior;
    end else begin
      LastDefTempl:=DefTempl;
      DefTempl:=TDefineTemplate.Create;
      DefTempl.InsertBehind(LastDefTempl);
    end;
    IndexedPath:=Path+'Node'+IntToStr(i)+'/';
    DefTempl.LoadValuesFromXMLConfig(XMLConfig,IndexedPath,WithMergeInfo);
    // load childs
    if XMLConfig.GetValue(IndexedPath+'Count/Value',0)>0 then begin
      NewChild:=TDefineTemplate.Create;
      DefTempl.AddChild(NewChild);
      if not NewChild.LoadFromXMLConfig(XMLConfig,IndexedPath,
                                        false,WithMergeInfo) then
      begin
        Result:=false;  exit;
      end;
    end;
  end;
  Result:=true;
end;

procedure TDefineTemplate.LoadValuesFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; WithMergeInfo: boolean);
var f: TDefineTemplateFlag;
begin
  Name:=XMLConfig.GetValue(Path+'Name/Value','no name');
  Description:=XMLConfig.GetValue(Path+'Description/Value','');
  Value:=XMLConfig.GetValue(Path+'Value/Value','');
  Variable:=XMLConfig.GetValue(Path+'Variable/Value','');
  Action:=DefineActionNameToAction(
                         XMLConfig.GetValue(Path+'Action/Value',''));
  Flags:=[];
  for f:=Low(TDefineTemplateFlag) to High(TDefineTemplateFlag) do begin
    if (f<>dtfAutoGenerated)
    and (XMLConfig.GetValue(Path+'Flags/'+DefineTemplateFlagNames[f],false))
    then
      Include(Flags,f);
  end;
  if WithMergeInfo then begin
    MergeNameInFront:=XMLConfig.GetValue(Path+'MergeNameInFront/Value','');
    MergeNameBehind:=XMLConfig.GetValue(Path+'MergeNameInFront/Value','');
  end else begin
    MergeNameInFront:='';
    MergeNameBehind:='';
  end;
end;

procedure TDefineTemplate.SaveValuesToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; WithMergeInfo: boolean);
var
  f: TDefineTemplateFlag;
begin
  XMLConfig.SetDeleteValue(Path+'Name/Value',Name,'');
  XMLConfig.SetDeleteValue(Path+'Description/Value',Description,'');
  XMLConfig.SetDeleteValue(Path+'Value/Value',Value,'');
  XMLConfig.SetDeleteValue(Path+'Variable/Value',Variable,'');
  XMLConfig.SetDeleteValue(Path+'Action/Value',
                           DefineActionNames[Action],
                           DefineActionNames[da_None]);
  for f:=Low(TDefineTemplateFlag) to High(TDefineTemplateFlag) do begin
    if (f<>dtfAutoGenerated) then
      XMLConfig.SetDeleteValue(
         Path+'Flags/'+DefineTemplateFlagNames[f]
         ,f in Flags,false);
  end;
  if WithMergeInfo then begin
    XMLConfig.SetDeleteValue(Path+'MergeNameInFront/Value',
                             MergeNameInFront,'');
    XMLConfig.SetDeleteValue(Path+'MergeNameBehind/Value',
                             MergeNameBehind,'');
  end else begin
    XMLConfig.SetDeleteValue(Path+'MergeNameInFront/Value','','');
    XMLConfig.SetDeleteValue(Path+'MergeNameBehind/Value','','');
  end;
end;

procedure TDefineTemplate.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string;
  WithSiblings, OnlyMarked, WithMergeInfo, UpdateMergeInfo: boolean);
var IndexedPath: string;
  Index, LvlCount: integer;
  DefTempl: TDefineTemplate;
begin
  if UpdateMergeInfo then CreateMergeInfo(WithSiblings,OnlyMarked);
  DefTempl:=Self;
  LvlCount:=0;
  while DefTempl<>nil do begin
    inc(LvlCount);
    DefTempl:=DefTempl.Next;
  end;
  DefTempl:=Self;
  Index:=0;
  repeat
    if (DefTempl.FMarked) or (not OnlyMarked) then begin
      // save node
      inc(Index);
      IndexedPath:=Path+'Node'+IntToStr(Index)+'/';
      DefTempl.SaveValuesToXMLConfig(XMLConfig,IndexedPath,WithMergeInfo);
      // save childs
      if DefTempl.FFirstChild<>nil then
        DefTempl.FirstChild.SaveToXMLConfig(XMLConfig,IndexedPath,
                                   true,OnlyMarked,
                                   WithMergeInfo,false)
      else
        XMLConfig.SetDeleteValue(IndexedPath+'Count/Value',0,0);
    end;
    if not WithSiblings then break;
    DefTempl:=DefTempl.Next;
  until DefTempl=nil;
  XMLConfig.SetDeleteValue(Path+'Count/Value',Index,0);
end;

procedure TDefineTemplate.CreateMergeInfo(WithSiblings, OnlyMarked: boolean);
var
  DefTempl: TDefineTemplate;
begin
  DefTempl:=Self;
  repeat
    if (DefTempl.FMarked) or (not OnlyMarked) then begin
      if DefTempl.Prior<>nil then
        DefTempl.MergeNameInFront:=DefTempl.Prior.Name
      else
        DefTempl.MergeNameInFront:='';
      if DefTempl.Next<>nil then
        DefTempl.MergeNameBehind:=DefTempl.Next.Name
      else
        DefTempl.MergeNameBehind:='';
      // update childs
      if DefTempl.FFirstChild<>nil then
        DefTempl.FirstChild.CreateMergeInfo(true,OnlyMarked);
    end;
    if not WithSiblings then break;
    DefTempl:=DefTempl.Next;
  until DefTempl=nil;
end;

procedure TDefineTemplate.MergeXMLConfig(ParentDefTempl: TDefineTemplate;
  var FirstSibling, LastSibling: TDefineTemplate;
  XMLConfig: TXMLConfig; const Path, NewNamePrefix: string);
var
  SrcNode: TDefineTemplate;
begin
  SrcNode:=TDefineTemplate.Create;
  SrcNode.LoadFromXMLConfig(XMLConfig,Path,false,true);
  MergeTemplates(ParentDefTempl,FirstSibling,LastSibling,SrcNode,true,
                 NewNamePrefix);
  SrcNode.Clear(true);
  SrcNode.Free;
end;

procedure TDefineTemplate.MergeTemplates(ParentDefTempl: TDefineTemplate;
  var FirstSibling, LastSibling: TDefineTemplate;
  SourceTemplate: TDefineTemplate; WithSiblings: boolean;
  const NewNamePrefix: string);
// merge SourceTemplate. This will keep SourceTemplate untouched
var
  NewNode, PosNode: TDefineTemplate;
  Inserted: boolean;
  SrcNode: TDefineTemplate;
begin
  SrcNode:=SourceTemplate;
  while SrcNode<>nil do begin
    // merge all source nodes
    NewNode:=SrcNode.CreateCopy(false,false,false);
    Inserted:=false;
    if NewNode.Name<>'' then begin
      // node has a name -> test if already exists
      PosNode:=FirstSibling;
      while (PosNode<>nil)
      and (AnsiCompareText(PosNode.Name,NewNode.Name)<>0) do
        PosNode:=PosNode.Next;
      if PosNode<>nil then begin
        // node with same name already exists -> check if it is a copy
        if NewNode.IsEqual(PosNode,false,false) then begin
          // node already exists
          NewNode.Free;
          NewNode:=PosNode;
        end else begin
          // node has same name, but different values
          // -> rename node
          NewNode.Name:=NewNode.FindUniqueName(NewNamePrefix+NewNode.Name);
          // insert behind PosNode
          NewNode.InsertBehind(PosNode);
        end;
        Inserted:=true;
      end;
    end;
    if not Inserted then begin
      // node name is unique or empty -> insert node
      if NewNode.MergeNameInFront<>'' then begin
        // last time, node was inserted behind MergeNameInFront
        // -> search MergeNameInFront
        PosNode:=LastSibling;
        while (PosNode<>nil)
        and (AnsiCompareText(PosNode.Name,NewNode.MergeNameInFront)<>0) do
          PosNode:=PosNode.Prior;
        if PosNode<>nil then begin
          // MergeNameInFront found -> insert behind
          NewNode.InsertBehind(PosNode);
          Inserted:=true;
        end;
      end;
      if not Inserted then begin
        if NewNode.MergeNameBehind<>'' then begin
          // last time, node was inserted in front of MergeNameBehind
          // -> search MergeNameBehind
          PosNode:=FirstSibling;
          while (PosNode<>nil)
          and (AnsiCompareText(PosNode.Name,NewNode.MergeNameBehind)<>0) do
            PosNode:=PosNode.Next;
          if PosNode<>nil then begin
            // MergeNameBehind found -> insert in front
            NewNode.InsertInFront(PosNode);
            Inserted:=true;
          end;
        end;
      end;
      if not Inserted then begin
        // no merge position found -> add as last
        if LastSibling<>nil then begin
          NewNode.InsertBehind(LastSibling);
        end else if ParentDefTempl<>nil then begin
          ParentDefTempl.AddChild(NewNode);
        end;
      end;
    end;
    // NewNode is now inserted -> update FirstSibling and LastSibling
    if FirstSibling=nil then begin
      FirstSibling:=NewNode;
      LastSibling:=NewNode;
    end;
    while FirstSibling.Prior<>nil do
      FirstSibling:=FirstSibling.Prior;
    while LastSibling.Next<>nil do
      LastSibling:=LastSibling.Next;
    // merge childs
    MergeTemplates(NewNode,NewNode.FFirstChild,NewNode.FLastChild,
                   SrcNode.FirstChild,true,NewNamePrefix);
    if not WithSiblings then break;
    SrcNode:=SrcNode.Next;
  end;
end;

function TDefineTemplate.ConsistencyCheck: integer;
var RealChildCount: integer;
  DefTempl: TDefineTemplate;
begin
  RealChildCount:=0;
  DefTempl:=FFirstChild;
  if DefTempl<>nil then begin
    if DefTempl.Prior<>nil then begin
      // not first child
      Result:=-2;  exit;
    end;
    while DefTempl<>nil do begin
      if DefTempl.Parent<>Self then begin
        writeln('  C: DefTempl.Parent<>Self: ',Name,',',DefTempl.Name);
        Result:=-3;  exit;
      end;
      if (DefTempl.Next<>nil) and (DefTempl.Next.Prior<>DefTempl) then begin
        Result:=-4;  exit;
      end;
      if (DefTempl.Prior<>nil) and (DefTempl.Prior.Next<>DefTempl) then begin
        Result:=-5;  exit;
      end;
      Result:=DefTempl.ConsistencyCheck;
      if Result<>0 then begin
        dec(Result,100);  exit;
      end;
      DefTempl:=DefTempl.Next;
      inc(RealChildCount);
    end;
  end;
  if (Parent<>nil) then begin
    if (Prior=nil) and (Parent.FirstChild<>Self) then begin
      Result:=-6;  exit;
    end;
    if (Next=nil) and (Parent.LastChild<>Self) then begin
      Result:=-7;  exit;
    end;
  end;
  if RealChildCount<>FChildCount then begin
    Result:=-1;  exit;
  end;
  Result:=0;
end;

procedure TDefineTemplate.SetDefineOwner(NewOwner: TObject;
  WithSiblings: boolean);
var
  ANode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    ANode.Owner:=NewOwner;
    if ANode.FFirstChild<>nil then
      ANode.FFirstChild.SetDefineOwner(NewOwner,true);
    if not WithSiblings then exit;
    ANode:=ANode.Next;
  end;
end;

procedure TDefineTemplate.SetFlags(AddFlags, SubFlags: TDefineTemplateFlags;
  WithSiblings: boolean);
var
  ANode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    ANode.Flags:=ANode.Flags+AddFlags-SubFlags;
    if ANode.FFirstChild<>nil then
      ANode.FFirstChild.SetFlags(AddFlags,SubFlags,true);
    if not WithSiblings then exit;
    ANode:=ANode.Next;
  end;
end;

procedure TDefineTemplate.WriteDebugReport(OnlyMarked: boolean);

  procedure WriteNode(ANode: TDefineTemplate; const Prefix: string);
  var ActionStr: string;
  begin
    if ANode=nil then exit;
    if (not OnlyMarked) or (ANode.Marked) then begin
      ActionStr:=DefineActionNames[ANode.Action];
      writeln(Prefix,'Self=',HexStr(Cardinal(ANode),8),
        ' Name="',ANode.Name,'"',
        ' Consistency=',ANode.ConsistencyCheck,
        ' Next=',HexStr(Cardinal(ANode.Next),8),
        ' Prior=',HexStr(Cardinal(ANode.Prior),8),
        ' Action=',ActionStr,
        ' Flags=[',DefineTemplateFlagsToString(ANode.Flags),']',
        ' Marked=',ANode.Marked
        );
      writeln(Prefix+'   + Description="',ANode.Description,'"');
      writeln(Prefix+'   + Variable="',ANode.Variable,'"');
      writeln(Prefix+'   + Value="',ANode.Value,'"');
    end;
    WriteNode(ANode.FirstChild,Prefix+'  ');
    WriteNode(ANode.Next,Prefix);
  end;

begin
  WriteNode(Self,'  ');
end;

function TDefineTemplate.HasDefines(OnlyMarked, WithSiblings: boolean): boolean;
var
  CurTempl: TDefineTemplate;
begin
  Result:=true;
  CurTempl:=Self;
  while CurTempl<>nil do begin
    if ((not OnlyMarked) or (CurTempl.FMarked))
    and (CurTempl.Action in DefineActionDefines) then exit;
    // go to next
    if CurTempl.FFirstChild<>nil then
      CurTempl:=CurTempl.FFirstChild
    else if (CurTempl.FNext<>nil)
    and (WithSiblings or (CurTempl.Parent<>Parent)) then
      CurTempl:=CurTempl.FNext
    else begin
      // search uncle
      repeat
        CurTempl:=CurTempl.Parent;
        if (CurTempl=Parent)
        or ((CurTempl.Parent=Parent) and not WithSiblings) then begin
          Result:=false;
          exit;
        end;
      until (CurTempl.FNext<>nil);
      CurTempl:=CurTempl.FNext;
    end;
  end;
  Result:=false;
end;

function TDefineTemplate.IsEqual(ADefineTemplate: TDefineTemplate;
  CheckSubNodes, CheckNextSiblings: boolean): boolean;
var SrcNode, DestNode: TDefineTemplate;
begin
  Result:=(ADefineTemplate<>nil)
      and (Name=ADefineTemplate.Name)
      and (Description=ADefineTemplate.Description)
      and (Variable=ADefineTemplate.Variable)
      and (Value=ADefineTemplate.Value)
      and (Action=ADefineTemplate.Action)
      and (Flags=ADefineTemplate.Flags)
      and (Owner=ADefineTemplate.Owner);
  if not Result then begin
    exit;
  end;
  if CheckSubNodes then begin
    if (ChildCount<>ADefineTemplate.ChildCount) then begin
      Result:=false;
      exit;
    end;
    SrcNode:=FirstChild;
    DestNode:=ADefineTemplate.FirstChild;
    if SrcNode<>nil then begin
      Result:=SrcNode.IsEqual(DestNode,CheckSubNodes,true);
      if not Result then exit;
    end;
  end;
  if CheckNextSiblings then begin
    SrcNode:=Next;
    DestNode:=ADefineTemplate.Next;
    while (SrcNode<>nil) and (DestNode<>nil) do begin
      Result:=SrcNode.IsEqual(DestNode,CheckSubNodes,false);
      if not Result then exit;
      SrcNode:=SrcNode.Next;
      DestNode:=DestNode.Next;
    end;
    Result:=(SrcNode=nil) and (DestNode=nil);
    if not Result then begin
writeln('TDefineTemplate.IsEqual DIFF 3 ',Name,' ',ADefineTemplate.Name,' ',ChildCount,' ',ADefineTemplate.ChildCount);
    end;
  end;
end;

function TDefineTemplate.IsAutoGenerated: boolean;
begin
  Result:=SelfOrParentContainsFlag(dtfAutoGenerated);
end;

procedure TDefineTemplate.RemoveFlags(TheFlags: TDefineTemplateFlags);
var ANode: TDefineTemplate;
begin
  ANode:=Self;
  while ANode<>nil do begin
    Flags:=Flags-TheFlags;
    if FirstChild<>nil then FirstChild.RemoveFlags(TheFlags);
    ANode:=ANode.Next;
  end;
end;

function TDefineTemplate.Level: integer;
var ANode: TDefineTemplate;
begin
  Result:=-1;
  ANode:=Self;
  while ANode<>nil do begin
    inc(Result);
    ANode:=ANode.Parent;
  end;
end;

function TDefineTemplate.GetFirstSibling: TDefineTemplate;
begin
  Result:=Self;
  while Result.Prior<>nil do Result:=Result.Prior;
end;

function TDefineTemplate.SelfOrParentContainsFlag(
  AFlag: TDefineTemplateFlag): boolean;
var Node: TDefineTemplate;
begin
  Node:=Self;
  while (Node<>nil) do begin
    if AFlag in Node.Flags then begin
      Result:=true;
      exit;
    end;
    Node:=Node.Parent;
  end;
  Result:=false;
end;

function TDefineTemplate.FindChildByName(const AName: string): TDefineTemplate;
begin
  if FirstChild<>nil then begin
    Result:=FirstChild.FindByName(AName,false,true)
  end else
    Result:=nil;
end;

function TDefineTemplate.FindByName(const AName: string; WithSubChilds,
  WithNextSiblings: boolean): TDefineTemplate;
var ANode: TDefineTemplate;
begin
  if AnsiCompareText(AName,Name)=0 then begin
    Result:=Self;
  end else begin
    if WithSubChilds and (FirstChild<>nil) then
      Result:=FirstChild.FindByName(AName,true,true)
    else
      Result:=nil;
    if (Result=nil) and WithNextSiblings then begin
      ANode:=Next;
      while (ANode<>nil) do begin
        Result:=ANode.FindByName(AName,WithSubChilds,false);
        if Result<>nil then break;
        ANode:=ANode.Next;
      end;
    end;
  end;
end;

function TDefineTemplate.FindUniqueName(const Prefix: string): string;
var Root: TDefineTemplate;
  i: integer;
begin
  Root:=FindRoot;
  i:=0;
  repeat
    inc(i);
    Result:=Prefix+IntToStr(i);
  until Root.FindByName(Result,true,true)=nil;
end;


{ TDirectoryDefines }

constructor TDirectoryDefines.Create;
begin
  inherited Create;
  Values:=TExpressionEvaluator.Create;
  Path:='';
end;

destructor TDirectoryDefines.Destroy;
begin
  Values.Free;
  inherited Destroy;
end;


{ TDefineTree }

procedure TDefineTree.Clear;
begin
  if FFirstDefineTemplate<>nil then begin
    FFirstDefineTemplate.Clear(true);
    FFirstDefineTemplate.Free;
    FFirstDefineTemplate:=nil;
  end;
  ClearCache;
end;

function TDefineTree.IsEqual(SrcDefineTree: TDefineTree): boolean;
begin
  Result:=false;
  if SrcDefineTree=nil then exit;
  if (FFirstDefineTemplate=nil) xor (SrcDefineTree.FFirstDefineTemplate=nil)
  then exit;
  if (FFirstDefineTemplate<>nil)
  and (not FFirstDefineTemplate.IsEqual(
                                  SrcDefineTree.FFirstDefineTemplate,true,true))
  then exit;
  Result:=true;
end;

procedure TDefineTree.Assign(SrcDefineTree: TDefineTree);
begin
  if IsEqual(SrcDefineTree) then exit;
  Clear;
  if SrcDefineTree.FFirstDefineTemplate<>nil then begin
    FFirstDefineTemplate:=TDefineTemplate.Create;
    FFirstDefineTemplate.Assign(SrcDefineTree.FFirstDefineTemplate,
                                true,true,true);
  end;
end;

procedure TDefineTree.AssignNonAutoCreated(SrcDefineTree: TDefineTree);
var
  SrcNonAutoCreated: TDefineTemplate;
begin
  MarkNonAutoCreated;
  RemoveMarked;
  SrcNonAutoCreated:=SrcDefineTree.ExtractNonAutoCreated;
writeln('TDefineTree.AssignNonAutoCreated A Front=',SrcNonAutoCreated.MergeNameInFront,' Behind=',SrcNonAutoCreated.MergeNameBehind);
  if SrcNonAutoCreated=nil then exit;
  MergeTemplates(SrcNonAutoCreated,'');
  SrcNonAutoCreated.Clear(true);
  SrcNonAutoCreated.Free;
  FFirstDefineTemplate.CreateMergeInfo(true,false);
writeln('TDefineTree.AssignNonAutoCreated B Front=',FFirstDefineTemplate.MergeNameInFront,' Behind=',FFirstDefineTemplate.MergeNameBehind);
end;

procedure TDefineTree.ClearCache;
begin
  if (FCache.Count=0) and (FVirtualDirCache=nil) then exit;
  DoClearCache;
end;

constructor TDefineTree.Create;
begin
  inherited Create;
  FFirstDefineTemplate:=nil;
  FCache:=TAVLTree.Create(@CompareDirectoryDefines);
  
  FMacroFunctions:=TKeyWordFunctionList.Create;
  FMacroFunctions.AddExtended('Ext',nil,@MacroFuncExtractFileExt);
  FMacroFunctions.AddExtended('PATH',nil,@MacroFuncExtractFilePath);
  FMacroFunctions.AddExtended('NAME',nil,@MacroFuncExtractFileName);
  FMacroFunctions.AddExtended('NAMEONLY',nil,@MacroFuncExtractFileNameOnly);
  
  FMacroVariables:=TKeyWordFunctionList.Create;
end;

destructor TDefineTree.Destroy;
begin
  Clear;
  FMacroVariables.Free;
  FMacroFunctions.Free;
  FCache.Free;
  inherited Destroy;
end;

function TDefineTree.GetLastRootTemplate: TDefineTemplate;
begin
  Result:=FFirstDefineTemplate;
  if Result=nil then exit;
  while Result.Next<>nil do Result:=Result.Next;
end;

function TDefineTree.FindDirectoryInCache(
  const Path: string): TDirectoryDefines;
var cmp: integer;
  ANode: TAVLTreeNode;
begin
  ANode:=FCache.Root;
  while (ANode<>nil) do begin
    cmp:=CompareFilenames(Path,TDirectoryDefines(ANode.Data).Path);
    if cmp<0 then
      ANode:=ANode.Left
    else if cmp>0 then
      ANode:=ANode.Right
    else
      break;
  end;
  if ANode<>nil then
    Result:=TDirectoryDefines(ANode.Data)
  else
    Result:=nil;
end;

function TDefineTree.MacroFuncExtractFileExt(Data: Pointer): boolean;
var
  FuncData: PReadFunctionData;
begin
  FuncData:=PReadFunctionData(Data);
  FuncData^.Result:=ExtractFileExt(FuncData^.Param);
  Result:=true;
end;

function TDefineTree.MacroFuncExtractFilePath(Data: Pointer): boolean;
var
  FuncData: PReadFunctionData;
begin
  FuncData:=PReadFunctionData(Data);
  FuncData^.Result:=ExtractFilePath(FuncData^.Param);
  Result:=true;
end;

function TDefineTree.MacroFuncExtractFileName(Data: Pointer): boolean;
var
  FuncData: PReadFunctionData;
begin
  FuncData:=PReadFunctionData(Data);
  FuncData^.Result:=ExtractFileName(FuncData^.Param);
  Result:=true;
end;

function TDefineTree.MacroFuncExtractFileNameOnly(Data: Pointer): boolean;
var
  FuncData: PReadFunctionData;
begin
  FuncData:=PReadFunctionData(Data);
  FuncData^.Result:=ExtractFileNameOnly(FuncData^.Param);
  Result:=true;
end;

procedure TDefineTree.DoClearCache;
begin
  {$IFDEF VerboseDefineCache}
  writeln('TDefineTree.DoClearCache A +++++++++');
  {$ENDIF}
  if FCache<>nil then FCache.FreeAndClear;
  if FVirtualDirCache<>nil then begin
    FVirtualDirCache.Free;
    FVirtualDirCache:=nil;
  end;
  IncreaseChangeStep;
end;

procedure TDefineTree.RemoveMarked;
begin
  if FFirstDefineTemplate=nil then exit;
  FFirstDefineTemplate.RemoveMarked(true,FFirstDefineTemplate);
  ClearCache;
end;

procedure TDefineTree.MarkNonAutoCreated;
begin
  if FFirstDefineTemplate=nil then exit;
  with FFirstDefineTemplate do begin
    // clear marks
    UnmarkNodes(true,true);
    // mark each non autocreated node
    MarkFlags([],[dtfAutoGenerated],true,true);
    // mark every parent with a marked child
    InheritMarks(true,true,false,true);
  end;
end;

function TDefineTree.GetUnitPathForDirectory(const Directory: string): string;
var Evaluator: TExpressionEvaluator;
begin
  Evaluator:=GetDefinesForDirectory(Directory,true);
  if Evaluator<>nil then begin
    Result:=Evaluator.Variables[UnitPathMacroName];
  end else begin
    Result:='';
  end;
end;

function TDefineTree.GetIncludePathForDirectory(const Directory: string
  ): string;
var Evaluator: TExpressionEvaluator;
begin
  Evaluator:=GetDefinesForDirectory(Directory,true);
  if Evaluator<>nil then begin
    Result:=Evaluator.Variables[IncludePathMacroName];
  end else begin
    Result:='';
  end;
end;

function TDefineTree.GetSrcPathForDirectory(const Directory: string): string;
var Evaluator: TExpressionEvaluator;
begin
  Evaluator:=GetDefinesForDirectory(Directory,true);
  if Evaluator<>nil then begin
    Result:=Evaluator.Variables[SrcPathMacroName];
  end else begin
    Result:='';
  end;
end;

function TDefineTree.GetPPUSrcPathForDirectory(const Directory: string
  ): string;
var Evaluator: TExpressionEvaluator;
begin
  Evaluator:=GetDefinesForDirectory(Directory,true);
  if Evaluator<>nil then begin
    Result:=Evaluator.Variables[PPUSrcPathMacroName];
  end else begin
    Result:='';
  end;
end;

function TDefineTree.GetPPWSrcPathForDirectory(const Directory: string
  ): string;
var Evaluator: TExpressionEvaluator;
begin
  Evaluator:=GetDefinesForDirectory(Directory,true);
  if Evaluator<>nil then begin
    Result:=Evaluator.Variables[PPWSrcPathMacroName];
  end else begin
    Result:='';
  end;
end;

function TDefineTree.GetDCUSrcPathForDirectory(const Directory: string
  ): string;
var Evaluator: TExpressionEvaluator;
begin
  Evaluator:=GetDefinesForDirectory(Directory,true);
  if Evaluator<>nil then begin
    Result:=Evaluator.Variables[DCUSrcPathMacroName];
  end else begin
    Result:='';
  end;
end;

function TDefineTree.GetCompiledSrcPathForDirectory(const Directory: string
  ): string;
var
  Evaluator: TExpressionEvaluator;
begin
  Evaluator:=GetDefinesForDirectory(Directory,true);
  if Evaluator<>nil then begin
    Result:=Evaluator.Variables[CompiledSrcPathMacroName];
  end else begin
    Result:='';
  end;
end;

function TDefineTree.GetDefinesForDirectory(
  const Path: string; WithVirtualDir: boolean): TExpressionEvaluator;
var ExpPath: string;
  DirDef: TDirectoryDefines;
begin
  //writeln('[TDefineTree.GetDefinesForDirectory] "',Path,'"');
  if (Path<>'') or (not WithVirtualDir) then begin
    ExpPath:=TrimFilename(Path);
    if (ExpPath<>'') and (ExpPath[length(ExpPath)]<>PathDelim) then
      ExpPath:=ExpPath+PathDelim;
    DirDef:=FindDirectoryInCache(ExpPath);
    if DirDef<>nil then begin
      Result:=DirDef.Values;
    end else begin
      DirDef:=TDirectoryDefines.Create;
      DirDef.Path:=ExpPath;
      //writeln('[TDefineTree.GetDefinesForDirectory] B ',ExpPath,' ');
      if Calculate(DirDef) then begin
        FCache.Add(DirDef);
        Result:=DirDef.Values;
      end else begin
        DirDef.Free;
        Result:=nil;
      end;
    end;
  end else begin
    Result:=GetDefinesForVirtualDirectory;
  end;
end;

function TDefineTree.GetDefinesForVirtualDirectory: TExpressionEvaluator;
begin
  if FVirtualDirCache<>nil then
    Result:=FVirtualDirCache.Values
  else begin
    //writeln('################ TDefineTree.GetDefinesForVirtualDirectory');
    FVirtualDirCache:=TDirectoryDefines.Create;
    FVirtualDirCache.Path:=VirtualDirectory;
    if Calculate(FVirtualDirCache) then begin
      Result:=FVirtualDirCache.Values;
      //writeln('TDefineTree.GetDefinesForVirtualDirectory ',Result.AsString);
    end else begin
      FVirtualDirCache.Free;
      FVirtualDirCache:=nil;
      Result:=nil;
    end;
  end;
end;

procedure TDefineTree.ReadValue(const DirDef: TDirectoryDefines;
  const PreValue, CurDefinePath: string; var NewValue: string);
var
  Buffer: PChar;
  BufferPos: integer;
  BufferSize: integer;
  ValuePos: integer;

  function SearchBracketClose(const s: string; Position:integer): integer;
  var BracketClose:char;
    sLen: Integer;
  begin
    if s[Position]='(' then
      BracketClose:=')'
    else
      BracketClose:='{';
    inc(Position);
    sLen:=length(s);
    while (Position<=sLen) and (s[Position]<>BracketClose) do begin
      if s[Position]=SpecialChar then
        inc(Position)
      else if (s[Position] in ['(','{']) then
        Position:=SearchBracketClose(s,Position);
      inc(Position);
    end;
    Result:=Position;
  end;

  function ExecuteMacroFunction(const FuncName, Params: string): string;
  var
    FuncData: TReadFunctionData;
  begin
    FuncData.Param:=Params;
    FuncData.Result:='';
    FMacroFunctions.DoDataFunction(@FuncName[1],length(FuncName),@FuncData);
    Result:=FuncData.Result;
  end;
  
  function ExecuteMacroVariable(var MacroVariable: string): boolean;
  var
    FuncData: TReadFunctionData;
  begin
    FuncData.Param:=MacroVariable;
    FuncData.Result:='';
    Result:=FMacroFunctions.DoDataFunction(
            @MacroVariable[1],length(MacroVariable),@FuncData);
    if Result then
      MacroVariable:=FuncData.Result;
  end;

  procedure GrowBuffer(MinSize: integer);
  var
    NewSize: Integer;
  begin
    if MinSize<=BufferSize then exit;
    NewSize:=MinSize*2+100;
    ReAllocMem(Buffer,NewSize);
    BufferSize:=NewSize;
  end;

  procedure CopyStringToBuffer(const Src: string);
  begin
    if Src='' then exit;
    Move(Src[1],Buffer[BufferPos],length(Src));
    inc(BufferPos,length(Src));
  end;

  procedure CopyFromValueToBuffer(Len: integer);
  begin
    if Len=0 then exit;
    Move(NewValue[ValuePos],Buffer[BufferPos],Len);
    inc(BufferPos,Len);
    inc(ValuePos,Len);
  end;

  function Substitute(const CurValue: string; ValueLen: integer;
    MacroStart: integer; var MacroEnd: integer): boolean;
  var
    MacroFuncNameEnd: Integer;
    MacroFuncNameLen: Integer;
    MacroStr: String;
    MacroFuncName: String;
    NewMacroLen: Integer;
    MacroParam: string;
    OldMacroLen: Integer;
    Handled: Boolean;
  begin
    Result:=false;
    MacroFuncNameEnd:=MacroEnd;
    MacroFuncNameLen:=MacroFuncNameEnd-MacroStart-1;
    MacroEnd:=SearchBracketClose(CurValue,MacroFuncNameEnd)+1;
    if MacroEnd>ValueLen+1 then exit;
    OldMacroLen:=MacroEnd-MacroStart;
    // Macro found
    if MacroFuncNameLen>0 then begin
      MacroFuncName:=copy(CurValue,MacroStart+1,MacroFuncNameLen);
      // Macro function -> substitute macro parameter first
      ReadValue(DirDef,copy(CurValue,MacroFuncNameEnd+1
          ,MacroEnd-MacroFuncNameEnd-2),CurDefinePath,MacroParam);
      // execute the macro function
      MacroStr:=ExecuteMacroFunction(MacroFuncName,MacroParam);
    end else begin
      // Macro variable
      MacroStr:=copy(CurValue,MacroStart+2,MacroEnd-MacroStart-3);
      //writeln('**** MacroStr=',MacroStr);
      //writeln('DirDef.Values=',DirDef.Values.AsString);
      if MacroStr=DefinePathMacroName then begin
        MacroStr:=CurDefinePath;
      end else if DirDef.Values.IsDefined(MacroStr) then begin
        MacroStr:=DirDef.Values.Variables[MacroStr];
      end else begin
        Handled:=false;
        if Assigned(FOnReadValue) then begin
          MacroParam:=MacroStr;
          MacroStr:='';
          FOnReadValue(Self,MacroParam,MacroStr,Handled);
        end;
        if not Handled then begin
          Handled:=ExecuteMacroVariable(MacroStr);
        end;
        if not Handled then begin
          MacroStr:='';
        end;
      end;
      //writeln('**** NewValue MacroStr=',MacroStr);
    end;
    NewMacroLen:=length(MacroStr);
    GrowBuffer(BufferPos+NewMacroLen-OldMacroLen+ValueLen-ValuePos+1);
    // copy text between this macro and last macro
    CopyFromValueToBuffer(MacroStart-ValuePos);
    // copy macro value to buffer
    CopyStringToBuffer(MacroStr);
    ValuePos:=MacroEnd;
    Result:=true;
  end;

  procedure SetNewValue;
  var
    RestLen: Integer;
  begin
    if Buffer=nil then exit;
    // write rest to buffer
    RestLen:=length(NewValue)-ValuePos+1;
    if RestLen>0 then begin
      GrowBuffer(BufferPos+RestLen);
      Move(NewValue[ValuePos],Buffer[BufferPos],RestLen);
      inc(BufferPos,RestLen);
    end;
    // copy the buffer into NewValue
    SetLength(NewValue,BufferPos);
    if BufferPos>0 then
      Move(Buffer^,NewValue[1],BufferPos);
    // clean up
    FreeMem(Buffer);
    Buffer:=nil;
  end;

var MacroStart,MacroEnd: integer;
  ValueLen: Integer;
begin
  //  writeln('    [ReadValue] A   "',PreValue,'"');
  NewValue:=PreValue;
  if NewValue='' then exit;
  MacroStart:=1;
  ValueLen:=length(NewValue);
  Buffer:=nil;
  BufferSize:=0;
  BufferPos:=0; // position in buffer
  ValuePos:=1;  // same position in value
  while MacroStart<=ValueLen do begin
    // search for macro
    while (MacroStart<=ValueLen) and (NewValue[MacroStart]<>'$') do begin
      if (NewValue[MacroStart]=SpecialChar) then inc(MacroStart);
      inc(MacroStart);
    end;
    if MacroStart>ValueLen then break;
    // read macro function name
    MacroEnd:=MacroStart+1;
    while (MacroEnd<=ValueLen)
    and (NewValue[MacroEnd] in ['0'..'9','A'..'Z','a'..'z','_']) do
      inc(MacroEnd);
    // read macro name / parameters
    if (MacroEnd<ValueLen) and (NewValue[MacroEnd] in ['(','{']) then
    begin
      if not Substitute(NewValue,ValueLen,MacroStart,MacroEnd) then break;
    end;
    MacroStart:=MacroEnd;
  end;
  if Buffer<>nil then SetNewValue;
  //  writeln('    [ReadValue] END "',NewValue,'"');
end;

procedure TDefineTree.MarkTemplatesOwnedBy(TheOwner: TObject; const MustFlags,
  NotFlags: TDefineTemplateFlags);
begin
  if FFirstDefineTemplate=nil then exit;
  with FFirstDefineTemplate do begin
    // unmark all nodes
    UnmarkNodes(true,true);
    // mark each node in filter
    MarkOwnedBy(TheOwner,MustFlags,NotFlags,true,true);
    // mark every parent, that has a marked child
    InheritMarks(true,true,false,true);
  end;
end;

procedure TDefineTree.RemoveTemplatesOwnedBy(TheOwner: TObject;
  const MustFlags, NotFlags: TDefineTemplateFlags);
begin
  if FFirstDefineTemplate=nil then exit;
  FFirstDefineTemplate.RemoveLeaves(TheOwner,MustFlags,NotFlags,true,
                                    FFirstDefineTemplate);
  FFirstDefineTemplate.RemoveOwner(TheOwner,true);
  ClearCache;
end;

function TDefineTree.ExtractTemplatesOwnedBy(TheOwner: TObject;
  const MustFlags, NotFlags: TDefineTemplateFlags): TDefineTemplate;
begin
  Result:=nil;
  if FFirstDefineTemplate=nil then exit;
  MarkTemplatesOwnedBy(TheOwner,MustFlags,NotFlags);
  with FFirstDefineTemplate do begin
    // store some information, so that merging the nodes will result in old order
    CreateMergeInfo(true,false);
    // extract marked nodes
    Result:=CreateCopy(true,true,true);
  end;
end;

function TDefineTree.ExtractNonAutoCreated: TDefineTemplate;
begin
  Result:=nil;
  if FFirstDefineTemplate=nil then exit;
  MarkNonAutoCreated;
  with FFirstDefineTemplate do begin
    // store some information, so that merging the nodes will result in old order
    CreateMergeInfo(true,false);
    // extract marked nodes
    Result:=CreateCopy(true,true,true);
  end;
end;

procedure TDefineTree.MergeTemplates(SourceTemplate: TDefineTemplate;
  const NewNamePrefix: string);
var
  LastDefTempl: TDefineTemplate;
begin
  LastDefTempl:=GetLastRootTemplate;
  TDefineTemplate.MergeTemplates(nil,FFirstDefineTemplate,LastDefTempl,
                  SourceTemplate,true,NewNamePrefix);
  ClearCache;
end;

function TDefineTree.Calculate(DirDef: TDirectoryDefines): boolean;
// calculates the values for a single directory
// returns false on error
var
  ExpandedDirectory, EvalResult, TempValue: string;

  procedure CalculateTemplate(DefTempl: TDefineTemplate; const CurPath: string);
  
    procedure CalculateIfChilds;
    begin
      // execute childs
      CalculateTemplate(DefTempl.FirstChild,CurPath);
      // jump to end of else templates
      DefTempl:=DefTempl.Next;
      while (DefTempl<>nil) and (DefTempl.Action in [da_Else,da_ElseIf])
      do
        DefTempl:=DefTempl.Next;
      if DefTempl=nil then exit;
    end;

  // procedure CalculateTemplate(DefTempl: TDefineTemplate; const CurPath: string);
  var SubPath, TempValue: string;
  begin
    while DefTempl<>nil do begin
      //writeln('  [CalculateTemplate] CurPath="',CurPath,'" DefTempl.Name="',DefTempl.Name,'"');
      case DefTempl.Action of
      da_Block:
        // calculate children
        CalculateTemplate(DefTempl.FirstChild,CurPath);

      da_Define:
        // Define for a single Directory (not SubDirs)
        if FilenameIsMatching(CurPath,ExpandedDirectory,true) then begin
          ReadValue(DirDef,DefTempl.Value,CurPath,TempValue);
          DirDef.Values.Variables[DefTempl.Variable]:=TempValue;
        end;

      da_DefineRecurse:
        // Define for current and sub directories
        begin
          ReadValue(DirDef,DefTempl.Value,CurPath,TempValue);
          DirDef.Values.Variables[DefTempl.Variable]:=TempValue;
        end;

      da_Undefine:
        // Undefine for a single Directory (not SubDirs)
        if FilenameIsMatching(CurPath,ExpandedDirectory,true) then begin
          DirDef.Values.Undefine(DefTempl.Variable);
        end;

      da_UndefineRecurse:
        // Undefine for current and sub directories
        DirDef.Values.Undefine(DefTempl.Variable);

      da_UndefineAll:
        // Undefine every value for current and sub directories
        DirDef.Values.Clear;

      da_If, da_ElseIf:
        begin
          // test expression in value
          ReadValue(DirDef,DefTempl.Value,CurPath,TempValue);
          EvalResult:=DirDef.Values.Eval(TempValue);
          if DirDef.Values.ErrorPosition>=0 then begin
            ReadValue(DirDef,DefTempl.Value,CurPath,TempValue);
            FErrorDescription:=Format(ctsSyntaxErrorInExpr,[TempValue]);
            FErrorTemplate:=DefTempl;
          end else if EvalResult='1' then
            CalculateIfChilds;
        end;
      da_IfDef:
        // test if variable is defined
        if DirDef.Values.IsDefined(DefTempl.Variable) then
          CalculateIfChilds;

      da_IfNDef:
        // test if variable is not defined
        if not DirDef.Values.IsDefined(DefTempl.Variable) then
          CalculateIfChilds;

      da_Else:
        // execute childs
        CalculateTemplate(DefTempl.FirstChild,CurPath);

      da_Directory:
        begin
          // template for a sub directory
          ReadValue(DirDef,DefTempl.Value,CurPath,TempValue);
          {$ifdef win32}
          if CurPath='' then
            SubPath:=TempValue
          else
          {$endif}
            SubPath:=CurPath+PathDelim+TempValue;
          // test if ExpandedDirectory is part of SubPath
          if FilenameIsMatching(SubPath,ExpandedDirectory,false) then
            CalculateTemplate(DefTempl.FirstChild,SubPath);
        end;
      end;
      if ErrorTemplate<>nil then exit;
      if DefTempl<>nil then
        DefTempl:=DefTempl.Next;
    end;
  end;

// function TDefineTree.Calculate(DirDef: TDirectoryDefines): boolean;
begin
  {$IFDEF VerboseDefineCache}
  writeln('[TDefineTree.Calculate] ++++++ "',DirDef.Path,'"');
  {$ENDIF}
  Result:=true;
  FErrorTemplate:=nil;
  ExpandedDirectory:=DirDef.Path;
  if (ExpandedDirectory=VirtualDirectory)
  and Assigned(OnGetVirtualDirectoryAlias) then
    OnGetVirtualDirectoryAlias(Self,ExpandedDirectory);
  if (ExpandedDirectory<>VirtualDirectory) then begin
    ReadValue(DirDef,ExpandedDirectory,'',TempValue);
    ExpandedDirectory:=TempValue;
  end;
  DirDef.Values.Clear;
  // compute the result of all matching DefineTemplates
  CalculateTemplate(FFirstDefineTemplate,'');
  if (ExpandedDirectory=VirtualDirectory)
  and (Assigned(OnGetVirtualDirectoryDefines)) then
    OnGetVirtualDirectoryDefines(Self,DirDef);
  Result:=(ErrorTemplate=nil);
end;

procedure TDefineTree.IncreaseChangeStep;
begin
  if FChangeStep<>$7fffffff then
    inc(FChangeStep)
  else
    FChangeStep:=-$7fffffff;
end;

procedure TDefineTree.Add(ADefineTemplate: TDefineTemplate);
// add as last
var LastDefTempl: TDefineTemplate;
begin
  if ADefineTemplate=nil then exit;
  if RootTemplate=nil then
    RootTemplate:=ADefineTemplate
  else begin
    // add as last
    LastDefTempl:=RootTemplate;
    while LastDefTempl.Next<>nil do
      LastDefTempl:=LastDefTempl.Next;
    ADefineTemplate.InsertBehind(LastDefTempl);
  end;
  ClearCache;
end;

procedure TDefineTree.AddFirst(ADefineTemplate: TDefineTemplate);
// add as first
begin
  if ADefineTemplate=nil then exit;
  if RootTemplate=nil then
    RootTemplate:=ADefineTemplate
  else begin
    RootTemplate.InsertBehind(ADefineTemplate);
    RootTemplate:=ADefineTemplate;
  end;
  ClearCache;
end;

function TDefineTree.FindDefineTemplateByName(
  const AName: string; OnlyRoots: boolean): TDefineTemplate;
begin
  Result:=RootTemplate;
  if RootTemplate<>nil then
    Result:=RootTemplate.FindByName(AName,not OnlyRoots,true)
  else
    Result:=nil;
end;

procedure TDefineTree.ReplaceRootSameName(const Name: string;
  ADefineTemplate: TDefineTemplate);
// if there is a DefineTemplate with the same name then replace it
// else add as last
var OldDefineTemplate: TDefineTemplate;
begin
  if (Name='') then exit;
  OldDefineTemplate:=FindDefineTemplateByName(Name,true);
  if OldDefineTemplate<>nil then begin
    if not OldDefineTemplate.IsEqual(ADefineTemplate,true,false) then begin
      ClearCache;
    end;
    if ADefineTemplate<>nil then
      ADefineTemplate.InsertBehind(OldDefineTemplate);
    if OldDefineTemplate=FFirstDefineTemplate then
      FFirstDefineTemplate:=FFirstDefineTemplate.Next;
    OldDefineTemplate.Unbind;
    OldDefineTemplate.Free;
  end else
    Add(ADefineTemplate);
end;

procedure TDefineTree.RemoveRootDefineTemplateByName(const AName: string);
var ADefTempl: TDefineTemplate;
begin
  ADefTempl:=FindDefineTemplateByName(AName,true);
  if ADefTempl<>nil then RemoveDefineTemplate(ADefTempl);
end;

procedure TDefineTree.RemoveDefineTemplate(ADefTempl: TDefineTemplate);
var
  HadDefines: Boolean;
begin
  if ADefTempl=FFirstDefineTemplate then
    FFirstDefineTemplate:=FFirstDefineTemplate.Next;
  HadDefines:=ADefTempl.HasDefines(false,false);
  ADefTempl.Unbind;
  ADefTempl.Free;
  if HadDefines then ClearCache;
end;

procedure TDefineTree.ReplaceChild(ParentTemplate,
  NewDefineTemplate: TDefineTemplate; const ChildName: string);
// if there is a DefineTemplate with the same name then replace it
// else add as last
var OldDefineTemplate: TDefineTemplate;
begin
  if (ChildName='') or (ParentTemplate=nil) then exit;
  OldDefineTemplate:=ParentTemplate.FindChildByName(ChildName);
  if OldDefineTemplate<>nil then begin
    if not OldDefineTemplate.IsEqual(NewDefineTemplate,true,false) then begin
      ClearCache;
    end;
    if NewDefineTemplate<>nil then
      NewDefineTemplate.InsertBehind(OldDefineTemplate);
    if OldDefineTemplate=FFirstDefineTemplate then
      FFirstDefineTemplate:=FFirstDefineTemplate.Next;
    OldDefineTemplate.Unbind;
    OldDefineTemplate.Free;
  end else begin
    ClearCache;
    ParentTemplate.AddChild(NewDefineTemplate);
  end;
end;

procedure TDefineTree.AddChild(ParentTemplate,
  NewDefineTemplate: TDefineTemplate);
begin
  ClearCache;
  ParentTemplate.AddChild(NewDefineTemplate);
end;

procedure TDefineTree.ReplaceRootSameName(ADefineTemplate: TDefineTemplate);
begin
  if (ADefineTemplate=nil) then exit;
  ReplaceRootSameName(ADefineTemplate.Name,ADefineTemplate);
end;

procedure TDefineTree.ReplaceRootSameNameAddFirst(
  ADefineTemplate: TDefineTemplate);
var OldDefineTemplate: TDefineTemplate;
begin
  if ADefineTemplate=nil then exit;
  OldDefineTemplate:=FindDefineTemplateByName(ADefineTemplate.Name,true);
  if OldDefineTemplate<>nil then begin
    if not OldDefineTemplate.IsEqual(ADefineTemplate,true,false) then begin
      ClearCache;
    end;
    ADefineTemplate.InsertBehind(OldDefineTemplate);
    if OldDefineTemplate=FFirstDefineTemplate then
      FFirstDefineTemplate:=FFirstDefineTemplate.Next;
    OldDefineTemplate.Unbind;
    OldDefineTemplate.Free;
  end else
    AddFirst(ADefineTemplate);
end;

procedure TDefineTree.MergeDefineTemplates(SourceTemplate: TDefineTemplate;
  const NewNamePrefix: string);
var
  LastDefTempl: TDefineTemplate;
begin
  if SourceTemplate=nil then exit;
  // import new defines
  LastDefTempl:=GetLastRootTemplate;
  TDefineTemplate.MergeTemplates(nil,FFirstDefineTemplate,LastDefTempl,
                                 SourceTemplate,true,NewNamePrefix);
  ClearCache;
end;

function TDefineTree.ConsistencyCheck: integer;
begin
  if FFirstDefineTemplate<>nil then begin
    Result:=FFirstDefineTemplate.ConsistencyCheck;
    if Result<>0 then begin
      dec(Result,1000);  exit;
    end;
  end;
  Result:=FCache.ConsistencyCheck;
  if Result<>0 then begin
    dec(Result,2000);  exit;
  end;
  Result:=0;
end;

procedure TDefineTree.WriteDebugReport;
begin
  writeln('TDefineTree.WriteDebugReport  Consistency=',ConsistencyCheck);
  if FFirstDefineTemplate<>nil then
    FFirstDefineTemplate.WriteDebugReport(false)
  else
    writeln('  No templates defined');
  writeln(FCache.ReportAsString);
  writeln('');
end;

    
{ TDefinePool }

constructor TDefinePool.Create;
begin
  inherited Create;
  FItems:=TList.Create;
end;

destructor TDefinePool.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TDefinePool.Clear;
var i: integer;
begin
  for i:=0 to Count-1 do begin
    Items[i].Clear(true);
    Items[i].Free;
  end;
  FItems.Clear;
end;

function TDefinePool.GetItems(Index: integer): TDefineTemplate;
begin
  Result:=TDefineTemplate(FItems[Index]);
end;

procedure TDefinePool.SetEnglishErrorMsgFilename(const AValue: string);
begin
  if FEnglishErrorMsgFilename=AValue then exit;
  FEnglishErrorMsgFilename:=AValue;
end;

procedure TDefinePool.Add(ADefineTemplate: TDefineTemplate);
begin
  if ADefineTemplate<>nil then
    FItems.Add(ADefineTemplate);
end;

procedure TDefinePool.Insert(Index: integer; ADefineTemplate: TDefineTemplate);
begin
  FItems.Insert(Index,ADefineTemplate);
end;

procedure TDefinePool.Delete(Index: integer);
begin
  Items[Index].Clear(true);
  Items[Index].Free;
  FItems.Delete(Index);
end;

procedure TDefinePool.Move(SrcIndex, DestIndex: integer);
begin
  FItems.Move(SrcIndex,DestIndex);
end;

function TDefinePool.Count: integer;
begin
  Result:=FItems.Count;
end;

function TDefinePool.CreateFPCTemplate(
  const PPC386Path, PPCOptions, TestPascalFile: string;
  var UnitSearchPath: string; Owner: TObject): TDefineTemplate;
// create symbol definitions for the freepascal compiler
// To get reliable values the compiler itself is asked for
var
  LastDefTempl: TDefineTemplate;
  ShortTestFile: string;
  
  procedure AddTemplate(NewDefTempl: TDefineTemplate);
  begin
    if NewDefTempl=nil then exit;
    if LastDefTempl<>nil then
      NewDefTempl.InsertBehind(LastDefTempl);
    LastDefTempl:=NewDefTempl;
  end;
  
  function FindSymbol(const SymbolName: string): TDefineTemplate;
  begin
    Result:=LastDefTempl;
    while (Result<>nil)
    and (AnsiComparetext(Result.Variable,SymbolName)<>0) do
      Result:=Result.Prior;
  end;

  procedure DefineSymbol(const SymbolName, SymbolValue: string);
  var NewDefTempl: TDefineTemplate;
  begin
    NewDefTempl:=FindSymbol(SymbolName);
    if NewDefTempl=nil then begin
      NewDefTempl:=TDefineTemplate.Create('Define '+SymbolName,
           ctsDefaultppc386Symbol,SymbolName,'',da_DefineRecurse);
      AddTemplate(NewDefTempl);
    end else begin
      NewDefTempl.Value:=SymbolValue;
    end;
  end;

  procedure UndefineSymbol(const SymbolName: string);
  var
    ADefTempl: TDefineTemplate;
  begin
    ADefTempl:=FindSymbol(SymbolName);
    if ADefTempl=nil then exit;
    if LastDefTempl=ADefTempl then LastDefTempl:=ADefTempl.Prior;
    ADefTempl.Unbind;
    ADefTempl.Free;
  end;

  procedure ProcessOutputLine(var Line: string);
  var
    SymbolName, SymbolValue, UpLine: string;
    i: integer;
  begin
    UpLine:=UpperCaseStr(Line);
    i:=length(ShortTestFile);
    if (length(Line)>i)
    and (AnsiCompareText(LeftStr(Line,i),ShortTestFile)=0)
    and (Line[i+1]='(') then begin
      inc(i);
      while (i<length(Line)) and (Line[i]<>')') do inc(i);
      inc(i);
      while (i<length(Line)) and (Line[i]=' ') do inc(i);
      if (i<=length(Line)) then begin
        System.Delete(Line,1,i-1);
        System.Delete(UpLine,1,i-1);
      end;
    end;
    if copy(UpLine,1,15)='MACRO DEFINED: ' then begin
      SymbolName:=copy(UpLine,16,length(Line)-15);
      DefineSymbol(SymbolName,'');
    end else if copy(UpLine,1,17)='MACRO UNDEFINED: ' then begin
      SymbolName:=copy(UpLine,18,length(Line)-17);
      UndefineSymbol(SymbolName);
    end else if copy(UpLine,1,6)='MACRO ' then begin
      System.Delete(Line,1,6);
      System.Delete(UpLine,1,6);
      i:=1;
      while (i<=length(Line)) and (Line[i]<>' ') do inc(i);
      SymbolName:=copy(UpLine,1,i-1);
      inc(i); // skip '='
      System.Delete(Line,1,i-1);
      System.Delete(UpLine,1,i-1);
      if copy(UpLine,1,7)='SET TO ' then begin
        SymbolValue:=copy(Line,8,length(Line)-7);
        DefineSymbol(SymbolName,SymbolValue);
      end;
    end else if copy(UpLine,1,17)='USING UNIT PATH: ' then begin
      UnitSearchPath:=UnitSearchPath+copy(Line,18,length(Line)-17)+#13;
    end;
  end;
  
// function TDefinePool.CreateFPCTemplate(
//   const PPC386Path: string): TDefineTemplate;
var CmdLine: string;
  i, OutLen, LineStart: integer;
  TheProcess : TProcess;
  OutputLine, Buf, TargetOS, SrcOS, TargetProcessor: String;
  NewDefTempl: TDefineTemplate;
begin
  //writeln('CreateFPCTemplate ',PPC386Path,' ',PPCOptions);
  Result:=nil;
  UnitSearchPath:='';
  if (PPC386Path='') or (not FileIsExecutable(PPC386Path)) then exit;
  LastDefTempl:=nil;
  // find all initial compiler macros and all unit paths
  // -> ask compiler with the -va switch
  SetLength(Buf,1024);
  try
    CmdLine:=PPC386Path+' -va ';
    if FileExists(EnglishErrorMsgFilename) then
      CmdLine:=CmdLine+'-Fr'+EnglishErrorMsgFilename+' ';
    if PPCOptions<>'' then
      CmdLine:=CmdLine+PPCOptions+' ';
    CmdLine:=CmdLine+TestPascalFile;
    ShortTestFile:=ExtractFileName(TestPascalFile);

    TheProcess := TProcess.Create(nil);
    TheProcess.CommandLine := CmdLine;
    TheProcess.Options:= [poUsePipes, poNoConsole, poStdErrToOutPut];
    TheProcess.ShowWindow := swoNone;
    try
      TheProcess.Execute;
      OutputLine:='';
      repeat
        if TheProcess.Output<>nil then
          OutLen:=TheProcess.Output.Read(Buf[1],length(Buf))
        else
          OutLen:=0;
        LineStart:=1;
        i:=1;
        while i<=OutLen do begin
          if Buf[i] in [#10,#13] then begin
            OutputLine:=OutputLine+copy(Buf,LineStart,i-LineStart);
            ProcessOutputLine(OutputLine);
            OutputLine:='';
            if (i<OutLen) and (Buf[i+1] in [#10,#13]) and (Buf[i]<>Buf[i+1])
            then
              inc(i);
            LineStart:=i+1;
          end;
          inc(i);
        end;
        OutputLine:=copy(Buf,LineStart,OutLen-LineStart+1);
      until OutLen=0;
      TheProcess.WaitOnExit;
    finally
      TheProcess.Free;
    end;

    // ask for target operating system -> ask compiler with switch -iTO
    CmdLine:=PPC386Path;
    if PPCOptions<>'' then
      CmdLine:=CmdLine+' '+PPCOptions;
    CmdLine:=CmdLine+' -iTO';

    TheProcess := TProcess.Create(nil);
    TheProcess.CommandLine := CmdLine;
    TheProcess.Options:= [poUsePipes, poNoConsole, poStdErrToOutPut];
    TheProcess.ShowWindow := swoNone;
    try
      TheProcess.Execute;
      if TheProcess.Output<>nil then
        OutLen:=TheProcess.Output.Read(Buf[1],length(Buf))
      else
        OutLen:=0;
      i:=1;
      while i<=OutLen do begin
        if Buf[i] in [#10,#13] then begin
          TargetOS:=copy(Buf,1,i-1);
          NewDefTempl:=TDefineTemplate.Create('Define TargetOS',
            ctsDefaultppc386TargetOperatingSystem,
            ExternalMacroStart+'TargetOS',TargetOS,da_DefineRecurse);
          AddTemplate(NewDefTempl);
          if (TargetOS='linux') then
            SrcOS:='unix'
          else
            SrcOS:=TargetOS;
          NewDefTempl:=TDefineTemplate.Create('Define SrcOS',
            ctsDefaultppc386SourceOperatingSystem,
            ExternalMacroStart+'SrcOS',SrcOS,da_DefineRecurse);
          AddTemplate(NewDefTempl);
          break;
        end;
        inc(i);
      end;
      TheProcess.WaitOnExit;
    finally
      TheProcess.Free;
    end;
    
    // ask for target processor -> ask compiler with switch -iTP
    TheProcess := TProcess.Create(nil);
    CmdLine:=PPC386Path;
    if PPCOptions<>'' then
      CmdLine:=CmdLine+' '+PPCOptions;
    CmdLine:=CmdLine+' -iTP';
    TheProcess.CommandLine := CmdLine;
    TheProcess.Options:= [poUsePipes, poNoConsole, poStdErrToOutPut];
    TheProcess.ShowWindow := swoNone;
    try
      TheProcess.Execute;
      if TheProcess.Output<>nil then
        OutLen:=TheProcess.Output.Read(Buf[1],length(Buf))
      else
        OutLen:=0;
      i:=1;
      while i<=OutLen do begin
        if Buf[i] in [#10,#13] then begin
          TargetProcessor:=copy(Buf,1,i-1);
          NewDefTempl:=TDefineTemplate.Create('Define TargetProcessor',
            ctsDefaultppc386TargetProcessor,
            ExternalMacroStart+'TargetProcessor',TargetProcessor,
            da_DefineRecurse);
          AddTemplate(NewDefTempl);
          break;
        end;
        inc(i);
      end;
      TheProcess.WaitOnExit;
    finally
      TheProcess.Free;
    end;

    // add
    if (LastDefTempl<>nil) then begin
      Result:=TDefineTemplate.Create('Free Pascal Compiler',
        ctsFreePascalCompilerInitialMacros,'','',da_Block);
      Result.AddChild(LastDefTempl.GetFirstSibling);
      Result.SetFlags([dtfAutoGenerated],[],false);
    end;
  except
    on E: Exception do begin
      writeln('ERROR: TDefinePool.CreateFPCTemplate: ',E.Message);
    end;
  end;
  if Result<>nil then
    Result.SetDefineOwner(Owner,true);
end;

function TDefinePool.CreateFPCSrcTemplate(
  const FPCSrcDir, UnitSearchPath, PPUExt: string;
  UnitLinkListValid: boolean; var UnitLinkList: string;
  Owner: TObject): TDefineTemplate;
var
  Dir, TargetOS, SrcOS, TargetProcessor, UnitLinks,
  IncPathMacro: string;
  DS: char;
  UnitTree: TAVLTree; // tree of TUnitNameLink

  procedure GatherUnits; forward;

  function FindUnitLink(const AnUnitName: string): TUnitNameLink;
  var ANode: TAVLTreeNode;
    cmp: integer;
  begin
    if UnitTree=nil then GatherUnits;
    ANode:=UnitTree.Root;
    while ANode<>nil do begin
      Result:=TUnitNameLink(ANode.Data);
      cmp:=AnsiCompareText(AnUnitName,Result.UnitName);
      if cmp<0 then
        ANode:=ANode.Left
      else if cmp>0 then
        ANode:=ANode.Right
      else
        exit;
    end;
    Result:=nil;
  end;

  procedure GatherUnits;
  
    function FileNameMacroCount(const AFilename: string): integer;
    // count number of macros in filename
    // a macro looks like this '$(name)' without a SpecialChar in front
    // macronames can contain macros themselves
    var i: integer;
    begin
      Result:=0;
      i:=1;
      while (i<=length(AFilename)) do begin
        if (AFilename[i]=SpecialChar) then
          inc(i,2)
        else if (AFilename[i]='$') then begin
          inc(i);
          if (i<=length(AFilename)) and (AFilename[i]='(') then
            inc(Result);
        end else
          inc(i);
      end;
    end;
    
    function BuildMacroFilename(const AFilename: string;
      var SrcOSMacroUsed: boolean): string;
    // replace Operating System and Processor Type with macros
    var DirStart, DirEnd, i: integer;
      DirName: string;
    begin
      SrcOSMacroUsed:=false;
      Result:=copy(AFilename,length(FPCSrcDir)+1,
                   length(AFilename)-length(FPCSrcDir));
      DirStart:=1;
      while (DirStart<=length(Result)) do begin
        while (DirStart<=length(Result)) and (Result[DirStart]=PathDelim)
        do
          inc(DirStart);
        DirEnd:=DirStart;
        while (DirEnd<=length(Result)) and (Result[DirEnd]<>PathDelim) do
          inc(DirEnd);
        if DirEnd>length(Result) then break;
        if DirEnd>DirStart then begin
          DirName:=copy(Result,DirStart,DirEnd-DirStart);
          // replace operating system
          for i:=Low(FPCOperatingSystemNames) to High(FPCOperatingSystemNames)
          do
            if FPCOperatingSystemNames[i]=DirName then begin
              Result:=copy(Result,1,DirStart-1)+TargetOS+
                      copy(Result,DirEnd,length(Result)-DirEnd+1);
              inc(DirEnd,length(TargetOS)-length(DirName));
              DirName:=TargetOS;
              break;
            end;
          // replace operating system class
          for i:=Low(FPCOperatingSystemAlternativeNames)
              to High(FPCOperatingSystemAlternativeNames)
          do
            if FPCOperatingSystemAlternativeNames[i]=DirName then begin
              Result:=copy(Result,1,DirStart-1)+SrcOS+
                      copy(Result,DirEnd,length(Result)-DirEnd+1);
              inc(DirEnd,length(SrcOS)-length(DirName));
              DirName:=SrcOS;
              SrcOSMacroUsed:=true;
              break;
            end;
          // replace processor type
          for i:=Low(FPCProcessorNames) to High(FPCProcessorNames) do
            if FPCProcessorNames[i]=DirName then begin
              Result:=copy(Result,1,DirStart-1)+TargetProcessor+
                      copy(Result,DirEnd,length(Result)-DirEnd+1);
              inc(DirEnd,length(TargetProcessor)-length(DirName));
              DirName:=TargetProcessor;
              break;
            end;
        end;
        DirStart:=DirEnd;
      end;
      Result:=FPCSrcDir+Result;
    end;
    
    procedure BrowseDirectory(ADirPath: string);
    const
      IgnoreDirs: array[1..12] of shortstring =(
          '.', '..', 'CVS', 'examples', 'example', 'tests', 'fake', 'ide',
          'demo', 'docs', 'template', 'fakertl'
        );
    var
      AFilename, Ext, UnitName, MacroFileName: string;
      FileInfo: TSearchRec;
      NewUnitLink, OldUnitLink: TUnitNameLink;
      SrcOSMacroUsed: boolean;
      i: integer;
    begin
      //  writeln('%%%Browse ',ADirPath);
      if ADirPath='' then exit;
      if not (ADirPath[length(ADirPath)]=PathDelim) then
        ADirPath:=ADirPath+PathDelim;
      if FindFirst(ADirPath+'*.*',faAnyFile,FileInfo)=0 then begin
        repeat
          AFilename:=FileInfo.Name;
          i:=High(IgnoreDirs);
          while (i>=Low(IgnoreDirs)) and (AFilename<>IgnoreDirs[i]) do dec(i);
          if i>=Low(IgnoreDirs) then continue;
          AFilename:=ADirPath+AFilename;
          if (FileInfo.Attr and faDirectory)>0 then begin
            // ToDo: prevent cycling in links
            BrowseDirectory(AFilename);
          end else begin
            Ext:=UpperCaseStr(ExtractFileExt(AFilename));
            if (Ext='.PP') or (Ext='.PAS') then begin
              // pascal unit found
              UnitName:=FileInfo.Name;
              UnitName:=copy(UnitName,1,length(UnitName)-length(Ext));
              if UnitName<>'' then begin
                OldUnitLink:=FindUnitLink(UnitName);
                MacroFileName:=BuildMacroFileName(AFilename,SrcOSMacroUsed);
                if OldUnitLink=nil then begin
                  // first unit with this name
                  NewUnitLink:=TUnitNameLink.Create;
                  NewUnitLink.UnitName:=UnitName;
                  NewUnitLink.FileName:=MacroFileName;
                  UnitTree.Add(NewUnitLink);
                end else begin
                  { there is another unit with this name

                    the decision which filename is the right one is based on a
                    simple heuristic:
                     FPC stores a unit many times, if there is different version
                     for each Operating System or Processor Type. And sometimes
                     units are stored in a combined OS (e.g. 'unix').
                     Therefore every occurence of such values is replaced by a
                     macro. And filenames without macros are always deleted if
                     there is a filename with a macro. (The filename without
                     macro is only used by the FPC team as a template source
                     for the OS specific)
                     For example:
                       classes.pp can be found in several places
                        <FPCSrcDir>/fcl/os2/classes.pp
                        <FPCSrcDir>/fcl/linux/classes.pp
                        <FPCSrcDir>/fcl/win32/classes.pp
                        <FPCSrcDir>/fcl/go32v2/classes.pp
                        <FPCSrcDir>/fcl/freebsd/classes.pp
                        <FPCSrcDir>/fcl/template/classes.pp

                       This will result in a single filename:
                        $(#FPCSrcDir)/fcl/$(#TargetOS)/classes.pp
                  }
                  if (FileNameMacroCount(OldUnitLink.Filename)=0)
                  or (SrcOSMacroUsed) then begin
                    // old filename has no macros -> take the macro filename
                    OldUnitLink.Filename:=MacroFileName;
                  end;
                end;
              end;
            end;
          end;
        until FindNext(FileInfo)<>0;
      end;
      FindClose(FileInfo);
    end;
  
  begin
    if UnitTree=nil then
      UnitTree:=TAVLTree.Create(@CompareUnitLinkNodes)
    else
      UnitTree.FreeAndClear;
    BrowseDirectory(FPCSrcDir);
  end;
  

  procedure AddFPCSourceLinkForUnit(const AnUnitName: string);
  var UnitLink: TUnitNameLink;
    s: string;
  begin
    // search
    if AnUnitName='' then exit;
    UnitLink:=FindUnitLink(AnUnitName);
    //writeln('AddFPCSourceLinkForUnit ',AnUnitName,' ',UnitLink<>nil);
    if UnitLink=nil then exit;
    s:=AnUnitName+' '+UnitLink.Filename+EndOfLine;
    UnitLinkList:=UnitLinkList+s;
  end;

  procedure FindStandardPPUSources;
  var PathStart, PathEnd: integer;
    ADirPath, UnitName: string;
    FileInfo: TSearchRec;
    CurMask: String;
  begin
    // try every ppu file in every reachable directory (CompUnitPath)
    if UnitLinkListValid then exit;
    UnitLinkList:='';
    PathStart:=1;
    CurMask:=PPUExt;
    if CurMask='' then CurMask:='.ppu';
    if CurMask[1]<>'.' then
      CurMask:='.'+CurMask;
    CurMask:='*'+CurMask;
    while PathStart<=length(UnitSearchPath) do begin
      while (PathStart<=length(UnitSearchPath))
      and (UnitSearchPath[PathStart]=#13) do
        inc(PathStart);
      PathEnd:=PathStart;
      // extract single path from unit search path
      while (PathEnd<=length(UnitSearchPath))
      and (UnitSearchPath[PathEnd]<>#13) do
        inc(PathEnd);
      if PathEnd>PathStart then begin
        ADirPath:=copy(UnitSearchPath,PathStart,PathEnd-PathStart);
        //writeln('&&& FindStandardPPUSources ',ADirPath);
        // search all ppu files in this directory
        if FindFirst(ADirPath+CurMask,faAnyFile,FileInfo)=0 then begin
          repeat
            UnitName:=ExtractFileName(FileInfo.Name);
            UnitName:=copy(UnitName,1,length(UnitName)-4);
            //writeln('&&& FindStandardPPUSources B ',UnitName);
            AddFPCSourceLinkForUnit(UnitName);
          until FindNext(FileInfo)<>0;
        end;
        FindClose(FileInfo);
      end;
      PathStart:=PathEnd;
    end;
    UnitLinkListValid:=true;
  end;

//  function CreateFPCSrcTemplate(const FPCSrcDir,
//      UnitSearchPath: string;
//      UnitLinkListValid: boolean; var UnitLinkList: string): TDefineTemplate;
var
  DefTempl, MainDir, FCLDir, RTLDir, RTLOSDir, PackagesDir, CompilerDir,
  UtilsDir, DebugSvrDir: TDefineTemplate;
  s: string;
  RTLWin32Dir: TDefineTemplate;
begin
  //writeln('CreateFPCSrcTemplate ',FPCSrcDir,': ',length(UnitSearchPath),' Valid=',UnitLinkListValid,' PPUExt=',PPUExt);
  Result:=nil;
  if (FPCSrcDir='') or (not DirectoryExists(FPCSrcDir)) then exit;
  DS:=PathDelim;
  Dir:=FPCSrcDir;
  if Dir[length(Dir)]<>DS then Dir:=Dir+DS;
  TargetOS:='$('+ExternalMacroStart+'TargetOS)';
  SrcOS:='$('+ExternalMacroStart+'SrcOS)';
  TargetProcessor:='$('+ExternalMacroStart+'TargetProcessor)';
  IncPathMacro:='$('+ExternalMacroStart+'IncPath)';
  UnitLinks:=ExternalMacroStart+'UnitLinks';
  UnitTree:=nil;

  Result:=TDefineTemplate.Create(StdDefTemplFPCSrc,
     Format(ctsFreePascalSourcesPlusDesc,['RTL, FCL, Packages, Compiler']),
     '','',da_Block);

  // try to find for every reachable ppu file the unit file in the FPC sources
  FindStandardPPUSources;
  DefTempl:=TDefineTemplate.Create('FPC Unit Links',
    ctsSourceFilenamesForStandardFPCUnits,
    UnitLinks,UnitLinkList,da_DefineRecurse);
  Result.AddChild(DefTempl);

  // The free pascal sources build a world of their own,
  // reset source search path
  MainDir:=TDefineTemplate.Create('Free Pascal Source Directory',
    ctsFreePascalSourceDir,'',FPCSrcDir,da_Directory);
  Result.AddChild(MainDir);
  DefTempl:=TDefineTemplate.Create('Reset SrcPath',
    ctsSrcPathInitialization,ExternalMacroStart+'SrcPath','',da_DefineRecurse);
  MainDir.AddChild(DefTempl);
  DefTempl:=TDefineTemplate.Create('Reset UnitPath',
    ctsSrcPathInitialization,ExternalMacroStart+'UnitPath','',da_DefineRecurse);
  MainDir.AddChild(DefTempl);
  // turn Nested comments on
  DefTempl:=TDefineTemplate.Create('Nested Comments',
    ctsNestedCommentsOn,ExternalMacroStart+'NestedComments','',da_DefineRecurse);
  MainDir.AddChild(DefTempl);

  // compiler
  CompilerDir:=TDefineTemplate.Create('Compiler',ctsCompiler,'','compiler',
     da_Directory);
  MainDir.AddChild(CompilerDir);
  // define 'i386'   ToDo: other types like m68k
  DefTempl:=TDefineTemplate.Create('Define i386',
    ctsDefineProzessorType,'i386','',da_DefineRecurse);
  CompilerDir.AddChild(DefTempl);

  // rtl
  RTLDir:=TDefineTemplate.Create('RTL',ctsRuntimeLibrary,'','rtl',da_Directory);
  MainDir.AddChild(RTLDir);
  s:=IncPathMacro
    +';'+Dir+'rtl'+DS+'objpas'+DS
    +';'+Dir+'rtl'+DS+'inc'+DS
    +';'+Dir+'rtl'+DS+TargetProcessor+DS
    +';'+Dir+'rtl'+DS+SrcOS+DS;
  if (TargetOS<>'') and (TargetOS<>SrcOS) then
    s:=s+';'+Dir+'rtl'+DS+TargetOS+DS;
  RTLDir.AddChild(TDefineTemplate.Create('Include Path',
    Format(ctsIncludeDirectoriesPlusDirs,
    ['objpas, inc,'+TargetProcessor+','+SrcOS]),
    ExternalMacroStart+'IncPath',s,da_DefineRecurse));
  if TargetOS<>'' then begin
    RTLOSDir:=TDefineTemplate.Create('TargetOS','Target OS','',
                                     TargetOS,da_Directory);
    s:=IncPathMacro
      +';'+Dir+'rtl'+DS+TargetOS+DS+TargetProcessor+DS;
    RTLOSDir.AddChild(TDefineTemplate.Create('Include Path',
      Format(ctsIncludeDirectoriesPlusDirs,[TargetProcessor]),
      ExternalMacroStart+'IncPath',s,da_DefineRecurse));
    RTLDir.AddChild(RTLOSDir);
  end;
  RTLWin32Dir:=TDefineTemplate.Create('Win32','Win32','','win32',da_Directory);
  RTLDir.AddChild(RTLWin32Dir);
  RTLWin32Dir.AddChild(TDefineTemplate.Create('Include Path',
      Format(ctsIncludeDirectoriesPlusDirs,['wininc']),
      ExternalMacroStart+'IncPath',
      IncPathMacro+';wininc',da_Define));

  // define 'i386'   ToDo: other types like m68k
  DefTempl:=TDefineTemplate.Create('Define i386',
    ctsDefineProzessorType,'i386','',da_DefineRecurse);
  RTLDir.AddChild(DefTempl);

  // fcl
  FCLDir:=TDefineTemplate.Create('FCL',ctsFreePascalComponentLibrary,'','fcl',
      da_Directory);
  MainDir.AddChild(FCLDir);
  FCLDir.AddChild(TDefineTemplate.Create('Include Path',
    Format(ctsIncludeDirectoriesPlusDirs,['inc,'+SrcOS]),
    ExternalMacroStart+'IncPath',
    IncPathMacro
    +';'+Dir+'fcl'+DS+'inc'+DS
    +';'+Dir+'fcl'+DS+SrcOS+DS
    ,da_DefineRecurse));

  // packages
  PackagesDir:=TDefineTemplate.Create('Packages',ctsPackageDirectories,'',
     'packages',da_Directory);
  MainDir.AddChild(PackagesDir);

  // utils
  UtilsDir:=TDefineTemplate.Create('Utils',ctsUtilsDirectories,'',
     'utils',da_Directory);
  MainDir.AddChild(UtilsDir);
  // utils/debugsvr
  DebugSvrDir:=TDefineTemplate.Create('DebugSvr','Debug Server','',
     'debugsvr',da_Directory);
  UtilsDir.AddChild(DebugSvrDir);
  DebugSvrDir.AddChild(TDefineTemplate.Create('Interface Path',
    Format(ctsAddsDirToSourcePath,['..']),ExternalMacroStart+'SrcPath',
    '..;'+ExternalMacroStart+'SrcPath',da_DefineRecurse));

  // clean up
  if UnitTree<>nil then begin
    UnitTree.FreeAndClear;
    UnitTree.Free;
  end;

  Result.SetDefineOwner(Owner,true);
  Result.SetFlags([dtfAutoGenerated],[],false);
end;

function TDefinePool.CreateDelphiSrcPath(DelphiVersion: integer;
  const PathPrefix: string): string;
begin
  case DelphiVersion of
  6:
    Result:=PathPrefix+'Source/Rtl/Win;'
      +PathPrefix+'Source/Rtl/Sys;'
      +PathPrefix+'Source/Rtl/Common;'
      +PathPrefix+'Source/Rtl/Corba40;'
      +PathPrefix+'Source/Vcl;';
  else
    Result:=PathPrefix+'Source/Rtl/Win;'
      +PathPrefix+'Source/Rtl/Sys;'
      +PathPrefix+'Source/Rtl/Corba;'
      +PathPrefix+'Source/Vcl;';
  end;
end;

function TDefinePool.CreateLazarusSrcTemplate(
  const LazarusSrcDir, WidgetType, ExtraOptions: string;
  Owner: TObject): TDefineTemplate;
type
  TLazWidgetSet = (wsGtk, wsGtk2, wsGnome, wsWin32);
const
  ds: char = PathDelim;
  LazWidgetSets: array[TLazWidgetSet] of string = (
    'gtk','gtk2','gnome','win32');
var
  MainDir, DirTempl, SubDirTempl, IntfDirTemplate, IfTemplate,
  SubTempl: TDefineTemplate;
  TargetOS, SrcPath, WidgetStr: string;
  WidgetSet: TLazWidgetSet;
begin
  Result:=nil;
  if (LazarusSrcDir='') or (WidgetType='') then exit;
  TargetOS:='$('+ExternalMacroStart+'TargetOS)';
  SrcPath:='$('+ExternalMacroStart+'SrcPath)';

  // <LazarusSrcDir>
  MainDir:=TDefineTemplate.Create(
    StdDefTemplLazarusSrcDir, ctsDefsForLazarusSources,'',LazarusSrcDir,
    da_Directory);
  MainDir.AddChild(TDefineTemplate.Create(
    'LCL path addition',
    Format(ctsAddsDirToSourcePath,['lcl']),ExternalMacroStart+'SrcPath',
    'lcl;lcl'+ds+'interfaces'+ds+WidgetType+';'+SrcPath
    ,da_Define));
  MainDir.AddChild(TDefineTemplate.Create(
    'Component path addition',
    Format(ctsAddsDirToSourcePath,['designer, debugger, components']),
    ExternalMacroStart+'SrcPath',
       'designer;'
      +'designer'+ds+'jitform;'
      +'debugger;'
      +'packager;'
      +'packager'+ds+'registration;'
      +'components'+ds+'synedit;'
      +'components'+ds+'codetools;'
      +'components'+ds+'custom;'
      +'components'+ds+'mpaslex;'
      +SrcPath
    ,da_Define));
  MainDir.AddChild(TDefineTemplate.Create('includepath addition',
    Format(ctsSetsIncPathTo,['include, include/TargetOS']),
    ExternalMacroStart+'IncPath',
    'include;include'+ds+TargetOS,
    da_Define));
  // turn Nested comments on
  MainDir.AddChild(TDefineTemplate.Create('Nested Comments',
    ctsNestedCommentsOn,ExternalMacroStart+'NestedComments','',da_DefineRecurse));


  // include

  // designer
  DirTempl:=TDefineTemplate.Create('Designer',ctsDesignerDirectory,
    '','designer',da_Directory);
  DirTempl.AddChild(TDefineTemplate.Create('LCL path addition',
    Format(ctsAddsDirToSourcePath,['lcl']),
    ExternalMacroStart+'SrcPath',
      '..'+ds+'lcl'
      +';..'+ds+'lcl'+ds+'interfaces'+ds+WidgetType
      +';'+SrcPath
    ,da_Define));
  DirTempl.AddChild(TDefineTemplate.Create('main path addition',
    Format(ctsAddsDirToSourcePath,[ctsLazarusMainDirectory]),
    ExternalMacroStart+'SrcPath',
    '..;..'+ds+'packager;'+SrcPath
    ,da_Define));
  DirTempl.AddChild(TDefineTemplate.Create('components path addition',
    Format(ctsAddsDirToSourcePath,['synedit']),
    ExternalMacroStart+'SrcPath',
      '..'+ds+'components'+ds+'synedit;'
      +'..'+ds+'components'+ds+'codetools;'
      +'..'+ds+'components'+ds+'custom;'
      +'jitform;'
      +SrcPath
    ,da_Define));
  DirTempl.AddChild(TDefineTemplate.Create('includepath addition',
    Format(ctsIncludeDirectoriesPlusDirs,['include']),
    ExternalMacroStart+'IncPath',
    '..'+ds+'include;..'+ds+'include'+ds+TargetOS,
    da_Define));
  // designer/jitform
  SubDirTempl:=TDefineTemplate.Create('JITForm',ctsJITFormDirectory,
    '','jitform',da_Directory);
  SubDirTempl.AddChild(TDefineTemplate.Create('LCL path addition',
    Format(ctsAddsDirToSourcePath,['lcl']),
    ExternalMacroStart+'SrcPath',
      '..'+ds+'..'+ds+'lcl'
      +';..'+ds+'..'+ds+'lcl'+ds+'interfaces'+ds+WidgetType
      +';'+SrcPath
    ,da_Define));
  DirTempl.AddChild(SubDirTempl);
  // designer/units
  SubDirTempl:=TDefineTemplate.Create('Designer Units',
    ctsDesignerUnitsDirectory,'','units',da_Directory);
  SubDirTempl.AddChild(TDefineTemplate.Create('CompiledSrcPath',
    ctsCompiledSrcPath,CompiledSrcPathMacroName,'..'+ds+'jitform'+ds,
    da_Define));
  DirTempl.AddChild(SubDirTempl);
  MainDir.AddChild(DirTempl);

  // images

  // debugger
  DirTempl:=TDefineTemplate.Create('Debugger',ctsDebuggerDirectory,
    '','debugger',da_Directory);
  DirTempl.AddChild(TDefineTemplate.Create('LCL path addition',
    Format(ctsAddsDirToSourcePath,['lcl, components']),
    ExternalMacroStart+'SrcPath',
      '..'
      +';..'+ds+'components'+ds+'codetools'
      +';..'+ds+'lcl'
      +';..'+ds+'lcl'+ds+'interfaces'+ds+WidgetType
      +';'+SrcPath
    ,da_DefineRecurse));
  MainDir.AddChild(DirTempl);

  // packager
  DirTempl:=TDefineTemplate.Create('Packager',ctsDesignerDirectory,
    '','packager',da_Directory);
  DirTempl.AddChild(TDefineTemplate.Create('LCL path addition',
    Format(ctsAddsDirToSourcePath,['lcl']),
    ExternalMacroStart+'SrcPath',
      '..'+ds+'lcl'
      +';..'+ds+'lcl'+ds+'interfaces'+ds+WidgetType
      +';'+SrcPath
    ,da_Define));
  DirTempl.AddChild(TDefineTemplate.Create('main path addition',
    Format(ctsAddsDirToSourcePath,[ctsLazarusMainDirectory]),
    ExternalMacroStart+'SrcPath',
    '..;'+SrcPath
    ,da_Define));
  DirTempl.AddChild(TDefineTemplate.Create('components path addition',
    Format(ctsAddsDirToSourcePath,['synedit']),
    ExternalMacroStart+'SrcPath',
       'registration;'
      +'..'+ds+'components'+ds+'synedit;'
      +'..'+ds+'components'+ds+'codetools;'
      +'..'+ds+'components'+ds+'custom;'
      +SrcPath
    ,da_Define));
  DirTempl.AddChild(TDefineTemplate.Create('includepath addition',
    Format(ctsIncludeDirectoriesPlusDirs,['include']),
    ExternalMacroStart+'IncPath',
    '..'+ds+'include;..'+ds+'include'+ds+TargetOS,
    da_Define));
  // packager/registration
  SubDirTempl:=TDefineTemplate.Create('Registration',
    ctsPackagerRegistrationDirectory,'','registration',da_Directory);
  DirTempl.AddChild(SubDirTempl);
  // packager/units
  SubDirTempl:=TDefineTemplate.Create('Packager Units',
    ctsPackagerUnitsDirectory,'','units',da_Directory);
  SubDirTempl.AddChild(TDefineTemplate.Create('CompiledSrcPath',
    ctsCompiledSrcPath,CompiledSrcPathMacroName,'..'+ds+'registration'+ds,
    da_Define));
  DirTempl.AddChild(SubDirTempl);
  MainDir.AddChild(DirTempl);

  // examples
  DirTempl:=TDefineTemplate.Create('Examples',
    Format(ctsNamedDirectory,['Examples']),
    '','examples',da_Directory);
  DirTempl.AddChild(TDefineTemplate.Create('LCL path addition',
    Format(ctsAddsDirToSourcePath,['lcl']),
    ExternalMacroStart+'SrcPath',
    '..'+ds+'lcl;..'+ds+'lcl'+ds+'interfaces'+ds+WidgetType+';'+SrcPath
    ,da_Define));
  MainDir.AddChild(DirTempl);
  
  // lcl
  DirTempl:=TDefineTemplate.Create('LCL',Format(ctsNamedDirectory,['LCL']),
    '','lcl',da_Directory);
  DirTempl.AddChild(TDefineTemplate.Create('IncludePath',
     Format(ctsIncludeDirectoriesPlusDirs,['include']),
     ExternalMacroStart+'IncPath',
     'include',da_Define));
  MainDir.AddChild(DirTempl);
  
  // lcl/units
  SubDirTempl:=TDefineTemplate.Create('Units',Format(ctsNamedDirectory,['Units']),
    '','units',da_Directory);
  SubDirTempl.AddChild(TDefineTemplate.Create('CompiledSrcPath',
     ctsSrcPathForCompiledUnits,CompiledSrcPathMacroName,
     '..',da_Define));
  DirTempl.AddChild(SubDirTempl);
  
  // lcl/units/{gtk,gtk2,gnome,win32}
  for WidgetSet:=Low(TLazWidgetSet) to High(TLazWidgetSet) do begin
    WidgetStr:=LazWidgetSets[WidgetSet];
    IntfDirTemplate:=TDefineTemplate.Create(WidgetStr+'IntfUnitsDirectory',
      ctsGtkIntfDirectory,'',WidgetStr,da_Directory);
    IntfDirTemplate.AddChild(TDefineTemplate.Create('CompiledSrcPath',
       ctsSrcPathForCompiledUnits,
       ExternalMacroStart+'CompiledSrcPath',
       '..'+ds+'..'+ds+'interfaces'+ds+WidgetStr,da_Define));
    SubDirTempl.AddChild(IntfDirTemplate);
  end;

  // lcl/interfaces
  SubDirTempl:=TDefineTemplate.Create('WidgetDirectory',
    ctsWidgetDirectory,'','interfaces',da_Directory);
  // add lcl to the source path of all widget set directories
  SubDirTempl.AddChild(TDefineTemplate.Create('LCL Path',
    Format(ctsAddsDirToSourcePath,['lcl']),ExternalMacroStart+'SrcPath',
    LazarusSrcDir+ds+'lcl;'+SrcPath,da_DefineRecurse));
  DirTempl.AddChild(SubDirTempl);
  
  // lcl/interfaces/gtk
  IntfDirTemplate:=TDefineTemplate.Create('gtkIntfDirectory',
    ctsGtkIntfDirectory,'','gtk',da_Directory);
    // if LCLWidgetType=gtk2
    IfTemplate:=TDefineTemplate.Create('IF '+WidgetType+'=gtk2',
      ctsIfLCLWidgetTypeEqualsGtk2,'',WidgetType+'=gtk2',da_If);
      // then define gtk2
      IfTemplate.AddChild(TDefineTemplate.Create('Define gtk2',
        ctsDefineMacroGTK2,'gtk2','',da_Define));
    IntfDirTemplate.AddChild(IfTemplate);
  SubDirTempl.AddChild(IntfDirTemplate);

  // lcl/interfaces/gtk2
  IntfDirTemplate:=TDefineTemplate.Create('gtk2IntfDirectory',
    ctsGtk2IntfDirectory,'','gtk2',da_Directory);
  // add '../gtk' to the SrcPath
  IntfDirTemplate.AddChild(TDefineTemplate.Create('SrcPath',
    Format(ctsAddsDirToSourcePath,['gtk']),ExternalMacroStart+'SrcPath',
    '..'+ds+'gtk;'+SrcPath,da_Define));
  SubDirTempl.AddChild(IntfDirTemplate);
  
  // lcl/interfaces/gnome
  IntfDirTemplate:=TDefineTemplate.Create('gnomeIntfDirectory',
    ctsGnomeIntfDirectory,'','gnome',da_Directory);
  // add '../gtk' to the SrcPath
  IntfDirTemplate.AddChild(TDefineTemplate.Create('SrcPath',
    Format(ctsAddsDirToSourcePath,['gtk']),ExternalMacroStart+'SrcPath',
    '..'+ds+'gtk;'+SrcPath,da_Define));
    // if LCLWidgetType=gnome2
    IfTemplate:=TDefineTemplate.Create('IF '+WidgetType+'=gnome2',
      ctsIfLCLWidgetTypeEqualsGnome2,'',WidgetType+'=gnome2',da_If);
      // then define gnome2
      IfTemplate.AddChild(TDefineTemplate.Create('Define gnome2',
        ctsDefineMacroGTK2,'gnome2','',da_Define));
    IntfDirTemplate.AddChild(IfTemplate);
  SubDirTempl.AddChild(IntfDirTemplate);

  // lcl/interfaces/win32
  // no special

  // components
  DirTempl:=TDefineTemplate.Create('Components',ctsComponentsDirectory,
    '','components',da_Directory);
  DirTempl.AddChild(TDefineTemplate.Create('LCL Path',
    Format(ctsAddsDirToSourcePath,['lcl']),
    ExternalMacroStart+'SrcPath',
    LazarusSrcDir+ds+'lcl'
    +';'+LazarusSrcDir+ds+'lcl'+ds+'interfaces'+ds+WidgetType
    +';'+SrcPath
    ,da_DefineRecurse));
  MainDir.AddChild(DirTempl);
  
  // components/units
  SubDirTempl:=TDefineTemplate.Create('units',
    'compiled components for the IDE',
    '','units',da_Directory);
  SubDirTempl.AddChild(TDefineTemplate.Create('CompiledSrcPath',
     ctsSrcPathForCompiledUnits,
     ExternalMacroStart+'CompiledSrcPath',
     '..'+ds+'synedit;'
     +'..'+ds+'codetools'
     ,da_Define));
  DirTempl.AddChild(SubDirTempl);

  // components/htmllite
  SubDirTempl:=TDefineTemplate.Create('HTMLLite',
    'HTMLLite',
    '','htmllite',da_Directory);
  SubDirTempl.AddChild(TDefineTemplate.Create('HL_LAZARUS',
    'Define HL_LAZARUS','HL_LAZARUS','',da_DefineRecurse));
  DirTempl.AddChild(SubDirTempl);

  // components/turbopower_ipro
  SubDirTempl:=TDefineTemplate.Create('TurboPower InternetPro',
    'TurboPower InternetPro components',
    '','turbopower_ipro',da_Directory);
  SubDirTempl.AddChild(TDefineTemplate.Create('IP_LAZARUS',
    'Define IP_LAZARUS','IP_LAZARUS','',da_DefineRecurse));
  SubDirTempl.AddChild(TDefineTemplate.Create('codetools',
    Format(ctsAddsDirToSourcePath,['../codetools']),
    ExternalMacroStart+'SrcPath',
    '..'+ds+'codetools'
    +';'+SrcPath
    ,da_DefineRecurse));
  DirTempl.AddChild(SubDirTempl);

  // components/custom
  SubDirTempl:=TDefineTemplate.Create('Custom Components',
    ctsCustomComponentsDirectory,
    '','custom',da_Directory);
  SubDirTempl.AddChild(TDefineTemplate.Create('lazarus standard components',
    Format(ctsAddsDirToSourcePath,['synedit']),
    ExternalMacroStart+'SrcPath',
    '..'+ds+'synedit;'
    +SrcPath
    ,da_DefineRecurse));
  DirTempl.AddChild(SubDirTempl);


  // tools
  DirTempl:=TDefineTemplate.Create('Tools',
    ctsToolsDirectory,
    '','tools',da_Directory);
  DirTempl.AddChild(TDefineTemplate.Create('LCL path addition',
    Format(ctsAddsDirToSourcePath,['lcl']),
    ExternalMacroStart+'SrcPath',
    '..'+ds+'lcl;..'+ds+'lcl'+ds+'interfaces'+ds+WidgetType
    +';..'+ds+'components'+ds+'codetools'
    +';'+SrcPath
    ,da_Define));
  MainDir.AddChild(DirTempl);
  
  // extra options
  SubTempl:=CreateFPCCommandLineDefines(StdDefTemplLazarusBuildOpts,
                                        ExtraOptions,true,Owner);
  MainDir.AddChild(SubTempl);

  // put it all into a block
  if MainDir<>nil then begin
    Result:=TDefineTemplate.Create(StdDefTemplLazarusSources,
       ctsLazarusSources,'','',da_Block);
    Result.AddChild(MainDir);
  end;
  
  Result.SetDefineOwner(Owner,true);
  Result.SetFlags([dtfAutoGenerated],[],false);
end;

function TDefinePool.CreateLCLProjectTemplate(
  const LazarusSrcDir, WidgetType, ProjectDir: string;
  Owner: TObject): TDefineTemplate;
var DirTempl: TDefineTemplate;
begin
  Result:=nil;
  if (LazarusSrcDir='') or (WidgetType='') or (ProjectDir='') then exit;
  DirTempl:=TDefineTemplate.Create('ProjectDir',ctsAnLCLProject,
    '',ProjectDir,da_Directory);
  DirTempl.AddChild(TDefineTemplate.Create('LCL',
    Format(ctsAddsDirToSourcePath,['lcl']),
    ExternalMacroStart+'SrcPath',
    LazarusSrcDir+PathDelim+'lcl;'
     +LazarusSrcDir+PathDelim+'lcl'+PathDelim+'interfaces'
     +PathDelim+WidgetType
     +';$('+ExternalMacroStart+'SrcPath)'
    ,da_DefineRecurse));
  Result:=TDefineTemplate.Create(StdDefTemplLCLProject,
       'LCL Project','','',da_Block);
  Result.AddChild(DirTempl);
  Result.SetDefineOwner(Owner,true);
  Result.SetFlags([dtfAutoGenerated],[],false);
end;

function TDefinePool.CreateDelphiCompilerDefinesTemplate(
  DelphiVersion: integer; Owner: TObject): TDefineTemplate;
var DefTempl: TDefineTemplate;
begin
  DefTempl:=TDefineTemplate.Create('Delphi'+IntToStr(DelphiVersion)
      +' Compiler Defines',
      Format(ctsOtherCompilerDefines,['Delphi'+IntToStr(DelphiVersion)]),
      '','',da_Block);
  DefTempl.AddChild(TDefineTemplate.Create('Reset',
      ctsResetAllDefines,
      '','',da_UndefineAll));
  DefTempl.AddChild(TDefineTemplate.Create('Define macro DELPHI',
      Format(ctsDefineMacroName,['DELPHI']),
      'DELPHI','',da_DefineRecurse));
  DefTempl.AddChild(TDefineTemplate.Create('Define macro FPC_DELPHI',
      Format(ctsDefineMacroName,['FPC_DELPHI']),
      'FPC_DELPHI','',da_DefineRecurse));
  DefTempl.AddChild(TDefineTemplate.Create('Define macro MSWINDOWS',
      Format(ctsDefineMacroName,['MSWINDOWS']),
      'MSWINDOWS','',da_DefineRecurse));

  // version
  case DelphiVersion of
  3:
    DefTempl.AddChild(TDefineTemplate.Create('Define macro VER_110',
        Format(ctsDefineMacroName,['VER_110']),
        'VER_130','',da_DefineRecurse));
  4:
    DefTempl.AddChild(TDefineTemplate.Create('Define macro VER_125',
        Format(ctsDefineMacroName,['VER_125']),
        'VER_130','',da_DefineRecurse));
  5:
    DefTempl.AddChild(TDefineTemplate.Create('Define macro VER_130',
        Format(ctsDefineMacroName,['VER_130']),
        'VER_130','',da_DefineRecurse));
  else
    // else define Delphi 6
    DefTempl.AddChild(TDefineTemplate.Create('Define macro VER_140',
        Format(ctsDefineMacroName,['VER_140']),
        'VER_140','',da_DefineRecurse));
  end;

  DefTempl.AddChild(TDefineTemplate.Create(
     Format(ctsDefineMacroName,[ExternalMacroStart+'Compiler']),
     'Define '+ExternalMacroStart+'Compiler variable',
     ExternalMacroStart+'Compiler','DELPHI',da_DefineRecurse));

  Result:=DefTempl;
  Result.SetDefineOwner(Owner,true);
end;

function TDefinePool.CreateDelphiDirectoryTemplate(
  const DelphiDirectory: string; DelphiVersion: integer;
  Owner: TObject): TDefineTemplate;
var MainDirTempl: TDefineTemplate;
begin
  MainDirTempl:=TDefineTemplate.Create('Delphi'+IntToStr(DelphiVersion)
     +' Directory',
     Format(ctsNamedDirectory,['Delphi'+IntToStr(DelphiVersion)]),
     '',DelphiDirectory,da_Directory);
  MainDirTempl.AddChild(CreateDelphiCompilerDefinesTemplate(DelphiVersion,Owner));
  MainDirTempl.AddChild(TDefineTemplate.Create('SrcPath',
      Format(ctsSetsSrcPathTo,['RTL, VCL']),
      ExternalMacroStart+'SrcPath',
      SetDirSeparators(CreateDelphiSrcPath(DelphiVersion,'$(#DefinePath)/')
                       +'$(#SrcPath)'),
      da_DefineRecurse));

  Result:=MainDirTempl;
  Result.SetDefineOwner(Owner,true);
end;

function TDefinePool.CreateDelphiProjectTemplate(
  const ProjectDir, DelphiDirectory: string;
  DelphiVersion: integer; Owner: TObject): TDefineTemplate;
var MainDirTempl: TDefineTemplate;
begin
  MainDirTempl:=TDefineTemplate.Create('Delphi'+IntToStr(DelphiVersion)+' Project',
     Format(ctsNamedProject,['Delphi'+IntToStr(DelphiVersion)]),
     '',ProjectDir,da_Directory);
  MainDirTempl.AddChild(
    CreateDelphiCompilerDefinesTemplate(DelphiVersion,Owner));
  MainDirTempl.AddChild(TDefineTemplate.Create(
     'Define '+ExternalMacroStart+'DelphiDir',
     Format(ctsDefineMacroName,[ExternalMacroStart+'DelphiDir']),
     ExternalMacroStart+'DelphiDir',DelphiDirectory,da_DefineRecurse));
  MainDirTempl.AddChild(TDefineTemplate.Create('SrcPath',
      Format(ctsAddsDirToSourcePath,['Delphi RTL+VCL']),
      ExternalMacroStart+'SrcPath',
      SetDirSeparators(CreateDelphiSrcPath(DelphiVersion,'$(#DelphiDir)/')
                       +'$(#SrcPath)'),
      da_DefineRecurse));

  Result:=MainDirTempl;
  Result.SetDefineOwner(Owner,true);
end;

function TDefinePool.CreateFPCCommandLineDefines(const Name, CmdLine: string;
  RecursiveDefines: boolean; Owner: TObject): TDefineTemplate;
  
  function ReadNextParam(LastEndPos: integer;
    var StartPos, EndPos: integer): boolean;
  begin
    StartPos:=LastEndPos;
    while (StartPos<=length(CmdLine)) and (CmdLine[StartPos] in [' ',#9]) do
      inc(StartPos);
    EndPos:=StartPos;
    while (EndPos<=length(CmdLine)) and (not (CmdLine[EndPos] in [' ',#9])) do
      inc(EndPos);
    Result:=StartPos<=length(CmdLine);
  end;
  
  procedure AddDefine(const AName, ADescription, AVariable, AValue: string;
    AnAction: TDefineAction);
  var
    NewTempl: TDefineTemplate;
  begin
    if AName='' then exit;
    NewTempl:=TDefineTemplate.Create(AName, ADescription, AVariable, AValue,
                                     AnAction);
    if Result=nil then
      Result:=TDefineTemplate.Create(Name,ctsCommandLineParameters,'','',
                                     da_Block);
    Result.AddChild(NewTempl);
  end;
  
var
  StartPos, EndPos: Integer;
  s: string;
  NewAction: TDefineAction;
begin
  Result:=nil;
  EndPos:=1;
  while ReadNextParam(EndPos,StartPos,EndPos) do begin
    if (StartPos<length(CmdLine)) and (CmdLine[StartPos]='-') then begin
      // a parameter
      case CmdLine[StartPos+1] of

      'd':
        begin
          // define
          s:=copy(CmdLine,StartPos+2,EndPos-StartPos-2);
          if RecursiveDefines then
            NewAction:=da_DefineRecurse
          else
            NewAction:=da_Define;
          AddDefine('Define '+s,ctsDefine+s,s,'',NewAction);
        end;

      end;
    end;
  end;
  Result.SetDefineOwner(Owner,true);
end;

function TDefinePool.ConsistencyCheck: integer;
var i: integer;
begin
  for i:=0 to Count-1 do begin
    Result:=Items[i].ConsistencyCheck;
    if Result<>0 then begin
      dec(Result,100);  exit;
    end;
  end;
  Result:=0;
end;

procedure TDefinePool.WriteDebugReport;
var i: integer;
begin
  writeln('TDefinePool.WriteDebugReport Consistency=',ConsistencyCheck);
  for i:=0 to Count-1 do begin
    Items[i].WriteDebugReport(false);
  end;
end;


end.

