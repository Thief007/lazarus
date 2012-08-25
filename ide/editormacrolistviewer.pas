unit EditorMacroListViewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Laz2_XMLCfg, SynMacroRecorder, SynEdit, SynEditKeyCmds,
  FileProcs, Forms, Controls, Dialogs, StdCtrls, ButtonPanel, ComCtrls, ExtCtrls, Spin, Menus,
  LCLType, IDEWindowIntf, IDEImagesIntf, LazarusIDEStrConsts, ProjectDefs, LazConf, Project,
  KeyMapping, KeyMapShortCutDlg, MainIntf, SrcEditorIntf, IDEHelpIntf, IDECommands, LazIDEIntf;

type
  TSynEditorMacro = class(TSynMacroRecorder) end;

  { TIdeEditorMacro }

  TIdeEditorMacro = class(TEditorMacro)
  private
    FMacroName: String;
    FHasError: Boolean;
    FFailedText: String;
    FSynMacro: TSynEditorMacro;
    FKeyBinding: TEditorMacroKeyBinding;

    procedure DoMacroRecorderState(Sender: TObject);
    procedure DoMacroRecorderUserCommand(aSender: TCustomSynMacroRecorder;
                aCmd: TSynEditorCommand; var aEvent: TSynMacroEvent);
  protected
    function  GetMacroName: String; override;
    procedure SetMacroName(AValue: string); override;
    function  GetState: TEditorMacroState; override;
    function  GetKeyBinding: TEditorMacroKeyBinding; override;

    procedure DoRecordMacro(aEditor: TCustomSynEdit); override;
    procedure DoPlaybackMacro(aEditor: TCustomSynEdit); override;
    procedure DoStop; override;
    procedure DoPause; override;
    procedure DoResume; override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure AssignEventsFrom(AMacroRecorder: TEditorMacro); override;
    function  AddEditor(AValue: TCustomSynEdit): integer;

    procedure Clear; override;

    function  GetAsSource: String; override;
    procedure SetFromSource(const AText: String); override;
    procedure WriteToXmlConf(AConf: TXMLConfig; const APath: String); override;
    procedure ReadFromXmlConf(AConf: TXMLConfig; const APath: String); override;

    function  IsEmpty: Boolean; override;
    function  IsInvalid: Boolean; override;
    function  IsRecording(AnEditor: TCustomSynEdit): Boolean; override;
  end;


  { TIdeEditorMacroKeyBinding }

  TIdeEditorMacroKeyBinding = class(TEditorMacroKeyBinding)
  protected
    FIdeCmd: TIDECommand;
    function  GetIdeCmd: TIDECommand; override;
    procedure ExecMacro(Sender: TObject);
  public
    destructor Destroy; override;
    procedure WriteToXmlConf(AConf: TXMLConfig; const APath: String); override;
    procedure ReadFromXmlConf(AConf: TXMLConfig; const APath: String); override;
    procedure MacroNameChanged; override;
    function  ShortCutAsText: String; override;
  end;

  { TIdeMacroEventWriter }

  TIdeMacroEventWriter = class(TSynMacroEventWriter)
  private
    FText: String;
    FCmdName, FParams: String;
    FUseLineFeed: Boolean;
  public
    constructor Create;
    procedure BeginEvent;
    procedure FinishEvent;
    procedure WriteEventCommand(const ACmd: TSynEditorCommand); override;
    procedure WriteEventParam(const AParam: string); override;
    procedure WriteEventParam(const AParam: integer); override;
    property Text: String read FText;
    property UseLineFeed: Boolean read FUseLineFeed write FUseLineFeed;
  end;

  { TIdeMacroEventReader }

  TIdeMacroEventReader = class(TSynMacroEventReader)
  private
    FEventName: String;
    FHasError: Boolean;
    FText: String;
    FEventCommand: TSynEditorCommand;
    FParams: Array of record
        ParamType: TSynEventParamType;
        Text : String;
        Num: Integer;
      end;
  protected
    function GetParamAsInt(Index: Integer): Integer; override;
    function GetParamAsString(Index: Integer): String; override;
    function GetParamType(Index: Integer): TSynEventParamType; override;
  public
    constructor Create(const Atext: String);
    function  EventCommand: TSynEditorCommand; override;
    function  ParamCount: Integer; override;
    function  ParseNextEvent: Boolean;
    property  EventName: String read FEventName;
    property  HasError: Boolean read FHasError;
  end;

  { TEditorMacroList }

  TEditorMacroList = class;
  TMacroAddedEvent = procedure(AList: TEditorMacroList; AMacro: TEditorMacro) of object;

  TEditorMacroList = class
  private
    FList: TList;
    FOnAdded: TMacroAddedEvent;
    FOnChange: TNotifyEvent;
    FOnRemove: TMacroAddedEvent;
    function GetMacros(Index: Integer): TEditorMacro;
    procedure DoChanged;
    procedure DoAdded(AMacro: TEditorMacro);
    procedure DoRemove(AMacro: TEditorMacro);
  public
    constructor Create;
    destructor Destroy; override;
    procedure WriteToXmlConf(AConf: TXMLConfig; const APath: String);
    procedure ReadFromXmlConf(AConf: TXMLConfig; const APath: String);
    procedure ClearAndFreeMacros;
    function Count: Integer;
    function IndexOf(AMacro: TEditorMacro): Integer;
    function IndexOfName(AName: String): Integer;
    function UniqName(AName: String): String;
    function Add(AMacro: TEditorMacro): Integer;
    procedure Delete(AnIndex: Integer);
    procedure Remove(AMacro: TEditorMacro);
    property Macros[Index: Integer]: TEditorMacro read GetMacros;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnAdded: TMacroAddedEvent read FOnAdded write FOnAdded;
    property OnRemove: TMacroAddedEvent read FOnRemove write FOnRemove;
  end;

  { TMacroListView }

  TMacroListView = class(TForm)
    btnEdit: TButton;
    btnSetKeys: TButton;
    btnPlay: TButton;
    btnRecord: TButton;
    btnRecordStop: TButton;
    btnDelete: TButton;
    btnSelect: TButton;
    btnRename: TButton;
    ButtonPanel1: TButtonPanel;
    chkRepeat: TCheckBox;
    lbMoveTo: TLabel;
    lbRecordedView: TListView;
    mnExport: TMenuItem;
    mnImport: TMenuItem;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    pnlButtons: TPanel;
    PopupMenu1: TPopupMenu;
    RenameButton: TPanelBitBtn;
    edRepeat: TSpinEdit;
    SaveDialog1: TSaveDialog;
    ToolBar1: TToolBar;
    tbRecorded: TToolButton;
    tbProject: TToolButton;
    tbIDE: TToolButton;
    ToolBar2: TToolBar;
    tbMoveProject: TToolButton;
    tbMoveIDE: TToolButton;
    procedure btnDeleteClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure btnRecordClick(Sender: TObject);
    procedure btnRecordStopClick(Sender: TObject);
    procedure btnRenameClick(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure btnSetKeysClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
    procedure lbRecordedViewSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure mnExportClick(Sender: TObject);
    procedure mnImportClick(Sender: TObject);
    procedure tbIDEClick(Sender: TObject);
    procedure tbMoveIDEClick(Sender: TObject);
    procedure tbMoveProjectClick(Sender: TObject);
    procedure tbProjectClick(Sender: TObject);
    procedure tbRecordedClick(Sender: TObject);
  private
    FImageRec: Integer;
    FImagePlay: Integer;
    FImageSel: Integer;
    FImageErr: Integer;
    FIsPlaying: Boolean;
    procedure DoOnMacroListChange(Sender: TObject);
    procedure DoMacroStateChanged(Sender: TObject);
    procedure UpdateButtons;
  protected
    procedure DoEditorMacroStateChanged;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function  MacroByFullName(AName: String): TEditorMacro;
    procedure UpdateDisplay;
  end;

function MacroListViewer: TMacroListView;
procedure ShowMacroListViewer;
procedure UpdateMacroListViewer;
procedure DoEditorMacroStateChanged;

procedure LoadProjectSpecificInfo(XMLConfig: TXMLConfig; Merge: boolean);
procedure SaveProjectSpecificInfo(XMLConfig: TXMLConfig; Flags: TProjectWriteFlags);
procedure LoadGlobalInfo;
procedure SaveGlobalInfo;

var
  OnKeyMapReloaded: procedure of object;
  OnEditorMacroStateChange: TNotifyEvent;
  // SelectedEditorMacro: Selected, for playing with default shortcut
  SelectedEditorMacro: TEditorMacro = nil;

implementation

var
  MacroListView: TMacroListView = nil;

  CurrentEditorMacroList: TEditorMacroList = nil;
  EditorMacroListRec, EditorMacroListProj, EditorMacroListGlob: TEditorMacroList;

  // CurrentRecordingMacro:
  // The player-macro, to wich the recording in process will be assigned
  CurrentRecordingMacro: TEditorMacro = nil;

  MacroRecCounter: Integer = 1;
  KeyCategory: TIDECommandCategory = nil;

const
  GlobalConfFileName = 'EditorMacros.xml';

function MacroListViewer: TMacroListView;
begin
  if MacroListView = nil then
    MacroListView := TMacroListView.Create(Application);
  Result := MacroListView;
end;

procedure ShowMacroListViewer;
begin
  IDEWindowCreators.ShowForm(MacroListViewer, True);
end;

procedure UpdateMacroListViewer;
begin
  if MacroListView <> nil then
    MacroListView.UpdateDisplay;
end;

function MacroListToName(AList: TEditorMacroList): string;
begin
  Result := '';
  if AList = EditorMacroListRec then Result := 'Rec'
  else if AList = EditorMacroListProj then Result := 'Prj'
  else if AList = EditorMacroListGlob then Result := 'Ide';
end;

function NameToMacroList(AName: string): TEditorMacroList;
begin
  Result := nil;
  if AName = 'Rec' then Result := EditorMacroListRec
  else if AName = 'Prj' then Result := EditorMacroListProj
  else if AName = 'Ide' then Result := EditorMacroListGlob;
end;

procedure DoEditorMacroStateChanged;
begin
  if EditorMacroForRecording= nil then exit;

  if not(EditorMacroForRecording.State  in [emRecording, emRecPaused]) and
    (CurrentRecordingMacro <> nil)
  then begin
    // finished recording
    if EditorMacroForRecording.IsEmpty then begin
      EditorMacroListRec.Remove(CurrentRecordingMacro);
      FreeAndNil(CurrentRecordingMacro);
    end else begin
      CurrentRecordingMacro.AssignEventsFrom(EditorMacroForRecording);
      SelectedEditorMacro := CurrentRecordingMacro;
      CurrentRecordingMacro := nil;
    end;
  end;

  if (EditorMacroForRecording.State = emRecording) and (CurrentRecordingMacro = nil) then begin
    CurrentRecordingMacro := EditorMacroPlayerClass.Create(nil);
    CurrentRecordingMacro.OnStateChange := @MacroListViewer.DoMacroStateChanged;
    CurrentRecordingMacro.MacroName := Format(lisNewMacroName, [MacroRecCounter]);
    inc(MacroRecCounter);
    EditorMacroListRec.Add(CurrentRecordingMacro);
  end;

  if MacroListView <> nil then
    MacroListView.DoEditorMacroStateChanged;
end;

procedure LoadProjectSpecificInfo(XMLConfig: TXMLConfig; Merge: boolean);
begin
  EditorMacroListProj.ReadFromXmlConf(XMLConfig, '');
end;

procedure SaveProjectSpecificInfo(XMLConfig: TXMLConfig; Flags: TProjectWriteFlags);
begin
  if not (pwfSkipSeparateSessionInfo in Flags) then
  begin
    EditorMacroListProj.WriteToXmlConf(XMLConfig, '');
  end;
end;

procedure LoadGlobalInfo;
var
  Filename: String;
  XMLConfig: TXMLConfig;
begin
  Filename := TrimFilename(AppendPathDelim(GetPrimaryConfigPath)+GlobalConfFileName);
  XMLConfig := TXMLConfig.Create(Filename);
  EditorMacroListGlob.ReadFromXmlConf(XMLConfig, '');
  XMLConfig.Free;
end;

procedure SaveGlobalInfo;
var
  Filename: String;
  XMLConfig: TXMLConfig;
begin
  Filename := TrimFilename(AppendPathDelim(GetPrimaryConfigPath)+GlobalConfFileName);
  XMLConfig := TXMLConfig.CreateClean(Filename);
  EditorMacroListGlob.WriteToXmlConf(XMLConfig, '');
  XMLConfig.Free;
end;

{ TIdeEditorMacroKeyBinding }

function TIdeEditorMacroKeyBinding.GetIdeCmd: TIDECommand;
begin
  Result := FIdeCmd;
end;

procedure TIdeEditorMacroKeyBinding.ExecMacro(Sender: TObject);
begin
  if ActiveEditorMacro <> nil then exit;
  FOwner.PlaybackMacro(TCustomSynEdit(SourceEditorManagerIntf.ActiveEditor.EditorControl));
end;

procedure TIdeEditorMacroKeyBinding.MacroNameChanged;
begin
  if (IDECommandList = nil) then
    exit;

  if FOwner.IsInvalid then begin
    if FIdeCmd <> nil then begin
      (IDECommandList as TKeyCommandRelationList).RemoveCommand(FIdeCmd);
      FreeAndNil(FIdeCmd);
    end;
    exit;
  end;

  if KeyCategory = nil then
    KeyCategory := IDECommandList.CreateCategory(nil, 'EditorMacros',
      'Editor Macros', IDECmdScopeSrcEditOnly);

  if FIdeCmd = nil then begin
    FIdeCmd := (IDECommandList as TKeyCommandRelationList).CreateCommand(
      KeyCategory,
      'EdtMacro'+FOwner.MacroName,
      FOwner.MacroName,
      IDEShortCut(VK_UNKNOWN, [], VK_UNKNOWN, []),
      IDEShortCut(VK_UNKNOWN, [], VK_UNKNOWN, []),
      @ExecMacro, nil
    );
    (FIdeCmd as TKeyCommandRelation).SkipSaving := True;
  end
  else
    FIdeCmd.LocalizedName := FOwner.MacroName;

end;

destructor TIdeEditorMacroKeyBinding.Destroy;
begin
  inherited Destroy;
  if (FIdeCmd <> nil) and (IDECommandList <> nil) then begin
    (IDECommandList as TKeyCommandRelationList).RemoveCommand(FIdeCmd);
    FreeAndNil(FIdeCmd);
  end;
end;

procedure TIdeEditorMacroKeyBinding.WriteToXmlConf(AConf: TXMLConfig; const APath: String);
  procedure ClearKey(const SubPath: string);
  begin
    AConf.DeleteValue(SubPath+'Key1');
    AConf.DeleteValue(SubPath+'Shift1');
    AConf.DeleteValue(SubPath+'Key2');
    AConf.DeleteValue(SubPath+'Shift2');
  end;
  procedure Store(const SubPath: string; Key: TIDEShortCut);
  var
    s: TShiftState;
  begin
    AConf.SetDeleteValue(SubPath+'Key1', key.Key1, VK_UNKNOWN);
    if key.Key1=VK_UNKNOWN then
      s:=[]
    else
      s:=key.Shift1;
    AConf.SetDeleteValue(SubPath+'Shift1',ShiftStateToCfgStr(s),ShiftStateToCfgStr([]));
    AConf.SetDeleteValue(SubPath+'Key2',key.Key2,VK_UNKNOWN);
    if key.Key2=VK_UNKNOWN then
      s:=[]
    else
      s:=key.Shift2;
    AConf.SetDeleteValue(SubPath+'Shift2',ShiftStateToCfgStr(s),ShiftStateToCfgStr([]));
  end;

begin
  if (FIdeCmd = nil) then begin
    ClearKey(APath + 'KeyA/');
    ClearKey(APath + 'KeyB/');
  end else begin
    Store(APath + 'KeyA/', FIdeCmd.ShortcutA);
    Store(APath + 'KeyB/', FIdeCmd.ShortcutB);
  end;
end;

procedure TIdeEditorMacroKeyBinding.ReadFromXmlConf(AConf: TXMLConfig; const APath: String);
  procedure Load(SubPath: string; out Key: TIDEShortCut);
  begin
    key.Key1   := AConf.GetValue(SubPath+'Key1',VK_UNKNOWN);
    key.Shift1 := CfgStrToShiftState(AConf.GetValue(SubPath+'Shift1',''));
    key.Key2   := AConf.GetValue(SubPath+'Key2',VK_UNKNOWN);
    key.Shift2 := CfgStrToShiftState(AConf.GetValue(SubPath+'Shift2',''));
  end;
var
  SCut: TIDEShortCut;
begin
  if (FIdeCmd <> nil) then begin
    Load(APath+'KeyA/', SCut);
    if (IDECommandList as TKeyCommandRelationList).Find(SCut, TSourceEditorWindowInterface) = nil then
      FIdeCmd.ShortcutA := SCut;

    Load(APath+'KeyB/', SCut);
    if (IDECommandList as TKeyCommandRelationList).Find(SCut, TSourceEditorWindowInterface) = nil then
      FIdeCmd.ShortcutB := SCut;
  end;
end;

function TIdeEditorMacroKeyBinding.ShortCutAsText: String;
begin
  Result := '';
  If FIdeCmd = nil then
    exit;
  if not IDEShortCutEmpty(FIdeCmd.ShortcutA) then
    Result := Result + ' (' + KeyAndShiftStateToEditorKeyString(FIdeCmd.ShortcutA) + ')';
  if not IDEShortCutEmpty(FIdeCmd.ShortcutB) then
    Result := Result + ' (' + KeyAndShiftStateToEditorKeyString(FIdeCmd.ShortcutB) + ')';
end;

{ TIdeEditorMacro }

function TIdeEditorMacro.GetMacroName: String;
begin
  Result := FMacroName;
end;

procedure TIdeEditorMacro.DoMacroRecorderState(Sender: TObject);
begin
  if Assigned(OnStateChange) then
    OnStateChange(Sender);
  CheckStateAndActivated;
end;

procedure TIdeEditorMacro.DoMacroRecorderUserCommand(aSender: TCustomSynMacroRecorder;
  aCmd: TSynEditorCommand; var aEvent: TSynMacroEvent);
begin
  case aCmd of
    ecSynMacroPlay, ecSynMacroRecord,
    ecToggleFormUnit..ecViewThreads, ecViewHistory,
    ecNextEditor, ecPrevEditor, ecNextWindow, ecPrevWindow,
    ecGotoEditor1..ecGotoEditor0:
      aEvent := TSynSkippedEvent.Create;
    else
      ;//
  end;
end;

function TIdeEditorMacro.GetState: TEditorMacroState;
begin
  case FSynMacro.state of
    msStopped:   Result := emStopped;
    msRecording: Result := emRecording;
    msPlaying:   Result := emPlaying;
    msPaused:    Result := emRecPaused;
  end;
end;

function TIdeEditorMacro.GetKeyBinding: TEditorMacroKeyBinding;
begin
  if FKeyBinding = nil then
    FKeyBinding := GetDefaultKeyBinding;
  Result := FKeyBinding;
end;

procedure TIdeEditorMacro.SetMacroName(AValue: string);
begin
  FMacroName := AValue;
  FSynMacro.MacroName := AValue;
end;

constructor TIdeEditorMacro.Create(aOwner: TComponent);
begin
  FSynMacro := TSynEditorMacro.Create(aOwner);
  FHasError := False;

  FSynMacro.OnUserCommand   := @DoMacroRecorderUserCommand;
  FSynMacro.OnStateChange  := @DoMacroRecorderState;
  FSynMacro.RecordCommandID := ecNone; // ecSynMacroRecord;
  FSynMacro.PlaybackCommandID := ecNone; // ecSynMacroPlay;
  FSynMacro.RecordShortCut := 0;
  FSynMacro.PlaybackShortCut := 0;
end;

destructor TIdeEditorMacro.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FSynMacro);
  FreeAndNil(FKeyBinding);
end;

procedure TIdeEditorMacro.AssignEventsFrom(AMacroRecorder: TEditorMacro);
begin
  if AMacroRecorder = nil then
    Clear
  else
  if AMacroRecorder is TIdeEditorMacro then
    FSynMacro.AssignEventsFrom(TIdeEditorMacro(AMacroRecorder).FSynMacro)
  else
    SetFromSource(AMacroRecorder.GetAsSource);
end;

function TIdeEditorMacro.AddEditor(AValue: TCustomSynEdit): integer;
begin
  Result := FSynMacro.AddEditor(AValue);
end;

procedure TIdeEditorMacro.DoRecordMacro(aEditor: TCustomSynEdit);
begin
  FSynMacro.RecordMacro(aEditor);
end;

procedure TIdeEditorMacro.DoPlaybackMacro(aEditor: TCustomSynEdit);
begin
  FSynMacro.PlaybackMacro(aEditor);
end;

procedure TIdeEditorMacro.DoStop;
begin
  FSynMacro.Stop;
end;

procedure TIdeEditorMacro.DoPause;
begin
  FSynMacro.Pause;
end;

procedure TIdeEditorMacro.DoResume;
begin
  FSynMacro.Resume;
end;

procedure TIdeEditorMacro.Clear;
begin
  FSynMacro.Clear;
end;

function TIdeEditorMacro.GetAsSource: String;
var
  i : integer;
  W: TIdeMacroEventWriter;
begin
  if FHasError then begin
    Result := FFailedText;
    exit;
  end;

  W := TIdeMacroEventWriter.Create;
  W.UseLineFeed := True;
  try
    for i := 0 to FSynMacro.EventCount -1 do
    begin
      W.BeginEvent;
      FSynMacro.Events[i].SaveToWriter(W);
      W.FinishEvent;
    end;
    Result := w.Text;
  finally
    W.Free;
  end;
end;

procedure TIdeEditorMacro.SetFromSource(const AText: String);
var
  iEvent: TSynMacroEvent;
  R: TIdeMacroEventReader;
begin
  Stop;
  FSynMacro.Clear;
  FHasError := False;

  R := TIdeMacroEventReader.Create(AText);
  try
    while R.ParseNextEvent do begin
      iEvent := FSynMacro.CreateMacroEvent(R.EventCommand);
      iEvent.LoadFromReader(R);
      FSynMacro.InsertCustomEvent(FSynMacro.EventCount, iEvent);
    end;
    if R.HasError then begin
      FHasError := True;
      FFailedText := AText;
      MacroName := MacroName;
    end;
  finally
    R.Free;
  end;
end;

procedure TIdeEditorMacro.WriteToXmlConf(AConf: TXMLConfig; const APath: String);
begin
  AConf.SetValue(APath + 'Name', MacroName);
  AConf.SetValue(APath + 'Code/Value', GetAsSource);

  if (KeyBinding <> nil) then
    KeyBinding.WriteToXmlConf(AConf, APath);
end;

procedure TIdeEditorMacro.ReadFromXmlConf(AConf: TXMLConfig; const APath: String);
var
  s: String;
begin
  s := AConf.GetValue(APath + 'Code/Value', '');
  SetFromSource(s);
  s := AConf.GetValue(APath + 'Name', '');
  if s <> '' then MacroName := s;

  if (not FHasError) and (FSynMacro.EventCount = 0) then begin
    FHasError := True;
    FFailedText := s;
  end;

  if (KeyBinding <> nil) then
    KeyBinding.ReadFromXmlConf(AConf, APath);
end;

function TIdeEditorMacro.IsEmpty: Boolean;
begin
  Result := FSynMacro.IsEmpty;
end;

function TIdeEditorMacro.IsInvalid: Boolean;
begin
  Result := FHasError;
end;

function TIdeEditorMacro.IsRecording(AnEditor: TCustomSynEdit): Boolean;
begin
  Result := (State in [emRecording, emRecPaused]) and
            (FSynMacro.CurrentEditor = AnEditor);
end;

{ TIdeMacroEventReader }

function TIdeMacroEventReader.GetParamAsInt(Index: Integer): Integer;
begin
  if (Index < 0) or (Index >= Length(FParams)) or (ParamType[Index] <> ptInteger)
  then begin
    FHasError := True;
    exit; // TODO error
  end;

  Result := FParams[Index].Num;
end;

function TIdeMacroEventReader.GetParamAsString(Index: Integer): String;
begin
  if (Index < 0) or (Index >= Length(FParams)) or (ParamType[Index] <> ptString)
  then begin
    FHasError := True;
    exit; // TODO error
  end;

  Result := FParams[Index].Text;
end;

function TIdeMacroEventReader.GetParamType(Index: Integer): TSynEventParamType;
begin
  if (Index < 0) or (Index >= Length(FParams)) then begin
    FHasError := True;
    exit; // TODO error
  end;

  Result := FParams[Index].ParamType;
end;

constructor TIdeMacroEventReader.Create(const Atext: String);
begin
  FText := Atext;
  FHasError := False;
end;

function TIdeMacroEventReader.EventCommand: TSynEditorCommand;
begin
  Result := FEventCommand;
end;

function TIdeMacroEventReader.ParamCount: Integer;
begin
  Result := Length(FParams);
end;

function TIdeMacroEventReader.ParseNextEvent: Boolean;
  procedure SkipNum(var i: integer);
  begin
    while (i <= Length(FText)) and (FText[i] in ['0'..'9']) do inc (i);
  end;
  procedure SkipSpace(var i: integer);
  begin
    while (i <= Length(FText)) and (FText[i] in [' '..#9, #13, #10]) do inc (i);
  end;
var
  c,i,j,k: Integer;
  s: String;
begin
  FEventName := '';
  FText := Trim(FText);
  Result := (FText <> '') and (not FHasError);
  if not Result then exit;
  Result := False;
  FHasError := True; // Assume the worst

  i := 1;
  while (i <= Length(FText)) and (FText[i] in ['a'..'z','A'..'Z','0'..'9','_']) do inc (i);
  if i = 1 then exit; // Todo error

  s := Copy(FText, 1, i-1);
  if not IdentToEditorCommand(s, j) then exit; // Todo error
  FEventCommand := j;
  FEventName := s;

  while (i <= Length(FText)) and (FText[i] in [' ', #9]) do inc (i);
  if (i > Length(FText)) then exit; // Todo error

  SetLength(FParams, 0);
  c := 0;

  if (FText[i] = '(') then begin
    inc(i);
    repeat
      SkipSpace(i);
      if (i > Length(FText)) then exit; // Todo error

      if FText[i] in ['0'..'9'] then begin
        // Parse number
        j := i;
        SkipNum(i);
        SetLength(FParams, c + 1);
        FParams[c].ParamType := ptInteger;
        FParams[c].Num := StrToInt(copy(FText, i, j-i));
        inc(c);
      end
      else
      if FText[i] in ['#', ''''] then begin
        // Parse string
        s := '';
        repeat
          case FText[i] of
            '#': begin
                j := i;
                SkipNum(i);
                k := StrToInt(copy(FText, i, j-i));
                if k > 255 then exit; // TODO error, todo utf8
                s := s + chr(k);
              end;
            '''':  begin
                inc(i);
                repeat
                  case FText[i] of
                    '''': begin
                        if (i+1 <= Length(FText)) and (FText[i+1] = '''') then begin
                          s := s + '''';
                          inc(i,2);
                        end
                        else begin
                          inc(i);
                          break;
                        end;
                      end;
                    else begin
                        s := s + FText[i];
                        inc(i);
                      end;
                  end;
                until i > Length(FText);
              end;
            else
              break;
          end;
        until i > Length(FText);

        SetLength(FParams, c + 1);
        FParams[c].ParamType := ptString;
        FParams[c].Text := s;
        inc(c);
      end
      else
      if FText[i] <> ')' then
        exit; // Todo error

      SkipSpace(i);
      if (i >= Length(FText)) then exit; // Todo error
      if FText[i] = ')' then break;
      if not(FText[i] = ',') then exit; // Todo error
      inc(i);
    until i > Length(FText);
    inc(i);
  end;

  if (i > Length(FText)) then exit; // Todo error
  if (FText[i] = ';') then begin
    Delete(FText, 1, i);
    Result := True;
    FHasError := False;
    exit;
  end;
end;

{ TSynMacroEventWriter }

constructor TIdeMacroEventWriter.Create;
begin
  FUseLineFeed := False;
end;

procedure TIdeMacroEventWriter.BeginEvent;
begin
  FCmdName := '';
  FParams := '';
end;

procedure TIdeMacroEventWriter.FinishEvent;
begin
  FText := FText + FCmdName;
  if FParams <> '' then
    FText := FText + '(' + FParams + ')';
  FText := FText + ';';
  if FUseLineFeed then
    FText := FText + LineEnding;
end;

procedure TIdeMacroEventWriter.WriteEventCommand(const ACmd: TSynEditorCommand);
begin
  EditorCommandToIdent(ACmd, FCmdName);
end;

procedure TIdeMacroEventWriter.WriteEventParam(const AParam: string);
var
  s: String;
  i: Integer;
  InQuotes: Boolean;
begin
  if FParams <> '' then
    FParams := FParams + ', ';
  s := '';
  InQuotes := False;
  for i := 1 to length(AParam) do
    case AParam[i] of
      #0..#31: begin
          if InQuotes then s := s + '''';
          InQuotes := False;
          s := s + '#' + IntToStr(ord(AParam[i]));
        end;
      '''': begin
          if not InQuotes then s := s + '''';
          InQuotes := True;
          s := s + '''''';
        end;
      else begin
          if not InQuotes then s := s + '''';
          InQuotes := True;
          s := s + AParam[i];
        end;
    end;
  if InQuotes then s := s + '''';
  FParams := FParams + s;
end;

procedure TIdeMacroEventWriter.WriteEventParam(const AParam: integer);
begin
  if FParams <> '' then
    FParams := FParams + ', ';
  FParams := FParams + IntToStr(AParam);
end;

{ TMacroListView }

procedure TMacroListView.btnRenameClick(Sender: TObject);
var
  s: String;
  M: TEditorMacro;
begin
  if lbRecordedView.ItemIndex < 0 then exit;
  M := CurrentEditorMacroList.Macros[lbRecordedView.ItemIndex];
  s := M.MacroName;
  if InputQuery(lisNewMacroname2, Format(lisEnterNewNameForMacroS, [m.MacroName]), s)
  then begin
    while (s <> '') and (CurrentEditorMacroList.IndexOfName(s) >= 0) do begin
      case MessageDlg(lisDuplicateName, lisAMacroWithThisNameAlreadyExists, mtWarning,
        mbOKCancel, 0) of
        mrOK:
          if not InputQuery(lisNewMacroname2, Format(lisEnterNewNameForMacroS, [m.MacroName]), s)
          then s := '';
        else
          s := '';
      end;
    end;

    if s <> '' then begin
      M.MacroName := s;
      if CurrentEditorMacroList = EditorMacroListProj then Project1.Modified := True;
      if CurrentEditorMacroList = EditorMacroListGlob then MainIDEInterface.SaveEnvironment(False);
    end;
    UpdateDisplay;
  end;
end;

procedure TMacroListView.btnPlayClick(Sender: TObject);
var
  i: Integer;
  M: TEditorMacro;
begin
  if ActiveEditorMacro <> nil then exit;
  if lbRecordedView.ItemIndex < 0 then exit;

  i := 1;
  if chkRepeat.Enabled then i := edRepeat.Value;
  FIsPlaying := True;
  UpdateButtons;

  M := CurrentEditorMacroList.Macros[lbRecordedView.ItemIndex];
  try
    while i > 0 do begin
      M.PlaybackMacro(TCustomSynEdit(SourceEditorManagerIntf.ActiveEditor.EditorControl));
      Application.ProcessMessages;
      dec(i);
      if not FIsPlaying then break;
    end;
  finally
    FIsPlaying := False;
    UpdateButtons;
  end;

end;

procedure TMacroListView.btnDeleteClick(Sender: TObject);
var
  m: TEditorMacro;
begin
  if lbRecordedView.ItemIndex < 0 then exit;
  if MessageDlg(lisDeleteSelectedMacro, mtConfirmation, [mbYes, mbNo], 0) = mrYes
  then begin
    if SelectedEditorMacro = CurrentEditorMacroList.Macros[lbRecordedView.ItemIndex] then begin
      SelectedEditorMacro := nil;
    end;
    m := CurrentEditorMacroList.Macros[lbRecordedView.ItemIndex];
    CurrentEditorMacroList.Delete(lbRecordedView.ItemIndex);
    m.Free;
    if CurrentEditorMacroList = EditorMacroListProj then Project1.Modified := True;
    if CurrentEditorMacroList = EditorMacroListGlob then MainIDEInterface.SaveEnvironment(False);
    UpdateDisplay;
  end;
end;

procedure TMacroListView.btnEditClick(Sender: TObject);
var
  M: TEditorMacro;
begin
  if lbRecordedView.ItemIndex < 0 then exit;
  M := CurrentEditorMacroList.Macros[lbRecordedView.ItemIndex];
  if M = nil then exit;
  LazarusIDE.DoOpenEditorFile(
    '//EMacro:/'+MacroListToName(CurrentEditorMacroList)+'/'+M.MacroName,
    -1, -1, [ofVirtualFile, ofEditorMacro]);
end;

procedure TMacroListView.btnRecordClick(Sender: TObject);
begin
  if (ActiveEditorMacro = nil) and (EditorMacroForRecording.State = emStopped) then begin
    EditorMacroForRecording.RecordMacro(TCustomSynEdit(SourceEditorManagerIntf.ActiveEditor.EditorControl));
  end
  else
  if EditorMacroForRecording.State = emRecording then begin
    EditorMacroForRecording.Pause;
  end
  else
  if EditorMacroForRecording.State = emRecPaused then begin
    EditorMacroForRecording.Resume;
  end;
  SourceEditorManagerIntf.ActiveEditor.EditorControl.SetFocus;
end;

procedure TMacroListView.btnRecordStopClick(Sender: TObject);
begin
  FIsPlaying := False;
  EditorMacroForRecording.Stop;
end;

procedure TMacroListView.btnSelectClick(Sender: TObject);
begin
  if ActiveEditorMacro <> nil then exit;
  if lbRecordedView.ItemIndex >= 0 then
    SelectedEditorMacro := CurrentEditorMacroList.Macros[lbRecordedView.ItemIndex]
  else
    SelectedEditorMacro:= nil;
  UpdateDisplay;
end;

procedure TMacroListView.btnSetKeysClick(Sender: TObject);
var
  i: integer;
  M: TEditorMacro;
begin
  if lbRecordedView.ItemIndex < 0 then exit;
  M := CurrentEditorMacroList.Macros[lbRecordedView.ItemIndex];

  if (M.KeyBinding = nil) or (M.KeyBinding.IdeCmd = nil) or
     not(M.KeyBinding.IdeCmd is TKeyCommandRelation)
  then // only for error macros
    exit;

  i := (IDECommandList as TKeyCommandRelationList).IndexOf(M.KeyBinding.IdeCmd as TKeyCommandRelation);
  if (i >= 0) then
    if ShowKeyMappingEditForm(i, (IDECommandList as TKeyCommandRelationList)) = mrOK then begin
      if CurrentEditorMacroList = EditorMacroListProj then Project1.Modified := True;
      if CurrentEditorMacroList = EditorMacroListGlob then MainIDEInterface.SaveEnvironment(False);
    end;
  UpdateDisplay;
  if OnKeyMapReloaded <> nil then OnKeyMapReloaded();
end;

procedure TMacroListView.DoMacroStateChanged(Sender: TObject);
begin
  if OnEditorMacroStateChange <> nil then
    OnEditorMacroStateChange(Sender);
end;

procedure TMacroListView.FormActivate(Sender: TObject);
begin
  lbRecordedView.HideSelection := Active;
end;

procedure TMacroListView.HelpButtonClick(Sender: TObject);
begin
  LazarusHelp.ShowHelpForIDEControl(Self);
end;

procedure TMacroListView.lbRecordedViewSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  UpdateButtons;
end;

procedure TMacroListView.mnExportClick(Sender: TObject);
var
  Conf: TXMLConfig;
begin
  if lbRecordedView.ItemIndex < 0 then exit;

  if SaveDialog1.Execute then begin
    Conf := TXMLConfig.Create(SaveDialog1.FileName);
    try
      Conf.Clear;
      Conf.SetValue('EditorMacros/Count', 1);
      CurrentEditorMacroList.Macros[lbRecordedView.ItemIndex].WriteToXmlConf(Conf, 'EditorMacros/Macro1/');
    finally
      Conf.Free;
    end;
  end;
end;

procedure TMacroListView.mnImportClick(Sender: TObject);
var
  Conf: TXMLConfig;
  NewMacro: TEditorMacro;
begin
  if OpenDialog1.Execute then begin
    Conf := TXMLConfig.Create(OpenDialog1.FileName);
    try
      NewMacro := EditorMacroPlayerClass.Create(nil);
      NewMacro.OnStateChange := @DoMacroStateChanged;
      NewMacro.ReadFromXmlConf(Conf, 'EditorMacros/Macro1/');
      if not NewMacro.IsEmpty then begin
        CurrentEditorMacroList.Add(NewMacro);
        if CurrentEditorMacroList = EditorMacroListProj then Project1.Modified := True;
        if CurrentEditorMacroList = EditorMacroListGlob then MainIDEInterface.SaveEnvironment(False);
      end
      else
        NewMacro.Free;
    finally
      Conf.Free;
    end;
  end;
end;

procedure TMacroListView.tbIDEClick(Sender: TObject);
begin
  CurrentEditorMacroList := EditorMacroListGlob;
  UpdateDisplay;
end;

procedure TMacroListView.tbMoveIDEClick(Sender: TObject);
var
  i: Integer;
begin
  if (lbRecordedView.ItemIndex < 0) or (CurrentEditorMacroList = EditorMacroListGlob) then exit;
  i := lbRecordedView.ItemIndex;
  EditorMacroListGlob.Add(CurrentEditorMacroList.Macros[i]);
  CurrentEditorMacroList.Delete(i);
  if CurrentEditorMacroList = EditorMacroListProj then Project1.Modified := True;
  MainIDEInterface.SaveEnvironment(False);
  UpdateDisplay;
end;

procedure TMacroListView.tbMoveProjectClick(Sender: TObject);
var
  i: Integer;
begin
  if (lbRecordedView.ItemIndex < 0) or (CurrentEditorMacroList = EditorMacroListProj) then exit;
  i := lbRecordedView.ItemIndex;
  EditorMacroListProj.Add(CurrentEditorMacroList.Macros[i]);
  CurrentEditorMacroList.Delete(i);
  Project1.Modified := True;
  if CurrentEditorMacroList = EditorMacroListGlob then MainIDEInterface.SaveEnvironment(False);
  UpdateDisplay;
end;

procedure TMacroListView.tbProjectClick(Sender: TObject);
begin
  CurrentEditorMacroList := EditorMacroListProj;
  UpdateDisplay;
end;

procedure TMacroListView.tbRecordedClick(Sender: TObject);
begin
  CurrentEditorMacroList := EditorMacroListRec;
  UpdateDisplay;
end;

procedure TMacroListView.DoOnMacroListChange(Sender: TObject);
begin
  UpdateDisplay;

  if Sender = EditorMacroListProj then
    Project1.SessionModified := True;
end;

procedure TMacroListView.UpdateDisplay;
var
  NewItem: TListItem;
  i, idx: Integer;
  M: TEditorMacro;
begin
  idx := lbRecordedView.ItemIndex;
  lbRecordedView.Items.Clear;

  for i := 0 to CurrentEditorMacroList.Count - 1 do begin
    M := CurrentEditorMacroList.Macros[i];
    NewItem := lbRecordedView.Items.Add;

    if m.KeyBinding <> nil then
      NewItem.Caption := M.MacroName + M.KeyBinding.ShortCutAsText
    else
      NewItem.Caption := M.MacroName;

    // Image
    if M.IsInvalid then
      NewItem.ImageIndex := FImageErr
    else
    if (m = CurrentRecordingMacro) then
      NewItem.ImageIndex := FImageRec
    else
    if (CurrentRecordingMacro = nil) then begin // If recording, then recorder is selected
      If (M = ActiveEditorMacro) and (M.State = emPlaying) then
        NewItem.ImageIndex := FImagePlay
      else
      if (M = SelectedEditorMacro) then
        NewItem.ImageIndex := FImageSel;
    end;
  end;
  if idx < lbRecordedView.Items.Count then
    lbRecordedView.ItemIndex := idx
  else
    lbRecordedView.ItemIndex := -1;

  lbRecordedViewSelectItem(nil, nil, False);
  UpdateButtons;
end;

procedure TMacroListView.UpdateButtons;
var
  IsSel, IsErr, IsStopped: Boolean;
  M: TEditorMacro;
  RecState: TEditorMacroState;
begin
  IsSel := (lbRecordedView.ItemIndex >= 0);
  IsStopped := (ActiveEditorMacro = nil);
  if IsSel then
    M := CurrentEditorMacroList.Macros[lbRecordedView.ItemIndex];
  IsErr := IsSel and M.IsInvalid;
  RecState := emStopped;
  if EditorMacroForRecording <> nil then
    RecState := EditorMacroForRecording.State;

  btnSelect.Enabled  := IsStopped and IsSel and (not FIsPlaying) and (not IsErr);
  btnRename.Enabled  := IsStopped and IsSel and (not FIsPlaying) and (not IsErr);
  btnEdit.Enabled    := IsStopped and IsSel and (not FIsPlaying);
  btnSetKeys.Enabled := IsStopped and IsSel and (not FIsPlaying) and (not IsErr);
  btnDelete.Enabled  := IsStopped and IsSel and (not FIsPlaying);

  btnPlay.Enabled    := IsStopped and IsSel and (not FIsPlaying) and (not IsErr);
  chkRepeat.Enabled  := IsStopped and (not FIsPlaying);
  edRepeat.Enabled   := IsStopped and (not FIsPlaying);

  btnRecord.Enabled  := (RecState in [emStopped, emRecPaused, emRecording]) and (not FIsPlaying);
  btnRecordStop.Enabled := (not IsStopped) or FIsPlaying;

  if (RecState = emRecording) then
    btnRecord.Caption := lisPause
  else if (RecState = emRecPaused) then
    btnRecord.Caption := lisContinue
  else
    btnRecord.Caption := lisRecord;

  mnImport.Enabled := IsStopped and (not FIsPlaying);
  mnExport.Enabled := IsStopped and IsSel and (not FIsPlaying);

  tbMoveProject.Visible := CurrentEditorMacroList <> EditorMacroListProj;
  tbMoveProject.Enabled := IsStopped and IsSel and (not FIsPlaying);
  tbMoveIDE.Visible := CurrentEditorMacroList <> EditorMacroListGlob;
  tbMoveIDE.Enabled := IsStopped and IsSel and (not FIsPlaying);

  Update;
end;

function TMacroListView.MacroByFullName(AName: String): TEditorMacro;
var
  Alist: TEditorMacroList;
  i: Integer;
begin
  Result := nil;
  If (copy(AName, 1, 10) <> '//EMacro:/') or
     (copy(AName, 14, 1) <> '/')
  then exit;
  Alist := NameToMacroList(copy(AName, 11, 3));
  if (Alist = nil) then exit;
  i := Alist.IndexOfName(copy(AName, 15, length(AName)));
  if i < 0 then exit;
  Result := Alist.Macros[i]
end;

procedure TMacroListView.DoEditorMacroStateChanged;
begin
  UpdateDisplay;
end;

constructor TMacroListView.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Caption := lisEditorMacros;
  EditorMacroListRec.OnChange := @DoOnMacroListChange;
  EditorMacroListProj.OnChange := @DoOnMacroListChange;
  EditorMacroListGlob.OnChange := @DoOnMacroListChange;

  tbRecorded.Caption := lisRecordedMacros;
  tbProject.Caption := lisProjectMacro;
  tbIDE.Caption := lisIDE;
  tbRecorded.Hint := lisNewRecordedMacrosNotToBeSaved;
  tbProject.Hint := lisSavedWithProjectSession;
  tbIDE.Hint := lisSavedWithIDESettings;
  tbMoveProject.Caption := lisProjectMacro;
  tbMoveIDE.Caption := lisIDE;
  lbMoveTo.Caption := lisMoveTo;

  btnSelect.Caption := lisMenuSelect;
  btnRename.Caption := lisRename2;
  btnSetKeys.Caption := lisEditKey;
  btnEdit.Caption   := lisEdit;
  btnDelete.Caption := lisDelete;
  btnPlay.Caption := lisPlay;
  chkRepeat.Caption := lisRepeat;
  btnRecord.Caption := lisRecord;
  btnRecordStop.Caption := lisStop;

  SaveDialog1.Title := lisSaveMacroAs;
  OpenDialog1.Title := lisLoadMacroFrom;
  mnImport.Caption := lisImport;
  mnExport.Caption := lisExport;

  lbRecordedView.SmallImages := IDEImages.Images_16;
  FImageRec := IDEImages.LoadImage(16, 'Record');  // red dot
  FImagePlay := IDEImages.LoadImage(16, 'menu_run');  // green triangle
  FImageSel := IDEImages.LoadImage(16, 'arrow_right');
  FImageErr := IDEImages.LoadImage(16, 'state_error');
  FIsPlaying := False;

  UpdateDisplay;
end;

destructor TMacroListView.Destroy;
begin
  inherited Destroy;
end;

{ TEditorMacroList }

function TEditorMacroList.GetMacros(Index: Integer): TEditorMacro;
begin
  Result := TEditorMacro(FList[Index]);
end;

procedure TEditorMacroList.DoChanged;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TEditorMacroList.DoAdded(AMacro: TEditorMacro);
begin
  if Assigned(FOnAdded) then
    FOnAdded(Self, AMacro);
end;

procedure TEditorMacroList.DoRemove(AMacro: TEditorMacro);
begin
  if Assigned(FOnRemove) then
    FOnRemove(Self, AMacro);
end;

constructor TEditorMacroList.Create;
begin
  FList := TList.Create;
end;

destructor TEditorMacroList.Destroy;
begin
  FOnChange := nil;
  ClearAndFreeMacros;
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TEditorMacroList.WriteToXmlConf(AConf: TXMLConfig; const APath: String);
var
  i: Integer;
begin
  AConf.SetValue(APath + 'EditorMacros/Count', Count);
  for i := 0 to Count - 1 do
    Macros[i].WriteToXmlConf(AConf, 'EditorMacros/Macro'+IntToStr(i+1)+'/');
end;

procedure TEditorMacroList.ReadFromXmlConf(AConf: TXMLConfig; const APath: String);
var
  c, i: Integer;
  NewMacro: TEditorMacro;
begin
  ClearAndFreeMacros;
  c := AConf.GetValue(APath + 'EditorMacros/Count', 0);
  for i := 0 to c -1 do begin
    NewMacro := EditorMacroPlayerClass.Create(nil);
    NewMacro.OnStateChange := @MacroListViewer.DoMacroStateChanged;
    try
      NewMacro.ReadFromXmlConf(AConf, 'EditorMacros/Macro'+IntToStr(i+1)+'/');
    finally
      Add(NewMacro)
    end;
  end;
end;

procedure TEditorMacroList.ClearAndFreeMacros;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do Macros[i].Free;
  FList.Clear;
end;

function TEditorMacroList.Count: Integer;
begin
  Result := FList.Count;
end;

function TEditorMacroList.IndexOf(AMacro: TEditorMacro): Integer;
begin
  Result := FList.IndexOf(AMacro);
end;

function TEditorMacroList.IndexOfName(AName: String): Integer;
begin
  Result := Count - 1;
  while Result >= 0 do
    if Macros[Result].MacroName = AName
    then break
    else dec(Result);
end;

function TEditorMacroList.UniqName(AName: String): String;
var
  i: Integer;
begin
  Result := AName;
  if IndexOfName(AName) < 0 then exit;
  i := 1;
  while IndexOfName(AName+'_'+IntToStr(i)) >= 0 do inc(i);
  Result := AName+'_'+IntToStr(i);
end;

function TEditorMacroList.Add(AMacro: TEditorMacro): Integer;
begin
  AMacro.MacroName := UniqName(AMacro.MacroName);
  Result := FList.Add(AMacro);
  DoAdded(AMacro);
  DoChanged;
end;

procedure TEditorMacroList.Delete(AnIndex: Integer);
begin
  DoRemove(Macros[AnIndex]);
  FList.Delete(AnIndex);
  DoChanged;
end;

procedure TEditorMacroList.Remove(AMacro: TEditorMacro);
begin
  DoRemove(AMacro);
  FList.Remove(AMacro);
  DoChanged;
end;

// itmMacroListView.enabled

{$R *.lfm}

initialization
  EditorMacroPlayerClass := TIdeEditorMacro;
  DefaultBindingClass := TIdeEditorMacroKeyBinding;
  EditorMacroListRec := TEditorMacroList.Create;
  EditorMacroListProj := TEditorMacroList.Create;
  EditorMacroListGlob := TEditorMacroList.Create;
  CurrentEditorMacroList := EditorMacroListRec;

finalization
  CurrentEditorMacroList := nil;
  FreeAndNil(EditorMacroListRec);
  FreeAndNil(EditorMacroListProj);
  FreeAndNil(EditorMacroListGlob);

end.

