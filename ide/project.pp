{
 /***************************************************************************
                         project.pp  -  project utility class file
                             -------------------
                   TProject is responsible for managing a complete project.


                   Initial Revision  : Sun Mar 28 23:15:32 CST 1999


 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

}
unit project;

{$mode objfpc}{$H+}

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}

interface

uses
  Classes, SysUtils, LCLLinux, XMLCfg, LazConf, CompilerOptions, FileCtrl,
  CodeTools, Forms, Controls, EditorOptions, Dialogs, IDEProcs;

type
  //---------------------------------------------------------------------------
  TProjectBookmark = class
  private
    fCursorPos: TPoint;
    fEditorIndex: integer;
    fID: integer;
  public
    property CursorPos: TPoint read fCursorPos write fCursorPos;
    property EditorIndex: integer read fEditorIndex write fEditorIndex;
    property ID:integer read fID write fID;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; Path: string);
  end;

  TProjectBookmarkList = class
  private
    FBookmarks:TList;  // list of TProjectBookmark
    function GetBookmarks(Index:integer):TProjectBookmark;
    procedure SetBookmarks(Index:integer;  ABookmark: TProjectBookmark);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[Index:integer]:TProjectBookmark
       read GetBookmarks write SetBookmarks; default;
    function Count:integer;
    procedure Delete(Index:integer);
    procedure Clear;
    function Add(ABookmark: TProjectBookmark):integer;
    procedure DeleteAllWithEditorIndex(EditorIndex:integer);
    function IndexOfID(ID:integer):integer;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; Path: string);
  end;


  //---------------------------------------------------------------------------
  TProjectBreakPoint = class
  private
    fLineNumber: integer;
    // ToDo: conditions, active/non active ...
  public
    property LineNumber:integer read fLineNumber write fLineNumber;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; Path: string);
 end;

  TProjectBreakPointList = class
  private
    FBreakPoints:TList;  // list of TProjectBreakPoint
    function GetBreakPoints(Index:integer):TProjectBreakPoint;
    procedure SetBreakPoints(Index:integer;  ABreakPoint: TProjectBreakPoint);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[Index:integer]:TProjectBreakPoint 
       read GetBreakPoints write SetBreakPoints; default;
    function Count:integer;
    procedure Delete(Index:integer);
    procedure Clear;
    function Add(ABreakPoint: TProjectBreakPoint):integer;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; Path: string);
  end;


  //---------------------------------------------------------------------------
  TUnitInfo = class;


  TOnFileBackup = function(const FileToBackup:string; 
                           IsPartOfProject:boolean):TModalResult of object;
  TOnLoadSaveFilename = procedure(var Filename:string; Load:boolean) of object;
  TOnUnitNameChange = procedure(AnUnitInfo: TUnitInfo; 
       const OldUnitName, NewUnitName: string;  var Allowed: boolean) of object;

  //---------------------------------------------------------------------------
  TNewUnitType = (
     nuEmpty,   // no code
     nuUnit,    // unit
     nuForm,    // unit with form
     nuCustomProgram  // program
   );
    

  TUnitInfo = class(TObject)
  private
    { Variables }
    fBreakpoints: TProjectBreakPointList;
    fCursorPos: TPoint;
    fEditorIndex: integer;
    fFilename: String;
    fForm: TComponent;
    fFormName: string; // classname is always T<fFormName>
        // this attribute contains the formname even if the unit is not loaded
    fHasResources: boolean;
    fIsPartOfProject: boolean;
    fLoaded:  Boolean;  // loaded in the source editor
    fModified: boolean;
    fOnFileBackup: TOnFileBackup;
    fOnLoadSaveFilename: TOnLoadSaveFilename;
    fOnUnitNameChange: TOnUnitNameChange;
    fReadOnly:  Boolean;
    fSource: TSourceLog;
    fSyntaxHighlighter: TLazSyntaxHighlighter;
    fTopLine: integer;
    fUnitName: String;

    function GetHasResources:boolean;
    procedure SetUnitName(NewUnitName:string);
  public
    constructor Create;
    destructor Destroy; override;

    function ReadUnitSource(ReadUnitName:boolean): TModalResult;
    function WriteUnitSource: TModalResult;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; Path: string);
    procedure Clear;
    procedure CreateStartCode(NewUnitType: TNewUnitType);

    { Properties }
    property Breakpoints: TProjectBreakPointList
        read fBreakpoints write fBreakpoints;
    property CursorPos: TPoint read fCursorPos write fCursorPos;
    property EditorIndex:integer read fEditorIndex write fEditorIndex;
    property Filename: String read fFilename write fFilename;
    property Form: TComponent read fForm write fForm;
    property FormName: string read fFormName write fFormName;
    property HasResources: boolean read GetHasResources write fHasResources;
    property IsPartOfProject:boolean 
        read fIsPartOfProject write fIsPartOfProject;
    property Loaded: Boolean read fLoaded write fLoaded;
    property Modified: boolean read fModified write fModified;
    property OnFileBackup: TOnFileBackup read fOnFileBackup write fOnFileBackup;
    property OnLoadSaveFilename: TOnLoadSaveFilename
        read fOnLoadSaveFilename write fOnLoadSaveFilename;
    property OnUnitNameChange: TOnUnitNameChange
        read fOnUnitNameChange write fOnUnitNameChange;
    property ReadOnly: Boolean read fReadOnly write fReadOnly;
    property Source: TSourceLog read fSource write fSource;
    property SyntaxHighlighter: TLazSyntaxHighlighter
        read fSyntaxHighlighter write fSyntaxHighlighter;
    property TopLine: integer read fTopLine write fTopLine;
    property UnitName: String read fUnitName write SetUnitName;
  end;


  //---------------------------------------------------------------------------
  TProjectType =   // for a description see ProjectTypeDescriptions
     (ptApplication, ptProgram, ptCustomProgram); 

  TProject = class(TObject)
  private
    xmlcfg: TXMLConfig;

    { Variables }
    fActiveEditorIndexAtStart: integer;
    fBookmarks: TProjectBookmarkList;
    fCompilerOptions: TCompilerOptions;
    fIconPath: String;
    fMainUnit: Integer;  // only for ptApplication
    fModified: boolean;
    fOnFileBackup: TOnFileBackup;
    fOutputDirectory: String;
    fProjectFile: String;  // the lpi filename
    fProjectType: TProjectType;
    fTargetFileExt: String;
    fTitle: String;
    fUnitList: TList;  // list of TUnitInfo
    fUnitOutputDirectory: String;

    function GetUnits(Index:integer):TUnitInfo;
    procedure SetUnits(Index:integer; AUnitInfo: TUnitInfo);
    procedure SetProjectFile(NewProjectFilename: string);
    function OnUnitFileBackup(const Filename:string;
                              IsPartOfProject:boolean):TModalResult;
    function GetProjectInfoFile:string;
    procedure SetProjectInfoFile(NewFilename:string);
    procedure OnLoadSaveFilename(var AFilename:string; Load:boolean);
    procedure OnUnitNameChange(AnUnitInfo: TUnitInfo; 
       const OldUnitName, NewUnitName: string;  var Allowed: boolean);
  public
    constructor Create(TheProjectType: TProjectType);
    destructor Destroy; override;

    function ReadProject(LPIFilename: string): TModalResult;
    function WriteProject: TModalResult;

    property Units[Index: integer]:TUnitInfo read GetUnits write SetUnits;
    function UnitCount:integer;
    function NewUniqueUnitName:string;
    procedure AddUnit(AUnit: TUnitInfo; AddToProjectFile:boolean);
    procedure RemoveUnit(Index:integer);
    function IndexOf(AUnitInfo: TUnitInfo):integer;
    function IndexOfUnitWithName(AUnitName:string;
       OnlyProjectUnits:boolean):integer;
    function IndexOfUnitWithForm(AForm: TComponent;
       OnlyProjectUnits:boolean):integer;

    function UnitWithEditorIndex(Index:integer):TUnitInfo;
    procedure CloseEditorIndex(EditorIndex:integer);
    procedure InsertEditorIndex(EditorIndex:integer);
    procedure Clear;
    function SomethingModified: boolean;
    function AddCreateFormToProjectFile(AClassName,AName:string):boolean;
    function RemoveCreateFormFromProjectFile(AClassName,AName:string):boolean;
    function FormIsCreatedInProjectFile(AClassname,AName:string):boolean;
    function UnitIsUsed(AUnitName:string):boolean;
    function GetResourceFilename(AnUnitInfo: TUnitInfo; Index:integer):string;
    function SearchIncludeFile(AnUnitInfo: TUnitInfo; Filename:string):string;
    function SearchFile(Filename,SearchPaths,InitialDir:string):string;
    function SearchResourceFilename(AnUnitInfo: TUnitInfo):string;

    property ActiveEditorIndexAtStart: integer 
       read fActiveEditorIndexAtStart write fActiveEditorIndexAtStart;
    property Bookmarks: TProjectBookmarkList read fBookmarks write fBookmarks;
    property CompilerOptions: TCompilerOptions 
       read fCompilerOptions write fCompilerOptions;
    property IconPath: String read fIconPath write fIconPath;
    property MainUnit: Integer //this is the unit index of the program file
       read fMainUnit write fMainUnit;
    property Modified: boolean read fModified write fModified;
    property OnFileBackup: TOnFileBackup read fOnFileBackup write fOnFileBackup;
    property OutputDirectory: String read fOutputDirectory write fOutputDirectory;
    property ProjectFile: String read fProjectFile write SetProjectFile;
    property ProjectInfoFile: string
       read GetProjectInfoFile write SetProjectInfoFile;
    property ProjectType: TProjectType read fProjectType write fProjectType;
    property TargetFileExt: String read fTargetFileExt write fTargetFileExt;
    property Title: String read fTitle write fTitle;
    property UnitOutputDirectory: String
       read fUnitOutputDirectory write fUnitOutputDirectory;
  end;

const
  ResourceFileExt = '.lrs';

  ProjectTypeNames : array[TProjectType] of string = (
      'Application', 'Program', 'Custom program'
    );

  ProjectTypeDescriptions : array[TProjectType] of string = (
      // ptApplication
      'Application'#13
      +'A graphical lcl/freepascal program. The program file is '
      +'automatically maintained by lazarus.'

      // ptProgram
      ,'Program:'#13
      +'A freepascal program. The program file is automatically '
      +'maintained by lazarus.'

      // ptCustomProgram
      ,'Custom program:'#13
      +'A freepascal program.'
    );

  ProjectDefaultExt : array[TProjectType] of string = (
      '.lpr','.pp','.pp'
    );


function ProjectTypeNameToType(s:string): TProjectType;


implementation


function ProjectTypeNameToType(s:string): TProjectType;
begin
  for Result:=Low(TProjectType) to High(TProjectType) do
    if (lowercase(ProjectTypeNames[Result])=lowercase(s)) then exit;
  Result:=ptCustomProgram;
end;

{ TProjectBookmark }

procedure TProjectBookmark.SaveToXMLConfig(XMLConfig: TXMLConfig; 
  Path: string);
begin
  XMLConfig.SetValue(Path+'CursorPosX',CursorPos.X);
  XMLConfig.SetValue(Path+'CursorPosY',CursorPos.Y);
  XMLConfig.SetValue(Path+'EditorIndex',EditorIndex);
end;

procedure TProjectBookmark.LoadFromXMLConfig(XMLConfig: TXMLConfig; 
  Path: string);
begin
  CursorPos.X:=XMLConfig.GetValue(Path+'CursorPosX',0);
  CursorPos.Y:=XMLConfig.GetValue(Path+'CursorPosY',0);
  EditorIndex:=XMLConfig.GetValue(Path+'EditorIndex',-1);
end;


{ TProjectBookmarkList }

constructor TProjectBookmarkList.Create;
begin
  inherited Create;
  fBookmarks:=TList.Create;
end;

destructor TProjectBookmarkList.Destroy;
begin
  Clear;
  fBookmarks.Free;
  inherited Destroy;
end;

procedure TProjectBookmarkList.Clear;
var a:integer;
begin
  for a:=0 to fBookmarks.Count-1 do Items[a].Free;
  fBookmarks.Clear;
end;

function TProjectBookmarkList.Count:integer;
begin
  Result:=fBookmarks.Count;
end;

function TProjectBookmarkList.GetBookmarks(Index:integer):TProjectBookmark;
begin
  Result:=TProjectBookmark(fBookmarks[Index]);
end;

procedure TProjectBookmarkList.SetBookmarks(Index:integer;  
  ABookmark: TProjectBookmark);
begin
  fBookmarks[Index]:=ABookmark;
end;

function TProjectBookmarkList.IndexOfID(ID:integer):integer;
begin
  Result:=Count-1;
  while (Result>=0) and (Items[Result].ID<>ID) do dec(Result);
end;

procedure TProjectBookmarkList.Delete(Index:integer);
begin
  Items[Index].Free;
  fBookmarks.Delete(Index);
end;

procedure TProjectBookmarkList.DeleteAllWithEditorIndex(
  EditorIndex:integer);
var i:integer;
begin
  i:=Count-1;
  while (i>=0) do begin
    if Items[i].EditorIndex=EditorIndex then Delete(i);
    dec(i);
  end;
end;

function TProjectBookmarkList.Add(ABookmark: TProjectBookmark):integer;
begin
  Result:=fBookmarks.Add(ABookmark);
end;

procedure TProjectBookmarkList.SaveToXMLConfig(XMLConfig: TXMLConfig; 
  Path: string);
var a:integer;
begin
  XMLConfig.SetValue(Path+'Bookmarks/Count',Count);
  for a:=0 to Count-1 do
    Items[a].SaveToXMLConfig(XMLConfig,Path+'Bookmarks/Mark'+IntToStr(a)+'/');
end;

procedure TProjectBookmarkList.LoadFromXMLConfig(XMLConfig: TXMLConfig; 
  Path: string);
var a,NewCount:integer;
  NewBookmark:TProjectBookmark;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'Bookmarks/Count',0);
  for a:=0 to NewCount-1 do begin
    NewBookmark:=TProjectBookmark.Create;
    Add(NewBookmark);
    NewBookmark.LoadFromXMLConfig(XMLConfig,Path+'Bookmarks/Mark'+IntToStr(a)+'/');
  end;
end;


{ TProjectBreakPoint }

procedure TProjectBreakPoint.SaveToXMLConfig(XMLConfig: TXMLConfig; 
  Path: string);
begin
  XMLConfig.SetValue(Path+'LineNumber',LineNumber);
end;

procedure TProjectBreakPoint.LoadFromXMLConfig(XMLConfig: TXMLConfig; 
  Path: string);
begin
  LineNumber:=XMLConfig.GetValue(Path+'LineNumber',-1);
end;


{ TProjectBreakPointList }

constructor TProjectBreakPointList.Create;
begin
  inherited Create;
  fBreakPoints:=TList.Create;
end;

destructor TProjectBreakPointList.Destroy;
begin
  Clear;
  fBreakPoints.Free;
  inherited Destroy;
end;

procedure TProjectBreakPointList.Clear;
var a:integer;
begin
  for a:=0 to fBreakPoints.Count-1 do Items[a].Free;
  fBreakPoints.Clear;
end;

function TProjectBreakPointList.Count:integer;
begin
  Result:=fBreakPoints.Count;
end;

function TProjectBreakPointList.GetBreakPoints(Index:integer):TProjectBreakPoint;
begin
  Result:=TProjectBreakPoint(fBreakPoints[Index]);
end;

procedure TProjectBreakPointList.SetBreakPoints(Index:integer;
  ABreakPoint: TProjectBreakPoint);
begin
  fBreakPoints[Index]:=ABreakPoint;
end;

procedure TProjectBreakPointList.Delete(Index:integer);
begin
  Items[Index].Free;
  fBreakPoints.Delete(Index);
end;

function TProjectBreakPointList.Add(ABreakPoint: TProjectBreakPoint):integer;
begin
  Result:=fBreakPoints.Add(ABreakPoint);
end;

procedure TProjectBreakPointList.SaveToXMLConfig(XMLConfig: TXMLConfig; 
  Path: string);
var a:integer;
begin
  XMLConfig.SetValue(Path+'BreakPoints/Count',Count);
  for a:=0 to Count-1 do
    Items[a].SaveToXMLConfig(XMLConfig,Path+'BreakPoints/Point'+IntToStr(a)+'/');
end;

procedure TProjectBreakPointList.LoadFromXMLConfig(XMLConfig: TXMLConfig; 
  Path: string);
var a,NewCount:integer;
  NewBreakPoint:TProjectBreakPoint;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'BreakPoints/Count',0);
  for a:=0 to NewCount-1 do begin
    NewBreakPoint:=TProjectBreakPoint.Create;
    Add(NewBreakPoint);
    NewBreakPoint.LoadFromXMLConfig(XMLConfig
      ,Path+'BreakPoints/Point'+IntToStr(a)+'/');
  end;
end;


{------------------------------------------------------------------------------
                              TUnitInfo Class
 ------------------------------------------------------------------------------}

{------------------------------------------------------------------------------
  TUnitInfo Constructor
 ------------------------------------------------------------------------------}
constructor TUnitInfo.Create;
begin
  inherited Create;
  Assert(False, 'Project Unit Info Class Created');
  fSource := TSourceLog.Create('');
  fBreakPoints:=TProjectBreakPointList.Create;
  Clear;
end;

{------------------------------------------------------------------------------
  TUnitInfo Destructor
 ------------------------------------------------------------------------------}
destructor TUnitInfo.Destroy;
begin
  fBreakPoints.Free;
  fSource.Free;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  TUnitInfo WriteUnitSource
 ------------------------------------------------------------------------------}
function TUnitInfo.WriteUnitSource: TModalResult;
var
  ACaption:string;
  AText:string;
  fs: TFileStream;
begin
  if Assigned(fOnFileBackup) then begin
    Result:=fOnFileBackup(fFilename,IsPartOfProject);
    if Result=mrAbort then exit;
  end;
  repeat
    try
      fs:=TFileStream.Create(fFilename,fmCreate);
      try
        fs.Write(Source.Source[1],Length(Source.Source));
      finally
        fs.Free;
      end;
    except
      ACaption:='Write error';
      AText:='Unable to write file "'+fFilename+'"!';
      Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
         ,MB_ABORTRETRYIGNORE);
      if Result=mrAbort then exit;
      if Result=mrIgnore then Result:=mrOk;
    end;
  until Result<>mrRetry;
  Result:=mrOk;
end;

{------------------------------------------------------------------------------
  TUnitInfo ReadUnitSource
 ------------------------------------------------------------------------------}
function TUnitInfo.ReadUnitSource(ReadUnitName:boolean): TmodalResult;
var UnitNameStart,UnitNameEnd:integer;
  ACaption:string;
  AText:string;
  fs: TFileStream;
  s: string;
begin
  repeat
    try
      fs:=TFileStream.Create(fFilename,fmOpenRead);
      try
        Setlength(s,fs.Size);
        fs.Read(s[1],Length(s));
        Source.Source:=s;
      finally
        fs.Free;
      end;
    except
      ACaption:='Read error';
      AText:='Unable to read file "'+fFilename+'"!';
      Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
         ,MB_ABORTRETRYIGNORE);
      if Result in [mrAbort,mrIgnore] then exit;
    end;
  until Result<>mrRetry;
  if ReadUnitName then
    fUnitName:=FindUnitNameInSource(Source.Source,UnitNameStart,UnitNameEnd);
  Result:=mrOk;
end;

{------------------------------------------------------------------------------
  TUnitInfo Clear
 ------------------------------------------------------------------------------}
procedure TUnitInfo.Clear;
begin
  fBreakPoints.Clear;
  fCursorPos.X := -1;
  fCursorPos.Y := -1;
  fEditorIndex := -1;
  fFilename := '';
  fForm := nil;
  fFormName := '';
  fHasResources := false;
  fIsPartOfProject := false;
  fLoaded := false;
  fModified := false;
  fReadOnly := false;
  fSource.Clear;
  fSyntaxHighlighter := lshFreePascal;
  fTopLine := -1;
  fUnitName := '';
end;


{------------------------------------------------------------------------------
  TUnitInfo SaveToXMLConfig
 ------------------------------------------------------------------------------}
procedure TUnitInfo.SaveToXMLConfig(XMLConfig: TXMLConfig; Path: string);
var AFilename:string;
begin
  XMLConfig.SetValue(Path+'CursorPos/X',fCursorPos.X);
  XMLConfig.SetValue(Path+'CursorPos/Y',fCursorPos.Y);
  XMLConfig.SetValue(Path+'EditorIndex/Value',fEditorIndex);
  AFilename:=Filename;
  if Assigned(fOnLoadSaveFilename) then
    fOnLoadSaveFilename(AFilename,false);
  XMLConfig.SetValue(Path+'Filename/Value',AFilename);
  XMLConfig.SetValue(Path+'FormName/Value',fFormName);
  XMLConfig.SetValue(Path+'HasResources/Value',fHasResources);
  XMLConfig.SetValue(Path+'IsPartOfProject/Value',fIsPartOfProject);
  XMLConfig.SetValue(Path+'Loaded/Value',fLoaded);
  XMLConfig.SetValue(Path+'ReadOnly/Value',fReadOnly);
  XMLConfig.SetValue(Path+'SyntaxHighlighter/Value'
     ,LazSyntaxHighlighterNames[fSyntaxHighlighter]);
  XMLConfig.SetValue(Path+'TopLine/Value',fTopLine);
  XMLConfig.SetValue(Path+'UnitName/Value',fUnitName);
  fBreakpoints.SaveToXMLConfig(XMLConfig,Path);
end;

{------------------------------------------------------------------------------
  TUnitInfo LoadFromXMLConfig
 ------------------------------------------------------------------------------}
procedure TUnitInfo.LoadFromXMLConfig(XMLConfig: TXMLConfig; Path: string);
var AFilename: string;
begin
  CursorPos.X:=XMLConfig.GetValue(Path+'CursorPos/X',-1);
  CursorPos.Y:=XMLConfig.GetValue(Path+'CursorPos/Y',-1);
  EditorIndex:=XMLConfig.GetValue(Path+'EditorIndex/Value',-1);
  AFilename:=XMLConfig.GetValue(Path+'Filename/Value','');
  if Assigned(fOnLoadSaveFilename) then
    fOnLoadSaveFilename(AFilename,true);
  fFilename:=AFilename;
  fFormName:=XMLConfig.GetValue(Path+'FormName/Value','');
  HasResources:=XMLConfig.GetValue(Path+'HasResources/Value',false);
  fIsPartOfProject:=XMLConfig.GetValue(Path+'IsPartOfProject/Value',false);
  fLoaded:=XMLConfig.GetValue(Path+'Loaded/Value',false);
  fReadOnly:=XMLConfig.GetValue(Path+'ReadOnly/Value',false);
  fSyntaxHighlighter:=StrToLazSyntaxHighlighter(XMLConfig.GetValue(
       Path+'SyntaxHighlighter/Value',''));
  fTopLine:=XMLConfig.GetValue(Path+'TopLine/Value',-1);
  UnitName:=XMLConfig.GetValue(Path+'UnitName/Value','');
  fBreakpoints.LoadFromXMLConfig(XMLConfig,Path);
end;

procedure TUnitInfo.SetUnitName(NewUnitName:string);
var NewIncludeFilename:string;
  IncludeStart,IncludeEnd:integer;
  Allowed:boolean;
begin
  if fUnitName<>NewUnitName then begin
    if NewUnitName<>'' then begin
      Allowed:=true;
      if Assigned(fOnUnitNameChange) then
        fOnUnitNameChange(Self,fUnitName,NewUnitName,Allowed);
      if not Allowed then exit;
      RenameUnitInSource(Source,NewUnitName);
      if FindIncludeDirective(Source.Source,'initialization',1
         ,IncludeStart,IncludeEnd) then
      begin
        NewIncludeFilename:=NewUnitName+ResourceFileExt;
        Source.Replace(IncludeStart,IncludeEnd-IncludeStart,
              '{$I '+NewIncludeFilename+'}');
      end;
      fUnitName:=NewUnitName;
      fModified:=true;
    end;
  end;
end;

procedure TUnitInfo.CreateStartCode(NewUnitType: TNewUnitType);
var ResourceFilename:string;
  NewSource: TStringList;
begin
  ResourceFilename:=fUnitName+ResourceFileExt;
  NewSource:=TStringList.Create;
  if NewUnitType in [nuForm,nuUnit] then with NewSource do begin
    Add('unit '+fUnitName+';');
    Add('');
    Add('{$mode objfpc}{$H+}');
    Add('');
    Add('interface');
    Add('');
    Add('uses');
    case NewUnitType of
     nuUnit:
      begin
        Add('  Classes, SysUtils;');
        Add('');
        Add('implementation');
      end;
     nuForm:
      begin
        Add('  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LResources;');
        Add('');
        Add('type');
        Add('  T'+fFormName+' = class(TForm)');
        Add('  private');
        Add('    { private declarations }');
        Add('  public');
        Add('    { public declarations }');
        Add('  end;');
        Add('');
        Add('var');
        Add('  '+fFormName+': T'+fFormName+';');
        Add('');
        Add('implementation');
        Add('');
        Add('initialization');
        Add('  {$I '+ResourceFilename+'}');
      end;
    end;
    Add('');
    Add('end.');
    Add('');
  end else if NewUnitType in [nuCustomProgram] then with NewSource do begin
    Add('program CustomProgram;');
    Add('');
    Add('{$mode objfpc}{$H+}');
    Add('');
    Add('uses');
    Add('  Classes, SysUtils;');
    Add('');
    Add('begin');
    Add('end.');
    Add('');
  end;
  Source.Source:=NewSource.Text;
  NewSource.Free;
  fModified:=true;
end;

function TUnitInfo.GetHasResources:boolean;
begin
  Result:=fHasResources or (FormName<>'');
end;
  

{------------------------------------------------------------------------------
                              TProject Class
 ------------------------------------------------------------------------------}

{------------------------------------------------------------------------------
  TProject Constructor
 ------------------------------------------------------------------------------}
constructor TProject.Create(TheProjectType: TProjectType);
var PrgUnitInfo: TUnitInfo;
  NewSource: TStringList;
begin
  inherited Create;

  Assert(False, 'Trace:Project Class Created');
  XMLCfg := nil;

  fProjectType:=TheProjectType;

  fActiveEditorIndexAtStart := -1;
  fBookmarks := TProjectBookmarkList.Create;
  fCompilerOptions := TCompilerOptions.Create;
  fIconPath := '';
  fMainUnit := -1;
  fModified := false;
  fOutputDirectory := '.';
  fProjectFile := '';
  fTargetFileExt := '';
  fTitle := '';
  fUnitList := TList.Create;  // list of TUnitInfo
  fUnitOutputDirectory := '.';

  // create program source
  NewSource:=TStringList.Create;
  case fProjectType of
   ptProgram, ptApplication, ptCustomProgram:
    begin
      PrgUnitInfo:=TUnitInfo.Create;
      PrgUnitInfo.IsPartOfProject:=true;
      PrgUnitInfo.SyntaxHighlighter:=
        ExtensionToLazSyntaxHighlighter(ProjectDefaultExt[fProjectType]);
      AddUnit(PrgUnitInfo,false);
      MainUnit:=0;
      with NewSource do begin
        Add('program Project1;');
        Add('');
        Add('{$mode objfpc}{$H+}');
        Add('');
        Add('uses');
        case fProjectType of
          ptProgram, ptCustomProgram:  Add('  Classes;');
          ptApplication:  Add('  Forms;');
        else
          Add('  { add your units here };');
        end;
        Add('');
        Add('begin');
        case fProjectType of
         ptApplication:
          begin
            Add('  Application.Initialize;');
            Add('  Application.Run;');
         end;
        end;
        Add('end.');
        Add('');
      end;
      Units[MainUnit].Source.Source:=NewSource.Text;
    end;
  end;
  NewSource.Free;
end;

{------------------------------------------------------------------------------
  TProject Destructor
 ------------------------------------------------------------------------------}
destructor TProject.Destroy;
begin
  Clear;
  fBookmarks.Free;
  if (XMLCfg <> nil) then XMLCfg.Free;
  fUnitList.Free;
  fCompilerOptions.Free;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  TProject WriteProject
 ------------------------------------------------------------------------------}
function TProject.WriteProject: TModalResult;
var
  confPath: String;
  i: Integer;
  AText, ACaption: string;
begin
  Result := mrCancel;

  confPath := ChangeFileExt(ProjectFile,'.lpi');
  if Assigned(fOnFileBackup) then begin
    Result:=fOnFileBackup(confPath,true);
    if Result=mrAbort then exit;
  end;
  xmlcfg := TXMLConfig.Create(SetDirSeparators(confPath));

  try
    repeat
      try
        xmlcfg.SetValue('ProjectOptions/General/ProjectType/Value',
            ProjectTypeNames[ProjectType]);
        xmlcfg.SetValue('ProjectOptions/General/MainUnit/Value', MainUnit);
        xmlcfg.SetValue('ProjectOptions/General/ActiveEditorIndexAtStart/Value'
            ,ActiveEditorIndexAtStart);
        xmlcfg.SetValue('ProjectOptions/General/IconPath/Value', IconPath);
        xmlcfg.SetValue('ProjectOptions/General/TargetFileExt/Value'
            ,TargetFileExt);
        xmlcfg.SetValue('ProjectOptions/General/Title/Value', Title);
        xmlcfg.SetValue('ProjectOptions/General/OutputDirectory/Value'
            ,OutputDirectory);
        xmlcfg.SetValue('ProjectOptions/General/UnitOutputDirectory/Value'
            ,UnitOutputDirectory);
        fBookmarks.SaveToXMLConfig(xmlcfg,'ProjectOptions/');

        // Set options for each Unit
        xmlcfg.SetValue('ProjectOptions/Units/Count',UnitCount);
        for i := 0 to UnitCount - 1 do begin
          Units[i].SaveToXMLConfig(
            xmlcfg,'ProjectOptions/Units/Unit'+IntToStr(i)+'/');
        end;

        // Save the compiler options
        CompilerOptions.XMLConfigFile := xmlcfg;
        CompilerOptions.ProjectFile := confPath;
        CompilerOptions.SaveCompilerOptions(true);

        xmlcfg.Flush;
        Modified:=false;
      except
        ACaption:='Write error';
        AText:='Unable to write to file "'+confPath+'".';
        Result:=Application.MessageBox(PChar(ACaption),PChar(AText),MB_ABORTRETRYIGNORE);
        if Result=mrIgnore then Result:=mrOk;
        if Result=mrAbort then exit;
      end;
    until Result<>mrRetry;
  finally
    xmlcfg.Free;
    xmlcfg:=nil;
  end;
  Result := mrOk;
end;

{------------------------------------------------------------------------------
  TProject ReadProject
 ------------------------------------------------------------------------------}
function TProject.ReadProject(LPIFilename: string): TModalResult;
var
  NewUnitInfo: TUnitInfo;
  NewUnitCount,i: integer;
begin
writeln('TProject.ReadProject 1');
  Result := mrCancel;
  Clear;

  ProjectInfoFile:=LPIFilename;
writeln('TProject.ReadProject 2 ',LPIFilename);
  try
    xmlcfg := TXMLConfig.Create(ProjectInfoFile);
  except
    MessageDlg('Unable to read the project info file "'+ProjectInfoFile+'".'
        ,mtError,[mbOk],0);
    Result:=mrCancel;
    exit;
  end;

  try
    ProjectType := ProjectTypeNameToType(xmlcfg.GetValue(
       'ProjectOptions/General/ProjectType/Value', ''));
    MainUnit := xmlcfg.GetValue('ProjectOptions/General/MainUnit/Value', -1);
    ActiveEditorIndexAtStart := xmlcfg.GetValue(
       'ProjectOptions/General/ActiveEditorIndexAtStart/Value', -1);
    IconPath := xmlcfg.GetValue('ProjectOptions/General/IconPath/Value', './');
    TargetFileExt := xmlcfg.GetValue(
       'ProjectOptions/General/TargetFileExt/Value', '');
    Title := xmlcfg.GetValue('ProjectOptions/General/Title/Value', '');
    OutputDirectory := xmlcfg.GetValue(
       'ProjectOptions/General/OutputDirectory/Value', '.');
    UnitOutputDirectory := xmlcfg.GetValue(
       'ProjectOptions/General/UnitOutputDirectory/Value', '.');
    fBookmarks.LoadFromXMLConfig(xmlcfg,'ProjectOptions/');

    NewUnitCount:=xmlcfg.GetValue('ProjectOptions/Units/Count',0);
    for i := 0 to NewUnitCount - 1 do begin
      NewUnitInfo:=TUnitInfo.Create;
      AddUnit(NewUnitInfo,false);
      NewUnitInfo.LoadFromXMLConfig(
         xmlcfg,'ProjectOptions/Units/Unit'+IntToStr(i)+'/');
//writeln('NewUnitInfo: ',NewUnitInfo.Filename,', ',NewUnitInfo.EditorIndex);
    end;

    // Load the compiler options
    CompilerOptions.XMLConfigFile := xmlcfg;
    CompilerOptions.ProjectFile := ProjectFile;
    CompilerOptions.LoadCompilerOptions(true);

  finally
    xmlcfg.Free;
    xmlcfg:=nil;
  end;

  Result := mrOk;
writeln('TProject.ReadProject end');
end;

{------------------------------------------------------------------------------
  TProject AddUnit
 ------------------------------------------------------------------------------}
procedure TProject.AddUnit(AUnit: TUnitInfo; AddToProjectFile:boolean);
var ShortUnitName:string;
  UnitNameStart,UnitNameEnd:integer;
begin
  if (AUnit = nil) then exit;
  fUnitList.Add(AUnit);
  AUnit.OnFileBackup:=@OnUnitFileBackup;
  AUnit.OnLoadSaveFilename:=@OnLoadSaveFilename;
  AUnit.OnUnitNameChange:=@OnUnitNameChange;

  if AddToProjectFile and (MainUnit>=0) then begin
    // add unit to uses section
    ShortUnitName:=FindUnitNameInSource(AUnit.Source.Source,
       UnitNameStart,UnitNameEnd);
    if ShortUnitName='' then ShortUnitName:=AUnit.UnitName;
    if (ShortUnitName<>'') then
      AddToProgramUsesSection(Units[MainUnit].Source,ShortUnitName,'');
  end;
  Modified:=true;
end;

{------------------------------------------------------------------------------
  TProject RemoveUnit
 ------------------------------------------------------------------------------}
procedure TProject.RemoveUnit(Index: integer);
var
  OldUnitInfo: TUnitInfo;
begin
  if (Index<0) or (Index>=UnitCount) then begin
    writeln('ERROR: TProject.RemoveUnit index out of bounds');
    Halt;
  end;
  if (Index=MainUnit) then begin
    writeln('ERROR: TProject.RemoveUnit index = MainUnit');
    Halt;
  end;
  OldUnitInfo:=Units[Index];
  Modified:=true;

  if MainUnit>=0 then begin
    // remove unit from uses section and from createforms in program file
    if OldUnitInfo.UnitName<>'' then
      RemoveFromProgramUsesSection(Units[MainUnit].Source,OldUnitInfo.UnitName);
    if (OldUnitInfo.FormName<>'') and (RemoveCreateFormFromProjectFile(
        'T'+OldUnitInfo.FormName,OldUnitInfo.FormName)) then
      Units[MainUnit].Source.Modified:=true;
  end;

  // delete bookmarks on this unit
  if OldUnitInfo.EditorIndex>=0 then begin
    Bookmarks.DeleteAllWithEditorIndex(OldUnitInfo.EditorIndex);
  end;

  // delete unitinfo instance
  OldUnitInfo.Free;
  fUnitList.Delete(Index);
end;

{------------------------------------------------------------------------------
  TProject Clear
 ------------------------------------------------------------------------------}
procedure TProject.Clear;
var i:integer;
begin
  if XMLCfg<>nil then XMLCfg.Free;
  XMLCfg:=nil;

  for i:=0 to UnitCount-1 do Units[i].Free;
  fUnitList.Clear;

  fActiveEditorIndexAtStart := -1;
  fBookmarks.Clear;
  fCompilerOptions.Clear;
  fIconPath := '';
  fMainUnit := -1;
  fModified := false;
  fOutputDirectory := '.';
  fProjectFile := '';
  fTargetFileExt := '';
  fTitle := '';
  fUnitOutputDirectory := '.';
end;

function TProject.GetUnits(Index:integer):TUnitInfo;
begin
  Result:=TUnitInfo(fUnitList[Index]);
end;

procedure TProject.SetUnits(Index:integer; AUnitInfo: TUnitInfo);
begin
  fUnitList[Index]:=AUnitInfo;
  Modified:=true;
end;

function TProject.UnitCount:integer;
begin
  Result:=fUnitList.Count;
end;

function TProject.NewUniqueUnitName:string;

  function ExpandedUnitname(AnUnitName:string):string;
  var s:string;
  begin
    if ExtractFilePath(AnUnitName)<>'' then
      Result:=AnUnitName
    else begin
      s:=ExtractFilePath(fProjectFile);
      if s<>'' then
        Result:=s+AnUnitName
      else
        Result:=GetCurrentDir+OSDirSeparator+AnUnitName;
    end;
    Result:=lowercase(ChangeFileExt(Result,''));
  end;

  function UnitNameExists(AnUnitName:string):boolean;
  var i:integer;
    ExpName:string;
  begin
    Result:=true;
    ExpName:=ExpandedUnitName(AnUnitName);
    if ExpandedUnitname(fProjectFile)=Expname then exit;
    for i:=0 to UnitCount-1 do
      if (Units[i].UnitName<>'') and (Units[i].IsPartOfProject)
      and (ExpandedUnitName(Units[i].UnitName)=ExpName) then
        exit;
    Result:=false;
  end;

// NewUniqueUnitName
var u:integer;
begin
  u:=1;
  while (UnitNameExists('Unit'+IntToStr(u))) do inc(u);
  Result:='Unit'+IntToStr(u);
end;

function TProject.AddCreateFormToProjectFile(AClassName,AName:string):boolean;
begin
  Result:=AddCreateFormToProgram(Units[MainUnit].Source,AClassName,AName);
  if Result then Modified:=true;
end;

function TProject.RemoveCreateFormFromProjectFile(
  AClassName,AName:string):boolean;
begin
  Result:=RemoveCreateFormFromProgram(Units[MainUnit].Source,AClassName,AName);
  if Result then Modified:=true;
end;

function TProject.FormIsCreatedInProjectFile(AClassname,AName:string):boolean;
begin
  Result:=CreateFormExistsInProgram(Units[MainUnit].Source.Source,AClassName,AName);
end;

function TProject.IndexOfUnitWithName(AUnitName:string; 
  OnlyProjectUnits:boolean):integer;
begin
  Result:=UnitCount-1;
  while (Result>=0) do begin
    if (OnlyProjectUnits and Units[Result].IsPartOfProject) 
    or (not OnlyProjectUnits) then begin
      if (lowercase(Units[Result].UnitName)=lowercase(AUnitName)) then
        exit;
    end;
    dec(Result);
  end;
end;

function TProject.IndexOfUnitWithForm(AForm: TComponent; 
  OnlyProjectUnits:boolean):integer;
begin
  Result:=UnitCount-1;
  while (Result>=0) do begin
    if (OnlyProjectUnits and Units[Result].IsPartOfProject) 
    or (not OnlyProjectUnits) then begin
      if Units[Result].Form=AForm then
        exit;
    end;
    dec(Result);
  end;
end;

function TProject.UnitWithEditorIndex(Index:integer):TUnitInfo;
var i:integer;
begin
  i:=UnitCount-1;
  while (i>=0) and (Units[i].EditorIndex<>Index) do dec(i);
  if i>=0 then 
    Result:=Units[i]
  else
    Result:=nil;
end;

function TProject.UnitIsUsed(AUnitName:string):boolean;
begin
  Result:=UnitIsUsedInSource(Units[MainUnit].Source.Source,AUnitName);
end;

function TProject.GetResourceFilename(AnUnitInfo: TUnitInfo;
  Index:integer):string;
var
  IncludeStart,IncludeEnd:integer;
  IncludeDirective,IncludeFilename:string;
begin
  // find the first include filename in the intialization section
  if FindIncludeDirective(AnUnitInfo.Source.Source,'initialization'
     ,Index,IncludeStart,IncludeEnd)
  then begin
    SplitCompilerDirective(copy(AnUnitInfo.Source.Source
           ,IncludeStart,IncludeEnd-IncludeStart)
         ,IncludeDirective,IncludeFilename);
    Result:=IncludeFilename;
  end else
    Result:='';
end;

function TProject.SearchIncludeFile(AnUnitInfo: TUnitInfo; 
  Filename:string):string;
begin
  if ExtractFileExt(Filename)='' then Filename:=Filename+'.pp';
  // search in the unit directory
  Result:=ExtractFilePath(AnUnitInfo.Filename)+Filename;
  if FileExists(Result) then exit;
  // search in all include paths
  Result:=SearchFile(Filename,CompilerOptions.IncludeFiles
      ,ExtractFilePath(AnUnitInfo.Filename));
end;

function TProject.SearchFile(Filename,SearchPaths,InitialDir:string):string;
var StartPos,EndPos:integer;
  CurPath: string;
  OldDir: string;
begin
  OldDir:=GetCurrentDir;
  SetCurrentDir(ExtractFilePath(InitialDir));
  try
    StartPos:=1;
    while StartPos<=length(SearchPaths) do begin
      EndPos:=Startpos;
      while (EndPos<=length(SearchPaths)) and (SearchPaths[EndPos]<>';') do 
        inc(EndPos);
      CurPath:=copy(SearchPaths,Startpos,EndPos-StartPos);
      if CurPath<>'' then begin
        if CurPath[length(CurPath)]<>OSDirSeparator then
          CurPath:=CurPath+OSDirSeparator;
        Result:=CurPath+Filename;
        if FileExists(Result) then exit;
      end;
      StartPos:=EndPos+1;
    end;
  finally
    SetCurrentDir(OldDir);
  end;
  Result:='';
end;

function TProject.SearchResourceFilename(AnUnitInfo: TUnitInfo):string;
var s:string;
begin
  Result:=GetResourceFilename(AnUnitInfo,1);
  if Result='' then begin
    Result:=ChangeFileExt(AnUnitInfo.Filename,ResourceFileExt);
    exit;
  end;
  if ExtractFileExt(Result)='' then Result:=Result+'.pp';
  s:=ExtractFilePath(AnUnitInfo.Filename)+Result;
  if FileExists(s) then begin
    Result:=s;
    exit;
  end;
  if Result<>'' then
    SearchIncludeFile(AnUnitInfo,Result);
  if Result='' then
    Result:=ChangeFileExt(AnUnitInfo.Filename,ResourceFileExt);
end;

function TProject.IndexOf(AUnitInfo: TUnitInfo):integer;
begin
  Result:=UnitCount-1;
  while (Result>=0) and (Units[Result]<>AUnitInfo) do dec(Result);
end;

procedure TProject.CloseEditorIndex(EditorIndex:integer);
var i:integer;
begin
  for i:=0 to UnitCount-1 do begin
    if Units[i].EditorIndex=EditorIndex then 
      Units[i].EditorIndex:=-1
    else if Units[i].EditorIndex>EditorIndex then 
      Units[i].EditorIndex:=Units[i].EditorIndex-1;
  end;
  i:=Bookmarks.Count-1;
  while (i>=0) do begin
    if (Bookmarks[i].EditorIndex=EditorIndex) then
      Bookmarks.Delete(i)
    else
      Bookmarks[i].EditorIndex:=Bookmarks[i].EditorIndex-1;
    dec(i);
  end;
  Modified:=true;
end;

procedure TProject.InsertEditorIndex(EditorIndex:integer);
var i:integer;
begin
  for i:=0 to UnitCount-1 do begin
    if Units[i].EditorIndex>=EditorIndex then 
      Units[i].EditorIndex:=Units[i].EditorIndex+1;
  end;
  i:=Bookmarks.Count-1;
  while (i>=0) do begin
    if (Bookmarks[i].EditorIndex>=EditorIndex) then
      Bookmarks[i].EditorIndex:=Bookmarks[i].EditorIndex+1;
    dec(i);
  end;
  Modified:=true;
end;

procedure TProject.SetProjectFile(NewProjectFilename: string);
var NewProgramName,Ext:string;
begin
  DoDirSeparators(NewProjectFilename);
  NewProjectFilename:=ExpandFilename(NewProjectFilename);
  if NewProjectFilename=fProjectFile then exit;
  Ext:=ExtractFileExt(NewProjectFilename);
  if ProjectType in [ptProgram, ptApplication] then begin
    // change programname in source
    NewProgramName:=ExtractFilename(NewProjectFilename);
    NewProgramName:=copy(NewProgramName,1,length(NewProgramName)-length(Ext));
    if MainUnit>=0 then
      RenameProgramInSource(Units[MainUnit].Source,NewProgramName);
  end;
  if MainUnit>=0 then begin
    Units[MainUnit].Filename:=ChangeFileExt(NewProjectFilename
       ,ProjectDefaultExt[ProjectType]);
    Units[MainUnit].Modified:=true;
  end;
  fProjectFile:=NewProjectFilename;
  Modified:=true;
end;

function TProject.OnUnitFileBackup(const Filename:string;
  IsPartOfProject:boolean):TModalResult;
begin
  if Assigned(fOnFileBackup) then
    Result:=fOnFileBackup(Filename,IsPartOfProject)
  else
    Result:=mrOk;
end;

function TProject.GetProjectInfoFile:string;
begin
  Result:=fProjectFile;
  if Result<>'' then Result:=ChangeFileExt(Result,'.lpi');
end;

procedure TProject.SetProjectInfoFile(NewFilename:string);
begin
  if NewFilename='' then exit;
  NewFilename:=ChangeFileExt(NewFilename,ProjectDefaultExt[ProjectType]);
  ProjectFile:=NewFilename;
end;

procedure TProject.OnLoadSaveFilename(var AFilename:string; Load:boolean);
var ProjectPath:string;
begin
  ProjectPath:=ExtractFilePath(ProjectFile);
  if ProjectPath='' then ProjectPath:=GetCurrentDir;
  DoDirSeparators(AFilename);
  if Load then begin
    // make filename absolute
    if not FilenameIsAbsolute(AFilename) then
      AFilename:=ProjectPath+AFilename;
  end else begin
    // try making filename relative to project file
    if FilenameIsAbsolute(AFilename) 
    and (copy(AFilename,1,length(ProjectPath))=ProjectPath) then
      AFilename:=copy(AFilename,length(ProjectPath)+1,
           length(AFilename)-length(ProjectPath));
  end;
end;

procedure TProject.OnUnitNameChange(AnUnitInfo: TUnitInfo; 
  const OldUnitName, NewUnitName: string;  var Allowed: boolean);
var i:integer;
begin
  if AnUnitInfo.IsPartOfProject then begin
    // check if no other project unit has this name
    for i:=0 to UnitCount-1 do
      if (Units[i].IsPartOfProject)
      and (Units[i]<>AnUnitInfo) and (Units[i].UnitName<>'') 
      and (lowercase(Units[i].UnitName)=lowercase(NewUnitName)) then begin
        Allowed:=false;
        exit;
      end;
    if ProjectType in [ptProgram, ptApplication] then begin
      // rename unit in program uses section
      RenameUnitInProgramUsesSection(Units[MainUnit].Source
        ,OldUnitName,NewUnitName,'');
    end;
  end;
end;

function TProject.SomethingModified: boolean;
var i: integer;
begin
  Result:=Modified;
  for i:=0 to UnitCount-1 do Result:=Result or Units[i].Modified;
end;

end.



{
  $Log$
  Revision 1.23  2001/05/27 11:52:00  lazarus
  MG: added --primary-config-path=<filename> cmd line option

  Revision 1.20  2001/04/04 13:55:35  lazarus
  MG: finished TComponentPropertyEditor, added OnModified to oi, cfe and designer

  Revision 1.19  2001/04/04 12:20:34  lazarus
  MG: added  add to/remove from project, small bugfixes

  Revision 1.18  2001/03/29 12:38:59  lazarus
  MG: new environment opts, ptApplication bugfixes

  Revision 1.17  2001/03/26 14:52:30  lazarus
  MG: TSourceLog + compiling bugfixes

  Revision 1.16  2001/03/19 14:00:47  lazarus
  MG: fixed many unreleased DC and GDIObj bugs

  Revision 1.15  2001/03/09 17:54:45  lazarus

  Fixed error in Windows section of OnLoadSaveFilename - missing ')'

  Revision 1.14  2001/03/09 11:38:20  lazarus
  auto load last project

  Revision 1.10  2001/03/03 11:06:15  lazarus
  added project support, codetools

  Revision 1.8  2001/02/22 17:04:57  lazarus
  added environment options + killed ide unit circles

  Revision 1.7  2001/02/08 06:08:13  lazarus
  Began adding code to save project to the output directory. Added TODO
  comments and cleaned up some of the code.                            CAW

  Revision 1.6  2001/01/31 13:03:33  lazarus
  Commitng source with new editor.
  Shane

  Revision 1.5  2001/01/31 06:28:41  lazarus
  Removed global unit.
  Renamed TProjectUnitInfo to TUnitInfo.
  Added Source property to both TUnitInfo and TProject to hold source code
    for units and project.
  Added functions to load and save units to TUnitInfo.
  Added code to save and load units when a project is saved and loaded.  CAW

  Revision 1.4  2001/01/29 05:42:41  lazarus
  Created new TProjectUnitInfo class.
  Created new TProject class. Saves to XML config file.
  Moved compiler options to write to the project file.            CAW

  Revision 1.3  2001/01/04 20:33:53  lazarus
  Moved lresources.
  Moved CreateLFM to Main.pp
  Changed Form1 and TFOrm1 to MainIDE and TMainIDE
  Shane

  Revision 1.2  2000/12/19 18:43:13  lazarus
  Removed IDEEDITOR.  This causes the PROJECT class to not function.
  Saving projects no longer works.

  I added TSourceNotebook and TSourceEditor.  They do all the work for saving/closing/opening units.  Somethings work but they are in early development.
  Shane

  Revision 1.1  2000/07/13 10:27:48  michael
  + Initial import

  Revision 1.14  2000/07/09 20:18:55  lazarus
  MWE:
    + added new controlselection
    + some fixes
    ~ some cleanup

  Revision 1.13  2000/05/10 02:34:43  lazarus
  Changed writelns to Asserts except for ERROR and WARNING messages.   CAW

  Revision 1.12  2000/04/18 20:06:39  lazarus
  Added some functions to Compiler.pp

  Revision 1.11  2000/04/17 19:50:05  lazarus
  Added some compiler stuff built into Lazarus.
  This depends on the path to your compiler being correct in the compileroptions
  dialog.
  Shane

  Revision 1.10  2000/03/07 16:52:58  lazarus
  Fixxed a problem with the main.pp unit determining a new files FORM name.
  Shane

  Revision 1.9  2000/03/03 20:22:02  lazarus
  Trying to add TBitBtn
  Shane

  Revision 1.8  2000/03/01 21:54:05  lazarus
  90% finished with SAVE PROJECT and OPEN PROJECT
  Shane

  Revision 1.6  1999/05/14 18:44:17  lazarus
  *** empty log message ***

  Revision 1.5  1999/05/14 14:53:10  michael
  + Removed objpas from uses clause

  Revision 1.4  1999/05/14 14:39:44  michael
  All file stuff now uses sysutils. Win32 compiles

  Revision 1.3  1999/05/07 05:46:54  lazarus
  *** empty log message ***

  Revision 1.2  1999/04/28 05:29:37  lazarus
  *** empty log message ***

  Revision 1.1  1999/04/27 05:08:28  lazarus
  *** empty log message ***

  Revision 1.3  1999/04/20 02:56:42  lazarus
  *** empty log message ***

  Revision 1.2  1999/04/18 05:42:05  lazarus
  *** empty log message ***

  Revision 1.1  1999/04/14 07:31:44  michael
  + Initial implementation

}
