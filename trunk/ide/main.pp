{  $Id$  }
{
 /***************************************************************************
                          main.pp  -  Toolbar
                          -------------------
                   TMainIDE is the application toolbar window.


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
unit Main;

{$mode objfpc}{$H+}

interface

{$I ide.inc}

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  Classes, LCLType, LclLinux, Compiler, StdCtrls, Forms, Buttons, Menus,
  ComCtrls, Spin, Project, SysUtils, FileCtrl, Controls, Graphics, ExtCtrls,
  Dialogs, LazConf, CompReg, CodeToolManager, CodeCache, DefineTemplates,
  MsgView, NewProjectDlg, IDEComp, AbstractFormEditor, FormEditor,
  CustomFormEditor, ObjectInspector, PropEdits, ControlSelection, UnitEditor,
  CompilerOptions, EditorOptions, EnvironmentOpts, TransferMacros, KeyMapping,
  ProjectOpts, IDEProcs, Process, UnitInfoDlg, Debugger, DBGBreakpoint,
  DBGWatch, GDBDebugger, RunParamsOpts, ExtToolDialog, MacroPromptDlg,
  LMessages, ProjectDefs, Watchesdlg, BreakPointsdlg, ColumnDlg, OutputFilter,
  BuildLazDialog, MiscOptions, EditDefineTree, CodeToolsOptions, TypInfo;

const
  Version_String = '0.8.2 alpha';

type
  {
    The IDE is at anytime in a specific state:
    
    itNone: The default mode. All editing allowed.
    itBuilder: compiling the project. Loading/Saving/Debugging is not allowed.
    itDebugger: debugging the project. Loading/Saving/Compiling is not allowed.
    itCustom: this state is not used yet.
  }
  TIDEToolStatus = (itNone, itBuilder, itDebugger, itCustom);

  TMainIDE = class(TForm)
    pnlSpeedButtons : TPanel;

    ViewUnitsSpeedBtn   : TSpeedButton;
    ViewFormsSpeedBtn   : TSpeedButton;
    NewUnitSpeedBtn     : TSpeedButton;
    OpenFileSpeedBtn    : TSpeedButton;
    OpenFileArrowSpeedBtn: TSpeedButton;
    SaveSpeedBtn        : TSpeedButton;
    SaveAllSpeedBtn     : TSpeedButton;
    ToggleFormSpeedBtn  : TSpeedButton;
    NewFormSpeedBtn     : TSpeedButton;
    RunSpeedButton      : TSpeedButton;
    PauseSpeedButton    : TSpeedButton;
    StepIntoSpeedButton : TSpeedButton;
    StepOverSpeedButton : TSpeedButton;
    OpenFilePopUpMenu   : TPopupMenu;
    GlobalMouseSpeedButton: TSpeedButton;

    mnuMain: TMainMenu;

    mnuFile: TMenuItem;
    mnuEdit: TMenuItem; 
    mnuSearch: TMenuItem;
    mnuView: TMenuItem; 
    mnuProject: TMenuItem; 
    mnuRun: TMenuItem; 
    mnuTools: TMenuItem; 
    mnuEnvironment: TMenuItem;
    mnuHelp: TMenuItem;

    itmSeperator: TMenuItem;

    itmFileNew : TMenuItem;
    itmFileNewForm : TMenuItem;
    itmFileOpen: TMenuItem;
    itmFileRecentOpen: TMenuItem;
    itmFileSave: TMenuItem; 
    itmFileSaveAs: TMenuItem; 
    itmFileSaveAll: TMenuItem; 
    itmFileClose: TMenuItem; 
    itmFileQuit: TMenuItem; 

    itmEditUndo: TMenuItem; 
    itmEditRedo: TMenuItem; 
    itmEditCut: TMenuItem; 
    itmEditCopy: TMenuItem; 
    itmEditPaste: TMenuItem; 

    itmSearchFind: TMenuItem;
    itmSearchFindNext: TMenuItem;
    itmSearchFindPrevious: TMenuItem;
    itmSearchFindInFiles: TMenuItem;
    itmSearchReplace: TMenuItem;
    itmGotoLine: TMenuItem;
    itmJumpBack: TMenuItem;
    itmJumpForward: TMenuItem;
    itmAddJumpPoint: TMenuItem;
    itmJumpHistory: TMenuItem;

    itmViewInspector: TMenuItem;
    itmViewProject: TMenuItem; 
    itmViewUnits : TMenuItem;
    itmViewCodeExplorer : TMenuItem;
    itmViewForms : TMenuItem;
    itmViewFile : TMenuItem;
    itmViewMessage : TMenuItem;
    itmViewwatches : TMenuItem;
    itmViewBreakpoints : TMenuItem;

    itmProjectNew: TMenuItem;
    itmProjectOpen: TMenuItem;
    itmProjectRecentOpen: TMenuItem;
    itmProjectSave: TMenuItem;
    itmProjectSaveAs: TMenuItem;
    itmProjectAddTo: TMenuItem;
    itmProjectRemoveFrom: TMenuItem;
    itmProjectViewSource: TMenuItem;
    itmProjectOptions: TMenuItem;
    
    itmProjectBuild: TMenuItem;
    itmProjectBuildAll: TMenuItem;
    itmProjectRun: TMenuItem;
    itmProjectPause: TMenuItem;
    itmProjectStepInto: TMenuItem;
    itmProjectStepOver: TMenuItem;
    itmProjectRunToCursor: TMenuItem;
    itmProjectStop: TMenuItem;
    itmProjectCompilerSettings: TMenuItem;
    itmProjectRunParameters: TMenuItem;
    
    itmToolConfigure: TMenuItem;
    itmToolSyntaxCheck: TMenuItem;
    itmToolGuessUnclosedBlockCheck: TMenuItem;
    itmToolBuildLazarus: TMenuItem;
    itmToolConfigureBuildLazarus: TMenuItem;

    itmEnvGeneralOptions: TMenuItem; 
    itmEnvEditorOptions: TMenuItem; 
    itmEnvCodeToolsOptions: TMenuItem;

    itmHelpAboutLazarus: TMenuItem;
    
    ComponentNotebook : TNotebook;

    HintTimer1 : TTimer;
    HintWindow1 : THintWindow;
    
    // event handlers
    procedure FormShow(Sender : TObject);
    procedure FormClose(Sender : TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender : TObject; var CanClose: boolean);
    procedure FormPaint(Sender : TObject);
    procedure MainMouseMoved(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure MainMouseDown(Sender: TObject; Button: TMouseButton; 
        Shift: TShiftState; X,Y: Integer);
    procedure MainKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    // file menu
    procedure mnuNewUnitClicked(Sender : TObject);
    procedure mnuNewFormClicked(Sender : TObject);
    procedure mnuOpenClicked(Sender : TObject);
    procedure mnuOpenFileAtCursorClicked(Sender : TObject);
    procedure mnuSaveClicked(Sender : TObject);
    procedure mnuSaveAsClicked(Sender : TObject);
    procedure mnuSaveAllClicked(Sender : TObject);
    procedure mnuCloseClicked(Sender : TObject);
    procedure mnuQuitClicked(Sender : TObject);

    // view menu
    procedure mnuViewInspectorClicked(Sender : TObject);
    procedure mnuViewUnitsClicked(Sender : TObject);
    procedure mnuViewFormsClicked(Sender : TObject);
    procedure mnuViewCodeExplorerClick(Sender : TObject);
    procedure mnuViewMessagesClick(Sender : TObject);
    procedure mnuViewWatchesClick(Sender : TObject);
    procedure mnuViewBreakPointsClick(Sender : TObject);
    procedure MessageViewDblClick(Sender : TObject);

    procedure mnuToggleFormUnitClicked(Sender : TObject);

    // project menu
    procedure mnuNewProjectClicked(Sender : TObject);
    procedure mnuOpenProjectClicked(Sender : TObject);
    procedure mnuSaveProjectClicked(Sender : TObject);
    procedure mnuSaveProjectAsClicked(Sender : TObject);
    procedure mnuAddToProjectClicked(Sender : TObject);
    procedure mnuRemoveFromProjectClicked(Sender : TObject);
    procedure mnuViewProjectSourceClicked(Sender : TObject);
    procedure mnuProjectOptionsClicked(Sender : TObject);
    
    // run menu
    procedure mnuBuildProjectClicked(Sender : TObject);
    procedure mnuBuildAllProjectClicked(Sender : TObject);
    procedure mnuRunProjectClicked(Sender : TObject);
    procedure mnuPauseProjectClicked(Sender : TObject);
    procedure mnuStepIntoProjectClicked(Sender : TObject);
    procedure mnuStepOverProjectClicked(Sender : TObject);
    procedure mnuRunToCursorProjectClicked(Sender : TObject);
    procedure mnuStopProjectClicked(Sender : TObject);
    procedure mnuRunParametersClicked(Sender : TObject);
    procedure mnuProjectCompilerSettingsClicked(Sender : TObject);

    // tools menu
    procedure mnuToolConfigureClicked(Sender : TObject);
    procedure mnuToolSyntaxCheckClicked(Sender : TObject);
    procedure mnuToolGuessUnclosedBlockClicked(Sender : TObject);
    procedure mnuToolBuildLazarusClicked(Sender : TObject);
    procedure mnuToolConfigBuildLazClicked(Sender : TObject);

    // environment menu
    procedure mnuEnvGeneralOptionsClicked(Sender : TObject);
    procedure mnuEnvEditorOptionsClicked(Sender : TObject);
    procedure mnuEnvCodeToolsOptionsClicked(Sender : TObject);

    // help menu
    procedure mnuHelpAboutLazarusClicked(Sender : TObject);

    procedure OpenFileDownArrowClicked(Sender : TObject);
    procedure ControlClick(Sender : TObject);
    procedure mnuFindDeclarationClicked(Sender : TObject);
    

    // SourceNotebook events
    Procedure OnSrcNoteBookActivated(Sender : TObject);
    Procedure OnSrcNoteBookAddJumpPoint(ACaretXY: TPoint; ATopLine: integer; 
      APageIndex: integer; DeleteForwardHistory: boolean);
    Procedure OnSrcNotebookDeleteLastJumPoint(Sender: TObject);
    Procedure OnSrcNotebookEditorVisibleChanged(Sender : TObject);

    //this is fired when the editor is focused, changed, ?.  Anything that causes the status change
    Procedure OnSrcNotebookEditorChanged(Sender : TObject);
    
    Procedure OnSrcNotebookFileNew(Sender : TObject);
    Procedure OnSrcNotebookFileOpen(Sender : TObject);
    Procedure OnSrcNotebookFileOpenAtCursor(Sender : TObject);
    Procedure OnSrcNotebookFileSave(Sender : TObject);
    Procedure OnSrcNotebookFileSaveAs(Sender : TObject);
    Procedure OnSrcNotebookFileClose(Sender : TObject);
    Procedure OnSrcNotebookFindDeclaration(Sender : TObject);
    Procedure OnSrcNotebookJumpToHistoryPoint(var NewCaretXY: TPoint;
      var NewTopLine, NewPageIndex: integer; Action: TJumpHistoryAction);
    Procedure OnSrcNotebookProcessCommand(Sender: TObject; Command: integer;
      var Handled: boolean);
    Procedure OnSrcNotebookSaveAll(Sender : TObject);
    procedure OnSrcNoteBookShowUnitInfo(Sender: TObject);
    Procedure OnSrcNotebookToggleFormUnit(Sender : TObject);
    Procedure OnSrcNotebookViewJumpHistory(Sender : TObject);
    Procedure OnSrcNotebookAddWatchesAtCursor(Sender : TObject);
    Procedure OnSrcNotebookCreateBreakPoint(Sender : TObject; Line : Integer);
    Procedure OnSrcNotebookDeleteBreakPoint(Sender : TObject; Line : Integer);
    
    // ObjectInspector + PropertyEditorHook events
    procedure OIOnAddAvailableComponent(AComponent:TComponent;
      var Allowed:boolean);
    procedure OIOnSelectComponent(AComponent:TComponent);
    procedure OnPropHookGetMethods(TypeData:PTypeData; Proc:TGetStringProc);
    function OnPropHookMethodExists(const AMethodName:ShortString;
      TypeData: PTypeData;
      var MethodIsCompatible,MethodIsPublished,IdentIsMethod: boolean):boolean;
    function OnPropHookCreateMethod(const AMethodName:ShortString;
      ATypeInfo:PTypeInfo): TMethod;
    procedure OnPropHookShowMethod(const AMethodName:ShortString);
    procedure OnPropHookRenameMethod(const CurName, NewName:ShortString);

    // Environment options dialog events
    procedure OnLoadEnvironmentSettings(Sender: TObject; 
       TheEnvironmentOptions: TEnvironmentOptions);
    procedure OnSaveEnvironmentSettings(Sender: TObject; 
       TheEnvironmentOptions: TEnvironmentOptions);
       
    // CodeToolBoss events
    procedure OnBeforeCodeToolBossApplyChanges(Manager: TCodeToolManager;
                                    var Abort: boolean);
    procedure OnAfterCodeToolBossApplyChanges(Manager: TCodeToolManager);
    
    // Debugger events
    procedure OnDebuggerChangeState(Sender: TObject);
    procedure OnDebuggerCurrentLine(Sender: TObject; 
       const ALocation: TDBGLocationRec);
    Procedure OnDebuggerWatchChanged(Sender : TObject);
    
    // MessagesView events
    procedure MessagesViewSelectionChanged(sender : TObject);

    // Hint Timer events
    Procedure HintTimer1Timer(Sender : TObject);
    
    // Watch Dialog events
    Procedure OnWatchAdded(Sender : TObject; AnExpression : String);
    
    // External Tools events
    procedure OnExtToolNeedsOutputFilter(var OutputFilter: TOutputFilter;
                                         var Abort: boolean);
    procedure OnExtToolFreeOutputFilter(OutputFilter: TOutputFilter;
                                        ErrorOccurred: boolean);

  private
    FHintSender : TObject;
    FCodeLastActivated : Boolean; //used for toggling between code and forms
    FLastFormActivated : TCustomForm;  //used to find the last form so you can display the correct tab
    FSelectedComponent : TRegisteredComponent;
    fProject: TProject;
    MacroList: TTransferMacroList;
    FMessagesViewBoundsRectValid: boolean;
    FOpenEditorsOnCodeToolChange: boolean;
    FBreakPoints: TDBGBreakPoints; // Points to debugger breakpoints if available
                                   // Else to own objet
    FDebugger: TDebugger;
    FRunProcess: TProcess; // temp solution, will be replaced by dummydebugger
    TheCompiler: TCompiler;
    TheOutputFilter: TOutputFilter;

    Function CreateSeperator : TMenuItem;
    Procedure SetDefaultsForForm(aForm : TCustomForm);

  protected
    procedure ToolButtonClick(Sender : TObject);
    Procedure AddWatch(const AnExpression : String);
  public
    ToolStatus: TIDEToolStatus;
 
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadMainMenu;
    procedure LoadSpeedbuttons;


    // files/units
    function DoNewEditorUnit(NewUnitType:TNewUnitType;
        const NewFilename: string):TModalResult;
    function DoSaveEditorUnit(PageIndex:integer;
        SaveAs, SaveToTestDir, ProjectSaving:boolean):TModalResult;
    function DoCloseEditorUnit(PageIndex:integer;
        SaveFirst: boolean):TModalResult;
    function DoOpenEditorFile(const AFileName:string;
        ProjectLoading, OnlyIfExists:boolean):TModalResult;
    function DoOpenFileAtCursor(Sender: TObject):TModalResult;
    function DoSaveAll: TModalResult;
    function DoOpenMainUnit(ProjectLoading: boolean): TModalResult;
    function DoViewUnitsAndForms(OnlyForms: boolean): TModalResult;
    
    // project(s)
    property Project: TProject read fProject write fProject;
    function DoNewProject(NewProjectType:TProjectType):TModalResult;
    function DoSaveProject(SaveAs,SaveToTestDir:boolean):TModalResult;
    function DoCloseProject:TModalResult;
    function DoOpenProjectFile(AFileName:string):TModalResult;
    function DoAddActiveUnitToProject: TModalResult;
    function DoRemoveFromProjectDialog: TModalResult;
    function DoBuildProject(BuildAll: boolean): TModalResult;
    function DoInitProjectRun: TModalResult;
    function DoRunProject: TModalResult;
    function DoPauseProject: TModalResult;
    function DoStepIntoProject: TModalResult;
    function DoStepOverProject: TModalResult;
    function DoRunToCursor: TModalResult;
    function DoStopProject: TModalResult;
    function SomethingOfProjectIsModified: boolean;
    function DoCreateProjectForProgram(ProgramBuf: TCodeBuffer): TModalResult;
    function DoSaveProjectToTestDirectory: TModalResult;
    
    // external tools
    function DoRunExternalTool(Index: integer): TModalResult;
    function DoBuildLazarus: TModalResult;

    // useful methods
    procedure GetCurrentUnit(var ActiveSourceEditor:TSourceEditor; 
      var ActiveUnitInfo:TUnitInfo);
    procedure DoSwitchToFormSrc(var ActiveSourceEditor:TSourceEditor;
      var ActiveUnitInfo:TUnitInfo);
    procedure GetUnitWithPageIndex(PageIndex:integer; 
      var ActiveSourceEditor:TSourceEditor; var ActiveUnitInfo:TUnitInfo);
    function DoSaveStreamToFile(AStream:TStream; const Filename:string; 
      IsPartOfProject:boolean): TModalResult;
    function DoLoadMemoryStreamFromFile(MemStream: TMemoryStream; 
      const AFilename:string): TModalResult;
    function DoSaveCodeBufferToFile(ABuffer: TCodeBuffer;
      const AFilename: string; IsPartOfProject:boolean): TModalResult;
    function DoLoadCodeBuffer(var ACodeBuffer: TCodeBuffer; 
      const AFilename: string; UpdateFromDisk, Revert, 
      CheckIfText: boolean): TModalResult;
    function DoBackupFile(const Filename:string; 
      IsPartOfProject:boolean): TModalResult;
    procedure UpdateCaption;
    procedure UpdateDefaultPascalFileExtensions;
    
    // methods for codetools
    procedure InitCodeToolBoss;
    function BeginCodeTool(var ActiveSrcEdit: TSourceEditor;
      var ActiveUnitInfo: TUnitInfo; SwitchToFormSrc: boolean): boolean;
    function DoJumpToCodePos(ActiveSrcEdit: TSourceEditor;
      ActiveUnitInfo: TUnitInfo;
      NewSource: TCodeBuffer; NewX, NewY, NewTopLine: integer;
      AddJumpPoint: boolean): TModalResult;
    procedure SaveSourceEditorChangesToCodeCache;
    procedure ApplyCodeToolChanges;
    procedure DoJumpToProcedureSection;
    procedure DoFindDeclarationAtCursor;
    procedure DoCompleteCodeAtCursor;
    procedure DoJumpToCodeToolBossError;
    function DoCheckSyntax: TModalResult;
    procedure DoGoToPascalBlockOtherEnd;
    procedure DoGoToPascalBlockStart;
    procedure DoJumpToGuessedUnclosedBlock(FindNext: boolean);
    
    // methods for debugging, compiling and external tools
    function DoJumpToCompilerMessage(Index:integer;
      FocusEditor: boolean): boolean;
    function DoInitDebugger: TModalResult;
    procedure DoShowMessagesView;
    procedure DoArrangeSourceEditorAndMessageView;
    function GetProjectTargetFilename: string;
    function GetTestProjectFilename: string;
    function GetTestUnitFilename(AnUnitInfo: TUnitInfo): string;
    procedure OnMacroSubstitution(TheMacro: TTransferMacro; var s:string;
      var Handled, Abort: boolean);
    function OnMacroPromptFunction(const s:string; var Abort: boolean):string;
    procedure OnCmdLineCreate(var CmdLine: string; var Abort:boolean);

    // form editor and designer
    property SelectedComponent : TRegisteredComponent 
      read FSelectedComponent write FSelectedComponent;
    procedure OnDesignerGetSelectedComponentClass(Sender: TObject;
      var RegisteredComponent: TRegisteredComponent);
    procedure OnDesignerUnselectComponentClass(Sender: TObject);
    procedure OnDesignerSetDesigning(Sender: TObject; Component: TComponent;
      Value: boolean);
    procedure OnDesignerComponentListChanged(Sender: TObject);
    procedure OnDesignerPropertiesChanged(Sender: TObject);
    procedure OnDesignerAddComponent(Sender: TObject; Component: TComponent;
      ComponentClass: TRegisteredComponent);
    procedure OnDesignerRemoveComponent(Sender: TObject; Component: TComponent);
    procedure OnDesignerModified(Sender: TObject);
    Procedure OnDesignerActivated(Sender : TObject);
    procedure OnControlSelectionChanged(Sender: TObject);
    procedure DoBringToFrontFormOrUnit;
    procedure SetDesigning(Control : TComponent; Value : Boolean);

    // editor and environment options
    procedure SaveEnvironment;
    procedure SaveDesktopSettings(TheEnvironmentOptions: TEnvironmentOptions);
    procedure LoadDesktopSettings(TheEnvironmentOptions: TEnvironmentOptions);
  end;



const
  CapLetters = ['A'..'Z'];
  SmallLetters = ['a'..'z'];
  Numbers = ['0'..'1'];

var
  MainIDE : TMainIDE;

  ObjectInspector1 : TObjectInspector;
  PropertyEditorHook1 : TPropertyEditorHook;
  SourceNotebook : TSourceNotebook;


implementation

uses
  ViewUnit_dlg, Math, LResources, Designer;


function LoadPixmapRes(const ResourceName:string; PixMap:TPixMap):boolean;
// this function is obsolete -> TPixmap can do it itself
var
  ms:TMemoryStream;
  res:TLResource;
begin
  Result:=false;
  res:=LazarusResources.Find(ResourceName);
  if (res<>nil) and (res.Value<>'') and (res.ValueType='XPM') then begin
    ms:=TMemoryStream.Create;
    try
      ms.Write(res.Value[1],length(res.Value));
      ms.Position:=0;
      Pixmap.LoadFromStream(ms);
      Result:=true;
    finally
      ms.Free;
    end;
  end;
end;

function LoadSpeedBtnPixMap(const ResourceName:string):TPixmap;
begin
  Result:=TPixmap.Create;
  Result.TransparentColor:=clBtnFace;
  if not LoadPixmapRes(ResourceName,Result) then
    LoadPixmapRes('default',Result);
end;


{ TMainIDE }


constructor TMainIDE.Create(AOwner: TComponent);
const
  PrimaryConfPathOpt='--primary-config-path=';
  SecondaryConfPathOpt='--secondary-config-path=';
var
  i,x : Integer;
  PageCount : Integer;
  RegComp     : TRegisteredComponent;
  RegCompPage : TRegisteredComponentPage;
  IDEComponent : TIdeComponent;
  SelectionPointerPixmap: TPixmap;
begin
  inherited Create(AOwner);

  // parse command line options
  for i:=1 to ParamCount do begin
    if copy(ParamStr(i),1,length(PrimaryConfPathOpt))=PrimaryConfPathOpt then
    begin
      SetPrimaryConfigPath(copy(ParamStr(i),length(PrimaryConfPathOpt)+1,
               length(ParamStr(i))));
    end;
    if copy(ParamStr(i),1,length(SecondaryConfPathOpt))=SecondaryConfPathOpt
    then begin
      SetSecondaryConfigPath(copy(ParamStr(i),length(SecondaryConfPathOpt)+1,
               length(ParamStr(i))));
    end;
  end;

  // load environment, miscellaneous and editor options
  CreatePrimaryConfigPath;

  EnvironmentOptions:=TEnvironmentOptions.Create;
  with EnvironmentOptions do begin
    SetLazarusDefaultFilename;
    Load(false);
    if EnvironmentOptions.CompilerFilename='' then
      EnvironmentOptions.CompilerFilename:=FindDefaultCompilerPath;
    ExternalTools.OnNeedsOutputFilter:=@OnExtToolNeedsOutputFilter;
    ExternalTools.OnFreeOutputFilter:=@OnExtToolFreeOutputFilter;
  end;
  UpdateDefaultPascalFileExtensions;

  EditorOpts:=TEditorOptions.Create;
  EditorOpts.Load;
  
  EnvironmentOptions.ExternalTools.LoadShortCuts(EditorOpts.KeyMap);
  
  MiscellaneousOptions:=TMiscellaneousOptions.Create;
  MiscellaneousOptions.Load;
  
  CodeToolsOpts:=TCodeToolsOptions.Create;
  with CodeToolsOpts do begin
    SetLazarusDefaultFilename;
    Load;
  end;

  // set the IDE mode to none (= editing mode)
  ToolStatus:=itNone;

  // setup the code tools
  InitCodeToolBoss;

  // build and position the MainIDE form
  Name := 'MainIDE';
  if (EnvironmentOptions.SaveWindowPositions) 
  and (EnvironmentOptions.WindowPositionsValid) 
  then begin
    BoundsRect := EnvironmentOptions.MainWindowBounds;
  end 
  else begin
    Left := 0;
    Top := 0;
    Width := Screen.Width - 10;
    Height := 125;
  end;
  Position:= poDesigned;

  if LazarusResources.Find(ClassName)=nil then begin
    LoadMainMenu;
    LoadSpeedbuttons;
  end;

  // Component Notebook
  ComponentNotebook := TNotebook.Create(Self);
  with ComponentNotebook do begin
    Parent := Self;
    Name := 'ComponentNotebook';
//    Align := alBottom;
    Left := ToggleFormSpeedBtn.Left + ToggleFormSpeedBtn.Width + 4;
//    Top :=50+ 2;
    Top := 0;
    Width := Self.ClientWidth - Left;
    Height := 60; //Self.ClientHeight - ComponentNotebook.Top;
    OnMouseMove := @MainMouseMoved;

  end;

  PageCount := 0;
  for I := 0 to RegCompList.PageCount-1 do begin
    // Component Notebook Pages
    RegCompPage := RegCompList.Pages[i];
    if RegCompPage.Name <> '' then
    Begin
      if (PageCount = 0) then
        ComponentNotebook.Pages.Strings[PageCount] := RegCompPage.Name
      else
        ComponentNotebook.Pages.Add(RegCompPage.Name);
      GlobalMouseSpeedButton := TSpeedButton.Create(Self);
      SelectionPointerPixmap:=LoadSpeedBtnPixMap('tmouse');
      with GlobalMouseSpeedButton do
      Begin
        Parent := ComponentNotebook.Page[PageCount];
        Parent.OnMouseMove := @MainMouseMoved;  //this is for the hints
        Enabled := True;
        Width := 26;
        Height := 26;
        OnClick := @ControlClick;
        Glyph := SelectionPointerPixmap;
        Visible := True;
        Flat := True;
        Down := True;
        Name := 'GlobalMouseSpeedButton'+IntToStr(PageCount);
        Hint := 'Selection tool';
        OnMouseMove := @MainMouseMoved;
      end;
      for x := 0 to RegCompPage.Count-1 do //for every component on the page....
      begin
        RegComp := RegCompPage.Items[x];
        IDEComponent := TIDEComponent.Create;
        IDEComponent.RegisteredComponent := RegComp;
        IDEComponent._SpeedButton(Self,ComponentNotebook.Page[PageCount]);
        IDEComponent.SpeedButton.OnClick := @ControlClick;
        IDEComponent.SpeedButton.OnMouseMove := @MainMouseMoved;
        IDEComponent.SpeedButton.Hint := RegComp.ComponentClass.ClassName;
        IDEComponent.SpeedButton.Name := IDEComponent.SpeedButton.Hint;
        IDEComponent.SpeedButton.ShowHint := True;
        IDECompList.Add(IDEComponent);
      end;
      inc(PageCount);
    end;
  end;
  ComponentNotebook.PageIndex := 0;   // Set it to the first page
  ComponentNotebook.OnPageChanged := @ControlClick;
  ComponentNotebook.Show;

  // output filter
  TheOutputFilter:=TOutputFilter.Create;

  // compiler interface
  TheCompiler := TCompiler.Create;
  with TheCompiler do begin
    OnCommandLineCreate:=@OnCmdLineCreate;
    OutputFilter:=TheOutputFilter;
  end;

  HintTimer1 := TTimer.Create(self);
  with HintTimer1 do
    Begin
      Name:='HintTimer1';
      Enabled := False;
      Interval := 500;
      OnTimer := @HintTimer1Timer;
    end;
    
  HintWindow1 := THintWindow.Create(nil);
  HIntWindow1.Visible := False;
  HintWindow1.Caption := '';
  HintWindow1.AutoHide := False;

  // MainIDE form events
  OnShow := @FormShow;
  OnClose := @FormClose;
  OnCloseQuery := @FormCloseQuery;
  
  OnMouseMOve := @MainMouseMoved;
  OnMouseDown := @MainMouseDown;
  OnKeyDown := @MainKeyDown;
  // object inspector
  ObjectInspector1 := TObjectInspector.Create(Self);
  if (EnvironmentOptions.SaveWindowPositions) 
  and (EnvironmentOptions.WindowPositionsValid) then begin
    with EnvironmentOptions.ObjectInspectorOptions do
      ObjectInspector1.SetBounds(Left,Top,Width,Height);
  end else begin
    ObjectInspector1.SetBounds(
      0,Top+Height+30,230,Max(Screen.Height-Top-Height-120,50));
  end;
  ObjectInspector1.OnAddAvailComponent:=@OIOnAddAvailableComponent;
  ObjectInspector1.OnSelectComponentInOI:=@OIOnSelectComponent;
  PropertyEditorHook1:=TPropertyEditorHook.Create;
  {$IFDEF TestEvents}
  PropertyEditorHook1.OnGetMethods:=@OnPropHookGetMethods;
  PropertyEditorHook1.OnMethodExists:=@OnPropHookMethodExists;
  PropertyEditorHook1.OnCreateMethod:=@OnPropHookCreateMethod;
  PropertyEditorHook1.OnShowMethod:=@OnPropHookShowMethod;
  PropertyEditorHook1.OnRenameMethod:=@OnPropHookRenameMethod;
  {$ENDIF}
  ObjectInspector1.PropertyEditorHook:=PropertyEditorHook1;
  ObjectInspector1.Show;

  // create formeditor
  FormEditor1 := TFormEditor.Create;
  FormEditor1.Obj_Inspector := ObjectInspector1;

  // source editor / notebook
  SourceNotebook := TSourceNotebook.Create(Self);
  SourceNotebook.OnActivate := @OnSrcNoteBookActivated;
  SourceNotebook.OnAddJumpPoint := @OnSrcNoteBookAddJumpPoint;
  SourceNotebook.OnCloseClicked := @OnSrcNotebookFileClose;
  SourceNotebook.OnDeleteLastJumpPoint := @OnSrcNotebookDeleteLastJumPoint;
  SourceNotebook.OnEditorVisibleChanged := @OnSrcNotebookEditorVisibleChanged;
  SourceNotebook.OnEditorChanged := @OnSrcNotebookEditorChanged;
  SourceNotebook.OnJumpToHistoryPoint := @OnSrcNotebookJumpToHistoryPoint;
  SourceNotebook.OnNewClicked := @OnSrcNotebookFileNew;
  SourceNotebook.OnOpenClicked := @OnSrcNotebookFileOpen;
  SourceNotebook.OnOpenFileAtCursorClicked := @OnSrcNotebookFileOpenAtCursor;
  SourceNotebook.OnFindDeclarationClicked := @OnSrcNotebookFindDeclaration;
  SourceNotebook.OnProcessUserCommand := @OnSrcNotebookProcessCommand;
  SourceNotebook.OnSaveClicked := @OnSrcNotebookFileSave;
  SourceNotebook.OnSaveAsClicked := @OnSrcNotebookFileSaveAs;
  SourceNotebook.OnSaveAllClicked := @OnSrcNotebookSaveAll;
  SourceNotebook.OnShowUnitInfo := @OnSrcNoteBookShowUnitInfo;
  SourceNotebook.OnToggleFormUnitClicked := @OnSrcNotebookToggleFormUnit;
  SourceNotebook.OnViewJumpHistory := @OnSrcNotebookViewJumpHistory;
  SourceNotebook.OnAddWatchAtCursor := @OnSrcNotebookAddWatchesAtCursor;
  SourceNotebook.OnCreateBreakPoint := @OnSrcNotebookCreateBreakPoint;
  SourceNotebook.OnDeleteBreakPoint := @OnSrcNotebookDeleteBreakPoint;

  // search menus
  itmSearchFind.OnClick := @SourceNotebook.FindClicked;
  itmSearchFindNext.OnClick := @SourceNotebook.FindNextClicked;
  itmSearchFindPrevious.OnClick := @SourceNotebook.FindPreviousClicked;
  itmSearchFindInFiles.OnClick := @SourceNotebook.FindInFilesClicked;
  itmSearchReplace.OnClick := @SourceNotebook.ReplaceClicked;
  itmGotoLine.OnClick := @SourceNotebook.GotoLineClicked;
  itmJumpBack.OnClick := @SourceNotebook.JumpBackClicked;
  itmJumpForward.OnClick := @SourceNotebook.JumpForwardClicked;
  itmAddJumpPoint.OnClick := @SourceNotebook.AddJumpPointClicked;
  itmJumpHistory.OnClick := @SourceNotebook.ViewJumpHistoryClicked;

  // message view
  FMessagesViewBoundsRectValid:=false;

  // macros
  MacroList:=TTransferMacroList.Create;
  MacroList.Add(TTransferMacro.Create('Col','',
                    'Cursor column in current editor',nil,[]));
  MacroList.Add(TTransferMacro.Create('Row','',
                    'Cursor row in current editor',nil,[]));
  MacroList.Add(TTransferMacro.Create('CompPath','',
                    'Compiler filename',nil,[]));
  MacroList.Add(TTransferMacro.Create('CurToken','',
                    'Word at cursor in current editor',nil,[]));
  MacroList.Add(TTransferMacro.Create('EdFile','',
                    'Expanded filename of current editor file',nil,[]));
  MacroList.Add(TTransferMacro.Create('FPCSrcDir','',
                    'Freepascal source directory',nil,[]));
  MacroList.Add(TTransferMacro.Create('LazarusDir','',
                    'Lazarus directory',nil,[]));
  MacroList.Add(TTransferMacro.Create('LCLWidgetType','',
                    'LCL Widget Type',nil,[]));
  MacroList.Add(TTransferMacro.Create('Params','',
                    'Command line parameters of program',nil,[]));
  MacroList.Add(TTransferMacro.Create('Prompt','',
                    'Prompt for value',@OnMacroPromptFunction,[tmfInteractive]));
  MacroList.Add(TTransferMacro.Create('ProjFile','',
                    'Project filename',nil,[]));
  MacroList.Add(TTransferMacro.Create('ProjPath','',
                    'Project directory',nil,[]));
  MacroList.Add(TTransferMacro.Create('Save','',
                    'save current editor file',nil,[tmfInteractive]));
  MacroList.Add(TTransferMacro.Create('SaveAll','',
                    'save all modified files',nil,[tmfInteractive]));
  MacroList.Add(TTransferMacro.Create('TargetFile','',
                    'Target filename of project',nil,[]));
  MacroList.OnSubstitution:=@OnMacroSubstitution;
  
  //twatcheslgd
  Watches_Dlg := TWatchesDlg.Create(Self);
  Watches_Dlg.OnWatchAddedEvent := @OnWatchAdded;


  //TBreakPointsDlg
  BreakPoints_Dlg := TBreakPointsDlg.Create(Self);

  FDebugger := nil;
  FBreakPoints := TDBGBreakPoints.Create(nil, TDBGBreakPoint);
  
  // control selection (selected components on edited form)
  TheControlSelection:=TControlSelection.Create;
  TheControlSelection.OnChange:=@OnControlSelectionChanged;

writeln('TMainIDE.Create A ***********');
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  // load command line project or last project or create a new project
  if (ParamCount>0) and (ParamStr(ParamCount)[1]<>'-')
  and (ExtractFileExt(ParamStr(ParamCount))='.lpi')
  and (DoOpenProjectFile(ParamStr(ParamCount))=mrOk) then
    // command line project loaded
  else if (EnvironmentOptions.OpenLastprojectAtStart)
  and (FileExists(EnvironmentOptions.LastSavedProjectFile)) 
  and (DoOpenProjectFile(EnvironmentOptions.LastSavedProjectFile)=mrOk) then
  begin
    // last project loaded
writeln('TMainIDE.Create last project loaded successfully');
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  end else
    // create new project
    DoNewProject(ptApplication);
    
writeln('TMainIDE.Create B');
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
end;

destructor TMainIDE.Destroy;
begin
writeln('[TMainIDE.Destroy] A');
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  if FDebugger <> nil
  then FDebugger.Done;
  
  if Project<>nil then begin
    Project.Free;
    Project:=nil;
  end;
  FBreakPoints.Free;
  FBreakPoints:=nil;
  if TheControlSelection<>nil then begin
    TheControlSelection.OnChange:=nil;
    TheControlSelection.Free;
    TheControlSelection:=nil;
  end;
  FormEditor1.Free;
  FormEditor1:=nil;
  PropertyEditorHook1.Free;
  TheCompiler.Free;
  TheOutputFilter.Free;
  MacroList.Free;
  CodeToolsOpts.Free;
  CodeToolsOpts:=nil;
  MiscellaneousOptions.Free;
  MiscellaneousOptions:=nil;
  EditorOpts.Free;
  EditorOpts:=nil;
  EnvironmentOptions.Free;
  EnvironmentOptions:=nil;
  HIntTimer1.Free;
  HintWindow1.Free;
  Watches_Dlg.Free;
  FDebugger.Free;
  FDebugger := nil;
  
writeln('[TMainIDE.Destroy] B  -> inherited Destroy...');
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  inherited Destroy;
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
writeln('[TMainIDE.Destroy] END');
end;

procedure TMainIDE.OIOnAddAvailableComponent(AComponent:TComponent;
var Allowed:boolean);
begin
  //Allowed:=(not (AComponent is TGrabber));
end;

procedure TMainIDE.OIOnSelectComponent(AComponent:TComponent);
begin
  with TheControlSelection do begin
    BeginUpdate;
    Clear;
    Add(AComponent);
    EndUpdate;
  end;
  if AComponent.Owner is TControl then
    TControl(AComponent.Owner).Invalidate;
end;

procedure TMainIDE.OnPropHookGetMethods(TypeData:PTypeData;
  Proc:TGetStringProc);
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
begin
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,true) then exit;
{$IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.OnPropHookGetMethods] ************');
{$ENDIF}
  if not CodeToolBoss.GetCompatiblePublishedMethods(ActiveUnitInfo.Source,
    ActiveUnitInfo.Form.ClassName,TypeData,Proc) then
  begin
    DoJumpToCodeToolBossError;
  end;
end;

Procedure TMainIDE.ToolButtonClick(Sender : TObject);
Begin
  Assert(False, 'Trace:TOOL BUTTON CLICK!');

end;

Procedure TMainIDE.FormPaint(Sender : TObject);
begin

end;

{------------------------------------------------------------------------------}
procedure TMainIDE.FormShow(Sender : TObject);
Begin

end;

procedure TMainIDE.FormClose(Sender : TObject; var Action: TCloseAction);
begin
  SaveEnvironment;
  if TheControlSelection<>nil then TheControlSelection.Clear;
  if SourceNoteBook<>nil then SourceNoteBook.ClearUnUsedEditorComponents(true);
end;

procedure TMainIDE.FormCloseQuery(Sender : TObject; var CanClose: boolean);
Begin
writeln('[TMainIDE.FormCloseQuery]');
  CanClose:=true;

  if SomethingOfProjectIsModified then begin
    if (Application.MessageBox('Save changes to project?','Project changed', MB_IconQuestion+mb_YesNo))=mrYes then
    begin
      CanClose:=DoSaveProject(false,false)<>mrAbort;
      if CanClose=false then exit;
    end;
  end;

  CanClose:=(DoCloseProject<>mrAbort);
End;

{------------------------------------------------------------------------------}
type 
  TMoveFlags = set of (mfTop, mfLeft);

procedure TMainIDE.LoadSpeedbuttons;
  
  function CreateButton(const AName, APixName: String; ANumGlyphs: Integer;
    var ALeft, ATop: Integer; const AMoveFlags: TMoveFlags;
    const AOnClick: TNotifyEvent; AHint : String): TSpeedButton;
  begin
    Result := TSpeedButton.Create(Self);
    with Result do
    begin
      Name := AName;
      Parent := pnlSpeedButtons;
//      Parent := Self;
      Enabled := True;
      Top := ATop;
      Left := ALeft;
      OnClick := AOnClick;
      Glyph := LoadSpeedBtnPixMap(APixName);
      NumGlyphs := ANumGlyphs;
      Flat := True;
      //Transparent:=True;
      if mfTop in AMoveFlags then Inc(ATop, Height + 1);
      if mfLeft in AMoveFlags then Inc(ALeft, Width + 1);
      Hint := AHint;
      OnMouseMove := @MainMouseMoved;
//writeln('---- W=',Width,',',Height,' Transparent=',Transparent);
      Visible := True;
    end;
  end;
var
  ButtonTop, ButtonLeft, n: Integer;

begin

  pnlSpeedButtons := TPanel.Create(Self);
  pnlSpeedButtons.Parent:= Self;
  with pnlSpeedButtons do begin
    Visible := True;
    Name := 'pnlSpeedButtons';
    Top := 0;
    Left:= 0;
//    Width:= 160;
//    Height:= 60;
    Caption:= '';
  end;


  ButtonTop := 1;
  ButtonLeft := 1;
  NewUnitSpeedBtn       := CreateButton('NewUnitSpeedBtn'      , 'btn_newunit'   , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuNewUnitClicked, 'New Unit');

  OpenFileSpeedBtn      := CreateButton('OpenFileSpeedBtn'     , 'btn_openfile'  , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuOpenClicked, 'Open');

  // store left
  n := ButtonLeft;
  OpenFileArrowSpeedBtn := CreateButton('OpenFileArrowSpeedBtn', 'btn_downarrow' , 1, ButtonLeft, ButtonTop, [mfLeft], @OpenFileDownArrowClicked, '');
  OpenFileArrowSpeedBtn.Width := 12;
  ButtonLeft := n+12+1;
  
  SaveSpeedBtn          := CreateButton('SaveSpeedBtn'         , 'btn_save'      , 2, ButtonLeft, ButtonTop, [mfLeft], @mnuSaveClicked, 'Save');
  SaveAllSpeedBtn       := CreateButton('SaveAllSpeedBtn'      , 'btn_saveall'   , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuSaveAllClicked, 'Save all');
  NewFormSpeedBtn       := CreateButton('NewFormSpeedBtn'      , 'btn_newform'   , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuNewFormClicked, 'New Form');
  ToggleFormSpeedBtn    := CreateButton('ToggleFormSpeedBtn'   , 'btn_toggleform', 2, ButtonLeft, ButtonTop, [mfLeft, mfTop], @mnuToggleFormUnitCLicked, 'Toggle Form/Unit');

// new row
  ButtonLeft := 1;
  ViewUnitsSpeedBtn     := CreateButton('ViewUnitsSpeedBtn'    , 'btn_viewunits' , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuViewUnitsClicked, 'View Units');
  ViewFormsSpeedBtn     := CreateButton('ViewFormsSpeedBtn'    , 'btn_viewforms' , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuViewFormsClicked, 'View Forms');
  inc(ButtonLeft,13);
  RunSpeedButton        := CreateButton('RunSpeedButton'       , 'btn_run'       , 2, ButtonLeft, ButtonTop, [mfLeft], @mnuRunProjectClicked, 'Run');
  PauseSpeedButton      := CreateButton('PauseSpeedButton'     , 'btn_pause'       , 2, ButtonLeft, ButtonTop, [mfLeft], @mnuPauseProjectClicked, 'Pause');
  PauseSpeedButton.Enabled:=false;
  StepIntoSpeedButton  := CreateButton('StepIntoSpeedButton'   , 'btn_stepinto'       , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuStepIntoProjectClicked, 'Step Into');
  StepOverSpeedButton  := CreateButton('StepOverpeedButton'   , 'btn_stepover'       , 1, ButtonLeft, ButtonTop, [mfLeft, mfTop], @mnuStepOverProjectClicked, 'Step Over');
  
  pnlSpeedButtons.Width := ButtonLeft+1;
  pnlSpeedButtons.Height := ButtonTop+1;
  

  // create the popupmenu for the OpenFileArrowSpeedBtn
  OpenFilePopUpMenu := TPopupMenu.Create(self);
  OpenFilePopupMenu.Name:='OpenFilePopupMenu';
  OpenFilePopupMenu.AutoPopup := False;
{ 
  MenuItem := TMenuItem.Create(Self);
  MenuItem.Caption := 'No files have been opened';
  MenuItem.OnClick := nil;
  OpenFilePopupMenu.Items.Add(MenuItem);
}
end;


{------------------------------------------------------------------------------}
procedure TMainIDE.LoadMainMenu;

  procedure AddRecentSubMenu(ParentMenuItem: TMenuItem; FileList: TStringList;
    OnClickEvent: TNotifyEvent);
  var i: integer;
    NewMenuItem: TMenuItem;
  begin
    for i:=0 to FileList.Count-1 do begin
      NewMenuItem:= TMenuItem.Create(Self);
      NewMenuItem.Name:=ParentMenuItem.Name+'Recent'+IntToStr(i);
      NewMenuItem.Caption := FileList[i];
      NewMenuItem.OnClick := OnClickEvent;
      ParentMenuItem.Add(NewMenuItem);
    end;
  end;

begin

//--------------
// The Menu
//--------------

  mnuMain := TMainMenu.Create(Self);
  mnuMain.Name:='mnuMainMenu';
  Menu := mnuMain;

//--------------
// Main menu
//--------------

  mnuFile := TMenuItem.Create(Self);
  mnuFile.Name:='mnuFile';
  mnuFile.Caption := '&File';
  mnuMain.Items.Add(mnuFile);

  mnuEdit := TMenuItem.Create(Self);
  mnuEdit.Name:='mnuEdit';
  mnuEdit.Caption := '&Edit';
  mnuMain.Items.Add(mnuEdit);

  mnuSearch := TMenuItem.Create(Self);
  mnuSearch.Name:='mnuSearch';
  mnuSearch.Caption := '&Search';
  mnuMain.Items.Add(mnuSearch);

  mnuView := TMenuItem.Create(Self);
  mnuView.Name:='mnuView';
  mnuView.Caption := '&View';
  mnuMain.Items.Add(mnuView);

  mnuProject := TMenuItem.Create(Self);
  mnuProject.Name:='mnuProject';
  mnuProject.Caption := '&Project';
  mnuMain.Items.Add(mnuProject);

  mnuRun := TMenuItem.Create(Self);
  mnuRun.Name:='mnuRun';
  mnuRun.Caption := '&Run';
  mnuMain.Items.Add(mnuRun);

  mnuTools := TMenuItem.Create(Self);
  mnuTools.Name:='mnuTools';
  mnuTools.Caption := '&Tools';
  mnuMain.Items.Add(mnuTools);

  mnuEnvironment := TMenuItem.Create(Self);
  mnuEnvironment.Name:='mnuEnvironment';
  mnuEnvironment.Caption := 'E&nvironment';
  mnuMain.Items.Add(mnuEnvironment);

  mnuHelp := TMenuItem.Create(Self);
  mnuHelp.Name:='mnuHelp';
  mnuHelp.Caption := '&Help';
  mnuMain.Items.Add(mnuHelp);

//--------------
// File
//--------------
  
  itmFileNew := TMenuItem.Create(Self);
  itmFileNew.Name:='itmFileNew';
  itmFileNew.Caption := 'New Unit';
  itmFileNew.OnClick := @mnuNewUnitClicked; // ToDo:  new dialog
  mnuFile.Add(itmFileNew);

  itmFileNewForm := TMenuItem.Create(Self);
  itmFileNewForm.Name:='itmFileNewForm';
  itmFileNewForm.Caption := 'New Form';
  itmFileNewForm.OnClick := @mnuNewFormClicked;
  mnuFile.Add(itmFileNewForm);

  mnuFile.Add(CreateSeperator);

  itmFileOpen := TMenuItem.Create(Self);
  itmFileOpen.Name:='itmFileOpen';
  itmFileOpen.Caption := 'Open';
  itmFileOpen.OnClick := @mnuOpenClicked;
  mnuFile.Add(itmFileOpen);

  itmFileRecentOpen := TMenuItem.Create(Self);
  itmFileRecentOpen.Name:='itmFileRecentOpen';
  itmFileRecentOpen.Caption := 'Open Recent';
  mnuFile.Add(itmFileRecentOpen);
  
  AddRecentSubMenu(itmFileRecentOpen,EnvironmentOptions.RecentOpenFiles,
                    @mnuOpenClicked);

  itmFileSave := TMenuItem.Create(Self);
  itmFileSave.Name:='itmFileSave';
  itmFileSave.Caption := 'Save';
  itmFileSave.ShortCut:= VK_S or scCtrl;
  itmFileSave.OnClick := @mnuSaveClicked;
  mnuFile.Add(itmFileSave);

  itmFileSaveAs := TMenuItem.Create(Self);
  itmFileSaveAs.Name:='itmFileSaveAs';
  itmFileSaveAs.Caption := 'Save As';
  itmFileSaveAs.OnClick := @mnuSaveAsClicked;
  mnuFile.Add(itmFileSaveAs);

  itmFileSaveAll := TMenuItem.Create(Self);
  itmFileSaveAll.Name:='itmFileSaveAll';
  itmFileSaveAll.Caption := 'Save All';
  itmFileSaveAll.ShortCut:= VK_S or scCtrl or scShift;
  itmFileSaveAll.OnClick := @mnuSaveAllClicked;
  mnuFile.Add(itmFileSaveAll);

  itmFileClose := TMenuItem.Create(Self);
  itmFileClose.Name:='itmFileClose';
  itmFileClose.Caption := 'Close';
  itmFileClose.Enabled := False;
  itmFileClose.OnClick := @mnuCloseClicked;
  mnuFile.Add(itmFileClose);

  mnuFile.Add(CreateSeperator);

  itmFileQuit := TMenuItem.Create(Self);
  itmFileQuit.Name:='itmFileQuit';
  itmFileQuit.Caption := 'Quit';
  itmFileQuit.OnClick := @mnuQuitClicked;
  mnuFile.Add(itmFileQuit);

//--------------
// Edit
//--------------

  itmEditUndo := TMenuItem.Create(nil);
  itmEditUndo.Name:='itmEditUndo';
  itmEditUndo.Caption := 'Undo';
  itmEditUndo.ShortCut:= VK_Z or scCtrl;
  mnuEdit.Add(itmEditUndo);

  itmEditRedo := TMenuItem.Create(nil);
  itmEditRedo.Name:='itmEditRedo';
  itmEditRedo.Caption := 'Redo';
  itmEditRedo.ShortCut:= VK_Z or scCtrl or scShift;
  mnuEdit.Add(itmEditRedo);

  mnuEdit.Add(CreateSeperator);

  itmEditCut  := TMenuItem.Create(nil);
  itmEditCut.Name:='itmEditCut';
  itmEditCut.Caption := 'Cut';
  itmEditCut.Shortcut:= VK_X or scCtrl;
  mnuEdit.Add(itmEditCut);

  itmEditCopy := TMenuItem.Create(nil);
  itmEditCopy.Name:='itmEditCopy';
  itmEditCopy.Caption := 'Copy';
  itmEditCopy.ShortCut:= VK_C or scCtrl;
  mnuEdit.Add(itmEditCopy);

  itmEditPaste := TMenuItem.Create(nil);
  itmEditPaste.Name:='itmEditPaste';
  itmEditPaste.Caption := 'Paste';
  itmEditPaste.Shortcut:= VK_V or scCtrl;
  mnuEdit.Add(itmEditPaste);

//--------------
// Search
//--------------

  itmSearchFind := TMenuItem.Create(nil);
  itmSearchFind.Name:='itmSearchFind';
  itmSearchFind.Caption := 'Find';
  itmSearchFind.ShortCut:= VK_F or scCtrl;
  mnuSearch.add(itmSearchFind);

  itmSearchFindNext := TMenuItem.Create(nil);
  itmSearchFindNext.Name:='itmSearchFindNext';
  itmSearchFindNext.Caption := 'Find &Next';
  itmSearchFindNext.ShortCut:= VK_F3;
  itmSearchFindNext.Enabled := False;
  mnuSearch.add(itmSearchFindNext);

  itmSearchFindPrevious := TMenuItem.Create(nil);
  itmSearchFindPrevious.Name:='itmSearchFindPrevious';
  itmSearchFindPrevious.Caption := 'Find &Previous';
  itmSearchFindPrevious.ShortCut:= VK_F3 or scShift;
  itmSearchFindPrevious.Enabled := False;
  mnuSearch.add(itmSearchFindPrevious);

  itmSearchFindInFiles := TMenuItem.Create(nil);
  itmSearchFindInFiles.Name:='itmSearchFindInFiles';
  itmSearchFindInFiles.Caption := 'Find &in files';
  itmSearchFindInFiles.Enabled := False;
  mnuSearch.add(itmSearchFindInFiles);

  itmSearchReplace := TMenuItem.Create(nil);
  itmSearchReplace.Name:='itmSearchReplace';
  itmSearchReplace.Caption := 'Replace';
  itmSearchReplace.ShortCut:= VK_R or scCtrl;
  mnuSearch.add(itmSearchReplace);

  mnuSearch.Add(CreateSeperator);
  
  itmGotoLine := TMenuItem.Create(nil);
  itmGotoLine.Name:='itmGotoLine';
  itmGotoLine.Caption := 'Goto line';
  itmGotoLine.ShortCut:= VK_G or scAlt;
  mnuSearch.add(itmGotoLine);
  
  mnuSearch.Add(CreateSeperator);
  
  itmJumpBack := TMenuItem.Create(nil);
  itmJumpBack.Name:='itmJumpBack';
  itmJumpBack.Caption := 'Jump back';
  mnuSearch.add(itmJumpBack);
  
  itmJumpForward := TMenuItem.Create(nil);
  itmJumpForward.Name:='itmJumpForward';
  itmJumpForward.Caption := 'Jump forward';
  mnuSearch.add(itmJumpForward);

  itmAddJumpPoint := TMenuItem.Create(nil);
  itmAddJumpPoint.Name:='itmAddJumpPoint';
  itmAddJumpPoint.Caption := 'Add jump point to history';
  mnuSearch.add(itmAddJumpPoint);

  itmJumpHistory := TMenuItem.Create(nil);
  itmJumpHistory.Name:='itmJumpHistory';
  itmJumpHistory.Caption := 'View Jump-History';
  mnuSearch.add(itmJumpHistory);
  
//--------------
// View
//--------------

  itmViewInspector := TMenuItem.Create(Self);
  itmViewInspector.Name:='itmViewInspector';
  itmViewInspector.Caption := 'Object Inspector';
  itmViewInspector.ShortCut := VK_F11;
  itmViewInspector.OnClick := @mnuViewInspectorClicked;
  mnuView.Add(itmViewInspector);

  itmViewProject  := TMenuItem.Create(Self);
  itmViewProject.Name:='itmViewProject';
  itmViewProject.Caption := 'Project Explorer';
  itmViewProject.ShortCut:= VK_F11 or scCtrl or scAlt;
  mnuView.Add(itmViewProject);

  mnuView.Add(CreateSeperator);

  itmViewCodeExplorer := TMenuItem.Create(Self);
  itmViewCodeExplorer.Name:='itmViewCodeExplorer';
  itmViewCodeExplorer.Caption := 'Code Explorer';
  itmViewCodeExplorer.OnClick := @mnuViewCodeExplorerClick;
  mnuView.Add(itmViewCodeExplorer);

  mnuView.Add(CreateSeperator);

  itmViewUnits := TMenuItem.Create(Self);
  itmViewUnits.Name:='itmViewUnits';
  itmViewUnits.Caption := 'Units...';
  itmViewUnits.Shortcut:= VK_F12 or scCtrl;
  itmViewUnits.OnClick := @mnuViewUnitsClicked;
  mnuView.Add(itmViewUnits);

  itmViewForms := TMenuItem.Create(Self);
  itmViewForms.Name:='itmViewForms';
  itmViewForms.Caption := 'Forms...';
  itmViewForms.ShortCut:= VK_F12 or scShift;
  itmViewForms.OnClick := @mnuViewFormsClicked;
  mnuView.Add(itmViewForms);

  mnuView.Add(CreateSeperator);

  itmViewMessage := TMenuItem.Create(Self);
  itmViewMessage.Name:='itmViewMessage';
  itmViewMessage.Caption := 'Messages';
  itmViewMessage.OnClick := @mnuViewMessagesClick;
  mnuView.Add(itmViewMessage);

  itmViewWatches := TMenuItem.Create(Self);
  itmViewWatches.Name:='itmViewWatches';
  itmViewWatches.Caption := 'Watches';
  itmViewWatches.ShortCut:= VK_W or scCtrl or scAlt;
  itmViewWatches.OnClick := @mnuViewWatchesClick;
  mnuView.Add(itmViewWatches);

  itmViewBreakPoints := TMenuItem.Create(Self);
  itmViewBreakPoints.Name:='itmViewBreakPoints';
  itmViewBreakPoints.Caption := 'BreakPoints';
  itmViewBreakPoints.Shortcut := VK_B or scCtrl or scAlt;
  itmViewBreakPoints.OnClick := @mnuViewBreakPointsClick;
  mnuView.Add(itmViewBreakPoints);
//--------------
// Project
//--------------

  itmProjectNew := TMenuItem.Create(Self);
  itmProjectNew.Name:='itmProjectNew';
  itmProjectNew.Caption := 'New Project';
  itmProjectNew.OnClick := @mnuNewProjectClicked;
  mnuProject.Add(itmProjectNew);

  itmProjectOpen := TMenuItem.Create(Self);
  itmProjectOpen.Name:='itmProjectOpen';
  itmProjectOpen.Caption := 'Open Project';
  itmProjectOpen.ShortCut:= VK_F11 or scCtrl;
  itmProjectOpen.OnClick := @mnuOpenProjectClicked;
  mnuProject.Add(itmProjectOpen);

  itmProjectRecentOpen := TMenuItem.Create(Self);
  itmProjectRecentOpen.Name:='itmProjectRecentOpen';
  itmProjectRecentOpen.Caption := 'Open Recent Project';
  mnuProject.Add(itmProjectRecentOpen);
  
  AddRecentSubMenu(itmProjectRecentOpen,EnvironmentOptions.RecentProjectFiles,
                   @mnuOpenProjectClicked);

  itmProjectSave := TMenuItem.Create(Self);
  itmProjectSave.Name:='itmProjectSave';
  itmProjectSave.Caption := 'Save Project';
  itmProjectSave.OnClick := @mnuSaveProjectClicked;
  mnuProject.Add(itmProjectSave);

  itmProjectSaveAs := TMenuItem.Create(Self);
  itmProjectSaveAs.Name:='itmProjectSaveAs';
  itmProjectSaveAs.Caption := 'Save Project As...';
  itmProjectSaveAs.OnClick := @mnuSaveProjectAsClicked;
  mnuProject.Add(itmProjectSaveAs);

  mnuProject.Add(CreateSeperator);

  itmProjectAddTo := TMenuItem.Create(Self);
  itmProjectAddTo.Name:='itmProjectAddTo';
  itmProjectAddTo.Caption := 'Add active unit to Project';
  itmProjectAddTo.ShortCut:= VK_F11 or scShift;
  itmProjectAddTo.OnClick := @mnuAddToProjectClicked;
  mnuProject.Add(itmProjectAddTo);

  itmProjectRemoveFrom := TMenuItem.Create(Self);
  itmProjectRemoveFrom.Name:='itmProjectRemoveFrom';
  itmProjectRemoveFrom.Caption := 'Remove from Project';
  itmProjectRemoveFrom.OnClick := @mnuRemoveFromProjectClicked;
  mnuProject.Add(itmProjectRemoveFrom);

  mnuProject.Add(CreateSeperator);

  itmProjectViewSource := TMenuItem.Create(Self);
  itmProjectViewSource.Name:='itmProjectViewSource';
  itmProjectViewSource.Caption := 'View Source';
  itmProjectViewSource.OnClick := @mnuViewProjectSourceClicked;
  mnuProject.Add(itmProjectViewSource);

  mnuProject.Add(CreateSeperator);

  itmProjectOptions := TMenuItem.Create(Self);
  itmProjectOptions.Name:='itmProjectOptions';
  itmProjectOptions.Caption := 'Project Options...';
  itmProjectOptions.ShortCut:= VK_F11 or scCtrl or scShift;
  itmProjectOptions.OnClick := @mnuProjectOptionsClicked;
  mnuProject.Add(itmProjectOptions);

//--------------
// Run
//--------------

  itmProjectBuild := TMenuItem.Create(Self);
  itmProjectBuild.Name:='itmProjectBuild';
  itmProjectBuild.Caption := 'Build';
  itmProjectBuild.OnClick := @mnuBuildProjectClicked;
  mnuRun.Add(itmProjectBuild);

  itmProjectBuildAll := TMenuItem.Create(Self);
  itmProjectBuildAll.Name:='itmProjectBuildAll';
  itmProjectBuildAll.Caption := 'Build all';
  itmProjectBuildAll.OnClick := @mnuBuildAllProjectClicked;
  mnuRun.Add(itmProjectBuildAll);

  itmProjectRun := TMenuItem.Create(Self);
  itmProjectRun.Name:='itmProjectRun';
  itmProjectRun.Caption := 'Run';
  itmProjectRun.ShortCut:= VK_F9;
  itmProjectRun.OnClick := @mnuRunProjectClicked;
  mnuRun.Add(itmProjectRun);

  itmProjectPause := TMenuItem.Create(Self);
  itmProjectPause.Name:='itmProjectPause';
  itmProjectPause.Caption := 'Pause';
  itmProjectPause.OnClick := @mnuPauseProjectClicked;
  itmProjectPause.Enabled := false;
  mnuRun.Add(itmProjectPause);

  itmProjectStepInto := TMenuItem.Create(Self);
  itmProjectStepInto.Name:='itmProjectStepInto';
  itmProjectStepInto.Caption := 'Step into';
  itmProjectStepInto.ShortCut:= VK_F7;
  itmProjectStepInto.OnClick := @mnuStepIntoProjectClicked;
  mnuRun.Add(itmProjectStepInto);

  itmProjectStepOver := TMenuItem.Create(Self);
  itmProjectStepOver.Name:='itmProjectStepOver';
  itmProjectStepOver.Caption := 'Step over';
  itmProjectStepOver.ShortCut:= VK_F8;
  itmProjectStepOver.OnClick := @mnuStepOverProjectClicked;
  mnuRun.Add(itmProjectStepOver);

  itmProjectRunToCursor := TMenuItem.Create(Self);
  itmProjectRunToCursor.Name:='itmProjectRunToCursor';
  itmProjectRunToCursor.Caption := 'Run to cursor';
  itmProjectRunToCursor.ShortCut:= VK_F4;
  itmProjectRunToCursor.OnClick := @mnuRunToCursorProjectClicked;
  mnuRun.Add(itmProjectRunToCursor);

  itmProjectStop := TMenuItem.Create(Self);
  itmProjectStop.Name:='itmProjectStop';
  itmProjectStop.Caption := 'Stop';
  itmProjectStop.ShortCut:= VK_F2 or scCtrl;
  itmProjectStop.OnClick := @mnuStopProjectClicked;
  mnuRun.Add(itmProjectStop);

  mnuRun.Add(CreateSeperator);

  itmProjectCompilerSettings := TMenuItem.Create(Self);
  itmProjectCompilerSettings.Name:='itmProjectCompilerSettings';
  itmProjectCompilerSettings.Caption := 'Compiler Options...';
  itmProjectCompilerSettings.OnClick := @mnuProjectCompilerSettingsClicked;
  mnuRun.Add(itmProjectCompilerSettings);

  itmProjectRunParameters := TMenuItem.Create(Self);
  itmProjectRunParameters.Name:='itmProjectRunParameters';
  itmProjectRunParameters.Caption := 'Run Parameters ...';
  itmProjectRunParameters.OnClick := @mnuRunParametersClicked;
  mnuRun.Add(itmProjectRunParameters);

//--------------
// Tools
//--------------

  itmToolConfigure := TMenuItem.Create(Self);
  itmToolConfigure.Name:='itmToolConfigure';
  itmToolConfigure.Caption := 'Settings ...';
  itmToolConfigure.OnClick := @mnuToolConfigureClicked;
  mnuTools.Add(itmToolConfigure);

  itmToolSyntaxCheck := TMenuItem.Create(Self);
  itmToolSyntaxCheck.Name:='itmToolSyntaxCheck';
  itmToolSyntaxCheck.Caption := 'Quick syntax check';
  itmToolSyntaxCheck.ShortCut:= VK_Q or scCtrl;
  itmToolSyntaxCheck.OnClick := @mnuToolSyntaxCheckClicked;
  mnuTools.Add(itmToolSyntaxCheck);

  itmToolGuessUnclosedBlockCheck := TMenuItem.Create(Self);
  itmToolGuessUnclosedBlockCheck.Name:='itmToolGuessUnclosedBlockCheck';
  itmToolGuessUnclosedBlockCheck.Caption := 'Guess unclosed block';
  itmToolGuessUnclosedBlockCheck.OnClick := @mnuToolGuessUnclosedBlockClicked;
  mnuTools.Add(itmToolGuessUnclosedBlockCheck);

  itmToolBuildLazarus := TMenuItem.Create(Self);
  itmToolBuildLazarus.Name:='itmToolBuildLazarus';
  itmToolBuildLazarus.Caption := 'Build Lazarus';
  itmToolBuildLazarus.OnClick := @mnuToolBuildLazarusClicked;
  mnuTools.Add(itmToolBuildLazarus);

  itmToolConfigureBuildLazarus := TMenuItem.Create(Self);
  itmToolConfigureBuildLazarus.Name:='itmToolConfigureBuildLazarus';
  itmToolConfigureBuildLazarus.Caption := 'Configure "Build Lazarus"';
  itmToolConfigureBuildLazarus.OnClick := @mnuToolConfigBuildLazClicked;
  mnuTools.Add(itmToolConfigureBuildLazarus);

//--------------
// Environment
//--------------

  itmEnvGeneralOptions := TMenuItem.Create(nil);
  itmEnvGeneralOptions.Name:='itmEnvGeneralOptions';
  itmEnvGeneralOptions.Caption := 'General options';
  itmEnvGeneralOptions.OnCLick := @mnuEnvGeneralOptionsClicked;
  mnuEnvironment.Add(itmEnvGeneralOptions);

  itmEnvEditorOptions := TMenuItem.Create(nil);
  itmEnvEditorOptions.Name:='itmEnvEditorOptions';
  itmEnvEditorOptions.Caption := 'Editor options';
  itmEnvEditorOptions.OnCLick := @mnuEnvEditorOptionsClicked;
  mnuEnvironment.Add(itmEnvEditorOptions);

  itmEnvCodeToolsOptions := TMenuItem.Create(nil);
  itmEnvCodeToolsOptions.Name:='itmEnvCodeToolsOptions';
  itmEnvCodeToolsOptions.Caption := 'CodeTools options';
  itmEnvCodeToolsOptions.OnCLick := @mnuEnvCodeToolsOptionsClicked;
  mnuEnvironment.Add(itmEnvCodeToolsOptions);

//--------------
// Help
//--------------

  itmHelpAboutLazarus := TMenuItem.Create(nil);
  itmHelpAboutLazarus.Name:='itmHelpAboutLazarus';
  itmHelpAboutLazarus.Caption := 'About Lazarus';
  itmHelpAboutLazarus.OnCLick := @mnuHelpAboutLazarusClicked;
  mnuHelp.Add(itmHelpAboutLazarus);

end;
{------------------------------------------------------------------------------}

function TMainIDE.CreateSeperator : TMenuItem;
begin
  itmSeperator := TMenuItem.Create(Self);
  itmSeperator.Caption := '-';
  Result := itmSeperator;
end;

{------------------------------------------------------------------------------}

Procedure TMainIDE.mnuToggleFormUnitClicked(Sender : TObject);
Begin
  FCodeLastActivated:=not FCodeLastActivated;
  DoBringToFrontFormOrUnit;
end;

Procedure TMainIDE.SetDesigning(Control : TComponent; Value : Boolean);
Begin
  Control.SetDesigning(Value);
  if Value then CNSendMessage(LM_SETDESIGNING, Control, nil);

end;


{
------------------------------------------------------------------------
-------------------ControlClick-----------------------------------------
------------------------------------------------------------------------
}

Procedure TMainIDE.ControlClick(Sender : TObject);
var
  I : Integer;
  IDECOmp : TIDEComponent;
  Speedbutton : TSpeedbutton;
  Temp : TControl;
begin
  if Sender is TSpeedButton then
  Begin
//    Writeln('sender is a speedbutton');
//    Writeln('The name is '+TSpeedbutton(sender).name);
    SpeedButton := TSpeedButton(Sender);
//    Writeln('Speedbutton s Name is '+SpeedButton.name);
    //find the IDECOmponent that has this speedbutton
    IDEComp := IDECompList.FindCompBySpeedButton(SpeedButton);
    if SelectedComponent <> nil then
      TIDeComponent(
       IdeCompList.FindCompByRegComponent(SelectedComponent)).SpeedButton.Down
         := False
    else begin
      Temp := nil;
      for i := 0 to 
              ComponentNotebook.Page[ComponentNotebook.Pageindex].ControlCount-1
      do begin
        if CompareText(
            TControl(ComponentNotebook.
                Page[ComponentNotebook.Pageindex].Controls[I]).Name
            ,'GlobalMouseSpeedButton'
              +IntToStr(ComponentNotebook.Pageindex)) = 0 then
        begin
          temp := TControl(ComponentNotebook.
                              Page[ComponentNotebook.Pageindex].Controls[i]);
          Break;
        end;
      end;
      if temp <> nil then
        TSpeedButton(Temp).down := False
      else begin
        Writeln('[TMainIDE.ControlClick] ERROR - Control ',
           'GlobalMouseSpeedButton',
           IntToStr(ComponentNotebook.PageIndex),' not found');
        Halt;
      end;
    end;
    if IDECOmp <> nil then Begin
      //draw this button down
      SpeedButton.Down := True;
      SelectedComponent := IDEComp.RegisteredComponent;
    end else begin
      SelectedComponent := nil;
      Temp := nil;
      for i := 0 to 
          ComponentNotebook.Page[ComponentNotebook.Pageindex].ControlCount-1 do
      begin
        if CompareText(
          TControl(ComponentNotebook.
               Page[ComponentNotebook.Pageindex].Controls[I]).Name
           ,'GlobalMouseSpeedButton'
             +IntToStr(ComponentNotebook.Pageindex)) = 0 then
        begin
          temp := TControl(ComponentNotebook.
                                 Page[ComponentNotebook.Pageindex].Controls[i]);
          Break;
        end;
      end;
      if temp <> nil then
        TSpeedButton(Temp).down := True
      else begin
        Writeln('[TMainIDE.ControlClick] ERROR - Control '
           +'GlobalMouseSpeedButton'
           +IntToStr(ComponentNotebook.Pageindex)+' not found');
        Halt;
      end;
    end;
  end
  else
  Begin
//    Writeln('must be nil');
    //draw old speedbutton up
    if SelectedComponent <> nil then
      TIDeComponent(
        IdeCompList.FindCompByRegComponent(SelectedComponent)).SpeedButton.Down
           := False;
    SelectedComponent := nil;
    Temp := nil;
    for i := 0 to 
          ComponentNotebook.Page[ComponentNotebook.Pageindex].ControlCount-1 do
    begin
      if CompareText(
         TControl(ComponentNotebook.
            Page[ComponentNotebook.Pageindex].Controls[I]).Name
         ,'GlobalMouseSpeedButton'
           +IntToStr(ComponentNotebook.Pageindex)) = 0 then
      begin
        temp := TControl(ComponentNotebook.
                              Page[ComponentNotebook.Pageindex].Controls[i]);
        Break;
      end;
    end;
    if temp <> nil then
      TSpeedButton(Temp).down := True
    else begin
      Writeln('[TMainIDE.ControlClick] ERROR - Control '
        +'GlobalMouseSpeedButton'
        +IntToStr(ComponentNotebook.Pageindex)+' not found');
      Halt;
    end;
  end;
//  Writeln('Exiting ControlClick');
end;



{------------------------------------------------------------------------------}
procedure TMainIDE.mnuFindDeclarationClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoFindDeclarationAtCursor;
end;

procedure TMainIDE.mnuNewUnitClicked(Sender : TObject);
begin
  DoNewEditorUnit(nuUnit,'');
end;

procedure TMainIDE.mnuNewFormClicked(Sender : TObject);
begin
  DoNewEditorUnit(nuForm,'');
end;

procedure TMainIDE.mnuOpenClicked(Sender : TObject);
var OpenDialog:TOpenDialog;
  AFilename: string;
  I  : Integer;
begin
  if (Sender=itmFileOpen) or (Sender=OpenFileSpeedBtn)
  or (Sender is TSourceNoteBook) then begin
    OpenDialog:=TOpenDialog.Create(Application);
    try
      OpenDialog.Title:='Open file';
      OpenDialog.InitialDir:=EnvironmentOptions.LastOpenDialogDir;
      OpenDialog.Options:=[ofAllowMultiSelect];
      if OpenDialog.Execute and (OpenDialog.Files.Count>0) then begin
        For I := 0 to OpenDialog.Files.Count-1 do
          Begin
            AFilename:=ExpandFilename(OpenDialog.Files.Strings[i]);
            if i=0 then
              EnvironmentOptions.LastOpenDialogDir:=ExtractFilePath(AFilename);
            if DoOpenEditorFile(AFilename,false,false)=mrOk then begin
               EnvironmentOptions.AddToRecentOpenFiles(AFilename);
          end;
        end;
        SaveEnvironment;
      end;
    finally
      OpenDialog.Free;
    end;
  end else if Sender is TMenuItem then begin
    AFileName:=ExpandFilename(TMenuItem(Sender).Caption);
    if DoOpenEditorFile(AFilename,false,false)=mrOk then begin
      EnvironmentOptions.AddToRecentOpenFiles(AFilename);
      SaveEnvironment;
    end;
  end;
end;

procedure TMainIDE.mnuOpenFileAtCursorClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoOpenFileAtCursor(Sender);  
end;

procedure TMainIDE.mnuSaveClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoSaveEditorUnit(SourceNoteBook.NoteBook.PageIndex,false,false,false);
end;

procedure TMainIDE.mnuSaveAsClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoSaveEditorUnit(SourceNoteBook.NoteBook.PageIndex,true,false,false);
end;

procedure TMainIDE.mnuSaveAllClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoSaveAll;  
end;

procedure TMainIDE.mnuCloseClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoCloseEditorUnit(SourceNoteBook.NoteBook.PageIndex,true);
end;

Procedure TMainIDE.OnSrcNotebookFileNew(Sender : TObject);
begin
  mnuNewFormClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookFileClose(Sender : TObject);
begin
  mnuCloseClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookFileOpen(Sender : TObject);
begin
  mnuOpenClicked(Sender);
end;

Procedure TMainIDE.OnSrcNoteBookFileOpenAtCursor(Sender : TObject);
begin
  mnuOpenFileAtCursorClicked(Sender);  
end;

Procedure TMainIDE.OnSrcNotebookFileSave(Sender : TObject);
begin
  mnuSaveClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookFileSaveAs(Sender : TObject);
begin
  mnuSaveAsClicked(Sender);
end;

Procedure TMainIDE.OnSrcNoteBookFindDeclaration(Sender : TObject);
begin
  mnuFindDeclarationClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookSaveAll(Sender : TObject);
begin
  mnuSaveAllClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookToggleFormUnit(Sender : TObject);
begin
  mnuToggleFormUnitClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookProcessCommand(Sender: TObject;
  Command: integer;  var Handled: boolean);
begin
  Handled:=true;
  case Command of
    ecBuild, 
    ecBuildAll:    DoBuildProject(Command=ecBuildAll);
    
    ecRun:         DoRunProject;
    ecPause:       DoPauseProject;
    ecStepInto:    DoStepIntoProject;
    ecStepOver:    DoStepOverProject;
    ecRunToCursor: DoRunToCursor;
    ecStopProgram: DoStopProject;
    
   ecFindProcedureDefinition,ecFindProcedureMethod:
     DoJumpToProcedureSection;
      
   ecFindDeclaration:
     DoFindDeclarationAtCursor;
     
   ecFindBlockOtherEnd:
     DoGoToPascalBlockOtherEnd;
     
   ecFindBlockStart:
     DoGoToPascalBlockStart;
    
   ecCompleteCode:
     DoCompleteCodeAtCursor;
      
   ecExtToolFirst..ecExtToolLast:
     DoRunExternalTool(Command-ecExtToolFirst);
    
   ecSyntaxCheck:
     DoCheckSyntax;
     
   ecGuessUnclosedBlock:
     DoJumpToGuessedUnclosedBlock(true);
    
   ecBuildLazarus:
     DoBuildLazarus;
    
  else
    Handled:=false;
  end;
end;

procedure TMainIDE.OnSrcNoteBookShowUnitInfo(Sender: TObject);
var ActiveSrcEdit:TSourceEditor;
  ActiveUnitInfo:TUnitInfo;
  ShortUnitName, AFilename: string;
begin
  GetCurrentUnit(ActiveSrcEdit,ActiveUnitInfo);
  if (ActiveSrcEdit=nil) or (ActiveUnitInfo=nil) then exit;
  ShortUnitName:=ExtractFileName(ActiveUnitInfo.Filename);
  if ShortUnitName='' then
    ShortUnitName:='(unsaved)';
  AFilename:=ActiveUnitInfo.Filename;
  if AFileName='' then
    AFileName:='(unsaved)';
  ShowUnitInfoDlg(ShortUnitName,
    LazSyntaxHighlighterNames[ActiveUnitInfo.SyntaxHighlighter],
    ActiveUnitInfo.IsPartOfProject, length(ActiveSrcEdit.Source.Text),
    ActiveSrcEdit.Source.Count,AFilename);
end;

{------------------------------------------------------------------------------}

{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{----------------OpenFileDownArrowClicked--------------------------------------}
{------------------------------------------------------------------------------}

Procedure TMainIDE.OpenFileDownArrowClicked(Sender : TObject);
Begin
  //display the PopupMenu
  if OpenFilePopupMenu.Items.Count > 0 then
    OpenFilePopupMenu.Popup(0,0);
end;

//==============================================================================
{
  This function creates a LFM file from any form.
  To create the resource file use the program lazres or the
  LFMtoLFCfile function.
}
function CreateLFM(AForm:TCustomForm):integer;
// 0 = ok
// -1 = error while streaming AForm to binary stream
// -2 = error while streaming binary stream to text file
var BinStream,TxtMemStream:TMemoryStream;
  Driver: TAbstractObjectWriter;
  Writer:TWriter;
  TxtFileStream:TFileStream;
begin
  Result:=0;
  BinStream:=TMemoryStream.Create;
  try
    try
      Driver:=TBinaryObjectWriter.Create(BinStream,4096);
      try
        Writer:=TWriter.Create(Driver);
        try
          Writer.WriteDescendent(AForm,nil);
        finally
          Writer.Free;
        end;
      finally
        Driver.Free;
      end;
    except
      Result:=-1;
      exit;
    end;
    try
      // transform binary to text and save LFM file
      TxtMemStream:=TMemoryStream.Create;
      TxtFileStream:=TFileStream.Create(lowercase(AForm.ClassName)+'.lfm'
                           ,fmCreate);
      try
        BinStream.Position:=0;
        ObjectBinaryToText(BinStream,TxtMemStream);
        TxtMemStream.Position:=0;
        TxtFileStream.CopyFrom(TxtMemStream,TxtMemStream.Size);
      finally
        TxtMemStream.Free;
        TxtFileStream.Free;
      end;
    except
      Result:=-2;
      exit;
    end;
  finally
    BinStream.Free;
  end;
end;

//==============================================================================

Procedure TMainIDE.SetDefaultsforForm(aForm : TCustomForm);
Begin
{$IFDEF IDE_DEBUG}
writeln('[TMainIDE.SetDefaultsforForm] A');
{$ENDIF}
  aForm.Designer := TDesigner.Create(aForm, TheControlSelection);
{$IFDEF IDE_DEBUG}
writeln('[TMainIDE.SetDefaultsforForm] B');
{$ENDIF}
  with TDesigner(aForm.Designer) do begin
    FormEditor := FormEditor1;
    OnGetSelectedComponentClass:=@OnDesignerGetSelectedComponentClass;
    OnUnselectComponentClass:=@OnDesignerUnselectComponentClass;
    OnSetDesigning:=@OnDesignerSetDesigning;
    OnComponentListChanged:=@OnDesignerComponentListChanged;
    OnPropertiesChanged:=@OnDesignerPropertiesChanged;
    OnAddComponent:=@OnDesignerAddComponent;
    OnRemoveComponent:=@OnDesignerRemoveComponent;
    OnGetNonVisualCompIconCanvas:=@IDECompList.OnGetNonVisualCompIconCanvas;
    OnModified:=@OnDesignerModified;
    OnActivated := @OnDesignerActivated;
    ShowHints:=EnvironmentOptions.ShowEditorHints;
  end;
end;


{------------------------------------------------------------------------------}

procedure TMainIDE.mnuQuitClicked(Sender : TObject);
var CanClose: boolean;
begin
  CanClose:=true;
  OnCloseQuery(Sender, CanClose);
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.mnuQuitClicked 1');
{$ENDIF}
  if CanClose then Close;
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.mnuQuitClicked 2');
{$ENDIF}
end;

{------------------------------------------------------------------------------}
procedure TMainIDE.mnuViewInspectorClicked(Sender : TObject);
begin
  ObjectInspector1.Show;
end;

{------------------------------------------------------------------------------}

Procedure TMainIDE.mnuViewUnitsClicked(Sender : TObject);
begin
  DoViewUnitsAndForms(false);
end;

Procedure TMainIDE.mnuViewFormsClicked(Sender : TObject);
Begin
  DoViewUnitsAndForms(true);
end;

Procedure TMainIDE.mnuViewCodeExplorerClick(Sender : TObject);
begin
  SourceNotebook.Show;
end;

Procedure TMainIDE.mnuViewMessagesClick(Sender : TObject);
Begin
  MessagesView.Show;
//  if Not Assigned(ColumnDlg1) then
//    ColumnDlg1 := TColumnDlg1.Create(self);
//  ColumnDlg1.ShowModal;
//  CreateLFM(ColumnDlg1);
End;


{------------------------------------------------------------------------------}

Procedure TMainIDE.mnuNewProjectClicked(Sender : TObject);
var
  NewProjectType: TProjectType;
Begin
  if ChooseNewProject(NewProjectType)=mrCancel then exit;
  DoNewProject(NewprojectType);
end;

Procedure TMainIDE.mnuOpenProjectClicked(Sender : TObject);
var OpenDialog:TOpenDialog;
  AFileName: string;
begin
  if Sender=itmProjectOpen then begin
    OpenDialog:=TOpenDialog.Create(Application);
    try
      OpenDialog.Title:='Open Project File (*.lpi)';
      OPenDialog.Filter := '*.lpi';
      OpenDialog.InitialDir:=EnvironmentOptions.LastOpenDialogDir;
      if OpenDialog.Execute then begin
        AFilename:=ExpandFilename(OpenDialog.Filename);
        EnvironmentOptions.LastOpenDialogDir:=ExtractFilePath(AFilename);
        if DoOpenProjectFile(AFilename)=mrOk then begin
          EnvironmentOptions.AddToRecentProjectFiles(AFilename);
          SaveEnvironment;
        end;
      end;
    finally
      OpenDialog.Free;
    end;
  end else if Sender is TMenuItem then begin
    AFileName:=ExpandFilename(TMenuItem(Sender).Caption);
    if DoOpenProjectFile(AFilename)=mrOk then begin
      EnvironmentOptions.AddToRecentProjectFiles(AFilename);
      SaveEnvironment;
    end;
  end;
end;

Procedure TMainIDE.mnuSaveProjectClicked(Sender : TObject);
Begin
  DoSaveProject(false,false);
end;

procedure TMainIDE.mnuSaveProjectAsClicked(Sender : TObject);
begin
  DoSaveProject(true,false);
end;

procedure TMainIDE.mnuAddToProjectClicked(Sender : TObject);
begin
  DoAddActiveUnitToProject;
end;

procedure TMainIDE.mnuRemoveFromProjectClicked(Sender : TObject);
begin
  DoRemoveFromProjectDialog;
end;

procedure TMainIDE.mnuViewProjectSourceClicked(Sender : TObject);
begin
  DoOpenMainUnit(false);
end;

procedure TMainIDE.mnuProjectOptionsClicked(Sender : TObject);
begin
  if ShowProjectOptionsDialog(Project)=mrOk then begin
    
  end;
end;

Procedure TMainIDE.mnuBuildProjectClicked(Sender : TObject);
Begin
  DoBuildProject(false);
end;

Procedure TMainIDE.mnuBuildAllProjectClicked(Sender : TObject);
Begin
  DoBuildProject(true);
end;

Procedure TMainIDE.mnuRunProjectClicked(Sender : TObject);
begin
  DoRunProject;
end;

Procedure TMainIDE.mnuPauseProjectClicked(Sender : TObject);
begin
  DoPauseProject;
end;

Procedure TMainIDE.mnuStepIntoProjectClicked(Sender : TObject);
begin
  DoStepIntoProject;
end;

Procedure TMainIDE.mnuStepOverProjectClicked(Sender : TObject);
begin
  DoStepOverProject;
end;

Procedure TMainIDE.mnuRunToCursorProjectClicked(Sender : TObject);
begin
  DoRunToCursor;
end;

Procedure TMainIDE.mnuStopProjectClicked(Sender : TObject);
begin
  DoStopProject;
end;

procedure TMainIDE.mnuProjectCompilerSettingsClicked(Sender : TObject);
var frmCompilerOptions:TfrmCompilerOptions;
begin
  frmCompilerOptions:=TfrmCompilerOptions.Create(Application);
  try
    frmCompilerOptions.CompilerOpts:=Project.CompilerOptions;
    frmCompilerOptions.GetCompilerOptions;
    frmCompilerOptions.OtherSourcePath:=Project.SrcPath;
    if frmCompilerOptions.ShowModal=mrOk then begin
      Project.SrcPath:=frmCompilerOptions.OtherSourcePath;
      CreateProjectDefineTemplate(Project.CompilerOptions,Project.SrcPath);
    end;
  finally
    frmCompilerOptions.Free;
  end;
end;

procedure TMainIDE.mnuRunParametersClicked(Sender : TObject);
begin
  if ShowRunParamsOptsDlg(Project.RunParameterOptions)=mrOk then begin
    
  end;
end;

//------------------------------------------------------------------------------

procedure TMainIDE.mnuToolConfigureClicked(Sender : TObject);
begin
  if ShowExtToolDialog(EnvironmentOptions.ExternalTools,MacroList)=mrOk then
  begin
    // save to enviroment options
    SaveDesktopSettings(EnvironmentOptions);
    EnvironmentOptions.Save(false);
    // save shortcuts to editor options
    EnvironmentOptions.ExternalTools.SaveShortCuts(EditorOpts.KeyMap);
    EditorOpts.Save;
    SourceNotebook.ReloadEditorOptions;
    // ToDo: update menu
    
  end;
end;

procedure TMainIDE.mnuToolSyntaxCheckClicked(Sender : TObject);
begin
  DoCheckSyntax;
end;

procedure TMainIDE.mnuToolGuessUnclosedBlockClicked(Sender : TObject);
begin
  DoJumpToGuessedUnclosedBlock(true);
end;

procedure TMainIDE.mnuToolBuildLazarusClicked(Sender : TObject);
begin
  DoBuildLazarus;
end;

procedure TMainIDE.mnuToolConfigBuildLazClicked(Sender : TObject);
begin
  if ShowConfigureBuildLazarusDlg(MiscellaneousOptions.BuildLazOpts)=mrOk then
    MiscellaneousOptions.Save;
end;

//------------------------------------------------------------------------------

procedure TMainIDE.SaveDesktopSettings(
  TheEnvironmentOptions: TEnvironmentOptions);
begin
  with TheEnvironmentOptions do begin
    MainWindowBounds:=BoundsRect;
    SourceEditorBounds:=SourceNoteBook.BoundsRect;
    MessagesViewBoundsValid:=FMessagesViewBoundsRectValid;
    MessagesViewBounds:=MessagesView.BoundsRect;
    ObjectInspectorOptions.Assign(ObjectInspector1);
    WindowPositionsValid:=true;
  end;
end;

procedure TMainIDE.LoadDesktopSettings(
  TheEnvironmentOptions: TEnvironmentOptions);
begin
  with TheEnvironmentOptions do begin
    if WindowPositionsValid then begin
      // set window positions
      BoundsRect:=MainWindowBounds;
      SourceNoteBook.BoundsRect:=SourceEditorBounds;
      if MessagesViewBoundsValid then begin
        MessagesView.BoundsRect:=MessagesViewBounds;
        FMessagesViewBoundsRectValid:=true;
      end;
      ObjectInspectorOptions.AssignTo(ObjectInspector1);
    end;
  end;
end;

procedure TMainIDE.UpdateDefaultPascalFileExtensions;
var nut: TNewUnitType;
  npt: TProjectType;
  DefPasExt: string;
begin
  // change default pascal file extensions
  DefPasExt:=PascalExtension[EnvironmentOptions.PascalFileExtension];
  for nut:=Low(TNewUnitType) to High(TNewUnitType) do
    if (UnitTypeDefaultExt[nut]='.pas') or (UnitTypeDefaultExt[nut]='.pp')
    then UnitTypeDefaultExt[nut]:=DefPasExt;
  for npt:=Low(TProjectType) to High(TProjectType) do
    if (ProjectDefaultExt[npt]='.pas') or (ProjectDefaultExt[npt]='.pp')
    then ProjectDefaultExt[npt]:=DefPasExt;
end;

procedure TMainIDE.OnLoadEnvironmentSettings(Sender: TObject; 
  TheEnvironmentOptions: TEnvironmentOptions);
begin
  LoadDesktopSettings(TheEnvironmentOptions);
end;

procedure TMainIDE.OnSaveEnvironmentSettings(Sender: TObject; 
  TheEnvironmentOptions: TEnvironmentOptions);
begin
  SaveDesktopSettings(TheEnvironmentOptions);
end;

procedure TMainIDE.mnuEnvGeneralOptionsClicked(Sender : TObject);
var EnvironmentOptionsDialog: TEnvironmentOptionsDialog;
  MacroValueChanged, FPCSrcDirChanged, FPCCompilerChanged: boolean;
  OldCompilerFilename, CompilerUnitSearchPath: string;
  CompilerTemplate, FPCSrcTemplate: TDefineTemplate;
  
  procedure ChangeMacroValue(const MacroName, NewValue: string);
  begin
    with CodeToolBoss.GlobalValues do begin
      if Variables[ExternalMacroStart+MacroName]=NewValue then exit;
      FPCSrcDirChanged:=FPCSrcDirChanged or (Macroname='FPCSrcDir');
      Variables[ExternalMacroStart+MacroName]:=NewValue;
    end;
    MacroValueChanged:=true;
  end;
  
Begin
  EnvironmentOptionsDialog:=TEnvironmentOptionsDialog.Create(Application);
  try
    // update EnvironmentOptions (save current window positions)
    SaveDesktopSettings(EnvironmentOptions);
    with EnvironmentOptionsDialog do begin
      OnLoadEnvironmentSettings:=@Self.OnLoadEnvironmentSettings;
      OnSaveEnvironmentSettings:=@Self.OnSaveEnvironmentSettings;
      // load settings from EnvironmentOptions to EnvironmentOptionsDialog
      ReadSettings(EnvironmentOptions);
    end;
    if EnvironmentOptionsDialog.ShowModal=mrOk then begin
      // load settings from EnvironmentOptionsDialog to EnvironmentOptions
      OldCompilerFilename:=EnvironmentOptions.CompilerFilename;
      EnvironmentOptionsDialog.WriteSettings(EnvironmentOptions);
      UpdateDefaultPascalFileExtensions;
      // set global variables
      MacroValueChanged:=false;
      FPCSrcDirChanged:=false;
      FPCCompilerChanged:=
        OldCompilerFilename<>EnvironmentOptions.CompilerFilename;
      ChangeMacroValue('LazarusDir',EnvironmentOptions.LazarusDirectory);
      ChangeMacroValue('FPCSrcDir',EnvironmentOptions.FPCSourceDirectory);
      
      if MacroValueChanged then CodeToolBoss.DefineTree.ClearCache;
      if FPCCompilerChanged or FPCSrcDirChanged then begin
        // rescan compiler defines
        // ask the compiler for his settings
        CompilerTemplate:=CodeToolBoss.DefinePool.CreateFPCTemplate(
                    EnvironmentOptions.CompilerFilename,CompilerUnitSearchPath);
        if CompilerTemplate<>nil then begin
          CodeToolBoss.DefineTree.ReplaceSameNameAddFirst(CompilerTemplate);
          // create compiler macros to simulate the Makefiles of the FPC sources
          FPCSrcTemplate:=CodeToolBoss.DefinePool.CreateFPCSrcTemplate(
            CodeToolBoss.GlobalValues.Variables[ExternalMacroStart+'FPCSrcDir'],
            CompilerUnitSearchPath);
          if FPCSrcTemplate<>nil then begin
            CodeToolBoss.DefineTree.RemoveDefineTemplateByName(
                                                           FPCSrcTemplate.Name);
            FPCSrcTemplate.InsertAfter(CompilerTemplate);
          end else begin
            MessageDlg('FPC Source Directory error',
              'Please check the freepascal source directory',
              mtError,[mbOk],0);
          end;
        end else begin
          MessageDlg('Compiler error','Please check the compiler name',
            mtError,[mbOk],0);
        end;
      end;
        
      // save to disk
      EnvironmentOptions.Save(false);
    end;
  finally
    EnvironmentOptionsDialog.Free;
  end;
End;

procedure TMainIDE.mnuEnvEditorOptionsClicked(Sender : TObject);
var EditorOptionsForm: TEditorOptionsForm;
Begin
  EditorOptionsForm:=TEditorOptionsForm.Create(Application);
  try
    if EditorOptionsForm.ShowModal=mrOk then
      SourceNotebook.ReloadEditorOptions;
  finally
    EditorOptionsForm.Free;
  end;
End;

procedure TMainIDE.mnuEnvCodeToolsOptionsClicked(Sender : TObject);
begin
  ShowCodeToolsOptions(CodeToolsOpts,@SourceNoteBook.GetSynEditPreviewSettings);
end;

procedure TMainIDE.SaveEnvironment;
begin
  SaveDesktopSettings(EnvironmentOptions);
  EnvironmentOptions.Save(false);
end;
//------------------------------------------------------------------------------

procedure TMainIDE.mnuHelpAboutLazarusClicked(Sender : TObject);
begin
  MessageDlg('About Lazarus',
    'Lazarus '+Version_String+#13
    +'License: GPL/LGPL'
    +#13
    +'Lazarus are the class libraries for Free Pascal that emulate Delphi.'#13
    +'Free Pascal is a (L)GPL''ed compiler that runs on Linux,'#13
    +'Win32, OS/2, 68K and more. Free Pascal is designed to be able to'#13
    +'understand and compile Delphi syntax, which is of course OOP.'#13
    +'Lazarus is the missing part of the puzzle that will allow you to'#13
    +'develop Delphi like programs in all of the above platforms.'#13
    +'The IDE will eventually become a RAD tool like Delphi.'#13
    +#13
    +'As Lazarus is growing we need more developers.'#13
    +'For example: Write a nicer about dialog with a logo.'
    ,mtInformation, [mbOk], 0);
end;

//------------------------------------------------------------------------------

Procedure TMainIDE.MessageViewDblClick(Sender : TObject);
Begin

end;

//==============================================================================

function TMainIDE.DoNewEditorUnit(NewUnitType:TNewUnitType;
  const NewFilename: string):TModalResult;
var NewUnitInfo:TUnitInfo;
  TempForm : TCustomForm;
  CInterface : TComponentInterface;
  NewSrcEdit: TSourceEditor;
  NewUnitName: string;
  NewBuffer, ResourceCode: TCodeBuffer;
begin
writeln('TMainIDE.DoNewEditorUnit A NewFilename=',NewFilename);
  Result:=mrCancel;
  if NewFilename='' then begin
    NewUnitName:=Project.NewUniqueUnitName(NewUnitType);
    NewBuffer:=CodeToolBoss.CreateFile(
                                   NewUnitName+UnitTypeDefaultExt[NewUnitType]);
  end else begin
    NewUnitName:=ExtractFileNameOnly(NewFilename);
    NewBuffer:=CodeToolBoss.CreateFile(NewFilename);
  end;
  if NewBuffer=nil then exit;
  NewUnitInfo:=TUnitInfo.Create(NewBuffer);

  // create source code
  if NewUnitType in [nuForm] then
    NewUnitInfo.FormName:=Project.NewUniqueFormName(NewUnitType);
  NewUnitInfo.CreateStartCode(NewUnitType,NewUnitName);
  
  // add to project
  with NewUnitInfo do begin
    Loaded:=true;
    IsPartOfProject:=true;
  end;
  Project.AddUnit(NewUnitInfo,true);
  if NewUnitType in [nuForm, nuUnit] then begin
    NewUnitInfo.SyntaxHighlighter:=lshFreePascal;
  end;

  if NewUnitType in [nuForm] then begin
    // create a buffer for the new resource file and for the LFM file
    ResourceCode:=
      CodeToolBoss.CreateFile(ChangeFileExt(NewUnitName,ResourceFileExt));
    ResourceCode.Source:=
      '{ This is an automatically generated lazarus resource file }';
    CodeToolBoss.CreateFile(ChangeFileExt(NewUnitName,'.lfm'));
    
    // clear formeditor
    if not Assigned(FormEditor1) then
      FormEditor1 := TFormEditor.Create;
    FormEditor1.ClearSelected;
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TMainIDE.DoNewEditorUnit G '+IntToStr(GetMem_Cnt));
{$ENDIF}

    // create jitform
    CInterface := TComponentInterface(
      FormEditor1.CreateComponent(nil,TForm,
        ObjectInspector1.Left+ObjectInspector1.Width+40,Top+Height+50,400,300));
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TMainIDE.DoNewEditorUnit H '+IntToStr(GetMem_Cnt));
{$ENDIF}
    FormEditor1.SetFormNameAndClass(CInterface,
      NewUnitInfo.FormName,'T'+NewUnitInfo.FormName);
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TMainIDE.DoNewEditorUnit I '+IntToStr(GetMem_Cnt));
{$ENDIF}
    TempForm:=TForm(CInterface.Control);
    NewUnitInfo.Form:=TempForm;
    SetDefaultsForForm(TempForm);

    NewUnitInfo.FormName:=TempForm.Name;
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TMainIDE.DoNewEditorUnit J '+IntToStr(GetMem_Cnt));
{$ENDIF}
    Project.AddCreateFormToProjectFile(TempForm.ClassName,TempForm.Name);
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TMainIDE.DoNewEditorUnit K '+IntToStr(GetMem_Cnt));
{$ENDIF}
  end;

  // create a new sourceeditor
  SourceNotebook.NewFile(NewUnitInfo.UnitName,NewUnitInfo.Source);
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TMainIDE.DoNewEditorUnit L '+IntToStr(GetMem_Cnt));
{$ENDIF}
  NewSrcEdit:=SourceNotebook.GetActiveSE;
  NewSrcEdit.SyntaxHighlighterType:=NewUnitInfo.SyntaxHighlighter;
  Project.InsertEditorIndex(SourceNotebook.NoteBook.PageIndex);
  NewUnitInfo.EditorIndex:=SourceNotebook.NoteBook.PageIndex;

  if NewUnitType in [nuForm] then begin
    // show form
    TDesigner(TempForm.Designer).SourceEditor := SourceNoteBook.GetActiveSE;

    TempForm.Show;
    SetDesigning(TempForm,True);

    // select the new form (object inspector, formeditor, control selection)
    PropertyEditorHook1.LookupRoot := TForm(CInterface.Control);
    TDesigner(TempForm.Designer).SelectOnlyThisComponent(TempForm);
  end;

  FCodeLastActivated:=not (NewUnitType in [nuForm]);
writeln('TMainIDE.DoNewUnit end');
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
end;

function TMainIDE.DoSaveEditorUnit(PageIndex:integer; 
  SaveAs, SaveToTestDir, ProjectSaving:boolean):TModalResult;
var ActiveSrcEdit:TSourceEditor;
  ActiveUnitInfo:TUnitInfo;
  SaveDialog:TSaveDialog;
  NewUnitName,NewFilename,NewPageName:string;
  AText,ACaption,CompResourceCode,TestFilename: string;
  SaveAsFileExt, SaveAsFilename: string;
  MemStream,BinCompStream,TxtCompStream:TMemoryStream;
  Driver: TAbstractObjectWriter;
  Writer:TWriter;
  ResourceCode, LFMCode, NewSource: TCodeBuffer;
  LinkIndex: integer;
begin
writeln('TMainIDE.DoSaveEditorUnit A PageIndex=',PageIndex,' SaveAs=',SaveAs,' SaveToTestDir=',SaveToTestDir);
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  Result:=mrCancel;
  if ToolStatus<>itNone then begin
    Result:=mrAbort;
    exit;
  end;
  GetUnitWithPageIndex(PageIndex,ActiveSrcEdit,ActiveUnitInfo);
  if ActiveUnitInfo=nil then exit;
  
  if (not ProjectSaving) and Project.IsVirtual
  and ActiveUnitInfo.IsPartOfProject then
  begin
    Result:=DoSaveProject(false,SaveToTestDir);
    exit;
  end;

  ActiveUnitInfo.ReadOnly:=ActiveSrcEdit.ReadOnly;
  if (ActiveUnitInfo.ReadOnly) and (not SaveToTestDir) then begin
    Result:=mrOk;
    exit;
  end;
  if ActiveSrcEdit.Modified then begin
    ActiveSrcEdit.UpdateCodeBuffer;
    ActiveUnitInfo.Modified:=true;
  end;
//writeln('TMainIDE.DoSaveEditorUnit A4 ');
  if (not SaveToTestDir) and (not ActiveUnitInfo.Modified) and (not SaveAs) then
  begin
    Result:=mrOk;
    exit;
  end;
  if (not SaveToTestDir) and (ActiveUnitInfo.IsVirtual) then
    SaveAs:=true;
  
  if ActiveUnitInfo.HasResources then begin
    LinkIndex:=-1;
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.DoSaveEditorUnit B');
CodeToolBoss.SourceCache.WriteAllFileNames;
{$ENDIF}
    ResourceCode:=CodeToolBoss.FindNextResourceFile(
      ActiveUnitInfo.Source,LinkIndex);
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.DoSaveEditorUnit B2 ',ResourceCode<>nil);
{$ENDIF}
    LFMCode:=nil;
    if (ResourceCode<>nil) and (not ResourceCode.IsVirtual) then begin
      Result:=DoLoadCodeBuffer(LFMCode,
          ChangeFileExt(ResourceCode.Filename,'.lfm'),false,false,true);
      if Result<>mrOk then exit;
      Result:=mrCancel;
    end;
  end else
    ResourceCode:=nil;
    
  if SaveAs and (not SaveToTestDir) then begin
    // let user choose a filename
    SaveDialog:=TSaveDialog.Create(Application);
    try
      // try to keep the old filename and extension
      SaveAsFileExt:=ExtractFileExt(ActiveUnitInfo.FileName);
      if SaveAsFileExt='' then begin
        if ActiveSrcEdit.SyntaxHighlighterType in [lshFreePascal, lshDelphi]
        then
          SaveAsFileExt:=PascalExtension[EnvironmentOptions.PascalFileExtension]
        else
          SaveAsFileExt:=EditorOpts.HighlighterList.GetDefaultFilextension(
            ActiveSrcEdit.SyntaxHighlighterType);
      end;
      SaveAsFilename:=CodeToolBoss.GetSourceName(ActiveUnitInfo.Source);
      if SaveAsFilename='' then
        SaveAsFilename:=ActiveUnitInfo.UnitName;
      if SaveAsFilename='' then
        SaveAsFilename:='noname';
      SaveDialog.Title:='Save '+SaveAsFilename+' (*'+SaveAsFileExt+')';
      SaveDialog.FileName:=SaveAsFilename+SaveAsFileExt;
      SaveDialog.InitialDir:=EnvironmentOptions.LastOpenDialogDir;
      if SaveDialog.Execute then begin
        NewFilename:=ExpandFilename(SaveDialog.Filename);
        EnvironmentOptions.LastOpenDialogDir:=ExtractFilePath(NewFilename);
        if ExtractFileExt(NewFilename)='' then
          NewFilename:=NewFilename+SaveAsFileExt;
        if FileExists(NewFilename) then begin
          ACaption:='Overwrite file?';
          AText:='A file "'+NewFilename+'" already exists.'#13'Replace it?';
          if MessageDlg(ACaption, AText, mtconfirmation,[mbok,mbCancel],0)
             =mrCancel then exit;
        end;
        EnvironmentOptions.AddToRecentOpenFiles(NewFilename);
        if not CodeToolBoss.SaveBufferAs(ActiveUnitInfo.Source,NewFilename,
               NewSource) then exit;
        if ResourceCode<>nil then begin
          // rename Resource file and form text file
          // the resource include line in the code will be changed later when
          // changing the unitname
          CodeToolBoss.SaveBufferAs(ResourceCode,
            ChangeFileExt(NewFilename,ResourceFileExt),ResourceCode);
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.DoSaveEditorUnit D ',ResourceCode<>nil);
if ResourceCode<>nil then writeln('*** ResourceFileName ',ResourceCode.Filename);
{$ENDIF}
          LFMCode:=nil;
        end else begin
          // removing support files
          // The IDE automatically opens lfm files. SaveAs makes sure, that
          // there is no old lfm file left, which does not belong to the file
          DeleteFile(ChangeFileExt(NewFilename,'.lfm'));
        end;
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.DoSaveEditorUnit C ',ResourceCode<>nil);
{$ENDIF}
        ActiveUnitInfo.Source:=NewSource;
        ActiveUnitInfo.Modified:=false;
        ActiveSrcEdit.CodeBuffer:=NewSource; // the code is not changed, thus the marks are kept
        NewUnitName:=ExtractFileNameOnly(ActiveUnitInfo.Filename);
        // change unitname in source (resource filename is also changed)
        ActiveUnitInfo.UnitName:=NewUnitName;
        LinkIndex:=-1;
        ResourceCode:=CodeToolBoss.FindNextResourceFile(NewSource,LinkIndex);
        // change unitname on SourceNotebook
        NewPageName:=SourceNoteBook.FindUniquePageName(
            ActiveUnitInfo.Filename,SourceNoteBook.NoteBook.PageIndex);
        SourceNoteBook.NoteBook.Pages[SourceNoteBook.NoteBook.PageIndex]:=
            NewPageName;
        ActiveSrcEdit.ShortName:=NewPageName;
      end else begin
        // user cancels
        Result:=mrCancel;
        exit;
      end;
    finally
      SaveDialog.Free;
    end;
  end;
  TestFilename:='';
  if not SaveToTestDir then begin
    if ActiveUnitInfo.Modified then begin
      // save source
{writeln('');
writeln(ActiveUnitInfo.Source.Source);
writeln('');}
      Result:=ActiveUnitInfo.WriteUnitSource;
      if Result=mrAbort then exit;
    end;
  end else begin
    // save source to test directory
    TestFilename:=GetTestUnitFilename(ActiveUnitInfo);
    if TestFilename<>'' then begin
      Result:=ActiveUnitInfo.WriteUnitSourceToFile(TestFilename);
      if Result<>mrOk then exit;
      Result:=mrCancel;
    end else
      exit;
  end;

{$IFDEF IDE_DEBUG}
writeln('*** HasResources=',ActiveUnitInfo.HasResources);
{$ENDIF}
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  if ResourceCode<>nil then begin
    // save lrs - lazarus resource file and lfm - lazarus form text file

    if (ActiveUnitInfo.Form<>nil) then begin
      // stream component to resource code and to lfm file
      
      // stream component to binary stream
      BinCompStream:=TMemoryStream.Create;
      try
        repeat
          try
            BinCompStream.Position:=0;
            Driver:=TBinaryObjectWriter.Create(BinCompStream,4096);
            try
              Writer:=TWriter.Create(Driver);
              try
                Writer.WriteDescendent(ActiveUnitInfo.Form,nil);
              finally
                Writer.Free;
              end;
            finally
              Driver.Free;
            end;
          except
            ACaption:='Streaming error';
            AText:='Unable to stream '
                +ActiveUnitInfo.FormName+':T'+ActiveUnitInfo.FormName+'.';
            Result:=MessageDlg(ACaption, AText, mtError,
                       [mbAbort, mbRetry, mbIgnore], 0);
            if Result=mrAbort then exit;
            if Result=mrIgnore then Result:=mrOk;
          end;
        until Result<>mrRetry;
        // create lazarus form resource code
        MemStream:=TMemoryStream.Create;
        try
          BinCompStream.Position:=0;
          BinaryToLazarusResourceCode(BinCompStream,MemStream
            ,'T'+ActiveUnitInfo.FormName,'FORMDATA');
          MemStream.Position:=0;
          SetLength(CompResourceCode,MemStream.Size);
          MemStream.Read(CompResourceCode[1],length(CompResourceCode));
        finally
          MemStream.Free;
        end;
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.DoSaveEditorUnit E ',CompResourceCode);
{$ENDIF}
        // replace lazarus form resource code
        if (not CodeToolBoss.AddLazarusResource(ResourceCode,
           'T'+ActiveUnitInfo.FormName,CompResourceCode)) then
        begin
          ACaption:='Resource error';
          AText:='Unable to add resource '
            +'T'+ActiveUnitInfo.FormName+':FORMDATA to resource file '#13
            +'"'+ResourceCode.FileName+'".'#13
            +'Probably a syntax error.';
          Result:=MessageDlg(ACaption, AText, mterror, [mbok, mbcancel], 0);
          if Result=mrCancel then Result:=mrAbort;
          exit;
        end;
        if (not SaveToTestDir) then begin
          // save lfm file
          if LFMCode=nil then begin
            LFMCode:=CodeToolBoss.CreateFile(
                            ChangeFileExt(ResourceCode.Filename,'.lfm'));
          end;
          if LFMCode<>nil then begin
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.DoSaveEditorUnit E2 LFM=',LFMCode.Filename);
{$ENDIF}
            repeat
              try
                // transform binary to text
                TxtCompStream:=TMemoryStream.Create;
                try
                  BinCompStream.Position:=0;
                  ObjectBinaryToText(BinCompStream,TxtCompStream);
                  TxtCompStream.Position:=0;
                  LFMCode.LoadFromStream(TxtCompStream);
                  Result:=DoSaveCodeBufferToFile(LFMCode,LFMCode.Filename,
                                   ActiveUnitInfo.IsPartOfProject);
                  if not Result=mrOk then exit;
                  Result:=mrCancel;
                finally
                  TxtCompStream.Free;
                end;
              except
                ACaption:='Streaming error';
                AText:='Unable to transform binary component stream of '
                   +ActiveUnitInfo.FormName+':T'+ActiveUnitInfo.FormName
                   +' into text.';
                Result:=MessageDlg(ACaption, AText, mtError,
                                    [mbAbort, mbRetry, mbIgnore], 0);
                if Result=mrAbort then exit;
                if Result=mrIgnore then Result:=mrOk;
              end;
            until Result<>mrRetry;
            Result:=mrCancel;
          end;
        end;
      finally
        BinCompStream.Free;
      end;
    end;
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.DoSaveEditorUnit F ',ResourceCode.Modified);
{$ENDIF}
    if not SaveToTestDir then begin
      if ResourceCode.Modified then begin
        Result:=DoSaveCodeBufferToFile(ResourceCode,ResourceCode.Filename,
            ActiveUnitInfo.IsPartOfProject);
        if not Result=mrOk then exit;
        Result:=mrCancel;
      end;
    end else begin
      // ToDo: calculate a better resource filename
{$IFDEF IDE_DEBUG}
writeln('>>>>>>>>>>>>> ',TestFilename,' ',ChangeFileExt(TestFilename,ResourceFileExt));
{$ENDIF}
      Result:=DoSaveCodeBufferToFile(ResourceCode,
                  ChangeFileExt(TestFilename,ResourceFileExt),false);
      if not Result=mrOk then exit;
      Result:=mrCancel;
    end;
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.DoSaveEditorUnit G ',LFMCode<>nil);
{$ENDIF}
  end;
  if not SaveToTestDir then begin
    ActiveUnitInfo.Modified:=false;
    ActiveSrcEdit.Modified:=false;
  end;
  SourceNoteBook.UpdateStatusBar;
writeln('TMainIDE.DoSaveEditorUnit END');
  Result:=mrOk;
end;

function TMainIDE.DoCloseEditorUnit(PageIndex:integer; 
  SaveFirst: boolean):TModalResult;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  ACaption,AText: string;
  i:integer;
  OldDesigner: TDesigner;
begin
writeln('TMainIDE.DoCloseEditorUnit A PageIndex=',PageIndex);
  Result:=mrCancel;
  GetUnitWithPageIndex(PageIndex,ActiveSrcEdit,ActiveUnitInfo);
  if ActiveUnitInfo=nil then exit;
  if ActiveUnitInfo.Form=FLastFormActivated then
    FLastFormActivated:=nil;
  ActiveUnitInfo.ReadOnly:=ActiveSrcEdit.ReadOnly;
  ActiveUnitInfo.TopLine:=ActiveSrcEdit.EditorComponent.TopLine;
  ActiveUnitInfo.CursorPos:=ActiveSrcEdit.EditorComponent.CaretXY;
  if SaveFirst and (not ActiveUnitInfo.ReadOnly) 
  and ((ActiveSrcEdit.Modified) or (ActiveUnitInfo.Modified)) then begin
    if ActiveUnitInfo.Filename<>'' then
      AText:='File "'+ActiveUnitInfo.Filename+'" has changed. Save?'
    else if ActiveUnitInfo.UnitName<>'' then
      AText:='Unit "'+ActiveUnitInfo.Unitname+'" has changed. Save?'
    else
      AText:='Source of page "'+
        SourceNotebook.NoteBook.Pages[SourceNotebook.NoteBook.PageIndex]
        +'" has changed. Save?';
    ACaption:='Source mofified';
    if Messagedlg(ACaption, AText, mtconfirmation, [mbyes, mbno], 0)=mryes then
    begin
      Result:=DoSaveEditorUnit(PageIndex,false,false,false);
      if Result=mrAbort then exit;
    end;
    Result:=mrOk;
  end;
  // close form
  if ActiveUnitInfo.Form<>nil then begin
    for i:=TWinControl(ActiveUnitInfo.Form).ComponentCount-1 downto 0 do
      TheControlSelection.Remove(
        TWinControl(ActiveUnitInfo.Form).Components[i]);
    TheControlSelection.Remove(TControl(ActiveUnitInfo.Form));
    OldDesigner:=TDesigner(TCustomForm(ActiveUnitInfo.Form).Designer);
    FormEditor1.DeleteControl(ActiveUnitInfo.Form);
    OldDesigner.Free;
    ActiveUnitInfo.Form:=nil;
  end;
  // close source editor
  SourceNoteBook.CloseFile(PageIndex);
  // close project file (not remove)
  Project.CloseEditorIndex(ActiveUnitInfo.EditorIndex);
  ActiveUnitInfo.Loaded:=false;
  i:=Project.IndexOf(ActiveUnitInfo);
  if (i<>Project.MainUnit) and (ActiveUnitInfo.Source.IsVirtual) then begin
    Project.RemoveUnit(i);
  end;
writeln('TMainIDE.DoCloseEditorUnit end');
  Result:=mrOk;
end;

function TMainIDE.DoOpenEditorFile(const AFileName:string; 
  ProjectLoading, OnlyIfExists:boolean):TModalResult;
var Ext,ACaption,AText:string;
  i,BookmarkID:integer;
  ReOpen:boolean;
  NewUnitInfo:TUnitInfo;
  NewPageName, NewProgramName, LFMFilename: string;
  NewSrcEdit: TSourceEditor;
  TxtLFMStream, BinLFMStream:TMemoryStream;
  CInterface: TComponentInterface;
  TempForm: TCustomForm;
  PreReadBuf, NewBuf: TCodeBuffer;
begin
writeln('');
writeln('*** TMainIDE.DoOpenEditorFile START "',AFilename,'"');
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  Result:=mrCancel;
  if ExtractFilenameOnly(AFilename)='' then exit;
  if (Project.IsVirtual)
  and (Project.Units[Project.MainUnit].Filename=AFilename) then begin
    Result:=DoOpenMainUnit(ProjectLoading);
    exit;
  end;
  // check if the project knows this file
  i:=Project.UnitCount-1;
  while (i>=0) and (CompareFilenames(Project.Units[i].Filename,AFileName)<>0) do
    dec(i);
  ReOpen:=(i>=0);
  if ReOpen then begin
    NewUnitInfo:=Project.Units[i];
    if (not ProjectLoading) and NewUnitInfo.Loaded then begin
      // file already open -> change to page
      SourceNoteBook.NoteBook.PageIndex:=NewUnitInfo.EditorIndex;
      Result:=mrOk;
      exit;
    end;
  end;
  if (not FileExists(AFilename)) then begin
    if ProjectLoading then begin
      Result:=MessageDlg('File not found',
        'The file "'+AFilename+'"'#13
        +'was not found.'#13
        +'Ignore  will go on loading the project,'#13
        +'Abort  will cancel the loading.',
        mtError, [mbIgnore, mbAbort], 0);
      exit;
    end;
    if (not OnlyIfExists)
    and (MessageDlg('File not found',
      'File "'+AFilename+'" not found.'#13
      +'Do you want to create it?'#13
      ,mtInformation,[mbYes,mbNo],0)=mrYes) then
    begin
      // create new file
      Ext:=lowercase(ExtractFileExt(AFilename));
      if (Ext='.pas') or (Ext='.pp') or (Ext='.lpr') or (Ext='.dpr') then
        Result:=DoNewEditorUnit(nuUnit,AFilename)
      else
        Result:=DoNewEditorUnit(nuEmpty,AFilename);
      exit;
    end else if OnlyIfExists then begin
      MessageDlg('File not found','File "'+AFilename+'" not found.'#13,
                 mtInformation,[mbCancel],0);
      // cancel loading file
      exit;
    end else begin
      // cancel loading file
      exit;
    end;
  end;
  Ext:=lowercase(ExtractFileExt(AFilename));
  if ReOpen then begin
    NewUnitInfo:=Project.Units[i];
    Result:=DoLoadCodeBuffer(NewBuf,AFileName,true,true,true);
    if Result<>mrOk then exit;
    NewUnitInfo.Source:=NewBuf;
    if (Ext='.pp') or (Ext='.pas') then
      NewUnitInfo.ReadUnitNameFromSource;
  end else begin
    if (not ProjectLoading) and (ToolStatus=itNone)
    and ((Ext='.lpi') or (Ext='.lpr')) then begin
      // load program file and project info file
      Result:=DoOpenProjectFile(AFilename);
      exit;
    end;
    Result:=DoLoadCodeBuffer(PreReadBuf,AFileName,true,true,true);
    if Result<>mrOk then exit;
    Result:=mrCancel;
    // check if unit is a program
    if (not ProjectLoading) and (not ReOpen)
    and ((Ext='.pp') or (Ext='.pas') or (Ext='.dpr') or (Ext='.lpr'))
    and (CodeToolBoss.GetSourceType(PreReadBuf)='PROGRAM') then begin
      NewProgramName:=CodeToolBoss.GetSourceName(PreReadBuf);
      if NewProgramName<>'' then begin
        if FileExists(ChangeFileExt(AFilename,'.lpi')) then begin
          AText:='The file "'+AFilename+'"'#13
              +'seems to be the program file of an existing lazarus project.'#13
              +'Open project?'#13
              +'Cancel will load the source.';
          ACaption:='Project info file detected';
          if MessageDlg(ACaption, AText, mtconfirmation, 
               [mbok, mbcancel], 0)=mrOk then
          begin
            Result:=DoOpenProjectFile(ChangeFileExt(AFilename,'.lpi'));
            exit;
          end;
        end else begin
          AText:='The file "'+AFilename+'"'#13
              +'seems to be a program. Close current project'
              +' and create a new lazarus project for this program?'#13
              +'Cancel will load the source.';
          ACaption:='Program detected';
          if MessageDlg(ACaption, AText, mtconfirmation,
              [mbok, mbcancel], 0)=mrOk then 
          begin
            Result:=DoCreateProjectForProgram(PreReadBuf);
            exit;
          end;
        end;
      end;
    end;
    NewUnitInfo:=TUnitInfo.Create(PreReadBuf);
    if (Ext='.pp') or (Ext='.pas') then
      NewUnitInfo.ReadUnitNameFromSource;
    Project.AddUnit(NewUnitInfo,false);
  end;
  NewUnitInfo.ReadOnly:=NewUnitInfo.ReadOnly 
                        or (not FileIsWritable(NewUnitInfo.Filename));
{$IFDEF IDE_DEBUG}
writeln('[TMainIDE.DoOpenEditorFile] B');
{$ENDIF}
  // create a new source editor
  NewUnitInfo.SyntaxHighlighter:=ExtensionToLazSyntaxHighlighter(Ext);
  NewPageName:=NewUnitInfo.UnitName;
  if NewPageName='' then begin
    NewPageName:=ExtractFileName(AFilename);
    if (Ext='.pas') or (Ext='.pp') then
      NewPageName:=copy(NewPageName,1,length(NewPageName)-length(Ext));
    if NewpageName='' then NewPageName:='file';
  end;
  SourceNotebook.NewFile(NewPageName,NewUnitInfo.Source);
  NewSrcEdit:=SourceNotebook.GetActiveSE;
  if not ProjectLoading then
    Project.InsertEditorIndex(SourceNotebook.NoteBook.PageIndex)
  else begin
    for BookmarkID:=0 to 9 do begin
      i:=Project.Bookmarks.IndexOfID(BookmarkID);
      if (i>=0) and (Project.Bookmarks[i].EditorIndex=NewUnitInfo.EditorIndex)
      then begin
        NewSrcEdit.EditorComponent.SetBookmark(BookmarkID,
           Project.Bookmarks[i].CursorPos.X,Project.Bookmarks[i].CursorPos.Y);
        while i>=0 do begin
          Project.Bookmarks.Delete(i);
          i:=Project.Bookmarks.IndexOfID(BookmarkID);
        end;
      end;
    end;
  end;
  NewUnitInfo.EditorIndex:=SourceNotebook.NoteBook.PageIndex;
  NewSrcEdit.SyntaxHighlighterType:=NewUnitInfo.SyntaxHighlighter;
  NewSrcEdit.EditorComponent.CaretXY:=NewUnitInfo.CursorPos;
  NewSrcEdit.EditorComponent.TopLine:=NewUnitInfo.TopLine;
  NewSrcEdit.EditorComponent.LeftChar:=1;
  NewSrcEdit.ReadOnly:=NewUnitInfo.ReadOnly;
  
{$IFDEF IDE_DEBUG}
writeln('[TMainIDE.DoOpenEditorFile] C');
{$ENDIF}
  NewUnitInfo.Loaded:=true;
  // read form data
  if (NewUnitInfo.Unitname<>'') then begin
    // this is a unit -> try to find the lfm file
    LFMFilename:=ChangeFileExt(NewUnitInfo.Filename,'.lfm');
    NewBuf:=nil;
    if FileExists(LFMFilename) then begin
      Result:=DoLoadCodeBuffer(NewBuf,LFMFilename,true,false,true);
      if Result<>mrOk then exit;
      Result:=mrCancel;
    end else begin
      i:=-1;
      NewBuf:=CodeToolBoss.FindNextResourceFile(NewUnitInfo.Source,i);
      if NewBuf<>nil then begin
        LFMFilename:=ChangeFileExt(NewBuf.Filename,'.lfm');
        NewBuf:=nil;
        if FileExists(LFMFilename) then begin
          Result:=DoLoadCodeBuffer(NewBuf,LFMFilename,true,false,true);
          if Result<>mrOk then exit;
          Result:=mrCancel;
        end;
      end;
    end;
    
    if NewBuf<>nil then begin
      // there is a lazarus form text file -> load it
      BinLFMStream:=TMemoryStream.Create;
      try
        TxtLFMStream:=TMemoryStream.Create;
        try
          NewBuf.SaveToStream(TxtLFMStream);
          TxtLFMStream.Position:=0;
          // convert text to binary format
          try
            ObjectTextToBinary(TxtLFMStream,BinLFMStream);
            BinLFMStream.Position:=0;
            Result:=mrOk;
          except
            on E: Exception do begin
              ACaption:='Format error';
              AText:='Unable to convert text form data of file '#13
                +'"'+NewBuf.Filename+'"'#13
                +'into binary stream. ('+E.Message+')';
              Result:=MessageDlg(ACaption, AText, mterror, [mbok, mbcancel], 0);
              if Result=mrCancel then Result:=mrAbort;
              if Result<>mrOk then exit;
            end;
          end;
        finally
          TxtLFMStream.Free;
        end;
        if not Assigned(FormEditor1) then
          FormEditor1 := TFormEditor.Create;
        if not ProjectLoading then FormEditor1.ClearSelected;

        // create jitform
        CInterface := TComponentInterface(
          FormEditor1.CreateFormFromStream(BinLFMStream));
        if CInterface=nil then begin
          ACaption:='Form load error';
          AText:='Unable to build form from file '#13
                      +'"'+NewBuf.Filename+'".';
          Result:=MessageDlg(ACaption, AText, mterror, [mbok, mbcancel], 0);
          if Result=mrCancel then Result:=mrAbort;
          if Result<>mrOk then exit;
        end;
        TempForm:=TForm(CInterface.Control);
        NewUnitInfo.Form:=TempForm;
        SetDefaultsForForm(TempForm);
        NewUnitInfo.FormName:=TempForm.Name;
        // show form
        TDesigner(TempForm.Designer).SourceEditor := SourceNoteBook.GetActiveSE;

        if not ProjectLoading then begin
          TempForm.Show;
          FCodeLastActivated:=false;
        end;
        SetDesigning(TempForm,True);
        
        // select the new form (object inspector, formeditor, control selection)
        if not ProjectLoading then begin
          PropertyEditorHook1.LookupRoot := TForm(CInterface.Control);
          TDesigner(TempForm.Designer).SelectOnlyThisComponent(TempForm);
        end;
{$IFDEF IDE_DEBUG}
writeln('[TMainIDE.DoOpenEditorFile] LFM end');
{$ENDIF}
      finally
        BinLFMStream.Free;
      end;
    end;
  end;
  SourceNoteBook.UpdateStatusBar;
  Result:=mrOk;
writeln('TMainIDE.DoOpenEditorFile END "',AFilename,'" NewSrcEdit.Filename=',NewSrcEdit.Filename);
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
end;

function TMainIDE.DoOpenMainUnit(ProjectLoading: boolean): TModalResult;
var MainUnitInfo: TUnitInfo;
  NewPageName, Ext: string;
  NewSrcEdit: TSourceEditor;
begin
writeln('[TMainIDE.DoOpenMainUnit] A');
  Result:=mrCancel;
  if Project.MainUnit<0 then exit;
  MainUnitInfo:=Project.Units[Project.MainUnit];
//writeln('TMainIDE.DoOpenMainUnit B1 ',MainUnitInfo.Source.SourceLength);
  if MainUnitInfo.Loaded then begin
    // already loaded switch to source editor
    SourceNotebook.NoteBook.PageIndex:=MainUnitInfo.EditorIndex;
    Result:=mrOk;
    exit;
  end;
  // MainUnit not loaded -> create source editor
  if MainUnitInfo.Source.IsVirtual then
    NewPageName:=CodeToolBoss.GetSourceName(MainUnitInfo.Source)
  else begin
    NewPageName:=ExtractFileName(MainUnitInfo.Filename);
    Ext:=uppercase(ExtractFileExt(MainUnitInfo.Filename));
    if (Ext='.PAS') or (Ext='.PP') then
      NewPageName:=copy(NewPageName,1,length(NewPageName)-length(Ext));
  end;
//writeln('TMainIDE.DoOpenMainUnit B ',NewPageName,'  ',MainUnitInfo.Source.SourceLength);
  if NewPageName='' then
    NewPageName:='mainunit';
//writeln('TMainIDE.DoOpenMainUnit C ',NewPageName);
  SourceNotebook.NewFile(NewPageName,MainUnitInfo.Source);
  if not ProjectLoading then
    Project.InsertEditorIndex(SourceNotebook.NoteBook.PageIndex);
  MainUnitInfo.EditorIndex:=SourceNotebook.NoteBook.PageIndex;
  MainUnitInfo.Loaded:=true;
  NewSrcEdit:=SourceNotebook.GetActiveSE;
  NewSrcEdit.SyntaxHighlighterType:=MainUnitInfo.SyntaxHighlighter;
  NewSrcEdit.EditorComponent.CaretXY:=MainUnitInfo.CursorPos;
  NewSrcEdit.EditorComponent.TopLine:=MainUnitInfo.TopLine;
  Result:=mrOk;
writeln('[TMainIDE.DoOpenMainUnit] END');
end;

function TMainIDE.DoViewUnitsAndForms(OnlyForms: boolean): TModalResult;
var UnitList: TList;
  i: integer;
  MainUnitName, Ext, DlgCaption: string;
  MainUnitInfo, AnUnitInfo: TUnitInfo;
  MainUnitIndex: integer;
  ActiveSourceEditor: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  AForm: TForm;
Begin
  GetCurrentUnit(ActiveSourceEditor,ActiveUnitInfo);
  UnitList:=TList.Create;
  try
    MainUnitIndex:=-1;
    for i:=0 to Project.UnitCount-1 do begin
      if Project.Units[i].IsPartOfProject then begin
        if OnlyForms then begin
          if Project.MainUnit=i then MainUnitIndex:=i;
          if Project.Units[i].FormName<>'' then
            UnitList.Add(TViewUnitsEntry.Create(
              Project.Units[i].FormName,i,Project.Units[i]=ActiveUnitInfo));
        end else begin
          if Project.Units[i].UnitName<>'' then begin
            if Project.MainUnit=i then MainUnitIndex:=i;
            UnitList.Add(TViewUnitsEntry.Create(
              Project.Units[i].UnitName,i,Project.Units[i]=ActiveUnitInfo));
          end else if Project.MainUnit=i then begin
            MainUnitInfo:=Project.Units[Project.MainUnit];
            if Project.ProjectType in [ptProgram,ptApplication,ptCustomProgram]
            then begin
              if (MainUnitInfo.Loaded) then
                MainUnitName:=SourceNoteBook.NoteBook.Pages[
                  MainUnitInfo.EditorIndex];
              if MainUnitName='' then begin
                MainUnitName:=CodeToolBoss.GetSourceName(MainUnitInfo.Source);
              end;
              if MainUnitName='' then begin
                MainUnitName:=ExtractFileName(MainUnitInfo.Filename);
                Ext:=ExtractFileExt(MainUnitName);
                MainUnitName:=copy(MainUnitName,1,length(MainUnitName)-length(Ext));
              end;
              if MainUnitName<>'' then begin
                MainUnitIndex:=UnitList.Count;
                UnitList.Add(TViewUnitsEntry.Create(
                  MainUnitName,i,MainUnitInfo=ActiveUnitInfo));
              end;
            end;
          end;
        end;
      end;
    end;
    if OnlyForms then
      DlgCaption:='View forms'
    else
      DlgCaption:='View units';
    if ShowViewUnitsDlg(UnitList,true,DlgCaption)=mrOk then begin
      AnUnitInfo:=nil;
      for i:=0 to UnitList.Count-1 do begin
        if TViewUnitsEntry(UnitList[i]).Selected then begin
          AnUnitInfo:=Project.Units[TViewUnitsEntry(UnitList[i]).ID];
          if AnUnitInfo.Loaded then begin
            SourceNoteBook.NoteBook.PageIndex:=AnUnitInfo.EditorIndex;
          end else begin
            if MainUnitIndex=i then
              Result:=DoOpenMainUnit(false)
            else
              Result:=DoOpenEditorFile(AnUnitInfo.Filename,false,true);
            if Result=mrAbort then exit;
          end;
        end;
      end;
      if (AnUnitInfo<>nil) then begin
        AForm:=SourceNotebook;
        if OnlyForms and (AnUnitInfo.Form<>nil) then begin
          AForm:=TForm(AnUnitInfo.Form);
        end;
        BringWindowToTop(AForm.Handle)
      end;
    end;
  finally
    UnitList.Free;
  end;
  Result:=mrOk;
end;

function TMainIDE.DoOpenFileAtCursor(Sender: TObject):TModalResult;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  FName,SPath: String;

  function FindPasFile(var FName: String; SPath: String): Boolean;
  //  Searches for FName in Spath
  //  If FName is not found, we'll check extensions pp and pas too
  //  Returns true if found. FName contains the full file+path in that case
  var TempFile,TempPath,CurPath,Ext: String;
      i,p,c: Integer;
  begin
    if SPath='' then SPath:='.';
    Result:=true;
    for i:=0 to 2 do begin
      case i of
        1: Ext:='.pp';
        2: Ext:='.pas';
        else Ext:='';
      end;
      TempPath:=SPath;
      while TempPath<>'' do begin
        p:=pos(';',TempPath);
        if p=0 then p:=length(TempPath)+1;
        CurPath:=copy(TempPath,1,p-1);
        Delete(TempPath,1,p);
        if CurPath='' then continue;
        if CurPath[length(CurPath)]<>PathDelim then
          CurPath:=CurPath+PathDelim;
        for c:=0 to 2 do begin
          case c of
            0: TempFile:=FName;
            1: TempFile:=LowerCase(FName);
            2: TempFile:=UpperCase(FName);
          end;
          TempFile:=ExpandFileName(CurPath+TempFile+Ext);
          if FileExists(TempFile) then begin
            FName:=TempFile;
            exit;
          end;
        end;
      end;
      if (Ext='') and (ExtractFileExt(FName)<>'') then break;
    end;
    result:=false;
  end;

  function GetFilenameAtRowCol(XY: TPoint): string;
  var
    Line: string;
    Len, Stop: integer;
    StopChars: set of char;
  begin
    Result := '';
    if (XY.Y >= 1) and (XY.Y <= ActiveSrcEdit.EditorComponent.Lines.Count) then 
    begin
      Line := ActiveSrcEdit.EditorComponent.Lines.Strings[XY.Y - 1];
      Len := Length(Line);
      if (XY.X >= 1) and (XY.X <= Len + 1) then begin
        StopChars := [',',';',':','[',']','{','}','(',')',' ','''','"','`'
                     ,'#','%','=','>'];
        Stop := XY.X;
        while (Stop <= Len) and (not (Line[Stop] in StopChars)) do
          Inc(Stop);
        while (XY.X > 1) and (not (Line[XY.X - 1] in StopChars)) do
          Dec(XY.X);
        if Stop > XY.X then
          Result := Copy(Line, XY.X, Stop - XY.X);
      end;
    end;
  end;

begin
  writeln('TMainIDE.DoOpenFileAtCursor');
  Result:=mrCancel;
  GetCurrentUnit(ActiveSrcEdit,ActiveUnitInfo);
  if (ActiveSrcEdit=nil) or (ActiveUnitInfo=nil) then exit;
  FName:=GetFilenameAtRowCol(ActiveSrcEdit.EditorComponent.CaretXY);
  if FName='' then exit;
  if ActiveUnitInfo.IsVirtual then
    SPath:='.'
  else
    SPath:=ExtractFilePath(ActiveUnitInfo.Filename);
  if not Project.IsVirtual then
    SPath:=SPath+';'+ExtractFilePath(Project.ProjectFile);
  if EnvironmentOptions.LazarusDirectory<>'' then
    SPath:=SPath
             +';'+EnvironmentOptions.LazarusDirectory+PathDelim+'lcl'
             +';'+EnvironmentOptions.LazarusDirectory+PathDelim+'designer';
  if FindPasFile(FName,SPath) then begin
    result:=mrOk;
    EnvironmentOptions.LastOpenDialogDir:=ExtractFilePath(FName);
    if DoOpenEditorFile(FName,false,false)=mrOk then begin
      EnvironmentOptions.AddToRecentOpenFiles(FName);
      SaveEnvironment;
    end;
  end;
end;

function TMainIDE.DoNewProject(NewProjectType:TProjectType):TModalResult;
var i:integer;
  ds: char;
Begin
writeln('TMainIDE.DoNewProject A');
  Result:=mrCancel;

  If Project<>nil then begin
    if SomethingOfProjectIsModified then begin
        if MessageDlg('Project changed', 'Save changes to project?', 
          mtconfirmation, [mbyes, mbno], 0)=mryes then begin
        if DoSaveProject(false,false)=mrAbort then begin
          Result:=mrAbort;
          exit;
        end;
      end;
    end;
    if DoCloseProject=mrAbort then begin
      Result:=mrAbort;
      exit;
    end;
  end;

  CodeToolBoss.GlobalValues.Variables[ExternalMacroStart+'ProjectDir']:=
    VirtualDirectory;

  Project:=TProject.Create(NewProjectType);
  Project.OnFileBackup:=@DoBackupFile;
  Project.Title := 'project1';
  Project.CompilerOptions.CompilerPath:='$(CompPath)';

  ds:=PathDelim;
  case NewProjectType of
   ptApplication:
    begin
      // add lcl ppu dirs to unit search path
      Project.CompilerOptions.OtherUnitFiles:=
        '$(LazarusDir)'+ds+'lcl'+ds+'units'
       +';'+
        '$(LazarusDir)'+ds+'lcl'+ds+'units'+ds+'$(LCLWidgetType)';
      // add lcl pp/pas dirs to source search path
      Project.SrcPath:=
        '$(LazarusDir)'+ds+'lcl'
       +';'+
        '$(LazarusDir)'+ds+'lcl'+ds+'interfaces'+ds+'$(LCLWidgetType)';
      // create a first form unit
      DoNewEditorUnit(nuForm,'');
    end;
   ptProgram,ptCustomProgram:
    begin
      // show program unit
      DoOpenMainUnit(false);
    end;
  end;
  
  CreateProjectDefineTemplate(Project.CompilerOptions,Project.SrcPath);
 
  // set all modified to false
  for i:=0 to Project.UnitCount-1 do
    Project.Units[i].Modified:=false;
  Project.Modified:=false;

writeln('TMainIDE.DoNewProject end ',CodeToolBoss.ConsistencyCheck);
  UpdateCaption;
  Result:=mrOk;
end;

function TMainIDE.DoSaveProject(SaveAs, SaveToTestDir:boolean):TModalResult;
var MainUnitSrcEdit, ASrcEdit: TSourceEditor;
  MainUnitInfo, AnUnitInfo: TUnitInfo;
  SaveDialog: TSaveDialog;
  NewFilename, NewProgramFilename, NewPageName, NewProgramName, AText, ACaption,
  Ext: string;
  i, BookmarkID, BookmarkX, BookmarkY :integer;
  NewBuf: TCodeBuffer;
begin
  Result:=mrCancel;
  if ToolStatus<>itNone then begin
    Result:=mrAbort;
    exit;
  end;
writeln('TMainIDE.DoSaveProject A SaveAs=',SaveAs,' SaveToTestDir=',SaveToTestDir);
  // check that all new units are saved first to get valid filenames
  for i:=0 to Project.UnitCount-1 do begin
    if (Project.Units[i].Loaded) and (Project.Units[i].IsVirtual)
    and (Project.MainUnit<>i) then begin
      Result:=DoSaveEditorUnit(Project.Units[i].EditorIndex,true,
                               SaveToTestDir,true);
      if (Result=mrAbort) or (Result=mrCancel) then exit;
    end;
  end;

  if SourceNotebook.Notebook=nil then
    Project.ActiveEditorIndexAtStart:=-1
  else
    Project.ActiveEditorIndexAtStart:=SourceNotebook.Notebook.PageIndex;
  MainUnitSrcEdit:=nil;
  if Project.MainUnit>=0 then begin
    MainUnitInfo:=Project.Units[Project.MainUnit];
    if MainUnitInfo.Loaded then begin
      MainUnitSrcEdit:=SourceNoteBook.FindSourceEditorWithPageIndex(
        MainUnitInfo.EditorIndex);
      if MainUnitSrcEdit.Modified then begin
        MainUnitSrcEdit.UpdateCodeBuffer;
        MainUnitInfo.Modified:=true;
      end;
    end;
  end else
    MainUnitInfo:=nil;

  // save some information of the loaded files to the project
  Project.Bookmarks.Clear;
  for i:=0 to Project.UnitCount-1 do begin
    AnUnitInfo:=Project.Units[i];
    if AnUnitInfo.Loaded then begin
{$IFDEF IDE_DEBUG}
writeln('AnUnitInfo.Filename=',AnUnitInfo.Filename);
{$ENDIF}
      ASrcEdit:=SourceNoteBook.FindSourceEditorWithPageIndex(
         AnUnitInfo.EditorIndex);
      AnUnitInfo.TopLine:=ASrcEdit.EditorComponent.TopLine;
      AnUnitInfo.CursorPos:=ASrcEdit.EditorComponent.CaretXY;
      for BookmarkID:=0 to 9 do begin
        if (ASrcEdit.EditorComponent.GetBookMark(
             BookmarkID,BookmarkX,BookmarkY))
        and (Project.Bookmarks.IndexOfID(BookmarkID)<0) then begin
          Project.Bookmarks.Add(TProjectBookmark.Create(BookmarkX,BookmarkY,
              AnUnitInfo.EditorIndex,BookmarkID));
        end;
      end;
    end;
  end;

  SaveAs:=SaveAs or (Project.IsVirtual);
  if SaveAs and (not SaveToTestDir) then begin
    // let user choose a filename
    SaveDialog:=TSaveDialog.Create(Application);
    try
      SaveDialog.Title:='Save Project '+Project.Title+' (*.lpi)';
      if ExtractFileName(Project.ProjectInfoFile)<>'' then
        SaveDialog.FileName:=ExtractFileName(Project.ProjectInfoFile)
      else if Project.ProjectFile<>'' then
        SaveDialog.FileName:=ExtractFileName(Project.ProjectFile)
      else if Project.Title<>'' then
        SaveDialog.Filename:=ChangeFileExt(Project.Title,'.lpi')
      else if SaveDialog.Filename='' then
        SaveDialog.Filename:='project1.lpi';
      repeat
        Result:=mrCancel;
        SaveDialog.InitialDir:=EnvironmentOptions.LastOpenDialogDir;
        if SaveDialog.Execute then begin
          if ExtractFileNameonly(SaveDialog.Filename)='' then begin
            Result:=MessageDlg('Invalid project filename',
              '"'+SaveDialog.Filename+'" is an invalid filename.'#13
              +'Please choose another (e.g. project1.lpi)',
              mtInformation,[mbRetry,mbAbort],0);
            if Result=mrAbort then exit;
          end else begin
            NewFilename:=ExpandFilename(SaveDialog.Filename);
            EnvironmentOptions.LastOpenDialogDir:=ExtractFilePath(NewFilename);
            if ExtractFileExt(NewFilename)='' then
              NewFilename:=NewFilename+'.lpi';
            NewProgramFilename:=ChangeFileExt(
              NewFilename,ProjectDefaultExt[Project.ProjectType]);
            if NewFilename=NewProgramFilename then begin
              ACaption:='Choose a different name';
              AText:='The project info file "'+NewFilename+'"'#13
                 +'is equal to the project source file!';
              Result:=MessageDlg(ACaption, AText, mtError, [mbAbort,mbRetry],0);
              if Result=mrAbort then exit;
            end else begin
              Result:=mrOk;
            end;
          end;
        end else begin
          // user cancels
          Result:=mrCancel;
          exit;
        end;
      until Result<>mrRetry;

      if FileExists(NewFilename) then begin
        ACaption:='Overwrite file?';
        AText:='A file "'+NewFilename+'" already exists.'#13'Replace it?';
        Result:=MessageDlg(ACaption, AText, mtconfirmation, [mbok, mbcancel], 0);
        if Result=mrCancel then exit;
      end else if Project.ProjectType in [ptProgram, ptApplication] then begin
        if FileExists(NewProgramFilename) then begin
          ACaption:='Overwrite file?';
          AText:='A file "'+NewProgramFilename+'" already exists.'#13
                          +'Replace it?';
          Result:=MessageDlg(ACaption, AText, mtConfirmation,[mbOk,mbCancel],0);
          if Result=mrCancel then exit;
        end;
      end;
      Project.ProjectFile:=NewFilename;
      CodeToolBoss.GlobalValues.Variables[ExternalMacroStart+'ProjectDir']:=
        ExtractFilePath(Project.ProjectFile);
      CodeToolBoss.DefineTree.ClearCache;
      EnvironmentOptions.AddToRecentProjectFiles(NewFilename);
      if (MainUnitInfo<>nil) then begin
        // switch MainUnitInfo to new code
        NewBuf:=CodeToolBoss.CreateFile(NewProgramFilename);
        if NewBuf=nil then begin
          Result:=MessageDlg('Error creating file','Unable to create file'#13
               +'"'+NewProgramFilename+'"',mtError,[mbCancel],0);
          exit;
        end;
        NewBuf.Source:=MainUnitInfo.Source.Source;
        MainUnitInfo.Source:=NewBuf;
        if MainUnitSrcEdit<>nil then
          MainUnitSrcEdit.CodeBuffer:=NewBuf;
        // change program name
        NewProgramName:=ExtractFileNameOnly(NewProgramFilename);
        MainUnitInfo.UnitName:=NewProgramName;
        
        // TODO: rename resource file
        
        // update source editor of main unit
        MainUnitInfo.Modified:=true;
        NewPageName:=ExtractFileName(MainUnitInfo.Filename);
        Ext:=ExtractFileExt(NewPagename);
        if (Ext='.pp') or (Ext='.pas') then
          NewPageName:=copy(NewpageName,1,length(NewPageName)-length(Ext));
        if MainUnitInfo.EditorIndex>=0 then begin
          NewPageName:=SourceNoteBook.FindUniquePageName(
            NewPageName,MainUnitInfo.EditorIndex);
          SourceNoteBook.NoteBook.Pages[MainUnitInfo.EditorIndex]:=
            NewPageName;
        end;
      end;
    finally
      SaveDialog.Free;
    end;
  end;
  if not SaveToTestDir then begin
    Result:=Project.WriteProject;
    if Result=mrAbort then exit;
  end;
  // save main source
  if MainUnitInfo<>nil then begin
    if MainUnitInfo.Loaded then begin
      // shown in source editor
      Result:=DoSaveEditorUnit(MainUnitInfo.EditorIndex,false,SaveToTestDir,
                               true);
      if Result=mrAbort then exit;
    end else begin
      // not shown in source editor, but code internally loaded
      if not SaveToTestDir then begin
        Result:=DoSaveCodeBufferToFile(MainUnitInfo.Source,
                                       MainUnitInfo.Filename,true);
      end else begin
        Result:=DoSaveCodeBufferToFile(MainUnitInfo.Source,
                                       GetTestUnitFilename(MainUnitInfo),false);
      end;
      if Result=mrAbort then exit;
    end;
  end;
  if not SaveToTestDir then begin
    EnvironmentOptions.LastSavedProjectFile:=Project.ProjectInfoFile;
    EnvironmentOptions.Save(false);
    if (Result=mrOk) then begin
      if MainUnitInfo<>nil then MainUnitInfo.Modified:=false;
      if MainUnitSrcEdit<>nil then MainUnitSrcEdit.Modified:=false;
    end;
    UpdateCaption;
  end;

  // save editor files
  if (SourceNoteBook.Notebook<>nil) and (not SaveToTestDir) then begin
    for i:=0 to SourceNoteBook.Notebook.Pages.Count-1 do begin
      if (Project.MainUnit<0)
      or (Project.Units[Project.MainUnit].EditorIndex<>i) then begin
        Result:=DoSaveEditorUnit(i,false,SaveToTestDir,true);
        if Result=mrAbort then exit;
      end;
    end;
  end;
writeln('TMainIDE.DoSaveProject End');
end;

function TMainIDE.DoCloseProject:TModalResult;
begin
writeln('TMainIDE.DoCloseProject A');
  // close all loaded files
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  while SourceNotebook.NoteBook<>nil do begin
    Result:=DoCloseEditorUnit(SourceNotebook.Notebook.Pages.Count-1,false);
    if Result=mrAbort then exit;
  end;
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  // close Project
  Project.Free;
  Project:=nil;
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  Result:=mrOk;
writeln('TMainIDE.DoCloseProject end ',CodeToolBoss.ConsistencyCheck);
end;

function TMainIDE.DoOpenProjectFile(AFileName:string):TModalResult;
var Ext,AText,ACaption,LPIFilename:string;
  LowestEditorIndex,LowestUnitIndex,LastEditorIndex,i:integer;
  NewBuf: TCodeBuffer;
begin
writeln('TMainIDE.DoOpenProjectFile A "'+AFileName+'"');
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  Result:=mrCancel;
  if ExtractFileNameOnly(AFileName)='' then exit;
  AFilename:=ExpandFileName(AFilename);
  Ext:=lowercase(ExtractFileExt(AFilename));
  repeat
    if not FileExists(AFilename) then begin
      ACaption:='File not found';
      AText:='File "'+AFilename+'" not found.';
      Result:=MessageDlg(ACaption, AText, mtError, [mbAbort, mbRetry], 0);
      if Result=mrAbort then exit;
    end;
  until Result<>mrRetry;
  Result:=mrCancel;
  if (FileExists(ChangeFileExt(AFileName,'.lpi'))) then begin
    // load instead of lazarus program file the project info file
    AFileName:=ChangeFileExt(AFileName,'.lpi');
    Ext:='.lpi';
  end;
  if Ext<>'.lpi' then begin
    Result:=DoOpenEditorFile(AFilename,false,false);
    exit;
  end;
  if FileExists(AFilename) and (not FileIsText(AFilename)) then begin
    ACaption:='File not text';
    AText:='File "'+AFilename+'"'#13
          +'does not look like a text file.'#13
          +'Open it anyway?';
    Result:=MessageDlg(ACaption, AText, mtConfirmation, [mbYes, mbAbort], 0);
    if Result=mrAbort then exit;
  end;
  // close the old project
  if SomethingOfProjectIsModified then begin
    if MessageDlg('Project changed', 'Save changes to project?',
      mtconfirmation,[mbYes, mbNo],0)=mrYes then
    begin
      if DoSaveProject(false,false)=mrAbort then begin
        Result:=mrAbort;
        exit;
      end;
    end;
  end;
  Result:=DoCloseProject;
  if Result=mrAbort then exit;
  // create a new one
writeln('TMainIDE.DoOpenProjectFile B');
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  LPIFilename:=ChangeFileExt(AFilename,'.lpi');
  Project:=TProject.Create(ptProgram);
  Project.ReadProject(LPIFilename);
  if Project.MainUnit>=0 then begin
    // read MainUnit Source
    Result:=DoLoadCodeBuffer(NewBuf,Project.Units[Project.MainUnit].Filename,
                             true,true,true);
    if Result=mrIgnore then Result:=mrAbort;
    if Result=mrAbort then exit;
    Project.Units[Project.MainUnit].Source:=NewBuf;
  end;
{$IFDEF IDE_DEBUG}
writeln('TMainIDE.DoOpenProjectFile C');
{$ENDIF}
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
  UpdateCaption;
  // restore files
  LastEditorIndex:=-1;
  repeat
    // find the unit which was loaded last time and has the lowest editor index
    // of all not opened units
    LowestUnitIndex:=-1;
    LowestEditorIndex:=-1;
    for i:=0 to Project.UnitCount-1 do begin
      if (Project.Units[i].Loaded) then begin
        if (Project.Units[i].EditorIndex>LastEditorIndex)
        and ((Project.Units[i].EditorIndex<LowestEditorIndex)
             or (LowestEditorIndex<0)) then
        begin
          LowestEditorIndex:=Project.Units[i].EditorIndex;
          LowestUnitIndex:=i;
        end;
      end;
    end;
    if LowestEditorIndex>=0 then begin
      // reopen file
//writeln('TMainIDE.DoOpenProjectFile C2 ',Project.Units[LowestUnitIndex].Filename);
      Result:=DoOpenEditorFile(Project.Units[LowestUnitIndex].Filename,true,
                               true);
//writeln('TMainIDE.DoOpenProjectFile C3 ',Result=mrOk);
      if Result=mrAbort then begin
        // mark all files, that are left to load as unloaded:
        for i:=0 to Project.UnitCount-1 do begin
          if Project.Units[i].Loaded 
          and (Project.Units[i].EditorIndex>LastEditorIndex) then begin
            Project.Units[i].Loaded:=false;
            Project.Units[i].EditorIndex:=-1;
            Project.ActiveEditorIndexAtStart:=-1;
          end;
        end;
        exit;
      end;
      if Result=mrOk then begin
        // open successful
        if Project.ActiveEditorIndexAtStart=LowestEditorIndex then
          Project.ActiveEditorIndexAtStart:=SourceNoteBook.NoteBook.PageIndex;
        LastEditorIndex:=LowestEditorIndex;
      end else begin
        // open failed -> ignore this unit
        Project.Units[LowestUnitIndex].EditorIndex:=-1;
        Project.Units[LowestUnitIndex].Loaded:=false;
        if Project.ActiveEditorIndexAtStart=LowestEditorIndex then
          Project.ActiveEditorIndexAtStart:=-1;
      end;
    end;
  until LowestEditorIndex<0;
  Result:=mrCancel;
//writeln('TMainIDE.DoOpenProjectFile D');
  // set active editor source editor
  if (SourceNoteBook.NoteBook<>nil) and (Project.ActiveEditorIndexAtStart>=0)
  and (Project.ActiveEditorIndexAtStart<SourceNoteBook.NoteBook.Pages.Count)
  then
    SourceNoteBook.Notebook.PageIndex:=Project.ActiveEditorIndexAtStart;

  // set all modified to false
  for i:=0 to Project.UnitCount-1 do begin
    Project.Units[i].Modified:=false;
  end;
  Project.Modified:=false;
  EnvironmentOptions.LastSavedProjectFile:=Project.ProjectInfoFile;
  EnvironmentOptions.Save(false);
  Result:=mrOk;
writeln('TMainIDE.DoOpenProjectFile end  CodeToolBoss.ConsistencyCheck=',CodeToolBoss.ConsistencyCheck);
{$IFDEF IDE_MEM_CHECK}
CheckHeap(IntToStr(GetMem_Cnt));
{$ENDIF}
end;

function TMainIDE.DoCreateProjectForProgram(
  ProgramBuf: TCodeBuffer): TModalResult;
var NewProjectType:TProjectType;
  ProgramTitle, Ext: string;
  MainUnitInfo: TUnitInfo;
begin
writeln('[TMainIDE.DoCreateProjectForProgram] A ',ProgramBuf.Filename);
  Result:=mrCancel;

  if SomethingOfProjectIsModified then begin
    if MessageDlg('Project changed','Save changes to project?',
      mtconfirmation,[mbYes, mbNo],0)=mrYes then
    begin
      if DoSaveProject(false,false)=mrAbort then begin
        Result:=mrAbort;
        exit;
      end;
    end;
  end;

  // let user choose the program type
  if ChooseNewProject(NewProjectType)=mrCancel then exit;

  // close old project
  If Project<>nil then begin
    if DoCloseProject=mrAbort then begin
      Result:=mrAbort;
      exit;
    end;
  end;

  // create a new project
  Project:=TProject.Create(NewProjectType);
  Project.OnFileBackup:=@DoBackupFile;
  ProgramTitle:=ExtractFileName(ProgramBuf.Filename);
  Ext:=ExtractFileExt(ProgramTitle);
  ProgramTitle:=copy(ProgramTitle,1,length(ProgramTitle)-length(Ext));
  Project.Title:=ProgramTitle;
  MainUnitInfo:=Project.Units[Project.MainUnit];
  MainUnitInfo.Source:=ProgramBuf;
  Project.ProjectFile:=ProgramBuf.Filename;
  Project.CompilerOptions.CompilerPath:='$(CompPath)';
  if NewProjectType=ptApplication then begin
    Project.CompilerOptions.OtherUnitFiles:=
       '$(LazarusDir)'+PathDelim+'lcl'+PathDelim+'units'
      +';'+
       '$(LazarusDir)'+PathDelim+'lcl'+PathDelim+'units'
       +PathDelim
       +CodeToolBoss.GlobalValues.Variables[ExternalMacroStart+'LCLWidgetType'];
  end;

  // show program unit
  Result:=DoOpenMainUnit(false);
  if Result=mrAbort then exit;
 
  UpdateCaption;

writeln('[TMainIDE.DoCreateProjectForProgram] END');
  Result:=mrOk;
end;

function TMainIDE.DoAddActiveUnitToProject: TModalResult;
var
  ActiveSourceEditor:TSourceEditor; 
  ActiveUnitInfo:TUnitInfo;
  s, ShortUnitName: string;
begin
  Result:=mrCancel;
  GetCurrentUnit(ActiveSourceEditor,ActiveUnitInfo);
  if ActiveUnitInfo<>nil then begin
    if ActiveUnitInfo.IsPartOfProject=false then begin
      if not ActiveUnitInfo.IsVirtual then
        s:='"'+ActiveUnitInfo.Filename+'"'
      else
        s:='"'+SourceNotebook.Notebook.Pages[SourceNotebook.Notebook.PageIndex]
          +'"';
      if (Project.ProjectType in [ptProgram, ptApplication])
      and (ActiveUnitInfo.UnitName<>'')
      and (Project.IndexOfUnitWithName(ActiveUnitInfo.UnitName,true)>=0) then
      begin
        MessageDlg('Unable to add '+s+' to project, because there is already a '
           +'unit with the same name in the project.',mtInformation,[mbOk],0);
      end else begin
        if MessageDlg('Add '+s+' to project?',mtConfirmation,[mbOk,mbCancel],0)
          =mrOk then
        begin
          ActiveUnitInfo.IsPartOfProject:=true;
          if (ActiveUnitInfo.UnitName<>'')
          and (Project.ProjectType in [ptProgram, ptApplication]) then begin
            ShortUnitName:=CodeToolBoss.GetSourceName(ActiveUnitInfo.Source);
            if ShortUnitName='' then ShortUnitName:=ActiveUnitInfo.UnitName;
            if (ShortUnitName<>'') then
              CodeToolBoss.AddUnitToMainUsesSection(
                 Project.Units[Project.MainUnit].Source,ShortUnitName,'');
          end;
          Project.Modified:=true;
        end;
      end;
    end else begin
      if not ActiveUnitInfo.IsVirtual then
        s:='The file "'+ActiveUnitInfo.Filename+'"'
      else
        s:='The file "'
          +SourceNotebook.Notebook.Pages[SourceNotebook.Notebook.PageIndex]
          +'"';
      s:=s+' is already part of the project.';
      MessageDlg(s,mtInformation,[mbOk],0);
    end;
  end else begin
    Result:=mrOk;
  end;
end;

function TMainIDE.DoRemoveFromProjectDialog: TModalResult;
var UnitList: TList;
  i:integer;
  AName: string;
  AnUnitInfo: TUnitInfo;
Begin
  UnitList:=TList.Create;
  try
    for i:=0 to Project.UnitCount-1 do begin
      AnUnitInfo:=Project.Units[i];
      if (AnUnitInfo.IsPartOfProject) and (i<>Project.MainUnit) then begin
        AName:=AnUnitInfo.FileName;
        if (AnUnitInfo.IsVirtual) and (AnUnitInfo.Loaded) then begin
          AName:=SourceNotebook.NoteBook.Pages[AnUnitInfo.EditorIndex];
        end;
        if not AnUnitInfo.IsVirtual then
          UnitList.Add(TViewUnitsEntry.Create(AName,i,false));
      end;
    end;
    if ShowViewUnitsDlg(UnitList,true,'Remove from project')=mrOk then begin
      for i:=0 to UnitList.Count-1 do begin
        if TViewUnitsEntry(UnitList[i]).Selected then begin
          AnUnitInfo:=Project.Units[TViewUnitsEntry(UnitList[i]).ID];
          AnUnitInfo.IsPartOfProject:=false;
          if (Project.MainUnit>=0)
          and (Project.ProjectType in [ptProgram, ptApplication]) then begin
            if (AnUnitInfo.UnitName<>'') then
              CodeToolBoss.RemoveUnitFromAllUsesSections(
                Project.Units[Project.MainUnit].Source,AnUnitInfo.UnitName);
            if (AnUnitInfo.FormName<>'') then
              Project.RemoveCreateFormFromProjectFile(
                  'T'+AnUnitInfo.FormName,AnUnitInfo.FormName);
          end;
        end;
      end;
    end;
  finally
    UnitList.Free;
  end;
  Result:=mrOk;
end;

function TMainIDE.DoSaveProjectToTestDirectory: TModalResult;
begin
  Result:=mrCancel;
  if (EnvironmentOptions.TestBuildDirectory='')
  or (not DirectoryExists(EnvironmentOptions.TestBuildDirectory)) then begin
    if (EnvironmentOptions.TestBuildDirectory<>'') then begin
      MessageDlg('The Test Directory could not be found:'#13
             +'"'+EnvironmentOptions.TestBuildDirectory+'"'#13
             +'(see environment options)',mtError,[mbCancel],0);
      Result:=mrCancel;
      exit;
    end;
    Result:=MessageDlg('Build new project',
       'The project must be saved before building'#13
      +'If you set the Test Directory in the environment options,'#13
      +'you can create new projects and build them at once.'#13
      +'Save project?',mtInformation,[mbYes,mbNo],0);
    if Result<>mrYes then exit;
    Result:=DoSaveAll;
    exit;
  end;
  Result:=DoSaveProject(false,true);
end;

function TMainIDE.DoBuildProject(BuildAll: boolean): TModalResult;
var ActiveSrcEdit: TSourceEditor;
  DefaultFilename: string;
begin
  Result:=mrCancel;
  if ToolStatus<>itNone then begin
    Result:=mrAbort;
    exit;
  end;
  if Project=nil then Begin
    MessageDlg('Create a project first!',mterror,[mbok],0);
    Exit;
  end;
  try
    if not (Project.ProjectType in [ptProgram, ptApplication, ptCustomProgram])
    then exit;
    if not Project.IsVirtual then
      Result:=DoSaveAll
    else
      Result:=DoSaveProjectToTestDirectory;
    if Result<>mrOk then exit;
    if not Project.IsVirtual then
      DefaultFilename:=''
    else
      DefaultFilename:=GetTestUnitFilename(Project.Units[Project.MainUnit]);

    ActiveSrcEdit:=SourceNotebook.GetActiveSE;
    if ActiveSrcEdit<>nil then ActiveSrcEdit.ErrorLine:=-1;

    ToolStatus:=itBuilder;
    MessagesView.Clear;
    DoArrangeSourceEditorAndMessageView;
   
    TheOutputFilter.OnOutputString:=@MessagesView.Add;
    Result:=TheCompiler.Compile(Project,BuildAll,DefaultFilename);
    if Result=mrOk then begin
      MessagesView.MessageView.Items.Add(
        'Project "'+Project.Title+'" successfully built. :)');
    end else begin
      DoJumpToCompilerMessage(-1,true);
    end;
  finally
    ToolStatus:=itNone;
  end;
end;

function TMainIDE.DoInitProjectRun: TModalResult;
var
  ProgramFilename: String;
begin
  if ToolStatus = itDebugger
  then begin
    // already running so no initialization needed
    Result := mrOk;
    Exit;
  end; 

  Result := mrCancel;

  // Check if we can run this project
  if not (Project.ProjectType in [ptProgram, ptApplication, ptCustomProgram])
  or (Project.MainUnit < 0) 
  or (ToolStatus <> itNone)
  then Exit;

  // Build project first
  if DoBuildProject(false) <> mrOk 
  then Exit;
  
  // Check project build
  ProgramFilename := GetProjectTargetFilename;
  if not FileExists(ProgramFilename)
  then begin
    MessageDlg('File not found', Format('No program file "%s" found!', [ProgramFilename]), mtError, [mbCancel], 0);
    Exit;
  end;

  // Setup debugger
  case EnvironmentOptions.DebuggerType of
    dtGnuDebugger: begin
      if (FDebugger = nil)
      and (DoInitDebugger <> mrOk)
      then Exit;
      FDebugger.FileName := ProgramFilename;
      FDebugger.Arguments := ''; //TODO: get arguments
      FDebugger.Run;
    end;
  else 
    // Temp solution, in futer it will be run by dummy debugger
    try
      CheckIfFileIsExecutable(ProgramFilename);
      FRunProcess := TProcess.Create(nil);
      FRunProcess.CommandLine := ProgramFilename;
      FRunProcess.Options:= [poUsePipes, poNoConsole];
      FRunProcess.ShowWindow := swoNone;
      FRunProcess.Execute;
    except
      on e: Exception do 
        MessageDlg(Format('Error initializing program'#13 + 
                          '"%s"'#13 + 
                          'Error: %s', [ProgramFilename, e.Message]), mterror, [mbok], 0);
    end;
  end;   

  Result := mrOK;
  ToolStatus := itDebugger;
end;

function TMainIDE.DoRunProject: TModalResult;
// ToDo:
//  -implement a better messages-form for vast amount of output
//  -command line parameters
begin
  Writeln('[TMainIDE.DoRunProject] A');
  
  if (DoInitProjectRun <> mrOK)
  or (ToolStatus <> itDebugger)
  then begin
    Result := mrAbort;
    Exit;
  end;

  Result := mrCancel;

  case EnvironmentOptions.DebuggerType of
    dtGnuDebugger: begin
      if FDebugger = nil then Exit;
      FDebugger.Run;
      Result := mrOK;
    end;
  else
    if FRunProcess = nil then Exit;
    try
      Writeln('  EXECUTING "',FRunProcess.CommandLine,'"');
      FRunProcess.Execute;
      ToolStatus:=itNone;
      Result := mrOk;
    except
      on e: Exception do 
        MessageDlg(Format('Error initializing program'#13 + 
                          '"%s"'#13 + 
                          'Error: %s', [FRunProcess.CommandLine, e.Message]), mterror, [mbok], 0);
    end;
  end;   
  Writeln('[TMainIDE.DoRunProject] END');
end;

function TMainIDE.DoPauseProject: TModalResult;
begin
  Result := mrCancel;
  if (ToolStatus <> itDebugger) 
  or (FDebugger = nil) 
  then Exit;
  FDebugger.Pause;
  Result := mrOk;
end;

function TMainIDE.DoStepIntoProject: TModalResult;
begin
  if (DoInitProjectRun <> mrOK)
  or (ToolStatus <> itDebugger)
  or (FDebugger = nil) 
  then begin
    Result := mrAbort;
    Exit;
  end;

  FDebugger.StepInto;
  Result := mrOk;
end;

function TMainIDE.DoStepOverProject: TModalResult;
begin
  if (DoInitProjectRun <> mrOK)
  or (ToolStatus <> itDebugger)
  or (FDebugger = nil) 
  then begin
    Result := mrAbort;
    Exit;
  end;

  FDebugger.StepOver;
  Result := mrOk;
end;

function TMainIDE.DoStopProject: TModalResult;
begin
  Result := mrCancel;
  if (ToolStatus <> itDebugger) 
  or (FDebugger=nil) 
  then Exit;

  FDebugger.Stop;
  Result := mrOk;
end;

function TMainIDE.DoRunToCursor: TModalResult;
var 
  ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  UnitFilename: string;
begin
  if (DoInitProjectRun <> mrOK)
  or (ToolStatus <> itDebugger)
  or (FDebugger = nil) 
  then begin
    Result := mrAbort;
    Exit;
  end;

  Result := mrCancel;

  GetCurrentUnit(ActiveSrcEdit, ActiveUnitInfo);
  if (ActiveSrcEdit=nil) or (ActiveUnitInfo=nil) 
  then begin
    MessageDlg('Run to failed','Please open a unit before run.',mtError,
      [mbCancel],0);
    Exit;
  end;

  if not ActiveUnitInfo.Source.IsVirtual 
  then UnitFilename:=ActiveUnitInfo.Filename
  else UnitFilename:=GetTestUnitFilename(ActiveUnitInfo);

  FDebugger.RunTo(UnitFilename, ActiveSrcEdit.EditorComponent.CaretY);

  Result := mrOK;
end;

function TMainIDE.DoInitDebugger: TModalResult;
var
  OldBreakpoints: TDBGBreakpoints;
begin
  WriteLN('[TMainIDE.DoInitDebugger] A');  
  
  Result:=mrCancel;
  if Project.MainUnit < 0 then Exit;
  
  OldBreakpoints := nil;  

  case EnvironmentOptions.DebuggerType of
    dtGnuDebugger: begin  
      if (FDebugger <> nil) 
      and not (FDebugger is TGDBDebugger) 
      then begin
        OldBreakpoints := TDBGBreakpoints.Create(nil, TDBGBreakpoint);
        OldBreakpoints.Assign(FBreakPoints);
        FBreakPoints := nil; 
        
        FDebugger.Free;
        FDebugger := nil;
      end;
      if FDebugger = nil
      then begin
        if FBreakPoints <> nil
        then begin
          OldBreakpoints := TDBGBreakpoints.Create(nil, TDBGBreakpoint);
          OldBreakpoints.Assign(FBreakPoints);
        end;
        FDebugger := TGDBDebugger.Create;
        FBreakPoints := FDebugger.BreakPoints;
      end;
      if OldBreakpoints <> nil
      then FBreakPoints.Assign(OldBreakpoints);
    end;
  else
    OldBreakpoints := FBreakPoints;
    FBreakPoints := TDBGBreakpoints.Create(nil, TDBGBreakpoint);
    FBreakPoints.Assign(OldBreakpoints);
    
    FDebugger.Free;
    FDebugger := nil;
    Exit;
  end;
  //MainUnitInfo:=Project.Units[Project.MainUnit];
  FDebugger.OnState:=@OnDebuggerChangeState;
  FDebugger.OnCurrent:=@OnDebuggerCurrentLine;
  if FDebugger.State = dsNone 
  then FDebugger.Init;
  
  //TODO: Show/hide debug menuitems based on FDebugger.SupportedCommands 
    
  // property BreakPointGroups: TDBGBreakPointGroups read FBreakPointGroups; // list of all breakpoints
  // property Watches: TDBGWatches read FWatches;   // list of all watches localvars etc
  
  Result := mrOk;
  WriteLN('[TMainIDE.DoInitDebugger] END');  
end;

procedure TMainIDE.OnDebuggerChangeState(Sender: TObject);
const
  // dsNone, dsIdle, dsStop, dsPause, dsRun, dsError
  TOOLSTATEMAP: array[TDBGState] of TIDEToolStatus = (
    // dsNone, dsIdle, dsStop, dsPause, dsRun, dsError
    itNone, itNone, itNone, itDebugger, itDebugger, itDebugger
  );          
  STATENAME: array[TDBGState] of string = (
    'dsNone', 'dsIdle', 'dsStop', 'dsPause', 'dsRun', 'dsError'
  );
begin
  // Is the next line needed ???
  if (Sender<>FDebugger) or (Sender=nil) then exit;
  
  WriteLN('[TMainIDE.OnDebuggerChangeState] state: ', STATENAME[FDebugger.State]);

  // All conmmands
  // -------------------
  // dcRun, dcPause, dcStop, dcStepOver, dcStepInto, dcRunTo, dcJumpto, dcBreak, dcWatch
  // -------------------

  RunSpeedButton.Enabled := dcRun in FDebugger.Commands;
  itmProjectRun.Enabled := RunSpeedButton.Enabled;
  PauseSpeedButton.Enabled := dcPause in FDebugger.Commands;
  itmProjectPause.Enabled := PauseSpeedButton.Enabled;
  StepIntoSpeedButton.Enabled := dcStepInto in FDebugger.Commands;
  itmProjectStepInto.Enabled := StepIntoSpeedButton.Enabled;
  StepOverSpeedButton.Enabled := dcStepOver in FDebugger.Commands;
  itmProjectStepOver.Enabled := StepOverSpeedButton.Enabled;

  itmProjectRunToCursor.Enabled := dcRunTo in FDebugger.Commands;
  itmProjectStop.Enabled := dcStop in FDebugger.Commands;;
  
  // TODO: add other debugger menuitems
  // TODO: implement by actions

  ToolStatus := TOOLSTATEMAP[FDebugger.State];
  
  if FDebugger.State = dsError
  then begin
    WriteLN('Ooops, the debugger entered the error state');
  end;
end;

procedure TMainIDE.OnDebuggerCurrentLine(Sender: TObject; 
  const ALocation: TDBGLocationRec);
// debugger paused program due to pause or error
// -> show the current execution line in editor
// if SrcLine = -1 then no source is available
var 
  ActiveSrcEdit: TSourceEditor;
begin
  if (Sender<>FDebugger) or (Sender=nil) then exit;
  //TODO: Show assembler window if no source can be found.
  if ALocation.SrcLine = -1 then Exit;
  if DoOpenEditorFile(ALocation.SrcFile,false,true) <> mrOk then exit;
  ActiveSrcEdit:=SourceNoteBook.GetActiveSE;
  if ActiveSrcEdit=nil then exit;
  with ActiveSrcEdit.EditorComponent do begin
    CaretXY:=Point(1, ALocation.SrcLine);
    BlockBegin:=CaretXY;
    BlockEnd:=CaretXY;
    TopLine:=ALocation.SrcLine-(LinesInWindow div 2);
  end;
  ActiveSrcEdit.ErrorLine:=ALocation.SrcLine;
end;

function TMainIDE.SomethingOfProjectIsModified: boolean;
begin
  Result:=(Project<>nil) 
      and (Project.SomethingModified or SourceNotebook.SomethingModified);
end;

function TMainIDE.DoSaveAll: TModalResult;
begin
writeln('TMainIDE.DoSaveAll');
  Result:=DoSaveProject(false,false);
  // ToDo: save package, cvs settings, ...
end;

//-----------------------------------------------------------------------------

function TMainIDE.DoRunExternalTool(Index: integer): TModalResult;
begin
  Result:=EnvironmentOptions.ExternalTools.Run(Index,MacroList);
end;

function TMainIDE.DoBuildLazarus: TModalResult;
begin
  Result:=BuildLazarus(MiscellaneousOptions.BuildLazOpts,
                       EnvironmentOptions.ExternalTools,MacroList);
end;

function TMainIDE.DoCheckSyntax: TModalResult;
var
  ActiveUnitInfo:TUnitInfo;
  ActiveSrcEdit:TSourceEditor;
  NewCode: TCodeBuffer;
  NewX, NewY, NewTopLine: integer;
  ErrorMsg: string;
begin
  Result:=mrOk;
  GetCurrentUnit(ActiveSrcEdit,ActiveUnitInfo);
  if (ActiveUnitInfo=nil) or (ActiveUnitInfo.Source=nil)
  or (ActiveSrcEdit=nil) then exit;
  CodeToolBoss.VisibleEditorLines:=ActiveSrcEdit.EditorComponent.LinesInWindow;
  SaveSourceEditorChangesToCodeCache;
  if not CodeToolBoss.CheckSyntax(ActiveUnitInfo.Source,NewCode,NewX,NewY,
    NewTopLine,ErrorMsg) then
  begin
    DoJumpToCodeToolBossError;
  end;
end;

//-----------------------------------------------------------------------------

procedure TMainIDE.GetCurrentUnit(var ActiveSourceEditor:TSourceEditor;
  var ActiveUnitInfo:TUnitInfo);
begin
  if SourceNoteBook.NoteBook=nil then begin
    ActiveSourceEditor:=nil;
    ActiveUnitInfo:=nil;
  end else begin
    GetUnitWithPageIndex(SourceNotebook.NoteBook.PageIndex,ActiveSourceEditor,
       ActiveUnitInfo);
  end;
end;

procedure TMainIDE.GetUnitWithPageIndex(PageIndex:integer; 
  var ActiveSourceEditor:TSourceEditor; var ActiveUnitInfo:TUnitInfo);
begin
  if SourceNoteBook.NoteBook=nil then begin
    ActiveSourceEditor:=nil;
    ActiveUnitInfo:=nil;
  end else begin
    ActiveSourceEditor:=SourceNoteBook.FindSourceEditorWithPageIndex(PageIndex);
    if ActiveSourceEditor=nil then
      ActiveUnitInfo:=nil
    else 
      ActiveUnitInfo:=Project.UnitWithEditorIndex(PageIndex);
  end;
end;

function TMainIDE.DoSaveStreamToFile(AStream:TStream; 
  const Filename:string; IsPartOfProject:boolean):TModalResult;
// save to file with backup and user interaction
var AText,ACaption:string;
  NewBuf: TCodeBuffer;
begin
  Result:=DoBackupFile(Filename,IsPartOfProject);
  if Result<>mrOk then exit;
  repeat
    NewBuf:=CodeToolBoss.CreateFile(FileName);
    if (NewBuf<>nil) or (not NewBuf.SaveToFile(Filename)) then begin
      ACaption:='Write error';
      AText:='Unable to save file "'+Filename+'"';
      Result:=MessageDlg(ACaption,AText,mterror, [mbabort, mbretry, mbignore],0);
      if Result=mrIgnore then Result:=mrOk;
      if Result=mrAbort then exit;
    end;
  until Result<>mrRetry;
end;

function TMainIDE.DoLoadMemoryStreamFromFile(MemStream: TMemoryStream; 
  const AFilename:string): TModalResult;
var FileStream: TFileStream;
  ACaption,AText:string;
begin
  repeat
    try
      FileStream:=TFileStream.Create(AFilename,fmOpenRead);
      try
        FileStream.Position:=0;
        MemStream.CopyFrom(FileStream,FileStream.Size);
        MemStream.Position:=0;
      finally
        FileStream.Free;
      end;
      Result:=mrOk;
    except
      ACaption:='Read Error';
      AText:='Unable to read file "'+AFilename+'"!';
      result := Application.MessageBox(PChar(aText),pChar(aCaption),mb_IconError+mb_AbortRetryIgnore);
      if Result=mrAbort then exit;
    end;
  until Result<>mrRetry;
end;

function TMainIDE.DoSaveCodeBufferToFile(ABuffer: TCodeBuffer;
  const AFilename: string; IsPartOfProject:boolean): TModalResult;
var
  ACaption,AText:string;
begin
  Result:=DoBackupFile(AFilename,IsPartOfProject);
  if Result<>mrOk then exit;
  repeat
    if ABuffer.SaveToFile(AFilename) then begin
      Result:=mrOk;
    end else begin
      ACaption:='Write Error';
      AText:='Unable to write to file "'+AFilename+'"!';
      Result:=MessageDlg(ACaption,AText,mtError,[mbAbort, mbRetry, mbIgnore],0);
      if Result=mrAbort then exit;
      if Result=mrIgnore then Result:=mrOk;
    end;
  until Result<>mrRetry;
end;

function TMainIDE.DoLoadCodeBuffer(var ACodeBuffer: TCodeBuffer; 
  const AFilename: string; UpdateFromDisk, Revert, 
  CheckIfText: boolean): TModalResult;
var
  ACaption,AText:string;
begin
  repeat
writeln('[TMainIDE.DoLoadCodeBuffer] A ',AFilename);
    if CheckIfText and FileExists(AFilename) and (not FileIsText(AFilename)) 
    then begin
      ACaption:='File not text';
      AText:='File "'+AFilename+'"'#13
            +'does not look like a text file.'#13
            +'Open it anyway?';
      Result:=MessageDlg(ACaption, AText, mtConfirmation, 
                         [mbOk, mbIgnore, mbAbort], 0);
      if Result<>mrOk then exit;
    end;
    ACodeBuffer:=CodeToolBoss.LoadFile(AFilename,UpdateFromDisk,Revert);
    if ACodeBuffer<>nil then begin
      Result:=mrOk;
writeln('[TMainIDE.DoLoadCodeBuffer] ',ACodeBuffer.SourceLength,' ',ACodeBuffer.Filename);
    end else begin
      ACaption:='Read Error';
      AText:='Unable to read file "'+AFilename+'"!';
      Result:=MessageDlg(ACaption,AText,mterror,[mbAbort, mbRetry, mbIgnore],0);
      if Result=mrAbort then exit;
    end;
  until Result<>mrRetry;
end;

function TMainIDE.DoBackupFile(const Filename:string; 
  IsPartOfProject:boolean): TModalResult;
var BackupFilename, CounterFilename: string;
  AText,ACaption:string;
  BackupInfo: TBackupInfo;
  FilePath, FileNameOnly, FileExt, SubDir: string;
  i: integer;
begin
  Result:=mrOk;
  if not (FileExists(Filename)) then exit;
  if IsPartOfProject then
    BackupInfo:=EnvironmentOptions.BackupInfoProjectFiles
  else
    BackupInfo:=EnvironmentOptions.BackupInfoOtherFiles;
  if (BackupInfo.BackupType=bakNone)
  or ((BackupInfo.BackupType=bakSameName) and (BackupInfo.SubDirectory='')) then
    exit;
  FilePath:=ExtractFilePath(Filename);
  FileExt:=ExtractFileExt(Filename);
  FileNameOnly:=ExtractFilename(Filename);
  FileNameOnly:=copy(FilenameOnly,1,length(FilenameOnly)-length(FileExt));
  if BackupInfo.SubDirectory<>'' then begin
    SubDir:=FilePath+BackupInfo.SubDirectory;
    repeat
      if not DirectoryExists(SubDir) then begin
        if not CreateDir(SubDir) then begin
          Result:=MessageDlg('Unable to create backup directory "'+SubDir+'".'
                ,mtWarning,[mbAbort,mbRetry,mbIgnore],0);
          if Result=mrAbort then exit;
          if Result=mrIgnore then Result:=mrOk;
        end;
      end;
    until Result<>mrRetry;
  end;
  if BackupInfo.BackupType in
   [bakSymbolInFront,bakSymbolBehind,bakUserDefinedAddExt,bakSameName] then
  begin
    case BackupInfo.BackupType of
      bakSymbolInFront:
        BackupFilename:=FileNameOnly+'.~'+copy(FileExt,2,length(FileExt)-1);
      bakSymbolBehind:
        BackupFilename:=FileNameOnly+FileExt+'~';
      bakUserDefinedAddExt:
        BackupFilename:=FileNameOnly+FileExt+'.'+BackupInfo.AdditionalExtension;
      bakSameName:
        BackupFilename:=FileNameOnly+FileExt;
    end;
    if BackupInfo.SubDirectory<>'' then
      BackupFilename:=SubDir+PathDelim+BackupFilename
    else
      BackupFilename:=FilePath+BackupFilename;
    // remove old backup file
    repeat
      if FileExists(BackupFilename) then begin
        if not DeleteFile(BackupFilename) then begin
          ACaption:='Delete file failed';
          AText:='Unable to remove old backup file "'+BackupFilename+'"!';

//          Result:=Application.MessageBox(PChar(AText),PChar(ACaption),MB_ABORTRETRYIGNORE);
          Result:=MessageDlg(ACaption,AText,mterror,[mbabort,mbretry,mbignore],0);

          if Result=mrAbort then exit;
          if Result=mrIgnore then Result:=mrOk;
        end;
      end;
    until Result<>mrRetry;
  end else begin
    // backup with counter
    if BackupInfo.SubDirectory<>'' then
      BackupFilename:=SubDir+PathDelim+FileNameOnly+FileExt+';'
    else
      BackupFilename:=Filename+';';
    if BackupInfo.MaxCounter<=0 then begin
      // search first non existing backup filename
      i:=1;
      while FileExists(BackupFilename+IntToStr(i)) do inc(i);
      BackupFilename:=BackupFilename+IntToStr(i);
    end else begin
      // rename all backup files (increase number)
      i:=1;
      while FileExists(BackupFilename+IntToStr(i))
      and (i<=BackupInfo.MaxCounter) do inc(i);
      if i>BackupInfo.MaxCounter then begin
        dec(i);
        CounterFilename:=BackupFilename+IntToStr(BackupInfo.MaxCounter);
        // remove old backup file
        repeat
          if FileExists(CounterFilename) then begin
            if not DeleteFile(CounterFilename) then begin
              ACaption:='Delete file failed';
              AText:='Unable to remove old backup file "'+CounterFilename+'"!';
              Result:=MessageDlg(ACaption,AText,mterror,[mbabort,mbretry,mbignore],0);
              if Result=mrAbort then exit;
              if Result=mrIgnore then Result:=mrOk;
            end;
          end;
        until Result<>mrRetry;
      end;
      // rename all old backup files
      dec(i);
      while i>=1 do begin
        repeat
          if not RenameFile(BackupFilename+IntToStr(i),
             BackupFilename+IntToStr(i+1)) then
          begin
            ACaption:='Rename file failed';
            AText:='Unable to rename file "'+BackupFilename+IntToStr(i)
                  +'" to "'+BackupFilename+IntToStr(i+1)+'"!';
            Result:=MessageDlg(ACaption,AText,mterror,[mbabort,mbretry,mbignore],0);
            if Result=mrAbort then exit;
            if Result=mrIgnore then Result:=mrOk;
          end;
        until Result<>mrRetry;
        dec(i);
      end;
      BackupFilename:=BackupFilename+'1';
    end;
  end;
  // backup file
  repeat
    if not RenameFile(Filename,BackupFilename) then begin
      ACaption:='Rename file failed';
      AText:='Unable to rename file "'+Filename+'" to "'+BackupFilename+'"!';
      Result:=MessageDlg(ACaption,AText,mterror,[mbabort,mbretry,mbignore],0);
      if Result=mrAbort then exit;
      if Result=mrIgnore then Result:=mrOk;
    end;
  until Result<>mrRetry;
end;

procedure TMainIDE.UpdateCaption;
var NewCaption:string;
begin
  NewCaption := 'Lazarus Editor v'+Version_String;
  if Project<>nil then begin
    if Project.Title<>'' then
      NewCaption:=NewCaption +' - '+Project.Title
    else if Project.ProjectFile<>'' then
      NewCaption:=NewCaption+' - '+ExtractFileName(Project.ProjectFile)
    else
      NewCaption:=NewCaption+' - (new project)'
  end;
  Caption:=NewCaption;
end;

procedure TMainIDE.DoBringToFrontFormOrUnit;
var AForm: TCustomForm;
  ActiveUnitInfo: TUnitInfo;
begin
  AForm:=nil;
  if FCodeLastActivated then begin
    if SourceNoteBook.NoteBook<>nil then begin
      AForm:=SourceNotebook;
      if FLastFormActivated<>nil then begin
        ActiveUnitInfo := Project.UnitWithForm(FLastFormActivated);
        if (ActiveUnitInfo <> nil) and (ActiveUnitInfo.EditorIndex>=0) then
        begin
          SourceNotebook.Notebook.PageIndex := ActiveUnitInfo.EditorIndex;
        end;
      end;
    end;
  end
  else
  begin
    if (SourceNoteBook.NoteBook<>nil) then begin
      ActiveUnitInfo:=Project.UnitWithEditorIndex(
        SourceNoteBook.NoteBook.PageIndex);
      if (ActiveUnitInfo<>nil) then
        AForm:=TCustomForm(ActiveUnitInfo.Form);
      FLastFormActivated := AForm;
    end;
  end;
  if AForm<>nil then begin
    BringWindowToTop(AForm.Handle);
  end;
end;

procedure TMainIDE.OnMacroSubstitution(TheMacro: TTransferMacro; var s:string;
  var Handled, Abort: boolean);
var MacroName:string;
begin
  if TheMacro=nil then exit;
  MacroName:=lowercase(TheMacro.Name);
  if MacroName='save' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      Abort:=(DoSaveEditorUnit(SourceNoteBook.NoteBook.PageIndex,false,false,
              false)<>mrOk);
    s:='';
  end else if MacroName='saveall' then begin
    Handled:=true;
    Abort:=(DoSaveAll<>mrOk);
    s:='';
  end else if MacroName='edfile' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      s:=Project.UnitWithEditorIndex(SourceNoteBook.NoteBook.PageIndex).Filename
    else
      s:='';
  end else if MacroName='col' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      s:=IntToStr(SourceNoteBook.GetActiveSE.EditorComponent.CaretX);
  end else if MacroName='row' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      s:=IntToStr(SourceNoteBook.GetActiveSE.EditorComponent.CaretY);
  end else if MacroName='projfile' then begin
    Handled:=true;
    s:=Project.ProjectFile;
  end else if MacroName='projpath' then begin
    Handled:=true;
    s:=ExtractFilePath(Project.ProjectFile);
  end else if MacroName='curtoken' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      s:=SourceNoteBook.GetActiveSE.EditorComponent.GetWordAtRowCol(
           SourceNoteBook.GetActiveSE.EditorComponent.CaretXY);
  end else if MacroName='lazarusdir' then begin
    Handled:=true;
    s:=EnvironmentOptions.LazarusDirectory;
    if s='' then s:=ExtractFilePath(ParamStr(0));
  end else if MacroName='lclwidgettype' then begin
    Handled:=true;
    s:=Project.CompilerOptions.LCLWidgetType;
    if s='' then s:='gtk';
  end else if MacroName='fpcsrcdir' then begin
    Handled:=true;
    s:=EnvironmentOptions.FPCSourceDirectory;
  end else if MacroName='comppath' then begin
    Handled:=true;
    s:=EnvironmentOptions.CompilerFilename;
  end else if MacroName='params' then begin
    Handled:=true;
    s:=Project.RunParameterOptions.CmdLineParams;
  end else if MacroName='targetfile' then begin
    Handled:=true;
    s:=GetProjectTargetFilename;
  end;
end;

function TMainIDE.OnMacroPromptFunction(const s:string;
  var Abort: boolean):string;
begin
  Result:=s;
  Abort:=(ShowMacroPromptDialog(Result)<>mrOk);
end;

procedure TMainIDE.OnCmdLineCreate(var CmdLine: string; var Abort:boolean);
// replace all transfer macros in command line
begin
  Abort:=not MacroList.SubstituteStr(CmdLine);
end;

function TMainIDE.DoJumpToCompilerMessage(Index:integer;
  FocusEditor: boolean): boolean;
  
  function SearchFile(const AFilename: string): string;
  var OldCurrDir, SearchPath, Delimiter, ProjectDir: string;
    PathStart, PathEnd: integer;
  begin
    if FilenameIsAbsolute(AFilename) then begin
      Result:=AFileName;
      exit;
    end;
    // search file in project directory
    if (Project.MainUnit>=0) and Project.Units[Project.MainUnit].IsVirtual then
    begin
      Result:=AFilename;
      exit;
    end;
    ProjectDir:=ExtractFilePath(Project.ProjectFile);
    Result:=ProjectDir+AFilename;
    if FileExists(Result) then exit;
    // search file with unit search path
    OldCurrDir:=GetCurrentDir;
    try
      SetCurrentDir(ProjectDir);
      Delimiter:=';';
      SearchPath:=Project.CompilerOptions.OtherUnitFiles+';'+Project.SrcPath;
      PathStart:=1;
      while (PathStart<=length(SearchPath)) do begin
        while (PathStart<=length(SearchPath)) 
        and (Pos(SearchPath[PathStart],Delimiter)>0) do
          inc(PathStart);
        PathEnd:=PathStart;
        while (PathEnd<=length(SearchPath)) 
        and (Pos(SearchPath[PathEnd],Delimiter)<1) do
          inc(PathEnd);
        if PathEnd>PathStart then begin
          Result:=ExpandFileName(copy(SearchPath,PathStart,PathEnd-PathStart));
          if Result<>'' then begin
            if Result[length(Result)]<>PathDelim then
              Result:=Result+PathDelim;
            Result:=Result+AFileName;
            if FileExists(Result) then exit;
          end;
        end;
        PathStart:=PathEnd;
      end;
    finally
      SetCurrentDir(OldCurrDir);
    end;
    Result:='';
  end;
  
var MaxMessages: integer;
  Filename, Ext, SearchedFilename: string;
  CaretXY: TPoint;
  TopLine: integer;
  MsgType: TErrorType;
  SrcEdit: TSourceEditor;
begin
  Result:=false;
  MaxMessages:=MessagesView.MessageView.Items.Count;
  if Index>=MaxMessages then exit;
  if (Index<0) then begin
    // search relevant message (first error, first fatal)
    Index:=0;
    while (Index<MaxMessages) do begin
      if (TheOutputFilter.GetSourcePosition(
        MessagesView.MessageView.Items[Index],
        Filename,CaretXY,MsgType)) then
      begin
        if MsgType in [etError,etFatal,etPanic] then break;
      end;
      inc(Index);
    end;
    if Index>=MaxMessages then exit;
    MessagesView.MessageView.ItemIndex:=Index;
  end;
  if TheOutputFilter.GetSourcePosition(MessagesView.MessageView.Items[Index],
        Filename,CaretXY,MsgType) then begin
    SearchedFilename:=SearchFile(Filename);
    if SearchedFilename<>'' then begin
      // open the file in the source editor
      Ext:=lowercase(ExtractFileExt(SearchedFilename));
      if (Ext<>'.lfm') and (Ext<>'.lpi') then begin
        Result:=(DoOpenEditorFile(SearchedFilename,false,true)=mrOk);
        if Result then begin
          // set caret position
          SourceNotebook.AddJumpPointClicked(Self);
          SrcEdit:=SourceNoteBook.GetActiveSE;
          TopLine:=CaretXY.Y-(SrcEdit.EditorComponent.LinesInWindow div 2);
          if TopLine<1 then TopLine:=1;
          if FocusEditor then begin
            //SourceNotebook.BringToFront;
            SrcEdit.EditorComponent.SetFocus;
            BringWindowToTop(SourceNoteBook.Handle);
          end;
          SrcEdit.EditorComponent.CaretXY:=CaretXY;
          SrcEdit.EditorComponent.TopLine:=TopLine;
          with SrcEdit.EditorComponent do begin
            BlockBegin:=CaretXY;
            BlockEnd:=CaretXY;
          end;
          SrcEdit.ErrorLine:=CaretXY.Y;
        end;
      end;
    end else begin
      if FilenameIsAbsolute(Filename) then begin
        MessageDlg('Unable to find file "'+Filename+'".',
           mtInformation,[mbOk],0)
      end else begin
        MessageDlg('Unable to find file "'+Filename+'".'#13
           +'Check search path in'#13
           +'Run->Compiler Options...->Search Paths->Other Unit Files',
           mtInformation,[mbOk],0);
      end;
    end;
  end;
end;

procedure TMainIDE.DoShowMessagesView;
var WasVisible: boolean;
begin
  if (EnvironmentOptions.SaveWindowPositions) 
  and (EnvironmentOptions.MessagesViewBoundsValid) then begin
    MessagesView.BoundsRect:=EnvironmentOptions.MessagesViewBounds;
  end else begin
    MessagesView.Top := Screen.Height - 100 - 100;
    MessagesView.Height := 100;
    MessagesView.Left := SourceNotebook.Left;
    MessagesView.Width := SourceNotebook.Width;
  end;
  FMessagesViewBoundsRectValid:=true;
  WasVisible:=MessagesView.Visible;
  MessagesView.Show;
  if not WasVisible then
     bringWindowToTop(SourceNotebook.Handle);  //sxm changed 2001-11-14

//set the event here for the selectionchanged event
  if not assigned(MessagesView.OnSelectionChanged) then
     MessagesView.OnSelectionChanged := @MessagesViewSelectionChanged;
end;

procedure TMainIDE.DoArrangeSourceEditorAndMessageView;
begin
  DoShowMessagesView;

  if (SourceNotebook.Top+SourceNotebook.Height) > MessagesView.Top then
    SourceNotebook.Height := Max(50,Min(SourceNotebook.Height,
       MessagesView.Top-SourceNotebook.Top));
end;

function TMainIDE.GetProjectTargetFilename: string;
begin
  Result:='';
  if Project=nil then exit;
  if Project.IsVirtual then
    Result:=GetTestProjectFilename
  else begin
    if Project.MainUnit>=0 then begin
      Result:=
        Project.CompilerOptions.CreateTargetFilename(
            Project.Units[Project.MainUnit].Filename)
    end;
  end;
end;

function TMainIDE.GetTestProjectFilename: string;
begin
  Result:='';
  if (Project.MainUnit<0) then exit;
  Result:=GetTestUnitFilename(Project.Units[Project.MainUnit]);
  if Result='' then exit;
  Result:=Project.CompilerOptions.CreateTargetFilename(Result);
end;

function TMainIDE.GetTestUnitFilename(AnUnitInfo: TUnitInfo): string;
var TestDir: string;
begin
  Result:='';
  if AnUnitInfo=nil then exit;
  TestDir:=EnvironmentOptions.TestBuildDirectory;
  if (TestDir='') then exit;
  if TestDir[length(TestDir)]<>PathDelim then
    TestDir:=TestDir+PathDelim;
  Result:=ExtractFilename(AnUnitInfo.Filename);
  if Result='' then exit;
  Result:=TestDir+Result;
end;

//------------------------------------------------------------------------------

procedure TMainIDE.OnDesignerGetSelectedComponentClass(Sender: TObject; 
  var RegisteredComponent: TRegisteredComponent);
begin
  RegisteredComponent:=SelectedComponent;
end;

procedure TMainIDE.OnDesignerUnselectComponentClass(Sender: TObject);
begin
  ControlClick(ComponentNoteBook);
end;

procedure TMainIDE.OnDesignerSetDesigning(Sender: TObject; 
  Component: TComponent;  Value: boolean);
begin
  SetDesigning(Component,Value);
end;

procedure TMainIDE.OnDesignerComponentListChanged(Sender: TObject);
begin
  ObjectInspector1.FillComponentComboBox;
end;

procedure TMainIDE.OnDesignerPropertiesChanged(Sender: TObject);
begin
  ObjectInspector1.RefreshPropertyValues;
end;

procedure TMainIDE.OnDesignerAddComponent(Sender: TObject; 
  Component: TComponent; ComponentClass: TRegisteredComponent);
var i: integer;
  ActiveForm: TCustomForm;
  ActiveUnitInfo: TUnitInfo;
  FormClassName: string;
begin
  ActiveForm:=TDesigner(Sender).Form;
  if ActiveForm=nil then begin
    writeln('[TMainIDE.OnDesignerAddComponent] Error: TDesigner without a form');
    halt;
  end;
  // find source for form
  i:=Project.UnitCount-1;
  while (i>=0) do begin
    if (Project.Units[i].Loaded) 
    and (Project.Units[i].Form=ActiveForm) then break;
    dec(i);
  end;
  if i<0 then begin
    writeln('[TMainIDE.OnDesignerAddComponent] Error: form without source');
    halt;
  end;
  ActiveUnitInfo:=Project.Units[i];
  // add needed unit to source
  CodeToolBoss.AddUnitToMainUsesSection(ActiveUnitInfo.Source,
            ComponentClass.UnitName,'');
  // add component definition to form source
  FormClassName:=ActiveForm.ClassName;
  if not CodeToolBoss.PublishedVariableExists(ActiveUnitInfo.Source,
    FormClassName,Component.Name) then begin
    // ! AddPublishedVariable does not rebuild the CodeTree, so we need
    // PublishedVariableExists before !
    CodeToolBoss.AddPublishedVariable(ActiveUnitInfo.Source,FormClassName,
      Component.Name, Component.ClassName);
  end;
end;

procedure TMainIDE.OnDesignerRemoveComponent(Sender: TObject;
  Component: TComponent);
var i: integer;
  ActiveForm: TCustomForm;
  ActiveUnitInfo: TUnitInfo;
  FormClassName: string;
begin
  ActiveForm:=TDesigner(Sender).Form;
  if ActiveForm=nil then begin
    writeln('[TMainIDE.OnDesignerAddComponent] Error: TDesigner without a form');
    halt;
  end;
  // find source for form
  i:=Project.UnitCount-1;
  while (i>=0) do begin
    if (Project.Units[i].Loaded) 
    and (Project.Units[i].Form=ActiveForm) then break;
    dec(i);
  end;
  if i<0 then begin
    writeln('[TMainIDE.OnDesignerAddComponent] Error: form without source');
    halt;
  end;
  ActiveUnitInfo:=Project.Units[i];
  // remove component definition to form source
  FormClassName:=ActiveForm.ClassName;
  CodeToolBoss.RemovePublishedVariable(ActiveUnitInfo.Source,FormClassName,
    Component.Name);
end;

procedure TMainIDE.OnDesignerModified(Sender: TObject);
var i: integer;
begin
  i:=Project.IndexOfUnitWithForm(TDesigner(Sender).Form,false);
  if i>=0 then begin
    Project.Units[i].Modified:=true;
    if Project.Units[i].Loaded then
      SourceNotebook.FindSourceEditorWithPageIndex(
        Project.Units[i].EditorIndex).EditorComponent.Modified:=true;
  end;
end;

procedure TMainIDE.OnControlSelectionChanged(Sender: TObject);
var NewSelectedComponents : TComponentSelectionList;
  i: integer;
begin
{$IFDEF IDE_DEBUG}
writeln('[TMainIDE.OnControlSelectionChanged]');
{$ENDIF}
  if (TheControlSelection=nil) or (FormEditor1=nil) then exit;
  NewSelectedComponents:=TComponentSelectionList.Create;
  for i:=0 to TheControlSelection.Count-1 do begin
    NewSelectedComponents.Add(TheControlSelection[i].Component);
  end;
  FormEditor1.SelectedComponents:=NewSelectedComponents;
  NewSelectedComponents.Free;
{$IFDEF IDE_DEBUG}
writeln('[TMainIDE.OnControlSelectionChanged] END');
{$ENDIF}
end;

// -----------------------------------------------------------------------------

procedure TMainIDE.InitCodeToolBoss;
// initialize the CodeToolBoss, which is the frontend for the codetools.
// - sets a basic set of compiler macros
// ToDo: build a frontend for the codetools and save the settings

  procedure AddTemplate(ADefTempl: TDefineTemplate; AddToPool: boolean; 
    const ErrorMsg: string);
  begin
    if ADefTempl=nil then begin
      writeln('');
      writeln(ErrorMsg);
    end else begin;
      CodeToolBoss.DefineTree.Add(ADefTempl);
      if AddToPool then
        CodeToolBoss.DefinePool.Add(ADefTempl.CreateCopy);
    end;
  end;

var CompilerUnitSearchPath: string;
  ADefTempl: TDefineTemplate;
  c: integer;
begin
  FOpenEditorsOnCodeToolChange:=false;
  
  if (not FileExists(EnvironmentOptions.CompilerFilename)) then begin
    writeln('');
    writeln('NOTE: Compiler Filename not set! (see Environment Options)');
  end;
  if (EnvironmentOptions.LazarusDirectory='') then begin
    writeln('');
    writeln(
      'NOTE: Lazarus Source Directory not set!  (see Environment Options)');
  end;
  if (EnvironmentOptions.FPCSourceDirectory='') then begin
    writeln('');
    writeln(
      'NOTE: FPC Source Directory not set!  (see Environment Options)');
  end;
  
  // set global variables
  with CodeToolBoss.GlobalValues do begin
    Variables[ExternalMacroStart+'LazarusDir']:=
      EnvironmentOptions.LazarusDirectory;
    Variables[ExternalMacroStart+'FPCSrcDir']:=
      EnvironmentOptions.FPCSourceDirectory;
    Variables[ExternalMacroStart+'LCLWidgetType']:='gtk';
    Variables[ExternalMacroStart+'ProjectDir']:=VirtualDirectory;
  end;
  
  // build DefinePool and Define Tree
  with CodeToolBoss.DefinePool do begin
    // start the compiler and ask for his settings
    ADefTempl:=CreateFPCTemplate(EnvironmentOptions.CompilerFilename,
                          CompilerUnitSearchPath);
    AddTemplate(ADefTempl,false,
      'NOTE: Could not create Define Template for Free Pascal Compiler');
      
    // create compiler macros to simulate the Makefiles of the FPC sources
    ADefTempl:=CreateFPCSrcTemplate(
            CodeToolBoss.GlobalValues.Variables[ExternalMacroStart+'FPCSrcDir'],
            CompilerUnitSearchPath);
    AddTemplate(ADefTempl,false,
        'NOTE: Could not create Define Template for Free Pascal Sources');
        
    // create compiler macros for the lazarus sources 
    ADefTempl:=CreateLazarusSrcTemplate(
      '$('+ExternalMacroStart+'LazarusDir)',
      '$('+ExternalMacroStart+'LCLWidgetType)');
    AddTemplate(ADefTempl,true,
        'NOTE: Could not create Define Template for Lazarus Sources');
  end;  
  // build define tree
  c:=CodeToolBoss.ConsistencyCheck;
  if c<>0 then begin
    writeln('CodeToolBoss.ConsistencyCheck=',c);
    Halt;
  end;
  
  with CodeToolBoss do begin
    WriteExceptions:=true;
    CatchExceptions:=true;
    OnBeforeApplyChanges:=@OnBeforeCodeToolBossApplyChanges;
    OnAfterApplyChanges:=@OnAfterCodeToolBossApplyChanges;
  end;
end;

procedure TMainIDE.OnBeforeCodeToolBossApplyChanges(Manager: TCodeToolManager;
  var Abort: boolean);
// the CodeToolBoss built a list of Sources that will be modified
// 1. open all of them in the source notebook
// 2. lock the editors to reduce repaints and undo steps
var i: integer;
begin
  if FOpenEditorsOnCodeToolChange then begin
    // open all sources in editor
    for i:=0 to Manager.SourceChangeCache.BuffersToModifyCount-1 do begin
      if DoOpenEditorFile(Manager.SourceChangeCache.BuffersToModify[i].Filename,
        false,true)<>mrOk then
      begin
        Abort:=true;
        exit;
      end;
    end;
  end;
  // lock all editors
  SourceNoteBook.LockAllEditorsInSourceChangeCache;
end;

procedure TMainIDE.OnAfterCodeToolBossApplyChanges(Manager: TCodeToolManager);
begin
  SourceNoteBook.UnlockAllEditorsInSourceChangeCache;
end;

procedure TMainIDE.SaveSourceEditorChangesToCodeCache;
// save all open sources to code tools cache
var i: integer;
  CurUnitInfo: TUnitInfo;
  SrcEdit: TSourceEditor;
begin
  for i:=0 to Project.UnitCount-1 do begin
    CurUnitInfo:=Project.Units[i];
    if CurUnitInfo.EditorIndex>=0 then begin
      SrcEdit:=SourceNotebook.FindSourceEditorWithPageIndex(
        CurUnitInfo.EditorIndex);
      if SrcEdit.Modified then begin
        SrcEdit.UpdateCodeBuffer;
        CurUnitInfo.Modified:=true;
      end;
    end;
  end;
end;

function TMainIDE.BeginCodeTool(var ActiveSrcEdit: TSourceEditor;
  var ActiveUnitInfo: TUnitInfo; SwitchToFormSrc: boolean): boolean;
begin
  Result:=false;
  if SourceNoteBook.NoteBook=nil then exit;
  if SwitchToFormSrc then
    DoSwitchToFormSrc(ActiveSrcEdit,ActiveUnitInfo)
  else
    GetCurrentUnit(ActiveSrcEdit,ActiveUnitInfo);
  if (ActiveSrcEdit=nil) or (ActiveUnitInfo=nil) then exit;
  SaveSourceEditorChangesToCodeCache;
  CodeToolBoss.VisibleEditorLines:=ActiveSrcEdit.EditorComponent.LinesInWindow;
  Result:=true;
end;

function TMainIDE.DoJumpToCodePos(ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  NewSource: TCodeBuffer; NewX, NewY, NewTopLine: integer;
  AddJumpPoint: boolean): TModalResult;
var NewSrcEdit: TSourceEditor;
  NewUnitInfo: TUnitInfo;
begin
  Result:=mrCancel;
  if AddJumpPoint then begin
    if (NewSource<>ActiveUnitInfo.Source)
    or (ActiveSrcEdit.EditorComponent.CaretX<>NewX)
    or (ActiveSrcEdit.EditorComponent.CaretY<>NewY) then
      SourceNotebook.AddJumpPointClicked(Self);
  end;
  if NewSource<>ActiveUnitInfo.Source then begin
    // jump to other file -> open it
    Result:=DoOpenEditorFile(NewSource.Filename,false,true);
    if Result<>mrOk then exit;
    GetUnitWithPageIndex(SourceNoteBook.NoteBook.PageIndex,NewSrcEdit,
      NewUnitInfo);
  end else begin
    NewSrcEdit:=ActiveSrcEdit;
  end;
//writeln('[TMainIDE.DoJumpToCodePos] ',NewX,',',NewY,',',NewTopLine);
  with NewSrcEdit.EditorComponent do begin
    CaretXY:=Point(NewX,NewY);
    BlockBegin:=CaretXY;
    BlockEnd:=CaretXY;
    TopLine:=NewTopLine;
    SetFocus;
  end;
  BringWindowToTop(SourceNoteBook.Handle);
  Result:=mrOk;
end;

procedure TMainIDE.ApplyCodeToolChanges;
begin
  // all changes were handled automatically by events
  // just clear the logs
  CodeToolBoss.SourceCache.ClearAllSourleLogEntries;
end;

procedure TMainIDE.DoJumpToProcedureSection;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  NewSource: TCodeBuffer;
  NewX, NewY, NewTopLine: integer;
begin
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,false) then exit;
{$IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.DoJumpToProcedureSection] ************');
{$ENDIF}
  if CodeToolBoss.JumpToMethod(ActiveUnitInfo.Source,
    ActiveSrcEdit.EditorComponent.CaretX,
    ActiveSrcEdit.EditorComponent.CaretY,
    NewSource,NewX,NewY,NewTopLine) then
  begin
    DoJumpToCodePos(ActiveSrcEdit, ActiveUnitInfo, 
      NewSource, NewX, NewY, NewTopLine, false);
  end else
    DoJumpToCodeToolBossError;
end;

procedure TMainIDE.DoJumpToCodeToolBossError;
var
  ActiveSrcEdit:TSourceEditor;
begin
  if CodeToolBoss.ErrorMessage='' then exit;
  // syntax error -> show error and jump
  // show error in message view
  DoArrangeSourceEditorAndMessageView;
  MessagesView.AddSeparator;
  if CodeToolBoss.ErrorCode<>nil then begin
    MessagesView.Add(Project.RemoveProjectPathFromFilename(
       CodeToolBoss.ErrorCode.Filename)
      +'('+IntToStr(CodeToolBoss.ErrorLine)
      +','+IntToStr(CodeToolBoss.ErrorColumn)
      +') Error: '+CodeToolBoss.ErrorMessage);
  end else
    MessagesView.Add(CodeToolBoss.ErrorMessage);
  // jump to error in source editor
  if CodeToolBoss.ErrorCode<>nil then begin
    SourceNotebook.AddJumpPointClicked(Self);
    if DoOpenEditorFile(CodeToolBoss.ErrorCode.Filename,false,true)=mrOk then
    begin
      ActiveSrcEdit:=SourceNoteBook.GetActiveSE;
      with ActiveSrcEdit.EditorComponent do begin
        SetFocus;
        CaretXY:=Point(CodeToolBoss.ErrorColumn,CodeToolBoss.ErrorLine);
        BlockBegin:=CaretXY;
        BlockEnd:=CaretXY;
        if CodeToolBoss.ErrorTopLine>0 then
          TopLine:=CodeToolBoss.ErrorTopLine;
      end;
      ActiveSrcEdit.ErrorLine:=CodeToolBoss.ErrorLine;
      
      // ToDo: clear all other errorlines
      
      //SourceNotebook.BringToFront;
      BringWindowToTop(SourceNoteBook.Handle);
    end;
  end;
end;

procedure TMainIDE.DoFindDeclarationAtCursor;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  NewSource: TCodeBuffer;
  NewX, NewY, NewTopLine: integer;
begin
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,false) then exit;
{$IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.DoFindDeclarationAtCursor] ************');
{$ENDIF}
  if CodeToolBoss.FindDeclaration(ActiveUnitInfo.Source,
    ActiveSrcEdit.EditorComponent.CaretX,
    ActiveSrcEdit.EditorComponent.CaretY,
    NewSource,NewX,NewY,NewTopLine) then
  begin
    DoJumpToCodePos(ActiveSrcEdit, ActiveUnitInfo, 
      NewSource, NewX, NewY, NewTopLine, true);
  end else 
    DoJumpToCodeToolBossError;
end;

procedure TMainIDE.DoGoToPascalBlockOtherEnd;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  NewSource: TCodeBuffer;
  NewX, NewY, NewTopLine: integer;
begin
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,false) then exit;
{$IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.DoGoToPascalBlockOtherEnd] ************');
{$ENDIF}
  if CodeToolBoss.FindBlockCounterPart(ActiveUnitInfo.Source,
    ActiveSrcEdit.EditorComponent.CaretX,
    ActiveSrcEdit.EditorComponent.CaretY,
    NewSource,NewX,NewY,NewTopLine) then
  begin
    DoJumpToCodePos(ActiveSrcEdit, ActiveUnitInfo, 
      NewSource, NewX, NewY, NewTopLine, false);
  end else 
    DoJumpToCodeToolBossError;
end;

procedure TMainIDE.DoGoToPascalBlockStart;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  NewSource: TCodeBuffer;
  NewX, NewY, NewTopLine: integer;
begin
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,false) then exit;
{$IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.DoGoToPascalBlockStart] ************');
{$ENDIF}
writeln('[TMainIDE.DoGoToPascalBlockStart] ************');
  if CodeToolBoss.FindBlockStart(ActiveUnitInfo.Source,
    ActiveSrcEdit.EditorComponent.CaretX,
    ActiveSrcEdit.EditorComponent.CaretY,
    NewSource,NewX,NewY,NewTopLine) then
  begin
    DoJumpToCodePos(ActiveSrcEdit, ActiveUnitInfo,
      NewSource, NewX, NewY, NewTopLine, false);
  end else
    DoJumpToCodeToolBossError;
end;

procedure TMainIDE.DoJumpToGuessedUnclosedBlock(FindNext: boolean);
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  NewSource: TCodeBuffer;
  StartX, StartY, NewX, NewY, NewTopLine: integer;
begin
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,false) then exit;
{$IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.DoGoToPascalBlockEnd] ************');
{$ENDIF}
  if FindNext then begin
    StartX:=ActiveSrcEdit.EditorComponent.CaretX;
    StartY:=ActiveSrcEdit.EditorComponent.CaretY;
  end else begin
    StartX:=1;
    StartY:=1;
  end;
  if CodeToolBoss.GuessUnclosedBlock(ActiveUnitInfo.Source,
    StartX,StartY,NewSource,NewX,NewY,NewTopLine) then
  begin
    DoJumpToCodePos(ActiveSrcEdit, ActiveUnitInfo, 
      NewSource, NewX, NewY, NewTopLine, true);
  end else 
    DoJumpToCodeToolBossError;
end;

procedure TMainIDE.DoCompleteCodeAtCursor;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  NewSource: TCodeBuffer;
  NewX, NewY, NewTopLine: integer;
begin
  FOpenEditorsOnCodeToolChange:=true;
  try
    if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,false) then exit;
{$IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.DoCompleteCodeAtCursor] ************');
{$ENDIF}
    if CodeToolBoss.CompleteCode(ActiveUnitInfo.Source,
      ActiveSrcEdit.EditorComponent.CaretX,
      ActiveSrcEdit.EditorComponent.CaretY,
      NewSource,NewX,NewY,NewTopLine) then
    begin
      ApplyCodeToolChanges;
      DoJumpToCodePos(ActiveSrcEdit, ActiveUnitInfo, 
        NewSource, NewX, NewY, NewTopLine, true);
    end else begin
      // error: probably a syntax error or just not in a procedure head/body
      // or not in a class
      // -> there are enough events to handle everything, so it can be ignored here
      ApplyCodeToolChanges;
      DoJumpToCodeToolBossError;
    end;
  finally  
    FOpenEditorsOnCodeToolChange:=false;
  end;
end;

//-----------------------------------------------------------------------------

procedure TMainIDE.MessagesViewSelectionChanged(sender : TObject);
begin
  DoJumpToCompilerMessage(TMessagesView(sender).SelectedMessageIndex,True);
end;

Procedure TMainIDE.OnSrcNotebookEditorVisibleChanged(Sender : TObject);
var
  ActiveUnitInfo : TUnitInfo;
begin
  if SourceNotebook.Notebook = nil then Exit;
  
  ActiveUnitInfo :=
    Project.UnitWithEditorIndex(SourceNotebook.Notebook.Pageindex);
  if ActiveUnitInfo = nil then Exit;

  SaveSpeedBtn.Enabled := SourceNotebook.GetActiveSe.MOdified;
  ToggleFormSpeedBtn.Enabled := Assigned(ActiveUnitInfo.Form);
end;

Procedure TMainIDE.OnSrcNoteBookActivated(Sender : TObject);
begin
  FCodeLastActivated:=True;
end;

Procedure TMainIDE.OnDesignerActivated(Sender : TObject);
begin
  FCodeLastActivated:=False;
  FLastFormActivated := TCustomForm(Sender);
end;

Procedure TMainIDE.OnSrcNoteBookAddJumpPoint(ACaretXY: TPoint; 
  ATopLine: integer; APageIndex: integer; DeleteForwardHistory: boolean);
var
  ActiveUnitInfo: TUnitInfo;
  NewJumpPoint: TProjectJumpHistoryPosition;
begin
//writeln('[TMainIDE.OnSrcNoteBookAddJumpPoint] A Line=',ACaretXY.Y,',DeleteForwardHistory=',DeleteForwardHistory,' Count=',Project.JumpHistory.Count,',HistoryIndex=',Project.JumpHistory.HistoryIndex);
  ActiveUnitInfo:=Project.UnitWithEditorIndex(APageIndex);
  if (ActiveUnitInfo=nil) then exit;
  NewJumpPoint:=TProjectJumpHistoryPosition.Create(ActiveUnitInfo.Filename,
    ACaretXY,ATopLine);
  if DeleteForwardHistory then Project.JumpHistory.DeleteForwardHistory;
  Project.JumpHistory.InsertSmart(Project.JumpHistory.HistoryIndex+1,
    NewJumpPoint);
  if Project.JumpHistory.HistoryIndex=Project.JumpHistory.Count-2 then
    Project.JumpHistory.HistoryIndex:=Project.JumpHistory.Count-1;
//writeln('[TMainIDE.OnSrcNoteBookAddJumpPoint] END Line=',ACaretXY.Y,',DeleteForwardHistory=',DeleteForwardHistory,' Count=',Project.JumpHistory.Count,',HistoryIndex=',Project.JumpHistory.HistoryIndex);
//Project.JumpHistory.WriteDebugReport;
end;

Procedure TMainIDE.OnSrcNotebookDeleteLastJumPoint(Sender: TObject);
begin
  Project.JumpHistory.DeleteLast;
end;

Procedure TMainIDE.OnSrcNotebookJumpToHistoryPoint(var NewCaretXY: TPoint;
  var NewTopLine, NewPageIndex: integer;  Action: TJumpHistoryAction);
var DestIndex, UnitIndex, NewHistoryIndex: integer;
  ActiveSrcEdit: TSourceEditor;
  DestJumpPoint: TProjectJumpHistoryPosition;
begin
//writeln('[TMainIDE.OnSrcNotebookJumpToHistoryPoint] A Back=',Action=jhaBack);
  { jumping back/forward is also a jump, that's why the current source position
    should be saved to the jump history before the jump.
    The InsertSmart method prevents putting positions twice in the history. }
    
  // update jump history (e.g. delete jumps to closed editors)
  Project.JumpHistory.DeleteInvalidPositions;
  
//writeln('[TMainIDE.OnSrcNotebookJumpToHistoryPoint] B Count=',Project.JumpHistory.Count,',HistoryIndex=',Project.JumpHistory.HistoryIndex);
  DestIndex:=Project.JumpHistory.HistoryIndex;
  if Action=jhaForward then begin
    inc(DestIndex,2);
    if DestIndex=Project.JumpHistory.Count then
      Dec(DestIndex);
  end;
  if (DestIndex<0) or (DestIndex>=Project.JumpHistory.Count) then exit;
  DestJumpPoint:=Project.JumpHistory[DestIndex];
//writeln('[TMainIDE.OnSrcNotebookJumpToHistoryPoint] C Line=',DestJumpPoint.CaretXY.Y);
  NewHistoryIndex:=Project.JumpHistory.HistoryIndex;
  if Action=jhaBack then begin
    dec(NewHistoryIndex);
    if Project.JumpHistory.HistoryIndex=Project.JumpHistory.Count-1 then begin
      // insert current source position into history
      if SourceNoteBook.NoteBook=nil then exit;
      ActiveSrcEdit:=SourceNotebook.GetActiveSE;
      if (ActiveSrcEdit=nil) then exit;
      OnSrcNoteBookAddJumpPoint(ActiveSrcEdit.EditorComponent.CaretXY,
        ActiveSrcEdit.EditorComponent.TopLine,SourceNotebook.Notebook.PageIndex,
        false);
    end;
  end else
    inc(NewHistoryIndex);
  Project.JumpHistory.HistoryIndex:=NewHistoryIndex;
  
  UnitIndex:=Project.IndexOfFilename(DestJumpPoint.Filename);
  if (UnitIndex>=0) and (Project.Units[UnitIndex].EditorIndex>=0) then begin
    with Project.JumpHistory do begin
      NewCaretXY:=DestJumpPoint.CaretXY;
      NewTopLine:=DestJumpPoint.TopLine;
    end;
    NewPageIndex:=Project.Units[UnitIndex].EditorIndex;
  end;
//writeln('[TMainIDE.OnSrcNotebookJumpToHistoryPoint] END Count=',Project.JumpHistory.Count,',HistoryIndex=',Project.JumpHistory.HistoryIndex);
//Project.JumpHistory.WriteDebugReport;
end;

Procedure TMainIDE.OnSrcNotebookViewJumpHistory(Sender : TObject);
begin
  // ToDo
  MessageDlg('Not implemented yet','Sorry, not implemented yet',mtInformation,
     [mbOk],0);
end;

Procedure TMainIDE.HintTimer1Timer(Sender : TObject);
var
  Rect : TRect;
  AHint : String;
  cPosition : TPoint;
//  TextPosition : TPoint;
//  SE : TSourceEditor;
  Window : TWinControl;
//  Caret : TPoint;
  Control : TControl;
//  Control2 : TControl;
//  tempPosition : TPoint;
begin
  HintTimer1.Enabled := False;

  cPosition := Mouse.CursorPos;
  Window := FindLCLWindow(cPosition);
  if not(Assigned(Window)) then Exit;

  //get the parent until parent is nil
  While Window.Parent <> nil do
    Window := Window.Parent;

  if (Window <> Self) then Exit;

  Control := nil;
  
  if (FHintSender is TSpeedButton) then begin
    Control := TControl(FHintSender);
    while (Control<>nil) do begin
      if (Control=Self) then begin
        // main speed button
        if not EnvironmentOptions.ShowHintsForMainSpeedButtons then exit;
      end else if (Control=ComponentNotebook) then begin
        // component palette
        if not EnvironmentOptions.ShowHintsForComponentPalette then exit;
      end;
      Control:=Control.Parent;
    end;
  end;

  AHint := '';

  if (Control <> nil) and (Control is TSpeedButton) then
     AHint := TSpeedButton(Control).Hint;


  //If no hint, then Exit
  if AHint = '' then Exit;

  Rect := HintWindow1.CalcHintRect(0,AHint,nil);  //no maxwidth
  Rect.Left := cPosition.X+10;
  Rect.Top := cPosition.Y+10;
  Rect.Top := Rect.Top + 25;
  Rect.Right := Rect.Left + Rect.Right+3;
  Rect.Bottom := Rect.Top + Rect.Bottom+3;

  HintWindow1.ActivateHint(Rect,AHint);

end;

Procedure TMainIDE.MainKeyDown(Sender: TObject; var Key: Word; Shift:
  TShiftState);
begin
  HintTimer1.Enabled := False;
  if HintWIndow1.Visible then
      HintWindow1.Visible := False;
end;

Procedure TMainIDE.MainMouseDown(Sender: TObject; Button: TMouseButton; Shift:
  TShiftState; X, Y: Integer);
begin
  HintTimer1.Enabled := False;
  if HintWIndow1.Visible then
    HintWindow1.Visible := False;
end;

Procedure TMainIDE.MainMouseMoved(Sender: TObject; Shift: TShiftState; X, Y:
  Integer);
var Control: TControl;
begin
  if HintWindow1.Visible then
    HintWindow1.Visible := False;
  HintTimer1.Enabled := False;
  FHintSender := Sender;
  if (FHintSender is TSpeedButton) then begin
    Control := TControl(FHintSender);
    while (Control<>nil) do begin
      if (Control=Self) then begin
        // main speed button
        if not EnvironmentOptions.ShowHintsForMainSpeedButtons then exit;
      end else if (Control=ComponentNotebook) then begin
        // component palette
        if not EnvironmentOptions.ShowHintsForComponentPalette then exit;
      end;
      Control:=Control.Parent;
    end;
    HintTimer1.Enabled := ([ssLeft,ssRight,ssMiddle]*Shift=[]);
  end;
end;

Procedure TMainIDE.OnSrcNotebookAddWatchesAtCursor(Sender : TObject);
var
  SE : TSourceEditor;
  WatchVar : String;
begin
  //get the sourceEditor.
  SE := TSourceNotebook(sender).GetActiveSE;
  if not Assigned(SE) then Exit;
  WatchVar := SE.GetWordAtCurrentCaret;
  if WatchVar = ''  then Exit;

  AddWatch(WatchVar);
end;

procedure TMainIDE.mnuViewWatchesClick(Sender : TObject);
begin
  Watches_dlg.Show;
//  CreateLFM(Watches_Dlg);
//  CreateLFM(Insertwatch);
end;

procedure TMainIDE.mnuViewBreakPointsClick(Sender : TObject);
begin
Writeln('showing breakpoints');
  BreakPoints_dlg.Show;
Writeln('DONE showing breakpoints');

//  CreateLFM(Watches_Dlg);
//  CreateLFM(Insertwatch);
end;

Procedure TMainIDE.OnDebuggerWatchChanged(Sender : TObject);
begin
  Writeln('OnDebuggerWatchChanged');
  //watch changed.
end;

//This adds the watch to the TWatches TCollection and to the watches dialog
procedure TMainIDE.AddWatch(const AnExpression : String);
var
  NewWatch : TdbgWatch;
begin
  if FDebugger = nil then Exit;
  if not Watches_Dlg.Visible then Watches_Dlg.Show;

  NewWatch := TdbgWatch(FDebugger.watches.Add);
  with NewWatch do
  begin
    Expression := AnExpression;
    OnChange := @OnDebuggerWatchChanged;
    Enabled := True;
  end;

  Watches_Dlg.AddWatch(NewWatch.Expression+':'+NewWatch.Value);
end;


Procedure TMainIDE.OnWatchAdded(Sender : TObject; AnExpression : String);
Var
  NewWatch : TdbgWatch;
begin

  if not Watches_Dlg.Visible then Watches_Dlg.Show;

  if Pos(':',AnExpression) > 0 then
     AnExpression := Copy(AnExpression,1,pos(':',AnExpression)-1);
     
  NewWatch := TdbgWatch(FDebugger.watches.Add);
  with NewWatch do
    Begin
      Expression := AnExpression;
      OnChange := @OnDebuggerWatchChanged;
      Enabled := True;

    end;

  Watches_Dlg.UpdateWatch(NewWatch.Expression,NewWatch.Value);

end;

//this is fired when the editor is focused, changed, ?.  Anything that causes the status change
Procedure TMainIDE.OnSrcNotebookEditorChanged(Sender : TObject);
begin
  if SourceNotebook.Notebook = nil then Exit;

  SaveSpeedBtn.Enabled := SourceNotebook.GetActiveSE.Modified;
end;

Procedure TMainIDE.OnSrcNotebookCreateBreakPoint(Sender : TObject;
  Line : Integer);
begin
  if SourceNotebook.Notebook = nil then Exit;

  Breakpoints_Dlg.AddBreakPoint(TSourceNotebook(sender).GetActiveSe.FileName,Line);
  FBreakPoints.Add(TSourceNotebook(sender).GetActiveSe.FileName, Line);
end;

Procedure TMainIDE.OnSrcNotebookDeleteBreakPoint(Sender : TObject;
  Line : Integer);
begin
  if SourceNotebook.Notebook = nil then Exit;

  Breakpoints_Dlg.DeleteBreakPoint(TSourceNotebook(sender).GetActiveSe.FileName,Line);
  FBreakPoints.Find(TSourceNotebook(sender).GetActiveSe.FileName, Line).Free;
end;

procedure TMainIDE.OnExtToolNeedsOutputFilter(var OutputFilter: TOutputFilter;
  var Abort: boolean);
var ActiveSrcEdit: TSourceEditor;
begin
  OutputFilter:=TheOutputFilter;
  OutputFilter.Project:=Project;
  if ToolStatus<>itNone then begin
    Abort:=true;
    exit;
  end;
  ActiveSrcEdit:=SourceNotebook.GetActiveSE;
  if ActiveSrcEdit<>nil then ActiveSrcEdit.ErrorLine:=-1;

  ToolStatus:=itBuilder;
  MessagesView.Clear;
  DoArrangeSourceEditorAndMessageView;

  TheOutputFilter.OnOutputString:=@MessagesView.Add;
end;

procedure TMainIDE.OnExtToolFreeOutputFilter(OutputFilter: TOutputFilter;
  ErrorOccurred: boolean);
begin
  if ToolStatus=itBuilder then
    ToolStatus:=itNone;
  if ErrorOccurred then
    DoJumpToCompilerMessage(-1,true);
end;

procedure TMainIDE.DoSwitchToFormSrc(var ActiveSourceEditor: TSourceEditor;
  var ActiveUnitInfo: TUnitInfo);
var i: integer;
begin
  if PropertyEditorHook1.LookupRoot<>nil then begin
    i:=Project.IndexOfUnitWithForm(PropertyEditorHook1.LookupRoot,false);
    if (i>=0) then begin
      i:=Project.Units[i].EditorIndex;
      if (i>=0) then begin
        SourceNoteBook.NoteBook.PageIndex:=i;
        GetCurrentUnit(ActiveSourceEditor,ActiveUnitInfo);
        exit;
      end;
    end;
  end;
  ActiveSourceEditor:=nil;
  ActiveUnitInfo:=nil;
end;

function TMainIDE.OnPropHookMethodExists(const AMethodName: ShortString;
  TypeData: PTypeData;
  var MethodIsCompatible,MethodIsPublished,IdentIsMethod: boolean): boolean;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
begin
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,true) then exit;
{$IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.OnPropHookMethodExists] ************');
{$ENDIF}
  Result:=CodeToolBoss.PublishedMethodExists(ActiveUnitInfo.Source,
                            ActiveUnitInfo.Form.ClassName,AMethodName,TypeData,
                            MethodIsCompatible,MethodIsPublished,IdentIsMethod);
  if CodeToolBoss.ErrorMessage<>'' then begin
    DoJumpToCodeToolBossError;
  end;
end;

function TMainIDE.OnPropHookCreateMethod(const AMethodName: ShortString;
  ATypeInfo: PTypeInfo): TMethod;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  r: boolean;
begin
  Result.Code:=nil;
  Result.Data:=nil;
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,true) then exit;
{ $IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.OnPropHookCreateMethod] ************');
{ $ENDIF}
  FOpenEditorsOnCodeToolChange:=true;
  try
    // create published method
    r:=CodeToolBoss.CreatePublishedMethod(ActiveUnitInfo.Source,
                ActiveUnitInfo.Form.ClassName,AMethodName,ATypeInfo);
{ $IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.OnPropHookCreateMethod] ************2 ',r);
{ $ENDIF}
    ApplyCodeToolChanges;
    if r then begin
      Result:=FormEditor1.JITFormList.CreateNewMethod(TForm(ActiveUnitInfo.Form)
                                                      ,AMethodName);
    end else begin
      DoJumpToCodeToolBossError;
    end;
  finally
    FOpenEditorsOnCodeToolChange:=false;
  end;
end;

procedure TMainIDE.OnPropHookShowMethod(const AMethodName: ShortString);
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  NewSource: TCodeBuffer;
  NewX, NewY, NewTopLine: integer;
begin
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,true) then exit;
{$IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.OnPropHookShowMethod] ************');
{$ENDIF}
  if CodeToolBoss.JumpToPublishedMethodBody(ActiveUnitInfo.Source,
    ActiveUnitInfo.Form.ClassName,AMethodName,
    NewSource,NewX,NewY,NewTopLine) then
  begin
    DoJumpToCodePos(ActiveSrcEdit, ActiveUnitInfo,
      NewSource, NewX, NewY, NewTopLine, true);
  end else
    DoJumpToCodeToolBossError;
end;

procedure TMainIDE.OnPropHookRenameMethod(const CurName, NewName: ShortString);
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  r: boolean;
begin
  if not BeginCodeTool(ActiveSrcEdit,ActiveUnitInfo,true) then exit;
{ $IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.OnPropHookRenameMethod] ************');
{ $ENDIF}
  FOpenEditorsOnCodeToolChange:=true;
  try
    // create published method
    r:=CodeToolBoss.RenamePublishedMethod(ActiveUnitInfo.Source,
                ActiveUnitInfo.Form.ClassName,CurName,NewName);
{ $IFDEF IDE_DEBUG}
writeln('');
writeln('[TMainIDE.OnPropHookRenameMethod] ************2 ',r);
{ $ENDIF}
    ApplyCodeToolChanges;
    if r then begin
      FormEditor1.JITFormList.RenameMethod(TForm(ActiveUnitInfo.Form),
                                           CurName,NewName);
    end else begin
      DoJumpToCodeToolBossError;
    end;
  finally
    FOpenEditorsOnCodeToolChange:=false;
  end;
end;


//-----------------------------------------------------------------------------

initialization
  { $I mainide.lrs}
  {$I images/laz_images.lrs}
  {$I images/mainicon.lrs}


end.


{ =============================================================================
  $Log$
  Revision 1.225  2002/02/18 22:46:10  lazarus
  Implented TMenuItem.ShortCut (not much tested).

  Revision 1.224  2002/02/17 19:51:10  lazarus
  MG: fixed running project

  Revision 1.223  2002/02/17 19:34:44  lazarus
  MG: fixed view units/forms

  Revision 1.222  2002/02/11 15:12:00  lazarus
  MG: started OI events

  Revision 1.221  2002/02/10 20:44:00  lazarus
  MG: fixed a node cache range bug

  Revision 1.220  2002/02/09 22:24:50  lazarus
  MG: get compatible published methods now works

  Revision 1.219  2002/02/09 21:09:19  lazarus
  MG: fixed sourcenotebook closing and form-unit switching

  Revision 1.218  2002/02/09 20:32:08  lazarus
  MG: many fixes on my way to events

  Revision 1.217  2002/02/08 21:08:00  lazarus
  MG: saving of virtual project files will now save the whole project

  Revision 1.214  2002/02/07 18:18:59  lazarus
  MG: fixed deactivating hints

  Revision 1.213  2002/02/07 13:48:47  lazarus
  MG: fixed mem leak FBreakPts

  Revision 1.212  2002/02/06 22:23:13  lazarus
  MG: codetools now know the compiler options

  Revision 1.211  2002/02/06 09:37:40  lazarus
  MG: outputfilter now recognizes, if compiler in sub directory

  Revision 1.210  2002/02/06 08:58:27  lazarus
  MG: fixed compiler warnings and asking to create non existing files

  Revision 1.209  2002/02/05 23:16:47  lazarus
  MWE: * Updated tebugger
       + Added debugger to IDE

  Revision 1.208  2002/02/03 00:23:54  lazarus
  TPanel implemented.
  Basic graphic primitives split into GraphType package, so that we can
  reference it from interface (GTK, Win32) units.
  New Frame3d canvas method that uses native (themed) drawing (GTK only).
  New overloaded Canvas.TextRect method.
  LCLLinux and Graphics was split, so a bunch of files had to be modified.

  Revision 1.207  2002/01/27 19:08:43  lazarus
  MWE: Removed ^M

  Revision 1.206  2002/01/24 14:12:52  lazarus
  MG: added build lazarus feature and config dialog

  Revision 1.205  2002/01/23 22:12:54  lazarus
  MG: external tool output parsing for fpc and make messages

  Revision 1.204  2002/01/23 20:07:20  lazarus
  MG: added outputfilter

  Revision 1.203  2002/01/21 14:17:44  lazarus
  MG: added find-block-start and renamed find-block-other-end

  Revision 1.202  2002/01/17 11:00:00  lazarus
  MG: increased IDE version to 0.8.2 alpha

  Revision 1.201  2002/01/15 20:21:37  lazarus
  MG: jump history for find declaration

  Revision 1.200  2002/01/13 12:46:17  lazarus
  MG: fixed linker options, compiler options dialog

  Revision 1.199  2002/01/11 20:41:52  lazarus
  MG: added  guess unclosed block

  Revision 1.197  2002/01/02 13:32:52  lazarus
  MG: fixed clean abort of project loading

  Revision 1.196  2001/12/31 22:45:41  lazarus
  Took out some test code.
  Shane

  Revision 1.195  2001/12/31 22:42:59  lazarus
  Added a TViewColumn editor to be used in the object inspector as TViewColumn's property editor.
  Shane

  Revision 1.194  2001/12/28 11:01:20  lazarus
  MG: fixed save as with lfm and lrs files

  Revision 1.193  2001/12/20 19:11:22  lazarus
  Changed the delay for the hints from 100 miliseconds to 500.  I'm hoping this reduces the crashing for some people until I determine the problem.
  Shane

  Revision 1.192  2001/12/19 22:09:13  lazarus
  MG: added GUID and alias parsing, added DoJumpToCodeToolBossError

  Revision 1.191  2001/12/19 20:28:50  lazarus
  Enabled Alignment of columns in a TListView.
  Shane

  Revision 1.190  2001/12/18 21:09:58  lazarus
  MOre additions for breakpoints dialog
  Added a TSynEditPlugin in SourceEditor to get notified of lines inserted and deleted from the source.
  Shane

  Revision 1.189  2001/12/18 21:00:59  lazarus
  MG: compiler, fpc source and lazarus src can now be changed without restart

  Revision 1.188  2001/12/17 19:41:05  lazarus
  MG: added binary file recognition and readonly recognition

  Revision 1.186  2001/12/17 11:16:08  lazarus
  MG: fixed open file key in source editor

  Revision 1.185  2001/12/16 22:24:54  lazarus
  MG: changes for new compiler 20011216

  Revision 1.183  2001/12/16 11:20:26  lazarus
  MG: find declaration for uses sections

  Revision 1.182  2001/12/15 22:58:09  lazarus
  MG: fixed code completion in virtual files

  Revision 1.181  2001/12/15 10:57:48  lazarus
  MG: added hint checkboxes to environment options

  Revision 1.180  2001/12/14 18:38:55  lazarus
  Changed code for TListView
  Added a generic Breakpoints dialog
  Shane

  Revision 1.179  2001/12/13 23:09:57  lazarus
  MG: enhanced code caching, fixed CursorToCleanPos and beautify statement

  Revision 1.178  2001/12/12 16:49:14  lazarus
  Added code to disable save button when the active unit is not "modified".
  Shane

  Revision 1.177  2001/12/12 15:12:31  lazarus
  MG: added file path to files in TOpenDialog

  Revision 1.176  2001/12/12 14:25:03  lazarus
  Changes to allow multiple files being opened in main.pp
  Shane

  Revision 1.175  2001/12/11 16:51:36  lazarus
  Modified the Watches dialog
  Shane

  Revision 1.174  2001/12/11 15:43:35  lazarus
  MG: TCodeBuffer.LoadFromFile now checks file date

  Revision 1.172  2001/12/11 11:14:10  lazarus
  MG: fixed save project, saving units twice

  Revision 1.171  2001/12/11 09:34:32  lazarus
  MG: fixed open file at cursor

  Revision 1.170  2001/12/10 23:03:18  lazarus
  MG: enhanced open file at cursor to read more than one word

  Revision 1.169  2001/12/10 22:39:36  lazarus
  MG: added perl highlighter

  Revision 1.168  2001/12/10 16:22:40  lazarus
  MG: started open file at cursor

  Revision 1.167  2001/12/10 14:32:57  lazarus
  MOdified the Watches dialog and added the lfm and lrs files for it and the insert watch dialog.

  Shane

  Revision 1.166  2001/12/10 08:44:23  lazarus
  MG: added search for compiler, if not set

  Revision 1.165  2001/12/07 20:12:13  lazarus
  Added a watch dialog.
  Shane

  Revision 1.164  2001/12/05 18:19:10  lazarus
  MG: added calendar to allunits and removed unused vars

  Revision 1.163  2001/12/04 14:28:04  lazarus
  Added hints to the main ide.
  Shane

  Revision 1.162  2001/12/02 13:05:33  lazarus
  MG: reduced output

  Revision 1.161  2001/12/02 11:03:35  lazarus
  MG: added default pascal file extension option

  Revision 1.160  2001/12/01 22:17:26  lazarus
  MG: added jump-history

  Revision 1.159  2001/11/27 15:06:11  lazarus
  MG: added multi language syntax hilighting

  Revision 1.158  2001/11/22 14:28:30  lazarus
  MG: cropped all component icons

  Revision 1.157  2001/11/22 10:37:23  lazarus
  MG: moved lazres, added images/README

  Revision 1.156  2001/11/21 19:32:31  lazarus
  TComboBox can now be moved in FormEditor
  Shane

  Revision 1.155  2001/11/21 13:09:50  lazarus
  MG: moved executable check to ideprocs.pp

  Revision 1.153  2001/11/20 19:39:45  lazarus
  MG: DoRunProject writes the programfilename

  Revision 1.152  2001/11/20 18:30:30  lazarus
  Pressing DEL when form is the only thing selected in designer no longer crashes Lazarus.
  Shane

  Revision 1.151  2001/11/20 15:09:21  lazarus
  MG: open project now only opens lpi files

  Revision 1.150  2001/11/19 22:01:25  lazarus
  MG: run button and menu run  now builds+runs

  Revision 1.148  2001/11/19 15:23:17  lazarus
  MG: added quick syntax check via codetools

  Revision 1.147  2001/11/19 12:15:03  lazarus
  MG: added dirty about lazarus dlg

  Revision 1.146  2001/11/17 10:16:23  lazarus
  MG: clear define cache on changing env paths

  Revision 1.145  2001/11/15 13:49:49  lazarus
  MG: fixed open non existing file and unitname in save project as

  Revision 1.144  2001/11/14 19:10:00  lazarus
  MG: fixes for parser and linkscanner and small cleanups

  Revision 1.143  2001/11/14 17:46:54  lazarus
  Changes to make toggling between form and unit work.
  Added BringWindowToTop
  Shane

  Revision 1.141  2001/11/12 16:56:04  lazarus
  MG: CLIPBOARD

  Revision 1.140  2001/11/09 18:39:11  lazarus
  MG: turned back to stable ground (use old process.pp)

  Revision 1.139  2001/11/09 18:15:20  lazarus
  MG: added external tools

  Revision 1.138  2001/11/07 16:14:11  lazarus
  MG: fixes for the new compiler

  Revision 1.137  2001/11/06 15:47:31  lazarus
  MG: added build all

  Revision 1.136  2001/11/06 12:20:30  lazarus
  MG: added Run Parameter Options - not enabled yet

  Revision 1.135  2001/11/05 18:18:13  lazarus
  added popupmenu+arrows to notebooks, added target filename

  Revision 1.134  2001/11/05 00:12:50  lazarus
  MWE: First steps of a debugger.

  Revision 1.133  2001/11/03 08:37:34  lazarus
  MG: fixed errorline showing, resource adding and published var editing and added make cleanall

  Revision 1.132  2001/11/01 21:30:32  lazarus
  Changes to Messagebox.
  Added line to CodeTools to prevent duplicate USES entries.

  Revision 1.131  2001/11/01 18:48:48  lazarus
  Changed Application.Messagebox to use TMessageBox class.
  Added icon images for mtError and mtConfirmation
  Shane

  Revision 1.130  2001/10/31 18:09:51  lazarus
  MG: fixed DirectoryExists

  Revision 1.129  2001/10/31 16:29:20  lazarus
  Fixed the gtk mousemove bug where the control gets the coord's based on it's parent instead of itself.
  Shane

  Revision 1.128  2001/10/26 20:36:48  lazarus
  Added an OnSelectionChanged event in Main.pp fired by MSgView dialog.  This fires when the ListBox gets clicked on.
  This allows the editor to highlight different lines when you click on different error messages.
  Shane

  Revision 1.126  2001/10/23 09:13:51  lazarus
  MG: fixed TestProject

  Revision 1.125  2001/10/18 13:34:03  lazarus
  MG: keys for debugging

  Revision 1.123  2001/10/17 13:43:15  lazarus
  MG: added find previous to source editor

  Revision 1.122  2001/10/16 14:19:10  lazarus
  MG: added nvidia opengl support and a new opengl example from satan

  Revision 1.121  2001/10/15 17:41:30  lazarus
  MG: fixed splashform showing

  Revision 1.115  2001/10/09 09:46:49  lazarus
  MG: added codetools, fixed synedit unindent, fixed MCatureHandle

  Revision 1.113  2001/07/31 18:57:48  lazarus
  MG: fixed source ediotr statusbar filename

  Revision 1.111  2001/07/29 20:33:23  lazarus
  MG: bugfixed event propeditor, DoJumpToMethod with searchpath

  Revision 1.110  2001/07/10 10:44:15  lazarus
  MG: save unit only if modified

  Revision 1.105  2001/07/01 15:55:43  lazarus
  MG: JumpToCompilerMessage now centered in source editor

  Revision 1.104  2001/06/27 21:43:23  lazarus
  MG: added project bookmark support

  Revision 1.103  2001/06/26 00:08:35  lazarus
  MG: added code for form icons from Rene E. Beszon

  Revision 1.102  2001/06/06 12:30:40  lazarus
  MG: bugfixes

  Revision 1.100  2001/06/05 10:27:50  lazarus
  MG: saving recent file lists

  Revision 1.98  2001/05/29 08:16:26  lazarus
  MG: bugfixes + starting programs

  Revision 1.97  2001/05/28 10:00:54  lazarus
  MG: removed unused code. fixed editor name bug.

  Revision 1.96  2001/05/27 11:52:00  lazarus
  MG: added --primary-config-path=<filename> cmd line option

  Revision 1.92  2001/04/21 14:50:21  lazarus
  MG: bugfix for mainunits ext <> .lpr

  Revision 1.91  2001/04/13 17:56:16  lazarus
  MWE:
  * Moved menubar outside clientarea
  * Played a bit with the IDE layout
  * Moved the creation of the toolbarspeedbuttons to a separate function

  Revision 1.90  2001/04/04 13:58:50  lazarus
  Added some changes to compreg.pp

  Revision 1.89  2001/04/04 13:55:34  lazarus
  MG: finished TComponentPropertyEditor, added OnModified to oi, cfe and designer

  Revision 1.88  2001/04/04 12:20:34  lazarus
  MG: added  add to/remove from project, small bugfixes

  Revision 1.86  2001/03/31 13:35:22  lazarus
  MG: added non-visual-component code to IDE and LCL

  Revision 1.85  2001/03/29 13:11:33  lazarus
  MG: fixed loading program file bug

  Revision 1.84  2001/03/29 12:38:59  lazarus
  MG: new environment opts, ptApplication bugfixes

  Revision 1.83  2001/03/28 14:08:45  lazarus
  MG: added backup code and fixed removing controls

  Revision 1.82  2001/03/27 11:11:13  lazarus
  MG: fixed mouse msg, added filedialog initialdir

  Revision 1.81  2001/03/26 14:52:30  lazarus
  MG: TSourceLog + compiling bugfixes

  Revision 1.75  2001/03/19 14:00:46  lazarus
  MG: fixed many unreleased DC and GDIObj bugs

  Revision 1.74  2001/03/12 18:57:31  lazarus
  MG: new designer and controlselection code

  Revision 1.68  2001/03/03 11:06:15  lazarus
  added project support, codetools

  Revision 1.62  2001/02/22 17:04:57  lazarus
  added environment options + killed ide unit circles

  Revision 1.61  2001/02/21 22:55:24  lazarus
  small bugfixes + added TOIOptions

  Revision 1.60  2001/02/20 16:53:24  lazarus
  Changes for wordcompletion and many other things from Mattias.
  Shane

  Revision 1.59  2001/02/16 19:13:29  lazarus
  Added some functions
  Shane

  Revision 1.58  2001/02/08 06:09:25  lazarus
  Partially implemented Save Project As menu selection.               CAW

  Revision 1.57  2001/02/06 13:38:57  lazarus
  Fixes from Mattias for EditorOPtions
  Fixes to COmpiler that should allow people to compile if their path is set up.
  Changes to code completion.
  Shane

  Revision 1.56  2001/02/04 04:18:11  lazarus
  Code cleanup and JITFOrms bug fix.
  Shane

  Revision 1.55  2001/02/02 14:23:37  lazarus
  Start of code completion code.
  Shane

  Revision 1.54  2001/02/01 16:45:19  lazarus
  Started the code completion.
  Shane

  Revision 1.52  2001/01/31 13:03:33  lazarus
  Commitng source with new editor.
  Shane

  Revision 1.51  2001/01/31 06:25:35  lazarus
  Removed global unit.
  Removed and commented all references to TUnitInfo.

  Revision 1.50  2001/01/29 05:46:30  lazarus
  Moved Project Options and Compiler Options menus to the Project menu.
  Added Project property to TMainIDE class to allow the project to be
  accessed from other units.                                            CAW

  Revision 1.49  2001/01/18 13:27:30  lazarus
  Minor changees
  Shane

  Revision 1.48  2001/01/16 23:30:45  lazarus
  trying to determine what's crashing LAzarus on load.
  Shane

  Revision 1.45  2001/01/15 20:55:44  lazarus
  Changes for loading filesa
  Shane

  Revision 1.44  2001/01/15 18:25:51  lazarus
  Fixed a stupid error I caused by using a variable as an index in main.pp and this variable sometimes caused an exception because the index was out of range.
  Shane

  Revision 1.43  2001/01/14 03:56:57  lazarus
  Shane

  Revision 1.42  2001/01/13 06:11:06  lazarus
  Minor fixes
  Shane

  Revision 1.41  2001/01/13 03:09:37  lazarus
  Minor changes
  Shane

  Revision 1.40  2001/01/12 18:46:49  lazarus
  Named the speedbuttons in MAINIDE and took out some writelns.
  Shane

  Revision 1.39  2001/01/12 18:10:53  lazarus
  Changes for keyevents in the editor.
  Shane

  Revision 1.38  2001/01/09 21:06:06  lazarus
  Started taking KeyDown messages in TDesigner
  Shane

  Revision 1.37  2001/01/09 18:23:20  lazarus
  Worked on moving controls.  It's just not working with the X and Y coord's I'm getting.
  Shane

  Revision 1.36  2001/01/08 23:48:33  lazarus
  MWE:
    ~ Changed makefiles
    ~ Removed testform from lararus and changed it into program
    * some formatting

  Revision 1.35  2001/01/06 06:28:47  lazarus
  Made Designer control the control movement and such.  I am now using ISDesignMsg to move the controls.
  Shane

  Revision 1.32  2001/01/04 20:33:53  lazarus
  Moved lresources.
  Moved CreateLFM to Main.pp
  Changed Form1 and TFOrm1 to MainIDE and TMainIDE
  Shane

  Revision 1.30  2001/01/03 18:44:54  lazarus
  The Speedbutton now has a numglyphs setting.
  I started the TStringPropertyEditor

  Revision 1.29  2000/12/29 20:43:17  lazarus
  I added the run button with an Enable and disable icon

  Revision 1.25  2000/12/29 13:35:50  lazarus
  Mattias submitted new lresources.pp and lazres.pp files.
  Shane

  Revision 1.23  2000/12/21 20:28:33  lazarus
  Project - RUN will run the program IF the program is the active unit in the Editor.
  Shane

  Revision 1.22  2000/12/20 20:04:30  lazarus
  Made PRoject Build compile the active unit.  This way we can actually play with it by compiling units.

  Revision 1.19  2000/12/19 18:43:12  lazarus
  Removed IDEEDITOR.  This causes the PROJECT class to not function.
  Saving projects no longer works.

  I added TSourceNotebook and TSourceEditor.  They do all the work for saving/closing/opening units.  Somethings work but they are in early development.
  Shane

  Revision 1.18  2000/12/15 18:25:16  lazarus
  Changes from Mattias and I.
  Shane

  Revision 1.16  2000/12/01 20:23:34  lazarus
  renamed Object_Inspector and Prop_edits by removing the underline.
  Shane

  Revision 1.5  2000/08/10 13:22:51  lazarus
  Additions for the FIND dialog
  Shane

  Revision 1.4  2000/08/09 18:32:10  lazarus
  Added more code for the find function.
  Shane

  Revision 1.2  2000/08/07 19:15:05  lazarus
  Added the Search menu to the IDE.
  Shane

  Revision 1.1  2000/07/13 10:27:47  michael
  + Initial import

}

