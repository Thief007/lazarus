{  $Id$  }
{
 /***************************************************************************
                             GTKWinapiWindow.pp
                             -------------------
                       gtkimplementation for basic window
                   Initial Revision  : Sun Jan 9 16:00:00 GMT+1 2000


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
{
@abstract(A GTK widget to support controls derived from a wincontrol)
@author(TGTKWinapiWindow - Marc Weustink <marc@@freepascal.org>)
@created(2000)
@lastmod(2004)
}
unit GTKWinapiWindow;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, LCLProc,
  {$IFDEF gtk2}
  glib2, gdk2pixbuf, gdk2, gtk2,
  {$ELSE}
  glib, gdk, gtk, gdkpixbuf,
  {$ENDIF}
  GtkDef;

{ $Define VerboseCaret}

type
  PGTKAPIWidget = ^TGTKAPIWidget;
  TGTKAPIWidget = record
    // ! the ScrolledWindow must be the first attribute of this record !
    ScrolledWindow: TGTKScrolledWindow;
{$if defined(win32) and defined(gtk2)}
    Reserved1: Word; // workaround gtk2 win32 fpc bug: SizeOf(TGTKScrolledWindow) is less than in real
{$ifend}
    Frame: PGtkFrame;
    Client: PGtkWidget;
  end;
  
  PGTKAPIWidgetClass = ^TGTKAPIWidgetClass;
  TGTKAPIWidgetClass = record
    ParentClass: TGTKScrolledWindowClass;
  end;

function GTKAPIWidget_GetType: guint;
function GTKAPIWidget_New: PGTKWidget;
procedure GTKAPIWidget_CreateCaret(APIWidget: PGTKAPIWidget;
                                 AWidth, AHeight: Integer; ABitmap: PGDKPixmap); 
procedure GTKAPIWidget_DestroyCaret(APIWidget: PGTKAPIWidget); 
procedure GTKAPIWidget_HideCaret(APIWidget: PGTKAPIWidget; var OldVisible: boolean);
procedure GTKAPIWidget_ShowCaret(APIWidget: PGTKAPIWidget); 
procedure GTKAPIWidget_SetCaretPos(APIWidget: PGTKAPIWidget; X, Y: Integer); 
procedure GTKAPIWidget_GetCaretPos(APIWidget: PGTKAPIWidget; var X, Y: Integer); 
procedure GTKAPIWidget_SetCaretRespondToFocus(APIWidget: PGTKAPIWidget;
  ShowHideOnFocus: boolean); 
procedure GTKAPIWidget_GetCaretRespondToFocus(APIWidget: PGTKAPIWidget;
  var ShowHideOnFocus: boolean);

procedure GTKAPIWidget_SetShadowType(APIWidget: PGTKAPIWidget; AShadowType: TGtkShadowType);

function GTK_APIWIDGETCLIENT_TYPE: Guint;

implementation

//---------------------------------------------------------------------------
// gtk_winapiwindow_internal
//---------------------------------------------------------------------------
type
  TCaretInfo = record
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer; 	    
    Visible: Boolean;  // Caret is on
    IsDrawn: Boolean;  // Caret is visible at the moment
    Blinking: Boolean; // Caret should blink
    Pixmap: PGDKPixMap;
    BackPixmap: PGDKPixMap;
    Timer: guint;
    ShowHideOnFocus: boolean; // true = hide on loose focus, show on get focus
  end;

  PGTKAPIWidgetClient = ^TGTKAPIWidgetClient;
  TGTKAPIWidgetClient = record
    // ! the Widget must be the first attribute of the record !
    Widget: TGtkFixed;
    Caret: TCaretInfo;
    {$IFNDEF gtk2}
    // the IC is only implemented for GKT1. GTK2 needs different code.
    ic: TGdkIC;
    ic_attr: PGdkICAttr;
    {$ENDIF}
  end;
  
  PGTKAPIWidgetClientClass = ^TGTKAPIWidgetClientClass;
  TGTKAPIWidgetClientClass = record
    ParentClass: TGTKFixedClass;
//    ParentClass: TGTKWidgetClass;
   
    set_scroll_adjustments: procedure(Widget: PGTKWidget;
                               HAdjustment, VAdjustment: PGTKAdjustment); cdecl;
  end;

{$IFDEF gtk2}                                                                                
////////////////////////////////////////////////////                                                                            
// TEMP solution until gtkmarshal.inc is implemeted
//      to get this compiled
////////////////////////////////////////////////////                                                                            
procedure gtk_marshal_VOID__POINTER_POINTER (closure: PGClosure; 
                                             return_value: PGValue;
                                             n_param_values: guint;
                                             param_values: PGValue;
                                             invocation_hint: gpointer;
                                             marshal_data: gpointer); cdecl; external gtklib;
////////////////////////////////////////////////////                                                                            
{$ELSE}
////////////////////////////////////////////////////                                                                            
// TEMP solution until attr is defined as PGdkICAttr 
////////////////////////////////////////////////////                                                                            
function  _gdk_ic_new(attr:PGdkICAttr; mask:TGdkICAttributesType):TGdkIC;cdecl;external gdkdll name 'gdk_ic_new';
function  _gdk_ic_attr_new:PGdkICAttr;cdecl;external gdkdll name 'gdk_ic_attr_new';
procedure _gdk_ic_attr_destroy(attr:PGdkICAttr);cdecl;external gdkdll name 'gdk_ic_attr_destroy';
function  _gdk_ic_set_attr(ic:TGdkIC; attr:PGdkICAttr; mask:TGdkICAttributesType):TGdkICAttributesType;cdecl;external gdkdll name 'gdk_ic_set_attr';
////////////////////////////////////////////////////                                                                            
{$ENDIF}

type
  {$IFDEF gtk2}
  GTKEventResult = gboolean;
  {$ELSE}
  GTKEventResult = gint;
  {$ENDIF}

var
  MParentClass: PGtkFixedClass;

function GTKAPIWidgetClient_Timer(Client: Pointer): GTKEventResult; cdecl; forward;
procedure GTKAPIWidgetClient_Realize(AWidget: PGTKWidget); cdecl; forward;
procedure GTKAPIWidgetClient_UnRealize(AWidget: PGTKWidget); cdecl; forward;
procedure GTKAPIWidgetClient_SizeAllocate (AWidget: PGTKWidget; AAllocation: PGtkAllocation); cdecl; forward;


function GTKAPIWidgetClient_KeyPress(Widget: PGTKWidget; 
  Event: PGDKEventKey): GTKEventResult; cdecl; forward;
function GTKAPIWidgetClient_ButtonPress(Widget: PGTKWidget;
  Event: PGDKEventButton): GTKEventResult; cdecl; forward;
function GTKAPIWidgetClient_FocusIn(AWidget: PGTKWidget;
  Event: PGdkEventFocus): GTKEventResult; cdecl; forward;
function GTKAPIWidgetClient_FocusOut(AWidget: PGTKWidget;
  Event: PGdkEventFocus): GTKEventResult; cdecl; forward;

procedure GTKAPIWidgetClient_ClassInit(theClass: Pointer);cdecl; forward;
{$ifdef gtk2}
procedure GTKAPIWidgetClient_Init(Client:PGTypeInstance; theClass: Pointer); cdecl; forward;
{$else}
procedure GTKAPIWidgetClient_Init(Client, theClass: Pointer); cdecl; forward;
{$endif}
function GTKAPIWidgetClient_GetType: Guint; forward;
function GTKAPIWidgetClient_New: PGTKWidget; forward;

procedure GTKAPIWidgetClient_HideCaret(Client: PGTKAPIWidgetClient;
                                       var OldVisible: boolean); forward;
procedure GTKAPIWidgetClient_DrawCaret(Client: PGTKAPIWidgetClient; CalledByTimer: boolean); forward;
procedure GTKAPIWidgetClient_ShowCaret(Client: PGTKAPIWidgetClient); forward;
procedure GTKAPIWidgetClient_CreateCaret(Client: PGTKAPIWidgetClient;
  AWidth, AHeight: Integer; ABitmap: PGDKPixmap); forward;
procedure GTKAPIWidgetClient_DestroyCaret(Client: PGTKAPIWidgetClient); forward;
procedure GTKAPIWidgetClient_SetCaretPos(Client: PGTKAPIWidgetClient;
  AX, AY: Integer); forward;
procedure GTKAPIWidgetClient_GetCaretPos(Client: PGTKAPIWidgetClient;
  var X, Y: Integer); forward;
procedure GTKAPIWidgetClient_SetCaretRespondToFocus(Client: PGTKAPIWidgetClient;
  ShowHideOnFocus: boolean); forward;
procedure GTKAPIWidgetClient_GetCaretRespondToFocus(Client: PGTKAPIWidgetClient;
  var ShowHideOnFocus: boolean); forward;

//-----------------------------

procedure GTKAPIWidget_SetShadowType(APIWidget: PGTKAPIWidget;
  AShadowType: TGtkShadowType);
begin
  if (APIWidget^.Frame <> nil) then
    gtk_frame_set_shadow_type(APIWidget^.Frame, AShadowType)
{$ifdef gtk2}
  else
    gtk_scrolled_window_set_shadow_type(PGtkScrolledWindow(APIWidget), AShadowType);
{$endif}
end;

function GTK_APIWIDGETCLIENT_TYPE: Guint;
begin
  GTK_APIWIDGETCLIENT_TYPE := GTKAPIWidgetClient_GetType;
end;


function GTKAPIWidgetClient_GetType: Guint;
const 
  TYPE_NAME = 'LCLWinapiClient';
  TheType: Guint = 0;
  Info: TGTKTypeInfo = (
    type_name: TYPE_NAME;
    object_size: SizeOf(TGTKAPIWidgetClient){+100};
    class_size:  SizeOf(TGTKAPIWidgetClientClass){+100};
    class_init_func:  @GTKAPIWidgetClient_ClassInit;
    object_init_func: @GTKAPIWidgetClient_Init;
    reserved_1: nil;
    reserved_2: nil;
    base_class_init_func: nil;
  );
begin
  if (TheType = 0)
  then begin
    TheType := gtk_type_from_name(TYPE_NAME);
    {$IFDEF gtk2}
    if TheType = 0 then TheType := gtk_type_unique(GTK_TYPE_FIXED, @Info);
    {$ELSE}
    if TheType = 0 then TheType := gtk_type_unique(gtk_fixed_type, @Info);
    {$ENDIF}
  end;
  Result := TheType;
end;

procedure GTKAPIWidgetClient_ClassInit(theClass: Pointer);cdecl;
// theClass: PGTKAPIWidgetClientClass
var
  ObjectClass: PGTKObjectClass;
  WidgetClass: PGTKWidgetClass;
  ClientClass: PGTKAPIWidgetClientClass;
  SignalID: Guint;
begin
  ObjectClass := PGTKObjectClass(theClass);
  WidgetClass := PGTKWidgetClass(theClass);
  ClientClass := PGTKAPIWidgetClientClass(theClass);
  
  MParentClass := gtk_type_class(gtk_fixed_get_type);
  SignalID := gtk_signal_new(
    'set_scroll_adjustments',
    GTK_RUN_FIRST,
    {$IFDEF gtk2}
    gtk_class_type(ObjectClass),
    {$ELSE}
    ObjectClass^.thetype,
    {$ENDIF}
    (@ClientClass^.set_scroll_adjustments - Pointer(theClass)),
    {$IFDEF gtk2}
    @gtk_marshal_VOID__POINTER_POINTER,
    {$ELSE}
    @gtk_marshal_NONE__POINTER_POINTER,
    {$ENDIF}
    GTK_TYPE_NONE,
    2, 
    [gtk_adjustment_get_type, gtk_adjustment_get_type]
  );
  
  ClientClass^.set_scroll_adjustments := nil;

  with WidgetClass^ do
  begin
    set_scroll_adjustments_signal := SignalID;
    realize := @GTKAPIWidgetClient_Realize;
    unrealize := @GTKAPIWidgetClient_UnRealize;
    size_allocate := @GTKAPIWidgetClient_SizeAllocate;
    button_press_event := @GTKAPIWidgetClient_ButtonPress;
    key_press_event := @GTKAPIWidgetClient_KeyPress;
    focus_in_event := @GTKAPIWidgetClient_FocusIn;
    focus_out_event := @GTKAPIWidgetClient_FocusOut;
  end;
end;

{$ifdef gtk2}
procedure GTKAPIWidgetClient_Init(Client:PGTypeInstance; theClass: Pointer); cdecl;
{$else}
procedure GTKAPIWidgetClient_Init(Client, theClass: Pointer); cdecl;
{$endif}
// Client: PGTKAPIWidgetClient
// theClass: PGTKAPIWidgetClientClass
begin
  if theClass=nil then ;
  gtk_widget_set_flags(PGTKWidget(Client), GTK_CAN_FOCUS);
  gtk_widget_set_flags(PGTKWidget(Client), GTK_CAN_DEFAULT);
  {$IfDef GTK2}
  gtk_widget_unset_flags(PGTKWidget(Client), GTK_NO_WINDOW);
  {$EndIf}
  with PGTKAPIWidgetClient(Client)^.Caret do
  begin
    Visible := False;
    IsDrawn := False;
    Blinking := True;
    X := 0;
    Y := 0;
    Width := 1;
    Height := 10;
    Pixmap := nil;
    BackPixmap := nil;
    Timer := 0;
    ShowHideOnFocus := true;
  end;

  {$IFNDEF NoStyle}
  gtk_widget_set_app_paintable(PGTKWidget(Client),true);
  {$ENDIF}
end;

function GTKAPIWidgetClient_New: PGTKWidget;
begin
  Result := PGTKWidget(gtk_type_new(GTKAPIWidgetClient_GetType()));
end;

function GTKAPIWidgetClient_Timer(Client: Pointer): GTKEventResult; cdecl;
// returning 0 would stop the timer, 1 will restart it
begin
  if PGTKAPIWidgetClient(Client)^.Caret.Timer<=0 then begin
    Result := gtk_False;
    exit;
  end;
  GTKAPIWidgetClient_DrawCaret(Client,true);
  if PGTKAPIWidgetClient(Client)^.Caret.Timer<>0 then
    Result := gtk_True
  else
    Result := gtk_False;
end;

procedure GTKAPIWidgetClient_Realize(AWidget: PGTKWidget); cdecl;
{$IFNDEF gtk2}
  procedure RealizeIC; // MG: it isn't called, why that?
  var
    width, height: GInt;
    mask: TGdkEventMask;
    colormap: PGdkColormap;  
    attrmask: TGdkICAttributesType;
    style, supported_style: TGdkIMStyle;
    ic: PGdkIC;
    ic_attr: PGdkICAttr;
  begin
    // Note: code is based on gtkentry implementation
    // don't know if all is needed
    // MWE
    
    if gdk_im_ready = 0 then Exit;
  
    ic_attr := _gdk_ic_attr_new;
    PGTKAPIWidgetClient(AWidget)^.ic_attr := ic_attr;
    if ic_attr = nil then Exit;
    
    attrmask := GDK_IC_ALL_REQ;
    supported_style := GDK_IM_PREEDIT_NONE or
                       GDK_IM_PREEDIT_NOTHING or
                       GDK_IM_PREEDIT_POSITION or
                       GDK_IM_STATUS_NONE or
                       GDK_IM_STATUS_NOTHING;
  
    if  (AWidget^.thestyle <> nil) 
    and (PGtkStyle(AWidget^.thestyle)^.font^.theType <> GDK_FONT_FONTSET)
    then supported_style := supported_style and not GDK_IM_PREEDIT_POSITION;
                     
    style := gdk_im_decide_style(supported_style);
    ic_attr^.style := style;
    ic_attr^.client_window := AWidget^.window;
         
    colormap := gtk_widget_get_colormap(AWidget);
    if colormap <> gtk_widget_get_default_colormap
    then begin
      attrmask := attrmask or GDK_IC_PREEDIT_COLORMAP;
      ic_attr^.preedit_colormap := colormap;
    end;
    attrmask := attrmask or GDK_IC_PREEDIT_FOREGROUND or GDK_IC_PREEDIT_BACKGROUND;
    ic_attr^.preedit_foreground := PGtkStyle(AWidget^.thestyle)^.fg[GTK_STATE_NORMAL];
    ic_attr^.preedit_background := PGtkStyle(AWidget^.thestyle)^.base[GTK_STATE_NORMAL];

    if (style and GDK_IM_PREEDIT_MASK) = GDK_IM_PREEDIT_POSITION
    then begin
      if  (AWidget^.thestyle <> nil) 
      and (PGtkStyle(AWidget^.thestyle)^.font^.thetype <> GDK_FONT_FONTSET)
      then begin
        DebugLn('[WAWc] over-the-spot style requires fontset');
      end
      else begin
        gdk_window_get_size(AWidget^.window, @width, @height);

        attrmask := attrmask or GDK_IC_PREEDIT_POSITION_REQ;
        ic_attr^.spot_location.x := 0;
        ic_attr^.spot_location.y := guint16(height);
        ic_attr^.preedit_area.x := 0;
        ic_attr^.preedit_area.y := 0;
        ic_attr^.preedit_area.width := guint16(width);
        ic_attr^.preedit_area.height := guint16(height);
        ic_attr^.preedit_fontset := PGtkStyle(AWidget^.thestyle)^.font;
      end;
    end;                         

    ic := _gdk_ic_new(ic_attr, attrmask);
    PGTKAPIWidgetClient(AWidget)^.ic := ic;
    if ic = nil
    then begin
      DebugLn('[WAWc] Can''t create input context.')
    end
    else begin
      mask := gdk_window_get_events(AWidget^.Window);
      mask := mask or gdk_ic_get_events(ic);
      gdk_window_set_events(AWidget^.Window, mask);
  
      if GTK_WIDGET_HAS_FOCUS(Awidget)
      then gdk_im_begin(ic, AWidget^.Window);
    end;
  end;
{$ENDIF}

// All //@ marked lines are already set by the inherited realize
// we only have to (re)set the event mask

//@var
//@  Attributes: TGdkWindowAttr;
//@  AttributesMask: gint;
begin
  PGTKWidgetClass(MParentClass)^.realize(AWidget);
  
//@  gtk_widget_set_flags(AWidget, GTK_REALIZED);
  
  {$Ifdef GTK2}
  gtk_widget_set_double_buffered(AWidget, False);
  gtk_widget_set_redraw_on_allocate(AWidget, False);
  {$EndIf}

//@  with Attributes do
//@  begin
//@    Window_type := gdk_window_child;
//@    X := AWidget^.allocation.x;
//@    Y := AWidget^.allocation.y;
//@    Width := AWidget^.allocation.width;
//@    Height := AWidget^.allocation.height;
//@    WClass := GDK_INPUT_OUTPUT;
//@    Visual := gtk_widget_get_visual(AWidget);
//@    Colormap := gtk_widget_get_colormap(AWidget);
//@    Event_mask := gtk_widget_get_events(AWidget)
//@      or GDK_EXPOSURE_MASK or GDK_BUTTON_PRESS_MASK or GDK_BUTTON_RELEASE_MASK
//@      or GDK_BUTTON_MOTION_MASK or GDK_ENTER_NOTIFY_MASK or GDK_LEAVE_NOTIFY_MASK
//@      or GDK_KEY_PRESS_MASK or GDK_KEY_RELEASE_MASK;
//@  end;
//@  AttributesMask := GDK_WA_X or GDK_WA_Y or GDK_WA_VISUAL or GDK_WA_COLORMAP;
//@
//@  AWidget^.Window := gdk_window_new(gtk_widget_get_parent_window(AWidget),
//@                                    @Attributes, AttributesMask);
//@
//@  gdk_window_set_user_data(AWidget^.Window, AWidget);

  gdk_window_set_events(AWidget^.Window, gdk_window_get_events(AWidget^.Window)
    or GDK_EXPOSURE_MASK or GDK_BUTTON_PRESS_MASK or GDK_BUTTON_RELEASE_MASK
    or GDK_BUTTON_MOTION_MASK or GDK_ENTER_NOTIFY_MASK or GDK_LEAVE_NOTIFY_MASK
    or GDK_KEY_PRESS_MASK or GDK_KEY_RELEASE_MASK);

//@  AWidget^.Style := gtk_style_attach(AWidget^.Style, AWidget^.Window);
//@  gtk_style_set_background(AWidget^.Style, AWidget^.Window, GTK_STATE_NORMAL);
  gdk_window_set_back_pixmap(AWidget^.Window, nil, GdkFalse);

end;

procedure GTKAPIWidgetClient_UnRealize(AWidget: PGTKWidget); cdecl;
begin
  with PGTKAPIWidgetClient(AWidget)^.Caret do 
  begin
    if Timer <> 0 
    then begin
      gtk_timeout_remove(Timer);
      Timer := 0;
    end;
  end;
    
  {$IFNDEF GTK2}
  with PGTKAPIWidgetClient(AWidget)^ do
  begin
    if ic <> nil
    then begin
      gdk_ic_destroy(ic);
      ic := nil;
    end;
    if ic_attr <> nil
    then begin
      _gdk_ic_attr_destroy(ic_attr);
      ic_attr := nil;
    end;
  end;
  {$ENDIF}
                          
  PGTKWidgetClass(MParentClass)^.unrealize(AWidget);
end;                        

procedure GTKAPIWidgetClient_SizeAllocate(AWidget: PGTKWidget; 
  AAllocation: PGtkAllocation); cdecl; 
{$IFNDEF GTK2}
var
  width, height: GInt;
  ic: PGdkIC;
  ic_attr: PGdkICAttr;
{$ENDIF}    
begin         
  PGTKWidgetClass(MParentClass)^.size_allocate(AWidget, AAllocation);
  
  {$IFNDEF GTK2}
  ic := PGTKAPIWidgetClient(AWidget)^.ic;
  ic_attr := PGTKAPIWidgetClient(AWidget)^.ic_attr;

  if  (ic <> nil) 
  and (gdk_ic_get_style(ic) and GDK_IM_PREEDIT_POSITION <> 0)
  then begin
    gdk_window_get_size(AWidget^.Window, @width, @height);
    ic_attr^.preedit_area.width := guint16(width);
    ic_attr^.preedit_area.height := guint16(height);
    _gdk_ic_set_attr(ic, ic_attr, GDK_IC_PREEDIT_AREA);
  end;
  {$ENDIF}
end;  

  
function GTKAPIWidgetClient_KeyPress(Widget: PGTKWidget;
  Event: PGDKEventKey): GTKEventResult; cdecl;
begin
  if (Widget=nil) or (Event=nil) then ;


  // DO NOT supress further processing. The next one who changes that please do the debugging too.
  // just dont.
  
{$ifdef gtk2}
  Result := gtk_False;
{$else}
  Result := gtk_True;
{$endif}
end;

function GTKAPIWidgetClient_ButtonPress(Widget: PGTKWidget;
  Event: PGDKEventButton): GTKEventResult; cdecl;
begin
  {$IFDEF VerboseFocus}
  DebugLn('GTKAPIWidgetClient_ButtonPress ',DbgS(Widget));
  {$ENDIF}
  if Event=nil then ;
  Result := gtk_False;
end;

function GTKAPIWidgetClient_FocusIn(AWidget: PGTKWidget;
  Event: PGdkEventFocus): GTKEventResult; cdecl;
begin
  {$IFDEF VerboseFocus}
  DebugLn('GTKAPIWidgetClient_FocusIn ',DbgS(AWidget),' ',dbgs(event^.thein));
  {$ENDIF}
  
  gtk_widget_set_flags(AWidget, GTK_HAS_FOCUS);
  GTKAPIWidgetClient_DrawCaret(PGTKAPIWidgetClient(AWidget), False);

  {$IFNDEF GTK2}
  if PGTKAPIWidgetClient(AWidget)^.ic <> nil
  then gdk_im_begin(PGTKAPIWidgetClient(AWidget)^.ic, AWidget^.Window);
  {$ENDIF}
  
  Result := gtk_False;
end;

function GTKAPIWidgetClient_FocusOut(AWidget: PGTKWidget;
  Event: PGdkEventFocus): GTKEventResult; cdecl;
begin
  {$IFDEF VerboseFocus}
  DebugLn('GTKAPIWidgetClient_FocusOut ',DbgS(AWidget),' ',dbgs(event^.thein));
  {$ENDIF}
  
  gtk_widget_unset_flags(AWidget, GTK_HAS_FOCUS);
  GTKAPIWidgetClient_DrawCaret(PGTKAPIWidgetClient(AWidget), False);

  {$IFNDEF GTK2}
  gdk_im_end;
  {$ENDIF}

  Result := gtk_False;
end;

procedure GTKAPIWidgetClient_HideCaret(Client: PGTKAPIWidgetClient;
  var OldVisible: boolean);
begin
  //DebugLn('[GTKAPIWidgetClient_HideCaret] A Client=',DbgS(Client));
  if Client = nil
  then begin
    DebugLn('WARNING: [GTKAPIWidgetClient_HideCaret] Got nil client');
    Exit;
  end;
  {$IFDEF VerboseCaret}
  DebugLn('GTKAPIWidgetClient_HideCaret ',DbgS(Client),' ShowHideOnFocus=',Client^.Caret.ShowHideOnFocus);
  {$ENDIF}
  OldVisible:=Client^.Caret.Visible;
  Client^.Caret.Visible := False;
  GTKAPIWidgetClient_DrawCaret(Client,false);

  if (Client^.Caret.IsDrawn) then begin
    with Client^.Caret do begin
      DebugLn('GTKAPIWidgetClient_ShowCaret IsDrawn=',dbgs(IsDrawn),' Visible=',dbgs(Visible),
        ' Blinking='+dbgs(Blinking),' HasFocus=',dbgs(gtk_widget_has_focus(PGtkWidget(Client))),
        ' ShowHideOnFocus='+dbgs(ShowHideOnFocus),
        ' Window='+dbgs(PGtkWidget(Client)^.Window<>nil),
        ' Style='+dbgs(gtk_widget_get_style(PGtkWidget(Client))<>nil));
    end;
  end;
end;

procedure GTKAPIWidgetClient_DrawCaret(Client: PGTKAPIWidgetClient;
  CalledByTimer: boolean);
const
  GC_STATE: array[Boolean] of TGtkStateType =
                                 (GTK_STATE_INSENSITIVE, GTK_STATE_NORMAL);
var
  Widget: PGTKWidget;
  WidgetStyle: PGTKStyle;
  HasFocus: boolean;
  ForeGroundGC: PGdkGC;
begin
  if Client = nil then begin
    DebugLn('WARNING: [GTKAPIWidgetClient_DrawCaret] Got nil client');
    Exit;
  end;
  Widget := PGTKWidget(Client);
  WidgetStyle := gtk_widget_get_style(Widget);

  with Client^.Caret do 
  begin
    HasFocus:=gtk_widget_has_focus(Widget);
  
    if (Timer <> 0) and
      ((not Blinking) or (not Visible)
      or (ShowHideOnFocus and (not HasFocus))) 
    then begin
      gtk_timeout_remove(Timer);
      Timer := 0;
    end;
    if IsDrawn and ((not Visible) or (Blinking and CalledByTimer))
    then begin
      {$IFDEF VerboseCaret}
      DebugLn('GTKAPIWidgetClient_DrawCaret ',DbgS(Client),
        ' Hiding Caret IsDrawn=',IsDrawn,' Visible=',Visible,' Blinking=',Blinking);
      {$ENDIF}
      // hide caret
      if (BackPixmap <> nil)
      and (Widget<>nil)
      and (WidgetStyle<>nil)
      then gdk_draw_pixmap(
        Widget^.Window,
        WidgetStyle^.bg_gc[GTK_STATE_NORMAL],
        BackPixmap, 0, 0,
        X, Y-1, // Y-1 for Delphi compatibility
        Width, Height
      );
      IsDrawn := False;
    end
    else
    if Visible
    and (HasFocus or (not ShowHideOnFocus))
    and (not IsDrawn) 
    and (Widget^.Window<>nil) 
    and (WidgetStyle<>nil)
    then begin
      if Pixmap <> nil then
        Assert(False, 'Trace:TODO: [GTKAPIWidgetClient_DrawCaret] Implement bitmap');
      
      //Create backbitmap if needed
      if (BackPixmap = nil) 
      and (Widget^.Window<>nil) 
      and (Width>0)
      and (Height>0)
      then
        BackPixmap := gdk_pixmap_new(Widget^.Window, Width, Height, -1);

      // undraw old caret
      if (BackPixmap <> nil) 
      and (Widget<>nil) 
      and (WidgetStyle<>nil)
      and (Width>0) and (Height>0)
      then gdk_draw_pixmap(
        BackPixmap, 
        WidgetStyle^.bg_gc[GTK_STATE_NORMAL], 
        Widget^.Window,
          X, Y-1, // Y-1 for Delphi compatibility
          0, 0,
          Width, Height
      );

      // draw caret
      {$IFDEF VerboseCaret}
      DebugLn('GTKAPIWidgetClient_DrawCaret B Client=',DbgS(Client)
      ,' ',cardinal(WidgetStyle)
      ,' ',cardinal(Widget^.Window)
      ,' ',Width
      ,' ',Height
      );
      {$ENDIF}
      if (WidgetStyle<>nil) 
      and (Widget^.Window<>nil)
      and (Width>0) 
      and (Height>0) 
      then begin
        // set draw function to xor
        ForeGroundGC:=WidgetStyle^.fg_gc[GC_STATE[PtrUInt(Pixmap) <> 1]];
        //gdk_gc_get_values(ForeGroundGC,@ForeGroundGCValues);
        //OldGdkFunction:=ForeGroundGCValues.thefunction;
        {$IFDEF VerboseCaret}
        DebugLn('GTKAPIWidgetClient_DrawCaret ',DbgS(Client),' Real Drawing Caret ');
        {$ENDIF}
        gdk_gc_set_function(ForeGroundGC,GDK_invert);
        try
          // draw the caret
          //DebugLn('DRAWING');
          gdk_draw_rectangle(
            Widget^.Window,
            ForeGroundGC,
            1,
            X, Y-1,  // Y-1 for Delphi compatibility
            Width, Height
          );
        finally
          // restore draw function
          gdk_gc_set_function(ForeGroundGC,GDK_COPY);
        end;
      end else
        DebugLn('***: Draw Caret failed: Client=',DbgS(Client),
          ' X='+dbgs(X)+' Y='+dbgs(Y)+' W='+dbgs(Width)+' H='+dbgs(Height),
          ' ',dbgs(Pixmap<>nil),',',dbgs(Widget^.Window),',',dbgs(WidgetStyle));
      IsDrawn := True;
    end;
    //DebugLn('GTKAPIWidgetClient_DrawCaret A Client=',DbgS(Client),' Timer=',Timer,' Blink=',Blinking,' Visible=',Visible,' ShowHideOnFocus=',ShowHideOnFocus,' Focus=',gtk_widget_has_focus(Widget),' IsDrawn=',IsDrawn,' W=',Width,' H=',Height);
    if Visible and Blinking and (Timer = 0) 
    and ((not ShowHideOnFocus) or HasFocus)
    then Timer := gtk_timeout_add(500, @GTKAPIWidgetClient_Timer, Client);
  end;
end;

procedure GTKAPIWidgetClient_ShowCaret(Client: PGTKAPIWidgetClient); 
begin
  //DebugLn('[GTKAPIWidgetClient_ShowCaret] A Client=',DbgS(Client));
  if Client = nil 
  then begin
    DebugLn('WARNING: [GTKAPIWidgetClient_ShowCaret] Got nil client');
    Exit;
  end;
  
  {$IFDEF VerboseCaret}
  DebugLn('GTKAPIWidgetClient_ShowCaret ',DbgS(Client));
  {$ENDIF}

  // force restarting time
  with Client^.Caret do
    if Timer<>0 then begin
      gtk_timeout_remove(Timer);
      Timer := 0;
    end;
  
  Client^.Caret.Visible := True;
  GTKAPIWidgetClient_DrawCaret(Client,false);
  
  if (not Client^.Caret.IsDrawn)
  and (gtk_widget_has_focus(PGtkWidget(Client))) then begin
    with Client^.Caret do begin
      DebugLn('GTKAPIWidgetClient_ShowCaret IsDrawn=',dbgs(IsDrawn),' Visible=',dbgs(Visible),
        ' Blinking='+dbgs(Blinking),' HasFocus=',dbgs(gtk_widget_has_focus(PGtkWidget(Client))),
        ' ShowHideOnFocus='+dbgs(ShowHideOnFocus),
        ' Window='+dbgs(PGtkWidget(Client)^.Window<>nil),
        ' Style='+dbgs(gtk_widget_get_style(PGtkWidget(Client))<>nil));
    end;
  end;
end;

procedure GTKAPIWidgetClient_CreateCaret(Client: PGTKAPIWidgetClient;
  AWidth, AHeight: Integer; ABitmap: PGDKPixmap); 
var
  IsVisible: Boolean;
  WasVisible: boolean;
begin
  {$IFDEF VerboseCaret}
  DebugLn('********** [GTKAPIWidgetClient_CreateCaret] A Client=',DbgS(Client),' Width=',AWidth,' Height=',AHeight,' Bitmap=',ABitmap<>nil);
  {$ENDIF}
  if Client = nil 
  then begin
    DebugLn('WARNING: [GTKAPIWidgetClient_CreateCaret] Got nil client');
    Exit;
  end;

  with Client^.Caret do
  begin
    IsVisible := Visible;
    if IsVisible then GTKAPIWidgetClient_HideCaret(Client,WasVisible);
    
    if (Width <> AWidth) or (Height <> AHeight) 
    then begin
      if BackPixmap <> nil then gdk_pixmap_unref(BackPixmap);
      BackPixmap := nil;
      Width := AWidth;
      Height := AHeight;
    end;
    
    Pixmap := ABitmap;

    if IsVisible then GTKAPIWidgetClient_ShowCaret(Client);
  end;
end;

procedure GTKAPIWidgetClient_DestroyCaret(Client: PGTKAPIWidgetClient); 
var
  WasVisible: boolean;
begin
  {$IFDEF VerboseCaret}
  DebugLn('********** [GTKAPIWidgetClient_DestroyCaret] A Client=',DbgS(Client));
  {$ENDIF}
  if Client = nil 
  then begin
    DebugLn('WARNING: [GTKAPIWidgetClient_DestroyCaret] Got nil client');
    Exit;
  end;

  with Client^.Caret do begin
    if Visible then GTKAPIWidgetClient_HideCaret(Client,WasVisible);
    
    if BackPixmap <> nil then begin
      gdk_pixmap_unref(BackPixmap);
      BackPixmap := nil;
    end;
    Pixmap := nil;
  end;
  {$IFDEF VerboseCaret}
  DebugLn('********** B[GTKAPIWidgetClient_DestroyCaret] A Client=',DbgS(Client));
  {$ENDIF}
end;

procedure GTKAPIWidgetClient_SetCaretPos(Client: PGTKAPIWidgetClient;
  AX, AY: Integer);
var
  IsVisible, WasVisible: Boolean;
begin
  {$IFDEF VerboseCaret}
  DebugLn('[GTKAPIWIDGETCLIENT] SetCaretPos '+inttostr(ax)+','+Inttostr(ay));
  {$ENDIF}

  if Client = nil 
  then begin
    DebugLn('WARNING: [GTKAPIWidgetClient_SetCaretPos] Got nil client');
    Exit;
  end;
  
  with Client^.Caret do
  begin
    IsVisible := Visible;
    if IsVisible then GTKAPIWidgetClient_HideCaret(Client,WasVisible);
    X := AX;
    Y := AY;
    if IsVisible then GTKAPIWidgetClient_ShowCaret(Client);
  end;
end;

procedure GTKAPIWidgetClient_GetCaretPos(Client: PGTKAPIWidgetClient;
  var X, Y: Integer); 
begin
  if Client = nil 
  then begin
    DebugLn('WARNING: [GTKAPIWidgetClient_GetCaretPos] Got nil client');
    Exit;
  end;
  
  X := Client^.Caret.X;
  Y := Client^.Caret.Y;
end;

procedure GTKAPIWidgetClient_SetCaretRespondToFocus(Client: PGTKAPIWidgetClient;
  ShowHideOnFocus: boolean);
begin
  {$IFDEF VerboseCaret}
  DebugLn('[GTKAPIWidgetClient_SetCaretRespondToFocus] A ',ShowHideOnFocus);
  {$ENDIF}
  if Client = nil
  then begin
    DebugLn(
      'WARNING: [GTKAPIWidgetClient_SetCaretRespondToFocus] Got nil client');
    Exit;
  end;
  
  Client^.Caret.ShowHideOnFocus:=ShowHideOnFocus;
end;

procedure GTKAPIWidgetClient_GetCaretRespondToFocus(Client: PGTKAPIWidgetClient;
  var ShowHideOnFocus: boolean);
begin
  if Client = nil
  then begin
    DebugLn(
      'WARNING: [GTKAPIWidgetClient_GetCaretRespondToFocus] Got nil client');
    Exit;
  end;

  ShowHideOnFocus:=Client^.Caret.ShowHideOnFocus;
end;

//---------------------------------------------------------------------------
// GTKAPIWidget
//---------------------------------------------------------------------------

function GTKAPIWidget_FocusIn(Widget: PGTKWidget;
  Event: PGdkEventFocus): GTKEventResult; cdecl;
var
  TopLevel: PGTKWidget;
begin
  Assert(False, 'Trace:[GTKAPIWidget_FocusIn]');

  if Event=nil then ;
  TopLevel := gtk_widget_get_toplevel(Widget);
  if gtk_type_is_a(gtk_object_type(PGTKObject(TopLevel)), gtk_window_get_type) 
  then gtk_window_set_focus(PGTKWindow(TopLevel), PGTKAPIWidget(Widget)^.Client);
  
  Result := gtk_True;
end;

function GTKAPIWidget_FocusOut(Widget: PGTKWidget;
  Event: PGdkEventFocus): GTKEventResult; cdecl;
begin
  if (Event=nil) or (Widget=nil) then ;
  Assert(False, 'Trace:[GTKAPIWidget_FocusOut]');
  Result := gtk_True;
end;


procedure GTKAPIWidget_ClassInit(wawClass: Pointer); cdecl;
//wawClass: PGTKAPIWidgetClass
var 
  WidgetClass: PGTKWidgetClass;
begin
  WidgetClass := PGTKWidgetClass(wawClass);
  
  WidgetClass^.focus_in_event := @GTKAPIWidget_FocusIn;
  WidgetClass^.focus_out_event := @GTKAPIWidget_FocusOut;
end;

{$ifdef gtk2}
procedure GTKAPIWidget_Init(waw:PGTypeInstance; theClass: Pointer); cdecl;
{$else}
procedure GTKAPIWidget_Init(waw, theClass: Pointer); cdecl;
{$endif}
// waw: PGTKAPIWidget; 
// theClass: PGTKAPIWidgetClass
var
  Widget: PGTKWidget;
begin
  if theClass=nil then ;
  Widget := PGTKWidget(waw);
  gtk_widget_set_flags(Widget, GTK_CAN_FOCUS);
end;

function GTKAPIWidget_GetType: Guint;
const 
  WAW_NAME = 'LCLWinapiWidget';
  wawType: Guint = 0;
  wawInfo: TGTKTypeInfo = (
    type_name: WAW_NAME;
    object_size: SizeOf(TGTKAPIWidget)+100; // a TGTKScrolledWindow
    class_size: SizeOf(TGTKAPIWidgetClass)+100;
    class_init_func: @GTKAPIWidget_ClassInit;
    object_init_func : @GTKAPIWidget_Init;
    reserved_1: nil;
    reserved_2: nil;
    base_class_init_func: nil;
  );
begin
  if (wawType = 0)
  then begin
    wawType := gtk_type_from_name(WAW_NAME);
    if wawType = 0
    then wawType := gtk_type_unique(gtk_scrolled_window_get_type, @wawInfo);
  end;
  Result := wawType;
end;

{$IFDEF GTK1}
function Laz_GTK_OBJECT_CONSTRUCTED(AnObject: PGtkObject): gboolean; cdecl;external gtkdll name 'gtk_object_constructed';
{$ENDIF GTK1}

function GTKAPIWidget_new: PGTKWidget;
var
  APIWidget: PGTKAPIWidget;
{$IFDEF gtk1}
var
  NewArgs: array[0..1] of TGTKArg;
{$ENDIF}
begin
{$IFDEF gtk1}
  FillChar(NewArgs[0],SizeOf(TGTKArg)*(High(NewArgs)-Low(NewArgs)+1),0);
  NewArgs[0].theType:=GTK_ADJUSTMENT_TYPE;
  NewArgs[0].name:='hadjustment';
  NewArgs[1].theType:=GTK_ADJUSTMENT_TYPE;
  NewArgs[1].name:='vadjustment';
  
  // something is rotten with gtk_widget_newv on some platforms
  //Result := gtk_widget_newv(GTKAPIWidget_GetType, 2, @ARGS[0]);
  
  // do it step by step
  Result:=gtk_type_new(GTKAPIWidget_GetType);
  gtk_object_arg_set (PGtkObject(Result), @NewArgs[0], NULL);
  gtk_object_arg_set (PGtkObject(Result), @NewArgs[1], NULL);
  if (not Laz_GTK_OBJECT_CONSTRUCTED (PGtkObject(Result))) then
    gtk_object_default_construct (PGtkObject(Result));
{$ELSE}
  // MWE: IMO the arguments can't work since we supply the adjustments as nil
  //      for gtk2 newv doesn't exist so the decision is easy
  //      TODO: check if we still need to pass the args in gtk1
  Result := gtk_widget_new(GTKAPIWidget_GetType, nil, []);
{$ENDIF}

  APIWidget := PGTKAPIWidget(Result);
  gtk_container_set_border_width(PGTKContainer(APIWidget),0);

  // create client widget
  APIWidget^.Client := GTKAPIWidgetClient_New;
  gtk_object_set_data(PGTKObject(Result), 'Fixed', APIWidget^.Client);
  gtk_object_set_data(PGTKObject(APIWidget^.Client), 'Main', Result);
  gtk_widget_show(APIWidget^.Client);
  gtk_container_add(PGTKContainer(APIWidget), APIWidget^.Client);
end;

procedure GTKAPIWidget_CreateCaret(APIWidget: PGTKAPIWidget;
  AWidth, AHeight: Integer; ABitmap: PGDKPixmap); 
begin
  if APIWidget = nil 
  then begin
    DebugLn('WARNING: [GTKAPIWidget_CreateCaret] Got nil client');
    Exit;
  end;
  GTKAPIWidgetClient_CreateCaret(PGTKAPIWidgetClient(APIWidget^.Client),
    AWidth, AHeight, ABitmap);
end;

procedure GTKAPIWidget_DestroyCaret(APIWidget: PGTKAPIWidget); 
begin
  if APIWidget = nil 
  then begin
    DebugLn('WARNING: [GTKAPIWidget_DestroyCaret] Got nil client');
    Exit;
  end;
  GTKAPIWidgetClient_DestroyCaret(PGTKAPIWidgetClient(APIWidget^.Client));
end;

procedure GTKAPIWidget_HideCaret(APIWidget: PGTKAPIWidget;
  var OldVisible: boolean);
begin
  {$IFDEF VerboseCaret}
  DebugLn('[GTKAPIWidget_HideCaret] A');
  {$ENDIF}
  if APIWidget = nil 
  then begin
    DebugLn('WARNING: [GTKAPIWidget_HideCaret] Got nil client');
    Exit;
  end;
  GTKAPIWidgetClient_HideCaret(PGTKAPIWidgetClient(APIWidget^.Client),OldVisible);
end;

procedure GTKAPIWidget_ShowCaret(APIWidget: PGTKAPIWidget); 
begin
  {$IFDEF VerboseCaret}
  DebugLn('[GTKAPIWidget_ShowCaret] A');
  {$ENDIF}
  if APIWidget = nil
  then begin
    DebugLn('WARNING: [GTKAPIWidget_ShowCaret] Got nil client');
    Exit;
  end;
  GTKAPIWidgetClient_ShowCaret(PGTKAPIWidgetClient(APIWidget^.Client));
end;

procedure GTKAPIWidget_SetCaretPos(APIWidget: PGTKAPIWidget; X, Y: Integer);
begin
  {$IFDEF VerboseCaret}
  DebugLn('[GTKAPIWidget_SetCaretPos] A');
  {$ENDIF}
  if APIWidget = nil
  then begin
    DebugLn('WARNING: [GTKAPIWidget_SetCaretPos] Got nil client');
    Exit;
  end;
  GTKAPIWidgetClient_SetCaretPos(PGTKAPIWidgetClient(APIWidget^.Client), X, Y);
end;

procedure GTKAPIWidget_GetCaretPos(APIWidget: PGTKAPIWidget; var X, Y: Integer); 
begin
  if APIWidget = nil 
  then begin
    DebugLn('WARNING: [GTKAPIWidget_GetCaretPos] Got nil client');
    Exit;
  end;
  GTKAPIWidgetClient_GetCaretPos(PGTKAPIWidgetClient(APIWidget^.Client), X, Y);
end;

procedure GTKAPIWidget_SetCaretRespondToFocus(APIWidget: PGTKAPIWidget;
  ShowHideOnFocus: boolean); 
begin
  {$IFDEF VerboseCaret}
  DebugLn('[GTKAPIWidget_SetCaretRespondToFocus] A ',ShowHideOnFocus);
  {$ENDIF}
  if APIWidget = nil
  then begin
    DebugLn('WARNING: [GTKAPIWidget_SetCaretRespondToFocus] Got nil client');
    Exit;
  end;
  GTKAPIWidgetClient_SetCaretRespondToFocus(
    PGTKAPIWidgetClient(APIWidget^.Client), ShowHideOnFocus);
end;

procedure GTKAPIWidget_GetCaretRespondToFocus(APIWidget: PGTKAPIWidget;
  var ShowHideOnFocus: boolean);
begin
  if APIWidget = nil
  then begin
    DebugLn('WARNING: [GTKAPIWidget_GetCaretRespondToFocus] Got nil client');
    Exit;
  end;
  GTKAPIWidgetClient_GetCaretRespondToFocus(
    PGTKAPIWidgetClient(APIWidget^.Client), ShowHideOnFocus);
end;

initialization
  MParentClass:=nil;

end.


