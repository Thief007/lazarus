{ $Id: winceint.pp 8004 2005-10-30 15:33:20Z micha $ }
{
 /***************************************************************************
                         WINCEINT.pp  -  WinCEInterface Object
                             -------------------



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

unit WinCEInt;

{$mode objfpc}{$H+}

interface

{$IFDEF Trace}
{$ASSERTIONS ON}
{$ENDIF}

// defining the following will print all messages as they are being handled
// valuable for investigation of message trees / interrelations
{ $define MSG_DEBUG}

{
  When editing this unit list, be sure to keep Windows listed first to ensure
  successful compilation.
}
Uses
  Windows, Classes, ComCtrls, Controls, Buttons, Dialogs, DynHashArray,
  ExtCtrls, Forms, GraphMath, GraphType, InterfaceBase, LCLIntf, LCLType,
  LMessages, StdCtrls, SysUtils, Graphics, Menus,Winceproc;
//roozbeh:the following makes some errors in wincewinapih that some procedures cannot be overriden!
//also causes some nasty problems too....
//why so many common names?just by changing units order program should not be ok or wrong...!!
//uses
//  Windows,Classes, Types, ComCtrls, Controls, Buttons, Dialogs, ExtCtrls, Forms,
//  GraphMath, GraphType, InterfaceBase, LCLIntf, LCLType, Winceproc,
//  LMessages, StdCtrls, SysUtils, Graphics, Menus;

(*const

  IDC_ARROW     = MakeIntResource(32512);
  IDC_IBEAM     = MakeIntResource(32513);
  IDC_WAIT      = MakeIntResource(32514);
  IDC_CROSS     = MakeIntResource(32515);
  IDC_UPARROW   = MakeIntResource(32516);
  IDC_SIZE      = MakeIntResource(32640);
  IDC_ICON      = MakeIntResource(32641);
  IDC_SIZENWSE  = MakeIntResource(32642);
  IDC_SIZENESW  = MakeIntResource(32643);
  IDC_SIZEWE    = MakeIntResource(32644);
  IDC_SIZENS    = MakeIntResource(32645);
  IDC_SIZEALL   = MakeIntResource(32646);
  IDC_NO        = MakeIntResource(32648);
  IDC_HAND      = MakeIntResource(32649);
  IDC_APPSTARTING = MakeIntResource(32650);
  IDC_HELP      = MakeIntResource(32651);

{
  These are add-ons, don't exist in windows itself!
  IDC_NODROP    = MakeIntResource(32767);
  IDC_DRAG      = MakeIntResource(32766);
  IDC_HSPLIT    = MakeIntResource(32765);
  IDC_VSPLIT    = MakeIntResource(32764);
  IDC_MULTIDRAG = MakeIntResource(32763);
  IDC_SQLWAIT   = MakeIntResource(32762);
  IDC_HANDPT    = MakeIntResource(32761);
}
  IDC_NODROP    = IDC_NO;
  IDC_DRAG      = IDC_ARROW;
  IDC_HSPLIT    = IDC_SIZEWE;
  IDC_VSPLIT    = IDC_SIZENS;
  IDC_MULTIDRAG = IDC_ARROW;
  IDC_SQLWAIT   = IDC_WAIT;
  IDC_HANDPT    = IDC_HAND;

  LclCursorToWin32CursorMap: array[crLow..crHigh] of PChar = (
  // uni-direction cursors are mapped to bidirection win32 cursors
     IDC_SIZENWSE, IDC_SIZENS, IDC_SIZENESW, IDC_SIZEWE, IDC_SIZEWE,
     IDC_SIZENESW, IDC_SIZENS, IDC_SIZENWSE, IDC_SIZEALL, IDC_HANDPT, IDC_HELP,
     IDC_APPSTARTING, IDC_NO, IDC_SQLWAIT, IDC_MULTIDRAG, IDC_VSPLIT,
     IDC_HSPLIT, IDC_NODROP, IDC_DRAG, IDC_WAIT, IDC_UPARROW, IDC_SIZEWE,
     IDC_SIZENWSE, IDC_SIZENS, IDC_SIZENESW, IDC_SIZE, IDC_IBEAM, IDC_CROSS,
     IDC_ARROW, IDC_ARROW, IDC_ARROW); *)

type
  { WinCE interface-object class }

  { TWinCEWidgetSet }

  TWinCEWidgetSet = class(TWidgetSet)
  private
    AppTerminated: Boolean;

    FAppHandle: HWND;//roozbeh:in win32 it was parrent of all..a window on taskbar

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

    procedure AllocAndCopy(const BitmapInfo: Windows.TBitmap; const BitmapHandle: HBITMAP;
      const SrcRect: TRect; var Data: PByte; var Size: Cardinal);
    procedure FillRawImageDescriptionColors(Desc: PRawImageDescription);
    procedure FillRawImageDescription(const BitmapInfo: Windows.TBitmap;
        Desc: PRawImageDescription);

//    FWaitHandleCount: dword;
//    FWaitHandles: array of HANDLE;
//    FWaitHandlers: array of TWaitHandler;
//    FWaitPipeHandlers: PPipeEventInfo;

    FThemesActive: boolean;
    
    Function WinRegister: Boolean;

  public
    { Constructor of the class }
    constructor Create;
    { Destructor of the class }
    destructor Destroy; override;
    { Initialize the API }
    procedure AppInit(var ScreenInfo: TScreenInfo); override;
    procedure AppMinimize; override;
    procedure AppBringToFront; override;
    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure SetDesigning(AComponent: TComponent); override;
    procedure AppProcessMessages; override;
    procedure AppWaitMessage; override;
    Procedure AppTerminate; override;
    Function  InitHintFont(HintFont: TObject): Boolean; override;
    Procedure AttachMenuToWindow(AMenuObject: TComponent); override;
    procedure AppRun(const ALoop: TApplicationMainLoop); override;


    // create and destroy
    function CreateComponent(Sender : TObject): THandle; override;
    function CreateTimer(Interval: integer; TimerFunc: TFNTimerProc) : integer; override;
    function DestroyTimer(TimerHandle: Integer) : boolean; override;

    procedure ShowHide(Sender: TObject);

    {$I wincewinapih.inc}
    {$I wincelclintfh.inc}

    property AppHandle: HWND read FAppHandle;
    property MessageFont: HFONT read FMessageFont;
    property ThemesActive: boolean read FThemesActive;//just for not removing all those refrences
  end;

 {$I wincelistslh.inc}


const
  BOOL_RESULT: Array[Boolean] Of String = ('False', 'True');
  ClsName: array[0..6] of WideChar = ('W','i','n','d','o','w',#0);
  EditClsName: array[0..4] of WideChar = ('E','D','I','T',#0);
  ButtonClsName: array[0..6] of WideChar = ('B','U','T','T','O','N',#0);
  LabelClsName: array[0..6] of WideChar = ('S','T','A','T','I','C',#0);
  ComboboxClsName: array[0..8] of WideChar = ('C','O','M','B','O','B','O','X',#0);
  TabControlClsName: array[0..15] of WideChar = ('S','y','s','T','a','b','C','o','n','t','r','o','l','3','2',#0);

  CP_UTF7                  = 65000;         { UTF-7 translation }
  CP_UTF8                  = 65001;         { UTF-8 translation }

function GetTopWindow(hWnd:HWND):HWND;

{ export for widgetset implementation }

function WindowProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
    LParam: Windows.LParam): LResult; stdcall;
function ComboBoxWindowProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
    LParam: Windows.LParam): LResult; stdcall;
function CallDefaultWindowProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
  LParam: Windows.LParam): LResult;

var
  WinCEWidgetSet: TWinCEWidgetSet;


implementation

uses
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To get as little as possible circles,
// uncomment only those units with implementation
////////////////////////////////////////////////////
// WinCEWSActnList,
// WinCEWSArrow,
 WinCEWSButtons,
// WinCEWSCalendar,
// WinCEWSCheckLst,
// WinCEWSCListBox,
 WinCEWSComCtrls,
// WinCEWSControls,
// WinCEWSDbCtrls,
// WinCEWSDBGrids,
// WinCEWSDialogs,
// WinCEWSDirSel,
// WinCEWSEditBtn,
// WinCEWSExtCtrls,
// WinCEWSExtDlgs,
// WinCEWSFileCtrl,
 WinCEWSForms,
// WinCEWSGrids,
// WinCEWSImgList,
// WinCEWSMaskEdit,
// WinCEWSMenus,//roozbeh:not yet ready for use!
// WinCEWSPairSplitter,
// WinCEWSSpin,
 WinCEWSStdCtrls,
 WinCEWSExtCtrls,
// WinCEWSToolwin,
////////////////////////////////////////////////////
  LCLProc;
type
  TMouseDownFocusStatus = (mfNone, mfFocusSense, mfFocusChanged);

var
  MouseDownTime: dword;
  MouseDownPos: TPoint;
  MouseDownWindow: HWND = 0;
  MouseDownFocusWindow: HWND;
  MouseDownFocusStatus: TMouseDownFocusStatus = mfNone;
  IgnoreNextCharWindow: HWND = 0;  // ignore next WM_(SYS)CHAR message
  ComboBoxHandleSizeWindow: HWND = 0;//just dont know the use ye

//roozbeh...move this to somewhere more meaningfull!
function GetTopWindow(hWnd:HWND):HWND;
begin
  Result := GetWindow(hWnd,GW_CHILD);
end;


{$I wincelistsl.inc}
{$I wincecallback.inc}
{$I winceobject.inc}
{$I wincewinapi.inc}
{$I wincelclintf.inc}

initialization

  Assert(False, 'Trace:WinCEint.pp - Initialization');

finalization
  Assert(False, 'Trace:WinCEint.pp - Finalization');

end.
