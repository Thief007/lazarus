{  $Id$  }
{
 /***************************************************************************
                               Controls.pp
                             -------------------
                             Component Library Controls
                   Initial Revision  : Sat Apr 10 22:49:32 CST 1999


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
unit Controls;

{$mode objfpc}{$H+}
{off $DEFINE BUFFERED_WMPAINT}

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}

{$IFOPT C-}
// Uncomment for local trace
//  {$C+}
//  {$DEFINE ASSERT_IS_ON}
{$ENDIF}

uses
  Classes, SysUtils, LCLStrConsts, vclglobals, LCLType, LCLProc,
  GraphType, Graphics, LMessages, LCLIntf, InterfaceBase, ImgList, UTrace,
  Menus, ActnList, LCLClasses;


const
  CM_BASE                 = $B000;
  CM_ACTIVATE             = CM_BASE + 0;
  CM_DEACTIVATE           = CM_BASE + 1;
  CM_GOTFOCUS             = CM_BASE + 2;
  CM_LOSTFOCUS            = CM_BASE + 3;
  CM_CANCELMODE           = CM_BASE + 4;
  CM_DIALOGKEY            = CM_BASE + 5;
  CM_DIALOGCHAR           = CM_BASE + 6;
  CM_FOCUSCHANGED         = CM_BASE + 7;
  CM_PARENTFONTCHANGED    = CM_BASE + 8;
  CM_PARENTCOLORCHANGED   = CM_BASE + 9;
  CM_HITTEST              = CM_BASE + 10;
  CM_VISIBLECHANGED       = CM_BASE + 11;
  CM_ENABLEDCHANGED       = CM_BASE + 12;
  CM_COLORCHANGED         = CM_BASE + 13;
  CM_FONTCHANGED          = CM_BASE + 14;
  CM_CURSORCHANGED        = CM_BASE + 15;
  CM_CTL3DCHANGED         = CM_BASE + 16;
  CM_PARENTCTL3DCHANGED   = CM_BASE + 17;
  CM_TEXTCHANGED          = CM_BASE + 18;
  CM_MOUSEENTER           = CM_BASE + 19;
  CM_MOUSELEAVE           = CM_BASE + 20;
  CM_MENUCHANGED          = CM_BASE + 21;
  CM_APPKEYDOWN           = CM_BASE + 22;
  CM_APPSYSCOMMAND        = CM_BASE + 23;
  CM_BUTTONPRESSED        = CM_BASE + 24;
  CM_SHOWINGCHANGED       = CM_BASE + 25;
  CM_ENTER                = CM_BASE + 26;
  CM_EXIT                 = CM_BASE + 27;
  CM_DESIGNHITTEST        = CM_BASE + 28;
  CM_ICONCHANGED          = CM_BASE + 29;
  CM_WANTSPECIALKEY       = CM_BASE + 30;
  CM_INVOKEHELP           = CM_BASE + 31;
  CM_WINDOWHOOK           = CM_BASE + 32;
  CM_RELEASE              = CM_BASE + 33;
  CM_SHOWHINTCHANGED      = CM_BASE + 34;
  CM_PARENTSHOWHINTCHANGED= CM_BASE + 35;
  CM_SYSCOLORCHANGE       = CM_BASE + 36;
  CM_WININICHANGE         = CM_BASE + 37;
  CM_FONTCHANGE           = CM_BASE + 38;
  CM_TIMECHANGE           = CM_BASE + 39;
  CM_TABSTOPCHANGED       = CM_BASE + 40;
  CM_UIACTIVATE           = CM_BASE + 41;
  CM_UIDEACTIVATE         = CM_BASE + 42;
  CM_DOCWINDOWACTIVATE    = CM_BASE + 43;
  CM_CONTROLLISTCHANGE    = CM_BASE + 44;
  CM_GETDATALINK          = CM_BASE + 45;
  CM_CHILDKEY             = CM_BASE + 46;
  CM_DRAG                 = CM_BASE + 47;
  CM_HINTSHOW             = CM_BASE + 48;
  CM_DIALOGHANDLE         = CM_BASE + 49;
  CM_ISTOOLCONTROL        = CM_BASE + 50;
  CM_RECREATEWND          = CM_BASE + 51;
  CM_INVALIDATE           = CM_BASE + 52;
  CM_SYSFONTCHANGED       = CM_BASE + 53;
  CM_CONTROLCHANGE        = CM_BASE + 54;
  CM_CHANGED              = CM_BASE + 55;
  CM_DOCKCLIENT           = CM_BASE + 56;
  CM_UNDOCKCLIENT         = CM_BASE + 57;
  CM_FLOAT                = CM_BASE + 58;
  CM_BORDERCHANGED        = CM_BASE + 59;
  CM_BIDIMODECHANGED      = CM_BASE + 60;
  CM_PARENTBIDIMODECHANGED= CM_BASE + 61;
  CM_ALLCHILDRENFLIPPED   = CM_BASE + 62;
  CM_ACTIONUPDATE         = CM_BASE + 63;
  CM_ACTIONEXECUTE        = CM_BASE + 64;
  CM_HINTSHOWPAUSE        = CM_BASE + 65;
  CM_DOCKNOTIFICATION     = CM_BASE + 66;
  CM_MOUSEWHEEL           = CM_BASE + 67;

  CN_BASE              = $BC00;
  CN_CHARTOITEM        = CN_BASE + LM_CHARTOITEM;
  CN_COMMAND           = CN_BASE + LM_COMMAND;
  CN_COMPAREITEM       = CN_BASE + LM_COMPAREITEM;
  CN_CTLCOLORBTN       = CN_BASE + LM_CTLCOLORBTN;
  CN_CTLCOLORDLG       = CN_BASE + LM_CTLCOLORDLG;
  CN_CTLCOLOREDIT      = CN_BASE + LM_CTLCOLOREDIT;
  CN_CTLCOLORLISTBOX   = CN_BASE + LM_CTLCOLORLISTBOX;
  CN_CTLCOLORMSGBOX    = CN_BASE + LM_CTLCOLORMSGBOX;
  CN_CTLCOLORSCROLLBAR = CN_BASE + LM_CTLCOLORSCROLLBAR;
  CN_CTLCOLORSTATIC    = CN_BASE + LM_CTLCOLORSTATIC;
  CN_DELETEITEM        = CN_BASE + LM_DELETEITEM;
  CN_DRAWITEM          = CN_BASE + LM_DRAWITEM;
  CN_HSCROLL           = CN_BASE + LM_HSCROLL;
  CN_MEASUREITEM       = CN_BASE + LM_MEASUREITEM;
  CN_PARENTNOTIFY      = CN_BASE + LM_PARENTNOTIFY;
  CN_VKEYTOITEM        = CN_BASE + LM_VKEYTOITEM;
  CN_VSCROLL           = CN_BASE + LM_VSCROLL;
  CN_KEYDOWN           = CN_BASE + LM_KEYDOWN;
  CN_KEYUP             = CN_BASE + LM_KEYUP;
  CN_CHAR              = CN_BASE + LM_CHAR;
  CN_SYSKEYUP          = CN_BASE + LM_SYSKEYUP;
  CN_SYSKEYDOWN        = CN_BASE + LM_SYSKEYDOWN;
  CN_SYSCHAR           = CN_BASE + LM_SYSCHAR;
  CN_NOTIFY            = CN_BASE + LM_NOTIFY;


const
  mrNone = 0;
  mrOK = mrNone + 1;
  mrCancel = mrNone + 2;
  mrAbort = mrNone + 3;
  mrRetry = mrNone + 4;
  mrIgnore = mrNone + 5;
  mrYes = mrNone + 6;
  mrNo = mrNone + 7;
  mrAll = mrNone + 8;
  mrNoToAll = mrNone + 9;
  mrYesToAll = mrNone + 10;
  mrLast = mrYesToAll;


type
  TWinControl = class;
  TControl = class;
  TWinControlClass = class of TWinControl;

  TDate = type TDateTime;
  TTime = type TDateTime;

  // ToDo: move this to a message definition unit
  TCMMouseWheel = record
    MSg: Cardinal;
    ShiftState : TShiftState;
    Unused : Byte;
    WheelData : SmallInt;
    case Integer of
    0 : (
      XPos : SmallInt;
      YPos : SmallInt);
    1 : (
      Pos : TSmallPoint;
      Result : LongInt);
  end;

  TCMHitTest = TLMNCHitTest;

  TCMControlChange = record
    Msg : Cardinal;
    Control : TControl;
    Inserting : Boolean;
    Result : Longint;
  End;

  TCMDialogChar = TLMKEY;
  TCMDialogKey = TLMKEY;

  TAlign = (alNone, alTop, alBottom, alLeft, alRight, alClient, alCustom);
  TAlignSet = set of TAlign;
  TAnchorKind = (akTop, akLeft, akRight, akBottom);
  TAnchors = set of TAnchorKind;
  TCaption = String;
  TCursor = -32768..32767;

  TFormStyle = (fsNormal, fsMDIChild, fsMDIFORM, fsStayOnTop);
  TFormBorderStyle = (bsNone, bsSingle, bsSizeable, bsDialog, bsToolWindow,
                      bsSizeToolWin);
  TBorderStyle = bsNone..bsSingle;
  TControlBorderStyle = TBorderStyle;

  TBevelCut = TGraphicsBevelCut;

  TMouseButton = (mbLeft, mbRight, mbMiddle);

const
  // Cursor constants
  crHigh        = TCursor(0);

  crDefault     = TCursor(0);
  crNone        = TCursor(-1);
  crArrow       = TCursor(-2);
  crCross       = TCursor(-3);
  crIBeam       = TCursor(-4);
  crSize        = TCursor(-22);
  crSizeNESW    = TCursor(-6);
  crSizeNS      = TCursor(-7);
  crSizeNWSE    = TCursor(-8);
  crSizeWE      = TCursor(-9);
  crUpArrow     = TCursor(-10);
  crHourGlass   = TCursor(-11);
  crDrag        = TCursor(-12);
  crNoDrop      = TCursor(-13);
  crHSplit      = TCursor(-14);
  crVSplit      = TCursor(-15);
  crMultiDrag   = TCursor(-16);
  crSQLWait     = TCursor(-17);
  crNo          = TCursor(-18);
  crAppStart    = TCursor(-19);
  crHelp        = TCursor(-20);
  crHandPoint   = TCursor(-21);
  crSizeAll     = TCursor(-22);

  crLow         = TCursor(-22);

type
  TWndMethod = procedure(var TheMessage : TLMessage) of Object;

  TControlStyleType = (
    csAcceptsControls, // can have childs
    csCaptureMouse,
    csDesignInteractive, // wants mouse events in design mode
    csClickEvents,
    csFramed,
    csSetCaption,
    csOpaque,
    csDoubleClicks,// control understands mouse double clicks
    csTripleClicks,// control understands mouse triple clicks
    csQuadClicks,  // control understands mouse quad clicks
    csFixedWidth,
    csFixedHeight,
    csNoDesignVisible,
    csReplicatable,
    csNoStdEvents,
    csDisplayDragImage,
    csReflector,
    csActionClient,
    csMenuEvents,
    csNoFocus,
    csNeedsBorderPaint, // not implemented
    csParentBackground, // not implemented
    csDesignNoSmoothResize, // no WYSIWYG resizing in designer
    csDesignFixedBounds // control can not be moved nor resized in designer
    );
  TControlStyle = set of TControlStyleType;

const
  csMultiClicks = [csDoubleClicks,csTripleClicks,csQuadClicks];


type
  TControlStateType = (
    csLButtonDown,
    csClicked,
    csPalette,
    csReadingState,
    csAlignmentNeeded,
    csFocusing,
    csCreating,
    csPaintCopy,
    csCustomPaint,
    csDestroyingHandle,
    csDocking,
    csVisibleSetInLoading
    );
  TControlState = set of TControlStateType;


  { TControlCanvas }

  TControlCanvas = class(TCanvas)
  private
    FControl: TControl;
    FDeviceContext: HDC;
    FWindowHandle: HWND;
    procedure SetControl(AControl: TControl);
    procedure CreateFont; override;
  protected
    procedure CreateHandle; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure FreeHandle;
    property Control: TControl read FControl write SetControl;
  end;


  { TDragImageList }

  TDragImageList = class(TCustomImageList)
  end;



  TKeyEvent = procedure(Sender: TObject; var Key: Word; Shift:TShiftState) of Object;
  TKeyPressEvent = procedure(Sender: TObject; var Key: Char) of Object;

  TMouseEvent = Procedure(Sender : TOBject; Button: TMouseButton;
                          Shift : TShiftState; X, Y: Integer) of object;
  TMouseMoveEvent = Procedure(Sender: TObject; Shift: TShiftState;
                              X, Y: Integer) of object;
  TMouseWheelEvent = Procedure(Sender: TObject; Shift: TShiftState;
         WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean) of object;
  TMouseWheelUpDownEvent = Procedure(Sender: TObject;
          Shift: TShiftState; MousePos: TPoint; var Handled: Boolean) of object;


  { TDragObject }

  TDragObject = class;

  TDragState = (dsDragEnter, dsDragLeave, dsDragMove);
  TDragMode = (dmManual , dmAutomatic);
  TDragKind = (dkDrag, dkDock);
  TDragOperation = (
    dopNone,  // not dragging or Drag initialized, but not yet started.
              //  Waiting for mouse move more then Treshold.
    dopDrag,  // Dragging
    dopDock   // Docking
    );
  TDragMessage = (dmDragEnter, dmDragLeave, dmDragMove, dmDragDrop,
                  dmDragCancel,dmFindTarget);
  TDragOverEvent = Procedure(Sender, Source: TObject;
               X,Y : Integer; State: TDragState; Var Accept: Boolean) of Object;
  TDragDropEvent = Procedure(Sender, Source: TObject; X,Y: Integer) of Object;
  TStartDragEvent = Procedure(Sender: TObject; DragObject: TDragObject) of Object;
  TEndDragEvent = Procedure(Sender, Target: TObject; X,Y: Integer) of Object;


  PDragRec = ^TDragRec;
  TDragRec = record
    Pos: TPoint;
    Source: TDragObject;
    Target: TControl;
    Docking: Boolean;
  end;

  TCMDrag = packed record
    Msg: Cardinal;
    DragMessage: TDragMessage;
    Reserved1: Byte; // for Delphi compatibility
    Reserved2: Word; // for Delphi compatibility
    DragRec: PDragRec;
    Result: Longint;
  end;

  TDragObject = class(TObject)
  private
    FDragTarget: TControl;
    FDragHandle: HWND;
    FDragPos: TPoint;
    FDragTargetPos: TPoint;
    FDropped: Boolean;
    FMouseDeltaX: Double;
    FMouseDeltaY: Double;
    FCancelling: Boolean;
    function Capture: HWND;
  protected
    procedure Finished(Target: TObject; X, Y: Integer; Accepted: Boolean); virtual;
    function GetDragCursor(Accepted: Boolean; X, Y: Integer): TCursor; virtual;
    function GetDragImages: TDragImageList; virtual;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseDown(Button: TMouseButton; Shift:TShiftState; X, Y: Integer); virtual;
    procedure MouseUp(Button: TMouseButton; Shift:TShiftState; X, Y: Integer); virtual;
    procedure CaptureChanged(OldCaptureControl: TControl); virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); virtual;
    procedure KeyUp(var Key: Word; Shift: TShiftState); virtual;
  public
    destructor Destroy; override;
    procedure Assign(Source: TDragObject); virtual;
    function GetName: string; virtual;
    procedure HideDragImage; virtual;
    function Instance: THandle; virtual;
    procedure ShowDragImage; virtual;
    property Cancelling: Boolean read FCancelling write FCancelling;
    property DragHandle: HWND read FDragHandle write FDragHandle;
    property DragPos: TPoint read FDragPos write FDragPos;
    property DragTargetPos: TPoint read FDragTargetPos write FDragTargetPos;
    property DragTarget: TControl read FDragTarget write FDragTarget;
    property Dropped: Boolean read FDropped;
    property MouseDeltaX: Double read FMouseDeltaX;
    property MouseDeltaY: Double read FMouseDeltaX;
  end;

  TDragObjectClass = class of TDragObject;


  { TBaseDragControlObject }

  TBaseDragControlObject = class(TDragObject)
  private
    FControl: TControl;
  protected
    Procedure EndDrag(Target: TObject; X, Y: Integer); Virtual;
    procedure Finished(Target: TObject; X, Y: Integer; Accepted: Boolean); override;
  Public
    constructor Create(AControl: TControl); virtual;
    procedure Assign(Source: TDragObject); override;
    property Control: TControl read FControl write FControl;
  end;


  { TDragControlObject }

  TDragControlObject = class(TBaseDragControlObject)
  protected
    function GetDragCursor(Accepted: Boolean; X, Y: Integer): TCursor; override;
    function GetDragImages: TDragImageList; override;
  public
    procedure HideDragImage; override;
    procedure ShowDragImage; override;
  end;


  { TDragDockObject }

  TDragDockObject = class;

  TDockOrientation = (
    doNoOrient,   // zone contains a TControl and no child zones.
    doHorizontal, // zone's children are stacked top-to-bottom.
    doVertical    // zone's children are arranged left-to-right.
    );
  TDockDropEvent = procedure(Sender: TObject; Source: TDragDockObject;
                             X, Y: Integer) of object;
  TDockOverEvent = procedure(Sender: TObject; Source: TDragDockObject;
                             X, Y: Integer; State: TDragState;
                             var Accept: Boolean) of object;
  TUnDockEvent = procedure(Sender: TObject; Client: TControl;
                          NewTarget: TWinControl; var Allow: Boolean) of object;
  TStartDockEvent = procedure(Sender: TObject;
                              var DragObject: TDragDockObject) of object;
  TGetSiteInfoEvent = procedure(Sender: TObject; DockClient: TControl;
    var InfluenceRect: TRect; MousePos: TPoint; var CanDock: Boolean) of object;

  TDragDockObject = class(TBaseDragControlObject)
  private
    FBrush: TBrush;
    FDockRect: TRect;
    FDropAlign: TAlign;
    FDropOnControl: TControl;
    FFloating: Boolean;
    procedure SetBrush(Value: TBrush);
  protected
    procedure AdjustDockRect(ARect: TRect); virtual;
    procedure DrawDragDockImage; virtual;
    procedure EndDrag(Target: TObject; X, Y: Integer); override;
    procedure EraseDragDockImage; virtual;
    function GetDragCursor(Accepted: Boolean; X, Y: Integer): TCursor; override;
    function GetFrameWidth: Integer; virtual;
  public
    constructor Create(AControl: TControl); override;
    destructor Destroy; override;
    procedure Assign(Source: TDragObject); override;
    property Brush: TBrush read FBrush write SetBrush;
    property DockRect: TRect read FDockRect write FDockRect;
    property DropAlign: TAlign read FDropAlign;
    property DropOnControl: TControl read FDropOnControl;
    property Floating: Boolean read FFloating write FFloating;
    property FrameWidth: Integer read GetFrameWidth;
  end;


  { TDockManager is an abstract class for managing a dock site's docked
    controls. See TDockTree for the default dock manager }
  TDockManager = class
    procedure BeginUpdate; virtual; abstract;
    procedure EndUpdate; virtual; abstract;
    procedure GetControlBounds(Control: TControl; var CtlBounds: TRect); virtual; abstract;
    procedure InsertControl(Control: TControl; InsertAt: TAlign;
      DropCtl: TControl); virtual; abstract;
    procedure LoadFromStream(Stream: TStream); virtual; abstract;
    procedure PaintSite(DC: HDC); virtual; abstract;
    procedure PositionDockRect(Client, DropCtl: TControl; DropAlign: TAlign;
      var DockRect: TRect); virtual; abstract;
    procedure RemoveControl(Control: TControl); virtual; abstract;
    procedure ResetBounds(Force: Boolean); virtual; abstract;
    procedure SaveToStream(Stream: TStream); virtual; abstract;
    procedure SetReplacingControl(Control: TControl); virtual; abstract;
  end;


  { TSizeConstraints }

  TConstraintSize = 0..MaxInt;

  TSizeConstraintsOption = (scoAdviceWidthAsMin, scoAdviceWidthAsMax,
    scoAdviceHeightAsMin, scoAdviceHeightAsMax);
  TSizeConstraintsOptions = set of TSizeConstraintsOption;

  TSizeConstraints = class(TPersistent)
  private
    FControl: TControl;
    FMaxHeight: TConstraintSize;
    FMaxInterfaceHeight: integer;
    FMaxInterfaceWidth: integer;
    FMaxWidth: TConstraintSize;
    FMinHeight: TConstraintSize;
    FMinInterfaceHeight: integer;
    FMinInterfaceWidth: integer;
    FMinWidth: TConstraintSize;
    FOnChange: TNotifyEvent;
    FOptions: TSizeConstraintsOptions;
    procedure SetOptions(const AValue: TSizeConstraintsOptions);
  protected
    procedure Change; dynamic;
    procedure AssignTo(Dest: TPersistent); override;
    procedure SetMaxHeight(Value: TConstraintSize); virtual;
    procedure SetMaxWidth(Value: TConstraintSize); virtual;
    procedure SetMinHeight(Value: TConstraintSize); virtual;
    procedure SetMinWidth(Value: TConstraintSize); virtual;
  public
    constructor Create(AControl: TControl); virtual;
    procedure UpdateInterfaceConstraints; virtual;
    procedure SetInterfaceConstraints(MinW, MinH, MaxW, MaxH: integer); virtual;
    function EffectiveMinWidth: integer; virtual;
    function EffectiveMinHeight: integer; virtual;
    function EffectiveMaxWidth: integer; virtual;
    function EffectiveMaxHeight: integer; virtual;
  public
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property MaxInterfaceHeight: integer read FMaxInterfaceHeight;
    property MaxInterfaceWidth: integer read FMaxInterfaceWidth;
    property MinInterfaceHeight: integer read FMinInterfaceHeight;
    property MinInterfaceWidth: integer read FMinInterfaceWidth;
    property Control: TControl read FControl;
    property Options: TSizeConstraintsOptions read FOptions write SetOptions default [];
  published
    property MaxHeight: TConstraintSize read FMaxHeight write SetMaxHeight default 0;
    property MaxWidth: TConstraintSize read FMaxWidth write SetMaxWidth default 0;
    property MinHeight: TConstraintSize read FMinHeight write SetMinHeight default 0;
    property MinWidth: TConstraintSize read FMinWidth write SetMinWidth default 0;
  end;

  TConstrainedResizeEvent = procedure(Sender : TObject;
      var MinWidth, MinHeight, MaxWidth, MaxHeight : TConstraintSize) of object;


  { TControlBorderSpacing }
  
  { TControlBorderSpacing defines the spacing around a control, around its
    childs and between its childs.

    Left, Top, Right, Bottom: integer;
        minimum space left to the control.
        For example: Control A lies left of control B.
        A has borderspacing Right=10 and B has borderspacing Left=5.
        Then A and B will have a minimum space of 10 between.

    Around: integer;
        same as Left, Top, Right and Bottom all at once. This will be added to
        the effective Left, Top, Right and Bottom.
        Example: Left=3 and Around=5 results in a minimum spacing to the left
        of 8.

  }
  
  TSpacingSize = 0..MaxInt;

  TControlBorderSpacing = class(TPersistent)
  private
    FAround: TSpacingSize;
    FBottom: TSpacingSize;
    FControl: TControl;
    FLeft: TSpacingSize;
    FOnChange: TNotifyEvent;
    FRight: TSpacingSize;
    FTop: TSpacingSize;
    procedure SetAround(const AValue: TSpacingSize);
    procedure SetBottom(const AValue: TSpacingSize);
    procedure SetLeft(const AValue: TSpacingSize);
    procedure SetRight(const AValue: TSpacingSize);
    procedure SetTop(const AValue: TSpacingSize);
  protected
    procedure Change; dynamic;
  public
    constructor Create(OwnerControl: TControl);
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
    function IsEqual(Spacing: TControlBorderSpacing): boolean;
  public
    property Control: TControl read FControl;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Left: TSpacingSize read FLeft write SetLeft;
    property Top: TSpacingSize read FTop write SetTop;
    property Right: TSpacingSize read FRight write SetRight;
    property Bottom: TSpacingSize read FBottom write SetBottom;
    property Around: TSpacingSize read FAround write SetAround;
  end;


  { TControlActionLink }

  TControlActionLink = class(TActionLink)
  protected
    FClient: TControl;
    procedure AssignClient(AClient: TObject); override;
    function IsCaptionLinked: Boolean; override;
    function IsEnabledLinked: Boolean; override;
    function IsHelpLinked: Boolean;  override;
    function IsHintLinked: Boolean; override;
    function IsVisibleLinked: Boolean; override;
    function IsOnExecuteLinked: Boolean; override;
    function DoShowHint(var HintStr: string): Boolean; virtual;
    procedure SetCaption(const Value: string); override;
    procedure SetEnabled(Value: Boolean); override;
    procedure SetHint(const Value: string); override;
    procedure SetHelpContext(Value: THelpContext); override;
    procedure SetHelpKeyword(const Value: string); override;
    procedure SetHelpType(Value: THelpType); override;
    procedure SetVisible(Value: Boolean); override;
    procedure SetOnExecute(Value: TNotifyEvent); override;
  end;

  TControlActionLinkClass = class of TControlActionLink;


  { TControl }

  TTabOrder = -1..32767;

  TControlShowHintEvent = procedure(Sender: TObject; HintInfo: Pointer) of object;
  TContextPopupEvent = procedure(Sender: TObject; MousePos: TPoint; var Handled: Boolean) of object;
  
  TControlFlag = (
    cfRequestAlignNeeded,
    cfClientWidthLoaded,
    cfClientHeightLoaded,
    cfLastAlignedBoundsValid
    );
  TControlFlags = set of TControlFlag;

  TControlHandlerType = (
    chtOnResize,
    chtOnChangeBounds
    );
  TControlHandlerTypes = set of TControlHandlerType;
  
(*
 * Note on TControl.Caption
 * The VCL implementation relies on the virtual Get/SetTextBuf to 
 * exchange text between widgets and VCL. This means a lot of 
 * (unnecesary) text copies.
 * The LCL uses strings for exchanging text (more efficient).
 * To maintain VCL compatibility, the virtual RealGet/SetText is
 * introduced. These functions interface with the LCLInterface. The
 * default Get/SetTextbuf implementation calls the RealGet/SetText.
 * As long as the Get/SetTextBuf isn't overridden Get/SetText 
 * calls RealGet/SetText to avoid PChar copiing.
 * To keep things optimal, LCL implementations should always 
 * override RealGet/SetText. Get/SetTextBuf is only kept for
 * compatibility.
 *)  

  TControl = class(TLCLComponent)
  private
    FActionLink: TControlActionLink;
    FAlign : TAlign;
    FAnchors : TAnchors;
    FAutoSize : Boolean;
    FBaseBounds: TRect;
    FBaseBoundsLock: integer;
    FBaseParentClientSize: TPoint;
    FBorderSpacing: TControlBorderSpacing;
    FCaption : TCaption;
    FColor : TColor;
    FConstraints : TSizeConstraints;
    FControlFlags: TControlFlags;
    FControlHandlers: array[TControlHandlerType] of TMethodList;
    FControlStyle: TControlStyle;
    FCtl3D : Boolean;
    FCursor : TCursor;
    FDockOrientation: TDockOrientation;
    FDragCursor : TCursor;
    FDragKind : TDragKind;
    FDragMode : TDragMode;
    FEnabled : Boolean;
    FFloatingDockSiteClass: TWinControlClass;
    FFont: TFont;
    FHeight: Integer;
    FHelpContext: THelpContext;
    FHelpKeyword: String;
    FHelpType: THelpType;
    FHint: String;
    FHostDockSite : TWinControl;
    FIsControl : Boolean;
    fLastAlignedBounds: TRect;
    FLastChangebounds: TRect;
    FLastDoChangeBounds: TRect;
    FLastResizeClientHeight: integer;
    FLastResizeClientWidth: integer;
    FLastResizeHeight: integer;
    FLastResizeWidth: integer;
    FLeft: Integer;
    FLoadedClientSize: TPoint;
    FLRDockWidth: Integer;
    FMouseEntered: boolean;
    FOnChangeBounds: TNotifyEvent;
    FOnClick: TNotifyEvent;
    FOnConstrainedResize : TConstrainedResizeEvent;
    FOnContextPopup: TContextPopupEvent;
    FOnDblClick: TNotifyEvent;
    FOnDragDrop: TDragDropEvent;
    FOnDragOver: TDragOverEvent;
    FOnEndDock: TEndDragEvent;
    FOnEndDrag: TEndDragEvent;
    FOnMouseDown: TMouseEvent;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseLeave: TNotifyEvent;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseUp: TMouseEvent;
    FOnQuadClick: TNotifyEvent;
    FOnResize: TNotifyEvent;
    FOnShowHint: TControlShowHintEvent;
    FOnStartDock: TStartDockEvent;
    FOnStartDrag: TStartDragEvent;
    FOnTripleClick: TNotifyEvent;
    FParent: TWinControl;
    FParentColor: Boolean;
    FParentFont: Boolean;
    FParentShowHint : Boolean;
    FPopupMenu: TPopupMenu;
    FShowHint: Boolean;
    FSizeLock: integer;
    FTabOrder: integer;
    FTabStop : Boolean;
    FTBDockHeight: Integer;
    FTop: Integer;
    FUndockHeight: Integer;
    FUndockWidth: Integer;
    FVisible: Boolean;
    FWidth: Integer;
    FWindowProc: TWndMethod;
    procedure DoActionChange(Sender: TObject);
    function GetBoundsRect : TRect;
    function GetClientHeight: Integer;
    function GetClientWidth: Integer;
    function GetLRDockWidth: Integer;
    function GetMouseCapture : Boolean;
    function GetTBDockHeight: Integer;
    function GetTabOrder: TTabOrder;
    function GetText: TCaption; 
    function GetUndockHeight: Integer;
    function GetUndockWidth: Integer;
    function IsCaptionStored : Boolean;
    function IsColorStored: Boolean;
    function IsEnabledStored: Boolean;
    function IsFontStored: Boolean;
    function IsHintStored: Boolean;
    function IsHelpContextStored: Boolean;
    function IsHelpKeyWordStored: boolean;
    function IsOnClickStored: Boolean;
    function IsShowHintStored: Boolean;
    function IsVisibleStored: Boolean;
    procedure CheckMenuPopup(const P : TSmallPoint);
    procedure DoBeforeMouseMessage;
    procedure DoConstrainedResize(var NewWidth, NewHeight : integer);
    procedure DoMouseDown(var Message: TLMMouse; Button: TMouseButton; Shift:TShiftState);
    procedure DoMouseUp(var Message: TLMMouse; Button: TMouseButton);
    procedure SetBorderSpacing(const AValue: TControlBorderSpacing);
    procedure SetBoundsRect(const ARect : TRect);
    procedure SetClientHeight(Value: Integer);
    procedure SetClientSize(Value: TPoint);
    procedure SetClientWidth(Value: Integer);
    procedure SetConstraints(const Value : TSizeConstraints);
    procedure SetCursor(Value : TCursor);
    procedure SetDragCursor(const AValue: TCursor);
    procedure SetFont(Value: TFont);
    procedure SetHeight(Value: Integer);
    procedure SetHelpContext(const AValue: THelpContext);
    procedure SetHelpKeyword(const AValue: String);
    procedure SetHostDockSite(const AValue: TWinControl);
    procedure SetLeft(Value: Integer);
    procedure SetMouseCapture(Value : Boolean);
    procedure SetParentShowHint(Value : Boolean);
    procedure SetParentColor(Value : Boolean);
    procedure SetPopupMenu(Value : TPopupMenu);
    procedure SetShowHint(Value : Boolean);
    Procedure SetTabOrder(Value : TTabOrder);
    procedure SetTabStop(Value : Boolean);
    procedure SetText(const Value: TCaption); 
    procedure SetTop(Value: Integer);
    procedure SetVisible(Value: Boolean);
    procedure SetWidth(Value: Integer);
    Procedure UpdateTabOrder(value : TTabOrder);
  protected
    FControlState: TControlState;
  protected
    // sizing/aligning
    AutoSizing: Boolean;
    procedure AdjustSize; dynamic;
    procedure DoAutoSize; Virtual;
    procedure SetAlign(Value: TAlign); virtual;
    procedure SetAnchors(const AValue: TAnchors); virtual;
    procedure SetAutoSize(const Value: Boolean); virtual;
    procedure BoundsChanged; dynamic;
    procedure DoConstraintsChange(Sender: TObject); virtual;
    procedure DoBorderSpacingChange(Sender: TObject); virtual;
    procedure SendMoveSizeMessages(SizeChanged, PosChanged: boolean); virtual;
    procedure ConstrainedResize(var MinWidth, MinHeight,
                                MaxWidth, MaxHeight: TConstraintSize); virtual;
    procedure DoOnResize; virtual;
    procedure DoOnChangeBounds; virtual;
    procedure Resize; virtual;
    procedure RequestAlign; dynamic;
    procedure UpdateBaseBounds(StoreBounds, StoreParentClientSize,
                               UseLoadedValues: boolean); virtual;
    procedure LockBaseBounds;
    procedure UnlockBaseBounds;
    procedure UpdateAnchorRules;
    procedure ChangeBounds(ALeft, ATop, AWidth, AHeight: integer); virtual;
    procedure DoSetBounds(ALeft, ATop, AWidth, AHeight: integer); virtual;
    procedure ChangeScale(M,D : Integer); dynamic;
    Function CanAutoSize(var NewWidth, NewHeight : Integer): Boolean; virtual;
    procedure SetAlignedBounds(aLeft, aTop, aWidth, aHeight: integer); virtual;
    Function GetClientOrigin : TPoint; virtual;
    Function GetClientRect: TRect; virtual;
    Function GetScrolledClientRect: TRect; virtual;
    function GetChildsRect(Scrolled: boolean): TRect; virtual;
    function GetClientScrollOffset: TPoint; virtual;
  protected
    // protected messages
    procedure WMLButtonDown(Var Message: TLMLButtonDown); message LM_LBUTTONDOWN;
    procedure WMRButtonDown(Var Message: TLMRButtonDown); message LM_RBUTTONDOWN;
    procedure WMMButtonDown(Var Message: TLMMButtonDown); message LM_MBUTTONDOWN;
    procedure WMLButtonDBLCLK(Var Message: TLMLButtonDblClk); message LM_LBUTTONDBLCLK;
    procedure WMRButtonDBLCLK(Var Message: TLMRButtonDblClk); message LM_RBUTTONDBLCLK;
    procedure WMMButtonDBLCLK(Var Message: TLMMButtonDblClk); message LM_MBUTTONDBLCLK;
    procedure WMLButtonTripleCLK(Var Message: TLMLButtonTripleClk); message LM_LBUTTONTRIPLECLK;
    procedure WMRButtonTripleCLK(Var Message: TLMRButtonTripleClk); message LM_RBUTTONTRIPLECLK;
    procedure WMMButtonTripleCLK(Var Message: TLMMButtonTripleClk); message LM_MBUTTONTRIPLECLK;
    procedure WMLButtonQuadCLK(Var Message: TLMLButtonQuadClk); message LM_LBUTTONQUADCLK;
    procedure WMRButtonQuadCLK(Var Message: TLMRButtonQuadClk); message LM_RBUTTONQUADCLK;
    procedure WMMButtonQuadCLK(Var Message: TLMMButtonQuadClk); message LM_MBUTTONQUADCLK;
    procedure WMMouseMove(Var Message: TLMMouseMove); message LM_MOUSEMOVE;
    procedure WMLButtonUp(var Message: TLMLButtonUp); message LM_LBUTTONUP;
    procedure WMRButtonUp(var Message: TLMRButtonUp); message LM_RBUTTONUP;
    procedure WMMButtonUp(var Message: TLMMButtonUp); message LM_MBUTTONUP;
    procedure WMDragStart(Var Message: TLMessage); message LM_DRAGSTART;  //not in delphi
    procedure WMMove(var Message: TLMMove); message LM_MOVE;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
    procedure WMWindowPosChanged(var Message: TLMWindowPosChanged); message LM_WINDOWPOSCHANGED;
    procedure LMCaptureChanged(Var Message: TLMessage); message LM_CaptureChanged;
    procedure CMEnabledChanged(var Message: TLMEssage); message CM_ENABLEDCHANGED;
    procedure CMHitTest(Var Message: TCMHittest) ; Message CM_HITTEST;
    procedure CMMouseEnter(var Message :TLMessage); message CM_MouseEnter;
    procedure CMMouseLeave(var Message :TLMessage); message CM_MouseLeave;
    procedure CMHintShow(var Message: TLMessage); message CM_HINTSHOW;
    procedure CMParentColorChanged(var Message : TLMessage); message CM_PARENTCOLORCHANGED;
    procedure CMParentShowHintChanged(var Message : TLMessage); message CM_PARENTSHOWHINTCHANGED;
    procedure CMVisibleChanged(var Message : TLMessage); message CM_VISIBLECHANGED;
  protected
    // drag and drop
    function GetDockEdge(const MousePos: TPoint): TAlign; dynamic;
    function GetFloating: Boolean; virtual;
    function GetFloatingDockSiteClass: TWinControlClass; virtual;
    procedure BeginAutoDrag; dynamic;
    procedure DefaultDockImage(DragDockObject: TDragDockObject; Erase: Boolean); dynamic;
    procedure DockTrackNoTarget(Source: TDragDockObject; X, Y: Integer); dynamic;
    procedure DoDock(NewDockSite: TWinControl; var ARect: TRect); dynamic;
    procedure DoDragMsg(var DragMsg: TCMDrag); virtual;
    procedure DoEndDock(Target: TObject; X, Y: Integer); dynamic;
    procedure DoEndDrag(Target: TObject; X,Y : Integer); dynamic;
    procedure DoStartDock(var DragObject: TDragObject); dynamic;
    procedure DoStartDrag(var DragObject: TDragObject); dynamic;
    procedure DragCanceled; dynamic;
    procedure DragOver(Source: TObject; X,Y: Integer; State: TDragState;
                       var Accept: Boolean); dynamic;
    procedure DrawDragDockImage(DragDockObject: TDragDockObject); dynamic;
    procedure EraseDragDockImage(DragDockObject: TDragDockObject); dynamic;
    procedure PositionDockRect(DragDockObject: TDragDockObject); dynamic;
    procedure SendDockNotification; virtual;
    procedure SetDragMode(Value: TDragMode); virtual;
  protected
    // mouse
    procedure Click; dynamic;
    procedure DblClick; dynamic;
    procedure TripleClick; dynamic;
    procedure QuadClick; dynamic;
    procedure MouseDown(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); dynamic;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer); Dynamic;
    procedure MouseUp(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); dynamic;
    procedure MouseEnter; virtual;
    procedure MouseLeave; virtual;
  protected
    procedure Changed;
    function  GetPalette: HPalette; virtual;
    function ChildClassAllowed(ChildClass: TClass): boolean; virtual;
    procedure Loaded; override;
    procedure AssignTo(Dest: TPersistent); override;
    procedure InvalidateControl(IsVisible, IsOpaque : Boolean);
    procedure InvalidateControl(IsVisible, IsOpaque, IgnoreWinControls: Boolean);
    procedure FontChanged(Sender: TObject); virtual;
    function GetAction: TBasicAction; virtual;
    function RealGetText: TCaption; virtual;
    procedure RealSetText(const Value: TCaption); virtual;
    procedure SetAction(Value: TBasicAction); virtual;
    procedure SetColor(Value : TColor); virtual;
    procedure SetEnabled(Value: Boolean); virtual;
    procedure SetHint(const Value: String); virtual;
    procedure SetName(const Value: TComponentName); override;
    procedure SetParent(AParent: TWinControl); virtual;
    Procedure SetParentComponent(Value: TComponent); override;
    procedure WndProc(var TheMessage: TLMessage); virtual;
    procedure CaptureChanged; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    Function CanTab: Boolean; virtual;
    Function Focused: Boolean; dynamic;
    Procedure SetFocus; virtual;
    function GetDeviceContext(var WindowHandle: HWnd): HDC; virtual;
    Function GetEnabled: Boolean; virtual;
    Function GetPopupMenu: TPopupMenu; dynamic;
    procedure DoOnShowHint(HintInfo: Pointer);
    procedure VisibleChanging; dynamic;
    procedure AddControlHandler(HandlerType: TControlHandlerType;
                                AMethod: TMethod; AsLast: boolean);
    procedure RemoveControlHandler(HandlerType: TControlHandlerType;
                                   AMethod: TMethod);
    procedure DoContextPopup(const MousePos: TPoint; var Handled: Boolean); virtual;
  protected
    // actions
    function GetActionLinkClass: TControlActionLinkClass; dynamic;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); dynamic;
  protected
    // optional properties (not every descendent supports them)
    property ActionLink: TControlActionLink read FActionLink write FActionLink;
    property AutoSize: Boolean read FAutoSize write SetAutoSize default FALSE;
    property Ctl3D: Boolean read FCtl3D write FCtl3D;//Is this needed for anything other than compatability?
    property DragCursor: TCursor read FDragCursor write SetDragCursor default crDrag;
    property DragKind: TDragKind read FDragKind write FDragKind default dkDrag;
    property DragMode: TDragMode read fDragMode write SetDragMode default dmManual;
    property MouseCapture: Boolean read GetMouseCapture write SetMouseCapture;
    property ParentFont: Boolean  read FParentFont write FParentFont;
    property ParentColor: Boolean  read FParentColor write SetParentColor;
    property ParentShowHint : Boolean read FParentShowHint write SetParentShowHint default True;
    property Text: TCaption read GetText write SetText;
    property OnConstrainedResize: TConstrainedResizeEvent read FOnConstrainedResize write FOnConstrainedResize;
    property OnContextPopup: TContextPopupEvent read FOnContextPopup write FOnContextPopup;
    property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
    property OnTripleClick: TNotifyEvent read FOnTripleClick write FOnTripleClick;
    property OnQuadClick: TNotifyEvent read FOnQuadClick write FOnQuadClick;
    property OnDragDrop: TDragDropEvent read FOnDragDrop write FOnDragDrop;
    property OnDragOver: TDragOverEvent read FOnDragOver write FOnDragOver;
    property OnEndDock: TEndDragEvent read FOnEndDock write FOnEndDock;
    property OnEndDrag: TEndDragEvent read FOnEndDrag write FOnEndDrag;
    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
    property OnStartDock: TStartDockEvent read FOnStartDock write FOnStartDock;
    property OnStartDrag: TStartDragEvent read FOnStartDrag write FOnStartDrag;
  public
    FCompStyle: Byte; // enables (valid) use of 'IN' operator (this is a hack
      // for speed. It will be replaced by the use of the widgetset classes.
      // So, don't use it anymore)
  public
    // drag and dock
    Procedure DragDrop(Source: TObject; X,Y: Integer); Dynamic;
    procedure Dock(NewDockSite: TWinControl; ARect: TRect); dynamic;
    function ManualDock(NewDockSite: TWinControl;
      DropControl: TControl {$IFNDEF VER1_0}= nil{$ENDIF};
      ControlSide: TAlign {$IFNDEF VER1_0}= alNone{$ENDIF}): Boolean;
    function ManualFloat(ScreenPos: TRect): Boolean;
    function ReplaceDockedControl(Control: TControl; NewDockSite: TWinControl;
      DropControl: TControl; ControlSide: TAlign): Boolean;
  public
    constructor Create(AOwner: TComponent);override;
    destructor Destroy; override;
    Function PerformTab(ForwardTab: boolean): Boolean; Virtual;
    procedure BeginDrag(Immediate: Boolean; Threshold: Integer);
    procedure BeginDrag(Immediate: Boolean);
    procedure BringToFront;
    function ColorIsStored: boolean; virtual;
    function HasParent: Boolean; override;
    function IsParentOf(AControl: TControl): boolean; virtual;
    procedure Refresh;
    procedure Repaint; virtual;
    Procedure Invalidate; virtual;
    procedure AddControl; virtual;
    function CheckChildClassAllowed(ChildClass: TClass;
                                    ExceptionOnInvalid: boolean): boolean;
    procedure CheckNewParent(AParent: TWinControl); virtual;
    procedure SendToBack;
    procedure SetBounds(aLeft, aTop, aWidth, aHeight: integer); virtual;
    procedure SetInitialBounds(aLeft, aTop, aWidth, aHeight: integer); virtual;
    procedure SetBoundsKeepBase(aLeft, aTop, aWidth, aHeight: integer;
                                Lock: boolean); virtual;
    function  GetTextBuf(Buffer: PChar; BufSize: Integer): Integer; virtual;
    function  GetTextLen: Integer; virtual;
    Procedure SetTextBuf(Buffer : PChar); virtual;
    Function  Perform(Msg:Cardinal; WParam: WParam; LParam: LParam): LongInt;
    Function  ScreenToClient(const Point : TPoint) : TPoint;
    Function  ClientToScreen(const Point : TPoint) : TPoint;
    Function  Dragging : Boolean;
    procedure Show;
    procedure Update; virtual;
    procedure SetZOrderPosition(NewPosition: Integer); virtual;
    Procedure SetZOrder(TopMost: Boolean); virtual;
    function HandleObjectShouldBeVisible: boolean; virtual;
    function ParentHandlesAllocated: boolean; virtual;
    procedure InitiateAction; virtual;
    property MouseEntered: Boolean read FMouseEntered;
  public
    // Event lists
    procedure RemoveAllControlHandlersOfObject(AnObject: TObject);
    procedure AddHandlerOnResize(OnResizeEvent: TNotifyEvent; AsLast: boolean);
    procedure RemoveHandlerOnResize(OnResizeEvent: TNotifyEvent);
    procedure AddHandlerOnChangeBounds(OnChangeBoundsEvent: TNotifyEvent;
                                       AsLast: boolean);
    procedure RemoveHandlerOnChangeBounds(OnChangeBoundsEvent: TNotifyEvent);
  public
    // standard properties, which should be supported by all descendents
    property Anchors: TAnchors read FAnchors write SetAnchors default [akLeft,akTop];
    property Action: TBasicAction read GetAction write SetAction;
    property Align: TAlign read FAlign write SetAlign;
    property BorderSpacing: TControlBorderSpacing read FBorderSpacing write SetBorderSpacing;
    property BoundsRect: TRect read GetBoundsRect write SetBoundsRect;
    property Caption: TCaption read GetText write SetText stored IsCaptionStored;
    property ClientOrigin: TPoint read GetClientOrigin;
    property ClientRect: TRect read GetClientRect;
    property ClientHeight: Integer read GetClientHeight write SetClientHeight stored False;
    property ClientWidth: Integer read GetClientWidth write SetClientWidth stored False;
    property Constraints: TSizeConstraints read FConstraints write SetConstraints;
    property ControlState: TControlState read FControlState write FControlState;
    property ControlStyle: TControlStyle read FControlStyle write FControlStyle;
    property Color: TColor read FColor write SetColor stored ColorIsStored default clWindow;
    property Enabled: Boolean read GetEnabled write SetEnabled stored IsEnabledStored default True;
    property Font: TFont read FFont write SetFont stored IsFontStored;
    property IsControl: Boolean read FIsControl write FIsControl;
    property OnResize: TNotifyEvent read FOnResize write FOnResize;
    property OnChangeBounds: TNotifyEvent read FOnChangeBounds write FOnChangeBounds;
    property OnClick: TNotifyEvent read FOnClick write FOnClick stored IsOnClickStored;
    property OnShowHint: TControlShowHintEvent read FOnShowHint write FOnShowHint;
    property Parent: TWinControl read FParent write SetParent;
    property PopupMenu: TPopupmenu read GetPopupmenu write SetPopupMenu;
    property ShowHint: Boolean read FShowHint write SetShowHint stored IsShowHintStored default False;
    property Visible: Boolean read FVisible write SetVisible stored IsVisibleStored default True;
    property WindowProc: TWndMethod read FWindowProc write FWindowProc;
    property TabStop: Boolean read FTabStop write SetTabStop;
    property TabOrder: TTabOrder read GetTabOrder write SetTaborder default -1;
  public
    // docking properties
    property DockOrientation: TDockOrientation read FDockOrientation write FDockOrientation;
    property Floating: Boolean read GetFloating;
    property FloatingDockSiteClass: TWinControlClass read GetFloatingDockSiteClass write FFloatingDockSiteClass;
    property HostDockSite: TWinControl read FHostDockSite write SetHostDockSite;
    property LRDockWidth: Integer read GetLRDockWidth write FLRDockWidth;
    property TBDockHeight: Integer read GetTBDockHeight write FTBDockHeight;
    property UndockHeight: Integer read GetUndockHeight write FUndockHeight;
    property UndockWidth: Integer read GetUndockWidth write FUndockWidth;
  published
    property Cursor: TCursor read FCursor write SetCursor default crDefault;
    property Left: Integer read FLeft write SetLeft;
    property Height: Integer read FHeight write SetHeight;
    property Hint: String read FHint write SetHint;
    property Top: Integer read FTop write SetTop;
    property Width: Integer read FWidth write SetWidth;
    property HelpType: THelpType read FHelpType write FHelpType default htContext;
    property HelpKeyword: String read FHelpKeyword write SetHelpKeyword stored IsHelpKeyWordStored;
    property HelpContext: THelpContext read FHelpContext write SetHelpContext stored IsHelpContextStored;
  end;


  // Moved to LCLType to avoid unit circles
  // TCreateParams is part of the interface
  TCreateParams = LCLType.TCreateParams;

  TBorderWidth = 0..MaxInt;

  TGetChildProc = procedure(Child: TComponent) of Object;

  { TControlChildSizing }

  { LeftRightSpacing, TopBottomSpacing: integer;
        minimum space between left client border and left most childs.
        For example: ClientLeftRight=5 means childs Left position is at least 5.

    HorizontalSpacing, VerticalSpacing: integer;
        minimum space between each child horizontally
  }

  {   Defines how child controls are resized/aligned.

      cesAnchorAligning, cssAnchorAligning
        Anchors and Align work like Delphi. For example if Anchors property of
        the control is [akLeft], it means fixed distance between left border of
        parent's client area. [akRight] means fixed distance between right
        border of the control and the right border of the parent's client area.
        When the parent is resized the child is moved to keep the distance.
        [akLeft,akRight] means fixed distance to left border and fixed distance
        to right border. When the parent is resized, the controls width is
        changed (resized) to keep the left and right distance.
        Same for akTop,akBottom.

        Align=alLeft for a control means set Left leftmost, Top topmost and
        maximize Height. The width is kept, if akRight is not set. If akRight
        is set in the Anchors property, then the right distance is kept and
        the control's width is resized.
        If there several controls with Align=alLeft, they will not overlapp and
        be put side by side.
        Same for alRight, alTop, alBottom. (Always expand 3 sides).

        Align=alClient. The control will fill the whole remaining space.
        Setting two childs to Align=alClient does only make sense, if you set
        maximum Constraints.

        Order: First all alTop childs are resized, then alBottom, then alLeft,
        then alRight and finally alClient.

      cesScaleChilds, cssScaleChilds
        Scale childs, keep space between them fixed.
        Childs are resized to their normal/adviced size. If there is some space
        left in the client area of the parent, then the childs are scaled to
        fill the space. You can set maximum Constraints. Then the other childs
        are scaled more.
        For example: 3 child controls A, B, C with A.Width=10, B.Width=20 and
        C.Width=30 (total=60). If the Parent's client area has a ClientWidth of
        120, then the childs are scaled with Factor 2.
        If B has a maximum constraint width of 30, then first the childs will be
        scaled with 1.5 (A.Width=15, B.Width=30, C.Width=45). Then A and C
        (15+45=60 and 30 pixel space left) will be scaled by 1.5 again, to a
        final result of: A.Width=23, B.Width=30, C.Width=67 (23+30+67=120).

      cesHomogenousChildGrowth, cssHomogenousChildDecrease
        Enlarge childs equally.
        Childs are resized to their normal/adviced size. If there is some space
        left in the client area of the parent, then the remaining space is
        distributed equally to each child.
        For example: 3 child controls A, B, C with A.Width=10, B.Width=20 and
        C.Width=30 (total=60). If the Parent's client area has a ClientWidth of
        120, then 60/3=20 is added to each Child.
        If B has a maximum constraint width of 30, then first 10 is added to
        all childs (A.Width=20, B.Width=30, C.Width=40). Then A and C
        (20+40=60 and 30 pixel space left) will get 30/2=15 additional,
        resulting in: A.Width=35, B.Width=30, C.Width=55 (35+30+55=120).


      cesHomogenousSpaceGrowth
        Enlarge space between childs equally.
        Childs are resized to their normal/adviced size. If there is some space
        left in the client area of the parent, then the space between the childs
        if expanded.
        For example: 3 child controls A, B, C with A.Width=10, B.Width=20 and
        C.Width=30 (total=60). If the Parent's client area has a ClientWidth of
        120, then there will be 60/2=30 space between A and B and between
        B and C.
  }

  TChildControlEnlargeStyle = (
      cesAnchorAligning, // (like Delphi)
      cesScaleChilds, // scale childs, keep space between childs fixed
      cesHomogenousChildGrowth, // enlarge childs equally
      cesHomogenousSpaceGrowth  // enlarge space between childs equally
    );
  TChildControlShrinkStyle = (
      cssAnchorAligning, // (like Delphi)
      cssScaleChilds, // scale childs
      cssHomogenousChildDecrease // shrink childs equally
    );

  TControlChildSizing = class(TPersistent)
  private
    FControl: TControl;
    FEnlargeHorizontal: TChildControlEnlargeStyle;
    FEnlargeVertical: TChildControlEnlargeStyle;
    FHorizontalSpacing: integer;
    FLeftRightSpacing: integer;
    FOnChange: TNotifyEvent;
    FShrinkHorizontal: TChildControlShrinkStyle;
    FShrinkVertical: TChildControlShrinkStyle;
    FTopBottomSpacing: integer;
    FVerticalSpacing: integer;
    procedure SetEnlargeHorizontal(const AValue: TChildControlEnlargeStyle);
    procedure SetEnlargeVertical(const AValue: TChildControlEnlargeStyle);
    procedure SetHorizontalSpacing(const AValue: integer);
    procedure SetLeftRightSpacing(const AValue: integer);
    procedure SetShrinkHorizontal(const AValue: TChildControlShrinkStyle);
    procedure SetShrinkVertical(const AValue: TChildControlShrinkStyle);
    procedure SetTopBottomSpacing(const AValue: integer);
    procedure SetVerticalSpacing(const AValue: integer);
  protected
    procedure Change; dynamic;
  public
    constructor Create(OwnerControl: TControl);
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
    function IsEqual(Sizing: TControlChildSizing): boolean;
  public
    property Control: TControl read FControl;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property LeftRightSpacing: integer read FLeftRightSpacing write SetLeftRightSpacing;
    property TopBottomSpacing: integer read FTopBottomSpacing write SetTopBottomSpacing;
    property HorizontalSpacing: integer read FHorizontalSpacing write SetHorizontalSpacing;
    property VerticalSpacing: integer read FVerticalSpacing write SetVerticalSpacing;
    property EnlargeHorizontal: TChildControlEnlargeStyle read FEnlargeHorizontal
                           write SetEnlargeHorizontal default cesAnchorAligning;
    property EnlargeVertical: TChildControlEnlargeStyle read FEnlargeVertical
                             write SetEnlargeVertical default cesAnchorAligning;
    property ShrinkHorizontal: TChildControlShrinkStyle read FShrinkHorizontal
                            write SetShrinkHorizontal default cssAnchorAligning;
    property ShrinkVertical: TChildControlShrinkStyle read FShrinkVertical
                              write SetShrinkVertical default cssAnchorAligning;
  end;


  { TWinControlActionLink }

  TWinControlActionLink = class(TControlActionLink)
  protected
    procedure AssignClient(AClient: TObject); override;
    function IsHelpContextLinked: Boolean; override;
    procedure SetHelpContext(Value: THelpContext); override;
  end;

  TWinControlActionLinkClass = class of TWinControlActionLink;


  { TWinControl }

  TWinControlFlag = (
    wcfClientRectNeedsUpdate,
    wcfColorChanged,
    wcfFontChanged,
    wcfReAlignNeeded,
    wcfAligningControls,
    wcfEraseBackground
    );
  TWinControlFlags = set of TWinControlFlag;

  TWinControl = class(TControl)
  private
    FAlignLevel: Word;
    FBorderWidth: TBorderWidth;
    FBoundsLockCount: integer;
    FBoundsRealized: TRect;
    FBorderStyle: TBorderStyle;
    FBrush: TBrush;
    FAdjustClientRectRealized: TRect;
    FChildSizing: TControlChildSizing;
    FControls: TList;
    FDefWndProc: Pointer;
    FDockClients: TList;
    //FDockSite: Boolean;
    FDoubleBuffered: Boolean;
    FClientWidth: Integer;
    FClientHeight: Integer;
    FDockManager: TDockManager;
    FDockSite: Boolean;
    FFlags: TWinControlFlags;
    FOnDockDrop: TDockDropEvent;
    FOnDockOver: TDockOverEvent;
    //FUseDockManager : Boolean;
    FOnKeyDown: TKeyEvent;
    FOnKeyPress: TKeyPressEvent;
    FOnKeyUp: TKeyEvent;
    FOnMouseWheel: TMouseWheelEvent;
    FOnMouseWheelDown: TMouseWheelUpDownEvent;
    FOnMouseWheelUp: TMouseWheelUpDownEvent;
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FOnUnDock: TUnDockEvent;
    FParentWindow: hwnd;
    FParentCtl3D: Boolean;
    FRealizeBoundsLockCount: integer;
    FHandle: Hwnd;
    FShowing: Boolean;
    FShowingValid: Boolean;
    FTabList: TList;
    FUseDockManager: Boolean;
    FWinControls: TList;
    FCreatingHandle: Boolean; // Set when constructing the handle
                              // Only used for checking
    procedure AlignControl(AControl : TControl);
    function GetBrush: TBrush;
    function GetControl(const Index: Integer): TControl;
    function GetControlCount: Integer;
    function GetDockClientCount: Integer;
    function GetDockClients(Index: Integer): TControl;
    function GetHandle : HWND;
    function GetIsResizing: boolean;
    function GetTabOrder: TTabOrder;
    function GetVisibleDockClientCount: Integer;
    procedure SetChildSizing(const AValue: TControlChildSizing);
    procedure SetDockSite(const NewDockSite: Boolean);
    procedure SetHandle(NewHandle: HWND);
    procedure SetBorderWidth(Value : TBorderWidth);
    procedure SetParentCtl3D(Value : Boolean);
    procedure SetUseDockManager(const AValue: Boolean);
    procedure UpdateTabOrder(NewTabValue: TTabOrder);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
    function GetActionLinkClass: TControlActionLinkClass; override;
    procedure AdjustSize; override;
    procedure AdjustClientRect(var ARect: TRect); virtual;
    procedure AlignControls(AControl: TControl; var ARect: TRect); virtual;
    function DoAlignChildControls(TheAlign: TAlign; AControl: TControl;
                        AControlList: TList; var ARect: TRect): Boolean; virtual;
    procedure DoChildSizingChange(Sender: TObject); virtual;
    Function CanTab: Boolean; override;
    procedure DoDragMsg(var DragMsg: TCMDrag); override;
    Procedure CMDrag(var Message : TCMDrag); message CM_DRAG;
    procedure CMShowingChanged(var Message: TLMessage); message CM_SHOWINGCHANGED;
    procedure CMVisibleChanged(var TheMessage: TLMessage); message CM_VISIBLECHANGED;
    function  ContainsControl(Control: TControl): Boolean;
    procedure ControlsAligned; virtual;
    procedure DoSendBoundsToInterface; virtual;
    procedure RealizeBounds; virtual;
    procedure CreateSubClass(var Params: TCreateParams;ControlClassName: PChar);
//    procedure CreateComponent(TheOwner: TComponent); virtual;
    procedure DestroyComponent; virtual;
    procedure DoConstraintsChange(Sender : TObject); override;
    procedure DoSetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
    procedure DoAutoSize; Override;
    procedure GetChildren(Proc : TGetChildProc; Root : TComponent); override;
    function ChildClassAllowed(ChildClass: TClass): boolean; override;
    procedure PaintControls(DC: HDC; First: TControl);
    procedure PaintHandler(var TheMessage: TLMPaint);
    procedure PaintWindow(DC: HDC); virtual;
    procedure CreateBrush; virtual;
    procedure CMEnabledChanged(var Message: TLMessage); message CM_ENABLEDCHANGED;
    procedure CMShowHintChanged(var Message: TLMessage); message CM_SHOWHINTCHANGED;
    procedure WMEraseBkgnd(var Message : TLMEraseBkgnd); message LM_ERASEBKGND;
    procedure WMNotify(var Message: TLMNotify); message LM_NOTIFY;
    procedure WMSetFocus(var Message: TLMSetFocus); message LM_SETFOCUS;
    procedure WMKillFocus(var Message: TLMKillFocus); message LM_KILLFOCUS;
    procedure WMShowWindow(var Message: TLMShowWindow); message LM_SHOWWINDOW;
    procedure WMEnter(var Message: TLMEnter); message LM_ENTER;
    procedure WMExit(var Message: TLMExit); message LM_EXIT;
    procedure WMMouseWheel(var Message: TLMMouseEvent); message LM_MOUSEWHEEL;
    procedure WMKeyDown(var Message: TLMKeyDown); message LM_KEYDOWN;
    procedure WMKeyUp(var Message: TLMKeyUp); message LM_KEYUP;
    procedure WMChar(var Message: TLMChar); message LM_CHAR;
    procedure WMPaint(var Msg: TLMPaint); message LM_PAINT;
    procedure WMDestroy(var Message: TLMDestroy); message LM_DESTROY;
    procedure WMMove(var Message: TLMMove); message LM_MOVE;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
    procedure CNKeyDown(var Message: TLMKeyDown); message CN_KEYDOWN;
    procedure CNKeyUp(var Message: TLMKeyUp); message CN_KEYUP;

    procedure CreateParams(var Params: TCreateParams); virtual;
    procedure DestroyHandle; virtual;
    procedure DoEnter; dynamic;
    procedure DoExit; dynamic;
    procedure DoFlipChildren; dynamic;
    procedure KeyDown(var Key: Word; Shift : TShiftState); dynamic;
    procedure KeyPress(var Key: Char); dynamic;
    procedure KeyUp(var Key: Word; Shift : TShiftState); dynamic;
    procedure ControlKeyDown(var Key: Word; Shift : TShiftState); dynamic;
    procedure MainWndProc(var Message : TLMessage);
    procedure ReAlign; // realign all childs
    procedure ReCreateWnd;
    procedure RemoveFocus(Removing: Boolean);
    function  RealGetText: TCaption; override;
    procedure RealSetText(const Value: TCaption); override;
    function GetBorderStyle: TBorderStyle;
    procedure SetBorderStyle(NewStyle: TBorderStyle); virtual;
    procedure UpdateControlState;
    procedure CreateHandle; virtual;
    procedure CreateWnd; virtual; //creates the window
    procedure InitializeWnd; virtual; //gets called after the window is created
    procedure ParentFormInitializeWnd; virtual; //gets called by InitializeWnd of parent form
    function ParentHandlesAllocated: boolean; override;
    procedure Loaded; override;
    procedure DestroyWnd; virtual;
    procedure UpdateShowing; virtual;
    procedure Update; override;
    procedure ShowControl(AControl: TControl); virtual;
    procedure WndProc(var Message : TLMessage); override;
    procedure DoAddDockClient(Client: TControl; const ARect: TRect); dynamic;
    procedure DockOver(Source: TDragDockObject; X, Y: Integer;
                       State: TDragState; var Accept: Boolean); dynamic;
    procedure DoDockOver(Source: TDragDockObject; X, Y: Integer;
                         State: TDragState; var Accept: Boolean); dynamic;
    procedure DoRemoveDockClient(Client: TControl); dynamic;
    function  DoUnDock(NewTarget: TWinControl; Client: TControl): Boolean; dynamic;
    procedure GetSiteInfo(Client: TControl; var InfluenceRect: TRect;
                          MousePos: TPoint; var CanDock: Boolean); dynamic;
    procedure ReloadDockedControl(const AControlName: string;
                                  var AControl: TControl); dynamic;
    function  DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
                           MousePos: TPoint): Boolean; dynamic;
    function  DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; dynamic;
    function  DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; dynamic;
    function  DoKeyDown(var Message: TLMKey): Boolean;
    function  DoKeyPress(var Message: TLMKey): Boolean;
    function  DoKeyUp(var Message: TLMKey): Boolean;
    Function  FindNextControl(CurrentControl: TControl; GoForward,
                              CheckTabStop, CheckParent, OnlyWinControls
                              : Boolean) : TControl;
    Function  FindNextControl(CurrentControl: TWinControl; GoForward,
                              CheckTabStop, CheckParent: Boolean) : TWinControl;
    procedure FixupTabList;
    function  GetClientOrigin: TPoint; override;
    function  GetClientRect: TRect; override;
    function  GetChildsRect(Scrolled: boolean): TRect; override;
    function  GetDeviceContext(var WindowHandle: HWnd): HDC; override;
    function  IsControlMouseMsg(var TheMessage : TLMMouse): Boolean;
    procedure FontChanged(Sender: TObject); override;
    procedure SetColor(Value : TColor); override;
    procedure SetZOrderPosition(NewPosition: Integer); override;
    procedure SetZOrder(Topmost: Boolean); override;
    procedure SendMoveSizeMessages(SizeChanged, PosChanged: boolean); override;
  protected
    property BorderStyle: TBorderStyle read GetBorderStyle write SetBorderStyle default bsNone;
  public
    property BorderWidth: TBorderWidth read FBorderWidth write SetBorderWidth default 0;
    property ChildSizing: TControlChildSizing read FChildSizing write SetChildSizing;
    property DefWndProc: Pointer read FDefWndProc write FDefWndPRoc;
    property DockClientCount: Integer read GetDockClientCount;
    property DockClients[Index: Integer]: TControl read GetDockClients;
    property DockSite: Boolean read FDockSite write SetDockSite default False;
    property DockManager: TDockManager read FDockManager write FDockManager;
    property DoubleBuffered: Boolean read FDoubleBuffered write FDoubleBuffered;
    property IsResizing: Boolean read GetIsResizing;
    property OnDockDrop: TDockDropEvent read FOnDockDrop write FOnDockDrop;
    property OnDockOver: TDockOverEvent read FOnDockOver write FOnDockOver;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;
    property OnKeyUp: TKeyEvent read FOnKeyUp write FOnKeyUp;
    property OnMouseWheel: TMouseWheelEvent read FOnMouseWheel write FOnMouseWheel;
    property OnMouseWheelDown: TMouseWheelUpDownEvent read FOnMouseWheelDown write FOnMouseWheelDown;
    property OnMouseWheelUp: TMouseWheelUpDownEvent read FOnMouseWheelUp write FOnMouseWheelUp;
    property OnUnDock: TUnDockEvent read FOnUnDock write FOnUnDock;
    property ParentCtl3D: Boolean read FParentCtl3D write SetParentCtl3d default True;
    property UseDockManager: Boolean read FUseDockManager
                                     write SetUseDockManager default False;
    property VisibleDockClientCount: Integer read GetVisibleDockClientCount;
  public
    constructor Create(TheOwner: TComponent);override;
    constructor CreateParented(ParentWindow: HWnd);
    class function CreateParentedControl(ParentWindow: HWnd): TWinControl;
    destructor Destroy; override;
    procedure BeginUpdateBounds;
    procedure EndUpdateBounds;
    procedure LockRealizeBounds;
    procedure UnlockRealizeBounds;
    procedure DockDrop(Source: TDragDockObject; X, Y: Integer); dynamic;
    Function CanFocus : Boolean;
    Function ControlAtPos(const Pos : TPoint; AllowDisabled : Boolean): TControl;
    Function ControlAtPos(const Pos : TPoint;
      AllowDisabled, AllowWinControls: Boolean): TControl;
    Function ControlAtPos(const Pos : TPoint;
      AllowDisabled, AllowWinControls, OnlyClientAreas: Boolean): TControl; virtual;
    function GetControlIndex(AControl: TControl): integer;
    procedure SetControlIndex(AControl: TControl; NewIndex: integer);
    procedure DoAdjustClientRectChange;
    procedure InvalidateClientRectCache(WithChildControls: boolean);
    function ClientRectNeedsInterfaceUpdate: boolean;
    Function Focused : Boolean; override;
    Procedure BroadCast(var Message);
    procedure NotifyControls(Msg: Word);
    procedure DefaultHandler(var Message); override;
    Procedure DisableAlign;
    Procedure EnableAlign;
    function  GetTextLen: Integer; override;
    Procedure Invalidate; override;
    Procedure InsertControl(AControl: TControl);
    Procedure InsertControl(AControl: TControl; Index: integer);
    Procedure RemoveControl(AControl: TControl);
    Procedure Insert(AControl: TControl);
    Procedure Insert(AControl: TControl; Index: integer);
    Procedure Remove(AControl: TControl);
    procedure SetBounds(aLeft, aTop, aWidth, aHeight: integer); override;
    procedure Hide;
    procedure Repaint; override;
    Procedure SetFocus; override;
    Function FindChildControl(const ControlName: String): TControl;
    procedure FlipChildren(AllLevels: Boolean); dynamic;
    Procedure GetTabOrderList(List : TList);
    function HandleAllocated: Boolean;
    procedure HandleNeeded;
    function BrushCreated: Boolean;
    procedure EraseBackground(DC: HDC); virtual;
  public
    property BoundsLockCount: integer read FBoundsLockCount;
    property Brush: TBrush read GetBrush;
    property Controls[Index: Integer]: TControl read GetControl;
    property ControlCount: Integer read GetControlCount;
    property Handle: HWND read GetHandle write SetHandle;
    property Showing: Boolean read FShowing;
    property CachedClientWidth: integer read FClientWidth;
    property CachedClientHeight: integer read FClientHeight;
  end;


  { TGraphicControl }

  TGraphicControl = class(TControl)
  private
    FCanvas: TCanvas;
    FOnPaint: TNotifyEvent;
    procedure WMPaint(var Message: TLMPaint); message LM_PAINT;
  protected
    procedure Paint; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Canvas: TCanvas read FCanvas;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
  end;


  { TCustomControl }

  TCustomControl = class(TWinControl)
  private
    FCanvas: TCanvas;
  protected
    procedure WMPaint(var Message: TLMPaint); message LM_PAINT;
    procedure PaintWindow(DC: HDC); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DestroyComponent; override;
    procedure Paint; virtual;

    property Canvas: TCanvas read FCanvas write FCanvas;
    property BorderStyle;
  end;


  { TImageList }

  TImageList = class(TDragImageList)
  published
    property BkColor: TColor;
    Property Height;
    property Masked;
    Property Width;
    Property OnChange;
  end;


{ TDockZone }

  TDockTree = class;

  { TDockZone is a node in the TDockTree and encapsulates a region into which
    other zones are contained. }

  TDockZone = class
  private
    FChildControl: TControl;
    FChildCount: integer;
    FFirstChildZone: TDockZone;
    FTree: TDockTree;
    FZoneLimit: integer;
    FParentZone: TDockZone;
    FOrientation: TDockOrientation;
    FNextSibling: TDockZone;
    FPrevSibling: TDockZone;
    //FPrevSibling: TDockZone;
    function GetHeight: Integer;
    function GetLeft: Integer;
    function GetLimitBegin: Integer;
    function GetLimitSize: Integer;
    function GetTop: Integer;
    function GetVisible: Boolean;
    function GetVisibleChildCount: Integer;
    function GetWidth: Integer;
    function GetZoneLimit: Integer;
    procedure SetZoneLimit(const AValue: Integer);
    function IsOrientationValid: boolean;
    function GetNextVisibleZone: TDockZone;
  public
    constructor Create(TheTree: TDockTree);
    procedure ExpandZoneLimit(NewLimit: Integer);
    function FirstVisibleChild: TDockZone;
    function NextVisible: TDockZone;
    function PrevVisible: TDockZone;
    procedure ResetChildren;
    procedure ResetZoneLimits;
    procedure Update;
    property Tree: TDockTree read FTree;
    property ChildCount: Integer read FChildCount;
    property Height: Integer read GetHeight;
    property Left: Integer read GetLeft;
    property LimitBegin: Integer read GetLimitBegin;
    property LimitSize: Integer read GetLimitSize;
    property Top: Integer read GetTop;
    property Visible: Boolean read GetVisible;
    property VisibleChildCount: Integer read GetVisibleChildCount;
    property Width: Integer read GetWidth;
    property ZoneLimit: Integer read GetZoneLimit write SetZoneLimit;
  end;


  { TDockTree - a tree of TDockZones }

  TForEachZoneProc = procedure(Zone: TDockZone) of object;

  TDockTreeClass = class of TDockTree;

  TDockTreeFlag = (
    dtfUpdateAllNeeded
    );
  TDockTreeFlags = set of TDockTreeFlag;

  TDockTree = class(TDockManager)
  private
    FBorderWidth: Integer;
    FDockSite: TWinControl;
    FGrabberSize: Integer;
    FGrabbersOnTop: Boolean;
    FFlags: TDockTreeFlags;
    //FOldRect: TRect;
    FOldWndProc: TWndMethod;
    //FReplacementZone: TDockZone;
    //FScaleBy: Double;
    //FShiftScaleOrient: TDockOrientation;
    //FShiftBy: Integer;
    //FSizePos: TPoint;
    //FSizingDC: HDC;
    //FSizingWnd: HWND;
    //FSizingZone: TDockZone;
    FTopZone: TDockZone;
    FTopXYLimit: Integer;
    FUpdateCount: Integer;
    //FVersion: Integer;
    procedure WindowProc(var AMessage: TLMessage);
    procedure DeleteZone(Zone: TDockZone);
  protected
    procedure AdjustDockRect(AControl: TControl; var ARect: TRect); virtual;
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    procedure GetControlBounds(AControl: TControl; var CtlBounds: TRect); override;
    function HitTest(const MousePos: TPoint; var HTFlag: Integer): TControl; virtual;
    procedure InsertControl(AControl: TControl; InsertAt: TAlign;
                            DropCtl: TControl); override;
    procedure LoadFromStream(SrcStream: TStream); override;
    procedure PaintDockFrame(ACanvas: TCanvas; AControl: TControl;
                             const ARect: TRect); virtual;
    procedure PositionDockRect(AClient, DropCtl: TControl; DropAlign: TAlign;
                               var DockRect: TRect); override;
    procedure RemoveControl(AControl: TControl); override;
    procedure SaveToStream(DestStream: TStream); override;
    procedure SetReplacingControl(AControl: TControl); override;
    procedure ResetBounds(Force: Boolean); override;
    procedure UpdateAll;
    property DockSite: TWinControl read FDockSite write FDockSite;
  public
    constructor Create(TheDockSite: TWinControl); virtual;
    destructor Destroy; override;
    procedure PaintSite(DC: HDC); override;
  end;


  { TMouse }

  TMouse = class
    FCapture : HWND;
    FDragImmediate : Boolean;
    FDragThreshold : Integer;
    Procedure SetCapture(const Value : HWND);
    Function GetCapture : HWND;
    Procedure SetCursorPos(value : TPoint);
    Function GetCursorPos : TPoint;
    function GetIsDragging: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property Capture : HWND read GetCapture write SetCapture;
    property CursorPos : TPoint read GetCursorPos write SetCursorPos;
    property DragImmediate : Boolean read FDragImmediate write FDragImmediate default True;
    property DragThreshold : Integer read FDragThreshold write FDragThreshold default 5;
    property IsDragging: Boolean read GetIsDragging;
  end;


const
  AnchorAlign: array[TAlign] of TAnchors = (
    { alNone }
    [akLeft, akTop],
    { alTop }
    [akLeft, akTop, akRight],
    { alBottom }
    [akLeft, akRight, akBottom],
    { alLeft }
    [akLeft, akTop, akBottom],
    { alRight }
    [akRight, akTop, akBottom],
    { alClient }
    [akLeft, akTop, akRight, akBottom],
    { alCustom }
    [akLeft, akTop]
    );
  AlignNames: array[TAlign] of string = (
    'alNone', 'alTop', 'alBottom', 'alLeft', 'alRight', 'alClient', 'alCustom');


function CNSendMessage(LM_Message: integer; Sender: TObject; data: pointer) : integer;
function FindDragTarget(const Position: TPoint; AllowDisabled: Boolean): TControl;
Function FindControlAtPosition(const Position: TPoint; AllowDisabled: Boolean): TControl;
Function FindLCLWindow(const ScreenPos : TPoint) : TWinControl;
Function FindControl(Handle: hwnd): TWinControl;
Function FindOwnerControl(Handle: hwnd): TWinControl;
function FindLCLControl(const ScreenPos: TPoint) : TControl;

function SendAppMessage(Msg: Cardinal; WParam: WParam; LParam: LParam): Longint;
Procedure MoveWindowOrg(dc : hdc; X,Y : Integer);

procedure SetCaptureControl(Control : TControl);
function GetCaptureControl : TControl;
procedure CancelDrag;
procedure DragDone(Drop: Boolean);

var
  NewStyleControls : Boolean;
  Mouse : TMouse;

function CursorToString(Cursor: TCursor): string;
function StringToCursor(const S: string): TCursor;
procedure GetCursorValues(Proc: TGetStrProc);
function CursorToIdent(Cursor: Longint; var Ident: string): Boolean;
function IdentToCursor(const Ident: string; var Cursor: Longint): Boolean;

function GetKeyShiftState: TShiftState;

procedure Register;


implementation

uses
  WSControls, // Widgetset uses circle is allowed

  Forms, // the circle can't be broken without breaking Delphi compatibility
  Math;  // Math is in RTL and only a few functions are used.

var
  // The interface knows, which TWinControl has the capture. This stores
  // what child control of this TWinControl has actually the capture.
  CaptureControl: TControl;

procedure Register;
begin
  RegisterComponents('Common Controls',[TImageList]);
end;

{------------------------------------------------------------------------------
  CNSendMessage  - To be replaced
------------------------------------------------------------------------------}
function CNSendMessage(LM_Message: integer; Sender: TObject;
  Data: pointer): integer;
begin
  Result := SendMsgToInterface(LM_Message, Sender, Data);
end;

{------------------------------------------------------------------------------
  FindControl
  
  Returns the TWinControl associated with the Handle.
  This is very interface specific. Better use FindOwnerControl.
  
  Handle can also be a child handle, and does not need to be the Handle
  property of the Result.
  IMPORTANT: So, in most cases: Result.Handle <> Handle in the params.

------------------------------------------------------------------------------}
function FindControl(Handle: hwnd): TWinControl;
begin
  if Handle <> 0
  then Result := TWinControl(GetProp(Handle,'WinControl'))
  else Result := nil;
end;

{------------------------------------------------------------------------------
  FindOwnerControl

  Returns the TWinControl owning the Handle. Handle can also be a child handle,
  and does not need to be the Handle property of the Result.
  IMPORTANT: So, in most cases: Result.Handle <> Handle in the params.
------------------------------------------------------------------------------}
function FindOwnerControl(Handle: hwnd): TWinControl;
begin
  While Handle<>0 do begin
    Result:=FindControl(Handle);
    if Result<>nil then exit;
    Handle:=GetParent(Handle);
  end;
  Result:=nil;
end;

{------------------------------------------------------------------------------
  FindLCLControl

  Returns the TControl that it at the moment at the visible screen position.
  This is not reliable during resizing.
------------------------------------------------------------------------------}
function FindLCLControl(const ScreenPos: TPoint) : TControl;
var
  AWinControl: TWinControl;
  ClientPos: TPoint;
begin
  Result:=nil;
  // find wincontrol at mouse cursor
  AWinControl:=FindLCLWindow(ScreenPos);
  if AWinControl=nil then exit;
  // find control at mouse cursor
  ClientPos:=AWinControl.ScreenToClient(ScreenPos);
  Result:=AWinControl.ControlAtPos(ClientPos,true,true,false);
  if Result=nil then Result:=AWinControl;
end;

function SendAppMessage(Msg: Cardinal; WParam: WParam; LParam: LParam): Longint;
begin
  Result:=LCLProc.SendApplicationMessage(Msg,WParam,LParam);
end;

procedure MoveWindowOrg(dc : hdc; X, Y : Integer);
begin
  MoveWindowOrgEx(DC,X,Y);
end;

function CompareRect(R1, R2: PRect): Boolean;
begin
  Result:=(R1^.Left=R2^.Left) and (R1^.Top=R2^.Top) and
          (R1^.Bottom=R2^.Bottom) and (R1^.Right=R2^.Right);
  {if not Result then begin
    DebugLn(' DIFFER: ',R1^.Left,',',R1^.Top,',',R1^.Right,',',R1^.Bottom
      ,' <> ',R2^.Left,',',R2^.Top,',',R2^.Right,',',R2^.Bottom);
  end;}
end;


{-------------------------------------------------------------------------------
  function DoControlMsg(Handle: hwnd; var Message) : Boolean;
  
  Find the owner wincontrol and Perform the Message.
-------------------------------------------------------------------------------}
function DoControlMsg(Handle: hwnd; var Message) : Boolean;
var
  AWinControl: TWinControl;
begin
  Result := False;
  AWinControl := FindOwnerControl(Handle);
  if AWinControl <> nil then begin
    with TLMessage(Message) do
      AWinControl.Perform(Msg + CN_BASE, WParam, LParam);
    Result:= True;
  end;
end;

{------------------------------------------------------------------------------
  Function: FindLCLWindow
  Params:
  Returns:

 ------------------------------------------------------------------------------}
function FindLCLWindow(const ScreenPos: TPoint): TWinControl;
var
  Handle : HWND;
begin
  Handle := WindowFromPoint(ScreenPos);
  Result := FindOwnerControl(Handle);
end;

function FindDragTarget(const Position: TPoint;
  AllowDisabled: Boolean): TControl;
begin
  Result:=FindControlAtPosition(Position,AllowDisabled);
end;

{------------------------------------------------------------------------------
  Function: FindControlAtPosition
  Params:
  Returns:

 ------------------------------------------------------------------------------}
function FindControlAtPosition(const Position: TPoint;
  AllowDisabled: Boolean): TControl;
var
  WinControl: TWinControl;
  Control: TControl;
begin
  Result := nil;
  WinControl := FindLCLWindow(Position);
  if WinControl <> nil
  then begin
    Result := WinControl;
    Control := WinControl.ControlAtPos(WinControl.ScreenToClient(Position),
                                       AllowDisabled,true);
    if Control <> nil then Result := Control;
  end;
end;

{------------------------------------------------------------------------------
  Function: GetCaptureControl
  Params:
  Returns:

 ------------------------------------------------------------------------------}
function GetCaptureControl: TControl;
begin
  Result := FindOwnerControl(GetCapture);
  if (Result <> nil)
  and (CaptureControl <> nil)
  and (CaptureControl.Parent = Result)
  then Result := CaptureControl;
end;

procedure SetCaptureControl(Control : TControl);
var
  OldCaptureWinControl: TWinControl;
  NewCaptureWinControl: TWinControl;
begin
  if CaptureControl=Control then exit;
  if Control=nil then begin
    {$IFDEF VerboseMouseCapture}
    write('SetCaptureControl Only ReleaseCapture');
    {$ENDIF}
    // just unset the capturing, intf call not needed
    CaptureControl:=nil;
    ReleaseCapture;
    exit;
  end;
  OldCaptureWinControl:=FindOwnerControl(GetCapture);
  if Control is TWinControl then
    NewCaptureWinControl:=TWinControl(Control)
  else
    NewCaptureWinControl:=Control.Parent;
  if NewCaptureWinControl=nil then begin
    {$IFDEF VerboseMouseCapture}
    write('SetCaptureControl Only ReleaseCapture');
    {$ENDIF}
    // just unset the capturing, intf call not needed
    CaptureControl:=nil;
    ReleaseCapture;
    exit;
  end;
  if NewCaptureWinControl=OldCaptureWinControl then begin
    {$IFDEF VerboseMouseCapture}
    write('SetCaptureControl Keep WinControl ',NewCaptureWinControl.Name,':',NewCaptureWinControl.ClassName,
    ' switch Control ',Control.Name,':',Control.ClassName);
    {$ENDIF}
    // just change the CaptureControl, intf call not needed
    CaptureControl:=Control;
    exit;
  end;
  // switch capture control
  {$IFDEF VerboseMouseCapture}
    write('SetCaptureControl Switch to WinControl=',NewCaptureWinControl.Name,':',NewCaptureWinControl.ClassName,
    ' and Control=',Control.Name,':',Control.ClassName);
  {$ENDIF}
  CaptureControl:=Control;
  ReleaseCapture;
  SetCapture(TWinControl(NewCaptureWinControl).Handle);
end;

function GetKeyShiftState: TShiftState;
begin
  Result:=[];
  if (GetKeyState(VK_CONTROL) and $8000)<>0 then
    Include(Result,ssCtrl);
  if (GetKeyState(VK_SHIFT) and $8000)<>0 then
    Include(Result,ssShift);
  if (GetKeyState(VK_MENU) and $8000)<>0 then
    Include(Result,ssAlt);
end;

{ Cursor translation function }

const
  DeadCursors = 1;

const
  Cursors: array[0..21] of TIdentMapEntry = (
    (Value: crDefault;      Name: 'crDefault'),
    (Value: crArrow;        Name: 'crArrow'),
    (Value: crCross;        Name: 'crCross'),
    (Value: crIBeam;        Name: 'crIBeam'),
    (Value: crSizeNESW;     Name: 'crSizeNESW'),
    (Value: crSizeNS;       Name: 'crSizeNS'),
    (Value: crSizeNWSE;     Name: 'crSizeNWSE'),
    (Value: crSizeWE;       Name: 'crSizeWE'),
    (Value: crUpArrow;      Name: 'crUpArrow'),
    (Value: crHourGlass;    Name: 'crHourGlass'),
    (Value: crDrag;         Name: 'crDrag'),
    (Value: crNoDrop;       Name: 'crNoDrop'),
    (Value: crHSplit;       Name: 'crHSplit'),
    (Value: crVSplit;       Name: 'crVSplit'),
    (Value: crMultiDrag;    Name: 'crMultiDrag'),
    (Value: crSQLWait;      Name: 'crSQLWait'),
    (Value: crNo;           Name: 'crNo'),
    (Value: crAppStart;     Name: 'crAppStart'),
    (Value: crHelp;         Name: 'crHelp'),
    (Value: crHandPoint;    Name: 'crHandPoint'),
    (Value: crSizeAll;      Name: 'crSizeAll'),

    { Dead cursors }
    (Value: crSize;         Name: 'crSize'));

function CursorToString(Cursor: TCursor): string;
begin
  if not CursorToIdent(Cursor, Result) then FmtStr(Result, '%d', [Cursor]);
end;

function StringToCursor(const S: string): TCursor;
var
  L: Longint;
begin
  if not IdentToCursor(S, L) then L := StrToInt(S);
  Result := TCursor(L);
end;

procedure GetCursorValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  for I := Low(Cursors) to High(Cursors) - DeadCursors do Proc(Cursors[I].Name);
end;

function CursorToIdent(Cursor: Longint; var Ident: string): Boolean;
begin
  Result := IntToIdent(Cursor, Ident, Cursors);
end;

function IdentToCursor(const Ident: string; var Cursor: Longint): Boolean;
begin
  Result := IdentToInt(Ident, Cursor, Cursors);
end;

// turn off before includes !!
{$IFDEF ASSERT_IS_ON}
  {$UNDEF ASSERT_IS_ON}
  {$C-}
{$ENDIF}

{$I sizeconstraints.inc}
{$I dragdock.inc}
{$I basedragcontrolobject.inc}
{$I controlsproc.inc}
{$I controlcanvas.inc}
{$I wincontrol.inc}
{$I controlactionlink.inc}
{$I control.inc}
{$I graphiccontrol.inc}
{$I customcontrol.inc}
{$I dockzone.inc}
{$I docktree.inc}
{$I mouse.inc}
{$I dragobject.inc}

{ TControlBorderSpacing }

procedure TControlBorderSpacing.SetAround(const AValue: TSpacingSize);
begin
  if FAround=AValue then exit;
  FAround:=AValue;
  Change;
end;

procedure TControlBorderSpacing.SetBottom(const AValue: TSpacingSize);
begin
  if FBottom=AValue then exit;
  FBottom:=AValue;
  Change;
end;

procedure TControlBorderSpacing.SetLeft(const AValue: TSpacingSize);
begin
  if FLeft=AValue then exit;
  FLeft:=AValue;
  Change;
end;

procedure TControlBorderSpacing.SetRight(const AValue: TSpacingSize);
begin
  if FRight=AValue then exit;
  FRight:=AValue;
  Change;
end;

procedure TControlBorderSpacing.SetTop(const AValue: TSpacingSize);
begin
  if FTop=AValue then exit;
  FTop:=AValue;
  Change;
end;

constructor TControlBorderSpacing.Create(OwnerControl: TControl);
begin
  FControl:=OwnerControl;
  inherited Create;
end;

procedure TControlBorderSpacing.Assign(Source: TPersistent);
var
  SrcSpacing: TControlBorderSpacing;
begin
  if Source is TControlBorderSpacing then begin
    SrcSpacing:=TControlBorderSpacing(Source);
    if IsEqual(SrcSpacing) then exit;
    
    FAround:=SrcSpacing.Around;
    FBottom:=SrcSpacing.Bottom;
    FLeft:=SrcSpacing.Left;
    FRight:=SrcSpacing.Right;
    FTop:=SrcSpacing.Top;
    
    Change;
  end else
    inherited Assign(Source);
end;

procedure TControlBorderSpacing.AssignTo(Dest: TPersistent);
begin
  Dest.Assign(Self);
end;

function TControlBorderSpacing.IsEqual(Spacing: TControlBorderSpacing
  ): boolean;
begin
  Result:=(FAround=Spacing.Around)
      and (FBottom=Spacing.Bottom)
      and (FLeft=Spacing.Left)
      and (FRight=Spacing.Right)
      and (FTop=Spacing.Top);
end;

procedure TControlBorderSpacing.Change;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

{ TControlChildSizing }

procedure TControlChildSizing.SetEnlargeHorizontal(
  const AValue: TChildControlEnlargeStyle);
begin
  if FEnlargeHorizontal=AValue then exit;
  FEnlargeHorizontal:=AValue;
  Change;
end;

procedure TControlChildSizing.SetEnlargeVertical(
  const AValue: TChildControlEnlargeStyle);
begin
  if FEnlargeVertical=AValue then exit;
  FEnlargeVertical:=AValue;
  Change;
end;

procedure TControlChildSizing.SetHorizontalSpacing(const AValue: integer);
begin
  if FHorizontalSpacing=AValue then exit;
  FHorizontalSpacing:=AValue;
  Change;
end;

procedure TControlChildSizing.SetLeftRightSpacing(const AValue: integer);
begin
  if FLeftRightSpacing=AValue then exit;
  FLeftRightSpacing:=AValue;
  Change;
end;

procedure TControlChildSizing.SetShrinkHorizontal(
  const AValue: TChildControlShrinkStyle);
begin
  if FShrinkHorizontal=AValue then exit;
  FShrinkHorizontal:=AValue;
  Change;
end;

procedure TControlChildSizing.SetShrinkVertical(
  const AValue: TChildControlShrinkStyle);
begin
  if FShrinkVertical=AValue then exit;
  FShrinkVertical:=AValue;
  Change;
end;

procedure TControlChildSizing.SetTopBottomSpacing(const AValue: integer);
begin
  if FTopBottomSpacing=AValue then exit;
  FTopBottomSpacing:=AValue;
  Change;
end;

procedure TControlChildSizing.SetVerticalSpacing(const AValue: integer);
begin
  if FVerticalSpacing=AValue then exit;
  FVerticalSpacing:=AValue;
  Change;
end;

constructor TControlChildSizing.Create(OwnerControl: TControl);
begin
  FControl:=OwnerControl;
  inherited Create;
  FEnlargeHorizontal:=cesAnchorAligning;
  FEnlargeVertical:=cesAnchorAligning;
  FShrinkHorizontal:=cssAnchorAligning;
  FShrinkVertical:=cssAnchorAligning;
end;

procedure TControlChildSizing.Assign(Source: TPersistent);
var
  SrcSizing: TControlChildSizing;
begin
  if Source is TControlChildSizing then begin
    SrcSizing:=TControlChildSizing(Source);
    if IsEqual(SrcSizing) then exit;

    FEnlargeHorizontal:=SrcSizing.EnlargeHorizontal;
    FEnlargeVertical:=SrcSizing.EnlargeVertical;
    FShrinkHorizontal:=SrcSizing.ShrinkHorizontal;
    FShrinkVertical:=SrcSizing.ShrinkVertical;
    FEnlargeHorizontal:=SrcSizing.EnlargeHorizontal;
    FEnlargeVertical:=SrcSizing.EnlargeVertical;
    FShrinkHorizontal:=SrcSizing.ShrinkHorizontal;
    FShrinkVertical:=SrcSizing.ShrinkVertical;

    Change;
  end else
    inherited Assign(Source);
end;

procedure TControlChildSizing.AssignTo(Dest: TPersistent);
begin
  Dest.Assign(Self);
end;

function TControlChildSizing.IsEqual(Sizing: TControlChildSizing): boolean;
begin
  Result:=(FEnlargeHorizontal=Sizing.EnlargeHorizontal)
      and (FEnlargeVertical=Sizing.EnlargeVertical)
      and (FShrinkHorizontal=Sizing.ShrinkHorizontal)
      and (FShrinkVertical=Sizing.ShrinkVertical)
      and (FEnlargeHorizontal=Sizing.EnlargeHorizontal)
      and (FEnlargeVertical=Sizing.EnlargeVertical)
      and (FShrinkHorizontal=Sizing.ShrinkHorizontal)
      and (FShrinkVertical=Sizing.ShrinkVertical);
end;

procedure TControlChildSizing.Change;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

initialization

  //DebugLn('controls.pp - initialization');
  Mouse := TMouse.create;
  DragControl := nil;
  CaptureControl := nil;

  RegisterIntegerConsts(TypeInfo(TCursor), @IdentToCursor, @CursorToIdent);

finalization
  Mouse.Free;

end.

{ =============================================================================

  $Log$
  Revision 1.206  2004/05/30 20:17:55  vincents
  changed radiobutton style to BS_RADIOBUTTON to prevent test program from hanging.

  Revision 1.205  2004/05/30 14:02:30  mattias
  implemented OnChange for TRadioButton, TCheckBox, TToggleBox and some more docking stuff

  Revision 1.204  2004/05/22 14:35:32  mattias
  fixed button return key

  Revision 1.203  2004/05/21 18:34:44  mattias
  readded protected TWinControl.BorderStyle

  Revision 1.202  2004/05/21 18:12:17  mattias
  quick fixed crashing property overloading BorderStyle

  Revision 1.201  2004/05/21 09:03:54  micha
  implement new borderstyle
  - centralize to twincontrol (protected)
  - public expose at tcustomcontrol to let interface access it

  Revision 1.200  2004/05/11 12:16:47  mattias
  replaced writeln by debugln

  Revision 1.199  2004/05/11 09:49:46  mattias
  started sending CN_KEYUP

  Revision 1.198  2004/04/26 10:01:27  mattias
  fixed TSynEdit.RealGetText

  Revision 1.197  2004/04/20 23:39:01  marc
  * Fixed setting of TWincontrol.Text during load

  Revision 1.196  2004/04/18 23:55:39  marc
  * Applied patch from Ladislav Michl
  * Changed the way TControl.Text is resolved
  * Added setting of text to TWSWinControl

  Revision 1.195  2004/04/11 10:19:28  micha
  cursor management updated:
  - lcl notifies interface via WSControl.SetCursor of changes
  - fix win32 interface to respond to wm_setcursor callback and set correct cursor

  Revision 1.194  2004/04/09 23:52:01  mattias
  fixed hiding uninitialized controls

  Revision 1.193  2004/04/04 12:32:21  mattias
  TWinControl.CanTab now checks for CanFocus

  Revision 1.192  2004/03/25 14:07:24  vincents
  use only key down (not toggle) state in GetKeyState

  Revision 1.191  2004/03/19 00:03:14  marc
  * Moved the implementation of (GTK)ButtonCreateHandle to the new
    (GTK)WSButton class

  Revision 1.190  2004/03/17 00:34:37  marc
  * Interface reconstruction. Created skeleton units, classes and wscontrols

  Revision 1.189  2004/03/15 09:06:57  mattias
  added FindDragTarget

  Revision 1.188  2004/03/08 22:36:01  mattias
  added TWinControl.ParentFormInitializeWnd

  Revision 1.187  2004/03/07 09:37:20  mattias
  added workaround for AutoSize in TCustomLabel

  Revision 1.186  2004/02/28 00:34:35  mattias
  fixed CreateComponent for buttons, implemented basic Drag And Drop

  Revision 1.185  2004/02/27 00:42:41  marc
  * Interface CreateComponent splitup
  * Implemented CreateButtonHandle on GTK interface
    on win32 interface it still needs to be done
  * Changed ApiWizz to support multilines and more interfaces

  Revision 1.184  2004/02/24 21:53:12  mattias
  added StdActns definitions, no code yet

  Revision 1.183  2004/02/23 23:15:12  mattias
  improved FindDragTarget

  Revision 1.182  2004/02/23 18:24:38  mattias
  completed new TToolBar

  Revision 1.181  2004/02/23 08:19:04  micha
  revert intf split

  Revision 1.179  2004/02/22 15:39:43  mattias
  fixed error handling on saving lpi file

  Revision 1.178  2004/02/22 10:43:20  mattias
  added child-parent checks

  Revision 1.177  2004/02/21 15:37:33  mattias
  moved compiler options to project menu, added -CX for smartlinking

  Revision 1.176  2004/02/17 00:32:25  mattias
  fixed TCustomImage.DoAutoSize fixing uninitialized vars

  Revision 1.175  2004/02/13 15:49:54  mattias
  started advanced LCL auto sizing

  Revision 1.174  2004/02/12 18:09:10  mattias
  removed win32 specific TToolBar code in new TToolBar, implemented TWinControl.FlipChildren

  Revision 1.173  2004/02/04 23:30:18  mattias
  completed TControl actions

  Revision 1.172  2004/02/02 16:59:28  mattias
  more Actions  TAction, TBasicAction, ...

  Revision 1.171  2004/02/02 12:44:45  mattias
  implemented interface constraints

  Revision 1.170  2004/02/02 11:07:43  mattias
  constraints and aligning now work together

  Revision 1.169  2004/02/02 00:41:06  mattias
  TScrollBar now automatically checks Align and Anchors for useful values

  Revision 1.168  2004/01/27 21:32:11  mattias
  improved changing style of controls

  Revision 1.167  2004/01/07 18:05:46  micha
  add TWinControl.DoubleBuffered property which is a hint for the interface to do double-buffering for this control

  Revision 1.166  2004/01/03 23:14:59  mattias
  default font can now change height and fixed gtk crash

  Revision 1.165  2004/01/03 21:06:05  micha
  - fix win32/checklistbox
  - implement proper lcl to interface move/size notify via setwindowpos
  - fix treeview to use inherited canvas from customcontrol
  - implement double buffering in win32

  Revision 1.164  2004/01/03 18:16:25  mattias
  set DragCursor props to default

  Revision 1.163  2003/12/29 14:22:22  micha
  fix a lot of range check errors win32

  Revision 1.162  2003/12/27 20:15:15  mattias
  set some colors to default

  Revision 1.161  2003/12/25 14:17:07  mattias
  fixed many range check warnings

  Revision 1.160  2003/12/23 16:50:45  micha
  fix defocus control when destroying it

  Revision 1.159  2003/12/14 19:18:03  micha
  hint fixes: parentfont, font itself, showing/hiding + more

  Revision 1.158  2003/11/22 17:22:14  mattias
  moved TBevelCut to controls.pp

  Revision 1.157  2003/11/03 16:57:47  peter
    * change $ifdef ver1_1 to $ifndef ver1_0 so it works also with
      fpc 1.9.x

  Revision 1.156  2003/10/16 19:43:44  ajgenius
  disable Buffering in TWinControl.WM_PAINT

  Revision 1.155  2003/10/06 10:50:10  mattias
  added recursion to InvalidateClientRectCache

  Revision 1.154  2003/09/26 06:59:59  mattias
  implemented GetBrush

  Revision 1.153  2003/09/23 17:52:04  mattias
  added SetAnchors

  Revision 1.152  2003/09/23 08:00:46  mattias
  improved OnEnter for gtkcombo

  Revision 1.151  2003/09/20 13:27:49  mattias
  varois improvements for ParentColor from Micha

  Revision 1.150  2003/09/18 09:21:03  mattias
  renamed LCLLinux to LCLIntf

  Revision 1.149  2003/09/13 15:51:21  mattias
  implemented parent color from Micha

  Revision 1.148  2003/09/02 08:39:16  mattias
  added italian localization

  Revision 1.147  2003/08/27 20:55:51  mattias
  fixed updating codetools on changing pkg output dir

  Revision 1.146  2003/08/27 11:01:10  mattias
  started TDockTree

  Revision 1.145  2003/08/26 20:30:39  mattias
  fixed updating component tree on delete component

  Revision 1.144  2003/08/25 16:18:15  mattias
  fixed background color of TPanel and clicks of TSpeedButton from Micha

  Revision 1.143  2003/08/23 21:17:08  mattias
  several fixes for the win32 intf, added pending OnResize events

  Revision 1.142  2003/08/23 11:30:50  mattias
  fixed SetComboHeight in win32 intf and finddeclaration of overloaded proc definition

  Revision 1.141  2003/08/21 13:04:10  mattias
  implemented insert marks for TTreeView

  Revision 1.140  2003/08/14 15:31:42  mattias
  started TTabSheet and TPageControl

  Revision 1.139  2003/08/04 08:43:20  mattias
  fixed breaking circle in ChangeBounds

  Revision 1.138  2003/07/30 13:03:44  mattias
  replaced label with memo

  Revision 1.137  2003/07/24 06:54:32  mattias
  fixed anti circle mechnism for aligned controls

  Revision 1.136  2003/07/04 10:12:16  mattias
  added default message handler to win32 interface

  Revision 1.135  2003/06/30 14:58:29  mattias
  implemented multi file add to package editor

  Revision 1.134  2003/06/27 23:42:38  mattias
  fixed TScrollBar resizing

  Revision 1.133  2003/06/25 18:12:32  mattias
  added docking properties

  Revision 1.132  2003/06/23 09:42:09  mattias
  fixes for debugging lazarus

  Revision 1.131  2002/08/19 15:15:23  mattias
  implemented TPairSplitter

  Revision 1.130  2002/08/17 23:41:34  mattias
  many clipping fixes

  Revision 1.129  2003/06/18 11:21:06  mattias
  fixed taborder=0, implemented TabOrder Editor

  Revision 1.128  2003/06/13 21:08:53  mattias
  moved TColorButton to dialogs.pp

  Revision 1.127  2003/06/13 14:38:01  mattias
  fixed using streamed clientwith/height for child anchors

  Revision 1.126  2003/06/13 12:53:51  mattias
  fixed TUpDown and added handler lists for TControl

  Revision 1.125  2003/06/11 22:29:42  mattias
  fixed realizing bounds after loading form

  Revision 1.124  2003/06/10 17:23:34  mattias
  implemented tabstop

  Revision 1.123  2003/06/10 12:28:23  mattias
  fixed anchoring controls

  Revision 1.122  2003/06/10 00:46:16  mattias
  fixed aligning controls

  Revision 1.121  2003/06/01 21:37:18  mattias
  fixed streaming TDataModule in programs

  Revision 1.120  2003/06/01 21:09:09  mattias
  implemented datamodules

  Revision 1.119  2003/05/30 16:25:47  mattias
  started datamodule

  Revision 1.118  2003/05/24 08:51:41  mattias
  implemented designer close query

  Revision 1.117  2003/05/09 14:21:25  mattias
  added published properties for gtkglarea

  Revision 1.116  2003/05/03 09:53:33  mattias
  fixed popupmenu for component palette

  Revision 1.115  2003/04/11 08:09:26  mattias
  published TControl help properties

  Revision 1.114  2003/04/07 01:59:25  mattias
  implemented package iterations

  Revision 1.113  2003/04/04 16:35:24  mattias
  started package registration

  Revision 1.112  2003/04/04 09:19:22  mattias
  activated TDataSource

  Revision 1.111  2003/04/02 13:23:23  mattias
  fixed default font

  Revision 1.110  2003/03/25 10:45:40  mattias
  reduced focus handling and improved focus setting

  Revision 1.109  2003/03/17 23:39:30  mattias
  added TCheckGroup

  Revision 1.108  2003/03/17 08:51:09  mattias
  added IsWindowVisible

  Revision 1.107  2003/03/11 23:14:19  mattias
  added TControl.HandleObjectShouldBeVisible

  Revision 1.106  2003/03/11 22:56:41  mattias
  added visiblechanging

  Revision 1.105  2003/03/11 07:46:43  mattias
  more localization for gtk- and win32-interface and lcl

  Revision 1.104  2003/03/09 17:44:12  mattias
  finshed Make Resourcestring dialog and implemented TToggleBox

  Revision 1.103  2003/02/27 09:52:00  mattias
  published TImgList.Width and Height

  Revision 1.102  2003/02/26 12:44:52  mattias
  readonly flag is now only saved if user set

  Revision 1.101  2003/01/01 13:01:01  mattias
  fixed setcolor for streamed components

  Revision 1.100  2002/12/28 12:42:38  mattias
  focus fixes, reduced lpi size

  Revision 1.99  2002/12/27 18:18:05  mattias
  fixes for htmllite

  Revision 1.98  2002/12/27 17:46:04  mattias
  fixed SetColor

  Revision 1.97  2002/12/27 17:12:37  mattias
  added more Delphi win32 compatibility functions

  Revision 1.96  2002/12/25 10:21:05  mattias
  made Form.Close more Delphish, added some windows compatibility functions

  Revision 1.95  2002/12/18 17:52:18  mattias
  fixed lazarus xml files for fpc 1.1

  Revision 1.94  2002/02/09 01:48:23  mattias
  renamed TinterfaceObject.Init to AppInit and TWinControls can now contain childs in gtk

  Revision 1.93  2002/12/04 20:39:14  mattias
  patch from Vincent: clean ups and fixed crash on destroying window

  Revision 1.92  2002/11/29 15:14:47  mattias
  replaced many invalidates by invalidaterect

  Revision 1.91  2002/11/21 18:49:52  mattias
  started OnMouseEnter and OnMouseLeave

  Revision 1.90  2002/11/09 15:02:06  lazarus
  MG: fixed LM_LVChangedItem, OnShowHint, small bugs

  Revision 1.89  2002/11/06 15:59:24  lazarus
  MG: fixed codetools abort

  Revision 1.88  2002/11/05 21:21:35  lazarus
  MG: fixed moving button with LEFT and RIGHT in messagedlgs

  Revision 1.87  2002/11/05 20:03:41  lazarus
  MG: implemented hints

  Revision 1.86  2002/11/04 19:49:35  lazarus
  MG: added persistent hints for main ide bar

  Revision 1.85  2002/11/03 22:40:28  lazarus
  MG: fixed ControlAtPos

  Revision 1.84  2002/11/01 14:40:30  lazarus
  MG: fixed mouse coords on scrolling wincontrols

  Revision 1.83  2002/10/30 12:37:25  lazarus
  MG: mouse cursors are now allocated on demand

  Revision 1.82  2002/10/26 15:15:45  lazarus
  MG: broke LCL<->interface circles

  Revision 1.81  2002/10/26 11:20:30  lazarus
  MG: broke some interfaces.pp circles

  Revision 1.80  2002/10/26 11:05:59  lazarus
  MG: broke actnlist <-> forms circle

  Revision 1.79  2002/10/24 10:05:50  lazarus
  MG: broke graphics.pp <-> clipbrd.pp circle

  Revision 1.78  2002/10/14 15:55:47  lazarus
  MG: reduced output

  Revision 1.77  2002/10/14 15:22:57  lazarus
  MG: default all hints to off

  Revision 1.76  2002/10/09 11:46:04  lazarus
  MG: fixed loading TListView from stream

  Revision 1.75  2002/10/01 10:41:47  lazarus
  MG: fixed mem leak

  Revision 1.74  2002/09/29 15:08:37  lazarus
  MWE: Applied patch from "Andrew Johnson" <aj_genius@hotmail.com>
    Patch includes:
      -fixes Problems with hiding modal forms
      -temporarily fixes TCustomForm.BorderStyle in bsNone
      -temporarily fixes problems with improper tabbing in TSynEdit

  Revision 1.73  2002/09/27 20:52:20  lazarus
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

  Revision 1.72  2002/09/10 06:49:18  lazarus
  MG: scrollingwincontrol from Andrew

  Revision 1.71  2002/09/09 19:04:01  lazarus
  MG: started TTreeView dragging

  Revision 1.70  2002/09/09 14:01:05  lazarus
  MG: improved TScreen and ShowModal

  Revision 1.69  2002/09/08 10:01:59  lazarus
  MG: fixed streaming visible=false

  Revision 1.68  2002/09/06 22:32:20  lazarus
  Enabled cursor property + property editor.

  Revision 1.67  2002/09/05 12:11:42  lazarus
  MG: TNotebook is now streamable

  Revision 1.66  2002/09/03 08:07:17  lazarus
  MG: image support, TScrollBox, and many other things from Andrew

  Revision 1.65  2002/09/02 19:10:28  lazarus
  MG: TNoteBook now starts with no Page and TPage has no auto names

  Revision 1.64  2002/09/01 16:11:21  lazarus
  MG: double, triple and quad clicks now works

  Revision 1.63  2002/08/31 18:45:54  lazarus
  MG: added some property editors and started component editors

  Revision 1.62  2002/08/30 12:32:20  lazarus
  MG: MoveWindowOrgEx, Splitted FWinControls/FControls, TControl drawing, Better DesignerDrawing, ...

  Revision 1.61  2002/08/30 06:46:03  lazarus

  Use comboboxes. Use history. Prettify the dialog. Preselect text on show.
  Make the findreplace a dialog. Thus removing resiying code (handled by Anchors now anyway).
  Make Anchors work again and publish them for various controls.
  SelStart and Co. for TEdit, SelectAll procedure for TComboBox and TEdit.
  Clean up and fix some bugs for TComboBox, plus selection stuff.

  Revision 1.60  2002/08/24 12:54:59  lazarus
  MG: fixed mouse capturing, OI edit focus

  Revision 1.59  2002/08/23 19:00:15  lazarus
  MG: implemented Ctrl+Mouse links in source editor

  Revision 1.58  2002/08/22 16:22:39  lazarus
  MG: started debugging of mouse capturing

  Revision 1.57  2002/08/17 15:45:32  lazarus
  MG: removed ClientRectBugfix defines

  Revision 1.56  2002/08/07 09:55:29  lazarus
  MG: codecompletion now checks for filebreaks, savefile now checks for filedate

  Revision 1.55  2002/08/06 09:32:48  lazarus
  MG: moved TColor definition to graphtype.pp and registered TColor names

  Revision 1.54  2002/07/09 17:18:22  lazarus
  MG: fixed parser for external vars

  Revision 1.53  2002/06/21 15:41:56  lazarus
  MG: moved RectVisible, ExcludeClipRect and IntersectClipRect to interface dependent functions

  Revision 1.52  2002/06/19 19:46:08  lazarus
  MG: Form Editing: snapping, guidelines, modified on move/resize, creating components in csDesigning, ...

  Revision 1.51  2002/06/04 15:17:21  lazarus
  MG: improved TFont for XLFD font names

  Revision 1.50  2002/05/30 21:19:26  lazarus

  + implemented HasParent for TControl & changed TCustomForm.GetChildren
    accordingly (sorry, control.inc & customform.inc got wrong comment:-( )
    stoppok

  Revision 1.49  2002/05/24 07:16:31  lazarus
  MG: started mouse bugfix and completed Makefile.fpc

  Revision 1.48  2002/05/20 14:19:03  lazarus
  MG: activated the clientrect bugfixes

  Revision 1.47  2002/05/10 06:05:49  lazarus
  MG: changed license to LGPL

  Revision 1.46  2002/05/09 12:41:28  lazarus
  MG: further clientrect bugfixes

  Revision 1.45  2002/05/06 08:50:36  lazarus
  MG: replaced logo, increased version to 0.8.3a and some clientrectbugfix

  Revision 1.44  2002/04/24 16:11:17  lazarus
  MG: started new client rectangle

  Revision 1.43  2002/04/24 09:29:06  lazarus
  MG: fixed typos

  Revision 1.42  2002/04/22 13:07:44  lazarus
  MG: fixed AdjustClientRect of TGroupBox

  Revision 1.41  2002/04/21 06:53:54  lazarus
  MG: fixed save lrs to test dir

  Revision 1.40  2002/04/18 08:13:36  lazarus
  MG: added include comments

  Revision 1.39  2002/04/18 08:09:03  lazarus
  MG: added include comments

  Revision 1.38  2002/04/04 12:25:01  lazarus
  MG: changed except statements to more verbosity

  Revision 1.37  2002/03/31 23:20:37  lazarus
  MG: fixed initial size of TPage

  Revision 1.36  2002/03/29 17:12:52  lazarus
  MG: added Triple and Quad mouse clicks to lcl and synedit

  Revision 1.35  2002/03/25 17:59:19  lazarus
  GTK Cleanup
  Shane

  Revision 1.34  2002/03/16 21:40:54  lazarus
  MG: reduced size+move messages between lcl and interface

  Revision 1.33  2002/03/14 23:25:51  lazarus
  MG: fixed TBevel.Create and TListView.Destroy

  Revision 1.32  2002/03/13 22:48:16  lazarus
  Constraints implementation (first cut) and sizig - moving system rework to
  better match Delphi/Kylix way of doing things (the existing implementation
  worked by acident IMHO :-)

  Revision 1.31  2002/02/03 00:24:00  lazarus
  TPanel implemented.
  Basic graphic primitives split into GraphType package, so that we can
  reference it from interface (GTK, Win32) units.
  New Frame3d canvas method that uses native (themed) drawing (GTK only).
  New overloaded Canvas.TextRect method.
  LCLLinux and Graphics was split, so a bunch of files had to be modified.

  Revision 1.30  2002/01/04 21:07:49  lazarus
  MG: added TTreeView

  Revision 1.29  2002/01/01 18:38:36  lazarus
  MG: more wmsize messages :(

  Revision 1.28  2002/01/01 15:50:13  lazarus
  MG: fixed initial component aligning

  Revision 1.27  2001/12/08 08:54:45  lazarus
  MG: added TControl.Refresh

  Revision 1.26  2001/12/05 17:23:44  lazarus
  Added Calendar component
  Shane

  Revision 1.25  2001/11/10 10:48:00  lazarus
  MG: fixed set formicon on invisible forms

  Revision 1.24  2001/11/09 19:14:23  lazarus
  HintWindow changes
  Shane

  Revision 1.23  2001/10/31 16:29:21  lazarus
  Fixed the gtk mousemove bug where the control gets the coord's based on it's parent instead of itself.
  Shane

  Revision 1.22  2001/10/07 07:28:32  lazarus
  MG: fixed setpixel and TCustomForm.OnResize event

  Revision 1.21  2001/09/30 08:34:49  lazarus
  MG: fixed mem leaks and fixed range check errors

  Revision 1.20  2001/06/14 14:57:58  lazarus
  MG: small bugfixes and less notes

  Revision 1.19  2001/05/13 22:07:08  lazarus
  Implemented BringToFront / SendToBack.

  Revision 1.18  2001/03/27 21:12:53  lazarus
  MWE:
    + Turned on longstrings
    + modified memotest to add lines

  Revision 1.17  2001/03/26 14:58:31  lazarus
  MG: setwindowpos + bugfixes

  Revision 1.16  2001/03/19 14:00:50  lazarus
  MG: fixed many unreleased DC and GDIObj bugs

  Revision 1.14  2001/03/12 12:17:01  lazarus
  MG: fixed random function results

  Revision 1.13  2001/02/20 16:53:27  lazarus
  Changes for wordcompletion and many other things from Mattias.
  Shane

  Revision 1.12  2001/02/04 04:18:12  lazarus
  Code cleanup and JITFOrms bug fix.
  Shane

  Revision 1.11  2001/02/01 16:45:19  lazarus
  Started the code completion.
  Shane

  Revision 1.10  2001/01/23 23:33:54  lazarus
  MWE:
    - Removed old LM_InvalidateRect
    - did some cleanup in old  code
    + added some comments  on gtkobject data (gtkproc)

  Revision 1.9  2000/12/29 13:14:05  lazarus
  Using the lresources.pp and registering components.
  This is a major change but will create much more flexibility for the IDE.
  Shane

  Revision 1.8  2000/12/22 19:55:37  lazarus
  Added the Popupmenu code to the LCL.
  Now you can right click on the editor and a PopupMenu appears.
  Shane

  Revision 1.7  2000/12/20 17:35:58  lazarus
  Added GetChildren
  Shane

  Revision 1.6  2000/12/01 15:50:39  lazarus
  changed the TCOmponentInterface SetPropByName.  It works for a few properties, but not all.
  Shane

  Revision 1.5  2000/11/30 21:43:38  lazarus
  Changed TDesigner.  It's now notified when a control is added to it's CustomForm.
  It's created in main.pp when New Form is selected.

  Shane

  Revision 1.3  2000/11/27 18:52:37  lazarus
  Added the Object Inspector code.
  Added more form editor code.
  Shane

  Revision 1.2  2000/07/30 21:48:32  lazarus
  MWE:
    = Moved ObjectToGTKObject to GTKProc unit
    * Fixed array checking in LoadPixmap
    = Moved LM_SETENABLED to API func EnableWindow and EnableMenuItem
    ~ Some cleanup

  Revision 1.1  2000/07/13 10:28:23  michael
  + Initial import

  Revision 1.92  2000/07/09 20:18:55  lazarus
  MWE:
    + added new controlselection
    + some fixes
    ~ some cleanup

  Revision 1.91  2000/06/28 13:11:37  lazarus
  Fixed TNotebook so it gets page change events.  Shane

  Revision 1.90  2000/06/16 13:33:21  lazarus
  Created a new method for adding controls to the toolbar to be dropped onto the form!
  Shane

  Revision 1.89  2000/05/27 22:20:55  lazarus
  MWE & VRS:
    + Added new hint code

  Revision 1.88  2000/05/23 21:41:10  lazarus
  MWE:
    * Fixed (one ?) crash on close: Mouse is created/freed twice.
      Thanks to Vincent Snijders pointing at this.

  Revision 1.87  2000/05/14 21:56:11  lazarus
  MWE:
    + added local messageloop
    + added PostMessage
    * fixed Peekmessage
    * fixed ClientToScreen
    * fixed Flat style of Speedutton (TODO: Draw)
    + Added TApplicatio.OnIdle

  Revision 1.86  2000/05/10 22:52:57  lazarus
  MWE:
    = Moved some global api stuf to gtkobject

  Revision 1.85  2000/05/09 18:37:02  lazarus
  *** empty log message ***

  Revision 1.84  2000/05/09 12:52:02  lazarus
  *** empty log message ***

  Revision 1.83  2000/05/09 00:38:10  lazarus
  Changed writelns to Asserts.                          CAW

  Revision 1.82  2000/05/08 16:07:32  lazarus
  fixed screentoclient and clienttoscreen
  Shane

  Revision 1.80  2000/04/18 21:03:13  lazarus
  Added
  TControl.bringtofront
  Shane

  Revision 1.79  2000/04/18 14:02:32  lazarus
  Added Double Clicks.  Changed the callback in gtkcallback for the buttonpress event to check the event type.
  Shane

  Revision 1.78  2000/04/17 19:50:05  lazarus
  Added some compiler stuff built into Lazarus.
  This depends on the path to your compiler being correct in the compileroptions
  dialog.
  Shane

  Revision 1.77  2000/04/13 21:25:16  lazarus
  MWE:
    ~ Added some docu and did some cleanup.
  Hans-Joachim Ott <hjott@compuserve.com>:
    * TMemo.Lines works now.
    + TMemo has now a property Scrollbar.
    = TControl.GetTextBuf revised :-)
    + Implementation for CListBox columns added
    * Bug in TGtkCListStringList.Assign corrected.

  Revision 1.76  2000/04/10 15:05:30  lazarus
  Modified the way the MOuseCapture works.
  Shane

  Revision 1.74  2000/04/07 16:59:54  lazarus
  Implemented GETCAPTURE and SETCAPTURE along with RELEASECAPTURE.
  Shane

  Revision 1.73  2000/03/30 18:07:53  lazarus
  Added some drag and drop code
  Added code to change the unit name when it's saved as a different name.  Not perfect yet because if you are in a comment it fails.

  Shane

  Revision 1.72  2000/03/22 20:40:43  lazarus
  Added dragobject shell

  Revision 1.71  2000/03/20 20:08:33  lazarus
  Added a generic MOUSE class.
  Shane

  Revision 1.70  2000/03/15 20:15:31  lazarus
  MOdified TBitmap but couldn't get it to work
  Shane

  Revision 1.69  2000/03/15 00:51:57  lazarus
  MWE:
    + Added LM_Paint on expose
    + Added forced creation of gdkwindow if needed
    ~ Modified DrawFrameControl
    + Added BF_ADJUST support on DrawEdge
    - Commented out LM_IMAGECHANGED in TgtkObject.IntSendMessage3
       (It did not compile)

  Revision 1.68  2000/03/14 19:49:04  lazarus
  Modified the painting process for TWincontrol.  Now it runs throug it's FCONTROLS list and paints all them
  Shane

  Revision 1.67  2000/03/10 18:31:09  lazarus
  Added TSpeedbutton code
  Shane

  Revision 1.66  2000/03/06 00:05:05  lazarus
  MWE: Added changes from Peter Dyson <peter@skel.demon.co.uk> for a new
    release of mwEdit (0.92)

  Revision 1.65  2000/02/28 00:15:54  lazarus
  MWE:
    Fixed creation of visible componets at runtime. (when a new editor
      was created it didn't show up)
    Made the hiding/showing of controls more delphi compatible

  Revision 1.64  2000/02/24 21:15:30  lazarus
  Added TCustomForm.GetClientRect and RequestAlign to try and get the controls to align correctly when a MENU is present.  Not Complete yet.

  Fixed the bug in TEdit that caused it not to update it's text property.  I will have to
  look at TMemo to see if anything there was affected.

  Added SetRect to WinAPI calls
  Added AdjustWindowRectEx to WINAPI calls.
  Shane

  Revision 1.63  2000/02/22 22:19:49  lazarus
  TCustomDialog is a descendant of TComponent.
  Initial cuts a form's proper Close behaviour.

  Revision 1.62  2000/02/22 21:51:40  lazarus
  MWE: Removed some double (or triple) event declarations.
       The latest compiler doesn't like it

  Revision 1.61  2000/02/22 17:32:49  lazarus
  Modified the ShowModal call.
  For TCustomForm is simply sets the visible to true now and adds fsModal to FFormState.  In gtkObject.inc FFormState is checked.  If it contains fsModal then either gtk_grab_add or gtk_grab_remove is called depending on the value of VISIBLE.

  The same goes for TCustomDialog (open, save, font, color).
  I moved the Execute out of the individual dialogs and moved it into TCustomDialog and made it virtual because FONT needs to set some stuff before calling the inherited execute.
  Shane

  Revision 1.60  2000/02/19 18:11:59  lazarus
  More work on moving, resizing, forms' border style etc.

  Revision 1.59  2000/02/18 19:38:52  lazarus
  Implemented TCustomForm.Position
  Better implemented border styles. Still needs some tweaks.
  Changed TComboBox and TListBox to work again, at least partially.
  Minor cleanups.

  Revision 1.58  2000/01/18 21:47:00  lazarus
  Added OffSetRec

  Revision 1.57  2000/01/10 00:07:12  lazarus
  MWE:
    Added more scrollbar support for TWinControl
    Most signals for TWinContorl are jet connected to the wrong widget
      (now scrolling window, should be fixed)
    Added some cvs entries


}

