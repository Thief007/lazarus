{
 /***************************************************************************
                         WIN32INT.pp  -  Win32Interface Object
                             -------------------



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

Unit Win32Int;

{$mode objfpc}{$H+}

Interface

{$IFDEF Trace}
{$ASSERTIONS ON}
{$ENDIF}

{
  When editing this unit list, be sure to keep Windows listed first to ensure
  successful compilation.
}
Uses
  Windows, Classes, LCLStrConsts, ComCtrls, Controls, Dialogs, DynHashArray,
  ExtCtrls, Forms, GraphMath, GraphType, InterfaceBase, LCLIntf, LCLType,
  LMessages, StdCtrls, SysUtils, VCLGlobals, Win32Def, Graphics, Menus;

Type
  { Virtual alignment-control record }
  TAlignment = Record
    Parent: HWnd;     // Parent Control
    Self: HWnd;       // Virtual control handle of alignment
    XAlign: Integer;  // Horizontal alignment
    YAlign: Integer;  // Vertical alignment
    XScale: Real;     // Horizontal scaling
    YScale: Real;     // Vertical scaling
  End;

  { Win32 interface-object class }
  TWin32Object = Class(TInterfaceBase)
  Private
    FAccelGroup: HACCEL;
    FAppHandle: HWND;    // The parent of all windows, represents the button of the taskbar
                         // Assoc. windowproc also acts as handler for popup menus
    FWin32MenuHeight: Integer;
    FNextControlId: Cardinal;

    FStockNullBrush: HBRUSH;
    FStockBlackBrush: HBRUSH;
    FStockLtGrayBrush: HBRUSH;
    FStockGrayBrush: HBRUSH;
    FStockDkGrayBrush: HBRUSH;
    FStockWhiteBrush: HBRUSH;

    Procedure CreateComponent(Sender: TObject);
    Function RecreateWnd(Sender: TWinControl): Integer; virtual;
    Function  GetText(Sender: TComponent; Handle: HWND; var Data: String): Boolean; virtual;
    Procedure SetLabel(Sender: TObject; Data: Pointer);
    Procedure AddChild(Parent, Child: HWND);
    Procedure ResizeChild(Sender: TWinControl; Left, Top, Width, Height: Integer);
    Procedure AssignSelf(Window: HWnd; Data: Pointer);
    Procedure ReDraw(Child: TObject);
    Procedure SetCursor(Sender: TObject);
    Procedure SetLimitText(Window: HWND; Limit: Word);

    Procedure ShowHide(Sender: TObject);
    Procedure AddNBPage(Notebook: TCustomNotebook; NewPage: TCustomPage; Index: Integer);
    Procedure RemoveNBPage(Parent: TObject; Index: Integer);
    Procedure SetText(Window: HWND; Data: Pointer);
    Procedure SetColor(Sender : TObject);
    Procedure SetPixel(Sender: TObject; Data: Pointer);
    Procedure GetPixel(Sender: TObject; Data: Pointer);
    Function GetValue (Sender: TObject; Data: Pointer): Integer;
    Function SetValue (Sender: TObject; Data: Pointer): Integer;
    Function SetProperties(Sender: TObject): Integer;
    Procedure AttachMenu(Sender: TObject);

    Procedure AllocAndCopy(const BitmapInfo: Windows.TBitmap; const SrcRect: TRect; var Data: PByte; var Size: Cardinal);
    procedure FillRawImageDescriptionColors(Desc: PRawImageDescription);
    procedure FillRawImageDescription(const BitmapInfo: Windows.TBitmap;
        Desc: PRawImageDescription);

    Function WinRegister: Boolean;
    Function ToolBtnWinRegister: Boolean;
    Procedure SetOwner(Window: HWND; Owner: TObject);
    Procedure PaintPixmap(Surface: TObject; PixmapData: Pointer);
    Procedure NormalizeIconName(Var IconName: String);
    Procedure NormalizeIconName(Var IconName: PChar);
    Procedure CreateCommonDialog(Sender: TCommonDialog; CompStyle: Integer);
    Procedure CreateSelectDirectoryDialog(Sender: TSelectDirectoryDialog);

  Public
    { Creates a callback of Lazarus message Msg for Sender }
    Procedure SetCallback(Msg: LongInt; Sender: TObject); virtual;
    { Removes all callbacks for Sender }
    Procedure RemoveCallbacks(Sender: TObject); virtual;

    { Constructor of the class }
    Constructor Create;
    { Destructor of the class }
    Destructor Destroy; Override;
    { Initialize the API }
    Procedure AppInit; Override;
    Function IntSendMessage3(LM_Message: Integer; Sender: TObject; Data: Pointer) : Integer; Override;
    Procedure HandleEvents; Override;
    Procedure WaitMessage; Override;
    Procedure AppTerminate; Override;
    Procedure AttachMenuToWindow(AMenuObject: TComponent); Override;

    function CreateTimer(Interval: integer; TimerFunc: TFNTimerProc) : integer; override;
    function DestroyTimer(TimerHandle: Integer) : boolean; override;

    {$I win32winapih.inc}
  End;

  {$I win32listslh.inc}

  { Asserts a trace for event named Message in the object Data }
  Procedure EventTrace(Message: String; Data: TObject);

Implementation

Uses
  Arrow, Buttons, Calendar, CListBox, Spin, CheckLst, WinExt;

Type
  TEventType = (etNotify, etKey, etKeyPress, etMouseWheeel, etMouseUpDown);

  { Linked list of objects for events }
  PLazObject = ^TLazObject;
  TLazObject = Record
    Parent: TObject;
    Messages: TList;
    Next: PLazObject;
  End;

  {$IFDEF VER1_1_MSG}
    TMsgArray = Array Of Integer;
  {$ELSE}
    TMsgArray = Array[0..1] Of Integer;
  {$ENDIF}

Const
  BOOL_RESULT: Array[Boolean] Of String = ('False', 'True');
  ClsName : array[0..20] of char = 'LazarusForm'#0;
  ToolBtnClsName : array[0..20] of char = 'ToolbarButton'#0;

Var
  WndList: TList;

{$I win32proc.inc}
{$I win32listsl.inc}
{$I win32callback.inc}
{$I win32object.inc}
{$I win32winapi.inc}

Initialization

Assert(False, 'Trace:win32int.pp - Initialization');
WndList := TList.Create;

Finalization

Assert(False, 'Trace:win32int.pp - Finalization');
WndList.Free;
WndList := Nil;

End.

{ =============================================================================

  $Log$
  Revision 1.54  2003/11/25 21:20:38  micha
  implement tchecklistbox

  Revision 1.53  2003/11/25 14:21:28  micha
  new api lclenable,checkmenuitem according to list

  Revision 1.52  2003/11/21 20:32:01  micha
  cleanups; wm_hscroll/wm_vscroll fix

  Revision 1.51  2003/11/14 20:23:31  micha
  fpimage fixes

  Revision 1.50  2003/11/10 16:15:32  micha
  cleanups; win32 fpimage support

  Revision 1.49  2003/11/08 17:41:03  micha
  compiler warning cleanups

  Revision 1.48  2003/10/28 14:25:37  mattias
  fixed unit circle

  Revision 1.47  2003/10/26 17:34:41  micha
  new interface method to attach a menu to window

  Revision 1.46  2003/10/23 07:45:49  micha
  cleanups; single parent window (single taskbar button)

  Revision 1.45  2003/10/21 15:06:27  micha
  spinedit fix; variables cleanup

  Revision 1.44  2003/09/30 13:05:59  mattias
  removed FMainForm by Micha

  Revision 1.43  2003/09/27 09:52:44  mattias
  TScrollBox for win32 intf from Karl

  Revision 1.42  2003/09/20 13:27:49  mattias
  varois improvements for ParentColor from Micha

  Revision 1.41  2003/09/18 09:21:03  mattias
  renamed LCLLinux to LCLIntf

  Revision 1.40  2003/09/14 09:43:45  mattias
  fixed common dialogs from Karl

  Revision 1.39  2003/09/08 13:24:17  mattias
  removed class function

  Revision 1.38  2003/09/08 12:21:48  mattias
  added fpImage reader/writer hooks to TBitmap

  Revision 1.37  2003/08/28 09:10:01  mattias
  listbox and comboboxes now set sort and selection at handle creation

  Revision 1.36  2003/08/27 09:33:26  mattias
  implements SET_LABEL from Micha

  Revision 1.35  2003/08/26 08:12:33  mattias
  applied listbox/combobox patch from Karl

  Revision 1.34  2003/08/26 07:04:04  mattias
  fixed win32int

  Revision 1.33  2003/08/21 06:52:47  mattias
  size fixes from Karl

  Revision 1.32  2003/08/17 12:51:35  mattias
  added directory selection dialog from Vincent

  Revision 1.31  2003/08/17 12:47:53  mattias
  fixed mem leak

  Revision 1.30  2003/08/17 12:26:00  mattias
  fixed parts of the win32 intf size system

  Revision 1.29  2003/03/13 19:57:38  mattias
  added identcompletion context information and fixed win32 intf

  Revision 1.28  2003/03/11 07:46:44  mattias
  more localization for gtk- and win32-interface and lcl

  Revision 1.27  2003/01/01 10:46:59  mattias
  fixes for win32 listbox/combobox from Karl Brandt

  Revision 1.26  2002/12/28 09:42:12  mattias
  toolbutton patch from Martin Smat

  Revision 1.25  2002/12/16 09:02:27  mattias
  applied win32 notebook patch from Vincent

  Revision 1.24  2002/02/09 01:48:23  mattias
  renamed TinterfaceObject.Init to AppInit and TWinControls can now contain childs in gtk

  Revision 1.23  2002/12/04 20:39:16  mattias
  patch from Vincent: clean ups and fixed crash on destroying window

  Revision 1.22  2002/12/03 09:15:15  mattias
  cleaned up

  Revision 1.21  2002/11/26 20:51:05  mattias
  applied clipbrd patch from Vincent

  Revision 1.20  2002/11/23 13:48:48  mattias
  added Timer patch from Vincent Snijders

  Revision 1.19  2002/11/15 23:43:54  mattias
  applied patch from Karl Brandt

  Revision 1.18  2002/10/27 19:59:03  lazarus
  AJ: fixed compiling

  Revision 1.17  2002/10/26 15:15:55  lazarus
  MG: broke LCL<->interface circles

  Revision 1.16  2002/08/08 18:05:48  lazarus
  MG: added graphics extensions from Andrew Johnson

  Revision 1.15  2002/05/31 13:10:49  lazarus
  Keith: Code cleanup.

  Revision 1.14  2002/05/10 07:43:48  lazarus
  MG: updated licenses

  Revision 1.13  2002/04/03 03:41:29  lazarus
  Keith:
    * Removed more obsolete code
    * Compiles again!

  Revision 1.12  2002/04/03 01:52:42  lazarus
  Keith: Removed obsolete code, in preperation of a pending TWin32Object cleanup

  Revision 1.11  2002/02/07 08:35:12  lazarus
  Keith: Fixed persistent label captions and a few less noticable things

  Revision 1.10  2002/02/03 06:06:25  lazarus
  Keith: Fixed Win32 compilation problems

  Revision 1.9  2002/02/01 10:13:09  lazarus
  Keith: Fixes for Win32

  Revision 1.8  2002/01/31 09:32:07  lazarus
  Keith:
    * Open and save dialogs can now coexist in apps (however, only one of each type of common dialog can be used per app :( )
    * Fixed make all
    * Fixed crash in Windows 98/ME

  Revision 1.7  2002/01/25 19:42:56  lazarus
  Keith: Improved events and common dialogs on Win32

  Revision 1.6  2002/01/17 03:17:44  lazarus
  Keith: Fixed TCustomPage creation

  Revision 1.5  2002/01/05 13:16:09  lazarus
  MG: win32 interface update from Keith Bowes

  Revision 1.4  2001/11/01 22:40:13  lazarus
  MG: applied Keith Bowes win32 interface updates

  Revision 1.3  2001/08/02 12:58:35  lazarus
  MG: win32 interface patch from Keith Bowes

  Revision 1.2  2000/12/12 14:16:43  lazarus
  Updated OI from Mattias
  Shane

  Revision 1.1  2000/07/13 10:28:29  michael
  + Initial import

}
