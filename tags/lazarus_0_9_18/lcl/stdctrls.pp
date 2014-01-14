{
 /***************************************************************************
                               stdctrls.pp
                               -----------

                   Initial Revision : Tue Oct 19 CST 1999

 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

unit StdCtrls;

{$mode objfpc}{$H+}
{off $Define NewCheckBox}

interface


uses
  Classes, SysUtils, LCLStrConsts, LCLType, LCLProc, LMessages, Graphics,
  GraphType, GraphMath, ExtendedStrings, LCLIntf, ClipBrd, ActnList, Controls,
  Forms;

type

  { TScrollBar }

  TScrollStyle = (ssNone, ssHorizontal, ssVertical, ssBoth,
    ssAutoHorizontal, ssAutoVertical, ssAutoBoth);

  TScrollCode = (
    // !!! Beware. The position of these enums must correspond to the SB_xxx
    // values in LCLType  (Delphi compatibility, not our decision)
    // MWE: Don't know it this still is a requirement
    //      afaik have I remeved all casts from the LCL
    scLineUp,   // = SB_LINEUP
    scLineDown, // = SB_LINEDOWN
    scPageUp,   // = SB_PAGEUP
    scPageDown, // = SB_PAGEDOWN
    scPosition, // = SB_THUMBPOSITION
    scTrack,    // = SB_THUMBTRACK
    scTop,      // = SB_TOP
    scBottom,   // = SB_BOTTOM
    scEndScroll // = SB_ENDSCROLL
    );

  TScrollEvent = procedure(Sender: TObject; ScrollCode: TScrollCode;
                           var ScrollPos: Integer) of object;

  TCustomScrollBar = class(TWinControl)
  private
    FKind: TScrollBarKind;
    FPosition: Integer;
    FMin: Integer;
    FMax: Integer;
    FPageSize: Integer;
    FRTLFactor: Integer;
    FSmallChange: TScrollBarInc;
    FLargeChange: TScrollBarInc;
    FOnChange: TNotifyEvent;
    FOnScroll: TScrollEvent;
    procedure DoScroll(var Message: TLMScroll);
    function NotRightToLeft: Boolean;
    procedure SetKind(Value: TScrollBarKind);
    procedure SetMax(Value: Integer);
    procedure SetMin(Value: Integer);
    procedure SetPosition(Value: Integer);
    procedure SetPageSize(Value: Integer);
    procedure CNHScroll(var Message: TLMHScroll); message LM_HSCROLL;
    procedure CNVScroll(var Message: TLMVScroll); message LM_VSCROLL;
    procedure CNCtlColorScrollBar(var Message: TLMessage); message CN_CTLCOLORSCROLLBAR;
    procedure WMEraseBkgnd(var Message: TLMEraseBkgnd); message LM_ERASEBKGND;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Change; dynamic;
    procedure Scroll(ScrollCode: TScrollCode; var ScrollPos: Integer); dynamic;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetParams(APosition, AMin, AMax: Integer);
  public
    property Kind: TScrollBarKind read FKind write SetKind default sbHorizontal;
    property LargeChange: TScrollBarInc read FLargeChange write FLargeChange default 1;
    property Max: Integer read FMax write SetMax default 100;
    property Min: Integer read FMin write SetMin default 0;
    property PageSize: Integer read FPageSize write SetPageSize;
    property Position: Integer read FPosition write SetPosition default 0;
    property SmallChange: TScrollBarInc read FSmallChange write FSmallChange default 1;
    property TabStop default true;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnScroll: TScrollEvent read FOnScroll write FOnScroll;
  end;


  { TScrollBar }

  TScrollBar = class(TCustomScrollBar)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Kind;
    property LargeChange;
    property Max;
    property Min;
    property PageSize;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property Position;
    property ShowHint;
    property SmallChange;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChange;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnScroll;
    property OnStartDrag;
  end;


  { TCustomGroupBox }

  TCustomGroupBox = class (TWinControl) {class(TCustomControl) }
  protected
  public
    constructor Create(AOwner: TComponent); Override;
    function CanTab: boolean; override;
  end;


  { TGroupBox }

  TGroupBox = class(TCustomGroupBox)
  published
    property Align;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property Caption;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property Ctl3D;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChangeBounds;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDockDrop;
    property OnDockOver;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
  end;


  { TCustomComboBox }
  TComboBoxAutoCompleteTextOption = (
    cbactEnabled,//Enable Auto-Completion Feature
    cbactEndOfLineComplete,//Perform Auto-Complete only when cursor is at end of line
    cbactRetainPrefixCase,//Retains the case of characters user has typed if is cbactEndOfLineComplete
    cbactSearchCaseSensitive,//Search Text with CaseSensitivity
    cbactSearchAscending//Search Text from top of the list
    );
  TComboBoxAutoCompleteText = set of TComboBoxAutoCompleteTextOption;

  TComboBoxStyle = (csDropDown, csSimple, csDropDownList, csOwnerDrawFixed,
                    csOwnerDrawVariable);

  TOwnerDrawState = TBaseOwnerDrawState;

  TDrawItemEvent = procedure(Control: TWinControl; Index: Integer;
                             ARect: TRect; State: TOwnerDrawState) of object;
  TMeasureItemEvent = procedure(Control: TWinControl; Index: Integer;
                                var Height: Integer) of object;

  { TCustomComboBox }

  TCustomComboBox = class(TWinControl)
  private
    FAutoCompleteText: TComboBoxAutoCompleteText;
    FAutoDropDown: Boolean;
    FCanvas: TCanvas;
    FDropDownCount: Integer;
    FDroppedDown: boolean;
    FItemHeight: integer;
    FItemIndex: integer;
    FItemWidth: integer;
    FItems: TStrings;
    fMaxLength: integer;
    FOnChange: TNotifyEvent;
    FOnCloseUp: TNotifyEvent;
    FOnDrawItem: TDrawItemEvent;
    FOnDropDown: TNotifyEvent;
    FOnMeasureItem: TMeasureItemEvent;
    FOnSelect: TNotifyEvent;
    FReadOnly: Boolean;
    FSelLength: integer;
    FSelStart: integer;
    FSorted: boolean;
    FStyle: TComboBoxStyle;
    FArrowKeysTraverseList: Boolean;
    FReturnArrowState: Boolean; //used to return the state of arrow keys from termporary change
    function GetAutoComplete: boolean;
    function GetDroppedDown: Boolean;
    function GetItemWidth: Integer;
    procedure SetAutoComplete(const AValue: boolean);
    procedure SetItemWidth(const AValue: Integer);
    procedure SetItems(Value: TStrings);
    procedure LMDrawListItem(var TheMessage: TLMDrawListItem); message LM_DrawListItem;
    procedure LMMeasureItem(var TheMessage: TLMMeasureItem); message LM_MeasureItem;
    procedure LMSelChange(var TheMessage); message LM_SelChange;
    procedure CNCommand(var TheMessage: TLMCommand); message CN_Command;
    procedure SetReadOnly(const AValue: Boolean);
    procedure UpdateSorted;
    procedure SetArrowKeysTraverseList(Value: Boolean);
    procedure WMChar(var Message: TLMChar); message LM_CHAR;
  protected
    procedure InitializeWnd; override;
    procedure DestroyWnd; override;
    procedure DrawItem(Index: Integer; ARect: TRect;
                       State: TOwnerDrawState); virtual;
    procedure LMChanged(var Msg); message LM_CHANGED;
    procedure Change; dynamic;
    procedure Select; dynamic;
    procedure DropDown; dynamic;
    procedure CloseUp; dynamic;
    procedure AdjustDropDown; virtual;

    function GetItemCount: Integer; //override;
    function GetItemHeight: Integer; virtual;
    function GetSelLength: integer; virtual;
    function GetSelStart: integer; virtual;
    function GetSelText: string; virtual;
    function GetItemIndex: integer; virtual;
    function GetMaxLength: integer; virtual;
    function IsReadOnlyStored: boolean;
    procedure SetDropDownCount(const AValue: Integer); virtual;
    procedure SetDroppedDown(const AValue: Boolean); virtual;
    procedure SetItemHeight(const AValue: Integer); virtual;
    procedure SetItemIndex(Val: integer); virtual;
    procedure SetMaxLength(Val: integer); virtual;
    procedure SetSelLength(Val: integer); virtual;
    procedure SetSelStart(Val: integer); virtual;
    procedure SetSelText(const Val: string); virtual;
    procedure SetSorted(Val: boolean); virtual;
    procedure SetStyle(Val: TComboBoxStyle); virtual;
    procedure RealSetText(const AValue: TCaption); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure MouseUp(Button: TMouseButton; Shift:TShiftState; X, Y: Integer); override;
    function SelectItem(const AnItem: String): Boolean;

    property DropDownCount: Integer read FDropDownCount write SetDropDownCount default 8;
    property ItemHeight: Integer read GetItemHeight write SetItemHeight;
    property ItemWidth: Integer read GetItemWidth write SetItemWidth;
    property MaxLength: integer read GetMaxLength write SetMaxLength default -1;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnCloseUp: TNotifyEvent read FOnCloseUp write FOnCloseUp;
    property OnDrawItem: TDrawItemEvent read FOnDrawItem write FOnDrawItem;
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
    property OnMeasureItem: TMeasureItemEvent
      read FOnMeasureItem write FOnMeasureItem;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
    property Sorted: boolean read FSorted write SetSorted;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddItem(const Item: String; AnObject: TObject); //override;
    procedure AddHistoryItem(const Item: string; MaxHistoryCount: integer;
                             SetAsText, CaseSensitive: boolean);
    procedure AddHistoryItem(const Item: string; AnObject: TObject;
                   MaxHistoryCount: integer; SetAsText, CaseSensitive: boolean);
    procedure Clear; virtual;
    procedure ClearSelection; //override;
    property DroppedDown: Boolean read GetDroppedDown write SetDroppedDown;
    procedure MeasureItem(Index: Integer; var TheHeight: Integer); virtual;
    procedure SelectAll;
    property AutoComplete: boolean read GetAutoComplete write SetAutoComplete;
    property AutoCompleteText: TComboBoxAutoCompleteText
                           read FAutoCompleteText write FAutoCompleteText;
    property AutoDropDown: Boolean
                           read FAutoDropDown write FAutoDropDown default False;
    property ArrowKeysTraverseList: Boolean read FArrowKeysTraverseList
                                    write SetArrowKeysTraverseList default True;
    property Canvas: TCanvas read FCanvas;
    property Items: TStrings read FItems write SetItems;
    property ItemIndex: integer read GetItemIndex write SetItemIndex default -1;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly stored IsReadOnlyStored;
    property SelLength: integer read GetSelLength write SetSelLength;
    property SelStart: integer read GetSelStart write SetSelStart;
    property SelText: String read GetSelText write SetSelText;
    property Style: TComboBoxStyle read FStyle write SetStyle;
    property Text;
  published
    property TabStop default true;
  end;


  { TComboBox }

  TComboBox = class(TCustomComboBox)
  published
    property Align;
    property Anchors;
    property ArrowKeysTraverseList;
    property AutoComplete;
    property AutoCompleteText;
    property AutoDropDown;
    property BorderSpacing;
    property Ctl3D;
    property DropDownCount;
    property Enabled;
    property Font;
    property ItemHeight;
    property ItemIndex;
    property Items;
    property ItemWidth;
    property MaxLength;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnCloseUp;
    property OnDblClick;
    property OnDrawItem;
    property OnDropDown;
    property OnEditingDone;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnSelect;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property Sorted;
    property Style;
    property TabOrder;
    property TabStop;
    property Text;
    property Visible;
  end;


  { TCustomListBox }

  TListBoxStyle = (lbStandard, lbOwnerDrawFixed, lbOwnerDrawVariable);
  TSelectionChangeEvent = procedure(Sender: TObject; User: boolean) of object;

  { TCustomListBox }

  TCustomListBox = class(TWinControl)
  private
    FCacheValid: Boolean;
    FCanvas: TCanvas;
    FClickOnSelChange: boolean;
    FClickTriggeredBySelectionChange: Boolean;
    FExtendedSelect: boolean;
    FIntegralHeight: boolean;
    FItemHeight: Integer;
    FItemIndex: integer;
    FItems: TStrings;
    FLockSelectionChange: integer;
    FMultiSelect: boolean;
    FOnDrawItem: TDrawItemEvent;
    FOnMeasureItem: TMeasureItemEvent;
    FOnSelectionChange: TSelectionChangeEvent;
    FSorted: boolean;
    FStyle: TListBoxStyle;
    FTopIndex: integer;
    function GetTopIndex: Integer;
    procedure SetTopIndex(const AValue: Integer);
    procedure UpdateSelectionMode;
    procedure UpdateSorted;
    procedure LMDrawListItem(var TheMessage: TLMDrawListItem); message LM_DrawListItem;
    procedure LMMeasureItem(var TheMessage: TLMMeasureItem); message LM_MeasureItem;
    procedure LMSelChange(var TheMessage); message LM_SelChange;
    procedure WMLButtonUp(Var Message: TLMLButtonUp); message LM_LBUTTONUP;
    procedure SendItemSelected(Index: integer; IsSelected: boolean);
  protected
    procedure AssignItemDataToCache(const AIndex: Integer; const AData: Pointer); virtual; // called to store item data while the handle isn't created
    procedure AssignCacheToItemData(const AIndex: Integer; const AData: Pointer); virtual; // called to restore the itemdata after a handle is created
    procedure Loaded; override;
    procedure InitializeWnd; override;
    procedure FinalizeWnd; override;
    procedure CheckIndex(const AIndex: Integer);
    function GetItemHeight: Integer;
    function GetItemIndex: integer; virtual;
    function GetSelCount: integer;
    function GetSelected(Index: integer): boolean;
    function GetCachedDataSize: Integer; virtual; // returns the amount of data needed per item
    function GetCachedData(const AIndex: Integer): Pointer;
    procedure SetExtendedSelect(Val: boolean); virtual;
    procedure SetItemIndex(Val: integer); virtual;
    procedure SetItems(Value: TStrings); virtual;
    procedure SetItemHeight(Value: Integer);
    procedure SetMultiSelect(Val: boolean); virtual;
    procedure SetSelected(Index: integer; Val: boolean);
    procedure SetSorted(Val: boolean); virtual;
    procedure SetStyle(Val: TListBoxStyle); virtual;
    procedure DrawItem(Index: Integer; ARect: TRect;
      State: TOwnerDrawState); virtual;
    procedure DoSelectionChange(User: Boolean); virtual;
    procedure SendItemIndex;
  protected
    property OnMeasureItem: TMeasureItemEvent
                                       read FOnMeasureItem write FOnMeasureItem;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function GetIndexAtY(Y: integer): integer;
    function GetSelectedText: string;
    function ItemAtPos(const Pos: TPoint; Existing: Boolean): Integer;
    function ItemRect(Index: Integer): TRect;
    function ItemVisible(Index: Integer): boolean;
    function ItemFullyVisible(Index: Integer): boolean;
    procedure MakeCurrentVisible;
    procedure MeasureItem(Index: Integer; var TheHeight: Integer); virtual;
    procedure Clear; virtual;
    procedure LockSelectionChange;
    procedure UnlockSelectionChange;
    procedure Click; override; // make it public
  public
    property Align;
    property Anchors;
    property BorderStyle default bsSingle;
    property Canvas: TCanvas read FCanvas;
    property ClickOnSelChange: boolean read FClickOnSelChange
               write FClickOnSelChange default true; // true is Delphi behaviour
    property Constraints;
    property ExtendedSelect: boolean read FExtendedSelect write SetExtendedSelect default true;
    property Font;
    property IntegralHeight: boolean read FIntegralHeight write FIntegralHeight; // not implemented
    property ItemHeight: Integer read GetItemHeight write SetItemHeight;
    property ItemIndex: integer read GetItemIndex write SetItemIndex;
    property Items: TStrings read FItems write SetItems;
    property MultiSelect: boolean read FMultiSelect write SetMultiSelect;
    property OnChangeBounds;
    property OnClick;
    property OnDblClick;
    property OnDrawItem: TDrawItemEvent read FOnDrawItem write FOnDrawItem;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnSelectionChange: TSelectionChangeEvent read FOnSelectionChange
                                                      write FOnSelectionChange;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property SelCount: integer read GetSelCount;
    property Selected[Index: integer]: boolean read GetSelected write SetSelected;
    property ShowHint;
    property Sorted: boolean read FSorted write SetSorted;
    property Style: TListBoxStyle read FStyle write SetStyle;
    property TabOrder;
    property TabStop default true;
    property TopIndex: Integer read GetTopIndex write SetTopIndex;
    property Visible;
  end;


  { TListBox }

  TListBox = class(TCustomListBox)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property BorderStyle;
    property ClickOnSelChange;
    property Color;
    property Constraints;
    property ExtendedSelect;
    property Enabled;
    property Font;
    property IntegralHeight;
    property Items;
    property ItemHeight;
    property MultiSelect;
    property OnChangeBounds;
    property OnClick;
    property OnDblClick;
    property OnDrawItem;
    property OnEnter;
    property OnExit;
    property OnKeyPress;
    property OnKeyDown;
    property OnKeyUp;
    property OnMouseMove;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnSelectionChange;
    property OnShowHint;
    property ParentShowHint;
    property ParentFont;
    property PopupMenu;
    property ShowHint;
    property Sorted;
    property Style;
    property TabOrder;
    property TabStop;
    property TopIndex;
    property Visible;
  end;


  { TCustomEdit }

  TEditCharCase = (ecNormal, ecUppercase, ecLowerCase);
  TEchoMode = (emNormal, emNone, emPassword);

  { TCustomEdit }

  TCustomEdit = class(TWinControl)
  private
    FCharCase: TEditCharCase;
    FEchoMode: TEchoMode;
    FMaxLength: Integer;
    FModified: Boolean;
    FPasswordChar: Char;
    FReadOnly: Boolean;
    FOnChange: TNotifyEvent;
    FSelLength: integer;
    FSelStart: integer;
    function GetModified: Boolean;
    procedure SetCharCase(Value: TEditCharCase);
    procedure SetMaxLength(Value: Integer);
    procedure SetModified(Value: Boolean);
    procedure SetPasswordChar(const AValue: Char);
    procedure SetReadOnly(Value: Boolean);
  protected
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: integer;
                                     WithThemeSpace: Boolean); override;
    procedure CreateWnd; override;
    procedure TextChanged; override;
    procedure Change; dynamic;
    function GetSelLength: integer; virtual;
    function GetSelStart: integer; virtual;
    function GetSelText: string; virtual;
    procedure InitializeWnd; override;
    procedure SetEchoMode(Val: TEchoMode); virtual;
    procedure SetSelLength(Val: integer); virtual;
    procedure SetSelStart(Val: integer); virtual;
    procedure SetSelText(const Val: string); virtual;
    procedure RealSetText(const Value: TCaption); override;
    function ChildClassAllowed(ChildClass: TClass): boolean; override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure WMChar(var Message: TLMChar); message LM_CHAR;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Clear;
    procedure SelectAll;
    procedure ClearSelection; virtual;
    procedure CopyToClipboard; virtual;
    procedure CutToClipboard; virtual;
    procedure PasteFromClipboard; virtual;
  public
    property BorderStyle;
    property CharCase: TEditCharCase read FCharCase write SetCharCase default ecNormal;
    property EchoMode: TEchoMode read FEchoMode write SetEchoMode default emNormal;
    property MaxLength: Integer read FMaxLength write SetMaxLength default -1;
    property Modified: Boolean read GetModified write SetModified;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property PasswordChar: Char read FPasswordChar write SetPasswordChar default #0;
    property PopupMenu;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default false;
    property SelLength: integer read GetSelLength write SetSelLength;
    property SelStart: integer read GetSelStart write SetSelStart;
    property SelText: String read GetSelText write SetSelText;
    property TabOrder;
    property TabStop default true;
    property Text;
  end;


  { TMemoScrollbar }

  TMemoScrollbar = class(TControlScrollBar)
  protected
    function GetHorzScrollBar: TControlScrollBar; override;
    function GetVertScrollBar: TControlScrollBar; override;
  public
    property Increment;
    property Page;
    property Smooth;
    property Position;
    property Range;
    property Size;
    property Visible;
  end;


  { TCustomMemo }

  TCustomMemo = class(TCustomEdit)
  private
    FHorzScrollBar: TMemoScrollBar;
    FLines: TStrings;
    FScrollBars: TScrollStyle;
    FVertScrollBar: TMemoScrollBar;
    FWantTabs: boolean;
    FWordWrap: Boolean;
    procedure SetHorzScrollBar(const AValue: TMemoScrollBar);
    procedure SetVertScrollBar(const AValue: TMemoScrollBar);
    function StoreScrollBars: boolean;
  protected
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
    function  RealGetText: TCaption; override;
    procedure RealSetText(const Value: TCaption); override;
    function GetCachedText(var CachedText: TCaption): boolean; override;
    procedure SetLines(const Value: TStrings);
    procedure SetWantTabs(const NewWantTabs: boolean);
    procedure SetWordWrap(const Value: boolean);
    procedure SetScrollBars(const Value: TScrollStyle);
    procedure Loaded; override;
    function WordWrapIsStored: boolean; virtual;
    procedure ControlKeyDown(var Key: Word; Shift: TShiftState); override;

    property WantTabs: boolean read FWantTabs write SetWantTabs default false;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Append(const Value: String);
  public
    property Lines: TStrings read FLines write SetLines;
    property ScrollBars: TScrollStyle read FScrollBars write SetScrollBars;
    property WordWrap: Boolean read FWordWrap write SetWordWrap stored WordWrapIsStored default true;
    //property Font: TFont read FFont write FFont;
    property HorzScrollBar: TMemoScrollBar
      read FHorzScrollBar write SetHorzScrollBar stored StoreScrollBars;
    property VertScrollBar: TMemoScrollBar
      read FVertScrollBar write SetVertScrollBar stored StoreScrollBars;
  end;


  { TEdit }

  TEdit = class(TCustomEdit)
  published
    property Action;
    property Align;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property Color;
    property Constraints;
    property CharCase;
    property DragMode;
    property EchoMode;
    property Enabled;
    property Font;
    property MaxLength;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnEditingDone;
    property OnEnter;
    property OnExit;
    Property OnKeyDown;
    property OnKeyPress;
    Property OnKeyUp;
    Property OnMouseDown;
    Property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property ParentFont;
    property ParentShowHint;
    property PasswordChar;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property TabStop;
    property TabOrder;
    property Text;
    property Visible;
  end;


  { TMemo }

  TMemo = class(TCustomMemo)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Color;
    property Constraints;
    property Font;
    property Lines;
    property MaxLength;
    property OnChange;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
    property OnMouseEnter;
    property OnMouseLeave;
    property ParentFont;
    property PopupMenu;
    property ReadOnly;
    property ScrollBars;
    property TabOrder;
    property TabStop;
    property Visible;
    property WantTabs;
    property WordWrap;
  end;


  { TCustomStaticText }

  TStaticBorderStyle = (sbsNone, sbsSingle, sbsSunken);

  TCustomStaticText = class(TWinControl)
  private
    FAlignment: TAlignment;
    FFocusControl: TWinControl;
    FShowAccelChar: boolean;
    FStaticBorderStyle: TStaticBorderStyle;
    procedure SetAlignment(Value: TAlignment);
    procedure SetStaticBorderStyle(Value: TStaticBorderStyle);
    procedure WMActivate(var Message: TLMActivate); message LM_ACTIVATE;
  protected
    function GetLabelText: String ; virtual;
    procedure RealSetText(const AValue: TCaption); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetFocusControl(Val: TWinControl); virtual;
    procedure SetShowAccelChar(Val: boolean); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property BorderStyle: TStaticBorderStyle read FStaticBorderStyle write SetStaticBorderStyle default sbsNone;
    property FocusControl: TWinControl read FFocusControl write SetFocusControl;
    property ShowAccelChar: boolean read FShowAccelChar write SetShowAccelChar default true;
  end;


  { TStaticText }

  TStaticText = class(TCustomStaticText)
  published
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property BorderStyle;
    property Caption;
    property Color;
    property Constraints;
    property FocusControl;
    property Font;
    property OnChangeBounds;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property ParentFont;
    property ShowAccelChar;
    property Visible;
  end;


  { TButtonControl }

  TButtonControl = class(TWinControl)
  private
    FClicksDisabled: Boolean;
    FOnChange: TNotifyEvent;
    FUseOnChange: boolean;
    function IsCheckedStored: boolean;
    function UseOnChangeIsStored: boolean;
  protected
    fLastCheckedOnChange: boolean;
    function GetChecked: Boolean; virtual;
    procedure SetChecked(Value: Boolean); virtual;
    procedure DoOnChange; virtual;
    procedure Click; override;
    function ColorIsStored: boolean; override;
    procedure Loaded; override;
  protected
    property Checked: Boolean read GetChecked write SetChecked stored IsCheckedStored default False;
    property ClicksDisabled: Boolean read FClicksDisabled write FClicksDisabled;
    property UseOnChange: boolean read FUseOnChange write FUseOnChange stored UseOnChangeIsStored;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(TheOwner: TComponent); override;
  end;

  { TButtonActionLink - Finish me }

  TButtonActionLink = class(TWinControlActionLink)
  protected
    FClientButton: TButtonControl;
    procedure AssignClient(AClient: TObject); override;
    function IsCheckedLinked: Boolean; override;
    procedure SetChecked(Value: Boolean); override;
  end;

  TButtonActionLinkClass = class of TButtonActionLink;


  { TCustomCheckBox }

  // ToDo: delete TLeftRight when in classesh.inc
  TLeftRight = taLeftJustify..taRightJustify;

  TCheckBoxState = (cbUnchecked, cbChecked, cbGrayed);

  { TCustomCheckBox }

  TCustomCheckBox = class(TButtonControl)
  private
    FAllowGrayed: Boolean;
    FState: TCheckBoxState;
    FShortCut: TShortcut;
    procedure SetState(Value: TCheckBoxState);
    function GetState: TCheckBoxState;
    procedure DoChange(var Msg); message LM_CHANGED;
  protected
    function RetrieveState: TCheckBoxState;
    procedure InitializeWnd; override;
    procedure Toggle; virtual;
    function DialogChar(var Message: TLMKey): boolean; override;
    function GetChecked: Boolean; override;
    procedure SetChecked(Value: Boolean); override;
    procedure RealSetText(const Value: TCaption); override;
    procedure ApplyChanges; virtual;
    procedure Loaded; override;
  public
    constructor Create(TheOwner: TComponent); override;
  public
    property AutoSize default true;
    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed default false;
    property State: TCheckBoxState read GetState write SetState;
    property TabStop default true;
    property UseOnChange;
    property OnChange;
  end;

{$IFNDef NewCheckBox}
  // Normal checkbox
  TCheckBox = class(TCustomCheckBox)
  published
    property Action;
    property Align;
    property AllowGrayed;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property Caption;
    property Checked;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Hint;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEditingDone;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property State;
    property TabOrder;
    property TabStop;
    property UseOnChange;
    property Visible;
  end;
{$Else NewCheckBox}
  // new checkbox
  TCBAlignment = (alLeftJustify, alRightJustify);

  TCheckBoxStyle = (cbsSystem, cbsCrissCross, cbsCheck);

  TCheckBox = Class(TCustomControl)
  Private
    FAllowGrayed,
    FWordWrap,
    FAttachTextToBox: Boolean;
    FAlignment: TCBAlignment;
    FState : TCheckBoxState;
    FCheckBoxStyle: TCheckBoxStyle;
    FMouseIsDragging,
    FMouseInControl: Boolean;
  Protected
    Procedure DoAutoSize; Override;
    Procedure SetAlignment(Value: TCBAlignment);
    Procedure SetState(Value: TCheckBoxState);

    Function GetChecked: Boolean;
    procedure SetChecked(Value: Boolean);
    procedure SetCheckBoxStyle(Value: TCheckBoxStyle);
    procedure SetAttachTextToBox(Value: Boolean);

    procedure CMMouseEnter(var Message: TLMMouse); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TLMMouse); message CM_MOUSELEAVE;
    Procedure WMMouseDown(var Message: TLMMouseEvent); Message LM_LBUTTONDOWN;
    Procedure WMMouseUp(var Message: TLMMouseEvent); Message LM_LBUTTONUP;
    Procedure WMKeyDown(var Message: TLMKeyDown); Message LM_KeyDown;
    Procedure WMKeyUp(var Message: TLMKeyUp); Message LM_KeyUp;
  public
    procedure Paint; Override;
    Procedure PaintCheck(var PaintRect: TRect);
    Procedure PaintText(var PaintRect: TRect);

    Constructor Create(AOwner: TComponent); Override;
    Function CheckBoxRect: TRect;
    procedure Click; Override;

    Property MouseInControl: Boolean read FMouseInControl;
    Property MouseIsDragging: Boolean read FMouseIsDragging;
  published
    property Alignment: TCBAlignment read FAlignment write SetAlignment;
    Property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed;
    Property Checked: Boolean read GetChecked write SetChecked;
    property State: TCheckBoxState read FState write SetState;
    property CheckBoxStyle: TCheckBoxStyle read FCheckBoxStyle write SetCheckBoxStyle;
    property AttachToBox: Boolean read FAttachTextToBox write SetAttachTextToBox default True;

    property Align;
    Property AutoSize;
    property WordWrap: Boolean read FWordWrap write FWordWrap;
    property TabStop;

    property Anchors;
    property Constraints;
    property Hint;
    property Font;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyUp;
    property OnKeyPress;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
    property Visible;
    property Caption;
    property Enabled;
    property ShowHint;
    property ParentFont;
    property ParentShowHint;
    property TabOrder;
  end;
{$EndIf NewCheckBox}


  { TToggleBox }

  TToggleBox = class(TCustomCheckBox)
  private
  public
    constructor Create(TheOwner: TComponent); override;
  published
    property AllowGrayed;
    property Anchors;
    property AutoSize default false;
    property BorderSpacing;
    property Caption;
    property Checked;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Hint;
    property OnChange;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property State;
    property TabOrder;
    property TabStop;
    property UseOnChange;
    property Visible;
  end;


  { TRadioButton }

  TRadioButton = class(TCustomCheckBox)
  protected
    function DialogChar(var Message: TLMKey): boolean; override;
    procedure RealSetText(const Value: TCaption); override;
    procedure ApplyChanges; override;
  public
    constructor Create(TheOwner: TComponent); override;
  published
    property Align;
    property AllowGrayed;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property Caption;
    property Checked;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Hint;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property State;
    property TabOrder;
    property TabStop;
    property UseOnChange;
    property Visible;
  end;


  { TCustomLabel }

  TCustomLabel = class(TGraphicControl)
  Private
    FAlignment: TAlignment;
    FFocusControl: TWinControl;
    FOptimalFill: Boolean;
    FShowAccelChar: Boolean;
    FWordWrap: Boolean;
    FLayout: TTextLayout;
    procedure SetOptimalFill(const AValue: Boolean);
  protected
    function  CanTab: boolean; override;
    function  HasMultiLine : boolean;
    procedure CalcSize(var AWidth, AHeight: integer);
    procedure DoAutoSize; override;
    function  DialogChar(var Message: TLMKey): boolean; override;
    procedure TextChanged; override;
    procedure Resize; override;
    procedure FontChanged(Sender: TObject); override;

    procedure WMActivate(var Message: TLMActivate); message LM_ACTIVATE;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    function  GetShowAccelChar: Boolean;
    function  GetAlignment: TAlignment;
    function  GetTransparent: boolean;
    procedure SetAlignment(Value: TAlignment);
    procedure SetColor(NewColor: TColor); override;
    procedure SetFocusControl(Value: TWinControl);
    procedure SetLayout(Value: TTextLayout);
    procedure SetShowAccelChar(Value: Boolean);
    procedure SetTransparent(NewTransparent: boolean);
    procedure SetWordWrap(Value: Boolean);
    procedure Loaded; override;

    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property FocusControl: TWinControl read FFocusControl write SetFocusControl;
    property Layout: TTextLayout read FLayout write SetLayout default tlTop;
    property ShowAccelChar: Boolean read GetShowAccelChar write SetShowAccelChar default true;
    property Transparent: boolean read GetTransparent write SetTransparent default true;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default false;
    property OptimalFill: Boolean read FOptimalFill write SetOptimalFill default false;
  public
    function CalcFittingFontHeight(const TheText: string;
                                   MaxWidth, MaxHeight: Integer; var FontHeight,
                                   NeededWidth, NeededHeight: integer): Boolean;
    function AdjustFontForOptimalFill: Boolean;
    constructor Create(TheOwner: TComponent); override;
    procedure Paint; override;
    property AutoSize default True;
  end;


  { TLabel }

  TLabel = class(TCustomLabel)
  published
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property Caption;
    property Color;
    property Constraints;
    property Enabled;
    property FocusControl;
    property Font;
    property Layout;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    property Transparent;
    property Visible;
    property WordWrap;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnChangeBounds;
    property OnResize;
    property OptimalFill;
  end;

var
  DefaultButtonControlUseOnChange: boolean;

procedure Register;

implementation

uses
  WSControls, WSStdCtrls; // Widgetset uses circle is allowed


type
  TMemoStrings = class(TStrings)
  private
    FMemo: TCustomMemo;
    FMemoWidgetClass: TWSCustomMemoClass;
  protected
    function Get(Index: Integer): String; override;
    function GetCount: Integer; override;
  public
    constructor Create(AMemo: TCustomMemo);
    procedure Clear; override;
    procedure Delete(index: Integer); override;
    procedure Insert(index: Integer; const S: String); override;

    property MemoWidgetClass: TWSCustomMemoClass read FMemoWidgetClass write FMemoWidgetClass;
  end;

procedure Register;
begin
  RegisterComponents('Standard',[TLabel,TEdit,TMemo,TToggleBox,TCheckBox,
       TRadioButton,TListBox,TComboBox,TScrollBar,TGroupBox]);
  RegisterComponents('Hidden',[TStaticText]);
end;


{$I customgroupbox.inc}
{$I customcombobox.inc}
{$I customlistbox.inc}
{$I custommemo.inc}
{$I customedit.inc}
{$I customlabel.inc}
{$I customcheckbox.inc}

{$I scrollbar.inc}
{$I memoscrollbar.inc}
{$I memo.inc}
{$I memostrings.inc}

{$I edit.inc}
{$I buttoncontrol.inc}

{$I checkbox.inc}

{$I radiobutton.inc}
{$I togglebox.inc}

{$I customstatictext.inc}

initialization
  DefaultButtonControlUseOnChange:=false;

end.

