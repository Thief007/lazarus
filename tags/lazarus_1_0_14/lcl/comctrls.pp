{ $Id$}
{
 /***************************************************************************
                               ComCtrls.pp
                               -----------
                             Component Library Common Controls
                   Initial Revision  : Sat Apr 10 22:49:32 CST 1999


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
{
@abstract(Just a try to provide the same objects as the Delphi comctrls unit)
@author(TCustomProgressBar - Stefan Hille <stoppok@osibisa.ms.sub.org>)
@author(TTrackBar - Stefan Hille <stoppok@osibisa.ms.sub.org>)
@created(1999)
}
unit ComCtrls;

{$mode objfpc}{$H+}
{$I lcl_defines.inc}

interface

uses
  SysUtils, Types, Classes, Math, LCLStrConsts, LResources, LCLIntf, LCLType,
  FileUtil, LCLProc, AvgLvlTree, LMessages, ImgList, ActnList, GraphType,
  Graphics, Menus, Controls, Forms, StdCtrls, ExtCtrls, ToolWin, Buttons,
  Themes, WSLCLClasses, LCLClasses;

type
  THitTest = (htAbove, htBelow, htNowhere, htOnItem, htOnButton, htOnIcon,
    htOnIndent, htOnLabel, htOnRight, htOnStateIcon, htToLeft, htToRight);
  THitTests = set of THitTest;

  TStatusPanelStyle = (psText, psOwnerDraw);
  TStatusPanelBevel = (pbNone, pbLowered, pbRaised);

  TStatusBar = class;  //forward declaration

  TPanelPart = (
    ppText,    // for text and text alignment
    ppBorder,  // for bevel and style
    ppWidth    // for width
    );
  TPanelParts = set of TPanelPart;

  { TStatusPanel }

  //added.
  TStatusPanelClass = class of TStatusPanel;
  
  TStatusPanel = class(TCollectionItem)
  private
    FText: TCaption;
    FWidth: Integer;
    FAlignment: TAlignment;
    FBevel: TStatusPanelBevel;
    FParentBiDiMode: Boolean;
    FStyle: TStatusPanelStyle;
    procedure SetAlignment(Value: TAlignment);
    procedure SetBevel(Value: TStatusPanelBevel);
    procedure SetStyle(Value: TStatusPanelStyle);
    procedure SetText(const Value: TCaption);
    procedure SetWidth(Value: Integer);
  protected
    // field to use by interface. do not use it in the LCL
    FIntfFlag: Integer;
    function GetDisplayName: string; override;
    procedure PanelChanged(const Parts: TPanelParts);
    procedure SetIndex(Value: Integer); override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function StatusBar: TStatusBar;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property Bevel: TStatusPanelBevel read FBevel write SetBevel default pbLowered;
    property Style: TStatusPanelStyle read FStyle write SetStyle default psText;
    property Text: TCaption read FText write SetText;
    property Width: Integer read FWidth write SetWidth;
  end;

  TStatusPanels = class(TCollection)
  private
    FStatusBar: TStatusBar;
    function GetItem(Index: Integer): TStatusPanel;
    procedure SetItem(Index: Integer; Value: TStatusPanel);
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AStatusBar: TStatusBar);
    function Add: TStatusPanel;
    property Items[Index: Integer]: TStatusPanel read GetItem write SetItem; default;
    property StatusBar: TStatusBar read FStatusBar;
  end;

  TSBCreatePanelClassEvent = procedure(Sender: TStatusBar;
    var PanelClass: TStatusPanelClass) of object;

  TDrawPanelEvent = procedure(StatusBar: TStatusBar; Panel: TStatusPanel;
    const Rect: TRect) of object;

  { TStatusBar }

  TStatusBar = class(TWinControl)
  private
    FAutoHint: Boolean;
    FCanvas: TCanvas;
    FHandlePanelCount: integer; // realized panels in the Handle object
    FHandleObjectNeedsUpdate: boolean;
    FHandleUpdatePanelIndex: integer; // which panel in the handle object needs update
    FOnCreatePanelClass: TSBCreatePanelClassEvent;
    FSizeGrip: Boolean;
    FUpdateLock: integer; // set by BeginUpdate/EndUpdate
    FPanels: TStatusPanels;
    FSimpleText: TCaption;
    FSimplePanel: Boolean;
    FOnDrawPanel: TDrawPanelEvent;
    FOnHint: TNotifyEvent;
    procedure SetPanels(Value: TStatusPanels);
    procedure SetSimpleText(const Value : TCaption);
    procedure SetSimplePanel(Value : Boolean);
    procedure SetSizeGrip(const AValue: Boolean);
  protected
    class procedure WSRegisterClass; override;
    procedure BoundsChanged; override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure Loaded; override;
    procedure UpdateHandleObject(PanelIndex: integer; PanelParts: TPanelParts); virtual;
    procedure CalculatePreferredSize(
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;

    //added.
    function CreatePanel: TStatusPanel; virtual;
    function CreatePanels: TStatusPanels; virtual;
    function GetPanelClass: TStatusPanelClass; virtual;

    function DoSetApplicationHint(AHintStr: String): Boolean; virtual;
    function DoHint: Boolean; virtual;
    procedure DrawPanel(Panel: TStatusPanel; const Rect: TRect); virtual;
    procedure LMDrawItem(var Message: TLMDrawItems); message LM_DRAWITEM;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure InvalidatePanel(PanelIndex: integer; PanelParts: TPanelParts); virtual;
    procedure BeginUpdate;
    procedure EndUpdate;
    function ExecuteAction(ExeAction: TBasicAction): Boolean; override;
    function GetPanelIndexAt(X, Y: Integer): Integer;
    function SizeGripEnabled: Boolean;
    function UpdatingStatusBar: boolean;
    property Canvas: TCanvas read FCanvas;
  published
    property Action;
    property Align default alBottom;
    property Anchors;
    property AutoHint: Boolean read FAutoHint write FAutoHint default false;
    property AutoSize default true;
    property BorderSpacing;
    property Color default {$ifdef UseCLDefault}clDefault{$else}clBtnFace{$endif};
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Panels: TStatusPanels read FPanels write SetPanels;
    property ParentShowHint;
    property SimpleText: TCaption read FSimpleText write SetSimpleText;
    property SimplePanel: Boolean read FSimplePanel write SetSimplePanel default True;
    property SizeGrip: Boolean read FSizeGrip write SetSizeGrip default True;
    property ShowHint;
    property Visible default true;
    property OnClick;
    property OnContextPopup;
    property OnCreatePanelClass: TSBCreatePanelClassEvent read FOnCreatePanelClass write FOnCreatePanelClass;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawPanel: TDrawPanelEvent read FOnDrawPanel write FOnDrawPanel;
    property OnEndDock;
    property OnEndDrag;
    property OnHint: TNotifyEvent read FOnHint write FOnHint;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

  { TCustomPage }

  TPageFlag = (
    pfAdded,  // handle of page added to notebook handle
    pfAdding, // currently handle of page adding to notebook handle
    pfRemoving, // currently removing page handle from notebook handle
    pfInserting // currently inserting page into notebook
    );
  TPageFlags = set of TPageFlag;

  TCustomPage = class(TWinControl)
  private
    FTabVisible: Boolean;
    FFlags: TPageFlags;
    FImageIndex: TImageIndex;
    FOnHide: TNotifyEvent;
    FOnShow: TNotifyEvent;
    procedure SetImageIndex(const AValue: TImageIndex);
    procedure SetTabVisible(const AValue: Boolean);
  protected
    class procedure WSRegisterClass; override;
    procedure WMPaint(var Msg: TLMPaint); message LM_PAINT;
    procedure SetParent(AParent: TWinControl); override;
    property Flags: TPageFlags read FFlags write FFlags;
    procedure CMHitTest(var Message: TLMNCHITTEST); message CM_HITTEST;
    function GetPageIndex: integer; virtual;
    procedure SetPageIndex(AValue: Integer); virtual;
    function GetTabVisible: Boolean; virtual;
    function  DialogChar(var Message: TLMKey): boolean; override;
    procedure DoHide; virtual;
    procedure DoShow; virtual;
    procedure DestroyHandle; override;
    procedure RealSetText(const AValue: TCaption); override;
  public
    constructor Create(TheOwner: TComponent); override;
    function CanTab: boolean; override;
    function IsControlVisible: Boolean; override;
    function HandleObjectShouldBeVisible: boolean; override;
    function VisibleIndex: integer; virtual;
    property PageIndex: Integer read GetPageIndex write SetPageIndex;
    property TabVisible: Boolean read GetTabVisible write SetTabVisible default True;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property Left stored False;
    property Top stored False;
    property Width stored False;
    property Height stored False;
    property TabOrder stored False;
    property Visible stored false;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
  end;

  TCustomPageClass = class of TCustomPage;

  { TNBPages }

  TCustomTabControl = class;

  TNBPages = class(TStrings)
  private
    FPageList: TListWithEvent;
    FNotebook: TCustomTabControl;
    procedure PageListChange(Ptr: Pointer; AnAction: TListNotification);
  protected
    function Get(Index: Integer): String; override;
    function GetCount: Integer; override;
    function GetObject(Index: Integer): TObject; override;
    procedure Put(Index: Integer; const S: String); override;
  public
    constructor Create(thePageList: TListWithEvent;
                       theNotebook: TCustomTabControl);
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: String); override;
    procedure Move(CurIndex, NewIndex: Integer); override;
  end;

  { TCustomTabControl }

  TTabChangingEvent = procedure(Sender: TObject;
    var AllowChange: Boolean) of object;

  TTabPosition = (tpTop, tpBottom, tpLeft, tpRight);

  TTabStyle = (tsTabs, tsButtons, tsFlatButtons);

  TTabGetImageEvent = procedure(Sender: TObject; TabIndex: Integer;
    var ImageIndex: Integer) of object;

  // These are LCL additions
  TCTabControlOption = (
    nboShowCloseButtons, nboMultiLine, nboHidePageListPopup,
    nboKeyboardTabSwitch, nboShowAddTabButton);
  TCTabControlOptions = set of TCTabControlOption;
  TCTabControlCapability = (nbcShowCloseButtons, nbcMultiLine, nbcPageListPopup, nbcShowAddTabButton);
  TCTabControlCapabilities = set of TCTabControlCapability;
  // Don't use anymore the old names of these types
  // TNotebook is unrelated to CustomTabControl, so the types were renamed to
  // better names
  TNoteBookOption = TCTabControlOption deprecated;
  TNoteBookOptions = TCTabControlOptions deprecated;
  TNoteBookCapability = TCTabControlCapability deprecated;
  TNoteBookCapabilities = TCTabControlCapabilities deprecated;

  TDrawTabEvent = procedure(Control: TCustomTabControl; TabIndex: Integer;
    const Rect: TRect; Active: Boolean) of object;

  TCustomTabControl = class(TWinControl)
  private
    FAccess: TStrings; // TNBPages
    FAddingPages: boolean;
    FHotTrack: Boolean;
    FImages: TCustomImageList;
    FImageListChangeLink: TChangeLink;
    FLoadedPageIndex: integer;
    FMultiSelect: Boolean;
    FOnChanging: TTabChangingEvent;
    FOnCloseTabClicked: TNotifyEvent;
    FOnDrawTab: TDrawTabEvent;
    FOnGetImageIndex: TTabGetImageEvent;
    FOnPageChanged: TNotifyEvent;
    FOptions: TCTabControlOptions;
    FOwnerDraw: Boolean;
    FPageIndex: Integer;
    FPageIndexOnLastChange: integer;// needed for unique OnChange events
    FPageIndexOnLastShow: integer;
    FPageList: TList;  // TListWithEvent of TCustomPage
    FRaggedRight: Boolean;
    FScrollOpposite: Boolean;
    FShowTabs: Boolean;
    FStyle: TTabStyle;
    FTabHeight: Smallint;
    FTabPosition: TTabPosition;
    FTabWidth: Smallint;
    procedure DoSendPageIndex;
    procedure DoSendShowTabs;
    procedure DoSendTabPosition;
    procedure DoImageListChange(Sender: TObject);
    function GetActivePage: String;
    function GetActivePageComponent: TCustomPage;
    function GetDisplayRect: TRect;
    function GetMultiLine: Boolean;
    function FindVisiblePage(Index: Integer): Integer;
    function IsStoredActivePage: boolean;
    procedure AddRemovePageHandle(APage: TCustomPage);
    procedure MoveTab(Sender: TObject; NewIndex: Integer);
    procedure SetMultiLine(const AValue: Boolean);
    procedure SetStyle(AValue: TTabStyle); virtual;
    procedure WSMovePage(APage: TCustomPage; NewIndex: Integer);
    procedure PageRemoved(Index: Integer);
    procedure SetActivePage(const Value: String);
    procedure SetActivePageComponent(const AValue: TCustomPage);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetOptions(const AValue: TCTabControlOptions);
    procedure SetPageIndex(AValue: Integer);
    procedure SetPages(AValue: TStrings);
    procedure SetShowTabs(AValue: Boolean);
    procedure SetTabPosition(tabPos: TTabPosition); virtual;
    procedure ShowCurrentPage;
    procedure UpdateAllDesignerFlags;
    procedure UpdateDesignerFlags(APageIndex: integer);
  protected
    PageClass: TCustomPageClass;
    procedure CNNotify(var Message: TLMNotify); message CN_NOTIFY;
    class procedure WSRegisterClass; override;
    procedure CreateWnd; override;
    procedure DoCreateWnd; virtual;
    procedure DoChange; virtual;
    procedure Change; virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Loaded; override;
    procedure ReadState(Reader: TReader); override;
    function  DialogChar(var Message: TLMKey): boolean; override;
    procedure ShowControl(APage: TControl); override;
    procedure UpdateTabProperties; virtual;
    class function GetControlClassDefaultSize: TSize; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    property ActivePageComponent: TCustomPage read GetActivePageComponent
                                              write SetActivePageComponent;
    property ActivePage: String read GetActivePage write SetActivePage
                                                      stored IsStoredActivePage;
  protected //elevated visibility for un/paged
    FUnPaged: boolean; //false iff unpaged (TabControl)
    function GetPage(AIndex: Integer): TCustomPage; virtual;
    function GetPageCount : integer; virtual;
    procedure InsertPage(APage: TCustomPage; Index: Integer); virtual;
    procedure RemovePage(Index: Integer); virtual;
  //Delphi compatible properties
    function CanChange: Boolean; virtual;
    property DisplayRect: TRect read GetDisplayRect;
    property HotTrack: Boolean read FHotTrack write FHotTrack default False;
    property MultiSelect: Boolean read FMultiSelect write FMultiSelect default False;
    property OwnerDraw: Boolean read FOwnerDraw write FOwnerDraw default False;
    property RaggedRight: Boolean read FRaggedRight write FRaggedRight default False;
    property ScrollOpposite: Boolean read FScrollOpposite write FScrollOpposite default False;
    property Style: TTabStyle read FStyle write SetStyle default tsTabs;
    property Tabs: TStrings read FAccess write SetPages;
    property TabHeight: Smallint read FTabHeight write FTabHeight default 0;
    property TabIndex: Integer read FPageIndex write SetPageIndex default -1;
    property TabWidth: Smallint read FTabWidth write FTabWidth default 0;
    property OnChange: TNotifyEvent read FOnPageChanged write FOnPageChanged;
    property OnDrawTab: TDrawTabEvent read FOnDrawTab write FOnDrawTab;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function TabIndexAtClientPos(ClientPos: TPoint): integer;
    function TabRect(AIndex: Integer): TRect;
    function GetImageIndex(ThePageIndex: Integer): Integer; virtual;
    function IndexOf(APage: TPersistent): integer; virtual;
    function CustomPage(Index: integer): TCustomPage;
    function CanChangePageIndex: boolean; virtual;
    function GetMinimumTabWidth: integer; virtual;
    function GetMinimumTabHeight: integer; virtual;
    function GetCapabilities: TNoteBookCapabilities; virtual;
    function TabToPageIndex(AIndex: integer): integer;
    function PageToTabIndex(AIndex: integer): integer;
    function IndexOfTabAt(X, Y: Integer): Integer;
  public
    procedure DoCloseTabClicked(APage: TCustomPage); virtual;
    property Images: TCustomImageList read FImages write SetImages;
    property MultiLine: Boolean read GetMultiLine write SetMultiLine default False;
    property OnChanging: TTabChangingEvent read FOnChanging write FOnChanging;
    property OnCloseTabClicked: TNotifyEvent read FOnCloseTabClicked
                                             write FOnCloseTabClicked;
    property OnGetImageIndex: TTabGetImageEvent read FOnGetImageIndex
                                                write FOnGetImageIndex;
    property Options: TCTabControlOptions read FOptions write SetOptions default [];
    property Page[Index: Integer]: TCustomPage read GetPage;
    property PageCount: integer read GetPageCount;
    property PageIndex: Integer read FPageIndex write SetPageIndex default -1;
    //property PageList: TList read FPageList; - iff paged
    property Pages: TStrings read FAccess write SetPages;
    property ShowTabs: Boolean read FShowTabs write SetShowTabs default True;
    property TabPosition: TTabPosition read FTabPosition write SetTabPosition default tpTop;
    property IsUnpaged: boolean read FUnPaged;
  published
    property TabStop default true;
  end;

  { TTabSheet }

  TPageControl = class;

  TTabSheet = class(TCustomPage)
  private
    function GetPageControl: TPageControl;
    function GetTabIndex: Integer;
    procedure SetPageControl(APageControl: TPageControl);
  protected
    class procedure WSRegisterClass; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property PageControl: TPageControl read GetPageControl write SetPageControl;
    property TabIndex: Integer read GetTabIndex;
  published
    property BorderWidth;
    property BiDiMode;
    property Caption;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Enabled;
    property Font;
    property Height stored False;
    property ImageIndex default 0;
    property Left stored False;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnHide;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnShow;
    property OnStartDrag;
    property PageIndex stored False;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabVisible default True;
    property Top stored False;
    property Width stored False;
  end;

  { TPageControl }

  TPageControl = class(TCustomTabControl)
  private
    FPageToUndock: TTabSheet;
    function GetActivePageIndex: Integer;
    function GetActiveTabSheet: TTabSheet;
    function GetTabSheet(Index: Integer): TTabSheet;
    procedure SetActivePageIndex(const AValue: Integer);
    procedure SetActiveTabSheet(const AValue: TTabSheet);
    function FindPageWithDockClient(Client: TControl): TTabSheet;
  protected
    class procedure WSRegisterClass; override;
    procedure DoAddDockClient(Client: TControl; const ARect: TRect); override;
    procedure DockOver(Source: TDragDockObject; X, Y: Integer;
                       State: TDragState; var Accept: Boolean); override;
    procedure DoRemoveDockClient(Client: TControl); override;
    function DoUndockClientMsg(NewTarget, Client: TControl):boolean; override;
    function ChildClassAllowed(ChildClass: TClass): boolean; override;
  public
    constructor Create(TheOwner: TComponent); override;
    function FindNextPage(CurPage: TTabSheet;
                          GoForward, CheckTabVisible: Boolean): TTabSheet;
    procedure SelectNextPage(GoForward: Boolean);
    procedure SelectNextPage(GoForward: Boolean; CheckTabVisible: Boolean);
    function AddTabSheet: TTabSheet;
    property ActivePageIndex: Integer read GetActivePageIndex
                                      write SetActivePageIndex;
    property Pages[Index: Integer]: TTabSheet read GetTabSheet;
  published
    property ActivePage: TTabSheet read GetActiveTabSheet write SetActiveTabSheet;
    property OnGetDockCaption;
    
    property Align;
    property Anchors;
    property BorderSpacing;
    property BiDiMode;
    property Constraints;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    //property HotTrack;
    property Images;
    property MultiLine;
    //property OwnerDraw;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    //property RaggedRight;
    //property ScrollOpposite;
    property ShowHint;
    property ShowTabs;
    //property Style;
    //property TabHeight;
    property TabIndex;
    property TabOrder;
    property TabPosition;
    property TabStop;
    //property TabWidth;
    property Visible;
    property OnChange;
    property OnChanging;
    property OnCloseTabClicked;
    property OnContextPopup;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    //property OnDrawTab;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetImageIndex;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property Options;
  end;

  TTabControl = class;

  { TTabControlStrings }

  TTabControlStrings = class(TStrings)
  private
    FHotTrack: Boolean;
    FImages: TCustomImageList;
    FMultiLine: Boolean;
    FMultiSelect: Boolean;
    FOwnerDraw: Boolean;
    FRaggedRight: Boolean;
    FScrollOpposite: Boolean;
    FTabControl: TTabControl;
    FTabHeight: Smallint;
    FTabWidth: Smallint;
    FUpdateCount: integer;
  protected
    function GetTabIndex: integer; virtual; abstract;
    procedure SetHotTrack(const AValue: Boolean); virtual;
    procedure SetImages(const AValue: TCustomImageList); virtual;
    procedure SetMultiLine(const AValue: Boolean); virtual;
    procedure SetMultiSelect(const AValue: Boolean); virtual;
    procedure SetOwnerDraw(const AValue: Boolean); virtual;
    procedure SetRaggedRight(const AValue: Boolean); virtual;
    procedure SetScrollOpposite(const AValue: Boolean); virtual;
    procedure SetTabHeight(const AValue: Smallint); virtual;
    procedure SetTabIndex(const AValue: integer); virtual; abstract;
    procedure SetTabWidth(const AValue: Smallint); virtual;
  public
    constructor Create(TheTabControl: TTabControl); virtual;
    function GetHitTestInfoAt(X, Y: Integer): THitTests; virtual;
    function GetSize: integer; virtual; abstract;
    function IndexOfTabAt(X, Y: Integer): Integer; virtual;
    function RowCount: Integer; virtual;
    function TabRect(Index: Integer): TRect; virtual;
    procedure ImageListChange(Sender: TObject); virtual;
    procedure ScrollTabs(Delta: Integer); virtual;
    procedure TabControlBoundsChange; virtual;
    procedure UpdateTabImages; virtual;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    function IsUpdating: boolean; virtual;
  public
    property TabControl: TTabControl read FTabControl;
    property TabIndex: integer read GetTabIndex write SetTabIndex;
    property HotTrack: Boolean read FHotTrack write SetHotTrack;
    property Images: TCustomImageList read FImages write SetImages;
    property MultiLine: Boolean read FMultiLine write SetMultiLine;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect;
    property OwnerDraw: Boolean read FOwnerDraw write SetOwnerDraw;
    property RaggedRight: Boolean read FRaggedRight write SetRaggedRight;
    property ScrollOpposite: Boolean read FScrollOpposite
                                     write SetScrollOpposite;
    property TabHeight: Smallint read FTabHeight write SetTabHeight;
    property TabWidth: Smallint read FTabWidth write SetTabWidth;
  end;

  { TNoteBookStringsTabControl }

  TNoteBookStringsTabControl = class(TCustomTabControl)
  protected
    FHandelCreated: TNotifyEvent;
    procedure CreateHandle; override;
  end;

  { TTabControlNoteBookStrings }

  TTabControlNoteBookStrings = class(TTabControlStrings)
  private
    FNoteBook: TCustomTabControl{%H-};
    FInHandleCreated: Boolean;
    function GetStyle: TTabStyle;
    procedure SetStyle(AValue: TTabStyle);
  protected
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
    function GetObject(Index: Integer): TObject; override;
    function GetTabIndex: integer; override;
    function GetTabPosition: TTabPosition;
    procedure NBChanging(Sender: TObject; var AllowChange: Boolean); virtual;
    procedure NBGetImageIndex(Sender: TObject; TheTabIndex: Integer;
                              var ImageIndex: Integer); virtual;
    procedure NBPageChanged(Sender: TObject); virtual;
    procedure NBHandleCreated(Sender: TObject);
    procedure Put(Index: Integer; const S: string); override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
    procedure SetImages(const AValue: TCustomImageList); override;
    procedure SetMultiLine(const AValue: Boolean); override;
    procedure SetTabIndex(const AValue: integer); override;
    procedure SetUpdateState(Updating: Boolean); override;
    procedure SetTabHeight(const AValue: Smallint); override;
    procedure SetTabPosition(AValue: TTabPosition);
    procedure SetTabWidth(const AValue: Smallint); override;
  public
    constructor Create(TheTabControl: TTabControl); override;
    destructor Destroy; override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: string); override;
    function GetSize: integer; override;
    procedure TabControlBoundsChange; override;
    function IndexOfTabAt(X, Y: Integer): Integer; override;
    property TabPosition: TTabPosition read GetTabPosition write SetTabPosition;
    property Style: TTabStyle read GetStyle write SetStyle;
  public
    property NoteBook: TCustomTabControl read FNoteBook;
  end;

(* This is the new TTabControl which replaces the one one.
  This new one is derived from TCustomTabControl.
*)

  TTabControl = class(TCustomTabControl)
  private
    FImageChangeLink: TChangeLink;
    FOnChange: TNotifyEvent;
    FOnChangeNeeded: Boolean;
    FTabControlCreating: Boolean;
    FTabs: TStrings;// this is a TTabControlNoteBookStrings
    FCanvas: TCanvas;
    FOnPaint: TNotifyEvent;
    procedure AdjustDisplayRect(var ARect: TRect);
    function GetDisplayRect: TRect;
    function GetHotTrack: Boolean;
    function GetMultiLine: Boolean;
    function GetMultiSelect: Boolean;
    function GetOwnerDraw: Boolean;
    function GetRaggedRight: Boolean;
    function GetScrollOpposite: Boolean;
    function GetTabHeight: Smallint;
    function GetTabIndex: Integer;
    function GetTabRectWithBorder: TRect;
    function GetTabWidth: Smallint;
    procedure SetHotTrack(const AValue: Boolean);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetMultiLine(const AValue: Boolean);
    procedure SetMultiSelect(const AValue: Boolean);
    procedure SetOwnerDraw(const AValue: Boolean);
    procedure SetRaggedRight(const AValue: Boolean);
    procedure SetScrollOpposite(const AValue: Boolean);
    procedure SetStyle(AValue: TTabStyle); override;
    procedure SetTabHeight(const AValue: Smallint);
    procedure SetTabPosition(AValue: TTabPosition); override;
    procedure SetTabs(const AValue: TStrings);
    procedure SetTabWidth(const AValue: Smallint);
  protected
    function CanChange: Boolean; override;
    function CanShowTab(ATabIndex: Integer): Boolean; virtual;
    procedure Change; override;
    procedure Loaded; override;
    procedure CreateWnd; override;
    procedure DestroyHandle; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetTabIndex(Value: Integer); virtual;
    procedure UpdateTabImages;
    procedure ImageListChange(Sender: TObject);
    procedure DoSetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
    class function GetControlClassDefaultSize: TSize; override;
    procedure PaintWindow(DC: HDC); override;
    procedure Paint; virtual;
    procedure AdjustDisplayRectWithBorder(var ARect: TRect); virtual;
    procedure AdjustClientRect(var ARect: TRect); override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function IndexOfTabAt(X, Y: Integer): Integer;
    function GetHitTestInfoAt(X, Y: Integer): THitTests;
    function GetImageIndex(ATabIndex: Integer): Integer; override;
    function IndexOfTabWithCaption(const TabCaption: string): Integer;
    function TabRect(Index: Integer): TRect;
    function RowCount: Integer;
    procedure ScrollTabs(Delta: Integer);
    procedure BeginUpdate;
    procedure EndUpdate;
    function IsUpdating: boolean;
  public
    property DisplayRect: TRect read GetDisplayRect;
  published
    property HotTrack: Boolean read GetHotTrack write SetHotTrack default False;
    property Images;
    property MultiLine: Boolean read GetMultiLine write SetMultiLine default False;
    property MultiSelect: Boolean read GetMultiSelect write SetMultiSelect default False;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChanging;
    property OnDrawTab;
    property OnGetImageIndex;
    property OwnerDraw: Boolean read GetOwnerDraw write SetOwnerDraw default False;
    property RaggedRight: Boolean read GetRaggedRight write SetRaggedRight default False;
    property ScrollOpposite: Boolean read GetScrollOpposite
                                     write SetScrollOpposite default False;
    property Style default tsTabs;
    property TabHeight: Smallint read GetTabHeight write SetTabHeight default 0;
    property TabPosition default tpTop;
    property TabWidth: Smallint read GetTabWidth write SetTabWidth default 0;
    property TabIndex: Integer read GetTabIndex write SetTabIndex default -1;
    property Tabs: TStrings read FTabs write SetTabs;
    property TabStop default True;
    //
    property Align;
    property Anchors;
    property BiDiMode;
    property BorderSpacing;
    property Constraints;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property OnChangeBounds;
    property OnContextPopup;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property Visible;
  end;

  { Custom draw }

  TCustomDrawTarget = (
    dtControl,   // the whole control
    dtItem,      // one item (= line in report mode)
    dtSubItem    // one subitem, except for subitem 0, this one is drawn by dtItem
  );
  TCustomDrawStage = (
    cdPrePaint,
    cdPostPaint,
    cdPreErase,
    cdPostErase
  );
  TCustomDrawStateFlag = (
    cdsSelected,
    cdsGrayed,
    cdsDisabled,
    cdsChecked,
    cdsFocused,
    cdsDefault,
    cdsHot,
    cdsMarked,
    cdsIndeterminate
  );
  TCustomDrawState = set of TCustomDrawStateFlag;
  
  TCustomDrawResultFlag = (
    cdrSkipDefault,
    cdrNotifyPostpaint,
    cdrNotifyItemdraw,
    cdrNotifySubitemdraw,
    cdrNotifyPosterase,
    cdrNotifyItemerase
  );
  TCustomDrawResult = set of TCustomDrawResultFlag;


  { TListView }

  TListItems = class;  //forward declaration!
  TCustomListView = class;  //forward declaration!
  TSortType = (stNone, stData, stText, stBoth);
  
  TListItemState = (lisCut, lisDropTarget, lisFocused, lisSelected);
  TListItemStates = set of TListItemState;
  
  TListItemFlag = (lifDestroying, lifCreated);
  TListItemFlags = set of TListItemFlag;

  TDisplayCode = (drBounds, drIcon, drLabel, drSelectBounds);
  
{ TIconOptions }

  TIconArrangement = (iaTop, iaLeft);

  TIconOptions = class(TPersistent)
  private
    FListView: TCustomListView;
    FArrangement: TIconArrangement;
    function GetAutoArrange: Boolean;
    function GetWrapText: Boolean;
    procedure SetArrangement(Value: TIconArrangement);
    procedure SetAutoArrange(Value: Boolean);
    procedure SetWrapText(Value: Boolean);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TCustomListView);
  published
    property Arrangement: TIconArrangement read FArrangement write SetArrangement default iaTop;
    property AutoArrange: Boolean read GetAutoArrange write SetAutoArrange default False;
    property WrapText: Boolean read GetWrapText write SetWrapText default True;
  end;

  { TListItem }

  TListItem = class(TPersistent)
  private
    FOwner: TListItems;
    FFlags: TListItemFlags;
    FSubItems: TStrings;
    FCaption: String;
    FData: Pointer;
    FImageIndex: TImageIndex;
    FStateIndex: TImageIndex;
    FStates: TListItemStates;
    FChecked: Boolean;
    function GetCaption: String; virtual;
    function GetChecked: Boolean;
    function GetLeft: Integer;
    function GetListView: TCustomListView;
    function GetPosition: TPoint;
    function GetState(const ALisOrd: Integer): Boolean;
    function GetImageIndex: TImageIndex; virtual;
    function GetIndex: Integer; virtual;
    function GetStateIndex: TImageIndex; virtual;
    function GetSubItemImages(const AIndex: Integer): Integer;
    function GetSubItems: TStrings; virtual;
    function GetTop: Integer;
    function WSUpdateAllowed: Boolean;
    procedure WSUpdateText;
    procedure WSUpdateImages;
    procedure WSUpdateChecked;
    procedure WSSetState;
    procedure WSUpdateState;

    procedure SetChecked(AValue: Boolean);
    procedure SetState(const ALisOrd: Integer; const AIsSet: Boolean);
    procedure SetData(const AValue: Pointer);
    procedure SetImageIndex(const AValue: TImageIndex); virtual;
    procedure SetLeft(Value: Integer);
    procedure SetCaption(const AValue : String); virtual;
    procedure SetPosition(const AValue: TPoint);
    procedure SetStateIndex(const AValue: TImageIndex); virtual;
    procedure SetSubItemImages(const AIndex, AValue: Integer);
    procedure SetSubItems(const AValue: TStrings);
    procedure SetTop(Value: Integer);
  protected
    function IsEqual(const AItem: TListItem): Boolean;
    function IsOwnerData: Boolean; virtual;
    function GetCheckedInternal: Boolean;
    function GetOwner: TPersistent; override;
  public
    procedure Assign(ASource: TPersistent); override;

    constructor Create(AOwner: TListItems); virtual;
    destructor Destroy; override;
    procedure Delete;
    procedure MakeVisible(PartialOK: Boolean);
    function DisplayRect(Code: TDisplayCode): TRect;
    function DisplayRectSubItem(subItem: integer;Code: TDisplayCode): TRect;
    function EditCaption: Boolean;

    property Caption : String read GetCaption write SetCaption;
    property Checked : Boolean read GetChecked write SetChecked;
    property Cut: Boolean index Ord(lisCut) read GetState write SetState;
    property Data: Pointer read FData write SetData;
    property DropTarget: Boolean index Ord(lisDropTarget) read GetState write SetState;
    property Focused: Boolean index Ord(lisFocused) read GetState write SetState;
    property Index: Integer read GetIndex;
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex default -1;
    property Left: Integer read GetLeft write SetLeft;
    property ListView: TCustomListView read GetListView;
    property Owner: TListItems read FOwner;
    property Position: TPoint read GetPosition write SetPosition;
    property Selected: Boolean index Ord(lisSelected) read GetState write SetState;
    property StateIndex: TImageIndex read GetStateIndex write SetStateIndex;
    property SubItems: TStrings read GetSubItems write SetSubItems;
    property SubItemImages[const AIndex: Integer]: Integer read GetSubItemImages write SetSubItemImages;
    property Top: Integer read GetTop write SetTop;
  end;
  TListItemClass = class of TListItem;

  { TOwnerDataListItem }

  TOwnerDataListItem = class(TListItem)
  private
    FDataIndex: Integer;    
    FCached: Boolean;
    function GetCaption: String; override;
    function GetIndex: Integer; override;
    function GetImageIndex: TImageIndex; override;

    procedure SetCaption(const AValue : String); override;
    procedure SetImageIndex(const AValue: TImageIndex); override;
    function GetSubItems: TStrings; override;
    procedure DoCacheItem;
  protected
    function IsOwnerData: Boolean; override;
  public
    procedure SetDataIndex(ADataIndex: Integer);
    procedure SetOwner(AOwner: TListItems);
  end;

  { TListItemsEnumerator }

  TListItemsEnumerator = class
  private
    FItems: TListItems;
    FPosition: Integer;
    function GetCurrent: TListItem;
  public
    constructor Create(AItems: TListItems);
    function MoveNext: Boolean;
    property Current: TListItem read GetCurrent;
  end;

  TListItemsFlag = (lisfWSItemsCreated);
  TListItemsFlags = set of TListItemsFlag;

  
  { TListItems }
  {
    Listitems have a build in cache of the last accessed item.
    This will speed up interface updates since Item.Index is 
    often used for the same item updating more properties.
    If FCacheIndex = -1 then the cache is not valid.
  }

  TListItems = class(TPersistent)
  private
    FOwner: TCustomListView;
    FItems: TFPList;
    FFlags: TListItemsFlags;
    FCacheIndex: Integer;  // Caches the last used item 
    FCacheItem: TListItem; //
    procedure WSCreateCacheItem;
    function WSUpdateAllowed: Boolean;
    procedure WSUpdateItem(const AIndex:Integer; const AValue: TListItem);
    procedure WSSetItemsCount(const ACount: Integer);
    procedure ItemDestroying(const AItem: TListItem); //called by TListItem when freed
    procedure ReadData(Stream: TStream); // read data in a Delphi compatible way
    procedure ReadLazData(Stream: TStream); // read data in a 64 bits safe way
    procedure WriteLazData(Stream: TStream); // write date in a 64 bits safe way
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function GetCount: Integer; virtual;
    function GetItem(const AIndex: Integer): TListItem; virtual;
    function GetOwner: TPersistent; override;
    procedure WSCreateItems;
    procedure DoFinalizeWnd;
    procedure SetCount(const ACount: Integer); virtual;
    procedure SetItem(const AIndex: Integer; const AValue: TListItem);
  public
    function Add: TListItem;
    procedure AddItem(AItem: TListItem);
    procedure BeginUpdate;
    procedure Clear; virtual;
    constructor Create(AOwner : TCustomListView);
    destructor Destroy; override;
    procedure Delete(const AIndex : Integer);
    procedure EndUpdate;
    procedure Exchange(const AIndex1, AIndex2: Integer);
    procedure Move(const AFromIndex, AToIndex: Integer);
    function FindCaption(StartIndex: Integer; Value: string;
                     Partial, Inclusive, Wrap: Boolean;
                     PartStart: Boolean = True): TListItem;
    function FindData(const AData: Pointer): TListItem; overload;
    function FindData(StartIndex: Integer; Value: Pointer;  Inclusive, Wrap: Boolean): TListItem; overload;
    function GetEnumerator: TListItemsEnumerator;
    function IndexOf(const AItem: TListItem): Integer;
    function Insert(const AIndex: Integer) : TListItem;
    procedure InsertItem(AItem: TListItem; const AIndex: Integer);
    property Flags: TListItemsFlags read FFlags;
    property Count: Integer read GetCount write SetCount;
    property Item[const AIndex: Integer]: TListItem read GetItem write SetItem; default;
    property Owner: TCustomListView read FOwner;
  end;

  { TOwnerDataListItems }

  TOwnerDataListItems = class(TListItems)
  private
    fItemsCount : Integer;
  protected
    function GetCount: Integer; override;
    procedure SetCount(const ACount: Integer); override;
    function GetItem(const AIndex: Integer): TListItem; override;
  public
    procedure Clear; override;
  end;


  { TListColumn }

  TWidth = 0..MaxInt;

  TListColumn = class(TCollectionItem)
  private
    FAlignment: TAlignment;
    FAutoSize: Boolean;
    FCaption: TTranslateString;
    FMinWidth: TWidth;
    FMaxWidth: TWidth;
    FVisible: Boolean;
    FWidth: TWidth;
    FImageIndex: TImageIndex;
    FTag: Integer;
    function GetWidth: TWidth;
    procedure WSCreateColumn;
    procedure WSDestroyColumn;
    function WSUpdateAllowed: Boolean;
    function WSReadAllowed: Boolean;
    procedure SetVisible(const AValue: Boolean);
    procedure SetAutoSize(const AValue: Boolean);
    procedure SetMinWidth(const AValue: TWidth);
    procedure SetMaxWidth(const AValue: TWidth);
    procedure SetWidth(const AValue: TWidth);
    procedure SetCaption(const AValue: TTranslateString);
    procedure SetAlignment(const AValue: TAlignment);
    procedure SetImageIndex(const AValue: TImageIndex);
  protected
    procedure SetIndex(AValue: Integer); override;
    function GetDisplayName: string; override;
    function GetStoredWidth: Integer;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    property WidthType: TWidth read FWidth;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property AutoSize: Boolean read FAutoSize write SetAutoSize default False;
    property Caption: TTranslateString read FCaption write SetCaption;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property MaxWidth: TWidth read FMaxWidth write SetMaxWidth default 0;
    property MinWidth: TWidth read FMinWidth write SetMinWidth default 0;
    property Tag: Integer read FTag write FTag default 0;
    property Visible: Boolean read FVisible write SetVisible default true;
    property Width: TWidth read GetWidth write SetWidth default 50;
  end;


  { TListColumns }

  TListColumns = class(TCollection)
  private
    FOwner: TCustomListView;
    FItemNeedsUpdate: TCollectionItem;
    FNeedsUpdate: boolean;
    function GetItem(const AIndex: Integer): TListColumn;
    procedure WSCreateColumns;
    procedure SetItem(const AIndex: Integer; const AValue: TListColumn);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TCustomListView);
    destructor Destroy; override;
    procedure Update(Item: TCollectionItem); override;
    function Add: TListColumn;
    property Owner: TCustomListView read FOwner;
    property Items[const AIndex: Integer]: TListColumn
                                            read GetItem write SetItem; default;
    procedure Assign(Source: TPersistent); override;
  end;


  { TCustomListView }

  TItemChange = (ctText, ctImage, ctState);
  TViewStyle = (vsIcon, vsSmallIcon, vsList, vsReport);

  TItemFind = (ifData, ifPartialString, ifExactString, ifNearest);
  TSearchDirection = (sdLeft, sdRight, sdAbove, sdBelow, sdAll);

  TLVChangeEvent = procedure(Sender: TObject; Item: TListItem;
                             Change: TItemChange) of object;

  TLVDataFindEvent = procedure(Sender: TObject; AFind: TItemFind;
    const AFindString: string; const AFindPosition: TPoint; AFindData: Pointer;
    AStartIndex: Integer; ADirection: TSearchDirection; AWrap: Boolean;
    var AIndex: Integer) of object;

  TLVDataHintEvent = procedure(Sender: TObject; StartIndex, EndIndex: Integer) of object;
  TLVDataStateChangeEvent = procedure(Sender: TObject; StartIndex,
    EndIndex: Integer; OldState, NewState: TListItemStates) of object;

  TLVColumnClickEvent = procedure(Sender: TObject;
                                  Column: TListColumn) of object;
  TLVColumnRClickEvent = procedure(Sender: TObject; Column: TListColumn;
                                   Point: TPoint) of object;
  TLVCompareEvent = procedure(Sender: TObject; Item1, Item2: TListItem;
                               Data: Integer; var Compare: Integer) of object;
  TLVDeletedEvent = procedure(Sender: TObject; Item: TListItem) of object;

  TLVEditingEvent = procedure(Sender: TObject; Item: TListItem;
    var AllowEdit: Boolean) of object;
  TLVEditedEvent = procedure(Sender: TObject; Item: TListItem;
    var AValue: string) of object;

  TLVInsertEvent = TLVDeletedEvent;
  TLVDataEvent = TLVDeletedEvent;
  TLVCheckedItemEvent = procedure (Sender: TObject; Item: TListItem) of object;
  TLVSelectItemEvent = procedure(Sender: TObject; Item: TListItem;
                                 Selected: Boolean) of object;
  TLVCustomDrawEvent = procedure(Sender: TCustomListView; const ARect: TRect;
                                  var DefaultDraw: Boolean) of object;
  TLVCustomDrawItemEvent = procedure(Sender: TCustomListView; Item: TListItem; 
                                State: TCustomDrawState; var DefaultDraw: Boolean) of object;
  TLVCustomDrawSubItemEvent=procedure(Sender: TCustomListView; Item: TListItem; 
                                 SubItem: Integer; State: TCustomDrawState;
                                 var DefaultDraw: Boolean) of object;
  TLVAdvancedCustomDrawEvent = procedure(Sender: TCustomListView; const ARect: TRect;
                                Stage: TCustomDrawStage; var DefaultDraw: Boolean) of object;
  TLVAdvancedCustomDrawItemEvent = procedure(Sender: TCustomListView; Item: TListItem; 
                                State: TCustomDrawState; Stage: TCustomDrawStage; 
                                var DefaultDraw: Boolean) of object;
  TLVAdvancedCustomDrawSubItemEvent=procedure(Sender: TCustomListView; Item: TListItem; 
                                 SubItem: Integer; State: TCustomDrawState;
                                 Stage: TCustomDrawStage; var DefaultDraw: Boolean) of object;
  TLVCreateItemClassEvent = procedure(Sender: TCustomListView; var ItemClass: TListItemClass) of object;

  TListViewProperty = (
    lvpAutoArrange,
    lvpCheckboxes,
    lvpColumnClick,
    lvpFlatScrollBars,
    lvpFullDrag,
    lvpGridLines,
    lvpHideSelection,
    lvpHotTrack,
    lvpMultiSelect,
    lvpOwnerDraw,
    lvpReadOnly,
    lvpRowSelect,
    lvpShowColumnHeaders,
    lvpShowWorkAreas,
    lvpWrapText,
    lvpToolTips
  );
  TListViewProperties = set of TListViewProperty;

  TListViewImageList = (lvilSmall, lvilLarge, lvilState);
  
  TListHotTrackStyle = (htHandPoint, htUnderlineCold, htUnderlineHot);
  TListHotTrackStyles = set of TListHotTrackStyle;
  
  TListViewFlag = (
    lffSelectedValid,
    lffItemsMoving,
    lffItemsSorting,
    lffPreparingSorting // do not trigger when we are setting more rules
    );
  TListViewFlags = set of TListViewFlag;

  TSortDirection = (sdAscending, sdDescending);

  { TCustomListViewEditor }
  {used to provide multiplatform TCustomListView editing ability}
  TCustomListViewEditor = class(TCustomEdit)
  private
    FItem: TListItem;
    procedure ListViewEditorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  protected
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Item: TListItem read FItem write FItem;
  end;

  { TCustomListView }

  TCustomListView = class(TWinControl)
  private
    FEditor: TCustomListViewEditor;
    FAllocBy: Integer;
    FAutoSort: Boolean;
    FAutoWidthLastColumn: Boolean;
    FCanvas: TCanvas;
    FDefaultItemHeight: integer;
    FHotTrackStyles: TListHotTrackStyles;
    FIconOptions: TIconOptions;
    FOnEdited: TLVEditedEvent;
    FOnEditing: TLVEditingEvent;

    FOwnerData: Boolean;
    FOwnerDataItem: TOwnerDataListItem;
    FListItems: TListItems;
    FColumns: TListColumns;
    FImages: array[TListViewImageList] of TCustomImageList;
    FImageChangeLinks: array[TListViewImageList] of TChangeLink;
    FFlags: TListViewFlags;
    FSortDirection: TSortDirection;

    FViewStyle: TViewStyle;
    FSortType: TSortType;
    FSortColumn: Integer;
    FScrollBars: TScrollStyle;
    FViewOriginCache: TPoint; // scrolled originwhile handle is not created
    FSelected: TListItem;     // temp copy of the selected item
    FFocused: TListItem;      // temp copy of the focused item
    FSelectedIdx: Integer;    // Index of Selected item, used if OwnerData = True;
    FHoverTime: Integer;      // temp copy of the hover time (the time a mouse must be over a item to auto select)
    // MWE: not used: see updateScrollbars
    // FLastHorzScrollInfo: TScrollInfo;
    // FLastVertScrollInfo: TScrollInfo;
    FUpdateCount: integer;
    FOnChange: TLVChangeEvent;
    FOnColumnClick: TLVColumnClickEvent;
    FOnCompare: TLVCompareEvent;
    FOnData: TLVDataEvent;
    FOnDataFind: TLVDataFindEvent;
    FOnDataHint: TLVDataHintEvent;
    FOnDataStateChange: TLVDataStateChangeEvent;
    FOnDeletion: TLVDeletedEvent;
    FOnInsert: TLVInsertEvent;
    FOnItemChecked: TLVCheckedItemEvent;
    FOnSelectItem: TLVSelectItemEvent;
    FOnCustomDraw: TLVCustomDrawEvent;
    FOnCustomDrawItem: TLVCustomDrawItemEvent;
    FOnCustomDrawSubItem: TLVCustomDrawSubItemEvent;
    FOnAdvancedCustomDraw: TLVAdvancedCustomDrawEvent;
    FOnAdvancedCustomDrawItem: TLVAdvancedCustomDrawItemEvent;
    FOnAdvancedCustomDrawSubItem: TLVAdvancedCustomDrawSubItemEvent;
    FProperties: TListViewProperties;
    function GetBoundingRect: TRect;
    function GetColumnCount: Integer;
    function GetColumnFromIndex(AIndex: Integer): TListColumn;
    function GetDropTarget: TListItem;
    function GetFocused: TListItem;
    function GetImageList(const ALvilOrd: Integer): TCustomImageList;
    function GetHoverTime: Integer;
    function GetItemIndex: Integer;
    function GetProperty(const ALvpOrd: Integer): Boolean;
    function GetSelCount: Integer;
    function GetSelection: TListItem;
    function GetTopItem: TListItem;
    function GetViewOrigin: TPoint;
    function GetVisibleRowCount: Integer;

    procedure ResizeLastColumn;
    procedure SetAllocBy(const AValue: Integer);
    procedure SetAutoWidthLastColumn(AValue: Boolean);
    procedure SetColumns(const AValue: TListColumns);
    procedure SetDefaultItemHeight(AValue: Integer);
    procedure SetDropTarget(const AValue: TListItem);
    procedure SetFocused(const AValue: TListItem);
    procedure SetHotTrackStyles(const AValue: TListHotTrackStyles);
    procedure SetHoverTime(const AValue: Integer);
    procedure SetIconOptions(const AValue: TIconOptions);
    procedure SetImageList(const ALvilOrd: Integer; const AValue: TCustomImageList);
    procedure SetItemIndex(const AValue: Integer);
    procedure SetItems(const AValue : TListItems);
    procedure SetItemVisible(const AValue: TListItem; const APartialOK: Boolean);
    procedure SetOwnerData(const AValue: Boolean);
    procedure SetProperty(const ALvpOrd: Integer; const AIsSet: Boolean);
    procedure SetScrollBars(const AValue: TScrollStyle);
    procedure SetSelection(const AValue: TListItem);
    procedure SetSortColumn(const AValue: Integer);
    procedure SetSortDirection(const AValue: TSortDirection);
    procedure SetSortType(const AValue: TSortType);
    procedure SetViewOrigin(AValue: TPoint);
    procedure SetViewStyle(const Avalue: TViewStyle);
    procedure Sort;
    procedure UpdateScrollbars;
    procedure CNNotify(var AMessage: TLMNotify); message CN_NOTIFY;
    procedure InvalidateSelected;
  private
    FOnCreateItemClass: TLVCreateItemClassEvent;
    procedure HideEditor;
    procedure ShowEditor;
    procedure WMHScroll(var message : TLMHScroll); message LM_HSCROLL;
    procedure WMVScroll(var message : TLMVScroll); message LM_VSCROLL;
  protected
    //called by TListItems
    procedure ItemDeleted(const AItem: TListItem);
    procedure ItemInserted(const AItem: TListItem);

  protected
    class procedure WSRegisterClass; override;
    class function GetControlClassDefaultSize: TSize; override;
    procedure InitializeWnd; override;
    procedure FinalizeWnd; override;
    procedure DestroyWnd; override;
    procedure BeginAutoDrag; override;

    function CreateListItem: TListItem; virtual;
    function CreateListItems: TListItems; virtual;
    function CanEdit(Item: TListItem): Boolean; virtual;
    procedure Change(AItem: TListItem; AChange: Integer); virtual;
    procedure ColClick(AColumn: TListColumn); virtual;

    procedure Delete(Item : TListItem);
    procedure DoDeletion(AItem: TListItem); virtual;
    procedure DoInsert(AItem: TListItem); virtual;
    procedure DoItemChecked(AItem: TListItem);
    procedure DoSelectItem(AItem: TListItem; ASelected: Boolean); virtual;
    procedure DoSetBounds(ALeft, ATop, AWidth, AHeight: integer); override;

    procedure DoEndEdit(AItem: TListItem; const AValue: String); virtual;

    procedure InsertItem(Item : TListItem);
    procedure ImageChanged(Sender : TObject);
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    function IsCustomDrawn(ATarget: TCustomDrawTarget; AStage: TCustomDrawStage): Boolean; virtual;
    function CustomDraw(const ARect: TRect; AStage: TCustomDrawStage): Boolean; virtual;                                                   // Return True if default drawing should be done
    function CustomDrawItem(AItem: TListItem; AState: TCustomDrawState; AStage: TCustomDrawStage): Boolean; virtual;                       //
    function CustomDrawSubItem(AItem: TListItem; ASubItem: Integer; AState: TCustomDrawState; AStage: TCustomDrawStage): Boolean; virtual; //
    function IntfCustomDraw(ATarget: TCustomDrawTarget; AStage: TCustomDrawStage; AItem, ASubItem: Integer; AState: TCustomDrawState; const ARect: PRect): TCustomDrawResult;
    function GetUpdateCount: Integer;

    procedure DoGetOwnerData(Item: TListItem); virtual;
    function DoOwnerDataHint(AStartIndex, AEndIndex: Integer): Boolean; virtual;
    function DoOwnerDataStateChange(AStartIndex, AEndIndex: Integer; AOldState,
      ANewState: TListItemStates): Boolean; virtual;
  protected
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  protected
    property AllocBy: Integer read FAllocBy write SetAllocBy default 0;
    property AutoSort: Boolean read FAutoSort write FAutoSort default True; // when we click header column sort automatically
    property AutoWidthLastColumn: Boolean read FAutoWidthLastColumn write SetAutoWidthLastColumn default False; // resize last column to fit width of TListView
    property ColumnClick: Boolean index Ord(lvpColumnClick) read GetProperty write SetProperty default True;
    property Columns: TListColumns read FColumns write SetColumns;
    property DefaultItemHeight: integer read FDefaultItemHeight write SetDefaultItemHeight;
    property HideSelection: Boolean index Ord(lvpHideSelection) read GetProperty write SetProperty default True;
    property HoverTime: Integer read GetHoverTime write SetHoverTime default -1;
    property LargeImages: TCustomImageList index Ord(lvilLarge) read GetImageList write SetImageList;
    property OwnerDraw: Boolean index Ord(lvpOwnerDraw) read GetProperty write SetProperty default False;
    property ScrollBars: TScrollStyle read FScrollBars write SetScrollBars default ssBoth;
    property ShowColumnHeaders: Boolean index Ord(lvpShowColumnHeaders) read GetProperty write SetProperty default True;
    property ShowWorkAreas: Boolean index Ord(lvpShowWorkAreas) read GetProperty write SetProperty default False;
    property SmallImages: TCustomImageList index Ord(lvilSmall) read GetImageList write SetImageList;
    property SortType: TSortType read FSortType write SetSortType default stNone;
    property SortColumn: Integer read FSortColumn write SetSortColumn default 0;
    property SortDirection: TSortDirection read FSortDirection write SetSortDirection default sdAscending;
    property StateImages: TCustomImageList index Ord(lvilState) read GetImageList write SetImageList;
    property ToolTips: Boolean index Ord(lvpToolTips) read GetProperty write SetProperty default True;
    property ViewStyle: TViewStyle read FViewStyle write SetViewStyle default vsList;
    property OnChange: TLVChangeEvent read FOnChange write FOnChange;
    property OnColumnClick: TLVColumnClickEvent read FOnColumnClick write FOnColumnClick;
    property OnCompare: TLVCompareEvent read FOnCompare write FOnCompare;
    property OnCreateItemClass: TLVCreateItemClassEvent read FOnCreateItemClass write FOnCreateItemClass;
    property OnData: TLVDataEvent read FOnData write FOnData;
    property OnDataFind: TLVDataFindEvent read FOnDataFind write FOnDataFind;
    property OnDataHint: TLVDataHintEvent read FOnDataHint write FOnDataHint;
    property OnDataStateChange: TLVDataStateChangeEvent read FOnDataStateChange write FOnDataStateChange;
    property OnDeletion: TLVDeletedEvent read FOnDeletion write FOnDeletion;
    property OnEdited: TLVEditedEvent read FOnEdited write FOnEdited;
    property OnEditing: TLVEditingEvent read FOnEditing write FOnEditing;
    property OnInsert: TLVInsertEvent read FOnInsert write FOnInsert;
    property OnItemChecked: TLVCheckedItemEvent read FOnItemChecked write FOnItemChecked;
    property OnSelectItem: TLVSelectItemEvent read FOnSelectItem write FOnSelectItem;
    property OnCustomDraw: TLVCustomDrawEvent read FOnCustomDraw write FOnCustomDraw;
    property OnCustomDrawItem: TLVCustomDrawItemEvent read FOnCustomDrawItem write FOnCustomDrawItem;
    property OnCustomDrawSubItem: TLVCustomDrawSubItemEvent read FOnCustomDrawSubItem write FOnCustomDrawSubItem;
    property OnAdvancedCustomDraw: TLVAdvancedCustomDrawEvent read FOnAdvancedCustomDraw write FOnAdvancedCustomDraw;
    property OnAdvancedCustomDrawItem: TLVAdvancedCustomDrawItemEvent read FOnAdvancedCustomDrawItem write FOnAdvancedCustomDrawItem;
    property OnAdvancedCustomDrawSubItem: TLVAdvancedCustomDrawSubItemEvent read FOnAdvancedCustomDrawSubItem write FOnAdvancedCustomDrawSubItem;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AlphaSort: Boolean; // always sorts column 0 in sdAscending order
    procedure BeginUpdate;
    procedure Clear;
    procedure EndUpdate;
    procedure Repaint; override;
    function FindCaption(StartIndex: Integer; Value: string; Partial, Inclusive, Wrap: Boolean; PartStart: Boolean = True): TListItem;
    function FindData(StartIndex: Integer; Value: Pointer;  Inclusive, Wrap: Boolean): TListItem;
    function GetHitTestInfoAt(X, Y: Integer): THitTests;
    function GetItemAt(x,y: integer): TListItem;
    function IsEditing: Boolean; // Delphi compatibile function which returns if our listview editor is active
    property BoundingRect: TRect read GetBoundingRect;
    property BorderStyle default bsSingle;
    property Canvas: TCanvas read FCanvas;
    property Checkboxes: Boolean index Ord(lvpCheckboxes) read GetProperty write SetProperty default False;
    property Column[AIndex: Integer]: TListColumn read GetColumnFromIndex;
    property ColumnCount: Integer read GetColumnCount;
    property DropTarget: TListItem read GetDropTarget write SetDropTarget;
    property FlatScrollBars: Boolean index Ord(lvpFlatScrollBars) read GetProperty write SetProperty default False;
    property FullDrag: Boolean index Ord(lvpFullDrag) read GetProperty write SetProperty default False;
    property GridLines: Boolean index Ord(lvpGridLines) read GetProperty write SetProperty default False;
    property HotTrack: Boolean index Ord(lvpHotTrack) read GetProperty write SetProperty default False;
    property HotTrackStyles: TListHotTrackStyles read FHotTrackStyles write SetHotTrackStyles default [];
    property IconOptions: TIconOptions read FIconOptions write SetIconOptions;
    property ItemFocused: TListItem read GetFocused write SetFocused;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property Items: TListItems read FListItems write SetItems;
    // MultiSelect and ReadOnly should be protected, but can't because Carbon Interface
    // needs to access this property and it cannot cast to TListItem, because we have
    // other classes descending from TCustomListItem which need to work too
    property MultiSelect: Boolean index Ord(lvpMultiselect) read GetProperty write SetProperty default False;
    property OwnerData: Boolean read FOwnerData write SetOwnerData default False;
    property ReadOnly: Boolean index Ord(lvpReadOnly) read GetProperty write SetProperty default False;
    property RowSelect: Boolean index Ord(lvpRowSelect) read GetProperty write SetProperty default False;
    property SelCount: Integer read GetSelCount;
    property Selected: TListItem read GetSelection write SetSelection;
    property TabStop default true;
    property TopItem: TListItem read GetTopItem;
    property ViewOrigin: TPoint read GetViewOrigin write SetViewOrigin;
    property VisibleRowCount: Integer read GetVisibleRowCount;
  end;


  { TListView }

  TListView = class(TCustomListView)
  published
    property Align;
    property AllocBy;
    property Anchors;
    property AutoSort;
    property AutoWidthLastColumn: Boolean read FAutoWidthLastColumn write SetAutoWidthLastColumn default False; // resize last column to fit width of TListView
    property BorderSpacing;
    property BorderStyle;
    property BorderWidth;
    property Checkboxes;
    property Color default {$ifdef UseCLDefault}clDefault{$else}clWindow{$endif};
    property Columns;
    property ColumnClick;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
//    property DefaultItemHeight;
//    property DropTarget;
    property Enabled;
//    property FlatScrollBars;
    property Font;
//    property FullDrag;
    property GridLines;
    property HideSelection;
//    property HotTrack;
//    property HotTrackStyles;
//    property HoverTime;
    property IconOptions;
//    property ItemIndex; shouldn't be published, see bug 16367
    property Items;
    property LargeImages;
    property MultiSelect;
    property OwnerData;
//    property OwnerDraw;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property RowSelect;
    property ScrollBars;
    property ShowColumnHeaders;
    property ShowHint;
//    property ShowWorkAreas;
    property SmallImages;
    property SortColumn;
    property SortDirection;
    property SortType;
    property StateImages;
    property TabStop;
    property TabOrder;
    property ToolTips;
    property Visible;
    property ViewStyle;
    property OnAdvancedCustomDraw;
    property OnAdvancedCustomDrawItem;
    property OnAdvancedCustomDrawSubItem;
    property OnChange;
    property OnClick;
    property OnColumnClick;
    property OnCompare;
    property OnContextPopup;
    property OnCreateItemClass;
    property OnCustomDraw;
    property OnCustomDrawItem;
    property OnCustomDrawSubItem;
    property OnData;
    property OnDataFind;
    property OnDataHint;
    property OnDataStateChange;
    property OnDblClick;
    property OnDeletion;
    property OnDragDrop;
    property OnDragOver;
    property OnEdited;
    property OnEditing;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnItemChecked;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnSelectItem;
    property OnStartDock;
    property OnStartDrag;
    property OnUTF8KeyPress;
  end;

  TProgressBarOrientation = (pbHorizontal, pbVertical, pbRightToLeft, pbTopDown);

  TProgressBarStyle = (pbstNormal, pbstMarquee);

  { TCustomProgressBar }
  {
    @abstract(Simple progressbar.)
    Introduced by Author Name <stoppok@osibisa.ms.sub.org>
    Currently maintained by Maintainer Name <stoppok@osibisa.ms.sub.org>
  }
  TCustomProgressBar = class(TWinControl)
  private
    FMin: Integer;
    FMax: Integer;
    FStep: Integer;
    FPosition: Integer;
    FSmooth: boolean;
    FBarShowText: boolean;
    FBarTextFormat: string;
    FOrientation: TProgressBarOrientation;
    FStyle: TProgressBarStyle;
    function GetMin: Integer;
    function GetMax: Integer;
    function GetPosition: Integer;
    procedure SetParams(AMin, AMax: Integer);
    procedure SetMin(Value: Integer);
    procedure SetMax(Value: Integer);
    procedure SetPosition(Value: Integer);
    procedure SetStep(Value: Integer);
    procedure SetSmooth (Value : boolean);
    procedure SetBarShowText (Value : boolean);
    procedure SetOrientation (Value : TProgressBarOrientation);
    procedure SetStyle(const AValue: TProgressBarStyle);
  protected
    class procedure WSRegisterClass; override;
    procedure ApplyChanges;
    procedure InitializeWnd; override;
    procedure Loaded; override;
    class function GetControlClassDefaultSize: TSize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure StepIt;
    procedure StepBy(Delta: Integer);
  public
    property Max: Integer read GetMax write SetMax default 100;
    property Min: Integer read GetMin write SetMin default 0;
    property Orientation: TProgressBarOrientation read FOrientation write SetOrientation default pbHorizontal;
    property Position: Integer read GetPosition write SetPosition default 0;
    property Smooth : boolean read FSmooth write SetSmooth default False;
    property Step: Integer read FStep write SetStep default 10;
    property Style: TProgressBarStyle read FStyle write SetStyle default pbstNormal;
    property BarShowText : boolean read FBarShowText write SetBarShowText default False;
  end;
 
 
  { TProgressBar }
 
  TProgressBar = class(TCustomProgressBar)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property BorderWidth;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Hint;
    property Max;
    property Min;
    property OnContextPopup;
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
    property OnStartDock;
    property OnStartDrag;
    property Orientation;
    property ParentShowHint;
    property PopupMenu;
    property Position;
    property ShowHint;
    property Smooth;
    property Step;
    property Style;
    property TabOrder;
    property TabStop;
    property Visible;
    property BarShowText;
  end;
 

  TUDAlignButton = (udLeft, udRight, udTop, udBottom);
  TUDOrientation = (udHorizontal, udVertical);
  TUpDownDirection = (updNone, updUp, updDown);
  TUDBtnType = (btNext, btPrev);
  TUDClickEvent = procedure (Sender: TObject; Button: TUDBtnType) of object;
  TUDChangingEvent = procedure (Sender: TObject; var AllowChange: Boolean) of object;
  TUDChangingEventEx = procedure (Sender: TObject; var AllowChange: Boolean; NewValue: SmallInt; Direction: TUpDownDirection) of object;

  { TCustomUpDown }

  TCustomUpDown = class(TCustomControl)
  private
    FOnChangingEx: TUDChangingEventEx;
    FOnChanging: TUDChangingEvent;
    MinBtn: TControl; // TSpeedButton
    MaxBtn: TControl; // TSpeedButton
    BTimerProc: procedure of Object;
    BTimerBounds : TRect;
    FArrowKeys: Boolean;
    FAssociate: TWinControl;
    FMin: SmallInt;
    FMax: SmallInt;
    FIncrement: Integer;
    FPosition: SmallInt;
    FThousands: Boolean;
    FWrap: Boolean;
    FOnClick: TUDClickEvent;
    FAlignButton: TUDAlignButton;
    FOrientation: TUDOrientation;
    FCanChange: record
      // some temp info needed for can changeex
      // it would have been better to pass this to the CanChange() function,
      // but that would break compatebility, so we do it the vcl way
      Pos: SmallInt;
      Dir: TUpDownDirection;
    end;
    function GetPosition: SmallInt;
    procedure BTimerExec(Sender : TObject);
    procedure SetAlignButton(Value: TUDAlignButton);
    procedure SetArrowKeys(Value: Boolean);
    procedure SetAssociate(Value: TWinControl);
    procedure SetIncrement(Value: Integer);
    procedure SetMax(Value: SmallInt);
    procedure SetMin(Value: SmallInt);
    procedure SetOrientation(Value: TUDOrientation);
    procedure SetPosition(Value: SmallInt);
    procedure SetThousands(Value: Boolean);
    procedure SetWrap(Value: Boolean);
    procedure UpdateAlignButtonPos;
    procedure UpdateOrientation;
    procedure UpdateUpDownPositionText;
  protected
    class procedure WSRegisterClass; override;
    procedure AssociateKeyDown(Sender: TObject; var Key: Word; ShiftState : TShiftState);
    procedure OnAssociateChangeBounds(Sender: TObject);
    procedure OnAssociateChangeEnabled(Sender: TObject);
    procedure OnAssociateChangeVisible(Sender: TObject);
    procedure DoOnResize; override;
    procedure SetEnabled(Value: Boolean); override;
    class function GetControlClassDefaultSize: TSize; override;
    function CanChange: Boolean; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Click(Button: TUDBtnType); virtual; overload;
    property AlignButton: TUDAlignButton read FAlignButton write SetAlignButton default udRight;
    property ArrowKeys: Boolean read FArrowKeys write SetArrowKeys default True;
    property Associate: TWinControl read FAssociate write SetAssociate;
    property Min: SmallInt read FMin write SetMin;
    property Max: SmallInt read FMax write SetMax default 100;
    property Increment: Integer read FIncrement write SetIncrement default 1;
    property Orientation: TUDOrientation read FOrientation write SetOrientation default udVertical;
    property Position: SmallInt read GetPosition write SetPosition;
    property Thousands: Boolean read FThousands write SetThousands default True;
    property Wrap: Boolean read FWrap write SetWrap;
    property OnChanging: TUDChangingEvent read FOnChanging write FOnChanging;
    property OnChangingEx: TUDChangingEventEx read FOnChangingEx write FOnChangingEx;
    property OnClick: TUDClickEvent read FOnClick write FOnClick;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; Override;
  end;


  { TUpDown }

  TUpDown = class(TCustomUpDown)
  published
    property AlignButton;
    property Anchors;
    property Associate;
    property ArrowKeys;
    property BorderSpacing;
    property Enabled;
    property Hint;
    property Min;
    property Max;
    property Increment;
    property Constraints;
    property Orientation;
    property ParentShowHint;
    property PopupMenu;
    property Position;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Thousands;
    property Visible;
    property Wrap;
    property OnChanging;
    property OnChangingEx;
    property OnClick;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;


  { TToolButton }

const
  CN_DROPDOWNCLOSED = LM_USER + $1000;

type
  TToolButtonStyle =
  (
    tbsButton,    // button (can be clicked)
    tbsCheck,     // check item (click to toggle state, can be grouped)
    tbsDropDown,  // button with dropdown button to show a popup menu
    tbsSeparator, // space holder
    tbsDivider    // space holder with line
  );
    
  TToolButtonFlag =
  (
    tbfPressed,     // set while mouse is pressed on button
    tbfArrowPressed // set while mouse is pressed on arrow button
  );
  TToolButtonFlags = set of TToolButtonFlag;

  { TToolButtonActionLink }

  TToolButtonActionLink = class(TControlActionLink)
  protected
    procedure AssignClient(AClient: TObject); override;
    procedure SetChecked(Value: Boolean); override;
    procedure SetImageIndex(Value: Integer); override;
  public
    function IsCheckedLinked: Boolean; override;
    function IsImageIndexLinked: Boolean; override;
  end;

  TToolButtonActionLinkClass = class of TToolButtonActionLink;
  
  TToolBar = class;

  TToolButton = class(TGraphicControl)
  private
    FAllowAllUp: Boolean;
    FDown: Boolean;
    FDropdownMenu: TPopupMenu;
    FGrouped: Boolean;
    FImageIndex: TImageIndex;
    FIndeterminate: Boolean;
    FMarked: Boolean;
    FMenuItem: TMenuItem;
    FMouseInControl: boolean;
    FShowCaption: boolean;
    FStyle: TToolButtonStyle;
    FToolButtonFlags: TToolButtonFlags;
    FUpdateCount: Integer;
    FWrap: Boolean;
    procedure GetGroupBounds(var StartIndex, EndIndex: integer);
    function GetIndex: Integer;
    function GetTextSize: TSize;
    function IsCheckedStored: Boolean;
    function IsImageIndexStored: Boolean;
    function IsWidthStored: Boolean;
    procedure SetDown(Value: Boolean);
    procedure SetDropdownMenu(Value: TPopupMenu);
    procedure SetGrouped(Value: Boolean);
    procedure SetImageIndex(Value: TImageIndex);
    procedure SetIndeterminate(Value: Boolean);
    procedure SetMarked(Value: Boolean);
    procedure SetMenuItem(Value: TMenuItem);
    procedure SetShowCaption(const AValue: boolean);
    procedure SetStyle(Value: TToolButtonStyle);
    procedure SetWrap(Value: Boolean);
    procedure SetMouseInControl(NewMouseInControl: Boolean);
    procedure CMEnabledChanged(var Message: TLMEssage); message CM_ENABLEDCHANGED;
    procedure CMVisibleChanged(var Message: TLMessage); message CM_VISIBLECHANGED;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
  protected
    FToolBar: TToolBar;
    class procedure WSRegisterClass; override;
    procedure CopyPropertiesFromMenuItem(const Value: TMenuItem);
    function GetActionLinkClass: TControlActionLinkClass; override;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
    procedure AssignTo(Dest: TPersistent); override;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure TextChanged; override;
    procedure CalculatePreferredSize(
                         var PreferredWidth, PreferredHeight: integer;
                         WithThemeSpace: Boolean); override;
    class function GetControlClassDefaultSize: TSize; override;
    procedure Loaded; override;
    procedure RefreshControl; virtual;
    procedure SetToolBar(NewToolBar: TToolBar);
    procedure UpdateControl; virtual;
    function GetButtonDrawDetail: TThemedElementDetails; virtual;
    procedure SetParent(AParent: TWinControl); override;
    procedure UpdateVisibleToolbar;
    function GroupAllUpAllowed: boolean;
    function DialogChar(var Message: TLMKey): boolean; override;
    procedure SetAutoSize(Value: Boolean); override;
    procedure RealSetText(const AValue: TCaption); override;
  public
    constructor Create(TheOwner: TComponent); override;
    function CheckMenuDropdown: Boolean; virtual;
    procedure Click; override;
    procedure GetCurrentIcon(var ImageList: TCustomImageList;
                             var TheIndex: integer); virtual;
    procedure GetPreferredSize(var PreferredWidth, PreferredHeight: integer;
                               Raw: boolean = false;
                               WithThemeSpace: boolean = true); override;
    property Index: Integer read GetIndex;
  published
    property Action;
    property AllowAllUp: Boolean read FAllowAllUp write FAllowAllUp default False;
    property AutoSize default False;
    property Caption;
    property Down: Boolean read FDown write SetDown stored IsCheckedStored default False;
    property DragCursor;
    property DragKind;
    property DragMode;
    property DropdownMenu: TPopupMenu read FDropdownMenu write SetDropdownMenu;
    property Enabled;
    property Grouped: Boolean read FGrouped write SetGrouped default False;
    property Height stored False;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex stored IsImageIndexStored default -1;
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate default False;
    property Marked: Boolean read FMarked write SetMarked default False;
    property MenuItem: TMenuItem read FMenuItem write SetMenuItem;
    property OnClick;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
    property ParentShowHint;
    property PopupMenu;
    property ShowCaption: boolean read FShowCaption write SetShowCaption default true;
    property ShowHint;
    property Style: TToolButtonStyle read FStyle write SetStyle default tbsButton;
    property Visible;
    property Width stored IsWidthStored;
    property Wrap: Boolean read FWrap write SetWrap default False;
  end;

  { TToolBarEnumerator }

  TToolBarEnumerator = class
  private
    FToolBar: TToolBar;
    FPosition: Integer;
    function GetCurrent: TToolButton;
  public
    constructor Create(AToolBar: TToolBar);
    function MoveNext: Boolean;
    property Current: TToolButton read GetCurrent;
  end;

  { TToolBar }
  
  TToolBarFlag = (
    tbfUpdateVisibleBarNeeded,
    tbfPlacingControls
    );
  
  TToolBarFlags = set of TToolBarFlag;
  
  TToolBar = class(TToolWindow)
  private
    FButtonHeight: Integer;
    FRealizedButtonHeight,
    FRealizedButtonWidth: integer;
    FButtons: TList;
    FButtonWidth: Integer;
    FDisabledImageChangeLink: TChangeLink;
    FDisabledImages: TCustomImageList;
    FDropDownWidth: integer;
    FDropDownButton: TToolButton;
    FFlat: Boolean;
    FHotImageChangeLink: TChangeLink;
    FHotImages: TCustomImageList;
    FImageChangeLink: TChangeLink;
    FImages: TCustomImageList;
    FIndent: Integer;
    FList: Boolean;
    FNewStyle: Boolean;
    FRowCount: integer;
    FShowCaptions: Boolean;
    FCurrentMenu: TPopupMenu;
    FCurrentMenuAutoFree: boolean;
    FSrcMenu: TMenu;
    FSrcMenuItem: TMenuItem;
    FToolBarFlags: TToolBarFlags;
    FUpdateCount: Integer;
    FWrapable: Boolean;
    procedure ApplyFontForButtons;
    procedure CloseCurrentMenu;
    function GetButton(Index: Integer): TToolButton;
    function GetButtonCount: Integer;
    function GetTransparent: Boolean;
    procedure SetButtonHeight(const AValue: Integer);
    procedure SetButtonWidth(const AValue: Integer);
    procedure SetDisabledImages(const AValue: TCustomImageList);
    procedure SetFlat(const AValue: Boolean);
    procedure SetHotImages(const AValue: TCustomImageList);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetIndent(const AValue: Integer);
    procedure SetList(const AValue: Boolean);
    procedure SetShowCaptions(const AValue: Boolean);
    procedure SetTransparent(const AValue: Boolean);
    procedure SetWrapable(const AValue: Boolean);
    procedure ToolButtonDown(AButton: TToolButton; NewDown: Boolean);
    procedure ImageListChange(Sender: TObject);
    procedure DisabledImageListChange(Sender: TObject);
    procedure HotImageListChange(Sender: TObject);
    procedure UpdateVisibleBar;
    procedure MoveSubMenuItems(SrcMenuItem, DestMenuItem: TMenuItem);
    procedure AddButton(Button: TToolButton);
    procedure RemoveButton(Button: TToolButton);
    function IsVertical: Boolean;
  protected
    class procedure WSRegisterClass; override;
    procedure AdjustClientRect(var ARect: TRect); override;
    class function GetControlClassDefaultSize: TSize; override;
    procedure DoAutoSize; override;
    procedure CalculatePreferredSize(var PreferredWidth,
                    PreferredHeight: integer; WithThemeSpace: Boolean); override;
    function CheckMenuDropdown(Button: TToolButton): Boolean; virtual;
    procedure ClickButton(Button: TToolButton); virtual;
    procedure CreateWnd; override;
    procedure ControlsAligned; override;
    function FindButtonFromAccel(Accel: Word): TToolButton;
    procedure FontChanged(Sender: TObject); override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure RepositionButton(Index: Integer);
    procedure RepositionButtons(Index: Integer);
    function WrapButtons(UseSize: integer;
                         out NewWidth, NewHeight: Integer;
                         Simulate: boolean): Boolean;
    procedure CNDropDownClosed(var Message: TLMessage); message CN_DROPDOWNCLOSED;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure FlipChildren(AllLevels: Boolean); override;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    function GetEnumerator: TToolBarEnumerator;
    procedure Paint; override;
    procedure SetButtonSize(NewButtonWidth, NewButtonHeight: integer);
    function CanFocus: Boolean; override;
  public
    property ButtonCount: Integer read GetButtonCount;
    property Buttons[Index: Integer]: TToolButton read GetButton;
    property ButtonList: TList read FButtons;
    property RowCount: Integer read FRowCount;
  published
    property Align default alTop;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property BorderWidth;
    property ButtonHeight: Integer read FButtonHeight write SetButtonHeight default 22;
    property ButtonWidth: Integer read FButtonWidth write SetButtonWidth default 23;
    property Caption;
    property ChildSizing;
    property Constraints;
    property Color;
    //property Customizable: Boolean read FCustomizable write SetCustomizable default False;
    property DisabledImages: TCustomImageList read FDisabledImages write SetDisabledImages;
    property DragCursor;
    property DragKind;
    property DragMode;
    property EdgeBorders default [ebTop];
    property EdgeInner;
    property EdgeOuter;
    property Enabled;
    property Flat: Boolean read FFlat write SetFlat default True;
    property Font;
    property Height default 32;
    //property HideClippedButtons: Boolean read FHideClippedButtons write SetHideClippedButtons default False;
    property HotImages: TCustomImageList read FHotImages write SetHotImages;
    property Images: TCustomImageList read FImages write SetImages;
    property Indent: Integer read FIndent write SetIndent default 1;
    property List: Boolean read FList write SetList default False;
    //property Menu: TMainMenu read FMenu write SetMenu;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowCaptions: Boolean read FShowCaptions write SetShowCaptions default False;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Transparent: Boolean read GetTransparent write SetTransparent default False;
    property Visible;
    property Wrapable: Boolean read FWrapable write SetWrapable default True;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
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
    property OnResize;
    property OnChangeBounds;
    property OnStartDrag;
  end;
  

  { TCustomTrackBar }

  TTrackBarOrientation = (trHorizontal, trVertical);
  TTickMark = (tmBottomRight, tmTopLeft, tmBoth);
  TTickStyle = (tsNone, tsAuto, tsManual);
  TTrackBarScalePos = (trLeft, trRight, trTop, trBottom);

  TCustomTrackBar = class(TWinControl)
  private
    FOrientation: TTrackBarOrientation;
    FReversed: Boolean;
    FSelEnd: Integer;
    FSelStart: Integer;
    FShowSelRange: Boolean;
    FTickMarks: TTickMark;
    FTickStyle: TTickStyle;
    FLineSize: Integer;
    FPageSize: Integer;
    FMin: Integer;
    FMax: Integer;
    FFrequency: Integer;
    FPosition: Integer;
    FScalePos: TTrackBarScalePos;
    FScaleDigits: integer;
    FOnChange: TNotifyEvent;
    procedure SetFrequency(Value: Integer);
    procedure SetLineSize(Value: Integer);
    procedure SetMax(Value: Integer);
    procedure SetMin(Value: Integer);
    procedure SetOrientation(Value: TTrackBarOrientation);
    procedure SetPageSize(Value: Integer);
    procedure SetParams(APosition, AMin, AMax: Integer);
    procedure SetPosition(Value: Integer);
    procedure SetReversed(const AValue: Boolean);
    procedure SetScalePos(Value: TTrackBarScalePos);
    procedure SetSelEnd(const AValue: Integer);
    procedure SetSelStart(const AValue: Integer);
    procedure SetShowSelRange(const AValue: Boolean);
    procedure SetTickMarks(Value: TTickMark);
    procedure SetTickStyle(Value: TTickStyle);
    procedure UpdateSelection;
  protected
    class procedure WSRegisterClass; override;
    procedure ApplyChanges;
    procedure Changed; virtual;
    procedure DoChange(var msg); message LM_CHANGED;
    procedure FixParams(var APosition, AMin, AMax: Integer);
    class function GetControlClassDefaultSize: TSize; override;
    procedure InitializeWnd; override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetTick(Value: Integer);
  published
    property Frequency: Integer read FFrequency write SetFrequency default 1;
    property LineSize: Integer read FLineSize write SetLineSize default 1;
    property Max: Integer read FMax write SetMax default 10;
    property Min: Integer read FMin write SetMin default 0;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Orientation: TTrackBarOrientation read FOrientation write SetOrientation default trHorizontal;
    property PageSize: Integer read FPageSize write SetPageSize default 2;
    property Position: Integer read FPosition write SetPosition;
    property Reversed: Boolean read FReversed write SetReversed default False;
    property ScalePos: TTrackBarScalePos read FScalePos write SetScalePos default trTop;
    property SelEnd: Integer read FSelEnd write SetSelEnd default 0;
    property SelStart: Integer read FSelStart write SetSelStart default 0;
    property ShowSelRange: Boolean read FShowSelRange write SetShowSelRange default True;
    property TabStop default True;
    property TickMarks: TTickMark read FTickMarks write SetTickMarks default tmBottomRight;
    property TickStyle: TTickStyle read FTickStyle write SetTickStyle default tsAuto;
  end;
  
  
  { TTrackBar }
  
  TTrackBar = class(TCustomTrackBar)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Frequency;
    property Hint;
    property LineSize;
    property Max;
    property Min;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnContextPopup;
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
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnResize;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property Orientation;
    property PageSize;
    property ParentShowHint;
    property PopupMenu;
    property Position;
    property Reversed;
    property ScalePos;
    property SelEnd;
    property SelStart;
    property ShowHint;
    property ShowSelRange;
    property TabOrder;
    property TabStop;
    property TickMarks;
    property TickStyle;
    property Visible;
  end;
  
{ TTreeNode }

type
  TCustomTreeView = class;
  TTreeNodes = class;
  TTreeNode = class;
  TTreeNodeClass = class of TTreeNode;

  TNodeState = (nsCut, nsDropHilited, nsFocused, nsSelected, nsMultiSelected,
                nsExpanded, nsHasChildren, nsInTree, nsDeleting, nsBound);
  TNodeStates = set of TNodeState;
  TNodeAttachMode = (
    naAdd,           // add as last sibling of Destination
    naAddFirst,      // add as first sibling of Destination
    naAddChild,      // add as last child of Destination
    naAddChildFirst, // add as first child of Destination
    naInsert,        // insert in front of Destination
    naInsertBehind   // insert behind Destination
    );

  TAddMode = (taAddFirst, taAdd, taInsert);

  TMultiSelectStyles = (msControlSelect, msShiftSelect, msVisibleOnly, msSiblingOnly);
  TMultiSelectStyle = set of TMultiSelectStyles;

  TTreeNodeArray = ^TTreeNode;

  ETreeNodeError = class(Exception);
  ETreeViewError = class(ETreeNodeError);

const
  LCLStreamID = -7;

type
  TTVChangingEvent = procedure(Sender: TObject; Node: TTreeNode;
                               var AllowChange: Boolean) of object;
  TTVChangedEvent = procedure(Sender: TObject; Node: TTreeNode) of object;
  TTVEditingEvent = procedure(Sender: TObject; Node: TTreeNode;
                              var AllowEdit: Boolean) of object;
  TTVEditingEndEvent = procedure(Sender: TObject; Node: TTreeNode;
                              Cancel: Boolean) of object;
  TTVEditedEvent = procedure(Sender: TObject; Node: TTreeNode;
                             var S: string) of object;
  TTVExpandingEvent = procedure(Sender: TObject; Node: TTreeNode;
                                var AllowExpansion: Boolean) of object;
  TTVCollapsingEvent = procedure(Sender: TObject; Node: TTreeNode;
                                 var AllowCollapse: Boolean) of object;
  TTVExpandedEvent = procedure(Sender: TObject; Node: TTreeNode) of object;
  TTVCompareEvent = procedure(Sender: TObject; Node1, Node2: TTreeNode;
                              var Compare: Integer) of object;
  TTVCustomDrawEvent = procedure(Sender: TCustomTreeView; const ARect: TRect;
                                 var DefaultDraw: Boolean) of object;
  TTVCustomDrawItemEvent = procedure(Sender: TCustomTreeView; Node: TTreeNode;
                   State: TCustomDrawState; var DefaultDraw: Boolean) of object;
  TTVAdvancedCustomDrawEvent = procedure(Sender: TCustomTreeView;
                                    const ARect: TRect; Stage: TCustomDrawStage;
                                    var DefaultDraw: Boolean) of object;
  TTVAdvancedCustomDrawItemEvent = procedure(Sender: TCustomTreeView;
              Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
              var PaintImages, DefaultDraw: Boolean) of object;
  TTVCustomCreateNodeEvent = procedure(Sender: TCustomTreeView;
                                       var ATreeNode: TTreenode) of object;
  TTVCreateNodeClassEvent = procedure(Sender: TCustomTreeView;
                                      var NodeClass: TTreeNodeClass) of object;

  TTreeNodeCompare = function(Node1, Node2: TTreeNode): integer of object;

  TOldTreeNodeInfo = packed record
    ImageIndex: Integer;
    SelectedIndex: Integer;
    StateIndex: Integer;
    OverlayIndex: Integer;
    Data: Pointer;
    Count: Integer;
    Height: integer;
    Expanded: boolean;
    TextLen: integer;
    // here follows the text
  end;

  TTreeNodeInfo = packed record
    ImageIndex: Integer;
    SelectedIndex: Integer;
    StateIndex: Integer;
    OverlayIndex: Integer;
    Count: Integer;
    Height: integer;
    Expanded: boolean;
    TextLen: integer;
    // here follows the text
  end;

  // this is the delphi node stream record
  PDelphiNodeInfo = ^TDelphiNodeInfo;
  TDelphiNodeInfo = packed record
    ImageIndex: Integer;
    SelectedIndex: Integer;
    StateIndex: Integer;
    OverlayIndex: Integer;
    Data: Pointer;
    Count: Integer;
    Text: string[255];
  end;

  { TTreeNode }

  TTreeNode = class(TPersistent)
  private
    FOwner: TTreeNodes;   // the object, which contains all nodes of the tree
    FCapacity: integer;   // size of FItems
    FCount: integer;      // # of first level children in FItems
    FData: Pointer;       // custom data
    FHeight: integer;     // height in pixels
    FNodeEffect: TGraphicsDrawEffect;
    FImageIndex: TImageIndex;
    FIndex: integer;      // index in parent
    FItems: TTreeNodeArray;  // first level child nodes
    FNextBrother: TTreeNode; // next sibling
    FNextMultiSelected: TTreeNode;
    FOverlayIndex: Integer;
    FParent: TTreeNode;
    FPrevBrother: TTreeNode; // previous sibling
    FPrevMultiSelected: TTreeNode;
    FSelectedIndex: Integer;
    FStateIndex: Integer;
    FStates: TNodeStates;
    FSubTreeCount: integer;// total of all child nodes and self
    FText: string;
    FTop: integer;        // top coordinate
    FVisible: Boolean;
    function AreParentsExpandedAndVisible: Boolean;
    procedure BindToMultiSelected;
    function CompareCount(CompareMe: Integer): Boolean;
    function DoCanExpand(ExpandIt: Boolean): Boolean;
    procedure DoExpand(ExpandIt: Boolean);
    procedure ExpandItem(ExpandIt: Boolean; Recurse: Boolean);
    function GetAbsoluteIndex: Integer;
    function GetDeleting: Boolean;
    function GetHasChildren: Boolean;
    function GetCount: Integer;
    function GetCut: boolean;
    function GetDropTarget: Boolean;
    function GetExpanded: Boolean;
    function GetFocused: Boolean;
    function GetHeight: integer;
    function GetIndex: Integer;
    function GetItems(AnIndex: Integer): TTreeNode;
    function GetLevel: Integer;
    function GetMultiSelected: Boolean;
    function GetSelected: Boolean;
    function GetState(NodeState: TNodeState): Boolean;
    function GetTreeNodes: TTreeNodes;
    function GetTreeView: TCustomTreeView;
    function GetTop: integer;
    procedure InternalMove(ANode: TTreeNode; AddMode: TAddMode);
    function IsEqual(Node: TTreeNode): Boolean;
    function IsNodeVisible: Boolean;
    function IsNodeHeightFullVisible: Boolean;
    procedure ReadData(Stream: TStream; StreamVersion: integer);
    procedure ReadDelphiData(Stream: TStream; Info: PDelphiNodeInfo);
    procedure SetCut(AValue: Boolean);
    procedure SetData(AValue: Pointer);
    procedure SetDropTarget(AValue: Boolean);
    procedure SetExpanded(AValue: Boolean);
    procedure SetFocused(AValue: Boolean);
    procedure SetHasChildren(AValue: Boolean);
    procedure SetHeight(AValue: integer);
    procedure SetImageEffect(AValue: TGraphicsDrawEffect);
    procedure SetImageIndex(AValue: TImageIndex);
    procedure SetIndex(const AValue: Integer);
    procedure SetItems(AnIndex: Integer; AValue: TTreeNode);
    procedure SetMultiSelected(const AValue: Boolean);
    procedure SetOverlayIndex(AValue: Integer);
    procedure SetSelected(AValue: Boolean);
    procedure SetSelectedIndex(AValue: Integer);
    procedure SetStateIndex(AValue: Integer);
    procedure SetText(const S: string);
    procedure SetVisible(const AValue: Boolean);
    procedure Unbind;
    procedure UnbindFromMultiSelected;
    procedure WriteData(Stream: TStream);
    procedure WriteDelphiData(Stream: TStream; Info: PDelphiNodeInfo);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AnOwner: TTreeNodes);
    function AlphaSort: Boolean;
    procedure Assign(Source: TPersistent); override;
    procedure Collapse(Recurse: Boolean);
    function CustomSort(SortProc: TTreeNodeCompare): Boolean;
    function DefaultTreeViewSort(Node1, Node2: TTreeNode): Integer;
    procedure Delete;
    procedure DeleteChildren;
    destructor Destroy; override;
    function DisplayExpandSignLeft: integer;
    function DisplayExpandSignRect: TRect;
    function DisplayExpandSignRight: integer;
    function DisplayIconLeft: integer;
    function DisplayRect(TextOnly: Boolean): TRect;
    function DisplayStateIconLeft: integer;
    function DisplayTextLeft: integer;
    function DisplayTextRight: integer;
    function EditText: Boolean;
    procedure EndEdit(Cancel: Boolean);
    procedure Expand(Recurse: Boolean);
    procedure ExpandParents;
    function Bottom: integer;
    function BottomExpanded: integer;
    function GetParentNodeOfAbsoluteLevel(TheAbsoluteLevel: integer): TTreeNode;
    function GetFirstChild: TTreeNode;
    function GetFirstVisibleChild: TTreeNode;
    function GetHandle: THandle;
    function GetLastSibling: TTreeNode;
    function GetLastChild: TTreeNode;
    function GetLastVisibleChild: TTreeNode;
    function GetLastSubChild: TTreeNode;
    function GetNext: TTreeNode;
    function GetNextSkipChildren: TTreeNode;
    function GetNextChild(AValue: TTreeNode): TTreeNode;
    function GetNextExpanded: TTreeNode;
    function GetNextMultiSelected: TTreeNode;
    function GetNextSibling: TTreeNode;
    function GetNextVisible: TTreeNode;
    function GetNextVisibleSibling: TTreeNode;
    function GetPrev: TTreeNode;
    function GetPrevChild(AValue: TTreeNode): TTreeNode;
    function GetPrevExpanded: TTreeNode;
    function GetPrevMultiSelected: TTreeNode;
    function GetPrevSibling: TTreeNode;
    function GetPrevVisible: TTreeNode;
    function GetPrevVisibleSibling: TTreeNode;
    function HasAsParent(AValue: TTreeNode): Boolean;
    function IndexOf(AValue: TTreeNode): Integer;
    function IndexOfText(const NodeText: string): Integer;
    function FindNode(const NodeText: string): TTreeNode;
    function GetTextPath: string;
    procedure MakeVisible;
    procedure MoveTo(Destination: TTreeNode; Mode: TNodeAttachMode); virtual;
    procedure MultiSelectGroup;
    procedure Update;
    procedure ConsistencyCheck;
    procedure WriteDebugReport(const Prefix: string; Recurse: boolean);
    property AbsoluteIndex: Integer read GetAbsoluteIndex;
    property Count: Integer read GetCount;
    property Cut: Boolean read GetCut write SetCut;
    property Data: Pointer read FData write SetData;
    property Deleting: Boolean read GetDeleting;
    property Focused: Boolean read GetFocused write SetFocused;
    property DropTarget: Boolean read GetDropTarget write SetDropTarget;
    property Expanded: Boolean read GetExpanded write SetExpanded;
    property Handle: THandle read GetHandle;
    property HasChildren: Boolean read GetHasChildren write SetHasChildren;
    property Height: integer read GetHeight write SetHeight;
    property NodeEffect: TGraphicsDrawEffect read FNodeEffect write SetImageEffect;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property Index: Integer read GetIndex write SetIndex;
    property IsVisible: Boolean read IsNodeVisible;
    property IsFullHeightVisible: Boolean read IsNodeHeightFullVisible;
    property Items[ItemIndex: Integer]: TTreeNode read GetItems write SetItems; default;
    property Level: Integer read GetLevel;
    property MultiSelected: Boolean read GetMultiSelected write SetMultiSelected;
    property OverlayIndex: Integer read FOverlayIndex write SetOverlayIndex default -1;
    property Owner: TTreeNodes read FOwner;
    property Parent: TTreeNode read FParent;
    property Selected: Boolean read GetSelected write SetSelected;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex default -1;
    property SubTreeCount: integer read FSubTreeCount;
    property StateIndex: Integer read FStateIndex write SetStateIndex default -1;
    property Text: string read FText write SetText;
    property TreeNodes: TTreeNodes read GetTreeNodes;
    property TreeView: TCustomTreeView read GetTreeView;
    property Top: integer read GetTop;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

  { TTreeNodesEnumerator }

  TTreeNodesEnumerator = class
  private
    FNodes: TTreeNodes;
    FPosition: Integer;
    function GetCurrent: TTreeNode;
  public
    constructor Create(ANodes: TTreeNodes);
    function MoveNext: Boolean;
    property Current: TTreeNode read GetCurrent;
  end;

  { TTreeNodes }

  PNodeCache = ^TNodeCache;
  TNodeCache = record
    CacheNode: TTreeNode;
    CacheIndex: Integer;
  end;

  { TTreeNodes }

  TTreeNodes = class(TPersistent)
  private
    FCount: integer;
    FSelection: TFPList;
    FFirstMultiSelected: TTreeNode;
    FLastMultiSelected: TTreeNode;
    FKeepCollapsedNodes: boolean;
    FNodeCache: TNodeCache;
    FOwner: TCustomTreeView;
    FTopLvlCapacity: integer;
    FTopLvlCount: integer;
    FTopLvlItems: TTreeNodeArray; // root and root siblings
    FUpdateCount: Integer;
    fNewNodeToBeAdded: TTreeNode;
    procedure ClearCache;
    function GetHandle: THandle;
    function GetNodeFromIndex(Index: Integer): TTreeNode;
    function GetSelectionCount: Cardinal;
    function GetTopLvlItems(Index: integer): TTreeNode;
    procedure GrowTopLvlItems;
    function IndexOfTopLvlItem(Node: TTreeNode): integer;
    procedure MoveTopLvlNode(TopLvlFromIndex, TopLvlToIndex: integer;
      Node: TTreeNode);
    procedure ReadData(Stream: TStream);
    procedure ReadExpandedState(Stream: TStream);
    procedure Repaint(ANode: TTreeNode);
    procedure ShrinkTopLvlItems;
    procedure SetTopLvlItems(Index: integer; AValue: TTreeNode);
    procedure WriteData(Stream: TStream);
    procedure WriteExpandedState(Stream: TStream);
  protected
    function InternalAddObject(Node: TTreeNode; const S: string;
      Data: Pointer; AddMode: TAddMode): TTreeNode;
    procedure DefineProperties(Filer: TFiler); override;
    function GetCount: Integer;
    function GetOwner: TPersistent; override;
    procedure SetItem(Index: Integer; AValue: TTreeNode);
    procedure SetUpdateState(Updating: Boolean);
  public
    constructor Create(AnOwner: TCustomTreeView);
    destructor Destroy; override;
    function Add(SiblingNode: TTreeNode; const S: string): TTreeNode;
    function AddChild(ParentNode: TTreeNode; const S: string): TTreeNode;
    function AddChildFirst(ParentNode: TTreeNode; const S: string): TTreeNode;
    function AddChildObject(ParentNode: TTreeNode; const S: string;
      Data: Pointer): TTreeNode;
    function AddChildObjectFirst(ParentNode: TTreeNode; const S: string;
      Data: Pointer): TTreeNode;
    function AddFirst(SiblingNode: TTreeNode; const S: string): TTreeNode;
    function AddObject(SiblingNode: TTreeNode; const S: string;
      Data: Pointer): TTreeNode;
    function AddObjectFirst(SiblingNode: TTreeNode; const S: string;
      Data: Pointer): TTreeNode;
    function AddNode(Node: TTreeNode; Relative: TTreeNode; const S: string;
      Ptr: Pointer; Method: TNodeAttachMode): TTreeNode;
    procedure Assign(Source: TPersistent); override;
    procedure BeginUpdate;
    procedure Clear;
    procedure ClearMultiSelection(ClearSelected: boolean = false);
    procedure SelectOnlyThis(Node: TTreeNode);
    function IsMultiSelection: boolean;
    procedure Delete(Node: TTreeNode);
    procedure EndUpdate;
    function GetEnumerator: TTreeNodesEnumerator;
    function GetFirstNode: TTreeNode;
    function GetFirstVisibleNode: TTreeNode;
    function GetLastNode: TTreeNode; // last top level node
    function GetLastVisibleNode: TTreeNode;
    function GetLastSubNode: TTreeNode; // absolute last node
    function GetLastExpandedSubNode: TTreeNode; // absolute last node
    function GetSelections(const AIndex: Integer): TTreeNode;
    function FindTopLvlNode(const NodeText: string): TTreeNode;
    function FindNodeWithText(const NodeText: string): TTreeNode;
    function FindNodeWithData(const NodeData: Pointer): TTreeNode;
    function Insert(NextNode: TTreeNode; const S: string): TTreeNode;
    function InsertObject(NextNode: TTreeNode; const S: string;
      Data: Pointer): TTreeNode;
    function InsertBehind(PrevNode: TTreeNode; const S: string): TTreeNode;
    function InsertObjectBehind(PrevNode: TTreeNode; const S: string;
      Data: Pointer): TTreeNode;
    procedure SelectionsChanged(ANode: TTreeNode; const AIsSelected: Boolean);
    procedure SortTopLevelNodes(SortProc: TTreeNodeCompare);
    procedure ConsistencyCheck;
    procedure WriteDebugReport(const Prefix: string; AllNodes: boolean);
    property Count: Integer read GetCount;
    property Item[Index: Integer]: TTreeNode read GetNodeFromIndex; default;
    property KeepCollapsedNodes: boolean
      read FKeepCollapsedNodes write FKeepCollapsedNodes;
    property Owner: TCustomTreeView read FOwner;
    property SelectionCount: Cardinal read GetSelectionCount;
    property TopLvlCount: integer read FTopLvlCount;
    property TopLvlItems[Index: integer]: TTreeNode
      read GetTopLvlItems write SetTopLvlItems;
  end;


  { TCustomTreeView }

  TTreeViewState = (
    tvsScrollbarChanged,
    tvsMaxRightNeedsUpdate,
    tvsTopsNeedsUpdate,
    tvsMaxLvlNeedsUpdate,
    tvsTopItemNeedsUpdate,
    tvsBottomItemNeedsUpdate,
    tvsCanvasChanged,
    tvsDragged,
    tvsIsEditing,
    tvsStateChanging,
    tvsManualNotify,
    tvsUpdating,
    tvsPainting,
    tvsDblClicked,
    tvsTripleClicked,
    tvsQuadClicked,
    tvsSelectionChanged,
    tvsEditOnMouseUp
    );
  TTreeViewStates = set of TTreeViewState;

  TTreeViewOption = (
    tvoAllowMultiselect,
    tvoAutoExpand,
    tvoAutoInsertMark,
    tvoAutoItemHeight,
    tvoHideSelection,
    tvoHotTrack,
    tvoKeepCollapsedNodes,
    tvoReadOnly,
    tvoRightClickSelect,
    tvoRowSelect,
    tvoShowButtons,
    tvoShowLines,
    tvoShowRoot,
    tvoShowSeparators,
    tvoToolTips,
    tvoNoDoubleClickExpand,
    tvoThemedDraw
    );
  TTreeViewOptions = set of TTreeViewOption;

const
  DefaultTreeViewOptions = [tvoShowRoot, tvoShowLines, tvoShowButtons,
                            tvoHideSelection, tvoToolTips,
                            tvoKeepCollapsedNodes, tvoAutoItemHeight, tvoThemedDraw];
  DefaultMultiSelectStyle = [msControlSelect];

type
  TTreeViewExpandSignType = (
    tvestTheme,      // use themed sign
    tvestPlusMinus,  // use +/- sign
    tvestArrow       // use arrow
  );

  TTreeViewInsertMarkType = (
    tvimNone,
    tvimAsFirstChild,  // or as root
    tvimAsNextSibling,
    tvimAsPrevSibling
  );

  TCustomTreeView = class(TCustomControl)
  private
    FAccessibilityOn: Boolean;
    FBackgroundColor: TColor;
    FBottomItem: TTreeNode;
    FEditingItem: TTreeNode;
    FExpandSignType: TTreeViewExpandSignType;
    FExpandSignSize: integer;
    FDefItemHeight: integer;
    FDragImage: TDragImageList;
    FDragNode: TTreeNode;
    FIndent: integer;
    FImageChangeLink: TChangeLink;
    FImages: TCustomImageList;
    FInsertMarkNode: TTreeNode;
    FInsertMarkType: TTreeViewInsertMarkType;
    FLastDropTarget: TTreeNode;
    FLastHorzScrollInfo: TScrollInfo;
    FLastVertScrollInfo: TScrollInfo;
    FMaxLvl: integer; // maximum level of all nodes
    FMaxRight: integer; // maximum text width of all nodes (needed for horizontal scrolling)
    fMouseDownPos: TPoint;
    FMultiSelectStyle: TMultiSelectStyle;
    FOnAddition: TTVExpandedEvent;
    FOnAdvancedCustomDraw: TTVAdvancedCustomDrawEvent;
    FOnAdvancedCustomDrawItem: TTVAdvancedCustomDrawItemEvent;
    FOnChange: TTVChangedEvent;
    FOnChanging: TTVChangingEvent;
    FOnCollapsed: TTVExpandedEvent;
    FOnCollapsing: TTVCollapsingEvent;
    FOnCompare: TTVCompareEvent;
    FOnCreateNodeClass: TTVCreateNodeClassEvent;
    FOnCustomCreateItem: TTVCustomCreateNodeEvent;
    FOnCustomDraw: TTVCustomDrawEvent;
    FOnCustomDrawItem: TTVCustomDrawItemEvent;
    FOnDeletion: TTVExpandedEvent;
    FOnEditing: TTVEditingEvent;
    FOnEditingEnd: TTVEditingEndEvent;
    FOnEdited: TTVEditedEvent;
    FOnExpanded: TTVExpandedEvent;
    FOnExpanding: TTVExpandingEvent;
    FOnGetImageIndex: TTVExpandedEvent;
    FOnGetSelectedIndex: TTVExpandedEvent;
    FOnSelectionChanged: TNotifyEvent;
    FOptions: TTreeViewOptions;
    FRClickNode: TTreeNode;
    FSaveItems: TStringList;
    FScrollBars: TScrollStyle;
    FScrolledLeft: integer; // horizontal scrolled pixels (hidden pixels at left)
    FScrolledTop: integer;  // vertical scrolled pixels (hidden pixels at top)
    FSelectedColor: TColor;
    FSelectedNode: TTreeNode;
    FSelectionChangeEventLock: integer;
    fSeparatorColor: TColor;
    FSortType: TSortType;
    FStateChangeLink: TChangeLink;
    FStateImages: TCustomImageList;
    FStates: TTreeViewStates;
    FTopItem: TTreeNode;
    FTreeLineColor: TColor;
    FTreeLinePenStyle: TPenStyle;
    FExpandSignColor : TColor;
    FTreeNodes: TTreeNodes;
    procedure CanvasChanged(Sender: TObject);
    function GetAutoExpand: boolean;
    function GetBottomItem: TTreeNode;
    function GetDropTarget: TTreeNode;
    function GetHideSelection: boolean;
    function GetHotTrack: boolean;
    function GetKeepCollapsedNodes: boolean;
    function GetMultiSelect: Boolean;
    function GetReadOnly: boolean;
    function GetRightClickSelect: boolean;
    function GetRowSelect: boolean;
    function GetSelection: TTreeNode;
    function GetSelectionCount: Cardinal;
    function GetSelections(AIndex: Integer): TTreeNode;
    function GetShowButtons: boolean;
    function GetShowLines: boolean;
    function GetShowRoot: boolean;
    function GetShowSeparators: boolean;
    function GetToolTips: boolean;
    function GetTopItem: TTreeNode;
    procedure ImageListChange(Sender: TObject);
    procedure OnChangeTimer(Sender: TObject);
    procedure SetAutoExpand(Value: Boolean);
    procedure SetBackgroundColor(Value: TColor);
    procedure SetBottomItem(Value: TTreeNode);
    procedure SetDefaultItemHeight(Value: integer);
    procedure SetExpandSignType(Value: TTreeViewExpandSignType);
    procedure SetDropTarget(Value: TTreeNode);
    procedure SetHideSelection(Value: Boolean);
    procedure SetHotTrack(Value: Boolean);
    procedure SetIndent(Value: Integer);
    procedure SetImages(Value: TCustomImageList);
    procedure SetInsertMarkNode(const AValue: TTreeNode);
    procedure SetInsertMarkType(const AValue: TTreeViewInsertMarkType);
    procedure SetKeepCollapsedNodes(Value: Boolean);
    procedure SetMultiSelect(const AValue: Boolean);
    procedure SetMultiSelectStyle(const AValue: TMultiSelectStyle);
    procedure SetReadOnly(Value: Boolean);
    procedure SetRightClickSelect(Value: Boolean);
    procedure SetRowSelect(Value: Boolean);
    procedure SetScrollBars(const Value: TScrollStyle);
    procedure SetScrolledLeft(AValue: integer);
    procedure SetScrolledTop(AValue: integer);
    procedure SetSelectedColor(Value: TColor);
    procedure SetSelection(Value: TTreeNode);
    procedure SetSeparatorColor(const AValue: TColor);
    procedure SetShowButton(Value: Boolean);
    procedure SetShowLines(Value: Boolean);
    procedure SetShowRoot(Value: Boolean);
    procedure SetShowSeparators(Value: Boolean);
    procedure SetSortType(Value: TSortType);
    procedure SetStateImages(Value: TCustomImageList);
    procedure SetToolTips(Value: Boolean);
    procedure SetTreeLineColor(Value: TColor);
    procedure SetTreeNodes(Value: TTreeNodes);
    procedure SetTopItem(Value: TTreeNode);
    procedure UpdateAllTops;
    procedure UpdateBottomItem;
    procedure UpdateExpandSignSize;
    procedure UpdateMaxLvl;
    procedure UpdateMaxRight;
    procedure UpdateTopItem;
    procedure UpdateScrollbars;
    procedure InternalSelectionChanged;
  protected
    FChangeTimer: TTimer;
    FEditor: TEdit;
    class procedure WSRegisterClass; override;
    class function GetControlClassDefaultSize: TSize; override;
    procedure Added(Node: TTreeNode); virtual;
    procedure EditorEditingDone(Sender: TObject); virtual;
    procedure EditorKeyDown(Sender: TObject; var Key : Word; Shift : TShiftState); virtual;
    procedure BeginAutoDrag; override;
    procedure BeginEditing(ANode: TTreeNode);
    function DoDragMsg(ADragMessage: TDragMessage; APosition: TPoint; ADragObject: TDragObject; ATarget: TControl; ADocking: Boolean): LRESULT; override;
    function CanChange(Node: TTreeNode): Boolean; virtual;
    function CanCollapse(Node: TTreeNode): Boolean; virtual;
    function CanEdit(Node: TTreeNode): Boolean; virtual;
    function CanExpand(Node: TTreeNode): Boolean; virtual;
    function CreateNode: TTreeNode; virtual;
    function CustomDraw(const ARect: TRect;
      Stage: TCustomDrawStage): Boolean; virtual;
    function CustomDrawItem(Node: TTreeNode; State: TCustomDrawState;
      Stage: TCustomDrawStage; var PaintImages: Boolean): Boolean; virtual;
    function GetDragImages: TDragImageList; override;
    function GetMaxLvl: integer;
    function GetMaxScrollLeft: integer;
    function GetMaxScrollTop: integer;
    function GetNodeAtY(Y: Integer): TTreeNode;
    function GetNodeDrawAreaHeight: integer;
    function GetNodeDrawAreaWidth: integer;
    function IsCustomDrawn(Target: TCustomDrawTarget;
      Stage: TCustomDrawStage): Boolean;
    function IsNodeVisible(ANode: TTreeNode): Boolean;
    function IsNodeHeightFullVisible(ANode: TTreeNode): Boolean;
    function IsInsertMarkVisible: boolean; virtual;
    procedure Change(Node: TTreeNode); virtual;
    procedure Collapse(Node: TTreeNode); virtual;
    procedure CreateWnd; override;
    procedure Delete(Node: TTreeNode); virtual;
    procedure DestroyWnd; override;
    procedure DoEndDrag(Target: TObject; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
                          MousePos: TPoint): Boolean; override;
    procedure DoPaint; virtual;
    procedure DoPaintNode(Node: TTreeNode); virtual;
    procedure DoStartDrag(var DragObject: TDragObject); override;
    procedure DragOver(Source: TObject; X,Y: Integer; State: TDragState;
                       var Accept: Boolean); override;
    procedure EndEditing(Cancel: boolean = false);
    procedure EnsureNodeIsVisible(ANode: TTreeNode);
    procedure Expand(Node: TTreeNode); virtual;
    procedure GetImageIndex(Node: TTreeNode); virtual;
    procedure GetSelectedIndex(Node: TTreeNode); virtual;
    procedure InitializeWnd; override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure SetDragMode(Value: TDragMode); override;
    procedure SetOptions(NewOptions: TTreeViewOptions); virtual;
    procedure UpdateDefaultItemHeight; virtual;
    procedure WndProc(var Message: TLMessage); override;
    procedure UpdateInsertMark(X,Y: integer); virtual;
    procedure DoSelectionChanged; virtual;
    procedure WMHScroll(var Msg: TLMScroll); message LM_HSCROLL;
    procedure WMVScroll(var Msg: TLMScroll); message LM_VSCROLL;
    procedure WMLButtonDown(var AMessage: TLMLButtonDown); message LM_LBUTTONDOWN;
    procedure WMNotify(var AMessage: TLMNotify); message LM_NOTIFY;
    procedure WMSetFocus(var Message: TLMSetFocus); message LM_SETFOCUS;
    procedure WMKillFocus(var Message: TLMKillFocus); message LM_KILLFOCUS;
    procedure Resize; override;
  public
    // Accessibility
    function GetSelectedChildAccessibleObject: TLazAccessibleObject; override;
    function GetChildAccessibleObjectAtPos(APos: TPoint): TLazAccessibleObject; override;
    // This property is provided for the case when a tree view contains a huge amount of items,
    // lets say 10.000+. In this case accessibility might slow the tree down, so turning
    // it off might make things faster
    property AccessibilityOn: Boolean read FAccessibilityOn write FAccessibilityOn default True;
  protected
    property AutoExpand: Boolean read GetAutoExpand write SetAutoExpand default False;
    property BorderStyle default bsSingle;
    property HideSelection: Boolean
      read GetHideSelection write SetHideSelection default True;
    property HotTrack: Boolean read GetHotTrack write SetHotTrack default False;
    property Images: TCustomImageList read FImages write SetImages;
    property Indent: Integer read FIndent write SetIndent default 15;
    property MultiSelect: Boolean read GetMultiSelect write SetMultiSelect default False;
    property OnAddition: TTVExpandedEvent read FOnAddition write FOnAddition;
    property OnAdvancedCustomDraw: TTVAdvancedCustomDrawEvent
      read FOnAdvancedCustomDraw write FOnAdvancedCustomDraw;
    property OnAdvancedCustomDrawItem: TTVAdvancedCustomDrawItemEvent
      read FOnAdvancedCustomDrawItem write FOnAdvancedCustomDrawItem;
    property OnChange: TTVChangedEvent read FOnChange write FOnChange;
    property OnChanging: TTVChangingEvent read FOnChanging write FOnChanging;
    property OnCollapsed: TTVExpandedEvent read FOnCollapsed write FOnCollapsed;
    property OnCollapsing: TTVCollapsingEvent read FOnCollapsing write FOnCollapsing;
    property OnCompare: TTVCompareEvent read FOnCompare write FOnCompare;
    property OnCreateNodeClass: TTVCreateNodeClassEvent read FOnCreateNodeClass write FOnCreateNodeClass;
    property OnCustomCreateItem: TTVCustomCreateNodeEvent read FOnCustomCreateItem write FOnCustomCreateItem;
    property OnCustomDraw: TTVCustomDrawEvent read FOnCustomDraw write FOnCustomDraw;
    property OnCustomDrawItem: TTVCustomDrawItemEvent
      read FOnCustomDrawItem write FOnCustomDrawItem;
    property OnDeletion: TTVExpandedEvent read FOnDeletion write FOnDeletion;
    property OnEdited: TTVEditedEvent read FOnEdited write FOnEdited;
    property OnEditing: TTVEditingEvent read FOnEditing write FOnEditing;
    property OnEditingEnd: TTVEditingEndEvent read FOnEditingEnd write FOnEditingEnd;
    property OnExpanded: TTVExpandedEvent read FOnExpanded write FOnExpanded;
    property OnExpanding: TTVExpandingEvent read FOnExpanding write FOnExpanding;
    property OnGetImageIndex: TTVExpandedEvent
      read FOnGetImageIndex write FOnGetImageIndex;
    property OnGetSelectedIndex: TTVExpandedEvent
      read FOnGetSelectedIndex write FOnGetSelectedIndex;
    property OnSelectionChanged: TNotifyEvent
      read FOnSelectionChanged write FOnSelectionChanged;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property RightClickSelect: Boolean
      read GetRightClickSelect write SetRightClickSelect default False;
    property RowSelect: Boolean read GetRowSelect write SetRowSelect default False;
    property ScrolledLeft: integer read FScrolledLeft write SetScrolledLeft;
    property ScrolledTop: integer read FScrolledTop write SetScrolledTop;
    property ShowButtons: Boolean read GetShowButtons write SetShowButton default True;
    property ShowLines: Boolean read GetShowLines write SetShowLines default True;
    property ShowRoot: Boolean read GetShowRoot write SetShowRoot default True;
    property ShowSeparators: Boolean read GetShowSeparators write SetShowSeparators default True;
    property SortType: TSortType read FSortType write SetSortType default stNone;
    property StateImages: TCustomImageList read FStateImages write SetStateImages;
    property ToolTips: Boolean read GetToolTips write SetToolTips default True;
  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    function AlphaSort: Boolean;
    procedure ConsistencyCheck;
    function CustomSort(SortProc: TTreeNodeCompare): Boolean;
    function DefaultTreeViewSort(Node1, Node2: TTreeNode): Integer;
    procedure EraseBackground(DC: HDC); override;
    function GetHitTestInfoAt(X, Y: Integer): THitTests;
    function GetNodeAt(X, Y: Integer): TTreeNode;
    procedure GetInsertMarkAt(X, Y: Integer; out AnInsertMarkNode: TTreeNode;
                              out AnInsertMarkType: TTreeViewInsertMarkType);
    procedure SetInsertMark(AnInsertMarkNode: TTreeNode;
                            AnInsertMarkType: TTreeViewInsertMarkType);
    procedure SetInsertMarkAt(X,Y: integer); virtual;
    procedure Invalidate; override;
    function IsEditing: Boolean;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure FullCollapse;
    procedure FullExpand;
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToFile(const FileName: string);
    procedure SaveToStream(Stream: TStream);
    procedure WriteDebugReport(const Prefix: string; AllNodes: boolean);
    procedure LockSelectionChangeEvent;
    procedure UnlockSelectionChangeEvent;
    function GetFirstMultiSelected: TTreeNode;
    function GetLastMultiSelected: TTreeNode;
    function SelectionVisible: boolean;
    procedure MakeSelectionVisible;
    procedure ClearInvisibleSelection;
    function StoreCurrentSelection: TStringList;
    procedure ApplyStoredSelection(ASelection: TStringList; FreeList: boolean = True);
    procedure MoveToNextNode;
    procedure MoveToPrevNode;
  public
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor default clWindow;
    property BorderWidth default 0;
    property BottomItem: TTreeNode read GetBottomItem write SetBottomItem;
    property DefaultItemHeight: integer read FDefItemHeight write SetDefaultItemHeight default 20;
    property DropTarget: TTreeNode read GetDropTarget write SetDropTarget;
    property ExpandSignType: TTreeViewExpandSignType
      read FExpandSignType write SetExpandSignType default tvestTheme;
    property InsertMarkNode: TTreeNode read FInsertMarkNode write SetInsertMarkNode;
    property InsertMarkType: TTreeViewInsertMarkType read FInsertMarkType write SetInsertMarkType;
    property Items: TTreeNodes read FTreeNodes write SetTreeNodes;
    property KeepCollapsedNodes: boolean read GetKeepCollapsedNodes write SetKeepCollapsedNodes;
    property MultiSelectStyle: TMultiSelectStyle read FMultiSelectStyle
      write SetMultiSelectStyle default DefaultMultiSelectStyle;
    property Options: TTreeViewOptions read FOptions write SetOptions default DefaultTreeViewOptions;
    property ScrollBars: TScrollStyle read FScrollBars write SetScrollBars default ssBoth;
    property Selected: TTreeNode read GetSelection write SetSelection;
    property SelectionColor: TColor read FSelectedColor write SetSelectedColor default clHighlight;
    property SelectionCount: Cardinal read GetSelectionCount;
    property Selections[AIndex: Integer]: TTreeNode read GetSelections;
    property SeparatorColor: TColor read fSeparatorColor write SetSeparatorColor default clGray;
    property TopItem: TTreeNode read GetTopItem write SetTopItem;
    property TreeLineColor: TColor read FTreeLineColor write FTreeLineColor default clWindowFrame;
    property TreeLinePenStyle: TPenStyle read FTreeLinePenStyle write FTreeLinePenStyle default psPattern;
    property ExpandSignColor: TColor read FExpandSignColor write FExpandSignColor default clWindowFrame;
  published
    property TabStop default true;
  end;


  { TTreeView }

  TTreeView = class(TCustomTreeView)
  published
    property Align;
    property Anchors;
    property AutoExpand;
    property BorderSpacing;
    //property BiDiMode;
    property BackgroundColor;
    property BorderStyle;
    property BorderWidth;
    property Color;
    property Constraints;
    property DefaultItemHeight;
    property DragKind;
    property DragCursor;
    property DragMode;
    property Enabled;
    property ExpandSignType;
    property Font;
    property HideSelection;
    property HotTrack;
    property Images;
    property Indent;
    property MultiSelect;
    property MultiSelectStyle;
    //property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property RightClickSelect;
    property RowSelect;
    property ScrollBars;
    property SelectionColor;
    property ShowButtons;
    property ShowHint;
    property ShowLines;
    property ShowRoot;
    property SortType;
    property StateImages;
    property TabOrder;
    property TabStop default True;
    property Tag;
    property ToolTips;
    property Visible;
    property OnAddition;
    property OnAdvancedCustomDraw;
    property OnAdvancedCustomDrawItem;
    property OnChange;
    property OnChanging;
    property OnClick;
    property OnCollapsed;
    property OnCollapsing;
    property OnCompare;
    property OnContextPopup;
    property OnCreateNodeClass;
    property OnCustomCreateItem;
    property OnCustomDraw;
    property OnCustomDrawItem;
    property OnDblClick;
    property OnDeletion;
    property OnDragDrop;
    property OnDragOver;
    property OnEdited;
    property OnEditing;
    property OnEditingEnd;
    //property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnExpanded;
    property OnExpanding;
    property OnGetImageIndex;
    property OnGetSelectedIndex;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnSelectionChanged;
    property OnShowHint;
    //property OnStartDock;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property Options;
    property Items;
    property TreeLineColor;
    property TreeLinePenStyle;
    property ExpandSignColor;
  end;


  { TTreeNodeExpandedState }
  { class to store and restore the expanded state of a TTreeView
    The nodes are identified by their Text property.

    Usage example:
      // save old expanded state
      OldExpanded:=TTreeNodeExpandedState.Create(ATreeView);
      ... change a lot of nodes ...
      // restore old expanded state
      OldExpanded.Apply(ATreeView);
      OldExpanded.Free;
   }

  TTreeNodeExpandedState = class
    NodeText: string;
    Children: TAvgLvlTree;
    constructor Create(FirstTreeNode: TTreeNode);
    constructor Create(TreeView: TCustomTreeView);
    destructor Destroy; override;
    procedure Clear;
    procedure CreateChildNodes(FirstTreeNode: TTreeNode);
    procedure Apply(FirstTreeNode: TTreeNode; CollapseToo: boolean = true);
    procedure Apply(TreeView: TCustomTreeView; CollapseToo: boolean = true);
  end;



  TCustomHeaderControl = class;


  { THeaderSection }
  THeaderSectionState =
  (
    hsNormal,
    hsHot,
    hsPressed
  );
  THeaderSection = class(TCollectionItem)
  private
    FAlignment: TAlignment;
    FImageIndex: TImageIndex;
    FMinWidth: Integer;
    FMaxWidth: Integer;
    FState: THeaderSectionState;
    FText: TCaption;
    FVisible: Boolean;
    FWidth: Integer;
    FOriginalIndex: Integer;
    function GetWidth: Integer;
    function GetLeft: Integer;
    function GetRight: Integer;
    procedure SetAlignment(const AValue: TAlignment);
    procedure SetMaxWidth(AValue: Integer);
    procedure SetMinWidth(AValue: Integer);
    procedure SetState(const AValue: THeaderSectionState);
    procedure SetText(const Value: TCaption);
    procedure SetVisible(const AValue: Boolean);
    procedure SetWidth(Value: Integer);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure CheckConstraints;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    property Left: Integer read GetLeft;
    property Right: Integer read GetRight;
    property State: THeaderSectionState read FState write SetState;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property MaxWidth: Integer read FMaxWidth write SetMaxWidth default 10000;
    property MinWidth: Integer read FMinWidth write SetMinWidth default 0;
    property Text: TCaption read FText write SetText;
    property Width: Integer read GetWidth write SetWidth;
    property Visible: Boolean read FVisible write SetVisible;
    //index which doesn't change when the user reorders the sections
    property OriginalIndex: Integer read FOriginalIndex;
  end;
  
  THeaderSectionClass = class of THeaderSection;


  { THeaderSections }
  
  THeaderSections = class(TCollection)
  private
    FHeaderControl: TCustomHeaderControl;
    function GetItem(Index: Integer): THeaderSection;
    procedure SetItem(Index: Integer; Value: THeaderSection);
  protected
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(HeaderControl: TCustomHeaderControl);
    function Add: THeaderSection;
    function AddItem(Item: THeaderSection; Index: Integer): THeaderSection;
    function Insert(Index: Integer): THeaderSection;
    procedure Delete(Index: Integer);
    property Items[Index: Integer]: THeaderSection read GetItem write SetItem; default;
  end;

  TSectionTrackState = (tsTrackBegin, tsTrackMove, tsTrackEnd);
    TCustomSectionTrackEvent = procedure(HeaderControl: TCustomHeaderControl; Section: THeaderSection; Width: Integer; State: TSectionTrackState) of object;
  TSectionDragEvent = procedure (Sender: TObject; FromSection, ToSection: THeaderSection;
    var AllowDrag: Boolean) of object;
  TCustomSectionNotifyEvent = procedure(HeaderControl: TCustomHeaderControl;
    Section: THeaderSection) of object;
  TCustomHCCreateSectionClassEvent = procedure(Sender: TCustomHeaderControl;
    var SectionClass: THeaderSectionClass) of object;
    
    
  { TCustomHeaderControl }
  
  TCustomHeaderControl = class(TCustomControl)
  private
    FDragReorder: boolean;
    FSections: THeaderSections;
    FImages: TCustomImageList;
    FPaintRect: TRect;
    FDown: Boolean;
    FDownPoint: TPoint;
    FTracking, FDragging: Boolean;
    FEndDragSectionIndex: longint;
    FSelectedSection: longint;
    FMouseInControl: Boolean;
    
    FOnSectionClick: TCustomSectionNotifyEvent;
    FOnSectionResize: TCustomSectionNotifyEvent;
    FOnSectionTrack: TCustomSectionTrackEvent;
    FOnSectionSeparatorDblClick: TCustomSectionNotifyEvent;
    FOnSectionDrag: TSectionDragEvent;
    FOnSectionEndDrag: TNotifyEvent;
    FOnCreateSectionClass: TCustomHCCreateSectionClassEvent;
    function GetSectionFromOriginalIndex(OriginalIndex: Integer): THeaderSection;
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetSections(const AValue: THeaderSections);
    procedure UpdateSection(Index: Integer);
    procedure UpdateSections;
  protected
    function CreateSection: THeaderSection; virtual;
    function CreateSections: THeaderSections; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SectionClick(Section: THeaderSection); virtual;
    procedure SectionResize(Section: THeaderSection); virtual;
    procedure SectionTrack(Section: THeaderSection; State: TSectionTrackState); virtual;
    procedure SectionSeparatorDblClick(Section: THeaderSection); virtual;
    procedure SectionEndDrag; virtual;
    function SectionDrag(FromSection, ToSection: THeaderSection): Boolean; virtual;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure UpdateState;
    class function GetControlClassDefaultSize: TSize; override;
  public
    property SectionFromOriginalIndex[OriginalIndex: Integer]: THeaderSection read GetSectionFromOriginalIndex;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure Click; override;
    procedure DblClick; override;
    function GetSectionAt(P: TPoint): Integer;
    procedure Paint; override;
    procedure PaintSection(Index: Integer); virtual;
  published
    property DragReorder: boolean read FDragReorder write FDragReorder;
    property Images: TCustomImageList read FImages write SetImages;
    property Sections: THeaderSections read FSections write SetSections;

    property OnSectionDrag: TSectionDragEvent read FOnSectionDrag
      write FOnSectionDrag;
    property OnSectionEndDrag: TNotifyEvent read FOnSectionEndDrag write FOnSectionEndDrag;
    property OnSectionClick: TCustomSectionNotifyEvent read FOnSectionClick
      write FOnSectionClick;
    property OnSectionResize: TCustomSectionNotifyEvent read FOnSectionResize
      write FOnSectionResize;
    property OnSectionTrack: TCustomSectionTrackEvent read FOnSectionTrack
      write FOnSectionTrack;
    property OnSectionSeparatorDblClick: TCustomSectionNotifyEvent read FOnSectionSeparatorDblClick
      write FOnSectionSeparatorDblClick;
    property OnCreateSectionClass: TCustomHCCreateSectionClassEvent read FOnCreateSectionClass
      write FOnCreateSectionClass;
  end;
  
  
  { THeaderControl }

  THeaderControl = class(TCustomHeaderControl)
  published
    property Align;
    property Anchors;
    property BiDiMode;
    property BorderWidth;
    property BorderSpacing;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Images;
    property Constraints;
    property Sections;
    property ShowHint;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property Visible;
    // events
    property OnContextPopup;
    property OnCreateSectionClass;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnSectionClick;
    property OnSectionResize;
    property OnSectionTrack;
  end;

const
  TCN_First = 0-550;
  TCN_SELCHANGE = TCN_FIRST - 1;
  TCN_SELCHANGING = TCN_FIRST - 2;

function CompareExpandedNodes(Data1, Data2: Pointer): integer;
function CompareTextWithExpandedNode(Key, Data: Pointer): integer;

procedure Register;

{ WidgetSetRegistration }

procedure RegisterCustomPage;
procedure RegisterCustomTabControl;

implementation

// !!! Avoid unit circles. Only add units if really needed.
uses
  InterfaceBase, WSComCtrls, WSFactory;

const
  ScrollBarWidth = 0;
  AllPanelsParts = [Low(TPanelPart)..High(TPanelPart)];

{$I custompage.inc}
{$I customnotebook.inc}
{$I statusbar.inc}
{$I statuspanel.inc}
{$I statuspanels.inc}
{$I tabsheet.inc}
{$I pagecontrol.inc}
{$I tabcontrol.inc}
{$I listcolumns.inc}
{$I listcolumn.inc}
{$I listitem.inc}
{$I listitems.inc}
{$I customlistview.inc}
{$I progressbar.inc}
{$I customupdown.inc}
{$I toolbutton.inc}
{$I toolbar.inc}
{$I trackbar.inc}
{$I treeview.inc}
{$I headercontrol.inc}

{ TTreeNodesEnumerator }

function TTreeNodesEnumerator.GetCurrent: TTreeNode;
begin
  Result := FNodes[FPosition];
end;

constructor TTreeNodesEnumerator.Create(ANodes: TTreeNodes);
begin
  inherited Create;
  FNodes := ANodes;
  FPosition := -1;
end;

function TTreeNodesEnumerator.MoveNext: Boolean;
begin
  inc(FPosition);
  Result := FPosition < FNodes.Count;
end;

{ TListItemsEnumerator }

function TListItemsEnumerator.GetCurrent: TListItem;
begin
  Result := FItems[FPosition];
end;

constructor TListItemsEnumerator.Create(AItems: TListItems);
begin
  inherited Create;
  FItems := AItems;
  FPosition := -1;
end;

function TListItemsEnumerator.MoveNext: Boolean;
begin
  inc(FPosition);
  Result := FPosition < FItems.Count;
end;

{ TToolBarEnumerator }

function TToolBarEnumerator.GetCurrent: TToolButton;
begin
  Result := FToolBar.Buttons[FPosition];
end;

constructor TToolBarEnumerator.Create(AToolBar: TToolBar);
begin
  inherited Create;
  FToolBar := AToolBar;
  FPosition := -1;
end;

function TToolBarEnumerator.MoveNext: Boolean;
begin
  inc(FPosition);
  Result := FPosition < FToolBar.ButtonCount;
end;

procedure Register;
begin
  RegisterComponents('Common Controls',[TTrackbar,TProgressBar,TTreeView,
    TListView,TStatusBar,TToolBar,TUpDown,TPageControl,TTabControl,
    THeaderControl]);
  RegisterNoIcon([TToolButton,TTabSheet]);
end;

{ WidgetSetRegistration }

procedure RegisterCustomPage;
const
  Done: Boolean = False;
begin
  if Done then exit;
  WSRegisterCustomPage;
//  if not WSRegisterCustomPage then
//    RegisterWSComponent(TCustomPage, TWSCustomPage);
  Done := True;
end;

procedure RegisterCustomTabControl;
const
  Done: Boolean = False;
begin
  if Done then exit;
  if not WSRegisterCustomNotebook then
    RegisterWSComponent(TCustomTabControl, TWSCustomTabControl);
  Done := True;
end;

end.