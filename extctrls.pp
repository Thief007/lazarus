{  $Id$  }
{
 /***************************************************************************
                               extctrls.pp
                               -----------
                             Component Library Extended Controls
                   Initial Revision  : Sat Jul 26 12:04:35 PDT 1999

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
unit ExtCtrls;

{$mode objfpc}
{$H+}

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}

uses
  SysUtils, Classes, LCLStrConsts, LCLType, LCLProc, LResources, Controls,
  Forms, StdCtrls, lMessages, GraphType, Graphics, LCLIntf, CustomTimer;

type
  { workaround problem with fcl }
  TAbstractReader = TReader;

  { TCustomPage }

  TPageFlag = (
    pfAdded,  // page handle added to notebook handle
    pfRemoving
    );
  TPageFlags = set of TPageFlag;

  TCustomPage = class(TWinControl)
  private
    FTabVisible: Boolean;
    FFlags: TPageFlags;
    FImageIndex: integer;
    function GetTabVisible: Boolean;
    procedure SetImageIndex(const AValue: integer);
    procedure SetTabVisible(const AValue: Boolean);
  protected
    procedure WMPaint(var Msg: TLMPaint); message LM_PAINT;
    procedure SetParent(AParent: TWinControl); override;
    property Flags: TPageFlags read FFlags write FFlags;
    procedure CMHitTest(var Message: TLMNCHITTEST); message CM_HITTEST;
    procedure DestroyHandle; override;
    function GetPageIndex: integer;
    procedure SetPageIndex(AValue: Integer);
  public
    constructor Create(TheOwner: TComponent); override;
    procedure AdjustClientRect(var ARect: TRect); override;
    function CanTab: boolean; override;
    function IsVisible: Boolean; override;
    property PageIndex: Integer read GetPageIndex write SetPageIndex;
    property TabVisible: Boolean read GetTabVisible write SetTabVisible default True;
    property ImageIndex: integer read FImageIndex write SetImageIndex default -1;
    property Left stored False;
    property Top stored False;
    property Width stored False;
    property Height stored False;
    property TabOrder stored False;
  end;

  TCustomPageClass = class of TCustomPage;


  { TNBPages }

  TCustomNotebook = class;

  TNBPages = class(TStrings)
  private
    FPageList: TList;
    FNotebook: TCustomNotebook;
  protected
    function Get(Index: Integer): String; override;
    function GetCount: Integer; override;
    function GetObject(Index: Integer): TObject; override;
    procedure Put(Index: Integer; const S: String); override;
  public
    constructor Create(thePageList: TList; theNotebook: TCustomNotebook);
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: String); override;
    procedure Move(CurIndex, NewIndex: Integer); override;
  end;


  { TCustomNotebook }

  TTabChangingEvent = procedure(Sender: TObject;
    var AllowChange: Boolean) of object;

  TTabPosition = (tpTop, tpBottom, tpLeft, tpRight);

  TTabStyle = (tsTabs, tsButtons, tsFlatButtons);

  TTabGetImageEvent = procedure(Sender: TObject; TabIndex: Integer;
    var ImageIndex: Integer) of object;

  TNoteBookOption = (nboShowCloseButtons, nboMultiLine);
  TNoteBookOptions = set of TNoteBookOption;

  TCustomNotebook = class(TWinControl)
  private
    FAccess: TStrings; // TNBPages
    FAddingPages: boolean;
    FImages: TImageList;
    FLoadedPageIndex: integer;
    FOnChanging: TTabChangingEvent;
    FOnCloseTabClicked: TNotifyEvent;
    FOnGetImageIndex: TTabGetImageEvent;
    fOnPageChanged: TNotifyEvent;
    FOptions: TNoteBookOptions;
    FPageIndex: Integer;
    FPageIndexOnLastChange: integer;
    FPageList: TList;  // List of TCustomPage
    FShowTabs: Boolean;
    FTabPosition: TTabPosition;
    Procedure CNNotify(var Message: TLMNotify); message CN_NOTIFY;
    procedure DoSendPageIndex;
    procedure DoSendShowTabs;
    procedure DoSendTabPosition;
    function GetActivePage: String;
    function GetActivePageComponent: TCustomPage;
    function GetPage(aIndex: Integer): TCustomPage;
    function GetPageCount : integer;
    function GetPageIndex: Integer;
    procedure InsertPage(APage: TCustomPage; Index: Integer);
    function IsStoredActivePage: boolean;
    procedure ChildPageSetTabVisible(APage: TCustomPage; AValue: Boolean;
                                     AIndex: Integer);
    procedure MoveTab(Sender: TObject; NewIndex: Integer);
    procedure WSMovePage(APage: TCustomPage; NewIndex: Integer);
    procedure RemovePage(Index: Integer);
    procedure SetActivePage(const Value: String);
    procedure SetActivePageComponent(const AValue: TCustomPage);
    procedure SetImages(const AValue: TImageList);
    procedure SetOptions(const AValue: TNoteBookOptions);
    procedure SetPageIndex(AValue: Integer);
    procedure SetPages(AValue: TStrings);
    procedure SetShowTabs(AValue: Boolean);
    procedure SetTabPosition(tabPos: TTabPosition);
    procedure ShowCurrentPage;
    procedure UpdateAllDesignerFlags;
    procedure UpdateDesignerFlags(APageIndex: integer);
  protected
    PageClass: TCustomPageClass;
    procedure CreateWnd; override;
    procedure DoCreateWnd; virtual;
    procedure Change; virtual;
    procedure Loaded; override;
    procedure ReadState(Reader: TAbstractReader); override;
    procedure ShowControl(APage: TControl); override;
    procedure UpdateTabProperties; virtual;
    function ChildClassAllowed(ChildClass: TClass): boolean; override;
    property ActivePageComponent: TCustomPage read GetActivePageComponent
                                              write SetActivePageComponent;
    property ActivePage: String read GetActivePage write SetActivePage
                                                      stored IsStoredActivePage;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function TabIndexAtClientPos(ClientPos: TPoint): integer;
    function CanTab: boolean; override;
    function GetImageIndex(ThePageIndex: Integer): Integer; virtual;
    function IndexOf(APage: TCustomPage): integer;
    function CustomPage(Index: integer): TCustomPage;
    function CanChangePageIndex: boolean; virtual;
    function GetMinimumTabWidth: integer; virtual;
    function GetMinimumTabHeight: integer; virtual;
  public
    //property MultiLine: boolean read fMultiLine write SetMultiLine default false;
    procedure DoCloseTabClicked(APage: TCustomPage); virtual;
    property Images: TImageList read FImages write SetImages;
    property OnChanging: TTabChangingEvent read FOnChanging write FOnChanging;
    property OnCloseTabClicked: TNotifyEvent read FOnCloseTabClicked
                                             write FOnCloseTabClicked;
    property OnGetImageIndex: TTabGetImageEvent read FOnGetImageIndex
                                                write FOnGetImageIndex;
    property OnPageChanged: TNotifyEvent read fOnPageChanged write fOnPageChanged;
    property Options: TNoteBookOptions read FOptions write SetOptions;
    property Page[Index: Integer]: TCustomPage read GetPage;
    property PageCount: integer read GetPageCount;
    property PageIndex: Integer read GetPageIndex write SetPageIndex default -1;
    property PageList: TList read fPageList;
    property Pages: TStrings read fAccess write SetPages;
    property ShowTabs: Boolean read fShowTabs write SetShowTabs default True;
    property TabPosition: TTabPosition read fTabPosition write SetTabPosition;
  published
    property TabStop default true;
  end;


  { TPage }

  TPage = class(TCustomPage)
  published
    property Caption;
    property ChildSizing;
    property ClientWidth;
    property ClientHeight;
    property ImageIndex;
    property Left stored False;
    property Top stored False;
    property Width stored False;
    property Height stored False;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property PageIndex stored False;
    property ParentShowHint;
    property PopupMenu;
    property TabOrder stored False;
    property Visible;
  end;


  { TNotebook }

  TNotebook = class(TCustomNotebook)
  private
    function GetActiveNotebookPageComponent: TPage;
    function GetNoteBookPage(Index: Integer): TPage;
    procedure SetActiveNotebookPageComponent(const AValue: TPage);
  public
    constructor Create(TheOwner: TComponent); override;
    property Page[Index: Integer]: TPage read GetNoteBookPage;
    property ActivePageComponent: TPage read GetActiveNotebookPageComponent
                                        write SetActiveNotebookPageComponent;
    property Pages;
  published
    property ActivePage;
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Enabled;
    property Images;
    property OnChangeBounds;
    property OnCloseTabClicked;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnGetImageIndex;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnPageChanged;
    property OnResize;
    property Options;
    property PageIndex;
    property ShowTabs;
  end;


  { Timer }

  TTimer = class (TCustomTimer)
  end;


  { TIdleTimer }

  TIdleTimerAutoEvent = (
    itaOnIdle,
    itaOnIdleEnd,
    itaOnUserInput
    );
  TIdleTimerAutoEvents = set of TIdleTimerAutoEvent;

  TIdleTimer = class(TTimer)
  private
    FAutoEnabled: boolean;
    FAutoEndEvent: TIdleTimerAutoEvent;
    FAutoStartEvent: TIdleTimerAutoEvent;
    FHandlersConnected: boolean;
    procedure UpdateHandlers;
    procedure SetAutoEndEvent(const AValue: TIdleTimerAutoEvent);
    procedure SetAutoStartEvent(const AValue: TIdleTimerAutoEvent);
  protected
    procedure SetAutoEnabled(const AValue: boolean); virtual;
    procedure DoOnIdle(Sender: TObject); virtual;
    procedure DoOnIdleEnd(Sender: TObject); virtual;
    procedure DoOnUserInput(Sender: TObject; Msg: Cardinal); virtual;
    procedure Loaded; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property AutoEnabled: boolean read FAutoEnabled write SetAutoEnabled;
    property AutoStartEvent: TIdleTimerAutoEvent
      read FAutoStartEvent write SetAutoStartEvent default itaOnIdle;
    property AutoEndEvent: TIdleTimerAutoEvent
      read FAutoEndEvent write SetAutoEndEvent default itaOnUserInput;
  end;


  { TShape }

  TShapeType = (stRectangle, stSquare, stRoundRect, stRoundSquare,
    stEllipse, stCircle, stSquaredDiamond, stDiamond);

  TShape = class(TGraphicControl)
  private
    FPen: TPen;
    FBrush: TBrush;
    FShape: TShapeType;
    procedure SetBrush(Value: TBrush);
    procedure SetPen(Value: TPen);
    procedure SetShape(Value: TShapeType);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure StyleChanged(Sender: TObject);
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Brush: TBrush read FBrush write SetBrush;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ParentShowHint;
    property Pen: TPen read FPen write SetPen;
    property OnChangeBounds;
//    property OnDragDrop;
//    property OnDragOver;
//    property OnEndDock;
//    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
//    property OnStartDock;
//    property OnStartDrag;
    property Shape: TShapeType read FShape write SetShape;
    property ShowHint;
    property Visible;
  end;


  { TCustomSplitter }

  TResizeStyle = (rsLine,rsNone,rsPattern,rsUpdate);

  TCanResizeEvent = procedure(Sender: TObject; var NewSize: Integer;
    var Accept: Boolean) of object;
  { TCustomSplitter is a control to interactively resize another control.
    It is a vertical or horizontal bar anchored to a side of a control.
    You can either set the Align property to alLeft (alRight,alTop,alBottom),
    then it will become a vertical bar, aligned to the left and when the user
    moves it with the mouse, the control to the left with the same Align=alLeft
    will be resized.
    The second more flexible possibility is to set the properties Align=alNone,
    AnchorSides and Orientation.
    }
  TCustomSplitter = class(TCustomControl)
  private
    FAutoSnap: boolean;
    FBeveled: boolean;
    FMinSize: integer;
    FOnCanResize: TCanResizeEvent;
    FOnMoved: TNotifyEvent;
    FResizeAnchor: TAnchorKind;
    FResizeStyle: TResizeStyle;
    FSplitDragging: Boolean;
    fSplitterStartMouseXY: TPoint; // in screen coordinates
    fSplitterStartLeftTop: TPoint; // in screen coordinates
    function GetResizeControl: TControl;
    procedure SetAutoSnap(const AValue: boolean);
    procedure SetBeveled(const AValue: boolean);
    procedure SetMinSize(const AValue: integer);
    procedure SetResizeAnchor(const AValue: TAnchorKind);
    procedure SetResizeControl(const AValue: TControl);
    procedure SetResizeStyle(const AValue: TResizeStyle);
  protected
    procedure StartSplitterMove(Restart: boolean; const MouseXY: TPoint);
    procedure MouseDown(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    function FindAlignControl: TControl;
    function FindAlignOtherControl: TControl;
    procedure SetAlign(Value: TAlign); override;
    procedure SetAnchors(const AValue: TAnchors); override;
    procedure CheckAlignment;
    function CheckNewSize(var NewSize: integer): boolean; virtual;
    procedure Paint; override;
  public
    constructor Create(TheOwner: TComponent); override;
    procedure AnchorSplitter(Kind: TAnchorKind; AControl: TControl);
    property ResizeControl: TControl read GetResizeControl write SetResizeControl;
    function GetOtherResizeControl: TControl;
  public
    property Align default alLeft;
    property ResizeStyle: TResizeStyle read FResizeStyle write SetResizeStyle default rsUpdate;
    property AutoSnap: boolean read FAutoSnap write SetAutoSnap default true;
    property Beveled: boolean read FBeveled write SetBeveled default false;
    property MinSize: integer read FMinSize write SetMinSize default 30;
    property OnCanResize: TCanResizeEvent read FOnCanResize write FOnCanResize;
    property OnMoved: TNotifyEvent read FOnMoved write FOnMoved;
    property Width default 5;
    property Cursor default crHSplit;
    property ResizeAnchor: TAnchorKind read FResizeAnchor write SetResizeAnchor default akLeft;
  end;


  { TSplitter }

  TSplitter = class(TCustomSplitter)
  published
    property Align;
    property Anchors;
    property AutoSnap;
    property Beveled;
    property Color;
    property Constraints;
    property Cursor;
    property Height;
    property MinSize;
    property ParentColor;
    property ParentShowHint;
    property ResizeStyle;
    property ShowHint;
    property Visible;
    property Width;
    property OnCanResize;
    property OnChangeBounds;
    property OnMoved;
  end;


  { TPaintBox }

  TPaintBox = class(TGraphicControl)
  private
    FOnPaint: TNotifyEvent;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Canvas;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Color;
    property Constraints;
//    property DragCursor;
//    property DragKind;
//    property DragMode;
    property Enabled;
    property Font;
    property Hint;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnChangeBounds;
    property OnClick;
    property OnDblClick;
//    property OnDragDrop;
//    property OnDragOver;
//    property OnEndDock;
//    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
    property OnResize;
//    property OnStartDock;
//    property OnStartDrag;
  end;


  { TCustomImage }

  TCustomImage = class(TGraphicControl)
  private
    FPicture: TPicture;
    FCenter: Boolean;
    FProportional: Boolean;
    FTransparent: Boolean;
    FStretch: Boolean;
    FUseParentCanvas: boolean;
    function  GetCanvas: TCanvas;
    procedure SetPicture(const AValue: TPicture);
    procedure SetCenter(Value : Boolean);
    procedure SetProportional(const AValue: Boolean);
    procedure SetStretch(Value : Boolean);
    procedure SetTransparent(Value : Boolean);
    procedure PictureChanged(SEnder : TObject);
  protected
    function DestRect: TRect; virtual;
    procedure DoAutoSize; Override;
    Procedure Paint; Override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Canvas: TCanvas read GetCanvas;
  public
    Property Align;
    property AutoSize;
    property Center: Boolean read FCenter write SetCenter;
    property Constraints;
    property Picture: TPicture read FPicture write SetPicture;
    property Visible;
    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property Stretch: Boolean read FStretch write SetStretch;
    property Transparent: Boolean read FTransparent write SetTransparent;
    property Proportional: Boolean read FProportional write SetProportional default false;
  end;


  { TImage }

  TImage = class(TCustomImage)
  published
    property Align;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property Center;
    property Constraints;
    property OnChangeBounds;
    property OnClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnPaint;
    property OnResize;
    property Picture;
    property PopupMenu;
    property Proportional;
    property Stretch;
    property Transparent;
    property Visible;
  end;


  { TBevel }

  TBevelStyle = (bsLowered, bsRaised);
  TBevelShape=(bsBox, bsFrame, bsTopLine, bsBottomLine, bsLeftLine, bsRightLine);

  TBevel = Class(TGraphicControl)
  private
    FStyle:TBevelStyle;
    FShape:TBevelShape;
    function GetStyle:TBevelStyle;
    procedure SetStyle(aStyle:TBevelStyle);
    function GetShape:TBevelShape;
    procedure SetShape(aShape:TBevelShape);
  protected
    procedure Paint; Override;
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Invalidate; override;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Height;
    property Left;
    property Name;
    property Shape:TBevelShape Read GetShape Write SetShape Default bsBox;
    property Top;
    property Style:TBevelStyle Read GetStyle Write SetStyle Default bsLowered;
    property Visible;
    property Width;
    property OnChangeBounds;
    property OnResize;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnPaint;
  end;


  { TCustomRadioGroup }

  TColumnLayout = (
    clHorizontalThenVertical,
    clVerticalThenHorizontal
    );

  { TCustomRadioGroup }

  TCustomRadioGroup = class(TCustomGroupBox)
    procedure ItemExit(Sender: TObject);
  private
    FButtonList: TList; // list of TRadioButton
    FColumnLayout: TColumnLayout;
    FColumns: integer;
    FCreatingWnd: boolean;
    FHiddenButton: TRadioButton;
    FItemIndex: integer;
    FItems: TStrings;
    FLastClickedItemIndex: integer;
    FOnClick: TNotifyEvent;
    FReading: boolean;
    fIgnoreClicks: boolean;
    procedure ItemsChanged(Sender: TObject);
    procedure Clicked(Sender: TObject);
    procedure Changed(Sender: TObject);
    procedure ItemEnter(Sender: TObject);
    procedure DoPositionButtons;
    procedure SetColumnLayout(const AValue: TColumnLayout);
  protected
    procedure UpdateRadioButtonStates; virtual;
    procedure ReadState(Reader: TReader); override;
    procedure SetItem(Value: TStrings);
    procedure SetColumns(Value: integer);
    procedure SetItemIndex(Value: integer);
    function GetItemIndex: integer;
    procedure Resize; override;
    procedure CheckItemIndexChanged; virtual;
  protected
    property ItemIndex: integer read GetItemIndex write SetItemIndex default -1;
    property Items: TStrings read FItems write SetItem;
    property Columns: integer read FColumns write SetColumns default 1;
    property ColumnLayout: TColumnLayout read FColumnLayout write SetColumnLayout default clHorizontalThenVertical;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function CanModify: boolean; virtual;
    procedure CreateWnd; override;
    function Rows: integer;
  end;


  { TRadioGroup }

  TRadioGroup = class(TCustomRadioGroup)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Caption;
    property ChildSizing;
    property Color;
    property ColumnLayout;
    property Columns;
    property Constraints;
    property Ctl3D;
    property Enabled;
    property ItemIndex;
    property Items;
    property OnChangeBounds;
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
    property ParentColor;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
  end;


  { TCustomCheckGroup }

  TCheckGroupClicked = procedure(Sender: TObject; Index: integer) of object;

  TCustomCheckGroup = class(TCustomGroupBox)
  private
    FButtonList: TList; // list of TCheckBox
    FColumnLayout: TColumnLayout;
    FCreatingWnd: boolean;
    FItems: TStrings;
    FColumns: integer;
    FOnItemClick: TCheckGroupClicked;
    function GetChecked(Index: integer): boolean;
    function GetCheckEnabled(Index: integer): boolean;
    procedure Clicked(Sender: TObject);
    procedure DoClick(Index: integer);
    procedure DoPositionButtons;
    procedure ItemsChanged (Sender : TObject);
    procedure SetChecked(Index: integer; const AValue: boolean);
    procedure SetCheckEnabled(Index: integer; const AValue: boolean);
    procedure SetColumnLayout(const AValue: TColumnLayout);
    procedure UpdateItems;
  protected
    procedure SetItems(Value: TStrings);
    procedure SetColumns(Value: integer);
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadData(Stream: TStream);
    procedure WriteData(Stream: TStream);
    procedure Loaded; override;
    procedure DoOnResize; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function Rows: integer;
  public
    property Items: TStrings read FItems write SetItems;
    property Checked[Index: integer]: boolean read GetChecked write SetChecked;
    property CheckEnabled[Index: integer]: boolean read GetCheckEnabled write SetCheckEnabled;
    property Columns: integer read FColumns write SetColumns default 1;
    property ColumnLayout: TColumnLayout read FColumnLayout write SetColumnLayout default clHorizontalThenVertical;
    property OnItemClick: TCheckGroupClicked read FOnItemClick write FOnItemClick;
  end;


  { TCheckGroup }

  TCheckGroup = class(TCustomCheckGroup)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Caption;
    property ChildSizing;
    property Color;
    property ColumnLayout;
    property Columns;
    property Constraints;
    property Ctl3D;
    property Enabled;
    property Items;
    property OnChangeBounds;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnItemClick;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property ParentColor;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
  end;


  { TBoundLabel }

  TBoundLabel = class(TCustomLabel)
  public
    constructor Create(TheOwner: TComponent); override;
    property FocusControl;
  published
    property Caption;
    property Color;
    property Height;
    property Left;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    property Top;
    property Layout;
    property WordWrap;
    property Width;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    //property OnEnter;
    //property OnExit;
  end;


  { TCustomLabeledEdit }

  TLabelPosition = (lpAbove, lpBelow, lpLeft, lpRight);

  TCustomLabeledEdit = class(TCustomEdit)
  private
    FEditLabel: TBoundLabel;
    FLabelPosition: TLabelPosition;
    FLabelSpacing: Integer;
    procedure SetLabelPosition(const Value: TLabelPosition);
    procedure SetLabelSpacing(const Value: Integer);
  protected
    procedure SetParent(AParent: TWinControl); override;
    procedure SetName(const Value: TComponentName); override;
    procedure DoSetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure DoPositionLabel; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CMVisibleChanged(var Msg: TLMessage); message CM_VISIBLECHANGED;
    procedure CMEnabledChanged(var Msg: TLMessage); message CM_ENABLEDCHANGED;
    procedure CreateInternalLabel; virtual;
  public
    constructor Create(TheOwner: TComponent); override;
    property EditLabel: TBoundLabel read FEditLabel stored false;
    property LabelPosition: TLabelPosition read FLabelPosition
                                         write SetLabelPosition default lpAbove;
    property LabelSpacing: Integer read FLabelSpacing write SetLabelSpacing
                                                                      default 3;
  end;


  { TLabeledEdit }

  TLabeledEdit = class(TCustomLabeledEdit)
  published
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property CharCase;
    property Color;
    property Constraints;
    property EditLabel;
    property Enabled;
    property LabelPosition;
    property LabelSpacing;
    property MaxLength;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PasswordChar;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Text;
    property Visible;
    property OnChange;
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
  end;


  { TCustomPanel }

  TPanelBevel = TBevelCut;
  TBevelWidth = 1..Maxint;

  TCustomPanel = class(TCustomControl)
  private
    FBevelInner, FBevelOuter : TPanelBevel;
    FBevelWidth : TBevelWidth;
    FBorderWidth : TBorderWidth;
    FAlignment : TAlignment;
//    FCaption : TCaption;
    FFullRepaint: Boolean;
    procedure SetAlignment(const Value : TAlignment);
    procedure SetBevelInner(const Value: TPanelBevel);
    procedure SetBevelOuter(const Value: TPanelBevel);
    procedure SetBevelWidth(const Value: TBevelWidth);
    procedure SetBorderWidth(const Value: TBorderWidth);
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure RealSetText(const Value: TCaption); override;
    procedure Paint; override;
    function ParentColorIsStored: boolean;
    Function CanTab: Boolean; override;
  public
    constructor Create(TheOwner: TComponent); override;
    property Align default alNone;
    property Alignment: TAlignment read FAlignment write SetAlignment default taCenter;
    property BevelInner: TPanelBevel read FBevelInner write SetBevelInner default bvNone;
    property BevelOuter: TPanelBevel read FBevelOuter write SetBevelOuter default bvRaised;
    property BevelWidth: TBevelWidth read FBevelWidth write SetBevelWidth default 1;
    property BorderWidth: TBorderWidth read FBorderWidth write SetBorderWidth default 0;
    property Color default clBtnFace;
    property Caption read GetText write SetText;
    property FullRepaint: Boolean read FFullRepaint write FFullRepaint default True;
    property ParentColor default true;
    property TabStop default False;
  end;


  { TPanel }

  TPanel = class(TCustomPanel)
  published
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property BorderWidth;
    property BorderStyle;
    property Caption;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property DragMode;
    property Enabled;
    property Font;
    property FullRepaint;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
  end;


const
  TCN_First = 0-550;
  TCN_SELCHANGE = TCN_FIRST - 1;
  TCN_SELCHANGING = TCN_FIRST - 2;

procedure Register;

implementation

// !!! Avoid unit circles. Only add units if really needed.
uses
  Math, WSExtCtrls;

procedure Register;
begin
  RegisterComponents('Standard',[TRadioGroup,TCheckGroup,TPanel]);
  RegisterComponents('Additional',[TImage,TShape,TBevel,TPaintBox,TNotebook,
                                   TLabeledEdit,TSplitter]);
  RegisterComponents('System',[TTimer,TIdleTimer]);
  RegisterNoIcon([TPage]);
end;

{$I custompage.inc}
{$I page.inc}
{$I customnotebook.inc}
{$I notebook.inc}
{$I timer.inc}
{$I idletimer.inc}
{$I shape.inc}
{$I customsplitter.inc}
{$I paintbox.inc}
{$I customcheckgroup.inc}
{$I boundlabel.inc}
{$I customlabelededit.inc}
{$I custompanel.inc}
{$I radiogroup.inc}
{$I bevel.inc}
{$I customimage.inc}

end.

