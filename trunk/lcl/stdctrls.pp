{
 /***************************************************************************
                               stdctrls.pp
                               -----------

                   Initial Revision  : Tue Oct 19 CST 1999

 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.LCL, included in this distribution,                 *
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
  VCLGlobals, Classes, SysUtils, LCLStrConsts, LCLType, LCLProc,
  LMessages, Graphics, GraphType, ExtendedStrings, LCLIntf,
  ClipBrd, ActnList, GraphMath, Controls, Forms;

type

  { TScrollBar }

  TScrollStyle = (ssNone, ssHorizontal, ssVertical, ssBoth,
    ssAutoHorizontal, ssAutoVertical, ssAutoBoth);

  TScrollCode = (
    // !!! Beware. The position of these enums must correspond to the SB_xxx
    // values in LCLType  (Delphi compatibility, not our decision)
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

  TScrollBar = class(TWinControl)
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
  published
    property Align;
    property Anchors;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Kind: TScrollBarKind read FKind write SetKind default sbHorizontal;
    property LargeChange: TScrollBarInc read FLargeChange write FLargeChange default 1;
    property Max: Integer read FMax write SetMax default 100;
    property Min: Integer read FMin write SetMin default 0;
    property PageSize: Integer read FPageSize write SetPageSize;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property Position: Integer read FPosition write SetPosition default 0;
    property ShowHint;
    property SmallChange: TScrollBarInc read FSmallChange write FSmallChange default 1;
    property TabOrder;
    property TabStop default true;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnScroll: TScrollEvent read FOnScroll write FOnScroll;
    property OnStartDrag;
  end;


  { TCustomGroupBox }

  TCustomGroupBox = class (TWinControl) {class(TCustomControl) }
  protected
  public
    constructor Create(AOwner : TComponent); Override;
    function CanTab: boolean; override;
  end;


  { TGroupBox }

  TGroupBox = class(TCustomGroupBox)
  published
    property Align;
    property Anchors;
    property Caption;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property Ctl3D;
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
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;


  { TCustomComboBox }

  TComboBoxStyle = (csDropDown, csSimple, csDropDownList, csOwnerDrawFixed,
                    csOwnerDrawVariable);

  TOwnerDrawState = TBaseOwnerDrawState;

  TDrawItemEvent = procedure(Control: TWinControl; Index: Integer;
    ARect: TRect; State: TOwnerDrawState) of object;
  TMeasureItemEvent = procedure(Control: TWinControl; Index: Integer;
    var Height: Integer) of object;

  TCustomComboBox = class(TWinControl)
  private
    FAutoDropDown: Boolean;
    FCanvas: TCanvas;
    FDropDownCount: Integer;
    FDroppedDown: boolean;
    FItemHeight: integer;
    FItemIndex: integer;
    FItemWidth: integer;
    FItems: TStrings;
    fMaxLength: integer;
    FOnChange : TNotifyEvent;
    FOnCloseUp: TNotifyEvent;
    FOnDrawItem: TDrawItemEvent;
    FOnDropDown: TNotifyEvent;
    FOnMeasureItem: TMeasureItemEvent;
    FOnSelect: TNotifyEvent;
    FSelLength: integer;
    FSelStart: integer;
    FSorted : boolean;
    FStyle : TComboBoxStyle;
    FArrowKeysTraverseList : Boolean;
    FReturnArrowState : Boolean; //used to return the state of arrow keys from termporary change
    function GetDroppedDown: Boolean;
    function GetItemWidth: Integer;
    procedure SetItemWidth(const AValue: Integer);
    procedure SetItems(Value : TStrings);
    procedure LMDrawListItem(var TheMessage : TLMDrawListItem); message LM_DrawListItem;
    procedure CNCommand(var TheMessage : TLMCommand); message CN_Command;
    procedure UpdateSorted;
    procedure SetArrowKeysTraverseList(Value : Boolean);
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure DrawItem(Index: Integer; ARect: TRect;
      State: TOwnerDrawState); virtual;
    procedure LMChange(var msg); message LM_CHANGED;
    procedure Change; dynamic;
    procedure Select; dynamic;
    procedure DropDown; dynamic;
    procedure CloseUp; dynamic;
    procedure AdjustDropDown; virtual;

    function GetItemCount: Integer; //override;
    function GetItemHeight: Integer; virtual;
    function GetSelLength : integer; virtual;
    function GetSelStart : integer; virtual;
    function GetSelText : string; virtual;
    function GetItemIndex : integer; virtual;
    function GetMaxLength : integer; virtual;
    procedure InitializeWnd; override;
    function SelectItem(const AnItem: String): Boolean;
    procedure SetDropDownCount(const AValue: Integer); virtual;
    procedure SetDroppedDown(const AValue: Boolean); virtual;
    procedure SetItemHeight(const AValue: Integer); virtual;
    procedure SetItemIndex(Val : integer); virtual;
    procedure SetMaxLength(Val : integer); virtual;
    procedure SetSelLength(Val : integer); virtual;
    procedure SetSelStart(Val : integer); virtual;
    procedure SetSelText(const Val : string); virtual;
    procedure SetSorted(Val : boolean); virtual;
    procedure SetStyle(Val : TComboBoxStyle); virtual;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
    procedure KeyPress(var Key : Char); override;

    property DropDownCount: Integer read FDropDownCount write SetDropDownCount default 8;
    property Items: TStrings read FItems write SetItems;
    property ItemHeight: Integer read GetItemHeight write SetItemHeight;
    property ItemIndex: integer read GetItemIndex write SetItemIndex;
    property ItemWidth: Integer read GetItemWidth write SetItemWidth;
    property MaxLength: integer read GetMaxLength write SetMaxLength default 0;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnCloseUp: TNotifyEvent read FOnCloseUp write FOnCloseUp;
    property OnDrawItem: TDrawItemEvent read FOnDrawItem write FOnDrawItem;
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
    property OnMeasureItem: TMeasureItemEvent
      read FOnMeasureItem write FOnMeasureItem;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
    property Sorted: boolean read FSorted write SetSorted;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure AddItem(const Item: String; AnObject: TObject); //override;
    procedure AddHistoryItem(const Item: string; MaxHistoryCount: integer;
                             SetAsText, CaseSensitive: boolean);
    procedure AddHistoryItem(const Item: string; AnObject: TObject;
                   MaxHistoryCount: integer; SetAsText, CaseSensitive: boolean);
    procedure Clear; //override;
    procedure ClearSelection; //override;
    property DroppedDown: Boolean read GetDroppedDown write SetDroppedDown;
    procedure MeasureItem(Index: Integer; var TheHeight: Integer); virtual;
    procedure SelectAll;

    property AutoDropDown: Boolean
                           read FAutoDropDown write FAutoDropDown default False;
    property ArrowKeysTraverseList : Boolean
                           read FArrowKeysTraverseList write SetArrowKeysTraverseList default True;
    property Canvas: TCanvas read FCanvas;
    property SelLength: integer read GetSelLength write SetSelLength;
    property SelStart: integer read GetSelStart write SetSelStart;
    property SelText: String read GetSelText write SetSelText;
    property Style: TComboBoxStyle read FStyle write SetStyle;
  published
    property TabStop default true;
  end;


  { TComboBox }

  TComboBox = class(TCustomComboBox)
  public
    property ItemIndex;
  published
    property Align;
    property Anchors;
    property ArrowKeysTraverseList;
    property AutoDropDown;
    property Ctl3D;
    property DropDownCount;
    property Enabled;
    property Font;
    property ItemHeight;
    property Items;
    property ItemWidth;
    property MaxLength default -1;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnCloseUp;
    property OnDrawItem;
    property OnDropDown;
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

  TCustomListBox = class(TWinControl)
  private
    FCanvas: TCanvas;
    FExtendedSelect, FMultiSelect : boolean;
    FIntegralHeight: boolean;
    FItems: TStrings;
    FItemHeight: Integer;
    FItemIndex: integer;
    FOnDrawItem: TDrawItemEvent;
    FOnMeasureItem: TMeasureItemEvent;
    FSorted: boolean;
    FStyle: TListBoxStyle;
    FTopIndex: integer;
    FCacheValid: Boolean;
    function GetTopIndex: Integer;
    procedure SetTopIndex(const AValue: Integer);
    procedure UpdateSelectionMode;
    procedure UpdateSorted;
    procedure LMDrawListItem(var TheMessage : TLMDrawListItem); message LM_DrawListItem;
    procedure SendItemSelected(Index: integer; IsSelected: boolean);
  protected
    procedure AssignItemDataToCache(const AIndex: Integer; const AData: Pointer); virtual; // called to store item data while the handle isn't created
    procedure AssignCacheToItemData(const AIndex: Integer; const AData: Pointer); virtual; // called to restore the itemdata after a handle is created
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
    procedure CheckIndex(const AIndex: Integer);
    function GetItemHeight: Integer;
    function GetItemIndex : integer; virtual;
    function GetSelCount : integer;
    function GetSelected(Index : integer) : boolean;
    function GetCachedDataSize: Integer; virtual; // returns the amount of data needed per item
    function GetCachedData(const AIndex: Integer): Pointer;
    procedure SetExtendedSelect(Val : boolean); virtual;
    procedure SetItemIndex(Val : integer); virtual;
    procedure SetItems(Value : TStrings); virtual;
    procedure SetItemHeight(Value: Integer);
    procedure SetMultiSelect(Val : boolean); virtual;
    procedure SetSelected(Index : integer; Val : boolean);
    procedure SetSorted(Val : boolean); virtual;
    procedure SetStyle(Val : TListBoxStyle); virtual;
    procedure DrawItem(Index: Integer; ARect: TRect;
      State: TOwnerDrawState); virtual;

    property OnMeasureItem: TMeasureItemEvent
      read FOnMeasureItem write FOnMeasureItem;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    function GetIndexAtY(Y: integer): integer;
    function ItemAtPos(const Pos: TPoint; Existing: Boolean): Integer;
    function ItemRect(Index: Integer): TRect;
    function ItemVisible(Index: Integer): boolean;
    procedure MakeCurrentVisible;
    procedure MeasureItem(Index: Integer; var TheHeight: Integer); virtual;
    procedure Clear;
  public
    property Align;
    property Anchors;
    property BorderStyle default bsSingle;
    property Canvas: TCanvas read FCanvas;
    property Constraints;
    property ExtendedSelect : boolean read FExtendedSelect write SetExtendedSelect;
    property Font;
    property IntegralHeight: boolean read FIntegralHeight write FIntegralHeight; // not implemented
    property ItemHeight: Integer read GetItemHeight write SetItemHeight;
    property ItemIndex : integer read GetItemIndex write SetItemIndex;
    property Items : TStrings read FItems write SetItems;
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
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property SelCount : integer read GetSelCount;
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
    property BorderStyle;
    property Constraints;
    property ExtendedSelect;
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
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
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
    function GetModified : Boolean;
    procedure SetCharCase(Value : TEditCharCase);
    procedure SetMaxLength(Value : Integer);
    procedure SetModified(Value : Boolean);
    procedure SetPasswordChar(const AValue: Char);
    procedure SetReadOnly(Value : Boolean);
  Protected
    Procedure DoAutoSize; Override;
    procedure CreateWnd; override;

    procedure CMTextChanged(Var Message : TLMessage); message CM_TextChanged;
    procedure Change; dynamic;
    function GetSelLength : integer; virtual;
    function GetSelStart : integer; virtual;
    function GetSelText : string; virtual;
    procedure InitializeWnd; override;
    procedure SetEchoMode(Val : TEchoMode); virtual;
    procedure SetSelLength(Val : integer); virtual;
    procedure SetSelStart(Val : integer); virtual;
    procedure SetSelText(const Val : string); virtual;
    procedure RealSetText(const Value: TCaption); override;
    function ChildClassAllowed(ChildClass: TClass): boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SelectAll;
    procedure ClearSelection; virtual;
    procedure CopyToClipboard; virtual;
    procedure CutToClipboard; virtual;
    procedure PasteFromClipboard; virtual;
    property CharCase: TEditCharCase read FCharCase write SetCharCase default ecNormal;
    property EchoMode: TEchoMode read FEchoMode write SetEchoMode default emNormal;
    property MaxLength: Integer read FMaxLength write SetMaxLength default -1;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default false;
    property SelLength: integer read GetSelLength write SetSelLength;
    property SelStart: integer read GetSelStart write SetSelStart;
    property SelText: String read GetSelText write SetSelText;
    property Modified: Boolean read GetModified write SetModified;
    property PasswordChar: Char read FPasswordChar write SetPasswordChar default #0;
    property Text;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property PopupMenu;
    property TabStop default true;
    property TabOrder;
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
    //FFont : TFont;
    FHorzScrollBar: TMemoScrollBar;
    FLines: TStrings;
    FScrollBars: TScrollStyle;
    FVertScrollBar: TMemoScrollBar;
    FWordWrap: Boolean;
    procedure SetHorzScrollBar(const AValue: TMemoScrollBar);
    procedure SetVertScrollBar(const AValue: TMemoScrollBar);
    function StoreScrollBars: boolean;
  protected
    procedure SetLines(const Value : TStrings);
    procedure SetWordWrap(const Value : boolean);
    procedure SetScrollBars(const Value : TScrollStyle);
    procedure InitializeWnd; override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Append(const Value : String);
    procedure Clear;
  public
    property Lines: TStrings read FLines write SetLines;
    property ScrollBars: TScrollStyle read FScrollBars write SetScrollBars;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default true;
    //property Font : TFont read FFont write FFont;
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
    property Constraints;
    property CharCase;
    property DragMode;
    property EchoMode;
    property Enabled;
    property MaxLength;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
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
  protected
    function WordWrapIsStored: boolean;
  published
    property Align;
    property Anchors;
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
    property Tabstop;
    property Visible;
    property WordWrap stored WordWrapIsStored;
  end;


  { TCustomLabel }

  TCustomLabel = class(TWinControl)
  private
    FAlignment : TAlignment;
    FWordWrap : Boolean;
    FLayout : TTextLayout;
    FFocusControl : TWinControl;
    FShowAccelChar : boolean;
    procedure SetAlignment(Value : TAlignment);
    procedure SetLayout(Value : TTextLayout);
    procedure SetWordWrap(Value : Boolean);
    procedure WMActivate(var Message: TLMActivate); message LM_ACTIVATE;
  protected
    function GetLabelText: String ; virtual;
    procedure DoAutoSize; Override;
    procedure ParentFormInitializeWnd; override;
    procedure Notification(AComponent : TComponent; Operation : TOperation); override;
    procedure SetFocusControl(Val : TWinControl); virtual;
    procedure SetShowAccelChar(Val : boolean); virtual;
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property FocusControl: TWinControl read FFocusControl write SetFocusControl;
    property Layout: TTextLayout read FLayout write SetLayout default tlTop;
    property ShowAccelChar : boolean read FShowAccelChar write SetShowAccelChar default true;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default false;
  public
    constructor Create(AOwner : TComponent); override;
  end;


  { TLabel }

  TLabel = class(TCustomLabel)
  published
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property Caption;
    property Color;
    property Constraints;
    property FocusControl;
    property Font;
    property Layout;
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
    property WordWrap;
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
  protected
    property Checked: Boolean read GetChecked write SetChecked stored IsCheckedStored default False;
    property ClicksDisabled: Boolean read FClicksDisabled write FClicksDisabled;
    property UseOnChange: boolean read FUseOnChange write FUseOnChange stored UseOnChangeIsStored;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(TheOwner: TComponent); override;
  end;


  { TCustomCheckBox }

  // ToDo: delete TLeftRight when in classesh.inc
  TLeftRight = taLeftJustify..taRightJustify;

  TCheckBoxState = (cbUnchecked, cbChecked, cbGrayed);

  TCustomCheckBox = class(TButtonControl)
  private
    // FAlignment: TLeftRight;
    FAllowGrayed: Boolean;
    FState: TCheckBoxState;
    FShortCut : TLMShortcut;
    procedure SetState(Value: TCheckBoxState);
    function GetState : TCheckBoxState;
  protected
    procedure InitializeWnd; override;
    procedure Toggle; virtual;
    function GetChecked: Boolean; override;
    procedure SetChecked(Value: Boolean); override;
    procedure RealSetText(const Value: TCaption); override;
    procedure ApplyChanges; virtual;
  public
    constructor Create(TheOwner: TComponent); override;
  public
    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed;
    property State: TCheckBoxState read GetState write SetState;
  published
    property TabStop default true;
  end;

{$IFNDef NewCheckBox}
  // Normal checkbox
  TCheckBox = class(TCustomCheckBox)
  protected
    procedure DoAutoSize; Override;
    procedure RealSetText(const Value: TCaption); Override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Action;
    property AllowGrayed;
    property Align;
    property Anchors;
    property AutoSize;
    property Caption;
    property Constraints;
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
    property OnChangeBounds;
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
    FAttachTextToBox : Boolean;
    FAlignment : TCBAlignment;
    FState  : TCheckBoxState;
    FCheckBoxStyle : TCheckBoxStyle;
    FMouseIsDragging,
    FMouseInControl: Boolean;
  Protected
    Procedure DoAutoSize; Override;
    Procedure SetAlignment(Value : TCBAlignment);
    Procedure SetState(Value : TCheckBoxState);

    Function GetChecked : Boolean;
    procedure SetChecked(Value : Boolean);
    procedure SetCheckBoxStyle(Value : TCheckBoxStyle);
    procedure SetAttachTextToBox(Value : Boolean);

    procedure CMMouseEnter(var Message: TLMMouse); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TLMMouse); message CM_MOUSELEAVE;
    Procedure WMMouseDown(var Message : TLMMouseEvent); Message LM_LBUTTONDOWN;
    Procedure WMMouseUp(var Message : TLMMouseEvent); Message LM_LBUTTONUP;
    Procedure WMKeyDown(var Message : TLMKeyDown); Message LM_KeyDown;
    Procedure WMKeyUp(var Message : TLMKeyUp); Message LM_KeyUp;
  public
    procedure Paint; Override;
    Procedure PaintCheck(var PaintRect: TRect);
    Procedure PaintText(var PaintRect: TRect);

    Constructor Create(AOwner: TComponent); Override;
    Function CheckBoxRect : TRect;
    procedure Click; Override;

    Property MouseInControl : Boolean read FMouseInControl;
    Property MouseIsDragging : Boolean read FMouseIsDragging;
  published
    property Alignment : TCBAlignment read FAlignment write SetAlignment;
    Property AllowGrayed : Boolean read FAllowGrayed write FAllowGrayed;
    Property Checked : Boolean read GetChecked write SetChecked;
    property State : TCheckBoxState read FState write SetState;
    property CheckBoxStyle : TCheckBoxStyle read FCheckBoxStyle write SetCheckBoxStyle;
    property AttachToBox : Boolean read FAttachTextToBox write SetAttachTextToBox default True;

    property Align;
    Property AutoSize;
    property WordWrap : Boolean read FWordWrap write FWordWrap;
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
    property OnEnter;
    property OnExit;
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
    property Caption;
    property Checked;
    property State;
    property Visible;
    property Enabled;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Hint;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
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
  end;


  { TRadioButton }

  TRadioButton = class(TCustomCheckBox)
  protected
    procedure DoAutoSize; override;
    procedure RealSetText(const Value: TCaption); override;
  public
    constructor Create(TheOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property AutoSize;
    property AllowGrayed;
    property Caption;
    property Checked;
    property Constraints;
    property State;
    property Visible;
    property Enabled;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Hint;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnChangeBounds;
    property OnResize;
    property OnStartDrag;
  end;


  { TStaticText }

  TStaticBorderStyle = (sbsNone, sbsSingle, sbsSunken);

  TCustomStaticText = class(TCustomControl)
  Private
    FAlignment: TAlignment;
    FStaticBorderStyle: TStaticBorderStyle;
    FFocusControl: TWinControl;
    FShowAccelChar: Boolean;
    Procedure FontChange(Sender : TObject);
  protected
    Procedure DoAutoSize; Override;
    Procedure CMTextChanged(var Message: TLMSetText); message CM_TEXTCHANGED;

    procedure WMActivate(var Message: TLMActivate); message LM_ACTIVATE;
    procedure Notification(AComponent : TComponent; Operation : TOperation); override;

    Procedure SetAlignment(Value : TAlignment);
    Function GetAlignment : TAlignment;
    Procedure SetStaticBorderStyle(Value : TStaticBorderStyle);
    Function GetStaticBorderStyle : TStaticBorderStyle;
    Procedure SetFocusControl(Value : TWinControl);
    Procedure SetShowAccelChar(Value : Boolean);
    Function GetShowAccelChar : Boolean;

    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property BorderStyle: TStaticBorderStyle read GetStaticBorderStyle write SetStaticBorderStyle;
    property FocusControl : TWinControl read FFocusControl write SetFocusControl;
    property ShowAccelChar: Boolean read GetShowAccelChar write SetShowAccelChar;
  public
    constructor Create(AOwner: TComponent); override;
    Procedure Paint; override;
  end;

  TStaticText = class(TCustomStaticText)
  published
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BorderStyle;
    property Caption;
    property Color;
    property Constraints;
    property Enabled;
    property FocusControl;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnChangeBounds;
    property OnResize;
  end;

var
  DefaultButtonControlUseOnChange: boolean;

procedure Register;

implementation

type
  TMemoStrings = class(TStrings)
  private
    FMemo: TCustomMemo;
  protected
    function Get(Index : Integer): String; override;
    function GetCount: Integer; override;
  public
    constructor Create(AMemo: TCustomMemo);
    procedure Clear; override;
    procedure Delete(index : Integer); override;
    procedure Insert(index: Integer; const S: String); override;
  end;

procedure Register;
begin
  RegisterComponents('Standard',[TLabel,TEdit,TMemo,TToggleBox,TCheckBox,
       TRadioButton,TListBox,TComboBox,TScrollBar,TGroupBox,TStaticText]);
end;


{$IFDef NewCheckBox}
Procedure TCheckbox.DoAutoSize;
var
  R : TRect;
  DC : hDC;
begin
  If AutoSizing or not AutoSize then
    Exit;
  if (not HandleAllocated) or ([csLoading,csDestroying]*ComponentState<>[]) then
    exit;
  AutoSizing := True;
  DC := GetDC(Handle);
  Try
    R := Rect(0,0, Width, Height);
    DrawText(DC, PChar(Caption), Length(Caption), R,
      DT_CalcRect or DT_NOPrefix);
    If R.Right > Width then
      Width := R.Right + 25;
    If R.Bottom > Height then
      Height := R.Bottom + 2;
  Finally
    ReleaseDC(Handle, DC);
    AutoSizing := False;
  end;
end;

Function TCheckBox.GetChecked : Boolean;
begin
  Result := (State = cbChecked);
end;

Procedure TCheckBox.SetChecked(Value : Boolean);
begin
  If Value then
    State := cbChecked
  else
    State := cbUnchecked
end;

procedure TCheckBox.SetCheckBoxStyle(Value : TCheckBoxStyle);
begin
  FCheckBoxStyle := Value;
  Invalidate;
end;

procedure TCheckBox.SetAttachTextToBox(Value : Boolean);
begin
  FAttachTextToBox := Value;
  Invalidate;
end;

Procedure TCheckbox.SetAlignment(Value : TCBAlignment);
begin
  FAlignment := Value;
  Invalidate;
end;

Procedure TCheckbox.SetState(Value : TCheckBoxState);
begin
  If Value = cbGrayed then begin
    If AllowGrayed then
      FState := Value
    else
      FState := cbUnchecked;
  end
  else
    FState := Value;
  Invalidate;
end;

Procedure TCheckbox.CMMouseEnter(var Message: TLMMouse);
begin
  if not MouseInControl
  and Enabled and (GetCapture = 0)
  then begin
    FMouseInControl := True;
    Invalidate;
  end;
end;

procedure TCheckbox.CMMouseLeave(var Message: TLMMouse);
begin
  if MouseInControl
  and Enabled and (GetCapture = 0)
  and not MouseIsDragging
  then begin
    FMouseInControl := False;
    Invalidate;
  end;
end;

Procedure TCheckbox.WMMouseDown(var Message : TLMMouseEvent);
begin
  if Enabled then
    If not MouseInControl then
      FMouseInControl := True;
  if MouseInControl and Enabled then begin
    FMouseIsDragging := True;
    Invalidate;
  end;
end;

Procedure TCheckbox.WMMouseUp(var Message : TLMMouseEvent);
begin
  If MouseInControl and Enabled then begin
    FMouseIsDragging := False;
    Case State of
      cbUnchecked :
       begin
          If AllowGrayed then
            State := cbGrayed
          else
            State := cbChecked;
        end;
      cbGrayed :
        State := cbChecked;
      cbChecked :
        State := cbUnchecked;
    end;
    Click;
  end;
end;

Procedure TCheckbox.WMKeyDown(var Message : TLMKeyDown);
begin
  ControlState := ControlState -  [csClicked];
  Case Message.CharCode of
    32:
      begin
        FMouseInControl := True;
        Invalidate;
      end;
    27:
      If MouseInControl then begin
        FMouseInControl := False;
        Invalidate;
      end;
  end;
  Message.Result := 1
end;

Procedure TCheckbox.WMKeyUp(var Message : TLMKeyUp);
begin
  Case Message.CharCode of
    32:
      begin
        If MouseInControl then begin
          FMouseInControl := False;
          Case State of
            cbUnchecked :
              begin
                If AllowGrayed then
                  State := cbGrayed
                else
                  State := cbChecked;
              end;
            cbGrayed :
              State := cbChecked;
            cbChecked :
              State := cbUnchecked;
          end;
          Click;
        end;
      end;
  end;
  Message.Result := 1
end;

Procedure TCheckBox.PaintCheck(var PaintRect: TRect);

  Procedure DrawBorder(Highlight, Shadow : TColor; Rect : TRect; Down : Boolean);
  begin
    With Canvas, Rect do begin
      Pen.Style := psSolid;
      If Down then
        Pen.Color := shadow
      else
        Pen.Color := Highlight;
      MoveTo(Left, Top);
      LineTo(Right - 1,Top);
      MoveTo(Left, Top);
      LineTo(Left,Bottom - 1);
      If Down then
        Pen.Color := Highlight
      else
        Pen.Color := shadow;
      MoveTo(Left,Bottom - 1);
      LineTo(Right - 1,Bottom - 1);
      MoveTo(Right - 1, Top);
      LineTo(Right - 1,Bottom);
    end;
  end;

var
  FD1, FD2 : TPoint;
  BD1, BD2 : TPoint;
  APaintRect : TRect;
  DrawFlags : Longint;
begin
  If CheckBoxStyle <> cbsSystem then begin
    If (State = cbGrayed) or (not Enabled) then begin
      If (MouseInControl and MouseIsDragging) or (not Enabled) then
        Canvas.Brush.Color := clBtnFace
      else
        Canvas.Brush.Color := clBtnHighlight;
      Canvas.FillRect(CheckBoxRect);
      Canvas.Pen.Color := clBtnShadow;
    end
    else begin
      If MouseInControl and MouseIsDragging then
        Canvas.Brush.Color := clBtnFace
      else
        Canvas.Brush.Color := clWindow;
      Canvas.FillRect(CheckBoxRect);
      Canvas.Pen.Color := clWindowText;
    end;
    If State <> cbUnchecked then begin
      Case CheckBoxStyle of
        cbsCrissCross:
          begin
            Canvas.Pen.Width := 1;

            {Backward Diagonal}
              BD1 := Point(CheckBoxRect.Left + 3,CheckBoxRect.Top + 3);
              BD2 := Point(CheckBoxRect.Right - 3,CheckBoxRect.Bottom - 3);

              Canvas.MoveTo(BD1.X + 1, BD1.Y);
              Canvas.LineTo(BD2.X, BD2.Y - 1);{Top Line}
              Canvas.MoveTo(BD1.X, BD1.Y);
              Canvas.LineTo(BD2.X, BD2.Y);{Center Line}
              Canvas.MoveTo(BD1.X, BD1.Y + 1);
              Canvas.LineTo(BD2.X - 1, BD2.Y);{Bottom Line}

            {Forward Diagonal}
              FD1 := Point(CheckBoxRect.Left + 3,CheckBoxRect.Bottom - 4);
              FD2 := Point(CheckBoxRect.Right - 3,CheckBoxRect.Top + 2);

              Canvas.MoveTo(FD1.X, FD1.Y - 1);
              Canvas.LineTo(FD2.X - 1, FD2.Y);{Top Line}
              Canvas.MoveTO(FD1.X, FD1.Y);
              Canvas.LineTo(FD2.X, FD2.Y);{Center Line}
              Canvas.MoveTo(FD1.X + 1, FD1.Y);
              Canvas.LineTo(FD2.X, FD2.Y + 1);{Bottom Line}

            Canvas.Pen.Width := 0;
          end;
        cbsCheck:
          begin
            Canvas.Pen.Width := 1;

            {Short Diagonal}
              BD1 := Point(CheckBoxRect.Left + 4,CheckBoxRect.Bottom - 8);
              BD2 := Point(CheckBoxRect.Left + 4,CheckBoxRect.Bottom - 5);

              Canvas.MoveTO(BD1.X - 1, BD1.Y);
              Canvas.LineTo(BD2.X - 1, BD2.Y);{Left Line}
              Canvas.MoveTo(BD1.X, BD1.Y + 1);
              Canvas.LineTo(BD2.X, BD2.Y + 1);{Right Line}

            {Long Diagonal}
              FD1 := Point(CheckBoxRect.Left + 5,CheckBoxRect.Bottom - 6);
              FD2 := Point(CheckBoxRect.Right - 3,CheckBoxRect.Top + 2);

              Canvas.MoveTo(FD1.X,FD1.Y);
              Canvas.LineTo(FD2.X, FD2.Y);{Top Line}
              Canvas.MoveTo(FD1.X, FD1.Y + 1);
              Canvas.LineTo(FD2.X, FD2.Y + 1);{Center Line}
              Canvas.MoveTo(FD1.X, FD1.Y + 2);
              Canvas.LineTo(FD2.X, FD2.Y + 2);{Bottom Line}

            Canvas.Pen.Width := 0;
          end;
      end;
    end;
    DrawBorder(clBtnHighlight, clBtnShadow, CheckBoxRect, True);
    InflateRect(APaintRect, -1, -1);
    DrawBorder(clBtnFace, clBlack, APaintRect, True);
  end
  else begin
    DrawFlags:=DFCS_BUTTONPUSH + DFCS_FLAT;
    If MouseInControl and Enabled then
      Inc(DrawFlags,DFCS_CHECKED);
    DrawFrameControl(Canvas.Handle, PaintRect, DFC_BUTTON, DrawFlags);

    DrawFlags:=DFCS_BUTTONCHECK;
    if Checked or (State = cbGrayed) then inc(DrawFlags,DFCS_PUSHED);
    if not Enabled then inc(DrawFlags,DFCS_INACTIVE);
    If MouseInControl and Enabled then
      Inc(DrawFlags,DFCS_CHECKED);

    APaintRect := CheckBoxRect;
    DrawFrameControl(Canvas.Handle, APaintRect, DFC_BUTTON, DrawFlags);
  end;
end;

Procedure TCheckBox.PaintText(var PaintRect: TRect);
var
  Sz : Integer;
  AR : TRect;
  dish, dis : TColor;

  Procedure DoDrawText(theRect : TRect);
  var
    TextStyle : TTextStyle;
  begin
    With TextStyle do begin
      Layout     := tlCenter;
      SingleLine := False;
      Clipping   := True;
      ExpandTabs := False;
      ShowPrefix := False;
      Wordbreak  := Wordwrap;
      Opaque     := False;
      SystemFont := CheckBoxStyle = cbsSystem;
    end;

    Case Alignment of
      alLeftJustify:
        begin
          If not FAttachTextToBox then begin
            TextStyle.Alignment  := taLeftJustify;
          end
          else
            TextStyle.Alignment  := taRightJustify;
        end;
      alRightJustify:
        begin
          If not FAttachTextToBox then begin
            TextStyle.Alignment  := taRightJustify;
          end
          else
            TextStyle.Alignment  := taLeftJustify;
        end;
    end;
    Canvas.TextRect(theRect, 0, 0, Caption, TextStyle);
  end;

  Procedure DoDisabledTextRect(Rect : TRect; Highlight, Shadow : TColor);
  var
    FC : TColor;
  begin
    FC := Canvas.Font.Color;
    Canvas.Font.Color := Highlight;
    OffsetRect(Rect, 1, 1);
    DoDrawText(Rect);
    Canvas.Font.Color := Shadow;
    OffsetRect(Rect, -1, -1);
    DoDrawText(Rect);
    Canvas.Font.Color := FC;
  end;

begin
  If Caption = '' then
    exit;
  Sz := CheckBoxRect.Right - CheckBoxRect.Left;
  AR.Top := PaintRect.Top;
  AR.Bottom := PaintRect.Bottom;
  If Alignment = alRightJustify then begin
    AR.Left := PaintRect.Left + Sz + 6;
    AR.Right := PaintRect.Right;
  end
  else begin
    AR.Left := PaintRect.Left;
    AR.Right := PaintRect.Right - Sz - 6;
  end;
  dish := clBtnHighlight;
  dis := clBtnShadow;
  Canvas.Font := Self.Font;
  If Enabled then begin
    If CheckBoxStyle = cbsSystem then
      Canvas.Font.Color := clBtnText;
    DoDrawText(AR)
  end
  else
    DoDisabledTextRect(AR,dish,dis);
end;

procedure TCheckbox.Paint;
var
  PaintRect: TRect;
begin
  PaintRect := Rect(0, 0, Width, Height);
  Canvas.Color := clBtnFace;

  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);
  PaintCheck(PaintRect);
  PaintText(PaintRect);
end;

Constructor TCheckbox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  controlstyle := controlstyle - [csAcceptsControls];
  Alignment := alRightJustify;
  FAttachTextToBox := True
end;

Function TCheckBox.CheckBoxRect : TRect;
var
  Sz : Integer;
begin
  Sz := 13;
  Result.Top := (Height div 2) - (Sz div 2);
  Result.Bottom := Result.Top + Sz;
  If Alignment = alRightJustify then begin
    Result.Left := 2;
    Result.Right := Result.Left + Sz;
  end
  else begin
    Result.Right := Width - 2;
    Result.Left := Result.Right - Sz;
  end;
end;

procedure TCheckBox.Click;
begin
  If Assigned(OnClick) then
    OnClick(Self);
end;
{$EndIf NewCheckbox}

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

{$IFNDef NewCheckBox}
  {$I checkbox.inc}
{$EndIf Not NewCheckbox}

{$I radiobutton.inc}
{$I togglebox.inc}

{$I customstatictext.inc}

initialization
  DefaultButtonControlUseOnChange:=false;

end.

{ =============================================================================

  $Log$
  Revision 1.143  2004/05/21 11:13:18  micha
  add measureitem to tcustomlistbox just like tcustomcombobox has

  Revision 1.142  2004/05/21 09:03:54  micha
  implement new borderstyle
  - centralize to twincontrol (protected)
  - public expose at tcustomcontrol to let interface access it

  Revision 1.141  2004/04/18 23:55:39  marc
  * Applied patch from Ladislav Michl
  * Changed the way TControl.Text is resolved
  * Added setting of text to TWSWinControl

  Revision 1.140  2004/04/02 19:39:46  mattias
  fixed checking empty mask raw image

  Revision 1.139  2004/03/12 15:48:57  mattias
  fixed 1.0.x compilation

  Revision 1.138  2004/03/08 22:36:01  mattias
  added TWinControl.ParentFormInitializeWnd

  Revision 1.137  2004/03/08 00:48:05  mattias
  moved TOnwerDrawState to StdCtrls

  Revision 1.136  2004/03/07 09:37:20  mattias
  added workaround for AutoSize in TCustomLabel

  Revision 1.135  2004/02/24 20:26:50  mattias
  published some TRadioButton properties

  Revision 1.134  2004/02/23 23:15:12  mattias
  improved FindDragTarget

  Revision 1.133  2004/02/23 20:06:05  mattias
  published TLabel.OnMouseXXX

  Revision 1.132  2004/02/22 10:43:20  mattias
  added child-parent checks

  Revision 1.131  2004/02/13 18:21:31  mattias
  fixed combo chane

  Revision 1.130  2004/02/09 19:52:52  mattias
  implemented ByteOrder for TLazIntfImage and added call of to LM_SETFONT

  Revision 1.129  2004/02/06 16:58:58  mattias
  updated polish translation

  Revision 1.128  2004/02/05 13:53:38  mattias
  fixed GetConstraints for win32 intf

  Revision 1.127  2004/02/05 09:45:33  mattias
  implemented Actions for TSpeedButton, TMenuItem, TCheckBox

  Revision 1.126  2004/02/04 23:30:18  mattias
  completed TControl actions

  Revision 1.125  2004/02/04 22:17:09  mattias
  removed workaround VirtualCreate

  Revision 1.124  2004/02/04 12:59:07  mattias
  added TToolButton.Action and published some props

  Revision 1.123  2004/02/04 11:09:40  mattias
  added DefineProperties check for check lfm

  Revision 1.122  2004/02/04 00:21:40  mattias
  added SelectDirectory and TListBox.ItemVisible

  Revision 1.121  2004/02/04 00:04:37  mattias
  added some TEdit ideas to TSpinEdit

  Revision 1.120  2004/02/02 12:44:45  mattias
  implemented interface constraints

  Revision 1.119  2004/02/02 00:41:06  mattias
  TScrollBar now automatically checks Align and Anchors for useful values

  Revision 1.118  2004/01/27 21:32:11  mattias
  improved changing style of controls

  Revision 1.117  2004/01/21 10:19:16  micha
  enable tabstops for controls; implement tabstops in win32 intf

  Revision 1.116  2004/01/12 15:04:41  mattias
  implemented TCustomListBox.ItemAtPos

  Revision 1.115  2004/01/11 11:57:54  mattias
  implemented TCustomListBox.ItemRect for gtk1 intf

  Revision 1.114  2004/01/06 17:58:06  mattias
  fixed setting TRadioButton.Caption for gtk

  Revision 1.113  2004/01/03 20:36:29  mattias
  published TEdit.Enabled

  Revision 1.112  2003/11/28 23:24:57  mattias
  implemented Clean Directories

  Revision 1.111  2003/11/27 19:40:34  mattias
  added TListBox.PopupMenu

  Revision 1.110  2003/11/08 14:12:48  mattias
  fixed scrollbar events under gtk from Colin

  Revision 1.109  2003/11/01 18:58:15  mattias
  added clipboard support for TCustomEdit from Colin

  Revision 1.108  2003/10/16 23:54:27  marc
  Implemented new gtk keyevent handling

  Revision 1.107  2003/09/26 18:19:40  ajgenius
  add minor TEdit/TMemo properties for delphi compatiblitity

  Revision 1.106  2003/09/23 08:00:46  mattias
  improved OnEnter for gtkcombo

  Revision 1.105  2003/09/18 11:24:29  mattias
  started TDBMemo

  Revision 1.104  2003/09/18 09:21:03  mattias
  renamed LCLLinux to LCLIntf

  Revision 1.103  2003/08/28 09:10:00  mattias
  listbox and comboboxes now set sort and selection at handle creation

  Revision 1.102  2003/08/26 08:12:33  mattias
  applied listbox/combobox patch from Karl

  Revision 1.101  2003/07/30 13:03:44  mattias
  replaced label with memo

  Revision 1.100  2003/07/07 23:58:43  marc
  + Implemented TCheckListBox.Checked[] property

  Revision 1.99  2003/06/23 09:42:09  mattias
  fixes for debugging lazarus

  Revision 1.98  2003/06/16 22:47:19  mattias
  fixed keeping TForm.Visible=false

  Revision 1.97  2003/06/13 14:38:01  mattias
  fixed using streamed clientwith/height for child anchors

  Revision 1.96  2003/06/12 16:18:23  mattias
  applied TComboBox fix for grabbing keys from Yoyong

  Revision 1.95  2003/06/10 17:23:34  mattias
  implemented tabstop

  Revision 1.94  2003/06/10 15:58:39  mattias
  started TLabeledEdit

  Revision 1.93  2003/06/10 13:35:54  mattias
  implemented TComboBox dropdown from Yoyong

  Revision 1.92  2003/06/07 09:34:21  mattias
  added ambigius compiled unit test for packages

  Revision 1.91  2003/04/29 13:35:39  mattias
  improved configure build lazarus dialog

  Revision 1.90  2003/04/16 22:59:35  mattias
  added TMaskEdit from Tony

  Revision 1.89  2003/04/15 08:54:27  mattias
  fixed TMemo.WordWrap

  Revision 1.88  2003/04/11 17:10:20  mattias
  added but not implemented ComboBoxDropDown

  Revision 1.87  2003/04/04 16:35:24  mattias
  started package registration

  Revision 1.86  2003/03/29 17:20:05  mattias
  added TMemoScrollBar

  Revision 1.85  2003/03/28 23:03:38  mattias
  started TMemoScrollbar

  Revision 1.84  2003/03/25 16:56:57  mattias
  implemented TButtonControl.UseOnChange

  Revision 1.83  2003/03/25 16:29:53  mattias
  fixed sending TButtonControl.OnClick on every change

  Revision 1.82  2003/03/17 20:53:16  mattias
  removed SetRadioButtonGroupMode

  Revision 1.81  2003/03/17 20:50:30  mattias
  fixed TRadioGroup.ItemIndex=-1

  Revision 1.80  2003/03/17 08:51:09  mattias
  added IsWindowVisible

  Revision 1.79  2003/03/11 07:46:43  mattias
  more localization for gtk- and win32-interface and lcl

  Revision 1.78  2003/03/09 17:44:12  mattias
  finshed Make Resourcestring dialog and implemented TToggleBox

  Revision 1.77  2003/03/08 21:51:57  mattias
  make resource string dialog nearly complete

  Revision 1.76  2003/02/28 15:49:43  mattias
  fixed initial size

  Revision 1.75  2003/01/24 13:07:33  mattias
  fixed TListBox.BorderStyle=bsNone

  Revision 1.74  2003/01/01 10:46:59  mattias
  fixes for win32 listbox/combobox from Karl Brandt

  Revision 1.73  2002/12/28 21:44:51  mattias
  further cleanup

  Revision 1.72  2002/12/27 10:34:55  mattias
  message view scrolls to message

  Revision 1.71  2002/12/27 08:46:32  mattias
  changes for fpc 1.1

  Revision 1.70  2002/12/22 23:25:34  mattias
  fixed setting TEdit properties after creating handle

  Revision 1.69  2002/12/12 17:47:45  mattias
  new constants for compatibility

  Revision 1.68  2002/11/27 14:37:37  mattias
  added form editor options for rubberband and colors

  Revision 1.67  2002/11/16 11:22:56  mbukovjan
  Fixes to MaxLength. TCustomMemo now has MaxLength, too.

  Revision 1.66  2002/11/12 10:16:14  lazarus
  MG: fixed TMainMenu creation

  Revision 1.65  2002/10/26 15:15:47  lazarus
  MG: broke LCL<->interface circles

  Revision 1.64  2002/10/26 11:20:30  lazarus
  MG: broke some interfaces.pp circles

  Revision 1.63  2002/10/25 09:47:37  lazarus
  MG: added inputdialog.inc

  Revision 1.62  2002/10/25 08:25:43  lazarus
  MG: broke circle stdctrls.pp <-> forms.pp

  Revision 1.61  2002/10/24 19:35:34  lazarus
  AJ: Fixed forms <-> stdctrls circular uses

  Revision 1.60  2002/10/24 10:05:51  lazarus
  MG: broke graphics.pp <-> clipbrd.pp circle

  Revision 1.59  2002/10/23 20:47:26  lazarus
  AJ: Started Form Scrolling
      Started StaticText FocusControl
      Fixed Misc Dialog Problems
      Added TApplication.Title

  Revision 1.58  2002/10/21 15:51:27  lazarus
  AJ: moved TCustomStaticText code to include/customstatictext.inc

  Revision 1.57  2002/10/20 22:57:18  lazarus
  AJ:switched to gtk_widget_newv to work around array of const

  Revision 1.56  2002/10/20 21:54:03  lazarus
  MG: fixes for 1.1

  Revision 1.55  2002/10/18 16:08:09  lazarus
  AJ: Partial HintWindow Fix; Added Screen.Font & Font.Name PropEditor; Started to fix ComboBox DropDown size/pos

  Revision 1.54  2002/10/14 14:29:50  lazarus
  AJ: Improvements to TUpDown; Added TStaticText & GNOME DrawText

  Revision 1.53  2002/10/04 14:24:14  lazarus
  MG: added DrawItem to TComboBox/TListBox

  Revision 1.52  2002/10/03 18:04:46  lazarus
  MG: started customdrawitem

  Revision 1.51  2002/10/03 14:47:30  lazarus
  MG: added TComboBox.OnPopup+OnCloseUp+ItemWidth

  Revision 1.50  2002/10/03 00:08:50  lazarus
  AJ: TCustomLabel Autosize, TCustomCheckbox '&' shortcuts started

  Revision 1.49  2002/10/02 16:16:40  lazarus
  MG: accelerated unitdependencies

  Revision 1.48  2002/10/02 14:23:22  lazarus
  MG: added various history lists

  Revision 1.47  2002/10/01 18:00:03  lazarus
  AJ: Initial TUpDown, minor property additions to improve reading Delphi created forms.

  Revision 1.46  2002/09/27 20:52:22  lazarus
  MWE: Applied patch from "Andrew Johnson" <aj_genius@hotmail.com>

  Here is the run down of what it includes -

   -Vasily Volchenko's Updated Russian Localizations

   -improvements to GTK Styles/SysColors
   -initial GTK Palette code - (untested, and for now useless)

   -Hint Windows and Modal dialogs now try to stay transient to
    the main program form, aka they stay on top of the main form
    and usually minimize/maximize with it.

   -fixes to Form BorderStyle code(tool windows needed a border)

   -fixes DrawFrameControl DFCS_BUTTONPUSH to match Win32 better
    when flat

   -fixes DrawFrameControl DFCS_BUTTONCHECK to match Win32 better
    and to match GTK theme better. It works most of the time now,
    but some themes, noteably Default, don't work.

   -fixes bug in Bitmap code which broke compiling in NoGDKPixbuf
    mode.

   -misc other cleanups/ fixes in gtk interface

   -speedbutton's should now draw correctly when flat in Win32

   -I have included an experimental new CheckBox(disabled by
    default) which has initial support for cbGrayed(Tri-State),
    and WordWrap, and misc other improvements. It is not done, it
    is mostly a quick hack to test DrawFrameControl
    DFCS_BUTTONCHECK, however it offers many improvements which
    can be seen in cbsCheck/cbsCrissCross (aka non-themed) state.

   -fixes Message Dialogs to more accurately determine
    button Spacing/Size, and Label Spacing/Size based on current
    System font.
   -fixes MessageDlgPos, & ShowMessagePos in Dialogs
   -adds InputQuery & InputBox to Dialogs

   -re-arranges & somewhat re-designs Control Tabbing, it now
    partially works - wrapping around doesn't work, and
    subcontrols(Panels & Children, etc) don't work. TabOrder now
    works to an extent. I am not sure what is wrong with my code,
    based on my other tests at least wrapping and TabOrder SHOULD
    work properly, but.. Anyone want to try and fix?

   -SynEdit(Code Editor) now changes mouse cursor to match
    position(aka over scrollbar/gutter vs over text edit)

   -adds a TRegion property to Graphics.pp, and Canvas. Once I
    figure out how to handle complex regions(aka polygons) data
    properly I will add Region functions to the canvas itself
    (SetClipRect, intersectClipRect etc.)

   -BitBtn now has a Stored flag on Glyph so it doesn't store to
    lfm/lrs if Glyph is Empty, or if Glyph is not bkCustom(aka
    bkOk, bkCancel, etc.) This should fix most crashes with older
    GDKPixbuf libs.

  Revision 1.45  2002/09/18 17:07:24  lazarus
  MG: added patch from Andrew

  Revision 1.44  2002/09/09 07:26:42  lazarus
  MG: started TCollectionPropertyEditor

  Revision 1.43  2002/09/08 19:09:55  lazarus
  Fixed and simplified TRadioButton

  Revision 1.42  2002/09/07 12:14:50  lazarus
  EchoMode for TCustomEdit. emNone not implemented for GTK+, falls back to emPassword
  behaviour.

  Revision 1.41  2002/09/05 10:12:06  lazarus

  New dialog for multiline caption of TCustomLabel.
  Prettified TStrings property editor.
  Memo now has automatic scrollbars (not fully working), WordWrap and Scrollbars property
  Removed saving of old combo text (it broke things and is not needed). Cleanups.

  Revision 1.40  2002/09/03 11:32:49  lazarus

  Added shortcut keys to labels
  Support for alphabetically sorting the properties
  Standardize message and add shortcuts ala Kylix
  Published BorderStyle, unpublished BorderWidth
  ShowAccelChar and FocusControl
  ShowAccelChar and FocusControl for TLabel, escaped ampersands now work.

  Revision 1.39  2002/09/03 08:07:19  lazarus
  MG: image support, TScrollBox, and many other things from Andrew

  Revision 1.38  2002/08/30 06:46:03  lazarus

  Use comboboxes. Use history. Prettify the dialog. Preselect text on show.
  Make the findreplace a dialog. Thus removing resiying code (handled by Anchors now anyway).
  Make Anchors work again and publish them for various controls.
  SelStart and Co. for TEdit, SelectAll procedure for TComboBox and TEdit.
  Clean up and fix some bugs for TComboBox, plus selection stuff.

  Revision 1.37  2002/08/27 18:45:13  lazarus
  MG: propedits text improvements from Andrew, uncapturing, improved comobobox

  Revision 1.36  2002/08/27 14:33:37  lazarus
  MG: fixed designer component deletion

  Revision 1.35  2002/08/25 13:31:35  lazarus
  MG: replaced C-style operators

  Revision 1.34  2002/08/24 06:51:22  lazarus
  MG: from Andrew: style list fixes, autosize for radio/checkbtns

  Revision 1.33  2002/08/19 20:34:47  lazarus
  MG: improved Clipping, TextOut, Polygon functions

  Revision 1.32  2002/08/17 15:45:32  lazarus
  MG: removed ClientRectBugfix defines

  Revision 1.31  2002/07/23 07:40:51  lazarus
  MG: fixed get widget position for inherited gdkwindows

  Revision 1.30  2002/05/20 14:19:03  lazarus
  MG: activated the clientrect bugfixes

  Revision 1.29  2002/05/13 14:47:00  lazarus
  MG: fixed client rectangles, TRadioGroup, RecreateWnd

  Revision 1.28  2002/05/10 06:05:50  lazarus
  MG: changed license to LGPL

  Revision 1.27  2002/05/09 12:41:28  lazarus
  MG: further clientrect bugfixes

  Revision 1.26  2002/04/22 13:07:45  lazarus
  MG: fixed AdjustClientRect of TGroupBox

  Revision 1.25  2002/04/21 06:53:54  lazarus
  MG: fixed save lrs to test dir

  Revision 1.24  2002/04/18 08:09:03  lazarus
  MG: added include comments

  Revision 1.23  2002/04/18 07:53:08  lazarus
  MG: fixed find declaration of forward def class

  Revision 1.22  2002/03/25 17:59:19  lazarus
  GTK Cleanup
  Shane

  Revision 1.21  2002/02/20 23:33:24  lazarus
  MWE:
    + Published OnClick for TMenuItem
    + Published PopupMenu property for TEdit and TMemo (Doesn't work yet)
    * Fixed debugger running twice
    + Added Debugger output form
    * Enabled breakpoints

  Revision 1.20  2002/02/03 00:24:01  lazarus
  TPanel implemented.
  Basic graphic primitives split into GraphType package, so that we can
  reference it from interface (GTK, Win32) units.
  New Frame3d canvas method that uses native (themed) drawing (GTK only).
  New overloaded Canvas.TextRect method.
  LCLLinux and Graphics was split, so a bunch of files had to be modified.

  Revision 1.19  2002/01/09 22:49:25  lazarus
  MWE: Converted to Unix fileformat

  Revision 1.18  2002/01/09 22:47:29  lazarus
  MWE: published OnClick for checkbox family

  Revision 1.17  2001/12/07 20:12:15  lazarus
  Added a watch dialog.
  Shane

  Revision 1.16  2001/10/19 14:27:43  lazarus
  MG: fixed customradiogroup OnClick + ItemIndex

  Revision 1.15  2001/06/14 14:57:58  lazarus
  MG: small bugfixes and less notes

  Revision 1.14  2001/03/27 21:12:53  lazarus
  MWE:
    + Turned on longstrings
    + modified memotest to add lines

  Revision 1.13  2001/02/02 14:23:38  lazarus
  Start of code completion code.
  Shane

  Revision 1.12  2001/02/01 16:45:19  lazarus
  Started the code completion.
  Shane

  Revision 1.11  2001/01/28 21:06:07  lazarus
  Changes for TComboBox events KeyPress Focus.
  Shane

  Revision 1.10  2001/01/11 20:16:47  lazarus
  Added some TImageList code.
  Added a bookmark resource with 10 resource images.
  Removed some of the IFDEF's in mwCustomEdit around the inherited code.
  Shane

  Revision 1.8  2001/01/05 17:44:37  lazarus
  ViewUnits1, ViewForms1 and MessageDlg are all loaded from their resources and all controls are auto-created on them.
  There are still a few problems with some controls so I haven't converted all forms.
  Shane

  Revision 1.7  2001/01/04 15:09:05  lazarus
  Tested TCustomEdit.Readonly, MaxLength and CharCase.
  Shane

  Revision 1.6  2001/01/04 13:52:00  lazarus
  Minor changes to TEdit.
  Not tested.
  Shane

  Revision 1.5  2000/12/29 15:04:07  lazarus
  Added more images to the resource.
  Shane

  Revision 1.4  2000/12/01 15:50:39  lazarus
  changed the TCOmponentInterface SetPropByName.  It works for a few properties, but not all.
  Shane

  Revision 1.3  2000/11/29 21:22:35  lazarus
  New Object Inspector code
  Shane

  Revision 1.2  2000/07/16 12:45:01  lazarus
  Added procedure ListBox.Clear (changes by chris, added by stoppok)

  Revision 1.1  2000/07/13 10:28:24  michael
  + Initial import

  Revision 1.28  2000/07/09 20:41:20  lazarus
  Added Attachsignals method to custombobobox, stoppok

  Revision 1.27  2000/06/29 21:07:08  lazarus
  some more published properties for combobox, stoppok

  Revision 1.26  2000/06/24 21:30:19  lazarus
  *** empty log message ***

  Revision 1.25  2000/06/16 13:33:21  lazarus
  Created a new method for adding controls to the toolbar to be dropped onto the form!
  Shane

  Revision 1.24  2000/05/30 22:28:41  lazarus
  MWE:
    Applied patches from Vincent Snijders:
    + Added GetWindowRect
    * Fixed horz label alignment
    + Added vert label alignment

  Revision 1.23  2000/05/08 12:54:19  lazarus
  Removed some writeln's
  Added alignment for the TLabel.  Isn't working quite right.
  Added the shell code for WindowFromPoint and GetParent.
  Added FindLCLWindow
  Shane

  Revision 1.22  2000/04/18 20:06:39  lazarus
  Added some functions to Compiler.pp

  Revision 1.21  2000/04/13 21:25:16  lazarus
  MWE:
    ~ Added some docu and did some cleanup.
  Hans-Joachim Ott <hjott@compuserve.com>:
    * TMemo.Lines works now.
    + TMemo has now a property Scrollbar.
    = TControl.GetTextBuf revised :-)
    + Implementation for CListBox columns added
    * Bug in TGtkCListStringList.Assign corrected.

  Revision 1.20  2000/04/10 14:03:06  lazarus
  Added SetProp and GetProp winapi calls.
  Added ONChange to the TEdit's published property list.
  Shane

  Revision 1.19  2000/03/30 21:57:45  lazarus
  MWE:
    + Added some general functions to Get/Set the Main/Fixed/CoreChild
      widget
    + Started with graphic scalig/depth stuff. This is way from finished

  Hans-Joachim Ott <hjott@compuserve.com>:
    + Added some improvements for TMEMO

  Revision 1.18  2000/03/30 18:07:54  lazarus
  Added some drag and drop code
  Added code to change the unit name when it's saved as a different name.  Not perfect yet because if you are in a comment it fails.

  Shane

  Revision 1.17  2000/02/28 19:16:04  lazarus
  Added code to the FILE CLOSE to check if the file was modified.  HAven't gotten the application.messagebox working yet though.  It won't stay visible.
  Shane

  Revision 1.16  2000/02/24 21:15:30  lazarus
  Added TCustomForm.GetClientRect and RequestAlign to try and get the controls to align correctly when a MENU is present.  Not Complete yet.

  Fixed the bug in TEdit that caused it not to update it's text property.  I will have to
  look at TMemo to see if anything there was affected.

  Added SetRect to WinAPI calls
  Added AdjustWindowRectEx to WINAPI calls.
  Shane

  Revision 1.15  2000/02/22 22:19:50  lazarus
  TCustomDialog is a descendant of TComponent.
  Initial cuts a form's proper Close behaviour.

  Revision 1.14  2000/02/22 21:51:40  lazarus
  MWE: Removed some double (or triple) event declarations.
       The latest compiler doesn't like it

  Revision 1.13  2000/02/21 17:38:04  lazarus
  Added modalresult to TCustomForm
  Added a View Units dialog box
  Added a View Forms dialog box
  Added a New Unit menu selection
  Added a New Form menu selection
  Shane

  Revision 1.12  2000/02/18 19:38:53  lazarus
  Implemented TCustomForm.Position
  Better implemented border styles. Still needs some tweaks.
  Changed TComboBox and TListBox to work again, at least partially.
  Minor cleanups.

  Revision 1.11  2000/01/04 19:16:09  lazarus
  Stoppok:
     - new messages LM_GETVALUE, LM_SETVALUE, LM_SETPROPERTIES
     - changed trackbar, progressbar, checkbox to use above messages
     - some more published properties for above components
       (all properties derived from TWinControl)
     - new functions SetValue, GetValue, SetProperties in gtk-interface

  Revision 1.10  1999/12/30 19:04:13  lazarus
   - Made TRadiobutton work again
   - Some more cleanups to checkbox code
           stoppok

  Revision 1.9  1999/12/30 10:38:59  lazarus

    Some changes to Checkbox code.
      stoppok

  Revision 1.8  1999/12/29 01:30:02  lazarus

    Made groupbox working again.
      stoppok

  Revision 1.7  1999/12/18 18:27:32  lazarus
  MWE:
    Rearranged some events to get a LM_SIZE, LM_MOVE and LM_WINDOWPOSCHANGED
    Initialized the TextMetricstruct to zeros to clear unset values
    Get mwEdit to show more than one line
    Fixed some errors in earlier commits

  Revision 1.6  1999/12/07 01:19:26  lazarus
  MWE:
    Removed some double events
    Changed location of SetCallBack
    Added call to remove signals
    Restructured somethings
    Started to add default handlers in TWinControl
    Made some parts of TControl and TWinControl more delphi compatible
    ... and lots more ...

  Revision 1.5  1999/11/01 01:28:30  lazarus
  MWE: Implemented HandleNeeded/CreateHandle/CreateWND
       Now controls are created on demand. A call to CreateComponent shouldn't
       be needed. It is now part of CreateWnd

  Revision 1.4  1999/10/27 17:27:07  lazarus
  Added alot of changes and TODO: statements
  shane

  Revision 1.3  1999/10/25 17:38:52  lazarus
  More stuff added for compatability.  Most stuff added was put in the windows.pp file.  CONST scroll bar messages and such.  2 functions were also added to that unit that needs to be completed.
  Shane

  Revision 1.2  1999/10/22 21:01:51  lazarus

        Removed calls to InterfaceObjects except for controls.pp. Commented
        out any gtk depend lines of code.     MAH

  Revision 1.1  1999/10/19 19:16:51  lazarus
  renamed stdcontrols.pp stdctrls.pp
  Shane

  Revision 1.9  1999/08/21 13:57:41  lazarus
  Implemented TListBox.BorderStyle. The listbox is scrollable now.

  Revision 1.8  1999/08/14 10:05:56  lazarus
  Added TListBox ItemIndex property. Made ItemIndex public for TComboBox and TListBox.

  Revision 1.7  1999/08/11 20:41:34  lazarus

  Minor changes and additions made.  Lazarus may not compile due to these changes

  Revision 1.6  1999/08/07 17:59:23  lazarus

        buttons.pp   the DoLeave and DoEnter were connected to the wrong
                     event.

        The rest were modified to use the new SendMessage function.   MAH

 }


