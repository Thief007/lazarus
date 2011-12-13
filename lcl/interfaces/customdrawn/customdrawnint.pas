{
 /***************************************************************************
                CustomDrawnInt.pas -  CustomDrawn Interface Object
                             -------------------

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

unit CustomDrawnInt;

{$mode objfpc}{$H+}

{$I customdrawndefines.inc}

interface

uses
  // RTL
  Types, Classes, SysUtils, Math,
  fpimage, fpcanvas, fpimgcanv, ctypes,
  {$ifdef CD_Windows}Windows, customdrawn_WinProc,{$endif}
  {$ifdef CD_Cocoa}MacOSAll, CocoaAll, CocoaPrivate, CocoaGDIObjects,{$endif}
  {$ifdef CD_X11}X, XLib, XUtil, customdrawn_x11proc,{unitxft, Xft font support}{$endif}
  {$ifdef CD_Android}
  customdrawn_androidproc, jni, bitmap, log,
  {$endif}
  // Widgetset
  customdrawnproc,
  // LCL
  customdrawn_common, customdrawncontrols, customdrawndrawers,
  lazcanvas, lazregions,
  InterfaceBase, Translations,
  Controls,  Forms, lclproc, IntfGraphics, GraphType,
  LCLType, LMessages, Graphics, LCLStrConsts;

type
  {$ifdef CD_Windows}
  PPPipeEventInfo = ^PPipeEventInfo;
  PPipeEventInfo = ^TPipeEventInfo;
  TPipeEventInfo = record
    Handle: THandle;
    UserData: PtrInt;
    OnEvent: TPipeEvent;
    Prev: PPipeEventInfo;
    Next: PPipeEventInfo;
  end;

  TWaitHandler = record
    ListIndex: pdword;
    UserData: PtrInt;
    OnEvent: TWaitHandleEvent;
  end;

  TSocketEvent = function(ASocket: THandle; Flags: dword): Integer of object;
  {$endif}
  {$ifdef CD_Cocoa}

  TCDTimerObject=objcclass(NSObject)
    func : TWSTimerProc;
    procedure timerEvent; message 'timerEvent';
    class function initWithFunc(afunc: TWSTimerProc): TCDTimerObject; message 'initWithFunc:';
  end;

  TCDAppDelegate = objcclass(NSObject, NSApplicationDelegateProtocol)
    function applicationShouldTerminate(sender: NSApplication): NSApplicationTerminateReply; message 'applicationShouldTerminate:';
  end;
  {$endif}

  { TCDWidgetSet }

  TCDWidgetSet = class(TWidgetSet)
  private
    FTerminating: Boolean;

    {$ifdef CD_WINDOWS}
    // In win32 it is: The parent of all windows, represents the button of the taskbar
    // In wince it is just an invisible window, but retains the following functions:
    // * This window is also the owner of the clipboard.
    // * Assoc. windowproc also acts as handler for popup menus
    // * It is indispensable for popupmenus and thread synchronization
    FAppHandle: THandle;

    FMetrics: TNonClientMetrics;
    FMetricsFailed: Boolean;

    FStockNullBrush: HBRUSH;
    FStockBlackBrush: HBRUSH;
    FStockLtGrayBrush: HBRUSH;
    FStockGrayBrush: HBRUSH;
    FStockDkGrayBrush: HBRUSH;
    FStockWhiteBrush: HBRUSH;

    FStatusFont: HFONT;
    FMessageFont: HFONT;

    FWaitHandleCount: dword;
    FWaitHandles: array of HANDLE;
    FWaitHandlers: array of TWaitHandler;
    FWaitPipeHandlers: PPipeEventInfo;

    FOnAsyncSocketMsg: TSocketEvent;

    function WinRegister: Boolean;
    procedure CreateAppHandle;
    {$endif}

    {$ifdef CD_Cocoa}
    pool      : NSAutoreleasePool;
    NSApp     : NSApplication;
    delegate  : TCDAppDelegate;
    {$endif}
  public
    {$ifdef CD_X11}
    FDisplayName: string;
    FDisplay: PDisplay;

    LeaderWindow: X.TWindow;
    ClientLeaderAtom: TAtom;

    FWMProtocols: TAtom;	  // Atom for "WM_PROTOCOLS"
    FWMDeleteWindow: TAtom;	  // Atom for "WM_DELETE_WINDOW"
    FWMHints: TAtom;		  // Atom for "_MOTIF_WM_HINTS"

    function FindWindowByXID(XWindowID: X.TWindow; out AWindowInfo: TX11WindowInfo): TWinControl;
    {$endif}
    {$ifdef CD_Android}
    procedure AndroidDebugLn(AStr: string);
    {$endif}
  // For generic methods added in customdrawn
  // They are used internally in LCL-CustomDrawn, LCL app should not use them
  public
    AccumulatedStr: string;
    // The currently focused control
    FocusedControl: TWinControl;
    // Default Fonts
    DefaultFont: TFPCustomFont;
    DefaultFontAndroidSize: Integer;
    // For unusual implementations of DebugLn/DebugOut
    procedure AccumulatingDebugOut(AStr: string);
    procedure CDSetFocusToControl(ALCLControl: TWinControl);
  //
  protected
    {function CreateThemeServices: TThemeServices; override;}
    {function GetAppHandle: THandle; override;
    procedure SetAppHandle(const AValue: THandle); override;}
    //
    procedure BackendCreate;
    procedure BackendDestroy;
  public
    // ScreenDC and Image for doing Canvas operations outside the Paint event
    // and also for text drawing operations
    ScreenDC: TLazCanvas;
    ScreenBitmapRawImage: TRawImage;
    ScreenBitmapHeight: Integer;
    ScreenBitmapWidth: Integer;
    ScreenImage: TLazIntfImage;

    constructor Create; override;
    destructor Destroy; override;

    function LCLPlatform: TLCLPlatform; override;
    function GetLCLCapability(ACapability: TLCLCapability): PtrUInt; override;

    { Initialize the API }
    procedure AppInit(var ScreenInfo: TScreenInfo); override;
    procedure AppRun(const ALoop: TApplicationMainLoop); override;
    procedure AppWaitMessage; override;
    procedure AppProcessMessages; override;
    procedure AppTerminate; override;
    procedure AppMinimize; override;
    procedure AppRestore; override;
    procedure AppBringToFront; override;
    procedure AppSetIcon(const Small, Big: HICON); override;
    procedure AppSetTitle(const ATitle: string); override;
    procedure AppSetVisible(const AVisible: Boolean); override;
    function AppRemoveStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;
    function AppRestoreStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;
    procedure AppSetMainFormOnTaskBar(const DoSet: Boolean); override;

    //function  InitStockFont(AFont: TObject; AStockFont: TStockFont): Boolean; override;

    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure DCSetAntialiasing(CanvasHandle: HDC; AEnabled: Boolean); override;
    procedure SetDesigning(AComponent: TComponent); override;

    // create and destroy
    function CreateTimer(Interval: integer; TimerFunc: TWSTimerProc): THandle; override;
    function DestroyTimer(TimerHandle: THandle): boolean; override;

    {$I customdrawnwinapih.inc}
    {$I customdrawnlclintfh.inc}
  end;

var
  CDWidgetSet: TCDWidgetSet absolute WidgetSet;

{$ifdef CD_WINDOWS}
function WindowProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
  LParam: Windows.LParam): LResult; stdcall;
{$endif}

{$ifdef CD_Android}
function Java_com_pascal_lclproject_LCLActivity_LCLOnTouch(env:PJNIEnv;this:jobject; x, y: single; action: jint): jint; cdecl;
function Java_com_pascal_lclproject_LCLActivity_LCLDrawToBitmap(
    env:PJNIEnv;this:jobject; width, height: jint; abitmap: jobject): jint; cdecl;
function Java_com_pascal_lclproject_LCLActivity_LCLOnCreate(
    env:PJNIEnv; this:jobject; alclactivity: jobject): jint; cdecl;
function Java_com_pascal_lclproject_LCLActivity_LCLOnMessageBoxFinished(
    env:PJNIEnv; this:jobject; AResult: jint): jint; cdecl;
function JNI_OnLoad(vm:PJavaVM;reserved:pointer):jint; cdecl;
procedure JNI_OnUnload(vm:PJavaVM;reserved:pointer); cdecl;

var
  javaVMRef: PJavaVM=nil;
  javaEnvRef: PJNIEnv=nil;
  javaActivityClass: JClass = nil;
  javaActivityObject: jobject = nil;

  // Fields of our Activity
  // Strings
  javaField_lcltext: JfieldID=nil;
  javaField_lcltitle: JfieldID=nil;
  javaField_lclbutton1str: JfieldID=nil;
  javaField_lclbutton2str: JfieldID=nil;
  javaField_lclbutton3str: JfieldID=nil;
  // Integers
  javaField_lclwidth: JfieldID=nil;
  javaField_lclheight: JfieldID=nil;
  javaField_lclbutton1: JfieldID=nil;
  javaField_lclbutton2: JfieldID=nil;
  javaField_lclbutton3: JfieldID=nil;
  javaField_lclbitmap: JfieldID=nil;
  javaField_lcltextsize: JfieldID=nil;
  // Text metrics
  javaField_lcltextascent: JfieldID=nil;
  javaField_lcltextbottom: JfieldID=nil;
  javaField_lcltextdescent: JfieldID=nil;
  javaField_lcltextleading: JfieldID=nil;
  javaField_lcltexttop: JfieldID=nil;

  // Methods of our Activity
  javaMethod_LCLDoGetTextBounds: jmethodid = nil;
  javaMethod_LCLDoDrawText: jmethodid = nil;
  javaMethod_LCLDoShowMessageBox: jmethodid = nil;

  // This is utilized to store the information such as invalidate requests in events
  eventResult: jint;
{$endif}

implementation

uses
  WsControls, lclintf,
  CustomDrawnWSFactory,
  CustomDrawnWSForms,
{  Win32WSButtons,
  Win32WSMenus,
  Win32WSStdCtrls,
  Win32WSDialogs,
  Win32Themes,
////////////////////////////////////////////////////
  Win32Extra,}
  customdrawnprivate,
  LCLMessageGlue;


{$I customdrawnobject.inc}

{$I customdrawnwinapi.inc}
{$I customdrawnlclintf.inc}

{$ifdef CD_Windows}
  {$include wincallback.inc}
  {$I customdrawnobject_win.inc}
  {$I customdrawnwinapi_win.inc}
{$endif}
{$ifdef CD_Cocoa}
  {$I customdrawnobject_cocoa.inc}
  {$I customdrawnwinapi_cocoa.inc}
{$endif}
{$ifdef CD_X11}
  {$I customdrawnobject_x11.inc}
  {$I customdrawnwinapi_x11.inc}
{$endif}
{$ifdef CD_Android}
  {$I customdrawnobject_android.inc}
  {$I customdrawnwinapi_android.inc}
{$endif}

end.
