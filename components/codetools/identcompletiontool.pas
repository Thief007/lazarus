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
    TIdentCompletionTool enhances the TFindDeclarationTool with the ability
    to create lists of valid identifiers at a specific code position.
}
unit IdentCompletionTool;

{$mode objfpc}{$H+}

interface

{$I codetools.inc}

// activate for debug:

// mem check
{ $DEFINE MEM_CHECK}

// verbosity
{ $DEFINE CTDEBUG}
{ $DEFINE ShowFoundIdents}
{ $DEFINE ShowFilteredIdents}
{ $DEFINE ShowHistory}
{ $DEFINE VerboseCodeContext}

uses
  {$IFDEF MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, typinfo, FileProcs, CodeTree, CodeAtom, CodeCache,
  CustomCodeTool, CodeToolsStrConsts, KeywordFuncLists, BasicCodeTools,
  LinkScanner, AVL_Tree, CodeToolMemManager, DefineTemplates, SourceChanger,
  FindDeclarationTool, PascalReaderTool, PascalParserTool, CodeToolsStructs,
  ExprEval;
  
type
  TIdentCompletionTool = class;
  TIdentifierHistoryList = class;

  //----------------------------------------------------------------------------
  // gathered identifier list

  TIdentifierCompatibility = (
    icompExact,
    icompCompatible,
    icompUnknown,
    icompIncompatible
    );
  TIdentifierCompatibilities = set of TIdentifierCompatibility;
  
  TIdentListItemFlag = (
    iliHasChilds,
    iliBaseExprTypeValid,
    iliIsFunction,
    iliIsFunctionValid,
    iliIsAbstractMethod,
    iliIsAbstractMethodValid,
    iliParamTypeListValid,
    iliParamNameListValid,
    iliNodeValid,
    iliNodeHashValid,
    iliNodeGoneWarned,
    iliIsConstructor,
    iliIsConstructorValid,
    iliIsDestructor,
    iliIsDestructorValid,
    iliKeyword,
    iliResultTypeValid,
    iliHasIndexValid,
    iliHasIndex,
    iliHasParamListValid,
    iliHasParamList,
    iliIsReadOnlyValid,
    iliIsReadOnly,
    iliHintModifiersValid,
    iliIsDeprecated,
    iliIsPlatform,
    iliIsExperimental,
    iliIsUnimplemented,
    iliIsLibrary,
    iliAtCursor // the item is the identifier at the completion
    );
  TIdentListItemFlags = set of TIdentListItemFlag;
  
  { TIdentifierListSearchItem }

  TIdentifierListSearchItem = class
  public
    Identifier: PChar;
    ParamList: string;
    function CalcMemSize: PtrUInt;
  end;

  { TIdentifierListItem }

  TIdentifierListItem = class
  private
    FParamTypeList: string;
    FParamNameList: string;
    FNode: TCodeTreeNode;
    FResultType: string;
    FToolNodesDeletedStep: integer;// only valid if iliNodeValid
    FNodeStartPos: integer;
    FNodeDesc: TCodeTreeNodeDesc;
    FNodeHash: string;
    function GetNode: TCodeTreeNode;
    function GetParamTypeList: string;
    function GetParamNameList: string;
    procedure SetNode(const AValue: TCodeTreeNode);
    procedure SetParamTypeList(const AValue: string);
    procedure SetParamNameList(const AValue: string);
    procedure SetResultType(const AValue: string);
  public
    Compatibility: TIdentifierCompatibility;
    HistoryIndex: integer;
    Identifier: string;
    Level: integer;
    Tool: TFindDeclarationTool;
    DefaultDesc: TCodeTreeNodeDesc;
    Flags: TIdentListItemFlags;
    BaseExprType: TExpressionType;
    function AsString: string;
    function GetDesc: TCodeTreeNodeDesc;
    constructor Create(NewCompatibility: TIdentifierCompatibility;
                       NewHasChilds: boolean; NewHistoryIndex: integer;
                       NewIdentifier: PChar; NewLevel: integer;
                       NewNode: TCodeTreeNode; NewTool: TFindDeclarationTool;
                       NewDefaultDesc: TCodeTreeNodeDesc);
    function IsProcNodeWithParams: boolean;
    function IsPropertyWithParams: boolean;
    function IsPropertyReadOnly: boolean;
    function GetHintModifiers: TPascalHintModifiers;
    function CheckHasChilds: boolean;
    function CanBeAssigned: boolean;
    procedure UpdateBaseContext;
    function HasChilds: boolean;
    function HasIndex: boolean;
    function IsFunction: boolean;
    function IsContructor: boolean;
    function IsDestructor: boolean;
    function IsAbstractMethod: boolean;
    function TryIsAbstractMethod: boolean;
    procedure Clear;
    procedure UnbindNode;
    procedure StoreNodeHash;
    function RestoreNode: boolean;
    function GetNodeHash(ANode: TCodeTreeNode): string;
    function CompareParamList(CompareItem: TIdentifierListItem): integer;
    function CompareParamList(CompareItem: TIdentifierListSearchItem): integer;
    function CalcMemSize: PtrUInt;
  public
    property ParamTypeList: string read GetParamTypeList write SetParamTypeList;
    property ParamNameList: string read GetParamNameList write SetParamNameList;
    property ResultType: string read FResultType write SetResultType;
    property Node: TCodeTreeNode read GetNode write SetNode;
  end;
  
  TIdentifierListFlag = (
    ilfFilteredListNeedsUpdate,
    ilfUsedToolsNeedsUpdate
    );
  TIdentifierListFlags = set of TIdentifierListFlag;
  
  TIdentifierListContextFlag = (
    ilcfStartInStatement,  // context starts in statements. e.g. between begin..end
    ilcfStartOfStatement,  // atom is start of statement. e.g. 'A|:=' or 'A|;', does not check if A can be assigned
    ilcfStartOfOperand,    // atom is start of an operand. e.g. 'A|.B'
    ilcfStartIsSubIdent,   // atom in front is point
    ilcfNeedsEndSemicolon, // after context a semicolon is needed. e.g. 'A| end'
    ilcfNoEndSemicolon,    // no semicolon after. E.g. 'A| else'
    ilcfNeedsEndComma,     // after context a comma is needed. e.g. 'uses sysutil| classes'
    ilcfNeedsDo,           // after context a 'do' is needed. e.g. 'with Form1| do'
    ilcfIsExpression,      // is expression part of statement. e.g. 'if expr'
    ilcfCanProcDeclaration,// context allows one to declare a procedure/method
    ilcfEndOfLine          // atom at end of line
    );
  TIdentifierListContextFlags = set of TIdentifierListContextFlag;
  
  TIdentifierList = class
  private
    FContext: TFindContext;
    FNewMemberVisibility: TCodeTreeNodeDesc;
    FContextFlags: TIdentifierListContextFlags;
    FStartAtom: TAtomPosition;
    FStartAtomBehind: TAtomPosition;
    FStartAtomInFront: TAtomPosition;
    FStartBracketLvl: integer;
    FStartContextPos: TCodeXYPosition;
    FCreatedIdentifiers: TFPList; // list of PChar
    FFilteredList: TFPList; // list of TIdentifierListItem
    FFlags: TIdentifierListFlags;
    FHistory: TIdentifierHistoryList;
    FItems: TAVLTree; // tree of TIdentifierListItem (completely sorted)
    FIdentView: TAVLTree; // tree of TIdentHistListItem sorted for identifiers
    FUsedTools: TAVLTree; // tree of TFindDeclarationTool
    FIdentSearchItem: TIdentifierListSearchItem;
    FPrefix: string;
    FStartContext: TFindContext;
    procedure SetHistory(const AValue: TIdentifierHistoryList);
    procedure UpdateFilteredList;
    function GetFilteredItems(Index: integer): TIdentifierListItem;
    procedure SetPrefix(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(NewItem: TIdentifierListItem);
    function Count: integer;
    function GetFilteredCount: integer;
    function HasIdentifier(Identifier: PChar; const ParamList: string): boolean;
    function FindIdentifier(Identifier: PChar; const ParamList: string): TIdentifierListItem;
    function FindIdentifier(Identifier: PChar; PreferProc: boolean): TIdentifierListItem;
    function FindCreatedIdentifier(const Ident: string): integer;
    function CreateIdentifier(const Ident: string): PChar;
    function StartUpAtomInFrontIs(const s: string): boolean;
    function StartUpAtomBehindIs(const s: string): boolean;
    function CompletePrefix(const OldPrefix: string): string;
    function CalcMemSize: PtrUInt;
  public
    property Context: TFindContext read FContext write FContext;
    property ContextFlags: TIdentifierListContextFlags
                                       read FContextFlags write FContextFlags;
    property NewMemberVisibility: TCodeTreeNodeDesc // identifier is a class member, e.g. a variable or a procedure name
                     read FNewMemberVisibility write FNewMemberVisibility;
    property FilteredItems[Index: integer]: TIdentifierListItem
                                                          read GetFilteredItems;
    property History: TIdentifierHistoryList read FHistory write SetHistory;
    property Prefix: string read FPrefix write SetPrefix;
    property StartAtom: TAtomPosition read FStartAtom write FStartAtom;
    property StartAtomInFront: TAtomPosition
                                 read FStartAtomInFront write FStartAtomInFront; // in front of variable, not only of identifier
    property StartAtomBehind: TAtomPosition
                                   read FStartAtomBehind write FStartAtomBehind; // directly behind
    property StartBracketLvl: integer
                                   read FStartBracketLvl write FStartBracketLvl;
    property StartContext: TFindContext read FStartContext write FStartContext;
    property StartContextPos: TCodeXYPosition
                                   read FStartContextPos write FStartContextPos;
  end;
  
  //----------------------------------------------------------------------------
  // history list

  { TIdentHistListItem }

  TIdentHistListItem = class
  public
    Identifier: string;
    NodeDesc: TCodeTreeNodeDesc;
    ParamList: string;
    HistoryIndex: integer;
    function CalcMemSize: PtrUInt;
  end;

  { TIdentifierHistoryList }

  TIdentifierHistoryList = class
  private
    FCapacity: integer;
    FItems: TAVLTree; // tree of TIdentHistListItem
    procedure SetCapacity(const AValue: integer);
    function FindItem(NewItem: TIdentifierListItem): TAVLTreeNode;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(NewItem: TIdentifierListItem);
    function GetHistoryIndex(AnItem: TIdentifierListItem): integer;
    function Count: integer;
    function CalcMemSize: PtrUInt;
  public
    property Capacity: integer read FCapacity write SetCapacity;
  end;


  //----------------------------------------------------------------------------

  { TCodeContextInfoItem }

  TCodeContextInfoItem = class
  public
    Expr: TExpressionType;
    // compiler predefined proc
    ProcName: string;
    Params: TStringList;
    ResultType: string;
    destructor Destroy; override;
  end;

  { TCodeContextInfo }

  TCodeContextInfo = class
  private
    FEndPos: integer;
    FItems: TFPList; // list of TCodeContextInfoItem
    FParameterIndex: integer;
    FProcName: string;
    FProcNameAtom: TAtomPosition;
    FStartPos: integer;
    FTool: TFindDeclarationTool;
    function GetItems(Index: integer): TCodeContextInfoItem;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: integer;
    property Items[Index: integer]: TCodeContextInfoItem read GetItems; default;
    function Add(const Context: TExpressionType): integer;
    function AddCompilerProc: integer;
    procedure Clear;
    property Tool: TFindDeclarationTool read FTool write FTool;
    property ParameterIndex: integer read FParameterIndex write FParameterIndex;// 1 based
    property ProcName: string read FProcName write FProcName;
    property ProcNameAtom: TAtomPosition read FProcNameAtom write FProcNameAtom;
    property StartPos: integer read FStartPos write FStartPos;// context is valid from StartPos to EndPos
    property EndPos: integer read FEndPos write FEndPos;

    function CalcMemSize: PtrUInt;
  end;

  //----------------------------------------------------------------------------
  // TIdentCompletionTool

  TIdentCompletionTool = class(TFindDeclarationTool)
  private
    FBeautifier: TBeautifyCodeOptions;
    FLastGatheredIdentParent: TCodeTreeNode;
    FLastGatheredIdentLevel: integer;
    FICTClassAndAncestors: TFPList;// list of PCodeXYPosition
    FIDCTFoundPublicProperties: TAVLTree;// tree of PChar (pointing to the
                                    // property names in source)
    FIDTFoundMethods: TAVLTree;// tree of TCodeTreeNodeExtension Txt=clean text
    FIDTTreeOfUnitFiles: TAVLTree;// tree of TUnitFileInfo
    procedure AddToTreeOfUnitFileInfo(const AFilename: string);
    procedure AddBaseConstant(const BaseName: PChar);
    procedure AddBaseType(const BaseName: PChar);
    procedure AddCompilerFunction(const AProcName, AParameterList,
      AResultType: PChar);
    procedure AddCompilerProcedure(const AProcName, AParameterList: PChar);
    procedure AddKeyWord(aKeyWord: string);
  protected
    CurrentIdentifierList: TIdentifierList;
    CurrentIdentifierContexts: TCodeContextInfo;
    function CollectAllIdentifiers(Params: TFindDeclarationParams;
      const FoundContext: TFindContext): TIdentifierFoundResult;
    procedure GatherPredefinedIdentifiers(CleanPos: integer;
      const Context: TFindContext);
    procedure GatherUsefulIdentifiers(CleanPos: integer;
      const Context: TFindContext);
    procedure GatherUnitnames;
    procedure GatherSourceNames(const Context: TFindContext);
    procedure GatherContextKeywords(const Context: TFindContext;
      CleanPos: integer; BeautifyCodeOptions: TBeautifyCodeOptions);
    procedure InitCollectIdentifiers(const CursorPos: TCodeXYPosition;
      var IdentifierList: TIdentifierList);
    procedure ParseSourceTillCollectionStart(const CursorPos: TCodeXYPosition;
      out CleanCursorPos: integer; out CursorNode: TCodeTreeNode;
      out IdentStartPos, IdentEndPos: integer);
    function FindIdentifierStartPos(const CursorPos: TCodeXYPosition
                                      ): TCodeXYPosition;
    procedure FindCollectionContext(Params: TFindDeclarationParams;
      IdentStartPos: integer; CursorNode: TCodeTreeNode;
      out GatherContext: TFindContext; out ContextExprStartPos: LongInt;
      out StartInSubContext: Boolean);
    function CollectAllContexts(Params: TFindDeclarationParams;
      const FoundContext: TFindContext): TIdentifierFoundResult;
    procedure AddCollectionContext(Tool: TFindDeclarationTool;
      Node: TCodeTreeNode);
    function IsInCompilerDirective(CursorPos: TCodeXYPosition): boolean;
    procedure AddCompilerDirectiveMacros(Directive: string);
  public
    function GatherAvailableUnitNames(const CursorPos: TCodeXYPosition;
                             var IdentifierList: TIdentifierList): Boolean;
    function GatherIdentifiers(const CursorPos: TCodeXYPosition;
                            var IdentifierList: TIdentifierList): boolean;
    function FindCodeContext(const CursorPos: TCodeXYPosition;
                             out CodeContexts: TCodeContextInfo): boolean;
    function FindAbstractMethods(const CursorPos: TCodeXYPosition;
                                 out ListOfPCodeXYPosition: TFPList;
                                 SkipAbstractsInStartClass: boolean = false): boolean;
    function GetValuesOfCaseVariable(const CursorPos: TCodeXYPosition;
                                     List: TStrings): boolean;
    property Beautifier: TBeautifyCodeOptions read FBeautifier write FBeautifier;

    procedure CalcMemSize(Stats: TCTMemStats); override;
  end;

function dbgs(Flag: TIdentifierListContextFlag): string; overload;
function dbgs(Flags: TIdentifierListContextFlags): string; overload;
  
implementation

const
  CompilerFuncHistoryIndex = 10;
  CompilerFuncLevel = 10;

function CompareIdentListItems(Data1, Data2: Pointer): integer;
var
  Item1: TIdentifierListItem absolute Data1;
  Item2: TIdentifierListItem absolute Data2;
begin
  // first sort for Compatibility  (lower is better)
  if ord(Item1.Compatibility)<ord(Item2.Compatibility) then begin
    Result:=-1;
    exit;
  end else if ord(Item1.Compatibility)>ord(Item2.Compatibility) then begin
    Result:=1;
    exit;
  end;
  
  // then sort for History (lower is better)
  if Item1.HistoryIndex<Item2.HistoryIndex then begin
    Result:=-1;
    exit;
  end else if Item1.HistoryIndex>Item2.HistoryIndex then begin
    Result:=1;
    exit;
  end;

  // then sort for Level (lower is better)
  if Item1.Level<Item2.Level then begin
    Result:=-1;
    exit;
  end else if Item1.Level>Item2.Level then begin
    Result:=1;
    exit;
  end;

  // then sort alpabetically (lower is better)
  Result:=CompareIdentifierPtrs(Pointer(Item2.Identifier),Pointer(Item1.Identifier));
  if Result<>0 then exit;
  
  // then sort for ParamList (lower is better)
  Result:=Item2.CompareParamList(Item1);
end;

function CompareIdentListItemsForIdents(Data1, Data2: Pointer): integer;
var
  Item1: TIdentifierListItem absolute Data1;
  Item2: TIdentifierListItem absolute Data2;
begin
  // sort alpabetically (lower is better)
  Result:=CompareIdentifierPtrs(Pointer(Item2.Identifier),Pointer(Item1.Identifier));
  if Result<>0 then exit;

  // then sort for ParamList (lower is better)
  Result:=Item2.CompareParamList(Item1);
end;

function CompareIdentListSearchWithItems(SearchItem, Item: Pointer): integer;
var
  TheSearchItem: TIdentifierListSearchItem absolute SearchItem;
  TheItem: TIdentifierListItem absolute Item;
begin
  // sort alpabetically (lower is better)
  Result:=CompareIdentifierPtrs(Pointer(TheItem.Identifier),TheSearchItem.Identifier);
  if Result<>0 then exit;

  // then sort for ParamList (lower is better)
  Result:=TheItem.CompareParamList(TheSearchItem);
end;

function CompareIdentListSearchWithItemsWithoutParams(SearchItem, Item: Pointer): integer;
var
  TheSearchItem: TIdentifierListSearchItem absolute SearchItem;
  TheItem: TIdentifierListItem absolute Item;
begin
  // sort alpabetically (lower is better)
  Result:=CompareIdentifierPtrs(Pointer(TheItem.Identifier),TheSearchItem.Identifier);
end;

function CompareIdentHistListItem(Data1, Data2: Pointer): integer;
var
  Item1: TIdentHistListItem absolute Data1;
  Item2: TIdentHistListItem absolute Data2;
begin
  Result:=CompareIdentifiers(PChar(Pointer(Item2.Identifier)),
                             PChar(Pointer(Item1.Identifier)));
  if Result<>0 then exit;

  //debugln('CompareIdentHistListItem ',Item2.Identifier,'=',Item1.Identifier);
  Result:=CompareIdentifiers(PChar(Pointer(Item2.ParamList)),
                             PChar(Pointer(Item1.ParamList)));
end;

function CompareIdentItemWithHistListItem(Data1, Data2: Pointer): integer;
var
  IdentItem: TIdentifierListItem absolute Data1;
  HistItem: TIdentHistListItem absolute Data2;
begin
  Result:=CompareIdentifierPtrs(Pointer(HistItem.Identifier),
                                Pointer(IdentItem.Identifier));
  if Result<>0 then exit;

  //debugln('CompareIdentItemWithHistListItem ',HistItem.Identifier,'=',GetIdentifier(IdentItem.Identifier));
  Result:=SysUtils.CompareText(HistItem.ParamList,IdentItem.ParamTypeList);
end;

function dbgs(Flag: TIdentifierListContextFlag): string;
begin
  Result:=GetEnumName(typeinfo(Flag),ord(Flag));
end;

function dbgs(Flags: TIdentifierListContextFlags): string;
var
  f: TIdentifierListContextFlag;
begin
  Result:='';
  for f:=Low(TIdentifierListContextFlag) to High(TIdentifierListContextFlag) do
    if f in Flags then begin
      if Result<>'' then Result+=',';
      Result+=dbgs(f);
    end;
  Result:='['+Result+']';
end;

{ TIdentifierList }

procedure TIdentifierList.SetPrefix(const AValue: string);
begin
  if FPrefix=AValue then exit;
  FPrefix:=AValue;
  Include(FFlags,ilfFilteredListNeedsUpdate);
end;

procedure TIdentifierList.UpdateFilteredList;
var
  AnAVLNode: TAVLTreeNode;
  CurItem: TIdentifierListItem;
begin
  if not (ilfFilteredListNeedsUpdate in FFlags) then exit;
  if FFilteredList=nil then FFilteredList:=TFPList.Create;
  FFilteredList.Count:=0;
  FFilteredList.Capacity:=FItems.Count;
  {$IFDEF CTDEBUG}
  DebugLn(['TIdentifierList.UpdateFilteredList Prefix="',Prefix,'"']);
  {$ENDIF}
  AnAVLNode:=FItems.FindLowest;
  while AnAVLNode<>nil do begin
    CurItem:=TIdentifierListItem(AnAVLNode.Data);
    if (CurItem.Identifier<>'')
    and ComparePrefixIdent(PChar(Pointer(Prefix)),PChar(Pointer(CurItem.Identifier)))
    then begin
      {$IFDEF ShowFilteredIdents}
      DebugLn(['::: FILTERED ITEM ',FFilteredList.Count,' ',CurItem.Identifier]);
      {$ENDIF}
      if (length(Prefix)=length(CurItem.Identifier))
      and (not (iliAtCursor in CurItem.Flags)) then
        // put exact matches at the beginning
        FFilteredList.Insert(0,CurItem)
      else
        FFilteredList.Add(CurItem);
    end;
    AnAVLNode:=FItems.FindSuccessor(AnAVLNode);
  end;
  {$IFDEF CTDEBUG}
  DebugLn(['TIdentifierList.UpdateFilteredList ',dbgs(FFilteredList.Count),' of ',dbgs(FItems.Count)]);
  {$ENDIF}
  Exclude(FFlags,ilfFilteredListNeedsUpdate);
end;

procedure TIdentifierList.SetHistory(const AValue: TIdentifierHistoryList);
begin
  if FHistory=AValue then exit;
  FHistory:=AValue;
end;

function TIdentifierList.GetFilteredItems(Index: integer): TIdentifierListItem;
begin
  UpdateFilteredList;
  if (Index<0) or (Index>=FFilteredList.Count) then
    Result:=nil
  else
    Result:=TIdentifierListItem(FFilteredList[Index]);
end;

constructor TIdentifierList.Create;
begin
  FFlags:=[ilfFilteredListNeedsUpdate];
  FItems:=TAVLTree.Create(@CompareIdentListItems);
  FIdentView:=TAVLTree.Create(@CompareIdentListItemsForIdents);
  FIdentSearchItem:=TIdentifierListSearchItem.Create;
  FCreatedIdentifiers:=TFPList.Create;
end;

destructor TIdentifierList.Destroy;
begin
  Clear;
  FreeAndNil(FUsedTools);
  FreeAndNil(FItems);
  FreeAndNil(FIdentView);
  FreeAndNil(FFilteredList);
  FreeAndNil(FIdentSearchItem);
  FreeAndNil(FCreatedIdentifiers);
  inherited Destroy;
end;

procedure TIdentifierList.Clear;
var
  i: Integer;
  p: Pointer;
begin
  fContextFlags:=[];
  fContext:=CleanFindContext;
  FNewMemberVisibility:=ctnNone;
  FStartBracketLvl:=0;
  fStartContext:=CleanFindContext;
  fStartContextPos.Code:=nil;
  fStartContextPos.X:=1;
  fStartContextPos.Y:=1;
  for i:=0 to FCreatedIdentifiers.Count-1 do begin
    p:=FCreatedIdentifiers[i];
    FreeMem(p);
  end;
  FCreatedIdentifiers.Clear;
  FItems.FreeAndClear;
  FIdentView.Clear;
  if FUsedTools<>nil then
    FUsedTools.Clear;
  FFlags:=FFlags+[ilfFilteredListNeedsUpdate,ilfUsedToolsNeedsUpdate];
end;

procedure TIdentifierList.Add(NewItem: TIdentifierListItem);
var
  AnAVLNode: TAVLTreeNode;
begin
  AnAVLNode:=FIdentView.FindKey(NewItem,@CompareIdentListItemsForIdents);
  if AnAVLNode=nil then begin
    if History<>nil then
      NewItem.HistoryIndex:=History.GetHistoryIndex(NewItem);
    FItems.Add(NewItem);
    FIdentView.Add(NewItem);
    FFlags:=FFlags+[ilfFilteredListNeedsUpdate,ilfUsedToolsNeedsUpdate];
  end else begin
    // redefined identifier -> ignore
    //DebugLn('TIdentifierList.Add redefined: ',NewItem.AsString);
    NewItem.Free;
  end;
end;

function TIdentifierList.Count: integer;
begin
  Result:=FItems.Count;
end;

function TIdentifierList.GetFilteredCount: integer;
begin
  UpdateFilteredList;
  Result:=FFilteredList.Count;
end;

function TIdentifierList.HasIdentifier(Identifier: PChar;
  const ParamList: string): boolean;
begin
  FIdentSearchItem.Identifier:=Identifier;
  FIdentSearchItem.ParamList:=ParamList;
  Result:=FIdentView.FindKey(FIdentSearchItem,
                             @CompareIdentListSearchWithItems)<>nil;
end;

function TIdentifierList.FindIdentifier(Identifier: PChar;
  const ParamList: string): TIdentifierListItem;
var
  AVLNode: TAVLTreeNode;
begin
  FIdentSearchItem.Identifier:=Identifier;
  FIdentSearchItem.ParamList:=ParamList;
  AVLNode:=FIdentView.FindKey(FIdentSearchItem,@CompareIdentListSearchWithItems);
  if AVLNode<>nil then
    Result:=TIdentifierListItem(AVLNode.Data)
  else
    Result:=nil;
end;

function TIdentifierList.FindIdentifier(Identifier: PChar; PreferProc: boolean
  ): TIdentifierListItem;
var
  AVLNode: TAVLTreeNode;
  StartNode: TAVLTreeNode;
begin
  Result:=nil;
  FIdentSearchItem.Identifier:=Identifier;
  // ignore ParamList (for checking function overloading)
  StartNode:=FIdentView.FindKey(FIdentSearchItem,@CompareIdentListSearchWithItemsWithoutParams);
  if StartNode=nil then exit;
  // identifier found, check preference
  if (TIdentifierListItem(StartNode.Data).GetDesc in [ctnProcedure,ctnProcedureHead])=PreferProc
  then
    exit(TIdentifierListItem(StartNode.Data));

  // identifier is a (not) proc, find the same identifier that fits PreferProc

  // search in next nodes
  AVLNode:=StartNode;
  repeat
    AVLNode:=FIdentView.FindSuccessor(AVLNode);
    if (AVLNode=nil)
    or (CompareIdentifiers(Identifier,PChar(TIdentifierListItem(AVLNode.Data).Identifier))<>0)
    then break;
    if (TIdentifierListItem(AVLNode.Data).GetDesc in [ctnProcedure,ctnProcedureHead])=PreferProc
    then
      exit(TIdentifierListItem(AVLNode.Data));
  until false;
  // search in previous nodes
  AVLNode:=StartNode;
  repeat
    AVLNode:=FIdentView.FindPrecessor(AVLNode);
    if (AVLNode=nil)
    or (CompareIdentifiers(Identifier,PChar(TIdentifierListItem(AVLNode.Data).Identifier))<>0)
    then break;
    if (TIdentifierListItem(AVLNode.Data).GetDesc in [ctnProcedure,ctnProcedureHead])=PreferProc
    then
      exit(TIdentifierListItem(AVLNode.Data));
  until false;
end;

function TIdentifierList.FindCreatedIdentifier(const Ident: string): integer;
begin
  if Ident<>'' then begin
    Result:=FCreatedIdentifiers.Count-1;
    while (Result>=0)
    and (CompareIdentifiers(PChar(Pointer(Ident)),
                            PChar(Pointer(FCreatedIdentifiers[Result])))<>0)
    do
      dec(Result);
  end else begin
    Result:=-1;
  end;
end;

function TIdentifierList.CreateIdentifier(const Ident: string): PChar;
var
  i: Integer;
begin
  if Ident<>'' then begin
    i:=FindCreatedIdentifier(Ident);
    if i>=0 then
      Result:=PChar(Pointer(FCreatedIdentifiers[i]))
    else begin
      GetMem(Result,length(Ident)+1);
      Move(Ident[1],Result^,length(Ident)+1);
      FCreatedIdentifiers.Add(Result);
    end;
  end else
    Result:=nil;
end;

function TIdentifierList.StartUpAtomInFrontIs(const s: string): boolean;
begin
  Result:=StartContext.Tool.FreeUpAtomIs(StartAtomInFront,s);
end;

function TIdentifierList.StartUpAtomBehindIs(const s: string): boolean;
begin
  Result:=StartContext.Tool.FreeUpAtomIs(StartAtomBehind,s);
end;

function TIdentifierList.CompletePrefix(const OldPrefix: string): string;
// search all identifiers beginning with Prefix
// and return the biggest prefix of all of them
var
  AnAVLNode: TAVLTreeNode;
  CurItem: TIdentifierListItem;
  FoundFirst: Boolean;
  SamePos: Integer;
  l: Integer;
begin
  Result:=Prefix;
  FoundFirst:=false;
  AnAVLNode:=FItems.FindLowest;
  while AnAVLNode<>nil do begin
    CurItem:=TIdentifierListItem(AnAVLNode.Data);
    if (CurItem.Identifier<>'')
    and ComparePrefixIdent(PChar(Pointer(Prefix)),PChar(Pointer(CurItem.Identifier)))
    and (not (iliAtCursor in CurItem.Flags))
    then begin
      if not FoundFirst then begin
        Result:=CurItem.Identifier;
        FoundFirst:=true;
      end else begin
        SamePos:=length(Prefix)+1;
        l:=length(Result);
        if l>length(CurItem.Identifier) then
          l:=length(CurItem.Identifier);
        while (SamePos<=l)
        and (UpChars[CurItem.Identifier[SamePos]]=UpChars[Result[SamePos]])
        do
          inc(SamePos);
        if SamePos<=length(Result) then begin
          Result:=copy(Result,1,SamePos-1);
          if length(Result)=length(Prefix) then exit;
        end;
      end;
    end;
    AnAVLNode:=FItems.FindSuccessor(AnAVLNode);
  end;
end;

function TIdentifierList.CalcMemSize: PtrUInt;
var
  i: Integer;
  Node: TAVLTreeNode;
  li: TIdentifierListItem;
  hli: TIdentHistListItem;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(FPrefix);
  if FCreatedIdentifiers<>nil then begin
    inc(Result,MemSizeFPList(FCreatedIdentifiers));
    for i:=0 to FCreatedIdentifiers.Count-1 do
      inc(Result,GetIdentLen(PChar(FCreatedIdentifiers[i])));
  end;
  if FFilteredList<>nil then begin
    inc(Result,MemSizeFPList(FFilteredList));
    for i:=0 to FFilteredList.Count-1 do
      inc(Result,TIdentifierListItem(FFilteredList[i]).CalcMemSize);
  end;
  if FHistory<>nil then begin
    inc(Result,FHistory.CalcMemSize);
  end;
  if FItems<>nil then begin
    inc(Result,FItems.Count*SizeOf(TAVLTreeNode));
    Node:=FItems.FindLowest;
    while Node<>nil do begin
      li:=TIdentifierListItem(Node.Data);
      inc(Result,li.CalcMemSize);
      Node:=FItems.FindSuccessor(Node);
    end;
  end;
  if FIdentView<>nil then begin
    inc(Result,FIdentView.Count*SizeOf(TAVLTreeNode));
    Node:=FIdentView.FindLowest;
    while Node<>nil do begin
      hli:=TIdentHistListItem(Node.Data);
      inc(Result,hli.CalcMemSize);
      Node:=FIdentView.FindSuccessor(Node);
    end;
  end;
  if FIdentSearchItem<>nil then
    inc(Result,FIdentSearchItem.CalcMemSize);
end;

{ TIdentCompletionTool }

procedure TIdentCompletionTool.AddToTreeOfUnitFileInfo(const AFilename: string);
begin
  AddToTreeOfUnitFiles(FIDTTreeOfUnitFiles,AFilename,false);
end;

procedure TIdentCompletionTool.AddCompilerProcedure(const AProcName, AParameterList: PChar);
var
  NewItem: TIdentifierListItem;
begin
  //DebugLn(['AddCompilerProcedure ',AProcName,' ',ilcfStartOfStatement in CurrentIdentifierList.ContextFlags]);
  if not (ilcfStartOfStatement in CurrentIdentifierList.ContextFlags) then exit;
  if not (ilcfStartOfOperand in CurrentIdentifierList.ContextFlags) then exit;

  NewItem:=TIdentifierListItem.Create(
      icompUnknown,
      false,
      CompilerFuncHistoryIndex,
      AProcName,
      CompilerFuncLevel,
      nil,
      nil,
      ctnProcedure);
  NewItem.ParamTypeList:=AParameterList;
  NewItem.ParamNameList:=AParameterList;
  NewItem.Flags:=NewItem.Flags+[iliParamTypeListValid,iliParamNameListValid];
  CurrentIdentifierList.Add(NewItem);
end;

procedure TIdentCompletionTool.AddKeyWord(aKeyWord: string);
var
  NewItem: TIdentifierListItem;
begin
  NewItem:=TIdentifierListItem.Create(
      icompExact,false,0,
      CurrentIdentifierList.CreateIdentifier(aKeyWord),
      1000,nil,nil,ctnNone);
  include(NewItem.Flags,iliKeyword);
  CurrentIdentifierList.Add(NewItem);
end;

procedure TIdentCompletionTool.AddCompilerFunction(const AProcName, AParameterList,
  AResultType: PChar);
var
  NewItem: TIdentifierListItem;
begin
  if not (ilcfStartOfOperand in CurrentIdentifierList.ContextFlags) then exit;

  NewItem:=TIdentifierListItem.Create(
      icompUnknown,
      false,
      CompilerFuncHistoryIndex,
      AProcName,
      CompilerFuncLevel,
      nil,
      nil,
      ctnProcedure);
  NewItem.ParamTypeList:=AParameterList;
  NewItem.ParamNameList:=AParameterList;
  NewItem.ResultType:=AResultType;
  NewItem.Flags:=NewItem.Flags+[iliParamTypeListValid,iliParamNameListValid,
                         iliIsFunction,iliIsFunctionValid,iliResultTypeValid];
  CurrentIdentifierList.Add(NewItem);
end;

procedure TIdentCompletionTool.AddBaseType(const BaseName: PChar);
var
  NewItem: TIdentifierListItem;
begin
  NewItem:=TIdentifierListItem.Create(
      icompUnknown,
      false,
      CompilerFuncHistoryIndex,
      BaseName,
      CompilerFuncLevel,
      nil,
      nil,
      ctnTypeDefinition);
  CurrentIdentifierList.Add(NewItem);
end;

procedure TIdentCompletionTool.AddBaseConstant(const BaseName: PChar);
var
  NewItem: TIdentifierListItem;
begin
  NewItem:=TIdentifierListItem.Create(
      icompUnknown,
      false,
      CompilerFuncHistoryIndex,
      BaseName,
      CompilerFuncLevel,
      nil,
      nil,
      ctnConstant);
  CurrentIdentifierList.Add(NewItem);
end;

function TIdentCompletionTool.CollectAllIdentifiers(
  Params: TFindDeclarationParams; const FoundContext: TFindContext
  ): TIdentifierFoundResult;
var
  Ident: PChar;
  CurContextParent: TCodeTreeNode;

  function ProtectedNodeIsInAllowedClass: boolean;
  var
    CurClassNode: TCodeTreeNode;
    FoundClassContext: TFindContext;
  begin
    Result:=false;
    if FICTClassAndAncestors<>nil then begin
      // start of the identifier completion is in a method or class
      // => all protected ancestor classes are allowed as well.
      CurClassNode:=FoundContext.Node;
      while (CurClassNode<>nil)
      and (not (CurClassNode.Desc in AllClasses)) do
        CurClassNode:=CurClassNode.Parent;
      if CurClassNode=nil then exit;
      FoundClassContext:=CreateFindContext(Params.NewCodeTool,CurClassNode);
      if IndexOfFindContext(FICTClassAndAncestors,@FoundClassContext)>=0 then begin
        // this class node is the class or one of the ancestors of the class
        // of the start context of the identifier completion
        exit(true);
      end;
    end;
    //DebugLn(['ProtectedNodeIsInAllowedClass hidden: ',FindContextToString(FoundContext)]);
  end;
  
  function PropertyIsOverridenPublicPublish: boolean;
  begin
    // protected properties can be made public in child classes.
    //debugln('PropertyIsOverridenPublicPublish Identifier=',GetIdentifier(Ident),' Find=',dbgs((FIDCTFoundPublicProperties<>nil) and (FIDCTFoundPublicProperties.Find(Ident)<>nil)));
    if FIDCTFoundPublicProperties<>nil then begin
      if FIDCTFoundPublicProperties.Find(Ident)<>nil then begin
        // there is a public/published property with the same name
        exit(true);
      end;
    end;
    Result:=false;
  end;
  
  procedure SavePublicPublishedProperty;
  begin
    if FIDCTFoundPublicProperties=nil then begin
      // create tree
      FIDCTFoundPublicProperties:=
                         TAVLTree.Create(TListSortCompare(@CompareIdentifiers))
    end else if FIDCTFoundPublicProperties.Find(Ident)<>nil then begin
      // identifier is already public
      exit;
    end;
    FIDCTFoundPublicProperties.Add(Ident);
    //debugln('SavePublicPublishedProperty Identifier=',GetIdentifier(Ident),' Find=',dbgs(FIDCTFoundPublicProperties.Find(Ident)<>nil));
  end;
  
var
  NewItem: TIdentifierListItem;
  Node: TCodeTreeNode;
  ProtectedForeignClass: Boolean;
  Lvl: LongInt;
  NamePos: TAtomPosition;
begin
  // proceed searching ...
  Result:=ifrProceedSearch;

  {$IFDEF ShowFoundIdents}
  if FoundContext.Tool=Self then
  DebugLn('::: COLLECT IDENT ',FoundContext.Node.DescAsString,
    ' "',StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)),'"'
    ,' '+dbgs(fdfIgnoreUsedUnits in Params.Flags));
  {$ENDIF}

  CurContextParent:=FoundContext.Node.GetFindContextParent;
  if FLastGatheredIdentParent<>CurContextParent then begin
    // new context level
    FLastGatheredIdentParent:=CurContextParent;
    inc(FLastGatheredIdentLevel);
  end;

  Lvl:=FLastGatheredIdentLevel;

  ProtectedForeignClass:=false;
  if FoundContext.Tool=Self then begin
    // identifier is in the same unit
    //DebugLn('::: COLLECT IDENT in SELF ',FoundContext.Node.DescAsString,
    //  ' "',dbgstr(FoundContext.Tool.Src,FoundContext.Node.StartPos,50),'"'
    //  ,' fdfIgnoreUsedUnits='+dbgs(fdfIgnoreUsedUnits in Params.Flags));
    if (FoundContext.Node=CurrentIdentifierList.StartContext.Node)
    or (FoundContext.Node=CurrentIdentifierList.Context.Node)
    or (FoundContext.Node.StartPos=CurrentIdentifierList.StartAtom.StartPos)
    then begin
      // found identifier is in cursor node
      // => do not show it
      exit;
    end;
  end else begin
    // identifier is in another unit
    Node:=FoundContext.Node.Parent;
    if (Node<>nil) and (Node.Desc in AllClassSubSections) then
      Node:=Node.Parent;
    if (Node<>nil) and (Node.Desc in AllClassBaseSections) then begin
      //debugln(['TIdentCompletionTool.CollectAllIdentifiers Node=',Node.DescAsString,' Context=',CurrentIdentifierList.Context.Node.DescAsString,' CtxVis=',NodeDescToStr(CurrentIdentifierList.NewMemberVisibility)]);
      if (CurrentIdentifierList.NewMemberVisibility<>ctnNone)
      and (CurrentIdentifierList.NewMemberVisibility<Node.Desc)
      and (CurrentIdentifierList.Context.Node.Desc
        in ([ctnProcedure,ctnProcedureHead,ctnProperty]+AllClassSections))
      then begin
        // the user wants to override a method or property
        // => ignore all with a higher visibility, because fpc does not allow
        //    to downgrade the visibility and will give a hint when trying
        //debugln(['TIdentCompletionTool.CollectAllIdentifiers skipping member, because it would downgrade: ',dbgstr(FoundContext.Tool.ExtractNode(FoundContext.Node,[]),1,30)]);
        exit;
      end;
      case Node.Desc of
      ctnClassPrivate:
        begin
          // skip private definitions in other units
          exit;
        end;
      ctnClassProtected:
        begin
          // protected definitions are only accessible from descendants
          // or if visibility was raised (e.g. property)
          if ProtectedNodeIsInAllowedClass then begin
            // protected node in an ancestor => allowed
            //debugln('TIdentCompletionTool.CollectAllIdentifiers ALLOWED Protected in ANCESTOR '+StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)));
          end else if (FoundContext.Node.Desc=ctnProperty) then begin
            // protected property: maybe the visibility was raised => continue
            ProtectedForeignClass:=true;
            //debugln('TIdentCompletionTool.CollectAllIdentifiers MAYBE Protected made Public '+StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)));
          end else begin
            // otherwise: treat as private
            //debugln('TIdentCompletionTool.CollectAllIdentifiers FORBIDDEN Protected '+StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)));
            exit;
          end;
        end;
      end;
    end;
  end;

  Ident:=nil;
  case FoundContext.Node.Desc of
  
  ctnTypeDefinition,ctnGenericType:
    begin
      Node:=FoundContext.Node.FirstChild;
      if FoundContext.Node.Desc=ctnTypeDefinition then
        Ident:=@FoundContext.Tool.Src[FoundContext.Node.StartPos]
      else begin
        // generic
        if Node=nil then exit;
        Ident:=@FoundContext.Tool.Src[Node.StartPos];
      end;
      if Node=nil then begin
        // type without definition
      end;
      if (Node<>nil)
      and (Node.Desc in AllClasses)
      and ((ctnsForwardDeclaration and Node.SubDesc)>0)
      then begin
        // forward definition of a class
        if CurrentIdentifierList.FindIdentifier(Ident,'')<>nil then begin
          // the real class is already in the list => skip forward
          exit;
        end;
      end;
    end;
  
  ctnVarDefinition,ctnConstDefinition,ctnEnumIdentifier,ctnGlobalProperty:
    Ident:=@FoundContext.Tool.Src[FoundContext.Node.StartPos];
    
  ctnProcedure,ctnProcedureHead:
    begin
      Ident:=FoundContext.Tool.GetProcNameIdentifier(FoundContext.Node);
      NewItem := CurrentIdentifierList.FindIdentifier(Ident,true);
      if (NewItem<>nil) and (NewItem.Tool<>nil) then begin
        if (NewItem.GetNode<>nil) then begin
          if (FoundContext.Node.Parent.Desc in AllClassBaseSections)
            <> (NewItem.Node.Parent.Desc in AllClassBaseSections)
          then
            exit; // class members hide normal procs and nested procs hide class members
          if (Lvl <> NewItem.Level) then begin
            // there is a previous declaration on a different level
            if (NewItem.Node.Desc<>ctnProcedure)
            or (not NewItem.Tool.ProcNodeHasSpecifier(NewItem.Node, psOVERLOAD))
            then
              exit; // there is a previous declaration without 'overload'
          end;
        end;
      end;
    end;
    
  ctnProperty:
    begin
      Ident:=FoundContext.Tool.GetPropertyNameIdentifier(FoundContext.Node);
      if FoundContext.Tool.PropNodeIsTypeLess(FoundContext.Node) then begin
        if FoundContext.Node.Parent.Desc in [ctnClassPublic,ctnClassPublished]
        then
          SavePublicPublishedProperty;
        // do not show properties without types (e.g. property Color;)
        // only show the real definition, which will follow in the ancestor
        exit;
      end;
      if (FoundContext.Node.Parent.Desc=ctnClassPrivate)
      and (FoundContext.Tool<>Self)
      and (not PropertyIsOverridenPublicPublish) then begin
        // a private property in another unit, that was not
        // made public/publish later
        // => skip
        exit;
      end;
      if (FoundContext.Node.Parent.Desc=ctnClassProtected)
      and ProtectedForeignClass
      and (not PropertyIsOverridenPublicPublish) then begin
        // a protected property in another unit, that was not
        // made public/publish later
        // => skip
        exit;
      end;
    end;
    
  ctnRecordCase:
    Ident:=@FoundContext.Tool.Src[Params.NewCleanPos];

  ctnUseUnit:
    if (FoundContext.Tool=Self) then begin
      Ident:=@Src[FoundContext.Node.StartPos];
    end;

  ctnUnit,ctnProgram,ctnLibrary,ctnPackage:
    if (FoundContext.Tool=Self)
    and GetSourceNamePos(NamePos) then
      Ident:=@Src[NamePos.StartPos];

  end;
  if Ident=nil then exit;

  NewItem:=TIdentifierListItem.Create(
                            icompUnknown,
                            false,
                            0,
                            Ident,
                            Lvl,
                            FoundContext.Node,
                            FoundContext.Tool,
                            ctnNone);
  if (FoundContext.Node=CurrentIdentifierList.StartContext.Node) then begin
    // found identifier is in cursor node
    Include(NewItem.Flags,iliAtCursor);
  end;

  {$IFDEF ShowFoundIdents}
  if FoundContext.Tool=Self then
  DebugLn('  IDENT COLLECTED: ',NewItem.AsString);
  {$ENDIF}
  
  CurrentIdentifierList.Add(NewItem);
end;

procedure TIdentCompletionTool.GatherPredefinedIdentifiers(CleanPos: integer;
  const Context: TFindContext);
// Add predefined identifiers

  function StatementLevel: integer;
  var
    ANode: TCodeTreeNode;
  begin
    Result:=0;
    ANode:=Context.Node;
    while (ANode<>nil) and (not (ANode.Desc in [ctnBeginBlock,ctnAsmBlock])) do
    begin
      ANode:=ANode.Parent;
      inc(Result);
    end;
    if ANode=nil then Result:=0;
  end;
  
  procedure AddSystemUnit(const AnUnitName: PChar);
  var
    NewItem: TIdentifierListItem;
  begin
    NewItem:=TIdentifierListItem.Create(
        icompUnknown,
        false,
        CompilerFuncHistoryIndex,
        AnUnitName,
        CompilerFuncLevel,
        nil,
        nil,
        ctnUseUnit);
    CurrentIdentifierList.Add(NewItem);
  end;

var
  NewItem: TIdentifierListItem;
  ProcNode: TCodeTreeNode;
  HidddnUnits: String;
  p: PChar;
begin
  if not (ilcfStartOfOperand in CurrentIdentifierList.ContextFlags) then exit;

  if Context.Node.Desc in AllPascalStatements then begin
    // see fpc/compiler/psystem.pp
    AddCompilerProcedure('Assert','Condition:Boolean;const Message:String');
    AddCompilerFunction('Assigned','P:Pointer','Boolean');
    AddCompilerFunction('Addr','var X','Pointer');
    AddCompilerFunction('BitSizeOf','Identifier','Integer');
    AddCompilerProcedure('Break','');
    AddCompilerFunction('Concat','S1:String;S2:String[...;Sn:String]', 'String');
    AddCompilerProcedure('Continue','');
    AddCompilerFunction('Copy','const S:String;FromPosition,Count:Integer', 'String');
    AddCompilerProcedure('Dec','var X:Ordinal;N:Integer=1');
    AddCompilerProcedure('Dispose','var X:Pointer');
    AddCompilerProcedure('Exclude','var S:Set;X:Ordinal');
    AddCompilerProcedure('Exit','');
    AddCompilerProcedure('Finalize','var X');
    AddCompilerFunction('get_frame','','Pointer');
    AddCompilerFunction('High','Arg:TypeOrVariable','Ordinal');
    AddCompilerProcedure('Inc','var X:Ordinal;N:Integer=1');
    AddCompilerProcedure('Include','var S:Set;X:Ordinal');
    AddCompilerProcedure('Initialize','var X');
    AddCompilerFunction('Length','S:String','Ordinal');
    AddCompilerFunction('Length','A:Array','Ordinal');
    AddCompilerFunction('Low','Arg:TypeOrVariable','Ordinal');
    AddCompilerProcedure('New','var X:Pointer');
    AddCompilerFunction('ObjCSelector','String','SEL');
    AddCompilerFunction('Ofs','var X','LongInt');
    AddCompilerFunction('Ord','X:Ordinal', 'Integer');
    AddCompilerProcedure('Pack','A:Array;N:Integer;var A:Array');
    AddCompilerFunction('Pred','X:Ordinal', 'Ordinal');
    AddCompilerProcedure('Read','');
    AddCompilerProcedure('ReadLn','');
    AddCompilerProcedure('ReadStr','S:String;var Args:Arguments');
    AddCompilerFunction('Seg','var X','LongInt');
    AddCompilerProcedure('SetLength','var S:String;NewLength:Integer');
    AddCompilerProcedure('SetLength','var A:Array;NewLength:Integer');
    AddCompilerFunction('SizeOf','Identifier','Integer');
    AddCompilerFunction('Slice','var A:Array;Count:Integer','Array');
    AddCompilerProcedure('Str','const X[:Width[:Decimals]];var S:String');
    AddCompilerFunction('Succ','X:Ordinal', 'Ordinal');
    AddCompilerFunction('TypeInfo','Identifier', 'Pointer');
    AddCompilerFunction('TypeOf','Identifier', 'Pointer');
    AddCompilerProcedure('Val','S:String;var V;var Code:Integer');
    AddCompilerFunction('Unaligned','var X','var'); // Florian declaration :)
    AddCompilerProcedure('Unpack','A:Array;var A:Array;N:Integer');
    AddCompilerProcedure('Write','Args:Arguments');
    AddCompilerProcedure('WriteLn','Args:Arguments');
    AddCompilerProcedure('WriteStr','var S:String;Args:Arguments');

    if (ilcfStartOfOperand in CurrentIdentifierList.ContextFlags)
    and Context.Tool.NodeIsInAMethod(Context.Node)
    and (not CurrentIdentifierList.HasIdentifier('Self','')) then begin
      // method body -> add 'Self'
      NewItem:=TIdentifierListItem.Create(
          icompUnknown,
          true,
          1,
          'Self',
          StatementLevel,
          nil,
          nil,
          ctnVarDefinition);
      CurrentIdentifierList.Add(NewItem);
    end;
    ProcNode:=Context.Node.GetNodeOfType(ctnProcedure);
    if (ilcfStartOfOperand in CurrentIdentifierList.ContextFlags)
    and Context.Tool.NodeIsFunction(ProcNode)
    and (not CurrentIdentifierList.HasIdentifier('Result','')) then begin
      // function body -> add 'Result'
      NewItem:=TIdentifierListItem.Create(
          icompUnknown,
          true,
          1,
          'Result',
          StatementLevel,
          nil,
          nil,
          ctnVarDefinition);
      CurrentIdentifierList.Add(NewItem);
    end;
  end;

  // system types
  AddBaseType('Char');
  AddBaseType('WideChar');
  AddBaseType('Real');
  AddBaseType('Single');
  AddBaseType('Double');
  AddBaseType('Extended');
  AddBaseType('CExtended');
  AddBaseType('Currency');
  AddBaseType('Comp');
  AddBaseType('Int64');
  AddBaseType('Cardinal');
  AddBaseType('QWord');
  AddBaseType('Boolean');
  AddBaseType('ByteBool');
  AddBaseType('WordBool');
  AddBaseType('LongBool');
  AddBaseType('QWordBool');
  AddBaseType('String');
  AddBaseType('AnsiString');
  AddBaseType('ShortString');
  AddBaseType('WideString');
  AddBaseType('UnicodeString');
  AddBaseType('Pointer');
  AddBaseType('LongInt');
  AddBaseType('Word');
  AddBaseType('SmallInt');
  AddBaseType('ShortInt');
  AddBaseType('Byte');
  if not (ilcfStartInStatement in CurrentIdentifierList.ContextFlags) then begin
    AddBaseType('File');
    AddBaseType('Text');
  end;
  AddBaseConstant('Nil');
  AddBaseConstant('True');
  AddBaseConstant('False');

  // system units
  HidddnUnits:=Scanner.GetHiddenUsedUnits;
  if HidddnUnits<>'' then begin
    p:=PChar(HidddnUnits);
    while p^<>#0 do begin
      while p^=',' do inc(p);
      if GetIdentLen(p)>0 then
        AddSystemUnit(p);
      while not (p^ in [',',#0]) do inc(p);
    end;
  end;
end;

procedure TIdentCompletionTool.GatherUsefulIdentifiers(CleanPos: integer;
  const Context: TFindContext);

  procedure AddPropertyProc(ProcName: string);
  var
    NewItem: TIdentifierListItem;
  begin
    NewItem:=TIdentifierListItem.Create(
        icompExact,true,0,
        CurrentIdentifierList.CreateIdentifier(ProcName),
        0,nil,nil,ctnProcedure);
    CurrentIdentifierList.Add(NewItem);
  end;

var
  PropertyName: String;
begin
  //debugln(['TIdentCompletionTool.GatherUsefulIdentifiers ',CleanPosToStr(CleanPos),' ',dbgsFC(Context)]);
  GatherPredefinedIdentifiers(CleanPos,Context);
  if Context.Node.Desc=ctnProperty then begin
    PropertyName:=ExtractPropName(Context.Node,false);
    //debugln('TIdentCompletionTool.GatherUsefulIdentifiers Property ',PropertyName);
    MoveCursorToCleanPos(CleanPos);
    ReadPriorAtom;
    //debugln(['TIdentCompletionTool.GatherUsefulIdentifiers Atom=',GetAtom]);
    if UpAtomIs('READ') then begin
      // add the default class completion 'read' specifier function
      AddPropertyProc(Beautifier.PropertyReadIdentPrefix+PropertyName);
    end;
    if UpAtomIs('WRITE') then begin
      // add the default class completion 'write' specifier function
      AddPropertyProc(Beautifier.PropertyWriteIdentPrefix+PropertyName);
    end;
    if (UpAtomIs('READ') or UpAtomIs('WRITE'))
    and (Context.Tool.FindClassOrInterfaceNode(Context.Node)<>nil)
    then begin
      // add the default class completion 'read'/'write' specifier variable
      AddPropertyProc(Beautifier.PrivateVariablePrefix+PropertyName);
    end;
    if UpAtomIs('STORED') then begin
      // add the default class completion 'stored' specifier function
      AddPropertyProc(PropertyName+Beautifier.PropertyStoredIdentPostfix);
    end;
  end;
end;

procedure TIdentCompletionTool.GatherUnitnames;

  procedure GatherUnitsFromSet;
  begin
    // collect all unit files in fpc unit paths
    DirectoryCache.IterateFPCUnitsInSet(@AddToTreeOfUnitFileInfo);
  end;

var
  UnitPath, SrcPath: string;
  BaseDir: String;
  ANode: TAVLTreeNode;
  UnitFileInfo: TUnitFileInfo;
  NewItem: TIdentifierListItem;
  UnitExt: String;
  SrcExt: String;
  CurSourceName: String;
begin
  UnitPath:='';
  SrcPath:='';
  GatherUnitAndSrcPath(UnitPath,SrcPath);
  //DebugLn('TIdentCompletionTool.GatherUnitnames UnitPath="',UnitPath,'" SrcPath="',SrcPath,'"');
  BaseDir:=ExtractFilePath(MainFilename);
  FIDTTreeOfUnitFiles:=nil;
  try
    // search in unitpath
    UnitExt:='pp;pas;ppu';
    if Scanner.CompilerMode=cmMacPas then
      UnitExt:=UnitExt+';p';
    GatherUnitFiles(BaseDir,UnitPath,UnitExt,false,true,FIDTTreeOfUnitFiles);
    // search in srcpath
    SrcExt:='pp;pas';
    if Scanner.CompilerMode=cmMacPas then
      SrcExt:=SrcExt+';p';
    GatherUnitFiles(BaseDir,SrcPath,SrcExt,false,true,FIDTTreeOfUnitFiles);
    // add unitlinks
    GatherUnitsFromSet;
    // create list
    CurSourceName:=GetSourceName;
    ANode:=FIDTTreeOfUnitFiles.FindLowest;
    while ANode<>nil do begin
      UnitFileInfo:=TUnitFileInfo(ANode.Data);
      if CompareIdentifiers(PChar(Pointer(UnitFileInfo.FileUnitName)),
                            PChar(Pointer(CurSourceName)))<>0
      then begin
        NewItem:=TIdentifierListItem.Create(
            icompCompatible,true,0,
            CurrentIdentifierList.CreateIdentifier(UnitFileInfo.FileUnitName),
            0,nil,nil,ctnUnit);
        CurrentIdentifierList.Add(NewItem);
      end;
      ANode:=FIDTTreeOfUnitFiles.FindSuccessor(ANode);
    end;
  finally
    FreeTreeOfUnitFiles(FIDTTreeOfUnitFiles);
  end;
end;

procedure TIdentCompletionTool.GatherSourceNames(const Context: TFindContext);

  procedure Add(const SrcName: string);
  var
    NewItem: TIdentifierListItem;
  begin
    NewItem:=TIdentifierListItem.Create(
        icompExact,true,0,
        CurrentIdentifierList.CreateIdentifier(SrcName),
        0,nil,nil,Context.Node.Desc);
    CurrentIdentifierList.Add(NewItem);
  end;

var
  NewSourceName: String;
  FileSourceName: String;
begin
  // add the unitname as in the filename and as in the source
  FileSourceName:=ExtractFilenameOnly(MainFilename);
  NewSourceName:=GetSourceName(false);
  //DebugLn('TIdentCompletionTool.GatherSourceNames FileSourceName=',FileSourceName,' NewSourceName=',NewSourceName);
  if (FileSourceName<>lowercase(FileSourceName)) then begin
    // the file is not written lowercase => case is important, ignore source name
    Add(FileSourceName);
  end else if (SysUtils.CompareText(NewSourceName,FileSourceName)<>0) then begin
    // source name is not correct => only use file name
    Add(FileSourceName);
  end else if NewSourceName=FileSourceName then begin
    // both are the same => add only one
    Add(FileSourceName);
  end else begin
    // both are valid, just different in case
    // the filename is written lowercase
    // => prefer the source name
    Add(NewSourceName);
  end;
end;

procedure TIdentCompletionTool.GatherContextKeywords(
  const Context: TFindContext; CleanPos: integer;
  BeautifyCodeOptions: TBeautifyCodeOptions);
type
  TPropertySpecifier = (
    psIndex,psRead,psWrite,psStored,psImplements,psDefault,psNoDefault
  );
  TPropertySpecifiers = set of TPropertySpecifier;

  procedure Add(Keyword: string);
  var
    NewItem: TIdentifierListItem;
  begin
    KeyWord:=BeautifyCodeOptions.BeautifyKeyWord(Keyword);
    NewItem:=TIdentifierListItem.Create(
        icompExact,false,0,
        CurrentIdentifierList.CreateIdentifier(Keyword),
        1000,nil,nil,ctnNone);
    include(NewItem.Flags,iliKeyword);
    CurrentIdentifierList.Add(NewItem);
  end;

  procedure AddSpecifiers(Forbidden: TPropertySpecifiers);
  begin
    if not (psIndex in Forbidden) then Add('index');
    if not (psRead in Forbidden) then Add('read');
    if not (psWrite in Forbidden) then Add('write');
    if not (psStored in Forbidden) then Add('stored');
    if not (psImplements in Forbidden) then Add('implements');
    if not (psDefault in Forbidden) then Add('default');
    if not (psNoDefault in Forbidden) then Add('nodefault');
  end;

  procedure CheckProperty(PropNode: TCodeTreeNode);
  var
    Forbidden: TPropertySpecifiers;
  begin
    if not MoveCursorToPropType(PropNode) then exit;
    if CleanPos<CurPos.EndPos then exit;
    ReadNextAtom;
    if CurPos.Flag=cafPoint then begin
      ReadNextAtom;
      if CurPos.Flag<>cafWord then exit;
      ReadNextAtom;
    end;
    Forbidden:=[];
    repeat
      if CleanPos<=CurPos.EndPos then begin
        AddSpecifiers(Forbidden);
        exit;
      end;
      if (not (psIndex in Forbidden)) and UpAtomIs('INDEX') then begin
        ReadNextAtom;
        Include(Forbidden,psIndex);
      end else if (not (psRead in Forbidden)) and UpAtomIs('READ') then begin
        ReadNextAtom;
        Forbidden:=Forbidden+[psIndex..psRead];
      end else if (not (psWrite in Forbidden)) and UpAtomIs('WRITE') then begin
        ReadNextAtom;
        Forbidden:=Forbidden+[psIndex..psWrite];
      end else if (not (psImplements in Forbidden)) and UpAtomIs('IMPLEMENTS')
      then begin
        ReadNextAtom;
        exit;
      end else if (not (psStored in Forbidden)) and UpAtomIs('STORED') then
      begin
        ReadNextAtom;
        Forbidden:=Forbidden+[psIndex..psImplements];
      end else if (not (psDefault in Forbidden)) and UpAtomIs('DEFAULT') then
      begin
        ReadNextAtom;
        exit;
      end else if (not (psNoDefault in Forbidden)) and UpAtomIs('NODEFAULT') then
      begin
        ReadNextAtom;
        exit;
      end else if CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen] then begin
        if not ReadTilBracketClose(false) then exit;
      end else
        ReadNextAtom;
    until (CleanPos<CurPos.StartPos) or (CurPos.EndPos>SrcLen);
  end;

  procedure AddMethodSpecifiers;
  var
    i: Integer;
  begin
    for i:=0 to IsKeyWordMethodSpecifier.Count-1 do
      Add(IsKeyWordMethodSpecifier.GetItem(i).KeyWord+';');
  end;

var
  Node: TCodeTreeNode;
  SubNode: TCodeTreeNode;
  NodeInFront: TCodeTreeNode;
  p: Integer;
  NodeBehind: TCodeTreeNode;
begin
  try
    Node:=Context.Node;
    //debugln(['TIdentCompletionTool.GatherContextKeywords ',Node.DescAsString]);

    ReadPriorAtomSafe(CleanPos);
    //debugln(['TIdentCompletionTool.GatherContextKeywords prioratom=',CleanPosToStr(CurPos.StartPos),'=',GetAtom(CurPos)]);
    NodeInFront:=nil;
    if CurPos.StartPos>0 then
      NodeInFront:=FindDeepestNodeAtPos(CurPos.StartPos,false);

    NodeBehind:=nil;
    MoveCursorToCleanPos(CleanPos);
    ReadNextAtom;
    //debugln(['TIdentCompletionTool.GatherContextKeywords nextatom=',CleanPosToStr(CurPos.StartPos),'=',GetAtom(CurPos)]);
    if CurPos.StartPos>CleanPos then
      NodeBehind:=FindDeepestNodeAtPos(CurPos.StartPos,false);

    //debugln(['TIdentCompletionTool.GatherContextKeywords Node=',Node.DescAsString,' NodeInFront=',NodeInFront.DescAsString,' NodeBehind=',NodeBehind.DescAsString]);

    case Node.Desc of
    ctnClass,ctnObject,ctnRecordType,ctnObjCCategory,ctnObjCClass,
    ctnClassPrivate,ctnClassProtected,ctnClassPublic,ctnClassPublished:
      begin
        Add('public');
        Add('private');
        Add('protected');
        Add('published');
        Add('procedure');
        Add('function');
        Add('property');
        if (Node.Desc=ctnClass) or (Node.Parent.Desc=ctnClass) then begin
          Add('constructor');
          Add('destructor');
        end;
        if (Node.Desc=ctnRecordType) or (Node.Parent.Desc=ctnRecordType) then begin
          Add('case');
        end;
        if (Node.LastChild<>nil) and (CleanPos>Node.LastChild.StartPos)
        and (Node.LastChild.EndPos>Node.LastChild.StartPos)
        and (Node.LastChild.EndPos<Srclen) then begin
          //debugln(['TIdentCompletionTool.GatherContextKeywords end of class section ',dbgstr(copy(Src,Node.LastChild.EndPos-10,10))]);
          SubNode:=Node.LastChild;
          if SubNode.Desc=ctnProperty then begin
            CheckProperty(SubNode);
          end;
        end;
        if NodeInFront<>nil then begin
          if NodeInFront.Desc=ctnProcedure then
            AddMethodSpecifiers;
        end;
      end;

    ctnClassInterface,ctnDispinterface,ctnObjCProtocol,ctnCPPClass:
      begin
        Add('procedure');
        Add('function');
      end;

    ctnInterface,ctnImplementation:
      begin
        if (Node.FirstChild=nil)
        or ((Node.FirstChild.Desc<>ctnUsesSection)
          and (Node.FirstChild.StartPos>=CleanPos))
        then
          Add('uses');
        Add('type');
        Add('var');
        Add('const');
        Add('procedure');
        Add('function');
        Add('resourcestring');
        if Node.Desc=ctnInterface then begin
          Add('property');
        end;
        if (NodeBehind=nil)
        or (NodeBehind.Desc in [ctnInitialization,ctnFinalization,ctnEndPoint,ctnBeginBlock])
        then begin
          if Node.Desc=ctnInterface then
            Add('implementation');
          Add('initialization');
          Add('finalization');
        end;
      end;

    ctnInitialization:
      if (NodeBehind=nil)
      or (NodeBehind.Desc in [ctnInitialization,ctnFinalization,ctnEndPoint,ctnBeginBlock])
      then begin
        Add('finalization');
        Add('begin');
      end;

    ctnProcedure:
      begin
        Add('begin');
        Add('type');
        Add('var');
        Add('const');
        Add('procedure');
        Add('function');
      end;

    ctnProcedureHead:
      begin
        MoveCursorBehindProcName(Node);
        p:=CurPos.StartPos;
        while (p>=1) and (Src[p] in [' ',#9]) do dec(p);
        if CleanPos>=p then
          AddMethodSpecifiers;
      end;

    ctnVarDefinition:
      if Node.Parent.Desc in [ctnClass,ctnObject,ctnRecordType,ctnObjCCategory,ctnObjCClass]
        +AllClassBaseSections
      then begin
        Add('public');
        Add('private');
        Add('protected');
        Add('published');
        Add('procedure');
        Add('function');
        Add('property');
        if [cmsObjectiveC1,cmsObjectiveC2]*Scanner.CompilerModeSwitches<>[] then
        begin
          Add('required');
          Add('optional');
        end;
        if (Node.Desc=ctnClass) or (Node.Parent.Desc=ctnClass) then begin
          Add('constructor');
          Add('destructor');
        end;
        if (Node.Desc=ctnRecordType) or (Node.Parent.Desc=ctnRecordType) then begin
          Add('case');
        end;
      end;

    ctnTypeSection,ctnVarSection,ctnConstSection,ctnLabelSection,ctnResStrSection,
    ctnLibrary,ctnProgram:
      begin
        Add('type');
        Add('const');
        Add('var');
        Add('resourcestring');
        Add('procedure');
        Add('function');
        Add('property');
        if Node.Desc=ctnLibrary then begin
          Add('initialization');
          Add('finalization');
          Add('begin');
        end;
      end;

    ctnProperty:
      CheckProperty(Node);

    end;
  except
    // ignore parser errors
    on E: ECodeToolError do ;
    on E: ELinkScannerError do ;
  end;
end;

procedure TIdentCompletionTool.InitCollectIdentifiers(
  const CursorPos: TCodeXYPosition; var IdentifierList: TIdentifierList);
var
  StartContext: TFindContext;
begin
  if IdentifierList=nil then IdentifierList:=TIdentifierList.Create;
  CurrentIdentifierList:=IdentifierList;
  CurrentIdentifierList.Clear;
  FLastGatheredIdentParent:=nil;
  FLastGatheredIdentLevel:=0;
  CurrentIdentifierList.StartContextPos:=CursorPos;
  StartContext := CurrentIdentifierList.StartContext;
  StartContext.Tool := Self;
  CurrentIdentifierList.StartContext:=StartContext;
end;

procedure TIdentCompletionTool.ParseSourceTillCollectionStart(
  const CursorPos: TCodeXYPosition; out CleanCursorPos: integer;
  out CursorNode: TCodeTreeNode; out IdentStartPos, IdentEndPos: integer);
var
  StartContext: TFindContext;
  ContextPos: Integer;
begin
  CleanCursorPos:=0;
  CursorNode:=nil;
  IdentStartPos:=0;
  IdentEndPos:=0;

  // build code tree
  {$IFDEF CTDEBUG}
  DebugLn(['TIdentCompletionTool.ParseSourceTillCollectionStart A CursorPos=',dbgs(CursorPos)]);
  {$ENDIF}
  BuildTreeAndGetCleanPos(trTillCursor,lsrEnd,CursorPos,CleanCursorPos,
                          [btSetIgnoreErrorPos]);
  if FindDeepestNodeAtPos(CleanCursorPos,false)=nil then begin
    debugln(['TIdentCompletionTool.ParseSourceTillCollectionStart',
      ' BuildTreeAndGetCleanPos worked, but no node found.',
      ' CursorPos=',dbgs(CursorPos),' CleanCursorPos=',CleanCursorPos,
      ' ScannedRange=',dbgs(ScannedRange),
      ' Scanner.ScannedRange=',dbgs(Scanner.ScannedRange),
      ' IgnoreErrorAfterValid=',IgnoreErrorAfterValid
      ]);
    if IgnoreErrorAfterValid then
      debugln(['  IgnoreErrorAfter=',dbgs(IgnoreErrorAfter),' IgnoreErrorAfterCleanedPos=',IgnoreErrorAfterCleanedPos,' CleanPosIsAfterIgnorePos=',CleanPosIsAfterIgnorePos(CleanCursorPos)]);
    if CursorPos.Y<=CursorPos.Code.LineCount then
      debugln(['  Line=',dbgstr(CursorPos.Code.GetLine(CursorPos.Y-1),1,CursorPos.X-1),'|',dbgstr(CursorPos.Code.GetLine(CursorPos.Y-1),CursorPos.X,100)]);
    CursorNode:=Tree.Root;
    if CursorNode=nil then begin
      debugln(['  no nodes']);
    end else begin
      while CursorNode.NextBrother<>nil do
        CursorNode:=CursorNode.NextBrother;
      while CursorNode<>nil do begin
        debugln(['  Node=',CursorNode.DescAsString,',Start=',CursorNode.StartPos,',End=',CursorNode.EndPos,',Src="...',dbgstr(RightStr(ExtractNode(CursorNode,[]),100)),'"']);
        CursorNode:=CursorNode.LastChild;
      end;
    end;
  end;

  // find node at position
  ContextPos:=CleanCursorPos;
  // The context node might be in front of the CleanCursorPos
  // For example: A.|end; In this case the statement ends at the point.
  // Check the atom in front
  ReadPriorAtomSafe(CleanCursorPos);
  if (CurPos.Flag<>cafNone) then begin
    if (CurPos.Flag in [cafPoint,cafRoundBracketOpen,cafEdgedBracketOpen])
    or UpAtomIs('INHERITED') then
      ContextPos:=CurPos.StartPos;
  end;

  CursorNode:=BuildSubTreeAndFindDeepestNodeAtPos(ContextPos,true);
  if CurrentIdentifierList<>nil then begin
    StartContext:=CurrentIdentifierList.StartContext;
    StartContext.Node:=CursorNode;
    CurrentIdentifierList.StartContext:=StartContext;
  end;
  
  // get identifier position
  if CursorPos.Code.LineColIsOutside(CursorPos.Y,CursorPos.X) then begin
    IdentStartPos:=CleanCursorPos;
    IdentEndPos:=CleanCursorPos;
  end else begin
    GetIdentStartEndAtPosition(Src,CleanCursorPos,IdentStartPos,IdentEndPos);
  end;
  //DebugLn(['TIdentCompletionTool.ParseSourceTillCollectionStart ',dbgstr(copy(Src,IdentStartPos,10)),' CursorPos.X=',CursorPos.X,' LineLen=',CursorPos.Code.GetLineLength(CursorPos.Y-1),' ',CursorPos.Code.GetLine(CursorPos.Y-1)]);
  if CursorPos.X>CursorPos.Code.GetLineLength(CursorPos.Y-1)+1 then
    IdentStartPos:=IdentEndPos;
end;

function TIdentCompletionTool.FindIdentifierStartPos(
  const CursorPos: TCodeXYPosition): TCodeXYPosition;
var
  p: integer;
  IdentStartPos, IdentEndPos: integer;
begin
  CursorPos.Code.LineColToPosition(CursorPos.Y,CursorPos.X,p);
  if p<1 then
    RaiseException(ctsCursorPosOutsideOfCode);
  if CursorPos.X<=CursorPos.Code.GetLineLength(CursorPos.Y-1)+1 then begin
    GetIdentStartEndAtPosition(CursorPos.Code.Source,p,IdentStartPos,IdentEndPos);
  end else begin
    IdentStartPos:=p;
    IdentEndPos:=p;
  end;
  Result:=CursorPos;
  if IdentStartPos>0 then
    dec(Result.X,p-IdentStartPos);
  //DebugLn(['TIdentCompletionTool.FindIdentifierStartPos ',dbgstr(copy(CursorPos.Code.Source,IdentStartPos,20))]);
end;

procedure TIdentCompletionTool.FindCollectionContext(
  Params: TFindDeclarationParams; IdentStartPos: integer;
  CursorNode: TCodeTreeNode;
  out GatherContext: TFindContext;
  out ContextExprStartPos: LongInt;
  out StartInSubContext: Boolean);

  function GetContextExprStartPos(IdentStartPos: integer;
    ContextNode: TCodeTreeNode): integer;
  begin
    MoveCursorToCleanPos(IdentStartPos);
    ReadPriorAtom;
    if (CurPos.Flag=cafPoint)
    or UpAtomIs('INHERITED') then begin
      Result:=FindStartOfTerm(IdentStartPos,NodeTermInType(ContextNode));
      if Result<ContextNode.StartPos then
        Result:=ContextNode.StartPos;
    end else
      Result:=IdentStartPos;
    MoveCursorToCleanPos(Result);
    ReadNextAtom;
    case ContextNode.Desc of
    ctnProperty:
      // check for special property keywords
      if WordIsPropertySpecifier.DoItCaseInsensitive(Src,
          CurPos.StartPos,CurPos.EndPos-CurPos.StartPos)
      then
        // do not resolve property specifiers
        Result:=IdentStartPos;
    end;
  end;

var
  ExprType: TExpressionType;
  IgnoreCurContext: Boolean;
begin
  GatherContext:=CreateFindContext(Self,CursorNode);

  IgnoreCurContext:=false;
  //DebugLn(['TIdentCompletionTool.FindCollectionContext IdentStartPos=',dbgstr(copy(Src,IdentStartPos,20)),' ',CursorNode.DescAsString]);
  ContextExprStartPos:=GetContextExprStartPos(IdentStartPos,CursorNode);
  if GatherContext.Node.Desc=ctnWithVariable then begin
    if GatherContext.Node.PriorBrother<>nil then
      GatherContext.Node:=GatherContext.Node.PriorBrother
    else
      GatherContext.Node:=GatherContext.Node.Parent;
  end
  else if (GatherContext.Node.GetNodeOfType(ctnClassInheritance)<>nil) then
  begin
    while not (GatherContext.Node.Desc in AllClasses) do
      GatherContext.Node:=GatherContext.Node.Parent;
    GatherContext.Node:=GatherContext.Node.Parent;
    IgnoreCurContext:=true;
  end else if GatherContext.Node.Desc=ctnIdentifier then begin
    IgnoreCurContext:=true;
  end;

  StartInSubContext:=false;
  //DebugLn(['TIdentCompletionTool.FindCollectionContext ContextExprStartPos=',ContextExprStartPos,' "',dbgstr(copy(Src,ContextExprStartPos,20)),'" IdentStartPos="',dbgstr(copy(Src,IdentStartPos,20)),'" Gather=',FindContextToString(GatherContext)]);
  if ContextExprStartPos<IdentStartPos then begin
    MoveCursorToCleanPos(IdentStartPos);
    Params.ContextNode:=CursorNode;
    Params.SetIdentifier(Self,nil,nil);
    Params.Flags:=[fdfExceptionOnNotFound,
                   fdfSearchInParentNodes,fdfSearchInAncestors];
    if IgnoreCurContext then
      Params.Flags:=Params.Flags+[fdfIgnoreCurContextNode];
    ExprType:=FindExpressionTypeOfTerm(ContextExprStartPos,IdentStartPos,
                                       Params,false);
    if (ExprType.Desc=xtContext) then begin
      GatherContext:=ExprType.Context;
      debugln(['TIdentCompletionTool.FindCollectionContext ',ExprTypeToString(ExprType)]);
      StartInSubContext:=true;
    end;
  end;
end;

function TIdentCompletionTool.CollectAllContexts(
  Params: TFindDeclarationParams; const FoundContext: TFindContext
  ): TIdentifierFoundResult;
begin
  Result:=ifrProceedSearch;
  if FoundContext.Node=nil then exit;
  //DebugLn(['TIdentCompletionTool.CollectAllContexts ',FoundContext.Node.DescAsString]);
  case FoundContext.Node.Desc of
  ctnProcedure:
    begin
      //DebugLn('TIdentCompletionTool.CollectAllContexts CurrentContexts.ProcNameAtom.StartPos=',dbgs(CurrentIdentifierContexts.ProcNameAtom.StartPos));
      if (CurrentIdentifierContexts.ProcName='') then exit;
      FoundContext.Tool.MoveCursorToProcName(FoundContext.Node,true);
      //DebugLn(['TIdentCompletionTool.CollectAllContexts ProcName=',GetIdentifier(@FoundContext.Tool.Src[FoundContext.Tool.CurPos.StartPos])]);
      if FoundContext.Tool.CompareSrcIdentifiers(
        FoundContext.Tool.CurPos.StartPos,
        PChar(CurrentIdentifierContexts.ProcName))
      then begin
        // method without 'overload' hides inherited one
        if not FoundContext.Tool.ProcNodeHasSpecifier(FoundContext.Node, psOVERLOAD) then
          Exclude(Params.Flags, fdfSearchInAncestors);
      end else exit
    end;
  ctnProperty,ctnGlobalProperty:
    begin
      if (CurrentIdentifierContexts.ProcName='') then exit;
      FoundContext.Tool.MoveCursorToPropName(FoundContext.Node);
      if not FoundContext.Tool.CompareSrcIdentifiers(
        FoundContext.Tool.CurPos.StartPos,
        PChar(CurrentIdentifierContexts.ProcName))
      then exit;
    end;
  ctnVarDefinition:
    begin
      //debugln(['TIdentCompletionTool.CollectAllContexts ',FoundContext.Tool.ExtractNode(FoundContext.Node,[])]);
      if (CurrentIdentifierContexts.ProcName='') then exit;
      if not FoundContext.Tool.CompareSrcIdentifiers(
        FoundContext.Node.StartPos,
        PChar(CurrentIdentifierContexts.ProcName))
      then exit;
    end;
  else
    exit;
  end;
  {$IFDEF VerboseCodeContext}
  DebugLn(['TIdentCompletionTool.CollectAllContexts add ',FoundContext.Node.DescAsString]);
  {$ENDIF}
  AddCollectionContext(FoundContext.Tool,FoundContext.Node);
end;

procedure TIdentCompletionTool.AddCollectionContext(Tool: TFindDeclarationTool;
  Node: TCodeTreeNode);
begin
  if CurrentIdentifierContexts=nil then
    CurrentIdentifierContexts:=TCodeContextInfo.Create;
  CurrentIdentifierContexts.Add(CreateExpressionType(xtContext,xtNone,
                                           CreateFindContext(Tool,Node)));
  //DebugLn('TIdentCompletionTool.AddCollectionContext ',Node.DescAsString,' ',ExtractNode(Node,[]));
end;

function TIdentCompletionTool.IsInCompilerDirective(CursorPos: TCodeXYPosition
  ): boolean;
var
  Line: String;
  p: Integer;
  EndPos: Integer;
  InnerStart: Integer;
  Directive: String;
  ms: TCompilerModeSwitch;
  cm: TCompilerMode;
begin
  Result:=false;
  Line:=CursorPos.Code.GetLine(CursorPos.Y-1);
  p:=1;
  while p<=length(Line) do begin
    p:=FindNextCompilerDirective(Line,p,Scanner.NestedComments);
    if p>length(Line) then exit;
    EndPos:=FindCommentEnd(Line,p,Scanner.NestedComments);
    if (CursorPos.X>p) and (CursorPos.X<EndPos) then begin
      // in a directive
      Result:=true;
      InnerStart:=p;
      if Line[InnerStart]='{' then
        inc(InnerStart,2)
      else
        inc(InnerStart,3);
      //debugln(['TIdentCompletionTool.IsInCompilerDirective InnerStart=',InnerStart,' X=',CursorPos.X]);
      if (InnerStart=CursorPos.X)
      or ((CursorPos.X>=InnerStart) and (InnerStart<=length(Line))
          and (CursorPos.X<=InnerStart+GetIdentLen(@Line[InnerStart])))
      then begin
        AddKeyWord('Align');
        AddKeyWord('AlignAssertions');
        AddKeyWord('AsmMode');
        AddKeyWord('Assertions');
        AddKeyWord('BitPacking');
        AddKeyWord('BoolEval');
        AddKeyWord('Calling');
        AddKeyWord('CheckPointer');
        AddKeyWord('CodeAlign');
        AddKeyWord('COperators');
        AddKeyWord('DebugInfo');
        AddKeyWord('Define');
        AddKeyWord('ElIfC');
        AddKeyWord('Else');
        AddKeyWord('ElseC');
        AddKeyWord('ElseIf');
        AddKeyWord('EndC');
        AddKeyWord('EndIf');
        AddKeyWord('Error');
        AddKeyWord('ErrorC');
        AddKeyWord('ExtendedSyntax');
        AddKeyWord('Fatal');
        AddKeyWord('FPUType');
        AddKeyWord('Goto');
        AddKeyWord('Hint');
        AddKeyWord('Hints');
        AddKeyWord('IfC');
        AddKeyWord('IfDef');
        AddKeyWord('IfEnd');
        AddKeyWord('IfNDef');
        AddKeyWord('IfOpt');
        AddKeyWord('ImplicitExceptions');
        AddKeyWord('Include');
        AddKeyWord('IncludePath');
        AddKeyWord('Info');
        AddKeyWord('Inline');
        AddKeyWord('Interfaces');
        AddKeyWord('IOChecks');
        AddKeyWord('Link');
        AddKeyWord('LinkFramework');
        AddKeyWord('LinkLib');
        AddKeyWord('LocalSymbols');
        AddKeyWord('LongStrings');
        AddKeyWord('Macro');
        AddKeyWord('MaxFPURegisters');
        AddKeyWord('Message');
        AddKeyWord('MinEnumSize');
        AddKeyWord('MMX');
        AddKeyWord('Mode');
        AddKeyWord('ModeSwitch');
        AddKeyWord('NameSpace');
        AddKeyWord('Note');
        AddKeyWord('Notes');
        AddKeyWord('ObjectChecks');
        AddKeyWord('OpenStrings');
        AddKeyWord('Optimization');
        AddKeyWord('Output_Format');
        AddKeyWord('OV');
        AddKeyWord('OverflowChecks');
        AddKeyWord('PackEnum');
        AddKeyWord('PackEecords');
        AddKeyWord('PackSet');
        AddKeyWord('PIC');
        AddKeyWord('PointerMath');
        AddKeyWord('Pop');
        AddKeyWord('Push');
        AddKeyWord('RangeChecks');
        AddKeyWord('ReferenceInfo');
        AddKeyWord('SetC');
        AddKeyWord('StackFrames');
        AddKeyWord('Stop');
        AddKeyWord('Threading');
        AddKeyWord('TypeAddress');
        AddKeyWord('TypeInfo');
        AddKeyWord('UnDef');
        AddKeyWord('VarStringChecks');
        AddKeyWord('Wait');
        AddKeyWord('Warning');
        AddKeyWord('Warnings');
        AddKeyWord('WritableConst');
        AddKeyWord('ZeroBasedStrings');
      end else if InnerStart<=length(Line) then begin
        Directive:=lowercase(GetIdentifier(@Line[InnerStart]));
        if (Directive='ifdef')
        or (Directive='ifndef')
        or (Directive='if')
        or (Directive='elseif')
        or (Directive='ifc')
        then begin
          AddCompilerDirectiveMacros(Directive);
        end else if Directive='modeswitch' then begin
          for ms:=low(TCompilerModeSwitch) to high(TCompilerModeSwitch) do
            AddKeyWord(lowercase(CompilerModeSwitchNames[ms]));
        end else if Directive='mode' then begin
          for cm:=low(TCompilerMode) to high(TCompilerMode) do
            AddKeyWord(lowercase(CompilerModeNames[cm]));
        end else if Directive='warn' then begin
          AddKeyWord('constructing_abstract');
          AddKeyWord('implicit_variants');
          AddKeyWord('no_retval');
          AddKeyWord('symbol_deprecated');
          AddKeyWord('symbol_experimental');
          AddKeyWord('symbol_library');
          AddKeyWord('symbol_platform');
          AddKeyWord('symbol_unimplemented');
          AddKeyWord('unit_deprecated');
          AddKeyWord('unit_experimental');
          AddKeyWord('unit_library');
          AddKeyWord('unit_platform');
          AddKeyWord('unit_unimplemented');
          AddKeyWord('zero_nil_compat');
          AddKeyWord('implicit_string_cast');
          AddKeyWord('implicit_variants');
          AddKeyWord('no_retval');
          AddKeyWord('symbol_deprecated');
          AddKeyWord('symbol_experimental');
          AddKeyWord('symbol_library');
          AddKeyWord('symbol_platform');
          AddKeyWord('symbol_unimplemented');
          AddKeyWord('unit_deprecated');
          AddKeyWord('unit_experimental');
          AddKeyWord('unit_library');
          AddKeyWord('unit_platform');
          AddKeyWord('unit_unimplemented');
          AddKeyWord('zero_nil_compat');
          AddKeyWord('implicit_string_cast');
          AddKeyWord('implicit_string_cast_loss');
          AddKeyWord('explicit_string_cast');
          AddKeyWord('explicit_string_cast_loss');
          AddKeyWord('cvt_narrowing_string_lost');
        end else if (Directive='i') or (Directive='include') then begin
          AddKeyWord('Date');
          AddKeyWord('FPCTarget');
          AddKeyWord('FPCTargetOS');
          AddKeyWord('FPCTargetCPU');
          AddKeyWord('FPCVersion');
          AddKeyWord('Time');
        end;
      end;
      exit;
    end;
    p:=EndPos;
  end;
end;

procedure TIdentCompletionTool.AddCompilerDirectiveMacros(Directive: string);
var
  Macros: TStringToStringTree;
  StrItem: PStringToStringTreeItem;
  CodeBufs: TAVLTree;
  AVLNode: TAVLTreeNode;

  procedure Add(e: TExpressionEvaluator);
  var
    i: Integer;
  begin
    for i:=0 to e.Count-1 do
      Macros[e.Names(i)]:=e.Values(i);
  end;

  procedure AddExprWords(CodeBuf: TCodeBuffer);
  var
    CurSrc: String;
    p: Integer;
    sp: PChar;
    NamePos: PChar;
    EndP: PChar;
    CurName: String;
  begin
    p:=1;
    CurSrc:=CodeBuf.Source;
    while p<=length(CurSrc) do begin
      p:=FindNextCompilerDirective(CurSrc,p,Scanner.NestedComments);
      if p>length(CurSrc) then break;
      sp:=@CurSrc[p];
      p:=FindCommentEnd(CurSrc,p,Scanner.NestedComments);
      // skip comment start
      if sp^='{' then inc(sp,2)
      else if sp^='(' then inc(sp,3);
      if not IsIdentStartChar[sp^] then break;
      NamePos:=sp;
      inc(sp,GetIdentLen(NamePos));
      if sp^=#0 then break;
      if (CompareIdentifiers(NamePos,'ifdef')=0)
      or (CompareIdentifiers(NamePos,'ifndef')=0)
      or (CompareIdentifiers(NamePos,'if')=0)
      or (CompareIdentifiers(NamePos,'ifc')=0)
      or (CompareIdentifiers(NamePos,'elseif')=0)
      or (CompareIdentifiers(NamePos,'elifc')=0)
      or (CompareIdentifiers(NamePos,'define')=0)
      or (CompareIdentifiers(NamePos,'unde')=0)
      or (CompareIdentifiers(NamePos,'setc')=0)
      then begin
        // add all identifiers in directive
        if p>length(CurSrc) then
          EndP:=PChar(CurSrc)+length(CurSrc)
        else
          EndP:=@CurSrc[p];
        while (sp<EndP) do begin
          if IsIdentStartChar[sp^] then begin
            CurName:=GetIdentifier(sp);
            if (CompareIdentifiers(sp,'defined')<>0)
            and (CompareIdentifiers(sp,'undefined')<>0) then begin
              if not Macros.Contains(CurName) then begin
                Macros[CurName]:='';
              end;
            end;
            inc(sp,length(CurName));
          end else begin
            inc(sp);
          end;
        end;
      end;
    end;
  end;

begin
  CodeBufs:=nil;
  Macros:=TStringToStringTree.Create(false);
  try
    Add(Scanner.InitialValues);
    Add(Scanner.Values);
    if (Directive='if') or (Directive='elseif')
    or (Directive='ifc') or (Directive='elifc') then begin
      AddCompilerFunction('defined','','boolean');
      AddCompilerFunction('undefined','','boolean');
    end;

    // add all words of all directives in unit
    CodeBufs:=Scanner.CreateTreeOfSourceCodes;
    AVLNode:=CodeBufs.FindLowest;
    while AVLNode<>nil do begin
      AddExprWords(TCodeBuffer(AVLNode.Data));
      AVLNode:=CodeBufs.FindSuccessor(AVLNode);
    end;

    for StrItem in Macros do
      AddKeyWord(StrItem^.Name);
  finally
    CodeBufs.Free;
    Macros.Free;
  end;
end;

function TIdentCompletionTool.GatherAvailableUnitNames(const CursorPos: TCodeXYPosition;
  var IdentifierList: TIdentifierList): Boolean;
begin
  Result:=false;

  try
    InitCollectIdentifiers(CursorPos, IdentifierList);

    GatherUnitNames;
    Result:=true;

  finally
    CurrentIdentifierList:=nil;
  end;
end;

function TIdentCompletionTool.GatherIdentifiers(
  const CursorPos: TCodeXYPosition; var IdentifierList: TIdentifierList
  ): boolean;
var
  CleanCursorPos, IdentStartPos, IdentEndPos: integer;
  CursorNode: TCodeTreeNode;
  Params: TFindDeclarationParams;
  GatherContext: TFindContext;
  ContextExprStartPos: Integer;
  StartInSubContext: Boolean;
  StartPosOfVariable: LongInt;
  CursorContext: TFindContext;
  IdentStartXY: TCodeXYPosition;
  InFrontOfDirective: Boolean;
  
  procedure CheckProcedureDeclarationContext;
  var
    Node: TCodeTreeNode;
    Can: Boolean;
  begin
    //DebugLn(['CheckProcedureDeclarationContext ',CursorNode.DescAsString]);
    Node:=CursorNode;
    Can:=false;
    if (Node.Parent<>nil)
    and (Node.Parent.Desc in AllClassSections)
    and (Node.Desc=ctnVarDefinition)
    and (CurrentIdentifierList.StartAtomBehind.Flag<>cafColon) then begin
      { cursor is at a class variable definition without type
        for example:
        
        public
          MouseM|
        end;
      }
      Can:=true;
    end
    else if (((Node.Desc=ctnProcedure) and (not NodeIsMethodBody(Node)))
    or ((Node.Desc=ctnProcedureHead) and (not NodeIsMethodBody(Node.Parent))))
    and (not (CurrentIdentifierList.StartAtomBehind.Flag
              in [cafEdgedBracketOpen,cafRoundBracketOpen]))
    then begin
      // for example: procedure DoSomething|
      Can:=true;
    end
    else if Node.Desc in (AllClassBaseSections+AllSourceTypes
                     +[ctnInterface,ctnImplementation])
    then begin
      //DebugLn(['TIdentCompletionTool.CheckProcedureDeclarationContext ilcfCanProcDeclaration']);
      Can:=true;
    end;
    if Can then
      CurrentIdentifierList.ContextFlags:=
        CurrentIdentifierList.ContextFlags+[ilcfCanProcDeclaration];
  end;

begin
  Result:=false;

  ActivateGlobalWriteLock;
  Params:=TFindDeclarationParams.Create;
  try
    InitCollectIdentifiers(CursorPos,IdentifierList);
    IdentStartXY:=FindIdentifierStartPos(CursorPos);
    if IsInCompilerDirective(IdentStartXY) then exit(true);

    ParseSourceTillCollectionStart(IdentStartXY,CleanCursorPos,CursorNode,
                                   IdentStartPos,IdentEndPos);
    if CleanCursorPos=0 then ;
    if IdentStartPos>0 then begin
      MoveCursorToCleanPos(IdentStartPos);
      ReadNextAtom;
      CurrentIdentifierList.StartAtom:=CurPos;
    end;

    // find context
    {$IFDEF CTDEBUG}
    DebugLn('TIdentCompletionTool.GatherIdentifiers B',
      ' CleanCursorPos=',CleanPosToStr(CleanCursorPos),
      ' IdentStartPos=',CleanPosToStr(IdentStartPos),' IdentEndPos=',CleanPosToStr(IdentEndPos),
      ' Ident=',copy(Src,IdentStartPos,IdentEndPos-IdentStartPos));
    {$ENDIF}
    GatherContext:=CreateFindContext(Self,CursorNode);
    CurrentIdentifierList.NewMemberVisibility:=GetClassVisibility(CursorNode);
    if CursorNode.Desc in [ctnUsesSection,ctnUseUnit] then begin
      GatherUnitNames;
      MoveCursorToCleanPos(IdentEndPos);
      ReadNextAtom;
      if (CurPos.Flag=cafWord) and (not UpAtomIs('IN')) then begin
        // add comma
        CurrentIdentifierList.ContextFlags:=
          CurrentIdentifierList.ContextFlags+[ilcfNeedsEndComma];
      end;
    end else if (CursorNode.Desc in AllSourceTypes)
    and (PositionsInSameLine(Src,CursorNode.StartPos,IdentStartPos)) then begin
      GatherSourceNames(GatherContext);
    end else begin
      FindCollectionContext(Params,IdentStartPos,CursorNode,
                           GatherContext,ContextExprStartPos,StartInSubContext);

      // find class and ancestors if existing (needed for protected identifiers)
      if GatherContext.Tool = Self then
        FindContextClassAndAncestors(IdentStartXY, FICTClassAndAncestors);

      CursorContext:=CreateFindContext(Self,CursorNode);
      GatherContextKeywords(CursorContext,IdentStartPos,Beautifier);

      // search and gather identifiers in context
      if (GatherContext.Tool<>nil) and (GatherContext.Node<>nil) then begin
        {$IFDEF CTDEBUG}
        DebugLn('TIdentCompletionTool.GatherIdentifiers D CONTEXT: ',
          GatherContext.Tool.MainFilename,
          ' ',GatherContext.Node.DescAsString,
          ' "',StringToPascalConst(copy(GatherContext.Tool.Src,GatherContext.Node.StartPos,50)),'"');
        {$ENDIF}

        // gather all identifiers in context
        Params.ContextNode:=GatherContext.Node;
        Params.SetIdentifier(Self,nil,@CollectAllIdentifiers);
        Params.Flags:=[fdfSearchInAncestors,fdfCollect,fdfFindVariable];
        if (Params.ContextNode.Desc=ctnInterface) and StartInSubContext then
          Include(Params.Flags,fdfIgnoreUsedUnits);
        if not StartInSubContext then
          Include(Params.Flags,fdfSearchInParentNodes);
        if Params.ContextNode.Desc in AllClasses then
          Exclude(Params.Flags,fdfSearchInParentNodes);
        {$IFDEF CTDEBUG}
        DebugLn('TIdentCompletionTool.GatherIdentifiers F');
        {$ENDIF}
        CurrentIdentifierList.Context:=GatherContext;
        if GatherContext.Node.Desc=ctnIdentifier then
          Params.Flags:=Params.Flags+[fdfIgnoreCurContextNode];
        GatherContext.Tool.FindIdentifierInContext(Params);
      end;

      // check for incomplete context
      
      // context bracket level
      CurrentIdentifierList.StartBracketLvl:=
        GetBracketLvl(Src,CursorNode.StartPos,IdentStartPos,
                      Scanner.NestedComments);
      if CursorNode.Desc in AllPascalStatements then begin
        CurrentIdentifierList.ContextFlags:=
          CurrentIdentifierList.ContextFlags+[ilcfStartInStatement];
      end;

      // context in front of
      StartPosOfVariable:=FindStartOfTerm(IdentStartPos,NodeTermInType(CursorNode));
      if StartPosOfVariable>0 then begin
        if StartPosOfVariable=IdentStartPos then begin
          // cursor is at start of an operand
          CurrentIdentifierList.ContextFlags:=
            CurrentIdentifierList.ContextFlags+[ilcfStartOfOperand];
        end else begin
          MoveCursorToCleanPos(IdentStartPos);
          ReadPriorAtom;
          if CurPos.Flag=cafPoint then
            // cursor is behind a point
            CurrentIdentifierList.ContextFlags:=
              CurrentIdentifierList.ContextFlags+[ilcfStartIsSubIdent];
        end;
        MoveCursorToCleanPos(StartPosOfVariable);
        ReadPriorAtom;
        CurrentIdentifierList.StartAtomInFront:=CurPos;
        if (ilcfStartInStatement in CurrentIdentifierList.ContextFlags)
        then begin
          // check if LValue
          if (CurPos.Flag in [cafSemicolon,cafEnd,cafColon])
          or UpAtomIs('BEGIN')
          or UpAtomIs('TRY') or UpAtomIs('FINALLY') or UpAtomIs('EXCEPT')
          or UpAtomIs('FOR') or UpAtomIs('DO') or UpAtomIs('THEN')
          or UpAtomIs('REPEAT') or UpAtomIs('ASM') or UpAtomIs('ELSE')
          then begin
            CurrentIdentifierList.ContextFlags:=
              CurrentIdentifierList.ContextFlags+[ilcfStartOfStatement];
          end;
          // check if expression
          if UpAtomIs('IF') or UpAtomIs('CASE') or UpAtomIs('WHILE')
          or UpAtomIs('UNTIL')
          then begin
            // todo: check at start of expression, not only in front of variable
            CurrentIdentifierList.ContextFlags:=
              CurrentIdentifierList.ContextFlags+[ilcfIsExpression];
          end;
        end;
      end;
      // context behind
      if (IdentEndPos<SrcLen) then begin
        MoveCursorToCleanPos(IdentEndPos);
        //debugln(['TIdentCompletionTool.GatherIdentifiers "',dbgstr(Src,IdentStartPos,IdentEndPos-IdentStartPos),'"']);
        InFrontOfDirective:=(CurPos.StartPos<SrcLen) and (Src[CurPos.StartPos]='{')
                            and (Src[CurPos.StartPos+1]='$');
        ReadNextAtom;

        // check end of line
        if (not InFrontOfDirective)
        and (CursorPos.Code.LineColIsOutside(CursorPos.Y,CursorPos.X)
          or (not PositionsInSameLine(Src,IdentEndPos,CurPos.StartPos)))
        then
          CurrentIdentifierList.ContextFlags:=
            CurrentIdentifierList.ContextFlags+[ilcfEndOfLine];

        CurrentIdentifierList.StartAtomBehind:=CurPos;
        // check if a semicolon is needed or forbidden at the end
        if InFrontOfDirective
        or (CurrentIdentifierList.StartBracketLvl>0)
        or (CurPos.Flag in [cafSemicolon, cafEqual, cafColon, cafComma,
                   cafPoint, cafRoundBracketOpen, cafRoundBracketClose,
                   cafEdgedBracketOpen, cafEdgedBracketClose])
        or ((CurPos.Flag in [cafWord,cafNone])
            and (UpAtomIs('ELSE')
                 or UpAtomIs('THEN')
                 or UpAtomIs('DO')
                 or UpAtomIs('TO')
                 or UpAtomIs('OF')
                 or WordIsBinaryOperator.DoItCaseInsensitive(Src,
                          CurPos.StartPos,CurPos.EndPos-CurPos.StartPos)))
        then begin
          // do not add semicolon
          CurrentIdentifierList.ContextFlags:=
            CurrentIdentifierList.ContextFlags+[ilcfNoEndSemicolon];
        end;
        // check if in statement
        if (ilcfStartInStatement in CurrentIdentifierList.ContextFlags) then
        begin
          // check if a semicolon is needed at the end
          if (not (ilcfNoEndSemicolon in CurrentIdentifierList.ContextFlags))
          then begin
            // check if a semicolon is needed at the end
            if (CurPos.Flag in [cafEnd])
            or WordIsBlockKeyWord.DoItCaseInsensitive(Src,
                                  CurPos.StartPos,CurPos.EndPos-CurPos.StartPos)
            or ((CurPos.Flag=cafWord)
                and (not PositionsInSameLine(Src,IdentEndPos,CurPos.StartPos)))
            then begin
              // add semicolon
              CurrentIdentifierList.ContextFlags:=
                CurrentIdentifierList.ContextFlags+[ilcfNeedsEndSemicolon];
            end;
          end;
        end;
        // check missing 'do' after 'with'
        if CurrentIdentifierList.StartUpAtomInFrontIs('WITH')
        and (not CurrentIdentifierList.StartUpAtomBehindIs('DO'))
        and (CurrentIdentifierList.StartBracketLvl=0)
        and (not (CurrentIdentifierList.StartAtomBehind.Flag in
               [cafComma,cafPoint,cafRoundBracketOpen,cafEdgedBracketOpen]))
        and (not CurrentIdentifierList.StartUpAtomBehindIs('^'))
        then
          CurrentIdentifierList.ContextFlags:=
            CurrentIdentifierList.ContextFlags+[ilcfNeedsDo];
      end else begin
        // end of source
        CurrentIdentifierList.ContextFlags:=
          CurrentIdentifierList.ContextFlags+[ilcfEndOfLine];
      end;

      // check for procedure/method declaration context
      CheckProcedureDeclarationContext;

      // add useful identifiers
      {$IFDEF CTDEBUG}
      DebugLn('TIdentCompletionTool.GatherIdentifiers G');
      {$ENDIF}
      GatherUsefulIdentifiers(IdentStartPos,CursorContext);
    end;

    Result:=true;
  finally
    FreeListOfPFindContext(FICTClassAndAncestors);
    FreeAndNil(FIDCTFoundPublicProperties);
    Params.Free;
    ClearIgnoreErrorAfter;
    DeactivateGlobalWriteLock;
    CurrentIdentifierList:=nil;
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TIdentCompletionTool.GatherIdentifiers END');
  {$ENDIF}
end;

function TIdentCompletionTool.FindCodeContext(const CursorPos: TCodeXYPosition;
  out CodeContexts: TCodeContextInfo): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  Params: TFindDeclarationParams;

  procedure AddPredefinedProcs(CurrentContexts: TCodeContextInfo;
    ProcNameAtom: TAtomPosition);

    procedure AddCompilerProc(const AProcName: string;
      const Params: string; const ResultType: string = '');
    var
      i: LongInt;
      Item: TCodeContextInfoItem;
    begin
      if CompareIdentifiers(PChar(AProcName),@Src[ProcNameAtom.StartPos])<>0
      then exit;
      i:=CurrentContexts.AddCompilerProc;
      Item:=CurrentContexts[i];
      Item.ProcName:=AProcName;
      Item.ResultType:=ResultType;
      Item.Params:=TStringList.Create;
      Item.Params.Delimiter:=';';
      Item.Params.StrictDelimiter:=true;
      Item.Params.DelimitedText:=Params;
    end;

  begin
    MoveCursorToAtomPos(ProcNameAtom);
    ReadPriorAtom;
    if (CurPos.Flag in [cafEnd,cafSemicolon,cafColon,
      cafRoundBracketOpen,cafEdgedBracketOpen])
    or UpAtomIs('BEGIN')
    or UpAtomIs('TRY') or UpAtomIs('FINALLY') or UpAtomIs('EXCEPT')
    or UpAtomIs('REPEAT') or UpAtomIs('ASM') then begin
      // see fpc/compiler/psystem.pp
      AddCompilerProc('Assert','Condition:Boolean;const Message:String');
      AddCompilerProc('Assigned','P:Pointer','Boolean');
      AddCompilerProc('Addr','var X','Pointer');
      AddCompilerProc('BitSizeOf','Identifier','Integer');
      AddCompilerProc('Concat','S1:String;S2:String[...;Sn:String]', 'String');
      AddCompilerProc('Copy','const S:String;FromPosition,Count:Integer', 'String');
      AddCompilerProc('Dec','var X:Ordinal;N:Integer=1');
      AddCompilerProc('Dispose','var X:Pointer');
      AddCompilerProc('Exclude','var S:Set;X:Ordinal');
      AddCompilerProc('Exit','ResultValue:Ordinal=Result');
      AddCompilerProc('Finalize','var X');
      AddCompilerProc('get_frame','','Pointer');
      AddCompilerProc('High','Arg:TypeOrVariable','Ordinal');
      AddCompilerProc('Inc','var X:Ordinal;N:Integer=1');
      AddCompilerProc('Include','var S:Set;X:Ordinal');
      AddCompilerProc('Initialize','var X');
      AddCompilerProc('Length','S:String','Integer');
      AddCompilerProc('Length','A:Array','Integer');
      AddCompilerProc('Low','Arg:TypeOrVariable','Ordinal');
      AddCompilerProc('New','var X:Pointer');
      AddCompilerProc('Ofs','var X','LongInt');
      AddCompilerProc('Ord','X:Ordinal', 'Integer');
      AddCompilerProc('Pack','A:Array;N:Integer;var A:Array');
      AddCompilerProc('Pred','X:Ordinal', 'Ordinal');
      AddCompilerProc('Read','');
      AddCompilerProc('ReadLn','');
      AddCompilerProc('ReadStr','S:String;var Args:Arguments');
      AddCompilerProc('Seg','var X','LongInt');
      AddCompilerProc('SetLength','var S:String;NewLength:Integer');
      AddCompilerProc('SetLength','var A:Array;NewLength:Integer');
      AddCompilerProc('SizeOf','Identifier','Integer');
      AddCompilerProc('Slice','var A:Array;Count:Integer','Array');
      AddCompilerProc('Str','const X[:Width[:Decimals]];var S:String');
      AddCompilerProc('Succ','X:Ordinal', 'Ordinal');
      AddCompilerProc('TypeInfo','Identifier', 'Pointer');
      AddCompilerProc('TypeOf','Identifier', 'Pointer');
      AddCompilerProc('Val','S:String;var V;var Code:Integer');
      AddCompilerProc('Unaligned','var X','var');
      AddCompilerProc('Unpack','A:Array;var A:Array;N:Integer');
      AddCompilerProc('Write','Args:Arguments');
      AddCompilerProc('WriteLn','Args:Arguments');
      AddCompilerProc('WriteStr','var S:String;Args:Arguments');
    end;
  end;

  function CheckContextIsParameter(var Ok: boolean): boolean;
  // returns true, on error or context is parameter
  var
    VarNameAtom, ProcNameAtom: TAtomPosition;
    ParameterIndex: integer;
    GatherContext: TFindContext;
    ContextExprStartPos: LongInt;
    StartInSubContext: Boolean;
  begin
    Result:=false;
    // check if in a begin..end block
    if CursorNode.GetNodeOfTypes([ctnBeginBlock,ctnInitialization,ctnFinalization])=nil
    then begin
      DebugLn(['TIdentCompletionTool.FindCodeContext.CheckContextIsParameter not in a begin block']);
      exit;
    end;
    // check if cursor is in a parameter list
    if not CheckParameterSyntax(CursorNode.StartPos, CleanCursorPos,
                                VarNameAtom, ProcNameAtom, ParameterIndex)
    then begin
      if VarNameAtom.StartPos=0 then ;
      DebugLn(['TIdentCompletionTool.FindCodeContext.CheckContextIsParameter not in a parameter list']);
      exit;
    end;
    //DebugLn('CheckContextIsParameter Variable=',GetAtom(VarNameAtom),' Proc=',GetAtom(ProcNameAtom),' ParameterIndex=',dbgs(ParameterIndex));
    
    // it is a parameter -> create context
    Result:=true;
    if CurrentIdentifierContexts=nil then
      CurrentIdentifierContexts:=TCodeContextInfo.Create;
    CurrentIdentifierContexts.Tool:=Self;
    CurrentIdentifierContexts.ParameterIndex:=ParameterIndex+1;
    CurrentIdentifierContexts.ProcNameAtom:=ProcNameAtom;
    CurrentIdentifierContexts.ProcName:=GetAtom(ProcNameAtom);

    AddPredefinedProcs(CurrentIdentifierContexts,ProcNameAtom);

    MoveCursorToAtomPos(ProcNameAtom);
    ReadNextAtom; // read opening bracket
    CurrentIdentifierContexts.StartPos:=CurPos.EndPos;
    // read closing bracket
    if ReadTilBracketClose(false) then
      CurrentIdentifierContexts.EndPos:=CurPos.StartPos
    else
      CurrentIdentifierContexts.EndPos:=SrcLen+1;

    FindCollectionContext(Params,ProcNameAtom.StartPos,CursorNode,
                          GatherContext,ContextExprStartPos,StartInSubContext);

    if ContextExprStartPos=0 then ;
    {$IFDEF VerboseCodeContext}
    DebugLn(['CheckContextIsParameter StartInSubContext=',StartInSubContext,' ',GatherContext.Node.DescAsString,' "',copy(GatherContext.Tool.Src,GatherContext.Node.StartPos-20,25),'"']);
    {$ENDIF}

    // gather declarations of all parameter lists
    Params.ContextNode:=GatherContext.Node;
    Params.SetIdentifier(Self,@Src[ProcNameAtom.StartPos],@CollectAllContexts);
    Params.Flags:=[fdfSearchInAncestors,fdfCollect,fdfFindVariable];
    if not StartInSubContext then
      Include(Params.Flags,fdfSearchInParentNodes);
    CurrentIdentifierList.Context:=GatherContext;
    {$IFDEF VerboseCodeContext}
    DebugLn('CheckContextIsParameter searching procedures, properties and variables ...');
    {$ENDIF}
    GatherContext.Tool.FindIdentifierInContext(Params);
    {$IFDEF VerboseCodeContext}
    DebugLn('CheckContextIsParameter END');
    {$ENDIF}
    Ok:=true;
  end;

var
  IdentifierList: TIdentifierList;
  IdentStartPos, IdentEndPos: integer;
begin
  CodeContexts:=nil;
  Result:=false;

  IdentifierList:=nil;
  CurrentIdentifierContexts:=CodeContexts;

  ActivateGlobalWriteLock;
  Params:=TFindDeclarationParams.Create;
  try
    InitCollectIdentifiers(CursorPos,IdentifierList);
    ParseSourceTillCollectionStart(CursorPos,CleanCursorPos,CursorNode,
                                   IdentStartPos,IdentEndPos);
    if IdentStartPos=0 then ;
    if IdentEndPos=0 then ;

    // find class and ancestors if existing (needed for protected identifiers)
    FindContextClassAndAncestors(CursorPos,FICTClassAndAncestors);

    if CursorNode<>nil then begin
      if not CheckContextIsParameter(Result) then begin
        DebugLn(['TIdentCompletionTool.FindCodeContext cursor not at parameter']);
        exit;
      end;
    end;

    if CurrentIdentifierContexts=nil then begin
      // create default
      AddCollectionContext(Self,CursorNode);
    end;

    Result:=true;
  finally
    if Result then begin
      CodeContexts:=CurrentIdentifierContexts;
      CurrentIdentifierContexts:=nil;
    end else begin
      FreeAndNil(CurrentIdentifierContexts);
    end;
    FreeListOfPFindContext(FICTClassAndAncestors);
    FreeAndNil(FIDCTFoundPublicProperties);
    Params.Free;
    ClearIgnoreErrorAfter;
    DeactivateGlobalWriteLock;
    FreeAndNil(CurrentIdentifierList);
  end;
end;

function TIdentCompletionTool.FindAbstractMethods(
  const CursorPos: TCodeXYPosition; out ListOfPCodeXYPosition: TFPList;
  SkipAbstractsInStartClass: boolean): boolean;
const
  ProcAttr = [phpWithoutClassKeyword,phpWithHasDefaultValues];
  FlagIsAbstract = 0;
  FlagIsImplemented = 1;
var
  ImplementedInterfaces: TStringToPointerTree;
  SearchedAncestors: TAVLTree;
  Procs: TAVLTree; // tree of TCodeTreeNodeExtension

  procedure AddProc(ATool: TFindDeclarationTool; ProcNode: TCodeTreeNode;
    IsAbstract: boolean);
  var
    ProcText: String;
    AVLNode: TAVLTreeNode;
    NodeExt: TCodeTreeNodeExtension;
  begin
    ProcText:=ATool.ExtractProcHead(ProcNode,ProcAttr);
    AVLNode:=FindCodeTreeNodeExtAVLNode(Procs,ProcText);
    if AVLNode<>nil then begin
      // known proc
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      //debugln(['AddProc "',ProcText,'" WasImplemented=',NodeExt.Flags=1,' IsAbstract=',IsAbstract]);
      if NodeExt.Flags=FlagIsImplemented then
        exit; // already implemented
      if IsAbstract then
        exit; // already abstract
      NodeExt.Flags:=FlagIsImplemented;
      NodeExt.Node:=ProcNode;
      NodeExt.Data:=ATool;
    end else begin
      // new method
      //debugln(['AddProc "',ProcText,'" New IsAbstract=',IsAbstract]);
      NodeExt:=TCodeTreeNodeExtension.Create;
      NodeExt.Node:=ProcNode;
      NodeExt.Data:=ATool;
      NodeExt.Txt:=ProcText;
      if IsAbstract then
        NodeExt.Flags:=FlagIsAbstract
      else
        NodeExt.Flags:=FlagIsImplemented;
      Procs.Add(NodeExt);
    end;
  end;

  procedure CollectImplements(ClassNode: TCodeTreeNode);
  var
    Node: TCodeTreeNode;
    StopNode: TCodeTreeNode;
    InterfaceName: String;
  begin
    Node:=ClassNode.FirstChild;
    StopNode:=ClassNode.NextSkipChilds;
    while Node<>StopNode do begin
      if Node.Desc in AllClassBaseSections then begin
        Node:=Node.Next;
        continue;
      end else if Node.Desc=ctnProperty then begin
        if PropertyHasSpecifier(Node,'IMPLEMENTS',false) then begin
          ReadNextAtom;
          while AtomIsIdentifier do begin
            InterfaceName:=GetAtom;
            ReadNextAtom;
            if CurPos.Flag=cafPoint then begin
              ReadNextAtom;
              AtomIsIdentifierE(true);
              InterfaceName+='.'+GetAtom;
              ReadNextAtom;
            end;
            //debugln(['CollectImplements ',InterfaceName]);
            ImplementedInterfaces[InterfaceName]:=Node;
            if CurPos.Flag<>cafComma then break;
            ReadNextAtom;
          end;
        end;
      end else if Node.Desc=ctnProcedure then begin
        if ProcNodeHasSpecifier(Node,psABSTRACT) then begin
          if not SkipAbstractsInStartClass then
            AddProc(Self,Node,true);
        end else begin
          AddProc(Self,Node,false);
        end;
      end;
      Node:=Node.NextSkipChilds;
    end;
  end;

  procedure CollectAncestors(aTool: TFindDeclarationTool;
    ClassNode: TCodeTreeNode; IsStartClass: boolean); forward;

  procedure CollectAncestor(ATool: TFindDeclarationTool;
    InheritanceNode: TCodeTreeNode; SearchedAncestors: TAVLTree;
    IsStartClass: boolean);
  var
    Params: TFindDeclarationParams;
    ClassNode: TCodeTreeNode;
    StopNode: TCodeTreeNode;
    Node: TCodeTreeNode;
    IsInterface: Boolean;
  begin
    //debugln(['CollectAncestor Ancestor=',ATool.ExtractIdentifierWithPoints(InheritanceNode.StartPos,false)]);
    Params:=TFindDeclarationParams.Create;
    try
      if not ATool.FindAncestorOfClassInheritance(InheritanceNode,Params,true)
      then exit;
      ATool:=Params.NewCodeTool;
      ClassNode:=Params.NewNode;
      if SearchedAncestors.Find(ClassNode)<>nil then
        exit; // already searched
      SearchedAncestors.Add(ClassNode);
      // check all procs of this ancestor
      StopNode:=ClassNode.NextSkipChilds;
      Node:=ClassNode.FirstChild;
      IsInterface:=ClassNode.Desc in AllClassInterfaces;
      if IsInterface and (not IsStartClass) then
        exit;
      while Node<>StopNode do begin
        if Node.Desc in AllClassBaseSections then begin
          Node:=Node.Next;
          continue;
        end else if Node.Desc=ctnProcedure then begin
          if IsInterface
          or ATool.ProcNodeHasSpecifier(Node,psABSTRACT) then
            AddProc(ATool,Node,true)
          else
            AddProc(ATool,Node,false);
        end;
        Node:=Node.NextSkipChilds;
      end;
      CollectAncestors(ATool,ClassNode,false);
    finally
      Params.Free;
    end;
  end;

  procedure CollectAncestors(aTool: TFindDeclarationTool;
    ClassNode: TCodeTreeNode; IsStartClass: boolean);
  var
    InheritanceNode: TCodeTreeNode;
    AncestorName: String;
    Node: TCodeTreeNode;
  begin
    //debugln(['CollectAncestors of Class=',aTool.ExtractClassName(ClassNode,false)]);
    InheritanceNode:=ATool.FindInheritanceNode(ClassNode);
    if (InheritanceNode=nil)
    or (InheritanceNode.FirstChild=nil) then begin
      // no ancestors
      exit;
    end;
    Node:=InheritanceNode.FirstChild;
    while Node<>nil do begin
      InheritanceNode:=Node;
      Node:=Node.NextBrother;
      if InheritanceNode.Desc=ctnIdentifier then begin
        if IsStartClass then begin
          AncestorName:=ATool.ExtractIdentifierWithPoints(InheritanceNode.StartPos,true);
          if ImplementedInterfaces.FindNode(AncestorName)<>nil then
            continue;
        end;
        CollectAncestor(ATool,InheritanceNode,SearchedAncestors,IsStartClass);
      end;
    end;
  end;

var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  ClassNode: TCodeTreeNode;
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  ProcXYPos: TCodeXYPosition;
  ATool: TFindDeclarationTool;
begin
  Result:=false;
  ListOfPCodeXYPosition:=nil;
  ImplementedInterfaces:=nil;
  Procs:=nil;
  SearchedAncestors:=nil;
  try
    BuildTreeAndGetCleanPos(trTillCursor,lsrEnd,CursorPos,CleanCursorPos,
                            [btSetIgnoreErrorPos]);

    // find node at position
    CursorNode:=BuildSubTreeAndFindDeepestNodeAtPos(CleanCursorPos,true);

    // if cursor is on type node, find class node
    if CursorNode.Desc=ctnTypeDefinition then
      CursorNode:=CursorNode.FirstChild
    else if CursorNode.Desc=ctnGenericType then
      CursorNode:=CursorNode.LastChild
    else
      CursorNode:=FindClassOrInterfaceNode(CursorNode);

    if (CursorNode=nil)
    or (not (CursorNode.Desc in AllClassObjects))
    or ((CursorNode.SubDesc and ctnsForwardDeclaration)>0) then begin
      MoveCursorToCleanPos(CleanCursorPos);
      RaiseException('TIdentCompletionTool.FindAbstractMethods cursor is not in a class');
    end;
    ClassNode:=CursorNode;

    // search class for implemented interfaces and method
    ImplementedInterfaces:=TStringToPointerTree.Create(false);
    Procs:=TAVLTree.Create(@CompareCodeTreeNodeExt);
    CollectImplements(ClassNode);

    // search all ancestors
    SearchedAncestors:=TAVLTree.Create;
    SearchedAncestors.Add(ClassNode);
    CollectAncestors(Self,ClassNode,true);

    // AddCodePosition for each abstract method
    AVLNode:=Procs.FindLowest;
    while AVLNode<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      if NodeExt.Flags=FlagIsAbstract then begin
        ATool:=TFindDeclarationTool(NodeExt.Data);
        if not ATool.CleanPosToCaret(NodeExt.Node.StartPos,ProcXYPos) then
          raise Exception.Create('TIdentCompletionTool.FindAbstractMethods inconsistency');
        AddCodePosition(ListOfPCodeXYPosition,ProcXYPos);
      end;
      AVLNode:=Procs.FindSuccessor(AVLNode);
    end;

    Result:=true;
  finally
    DisposeAVLTree(Procs);
    ImplementedInterfaces.Free;
    SearchedAncestors.Free;
  end;
end;

function TIdentCompletionTool.GetValuesOfCaseVariable(
  const CursorPos: TCodeXYPosition; List: TStrings): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  CaseAtom: TAtomPosition;
  Params: TFindDeclarationParams;
  EndPos: LongInt;
  ExprType: TExpressionType;
  Node: TCodeTreeNode;
  Tool: TFindDeclarationTool;
begin
  Result:=false;
  ActivateGlobalWriteLock;
  Params:=nil;
  try
    BuildTreeAndGetCleanPos(trTillCursor,lsrEnd,CursorPos,CleanCursorPos,
                           [btSetIgnoreErrorPos]);

    // find node at position
    CursorNode:=BuildSubTreeAndFindDeepestNodeAtPos(CleanCursorPos,true);

    // find keyword case
    MoveCursorToNodeStart(CursorNode);
    CaseAtom:=CleanAtomPosition;
    repeat
      ReadNextAtom;
      if UpAtomIs('CASE') then
        CaseAtom:=CurPos
    until (CurPos.EndPos>SrcLen) or (CurPos.EndPos>CleanCursorPos);
    if CaseAtom.StartPos<1 then exit;

    // find case variable
    EndPos:=FindEndOfExpression(CaseAtom.EndPos);
    if EndPos>CleanCursorPos then
      EndPos:=CleanCursorPos;
    //DebugLn(['TIdentCompletionTool.GetValuesOfCaseVariable Expr=',dbgstr(copy(Src,CaseAtom.EndPos,EndPos-CaseAtom.EndPos))]);

    Params:=TFindDeclarationParams.Create;
    Params.ContextNode:=CursorNode;
    Params.Flags:=fdfDefaultForExpressions+[fdfFunctionResult];
    ExprType:=FindExpressionTypeOfTerm(CaseAtom.EndPos,EndPos,Params,true);
    //DebugLn(['TIdentCompletionTool.GetValuesOfCaseVariable Type=',ExprTypeToString(ExprType)]);

    if ExprType.Desc=xtContext then begin
      // resolve aliases and properties
      Params.Clear;
      Params.Flags:=fdfDefaultForExpressions;
      ExprType.Context:=ExprType.Context.Tool.FindBaseTypeOfNode(Params,
                                 ExprType.Context.Node);
    end;

    case ExprType.Desc of

    xtBoolean,xtByteBool,xtWordBool,xtLongBool,xtQWordBool:
      begin
        List.Add('True');
        List.Add('False');
      end;

    xtContext:
      begin
        Node:=ExprType.Context.Node;
        Tool:=ExprType.Context.Tool;
        if Node=nil then exit;
        case Node.Desc of

        ctnEnumerationType:
          begin
            Node:=Node.FirstChild;
            while Node<>nil do begin
              List.Add(GetIdentifier(@Tool.Src[Node.StartPos]));
              Node:=Node.NextBrother;
            end;
          end;

        else
          debugln(['TIdentCompletionTool.GetValuesOfCaseVariable not an enum: ',Node.DescAsString]);
          exit;
        end;
      end;
    else
      exit;
    end;

    Result:=true;
  finally
    Params.Free;
    DeactivateGlobalWriteLock;
  end;
end;

procedure TIdentCompletionTool.CalcMemSize(Stats: TCTMemStats);
var
  Node: TAVLTreeNode;
  Ext: TCodeTreeNodeExtension;
  m: PtrUint;
begin
  inherited CalcMemSize(Stats);
  if FICTClassAndAncestors<>nil then
    Stats.Add('TIdentCompletionTool.ClassAndAncestors',
        FICTClassAndAncestors.Count*(SizeOf(TAVLTreeNode)+SizeOf(TCodeXYPosition)));
  if FIDCTFoundPublicProperties<>nil then
    Stats.Add('TIdentCompletionTool.FoundPublicProperties',
              FIDCTFoundPublicProperties.Count*SizeOf(TAVLTreeNode));
  if FIDTFoundMethods<>nil then begin
    m:=PtrUint(FIDTFoundMethods.Count)*SizeOf(TAVLTreeNode);
    Node:=FIDTFoundMethods.FindLowest;
    while Node<>nil do begin
      Ext:=TCodeTreeNodeExtension(Node.Data);
      inc(m,Ext.CalcMemSize);
      Node:=FIDTFoundMethods.FindSuccessor(Node);
    end;
    STats.Add('TIdentCompletionTool.FoundMethods',m);
  end;
  if CurrentIdentifierList<>nil then
    Stats.Add('TIdentCompletionTool.CurrentIdentifierList',
      CurrentIdentifierList.CalcMemSize);
  if CurrentIdentifierContexts<>nil then
    Stats.Add('TIdentCompletionTool.CurrentContexts',
              CurrentIdentifierContexts.CalcMemSize);
end;

{ TIdentifierListItem }

function TIdentifierListItem.GetParamTypeList: string;
var
  ANode: TCodeTreeNode;
begin
  if not (iliParamTypeListValid in Flags) then begin
    // Note: if you implement param lists for other than ctnProcedure, check
    //       CompareParamList
    ANode:=Node;
    FParamTypeList:='';
    if (ANode<>nil) and (ANode.Desc=ctnProcedure) then begin
      try
        FParamTypeList:=Tool.ExtractProcHead(ANode,
           [phpWithoutClassKeyword,phpWithoutClassName,
            phpWithoutName,phpInUpperCase]);
        //debugln('TIdentifierListItem.GetParamTypeList A ',GetIdentifier(Identifier),' ',Tool.MainFilename,' ',dbgs(CurNode.StartPos));
      except
        on E: ECodeToolError do ; // ignore syntax errors
      end;
    end;
    Include(Flags,iliParamTypeListValid);
  end;
  Result:=FParamTypeList;
end;

function TIdentifierListItem.GetParamNameList: string;
var
  ANode: TCodeTreeNode;
begin
  if not (iliParamNameListValid in Flags) then begin
    // Note: if you implement param lists for other than ctnProcedure, check
    //       CompareParamList
    ANode:=Node;
    FParamNameList:='';
    if (ANode<>nil) and (ANode.Desc=ctnProcedure) then begin
      try
        FParamNameList:=Tool.ExtractProcHead(ANode,
           [phpWithoutClassKeyword,phpWithoutClassName,
            phpWithoutName,phpInUpperCase,phpWithParameterNames]);
        //debugln('TIdentifierListItem.GetParamNameList A ',GetIdentifier(Identifier),' ',Tool.MainFilename,' ',dbgs(CurNode.StartPos));
      except
        on E: ECodeToolError do ; // ignore syntax errors
      end;
    end;
    Include(Flags,iliParamNameListValid);
  end;
  Result:=FParamNameList;
end;

function TIdentifierListItem.GetNode: TCodeTreeNode;
begin
  Result:=nil;
  if Tool=nil then
    exit;

  if (iliNodeValid in Flags)
  and (FToolNodesDeletedStep<>Tool.NodesDeletedChangeStep) then
    Exclude(Flags,iliNodeValid);

  if (not (iliNodeValid in Flags)) then begin
    if iliNodeHashValid in Flags then begin
      RestoreNode;
      if (iliNodeValid in Flags) then begin
        Result:=FNode;
      end;
    end;
  end else begin
    if FToolNodesDeletedStep=Tool.NodesDeletedChangeStep then begin
      Result:=FNode;
    end else begin
      if not (iliNodeGoneWarned in Flags) then begin
        DebugLn(['TIdentifierListItem.GetNode node ',Identifier,' is gone from ',Tool.MainFilename]);
        Include(Flags,iliNodeGoneWarned);
      end;
      FNode:=nil;
    end;
  end;
end;

procedure TIdentifierListItem.SetNode(const AValue: TCodeTreeNode);

  procedure RaiseToolMissing;
  begin
    raise Exception.Create('TIdentifierListItem.SetNode Node without Tool');
  end;

begin
  FNode:=AValue;
  Include(Flags,iliNodeValid);
  Exclude(Flags,iliNodeHashValid);
  if (FNode<>nil) and (Tool=nil) then
    RaiseToolMissing;
  if (Tool<>nil) then
    FToolNodesDeletedStep:=Tool.NodesDeletedChangeStep;
end;

procedure TIdentifierListItem.SetParamTypeList(const AValue: string);
begin
  FParamTypeList:=AValue;
  Include(Flags,iliParamTypeListValid);
end;

procedure TIdentifierListItem.SetParamNameList(const AValue: string);
begin
  FParamNameList:=AValue;
  Include(Flags,iliParamNameListValid);
end;

procedure TIdentifierListItem.SetResultType(const AValue: string);
begin
  FResultType := AValue;
  Include(Flags, iliResultTypeValid);
end;

function TIdentifierListItem.AsString: string;
var
  ANode: TCodeTreeNode;
begin
  WriteStr(Result, Compatibility);
  if HasChilds then
    Result:=Result+' HasChilds'
  else
    Result:=Result+' HasNoChilds';
  Result:=Result+' History='+IntToStr(HistoryIndex);
  Result:=Result+' Ident='+Identifier;
  Result:=Result+' Lvl='+IntToStr(Level);
  if Tool<>nil then
    Result:=Result+' File='+Tool.MainFilename;
  ANode:=Node;
  if ANode<>nil then
    Result:=Result+' Node='+ANode.DescAsString
      +' "'+StringToPascalConst(copy(Tool.Src,ANode.StartPos,50))+'"';
end;

function TIdentifierListItem.GetDesc: TCodeTreeNodeDesc;
var
  ANode: TCodeTreeNode;
begin
  ANode:=Node;
  if ANode<>nil then
    Result:=ANode.Desc
  else
    Result:=DefaultDesc;
end;

constructor TIdentifierListItem.Create(
  NewCompatibility: TIdentifierCompatibility; NewHasChilds: boolean;
  NewHistoryIndex: integer; NewIdentifier: PChar; NewLevel: integer;
  NewNode: TCodeTreeNode; NewTool: TFindDeclarationTool;
  NewDefaultDesc: TCodeTreeNodeDesc);
begin
  Compatibility:=NewCompatibility;
  if NewHasChilds then Include(FLags,iliHasChilds);
  HistoryIndex:=NewHistoryIndex;
  Identifier:=GetIdentifier(NewIdentifier);
  Level:=NewLevel;
  Tool:=NewTool;
  Node:=NewNode;
  DefaultDesc:=NewDefaultDesc;
  BaseExprType:=CleanExpressionType;
end;

function TIdentifierListItem.IsProcNodeWithParams: boolean;
var
  ANode: TCodeTreeNode;
  StartPos: Integer;
begin
  Result:=(GetDesc=ctnProcedure);
  if not Result then exit;
  if (iliParamNameListValid in Flags) then begin
    StartPos:=1;
    while (StartPos<=length(FParamTypeList))
    and (FParamTypeList[StartPos] in [' ',#9,'(','[']) do
      inc(StartPos);
    if (StartPos<=length(FParamTypeList))
    and (FParamTypeList[StartPos] in [')',']',';']) then
      exit(false)
    else
      exit(true);
  end else if (iliParamTypeListValid in Flags) then begin
    // the type list does not contain names
    // so a () could be empty or (var buf)
    StartPos:=1;
    while (StartPos<=length(FParamTypeList))
    and (FParamTypeList[StartPos] in [' ',#9,'(','[']) do
      inc(StartPos);
    if (StartPos<=length(FParamTypeList))
    and (not (FParamTypeList[StartPos] in [')',']',';'])) then
      exit(true);
  end;
  ANode:=Node;
  Result:=(ANode<>nil) and Tool.ProcNodeHasParamList(ANode);
end;

function TIdentifierListItem.IsPropertyWithParams: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliHasParamListValid in Flags) then begin
    Include(Flags,iliHasParamListValid);
    ANode:=Node;
    if (ANode<>nil) and Tool.PropertyNodeHasParamList(ANode) then
      Include(Flags,iliHasParamList)
    else
      Exclude(Flags,iliHasParamList);
  end;
  Result:=iliHasParamList in Flags;
end;

function TIdentifierListItem.IsPropertyReadOnly: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliIsReadOnlyValid in Flags) then begin
    Include(Flags,iliIsReadOnlyValid);
    ANode:=Node;
    if (ANode<>nil) and Tool.PropertyHasSpecifier(ANode,'read',false)
    and not Tool.PropertyHasSpecifier(ANode,'write',false) then
      Include(Flags,iliIsReadOnly)
    else
      Exclude(Flags,iliIsReadOnly);
  end;
  Result:=iliIsReadOnly in Flags;
end;

function TIdentifierListItem.GetHintModifiers: TPascalHintModifiers;
var
  ANode: TCodeTreeNode;
begin
  Result:=[];
  if not (iliHintModifiersValid in Flags) then begin
    Include(Flags,iliHintModifiersValid);
    ANode:=Node;
    if ANode<>nil then begin
      Result:=Tool.GetHintModifiers(ANode);
      if phmDeprecated in Result then Include(Flags,iliIsDeprecated);
      if phmPlatform in Result then Include(Flags,iliIsPlatform);
      if phmLibrary in Result then Include(Flags,iliIsLibrary);
      if phmUnimplemented in Result then Include(Flags,iliIsUnimplemented);
      if phmExperimental in Result then Include(Flags,iliIsExperimental);
    end;
  end else begin
    if iliIsDeprecated in Flags then Include(Result,phmDeprecated);
    if iliIsPlatform in Flags then Include(Result,phmPlatform);
    if iliIsLibrary in Flags then Include(Result,phmLibrary);
    if iliIsUnimplemented in Flags then Include(Result,phmUnimplemented);
    if iliIsExperimental in Flags then Include(Result,phmExperimental);
  end;
end;

function TIdentifierListItem.CheckHasChilds: boolean;
// returns true if test was successful
var
  ANode: TCodeTreeNode;
begin
  Result:=false;
  if GetDesc in AllClasses then begin
    Result:=true;
    exit;
  end;
  ANode:=Node;
  if ANode=nil then exit;
  UpdateBaseContext;
  if (BaseExprType.Desc=xtContext)
    and (BaseExprType.Context.Node<>nil)
    and (BaseExprType.Context.Node.Desc in AllClasses)
  then
    Include(Flags,iliHasChilds);
  Result:=true;
end;

function TIdentifierListItem.CanBeAssigned: boolean;
var
  ANode: TCodeTreeNode;
begin
  Result:=false;
  ANode:=Node;
  if (ANode=nil) then exit;
  if (GetDesc=ctnVarDefinition) then
    Result:=true;
  if (ANode.Desc in [ctnProperty,ctnGlobalProperty]) then begin
    if Tool.PropertyHasSpecifier(ANode,'write') then exit(true);
    if Tool.PropNodeIsTypeLess(ANode) then begin
      exit(true);// ToDo: search the real property definition
    end;
  end;
end;

procedure TIdentifierListItem.UpdateBaseContext;
var
  Params: TFindDeclarationParams;
  ANode: TCodeTreeNode;
begin
  if (iliBaseExprTypeValid in Flags) then exit;
  Include(Flags,iliBaseExprTypeValid);
  BaseExprType:=CleanExpressionType;
  BaseExprType.Desc:=xtNone;
  ANode:=Node;
  if (ANode<>nil) and (Tool<>nil) then begin
    Tool.ActivateGlobalWriteLock;
    Params:=TFindDeclarationParams.Create;
    try
      if ANode.HasParentOfType(ctnGenericType) then exit;
      BaseExprType.Context:=Tool.FindBaseTypeOfNode(Params,ANode);
      if (BaseExprType.Context.Node<>nil) then
        BaseExprType.Desc:=xtContext;
    finally
      Params.Free;
      Tool.DeactivateGlobalWriteLock;
    end;
  end;
end;

function TIdentifierListItem.HasChilds: boolean;
begin
  Result:=iliHasChilds in Flags;
end;

function TIdentifierListItem.HasIndex: boolean;
// check if edged bracket can be used []
var
  ANode: TCodeTreeNode;
begin
  if not (iliHasIndexValid in Flags) then begin
    UpdateBaseContext;
    if BaseExprType.Desc in (xtAllStringConvertibles+xtAllWideStringConvertibles)
    then begin
      // strings, widestrings and PChar
      Include(Flags,iliHasIndex);
    end else if (BaseExprType.Desc=xtContext) and (BaseExprType.Context.Node<>nil)
    then begin
      //debugln(['TIdentifierListItem.HasIndex ',BaseExprType.Context.Node.DescAsString]);
      ANode:=BaseExprType.Context.Node;
      case ANode.Desc of
      ctnRangedArrayType,ctnOpenArrayType: Include(Flags,iliHasIndex);
      end;
    end;
  end;
  Result:=iliHasIndex in Flags;
end;

function TIdentifierListItem.IsFunction: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliIsFunctionValid in Flags) then
  begin
    ANode := Node;
    if (ANode <> nil) and Tool.NodeIsFunction(ANode) then
      Include(Flags, iliIsFunction);
    Include(Flags, iliIsFunctionValid);
  end;
  Result := iliIsFunction in Flags;
end;

function TIdentifierListItem.IsContructor: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliIsConstructorValid in Flags) then
  begin
    ANode := Node;
    if (ANode <> nil) and Tool.NodeIsConstructor(ANode) then
      Include(Flags, iliIsConstructor);
    Include(Flags, iliIsConstructorValid);
  end;
  Result := iliIsConstructor in Flags;
end;

function TIdentifierListItem.IsDestructor: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliIsDestructorValid in Flags) then
  begin
    ANode := Node;
    if (ANode <> nil) and Tool.NodeIsDestructor(ANode) then
      Include(Flags, iliIsDestructor);
    Include(Flags, iliIsDestructorValid);
  end;
  Result := iliIsDestructor in Flags;
end;

function TIdentifierListItem.IsAbstractMethod: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliIsAbstractMethodValid in Flags) then begin
    ANode:=Node;
    if (ANode<>nil)
    and Tool.ProcNodeHasSpecifier(ANode,psABSTRACT) then
      Include(Flags,iliIsAbstractMethod);
    Include(Flags,iliIsAbstractMethodValid);
  end;
  Result:=iliIsAbstractMethod in Flags;
end;

function TIdentifierListItem.TryIsAbstractMethod: boolean;
begin
  try
    Result:=IsAbstractMethod;
  except
    Result:=false;
  end;
end;

procedure TIdentifierListItem.Clear;
begin
  FParamTypeList:='';
  FResultType:='';
  Compatibility:=icompUnknown;
  HistoryIndex:=0;
  Identifier:='';
  Level:=0;
  FNode:=nil;
  Tool:=nil;
  DefaultDesc:=ctnNone;
  Flags:=[];
  BaseExprType:=CleanExpressionType;
end;

procedure TIdentifierListItem.UnbindNode;
begin
  if FNode=nil then exit;
  StoreNodeHash;
  Exclude(Flags,iliNodeValid);
  FNode:=nil;
end;

procedure TIdentifierListItem.StoreNodeHash;
begin
  Include(Flags,iliNodeHashValid);
  FNodeStartPos:=FNode.StartPos;
  FNodeDesc:=FNode.Desc;
  FNodeHash:=GetNodeHash(FNode);
  //DebugLn(['TIdentifierListItem.StoreNodeHash ',Identifier,' Pos=',FNodeStartPos,' Hash=',FNodeHash]);
end;

function TIdentifierListItem.RestoreNode: boolean;
var
  NewNode: TCodeTreeNode;
  NewHash: String;
begin
  if not (iliNodeHashValid in Flags) then exit(true);
  //DebugLn(['TIdentifierListItem.RestoreNode ',Identifier]);
  NewNode:=Tool.BuildSubTreeAndFindDeepestNodeAtPos(FNodeStartPos,false);
  Result:=false;
  if (NewNode=nil) or (NewNode.StartPos<>FNodeStartPos)
  or (NewNode.Desc<>FNodeDesc) then begin
    DebugLn(['TIdentifierListItem.RestoreNode not found: ',Identifier]);
    Exclude(Flags,iliNodeHashValid);
    exit;
  end;
  NewHash:=GetNodeHash(NewNode);
  if NewHash<>FNodeHash then begin
    DebugLn(['TIdentifierListItem.RestoreNode hash changed: ',Identifier]);
    Exclude(Flags,iliNodeHashValid);
    exit;
  end;
  //DebugLn(['TIdentifierListItem.RestoreNode Success ',Identifier]);
  Node:=NewNode;
  Result:=true;
end;

function TIdentifierListItem.GetNodeHash(ANode: TCodeTreeNode): string;
var
  StartPos: LongInt;
  EndPos: LongInt;
begin
  case ANode.Desc of
  ctnVarDefinition,ctnConstDefinition,ctnTypeDefinition,ctnGenericType:
    Result:=Tool.ExtractDefinitionName(ANode)
  else
    StartPos:=ANode.StartPos;
    EndPos:=StartPos+20;
    if EndPos>ANode.EndPos then EndPos:=ANode.EndPos;
    Result:=copy(Tool.Src,StartPos,EndPos);
  end;
end;

function TIdentifierListItem.CompareParamList(CompareItem: TIdentifierListItem
  ): integer;
var
  ANode: TCodeTreeNode;
  CmpNode: TCodeTreeNode;
begin
  Result:=0;
  if Self=CompareItem then exit;
  ANode:=Node;
  CmpNode:=CompareItem.Node;
  if (ANode=CmpNode) then exit;
  if (ANode=nil) or (CmpNode=nil) then exit;
  if (ANode.Desc<>ctnProcedure) or (CmpNode.Desc<>ctnProcedure) then
    exit;
  {DbgOut('TIdentifierListItem.CompareParamList ',GetIdentifier(Identifier),'=',GetIdentifier(CompareItem.Identifier));
  if Node<>nil then
    DbgOut(' Self=',Tool.MainFilename,' ',dbgs(Node.StartPos));
  if CompareItem.Node<>nil then
    DbgOut(' Other=',CompareItem.Tool.MainFilename,' ',dbgs(CompareItem.Node.StartPos));
  debugln('');}
  Result:=CompareTextIgnoringSpace(ParamTypeList,CompareItem.ParamTypeList,false);
end;

function TIdentifierListItem.CompareParamList(
  CompareItem: TIdentifierListSearchItem): integer;
begin
  if (ParamTypeList='') and (CompareItem.ParamList='') then
    exit(0);
  Result:=CompareTextIgnoringSpace(ParamTypeList,CompareItem.ParamList,false);
end;

function TIdentifierListItem.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(FParamTypeList)
    +MemSizeString(FNodeHash)
    +MemSizeString(Identifier);
end;

{ TIdentifierHistoryList }

procedure TIdentifierHistoryList.SetCapacity(const AValue: integer);
begin
  if FCapacity=AValue then exit;
  FCapacity:=AValue;
  if FCapacity<1 then FCapacity:=1;
  while (FItems.Count>0) and (FItems.Count>=FCapacity) do
    FItems.FreeAndDelete(FItems.FindHighest);
end;

function TIdentifierHistoryList.FindItem(NewItem: TIdentifierListItem
  ): TAVLTreeNode;
begin
  if NewItem<>nil then
    Result:=FItems.FindKey(NewItem,@CompareIdentItemWithHistListItem)
  else
    Result:=nil;
end;

constructor TIdentifierHistoryList.Create;
begin
  FItems:=TAVLTree.Create(@CompareIdentHistListItem);
  FCapacity:=30;
end;

destructor TIdentifierHistoryList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TIdentifierHistoryList.Clear;
begin
  FItems.FreeAndClear;
end;

procedure TIdentifierHistoryList.Add(NewItem: TIdentifierListItem);
var
  OldAVLNode: TAVLTreeNode;
  NewHistItem: TIdentHistListItem;
  AnAVLNode: TAVLTreeNode;
  AdjustIndex: Integer;
  AnHistItem: TIdentHistListItem;
begin
  if NewItem=nil then exit;
  OldAVLNode:=FindItem(NewItem);
  {$IFDEF ShowHistory}
  DebugLn('TIdentifierHistoryList.Add Count=',Count,' Found=',OldAVLNode<>nil,
    ' ITEM: ',NewItem.AsString);
  {$ENDIF}
  if OldAVLNode<>nil then begin
    // already in tree
    NewHistItem:=TIdentHistListItem(OldAVLNode.Data);
    if NewHistItem.HistoryIndex=0 then exit;
    // must be moved -> remove it from the tree
    AdjustIndex:=NewHistItem.HistoryIndex;
    FItems.Delete(OldAVLNode);
  end else begin
    // create a new history item
    NewHistItem:=TIdentHistListItem.Create;
    NewHistItem.Identifier:=NewItem.Identifier;
    NewHistItem.NodeDesc:=NewItem.GetDesc;
    NewHistItem.ParamList:=NewItem.ParamTypeList;
    AdjustIndex:=0;
  end;
  NewHistItem.HistoryIndex:=0;
  // adjust all other HistoryIndex
  AnAVLNode:=Fitems.FindLowest;
  while AnAVLNode<>nil do begin
    AnHistItem:=TIdentHistListItem(AnAVLNode.Data);
    if AnHistItem.HistoryIndex>=AdjustIndex then
      inc(AnHistItem.HistoryIndex);
    AnAVLNode:=FItems.FindSuccessor(AnAVLNode);
  end;
  if (FItems.Count>0) and (FItems.Count>=FCapacity) then
    FItems.FreeAndDelete(FItems.FindHighest);
  FItems.Add(NewHistItem);
  {$IFDEF ShowHistory}
  DebugLn('TIdentifierHistoryList.Added Count=',Count);
  {$ENDIF}
end;

function TIdentifierHistoryList.GetHistoryIndex(AnItem: TIdentifierListItem
  ): integer;
var
  AnAVLNode: TAVLTreeNode;
begin
  AnAVLNode:=FindItem(AnItem);
  if AnAVLNode=nil then
    Result:=33333333  // a very high value
  else
    Result:=TIdentHistListItem(AnAVLNode.Data).HistoryIndex;
end;

function TIdentifierHistoryList.Count: integer;
begin
  Result:=FItems.Count;
end;

function TIdentifierHistoryList.CalcMemSize: PtrUInt;
var
  Node: TAVLTreeNode;
  Item: TIdentHistListItem;
begin
  Result:=PtrUInt(InstanceSize);
  if FItems<>nil then begin
    inc(Result,FItems.Count*SizeOf(TAVLTreeNode));
    Node:=FItems.FindLowest;
    while Node<>nil do begin
      Item:=TIdentHistListItem(Node.Data);
      inc(Result,Item.CalcMemSize);
      Node:=FItems.FindSuccessor(Node);
    end;
  end;
end;

{ TCodeContextInfo }

function TCodeContextInfo.GetItems(Index: integer): TCodeContextInfoItem;
begin
  Result:=TCodeContextInfoItem(FItems[Index]);
end;

constructor TCodeContextInfo.Create;
begin
  FItems:=TFPList.Create;
end;

destructor TCodeContextInfo.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited Destroy;
end;

function TCodeContextInfo.Count: integer;
begin
  Result:=FItems.Count;
end;

function TCodeContextInfo.Add(const Context: TExpressionType): integer;
var
  Item: TCodeContextInfoItem;
begin
  Item:=TCodeContextInfoItem.Create;
  Item.Expr:=Context;
  Result:=FItems.Add(Item);
end;

function TCodeContextInfo.AddCompilerProc: integer;
var
  Item: TCodeContextInfoItem;
begin
  Item:=TCodeContextInfoItem.Create;
  Result:=FItems.Add(Item);
end;

procedure TCodeContextInfo.Clear;
var
  i: Integer;
begin
  for i:=0 to FItems.Count-1 do
    TObject(FItems[i]).Free;
  FItems.Clear;
end;

function TCodeContextInfo.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +PtrUInt(TCodeContextInfoItem)*SizeOf(FItems.Count)
    +MemSizeString(FProcName);
end;

{ TIdentifierListSearchItem }

function TIdentifierListSearchItem.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(ParamList);
end;

{ TIdentHistListItem }

function TIdentHistListItem.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(Identifier)
    +MemSizeString(ParamList);
end;

{ TCodeContextInfoItem }

destructor TCodeContextInfoItem.Destroy;
begin
  FreeAndNil(Params);
  inherited Destroy;
end;

end.

