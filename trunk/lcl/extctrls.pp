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

{
@abstract(Just a try to provide the same objects as the Delphi extctrls unit)
@author(TCustomNotebook, TNotebook - Curtis White <cwhite@aracnet.com>)
@author(TTimer - Stefan Hille (stoppok@osibisa.ms.sub.org))
@created(26 Jul 1999)
@lastmod(28 Jul 1999)

Extctrls contains only few class defintions at the moment and is very
incomplete.
}

unit ExtCtrls;

{$mode objfpc}
{$H+}

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}

uses
  SysUtils, Classes, LCLStrConsts, LCLProc, Controls, Forms, StdCtrls,
  vclGlobals, lMessages, GraphType, Graphics, LCLIntf, CustomTimer;

type
  { workaround problem with fcl }
  TAbstractReader = TReader;
  
  { TTabPosition - Move to TTabbedNotebook when it is created }
  TTabPosition = (tpTop, tpBottom, tpLeft, tpRight);


  { TPage }

  TPageFlag = (pfAdded,pfRemoving);
  TPageFlags = set of TPageFlag;

  TPage = class(TWinControl)
  private
    FFlags: TPageFlags;
    FImageIndex: integer;
    procedure SetImageIndex(const AValue: integer);
  protected
    procedure WMPaint(var Msg: TLMPaint); message LM_PAINT;
    procedure SetParent(AParent : TWinControl); override;
    property Flags: TPageFlags read FFlags write FFlags;
    procedure CMHitTest(var Message: TLMNCHITTEST); message CM_HITTEST;
  public
    constructor Create(TheOwner: TComponent); override;
    procedure AdjustClientRect(var ARect: TRect); override;
    function PageIndex: integer;
    function CanTab: boolean; override;
  published
    property Caption;
    property ClientWidth;
    property ClientHeight;
    property ImageIndex: integer read FImageIndex write SetImageIndex default -1;
    property Left stored False;
    property Top stored False;
    property Width stored False;
    property Height stored False;
    property OnResize;
    property TabOrder stored False;
    property Visible;
  end;

  TCustomNotebook = class;


  { TNBPages }

  TNBPages = class(TStrings)
  private
    fPageList: TList;
    fNotebook: TCustomNotebook;
  protected
    function Get(Index: Integer): String; override;
    function GetCount: Integer; override;
    function GetObject(Index: Integer): TObject; override;
    procedure Put(Index: Integer; const S: String); override;
    procedure RemovePage(Index: integer);
  public
    constructor Create(thePageList: TList; theNotebook: TCustomNotebook);
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: String); override;
    procedure InsertPage(Index:integer; APage: TPage);

    procedure Move(CurIndex, NewIndex: Integer); override;
  end;


  { TCustomNotebook }

  TNoteBookOption = (nboShowCloseButtons, nboMultiLine);
  TNoteBookOptions = set of TNoteBookOption;
  
  TCustomNotebook = class(TCustomControl)
  private
    fAccess: TStrings; // TNBPages
    FImages: TImageList;
    FOnCloseTabClicked: TNotifyEvent;
    FOptions: TNoteBookOptions;
    fPageIndex: Integer;
    fPageList: TList;  // List of TPage
    //fMultiLine: boolean;
    fOnPageChanged: TNotifyEvent;
    fShowTabs: Boolean;
    fTabPosition: TTabPosition;
    fAddingPages: boolean;

    Procedure CNNotify(var Message : TLMNotify); message CN_NOTIFY;
    procedure DoSendPageIndex;
    procedure DoSendShowTabs;
    procedure DoSendTabPosition;
    function GetActivePage: String;
    function GetActivePageComponent: TPage;
    function GetPage(aIndex: Integer): TPage;
    function GetPageCount : integer;
    function GetPageIndex: Integer;
    function IsStoredActivePage: boolean;
    //function InternalSetMultiLine(Value: boolean): boolean;
    procedure SetActivePage(const Value: String);
    procedure SetActivePageComponent(const AValue: TPage);
    procedure SetImages(const AValue: TImageList);
    procedure SetOptions(const AValue: TNoteBookOptions);
    //procedure SetMultiLine(Value: boolean);
    procedure SetPageIndex(Value: Integer);
    procedure SetPages(Value: TStrings);
    procedure SetShowTabs(AValue: Boolean);
    procedure SetTabPosition(tabPos: TTabPosition);
    procedure UpdateAllDesignerFlags;
    procedure UpdateDesignerFlags(APageIndex: integer);
  protected
    procedure CreateParams(var Params: TCreateParams);override;
    procedure CreateWnd; override;
    procedure DoCreateWnd;
    procedure Change; virtual;
    procedure Loaded; override;
    procedure ReadState(Reader: TAbstractReader); override;
    procedure ShowControl(APage: TControl); override;
    procedure UpdateTabProperties; virtual;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function TabIndexAtClientPos(ClientPos: TPoint): integer;
    function CanTab: boolean; override;
  public
    property ActivePage: String read GetActivePage write SetActivePage
                                stored IsStoredActivePage;
    property ActivePageComponent: TPage read GetActivePageComponent
                                        write SetActivePageComponent;
    //property MultiLine: boolean read fMultiLine write SetMultiLine default false;
    property Page[Index: Integer]: TPage read GetPage;
    property PageCount : integer read GetPageCount;
    property PageIndex: Integer read GetPageIndex write SetPageIndex default -1;
    property PageList: TList read fPageList;
    property Pages: TStrings read fAccess write SetPages;
    property OnPageChanged: TNotifyEvent read fOnPageChanged write fOnPageChanged;
    property ShowTabs: Boolean read fShowTabs write SetShowTabs default True;
    property TabPosition: TTabPosition read fTabPosition write SetTabPosition;
    procedure DoCloseTabClicked(APage: TPage); virtual;
    property Images: TImageList read FImages write SetImages;
    property Name;
    property OnCloseTabClicked: TNotifyEvent
      read FOnCloseTabClicked write FOnCloseTabClicked;
    property Options: TNoteBookOptions read FOptions write SetOptions;
  end;


  { TNotebook }

  TNotebook = class(TCustomNotebook)
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ActivePage;
    property Align;
    property Anchors;
    property Images;
    property OnCloseTabClicked;
    //property MultiLine;
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
    property AutoEndEvent: TIdleTimerAutoEvent
      read FAutoEndEvent write SetAutoEndEvent default itaOnIdle;
    property AutoStartEvent: TIdleTimerAutoEvent
      read FAutoStartEvent write SetAutoStartEvent default itaOnUserInput;
  end;
  

  { TShape }
  
  TShapeType = (stRectangle, stSquare, stRoundRect, stRoundSquare,
    stEllipse, stCircle);

  TShape = class(TGraphicControl)
  private
    FPen: TPen;
    FBrush: TBrush;
    FShape: TShapeType;
    procedure SetBrush(Value: TBrush);
    procedure SetPen(Value: TPen);
    procedure SetShape(Value: TShapeType);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Paint; override;
  published
    procedure StyleChanged(Sender: TObject);
    property Align;
    property Anchors;
    property Brush: TBrush read FBrush write SetBrush;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Constraints;
    property ParentShowHint;
    property Pen: TPen read FPen write SetPen;
    property Shape: TShapeType read FShape write SetShape;
    property ShowHint;
    property Visible;
//    property OnDragDrop;
//    property OnDragOver;
//    property OnEndDock;
//    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
//    property OnStartDock;
//    property OnStartDrag;
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
    property Color;
    property Constraints;
//    property DragCursor;
//    property DragKind;
//    property DragMode;
//    property Enabled;
    property Font;
    property Hint;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnDblClick;
//    property OnDragDrop;
//    property OnDragOver;
//    property OnEndDock;
//    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
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
  public
    Property Align;
    property AutoSize;
    property Center : Boolean read FCenter write SetCenter;
    property Constraints;
    property Picture : TPicture read FPicture write SetPicture;
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
    property AutoSize;
    property Center;
    property Constraints;
    property Picture;
    property Visible;
    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property Stretch;
    property Transparent;
    property Proportional;
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
    procedure Invalidate; override;
  published
    property Align;
    property Anchors;
    property Constraints;
    property Height;
    property Left;
    property Name;
    property Shape:TBevelShape Read GetShape Write SetShape Default bsBox;
    property Top;
    property Style:TBevelStyle Read GetStyle Write SetStyle Default bsLowered;
    property Visible;
    property Width;
  end;


  { TCustomRadioGroup }

  TCustomRadioGroup = class(TCustomGroupBox)
  private
    FButtonList : TList; // list of TRadioButton
    FHiddenButton: TRadioButton;
    FCreatingWnd: boolean;
    FItems      : TStrings;
    FItemIndex  : integer;
    FColumns    : integer;
    FReading    : boolean;
    FOnClick    : TNotifyEvent;
    procedure ItemsChanged(Sender: TObject);
    procedure Clicked(Sender: TObject); virtual;
    procedure DoPositionButtons;
  protected
    procedure UpdateRadioButtonStates; virtual;
    procedure ReadState(Reader: TReader); override;
    procedure SetItem(Value: TStrings);
    procedure SetColumns(Value: integer);
    procedure SetItemIndex(Value: integer);
    function GetItemIndex: integer;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
  protected
    property ItemIndex: integer read GetItemIndex write SetItemIndex default -1;
    property Items: TStrings read FItems write SetItem;
    property Columns: integer read FColumns write SetColumns default 1;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  public
    constructor Create (AOwner : TComponent); override;
    destructor Destroy; override;
    function CanModify: boolean; virtual;
    procedure CreateWnd; override;
    function Rows: integer;
  end;


  { TRadioGroup }

  TRadioGroup = class(TCustomRadioGroup)
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property Caption;
    property Enabled;
    property ItemIndex;
    property Items;
    property Columns;
    property Visible;
    property OnClick;
    property OnResize;
    property OnChangeBounds;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseuP;
  end;
  
  
  { TCustomCheckGroup }
  
  TCheckGroupClicked = procedure(Sender: TObject; Index: integer) of object;
  
  TCustomCheckGroup = class(TCustomGroupBox)
  private
    FButtonList : TList; // list of TCheckBox
    FCreatingWnd: boolean;
    FItems      : TStrings;
    FColumns    : integer;
    FOnItemClick: TCheckGroupClicked;
    function GetChecked(Index: integer): boolean;
    function GetCheckEnabled(Index: integer): boolean;
    procedure Clicked(Sender: TObject);
    procedure DoClick(Index: integer);
    procedure DoPositionButtons;
    procedure ItemsChanged (Sender : TObject);
    procedure SetChecked(Index: integer; const AValue: boolean);
    procedure SetCheckEnabled(Index: integer; const AValue: boolean);
    procedure UpdateItems;
  protected
    procedure SetItems(Value: TStrings);
    procedure SetColumns(Value: integer);
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
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
    property OnItemClick: TCheckGroupClicked read FOnItemClick write FOnItemClick;
  end;


  { TCheckGroup }

  TCheckGroup = class(TCustomCheckGroup)
  public
  published
    property Align;
    property Caption;
    property Enabled;
    property Items;
    property Columns;
    property Visible;
    property OnItemClick;
    property OnResize;
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
    property CharCase;
    property Color;
    property Constraints;
    //property EditLabel; sub components no implemented in FCL
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
  TBorderWidth = 0..Maxint;

  TCustomPanel = class(TCustomControl)
  private
    FBevelInner, FBevelOuter : TPanelBevel;
    FBevelWidth : TBevelWidth;
    FBorderWidth : TBorderWidth;
    FBorderStyle : TControlBorderStyle;
    FAlignment : TAlignment;
    FCaption : TCaption;
    procedure SetAlignment(const Value : TAlignment);
    procedure SetBevelInner(const Value: TPanelBevel);
    procedure SetBevelOuter(const Value: TPanelBevel);
    procedure SetBevelWidth(const Value: TBevelWidth);
    procedure SetBorderWidth(const Value: TBorderWidth);
    procedure SetBorderStyle(const Value: TControlBorderStyle);
  protected
    procedure AdjustClientRect(var Rect: TRect); override;
    function GetText: TCaption; override;
    procedure SetText(const Value: TCaption); override;
    procedure Paint; override;
    function ParentColorIsStored: boolean;
  public
    constructor Create(TheOwner: TComponent); override;
    property Alignment: TAlignment read FAlignment write SetAlignment default taCenter;
    property BevelInner: TPanelBevel read FBevelInner write SetBevelInner default bvNone;
    property BevelOuter: TPanelBevel read FBevelOuter write SetBevelOuter default bvRaised;
    property BevelWidth: TBevelWidth read FBevelWidth write SetBevelWidth default 1;
    property BorderWidth: TBorderWidth read FBorderWidth write SetBorderWidth default 0;
    property BorderStyle: TControlBorderStyle read FBorderStyle write SetBorderStyle default bsNone;
    property Color default clBtnFace;
    property Caption read GetText write SetText;
    property ParentColor stored ParentColorIsStored;
  end;
  
  
  { TPanel }

  TPanel = class(TCustomPanel)
  published
    property Align default alNone;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property BorderWidth;
    property BorderStyle;
    property Caption;
    property ClientHeight;
    property ClientWidth;
    property Color default clBackground;
    property DragMode;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default False;
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
  
procedure Register;

implementation

uses Math;

procedure Register;
begin
  RegisterComponents('Standard',[TRadioGroup,TCheckGroup,TPanel]);
  RegisterComponents('Additional',[TImage,TShape,TBevel,TPaintBox,TNotebook,
                                   TLabeledEdit]);
  RegisterComponents('System',[TTimer,TIdleTimer]);
  RegisterNoIcon([TPage]);
end;

{$I page.inc}
{$I customnotebook.inc}
{$I notebook.inc}
{$I timer.inc}
{$I idletimer.inc}
{$I shape.inc}
{$I paintbox.inc}
{$I customcheckgroup.inc}
{$I customradiogroup.inc}
{$I boundlabel.inc}
{$I customlabelededit.inc}
{$I custompanel.inc}
{$I radiogroup.inc}
{$I bevel.inc}
{$I customimage.inc}

end.

 {
  $Log$
  Revision 1.76  2003/09/18 21:01:18  mattias
  started TDBImage

  Revision 1.75  2003/09/18 09:21:03  mattias
  renamed LCLLinux to LCLIntf

  Revision 1.74  2003/09/17 15:26:41  mattias
  fixed removing TPage

  Revision 1.73  2003/09/16 11:35:14  mattias
  started TDBCheckBox

  Revision 1.72  2003/09/15 22:02:02  mattias
  implemented TDBRadioGroup

  Revision 1.71  2003/09/04 11:10:18  mattias
  added csClickEvents to TImage

  Revision 1.70  2003/09/03 08:53:39  mattias
  implemented TImage.Proportional

  Revision 1.69  2003/08/26 14:33:40  mattias
  implemented component tree for OI

  Revision 1.68  2003/08/14 15:31:42  mattias
  started TTabSheet and TPageControl

  Revision 1.67  2003/07/10 15:17:43  mattias
  fixed reading empty stream and TCustomRadioGroup.ItemsChanged

  Revision 1.66  2002/08/19 15:15:23  mattias
  implemented TPairSplitter

  Revision 1.65  2003/06/19 22:38:21  mattias
  fixed update on changing package usage options

  Revision 1.64  2003/06/19 09:26:58  mattias
  fixed changing unitname during update

  Revision 1.63  2003/06/13 15:36:32  mattias
  fixed popupmenu on menueditor

  Revision 1.62  2003/06/13 14:38:01  mattias
  fixed using streamed clientwith/height for child anchors

  Revision 1.61  2003/06/13 10:09:04  mattias
  fixed Set/GetPixel

  Revision 1.60  2003/06/12 15:56:42  mattias
  published TNoteBook.Anchors and started context diff

  Revision 1.59  2003/06/10 17:23:34  mattias
  implemented tabstop

  Revision 1.58  2003/06/10 15:58:39  mattias
  started TLabeledEdit

  Revision 1.57  2003/04/22 13:27:10  mattias
  implemented installing components in component palette

  Revision 1.56  2003/04/04 16:35:24  mattias
  started package registration

  Revision 1.55  2003/03/31 20:25:19  mattias
  fixed scrollbars of TIpHtmlPanel

  Revision 1.54  2003/03/18 00:00:05  mattias
  added TCheckGroup.CheckEnabled

  Revision 1.53  2003/03/17 23:39:30  mattias
  added TCheckGroup

  Revision 1.52  2003/03/17 20:50:30  mattias
  fixed TRadioGroup.ItemIndex=-1

  Revision 1.51  2003/03/11 07:46:43  mattias
  more localization for gtk- and win32-interface and lcl

  Revision 1.50  2003/01/27 13:49:16  mattias
  reduced speedbutton invalidates, added TCanvas.Frame

  Revision 1.49  2003/01/21 23:07:14  mattias
  applied patch from Jesus for many grid improvements

  Revision 1.48  2003/01/04 20:55:55  mattias
  published TNoteBook.Align

  Revision 1.47  2002/12/27 18:18:05  mattias
  fixes for htmllite

  Revision 1.46  2002/11/18 17:06:29  mattias
  improved designer rubberband

  Revision 1.45  2002/11/09 15:02:06  lazarus
  MG: fixed LM_LVChangedItem, OnShowHint, small bugs

  Revision 1.44  2002/11/05 20:03:41  lazarus
  MG: implemented hints

  Revision 1.43  2002/11/04 11:48:48  lazarus
  MG: implemented TIdleTimer and fixed small bugs

  Revision 1.42  2002/10/31 04:27:58  lazarus
  AJ: added TShape

  Revision 1.41  2002/10/26 15:56:45  lazarus
  MG: fixed changing notebook pageindex at designtime

  Revision 1.40  2002/10/26 11:20:30  lazarus
  MG: broke some interfaces.pp circles

  Revision 1.39  2002/10/24 10:27:52  lazarus
  MG: broke extctrls.pp <-> forms.pp circle

  Revision 1.38  2002/10/24 08:56:30  lazarus
  MG: fixed TnoteBook AddPage and double creation of MeinMenu

  Revision 1.37  2002/10/20 22:31:08  lazarus
  AJ:switched TImage.Autosize to use DoAutoSize

  Revision 1.36  2002/10/20 21:54:03  lazarus
  MG: fixes for 1.1

  Revision 1.35  2002/10/16 13:06:42  lazarus
  MG: fixed TPage.Visible

  Revision 1.34  2002/10/15 16:01:36  lazarus
  MG: fixed timers

  Revision 1.33  2002/10/01 10:05:48  lazarus
  MG: changed PDeviceContext into class TDeviceContext

  Revision 1.32  2002/09/09 07:26:42  lazarus
  MG: started TCollectionPropertyEditor

  Revision 1.31  2002/09/05 12:11:42  lazarus
  MG: TNotebook is now streamable

  Revision 1.30  2002/09/05 10:12:06  lazarus

  New dialog for multiline caption of TCustomLabel.
  Prettified TStrings property editor.
  Memo now has automatic scrollbars (not fully working), WordWrap and Scrollbars property
  Removed saving of old combo text (it broke things and is not needed). Cleanups.

  Revision 1.29  2002/09/03 08:07:18  lazarus
  MG: image support, TScrollBox, and many other things from Andrew

  Revision 1.28  2002/09/02 19:10:28  lazarus
  MG: TNoteBook now starts with no Page and TPage has no auto names

  Revision 1.27  2002/08/28 11:41:53  lazarus
  MG: activated environment opts in debugger

  Revision 1.26  2002/07/27 15:38:01  lazarus
  MG: fixed search forward

  Revision 1.25  2002/06/08 17:16:02  lazarus
  MG: added close buttons and images to TNoteBook and close buttons to source editor

  Revision 1.24  2002/05/13 14:47:00  lazarus
  MG: fixed client rectangles, TRadioGroup, RecreateWnd

  Revision 1.23  2002/05/10 06:05:50  lazarus
  MG: changed license to LGPL

  Revision 1.22  2002/04/22 13:07:45  lazarus
  MG: fixed AdjustClientRect of TGroupBox

  Revision 1.21  2002/03/25 17:59:19  lazarus
  GTK Cleanup
  Shane

  Revision 1.20  2002/03/14 23:25:51  lazarus
  MG: fixed TBevel.Create and TListView.Destroy

  Revision 1.19  2002/03/13 22:48:16  lazarus
  Constraints implementation (first cut) and sizig - moving system rework to
  better match Delphi/Kylix way of doing things (the existing implementation
  worked by acident IMHO :-)

  Revision 1.18  2002/02/24 20:51:23  lazarus
  Improved TSpeedButton (Glyph, Spacing, Margin, drawing)
  Added PageCount to TNotebook
  Optimized component selection buttons a bit.

  Revision 1.17  2002/02/03 00:24:00  lazarus
  TPanel implemented.
  Basic graphic primitives split into GraphType package, so that we can
  reference it from interface (GTK, Win32) units.
  New Frame3d canvas method that uses native (themed) drawing (GTK only).
  New overloaded Canvas.TextRect method.
  LCLLinux and Graphics was split, so a bunch of files had to be modified.

  Revision 1.16  2002/01/01 15:50:13  lazarus
  MG: fixed initial component aligning

  Revision 1.15  2001/12/21 18:16:59  lazarus
  Added TImage class
  Shane

  Revision 1.14  2001/11/05 18:18:19  lazarus
  added popupmenu+arrows to notebooks, added target filename

  Revision 1.12  2001/06/26 21:44:32  lazarus
  MG: reduced paint messages

  Revision 1.11  2001/06/12 18:31:01  lazarus
  MG: small bugfixes

  Revision 1.10  2001/04/17 21:39:17  lazarus
  + added working OnClick support for TCustomRadiogroup, stoppok

  Revision 1.9  2001/04/06 22:28:09  lazarus
  * TTimer uses winapi interface now instead of sendmessage interface, stoppok

  Revision 1.8  2001/03/15 14:42:20  lazarus
  MG: customradiogroup is now streamable

  Revision 1.7  2001/01/12 18:27:31  lazarus
  Streaming additions by MAttias
  Shane

  Revision 1.6  2001/01/09 21:06:06  lazarus
  Started taking KeyDown messages in TDesigner
  Shane

  Revision 1.5  2001/01/09 18:23:20  lazarus
  Worked on moving controls.  It's just not working with the X and Y coord's I'm getting.
  Shane

  Revision 1.4  2001/01/05 18:56:23  lazarus
  Minor changes

  Revision 1.3  2001/01/04 20:33:53  lazarus
  Moved lresources.
  Moved CreateLFM to Main.pp
  Changed Form1 and TFOrm1 to MainIDE and TMainIDE
  Shane

  Revision 1.2  2000/12/29 15:04:07  lazarus
  Added more images to the resource.
  Shane

  Revision 1.1  2000/07/13 10:28:23  michael
  + Initial import

  Revision 1.25  2000/06/29 21:06:14  lazarus
  reintroduced TAbstractReader=Treader hack, stoppok

  Revision 1.24  2000/06/28 13:11:37  lazarus
  Fixed TNotebook so it gets page change events.  Shane

  Revision 1.23  2000/05/08 23:59:52  lazarus
  Updated my email address in the documentation to the current one. Also
  removed email references in comments that were not @author comments to
  fix problems with the documentation produced by pasdoc.           CAW

  Revision 1.22  2000/02/26 23:31:50  lazarus
  MWE:
    Fixed notebook crash on insert
    Fixed loadfont problem for win32 (tleast now a fontname is required)

  Revision 1.21  2000/01/10 19:09:18  lazarus
  MWE:
    Removed temp hack TAbstractReader=TReader. It is now defined

  Revision 1.20  2000/01/10 00:07:12  lazarus
  MWE:
    Added more scrollbar support for TWinControl
    Most signals for TWinContorl are jet connected to the wrong widget
      (now scrolling window, should be fixed)
    Added some cvs entries

  Revision 1.19  2000/01/07 21:14:13  lazarus
  Added code for getwindowlong and setwindowlong.
  Shane

  Revision 1.18  2000/01/06 01:10:36  lazarus
  Stoppok:
     - changed ReadState to match current definition in fcl
       (affects TPage & TCustomNotebook)
     - added callback FItems.OnChanging to TCustomRadiogroup

  Revision 1.17  2000/01/02 00:22:54  lazarus
  stoppok:
    - introduced TBevel
    - enhanced TCustomRadioGroup

  Revision 1.16  1999/12/31 02:20:57  lazarus
    Initial implementation of TCustomRadioGroup / TRadioGroup
      stoppok

  Revision 1.15  1999/11/01 01:28:29  lazarus
  MWE: Implemented HandleNeeded/CreateHandle/CreateWND
       Now controls are created on demand. A call to CreateComponent shouldn't
       be needed. It is now part of CreateWnd

  Revision 1.14  1999/10/22 21:01:50  lazarus

        Removed calls to InterfaceObjects except for controls.pp. Commented
        out any gtk depend lines of code.     MAH

  Revision 1.13  1999/10/19 19:16:51  lazarus
  renamed stdcontrols.pp stdctrls.pp
  Shane

  Revision 1.12  1999/10/04 23:36:25  lazarus
  Moved PageList and Page property to public to allow access to them.   CAW

  Revision 1.11  1999/09/30 21:59:01  lazarus
  MWE: Fixed TNoteBook problems
       Modifications: A few
       - Removed some debug messages
       + Added some others
       * changed fixed widged of TPage. Code is still broken.
       + TWinControls are also added to the Controls collection
       + Added TControl.Controls[] property

  Revision 1.10  1999/09/22 19:09:17  lazarus
  Added some trace info for the TNotebook problem.

  Revision 1.9  1999/09/21 23:46:54  lazarus
  *** empty log message ***

  Revision 1.8  1999/09/16 21:14:27  lazarus
    Some cleanups to the timer class. (moved some comments to timer.inc,
    added more comments and changed TTimer.Timer from function to procedure)
      Stoppok

  Revision 1.7  1999/09/13 03:27:10  lazarus
  Fixed a bug in the PageIndex property of TCustomNotebook where
  it was not tracking notebook pages if the user selected them
  with the mouse in a TTabbedNotebook.                               caw

  Revision 1.6  1999/08/26 23:36:02  peter
    + paintbox
    + generic keydefinitions and gtk conversion
    * gtk state -> shiftstate conversion

  Revision 1.5  1999/08/04 05:21:11  lazarus
  Created TCustomNotebook to allow both TNotebook and TTabbedNotebook to
  inherit from a common object. Made TNotebook work like Delphi TNotebook.

  Revision 1.3  1999/07/31 06:39:22  lazarus

       Modified the IntSendMessage3 to include a data variable. It isn't used
       yet but will help in merging the Message2 and Message3 features.

       Adjusted TColor routines to match Delphi color format

       Added a TGdkColorToTColor routine in gtkproc.inc

       Finished the TColorDialog added to comDialog example.        MAH

 }
