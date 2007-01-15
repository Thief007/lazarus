{
 /***************************************************************************
                         GTKINT.pp  -  GTKInterface Object
                             -------------------

                   Initial Revision  : Thu July 1st CST 1999


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

unit GtkInt;

{$mode objfpc}
{$LONGSTRINGS ON}

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}

{ $DEFINE VerboseTimer}
{ $DEFINE VerboseMouseBugfix}
{ $DEFINE RaiseExceptionOnNilPointers}

{$DEFINE Use_KeyStateList} // keep track of keystates instead of using OS
                           // This is the old mode and might be removed

// TODO: Test on all platforms
{$IFNDEF DisableAsyncProcess}
  {$IFDEF Linux}
    {$IFDEF CPUI386}
      {off $DEFINE UseAsyncProcess}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$IFDEF win32}
{$DEFINE NoGdkPixbufLib}
{$ELSE}
{off $DEFINE NoGdkPixbufLib}
{$ENDIF}
{off $Define DisableCriticalSections}

{off $Define Disable_GC_SysColors}

{$IFDEF gtk2}
  {$IFDEF NoGdkPixbufLib}
    {$UNDEF NoGdkPixbufLib}
  {$EndIF}
{$EndIF}

{$IFDEF Unix}
  {$DEFINE HasX}
  {$IFDEF Gtk1}
    {$DEFINE HasGtkX}
  {$ENDIF}
{$ENDIF}

uses
  {$IFDEF WIN32}
  // use windows unit first,
  // if not, Rect and Point are taken from the windows unit instead of classes.
  Windows,
  {$ENDIF}
  {$IFDEF UNIX}
  // use unix units first,
  // if not, TSize is taken from the unix unit instead of types.
  ctypes, baseunix, unix,
  {$ENDIF}
  {$IFDEF TraceGdiCalls}
  LineInfo,
  {$ENDIF}
  // rtl+fcl
  Types, Classes, SysUtils, FPCAdds,
  // interfacebase
  InterfaceBase,
  // gtk
  {$IFDEF gtk2}
  glib2, gdk2pixbuf, gdk2, gtk2, Pango,
  {$ELSE}
  glib, gdk, gtk, {$Ifndef NoGdkPixbufLib}gdkpixbuf,{$EndIf}
  {$ENDIF}
  // Target OS specific
  {$IFDEF UNIX}
  x, xlib,
  {$ENDIF}
  Math, // after gtk to get the correct Float type
  // LCL
  ExtDlgs, Dialogs, Controls, Forms, LCLStrConsts, LMessages,
  LCLProc, LCLIntf, LCLType, GtkFontCache, gtkDef, GtkProc, DynHashArray,
  gtkMsgQueue, GraphType, GraphMath, Graphics, Menus, Maps;


type

  { TGTKWidgetSet }

  TGTKWidgetSet = class(TWidgetSet)
  protected
    FKeyStateList_: TFPList; // Keeps track of which keys are pressed
    FDeviceContexts: TDynHashArray;// hasharray of HDC
    FGDIObjects: TDynHashArray;    // hasharray of PGdiObject
    FMessageQueue: TGtkMessageQueue;      // queue of PMsg
    WaitingForMessages: boolean;
    MovedPaintMessageCount: integer;// how many paint messages moved to he end of the queue

    FRCFilename: string;
    FRCFileParsed: boolean;
    FRCFileAge: integer;
    FWidgetsWithResizeRequest: TDynHashArray; // hasharray of PGtkWidget
    FGTKToolTips: PGtkToolTips;

    FLogHandlerID: guint; // ID returend by set_handler

    FStockNullBrush: HBRUSH;
    FStockBlackBrush: HBRUSH;
    FStockLtGrayBrush: HBRUSH;
    FStockGrayBrush: HBRUSH;
    FStockDkGrayBrush: HBRUSH;
    FStockWhiteBrush: HBRUSH;

    FStockNullPen: HPEN;
    FStockBlackPen: HPEN;
    FStockWhitePen: HPEN;

    FWaitHandles: PWaitHandleEventHandler;
    {$ifdef unix}
    FChildSignalHandlers: PChildSignalEventHandler;
    {$else}
    {$warning no declaration of FChildSignalHandlers for this OS}
    {$endif}

    {$Ifdef GTK2}
    FDefaultFontDesc: PPangoFontDescription;
    {$Endif}
    FDefaultFont: TGtkIntfFont;
    FStockSystemFont: HFONT;
    FExtUTF8OutCache: Pointer;
    FExtUTF8OutCacheSize: integer;

  public
    procedure InitStockItems; virtual;
    procedure FreeStockItems; virtual;
    procedure PassCmdLineOptions; override;
   
{$ifdef Unix}
    procedure InitSynchronizeSupport;
    procedure ProcessChildSignal;
    procedure PrepareSynchronize(AObject: TObject);
{$endif}  

    procedure HandlePipeEvent(AData: PtrInt; AFlags: dword);

    // styles
    procedure FreeAllStyles; virtual;
    Function GetCompStyle(Sender : TObject) : Longint; Virtual;

    // create and destroy
    function CreateComboBox(ComboBoxObject: TObject): Pointer;
    function CreateAPIWidget(AWinControl: TWinControl): PGtkWidget;
    function CreateForm(ACustomForm: TCustomForm): PGtkWidget; virtual;
    function CreateListView(ListViewObject: TObject): PGtkWidget; virtual;
    function CreatePairSplitter(PairSplitterObject: TObject): PGtkWidget;
    function CreateStatusBar(StatusBar: TObject): PGtkWidget;
    function OldCreateStatusBarPanel(StatusBar: TObject; Index: integer): PGtkWidget;
    function CreateSimpleClientAreaWidget(Sender: TObject;
      NotOnParentsClientArea: boolean): PGtkWidget;
    function CreateToolBar(ToolBarObject: TObject): PGtkWidget;
    procedure DestroyEmptySubmenu(Sender: TObject);virtual;
    procedure DestroyConnectedWidget(Widget: PGtkWidget;
                                     CheckIfDestroying: boolean);virtual;
    function  RecreateWnd(Sender: TObject): Integer; virtual;
    procedure AssignSelf(Child, Data: Pointer);virtual;

    // clipboard
    procedure SetClipboardWidget(TargetWidget: PGtkWidget);virtual;

    // device contexts
    function IsValidDC(const DC: HDC): Boolean;virtual;
    function NewDC: TDeviceContext;virtual;
    procedure DisposeDC(aDC: TDeviceContext);virtual;
    function CreateDCForWidget(TheWidget: PGtkWidget; TheWindow: PGdkWindow;
      WithChildWindows: boolean): HDC;
    function GetDoubleBufferedDC(Handle: HWND): HDC;

    // GDIObjects
    function IsValidGDIObject(const GDIObject: HGDIOBJ): Boolean;virtual;
    function IsValidGDIObjectType(const GDIObject: HGDIOBJ;
                                  const GDIType: TGDIType): Boolean;virtual;
    function NewGDIObject(const GDIType: TGDIType): PGdiObject;virtual;
    procedure DisposeGDIObject(GdiObject: PGdiObject);virtual;
    procedure SelectGDKBrushProps(DC: HDC);virtual;
    procedure SelectGDKTextProps(DC: HDC);virtual;
    procedure SelectGDKPenProps(DC: HDC);virtual;
    function CreateDefaultBrush: PGdiObject;virtual;
    function CreateDefaultFont: PGdiObject;virtual;
    function CreateDefaultPen: PGdiObject;virtual;
    procedure UpdateDCTextMetric(DC: TDeviceContext); virtual;
    {$Ifdef GTK2}
    function GetDefaultFontDesc(IncreaseReferenceCount: boolean): PPangoFontDescription;
    {$Endif}
    function GetDefaultGtkFont(IncreaseReferenceCount: boolean): TGtkIntfFont;
    function CreateRegionCopy(SrcRGN: hRGN): hRGN; override;
    function DCClipRegionValid(DC: HDC): boolean; override;
    function CreateEmptyRegion: hRGN; override;

    // images
    {$IfNDef NoGdkPixbufLib}
    procedure LoadPixbufFromLazResource(const ResourceName: string;
      var Pixbuf: PGdkPixbuf);
    {$EndIf}
    procedure LoadFromXPMFile(Bitmap: TObject; Filename: PChar);virtual;
    procedure LoadFromPixbufFile(Bitmap: TObject; Filename: PChar);virtual;
    procedure LoadFromPixbufData(Bitmap : hBitmap; Data : PByte);virtual;
    function InternalGetDIBits(DC: HDC; Bitmap: HBitmap; StartScan, NumScans: UINT;
      BitSize : Longint; Bits: Pointer; var BitInfo: BitmapInfo; Usage: UINT; DIB : Boolean): Integer;virtual;
    function GetWindowRawImageDescription(GDKWindow: PGdkWindow;
      Desc: PRawImageDescription): boolean;
    function GetRawImageFromGdkWindow(GDKWindow: PGdkWindow;
      MaskBitmap: PGdkBitmap; const SrcRect: TRect;
      out NewRawImage: TRawImage): boolean;
    function GetRawImageMaskFromGdkBitmap(MaskBitmap: PGdkBitmap;
      const SrcRect: TRect; var RawImage: TRawImage): boolean;
    function StretchCopyArea(DestDC: HDC; X, Y, Width, Height: Integer;
      SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer;
      Mask: HBITMAP; XMask, YMask: Integer;
      Rop: Cardinal): Boolean;

    // RC file
    procedure SetRCFilename(const AValue: string);virtual;
    procedure CheckRCFilename;virtual;
    procedure ParseRCFile;virtual;

    // notebook
    procedure AddDummyNoteBookPage(NoteBookWidget: PGtkNoteBook);virtual;

    // forms and dialogs
    procedure BringFormToFront(Sender: TObject);
    procedure SetWindowSizeAndPosition(Window: PGtkWindow;
      AWinControl: TWinControl);virtual;
    procedure UntransientWindow(GtkWindow: PGtkWindow);
    procedure InitializeFileDialog(FileDialog: TFileDialog;
      var SelWidget: PGtkWidget; Title: PChar); virtual;
    procedure InitializeFontDialog(FontDialog: TFontDialog;
      var SelWidget: PGtkWidget; Title: PChar);
    procedure InitializeCommonDialog(ADialog: TObject; AWindow: PGtkWidget);
    function CreateOpenDialogFilter(OpenDialog: TOpenDialog;
      SelWidget: PGtkWidget): string; virtual;
    procedure CreatePreviewDialogControl(PreviewDialog: TPreviewFileDialog;
      SelWidget: PGtkWidget); virtual;
    procedure InitializeOpenDialog(OpenDialog: TOpenDialog;
      SelWidget: PGtkWidget); virtual;

    // misc
    Function GetCaption(Sender : TObject) : String; virtual;
    procedure WordWrap(DC: HDC; AText: PChar; MaxWidthInPixel: integer;
      var Lines: PPChar; var LineCount: integer);

    procedure ResizeChild(Sender : TObject; Left,Top,Width,Height : Integer);virtual;
    procedure RemoveCallbacks(Widget: PGtkWidget); virtual;
    function ROP2ModeToGdkFunction(Mode: Integer): TGdkFunction;
    function gdkFunctionToROP2Mode(aFunction: TGdkFunction): Integer;

    // for gtk specific components:
    procedure SetLabelCaption(const ALabel: PGtkLabel; const ACaption: String;
                              const AComponent: TComponent;
                              const ASignalWidget: PGTKWidget;
                              const ASignal: PChar); virtual;
    procedure SetWidgetColor(const AWidget : PGtkWidget;
                             const FGColor,BGColor : TColor;
                             const Mask : tGtkStateEnum);
    procedure SetWidgetFont(const AWidget : PGtkWidget;const AFONT : tFont);
    procedure SetCallback(const AMsg: LongInt; const AGTKObject: PGTKObject;
                          const ALCLObject: TObject); virtual;
    procedure SendPaintMessagesForInternalWidgets(AWinControl: TWinControl);
    function  LCLtoGtkMessagePending: boolean;virtual;
    procedure SendCachedGtkMessages;virtual;
    procedure RealizeWidgetSize(Widget: PGtkWidget;
                                NewWidth, NewHeight: integer); virtual;
    procedure FinishComponentCreate(const ALCLObject: TObject;
              const AGTKObject: Pointer; const ASetupProps : Boolean); virtual;

    // show, hide and invalidate
    procedure ShowHide(Sender : TObject);virtual;

    // control functions for messages, callbacks
    procedure HookSignals(const AGTKObject: PGTKObject;
                          const ALCLObject: TObject); virtual;  //hooks all signals for controls
  public
    // Application
    procedure AppInit(var ScreenInfo: TScreenInfo); override;
    procedure AppProcessMessages; override;
    procedure AppWaitMessage; override;
    procedure AppTerminate; override;
    procedure AppMinimize; override;
    procedure AppRestore; override;
    procedure AppBringToFront; override;
    procedure AppSetTitle(const ATitle: string); override;
    function  WidgetSetName: string; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SendCachedLCLMessages; override;
    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure SetDesigning(AComponent: TComponent); override;

    // helper routines needed by interface methods
    procedure UnsetResizeRequest(Widget: PGtkWidget);virtual;
    procedure SetResizeRequest(Widget: PGtkWidget);virtual;
    // |-forms
    procedure UpdateTransientWindows; virtual;
    // |-listbox
    procedure SetSelectionMode(Sender: TObject; Widget: PGtkWidget;
                               MultiSelect, ExtendedSelect: boolean); virtual;
    function ForceLineBreaks(DC : hDC; Src: PChar; MaxWidthInPixels : Longint;
      ProcessAmpersands : Boolean) : PChar;

    // create and destroy
    function CreateComponent(Sender : TObject): THandle; override;
    function CreateTimer(Interval: integer; TimerFunc: TFNTimerProc) : THandle; override;
    function DestroyTimer(TimerHandle: THandle) : boolean; override;
    procedure DestroyLCLComponent(Sender: TObject);virtual;

    {$I gtkwinapih.inc}
    {$I gtklclintfh.inc}

  public
    property RCFilename: string read FRCFilename write SetRCFilename;
  end;

{$I gtklistslh.inc}
{$I gtkfiledialogutilsh.inc}

procedure CreateOpenDialogHistory(OpenDialog: TOpenDialog;
  SelWidget: PGtkWidget);

var
  GTKWidgetSet: TGTKWidgetSet;

implementation

uses
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To get as little as possible circles,
// uncomment only those units with implementation
////////////////////////////////////////////////////
// GtkWSActnList,
 GtkWSArrow,
 GtkWSButtons,
 GtkWSCalendar,
 GtkWSCheckLst,
// GtkWSCListBox,
 GtkWSComCtrls,
 GtkWSControls,
// GtkWSDbCtrls,
// GtkWSDBGrids,
 GtkWSDialogs,
// GtkWSDirSel,
// GtkWSEditBtn,
 GtkWSExtCtrls,
// GtkWSExtDlgs,
// GtkWSFileCtrl,
 GtkWSForms,
 GtkWSGrids,
// GtkWSImgList,
// GtkWSMaskEdit,
 GtkWSMenus,
// GtkWSPairSplitter,
 GtkWSSpin,
 GtkWSStdCtrls,
// GtkWSToolwin,
////////////////////////////////////////////////////
  Buttons, StdCtrls, PairSplitter,
  GTKWinApiWindow, ComCtrls, CListBox, Calendar, Arrow, Spin, CommCtrl,
  ExtCtrls, FileCtrl, LResources, gtkglobals;

const
  GtkNil = nil;

{$I gtklistsl.inc}
{$I gtkfiledialogutils.inc}
{$I gtkobject.inc}
{$I gtkwinapi.inc}
{$I gtklclintf.inc}


procedure InternalInit;
var
  c: TClipboardType;
  cr: TCursor;
begin
  gtk_handler_quark := g_quark_from_static_string('gtk-signal-handlers');

  MouseCaptureWidget := nil;
  MouseCaptureType := mctGTK;

  LastLeft:=EmptyLastMouseClick;
  LastMiddle:=EmptyLastMouseClick;
  LastRight:=EmptyLastMouseClick;

  // clipboard
  ClipboardSelectionData:=TFPList.Create;
  for c:=Low(TClipboardType) to High(TClipboardType) do begin
    ClipboardTypeAtoms[c]:=0;
    ClipboardHandler[c]:=nil;
    //ClipboardIgnoreLossCount[c]:=0;
    ClipboardTargetEntries[c]:=nil;
    ClipboardTargetEntryCnt[c]:=0;
  end;

  // mouse cursors
  MMouseCursorMap := TMap.Create(its2, SizeOf(PGDKCursor));

  // charset encodings
  CharSetEncodingList := TList.Create;
  CreateDefaultCharsetEncodings;
  
  InitDesignSignalMasks;
end;

procedure InternalFinal;
var i: integer;
  ced: PClipboardEventData;
  c: TClipboardType;
begin
  // clipboard
  for i:=0 to ClipboardSelectionData.Count-1 do begin
    ced:=PClipboardEventData(ClipboardSelectionData[i]);
    if ced^.Data.Data<>nil then FreeMem(ced^.Data.Data);
    Dispose(ced);
  end;
  for c:=Low(TClipboardType) to High(TClipboardType) do
    FreeClipboardTargetEntries(c);
  ClipboardSelectionData.Free;
  ClipboardSelectionData:=nil;
  
  // charset encodings
  if CharSetEncodingList<>nil then begin
    ClearCharSetEncodings;
    CharSetEncodingList.Free;
    CharSetEncodingList:=nil;
  end;
  
  FreeAndNil(MMouseCursorMap);
end;


initialization
  {$I gtkimages.lrs}
  InternalInit;

finalization
  InternalFinal;

end.
