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
unit GTKProc;

{$mode objfpc}{$H+}

interface

{$IFDEF win32}
{$DEFINE NoGdkPixbufLib}
{$ELSE}
{off $DEFINE NoGdkPixbufLib}
{$ENDIF}

{off $DEFINE GDK_ERROR_TRAP_FLUSH}
{$DEFINE REPORT_GDK_ERRORS}

uses
  SysUtils, Classes,
  {$IFDEF GTK1}
  {$Ifndef Win32}
  X, XLib,//Font retrieval
  {$EndIf}
  {$EndIf}
  InterfaceBase,
  {$IFDEF gtk2}
  glib2, gdk2pixbuf, gdk2, gtk2, Pango,
  {$ELSE}
  glib, gdk, gtk, {$Ifndef NoGdkPixbufLib}gdkpixbuf,{$EndIf}
  {$ENDIF}
  LMessages, Controls, Forms, VclGlobals, LCLProc,
  LCLStrConsts, LCLIntf, LCLType, gtkDef, DynHashArray, LazLinkedList,
  GraphType, GraphMath, Graphics, Buttons, Menus, GTKWinApiWindow, StdCtrls,
  ComCtrls, CListBox, KeyMap, Calendar, Arrow, Spin, CommCtrl, ExtCtrls,
  Dialogs, ExtDlgs, FileCtrl, LResources, Math, GTKGlobals;


  {$IFDEF gtk2}
    const 
      gdkdll = gdklib;
  {$ENDIF}
  

{$IFNDEF GTK2}
  function  GTK_TYPE_WIDGET  : TGTKType; cdecl; external gtkdll name 'gtk_widget_get_type';
  function  GTK_TYPE_CONTAINER : TGTKType; cdecl; external gtkdll name 'gtk_container_get_type';
  function  GTK_TYPE_BIN  : TGTKType; cdecl; external gtkdll name 'gtk_bin_get_type';
  function  GTK_TYPE_HBOX  : TGTKType; cdecl; external gtkdll name 'gtk_hbox_get_type';
  function  GTK_TYPE_SCROLLED_WINDOW : TGTKType; cdecl; external gtkdll name 'gtk_scrolled_window_get_type';
  function  GTK_TYPE_COMBO  : TGTKType; cdecl; external gtkdll name 'gtk_combo_get_type';
  function  GTK_TYPE_WINDOW  : TGTKType; cdecl; external gtkdll name 'gtk_window_get_type';
  function  GTK_TYPE_MENU  : TGTKType; cdecl; external gtkdll name 'gtk_menu_get_type';
  function  GTK_TYPE_MENU_ITEM  : TGTKType; cdecl; external gtkdll name 'gtk_menu_item_get_type';
  function  GTK_TYPE_MENU_BAR  : TGTKType; cdecl; external gtkdll name 'gtk_menu_bar_get_type';
  function  GTK_TYPE_RADIO_MENU_ITEM  : TGTKType; cdecl; external gtkdll name 'gtk_radio_menu_item_get_type';
  function  GTK_TYPE_CHECK_MENU_ITEM  : TGTKType; cdecl; external gtkdll name 'gtk_check_menu_item_get_type';
  function  GTK_TYPE_TEXT  : TGTKType; cdecl; external gtkdll name 'gtk_text_get_type';
  function  GTK_TYPE_ENTRY  : TGTKType; cdecl; external gtkdll name 'gtk_entry_get_type';
  function  GTK_TYPE_RANGE  : TGTKType; cdecl; external gtkdll name 'gtk_range_get_type';
  function  GTK_TYPE_SCROLLBAR : TGTKType; cdecl; external gtkdll name 'gtk_scrollbar_get_type';
  function  GTK_TYPE_HSCROLLBAR : TGTKType; cdecl; external gtkdll name 'gtk_hscrollbar_get_type';
  function  GTK_TYPE_VSCROLLBAR : TGTKType; cdecl; external gtkdll name 'gtk_vscrollbar_get_type';
{$ENDIF}

procedure laz_gdk_gc_set_dashes(gc:PGdkGC; dash_offset:gint;
  dashlist:Pgint8; n:gint); cdecl; external gdkdll name 'gdk_gc_set_dashes';


// GTKCallback.inc headers
procedure EventTrace(const TheMessage : string; data : pointer);
function gtkNoteBookCloseBtnClicked(Widget: PGtkWidget;
  Data: Pointer): GBoolean; cdecl;
function gtkRealizeCB(Widget: PGtkWidget; Data: Pointer): GBoolean; cdecl;
function gtkRealizeAfterCB(Widget: PGtkWidget; Data: Pointer): GBoolean; cdecl;
function gtkshowCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkHideCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkactivateCB(widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkchangedCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkchanged_editbox( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkdaychanged(Widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
{$Ifdef GTK1}
function gtkDrawAfter(Widget: PGtkWidget; area: PGDKRectangle;
  data: gPointer) : GBoolean; cdecl;
{$EndIf}
function gtkExposeEventAfter(Widget: PGtkWidget; Event : PGDKEventExpose;
  Data: gPointer): GBoolean; cdecl;
function gtkfrmactivateAfter( widget: PGtkWidget; Event : PgdkEventFocus;
  data: gPointer) : GBoolean; cdecl;
function gtkfrmdeactivateAfter( widget: PGtkWidget; Event : PgdkEventFocus;
  data: gPointer) : GBoolean; cdecl;
function GTKMap(Widget: PGTKWidget; Data: gPointer): GBoolean; cdecl;
function GTKKeyUpDown(Widget: PGtkWidget; Event : pgdkeventkey;
  Data: gPointer) : GBoolean; cdecl;
function GTKFocusCB(widget: PGtkWidget; event:PGdkEventFocus; data: gPointer) : GBoolean; cdecl;
function GTKFocusCBAfter(widget: PGtkWidget; event:PGdkEventFocus; data: gPointer) : GBoolean; cdecl;
function GTKKillFocusCB(widget: PGtkWidget; event:PGdkEventFocus; data: gPointer) : GBoolean; cdecl;
function GTKKillFocusCBAfter(widget: PGtkWidget; event:PGdkEventFocus; data: gPointer) : GBoolean; cdecl;
function gtkdestroyCB(widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkdeleteCB( widget : PGtkWidget; event : PGdkEvent; data : gPointer) : GBoolean; cdecl;
function gtkresizeCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkMonthChanged(Widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
procedure DeliverMouseMoveMessage(Widget:PGTKWidget; Event: PGDKEventMotion;
  AWinControl: TWinControl);
function ControlGetsMouseMoveBefore(AControl: TControl): boolean;
function gtkMotionNotify(Widget:PGTKWidget; Event: PGDKEventMotion;
  Data: gPointer): GBoolean; cdecl;
function GTKMotionNotifyAfter(widget:PGTKWidget; event: PGDKEventMotion;
  data: gPointer): GBoolean; cdecl;
function ControlGetsMouseDownBefore(AControl: TControl): boolean;
procedure DeliverMouseDownMessage(widget: PGtkWidget; event : pgdkEventButton;
  AWinControl: TWinControl);
function gtkMouseBtnPress(widget: PGtkWidget; event : pgdkEventButton;
  data: gPointer) : GBoolean; cdecl;
function gtkMouseBtnPressAfter(widget: PGtkWidget; event : pgdkEventButton;
  data: gPointer) : GBoolean; cdecl;
function ControlGetsMouseUpBefore(AControl: TControl): boolean;
procedure DeliverMouseUpMessage(widget: PGtkWidget; event : pgdkEventButton;
  AWinControl: TWinControl);
function gtkMouseBtnRelease(widget: PGtkWidget; event : pgdkEventButton;
  data: gPointer) : GBoolean; cdecl;
function gtkMouseBtnReleaseAfter(widget: PGtkWidget; event : pgdkEventButton;
  data: gPointer) : GBoolean; cdecl;
function gtkclickedCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;

function gtkOpenDialogRowSelectCB( widget : PGtkWidget; row : gint;
  column : gint; event : pgdkEventButton; data : gPointer ) : GBoolean; cdecl;
function gtkDialogOKclickedCB( widget: PGtkWidget;
  data: gPointer) : GBoolean; cdecl;
function gtkDialogCancelclickedCB(widget: PGtkWidget; data: gPointer): GBoolean;cdecl;
function gtkDialogHelpclickedCB(widget: PGtkWidget; data: gPointer): GBoolean;cdecl;
function gtkDialogApplyclickedCB(widget: PGtkWidget; data: gPointer): GBoolean; cdecl;
function gtkDialogCloseQueryCB(widget: PGtkWidget; data: gPointer): GBoolean; cdecl;
procedure UpdateDetailView(OpenDialog: TOpenDialog);
function GTKDialogKeyUpDownCB(Widget: PGtkWidget; Event : pgdkeventkey;
  Data: gPointer) : GBoolean; cdecl;
function GTKDialogRealizeCB(Widget: PGtkWidget; Data: Pointer): GBoolean; cdecl;
function GTKDialogFocusInCB(widget: PGtkWidget; data: gPointer): GBoolean; cdecl;
function GTKDialogSelectRowCB(widget: PGtkWidget; Row, Column: gInt;
  bevent: pgdkEventButton; data: gPointer): GBoolean; cdecl;
function GTKDialogMenuActivateCB(widget: PGtkWidget; data: gPointer): GBoolean; cdecl;
function gtkDialogDestroyCB(widget: PGtkWidget; data: gPointer): GBoolean; cdecl;

function gtkPressedCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkEnterCB(widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkLeaveCB(widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkMoveCursorCB(widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtksize_allocateCB(widget: PGtkWidget; size :pGtkAllocation;
  data: gPointer) : GBoolean; cdecl;
function gtksize_allocate_client(widget: PGtkWidget; size :pGtkAllocation;
  data: gPointer) : GBoolean; cdecl;
function gtkswitchpage(widget: PGtkWidget; page: Pgtkwidget; pagenum : integer;
  data: gPointer) : GBoolean; cdecl;
function gtkconfigureevent( widget: PGtkWidget; event : PgdkEventConfigure;
  data: gPointer) : GBoolean; cdecl;
function gtkreleasedCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkInsertText( widget: PGtkWidget; char : pChar; NewTextLength : Integer; Position : pgint; data: gPointer) : GBoolean; cdecl;
function gtkDeleteText( widget: PGtkWidget; Startpos, EndPos : Integer; data: gPointer) : GBoolean; cdecl;
function gtkSetEditable( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkMoveWord( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkMovePage( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkMoveToRow( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkMoveToColumn( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkKillChar( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkKillWord( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkKillLine( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkCutToClip( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkCopyToClip( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkPasteFromClip( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkValueChanged(widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
function gtkTimerCB(Data: gPointer): {$IFDEF Gtk2}gBoolean{$ELSE}gint{$ENDIF}; cdecl;
function gtkFocusInNotifyCB (widget : PGtkWidget; event : PGdkEvent;
  data : gpointer) : GBoolean; cdecl;
function gtkFocusOutNotifyCB (widget : PGtkWidget; event : PGdkEvent;
  data : gpointer) : GBoolean; cdecl;
function GTKHScrollCB(Adjustment: PGTKAdjustment; data: GPointer): GBoolean; cdecl;
function GTKVScrollCB(Adjustment: PGTKAdjustment;
  data: GPointer): GBoolean; cdecl;
function GTKCheckMenuToggeledCB(AMenuItem: PGTKCheckMenuItem; AData: gPointer): GBoolean; cdecl;
function GTKKeySnooper(Widget: PGtkWidget; Event: PGdkEventKey;
  FuncData: gPointer): gInt; cdecl;
function gtkYearChanged(Widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
procedure ClipboardSelectionReceivedHandler(TargetWidget: PGtkWidget;
  SelectionData: PGtkSelectionData; TimeID: cardinal; Data: Pointer); cdecl;
procedure ClipboardSelectionRequestHandler(TargetWidget: PGtkWidget;
  SelectionData: PGtkSelectionData; Info: cardinal; TimeID: cardinal;
  Data: Pointer); cdecl;
function ClipboardSelectionLostOwnershipHandler(TargetWidget: PGtkWidget;
  EventSelection: PGdkEventSelection;  Data: Pointer): cardinal; cdecl;
Procedure GTKStyleChanged(Widget: PGtkWidget; previous_style :
  PGTKStyle; Data: Pointer); cdecl;

function DeliverPostMessage(const Target: Pointer; var TheMessage): GBoolean;
function DeliverMessage(const Target: Pointer; var AMessage): Integer;

// gtkDragCallback.inc headers
Function edit_drag_data_received(widget : pgtkWidget;
			          Context : pGdkDragContext;
			          X : Integer;
			          Y : Integer;
			          seldata : pGtkSelectionData;
			          info : Integer;
			          time : Integer;
                                  data : pointer) : GBoolean; cdecl;
Function edit_source_drag_data_get(widget : pgtkWidget;
			          Context : pGdkDragContext;
			          Selection_data : pGtkSelectionData;
			          info : Integer;
			          time : Integer;
                                  data : pointer) : GBoolean; cdecl;
Function Edit_source_drag_data_delete (widget : pGtkWidget;
			                context : pGdkDragContext;
			                data : gpointer): gBoolean ; cdecl;

// gtkListViewCallback.inc headers

function gtkLVHScroll(AList: PGTKCList; AData: gPointer): GBoolean; cdecl;
function gtkLVVScroll(AList: PGTKCList; AData: gPointer): GBoolean; cdecl;
function gtkLVAbortColumnResize(AList: PGTKCList; AData: gPointer): GBoolean; cdecl;
function gtkLVResizeColumn(AList: PGTKCList; AColumn, AWidth: Integer; AData: gPointer): GBoolean; cdecl;
function gtkLVClickColumn(AList: PGTKCList; AColumn: Integer; AData: gPointer): GBoolean; cdecl;
function gtkLVRowMove(AList: PGTKCList; AnOldIdx, ANewIdx: Integer; AData: gPointer): GBoolean; cdecl;
function gtkLVSelectRow(AList: PGTKCList; ARow, AColumn: Integer; AEvent: PGDKEventButton; AData: gPointer): GBoolean; cdecl;
function gtkLVUnSelectRow(AList: PGTKCList; ARow, AColumn: Integer; AEvent: PGDKEventButton; AData: gPointer): GBoolean; cdecl;
function gtkLVToggleFocusRow(AList: PGTKCList; AData: gPointer): GBoolean; cdecl;
function gtkLVSelectAll(AList: PGTKCList; AData: gPointer): GBoolean; cdecl;
function gtkLVUnSelectAll(AList: PGTKCList; AData: gPointer): GBoolean; cdecl;
function gtkLVEndSelection(AList: PGTKCList; AData: gPointer): GBoolean; cdecl;

// gtkComboBoxCallback.inc headers
function gtkComboBoxShowCB(widget: PGtkWidget; data: gPointer): GBoolean; cdecl;
function gtkComboBoxHideCB(widget: PGtkWidget; data: gPointer): GBoolean; cdecl;

// functions
procedure Set_RC_Name(Sender : TObject; AWidget: PGtkWidget);

procedure RaiseException(const Msg: string);

function CreatePChar(const s: string): PChar;
function ComparePChar(P1, P2: PChar): boolean;
function FindChar(c: char; p:PChar; Max: integer): integer;

function GtkWidgetIsA(Widget: PGtkWidget; AType: TGtkType): boolean;
function WidgetIsDestroyingHandle(Widget: PGtkWidget): boolean;
procedure SetWidgetIsDestroyingHandle(Widget: PGtkWidget);
function ComponentIsDestroyingHandle(AWinControl: TWinControl): boolean;
function LockOnChange(GtkObject: PGtkObject; LockOffset: integer): integer;
function ObjectToGTKObject(const AObject: TObject): PGtkObject;
function GetMainWidget(const Widget: Pointer): Pointer;
procedure SetMainWidget(const ParentWidget, ChildWidget: Pointer);
function GetFixedWidget(const Widget: Pointer): Pointer;
procedure SetFixedWidget(const ParentWidget, FixedWidget: Pointer);
Function GetControlWindow(Widget: Pointer) : PGDKWindow;
function GetDCOffset(DC: TDeviceContext): TPoint;
function CreateWidgetInfo(const Widget: Pointer): PWinWidgetInfo;
function GetWidgetInfo(const Widget: Pointer; const Create: Boolean): PWinWidgetInfo;
procedure FreeWinWidgetInfo(Widget: Pointer);
procedure DestroyWidget(Widget: PGtkWidget);
procedure SetLCLObject(const Widget: Pointer; const AnObject: TObject);
function GetLCLObject(const Widget: Pointer): TObject;
function GetParentLCLObject(Widget: PGtkWidget): TObject;
procedure SetHiddenLCLObject(const Widget: Pointer; const AnObject: TObject);
function GetHiddenLCLObject(const Widget: Pointer): TObject;
Procedure FixedMoveControl(Parent, Child : PGTKWIdget; Left, Top : Longint);
Procedure FixedPutControl(Parent, Child : PGTKWidget; Left, Top : Longint);
function GetParentWidget(Child: PGtkWidget): PGtkWidget;
function GetParentFixedWidget(Child: PGtkWidget): PGtkWidget;
function FindFixedChild(ParentFixed: PGtkFixed; Child: PGtkWidget): PGList;
procedure MoveGListLinkBehind(First, Item, After: PGList);

procedure SetComboBoxText(ComboWidget: PGtkCombo; NewText: PChar);
function GetComboBoxItemIndex(ComboBox: TComboBox): integer;
procedure SetComboBoxItemIndex(ComboBox: TComboBox; Index: integer);

function GtkPaintMessageToPaintMessage(const GtkPaintMsg: TLMGtkPaint;
  FreeGtkPaintMsg: boolean): TLMPaint;
procedure FinalizePaintMessage(Msg: PLMessage);
procedure FinalizePaintTagMsg(Msg: PMsg);

function NewGDI_RGBImage(const AWidth, AHeight: Integer; const ADepth: Byte): PGDI_RGBImage;

function CopyDCData(DestinationDC, SourceDC: TDeviceContext): Boolean;

Function RegionType(RGN: PGDKRegion): Longint;
Procedure SelectGDIRegion(const DC: HDC);
function GDKRegionAsString(RGN: PGDKRegion): string;
function CreateRectGDKRegion(const ARect: TRect): PGDKRegion;

Procedure FreeGDIColor(GDIColor : PGDIColor);
Procedure AllocGDIColor(DC: hDC; GDIColor: PGDIColor);
procedure BuildColorRefFromGDKColor(var GDIColor : TGDIColor);
procedure SetGDIColorRef(var GDIColor : TGDIColor; NewColorRef: TColorRef);
Procedure EnsureGCColor(DC: hDC; ColorType: TDevContextsColorType;
  IsSolidBrush, AsBackground: Boolean);
procedure CopyGDIColor(var SourceGDIColor, DestGDIColor: TGDIColor);
function AllocGDKColor(const AColor: LongInt): TGDKColor;
function TGDKColorToTColor(const value : TGDKColor) : TColor;
function TColortoTGDKColor(const value : TColor) : TGDKColor;
procedure UpdateSysColorMap(Widget: PGtkWidget);

function CompareGDIColor(const Color1, Color2: TGDIColor): boolean;
function CompareGDIFill(const Fill1, Fill2: TGdkFill): boolean;
function CompareGDIBrushes(Brush1, Brush2: PGdiObject): boolean;

function PaletteIndexExists(Pal : PGDIObject; I : longint): Boolean;
function PaletteRGBExists(Pal : PGDIObject; RGB : longint): Boolean;
function PaletteAddIndex(Pal : PGDIObject; I, RGB : Longint): Boolean;
function PaletteDeleteIndex(Pal : PGDIObject; I : Longint): Boolean;
function PaletteIndexToRGB(Pal : PGDIObject; I : longint): longint;
function PaletteRGBToIndex(Pal : PGDIObject; RGB : longint): longint;
Procedure InitializePalette(Pal : PGDIObject; Entries : PPALETTEENTRY; RGBCount : Longint);
function GetIndexAsKey(p: pointer): pointer;
function GetRGBAsKey(p: pointer): pointer;

function GTKEventState2ShiftState(KeyState: Word): TShiftState;
function KeyToListCode(KeyCode, VirtKeyCode: Word; Extended: boolean): integer;
procedure GetGTKKeyInfo(const Event: PGDKEventKey; var KeyCode,VirtualKey: Word;
  var SysKey, Extended, Toggle: Boolean; var ShiftState: TShiftState);

procedure StoreCommonDialogSetup(ADialog: TCommonDialog);
procedure DestroyCommonDialogAddOns(ADialog: TCommonDialog);

function GetGtkNoteBookDummyPage(ANoteBookWidget: PGtkNoteBook): PGtkWidget;
procedure SetGtkNoteBookDummyPage(ANoteBookWidget: PGtkNoteBook;
  DummyWidget: PGtkWidget);
procedure UpdateNoteBookClientWidget(ANoteBook: TObject);
function GetGtkNoteBookPageCount(ANoteBookWidget: PGtkNoteBook): integer;

function GetWidgetOrigin(TheWidget: PGtkWidget): TPoint;
function GetWidgetClientOrigin(TheWidget: PGtkWidget): TPoint;
function TranslateGdkPointToClientArea(SourceWindow: PGdkWindow;
  SourcePos: TPoint;  DestinationWidget: PGtkWidget): TPoint;
procedure ReleaseMouseCapture(OnlyIfCapturedByLCL: boolean);
procedure UpdateMouseCaptureControl;
procedure SetCursor(AWinControl : TWinControl; Data: Pointer);

type
  TConnectSignalFlag = (
    csfAfter,            // connect after signal
    csfConnectRealize,   // auto connect realize handler
    csfUpdateSignalMask, // extend signal mask for gdkwindow
    csfDesignOnly        // mark signal as design only
    );
  TConnectSignalFlags = set of TConnectSignalFlag;

  TDesignSignalType = (
    dstUnknown,
    dstMousePress,
    dstMouseMotion,
    dstMouseRelease,
{$Ifdef GTK1}
    dstDrawAfter,
{$EndIf}
    dstExposeAfter
    );
  TDesignSignalTypes = set of TDesignSignalType;

  TDesignSignalMask = longint;

const
    DesignSignalNames: array[TDesignSignalType] of PChar = (
    '',
    'button-press-event',
    'motion-notify-event',
    'button-release-event',
{$Ifdef GTK1}
    'draw',
{$EndIf}
    'expose-event'
    );

  DesignSignalAfter: array[TDesignSignalType] of boolean =
    (false,false,false,false,{$Ifdef GTK1}true,{$EndIf}true);

  DesignSignalFuncs: array[TDesignSignalType] of Pointer = (
    nil,
    @gtkMouseBtnPress,
    @gtkMotionNotify,
    @gtkMouseBtnRelease,
{$Ifdef GTK1}
    @gtkDrawAfter,
{$EndIf}
    @gtkExposeEventAfter
    );

var
  DesignSignalMasks: array[TDesignSignalType] of TDesignSignalMask;
  
{$IFDEF GTK1}
var
  X11Display : Pointer;//only needed to get X fonts
{$EndIf}
procedure InitDesignSignalMasks;
function DesignSignalNameToType(Name: PChar; After: boolean): TDesignSignalType;
function GetDesignSignalMask(Widget: PGtkWidget): TDesignSignalMask;
procedure SetDesignSignalMask(Widget: PGtkWidget; NewMask: TDesignSignalMask);
function GetDesignOnlySignalFlag(Widget: PGtkWidget;
  DesignSignalType: TDesignSignalType): boolean;

procedure ConnectSignal(const AnObject:PGTKObject; const ASignal: PChar;
  const ACallBackProc: Pointer; LCLComponent: TComponent;
  const ReqSignalMask: TGdkEventMask; SFlags: TConnectSignalFlags);
procedure ConnectSignal(const AnObject:PGTKObject; const ASignal: PChar;
  const ACallBackProc: Pointer; LCLComponent: TComponent;
  const ReqSignalMask: TGdkEventMask);
procedure ConnectSignalAfter(const AnObject:PGTKObject; const ASignal: PChar;
  const ACallBackProc: Pointer; LCLComponent: TComponent;
  const ReqSignalMask: TGdkEventMask);
procedure ConnectSignal(const AnObject:PGTKObject; const ASignal: PChar;
  const ACallBackProc: Pointer; LCLComponent: TComponent);
procedure ConnectSignalAfter(const AnObject:PGTKObject; const ASignal: PChar;
  const ACallBackProc: Pointer; LCLComponent: TComponent);

procedure ConnectInternalWidgetsSignals(AWidget: PGtkWidget;
  AWinControl: TWinControl);
  
// accelerators
Function DeleteAmpersands(var Str : String) : Longint;
function Ampersands2Underscore(Src: PChar) : PChar;
function RemoveAmpersands(Src: PChar; LineLength : Longint) : PChar;

{$Ifdef GTK2}
Procedure GetTextExtentIgnoringAmpersands(FontDesc : PPangoFontDescription; Str : PChar;
  LineLength : Longint; lbearing, rbearing, width, ascent, descent : Pgint);
{$Else}
Procedure GetTextExtentIgnoringAmpersands(Font : PGDKFont; Str : PChar;
  LineLength : Longint; lbearing, rbearing, width, ascent, descent : Pgint);
{$EndIf}

function GetAccelGroup(const Widget: PGtkWidget;
  CreateIfNotExists: boolean): PGTKAccelGroup;
procedure SetAccelGroup(const Widget: PGtkWidget;
  const AnAccelGroup: PGTKAccelGroup);
procedure FreeAccelGroup(const Widget: PGtkWidget);
procedure RegroupAccelerator(Widget: PGtkWidget);
procedure ClearAccelKey(Widget: PGtkWidget);
procedure Accelerate(Component: TComponent; const Widget : PGtkWidget;
  const Key: guint; Mods: TGdkModifierType; const Signal : string);
procedure Accelerate(Component: TComponent; const Widget : PGtkWidget;
  const Msg : TLMShortCut; const Signal : string);
procedure ShareWindowAccelGroups(AWindow: PGtkWidget);
procedure UnshareWindowAccelGroups(AWindow: PGtkWidget);

procedure GetGdkPixmapFromGraphic(LCLGraphic: TGraphic;
  var IconImg, IconMask: PGdkPixmap; var Width, Height: integer);

// menus
function MENU_ITEM_CLASS(widget: PGtkWidget): PGtkMenuItemClass;
function CHECK_MENU_ITEM_CLASS(widget: PGtkWidget): PGtkCheckMenuItemClass;
function GetRadioMenuItemGroup(LCLMenuItem: TMenuItem): PGSList;
function GetRadioMenuItemGroup(MenuItem: PGtkRadioMenuItem): PGSList;
procedure LockRadioGroupOnChange(RadioGroup: PGSList; const ADelta: Integer);
procedure UpdateRadioGroupChecks(RadioGroup: PGSList);
procedure DrawMenuItemIcon(MenuItem: PGtkCheckMenuItem;
  Area: PGdkRectangle); cdecl;
procedure MenuSizeRequest(widget:PGtkWidget; requisition:PGtkRequisition); cdecl;
procedure UpdateInnerMenuItem(LCLMenuItem: TMenuItem;
  MenuItemWidget: PGtkWidget);
function CreateMenuItem(LCLMenuItem: TMenuItem): Pointer;
procedure GetGdkPixmapFromMenuItem(LCLMenuItem: TMenuItem;
  var IconImg, IconMask: PGdkPixmap; var Width, Height: integer);

procedure SaveSizeNotification(Widget: PGtkWidget);
procedure SaveClientSizeNotification(FixWidget: PGtkWidget);
function CreateTopologicalSortedWidgets(HashArray: TDynHashArray): TList;
Procedure ReportNotObsolete(const Texts : String);
function WaitForClipboardAnswer(c: PClipboardEventData): boolean;
function RequestSelectionData(ClipboardWidget: PGtkWidget;
  ClipboardType: TClipboardType;  FormatID: cardinal): TGtkSelectionData;
procedure FreeClipboardTargetEntries(ClipboardType: TClipboardType);

Function CreateFormContents(var FormWidget : Pointer) : Pointer;

function IndexOfStyle(const WName : String): integer;
Procedure ReleaseStyle(const WName : String);
function GetStyle(const WName : String) : PGTKStyle;
Function GetStyleWidget(const WName : String) : PGTKWidget;
Procedure StyleFillRectangle(drawable : PGDKDrawable; GC : PGDKGC; Color : TColorRef; x, y, width, height : gint);
Function StyleForegroundColor(Color : TColorRef; DefaultColor : PGDKColor): PGDKColor;

{$Ifdef GTK2}
function LoadDefaultFontDesc: PPangoFontDescription;
{$Else}
function LoadDefaultFont: PGDKFont;
{$EndIf}

Function GetSysGCValues(Color : TColorRef) : TGDKGCValues;

{$Ifdef GTK1}
function FontIsDoubleByteCharsFont(TheFont: PGdkFont): boolean;
{$EndIf}

Function GDKPixel2GDIRGB(Pixel : Longint; Visual : PGDKVisual;
  Colormap : PGDKColormap) : TGDIRGB;

Function GetWindowDecorations(AForm : TCustomForm) : Longint;
Function GetWindowFunction(AForm : TCustomForm) : Longint;

Procedure FillScreenFonts(ScreenFonts : TStrings);

function GetGDKMouseCursor(Cursor: TCursor): PGdkCursor;
Procedure FreeGDKCursors;

// functions for easier GTK2<->GTK1 Compatibility/Consistancy  ---->
function gtk_widget_get_xthickness(Style : PGTKStyle) : gint; overload;
function gtk_widget_get_ythickness(Style : PGTKStyle) : gint; overload;

function gtk_widget_get_xthickness(Style : PGTKWidget) : gint; overload;
function gtk_widget_get_ythickness(Style : PGTKWidget) : gint; overload;

procedure gdk_event_key_get_string(Event : PGDKEventKey; var theString : PPgchar);
function gdk_event_get_type(Event : Pointer) : guint;

procedure BeginGDKErrorTrap;
procedure EndGDKErrorTrap;

{$Ifdef GTK1}
  const
    GDK_key_dead_circumflex = GDK_dead_circumflex;
    GDK_KEY_KP_Space = GDK_KP_Space;
    GDK_KEY_KP_ENTER = GDK_KP_ENTER;
    GDK_KEY_Tab = GDK_Tab;
    GDK_KEY_ISO_Left_Tab = GDK_ISO_Left_Tab;
    GDK_KEY_KP_Tab = GDK_KP_Tab;
    GDK_KEY_RETURN = GDK_Return;
    GDK_KEY_LINEFEED = GDK_LINEFEED;
    GDK_KEY_INSERT = GDK_INSERT;
    GDK_KEY_HOME = GDK_HOME;
    GDK_KEY_LEFT = GDK_LEFT;
    GDK_KEY_UP = GDK_UP;
    GDK_KEY_RIGHT = GDK_RIGHT;
    GDK_KEY_DOWN = GDK_DOWN;
    GDK_KEY_Page_Up = GDK_Page_Up;
    GDK_KEY_Page_Down = GDK_Page_Down;
    GDK_KEY_End = GDK_End;
    GDK_KEY_KP_INSERT = GDK_KP_INSERT;
    GDK_KEY_KP_HOME = GDK_KP_HOME;
    GDK_KEY_KP_LEFT = GDK_KP_LEFT;
    GDK_KEY_KP_UP = GDK_KP_UP;
    GDK_KEY_KP_RIGHT = GDK_KP_RIGHT;
    GDK_KEY_KP_DOWN = GDK_KP_DOWN;
    GDK_KEY_KP_PAGE_UP = GDK_KP_PAGE_UP;
    GDK_KEY_KP_PAGE_DOWN = GDK_KP_PAGE_DOWN;
    GDK_KEY_KP_END = GDK_KP_END;
    GDK_KEY_Num_Lock = GDK_Num_Lock;
    GDK_KEY_KP_F1 = GDK_KP_F1;
    GDK_KEY_KP_F2 = GDK_KP_F2;
    GDK_KEY_KP_F3 = GDK_KP_F3;
    GDK_KEY_KP_F4 = GDK_KP_F4;
    GDK_KEY_KP_EQUAL = GDK_KP_EQUAL;
    GDK_KEY_KP_Multiply = GDK_KP_Multiply;
    GDK_KEY_KP_Add = GDK_KP_Add;
    GDK_KEY_KP_Separator = GDK_KP_Separator;
    GDK_KEY_KP_Subtract = GDK_KP_Subtract;
    GDK_KEY_KP_Decimal = GDK_KP_Decimal;
    GDK_KEY_KP_Divide = GDK_KP_Divide;
    GDK_KEY_KP_0 = GDK_KP_0;
    GDK_KEY_KP_1 = GDK_KP_1;
    GDK_KEY_KP_2 = GDK_KP_2;
    GDK_KEY_KP_3 = GDK_KP_3;
    GDK_KEY_KP_4 = GDK_KP_4;
    GDK_KEY_KP_5 = GDK_KP_5;
    GDK_KEY_KP_6 = GDK_KP_6;
    GDK_KEY_KP_7 = GDK_KP_7;
    GDK_KEY_KP_8 = GDK_KP_8;
    GDK_KEY_KP_9 = GDK_KP_9;
    GDK_KEY_BackSpace = GDK_BackSpace;
    GDK_KEY_Clear = GDK_Clear_Key;
    GDK_KEY_Pause = GDK_Pause;
    GDK_KEY_Scroll_Lock = GDK_Scroll_Lock;
    GDK_KEY_Sys_Req = GDK_Sys_Req;
    GDK_KEY_Escape = GDK_Escape;
    GDK_KEY_Delete = GDK_Delete_Key;
    GDK_KEY_Kanji = GDK_Kanji;
    GDK_KEY_Select = GDK_Select;
    GDK_KEY_Print = GDK_Print;
    GDK_KEY_Execute = GDK_Execute;
    GDK_KEY_Menu = GDK_Menu;
    GDK_KEY_Cancel = GDK_Cancel;
    GDK_KEY_Help = GDK_Help;
    GDK_KEY_Break = GDK_Break;
    GDK_KEY_Mode_switch = GDK_Mode_switch;
    GDK_KEY_Caps_Lock = GDK_Caps_Lock;
    GDK_KEY_Shift_L = GDK_Shift_L;
    GDK_KEY_Shift_R = GDK_Shift_R;
    GDK_KEY_Control_L = GDK_Control_L;
    GDK_KEY_Control_R = GDK_Control_R;
    GDK_KEY_Alt_L = GDK_Alt_L;
    GDK_KEY_Alt_R = GDK_Alt_R;
    GDK_KEY_F1 = GDK_F1;
    GDK_KEY_F2 = GDK_F2;
    GDK_KEY_F3 = GDK_F3;
    GDK_KEY_F4 = GDK_F4;
    GDK_KEY_F5 = GDK_F5;
    GDK_KEY_F6 = GDK_F6;
    GDK_KEY_F7 = GDK_F7;
    GDK_KEY_F8 = GDK_F8;
    GDK_KEY_F9 = GDK_F9;
    GDK_KEY_F10 = GDK_F10;
    GDK_KEY_F11 = GDK_F11;
    GDK_KEY_F12 = GDK_F12;
    GDK_KEY_F13 = GDK_F13;
    GDK_KEY_F14 = GDK_F14;
    GDK_KEY_F15 = GDK_F15;
    GDK_KEY_F16 = GDK_F16;
    GDK_KEY_F17 = GDK_F17;
    GDK_KEY_F18 = GDK_F18;
    GDK_KEY_F19 = GDK_F19;
    GDK_KEY_F20 = GDK_F20;
    GDK_KEY_F21 = GDK_F21;
    GDK_KEY_F22 = GDK_F22;
    GDK_KEY_F23 = GDK_F23;
    GDK_KEY_F24 = GDK_F24;
    GDK_KEY_cyrillic_io = GDK_cyrillic_io;
    GDK_KEY_cyrillic_Capital_hardsign = GDK_cyrillic_Capital_hardsign;

  type
     PGtkOldEditable = PGtkEditable;

  function gtk_class_get_type(aclass : Pointer) : TGtkType;

  //routines to mimic GObject routines/behaviour-->
  procedure g_signal_emit_by_name(anObject:PGtkObject; name:Pgchar; args:array of const); cdecl; overload; external gtkdll name 'gtk_signal_emit_by_name';
  procedure g_signal_emit_by_name(anObject:PGtkObject; name:Pgchar); cdecl; overload; external gtkdll name 'gtk_signal_emit_by_name';

  Procedure g_signal_handlers_destroy(anObject : PGtkObject); cdecl; external gtkdll name 'gtk_signal_handlers_destroy';
  Procedure g_signal_stop_emission_by_name(anObject : PGtkObject; detailed_signal : Pgchar); cdecl; external gtkdll name 'gtk_signal_emit_stop_by_name';
  Function g_signal_connect(anObject : PGtkObject; name : Pgchar; func : TGtkSignalFunc; func_data : gpointer) : guint; cdecl; external gtkdll name 'gtk_signal_connect';
  Function g_signal_connect_after(anObject : PGtkObject; name : Pgchar; func : TGtkSignalFunc; func_data : gpointer) : guint; cdecl; external gtkdll name 'gtk_signal_connect_after';
  Function g_signal_lookup(name : Pgchar; anObject : TGTKType) : guint; cdecl; external gtkdll name 'gtk_signal_lookup';

  //routines to mimic similar GTK2 routines/behaviour-->
  function gtk_object_get_class(anobject : Pointer) : Pointer;
  Function gtk_window_get_modal(window:PGtkWindow):gboolean;
  Function gtk_bin_get_child(bin : PGTKBin) : PGTKWidget;
  Procedure gtk_menu_item_set_right_justified(menu_item : PGtkMenuItem; right_justified : gboolean);
  Function gtk_check_menu_item_get_active(menu_item : PGtkCheckMenuItem) : gboolean;
  Procedure gtk_menu_append(menu : PGTKWidget; Item : PGtkWidget);
  Procedure gtk_menu_insert(menu : PGtkWidget; Item : PGTKWidget; Index : gint);
  Procedure gtk_menu_bar_insert(menubar : PGtkWidget; Item : PGTKWidget; Index : gint);
  Function gtk_image_new : PGTKWidget;
  Function gtk_toolbar_new : PGTKWidget;
  Procedure gtk_color_selection_get_current_color(colorsel : PGTKColorSelection; Color : PGDKColor);
  Procedure gtk_color_selection_set_current_color(colorsel : PGTKColorSelection; Color : PGDKColor);

  //routines to mimic similar GDK2 routines/behaviour-->
  procedure gdk_image_unref(Image : PGdkImage);
  Function gdk_image_get_colormap(Image : PGDKImage) : PGdkColormap;
  Procedure gdk_colormap_query_color(colormap : PGDKColormap; Pixel : gulong; Result : PGDKColor);

  //Wrapper around misnamed "regions" routines -->
  Function gdk_region_intersect(source1:PGdkRegion; source2:PGdkRegion) : PGdkRegion;
  Function gdk_region_union(source1:PGdkRegion; source2:PGdkRegion) : PGdkRegion;
  Function gdk_region_subtract(source1:PGdkRegion; source2:PGdkRegion) : PGdkRegion;
  Function gdk_region_xor(source1:PGdkRegion; source2:PGdkRegion) : PGdkRegion;
  function gdk_region_copy(region: PGDKRegion): PGDKRegion;
  function gdk_region_rectangle(rect: PGdkRectangle): PGDKRegion;

  //routines to mimic similar GDK2 routines/behaviour-->
  Function gdk_pixmap_create_from_xpm_d (window : PGdkWindow; var mask : PGdkBitmap; transparent_color : PGdkColor; data : PPgchar) : PGdkPixmap;
  Function gdk_pixmap_colormap_create_from_xpm_d (window : PGdkWindow; colormap: PGdkColormap; var mask : PGdkBitmap; transparent_color : PGdkColor; data : PPgchar) : PGdkPixmap;
  Function gdk_pixmap_colormap_create_from_xpm (window : PGdkWindow; colormap: PGdkColormap; var mask : PGdkBitmap; transparent_color : PGdkColor; filename : Pgchar) : PGdkPixmap;

  {$IfNDef NoGdkPixbufLib}
  Procedure gdk_pixbuf_render_pixmap_and_mask(pixbuf : PGdkPixbuf; var pixmap_return : PGdkPixmap; var mask_return : PGdkBitmap; alpha_threshold : gint);
  {$EndIf}
  
  //Wrapper around window functions like gtk2 -->
  Function gdk_drawable_get_depth(Drawable : PGDKDrawable) : gint;
  Procedure gdk_drawable_get_size(Drawable : PGDKDrawable; Width, Height : PGInt);
  Function gdk_drawable_get_image(Drawable : PGDKDrawable; x, y, width, height : gint) : PGdkImage;
  Function gdk_drawable_get_colormap(Drawable : PGDKDrawable) : PGdkColormap;
{$EndIF}

{$Ifdef GTK2}
  function gtk_class_get_type(aclass : Pointer) : TGtkType;

  //we wrap our own versions to handle nil tests -->
  function gtk_object_get_class(anobject : Pointer) : Pointer;
  Function gtk_window_get_modal(window:PGtkWindow):gboolean;

  //we wrap our own versions to do gtk1 style result = new region -->
  Function gdk_region_union_with_rect(region:PGdkRegion; rect:PGdkRectangle) : PGdkRegion;
  Function gdk_region_intersect(source1:PGdkRegion; source2:PGdkRegion) : PGdkRegion;
  Function gdk_region_union(source1:PGdkRegion; source2:PGdkRegion) : PGdkRegion;
  Function gdk_region_subtract(source1:PGdkRegion; source2:PGdkRegion) : PGdkRegion;
  Function gdk_region_xor(source1:PGdkRegion; source2:PGdkRegion) : PGdkRegion;

  //mimic GDKFont Routines With Pango -->
  Procedure gdk_text_extents(FontDesc : PPangoFontDescription; Str : PChar; LineLength : Longint; lbearing, rbearing, width, ascent, descent : Pgint);
{$EndIf}

implementation

var
  GdkTrapIsSet : Boolean;
  GdkTrapCalls : Integer;

procedure Set_RC_Name(Sender : TObject; AWidget: PGtkWidget);
var RCName: string;
  AComponent: TComponent;
begin
  {$IFDEF NoStyle}
  exit;
  {$ENDIF}
  if (AWidget=nil) or (not (Sender is TComponent)) then exit;

  // check if a unique name can be created
  AComponent:=TComponent(Sender);
  while (AComponent<>nil) and (AComponent.Name<>'') do begin
    AComponent:=AComponent.Owner;
  end;
  if (AComponent=nil) or (AComponent=TComponent(Application)) then begin
    // create unique name
    AComponent:=TComponent(Sender);
    RCName:=AComponent.Name;
    while (AComponent<>nil) do begin
      AComponent:=TComponent(AComponent.Owner);
      if (AComponent<>nil) and (AComponent.Name<>'') then
        RCName:=AComponent.Name+'_'+RCName;
    end;
    gtk_widget_set_name(AWidget,PChar(RCName));
    gtk_widget_set_rc_style(AWidget);
  end;
  if (Sender is TCustomForm)
  and ((Application.MainForm=TCustomForm(Sender))
    or (Application.MainForm=nil))
  then
    UpdateSysColorMap(AWidget);
end;

{$I gtkproc.inc}
{$I gtkcallback.inc}

initialization
  {$IFDEF GTK1} //only needed to get X fonts
  X11Display := nil;
  {$EndIf}
  GdkTrapIsSet := False;
  GdkTrapCalls := 0;

Finalization
  GdkTrapCalls := 0;
  EndGDKErrorTrap;

  {$IFDEF GTK1} //only needed to get X fonts
  {$IfNdef Win32}
  If X11Display <> nil then
    XCloseDisplay(X11Display);
  {$EndIf}
  X11Display := nil;
  {$EndIf}

end.

