{
/***************************************************************************
                               SourceEditor.pp
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
unit SourceEditor;

{$mode objfpc}
{$H+}

interface

{$I ide.inc}

uses
  {$IFDEF IDE_MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, Math, Controls, LCLProc, LCLType, LResources, LCLIntf,
  FileUtil, Forms, ComCtrls, Dialogs, StdCtrls, Graphics,
  Translations, ClipBrd, types, Extctrls, Menus, HelpIntfs, LConvEncoding, LDockCtrl,
  // codetools
  BasicCodeTools, CodeBeautifier, CodeToolManager, CodeCache, SourceLog,
  // synedit
  SynEditLines, SynEditStrConst, SynEditTypes, SynEdit, SynRegExpr,
  SynEditHighlighter, SynEditAutoComplete, SynEditKeyCmds, SynCompletion,
  SynEditMiscClasses, SynEditMarkupHighAll, SynEditMarks,
  SynBeautifier, SynEditTextBase, SynPluginTemplateEdit, SynPluginSyncroEdit,
  SynPluginSyncronizedEditBase, SourceSynEditor,
  // Intf
  SrcEditorIntf, MenuIntf, LazIDEIntf, PackageIntf, IDEHelpIntf, IDEImagesIntf,
  ProjectIntf,
  // IDE units
  IDEDialogs, LazarusIDEStrConsts, IDECommands, EditorOptions,
  WordCompletion, FindReplaceDialog, IDEProcs, IDEOptionDefs,
  MacroPromptDlg, TransferMacros, CodeContextForm, SrcEditHintFrm,
  EnvironmentOpts, MsgView, InputHistory, CodeMacroPrompt,
  CodeTemplatesDlg, TodoDlg, TodoList, CodeToolsOptions,
  SortSelectionDlg, EncloseSelectionDlg, ConDef, InvertAssignTool,
  SourceEditProcs, SourceMarks, CharacterMapDlg, SearchFrm,
  FPDocHints, FPDocEditWindow,
  BaseDebugManager, Debugger, MainIntf, GotoFrm;

type
  TSourceNotebook = class;
  TSourceEditorManager = class;

  TNotifyFileEvent = procedure(Sender: TObject; Filename : AnsiString) of object;

  TOnProcessUserCommand = procedure(Sender: TObject;
            Command: word; var Handled: boolean) of object;
  TOnUserCommandProcessed = procedure(Sender: TObject;
            Command: word; var Handled: boolean) of object;

  TOnLinesInsertedDeleted = procedure(Sender : TObject;
             FirstLine,Count : Integer) of Object;
  TPlaceBookMarkEvent = procedure(Sender: TObject; var Mark: TSynEditMark) of object;
  TBookMarkActionEvent = procedure(Sender: TObject; ID: Integer; Toggle: Boolean) of object;

  TCharSet = set of Char;

  { TSynEditPlugin1 }

  TSynEditPlugin1 = class(TSynEditPlugin)
  private
    FEnabled: Boolean;
    FOnLinesInserted : TOnLinesInsertedDeleted;
    FOnLinesDeleted : TOnLinesInsertedDeleted;
  protected
    Procedure LineCountChanged(Sender: TSynEditStrings; AIndex, ACount : Integer);
    function OwnedByEditor: Boolean; override;
  public
    property OnLinesInserted : TOnLinesInsertedDeleted
      read FOnLinesinserted write FOnLinesInserted;
    property OnLinesDeleted : TOnLinesInsertedDeleted
      read FOnLinesDeleted write FOnLinesDeleted;
    property Enabled: Boolean read FEnabled write FEnabled;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TSourceEditCompletion }

  TSourceEditCompletion=class(TSynCompletion)
  private
    FIdentCompletionJumpToError: boolean;
    ccSelection: String;
    // colors for the completion form (popup form, e.g. word completion)
    FActiveEditDefaultFGColor: TColor;
    FActiveEditDefaultBGColor: TColor;
    FActiveEditSelectedFGColor: TColor;
    FActiveEditSelectedBGColor: TColor;

    procedure ccExecute(Sender: TObject);
    procedure ccCancel(Sender: TObject);
    procedure ccComplete(var Value: string; SourceValue: string;
                         var SourceStart, SourceEnd: TPoint;
                         KeyChar: TUTF8Char; Shift: TShiftState);
    function OnSynCompletionPaintItem(const AKey: string; ACanvas: TCanvas;
                 X, Y: integer; ItemSelected: boolean; Index: integer): boolean;
    function OnSynCompletionMeasureItem(const AKey: string; ACanvas: TCanvas;
                                 ItemSelected: boolean; Index: integer): TPoint;
    procedure OnSynCompletionSearchPosition(var APosition: integer);
    procedure OnSynCompletionCompletePrefix(Sender: TObject);
    procedure OnSynCompletionNextChar(Sender: TObject);
    procedure OnSynCompletionPrevChar(Sender: TObject);
    procedure OnSynCompletionKeyPress(Sender: TObject; var Key: Char);
    procedure OnSynCompletionUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
    procedure OnSynCompletionPositionChanged(Sender: TObject);

    function InitIdentCompletionValues(S: TStrings): boolean;
    procedure StartShowCodeHelp;
  protected
    CurrentCompletionType: TCompletionType;
    function Manager: TSourceEditorManager;
  public
    constructor Create(AOwner: TComponent); override;
    property IdentCompletionJumpToError: Boolean
      read FIdentCompletionJumpToError write FIdentCompletionJumpToError;
  end;

  TSourceEditor = class;
  { TSourceEditorSharedValues }

  TSourceEditorSharedValues = class
  private
    FSharedEditorList: TFPList; // list of TSourceEditor sharing one TSynEdit
    function GetOtherSharedEditors(Caller: TSourceEditor; Index: Integer): TSourceEditor;
    function GetSharedEditors(Index: Integer): TSourceEditor;
    function SynEditor: TIDESynEditor;
  public
    procedure AddSharedEditor(AnEditor: TSourceEditor);
    procedure RemoveSharedEditor(AnEditor: TSourceEditor);
    function  SharedEditorCount: Integer;
    function  OtherSharedEditorCount: Integer;
    property  SharedEditors[Index: Integer]: TSourceEditor read GetSharedEditors;
    property  OtherSharedEditors[Caller: TSourceEditor; Index: Integer]: TSourceEditor
              read GetOtherSharedEditors;
  private
    FExecutionMark: TSourceMark;
    FExecutionLine: integer;
    FMarksRequested: Boolean;
  public
    procedure CreateExecutionMark;
    property ExecutionLine: Integer read FExecutionLine write FExecutionLine;
    property ExecutionMark: TSourceMark read FExecutionMark write FExecutionMark;
    property MarksRequested: Boolean read FMarksRequested write FMarksRequested;
  private
    FModified: boolean;
    FIgnoreCodeBufferLock: integer;
    FEditorStampCommitedToCodetools: int64;
    FCodeBuffer: TCodeBuffer;
    function GetModified: Boolean;
    procedure SetCodeBuffer(const AValue: TCodeBuffer);
    procedure SetModified(const AValue: Boolean);
    procedure OnCodeBufferChanged(Sender: TSourceLog; SrcLogEntry: TSourceLogEntry);
  public
    property Modified: Boolean read GetModified write SetModified;
    property  IgnoreCodeBufferLock: Integer read FIgnoreCodeBufferLock;
    procedure IncreaseIgnoreCodeBufferLock;
    procedure DecreaseIgnoreCodeBufferLock;
//    property  EditorStampCommitedToCodetools read
    function NeedsUpdateCodeBuffer: boolean;
    procedure UpdateCodeBuffer;
    property CodeBuffer: TCodeBuffer read FCodeBuffer write SetCodeBuffer;
  protected
    BookmarkEventLock: Integer;
  public
    constructor Create;
    destructor Destroy; override;
  end;

{ TSourceEditor ---
  TSourceEditor is the class that controls access for the Editor. }

  TSourceEditor = class(TSourceEditorInterface)
  private
    //FAOwner is normally a TSourceNotebook.  This is set in the Create constructor.
    FAOwner: TComponent;
    FIsNewSharedEditor: Boolean;
    FSharedValues: TSourceEditorSharedValues;
    FEditor: TIDESynEditor;
    FEditPlugin: TSynEditPlugin1;  // used to get the LinesInserted and
                                   //   LinesDeleted messages
    FSyncroLockCount: Integer;
    FPageName: string;

    FPopUpMenu: TPopupMenu;
    FSyntaxHighlighterType: TLazSyntaxHighlighter;
    FErrorLine: integer;
    FErrorColumn: integer;
    FLineInfoNotification: TIDELineInfoNotification;

    FOnEditorChange: TNotifyEvent;
    FVisible: Boolean;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseDown: TMouseEvent;
    FOnMouseWheel : TMouseWheelEvent;
    FOnKeyDown: TKeyEvent;

    FSourceNoteBook: TSourceNotebook;

    procedure EditorMouseMoved(Sender: TObject; Shift: TShiftState; X,Y:Integer);
    procedure EditorMouseDown(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X,Y: Integer);
    procedure EditorMouseWheel(Sender: TObject; Shift: TShiftState;
         WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditorStatusChanged(Sender: TObject; Changes: TSynStatusChanges);
    procedure EditorPaste(Sender: TObject; var AText: String;
         var AMode: TSynSelectionMode; ALogStartPos: TPoint;
         var AnAction: TSynCopyPasteAction);
    procedure EditorPlaceBookmark(Sender: TObject; var Mark: TSynEditMark);
    procedure EditorClearBookmark(Sender: TObject; var Mark: TSynEditMark);
    procedure EditorEnter(Sender: TObject);
    procedure EditorActivateSyncro(Sender: TObject);
    procedure EditorDeactivateSyncro(Sender: TObject);
    function GetCodeBuffer: TCodeBuffer;
    function GetExecutionLine: integer;
    function GetHasExecutionMarks: Boolean;
    function GetSharedEditors(Index: Integer): TSourceEditor;
    procedure SetCodeBuffer(NewCodeBuffer: TCodeBuffer);
    function GetSource: TStrings;
    procedure SetPageName(const AValue: string);
    procedure UpdateExecutionSourceMark;
    procedure UpdatePageName;
    procedure SetSource(Value: TStrings);
    function GetCurrentCursorXLine: Integer;
    procedure SetCurrentCursorXLine(num : Integer);
    function GetCurrentCursorYLine: Integer;
    procedure SetCurrentCursorYLine(num: Integer);
    Function GetInsertMode: Boolean;
    procedure SetPopupMenu(NewPopupMenu: TPopupMenu);

    function GotoLine(Value: Integer): Integer;

    procedure CreateEditor(AOwner: TComponent; AParent: TWinControl);
    procedure UpdateNoteBook(const ANewNoteBook: TSourceNotebook; ANewPage: TPage);
    procedure SetVisible(Value: boolean);
    procedure UnbindEditor;
  protected
    ErrorMsgs: TStrings;

    procedure ProcessCommand(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
    procedure ProcessUserCommand(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
    procedure UserCommandProcessed(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
    procedure ccAddMessage(Texts: String);
    function AutoCompleteChar(Char: TUTF8Char; var AddChar: boolean;
       Category: TAutoCompleteOption): boolean;
    procedure AutoCompleteBlock;

    procedure FocusEditor;// called by TSourceNotebook when the Notebook page
                          // changes so the editor is focused
    procedure OnGutterClick(Sender: TObject; X, Y, Line: integer;
         mark: TSynEditMark);
    procedure OnEditorSpecialLineColor(Sender: TObject; Line: integer;
         var Special: boolean; Markup: TSynSelectedColor);
    function RefreshEditorSettings: Boolean;
    function GetModified: Boolean; override;
    procedure SetModified(const NewValue: Boolean); override;
    procedure SetSyntaxHighlighterType(
                                 ASyntaxHighlighterType: TLazSyntaxHighlighter);
    procedure SetErrorLine(NewLine: integer);
    procedure SetExecutionLine(NewLine: integer);
    procedure StartIdentCompletionBox(JumpToError: boolean);
    procedure StartWordCompletionBox(JumpToError: boolean);

    procedure LinesInserted(sender: TObject; FirstLine, Count: Integer);
    procedure LinesDeleted(sender: TObject; FirstLine, Count: Integer);

    function GetFilename: string; override;
    function GetEditorControl: TWinControl; override;
    function GetCodeToolsBuffer: TObject; override;
    Function GetReadOnly: Boolean; override;
    procedure SetReadOnly(const NewValue: boolean); override;

    function Manager: TSourceEditorManager;
    property Visible: Boolean read FVisible write SetVisible default False;
    function IsSharedWith(AnOtherEditor: TSourceEditor): Boolean;
  public
    constructor Create(AOwner: TComponent; AParent: TWinControl; ASharedEditor: TSourceEditor = nil);
    destructor Destroy; override;
    function Close: Boolean;

    // codebuffer
    procedure BeginUndoBlock; override;
    procedure EndUndoBlock; override;
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    procedure IncreaseIgnoreCodeBufferLock; override;
    procedure DecreaseIgnoreCodeBufferLock; override;
    procedure UpdateCodeBuffer; override;// copy the source from EditorComponent
    function NeedsUpdateCodeBuffer: boolean; override;

    // find
    procedure StartFindAndReplace(Replace:boolean);
    procedure AskReplace(Sender: TObject; const ASearch, AReplace:
       string; Line, Column: integer; var Action: TSrcEditReplaceAction); override;
    procedure OnReplace(Sender: TObject; const ASearch, AReplace:
       string; Line, Column: integer; var Action: TSynReplaceAction);
    function DoFindAndReplace: Integer;
    procedure FindNextUTF8;
    procedure FindPrevious;
    procedure FindNextWordOccurrence(DirectionForward: boolean);
    procedure ShowGotoLineDialog;

    // dialogs
    procedure GetDialogPosition(Width, Height: integer; out Left, Top: integer);
    procedure ActivateHint(ClientPos: TPoint;
                           const BaseURL, TheHint: string);

    // selections
    function SelectionAvailable: boolean; override;
    function GetText(OnlySelection: boolean): string; override;
    procedure SelectText(const StartPos, EndPos: TPoint); override;
    procedure ReplaceLines(StartLine, EndLine: integer; const NewText: string); override;
    procedure EncloseSelection;
    procedure UpperCaseSelection;
    procedure LowerCaseSelection;
    procedure TabsToSpacesInSelection;
    procedure CommentSelection;
    procedure UncommentSelection;
    procedure ToggleCommentSelection;
    procedure UpdateCommentSelection(CommentOn, Toggle: Boolean);
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
    procedure InsertLicenseNotice(const Notice: string; CommentType: TCommentType);
    procedure InsertGPLNotice(CommentType: TCommentType);
    procedure InsertLGPLNotice(CommentType: TCommentType);
    procedure InsertModifiedLGPLNotice(CommentType: TCommentType);
    procedure InsertUsername;
    procedure InsertTodo;
    procedure InsertDateTime;
    procedure InsertChangeLogEntry;
    procedure InsertCVSKeyword(const AKeyWord: string);
    function GetSelEnd: Integer; override;
    function GetSelStart: Integer; override;
    procedure SetSelEnd(const AValue: Integer); override;
    procedure SetSelStart(const AValue: Integer); override;
    function GetSelection: string; override;
    procedure SetSelection(const AValue: string); override;
    procedure CopyToClipboard; override;
    procedure CutToClipboard; override;

    // context help
    procedure FindHelpForSourceAtCursor;

    // editor commands
    procedure DoEditorExecuteCommand(EditorCommand: word);

    // used to get the word at the mouse cursor
    function GetWordFromCaret(const ACaretPos: TPoint): String;
    function GetWordAtCurrentCaret: String;
    function GetOperandFromCaret(const ACaretPos: TPoint): String;
    function GetOperandAtCurrentCaret: String;
    function CaretInSelection(const ACaretPos: TPoint): Boolean;

    // cursor
    procedure CenterCursor;
    function TextToScreenPosition(const Position: TPoint): TPoint; override;
    function ScreenToTextPosition(const Position: TPoint): TPoint; override;
    function ScreenToPixelPosition(const Position: TPoint): TPoint; override;
    function GetCursorScreenXY: TPoint; override;
    function GetCursorTextXY: TPoint; override;
    procedure SetCursorScreenXY(const AValue: TPoint); override;
    procedure SetCursorTextXY(const AValue: TPoint); override;
    function GetBlockBegin: TPoint; override;
    function GetBlockEnd: TPoint; override;
    procedure SetBlockBegin(const AValue: TPoint); override;
    procedure SetBlockEnd(const AValue: TPoint); override;
    function GetTopLine: Integer; override;
    procedure SetTopLine(const AValue: Integer); override;
    function CursorInPixel: TPoint; override;

    // text
    function SearchReplace(const ASearch, AReplace: string;
                           SearchOptions: TSrcEditSearchOptions): integer; override;
    function GetSourceText: string; override;
    procedure SetSourceText(const AValue: string); override;
    function LineCount: Integer; override;
    function WidthInChars: Integer; override;
    function HeightInLines: Integer; override;
    function CharWidth: integer; override;
    function GetLineText: string; override;
    procedure SetLineText(const AValue: string); override;
    function GetLines: TStrings; override;
    procedure SetLines(const AValue: TStrings); override;

    // context
    function GetProjectFile: TLazProjectFile; override;
    procedure UpdateProjectFile; override;
    function GetDesigner(LoadForm: boolean): TIDesigner; override;

    // notebook
    procedure Activate;
    function PageIndex: integer;
    function IsActiveOnNoteBook: boolean;

    // debugging
    procedure FillExecutionMarks;
    procedure ClearExecutionMarks;
    procedure LineInfoNotificationChange(const ASender: TObject; const ASource: String);
    function  SourceToDebugLine(aLinePos: Integer): Integer;
    function  DebugToSourceLine(aLinePos: Integer): Integer;
  public
    // properties
    property CodeBuffer: TCodeBuffer read GetCodeBuffer write SetCodeBuffer;
    property CurrentCursorXLine: Integer
       read GetCurrentCursorXLine write SetCurrentCursorXLine;
    property CurrentCursorYLine: Integer
       read GetCurrentCursorYLine write SetCurrentCursorYLine;
    property EditorComponent: TIDESynEditor read FEditor;
    property ErrorLine: integer read FErrorLine write SetErrorLine;
    property ExecutionLine: integer read GetExecutionLine write SetExecutionLine;
    property HasExecutionMarks: Boolean read GetHasExecutionMarks;
    property InsertMode: Boolean read GetInsertmode;
    property OnEditorChange: TNotifyEvent read FOnEditorChange
                                          write FOnEditorChange;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseWheel: TMouseWheelEvent read FOnMouseWheel write FOnMouseWheel;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property Owner: TComponent read FAOwner;
    property PageName: string read FPageName write SetPageName;
    property PopupMenu: TPopupMenu read FPopUpMenu write SetPopUpMenu;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property Source: TStrings read GetSource write SetSource;
    property SourceNotebook: TSourceNotebook read FSourceNoteBook;
    property SyntaxHighlighterType: TLazSyntaxHighlighter
       read fSyntaxHighlighterType write SetSyntaxHighlighterType;
    property SyncroLockCount: Integer read FSyncroLockCount;
    function SharedEditorCount: Integer;
    property SharedEditors[Index: Integer]: TSourceEditor read GetSharedEditors;
    property IsNewSharedEditor: Boolean read FIsNewSharedEditor write FIsNewSharedEditor;
  end;

  //============================================================================

  { TSourceNotebook }

  TJumpHistoryAction = (jhaBack, jhaForward, jhaViewWindow);

  TOnJumpToHistoryPoint = procedure(var NewCaretXY: TPoint;
                                    var NewTopLine: integer;
                                    var DestEditor: TSourceEditor;
                                    Action: TJumpHistoryAction) of object;
  TOnAddJumpPoint = procedure(ACaretXY: TPoint; ATopLine: integer;
                  AEditor: TSourceEditor; DeleteForwardHistory: boolean) of object;
  TOnMovingPage = procedure(Sender: TObject;
                            OldPageIndex, NewPageIndex: integer) of object;
  TOnCloseSrcEditor = procedure(Sender: TObject; InvertedClose: boolean) of object;
  TOnShowHintForSource = procedure(SrcEdit: TSourceEditor; ClientPos: TPoint;
                                   CaretPos: TPoint) of object;
  TOnInitIdentCompletion = procedure(Sender: TObject; JumpToError: boolean;
                                     out Handled, Abort: boolean) of object;
  TSrcEditPopupMenuEvent = procedure(const AddMenuItemProc: TAddMenuItemProc
                                     ) of object;
  TOnShowCodeContext = procedure(JumpToError: boolean;
                                 out Abort: boolean) of object;
  TOnGetIndentEvent = function(Sender: TObject; Editor: TSourceEditor;
      LogCaret, OldLogCaret: TPoint; FirstLinePos, LinesCount: Integer;
      Reason: TSynEditorCommand; SetIndentProc: TSynBeautifierSetIndentProc
     ): boolean of object;

  TSourceNotebookState = (
    snIncrementalFind,
    snWarnedFont
    );
  TSourceNotebookStates = set of TSourceNotebookState;

  TDragMoveTabEvent = procedure(Sender, Source: TObject; OldIndex, NewIndex: Integer; CopyDrag: Boolean) of object;
  TDragMoveTabQuery = function(Sender, Source: TObject; OldIndex, NewIndex: Integer; CopyDrag: Boolean): Boolean of object;

  { TSourceDragableNotebook }

  TSourceDragableNotebook = class(TNoteBook)
  private
    FMouseDownTabIndex: Integer;
    FOnCanDragMoveTab: TDragMoveTabQuery;
    FOnDragMoveTab: TDragMoveTabEvent;
    FTabDragged: boolean;

    FDragOverIndex: Integer;
    FDragToRightSide: Boolean;
    FDragOverTabRect, FDragNextToTabRect: TRect;

  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,
             Y: Integer); override;
    procedure DragOver(Source: TObject; X, Y: Integer; State: TDragState;
      var Accept: Boolean); override;
    procedure DragCanceled; override;
    property MouseDownTabIndex: Integer read FMouseDownTabIndex;
    procedure PaintWindow(DC: HDC); override;
    procedure InitDrag;
  public
    constructor Create(TheOwner: TComponent); override;
    procedure DragDrop(Source: TObject; X, Y: Integer); override;
    property  OnDragMoveTab: TDragMoveTabEvent read FOnDragMoveTab write FOnDragMoveTab;
    property  OnCanDragMoveTab: TDragMoveTabQuery read FOnCanDragMoveTab write FOnCanDragMoveTab;
  end;

  { TSourceNotebook }

  TSourceNotebook = class(TSourceEditorWindowInterface)
    StatusBar: TStatusBar;
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StatusBarDblClick(Sender: TObject);
  private
    FNotebook: TSourceDragableNotebook;
    FIsClosing: Boolean;
    SrcPopUpMenu: TPopupMenu;
  protected
    procedure CompleteCodeMenuItemClick(Sender: TObject);
    procedure EncloseSelectionMenuItemClick(Sender: TObject);
    procedure ExtractProcMenuItemClick(Sender: TObject);
    procedure InvertAssignmentMenuItemClick(Sender: TObject);
    procedure FindIdentifierReferencesMenuItemClick(Sender: TObject);
    procedure RenameIdentifierMenuItemClick(Sender: TObject);
    procedure ShowAbstractMethodsMenuItemClick(Sender: TObject);
    procedure ShowEmptyMethodsMenuItemClick(Sender: TObject);
    procedure ShowUnusedUnitsMenuItemClick(Sender: TObject);
    procedure FindOverloadsMenuItemClick(Sender: TObject);
    procedure RunToClicked(Sender: TObject);
    procedure ViewCallStackClick(Sender: TObject);
    procedure EditorPropertiesClicked(Sender: TObject);
    procedure LineEndingClicked(Sender: TObject);
    procedure EncodingClicked(Sender: TObject);
    procedure HighlighterClicked(Sender: TObject);
    procedure FindDeclarationClicked(Sender: TObject);
    procedure ProcedureJumpClicked(Sender: TObject);
    procedure FindNextWordOccurrenceClicked(Sender: TObject);
    procedure FindPrevWordOccurrenceClicked(Sender: TObject);
    procedure FindInFilesClicked(Sender: TObject);
    procedure InsertTodoClicked(Sender: TObject);
    procedure MoveEditorLeftClicked(Sender: TObject);
    procedure MoveEditorRightClicked(Sender: TObject);
    procedure MoveEditorFirstClicked(Sender: TObject);
    procedure MoveEditorLastClicked(Sender: TObject);
    procedure DockingClicked(Sender: TObject);
    procedure NotebookPageChanged(Sender: TObject);
    procedure NotebookShowTabHint(Sender: TObject; HintInfo: PHintInfo);
    procedure OpenAtCursorClicked(Sender: TObject);
    procedure ReadOnlyClicked(Sender: TObject);
    procedure OnPopupMenuOpenPasFile(Sender: TObject);
    procedure OnPopupMenuOpenPPFile(Sender: TObject);
    procedure OnPopupMenuOpenPFile(Sender: TObject);
    procedure OnPopupMenuOpenLFMFile(Sender: TObject);
    procedure OnPopupMenuOpenLRSFile(Sender: TObject);
    procedure OnPopupMenuOpenSFile(Sender: TObject);
    procedure OnPopupMenuOpenFile(Sender: TObject);
    procedure ShowUnitInfo(Sender: TObject);
    procedure SrcPopUpMenuPopup(Sender: TObject);
    procedure ToggleLineNumbersClicked(Sender: TObject);
    procedure InsertCharacter(const C: TUTF8Char);
    procedure SrcEditMenuCopyToNewWindowClicked(Sender: TObject);
    procedure SrcEditMenuCopyToExistingWindowClicked(Sender: TObject);
    procedure SrcEditMenuMoveToNewWindowClicked(Sender: TObject);
    procedure SrcEditMenuMoveToExistingWindowClicked(Sender: TObject);
  public
    procedure DeleteBreakpointClicked(Sender: TObject);
    procedure ToggleBreakpointClicked(Sender: TObject);
  private
    FManager: TSourceEditorManager;
    FUpdateLock, FFocusLock: Integer;
    FPageIndex: Integer;
    fAutoFocusLock: integer;
    FIncrementalSearchPos: TPoint; // last set position
    fIncrementalSearchStartPos: TPoint; // position where to start searching
    FIncrementalSearchStr, FIncrementalFoundStr: string;
    FIncrementalSearchBackwards : Boolean;
    FIncrementalSearchEditor: TSourceEditor; // editor with active search (MWE:shouldnt all FIncrementalSearch vars go to that editor ?)
    FKeyStrokes: TSynEditKeyStrokes;
    FLastCodeBuffer: TCodeBuffer;
    FProcessingCommand: boolean;
    FSourceEditorList: TList; // list of TSourceEditor
  private
    // PopupMenu
    procedure BuildPopupMenu;
    procedure AssignPopupMenu;
    //forwarders to FNoteBook
    function GetNoteBookPage(Index: Integer): TPage;
    function GetNotebookPages: TStrings;
    function GetPageCount: Integer;
    function GetPageIndex: Integer;
    procedure SetPageIndex(const AValue: Integer);

    procedure UpdateHighlightMenuItems;
    procedure UpdateLineEndingMenuItems;
    procedure UpdateEncodingMenuItems;
    procedure RemoveUserDefinedMenuItems;
    function AddUserDefinedPopupMenuItem(const NewCaption: string;
                                     const NewEnabled: boolean;
                                     const NewOnClick: TNotifyEvent): TIDEMenuItem;
    procedure RemoveContextMenuItems;
    function AddContextPopupMenuItem(const NewCaption: string;
                                     const NewEnabled: boolean;
                                     const NewOnClick: TNotifyEvent): TIDEMenuItem;

    // Incremental Search
    procedure UpdateActiveEditColors(AEditor: TSynEdit);
    procedure SetIncrementalSearchStr(const AValue: string);
    procedure IncrementalSearch(ANext, ABackward: Boolean);
    procedure UpdatePageNames;
    procedure UpdateProjectFiles;

  protected
    States: TSourceNotebookStates;
    // hintwindow stuff
    FHintWindow: THintWindow;
    FMouseHintTimer: TIdleTimer;

    procedure Activate; override;
    procedure CreateNotebook;
    function NewSE(Pagenum: Integer; NewPagenum: Integer = -1; ASharedEditor: TSourceEditor = nil): TSourceEditor;
    procedure AcceptEditor(AnEditor: TSourceEditor);
    procedure ReleaseEditor(AnEditor: TSourceEditor);
    procedure EditorChanged(Sender: TObject);
    procedure DoClose(var CloseAction: TCloseAction); override;

    function IndexOfEditorInShareWith(AnOtherEditor: TSourceEditor): Integer;
  protected
    function GetActiveCompletionPlugin: TSourceEditorCompletionPlugin; override;
    function GetCompletionPlugins(Index: integer): TSourceEditorCompletionPlugin; override;
    function GetCompletionBoxPosition: integer; override;
        deprecated {$IFDEF VER2_5}'use SourceEditorManager'{$ENDIF};       // deprecated in 0.9.29 March 2010

    procedure EditorMouseMove(Sender: TObject; Shift: TShiftstate;
                              X,Y: Integer);
    procedure EditorMouseDown(Sender: TObject; Button: TMouseButton;
                              Shift: TShiftstate; X,Y: Integer);
    function EditorGetIndent(Sender: TObject; Editor: TObject;
             LogCaret, OldLogCaret: TPoint; FirstLinePos, LastLinePos: Integer;
             Reason: TSynEditorCommand;
             SetIndentProc: TSynBeautifierSetIndentProc): Boolean;
    procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditorMouseWheel(Sender: TObject; Shift: TShiftState;
         WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);

    procedure NotebookMouseDown(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X,Y: Integer);
    procedure NotebookDragTabMove(Sender, Source: TObject;
                                  OldIndex, NewIndex: Integer; CopyDrag: Boolean);
    function  NotebookCanDragTabMove(Sender, Source: TObject;
                                  OldIndex, NewIndex: Integer; CopyDrag: Boolean): Boolean;

    // hintwindow stuff
    procedure HintTimer(Sender: TObject);
    procedure OnApplicationUserInput(Sender: TObject; Msg: Cardinal);
    procedure ShowSynEditHint(const MousePos: TPoint);

    procedure NextEditor;
    procedure PrevEditor;
    procedure MoveEditor(OldPageIndex, NewPageIndex: integer);
    procedure MoveEditorLeft(CurrentPageIndex: integer);
    procedure MoveEditorRight(CurrentPageIndex: integer);
    procedure MoveActivePageLeft;
    procedure MoveActivePageRight;
    procedure MoveEditorFirst(CurrentPageIndex: integer);
    procedure MoveEditorLast(CurrentPageIndex: integer);
    procedure MoveActivePageFirst;
    procedure MoveActivePageLast;
    procedure GotoNextWindow(Backward: Boolean = False);
    procedure GotoNextSharedEditor(Backward: Boolean = False);
    procedure MoveEditorNextWindow(Backward: Boolean = False; Copy: Boolean = False);
    procedure MoveEditor(OldPageIndex, NewWindowIndex, NewPageIndex: integer);
    procedure CopyEditor(OldPageIndex, NewWindowIndex, NewPageIndex: integer);
    procedure ProcessParentCommand(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer;
       var Handled: boolean);
    procedure ParentCommandProcessed(Sender: TObject;
       var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer;
       var Handled: boolean);

    function GetActiveEditor: TSourceEditorInterface; override;
    procedure SetActiveEditor(const AValue: TSourceEditorInterface); override;
    function GetItems(Index: integer): TSourceEditorInterface; override;
    function GetEditors(Index:integer): TSourceEditor;

    property Manager: TSourceEditorManager read FManager;

    procedure KeyDownBeforeInterface(var Key: Word; Shift: TShiftState); override;

    procedure BeginAutoFocusLock;
    procedure EndAutoFocusLock;
  public
    ControlDocker: TLazControlDocker;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Editors[Index:integer]:TSourceEditor read GetEditors; // !!! not ordered for PageIndex
    function EditorCount: integer;
    function IndexOfEditor(aEditor: TSourceEditorInterface): integer;
    function Count: integer; override;

    function FindSourceEditorWithPageIndex(APageIndex:integer):TSourceEditor;
    function FindPageWithEditor(ASourceEditor: TSourceEditor):integer;
    function FindSourceEditorWithEditorComponent(
                                         EditorComp: TComponent): TSourceEditor;
    function GetActiveSE: TSourceEditor;                                        { $note deprecate and use SetActiveEditor}
    procedure CheckCurrentCodeBufferChanged;

    procedure UpdateStatusBar;
    procedure ClearErrorLines; override;
    procedure ClearExecutionLines;
    procedure ClearExecutionMarks;

    procedure CloseTabClicked(Sender: TObject);
    procedure CloseClicked(Sender: TObject);
    procedure CloseOtherPagesClicked(Sender: TObject);
    procedure ToggleFormUnitClicked(Sender: TObject);
    procedure ToggleObjectInspClicked(Sender: TObject);

    // incremental find
    procedure BeginIncrementalFind;
    procedure EndIncrementalFind;
    property IncrementalSearchStr: string
      read FIncrementalSearchStr write SetIncrementalSearchStr;

    // hints
    procedure ActivateHint(const ScreenPos: TPoint;
                           const BaseURL, TheHint: string);
    procedure HideHint;
    procedure StartShowCodeContext(JumpToError: boolean);

    // new, close, focus
    function NewFile(const NewShortName: String; ASource: TCodeBuffer;
                      FocusIt: boolean; AShareEditor: TSourceEditor = nil): TSourceEditor;
    procedure CloseFile(APageIndex:integer);
    procedure FocusEditor;

    // paste and copy
    procedure CutClicked(Sender: TObject);
    procedure CopyClicked(Sender: TObject);
    procedure PasteClicked(Sender: TObject);
    procedure CopyFilenameClicked(Sender: TObject);

    procedure ReloadEditorOptions;
    procedure CheckFont;
    function GetEditorControlSettings(EditControl: TControl): boolean; override;
             deprecated {$IFDEF VER2_5}'use SourceEditorManager'{$ENDIF};       // deprecated in 0.9.29 March 2010
    function GetHighlighterSettings(Highlighter: TObject): boolean; override;
             deprecated {$IFDEF VER2_5}'use SourceEditorManager'{$ENDIF};       // deprecated in 0.9.29 March 2010

    procedure DeactivateCompletionForm; override;
             deprecated {$IFDEF VER2_5}'use SourceEditorManager'{$ENDIF};       // deprecated in 0.9.29 March 2010
    function CompletionPluginCount: integer; override;
              deprecated {$IFDEF VER2_5}'use SourceEditorManager'{$ENDIF};       // deprecated in 0.9.29 March 2010
    procedure RegisterCompletionPlugin(Plugin: TSourceEditorCompletionPlugin); override;
              deprecated {$IFDEF VER2_5}'use SourceEditorManager'{$ENDIF};       // deprecated in 0.9.29 March 2010
    procedure UnregisterCompletionPlugin(Plugin: TSourceEditorCompletionPlugin); override;
              deprecated {$IFDEF VER2_5}'use SourceEditorManager'{$ENDIF};       // deprecated in 0.9.29 March 2010

    function GetCapabilities: TNoteBookCapabilities;
    procedure IncUpdateLock;
    procedure DecUpdateLock;

    // forwarders to the FNotebook
    property PageIndex: Integer read GetPageIndex write SetPageIndex;
    property PageCount: Integer read GetPageCount;
    property NotebookPages: TStrings read GetNotebookPages;
  private
    property NoteBookPage[Index: Integer]: TPage read GetNoteBookPage;
    procedure NoteBookInsertPage(Index: Integer; const S: string);
    procedure NoteBookDeletePage(Index: Integer);
  protected
    function NoteBookIndexOfPage(APage: TPage): Integer;
  end;

  { TSourceEditorManagerBase }
  (* Implement all Methods with the Interface types *)

  TSourceEditorManagerBase = class(TSourceEditorManagerInterface)
  private
    FActiveWindow: TSourceNotebook;
    FSourceWindowList: TFPList;
    FUpdateLock: Integer;
    FShowWindowOnTop: Boolean;
    FShowWindowOnTopFocus: Boolean;
    procedure FreeSourceWindows;
    function GetActiveSourceWindowIndex: integer;
    procedure SetActiveSourceWindowIndex(const AValue: integer);
  protected
    FChangeNotifyLists: Array [TsemChangeReason] of TMethodList;
    function  GetActiveSourceWindow: TSourceEditorWindowInterface; override;
    procedure SetActiveSourceWindow(const AValue: TSourceEditorWindowInterface); override;
    function  GetSourceWindows(Index: integer): TSourceEditorWindowInterface; override;
    function  GetActiveEditor: TSourceEditorInterface; override;
    procedure SetActiveEditor(const AValue: TSourceEditorInterface); override;
    function  GetSourceEditors(Index: integer): TSourceEditorInterface; override;
    function  GetUniqueSourceEditors(Index: integer): TSourceEditorInterface; override;
  public
    // Windows
    function SourceWindowWithEditor(const AEditor: TSourceEditorInterface): TSourceEditorWindowInterface;
              override;
    function  SourceWindowCount: integer; override;
    function  IndexOfSourceWindow(AWindow: TSourceEditorWindowInterface): integer;
    property  ActiveSourceWindowIndex: integer
              read GetActiveSourceWindowIndex write SetActiveSourceWindowIndex;
    // Editors
    function  SourceEditorIntfWithFilename(const Filename: string): TSourceEditorInterface;
              override;
    function  SourceEditorCount: integer; override;
    function  UniqueSourceEditorCount: integer; override;
    // Settings
    function  GetEditorControlSettings(EditControl: TControl): boolean; override;
    function  GetHighlighterSettings(Highlighter: TObject): boolean; override;
  private
    // Completion Plugins
    FCompletionPlugins: TFPList;
    FDefaultCompletionForm: TSourceEditCompletion;
    FActiveCompletionPlugin: TSourceEditorCompletionPlugin;
    function GetDefaultCompletionForm: TSourceEditCompletion;
    procedure  FreeCompletionPlugins;
  protected
    function  GetActiveCompletionPlugin: TSourceEditorCompletionPlugin; override;
    function  GetCompletionBoxPosition: integer; override;
    function  GetCompletionPlugins(Index: integer): TSourceEditorCompletionPlugin; override;
    function FindIdentCompletionPlugin(SrcEdit: TSourceEditor; JumpToError: boolean;
                               var s: string; var BoxX, BoxY: integer;
                               var UseWordCompletion: boolean): boolean;
    property DefaultCompletionForm: TSourceEditCompletion
      read GetDefaultCompletionForm;
  public
    // Completion Plugins
    function  CompletionPluginCount: integer; override;
    procedure DeactivateCompletionForm; override;
    procedure RegisterCompletionPlugin(Plugin: TSourceEditorCompletionPlugin); override;
    procedure UnregisterCompletionPlugin(Plugin: TSourceEditorCompletionPlugin); override;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RegisterChangeEvent(AReason: TsemChangeReason; AHandler: TNotifyEvent); override;
    procedure UnRegisterChangeEvent(AReason: TsemChangeReason; AHandler: TNotifyEvent); override;
  public
    procedure IncUpdateLock;
    procedure DecUpdateLock;
    procedure ShowActiveWindowOnTop(Focus: Boolean = False);
    procedure UpdateFPDocEditor;
  private
    FOnEditorVisibleChanged: TNotifyEvent;
    FOnCurrentCodeBufferChanged: TNotifyEvent;
  public
    property OnEditorVisibleChanged: TNotifyEvent
             read FOnEditorVisibleChanged write FOnEditorVisibleChanged;
    property OnCurrentCodeBufferChanged: TNotifyEvent
             read FOnCurrentCodeBufferChanged write FOnCurrentCodeBufferChanged;
  end;

  { TSourceEditorManager }
  (* Reintroduce all Methods with the final types *)

  TSourceEditorManager = class(TSourceEditorManagerBase)
  private
    function GetActiveSourceNotebook: TSourceNotebook;
    function GetActiveSrcEditor: TSourceEditor;
    function GetSourceEditorsByPage(WindowIndex, PageIndex: integer
      ): TSourceEditor;
    function GetSrcEditors(Index: integer): TSourceEditor;
    procedure SetActiveSourceNotebook(const AValue: TSourceNotebook);
    function GetSourceNotebook(Index: integer): TSourceNotebook;
    procedure SetActiveSrcEditor(const AValue: TSourceEditor);
  public
    // Windows
    function  SourceWindowWithEditor(const AEditor: TSourceEditorInterface): TSourceNotebook;
              reintroduce;
    property  SourceWindows[Index: integer]: TSourceNotebook read GetSourceNotebook; // reintroduce
    property  ActiveSourceWindow: TSourceNotebook
              read GetActiveSourceNotebook write SetActiveSourceNotebook;       // reintroduce
    function  ActiveOrNewSourceWindow: TSourceNotebook;
    function  NewSourceWindow: TSourceNotebook;
    function  SourceWindowWithPage(const APage: TPage): TSourceNotebook;
    // Editors
    function  SourceEditorCount: integer; override;
    function  GetActiveSE: TSourceEditor;                                       { $note deprecate and use ActiveEditor}
    property  ActiveEditor: TSourceEditor read GetActiveSrcEditor  write SetActiveSrcEditor; // reintroduced
    property SourceEditors[Index: integer]: TSourceEditor read GetSrcEditors;   // reintroduced
    property  SourceEditorsByPage[WindowIndex, PageIndex: integer]: TSourceEditor
              read GetSourceEditorsByPage;
    function  SourceEditorIntfWithFilename(const Filename: string): TSourceEditor; reintroduce;
    function FindSourceEditorWithEditorComponent(EditorComp: TComponent): TSourceEditor; // With SynEdit
  protected
    procedure NewEditorCreated(AEditor: TSourceEditor);
    procedure EditorRemoved(AEditor: TSourceEditor);
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure RemoveWindow(AWindow: TSourceNotebook);
  public
    // Forward to all windows
    procedure ClearErrorLines; override;
    procedure ClearExecutionLines;
    procedure ClearExecutionMarks;
    procedure FillExecutionMarks;
    procedure ReloadEditorOptions;
    // find / replace text
    procedure FindClicked(Sender: TObject);
    procedure FindNextClicked(Sender: TObject);
    procedure FindPreviousClicked(Sender: TObject);
    procedure ReplaceClicked(Sender: TObject);
    procedure IncrementalFindClicked(Sender: TObject);
    procedure GotoLineClicked(Sender: TObject);
    procedure JumpBackClicked(Sender: TObject);
    procedure JumpForwardClicked(Sender: TObject);
    procedure AddJumpPointClicked(Sender: TObject);
    procedure DeleteLastJumpPointClicked(Sender: TObject);
    procedure ViewJumpHistoryClicked(Sender: TObject);
  protected
    // Bookmarks
    procedure BookMarkSetFreeClicked(Sender: TObject);
    procedure BookMarkToggleClicked(Sender: TObject);
    procedure BookMarkGotoClicked(Sender: TObject);
  public
    procedure BookMarkNextClicked(Sender: TObject);
    procedure BookMarkPrevClicked(Sender: TObject);
  protected
    // macros
    function MacroFuncCol(const s:string; const Data: PtrInt;
                          var Abort: boolean): string;
    function MacroFuncRow(const s:string; const Data: PtrInt;
                          var Abort: boolean): string;
    function MacroFuncEdFile(const s:string; const Data: PtrInt;
                             var Abort: boolean): string;
    function MacroFuncCurToken(const s:string; const Data: PtrInt;
                               var Abort: boolean): string;
    function MacroFuncPrompt(const s:string; const Data: PtrInt;
                             var Abort: boolean): string;
  public
    procedure InitMacros(AMacroList: TTransferMacroList);
    procedure SetupShortCuts;

    function FindUniquePageName(FileName:string; IgnoreEditor: TSourceEditor):string;
    procedure ShowFPDocEditor;
    function SomethingModified: boolean;
    procedure HideHint;
    procedure LockAllEditorsInSourceChangeCache;
    procedure UnlockAllEditorsInSourceChangeCache;
    procedure CloseFile(AEditor: TSourceEditorInterface);
    // history jumping
    procedure HistoryJump(Sender: TObject; CloseAction: TJumpHistoryAction);
  private
    FCodeTemplateModul: TSynEditAutoComplete;
    FGotoDialog: TfrmGoto;
    procedure OnCodeTemplateTokenNotFound(Sender: TObject; AToken: string;
                                   AnEditor: TCustomSynEdit; var Index:integer);
    procedure OnCodeTemplateExecuteCompletion(
                                       ASynAutoComplete: TCustomSynAutoComplete;
                                       Index: integer);
  protected
    procedure OnWordCompletionGetSource(var Source: TStrings; SourceIndex: integer);
    procedure OnSourceCompletionTimer(Sender: TObject);
    // marks
    function OnSourceMarksGetSourceEditorID(ASrcEdit: TSourceEditorInterface): TObject;
    function OnSourceMarksGetFilename(ASourceEditor: TObject): string;
    procedure OnSourceMarksAction(AMark: TSourceMark; AAction: TMarksAction);
    property CodeTemplateModul: TSynEditAutoComplete
                               read FCodeTemplateModul write FCodeTemplateModul;
    // goto dialog
    function GotoDialog: TfrmGoto;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CreateNewWindow(Activate: Boolean= False): TSourceNotebook;
  private
    FOnAddJumpPoint: TOnAddJumpPoint;
    FOnClearBookmark: TPlaceBookMarkEvent;
    FOnClickLink: TMouseEvent;
    FOnCloseClicked: TOnCloseSrcEditor;
    FOnDeleteLastJumpPoint: TNotifyEvent;
    FOnEditorChanged: TNotifyEvent;
    FOnEditorClosed: TNotifyEvent;
    FOnEditorMoved: TNotifyEvent;
    FOnEditorPropertiesClicked: TNotifyEvent;
    FOnFindDeclarationClicked: TNotifyEvent;
    FOnGetIndent: TOnGetIndentEvent;
    FOnGotoBookmark: TBookMarkActionEvent;
    FOnInitIdentCompletion: TOnInitIdentCompletion;
    FOnInsertTodoClicked: TNotifyEvent;
    FOnJumpToHistoryPoint: TOnJumpToHistoryPoint;
    FOnMouseLink: TSynMouseLinkEvent;
    FOnNoteBookCloseQuery: TCloseEvent;
    FOnOpenFileAtCursorClicked: TNotifyEvent;
    FOnPlaceMark: TPlaceBookMarkEvent;
    FOnPopupMenu: TSrcEditPopupMenuEvent;
    FOnProcessUserCommand: TOnProcessUserCommand;
    fOnReadOnlyChanged: TNotifyEvent;
    FOnSetBookmark: TBookMarkActionEvent;
    FOnShowCodeContext: TOnShowCodeContext;
    FOnShowHintForSource: TOnShowHintForSource;
    FOnShowUnitInfo: TNotifyEvent;
    FOnToggleFormUnitClicked: TNotifyEvent;
    FOnToggleObjectInspClicked: TNotifyEvent;
    FOnUserCommandProcessed: TOnUserCommandProcessed;
    FOnViewJumpHistory: TNotifyEvent;
    FOnWindowActivate: TNotifyEvent;
  public
    property OnWindowActivate: TNotifyEvent read FOnWindowActivate write FOnWindowActivate;
    property OnAddJumpPoint: TOnAddJumpPoint
             read FOnAddJumpPoint write FOnAddJumpPoint;
    property OnCloseClicked: TOnCloseSrcEditor
             read FOnCloseClicked write FOnCloseClicked;
    property OnClickLink: TMouseEvent read FOnClickLink write FOnClickLink;
    property OnMouseLink: TSynMouseLinkEvent read FOnMouseLink write FOnMouseLink;
    property OnGetIndent: TOnGetIndentEvent
             read FOnGetIndent write FOnGetIndent;
    property OnDeleteLastJumpPoint: TNotifyEvent
             read FOnDeleteLastJumpPoint write FOnDeleteLastJumpPoint;
    property OnEditorChanged: TNotifyEvent
             read FOnEditorChanged write FOnEditorChanged;
    property OnEditorMoved: TNotifyEvent
             read FOnEditorMoved write FOnEditorMoved;
    property OnEditorClosed: TNotifyEvent
             read FOnEditorClosed write FOnEditorClosed;
    property OnEditorPropertiesClicked: TNotifyEvent
             read FOnEditorPropertiesClicked write FOnEditorPropertiesClicked;
    property OnFindDeclarationClicked: TNotifyEvent
             read FOnFindDeclarationClicked write FOnFindDeclarationClicked;
    property OnInitIdentCompletion: TOnInitIdentCompletion
             read FOnInitIdentCompletion write FOnInitIdentCompletion;
    property OnInsertTodoClicked: TNotifyEvent
             read FOnInsertTodoClicked write FOnInsertTodoClicked;
    property OnShowCodeContext: TOnShowCodeContext
             read FOnShowCodeContext write FOnShowCodeContext;
    property OnJumpToHistoryPoint: TOnJumpToHistoryPoint
             read FOnJumpToHistoryPoint write FOnJumpToHistoryPoint;
    property OnPlaceBookmark: TPlaceBookMarkEvent  // Bookmark was placed by SynEdit
             read FOnPlaceMark write FOnPlaceMark;
    property OnClearBookmark: TPlaceBookMarkEvent  // Bookmark was cleared by SynEdit
             read FOnClearBookmark write FOnClearBookmark;
    property OnSetBookmark: TBookMarkActionEvent  // request to set a Bookmark
             read FOnSetBookmark write FOnSetBookmark;
    property OnGotoBookmark: TBookMarkActionEvent  // request to go to a Bookmark
             read FOnGotoBookmark write FOnGotoBookmark;
    property OnOpenFileAtCursorClicked: TNotifyEvent
             read FOnOpenFileAtCursorClicked write FOnOpenFileAtCursorClicked;
    property OnProcessUserCommand: TOnProcessUserCommand
             read FOnProcessUserCommand write FOnProcessUserCommand;
    property OnUserCommandProcessed: TOnUserCommandProcessed
             read FOnUserCommandProcessed write FOnUserCommandProcessed;
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
    property OnViewJumpHistory: TNotifyEvent
             read FOnViewJumpHistory write FOnViewJumpHistory;
    property OnPopupMenu: TSrcEditPopupMenuEvent read FOnPopupMenu write FOnPopupMenu;
    property OnNoteBookCloseQuery: TCloseEvent
             read FOnNoteBookCloseQuery write FOnNoteBookCloseQuery;
  end;

function SourceNotebook: TSourceNotebook;
  deprecated {$IFDEF VER2_5}'use SourceEditorManager'{$ENDIF};   // deprecated in 0.9.29 March 2010

function SourceEditorManager: TSourceEditorManager;

  //=============================================================================

const
  SourceEditorMenuRootName = 'SourceEditor';

var
  SrcEditMenuFindDeclaration: TIDEMenuCommand;
    // finding / jumping
    SrcEditMenuProcedureJump: TIDEMenuCommand;
    SrcEditMenuFindNextWordOccurrence: TIDEMenuCommand;
    SrcEditMenuFindPrevWordOccurrence: TIDEMenuCommand;
    SrcEditMenuFindinFiles: TIDEMenuCommand;
    // open file
    SrcEditMenuOpenFileAtCursor: TIDEMenuCommand;
  SrcEditMenuClosePage: TIDEMenuCommand;
  SrcEditMenuCloseOtherPages: TIDEMenuCommand;
  SrcEditMenuCut: TIDEMenuCommand;
  SrcEditMenuCopy: TIDEMenuCommand;
  SrcEditMenuPaste: TIDEMenuCommand;
  SrcEditMenuCopyFilename: TIDEMenuCommand;
    // bookmarks
    SrcEditMenuNextBookmark: TIDEMenuCommand;
    SrcEditMenuPrevBookmark: TIDEMenuCommand;
    SrcEditMenuSetFreeBookmark: TIDEMenuCommand;
    // debugging
    SrcEditMenuToggleBreakpoint: TIDEMenuCommand;
    SrcEditMenuRunToCursor: TIDEMenuCommand;
    SrcEditMenuEvaluateModify: TIDEMenuCommand;
    SrcEditMenuAddWatchAtCursor: TIDEMenuCommand;
    SrcEditMenuInspect: TIDEMenuCommand;
    SrcEditMenuViewCallStack: TIDEMenuCommand;
    // refactoring
    SrcEditMenuCompleteCode: TIDEMenuCommand;
    SrcEditMenuEncloseSelection: TIDEMenuCommand;
    SrcEditMenuRenameIdentifier: TIDEMenuCommand;
    SrcEditMenuFindIdentifierReferences: TIDEMenuCommand;
    SrcEditMenuExtractProc: TIDEMenuCommand;
    SrcEditMenuInvertAssignment: TIDEMenuCommand;
    SrcEditMenuShowAbstractMethods: TIDEMenuCommand;
    SrcEditMenuShowEmptyMethods: TIDEMenuCommand;
    SrcEditMenuShowUnusedUnits: TIDEMenuCommand;
    SrcEditMenuFindOverloads: TIDEMenuCommand;
  SrcEditMenuInsertTodo: TIDEMenuCommand;
  SrcEditMenuMoveEditorLeft: TIDEMenuCommand;
  SrcEditMenuMoveEditorRight: TIDEMenuCommand;
  SrcEditMenuMoveEditorFirst: TIDEMenuCommand;
  SrcEditMenuMoveEditorLast: TIDEMenuCommand;
  SrcEditMenuDocking: TIDEMenuCommand;
  SrcEditMenuReadOnly: TIDEMenuCommand;
  SrcEditMenuShowLineNumbers: TIDEMenuCommand;
  SrcEditMenuShowUnitInfo: TIDEMenuCommand;
  SrcEditMenuEditorProperties: TIDEMenuCommand;
  {$IFnDEF SingleSrcWindow}
  // Multi Window
  SrcEditMenuMoveToNewWindow: TIDEMenuCommand;
  SrcEditMenuMoveToOtherWindow: TIDEMenuSection;
  SrcEditMenuMoveToOtherWindowNew: TIDEMenuCommand;
  SrcEditMenuMoveToOtherWindowList: TIDEMenuSection;
  SrcEditMenuCopyToNewWindow: TIDEMenuCommand;
  SrcEditMenuCopyToOtherWindow: TIDEMenuSection;
  SrcEditMenuCopyToOtherWindowNew: TIDEMenuCommand;
  SrcEditMenuCopyToOtherWindowList: TIDEMenuSection;
  {$ENDIF}


procedure RegisterStandardSourceEditorMenuItems;

var
  Highlighters: array[TLazSyntaxHighlighter] of TSynCustomHighlighter;

implementation

{$R *.lfm}

var
  SourceCompletionTimer: TIdleTimer = nil;
  SourceCompletionCaretXY: TPoint;
  AWordCompletion: TWordCompletion = nil;

function SourceNotebook: TSourceNotebook;
begin
  if SourceEditorManager = nil then
    Result := nil
  else
    Result := SourceEditorManager.ActiveOrNewSourceWindow;
end;

function SourceEditorManager: TSourceEditorManager;
begin
  Result := TSourceEditorManager(SourceEditorManagerIntf);
end;

procedure RegisterStandardSourceEditorMenuItems;
var
  AParent: TIDEMenuSection;
  I: Integer;
begin
  SourceEditorMenuRoot:=RegisterIDEMenuRoot(SourceEditorMenuRootName);
  AParent:=SourceEditorMenuRoot;

  // register the first dynamic section for often used context sensitive stuff
  SrcEditMenuSectionFirstDynamic:=RegisterIDEMenuSection(AParent,
                                                       'First dynamic section');
  // register the first static section
  SrcEditMenuSectionFirstStatic:=RegisterIDEMenuSection(AParent,
                                                        'First static section');
  AParent:=SrcEditMenuSectionFirstStatic;
    SrcEditMenuFindDeclaration:=RegisterIDEMenuCommand(AParent,
                                         'Find Declaration',uemFindDeclaration);
    // register the sub menu Find
    SrcEditSubMenuFind:=RegisterIDESubMenu(AParent, 'Find section', lisMenuFind
      );
    AParent:=SrcEditSubMenuFind;
      SrcEditMenuProcedureJump:=RegisterIDEMenuCommand(AParent,'Procedure Jump',
                                                       uemProcedureJump);
      SrcEditMenuFindNextWordOccurrence:=RegisterIDEMenuCommand(AParent,
                      'Find next word occurrence', srkmecFindNextWordOccurrence, nil, nil, nil, 'menu_search_find_next');
      SrcEditMenuFindPrevWordOccurrence:=RegisterIDEMenuCommand(AParent,
                  'Find previous word occurrence', srkmecFindPrevWordOccurrence, nil, nil, nil, 'menu_search_find_previous');
      SrcEditMenuFindInFiles:=RegisterIDEMenuCommand(AParent,
                  'Find in files', srkmecFindInFiles, nil, nil, nil, 'menu_search_files');
  SrcEditMenuSectionPages := RegisterIDEMenuSection(SourceEditorMenuRoot,
                                                      'Pages');

    SrcEditMenuClosePage := RegisterIDEMenuCommand(SrcEditMenuSectionPages,
                        'Close Page',uemClosePage, nil, nil, nil, 'menu_close');
    SrcEditMenuCloseOtherPages := RegisterIDEMenuCommand(SrcEditMenuSectionPages,
                        'Close All Other Pages',uemCloseOtherPages, nil, nil, nil);

    {$IFnDEF SingleSrcWindow}
    // Move to other Window
    SrcEditMenuMoveToNewWindow   := RegisterIDEMenuCommand(SrcEditMenuSectionPages,
                                    'MoveToNewWindow', uemMoveToNewWindow);
    SrcEditMenuMoveToOtherWindow := RegisterIDESubMenu(SrcEditMenuSectionPages,
                                    'MoveToOtherWindow', uemMoveToOtherWindow);
      SrcEditMenuMoveToOtherWindowNew  := RegisterIDEMenuCommand(SrcEditMenuMoveToOtherWindow,
                                          'MoveToOtherWindowNew', uemMoveToOtherWindowNew);
      SrcEditMenuMoveToOtherWindowList := RegisterIDEMenuSection(SrcEditMenuMoveToOtherWindow,
                                        'MoveToOtherWindowList Section');

    SrcEditMenuCopyToNewWindow   := RegisterIDEMenuCommand(SrcEditMenuSectionPages,
                                    'CopyToNewWindow', uemCopyToNewWindow);
    SrcEditMenuCopyToOtherWindow := RegisterIDESubMenu(SrcEditMenuSectionPages,
                                    'CopyToOtherWindow', uemCopyToOtherWindow);
      SrcEditMenuCopyToOtherWindowNew  := RegisterIDEMenuCommand(SrcEditMenuCopyToOtherWindow,
                                          'CopyToOtherWindowNew', uemCopyToOtherWindowNew);
      SrcEditMenuCopyToOtherWindowList := RegisterIDEMenuSection(SrcEditMenuCopyToOtherWindow,
                                        'CopyToOtherWindowList Section');
    {$ENDIF}
    // register the Move Page sub menu
    SrcEditSubMenuMovePage:=RegisterIDESubMenu(SrcEditMenuSectionPages,
                                               'Move Page ...', lisMovePage);
    AParent:=SrcEditSubMenuMovePage;
      SrcEditMenuMoveEditorLeft:=RegisterIDEMenuCommand(AParent,'MoveEditorLeft',
                                                        uemMovePageLeft);
      SrcEditMenuMoveEditorRight:=RegisterIDEMenuCommand(AParent,'MoveEditorRight',
                                                        uemMovePageRight);
      SrcEditMenuMoveEditorFirst:=RegisterIDEMenuCommand(AParent,'MoveEditorLeftmost',
                                                        uemMovePageLeftmost);
      SrcEditMenuMoveEditorLast:=RegisterIDEMenuCommand(AParent,'MoveEditorRightmost',
                                                        uemMovePageRightmost);

    // register the sub menu Open File
    SrcEditSubMenuOpenFile:=RegisterIDESubMenu(SrcEditMenuSectionPages,
      'Open File ...', lisOpenFile2);
      AParent:=SrcEditSubMenuOpenFile;
      SrcEditMenuOpenFileAtCursor:=RegisterIDEMenuCommand(AParent,
                                     'Open File At Cursor',uemOpenFileAtCursor, nil, nil, nil, 'menu_search_openfile_atcursor');
      // register the File Specific dynamic section
      SrcEditMenuSectionFileDynamic:=RegisterIDEMenuSection(AParent,
                                                        'File dynamic section');

    // register the Flags section
    SrcEditSubMenuFlags:=RegisterIDESubMenu(SrcEditMenuSectionPages,
                                            'Flags section', lisFileSettings);
    AParent:=SrcEditSubMenuFlags;
      SrcEditMenuReadOnly:=RegisterIDEMenuCommand(AParent,'ReadOnly',uemReadOnly);
      SrcEditMenuReadOnly.ShowAlwaysCheckable:=true;
      SrcEditMenuShowLineNumbers:=RegisterIDEMenuCommand(AParent,
                                            'ShowLineNumbers',uemShowLineNumbers);
      SrcEditMenuShowLineNumbers.ShowAlwaysCheckable:=true;
      SrcEditMenuShowUnitInfo:=RegisterIDEMenuCommand(AParent,'ShowUnitInfo',
                                                      uemShowUnitInfo);
      SrcEditSubMenuHighlighter:=RegisterIDESubMenu(AParent,'Highlighter',
                                                      uemHighlighter);
      SrcEditSubMenuEncoding:=RegisterIDESubMenu(AParent,'Encoding',
                                                      uemEncoding);
      SrcEditSubMenuLineEnding:=RegisterIDESubMenu(AParent,'LineEnding',
                                                      uemLineEnding);

  // register the Clipboard section
  SrcEditMenuSectionClipboard:=RegisterIDEMenuSection(SourceEditorMenuRoot,
                                                      'Clipboard');
  AParent:=SrcEditMenuSectionClipboard;
    SrcEditMenuCut:=RegisterIDEMenuCommand(AParent,'Cut',uemCut, nil, nil, nil, 'laz_cut');
    SrcEditMenuCopy:=RegisterIDEMenuCommand(AParent,'Copy',uemCopy, nil, nil, nil, 'laz_copy');
    SrcEditMenuPaste:=RegisterIDEMenuCommand(AParent,'Paste',uemPaste, nil, nil, nil, 'laz_paste');
    SrcEditMenuCopyFilename:=RegisterIDEMenuCommand(AParent,'Copy filename',
                                                    uemCopyFilename);

  // register the Marks section
  SrcEditMenuSectionMarks:=RegisterIDEMenuSection(SourceEditorMenuRoot,
                                                  'Marks section');
    // register the Goto Bookmarks Submenu
    SrcEditSubMenuGotoBookmarks:=RegisterIDESubMenu(SrcEditMenuSectionMarks,
                                              'Goto bookmarks',uemGotoBookmark);
    AParent:=SrcEditSubMenuGotoBookmarks;
      for I := 0 to 9 do
        RegisterIDEMenuCommand(AParent,'GotoBookmark'+IntToStr(I),
                               uemBookmarkN+IntToStr(i));
      SrcEditMenuNextBookmark:=RegisterIDEMenuCommand(AParent,
                                          'Goto next Bookmark',uemNextBookmark, nil, nil, nil, 'menu_search_next_bookmark');
      SrcEditMenuPrevBookmark:=RegisterIDEMenuCommand(AParent,
                                      'Goto previous Bookmark',uemPrevBookmark, nil, nil, nil, 'menu_search_previous_bookmark');

    // register the Set Bookmarks Submenu
    SrcEditSubMenuToggleBookmarks:=RegisterIDESubMenu(SrcEditMenuSectionMarks,
                                          'Toggle bookmarks',uemToggleBookmark);
    AParent:=SrcEditSubMenuToggleBookmarks;
      for I := 0 to 9 do
        RegisterIDEMenuCommand(AParent,'ToggleBookmark'+IntToStr(I),
                               uemBookmarkN+IntToStr(i));
      SrcEditMenuSetFreeBookmark:=RegisterIDEMenuCommand(AParent,
                                      'Set a free Bookmark',uemSetFreeBookmark);

  // register the Debug section
  SrcEditMenuSectionDebug:=RegisterIDEMenuSection(SourceEditorMenuRoot,
                                                  'Debug section');
    // register the Debug submenu
    SrcEditSubMenuDebug:=RegisterIDESubMenu(SrcEditMenuSectionDebug,
                                            'Debug', uemDebugWord, nil, nil, 'debugger');
    AParent:=SrcEditSubMenuDebug;
      // register the Debug submenu items
      SrcEditMenuToggleBreakpoint:=RegisterIDEMenuCommand(AParent,'Toggle Breakpoint',
                                                       uemToggleBreakpoint);
      SrcEditMenuEvaluateModify:=RegisterIDEMenuCommand(AParent,'Evaluate/Modify...',
                                                       uemEvaluateModify, nil, nil, nil,'debugger_modify');
      SrcEditMenuEvaluateModify.Enabled:=False;
      SrcEditMenuAddWatchAtCursor:=RegisterIDEMenuCommand(AParent,
                                     'Add Watch at Cursor',uemAddWatchAtCursor);
      SrcEditMenuInspect:=RegisterIDEMenuCommand(AParent,
                             'Inspect...', uemInspect, nil, nil, nil, 'debugger_inspect');
      SrcEditMenuInspect.Enabled:=False;
      SrcEditMenuRunToCursor:=RegisterIDEMenuCommand(AParent,
                                                'Run to cursor', uemRunToCursor, nil, nil, nil, 'menu_run_cursor');
      SrcEditMenuViewCallStack:=RegisterIDEMenuCommand(AParent,
                                            'View Call Stack', uemViewCallStack, nil, nil, nil, 'debugger_call_stack');

  // register the Refactoring submenu
  SrcEditSubMenuRefactor:=RegisterIDESubMenu(SourceEditorMenuRoot,
                                             'Refactoring',uemRefactor);
  AParent:=SrcEditSubMenuRefactor;
    SrcEditMenuCompleteCode:=RegisterIDEMenuCommand(AParent,'CompleteCode',
                                                    uemCompleteCode);
    SrcEditMenuEncloseSelection:=RegisterIDEMenuCommand(AParent,
                                        'EncloseSelection',uemEncloseSelection);
    SrcEditMenuRenameIdentifier:=RegisterIDEMenuCommand(AParent,
                                        'RenameIdentifier',uemRenameIdentifier);
    SrcEditMenuFindIdentifierReferences:=RegisterIDEMenuCommand(AParent,
                        'FindIdentifierReferences',uemFindIdentifierReferences);
    SrcEditMenuExtractProc:=RegisterIDEMenuCommand(AParent,
                                                 'ExtractProc',uemExtractProc);
    SrcEditMenuInvertAssignment:=RegisterIDEMenuCommand(AParent,
                                        'InvertAssignment',uemInvertAssignment);
    SrcEditMenuShowAbstractMethods:=RegisterIDEMenuCommand(AParent,
                               'ShowAbstractMethods',srkmecShowAbstractMethods);
    SrcEditMenuShowEmptyMethods:=RegisterIDEMenuCommand(AParent,
                               'ShowEmptyMethods', lisCodeHelpShowEmptyMethods);
    SrcEditMenuShowUnusedUnits:=RegisterIDEMenuCommand(AParent,
                               'ShowUnusedUnits', lisCodeHelpShowUnusedUnits);
    SrcEditMenuFindOverloads:=RegisterIDEMenuCommand(AParent,
                               'FindOverloads', srkmecFindOverloads);
   {$IFNDEF EnableFindOverloads}
   SrcEditMenuFindOverloads.Visible:=false;
   {$ENDIF}

  SrcEditMenuInsertTodo:=RegisterIDEMenuCommand(SourceEditorMenuRoot,
                        'InsertTodo',uemInsertTodo, nil, nil, nil, 'item_todo');

  SrcEditMenuEditorProperties:=RegisterIDEMenuCommand(SourceEditorMenuRoot,
           'EditorProperties', dlgFROpts, nil, nil, nil, 'menu_environment_options');
  SrcEditMenuDocking:=RegisterIDEMenuCommand(SourceEditorMenuRoot, 'Docking',
           lisMVDocking);
  {$IFNDEF EnableIDEDocking}
  SrcEditMenuDocking.Visible:=false;
  {$ENDIF}
end;


{ TSourceEditCompletion }

procedure TSourceEditCompletion.ccExecute(Sender: TObject);
// init completion form
// called by OnExecute just before showing
var
  S: TStrings;
  Prefix: String;
  I: Integer;
  NewStr: String;
  fst, fstm : TFontStyles;
Begin
  {$IFDEF VerboseIDECompletionBox}
  debugln(['TSourceEditCompletion.ccExecute START']);
  {$ENDIF}
  TheForm.Font := Editor.Font;
  FActiveEditDefaultFGColor := Editor.Font.Color;
  FActiveEditDefaultBGColor := Editor.Color;
  EditorOpts.GetLineColors(Editor.Highlighter, ahaTextBlock, {TODO: MFR use AEditor.SelectedColor which includes styles / or have a copy}
    FActiveEditSelectedFGColor, FActiveEditSelectedBGColor, fst ,fstm);

  if Editor.Highlighter<>nil
  then begin
    with Editor.Highlighter do begin
      if IdentifierAttribute<>nil
      then begin
        if IdentifierAttribute.ForeGround<>clNone then
          FActiveEditDefaultFGColor:=IdentifierAttribute.ForeGround;
        if IdentifierAttribute.BackGround<>clNone then
          FActiveEditDefaultBGColor:=IdentifierAttribute.BackGround;
      end;
    end;
  end;

  S := TStringList.Create;
  try
    Prefix := CurrentString;
    case CurrentCompletionType of
     ctIdentCompletion:
       if not InitIdentCompletionValues(S) then begin
         ItemList.Clear;
         exit;
       end;

     ctWordCompletion:
       begin
         ccSelection := '';
       end;

     ctTemplateCompletion:
       begin
         ccSelection:='';
         for I := 0 to Manager.CodeTemplateModul.Completions.Count-1 do begin
           NewStr := Manager.CodeTemplateModul.Completions[I];
           if NewStr<>'' then begin
             NewStr:=#3'B'+NewStr+#3'b';
             while length(NewStr)<10+4 do NewStr:=NewStr+' ';
             NewStr:=NewStr+' '+Manager.CodeTemplateModul.CompletionComments[I];
             S.Add(NewStr);
           end;
         end;
       end;

    end;

    ItemList := S;
  finally
    S.Free;
  end;
  CurrentString:=Prefix;
  // set colors
  if (Editor<>nil) and (TheForm<>nil) then begin
    with TheForm do begin
      BackgroundColor   := FActiveEditDefaultBGColor;
      clSelect          := FActiveEditSelectedBGColor;
      TextColor         := FActiveEditDefaultFGColor;
      TextSelectedColor := FActiveEditSelectedFGColor;
      //writeln('TSourceNotebook.ccExecute A Color=',DbgS(Color),
      // ' clSelect=',DbgS(clSelect),
      // ' TextColor=',DbgS(TextColor),
      // ' TextSelectedColor=',DbgS(TextSelectedColor),
      // '');
    end;
    if (CurrentCompletionType=ctIdentCompletion) and (SourceEditorManager.ActiveCompletionPlugin=nil)
    then
      StartShowCodeHelp
    else if SrcEditHintWindow<>nil then
      SrcEditHintWindow.HelpEnabled:=false;
  end;
end;

procedure TSourceEditCompletion.ccCancel(Sender: TObject);
// user cancels completion form
begin
  {$IFDEF VerboseIDECompletionBox}
  debugln(['TSourceNotebook.ccCancel START']);
  //debugln(GetStackTrace(true));
  {$ENDIF}
  Manager.DeactivateCompletionForm;
end;

procedure TSourceEditCompletion.ccComplete(var Value: string;
  SourceValue: string; var SourceStart, SourceEnd: TPoint; KeyChar: TUTF8Char;
  Shift: TShiftState);
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
  NewCaretXY: TPoint;
  CursorToLeft: integer;
  NewValue: String;
  OldCompletionType: TCompletionType;
Begin
  {$IFDEF VerboseIDECompletionBox}
  debugln(['TSourceNotebook.ccComplete START']);
  {$ENDIF}
  OldCompletionType:=CurrentCompletionType;
  case CurrentCompletionType of

    ctIdentCompletion:
      if Manager.ActiveCompletionPlugin<>nil then
      begin
        Manager.ActiveCompletionPlugin.Complete(Value,SourceValue,
           SourceStart,SourceEnd,KeyChar,Shift);
        Manager.FActiveCompletionPlugin:=nil;
      end else begin
        // add to history
        CodeToolBoss.IdentifierHistory.Add(
          CodeToolBoss.IdentifierList.FilteredItems[Position]);
        // get value
        NewValue:=GetIdentCompletionValue(self, KeyChar, ValueType, CursorToLeft);
        if ValueType=icvIdentifier then ;
        // insert value plus special chars like brackets, semicolons, ...
        if ValueType <> icvNone then
          Editor.TextBetweenPointsEx[SourceStart, SourceEnd, scamEnd] := NewValue;
        if CursorToLeft>0 then
        begin
          NewCaretXY:=Editor.CaretXY;
          dec(NewCaretXY.X,CursorToLeft);
          Editor.CaretXY:=NewCaretXY;
        end;
        ccSelection := '';
        Value:='';
        SourceEnd := SourceStart;
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
          Manager.CodeTemplateModul.ExecuteCompletion(Value, Editor);
        SourceEnd := SourceStart;
        Value:='';
      end;

    ctWordCompletion:
      // the completion is already in Value
      begin
        ccSelection := '';
        if Value<>'' then AWordCompletion.AddWord(Value);
      end;

    else begin
      Value:='';
    end;
  end;

  Manager.DeactivateCompletionForm;

  //DebugLn(['TSourceNotebook.ccComplete ',KeyChar,' ',OldCompletionType=ctIdentCompletion]);
  if (KeyChar='.') and (OldCompletionType=ctIdentCompletion) then
  begin
    SourceCompletionCaretXY:=Editor.CaretXY;
    SourceCompletionTimer.AutoEnabled:=true;
  end;
end;

function TSourceEditCompletion.OnSynCompletionPaintItem(const AKey: string;
  ACanvas: TCanvas; X, Y: integer; ItemSelected: boolean; Index: integer
  ): boolean;
var
  MaxX: Integer;
  t: TCompletionType;
begin
  with ACanvas do begin
    if (Editor<>nil) then
      Font := Editor.Font
    else begin
      Font.Height:=EditorOpts.EditorFontHeight; // set Height before name for XLFD !
      Font.Name:=EditorOpts.EditorFont;
    end;
    Font.Style:=[];
    if not ItemSelected then
      Font.Color := FActiveEditDefaultFGColor
    else
      Font.Color := FActiveEditSelectedFGColor;
  end;
  MaxX:=TheForm.ClientWidth;
  t:=CurrentCompletionType;
  if Manager.ActiveCompletionPlugin<>nil then
  begin
    if Manager.ActiveCompletionPlugin.HasCustomPaint then
    begin
      Manager.ActiveCompletionPlugin.PaintItem(AKey,ACanvas,X,Y,ItemSelected,Index);
    end else begin
      t:=ctWordCompletion;
    end;
  end;
  PaintCompletionItem(AKey,ACanvas,X,Y,MaxX,ItemSelected,Index,self,
                      t,Editor.Highlighter);
  Result:=true;
end;

function TSourceEditCompletion.OnSynCompletionMeasureItem(const AKey: string;
  ACanvas: TCanvas; ItemSelected: boolean; Index: integer): TPoint;
var
  MaxX: Integer;
  t: TCompletionType;
begin
  with ACanvas do begin
    if (Editor<>nil) then
      Font:=Editor.Font
    else begin
      Font.Height:=EditorOpts.EditorFontHeight; // set Height before name of XLFD !
      Font.Name:=EditorOpts.EditorFont;
    end;
    Font.Style:=[];
    if not ItemSelected then
      Font.Color := FActiveEditDefaultFGColor
    else
      Font.Color := FActiveEditSelectedFGColor;
  end;
  MaxX := Screen.Width-20;
  t:=CurrentCompletionType;
  if Manager.ActiveCompletionPlugin<>nil then
  begin
    if Manager.ActiveCompletionPlugin.HasCustomPaint then
    begin
      Manager.ActiveCompletionPlugin.MeasureItem(AKey,ACanvas,ItemSelected,Index);
    end else begin
      t:=ctWordCompletion;
    end;
  end;
  Result := PaintCompletionItem(AKey,ACanvas,0,0,MaxX,ItemSelected,Index,
                                self,t,nil,True);
  Result.Y:=FontHeight;
end;

procedure TSourceEditCompletion.OnSynCompletionSearchPosition(
  var APosition: integer);
// prefix changed -> filter list
var
  i,x:integer;
  CurStr,s:Ansistring;
  SL: TStrings;
  ItemCnt: Integer;
begin
  case CurrentCompletionType of

    ctIdentCompletion:
      if Manager.ActiveCompletionPlugin<>nil then
      begin
        // let plugin rebuild completion list
        SL:=TStringList.Create;
        try
          Manager.ActiveCompletionPlugin.PrefixChanged(CurrentString,
            APosition,sl);
          ItemList:=SL;
        finally
          SL.Free;
        end;
      end else begin
        // rebuild completion list
        APosition:=0;
        CurStr:=CurrentString;
        CodeToolBoss.IdentifierList.Prefix:=CurStr;
        ItemCnt:=CodeToolBoss.IdentifierList.GetFilteredCount;
        SL:=TStringList.Create;
        try
          sl.Capacity:=ItemCnt;
          for i:=0 to ItemCnt-1 do
            SL.Add('Dummy'); // these entries are not shown
          ItemList:=SL;
        finally
          SL.Free;
        end;
      end;

    ctTemplateCompletion:
      begin
        // search CurrentString in bold words (words after #3'B')
        CurStr:=CurrentString;
        i:=0;
        while i<ItemList.Count do begin
          s:=ItemList[i];
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
        CurStr:=CurrentString;
        SL:=TStringList.Create;
        try
          aWordCompletion.GetWordList(SL, CurStr, false, 100);
          ItemList:=SL;
        finally
          SL.Free;
        end;
      end;

  end;
end;

procedure TSourceEditCompletion.OnSynCompletionCompletePrefix(Sender: TObject);
var
  OldPrefix: String;
  NewPrefix: String;
  SL: TStringList;
  AddPrefix: String;
begin
  OldPrefix:=CurrentString;
  NewPrefix:=OldPrefix;

  case CurrentCompletionType of

  ctIdentCompletion:
    if Manager.ActiveCompletionPlugin<>nil then
    begin
      Manager.ActiveCompletionPlugin.CompletePrefix(NewPrefix);
    end else begin
      NewPrefix:=CodeToolBoss.IdentifierList.CompletePrefix(OldPrefix);
    end;

  ctWordCompletion:
    begin
      aWordCompletion.CompletePrefix(OldPrefix,NewPrefix,false);
    end;

  end;

  if NewPrefix<>OldPrefix then begin
    AddPrefix:=copy(NewPrefix,length(OldPrefix)+1,length(NewPrefix));
    Editor.InsertTextAtCaret(AddPrefix);
    if CurrentCompletionType=ctWordCompletion then begin
      SL:=TStringList.Create;
      try
        aWordCompletion.GetWordList(SL, NewPrefix, false, 100);
        ItemList:=SL;
      finally
        SL.Free;
      end;
    end;
    CurrentString:=NewPrefix;
  end;
end;

procedure TSourceEditCompletion.OnSynCompletionNextChar(Sender: TObject);
var
  NewPrefix: String;
  Line: String;
  LogCaret: TPoint;
  CharLen: LongInt;
  AddPrefix: String;
begin
  if Editor=nil then exit;
  LogCaret:=Editor.LogicalCaretXY;
  if LogCaret.Y>=Editor.Lines.Count then exit;
  Line:=Editor.Lines[LogCaret.Y-1];
  if LogCaret.X>length(Line) then exit;
  CharLen:=UTF8CharacterLength(@Line[LogCaret.X]);
  AddPrefix:=copy(Line,LogCaret.X,CharLen);
  NewPrefix:=CurrentString+AddPrefix;
  //debugln('TSourceNotebook.OnSynCompletionNextChar NewPrefix="',NewPrefix,'" LogCaret.X=',dbgs(LogCaret.X));
  inc(LogCaret.X);
  Editor.LogicalCaretXY:=LogCaret;
  CurrentString:=NewPrefix;
end;

procedure TSourceEditCompletion.OnSynCompletionPrevChar(Sender: TObject);
var
  NewPrefix: String;
  NewLen: LongInt;
begin
  NewPrefix:=CurrentString;
  if NewPrefix='' then exit;
  if Editor=nil then exit;
  Editor.CaretX:=Editor.CaretX-1;
  NewLen:=UTF8FindNearestCharStart(PChar(NewPrefix),length(NewPrefix),
                                   length(NewPrefix))-1;
  NewPrefix:=copy(NewPrefix,1,NewLen);
  CurrentString:=NewPrefix;
end;

procedure TSourceEditCompletion.OnSynCompletionKeyPress(Sender: TObject;
  var Key: Char);
begin
  if (System.Pos(Key,EndOfTokenChr)>0) then begin
    // identifier completed
    //debugln('TSourceNotebook.OnSynCompletionKeyPress A');
    TheForm.OnValidate(Sender,Key,[]);
    //debugln('TSourceNotebook.OnSynCompletionKeyPress B');
    Key:=#0;
  end;
end;

procedure TSourceEditCompletion.OnSynCompletionUTF8KeyPress(Sender: TObject;
  var UTF8Key: TUTF8Char);
begin
  if (length(UTF8Key)=1)
  and (System.Pos(UTF8Key[1],EndOfTokenChr)>0) then begin
    // identifier completed
    //debugln('TSourceNotebook.OnSynCompletionUTF8KeyPress A');
    TheForm.OnValidate(Sender,UTF8Key,[]);
    //debugln('TSourceNotebook.OnSynCompletionKeyPress B');
    UTF8Key:='';
  end else begin
    Editor.CommandProcessor(ecChar,UTF8Key,nil);
    UTF8Key:='';
  end;
  //debugln('TSourceNotebook.OnSynCompletionKeyPress B UTF8Key=',dbgstr(UTF8Key));
end;

procedure TSourceEditCompletion.OnSynCompletionPositionChanged(Sender: TObject
  );
begin
  if Manager.ActiveCompletionPlugin<>nil then
    Manager.ActiveCompletionPlugin.IndexChanged(Position);
  if SrcEditHintWindow<>nil then
    SrcEditHintWindow.UpdateHints;
end;

function TSourceEditCompletion.InitIdentCompletionValues(S: TStrings): boolean;
var
  i: integer;
  Handled: boolean;
  Abort: boolean;
  Prefix: string;
  ItemCnt: Integer;
begin
  Result:=false;
  Prefix := CurrentString;
  if Manager.ActiveCompletionPlugin<>nil then
  begin
    Result := Manager.ActiveCompletionPlugin.Collect(S);
  end else if Assigned(Manager.OnInitIdentCompletion) then
  begin
    Manager.OnInitIdentCompletion(Self, FIdentCompletionJumpToError, Handled, Abort);
    if Handled then begin
      if Abort then exit;
      // add one entry per item
      CodeToolBoss.IdentifierList.Prefix:=Prefix;
      ItemCnt:=CodeToolBoss.IdentifierList.GetFilteredCount;
      //DebugLn('InitIdentCompletion B Prefix=',Prefix,' ItemCnt=',IntToStr(ItemCnt));
      Position:=0;
      for i:=0 to ItemCnt-1 do
        s.Add('Dummy');
      Result:=true;
      exit;
    end;
  end;
end;

procedure TSourceEditCompletion.StartShowCodeHelp;
begin
  if SrcEditHintWindow = nil then begin
    SrcEditHintWindow := TSrcEditHintWindow.Create(Manager);
    SrcEditHintWindow.Name:='TSourceNotebook_SrcEditHintWindow';
    SrcEditHintWindow.Provider:=TFPDocHintProvider.Create(SrcEditHintWindow);
  end;
  SrcEditHintWindow.AnchorForm := TheForm;
  {$IFDEF EnableCodeHelp}
  SrcEditHintWindow.HelpEnabled:=true;
  {$ENDIF}
end;

function TSourceEditCompletion.Manager: TSourceEditorManager;
begin
  Result := SourceEditorManager;
end;

constructor TSourceEditCompletion.Create(AOwner: TComponent);
begin
  inherited;
  EndOfTokenChr:='()[].,;:-+=^*<>/';
  Width:=400;
  OnExecute := @ccExecute;
  OnCancel := @ccCancel;
  OnCodeCompletion := @ccComplete;
  OnPaintItem:=@OnSynCompletionPaintItem;
  OnMeasureItem := @OnSynCompletionMeasureItem;
  OnSearchPosition:=@OnSynCompletionSearchPosition;
  OnKeyCompletePrefix:=@OnSynCompletionCompletePrefix;
  OnKeyNextChar:=@OnSynCompletionNextChar;
  OnKeyPrevChar:=@OnSynCompletionPrevChar;
  OnKeyPress:=@OnSynCompletionKeyPress;
  OnUTF8KeyPress:=@OnSynCompletionUTF8KeyPress;
  OnPositionChanged:=@OnSynCompletionPositionChanged;
  ShortCut:=Menus.ShortCut(VK_UNKNOWN,[]);
end;

{ TSourceEditorSharedValues }

function TSourceEditorSharedValues.GetSharedEditors(Index: Integer
  ): TSourceEditor;
begin
  Result := TSourceEditor(FSharedEditorList[Index]);
end;

function TSourceEditorSharedValues.GetOtherSharedEditors(Caller: TSourceEditor;
  Index: Integer): TSourceEditor;
begin
  if Index >= FSharedEditorList.IndexOf(Caller) then
    inc(Index);
  Result := TSourceEditor(FSharedEditorList[Index]);
end;

function TSourceEditorSharedValues.SynEditor: TIDESynEditor;
begin
  Result := SharedEditors[0].FEditor;
end;

procedure TSourceEditorSharedValues.SetCodeBuffer(const AValue: TCodeBuffer);
var
  i: Integer;
begin
  if FCodeBuffer = AValue then exit;
  if FCodeBuffer<>nil then
    FCodeBuffer.RemoveChangeHook(@OnCodeBufferChanged);
  FCodeBuffer := AValue;
  if FCodeBuffer <> nil then
  begin
    FCodeBuffer.AddChangeHook(@OnCodeBufferChanged);
    if (FIgnoreCodeBufferLock <= 0) and (not FCodeBuffer.IsEqual(SynEditor.Lines))
    then begin
      {$IFDEF IDE_DEBUG}
      debugln(' *** WARNING *** : TSourceEditor.SetCodeBuffer - loosing marks: ',Filename);
      {$ENDIF}
      for i := 0 to FSharedEditorList.Count - 1 do
        if assigned(SharedEditors[i].FEditPlugin) then
          SharedEditors[i].FEditPlugin.Enabled := False;
      SynEditor.BeginUpdate;
      FCodeBuffer.AssignTo(SynEditor.Lines,true);
      FEditorStampCommitedToCodetools:=(SynEditor.Lines as TSynEditLines).TextChangeStamp;
      SynEditor.EndUpdate;
      for i := 0 to FSharedEditorList.Count - 1 do
        if assigned(SharedEditors[i].FEditPlugin) then
          SharedEditors[i].FEditPlugin.Enabled := True;
    end;
    for i := 0 to FSharedEditorList.Count - 1 do begin
      if SharedEditors[i].IsActiveOnNoteBook then SharedEditors[i].SourceNotebook.UpdateStatusBar;
      // HasExecutionMarks is shared through synedit => this is only needed once
      // but HasExecutionMarks must be called on each synedit, so each synedit is notified
      if (DebugBoss.State in [dsPause, dsRun]) and
         not SharedEditors[i].HasExecutionMarks and (FCodeBuffer.FileName <> '')
      then
        SharedEditors[i].FillExecutionMarks;
    end;
  end;
end;

function TSourceEditorSharedValues.GetModified: Boolean;
begin
  Result := FModified or SynEditor.Modified;
end;

procedure TSourceEditorSharedValues.SetModified(const AValue: Boolean);
var
  OldModified: Boolean;
  i: Integer;
begin
  OldModified := Modified; // Include SynEdit
  FModified := AValue;
  if not FModified then
    SynEditor.Modified := False; // All shared SynEdits share this value
    FEditorStampCommitedToCodetools := TSynEditLines(SynEditor.Lines).TextChangeStamp;
    for i := 0 to FSharedEditorList.Count - 1 do
      SharedEditors[i].FEditor.MarkTextAsSaved; // Todo: centralize in SynEdit
  if OldModified <> Modified then
    for i := 0 to FSharedEditorList.Count - 1 do begin
      SharedEditors[i].UpdatePageName;
      SharedEditors[i].SourceNotebook.UpdateStatusBar;
    end;
end;

procedure TSourceEditorSharedValues.OnCodeBufferChanged(Sender: TSourceLog;
  SrcLogEntry: TSourceLogEntry);

  procedure MoveTxt(const StartPos, EndPos, MoveToPos: TPoint;
    DirectionForward: boolean);
  var Txt: string;
  begin
    if DirectionForward then begin
      SynEditor.TextBetweenPointsEx[MoveToPos, MoveToPos, scamAdjust] :=
        SynEditor.TextBetweenPoints[StartPos, EndPos];
      SynEditor.TextBetweenPointsEx[StartPos, EndPos, scamAdjust] := '';
    end else begin
      Txt := SynEditor.TextBetweenPoints[StartPos, EndPos];
      SynEditor.TextBetweenPointsEx[StartPos, EndPos, scamAdjust] := '';
      SynEditor.TextBetweenPointsEx[MoveToPos, MoveToPos, scamAdjust] := Txt;;
    end;
  end;

var
  StartPos, EndPos, MoveToPos: TPoint;
  CodeToolsInSync: Boolean;
begin
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceEditor.OnCodeBufferChanged] A ',FIgnoreCodeBufferLock,' ',SrcLogEntry<>nil);
  {$ENDIF}
  if FIgnoreCodeBufferLock>0 then exit;
  CodeToolsInSync:=not NeedsUpdateCodeBuffer;
  if SrcLogEntry<>nil then begin
    SynEditor.BeginUpdate;
    SynEditor.BeginUndoBlock;
    case SrcLogEntry.Operation of
      sleoInsert:
        begin
          Sender.AbsoluteToLineCol(SrcLogEntry.Position,StartPos.Y,StartPos.X);
          if StartPos.Y>=1 then
            SynEditor.TextBetweenPointsEx[StartPos, StartPos, scamAdjust] := SrcLogEntry.Txt;
        end;
      sleoDelete:
        begin
          Sender.AbsoluteToLineCol(SrcLogEntry.Position,StartPos.Y,StartPos.X);
          Sender.AbsoluteToLineCol(SrcLogEntry.Position+SrcLogEntry.Len,
            EndPos.Y,EndPos.X);
          if (StartPos.Y>=1) and (EndPos.Y>=1) then
            SynEditor.TextBetweenPointsEx[StartPos, EndPos, scamAdjust] := '';
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
    SynEditor.EndUndoBlock;
    SynEditor.EndUpdate;
  end else begin
    {$IFDEF VerboseSrcEditBufClean}
    debugln(['TSourceEditor.OnCodeBufferChanged clean up ',TCodeBuffer(Sender).FileName,' ',Sender=CodeBuffer,' ',Filename]);
    DumpStack;
    {$ENDIF}
    SynEditor.BeginUpdate;
    Sender.AssignTo(SynEditor.Lines,false);
    SynEditor.EndUpdate;
  end;
  if CodeToolsInSync then begin
    // synedit and codetools were in sync -> mark as still in sync
    FEditorStampCommitedToCodetools:=TSynEditLines(SynEditor.Lines).TextChangeStamp;
  end;
end;

procedure TSourceEditorSharedValues.AddSharedEditor(AnEditor: TSourceEditor);
begin
  if FSharedEditorList.IndexOf(AnEditor) < 0 then
    FSharedEditorList.Add(AnEditor);
end;

procedure TSourceEditorSharedValues.RemoveSharedEditor(AnEditor: TSourceEditor
  );
begin
  FSharedEditorList.Remove(AnEditor);
end;

function TSourceEditorSharedValues.SharedEditorCount: Integer;
begin
  Result := FSharedEditorList.Count;
end;

function TSourceEditorSharedValues.OtherSharedEditorCount: Integer;
begin
  Result := FSharedEditorList.Count - 1;
end;

procedure TSourceEditorSharedValues.CreateExecutionMark;
begin
  FExecutionMark := TSourceMark.Create(SharedEditors[0], nil);
  SourceEditorMarks.Add(FExecutionMark);
  FExecutionMark.LineColorAttrib := ahaExecutionPoint;
  FExecutionMark.Priority := 1;
end;

procedure TSourceEditorSharedValues.IncreaseIgnoreCodeBufferLock;
begin
  inc(FIgnoreCodeBufferLock);
end;

procedure TSourceEditorSharedValues.DecreaseIgnoreCodeBufferLock;
begin
  if FIgnoreCodeBufferLock<=0 then raise Exception.Create('unbalanced calls');
  dec(FIgnoreCodeBufferLock);
end;

function TSourceEditorSharedValues.NeedsUpdateCodeBuffer: boolean;
begin
  Result := TSynEditLines(SharedEditors[0].FEditor.Lines).TextChangeStamp
            <> FEditorStampCommitedToCodetools;
end;

procedure TSourceEditorSharedValues.UpdateCodeBuffer;
begin
  if not NeedsUpdateCodeBuffer then exit;
  {$IFDEF IDE_DEBUG}
  if FCodeBuffer=nil then begin
    debugln('*********** Oh, no: UpdateCodeBuffer ************ ');
  end;
  {$ENDIF}
  if FCodeBuffer=nil then exit;
  //DebugLn(['TSourceEditor.UpdateCodeBuffer ',FileName]);
  IncreaseIgnoreCodeBufferLock;
  SynEditor.BeginUpdate;
  FCodeBuffer.Assign(SynEditor.Lines);
  FEditorStampCommitedToCodetools:=(SynEditor.Lines as TSynEditLines).TextChangeStamp;
  SynEditor.EndUpdate;
  DecreaseIgnoreCodeBufferLock;
end;

constructor TSourceEditorSharedValues.Create;
begin
  FSharedEditorList := TFPList.Create;
  BookmarkEventLock := 0;
  FExecutionLine:=-1;
  FExecutionMark := nil;
  FMarksRequested := False;
end;

destructor TSourceEditorSharedValues.Destroy;
begin
  CodeBuffer := nil;
  FreeAndNil(FSharedEditorList);
  // no need to care about ExecutionMark, it was removed in EditorClose
  // via: SourceEditorMarks.DeleteAllForEditor(Self);
  inherited Destroy;
end;

{ TSourceEditor }

{ The constructor for @link(TSourceEditor).
  AOwner is the @link(TSourceNotebook)
  and the AParent is usually a page of a @link(TNotebook) }
constructor TSourceEditor.Create(AOwner: TComponent; AParent: TWinControl; ASharedEditor: TSourceEditor = nil);
var
  i: Integer;
Begin
  if ASharedEditor = nil then
    FSharedValues := TSourceEditorSharedValues.Create
  else
    FSharedValues := ASharedEditor.FSharedValues;
  FSharedValues.AddSharedEditor(Self);

  inherited Create;
  FAOwner := AOwner;
  if (FAOwner<>nil) and (FAOwner is TSourceNotebook) then
    FSourceNoteBook:=TSourceNotebook(FAOwner)
  else
    FSourceNoteBook:=nil;

  FSyntaxHighlighterType:=lshNone;
  FErrorLine:=-1;
  FErrorColumn:=-1;
  FSyncroLockCount := 0;
  FLineInfoNotification := TIDELineInfoNotification.Create;
  FLineInfoNotification.AddReference;
  FLineInfoNotification.OnChange := @LineInfoNotificationChange;

  CreateEditor(AOwner,AParent);
  FIsNewSharedEditor := False;
  if ASharedEditor <> nil then begin
    PageName := ASharedEditor.PageName;
    FEditor.ShareTextBufferFrom(ASharedEditor.EditorComponent);
    FEditor.Highlighter := ASharedEditor.EditorComponent.Highlighter;

    // bookmakrs
    inc(FSharedValues.BookmarkEventLock);
    try
      for i := 0 to ASharedEditor.FEditor.Marks.Count - 1 do
        if ASharedEditor.FEditor.Marks[i].IsBookmark then
          FEditor.SetBookMark(ASharedEditor.FEditor.Marks[i].BookmarkNumber,
            ASharedEditor.FEditor.Marks[i].Column,
            ASharedEditor.FEditor.Marks[i].Line);
    finally
      dec(FSharedValues.BookmarkEventLock);
    end;

    SourceEditorMarks.AddSourceEditor(Self, ASharedEditor);
  end;

  FEditPlugin := TSynEditPlugin1.Create(FEditor);
  // IMPORTANT: when you change below, don't forget updating UnbindEditor
  FEditPlugin.OnLinesInserted := @LinesInserted;
  FEditPlugin.OnLinesDeleted := @LinesDeleted;
end;

destructor TSourceEditor.Destroy;
begin
  if (FAOwner<>nil) and (FEditor<>nil) then begin
    UnbindEditor;
    FEditor.Visible:=false;
    FEditor.Parent:=nil;
    if SourceEditorMarks<>nil then
      SourceEditorMarks.DeleteAllForEditor(Self);
    TSourceNotebook(FAOwner).ReleaseEditor(self);
    // free the synedit control after processing the events
    Application.ReleaseComponent(FEditor);
  end;
  FEditor:=nil;
  if (DebugBoss <> nil) and (DebugBoss.LineInfo <> nil) then
    DebugBoss.LineInfo.RemoveNotification(FLineInfoNotification);
  FLineInfoNotification.ReleaseReference;
  inherited Destroy;
  FSharedValues.RemoveSharedEditor(Self);
  if FSharedValues.SharedEditorCount = 0 then
    FreeAndNil(FSharedValues);
end;

{------------------------------G O T O   L I N E  -----------------------------}
Function TSourceEditor.GotoLine(Value: Integer): Integer;
Var
  P: TPoint;
  NewTopLine: integer;
Begin
  Manager.AddJumpPointClicked(Self);
  P.X := 1;
  P.Y := Value;
  NewTopLine := P.Y - (FEditor.LinesInWindow div 2);
  if NewTopLine < 1 then NewTopLine:=1;
  FEditor.CaretXY := P;
  FEditor.TopLine := NewTopLine;
  Result:=FEditor.CaretY;
end;

procedure TSourceEditor.ShowGotoLineDialog;
var
  NewLeft: integer;
  NewTop: integer;
  dlg: TfrmGoto;
begin
  dlg := Manager.GotoDialog;
  dlg.Edit1.Text:='';
  GetDialogPosition(dlg.Width, dlg.Height, NewLeft, NewTop);
  dlg.SetBounds(NewLeft, NewTop, dlg.Width, dlg.Height);
  if (dlg.ShowModal = mrOK) then
    GotoLine(StrToIntDef(dlg.Edit1.Text,1));
  Self.FocusEditor;
end;

procedure TSourceEditor.GetDialogPosition(Width, Height: integer;
  out Left, Top: integer);
var 
  P: TPoint;
  ABounds: TRect;
begin
  with EditorComponent do
    P := ClientToScreen(Point(CaretXPix, CaretYPix));
  ABounds := Screen.MonitorFromPoint(P).BoundsRect;
  Left := EditorComponent.ClientOrigin.X + (EditorComponent.Width - Width) div 2;
  Top := P.Y - Height - 3 * EditorComponent.LineHeight;
  if Top < ABounds.Top + 10 then
    Top := P.Y + 2 * EditorComponent.LineHeight;
  if Top + Height > ABounds.Bottom then
    Top := (ABounds.Bottom + ABounds.Top - Height) div 2;
  if Top < ABounds.Top then Top := ABounds.Top;
end;

procedure TSourceEditor.ActivateHint(ClientPos: TPoint;
  const BaseURL, TheHint: string);
var
  ScreenPos: TPoint;
begin
  if SourceNotebook=nil then exit;
  ScreenPos:=EditorComponent.ClientToScreen(ClientPos);
  SourceNotebook.ActivateHint(ScreenPos,BaseURL,TheHint);
end;

{------------------------------S T A R T  F I N D-----------------------------}
procedure TSourceEditor.StartFindAndReplace(Replace:boolean);
const
  SaveOptions = [ssoWholeWord,ssoBackwards,ssoEntireScope,ssoRegExpr,ssoRegExprMultiLine];
var
  NewOptions: TSynSearchOptions;
  ALeft,ATop:integer;
  bSelectedTextOption: Boolean;
  DlgResult: TModalResult;
begin
  LazFindReplaceDialog.ResetUserHistory;
  //debugln('TSourceEditor.StartFindAndReplace A LazFindReplaceDialog.FindText="',dbgstr(LazFindReplaceDialog.FindText),'"');
  if ReadOnly then Replace := False;
  NewOptions:=LazFindReplaceDialog.Options;
  if Replace then
    NewOptions := NewOptions + [ssoReplace, ssoReplaceAll]
  else
    NewOptions := NewOptions - [ssoReplace, ssoReplaceAll];
  NewOptions:=NewOptions-SaveOptions+InputHistories.FindOptions*SaveOptions;
  LazFindReplaceDialog.Options := NewOptions;

  // Fill in history items
  LazFindReplaceDialog.TextToFindComboBox.Items.Assign(InputHistories.FindHistory);
  LazFindReplaceDialog.ReplaceTextComboBox.Items.Assign(
                                                 InputHistories.ReplaceHistory);

  with EditorComponent do begin
    if EditorOpts.FindTextAtCursor then begin
      if SelAvail and (BlockBegin.Y = BlockEnd.Y) then begin
        //debugln('TSourceEditor.StartFindAndReplace B FindTextAtCursor SelAvail');
        LazFindReplaceDialog.FindText := SelText
      end else begin
        //debugln('TSourceEditor.StartFindAndReplace B FindTextAtCursor not SelAvail');
        LazFindReplaceDialog.FindText := GetWordAtRowCol(LogicalCaretXY);
      end;
    end else begin
      //debugln('TSourceEditor.StartFindAndReplace B not FindTextAtCursor');
      LazFindReplaceDialog.FindText:='';
    end;
  end;
  LazFindReplaceDialog.EnableAutoComplete:=InputHistories.FindAutoComplete;
  // if there is no FindText, use the most recently used FindText
  if (LazFindReplaceDialog.FindText='') and (InputHistories.FindHistory.Count > 0) then
    LazFindReplaceDialog.FindText:=InputHistories.FindHistory[0];

  GetDialogPosition(LazFindReplaceDialog.Width,LazFindReplaceDialog.Height,ALeft,ATop);
  LazFindReplaceDialog.Left:=ALeft;
  LazFindReplaceDialog.Top:=ATop;

  try
    bSelectedTextOption := (ssoSelectedOnly in LazFindReplaceDialog.Options);
    //if there are selected text and more than 1 word, automatically enable selected text option
    if EditorComponent.SelAvail
    and (EditorComponent.BlockBegin.Y<>EditorComponent.BlockEnd.Y) then
      LazFindReplaceDialog.Options := LazFindReplaceDialog.Options + [ssoSelectedOnly];

    DlgResult:=LazFindReplaceDialog.ShowModal;
    InputHistories.FindOptions:=LazFindReplaceDialog.Options*SaveOptions;
    InputHistories.FindAutoComplete:=LazFindReplaceDialog.EnableAutoComplete;
    if DlgResult = mrCancel then
      exit;
    //debugln('TSourceEditor.StartFindAndReplace B LazFindReplaceDialog.FindText="',dbgstr(LazFindReplaceDialog.FindText),'"');

    Replace:=ssoReplace in LazFindReplaceDialog.Options;
    if Replace then
      InputHistories.AddToReplaceHistory(LazFindReplaceDialog.ReplaceText);
    InputHistories.AddToFindHistory(LazFindReplaceDialog.FindText);
    InputHistories.Save;
    DoFindAndReplace;
  finally
    //Restore original find options
    if bSelectedTextOption then
      LazFindReplaceDialog.Options := LazFindReplaceDialog.Options + [ssoSelectedOnly]
    else
      LazFindReplaceDialog.Options := LazFindReplaceDialog.Options - [ssoSelectedOnly];
  end;//End try-finally
end;

procedure TSourceEditor.AskReplace(Sender: TObject; const ASearch,
  AReplace: string; Line, Column: integer; var Action: TSrcEditReplaceAction);
var
  SynAction: TSynReplaceAction;
begin
  SynAction:=raCancel;
  SourceNotebook.BringToFront;
  OnReplace(Sender, ASearch, AReplace, Line, Column, SynAction);
  case SynAction of
  raSkip: Action:=seraSkip;
  raReplaceAll: Action:=seraReplaceAll;
  raReplace: Action:=seraReplace;
  raCancel: Action:=seraCancel;
  else
    RaiseGDBException('TSourceEditor.AskReplace: inconsistency');
  end;
end;

{------------------------------F I N D  A G A I N ----------------------------}
procedure TSourceEditor.FindNextUTF8;
var
  OldOptions: TSynSearchOptions;
begin
  if snIncrementalFind in FSourceNoteBook.States
  then begin
    FSourceNoteBook.IncrementalSearch(True, False);
  end
  else if LazFindReplaceDialog.FindText = ''
  then begin
    StartFindAndReplace(False)
  end
  else begin
    OldOptions:=LazFindReplaceDialog.Options;
    LazFindReplaceDialog.Options:=LazFindReplaceDialog.Options
                                     -[ssoEntireScope,ssoReplaceAll];
    DoFindAndReplace;
    LazFindReplaceDialog.Options:=OldOptions;
  end;
End;

{---------------------------F I N D   P R E V I O U S ------------------------}
procedure TSourceEditor.FindPrevious;
var
  OldOptions: TSynSearchOptions;
begin
  if snIncrementalFind in FSourceNoteBook.States
  then begin
    FSourceNoteBook.IncrementalSearch(True, True);
  end
  else begin
    OldOptions:=LazFindReplaceDialog.Options;
    LazFindReplaceDialog.Options:=LazFindReplaceDialog.Options-[ssoEntireScope];
    if ssoBackwards in LazFindReplaceDialog.Options then
      LazFindReplaceDialog.Options:=LazFindReplaceDialog.Options-[ssoBackwards]
    else
      LazFindReplaceDialog.Options:=LazFindReplaceDialog.Options+[ssoBackwards];
    if LazFindReplaceDialog.FindText = '' then
      StartFindAndReplace(False)
    else
      DoFindAndReplace;
    LazFindReplaceDialog.Options:=OldOptions;
  end;
end;

procedure TSourceEditor.FindNextWordOccurrence(DirectionForward: boolean);
var
  StartX, EndX: Integer;
  Flags: TSynSearchOptions;
  LogCaret: TPoint;
begin
  LogCaret:=EditorComponent.LogicalCaretXY;
  EditorComponent.GetWordBoundsAtRowCol(LogCaret,StartX,EndX);
  if EndX<=StartX then exit;
  Flags:=[ssoWholeWord];
  if DirectionForward then begin
    LogCaret.X:=EndX;
  end else begin
    LogCaret.X:=StartX;
    Include(Flags,ssoBackwards);
  end;
  EditorComponent.LogicalCaretXY:=LogCaret;
  EditorComponent.SearchReplace(EditorComponent.GetWordAtRowCol(LogCaret),
                                '',Flags);
end;

function TSourceEditor.DoFindAndReplace: integer;
var
  OldCaretXY: TPoint;
  AText, ACaption: String;
  NewTopLine: integer;
begin
  Result:=0;
  if SourceNotebook<>nil then
    Manager.AddJumpPointClicked(Self);
  if (ssoReplace in LazFindReplaceDialog.Options)
  and ReadOnly then begin
    DebugLn(['TSourceEditor.DoFindAndReplace Read only']);
    exit;
  end;

  OldCaretXY:=EditorComponent.CaretXY;
  if EditorComponent.SelAvail and
     not(ssoSelectedOnly in LazFindReplaceDialog.Options)
  then begin
    // Adjust the cursor. to exclude the selection from being searched
    // needed for find next / find previous
    if ssoBackwards in LazFindReplaceDialog.Options then
      EditorComponent.LogicalCaretXY:=EditorComponent.BlockBegin
    else
      EditorComponent.LogicalCaretXY:=EditorComponent.BlockEnd
  end;
  //debugln('TSourceEditor.DoFindAndReplace A LazFindReplaceDialog.FindText="',dbgstr(LazFindReplaceDialog.FindText),'" ssoEntireScope=',dbgs(ssoEntireScope in LazFindReplaceDialog.Options),' ssoBackwards=',dbgs(ssoBackwards in LazFindReplaceDialog.Options));
  try
    Result:=EditorComponent.SearchReplace(
      LazFindReplaceDialog.FindText,LazFindReplaceDialog.ReplaceText,
      LazFindReplaceDialog.Options);
  except
    on E: ERegExpr do begin
      MessageDlg(lisUEErrorInRegularExpression,
        E.Message,mtError,[mbCancel],0);
      exit;
    end;
  end;

  if (OldCaretXY.X = EditorComponent.CaretX) and
     (OldCaretXY.Y = EditorComponent.CaretY) and
     not (ssoReplaceAll in LazFindReplaceDialog.Options) then
  begin
    ACaption := lisUENotFound;
    AText := Format(lisUESearchStringNotFound, [ValidUTF8String(LazFindReplaceDialog.FindText)]);
    MessageDlg(ACaption, AText, mtInformation, [mbOk], 0);
    Manager.DeleteLastJumpPointClicked(Self);
  end else
  if (EditorComponent.CaretY <= EditorComponent.TopLine + 1) or
     (EditorComponent.CaretY >= EditorComponent.TopLine + EditorComponent.LinesInWindow - 1) then
  begin
    NewTopLine := EditorComponent.CaretY - (EditorComponent.LinesInWindow div 2);
    if NewTopLine < 1 then
      NewTopLine := 1;
    EditorComponent.TopLine := NewTopLine;
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
  //DebugLn('TSourceEditor.FocusEditor ',dbgsName(FindOwnerControl(GetFocus)),' ',dbgs(GetFocus));
  {$IFDEF VerboseFocus}
  writeln('TSourceEditor.FocusEditor END ',PageName,' ',FEditor.Name);
  {$ENDIF}
end;

Function TSourceEditor.GetReadOnly: Boolean;
Begin
  Result:=FEditor.ReadOnly;
End;

procedure TSourceEditor.SetReadOnly(const NewValue: boolean);
begin
  FEditor.ReadOnly:=NewValue;
end;

function TSourceEditor.Manager: TSourceEditorManager;
begin
  if FSourceNoteBook <> nil then
    Result := FSourceNoteBook.Manager
  else
    Result := nil;
end;

function TSourceEditor.IsSharedWith(AnOtherEditor: TSourceEditor): Boolean;
begin
  Result := (AnOtherEditor <> nil) and
            (AnOtherEditor.FSharedValues = FSharedValues);
end;

Procedure TSourceEditor.ProcessCommand(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
// these are normal commands for synedit (lower than ecUserFirst),
// define extra actions here
// for non synedit keys (bigger than ecUserFirst) use ProcessUserCommand
var
  AddChar: Boolean;
  s: String;
begin
  //DebugLn('TSourceEditor.ProcessCommand Command=',dbgs(Command));

  SourceCompletionTimer.AutoEnabled:=false;

  if (Command=ecChar) and (AChar=#27) then begin
    // close hint windows
    if (CodeContextFrm<>nil) then
      CodeContextFrm.Hide;
    if (SrcEditHintWindow<>nil) then
      SrcEditHintWindow.Hide;
  end;

  if (FSourceNoteBook<>nil)
  and (snIncrementalFind in FSourceNoteBook.States) then begin
    case Command of
    ecChar:
      begin
        if AChar=#27 then begin
          if (CodeContextFrm<>nil) then
            CodeContextFrm.Hide;

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

    ecPaste:
      begin
        s:=Clipboard.AsText;
        s:=copy(s,1,EditorOpts.RightMargin);
        FSourceNoteBook.IncrementalSearchStr:=
          FSourceNoteBook.IncrementalSearchStr+s;
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
        Manager.AddJumpPointClicked(Self);
    end;

  ecCopy,ecCut:
    begin
      if (not FEditor.SelAvail) then begin
        // nothing selected
        if EditorOpts.CopyWordAtCursorOnCopyNone then begin
          FEditor.SelectWord;
        end;
      end;
    end;

  ecChar:
    begin
      AddChar:=true;
      //debugln(['TSourceEditor.ProcessCommand AChar="',AChar,'" AutoIdentifierCompletion=',dbgs(EditorOpts.AutoIdentifierCompletion),' Interval=',SourceCompletionTimer.Interval,' ',Dbgs(FEditor.CaretXY),' ',FEditor.IsIdentChar(aChar)]);
      if (aChar=' ') and AutoCompleteChar(aChar,AddChar,acoSpace) then begin
        // completed
      end else if (not FEditor.IsIdentChar(aChar))
      and AutoCompleteChar(aChar,AddChar,acoWordEnd) then begin
        // completed
      end else if CodeToolsOpts.IdentComplAutoStartAfterPoint then begin
        // store caret position to detect caret changes
        SourceCompletionCaretXY:=FEditor.CaretXY;
        // add the char
        inc(SourceCompletionCaretXY.x,length(AChar));
        SourceCompletionTimer.AutoEnabled:=true;
      end;
      //DebugLn(['TSourceEditor.ProcessCommand ecChar AddChar=',AddChar]);
      if not AddChar then Command:=ecNone;
    end;

  ecLineBreak:
    begin
      AddChar:=true;
      if AutoCompleteChar(aChar,AddChar,acoLineBreak) then ;
      //DebugLn(['TSourceEditor.ProcessCommand ecLineBreak AddChar=',AddChar]);
      if not AddChar then Command:=ecNone;
      if EditorOpts.AutoBlockCompletion then
        AutoCompleteBlock;
    end;

  ecPrevBookmark: // Note: book mark commands lower than ecUserFirst must be handled here
    if Assigned(Manager.OnGotoBookmark) then
      Manager.OnGotoBookmark(Self, -1, True);

  ecNextBookmark:
    if Assigned(Manager.OnGotoBookmark) then
      Manager.OnGotoBookmark(Self, -1, False);

  ecGotoMarker0..ecGotoMarker9:
    if Assigned(Manager.OnGotoBookmark) then
      Manager.OnGotoBookmark(Self, Command - ecGotoMarker0, False);

  ecSetMarker0..ecSetMarker9:
    if Assigned(Manager.OnSetBookmark) then
      Manager.OnSetBookmark(Self, Command - ecSetMarker0, False);

  ecToggleMarker0..ecToggleMarker9:
    if Assigned(Manager.OnSetBookmark) then
      Manager.OnSetBookmark(Self, Command - ecToggleMarker0, True);

  end;
  //debugln('TSourceEditor.ProcessCommand B IdentCompletionTimer.AutoEnabled=',dbgs(SourceCompletionTimer.AutoEnabled));
end;

Procedure TSourceEditor.ProcessUserCommand(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
// these are the keys above ecUserFirst
// define all extra keys here, that should not be handled by synedit
var
  Handled: boolean;
Begin
  //debugln('TSourceEditor.ProcessUserCommand A ',dbgs(Command));
  Handled:=true;

  if Manager.ActiveSourceWindow <> SourceNotebook then begin
    debugln('Warning: ActiveSourceWindow is set incorrectly');
    Manager.ActiveSourceWindow := SourceNotebook;
  end;

  case Command of

  ecContextHelp:
    FindHelpForSourceAtCursor;

  ecIdentCompletion :
    StartIdentCompletionBox(true);

  ecShowCodeContext :
    SourceNotebook.StartShowCodeContext(true);

  ecWordCompletion :
    StartWordCompletionBox(true);

  ecFind:
    StartFindAndReplace(false);

  ecFindNext:
    FindNextUTF8;

  ecFindPrevious:
    FindPrevious;

  ecIncrementalFind:
    if FSourceNoteBook<>nil then FSourceNoteBook.BeginIncrementalFind;

  ecReplace:
    StartFindAndReplace(true);

  ecGotoLineNumber :
    ShowGotoLineDialog;

  ecFindNextWordOccurrence:
    FindNextWordOccurrence(true);

  ecFindPrevWordOccurrence:
    FindNextWordOccurrence(false);

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

  ecToggleComment:
    ToggleCommentSelection;

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

  ecInsertModifiedLGPLNotice:
    InsertModifiedLGPLNotice(comtDefault);

  ecInsertUserName:
    InsertUsername;

  ecInsertDateTime:
    InsertDateTime;

  ecInsertTodo:
    InsertTodo;

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
// called after the source editor processed a key
var Handled: boolean;
begin
  Handled:=true;
  case Command of

  ecNone: ;

  else
    begin
      Handled:=false;
      if FaOwner<>nil then
        TSourceNotebook(FaOwner).ParentCommandProcessed(Self,Command,aChar,Data,
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
  Result := EditorComponent.SelAvail;
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
var
  OldBlockBegin, OldBlockEnd: TPoint;
  OldMode: TSynSelectionMode;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  OldBlockBegin:=FEditor.BlockBegin;
  OldBlockEnd:=FEditor.BlockEnd;
  OldMode:=FEditor.SelectionMode;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  FEditor.SelText:=UpperCase(EditorComponent.SelText);
  FEditor.BlockBegin:=OldBlockBegin;
  FEditor.BlockEnd:=OldBlockEnd;
  FEditor.SelectionMode := OldMode;
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

{-------------------------------------------------------------------------------
  method TSourceEditor.LowerCaseSelection

  Turns current text selection lowercase.
-------------------------------------------------------------------------------}
procedure TSourceEditor.LowerCaseSelection;
var
  OldBlockBegin, OldBlockEnd: TPoint;
  OldMode: TSynSelectionMode;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  OldBlockBegin:=FEditor.BlockBegin;
  OldBlockEnd:=FEditor.BlockEnd;
  OldMode:=FEditor.SelectionMode;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  FEditor.SelText:=LowerCase(EditorComponent.SelText);
  FEditor.BlockBegin:=OldBlockBegin;
  FEditor.BlockEnd:=OldBlockEnd;
  FEditor.SelectionMode := OldMode;
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

{-------------------------------------------------------------------------------
  method TSourceEditor.TabsToSpacesInSelection

  Convert all tabs into spaces in current text selection.
-------------------------------------------------------------------------------}
procedure TSourceEditor.TabsToSpacesInSelection;
var
  OldBlockBegin, OldBlockEnd: TPoint;
  OldMode: TSynSelectionMode;
begin
  if ReadOnly then exit;
  if not EditorComponent.SelAvail then exit;
  OldBlockBegin:=FEditor.BlockBegin;
  OldBlockEnd:=FEditor.BlockEnd;
  OldMode:=FEditor.SelectionMode;
  FEditor.BeginUpdate;
  FEditor.BeginUndoBlock;
  // ToDo: replace step by step to keep bookmarks and breakpoints
  FEditor.SelText:=TabsToSpaces(EditorComponent.SelText,
                                EditorComponent.TabWidth,FEditor.UseUTF8);
  FEditor.BlockBegin:=OldBlockBegin;
  FEditor.BlockEnd:=OldBlockEnd;
  FEditor.SelectionMode := OldMode;
  FEditor.EndUndoBlock;
  FEditor.EndUpdate;
end;

procedure TSourceEditor.CommentSelection;
begin
  UpdateCommentSelection(True, False);
end;

procedure TSourceEditor.UncommentSelection;
begin
  UpdateCommentSelection(False, False);
end;

procedure TSourceEditor.ToggleCommentSelection;
begin
  UpdateCommentSelection(False, True);
end;

procedure TSourceEditor.UpdateCommentSelection(CommentOn, Toggle: Boolean);
var
  OldCaretPos, OldBlockStart, OldBlockEnd: TPoint;
  WasSelAvail: Boolean;
  WasSelMode: TSynSelectionMode;
  BlockBeginLine: Integer;
  BlockEndLine: Integer;
  CommonIndent: Integer;

  function FirstNonBlankPos(const Text: String; Start: Integer = 1): Integer;
  var
    i: Integer;
  begin
    for i := Start to Length(Text) do
      if (Text[i] <> #32) and (Text[i] <> #9) then
        exit(i);
    Result := -1;
  end;

  function MinCommonIndent: Integer;
  var
    i, j: Integer;
  begin
    If CommonIndent = 0 then begin
      CommonIndent := Max(FirstNonBlankPos(FEditor.Lines[BlockBeginLine - 1]), 1);
      for i := BlockBeginLine + 1 to BlockEndLine do begin
        j := FirstNonBlankPos(FEditor.Lines[i - 1]);
        if (j < CommonIndent) and (j > 0) then
          CommonIndent := j;
      end;
    end;
    Result := CommonIndent;
  end;

  function InsertPos(ALine: Integer): Integer;
  begin
    if not WasSelAvail then
      Result := MinCommonIndent
    else case WasSelMode of
      smColumn: // CommonIndent is not used otherwise
        begin
          if CommonIndent = 0 then
            CommonIndent := Min(FEditor.LogicalToPhysicalPos(OldBlockStart).X,
                                FEditor.LogicalToPhysicalPos(OldBlockEnd).X);
          Result := FEditor.PhysicalToLogicalPos(Point(CommonIndent, ALine)).X;
        end;
      smNormal:
        begin
          if OldBlockStart.Y = OldBlockEnd.Y then
            Result := OldBlockStart.X
          else
            Result := MinCommonIndent;
        end;
       else
         Result := 1;
    end;
  end;

  function DeletePos(ALine: Integer): Integer;
  var
    line: String;
  begin
    line := FEditor.Lines[ALine - 1];
    Result := FirstNonBlankPos(line, InsertPos(ALine));
    if (WasSelMode = smColumn) and((Result < 1) or (Result > length(line) - 1))
    then
      Result := length(line) - 1;
    Result := Max(1, Result);
    if (Length(line) < Result +1) or
       (line[Result] <> '/') or (line[Result+1] <> '/') then
      Result := -1;
  end;

var
  i: Integer;
  NonBlankStart: Integer;
begin
  if ReadOnly then exit;
  OldCaretPos   := FEditor.CaretXY;
  OldBlockStart := FEditor.BlockBegin;
  OldBlockEnd   := FEditor.BlockEnd;
  WasSelAvail := FEditor.SelAvail;
  WasSelMode  := FEditor.SelectionMode;
  CommonIndent := 0;

  BlockBeginLine := OldBlockStart.Y;
  BlockEndLine := OldBlockEnd.Y;
  if (OldBlockEnd.X = 1) and (BlockEndLine > BlockBeginLine) and (FEditor.SelectionMode <> smLine) then
    Dec(BlockEndLine);

  if Toggle then begin
    CommentOn := False;
    for i := BlockBeginLine to BlockEndLine do
      if DeletePos(i) < 0 then begin
        CommentOn := True;
        break;
      end;
  end;

  BeginUpdate;
  BeginUndoBlock;
  FEditor.SelectionMode := smNormal;

  if CommentOn then begin
    for i := BlockEndLine downto BlockBeginLine do
      FEditor.TextBetweenPoints[Point(InsertPos(i), i), Point(InsertPos(i), i)] := '//';
    if OldCaretPos.X > InsertPos(OldCaretPos.Y) then
      OldCaretPos.x := OldCaretPos.X + 2;
    if OldBlockStart.X > InsertPos(OldBlockStart.Y) then
      OldBlockStart.X := OldBlockStart.X + 2;
    if OldBlockEnd.X > InsertPos(OldBlockEnd.Y) then
      OldBlockEnd.X := OldBlockEnd.X + 2;
  end
  else begin
    for i := BlockEndLine downto BlockBeginLine do
    begin
      NonBlankStart := DeletePos(i);
      if NonBlankStart < 1 then continue;
      FEditor.TextBetweenPoints[Point(NonBlankStart, i), Point(NonBlankStart + 2, i)] := '';
      if (OldCaretPos.Y = i) and (OldCaretPos.X > NonBlankStart) then
        OldCaretPos.x := Max(OldCaretPos.X - 2, NonBlankStart);
      if (OldBlockStart.Y = i) and (OldBlockStart.X > NonBlankStart) then
        OldBlockStart.X := Max(OldBlockStart.X - 2, NonBlankStart);
      if (OldBlockEnd.Y = i) and (OldBlockEnd.X > NonBlankStart) then
        OldBlockEnd.X := Max(OldBlockEnd.X - 2, NonBlankStart);
    end;
  end;

  EndUndoBlock;
  EndUpdate;

  FEditor.CaretXY := OldCaretPos;
  FEditor.BlockBegin := OldBlockStart;
  FEditor.BlockEnd := OldBlockEnd;
  FEditor.SelectionMode := WasSelMode;
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
  FEditor.SelText:=AddConditional(EditorComponent.SelText,IsPascal);
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
  EditorComponent.SelectWord;
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
begin
  ShowCharacterMap(@SourceNotebook.InsertCharacter);
end;

procedure TSourceEditor.InsertLicenseNotice(const Notice: string;
  CommentType: TCommentType);
var
  Txt: string;
begin
  if ReadOnly then Exit;
  Txt:=CommentText(LCLProc.BreakString(
           Format(Notice,[#13#13,#13#13,#13#13,#13#13,#13#13]),
           FEditor.RightEdge-2,0),CommentType);
  FEditor.InsertTextAtCaret(Txt);
end;

procedure TSourceEditor.InsertGPLNotice(CommentType: TCommentType);
begin
  InsertLicenseNotice(lisGPLNotice, CommentType);
end;

procedure TSourceEditor.InsertLGPLNotice(CommentType: TCommentType);
begin
  InsertLicenseNotice(lisLGPLNotice, CommentType);
end;

procedure TSourceEditor.InsertModifiedLGPLNotice(CommentType: TCommentType);
begin
  InsertLicenseNotice(lisModifiedLGPLNotice, CommentType);
end;

procedure TSourceEditor.InsertUsername;
begin
  if ReadOnly then Exit;
  FEditor.InsertTextAtCaret(GetCurrentUserName);
end;

procedure TSourceEditor.InsertTodo;
Var
  aTodoItem: TTodoItem;
begin
  //DebugLn(['TSourceEditor.InsertTodo ']);
  if ReadOnly then Exit;
  aTodoItem := ExecuteTodoDialog;
  try
    if Assigned(aTodoItem) then
      FEditor.InsertTextAtCaret(aTodoItem.AsComment);
  finally
    aTodoItem.Free;
  end;
end;

procedure TSourceEditor.InsertDateTime;
begin
  if ReadOnly then Exit;
  FEditor.InsertTextAtCaret(DateTimeToStr(now));
end;

procedure TSourceEditor.InsertChangeLogEntry;
var s: string;
begin
  if ReadOnly then Exit;
  s:=DateToStr(now)+'   '+GetCurrentUserName+' '+GetCurrentMailAddress;
  FEditor.InsertTextAtCaret(s);
end;

procedure TSourceEditor.InsertCVSKeyword(const AKeyWord: string);
begin
  if ReadOnly then Exit;
  FEditor.InsertTextAtCaret('$'+AKeyWord+'$'+LineEnding);
end;

function TSourceEditor.GetSelEnd: Integer;
begin
  Result:=FEditor.SelEnd;
end;

function TSourceEditor.GetSelStart: Integer;
begin
  Result:=FEditor.SelStart;
end;

procedure TSourceEditor.SetSelEnd(const AValue: Integer);
begin
  FEditor.SelEnd:=AValue;
end;

procedure TSourceEditor.SetSelStart(const AValue: Integer);
begin
  FEditor.SelStart:=AValue;
end;

function TSourceEditor.GetSelection: string;
begin
  Result:=FEditor.SelText;
end;

procedure TSourceEditor.SetSelection(const AValue: string);
begin
  FEditor.SelText:=AValue;
end;

procedure TSourceEditor.CopyToClipboard;
begin
  FEditor.CopyToClipboard;
end;

procedure TSourceEditor.CutToClipboard;
begin
  FEditor.CutToClipboard;
end;

procedure TSourceEditor.FindHelpForSourceAtCursor;
begin
  //DebugLn('TSourceEditor.FindHelpForSourceAtCursor A');
  ShowHelpOrErrorForSourcePosition(Filename,FEditor.LogicalCaretXY);
end;

procedure TSourceEditor.OnGutterClick(Sender: TObject; X, Y, Line: integer;
  mark: TSynEditMark);
var
  Marks: PSourceMark;
  i, MarkCount: Integer;
  BreakFound: Boolean;
begin
  // create or delete breakpoint
  // find breakpoint mark at line
  Marks := nil;
  try
    SourceEditorMarks.GetMarksForLine(Self, Line, Marks, MarkCount);
    BreakFound := False;
    for i := 0 to MarkCount - 1 do
    begin
      if not Marks[i].Visible then
        Continue;
      if Marks[i].IsBreakPoint then
      begin
        BreakFound := True;
        DebugBoss.DoDeleteBreakPointAtMark(Marks[i])
      end;
    end;
  finally
    FreeMem(Marks);
  end;

  if not BreakFound then
    DebugBoss.DoCreateBreakPoint(Filename, Line, True);
end;

procedure TSourceEditor.OnEditorSpecialLineColor(Sender: TObject; Line: integer;
  var Special: boolean; Markup: TSynSelectedColor);
var
  i:integer;
  aha: TAdditionalHilightAttribute;
  CurMarks: PSourceMark;
  CurMarkCount: integer;
  CurFG: TColor;
  CurBG: TColor;
begin
  aha := ahaNone;
  Special := False;

  if ErrorLine = Line
  then begin
    aha := ahaErrorLine
  end
  else begin
    SourceEditorMarks.GetMarksForLine(Self, Line, CurMarks, CurMarkCount);
    if CurMarkCount > 0 then
    begin
      for i := 0 to CurMarkCount - 1 do
      begin
        if not CurMarks[i].Visible then
          Continue;
        // check highlight attribute
        aha := CurMarks[i].LineColorAttrib;
        if aha <> ahaNone then Break;

        // check custom colors
        CurFG := CurMarks[i].LineColorForeGround;
        CurBG := CurMarks[i].LineColorBackGround;
        if (CurFG <> clNone) or (CurBG <> clNone) then
        begin
          Markup.Foreground := CurFG;
          Markup.Background := CurBG;
          Special := True;
          break;
        end;
      end;
      // clean up
      FreeMem(CurMarks);
    end;
  end;

  if aha <> ahaNone
  then begin
    Special := True;
    EditorOpts.SetMarkupColor(TCustomSynEdit(Sender).Highlighter, aha, Markup);
  end;
end;

procedure TSourceEditor.SetSyntaxHighlighterType(
  ASyntaxHighlighterType: TLazSyntaxHighlighter);
begin
  if (ASyntaxHighlighterType=fSyntaxHighlighterType)
  and ((FEditor.Highlighter<>nil) = EditorOpts.UseSyntaxHighlight) then exit;

  if EditorOpts.UseSyntaxHighlight
  then begin
    if Highlighters[ASyntaxHighlighterType]=nil then begin
      Highlighters[ASyntaxHighlighterType]:=
        EditorOpts.CreateSyn(ASyntaxHighlighterType);
    end;
    FEditor.Highlighter:=Highlighters[ASyntaxHighlighterType];
  end
  else
    FEditor.Highlighter:=nil;

  FSyntaxHighlighterType:=ASyntaxHighlighterType;
  SourceNotebook.UpdateActiveEditColors(FEditor);
end;

procedure TSourceEditor.SetErrorLine(NewLine: integer);
begin
  if fErrorLine=NewLine then exit;
  fErrorLine:=NewLine;
  fErrorColumn:=EditorComponent.CaretX;
  EditorComponent.Invalidate;
end;

procedure TSourceEditor.UpdateExecutionSourceMark;
var
  BreakPoint: TIDEBreakPoint;
  ExecutionMark: TSourceMark;
begin
  ExecutionMark := FSharedValues.ExecutionMark;
  if ExecutionMark = nil then exit;

  if ExecutionMark.Visible then
  begin
    if SourceEditorMarks.FindBreakPointMark(Self, ExecutionLine) <> nil then
    begin
      BreakPoint := DebugBoss.BreakPoints.Find(Self.FileName, ExecutionLine);
      if (BreakPoint <> nil) and (not BreakPoint.Enabled) then
        ExecutionMark.ImageIndex := SourceEditorMarks.CurrentLineDisabledBreakPointImg
      else
        ExecutionMark.ImageIndex := SourceEditorMarks.CurrentLineBreakPointImg;
    end
    else
      ExecutionMark.ImageIndex := SourceEditorMarks.CurrentLineImg;
  end;
end;

procedure TSourceEditor.SetExecutionLine(NewLine: integer);
begin
  if ExecutionLine=NewLine then exit;
  if (FSharedValues.ExecutionMark = nil) then begin
    if NewLine = -1 then
      exit;
    FSharedValues.CreateExecutionMark;
  end;
  FSharedValues.ExecutionLine := NewLine;
  FSharedValues.ExecutionMark.Visible := NewLine <> -1;
  if NewLine <> -1 then
    FSharedValues.ExecutionMark.Line := NewLine;
  UpdateExecutionSourceMark;
end;

Function TSourceEditor.RefreshEditorSettings: Boolean;
var
  SimilarEditor: TSynEdit;
Begin
  Result:=true;
  SetSyntaxHighlighterType(fSyntaxHighlighterType);

  // try to copy settings from an editor to the left
  SimilarEditor:=nil;
  if (SourceNotebook.EditorCount>0) and (SourceNotebook.Editors[0]<>Self) then
    SimilarEditor:=SourceNotebook.Editors[0].EditorComponent;
  EditorOpts.GetSynEditSettings(FEditor,SimilarEditor);

  SourceNotebook.UpdateActiveEditColors(FEditor);
end;

Procedure TSourceEditor.ccAddMessage(Texts: String);
Begin
  ErrorMsgs.Add(Texts);
End;

function TSourceEditor.AutoCompleteChar(Char: TUTF8Char; var AddChar: boolean;
  Category: TAutoCompleteOption): boolean;
var
  AToken: String;
  i, x1, x2: Integer;
  p: TPoint;
  Line: String;
  CatName: String;
  SrcToken: String;
  IdChars: TSynIdentChars;
  WordToken: String;
begin
  Result:=false;
  Line:=GetLineText;
  p:=GetCursorTextXY;
  if (p.x>length(Line)+1) or (Line='') then exit;
  CatName:=AutoCompleteOptionNames[Category];

  FEditor.GetWordBoundsAtRowCol(p, x1, x2);
  // A new word-break char is going to be inserted, so end the word here
  x2 := Min(x2, p.x);
  WordToken := copy(Line, x1, x2-x1);
  IdChars := FEditor.IdentChars;
  for i:=0 to Manager.CodeTemplateModul.Completions.Count-1 do begin
    AToken:=Manager.CodeTemplateModul.Completions[i];
    if AToken='' then continue;
    if AToken[1] in IdChars then
      SrcToken:=WordToken
    else
      SrcToken:=copy(Line,length(Line)-length(AToken)+1,length(AToken));
    //DebugLn(['TSourceEditor.AutoCompleteChar ',AToken,' SrcToken=',SrcToken,' CatName=',CatName,' Index=',Manager.CodeTemplateModul.CompletionAttributes[i].IndexOfName(CatName)]);
    if (AnsiCompareText(AToken,SrcToken)=0)
    and (Manager.CodeTemplateModul.CompletionAttributes[i].IndexOfName(CatName)>=0)
    then begin
      Result:=true;
      //DebugLn(['TSourceEditor.AutoCompleteChar ',AToken,' SrcToken=',SrcToken,' CatName=',CatName,' Index=',Manager.CodeTemplateModul.CompletionAttributes[i].IndexOfName(CatName)]);
      Manager.CodeTemplateModul.ExecuteCompletion(AToken,FEditor);
      AddChar:=not Manager.CodeTemplateModul.CompletionAttributes[i].IndexOfName(
                                     AutoCompleteOptionNames[acoRemoveChar])>=0;
      exit;
    end;
  end;
end;

procedure TSourceEditor.AutoCompleteBlock;
var
  XY: TPoint;
  NewCode: TCodeBuffer;
  NewX, NewY, NewTopLine: integer;
begin
  if not LazarusIDE.SaveSourceEditorChangesToCodeCache(self) then exit;
  XY:=FEditor.LogicalCaretXY;
  FEditor.BeginUndoBlock;
  try
    if not CodeToolBoss.CompleteBlock(CodeBuffer,XY.X,XY.Y,
                                      NewCode,NewX,NewY,NewTopLine) then exit;
    XY:=FEditor.LogicalCaretXY;
    //DebugLn(['TSourceEditor.AutoCompleteBlock XY=',dbgs(XY),' NewX=',NewX,' NewY=',NewY]);
    if (NewCode<>CodeBuffer) or (NewX<>XY.X) or (NewY<>XY.Y) or (NewTopLine>0)
    then begin
      XY.X:=NewX;
      XY.Y:=NewY;
      FEditor.LogicalCaretXY:=XY;
    end;
  finally
    FEditor.EndUndoBlock;
  end;
end;

procedure TSourceEditor.UpdateNoteBook(const ANewNoteBook: TSourceNotebook; ANewPage: TPage);
begin
  if FSourceNoteBook = ANewNoteBook then exit;

  FSourceNoteBook := ANewNoteBook;
  FAOwner := ANewNoteBook;
  FPageName := ANewNoteBook.NoteBookPages[ANewNoteBook.NoteBookIndexOfPage(ANewPage)];

  // Change the Owner of the SynEdit
  EditorComponent.Owner.RemoveComponent(EditorComponent);
  FSourceNoteBook.InsertComponent(EditorComponent);
  // And the Parent
  EditorComponent.Parent := ANewPage;
end;

{ AOwner is the TSourceNotebook
  AParent is a page of the TNotebook }
Procedure TSourceEditor.CreateEditor(AOwner: TComponent; AParent: TWinControl);
var
  NewName: string;
  i: integer;
  bmp: TCustomBitmap;
  TemplateEdit: TSynPluginTemplateEdit;
  SyncroEdit: TSynPluginSyncroEdit;
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
    FEditor := TIDESynEditor.Create(AOwner);
    FEditor.BeginUpdate;
    with FEditor do begin
      Name:=NewName;
      Text:='';
      Parent := AParent;
      Align := alClient;
      BookMarkOptions.EnableKeys := false;
      BookMarkOptions.LeftMargin:=1;
      BookMarkOptions.BookmarkImages := SourceEditorMarks.ImgList;
      Gutter.MarksPart.DebugMarksImageIndex := SourceEditorMarks.SourceLineImg;
      WantTabs := true;
      ScrollBars := ssAutoBoth;

      // IMPORTANT: when you change below, don't forget updating UnbindEditor
      OnStatusChange := @EditorStatusChanged;
      OnProcessCommand := @ProcessCommand;
      OnProcessUserCommand := @ProcessUserCommand;
      OnCommandProcessed := @UserCommandProcessed;
      OnReplaceText := @OnReplace;
      OnGutterClick := @Self.OnGutterClick;
      OnSpecialLineMarkup := @OnEditorSpecialLineColor;
      OnMouseMove := @EditorMouseMoved;
      OnMouseWheel := @EditorMouseWheel;
      OnMouseDown := @EditorMouseDown;
      OnClickLink := Manager.OnClickLink;
      OnMouseLink := Manager.OnMouseLink;
      OnKeyDown := @EditorKeyDown;
      OnPaste:=@EditorPaste;
      OnEnter:=@EditorEnter;
      OnPlaceBookmark := @EditorPlaceBookmark;
      OnClearBookmark := @EditorClearBookmark;
      // IMPORTANT: when you change above, don't forget updating UnbindEditor
    end;
    Manager.CodeTemplateModul.AddEditor(FEditor);
    Manager.NewEditorCreated(self);
    TemplateEdit:=TSynPluginTemplateEdit.Create(FEditor);
    TemplateEdit.OnActivate := @EditorActivateSyncro;
    TemplateEdit.OnDeactivate := @EditorDeactivateSyncro;
    SyncroEdit := TSynPluginSyncroEdit.Create(FEditor);
    bmp := CreateBitmapFromLazarusResource('tsynsyncroedit');
    SyncroEdit.GutterGlyph.Assign(bmp);
    bmp.Free;
    SyncroEdit.OnActivate := @EditorActivateSyncro;
    SyncroEdit.OnDeactivate := @EditorDeactivateSyncro;
    RefreshEditorSettings;
    FEditor.EndUpdate;
  end else begin
    FEditor.Parent:=AParent;
  end;
end;

procedure TSourceEditor.SetCodeBuffer(NewCodeBuffer: TCodeBuffer);
begin
  FSharedValues.CodeBuffer := NewCodeBuffer;
end;

procedure TSourceEditor.StartIdentCompletionBox(JumpToError: boolean);
var
  I: Integer;
  P: TPoint;
  TextS, TextS2: String;
  LogCaret: TPoint;
  UseWordCompletion: Boolean;
  Completion: TSourceEditCompletion;
begin
  {$IFDEF VerboseIDECompletionBox}
  debugln(['TSourceEditor.StartIdentCompletionBox JumpToError: ',JumpToError]);
  {$ENDIF}
  if (FEditor.ReadOnly) then exit;
  Completion := Manager.DefaultCompletionForm;
  if (Completion.CurrentCompletionType<>ctNone) then exit;
  Completion.IdentCompletionJumpToError := JumpToError;
  Completion.CurrentCompletionType:=ctIdentCompletion;
  TextS := FEditor.LineText;
  LogCaret:=FEditor.LogicalCaretXY;
  Completion.Editor:=FEditor;
  i := LogCaret.X - 1;
  if i > length(TextS) then
    TextS2 := ''
  else begin
    while (i > 0) and (TextS[i] in ['a'..'z','A'..'Z','0'..'9','_']) do
      dec(i);
    TextS2 := Trim(copy(TextS, i + 1, LogCaret.X - i - 1));
  end;
  with FEditor do begin
    P := Point(CaretXPix - length(TextS2)*CharWidth,CaretYPix + LineHeight + 1);
    P.X:=Max(0,Min(P.X,ClientWidth-Completion.Width));
    P := ClientToScreen(p);
  end;
  UseWordCompletion:=false;
  if not Manager.FindIdentCompletionPlugin
                 (Self, JumpToError, TextS2, P.X, P.Y, UseWordCompletion)
  then
    exit;
  if UseWordCompletion then
    Completion.CurrentCompletionType:=ctWordCompletion;

  Completion.Execute(TextS2,P.X,P.Y);
  {$IFDEF VerboseIDECompletionBox}
  debugln(['TSourceEditor.StartIdentCompletionBox END Completion.TheForm.Visible=',Completion.TheForm.Visible]);
  {$ENDIF}
end;

procedure TSourceEditor.StartWordCompletionBox(JumpToError: boolean);
var
  TextS: String;
  LogCaret: TPoint;
  i: Integer;
  TextS2: String;
  P: TPoint;
  Completion: TSourceEditCompletion;
begin
  if (FEditor.ReadOnly) then exit;
  Completion := Manager.DefaultCompletionForm;
  if (Completion.CurrentCompletionType<>ctNone) then exit;
  Completion.CurrentCompletionType:=ctWordCompletion;
  TextS := FEditor.LineText;
  LogCaret:=FEditor.LogicalCaretXY;
  Completion.Editor:=FEditor;
  i := LogCaret.X - 1;
  if i > length(TextS) then
    TextS2 := ''
  else begin
    while (i > 0) and (TextS[i] in ['a'..'z','A'..'Z','0'..'9','_']) do
      dec(i);
    TextS2 := Trim(copy(TextS, i + 1, LogCaret.X - i - 1));
  end;
  with FEditor do begin
    P := Point(CaretXPix - length(TextS2)*CharWidth,CaretYPix + LineHeight + 1);
    P.X:=Max(0,Min(P.X,ClientWidth - Completion.Width));
    P := ClientToScreen(p);
  end;
  Completion.Execute(TextS2,P.X,P.Y);
end;

procedure TSourceEditor.IncreaseIgnoreCodeBufferLock;
begin
  FSharedValues.IncreaseIgnoreCodeBufferLock;
end;

procedure TSourceEditor.DecreaseIgnoreCodeBufferLock;
begin
  FSharedValues.DecreaseIgnoreCodeBufferLock;
end;

procedure TSourceEditor.UpdateCodeBuffer;
// copy the source from EditorComponent to codetools
begin
  FSharedValues.UpdateCodeBuffer;
end;

function TSourceEditor.NeedsUpdateCodeBuffer: boolean;
begin
  Result := FSharedValues.NeedsUpdateCodeBuffer;
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
  if EditorOpts.ShowTabNumbers and (p < 10) then
    // Number pages 1, ..., 9, 0 -- according to Alt+N hotkeys.
    NewPageName:=Format('%s:%d', [FPageName, (p+1) mod 10])
  else
    NewPageName:=FPageName;
  if Modified then NewPageName:='*'+NewPageName;
  if SourceNotebook.NoteBookPages[p] <> NewPageName then
    SourceNotebook.NoteBookPages[p] := NewPageName;
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

Procedure TSourceEditor.SelectText(const StartPos, EndPos: TPoint);
Begin
  FEditor.BlockBegin := StartPos;
  FEditor.BlockEnd := EndPos;
end;

procedure TSourceEditor.ReplaceLines(StartLine, EndLine: integer;
  const NewText: string);
begin
  if ReadOnly then Exit;
  FEditor.TextBetweenPointsEx[Point(1,StartLine),
                            Point(length(FEditor.Lines[Endline-1])+1,EndLine),
                            scamEnd] := NewText;
end;

procedure TSourceEditor.EncloseSelection;
var
  EncloseType: TEncloseSelectionType;
  EncloseTemplate: string;
  NewSelection: string;
  NewCaretXY: TPoint;
begin
  if ReadOnly then exit;
  if not FEditor.SelAvail then
    exit;
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
  Result := FSharedValues.Modified;
end;

procedure TSourceEditor.SetModified(const NewValue: Boolean);
begin
  FSharedValues.SetModified(NewValue);
end;

Function TSourceEditor.GetInsertMode: Boolean;
Begin
  Result := FEditor.Insertmode;
end;

Function TSourceEditor.Close: Boolean;
Begin
  Result := True;
  Visible := False;
  Manager.EditorRemoved(Self);
  SourceEditorMarks.DeleteAllForEditor(Self);
  UnbindEditor;
  FEditor.Parent:=nil;
  if FSharedValues.SharedEditorCount = 1 then
    CodeBuffer := nil;
end;

procedure TSourceEditor.BeginUndoBlock;
begin
  FEditor.BeginUndoBlock;
end;

procedure TSourceEditor.EndUndoBlock;
begin
  FEditor.EndUndoBlock;
end;

procedure TSourceEditor.BeginUpdate;
begin
  FEditor.BeginUpdate;
end;

procedure TSourceEditor.EndUpdate;
begin
  FEditor.EndUpdate;
end;

procedure TSourceEditor.SetPopupMenu(NewPopupMenu: TPopupMenu);
begin
  if NewPopupMenu<>FPopupMenu then begin
    FPopupMenu:=NewPopupMenu;
    if FEditor<>nil then begin
      if FEditor.PopupMenu <> nil then // Todo: why?
        FEditor.PopupMenu.RemoveFreeNotification(FEditor);
      FEditor.PopupMenu:=NewPopupMenu;
    end;
  end;
end;

function TSourceEditor.GetFilename: string;
begin
  if CodeBuffer <> nil then
    Result := CodeBuffer.Filename
  else
    Result := '';
end;

function TSourceEditor.GetEditorControl: TWinControl;
begin
  Result:=FEditor;
end;

function TSourceEditor.GetCodeToolsBuffer: TObject;
begin
  Result:=CodeBuffer;
end;

procedure TSourceEditor.EditorPaste(Sender: TObject; var AText: String;
  var AMode: TSynSelectionMode; ALogStartPos: TPoint;
  var AnAction: TSynCopyPasteAction);
var
  p: integer;
  NestedComments: Boolean;
  NewIndent: TFABIndentationPolicy;
  Indent: LongInt;
  NewSrc: string;
begin
  if AMode<>smNormal then exit;
  if SyncroLockCount > 0 then exit;
  if not CodeToolsOpts.IndentOnPaste then exit;
  {$IFDEF VerboseIndenter}
  debugln(['TSourceEditor.EditorPaste LogCaret=',dbgs(ALogStartPos)]);
  {$ENDIF}
  if ALogStartPos.X>1 then exit;
  UpdateCodeBuffer;
  CodeBuffer.LineColToPosition(ALogStartPos.Y,ALogStartPos.X,p);
  if p<1 then exit;
  {$IFDEF VerboseIndenter}
  if ALogStartPos.Y>0 then
    DebugLn(['TSourceEditor.EditorPaste Y-1=',Lines[ALogStartPos.Y-2]]);
  DebugLn(['TSourceEditor.EditorPaste Y+0=',Lines[ALogStartPos.Y-1]]);
  if ALogStartPos.Y<LineCount then
    DebugLn(['TSourceEditor.EditorPaste Y+1=',Lines[ALogStartPos.Y+0]]);
  {$ENDIF}
  NestedComments:=CodeToolBoss.GetNestedCommentsFlagForFile(CodeBuffer.Filename);
  if not CodeToolBoss.Indenter.GetIndent(CodeBuffer.Source,p,NestedComments,
    true,NewIndent,CodeToolsOpts.IndentContextSensitive,AText)
  then exit;
  if not NewIndent.IndentValid then exit;
  Indent:=NewIndent.Indent-GetLineIndentWithTabs(AText,1,EditorComponent.TabWidth);
  {$IFDEF VerboseIndenter}
  debugln(AText);
  DebugLn(['TSourceEditor.EditorPaste Indent=',Indent]);
  {$ENDIF}
  IndentText(AText,Indent,EditorComponent.TabWidth,NewSrc);
  AText:=NewSrc;
  {$IFDEF VerboseIndenter}
  debugln(AText);
  DebugLn(['TSourceEditor.EditorPaste END']);
  {$ENDIF}
end;

procedure TSourceEditor.EditorPlaceBookmark(Sender: TObject;
  var Mark: TSynEditMark);
var
  i: Integer;
begin
  if FSharedValues.BookmarkEventLock > 0 then exit;
  inc(FSharedValues.BookmarkEventLock);
  try
    for i := 0 to FSharedValues.OtherSharedEditorCount -1 do
      FSharedValues.OtherSharedEditors[Self, i].EditorComponent.SetBookMark
        (Mark.BookmarkNumber, Mark.Column, Mark.Line);
  finally
    dec(FSharedValues.BookmarkEventLock);
  end;
  if Assigned(Manager) and Assigned(Manager.OnPlaceBookmark) then
    Manager.OnPlaceBookmark(Self, Mark);
end;

procedure TSourceEditor.EditorClearBookmark(Sender: TObject;
  var Mark: TSynEditMark);
var
  i: Integer;
begin
  if FSharedValues.BookmarkEventLock > 0 then exit;
  inc(FSharedValues.BookmarkEventLock);
  try
    for i := 0 to FSharedValues.OtherSharedEditorCount -1 do
      FSharedValues.OtherSharedEditors[Self, i].EditorComponent.ClearBookMark(Mark.BookmarkNumber);
  finally
    dec(FSharedValues.BookmarkEventLock);
  end;
  if Assigned(Manager) and Assigned(Manager.OnClearBookmark) then
    Manager.OnClearBookmark(Self, Mark);
end;

procedure TSourceEditor.EditorEnter(Sender: TObject);
begin
  if (FSourceNoteBook.FUpdateLock <> 0) or
     (FSourceNoteBook.FFocusLock <> 0)
  then exit;
  if (FSourceNoteBook.PageIndex = PageIndex) then
    Activate
  else
    SourceNotebook.GetActiveSE.FocusEditor;
    // Navigating with mousebuttons between editors (eg jump history on btn 4/5)
    // can trigger the old editor to be refocused (while not visible)
end;

procedure TSourceEditor.EditorActivateSyncro(Sender: TObject);
begin
  inc(FSyncroLockCount);
end;

procedure TSourceEditor.EditorDeactivateSyncro(Sender: TObject);
begin
  dec(FSyncroLockCount);
end;

function TSourceEditor.GetCodeBuffer: TCodeBuffer;
begin
  Result := FSharedValues.CodeBuffer;
end;

function TSourceEditor.GetExecutionLine: integer;
begin
  Result := FSharedValues.ExecutionLine;
end;

function TSourceEditor.GetHasExecutionMarks: Boolean;
begin
  Result := EditorComponent.IDEGutterMarks.HasDebugMarks;
end;

function TSourceEditor.GetSharedEditors(Index: Integer): TSourceEditor;
begin
  Result := FSharedValues.SharedEditors[Index];
end;

Procedure TSourceEditor.EditorMouseMoved(Sender: TObject;
  Shift: TShiftState; X,Y: Integer);
begin
//  Writeln('MouseMove in Editor',X,',',Y);
  if Assigned(OnMouseMove) then
    OnMouseMove(Self,Shift,X,Y);
end;

procedure TSourceEditor.EditorMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
//  Writeln('MouseWheel in Editor');
  if Assigned(OnMouseWheel) then
    OnMouseWheel(Self, Shift, WheelDelta, MousePos, Handled)
end;

Procedure TSourceEditor.EditorMouseDown(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(OnMouseDown) then
    OnMouseDown(Sender, Button, Shift, X,Y);
end;

Procedure TSourceEditor.EditorKeyDown(Sender: TObject; var Key: Word; Shift :
  TShiftState);
begin
  //DebugLn('TSourceEditor.EditorKeyDown A ',dbgsName(Sender),' ',IntToStr(Key));
  if Assigned(OnKeyDown) then
    OnKeyDown(Sender, Key, Shift);
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

function TSourceEditor.TextToScreenPosition(const Position: TPoint): TPoint;
begin
  Result:=FEditor.LogicalToPhysicalPos(Position);
end;

function TSourceEditor.ScreenToTextPosition(const Position: TPoint): TPoint;
begin
  Result:=FEditor.PhysicalToLogicalPos(Position);
end;

function TSourceEditor.ScreenToPixelPosition(const Position: TPoint): TPoint;
begin
  Result:=FEditor.RowColumnToPixels(Position);
end;

function TSourceEditor.LineCount: Integer;
begin
  Result:=FEditor.Lines.Count;
end;

function TSourceEditor.WidthInChars: Integer;
begin
  Result:=FEditor.CharsInWindow;
end;

function TSourceEditor.HeightInLines: Integer;
begin
  Result:=FEditor.LinesInWindow;
end;

function TSourceEditor.CharWidth: integer;
begin
  Result:=FEditor.CharWidth;
end;

function TSourceEditor.GetLineText: string;
begin
  Result:=FEditor.LineText;
end;

procedure TSourceEditor.SetLineText(const AValue: string);
begin
  FEditor.LineText:=AValue;
end;

function TSourceEditor.GetLines: TStrings;
begin
  Result:=FEditor.Lines;
end;

procedure TSourceEditor.SetLines(const AValue: TStrings);
begin
  FEditor.Lines:=AValue;
end;

function TSourceEditor.GetProjectFile: TLazProjectFile;
begin
  Result:=LazarusIDE.GetProjectFileForProjectEditor(Self);
end;

procedure TSourceEditor.UpdateProjectFile;
begin
  if Assigned(Manager) and Assigned(Manager.OnEditorMoved)
    then Manager.OnEditorMoved(self);
end;

function TSourceEditor.GetDesigner(LoadForm: boolean): TIDesigner;
begin
  Result:=LazarusIDE.GetDesignerForProjectEditor(Self, LoadForm)
end;

function TSourceEditor.GetCursorScreenXY: TPoint;
begin
  Result:=FEditor.CaretXY;
end;

function TSourceEditor.GetCursorTextXY: TPoint;
begin
  Result:=FEditor.LogicalCaretXY;
end;

procedure TSourceEditor.SetCursorScreenXY(const AValue: TPoint);
begin
  FEditor.CaretXY:=AValue;
end;

procedure TSourceEditor.SetCursorTextXY(const AValue: TPoint);
begin
  FEditor.LogicalCaretXY:=AValue;
end;

function TSourceEditor.GetBlockBegin: TPoint;
begin
  Result:=FEditor.BlockBegin;
end;

function TSourceEditor.GetBlockEnd: TPoint;
begin
  Result:=FEditor.BlockEnd;
end;

procedure TSourceEditor.SetBlockBegin(const AValue: TPoint);
begin
  FEditor.BlockBegin:=AValue;
end;

procedure TSourceEditor.SetBlockEnd(const AValue: TPoint);
begin
  FEditor.BlockEnd:=AValue;
end;

function TSourceEditor.GetTopLine: Integer;
begin
  Result:=FEditor.TopLine;
end;

procedure TSourceEditor.SetTopLine(const AValue: Integer);
begin
  FEditor.TopLine:=AValue;
end;

function TSourceEditor.CursorInPixel: TPoint;
begin
  Result:=Point(FEditor.CaretXPix,FEditor.CaretYPix);
end;

function TSourceEditor.SearchReplace(const ASearch, AReplace: string;
  SearchOptions: TSrcEditSearchOptions): integer;
const
  SrcEdit2SynEditSearchOption: array[TSrcEditSearchOption] of TSynSearchOption =(
    ssoMatchCase,
    ssoWholeWord,
    ssoBackwards,
    ssoEntireScope,
    ssoSelectedOnly,
    ssoReplace,
    ssoReplaceAll,
    ssoPrompt,
    ssoRegExpr,
    ssoRegExprMultiLine
  );
var
  OldOptions, NewOptions: TSynSearchOptions;
  o: TSrcEditSearchOption;
begin
  OldOptions:=LazFindReplaceDialog.Options;
  NewOptions:=[];
  for o:=Low(TSrcEditSearchOption) to High(TSrcEditSearchOption) do
    if o in SearchOptions then
      Include(NewOptions,SrcEdit2SynEditSearchOption[o]);
  LazFindReplaceDialog.Options:=NewOptions;
  Result:=DoFindAndReplace;
  LazFindReplaceDialog.Options:=OldOptions;
end;

function TSourceEditor.GetSourceText: string;
begin
  Result:=FEditor.Text;
end;

procedure TSourceEditor.SetSourceText(const AValue: string);
begin
  FEditor.Text:=AValue;
end;

procedure TSourceEditor.Activate;
begin
{ $note: avoid this if FSourceNoteBook.FUpdateLock > 0 / e.g. debugger calls ProcessMessages, and the internall Index is lost/undone}
  if (FSourceNoteBook=nil) then exit;
  if (FSourceNoteBook.FUpdateLock = 0) then
    FSourceNoteBook.ActiveEditor := Self;
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

function TSourceEditor.IsActiveOnNoteBook: boolean;
begin
  if FSourceNoteBook<>nil then
    Result:=(FSourceNoteBook.GetActiveSE=Self)
  else
    Result:=false;
end;

procedure TSourceEditor.FillExecutionMarks;
var
  ASource: String;
  i, idx: integer;
  Addr: TDBGPtr;
begin
  if EditorComponent.IDEGutterMarks.HasDebugMarks then Exit;

  ASource := FileName;
  idx := DebugBoss.LineInfo.IndexOf(ASource);
  if (idx = -1) then
  begin
    if not FSharedValues.MarksRequested then
    begin
      FSharedValues.MarksRequested := True;
      DebugBoss.LineInfo.AddNotification(FLineInfoNotification);
      DebugBoss.LineInfo.Request(ASource);
    end;
    Exit;
  end;

  for i := 0 to EditorComponent.Lines.Count - 1 do
  begin
    Addr := DebugBoss.LineInfo.GetAddress(idx, i);
    if (Addr <> 0) then
      EditorComponent.IDEGutterMarks.SetDebugMarks(i, i);
  end;
end;

procedure TSourceEditor.ClearExecutionMarks;
begin
  EditorComponent.IDEGutterMarks.ClearDebugMarks;
  FSharedValues.MarksRequested := False;
  if (FLineInfoNotification <> nil) and (DebugBoss <> nil) and (DebugBoss.LineInfo <> nil) then
    DebugBoss.LineInfo.RemoveNotification(FLineInfoNotification);
end;

procedure TSourceEditor.LineInfoNotificationChange(const ASender: TObject; const ASource: String);
begin
  if ASource = FileName then
    FillExecutionMarks;
end;

function TSourceEditor.SourceToDebugLine(aLinePos: Integer): Integer;
begin
  Result := FEditor.IDEGutterMarks.SourceLineToDebugLine(aLinePos, True);
end;

function TSourceEditor.DebugToSourceLine(aLinePos: Integer): Integer;
begin
  Result := FEditor.IDEGutterMarks.DebugLineToSourceLine(aLinePos);
end;

function TSourceEditor.SharedEditorCount: Integer;
begin
  Result := FSharedValues.SharedEditorCount;
  if Result = 1 then
    Result := 0; // not a sharing editor
end;

function TSourceEditor.GetWordAtCurrentCaret: String;
var
  CaretPos: TPoint;
begin
  CaretPos.Y := CurrentCursorYLine;
  CaretPos.X := CurrentCursorXLine;
  Result := GetWordFromCaret(ScreenToTextPosition(CaretPos));
end;

function TSourceEditor.GetOperandFromCaret(const ACaretPos: TPoint): String;
begin
  if not CodeToolBoss.ExtractOperand(CodeBuffer, ACaretPos.X, ACaretPos.Y,
    Result, False, False, true)
  then
    Result := GetWordFromCaret(ACaretPos);
end;

function TSourceEditor.GetOperandAtCurrentCaret: String;
var
  CaretPos: TPoint;
begin
  CaretPos.Y := CurrentCursorYLine;
  CaretPos.X := CurrentCursorXLine;
  Result := GetOperandFromCaret(ScreenToTextPosition(CaretPos));
end;

function TSourceEditor.GetWordFromCaret(const ACaretPos: TPoint): String;
begin
  Result := FEditor.GetWordAtRowCol(ACaretPos);
end;

procedure TSourceEditor.LinesDeleted(Sender: TObject; FirstLine,
  Count: Integer);
begin
  // notify the notebook that lines were deleted.
  // marks will use this to update themselves
  if (Self = FSharedValues.SharedEditors[0]) then
    MessagesView.SrcEditLinesInsertedDeleted(Filename,FirstLine,-Count);
end;

procedure TSourceEditor.LinesInserted(Sender: TObject; FirstLine,
  Count: Integer);
begin
  // notify the notebook that lines were Inserted.
  // marks will use this to update themselves
  if (Self = FSharedValues.SharedEditors[0]) then
    MessagesView.SrcEditLinesInsertedDeleted(Filename,FirstLine,Count);
end;

procedure TSourceEditor.SetVisible(Value: boolean);
begin
  if FVisible=Value then exit;
  if FEditor<>nil then FEditor.Visible:=Value;
  FVisible:=Value;
end;

procedure TSourceEditor.UnbindEditor;
// disconnect all events
var
  i: Integer;
begin
  with EditorComponent do begin
    OnStatusChange := nil;
    OnProcessCommand := nil;
    OnProcessUserCommand := nil;
    OnCommandProcessed := nil;
    OnReplaceText := nil;
    OnGutterClick := nil;
    OnSpecialLineMarkup := nil;
    OnMouseMove := nil;
    OnMouseWheel := nil;
    OnMouseDown := nil;
    OnClickLink := nil;
    OnMouseLink := nil;
    OnKeyDown := nil;
    OnEnter := nil;
    OnPlaceBookmark := nil;
    OnClearBookmark := nil;
  end;
  for i := 0 to EditorComponent.PluginCount - 1 do
    if EditorComponent.Plugin[i] is TSynPluginSyncronizedEditBase then begin
      TSynPluginSyncronizedEditBase(EditorComponent.Plugin[i]).OnActivate := nil;
      TSynPluginSyncronizedEditBase(EditorComponent.Plugin[i]).OnDeactivate := nil;
    end;
  if FEditPlugin<>nil then begin
    FEditPlugin.OnLinesInserted := nil;
    FEditPlugin.OnLinesDeleted := nil;
  end;
end;

procedure TSourceEditor.DoEditorExecuteCommand(EditorCommand: word);
begin
  EditorComponent.CommandProcessor(TSynEditorCommand(EditorCommand),' ',nil);
end;

{------------------------------------------------------------------------}
                      { TSourceNotebook }

constructor TSourceNotebook.Create(AOwner: TComponent);
var
  i: Integer;
  n: TComponent;
begin
  inherited Create(AOwner);
  FManager := TSourceEditorManager(AOwner);
  FUpdateLock := 0;
  FFocusLock := 0;
  Visible:=false;
  FIsClosing := False;
  i := 2;
  n := Owner.FindComponent(NonModalIDEWindowNames[nmiwSourceNoteBookName]);
  if (n <> nil) and (n <> self) then begin
    while Owner.FindComponent(NonModalIDEWindowNames[nmiwSourceNoteBookName]+IntToStr(i)) <> nil do
      inc(i);
    Name := NonModalIDEWindowNames[nmiwSourceNoteBookName] + IntToStr(i);
  end
  else
    Name := NonModalIDEWindowNames[nmiwSourceNoteBookName];
  if Manager.SourceWindowCount > 0 then
    Caption := locWndSrcEditor + ' (' + IntToStr(Manager.SourceWindowCount+1) + ')'
  else
    Caption := locWndSrcEditor;
  KeyPreview:=true;
  FProcessingCommand := false;

  if EnvironmentOptions.IDEWindowLayoutList.ItemByFormID(self.Name) = nil then
    EnvironmentOptions.CreateWindowLayout(self.name);
  EnvironmentOptions.IDEWindowLayoutList.Apply(Self, self.Name);
  ControlDocker:=TLazControlDocker.Create(Self);
  ControlDocker.Name:='SourceEditor';
  {$IFDEF EnableIDEDocking}
  ControlDocker.Manager:=LazarusIDE.DockingManager;
  {$ENDIF}

  FSourceEditorList := TList.Create;

  // key mapping
  FKeyStrokes:=TSynEditKeyStrokes.Create(Self);
  EditorOpts.KeyMap.AssignTo(FKeyStrokes,TSourceEditorWindowInterface);

  // popup menu
  BuildPopupMenu;

  // HintTimer
  FMouseHintTimer := TIdleTimer.Create(Self);
  with FMouseHintTimer do begin
    Name:=Self.Name+'_MouseHintTimer';
    Interval := EditorOpts.AutoDelayInMSec;
    Enabled := False;
    AutoEnabled := False;
    OnTimer := @HintTimer;
  end;

  // HintWindow
  FHintWindow := THintWindow.Create(Self);
  with FHintWindow do begin
    Name:=Self.Name+'_HintWindow';
    Visible := False;
    Caption := '';
    HideInterval := 4000;
    AutoHide := False;
  end;

  CreateNotebook;
  Application.AddOnUserInputHandler(@OnApplicationUserInput,true);
end;

destructor TSourceNotebook.Destroy;
var
  i: integer;
begin
  if assigned(Manager) then
    Manager.RemoveWindow(Self);
  DisableAutoSizing{$IFDEF DebugDisableAutoSizing}('TSourceNotebook.Destroy'){$ENDIF};
  FProcessingCommand:=false;
  for i:=FSourceEditorList.Count-1 downto 0 do
    Editors[i].Free;
  FKeyStrokes.Free;
  FSourceEditorList.Free;

  Application.RemoveOnUserInputHandler(@OnApplicationUserInput);
  FreeThenNil(FMouseHintTimer);
  FreeThenNil(FHintWindow);
  FreeAndNil(FNotebook);

  inherited Destroy;
end;

procedure TSourceNotebook.DeactivateCompletionForm;
begin
  Manager.DeactivateCompletionForm;
end;

Procedure TSourceNotebook.CreateNotebook;
Begin
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.CreateNotebook] START');
  {$ENDIF}
  {$IFDEF IDE_MEM_CHECK}
  CheckHeapWrtMemCnt('[TSourceNotebook.CreateNotebook] A ');
  {$ENDIF}
  FNotebook := TSourceDragableNotebook.Create(self);
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.CreateNotebook] B');
  {$ENDIF}
  {$IFDEF IDE_MEM_CHECK}
  CheckHeapWrtMemCnt('[TSourceNotebook.CreateNotebook] B ');
  {$ENDIF}
  with FNotebook do Begin
    Name:='SrcEditNotebook';
    Parent := Self;
    {$IFDEF IDE_DEBUG}
    writeln('[TSourceNotebook.CreateNotebook] C');
    {$ENDIF}
    Align := alClient;
    if PageCount>0 then
      Pages.Strings[0] := 'unit1'
    else
      Pages.Add('unit1');
    PageIndex := 0;   // Set it to the first page
    if not (nbcPageListPopup in GetCapabilities) then
      PopupMenu := SrcPopupMenu;
    if EditorOpts.ShowTabCloseButtons then
      Options:=Options+[nboShowCloseButtons]
    else
      Options:=Options-[nboShowCloseButtons];
    TabPosition := EditorOpts.TabPosition;
    OnPageChanged := @NotebookPageChanged;
    OnCloseTabClicked:=@CloseTabClicked;
    OnMouseDown:=@NotebookMouseDown;
    OnCanDragMoveTab := @NotebookCanDragTabMove;
    OnDragMoveTab := @NotebookDragTabMove;
    ShowHint:=true;
    OnShowHint:=@NotebookShowTabHint;
    {$IFDEF IDE_DEBUG}
    writeln('[TSourceNotebook.CreateNotebook] D');
    {$ENDIF}
    Visible := False;
  end; //with
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.CreateNotebook] END');
  {$ENDIF}
  {$IFDEF IDE_MEM_CHECK}
  CheckHeapWrtMemCnt('[TSourceNotebook.CreateNotebook] END ');
  {$ENDIF}
End;

procedure TSourceNotebook.EditorPropertiesClicked(Sender: TObject);
begin
  if assigned(Manager) and Assigned(Manager.OnEditorPropertiesClicked) then
    Manager.OnEditorPropertiesClicked(Sender);
end;

procedure TSourceNotebook.LineEndingClicked(Sender: TObject);
var
  IDEMenuItem: TIDEMenuItem;
  SrcEdit: TSourceEditor;
  NewLineEnding: String;
  OldLineEnding: String;
begin
  SrcEdit:=GetActiveSE;
  if SrcEdit=nil then exit;
  if not (Sender is TIDEMenuItem) then exit;
  if SrcEdit.CodeBuffer=nil then exit;
  IDEMenuItem:=TIDEMenuItem(Sender);
  NewLineEnding:=IDEMenuItem.Caption;
  DebugLn(['TSourceNotebook.LineEndingClicked NewLineEnding=',NewLineEnding]);
  NewLineEnding:=StringReplace(StringReplace(NewLineEnding,'CR',#13,[rfReplaceAll]),'LF',#10,[rfReplaceAll]);
  OldLineEnding:=SrcEdit.CodeBuffer.DiskLineEnding;
  if OldLineEnding='' then
    OldLineEnding:=LineEnding;
  if NewLineEnding<>SrcEdit.CodeBuffer.DiskLineEnding then begin
    DebugLn(['TSourceNotebook.LineEndingClicked Old=',dbgstr(OldLineEnding),' New=',dbgstr(NewLineEnding)]);
    // change file
    SrcEdit.CodeBuffer.DiskLineEnding:=NewLineEnding;
    SrcEdit.CodeBuffer.Modified:=true;
    SrcEdit.Modified:=true;
  end;
end;

procedure TSourceNotebook.EncodingClicked(Sender: TObject);
var
  IDEMenuItem: TIDEMenuItem;
  SrcEdit: TSourceEditor;
  NewEncoding: String;
  OldEncoding: String;
  CurResult: TModalResult;
begin
  SrcEdit:=GetActiveSE;
  if SrcEdit=nil then exit;
  if Sender is TIDEMenuItem then begin
    IDEMenuItem:=TIDEMenuItem(Sender);
    NewEncoding:=IDEMenuItem.Caption;
    if SysUtils.CompareText(copy(NewEncoding,1,length(EncodingAnsi)+2),EncodingAnsi+' (')=0
    then begin
      // the ansi encoding is shown as 'ansi (system encoding)' -> cut
      NewEncoding:=EncodingAnsi;
    end else if NewEncoding=lisUtf8WithBOM then begin
      NewEncoding:=EncodingUTF8BOM;
    end;
    DebugLn(['TSourceNotebook.EncodingClicked NewEncoding=',NewEncoding]);
    if SrcEdit.CodeBuffer<>nil then begin
      OldEncoding:=NormalizeEncoding(SrcEdit.CodeBuffer.DiskEncoding);
      if OldEncoding='' then
        OldEncoding:=GetDefaultTextEncoding;
      if NewEncoding<>SrcEdit.CodeBuffer.DiskEncoding then begin
        DebugLn(['TSourceNotebook.EncodingClicked Old=',OldEncoding,' New=',NewEncoding]);
        if SrcEdit.ReadOnly then begin
          if SrcEdit.CodeBuffer.IsVirtual then
            CurResult:=mrCancel
          else
            CurResult:=IDEQuestionDialog(lisChangeEncoding,
              Format(lisEncodingOfFileOnDiskIsNewEncodingIs, ['"',
                SrcEdit.CodeBuffer.Filename, '"', #13, OldEncoding, NewEncoding]),
              mtConfirmation, [mrOk, lisReopenWithAnotherEncoding, mrCancel], '');
        end else begin
          if SrcEdit.CodeBuffer.IsVirtual then
            CurResult:=IDEQuestionDialog(lisChangeEncoding,
              Format(lisEncodingOfFileOnDiskIsNewEncodingIs, ['"',
                SrcEdit.CodeBuffer.Filename, '"', #13, OldEncoding, NewEncoding]),
              mtConfirmation, [mrYes, lisChangeFile, mrCancel], '')
          else
            CurResult:=IDEQuestionDialog(lisChangeEncoding,
              Format(lisEncodingOfFileOnDiskIsNewEncodingIs2, ['"',
                SrcEdit.CodeBuffer.Filename, '"', #13, OldEncoding, NewEncoding]),
              mtConfirmation, [mrYes, lisChangeFile, mrOk,
                lisReopenWithAnotherEncoding, mrCancel], '');
        end;
        if CurResult=mrYes then begin
          // change file
          SrcEdit.CodeBuffer.DiskEncoding:=NewEncoding;
          SrcEdit.CodeBuffer.Modified:=true;
          // set override
          InputHistories.FileEncodings[SrcEdit.CodeBuffer.Filename]:=NewEncoding;
          DebugLn(['TSourceNotebook.EncodingClicked Change file to ',SrcEdit.CodeBuffer.DiskEncoding]);
          if (not SrcEdit.CodeBuffer.IsVirtual)
          and (LazarusIDE.DoSaveEditorFile(SrcEdit, []) <> mrOk)
          then begin
            DebugLn(['TSourceNotebook.EncodingClicked LazarusIDE.DoSaveEditorFile failed']);
          end;
        end else if CurResult=mrOK then begin
          // reopen with another encoding
          if SrcEdit.Modified then begin
            if IDEQuestionDialog(lisAbandonChanges,
              Format(lisAllYourModificationsToWillBeLostAndTheFileReopened, [
                '"', SrcEdit.CodeBuffer.Filename, '"', #13]),
              mtConfirmation,[mbOk,mbAbort],'')<>mrOk
            then begin
              exit;
            end;
          end;
          // set override
          InputHistories.FileEncodings[SrcEdit.CodeBuffer.Filename]:=NewEncoding;
          if not SrcEdit.CodeBuffer.Revert then begin
            IDEMessageDialog(lisCodeToolsDefsReadError,
              Format(lisUnableToRead, [SrcEdit.CodeBuffer.Filename]),
              mtError,[mbCancel],'');
            exit;
          end;
          SrcEdit.EditorComponent.BeginUpdate;
          SrcEdit.CodeBuffer.AssignTo(SrcEdit.EditorComponent.Lines,true);
          SrcEdit.EditorComponent.EndUpdate;
        end;
      end;
    end;
  end;
end;

procedure TSourceNotebook.HighlighterClicked(Sender: TObject);
var
  IDEMenuItem: TIDEMenuItem;
  i: LongInt;
  SrcEdit: TSourceEditor;
  h: TLazSyntaxHighlighter;
begin
  SrcEdit:=GetActiveSE;
  if SrcEdit=nil then exit;
  if Sender is TIDEMenuItem then begin
    IDEMenuItem:=TIDEMenuItem(Sender);
    i:=IDEMenuItem.SectionIndex;
    if (i>=ord(Low(TLazSyntaxHighlighter)))
    and (i<=ord(High(TLazSyntaxHighlighter))) then begin
      h:=TLazSyntaxHighlighter(i);
      SrcEdit.SyntaxHighlighterType:=h;
    end;
  end;
end;

procedure TSourceNotebook.SrcPopUpMenuPopup(Sender: TObject);
var
  ASrcEdit: TSourceEditor;
  BookMarkID, BookMarkX, BookMarkY: integer;
  MarkSrcEdit: TSourceEditor;
  MarkDesc: String;
  MarkMenuItem: TIDEMenuItem;
  EditorComp: TSynEdit;
  Marks: PSourceMark;
  MarkCount: integer;
  i: Integer;
  NBAvail: Boolean;
  CurMark: TSourceMark;
  EditorPopupPoint, EditorCaret: TPoint;
  SelAvail: Boolean;
  SelAvailAndWritable: Boolean;
  CurFilename: String;
  CurWordAtCursor: String;
  AtIdentifier: Boolean;
begin
  //DebugLn(['TSourceNotebook.SrcPopUpMenuPopup ',dbgsName(Sender)]);
  //SourceEditorMenuRoot.WriteDebugReport('TSourceNotebook.SrcPopUpMenuPopup START ',true);
  //SourceEditorMenuRoot.ConsistencyCheck;

  SourceEditorMenuRoot.MenuItem:=SrcPopupMenu.Items;
  SourceEditorMenuRoot.BeginUpdate;
  AssignPopupMenu; // Point all on click events to this SourceNoteBook
  try
    RemoveUserDefinedMenuItems;
    RemoveContextMenuItems;

    ASrcEdit:=
         FindSourceEditorWithEditorComponent(TPopupMenu(Sender).PopupComponent);
    if ASrcEdit=nil then begin
      ASrcEdit:=GetActiveSE;
      if ASrcEdit=nil then begin
        DebugLn(['TSourceNotebook.SrcPopUpMenuPopup ASrcEdit=nil ',dbgsName(TPopupMenu(Sender).PopupComponent)]);
        exit;
      end;
    end;
    EditorComp:=ASrcEdit.EditorComponent;

    // Clipboard
    SrcEditMenuCut.Enabled := ASrcEdit.SelectionAvailable and not ASrcEdit.ReadOnly;
    SrcEditMenuCopy.Enabled := ASrcEdit.SelectionAvailable;
    SrcEditMenuPaste.Enabled := not ASrcEdit.ReadOnly;

    // Readonly, ShowLineNumbers
    SrcEditMenuReadOnly.MenuItem.Checked:=ASrcEdit.ReadOnly;
    SrcEditMenuShowLineNumbers.MenuItem.Checked :=
      EditorComp.Gutter.LineNumberPart.Visible;
    UpdateHighlightMenuItems;
    UpdateLineEndingMenuItems;
    UpdateEncodingMenuItems;

    // bookmarks
    for BookMarkID:=0 to 9 do begin
      MarkDesc:=' '+IntToStr(BookMarkID);
      MarkSrcEdit := nil;
      i := 0;
      while i < Manager.SourceEditorCount do begin
        if Manager.SourceEditors[i].EditorComponent.GetBookMark
          (BookMarkID,BookMarkX,BookMarkY)
      then begin
          MarkDesc := MarkDesc+': ' + Manager.SourceEditors[i].PageName
          +' ('+IntToStr(BookMarkY)+','+IntToStr(BookMarkX)+')';
          break;
        end;
        inc(i);
      end;
      // goto book mark item
      MarkMenuItem:=SrcEditSubMenuGotoBookmarks[BookMarkID];
      if MarkMenuItem is TIDEMenuCommand then
        TIDEMenuCommand(MarkMenuItem).Checked:=(MarkSrcEdit<>nil);
      MarkMenuItem.Caption:=uemBookmarkN+MarkDesc;
      // set book mark item
      MarkMenuItem:=SrcEditSubMenuToggleBookmarks[BookMarkID];
      if MarkMenuItem is TIDEMenuCommand then
        TIDEMenuCommand(MarkMenuItem).Checked:=(MarkSrcEdit<>nil);
      MarkMenuItem.Caption:=uemToggleBookmark+MarkDesc;
    end;

    // editor layout
    SrcEditMenuMoveEditorLeft.MenuItem.Enabled:= (PageCount>1);
    SrcEditMenuMoveEditorRight.MenuItem.Enabled:= (PageCount>1);
    SrcEditMenuMoveEditorFirst.MenuItem.Enabled:= (PageCount>1) and (PageIndex>0);
    SrcEditMenuMoveEditorLast.MenuItem.Enabled:= (PageCount>1) and (PageIndex<(PageCount-1));

    EditorPopupPoint:=EditorComp.ScreenToClient(SrcPopUpMenu.PopupPoint);
    if EditorPopupPoint.X>EditorComp.GutterWidth then begin
      // user clicked on text
      // collect some flags
      SelAvail:=ASrcEdit.EditorComponent.SelAvail;
      SelAvailAndWritable:=SelAvail and (not ASrcEdit.ReadOnly);
      // enable menu items
      SrcEditMenuEncloseSelection.Enabled := SelAvailAndWritable;
      SrcEditMenuExtractProc.Enabled := SelAvailAndWritable;
      SrcEditMenuInvertAssignment.Enabled := SelAvailAndWritable;
      CurWordAtCursor:=ASrcEdit.GetWordAtCurrentCaret;
      AtIdentifier:=IsValidIdent(CurWordAtCursor);
      SrcEditMenuFindIdentifierReferences.Enabled:=AtIdentifier;
      SrcEditMenuRenameIdentifier.Enabled:=AtIdentifier
                                           and (not ASrcEdit.ReadOnly);
      SrcEditMenuShowAbstractMethods.Enabled:=not ASrcEdit.ReadOnly;
      SrcEditMenuShowEmptyMethods.Enabled:=not ASrcEdit.ReadOnly;
      SrcEditMenuFindOverloads.Enabled:=AtIdentifier;
    end else
    begin
      EditorCaret := EditorComp.PhysicalToLogicalPos(EditorComp.PixelsToRowColumn(EditorPopupPoint));
      // user clicked on gutter
      SourceEditorMarks.GetMarksForLine(ASrcEdit, EditorCaret.y,
                                        Marks, MarkCount);
      if Marks <> nil then
      begin
        for i := 0 to MarkCount - 1 do
        begin
          CurMark := Marks[i];
          CurMark.CreatePopupMenuItems(@AddUserDefinedPopupMenuItem);
        end;
        FreeMem(Marks);
      end;
    end;

    // add context specific menu items
    CurFilename:=ASrcEdit.FileName;
    if (FilenameIsAbsolute(CurFilename)) then begin
      if FilenameIsPascalUnit(CurFilename) then begin
        if FileExistsUTF8(ChangeFileExt(CurFilename,'.lfm')) then
          AddContextPopupMenuItem(Format(lisOpenLfm,
            [ChangeFileExt(ExtractFileName(CurFilename),'.lfm')]),
            true,@OnPopupMenuOpenLFMFile);
        if FileExistsUTF8(ChangeFileExt(CurFilename,'.lrs')) then
          AddContextPopupMenuItem(Format(lisOpenLfm,
            [ChangeFileExt(ExtractFileName(CurFilename),'.lrs')]),
            true,@OnPopupMenuOpenLRSFile);
        if FileExistsUTF8(ChangeFileExt(CurFilename,'.s')) then
          AddContextPopupMenuItem(Format(lisOpenLfm,
            [ChangeFileExt(ExtractFileName(CurFilename),'.s')]),
            true,@OnPopupMenuOpenSFile);
      end;
      if (CompareFileExt(CurFilename,'.lfm',true)=0) then begin
        if FileExistsUTF8(ChangeFileExt(CurFilename,'.pas')) then
          AddContextPopupMenuItem(Format(lisOpenLfm,
            [ChangeFileExt(ExtractFileName(CurFilename),'.pas')]),
            true,@OnPopupMenuOpenPasFile);
        if FileExistsUTF8(ChangeFileExt(CurFilename,'.pp')) then
          AddContextPopupMenuItem(Format(lisOpenLfm,
            [ChangeFileExt(ExtractFileName(CurFilename),'.pp')]),
            true,@OnPopupMenuOpenPPFile);
        if FileExistsUTF8(ChangeFileExt(CurFilename,'.p')) then
          AddContextPopupMenuItem(Format(lisOpenLfm,
            [ChangeFileExt(ExtractFileName(CurFilename),'.p')]),
            true,@OnPopupMenuOpenPFile);
      end;
      if (CompareFileExt(CurFilename,'.lpi',true)=0)
      or (CompareFileExt(CurFilename,'.lpk',true)=0) then begin
        AddContextPopupMenuItem(Format(lisOpenLfm,
          [ExtractFileName(CurFilename)]),true,@OnPopupMenuOpenFile);
      end;
    end;

    {$IFnDEF SingleSrcWindow}
    SrcEditMenuMoveToOtherWindowList.Clear;
    NBAvail := False;
    for i := 0 to Manager.SourceWindowCount - 1 do
      if (i <> Manager.IndexOfSourceWindow(self)) and
         (Manager.SourceWindows[i].IndexOfEditorInShareWith(GetActiveSE) < 0)
      then begin
        NBAvail := True;
        with RegisterIDEMenuCommand(SrcEditMenuMoveToOtherWindowList,
                                    'MoveToWindow'+IntToStr(i),
                                    Manager.SourceWindows[i].Caption,
                                    @SrcEditMenuMoveToExistingWindowClicked)
        do
          Tag := i;
      end;
    SrcEditMenuMoveToNewWindow.Visible := not NBAvail;
    SrcEditMenuMoveToNewWindow.Enabled := PageCount > 1;
    SrcEditMenuMoveToOtherWindow.Visible := NBAvail;
    SrcEditMenuMoveToOtherWindowNew.Enabled := (PageCount > 1);

    NBAvail := False;
    SrcEditMenuCopyToOtherWindowList.Clear;
    for i := 0 to Manager.SourceWindowCount - 1 do
      if (Manager.SourceWindows[i].IndexOfEditorInShareWith(GetActiveSE) < 0) and
         (i <> Manager.IndexOfSourceWindow(self))
      then begin
        NBAvail := True;
        with RegisterIDEMenuCommand(SrcEditMenuCopyToOtherWindowList,
                                    'CopyToWindow'+IntToStr(i),
                                    Manager.SourceWindows[i].Caption,
                                    @SrcEditMenuCopyToExistingWindowClicked)
        do
          Tag := i;
      end;
    SrcEditMenuCopyToNewWindow.Visible := not NBAvail;
    SrcEditMenuCopyToOtherWindow.Visible := NBAvail;
    {$ENDIF}

    if Assigned(Manager.OnPopupMenu) then Manager.OnPopupMenu(@AddContextPopupMenuItem);

    SourceEditorMenuRoot.NotifySubSectionOnShow(Self);
  finally
    SourceEditorMenuRoot.EndUpdate;
  end;
  //SourceEditorMenuRoot.WriteDebugReport('TSourceNotebook.SrcPopUpMenuPopup END ',true);
  //SourceEditorMenuRoot.ConsistencyCheck;
end;

procedure TSourceNotebook.NotebookShowTabHint(Sender: TObject;
  HintInfo: PHintInfo);
var
  Tabindex: integer;
  ASrcEdit: TSourceEditor;
begin
  if (PageCount=0) or (HintInfo=nil) then exit;
  TabIndex:=FNoteBook.TabIndexAtClientPos(FNotebook.ScreenToClient(Mouse.CursorPos));
  if TabIndex<0 then exit;
  ASrcEdit:=FindSourceEditorWithPageIndex(TabIndex);
  if ASrcEdit=nil then exit;
  if ASrcEdit.CodeBuffer<>nil then begin
    HintInfo^.HintStr:=ASrcEdit.CodeBuffer.Filename;
  end;
end;

function TSourceNotebook.GetItems(Index: integer): TSourceEditorInterface;
begin
  Result:=TSourceEditorInterface(FSourceEditorList[Index]);
end;

Procedure TSourceNotebook.BuildPopupMenu;
begin
  //debugln('TSourceNotebook.BuildPopupMenu');

  SrcPopupMenu := TPopupMenu.Create(Self);
  with SrcPopupMenu do
  begin
    AutoPopup := True;
    OnPopup :=@SrcPopupMenuPopup;
    Images := IDEImages.Images_16;
  end;

  // assign the root TMenuItem to the registered menu root.
  // This will automatically create all registered items
  {$IFDEF VerboseMenuIntf}
  SrcPopupMenu.Items.WriteDebugReport('TSourceNotebook.BuildPopupMenu ');
  SourceEditorMenuRoot.ConsistencyCheck;
  {$ENDIF}
end;

procedure TSourceNotebook.AssignPopupMenu;
var
  i: Integer;
begin
  SrcEditMenuFindDeclaration.OnClick:=@FindDeclarationClicked;
  SrcEditMenuProcedureJump.OnClick:=@ProcedureJumpClicked;
  SrcEditMenuFindNextWordOccurrence.OnClick:=@FindNextWordOccurrenceClicked;
  SrcEditMenuFindPrevWordOccurrence.OnClick:=@FindPrevWordOccurrenceClicked;
  SrcEditMenuFindinFiles.OnClick:=@FindInFilesClicked;
  SrcEditMenuOpenFileAtCursor.OnClick:=@OpenAtCursorClicked;

  SrcEditMenuClosePage.OnClick:=@CloseClicked;
  SrcEditMenuCloseOtherPages.OnClick:=@CloseOtherPagesClicked;
  SrcEditMenuCut.OnClick:=@CutClicked;
  SrcEditMenuCopy.OnClick:=@CopyClicked;
  SrcEditMenuPaste.OnClick:=@PasteClicked;
  SrcEditMenuCopyFilename.OnClick:=@CopyFilenameClicked;
  for i:=0 to 9 do begin
    SrcEditSubMenuGotoBookmarks.FindByName('GotoBookmark'+IntToStr(i))
                                           .OnClick:=@Manager.BookmarkGotoClicked;
    SrcEditSubMenuToggleBookmarks.FindByName('ToggleBookmark'+IntToStr(i))
                                            .OnClick:=@Manager.BookMarkToggleClicked;
  end;
  SrcEditMenuSetFreeBookmark.OnClick:=@Manager.BookMarkSetFreeClicked;
  SrcEditMenuNextBookmark.OnClick:=@Manager.BookMarkNextClicked;
  SrcEditMenuPrevBookmark.OnClick:=@Manager.BookMarkPrevClicked;

  SrcEditMenuToggleBreakpoint.OnClick:=@ToggleBreakpointClicked;
  SrcEditMenuRunToCursor.OnClick:=@RunToClicked;
  SrcEditMenuViewCallStack.OnClick:=@ViewCallStackClick;

  SrcEditMenuMoveEditorLeft.OnClick:=@MoveEditorLeftClicked;
  SrcEditMenuMoveEditorRight.OnClick:=@MoveEditorRightClicked;
  SrcEditMenuMoveEditorFirst.OnClick:=@MoveEditorFirstClicked;
  SrcEditMenuMoveEditorLast.OnClick:=@MoveEditorLastClicked;
  SrcEditMenuMoveEditorLast.OnClick:=@MoveEditorLastClicked;
  SrcEditMenuDocking.OnClick:=@DockingClicked;

  SrcEditMenuInsertTodo.OnClick:=@InsertTodoClicked;

  SrcEditMenuCompleteCode.OnClick:=@CompleteCodeMenuItemClick;
  SrcEditMenuEncloseSelection.OnClick:=@EncloseSelectionMenuItemClick;
  SrcEditMenuExtractProc.OnClick:=@ExtractProcMenuItemClick;
  SrcEditMenuInvertAssignment.OnClick:=@InvertAssignmentMenuItemClick;
  SrcEditMenuFindIdentifierReferences.OnClick:=
                                         @FindIdentifierReferencesMenuItemClick;
  SrcEditMenuRenameIdentifier.OnClick:=@RenameIdentifierMenuItemClick;
  SrcEditMenuShowAbstractMethods.OnClick:=@ShowAbstractMethodsMenuItemClick;
  SrcEditMenuShowEmptyMethods.OnClick:=@ShowEmptyMethodsMenuItemClick;
  SrcEditMenuShowUnusedUnits.OnClick:=@ShowUnusedUnitsMenuItemClick;
  SrcEditMenuFindOverloads.OnClick:=@FindOverloadsMenuItemClick;

  SrcEditMenuReadOnly.OnClick:=@ReadOnlyClicked;
  SrcEditMenuShowLineNumbers.OnClick:=@ToggleLineNumbersClicked;
  SrcEditMenuShowUnitInfo.OnClick:=@ShowUnitInfo;
  SrcEditMenuEditorProperties.OnClick:=@EditorPropertiesClicked;

  {$IFnDEF SingleSrcWindow}
  SrcEditMenuMoveToNewWindow.OnClick := @SrcEditMenuMoveToNewWindowClicked;
  SrcEditMenuMoveToOtherWindowNew.OnClick := @SrcEditMenuMoveToNewWindowClicked;

  SrcEditMenuCopyToNewWindow.OnClick := @SrcEditMenuCopyToNewWindowClicked;
  SrcEditMenuCopyToOtherWindowNew.OnClick := @SrcEditMenuCopyToNewWindowClicked;
  {$ENDIF}
end;

function TSourceNotebook.GetNoteBookPage(Index: Integer): TPage;
begin
  if FNotebook.Visible then
    Result := FNotebook.Page[Index]
  else
    Result := nil;
end;

function TSourceNotebook.GetNotebookPages: TStrings;
begin
  if FNotebook.Visible then
    Result := FNotebook.Pages
  else
    Result := nil;
end;

function TSourceNotebook.GetPageCount: Integer;
begin
  If FNotebook.Visible then
    Result := FNotebook.PageCount
  else
    Result := 0;
end;

function TSourceNotebook.GetPageIndex: Integer;
begin
  if FUpdateLock > 0 then
    Result := FPageIndex
  else
  if FNotebook.Visible then
    Result := FNotebook.PageIndex
  else
    Result := -1
end;

procedure TSourceNotebook.SetPageIndex(const AValue: Integer); {$hint set a breakpoint here => this gets called a zillion times // from EditorEnter / Activate}
begin
  FPageIndex := AValue;
  if FUpdateLock = 0 then begin
    FPageIndex := Max(0, Min(FPageIndex, FNotebook.PageCount-1));
    FNotebook.PageIndex := FPageIndex;
  end;
end;

function TSourceNotebook.GetCompletionBoxPosition: integer;
begin
  Result := Manager.CompletionBoxPosition;
end;

procedure TSourceNotebook.UpdateHighlightMenuItems;
var
  h: TLazSyntaxHighlighter;
  i: Integer;
  CurName: String;
  CurCaption: String;
  IDEMenuItem: TIDEMenuItem;
  SrcEdit: TSourceEditor;
begin
  SrcEditSubMenuHighlighter.ChildsAsSubMenu:=true;
  SrcEdit:=GetActiveSE;
  i:=0;
  for h:=Low(TLazSyntaxHighlighter) to High(TLazSyntaxHighlighter) do begin
    CurName:='Highlighter'+IntToStr(i);
    CurCaption:=LazSyntaxHighlighterNames[h];
    if SrcEditSubMenuHighlighter.Count=i then begin
      // add new item
      IDEMenuItem:=RegisterIDEMenuCommand(SrcEditSubMenuHighlighter,
                             CurName,CurCaption,@HighlighterClicked);
    end else begin
      IDEMenuItem:=SrcEditSubMenuHighlighter[i];
      IDEMenuItem.Caption:=CurCaption;
      IDEMenuItem.OnClick:=@HighlighterClicked;
    end;
    if IDEMenuItem is TIDEMenuCommand then
      TIDEMenuCommand(IDEMenuItem).Checked:=(SrcEdit<>nil)
                                          and (SrcEdit.SyntaxHighlighterType=h);
    inc(i);
  end;
end;

procedure TSourceNotebook.UpdateLineEndingMenuItems;
var
  List: TStringList;
  i: Integer;
  SrcEdit: TSourceEditor;
  DiskLineEnding: String;
  CurLineEnding: string;
  CurName: String;
  CurCaption: String;
  IDEMenuItem: TIDEMenuItem;
begin
  SrcEditSubMenuLineEnding.ChildsAsSubMenu:=true;
  SrcEdit:=GetActiveSE;
  DiskLineEnding:=LineEnding;
  if (SrcEdit<>nil) and (SrcEdit.CodeBuffer<>nil) then
    DiskLineEnding:=SrcEdit.CodeBuffer.DiskLineEnding;
  DiskLineEnding:=StringReplace(StringReplace(DiskLineEnding,#13,'CR',[rfReplaceAll]),#10,'LF',[rfReplaceAll]);
  //DebugLn(['TSourceNotebook.UpdateEncodingMenuItems ',Encoding]);
  List:=TStringList.Create;
  List.add('LF');
  List.add('CR');
  List.add('CRLF');
  for i:=0 to List.Count-1 do begin
    CurName:='LineEnding'+IntToStr(i);
    CurLineEnding:=List[i];
    // warning! captions are later used as replacment for actuall LineEndings.
    // This is note good practice to mix data and user interface.
    CurCaption:=CurLineEnding;
    if SrcEditSubMenuLineEnding.Count=i then begin
      // add new item
      IDEMenuItem:=RegisterIDEMenuCommand(SrcEditSubMenuLineEnding,
                             CurName,CurCaption,@LineEndingClicked);
    end else begin
      IDEMenuItem:=SrcEditSubMenuLineEnding[i];
      IDEMenuItem.Caption:=CurCaption;
      IDEMenuItem.OnClick:=@LineEndingClicked;
    end;
    if IDEMenuItem is TIDEMenuCommand then
      TIDEMenuCommand(IDEMenuItem).Checked:=
        DiskLineEnding=CurLineEnding;
  end;
  List.Free;
end;

procedure TSourceNotebook.UpdatePageNames;
var
  i: Integer;
begin
  for i:=0 to PageCount-1 do
    FindSourceEditorWithPageIndex(i).UpdatePageName;
end;

procedure TSourceNotebook.UpdateProjectFiles;
var
  i: Integer;
begin
  for i := 0 to EditorCount - 1 do
    Editors[i].UpdateProjectFile;
end;

procedure TSourceNotebook.UpdateEncodingMenuItems;
var
  List: TStringList;
  i: Integer;
  SrcEdit: TSourceEditor;
  Encoding: String;
  CurEncoding: string;
  CurName: String;
  CurCaption: String;
  IDEMenuItem: TIDEMenuItem;
  SysEncoding: String;
begin
  SrcEditSubMenuEncoding.ChildsAsSubMenu:=true;
  SrcEdit:=GetActiveSE;
  Encoding:='';
  if SrcEdit<>nil then begin
    if SrcEdit.CodeBuffer<>nil then
      Encoding:=NormalizeEncoding(SrcEdit.CodeBuffer.DiskEncoding);
  end;
  if Encoding='' then
    Encoding:=GetDefaultTextEncoding;
  //DebugLn(['TSourceNotebook.UpdateEncodingMenuItems ',Encoding]);
  List:=TStringList.Create;
  GetSupportedEncodings(List);
  for i:=0 to List.Count-1 do begin
    CurName:='Encoding'+IntToStr(i);
    CurEncoding:=List[i];
    CurCaption:=CurEncoding;
    if SysUtils.CompareText(CurEncoding,EncodingAnsi)=0 then begin
      SysEncoding:=GetDefaultTextEncoding;
      if (SysEncoding<>'') and (SysUtils.CompareText(SysEncoding,EncodingAnsi)<>0)
      then
        CurCaption:=CurCaption+' ('+GetDefaultTextEncoding+')';
    end;
    if CurEncoding='UTF-8BOM' then begin
      CurCaption:=lisUtf8WithBOM;
    end;
    if SrcEditSubMenuEncoding.Count=i then begin
      // add new item
      IDEMenuItem:=RegisterIDEMenuCommand(SrcEditSubMenuEncoding,
                             CurName,CurCaption,@EncodingClicked);
    end else begin
      IDEMenuItem:=SrcEditSubMenuEncoding[i];
      IDEMenuItem.Caption:=CurCaption;
      IDEMenuItem.OnClick:=@EncodingClicked;
    end;
    if IDEMenuItem is TIDEMenuCommand then
      TIDEMenuCommand(IDEMenuItem).Checked:=
        Encoding=NormalizeEncoding(CurEncoding);
  end;
  List.Free;
end;

procedure TSourceNotebook.RemoveUserDefinedMenuItems;
begin
  SrcEditMenuSectionFirstDynamic.Clear;
end;

function TSourceNotebook.AddUserDefinedPopupMenuItem(const NewCaption: string;
  const NewEnabled: boolean; const NewOnClick: TNotifyEvent): TIDEMenuItem;
begin
  Result:=RegisterIDEMenuCommand(SrcEditMenuSectionFirstDynamic.GetPath,
    'Dynamic',NewCaption,NewOnClick);
  Result.Enabled:=NewEnabled;
end;

procedure TSourceNotebook.RemoveContextMenuItems;
begin
  SrcEditMenuSectionFileDynamic.Clear;
  {$IFDEF VerboseMenuIntf}
  SrcEditMenuSectionFileDynamic.WriteDebugReport('TSourceNotebook.RemoveContextMenuItems ');
  {$ENDIF}
end;

function TSourceNotebook.AddContextPopupMenuItem(const NewCaption: string;
  const NewEnabled: boolean; const NewOnClick: TNotifyEvent): TIDEMenuItem;
begin
  Result:=RegisterIDEMenuCommand(SrcEditMenuSectionFileDynamic.GetPath,
                                 'FileDynamic',NewCaption,NewOnClick);
  Result.Enabled:=NewEnabled;
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
  SenderDeleted:=(Sender as TControl).Parent=nil;
  if SenderDeleted then exit;
  UpdateStatusBar;
  if assigned(Manager) and Assigned(Manager.OnEditorChanged) then
    Manager.OnEditorChanged(Sender);
End;

procedure TSourceNotebook.DoClose(var CloseAction: TCloseAction);
begin
  inherited DoClose(CloseAction);
  CloseAction := caHide;
  {$IFnDEF SingleSrcWindow}
  if PageCount = 0 then begin { $NOTE maybe keep the last one}
    if EnvironmentOptions.IDEWindowLayoutList.ItemByFormID(Self.Name) <> nil then
      EnvironmentOptions.IDEWindowLayoutList.ItemByFormID(Self.Name).CloseForm;
    // Make the name unique, because it may not immediately be released
    Name := Name + '___' + IntToStr(PtrUInt(Pointer(Self)));
    CloseAction := caFree;
  end
  else begin
    FIsClosing := True;
    try
      if Assigned(Manager) and Assigned(Manager.OnNoteBookCloseQuery) then
        Manager.OnNoteBookCloseQuery(Self, CloseAction);
    finally
      FIsClosing := False;
    end;
  end;
  {$ENDIF}
end;

function TSourceNotebook.IndexOfEditorInShareWith(AnOtherEditor: TSourceEditor
  ): Integer;
var
  i: Integer;
begin
  for i := 0 to EditorCount - 1 do
    if Editors[i].IsSharedWith(AnOtherEditor) then
      exit(i);
  Result := -1;
end;

function TSourceNotebook.GetActiveCompletionPlugin: TSourceEditorCompletionPlugin;
begin
  Result := Manager.ActiveCompletionPlugin;
end;

function TSourceNotebook.CompletionPluginCount: integer;
begin
  Result := SourceEditorManager.CompletionPluginCount;
end;

procedure TSourceNotebook.RegisterCompletionPlugin(
  Plugin: TSourceEditorCompletionPlugin);
begin
  // Deprecated; forward to manager
  SourceEditorManager.RegisterCompletionPlugin(Plugin);
end;

procedure TSourceNotebook.UnregisterCompletionPlugin(
  Plugin: TSourceEditorCompletionPlugin);
begin
  // Deprecated; forward to manager
  SourceEditorManager.UnregisterCompletionPlugin(Plugin);
end;

function TSourceNotebook.GetCompletionPlugins(Index: integer
  ): TSourceEditorCompletionPlugin;
begin
  Result := SourceEditorManager.CompletionPlugins[Index];
end;

function TSourceNotebook.NewSE(PageNum: Integer; NewPageNum: Integer = -1; ASharedEditor: TSourceEditor = nil): TSourceEditor;
begin
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.NewSE A ');
  {$ENDIF}
  if Pagenum < 0 then begin
    // add a new page right to the current
    if NewPageNum >= 0 then
      PageNum := NewPageNum
    else
      Pagenum := PageIndex+1;
    Pagenum := Max(0,Min(PageNum, PageCount));
    NoteBookInsertPage(PageNum, Manager.FindUniquePageName('', nil));
    NotebookPage[PageNum].ReAlign;
  end;
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.NewSE B  ', PageIndex,',',PagesCount);
  {$ENDIF}
  Result := TSourceEditor.Create(Self, NotebookPage[PageNum], ASharedEditor);
  Result.FPageName := NoteBookPages[Pagenum];
  AcceptEditor(Result);
  PageIndex := Pagenum;
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.NewSE end ');
  {$ENDIF}
end;

procedure TSourceNotebook.AcceptEditor(AnEditor: TSourceEditor);
begin
  FSourceEditorList.Add(AnEditor);

  AnEditor.EditorComponent.BeginUpdate;
  AnEditor.PopupMenu := SrcPopupMenu;
  AnEditor.OnEditorChange := @EditorChanged;
  AnEditor.OnMouseMove := @EditorMouseMove;
  AnEditor.OnMouseDown := @EditorMouseDown;
  AnEditor.OnMouseWheel := @EditorMouseWheel;
  AnEditor.OnKeyDown := @EditorKeyDown;
  AnEditor.EditorComponent.Beautifier.OnGetDesiredIndent := @EditorGetIndent;
  AnEditor.EditorComponent.EndUpdate;
end;

procedure TSourceNotebook.ReleaseEditor(AnEditor: TSourceEditor);
begin
  FSourceEditorList.Remove(AnEditor);
end;

function TSourceNotebook.FindSourceEditorWithPageIndex(
  APageIndex: integer): TSourceEditor;
var I: integer;
  TempEditor: TControl;
begin
  Result := nil;
  if (FSourceEditorList=nil)
    or (APageIndex < 0) or (APageIndex >= PageCount) then exit;
  TempEditor:=nil;
  with NotebookPage[APageIndex] do
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
  if (FSourceEditorList=nil) or (FSourceEditorList.Count=0) or (PageIndex<0) then
    exit;
  Result:=FindSourceEditorWithPageIndex(PageIndex);
end;

function TSourceNotebook.GetActiveEditor: TSourceEditorInterface;
begin
  Result:=GetActiveSE;
end;

procedure TSourceNotebook.SetActiveEditor(const AValue: TSourceEditorInterface
  );
var
  i: integer;
begin
  i := FindPageWithEditor(AValue as TSourceEditor);
  inc(FFocusLock);
  if  i>= 0 then
    PageIndex := i;
  dec(FFocusLock);
  SourceEditorManager.ActiveSourceWindow := self;
end;

procedure TSourceNotebook.CheckCurrentCodeBufferChanged;
var
  SrcEdit: TSourceEditor;
begin
  // Todo: Move to manager, include window changes
  SrcEdit:=GetActiveSE;
  if SrcEdit = nil then Exit;
  if FLastCodeBuffer=SrcEdit.CodeBuffer then exit;
  FLastCodeBuffer:=SrcEdit.CodeBuffer;
  if assigned(Manager) and Assigned(Manager.OnCurrentCodeBufferChanged) then
    Manager.OnCurrentCodeBufferChanged(Self);
end;

function TSourceNotebook.GetCapabilities: TNoteBookCapabilities;
begin
  Result := FNotebook.GetCapabilities
end;

procedure TSourceNotebook.IncUpdateLock;
begin
  inc(FUpdateLock);
end;

procedure TSourceNotebook.DecUpdateLock;
begin
  dec(FUpdateLock);
  if FUpdateLock = 0 then
    PageIndex := FPageIndex;
end;

procedure TSourceNotebook.NoteBookInsertPage(Index: Integer; const S: string);
begin
  if FNotebook.Visible then
    NotebookPages.Insert(Index, S)
  else begin
    Show;
    FNotebook.Visible := True;
    NotebookPages[Index] := S;
  end;
end;

procedure TSourceNotebook.NoteBookDeletePage(Index: Integer);
begin
  if PageCount > 1 then begin
    if Index < PageCount - 1 then
      FNoteBook.PageIndex := Index + 1
    else
      FNoteBook.PageIndex := Index - 1;
    NotebookPages.Delete(Index);
  end else
    FNotebook.Visible := False;
end;

function TSourceNotebook.NoteBookIndexOfPage(APage: TPage): Integer;
begin
  Result := FNoteBook.IndexOf(APage);
end;

procedure TSourceNotebook.BeginIncrementalFind;
var
  TempEditor: TSourceEditor;
begin
  if (snIncrementalFind in States)AND not(FIncrementalSearchEditor = nil)
  then begin
    if (IncrementalSearchStr=  '') then begin
      FIncrementalSearchStr := FIncrementalFoundStr;
      IncrementalSearch(False, FIncrementalSearchBackwards);
    end
    else IncrementalSearch(True, FIncrementalSearchBackwards);
    exit;
  end;

  TempEditor:=GetActiveSE;
  if TempEditor = nil then exit;
  Include(States, snIncrementalFind);
  fIncrementalSearchStartPos:=TempEditor.EditorComponent.LogicalCaretXY;
  FIncrementalSearchPos:=fIncrementalSearchStartPos;
  FIncrementalSearchEditor := TempEditor;
  if assigned(FIncrementalSearchEditor.EditorComponent) then
    with FIncrementalSearchEditor.EditorComponent do begin
      UseIncrementalColor:= true;
      if assigned(MarkupByClass[TSynEditMarkupHighlightAllCaret]) then
        MarkupByClass[TSynEditMarkupHighlightAllCaret].TempDisable;
    end;

  IncrementalSearchStr:='';

  UpdateStatusBar;
end;

procedure TSourceNotebook.EndIncrementalFind;
begin
  if not (snIncrementalFind in States) then exit;

  Exclude(States,snIncrementalFind);

  if FIncrementalSearchEditor <> nil
  then begin
    if assigned(FIncrementalSearchEditor.EditorComponent) then
      with FIncrementalSearchEditor.EditorComponent do begin
        UseIncrementalColor:= False;
        if assigned(MarkupByClass[TSynEditMarkupHighlightAllCaret]) then
          MarkupByClass[TSynEditMarkupHighlightAllCaret].TempEnable;
      end;
    FIncrementalSearchEditor.EditorComponent.SetHighlightSearch('', []);
    FIncrementalSearchEditor := nil;
  end;

  LazFindReplaceDialog.FindText:=fIncrementalSearchStr;
  LazFindReplaceDialog.Options:=[];
  UpdateStatusBar;
end;

Procedure TSourceNotebook.NextEditor;
Begin
  if PageIndex < PageCount-1 then
    PageIndex := PageIndex+1
  else
    PageIndex := 0;
  NotebookPageChanged(Self);
End;

Procedure TSourceNotebook.PrevEditor;
Begin
  if PageIndex > 0 then
    PageIndex := PageIndex-1
  else
    PageIndex := PageCount-1;
  NotebookPageChanged(Self);
End;

procedure TSourceNotebook.MoveEditor(OldPageIndex, NewPageIndex: integer);
begin
  if (PageCount<=1)
  or (OldPageIndex=NewPageIndex)
  or (OldPageIndex<0) or (OldPageIndex>=PageCount)
  or (NewPageIndex<0) or (NewPageIndex>=PageCount)
  then
    exit;
  NoteBookPages.Move(OldPageIndex,NewPageIndex);
  UpdatePageNames;
  UpdateProjectFiles;
end;

procedure TSourceNotebook.MoveEditorLeft(CurrentPageIndex: integer);
begin
  if (PageCount<=1) then exit;
  if CurrentPageIndex>0 then
    MoveEditor(CurrentPageIndex, CurrentPageIndex-1)
  else
    MoveEditor(CurrentPageIndex, PageCount-1);
end;

procedure TSourceNotebook.MoveEditorRight(CurrentPageIndex: integer);
begin
  if (PageCount<=1) then exit;
  if CurrentPageIndex < PageCount-1 then
    MoveEditor(CurrentPageIndex, CurrentPageIndex+1)
  else
    MoveEditor(CurrentPageIndex, 0);
end;

procedure TSourceNotebook.MoveEditorFirst(CurrentPageIndex: integer);
begin
  if (PageCount<=1) then exit;
  MoveEditor(CurrentPageIndex, 0)
end;

procedure TSourceNotebook.MoveEditorLast(CurrentPageIndex: integer);
begin
  if (PageCount<=1) then exit;
  MoveEditor(CurrentPageIndex, PageCount-1);
end;

procedure TSourceNotebook.MoveActivePageLeft;
begin
  MoveEditorLeft(PageIndex);
end;

procedure TSourceNotebook.MoveActivePageRight;
begin
  MoveEditorRight(PageIndex);
end;

procedure TSourceNotebook.MoveActivePageFirst;
begin
  MoveEditorFirst(PageIndex);
end;

procedure TSourceNotebook.MoveActivePageLast;
begin
  MoveEditorLast(PageIndex);
end;

procedure TSourceNotebook.GotoNextWindow(Backward: Boolean);
begin
  if Backward then begin
    if Manager.IndexOfSourceWindow(Self) > 0 then
      Manager.ActiveSourceWindow := Manager.SourceWindows[Manager.IndexOfSourceWindow(Self)-1]
    else
      Manager.ActiveSourceWindow := Manager.SourceWindows[Manager.SourceWindowCount-1];
  end else begin
    if Manager.IndexOfSourceWindow(Self) < Manager.SourceWindowCount - 1 then
      Manager.ActiveSourceWindow := Manager.SourceWindows[Manager.IndexOfSourceWindow(Self)+1]
    else
      Manager.ActiveSourceWindow := Manager.SourceWindows[0];
  end;
  Manager.ShowActiveWindowOnTop(True);
end;

procedure TSourceNotebook.GotoNextSharedEditor(Backward: Boolean = False);
var
  SrcEd: TSourceEditor;
  i, j: Integer;
begin
  i := Manager.IndexOfSourceWindow(Self);
  SrcEd := GetActiveSE;
  repeat
    if Backward then dec(i)
    else inc(i);
    if i < 0 then
      i := Manager.SourceWindowCount - 1;
    if i = Manager.SourceWindowCount then
      i := 0;
    j := Manager.SourceWindows[i].IndexOfEditorInShareWith(SrcEd);
    if j >= 0 then begin
      Manager.ActiveEditor := Manager.SourceWindows[i].Editors[j];
      Manager.ShowActiveWindowOnTop(True);
      exit;
    end;
  until Manager.SourceWindows[i] = Self;
end;

procedure TSourceNotebook.MoveEditorNextWindow(Backward: Boolean; Copy: Boolean);
var
  SrcEd: TSourceEditor;
  i: Integer;
begin
  i := Manager.IndexOfSourceWindow(Self);
  SrcEd := GetActiveSE;
  repeat
    if Backward then dec(i)
    else inc(i);
    if i < 0 then
      i := Manager.SourceWindowCount - 1;
    if i = Manager.SourceWindowCount then
      i := 0;
    if Manager.SourceWindows[i].IndexOfEditorInShareWith(SrcEd) < 0 then
      break;
  until Manager.SourceWindows[i] = Self;
  if Manager.SourceWindows[i] = Self then exit;

  if Copy then
    CopyEditor(FindPageWithEditor(GetActiveSE), i, -1)
  else
    MoveEditor(FindPageWithEditor(GetActiveSE), i, -1);

  Manager.ActiveSourceWindowIndex := i;
  Manager.ShowActiveWindowOnTop(True);
end;

procedure TSourceNotebook.MoveEditor(OldPageIndex, NewWindowIndex,
  NewPageIndex: integer);
var
  DestWin: TSourceNotebook;
  Edit: TSourceEditor;
begin
  if (NewWindowIndex < 0) or (NewWindowIndex >= Manager.SourceWindowCount) then
    exit;
  DestWin := Manager.SourceWindows[NewWindowIndex];
  if DestWin = self then begin
    MoveEditor(OldPageIndex, NewPageIndex);
    exit
  end;

  if NewPageIndex < 0 then
    NewPageIndex := DestWin.PageCount;
  if (OldPageIndex<0) or (OldPageIndex>=PageCount) or
     (NewPageIndex<0) or (NewPageIndex>DestWin.PageCount)
  then
    exit;

  Edit := FindSourceEditorWithPageIndex(OldPageIndex);
  DestWin.NoteBookInsertPage(NewPageIndex, Edit.PageName);
  DestWin.PageIndex := NewPageIndex;

  ReleaseEditor(Edit);
  Edit.UpdateNoteBook(DestWin, DestWin.NoteBookPage[NewPageIndex]);
  DestWin.AcceptEditor(Edit);
  {$IfNDef OldAutoSize}
  DestWin.NotebookPage[NewPageIndex].ReAlign;
  {$EndIf}

  NoteBookDeletePage(OldPageIndex);
  UpdatePageNames;
  UpdateProjectFiles;
  DestWin.UpdatePageNames;
  DestWin.UpdateProjectFiles;
  DestWin.UpdateActiveEditColors(Edit.EditorComponent);
  DestWin.UpdateStatusBar;

  if (PageCount = 0) and not FIsClosing then
    Close;
end;

procedure TSourceNotebook.CopyEditor(OldPageIndex, NewWindowIndex,
  NewPageIndex: integer);
var
  DestWin: TSourceNotebook;
  SrcEdit, NewEdit: TSourceEditor;
begin
  if (NewWindowIndex < 0) or (NewWindowIndex >= Manager.SourceWindowCount) then
    exit;
  DestWin := Manager.SourceWindows[NewWindowIndex];
  if DestWin = self then exit;

  if (OldPageIndex<0) or (OldPageIndex>=PageCount) or
     (NewPageIndex>DestWin.PageCount)
  then
    exit;

  SrcEdit := FindSourceEditorWithPageIndex(OldPageIndex);
  NewEdit := DestWin.NewSE(-1, NewPageIndex, SrcEdit);
  NewEdit.IsNewSharedEditor := True;

  NewEdit.PageName := SrcEdit.PageName;
  NewEdit.SyntaxHighlighterType := SrcEdit.SyntaxHighlighterType;
  NewEdit.EditorComponent.TopLine := SrcEdit.EditorComponent.TopLine;
  NewEdit.EditorComponent.CaretXY := SrcEdit.EditorComponent.CaretXY;

  UpdatePageNames;
  UpdateProjectFiles;
  DestWin.UpdateProjectFiles;
  // Update IsVisibleTab; needs UnitEditorInfo created in DestWin.UpdateProjectFiles
  if Assigned(Manager.OnEditorVisibleChanged) then
    Manager.OnEditorVisibleChanged(Self);
end;

procedure TSourceNotebook.ActivateHint(const ScreenPos: TPoint;
  const BaseURL, TheHint: string);
var
  HintWinRect: TRect;
  AHint: String;
begin
  if csDestroying in ComponentState then exit;
  if FHintWindow<>nil then
    FHintWindow.Visible:=false;
  if FHintWindow=nil then
    FHintWindow:=THintWindow.Create(Self);
  AHint:=TheHint;
  if LazarusHelp.CreateHint(FHintWindow,ScreenPos,BaseURL,AHint,HintWinRect) then
    FHintWindow.ActivateHint(HintWinRect,aHint);
end;

procedure TSourceNotebook.HideHint;
begin
  //DebugLn(['TSourceNotebook.HideHint ']);
  if FMouseHintTimer<>nil then
  begin
    FMouseHintTimer.AutoEnabled := false;
    FMouseHintTimer.Enabled:=false;
  end;
  if SourceCompletionTimer<>nil then
    SourceCompletionTimer.Enabled:=false;
  if FHintWindow<>nil then
    FHintWindow.Visible:=false;
end;

procedure TSourceNotebook.StartShowCodeContext(JumpToError: boolean);
var
  Abort: boolean;
begin
  if assigned(Manager) and (Manager.OnShowCodeContext<>nil) then begin
    Manager.OnShowCodeContext(JumpToError,Abort);
    if Abort then ;
  end;
end;

Procedure TSourceNotebook.ReadOnlyClicked(Sender: TObject);
var ActEdit: TSourceEditor;
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
  if assigned(Manager) and Assigned(Manager.OnReadOnlyChanged) then
    Manager.OnReadOnlyChanged(Self);
  UpdateStatusBar;
end;

procedure TSourceNotebook.OnPopupMenuOpenPasFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.pas'),
    PageIndex+1, Manager.IndexOfSourceWindow(self),
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

procedure TSourceNotebook.OnPopupMenuOpenPPFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.pp'),
    PageIndex+1, Manager.IndexOfSourceWindow(self),
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

procedure TSourceNotebook.OnPopupMenuOpenPFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.p'),
    PageIndex+1, Manager.IndexOfSourceWindow(self),
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

procedure TSourceNotebook.OnPopupMenuOpenLFMFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.lfm'),
    PageIndex+1, Manager.IndexOfSourceWindow(self),
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

procedure TSourceNotebook.OnPopupMenuOpenLRSFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.lrs'),
    PageIndex+1, Manager.IndexOfSourceWindow(self),
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

procedure TSourceNotebook.OnPopupMenuOpenSFile(Sender: TObject);
begin
  MainIDEInterface.DoOpenEditorFile(ChangeFileExt(GetActiveSE.Filename,'.s'),
    PageIndex+1, Manager.IndexOfSourceWindow(self),
    [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofUseCache,ofDoNotLoadResource]);
end;

procedure TSourceNotebook.OnPopupMenuOpenFile(Sender: TObject);
var
  AFilename: String;
begin
  AFilename:=GetActiveSE.Filename;
  if CompareFileExt(AFilename,'.lpi')=0 then
    MainIDEInterface.DoOpenProjectFile(AFilename,
      [ofOnlyIfExists,ofAddToRecent,ofUseCache])
  else if CompareFileExt(AFilename,'.lpk')=0 then
    PackageEditingInterface.DoOpenPackageFile(AFilename,[pofAddToRecent],false);
end;

Procedure TSourceNotebook.ShowUnitInfo(Sender: TObject);
begin
  if assigned(Manager) and Assigned(Manager.OnShowUnitInfo) then
    Manager.OnShowUnitInfo(Sender);
end;

Procedure TSourceNotebook.ToggleLineNumbersClicked(Sender: TObject);
var
  MenuITem: TIDEMenuCommand;
  ActEdit:TSourceEditor;
  i: integer;
  ShowLineNumbers: boolean;
begin
  MenuItem := Sender as TIDEMenuCommand;
  ActEdit:=GetActiveSE;
  MenuItem.Checked :=
    not ActEdit.EditorComponent.Gutter.LineNumberPart.Visible;
  ShowLineNumbers:=MenuItem.Checked;
  for i:=0 to EditorCount-1 do
    Editors[i].EditorComponent.Gutter.LineNumberPart.Visible
      := ShowLineNumbers;
  EditorOpts.ShowLineNumbers := ShowLineNumbers;
  EditorOpts.Save;
end;

Procedure TSourceNotebook.OpenAtCursorClicked(Sender: TObject);
begin
  if assigned(Manager) and Assigned(Manager.OnOpenFileAtCursorClicked) then
    Manager.OnOpenFileAtCursorClicked(Sender);
end;

Procedure TSourceNotebook.FindDeclarationClicked(Sender: TObject);
begin
  if assigned(Manager) and Assigned(Manager.OnFindDeclarationClicked) then
    Manager.OnFindDeclarationClicked(Sender);
end;

procedure TSourceNotebook.ProcedureJumpClicked(Sender: TObject);
var ActSE: TSourceEditor;
begin
  ActSE := GetActiveSE;
  if ActSE <> nil then
    ActSE.DoEditorExecuteCommand(ecFindProcedureDefinition);
end;

procedure TSourceNotebook.FindNextWordOccurrenceClicked(Sender: TObject);
var
  SrcEdit: TSourceEditor;
begin
  SrcEdit := GetActiveSE;
  if SrcEdit<>nil then
    SrcEdit.FindNextWordOccurrence(true);
end;

procedure TSourceNotebook.FindPrevWordOccurrenceClicked(Sender: TObject);
var
  SrcEdit: TSourceEditor;
begin
  SrcEdit := GetActiveSE;
  if SrcEdit<>nil then
    SrcEdit.FindNextWordOccurrence(false);
end;

procedure TSourceNotebook.FindInFilesClicked(Sender: TObject);
var
  SrcEdit: TSourceEditor;
begin
  SrcEdit := GetActiveSE;
  if SrcEdit<>nil then
    SrcEdit.DoEditorExecuteCommand(ecFindInFiles);
end;

procedure TSourceNotebook.InsertTodoClicked(Sender: TObject);
begin
  if assigned(Manager) and Assigned(Manager.OnInsertTodoClicked) then
    Manager.OnInsertTodoClicked(Sender);
end;

Procedure TSourceNotebook.CutClicked(Sender: TObject);
var ActSE: TSourceEditor;
begin
  ActSE := GetActiveSE;
  if ActSE <> nil then
    ActSE.DoEditorExecuteCommand(ecCut);
end;

Procedure TSourceNotebook.CopyClicked(Sender: TObject);
var ActSE: TSourceEditor;
begin
  ActSE := GetActiveSE;
  if ActSE <> nil then
    ActSE.DoEditorExecuteCommand(ecCopy);
end;

Procedure TSourceNotebook.PasteClicked(Sender: TObject);
var ActSE: TSourceEditor;
begin
  ActSE := GetActiveSE;
  if ActSE <> nil then
    ActSE.DoEditorExecuteCommand(ecPaste);
end;

procedure TSourceNotebook.CopyFilenameClicked(Sender: TObject);
var ActSE: TSourceEditor;
begin
  ActSE := GetActiveSE;
  if ActSE <> nil then
    Clipboard.AsText:=ActSE.FileName;
end;

procedure TSourceNotebook.MoveEditorLeftClicked(Sender: TObject);
begin
  MoveActivePageLeft;
end;

procedure TSourceNotebook.MoveEditorRightClicked(Sender: TObject);
begin
  MoveActivePageRight;
end;

procedure TSourceNotebook.MoveEditorFirstClicked(Sender: TObject);
begin
  MoveActivePageFirst;
end;

procedure TSourceNotebook.MoveEditorLastClicked(Sender: TObject);
begin
  MoveActivePageLast;
end;

procedure TSourceNotebook.DockingClicked(Sender: TObject);
begin
  ControlDocker.ShowDockingEditor;
end;

procedure TSourceNotebook.StatusBarDblClick(Sender: TObject);
var
  P: TPoint;
begin
  P := StatusBar.ScreenToClient(Mouse.CursorPos);
  // if we clicked on first panel which shows position in code
  if assigned(Manager) and (StatusBar.GetPanelIndexAt(P.X, P.Y) = 0) then
  begin
    // then show goto line dialog
    Manager.GotoLineClicked(nil);
  end;
end;

procedure TSourceNotebook.ToggleBreakpointClicked(Sender: TObject);
var
  ASrcEdit: TSourceEditor;
  Line: LongInt;
  BreakPtMark: TSourceMark;
begin
  ASrcEdit:=GetActiveSE;
  if ASrcEdit=nil then exit;
  // create or delete breakpoint
  // find breakpoint mark at line
  Line:=ASrcEdit.EditorComponent.CaretY;
  BreakPtMark := SourceEditorMarks.FindBreakPointMark(ASrcEdit, Line);
  if BreakPtMark = nil then
    DebugBoss.DoCreateBreakPoint(ASrcEdit.Filename,Line,true)
  else
    DebugBoss.DoDeleteBreakPointAtMark(BreakPtMark);
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

procedure TSourceNotebook.ShowAbstractMethodsMenuItemClick(Sender: TObject);
begin
  MainIDEInterface.DoCommand(ecShowAbstractMethods);
end;

procedure TSourceNotebook.ShowEmptyMethodsMenuItemClick(Sender: TObject);
begin
  MainIDEInterface.DoCommand(ecRemoveEmptyMethods);
end;

procedure TSourceNotebook.ShowUnusedUnitsMenuItemClick(Sender: TObject);
begin
  MainIDEInterface.DoCommand(ecRemoveUnusedUnits);
end;

procedure TSourceNotebook.FindOverloadsMenuItemClick(Sender: TObject);
begin
  MainIDEInterface.DoCommand(ecFindOverloads);
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

function TSourceNotebook.NewFile(const NewShortName: String;
  ASource: TCodeBuffer; FocusIt: boolean; AShareEditor: TSourceEditor = nil): TSourceEditor;
Begin
  //create a new page
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.NewFile] A ');
  {$ENDIF}
  {$IFNDEF OldAutoSize}
  DisableAutoSizing{$IFDEF DebugDisableAutoSizing}('TSourceNotebook.NewFile'){$ENDIF};
  try
  {$ENDIF}
    Visible:=true;
    Result := NewSE(-1, -1, AShareEditor);
    {$IFDEF IDE_DEBUG}
    writeln('[TSourceNotebook.NewFile] B ');
    {$ENDIF}
    Result.CodeBuffer:=ASource;
    {$IFDEF IDE_DEBUG}
    writeln('[TSourceNotebook.NewFile] D ');
    {$ENDIF}
    Result.PageName:= Manager.FindUniquePageName(NewShortName, Result);
    UpdatePageNames;
    UpdateProjectFiles;
  {$IFNDEF OldAutoSize}
  finally
    EnableAutoSizing{$IFDEF DebugDisableAutoSizing}('TSourceNotebook.NewFile'){$ENDIF};
  end;
  {$ENDIF}
  if FocusIt then FocusEditor;
  {$IFDEF IDE_DEBUG}
  writeln('[TSourceNotebook.NewFile] end');
  {$ENDIF}
  CheckFont;
end;

procedure TSourceNotebook.CloseFile(APageIndex:integer);
var
  TempEditor: TSourceEditor;
begin
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.CloseFile A  APageIndex=',APageIndex);
  {$ENDIF}
  TempEditor:=FindSourceEditorWithPageIndex(APageIndex);
  if TempEditor=nil then exit;
  //debugln(['TSourceNotebook.CloseFile ',TempEditor.FileName,' ',TempEditor.APageIndex]);
  {$IFNDEF OldAutoSize}
  DisableAutoSizing{$IFDEF DebugDisableAutoSizing}('TSourceNotebook.CloseFile'){$ENDIF};
  try
  {$ENDIF}
    Visible:=true;
    EndIncrementalFind;
    TempEditor.Close;
    TempEditor.Free;
    TempEditor:=nil;
    //writeln('TSourceNotebook.CloseFile B  APageIndex=',APageIndex,' Notebook.APageIndex=',APageIndex);
    // make sure to select another page in the NoteBook, otherwise the
    // widgetset will choose one and will send a message
    // if this is the current page, switch to right APageIndex (if possible)
    if (PageCount > 1) and (PageIndex = APageIndex) then
        PageIndex := PageIndex + IfThen(PageIndex + 1 < PageCount, 1, -1);
    // delete the page
    //writeln('TSourceNotebook.CloseFile C  APageIndex=',APageIndex,' PageCount=',PageCount,' NoteBook.APageIndex=',Notebook.APageIndex);
    NoteBookDeletePage(APageIndex);
    //writeln('TSourceNotebook.CloseFile D  APageIndex=',APageIndex,' PageCount=',PageCount,' NoteBook.APageIndex=',Notebook.APageIndex);
    UpdateProjectFiles;
    UpdateStatusBar;
    UpdatePageNames;
    // set focus to new editor
    TempEditor:=FindSourceEditorWithPageIndex(PageIndex);
    if PageCount = 0 then begin
      {$IFnDEF SingleSrcWindow}
      Manager.RemoveWindow(self);
      FManager := nil;
      {$ENDIF}
      if not FIsClosing then
        Close;
    end;
  {$IFNDEF OldAutoSize}
  finally
    EnableAutoSizing{$IFDEF DebugDisableAutoSizing}('TSourceNotebook.CloseFile'){$ENDIF};
  end;
  {$ENDIF}
  if (TempEditor <> nil) then
    TempEditor.EditorComponent.SetFocus;
  {$IFDEF IDE_DEBUG}
  writeln('TSourceNotebook.CloseFile END');
  {$ENDIF}
end;

procedure TSourceNotebook.FocusEditor;
var
  SrcEdit: TSourceEditor;
begin
  if (fAutoFocusLock>0) then exit;
  SrcEdit:=GetActiveSE;
  if SrcEdit=nil then exit;
  Show;
  SrcEdit.FocusEditor;
end;

procedure TSourceNotebook.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Cursor:=crDefault;
end;

function TSourceNotebook.GetEditors(Index:integer):TSourceEditor;
begin
  Result:=TSourceEditor(FSourceEditorList[Index]);
end;

function TSourceNotebook.EditorCount:integer;
begin
  Result:=FSourceEditorList.Count;
end;

function TSourceNotebook.IndexOfEditor(aEditor: TSourceEditorInterface
  ): integer;
begin
  Result := FSourceEditorList.IndexOf(aEditor);
end;

function TSourceNotebook.Count: integer;
begin
  Result:=FSourceEditorList.Count;
end;

Procedure TSourceNotebook.CloseClicked(Sender: TObject);
Begin
  if assigned(Manager) and Assigned(Manager.OnCloseClicked) then
    Manager.OnCloseClicked(Sender, False);
end;

procedure TSourceNotebook.CloseOtherPagesClicked(Sender: TObject);
begin
  if assigned(Manager) and Assigned(Manager.OnCloseClicked) then
    Manager.OnCloseClicked(Sender, True);
end;

procedure TSourceNotebook.ToggleFormUnitClicked(Sender: TObject);
begin
  if assigned(Manager) and Assigned(Manager.OnToggleFormUnitClicked) then
    Manager.OnToggleFormUnitClicked(Sender);
end;

procedure TSourceNotebook.ToggleObjectInspClicked(Sender: TObject);
begin
  if assigned(Manager) and Assigned(Manager.OnToggleObjectInspClicked) then
    Manager.OnToggleObjectInspClicked(Sender);
end;

procedure TSourceNotebook.InsertCharacter(const C: TUTF8Char);
var
  FActiveEdit: TSourceEditor;
begin
  FActiveEdit := GetActiveSE;
  if FActiveEdit <> nil then
  begin
    if FActiveEdit.ReadOnly then Exit;
    FActiveEdit.EditorComponent.InsertTextAtCaret(C);
  end;
end;

procedure TSourceNotebook.SrcEditMenuCopyToNewWindowClicked(Sender: TObject);
begin
  inc(FFocusLock);
  try
    CopyEditor(PageIndex, Manager.IndexOfSourceWindow(Manager.CreateNewWindow(True)), -1);
    Manager.ShowActiveWindowOnTop(True);
  finally
    dec(FFocusLock);
  end;
end;

procedure TSourceNotebook.SrcEditMenuCopyToExistingWindowClicked(Sender: TObject);
begin
  inc(FFocusLock);
  try
    CopyEditor(PageIndex, (Sender as TIDEMenuItem).Tag, -1);
  finally
    dec(FFocusLock);
  end;
end;

procedure TSourceNotebook.SrcEditMenuMoveToNewWindowClicked(Sender: TObject);
begin
  inc(FFocusLock);
  try
    MoveEditor(PageIndex, Manager.IndexOfSourceWindow(Manager.CreateNewWindow(True)), -1);
    Manager.ShowActiveWindowOnTop(True);
  finally
    dec(FFocusLock);
  end;
end;

procedure TSourceNotebook.SrcEditMenuMoveToExistingWindowClicked(Sender: TObject);
begin
  MoveEditor(PageIndex, (Sender as TIDEMenuItem).Tag, -1)
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
        PanelFileMode := Format(lisUEReadOnly, [PanelFileMode])
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

  CheckCurrentCodeBufferChanged;
  if assigned(Manager) then
    Manager.UpdateFPDocEditor;
End;

function TSourceNotebook.FindPageWithEditor(
  ASourceEditor: TSourceEditor):integer;
var i:integer;
begin
  Result:=PageCount-1;
  while (Result>=0) do begin
    with NotebookPage[Result] do
      for I := 0 to ControlCount-1 do
        if Controls[I]=ASourceEditor.EditorComponent then exit;
    dec(Result);
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

procedure TSourceNotebook.NotebookMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  TabIndex: Integer;
begin
  if (Button = mbMiddle) then begin
    TabIndex:=FNotebook.TabIndexAtClientPos(Point(X,Y));
    if TabIndex>=0 then
      CloseClicked(NoteBookPage[TabIndex])
  end;
end;

procedure TSourceNotebook.NotebookDragTabMove(Sender, Source: TObject; OldIndex,
  NewIndex: Integer; CopyDrag: Boolean);
  function SourceIndex: Integer;
  begin
    Result := Manager.SourceWindowCount - 1;
    while Result >= 0 do begin
      if Manager.SourceWindows[Result].FNotebook = Source then break;
      dec(Result);
    end;
  end;
begin
  If CopyDrag then begin
    Manager.SourceWindows[SourceIndex].CopyEditor
      (OldIndex, Manager.IndexOfSourceWindow(self), NewIndex);
  end
  else begin
    if (Source = FNotebook) then
      MoveEditor(OldIndex, NewIndex)
    else begin
      Manager.SourceWindows[SourceIndex].MoveEditor
        (OldIndex, Manager.IndexOfSourceWindow(self), NewIndex);
    end;
  end;
end;

function TSourceNotebook.NotebookCanDragTabMove(Sender, Source: TObject;
  OldIndex, NewIndex: Integer; CopyDrag: Boolean): Boolean;
  function SourceIndex: Integer;
  begin
    Result := Manager.SourceWindowCount - 1;
    while Result >= 0 do begin
      if Manager.SourceWindows[Result].FNotebook = Source then break;
      dec(Result);
    end;
  end;
var
  Src: TSourceNotebook;
  NBHasSharedEditor: Boolean;
begin
  Src := Manager.SourceWindows[SourceIndex];
  NBHasSharedEditor := IndexOfEditorInShareWith
    (Src.FindSourceEditorWithPageIndex(OldIndex)) >= 0;
  if CopyDrag then
    Result := (NewIndex >= 0) and (Source <> Sender) and (not NBHasSharedEditor)
  else
    Result := (NewIndex >= 0) and
              ((Source <> Sender) or (OldIndex <> NewIndex)) and
              ((Source = Sender) or (not NBHasSharedEditor));
end;

Procedure TSourceNotebook.NotebookPageChanged(Sender: TObject);
var TempEditor:TSourceEditor;
Begin
  if not assigned(Manager) Then exit;
  TempEditor:=GetActiveSE;

  //writeln('TSourceNotebook.NotebookPageChanged ',Pageindex,' ',TempEditor <> nil,' fAutoFocusLock=',fAutoFocusLock);
  if TempEditor <> nil then
  begin
    if fAutoFocusLock=0 then begin
      {$IFDEF VerboseFocus}
      writeln('TSourceNotebook.NotebookPageChanged BEFORE SetFocus ',
        TempEditor.EditorComponent.Name,' ',
        NoteBookPages[FindPageWithEditor(TempEditor)]);
      {$ENDIF}
      TempEditor.FocusEditor;
      {$IFDEF VerboseFocus}
      writeln('TSourceNotebook.NotebookPageChanged AFTER SetFocus ',
        TempEditor.EditorComponent.Name,' ',
        NotebookPages[FindPageWithEditor(TempEditor)]);
      {$ENDIF}
    end;
    UpdateStatusBar;
    UpdateActiveEditColors(TempEditor.EditorComponent);
    if (DebugBoss.State in [dsPause, dsRun]) and
       not TempEditor.HasExecutionMarks and
       (TempEditor.FileName <> '') then
      TempEditor.FillExecutionMarks;
    if Assigned(Manager.OnEditorVisibleChanged) then
      Manager.OnEditorVisibleChanged(Self);
  end;

  CheckCurrentCodeBufferChanged;
  Manager.UpdateFPDocEditor;
end;

Procedure TSourceNotebook.ProcessParentCommand(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer;
  var Handled: boolean);
begin
  //DebugLn(['TSourceNotebook.ProcessParentCommand START ',dbgsName(Sender),' Command=',Command,' AChar=',AChar]);

  FProcessingCommand:=true;
  if Assigned(Manager.OnProcessUserCommand) then begin
    Handled:=false;
    Manager.OnProcessUserCommand(Self,Command,Handled);
    if Handled or (Command=ecNone) then begin
      FProcessingCommand:=false;
      Command:=ecNone;
      exit;
    end;
  end;
  //DebugLn(['TSourceNotebook.ProcessParentCommand after mainide: ',dbgsName(Sender),' Command=',Command,' AChar=',AChar]);

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

  ecMoveEditorLeftmost:
    MoveActivePageFirst;

  ecMoveEditorRightmost:
    MoveActivePageLast;

  ecNextSharedEditor:
    GotoNextSharedEditor(False);
  ecPrevSharedEditor:
    GotoNextSharedEditor(True);
  ecNextWindow:
    GotoNextWindow(False);
  ecPrevWindow:
    GotoNextWindow(True);
  ecMoveEditorNextWindow:
    MoveEditorNextWindow(False, False);
  ecMoveEditorPrevWindow:
    MoveEditorNextWindow(True, False);
  ecMoveEditorNewWindow:
    if EditorCount > 1 then
      MoveEditor(FindPageWithEditor(GetActiveSE), Manager.IndexOfSourceWindow(Manager.CreateNewWindow(True)), -1);
  ecCopyEditorNextWindow:
    MoveEditorNextWindow(False, True);
  ecCopyEditorPrevWindow:
    MoveEditorNextWindow(True, True);
  ecCopyEditorNewWindow:
    CopyEditor(FindPageWithEditor(GetActiveSE), Manager.IndexOfSourceWindow(Manager.CreateNewWindow(True)), -1);


  ecOpenFileAtCursor:
    OpenAtCursorClicked(self);

  ecGotoEditor1..ecGotoEditor9,ecGotoEditor0:
    if PageCount>Command-ecGotoEditor1 then
      PageIndex:=Command-ecGotoEditor1;

  ecToggleFormUnit:
    ToggleFormUnitClicked(Self);

  ecToggleObjectInsp:
    ToggleObjectInspClicked(Self);

  ecSetFreeBookmark:
    if Assigned(Manager.OnSetBookmark) then
      Manager.OnSetBookmark(GetActiveSE, -1, False);

  ecJumpBack:
    Manager.HistoryJump(Self,jhaBack);

  ecJumpForward:
    Manager.HistoryJump(Self,jhaForward);

  ecAddJumpPoint:
    Manager.AddJumpPointClicked(Self);

  ecViewJumpHistory:
    Manager.ViewJumpHistoryClicked(Self);

  else
    Handled:=ExecuteIDECommand(Self,Command);
    DebugLn('TSourceNotebook.ProcessParentCommand Command=',dbgs(Command),' Handled=',dbgs(Handled));
  end;  //case
  if Handled then Command:=ecNone;
  FProcessingCommand:=false;
end;

Procedure TSourceNotebook.ParentCommandProcessed(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer;
  var Handled: boolean);
begin
  if assigned(Manager) and Assigned(Manager.OnUserCommandProcessed) then begin
    Handled:=false;
    Manager.OnUserCommandProcessed(Self,Command,Handled);
    if Handled then exit;
  end;

  Handled:=(Command=ecClose);

  if Handled then Command:=ecNone;
end;

Procedure TSourceNotebook.ReloadEditorOptions;
var
  I: integer;
Begin
  for i := 0 to EditorCount-1 do
    Editors[i].RefreshEditorSettings;

  EditorOpts.KeyMap.AssignTo(FKeyStrokes,TSourceEditorWindowInterface);
  if EditorOpts.ShowTabCloseButtons then
    FNoteBook.Options:=FNoteBook.Options+[nboShowCloseButtons]
  else
    FNoteBook.Options:=FNoteBook.Options-[nboShowCloseButtons];
  FNotebook.TabPosition := EditorOpts.TabPosition;

  FMouseHintTimer.Interval:=EditorOpts.AutoDelayInMSec;

  Exclude(States,snWarnedFont);
  CheckFont;
  UpdatePageNames;
end;

procedure TSourceNotebook.CheckFont;
var
  SrcEdit: TSourceEditor;
  DummyResult: TModalResult;
  CurFont: TFont;
begin
  if (snWarnedFont in States) then exit;
  Include(States,snWarnedFont);
  SrcEdit:=GetActiveSE;
  if SrcEdit = nil then
    Exit;
  CurFont:=SrcEdit.EditorComponent.Font;
  if (not CurFont.CanUTF8) and SystemCharSetIsUTF8
  and ((EditorOpts.DoNotWarnForFont='')
       or (EditorOpts.DoNotWarnForFont<>CurFont.Name))
  then begin
    {$IFDEF HasMonoSpaceFonts}
    DummyResult:=QuestionDlg(lisUEFontWith,
      Format(lisUETheCurre, [#13, #13]),
      mtWarning, [mrIgnore, mrYesToAll, lisUEDoNotSho], 0);
    {$ELSE}
    DummyResult:=mrYesToAll;
    {$ENDIF}
    if DummyResult=mrYesToAll then begin
      if EditorOpts.DoNotWarnForFont<>CurFont.Name then begin
        EditorOpts.DoNotWarnForFont:=CurFont.Name;
        EditorOpts.Save;
      end;
    end;
  end;
end;

procedure TSourceNotebook.KeyDownBeforeInterface(var Key: Word;
  Shift: TShiftState);
var i, Command: integer;
Begin
  inherited KeyDown(Key,Shift);
  if not assigned(Manager) then exit;
  i := FKeyStrokes.FindKeycode(Key, Shift);
  if i>=0 then begin
    Command:=FKeyStrokes[i].Command;
    case Command of

    ecGotoMarker0..ecGotoMarker9:
      begin
        if Assigned(Manager.OnGotoBookmark) then
          Manager.OnGotoBookmark(ActiveEditor, Command - ecGotoMarker0, False);
        Key:=0;
      end;

    ecSetMarker0..ecSetMarker9:
      begin
        if Assigned(Manager.OnSetBookmark) then
          Manager.OnSetBookmark(GetActiveSE, Command - ecSetMarker0, False);
        Key:=0;
      end;

    ecToggleMarker0..ecToggleMarker9:
      begin
        if Assigned(Manager.OnSetBookmark) then
          Manager.OnSetBookmark(GetActiveSE, Command - ecToggleMarker0, True);
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
  HideHint;
  if not Visible then exit;
  if (MainIDEInterface.ToolStatus=itDebugger) then
    FMouseHintTimer.AutoEnabled := EditorOpts.AutoToolTipExprEval
  else
    FMouseHintTimer.AutoEnabled := EditorOpts.AutoToolTipSymbTools;
end;

procedure TSourceNotebook.EditorMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  HideHint;
  //handled:=true; //The scrolling is not done: it's not handled! See TWinControl.DoMouseWheel
end;

procedure TSourceNotebook.EditorMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftstate; X, Y: Integer);
begin

end;

function TSourceNotebook.EditorGetIndent(Sender: TObject; Editor: TObject;
  LogCaret, OldLogCaret: TPoint; FirstLinePos, LastLinePos: Integer;
  Reason: TSynEditorCommand; SetIndentProc: TSynBeautifierSetIndentProc
  ): Boolean;
var
  SrcEdit: TSourceEditor;
  p: LongInt;
  NestedComments: Boolean;
  NewIndent: TFABIndentationPolicy;
  Indent: LongInt;
  CodeBuf: TCodeBuffer;
begin
  Result:=false;
  //SrcEdit:=GetActiveSE;
  SrcEdit := Manager.ActiveEditor; // Todo: Each SynEdit needs its own Beautifier, otherwise they call the wrong notebook
  if assigned(Manager) and Assigned(Manager.OnGetIndent) then begin
    Result := Manager.OnGetIndent(Sender, SrcEdit, LogCaret, OldLogCaret, FirstLinePos, LastLinePos,
                          Reason, SetIndentProc);
    if Result then exit;
  end;
  if (SrcEdit.SyncroLockCount > 0) then exit;
  if not (SrcEdit.SyntaxHighlighterType in [lshFreePascal, lshDelphi]) then
    exit;
  if Reason<>ecLineBreak then exit;
  if not CodeToolsOpts.IndentOnLineBreak then exit;
  {$IFDEF VerboseIndenter}
  debugln(['TSourceNotebook.EditorGetIndent LogCaret=',dbgs(LogCaret),' FirstLinePos=',FirstLinePos,' LastLinePos=',LastLinePos]);
  {$ENDIF}
  Result := True;
  SrcEdit.UpdateCodeBuffer;
  CodeBuf:=SrcEdit.CodeBuffer;
  CodeBuf.LineColToPosition(LogCaret.Y-1,LogCaret.X,p);
  if p<1 then exit;
  {$IFDEF VerboseIndenter}
  if FirstLinePos>0 then
    DebugLn(['TSourceNotebook.EditorGetIndent Firstline-1=',SrcEdit.Lines[FirstLinePos-1]]);
  DebugLn(['TSourceNotebook.EditorGetIndent Firstline+0=',SrcEdit.Lines[FirstLinePos]]);
  if FirstLinePos<SrcEdit.LineCount then
    DebugLn(['TSourceNotebook.EditorGetIndent Firstline+1=',SrcEdit.Lines[FirstLinePos+1]]);
  {$ENDIF}
  NestedComments:=CodeToolBoss.GetNestedCommentsFlagForFile(CodeBuf.Filename);
  if not CodeToolBoss.Indenter.GetIndent(CodeBuf.Source,p,NestedComments,
    True,NewIndent,CodeToolsOpts.IndentContextSensitive)
  then exit;
  if not NewIndent.IndentValid then exit;
  Indent:=NewIndent.Indent;
  {$IFDEF VerboseIndenter}
  DebugLn(['TSourceNotebook.EditorGetIndent Indent=',Indent]);
  {$ENDIF}
  {$IFDEF VerboseIndenter}
  DebugLn(['TSourceNotebook.EditorGetIndent Apply to FirstLinePos+1']);
  {$ENDIF}
  SetIndentProc(LogCaret.Y, Indent, 0,' ');
  SrcEdit.CursorScreenXY:=Point(Indent+1,SrcEdit.CursorScreenXY.Y);
end;

Procedure TSourceNotebook.HintTimer(sender: TObject);
var
  MousePos: TPoint;
  AControl: TControl;
begin
  //DebugLn(['TSourceNotebook.HintTimer ']);
  FMouseHintTimer.Enabled := False;
  FMouseHintTimer.AutoEnabled := False;
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

procedure TSourceNotebook.EditorKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

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
  EditCaret:=ASynEdit.PhysicalToLogicalPos(ASynEdit.PixelsToRowColumn(EditPos));
  if (EditCaret.Y<1) then exit;
  if EditPos.X<ASynEdit.Gutter.Width then begin
    // hint for a gutter item
    if EditorOpts.ShowGutterHints then begin
      ASynEdit.Marks.GetMarksForLine(EditCaret.Y,LineMarks);
      HintStr:='';
      for i:=Low(TSynEditMarks) to High(TSynEditMarks) do begin
        if not (LineMarks[i] is TSourceSynMark) then continue;
        AMark := TSourceSynMark(LineMarks[i]).SourceMark;
        if AMark = nil then continue;
        CurHint:=AMark.GetHint;
        if CurHint='' then continue;
        if HintStr<>'' then HintStr:=HintStr+LineEnding;
        HintStr:=HintStr+CurHint;
      end;
      if HintStr<>'' then
        ActivateHint(MousePos,'',HintStr);
    end;
  end else begin
    // hint for source
    if assigned(manager) and Assigned(Manager.OnShowHintForSource) then
      Manager.OnShowHintForSource(ASrcEdit,EditPos,EditCaret);
  end;
end;

procedure TSourceNotebook.SetIncrementalSearchStr(const AValue: string);
begin
  if FIncrementalSearchStr=AValue then exit;
  FIncrementalSearchStr:=AValue;
  IncrementalSearch(False, False);
end;

procedure TSourceNotebook.IncrementalSearch(ANext, ABackward: Boolean);
const
  SEARCH_OPTS: array[Boolean] of TSynSearchOptions = ([], [ssoBackwards]);
var
  CurEdit: TSynEdit;
  AStart : TPoint;
begin
  if not (snIncrementalFind in States)
  then begin
    UpdateStatusBar;
    Exit;
  end;
  if FIncrementalSearchEditor = nil then Exit;

  // search string
  CurEdit := FIncrementalSearchEditor.EditorComponent;
  CurEdit.BeginUpdate;
  if FIncrementalSearchStr<>''
  then begin
    // search from search start position when not searching for the next
    AStart := CurEdit.LogicalCaretXY;
    if not ANext
    then AStart := FIncrementalSearchStartPos
    else if ABackward
    then AStart := CurEdit.BlockBegin;
    FIncrementalSearchBackwards:=ABackward;
    CurEdit.SearchReplaceEx(FIncrementalSearchStr,'', SEARCH_OPTS[ABackward], AStart);

    // searching next resets incremental history
    if ANext
    then begin
      FIncrementalSearchStartPos := CurEdit.BlockBegin;
    end;

    // cut the not found
    FIncrementalSearchStr := CurEdit.SelText;

    CurEdit.SetHighlightSearch(FIncrementalSearchStr, []);
    if Length(FIncrementalSearchStr) > 0
    then FIncrementalFoundStr := FIncrementalSearchStr;
  end
  else begin
    // go to start
    CurEdit.LogicalCaretXY:= FIncrementalSearchStartPos;
    CurEdit.BlockBegin:=CurEdit.LogicalCaretXY;
    CurEdit.BlockEnd:=CurEdit.BlockBegin;
    CurEdit.SetHighlightSearch('', []);
  end;
  FIncrementalSearchPos:=CurEdit.LogicalCaretXY;
  CurEdit.EndUpdate;

  UpdateStatusBar;
end;

procedure TSourceNotebook.Activate;
begin
  inherited Activate;
  if assigned(Manager) then
    Manager.ActiveSourceWindow := self;
  if assigned(Manager) and assigned(Manager.OnWindowActivate) then
    Manager.OnWindowActivate(self);
end;

procedure TSourceNotebook.UpdateActiveEditColors(AEditor: TSynEdit);
begin
  if AEditor=nil then exit;
  EditorOpts.SetMarkupColors(AEditor.Highlighter, AEditor);
  AEditor.UseIncrementalColor:= snIncrementalFind in States;
end;

function TSourceNotebook.GetEditorControlSettings(EditControl: TControl
  ): boolean;
begin
  // Deprecated; forward to manager
  Result := SourceEditorManager.GetEditorControlSettings(EditControl);
end;

function TSourceNotebook.GetHighlighterSettings(Highlighter: TObject): boolean;
begin
  // Deprecated; forward to manager
  Result := SourceEditorManager.GetHighlighterSettings(Highlighter);
end;

procedure TSourceNotebook.ClearErrorLines;
var
  i: integer;
begin
  for i := 0 to EditorCount - 1 do
    Editors[i].ErrorLine := -1;
end;

procedure TSourceNotebook.ClearExecutionLines;
var
  i: integer;
begin
  for i := 0 to EditorCount - 1 do
    Editors[i].ExecutionLine := -1;
end;

procedure TSourceNotebook.ClearExecutionMarks;
var
  i: integer;
begin
  for i := 0 to EditorCount - 1 do
    Editors[i].ClearExecutionMarks;
end;

procedure TSourceNotebook.CloseTabClicked(Sender: TObject);
begin
  FPageIndex := PageIndex;
  if assigned(manager) and Assigned(Manager.OnCloseClicked) then
    Manager.OnCloseClicked(Sender, GetKeyState(VK_CONTROL) < 0);
end;

{ TSynEditPlugin1 }

constructor TSynEditPlugin1.Create(AOwner: TComponent);
Begin
  inherited Create(AOwner);
  FEnabled := True;
  ViewedTextBuffer.AddChangeHandler(senrLineCount, {$IFDEF FPC}@{$ENDIF}LineCountChanged);
end;

destructor TSynEditPlugin1.Destroy;
begin
  ViewedTextBuffer.RemoveChangeHandler(senrLineCount, {$IFDEF FPC}@{$ENDIF}LineCountChanged);
  inherited Destroy;
end;

procedure TSynEditPlugin1.LineCountChanged(Sender: TSynEditStrings; AIndex, ACount: Integer);
begin
  if not FEnabled then exit;
  if ACount < 0 then begin
    if Assigned(OnLinesDeleted) then
      OnLinesDeleted(self, AIndex+1, -ACount);
  end else begin
    if Assigned(OnLinesInserted) then
      OnLinesInserted(self, AIndex+1, ACount);
  end;
end;

function TSynEditPlugin1.OwnedByEditor: Boolean;
begin
  Result := True;
end;

//-----------------------------------------------------------------------------

procedure InternalInit;
var h: TLazSyntaxHighlighter;
begin
  for h:=Low(TLazSyntaxHighlighter) to High(TLazSyntaxHighlighter) do
    Highlighters[h]:=nil;
  IDESearchInText:=@SearchInText;
end;

procedure InternalFinal;
var h: TLazSyntaxHighlighter;
begin
  for h:=Low(TLazSyntaxHighlighter) to High(TLazSyntaxHighlighter) do
    FreeThenNil(Highlighters[h]);
  FreeThenNil(aWordCompletion);
end;


{ TSourceDragableNotebook }

procedure TSourceDragableNotebook.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  InitDrag;
  FTabDragged:=false;
  inherited MouseDown(Button, Shift, X, Y);
  FMouseDownTabIndex := TabIndexAtClientPos(Point(X,Y));
  if (Button = mbLeft) and (FMouseDownTabIndex >= 0) then
    BeginDrag(False);
end;

procedure TSourceDragableNotebook.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  MouseUpTabIndex: LongInt;
begin
  InitDrag;
  inherited MouseUp(Button, Shift, X, Y);
  if not FTabDragged then begin
    // no drag => check for normal click and activate page
    MouseUpTabIndex := TabIndexAtClientPos(Point(X,Y));
    if (Button = mbLeft) and (FMouseDownTabIndex = MouseUpTabIndex) then
      PageIndex:=MouseUpTabIndex;
  end;
end;

procedure TSourceDragableNotebook.DragOver(Source: TObject; X, Y: Integer; State: TDragState;
  var Accept: Boolean);
var
  TabIndex: Integer;
  TabPos, LastRect, LastNRect, tmp: TRect;
  LastIndex: Integer;
  LastRight, NeedInvalidate: Boolean;
  Ctrl: Boolean;
  Src: TSourceDragableNotebook;
begin
  inherited DragOver(Source, X, Y, State, Accept);
  if (state = dsDragLeave) and (FDragOverIndex >= 0) then begin
    tmp := FDragOverTabRect;
    InvalidateRect(Handle, @tmp, false);
    tmp := FDragNextToTabRect;
    InvalidateRect(Handle, @tmp, false);
    FDragOverIndex := -1;
  end;
  // currently limited to source=self => extendable to allow dragging tabs from other notebooks
  if (Source is TSourceDragableNotebook) and
     (TSourceDragableNotebook(Source).FMouseDownTabIndex >= 0)
  then begin
    {$IFnDEF SingleSrcWindow}
    Ctrl := (GetKeyState(VK_CONTROL) and $8000)<>0;
    {$ELSE}
    Ctrl := false;
    {$ENDIF}
    if Ctrl then
      DragCursor := crMultiDrag
    else
      DragCursor := crDrag;


    TabIndex := TabIndexAtClientPos(Point(X,Y));
    if TabIndex < 0 then begin
      TabPos := TabRect(PageCount-1);
      if (TabPos.Right > 1) and (X > TabPos.Right) then
        TabIndex := PageCount - 1;
    end;

    LastIndex := FDragOverIndex;
    LastRight := FDragToRightSide;
    LastRect := FDragOverTabRect;
    LastNRect := FDragNextToTabRect;
    FDragOverIndex := TabIndex;
    FDragOverTabRect := TabRect(TabIndex);
    FDragToRightSide := X > (FDragOverTabRect.Left + FDragOverTabRect.Right) div 2;
    if (Source = Self) and (TabIndex = FMouseDownTabIndex - 1) then
      FDragToRightSide := False;
    if (Source = Self) and (TabIndex = FMouseDownTabIndex + 1) then
      FDragToRightSide := True;

    NeedInvalidate := (FDragOverIndex <> LastIndex) or (FDragToRightSide <> LastRight);
    if NeedInvalidate then begin
      InvalidateRect(Handle, @LastRect, false);
      InvalidateRect(Handle, @LastNRect, false);
      tmp := FDragOverTabRect;
      InvalidateRect(Handle, @tmp, false);
      tmp := FDragNextToTabRect;
      InvalidateRect(Handle, @tmp, false);
    end;

    if FDragToRightSide then begin
      inc(TabIndex);
      if TabIndex < PageCount then
        FDragNextToTabRect := TabRect(TabIndex);
    end else begin
      if TabIndex > 0 then
        FDragNextToTabRect := TabRect(TabIndex - 1);
    end;
    if NeedInvalidate then begin
      tmp := FDragNextToTabRect;
      InvalidateRect(Handle, @tmp, false);
    end;

    Src := TSourceDragableNotebook(Source);
    if (Source = self) and (TabIndex > Src.MouseDownTabIndex) then
      dec(TabIndex);

    Accept := OnCanDragMoveTab(Self, Source, Src.MouseDownTabIndex, TabIndex, Ctrl);
  end
  else
    FDragOverIndex := -1;
  if (not Accept) or (state = dsDragLeave) then
    FDragOverIndex := -1;

end;

procedure TSourceDragableNotebook.DragCanceled;
var
  tmp: TRect;
begin
  inherited DragCanceled;
  if (FDragOverIndex >= 0) then begin
    tmp := FDragOverTabRect;
    InvalidateRect(Handle, @tmp, false);
    tmp := FDragNextToTabRect;
    InvalidateRect(Handle, @tmp, false);
  end;
  FDragOverIndex := -1;
  DragCursor := crDrag;
end;

procedure TSourceDragableNotebook.PaintWindow(DC: HDC);
var
  Points: Array [0..3] of TPoint;
  h, x: Integer;
begin
  inherited PaintWindow(DC);
  if FDragOverIndex < 0 then exit;

  x := 0;
  h := (Abs(FDragOverTabRect.Bottom - FDragOverTabRect.Top) - 4) div 2;
  if FDragToRightSide then begin
    if (FDragNextToTabRect.Left < FDragOverTabRect.Right) and
       (FDragOverIndex < PageCount - 1)
    then
      x := FDragOverTabRect.Right - FDragNextToTabRect.Left
    else
      x := 8;
    Points[0].X := FDragOverTabRect.Right - 2 - h - x;
    Points[0].y := FDragOverTabRect.Top + 2;
    Points[1].X := FDragOverTabRect.Right - 2 - h - x;
    Points[1].y := FDragOverTabRect.Bottom - 2;
    Points[2].X := FDragOverTabRect.Right - 2 - x;
    Points[2].y := FDragOverTabRect.Top + 2 + h;
    Points[3] := Points[0];
    Polygon(DC, @Points, 4, False);

    if (FDragOverIndex < PageCount - 1) then begin
      Points[0].X := FDragNextToTabRect.Left + 2 + h;
      Points[0].y := FDragNextToTabRect.Top + 2;
      Points[1].X := FDragNextToTabRect.Left + 2 + h;
      Points[1].y := FDragNextToTabRect.Bottom - 2;
      Points[2].X := FDragNextToTabRect.Left + 2;
      Points[2].y := FDragNextToTabRect.Top + 2 + h;
      Points[3] := Points[0];
      Polygon(DC, @Points, 4, False);
    end;
  end else begin
    if (FDragNextToTabRect.Right < FDragOverTabRect.Left) and
       (FDragOverIndex > 1)
    then
      x := FDragOverTabRect.Left - FDragNextToTabRect.Right
    else
      x := 8;
    Points[0].X := FDragOverTabRect.Left + 2 + h;
    Points[0].y := FDragOverTabRect.Top + 2;
    Points[1].X := FDragOverTabRect.Left + 2 + h;
    Points[1].y := FDragOverTabRect.Bottom - 2;
    Points[2].X := FDragOverTabRect.Left + 2;
    Points[2].y := FDragOverTabRect.Top + 2 + h;
    Points[3] := Points[0];
    Polygon(DC, @Points, 4, True);

    if (FDragOverIndex > 0) then begin
      Points[0].X := FDragNextToTabRect.Right - 2 - h - x;
      Points[0].y := FDragNextToTabRect.Top + 2;
      Points[1].X := FDragNextToTabRect.Right - 2 - h - x;
      Points[1].y := FDragNextToTabRect.Bottom - 2;
      Points[2].X := FDragNextToTabRect.Right - 2 - x;
      Points[2].y := FDragNextToTabRect.Top + 2 + h;
      Points[3] := Points[0];
      Polygon(DC, @Points, 4, False);
    end;
  end;

end;

procedure TSourceDragableNotebook.InitDrag;
begin
  DragCursor := crDrag;
  FDragOverIndex := -1;
  FDragOverTabRect := Rect(0, 0, 0, 0);
  FDragNextToTabRect := Rect(0, 0, 0, 0);
end;

constructor TSourceDragableNotebook.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  InitDrag;
end;

procedure TSourceDragableNotebook.DragDrop(Source: TObject; X, Y: Integer);
var
  TabIndex: Integer;
  TabPos, tmp: TRect;
  ToRight: Boolean;
  Ctrl: Boolean;
  Src: TSourceDragableNotebook;
begin
  inherited DragDrop(Source, X, Y);
  if (FDragOverIndex >= 0) then begin
    tmp := FDragOverTabRect;
    InvalidateRect(Handle, @tmp, false);
    tmp := FDragNextToTabRect;
    InvalidateRect(Handle, @tmp, false);
  end;
  FDragOverIndex := -1;
  DragCursor := crDrag;

  if assigned(FOnDragMoveTab) and (Source is TSourceDragableNotebook) and
     (TSourceDragableNotebook(Source).MouseDownTabIndex >= 0)
  then begin
    {$IFnDEF SingleSrcWindow}
    Ctrl := (GetKeyState(VK_CONTROL) and $8000)<>0;
    {$ELSE}
    Ctrl := false;
    {$ENDIF}

    TabIndex := TabIndexAtClientPos(Point(X,Y));
    if TabIndex < 0 then begin
      TabPos := TabRect(PageCount-1);
      if (TabPos.Right > 1) and (X > TabPos.Right) then
        TabIndex := PageCount - 1;
    end;
    TabPos := TabRect(TabIndex);

    ToRight := X > (TabPos.Left + TabPos.Right) div 2;
    if (Source = Self) and (TabIndex = FMouseDownTabIndex - 1) then
      ToRight := False;
    if (Source = Self) and (TabIndex = FMouseDownTabIndex + 1) then
      ToRight := True;
    if ToRight then
      inc(TabIndex);

    Src := TSourceDragableNotebook(Source);
    // includes unknown
    if (Source = self) and (TabIndex > Src.MouseDownTabIndex) then
      dec(TabIndex);
    if OnCanDragMoveTab(Self, Source, Src.MouseDownTabIndex, TabIndex, Ctrl) then
    begin
      FTabDragged:=true;
      FOnDragMoveTab(Self, Source, Src.MouseDownTabIndex, TabIndex, Ctrl);
    end;
  end;
end;

{ TSourceEditorManagerBase }

procedure TSourceEditorManagerBase.FreeSourceWindows;
var
  s: TSourceEditorWindowInterface;
begin
  while FSourceWindowList.Count > 0 do begin
    s := TSourceEditorWindowInterface(FSourceWindowList[0]);
    FSourceWindowList.Delete(0);
    s.Free;
  end;
  FSourceWindowList.Clear;
end;

function TSourceEditorManagerBase.GetActiveSourceWindowIndex: integer;
begin
  Result := IndexOfSourceWindow(ActiveSourceWindow);
end;

procedure TSourceEditorManagerBase.SetActiveSourceWindowIndex(
  const AValue: integer);
begin
  ActiveSourceWindow := SourceWindows[AValue];
end;

function TSourceEditorManagerBase.GetActiveSourceWindow: TSourceEditorWindowInterface;
begin
  Result := FActiveWindow;
end;

procedure TSourceEditorManagerBase.SetActiveSourceWindow(
  const AValue: TSourceEditorWindowInterface);
begin
  if AValue = FActiveWindow then exit;
  if (FActiveWindow <> nil) and (AValue <> nil) and (FActiveWindow.Focused) then
    AValue.SetFocus;

  FActiveWindow := AValue as TSourceNotebook;

  // Todo: Each synEdit needs it's own beautifier
  if SourceEditorCount > 0 then
    TSourceEditor(SourceEditors[0]).EditorComponent.Beautifier.OnGetDesiredIndent
      := @TSourceNotebook(ActiveSourceWindow).EditorGetIndent;

  if Assigned(OnEditorVisibleChanged) then
    OnEditorVisibleChanged(nil);
  if Assigned(OnCurrentCodeBufferChanged) then
    OnCurrentCodeBufferChanged(nil);
  UpdateFPDocEditor;
end;

function TSourceEditorManagerBase.GetSourceWindows(Index: integer
  ): TSourceEditorWindowInterface;
begin
  Result := TSourceEditorWindowInterface(FSourceWindowList[Index]);
end;

function TSourceEditorManagerBase.GetActiveEditor: TSourceEditorInterface;
begin
  If FActiveWindow <> nil then
    Result := FActiveWindow.ActiveEditor
  else
    Result := nil;
end;

procedure TSourceEditorManagerBase.SetActiveEditor(
  const AValue: TSourceEditorInterface);
var
  Window: TSourceEditorWindowInterface;
begin
  if (FActiveWindow <> nil) and (FActiveWindow.IndexOfEditor(AValue) >= 0) then
    Window := FActiveWindow
  else
    Window := SourceWindowWithEditor(AValue);
  if Window = nil then exit;
  ActiveSourceWindow := TSourceNotebook(Window);
  Window.ActiveEditor := AValue;
end;

function TSourceEditorManagerBase.GetSourceEditors(Index: integer
  ): TSourceEditorInterface;
var
  i: Integer;
begin
  i := 0;
  while (i < SourceWindowCount) and (Index >= SourceWindows[i].Count) do begin
    Index := Index - SourceWindows[i].Count;
    inc(i);
  end;
  if (i < SourceWindowCount) then
    Result := SourceWindows[i].Items[Index]
  else
    Result := nil;
end;

function TSourceEditorManagerBase.GetUniqueSourceEditors(Index: integer
  ): TSourceEditorInterface;
var
  i: Integer;
begin
  for i := 0 to SourceEditorCount - 1 do begin
    Result := SourceEditors[i];
    if (TSourceEditor(Result).SharedEditorCount = 0) or
       (TSourceEditor(Result).SharedEditors[0] = Result)
    then
      dec(Index);
    if Index < 0 then exit;
  end;
  Result := nil;
end;

function TSourceEditorManagerBase.SourceWindowWithEditor(
  const AEditor: TSourceEditorInterface): TSourceEditorWindowInterface;
var
  i: Integer;
begin
  Result := nil;
  for i := FSourceWindowList.Count-1 downto 0 do begin
    if TSourceNotebook(SourceWindows[i]).IndexOfEditor(AEditor) >= 0 then begin
      Result := SourceWindows[i];
      break;
    end;
  end;
end;

function TSourceEditorManagerBase.SourceWindowCount: integer;
begin
  if assigned(FSourceWindowList) then
    Result := FSourceWindowList.Count
  else
    Result := 0;
end;

function TSourceEditorManagerBase.IndexOfSourceWindow(
  AWindow: TSourceEditorWindowInterface): integer;
begin
  Result := SourceWindowCount - 1;
  while Result >= 0 do Begin
    if SourceWindows[Result] = AWindow then
      exit;
    dec(Result);
  end;
end;

function TSourceEditorManagerBase.SourceEditorIntfWithFilename(
  const Filename: string): TSourceEditorInterface;
var
  i: Integer;
begin
  for i := SourceEditorCount - 1 downto 0 do begin
    Result := SourceEditors[i];
    if CompareFilenames(Result.Filename, Filename) = 0 then exit;
  end;
  Result:=nil;
end;

function TSourceEditorManagerBase.SourceEditorCount: integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to SourceWindowCount - 1 do
    Result := Result + SourceWindows[i].Count;
end;

function TSourceEditorManagerBase.UniqueSourceEditorCount: integer;
var
  SrcEdit: TSourceEditor;
  i: Integer;
begin
  Result := 0;
  for i := 0 to SourceEditorCount - 1 do begin
    SrcEdit := TSourceEditor(SourceEditors[i]);
    if (SrcEdit.SharedEditorCount = 0) or (SrcEdit.SharedEditors[0] = SrcEdit) then
      inc(Result);
  end;
end;

function TSourceEditorManagerBase.GetEditorControlSettings(EditControl: TControl
  ): boolean;
begin
  Result:=true;
  if EditControl is TSynEdit then begin
    EditorOpts.GetSynEditSettings(TSynEdit(EditControl));
    Result:=true;
  end else begin
    Result:=false;
  end;
end;

function TSourceEditorManagerBase.GetHighlighterSettings(Highlighter: TObject
  ): boolean;
begin
  Result:=true;
  if Highlighter is TSynCustomHighlighter then begin
    EditorOpts.GetHighlighterSettings(TSynCustomHighlighter(Highlighter));
    Result:=true;
  end else begin
    Result:=false;
  end;
end;

function TSourceEditorManagerBase.GetDefaultCompletionForm: TSourceEditCompletion;
var
  i: Integer;
begin
  Result := FDefaultCompletionForm;
  if Result <> nil then exit;
  FDefaultCompletionForm := TSourceEditCompletion.Create(Self);
  Result := FDefaultCompletionForm;
  for i:=0 to SourceEditorCount - 1 do
    FDefaultCompletionForm.AddEditor(TSourceEditor(SourceEditors[i]).EditorComponent);
end;

procedure TSourceEditorManagerBase.FreeCompletionPlugins;
var
  p: TSourceEditorCompletionPlugin;
begin
  while FCompletionPlugins.Count > 0 do begin
    p := TSourceEditorCompletionPlugin(FCompletionPlugins[0]);
    FCompletionPlugins.Delete(0);
    p.Free;
  end;
  FCompletionPlugins.Clear;
end;

function TSourceEditorManagerBase.GetActiveCompletionPlugin: TSourceEditorCompletionPlugin;
begin
  Result := FActiveCompletionPlugin;
end;

function TSourceEditorManagerBase.GetCompletionBoxPosition: integer;
begin
  Result:=-1;
  if (FDefaultCompletionForm<>nil) and FDefaultCompletionForm.IsActive then
    Result := FDefaultCompletionForm.Position;
end;

function TSourceEditorManagerBase.GetCompletionPlugins(Index: integer
  ): TSourceEditorCompletionPlugin;
begin
  Result:=TSourceEditorCompletionPlugin(fCompletionPlugins[Index]);
end;

function TSourceEditorManagerBase.FindIdentCompletionPlugin(
  SrcEdit: TSourceEditor; JumpToError: boolean; var s: string; var BoxX,
  BoxY: integer; var UseWordCompletion: boolean): boolean;
var
  i: Integer;
  Plugin: TSourceEditorCompletionPlugin;
  Handled: Boolean;
  Cancel: Boolean;
begin
  for i:=0 to CompletionPluginCount-1 do begin
    Plugin := CompletionPlugins[i];
    Handled:=false;
    Cancel:=false;
    Plugin.Init(SrcEdit,JumpToError,Handled,Cancel,s,BoxX,BoxY);
    if Cancel then begin
      DeactivateCompletionForm;
      exit(false);
    end;
    if Handled then begin
      FActiveCompletionPlugin:=Plugin;
      exit(true);
    end;
  end;

  if not (SrcEdit.SyntaxHighlighterType in [lshFreePascal, lshDelphi]) then
    UseWordCompletion:=true;
  Result:=true;
end;

function TSourceEditorManagerBase.CompletionPluginCount: integer;
begin
  Result:=fCompletionPlugins.Count;
end;

procedure TSourceEditorManagerBase.DeactivateCompletionForm;
begin
  if ActiveCompletionPlugin<>nil then begin
    ActiveCompletionPlugin.Cancel;
    FActiveCompletionPlugin:=nil;
  end;

  if (FDefaultCompletionForm=nil) or
     (FDefaultCompletionForm.CurrentCompletionType = ctNone)
  then
    exit;

  // clear the IdentifierList (otherwise it would try to update everytime
  // the codetools are used)
  CodeToolBoss.IdentifierList.Clear;
  FDefaultCompletionForm.CurrentCompletionType:=ctNone;
  FDefaultCompletionForm.Deactivate;

  if ActiveEditor<>nil then begin
    //LCLIntf.ShowCaret(ActSE.EditorComponent.Handle);
    TSourceEditor(ActiveEditor).EditorComponent.SetFocus;
  end;
end;

procedure TSourceEditorManagerBase.RegisterCompletionPlugin(
  Plugin: TSourceEditorCompletionPlugin);
begin
  fCompletionPlugins.Add(Plugin);
  Plugin.FreeNotification(Self);
end;

procedure TSourceEditorManagerBase.UnregisterCompletionPlugin(
  Plugin: TSourceEditorCompletionPlugin);
begin
  Plugin.RemoveFreeNotification(Self);
  fCompletionPlugins.Remove(Plugin);
end;

procedure TSourceEditorManagerBase.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation=opRemove then
  begin
    if Assigned(fCompletionPlugins) then
      fCompletionPlugins.Remove(AComponent);
    if ActiveCompletionPlugin = AComponent then
      DeactivateCompletionForm;
  end;
end;

constructor TSourceEditorManagerBase.Create(AOwner: TComponent);
var
  i: TsemChangeReason;
begin
  for i := low(TsemChangeReason) to high(TsemChangeReason) do
    FChangeNotifyLists[i] := TMethodList.Create;
  SrcEditorIntf.SourceEditorManagerIntf := Self;
  FSourceWindowList := TFPList.Create;
  FCompletionPlugins := TFPList.Create;
  FUpdateLock := 0;
  inherited;
end;

destructor TSourceEditorManagerBase.Destroy;
var
  i: TsemChangeReason;
begin
  FActiveWindow := nil;
  FreeCompletionPlugins;
  FreeSourceWindows;
  SrcEditorIntf.SourceEditorManagerIntf := nil; // xx move down
  FreeAndNil(FCompletionPlugins);
  FreeAndNil(FSourceWindowList);
  for i := low(TsemChangeReason) to high(TsemChangeReason) do
    FChangeNotifyLists[i].Free;;
  inherited Destroy;
end;

procedure TSourceEditorManagerBase.RegisterChangeEvent(
  AReason: TsemChangeReason; AHandler: TNotifyEvent);
begin
  FChangeNotifyLists[AReason].Add(TMethod(AHandler));
end;

procedure TSourceEditorManagerBase.UnRegisterChangeEvent(
  AReason: TsemChangeReason; AHandler: TNotifyEvent);
begin
  FChangeNotifyLists[AReason].Remove(TMethod(AHandler));
end;

procedure TSourceEditorManagerBase.IncUpdateLock;
var
  i: Integer;
begin
  if FUpdateLock = 0 then begin
    FShowWindowOnTop := False;
    FShowWindowOnTopFocus := False;
  end;
  inc(FUpdateLock);
  for i := 0 to SourceWindowCount - 1 do
    TSourceNotebook(SourceWindows[i]).IncUpdateLock;
end;

procedure TSourceEditorManagerBase.DecUpdateLock;
var
  i: Integer;
begin
  for i := 0 to SourceWindowCount - 1 do
    TSourceNotebook(SourceWindows[i]).DecUpdateLock;
  dec(FUpdateLock);
  if (FUpdateLock = 0) and FShowWindowOnTop then
    ShowActiveWindowOnTop(FShowWindowOnTopFocus);
end;

procedure TSourceEditorManagerBase.ShowActiveWindowOnTop(Focus: Boolean);
begin
  if ActiveSourceWindow = nil then exit;
  if FUpdateLock > 0 then begin
    FShowWindowOnTop := True;
    if Focus then
      FShowWindowOnTopFocus := True;
    exit;
  end;;
  ActiveSourceWindow.ShowOnTop;
  if Focus then
    TSourceNotebook(ActiveSourceWindow).FocusEditor;
end;

procedure TSourceEditorManagerBase.UpdateFPDocEditor;
var
  SrcEdit: TSourceEditor;
  CaretPos: TPoint;
begin
  if FPDocEditor = nil then exit;
  SrcEdit:= TSourceEditor(ActiveEditor);
  if SrcEdit=nil then exit;
  CaretPos := SrcEdit.EditorComponent.CaretXY;
  FPDocEditor.UpdateFPDocEditor(SrcEdit.Filename,CaretPos);
end;

{ TSourceEditorManager }

function TSourceEditorManager.GetActiveSourceNotebook: TSourceNotebook;
begin
  Result := TSourceNotebook(inherited ActiveSourceWindow);
end;

function TSourceEditorManager.GetActiveSrcEditor: TSourceEditor;
begin
  Result := TSourceEditor(inherited ActiveEditor);
end;

function TSourceEditorManager.GetSourceEditorsByPage(WindowIndex,
  PageIndex: integer): TSourceEditor;
begin
  if SourceWindows[WindowIndex] <> nil then
    Result := SourceWindows[WindowIndex].FindSourceEditorWithPageIndex(PageIndex)
  else
    Result := nil;
end;

function TSourceEditorManager.GetSrcEditors(Index: integer): TSourceEditor;
begin
  Result := TSourceEditor(inherited SourceEditors[Index]);
end;

procedure TSourceEditorManager.SetActiveSourceNotebook(
  const AValue: TSourceNotebook);
begin
  inherited ActiveSourceWindow := AValue;
end;

function TSourceEditorManager.GetSourceNotebook(Index: integer
  ): TSourceNotebook;
begin
  Result := TSourceNotebook(inherited SourceWindows[Index]);
end;

procedure TSourceEditorManager.SetActiveSrcEditor(const AValue: TSourceEditor);
begin
  inherited ActiveEditor := AValue;
end;

function TSourceEditorManager.SourceWindowWithEditor(
  const AEditor: TSourceEditorInterface): TSourceNotebook;
begin
  Result := TSourceNotebook(inherited SourceWindowWithEditor(AEditor));
end;

function TSourceEditorManager.ActiveOrNewSourceWindow: TSourceNotebook;
begin
  Result := ActiveSourceWindow;
  if Result <> nil then exit;
  Result := CreateNewWindow(True);
  ActiveSourceWindow := Result;
end;

function TSourceEditorManager.NewSourceWindow: TSourceNotebook;
begin
  Result := CreateNewWindow(True);
  ActiveSourceWindow := Result;
end;

function TSourceEditorManager.SourceWindowWithPage(const APage: TPage
  ): TSourceNotebook;
var
  i: Integer;
begin
  Result := nil;
  for i := FSourceWindowList.Count-1 downto 0 do begin
    if TSourceNotebook(SourceWindows[i]).FNoteBook.PageList.IndexOf(APage) >= 0 then begin
      Result := SourceWindows[i];
      break;
    end;
  end;
end;

function TSourceEditorManager.SourceEditorCount: integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to SourceWindowCount - 1 do
    Result := Result + SourceWindows[i].Count;
end;


function TSourceEditorManager.GetActiveSE: TSourceEditor;
begin
  Result := TSourceEditor(ActiveEditor);
end;

function TSourceEditorManager.SourceEditorIntfWithFilename(
  const Filename: string): TSourceEditor;
begin
  Result := TSourceEditor(inherited SourceEditorIntfWithFilename(Filename));
end;

function TSourceEditorManager.FindSourceEditorWithEditorComponent(
  EditorComp: TComponent): TSourceEditor;
var
  i: Integer;
begin
  Result := nil;
  i := SourceWindowCount - 1;
  while i >= 0 do begin
    Result := SourceWindows[i].FindSourceEditorWithEditorComponent(EditorComp);
    if Result <> nil then break;
    dec(i);
  end;
end;

procedure TSourceEditorManager.NewEditorCreated(AEditor: TSourceEditor);
begin
  if FDefaultCompletionForm <> nil then
    FDefaultCompletionForm.AddEditor(AEditor.EditorComponent);
end;

procedure TSourceEditorManager.EditorRemoved(AEditor: TSourceEditor);
begin
  if FDefaultCompletionForm <> nil then
    FDefaultCompletionForm.RemoveEditor(AEditor.EditorComponent);
  if Assigned(OnEditorClosed) then
    OnEditorClosed(AEditor);
end;

procedure TSourceEditorManager.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation=opRemove then
  begin
    if AComponent is TSourceNotebook then
      RemoveWindow(TSourceNotebook(AComponent));
  end;
end;

procedure TSourceEditorManager.ClearErrorLines;
var
  i: Integer;
begin
  for i := FSourceWindowList.Count - 1 downto 0 do
    SourceWindows[i].ClearErrorLines;
end;

procedure TSourceEditorManager.ClearExecutionLines;
var
  i: Integer;
begin
  for i := FSourceWindowList.Count - 1 downto 0 do
    SourceWindows[i].ClearExecutionLines;
end;

procedure TSourceEditorManager.ClearExecutionMarks;
var
  i: Integer;
begin
  for i := FSourceWindowList.Count - 1 downto 0 do
    SourceWindows[i].ClearExecutionMarks;
end;

procedure TSourceEditorManager.FillExecutionMarks;
var
  i: Integer;
begin
  for i := FSourceWindowList.Count - 1 downto 0 do
    SourceWindows[i].GetActiveSE.FillExecutionMarks;
end;

procedure TSourceEditorManager.ReloadEditorOptions;
var
  i: Integer;
begin
  for i := FSourceWindowList.Count - 1 downto 0 do
    SourceWindows[i].ReloadEditorOptions;

  SourceCompletionTimer.Interval:=EditorOpts.AutoDelayInMSec;
  // reload code templates
  with CodeTemplateModul do begin
    if FileExistsUTF8(EditorOpts.CodeTemplateFilename) then
      AutoCompleteList.LoadFromFile(UTF8ToSys(EditorOpts.CodeTemplateFilename))
    else
      if FileExistsUTF8('lazarus.dci') then
        AutoCompleteList.LoadFromFile(UTF8ToSys('lazarus.dci'));
    IndentToTokenStart:=EditorOpts.CodeTemplateIndentToTokenStart;
  end;

end;

procedure TSourceEditorManager.FindClicked(Sender: TObject);
begin
  if ActiveEditor <> nil then ActiveEditor.StartFindAndReplace(false);
end;

procedure TSourceEditorManager.FindNextClicked(Sender: TObject);
begin
  if ActiveEditor <> nil then ActiveEditor.FindNextUTF8;
end;

procedure TSourceEditorManager.FindPreviousClicked(Sender: TObject);
begin
  if ActiveEditor <> nil then ActiveEditor.FindPrevious;
end;

procedure TSourceEditorManager.ReplaceClicked(Sender: TObject);
begin
  if ActiveEditor <> nil then ActiveEditor.StartFindAndReplace(true);
end;

procedure TSourceEditorManager.IncrementalFindClicked(Sender: TObject);
begin
  if ActiveSourceWindow <> nil then ActiveSourceWindow.BeginIncrementalFind;
end;

procedure TSourceEditorManager.GotoLineClicked(Sender: TObject);
begin
  if ActiveEditor <> nil then ActiveEditor.ShowGotoLineDialog;
end;

procedure TSourceEditorManager.JumpBackClicked(Sender: TObject);
begin
  if ActiveSourceWindow <> nil then HistoryJump(Sender,jhaBack);
end;

procedure TSourceEditorManager.JumpForwardClicked(Sender: TObject);
begin
  if ActiveSourceWindow <> nil then HistoryJump(Sender,jhaForward);
end;

procedure TSourceEditorManager.AddJumpPointClicked(Sender: TObject);
begin
  if Assigned(OnAddJumpPoint) and (ActiveEditor <> nil) then
    OnAddJumpPoint(ActiveEditor.EditorComponent.LogicalCaretXY,
      ActiveEditor.EditorComponent.TopLine, ActiveEditor, true);
end;

procedure TSourceEditorManager.DeleteLastJumpPointClicked(Sender: TObject);
begin
  if Assigned(OnDeleteLastJumpPoint) then
    OnDeleteLastJumpPoint(Sender);
end;

procedure TSourceEditorManager.ViewJumpHistoryClicked(Sender: TObject);
begin
  if Assigned(OnViewJumpHistory) then
    OnViewJumpHistory(Sender);
end;

procedure TSourceEditorManager.BookMarkSetFreeClicked(Sender: TObject);
begin
  if Assigned(OnSetBookmark) then
    OnSetBookmark(ActiveEditor, -1, False);
end;

procedure TSourceEditorManager.BookMarkToggleClicked(Sender: TObject);
begin
  if Assigned(OnSetBookmark) then
    OnSetBookmark(ActiveEditor, (Sender as TIDEMenuItem).SectionIndex, True);
end;

procedure TSourceEditorManager.BookMarkGotoClicked(Sender: TObject);
begin
  if Assigned(OnGotoBookmark) then
    OnGotoBookmark(ActiveEditor, (Sender as TIDEMenuItem).SectionIndex, False);
end;

procedure TSourceEditorManager.BookMarkNextClicked(Sender: TObject);
begin
  if Assigned(OnGotoBookmark) then
    OnGotoBookmark(ActiveEditor, -1, False);
end;

procedure TSourceEditorManager.BookMarkPrevClicked(Sender: TObject);
begin
  if Assigned(OnGotoBookmark) then
    OnGotoBookmark(ActiveEditor, -1, True);
end;

function TSourceEditorManager.MacroFuncCol(const s: string; const Data: PtrInt;
  var Abort: boolean): string;
begin
  if (ActiveEditor <> nil) then
    Result:=IntToStr(ActiveEditor.EditorComponent.CaretX)
  else
    Result:='';
end;

function TSourceEditorManager.MacroFuncRow(const s: string; const Data: PtrInt;
  var Abort: boolean): string;
begin
  if (ActiveEditor <> nil) then
    Result:=IntToStr(ActiveEditor.EditorComponent.CaretY)
  else
    Result:='';
end;

function TSourceEditorManager.MacroFuncEdFile(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  if (ActiveEditor <> nil) then
    Result := ActiveEditor.FileName
  else
    Result := '';
end;

function TSourceEditorManager.MacroFuncCurToken(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  if (ActiveEditor <> nil) then begin
    with ActiveEditor.EditorComponent do
      Result := GetWordAtRowCol(LogicalCaretXY)
  end else
    Result := '';
end;

function TSourceEditorManager.MacroFuncPrompt(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  Result:=s;
  Abort:=(ShowMacroPromptDialog(Result)<>mrOk);
end;

procedure TSourceEditorManager.InitMacros(AMacroList: TTransferMacroList);
begin
  AMacroList.Add(TTransferMacro.Create('Col','',
                 lisCursorColumnInCurrentEditor,@MacroFuncCol,[]));
  AMacroList.Add(TTransferMacro.Create('Row','',
                 lisCursorRowInCUrrentEditor,@MacroFuncRow,[]));
  AMacroList.Add(TTransferMacro.Create('CurToken','',
                 lisWordAtCursorInCurrentEditor,@MacroFuncCurToken,[]));
  AMacroList.Add(TTransferMacro.Create('EdFile','',
                 lisExpandedFilenameOfCurrentEditor,@MacroFuncEdFile,[]));
  AMacroList.Add(TTransferMacro.Create('Prompt','',
                 lisPromptForValue,@MacroFuncPrompt,[tmfInteractive]));
end;

procedure TSourceEditorManager.SetupShortCuts;

  function GetCommand(ACommand: Word): TIDECommand; inline;
  begin
    Result := IDECommandList.FindIDECommand(ACommand);
  end;

begin
  SrcEditMenuProcedureJump.Command:=GetCommand(ecFindProcedureDefinition);
  SrcEditMenuFindinFiles.Command:=GetCommand(ecFindInFiles);

  SrcEditMenuCut.Command:=GetCommand(ecCut);
  SrcEditMenuCopy.Command:=GetCommand(ecCopy);
  SrcEditMenuPaste.Command:=GetCommand(ecPaste);

  SrcEditMenuCompleteCode.Command:=GetCommand(ecCompleteCode);
  SrcEditMenuRenameIdentifier.Command:=GetCommand(ecRenameIdentifier);
  SrcEditMenuFindIdentifierReferences.Command:=GetCommand(ecFindIdentifierRefs);
  SrcEditMenuExtractProc.Command:=GetCommand(ecExtractProc);
  SrcEditMenuShowAbstractMethods.Command:=GetCommand(ecShowAbstractMethods);
  SrcEditMenuShowEmptyMethods.Command:=GetCommand(ecRemoveEmptyMethods);
  SrcEditMenuShowUnusedUnits.Command:=GetCommand(ecRemoveUnusedUnits);
  SrcEditMenuFindOverloads.Command:=GetCommand(ecFindOverloads);

  DebugBoss.SetupSourceMenuShortCuts;
end;

function TSourceEditorManager.FindUniquePageName(FileName: string;
  IgnoreEditor: TSourceEditor): string;
var
  I:integer;
  ShortName:string;

  function PageNameExists(const AName:string):boolean;
  var a:integer;
  begin
    Result:=false;
    for a := 0 to SourceEditorCount - 1 do begin
      if (SourceEditors[a] <> IgnoreEditor) and
         (not SourceEditors[a].IsSharedWith(IgnoreEditor)) and
         (AnsiCompareText(AName, SourceEditors[a].PageName) = 0)
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

procedure TSourceEditorManager.ShowFPDocEditor;
begin
  DoShowFPDocEditor;
  UpdateFPDocEditor;
end;

function TSourceEditorManager.SomethingModified: boolean;
var
  i: integer;
begin
  Result:=false;
  for i:=0 to SourceEditorCount - 1 do Result := Result or SourceEditors[i].Modified;
end;

procedure TSourceEditorManager.HideHint;
var
  i: Integer;
begin
  for i := 0 to SourceWindowCount - 1 do
    SourceWindows[i].HideHint;
end;

procedure TSourceEditorManager.LockAllEditorsInSourceChangeCache;
// lock all sourceeditors that are to be modified by the CodeToolBoss
var
  i: integer;
begin
  for i:=0 to SourceEditorCount - 1 do begin
    if CodeToolBoss.SourceChangeCache.BufferIsModified(SourceEditors[i].CodeBuffer)
    then begin
      with SourceEditors[i].EditorComponent do begin
        BeginUpdate;
        BeginUndoBlock;
      end;
    end;
  end;
end;

procedure TSourceEditorManager.UnlockAllEditorsInSourceChangeCache;
// unlock all sourceeditors that were modified by the CodeToolBoss
var
  i: integer;
begin
  for i:=0 to SourceEditorCount - 1 do begin
    if CodeToolBoss.SourceChangeCache.BufferIsModified(SourceEditors[i].CodeBuffer)
    then begin
      with SourceEditors[i].EditorComponent do begin
        EndUndoBlock;
        EndUpdate;
      end;
    end;
  end;
end;

procedure TSourceEditorManager.CloseFile(AEditor: TSourceEditorInterface);
var
  i, j: Integer;
begin
  i := SourceWindowCount - 1;
  while i >= 0 do begin
    j := SourceWindows[i].FindPageWithEditor(TSourceEditor(AEditor));
    if j >= 0 then begin
      SourceWindows[i].CloseFile(j);
      break;
    end;
    dec(i);
  end;
end;

procedure TSourceEditorManager.HistoryJump(Sender: TObject;
  CloseAction: TJumpHistoryAction);
var NewCaretXY: TPoint;
  NewTopLine: integer;
  NewEditor: TSourceEditor;
begin
  if Assigned(OnJumpToHistoryPoint) then begin
    NewCaretXY.X:=-1;
    NewEditor:=nil;
    OnJumpToHistoryPoint(NewCaretXY,NewTopLine,NewEditor,CloseAction);
    if NewEditor<>nil then begin
      ActiveEditor := NewEditor;
      ShowActiveWindowOnTop(True);
      with NewEditor.EditorComponent do begin
        TopLine:=NewTopLine;
        LogicalCaretXY:=NewCaretXY;
      end;
    end;
  end;
end;

procedure TSourceEditorManager.OnCodeTemplateTokenNotFound(Sender: TObject;
  AToken: string; AnEditor: TCustomSynEdit; var Index: integer);
var
  P:TPoint;
begin
  //writeln('TSourceNotebook.OnCodeTemplateTokenNotFound ',AToken,',',AnEditor.ReadOnly,',',DefaultCompletionForm.CurrentCompletionType=ctNone);
  if (AnEditor.ReadOnly=false) and
     (DefaultCompletionForm.CurrentCompletionType=ctNone)
  then begin
    DefaultCompletionForm.CurrentCompletionType:=ctTemplateCompletion;
    with AnEditor do begin
      P := Point(CaretXPix - length(AToken)*CharWidth,CaretYPix + LineHeight + 1);
      P.X:=Max(0,Min(P.X,ClientWidth-DefaultCompletionForm.Width));
      P := ClientToScreen(p);
    end;
    DefaultCompletionForm.Editor:=AnEditor;
    DefaultCompletionForm.Execute(AToken,P.X,P.Y);
  end;
end;

procedure TSourceEditorManager.OnCodeTemplateExecuteCompletion(
  ASynAutoComplete: TCustomSynAutoComplete; Index: integer);
var
  SrcEdit: TSourceEditorInterface;
  TemplateName: string;
  TemplateValue: string;
  TemplateComment: string;
  TemplateAttr: TStrings;
begin
  SrcEdit:=FindSourceEditorWithEditorComponent(ASynAutoComplete.Editor);
  if SrcEdit=nil then
    SrcEdit := ActiveEditor;
  //debugln('TSourceNotebook.OnCodeTemplateExecuteCompletion A ',dbgsName(SrcEdit),' ',dbgsName(ASynAutoComplete.Editor));

  TemplateName:=ASynAutoComplete.Completions[Index];
  TemplateValue:=ASynAutoComplete.CompletionValues[Index];
  TemplateComment:=ASynAutoComplete.CompletionComments[Index];
  TemplateAttr:=ASynAutoComplete.CompletionAttributes[Index];
  ExecuteCodeTemplate(SrcEdit,TemplateName,TemplateValue,TemplateComment,
                      ASynAutoComplete.EndOfTokenChr,TemplateAttr,
                      ASynAutoComplete.IndentToTokenStart);
end;

procedure TSourceEditorManager.OnWordCompletionGetSource(var Source: TStrings;
  SourceIndex: integer);
var TempEditor: TSourceEditor;
  i:integer;
begin
  TempEditor:=GetActiveSE;
  if SourceIndex=0 then begin
    Source:=TempEditor.EditorComponent.Lines;
  end else begin
    i:=0;
    while (i < SourceEditorCount) do begin
      if SourceEditors[i] <> TempEditor then dec(SourceIndex);
      if SourceIndex = 0 then begin
        Source := SourceEditors[i].EditorComponent.Lines;
        exit;
      end;
      inc(i);
    end;
    Source := nil;
  end;
end;

procedure TSourceEditorManager.OnSourceCompletionTimer(Sender: TObject);

  function CheckStartIdentCompletion: boolean;
  var
    Line: String;
    LogCaret: TPoint;
    p: Integer;
    InStringConstant: Boolean;
    SrcEdit: TSourceEditor;
    Token: string;
    Attri: TSynHighlighterAttributes;
  begin
    Result := false;
    SrcEdit := ActiveEditor;
    if SrcEdit = nil then exit;
    Line := SrcEdit.FEditor.LineText;
    LogCaret := SrcEdit.FEditor.LogicalCaretXY;
    //DebugLn(['CheckStartIdentCompletion Line="',Line,'" LogCaret=',dbgs(LogCaret)]);

    // check if last character is a point
    if (Line='') or (LogCaret.X<=1) or (LogCaret.X-1>length(Line))
    or (Line[LogCaret.X-1]<>'.') then
      exit;

    // check if range operator '..'
    if (LogCaret.X>2) and (Line[LogCaret.X-2]='.') then
      exit; // this is a double point ..

    // check if in a string constant
    p:=1;
    InStringConstant:=false;
    while (p<=LogCaret.X) and (p<=length(Line)) do begin
      if Line[p]='''' then
        InStringConstant:=not InStringConstant;
      inc(p);
    end;
    if InStringConstant then exit;

    // check if in a comment
    Token:='';
    Attri:=nil;
    dec(LogCaret.X);
    if SrcEdit.EditorComponent.GetHighlighterAttriAtRowCol(LogCaret,Token,Attri)
    and (Attri<>nil) and (Attri.Name=SYNS_AttrComment) then
    begin
      exit;
    end;

    // invoke identifier completion
    SrcEdit.StartIdentCompletionBox(false);
    Result:=true;
  end;

  function CheckTemplateCompletion: boolean;
  begin
    Result:=false;
    // execute context sensitive templates
    //FCodeTemplateModul.ExecuteCompletion(Value,GetActiveSE.EditorComponent);
  end;

var
  TempEditor: TSourceEditor;
begin
  SourceCompletionTimer.Enabled:=false;
  SourceCompletionTimer.AutoEnabled:=false;
  TempEditor := ActiveEditor;
  if (TempEditor <> nil) and TempEditor.EditorComponent.Focused and
     (ComparePoints(TempEditor.EditorComponent.CaretXY, SourceCompletionCaretXY) = 0)
  then begin
    if CheckStartIdentCompletion then begin
    end
    else if CheckTemplateCompletion then begin
    end;
  end;
end;

function TSourceEditorManager.OnSourceMarksGetSourceEditorID(
  ASrcEdit: TSourceEditorInterface): TObject;
begin
  Result := TSourceEditor(ASrcEdit).FSharedValues;
end;

function TSourceEditorManager.OnSourceMarksGetFilename(ASourceEditor: TObject
  ): string;
begin
  if (ASourceEditor = nil) or (not (ASourceEditor is TSourceEditor)) then
    RaiseException('TSourceNotebook.OnSourceMarksGetFilename');
  Result := TSourceEditor(ASourceEditor).Filename;
end;

procedure TSourceEditorManager.OnSourceMarksAction(AMark: TSourceMark;
  AAction: TMarksAction);
var
  Editor: TSourceEditor;
  i: Integer;
begin
  Editor := TSourceEditor(AMark.SourceEditor);
  if Editor = nil then
    Exit;

  if AAction = maAdded then begin
    for i := 0 to Editor.FSharedValues.SharedEditorCount - 1 do
      if not AMark.HasSourceEditor(Editor.FSharedValues.SharedEditors[i]) then
        AMark.AddSourceEditor(Editor.FSharedValues.SharedEditors[i]);
  end;

  if ( AMark.IsBreakPoint and (Editor.FSharedValues.ExecutionMark <> nil) and
       (AMark.Line = Editor.ExecutionLine)
     ) or (AMark = Editor.FSharedValues.ExecutionMark)
  then
    Editor.UpdateExecutionSourceMark;
end;

function TSourceEditorManager.GotoDialog: TfrmGoto;
begin
  if FGotoDialog=nil then
    FGotoDialog := TfrmGoto.Create(self);
  Result := FGotoDialog;
end;

constructor TSourceEditorManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FDefaultCompletionForm := nil;

  // word completion
  if aWordCompletion=nil then begin
    aWordCompletion:=TWordCompletion.Create;
    with AWordCompletion do begin
      WordBufferCapacity:=100;
      OnGetSource:=@OnWordCompletionGetSource;
    end;
  end;

  // identifier completion
  SourceCompletionTimer := TIdleTimer.Create(Self);
  with SourceCompletionTimer do begin
    AutoEnabled := False;
    Enabled := false;
    Interval := EditorOpts.AutoDelayInMSec;
    OnTimer := @OnSourceCompletionTimer;
  end;

  // marks
  SourceEditorMarks:=TSourceMarks.Create(Self);
  SourceEditorMarks.OnGetSourceEditorID := @OnSourceMarksGetSourceEditorID;
  SourceEditorMarks.OnGetFilename:=@OnSourceMarksGetFilename;
  SourceEditorMarks.OnAction:=@OnSourceMarksAction;

  // code templates
  FCodeTemplateModul:=TSynEditAutoComplete.Create(Self);
  with FCodeTemplateModul do begin
    if FileExistsUTF8(EditorOpts.CodeTemplateFilename) then
      AutoCompleteList.LoadFromFile(UTF8ToSys(EditorOpts.CodeTemplateFilename))
    else
      if FileExistsUTF8('lazarus.dci') then
        AutoCompleteList.LoadFromFile(UTF8ToSys('lazarus.dci'));
    IndentToTokenStart := EditorOpts.CodeTemplateIndentToTokenStart;
    OnTokenNotFound := @OnCodeTemplateTokenNotFound;
    OnExecuteCompletion := @OnCodeTemplateExecuteCompletion;
    EndOfTokenChr:=' ()[]{},.;:"+-*^@$\<>=''';
  end;

end;

destructor TSourceEditorManager.Destroy;
begin
  inherited Destroy;
end;

function SortSourceWindows(SrcWin1, SrcWin2: TSourceNotebook): Integer;
begin
  Result := AnsiStrComp(PChar(SrcWin1.Caption), PChar(SrcWin2.Caption));
end;

function TSourceEditorManager.CreateNewWindow(Activate: Boolean= False): TSourceNotebook;
var
  i: Integer;
begin
  Result := TSourceNotebook.Create(Self);
  Result.FreeNotification(self);
  Result.OnActivate := OnWindowActivate;
  for i := 1 to FUpdateLock do
    Result.IncUpdateLock;
  FSourceWindowList.Add(Result);
  FSourceWindowList.Sort(TListSortCompare(@SortSourceWindows));
  if Activate then begin
    ActiveSourceWindow := Result;
    ShowActiveWindowOnTop(False);
  end;
  FChangeNotifyLists[semWindowCreate].CallNotifyEvents(Result);
end;

procedure TSourceEditorManager.RemoveWindow(AWindow: TSourceNotebook);
var
  i: Integer;
begin
  if FSourceWindowList = nil then exit;
  i := FSourceWindowList.IndexOf(AWindow);
  FSourceWindowList.Remove(AWindow);
  if SourceWindowCount = 0 then
    ActiveSourceWindow := nil
  else if ActiveSourceWindow = AWindow then
    ActiveSourceWindow := SourceWindows[Max(0, Min(i, SourceWindowCount-1))];
  if i >= 0 then
    FChangeNotifyLists[semWindowDestroy].CallNotifyEvents(AWindow);
end;

initialization
  InternalInit;
  {$I ../images/bookmark.lrs}

finalization
  InternalFinal;

end.

