{%MainUnit gtkint.pp}
{ $Id$ }

(******************************************************************************
  All GTK Winapi related stuff goes here.

  !! Keep this alphabetical !!
 ******************************************************************************)
{
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

//##apiwiz##sps##   // Do not remove

function Arc(DC: HDC; Left,Top,width,height,angle1,angle2 : Integer): Boolean; override;
function AngleChord(DC: HDC; x,y,width,height,angle1,angle2 : Integer): Boolean; override;

function BeginPaint(Handle: hWnd; Var PS : TPaintStruct) : hdc; override;
function BitBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc: Integer; Rop: DWORD): Boolean; override;
Function BringWindowToTop(hWnd : HWND): Boolean; override;

function CallNextHookEx(hHk: HHOOK; ncode : Integer; wParam: WParam; lParam : LParam) : Integer; override;
Function CallWindowProc(lpPrevWndFunc : TFarProc; Handle : HWND; Msg : UINT; wParam: WParam; lParam : lParam) : Integer; override;
Function ClientToScreen(Handle : HWND; var P : TPoint) : Boolean;override;

// clipboard
function ClipboardFormatToMimeType(FormatID: TClipboardFormat): string; override;
function ClipboardGetData(ClipboardType: TClipboardType;
  FormatID: TClipboardFormat; Stream: TStream): boolean; override;
// ! List will be created. You must free it yourself with FreeMem(List) !
function ClipboardGetFormats(ClipboardType: TClipboardType;
  var Count: integer; var List: PClipboardFormat): boolean; override;
function ClipboardGetOwnerShip(ClipboardType: TClipboardType;
  OnRequestProc: TClipboardRequestEvent;  FormatCount: integer;
  Formats: PClipboardFormat): boolean; override;
function ClipboardRegisterFormat(const AMimeType: string): TClipboardFormat; override;

Function CombineRgn(Dest, Src1, Src2 : HRGN; fnCombineMode : Longint) : Longint;  override;
function ComboBoxDropDown(Handle: HWND; DropDown: boolean): boolean; override;
function CreateBitmap(Width, Height: Integer; Planes, BitCount: Longint; BitmapBits: Pointer): HBITMAP; override;
function CreateBitmapFromRawImage(const RawImage: TRawImage; var Bitmap, MaskBitmap: HBitmap; AlwaysCreateMask: boolean): boolean; override;
function CreateBrushIndirect(const LogBrush: TLogBrush): HBRUSH; override;
function CreateCaret(Handle : HWND; Bitmap : hBitmap; width, Height : Integer) : Boolean; override;
function CreateCompatibleBitmap(DC: HDC; Width, Height: Integer): HBITMAP; override;
function CreateCompatibleDC(DC: HDC): HDC; override;
function CreateFontIndirect(const LogFont: TLogFont): HFONT; override;
function CreateFontIndirectEx(const LogFont: TLogFont; const LongFontName: string): HFONT; override;
function CreatePalette(const LogPalette: TLogPalette): HPALETTE; override;
function CreatePenIndirect(const LogPen: TLogPen): HPEN; override;
function CreatePixmapIndirect(const Data: Pointer; const TransColor: Longint): HBITMAP; override;
Function CreatePolygonRgn(Points: PPoint; NumPts: Integer; FillMode: integer): HRGN; Override;
function CreateRectRgn(X1,Y1,X2,Y2 : Integer): HRGN; override;

procedure DeleteCriticalSection(var CritSection: TCriticalSection); override;
function DeleteDC(hDC: HDC): Boolean; override;
function DeleteObject(GDIObject: HGDIOBJ): Boolean;  override;
function DestroyCaret(Handle : HWND): Boolean; override;
Function DrawFrameControl(DC: HDC; var Rect : TRect; uType, uState : Cardinal) : Boolean; override;
function DrawEdge(DC: HDC; var ARect: TRect; Edge: Cardinal; grfFlags: Cardinal): Boolean; override;
function DrawText(DC: HDC; Str: PChar; Count: Integer; var Rect: TRect; Flags: Cardinal): Integer; Override;

function Ellipse(DC: HDC; x1,y1,x2,y2: Integer): Boolean; override;
function EnableScrollBar(Wnd: HWND; wSBflags, wArrows: Cardinal): Boolean; override;
function EnableWindow(hWnd: HWND; bEnable: Boolean): Boolean; override;
function EndPaint(Handle : hwnd; var PS : TPaintStruct): Integer; override;
procedure EnterCriticalSection(var CritSection: TCriticalSection); Override;
function ExcludeClipRect(dc: hdc; Left, Top, Right, Bottom : Integer) : Integer; override;
function ExtTextOut(DC: HDC; X, Y: Integer; Options: Longint; Rect: PRect; Str: PChar; Count: Longint; Dx: PInteger): Boolean;  override;
function ExtSelectClipRGN(dc: hdc; rgn : hrgn; Mode : Longint) : Integer;  override;

function FillRect(DC: HDC; const Rect: TRect; Brush: HBRUSH): Boolean; override;
function Frame(DC: HDC; const ARect: TRect): Integer; override;
function Frame3d(DC: HDC; var ARect: TRect; const FrameWidth : integer; const Style : TBevelCut): Boolean; override;
function FrameRect(DC: HDC; const ARect: TRect; hBr: HBRUSH): Integer; override;

Function GetActiveWindow : HWND; override;
function GetBitmapBits(Bitmap: HBITMAP; Count: Longint;  Bits: Pointer): Longint; override;
function GetBitmapRawImageDescription(Bitmap: HBITMAP; Desc: PRawImageDescription): boolean; override;
function GetCapture: HWND; override;
function GetCaretPos(var lpPoint: TPoint): Boolean; override;
function GetCaretRespondToFocus(handle: HWND; var ShowHideOnFocus: boolean): Boolean; override;
function GetCharABCWidths(DC: HDC; p2, p3: UINT; const ABCStructs): Boolean; override;
Function GetClientBounds(handle : HWND; var ARect : TRect) : Boolean; override;
Function GetClientRect(handle : HWND; var ARect : TRect) : Boolean; override;
Function GetClipBox(DC : hDC; lpRect : PRect) : Longint; override;
Function GetClipRGN(DC : hDC; RGN : hRGN) : Longint; override;
Function GetCmdLineParamDescForInterface: string; override;
function GetCursorPos(var lpPoint: TPoint): Boolean; override;
function GetDC(hWnd: HWND): HDC;  override;
function GetDCOriginRelativeToWindow(PaintDC: HDC; WindowHandle: HWND; var OriginDiff: TPoint): boolean; override;
function GetDesignerDC(WindowHandle: HWND): HDC; override;
function GetDeviceCaps(DC: HDC; Index: Integer): Integer; Override;
function GetDeviceRawImageDescription(DC: HDC; Desc: PRawImageDescription): boolean; override;
function GetDeviceSize(DC: HDC; var p: TPoint): boolean; override;
function GetDIBits(DC: HDC; Bitmap: HBitmap; StartScan, NumScans: UINT; Bits: Pointer; var BitInfo: BitmapInfo; Usage: UINT): Integer; Override;
function GetFocus: HWND; override;
function GetFontLanguageInfo(DC: HDC): DWord; override;
function GetKeyState(nVirtKey: Integer): Smallint; override;
function GetObject(GDIObj: HGDIOBJ; BufSize: Integer; Buf: Pointer): Integer; override;
Function GetParent(Handle : HWND): HWND; override;
Function GetProp(Handle : hwnd; Str : PChar): Pointer; override;
function GetRawImageFromDevice(SrcDC: HDC; const SrcRect: TRect; var NewRawImage: TRawImage): boolean; override;
function GetRawImageFromBitmap(SrcBitmap, SrcMaskBitmap: HBITMAP; const SrcRect: TRect; var NewRawImage: TRawImage): boolean; override;
Function GetRgnBox(RGN : HRGN; lpRect : PRect) : Longint; override;
function GetROP2(DC: HDC): Integer; override;
function GetScrollBarSize(Handle: HWND; BarKind: Integer): integer; override;
function GetScrollbarVisible(Handle: HWND; SBStyle: Integer): boolean; override;
function GetScrollInfo(Handle: HWND; SBStyle: Integer; var ScrollInfo: TScrollInfo): Boolean; override;
function GetStockObject(Value: Integer): LongInt; override;
function GetSysColor(nIndex: Integer): DWORD; override;
function GetSystemMetrics(nIndex: Integer): Integer;  override;
function GetTextColor(DC: HDC) : TColorRef; Override;
function GetTextExtentPoint(DC: HDC; Str: PChar; Count: Integer; var Size: TSize): Boolean; override;
function GetTextMetrics(DC: HDC; var TM: TTextMetric): Boolean;  override;
Function GetWindowLong(Handle : hwnd; int: Integer): Longint; override;
Function GetWindowOrgEx(dc : hdc; P: PPoint): Integer;  override;
Function GetWindowRect(Handle : hwnd; var ARect: TRect): Integer; override;
function GetWindowRelativePosition(Handle : hwnd; var Left, Top: integer): boolean; override;
Function GetWindowSize(Handle : hwnd; var Width, Height: integer): boolean; override;
function GradientFill(DC: HDC; Vertices: PTriVertex; NumVertices : Longint;
  Meshes: Pointer; NumMeshes : Longint; Mode : Longint): Boolean; Override;

function HideCaret(hWnd: HWND): Boolean; override;

Procedure InitializeCriticalSection(var CritSection: TCriticalSection); Override;
function IntersectClipRect(dc: hdc; Left, Top, Right, Bottom: Integer): Integer; override;
function InvalidateRect(aHandle : HWND; Rect : pRect; bErase : Boolean) : Boolean; override;
function IsWindowEnabled(handle: HWND): boolean; override;
function IsWindowVisible(handle: HWND): boolean; override;

Procedure LeaveCriticalSection(var CritSection: TCriticalSection); Override;
function LineTo(DC: HDC; X, Y: Integer): Boolean; override;

function MessageBox(hWnd: HWND; lpText, lpCaption: PChar; uType: Cardinal): integer; override;
function MoveToEx(DC: HDC; X, Y: Integer; OldPoint: PPoint): Boolean; override;
function MoveWindowOrgEx(DC: HDC; dX, dY: Integer): Boolean; override;

function PairSplitterAddSide(SplitterHandle, SideHandle: hWnd; Side: integer): Boolean; override;
function PairSplitterGetInterfaceInfo: Boolean; override;
function PairSplitterRemoveSide(SplitterHandle, SideHandle: hWnd; Side: integer): Boolean; override;
function PairSplitterSetPosition(SplitterHandle: hWnd; var NewPosition: integer): Boolean; override;
function PeekMessage(var lpMsg : TMsg; Handle : HWND; wMsgFilterMin, wMsgFilterMax,wRemoveMsg : UINT): Boolean; override;
function PolyBezier(DC: HDC; Points: PPoint; NumPts: Integer; Filled, Continuous: boolean): boolean; override;
function Polygon(DC: HDC; Points: PPoint; NumPts: Integer; Winding: boolean): boolean; override;
function Polyline(DC: HDC; Points: PPoint; NumPts: Integer): boolean; override;
function PostMessage(Handle: HWND; Msg: Cardinal; wParam: WParam; lParam: LParam): Boolean; override;

function RadialArc(DC: HDC; x,y,width,height,sx,sy,ex,ey : Integer): Boolean; override;
function RadialChord(DC: HDC; x,y,width,height,sx,sy,ex,ey : Integer): Boolean; override;
function RadialPie(DC: HDC; x,y,width,height,sx,sy,ex,ey : Integer): Boolean; override;
function RadioMenuItemGroup(hndMenu: HMENU; bRadio: Boolean): Boolean; override;
function RealizePalette(DC: HDC): Cardinal; override;
function Rectangle(DC: HDC; X1, Y1, X2, Y2: Integer): Boolean; override;
function RectVisible(dc : hdc; const ARect: TRect) : Boolean; override;
function RegroupMenuItem(hndMenu: HMENU; GroupIndex: integer): Boolean; override;
Function ReleaseCapture : Boolean; override;
function ReleaseDC(hWnd: HWND; DC: HDC): Integer; override;
function RemoveProp(Handle: hwnd; Str: PChar): THandle; override;
function RestoreDC(DC: HDC; SavedDC: Integer): Boolean; override;
Function RoundRect(DC : hDC; X1, Y1, X2, Y2: Integer; RX,RY : Integer): Boolean;  override;

function SaveDC(DC: HDC): Integer; override;
Function ScreenToClient(Handle : HWND; var P : TPoint) : Integer; override;
function ScrollWindowEx(hWnd: HWND; dx, dy: Integer; prcScroll, prcClip: PRect; hrgnUpdate: HRGN; prcUpdate: PRect; flags: UINT): Boolean; override;
Function SelectClipRGN(DC : hDC; RGN : HRGN) : Longint; override;
function SelectObject(DC: HDC; GDIObj: HGDIOBJ): HGDIOBJ;  override;
function SelectPalette(DC: HDC; Palette: HPALETTE; ForceBackground: Boolean): HPALETTE; override;
function SendMessage(HandleWnd: HWND; Msg: Cardinal; wParam: WParam; lParam: LParam): LResult; override;
function SetActiveWindow(Handle: HWND): HWND; override;
function SetBkColor(DC: HDC; Color: TColorRef): TColorRef; override;
Function SetBkMode(DC: HDC; bkMode : Integer) : Integer; override;
Function SetComboMinDropDownSize(Handle: HWND; MinItemsWidth, MinItemsHeight, MinItemCount: integer): boolean; override;
function SetCapture(AHandle: HWND): HWND; override;
function SetCaretPos(X, Y: Integer): Boolean; override;
function SetCaretPosEx(Handle: HWnd; X, Y: Integer): Boolean; override;
function SetCaretRespondToFocus(handle: HWND; ShowHideOnFocus: boolean): Boolean; override;
function SetCursorPos(X, Y: Integer): Boolean; override;
function SetFocus(hWnd: HWND): HWND; override;
Function SetProp(Handle: hwnd; Str : PChar; Data : Pointer) : Boolean; override;
function SetROP2(DC: HDC; Mode: Integer): Integer; override;
function SetScrollInfo(Handle : HWND; SBStyle : Integer; ScrollInfo: TScrollInfo; bRedraw : Boolean): Integer; override;
function SetSysColors(cElements: Integer; const lpaElements; const lpaRgbValues): Boolean; override;
Function SetTextCharacterExtra(_hdc : hdc; nCharExtra : Integer):Integer; override;
function SetTextColor(DC: HDC; Color: TColorRef): TColorRef; override;
function SetWindowLong(Handle: HWND; Idx: Integer; NewLong : Longint): LongInt; override;
function SetWindowOrgEx(dc : hdc; NewX, NewY : Integer; OldPoint: PPoint) : Boolean; override;
function SetWindowPos(hWnd: HWND; hWndInsertAfter: HWND;
      X, Y, cx, cy: Integer; uFlags: UINT): Boolean;  override;
function ShowCaret(hWnd: HWND): Boolean; override;
function ShowScrollBar(Handle: HWND; wBar: Integer; bShow: Boolean): Boolean; override;
function ShowWindow(hWnd: HWND; nCmdShow: Integer): Boolean; override;
function StretchBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer; ROp: Cardinal): Boolean; override;
function StretchMaskBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer; Mask: HBITMAP; XMask, YMask: Integer; Rop: DWORD): Boolean; override;

Function TextOut(DC: HDC; X,Y : Integer; Str : Pchar; Count: Integer) : Boolean; override;

function VkKeyScan(AChar: Char): Short; override;

Function WindowFromPoint(Point : TPoint) : HWND; override;

//##apiwiz##eps##   // Do not remove, no wizard declaration after this line


// included by gtkint.pp

{ =============================================================================

  $Log$
  Revision 1.98  2005/06/22 17:37:06  mattias
  implemented TMouse.SetCursorPos  from Andrew

  Revision 1.97  2005/05/21 15:58:44  mattias
  implemented right justification for menuitems for winapi intf  from Martin Smat

  Revision 1.96  2005/03/04 13:50:09  mattias
  fixed Arc and changed x,y to Left,Top to make meaning more clear

  Revision 1.95  2005/02/23 01:12:47  marc
  + Added RemoveProp winapi call
  * Some maintenace on winapi/lclintf files

  Revision 1.94  2005/02/05 16:09:52  marc
  * first 64bit changes

  Revision 1.93  2005/02/05 09:05:51  micha
  add platform independent winapi function IsWindowEnabled

  Revision 1.92  2005/01/16 11:40:11  mattias
  fixed TGtkWidgetSet.ExtSelectClipRGN for DCOrigin

  Revision 1.91  2005/01/08 11:03:18  mattias
  implemented TPen.Mode=pmXor  from Jesus

  Revision 1.90  2004/09/10 16:28:51  mattias
  implemented very rudimentary TTabControl

  Revision 1.89  2004/02/23 18:24:38  mattias
  completed new TToolBar

  Revision 1.88  2004/02/19 05:07:17  mattias
  CreateBitmapFromRawImage now creates mask only if needed

  Revision 1.87  2004/02/10 00:05:03  mattias
  TSpeedButton now uses MaskBlt

  Revision 1.86  2004/02/03 08:54:09  mattias
  Frame3D rect now var again

  Revision 1.85  2004/02/02 15:46:19  mattias
  implemented basic TSplitter, still many ToDos

  Revision 1.84  2004/01/22 11:23:36  mattias
  started MaskBlt for gtkIF and applied patch for dir dlg in env opts from Vincent

  Revision 1.83  2004/01/10 18:00:42  mattias
  fixed GetWindowOrgEx, added GetDCOriginRelativeToWindow

  Revision 1.82  2003/12/30 21:05:13  micha
  fix gtk interface due to lcl interface change (from vincent

  Revision 1.81  2003/11/24 11:03:07  marc
  * Splitted winapi*.inc into a winapi and a lcl interface communication part

  Revision 1.80  2003/11/10 16:15:32  micha
  cleanups; win32 fpimage support

  Revision 1.79  2003/11/03 22:37:41  mattias
  fixed vert scrollbar, implemented GetDesignerDC

  Revision 1.78  2003/10/16 23:54:27  marc
  Implemented new gtk keyevent handling

  Revision 1.77  2003/09/17 19:40:46  ajgenius
  Initial DoubleBuffering Support for GTK2

  Revision 1.76  2003/08/26 08:12:33  mattias
  applied listbox/combobox patch from Karl

  Revision 1.75  2003/08/18 19:24:18  mattias
  fixed TCanvas.Pie

  Revision 1.74  2003/07/29 00:28:43  marc
  + Implemented GetCursorPos

  Revision 1.73  2003/07/06 20:40:34  mattias
  TWinControl.WmSize/Move now updates interface messages smarter

  Revision 1.72  2003/07/02 15:56:15  mattias
  fixed win32 painting and started creating bitmaps from rawimages

  Revision 1.71  2003/07/02 10:02:51  mattias
  fixed TPaintStruct

  Revision 1.70  2003/07/01 09:29:52  mattias
  attaching menuitems topdown

  Revision 1.69  2002/08/19 15:15:24  mattias
  implemented TPairSplitter

  Revision 1.68  2002/08/17 23:41:35  mattias
  many clipping fixes

  Revision 1.67  2003/04/11 17:10:20  mattias
  added but not implemented ComboBoxDropDown

  Revision 1.66  2003/03/29 17:20:05  mattias
  added TMemoScrollBar

  Revision 1.65  2003/03/17 20:53:16  mattias
  removed SetRadioButtonGroupMode

  Revision 1.64  2003/03/17 20:50:30  mattias
  fixed TRadioGroup.ItemIndex=-1

  Revision 1.63  2003/03/17 08:51:10  mattias
  added IsWindowVisible

  Revision 1.62  2003/03/09 21:13:32  mattias
  localized gtk interface

  Revision 1.61  2003/02/28 19:54:05  mattias
  added ShowWindow

  Revision 1.60  2003/01/27 13:49:16  mattias
  reduced speedbutton invalidates, added TCanvas.Frame

  Revision 1.59  2002/12/30 17:24:08  mattias
  added history to identifier completion

  Revision 1.58  2002/12/27 17:12:38  mattias
  added more Delphi win32 compatibility functions

  Revision 1.57  2002/12/26 11:00:15  mattias
  added included by to unitinfo and a few win32 functions

  Revision 1.56  2002/12/25 13:30:37  mattias
  added more windows funcs and fixed jump to compiler error end of file

  Revision 1.55  2002/12/05 22:16:35  mattias
  double byte char font started

  Revision 1.54  2002/11/23 13:48:47  mattias
  added Timer patch from Vincent Snijders

  Revision 1.53  2002/11/09 15:02:12  lazarus
  MG: fixed LM_LVChangedItem, OnShowHint, small bugs

  Revision 1.52  2002/10/31 21:29:49  lazarus
  MG: implemented TControlScrollBar.Size

  Revision 1.51  2002/10/03 14:47:34  lazarus
  MG: added TComboBox.OnPopup+OnCloseUp+ItemWidth

  Revision 1.50  2002/09/27 20:52:26  lazarus
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

  Revision 1.49  2002/09/20 13:11:14  lazarus
  MG: fixed TPanel and Frame3D

  Revision 1.48  2002/09/19 19:56:18  lazarus
  MG: accelerated designer drawings

  Revision 1.47  2002/09/18 17:07:30  lazarus
  MG: added patch from Andrew

  Revision 1.46  2002/09/12 05:56:17  lazarus
  MG: gradient fill, minor issues from Andrew

  Revision 1.45  2002/09/10 06:49:24  lazarus
  MG: scrollingwincontrol from Andrew

  Revision 1.44  2002/09/09 14:01:07  lazarus
  MG: improved TScreen and ShowModal

  Revision 1.43  2002/08/30 12:32:25  lazarus
  MG: MoveWindowOrgEx, Splitted FWinControls/FControls, TControl drawing, Better DesignerDrawing, ...

  Revision 1.42  2002/08/28 09:40:52  lazarus
  MG: reduced paint messages and DC getting/releasing

  Revision 1.41  2002/08/19 20:34:48  lazarus
  MG: improved Clipping, TextOut, Polygon functions

  Revision 1.40  2002/08/17 15:45:36  lazarus
  MG: removed ClientRectBugfix defines

  Revision 1.39  2002/08/15 15:46:50  lazarus
  MG: added changes from Andrew (Clipping)

  Revision 1.38  2002/08/13 07:08:25  lazarus
  MG: added gdkpixbuf.pp and changes from Andrew Johnson

  Revision 1.37  2002/08/08 18:05:48  lazarus
  MG: added graphics extensions from Andrew Johnson

  Revision 1.36  2002/08/08 17:26:40  lazarus
  MG: added property TMenuItems.RightJustify

  Revision 1.35  2002/08/08 09:07:08  lazarus
  MG: TMenuItem can now be created/destroyed/moved at any time

  Revision 1.34  2002/08/07 09:55:31  lazarus
  MG: codecompletion now checks for filebreaks, savefile now checks for filedate

  Revision 1.33  2002/08/05 10:45:08  lazarus
  MG: TMenuItem.Caption can now be set after creation

  Revision 1.32  2002/06/21 15:41:57  lazarus
  MG: moved RectVisible, ExcludeClipRect and IntersectClipRect to interface dependent functions

  Revision 1.31  2002/06/04 15:17:26  lazarus
  MG: improved TFont for XLFD font names

  Revision 1.30  2002/05/27 17:58:42  lazarus
  MG: added command line help

  Revision 1.29  2002/05/24 07:16:35  lazarus
  MG: started mouse bugfix and completed Makefile.fpc

  Revision 1.28  2002/05/10 06:05:58  lazarus
  MG: changed license to LGPL

  Revision 1.27  2002/05/09 12:41:32  lazarus
  MG: further clientrect bugfixes

  Revision 1.26  2002/04/22 13:07:46  lazarus
  MG: fixed AdjustClientRect of TGroupBox

  Revision 1.25  2002/03/27 08:57:17  lazarus
  MG: reduced compiler warnings

  Revision 1.24  2002/02/03 00:24:02  lazarus
  TPanel implemented.
  Basic graphic primitives split into GraphType package, so that we can
  reference it from interface (GTK, Win32) units.
  New Frame3d canvas method that uses native (themed) drawing (GTK only).
  New overloaded Canvas.TextRect method.
  LCLLinux and Graphics was split, so a bunch of files had to be modified.

  Revision 1.23  2002/01/02 15:24:59  lazarus
  MG: added TCanvas.Polygon and TCanvas.Polyline

  Revision 1.22  2001/12/28 11:41:51  lazarus
  MG: added TCanvas.Ellipse, TCanvas.Pie

  Revision 1.21  2001/12/27 16:31:28  lazarus
  MG: implemented TCanvas.Arc

  Revision 1.20  2001/12/12 14:23:18  lazarus
  MG: implemented DestroyCaret

  Revision 1.19  2001/11/14 17:46:59  lazarus
  Changes to make toggling between form and unit work.
  Added BringWindowToTop
  Shane

  Revision 1.18  2001/11/12 16:56:09  lazarus
  MG: CLIPBOARD

  Revision 1.17  2001/10/10 17:55:06  lazarus
  MG: fixed caret lost, gtk cleanup, bracket lvls, bookmark saving

  Revision 1.16  2001/06/26 21:44:33  lazarus
  MG: reduced paint messages

  Revision 1.15  2001/06/14 23:13:30  lazarus
  MWE:
    * Fixed some syntax errors for the latest 1.0.5 compiler

  Revision 1.14  2001/04/06 22:25:15  lazarus
  * TTimer uses winapi-interface now instead of sendmessage-interface, stoppok

  Revision 1.13  2001/03/26 14:58:32  lazarus
  MG: setwindowpos + bugfixes

  Revision 1.12  2001/03/13 15:02:14  lazarus
  MG: activated GetWindowOrgEx

  Revision 1.11  2001/02/16 19:13:31  lazarus
  Added some functions
  Shane

  Revision 1.10  2001/01/23 23:33:55  lazarus
  MWE:
    - Removed old LM_InvalidateRect
    - did some cleanup in old  code
    + added some comments  on gtkobject data (gtkproc)

  Revision 1.9  2001/01/23 19:13:57  lazarus
  Fixxed the errors I commited with Unionrect
  Shane

  Revision 1.8  2001/01/23 19:01:10  lazarus
  Fixxed bug in RestoreDC
  Shane

  Revision 1.7  2001/01/23 18:42:10  lazarus
  Added InvalidateRect to gtkwinapi.inc
  Shane

  Revision 1.6  2000/09/10 23:08:31  lazarus
  MWE:
    + Added CreateCompatibeleBitamp function
    + Updated TWinControl.WMPaint
    + Added some checks to avoid gtk/gdk errors
    - Removed no fixed warning from GetDC
    - Removed some output

  Revision 1.5  2000/08/14 12:31:12  lazarus
  Minor modifications for SynEdit .
  Shane

  Revision 1.4  2000/08/11 14:59:09  lazarus
  Adding all the Synedit files.
  Changed the GDK_KEY_PRESS and GDK_KEY_RELEASE stuff to fix the problem in the editor with the shift key being ignored.
  Shane

  Revision 1.3  2000/08/10 18:56:24  lazarus
  Added some winapi calls.
  Most don't have code yet.
  SetTextCharacterExtra
  CharLowerBuff
  IsCharAlphaNumeric
  Shane

  Revision 1.2  2000/07/30 21:48:34  lazarus
  MWE:
    = Moved ObjectToGTKObject to GTKProc unit
    * Fixed array checking in LoadPixmap
    = Moved LM_SETENABLED to API func EnableWindow and EnableMenuItem
    ~ Some cleanup

  Revision 1.1  2000/07/13 10:28:30  michael
  + Initial import

  Revision 1.7  2000/05/11 22:04:16  lazarus
  MWE:
    + Added messagequeue
    * Recoded SendMessage and Peekmessage
    + Added postmessage
    + added DeliverPostMessage

  Revision 1.6  2000/05/08 12:54:20  lazarus
  Removed some writeln's
  Added alignment for the TLabel.  Isn't working quite right.
  Added the shell code for WindowFromPoint and GetParent.
  Added FindLCLWindow
  Shane

  Revision 1.5  2000/05/03 00:27:05  lazarus
  MWE:
    + First rollout of the API wizzard.

  Revision 1.4  2000/04/10 14:03:07  lazarus
  Added SetProp and GetProp winapi calls.
  Added ONChange to the TEdit's published property list.
  Shane

  Revision 1.3  2000/04/07 16:59:55  lazarus
  Implemented GETCAPTURE and SETCAPTURE along with RELEASECAPTURE.
  Shane

  Revision 1.2  2000/03/31 18:41:03  lazarus
  Implemented MessageBox / Application.MessageBox calls. No icons yet, though...

  Revision 1.1  2000/03/30 22:51:43  lazarus
  MWE:
    Moved from ../../lcl

  Revision 1.29  2000/03/30 18:07:54  lazarus
  Added some drag and drop code
  Added code to change the unit name when it's saved as a different name.  Not perfect yet because if you are in a comment it fails.

  Shane

  Revision 1.28  2000/03/28 22:47:50  lazarus
  MWE:
    Started with the blt function family

  Revision 1.27  2000/03/19 23:01:43  lazarus
  MWE:
    = Changed splashscreen loading/colordepth
    = Chenged Save/RestoreDC to platform  dependent, since they are
      relative to a DC

  Revision 1.26  2000/03/16 23:58:46  lazarus
  MWE:
    Added TPixmap for XPM support

  Revision 1.25  2000/03/14 19:49:05  lazarus
  Modified the painting process for TWincontrol.  Now it runs throug it's FCONTROLS list and paints all them
  Shane

  Revision 1.24  2000/03/10 18:31:10  lazarus
  Added TSpeedbutton code
  Shane

  Revision 1.23  2000/03/09 23:48:00  lazarus
  MWE:
    * Fixed colorcache
    * Fixed black window in new editor
    ~ Did some cosmetic stuff

  From Peter Dyson <peter@skel.demon.co.uk>:
    + Added Rect api support functions
    + Added the start of ScrollWindowEx

  Revision 1.22  2000/03/08 23:57:39  lazarus
  MWE:
    Added SetSysColors
    Fixed TEdit text bug (thanks to hans-joachim ott <hjott@compuserve.com>)
    Finished GetKeyState
    Added changes from Peter Dyson <peter@skel.demon.co.uk>
    - a new GetSysColor
    - some improvements on ExTextOut

  Revision 1.21  2000/03/06 00:05:05  lazarus
  MWE: Added changes from Peter Dyson <peter@skel.demon.co.uk> for a new
    release of mwEdit (0.92)

  Revision 1.20  2000/03/03 22:58:26  lazarus
  MWE:
    Fixed focussing problem.
      LM-FOCUS was bound to the wrong signal
    Added GetKeyState api func.
      Now LCL knows if shift/trl/alt is pressed (might be handy for keyboard
      selections ;-)

  Revision 1.19  2000/02/22 23:26:13  lazarus
  MWE: Fixed cursor movement in editor
       Started on focus problem

  Revision 1.18  2000/01/31 20:00:22  lazarus
  Added code for Application.ProcessMessages.  Needs work.
  Added TScreen.Width and TScreen.Height.  Added the code into
  GetSystemMetrics for these two properties.
  Shane

  Revision 1.17  2000/01/25 00:38:25  lazarus
  MWE:
    Added GetFocus

  Revision 1.16  2000/01/16 23:23:07  lazarus
  MWE:
    Added/completed scrollbar API funcs

  Revision 1.15  1999/12/21 21:35:54  lazarus
  committed the latest toolbar code.  Currently it doesn't appear anywhere and I have to get it to add buttons correctly through (I think) setstyle.  I think I'll implement the LM_TOOLBARINSERTBUTTON call there.
  Shane

  Revision 1.14  1999/12/21 00:07:06  lazarus
  MWE:
    Some fixes
    Completed a bit of DraWEdge

  Revision 1.13  1999/12/20 21:01:14  lazarus
  Added a few things for compatability with Delphi and TToolbar
  Shane

  Revision 1.12  1999/12/18 18:27:32  lazarus
  MWE:
    Rearranged some events to get a LM_SIZE, LM_MOVE and LM_WINDOWPOSCHANGED
    Initialized the TextMetricstruct to zeros to clear unset values
    Get mwEdit to show more than one line
    Fixed some errors in earlier commits

  Revision 1.11  1999/12/14 21:07:12  lazarus
  Added more stuff for TToolbar
  Shane

  Revision 1.10  1999/12/02 19:00:59  lazarus
  MWE:
    Added (GDI)Pen
    Changed (GDI)Brush
    Changed (GDI)Font (color)
    Changed Canvas to use/create pen/brush/font
    Hacked mwedit to allow setting the number of chars (till it get a WM/LM_SIZE event)
    The editor shows a line !

  Revision 1.9  1999/11/29 00:46:47  lazarus
  MWE:
    Added TBrush as gdiobject
    commented out some more mwedit MWE_FPC ifdefs

  Revision 1.8  1999/11/25 23:45:08  lazarus
  MWE:
    Added font as GDIobject
    Added some API testcode to testform
    Commented out some more IFDEFs in mwCustomEdit

  Revision 1.7  1999/11/19 01:09:43  lazarus
  MWE:
    implemented TCanvas.CopyRect
    Added StretchBlt
    Enabled creation of TCustomControl.Canvas
    Added a temp hack in TWinControl.Repaint to get a LM_PAINT

  Revision 1.6  1999/11/18 00:13:08  lazarus
  MWE:
    Partly Implemented SelectObject
    Added  ExTextOut
    Added  GetTextExtentPoint
    Added  TCanvas.TextExtent/TextWidth/TextHeight
    Added  TSize and HPEN

  Revision 1.5  1999/11/17 01:16:40  lazarus
  MWE:
    Added some more API stuff
    Added an initial TBitmapCanvas
    Added some DC stuff
    Changed and commented out, original gtk linedraw/rectangle code. This
      is now called through the winapi wrapper.

  Revision 1.4  1999/11/16 01:32:22  lazarus
  MWE:
    Added some more DC functionality

}
