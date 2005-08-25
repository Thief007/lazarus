{
/***************************************************************************
                               UnitEditor.pp
                             -------------------

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
{ This unit builds the TSourceNotebook that the editors are held on.
  It also has a class that controls the editors (TSourceEditor)
}

unit UnitEditor;

{$mode objfpc}
{$H+}

interface

{$I ide.inc}

uses
  {$IFDEF IDE_MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, Controls, LCLProc, LCLType, LResources, LCLIntf, FileUtil,
  Forms, Buttons, ComCtrls, Dialogs, StdCtrls, GraphType, Graphics, TypInfo,
  Extctrls, Menus,
  // codetools
  CodeToolManager, CodeCache, SourceLog,
  // synedit
  SynEditTypes, SynEdit, SynRegExpr, SynEditHighlighter, SynEditAutoComplete,
  SynEditKeyCmds, SynCompletion,
  // IDE interface
  HelpIntf, SrcEditorIntf, MenuIntf, LazIDEIntf, IDEWindowIntf,
  // IDE units
  LazarusIDEStrConsts, LazConf, IDECommands, EditorOptions, KeyMapping, Project,
  WordCompletion, FindReplaceDialog, FindInFilesDlg, IDEProcs, IDEOptionDefs,
  EnvironmentOpts, MsgView, SearchResultView, InputHistory,
  SortSelectionDlg, EncloseSelectionDlg, DiffDialog, ConDef, InvertAssignTool,
  SourceEditProcs, SourceMarks, CharacterMapDlg, frmSearch,
  BaseDebugManager, Debugger, MainIntf;

type
  TSourceNoteBook = class;

  TNotifyFileEvent = procedure(Sender: TObject; Filename : AnsiString) of object;

  TOnAddWatch = function(Sender: TObject): boolean of object;

  TOnProcessUserCommand = procedure(Sender: TObject;
            Command: word; var Handled: boolean) of object;
  TOnUserCommandProcessed = procedure(Sender: TObject;
            Command: word; var Handled: boolean) of object;

  TOnLinesInsertedDeleted = procedure(Sender : TObject;
             FirstLine,Count : Integer) of Object;

  TSynEditPlugin1 = class(TSynEditPlugin)
  private
    FOnLinesInserted : TOnLinesInsertedDeleted;
    FOnLinesDeleted : TOnLinesInsertedDeleted;
  protected
    procedure AfterPaint(ACanvas: TCanvas; AClip: TRect;
      FirstLine, LastLine: integer); override;
    procedure LinesInserted(FirstLine, Count: integer); override;
    procedure LinesDeleted(FirstLine, Count: integer); override;
  public
    property OnLinesInserted : TOnLinesInsertedDeleted
      read FOnLinesinserted write FOnLinesInserted;
    property OnLinesDeleted : TOnLinesInsertedDeleted
      read FOnLinesDeleted write FOnLinesDeleted;

    constructor Create(AOwner: TCustomSynEdit);
  end;


  TCharSet = set of Char;

{---- TSource Editor ---
  TSourceEditor is the class that controls access for the Editor.
 ---- TSource Editor ---}

  { TSourceEditor }

  TSourceEditor = class(TSourceEditorInterface)
  private
    //FAOwner is normally a TSourceNotebook.  This is set in the Create constructor.
    FAOwner: TComponent;
    FEditor: TSynEdit;
    FEditPlugin: TSynEditPlugin1;  // used to get the LinesInserted and
                                   //   LinesDeleted messages
    FCodeTemplates: TSynEditAutoComplete;
    FPageName: string;

    FCodeBuffer: TCodeBuffer;
    FIgnoreCodeBufferLock: integer;

    FPopUpMenu: TPopupMenu;
    FSyntaxHighlighterType: TLazSyntaxHighlighter;
    FErrorLine: integer;
    FErrorColumn: integer;
    FExecutionLine: integer;
    FModified: boolean;

    FOnAfterClose: TNotifyEvent;
    FOnAfterOpen: TNotifyEvent;
    FOnAfterSave: TNotifyEvent;
    FOnBeforeClose: TNotifyEvent;
    FOnBeforeOpen: TNotifyEvent;
    FOnBeforeSave: TNotifyEvent;
    FOnEditorChange: TNotifyEvent;
    FVisible: Boolean;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseDown: TMouseEvent;
    FOnMouseUp: TMouseEvent;
    FOnKeyDown: TKeyEvent;

    FSourceNoteBook: TSourceNotebook;

    Procedure EditorMouseMoved(Sender: TObject; Shift: TShiftState; X,Y:Integer);
    Procedure EditorMouseDown(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X,Y: Integer);
    Procedure EditorMouseUp(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X,Y: Integer);
    Procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    Procedure EditorStatusChanged(Sender: TObject; Changes: TSynStatusChanges);
    procedure SetCodeBuffer(NewCodeBuffer: TCodeBuffer);
    Function GetSource: TStrings;
    procedure SetPageName(const AValue: string);
    procedure UpdatePageName;
    Procedure SetSource(Value: TStrings);
    Function GetCurrentCursorXLine: Integer;
    Procedure SetCurrentCursorXLine(num : Integer);
    Function GetCurrentCursorYLine: Integer;
    Procedure SetCurrentCursorYLine(num: Integer);
    Function GetModified: Boolean;
    procedure SetModified(NewValue:boolean);
    Function GetInsertMode: Boolean;
    Function GetReadOnly: Boolean;
    procedure SetReadOnly(NewValue: boolean);
    procedure SetCodeTemplates(
         NewCodeTemplates: TSynEditAutoComplete);
    procedure SetPopupMenu(NewPopupMenu: TPopupMenu);
    function GetFilename: string;

    function GotoLine(Value: Integer): Integer;

    procedure CreateEditor(AOwner: TComponent; AParent: TWinControl);
    procedure SetVisible(Value: boolean);
  protected
    ErrorMsgs: TStrings;
    procedure ReParent(AParent: TWinControl);

    procedure ProcessCommand(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
    procedure ProcessUserCommand(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
    procedure UserCommandProcessed(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
    procedure ccAddMessage(Texts: String);

    procedure FocusEditor;// called by TSourceNotebook when the Notebook page
                          // changes so the editor is focused
    procedure OnGutterClick(Sender: TObject; X, Y, Line: integer;
         mark: TSynEditMark);
    procedure OnEditorSpecialLineColor(Sender: TObject; Line: integer;
         var Special: boolean; var FG, BG: TColor);
    Function RefreshEditorSettings: Boolean;
    procedure SetSyntaxHighlighterType(
         ASyntaxHighlighterType: TLazSyntaxHighlighter);
    procedure SetErrorLine(NewLine: integer);
    procedure SetExecutionLine(NewLine: integer);
    procedure OnCodeBufferChanged(Sender: TSourceLog;
      SrcLogEntry: TSourceLogEntry);
    procedure StartIdentCompletion(JumpToError: boolean);

    procedure LinesInserted(sender: TObject; FirstLine,Count: Integer);
    procedure LinesDeleted(sender: TObject; FirstLine,Count: Integer);

    property Visible: Boolean read FVisible write SetVisible default False;
  public
    constructor Create(AOwner: TComponent; AParent: TWinControl);
    destructor Destroy; override;
    Function Close: Boolean;

    // codebuffer
    procedure IncreaseIgnoreCodeBufferLock;
    procedure DecreaseIgnoreCodeBufferLock;
    procedure UpdateCodeBuffer; // copy the source from EditorComponent

    // dialogs
    procedure StartFindAndReplace(Replace:boolean);
    procedure OnReplace(Sender: TObject; const ASearch, AReplace:
       string; Line, Column: integer; var Action: TSynReplaceAction);
    procedure DoFindAndReplace;
    procedure FindNext;
    procedure FindPrevious;
    procedure ShowGotoLineDialog;
    procedure GetDialogPosition(Width, Height:integer; var Left,Top:integer);
    procedure ActivateHint(ClientPos: TPoint; const TheHint: string);

    // selections
    function SelectionAvailable: boolean;
    function GetText(OnlySelection: boolean): string;
    Procedure SelectText(LineNum,CharStart,LineNum2,CharEnd: Integer);
    procedure ReplaceLines(StartLine, EndLine: integer; const NewText: string);
    procedure EncloseSelection;
    procedure UpperCaseSelection;
    procedure LowerCaseSelection;
    procedure TabsToSpacesInSelection;
    procedure CommentSelection;
    procedure UncommentSelection;
    procedure ConditionalSelection;
    procedure SortSelection;
    procedure BreakLinesInSelection;
    procedure InvertAssignment;
    procedure SelectToBrace;
    procedure SelectCodeBlock;
    procedure SelectWord;
    procedure SelectLine;
    procedure SelectParagraph;
    function CommentText(const Txt: string; CommentType: TCommentType): string;
    procedure InsertCharacterFromMap;
    procedure InsertGPLNotice(CommentType: TCommentType);
    procedure InsertLGPLNotice(CommentType: TCommentType);
    procedure InsertUsername;
    procedure InsertDateTime;
    procedure InsertChangeLogEntry;
    procedure InsertCVSKeyword(const AKeyWord: string);
    
    // context help
    procedure FindHelpForSourceAtCursor;

    // editor commands
    procedure DoEditorExecuteCommand(EditorCommand: integer);

    // used to get the word at the mouse cursor
    Function GetWordAtPosition(Position: TPoint): String;
    function GetWordFromCaret(const ACaretPos: TPoint): String;
    function GetWordFromCaretEx(const ACaretPos: TPoint;
      const ALeftLimit, ARightLimit: TCharSet): String;
    Function GetWordAtCurrentCaret: String;
    function CaretInSelection(const ACaretPos: TPoint): Boolean;
    function PositionInSelection(const APosition: TPoint): Boolean;

    // cursor
    Function GetCaretPosFromCursorPos(CursorPos: TPoint): TPoint;
    procedure CenterCursor;

    // notebook
    procedure Activate;
    function PageIndex: integer;
    function IsActiveOnNoteBook: boolean;
  public
    // properties
    property CodeBuffer: TCodeBuffer read FCodeBuffer write SetCodeBuffer;
    property CodeTemplates: TSynEditAutoComplete
       read FCodeTemplates write SetCodeTemplates;
    property CurrentCursorXLine: Integer
       read GetCurrentCursorXLine write SetCurrentCursorXLine;
    property CurrentCursorYLine: Integer
       read GetCurrentCursorYLine write SetCurrentCursorYLine;
    property EditorComponent: TSynEdit read FEditor;
    property ErrorLine: integer read FErrorLine write SetErrorLine;
    property ExecutionLine: integer read FExecutionLine write SetExecutionLine;
    property FileName: AnsiString read GetFileName;
    property InsertMode: Boolean read GetInsertmode;
    property Modified: Boolean read GetModified write SetModified;
    property OnAfterClose: TNotifyEvent read FOnAfterClose write FOnAfterClose;
    property OnBeforeClose: TNotifyEvent read FOnBeforeClose
                                          write FOnBeforeClose;
    property OnAfterOpen: TNotifyEvent read FOnAfterOpen write FOnAfterOpen;
    property OnBeforeOpen: TNotifyEvent read FOnBeforeOpen write FOnBeforeOpen;
    property OnAfterSave: TNotifyEvent read FOnAfterSave write FOnAfterSave;
    property OnBeforeSave: TNotifyEvent read FOnBeforeSave write FOnBeforeSave;
    property OnEditorChange: TNotifyEvent read FOnEditorChange
                                          write FOnEditorChange;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property Owner: TComponent read FAOwner;
    property PageName: string read FPageName write SetPageName;
    property PopupMenu: TPopupMenu read FPopUpMenu write SetPopUpMenu;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property Source: TStrings read GetSource write SetSource;
    property SourceNoteBook: TSourceNotebook read FSourceNoteBook;
    property SyntaxHighlighterType: TLazSyntaxHighlighter
       read fSyntaxHighlighterType write SetSyntaxHighlighterType;
  end;

  //============================================================================

  { TSourceNotebook }

  TJumpHistoryAction = (jhaBack, jhaForward);

  TOnJumpToHistoryPoint = procedure(var NewCaretXY: TPoint;
                                    var NewTopLine, NewPageIndex: integer;
                                    Action: TJumpHistoryAction) of object;
  TOnAddJumpPoint = procedure(ACaretXY: TPoint; ATopLine: integer;
                  APageIndex: integer; DeleteForwardHistory: boolean) of object;
  TOnMovingPage = procedure(Sender: TObject;
                            OldPageIndex, NewPageIndex: integer) of object;
  TOnShowHintForSource = procedure(SrcEdit: TSourceEditor; ClientPos: TPoint;
                                   CaretPos: TPoint) of object;
  TOnInitIdentCompletion = procedure(Sender: TObject; JumpToError: boolean;
                                     out Handled, Abort: boolean) of object;
  TSrcEditPopupMenuEvent = procedure(AddMenuItemProc: TAddMenuItemProc
                                     ) of object;
  TOnShowCodeContext = procedure(JumpToError: boolean;
                                 out Abort: boolean) of object;

  TSourceNotebookState = (snIncrementalFind, snIncrementalSearching);
  TSourceNotebookStates = set of TSourceNotebookState;

  { TSourceNotebook }

  TSourceNotebook = class(TForm)
    AddBreakpointMenuItem: TMenuItem;
    AddWatchAtCursorMenuItem: TMenuItem;
    ClosePageMenuItem: TMenuItem;
    CompleteCodeMenuItem: TMenuItem;
    DebugMenuItem: TMenuItem;
    EditorPropertiesMenuItem: TMenuItem;
    EncloseSelectionMenuItem: TMenuItem;
    ExtractProcMenuItem: TMenuItem;
    InvertAssignmentMenuItem: TMenuItem;
    FindDeclarationMenuItem: TMenuItem;
    CutMenuItem: TMenuItem;
    CopyMenuItem: TMenuItem;
    PasteMenuItem: TMenuItem;
    GotoBookmarkMenuItem: TMenuItem;
    NextBookmarkMenuItem: TMenuItem;
    PrevBookmarkMenuItem: TMenuItem;
    MoveEditorLeftMenuItem: TMenuItem;
    MoveEditorRightMenuItem: TMenuItem;
    OpenFileAtCursorMenuItem: TMenuItem;
    ReadOnlyMenuItem: TMenuItem;
    RefactorMenuItem: TMenuItem;
    FindIdentifierReferencesMenuItem: TMenuItem;
    RenameIdentifierMenuItem: TMenuItem;
    RunToCursorMenuItem: TMenuItem;
    SetBookmarkMenuItem: TMenuItem;
    ShowLineNumbersMenuItem: TMenuItem;
    ShowUnitInfoMenuItem: TMenuItem;
    ViewCallStackMenuItem: TMenuItem;

    SrcPopUpMenu: TPopupMenu;
    StatusBar: TStatusBar;
    Notebook: TNotebook;
    procedure AddBreakpointClicked(Sender: TObject);
    procedure CompleteCodeMenuItemClick(Sender: TObject);
    procedure DeleteBreakpointClicked(Sender: TObject);
    procedure EncloseSelectionMenuItemClick(Sender: TObject);
    procedure ExtractProcMenuItemClick(Sender: TObject);
    procedure InvertAssignmentMenuItemClick(Sender: TObject);
    procedure FindIdentifierReferencesMenuItemClick(Sender: TObject);
    procedure RenameIdentifierMenuItemClick(Sender: TObject);
    procedure RunToClicked(Sender: TObject);
    procedure ViewCallStackClick(Sender: TObject);
    procedure AddWatchAtCursor(Sender: TObject);
    procedure BookmarkGoTo(Index: Integer);
    procedure BookmarkGotoNext(GoForward: boolean);
    procedure BookMarkNextClicked(Sender: TObject);
    procedure BookMarkPrevClicked(Sender: TObject);
    procedure BookMarkGotoClicked(Sender: TObject);
    procedure BookMarkSet(Value: Integer);
    procedure BookMarkSetClicked(Sender: TObject);
    procedure BookMarkToggle(Value: Integer);
    procedure EditorPropertiesClicked(Sender: TObject);
    procedure FindDeclarationClicked(Sender: TObject);
    procedure MoveEditorLeftClicked(Sender: TObject);
    procedure MoveEditorRightClicked(Sender: TObject);
    procedure NotebookPageChanged(Sender: TObject);
    procedure NotebookShowTabHint(Sender: TObject; HintInfo: PHintInfo);
    procedure OpenAtCursorClicked(Sender: TObject);
    procedure ReadOnlyClicked(Sender: TObject);
    procedure OnPopupMenuOpenPasFile(Sender: TObject);
    procedure OnPopupMenuOpenPPFile(Sender: TObject);
    procedure OnPopupMenuOpenLFMFile(Sender: TObject);
    procedure OnPopupMenuOpenLRSFile(Sender: TObject);
    procedure ShowUnitInfo(Sender: TObject);
    procedure SrcPopUpMenuPopup(Sender: TObject);
    procedure ToggleLineNumbersClicked(Sender: TObject);
  private
    fAutoFocusLock: integer;
    FCodeTemplateModul: TSynEditAutoComplete;
    fCustomPopupMenuItems: TList;
    fContextPopupMenuItems: TList;
    fIdentCompletionJumpToError: boolean;
    FIncrementalSearchPos: TPoint; // last set position
    fIncrementalSearchStartPos: TPoint; // position where to start searching
    fIncrementalSearchCancelPos: TPoint;// position where to jump on cancel
    FIncrementalSearchStr: string;
    FKeyStrokes: TSynEditKeyStrokes;
    FLastCodeBuffer: TCodeBuffer;
    FOnAddJumpPoint: TOnAddJumpPoint;
    FOnAddWatchAtCursor: TOnAddWatch;
    FOnCloseClicked: TNotifyEvent;
    FOnCtrlMouseUp: TMouseEvent;
    FOnCurrentCodeBufferChanged: TNotifyEvent;
    FOnDeleteLastJumpPoint: TNotifyEvent;
    FOnEditorChanged: TNotifyEvent;
    FOnEditorPropertiesClicked: TNotifyEvent;
    FOnEditorVisibleChanged: TNotifyEvent;
    FOnFindDeclarationClicked: TNotifyEvent;
    FOnInitIdentCompletion: TOnInitIdentCompletion;
    FOnJumpToHistoryPoint: TOnJumpToHistoryPoint;
    FOnMovingPage: TOnMovingPage;
    FOnOpenFileAtCursorClicked: TNotifyEvent;
    FOnProcessUserCommand: TOnProcessUserCommand;
    fOnReadOnlyChanged: TNotifyEvent;
    FOnShowHintForSource: TOnShowHintForSource;
    FOnShowSearchResultsView: TNotifyEvent;
    FOnShowUnitInfo: TNotifyEvent;
    FOnToggleFormUnitClicked: TNotifyEvent;
    FOnToggleObjectInspClicked: TNotifyEvent;
    FOnUserCommandProcessed: TOnProcessUserCommand;
    FOnViewJumpHistory: TNotifyEvent;
    FProcessingCommand: boolean;
    FSourceEditorList: TList; // list of TSourceEditor
    FUnUsedEditorComponents: TList; // list of TSynEdit
    FOnPopupMenu: TSrcEditPopupMenuEvent;
  private
    // colors for the completion form (popup form, e.g. word completion)
    FActiveEditDefaultFGColor: TColor;
    FActiveEditDefaultBGColor: TColor;
    FActiveEditSelectedFGColor: TColor;
    FActiveEditSelectedBGColor: TColor;
    FActiveEditKeyFGColor: TColor;
    FActiveEditKeyBGColor: TColor;
    FActiveEditSymbolFGColor: TColor;
    FActiveEditSymbolBGColor: TColor;
    FOnShowCodeContext: TOnShowCodeContext;

    // PopupMenu
    procedure BuildPopupMenu;
    procedure RemoveUserDefinedMenuItems;
    function AddUserDefinedPopupMenuItem(const NewCaption: string;
                                     const NewEnabled: boolean;
                                     const NewOnClick: TNotifyEvent): TMenuItem;
    procedure RemoveContextMenuItems;
    function AddContextPopupMenuItem(const NewCaption: string;
                                     const NewEnabled: boolean;
                                     const NewOnClick: TNotifyEvent): TMenuItem;

    procedure UpdateActiveEditColors;
    procedure SetIncrementalSearchStr(const AValue: string);
    procedure DoIncrementalSearch;
  protected
    ccSelection: String;
    States: TSourceNotebookStates;

    function CreateNotebook: Boolean;
    function NewSE(Pagenum: Integer): TSourceEditor;
    procedure EditorChanged(Sender: TObject);

    procedure ccExecute(Sender: TObject);
    procedure ccCancel(Sender: TObject);
    procedure ccComplete(var Value: ansistring; Shift: TShiftState);
    function OnSynCompletionPaintItem(const AKey: string; ACanvas: TCanvas;
       X, Y: integer; ItemSelected: boolean; Index: integer): boolean;
    procedure OnSynCompletionSearchPosition(var APosition: integer);
    procedure OnSynCompletionCompletePrefix(Sender: TObject);
    procedure OnSynCompletionNextChar(Sender: TObject);
    procedure OnSynCompletionPrevChar(Sender: TObject);
    procedure OnSynCompletionKeyPress(Sender: TObject; var Key: Char);
    procedure DeactivateCompletionForm;
    procedure InitIdentCompletion(S: TStrings);

    procedure EditorMouseMove(Sender: TObject; Shift: TShiftstate;
       X,Y: Integer);
    procedure EditorMouseDown(Sender: TObject; Button: TMouseButton;
       Shift: TShiftstate; X,Y: Integer);
    procedure EditorMouseUp(Sender: TObject; Button: TMouseButton;
       Shift: TShiftstate; X,Y: Integer);

    //hintwindow stuff
    FHintWindow: THintWindow;
    FHintTimer: TTimer;
    procedure HintTimer(Sender: TObject);
    procedure OnApplicationUserInput(Sender: TObject; Msg: Cardinal);
    procedure ShowSynEditHint(const MousePos: TPoint);

    Procedure NextEditor;
    Procedure PrevEditor;
    procedure MoveEditor(OldPageIndex, NewPageIndex: integer);
    procedure MoveEditorLeft(PageIndex: integer);
    procedure MoveEditorRight(PageIndex: integer);
    procedure MoveActivePageLeft;
    procedure MoveActivePageRight;
    Procedure ProcessParentCommand(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer;
       var Handled: boolean);
    Procedure ParentCommandProcessed(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer;
       var Handled: boolean);

    // marks
    function FindBookmark(BookmarkID: integer): TSourceEditor;
    function OnSourceMarksGetSourceEditor(ASynEdit: TCustomSynEdit): TObject;
    function OnSourceMarksGetFilename(ASourceEditor: TObject): string;

    function GetEditors(Index:integer): TSourceEditor;

    procedure KeyDownBeforeInterface(var Key: Word; Shift: TShiftState); override;

    procedure BeginAutoFocusLock;
    procedure EndAutoFocusLock;
  public
    FindReplaceDlgHistoryIndex: array[TFindDlgComponent] of integer;
    FindReplaceDlgUserText: array[TFindDlgComponent] of string;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Editors[Index:integer]:TSourceEditor read GetEditors;
    function EditorCount:integer;
    function Empty: boolean;

    function FindSourceEditorWithPageIndex(PageIndex:integer):TSourceEditor;
    function FindPageWithEditor(ASourceEditor: TSourceEditor):integer;
    function FindSourceEditorWithEditorComponent(
                                         EditorComp: TComponent): TSourceEditor;
    function FindSourceEditorWithFilename(const Filename: string): TSourceEditor;
    Function GetActiveSE: TSourceEditor;
    procedure SetActiveSE(SrcEdit: TSourceEditor);
    procedure CheckCurrentCodeBufferChanged;

    procedure LockAllEditorsInSourceChangeCache;
    procedure UnlockAllEditorsInSourceChangeCache;
    function GetDiffFiles: TDiffFiles;
    procedure GetSourceText(PageIndex: integer; OnlySelection: boolean;
                            var Source: string);

    Function ActiveFileName: AnsiString;
    Function FindUniquePageName(FileName:string; IgnorePageIndex:integer):string;
    function SomethingModified: boolean;
    procedure UpdateStatusBar;
    Procedure ClearUnusedEditorComponents(Force: boolean);
    procedure ClearErrorLines;
    procedure ClearExecutionLines;

    procedure CloseClicked(Sender: TObject);
    procedure ToggleFormUnitClicked(Sender: TObject);
    procedure ToggleObjectInspClicked(Sender: TObject);

    // find / replace text
    procedure InitFindDialog;
    procedure FindClicked(Sender: TObject);
    procedure FindNextClicked(Sender: TObject);
    procedure FindPreviousClicked(Sender: TObject);
    procedure ReplaceClicked(Sender: TObject);

    // incremental find
    procedure IncrementalFindClicked(Sender: TObject);
    procedure EndIncrementalFind;
    property IncrementalSearchStr: string
      read FIncrementalSearchStr write SetIncrementalSearchStr;

    // FindInFiles
    procedure FindInFilesPerDialog(AProject: TProject);
    procedure FindInFiles(AProject: TProject; const FindText: string);
    procedure ShowSearchResultsView;
    function CreateFindInFilesDialog: TLazFindInFilesDialog;
    procedure LoadFindInFilesHistory(ADialog: TLazFindInFilesDialog);
    procedure SaveFindInFilesHistory(ADialog: TLazFindInFilesDialog);
    procedure FIFSearchProject(AProject: TProject;
                               ADialog: TLazFindInFilesDialog);
    procedure FIFSearchOpenFiles(ADialog: TLazFindInFilesDialog);
    procedure FIFSearchDir(ADialog: TLazFindInFilesDialog);
    function FIFCreateSearchForm(ADialog:TLazFindInFilesDialog): TSearchForm;
    procedure DoFindInFiles(ASearchForm: TSearchForm);

    // goto line number
    procedure GotoLineClicked(Sender: TObject);

    // history jumping
    procedure HistoryJump(Sender: TObject; CloseAction: TJumpHistoryAction);
    procedure JumpBackClicked(Sender: TObject);
    procedure JumpForwardClicked(Sender: TObject);
    procedure AddJumpPointClicked(Sender: TObject);
    procedure DeleteLastJumpPointClicked(Sender: TObject);
    procedure ViewJumpHistoryClicked(Sender: TObject);

    // hints
    procedure ActivateHint(const ScreenPos: TPoint; const TheHint: string);
    procedure HideHint;
    procedure StartShowCodeContext(JumpToError: boolean);

    Procedure NewFile(const NewShortName: String; ASource: TCodeBuffer;
                      FocusIt: boolean);
    Procedure CloseFile(PageIndex:integer);
    procedure FocusEditor;

    procedure CutClicked(Sender: TObject);
    procedure CopyClicked(Sender: TObject);
    procedure PasteClicked(Sender: TObject);

    Procedure ToggleBookmark(Value: Integer);
    Procedure SetBookmark(Value: Integer);
    Procedure GotoBookmark(Value: Integer);

    Procedure ReloadEditorOptions;
    Procedure GetSynEditPreviewSettings(APreviewEditor: TObject);

    Property CodeTemplateModul: TSynEditAutoComplete
       read FCodeTemplateModul write FCodeTemplateModul;
    procedure OnCodeTemplateTokenNotFound(Sender: TObject; AToken: string;
                                AnEditor: TCustomSynEdit; var Index:integer);
    procedure OnWordCompletionGetSource(
       var Source: TStrings; SourceIndex: integer);
    procedure OnIdentCompletionTimer(Sender: TObject);

    procedure FindReplaceDlgKey(Sender: TObject; var Key: Word;
                  Shift:TShiftState; FindDlgComponent: TFindDlgComponent);
  published
    property OnAddJumpPoint: TOnAddJumpPoint
                                     read FOnAddJumpPoint write FOnAddJumpPoint;
    property OnCloseClicked: TNotifyEvent
                                     read FOnCloseClicked write FOnCloseClicked;
    property OnCtrlMouseUp: TMouseEvent
                                       read FOnCtrlMouseUp write FOnCtrlMouseUp;
    property OnDeleteLastJumpPoint: TNotifyEvent
                       read FOnDeleteLastJumpPoint write FOnDeleteLastJumpPoint;
    property OnEditorVisibleChanged: TNotifyEvent
                     read FOnEditorVisibleChanged write FOnEditorVisibleChanged;
    property OnEditorChanged: TNotifyEvent
                                   read FOnEditorChanged write FOnEditorChanged;
    property OnEditorPropertiesClicked: TNotifyEvent
               read FOnEditorPropertiesClicked write FOnEditorPropertiesClicked;
    property OnCurrentCodeBufferChanged: TNotifyEvent
             read FOnCurrentCodeBufferChanged write FOnCurrentCodeBufferChanged;
    property OnFindDeclarationClicked: TNotifyEvent
                 read FOnFindDeclarationClicked write FOnFindDeclarationClicked;
    property OnInitIdentCompletion: TOnInitIdentCompletion
                       read FOnInitIdentCompletion write FOnInitIdentCompletion;
    property OnShowCodeContext: TOnShowCodeContext
                               read FOnShowCodeContext write FOnShowCodeContext;
    property OnJumpToHistoryPoint: TOnJumpToHistoryPoint
                         read FOnJumpToHistoryPoint write FOnJumpToHistoryPoint;
    property OnMovingPage: TOnMovingPage read FOnMovingPage write FOnMovingPage;
    property OnOpenFileAtCursorClicked: TNotifyEvent
               read FOnOpenFileAtCursorClicked write FOnOpenFileAtCursorClicked;
    property OnReadOnlyChanged: TNotifyEvent
                               read fOnReadOnlyChanged write fOnReadOnlyChanged;
    property OnShowHintForSource: TOnShowHintForSource
                           read FOnShowHintForSource write FOnShowHintForSource;
    property OnShowUnitInfo: TNotifyEvent
                                     read FOnShowUnitInfo write FOnShowUnitInfo;
    property OnToggleFormUnitClicked: TNotifyEvent
                   read FOnToggleFormUnitClicked write FOnToggleFormUnitClicked;
    property OnToggleObjectInspClicked: TNotifyEvent
               read FOnToggleObjectInspClicked write FOnToggleObjectInspClicked;
    property OnProcessUserCommand: TOnProcessUserCommand
                         read FOnProcessUserCommand write FOnProcessUserCommand;
    property OnUserCommandProcessed: TOnUserCommandProcessed
                     read FOnUserCommandProcessed write FOnUserCommandProcessed;
    property OnViewJumpHistory: TNotifyEvent
                               read FOnViewJumpHistory write FOnViewJumpHistory;
    property OnAddWatchAtCursor: TOnAddWatch
                             read FOnAddWatchAtCursor write FOnAddWatchAtCursor;
    property OnShowSearchResultsView: TNotifyEvent
                   read FOnShowSearchResultsView write FOnShowSearchResultsView;
    property OnPopupMenu: TSrcEditPopupMenuEvent read FOnPopupMenu write FOnPopupMenu;
  end;

  //=============================================================================

{ Goto dialog }

  TfrmGoto = class(TForm)
    Label1: TLabel;
    Edit1: TEdit;
    btnOK: TBitbtn;
    btnCancel: TBitBtn;
    procedure Edit1KeyDown(Sender: TObject; var Key:Word; Shift:TShiftState);
  public
    constructor Create(AOwner: TComponent); override;
    procedure DoShow; override;
  end;
  
const
  SourceEditorMenuRootName = 'SourceEditor';

var
  SrcEditMenuFindDeclaration: TIDEMenuCommand;
  SrcEditMenuOpenFileAtCursor: TIDEMenuCommand;
  SrcEditMenuClosePage: TIDEMenuCommand;
  SrcEditMenuCut: TIDEMenuCommand;
  SrcEditMenuCopy: TIDEMenuCommand;
  SrcEditMenuPaste: TIDEMenuCommand;
  SrcEditMenuAddBreakpoint: TIDEMenuCommand;
  SrcEditMenuRunToCursor: TIDEMenuCommand;
  SrcEditMenuAddWatchAtCursor: TIDEMenuCommand;
  SrcEditMenuViewCallStack: TIDEMenuCommand;
  SrcEditMenuCompleteCode: TIDEMenuCommand;
  SrcEditMenuEncloseSelection: TIDEMenuCommand;
  SrcEditMenuExtractProc: TIDEMenuCommand;
  SrcEditMenuInvertAssignment: TIDEMenuCommand;
  SrcEditMenuFindIdentifierReferences: TIDEMenuCommand;
  SrcEditMenuRenameIdentifier: TIDEMenuCommand;
  SrcEditMenuMoveEditorLeft: TIDEMenuCommand;
  SrcEditMenuMoveEditorRight: TIDEMenuCommand;
  SrcEditMenuReadOnly: TIDEMenuCommand;
  SrcEditMenuShowLineNumbers: TIDEMenuCommand;
  SrcEditMenuShowUnitInfo: TIDEMenuCommand;
  SrcEditMenuEditorProperties: TIDEMenuCommand;

procedure RegisterStandardSourceEditorMenuItems;


implementation

var
  Highlighters: array[TLazSyntaxHighlighter] of TSynCustomHighlighter;
  // aCompletion:
  //   The component controlling the completion form. It is created on demand
  //   and killed when the IDE ends.
  aCompletion: TSynCompletion;
  // CurCompletionControl contains aCompletion whenever the completion form is
  // active
  CurCompletionControl: TSynCompletion;
  CurrentCompletionType: TCompletionType;
  IdentCompletionTimer: TIdleTimer;
  AWordCompletion: TWordCompletion;

  GotoDialog: TfrmGoto;

procedure RegisterStandardSourceEditorMenuItems;
var
  Path: String;
  SubPath: String;
  SubSubPath: String;
  I: Integer;
begin
  SourceEditorMenuRoot:=RegisterIDEMenuRoot(SourceEditorMenuRootName);
  Path:=SourceEditorMenuRoot.Name;
  
  // register the first dynamic section for often used context sensitive stuff
  SrcEditMenuSectionFirstDynamic:=RegisterIDEMenuSection(Path,
                                                         'First dynamic section');
  // register the first static section
  SrcEditMenuSectionFirstStatic:=RegisterIDEMenuSection(Path,'First static section');
  SubPath:=SrcEditMenuSectionFirstStatic.GetPath;
  SrcEditMenuFindDeclaration:=RegisterIDEMenuCommand(SubPath,'Find Declaration',
                                            uemFindDeclaration);
  SrcEditMenuOpenFileAtCursor:=RegisterIDEMenuCommand(SubPath,
                                     'Open File At Cursor',uemOpenFileAtCursor);
  SrcEditMenuClosePage:=RegisterIDEMenuCommand(SubPath,
                                                     'Close Page',uemClosePage);

  // register the Clipboard section
  SrcEditMenuSectionClipboard:=RegisterIDEMenuSection(Path,'Clipboard');
  SubPath:=SrcEditMenuSectionClipboard.GetPath;
  SrcEditMenuCut:=RegisterIDEMenuCommand(SubPath,'Cut',uemCut);
  SrcEditMenuCopy:=RegisterIDEMenuCommand(SubPath,'Copy',uemCopy);
  SrcEditMenuPaste:=RegisterIDEMenuCommand(SubPath,'Paste',uemPaste);

  // register the File Specific dynamic section
  SrcEditMenuSectionFileDynamic:=RegisterIDEMenuSection(Path,
                                                        'File dynamic section');

  // register the Marks section
  SrcEditMenuSectionMarks:=RegisterIDEMenuSection(Path,'Marks section');
  SubPath:=SrcEditMenuSectionMarks.GetPath;

    // register the Goto Bookmarks Submenu
    SrcEditSubMenuGotoBookmarks:=RegisterIDESubMenu(SubPath,'Goto bookmarks',
                                                    uemGotoBookmark);
    SubSubPath:=SrcEditSubMenuGotoBookmarks.GetPath;
    for I := 0 to 9 do
      RegisterIDEMenuCommand(SubSubPath,'GotoBookmark'+IntToStr(I),
                             uemBookmarkN+IntToStr(i));

    // register the Set Bookmarks Submenu
    SrcEditSubMenuSetBookmarks:=RegisterIDESubMenu(SubPath,'Set bookmarks',
                                                   uemSetBookmark);
    SubSubPath:=SrcEditSubMenuSetBookmarks.GetPath;
    for I := 0 to 9 do
      RegisterIDEMenuCommand(SubSubPath,'SetBookmark'+IntToStr(I),
                             uemBookmarkN+IntToStr(i));

    // register the Debug submenu
    SrcEditSubMenuDebug:=RegisterIDESubMenu(SubPath,'Debug',uemDebugWord);
    SubSubPath:=SrcEditSubMenuDebug.GetPath;
    SrcEditMenuAddBreakpoint:=RegisterIDEMenuCommand(SubSubPath,'Add Breakpoint',
                                                     uemAddBreakpoint);
    SrcEditMenuAddWatchAtCursor:=RegisterIDEMenuCommand(SubSubPath,
                                       'Add Watch at Cursor',uemAddWatchAtCursor);
    SrcEditMenuRunToCursor:=RegisterIDEMenuCommand(SubSubPath,
                                                  'Run to cursor',uemRunToCursor);
    SrcEditMenuViewCallStack:=RegisterIDEMenuCommand(SubSubPath,
                                          'View Call Stack',uemViewCallStack);

  // register the Move Page section
  SrcEditMenuSectionMovePage:=RegisterIDEMenuSection(Path,'Move Page section');
  SubPath:=SrcEditMenuSectionMovePage.GetPath;
  SrcEditMenuMoveEditorLeft:=RegisterIDEMenuCommand(SubPath,'MoveEditorLeft',
                                                    uemMoveEditorLeft);
  SrcEditMenuMoveEditorRight:=RegisterIDEMenuCommand(SubPath,'MoveEditorRight',
                                                    uemMoveEditorRight);

  // register the Refactoring submenu
  SrcEditSubMenuRefactor:=RegisterIDESubMenu(Path,'Refactoring',uemRefactor);
  SubSubPath:=SrcEditSubMenuRefactor.GetPath;
  SrcEditMenuCompleteCode:=RegisterIDEMenuCommand(SubSubPath,'CompleteCode',
                                                  uemCompleteCode);
  SrcEditMenuEncloseSelection:=RegisterIDEMenuCommand(SubSubPath,
                                        'EncloseSelection',uemEncloseSelection);
  SrcEditMenuExtractProc:=RegisterIDEMenuCommand(SubSubPath,
                                                 'ExtractProc',uemExtractProc);
  SrcEditMenuInvertAssignment:=RegisterIDEMenuCommand(SubSubPath,
                                        'InvertAssignment',uemInvertAssignment);
  SrcEditMenuFindIdentifierReferences:=RegisterIDEMenuCommand(SubSubPath,
                        'FindIdentifierReferences',uemFindIdentifierReferences);
  SrcEditMenuRenameIdentifier:=RegisterIDEMenuCommand(SubSubPath,
                                        'RenameIdentifier',uemRenameIdentifier);

  // register the Flags section
  SrcEditMenuSectionFlags:=RegisterIDEMenuSection(Path,'Flags section');
  SubPath:=SrcEditMenuSectionFlags.GetPath;
  SrcEditMenuReadOnly:=RegisterIDEMenuCommand(SubPath,'ReadOnly',uemReadOnly);
  SrcEditMenuReadOnly.ShowAlwaysCheckable:=true;
  SrcEditMenuShowLineNumbers:=RegisterIDEMenuCommand(SubPath,'ShowLineNumbers',
                                                     uemShowLineNumbers);
  SrcEditMenuShowLineNumbers.ShowAlwaysCheckable:=true;
  SrcEditMenuShowUnitInfo:=RegisterIDEMenuCommand(SubPath,'ShowUnitInfo',
                                                  uemShowUnitInfo);
  SrcEditMenuEditorProperties:=RegisterIDEMenuCommand(SubPath,
                                        'EditorProperties',uemEditorProperties);
end;

{ TSourceEditor }

{ The constructor for @link(TSourceEditor).
  AOwner is the @link(TSourceNotebook)
  and the AParent is usually a page of a @link(TNotebook) }
constructor TSourceEditor.Create(AOwner: TComponent; AParent: TWinControl);
Begin
  inherited Create;
  FAOwner := AOwner;
  if (FAOwner<>nil) and (FAOwner is TSourceNotebook) then
    FSourceNoteBook:=TSourceNotebook(FAOwner)
  else
    FSourceNoteBook:=nil;

  FSyntaxHighlighterType:=lshNone;
  FErrorLine:=-1;
  FErrorColumn:=-1;
  FExecutionLine:=-1;

  CreateEditor(AOwner,AParent);

  FEditPlugin := TSynEditPlugin1.Create(FEditor);
  FEditPlugin.OnLinesInserted := @LinesInserted;
  FEditPlugin.OnLinesDeleted := @LinesDeleted;
end;

destructor TSourceEditor.Destroy;
begin
//writeln('TSourceEditor.Destroy A ',FEditor.Name);
  if (FAOwner<>nil) and (FEditor<>nil) then begin
    FEditor.Visible:=false;
    FEditor.Parent:=nil;
    if SourceEditorMarks<>nil then
      SourceEditorMarks.DeleteAllForEditor(FEditor);
    TSourceNoteBook(FAOwner).FSourceEditorList.Remove(Self);
    TSourceNoteBook(FAOwner).FUnUsedEditorComponents.Add(FEditor);
  end;
//writeln('TSourceEditor.Destroy B ');
  inherited Destroy;
//writeln('TSourceEditor.Destroy END ');
end;

{------------------------------G O T O   L I N E  -----------------------------}
Function TSourceEditor.GotoLine(Value: Integer): Integer;
Var
  P: TPoint;
  TopLine: integer;
Begin
  TSourceNotebook(Owner).AddJumpPointClicked(Self);
  P.X := 1;
  P.Y := Value;
  TopLine := P.Y - (FEditor.LinesInWindow div 2);
  if TopLine < 1 then TopLine:=1;
  FEditor.CaretXY := P;
  with FEditor do begin
    BlockBegin:=CaretXY;
    BlockEnd:=CaretXY;
  end;
  FEditor.TopLine := TopLine;
  Result:=FEditor.CaretY;
end;

procedure TSourceEditor.ShowGotoLineDialog;
begin
  GotoDialog.Edit1.Text:='';
  if (GotoDialog.ShowModal = mrOK) then
    GotoLine(StrToIntDef(GotoDialog.Edit1.Text,1));
end;

procedure TSourceEditor.GetDialogPosition(Width, Height:integer;
  var Left,Top:integer);
var P:TPoint;
begin
  with EditorComponent do
    P := ClientToScreen(Point(CaretXPix, CaretYPix));
  Left:=EditorComponent.ClientOrigin.X+(EditorComponent.Width - Width) div 2;
  Top:=P.Y-Height-2*EditorComponent.LineHeight;
  if Top<10 then
    Top:=P.y+2*EditorComponent.LineHeight;
  if Top+Height>Screen.Height then
    Top:=(Screen.Height-Height) div 2;
  if Top<0 then Top:=0;
end;

procedure TSourceEditor.ActivateHint(ClientPos: TPoint; const TheHint: string);
var
  ScreenPos: TPoint;
begin
  if SourceNoteBook=nil then exit;
  ScreenPos:=EditorComponent.ClientToScreen(ClientPos);
  SourceNoteBook.ActivateHint(ScreenPos,TheHint);
end;

{------------------------------S T A R T  F I N D-----------------------------}
procedure TSourceEditor.StartFindAndReplace(Replace:boolean);
var ALeft,ATop:integer;
begin
  if SourceNotebook<>nil then
    SourceNotebook.InitFindDialog;
  //debugln('TSourceEditor.StartFindAndReplace A FindReplaceDlg.FindText="',dbgstr(FindReplaceDlg.FindText),'"');
  if Replace then
    FindReplaceDlg.Options :=
      FindReplaceDlg.Options + [ssoReplace, ssoReplaceAll, ssoPrompt]
  else
    FindReplaceDlg.Options :=
      FindReplaceDlg.Options - [ssoReplace, ssoReplaceAll, ssoPrompt];

  // Fill in history items
  FindReplaceDlg.TextToFindComboBox.Items.Assign(InputHistories.FindHistory);
  if Replace then
    FindReplaceDlg.ReplaceTextComboBox.Items.Assign(
                                                 InputHistories.ReplaceHistory);

  with EditorComponent do begin
    if EditorOpts.FindTextAtCursor then begin
      if SelAvail and (BlockBegin.Y = BlockEnd.Y) then begin
        //debugln('TSourceEditor.StartFindAndReplace B FindTextAtCursor SelAvail');
        FindReplaceDlg.FindText := SelText
      end else begin
        //debugln('TSourceEditor.StartFindAndReplace B FindTextAtCursor not SelAvail');
        FindReplaceDlg.FindText := GetWordAtRowCol(LogicalCaretXY);
      end;
    end else begin
      //debugln('TSourceEditor.StartFindAndReplace B not FindTextAtCursor');
      FindReplaceDlg.FindText:='';
    end;
  end;

  GetDialogPosition(FindReplaceDlg.Width,FindReplaceDlg.Height,ALeft,ATop);
  FindReplaceDlg.Left:=ALeft;
  FindReplaceDlg.Top:=ATop;

  if (FindReplaceDlg.ShowModal = mrCancel) then begin
    exit;
  end;
  //debugln('TSourceEditor.StartFindAndReplace B FindReplaceDlg.FindText="',dbgstr(FindReplaceDlg.FindText),'"');

  if Replace then
    InputHistories.AddToReplaceHistory(FindReplaceDlg.ReplaceText);
  InputHistories.AddToFindHistory(FindReplaceDlg.FindText);
  InputHistories.Save;
  DoFindAndReplace;
End;

{------------------------------F I N D  A G A I N ----------------------------}
procedure TSourceEditor.FindNext;
var
  OldOptions: TSynSearchOptions;
Begin
  if snIncrementalFind in FSourceNoteBook.States then begin
    FSourceNoteBook.fIncrementalSearchStartPos:=FEditor.LogicalCaretXY;
    FSourceNoteBook.DoIncrementalSearch;
  end else begin
    OldOptions:=FindReplaceDlg.Options;
    FindReplaceDlg.Options:=FindReplaceDlg.Options-[ssoEntireScope];
    DoFindAndReplace;
    FindReplaceDlg.Options:=OldOptions;
  end;
End;

{---------------------------F I N D   P R E V I O U S ------------------------}
procedure TSourceEditor.FindPrevious;
var OldOptions: TSynSearchOptions;
Begin
  OldOptions:=FindReplaceDlg.Options;
  FindReplaceDlg.Options:=FindReplaceDlg.Options-[ssoEntireScope];
  if ssoBackwards in FindReplaceDlg.Options then
    FindReplaceDlg.Options:=FindReplaceDlg.Options-[ssoBackwards]
  else
    FindReplaceDlg.Options:=FindReplaceDlg.Options+[ssoBackwards];
  DoFindAndReplace;
  FindReplaceDlg.Options:=OldOptions;
End;

procedure TSourceEditor.DoFindAndReplace;
var
  OldCaretXY:TPoint;
  AText,ACaption:AnsiString;
  TopLine: integer;
begin
  if SourceNotebook<>nil then
    SourceNotebook.AddJumpPointClicked(Self);
  OldCaretXY:=EditorComponent.CaretXY;
  if EditorComponent.SelAvail then begin
    if ssoBackwards in FindReplaceDlg.Options then
      EditorComponent.LogicalCaretXY:=EditorComponent.BlockBegin
    else
      EditorComponent.LogicalCaretXY:=EditorComponent.BlockEnd
  end;
  //debugln('TSourceEditor.DoFindAndReplace A FindReplaceDlg.FindText="',dbgstr(FindReplaceDlg.FindText),'" ssoEntireScope=',dbgs(ssoEntireScope in FindReplaceDlg.Options),' ssoBackwards=',dbgs(ssoBackwards in FindReplaceDlg.Options));
  try
    EditorComponent.SearchReplace(
      FindReplaceDlg.FindText,FindReplaceDlg.ReplaceText,FindReplaceDlg.Options);
  except
    on E: ERegExpr do begin
      MessageDlg(lisUEErrorInRegularExpression,
        E.Message,mtError,[mbCancel],0);
      exit;
    end;
  end;
  if (OldCaretXY.X=EditorComponent.CaretX)
  and (OldCaretXY.Y=EditorComponent.CaretY)
  and not (ssoReplaceAll in FindReplaceDlg.Options) then begin
    ACaption:=lisUENotFound;
    AText:=Format(lisUESearchStringNotFound, [FindReplaceDlg.FindText]);
    MessageDlg(ACaption,AText,mtInformation,[mbOk],0);
    TSourceNotebook(Owner).DeleteLastJumpPointClicked(Self);
  end else begin
    TopLine := EditorComponent.CaretY - (EditorComponent.LinesInWindow div 2);
    if TopLine < 1 then TopLine:=1;
    EditorComponent.TopLine := TopLine;
  end;
end;

procedure TSourceEditor.OnReplace(Sender: TObject; const ASearch, AReplace:
  string; Line, Column: integer; var Action: TSynReplaceAction);
var a,x,y:integer;
  AText:AnsiString;
begin
  if FAOwner<>nil then
    TSourceNotebook(FAOwner).UpdateStatusBar;
  AText:=Format(lisUEReplaceThisOccurrenceOfWith, ['"', ASearch, '"', #13, '"',
    AReplace, '"']);

  GetDialogPosition(300,150,X,Y);
  a:=MessageDlgPos(AText,mtconfirmation,
            [mbYes,mbYesToAll,mbNo,mbCancel],0,X,Y);

  case a of
    mrYes:Action:=raReplace;
    mrNo :Action:=raSkip;
    mrAll,mrYesToAll:Action:=raReplaceAll;
  else
    Action:=raCancel;
  end;
end;

//-----------------------------------------------------------------------------

Procedure TSourceEditor.FocusEditor;
Begin
  {$IFDEF VerboseFocus}
  writeln('TSourceEditor.FocusEditor A ',PageName,' ',FEditor.Name);
  {$ENDIF}
  if SourceNotebook<>nil then SourceNotebook.Visible:=true;
  FEditor.SetFocus;
  {$IFDEF VerboseFocus}
  writeln('TSourceEditor.FocusEditor END ',PageName,' ',FEditor.Name);
  {$ENDIF}
end;

Function TSourceEditor.GetReadOnly: Boolean;
Begin
  Result:=FEditor.ReadOnly;
End;

procedure TSourceEditor.SetReadOnly(NewValue: boolean);
begin
  FEditor.ReadOnly:=NewValue;
end;

Procedure TSourceEditor.ProcessCommand(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
// these are normal commands for synedit, define extra actions here
// otherwise use ProcessUserCommand
begin
  IdentCompletionTimer.AutoEnabled:=false;

  if (FSourceNoteBook<>nil)
  and (snIncrementalFind in FSourceNoteBook.States) then begin
    case Command of
    ecChar:
      begin
        if AChar=#27 then begin
          FSourceNoteBook.IncrementalSearchStr:='';
        end else
          FSourceNoteBook.IncrementalSearchStr:=
            FSourceNoteBook.IncrementalSearchStr+AChar;
        Command:=ecNone;
      end;

    ecDeleteLastChar:
      begin
        FSourceNoteBook.IncrementalSearchStr:=
          LeftStr(FSourceNoteBook.IncrementalSearchStr,
            length(FSourceNoteBook.IncrementalSearchStr)-1);
        Command:=ecNone;
      end;

    ecLineBreak:
      begin
        FSourceNoteBook.EndIncrementalFind;
        Command:=ecNone;
      end;
      
    else
      FSourceNoteBook.EndIncrementalFind;
    end;
  end;

  case Command of

  ecSelEditorTop, ecSelEditorBottom, ecEditorTop, ecEditorBottom:
    begin
      if FaOwner<>nil then
        TSourceNotebook(FaOwner).AddJumpPointClicked(Self);
    end;

  ecCopy:
    begin
      if (not FEditor.SelAvail) then begin
        // nothing selected
        if EditorOpts.CopyWordAtCursorOnCopyNone then begin
          FEditor.SetSelWord;
        end;
      end;
    end;
    
  ecChar:
    begin
      //debugln('TSourceEditor.ProcessCommand AChar="',AChar,'" AutoIdentifierCompletion=',dbgs(EditorOpts.AutoIdentifierCompletion),' Interval=',dbgs(IdentCompletionTimer.Interval));
      if (AChar='.') and EditorOpts.AutoIdentifierCompletion then
        IdentCompletionTimer.AutoEnabled:=true;
    end;

  end;
  //debugln('TSourceEditor.ProcessCommand B IdentCompletionTimer.AutoEnabled=',dbgs(IdentCompletionTimer.AutoEnabled));
end;

Procedure TSourceEditor.ProcessUserCommand(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
// define all extra keys here, that should not be handled by synedit
var
  I: Integer;
  P: TPoint;
  Texts, Texts2: String;
  Handled: boolean;
  LogCaret: TPoint;
Begin
  Handled:=true;

  //debugln('TSourceEditor.ProcessUserCommand A ',dbgs(Command));

  case Command of

  ecContextHelp:
    FindHelpForSourceAtCursor;

  ecIdentCompletion :
    StartIdentCompletion(true);

  ecShowCodeContext :
    SourceNoteBook.StartShowCodeContext(true);

  ecWordCompletion :
    if not TCustomSynEdit(Sender).ReadOnly then begin
      CurrentCompletionType:=ctWordCompletion;
      TextS := FEditor.LineText;
      LogCaret:=FEditor.LogicalCaretXY;
      i := LogCaret.X - 1;
      if i > length(TextS) then
        TextS2 := ''
      else begin
        while (i > 0) and (TextS[i] in ['a'..'z','A'..'Z','0'..'9','_']) do
          dec(i);
        TextS2 := Trim(copy(TextS, i + 1, FEditor.CaretX - i - 1));
      end;
      with TCustomSynEdit(Sender) do
        P := ClientToScreen(Point(CaretXPix - length(TextS2)*CharWidth
                ,CaretYPix + LineHeight));
      aCompletion.Editor:=TCustomSynEdit(Sender);
      aCompletion.Execute(TextS2,P.X,P.Y);
    end;

  ecFind:
    StartFindAndReplace(false);

  ecFindNext:
    FindNext;

  ecFindPrevious:
    FindPrevious;

  ecIncrementalFind:
    if FSourceNoteBook<>nil then FSourceNoteBook.IncrementalFindClicked(Self);

  ecFindInFiles:
    // ToDo
    ;

  ecReplace:
    StartFindAndReplace(true);

  ecGotoLineNumber :
    ShowGotoLineDialog;

  ecSelectionEnclose:
    EncloseSelection;

  ecSelectionUpperCase:
    UpperCaseSelection;

  ecSelectionLowerCase:
    LowerCaseSelection;

  ecSelectionTabs2Spaces:
    TabsToSpacesInSelection;

  ecSelectionComment:
    CommentSelection;

  ecSelectionUnComment:
    UncommentSelection;

  ecSelectionConditional:
    ConditionalSelection;

  ecSelectionSort:
    SortSelection;

  ecSelectionBreakLines:
    BreakLinesInSelection;

  ecInvertAssignment:
    InvertAssignment;

  ecSelectToBrace:
    SelectToBrace;

  ecSelectCodeBlock:
    SelectCodeBlock;

  ecSelectLine:
    SelectLine;

  ecSelectWord:
    SelectWord;

  ecSelectParagraph:
    SelectParagraph;

  ecInsertCharacter:
    InsertCharacterFromMap;

  ecInsertGPLNotice:
    InsertGPLNotice(comtDefault);

  ecInsertLGPLNotice:
    InsertLGPLNotice(comtDefault);

  ecInsertUserName:
    InsertUsername;

  ecInsertDateTime:
    InsertDateTime;

  ecInsertChangeLogEntry:
    InsertChangeLogEntry;

  ecInsertCVSAuthor:
    InsertCVSKeyword('Author');

  ecInsertCVSDate:
    InsertCVSKeyword('Date');

  ecInsertCVSHeader:
    InsertCVSKeyword('Header');

  ecInsertCVSID:
    InsertCVSKeyword('ID');

  ecInsertCVSLog:
    InsertCVSKeyword('Log');

  ecInsertCVSName:
    InsertCVSKeyword('Name');

  ecInsertCVSRevision:
    InsertCVSKeyword('Revision');

  ecInsertCVSSource:
    InsertCVSKeyword('Source');

  else
    begin
      Handled:=false;
      if FaOwner<>nil then
        TSourceNotebook(FaOwner).ProcessParentCommand(self,Command,aChar,Data,
                        Handled);
    end;
  end;  //case
  if Handled then Command:=ecNone;
end;

Procedure TSourceEditor.UserCommandProcessed(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
var Handled: boolean;
begin
  Handled:=true;
  case Command of

  ecNone: ;

  ecUndo:
      if (FEditor.Modified=false) and (CodeBuffer<>nil) then
        CodeBuffer.Assign(FEditor.Lines);

  else
    begin
      Handled:=false;
      if FaOwner<>nil then
        TSourceNotebook(FaOwner).ParentCommandProcessed(self,Command,aChar,Data,
                        Handled);
    end;
  end;
  if Handled then Command:=ecNone;
end;

Procedure TSourceEditor.EditorStatusChanged(Sender: TObject;
  Changes: TSynStatusChanges);
Begin
  If Assigned(OnEditorChange) then
    OnEditorChange(Sender);
  UpdatePageName;
end;

function TSourceEditor.SelectionAvailable: boolean;
begin
  Result:=CompareCaret(EditorComponent.BlockBegin,EditorComponent.BlockEnd)<>0;
end;

function TSourceEditor.GetText(OnlySelection: boolean): string;
begin
  if OnlySelection then
    Result:=EditorComponent.SelText
  else
    Result:=EditorComponent.Lines.Text;
end;

{-------------------------------------------------------------------------------
  method TSourceEditor.UpperCaseSelection

  Turns current text selection uppercase.
-------------------------------------------------------------------------------}
procedure TSourceEditor.UpperCaseSelection;
var OldBlockBegin, OldBlockEnd: TPoint;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  OldBlockBegin:=FEditor.BlockBegin;
  OldBlockEnd:=FEditor.BlockEnd;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  FEditor.SelText:=UpperCase(EditorComponent.SelText);
  FEditor.BlockBegin:=OldBlockBegin;
  FEditor.BlockEnd:=OldBlockEnd;
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

{-------------------------------------------------------------------------------
  method TSourceEditor.LowerCaseSelection

  Turns current text selection lowercase.
-------------------------------------------------------------------------------}
procedure TSourceEditor.LowerCaseSelection;
var OldBlockBegin, OldBlockEnd: TPoint;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  OldBlockBegin:=FEditor.BlockBegin;
  OldBlockEnd:=FEditor.BlockEnd;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  FEditor.SelText:=LowerCase(EditorComponent.SelText);
  FEditor.BlockBegin:=OldBlockBegin;
  FEditor.BlockEnd:=OldBlockEnd;
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

{-------------------------------------------------------------------------------
  method TSourceEditor.TabsToSpacesInSelection

  Convert all tabs into spaces in current text selection.
-------------------------------------------------------------------------------}
procedure TSourceEditor.TabsToSpacesInSelection;
var OldBlockBegin, OldBlockEnd: TPoint;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  OldBlockBegin:=FEditor.BlockBegin;
  OldBlockEnd:=FEditor.BlockEnd;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  // ToDo: replace step by step to keep bookmarks and breakpoints
  FEditor.SelText:=TabsToSpaces(EditorComponent.SelText,EditorComponent.TabWidth);
  FEditor.BlockBegin:=OldBlockBegin;
  FEditor.BlockEnd:=OldBlockEnd;
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

procedure TSourceEditor.CommentSelection;
var OldBlockBegin, OldBlockEnd: TPoint;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  OldBlockBegin:=FEditor.BlockBegin;
  OldBlockEnd:=FEditor.BlockEnd;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  // ToDo: replace step by step to keep bookmarks and breakpoints
  FEditor.SelText:=CommentLines(EditorComponent.SelText);
  FEditor.BlockBegin:=OldBlockBegin;
  FEditor.BlockEnd:=OldBlockEnd;
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

procedure TSourceEditor.UncommentSelection;
var OldBlockBegin, OldBlockEnd: TPoint;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  OldBlockBegin:=FEditor.BlockBegin;
  OldBlockEnd:=FEditor.BlockEnd;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  // ToDo: replace step by step to keep bookmarks and breakpoints
  FEditor.SelText:=UncommentLines(EditorComponent.SelText);
  FEditor.BlockBegin:=OldBlockBegin;
  FEditor.BlockEnd:=OldBlockEnd;
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

procedure TSourceEditor.ConditionalSelection;
var
  IsPascal: Boolean;
  i: Integer;
  P: TPoint;
begin
  if ReadOnly then exit;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  if not EditorComponent.SelAvail then begin
    P.Y := FEditor.CaretY;
    P.X := 1;
    FEditor.BlockBegin := P;
    Inc(P.Y);
    FEditor.BlockEnd := P;
  end;
  // ToDo: replace step by step to keep bookmarks and breakpoints
  IsPascal := True;
  i:=EditorOpts.HighlighterList.FindByHighlighter(FEditor.Highlighter);
  if i>=0 then
    IsPascal := EditorOpts.HighlighterList[i].DefaultCommentType <> comtCPP;
  FEditor.SelText:=AddConditional(EditorComponent.SelText, IsPascal);
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

procedure TSourceEditor.SortSelection;
var
  OldSelText, NewSortedText: string;
begin
  if ReadOnly then exit;
  OldSelText:=EditorComponent.SelText;
  if OldSelText='' then exit;
  if ShowSortSelectionDialog(OldSelText,EditorComponent.Highlighter,
                             NewSortedText)=mrOk
  then
    EditorComponent.SelText:=NewSortedText;
end;

procedure TSourceEditor.BreakLinesInSelection;
var
  OldSelection: String;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  // ToDo: replace step by step to keep bookmarks and breakpoints
  OldSelection:=EditorComponent.SelText;
  FEditor.SelText:=BreakLinesInText(OldSelection,FEditor.RightEdge);
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

procedure TSourceEditor.InvertAssignment;
var
  codelines: TStringList;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  // ToDo: replace step by step to keep bookmarks and breakpoints
  codelines := TStringList.Create;
  try
    codelines.Text := FEditor.SelText;
    FEditor.SelText := InvertAssignTool.InvertAssignment( codelines ).Text;
  finally
    codelines.Free;
  end;
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

procedure TSourceEditor.SelectToBrace;
begin
  EditorComponent.SelectToBrace;
end;

procedure TSourceEditor.SelectCodeBlock;
begin
  // ToDo:
  DebugLn('TSourceEditor.SelectCodeBlock: not implemented yet');
end;

procedure TSourceEditor.SelectWord;
begin
  EditorComponent.SetSelWord;
end;

procedure TSourceEditor.SelectLine;
begin
  EditorComponent.SelectLine;
end;

procedure TSourceEditor.SelectParagraph;
begin
  EditorComponent.SelectParagraph;
end;

function TSourceEditor.CommentText(const Txt: string; CommentType: TCommentType
  ): string;
var
  i: integer;
begin
  Result:=Txt;
  case CommentType of
    comtNone: exit;
    comtDefault:
      begin
        i:=EditorOpts.HighlighterList.FindByHighlighter(FEditor.Highlighter);
        if i>=0 then
          CommentType:=EditorOpts.HighlighterList[i].DefaultCommentType;
      end;
  end;
  Result:=IDEProcs.CommentText(Txt,CommentType);
end;

procedure TSourceEditor.InsertCharacterFromMap;
var
  NewChars: string;
begin
  if not ShowCharacterMap(NewChars) then exit;
  FEditor.SelText:=NewChars;
end;

procedure TSourceEditor.InsertGPLNotice(CommentType: TCommentType);
var
  Txt: string;
begin
  Txt:=CommentText(LCLProc.BreakString(
           Format(lisGPLNotice,[#13#13,#13#13,#13#13]),
           FEditor.RightEdge-2,0),CommentType);
  FEditor.SelText:=Txt;
end;

procedure TSourceEditor.InsertLGPLNotice(CommentType: TCommentType);
var
  Txt: string;
begin
  Txt:=CommentText(LCLProc.BreakString(
           Format(lisLGPLNotice,[#13#13,#13#13,#13#13]),
           FEditor.RightEdge-2,0),CommentType);
  FEditor.SelText:=Txt;
end;

procedure TSourceEditor.InsertUsername;
begin
  FEditor.SelText:=GetCurrentUserName;
end;

procedure TSourceEditor.InsertDateTime;
begin
  FEditor.SelText:=DateTimeToStr(now);
end;

procedure TSourceEditor.InsertChangeLogEntry;
var s: string;
begin
  s:=DateToStr(now)+'   '+GetCurrentUserName+' '+GetCurrentMailAddress;
  FEditor.SelText:=s;
end;

procedure TSourceEditor.InsertCVSKeyword(const AKeyWord: string);
begin
  FEditor.SelText:='$'+AKeyWord+'$'+LineEnding;
end;

procedure TSourceEditor.FindHelpForSourceAtCursor;
begin
  DebugLn('TSourceEditor.FindHelpForSourceAtCursor A');
  ShowHelpOrErrorForSourcePosition(Filename,FEditor.LogicalCaretXY);
end;

procedure TSourceEditor.OnGutterClick(Sender: TObject; X, Y, Line: integer;
  mark: TSynEditMark);
var
  BreakPtMark: TSourceMark;
begin
  // create or delete breakpoint
  // find breakpoint mark at line
  BreakPtMark := SourceEditorMarks.FindBreakPointMark(FEditor,Line);
  if BreakPtMark = nil then
    DebugBoss.DoCreateBreakPoint(Filename,Line)
  else
    DebugBoss.DoDeleteBreakPointAtMark(BreakPtMark);
end;

procedure TSourceEditor.OnEditorSpecialLineColor(Sender: TObject; Line: integer;
  var Special: boolean; var FG, BG: TColor);
var
  i:integer;
  aha: TAdditionalHilightAttribute;
  CurMarks: PSourceMark;
  CurMarkCount: integer;
  CurFG: TColor;
  CurBG: TColor;
begin
  aha := ahaNone;

  if ErrorLine = Line
  then begin
    aha := ahaErrorLine
  end
  else if ExecutionLine = Line
  then begin
    aha := ahaExecutionPoint;
  end
  else begin
    SourceEditorMarks.GetMarksForLine(FEditor,Line,CurMarks,CurMarkCount);
    if CurMarkCount>0 then begin
      for i := 0 to CurMarkCount-1 do begin
        // check highlight attribute
        aha := CurMarks[i].LineColorAttrib;
        if aha<>ahaNone then break;

        // check custom colors
        CurFG:=CurMarks[i].LineColorForeGround;
        CurBG:=CurMarks[i].LineColorBackGround;
        if (CurFG<>clNone) or (CurBG<>clNone) then begin
          FG:=CurFG;
          BG:=CurBG;
          Special:=true;
          break;
        end;
      end;
      // clean up
      FreeMem(CurMarks);
    end;
  end;
  if aha <> ahaNone
  then begin
    EditorOpts.GetSpecialLineColors(TCustomSynEdit(Sender).Highlighter, aha,
                                    Special, FG, BG);
  end;
end;

procedure TSourceEditor.SetSyntaxHighlighterType(
  ASyntaxHighlighterType: TLazSyntaxHighlighter);
begin
  if (ASyntaxHighlighterType=fSyntaxHighlighterType)
  and ((FEditor.Highlighter=nil) xor EditorOpts.UseSyntaxHighlight) then exit;
  if EditorOpts.UseSyntaxHighlight then begin
    if Highlighters[ASyntaxHighlighterType]=nil then begin
      Highlighters[ASyntaxHighlighterType]:=
        EditorOpts.CreateSyn(ASyntaxHighlighterType);
    end;
    FEditor.Highlighter:=Highlighters[ASyntaxHighlighterType];
  end else
    FEditor.Highlighter:=nil;
  if ASyntaxHighlighterType<>fSyntaxHighlighterType then begin
    fSyntaxHighlighterType:=ASyntaxHighlighterType;
  end;
  EditorOpts.GetSynEditSelectedColor(FEditor);
  SourceNoteBook.UpdateActiveEditColors;
end;

procedure TSourceEditor.SetErrorLine(NewLine: integer);
begin
//writeln('[TSourceEditor.SetErrorLine] ',NewLine,',',fErrorLine);
  if fErrorLine=NewLine then exit;
  fErrorLine:=NewLine;
  fErrorColumn:=EditorComponent.CaretX;
  EditorComponent.Invalidate;
end;

procedure TSourceEditor.SetExecutionLine(NewLine: integer);
begin
  if fExecutionLine=NewLine then exit;
  fExecutionLine:=NewLine;
  EditorComponent.Invalidate;
end;

Function TSourceEditor.RefreshEditorSettings: Boolean;
Begin
  Result:=true;
  SetSyntaxHighlighterType(fSyntaxHighlighterType);
  EditorOpts.GetSynEditSettings(FEditor);
  SourceNoteBook.UpdateActiveEditColors;
  if EditorOpts.CtrlMouseLinks then
    FEditor.Options:=FEditor.Options+[eoShowCtrlMouseLinks]
  else
    FEditor.Options:=FEditor.Options-[eoShowCtrlMouseLinks];
end;

Procedure TSourceEditor.ccAddMessage(Texts: String);
Begin
  ErrorMsgs.Add(Texts);
End;

Procedure TSourceEditor.CreateEditor(AOwner: TComponent; AParent: TWinControl);
var
  NewName: string;
  i: integer;
Begin
  {$IFDEF IDE_DEBUG}
  writeln('TSourceEditor.CreateEditor  A ');
  {$ENDIF}
  if not assigned(FEditor) then Begin
    i:=0;
    repeat
      inc(i);
      NewName:='SynEdit'+IntToStr(i);
    until (AOwner.FindComponent(NewName)=nil);
    FEditor:=TSynEdit.Create(AOwner);
    FEditor.BeginUpdate;
    with FEditor do begin
      Name:=NewName;
      Parent := AParent;
      Align := alClient;
      BookMarkOptions.EnableKeys := false;
      BookMarkOptions.LeftMargin:=1;
      WantTabs := true;
      OnStatusChange := @EditorStatusChanged;
      OnProcessCommand := @ProcessCommand;
      OnProcessUserCommand := @ProcessUserCommand;
      OnCommandProcessed := @UserCommandProcessed;
      OnReplaceText := @OnReplace;
      OnGutterClick := @Self.OnGutterClick;
      OnSpecialLineColors:=@OnEditorSpecialLineColor;
      OnMouseMove := @EditorMouseMoved;
      OnMouseDown := @EditorMouseDown;
      OnMouseUp := @EditorMouseUp;
      OnKeyDown := @EditorKeyDown;
    end;
    if FCodeTemplates<>nil then
      FCodeTemplates.AddEditor(FEditor);
    aCompletion.AddEditor(FEditor);
    RefreshEditorSettings;
    FEditor.EndUpdate;
  end else begin
    FEditor.Parent:=AParent;
  end;
end;

procedure TSourceEditor.SetCodeBuffer(NewCodeBuffer: TCodeBuffer);
begin
  if NewCodeBuffer=FCodeBuffer then exit;
  if FCodeBuffer<>nil then
    FCodeBuffer.RemoveChangeHook(@OnCodeBufferChanged);
  FCodeBuffer:=NewCodeBuffer;
  if FCodeBuffer<>nil then begin
    FCodeBuffer.AddChangeHook(@OnCodeBufferChanged);
    if (FIgnoreCodeBufferLock<=0) and (not FCodeBuffer.IsEqual(FEditor.Lines))
    then begin
      {$IFDEF IDE_DEBUG}
      writeln('');
      writeln('WARNING: TSourceEditor.SetCodeBuffer - loosing marks');
      writeln('');
      {$ENDIF}
      FEditor.BeginUpdate;
      FCodeBuffer.AssignTo(FEditor.Lines);
      FEditor.EndUpdate;
    end;
    if IsActiveOnNoteBook then SourceNoteBook.UpdateStatusBar;
  end;
end;

procedure TSourceEditor.OnCodeBufferChanged(Sender: TSourceLog;
  SrcLogEntry: TSourceLogEntry);

  procedure InsertTxt(const StartPos: TPoint; const Txt: string);
  begin
    FEditor.LogicalCaretXY:=StartPos;
    FEditor.BlockBegin:=StartPos;
    FEditor.BlockEnd:=StartPos;
    FEditor.SelText:=Txt;
  end;

  procedure DeleteTxt(const StartPos, EndPos: TPoint);
  begin
    FEditor.LogicalCaretXY:=StartPos;
    FEditor.BlockBegin:=StartPos;
    FEditor.BlockEnd:=EndPos;
    FEditor.SelText:='';
  end;

  procedure MoveTxt(const StartPos, EndPos, MoveToPos: TPoint;
    DirectionForward: boolean);
  var Txt: string;
  begin
    FEditor.LogicalCaretXY:=StartPos;
    FEditor.BlockBegin:=StartPos;
    FEditor.BlockEnd:=EndPos;
    Txt:=FEditor.SelText;
    if DirectionForward then begin
      FEditor.LogicalCaretXY:=MoveToPos;
      FEditor.BlockBegin:=MoveToPos;
      FEditor.BlockEnd:=MoveToPos;
      FEditor.SelText:=Txt;
      FEditor.LogicalCaretXY:=StartPos;
      FEditor.BlockBegin:=StartPos;
      FEditor.BlockEnd:=EndPos;
      FEditor.SelText:='';
    end else begin
      FEditor.SelText:='';
      FEditor.LogicalCaretXY:=MoveToPos;
      FEditor.BlockBegin:=MoveToPos;
      FEditor.BlockEnd:=MoveToPos;
      FEditor.SelText:=Txt;
    end;
  end;

var StartPos, EndPos, MoveToPos: TPoint;
begin
{$IFDEF IDE_DEBUG}
writeln('[TSourceEditor.OnCodeBufferChanged] A ',FIgnoreCodeBufferLock,' ',SrcLogEntry<>nil);
{$ENDIF}
  if FIgnoreCodeBufferLock>0 then exit;
  if SrcLogEntry<>nil then begin
    FEditor.BeginUpdate;
    FEditor.BeginUndoBlock;
    case SrcLogEntry.Operation of
      sleoInsert:
        begin
          Sender.AbsoluteToLineCol(SrcLogEntry.Position,StartPos.Y,StartPos.X);
          if StartPos.Y>=1 then
            InsertTxt(StartPos,SrcLogEntry.Txt);
        end;
      sleoDelete:
        begin
          Sender.AbsoluteToLineCol(SrcLogEntry.Position,StartPos.Y,StartPos.X);
          Sender.AbsoluteToLineCol(SrcLogEntry.Position+SrcLogEntry.Len,
            EndPos.Y,EndPos.X);
          if (StartPos.Y>=1) and (EndPos.Y>=1) then
            DeleteTxt(StartPos,EndPos);
        end;
      sleoMove:
        begin
          Sender.AbsoluteToLineCol(SrcLogEntry.Position,StartPos.Y,StartPos.X);
          Sender.AbsoluteToLineCol(SrcLogEntry.Position+SrcLogEntry.Len,
            EndPos.Y,EndPos.X);
          Sender.AbsoluteToLineCol(SrcLogEntry.MoveTo,MoveToPos.Y,MoveToPos.X);
          if (StartPos.Y>=1) and (EndPos.Y>=1) and (MoveToPos.Y>=1) then
            MoveTxt(StartPos, EndPos, MoveToPos,
              SrcLogEntry.Position<SrcLogEntry.MoveTo);
        end;
    end;
    FEditor.EndUndoBlock;
    FEditor.EndUpdate;
  end else begin
    if Sender.IsEqual(FEditor.Lines) then exit;
    Sender.AssignTo(FEditor.Lines);
  end;
end;

procedure TSourceEditor.StartIdentCompletion(JumpToError: boolean);
var
  I: Integer;
  P: TPoint;
  TextS, TextS2: String;
  LogCaret: TPoint;
begin
  //debugln('TSourceEditor.StartIdentCompletion');
  if (FEditor.ReadOnly) or (CurrentCompletionType<>ctNone) then exit;
  SourceNoteBook.fIdentCompletionJumpToError:=JumpToError;
  
  CurrentCompletionType:=ctIdentCompletion;
  TextS := FEditor.LineText;
  LogCaret:=FEditor.LogicalCaretXY;
  i := LogCaret.X - 1;
  if i > length(TextS) then
    TextS2 := ''
  else begin
    while (i > 0) and (TextS[i] in ['a'..'z','A'..'Z','0'..'9','_']) do
      dec(i);
    TextS2 := Trim(copy(TextS, i + 1, LogCaret.X - i - 1));
  end;
  with FEditor do
    P := ClientToScreen(Point(CaretXPix - length(TextS2)*CharWidth
            ,CaretYPix + LineHeight));
  aCompletion.Editor:=FEditor;
  aCompletion.Execute(TextS2,P.X,P.Y);
end;

procedure TSourceEditor.IncreaseIgnoreCodeBufferLock;
begin
  inc(FIgnoreCodeBufferLock);
end;

procedure TSourceEditor.DecreaseIgnoreCodeBufferLock;
begin
  if FIgnoreCodeBufferLock<=0 then exit;
  dec(FIgnoreCodeBufferLock);
end;

procedure TSourceEditor.UpdateCodeBuffer;
// copy the source from EditorComponent
begin
  if not FEditor.Modified then exit;
  {$IFDEF IDE_DEBUG}
  if FCodeBuffer=nil then begin
    writeln('');
    writeln('*********** Oh, no: UpdateCodeBuffer ************');
    writeln('');
  end;
  {$ENDIF}
  if FCodeBuffer=nil then exit;
  IncreaseIgnoreCodeBufferLock;
  FModified:=FModified or FEditor.Modified;
  FCodeBuffer.Assign(FEditor.Lines);
  FEditor.Modified:=false;
  DecreaseIgnoreCodeBufferLock;
end;

Function TSourceEditor.GetSource: TStrings;
Begin
  //return synedit's source.
  Result := FEditor.Lines;
end;

procedure TSourceEditor.SetPageName(const AValue: string);
begin
  if FPageName=AValue then exit;
  FPageName:=AValue;
  UpdatePageName;
end;

procedure TSourceEditor.UpdatePageName;
var
  p: Integer;
  NewPageName: String;
begin
  p:=SourceNotebook.FindPageWithEditor(Self);
  NewPageName:=FPageName;
  if Modified then NewPageName:='*'+NewPageName;
  if SourceNotebook.NoteBook.Pages[p]<>NewPageName then
    SourceNotebook.NoteBook.Pages[p]:=NewPageName;
end;

Procedure TSourceEditor.SetSource(value: TStrings);
Begin
  FEditor.Lines.Assign(Value);
end;

Function TSourceEditor.GetCurrentCursorXLine: Integer;
Begin
  Result := FEditor.CaretX
end;

Procedure TSourceEditor.SetCurrentCursorXLine(num: Integer);
Begin
  FEditor.CaretX := Num;
end;

Function TSourceEditor.GetCurrentCursorYLine: Integer;
Begin
  Result := FEditor.CaretY;
end;

Procedure TSourceEditor.SetCurrentCursorYLine(num: Integer);
Begin
  FEditor.CaretY := Num;
end;

Procedure TSourceEditor.SelectText(LineNum,CharStart,LineNum2,CharEnd: Integer);
var
  P: TPoint;
Begin
  P.X := CharStart;
  P.Y := LineNum;
  FEditor.BlockBegin := P;
  P.X := CharEnd;
  P.Y := LineNum2;
  FEditor.BlockEnd := P;
end;

procedure TSourceEditor.ReplaceLines(StartLine, EndLine: integer;
  const NewText: string);
begin
  FEditor.BeginUndoBlock;
  FEditor.BlockBegin:=Point(1,StartLine);
  FEditor.BlockEnd:=Point(length(FEditor.Lines[Endline-1])+1,EndLine);
  FEditor.SelText:=NewText;
  FEditor.EndUndoBlock;
end;

procedure TSourceEditor.EncloseSelection;
var
  EncloseType: TEncloseSelectionType;
  EncloseTemplate: string;
  NewSelection: string;
  NewCaretXY: TPoint;
begin
  if ReadOnly then exit;
  if not FEditor.SelAvail then begin
    FEditor.BlockBegin:=FEditor.LogicalCaretXY;
    FEditor.BlockEnd:=FEditor.BlockBegin;
  end;
  if ShowEncloseSelectionDialog(EncloseType)<>mrOk then exit;
  GetEncloseSelectionParams(EncloseType,EncloseTemplate);
  EncloseTextSelection(EncloseTemplate,FEditor.Lines,
                       FEditor.BlockBegin,FEditor.BlockEnd,
                       FEditor.BlockIndent,
                       NewSelection,NewCaretXY);
  //writeln('TSourceEditor.EncloseSelection A NewCaretXY=',NewCaretXY.X,',',NewCaretXY.Y,
  //  ' "',NewSelection,'"');
  FEditor.SelText:=NewSelection;
  FEditor.LogicalCaretXY:=NewCaretXY;
end;

Function TSourceEditor.GetModified: Boolean;
Begin
  Result := FEditor.Modified or FModified;
end;

procedure TSourceEditor.SetModified(NewValue:boolean);
var
  OldModified: Boolean;
begin
  OldModified:=Modified;
  FModified:=NewValue;
  if not FModified then FEditor.Modified:=false;
  if OldModified<>Modified then
    UpdatePageName;
end;

Function TSourceEditor.GetInsertMode: Boolean;
Begin
  Result := FEditor.Insertmode;
end;

Function TSourceEditor.Close: Boolean;
Begin
  Result := True;
  If Assigned(FOnBeforeClose) then
    FOnBeforeClose(Self);

  Visible := False;
  aCompletion.RemoveEditor(FEditor);
  SourceEditorMarks.DeleteAllForEditor(FEditor);
  FEditor.Parent:=nil;
  CodeBuffer := nil;
  If Assigned(FOnAfterClose) then FOnAfterClose(Self);
end;

Procedure TSourceEditor.ReParent(AParent: TWInControl);
Begin
  CreateEditor(FAOwner,AParent);
End;

procedure TSourceEditor.SetCodeTemplates(
  NewCodeTemplates: TSynEditAutoComplete);
begin
  if NewCodeTemplates<>FCodeTemplates then begin
    if FCodeTemplates<>nil then
      FCodeTemplates.RemoveEditor(FEditor);
    if NewCodeTemplates<>nil then
      NewCodeTemplates.AddEditor(FEditor);
  end;
end;

procedure TSourceEditor.SetPopupMenu(NewPopupMenu: TPopupMenu);
begin
  if NewPopupMenu<>FPopupMenu then begin
    FPopupMenu:=NewPopupMenu;
    if FEditor<>nil then FEditor.PopupMenu:=NewPopupMenu;
  end;
end;

function TSourceEditor.GetFilename: string;
begin
  if FCodeBuffer<>nil then
    Result:=FCodeBuffer.Filename
  else
    Result:='';
end;

Procedure TSourceEditor.EditorMouseMoved(Sender: TObject;
  Shift: TShiftState; X,Y: Integer);
begin
//  Writeln('MouseMove in Editor',X,',',Y);
  if Assigned(OnMouseMove) then
    OnMouseMove(Self,Shift,X,Y);
end;

Function TSourceEditor.GetWordAtPosition(Position: TPoint): String;
var
  CaretPos: TPoint;
begin
  Result := '';
  Caretpos := GetCaretPosfromCursorPos(Position);
  Result := GetWordFromCaret(CaretPos);
end;

Procedure TSourceEditor.EditorMouseDown(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(OnMouseDown) then
    OnMouseDown(Sender, Button, Shift, X,Y);
end;

procedure TSourceEditor.EditorMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(OnMouseUp) then
    OnMouseUp(Sender, Button, Shift, X,Y);
end;

Procedure TSourceEditor.EditorKeyDown(Sender: TObject; var Key: Word; Shift :
  TShiftState);
begin
  DebugLn('TSourceEditor.EditorKeyDown A ',TComponent(Sender).Name,
    ':',ClassName,' ',IntToStr(Key));
  if Assigned(OnKeyDown) then
    OnKeyDown(Sender, Key, Shift);
end;

Function TSourceEditor.GetCaretPosFromCursorPos(CursorPos: TPoint): TPoint;
var
  TopLine: Integer;
  LineHeight: Integer;
  LineNum: Integer;
  XLine: Integer;
begin
  //Figure out the line number
  TopLine := FEditor.TopLine;
  LineHeight := FEditor.LineHeight;
  if CursorPos.Y > 1 then
    LineNum := CursorPos.Y div LineHeight
  else
    LineNum := 1;
  LineNum := LineNum + (TopLine);
  XLine := CursorPos.X div FEditor.CharWidth;
  if XLine = 0 then inc(XLine);

  Result.X := XLine;
  Result.Y := LineNum;
end;

{-------------------------------------------------------------------------------
  method TSourceEditor.CenterCursor
  Params: none
  Result: none

  Center the current cursor line in editor.
-------------------------------------------------------------------------------}
procedure TSourceEditor.CenterCursor;
var NewTopLine: integer;
begin
  NewTopLine:=EditorComponent.CaretY-((EditorComponent.LinesInWindow-1) div 2);
  if NewTopLine<1 then NewTopLine:=1;
  EditorComponent.TopLine:=NewTopLine;
end;

procedure TSourceEditor.Activate;
begin
  if (FSourceNoteBook=nil) then exit;
  FSourceNoteBook.SetActiveSE(Self);
end;

function TSourceEditor.PageIndex: integer;
begin
  if FSourceNoteBook<>nil then
    Result:=FSourceNoteBook.FindPageWithEditor(Self)
  else
    Result:=-1;
end;

function TSourceEditor.CaretInSelection(const ACaretPos: TPoint): Boolean;
begin
  Result := (CompareCaret(EditorComponent.BlockBegin, ACaretpos) >= 0)
        and (CompareCaret(ACaretPos, EditorComponent.BlockEnd) >= 0);
end;

function TSourceEditor.PositionInSelection(const APosition: TPoint): Boolean;
begin
  Result := CaretInSelection(GetCaretPosfromCursorPos(APosition));
end;

function TSourceEditor.IsActiveOnNoteBook: boolean;
begin
  if FSourceNoteBook<>nil then
    Result:=(FSourceNoteBook.GetActiveSE=Self)
  else
    Result:=false;
end;

Function TSourceEditor.GetWordAtCurrentCaret: String;
var
  CaretPos: TPoint;
begin
  Result := '';
  CaretPos.Y := CurrentCursorYLine;
  CaretPos.X := CurrentCursorXLine;
  Result := GetWordFromCaret(CaretPos);
end;

function TSourceEditor.GetWordFromCaret(const ACaretPos: TPoint): String;
begin
  Result := GetWordFromCaretEx(ACaretPos, ['A'..'Z', 'a'..'z', '0'..'9','_'], ['A'..'Z', 'a'..'z', '0'..'9', '_']);
end;

function TSourceEditor.GetWordFromCaretEx(const ACaretPos: TPoint; const ALeftLimit, ARightLimit: TCharSet): String;
var
  XLine,YLine: Integer;
  EditorLine: String;
begin
  Result := '';

  YLine := ACaretPos.Y;
  XLine := ACaretPos.X;
  EditorLine := FEditor.Lines[YLine-1];

  if Length(trim(EditorLine)) = 0 then Exit;
  if XLine > Length(EditorLine) then Exit;
  if not (EditorLine[XLine] in ALeftLimit) then Exit;

  //walk backwards to a space or non-standard character.
  while (XLine > 1) and (EditorLine[XLine - 1] in ALeftLimit) do Dec(XLine);

  //chop off the beginning
  Result := Copy(EditorLine, XLine, Length(EditorLine));

  //start forward search
  XLine := ACaretPos.X - XLine + 1;

  while (XLine <= Length(Result)) and (Result[XLine] in ARightLimit) do Inc(Xline);

  // Strip remainder
  SetLength(Result, XLine - 1);
end;

procedure TSourceEditor.LinesDeleted(sender: TObject; FirstLine,
  Count: Integer);
begin
  //notify the notebook that lines were deleted.
  //marks will use this to update themselves
end;

procedure TSourceEditor.LinesInserted(sender: TObject; FirstLine,
  Count: Integer);
begin
  //notify the notebook that lines were Inserted.
  //marks will use this to update themselves
end;

procedure TSourceEditor.SetVisible(Value: boolean);
begin
  if FVisible=Value then exit;
  if FEditor<>nil then FEditor.Visible:=Value;
  FVisible:=Value;
end;

procedure TSourceEditor.DoEditorExecuteCommand(EditorCommand: integer);
begin
  EditorComponent.CommandProcessor(TSynEditorCommand(EditorCommand),' ',nil);
end;

{------------------------------------------------------------------------}
                      { TSourceNotebook }

constructor TSourceNotebook.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Visible:=false;
  Name:=NonModalIDEWindowNames[nmiwSourceNoteBookName];
  Caption := locWndSrcEditor;
  KeyPreview:=true;
  FProcessingCommand := false;

  EnvironmentOptions.IDEWindowLayoutList.Apply(Self,Name);

  FSourceEditorList := TList.Create;
  FUnUsedEditorComponents := TList.Create;

  // code templates
  FCodeTemplateModul:=TSynEditAutoComplete.Create(Self);
  with FCodeTemplateModul do begin
    if FileExists(EditorOpts.CodeTemplateFilename) then
      AutoCompleteList.LoadFromFile(EditorOpts.CodeTemplateFilename)
    else
      if FileExists('lazarus.dci') then
        AutoCompleteList.LoadFromFile('lazarus.dci');
    IndentToTokenStart:=EditorOpts.CodeTemplateIndentToTokenStart;
    OnTokenNotFound:=@OnCodeTemplateTokenNotFound;
    EndOfTokenChr:=' ()[]{},.;:"+-*^@$\<>=''';
  end;

  // word completion
  if aWordCompletion=nil then begin
    aWordCompletion:=TWordCompletion.Create;
    with AWordCompletion do begin
      WordBufferCapacity:=100;
      OnGetSource:=@OnWordCompletionGetSource;
    end;
  end;

  // identifier completion
  IdentCompletionTimer := TIdleTimer.Create(Self);
  with IdentCompletionTimer do begin
    AutoEnabled := False;
    Enabled := false;
    Interval := EditorOpts.AutoDelayInMSec;
    OnTimer := @OnIdentCompletionTimer;
  end;
  

  // marks
  SourceEditorMarks:=TSourceMarks.Create(Self);
  SourceEditorMarks.OnGetSourceEditor:=@OnSourceMarksGetSourceEditor;
  SourceEditorMarks.OnGetFilename:=@OnSourceMarksGetFilename;

  // key mapping
  FKeyStrokes:=TSynEditKeyStrokes.Create(Self);
  EditorOpts.KeyMap.AssignTo(FKeyStrokes,[caSourceEditor]);

  // popup menu
  BuildPopupMenu;

  // completion form
  aCompletion := TSynCompletion.Create(nil);
    with aCompletion do
      Begin
        EndOfTokenChr:='()[].,;:-+=^*<>/';
        Width:=400;
        OnExecute := @ccExecute;
        OnCancel := @ccCancel;
        OnCodeCompletion := @ccComplete;
        OnPaintItem:=@OnSynCompletionPaintItem;
        OnSearchPosition:=@OnSynCompletionSearchPosition;
        OnKeyCompletePrefix:=@OnSynCompletionCompletePrefix;
        OnKeyNextChar:=@OnSynCompletionNextChar;
        OnKeyPrevChar:=@OnSynCompletionPrevChar;
        OnKeyPress:=@OnSynCompletionKeyPress;
        ShortCut:=Menus.ShortCut(VK_UNKNOWN,[]);
      end;

  // statusbar
  StatusBar := TStatusBar.Create(self);
    with Statusbar do
      begin
       Parent := Self;
       Name := 'StatusBar';
       Visible := True;
       SimpleText := 'This is a test';
       Panels.Add;       //x,y coord
       Panels.Add;       //Readonly/Modified
       Panels.Add;       //OVR/INS
       Panels.Add;       //Unitname
       Panels[0].Text := '';
       Panels[0].Width := 100;
       Panels[0].Bevel := pbLowered;
       Panels[1].Text := '';
       Panels[1].Bevel := pbLowered;
       Panels[1].Width := 150;
       Panels[2].Text := '';
       Panels[2].Bevel := pbLowered;
       Panels[2].Width := 50;
       Panels[3].Text := 'INS';
       Panels[3].Bevel := pbLowered;
       Panels[3].Width := 50;
       SimplePanel := False;
      end;

  // goto dialog
  GotoDialog := TfrmGoto.Create(self);

  // HintTimer
  FHintTimer := TTimer.Create(nil);
  with FHintTimer do begin
    Interval := 500;
    Enabled := False;
    OnTimer := @HintTimer;
  end;

  // HintWindow
  FHintWindow := THintWindow.Create(nil);
  with FHintWindow do begin
    Visible := False;
    Caption := '';
    HideInterval := 4000;
    AutoHide := False;
  end;

  Application.AddOnUserInputHandler(@OnApplicationUserInput,true);
end;

destructor TSourceNotebook.Destroy;
var
  i: integer;
begin
  {$IFDEF UseMenuIntf}
  SourceEditorMenuRoot.MenuItem:=nil;
  {$ENDIF}

  FProcessingCommand:=false;
  for i:=FSourceEditorList.Count-1 downto 0 do
    Editors[i].Free;
  ClearUnUsedEditorComponents(true);
  FUnUsedEditorComponents.Free;
  if Notebook<>nil then begin
    FreeThenNil(Notebook);
  end;
  FKeyStrokes.Free;
  FCodeTemplateModul.Free;
  FSourceEditorList.Free;
  Gotodialog.free;

  FreeThenNil(aCompletion);
  FreeThenNil(FHintTimer);
  FreeThenNil(FHintWindow);
  FreeThenNil(fCustomPopupMenuItems);
  FreeThenNil(fContextPopupMenuItems);

  inherited Destroy;
end;

function TSourceNotebook.OnSynCompletionPaintItem(const AKey: string;
  ACanvas: TCanvas;  X, Y: integer; ItemSelected: boolean;
  Index: integer): boolean;
var
  MaxX: Integer;
begin
  with ACanvas do begin
    if (aCompletion<>nil) and (aCompletion.Editor<>nil) then
      Font:=aCompletion.Editor.Font
    else begin
      Font.Height:=EditorOpts.EditorFontHeight; // set Height before name for XLFD !
      Font.Name:=EditorOpts.EditorFont;
    end;
    Font.Style:=[];
    if not ItemSelected then
      Font.Color:=FActiveEditDefaultFGColor
    else
      Font.Color:=FActiveEditSelectedFGColor;
  end;
  MaxX:=aCompletion.TheForm.ClientWidth;
  PaintCompletionItem(AKey,ACanvas,X,Y,MaxX,ItemSelected,Index,aCompletion,
                      CurrentCompletionType);
  Result:=true;
end;

procedure TSourceNotebook.OnWordCompletionGetSource(var Source: TStrings;
  SourceIndex: integer);
var TempEditor: TSourceEditor;
  i:integer;
begin
  TempEditor:=GetActiveSE;
  if SourceIndex=0 then begin
    Source:=TempEditor.EditorComponent.Lines;
  end else begin
    i:=0;
    while (i<FSourceEditorList.Count) do begin
      if Editors[i]<>TempEditor then dec(SourceIndex);
      if SourceIndex=0 then begin
        Source:=Editors[i].EditorComponent.Lines;
        exit;
      end;
      inc(i);
    end;
    Source:=nil;
  end;
end;

procedure TSourceNotebook.OnIdentCompletionTimer(Sender: TObject);
var
  TempEditor: TSourceEditor;
begin
  //debugln('TSourceNotebook.OnIdentCompletionTimer');
  IdentCompletionTimer.Enabled:=false;
  IdentCompletionTimer.AutoEnabled:=false;
  TempEditor:=GetActiveSE;
  if TempEditor<>nil then TempEditor.StartIdentCompletion(false);
end;

procedure TSourceNotebook.OnCodeTemplateTokenNotFound(Sender: TObject;
  AToken: string; AnEditor: TCustomSynEdit; var Index:integer);
var P:TPoint;
begin
  //writeln('TSourceNotebook.OnCodeTemplateTokenNotFound ',AToken,',',AnEditor.ReadOnly,',',CurrentCompletionType=ctNone);
  if (AnEditor.ReadOnly=false) and (CurrentCompletionType=ctNone) then begin
    CurrentCompletionType:=ctTemplateCompletion;
    with AnEditor do
      P := ClientToScreen(Point(CaretXPix,CaretYPix+LineHeight));
    aCompletion.Editor:=AnEditor;
    aCompletion.Execute(AToken,P.X,P.Y);
  end;
end;

procedure TSourceNotebook.OnSynCompletionSearchPosition(var APosition:integer);
// word changed
var
  i,x:integer;
  CurStr,s:Ansistring;
  SL:TStringList;
  ItemCnt: Integer;
begin
  if CurCompletionControl=nil then exit;
  case CurrentCompletionType of

    ctIdentCompletion:
      begin
        // rebuild completion list
        APosition:=0;
        CurStr:=CurCompletionControl.CurrentString;
        CodeToolBoss.IdentifierList.Prefix:=CurStr;
        ItemCnt:=CodeToolBoss.IdentifierList.GetFilteredCount;
        SL:=TStringList.Create;
        try
          for i:=0 to ItemCnt-1 do
            SL.Add('Dummy'); // these entries are not shown
          CurCompletionControl.ItemList:=SL;
        finally
          SL.Free;
        end;
      end;

    ctTemplateCompletion:
      begin
        // search CurrentString in bold words (words after #3'B')
        CurStr:=CurCompletionControl.CurrentString;
        i:=0;
        while i<CurCompletionControl.ItemList.Count do begin
          s:=CurCompletionControl.ItemList[i];
          x:=1;
          while (x<=length(s)) and (s[x]<>#3) do inc(x);
          if x<length(s) then begin
            inc(x,2);
            if AnsiCompareText(CurStr,copy(s,x,length(CurStr)))=0 then begin
              APosition:=i;
              break;
            end;
          end;
          inc(i);
        end;
      end;

    ctWordCompletion:
      begin
        // rebuild completion list
        APosition:=0;
        CurStr:=CurCompletionControl.CurrentString;
        SL:=TStringList.Create;
        try
          aWordCompletion.GetWordList(SL, CurStr, false, 100);
          CurCompletionControl.ItemList:=SL;
        finally
          SL.Free;
        end;
      end;

  end;
end;

procedure TSourceNotebook.OnSynCompletionCompletePrefix(Sender: TObject);
var
  OldPrefix: String;
  NewPrefix: String;
  SL: TStringList;
  AddPrefix: String;
begin
  if CurCompletionControl=nil then exit;
  OldPrefix:=CurCompletionControl.CurrentString;
  NewPrefix:=OldPrefix;

  case CurrentCompletionType of

  ctIdentCompletion:
    begin
      NewPrefix:=CodeToolBoss.IdentifierList.CompletePrefix(OldPrefix);
    end;

  ctWordCompletion:
    begin
      aWordCompletion.CompletePrefix(OldPrefix,NewPrefix,false);
    end;

  end;

  if NewPrefix<>OldPrefix then begin
    AddPrefix:=copy(NewPrefix,length(OldPrefix)+1,length(NewPrefix));
    CurCompletionControl.Editor.SelText:=AddPrefix;
    CurCompletionControl.Editor.LogicalCaretXY:=
      CurCompletionControl.Editor.BlockBegin;
    if CurrentCompletionType=ctWordCompletion then begin
      SL:=TStringList.Create;
      try
        aWordCompletion.GetWordList(SL, NewPrefix, false, 100);
        CurCompletionControl.ItemList:=SL;
      finally
        SL.Free;
      end;
    end;
    CurCompletionControl.CurrentString:=NewPrefix;
  end;
end;

procedure TSourceNotebook.OnSynCompletionNextChar(Sender: TObject);
var
  NewPrefix: String;
  SrcEdit: TSourceEditor;
  Line: String;
  Editor: TSynEdit;
  LogCaret: TPoint;
  CharLen: LongInt;
  AddPrefix: String;
begin
  if CurCompletionControl=nil then exit;
  SrcEdit:=GetActiveSE;
  if SrcEdit=nil then exit;
  Editor:=SrcEdit.EditorComponent;
  LogCaret:=Editor.LogicalCaretXY;
  if LogCaret.Y>=Editor.Lines.Count then exit;
  Line:=SrcEdit.EditorComponent.Lines[LogCaret.Y-1];
  if LogCaret.X>length(Line) then exit;
  CharLen:=UTF8CharacterLength(@Line[LogCaret.X]);
  AddPrefix:=copy(Line,LogCaret.X,CharLen);
  NewPrefix:=CurCompletionControl.CurrentString+AddPrefix;
  //debugln('TSourceNotebook.OnSynCompletionNextChar NewPrefix="',NewPrefix,'" LogCaret.X=',dbgs(LogCaret.X));
  inc(LogCaret.X);
  CurCompletionControl.Editor.LogicalCaretXY:=LogCaret;
  CurCompletionControl.CurrentString:=NewPrefix;
end;

procedure TSourceNotebook.OnSynCompletionPrevChar(Sender: TObject);
var
  NewPrefix: String;
  SrcEdit: TSourceEditor;
  Editor: TSynEdit;
  NewLen: LongInt;
begin
  if CurCompletionControl=nil then exit;
  NewPrefix:=CurCompletionControl.CurrentString;
  if NewPrefix='' then exit;
  SrcEdit:=GetActiveSE;
  if SrcEdit=nil then exit;
  Editor:=SrcEdit.EditorComponent;
  Editor.CaretX:=Editor.CaretX-1;
  NewLen:=UTF8FindNearestCharStart(PChar(NewPrefix),length(NewPrefix),
                                   length(NewPrefix))-1;
  NewPrefix:=copy(NewPrefix,1,NewLen);
  CurCompletionControl.CurrentString:=NewPrefix;
end;

procedure TSourceNotebook.OnSynCompletionKeyPress(Sender: TObject;
  var Key: Char);
begin
  if CurCompletionControl=nil then exit;
  if (System.Pos(Key,CurCompletionControl.EndOfTokenChr)>0) then begin
    // identifier completed
    //debugln('TSourceNotebook.OnSynCompletionKeyPress A');
    CurCompletionControl.TheForm.OnValidate(Sender,[]);
    //debugln('TSourceNotebook.OnSynCompletionKeyPress B');
  end;
end;

procedure TSourceNotebook.DeactivateCompletionForm;
var ActSE: TSourceEditor;
begin
  CurCompletionControl.Deactivate;
  CurCompletionControl:=nil;
  CurrentCompletionType:=ctNone;
  ActSE:=GetActiveSE;
  if ActSE<>nil then begin
    LCLIntf.ShowCaret(ActSE.EditorComponent.Handle);
    ActSE.EditorComponent.SetFocus;
  end;
end;

procedure TSourceNotebook.InitIdentCompletion(S: TStrings);
var
  i: integer;
  Handled: boolean;
  Abort: boolean;
  Prefix: string;
  ItemCnt: Integer;
begin
  Prefix := CurCompletionControl.CurrentString;
  if Assigned(OnInitIdentCompletion) then begin
    OnInitIdentCompletion(Self,fIdentCompletionJumpToError,Handled,Abort);
    if Handled then begin
      if Abort then exit;
      // add one entry per item
      CodeToolBoss.IdentifierList.Prefix:=Prefix;
      ItemCnt:=CodeToolBoss.IdentifierList.GetFilteredCount;
      DebugLn('InitIdentCompletion B Prefix=',Prefix,' ItemCnt=',IntToStr(ItemCnt));
      CurCompletionControl.Position:=0;
      for i:=0 to ItemCnt-1 do
        s.Add('Dummy');
      exit;
    end;
  end;
end;

procedure TSourceNotebook.ccComplete(var Value: ansistring; Shift: TShiftState);
// completion selected -> deactivate completion form
// Called when user has selected a completion item

  function CharBehindIdent(const Line: string; StartPos: integer): char;
  begin
    while (StartPos<=length(Line))
    and (Line[StartPos] in ['_','A'..'Z','a'..'z']) do
      inc(StartPos);
    while (StartPos<=length(Line)) and (Line[StartPos] in [' ',#9]) do
      inc(StartPos);
    if StartPos<=length(Line) then
      Result:=Line[StartPos]
    else
      Result:=#0;
  end;

  function CharInFrontOfIdent(const Line: string; StartPos: integer): char;
  begin
    while (StartPos>=1)
    and (Line[StartPos] in ['_','A'..'Z','a'..'z']) do
      dec(StartPos);
    while (StartPos>=1) and (Line[StartPos] in [' ',#9]) do
      dec(StartPos);
    if StartPos>=1 then
      Result:=Line[StartPos]
    else
      Result:=#0;
  end;

var
  p1, p2: integer;
  ValueType: TIdentComplValue;
  SrcEdit: TSourceEditor;
  NewCaretXY: TPoint;
  CursorToLeft: integer;
  NewValue: String;
  Editor: TSynEdit;
Begin
  if CurCompletionControl=nil then exit;
  case CurrentCompletionType of

    ctIdentCompletion:
      begin
        // add to history
        CodeToolBoss.IdentifierHistory.Add(
          CodeToolBoss.IdentifierList.FilteredItems[aCompletion.Position]);
        // get value
        NewValue:=GetIdentCompletionValue(aCompletion,ValueType,CursorToLeft);
        // insert value plus special chars like brackets, semicolons, ...
        SrcEdit:=GetActiveSE;
        Editor:=SrcEdit.EditorComponent;
        Editor.SelText:=NewValue;
        if CursorToLeft>0 then
        begin
          NewCaretXY:=Editor.LogicalToPhysicalPos(Editor.BlockEnd);
          dec(NewCaretXY.X,CursorToLeft);
          Editor.CaretXY:=NewCaretXY;
        end;
        ccSelection := '';
        Value:='';
      end;

    ctTemplateCompletion:
      begin
        // the completion is the bold text between #3'B' and #3'b'
        p1:=Pos(#3,Value);
        if p1>=0 then begin
          p2:=p1+2;
          while (p2<=length(Value)) and (Value[p2]<>#3) do inc(p2);
          Value:=copy(Value,p1+2,p2-p1-2);
          // keep parent identifier (in front of '.')
          p1:=length(ccSelection);
          while (p1>=1) and (ccSelection[p1]<>'.') do dec(p1);
          if p1>=1 then
            Value:=copy(ccSelection,1,p1)+Value;
        end;
        ccSelection := '';
        if Value<>'' then
          FCodeTemplateModul.ExecuteCompletion(Value,
                                               GetActiveSE.EditorComponent);
        Value:='';
      end;

    ctWordCompletion:
      // the completion is already in Value
      begin
        ccSelection := '';
        if Value<>'' then AWordCompletion.AddWord(Value);
      end;
  end;

  DeactivateCompletionForm;
End;

Procedure TSourceNotebook.ccCancel(Sender: TObject);
// user cancels completion form
begin
  if CurCompletionControl=nil then exit;
  DeactivateCompletionForm;
end;

Procedure TSourceNotebook.ccExecute(Sender: TObject);
// init completion form
// called by aCompletion.OnExecute just before showing
var
  S: TStrings;
  Prefix: String;
  I: Integer;
  NewStr: String;
  ActiveEditor: TSynEdit;
Begin
  CurCompletionControl := Sender as TSynCompletion;
  S := TStringList.Create;
  Prefix := CurCompletionControl.CurrentString;
  ActiveEditor:=GetActiveSE.EditorComponent;
  case CurrentCompletionType of
   ctIdentCompletion:
     InitIdentCompletion(S);

   ctWordCompletion:
     begin
       ccSelection:='';
     end;

   ctTemplateCompletion:
     begin
       ccSelection:='';
       for I:=0 to FCodeTemplateModul.Completions.Count-1 do begin
         NewStr:=FCodeTemplateModul.Completions[I];
         if NewStr<>'' then begin
           NewStr:=#3'B'+NewStr+#3'b';
           while length(NewStr)<10+4 do NewStr:=NewStr+' ';
           NewStr:=NewStr+' '+FCodeTemplateModul.CompletionComments[I];
           S.Add(NewStr);
         end;
       end;
     end;

  end;

  CurCompletionControl.ItemList := S;
  S.Free;
  CurCompletionControl.CurrentString:=Prefix;
  // set colors
  if (ActiveEditor<>nil) and (CurCompletionControl.TheForm<>nil) then begin
    with CurCompletionControl.TheForm do begin
      BackgroundColor:=FActiveEditDefaultBGColor;
      clSelect:=FActiveEditSelectedBGColor;
      TextColor:=FActiveEditDefaultFGColor;
      TextSelectedColor:=FActiveEditSelectedFGColor;
      //writeln('TSourceNotebook.ccExecute A Color=',DbgS(Color),
      // ' clSelect=',DbgS(clSelect),
      // ' TextColor=',DbgS(TextColor),
      // ' TextSelectedColor=',DbgS(TextSelectedColor),
      // '');
    end;
  end;
End;

Function TSourceNotebook.CreateNotebook: Boolean;
Begin
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.CreateNotebook] START');
  {$ENDIF}
  {$IFDEF IDE_MEM_CHECK}
  CheckHeapWrtMemCnt('[TSourceNotebook.CreateNotebook] A ');
  {$ENDIF}
  ClearUnUsedEditorComponents(false);
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.CreateNotebook] A');
  {$ENDIF}
  {$IFDEF IDE_MEM_CHECK}
  CheckHeapWrtMemCnt('[TSourceNotebook.CreateNotebook] B ');
  {$ENDIF}
  Result := False;
  if not assigned(Notebook) then
    Begin
      Result := True;
      {$IFDEF IDE_DEBUG}
      writeln('[TSourceNotebook.CreateNotebook] B');
      {$ENDIF}
      Notebook := TNotebook.Create(self);
      {$IFDEF IDE_DEBUG}
      writeln('[TSourceNotebook.CreateNotebook] C');
      {$ENDIF}
      {$IFDEF IDE_MEM_CHECK}
      CheckHeapWrtMemCnt('[TSourceNotebook.CreateNotebook] C ');
      {$ENDIF}
      with Notebook do
        Begin
          Name:='SrcEditNotebook';
          Parent := Self;
          {$IFDEF IDE_DEBUG}
          writeln('[TSourceNotebook.CreateNotebook] D');
          {$ENDIF}
          Align := alClient;
          if PageCount>0 then
            Pages.Strings[0] := 'unit1'
          else
            Pages.Add('unit1');
          PageIndex := 0;   // Set it to the first page
          if EditorOpts.ShowTabCloseButtons then
            Options:=Options+[nboShowCloseButtons]
          else
            Options:=Options-[nboShowCloseButtons];
          OnPageChanged := @NotebookPageChanged;
          OnCloseTabClicked:=@CloseClicked;
          ShowHint:=true;
          OnShowHint:=@NotebookShowTabHint;
          {$IFDEF IDE_DEBUG}
          writeln('[TSourceNotebook.CreateNotebook] E');
          {$ENDIF}
          Visible := true;
          {$IFDEF IDE_DEBUG}
          writeln('[TSourceNotebook.CreateNotebook] F');
          {$ENDIF}
          {$IFDEF IDE_MEM_CHECK}
          CheckHeapWrtMemCnt('[TSourceNotebook.CreateNotebook] F ');
          {$ENDIF}
        end; //with
      Show;  //used to display the code form
    end;
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.CreateNotebook] END');
  {$ENDIF}
  {$IFDEF IDE_MEM_CHECK}
  CheckHeapWrtMemCnt('[TSourceNotebook.CreateNotebook] END ');
  {$ENDIF}
End;

Procedure TSourceNotebook.ClearUnUsedEditorComponents(Force: boolean);
var i:integer;
begin
  if (not Force) and FProcessingCommand then exit;
  for i:=FUnUsedEditorComponents.Count-1 downto 0 do
    TSynEdit(FUnUsedEditorComponents[i]).Free;
  FUnUsedEditorComponents.Clear;
end;

procedure TSourceNotebook.EditorPropertiesClicked(Sender: TObject);
begin
  if Assigned(FOnEditorPropertiesClicked) then
    FOnEditorPropertiesClicked(Sender);
end;

procedure TSourceNotebook.SrcPopUpMenuPopup(Sender: TObject);
{$IFDEF UseMenuIntf}
var
  ASrcEdit: TSourceEditor;
  BookMarkID, BookMarkX, BookMarkY: integer;
  MarkSrcEdit: TSourceEditor;
  MarkDesc: String;
  MarkEditorIndex: Integer;
  MarkMenuItem: TMenuItem;
  EditorComp: TSynEdit;
  Marks: PSourceMark;
  MarkCount: integer;
  i: Integer;
  CurMark: TSourceMark;
  EditorPopupPoint: TPoint;
  SelAvail: Boolean;
  SelAvailAndWritable: Boolean;
  CurFilename: String;
begin
  //RemoveUserDefinedMenuItems;
  //RemoveContextMenuItems;

  ASrcEdit:=
         FindSourceEditorWithEditorComponent(TPopupMenu(Sender).PopupComponent);
  if ASrcEdit=nil then exit;
  EditorComp:=ASrcEdit.EditorComponent;

  // readonly
  SrcEditMenuReadOnly.MenuItem.Checked:=ASrcEdit.ReadOnly;
  SrcEditMenuShowLineNumbers.MenuItem.Checked:=EditorComp.Gutter.ShowLineNumbers;

  // bookmarks
  for BookMarkID:=0 to 9 do begin
    MarkDesc:=' '+IntToStr(BookMarkID);
    MarkSrcEdit:=FindBookmark(BookMarkID);
    if (MarkSrcEdit<>nil)
    and MarkSrcEdit.EditorComponent.GetBookMark(BookMarkID,BookMarkX,BookMarkY)
    then begin
      MarkEditorIndex:=FindPageWithEditor(MarkSrcEdit);
      MarkDesc:=MarkDesc+': '+Notebook.Pages[MarkEditorIndex]
        +' ('+IntToStr(BookMarkY)+','+IntToStr(BookMarkX)+')';
    end;
    // goto book mark item
    MarkMenuItem:=SrcEditSubMenuGotoBookmarks.MenuItem[BookMarkID];
    MarkMenuItem.Checked:=(MarkSrcEdit<>nil);
    MarkMenuItem.Caption:=uemBookmarkN+MarkDesc;
    // set book mark item
    MarkMenuItem:=SrcEditSubMenuSetBookmarks.MenuItem[BookMarkID];
    MarkMenuItem.Checked:=(MarkSrcEdit<>nil);
    MarkMenuItem.Caption:=uemSetBookmark+MarkDesc;
  end;

  // editor layout
  SrcEditMenuMoveEditorLeft.MenuItem.Enabled:=
                                     (NoteBook<>nil) and (NoteBook.PageCount>1);
  SrcEditMenuMoveEditorRight.MenuItem.Enabled:=
                                     (NoteBook<>nil) and (NoteBook.PageCount>1);

  EditorPopupPoint:=EditorComp.ScreenToClient(SrcPopUpMenu.PopupPoint);
  if EditorPopupPoint.X>EditorComp.Gutter.Width then begin
    // user clicked on text
    SelAvail:=ASrcEdit.EditorComponent.SelAvail;
    SelAvailAndWritable:=SelAvail and (not ASrcEdit.ReadOnly);
    SrcEditMenuEncloseSelection.MenuItem.Enabled := SelAvailAndWritable;
    SrcEditMenuExtractProc.MenuItem.Enabled := SelAvailAndWritable;
    SrcEditMenuInvertAssignment.MenuItem.Enabled := SelAvailAndWritable;
    SrcEditMenuFindIdentifierReferences.MenuItem.Enabled:=
                                   IsValidIdent(ASrcEdit.GetWordAtCurrentCaret);
    SrcEditMenuRenameIdentifier.MenuItem.Enabled:=
                                   IsValidIdent(ASrcEdit.GetWordAtCurrentCaret)
                                   and (not ASrcEdit.ReadOnly);
  end else begin
    // user clicked on gutter
    SourceEditorMarks.GetMarksForLine(EditorComp,EditorComp.CaretY,
                                      Marks,MarkCount);
    if Marks<>nil then begin
      for i:=0 to MarkCount-1 do begin
        CurMark:=Marks[i];
        //CurMark.CreatePopupMenuItems(@AddUserDefinedPopupMenuItem);
      end;
      FreeMem(Marks);
    end;
  end;

  // add context specific menu items
  {CurFilename:=ASrcEdit.FileName;
  if FilenameIsPascalUnit(CurFilename)
  and (FilenameIsAbsolute(CurFilename)) then begin
    if FileExists(ChangeFileExt(CurFilename,'.lfm')) then
      AddContextPopupMenuItem(
        'Open '+ChangeFileExt(ExtractFileName(CurFilename),'.lfm'),
        true,@OnPopupMenuOpenLFMFile);
    if FileExists(ChangeFileExt(CurFilename,'.lrs')) then
      AddContextPopupMenuItem(
        'Open '+ChangeFileExt(ExtractFileName(CurFilename),'.lrs'),
        true,@OnPopupMenuOpenLRSFile);
  end;
  if (CompareFileExt(CurFilename,'.lfm',true)=0)
  and (FilenameIsAbsolute(CurFilename)) then begin
    if FileExists(ChangeFileExt(CurFilename,'.pas')) then
      AddContextPopupMenuItem(
        'Open '+ChangeFileExt(ExtractFileName(CurFilename),'.pas'),
        true,@OnPopupMenuOpenPasFile);
    if FileExists(ChangeFileExt(CurFilename,'.pp')) then
      AddContextPopupMenuItem(
        'Open '+ChangeFileExt(ExtractFileName(CurFilename),'.pp'),
        true,@OnPopupMenuOpenPPFile);
  end;}

  //if Assigned(OnPopupMenu) then OnPopupMenu(@AddContextPopupMenuItem);
end;
{$ELSE}
var
  ASrcEdit: TSourceEditor;
  BookMarkID, BookMarkX, BookMarkY: integer;
  MarkSrcEdit: TSourceEditor;
  MarkDesc: String;
  MarkEditorIndex: Integer;
  MarkMenuItem: TMenuItem;
  EditorComp: TSynEdit;
  Marks: PSourceMark;
  MarkCount: integer;
  i: Integer;
  CurMark: TSourceMark;
  EditorPopupPoint: TPoint;
  SelAvail: Boolean;
  SelAvailAndWritable: Boolean;
  CurFilename: String;
begin
  if not (Sender is TPopupMenu) then exit;

  RemoveUserDefinedMenuItems;
  RemoveContextMenuItems;

  ASrcEdit:=
    FindSourceEditorWithEditorComponent(TPopupMenu(Sender).PopupComponent);
  if ASrcEdit=nil then exit;
  EditorComp:=ASrcEdit.EditorComponent;

  // readonly
  ReadOnlyMenuItem.Checked:=ASrcEdit.ReadOnly;
  ShowLineNumbersMenuItem.Checked:=EditorComp.Gutter.ShowLineNumbers;

  // bookmarks
  for BookMarkID:=0 to 9 do begin
    MarkDesc:=' '+IntToStr(BookMarkID);
    MarkSrcEdit:=FindBookmark(BookMarkID);
    if (MarkSrcEdit<>nil)
    and MarkSrcEdit.EditorComponent.GetBookMark(BookMarkID,BookMarkX,BookMarkY)
    then begin
      MarkEditorIndex:=FindPageWithEditor(MarkSrcEdit);
      MarkDesc:=MarkDesc+': '+Notebook.Pages[MarkEditorIndex]
        +' ('+IntToStr(BookMarkY)+','+IntToStr(BookMarkX)+')';
    end;
    // set book mark item
    MarkMenuItem:=SetBookmarkMenuItem[BookMarkID];
    MarkMenuItem.Checked:=(MarkSrcEdit<>nil);
    MarkMenuItem.Caption:=uemSetBookmark+MarkDesc;
    // goto book mark item
    MarkMenuItem:=GotoBookmarkMenuItem[BookMarkID];
    MarkMenuItem.Checked:=(MarkSrcEdit<>nil);
    MarkMenuItem.Caption:=uemBookmarkN+MarkDesc;
  end;

  // editor layout
  MoveEditorLeftMenuItem.Enabled:=(NoteBook<>nil) and (NoteBook.PageCount>1);
  MoveEditorRightMenuItem.Enabled:=(NoteBook<>nil) and (NoteBook.PageCount>1);

  EditorPopupPoint:=EditorComp.ScreenToClient(SrcPopUpMenu.PopupPoint);
  if EditorPopupPoint.X>EditorComp.Gutter.Width then begin
    // user clicked on text
    SelAvail:=ASrcEdit.EditorComponent.SelAvail;
    SelAvailAndWritable:=SelAvail and (not ASrcEdit.ReadOnly);
    EncloseSelectionMenuItem.Enabled := SelAvailAndWritable;
    ExtractProcMenuItem.Enabled := SelAvailAndWritable;
    InvertAssignmentMenuItem.Enabled := SelAvailAndWritable;
    FindIdentifierReferencesMenuItem.Enabled:=
                                   IsValidIdent(ASrcEdit.GetWordAtCurrentCaret);
    RenameIdentifierMenuItem.Enabled:=
                                   IsValidIdent(ASrcEdit.GetWordAtCurrentCaret)
                                   and (not ASrcEdit.ReadOnly);
  end else begin
    // user clicked on gutter
    SourceEditorMarks.GetMarksForLine(EditorComp,EditorComp.CaretY,
                                      Marks,MarkCount);
    if Marks<>nil then begin
      for i:=0 to MarkCount-1 do begin
        CurMark:=Marks[i];
        CurMark.CreatePopupMenuItems(@AddUserDefinedPopupMenuItem);
      end;
      FreeMem(Marks);
    end;
  end;

  // add context specific menu items
  CurFilename:=ASrcEdit.FileName;
  if FilenameIsPascalUnit(CurFilename)
  and (FilenameIsAbsolute(CurFilename)) then begin
    if FileExists(ChangeFileExt(CurFilename,'.lfm')) then
      AddContextPopupMenuItem(
        Format(lisOpenLfm, [ChangeFileExt(ExtractFileName(CurFilename), '.lfm')]
          ),
        true,@OnPopupMenuOpenLFMFile);
    if FileExists(ChangeFileExt(CurFilename,'.lrs')) then
      AddContextPopupMenuItem(
        Format(lisOpenLfm, [ChangeFileExt(ExtractFileName(CurFilename), '.lrs')]
          ),
        true,@OnPopupMenuOpenLRSFile);
  end;
  if (CompareFileExt(CurFilename,'.lfm',true)=0)
  and (FilenameIsAbsolute(CurFilename)) then begin
    if FileExists(ChangeFileExt(CurFilename,'.pas')) then
      AddContextPopupMenuItem(
        Format(lisOpenLfm, [ChangeFileExt(ExtractFileName(CurFilename), '.pas')]
          ),
        true,@OnPopupMenuOpenPasFile);
    if FileExists(ChangeFileExt(CurFilename,'.pp')) then
      AddContextPopupMenuItem(
        Format(lisOpenLfm, [ChangeFileExt(ExtractFileName(CurFilename), '.pp')]
          ),
        true,@OnPopupMenuOpenPPFile);
  end;

  if Assigned(OnPopupMenu) then OnPopupMenu(@AddContextPopupMenuItem);
end;
{$ENDIF}

procedure TSourceNotebook.NotebookShowTabHint(Sender: TObject;
  HintInfo: PHintInfo);
var
  Tabindex: integer;
  ASrcEdit: TSourceEditor;
begin
  if (NoteBook=nil) or (HintInfo=nil) then exit;
  TabIndex:=NoteBook.TabIndexAtClientPos(
                                      Notebook.ScreenToClient(Mouse.CursorPos));
  if TabIndex<0 then exit;
  ASrcEdit:=FindSourceEditorWithPageIndex(TabIndex);
  if ASrcEdit=nil then exit;
  if ASrcEdit.CodeBuffer<>nil then begin
    HintInfo^.HintStr:=ASrcEdit.CodeBuffer.Filename;
  end;
end;

function TSourceNotebook.OnSourceMarksGetFilename(ASourceEditor: TObject
  ): string;
begin
  if (ASourceEditor=nil) or (not (ASourceEditor is TSourceEditor)) then
    RaiseException('TSourceNotebook.OnSourceMarksGetFilename');
  Result:=TSourceEditor(ASourceEditor).Filename;
end;

function TSourceNotebook.OnSourceMarksGetSourceEditor(ASynEdit: TCustomSynEdit
  ): TObject;
begin
  Result:=FindSourceEditorWithEditorComponent(ASynEdit);
end;

Procedure TSourceNotebook.BuildPopupMenu;
{$IFDEF UseMenuIntf}
var
  i: Integer;
begin
  debugln('TSourceNotebook.BuildPopupMenu');
  
  SrcPopupMenu := TPopupMenu.Create(Self);
  with SrcPopupMenu do begin
    AutoPopup := True;
    OnPopup :=@SrcPopUpMenuPopup;
  end;
  
  // assign the root TMenuItem to the registered menu root.
  // This will automatically create all registered items
  SourceEditorMenuRoot.MenuItem:=SrcPopupMenu.Items;
  SrcPopupMenu.Items.WriteDebugReport('TSourceNotebook.BuildPopupMenu ');

  SrcEditMenuFindDeclaration.OnClickMethod:=@FindDeclarationClicked;
  SrcEditMenuOpenFileAtCursor.OnClickMethod:=@OpenAtCursorClicked;

  SrcEditMenuClosePage.OnClickMethod:=@CloseClicked;
  SrcEditMenuCut.OnClickMethod:=@CutClicked;
  SrcEditMenuCopy.OnClickMethod:=@CopyClicked;
  SrcEditMenuPaste.OnClickMethod:=@PasteClicked;
  for i:=0 to 9 do begin
    SrcEditSubMenuGotoBookmarks.FindByName('GotoBookmark'+IntToStr(i))
                                           .OnClickMethod:=@BookmarkGotoClicked;
    SrcEditSubMenuSetBookmarks.FindByName('SetBookmark'+IntToStr(i))
                                            .OnClickMethod:=@BookMarkSetClicked;
  end;
  SrcEditMenuNextBookmark.OnClickMethod:=@NextBookmarkClicked;
  SrcEditMenuPrevBookmark.OnClickMethod:=@PrevBookmarkClicked;

  SrcEditMenuAddBreakpoint.OnClickMethod:=@AddBreakpointClicked;
  SrcEditMenuAddWatchAtCursor.OnClickMethod:=@AddWatchAtCursor;
  SrcEditMenuRunToCursor.OnClickMethod:=@RunToClicked;
  SrcEditMenuViewCallStack.OnClickMethod:=@ViewCallStackClick;

  SrcEditMenuMoveEditorLeft.OnClickMethod:=@MoveEditorLeftClicked;
  SrcEditMenuMoveEditorRight.OnClickMethod:=@MoveEditorRightClicked;

  SrcEditMenuCompleteCode.OnClickMethod:=@CompleteCodeMenuItemClick;
  SrcEditMenuEncloseSelection.OnClickMethod:=@EncloseSelectionMenuItemClick;
  SrcEditMenuExtractProc.OnClickMethod:=@ExtractProcMenuItemClick;
  SrcEditMenuInvertAssignment.OnClickMethod:=@InvertAssignmentMenuItemClick;
  SrcEditMenuFindIdentifierReferences.OnClickMethod:=
                                         @FindIdentifierReferencesMenuItemClick;
  SrcEditMenuRenameIdentifier.OnClickMethod:=@RenameIdentifierMenuItemClick;

  SrcEditMenuReadOnly.OnClickMethod:=@ReadOnlyClicked;
  SrcEditMenuShowLineNumbers.OnClickMethod:=@ToggleLineNumbersClicked;
  SrcEditMenuShowUnitInfo.OnClickMethod:=@ShowUnitInfo;
  SrcEditMenuEditorProperties.OnClickMethod:=@EditorPropertiesClicked;
end;
{$ELSE}
  Function Seperator: TMenuItem;
  Begin
    Result := TMenuItem.Create(Self);
    Result.Caption := '-';
  end;
  
  procedure AddFileTypeSpecificMenuItems;
  begin

  end;

var
  SubMenuItem: TMenuItem;
  I: Integer;
Begin
  SrcPopupMenu := TPopupMenu.Create(Self);
  with SrcPopupMenu do begin
    AutoPopup := True;
    OnPopup :=@SrcPopUpMenuPopup;
  end;

  FindDeclarationMenuItem := TMenuItem.Create(Self);
  with FindDeclarationMenuItem do begin
    Name:='FindDeclarationMenuItem';
    Caption := uemFindDeclaration;
    OnClick := @FindDeclarationClicked;
  end;
  SrcPopupMenu.Items.Add(FindDeclarationMenuItem);

  OpenFileAtCursorMenuItem := TMenuItem.Create(Self);
  with OpenFileAtCursorMenuItem do begin
    Name:='OpenFileAtCursorMenuItem';
    Caption := uemOpenFileAtCursor;
    OnClick := @OpenAtCursorClicked;
  end;
  SrcPopupMenu.Items.Add(OpenFileAtCursorMenuItem);

  ClosePageMenuItem := TMenuItem.Create(Self);
  with ClosePageMenuItem do begin
    Name:='ClosePageMenuItem';
    Caption := uemClosePage;
    OnClick := @CloseClicked;
  end;
  SrcPopupMenu.Items.Add(ClosePageMenuItem);

  SrcPopupMenu.Items.Add(Seperator);

  CutMenuItem := TMenuItem.Create(Self);
  with CutMenUItem do begin
    Name := 'CutMenuItem';
    Caption := uemCut;
    onClick := @CutClicked;
  end;
  SrcPopupMenu.Items.Add(CutMenuItem);
  
  CopyMenuItem := TMenuItem.Create(Self);
  with CopyMenUItem do begin
    Name := 'CopyMenuItem';
    Caption := uemCopy;
    onClick := @CopyClicked;
  end;
  SrcPopupMenu.Items.Add(CopyMenuItem);
  
  PasteMenuItem := TMenuItem.Create(Self);
  with PasteMenUItem do begin
    Name := 'PasteMenuItem';
    Caption := uemPaste;
    onClick := @PasteClicked;
  end;
  SrcPopupMenu.Items.Add(PasteMenuItem);
  
  AddFileTypeSpecificMenuItems;

  SrcPopupMenu.Items.Add(Seperator);

  GotoBookmarkMenuItem := TMenuItem.Create(Self);
  with GotoBookmarkMenuItem do begin
    Name:='GotoBookmarkMenuItem';
    Caption := uemGotoBookmark;
  end;
  SrcPopupMenu.Items.Add(GotoBookmarkMenuItem);

  begin
    for I := 0 to 9 do
    Begin
      SubMenuItem := TMenuItem.Create(Self);
      with SubmenuItem do begin
        Name:='GotoBookmark'+IntToStr(I)+'MenuItem';
        Caption := uemBookmarkN+IntToStr(i);
        OnClick := @BookmarkGotoClicked;
      end;
      GotoBookmarkMenuItem.Add(SubMenuItem);
    end;

    NextBookmarkMenuItem := TMenuItem.Create(Self);
    with NextBookmarkMenuItem do begin
      Name:='NextBookmarkMenuItem';
      Caption := uemNextBookmark;
      OnClick := @BookmarkNextClicked;
    end;
    GotoBookmarkMenuItem.Add(NextBookmarkMenuItem);

    PrevBookmarkMenuItem := TMenuItem.Create(Self);
    with PrevBookmarkMenuItem do begin
      Name:='PrevBookmarkMenuItem';
      Caption := uemPrevBookmark;
      OnClick := @BookmarkPrevClicked;
    end;
    GotoBookmarkMenuItem.Add(PrevBookmarkMenuItem);
  end;

  SetBookmarkMenuItem := TMenuItem.Create(Self);
  with SetBookmarkMenuItem do begin
    Name:='SetBookmarkMenuItem';
    Caption := uemSetBookmark;
  end;
  SrcPopupMenu.Items.Add(SetBookmarkMenuItem);

  for I := 0 to 9 do
    Begin
      SubMenuItem := TMenuItem.Create(Self);
      with SubMenuItem do begin
        Name:='SubSetBookmarkMenuItem'+IntToStr(I);
        Caption := uemBookmarkN+IntToStr(i);
        OnClick := @BookmarkSetClicked;
      end;
      SetBookmarkMenuItem.Add(SubMenuItem);
    end;

  SrcPopupMenu.Items.Add(Seperator);

  ReadOnlyMenuItem := TMenuItem.Create(Self);
  with ReadOnlyMenuItem do begin
    Name:='ReadOnlyMenuItem';
    Caption := uemReadOnly;
    OnClick := @ReadOnlyClicked;
    ShowAlwaysCheckable:=true;
  end;
  SrcPopupMenu.Items.Add(ReadOnlyMenuItem);

  ShowLineNumbersMenuItem := TMenuItem.Create(Self);
  with ShowLineNumbersMenuItem do begin
    Name := 'ShowLineNumbersMenuItem';
    Caption := dlgShowLineNumbers;
    OnClick := @ToggleLineNumbersClicked;
    ShowAlwaysCheckable:=true;
  end;
  SrcPopupMenu.Items.Add(ShowLineNumbersMenuItem);

  SrcPopupMenu.Items.Add(Seperator);

  ShowUnitInfoMenuItem := TMenuItem.Create(Self);
  with ShowUnitInfoMenuItem do begin
    Name:='ShowUnitInfoMenuItem';
    Caption := uemShowUnitInfo;
    OnClick:=@ShowUnitInfo;
  end;
  SrcPopupMenu.Items.Add(ShowUnitInfoMenuItem);

  SrcPopupMenu.Items.Add(Seperator);

  DebugMenuItem := TMenuItem.Create(Self);
  with DebugMenuItem do begin
    Name:='DebugMenuItem';
    Caption := uemDebugWord;
  end;
  SrcPopupMenu.Items.Add(DebugMenuItem);

      AddBreakpointMenuItem := TMenuItem.Create(Self);
      with AddBreakpointMenuItem do begin
        Name := 'AddBreakpointMenuItem';
        Caption := uemAddBreakpoint;
        OnClick := @AddBreakpointClicked;
      end;
      DebugMenuItem.Add(AddBreakpointMenuItem);

      AddWatchAtCursorMenuItem := TMenuItem.Create(Self);
      with AddWatchAtCursorMenuItem do begin
        Name := 'AddWatchAtCursorMenuItem';
        Caption := uemAddWatchAtCursor;
        OnClick := @AddWatchAtCursor;
      end;
      DebugMenuItem.Add(AddWatchAtCursorMenuItem);

      RunToCursorMenuItem := TMenuItem.Create(Self);
      with RunToCursorMenuItem do begin
        Name := 'RunToCursorMenuItem';
        Caption := uemRunToCursor;
        OnClick := @RunToClicked;
      end;
      DebugMenuItem.Add(RunToCursorMenuItem);

      ViewCallStackMenuItem := TMenuItem.Create(Self);
      with ViewCallStackMenuItem do begin
        Name := 'ViewCallStackMenuItem';
        Caption := uemViewCallStack;
        OnClick := @ViewCallStackClick;
      end;
      DebugMenuItem.Add(ViewCallStackMenuItem);


  SrcPopupMenu.Items.Add(Seperator);

  MoveEditorLeftMenuItem := TMenuItem.Create(Self);
  with MoveEditorLeftMenuItem do begin
    Name := 'MoveEditorLeftMenuItem';
    Caption := uemMoveEditorLeft;
    OnClick :=@MoveEditorLeftClicked;
  end;
  SrcPopupMenu.Items.Add(MoveEditorLeftMenuItem);

  MoveEditorRightMenuItem := TMenuItem.Create(Self);
  with MoveEditorRightMenuItem do begin
    Name := 'MoveEditorRightMenuItem';
    Caption := uemMoveEditorRight;
    OnClick :=@MoveEditorRightClicked;
  end;
  SrcPopupMenu.Items.Add(MoveEditorRightMenuItem);

  SrcPopupMenu.Items.Add(Seperator);

  RefactorMenuItem := TMenuItem.Create(Self);
  with RefactorMenuItem do begin
    Name:='RefactorMenuItem';
    Caption := uemRefactor;
  end;
  SrcPopupMenu.Items.Add(RefactorMenuItem);
  
      CompleteCodeMenuItem := TMenuItem.Create(Self);
      with CompleteCodeMenuItem do begin
        Name := 'CompleteCodeMenuItem';
        Caption := uemCompleteCode;
        OnClick :=@CompleteCodeMenuItemClick;
      end;
      RefactorMenuItem.Add(CompleteCodeMenuItem);

      EncloseSelectionMenuItem := TMenuItem.Create(Self);
      with EncloseSelectionMenuItem do begin
        Name := 'EncloseSelectionMenuItem';
        Caption := uemEncloseSelection;
        OnClick :=@EncloseSelectionMenuItemClick;
      end;
      RefactorMenuItem.Add(EncloseSelectionMenuItem);

      ExtractProcMenuItem := TMenuItem.Create(Self);
      with ExtractProcMenuItem do begin
        Name := 'ExtractProcMenuItem';
        Caption := uemExtractProc;
        OnClick :=@ExtractProcMenuItemClick;
      end;
      RefactorMenuItem.Add(ExtractProcMenuItem);

      InvertAssignmentMenuItem := TMenuItem.Create(Self);
      with InvertAssignmentMenuItem do begin
        Name := 'InvertAssignment';
        Caption := uemInvertAssignment;
        OnClick :=@InvertAssignmentMenuItemClick;
      end;
      RefactorMenuItem.Add(InvertAssignmentMenuItem);

      FindIdentifierReferencesMenuItem := TMenuItem.Create(Self);
      with FindIdentifierReferencesMenuItem do begin
        Name := 'FindIdentifierReferencesMenuItem';
        Caption := lisMenuFindIdentifierRefs;
        OnClick :=@FindIdentifierReferencesMenuItemClick;
      end;
      RefactorMenuItem.Add(FindIdentifierReferencesMenuItem);

      RenameIdentifierMenuItem := TMenuItem.Create(Self);
      with RenameIdentifierMenuItem do begin
        Name := 'RenameIdentifierMenuItem';
        Caption := lisMenuRenameIdentifier;
        OnClick :=@RenameIdentifierMenuItemClick;
      end;
      RefactorMenuItem.Add(RenameIdentifierMenuItem);

  SrcPopupMenu.Items.Add(Seperator);

  EditorPropertiesMenuItem := TMenuItem.Create(Self);
  with EditorPropertiesMenuItem do begin
    Name := 'EditorPropertiesMenuItem';
    Caption := uemEditorproperties;
    OnClick :=@EditorPropertiesClicked;
  end;
  SrcPopupMenu.Items.Add(EditorPropertiesMenuItem);
end;
{$ENDIF}

procedure TSourceNotebook.RemoveUserDefinedMenuItems;
var
  AMenuItem: TMenuItem;
begin
  if fCustomPopupMenuItems=nil then exit;
  while fCustomPopupMenuItems.Count>0 do begin
    AMenuItem:=TMenuItem(fCustomPopupMenuItems[fCustomPopupMenuItems.Count-1]);
    AMenuItem.Free;
    fCustomPopupMenuItems.Delete(fCustomPopupMenuItems.Count-1);
  end;
end;

function TSourceNotebook.AddUserDefinedPopupMenuItem(const NewCaption: string;
  const NewEnabled: boolean; const NewOnClick: TNotifyEvent): TMenuItem;
var
  NewIndex: Integer;
begin
  if fCustomPopupMenuItems=nil then fCustomPopupMenuItems:=TList.Create;
  NewIndex:=fCustomPopupMenuItems.Count;
  Result:=TMenuItem.Create(Self);
  fCustomPopupMenuItems.Add(Result);
  Result.Caption:=NewCaption;
  Result.Enabled:=NewEnabled;
  Result.OnClick:=NewOnClick;
  SrcPopUpMenu.Items.Insert(NewIndex,Result);
end;

procedure TSourceNotebook.RemoveContextMenuItems;
var
  AMenuItem: TMenuItem;
begin
  if fContextPopupMenuItems=nil then exit;
  while fContextPopupMenuItems.Count>0 do begin
    AMenuItem:=TMenuItem(fContextPopupMenuItems[fContextPopupMenuItems.Count-1]);
    AMenuItem.Free;
    fContextPopupMenuItems.Delete(fContextPopupMenuItems.Count-1);
  end;
end;

function TSourceNotebook.AddContextPopupMenuItem(const NewCaption: string;
  const NewEnabled: boolean; const NewOnClick: TNotifyEvent): TMenuItem;
var
  NewIndex: Integer;
begin
  if fContextPopupMenuItems=nil then fContextPopupMenuItems:=TList.Create;
  if fContextPopupMenuItems.Count=0 then begin
    Result:=TMenuItem.Create(Self);
    Result.Caption:='-';
    fContextPopupMenuItems.Add(Result);
    NewIndex:=fContextPopupMenuItems.Count+ClosePageMenuItem.MenuIndex;
    SrcPopUpMenu.Items.Insert(NewIndex,Result);
  end;
  Result:=TMenuItem.Create(Self);
  fContextPopupMenuItems.Add(Result);
  Result.Caption:=NewCaption;
  Result.Enabled:=NewEnabled;
  Result.OnClick:=NewOnClick;
  NewIndex:=fContextPopupMenuItems.Count+ClosePageMenuItem.MenuIndex;
  SrcPopUpMenu.Items.Insert(NewIndex,Result);
end;

{-------------------------------------------------------------------------------
  Procedure TSourceNotebook.EditorChanged
  Params: Sender: TObject
  Result: none

  Called whenever an editor status changes. Sender is normally a TSynEdit.
-------------------------------------------------------------------------------}
Procedure TSourceNotebook.EditorChanged(Sender: TObject);
var SenderDeleted: boolean;
Begin
  SenderDeleted:=FUnUsedEditorComponents.IndexOf(Sender)>=0;
  ClearUnUsedEditorComponents(false);
  UpdateStatusBar;
  if (not SenderDeleted) and Assigned(OnEditorChanged) then
    OnEditorChanged(Sender);
End;

Function TSourceNotebook.NewSE(PageNum: Integer): TSourceEditor;
Begin
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.NewSE A ');
  {$ENDIF}
  if CreateNotebook then Pagenum := 0;
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.NewSE A2 ');
  {$ENDIF}
  if Pagenum < 0 then begin
    // add a new page right to the current
    Pagenum := Notebook.PageIndex+1;
    Notebook.Pages.Insert(PageNum,FindUniquePageName('',-1));
  end;
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.NewSE B  ',Notebook.PageIndex,',',NoteBook.Pages.Count);
  {$ENDIF}
  Result := TSourceEditor.Create(Self,Notebook.Page[PageNum]);
  Result.EditorComponent.BeginUpdate;
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.NewSE C ');
  {$ENDIF}
  FSourceEditorList.Add(Result);
  Result.CodeTemplates:=CodeTemplateModul;
  Notebook.PageIndex := Pagenum;
  Result.FPageName:=NoteBook.Pages[Pagenum];
  Result.EditorComponent.BookMarkOptions.BookmarkImages :=
                                                      SourceEditorMarks.ImgList;
  Result.PopupMenu:=SrcPopupMenu;
  Result.OnEditorChange := @EditorChanged;
  Result.OnMouseMove := @EditorMouseMove;
  Result.OnMouseDown := @EditorMouseDown;
  Result.OnMouseUp := @EditorMouseUp;
  Result.EditorComponent.EndUpdate;
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.NewSE end ');
  {$ENDIF}
end;

function TSourceNotebook.FindSourceEditorWithPageIndex(
  PageIndex:integer):TSourceEditor;
var I:integer;
  TempEditor: TControl;
begin
  ClearUnUsedEditorComponents(false);
  Result := nil;
  if (FSourceEditorList=nil)
    or (Notebook=nil)
    or (PageIndex<0) or (PageIndex>=Notebook.PageCount) then exit;
  TempEditor:=nil;
  with Notebook.Page[PageIndex] do
    for I := 0 to ControlCount-1 do
      if Controls[I] is TSynEdit then
        Begin
          TempEditor := Controls[I];
          Break;
        end;
  if TempEditor=nil then exit;
  I := FSourceEditorList.Count-1;
  while (I>=0)
  and (TSourceEditor(FSourceEditorList[I]).EditorComponent <> TempEditor) do
    dec(i);
  if i<0 then exit;
  Result := TSourceEditor(FSourceEditorList[i]);
end;

Function TSourceNotebook.GetActiveSE: TSourceEditor;
Begin
  Result := nil;
  if (FSourceEditorList=nil) or (FSourceEditorList.Count=0)
    or (Notebook=nil) or (Notebook.PageIndex<0) then exit;
  Result:=FindSourceEditorWithPageIndex(Notebook.PageIndex);
end;

procedure TSourceNotebook.SetActiveSE(SrcEdit: TSourceEditor);
var
  i: integer;
begin
  i:=FindPageWithEditor(SrcEdit);
  if i>=0 then
    NoteBook.PageIndex:=i;
end;

procedure TSourceNotebook.CheckCurrentCodeBufferChanged;
var
  SrcEdit: TSourceEditor;
begin
  SrcEdit:=GetActiveSE;
  if FLastCodeBuffer=SrcEdit.CodeBuffer then exit;
  FLastCodeBuffer:=SrcEdit.CodeBuffer;
  if Assigned(OnCurrentCodeBufferChanged) then
    OnCurrentCodeBufferChanged(Self);
end;

procedure TSourceNotebook.LockAllEditorsInSourceChangeCache;
// lock all sourceeditors that are to be modified by the CodeToolBoss
var i: integer;
begin
  for i:=0 to EditorCount-1 do begin
    if CodeToolBoss.SourceChangeCache.BufferIsModified(Editors[i].CodeBuffer)
    then begin
      with Editors[i].EditorComponent do begin
        BeginUpdate;
        BeginUndoBlock;
      end;
    end;
  end;
end;

procedure TSourceNotebook.UnlockAllEditorsInSourceChangeCache;
// unlock all sourceeditors that were modified by the CodeToolBoss
var i: integer;
begin
  for i:=0 to EditorCount-1 do begin
    if CodeToolBoss.SourceChangeCache.BufferIsModified(Editors[i].CodeBuffer)
    then begin
      with Editors[i].EditorComponent do begin
        EndUndoBlock;
        EndUpdate;
      end;
    end;
  end;
end;

function TSourceNotebook.GetDiffFiles: TDiffFiles;
var
  i: Integer;
  SrcEdit: TSourceEditor;
begin
  Result:=TDiffFiles.Create;
  if Notebook=nil then exit;
  for i:=0 to NoteBook.PageCount-1 do begin
    SrcEdit:=FindSourceEditorWithPageIndex(i);
    Result.Add(TDiffFile.Create(NoteBook.Pages[i],i,SrcEdit.SelectionAvailable));
  end;
end;

procedure TSourceNotebook.GetSourceText(PageIndex: integer;
  OnlySelection: boolean; var Source: string);
var
  SrcEdit: TSourceEditor;
begin
  SrcEdit:=FindSourceEditorWithPageIndex(PageIndex);
  if SrcEdit=nil then
    Source:=''
  else
    Source:=SrcEdit.GetText(OnlySelection);
end;

Function TSourceNotebook.Empty: Boolean;
Begin
  Result := (not assigned(Notebook)) or (Notebook.PageCount = 0);
end;

procedure TSourceNotebook.FindReplaceDlgKey(Sender: TObject; var Key: Word;
  Shift: TShiftState; FindDlgComponent: TFindDlgComponent);
var
  HistoryList: TStringList;
  CurText: string;
  CurIndex: integer;

  procedure SetHistoryText;
  var s: string;
  begin
    if FindReplaceDlgHistoryIndex[FindDlgComponent]>=0 then
      s:=HistoryList[FindReplaceDlgHistoryIndex[FindDlgComponent]]
    else
      s:=FindReplaceDlgUserText[FindDlgComponent];
    //writeln('  SetHistoryText "',s,'"');
    FindReplaceDlg.ComponentText[FindDlgComponent]:=s
  end;

  procedure FetchFocus;
  begin
    if Sender is TWinControl then
      TWinControl(Sender).SetFocus;
  end;

begin
  if FindDlgComponent=fdcText then
    HistoryList:=InputHistories.FindHistory
  else
    HistoryList:=InputHistories.ReplaceHistory;
  CurIndex:=FindReplaceDlgHistoryIndex[FindDlgComponent];
  CurText:=FindReplaceDlg.ComponentText[FindDlgComponent];
  //writeln('TSourceNotebook.FindReplaceDlgKey CurIndex=',CurIndex,' CurText="',CurText,'"');
  if Key=VK_Down then begin
    // go forward in history
    if CurIndex>=0 then begin
      if (HistoryList[CurIndex]<>CurText) then begin
        // save user text
        FindReplaceDlgUserText[FindDlgComponent]:=CurText;
      end;
      dec(FindReplaceDlgHistoryIndex[FindDlgComponent]);
      SetHistoryText;
    end;
    FetchFocus;
    Key:=VK_UNKNOWN;
  end else if Key=VK_UP then begin
    if (CurIndex<0)
    or (HistoryList[CurIndex]<>CurText) then
    begin
      // save user text
      FindReplaceDlgUserText[FindDlgComponent]:=CurText;
    end;
    // go back in history
    if CurIndex<HistoryList.Count-1 then
    begin
      inc(FindReplaceDlgHistoryIndex[FindDlgComponent]);
      SetHistoryText;
    end;
    FetchFocus;
    Key:=VK_UNKNOWN;
  end;
end;

procedure TSourceNotebook.EndIncrementalFind;
begin
  if not (snIncrementalFind in States) then exit;
  Exclude(States,snIncrementalFind);
  FindReplaceDlg.FindText:=fIncrementalSearchStr;
  FindReplaceDlg.Options:=[];
  UpdateStatusBar;
end;

function TSourceNotebook.SomethingModified: boolean;
var i: integer;
begin
  Result:=false;
  for i:=0 to EditorCount-1 do Result:=Result or Editors[i].Modified;
end;

Procedure TSourceNotebook.NextEditor;
Begin
  if NoteBook=nil then exit;
  if Notebook.PageIndex < Notebook.PageCount-1 then
    Notebook.PageIndex := Notebook.PageIndex+1
  else
    NoteBook.PageIndex := 0;
End;

Procedure TSourceNotebook.PrevEditor;
Begin
  if NoteBook=nil then exit;
  if Notebook.PageIndex > 0 then
    Notebook.PageIndex := Notebook.PageIndex-1
  else
    NoteBook.PageIndex := NoteBook.PageCount-1;
End;

procedure TSourceNotebook.MoveEditor(OldPageIndex, NewPageIndex: integer);
begin
  if (NoteBook=nil) or (NoteBook.PageCount<=1)
  or (OldPageIndex=NewPageIndex)
  or (OldPageIndex<0) or (OldPageIndex>=Notebook.PageCount)
  or (NewPageIndex<0) or (NewPageIndex>=Notebook.PageCount) then exit;
  if Assigned(OnMovingPage) then
    OnMovingPage(Self,OldPageIndex,NewPageIndex);
  NoteBook.Pages.Move(OldPageIndex,NewPageIndex);
end;

procedure TSourceNotebook.MoveEditorLeft(PageIndex: integer);
begin
  if (NoteBook=nil) or (NoteBook.PageCount<=1) then exit;
  if PageIndex>0 then
    MoveEditor(PageIndex,PageIndex-1)
  else
    MoveEditor(PageIndex,NoteBook.PageCount-1);
end;

procedure TSourceNotebook.MoveEditorRight(PageIndex: integer);
begin
  if (NoteBook=nil) or (NoteBook.PageCount<=1) then exit;
  if PageIndex<Notebook.PageCount-1 then
    MoveEditor(PageIndex,PageIndex+1)
  else
    MoveEditor(PageIndex,0);
end;

procedure TSourceNotebook.MoveActivePageLeft;
begin
  if (NoteBook=nil) then exit;
  MoveEditorLeft(NoteBook.PageIndex);
end;

procedure TSourceNotebook.MoveActivePageRight;
begin
  if (NoteBook=nil) then exit;
  MoveEditorRight(NoteBook.PageIndex);
end;

Procedure TSourceNotebook.FindClicked(Sender: TObject);
var TempEditor:TSourceEditor;
Begin
  TempEditor:=GetActiveSE;
  if TempEditor <> nil then TempEditor.StartFindAndReplace(false);
End;

Procedure TSourceNotebook.ReplaceClicked(Sender: TObject);
var TempEditor:TSourceEditor;
Begin
  TempEditor:=GetActiveSE;
  if TempEditor <> nil then TempEditor.StartFindAndReplace(true);
End;

procedure TSourceNotebook.IncrementalFindClicked(Sender: TObject);
var
  TempEditor: TSourceEditor;
begin
  TempEditor:=GetActiveSE;
  if TempEditor = nil then exit;
  Include(States,snIncrementalFind);
  fIncrementalSearchStartPos:=TempEditor.EditorComponent.LogicalCaretXY;
  fIncrementalSearchCancelPos:=fIncrementalSearchStartPos;
  FIncrementalSearchPos:=fIncrementalSearchStartPos;
  IncrementalSearchStr:='';
  UpdateStatusBar;
end;

Procedure TSourceNotebook.FindNextClicked(Sender: TObject);
var TempEditor:TSourceEditor;
Begin
  TempEditor:=GetActiveSe;
  if TempEditor <> nil then TempEditor.FindNext;
End;

Procedure TSourceNotebook.FindPreviousClicked(Sender: TObject);
var TempEditor:TSourceEditor;
Begin
  TempEditor:=GetActiveSe;
  if TempEditor <> nil then TempEditor.FindPrevious;
End;

function TSourceNotebook.CreateFindInFilesDialog: TLazFindInFilesDialog;
begin
  Result := TLazFindInFilesDialog.Create(Application);
  LoadFindInFilesHistory(Result);
end;

procedure TSourceNotebook.LoadFindInFilesHistory(ADialog: TLazFindInFilesDialog);
  procedure AssignToComboBox(AComboBox: TComboBox; Strings: TStrings);
  begin
    AComboBox.Items.Assign(Strings);
    if AComboBox.Items.Count>0 then
      AComboBox.ItemIndex := 0;
  end;
begin
  if Assigned(ADialog) then
  begin
    with ADialog, InputHistories do
    begin
      TextToFindComboBox.Items.Assign(FindHistory);
      if not EditorOpts.FindTextAtCursor then begin
        if TextToFindComboBox.Items.Count>0 then begin
          //debugln('TSourceNotebook.LoadFindInFilesHistory A TextToFindComboBox.Text=',TextToFindComboBox.Text);
          TextToFindComboBox.ItemIndex:=0;
          TextToFindComboBox.SelectAll;
          //debugln('TSourceNotebook.LoadFindInFilesHistory B TextToFindComboBox.Text=',TextToFindComboBox.Text);
        end;
      end;
      AssignToComboBox(DirectoryComboBox, FindInFilesPathHistory);
      AssignToComboBox(FileMaskComboBox, FindInFilesMaskHistory);
      Options:=FindInFilesSearchOptions;
    end;
  end;
end;

procedure TSourceNoteBook.SaveFindInFilesHistory(ADialog: TLazFindInFilesDialog);
begin
  if Assigned(ADialog) then
  begin
    with ADialog do
    begin
      InputHistories.AddToFindHistory(FindText);
      InputHistories.AddToFindInFilesPathHistory(DirectoryComboBox.Text);
      InputHistories.AddToFindInFilesMaskHistory(FileMaskComboBox.Text);
      InputHistories.FindInFilesSearchOptions:=Options;
    end;
    InputHistories.Save;
  end;
end;

{Search All the files in a project and add the results to the SearchResultsView
 Dialog}
procedure TSourceNoteBook.FIFSearchProject(AProject: TProject;
                                           ADialog: TLazFindInFilesDialog);
var
  AnUnitInfo:  TUnitInfo;
  TheFileList: TStringList;
  SearchForm:  TSearchForm;
begin
  try
    TheFileList:= TStringList.Create;
    AnUnitInfo:=AProject.FirstPartOfProject;
    while AnUnitInfo<>nil do begin
      //Only if file exists on disk.
      if FilenameIsAbsolute(AnUnitInfo.FileName)
      and FileExists(AnUnitInfo.FileName) then
        TheFileList.Add(AnUnitInfo.FileName);
      AnUnitInfo:=AnUnitInfo.NextPartOfProject;
    end;
    SearchForm:= FIFCreateSearchForm(ADialog);
    SearchForm.SearchFileList:= TheFileList;
    DoFindInFiles(SearchForm);
  finally
    FreeAndNil(TheFileList);
    FreeAndNil(SearchForm);
  end;
end;

procedure TSourceNoteBook.FIFSearchDir(ADialog: TLazFindInFilesDialog);
var
  SearchForm: TSearchForm;
begin
  try
    SearchForm:= FIFCreateSearchForm(ADialog);
    SearchForm.SearchFileList:= Nil;
    DoFindInFiles(SearchForm);
  finally
    FreeAndNil(SearchForm);
  end;
end;

Procedure TSourceNoteBook.DoFindInFiles(ASearchForm: TSearchForm);
var
  ListIndex: integer;
begin
  ShowSearchResultsView;
  ListIndex:=SearchResultsView.AddResult(lisSearchFor+ASearchForm.SearchText,
                                          ASearchForm.SearchText,
                                          ASearchForm.SearchDirectory,
                                          ASearchForm.SearchMask,
                                          ASearchForm.SearchOptions);

  try
    SearchResultsView.BeginUpdate(ListIndex);
    ASearchForm.ResultsList:= SearchResultsView.Items[ListIndex];
    SearchResultsView.Items[ListIndex].Clear;
    ASearchForm.ResultsWindow:= ListIndex;
    try
      ASearchForm.Show;
      ASearchForm.DoSearch;
    except
      on E: ERegExpr do
        MessageDlg(lisUEErrorInRegularExpression, E.Message,mtError,
                   [mbCancel],0);
    end;
  finally
    SearchResultsView.EndUpdate(ListIndex);
    SearchResultsView.ShowOnTop;
  end;
end;

procedure TSourceNoteBook.FIFSearchOpenFiles(ADialog: TLazFindInFilesDialog);
var
  i: integer;
  TheFileList: TStringList;
  SearchForm:  TSearchForm;
begin
  try
    TheFileList:= TStringList.Create;
    for i:= 0 to self.EditorCount -1 do
    begin
      //only if file exists on disk
      if FilenameIsAbsolute(Editors[i].FileName) and
         FileExists(Editors[i].FileName) then
      begin
         TheFileList.Add(Editors[i].FileName);
      end;//if
    end;//for
    SearchForm:= FIFCreateSearchForm(ADialog);
    SearchForm.SearchFileList:= TheFileList;
    DoFindInFiles(SearchForm);
  finally
    FreeAndNil(TheFileList);
    FreeAndNil(SearchForm);
  end;//finally
end;//FIFSearchOpenFiles

{Creates the search form and loads the options selected in the
 findinfilesdialog}
function TSourceNoteBook.FIFCreateSearchForm
                         (ADialog: TLazFindInFilesDialog): TSearchForm;
begin
  result:= TSearchForm.Create(SearchResultsView);
  with result do
  begin
    SearchOptions:= ADialog.Options;
    SearchText:= ADialog.FindText;
    SearchMask:= ADialog.FileMaskComboBox.Text;
    SearchDirectory:= ADialog.DirectoryComboBox.Text;
  end;//with
end;//FIFCreateSearchForm

Procedure TSourceNotebook.FindInFilesPerDialog(AProject: TProject);
var
  TempEditor: TSourceEditor;
  FindText: string;
Begin
  FindText:='';
  TempEditor := GetActiveSE;
  if TempEditor <> nil 
  then with TempEditor, EditorComponent do 
  begin
    if EditorOpts.FindTextAtCursor 
    then begin
      if SelAvail and (BlockBegin.Y = BlockEnd.Y) 
      then FindText := SelText
      else FindText := GetWordAtRowCol(LogicalCaretXY);
    end else begin
      if InputHistories.FindHistory.Count>0 then
        FindText:=InputHistories.FindHistory[0];
    end;
  end;
  
  FindInFiles(AProject, FindText);
End;

procedure TSourceNotebook.FindInFiles(AProject: TProject;
  const FindText: string);
begin
  if FindInFilesDialog = nil then
    FindInFilesDialog := CreateFindInFilesDialog
  else
    LoadFindInFilesHistory(FindInFilesDialog);

  FindInFilesDialog.FindText:= FindText;
  IDEDialogLayoutList.ApplyLayout(FindInFilesDialog,320,430);
  if FindInFilesDialog.ShowModal=mrOk then
  begin
    SaveFindInFilesHistory(FindInFilesDialog);

    if FindInFilesDialog.FindText <>'' then
    begin
      case FindInFilesDialog.WhereRadioGroup.ItemIndex of
        Integer(0): FIFSearchProject(AProject, FindInFilesDialog);
        integer(1): FIFSearchOpenFiles(FindInFilesDialog);
        integer(2): FIFSearchDir(FindInFilesDialog);
      end;
    end;
  end;
  IDEDialogLayoutList.SaveLayout(FindInFilesDialog);
end;

procedure TSourceNotebook.ShowSearchResultsView;
begin
  if Assigned(OnShowSearchResultsView) then OnShowSearchResultsView(Self);
end;

procedure TSourceNotebook.GotoLineClicked(Sender: TObject);
var SrcEdit: TSourceEditor;
begin
  SrcEdit:=GetActiveSE;
  if SrcEdit<>nil then SrcEdit.ShowGotoLineDialog;
end;

procedure TSourceNotebook.HistoryJump(Sender: TObject;
  CloseAction: TJumpHistoryAction);
var NewCaretXY: TPoint;
  NewTopLine: integer;
  NewPageIndex: integer;
  SrcEdit: TSourceEditor;
begin
  if (NoteBook<>nil) and Assigned(OnJumpToHistoryPoint) then begin
    NewCaretXY.X:=-1;
    NewPageIndex:=-1;
    OnJumpToHistoryPoint(NewCaretXY,NewTopLine,NewPageIndex,CloseAction);
    SrcEdit:=FindSourceEditorWithPageIndex(NewPageIndex);
    if SrcEdit<>nil then begin
      NoteBook.PageIndex:=NewPageIndex;
      with SrcEdit.EditorComponent do begin
        TopLine:=NewTopLine;
        LogicalCaretXY:=NewCaretXY;
        BlockBegin:=NewCaretXY;
        BlockEnd:=NewCaretXY;
      end;
    end;
  end;
end;

procedure TSourceNotebook.JumpBackClicked(Sender: TObject);
begin
  HistoryJump(Sender,jhaBack);
end;

procedure TSourceNotebook.JumpForwardClicked(Sender: TObject);
begin
  HistoryJump(Sender,jhaForward);
end;

procedure TSourceNotebook.AddJumpPointClicked(Sender: TObject);
var SrcEdit: TSourceEditor;
begin
  if Assigned(OnAddJumpPoint) then begin
    SrcEdit:=GetActiveSE;
    if SrcEdit<>nil then begin
      OnAddJumpPoint(SrcEdit.EditorComponent.LogicalCaretXY,
        SrcEdit.EditorComponent.TopLine, Notebook.PageIndex, true);
    end;
  end;
end;

procedure TSourceNotebook.DeleteLastJumpPointClicked(Sender: TObject);
begin
  if Assigned(OnDeleteLastJumpPoint) then
    OnDeleteLastJumpPoint(Sender);
end;

procedure TSourceNotebook.ViewJumpHistoryClicked(Sender: TObject);
begin
  if Assigned(OnViewJumpHistory) then
    OnViewJumpHistory(Sender);
end;

procedure TSourceNotebook.ActivateHint(const ScreenPos: TPoint;
  const TheHint: string);
var
  HintWinRect: TRect;
begin
  if FHintWindow<>nil then
    FHintWindow.Visible:=false;
  if FHintWindow=nil then
    FHintWindow:=THintWindow.Create(Self);
  HintWinRect := FHintWindow.CalcHintRect(Screen.Width, TheHint, nil);
  OffsetRect(HintWinRect, ScreenPos.X, ScreenPos.Y+30);
  FHintWindow.ActivateHint(HintWinRect,TheHint);
end;

procedure TSourceNotebook.HideHint;
begin
  if FHintTimer<>nil then
    FHintTimer.Enabled:=false;
  if IdentCompletionTimer<>nil then
    IdentCompletionTimer.Enabled:=false;
  if FHintWindow<>nil then
    FHintWindow.Visible:=false;
end;

procedure TSourceNotebook.StartShowCodeContext(JumpToError: boolean);
var
  Abort: boolean;
begin
  if OnShowCodeContext<>nil then begin
    OnShowCodeContext(JumpToError,Abort);
  end;
end;

Procedure TSourceNotebook.BookMarkSetClicked(Sender: TObject);
// popup menu:  set bookmark clicked
var
  MenuItem: TMenuItem;
Begin
  MenuItem := TMenuItem(sender);
  BookMarkSet(MenuItem.MenuIndex);
end;

Procedure TSourceNotebook.BookMarkGotoClicked(Sender: TObject);
// popup menu goto bookmark clicked
var
  MenuItem: TMenuItem;
Begin
  MenuItem := TMenuItem(sender);
  GotoBookMark(MenuItem.MenuIndex);
end;

Procedure TSourceNotebook.ReadOnlyClicked(Sender: TObject);
var ActEdit:TSourceEditor;
begin
  ActEdit:=GetActiveSE;
  if ActEdit.ReadOnly and (ActEdit.CodeBuffer<>nil)
  and (not ActEdit.CodeBuffer.IsVirtual)
  and (not FileIsWritable(ActEdit.CodeBuffer.Filename)) then begin
    MessageDlg(ueFileROCap,
      ueFileROText1+ActEdit.CodeBuffer.Filename+ueFileROText2,
      mtError,[mbCancel],0);
    exit;
  end;
  ActEdit.EditorComponent.ReadOnly := not(ActEdit.EditorComponent.ReadOnly);
  if Assigned(OnReadOnlyChanged) then
    OnReadOnlyChanged(Self);
  UpdateStatusBar;
end;

procedure TSourceNotebook.OnPopupMenuOpenPasFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.pas'),
    Notebook.PageIndex+1,
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

procedure TSourceNotebook.OnPopupMenuOpenPPFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.pp'),
    Notebook.PageIndex+1,
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

procedure TSourceNotebook.OnPopupMenuOpenLFMFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.lfm'),
    Notebook.PageIndex+1,
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

procedure TSourceNotebook.OnPopupMenuOpenLRSFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.lrs'),
    Notebook.PageIndex+1,
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

Procedure TSourceNotebook.ShowUnitInfo(Sender: TObject);
begin
  if Assigned(FOnShowUnitInfo) then FOnShowUnitInfo(Sender);
end;

Procedure TSourceNotebook.ToggleLineNumbersClicked(Sender: TObject);
var
  MenuITem: TMenuItem;
  ActEdit:TSourceEditor;
  i: integer;
  ShowLineNumbers: boolean;
begin
  MenuItem := TMenuITem(Sender);
  ActEdit:=GetActiveSE;
  MenuItem.Checked := not(ActEdit.EditorComponent.Gutter.ShowLineNumbers);
  ShowLineNumbers:=MenuItem.Checked;
  for i:=0 to EditorCount-1 do
    Editors[i].EditorComponent.Gutter.ShowLineNumbers := ShowLineNumbers;
  EditorOpts.ShowLineNumbers := ShowLineNumbers;
  EditorOpts.Save;
end;

Procedure TSourceNotebook.OpenAtCursorClicked(Sender: TObject);
begin
  if Assigned(FOnOpenFileAtCursorClicked) then
    FOnOpenFileAtCursorClicked(Sender);
end;

Procedure TSourceNotebook.FindDeclarationClicked(Sender: TObject);
begin
  if Assigned(FOnFindDeclarationClicked) then
    FOnFindDeclarationClicked(Sender);
end;

Procedure TSourceNoteBook.CutClicked(Sender: TObject);
var ActSE: TSourceEditor;
begin
  ActSE := GetActiveSE;
  if ActSE <> nil then
    ActSE.DoEditorExecuteCommand(ecCut);
end;

Procedure TSourceNoteBook.CopyClicked(Sender: TObject);
var ActSE: TSourceEditor;
begin
  ActSE := GetActiveSE;
  if ActSE <> nil then
    ActSE.DoEditorExecuteCommand(ecCopy);
end;

Procedure TSourceNoteBook.PasteClicked(Sender: TObject);
var ActSE: TSourceEditor;
begin
  ActSE := GetActiveSE;
  if ActSE <> nil then
    ActSE.DoEditorExecuteCommand(ecPaste);
end;

Procedure TSourceNotebook.BookMarkToggle(Value: Integer);
var
  MenuItem: TMenuItem;
  ActEdit,AnEdit:TSourceEditor;
Begin
  MenuItem := TMenuItem(SetBookmarkMenuItem.Items[Value]);
  MenuItem.Checked := not MenuItem.Checked;
  ActEdit:=GetActiveSE;

  AnEdit:=FindBookmark(Value);
  if AnEdit<>nil then AnEdit.EditorComponent.ClearBookMark(Value);
  if MenuItem.Checked then
    Begin
      ActEdit.EditorComponent.SetBookMark(Value,
         ActEdit.EditorComponent.CaretX,ActEdit.EditorComponent.CaretY);
      MenuItem.Caption := MenuItem.Caption + '*';
    end
  else
    begin
      MenuItem.Caption := copy(MenuItem.Caption,1,Length(MenuItem.Caption)-1);
    end;
end;

procedure TSourceNotebook.MoveEditorLeftClicked(Sender: TObject);
begin
  MoveActivePageLeft;
end;

procedure TSourceNotebook.MoveEditorRightClicked(Sender: TObject);
begin
  MoveActivePageRight;
end;

{This is called from outside to toggle a bookmark}
Procedure TSourceNotebook.ToggleBookmark(Value: Integer);
Begin
  BookMarkToggle(Value);
End;

procedure TSourceNotebook.AddBreakpointClicked(Sender: TObject );
var
  ASrcEdit: TSourceEditor;
begin
  ASrcEdit:=GetActiveSE;
  if ASrcEdit=nil then exit;
  DebugBoss.DoCreateBreakPoint(ASrcEdit.Filename,
                               ASrcEdit.EditorComponent.CaretY);
end;

procedure TSourceNotebook.CompleteCodeMenuItemClick(Sender: TObject);
begin
  MainIDEInterface.DoCommand(ecCompleteCode);
end;

procedure TSourceNotebook.DeleteBreakpointClicked(Sender: TObject);
var
  ASrcEdit: TSourceEditor;
begin
  ASrcEdit:=GetActiveSE;
  if ASrcEdit=nil then exit;
  DebugBoss.DoDeleteBreakPoint(ASrcEdit.Filename,
                               ASrcEdit.EditorComponent.CaretY);
end;

procedure TSourceNotebook.EncloseSelectionMenuItemClick(Sender: TObject);
var
  ASrcEdit: TSourceEditor;
begin
  ASrcEdit:=GetActiveSE;
  if ASrcEdit=nil then exit;
  ASrcEdit.EncloseSelection;
end;

procedure TSourceNotebook.ExtractProcMenuItemClick(Sender: TObject);
begin
  MainIDEInterface.DoCommand(ecExtractProc);
end;

procedure TSourceNotebook.InvertAssignmentMenuItemClick(Sender: TObject);
var
  ASrcEdit: TSourceEditor;
begin
  ASrcEdit:=GetActiveSE;
  if ASrcEdit=nil then exit;
  ASrcEdit.InvertAssignment;
end;

procedure TSourceNotebook.FindIdentifierReferencesMenuItemClick(Sender: TObject
  );
begin
  MainIDEInterface.DoCommand(ecFindIdentifierRefs);
end;

procedure TSourceNotebook.RenameIdentifierMenuItemClick(Sender: TObject);
begin
  MainIDEInterface.DoCommand(ecRenameIdentifier);
end;

procedure TSourceNotebook.RunToClicked(Sender: TObject);
var
  ASrcEdit: TSourceEditor;
begin
  ASrcEdit:=GetActiveSE;
  if ASrcEdit=nil then exit;
  DebugBoss.DoRunToCursor;
end;

procedure TSourceNotebook.ViewCallStackClick(Sender: TObject);
var
  Command: TSynEditorCommand;
  AChar: TUTF8Char;
  Handled: boolean;
begin
  Command:=ecToggleCallStack;
  AChar:=#0;
  Handled:=false;
  ProcessParentCommand(Self,Command,AChar,nil,Handled);
end;

Procedure TSourceNotebook.BookMarkSet(Value: Integer);
var
  MenuItem: TMenuItem;
  ActEdit,AnEdit:TSourceEditor;
Begin
  MenuItem := TMenuItem(SetBookmarkMenuItem.Items[Value]);
  ActEdit:=GetActiveSE;

  AnEdit:=FindBookmark(Value);
  if AnEdit<>nil then begin
    AnEdit.EditorComponent.ClearBookMark(Value);
  end;
  ActEdit.EditorComponent.SetBookMark(Value,
     ActEdit.EditorComponent.CaretX,ActEdit.EditorComponent.CaretY);
  MenuItem.Checked := true;
  GotoBookmarkMenuItem[Value].Checked:=true;
end;

{This is called from outside to set a bookmark}
procedure TSourceNotebook.SetBookmark(Value: Integer);
Begin
  BookMarkSet(Value);
End;

procedure TSourceNotebook.BookmarkGotoNext(GoForward: boolean);
var
  CurBookmarkID: Integer;
  x: Integer;
  y: Integer;
  SrcEdit: TSourceEditor;
  StartY: LongInt;
  CurEditorComponent: TSynEdit;
  StartEditorComponent: TSynEdit;
  BestBookmarkID: Integer;
  BestY: Integer;
  CurPageIndex: Integer;
  CurSrcEdit: TSourceEditor;
  StartPageIndex: LongInt;
  BetterFound: Boolean;
  PageDistance: Integer;
  BestPageDistance: Integer;
begin
  if Notebook=nil then exit;
  SrcEdit:=GetActiveSE;
  if SrcEdit=nil then exit;
  // init best bookmark
  BestBookmarkID:=-1;
  BestY:=-1;
  BestPageDistance:=-1;
  // where is the cursor
  StartPageIndex:=Notebook.PageIndex;
  StartEditorComponent:=SrcEdit.EditorComponent;
  StartY:=StartEditorComponent.CaretY;
  // go through all bookmarks
  for CurPageIndex:=0 to Notebook.PageCount-1 do begin
    CurSrcEdit:=FindSourceEditorWithPageIndex(CurPageIndex);
    CurEditorComponent:=CurSrcEdit.EditorComponent;
    for CurBookmarkID:=0 to 9 do begin
      if CurEditorComponent.GetBookmark(CurBookmarkID,x,y) then begin
        if (CurPageIndex=StartPageIndex) and (y=StartY) then
          continue;

        // for GoForward=true we are searching the nearest bookmark down the
        // current page, then the pages from left to right, starting at the
        // current page. That means the lines above the cursor are the most
        // far away.

        // calculate the distance of pages between the current bookmark
        // and the current page
        PageDistance:=(StartPageIndex-CurPageIndex);
        if GoForward then PageDistance:=-PageDistance;
        if PageDistance<0 then
          // for GoForward=true the pages on the left are farer than the pages
          // on the right (and vice versus)
          inc(PageDistance,Notebook.PageCount);
        if (PageDistance=0) then begin
          // for GoForward=true the lines in front are farer than the pages
          // on the left side
          if (GoForward and (y<StartY))
          or ((not GoForward) and (y>StartY)) then
            inc(PageDistance,Notebook.PageCount);
        end;

        BetterFound:=false;
        if BestBookmarkID<0 then
          BetterFound:=true
        else if PageDistance<BestPageDistance then begin
          BetterFound:=true;
        end else if PageDistance=BestPageDistance then begin
          if (GoForward and (y<BestY))
          or ((not GoForward) and (y>BestY)) then
            BetterFound:=true;
        end;
        //debugln('TSourceNotebook.BookmarkGotoNext GoForward=',dbgs(GoForward),
        //  ' CurBookmarkID=',dbgs(CurBookmarkID),
        //  ' PageDistance=',dbgs(PageDistance),' BestPageDistance='+dbgs(BestPageDistance),
        //  ' y='+dbgs(y),' BestY='+dbgs(BestY),' StartY=',dbgs(StartY),
        //  ' StartPageIndex='+dbgs(StartPageIndex),' CurPageIndex='+dbgs(CurPageIndex),
        //  ' BetterFound='+dbgs(BetterFound));
        
        if BetterFound then begin
          // nearer bookmark found
          BestBookmarkID:=CurBookmarkID;
          BestY:=y;
          BestPageDistance:=PageDistance;
        end;
      end;
    end;
  end;
  if BestBookmarkID>=0 then
    BookMarkGoto(BestBookmarkID);
end;

procedure TSourceNotebook.BookMarkGoto(Index: Integer);
var
  AnEditor:TSourceEditor;
begin
  if Notebook=nil then exit;
  AnEditor:=FindBookmark(Index);
  if AnEditor<>nil then begin
    AnEditor.EditorComponent.GotoBookMark(Index);
    AnEditor.CenterCursor;
    Notebook.PageIndex:=FindPageWithEditor(AnEditor);
  end;
end;

procedure TSourceNotebook.BookMarkNextClicked(Sender: TObject);
begin
  BookmarkGotoNext(true);
end;

procedure TSourceNotebook.BookMarkPrevClicked(Sender: TObject);
begin
  BookmarkGotoNext(false);
end;

{This is called from outside to Go to a bookmark}
Procedure TSourceNotebook.GoToBookmark(Value: Integer);
begin
  BookMarkGoTo(Value);
End;

Procedure TSourceNotebook.NewFile(const NewShortName: String;
  ASource: TCodeBuffer; FocusIt: boolean);
Var
  TempEditor: TSourceEditor;
Begin
  //create a new page
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.NewFile] A ');
  {$ENDIF}
  Visible:=true;
  TempEditor := NewSE(-1);
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.NewFile] B ');
  {$ENDIF}
  TempEditor.CodeBuffer:=ASource;
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.NewFile] D ');
  {$ENDIF}
  TempEditor.PageName:=FindUniquePageName(NewShortName,Notebook.PageIndex);
  if FocusIt then FocusEditor;
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.NewFile] end');
  {$ENDIF}
end;

Procedure TSourceNotebook.CloseFile(PageIndex:integer);
var
  TempEditor: TSourceEditor;
Begin
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.CloseFile A  PageIndex=',PageIndex);
  {$ENDIF}
  TempEditor:=FindSourceEditorWithPageIndex(PageIndex);
  if TempEditor=nil then exit;
  Visible:=true;
  TempEditor.Close;
  TempEditor.Free;
  if Notebook.PageCount>1 then begin
    //writeln('TSourceNotebook.CloseFile B  PageIndex=',PageIndex);
    // if this is the current page, switch to left PageIndex
    if (Notebook.PageIndex=PageIndex) and (PageIndex>0) then
      Notebook.PageIndex:=PageIndex-1;
    // delete the page
    Notebook.Pages.Delete(PageIndex);
    //writeln('TSourceNotebook.CloseFile C  PageIndex=',PageIndex,' Notebook.PageCount=',Notebook.PageCount);
    UpdateStatusBar;
  end else begin
    //writeln('TSourceNotebook.CloseFile D  PageIndex=',PageIndex);
    Notebook.Free;
    //writeln('TSourceNotebook.CloseFile E  PageIndex=',PageIndex);
    Notebook:=nil;
    Hide;
  end;
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.CloseFile END');
  {$ENDIF}
end;

procedure TSourceNotebook.FocusEditor;
var
  SrcEdit: TSourceEditor;
begin
  if (NoteBook=nil) or (fAutoFocusLock>0) then exit;
  SrcEdit:=GetActiveSE;
  if SrcEdit=nil then exit;
  Show;
  SrcEdit.FocusEditor;
end;

Function TSourceNotebook.ActiveFileName: AnsiString;
Begin
  Result := GetActiveSE.FileName;
end;

function TSourceNotebook.GetEditors(Index:integer):TSourceEditor;
begin
  Result:=TSourceEditor(FSourceEditorList[Index]);
end;

function TSourceNotebook.EditorCount:integer;
begin
  Result:=FSourceEditorList.Count;
end;

Procedure TSourceNotebook.CloseClicked(Sender: TObject);
Begin
  if Assigned(FOnCloseClicked) then FOnCloseClicked(Sender);
end;

Function TSourceNotebook.FindUniquePageName(FileName:string;
  IgnorePageIndex:integer):string;
var I:integer;
  ShortName:string;

  function PageNameExists(const AName:string):boolean;
  var a:integer;
  begin
    Result:=false;
    if Notebook=nil then exit;
    for a:=0 to Notebook.PageCount-1 do begin
      if (a<>IgnorePageIndex)
      and (AnsiCompareText(AName,FindSourceEditorWithPageIndex(a).PageName)=0)
      then begin
        Result:=true;
        exit;
      end;
    end;
  end;

begin
  if FileName='' then begin
    FileName:='unit1';
    if not PageNameExists(FileName) then begin
      Result:=Filename;
      exit;
    end;
  end;
  if FilenameIsPascalUnit(FileName) then
    ShortName:=ExtractFileNameOnly(Filename)
  else
    ShortName:=ExtractFileName(FileName);
  Result:=ShortName;
  if PageNameExists(Result) then begin
    i:=1;
    repeat
      inc(i);
      Result:=ShortName+'('+IntToStr(i)+')';
    until PageNameExists(Result)=false;
  end;
end;

procedure TSourceNotebook.ToggleFormUnitClicked(Sender: TObject);
begin
  if Assigned(FOnToggleFormUnitClicked) then FOnToggleFormUnitClicked(Sender);
end;

procedure TSourceNotebook.ToggleObjectInspClicked(Sender: TObject);
begin
  if Assigned(FOnToggleObjectInspClicked) then FOnToggleObjectInspClicked(Sender);
end;

procedure TSourceNotebook.InitFindDialog;
var c: TFindDlgComponent;
begin
  FindReplaceDlg.OnKey:=@FindReplaceDlgKey;
  for c:=Low(TFindDlgComponent) to High(TFindDlgComponent) do
    FindReplaceDlgHistoryIndex[c]:=-1;
end;

Procedure TSourceNotebook.UpdateStatusBar;
var
  tempEditor: TSourceEditor;
  PanelFilename: String;
  PanelCharMode: string;
  PanelXY: string;
  PanelFileMode: string;
  CurEditor: TSynEdit;
begin
  if not Visible then exit;
  TempEditor := GetActiveSE;
  if TempEditor = nil then Exit;
  CurEditor:=TempEditor.EditorComponent;
  
  if (snIncrementalFind in States)
  and (CompareCaret(CurEditor.LogicalCaretXY,FIncrementalSearchPos)<>0) then
  begin
    // some action has changed the cursor during incremental search
    // -> end incremental search
    EndIncrementalFind;
    // this called UpdateStatusBar -> exit
    exit;
  end;

  if (CurEditor.CaretY<>TempEditor.ErrorLine)
  or (CurEditor.CaretX<>TempEditor.fErrorColumn) then
    TempEditor.ErrorLine:=-1;

  Statusbar.BeginUpdate;

  if snIncrementalFind in States then begin
    Statusbar.SimplePanel:=true;
    Statusbar.SimpleText:=Format(lisUESearching, [IncrementalSearchStr]);

  end else begin
    Statusbar.SimplePanel:=false;
    PanelFilename:=TempEditor.Filename;

    If TempEditor.Modified then
      PanelFileMode := ueModified
    else
      PanelFileMode := '';

    If TempEditor.ReadOnly then
      if PanelFileMode <> '' then
        PanelFileMode := Format(lisUEReadOnly, [StatusBar.Panels[1
          ].Text])
      else
        PanelFileMode := uepReadonly;

    PanelXY := Format(' %6d:%4d',
                 [TempEditor.CurrentCursorYLine,TempEditor.CurrentCursorXLine]);

    if GetActiveSE.InsertMode then
      PanelCharMode := uepIns
    else
      PanelCharMode := uepOvr;

    Statusbar.Panels[0].Text := PanelXY;
    StatusBar.Panels[1].Text := PanelFileMode;
    Statusbar.Panels[2].Text := PanelCharMode;
    Statusbar.Panels[3].Text := PanelFilename;
  end;
  Statusbar.EndUpdate;
End;

function TSourceNotebook.FindBookmark(BookmarkID: integer): TSourceEditor;
var i,x,y:integer;
begin
  for i:=0 to EditorCount-1 do begin
    if Editors[i].EditorComponent.GetBookmark(BookMarkID,x,y) then begin
      Result:=Editors[i];
      exit;
    end;
  end;
  Result:=nil;
end;

function TSourceNotebook.FindPageWithEditor(
  ASourceEditor: TSourceEditor):integer;
var i:integer;
begin
  if Notebook=nil then begin
    Result:=-1;
  end else begin
    Result:=Notebook.PageCount-1;
    while (Result>=0) do begin
      with Notebook.Page[Result] do
        for I := 0 to ControlCount-1 do
          if Controls[I]=ASourceEditor.EditorComponent then exit;
      dec(Result);
    end;
  end;
end;

function TSourceNotebook.FindSourceEditorWithEditorComponent(
  EditorComp: TComponent): TSourceEditor;
var i: integer;
begin
  for i:=0 to EditorCount-1 do begin
    Result:=Editors[i];
    if Result.EditorComponent=EditorComp then exit;
  end;
  Result:=nil;
end;

function TSourceNotebook.FindSourceEditorWithFilename(const Filename: string
  ): TSourceEditor;
var i: integer;
begin
  for i:=0 to EditorCount-1 do begin
    Result:=Editors[i];
    if CompareFilenames(Result.Filename,Filename)=0 then exit;
  end;
  Result:=nil;
end;

Procedure TSourceNotebook.NotebookPageChanged(Sender: TObject);
var TempEditor:TSourceEditor;
Begin
  TempEditor:=GetActiveSE;
  //writeln('TSourceNotebook.NotebookPageChanged ',Notebook.Pageindex,' ',TempEditor <> nil,' fAutoFocusLock=',fAutoFocusLock);
  if TempEditor <> nil then
  begin
    if fAutoFocusLock=0 then begin
      {$IFDEF VerboseFocus}
      writeln('TSourceNotebook.NotebookPageChanged BEFORE SetFocus ',
        TempEditor.EditorComponent.Name,' ',
        NoteBook.Pages[FindPageWithEditor(TempEditor)]);
      {$ENDIF}
      TempEditor.FocusEditor;
      {$IFDEF VerboseFocus}
      writeln('TSourceNotebook.NotebookPageChanged AFTER SetFocus ',
        TempEditor.EditorComponent.Name,' ',
        NoteBook.Pages[FindPageWithEditor(TempEditor)]);
      {$ENDIF}
    end;
    UpdateStatusBar;
    UpdateActiveEditColors;
    if Assigned(FOnEditorVisibleChanged) then
      FOnEditorVisibleChanged(sender);
    CheckCurrentCodeBufferChanged;
  end;
end;

Procedure TSourceNotebook.ProcessParentCommand(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer;
  var Handled: boolean);
begin
  FProcessingCommand:=true;
  if Assigned(FOnProcessUserCommand) then begin
    Handled:=false;
    FOnProcessUserCommand(Self,Command,Handled);
    if Handled or (Command=ecNone) then begin
      FProcessingCommand:=false;
      exit;
    end;
  end;

  Handled:=true;
  case Command of

  ecNextEditor:
    NextEditor;

  ecPrevEditor :
    PrevEditor;

  ecMoveEditorLeft:
    MoveActivePageLeft;

  ecMoveEditorRight:
    MoveActivePageRight;

  ecOpenFileAtCursor:
    OpenAtCursorClicked(self);

  ecJumpToEditor:
    Begin
      // This is NOT implemented yet

    end;

  ecGotoEditor1..ecGotoEditor9,ecGotoEditor0:
    if Notebook.PageCount>Command-ecGotoEditor1 then
      Notebook.PageIndex:=Command-ecGotoEditor1;

  ecToggleFormUnit:
    ToggleFormUnitClicked(Self);

  ecToggleObjectInsp:
    ToggleObjectInspClicked(Self);
    
  ecPrevBookmark:
    BookmarkGotoNext(false);

  ecNextBookmark:
    BookmarkGotoNext(true);

  ecGotoMarker0..ecGotoMarker9:
    BookmarkGoto(Command - ecGotoMarker0);

  ecSetMarker0..ecSetMarker9:
    BookmarkSet(Command - ecSetMarker0);

  ecJumpBack:
    HistoryJump(Self,jhaBack);

  ecJumpForward:
    HistoryJump(Self,jhaForward);

  ecAddJumpPoint:
    AddJumpPointClicked(Self);

  ecViewJumpHistory:
    ViewJumpHistoryClicked(Self);

  else
    Handled:=false;
  end;  //case
  if Handled then Command:=ecNone;
  FProcessingCommand:=false;
end;

Procedure TSourceNotebook.ParentCommandProcessed(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer;
  var Handled: boolean);
begin
  if Assigned(FOnUserCommandProcessed) then begin
    Handled:=false;
    FOnUserCommandProcessed(Self,Command,Handled);
    if Handled then exit;
  end;

  Handled:=(Command=ecClose);

  if Handled then Command:=ecNone;
end;

Procedure TSourceNotebook.ReloadEditorOptions;
var
  I: integer;
  h: TLazSyntaxHighlighter;
Begin
  // this reloads the colors for the highlighter and other editor settings.
  for h:=Low(TLazSyntaxHighlighter) to High(TLazSyntaxHighlighter) do
    if Highlighters[h]<>nil then
      EditorOpts.GetHighlighterSettings(Highlighters[h]);
  for I := 0 to FSourceEditorList.Count-1 do
    TSourceEditor(FSourceEditorList.Items[i]).RefreshEditorSettings;

  // reload code templates
  with CodeTemplateModul do begin
    if FileExists(EditorOpts.CodeTemplateFilename) then
      AutoCompleteList.LoadFromFile(EditorOpts.CodeTemplateFilename)
    else
      if FileExists('lazarus.dci') then
        AutoCompleteList.LoadFromFile('lazarus.dci');
    IndentToTokenStart:=EditorOpts.CodeTemplateIndentToTokenStart;
  end;

  EditorOpts.KeyMap.AssignTo(FKeyStrokes,[caSourceEditor]);
  if NoteBook<>nil then begin
    if EditorOpts.ShowTabCloseButtons then
      NoteBook.Options:=NoteBook.Options+[nboShowCloseButtons]
    else
      NoteBook.Options:=NoteBook.Options-[nboShowCloseButtons];
  end;
  
  IdentCompletionTimer.Interval:=EditorOpts.AutoDelayInMSec;
end;

procedure TSourceNotebook.KeyDownBeforeInterface(var Key: Word;
  Shift: TShiftState);
var i, Command: integer;
Begin
  inherited KeyDown(Key,Shift);
  i := FKeyStrokes.FindKeycode(Key, Shift);
  if i>=0 then begin
    Command:=FKeyStrokes[i].Command;
    case Command of

    ecGotoMarker0..ecGotoMarker9:
      begin
        BookMarkGoto(Command - ecGotoMarker0);
        Key:=0;
      end;

    ecSetMarker0..ecSetMarker9:
      begin
        BookMarkSet(Command - ecSetMarker0);
        Key:=0;
      end;

    ecClose:
      begin
        CloseClicked(Self);
        Key:=0;
      end;
    end;
  end;
end;

procedure TSourceNotebook.BeginAutoFocusLock;
begin
  inc(fAutoFocusLock);
end;

procedure TSourceNotebook.EndAutoFocusLock;
begin
  dec(fAutoFocusLock);
end;

Procedure TSourceNotebook.EditorMouseMove(Sender: TObject; Shift: TShiftstate;
  X,Y: Integer);
begin
  // restart hint timer
  FHintTimer.Enabled := False;
  FHintTimer.Enabled := EditorOpts.AutoToolTipSymbTools and Visible;
end;

procedure TSourceNotebook.EditorMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftstate; X, Y: Integer);
begin

end;

Procedure TSourceNotebook.HintTimer(sender: TObject);
var
  MousePos: TPoint;
  AControl: TControl;
begin
  FHintTimer.Enabled := False;
  MousePos := Mouse.CursorPos;
  AControl:=FindLCLControl(MousePos);
  if (AControl=nil) or (GetParentForm(AControl)<>Self) then exit;
  if AControl is TSynEdit then
    ShowSynEditHint(MousePos);
end;

{------------------------------------------------------------------------------
  procedure TSourceNotebook.OnApplicationUserInput(Sender: TObject;
    Msg: Cardinal);
------------------------------------------------------------------------------}
procedure TSourceNotebook.OnApplicationUserInput(Sender: TObject; Msg: Cardinal
  );
begin
  //debugln('TSourceNotebook.OnApplicationUserInput');
  HideHint;
end;

procedure TSourceNotebook.EditorMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftstate; X, Y: Integer);
begin
  if GetKeyShiftState=[ssCtrl] then begin
    // Control+MouseUp = Find Declaration
    if Assigned(FOnCtrlMouseUp) then begin
      FOnCtrlMouseUp(Sender,Button,Shift,X,Y);
    end;
  end;
end;

procedure TSourceNotebook.ShowSynEditHint(const MousePos: TPoint);
var
  EditPos: TPoint;
  ASrcEdit: TSourceEditor;
  ASynEdit: TSynEdit;
  EditCaret: TPoint;
  LineMarks: TSynEditMarks;
  AMark: TSourceMark;
  i: integer;
  HintStr: String;
  CurHint: String;
begin
  // hide other hints
  //debugln('TSourceNotebook.ShowSynEditHint A');
  Application.HideHint;
  //
  ASrcEdit:=GetActiveSE;
  if ASrcEdit=nil then exit;
  ASynEdit:=ASrcEdit.EditorComponent;
  EditPos:=ASynEdit.ScreenToClient(MousePos);
  if not PtInRect(ASynEdit.ClientRect,EditPos) then exit;
  EditCaret:=ASynEdit.PixelsToRowColumn(EditPos);
  if (EditCaret.Y<1) then exit;
  if EditPos.X<ASynEdit.Gutter.Width then begin
    // hint for a gutter item
    if EditorOpts.ShowGutterHints then begin
      ASynEdit.Marks.GetMarksForLine(EditCaret.Y,LineMarks);
      HintStr:='';
      for i:=Low(TSynEditMarks) to High(TSynEditMarks) do begin
        AMark:=TSourceMark(LineMarks[i]);
        if not (AMark is TSourceMark) then continue;
        CurHint:=AMark.GetHint;
        if CurHint='' then continue;
        if HintStr<>'' then HintStr:=HintStr+LineEnding;
        HintStr:=HintStr+CurHint;
      end;
      if HintStr<>'' then
        ActivateHint(MousePos,HintStr);
    end;
  end else begin
    // hint for source
    if Assigned(OnShowHintForSource) then
      OnShowHintForSource(ASrcEdit,EditPos,EditCaret);
  end;
end;

Procedure TSourceNotebook.AddWatchAtCursor(Sender: TObject);
begin
  if Assigned(OnAddWatchAtCursor) then
    OnAddWatchAtCursor(Self);
end;

procedure TSourceNotebook.SetIncrementalSearchStr(const AValue: string);
begin
  if FIncrementalSearchStr=AValue then exit;
  FIncrementalSearchStr:=AValue;
  DoIncrementalSearch;
end;

procedure TSourceNotebook.DoIncrementalSearch;
var
  CurEdit: TSynEdit;
begin
  if snIncrementalFind in States then begin
    Include(States,snIncrementalSearching);
    // search string
    CurEdit:=GetActiveSE.EditorComponent;
    CurEdit.BeginUpdate;
    if fIncrementalSearchStr<>'' then begin
      // search from search start position
      CurEdit.LogicalCaretXY:=fIncrementalSearchStartPos;
      CurEdit.SearchReplace(fIncrementalSearchStr,'',[]);
      CurEdit.LogicalCaretXY:=CurEdit.BlockEnd;
      FIncrementalSearchStr:=CurEdit.SelText;
    end else begin
      // go to start
      CurEdit.LogicalCaretXY:=fIncrementalSearchCancelPos;
      CurEdit.BlockBegin:=CurEdit.LogicalCaretXY;
      CurEdit.BlockEnd:=CurEdit.BlockBegin;
    end;
    FIncrementalSearchPos:=CurEdit.LogicalCaretXY;
    CurEdit.EndUpdate;
    Exclude(States,snIncrementalSearching);
  end;
  UpdateStatusBar;
end;

procedure TSourceNotebook.UpdateActiveEditColors;
var ASynEdit: TSynEdit;
  SrcEDit: TSourceEditor;
begin
  SrcEdit:=GetActiveSe;
  if SrcEdit=nil then exit;
  ASynEdit:=SrcEdit.EditorComponent;
  if ASynEdit=nil then exit;
  FActiveEditDefaultFGColor:=ASynEdit.Font.Color;
  FActiveEditDefaultBGColor:=ASynEdit.Color;
  FActiveEditSelectedFGColor:=ASynEdit.SelectedColor.ForeGround;
  FActiveEditSelectedBGColor:=ASynEdit.SelectedColor.Background;
  FActiveEditKeyFGColor:=FActiveEditDefaultFGColor;
  FActiveEditKeyBGColor:=FActiveEditDefaultBGColor;
  FActiveEditSymbolFGColor:=FActiveEditDefaultFGColor;
  FActiveEditSymbolBGColor:=FActiveEditDefaultBGColor;
  if ASynEdit.Highlighter<>nil then begin
    with ASynEdit.Highlighter do begin
      if IdentifierAttribute<>nil then begin
        if IdentifierAttribute.ForeGround<>clNone then
          FActiveEditDefaultFGColor:=IdentifierAttribute.ForeGround;
        if IdentifierAttribute.BackGround<>clNone then
          FActiveEditDefaultBGColor:=IdentifierAttribute.BackGround;
      end;
      if KeywordAttribute<>nil then begin
        if KeywordAttribute.ForeGround<>clNone then
          FActiveEditKeyFGColor:=KeywordAttribute.ForeGround;
        if KeywordAttribute.BackGround<>clNone then
          FActiveEditKeyBGColor:=KeywordAttribute.BackGround;
      end;
      if SymbolAttribute<>nil then begin
        if SymbolAttribute.ForeGround<>clNone then
          FActiveEditSymbolFGColor:=SymbolAttribute.ForeGround;
        if SymbolAttribute.BackGround<>clNone then
          FActiveEditSymbolBGColor:=SymbolAttribute.BackGround;
      end;
    end;
  end;
end;

Procedure TSourceNotebook.GetSynEditPreviewSettings(APreviewEditor: TObject);
var ASynEdit: TSynEdit;
begin
  if not (APreviewEditor is TSynEdit) then exit;
  ASynEdit:=TSynEdit(APreviewEditor);
  EditorOpts.GetSynEditPreviewSettings(ASynEdit);
  ASynEdit.Highlighter:=Highlighters[lshFreePascal];
end;

procedure TSourceNotebook.ClearErrorLines;
var i: integer;
begin
  for i:=0 to EditorCount-1 do
    Editors[i].ErrorLine:=-1;
end;

procedure TSourceNotebook.ClearExecutionLines;
var i: integer;
begin
  for i:=0 to EditorCount-1 do
    Editors[i].ExecutionLine:=-1;
end;


{ GOTO DIALOG }

Constructor TfrmGoto.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  if LazarusResources.Find(ClassName)=nil then begin
    Position := poScreenCenter;
    Width := 250;
    Height := 100;
    Caption := lisMenuGotoLine;
    BorderStyle:= bsDialog;

    Label1 := TLabel.Create(self);
    with Label1 do
    Begin
      Parent := self;
      Top := 10;
      Left := 5;
      Width:=Self.Width-2*Left;
      Caption := lisUEGotoLine;
      Visible := True;
    end;

    Edit1 := TEdit.Create(self);
    with Edit1 do
    Begin
      Parent := self;
      Top := 30;
      Width := Self.width-40;
      Left := 5;
      Caption := '';
      OnKeyDown:=@Edit1KeyDown;
      Visible := True;
    end;

    btnOK := TBitbtn.Create(self);
    with btnOK do
    Begin
      Name:='btnOK';
      Parent := self;
      Top := 70;
      Left := 40;
      kind := bkOK;
      Default:=false;
      Visible := True;
    end;

    btnCancel := TBitbtn.Create(self);
    with btnCancel do
    Begin
      Name:='btnCancel';
      Parent := self;
      Top := 70;
      Left := 120;
      kind := bkCancel;
      Default:=false;
      Visible := True;
    end;
  end;
  ActiveControl:=Edit1;
end;

procedure TfrmGoto.DoShow;
begin
  Edit1.SelectAll;
  inherited DoShow;
end;

procedure TfrmGoto.Edit1KeyDown(Sender: TObject; var Key:Word;
   Shift:TShiftState);
begin
  if (Key=VK_RETURN) then ModalResult:=mrOk;
  if (Key=VK_ESCAPE) then ModalResult:=mrCancel;
end;

{ TSynEditPlugin1 }

constructor TSynEditPlugin1.Create(AOwner: TCustomSynEdit);
Begin
  inherited Create(AOwner);
end;

procedure TSynEditPlugin1.AfterPaint(ACanvas: TCanvas; AClip: TRect; FirstLine,
  LastLine: integer);
begin
  //don't do anything
end;

procedure TSynEditPlugin1.LinesDeleted(FirstLine, Count: integer);
begin
  if Assigned(OnLinesDeleted) then
    OnLinesDeleted(self,Firstline,Count);
end;

procedure TSynEditPlugin1.LinesInserted(FirstLine, Count: integer);
begin
  if Assigned(OnLinesInserted) then
    OnLinesInserted(self,Firstline,Count);
end;

//-----------------------------------------------------------------------------

procedure InternalInit;
var h: TLazSyntaxHighlighter;
begin
  for h:=Low(TLazSyntaxHighlighter) to High(TLazSyntaxHighlighter) do
    Highlighters[h]:=nil;
  aCompletion:=nil;
  CurCompletionControl:=nil;
  GotoDialog:=nil;
  IdentCompletionTimer:=nil;
  AWordCompletion:=nil;
end;

procedure InternalFinal;
var h: TLazSyntaxHighlighter;
begin
  for h:=Low(TLazSyntaxHighlighter) to High(TLazSyntaxHighlighter) do
    FreeThenNil(Highlighters[h]);
  FreeThenNil(aWordCompletion);
end;


initialization
  InternalInit;

{$I ../images/bookmark.lrs}

finalization
  InternalFinal;

end.

