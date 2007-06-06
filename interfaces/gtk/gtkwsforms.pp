{ $Id$}
{
 *****************************************************************************
 *                               GtkWSForms.pp                               * 
 *                               -------------                               * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit GtkWSForms;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF GTK2}
  Gtk2, Glib2, gdk2,
  {$ELSE}
  Gtk, gdk, Glib, X, Xlib,
  {$ENDIF}
  SysUtils, Classes, LCLProc, LCLType, Controls, LMessages, InterfaceBase,
  Graphics, Dialogs,Forms, Math,
  WSDialogs, WSLCLClasses, WSControls, WSForms, WSProc,
  gtkInt, gtkProc, gtkWSControls, gtkDef, gtkExtra, GtkWSPrivate;

type

  { TGtkWSScrollingWinControl }

  TGtkWSScrollingWinControl = class(TWSScrollingWinControl)
  private
  protected
  public
    class procedure ScrollBy(const AWinControl: TScrollingWinControl; const DeltaX, DeltaY: integer); override;
  end;

  { TGtkWSScrollBox }

  TGtkWSScrollBox = class(TWSScrollBox)
  private
  protected
  public
  end;

  { TGtkWSCustomFrame }

  TGtkWSCustomFrame = class(TWSCustomFrame)
  private
  protected
  public
  end;

  { TGtkWSFrame }

  TGtkWSFrame = class(TWSFrame)
  private
  protected
  public
  end;

  { TGtkWSCustomForm }

  TGtkWSCustomForm = class(TWSCustomForm)
  private
    class procedure  SetCallbacks(const AWinControl: TWinControl; const AWidgetInfo: PWidgetInfo); virtual;
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND; override;
    
    class procedure SetFormBorderStyle(const AForm: TCustomForm;
                             const AFormBorderStyle: TFormBorderStyle); override;
    class procedure SetIcon(const AForm: TCustomForm; const AIcon: HICON); override;
    class procedure SetShowInTaskbar(const AForm: TCustomForm; const AValue: TShowInTaskbar); override;
    class procedure ShowModal(const AForm: TCustomForm); override;
    class procedure SetBorderIcons(const AForm: TCustomForm;
                                   const ABorderIcons: TBorderIcons); override;
  end;

  { TGtkWSForm }

  TGtkWSForm = class(TWSForm)
  private
  protected
  public
  end;

  { TGtkWSHintWindow }

  TGtkWSHintWindow = class(TWSHintWindow)
  private
  protected
  public
  end;

  { TGtkWSScreen }

  TGtkWSScreen = class(TWSScreen)
  private
  protected
  public
  end;

  { TGtkWSApplicationProperties }

  TGtkWSApplicationProperties = class(TWSApplicationProperties)
  private
  protected
  public
  end;


implementation

{ TGtkWSCustomForm }

class procedure TGtkWSScrollingWinControl.ScrollBy(const AWinControl: TScrollingWinControl;
  const DeltaX, DeltaY: integer);
begin
end;


{ TGtkWSCustomForm }

{$IFDEF GTK1}
function GtkWSFormMapEvent(Widget: PGtkWidget; Event: PGdkEvent; WidgetInfo: PWidgetInfo): gboolean; cdecl;
var
  Message: TLMSize;
  AForm: TCustomForm;
begin
  Result := True;
  FillChar(Message, 0, SizeOf(Message));
  AForm := TCustomForm(WidgetInfo^.LCLObject);
  Message.Width := AForm.Width;
  Message.Height := AForm.Height;
  if WidgetInfo^.UserData <> nil then begin
    if AForm.WindowState = wsMaximized then
      WidgetSet.ShowWindow(AForm.Handle, SW_MAXIMIZE)
    else if AForm.WindowState = wsMinimized then
      WidgetSet.ShowWindow(AForm.Handle, SW_MINIMIZE);
    WidgetInfo^.UserData := nil;
  end;

  Message.Msg := LM_SIZE;
  if GDK_WINDOW_GET_MAXIMIZED(PGdkWindowPrivate(Widget^.window)) = True then
  begin
    Message.SizeType := SIZEFULLSCREEN or Size_SourceIsInterface;
  end
  else
  begin
    Message.SizeType := SIZENORMAL or Size_SourceIsInterface;
  end;
  
  DeliverMessage(WidgetInfo^.LCLObject, Message);
end;

function GtkWSFormUnMapEvent(Widget: PGtkWidget; Event: PGdkEvent; WidgetInfo: PWidgetInfo): gboolean; cdecl;
var
  Message: TLMSize;
  AForm: TCustomForm;
begin
  Result := True;
  FillChar(Message, 0, SizeOf(Message));
  AForm := TCustomForm(WidgetInfo^.LCLObject);
  
  // ignore the unmap signals when we switch desktops
  // as this results in irritating behavior when we return to the desktop
  if GDK_GET_CURRENT_DESKTOP <> GDK_WINDOW_GET_DESKTOP(PGdkWindowPrivate(Widget^.Window)) then Exit;

  Message.Msg := LM_SIZE;
  Message.SizeType := SIZEICONIC or Size_SourceIsInterface;
  Message.Width := AForm.Width;
  Message.Height := AForm.Height;

  DeliverMessage(WidgetInfo^.LCLObject, Message);
end;
{$ENDIF}


class procedure TGtkWSCustomForm.SetCallbacks(const AWinControl: TWinControl;
  const AWidgetInfo: PWidgetInfo);
begin
  {$IFDEF GTK1}
  gtk_signal_connect(PGtkObject(AWidgetInfo^.CoreWidget),'map-event', TGtkSignalFunc(@GtkWSFormMapEvent), AWidgetInfo);
  gtk_signal_connect(PGtkObject(AWidgetInfo^.CoreWidget),'unmap-event', TGtkSignalFunc(@GtkWSFormUnMapEvent), AWidgetInfo);
  {$ENDIF}
end;

class function TGtkWSCustomForm.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  AWidgetInfo: PWidgetInfo;
begin
  // TODO: Move GtkInt.CreateForm to here. Somewhat complicated though because
  //       it depends on several other methods from gtkint that are private.
  Result:=WidgetSet.CreateComponent(AWinControl);
  AWidgetInfo := GetWidgetInfo(Pointer(Result));
  if not (csDesigning in AWinControl.ComponentState) then
    AWidgetInfo^.UserData := Pointer(1);
  SetCallbacks(AWinControl, AWidgetInfo);
end;

class procedure TGtkWSCustomForm.SetFormBorderStyle(const AForm: TCustomForm;
  const AFormBorderStyle: TFormBorderStyle);
begin
  if not WSCheckHandleAllocated(AForm, 'SetFormBorderStyle')
  then Exit;

  inherited SetFormBorderStyle(AForm, AFormBorderStyle);
  // the form border style can only be set at creation time.
  // This is Delphi compatible, so no Recreatewnd needed.
  {$note check if this implies that the lcl recreates the handle here}
  // otherwise the lcl recreatewnd call should be removed and placed here.
end;

class procedure TGtkWSCustomForm.SetIcon(const AForm: TCustomForm; const AIcon: HICON);
var
  GdiObject: PGdiObject;
  Window: PGdkWindow;
begin
  if not WSCheckHandleAllocated(AForm, 'SetIcon')
  then Exit;

  if AForm.Parent <> nil then Exit;
  if AIcon = 0 then Exit;

  Window := GetControlWindow(PGtkWidget(AForm.Handle));
  if Window = nil then Exit;

  GdiObject := PGdiObject(AIcon);
  gdk_window_set_icon(Window, nil, GdiObject^.GDIPixmapObject.Image, GdiObject^.GDIPixmapObject.Mask);
end;

class procedure TGtkWSCustomForm.SetShowInTaskbar(const AForm: TCustomForm;
  const AValue: TShowInTaskbar);
begin
  if not WSCheckHandleAllocated(AForm, 'SetShowInTaskbar')
  then Exit;

  SetFormShowInTaskbar(AForm,AValue);
end;

class procedure TGtkWSCustomForm.ShowModal(const AForm: TCustomForm);
var
  GtkWindow: PGtkWindow;
begin
  if not WSCheckHandleAllocated(AForm, 'ShowModal')
  then Exit;

  if AForm.Parent <> nil then Exit;
  ReleaseMouseCapture;

  GtkWindow := PGtkWindow(AForm.Handle);
  gtk_window_set_default_size(GtkWindow, Max(1,AForm.Width), Max(1,AForm.Height));
  gtk_widget_set_uposition(PGtkWidget(GtkWindow), AForm.Left, AForm.Top);
  GtkWindowShowModal(GtkWindow);
end;

class procedure TGtkWSCustomForm.SetBorderIcons(const AForm: TCustomForm;
  const ABorderIcons: TBorderIcons);
  
  procedure RaiseNotImplemented;
  begin
    raise Exception.Create('TGtkWSCustomForm.SetBorderIcons BorderIcons not supported by gtk interface');
  end;
  
begin
  if not WSCheckHandleAllocated(AForm, 'SetBorderIcons')
  then Exit;
  
  {$note remove check here, it belongs in the lcl}
  if (AForm.ComponentState*[csDesigning,csLoading]=[csDesigning]) then begin
    if (AForm.BorderIcons<>DefaultBorderIcons[AForm.BorderStyle]) then
      RaiseNotImplemented;
  end;
  inherited SetBorderIcons(AForm, ABorderIcons);
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TScrollingWinControl, TGtkWSScrollingWinControl, TGtkPrivateScrollingWinControl);
//  RegisterWSComponent(TScrollBox, TGtkWSScrollBox);
//  RegisterWSComponent(TCustomFrame, TGtkWSCustomFrame);
//  RegisterWSComponent(TFrame, TGtkWSFrame);
  RegisterWSComponent(TCustomForm, TGtkWSCustomForm);
//  RegisterWSComponent(TForm, TGtkWSForm);
//  RegisterWSComponent(THintWindow, TGtkWSHintWindow);
//  RegisterWSComponent(TScreen, TGtkWSScreen);
//  RegisterWSComponent(TApplicationProperties, TGtkWSApplicationProperties);
////////////////////////////////////////////////////
end.
