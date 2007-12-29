{
/***************************************************************************
                               LazDoc.pas
                               ----------

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
unit CodeHelp;

{$mode objfpc}{$H+}

{ $define VerboseLazDoc}

interface

uses
  Classes, SysUtils, LCLProc, Forms, Controls, FileUtil, Dialogs, AvgLvlTree,
  // codetools
  CodeAtom, CodeTree, CodeToolManager, FindDeclarationTool, BasicCodeTools,
  CodeCache, CacheCodeTools, FileProcs,
  Laz_DOM, Laz_XMLRead, Laz_XMLWrite,
  // IDEIntf
  MacroIntf, PackageIntf, LazHelpIntf, ProjectIntf, IDEDialogs, LazIDEIntf,
  // IDE
  CompilerOptions, IDEProcs, PackageDefs, EnvironmentOpts, DialogProcs;

type
  TFPDocItem = (
    fpdiShort,
    fpdiDescription,
    fpdiErrors,
    fpdiSeeAlso,
    fpdiExample
    );

  TFPDocElementValues = array [TFPDocItem] of String;
  
const
  FPDocItemNames: array[TFPDocItem] of shortstring = (
      'short',
      'descr',
      'errors',
      'seealso',
      'example'
    );

type

  TLazFPDocFileFlag = (
    ldffDocChangingCalled,
    ldffDocChangedNeedsCalling
    );
  TLazFPDocFileFlags = set of TLazFPDocFileFlag;

  { TLazFPDocFile }

  TLazFPDocFile = class
  private
    fUpdateLock: integer;
    FFlags: TLazFPDocFileFlags;
  public
    Filename: string;
    Doc: TXMLdocument;// IMPORTANT: if you change this, call DocChanging and DocChanged to notify the references
    DocModified: boolean;
    ChangeStep: integer;// the CodeBuffer.ChangeStep value, when Doc was build
    CodeBuffer: TCodeBuffer;
    destructor Destroy; override;
    function GetModuleNode: TDOMNode;
    function GetFirstElement: TDOMNode;
    function GetElementWithName(const ElementName: string;
                                CreateIfNotExists: boolean = false): TDOMNode;
    function GetChildValuesAsString(Node: TDOMNode): String;
    function GetValuesFromNode(Node: TDOMNode): TFPDocElementValues;
    function GetValueFromNode(Node: TDOMNode; Item: TFPDocItem): string;
    procedure SetChildValue(Node: TDOMNode; const ChildName: string; NewValue: string);
    procedure DocChanging;
    procedure DocChanged;
    procedure BeginUpdate;
    procedure EndUpdate;
  end;
  
  { TLDSourceToFPDocFile - cache item for source to FPDoc file mapping }

  TLDSourceToFPDocFile = class
  public
    SourceFilename: string;
    FPDocFilename: string;
    FPDocFilenameTimeStamp: integer;
    FilesTimeStamp: integer;
  end;
  
  { TLazDocElement }

  TLazDocElement = class
  public
    CodeContext: TFindContext;
    CodeXYPos: TCodeXYPosition;
    ElementName: string;
    ElementNode: TDOMNode;
    ElementNodeValid: boolean;
    FPDocFile: TLazFPDocFile;
  end;
  
  { TLazDocElementChain }

  TLazDocElementChain = class
  private
    FItems: TFPList; // list of TLazDocElement
    function GetCount: integer;
    function GetItems(Index: integer): TLazDocElement;
    function Add: TLazDocElement;
  public
    CodePos: TCodePosition;
    IDEChangeStep: integer;
    CodetoolsChangeStep: integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    property Items[Index: integer]: TLazDocElement read GetItems; default;
    property Count: integer read GetCount;
    function IndexOfFile(AFile: TLazFPDocFile): integer;
    function IsValid: boolean;
    procedure MakeValid;
    function DocFile: TLazFPDocFile;
  end;
  
  TLazDocChangeEvent = procedure(Sender: TObject; LazDocFPFile: TLazFPDocFile) of object;
  
  TLazDocManagerHandler = (
    ldmhDocChanging,
    ldmhDocChanged
    );
    
  TLazDocParseResult = (
    ldprParsing, // means: done a small step, but not yet finished the job
    ldprFailed,
    ldprSuccess
    );
    
  { TLazDocManager }

  TLazDocManager = class
  private
    FDocs: TAvgLvlTree;// tree of loaded TLazFPDocFile
    FHandlers: array[TLazDocManagerHandler] of TMethodList;
    FSrcToDocMap: TAvgLvlTree; // tree of TLDSourceToFPDocFile sorted for SourceFilename
    FDeclarationCache: TDeclarationInheritanceCache;
    procedure AddHandler(HandlerType: TLazDocManagerHandler;
                         const AMethod: TMethod; AsLast: boolean = false);
    procedure RemoveHandler(HandlerType: TLazDocManagerHandler;
                            const AMethod: TMethod);
    procedure CallDocChangeEvents(HandlerType: TLazDocManagerHandler;
                                  Doc: TLazFPDocFile);
    function DoCreateFPDocFileForSource(const SrcFilename: string): string;
    function CreateFPDocFile(const ExpandedFilename, PackageName,
                             ModuleName: string): TCodeBuffer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure FreeDocs;
    procedure ClearSrcToDocMap;
    
    function FindFPDocFile(const Filename: string): TLazFPDocFile;
    function LoadFPDocFile(const Filename: string;
                           UpdateFromDisk, Revert: Boolean;
                           out ADocFile: TLazFPDocFile;
                           out CacheWasUsed: boolean): Boolean;
    function SaveFPDocFile(ADocFile: TLazFPDocFile): TModalResult;
    function GetFPDocFilenameForHelpContext(
                                       Context: TPascalHelpContextList;
                                       out CacheWasUsed: boolean): string;
    function GetFPDocFilenameForSource(SrcFilename: string;
                                       ResolveIncludeFiles: Boolean;
                                       out CacheWasUsed: boolean;
                                       CreateIfNotExists: boolean = false): string;
    function CodeNodeToElementName(Tool: TFindDeclarationTool;
                                   CodeNode: TCodeTreeNode): string;
    function GetFPDocNode(Tool: TCodeTool; CodeNode: TCodeTreeNode; Complete: boolean;
                          out FPDocFile: TLazFPDocFile; out DOMNode: TDOMNode;
                          out CacheWasUsed: boolean): TLazDocParseResult;
    function GetDeclarationChain(Code: TCodeBuffer; X, Y: integer;
                                 out ListOfPCodeXYPosition: TFPList;
                                 out CacheWasUsed: boolean): TLazDocParseResult;
    function GetCodeContext(CodePos: PCodeXYPosition;
                            out FindContext: TFindContext;
                            Complete: boolean;
                            out CacheWasUsed: boolean): TLazDocParseResult;
    function GetElementChain(Code: TCodeBuffer; X, Y: integer; Complete: boolean;
                             out Chain: TLazDocElementChain;
                             out CacheWasUsed: boolean): TLazDocParseResult;
    function GetHint(Code: TCodeBuffer; X, Y: integer; Complete: boolean;
                     out Hint: string;
                     out CacheWasUsed: boolean): TLazDocParseResult;
    function CreateElement(Code: TCodeBuffer; X, Y: integer;
                           out Element: TLazDocElement): Boolean;
  public
    // Event lists
    procedure RemoveAllHandlersOfObject(AnObject: TObject);
    procedure AddHandlerOnChanging(const OnDocChangingEvent: TLazDocChangeEvent;
                                   AsLast: boolean = false);
    procedure RemoveHandlerOnChanging(const OnDocChangingEvent: TLazDocChangeEvent);
    procedure AddHandlerOnChanged(const OnDocChangedEvent: TLazDocChangeEvent;
                                  AsLast: boolean = false);
    procedure RemoveHandlerOnChanged(const OnDocChangedEvent: TLazDocChangeEvent);
  end;

var
  LazDocBoss: TLazDocManager = nil;// set by the IDE
  
function CompareLazFPDocFilenames(Data1, Data2: Pointer): integer;
function CompareAnsistringWithLazFPDocFile(Key, Data: Pointer): integer;
function CompareLDSrc2DocSrcFilenames(Data1, Data2: Pointer): integer;
function CompareAnsistringWithLDSrc2DocSrcFile(Key, Data: Pointer): integer;

function ToUnixLineEnding(const s: String): String;


implementation


function ToUnixLineEnding(const s: String): String;
var
  p: Integer;
begin
  Result:=s;
  p:=1;
  while (p<=length(s)) do begin
    if not (s[p] in [#10,#13]) then begin
      inc(p);
    end else begin
      // line ending
      if (p<length(s)) and (s[p+1] in [#10,#13]) and (s[p]<>s[p+1]) then begin
        // double character line ending
        Result:=copy(Result,1,p-1)+#10+copy(Result,p+2,length(Result));
      end else if s[p]=#13 then begin
        // single char line ending #13
        Result[p]:=#10;
      end;
      inc(p);
    end;
  end;
end;

function CompareLazFPDocFilenames(Data1, Data2: Pointer): integer;
begin
  Result:=CompareFilenames(TLazFPDocFile(Data1).Filename,
                           TLazFPDocFile(Data2).Filename);
end;

function CompareAnsistringWithLazFPDocFile(Key, Data: Pointer): integer;
begin
  Result:=CompareFilenames(AnsiString(Key),TLazFPDocFile(Data).Filename);
end;

function CompareLDSrc2DocSrcFilenames(Data1, Data2: Pointer): integer;
begin
  Result:=CompareFilenames(TLDSourceToFPDocFile(Data1).SourceFilename,
                           TLDSourceToFPDocFile(Data2).SourceFilename);
end;

function CompareAnsistringWithLDSrc2DocSrcFile(Key, Data: Pointer): integer;
begin
  Result:=CompareFilenames(AnsiString(Key),TLDSourceToFPDocFile(Data).SourceFilename);
end;

{ TLazFPDocFile }

destructor TLazFPDocFile.Destroy;
begin
  FreeAndNil(Doc);
  inherited Destroy;
end;

function TLazFPDocFile.GetModuleNode: TDOMNode;
begin
  Result:=nil;
  if Doc=nil then exit;

  // get first node
  Result := Doc.FindNode('fpdoc-descriptions');
  if Result=nil then begin
    //DebugLn(['TLazFPDocFile.GetModuleNode fpdoc-descriptions not found']);
    exit;
  end;

  // proceed to package
  Result := Result.FindNode('package');
  if Result=nil then begin
    //DebugLn(['TLazFPDocFile.GetModuleNode fpdoc-descriptions has no package']);
    exit;
  end;

  // proceed to module
  Result := Result.FindNode('module');
end;

function TLazFPDocFile.GetFirstElement: TDOMNode;
begin
  //get first module node
  Result := GetModuleNode;
  //DebugLn(['TLazFPDocFile.GetFirstElement GetModuleNode=',GetModuleNode<>nil]);
  if Result=nil then exit;

  //proceed to element
  Result := Result.FirstChild;
  while (Result<>nil) and (Result.NodeName <> 'element') do
    Result := Result.NextSibling;
end;

function TLazFPDocFile.GetElementWithName(const ElementName: string;
  CreateIfNotExists: boolean): TDOMNode;
var
  ModuleNode: TDOMNode;
begin
  Result:=GetFirstElement;
  //DebugLn(['TLazFPDocFile.GetElementWithName ',ElementName,' GetFirstElement=',GetFirstElement<>nil]);
  while Result<>nil do begin
    //DebugLn(['TLazFPDocFile.GetElementWithName ',dbgsName(Result)]);
    //if Result is TDomElement then DebugLn(['TLazFPDocFile.GetElementWithName ',TDomElement(Result).GetAttribute('name')]);
    if (Result is TDomElement)
    and (SysUtils.CompareText(TDomElement(Result).GetAttribute('name'),ElementName)=0)
    then
      exit;
    Result:=Result.NextSibling;
  end;
  if (Result=nil) and CreateIfNotExists then begin
    DebugLn(['TLazFPDocFile.GetElementWithName creating ',ElementName]);
    ModuleNode:=GetModuleNode;
    if ModuleNode=nil then begin
      DebugLn(['TLazFPDocFile.GetElementWithName create failed: missing module name. ElementName=',ElementName]);
      exit;
    end;
    Result:=Doc.CreateElement('element');
    DocChanging;
    TDOMElement(Result).SetAttribute('name',ElementName);
    ModuleNode.AppendChild(Result);
    DocChanged;
  end;
end;

function TLazFPDocFile.GetChildValuesAsString(Node: TDOMNode): String;
var
  Child: TDOMNode;
begin
  Result:='';
  Child:=Node.FirstChild;
  while Child<>nil do begin
    //DebugLn(['TLazFPDocFile.GetChildValuesAsString ',dbgsName(Child)]);
    if Child is TDOMText then begin
      //DebugLn(['TLazFPDocFile.GetChildValuesAsString Data="',TDOMText(Child).Data,'" Length=',TDOMText(Child).Length]);
      Result:=Result+TDOMText(Child).Data;
    end;
    Child:=Child.NextSibling;
  end;
end;

function TLazFPDocFile.GetValuesFromNode(Node: TDOMNode): TFPDocElementValues;
// simple function to return the values as string
var
  S: String;
begin
  Node := Node.FirstChild;
  while Assigned(Node) do
  begin
    if (Node.NodeType = ELEMENT_NODE) then
    begin
      S := Node.NodeName;

      if S = 'short' then
        Result[fpdiShort] := GetChildValuesAsString(Node);

      if S = 'descr' then
        Result[fpdiDescription] := GetChildValuesAsString(Node);

      if S = 'errors' then
        Result[fpdiErrors] := GetChildValuesAsString(Node);

      if S = 'seealso' then
        Result[fpdiSeeAlso] := GetChildValuesAsString(Node);

      if S = 'example' then
        Result[fpdiExample] := Node.Attributes.GetNamedItem('file').NodeValue;
    end;
    Node := Node.NextSibling;
  end;
end;

function TLazFPDocFile.GetValueFromNode(Node: TDOMNode; Item: TFPDocItem
  ): string;
var
  Child: TDOMNode;
begin
  Result:='';
  Child:=Node.FindNode(FPDocItemNames[Item]);
  //DebugLn(['TLazFPDocFile.GetValueFromNode ',FPDocItemNames[Item],' Found=',Child<>nil]);
  if Child<>nil then begin
    if Item=fpdiExample then
      Result := Child.Attributes.GetNamedItem('file').NodeValue
    else
      Result := GetChildValuesAsString(Child);
  end;
end;

procedure TLazFPDocFile.SetChildValue(Node: TDOMNode; const ChildName: string;
  NewValue: string);
var
  Child: TDOMNode;
  TextNode: TDOMText;
begin
  Child:=Node.FindNode(ChildName);
  NewValue:=ToUnixLineEnding(NewValue);
  if Child=nil then begin
    {if ChildName = 'example' then begin
      OldNode:=Child.Attributes.GetNamedItem('file');
      NewValue:=FilenameToURLPath(NewValue);
      if (NewValue<>'')
      or (not (OldNode is TDOMAttr))
      or (TDOMAttr(OldNode).Value<>NewValue) then begin
        DebugLn(['TLazFPDocFile.SetChildValue Changing Name=',ChildName,' NewValue="',NewValue,'"']);
        // add or change example
        DocChanging;
        FileAttribute := Doc.CreateAttribute('file');
        FileAttribute.Value := NewValue;
        OldNode:=Node.Attributes.SetNamedItem(FileAttribute);
        OldNode.Free;
        DocChanged;
      end;
    end
    else }
    // add node
    if NewValue<>'' then begin
      DebugLn(['TLazFPDocFile.SetChildValue Adding Name=',ChildName,' NewValue="',NewValue,'"']);
      DocChanging;
      Child := Doc.CreateElement(ChildName);
      Node.AppendChild(Child);
      TextNode := Doc.CreateTextNode(NewValue);
      Child.AppendChild(TextNode);
      DocChanged;
    end;
  end else if GetChildValuesAsString(Child)<>NewValue then begin
    // change node
    DocChanging;
    while Child.FirstChild<>nil do
      Child.FirstChild.Free;
    DebugLn(['TLazDocForm.CheckAndWriteNode Changing ',Node.NodeName,' ChildName=',Child.NodeName,' OldValue=',Child.FirstChild.NodeValue,' NewValue="',NewValue,'"']);
    TextNode := Doc.CreateTextNode(NewValue);
    Child.AppendChild(TextNode);
    DocChanged;
  end;
end;

procedure TLazFPDocFile.DocChanging;
begin
  DocModified:=true;
  if (fUpdateLock>0) then begin
    if (ldffDocChangingCalled in FFlags) then exit;
    Include(FFlags,ldffDocChangingCalled);
  end;
  LazDocBoss.CallDocChangeEvents(ldmhDocChanging,Self);
end;

procedure TLazFPDocFile.DocChanged;
begin
  if (fUpdateLock>0) then begin
    Include(FFlags,ldffDocChangedNeedsCalling);
    exit;
  end;
  Exclude(FFlags,ldffDocChangedNeedsCalling);
  LazDocBoss.CallDocChangeEvents(ldmhDocChanged,Self);
end;

procedure TLazFPDocFile.BeginUpdate;
begin
  inc(fUpdateLock);
end;

procedure TLazFPDocFile.EndUpdate;
begin
  dec(fUpdateLock);
  if fUpdateLock<0 then RaiseGDBException('TLazFPDocFile.EndUpdate');
  if fUpdateLock=0 then begin
    Exclude(FFlags,ldffDocChangingCalled);
    if ldffDocChangedNeedsCalling in FFlags then
      DocChanged;
  end;
end;

procedure TLazDocManager.AddHandler(HandlerType: TLazDocManagerHandler;
  const AMethod: TMethod; AsLast: boolean);
begin
  if FHandlers[HandlerType]=nil then
    FHandlers[HandlerType]:=TMethodList.Create;
  FHandlers[HandlerType].Add(AMethod);
end;

procedure TLazDocManager.RemoveHandler(HandlerType: TLazDocManagerHandler;
  const AMethod: TMethod);
begin
  FHandlers[HandlerType].Remove(AMethod);
end;

procedure TLazDocManager.CallDocChangeEvents(HandlerType: TLazDocManagerHandler;
  Doc: TLazFPDocFile);
var
  i: LongInt;
begin
  i:=FHandlers[HandlerType].Count;
  while FHandlers[HandlerType].NextDownIndex(i) do
    TLazDocChangeEvent(FHandlers[HandlerType].Items[i])(Self,Doc);
end;

function TLazDocManager.DoCreateFPDocFileForSource(const SrcFilename: string
  ): string;
  
  procedure CleanUpPkgList(var PkgList: TFPList);
  var
    i: Integer;
    AProject: TLazProject;
    BaseDir: String;
    APackage: TLazPackage;
  begin
    if (PkgList=nil) then exit;
    for i:=PkgList.Count-1 downto 0 do begin
      if TObject(PkgList[i]) is TLazProject then begin
        AProject:=TLazProject(PkgList[i]);
        BaseDir:=ExtractFilePath(AProject.ProjectInfoFile);
        if BaseDir<>'' then continue;
      end else if TObject(PkgList[i]) is TLazPackage then begin
        APackage:=TLazPackage(PkgList[i]);
        BaseDir:=APackage.Directory;
        if BaseDir<>'' then continue;
      end;
      // this owner can not be used
      PkgList.Delete(i);
    end;
    if PkgList.Count=0 then
      FreeAndNil(PkgList);
      
    if PkgList.Count>1 then begin
      // there are more than one possible owners
      DebugLn(['TLazDocManager.DoCreateFPDocFileForSource.CleanUpPkgList Warning: overlapping projects/packages']);
    end;
  end;
  
  function SelectNewLazDocPaths(const Title, BaseDir: string): string;
  begin
    Result:=LazSelectDirectory('Choose LazDoc directory for '+Title,BaseDir);
  end;
  
var
  PkgList: TFPList;
  NewOwner: TObject;
  AProject: TLazProject;
  APackage: TLazPackage;
  p: Integer;
  LazDocPaths: String;
  LazDocPackageName: String;
  NewPath: String;
  BaseDir: String;
  Code: TCodeBuffer;
  CurUnitName: String;
  AVLNode: TAvgLvlTreeNode;
begin
  Result:='';
  DebugLn(['TLazDocManager.DoCreateFPDocFileForSource ',SrcFilename]);
  if not FilenameIsAbsolute(SrcFilename) then begin
    DebugLn(['TLazDocManager.DoCreateFPDocFileForSource failed, because file no absolute: ',SrcFilename]);
    exit;
  end;

  PkgList:=nil;
  try
    // get all packages owning the file
    PkgList:=PackageEditingInterface.GetOwnersOfUnit(SrcFilename);
    CleanUpPkgList(PkgList);
    if (PkgList=nil) then begin
      PkgList:=PackageEditingInterface.GetOwnersOfUnit(SrcFilename);
      CleanUpPkgList(PkgList);
    end;
    if PkgList=nil then begin
      // no package/project found
      MessageDlg('Package not found',
        'The unit '+SrcFilename+' is not owned be any package or project.'#13
        +'Please add the unit to a package or project.'#13
        +'Unable to create the fpdoc file.',mtError,[mbCancel],0);
      exit;
    end;

    NewOwner:=TObject(PkgList[0]);
    if NewOwner is TLazProject then begin
      AProject:=TLazProject(NewOwner);
      BaseDir:=ExtractFilePath(AProject.ProjectInfoFile);
      if AProject.LazDocPaths='' then
        AProject.LazDocPaths:=SelectNewLazDocPaths(AProject.ShortDescription,BaseDir);
      LazDocPaths:=AProject.LazDocPaths;
      LazDocPackageName:=ExtractFileNameOnly(AProject.ProjectInfoFile);
    end else if NewOwner is TLazPackage then begin
      APackage:=TLazPackage(NewOwner);
      BaseDir:=APackage.Directory;
      if APackage.LazDocPaths='' then
        APackage.LazDocPaths:=SelectNewLazDocPaths(APackage.Name,BaseDir);
      LazDocPaths:=APackage.LazDocPaths;
      LazDocPackageName:=APackage.Name;
    end else begin
      DebugLn(['TLazDocManager.DoCreateFPDocFileForSource unknown owner type ',dbgsName(NewOwner)]);
      exit;
    end;
      
    p:=1;
    repeat
      NewPath:=GetNextDirectoryInSearchPath(LazDocPaths,p);
      if not FilenameIsAbsolute(NewPath) then
        NewPath:=AppendPathDelim(BaseDir)+NewPath;
      if DirPathExistsCached(NewPath) then begin
        // fpdoc directory found
        Result:=AppendPathDelim(NewPath)+lowercase(ExtractFileNameOnly(SrcFilename))+'.xml';
        Code:=CodeToolBoss.LoadFile(SrcFilename,true,false);
        // get unitname
        CurUnitName:=ExtractFileNameOnly(SrcFilename);
        if Code<>nil then
          CurUnitName:=CodeToolBoss.GetSourceName(Code,false);
        // remove cache (source to fpdoc filename)
        AVLNode:=FSrcToDocMap.FindKey(Pointer(SrcFilename),
                                      @CompareAnsistringWithLDSrc2DocSrcFile);
        if AVLNode<>nil then
          FSrcToDocMap.FreeAndDelete(AVLNode);
        // create fpdoc file
        if CreateFPDocFile(Result,LazDocPackageName,CurUnitName)=nil then
          Result:='';
        exit;
      end;
    until false;
    
    // no valid directory found
    DebugLn(['TLazDocManager.DoCreateFPDocFileForSource LazDocModul="',LazDocPackageName,'" LazDocPaths="',LazDocPaths,'" ']);
    MessageDlg('No valid lazdoc path',
      LazDocPackageName+' does not have any valid lazdoc path.'#13
      +'Unable to create the fpdoc file for '+SrcFilename,mtError,[mbCancel],0);
  finally
    PkgList.Free;
  end;
end;

function TLazDocManager.CreateFPDocFile(const ExpandedFilename,
  PackageName, ModuleName: string): TCodeBuffer;
var
  Doc: TXMLDocument;
  DescrNode: TDOMElement;
  ms: TMemoryStream;
  s: string;
  ModuleNode: TDOMElement;
  PackageNode: TDOMElement;
begin
  Result:=nil;
  if FileExistsCached(ExpandedFilename) then begin
    Result:=CodeToolBoss.LoadFile(ExpandedFilename,true,false);
    exit;
  end;
  Result:=CodeToolBoss.CreateFile(ExpandedFilename);
  if Result=nil then begin
    MessageDlg('Unable to create file',
      'Unable to create file '+ExpandedFilename,mtError,[mbCancel],0);
    exit;
  end;
  
  Doc:=nil;
  ms:=nil;
  try
    Doc:=TXMLDocument.Create;
    // <fpdoc-descriptions>
    DescrNode:=Doc.CreateElement('fpdoc-descriptions');
    Doc.AppendChild(DescrNode);
    //   <package name="packagename">
    PackageNode:=Doc.CreateElement('package');
    PackageNode.SetAttribute('name',PackageName);
    DescrNode.AppendChild(PackageNode);
    //   <module name="unitname">
    ModuleNode:=Doc.CreateElement('module');
    ModuleNode.SetAttribute('name',ModuleName);
    PackageNode.AppendChild(ModuleNode);
    // write the XML to a string
    ms:=TMemoryStream.Create;
    WriteXMLFile(Doc,ms);
    ms.Position:=0;
    SetLength(s,ms.Size);
    if s<>'' then
      ms.Read(s[1],length(s));
    // copy to codebuffer
    //DebugLn(['TLazDocManager.CreateFPDocFile ',s]);
    Result.Source:=s;
    // save file
    if SaveCodeBuffer(Result)<>mrOk then
      Result:=nil;
  finally
    ms.Free;
    Doc.Free;
  end;
end;

constructor TLazDocManager.Create;
begin
  FDocs:=TAvgLvlTree.Create(@CompareLazFPDocFilenames);
  FSrcToDocMap:=TAvgLvlTree.Create(@CompareLDSrc2DocSrcFilenames);
  FDeclarationCache:=TDeclarationInheritanceCache.Create(
                                  @CodeToolBoss.FindDeclarationAndOverload,
                                  @CodeToolBoss.GetCodeTreeNodesDeletedStep);
end;

destructor TLazDocManager.Destroy;
begin
  ClearSrcToDocMap;
  FreeDocs;
  FreeAndNil(FDocs);
  FreeAndNil(FSrcToDocMap);
  FreeAndNil(FDeclarationCache);
  inherited Destroy;
end;

function TLazDocManager.FindFPDocFile(const Filename: string): TLazFPDocFile;
var
  Node: TAvgLvlTreeNode;
begin
  Node:=FDocs.FindKey(Pointer(Filename),@CompareAnsistringWithLazFPDocFile);
  if Node<>nil then
    Result:=TLazFPDocFile(Node.Data)
  else
    Result:=nil;
end;

function TLazDocManager.LoadFPDocFile(const Filename: string; UpdateFromDisk,
  Revert: Boolean; out ADocFile: TLazFPDocFile; out CacheWasUsed: boolean): Boolean;
var
  MemStream: TMemoryStream;
begin
  Result:=false;
  CacheWasUsed:=true;
  ADocFile:=FindFPDocFile(Filename);
  if ADocFile=nil then begin
    ADocFile:=TLazFPDocFile.Create;
    ADocFile.Filename:=Filename;
    FDocs.Add(ADocFile);
  end;
  ADocFile.CodeBuffer:=CodeToolBoss.LoadFile(Filename,UpdateFromDisk,Revert);
  if ADocFile.CodeBuffer=nil then begin
    DebugLn(['TLazDocForm.LoadFPDocFile unable to load "',Filename,'"']);
    FreeAndNil(ADocFile.Doc);
    exit;
  end;
  if (ADocFile.Doc<>nil) then begin
    if (ADocFile.ChangeStep=ADocFile.CodeBuffer.ChangeStep) then begin
      // CodeBuffer has not changed
      if ADocFile.DocModified and Revert then begin
        // revert the modifications => rebuild the Doc from the CodeBuffer
      end else begin
        // no update needed
        exit(true);
      end;
    end;
  end;
  CacheWasUsed:=false;
  
  {$IFDEF VerboseLazDoc}
  DebugLn(['TLazDocManager.LoadFPDocFile parsing ',ADocFile.Filename]);
  {$ENDIF}
  CallDocChangeEvents(ldmhDocChanging,ADocFile);

  // parse XML
  ADocFile.ChangeStep:=ADocFile.CodeBuffer.ChangeStep;
  ADocFile.DocModified:=false;
  FreeAndNil(ADocFile.Doc);

  MemStream:=TMemoryStream.Create;
  try
    ADocFile.CodeBuffer.SaveToStream(MemStream);
    MemStream.Position:=0;
    Result:=false;
    ReadXMLFile(ADocFile.Doc, MemStream);
    Result:=true;
  finally
    if not Result then
      FreeAndNil(ADocFile.Doc);
    MemStream.Free;
    CallDocChangeEvents(ldmhDocChanging,ADocFile);
  end;
end;

function TLazDocManager.SaveFPDocFile(ADocFile: TLazFPDocFile): TModalResult;
var
  ms: TMemoryStream;
  s: string;
begin
  if (not ADocFile.DocModified)
  and (ADocFile.ChangeStep=ADocFile.CodeBuffer.ChangeStep)
  and (not ADocFile.CodeBuffer.FileOnDiskNeedsUpdate) then begin
    DebugLn(['TLazDocManager.SaveFPDocFile no save needed: ',ADocFile.Filename]);
    exit(mrOk);
  end;
  if (ADocFile.Doc=nil) then begin
    DebugLn(['TLazDocManager.SaveFPDocFile no Doc: ',ADocFile.Filename]);
    exit(mrOk);
  end;
  if not FilenameIsAbsolute(ADocFile.Filename) then begin
    DebugLn(['TLazDocManager.SaveFPDocFile no expanded filename: ',ADocFile.Filename]);
    exit(mrCancel);
  end;

  // write Doc to xml stream
  try
    ms:=TMemoryStream.Create;
    WriteXMLFile(ADocFile.Doc, ms);
    ms.Position:=0;
    SetLength(s,ms.Size);
    if s<>'' then
      ms.Read(s[1],length(s));
  finally
    ms.Free;
  end;

  // write to CodeBuffer
  ADocFile.CodeBuffer.Source:=s;
  ADocFile.DocModified:=false;
  if ADocFile.CodeBuffer.ChangeStep=ADocFile.ChangeStep then begin
    // doc was not really modified => do not save to keep file date
    DebugLn(['TLazDocManager.SaveFPDocFile Doc was not really modified ',ADocFile.Filename]);
    exit(mrOk);
  end;
  ADocFile.ChangeStep:=ADocFile.CodeBuffer.ChangeStep;
  
  // write to disk
  Result:=SaveCodeBuffer(ADocFile.CodeBuffer);
  DebugLn(['TLazDocManager.SaveFPDocFile saved ',ADocFile.Filename]);
end;

function TLazDocManager.GetFPDocFilenameForHelpContext(
  Context: TPascalHelpContextList; out CacheWasUsed: boolean): string;
var
  i: Integer;
  SrcFilename: String;
begin
  Result:='';
  CacheWasUsed:=true;
  if Context=nil then exit;
  for i:=0 to Context.Count-1 do begin
    if Context.Items[i].Descriptor<>pihcFilename then continue;
    SrcFilename:=Context.Items[i].Context;
    Result:=GetFPDocFilenameForSource(SrcFilename,true,CacheWasUsed);
    exit;
  end;
end;

function TLazDocManager.GetFPDocFilenameForSource(SrcFilename: string;
  ResolveIncludeFiles: Boolean; out CacheWasUsed: boolean;
  CreateIfNotExists: boolean): string;
var
  FPDocName: String;
  SearchPath: String;
  
  procedure AddSearchPath(Paths: string; const BaseDir: string);
  begin
    if Paths='' then exit;
    if not IDEMacros.CreateAbsoluteSearchPath(Paths,BaseDir) then exit;
    if Paths='' then exit;
    SearchPath:=SearchPath+';'+Paths;
  end;
  
  procedure CheckUnitOwners(CheckSourceDirectories: boolean);
  var
    PkgList: TFPList;
    i: Integer;
    APackage: TLazPackage;
    BaseDir: String;
    AProject: TLazProject;
  begin
    if not FilenameIsAbsolute(SrcFilename) then exit;
    
    if CheckSourceDirectories then begin
      PkgList:=PackageEditingInterface.GetPossibleOwnersOfUnit(SrcFilename,[]);
    end else begin
      PkgList:=PackageEditingInterface.GetOwnersOfUnit(SrcFilename);
    end;
    // get all packages owning the file
    if PkgList=nil then exit;
    try
      for i:=0 to PkgList.Count-1 do begin
        if TObject(PkgList[i]) is TLazProject then begin
          AProject:=TLazProject(PkgList[i]);
          if AProject.LazDocPaths='' then continue;
          BaseDir:=ExtractFilePath(AProject.ProjectInfoFile);
          if BaseDir='' then continue;
          // add lazdoc paths of project
          AddSearchPath(AProject.LazDocPaths,BaseDir);
        end else if TObject(PkgList[i]) is TLazPackage then begin
          APackage:=TLazPackage(PkgList[i]);
          if APackage.LazDocPaths='' then continue;
          BaseDir:=APackage.Directory;
          if BaseDir='' then continue;
          // add lazdoc paths of package
          AddSearchPath(APackage.LazDocPaths,BaseDir);
        end;
      end;
    finally
      PkgList.Free;
    end;
  end;
  
  procedure CheckIfInLazarus;
  var
    LazDir: String;
  begin
    if not FilenameIsAbsolute(SrcFilename) then exit;
    LazDir:=AppendPathDelim(EnvironmentOptions.LazarusDirectory);
    // check LCL
    if FileIsInPath(SrcFilename,LazDir+'lcl') then begin
      AddSearchPath(SetDirSeparators('docs/xml/lcl'),LazDir);
    end;
  end;

var
  CodeBuf: TCodeBuffer;
  AVLNode: TAvgLvlTreeNode;
  MapEntry: TLDSourceToFPDocFile;
begin
  Result:='';
  CacheWasUsed:=true;
  
  if ResolveIncludeFiles then begin
    CodeBuf:=CodeToolBoss.FindFile(SrcFilename);
    if CodeBuf<>nil then begin
      CodeBuf:=CodeToolBoss.GetMainCode(CodeBuf);
      if CodeBuf<>nil then begin
        SrcFilename:=CodeBuf.Filename;
      end;
    end;
  end;
  
  if not FilenameIsPascalSource(SrcFilename) then begin
    DebugLn(['TLazDocManager.GetFPDocFilenameForSource error: not a source file: "',SrcFilename,'"']);
    exit;
  end;
  
  try
    // first try cache
    MapEntry:=nil;
    AVLNode:=FSrcToDocMap.FindKey(Pointer(SrcFilename),
                                  @CompareAnsistringWithLDSrc2DocSrcFile);
    if AVLNode<>nil then begin
      MapEntry:=TLDSourceToFPDocFile(AVLNode.Data);
      if (MapEntry.FPDocFilenameTimeStamp=CompilerParseStamp)
      and (MapEntry.FilesTimeStamp=FileStateCache.TimeStamp) then begin
        Result:=MapEntry.FPDocFilename;
        exit;
      end;
    end;
    CacheWasUsed:=false;

    {$IFDEF VerboseLazDoc}
    DebugLn(['TLazDocManager.GetFPDocFilenameForSource searching SrcFilename=',SrcFilename]);
    {$ENDIF}

    // first check if the file is owned by any project/package
    SearchPath:='';
    CheckUnitOwners(false);// first check if file is owned by a package/project
    CheckUnitOwners(true);// then check if the file is in a source directory of a package/project
    CheckIfInLazarus;

    // finally add the default paths
    AddSearchPath(EnvironmentOptions.LazDocPaths,'');
    FPDocName:=lowercase(ExtractFileNameOnly(SrcFilename))+'.xml';
    {$IFDEF VerboseLazDoc}
    DebugLn(['TLazDocManager.GetFPDocFilenameForSource Search ',FPDocName,' in "',SearchPath,'"']);
    {$ENDIF}
    Result:=SearchFileInPath(FPDocName,'',SearchPath,';',ctsfcAllCase);

    // save to cache
    if MapEntry=nil then begin
      MapEntry:=TLDSourceToFPDocFile.Create;
      MapEntry.SourceFilename:=SrcFilename;
      FSrcToDocMap.Add(MapEntry);
    end;
    MapEntry.FPDocFilename:=Result;
    MapEntry.FPDocFilenameTimeStamp:=CompilerParseStamp;
    MapEntry.FilesTimeStamp:=FileStateCache.TimeStamp;
  finally
    if (Result='') and CreateIfNotExists then begin
      Result:=DoCreateFPDocFileForSource(SrcFilename);
    end;
    {$IFDEF VerboseLazDoc}
    DebugLn(['TLazDocManager.GetFPDocFilenameForSource SrcFilename="',SrcFilename,'" Result="',Result,'"']);
    {$ENDIF}
  end;
end;

function TLazDocManager.CodeNodeToElementName(Tool: TFindDeclarationTool;
  CodeNode: TCodeTreeNode): string;
var
  NodeName: String;
begin
  Result:='';
  while CodeNode<>nil do begin
    case CodeNode.Desc of
    ctnVarDefinition, ctnConstDefinition, ctnTypeDefinition, ctnGenericType:
      NodeName:=Tool.ExtractDefinitionName(CodeNode);
    ctnProperty:
      NodeName:=Tool.ExtractPropName(CodeNode,false);
    ctnProcedure:
      NodeName:=Tool.ExtractProcName(CodeNode,[]);
    else NodeName:='';
    end;
    if NodeName<>'' then begin
      if Result<>'' then
        Result:='.'+Result;
      Result:=NodeName+Result;
    end;
    CodeNode:=CodeNode.Parent;
  end;
end;

function TLazDocManager.GetFPDocNode(Tool: TCodeTool; CodeNode: TCodeTreeNode;
  Complete: boolean; out FPDocFile: TLazFPDocFile; out DOMNode: TDOMNode;
  out CacheWasUsed: boolean): TLazDocParseResult;
var
  SrcFilename: String;
  FPDocFilename: String;
  ElementName: String;
begin
  FPDocFile:=nil;
  DOMNode:=nil;
  CacheWasUsed:=true;
  
  // find corresponding FPDoc file
  SrcFilename:=Tool.MainFilename;
  FPDocFilename:=GetFPDocFilenameForSource(SrcFilename,false,CacheWasUsed);
  if FPDocFilename='' then exit(ldprFailed);
  if (not CacheWasUsed) and (not Complete) then exit(ldprParsing);

  // load FPDoc file
  if not LoadFPDocFile(FPDocFilename,true,false,FPDocFile,CacheWasUsed) then
    exit(ldprFailed);
  if (not CacheWasUsed) and (not Complete) then exit(ldprParsing);

  // find FPDoc node
  ElementName:=CodeNodeToElementName(Tool,CodeNode);
  if ElementName='' then exit(ldprFailed);
  DOMNode:=FPDocFile.GetElementWithName(ElementName);
  if DOMNode=nil then exit(ldprFailed);
  
  Result:=ldprSuccess;
end;

function TLazDocManager.GetDeclarationChain(Code: TCodeBuffer; X, Y: integer;
  out ListOfPCodeXYPosition: TFPList; out CacheWasUsed: boolean
  ): TLazDocParseResult;
begin
  if FDeclarationCache.FindDeclarations(Code,X,Y,ListOfPCodeXYPosition,
    CacheWasUsed)
  then
    Result:=ldprSuccess
  else
    Result:=ldprFailed;
end;

function TLazDocManager.GetCodeContext(CodePos: PCodeXYPosition; out
  FindContext: TFindContext; Complete: boolean; out CacheWasUsed: boolean
  ): TLazDocParseResult;
var
  CurTool: TCodeTool;
  CleanPos: integer;
  Node: TCodeTreeNode;
begin
  Result:=ldprFailed;
  FindContext:=CleanFindContext;
  CacheWasUsed:=true;

  //DebugLn(['TLazDocManager.GetElementChain i=',i,' X=',CodePos^.X,' Y=',CodePos^.Y]);
  if (CodePos=nil) or (CodePos^.Code=nil) or (CodePos^.X<1) or (CodePos^.Y<1)
  then begin
    DebugLn(['TLazDocManager.GetElementChain invalid CodePos']);
    exit;
  end;

  // build CodeTree and find node
  if not CodeToolBoss.Explore(CodePos^.Code,CurTool,false,true) then begin
    DebugLn(['TLazDocManager.GetElementChain note: there was a parser error']);
  end;
  if CurTool=nil then begin
    DebugLn(['TLazDocManager.GetElementChain explore failed']);
    exit;
  end;
  if CurTool.CaretToCleanPos(CodePos^,CleanPos)<>0 then begin
    DebugLn(['TLazDocManager.GetElementChain invalid CodePos']);
    exit;
  end;

  Node:=CurTool.FindDeepestNodeAtPos(CleanPos,false);
  if Node=nil then begin
    DebugLn(['TLazDocManager.GetElementChain node not found']);
    exit;
  end;

  // use only definition nodes
  if (Node.Desc=ctnProcedureHead)
  and (Node.Parent<>nil) and (Node.Parent.Desc=ctnProcedure) then
    Node:=Node.Parent;
  if not (Node.Desc in
    (AllIdentifierDefinitions+[ctnProperty,ctnProcedure,ctnEnumIdentifier]))
  then begin
    DebugLn(['TLazDocManager.GetElementChain ignoring node ',Node.DescAsString]);
    exit;
  end;
  if (CurTool.NodeIsForwardDeclaration(Node)) then begin
    DebugLn(['TLazDocManager.GetElementChain ignoring forward']);
    exit;
  end;
  
  // success
  FindContext.Tool:=CurTool;
  FindContext.Node:=Node;
  Result:=ldprSuccess;
end;

function TLazDocManager.GetElementChain(Code: TCodeBuffer; X, Y: integer;
  Complete: boolean; out Chain: TLazDocElementChain; out CacheWasUsed: boolean
  ): TLazDocParseResult;
var
  ListOfPCodeXYPosition: TFPList;
  i: Integer;
  CodePos: PCodeXYPosition;
  LDElement: TLazDocElement;
  SrcFilename: String;
  FPDocFilename: String;
  FindContext: TFindContext;
begin
  Chain:=nil;
  ListOfPCodeXYPosition:=nil;
  try
    //DebugLn(['TLazDocManager.GetElementChain GetDeclarationChain...']);
    // get the declaration chain
    Result:=GetDeclarationChain(Code,X,Y,ListOfPCodeXYPosition,CacheWasUsed);
    if Result<>ldprSuccess then exit;
    if (not CacheWasUsed) and (not Complete) then exit(ldprParsing);
    
    {$IFDEF VerboseLazDoc}
    DebugLn(['TLazDocManager.GetElementChain init the element chain: ListOfPCodeXYPosition.Count=',ListOfPCodeXYPosition.Count,' ...']);
    {$ENDIF}
    // init the element chain
    Result:=ldprParsing;
    Chain:=TLazDocElementChain.Create;
    Chain.CodePos.Code:=Code;
    Chain.MakeValid;
    Code.LineColToPosition(Y,X,Chain.CodePos.P);
    // fill the element chain
    for i:=0 to ListOfPCodeXYPosition.Count-1 do begin
      // get source position of declaration
      CodePos:=PCodeXYPosition(ListOfPCodeXYPosition[i]);
      Result:=GetCodeContext(CodePos,FindContext,Complete,CacheWasUsed);
      if Result=ldprFailed then continue; // skip invalid contexts
      if Result<>ldprSuccess then continue;
      if (not CacheWasUsed) and (not Complete) then exit(ldprParsing);

      // add element
      LDElement:=Chain.Add;
      LDElement.CodeXYPos:=CodePos^;
      LDElement.CodeContext:=FindContext;
      //DebugLn(['TLazDocManager.GetElementChain i=',i,' CodeContext=',FindContextToString(LDElement.CodeContext)]);

      // find corresponding FPDoc file
      SrcFilename:=LDElement.CodeContext.Tool.MainFilename;
      FPDocFilename:=GetFPDocFilenameForSource(SrcFilename,false,CacheWasUsed);
      //DebugLn(['TLazDocManager.GetElementChain FPDocFilename=',FPDocFilename]);
      if (not CacheWasUsed) and (not Complete) then exit(ldprParsing);

      if FPDocFilename<>'' then begin
        // load FPDoc file
        LoadFPDocFile(FPDocFilename,true,false,LDElement.FPDocFile,
                      CacheWasUsed);
        if (not CacheWasUsed) and (not Complete) then exit(ldprParsing);
      end;
    end;
    
    // get fpdoc nodes
    for i:=0 to Chain.Count-1 do begin
      LDElement:=Chain[i];
      // get fpdoc element path
      LDElement.ElementName:=CodeNodeToElementName(LDElement.CodeContext.Tool,
                                                   LDElement.CodeContext.Node);
      //DebugLn(['TLazDocManager.GetElementChain i=',i,' Element=',LDElement.ElementName]);
      // get fpdoc node
      if (LDElement.FPDocFile<>nil) and (LDElement.ElementName<>'') then begin
        LDElement.ElementNode:=
                  LDElement.FPDocFile.GetElementWithName(LDElement.ElementName);
        LDElement.ElementNodeValid:=true;
      end;
      //DebugLn(['TLazDocManager.GetElementChain ElementNode=',LDElement.ElementNode<>nil]);
    end;

    Result:=ldprSuccess;
  finally
    if Result<>ldprSuccess then
      FreeAndNil(Chain);
  end;
end;

function TLazDocManager.GetHint(Code: TCodeBuffer; X, Y: integer;
  Complete: boolean; out Hint: string; out CacheWasUsed: boolean
  ): TLazDocParseResult;
  
  function EndNow(var LastResult: TLazDocParseResult): boolean;
  begin
    if LastResult<>ldprSuccess then begin
      Result:=true;
      if Hint<>'' then
        LastResult:=ldprSuccess
      else
        LastResult:=ldprFailed;
      exit;
    end;
    if (not CacheWasUsed) and (not Complete) then begin
      Result:=true;
      LastResult:=ldprParsing;
    end;
    Result:=false;
  end;
  
var
  Chain: TLazDocElementChain;
  i: Integer;
  Item: TLazDocElement;
  NodeValues: TFPDocElementValues;
  f: TFPDocItem;
  ListOfPCodeXYPosition: TFPList;
  CodeXYPos: PCodeXYPosition;
  CommentStart: integer;
  NestedComments: Boolean;
  CommentStr: String;
  ItemAdded: Boolean;
  CommentCode: TCodeBuffer;
  j: Integer;
begin
  //DebugLn(['TLazDocManager.GetHint ',Code.Filename,' ',X,',',Y]);
  Hint:=CodeToolBoss.FindSmartHint(Code,X,Y);

  CacheWasUsed:=true;
  Chain:=nil;
  ListOfPCodeXYPosition:=nil;
  try
    //DebugLn(['TLazDocManager.GetHint GetElementChain...']);
    Result:=GetElementChain(Code,X,Y,Complete,Chain,CacheWasUsed);
    if EndNow(Result) then exit;

    if Chain<>nil then begin
      for i:=0 to Chain.Count-1 do begin
        Item:=Chain[i];
        ItemAdded:=false;
        DebugLn(['TLazDocManager.GetHint ',i,' Element=',Item.ElementName]);
        if Item.ElementNode<>nil then begin
          NodeValues:=Item.FPDocFile.GetValuesFromNode(Item.ElementNode);
          for f:=Low(TFPDocItem) to High(TFPDocItem) do
            DebugLn(['TLazDocManager.GetHint ',FPDocItemNames[f],' ',NodeValues[f]]);
          if NodeValues[fpdiShort]<>'' then begin
            Hint:=Hint+#13#13
                  +Item.ElementName+#13
                  +NodeValues[fpdiShort];
            ItemAdded:=true;
          end;
        end;
        
        // Add comments
        if CodeToolBoss.GetPasDocComments(Item.CodeXYPos.Code,
          Item.CodeXYPos.X,Item.CodeXYPos.Y,ListOfPCodeXYPosition)
        and (ListOfPCodeXYPosition<>nil) then
        begin
          NestedComments:=CodeToolBoss.GetNestedCommentsFlagForFile(
                                                  Item.CodeXYPos.Code.Filename);
          for j:=0 to ListOfPCodeXYPosition.Count-1 do begin
            CodeXYPos:=PCodeXYPosition(ListOfPCodeXYPosition[j]);
            CommentCode:=CodeXYPos^.Code;
            CommentCode.LineColToPosition(CodeXYPos^.Y,CodeXYPos^.X,CommentStart);
            if (CommentStart<1) or (CommentStart>CommentCode.SourceLength)
            then
              continue;
            CommentStr:=ExtractCommentContent(CommentCode.Source,CommentStart,
                                              NestedComments,true,true);
            if CommentStr<>'' then begin
              if not ItemAdded then begin
                Hint:=Hint+#13#13
                      +Item.ElementName+#13
                      +CommentStr;
              end else begin
                Hint:=Hint+#13
                      +CommentStr;
              end;
              ItemAdded:=true;
            end;
          end;
        end;
      end;
    end;
    Result:=ldprSuccess;
  finally
    FreeListOfPCodeXYPosition(ListOfPCodeXYPosition);
    Chain.Free;
  end;
  
  DebugLn(['TLazDocManager.GetHint END Hint="',Hint,'"']);
end;

function TLazDocManager.CreateElement(Code: TCodeBuffer; X, Y: integer;
  out Element: TLazDocElement): Boolean;
var
  CacheWasUsed: boolean;
  SrcFilename: String;
  FPDocFilename: String;
begin
  Result:=false;
  Element:=nil;
  if Code=nil then begin
    DebugLn(['TLazDocManager.CreateElement failed Code=nil']);
    exit;
  end;
  DebugLn(['TLazDocManager.CreateElement START ',Code.Filename,' ',X,',',Y]);
  
  Element:=TLazDocElement.Create;
  try
    // check if code context can have a fpdoc element
    Element.CodeXYPos.Code:=Code;
    Element.CodeXYPos.X:=X;
    Element.CodeXYPos.Y:=Y;
    if GetCodeContext(@Element.CodeXYPos,Element.CodeContext,true,
      CacheWasUsed)<>ldprSuccess then
    begin
      DebugLn(['TLazDocManager.CreateElement GetCodeContext failed for ',Code.Filename,' ',X,',',Y]);
      exit;
    end;
    Element.ElementName:=CodeNodeToElementName(Element.CodeContext.Tool,
                                               Element.CodeContext.Node);
    DebugLn(['TLazDocManager.CreateElement Element.ElementName=',Element.ElementName]);

    // find / create fpdoc file
    SrcFilename:=Element.CodeContext.Tool.MainFilename;
    FPDocFilename:=GetFPDocFilenameForSource(SrcFilename,false,CacheWasUsed,true);
    if FPDocFilename='' then begin
      // no fpdoc file
      DebugLn(['TLazDocManager.CreateElement unable to create fpdoc file for ',FPDocFilename]);
    end;
    DebugLn(['TLazDocManager.CreateElement FPDocFilename=',FPDocFilename]);

    // parse fpdoc file
    if not LoadFPDocFile(FPDocFilename,true,false,Element.FPDocFile,CacheWasUsed)
    then begin
      DebugLn(['TLazDocManager.CreateElement unable to load fpdoc file ',FPDocFilename]);
      exit;
    end;

    Element.ElementNode:=Element.FPDocFile.GetElementWithName(
                                                      Element.ElementName,true);
    Result:=Element.ElementNode<>nil;
  finally
    if not Result then
      FreeAndNil(Element);
  end;
end;

procedure TLazDocManager.FreeDocs;
var
  AVLNode: TAvgLvlTreeNode;
begin
  AVLNode:=FDocs.FindLowest;
  while AVLNode<>nil do begin
    CallDocChangeEvents(ldmhDocChanging,TLazFPDocFile(AVLNode.Data));
    AVLNode:=FDocs.FindSuccessor(AVLNode);
  end;
  FDocs.FreeAndClear;
end;

procedure TLazDocManager.ClearSrcToDocMap;
begin
  FSrcToDocMap.FreeAndClear;
end;

procedure TLazDocManager.RemoveAllHandlersOfObject(AnObject: TObject);
var
  HandlerType: TLazDocManagerHandler;
begin
  for HandlerType:=Low(TLazDocManagerHandler) to High(TLazDocManagerHandler) do
    FHandlers[HandlerType].RemoveAllMethodsOfObject(AnObject);
end;

procedure TLazDocManager.AddHandlerOnChanging(
  const OnDocChangingEvent: TLazDocChangeEvent; AsLast: boolean);
begin
  AddHandler(ldmhDocChanging,TMethod(OnDocChangingEvent),AsLast);
end;

procedure TLazDocManager.RemoveHandlerOnChanging(
  const OnDocChangingEvent: TLazDocChangeEvent);
begin
  RemoveHandler(ldmhDocChanging,TMethod(OnDocChangingEvent));
end;

procedure TLazDocManager.AddHandlerOnChanged(
  const OnDocChangedEvent: TLazDocChangeEvent; AsLast: boolean);
begin
  AddHandler(ldmhDocChanged,TMethod(OnDocChangedEvent),AsLast);
end;

procedure TLazDocManager.RemoveHandlerOnChanged(
  const OnDocChangedEvent: TLazDocChangeEvent);
begin
  RemoveHandler(ldmhDocChanged,TMethod(OnDocChangedEvent));
end;


{ TLazDocElementChain }

function TLazDocElementChain.GetCount: integer;
begin
  Result:=FItems.Count;
end;

function TLazDocElementChain.GetItems(Index: integer): TLazDocElement;
begin
  Result:=TLazDocElement(FItems[Index]);
end;

function TLazDocElementChain.Add: TLazDocElement;
begin
  Result:=TLazDocElement.Create;
  FItems.Add(Result);
end;

constructor TLazDocElementChain.Create;
begin
  FItems:=TFPList.Create;
end;

destructor TLazDocElementChain.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TLazDocElementChain.Clear;
var
  i: Integer;
begin
  for i:=0 to FItems.Count-1 do TObject(FItems[i]).Free;
  FItems.Clear;
end;

function TLazDocElementChain.IndexOfFile(AFile: TLazFPDocFile): integer;
begin
  Result:=FItems.Count-1;
  while (Result>=0) do begin
    if Items[Result].FPDocFile=AFile then exit;
    dec(Result);
  end;
end;

function TLazDocElementChain.IsValid: boolean;
begin
  Result:=(IDEChangeStep=CompilerParseStamp)
    and (CodetoolsChangeStep=CodeToolBoss.CodeTreeNodesDeletedStep);
end;

procedure TLazDocElementChain.MakeValid;
begin
  IDEChangeStep:=CompilerParseStamp;
  CodetoolsChangeStep:=CodeToolBoss.CodeTreeNodesDeletedStep;
end;

function TLazDocElementChain.DocFile: TLazFPDocFile;
begin
  Result:=nil;
  if (Count>0) then
    Result:=Items[0].FPDocFile;
end;

end.

