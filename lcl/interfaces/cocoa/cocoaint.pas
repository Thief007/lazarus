{
 /***************************************************************************
                    CocoaInt.pas  -  CocoaInterface Object
                    ----------------------------------------

                 Initial Revision  : Mon August 6th CST 2004


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

unit CocoaInt;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

interface

uses
  // rtl+ftl
  Types, Classes, SysUtils, Math,
  // carbon bindings
  MacOSAll,
  // interfacebase
  InterfaceBase, GraphType,
  // private
  CocoaAll, CocoaPrivate, CocoaUtils, CocoaGDIObjects, CocoaTextLayout,
  CocoaProc,
  // LCL
  LCLStrConsts, LMessages, LCLMessageGlue, LCLProc, LCLIntf, LCLType,
  Controls,
  IntfGraphics, Graphics, CocoaWSFactory;

type

  { TCocoaTimerObject }

  TCocoaTimerObject=objcclass(NSObject)
    func : TWSTimerProc;
    procedure timerEvent; message 'timerEvent';
    class function initWithFunc(afunc: TWSTimerProc): TCocoaTimerObject; message 'initWithFunc:';
  end;

  { TCocoaAppDelegate }

  TCocoaAppDelegate = objcclass(NSObject, NSApplicationDelegateProtocol)
    function applicationShouldTerminate(sender: NSApplication): NSApplicationTerminateReply; message 'applicationShouldTerminate:';
  end;

  { TCocoaWidgetSet }

  TCocoaWidgetSet = class(TWidgetSet)
  private
    FTerminating: Boolean;

    pool      : NSAutoreleasePool;
    FNSApp    : NSApplication;
    delegate  : TCocoaAppDelegate;
  protected
    function GetAppHandle: THandle; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    function LCLPlatform: TLCLPlatform; override;

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

    function CreateTimer(Interval: integer; TimerFunc: TWSTimerProc): THandle; override;
    function DestroyTimer(TimerHandle: THandle): boolean; override;

    {todo:}
    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure DCSetAntialiasing(CanvasHandle: HDC; AEnabled: Boolean); override;
    procedure SetDesigning(AComponent: TComponent); override;

    function RawImage_DescriptionFromCocoaBitmap(out ADesc: TRawImageDescription; ABitmap: TCocoaBitmap): Boolean;
    function RawImage_FromCocoaBitmap(out ARawImage: TRawImage; ABitmap, AMask: TCocoaBitmap; ARect: PRect = nil): Boolean;
    function RawImage_DescriptionToBitmapType(ADesc: TRawImageDescription; out bmpType: TCocoaBitmapType): Boolean;
//    function GetImagePixelData(AImage: CGImageRef; var bitmapByteCount: PtrUInt): Pointer;
    property NSApp: NSApplication read FNSApp;
    // the winapi compatibility methods
    {$I cocoawinapih.inc}
    // the extra LCL interface methods
    {$I cocoalclintfh.inc}
  end;
  
var
  CocoaWidgetSet: TCocoaWidgetSet;

implementation

var
  ScreenContext : TCocoaContext = nil;

// the implementation of the utility methods
{$I cocoaobject.inc}
// the implementation of the winapi compatibility methods
{$I cocoawinapi.inc}
// the implementation of the extra LCL interface methods
{$I cocoalclintf.inc}

initialization
//  {$I Cocoaimages.lrs}
  InternalInit;

finalization
  InternalFinal;

end.
