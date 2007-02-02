{ $Id: $ }
{
                  ----------------------------------------
                   Gtkprivate.pp  -  Gtk internal classes
                  ----------------------------------------

 @created(Thu Feb 1st WET 2007)
 @lastmod($Date: $)
 @author(Marc Weustink <marc@@lazarus.dommelstein.net>)

 This unit contains the private classhierarchy for the gtk implemetations
 This hierarchy reflects (more or less) the gtk widget hierarchy

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

unit GtkPrivate;
{$mode objfpc}{$H+}

interface

uses
  // libs
  {$IFDEF GTK2}
  Gtk2, Glib2, Gdk2,
  {$ELSE}
  Gtk, Glib, Gdk,
  {$ENDIF}
  // RTL
  Classes, SysUtils, 
  // LCL
  LCLType, LMessages, LCLProc, Controls, Forms,
  // widgetset
  WSControls, WSLCLClasses, WSProc,
  // interface
  GtkDef, GtkProc;


type
  { TGtkPrivate }
  { Generic base class, don't know if it is needed }

  TGtkPrivate = class(TWSPrivate)
  private
  protected
  public
  end;

  { TGtkPrivateWidget }
  { Private class for all gtk widgets }

  TGtkPrivateWidget = class(TGtkPrivate)
  private
  protected
  public
    class procedure SetZPosition(const AWinControl: TWinControl; const APosition: TWSZPosition); virtual;
    class procedure UpdateCursor(AInfo: PWidgetInfo); virtual;
  end;
  TGtkPrivateWidgetClass = class of TGtkPrivateWidget;
  
  

  { TGtkPrivateContainer }
  { Private class for gtkcontainers }

  TGtkPrivateContainer = class(TGtkPrivateWidget)
  private
  protected
  public
  end;
  
  
  { ------------------------------------}
  { temp classes to keep things working }
  
  { TGtkWSScrollingPrivate }
  { we may want to use something  like a compund class }

  TGtkPrivateScrolling = class(TGtkPrivateContainer)
  private
  protected
  public
    class procedure SetZPosition(const AWinControl: TWinControl; const APosition: TWSZPosition); override;
  end;
  
  TGtkPrivateScrollingWinControl = class(TGtkPrivateScrolling)
  private
  protected
  public
    class procedure SetZPosition(const AWinControl: TWinControl; const APosition: TWSZPosition); override;
  end;
  { ------------------------------------}




  { TGtkPrivateBin }
  { Private class for gtkbins }

  TGtkPrivateBin = class(TGtkPrivateContainer)
  private
  protected
  public
  end;


  { TGtkPrivateWindow }
  { Private class for gtkwindows }

  TGtkPrivateWindow = class(TGtkPrivateBin)
  private
  protected
  public
  end;


  { TGtkPrivateDialog }
  { Private class for gtkdialogs }

  TGtkPrivateDialog = class(TGtkPrivateWindow)
  private
  protected
  public
  end;


  { TGtkPrivateButton }
  { Private class for gtkbuttons }

  TGtkPrivateButton = class(TGtkPrivateBin)
  private
  protected
  public
  end;


implementation

// Helper functions

function GetWidgetWithWindow(const AHandle: THandle): PGtkWidget;
var
  Children: PGList;
begin
  Result := PGTKWidget(AHandle);
  while (Result <> nil) and GTK_WIDGET_NO_WINDOW(Result)
  and GtkWidgetIsA(Result,gtk_container_get_type) do
  begin
    Children := gtk_container_children(PGtkContainer(Result));
    if Children = nil
    then Result := nil
    else Result := Children^.Data;
  end;
end;


{ TGtkPrivateScrolling }
{ temp class to keep things working }

class procedure TGtkPrivateScrolling.SetZPosition(const AWinControl: TWinControl; const APosition: TWSZPosition);
var
  ScrollWidget: PGtkScrolledWindow;
//  WidgetInfo: PWidgetInfo;
  Widget: PGtkWidget;
begin
  if not WSCheckHandleAllocated(AWincontrol, 'SetZPosition')
  then Exit;

  ScrollWidget := Pointer(AWinControl.Handle);
//  WidgetInfo := GetWidgetInfo(ScrollWidget);
  // Some controls have viewports, so we get the first window.
  Widget := GetWidgetWithWindow(AWinControl.Handle);

  case APosition of
    wszpBack:  begin
      //gdk_window_lower(WidgetInfo^.CoreWidget^.Window);
      gdk_window_lower(Widget^.Window);
      if ScrollWidget^.hscrollbar <> nil
      then gdk_window_lower(ScrollWidget^.hscrollbar^.Window);
      if ScrollWidget^.vscrollbar <> nil
      then gdk_window_lower(ScrollWidget^.vscrollbar^.Window);
    end;
    wszpFront: begin
      //gdk_window_raise(WidgetInfo^.CoreWidget^.Window);
      gdk_window_raise(Widget^.Window);
      if ScrollWidget^.hscrollbar <> nil
      then gdk_window_raise(ScrollWidget^.hscrollbar^.Window);
      if ScrollWidget^.vscrollbar <> nil
      then gdk_window_raise(ScrollWidget^.vscrollbar^.Window);
    end;
  end;
end;

{ TGtkPrivateScrollingWinControl }

class procedure TGtkPrivateScrollingWinControl.SetZPosition(const AWinControl: TWinControl; const APosition: TWSZPosition);
var
  Widget: PGtkWidget;
  ScrollWidget: PGtkScrolledWindow;
//  WidgetInfo: PWidgetInfo;
begin
  if not WSCheckHandleAllocated(AWincontrol, 'SetZPosition')
  then Exit;

  //TODO: when all scrolling controls are "derived" from TGtkWSBaseScrollingWinControl
  //      retrieve scrollbars from WidgetInfo^.Userdata. In that case, the following
  //      code can be removed and a call to TGtkWSBaseScrollingWinControl.SetZPosition
  //      can be made. This is not possible now since we have a frame around us

  Widget := Pointer(AWinControl.Handle);
//  WidgetInfo := GetWidgetInfo(Widget);
  ScrollWidget := PGtkScrolledWindow(PGtkFrame(Widget)^.Bin.Child);

  // Only do the scrollbars, leave the core to the default (we might have a viewport)
  TGtkPrivateWidget.SetZPosition(AWinControl, APosition);

  case APosition of
    wszpBack:  begin
//      gdk_window_lower(WidgetInfo^.CoreWidget^.Window);
      if ScrollWidget^.hscrollbar <> nil
      then gdk_window_lower(ScrollWidget^.hscrollbar^.Window);
      if ScrollWidget^.vscrollbar <> nil
      then gdk_window_lower(ScrollWidget^.vscrollbar^.Window);
    end;
    wszpFront: begin
//      gdk_window_raise(WidgetInfo^.CoreWidget^.Window);
      if ScrollWidget^.hscrollbar <> nil
      then gdk_window_raise(ScrollWidget^.hscrollbar^.Window);
      if ScrollWidget^.vscrollbar <> nil
      then gdk_window_raise(ScrollWidget^.vscrollbar^.Window);
    end;
  end;
end;



{$I gtkprivatewidget.inc}

end.
  
