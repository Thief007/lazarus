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
{$ifdef Darwin}
{$modeswitch objectivec1}
{$endif}

{$I customdrawndefines.inc}

interface

uses
  // RTL
  Types, Classes, SysUtils, Math,
  {$ifdef CD_Windows}Windows, WinProc,{$endif}
  {$ifdef CD_Cocoa}MacOSAll, CocoaAll,{$endif}
  // Widgetset
   //CocoaPrivate, CocoaUtils, CocoaGDIObjects, CocoaTextLayout, CocoaProc,
  // LCL
  InterfaceBase, Translations,
  Controls,  Forms, lclproc,
  {Buttons, Dialogs, GraphMath, GraphType, LCLIntf,}
  LCLType, LMessages{, StdCtrls, Graphics, Menus };

type
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
    {$ifdef CD_WINDOWS}
    // In win32 it is: The parent of all windows, represents the button of the taskbar
    // In wince it is just an invisible window, but retains the following functions:
    // * This window is also the owner of the clipboard.
    // * Assoc. windowproc also acts as handler for popup menus
    // * It is indispensable for popupmenus and thread synchronization
    FAppHandle: HWND;

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

    {FWaitHandleCount: dword;
    FWaitHandles: array of HANDLE;
    FWaitHandlers: array of TWaitHandler;
    FWaitPipeHandlers: PPipeEventInfo;

    FOnAsyncSocketMsg: TSocketEvent;}
    {$endif}

    {$ifdef CD_Cocoa}
    FTerminating: Boolean;
    pool      : NSAutoreleasePool;
    NSApp     : NSApplication;
    delegate  : TCDAppDelegate;
    {$endif}
  protected
    {function CreateThemeServices: TThemeServices; override;
    function GetAppHandle: THandle; override;
    procedure SetAppHandle(const AValue: THandle); override;}
    //
    procedure BackendCreate;
    procedure BackendDestroy;
  public
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
    procedure AppSetTitle(const ATitle: string); override;
  (*
    procedure AppSetIcon(const Small, Big: HICON); override;
    procedure AppSetVisible(const AVisible: Boolean); override;
    function AppRemoveStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;
    function AppRestoreStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;
    procedure AppSetMainFormOnTaskBar(const DoSet: Boolean); override;

    function  InitStockFont(AFont: TObject; AStockFont: TStockFont): Boolean; override;

    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure SetDesigning(AComponent: TComponent); override;*)

    // create and destroy
    function CreateTimer(Interval: integer; TimerFunc: TWSTimerProc): THandle; override;
    function DestroyTimer(TimerHandle: THandle): boolean; override;

//    {$I win32winapih.inc}
//    {$I win32lclintfh.inc}
  end;

var
  CDWidgetSet: TCDWidgetSet absolute WidgetSet;

{$ifdef CD_WINDOWS}
function WindowProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
  LParam: Windows.LParam): LResult; stdcall;
{$endif}

implementation

uses
  WsControls, lclintf,
{  Win32WSFactory,
  Win32WSButtons,
  Win32WSMenus,
  Win32WSStdCtrls,
  Win32WSDialogs,
  Win32Themes,
////////////////////////////////////////////////////
  Win32Extra,} LCLMessageGlue;


//{$I win32winapi.inc}
//{$I win32lclintf.inc}

{$I customdrawnobject.inc}

{$ifdef CD_Windows}
  {$include wincallback.inc}
  {$I customdrawnobject_win.inc}
{$endif}
{$ifdef CD_Cocoa}
  {$I customdrawnobject_cocoa.inc}
{$endif}
{$ifdef CD_X11}
  {$I customdrawnobject_x11.inc}
{$endif}

initialization
  SystemCharSetIsUTF8:=true;
end.
