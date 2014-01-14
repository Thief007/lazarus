{ $Id$}
{
 *****************************************************************************
 *                             GtkWSControls.pp                              * 
 *                             ----------------                              * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit GtkWSControls;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF GTK2} Gtk2, Glib2, Gdk2, {$ELSE} Gtk, Glib, Gdk, {$ENDIF}
  SysUtils, Classes, Controls, LMessages, InterfaceBase,
  WSControls, WSLCLClasses, Graphics, ComCtrls;

type

  { TGtkWSDragImageList }

  TGtkWSDragImageList = class(TWSDragImageList)
  private
  protected
  public
  end;

  { TGtkWSControl }

  TGtkWSControl = class(TWSControl)
  private
  protected
  public
  end;

  { TGtkWSWinControl }

  TGtkWSWinControl = class(TWSWinControl)
  private
  protected
  public
    // Internal public
    class procedure SetCallbacks(const AGTKObject: PGTKObject; const AComponent: TComponent);
  public
    class procedure AddControl(const AControl: TControl); override;

    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
    class procedure SetSize(const AWinControl: TWinControl; const AWidth, AHeight: Integer); override;
    class procedure SetPos(const AWinControl: TWinControl; const ALeft, ATop: Integer); override;
    class procedure SetCursor(const AControl: TControl; const ACursor: TCursor); override;
    class procedure SetColor(const AWinControl: TWinControl); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: string); override;

    class procedure ConstraintsChange(const AWinControl: TWinControl); override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class procedure Invalidate(const AWinControl: TWinControl); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
  end;

  { TGtkWSGraphicControl }

  TGtkWSGraphicControl = class(TWSGraphicControl)
  private
  protected
  public
  end;

  { TGtkWSCustomControl }

  TGtkWSCustomControl = class(TWSCustomControl)
  private
  protected
  public
  end;

  { TGtkWSImageList }

  TGtkWSImageList = class(TWSImageList)
  private
  protected
  public
  end;


procedure GtkWindowShowModal(GtkWindow: PGtkWindow);

implementation

uses
  GtkDef, GtkInt, gtkglobals, gtkproc, GTKWinApiWindow,
  StdCtrls, LCLProc, LCLIntf, LCLType;

{ TGtkWSWinControl }
  
procedure TGtkWSWinControl.AddControl(const AControl: TControl);
var
  AParent: TWinControl;
  ParentWidget: PGTKWidget;
  ChildWidget: PGTKWidget;
  pFixed: PGTKWidget;
begin
  {$IFDEF OldToolBar}
  if (AControl.Parent is TToolbar) then
    exit;
  {$ENDIF}
  
  AParent := TWinControl(AControl).Parent;
  //debugln('LM_AddChild: ',TWinControl(Sender).Name,' ',dbgs(AParent<>nil));
  if not Assigned(AParent) then begin
    Assert(true, Format('Trace: [TGtkWSWinControl.AddControl] %s --> Parent is not assigned', [AControl.ClassName]));
  end else begin
    Assert(False, Format('Trace:  [TGtkWSWinControl.AddControl] %s --> Calling Add Child: %s', [AParent.ClassName, AControl.ClassName]));
    ParentWidget := Pgtkwidget(AParent.Handle);
    pFixed := GetFixedWidget(ParentWidget);
    if pFixed <> ParentWidget then begin
      // parent changed for child
      ChildWidget := PgtkWidget(TWinControl(AControl).Handle);
      FixedPutControl(pFixed, ChildWidget, AParent.Left, AParent.Top);
      RegroupAccelerator(ChildWidget);
    end;
  end;
end;

function TGtkWSWinControl.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
var
  CS: PChar;
  Handle: HWND;
begin
  Result := true;
  Handle := AWinControl.Handle;
  case AWinControl.fCompStyle of
   csComboBox:
     begin
       AText := StrPas(gtk_entry_get_text(PGtkEntry(PGtkCombo(Handle)^.entry)));
     end;

   csEdit, csSpinEdit:
       AText:= StrPas(gtk_entry_get_text(PgtkEntry(Handle)));

   csMemo    : begin
                  CS := gtk_editable_get_chars(PGtkOldEditable(
                    GetWidgetInfo(Pointer(Handle), True)^.CoreWidget), 0, -1);
                  AText := StrPas(CS);
                  g_free(CS);
               end;
  else
    Result := false;
  end;
end;

procedure TGtkWSWinControl.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
begin                
  TGtkWidgetSet(InterfaceObject).SetResizeRequest(PGtkWidget(AWinControl.Handle));
end;

procedure TGtkWSWinControl.SetCallbacks(const AGTKObject: PGTKObject; const AComponent: TComponent);
//TODO: Remove ALCLObject when the creation splitup is finished
begin
  GtkWidgetSet.SetCallback(LM_SHOWWINDOW, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_DESTROY, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_FOCUS, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_WINDOWPOSCHANGED, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_PAINT, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_EXPOSEEVENT, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_KEYDOWN, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_KEYUP, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_CHAR, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_MOUSEMOVE, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_LBUTTONDOWN, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_LBUTTONUP, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_RBUTTONDOWN, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_RBUTTONUP, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_MBUTTONDOWN, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_MBUTTONUP, AGTKObject, AComponent);
  GtkWidgetSet.SetCallback(LM_MOUSEWHEEL, AGTKObject, AComponent);
end;

procedure TGtkWSWinControl.SetBorderStyle(const AWinControl: TWinControl;
  const ABorderStyle: TBorderStyle);
var
  Widget: PGtkWidget;
  APIWidget: PGTKAPIWidget;
begin
  Widget := PGtkWidget(AWinControl.Handle);
  if GtkWidgetIsA(Widget,GTKAPIWidget_GetType) then begin
    //DebugLn('TGtkWSWinControl.SetBorderStyle ',AWinControl.Name,':',AWinControl.ClassName,' ',ord(ABorderStyle));
    APIWidget := PGTKAPIWidget(Widget);
    if (APIWidget^.Frame<>nil) then begin
      case ABorderStyle of
      bsNone: gtk_frame_set_shadow_type(APIWidget^.Frame,GTK_SHADOW_NONE);
      bsSingle: gtk_frame_set_shadow_type(APIWidget^.Frame,GTK_SHADOW_ETCHED_IN);
      end;
    end;
  end;
end;

procedure TGtkWSWinControl.SetCursor(const AControl: TControl; const ACursor: TCursor);
begin
  GtkProc.SetCursor(AControl as TWinControl, ACursor); 
end;

procedure TGtkWSWinControl.SetFont(const AWinControl: TWinControl; const AFont: TFont);
begin
  DebugLn('TGtkWSWinControl.SetFont: implement me!');
  // TODO: implement me!
end;

procedure TGtkWSWinControl.SetPos(const AWinControl: TWinControl; const ALeft, ATop: Integer); 
var
  Widget: PGtkWidget;
  Allocation: TGTKAllocation;
begin                
  Widget := PGtkWidget(AWinControl.Handle);
  Allocation.X := gint16(ALeft);
  Allocation.Y := gint16(ATop);
  Allocation.Width := guint16(Widget^.Allocation.Width);
  Allocation.Height := guint16(Widget^.Allocation.Height);
  gtk_widget_size_allocate(Widget, @Allocation);
end;

procedure TGtkWSWinControl.SetSize(const AWinControl: TWinControl; const AWidth, AHeight: Integer); 
var
  Widget: PGtkWidget;
  Allocation: TGTKAllocation;
begin                
  Widget := PGtkWidget(AWinControl.Handle);
  Allocation.X := Widget^.Allocation.X;
  Allocation.Y := Widget^.Allocation.Y;
  Allocation.Width := guint16(AWidth);
  Allocation.Height := guint16(AHeight);
  gtk_widget_size_allocate(Widget, @Allocation);
end;

procedure TGtkWSWinControl.SetColor(const AWinControl: TWinControl);
begin
  UpdateWidgetStyleOfControl(AWinControl);
end;

procedure TGtkWSWinControl.SetText(const AWinControl: TWinControl; const AText: string);

  procedure SetNotebookPageTabLabel;
  var
    NoteBookWidget: PGtkWidget; // the notebook
    PageWidget: PGtkWidget;     // the page (content widget)
    TabWidget: PGtkWidget;      // the tab (hbox containing a pixmap, a label
                                //          and a close button)
    TabLabelWidget: PGtkWidget; // the label in the tab
    MenuWidget: PGtkWidget;     // the popup menu (hbox containing a pixmap and
                                // a label)
    MenuLabelWidget: PGtkWidget; // the label in the popup menu item
    NewText: PChar;
  begin
    // dig through the hierachy to get the labels
    NoteBookWidget:=PGtkWidget((AWinControl.Parent).Handle);
    PageWidget:=PGtkWidget(AWinControl.Handle);
    TabWidget:=gtk_notebook_get_tab_label(PGtkNoteBook(NotebookWidget),
                                          PageWidget);
    if TabWidget<>nil then
      TabLabelWidget:=gtk_object_get_data(PGtkObject(TabWidget), 'TabLabel')
    else
      TabLabelWidget:=nil;
    MenuWidget:=gtk_notebook_get_menu_label(PGtkNoteBook(NotebookWidget),
                                            PageWidget);
    if MenuWidget<>nil then
      MenuLabelWidget:=gtk_object_get_data(PGtkObject(MenuWidget), 'TabLabel')
    else
      MenuLabelWidget:=nil;
    // set new text
    NewText:=PChar(AText);
    if TabLabelWidget<>nil then
      gtk_label_set_text(pGtkLabel(TabLabelWidget), NewText);
    if MenuLabelWidget<>nil then
      gtk_label_set_text(pGtkLabel(MenuLabelWidget), NewText);
  end;

var
  DC : hDC;
  P : Pointer;
  aLabel, pLabel: pchar;
  AccelKey : integer;
begin
  P := Pointer(AWinControl.Handle);
  Assert(p = nil, 'Trace:WARNING: [TGtkWidgetSet.SetLabel] --> got nil pointer');
  Assert(False, 'Trace:Setting Str1 in SetLabel');
  pLabel := pchar(AText);

  case AWinControl.fCompStyle of
  csBitBtn,
  csButton: DebugLn('[WARNING] Obsolete call to TGTKOBject.SetLabel for ', AWinControl.ClassName);
  
{$IFDEF OldToolBar}
  csToolButton:
    with PgtkButton(P)^ do
    begin
      //aLabel := StrAlloc(Length(AnsiString(PLabel)) + 1);
      aLabel := Ampersands2Underscore(PLabel);
      Try
        //StrPCopy(aLabel, AnsiString(PLabel));
        //Accel := Ampersands2Underscore(aLabel);
        if gtk_bin_get_child(P) = nil then
        begin
          Assert(False, Format('trace:  [TGtkWidgetSet.SetLabel] %s has no child label', [AWinControl.ClassName]));
           gtk_container_add(P, gtk_label_new(aLabel));
        end
        else begin
          Assert(False, Format('trace:  [TGtkWidgetSet.SetLabel] %s has child label', [AWinControl.ClassName]));
          gtk_label_set_text(pgtkLabel( gtk_bin_get_child(P)), aLabel);
        end;
        //If Accel <> -1 then
        AccelKey:=gtk_label_parse_uline(PGtkLabel( gtk_bin_get_child(P)), aLabel);
        Accelerate(AWinControl,PGtkWidget(P),AccelKey,0,'clicked');
      Finally
        StrDispose(aLabel);
      end;
    end;
{$ENDIF OldToolBar}

  csForm,
  csFileDialog, csOpenFileDialog, csSaveFileDialog, csSelectDirectoryDialog,
  csPreviewFileDialog,
  csColorDialog,
  csFontDialog:
    if GtkWidgetIsA(p,gtk_window_get_type) then
      gtk_window_set_title(pGtkWindow(p),PLabel);

  csStaticText:
    begin
      if TStaticText(AWinControl).ShowAccelChar then begin
        If {TStaticText(AWinControl).WordWrap and }(TStaticText(AWinControl).Caption<>'') then begin
          DC := GetDC(HDC(GetStyleWidget(lgsLabel)));
          aLabel := TGtkWidgetSet(InterfaceObject).ForceLineBreaks(DC, pLabel, TStaticText(AWinControl).Width, True);
          DeleteDC(DC);
        end
        else
          aLabel:= Ampersands2Underscore(pLabel);
        try
          AccelKey:= gtk_label_parse_uline(pGtkLabel(p), aLabel);
          Accelerate(TComponent(AWinControl),PGtkWidget(p),AccelKey,0,'grab_focus');
        finally
          StrDispose(aLabel);
        end;
      end else begin
{
        If TStaticText(AWinControl).WordWrap then begin
          DC := GetDC(HDC(GetStyleWidget(lgsLabel)));
          aLabel := TGtkWidgetSet(InterfaceObject).ForceLineBreaks(DC, pLabel, TStaticText(AWinControl).Width, False);
          gtk_label_set_text(PGtkLabel(p), aLabel);
          StrDispose(aLabel);
          DeleteDC(DC);
        end
        else
}      
          gtk_label_set_text(PGtkLabel(p), pLabel);
        gtk_label_set_pattern(PGtkLabel(p), nil);
      end;
    end;

  csCheckBox,
  csToggleBox,
  csRadioButton:
    begin
      aLabel := Ampersands2Underscore(PLabel);
      Try
        gtk_label_set_text(
                    pGtkLabel(gtk_bin_get_child(@PGTKToggleButton(p)^.Button)),
                    aLabel);
        gtk_label_parse_uline(pGtkLabel(gtk_bin_get_child(@PGTKToggleButton(p)^.Button)),
          aLabel);
      Finally
        StrDispose(aLabel);
      end;
    end;

  csGroupBox    : gtk_frame_set_label(pgtkFrame(P),pLabel);

  csEdit        : begin
                    LockOnChange(PGtkObject(p),+1);
                    gtk_entry_set_text(pGtkEntry(P), pLabel);
                    LockOnChange(PGtkObject(p),-1);
                  end;

  csMemo        : begin
                    P:= GetWidgetInfo(P, True)^.CoreWidget;
                    //debugln('TGtkWSWinControl.SetText A ',dbgs(gtk_text_get_length(PGtkText(P))),' AText="',AText,'"');
                    gtk_text_freeze(PGtkText(P));
                    gtk_text_set_point(PGtkText(P), 0);
                    gtk_text_forward_delete(PGtkText(P), gtk_text_get_length(PGtkText(P)));
                    gtk_text_insert(PGtkText(P), nil, nil, nil, pLabel, -1);
                    gtk_text_thaw(PGtkText(P));
                    //debugln('TGtkWSWinControl.SetText B ',dbgs(gtk_text_get_length(PGtkText(P))));
                  end;

  csPage:
    SetNotebookPageTabLabel;

  csComboBox    :
    begin
      //DebugLn('SetLabel: ',TComboBox(Sender).Name,':',TComboBox(Sender).ClassName,
      //  ' ',HexStr(Cardinal(TComboBox(Sender).Handle),8),' "',PLabel,'"');
      SetComboBoxText(PGtkCombo(TComboBox(AWinControl).Handle), PLabel);
    end;

  else
    // DebugLn('WARNING: [TGtkWidgetSet.SetLabel] --> not handled for class ',Sender.ClassName);
  end;
  Assert(False, Format('trace:  [TGtkWidgetSet.SetLabel] %s --> END', [AWinControl.ClassName]));
end;

procedure TGtkWSWinControl.ConstraintsChange(const AWinControl: TWinControl);
var
  Widget: PGtkWidget;
  Geometry: TGdkGeometry;
begin
  Widget := PGtkWidget(AWinControl.Handle);
  if (Widget <> nil) and (GtkWidgetIsA(Widget,gtk_window_get_type)) then begin
    with Geometry, AWinControl do begin
      if Constraints.MinWidth > 0 then
        min_width:= Constraints.MinWidth else min_width:= 1;
      if Constraints.MaxWidth > 0 then
        max_width:= Constraints.MaxWidth else max_width:= 32767;
      if Constraints.MinHeight > 0 then
        min_height:= Constraints.MinHeight else min_height:= 1;
      if Constraints.MaxHeight > 0 then
        max_height:= Constraints.MaxHeight else max_height:= 32767;
      base_width:= Width;
      base_height:= Height;
      width_inc:= 1;
      height_inc:= 1;
      min_aspect:= 0;
      max_aspect:= 1;
    end;
    //debugln('TGtkWSWinControl.ConstraintsChange A ',GetWidgetDebugReport(Widget),' max=',dbgs(Geometry.max_width),'x',dbgs(Geometry.max_height));
    gtk_window_set_geometry_hints(PGtkWindow(Widget), nil, @Geometry,
                                GDK_HINT_MIN_SIZE or GDK_HINT_MAX_SIZE);
  end;
end;

procedure TGtkWSWinControl.DestroyHandle(const AWinControl: TWinControl);
begin
  TGtkWidgetSet(InterfaceObject).DestroyLCLComponent(AWinControl);
end;

procedure TGtkWSWinControl.Invalidate(const AWinControl: TWinControl);
begin
  Assert(false, 'Trace:Trying to invalidate window... !!!');
  //THIS DOESN'T WORK YET....
  {
         Event.thetype := GDK_EXPOSE;
     Event.window := PgtkWidget(Handle)^.Window;
     Event.Send_Event := 0;
     Event.X := 0;
     Event.Y := 0;
     Event.Width := PgtkWidget((Handle)^.Allocation.Width;
     Event.Height := PgtkWidget(Handle)^.Allocation.Height;
         gtk_Signal_Emit_By_Name(PgtkObject(Handle),'expose_event',[(Sender as TWinControl).Handle,Sender,@Event]);
     Assert(False, 'Trace:Signal Emitted - invalidate window'); 
  }
  gtk_widget_queue_draw(PGtkWidget(AWinControl.Handle));
end;

procedure TGtkWSWinControl.ShowHide(const AWinControl: TWinControl);
begin
  // other methods use ShowHide also, can't move code
  TGtkWidgetSet(InterfaceObject).ShowHide(AWinControl);
end;

{ helper/common routines }

procedure GtkWindowShowModal(GtkWindow: PGtkWindow);
begin
  if (GtkWindow=nil) then exit;
  TGtkWidgetSet(InterfaceObject).UnsetResizeRequest(PgtkWidget(GtkWindow));

  if ModalWindows=nil then ModalWindows:=TList.Create;
  ModalWindows.Add(GtkWindow);

  gtk_window_set_modal(GtkWindow, true);
  gtk_widget_show(PGtkWidget(GtkWindow));

  {$IFDEF VerboseTransient}
  DebugLn('TGtkWidgetSet.ShowModal ',Sender.ClassName);
  {$ENDIF}
  TGtkWidgetSet(InterfaceObject).UpdateTransientWindows;
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TDragImageList, TGtkWSDragImageList);
//  RegisterWSComponent(TControl, TGtkWSControl);
  RegisterWSComponent(TWinControl, TGtkWSWinControl);
//  RegisterWSComponent(TGraphicControl, TGtkWSGraphicControl);
//  RegisterWSComponent(TCustomControl, TGtkWSCustomControl);
//  RegisterWSComponent(TImageList, TGtkWSImageList);
////////////////////////////////////////////////////
end.