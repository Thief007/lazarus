unit ConvCodeTool;

{$mode objfpc}{$H+}

interface

uses
  // LCL+FCL
  Classes, SysUtils, FileProcs, Forms, Controls, DialogProcs, Dialogs,
  contnrs, strutils,
  // IDE
  LazarusIDEStrConsts, LazIDEIntf, FormEditor, IDEMsgIntf,
  // codetools
  CodeToolManager, StdCodeTools, CodeTree, CodeAtom, AVL_Tree,
  FindDeclarationTool, PascalReaderTool, PascalParserTool, LFMTrees,
  CodeBeautifier, ExprEval, KeywordFuncLists, BasicCodeTools, LinkScanner,
  CodeCache, SourceChanger, CustomCodeTool, CodeToolsStructs, EventCodeTool,
  // Converter
  ConverterTypes, ConvertSettings, ReplaceNamesUnit, ReplaceFuncsUnit;

type

  // For future, when .dfm form file can be used for both Delphi and Lazarus.
{  TFormFileAction = (faUseDfm, faRenameToLfm, faUseBothDfmAndLfm); }

  { TConvDelphiCodeTool }

  TConvDelphiCodeTool = class
  private
    fCodeTool: TCodeTool;
    fCode: TCodeBuffer;
    fSrcCache: TSourceChangeCache;
    fAsk: Boolean;
    fHasFormFile: boolean;
    fLowerCaseRes: boolean;
    fDfmDirectiveStart: integer;
    fDfmDirectiveEnd: integer;
    fTarget: TConvertTarget;
    // List of units to remove.
    fUnitsToRemove: TStringList;
    // Units to rename. Map of unit name -> real unit name.
    fUnitsToRename: TStringToStringTree;
    // List of units to be commented.
    fUnitsToComment: TStringList;
    // Delphi Function names to replace with FCL/LCL functions.
    fDefinedProcNames: TStringList;
    fReplaceFuncs: TFuncsAndCategories;
    fFuncsToReplace: TObjectList;           // List of TFuncReplacement.
    function AddDelphiAndLCLSections: boolean;
    function AddModeDelphiDirective: boolean;
    function RenameResourceDirectives: boolean;
    function CommentOutUnits: boolean;
    function ReplaceFuncsInSource: boolean;
    function RememberProcDefinition(aNode: TCodeTreeNode): TCodeTreeNode;
    function ReplaceFuncCalls(aIsConsoleApp: boolean): boolean;
    function HandleCodetoolError: TModalResult;
  public
    constructor Create(Code: TCodeBuffer);
    destructor Destroy; override;
    function Convert(aIsConsoleApp: boolean): TModalResult;
    function FindApptypeConsole: boolean;
    function RemoveUnits: boolean;
    function RenameUnits: boolean;
    function UsesSectionsToUnitnames: TStringList;
    function FixMainClassAncestor(const AClassName: string;
                                  AReplaceTypes: TStringToStringTree): boolean;
    function CheckTopOffsets(LFMBuf: TCodeBuffer; LFMTree: TLFMTree;
               ParentOffsets: TStringToStringTree; ValueNodes: TObjectList): boolean;
  public
    property Ask: Boolean read fAsk write fAsk;
    property HasFormFile: boolean read fHasFormFile write fHasFormFile;
    property LowerCaseRes: boolean read fLowerCaseRes write fLowerCaseRes;
    property Target: TConvertTarget read fTarget write fTarget;
    property UnitsToRemove: TStringList read fUnitsToRemove write fUnitsToRemove;
    property UnitsToRename: TStringToStringTree read fUnitsToRename write fUnitsToRename;
    property UnitsToComment: TStringList read fUnitsToComment write fUnitsToComment;
    property ReplaceFuncs: TFuncsAndCategories read fReplaceFuncs write fReplaceFuncs;
  end;


implementation

{ TConvDelphiCodeTool }

constructor TConvDelphiCodeTool.Create(Code: TCodeBuffer);
begin
  fCode:=Code;
  // Default values for vars.
  fAsk:=true;
  fLowerCaseRes:=false;
  fTarget:=ctLazarus;
  fUnitsToRemove:=nil;            // These are set from outside.
  fUnitsToComment:=nil;
  fUnitsToRename:=nil;
  // Initialize codetools. (Copied from TCodeToolManager.)
  if not CodeToolBoss.InitCurCodeTool(fCode) then exit;
  try
    fCodeTool:=CodeToolBoss.CurCodeTool;
    fSrcCache:=CodeToolBoss.SourceChangeCache;
    fSrcCache.MainScanner:=fCodeTool.Scanner;
  except
    on e: Exception do
      CodeToolBoss.HandleException(e);
  end;
end;

destructor TConvDelphiCodeTool.Destroy;
begin
  inherited Destroy;
end;

function TConvDelphiCodeTool.HandleCodetoolError: TModalResult;
// returns mrOk or mrAbort
const
  CodetoolsFoundError='The codetools found an error in unit %s:%s%s%s';
var
  ErrMsg: String;
begin
  ErrMsg:=CodeToolBoss.ErrorMessage;
  LazarusIDE.DoJumpToCodeToolBossError;
  if fAsk then begin
    Result:=QuestionDlg(lisCCOErrorCaption,
      Format(CodetoolsFoundError, [ExtractFileName(fCode.Filename), #13, ErrMsg, #13]),
      mtWarning, [mrIgnore, lisIgnoreAndContinue, mrAbort], 0);
    if Result=mrIgnore then Result:=mrOK;
  end else begin
    Result:=mrOK;
  end;
end;

function TConvDelphiCodeTool.Convert(aIsConsoleApp: boolean): TModalResult;
// add {$mode delphi} directive
// remove {$R *.dfm} or {$R *.xfm} directive
// Change {$R *.RES} to {$R *.res} if needed
// TODO: fix delphi ambiguouties like incomplete proc implementation headers
begin
  Result:=mrCancel;
  try
    fSrcCache.BeginUpdate;
    try
      // these changes can be applied together without rescan
      if not AddModeDelphiDirective then exit;
      if not RenameResourceDirectives then exit;
      if not ReplaceFuncCalls(aIsConsoleApp) then exit;
      if not fSrcCache.Apply then exit;
    finally
      fSrcCache.EndUpdate;
    end;
    if fTarget=ctLazarus then begin
      // One way conversion -> remove, rename and comment out units.
      if not RemoveUnits then exit;
      if not RenameUnits then exit;
    end;
    if fTarget=ctLazarusAndDelphi then begin
      // Support Delphi. Add IFDEF blocks for units.
      if not AddDelphiAndLCLSections then exit;
    end
    else  // ctLazarus or ctLazarusWin -> comment units if needed.
      if not CommentOutUnits then exit;
    if not fCodeTool.FixUsedUnitCase(fSrcCache) then exit;
    if not fSrcCache.Apply then exit;
    Result:=mrOK;
  except
    on e: Exception do begin
      CodeToolBoss.HandleException(e);
      Result:=HandleCodetoolError;
    end;
  end;
end;

function TConvDelphiCodeTool.FindApptypeConsole: boolean;
// Return true if there is {$APPTYPE CONSOLE} directive.
var
  ParamPos, ACleanPos: Integer;
begin
  Result:=false;
  ACleanPos:=0;
  with fCodeTool do begin
    BuildTree(true);
    ACleanPos:=FindNextCompilerDirectiveWithName(Src, 1, 'Apptype',
                                                 Scanner.NestedComments, ParamPos);
    if (ACleanPos>0) and (ACleanPos<=SrcLen) and (ParamPos>0) then
      Result:=LowerCase(copy(Src,ParamPos,7))='console';
  end;
end;

function TConvDelphiCodeTool.AddDelphiAndLCLSections: boolean;
// add, remove and rename units for desired target.

  procedure RemoveUsesUnit(AUnitName: string);
  var
    UsesNode: TCodeTreeNode;
  begin
    fCodeTool.BuildTree(true);
    UsesNode:=fCodeTool.FindMainUsesSection;
    fCodeTool.MoveCursorToUsesStart(UsesNode);
    fCodeTool.RemoveUnitFromUsesSection(UsesNode, UpperCaseStr(AUnitName), fSrcCache);
  end;

var
  DelphiOnlyUnits: TStringList;  // Delphi specific units.
  LclOnlyUnits: TStringList;     // LCL specific units.
  RenameList: TStringList;
  UsesNode: TCodeTreeNode;
  s, nl: string;
  InsPos, i: Integer;
begin
  Result:=false;
  DelphiOnlyUnits:=TStringList.Create;
  LclOnlyUnits:=TStringList.Create;
  try
  fCodeTool.BuildTree(true);
  fSrcCache.MainScanner:=fCodeTool.Scanner;
  UsesNode:=fCodeTool.FindMainUsesSection;
  if UsesNode<>nil then begin
    fCodeTool.MoveCursorToUsesStart(UsesNode);
    InsPos:=fCodeTool.CurPos.StartPos;
    // Now don't remove or comment but add to Delphi block instead.
    for i:=0 to fUnitsToRemove.Count-1 do begin
      s:=fUnitsToRemove[i];
      RemoveUsesUnit(s);
      DelphiOnlyUnits.Append(s);
    end;
    for i:=0 to fUnitsToComment.Count-1 do begin
      s:=fUnitsToComment[i];
      RemoveUsesUnit(s);
      DelphiOnlyUnits.Append(s);
    end;
    RenameList:=TStringList.Create;
    try
      // Add replacement units to LCL block.
      fUnitsToRename.GetNames(RenameList);
      for i:=0 to RenameList.Count-1 do begin
        s:=RenameList[i];
        RemoveUsesUnit(s);
        DelphiOnlyUnits.Append(s);
        LclOnlyUnits.Append(fUnitsToRename[s]);
      end;
    finally
      RenameList.Free;
    end;
    if (LclOnlyUnits.Count>0) or (DelphiOnlyUnits.Count>0) then begin
      // Add LCL and Delphi sections for output.
      nl:=fSrcCache.BeautifyCodeOptions.LineEnd;
      s:='{$IFNDEF FPC}'+nl+'  ';
      for i:=0 to DelphiOnlyUnits.Count-1 do
        s:=s+DelphiOnlyUnits[i]+', ';
      s:=s+nl+'{$ELSE}'+nl+'  ';
      for i:=0 to LclOnlyUnits.Count-1 do
        s:=s+LclOnlyUnits[i]+', ';
      s:=s+nl+'{$ENDIF}';
      // Now add the generated lines.
      if not fSrcCache.Replace(gtEmptyLine,gtNewLine,InsPos,InsPos,s) then exit;
    end;
  end;
  Result:=true;
  finally
    LclOnlyUnits.Free;
    DelphiOnlyUnits.Free;
  end;
end;

function TConvDelphiCodeTool.AddModeDelphiDirective: boolean;
var
  ModeDirectivePos: integer;
  InsertPos: Integer;
  s, nl: String;
begin
  Result:=false;
  with fCodeTool do begin
    BuildTree(true);
    if not FindModeDirective(false,ModeDirectivePos) then begin
      // add {$MODE Delphi} behind source type
      if Tree.Root=nil then exit;
      MoveCursorToNodeStart(Tree.Root);
      ReadNextAtom; // 'unit', 'program', ..
      ReadNextAtom; // name
      ReadNextAtom; // semicolon
      InsertPos:=CurPos.EndPos;
      nl:=fSrcCache.BeautifyCodeOptions.LineEnd;
      if fTarget=ctLazarusAndDelphi then
        s:='{$IFDEF FPC}'+nl+'  {$MODE Delphi}'+nl+'{$ENDIF}'
      else
        s:='{$MODE Delphi}';
      fSrcCache.Replace(gtEmptyLine,gtEmptyLine,InsertPos,InsertPos,s);
    end;
    // changing mode requires rescan
    BuildTree(false);
  end;
  Result:=true;
end;

function TConvDelphiCodeTool.RenameResourceDirectives: boolean;
// rename {$R *.dfm} directive to {$R *.lfm}, or lowercase it.
// lowercase {$R *.RES} to {$R *.res}
var
  ParamPos: Integer;
  ACleanPos: Integer;
  Key, LowKey, NewKey: String;
  s, nl: string;
  AlreadyIsLfm: Boolean;
begin
  Result:=false;
  AlreadyIsLfm:=false;
  fDfmDirectiveStart:=-1;
  fDfmDirectiveEnd:=-1;
  ACleanPos:=1;
  // find $R directive
  with fCodeTool do
    repeat
      ACleanPos:=FindNextCompilerDirectiveWithName(Src, ACleanPos, 'R',
                                                   Scanner.NestedComments, ParamPos);
      if (ACleanPos<1) or (ACleanPos>SrcLen) or (ParamPos>SrcLen-6) then break;
      NewKey:='';
      if (Src[ACleanPos]='{') and
         (Src[ParamPos]='*') and (Src[ParamPos+1]='.') and
         (Src[ParamPos+5]='}')
      then begin
        Key:=copy(Src,ParamPos+2,3);
        LowKey:=LowerCase(Key);

        // Form file resource rename or lowercase:
        if (LowKey='dfm') or (LowKey='xfm') then begin
          // Lowercase existing key. (Future, when the same dfm file can be used)
//          faUseDfm: if Key<>LowKey then NewKey:=LowKey;
          if fTarget=ctLazarusAndDelphi then begin
            // Later IFDEF will be added so that Delphi can still use .dfm.
            fDfmDirectiveStart:=ACleanPos;
            fDfmDirectiveEnd:=ParamPos+6;
          end
          else       // Change .dfm to .lfm.
            NewKey:='lfm';
        end

        // If there already is .lfm, prevent adding IFDEF for .dfm / .lfm.
        else if LowKey='lfm' then begin
          AlreadyIsLfm:=true;
        end

        // lowercase {$R *.RES} to {$R *.res}
        else if (Key='RES') and fLowerCaseRes then
          NewKey:=LowKey;

        // Now change code.
        if NewKey<>'' then
          if not fSrcCache.Replace(gtNone,gtNone,ParamPos+2,ParamPos+5,NewKey) then exit;
      end;
      ACleanPos:=FindCommentEnd(Src, ACleanPos, Scanner.NestedComments);
    until false;
  // if there is already .lfm file, don't add IFDEF for .dfm / .lfm.
  if (fTarget=ctLazarusAndDelphi) and (fDfmDirectiveStart<>-1) and not AlreadyIsLfm then
  begin
    // Add IFDEF for .lfm and .dfm allowing Delphi to use .dfm.
    nl:=fSrcCache.BeautifyCodeOptions.LineEnd;
    s:='{$IFNDEF FPC}'+nl+
       '  {$R *.dfm}'+nl+
       '{$ELSE}'+nl+
       '  {$R *.lfm}'+nl+
       '{$ENDIF}';
    Result:=fSrcCache.Replace(gtNone,gtNone,fDfmDirectiveStart,fDfmDirectiveEnd,s);
  end;
  Result:=true;
end;

function TConvDelphiCodeTool.RemoveUnits: boolean;
// Remove units
var
  i: Integer;
begin
  Result:=false;
  if Assigned(fUnitsToRemove) then begin
    for i:=0 to fUnitsToRemove.Count-1 do begin
      fSrcCache:=CodeToolBoss.SourceChangeCache;
      fSrcCache.MainScanner:=fCodeTool.Scanner;
      if not fCodeTool.RemoveUnitFromAllUsesSections(UpperCaseStr(fUnitsToRemove[i]),
                                                     fSrcCache) then
        exit;
      if not fSrcCache.Apply then exit;
    end;
  end;
  fUnitsToRemove.Clear;
  Result:=true;
end;

function TConvDelphiCodeTool.RenameUnits: boolean;
// Rename units
begin
  Result:=false;
  if Assigned(fUnitsToRename) then
    if not fCodeTool.ReplaceUsedUnits(fUnitsToRename, fSrcCache) then
      exit;
  fUnitsToRename.Clear;
  Result:=true;
end;

function TConvDelphiCodeTool.CommentOutUnits: boolean;
// Comment out missing units
begin
  Result:=false;
  if Assigned(fUnitsToComment) and (fUnitsToComment.Count>0) then
    if not fCodeTool.CommentUnitsInUsesSections(fUnitsToComment, fSrcCache) then
      exit;
  Result:=true;
end;

function TConvDelphiCodeTool.UsesSectionsToUnitnames: TStringList;
// Collect all unit names from uses sections to a StringList.
var
  UsesNode: TCodeTreeNode;
  ImplList: TStrings;
begin
  fCodeTool.BuildTree(true);
  fSrcCache.MainScanner:=fCodeTool.Scanner;
  UsesNode:=fCodeTool.FindMainUsesSection;
  Result:=TStringList(fCodeTool.UsesSectionToUnitnames(UsesNode));
  UsesNode:=fCodeTool.FindImplementationUsesSection;
  ImplList:=fCodeTool.UsesSectionToUnitnames(UsesNode);
  Result.AddStrings(ImplList);
  ImplList.Free;
end;


function TConvDelphiCodeTool.FixMainClassAncestor(const AClassName: string;
                                    AReplaceTypes: TStringToStringTree): boolean;
// Replace the ancestor type of main form with a fall-back type if needed.
var
  ANode, InheritanceNode: TCodeTreeNode;
  TypeUpdater: TStringMapUpdater;
  OldType, NewType: String;
begin
  Result:=false;
  with fCodeTool do begin
    BuildTree(true);
    // Find the class name that the main class inherits from.
    ANode:=FindClassNodeInInterface(AClassName,true,false,false);
    if ANode=nil then exit;
    BuildSubTreeForClass(ANode);
    InheritanceNode:=FindInheritanceNode(ANode);
    if InheritanceNode=nil then exit;
    ANode:=InheritanceNode.FirstChild;
    if ANode=nil then exit;
    if ANode.Desc=ctnIdentifier then begin
      MoveCursorToNodeStart(ANode);  // cursor to the identifier
      ReadNextAtom;
      OldType:=GetAtom;
    end;
    TypeUpdater:=TStringMapUpdater.Create(AReplaceTypes);
    try
      // Find replacement for ancestor type maybe using regexp syntax.
      if TypeUpdater.FindReplacement(OldType, NewType) then begin
        fSrcCache.MainScanner:=Scanner;
        if not fSrcCache.Replace(gtNone, gtNone,
                      CurPos.StartPos, CurPos.EndPos, NewType) then exit;
        if not fSrcCache.Apply then exit;
      end;
    finally
      TypeUpdater.Free;
    end;
  end;
  Result:=true;
end;

procedure SplitParam(const aStr: string; aDelimiter: Char; ResultList: TStringList);
// A modified split function. Removes '$' in front of every token.

  procedure SetItem(Start, Len: integer); // Add the item.
  begin
    while (aStr[Start]=' ') do begin      // Trim leading space.
      Inc(Start);
      Dec(Len);
    end;
    while (aStr[Start+Len-1]=' ') do      // Trim trailing space.
      Dec(Len);
    if (aStr[Start]='$') then begin       // Parameters must begin with '$'.
      Inc(Start);
      Dec(Len);
    end
    else
      raise EDelphiConverterError.Create('Replacement function parameter should start with "$".');
    ResultList.Add(Copy(aStr, Start, Len));
  end;

var
  i, Start, EndPlus1: Integer;
begin
  ResultList.Clear;
  Start:=1;
  repeat
    i:=Start;
    while (i<Length(aStr)) and (aStr[i]<>aDelimiter) do
      Inc(i);                             // Next delimiter.
    EndPlus1:=i;
    if i<Length(aStr) then
    begin
      SetItem(Start, EndPlus1-Start);
      Start:=i+1;                         // Start of next item.
    end
    else begin
      EndPlus1:=i+1;
      if EndPlus1>=Start then
        SetItem(Start, EndPlus1-Start);   // Copy the rest to last item.
      Break;                              // Out of the loop.
    end;
  until False;
end;

function TConvDelphiCodeTool.ReplaceFuncsInSource: boolean;
// Replace the function names and parameters in source.
var
  ParamList: TStringList;
  BodyEnd: Integer;                     // End of function body.

  function ParseReplacementParams(const aStr: string): integer;
  // Parse replacement params. They show which original params are copied where.
  // Returns the first position where comments can be searched from.
  var
    ParamBeg, ParamEnd: Integer;        // Start and end of parameters.
    s: String;
  begin
    Result:=1;
    ParamBeg:=Pos('(', aStr);
    if ParamBeg>0 then begin
      ParamEnd:=Pos(')', aStr);
      if ParamEnd=0 then
        raise EDelphiConverterError.Create('")" is missing from replacement function.');
      s:=Copy(aStr, ParamBeg+1, ParamEnd-ParamBeg-1);
      SplitParam(s, ',', ParamList);    // The actual parameter list.
      BodyEnd:=ParamBeg-1;
      Result:=ParamEnd+1;
    end;
  end;

  function CollectParams(aParams: TStringList): string;
  // Collect parameters from original call. Construct and return a new parameter list.
  var
    Param: String;
    ParamPos: Integer;             // Position of parameter in the original call.
    i: Integer;
  begin
    Result:='';
    for i:=0 to ParamList.Count-1 do begin
      ParamPos:=StrToInt(ParamList[i]);
      if ParamPos < 1 then
        raise EDelphiConverterError.Create('Replacement function parameter number should be >= 1.');
      Param:='nil';                // Default value if not found from original code.
      if ParamPos<=aParams.Count then
        Param:=aParams[ParamPos-1];
      if Result<>'' then
        Result:=Result+', ';
      Result:=Result+Param;
    end;
  end;

  function GetComment(const aStr: string; aPossibleStartPos: integer): string;
  // Extract and return a possible comment.
  var
    CommChBeg, CommBeg, CommEnd, i: Integer;   // Start and end of comment.
  begin
    Result:='';
    CommEnd:=Length(aStr);
    CommChBeg:=PosEx('//', aStr, aPossibleStartPos);
    if CommChBeg<>0 then
      CommBeg:=CommChBeg+2
    else begin
      CommChBeg:=PosEx('{', aStr, aPossibleStartPos);
      if CommChBeg<>0 then begin
      CommBeg:=CommChBeg+1;
        i:=PosEx('}', aStr, CommBeg);
        if i<>0 then
          CommEnd:=i-1;
      end;
    end;
    if CommChBeg<>0 then begin
      if BodyEnd=-1 then
        BodyEnd:=CommChBeg-1;
      Result:=Trim(Copy(aStr, CommBeg, CommEnd-CommBeg+1));
    end;
  end;

var
  FuncInfo: TFuncReplacement;
  PossibleCommPos: Integer;                    // Start looking for comments here.
  i: Integer;
  s, NewFunc, NewParamStr, Comment: String;
begin
  Result:=false;
  ParamList:=TStringList.Create;
  try
    // Replace from bottom to top.
    for i:=fFuncsToReplace.Count-1 downto 0 do begin
      FuncInfo:=TFuncReplacement(fFuncsToReplace[i]);
      BodyEnd:=-1;
      PossibleCommPos:=ParseReplacementParams(FuncInfo.ReplFunc);
      NewParamStr:=CollectParams(FuncInfo.Params);
      Comment:=GetComment(FuncInfo.ReplFunc, PossibleCommPos);
      // Separate function body
      if BodyEnd=-1 then
        BodyEnd:=Length(FuncInfo.ReplFunc);
      NewFunc:=Trim(Copy(FuncInfo.ReplFunc, 1, BodyEnd));
      NewFunc:=Format('%s(%s)%s { *Converted from %s* %s }',
        [NewFunc, NewParamStr, FuncInfo.InclSemiColon, FuncInfo.FuncName, Comment]);
      // Old function call with params for IDE message output.
      s:=copy(fCodeTool.Src, FuncInfo.StartPos, FuncInfo.EndPos-FuncInfo.StartPos);
      s:=StringReplace(s, sLineBreak, '', [rfReplaceAll]);
      // Now replace it.
      fSrcCache.MainScanner:=fCodeTool.Scanner;
      if not fSrcCache.Replace(gtNone, gtNone,
                          FuncInfo.StartPos, FuncInfo.EndPos, NewFunc) then exit;
      IDEMessagesWindow.AddMsg('Replaced call '+s, '', -1);
      IDEMessagesWindow.AddMsg('                  with '+NewFunc, '', -1);
    end;
  finally
    ParamList.Free;
  end;
  Result:=true;
end;

function TConvDelphiCodeTool.RememberProcDefinition(aNode: TCodeTreeNode): TCodeTreeNode;
// This is called when Node.Desc=ctnProcedureHead.
// Save the defined proc name so it is not replaced later.
var
  ProcName: string;
begin
  with fCodeTool do begin
    MoveCursorToCleanPos(aNode.StartPos);
    ReadNextAtom;               // Read proc name.
    ProcName:=GetAtom;
    ReadNextAtom;
    if GetAtom<>'.' then        // Don't save a method name (like TClass.Method).
      fDefinedProcNames.Add(ProcName);
  end;
  Result:=aNode.Next;
end;

function TConvDelphiCodeTool.ReplaceFuncCalls(aIsConsoleApp: boolean): boolean;
// Copied and modified from TFindDeclarationTool.FindReferences.
// Search for calls to functions / procedures in a list from current unit's
// implementation section. Replace found calls with a given replacement.
var
  xStart: Integer;

  procedure CheckSemiColon(FuncInfo: TFuncReplacement);
  begin
    with fCodeTool do
      if AtomIsChar(';') then begin
        FuncInfo.EndPos:=CurPos.EndPos;
        FuncInfo.InclSemiColon:=';';
      end;
  end;

  procedure ReadParams(FuncInfo: TFuncReplacement);
  var
    ExprStartPos, ExprEndPos: integer;
  begin
    FuncInfo.InclSemiColon:='';
    FuncInfo.StartPos:=xStart;
    with fCodeTool do begin
      MoveCursorToCleanPos(xStart);
      ReadNextAtom;                     // Read func name.
      ReadNextAtom;                     // Read first atom after proc name.
      if AtomIsChar('(') then begin
        // read parameter list
        ReadNextAtom;
        if not AtomIsChar(')') then begin
          // read all expressions
          while true do begin
            ExprStartPos:=CurPos.StartPos;
            // read til comma or bracket close
            repeat
              ReadNextAtom;
              if (CurPos.StartPos>SrcLen)
              or (CurPos.Flag in [cafRoundBracketClose, cafComma]) then
                break;
            until false;
            ExprEndPos:=CurPos.StartPos;
            // Add parameter to list
            FuncInfo.Params.Add(copy(Src,ExprStartPos,ExprEndPos-ExprStartPos));
            MoveCursorToCleanPos(ExprEndPos);
            ReadNextAtom;
            if AtomIsChar(')') then begin
              FuncInfo.EndPos:=CurPos.EndPos;
              ReadNextAtom;
              CheckSemiColon(FuncInfo);
              break;
            end;
            if not AtomIsChar(',') then
              raise EDelphiConverterError.Create('Bracket not found');
            ReadNextAtom;
          end;
        end;
      end
      else
        CheckSemiColon(FuncInfo);
    end;
    FuncInfo.UpdateReplacement;
  end;

  procedure ReadFuncCall(MaxPos: Integer);
  var
    FuncDefInfo, FuncCallInfo: TFuncReplacement;
    FuncName: string;
    i, x, IdentEndPos: Integer;
  begin
    IdentEndPos:=xStart;
    with fCodeTool do begin
      while (IdentEndPos<=MaxPos) and (IsIdentChar[Src[IdentEndPos]]) do
        inc(IdentEndPos);
      for i:=0 to fReplaceFuncs.Funcs.Count-1 do begin
        FuncName:=fReplaceFuncs.Funcs[i];
        if (IdentEndPos-xStart=length(FuncName))
        and (CompareIdentifiers(PChar(Pointer(FuncName)),@Src[xStart])=0)
        and not fDefinedProcNames.Find(FuncName, x)
        then begin
          FuncDefInfo:=fReplaceFuncs.FuncAtInd(i);
          if fReplaceFuncs.Categories.Find(FuncDefInfo.Category, x)
          and not (aIsConsoleApp and (FuncDefInfo.Category='UTF8Names'))
          then begin
            // Create a new replacement object for params, position and other info.
            FuncCallInfo:=TFuncReplacement.Create(FuncDefInfo);
            ReadParams(FuncCallInfo);
            IdentEndPos:=FuncCallInfo.EndPos; // Skip the params, too, for next search.
            fFuncsToReplace.Add(FuncCallInfo);
            Break;
          end;
        end;
      end;
    end;
    xStart:=IdentEndPos;
  end;

  function SearchFuncCalls(aNode: TCodeTreeNode): TCodeTreeNode;
  var
    CommentLvl: Integer;
    InStrConst: Boolean;
  begin
    xStart:=aNode.StartPos;
    with fCodeTool do
    while xStart<=aNode.EndPos do begin
      case Src[xStart] of

      '{':                         // pascal comment
        begin
          inc(xStart);
          CommentLvl:=1;
          InStrConst:=false;
          while xStart<=aNode.EndPos do begin
            case Src[xStart] of
            '{': if Scanner.NestedComments then inc(CommentLvl);
            '}':
              begin
                dec(CommentLvl);
                if CommentLvl=0 then break;
              end;
            '''':
              InStrConst:=not InStrConst;
            end;
            inc(xStart);
          end;
          inc(xStart);
        end;

      '/':                         // Delphi comment
        if (Src[xStart+1]<>'/') then begin
          inc(xStart);
        end else begin
          inc(xStart,2);
          InStrConst:=false;
          while (xStart<=aNode.EndPos) do begin
            case Src[xStart] of
            #10,#13:
              break;
            '''':
              InStrConst:=not InStrConst;
            end;
            inc(xStart);
          end;
          inc(xStart);
          if (xStart<=aNode.EndPos) and (Src[xStart] in [#10,#13])
          and (Src[xStart-1]<>Src[xStart]) then
            inc(xStart);
        end;

      '(':                         // turbo pascal comment
        if (Src[xStart+1]<>'*') then begin
          inc(xStart);
        end else begin
          inc(xStart,3);
          InStrConst:=false;
          while (xStart<=aNode.EndPos) do begin
            case Src[xStart] of
            ')':
              if Src[xStart-1]='*' then break;
            '''':
              InStrConst:=not InStrConst;
            end;
            inc(xStart);
          end;
          inc(xStart);
        end;

      'a'..'z','A'..'Z','_':
        ReadFuncCall(aNode.EndPos);

      '''':
        begin                      // skip string constant
          inc(xStart);
          while (xStart<=aNode.EndPos) do begin
            if (not (Src[xStart] in ['''',#10,#13])) then
              inc(xStart)
            else begin
              inc(xStart);
              break;
            end;
          end;
        end;

      else
        inc(xStart);
      end;
    end;
    Result:=aNode.NextSkipChilds;
  end;

var
  Node: TCodeTreeNode;
begin
  Result:=false;
  with fCodeTool do begin
    fFuncsToReplace:=TObjectList.Create;
    fDefinedProcNames:=TStringList.Create;
    fDefinedProcNames.Sorted:=True;
    fDefinedProcNames.Duplicates:=dupIgnore;
    ActivateGlobalWriteLock;
    try
      BuildTree(false);
      // Only convert identifiers in ctnBeginBlock nodes
      Node:=fCodeTool.Tree.Root;
      while Node<>nil do begin
        if Node.Desc=ctnBeginBlock then
          Node:=SearchFuncCalls(Node)
        else if Node.Desc=ctnProcedureHead then
          Node:=RememberProcDefinition(Node)
        else
          Node:=Node.Next;
      end;
      if not ReplaceFuncsInSource then Exit;
    finally
      DeactivateGlobalWriteLock;
      fDefinedProcNames.Free;
      fFuncsToReplace.Free;
    end;
  end;
  Result:=true;
end;

/////////////////////////////

function TConvDelphiCodeTool.CheckTopOffsets(LFMBuf: TCodeBuffer; LFMTree: TLFMTree;
                     ParentOffsets: TStringToStringTree; ValueNodes: TObjectList): boolean;
// Collect a list of Top attributes for components that are inside
//  a visual container component. An offset will be added to those attributes.
// Parameters: ParentOffsets has names of parent visual container types.
//             ValueNodes - the found Top attributes are added here as TTopOffset objects.
// Based on function CheckLFM.
var
  RootContext: TFindContext;

  function CheckLFMObjectValues(LFMObject: TLFMObjectNode; const GrandParentContext, ClassContext: TFindContext;
                                ContextIsDefault: boolean): boolean; forward;

  function FindLFMIdentifier(LFMNode: TLFMTreeNode;
    DefaultErrorPosition: integer;
    const IdentName: string; const ClassContext: TFindContext;
    SearchAlsoInDefineProperties, ErrorOnNotFound: boolean;
    out IdentContext: TFindContext): boolean;
  var
    Params: TFindDeclarationParams;
    IdentifierNotPublished: Boolean;
    IsPublished: Boolean;
  begin
    Result:=false;
    IdentContext:=CleanFindContext;
    IsPublished:=false;
    if (ClassContext.Node=nil) or (not (ClassContext.Node.Desc in AllClasses)) then
      exit;
    Params:=TFindDeclarationParams.Create;
    try
      Params.Flags:=[fdfSearchInAncestors,fdfExceptionOnNotFound,
                     fdfExceptionOnPredefinedIdent,fdfIgnoreMissingParams,
                     fdfIgnoreOverloadedProcs];
      Params.ContextNode:=ClassContext.Node;
      Params.SetIdentifier(ClassContext.Tool,PChar(Pointer(IdentName)),nil);
      try
        if ClassContext.Tool.FindIdentifierInContext(Params) then begin
          Result:=true;
          repeat
            IdentContext:=CreateFindContext(Params);
            if (not IsPublished)
            and (IdentContext.Node.HasParentOfType(ctnClassPublished)) then
              IsPublished:=true;

            if (IdentContext.Node<>nil)
            and (IdentContext.Node.Desc=ctnProperty)
            and (IdentContext.Tool.PropNodeIsTypeLess(IdentContext.Node)) then
            begin
              // this is a typeless property -> search further
              Params.Clear;
              Params.Flags:=[fdfSearchInAncestors,
                             fdfIgnoreMissingParams,
                             fdfIgnoreCurContextNode,
                             fdfIgnoreOverloadedProcs];
              Params.ContextNode:=IdentContext.Node.Parent;
              while (Params.ContextNode<>nil)
              and (not (Params.ContextNode.Desc in AllClasses)) do
                Params.ContextNode:=Params.ContextNode.Parent;
              if Params.ContextNode<>nil then begin
                Params.SetIdentifier(ClassContext.Tool,PChar(Pointer(IdentName)),nil);
                if not IdentContext.Tool.FindIdentifierInContext(Params) then
                  break;
              end;
            end else
              break;
          until false;
        end;
      except
        on E: ECodeToolError do ;        // ignore search/parse errors
      end;
    finally
      Params.Free;
    end;

    IdentifierNotPublished:=not IsPublished;

    if (IdentContext.Node=nil) or IdentifierNotPublished then begin
      // no proper node found
    end;
    if (not Result) and ErrorOnNotFound then begin
      if (IdentContext.Node<>nil) and IdentifierNotPublished then begin
        LFMTree.AddError(lfmeIdentifierNotPublished,LFMNode,
                         'identifier '+IdentName+' is not published in class '
                         +'"'+ClassContext.Tool.ExtractClassName(ClassContext.Node,false)+'"',
                         DefaultErrorPosition);
      end else begin
        LFMTree.AddError(lfmeIdentifierNotFound,LFMNode,
                         'identifier '+IdentName+' not found in class '
                         +'"'+ClassContext.Tool.ExtractClassName(ClassContext.Node,false)+'"',
                         DefaultErrorPosition);
      end;
    end;
  end;
////////////////////////

  function FindClassNodeForLFMObject(LFMNode: TLFMTreeNode;
    DefaultErrorPosition: integer;
    StartTool: TFindDeclarationTool; DefinitionNode: TCodeTreeNode): TFindContext;
  var
    Params: TFindDeclarationParams;
    Identifier: PChar;
    OldInput: TFindDeclarationInput;
  begin
    Result:=CleanFindContext;
    if (DefinitionNode.Desc=ctnIdentifier) then
      Identifier:=@StartTool.Src[DefinitionNode.StartPos]
    else if DefinitionNode.Desc=ctnProperty then
      Identifier:=StartTool.GetPropertyTypeIdentifier(DefinitionNode)
    else
      Identifier:=nil;
    if Identifier=nil then exit;
    Params:=TFindDeclarationParams.Create;
    try
      Params.Flags:=[fdfSearchInAncestors,fdfExceptionOnNotFound,
        fdfSearchInParentNodes,
        fdfExceptionOnPredefinedIdent,fdfIgnoreMissingParams,
        fdfIgnoreOverloadedProcs];
      Params.ContextNode:=DefinitionNode;
      Params.SetIdentifier(StartTool,Identifier,nil);
      try
        Params.Save(OldInput);
        if StartTool.FindIdentifierInContext(Params) then begin
          Params.Load(OldInput,true);
          Result:=Params.NewCodeTool.FindBaseTypeOfNode(Params,Params.NewNode);
          if (Result.Node=nil)
          or (not (Result.Node.Desc in AllClasses)) then
            Result:=CleanFindContext;
        end;
      except
        on E: ECodeToolError do ;        // ignore search/parse errors
      end;
    finally
      Params.Free;
    end;
    if Result.Node=nil then begin
      // FindClassNodeForLFMObject
      LFMTree.AddError(lfmeIdentifierNotFound,LFMNode,
                       'class '+GetIdentifier(Identifier)+' not found',
                       DefaultErrorPosition);
      exit;
    end;
  end;
////////////////////

  function CreateFootNote(const Context: TFindContext): string;
  var
    Caret: TCodeXYPosition;
  begin
    Result:=' see '+Context.Tool.MainFilename;
    if Context.Tool.CleanPosToCaret(Context.Node.StartPos,Caret) then
      Result:=Result+'('+IntToStr(Caret.Y)+','+IntToStr(Caret.X)+')';
  end;
///////////////

  function FindClassContext(const ClassName: string): TFindContext;
  var
    Params: TFindDeclarationParams;
    Identifier: PChar;
    OldInput: TFindDeclarationInput;
    StartTool: TStandardCodeTool;
  begin
    Result:=CleanFindContext;
    Params:=TFindDeclarationParams.Create;
    StartTool:=fCodeTool;
    Identifier:=PChar(Pointer(ClassName));
    try
      Params.Flags:=[fdfExceptionOnNotFound,
        fdfSearchInParentNodes,
        fdfExceptionOnPredefinedIdent,fdfIgnoreMissingParams,
        fdfIgnoreOverloadedProcs];
      with fCodeTool do begin
        Params.ContextNode:=FindInterfaceNode;
        if Params.ContextNode=nil then
          Params.ContextNode:=FindMainUsesSection;
        Params.SetIdentifier(StartTool,Identifier,nil);
        try
          Params.Save(OldInput);
          if FindIdentifierInContext(Params) then begin
            Params.Load(OldInput,true);
            Result:=Params.NewCodeTool.FindBaseTypeOfNode(Params,Params.NewNode);
            if (Result.Node=nil)
            or (not (Result.Node.Desc in AllClasses)) then
              Result:=CleanFindContext;
          end;
        except
          on E: ECodeToolError do ;          // ignore search/parse errors
        end;
      end;
    finally
      Params.Free;
    end;
  end;
/////////////////

  procedure CheckLFMChildObject(LFMObject: TLFMObjectNode;
    const GrandParentContext, ParentContext: TFindContext;
    SearchAlsoInDefineProperties, ContextIsDefault: boolean);
  var
    LFMObjectName: String;
    VariableTypeName: String;
    ChildContext: TFindContext;
    DefinitionNode: TCodeTreeNode;
    ClassContext: TFindContext;
    IdentifierFound: Boolean;
  begin
    // find variable for object
    LFMObjectName:=LFMObject.Name;    // find identifier in Lookup Root
    if LFMObjectName='' then begin
      LFMTree.AddError(lfmeObjectNameMissing,LFMObject,'missing object name',
                       LFMObject.StartPos);
      exit;
    end;

    IdentifierFound:=(not ContextIsDefault) and
      FindLFMIdentifier(LFMObject, LFMObject.NamePosition,
                        LFMObjectName, RootContext, SearchAlsoInDefineProperties,
                        True, ChildContext);

    if IdentifierFound then begin
      if ChildContext.Node=nil then begin
        // this is an extra entry, created via DefineProperties.
        // There is no generic way to test such things
        exit;
      end;

      // check if identifier is a variable or property
      VariableTypeName:='';
      if (ChildContext.Node.Desc=ctnVarDefinition) then begin
        DefinitionNode:=ChildContext.Tool.FindTypeNodeOfDefinition(ChildContext.Node);
        if DefinitionNode=nil then begin
          ChildContext.Node:=DefinitionNode;
          LFMTree.AddError(lfmeObjectIncompatible,LFMObject,
                           LFMObjectName+' is not a variable.'
                           +CreateFootNote(ChildContext),
                           LFMObject.NamePosition);
          exit;
        end;

        VariableTypeName:=ChildContext.Tool.ExtractDefinitionNodeType(ChildContext.Node);
      end else if (ChildContext.Node.Desc=ctnProperty) then begin
        DefinitionNode:=ChildContext.Node;
        VariableTypeName:=ChildContext.Tool.ExtractPropType(ChildContext.Node,false,false);
      end else begin
        LFMTree.AddError(lfmeObjectIncompatible,LFMObject,
                         LFMObjectName+' is not a variable'
                         +CreateFootNote(ChildContext),
                         LFMObject.NamePosition);
        exit;
      end;

      // check if variable/property has a compatible type
      if (VariableTypeName<>'') and (LFMObject.TypeName<>'')
          and (CompareIdentifiers(PChar(VariableTypeName),
                                  PChar(LFMObject.TypeName))<>0) then begin
        ChildContext.Node:=DefinitionNode;
        LFMTree.AddError(lfmeObjectIncompatible, LFMObject,
                       VariableTypeName+' expected, but '+LFMObject.TypeName+' found.'
                       +CreateFootNote(ChildContext), LFMObject.NamePosition);
        exit;
      end;

      // find class node
      ClassContext:=FindClassNodeForLFMObject(LFMObject,LFMObject.TypeNamePosition,
                                              ChildContext.Tool,DefinitionNode);
    end else begin
      // try the object type
      ClassContext:=FindClassContext(LFMObject.TypeName);
      if ClassContext.Node=nil then begin
        // object type not found
        LFMTree.AddError(lfmeIdentifierNotFound,LFMObject,
                         'type '+LFMObject.TypeName+' not found',
                         LFMObject.TypeNamePosition);
      end;
    end;
    // check child LFM nodes
    if ClassContext.Node<>nil then
      CheckLFMObjectValues(LFMObject, ParentContext, ClassContext, false)
    else
      raise Exception.Create('No ClassContext in CheckLFMChildObject'); //CheckLFMObjectValues(LFMObject, CleanFindContext, ParentContext, true);
  end;
/////////////////

  function FindClassNodeForPropertyType(LFMProperty: TLFMPropertyNode;
    DefaultErrorPosition: integer; const PropertyContext: TFindContext): TFindContext;
  var
    Params: TFindDeclarationParams;
  begin
    Result:=CleanFindContext;
    Params:=TFindDeclarationParams.Create;
    try
      Params.Flags:=[fdfSearchInAncestors,  fdfExceptionOnNotFound,
                     fdfSearchInParentNodes,fdfExceptionOnPredefinedIdent,
                     fdfIgnoreMissingParams,fdfIgnoreOverloadedProcs];
      Params.ContextNode:=PropertyContext.Node;
      Params.SetIdentifier(PropertyContext.Tool,nil,nil);
      try
        Result:=PropertyContext.Tool.FindBaseTypeOfNode(Params, PropertyContext.Node);
      except
        on E: ECodeToolError do ;              // ignore search/parse errors
      end;
    finally
      Params.Free;
    end;
    if Result.Node=nil then begin
      LFMTree.AddError(lfmePropertyHasNoSubProperties,LFMProperty,
                       'property has no sub properties', DefaultErrorPosition);
      exit;
    end;
  end;
//////////////////

  procedure CheckLFMProperty(LFMProperty: TLFMPropertyNode;
    const GrandParentContext, ParentContext: TFindContext);
  // checks properties. For example lines like 'OnShow = FormShow'
  // or 'VertScrollBar.Range = 29'
  // LFMProperty is the property node
  // ParentContext is the context, where properties are searched.
  //               This can be a class or a property.
  var
    i: Integer;
    ValNode: TLFMValueNode;
    CurName, GrandName: string;
    CurPropertyContext: TFindContext;
    SearchContext: TFindContext;
  begin
    // find complete property name
    if LFMProperty.CompleteName='' then begin
      LFMTree.AddError(lfmePropertyNameMissing, LFMProperty,
                       'property without name', LFMProperty.StartPos);
      exit;
    end;

  if LFMProperty.CompleteName='Top' then begin
    CurName:=ParentContext.Tool.ExtractClassName(ParentContext.Node, False);
    GrandName:=GrandParentContext.Tool.ExtractClassName(GrandParentContext.Node, False);
    if ParentOffsets[GrandName]<>'' then begin
      if LFMProperty.FirstChild is TLFMValueNode then begin
        ValNode:=LFMProperty.FirstChild as TLFMValueNode;
        ValueNodes.Add(TTopOffset.Create(GrandName, CurName, ValNode.StartPos));
      end;
    end;
  end;

    // find every part of the property name
    SearchContext:=ParentContext;
    for i:=0 to LFMProperty.NameParts.Count-1 do begin
      if SearchContext.Node.Desc=ctnProperty then begin
        // get the type of the property and search the class node
        SearchContext:=FindClassNodeForPropertyType(LFMProperty,
          LFMProperty.NameParts.NamePositions[i],SearchContext);
        if SearchContext.Node=nil then exit;
      end;

      CurName:=LFMProperty.NameParts.Names[i];
      if not FindLFMIdentifier(LFMProperty,
                       LFMProperty.NameParts.NamePositions[i],
                       CurName, SearchContext, true, true, CurPropertyContext) then
        break;
      if CurPropertyContext.Node=nil then begin
        // this is an extra entry, created via DefineProperties.
        // There is no generic way to test such things
        break;
      end;
      SearchContext:=CurPropertyContext;
    end;
  end;
////////////

  function CheckLFMObjectValues(LFMObject: TLFMObjectNode;
    const GrandParentContext, ClassContext: TFindContext; ContextIsDefault: boolean): boolean;
  var
    CurLFMNode: TLFMTreeNode;
    i: Integer;
  begin
    CurLFMNode:=LFMObject.FirstChild;
    while CurLFMNode<>nil do begin
      case CurLFMNode.TheType of
      lfmnObject:
        CheckLFMChildObject(TLFMObjectNode(CurLFMNode),
                        GrandParentContext, ClassContext, false, ContextIsDefault);
      lfmnProperty:
        if not ContextIsDefault then
          CheckLFMProperty(TLFMPropertyNode(CurLFMNode),
                           GrandParentContext, ClassContext);
      end;
      CurLFMNode:=CurLFMNode.NextSibling;
    end;
    Result:=true;
  end;
////////////

  function CheckLFMRoot(RootLFMNode: TLFMTreeNode): boolean;
  var
    LookupRootLFMNode: TLFMObjectNode;
    LookupRootTypeName: String;
    RootClassNode: TCodeTreeNode;
  begin
    Result:=false;
    // get root object node
    if (RootLFMNode=nil) or (not (RootLFMNode is TLFMObjectNode)) then begin
      LFMTree.AddError(lfmeMissingRoot,nil,'missing root object',1);
      exit;
    end;
    LookupRootLFMNode:=TLFMObjectNode(RootLFMNode);

    // get type name of root object
    LookupRootTypeName:=UpperCaseStr(LookupRootLFMNode.TypeName);
    if LookupRootTypeName='' then begin
      LFMTree.AddError(lfmeMissingRoot,nil,'missing type of root object',1);
      exit;
    end;

    // find root type
    RootClassNode:=fCodeTool.FindClassNodeInInterface(LookupRootTypeName,true,false,false);
    RootContext:=CleanFindContext;
    RootContext.Node:=RootClassNode;
    RootContext.Tool:=fCodeTool;
    if RootClassNode=nil then begin
      LFMTree.AddError(lfmeMissingRoot,LookupRootLFMNode,
                       'type '+LookupRootLFMNode.TypeName+' not found',
                       LookupRootLFMNode.TypeNamePosition);
      exit;
    end;
    Result:=CheckLFMObjectValues(LookupRootLFMNode, CleanFindContext, RootContext, false);
  end;
///////////////

var
  CurRootLFMNode: TLFMTreeNode;
begin
  Result:=false;
  // create tree from LFM file
  LFMTree:=DefaultLFMTrees.GetLFMTree(LFMBuf,true);
  fCodeTool.ActivateGlobalWriteLock;
  try
    if not LFMTree.ParseIfNeeded then exit;
    // parse unit and find LookupRoot
    fCodeTool.BuildTree(true);
    // find every identifier
    CurRootLFMNode:=LFMTree.Root;
    while CurRootLFMNode<>nil do begin
      if not CheckLFMRoot(CurRootLFMNode) then exit;
      CurRootLFMNode:=CurRootLFMNode.NextSibling;
    end;
  finally
    fCodeTool.DeactivateGlobalWriteLock;
  end;
  Result:=LFMTree.FirstError=nil;
end;


end.

