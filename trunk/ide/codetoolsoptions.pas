{ /***************************************************************************
                   codetoolsoptions.pas  -  Lazarus IDE unit
                   -----------------------------------------

 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

  Author: Mattias Gaertner

  Abstract:
    - TCodeToolsOptions and TCodeToolsOptsDlg
}
unit CodeToolsOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IDEProcs, LazConf, LResources, Forms, Controls, Buttons,
  ExtCtrls, StdCtrls, ComCtrls, Dialogs, XMLCfg, CodeToolManager,
  DefineTemplates, SourceChanger, EditDefineTree, SynEdit;

type
  TCodeToolsOptions = class
  private
    FFilename: string;
    
    // General
    FSrcPath: string;
    FAdjustTopLineDueToComment: boolean;
    FJumpCentered: boolean;
    FCursorBeyondEOL: boolean;

    // CodeCreation
    FLineLength: integer;
    FClassPartInsertPolicy: TClassPartInsertPolicy;
    FProcedureInsertPolicy: TProcedureInsertPolicy;
    FKeyWordPolicy : TWordPolicy;
    FIdentifierPolicy: TWordPolicy;
    FDoNotSplitLineBefore: TAtomTypes;
    FDoNotSplitLineAfter: TAtomTypes;
    FDoInsertSpaceBefore: TAtomTypes;
    FDoInsertSpaceAfter: TAtomTypes;
    FPropertyReadIdentPrefix: string;
    FPropertyWriteIdentPrefix: string;
    FPropertyStoredIdentPostfix: string;
    FPrivatVariablePrefix: string;
    FSetPropertyVariablename: string;

    procedure SetFilename(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Load;
    procedure Save;
    procedure AssignTo(Boss: TCodeToolManager);
    property Filename: string read FFilename write SetFilename;
    procedure SetLazarusDefaultFilename;
    procedure Assign(CodeToolsOpts: TCodeToolsOptions);
    function IsEqual(CodeToolsOpts: TCodeToolsOptions): boolean;
    function CreateCopy: TCodeToolsOptions;
    
    // General
    property SrcPath: string read FSrcPath write FSrcPath;
    property AdjustTopLineDueToComment: boolean
      read FAdjustTopLineDueToComment write FAdjustTopLineDueToComment;
    property JumpCentered: boolean read FJumpCentered write FJumpCentered;
    property CursorBeyondEOL: boolean
      read FCursorBeyondEOL write FCursorBeyondEOL;
    
    // CodeCreation
    property LineLength: integer read FLineLength write FLineLength;
    property ClassPartInsertPolicy: TClassPartInsertPolicy
      read FClassPartInsertPolicy write FClassPartInsertPolicy;
    property ProcedureInsertPolicy: TProcedureInsertPolicy
      read FProcedureInsertPolicy write FProcedureInsertPolicy;
    property KeyWordPolicy : TWordPolicy
      read FKeyWordPolicy write FKeyWordPolicy;
    property IdentifierPolicy: TWordPolicy
      read FIdentifierPolicy write FIdentifierPolicy;
    property DoNotSplitLineBefore: TAtomTypes
      read FDoNotSplitLineBefore write FDoNotSplitLineBefore;
    property DoNotSplitLineAfter: TAtomTypes
      read FDoNotSplitLineAfter write FDoNotSplitLineAfter;
    property DoInsertSpaceBefore: TAtomTypes
      read FDoInsertSpaceBefore write FDoInsertSpaceBefore;
    property DoInsertSpaceAfter: TAtomTypes
      read FDoInsertSpaceAfter write FDoInsertSpaceAfter;
    property PropertyReadIdentPrefix: string
      read FPropertyReadIdentPrefix write FPropertyReadIdentPrefix;
    property PropertyWriteIdentPrefix: string
      read FPropertyWriteIdentPrefix write FPropertyWriteIdentPrefix;
    property PropertyStoredIdentPostfix: string
      read FPropertyStoredIdentPostfix write FPropertyStoredIdentPostfix;
    property PrivatVariablePrefix: string
      read FPrivatVariablePrefix write FPrivatVariablePrefix;
    property SetPropertyVariablename: string
      read FSetPropertyVariablename write FSetPropertyVariablename;
  end;

  TCodeToolsOptsDlg = class(TForm)
    NoteBook: TNoteBook;
    
    // General
    SrcPathGroupBox: TGroupBox;
    SrcPathEdit: TEdit;
    JumpingGroupBox: TGroupBox;
    AdjustTopLineDueToCommentCheckBox: TCheckBox;
    JumpCenteredCheckBox: TCheckBox;
    CursorBeyondEOLCheckBox: TCheckBox;
    
    // Code Creation
    ClassPartInsertPolicyRadioGroup: TRadioGroup;
    ProcedureInsertPolicyRadioGroup: TRadioGroup;
    KeyWordPolicyRadioGroup: TRadioGroup;
    IdentifierPolicyRadioGroup: TRadioGroup;
    PropertyPrePostfixesGroupBox: TGroupBox;
    PropertyReadIdentPrefixLabel: TLabel;
    PropertyReadIdentPrefixEdit: TEdit;
    PropertyWriteIdentPrefixLabel: TLabel;
    PropertyWriteIdentPrefixEdit: TEdit;
    PropertyStoredIdentPostfixLabel: TLabel;
    PropertyStoredIdentPostfixEdit: TEdit;
    PrivatVariablePrefixLabel: TLabel;
    PrivatVariablePrefixEdit: TEdit;
    SetPropertyVariablenameLabel: TLabel;
    SetPropertyVariablenameEdit: TEdit;

    // Line Splitting
    LineLengthLabel: TLabel;
    LineLengthEdit: TEdit;
    DoNotSplitLineBeforeGroupBox: TGroupBox;
    DoNotSplitLineAfterGroupBox: TGroupBox;
    SplitPreviewGroupBox: TGroupBox;
    SplitPreviewSynEdit: TSynEdit;
    
    // Space
    DoInsertSpaceBeforeGroupBox: TGroupBox;
    DoInsertSpaceAfterGroupBox: TGroupBox;
    SpacePreviewGroupBox: TGroupBox;
    SpacePreviewSynEdit: TSynEdit;

    // Defines
    // ToDo

    // buttons at bottom
    OkButton: TButton;
    CancelButton: TButton;

    procedure FormResize(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure UpdateExamples(Sender: TObject);
  private
    FOnGetSynEditSettings: TNotifyEvent;
    BeautifyCodeOptions: TBeautifyCodeOptions;
    procedure SetupGeneralPage;
    procedure SetupCodeCreationPage;
    procedure SetupLineSplittingPage;
    procedure SetupSpacePage;
    procedure SetupDefinesPage;
    procedure CreateAtomCheckBoxes(ParentGroupBox: TGroupBox;
      AtomTypes: TAtomTypes; Columns: integer);
    procedure SetAtomCheckBoxes(AtomTypes: TAtomTypes;
      ParentGroupBox: TGroupBox);
    function ReadAtomCheckBoxes(ParentGroupBox: TGroupBox): TAtomTypes;
    procedure UpdateSinglePreviewSettings(APreview: TSynEdit);
    procedure WriteBeautifyCodeOptions(Options: TBeautifyCodeOptions);
    procedure UpdateSplitLineExample;
    procedure UpdateSpaceExample;
  public
    procedure ReadSettings(Options: TCodeToolsOptions);
    procedure WriteSettings(Options: TCodeToolsOptions);
    procedure UpdatePreviewSettings;
    constructor Create(AnOwner:TComponent);  override;
    destructor Destroy; override;
    property OnGetSynEditSettings: TNotifyEvent
      read FOnGetSynEditSettings write FOnGetSynEditSettings;
  end;

var CodeToolsOpts: TCodeToolsOptions;

function ShowCodeToolsOptions(Options: TCodeToolsOptions;
  OnGetSynEditSettings: TNotifyEvent): TModalResult;


implementation


const
  CodeToolsOptionsVersion = 1;
  DefaultCodeToolsOptsFile = 'codetoolsoptions.xml';
  
  AtomTypeDescriptions: array[TAtomType] of shortstring = (
      'None', 'Keyword', 'Identifier', 'Colon', 'Semicolon', 'Comma', 'Point',
      'At', 'Number', 'String constant', 'Newline', 'Space', 'Symbol'
    );
  DoNotSplitAtoms = [atKeyword, atIdentifier, atColon, atSemicolon, atComma,
               atPoint, atAt, atNumber, atStringConstant, atSpace, atSymbol];
  DoInsertSpaceAtoms = [atKeyword, atIdentifier, atColon, atSemicolon, atComma,
               atPoint, atAt, atNumber, atStringConstant, atSymbol];

  LineSplitExampleText =
       'function(Sender: TObject; const Val1, Val2, Val3:char; '
      +'var Var1, Var2: array of const): integer;'#13
      +'const s=''abc''#13#10+''xyz'';';
  SpaceExampleText =
       'function(Sender:TObject;const Val1,Val2,Val3:char;'
      +'var Var1,Var2:array of const):integer;'#13
      +'const s=''abc''#13#10+''xyz'';'#13
      +'begin'#13
      +'  A:=@B.C;D:=3;'#13
      +'end;';

function AtomTypeDescriptionToType(const s: string): TAtomType;
begin
  for Result:=Low(TAtomType) to High(TAtomType) do begin
    if s=AtomTypeDescriptions[Result] then exit;
  end;
  Result:=atNone;
end;

function ReadAtomTypesFromXML(XMLConfig: TXMLConfig; const Path: string;
  DefaultValues: TAtomTypes): TAtomTypes;
var a: TAtomType;
begin
  Result:=[];
  for a:=Low(TAtomType) to High(TAtomType) do begin
    if (a<>atNone)
    and (XMLConfig.GetValue(Path+AtomTypeNames[a]+'/Value',a in DefaultValues))
    then
      Include(Result,a);
  end;
end;

procedure WriteAtomTypesToXML(XMLConfig: TXMLConfig; const Path: string;
  NewValues: TAtomTypes);
var a: TAtomType;
begin
  for a:=Low(TAtomType) to High(TAtomType) do begin
    if (a<>atNone) then
      XMLConfig.SetValue(Path+AtomTypeNames[a]+'/Value',a in NewValues);
  end;
end;


function IsIdentifier(const s: string): boolean;
var i: integer;
begin
  Result:=false;
  if (s='') then exit;
  for i:=1 to length(s) do begin
    if not (s[i] in ['_','A'..'Z','a'..'z']) then exit;
  end;
  Result:=true;
end;

function ReadIdentifier(
  const s, DefaultIdent: string): string;
begin
  if IsIdentifier(s) then
    Result:=s
  else
    Result:=DefaultIdent;
end;

{ TCodeToolsOptions }

constructor TCodeToolsOptions.Create;
begin
  inherited Create;
  FFilename:='';
  Clear;
end;

destructor TCodeToolsOptions.Destroy;
begin

  inherited Destroy;
end;

procedure TCodeToolsOptions.Load;
var
  XMLConfig: TXMLConfig;
  FileVersion: integer;
begin
  try
    XMLConfig:=TXMLConfig.Create(FFileName);
    FileVersion:=XMLConfig.GetValue('CodeToolsOptions/Version/Value',0);
    if FileVersion<CodeToolsOptionsVersion then
      writeln('Note: loading old codetools options file: ',FFileName);

    // General
    FSrcPath:=XMLConfig.GetValue('CodeToolsOptions/SrcPath/Value','');
    FAdjustTopLineDueToComment:=XMLConfig.GetValue(
      'CodeToolsOptions/AdjustTopLineDueToComment/Value',true);
    FJumpCentered:=XMLConfig.GetValue('CodeToolsOptions/JumpCentered/Value',
      true);
    FCursorBeyondEOL:=XMLConfig.GetValue(
      'CodeToolsOptions/CursorBeyondEOL/Value',true);
    
    // CodeCreation
    FLineLength:=XMLConfig.GetValue(
      'CodeToolsOptions/LineLengthXMLConfig/Value',80);
    FClassPartInsertPolicy:=ClassPartPolicyNameToPolicy(XMLConfig.GetValue(
      'CodeToolsOptions/ClassPartInsertPolicy/Value','Last'));
    FProcedureInsertPolicy:=ProcedureInsertPolicyNameToPolicy(XMLConfig.GetValue(
      'CodeToolsOptions/ProcedureInsertPolicy/Value','Last'));
    FKeyWordPolicy:=WordPolicyNameToPolicy(XMLConfig.GetValue(
      'CodeToolsOptions/KeyWordPolicy/Value','LowerCase'));
    FIdentifierPolicy:=WordPolicyNameToPolicy(XMLConfig.GetValue(
      'CodeToolsOptions/IdentifierPolicy/Value','None'));
    FDoNotSplitLineBefore:=ReadAtomTypesFromXML(XMLConfig,
      'CodeToolsOptions/DoNotSplitLineBefore/',DefaultDoNotSplitLineBefore);
    FDoNotSplitLineAfter:=ReadAtomTypesFromXML(XMLConfig,
      'CodeToolsOptions/DoNotSplitLineAfter/',DefaultDoNotSplitLineAfter);
    FDoInsertSpaceBefore:=ReadAtomTypesFromXML(XMLConfig,
      'CodeToolsOptions/DoInsertSpaceBefore/',DefaultDoInsertSpaceBefore);
    FDoInsertSpaceAfter:=ReadAtomTypesFromXML(XMLConfig,
      'CodeToolsOptions/DoInsertSpaceAfter/',DefaultDoInsertSpaceAfter);
    FPropertyReadIdentPrefix:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/PropertyReadIdentPrefix/Value',''),'Get');
    FPropertyWriteIdentPrefix:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/PropertyWriteIdentPrefix/Value',''),'Set');
    FPropertyStoredIdentPostfix:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/PropertyStoredIdentPostfix/Value',''),'IsStored');
    FPrivatVariablePrefix:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/PrivatVariablePrefix/Value',''),'F');
    FSetPropertyVariablename:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/SetPropertyVariablename/Value',''),'AValue');

    XMLConfig.Free;

  except
    // ToDo
    writeln('[TCodeToolsOptions.Load]  error reading "',FFilename,'"');
  end;
end;

procedure TCodeToolsOptions.Save;
var
  XMLConfig: TXMLConfig;
begin
  try
    XMLConfig:=TXMLConfig.Create(FFileName);
    XMLConfig.SetValue('EnvironmentOptions/Version/Value',
      CodeToolsOptionsVersion);

    // General
    XMLConfig.SetValue('CodeToolsOptions/SrcPath/Value',FSrcPath);
    XMLConfig.SetValue('CodeToolsOptions/AdjustTopLineDueToComment/Value',
      FAdjustTopLineDueToComment);
    XMLConfig.SetValue('CodeToolsOptions/JumpCentered/Value',FJumpCentered);
    XMLConfig.SetValue('CodeToolsOptions/CursorBeyondEOL/Value',
      FCursorBeyondEOL);

    // CodeCreation
    XMLConfig.SetValue(
      'CodeToolsOptions/LineLengthXMLConfig/Value',FLineLength);
    XMLConfig.SetValue('CodeToolsOptions/ClassPartInsertPolicy/Value',
      ClassPartInsertPolicyNames[FClassPartInsertPolicy]);
    XMLConfig.SetValue('CodeToolsOptions/ProcedureInsertPolicy/Value',
      ProcedureInsertPolicyNames[FProcedureInsertPolicy]);
    XMLConfig.SetValue('CodeToolsOptions/KeyWordPolicy/Value',
      WordPolicyNames[FKeyWordPolicy]);
    XMLConfig.SetValue('CodeToolsOptions/IdentifierPolicy/Value',
      WordPolicyNames[FIdentifierPolicy]);
    WriteAtomTypesToXML(XMLConfig,'CodeToolsOptions/DoNotSplitLineBefore/',
      FDoNotSplitLineBefore);
    WriteAtomTypesToXML(XMLConfig,'CodeToolsOptions/DoNotSplitLineAfter/',
      FDoNotSplitLineAfter);
    WriteAtomTypesToXML(XMLConfig,'CodeToolsOptions/DoInsertSpaceBefore/',
      FDoInsertSpaceBefore);
    WriteAtomTypesToXML(XMLConfig,'CodeToolsOptions/DoInsertSpaceAfter/',
      FDoInsertSpaceAfter);
    XMLConfig.SetValue('CodeToolsOptions/PropertyReadIdentPrefix/Value',
      FPropertyReadIdentPrefix);
    XMLConfig.SetValue('CodeToolsOptions/PropertyWriteIdentPrefix/Value',
      FPropertyWriteIdentPrefix);
    XMLConfig.SetValue('CodeToolsOptions/PropertyStoredIdentPostfix/Value',
      FPropertyStoredIdentPostfix);
    XMLConfig.SetValue('CodeToolsOptions/PrivatVariablePrefix/Value',
      FPrivatVariablePrefix);
    XMLConfig.SetValue('CodeToolsOptions/SetPropertyVariablename/Value',
      FSetPropertyVariablename);

    XMLConfig.Flush;
    XMLConfig.Free;
  except
    // ToDo
    writeln('[TEnvironmentOptions.Save]  error writing "',FFilename,'"');
  end;
end;

procedure TCodeToolsOptions.SetFilename(const AValue: string);
begin
  FFilename:=AValue;
end;

procedure TCodeToolsOptions.SetLazarusDefaultFilename;
var
  ConfFileName: string;
begin
  ConfFileName:=SetDirSeparators(
                             GetPrimaryConfigPath+'/'+DefaultCodeToolsOptsFile);
  CopySecondaryConfigFile(DefaultCodeToolsOptsFile);
  if (not FileExists(ConfFileName)) then begin
    writeln('Note: codetools config file not found - using defaults');
  end;
  FFilename:=ConfFilename;
end;

procedure TCodeToolsOptions.Assign(CodeToolsOpts: TCodeToolsOptions);
begin
  if CodeToolsOpts<>nil then begin
    // General
    FSrcPath:=CodeToolsOpts.FSrcPath;
    FAdjustTopLineDueToComment:=CodeToolsOpts.FAdjustTopLineDueToComment;
    FJumpCentered:=CodeToolsOpts.FJumpCentered;
    FCursorBeyondEOL:=CodeToolsOpts.FCursorBeyondEOL;

    // CodeCreation
    FLineLength:=CodeToolsOpts.FLineLength;
    FClassPartInsertPolicy:=CodeToolsOpts.FClassPartInsertPolicy;
    FProcedureInsertPolicy:=CodeToolsOpts.FProcedureInsertPolicy;
    FKeyWordPolicy:=CodeToolsOpts.FKeyWordPolicy;
    FIdentifierPolicy:=CodeToolsOpts.FIdentifierPolicy;
    FDoNotSplitLineBefore:=CodeToolsOpts.FDoNotSplitLineBefore;
    FDoNotSplitLineAfter:=CodeToolsOpts.FDoNotSplitLineAfter;
    FDoInsertSpaceBefore:=CodeToolsOpts.FDoInsertSpaceBefore;
    FDoInsertSpaceAfter:=CodeToolsOpts.FDoInsertSpaceAfter;
    FPropertyReadIdentPrefix:=CodeToolsOpts.FPropertyReadIdentPrefix;
    FPropertyWriteIdentPrefix:=CodeToolsOpts.FPropertyWriteIdentPrefix;
    FPropertyStoredIdentPostfix:=CodeToolsOpts.FPropertyStoredIdentPostfix;
    FPrivatVariablePrefix:=CodeToolsOpts.FPrivatVariablePrefix;
    FSetPropertyVariablename:=CodeToolsOpts.FSetPropertyVariablename;
  end else begin
    Clear;
  end;
end;

procedure TCodeToolsOptions.Clear;
// !!! Does not reset Filename !!!
begin
  // General
  FSrcPath:='';
  FAdjustTopLineDueToComment:=true;
  FJumpCentered:=true;
  FCursorBeyondEOL:=true;

  // CodeCreation
  FLineLength:=80;
  FClassPartInsertPolicy:=cpipLast;
  FProcedureInsertPolicy:=pipClassOrder;
  FKeyWordPolicy:=wpLowerCase;
  FIdentifierPolicy:=wpNone;
  FDoNotSplitLineBefore:=DefaultDoNotSplitLineBefore;
  FDoNotSplitLineAfter:=DefaultDoNotSplitLineAfter;
  FDoInsertSpaceBefore:=DefaultDoInsertSpaceBefore;
  FDoInsertSpaceAfter:=DefaultDoInsertSpaceAfter;
  FPropertyReadIdentPrefix:='Get';
  FPropertyWriteIdentPrefix:='Set';
  FPropertyStoredIdentPostfix:='IsStored';
  FPrivatVariablePrefix:='f';
  FSetPropertyVariablename:='AValue';
end;

function TCodeToolsOptions.IsEqual(CodeToolsOpts: TCodeToolsOptions): boolean;
begin
  Result:=
    // General
        (FSrcPath=CodeToolsOpts.FSrcPath)
    and (FAdjustTopLineDueToComment=CodeToolsOpts.FAdjustTopLineDueToComment)
    and (FJumpCentered=CodeToolsOpts.FJumpCentered)
    and (FCursorBeyondEOL=CodeToolsOpts.FCursorBeyondEOL)

    // CodeCreation
    and (FLineLength=CodeToolsOpts.FLineLength)
    and (FClassPartInsertPolicy=CodeToolsOpts.FClassPartInsertPolicy)
    and (FProcedureInsertPolicy=CodeToolsOpts.FProcedureInsertPolicy)
    and (FKeyWordPolicy=CodeToolsOpts.FKeyWordPolicy)
    and (FIdentifierPolicy=CodeToolsOpts.FIdentifierPolicy)
    and (FDoNotSplitLineBefore=CodeToolsOpts.FDoNotSplitLineBefore)
    and (FDoNotSplitLineAfter=CodeToolsOpts.FDoNotSplitLineAfter)
    and (FDoInsertSpaceBefore=CodeToolsOpts.FDoInsertSpaceBefore)
    and (FDoInsertSpaceAfter=CodeToolsOpts.FDoInsertSpaceAfter)
    and (FPropertyReadIdentPrefix=CodeToolsOpts.FPropertyReadIdentPrefix)
    and (FPropertyWriteIdentPrefix=CodeToolsOpts.FPropertyWriteIdentPrefix)
    and (FPropertyStoredIdentPostfix=CodeToolsOpts.FPropertyStoredIdentPostfix)
    and (FPrivatVariablePrefix=CodeToolsOpts.FPrivatVariablePrefix)
    and (FSetPropertyVariablename=CodeToolsOpts.FSetPropertyVariablename)
   ;
end;

function TCodeToolsOptions.CreateCopy: TCodeToolsOptions;
begin
  Result:=TCodeToolsOptions.Create;
  Result.Assign(Self);
  Result.Filename:=Filename;
end;

procedure TCodeToolsOptions.AssignTo(Boss: TCodeToolManager);
begin
  // General - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SetAdditionalGlobalSrcPathToCodeToolBoss(SrcPath);
  Boss.AdjustTopLineDueToComment:=AdjustTopLineDueToComment;
  Boss.JumpCentered:=JumpCentered;
  Boss.CursorBeyondEOL:=CursorBeyondEOL;

  // CreateCode - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  with Boss.SourceChangeCache do begin
    BeautifyCodeOptions.LineLength:=LineLength;
    BeautifyCodeOptions.ClassPartInsertPolicy:=ClassPartInsertPolicy;
    BeautifyCodeOptions.ProcedureInsertPolicy:=ProcedureInsertPolicy;
    BeautifyCodeOptions.KeyWordPolicy:=KeyWordPolicy;
    BeautifyCodeOptions.IdentifierPolicy:=IdentifierPolicy;
    BeautifyCodeOptions.DoNotSplitLineBefore:=DoNotSplitLineBefore;
    BeautifyCodeOptions.DoNotSplitLineAfter:=DoNotSplitLineAfter;
    BeautifyCodeOptions.DoInsertSpaceBefore:=DoInsertSpaceBefore;
    BeautifyCodeOptions.DoInsertSpaceAfter:=DoInsertSpaceAfter;
    BeautifyCodeOptions.PropertyReadIdentPrefix:=PropertyReadIdentPrefix;
    BeautifyCodeOptions.PropertyWriteIdentPrefix:=PropertyWriteIdentPrefix;
    BeautifyCodeOptions.PropertyStoredIdentPostfix:=PropertyStoredIdentPostfix;
    BeautifyCodeOptions.PrivatVariablePrefix:=PrivatVariablePrefix;
  end;
  Boss.SetPropertyVariablename:=SetPropertyVariablename;
end;

{ TCodeToolsOptsDlg }

constructor TCodeToolsOptsDlg.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  if LazarusResources.Find(ClassName)=nil then begin
    SetBounds((Screen.Width-480) div 2,(Screen.Height-430) div 2, 485, 435);
    Caption:='CodeTools Options';

    NoteBook:=TNoteBook.Create(Self);
    with NoteBook do begin
      Name:='NoteBook';
      Parent:=Self;
      SetBounds(0,0,Self.ClientWidth,Self.ClientHeight-50);
      Pages[0]:='General';
      Pages.Add('Code Creation');
      Pages.Add('Line Splitting');
      Pages.Add('Space');
      Pages.Add('Defines');
    end;

    SetupGeneralPage;
    SetupCodeCreationPage;
    SetupLineSplittingPage;
    SetupSpacePage;
    SetupDefinesPage;

    NoteBook.Show;

    CancelButton:=TButton.Create(Self);
    with CancelButton do begin
      Name:='CancelButton';
      Parent:=Self;
      Width:=70;
      Height:=23;
      Left:=Self.ClientWidth-Width-15;
      Top:=Self.ClientHeight-Height-15;
      Caption:='Cancel';
      OnClick:=@CancelButtonClick;
      Visible:=true;
    end;

    OkButton:=TButton.Create(Self);
    with OkButton do begin
      Name:='OkButton';
      Parent:=Self;
      Width:=CancelButton.Width;
      Height:=CancelButton.Height;
      Left:=CancelButton.Left-15-Width;
      Top:=CancelButton.Top;
      Caption:='Ok';
      OnClick:=@OkButtonClick;
      Visible:=true;
    end;
  end;
  BeautifyCodeOptions:=TBeautifyCodeOptions.Create;
  UpdateExamples(Self);
end;

destructor TCodeToolsOptsDlg.Destroy;
begin
  BeautifyCodeOptions.Free;
  inherited Destroy;
end;

procedure TCodeToolsOptsDlg.SetupDefinesPage;
begin

end;

procedure TCodeToolsOptsDlg.SetupGeneralPage;
begin
  SrcPathGroupBox:=TGroupBox.Create(Self);
  with SrcPathGroupBox do begin
    Name:='SrcPathGroupBox';
    Parent:=NoteBook.Page[0];
    SetBounds(8,7,Self.ClientWidth-20,51);
    Caption:='Additional Source search path for all projects (.pp;.pas)';
    Visible:=true;
  end;
  
  SrcPathEdit:=TEdit.Create(Self);
  with SrcPathEdit do begin
    Name:='SrcPathEdit';
    Parent:=SrcPathGroupBox;
    SetBounds(5,6,Parent.ClientWidth-14,Height);
    Visible:=true;
  end;
  
  JumpingGroupBox:=TGroupBox.Create(Self);
  with JumpingGroupBox do begin
    Name:='JumpingGroupBox';
    Parent:=NoteBook.Page[0];
    SetBounds(8,SrcPathGroupBox.Top+SrcPathGroupBox.Height+7,
      SrcPathGroupBox.Width,95);
    Caption:='Jumping (e.g. Method Jumping)';
    Visible:=true;
  end;

  AdjustTopLineDueToCommentCheckBox:=TCheckBox.Create(Self);
  with AdjustTopLineDueToCommentCheckBox do begin
    Name:='AdjustTopLineDueToCommentCheckBox';
    Parent:=JumpingGroupBox;
    SetBounds(5,6,Parent.ClientWidth-10,Height);
    Caption:='Adjust top line due to comment in front';
    Visible:=true;
  end;

  JumpCenteredCheckBox:=TCheckBox.Create(Self);
  with JumpCenteredCheckBox do begin
    Name:='JumpCenteredCheckBox';
    Parent:=JumpingGroupBox;
    SetBounds(AdjustTopLineDueToCommentCheckBox.Left,
      AdjustTopLineDueToCommentCheckBox.Top+2
      +AdjustTopLineDueToCommentCheckBox.Height,
      AdjustTopLineDueToCommentCheckBox.Width,Height);
    Caption:='Center Cursor Line';
    Visible:=true;
  end;

  CursorBeyondEOLCheckBox:=TCheckBox.Create(Self);
  with CursorBeyondEOLCheckBox do begin
    Name:='CursorBeyondEOLCheckBox';
    Parent:=JumpingGroupBox;
    SetBounds(JumpCenteredCheckBox.Left,
      JumpCenteredCheckBox.Top+JumpCenteredCheckBox.Height+2,
      JumpCenteredCheckBox.Width,Height);
    Caption:='Cursor beyond EOL';
    Visible:=true;
  end;
end;

procedure TCodeToolsOptsDlg.SetupCodeCreationPage;
begin
  ClassPartInsertPolicyRadioGroup:=TRadioGroup.Create(Self);
  with ClassPartInsertPolicyRadioGroup do begin
    Name:='ClassPartInsertPolicyRadioGroup';
    Parent:=NoteBook.Page[1];
    SetBounds(8,6,
      (Self.ClientWidth div 2)-12,80);
    Caption:='Class part insert policy';
    with Items do begin
      BeginUpdate;
      Add('Alphabetically');
      Add('Last');
      EndUpdate;
    end;
    Enabled:=false;
    Visible:=true;
  end;

  ProcedureInsertPolicyRadioGroup:=TRadioGroup.Create(Self);
  with ProcedureInsertPolicyRadioGroup do begin
    Name:='ProcedureInsertPolicyRadioGroup';
    Parent:=NoteBook.Page[1];
    SetBounds(ClassPartInsertPolicyRadioGroup.Left
      +ClassPartInsertPolicyRadioGroup.Width+8,
      ClassPartInsertPolicyRadioGroup.Top,
      ClassPartInsertPolicyRadioGroup.Width,
      ClassPartInsertPolicyRadioGroup.Height);
    Caption:='Procedure insert policy';
    with Items do begin
      BeginUpdate;
      Add('Alphabetically');
      Add('Last');
      Add('Class order');
      EndUpdate;
    end;
    Enabled:=false;
    Visible:=true;
  end;

  KeyWordPolicyRadioGroup:=TRadioGroup.Create(Self);
  with KeyWordPolicyRadioGroup do begin
    Name:='KeyWordPolicyRadioGroup';
    Parent:=NoteBook.Page[1];
    SetBounds(ClassPartInsertPolicyRadioGroup.Left,
      ClassPartInsertPolicyRadioGroup.Top
       +ClassPartInsertPolicyRadioGroup.Height+7,
      (Self.ClientWidth div 2)-12,100);
    Caption:='Keyword policy';
    with Items do begin
      BeginUpdate;
      Add('None');
      Add('lowercase');
      Add('UPPERCASE');
      Add('Lowercase, first letter up');
      EndUpdate;
    end;
    OnClick:=@UpdateExamples;
    Visible:=true;
  end;

  IdentifierPolicyRadioGroup:=TRadioGroup.Create(Self);
  with IdentifierPolicyRadioGroup do begin
    Name:='IdentifierPolicyRadioGroup';
    Parent:=NoteBook.Page[1];
    SetBounds(KeyWordPolicyRadioGroup.Left+KeyWordPolicyRadioGroup.Width+8,
      KeyWordPolicyRadioGroup.Top,
      KeyWordPolicyRadioGroup.Width,KeyWordPolicyRadioGroup.Height);
    Caption:='Identifier policy';
    with Items do begin
      BeginUpdate;
      Add('None');
      Add('lowercase');
      Add('UPPERCASE');
      Add('Lowercase, first letter up');
      EndUpdate;
    end;
    OnClick:=@UpdateExamples;
    Visible:=true;
  end;
  
  PropertyPrePostfixesGroupBox:=TGroupBox.Create(Self);
  with PropertyPrePostfixesGroupBox do begin
    Name:='PropertyPrePostfixesGroupBox';
    Parent:=NoteBook.Page[1];
    SetBounds(KeyWordPolicyRadioGroup.Left,
      KeyWordPolicyRadioGroup.Top+KeyWordPolicyRadioGroup.Height+7,
      Self.ClientWidth-20,100);
    Caption:='Property completion identifiers';
    Visible:=true;
  end;

  PropertyReadIdentPrefixLabel:=TLabel.Create(Self);
  with PropertyReadIdentPrefixLabel do begin
    Name:='PropertyReadIdentPrefixLabel';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds(6,5,100,Height);
    Caption:='Read prefix';
    Visible:=true;
  end;

  PropertyReadIdentPrefixEdit:=TEdit.Create(Self);
  with PropertyReadIdentPrefixEdit do begin
    Name:='PropertyReadIdentPrefixEdit';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds(110,PropertyReadIdentPrefixLabel.Top,80,Height);
    Visible:=true;
  end;

  PropertyWriteIdentPrefixLabel:=TLabel.Create(Self);
  with PropertyWriteIdentPrefixLabel do begin
    Name:='PropertyWriteIdentPrefixLabel';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds(6,PropertyReadIdentPrefixLabel.Top
      +PropertyReadIdentPrefixLabel.Height+5,
      PropertyReadIdentPrefixLabel.Width,Height);
    Caption:='Write prefix';
    Visible:=true;
  end;

  PropertyWriteIdentPrefixEdit:=TEdit.Create(Self);
  with PropertyWriteIdentPrefixEdit do begin
    Name:='PropertyWriteIdentPrefixEdit';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds(PropertyReadIdentPrefixEdit.Left,
      PropertyWriteIdentPrefixLabel.Top,80,Height);
    Visible:=true;
  end;

  PropertyStoredIdentPostfixLabel:=TLabel.Create(Self);
  with PropertyStoredIdentPostfixLabel do begin
    Name:='PropertyStoredIdentPostfixLabel';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds(6,PropertyWriteIdentPrefixLabel.Top
      +PropertyWriteIdentPrefixLabel.Height+5,
      PropertyReadIdentPrefixLabel.Width,Height);
    Caption:='Stored postfix';
    Visible:=true;
  end;

  PropertyStoredIdentPostfixEdit:=TEdit.Create(Self);
  with PropertyStoredIdentPostfixEdit do begin
    Name:='PropertyStoredIdentPostfixEdit';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds(PropertyReadIdentPrefixEdit.Left,
      PropertyStoredIdentPostfixLabel.Top,80,Height);
    Visible:=true;
  end;

  PrivatVariablePrefixLabel:=TLabel.Create(Self);
  with PrivatVariablePrefixLabel do begin
    Name:='PrivatVariablePrefixLabel';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds((PropertyPrePostfixesGroupBox.ClientWidth-20) div 2,
      PropertyReadIdentPrefixLabel.Top,120,Height);
    Caption:='Variable prefix';
    Visible:=true;
  end;

  PrivatVariablePrefixEdit:=TEdit.Create(Self);
  with PrivatVariablePrefixEdit do begin
    Name:='PrivatVariablePrefixEdit';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds(PrivatVariablePrefixLabel.Left+150,PrivatVariablePrefixLabel.Top,
      80,Height);
    Visible:=true;
  end;

  SetPropertyVariablenameLabel:=TLabel.Create(Self);
  with SetPropertyVariablenameLabel do begin
    Name:='SetPropertyVariablenameLabel';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds(PrivatVariablePrefixLabel.Left,
      PrivatVariablePrefixLabel.Top+PrivatVariablePrefixLabel.Height+5,
      120,Height);
    Caption:='Set property Variable';
    Visible:=true;
  end;

  SetPropertyVariablenameEdit:=TEdit.Create(Self);
  with SetPropertyVariablenameEdit do begin
    Name:='SetPropertyVariablenameEdit';
    Parent:=PropertyPrePostfixesGroupBox;
    SetBounds(PrivatVariablePrefixEdit.Left,
      PrivatVariablePrefixLabel.Top+PrivatVariablePrefixLabel.Height+5,
      80,Height);
    Visible:=true;
  end;
end;

procedure TCodeToolsOptsDlg.SetupLineSplittingPage;
begin
  LineLengthLabel:=TLabel.Create(Self);
  with LineLengthLabel do begin
    Name:='LineLengthLabel';
    Parent:=NoteBook.Page[2];
    SetBounds(8,7,Canvas.TextWidth('Max line length: '),Height);
    Caption:='Max line length:';
    Visible:=true;
  end;

  LineLengthEdit:=TEdit.Create(Self);
  with LineLengthEdit do begin
    Name:='LineLengthEdit';
    Parent:=LineLengthLabel.Parent;
    Left:=LineLengthLabel.Left+LineLengthLabel.Width+5;
    Top:=LineLengthLabel.Top-2;
    Width:=50;
    OnChange:=@UpdateExamples;
    Visible:=true;
  end;

  DoNotSplitLineBeforeGroupBox:=TGroupBox.Create(Self);
  with DoNotSplitLineBeforeGroupBox do begin
    Name:='DoNotSplitLineBeforeGroupBox';
    Parent:=NoteBook.Page[2];
    SetBounds(6,LineLengthLabel.Top+LineLengthLabel.Height+7,
      (Self.ClientWidth-24) div 2,150);
    Caption:='Do not split line before:';
    CreateAtomCheckBoxes(DoNotSplitLineBeforeGroupBox,DoNotSplitAtoms,2);
    OnClick:=@UpdateExamples;
    Visible:=true;
  end;

  DoNotSplitLineAfterGroupBox:=TGroupBox.Create(Self);
  with DoNotSplitLineAfterGroupBox do begin
    Name:='DoNotSplitLineAfterGroupBox';
    Parent:=NoteBook.Page[2];
    SetBounds(DoNotSplitLineBeforeGroupBox.Left,
      DoNotSplitLineBeforeGroupBox.Top+DoNotSplitLineBeforeGroupBox.Height+7,
      DoNotSplitLineBeforeGroupBox.Width,
      DoNotSplitLineBeforeGroupBox.Height);
    Caption:='Do not split line after:';
    CreateAtomCheckBoxes(DoNotSplitLineAfterGroupBox,DoNotSplitAtoms,2);
    OnClick:=@UpdateExamples;
    Visible:=true;
  end;
  
  SplitPreviewGroupBox:=TGroupBox.Create(Self);
  with SplitPreviewGroupBox do begin
    Name:='SplitPreviewGroupBox';
    Parent:=NoteBook.Page[2];
    Left:=DoNotSplitLineBeforeGroupBox.Left+DoNotSplitLineBeforeGroupBox.Width+8;
    Top:=LineLengthLabel.Top;
    Width:=Self.ClientWidth-10-Left;
    Height:=Self.ClientHeight-92-Top;
    Caption:='Preview (Max line length = 1)';
    Visible:=true;
  end;
  
  SplitPreviewSynEdit:=TSynEdit.Create(Self);
  with SplitPreviewSynEdit do begin
    Name:='SplitPreviewSynEdit';
    Parent:=SplitPreviewGroupBox;
    SetBounds(2,2,Parent.ClientWidth-8,Parent.ClientHeight-25);
    Visible:=true;
  end;
end;

procedure TCodeToolsOptsDlg.SetupSpacePage;
begin
  DoInsertSpaceBeforeGroupBox:=TGroupBox.Create(Self);
  with DoInsertSpaceBeforeGroupBox do begin
    Name:='DoInsertSpaceBeforeGroupBox';
    Parent:=NoteBook.Page[3];
    SetBounds(6,6,
      (Self.ClientWidth-24) div 2,150);
    Caption:='Insert space before';
    CreateAtomCheckBoxes(DoInsertSpaceBeforeGroupBox,DoInsertSpaceAtoms,2);
    OnClick:=@UpdateExamples;
    Visible:=true;
  end;

  DoInsertSpaceAfterGroupBox:=TGroupBox.Create(Self);
  with DoInsertSpaceAfterGroupBox do begin
    Name:='DoInsertSpaceAfterGroupBox';
    Parent:=NoteBook.Page[3];
    SetBounds(DoInsertSpaceBeforeGroupBox.Left
      +DoInsertSpaceBeforeGroupBox.Width+8,
      DoInsertSpaceBeforeGroupBox.Top,
      DoInsertSpaceBeforeGroupBox.Width,
      DoInsertSpaceBeforeGroupBox.Height);
    Caption:='Insert space after';
    CreateAtomCheckBoxes(DoInsertSpaceAfterGroupBox,DoInsertSpaceAtoms,2);
    OnClick:=@UpdateExamples;
    Visible:=true;
  end;
  
  SpacePreviewGroupBox:=TGroupBox.Create(Self);
  with SpacePreviewGroupBox do begin
    Name:='SpacePreviewGroupBox';
    Parent:=NoteBook.Page[3];
    Left:=DoInsertSpaceBeforeGroupBox.Left;
    Top:=DoInsertSpaceBeforeGroupBox.Top+DoInsertSpaceBeforeGroupBox.Height+7;
    Width:=Self.ClientWidth-10-Left;
    Height:=Self.ClientHeight-92-Top;
    Caption:='Preview';
    Visible:=true;
  end;

  SpacePreviewSynEdit:=TSynEdit.Create(Self);
  with SpacePreviewSynEdit do begin
    Name:='SpacePreviewSynEdit';
    Parent:=SpacePreviewGroupBox;
    SetBounds(2,2,Parent.ClientWidth-8,Parent.ClientHeight-25);
    Visible:=true;
  end;
end;

procedure TCodeToolsOptsDlg.FormResize(Sender: TObject);
begin
  // ToDo
end;

procedure TCodeToolsOptsDlg.CreateAtomCheckBoxes(ParentGroupBox: TGroupBox;
  AtomTypes: TAtomTypes; Columns: integer);
var
  Count, i, yi, MaxYCount: integer;
  a: TAtomType;
  X, Y, CurX, CurY, XStep, YStep: integer;
  NewCheckBox: TCheckBox;
begin
  if Columns<1 then Columns:=1;
  Count:=0;
  for a:=Low(TAtomTypes) to High(TAtomTypes) do begin
    if a in AtomTypes then inc(Count);
  end;
  if Count=0 then exit;
  MaxYCount:=((Count+Columns-1) div Columns);
  X:=6;
  Y:=1;
  XStep:=((ParentGroupBox.ClientWidth-10) div Columns);
  YStep:=((ParentGroupBox.ClientHeight-20) div MaxYCount);
  CurX:=X;
  CurY:=Y;
  i:=0;
  yi:=0;
  for a:=Low(TAtomTypes) to High(TAtomTypes) do begin
    if a in AtomTypes then begin
      inc(i);
      inc(yi);
      NewCheckBox:=TCheckBox.Create(ParentGroupBox);
      with NewCheckBox do begin
        Name:=ParentGroupBox.Name+'CheckBox'+IntToStr(i+1);
        Parent:=ParentGroupBox;
        SetBounds(CurX,CurY,XStep-10,Height);
        Caption:=AtomTypeDescriptions[a];
        OnClick:=@UpdateExamples;
        Visible:=true;
      end;
      if yi>=MaxYCount then begin
        inc(X,XStep);
        CurX:=X;
        CurY:=Y;
        yi:=0;
      end else begin
        inc(CurY,YStep);
      end;
    end;
  end;
end;

procedure TCodeToolsOptsDlg.CancelButtonClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TCodeToolsOptsDlg.OkButtonClick(Sender: TObject);
begin
  ModalResult:=mrOk;
end;

procedure TCodeToolsOptsDlg.ReadSettings(Options: TCodeToolsOptions);
begin
  // General - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SrcPathEdit.Text:=Options.SrcPath;
  AdjustTopLineDueToCommentCheckBox.Checked:=Options.AdjustTopLineDueToComment;
  JumpCenteredCheckBox.Checked:=Options.JumpCentered;
  CursorBeyondEOLCheckBox.Checked:=Options.CursorBeyondEOL;

  // CodeCreation  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  LineLengthEdit.Text:=IntToStr(Options.LineLength);
  case Options.ClassPartInsertPolicy of
  cpipAlphabetically:
    ClassPartInsertPolicyRadioGroup.ItemIndex:=0;
  else
    // cpipLast
    ClassPartInsertPolicyRadioGroup.ItemIndex:=1;
  end;
  case Options.ProcedureInsertPolicy of
  pipAlphabetically:
    ProcedureInsertPolicyRadioGroup.ItemIndex:=0;
  pipLast:
    ProcedureInsertPolicyRadioGroup.ItemIndex:=1;
  else
    // pipClassOrder
    ProcedureInsertPolicyRadioGroup.ItemIndex:=2;
  end;
  case Options.KeyWordPolicy of
  wpLowerCase:
    KeyWordPolicyRadioGroup.ItemIndex:=1;
  wpUpperCase:
    KeyWordPolicyRadioGroup.ItemIndex:=2;
  wpLowerCaseFirstLetterUp:
    KeyWordPolicyRadioGroup.ItemIndex:=3;
  else
    // wpNone
    KeyWordPolicyRadioGroup.ItemIndex:=0;
  end;
  case Options.IdentifierPolicy of
  wpLowerCase:
    IdentifierPolicyRadioGroup.ItemIndex:=1;
  wpUpperCase:
    IdentifierPolicyRadioGroup.ItemIndex:=2;
  wpLowerCaseFirstLetterUp:
    IdentifierPolicyRadioGroup.ItemIndex:=3;
  else
    // wpNone
    IdentifierPolicyRadioGroup.ItemIndex:=0;
  end;
  SetAtomCheckBoxes(Options.DoNotSplitLineBefore,DoNotSplitLineBeforeGroupBox);
  SetAtomCheckBoxes(Options.DoNotSplitLineAfter,DoNotSplitLineAfterGroupBox);
  SetAtomCheckBoxes(Options.DoInsertSpaceBefore,DoInsertSpaceBeforeGroupBox);
  SetAtomCheckBoxes(Options.DoInsertSpaceAfter,DoInsertSpaceAfterGroupBox);
  PropertyReadIdentPrefixEdit.Text:=Options.PropertyReadIdentPrefix;
  PropertyWriteIdentPrefixEdit.Text:=Options.PropertyWriteIdentPrefix;
  PropertyStoredIdentPostfixEdit.Text:=Options.PropertyStoredIdentPostfix;
  PrivatVariablePrefixEdit.Text:=Options.PrivatVariablePrefix;
  SetPropertyVariablenameEdit.Text:=Options.SetPropertyVariablename;
end;

procedure TCodeToolsOptsDlg.WriteSettings(Options: TCodeToolsOptions);
begin
  // General - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  Options.SrcPath:=SrcPathEdit.Text;
  Options.AdjustTopLineDueToComment:=AdjustTopLineDueToCommentCheckBox.Checked;
  Options.JumpCentered:=JumpCenteredCheckBox.Checked;
  Options.CursorBeyondEOL:=CursorBeyondEOLCheckBox.Checked;

  // CodeCreation  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  Options.LineLength:=StrToIntDef(LineLengthEdit.Text,80);
  if Options.LineLength<5 then
    Options.LineLength:=5;
  case ClassPartInsertPolicyRadioGroup.ItemIndex of
  0: Options.ClassPartInsertPolicy:=cpipAlphabetically;
  1: Options.ClassPartInsertPolicy:=cpipLast;
  end;
  case ProcedureInsertPolicyRadioGroup.ItemIndex of
  0: Options.ProcedureInsertPolicy:=pipAlphabetically;
  1: Options.ProcedureInsertPolicy:=pipLast;
  2: Options.ProcedureInsertPolicy:=pipClassOrder;
  end;
  case KeyWordPolicyRadioGroup.ItemIndex of
  0: Options.KeyWordPolicy:=wpNone;
  1: Options.KeyWordPolicy:=wpLowerCase;
  2: Options.KeyWordPolicy:=wpUpperCase;
  3: Options.KeyWordPolicy:=wpLowerCaseFirstLetterUp;
  end;
  case IdentifierPolicyRadioGroup.ItemIndex of
  0: Options.IdentifierPolicy:=wpNone;
  1: Options.IdentifierPolicy:=wpLowerCase;
  2: Options.IdentifierPolicy:=wpUpperCase;
  3: Options.IdentifierPolicy:=wpLowerCaseFirstLetterUp;
  end;
  Options.DoNotSplitLineBefore:=ReadAtomCheckBoxes(DoNotSplitLineBeforeGroupBox);
  Options.DoNotSplitLineAfter:=ReadAtomCheckBoxes(DoNotSplitLineAfterGroupBox);
  Options.DoInsertSpaceBefore:=ReadAtomCheckBoxes(DoInsertSpaceBeforeGroupBox);
  Options.DoInsertSpaceAfter:=ReadAtomCheckBoxes(DoInsertSpaceAfterGroupBox);
  Options.PropertyReadIdentPrefix:=
    ReadIdentifier(PropertyReadIdentPrefixEdit.Text,'Get');
  Options.PropertyWriteIdentPrefix:=
    ReadIdentifier(PropertyWriteIdentPrefixEdit.Text,'Set');
  Options.PropertyStoredIdentPostfix:=
    ReadIdentifier(PropertyStoredIdentPostfixEdit.Text,'IsStored');
  Options.PrivatVariablePrefix:=
    ReadIdentifier(PrivatVariablePrefixEdit.Text,'F');
  Options.SetPropertyVariablename:=
    ReadIdentifier(SetPropertyVariablenameEdit.Text,'AValue');
end;

procedure TCodeToolsOptsDlg.SetAtomCheckBoxes(AtomTypes: TAtomTypes;
  ParentGroupBox: TGroupBox);
var
  i: integer;
  ACheckBox: TCheckBox;
  a: TAtomType;
begin
  for i:=0 to ParentGroupBox.ComponentCount-1 do begin
    if (ParentGroupBox.Components[i] is TCheckBox) then begin
      ACheckBox:=TCheckBox(ParentGroupBox.Components[i]);
      a:=AtomTypeDescriptionToType(ACheckBox.Caption);
      ACheckBox.Checked:=(a<>atNone) and (a in AtomTypes);
    end;
  end;
end;

function TCodeToolsOptsDlg.ReadAtomCheckBoxes(
  ParentGroupBox: TGroupBox): TAtomTypes;
var
  i: integer;
  ACheckBox: TCheckBox;
  a: TAtomType;
begin
  Result:=[];
  for i:=0 to ParentGroupBox.ComponentCount-1 do begin
    if (ParentGroupBox.Components[i] is TCheckBox) then begin
      ACheckBox:=TCheckBox(ParentGroupBox.Components[i]);
      a:=AtomTypeDescriptionToType(ACheckBox.Caption);
      if (a<>atNone) and (ACheckBox.Checked) then
        Include(Result,a);
    end;
  end;
end;

procedure TCodeToolsOptsDlg.UpdatePreviewSettings;
begin
  UpdateSinglePreviewSettings(SplitPreviewSynEdit);
  UpdateSinglePreviewSettings(SpacePreviewSynEdit);
end;

procedure TCodeToolsOptsDlg.UpdateSinglePreviewSettings(APreview: TSynEdit);
begin
  if Assigned(FOnGetSynEditSettings) then begin
    FOnGetSynEditSettings(APreview);
  end;
  APreview.Gutter.Visible:=false;
  APreview.Options:=APreview.Options+[eoNoCaret, eoNoSelection];
  APreview.ReadOnly:=true;
end;

procedure TCodeToolsOptsDlg.UpdateSplitLineExample;
begin
  if BeautifyCodeOptions=nil then exit;
  WriteBeautifyCodeOptions(BeautifyCodeOptions);
  BeautifyCodeOptions.LineLength:=1;
  SplitPreviewSynEdit.Text:=BeautifyCodeOptions.BeautifyStatement(
    LineSplitExampleText,0);
end;

procedure TCodeToolsOptsDlg.WriteBeautifyCodeOptions(
  Options: TBeautifyCodeOptions);
begin
  Options.LineLength:=StrToIntDef(LineLengthEdit.Text,80);
  if Options.LineLength<5 then
    Options.LineLength:=5;
  case ClassPartInsertPolicyRadioGroup.ItemIndex of
  0: Options.ClassPartInsertPolicy:=cpipAlphabetically;
  1: Options.ClassPartInsertPolicy:=cpipLast;
  end;
  case ProcedureInsertPolicyRadioGroup.ItemIndex of
  0: Options.ProcedureInsertPolicy:=pipAlphabetically;
  1: Options.ProcedureInsertPolicy:=pipLast;
  2: Options.ProcedureInsertPolicy:=pipClassOrder;
  end;
  case KeyWordPolicyRadioGroup.ItemIndex of
  0: Options.KeyWordPolicy:=wpNone;
  1: Options.KeyWordPolicy:=wpLowerCase;
  2: Options.KeyWordPolicy:=wpUpperCase;
  3: Options.KeyWordPolicy:=wpLowerCaseFirstLetterUp;
  end;
  case IdentifierPolicyRadioGroup.ItemIndex of
  0: Options.IdentifierPolicy:=wpNone;
  1: Options.IdentifierPolicy:=wpLowerCase;
  2: Options.IdentifierPolicy:=wpUpperCase;
  3: Options.IdentifierPolicy:=wpLowerCaseFirstLetterUp;
  end;
  Options.DoNotSplitLineBefore:=ReadAtomCheckBoxes(DoNotSplitLineBeforeGroupBox);
  Options.DoNotSplitLineAfter:=ReadAtomCheckBoxes(DoNotSplitLineAfterGroupBox);
  Options.DoInsertSpaceBefore:=ReadAtomCheckBoxes(DoInsertSpaceBeforeGroupBox);
  Options.DoInsertSpaceAfter:=ReadAtomCheckBoxes(DoInsertSpaceAfterGroupBox);
  Options.PropertyReadIdentPrefix:=
    ReadIdentifier(PropertyReadIdentPrefixEdit.Text,'Get');
  Options.PropertyWriteIdentPrefix:=
    ReadIdentifier(PropertyWriteIdentPrefixEdit.Text,'Set');
  Options.PropertyStoredIdentPostfix:=
    ReadIdentifier(PropertyStoredIdentPostfixEdit.Text,'IsStored');
  Options.PrivatVariablePrefix:=
    ReadIdentifier(PrivatVariablePrefixEdit.Text,'F');
end;

procedure TCodeToolsOptsDlg.UpdateExamples(Sender: TObject);
begin
  if Sender=nil then exit;
  UpdateSplitLineExample;
  UpdateSpaceExample;
end;

procedure TCodeToolsOptsDlg.UpdateSpaceExample;
begin
  if BeautifyCodeOptions=nil then exit;
  WriteBeautifyCodeOptions(BeautifyCodeOptions);
  BeautifyCodeOptions.LineLength:=40;
  SpacePreviewSynEdit.Text:=BeautifyCodeOptions.BeautifyStatement(
    SpaceExampleText,0);
end;

//------------------------------------------------------------------------------

function ShowCodeToolsOptions(Options: TCodeToolsOptions;
  OnGetSynEditSettings: TNotifyEvent): TModalResult;
var CodeToolsOptsDlg: TCodeToolsOptsDlg;
begin
  Result:=mrCancel;
  CodeToolsOptsDlg:=TCodeToolsOptsDlg.Create(Application);
  try
    CodeToolsOptsDlg.ReadSettings(Options);
    CodeToolsOptsDlg.OnGetSynEditSettings:=OnGetSynEditSettings;
    CodeToolsOptsDlg.UpdatePreviewSettings;
    Result:=CodeToolsOptsDlg.ShowModal;
    if Result=mrOk then begin
      CodeToolsOptsDlg.WriteSettings(Options);
      Options.AssignTo(CodeToolBoss);
      Options.Save;
    end;
  finally
    CodeToolsOptsDlg.Free;
  end;
end;

end.

