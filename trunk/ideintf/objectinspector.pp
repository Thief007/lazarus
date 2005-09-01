{ $Id$}
{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Mattias Gaertner

  Abstract:
   This unit defines the TObjectInspector.
   It uses TOIPropertyGrid and TOIPropertyGridRow which are also defined in this
   unit. The object inspector uses property editors (see TPropertyEditor) to
   display and control properties, thus the object inspector is merely an
   object viewer than an editor. The property editors do the real work.


  ToDo:
   - backgroundcolor=clNone
   - replace pair splitter with splitter
   - Define Init values
   - Set to init value
   - add favorites page
}
unit ObjectInspector;

{$MODE OBJFPC}{$H+}

{off $DEFINE DoNotCatchOIExceptions}

interface

uses
  Forms, SysUtils, Buttons, Classes, Graphics, GraphType, StdCtrls, LCLType,
  LCLIntf, LCLProc, Controls, ComCtrls, ExtCtrls, TypInfo, Messages,
  LResources, PairSplitter, ConfigStorage, Menus, Dialogs, ObjInspStrConsts,
  PropEdits, GraphPropEdits, ListViewPropEdit, ImageListEditor,
  ComponentTreeView, ComponentEditors;

const
  OIOptionsFileVersion = 2;

type
  EObjectInspectorException = class(Exception);
  
  TObjectInspector = class;

  // standard ObjectInspector pages
  TObjectInspectorPage = (
    oipgpProperties,
    oipgpEvents,
    oipgpFavourite
    );
  TObjectInspectorPages = set of TObjectInspectorPage;
  
  
  { TOIFavouriteProperty
    BaseClassName }
  TOIFavouriteProperty = class
  public
    BaseClass: TPersistentClass;
    BaseClassname: string;
    PropertyName: string;
    Include: boolean; // include or exclude
    constructor Create(ABaseClass: TPersistentClass;
                       const APropertyName: string; TheInclude: boolean);
    function Constrains(AnItem: TOIFavouriteProperty): boolean;
    function IsFavourite(AClass: TPersistentClass;
                         const APropertyName: string): boolean;
    function Compare(AFavourite: TOIFavouriteProperty): integer;
    procedure SaveToConfig(ConfigStore: TConfigStorage; const Path: string);
    procedure Assign(Src: TOIFavouriteProperty); virtual;
    function CreateCopy: TOIFavouriteProperty;
    function DebugReportAsString: string;
  end;

  { TOIFavouriteProperties }

  TOIFavouriteProperties = class
  private
    FItems: TList;
    FModified: Boolean;
    FSorted: Boolean;
    FDoublesDeleted: Boolean;
  protected
    function GetCount: integer; virtual;
    function GetItems(Index: integer): TOIFavouriteProperty; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure Assign(Src: TOIFavouriteProperties); virtual;
    function CreateCopy: TOIFavouriteProperties;
    function Contains(AnItem: TOIFavouriteProperty): Boolean; virtual;
    procedure Add(NewItem: TOIFavouriteProperty); virtual;
    procedure AddNew(NewItem: TOIFavouriteProperty);
    procedure Remove(AnItem: TOIFavouriteProperty); virtual;
    procedure DeleteConstraints(AnItem: TOIFavouriteProperty); virtual;
    function IsFavourite(AClass: TPersistentClass;
                         const PropertyName: string): boolean;
    function AreFavourites(Selection: TPersistentSelectionList;
                           const PropertyName: string): boolean;
    procedure LoadFromConfig(ConfigStore: TConfigStorage; const Path: string);
    procedure SaveToConfig(ConfigStore: TConfigStorage; const Path: string);
    procedure MergeConfig(ConfigStore: TConfigStorage; const Path: string);
    procedure SaveNewItemsToConfig(ConfigStore: TConfigStorage;
                    const Path: string; BaseFavourites: TOIFavouriteProperties);
    procedure Sort; virtual;
    procedure DeleteDoubles; virtual;
    function IsEqual(TheFavourites: TOIFavouriteProperties): boolean;
    function GetSubtractList(FavouritesToSubtract: TOIFavouriteProperties): TList;
    procedure WriteDebugReport;
  public
    property Items[Index: integer]: TOIFavouriteProperty read GetItems; default;
    property Count: integer read GetCount;
    property Modified: Boolean read FModified write FModified;
    property Sorted: Boolean read FSorted;
    property DoublesDeleted: boolean read FDoublesDeleted;
  end;
  TOIFavouritePropertiesClass = class of TOIFavouriteProperties;


  { TOIOptions }

  TOIOptions = class
  private
    FComponentTreeHeight: integer;
    FConfigStore: TConfigStorage;
    FDefaultItemHeight: integer;
    FShowComponentTree: boolean;

    FSaveBounds: boolean;
    FLeft: integer;
    FTop: integer;
    FWidth: integer;
    FHeight: integer;
    FGridSplitterX: array[TObjectInspectorPage] of integer;

    FPropertyNameColor: TColor;
    FDefaultValueColor: TColor;
    FSubPropertiesColor: TColor;
    FValueColor: TColor;
    FReferencesColor: TColor;
    FGridBackgroundColor: TColor;
    FShowHints: boolean;
    function FPropertyGridSplitterX(Page: TObjectInspectorPage): integer;
    procedure FPropertyGridSplitterX(Page: TObjectInspectorPage;
      const AValue: integer);
  public
    constructor Create;
    function Load: boolean;
    function Save: boolean;
    procedure Assign(AnObjInspector: TObjectInspector);
    procedure AssignTo(AnObjInspector: TObjectInspector);
  public
    property ConfigStore: TConfigStorage read FConfigStore write FConfigStore;

    property SaveBounds:boolean read FSaveBounds write FSaveBounds;
    property Left:integer read FLeft write FLeft;
    property Top:integer read FTop write FTop;
    property Width:integer read FWidth write FWidth;
    property Height:integer read FHeight write FHeight;
    property GridSplitterX[Page: TObjectInspectorPage]:integer
                       read FPropertyGridSplitterX write FPropertyGridSplitterX;
    property DefaultItemHeight: integer read FDefaultItemHeight
                                        write FDefaultItemHeight;
    property ShowComponentTree: boolean read FShowComponentTree
                                        write FShowComponentTree;
    property ComponentTreeHeight: integer read FComponentTreeHeight
                                          write FComponentTreeHeight;

    property GridBackgroundColor: TColor read FGridBackgroundColor
                                         write FGridBackgroundColor;
    property SubPropertiesColor: TColor read FSubPropertiesColor
                                         write FSubPropertiesColor;
    property ReferencesColor: TColor read FReferencesColor
                                         write FReferencesColor;
    property ValueColor: TColor read FValueColor
                                         write FValueColor;
    property DefaultValueColor: TColor read FDefaultValueColor
                                         write FDefaultValueColor;
    property PropertyNameColor: TColor read FPropertyNameColor
                                         write FPropertyNameColor;
    property ShowHints: boolean read FShowHints
                                write FShowHints;
  end;

  TOICustomPropertyGrid = class;


  { TOIPropertyGridRow }

  TOIPropertyGridRow = class
  private
    FTop:integer;
    FHeight:integer;
    FLvl:integer;
    FName:string;
    FExpanded: boolean;
    FTree:TOICustomPropertyGrid;
    FChildCount:integer;
    FPriorBrother,
    FFirstChild,
    FLastChild,
    FNextBrother,
    FParent:TOIPropertyGridRow;
    FEditor: TPropertyEditor;
    procedure GetLvl;
  public
    constructor Create(PropertyTree:TOICustomPropertyGrid;
       PropEditor:TPropertyEditor; ParentNode:TOIPropertyGridRow);
    destructor Destroy; override;
    function ConsistencyCheck: integer;
    function HasChild(Row: TOIPropertyGridRow): boolean;
  public
    Index:integer;
    LastPaintedValue:string;
    function GetBottom:integer;
    function IsReadOnly: boolean;
    function IsDisabled: boolean;
    procedure MeasureHeight(ACanvas: TCanvas);
  public
    property Editor:TPropertyEditor read FEditor;
    property Top:integer read FTop write FTop;
    property Height:integer read FHeight write FHeight;
    property Bottom: integer read GetBottom;
    property Lvl:integer read FLvl;
    property Name: string read FName;
    property Expanded:boolean read FExpanded;
    property Tree:TOICustomPropertyGrid read FTree;
    property Parent:TOIPropertyGridRow read FParent;
    property ChildCount:integer read FChildCount;
    property FirstChild:TOIPropertyGridRow read FFirstChild;
    property LastChild:TOIPropertyGridRow read FFirstChild;
    property NextBrother:TOIPropertyGridRow read FNextBrother;
    property PriorBrother:TOIPropertyGridRow read FPriorBrother;
  end;

  //----------------------------------------------------------------------------
  TOIPropertyGridState = (pgsChangingItemIndex, pgsApplyingValue,
    pgsUpdatingEditControl);
  TOIPropertyGridStates = set of TOIPropertyGridState;
  
  { TOICustomPropertyGrid }
  
  TOICustomPropertyGridColumn = (
    oipgcName,
    oipgcValue
  );

  TOICustomPropertyGrid = class(TCustomControl)
  private
    FBackgroundColor:TColor;
    FColumn: TOICustomPropertyGridColumn;
    FReferencesColor: TColor;
    FSubPropertiesColor: TColor;
    FChangeStep: integer;
    FCurrentButton: TWinControl; // nil or ValueButton
    FCurrentEdit: TWinControl;  // nil or ValueEdit or ValueComboBox
    FCurrentEditorLookupRoot: TPersistent;
    FDefaultItemHeight:integer;
    FDragging: boolean;
    FExpandedProperties: TStringList;
    FExpandingRow: TOIPropertyGridRow;
    FFavourites: TOIFavouriteProperties;
    FFilter: TTypeKinds;
    FIndent: integer;
    FItemIndex: integer;
    FNameFont, FDefaultValueFont, FValueFont: TFont;
    FNewComboBoxItems: TStringList;
    FOnModified: TNotifyEvent;
    FPreferredSplitterX: integer; // best splitter position
    FPropertyEditorHook: TPropertyEditorHook;
    FRows: TList;
    FSelection: TPersistentSelectionList;
    FSplitterX: integer; // current splitter position
    FStates: TOIPropertyGridStates;
    FTopY: integer;

    // hint stuff
    FHintTimer: TTimer;
    FHintWindow: THintWindow;
    Procedure HintTimer(Sender: TObject);
    Procedure ResetHintTimer;
    procedure OnUserInput(Sender: TObject; Msg: Cardinal);

    procedure IncreaseChangeStep;

    function GetRow(Index:integer):TOIPropertyGridRow;
    function GetRowCount:integer;
    procedure ClearRows;
    function GetCurrentEditValue: string;
    procedure SetColumn(const AValue: TOICustomPropertyGridColumn);
    procedure SetCurrentEditValue(const NewValue: string);
    procedure SetFavourites(const AValue: TOIFavouriteProperties);
    procedure SetItemIndex(NewIndex:integer);

    procedure SetItemsTops;
    procedure AlignEditComponents;
    procedure EndDragSplitter;
    procedure SetSplitterX(const NewValue:integer);
    procedure SetTopY(const NewValue:integer);

    function GetPropNameColor(ARow:TOIPropertyGridRow):TColor;
    function GetTreeIconX(Index:integer):integer;
    function RowRect(ARow:integer):TRect;
    procedure PaintRow(ARow:integer);
    procedure DoPaint(PaintOnlyChangedValues:boolean);

    procedure SetSelection(const ASelection:TPersistentSelectionList);
    procedure SetPropertyEditorHook(NewPropertyEditorHook:TPropertyEditorHook);

    procedure AddPropertyEditor(PropEditor: TPropertyEditor);
    procedure AddStringToComboBox(const s: string);
    procedure ExpandRow(Index: integer);
    procedure ShrinkRow(Index: integer);
    procedure AddSubEditor(PropEditor: TPropertyEditor);

    procedure SetRowValue;
    procedure DoCallEdit;
    procedure RefreshValueEdit;
    Procedure ValueEditDblClick(Sender : TObject);
    procedure ValueEditMouseDown(Sender: TObject; Button:TMouseButton;
      Shift: TShiftState; X,Y:integer);
    procedure ValueEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ValueEditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ValueEditExit(Sender: TObject);
    procedure ValueEditChange(Sender: TObject);
    procedure ValueComboBoxExit(Sender: TObject);
    procedure ValueComboBoxChange(Sender: TObject);
    procedure ValueComboBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ValueComboBoxKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ValueComboBoxCloseUp(Sender: TObject);
    procedure ValueComboBoxDropDown(Sender: TObject);
    procedure ValueButtonClick(Sender: TObject);
    procedure ValueComboBoxDrawItem(Control: TWinControl; Index: Integer;
          ARect: TRect; State: TOwnerDrawState);

    procedure WMVScroll(var Msg: TWMScroll); message WM_VSCROLL;
    procedure SetBackgroundColor(const AValue: TColor);
    procedure SetReferences(const AValue: TColor);
    procedure SetSubPropertiesColor(const AValue: TColor);
    procedure UpdateScrollBar;
    procedure FillComboboxItems;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;

    procedure MouseDown(Button:TMouseButton; Shift:TShiftState; X,Y:integer); override;
    procedure MouseMove(Shift:TShiftState; X,Y:integer);  override;
    procedure MouseUp(Button:TMouseButton; Shift:TShiftState; X,Y:integer); override;
    
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure HandleStandardKeys(var Key: Word; Shift: TShiftState); virtual;
    procedure HandleKeyUp(var Key: Word; Shift: TShiftState); virtual;
    procedure DoTabKey; virtual;

    procedure EraseBackground(DC: HDC); override;
    
    procedure DoSetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
  public
    ValueEdit:TEdit;
    ValueComboBox:TComboBox;
    ValueButton:TButton;

    constructor Create(TheOwner: TComponent); override;
    constructor CreateWithParams(AnOwner: TComponent;
                                 APropertyEditorHook: TPropertyEditorHook;
                                 TypeFilter: TTypeKinds;
                                 DefItemHeight: integer);
    destructor Destroy;  override;
    function CanEditRowValue: boolean;
    procedure SaveChanges;
    function ConsistencyCheck: integer;
    function GetActiveRow: TOIPropertyGridRow;
    function GetHintTypeAt(RowIndex: integer; X: integer): TPropEditHint;

    function GetRowByPath(const PropPath: string): TOIPropertyGridRow;
    function GridHeight: integer;
    function MouseToIndex(y: integer; MustExist: boolean):integer;
    function PropertyPath(Index: integer):string;
    function TopMax: integer;
    procedure BuildPropertyList;
    procedure Clear;
    procedure Paint;  override;
    procedure PropEditLookupRootChange;
    procedure RefreshPropertyValues;
    procedure SetBounds(aLeft, aTop, aWidth, aHeight: integer); override;
    procedure SetCurrentRowValue(const NewValue: string);
    procedure SetItemIndexAndFocus(NewItemIndex: integer);
  public
    property BackgroundColor: TColor read FBackgroundColor
                                     write SetBackgroundColor default clBtnFace;
    property ReferencesColor: TColor read FReferencesColor
                                     write SetReferences default clMaroon;
    property SubPropertiesColor: TColor read FSubPropertiesColor
                                     write SetSubPropertiesColor default clGreen;
    property BorderStyle default bsSingle;
    property Column: TOICustomPropertyGridColumn read FColumn write SetColumn;
    property CurrentEditValue: string read GetCurrentEditValue
                                      write SetCurrentEditValue;
    property DefaultItemHeight:integer read FDefaultItemHeight
                                       write FDefaultItemHeight default 25;
    property DefaultValueFont: TFont read FDefaultValueFont write FDefaultValueFont;
    property ExpandedProperties: TStringList read FExpandedProperties
                                            write FExpandedProperties;
    property Indent: integer read FIndent write FIndent default 9;
    property ItemIndex: integer read FItemIndex write SetItemIndex;
    property NameFont: TFont read FNameFont write FNameFont;
    property OnModified: TNotifyEvent read FOnModified write FOnModified;
    property PrefferedSplitterX: integer read FPreferredSplitterX
                                         write FPreferredSplitterX default 100;
    property PropertyEditorHook: TPropertyEditorHook read FPropertyEditorHook
                                                    write SetPropertyEditorHook;
    property RowCount: integer read GetRowCount;
    property Rows[Index: integer]:TOIPropertyGridRow read GetRow;
    property Selection: TPersistentSelectionList read FSelection
                                                 write SetSelection;
    property SplitterX: integer read FSplitterX write SetSplitterX default 100;
    property TopY: integer read FTopY write SetTopY default 0;
    property ValueFont: TFont read FValueFont write FValueFont;
    property Favourites: TOIFavouriteProperties read FFavourites
                                                write SetFavourites;
  end;
  
  
  { TOIPropertyGrid }
  
  TOIPropertyGrid = class(TOICustomPropertyGrid)
  published
    property Align;
    property Anchors;
    property BackgroundColor;
    property BorderStyle;
    property Constraints;
    property DefaultItemHeight;
    property DefaultValueFont;
    property Indent;
    property NameFont;
    property OnChangeBounds;
    property OnClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnModified;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property PopupMenu;
    property PrefferedSplitterX;
    property SplitterX;
    property Tabstop;
    property ValueFont;
    property Visible;
  end;
  

  { TCustomPropertiesGrid }

  TCustomPropertiesGrid = class(TOICustomPropertyGrid)
  private
    FAutoFreeHook: boolean;
    FSaveOnChangeTIObject: boolean;
    function GetTIObject: TPersistent;
    procedure SetAutoFreeHook(const AValue: boolean);
    procedure SetTIObject(const AValue: TPersistent);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property TIObject: TPersistent read GetTIObject write SetTIObject;
    property AutoFreeHook: boolean read FAutoFreeHook write SetAutoFreeHook;
    property SaveOnChangeTIObject: boolean read FSaveOnChangeTIObject
                                           write FSaveOnChangeTIObject
                                           default true;
  end;


  //============================================================================
  
  
  { TObjectInspector }
  
  TOnAddAvailablePersistent = procedure(APersistent: TPersistent;
    var Allowed: boolean) of object;

  TOIFlag = (
    oifRebuildPropListsNeeded
    );
  TOIFlags = set of TOIFlag;
  
  { TObjectInspector }

  TObjectInspector = class (TForm)
    AvailPersistentComboBox: TComboBox;
    PairSplitter1: TPairSplitter;
    ComponentTree: TComponentTreeView;
    NoteBook: TNoteBook;
    PropertyGrid: TOICustomPropertyGrid;
    EventGrid: TOICustomPropertyGrid;
    FavouriteGrid: TOICustomPropertyGrid;
    StatusBar: TStatusBar;
    MainPopupMenu: TPopupMenu;
    SetDefaultPopupMenuItem: TMenuItem;
    AddToFavoritesPopupMenuItem: TMenuItem;
    RemoveFromFavoritesPopupMenuItem: TMenuItem;
    UndoPropertyPopupMenuItem: TMenuItem;
    CutPopupmenuItem: TMenuItem;
    CopyPopupmenuItem: TMenuItem;
    PastePopupmenuItem: TMenuItem;
    DeletePopupmenuItem: TMenuItem;
    OptionsSeparatorMenuItem2: TMenuItem;
    ShowHintsPopupMenuItem: TMenuItem;
    ShowComponentTreePopupMenuItem: TMenuItem;
    ShowOptionsPopupMenuItem: TMenuItem;
    procedure AvailComboBoxCloseUp(Sender: TObject);
    procedure ComponentTreeSelectionChanged(Sender: TObject);
    procedure ObjectInspectorResize(Sender: TObject);
    procedure OnGriddKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnSetDefaultPopupmenuItemClick(Sender: TObject);
    procedure OnAddToFavoritesPopupmenuItemClick(Sender: TObject);
    procedure OnRemoveFromFavoritesPopupmenuItemClick(Sender: TObject);
    procedure OnUndoPopupmenuItemClick(Sender: TObject);
    procedure OnCutPopupmenuItemClick(Sender: TObject);
    procedure OnCopyPopupmenuItemClick(Sender: TObject);
    procedure OnPastePopupmenuItemClick(Sender: TObject);
    procedure OnDeletePopupmenuItemClick(Sender: TObject);
    procedure OnShowHintPopupMenuItemClick(Sender: TObject);
    procedure OnShowOptionsPopupMenuItemClick(Sender: TObject);
    procedure OnShowComponentTreePopupMenuItemClick(Sender: TObject);
    procedure OnMainPopupMenuPopup(Sender: TObject);
  private
    FFavourites: TOIFavouriteProperties;
    FOnAddToFavourites: TNotifyEvent;
    FOnRemainingKeyUp: TKeyEvent;
    FOnRemoveFromFavourites: TNotifyEvent;
    FSelection: TPersistentSelectionList;
    FComponentTreeHeight: integer;
    FDefaultItemHeight: integer;
    FFlags: TOIFlags;
    FOnShowOptions: TNotifyEvent;
    FPropertyEditorHook:TPropertyEditorHook;
    FOnAddAvailablePersistent: TOnAddAvailablePersistent;
    FOnSelectPersistentsInOI: TNotifyEvent;
    FOnModified: TNotifyEvent;
    FShowComponentTree: boolean;
    FShowFavouritePage: boolean;
    FUpdateLock: integer;
    FUpdatingAvailComboBox: boolean;
    FUsePairSplitter: boolean;
    function GetGridControl(Page: TObjectInspectorPage): TOICustomPropertyGrid;
    procedure SetFavourites(const AValue: TOIFavouriteProperties);
    procedure SetShowFavouritePage(const AValue: boolean);
    procedure SetComponentTreeHeight(const AValue: integer);
    procedure SetDefaultItemHeight(const AValue: integer);
    procedure SetOnShowOptions(const AValue: TNotifyEvent);
    procedure SetPropertyEditorHook(NewValue: TPropertyEditorHook);
    procedure SetSelection(const ASelection: TPersistentSelectionList);
    procedure SetShowComponentTree(const AValue: boolean);
    procedure SetUsePairSplitter(const AValue: boolean);
  protected
    function PersistentToString(APersistent: TPersistent): string;
    procedure AddPersistentToList(APersistent: TPersistent; List: TStrings);
    procedure HookLookupRootChange;
    procedure OnGridModified(Sender: TObject);
    procedure SetAvailComboBoxText;
    procedure HookGetSelection(const ASelection: TPersistentSelectionList);
    procedure HookSetSelection(const ASelection: TPersistentSelectionList);
    procedure CreatePairSplitter;
    procedure DestroyNoteBook;
    procedure CreateNoteBook;
    procedure CreateFavouritePage;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshSelection;
    procedure RefreshPropertyValues;
    procedure RebuildPropertyLists;
    procedure FillPersistentComboBox;
    procedure BeginUpdate;
    procedure EndUpdate;
    function GetActivePropertyGrid: TOICustomPropertyGrid;
    function GetActivePropertyRow: TOIPropertyGridRow;
    function GetCurRowDefaultValue(var DefaultStr: string): boolean;
    procedure HookRefreshPropertyValues;
  public
    property DefaultItemHeight: integer read FDefaultItemHeight
                                        write SetDefaultItemHeight;
    property Selection: TPersistentSelectionList
                                        read FSelection write SetSelection;
    property OnAddAvailPersistent: TOnAddAvailablePersistent
                 read FOnAddAvailablePersistent write FOnAddAvailablePersistent;
    property OnSelectPersistentsInOI: TNotifyEvent
                   read FOnSelectPersistentsInOI write FOnSelectPersistentsInOI;
    property PropertyEditorHook: TPropertyEditorHook
                           read FPropertyEditorHook write SetPropertyEditorHook;
    property OnModified: TNotifyEvent read FOnModified write FOnModified;
    property OnShowOptions: TNotifyEvent read FOnShowOptions
                                         write SetOnShowOptions;
    property OnRemainingKeyUp: TKeyEvent read FOnRemainingKeyUp
                                         write FOnRemainingKeyUp;
    property ShowComponentTree: boolean read FShowComponentTree
                                        write SetShowComponentTree;
    property ComponentTreeHeight: integer read FComponentTreeHeight
                                          write SetComponentTreeHeight;
    property UsePairSplitter: boolean read FUsePairSplitter
                                      write SetUsePairSplitter;
    property ShowFavouritePage: boolean read FShowFavouritePage
                                        write SetShowFavouritePage;
    property GridControl[Page: TObjectInspectorPage]: TOICustomPropertyGrid
                                                            read GetGridControl;
    property Favourites: TOIFavouriteProperties read FFavourites write SetFavourites;
    property OnAddToFavourites: TNotifyEvent read FOnAddToFavourites
                                             write FOnAddToFavourites;
    property OnRemoveFromFavourites: TNotifyEvent read FOnRemoveFromFavourites
                                                  write FOnRemoveFromFavourites;
  end;

const
  DefaultObjectInspectorName: string = 'ObjectInspector';
  
  DefaultOIPageNames: array[TObjectInspectorPage] of shortstring = (
    'PropertyPage',
    'EventPage',
    'FavouritePage'
    );
  DefaultOIGridNames: array[TObjectInspectorPage] of shortstring = (
    'PropertyGrid',
    'EventGrid',
    'FavouriteGrid'
    );


function CompareOIFavouriteProperties(Data1, Data2: Pointer): integer;

//******************************************************************************


implementation

const
  ScrollBarWidth=0;

function SortGridRows(Item1, Item2 : pointer) : integer; 
begin
  Result:= AnsiCompareText(TOIPropertyGridRow(Item1).Name, TOIPropertyGridRow(Item2).Name);
end;

function CompareOIFavouriteProperties(Data1, Data2: Pointer): integer;
var
  Favourite1: TOIFavouriteProperty;
  Favourite2: TOIFavouriteProperty;
begin
  Favourite1:=TOIFavouriteProperty(Data1);
  Favourite2:=TOIFavouriteProperty(Data2);
  Result:=Favourite1.Compare(Favourite2)
end;


{ TOICustomPropertyGrid }

constructor TOICustomPropertyGrid.CreateWithParams(AnOwner:TComponent;
  APropertyEditorHook:TPropertyEditorHook; TypeFilter:TTypeKinds;
  DefItemHeight: integer);
begin
  inherited Create(AnOwner);
  FSelection:=TPersistentSelectionList.Create;
  FPropertyEditorHook:=APropertyEditorHook;
  FFilter:=TypeFilter;
  FItemIndex:=-1;
  FStates:=[];
  FRows:=TList.Create;
  FExpandingRow:=nil;
  FDragging:=false;
  FExpandedProperties:=TStringList.Create;
  FCurrentEdit:=nil;
  FCurrentButton:=nil;

  // visible values
  FTopY:=0;
  FSplitterX:=100;
  FPreferredSplitterX:=FSplitterX;
  FIndent:=9;
  FBackgroundColor:=clBtnFace;
  FReferencesColor:=clMaroon;
  FSubPropertiesColor:=clGreen;
  FNameFont:=TFont.Create;
  FNameFont.Color:=clWindowText;
  FValueFont:=TFont.Create;
  FValueFont.Color:=clMaroon;
  FDefaultValueFont:=TFont.Create;
  FDefaultValueFont.Color:=clWindowText;

  SetInitialBounds(0,0,200,130);
  ControlStyle:=ControlStyle+[csAcceptsControls,csOpaque];
  BorderWidth:=0;
  BorderStyle := bsSingle;

  // create sub components
  ValueEdit:=TEdit.Create(Self);
  with ValueEdit do begin
    Name:='ValueEdit';
    Visible:=false;
    Enabled:=false;
    SetBounds(0,-30,80,25); // hidden
    Parent:=Self;
    OnMouseDown := @ValueEditMouseDown;
    OnDblClick := @ValueEditDblClick;
    OnExit:=@ValueEditExit;
    OnChange:=@ValueEditChange;
    OnKeyDown:=@ValueEditKeyDown;
    OnKeyUp:=@ValueEditKeyUp;
  end;

  ValueComboBox:=TComboBox.Create(Self);
  with ValueComboBox do begin
    Name:='ValueComboBox';
    Visible:=false;
    Enabled:=false;
    SetBounds(0,-30,80,25); // hidden
    Parent:=Self;
    OnMouseDown := @ValueEditMouseDown;
    OnDblClick := @ValueEditDblClick;
    OnExit:=@ValueComboBoxExit;
    //OnChange:=@ValueComboBoxChange; the on change event is called even,
                                   // if the user is still editing
    OnKeyDown:=@ValueComboBoxKeyDown;
    OnKeyUp:=@ValueComboBoxKeyUp;
    OnDropDown:=@ValueComboBoxDropDown;
    OnCloseUp:=@ValueComboBoxCloseUp;
    OnDrawItem:=@ValueComboBoxDrawItem;
  end;

  ValueButton:=TButton.Create(Self);
  with ValueButton do begin
    Name:='ValueButton';
    Visible:=false;
    Enabled:=false;
    OnClick:=@ValueButtonClick;
    Caption := '...';
    SetBounds(0,-30,25,25); // hidden
    Parent:=Self;
  end;

  if DefItemHeight<3 then
    FDefaultItemHeight:=ValueComboBox.Height-3
  else
    FDefaultItemHeight:=DefItemHeight;

  BuildPropertyList;

  FHintTimer := TTimer.Create(nil);
  FHintTimer.Interval := 500;
  FHintTimer.Enabled := False;
  FHintTimer.OnTimer := @HintTimer;

  FHintWindow := THintWindow.Create(nil);

  FHIntWindow.Visible := False;
  FHintWindow.Caption := 'This is a hint window'#13#10'Neat huh?';
  FHintWindow.HideInterval := 4000;
  FHintWindow.AutoHide := True;
  
  Application.AddOnUserInputHandler(@OnUserInput,true);
end;

procedure TOICustomPropertyGrid.UpdateScrollBar;
var
  ScrollInfo: TScrollInfo;
begin
  if HandleAllocated then begin
    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_ALL or SIF_DISABLENOSCROLL;
    ScrollInfo.nMin := 0;
    ScrollInfo.nTrackPos := 0;
    ScrollInfo.nMax := TopMax+ClientHeight-1;
    ScrollInfo.nPage := ClientHeight;
    if ScrollInfo.nPage<1 then ScrollInfo.nPage:=1;
    if TopY > ScrollInfo.nMax then TopY:=ScrollInfo.nMax;
    ScrollInfo.nPos := TopY;
    ShowScrollBar(Handle, SB_VERT, True);
    SetScrollInfo(Handle, SB_VERT, ScrollInfo, True);
  end;
end;

procedure TOICustomPropertyGrid.FillComboboxItems;
var
  ExcludeUpdateFlag: boolean;
  CurRow: TOIPropertyGridRow;
begin
  ExcludeUpdateFlag:=not (pgsUpdatingEditControl in FStates);
  Include(FStates,pgsUpdatingEditControl);
  ValueComboBox.Items.BeginUpdate;
  try
    CurRow:=Rows[FItemIndex];
    if FNewComboBoxItems<>nil then FNewComboBoxItems.Clear;
    CurRow.Editor.GetValues(@AddStringToComboBox);
    if FNewComboBoxItems<>nil then begin
      FNewComboBoxItems.Sorted:=paSortList in CurRow.Editor.GetAttributes;
      if not ValueComboBox.Items.Equals(FNewComboBoxItems) then begin
        ValueComboBox.Items.Assign(FNewComboBoxItems);
      end;
      //debugln('TOICustomPropertyGrid.FillComboboxItems "',FNewComboBoxItems.Text,'" Cur="',ValueComboBox.Items.Text,'" ValueComboBox.Items.Count=',dbgs(ValueComboBox.Items.Count));
      FreeAndNil(FNewComboBoxItems);
    end else begin
      ValueComboBox.Items.Text:='';
      ValueComboBox.Items.Clear;
      //debugln('TOICustomPropertyGrid.FillComboboxItems FNewComboBoxItems=nil Cur="',ValueComboBox.Items.Text,'" ValueComboBox.Items.Count=',dbgs(ValueComboBox.Items.Count));
    end;
  finally
    ValueComboBox.Items.EndUpdate;
    if ExcludeUpdateFlag then
      Exclude(FStates,pgsUpdatingEditControl);
  end;
end;

procedure TOICustomPropertyGrid.CreateParams(var Params: TCreateParams);
const
  ClassStylesOff = CS_VREDRAW or CS_HREDRAW;
begin
  inherited CreateParams(Params);
  with Params do begin
    {$R-}
    WindowClass.Style := WindowClass.Style and not ClassStylesOff;
    Style := Style or WS_VSCROLL or WS_CLIPCHILDREN;
    {$R+}
    ExStyle := ExStyle or WS_EX_CLIENTEDGE;
  end;
end;

procedure TOICustomPropertyGrid.CreateWnd;
begin
  inherited CreateWnd;
  // handle just created, set scrollbar
  UpdateScrollBar;
end;

procedure TOICustomPropertyGrid.WMVScroll(var Msg: TWMScroll);
begin
  case Msg.ScrollCode of
      // Scrolls to start / end of the text
    SB_TOP:        TopY := 0;
    SB_BOTTOM:     TopY := TopMax;
      // Scrolls one line up / down
    SB_LINEDOWN:   TopY := TopY + DefaultItemHeight div 2;
    SB_LINEUP:     TopY := TopY - DefaultItemHeight div 2;
      // Scrolls one page of lines up / down
    SB_PAGEDOWN:   TopY := TopY + ClientHeight - DefaultItemHeight;
    SB_PAGEUP:     TopY := TopY - ClientHeight + DefaultItemHeight;
      // Scrolls to the current scroll bar position
    SB_THUMBPOSITION,
    SB_THUMBTRACK: TopY := Msg.Pos;
      // Ends scrolling
    SB_ENDSCROLL: ;
  end;
end;

destructor TOICustomPropertyGrid.Destroy;
var a:integer;
begin
  Application.RemoveOnUserInputHandler(@OnUserInput);
  FItemIndex:=-1;
  for a:=0 to FRows.Count-1 do Rows[a].Free;
  FreeAndNil(FRows);
  FreeAndNil(FSelection);
  FreeAndNil(FValueFont);
  FreeAndNil(FDefaultValueFont);
  FreeAndNil(FNameFont);
  FreeAndNil(FExpandedProperties);
  FreeAndNil(FHintTimer);
  FreeAndNil(FHintWindow);
  FreeAndNil(FNewComboBoxItems);
  inherited Destroy;
end;

function TOICustomPropertyGrid.ConsistencyCheck: integer;
var
  i: integer;
begin
  for i:=0 to FRows.Count-1 do begin
    if Rows[i]=nil then begin
      Result:=-1;
      exit;
    end;
    if Rows[i].Index<>i then begin
      Result:=-2;
      exit;
    end;
    Result:=Rows[i].ConsistencyCheck;
    if Result<>0 then begin
      dec(Result,100);
      exit;
    end;
  end;
  Result:=0;
end;

procedure TOICustomPropertyGrid.SetSelection(
  const ASelection: TPersistentSelectionList);
var
  CurRow:TOIPropertyGridRow;
  OldSelectedRowPath:string;
begin
  OldSelectedRowPath:=PropertyPath(ItemIndex);
  ItemIndex:=-1;
  ClearRows;
  FSelection.Assign(ASelection);
  BuildPropertyList;
  CurRow:=GetRowByPath(OldSelectedRowPath);
  if CurRow<>nil then
    ItemIndex:=CurRow.Index;
end;

procedure TOICustomPropertyGrid.SetPropertyEditorHook(
  NewPropertyEditorHook:TPropertyEditorHook);
begin
  if FPropertyEditorHook=NewPropertyEditorHook then exit;
  FPropertyEditorHook:=NewPropertyEditorHook;
  IncreaseChangeStep;
  SetSelection(FSelection);
end;

function TOICustomPropertyGrid.PropertyPath(Index:integer):string;
var CurRow:TOIPropertyGridRow;
begin
  if (Index>=0) and (Index<FRows.Count) then begin
    CurRow:=Rows[Index];
    Result:=CurRow.Name;
    CurRow:=CurRow.Parent;
    while CurRow<>nil do begin
      Result:=CurRow.Name+'.'+Result;
      CurRow:=CurRow.Parent;
    end;
  end else Result:='';
end;

function TOICustomPropertyGrid.GetRowByPath(
  const PropPath: string): TOIPropertyGridRow;
// searches PropPath. Expands automatically parent rows
var CurName:string;
  s,e:integer;
  CurParentRow:TOIPropertyGridRow;
begin
  Result:=nil;
  if FRows.Count=0 then exit;
  CurParentRow:=nil;
  s:=1;
  while (s<=length(PropPath)) do begin
    e:=s;
    while (e<=length(PropPath)) and (PropPath[e]<>'.') do inc(e);
    CurName:=uppercase(copy(PropPath,s,e-s));
    s:=e+1;
    // search name in childs
    if CurParentRow=nil then
      Result:=Rows[0]
    else
      Result:=CurParentRow.FirstChild;
    while (Result<>nil) and (uppercase(Result.Name)<>CurName) do
      Result:=Result.NextBrother;
    if Result=nil then begin
      exit;
    end else begin
      // expand row
      CurParentRow:=Result;
      ExpandRow(CurParentRow.Index);
    end;
  end;
  if s<=length(PropPath) then Result:=nil;
end;

procedure TOICustomPropertyGrid.SetRowValue;
var
  CurRow: TOIPropertyGridRow;
  NewValue: string;
  OldExpanded: boolean;
  OldChangeStep: integer;
begin
  //debugln('TOICustomPropertyGrid.SetRowValue A ',dbgs(FStates*[pgsChangingItemIndex,pgsApplyingValue]<>[]),' ',dbgs(FItemIndex));
  if not CanEditRowValue then exit;

  if FCurrentEdit=ValueEdit then
    NewValue:=ValueEdit.Text
  else
    NewValue:=ValueComboBox.Text;
  CurRow:=Rows[FItemIndex];
  if length(NewValue)>CurRow.Editor.GetEditLimit then
    NewValue:=LeftStr(NewValue,CurRow.Editor.GetEditLimit);

  if CurRow.Editor.GetVisualValue=NewValue then exit;

  OldChangeStep:=fChangeStep;
  Include(FStates,pgsApplyingValue);
  try
    {$IFNDEF DoNotCatchOIExceptions}
    try
    {$ENDIF}
      //debugln('TOICustomPropertyGrid.SetRowValue B ClassName=',CurRow.Editor.ClassName,' Visual=',CurRow.Editor.GetVisualValue,' NewValue=',NewValue,' AllEqual=',CurRow.Editor.AllEqual);
      CurRow.Editor.SetValue(NewValue);
      //debugln('TOICustomPropertyGrid.SetRowValue C ClassName=',CurRow.Editor.ClassName,' Visual=',CurRow.Editor.GetVisualValue,' NewValue=',NewValue,' AllEqual=',CurRow.Editor.AllEqual);
    {$IFNDEF DoNotCatchOIExceptions}
    except
      on E: Exception do begin
        MessageDlg(oisError, E.Message, mtError, [mbOk], 0);
      end;
    end;
    {$ENDIF}
    if (OldChangeStep<>FChangeStep) then begin
      // the selection has changed
      // => CurRow does not exist any more
      exit;
    end;
    
    // set value in edit control
    SetCurrentEditValue(CurRow.Editor.GetVisualValue);

    // update volatile sub properties
    if (paVolatileSubProperties in CurRow.Editor.GetAttributes)
    and ((CurRow.Expanded) or (CurRow.ChildCount>0)) then begin
      OldExpanded:=CurRow.Expanded;
      ShrinkRow(FItemIndex);
      if OldExpanded then
        ExpandRow(FItemIndex);
    end;
    //debugln('TOICustomPropertyGrid.SetRowValue D ClassName=',CurRow.Editor.ClassName,' Visual=',CurRow.Editor.GetVisualValue,' NewValue=',NewValue,' AllEqual=',CurRow.Editor.AllEqual);
  finally
    Exclude(FStates,pgsApplyingValue);
  end;
  if FPropertyEditorHook=nil then
    DoPaint(true)
  else
    FPropertyEditorHook.RefreshPropertyValues;
  if Assigned(FOnModified) then FOnModified(Self);
end;

procedure TOICustomPropertyGrid.DoCallEdit;
var
  CurRow:TOIPropertyGridRow;
  OldChangeStep: integer;
begin
  //writeln('#################### TOICustomPropertyGrid.DoCallEdit ...');
  if (FStates*[pgsChangingItemIndex,pgsApplyingValue]<>[])
  or (FCurrentEdit=nil)
  or (FItemIndex<0)
  or (FItemIndex>=FRows.Count)
  or ((FCurrentEditorLookupRoot<>nil)
    and (FPropertyEditorHook<>nil)
    and (FPropertyEditorHook.LookupRoot<>FCurrentEditorLookupRoot))
  then begin
    exit;
  end;

  OldChangeStep:=fChangeStep;
  CurRow:=Rows[FItemIndex];
  if paDialog in CurRow.Editor.GetAttributes then begin
    {$IFNDEF DoNotCatchOIExceptions}
    try
    {$ENDIF}
      DebugLn('#################### TOICustomPropertyGrid.DoCallEdit for ',CurRow.Editor.ClassName);
      Include(FStates,pgsApplyingValue);
      try
        CurRow.Editor.Edit;
      finally
        Exclude(FStates,pgsApplyingValue);
      end;
    {$IFNDEF DoNotCatchOIExceptions}
    except
      on E: Exception do begin
        MessageDlg(oisError, E.Message, mtError, [mbOk], 0);
      end;
    end;
    {$ENDIF}
    if (OldChangeStep<>FChangeStep) then begin
      // the selection has changed
      // => CurRow does not exist any more
      exit;
    end;
    
    // update value
    RefreshValueEdit;
  end;
end;

procedure TOICustomPropertyGrid.RefreshValueEdit;
var
  CurRow: TOIPropertyGridRow;
  NewValue: string;
begin
  if (FStates*[pgsChangingItemIndex,pgsApplyingValue]=[])
  and (FCurrentEdit<>nil)
  and (FItemIndex>=0) and (FItemIndex<FRows.Count) then begin
    CurRow:=Rows[FItemIndex];
    NewValue:=CurRow.Editor.GetVisualValue;
    SetCurrentEditValue(NewValue);
  end;
end;

procedure TOICustomPropertyGrid.ValueEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  HandleStandardKeys(Key,Shift);
end;

procedure TOICustomPropertyGrid.ValueEditKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  HandleKeyUp(Key,Shift);
end;

procedure TOICustomPropertyGrid.ValueEditExit(Sender: TObject);
begin
  SetRowValue;
end;

procedure TOICustomPropertyGrid.ValueEditChange(Sender: TObject);
var CurRow:TOIPropertyGridRow;
begin
  if pgsUpdatingEditControl in FStates then exit;
  if (FCurrentEdit<>nil) and (FItemIndex>=0) and (FItemIndex<FRows.Count) then
  begin
    CurRow:=Rows[FItemIndex];
    if paAutoUpdate in CurRow.Editor.GetAttributes then
      SetRowValue;
  end;
end;

procedure TOICustomPropertyGrid.ValueComboBoxExit(Sender: TObject);
begin
  if pgsUpdatingEditControl in FStates then exit;
  SetRowValue;
end;

procedure TOICustomPropertyGrid.ValueComboBoxChange(Sender: TObject);
var i:integer;
begin
  if pgsUpdatingEditControl in FStates then exit;
  i:=TComboBox(Sender).Items.IndexOf(TComboBox(Sender).Text);
  if i>=0 then SetRowValue;
end;

procedure TOICustomPropertyGrid.ValueComboBoxKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  HandleStandardKeys(Key,Shift);
end;

procedure TOICustomPropertyGrid.ValueComboBoxKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  HandleKeyUp(Key,Shift);
end;

procedure TOICustomPropertyGrid.ValueButtonClick(Sender: TObject);
begin
  DoCallEdit;
end;

procedure TOICustomPropertyGrid.SetItemIndex(NewIndex:integer);
var NewRow:TOIPropertyGridRow;
  NewValue:string;
begin
  if (FStates*[pgsChangingItemIndex,pgsApplyingValue]<>[])
  or (FItemIndex=NewIndex) then
    exit;
    
  // save old edit value
  SetRowValue;
  
  Include(FStates,pgsChangingItemIndex);
  if (FItemIndex>=0) and (FItemIndex<FRows.Count) then
    Rows[FItemIndex].Editor.Deactivate;
  SetCaptureControl(nil);
  
  FItemIndex:=NewIndex;
  if FCurrentEdit<>nil then begin
    FCurrentEdit.Visible:=false;
    FCurrentEdit.Enabled:=false;
    FCurrentEdit:=nil;
  end;
  if FCurrentButton<>nil then begin
    FCurrentButton.Visible:=false;
    FCurrentButton.Enabled:=false;
    FCurrentButton:=nil;
  end;
  FCurrentEditorLookupRoot:=nil;
  if (NewIndex>=0) and (NewIndex<FRows.Count) then begin
    NewRow:=Rows[NewIndex];
    if NewRow.Bottom>=TopY+(ClientHeight-2*BorderWidth) then
      TopY:=NewRow.Bottom-(ClientHeight-2*BorderWidth)+1
    else if NewRow.Top<TopY then
      TopY:=NewRow.Top;
    NewRow.Editor.Activate;
    if paDialog in NewRow.Editor.GetAttributes then begin
      FCurrentButton:=ValueButton;
      FCurrentButton.Visible:=true;
    end;
    NewValue:=NewRow.Editor.GetVisualValue;
    if paValueList in NewRow.Editor.GetAttributes then begin
      FCurrentEdit:=ValueComboBox;
      ValueComboBox.MaxLength:=NewRow.Editor.GetEditLimit;
      ValueComboBox.Sorted:=paSortList in NewRow.Editor.GetAttributes;
      ValueComboBox.Enabled:=not NewRow.IsReadOnly;
      // Do not fill the items here, it can be very slow.
      // Just fill in some values and update the values, before the combobox
      // popups
      ValueComboBox.Items.Text:=NewValue;
      ValueComboBox.Text:=NewValue;
    end else begin
      FCurrentEdit:=ValueEdit;
      ValueEdit.ReadOnly:=NewRow.IsReadOnly;
      ValueEdit.Enabled:=true;
      ValueEdit.MaxLength:=NewRow.Editor.GetEditLimit;
      ValueEdit.Text:=NewValue;
    end;
    AlignEditComponents;
    if FCurrentEdit<>nil then begin
      if FPropertyEditorHook<>nil then
        FCurrentEditorLookupRoot:=FPropertyEditorHook.LookupRoot;
      FCurrentEdit.Visible:=true;
      if (FDragging=false) and (FCurrentEdit.Showing)
      and FCurrentEdit.Enabled
      and (not NewRow.IsReadOnly) then begin
        if (Column=oipgcValue) then
          FCurrentEdit.SetFocus
        else
          Self.SetFocus;
      end;
    end;
    if FCurrentButton<>nil then
      FCurrentButton.Enabled:=not NewRow.IsDisabled;
  end;
  Exclude(FStates,pgsChangingItemIndex);
  Invalidate;
end;

function TOICustomPropertyGrid.GetRowCount:integer;
begin
  Result:=FRows.Count;
end;

procedure TOICustomPropertyGrid.BuildPropertyList;
var a:integer;
  CurRow:TOIPropertyGridRow;
  OldSelectedRowPath:string;
begin
  OldSelectedRowPath:=PropertyPath(ItemIndex);
  // unselect
  ItemIndex:=-1;
  // clear
  for a:=0 to FRows.Count-1 do Rows[a].Free;
  FRows.Clear;
  // get properties
  GetPersistentProperties(FSelection, FFilter, FPropertyEditorHook,
    @AddPropertyEditor,nil);
  // sort
  FRows.Sort(@SortGridRows);
  for a:=0 to FRows.Count-1 do begin
    if a>0 then
      Rows[a].FPriorBrother:=Rows[a-1]
    else
      Rows[a].FPriorBrother:=nil;
    if a<FRows.Count-1 then
      Rows[a].FNextBrother:=Rows[a+1]
    else
      Rows[a].FNextBrother:=nil;
  end;
  // set indices and tops
  SetItemsTops;
  // restore expands
  for a:=FExpandedProperties.Count-1 downto 0 do begin
    CurRow:=GetRowByPath(FExpandedProperties[a]);
    if CurRow<>nil then
      ExpandRow(CurRow.Index);
  end;
  // reselect
  CurRow:=GetRowByPath(OldSelectedRowPath);
  if CurRow<>nil then begin
    ItemIndex:=CurRow.Index;
  end;
  // update scrollbar
  FTopY:=0;
  UpdateScrollBar;
  // paint
  Invalidate;
end;

procedure TOICustomPropertyGrid.AddPropertyEditor(PropEditor: TPropertyEditor);
var
  NewRow: TOIPropertyGridRow;
begin
  if Favourites<>nil then begin
    //debugln('TOICustomPropertyGrid.AddPropertyEditor A ',PropEditor.GetName);
    if not Favourites.AreFavourites(Selection,PropEditor.GetName) then begin
      PropEditor.Free;
      exit;
    end;
  end;
  NewRow:=TOIPropertyGridRow.Create(Self,PropEditor,nil);
  FRows.Add(NewRow);
  if FRows.Count>1 then begin
    NewRow.FPriorBrother:=Rows[FRows.Count-2];
    NewRow.FPriorBrother.FNextBrother:=NewRow;
  end;
end;

procedure TOICustomPropertyGrid.AddStringToComboBox(const s: string);
begin
  if FNewComboBoxItems=nil then
    FNewComboBoxItems:=TStringList.Create;
  FNewComboBoxItems.Add(s);
end;

procedure TOICustomPropertyGrid.ExpandRow(Index:integer);
var a:integer;
  CurPath:string;
  AlreadyInExpandList:boolean;
begin
  FExpandingRow:=Rows[Index];
  if (FExpandingRow.Expanded)
  or (not (paSubProperties in FExpandingRow.Editor.GetAttributes))
  then begin
    FExpandingRow:=nil;
    exit;
  end;
  FExpandingRow.Editor.GetProperties(@AddSubEditor);
  SetItemsTops;
  FExpandingRow.FExpanded:=true;
  a:=0;
  CurPath:=uppercase(PropertyPath(FExpandingRow.Index));
  AlreadyInExpandList:=false;
  while a<FExpandedProperties.Count do begin
    if FExpandedProperties[a]=copy(CurPath,1,length(FExpandedProperties[a]))
    then begin
      if length(FExpandedProperties[a])=length(CurPath) then begin
        AlreadyInExpandList:=true;
        inc(a);
      end else begin
        FExpandedProperties.Delete(a);
      end;
    end else begin
      inc(a);
    end;
  end;
  if not AlreadyInExpandList then
    FExpandedProperties.Add(CurPath);
  FExpandingRow:=nil;
  UpdateScrollBar;
  Invalidate;
end;

procedure TOICustomPropertyGrid.ShrinkRow(Index:integer);
var CurRow, ARow:TOIPropertyGridRow;
  StartIndex,EndIndex,a:integer;
  CurPath:string;
begin
  CurRow:=Rows[Index];
  if (not CurRow.Expanded) then exit;
  // calculate all childs (between StartIndex..EndIndex)
  StartIndex:=CurRow.Index+1;
  EndIndex:=FRows.Count-1;
  ARow:=CurRow;
  while ARow<>nil do begin
    if ARow.NextBrother<>nil then begin
      EndIndex:=ARow.NextBrother.Index-1;
      break;
    end;
    ARow:=ARow.Parent;
  end;
  if (FItemIndex>=StartIndex) and (FItemIndex<=EndIndex) then
    // current row delete, set new current row
    ItemIndex:=0
  else if FItemIndex>EndIndex then
    // adjust current index for deleted rows
    FItemIndex := FItemIndex - (EndIndex - StartIndex + 1);
  for a:=EndIndex downto StartIndex do begin
    Rows[a].Free;
    FRows.Delete(a);
  end;
  SetItemsTops;
  CurRow.FExpanded:=false;
  CurPath:=uppercase(PropertyPath(CurRow.Index));
  a:=0;
  while a<FExpandedProperties.Count do begin
    if copy(FExpandedProperties[a],1,length(CurPath))=CurPath then
      FExpandedProperties.Delete(a)
    else
      inc(a);
  end;
  if CurRow.Parent<>nil then
    FExpandedProperties.Add(PropertyPath(CurRow.Parent.Index));
  UpdateScrollBar;
  Invalidate;
end;

procedure TOICustomPropertyGrid.AddSubEditor(PropEditor:TPropertyEditor);
var NewRow:TOIPropertyGridRow;
  NewIndex:integer;
begin
  NewRow:=TOIPropertyGridRow.Create(Self,PropEditor,FExpandingRow);
  NewIndex:=FExpandingRow.Index+1+FExpandingRow.ChildCount;
  FRows.Insert(NewIndex,NewRow);
  if NewIndex<FItemIndex
    then inc(FItemIndex);
  if FExpandingRow.FFirstChild=nil then
    FExpandingRow.FFirstChild:=NewRow;
  NewRow.FPriorBrother:=FExpandingRow.FLastChild;
  FExpandingRow.FLastChild:=NewRow;
  if NewRow.FPriorBrother<>nil then
    NewRow.FPriorBrother.FNextBrother:=NewRow;
  inc(FExpandingRow.FChildCount);
end;

function TOICustomPropertyGrid.MouseToIndex(y:integer;MustExist:boolean):integer;
var l,r,m:integer;
begin
  l:=0;
  r:=FRows.Count-1;
  inc(y,FTopY);
  while (l<=r) do begin
    m:=(l+r) shr 1;
    if Rows[m].Top>y then begin
      r:=m-1;
    end else if Rows[m].Bottom<=y then begin
      l:=m+1;
    end else begin
      Result:=m;  exit;
    end;
  end;
  if (MustExist=false) and (FRows.Count>0) then begin
    if y<0 then Result:=0
    else Result:=FRows.Count-1;
  end else Result:=-1;
end;

function TOICustomPropertyGrid.GetActiveRow: TOIPropertyGridRow;
begin
  Result:=nil;
  if ItemIndex<0 then exit;
  Result:=Rows[ItemIndex];
end;

procedure TOICustomPropertyGrid.SetCurrentRowValue(const NewValue: string);
begin
  if not CanEditRowValue then exit;
  // SetRowValue reads the value from the current edit control and writes it
  // to the property editor
  // -> set the text in the current edit control without changing FLastEditValue
  if FCurrentEdit=ValueEdit then
    ValueEdit.Text:=NewValue
  else if FCurrentEdit=ValueComboBox then
    ValueComboBox.Text:=NewValue;
  SetRowValue;
end;

procedure TOICustomPropertyGrid.SetItemIndexAndFocus(NewItemIndex: integer);
begin
  ItemIndex:=NewItemIndex;
  if FCurrentEdit<>nil then FCurrentEdit.SetFocus;
end;

function TOICustomPropertyGrid.CanEditRowValue: boolean;
begin
  if (FStates*[pgsChangingItemIndex,pgsApplyingValue,pgsUpdatingEditControl]<>[])
  or (FCurrentEdit=nil)
  or (FItemIndex<0)
  or (FItemIndex>=FRows.Count)
  or ((FCurrentEditorLookupRoot<>nil)
    and (FPropertyEditorHook<>nil)
    and (FPropertyEditorHook.LookupRoot<>FCurrentEditorLookupRoot))
  then begin
    Result:=false;
  end else begin
    Result:=true;
  end;
end;

procedure TOICustomPropertyGrid.SaveChanges;
begin
  SetRowValue;
end;

function TOICustomPropertyGrid.GetHintTypeAt(RowIndex: integer; X: integer
  ): TPropEditHint;
var
  IconX: integer;
begin
  Result:=pehNone;
  if (RowIndex<0) or (RowIndex>=RowCount) then exit;
  if SplitterX>=X then begin
    if (FCurrentButton<>nil)
    and (FCurrentButton.Left<=X) then
      Result:=pehEditButton
    else
      Result:=pehValue;
  end else begin
    IconX:=GetTreeIconX(RowIndex);
    if IconX+Indent>X then
      Result:=pehTree
    else
      Result:=pehName;
  end;
end;

procedure TOICustomPropertyGrid.MouseDown(Button:TMouseButton;  Shift:TShiftState;
  X,Y:integer);
begin
  //ShowMessageDialog('X'+IntToStr(X)+',Y'+IntToStr(Y));
  inherited MouseDown(Button,Shift,X,Y);

  //hide the hint
  FHintWindow.Visible := False;
  
  if Button=mbLeft then begin
    if Cursor=crHSplit then begin
      FDragging:=true;
    end;
  end;
end;

procedure TOICustomPropertyGrid.MouseMove(Shift:TShiftState;  X,Y:integer);
var
  SplitDistance:integer;
  Index: Integer;
  fPropRow: TOIPropertyGridRow;
  fHint: String;
  fpoint: TPoint;
  fHintRect: TRect;
begin
  inherited MouseMove(Shift,X,Y);
  SplitDistance:=X-SplitterX;
  if FDragging then begin
    if ssLeft in Shift then begin
      SplitterX:=SplitterX+SplitDistance;
    end else begin
      EndDragSplitter;
    end;
  end else begin
    if (abs(SplitDistance)<=2) then begin
      Cursor:=crHSplit;
    end else begin
      Cursor:=crDefault;
    end;
    // to check if the property text fits in its box, if not show a hint
    if ShowHint then begin
      Index := MouseToIndex(y,false);
      if Index > -1 then begin
        fPropRow := GetRow(Index);
        if X < SplitterX then begin
          // Mouse is over property name...
          fHint := fPropRow.Name;
          if (Canvas.TextWidth(fHint)+BorderWidth+GetTreeIconX(Index)+Indent)
          >= SplitterX
          then begin
            fHintRect := FHintWindow.CalcHintRect(0,fHint,nil);
            fpoint := ClientToScreen(
                                   Point(BorderWidth+GetTreeIconX(Index)+Indent,
                                   fPropRow.Top - TopY-1));
            MoveRect(fHintRect,fPoint.x,fPoint.y);
            FHintWindow.ActivateHint(fHintRect,fHint);
          end;
        end
        else begin
          // Mouse is over property value...
          fHint := fPropRow.LastPaintedValue;
          if length(fHint)>100 then fHint:=copy(fHint,1,100)+'...';
          if Canvas.TextWidth(fHint) > (ClientWidth - BorderWidth - SplitterX)
          then begin
            fHintRect := FHintWindow.CalcHintRect(0,fHint,nil);
            fpoint := ClientToScreen(Point(SplitterX,fPropRow.Top - TopY-1));
            MoveRect(fHintRect,fPoint.x,fPoint.y);
            FHintWindow.ActivateHint(fHintRect,fHint);
          end;
        end;
      end;
    end;
  end;
end;

procedure TOICustomPropertyGrid.MouseUp(Button:TMouseButton;  Shift:TShiftState;
  X,Y:integer);
var
  IconX,Index:integer;
  PointedRow:TOIpropertyGridRow;
  WasDragging: boolean;
begin
  WasDragging:=FDragging;
  if FDragging then EndDragSplitter;
  inherited MouseUp(Button,Shift,X,Y);

  if Button=mbLeft then begin
    if not WasDragging then begin
      Index:=MouseToIndex(Y,false);
      if (Index>=0) and (Index<FRows.Count) then begin
        IconX:=GetTreeIconX(Index);
        if (X>=IconX) and (X<=IconX+FIndent) then begin
          PointedRow:=Rows[Index];
          if paSubProperties in PointedRow.Editor.GetAttributes then begin
            if PointedRow.Expanded then
              ShrinkRow(Index)
            else
              ExpandRow(Index);
            ItemIndex:=Index;
          end;
        end else begin
          SetItemIndexAndFocus(Index);
        end;
      end;
    end;
  end;
end;

procedure TOICustomPropertyGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  HandleStandardKeys(Key,Shift);
  inherited KeyDown(Key, Shift);
end;

procedure TOICustomPropertyGrid.HandleStandardKeys(var Key: Word; Shift: TShiftState
  );
var
  Handled: Boolean;
begin
  Handled:=true;
  case Key of
  
  VK_UP:
    if (ItemIndex>0) then SetItemIndexAndFocus(ItemIndex-1);

  VK_Down:
    if (ItemIndex<FRows.Count-1) then SetItemIndexAndFocus(ItemIndex+1);
    
  VK_TAB:
    DoTabKey;

  VK_LEFT:
    if (FCurrentEdit=nil)
    and (ItemIndex>=0) and (Rows[ItemIndex].Expanded) then
      ShrinkRow(ItemIndex)
    else
      Handled:=false;
    
  VK_RIGHT:
    if (FCurrentEdit=nil)
    and (ItemIndex>=0) and (not Rows[ItemIndex].Expanded)
    and (paSubProperties in Rows[ItemIndex].Editor.GetAttributes) then
      ExpandRow(ItemIndex)
    else
      Handled:=false;

  VK_RETURN:
    SetRowValue;

  else
    Handled:=false;
  end;
  if Handled then Key:=VK_UNKNOWN;
end;

procedure TOICustomPropertyGrid.HandleKeyUp(var Key: Word; Shift: TShiftState);
begin
  if (Key<>VK_UNKNOWN) and Assigned(OnKeyUp) then OnKeyUp(Self,Key,Shift);
end;

procedure TOICustomPropertyGrid.DoTabKey;
begin
  if Column=oipgcValue then begin
    Column:=oipgcName;
    Self.SetFocus;
  end else begin
    Column:=oipgcValue;
    if FCurrentEdit<>nil then
      FCurrentEdit.SetFocus;
  end;
end;

procedure TOICustomPropertyGrid.EraseBackground(DC: HDC);
begin
  // everything is painted, so erasing the background is not needed
end;

procedure TOICustomPropertyGrid.DoSetBounds(ALeft, ATop, AWidth, AHeight: integer);
begin
  inherited DoSetBounds(ALeft, ATop, AWidth, AHeight);
  UpdateScrollBar;
end;

constructor TOICustomPropertyGrid.Create(TheOwner: TComponent);
begin
  CreateWithParams(TheOwner,nil,AllTypeKinds,25);
end;

procedure TOICustomPropertyGrid.OnUserInput(Sender: TObject; Msg: Cardinal);
begin
  ResetHintTimer;
end;

procedure TOICustomPropertyGrid.EndDragSplitter;
begin
  if FDragging then begin
    Cursor:=crDefault;
    FDragging:=false;
    FPreferredSplitterX:=FSplitterX;
    if FCurrentEdit<>nil then begin
      SetCaptureControl(nil);
      if Column=oipgcValue then
        FCurrentEdit.SetFocus
      else
        Self.SetFocus;
    end;
  end;
end;

procedure TOICustomPropertyGrid.SetSplitterX(const NewValue:integer);
var AdjustedValue:integer;
begin
  AdjustedValue:=NewValue;
  if AdjustedValue>ClientWidth then AdjustedValue:=ClientWidth;
  if AdjustedValue<1 then AdjustedValue:=1;
  if FSplitterX<>AdjustedValue then begin
    FSplitterX:=AdjustedValue;
    AlignEditComponents;
    Invalidate;
  end;
end;

procedure TOICustomPropertyGrid.SetTopY(const NewValue:integer);
var
  NewTopY: integer;
begin
  NewTopY := TopMax;
  if NewValue < NewTopY then
    NewTopY := NewValue;
  if NewTopY < 0 then
    NewTopY := 0;
  if FTopY<>NewTopY then begin
    FTopY:=NewTopY;
    UpdateScrollBar;
    ItemIndex:=-1;
    Invalidate;
  end;
end;

function TOICustomPropertyGrid.GetPropNameColor(ARow:TOIPropertyGridRow):TColor;
var
  ParentRow:TOIPropertyGridRow;
  IsObjectSubProperty:Boolean;
begin
  // Try to guest if ARow, or one of its parents, is a subproperty
  // of an object (and not an item of a set)
  IsObjectSubProperty:=false;
  ParentRow:=ARow.Parent;
  while Assigned(ParentRow) do
  begin
    if ParentRow.Editor is TPersistentPropertyEditor then
      IsObjectSubProperty:=true;
    ParentRow:=ParentRow.Parent;
  end;
  
  if IsObjectSubProperty then
    Result := FSubPropertiesColor
  else if ARow.Editor is TPersistentPropertyEditor then
    Result := FReferencesColor
  else
    Result := FNameFont.Color;
end;

procedure TOICustomPropertyGrid.SetBounds(aLeft,aTop,aWidth,aHeight:integer);
begin
//writeln('[TOICustomPropertyGrid.SetBounds] ',Name,' ',aLeft,',',aTop,',',aWidth,',',aHeight,' Visible=',Visible);
  inherited SetBounds(aLeft,aTop,aWidth,aHeight);
  if Visible then begin
    if not FDragging then begin
      if (SplitterX<5) and (aWidth>20) then
        SplitterX:=100
      else
        SplitterX:=FPreferredSplitterX;
    end;
    AlignEditComponents;
  end;
end;

function TOICustomPropertyGrid.GetTreeIconX(Index:integer):integer;
begin
  Result:=Rows[Index].Lvl*Indent+2;
end;

function TOICustomPropertyGrid.TopMax:integer;
begin
  Result:=GridHeight-ClientHeight+2*BorderWidth;
  if Result<0 then Result:=0;
end;

function TOICustomPropertyGrid.GridHeight:integer;
begin
  if FRows.Count>0 then
    Result:=Rows[FRows.Count-1].Bottom
  else
    Result:=0;
end;

procedure TOICustomPropertyGrid.AlignEditComponents;
var RRect,EditCompRect,EditBtnRect:TRect;

  function CompareRectangles(r1,r2:TRect):boolean;
  begin
    Result:=(r1.Left=r2.Left) and (r1.Top=r2.Top) and (r1.Right=r2.Right)
       and (r1.Bottom=r2.Bottom);
  end;

// AlignEditComponents
begin
  if ItemIndex>=0 then begin
    RRect:=RowRect(ItemIndex);
    EditCompRect:=RRect;
    EditCompRect.Top:=EditCompRect.Top-1;
    EditCompRect.Left:=RRect.Left+SplitterX;
    if FCurrentButton<>nil then begin
      // edit dialog button
      with EditBtnRect do begin
        Top:=RRect.Top;
        Left:=RRect.Right-20;
        Bottom:=RRect.Bottom;
        Right:=RRect.Right;
        EditCompRect.Right:=Left;
      end;
      if not CompareRectangles(FCurrentButton.BoundsRect,EditBtnRect) then begin
        FCurrentButton.BoundsRect:=EditBtnRect;
        //FCurrentButton.Invalidate;
      end;
    end;
    if FCurrentEdit<>nil then begin
      // resize the edit component
      EditCompRect.Left:=EditCompRect.Left-1;
      if not CompareRectangles(FCurrentEdit.BoundsRect,EditCompRect) then begin
        FCurrentEdit.BoundsRect:=EditCompRect;
        FCurrentEdit.Invalidate;
      end;
    end;
  end;
end;

procedure TOICustomPropertyGrid.PaintRow(ARow:integer);
var ARowRect,NameRect,NameIconRect,NameTextRect,ValueRect:TRect;
  IconX,IconY:integer;
  CurRow:TOIPropertyGridRow;
  DrawState:TPropEditDrawState;
  OldFont:TFont;

  procedure DrawTreeIcon(x,y:integer;Plus:boolean);
  begin
    with Canvas do begin
      Brush.Color:=clWhite;
      Pen.Color:=clBlack;
      Rectangle(x,y,x+8,y+8);
      MoveTo(x+2,y+4);
      LineTo(x+7,y+4);
      if Plus then begin
        MoveTo(x+4,y+2);
        LineTo(x+4,y+7);
      end;
    end;
  end;

// PaintRow
begin
  CurRow:=Rows[ARow];
  ARowRect:=RowRect(ARow);
  NameRect:=ARowRect;
  ValueRect:=ARowRect;
  NameRect.Right:=SplitterX;
  ValueRect.Left:=SplitterX;
  IconX:=GetTreeIconX(ARow);
  IconY:=((NameRect.Bottom-NameRect.Top-9) div 2)+NameRect.Top;
  NameIconRect:=NameRect;
  NameIconRect.Right:=IconX+Indent;
  NameTextRect:=NameRect;
  NameTextRect.Left:=NameIconRect.Right;
  DrawState:=[];
  if ARow=FItemIndex then Include(DrawState,pedsSelected);
  with Canvas do begin
    // draw name background
    if FBackgroundColor<>clNone then begin
      Brush.Color:=FBackgroundColor;
      FillRect(NameIconRect);
      FillRect(NameTextRect);
    end;
    // draw icon
    if paSubProperties in CurRow.Editor.GetAttributes then begin
      DrawTreeIcon(IconX,IconY,not CurRow.Expanded);
    end;
    // draw name
    OldFont:=Font;
    Font:=FNameFont;
    Font.Color := GetPropNameColor(CurRow);
    CurRow.Editor.PropDrawName(Canvas,NameTextRect,DrawState);
    Font:=OldFont;
    // draw frame for name
    if ARow<>FItemIndex then begin
      Pen.Style := psDot;
      Pen.Color:=cl3DShadow;
      MoveTo(NameRect.Left,NameRect.Bottom-1);
      LineTo(NameRect.Right-1,NameRect.Bottom-1);
    end else begin
      Pen.Color:=cl3DDKShadow;
      MoveTo(NameRect.Left,NameRect.Top-1);
      LineTo(NameRect.Right-1,NameRect.Top-1);
      Pen.Color:=cl3DShadow;
      MoveTo(NameRect.Left,NameRect.Top);
      LineTo(NameRect.Right-1,NameRect.Top);
      Pen.Color:=clWhite;
      MoveTo(NameRect.Left,NameRect.Bottom-1);
      LineTo(NameRect.Right-1,NameRect.Bottom-1);
    end;

    Pen.Color:=clWhite;
    Pen.Style := psSolid;
    LineTo(NameRect.Right-1,NameRect.Top-1);
    Pen.Color:=cl3DShadow;
    MoveTo(NameRect.Right-2,NameRect.Bottom-1);
    LineTo(NameRect.Right-2,NameRect.Top-1);
    Pen.Style := psSolid;
    // draw value background
    if FBackgroundColor<>clNone then begin
      Brush.Color:=FBackgroundColor;
      FillRect(ValueRect);
    end;
    // draw value
    if ARow<>ItemIndex then begin
      OldFont:=Font;
      if CurRow.Editor.IsNotDefaultValue then
        Font:=FValueFont
      else
        Font:=FDefaultValueFont;
      CurRow.Editor.PropDrawValue(Canvas,ValueRect,DrawState);
      Font:=OldFont;
    end;
    CurRow.LastPaintedValue:=CurRow.Editor.GetVisualValue;
    // draw frame for value
    Pen.Color:=cl3DShadow;
    if ARow=FItemIndex then
      Pen.Style := psSolid
    else
      Pen.Style := psDot;
    MoveTo(ValueRect.Left-1,ValueRect.Bottom-1);
    LineTo(ValueRect.Right,ValueRect.Bottom-1);
    Pen.Color:=cl3DLight;
    MoveTo(ValueRect.Left,ValueRect.Bottom-1);
    LineTo(ValueRect.Left,ValueRect.Top);
    Pen.Style := psSolid;
  end;
end;

procedure TOICustomPropertyGrid.DoPaint(PaintOnlyChangedValues:boolean);
var a:integer;
  SpaceRect:TRect;
begin
  if not PaintOnlyChangedValues then begin
    with Canvas do begin
      // draw properties
      for a:=0 to FRows.Count-1 do begin
        PaintRow(a);
      end;
      // draw unused space below rows
      SpaceRect:=Rect(BorderWidth,BorderWidth,
                      ClientWidth-BorderWidth+1,ClientHeight-BorderWidth+1);
      if FRows.Count>0 then
        SpaceRect.Top:=Rows[FRows.Count-1].Bottom-FTopY+BorderWidth;
// TWinControl(Parent).InvalidateRect(Self,SpaceRect,true);
      if FBackgroundColor<>clNone then begin
        Brush.Color:=FBackgroundColor;
        FillRect(SpaceRect);
      end;
      // don't draw border: borderstyle=bsSingle
    end;
  end else begin
    for a:=0 to FRows.Count-1 do begin
      if Rows[a].Editor.GetVisualValue<>Rows[a].LastPaintedValue then
        PaintRow(a);
    end;
  end;
end;

procedure TOICustomPropertyGrid.Paint;
begin
  inherited Paint;
  DoPaint(false);
end;

procedure TOICustomPropertyGrid.RefreshPropertyValues;
begin
  RefreshValueEdit;
  DoPaint(true);
end;

procedure TOICustomPropertyGrid.PropEditLookupRootChange;
begin
  // When the LookupRoot changes, no changes can be stored
  // -> undo the value editor changes
  RefreshValueEdit;
end;

function TOICustomPropertyGrid.RowRect(ARow:integer):TRect;
begin
  Result.Left:=BorderWidth;
  Result.Top:=Rows[ARow].Top-FTopY+BorderWidth;
  Result.Right:=ClientWidth-ScrollBarWidth;
  Result.Bottom:=Rows[ARow].Bottom-FTopY+BorderWidth;
end;

procedure TOICustomPropertyGrid.SetItemsTops;
// compute row tops from row heights
// set indices of all rows
var a,scrollmax:integer;
begin
  for a:=0 to FRows.Count-1 do begin
    Rows[a].Index:=a;
    Rows[a].MeasureHeight(Canvas);
  end;
  if FRows.Count>0 then
    Rows[0].Top:=0;
  for a:=1 to FRows.Count-1 do
    Rows[a].FTop:=Rows[a-1].Bottom;
  if FRows.Count>0 then
    scrollmax:=Rows[FRows.Count-1].Bottom-Height
  else
    scrollmax:=0;
  // always show something
  if scrollmax<10 then scrollmax:=10;
end;

procedure TOICustomPropertyGrid.ClearRows;
var a:integer;
begin
  IncreaseChangeStep;
  // reverse order to make sure child rows are freed before parent rows
  for a:=FRows.Count-1 downto 0 do begin
    Rows[a].Free;
  end;
  FRows.Clear;
end;

function TOICustomPropertyGrid.GetCurrentEditValue: string;
begin
  if FCurrentEdit=ValueEdit then
    Result:=ValueEdit.Text
  else if FCurrentEdit=ValueComboBox then
    Result:=ValueComboBox.Text
  else
    Result:='';
end;

procedure TOICustomPropertyGrid.SetColumn(
  const AValue: TOICustomPropertyGridColumn);
begin
  if FColumn=AValue then exit;
  FColumn:=AValue;
end;

procedure TOICustomPropertyGrid.SetCurrentEditValue(const NewValue: string);
begin
  if FCurrentEdit=ValueEdit then
    ValueEdit.Text:=NewValue
  else if FCurrentEdit=ValueComboBox then
    ValueComboBox.Text:=NewValue;
end;

procedure TOICustomPropertyGrid.SetFavourites(
  const AValue: TOIFavouriteProperties);
begin
  //debugln('TOICustomPropertyGrid.SetFavourites ',dbgsName(Self));
  if FFavourites=AValue then exit;
  FFavourites:=AValue;
  BuildPropertyList;
end;

procedure TOICustomPropertyGrid.Clear;
begin
  ClearRows;
end;

function TOICustomPropertyGrid.GetRow(Index:integer):TOIPropertyGridRow;
begin
  Result:=TOIPropertyGridRow(FRows[Index]);
end;

procedure TOICustomPropertyGrid.ValueComboBoxCloseUp(Sender: TObject);
begin
  SetRowValue;
end;

procedure TOICustomPropertyGrid.ValueComboBoxDropDown(Sender: TObject);
var
  CurRow: TOIPropertyGridRow;
  MaxItemWidth, CurItemWidth, i, Cnt: integer;
  ItemValue, CurValue: string;
  NewItemIndex: LongInt;
  ExcludeUpdateFlag: boolean;
begin
  if (FItemIndex>=0) and (FItemIndex<FRows.Count) then begin
    //debugln('TOICustomPropertyGrid.ValueComboBoxDropDown A');
    ExcludeUpdateFlag:=not (pgsUpdatingEditControl in FStates);
    Include(FStates,pgsUpdatingEditControl);
    ValueComboBox.Items.BeginUpdate;
    try
      CurRow:=Rows[FItemIndex];

      // Items
      FillComboboxItems;

      // Text and ItemIndex
      CurValue:=CurRow.Editor.GetVisualValue;
      ValueComboBox.Text:=CurValue;
      NewItemIndex:=ValueComboBox.Items.IndexOf(CurValue);
      if NewItemIndex>=0 then
        ValueComboBox.ItemIndex:=NewItemIndex;
        
      // ItemWidth
      MaxItemWidth:=ValueComboBox.Width;
      Cnt:=ValueComboBox.Items.Count;
      for i:=0 to Cnt-1 do begin
        ItemValue:=ValueComboBox.Items[i];
        CurItemWidth:=ValueComboBox.Canvas.TextWidth(ItemValue);
        CurRow.Editor.ListMeasureWidth(ItemValue,i,ValueComboBox.Canvas,
                                       CurItemWidth);
        if MaxItemWidth<CurItemWidth then
          MaxItemWidth:=CurItemWidth;
      end;
      ValueComboBox.ItemWidth:=MaxItemWidth;
    finally
      ValueComboBox.Items.EndUpdate;
      if ExcludeUpdateFlag then
        Exclude(FStates,pgsUpdatingEditControl);
    end;
  end;
end;

procedure TOICustomPropertyGrid.ValueComboBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  CurRow: TOIPropertyGridRow;
  ItemValue: string;
  AState: TPropEditDrawState;
begin
  if (FItemIndex>=0) and (FItemIndex<FRows.Count) then begin
    CurRow:=Rows[FItemIndex];
    if (Index>=0) and (Index<ValueComboBox.Items.Count) then
      ItemValue:=ValueComboBox.Items[Index]
    else
      ItemValue:='';
    AState:=[];
    if odPainted in State then Include(AState,pedsPainted);
    if odSelected in State then Include(AState,pedsSelected);
    if odFocused in State then Include(AState,pedsFocused);
    if odComboBoxEdit in State then
      Include(AState,pedsInEdit)
    else
      Include(AState,pedsInComboList);
      
    // clear background
    with ValueComboBox.Canvas do begin
      Brush.Color:=clWhite;
      Pen.Color:=clBlack;
      Font.Color:=Pen.Color;
      FillRect(ARect);
    end;
    CurRow.Editor.ListDrawValue(ItemValue,Index,ValueComboBox.Canvas,ARect,
                                AState);
  end;
end;

Procedure TOICustomPropertyGrid.HintTimer(sender : TObject);
var
  Rect : TRect;
  AHint : String;
  Position : TPoint;
  Index: integer;
  PointedRow:TOIpropertyGridRow;
  Window: TWinControl;
  HintType: TPropEditHint;
begin
  // ToDo: use LCL hintsystem
  FHintTimer.Enabled := False;
  if not ShowHint then exit;

  Position := Mouse.CursorPos;

  Window := FindLCLWindow(Position);
  if not(Assigned(Window)) then Exit;
  If (Window<>Self) and (not IsParentOf(Window)) then exit;

  Position := ScreenToClient(Position);
  if ((Position.X <=0) or (Position.X >= Width) or (Position.Y <= 0)
  or (Position.Y >= Height)) then
    Exit;
  
  AHint := '';
  Index:=MouseToIndex(Position.Y,false);
  if (Index>=0) and (Index<FRows.Count) then
  begin
    //IconX:=GetTreeIconX(Index);
    PointedRow:=Rows[Index];
    if Assigned(PointedRow) then
    Begin
      if Assigned(PointedRow.Editor) then begin
        HintType := GetHintTypeAt(Index,Position.X);
        AHint := PointedRow.Editor.GetHint(HintType,Position.X,Position.Y);
      end;
    end;
  end;
  if AHint = '' then Exit;
  Rect := FHintWindow.CalcHintRect(0,AHint,nil);  //no maxwidth
  Position := Mouse.CursorPos;
  Rect.Left := Position.X+10;
  Rect.Top := Position.Y+10;
  Rect.Right := Rect.Left + Rect.Right+3;
  Rect.Bottom := Rect.Top + Rect.Bottom+3;

  FHintWindow.ActivateHint(Rect,AHint);
end;

Procedure TOICustomPropertyGrid.ResetHintTimer;
begin
  if FHintWIndow.Visible then
    FHintWindow.Visible := False;
     
  FHintTimer.Enabled := False;
  if RowCount > 0 then
    FHintTimer.Enabled := not FDragging;
end;

procedure TOICustomPropertyGrid.ValueEditMouseDown(Sender : TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  //hide the hint window!
  if FHintWindow.Visible then FHintWindow.Visible := False;
end;

procedure TOICustomPropertyGrid.IncreaseChangeStep;
begin
  if FChangeStep<>$7fffffff then
    inc(FChangeStep)
  else
    FChangeStep:=-$7fffffff;
end;

PRocedure TOICustomPropertyGrid.ValueEditDblClick(Sender : TObject);
var
  CurRow: TOIPropertyGridRow;
  TypeKind : TTypeKind;
begin
  if (FStates*[pgsChangingItemIndex,pgsApplyingValue]<>[])
  or (FCurrentEdit=nil)
  or (FItemIndex<0)
  or (FItemIndex>=FRows.Count)
  or ((FCurrentEditorLookupRoot<>nil)
    and (FPropertyEditorHook<>nil)
    and (FPropertyEditorHook.LookupRoot<>FCurrentEditorLookupRoot))
  then begin
    exit;
  end;

  FHintTimer.Enabled := False;

  if (FCurrentEdit=ValueComboBox) then Begin
    //either an Event or an enumeration or Boolean
    CurRow:=Rows[FItemIndex];
    TypeKind := CurRow.Editor.GetPropType^.Kind;
    if TypeKind in [tkEnumeration,tkBool] then begin
      // set value to next value in list
      FillComboboxItems;
      if ValueComboBox.Items.Count = 0 then Exit;
      if ValueComboBox.ItemIndex < (ValueComboBox.Items.Count-1) then
        ValueComboBox.ItemIndex := ValueComboBox.ItemIndex +1
      else
        ValueComboBox.ItemIndex := 0;
      exit;
    end;
  end;
  DoCallEdit;
end;

procedure TOICustomPropertyGrid.SetBackgroundColor(const AValue: TColor);
begin
  if FBackgroundColor=AValue then exit;
  FBackgroundColor:=AValue;
  Invalidate;
end;

procedure TOICustomPropertyGrid.SetReferences(const AValue: TColor);
begin
  if FReferencesColor=AValue then exit;
  FReferencesColor:=AValue;
  Invalidate;
end;

procedure TOICustomPropertyGrid.SetSubPropertiesColor(const AValue: TColor);
begin
  if FSubPropertiesColor=AValue then exit;
  FSubPropertiesColor:=AValue;
  Invalidate;
end;

//------------------------------------------------------------------------------

{ TOIPropertyGridRow }

constructor TOIPropertyGridRow.Create(PropertyTree: TOICustomPropertyGrid;
  PropEditor:TPropertyEditor; ParentNode:TOIPropertyGridRow);
begin
  inherited Create;
  // tree pointer
  FTree:=PropertyTree;
  FParent:=ParentNode;
  FNextBrother:=nil;
  FPriorBrother:=nil;
  FExpanded:=false;
  // child nodes
  FChildCount:=0;
  FFirstChild:=nil;
  FLastChild:=nil;
  // director
  FEditor:=PropEditor;
  GetLvl;
  FName:=FEditor.GetName;
  FTop:=0;
  FHeight:=FTree.DefaultItemHeight;
  Index:=-1;
  LastPaintedValue:='';
end;

destructor TOIPropertyGridRow.Destroy;
begin
  if FPriorBrother<>nil then FPriorBrother.FNextBrother:=FNextBrother;
  if FNextBrother<>nil then FNextBrother.FPriorBrother:=FPriorBrother;
  if FParent<>nil then begin
    if FParent.FFirstChild=Self then FParent.FFirstChild:=FNextBrother;
    if FParent.FLastChild=Self then FParent.FLastChild:=FPriorBrother;
    dec(FParent.FChildCount);
  end;
  if FEditor<>nil then FEditor.Free;
  inherited Destroy;
end;

function TOIPropertyGridRow.ConsistencyCheck: integer;
var
  OldLvl, RealChildCount: integer;
  AChild: TOIPropertyGridRow;
begin
  if Top<0 then begin
    Result:=-1;
    exit;
  end;
  if Height<0 then begin
    Result:=-2;
    exit;
  end;
  if Lvl<0 then begin
    Result:=-3;
    exit;
  end;
  OldLvl:=Lvl;
  GetLvl;
  if Lvl<>OldLvl then begin
    Result:=-4;
    exit;
  end;
  if Name='' then begin
    Result:=-5;
    exit;
  end;
  if NextBrother<>nil then begin
    if NextBrother.PriorBrother<>Self then begin
      Result:=-6;
      exit;
    end;
    if NextBrother.Index<Index+1 then begin
      Result:=-7;
      exit;
    end;
  end;
  if PriorBrother<>nil then begin
    if PriorBrother.NextBrother<>Self then begin
      Result:=-8;
      exit;
    end;
    if PriorBrother.Index>Index-1 then begin
      Result:=-9
    end;
  end;
  if (Parent<>nil) then begin
    // has parent
    if (not Parent.HasChild(Self)) then begin
      Result:=-10;
      exit;
    end;
  end else begin
    // no parent
  end;
  if FirstChild<>nil then begin
    if Expanded then begin
      if (FirstChild.Index<>Index+1) then begin
        Result:=-11;
        exit;
      end;
    end;
  end else begin
    if LastChild<>nil then begin
      Result:=-12;
      exit;
    end;
  end;
  RealChildCount:=0;
  AChild:=FirstChild;
  while AChild<>nil do begin
    if AChild.Parent<>Self then begin
      Result:=-13;
      exit;
    end;
    inc(RealChildCount);
    AChild:=AChild.NextBrother;
  end;
  if RealChildCount<>ChildCount then begin
    Result:=-14;
    exit;
  end;
  Result:=0;
end;

function TOIPropertyGridRow.HasChild(Row: TOIPropertyGridRow): boolean;
var
  ChildRow: TOIPropertyGridRow;
begin
  ChildRow:=FirstChild;
  while ChildRow<>nil do begin
    if ChildRow=Row then begin
      Result:=true;
      exit;
    end;
  end;
  Result:=false;
end;

procedure TOIPropertyGridRow.GetLvl;
var n:TOIPropertyGridRow;
begin
  FLvl:=0;
  n:=FParent;
  while n<>nil do begin
    inc(FLvl);
    n:=n.FParent;
  end;
end;

function TOIPropertyGridRow.GetBottom:integer;
begin
  Result:=FTop+FHeight;
end;

function TOIPropertyGridRow.IsReadOnly: boolean;
begin
  Result:=Editor.IsReadOnly or IsDisabled;
end;

function TOIPropertyGridRow.IsDisabled: boolean;
var
  ParentRow: TOIPropertyGridRow;
begin
  Result:=false;
  ParentRow:=Parent;
  while (ParentRow<>nil) do begin
    if paDisableSubProperties in ParentRow.Editor.GetAttributes then begin
      Result:=true;
      exit;
    end;
    ParentRow:=ParentRow.Parent;
  end;
end;

procedure TOIPropertyGridRow.MeasureHeight(ACanvas: TCanvas);
begin
  FHeight:=FTree.DefaultItemHeight;
  Editor.PropMeasureHeight(Name,ACanvas,FHeight);
end;

//==============================================================================


{ TOIOptions }

function TOIOptions.FPropertyGridSplitterX(Page: TObjectInspectorPage): integer;
begin
  Result:=FGridSplitterX[Page];
end;

procedure TOIOptions.FPropertyGridSplitterX(Page: TObjectInspectorPage;
  const AValue: integer);
begin
  FGridSplitterX[Page]:=AValue;
end;

constructor TOIOptions.Create;
var
  p: TObjectInspectorPage;
begin
  inherited Create;

  FSaveBounds:=false;
  FLeft:=0;
  FTop:=0;
  FWidth:=250;
  FHeight:=400;
  for p:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
    FGridSplitterX[p]:=110;
  FDefaultItemHeight:=20;
  FShowComponentTree:=true;
  FComponentTreeHeight:=100;

  FGridBackgroundColor:=clBtnFace;
  FDefaultValueColor:=clWindowText;
  FSubPropertiesColor:= clGreen;
  FValueColor:=clMaroon;
  FReferencesColor:= clMaroon;
  FPropertyNameColor:=clWindowText;
end;

function TOIOptions.Load: boolean;
var
  Path: String;
  FileVersion: integer;
  Page: TObjectInspectorPage;
begin
  Result:=false;
  if ConfigStore=nil then exit;
  try
    Path:='ObjectInspectorOptions/';
    FileVersion:=ConfigStore.GetValue(Path+'Version/Value',0);
  
    FSaveBounds:=ConfigStore.GetValue(Path+'Bounds/Valid'
                                      ,false);
    if FSaveBounds then begin
      FLeft:=ConfigStore.GetValue(Path+'Bounds/Left',0);
      FTop:=ConfigStore.GetValue(Path+'Bounds/Top',0);
      FWidth:=ConfigStore.GetValue(Path+'Bounds/Width',250);
      FHeight:=ConfigStore.GetValue(Path+'Bounds/Height',400);
    end;

    if FileVersion>=2 then begin
      for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
        FGridSplitterX[Page]:=ConfigStore.GetValue(
           Path+'Bounds/'+DefaultOIPageNames[Page]+'/SplitterX',110);
    end else begin
      FGridSplitterX[oipgpProperties]:=ConfigStore.GetValue(
         Path+'Bounds/PropertyGridSplitterX',110);
      FGridSplitterX[oipgpEvents]:=ConfigStore.GetValue(
         Path+'Bounds/EventGridSplitterX',110);
    end;
    for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
      if FGridSplitterX[Page]<10 then FGridSplitterX[Page]:=10;

    FDefaultItemHeight:=ConfigStore.GetValue(
       Path+'Bounds/DefaultItemHeight',20);
    if FDefaultItemHeight<0 then FDefaultItemHeight:=20;
    FShowComponentTree:=ConfigStore.GetValue(
       Path+'ComponentTree/Show/Value',true);
    FComponentTreeHeight:=ConfigStore.GetValue(
       Path+'ComponentTree/Height/Value',100);

    FGridBackgroundColor:=ConfigStore.GetValue(
         Path+'Color/GridBackground',clBtnFace);
    FDefaultValueColor:=ConfigStore.GetValue(
         Path+'Color/DefaultValue', clWindowText);
    FSubPropertiesColor:=ConfigStore.GetValue(
         Path+'Color/SubProperties', clGreen);
    FValueColor:=ConfigStore.GetValue(
         Path+'Color/Value', clMaroon);
    FReferencesColor:=ConfigStore.GetValue(
         Path+'Color/References',clMaroon);
    FPropertyNameColor:=ConfigStore.GetValue(
         Path+'Color/PropertyName',clWindowText);

    FShowHints:=ConfigStore.GetValue(
         Path+'ShowHints',false);
  except
    on E: Exception do begin
      DebugLn('ERROR: TOIOptions.Load: ',E.Message);
      exit;
    end;
  end;
  Result:=true;
end;

function TOIOptions.Save: boolean;
var
  Page: TObjectInspectorPage;
  Path: String;
begin
  Result:=false;
  if ConfigStore=nil then exit;
  try
    Path:='ObjectInspectorOptions/';
    ConfigStore.SetValue(Path+'Version/Value',OIOptionsFileVersion);

    ConfigStore.SetDeleteValue(Path+'Bounds/Valid',FSaveBounds,
                             false);

    ConfigStore.SetDeleteValue(Path+'Bounds/Valid',FSaveBounds,
                             false);
    if FSaveBounds then begin
      ConfigStore.SetValue(Path+'Bounds/Left',FLeft);
      ConfigStore.SetValue(Path+'Bounds/Top',FTop);
      ConfigStore.SetValue(Path+'Bounds/Width',FWidth);
      ConfigStore.SetValue(Path+'Bounds/Height',FHeight);
    end;
    for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
      ConfigStore.SetDeleteValue(
         Path+'Bounds/'+DefaultOIPageNames[Page]+'/SplitterX',
         FGridSplitterX[Page],110);
    ConfigStore.SetDeleteValue(Path+'Bounds/DefaultItemHeight',
                             FDefaultItemHeight,20);
    ConfigStore.SetDeleteValue(Path+'ComponentTree/Show/Value',
                             FShowComponentTree,true);
    ConfigStore.SetDeleteValue(Path+'ComponentTree/Height/Value',
                             FComponentTreeHeight,100);

    ConfigStore.SetDeleteValue(Path+'Color/GridBackground',
                             FGridBackgroundColor,clBackground);
    ConfigStore.SetDeleteValue(Path+'Color/DefaultValue',
                             FDefaultValueColor,clBackground);
    ConfigStore.SetDeleteValue(Path+'Color/SubProperties',
                             FSubPropertiesColor,clBackground);
    ConfigStore.SetDeleteValue(Path+'Color/Value',
                             FValueColor,clBackground);
    ConfigStore.SetDeleteValue(Path+'Color/References',
                             FReferencesColor,clBackground);
    ConfigStore.SetDeleteValue(Path+'Color/PropertyName',
                              FPropertyNameColor,clWindowText);

    ConfigStore.SetDeleteValue(Path+'ShowHints',FShowHints,
                             false);
  except
    on E: Exception do begin
      DebugLn('ERROR: TOIOptions.Save: ',E.Message);
      exit;
    end;
  end;
  Result:=true;
end;

procedure TOIOptions.Assign(AnObjInspector: TObjectInspector);
var
  Page: TObjectInspectorPage;
begin
  FLeft:=AnObjInspector.Left;
  FTop:=AnObjInspector.Top;
  FWidth:=AnObjInspector.Width;
  FHeight:=AnObjInspector.Height;
  for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
    if AnObjInspector.GridControl[Page]<>nil then
      FGridSplitterX[Page]:=AnObjInspector.GridControl[Page].PrefferedSplitterX;
  FDefaultItemHeight:=AnObjInspector.DefaultItemHeight;
  FShowComponentTree:=AnObjInspector.ShowComponentTree;
  FComponentTreeHeight:=AnObjInspector.ComponentTreeHeight;
  
  FGridBackgroundColor:=AnObjInspector.PropertyGrid.BackgroundColor;
  FSubPropertiesColor:=AnObjInspector.PropertyGrid.SubPropertiesColor;
  FReferencesColor:=AnObjInspector.PropertyGrid.ReferencesColor;
  FValueColor:=AnObjInspector.PropertyGrid.ValueFont.Color;
  FDefaultValueColor:=AnObjInspector.PropertyGrid.DefaultValueFont.Color;
  FPropertyNameColor:=AnObjInspector.PropertyGrid.NameFont.Color;

  FShowHints:=AnObjInspector.PropertyGrid.ShowHint;
end;

procedure TOIOptions.AssignTo(AnObjInspector: TObjectInspector);
var
  Page: TObjectInspectorPage;
  Grid: TOICustomPropertyGrid;
begin
  if FSaveBounds then begin
    AnObjInspector.SetBounds(FLeft,FTop,FWidth,FHeight);
  end;
  for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do begin
    Grid:=AnObjInspector.GridControl[Page];
    if Grid=nil then continue;
    Grid.PrefferedSplitterX:=FGridSplitterX[Page];
    Grid.SplitterX:=FGridSplitterX[Page];
    Grid.BackgroundColor:=FGridBackgroundColor;
    Grid.SubPropertiesColor:=FSubPropertiesColor;
    Grid.ReferencesColor:=FReferencesColor;
    Grid.ValueFont.Color:=FValueColor;
    Grid.DefaultValueFont.Color:=FDefaultValueColor;
    Grid.NameFont.Color:=FPropertyNameColor;
    Grid.ShowHint:=FShowHints;
  end;
  AnObjInspector.DefaultItemHeight:=FDefaultItemHeight;
  AnObjInspector.ShowComponentTree:=FShowComponentTree;
  AnObjInspector.ComponentTreeHeight:=FComponentTreeHeight;
end;


//==============================================================================


{ TObjectInspector }

constructor TObjectInspector.Create(AnOwner: TComponent);

  procedure AddPopupMenuItem(var NewMenuItem: TMenuItem;
    ParentMenuItem: TMenuItem; const AName, ACaption, AHint: string;
    AnOnClick: TNotifyEvent; CheckedFlag, EnabledFlag, VisibleFlag: boolean);
  begin
    NewMenuItem:=TMenuItem.Create(Self);
    with NewMenuItem do begin
      Name:=AName;
      Caption:=ACaption;
      Hint:=AHint;
      OnClick:=AnOnClick;
      Checked:=CheckedFlag;
      Enabled:=EnabledFlag;
      Visible:=VisibleFlag;
    end;
    if ParentMenuItem<>nil then
      ParentMenuItem.Add(NewMenuItem)
    else
      MainPopupMenu.Items.Add(NewMenuItem);
  end;

  procedure AddSeparatorMenuItem(ParentMenuItem: TMenuItem;
    const AName: string; VisibleFlag: boolean);
  var
    NewMenuItem: TMenuItem;
  begin
    NewMenuItem:=TMenuItem.Create(Self);
    with NewMenuItem do begin
      Name:=AName;
      Caption:='-';
      Visible:=VisibleFlag;
    end;
    if ParentMenuItem<>nil then
      ParentMenuItem.Add(NewMenuItem)
    else
      MainPopupMenu.Items.Add(NewMenuItem);
  end;

begin
  inherited Create(AnOwner);
  FPropertyEditorHook:=nil;
  FSelection:=TPersistentSelectionList.Create;
  FUpdatingAvailComboBox:=false;
  FDefaultItemHeight := 22;
  FComponentTreeHeight:=100;
  FShowComponentTree:=true;
  FUsePairSplitter:=TPairSplitter.IsSupportedByInterface;
  FShowFavouritePage:=false;

  Caption := oisObjectInspector;
  Name := DefaultObjectInspectorName;
  KeyPreview:=true;

  // StatusBar
  StatusBar:=TStatusBar.Create(Self);
  with StatusBar do begin
    Name:='StatusBar';
    Parent:=Self;
    SimpleText:=oisAll;
    Align:= alBottom;
  end;

  // PopupMenu
  MainPopupMenu:=TPopupMenu.Create(Self);
  with MainPopupMenu do begin
    Name:='MainPopupMenu';
    OnPopup:=@OnMainPopupMenuPopup;
    AutoPopup:=true;
  end;
  AddPopupMenuItem(SetDefaultPopupmenuItem,nil,'SetDefaultPopupMenuItem',
     'Set to Default value','Set property value to Default',
     @OnSetDefaultPopupmenuItemClick,false,true,true);
  AddPopupMenuItem(AddToFavoritesPopupMenuItem,nil,'AddToFavoritePopupMenuItem',
     oisAddtofavorites,'Add property to favorites properties',
     @OnAddToFavoritesPopupmenuItemClick,false,true,true);
  AddPopupMenuItem(RemoveFromFavoritesPopupMenuItem,nil,
     'RemoveFromFavoritesPopupMenuItem',
     oisRemovefromfavorites,'Remove property from favorites properties',
     @OnRemoveFromFavoritesPopupmenuItemClick,false,true,true);
  AddPopupMenuItem(UndoPropertyPopupMenuItem,nil,'UndoPropertyPopupMenuItem',
     oisUndo,'Set property value to last valid value',
     @OnUndoPopupmenuItemClick,false,true,true);
  AddSeparatorMenuItem(nil,'OptionsSeparatorMenuItem',true);
  AddPopupMenuItem(CutPopupMenuItem,nil,'CutPopupMenuItem',
     oisCut,'Cut selected item',
     @OnCutPopupmenuItemClick,false,true,true);
  AddPopupMenuItem(CopyPopupMenuItem,nil,'CopyPopupMenuItem',
     oisCopy,'Copy selected item',
     @OnCopyPopupmenuItemClick,false,true,true);
  AddPopupMenuItem(PastePopupMenuItem,nil,'PastePopupMenuItem',
     oisPaste,'Paste selected item',
     @OnPastePopupmenuItemClick,false,true,true);
  AddPopupMenuItem(DeletePopupMenuItem,nil,'DeletePopupMenuItem',
     oisDelete,'Delete selected item',
     @OnDeletePopupmenuItemClick,false,true,true);
  AddPopupMenuItem(OptionsSeparatorMenuItem2,nil,'',
     '-','',nil,false,true,true);
  AddPopupMenuItem(ShowHintsPopupMenuItem,nil
     ,'ShowHintPopupMenuItem',oisShowHints,'Grid hints'
     ,@OnShowHintPopupMenuItemClick,false,true,true);
  ShowHintsPopupMenuItem.ShowAlwaysCheckable:=true;
  AddPopupMenuItem(ShowComponentTreePopupMenuItem,nil
     ,'ShowComponentTreePopupMenuItem',oisShowComponentTree,''
     ,@OnShowComponentTreePopupMenuItemClick,FShowComponentTree,true,true);
  ShowComponentTreePopupMenuItem.ShowAlwaysCheckable:=true;
  AddPopupMenuItem(ShowOptionsPopupMenuItem,nil
     ,'ShowOptionsPopupMenuItem',oisOptions,''
     ,@OnShowOptionsPopupMenuItemClick,false,true,FOnShowOptions<>nil);

  PopupMenu:=MainPopupMenu;

  // combobox at top (filled with available persistents)
  AvailPersistentComboBox := TComboBox.Create (Self);
  with AvailPersistentComboBox do begin
    Name:='AvailPersistentComboBox';
    Parent:=Self;
    Style:=csDropDown;
    Text:='';
    OnCloseUp:=@AvailComboBoxCloseUp;
    //Sorted:=true;
    Align:= alTop;
    Visible:=not FShowComponentTree;
  end;
  
  if FUsePairSplitter and ShowComponentTree then
    CreatePairSplitter;

  // Component Tree at top (filled with available components)
  ComponentTree:=TComponentTreeView.Create(Self);
  with ComponentTree do begin
    Name:='ComponentTree';
    Height:=ComponentTreeHeight;
    if PairSplitter1<>nil then begin
      Parent:=PairSplitter1.Sides[0];
      Align:=alClient;
    end else begin
      Parent:=Self;
      Align:=alTop;
    end;
    OnSelectionChanged:=@ComponentTreeSelectionChanged;
    Visible:=FShowComponentTree;
  end;

  CreateNoteBook;
  
  OnResize:=@ObjectInspectorResize;
end;

destructor TObjectInspector.Destroy;
begin
  FreeAndNil(FSelection);
  inherited Destroy;
  FreeAndNil(FFavourites);
end;

procedure TObjectInspector.SetPropertyEditorHook(NewValue:TPropertyEditorHook);
var
  Page: TObjectInspectorPage;
begin
  if FPropertyEditorHook=NewValue then exit;
  if FPropertyEditorHook<>nil then begin
    FPropertyEditorHook.RemoveAllHandlersForObject(Self);
  end;
  FPropertyEditorHook:=NewValue;
  if FPropertyEditorHook<>nil then begin
    FPropertyEditorHook.AddHandlerChangeLookupRoot(@HookLookupRootChange);
    FPropertyEditorHook.AddHandlerRefreshPropertyValues(
                                                @HookRefreshPropertyValues);
    FPropertyEditorHook.AddHandlerGetSelection(@HookGetSelection);
    FPropertyEditorHook.AddHandlerSetSelection(@HookSetSelection);
    // select root component
    FSelection.Clear;
    if (FPropertyEditorHook<>nil) and (FPropertyEditorHook.LookupRoot<>nil)
    and (FPropertyEditorHook.LookupRoot is TComponent) then
      FSelection.Add(TComponent(FPropertyEditorHook.LookupRoot));
    FillPersistentComboBox;
    for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
      if GridControl[Page]<>nil then
        GridControl[Page].PropertyEditorHook:=FPropertyEditorHook;
    ComponentTree.PropertyEditorHook:=FPropertyEditorHook;
    RefreshSelection;
  end;
end;

function TObjectInspector.PersistentToString(APersistent: TPersistent): string;
begin
  if APersistent is TComponent then
    Result:=TComponent(APersistent).GetNamePath+': '+APersistent.ClassName
  else
    Result:=APersistent.ClassName;
end;

procedure TObjectInspector.SetComponentTreeHeight(const AValue: integer);
begin
  if FComponentTreeHeight=AValue then exit;
  FComponentTreeHeight:=AValue;
end;

procedure TObjectInspector.SetDefaultItemHeight(const AValue: integer);
var
  NewValue: Integer;
  Page: TObjectInspectorPage;
begin
  NewValue:=AValue;
  if NewValue<0 then
    NewValue:=0
  else if NewValue=0 then
    NewValue:=22
  else if (NewValue>0) and (NewValue<10) then
    NewValue:=10
  else if NewValue>100 then NewValue:=100;
  if FDefaultItemHeight=NewValue then exit;
  FDefaultItemHeight:=NewValue;
  for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
    if GridControl[Page]<>nil then
      GridControl[Page].DefaultItemHeight:=FDefaultItemHeight;
  RebuildPropertyLists;
end;

procedure TObjectInspector.SetOnShowOptions(const AValue: TNotifyEvent);
begin
  if FOnShowOptions=AValue then exit;
  FOnShowOptions:=AValue;
  ShowOptionsPopupMenuItem.Visible:=FOnShowOptions<>nil;
end;

procedure TObjectInspector.AddPersistentToList(APersistent: TPersistent;
  List: TStrings);
var
  Allowed: boolean;
begin
  if (APersistent is TComponent)
  and (csDestroying in TComponent(APersistent).ComponentState) then exit;
  Allowed:=true;
  if Assigned(FOnAddAvailablePersistent) then
    FOnAddAvailablePersistent(APersistent,Allowed);
  if Allowed then
    List.AddObject(PersistentToString(APersistent),APersistent);
end;

procedure TObjectInspector.HookLookupRootChange;
var
  Page: TObjectInspectorPage;
begin
  for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
    if GridControl[Page]<>nil then
      GridControl[Page].PropEditLookupRootChange;
  FillPersistentComboBox;
end;

procedure TObjectInspector.FillPersistentComboBox;
var a:integer;
  Root:TComponent;
  OldText:AnsiString;
  NewList: TStringList;
begin
//writeln('[TObjectInspector.FillComponentComboBox] A ',FUpdatingAvailComboBox
//,' ',FPropertyEditorHook<>nil,'  ',FPropertyEditorHook.LookupRoot<>nil);
  if FUpdatingAvailComboBox then exit;
  FUpdatingAvailComboBox:=true;
  if ComponentTree<>nil then
    ComponentTree.Selection:=FSelection;
  NewList:=TStringList.Create;
  try
    if (FPropertyEditorHook<>nil)
    and (FPropertyEditorHook.LookupRoot<>nil) then begin
      AddPersistentToList(FPropertyEditorHook.LookupRoot,NewList);
      if FPropertyEditorHook.LookupRoot is TComponent then begin
        Root:=TComponent(FPropertyEditorHook.LookupRoot);
  //writeln('[TObjectInspector.FillComponentComboBox] B  ',Root.Name,'  ',Root.ComponentCount);
        for a:=0 to Root.ComponentCount-1 do
          AddPersistentToList(Root.Components[a],NewList);
      end;
    end;

    if AvailPersistentComboBox.Items.Equals(NewList) then exit;

    AvailPersistentComboBox.Items.BeginUpdate;
    if AvailPersistentComboBox.Items.Count=1 then
      OldText:=AvailPersistentComboBox.Text
    else
      OldText:='';
    AvailPersistentComboBox.Items.Assign(NewList);
    AvailPersistentComboBox.Items.EndUpdate;
    a:=AvailPersistentComboBox.Items.IndexOf(OldText);
    if (OldText='') or (a<0) then
      SetAvailComboBoxText
    else
      AvailPersistentComboBox.ItemIndex:=a;

  finally
    NewList.Free;
    FUpdatingAvailComboBox:=false;
  end;
end;

procedure TObjectInspector.BeginUpdate;
begin
  inc(FUpdateLock);
end;

procedure TObjectInspector.EndUpdate;
begin
  dec(FUpdateLock);
  if FUpdateLock<0 then begin
    DebugLn('ERROR TObjectInspector.EndUpdate');
  end;
  if FUpdateLock=0 then begin
    if oifRebuildPropListsNeeded in FFLags then
      RebuildPropertyLists;
  end;
end;

function TObjectInspector.GetActivePropertyGrid: TOICustomPropertyGrid;
begin
  Result:=nil;
  if NoteBook=nil then exit;
  case NoteBook.PageIndex of
  0: Result:=PropertyGrid;
  1: Result:=EventGrid;
  2: Result:=FavouriteGrid;
  end;
end;

function TObjectInspector.GetActivePropertyRow: TOIPropertyGridRow;
var
  CurGrid: TOICustomPropertyGrid;
begin
  Result:=nil;
  CurGrid:=GetActivePropertyGrid;
  if CurGrid=nil then exit;
  Result:=CurGrid.GetActiveRow;
end;

function TObjectInspector.GetCurRowDefaultValue(var DefaultStr: string): boolean;
var
  CurRow: TOIPropertyGridRow;
begin
  Result:=false;
  DefaultStr:='';
  CurRow:=GetActivePropertyRow;
  if (CurRow=nil) or (not (paHasDefaultValue in CurRow.Editor.GetAttributes))
  then exit;
  try
    DefaultStr:=CurRow.Editor.GetDefaultValue;
    Result:=true;
  except
    DefaultStr:='';
  end;
end;

procedure TObjectInspector.SetSelection(
  const ASelection:TPersistentSelectionList);
begin
  if FSelection.IsEqual(ASelection) then exit;
  //if (FSelection.Count=1) and (FSelection[0] is TCollectionItem)
  //and (ASelection.Count=0) then RaiseGDBException('');
  FSelection.Assign(ASelection);
  SetAvailComboBoxText;
  RefreshSelection;
  if Assigned(FOnSelectPersistentsInOI) then
    FOnSelectPersistentsInOI(Self);
end;

procedure TObjectInspector.RefreshSelection;
var
  Page: TObjectInspectorPage;
begin
  for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
    if GridControl[Page]<>nil then
      GridControl[Page].Selection := FSelection;
  ComponentTree.Selection := FSelection;
  ComponentTree.MakeSelectionVisible;
  if (not Visible) and (FSelection.Count>0) then
    Visible:=true;
end;

procedure TObjectInspector.RefreshPropertyValues;
var
  Page: TObjectInspectorPage;
begin
  for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
    if GridControl[Page]<>nil then
      GridControl[Page].RefreshPropertyValues;
end;

procedure TObjectInspector.RebuildPropertyLists;
var
  Page: TObjectInspectorPage;
begin
  if FUpdateLock>0 then
    Include(FFLags,oifRebuildPropListsNeeded)
  else begin
    Exclude(FFLags,oifRebuildPropListsNeeded);
    for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
      if GridControl[Page]<>nil then
        GridControl[Page].BuildPropertyList;
  end;
end;

procedure TObjectInspector.AvailComboBoxCloseUp(Sender:TObject);
var NewComponent,Root:TComponent;
  a:integer;

  procedure SetSelectedPersistent(c:TPersistent);
  begin
    if (FSelection.Count=1) and (FSelection[0]=c) then exit;
    FSelection.Clear;
    FSelection.Add(c);
    RefreshSelection;
    if Assigned(FOnSelectPersistentsInOI) then
      FOnSelectPersistentsInOI(Self);
  end;

// AvailComboBoxChange
begin
  if FUpdatingAvailComboBox then exit;
  if (FPropertyEditorHook=nil) or (FPropertyEditorHook.LookupRoot=nil) then
    exit;
  if not (FPropertyEditorHook.LookupRoot is TComponent) then begin
    // not a TComponent => no childs => select always only the root
    SetSelectedPersistent(FPropertyEditorHook.LookupRoot);
    exit;
  end;
  Root:=TComponent(FPropertyEditorHook.LookupRoot);
  if (AvailPersistentComboBox.Text=PersistentToString(Root)) then begin
    SetSelectedPersistent(Root);
  end else begin
    for a:=0 to Root.ComponentCount-1 do begin
      NewComponent:=Root.Components[a];
      if AvailPersistentComboBox.Text=PersistentToString(NewComponent) then
      begin
        SetSelectedPersistent(NewComponent);
        break;
      end;
    end;
  end;
end;

procedure TObjectInspector.ComponentTreeSelectionChanged(Sender: TObject);
begin
  if (PropertyEditorHook=nil) or (PropertyEditorHook.LookupRoot=nil) then exit;
  if FSelection.IsEqual(ComponentTree.Selection) then exit;
  Fselection.Assign(ComponentTree.Selection);
  RefreshSelection;
  if Assigned(FOnSelectPersistentsInOI) then
    FOnSelectPersistentsInOI(Self);
end;

procedure TObjectInspector.ObjectInspectorResize(Sender: TObject);
begin
  if (ComponentTree<>nil) and (ComponentTree.Visible)
  and (ComponentTree.Parent=Self) then
    ComponentTree.Height:=ClientHeight div 4;
end;

procedure TObjectInspector.OnGriddKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Assigned(OnRemainingKeyUp) then OnRemainingKeyUp(Self,Key,Shift);
end;

procedure TObjectInspector.OnSetDefaultPopupmenuItemClick(Sender: TObject);
var
  CurGrid: TOICustomPropertyGrid;
  DefaultStr: string;
begin
  if not GetCurRowDefaultValue(DefaultStr) then exit;
  CurGrid:=GetActivePropertyGrid;
  if CurGrid=nil then exit;
  CurGrid.SetCurrentRowValue(DefaultStr);
  RefreshPropertyValues;
end;

procedure TObjectInspector.OnAddToFavoritesPopupmenuItemClick(Sender: TObject);
begin
  //debugln('TObjectInspector.OnAddToFavouritePopupmenuItemClick');
  if Assigned(OnAddToFavourites) then OnAddToFavourites(Self);
end;

procedure TObjectInspector.OnRemoveFromFavoritesPopupmenuItemClick(
  Sender: TObject);
begin
  if Assigned(OnRemoveFromFavourites) then OnRemoveFromFavourites(Self);
end;

procedure TObjectInspector.OnUndoPopupmenuItemClick(Sender: TObject);
var
  CurGrid: TOICustomPropertyGrid;
  CurRow: TOIPropertyGridRow;
begin
  CurGrid:=GetActivePropertyGrid;
  CurRow:=GetActivePropertyRow;
  if CurRow=nil then exit;
  CurGrid.CurrentEditValue:=CurRow.Editor.GetVisualValue;
end;

procedure TObjectInspector.OnCutPopupmenuItemClick(Sender: TObject);
var
  ADesigner: TIDesigner;
begin
  if (Selection.Count > 0) and (Selection[0] is TComponent) then begin
    ADesigner:=FindRootDesigner(TComponent(Selection[0]));
    if ADesigner is TComponentEditorDesigner then begin
      TComponentEditorDesigner(ADesigner).CutSelection;
    end;
  end;
end;

procedure TObjectInspector.OnCopyPopupmenuItemClick(Sender: TObject);
var
  ADesigner: TIDesigner;
begin
  if (Selection.Count > 0) and (Selection[0] is TComponent) then
  begin
    ADesigner:=FindRootDesigner(TComponent(Selection[0]));
    if ADesigner is TComponentEditorDesigner then begin
      TComponentEditorDesigner(ADesigner).CopySelection;
    end;
  end;
end;

procedure TObjectInspector.OnPastePopupmenuItemClick(Sender: TObject);
var
  ADesigner: TIDesigner;
begin
  if Selection.Count > 0 then begin
    ADesigner:=FindRootDesigner(TComponent(Selection[0]));
    if ADesigner is TComponentEditorDesigner then begin
      TComponentEditorDesigner(ADesigner).PasteSelection([cpsfReplace]);
    end;
  end;
end;

procedure TObjectInspector.OnDeletePopupmenuItemClick(Sender: TObject);
var
  ADesigner: TIDesigner;
begin
  if (Selection.Count > 0) and (Selection[0] is TComponent) then
  begin
    ADesigner:=FindRootDesigner(TComponent(Selection[0]));
    if ADesigner is TComponentEditorDesigner then begin
      TComponentEditorDesigner(ADesigner).DeleteSelection;
    end;
  end;
end;

procedure TObjectInspector.OnGridModified(Sender: TObject);
begin
  if Assigned(FOnModified) then FOnModified(Self);
end;

procedure TObjectInspector.SetAvailComboBoxText;
begin
  case FSelection.Count of
    0: // none selected
       AvailPersistentComboBox.Text:='';
    1: // single selection
       AvailPersistentComboBox.Text:=PersistentToString(FSelection[0]);
  else
    // multi selection
    AvailPersistentComboBox.Text:=Format(oisItemsSelected, [FSelection.Count]);
  end;
end;

procedure TObjectInspector.HookGetSelection(
  const ASelection: TPersistentSelectionList);
begin
  if ASelection=nil then exit;
  ASelection.Assign(FSelection);
end;

procedure TObjectInspector.HookSetSelection(
  const ASelection: TPersistentSelectionList);
begin
  if ASelection=nil then exit;
  if FSelection.IsEqual(ASelection) then exit;
  Selection:=ASelection;
  if Assigned(FOnSelectPersistentsInOI) then
    FOnSelectPersistentsInOI(Self);
end;

procedure TObjectInspector.SetShowComponentTree(const AValue: boolean);
begin
  if FShowComponentTree=AValue then exit;
  FShowComponentTree:=AValue;
  BeginUpdate;
  ShowComponentTreePopupMenuItem.Checked:=FShowComponentTree;
  // hide controls while rebuilding
  if PairSplitter1<>nil then
    PairSplitter1.Visible:=false;
  DestroyNoteBook;
  ComponentTree.Visible:=false;
  AvailPersistentComboBox.Visible:=false;
  // rebuild controls
  if FUsePairSplitter and FShowComponentTree then begin
    CreatePairSplitter;
    ComponentTree.Parent:=PairSplitter1.Sides[0];
    ComponentTree.Align:=alClient;
  end else begin
    ComponentTree.Parent:=Self;
    ComponentTree.Align:=alTop;
    ComponentTree.Height:=ComponentTreeHeight;
    if PairSplitter1<>nil then begin
      PairSplitter1.Free;
      PairSplitter1:=nil;
    end;
  end;
  ComponentTree.Visible:=FShowComponentTree;
  AvailPersistentComboBox.Visible:=not FShowComponentTree;
  CreateNoteBook;
  EndUpdate;
end;

procedure TObjectInspector.SetUsePairSplitter(const AValue: boolean);
begin
  if FUsePairSplitter=AValue then exit;
  FUsePairSplitter:=AValue;
end;

procedure TObjectInspector.CreatePairSplitter;
begin
  // pair splitter between component tree and notebook
  PairSplitter1:=TPairSplitter.Create(Self);
  with PairSplitter1 do begin
    Name:='PairSplitter1';
    Parent:=Self;
    SplitterType:=pstVertical;
    Align:=alClient;
    Position:=ComponentTreeHeight;
    Sides[0].Name:=Name+'Side1';
    Sides[1].Name:=Name+'Side2';
  end;
end;

procedure TObjectInspector.DestroyNoteBook;
begin
  if NoteBook<>nil then
    NoteBook.Visible:=false;
  FreeAndNil(PropertyGrid);
  FreeAndNil(EventGrid);
  FreeAndNil(FavouriteGrid);
  FreeAndNil(NoteBook);
end;

procedure TObjectInspector.CreateNoteBook;
begin
  DestroyNoteBook;

  // NoteBook
  NoteBook:=TNoteBook.Create(Self);
  with NoteBook do begin
    Name:='NoteBook';
    if PairSplitter1<>nil then begin
      Parent:=PairSplitter1.Sides[1];
    end else begin
      Parent:=Self;
    end;
    Align:= alClient;
    if PageCount>0 then
      Pages.Strings[0]:=oisProperties
    else
      Pages.Add(oisProperties);
    Page[0].Name:=DefaultOIPageNames[oipgpProperties];
    Pages.Add(oisEvents);
    Page[1].Name:=DefaultOIPageNames[oipgpEvents];
    PageIndex:=0;
    PopupMenu:=MainPopupMenu;
  end;

  // property grid
  PropertyGrid:=TOICustomPropertyGrid.CreateWithParams(Self,PropertyEditorHook
      ,[tkUnknown, tkInteger, tkChar, tkEnumeration, tkFloat, tkSet{, tkMethod}
      , tkSString, tkLString, tkAString, tkWString, tkVariant
      {, tkArray, tkRecord, tkInterface}, tkClass, tkObject, tkWChar, tkBool
      , tkInt64, tkQWord],
      FDefaultItemHeight);
  with PropertyGrid do begin
    Name:=DefaultOIGridNames[oipgpProperties];
    Parent:=NoteBook.Page[0];
    Selection:=Self.FSelection;
    Align:=alClient;
    PopupMenu:=MainPopupMenu;
    OnModified:=@OnGridModified;
    OnKeyUp:=@OnGriddKeyUp;
  end;

  // event grid
  EventGrid:=TOICustomPropertyGrid.CreateWithParams(Self,PropertyEditorHook,
                                              [tkMethod],FDefaultItemHeight);
  with EventGrid do begin
    Name:=DefaultOIGridNames[oipgpEvents];
    Parent:=NoteBook.Page[1];
    Selection:=Self.FSelection;
    Align:=alClient;
    PopupMenu:=MainPopupMenu;
    OnModified:=@OnGridModified;
    OnKeyUp:=@OnGriddKeyUp;
  end;
  
  CreateFavouritePage;
end;

procedure TObjectInspector.CreateFavouritePage;
var
  NewPage: TPage;
  i: LongInt;
begin
  if FShowFavouritePage then begin
    if FavouriteGrid=nil then begin
      // create favourite page
      NoteBook.Pages.Add(oisFavorites);
      NewPage:=NoteBook.Page[NoteBook.PageCount-1];
      NewPage.Name:=DefaultOIPageNames[oipgpFavourite];

      // create favourite property grid
      FavouriteGrid:=TOICustomPropertyGrid.CreateWithParams(Self,PropertyEditorHook
          ,[tkUnknown, tkInteger, tkChar, tkEnumeration, tkFloat, tkSet, tkMethod
          , tkSString, tkLString, tkAString, tkWString, tkVariant
          {, tkArray, tkRecord, tkInterface}, tkClass, tkObject, tkWChar, tkBool
          , tkInt64, tkQWord],
          FDefaultItemHeight);
      with FavouriteGrid do begin
        Name:=DefaultOIGridNames[oipgpFavourite];
        Parent:=NewPage;
        Selection:=Self.FSelection;
        Align:=alClient;
        PopupMenu:=MainPopupMenu;
        OnModified:=@OnGridModified;
        OnKeyUp:=@OnGriddKeyUp;
      end;
      FavouriteGrid.Favourites:=FFavourites;
    end;
  end else begin
    if FavouriteGrid<>nil then begin
      // free and remove favourite page
      i:=NoteBook.PageList.IndexOf(FavouriteGrid.Parent);
      FreeAndNil(FavouriteGrid);
      if i>=0 then
        NoteBook.Pages.Delete(i);
    end;
  end;
end;

procedure TObjectInspector.KeyDown(var Key: Word; Shift: TShiftState);
var
  CurGrid: TOICustomPropertyGrid;
begin
  CurGrid:=GetActivePropertyGrid;
  if CurGrid<>nil then begin
    CurGrid.HandleStandardKeys(Key,Shift);
    if Key=VK_UNKNOWN then exit;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TObjectInspector.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  if (Key<>VK_UNKNOWN) and Assigned(OnRemainingKeyUp) then
    OnRemainingKeyUp(Self,Key,Shift);
end;

procedure TObjectInspector.OnShowHintPopupMenuItemClick(Sender : TObject);
var
  Page: TObjectInspectorPage;
begin
  for Page:=Low(TObjectInspectorPage) to High(TObjectInspectorPage) do
    if GridControl[Page]<>nil then
      GridControl[Page].ShowHint:=not GridControl[Page].ShowHint;
end;

procedure TObjectInspector.OnShowOptionsPopupMenuItemClick(Sender: TObject);
begin
  if Assigned(FOnShowOptions) then FOnShowOptions(Sender);
end;

procedure TObjectInspector.OnShowComponentTreePopupMenuItemClick(Sender: TObject
  );
begin
  ShowComponentTree:=not ShowComponentTree;
end;

procedure TObjectInspector.OnMainPopupMenuPopup(Sender: TObject);
var
  DefaultStr: String;
  CurGrid: TOICustomPropertyGrid;
  CurRow: TOIPropertyGridRow;
begin
  SetDefaultPopupMenuItem.Enabled:=GetCurRowDefaultValue(DefaultStr);
  if SetDefaultPopupMenuItem.Enabled then
    SetDefaultPopupMenuItem.Caption:=Format(oisSetToDefault, [DefaultStr])
  else
    SetDefaultPopupMenuItem.Caption:=oisSetToDefaultValue;
    
  AddToFavoritesPopupMenuItem.Visible:=(Favourites<>nil)
                and ShowFavouritePage
                and (GetActivePropertyGrid<>FavouriteGrid)
                and Assigned(OnAddToFavourites) and (GetActivePropertyRow<>nil);
  RemoveFromFavoritesPopupMenuItem.Visible:=(Favourites<>nil)
           and ShowFavouritePage
           and (GetActivePropertyGrid=FavouriteGrid)
           and Assigned(OnRemoveFromFavourites) and (GetActivePropertyRow<>nil);

  CurGrid:=GetActivePropertyGrid;
  CurRow:=GetActivePropertyRow;
  if (CurRow<>nil) and (CurRow.Editor.GetVisualValue<>CurGrid.CurrentEditValue)
  then
    UndoPropertyPopupMenuItem.Enabled:=true
  else
    UndoPropertyPopupMenuItem.Enabled:=false;
  ShowHintsPopupMenuItem.Checked:=PropertyGrid.ShowHint;
  if (Selection.Count > 0) and FShowComponentTree then begin
    CutPopupMenuItem.Visible := true;
    CopyPopupMenuItem.Visible := true;
    PastePopupMenuItem.Visible := true;
    DeletePopupMenuItem.visible := true;
    OptionsSeparatorMenuItem2.visible := true;
  end else begin
    CutPopupMenuItem.Visible := false;
    CopyPopupMenuItem.Visible := false;
    PastePopupMenuItem.Visible := false;
    DeletePopupMenuItem.visible := false;
    OptionsSeparatorMenuItem2.visible := false;
  end;
end;

procedure TObjectInspector.HookRefreshPropertyValues;
begin
  RefreshPropertyValues;
end;

procedure TObjectInspector.SetShowFavouritePage(const AValue: boolean);
begin
  if FShowFavouritePage=AValue then exit;
  FShowFavouritePage:=AValue;
  CreateFavouritePage;
end;

function TObjectInspector.GetGridControl(Page: TObjectInspectorPage
  ): TOICustomPropertyGrid;
begin
  case Page of
  oipgpFavourite: Result:=FavouriteGrid;
  oipgpEvents: Result:=EventGrid;
  else  Result:=PropertyGrid;
  end;
end;

procedure TObjectInspector.SetFavourites(const AValue: TOIFavouriteProperties);
begin
  //debugln('TObjectInspector.SetFavourites ',dbgsName(Self));
  if FFavourites=AValue then exit;
  FFavourites:=AValue;
  if FavouriteGrid<>nil then
    FavouriteGrid.Favourites:=FFavourites;
end;

{ TCustomPropertiesGrid }

function TCustomPropertiesGrid.GetTIObject: TPersistent;
begin
  if PropertyEditorHook<>nil then Result:=PropertyEditorHook.LookupRoot;
end;

procedure TCustomPropertiesGrid.SetAutoFreeHook(const AValue: boolean);
begin
  if FAutoFreeHook=AValue then exit;
  FAutoFreeHook:=AValue;
end;

procedure TCustomPropertiesGrid.SetTIObject(const AValue: TPersistent);
var
  NewSelection: TPersistentSelectionList;
begin
  if (TIObject=AValue) then begin
    if ((AValue<>nil) and (Selection.Count=1) and (Selection[0]=AValue))
    or (AValue=nil) then
      exit;
  end;
  if SaveOnChangeTIObject then
    SaveChanges;
  if PropertyEditorHook=nil then
    PropertyEditorHook:=TPropertyEditorHook.Create;
  PropertyEditorHook.LookupRoot:=AValue;
  if (AValue<>nil) and ((Selection.Count<>1) or (Selection[0]<>AValue)) then
  begin
    NewSelection:=TPersistentSelectionList.Create;
    try
      if AValue<>nil then
        NewSelection.Add(AValue);
      Selection:=NewSelection;
    finally
      NewSelection.Free;
    end;
  end;
end;

constructor TCustomPropertiesGrid.Create(TheOwner: TComponent);
var
  Hook: TPropertyEditorHook;
begin
  Hook:=TPropertyEditorHook.Create;
  FSaveOnChangeTIObject:=true;
  FAutoFreeHook:=true;
  CreateWithParams(TheOwner,Hook,AllTypeKinds,25);
end;

destructor TCustomPropertiesGrid.Destroy;
begin
  if FAutoFreeHook then
    FPropertyEditorHook.Free;
  inherited Destroy;
end;

{ TOIFavouriteProperties }

function TOIFavouriteProperties.GetCount: integer;
begin
  Result:=FItems.Count;
end;

function TOIFavouriteProperties.GetItems(Index: integer): TOIFavouriteProperty;
begin
  Result:=TOIFavouriteProperty(FItems[Index]);
end;

constructor TOIFavouriteProperties.Create;
begin
  FItems:=TList.Create;
end;

destructor TOIFavouriteProperties.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TOIFavouriteProperties.Clear;
var
  i: Integer;
begin
  for i:=0 to FItems.Count-1 do
    TObject(FItems[i]).Free;
  FItems.Clear;
  FSorted:=true;
end;

procedure TOIFavouriteProperties.Assign(Src: TOIFavouriteProperties);
var
  i: Integer;
begin
  Clear;
  for i:=0 to Src.Count-1 do
    FItems.Add(Src[i].CreateCopy);
  FModified:=Src.Modified;
  FDoublesDeleted:=Src.DoublesDeleted;
  FSorted:=Src.Sorted;
end;

function TOIFavouriteProperties.CreateCopy: TOIFavouriteProperties;
begin
  Result:=TOIFavouriteProperties.Create;
  Result.Assign(Self);
end;

function TOIFavouriteProperties.Contains(AnItem: TOIFavouriteProperty
  ): Boolean;
var
  i: Integer;
begin
  for i:=Count-1 downto 0 do begin
    if Items[i].Compare(AnItem)=0 then begin
      Result:=true;
      exit;
    end;
  end;
  Result:=false;
end;

procedure TOIFavouriteProperties.Add(NewItem: TOIFavouriteProperty);
begin
  FItems.Add(NewItem);
  FSorted:=(Count<=1)
           or (FSorted and (Items[Count-1].Compare(Items[Count-2])<0));
  FDoublesDeleted:=FSorted
             and ((Count<=1) or (Items[Count-1].Compare(Items[Count-2])<>0));
  Modified:=true;
end;

procedure TOIFavouriteProperties.AddNew(NewItem: TOIFavouriteProperty);
begin
  if Contains(NewItem) then
    NewItem.Free
  else
    Add(NewItem);
end;

procedure TOIFavouriteProperties.Remove(AnItem: TOIFavouriteProperty);
begin
  Modified:=FItems.Remove(AnItem)>=0;
end;

procedure TOIFavouriteProperties.DeleteConstraints(
  AnItem: TOIFavouriteProperty);
// delete all items, that would constrain AnItem
var
  i: Integer;
  CurItem: TOIFavouriteProperty;
begin
  for i:=Count-1 downto 0 do begin
    CurItem:=Items[i];
    if CurItem.Constrains(AnItem) then begin
      FItems.Delete(i);
      Modified:=true;
      CurItem.Free;
    end;
  end;
end;

function TOIFavouriteProperties.IsFavourite(AClass: TPersistentClass;
  const PropertyName: string): boolean;
var
  i: Integer;
  CurItem: TOIFavouriteProperty;
  BestItem: TOIFavouriteProperty;
begin
  if (AClass=nil) or (PropertyName='') then begin
    Result:=false;
    exit;
  end;
  BestItem:=nil;
  for i:=0 to Count-1 do begin
    CurItem:=Items[i];
    if not CurItem.IsFavourite(AClass,PropertyName) then continue;
    if (BestItem=nil)
    or (AClass.InheritsFrom(BestItem.BaseClass)) then begin
      //debugln('TOIFavouriteProperties.IsFavourite ',AClass.ClassName,' ',PropertyName);
      BestItem:=CurItem;
    end;
  end;
  Result:=(BestItem<>nil) and BestItem.Include;
end;

function TOIFavouriteProperties.AreFavourites(
  Selection: TPersistentSelectionList; const PropertyName: string): boolean;
var
  i: Integer;
begin
  Result:=(Selection<>nil) and (Selection.Count>0);
  if not Result then exit;
  for i:=0 to Selection.Count-1 do begin
    if not IsFavourite(TPersistentClass(Selection[i].ClassType),PropertyName)
    then begin
      Result:=false;
      exit;
    end;
  end;
end;

procedure TOIFavouriteProperties.LoadFromConfig(ConfigStore: TConfigStorage;
  const Path: string);
var
  NewCount: LongInt;
  i: Integer;
  NewItem: TOIFavouriteProperty;
  p: String;
  NewPropertyName: String;
  NewInclude: Boolean;
  NewBaseClassname: String;
  NewBaseClass: TPersistentClass;
begin
  Clear;
  NewCount:=ConfigStore.GetValue(Path+'Count',0);
  for i:=0 to NewCount-1 do begin
    p:=Path+'Item'+IntToStr(i)+'/';
    NewPropertyName:=ConfigStore.GetValue(p+'PropertyName','');
    if (NewPropertyName='') or (not IsValidIdent(NewPropertyName)) then
      continue;
    NewInclude:=ConfigStore.GetValue(p+'Include',true);
    NewBaseClassname:=ConfigStore.GetValue(p+'BaseClass','');
    if (NewBaseClassname='') or (not IsValidIdent(NewBaseClassname))  then
      continue;
    NewBaseClass:=GetClass(NewBaseClassname);
    NewItem:=TOIFavouriteProperty.Create(NewBaseClass,NewPropertyName,
                                         NewInclude);
    NewItem.BaseClassName:=NewBaseClassname;
    Add(NewItem);
  end;
  {$IFDEF DebugFavouriteroperties}
  debugln('TOIFavouriteProperties.LoadFromConfig END');
  WriteDebugReport;
  {$ENDIF}
end;

procedure TOIFavouriteProperties.SaveToConfig(ConfigStore: TConfigStorage;
  const Path: string);
var
  i: Integer;
begin
  ConfigStore.SetDeleteValue(Path+'Count',Count,0);
  for i:=0 to Count-1 do
    Items[i].SaveToConfig(ConfigStore,Path+'Item'+IntToStr(i)+'/');
end;

procedure TOIFavouriteProperties.MergeConfig(ConfigStore: TConfigStorage;
  const Path: string);
var
  NewFavourites: TOIFavouriteProperties;
  OldItem: TOIFavouriteProperty;
  NewItem: TOIFavouriteProperty;
  cmp: LongInt;
  NewIndex: Integer;
  OldIndex: Integer;
begin
  NewFavourites:=TOIFavouritePropertiesClass(ClassType).Create;
  {$IFDEF DebugFavouriteroperties}
  debugln('TOIFavouriteProperties.MergeConfig ',dbgsName(NewFavourites),' ',dbgsName(NewFavourites.FItems));
  {$ENDIF}
  try
    // load config
    NewFavourites.LoadFromConfig(ConfigStore,Path);
    // sort both to see the differences
    NewFavourites.DeleteDoubles; // descending
    DeleteDoubles;               // descending
    // add all new things from NewFavourites
    NewIndex:=0;
    OldIndex:=0;
    while (NewIndex<NewFavourites.Count) do begin
      NewItem:=NewFavourites[NewIndex];
      if OldIndex>=Count then begin
        // item only exists in config -> move to this list
        NewFavourites.FItems[NewIndex]:=nil;
        inc(NewIndex);
        FItems.Insert(OldIndex,NewItem);
        inc(OldIndex);
      end else begin
        OldItem:=Items[OldIndex];
        cmp:=OldItem.Compare(NewItem);
        //debugln('TOIFavouriteProperties.MergeConfig cmp=',dbgs(cmp),' OldItem=[',OldItem.DebugReportAsString,'] NewItem=[',NewItem.DebugReportAsString,']');
        if cmp=0 then begin
          // item already exists in this list
          inc(NewIndex);
          inc(OldIndex);
        end else if cmp<0 then begin
          // item exists only in old favourites
          // -> next old
          inc(OldIndex);
        end else begin
          // item only exists in config -> move to this list
          NewFavourites.FItems[NewIndex]:=nil;
          inc(NewIndex);
          FItems.Insert(OldIndex,NewItem);
          inc(OldIndex);
        end;
      end;
    end;
  finally
    NewFavourites.Free;
  end;
  {$IFDEF DebugFavouriteroperties}
  debugln('TOIFavouriteProperties.MergeConfig END');
  WriteDebugReport;
  {$ENDIF}
end;

procedure TOIFavouriteProperties.SaveNewItemsToConfig(
  ConfigStore: TConfigStorage; const Path: string;
  BaseFavourites: TOIFavouriteProperties);
// Save all items, that are in this list and not in BaseFavourites
// It does not save, if an item in BaseFavourites is missing in this list
var
  SubtractList: TList;
  i: Integer;
  CurItem: TOIFavouriteProperty;
begin
  SubtractList:=GetSubtractList(BaseFavourites);
  try
    ConfigStore.SetDeleteValue(Path+'Count',SubtractList.Count,0);
    {$IFDEF DebugFavouriteroperties}
    debugln('TOIFavouriteProperties.SaveNewItemsToConfig A Count=',dbgs(SubtractList.Count));
    {$ENDIF}
    for i:=0 to SubtractList.Count-1 do begin
      CurItem:=TOIFavouriteProperty(SubtractList[i]);
      CurItem.SaveToConfig(ConfigStore,Path+'Item'+IntToStr(i)+'/');
      {$IFDEF DebugFavouriteroperties}
      debugln(' i=',dbgs(i),' ',CurItem.DebugReportAsString);
      {$ENDIF}
    end;
  finally
    SubtractList.Free;
  end;
end;

procedure TOIFavouriteProperties.Sort;
begin
  if FSorted then exit;
  FItems.Sort(@CompareOIFavouriteProperties);
end;

procedure TOIFavouriteProperties.DeleteDoubles;
// This also sorts
var
  i: Integer;
begin
  if FDoublesDeleted then exit;
  Sort;
  for i:=Count-1 downto 1 do begin
    if Items[i].Compare(Items[i-1])=0 then begin
      Items[i].Free;
      FItems.Delete(i);
    end;
  end;
  FDoublesDeleted:=true;
end;

function TOIFavouriteProperties.IsEqual(TheFavourites: TOIFavouriteProperties
  ): boolean;
var
  i: Integer;
begin
  Result:=false;
  DeleteDoubles;
  TheFavourites.DeleteDoubles;
  if Count<>TheFavourites.Count then exit;
  for i:=Count-1 downto 1 do
    if Items[i].Compare(TheFavourites.Items[i])<>0 then exit;
  Result:=true;
end;

function TOIFavouriteProperties.GetSubtractList(
  FavouritesToSubtract: TOIFavouriteProperties): TList;
// create a list of TOIFavouriteProperty of all items in this list
// and not in FavouritesToSubtract
var
  SelfIndex: Integer;
  SubtractIndex: Integer;
  CurItem: TOIFavouriteProperty;
  cmp: LongInt;
begin
  Result:=TList. Create;
  DeleteDoubles; // this also sorts descending
  FavouritesToSubtract.DeleteDoubles; // this also sorts descending
  SelfIndex:=0;
  SubtractIndex:=0;
  while SelfIndex<Count do begin
    CurItem:=Items[SelfIndex];
    if SubtractIndex>=FavouritesToSubtract.Count then begin
      // item does not exist in SubtractIndex -> add it
      Result.Add(CurItem);
      inc(SelfIndex);
    end else begin
      cmp:=CurItem.Compare(FavouritesToSubtract[SubtractIndex]);
      //debugln('TOIFavouriteProperties.GetSubtractList cmp=',dbgs(cmp),' CurItem=[',CurItem.DebugReportAsString,'] SubtractItem=[',FavouritesToSubtract[SubtractIndex].DebugReportAsString,']');
      if cmp=0 then begin
        // item exists in SubtractIndex -> skip
        inc(SubtractIndex);
        inc(SelfIndex);
      end else if cmp>0 then begin
        // item does not exist in FavouritesToSubtract -> add it
        Result.Add(CurItem);
        inc(SelfIndex);
      end else begin
        // item exists only in FavouritesToSubtract -> skip
        inc(SubtractIndex);
      end;
    end;
  end;
end;

procedure TOIFavouriteProperties.WriteDebugReport;
var
  i: Integer;
begin
  debugln('TOIFavouriteProperties.WriteDebugReport Count=',dbgs(Count));
  for i:=0 to Count-1 do
    debugln('  i=',dbgs(i),' ',Items[i].DebugReportAsString);
end;

{ TOIFavouriteProperty }

constructor TOIFavouriteProperty.Create(ABaseClass: TPersistentClass;
  const APropertyName: string; TheInclude: boolean);
begin
  BaseClass:=ABaseClass;
  PropertyName:=APropertyName;
  Include:=TheInclude;
end;

function TOIFavouriteProperty.Constrains(AnItem: TOIFavouriteProperty
  ): boolean;
// true if this item constrains AnItem
// This item constrains AnItem, if this is the opposite (Include) and
// AnItem has the same or greater scope
begin
  Result:=(Include<>AnItem.Include)
          and (CompareText(PropertyName,AnItem.PropertyName)=0)
          and (BaseClass.InheritsFrom(AnItem.BaseClass));
end;

function TOIFavouriteProperty.IsFavourite(AClass: TPersistentClass;
  const APropertyName: string): boolean;
begin
  Result:=(CompareText(PropertyName,APropertyName)=0)
          and (AClass.InheritsFrom(BaseClass));
end;

function TOIFavouriteProperty.Compare(AFavourite: TOIFavouriteProperty
  ): integer;
  
  function CompareBaseClass: integer;
  begin
    if BaseClass<>nil then begin
      if AFavourite.BaseClass<>nil then
        Result:=ComparePointers(BaseClass,AFavourite.BaseClass)
      else
        Result:=CompareText(BaseClass.ClassName,AFavourite.BaseClassName);
    end else begin
      if AFavourite.BaseClass<>nil then
        Result:=CompareText(BaseClassName,AFavourite.BaseClass.ClassName)
      else
        Result:=CompareText(BaseClassName,AFavourite.BaseClassName);
    end;
  end;

begin
  // first compare PropertyName
  Result:=CompareText(PropertyName,AFavourite.PropertyName);
  if Result<>0 then exit;
  // then compare Include
  if Include<>AFavourite.Include then begin
    if Include then
      Result:=1
    else
      Result:=-1;
    exit;
  end;
  // then compare BaseClass and BaseClassName
  Result:=CompareBaseClass;
end;

procedure TOIFavouriteProperty.SaveToConfig(ConfigStore: TConfigStorage;
  const Path: string);
begin
  if BaseClass<>nil then
    ConfigStore.SetDeleteValue(Path+'BaseClass',BaseClass.ClassName,'')
  else
    ConfigStore.SetDeleteValue(Path+'BaseClass',BaseClassName,'');
  ConfigStore.SetDeleteValue(Path+'PropertyName',PropertyName,'');
  ConfigStore.SetDeleteValue(Path+'Include',Include,true);
end;

procedure TOIFavouriteProperty.Assign(Src: TOIFavouriteProperty);
begin
  BaseClassName:=Src.BaseClassName;
  BaseClass:=Src.BaseClass;
  PropertyName:=Src.PropertyName;
  Include:=Src.Include;
end;

function TOIFavouriteProperty.CreateCopy: TOIFavouriteProperty;
begin
  Result:=TOIFavouriteProperty.Create(BaseClass,PropertyName,Include);
  Result.BaseClass:=BaseClass;
end;

function TOIFavouriteProperty.DebugReportAsString: string;
begin
  Result:='PropertyName="'+PropertyName+'"'
      +' Include='+dbgs(Include)
      +' BaseClassName="'+BaseClassName+'"'
      +' BaseClass='+dbgsName(BaseClass);
end;

end.

