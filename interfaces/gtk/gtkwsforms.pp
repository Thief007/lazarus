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
 *  See the file COPYING.LCL, included in this distribution,                 *
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
  {$IFDEF GTK2} Gtk2, Glib2, gdk2, {$ELSE} Gtk, gdk, Glib, {$ENDIF}
  SysUtils, Classes, Controls, LMessages, InterfaceBase, graphics,
  Dialogs, WSDialogs, WSLCLClasses, gtkint, gtkproc, gtkwscontrols,
  Forms, WSForms, Math;

type

  { TGtkWSScrollingWinControl }

  TGtkWSScrollingWinControl = class(TWSScrollingWinControl)
  private
  protected
  public
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
  protected
  public
    class procedure SetFormBorderStyle(const AForm: TCustomForm;
                             const AFormBorderStyle: TFormBorderStyle); override;
    class procedure ShowModal(const ACustomForm: TCustomForm); override;
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

procedure TGtkWSCustomForm.SetFormBorderStyle(const AForm: TCustomForm;
  const AFormBorderStyle: TFormBorderStyle);
begin
  inherited SetFormBorderStyle(AForm, AFormBorderStyle);
  // the form border style can only be set at creation time.
  // This is Delphi compatible, so no Recreatewnd needed.
end;

procedure TGtkWSCustomForm.ShowModal(const ACustomForm: TCustomForm);
var
  GtkWindow: PGtkWindow;
begin
  ReleaseMouseCapture;
  if ACustomForm.Parent=nil then begin
    GtkWindow:=PGtkWindow(ACustomForm.Handle);
    gtk_window_set_default_size(GtkWindow,
                          Max(1,ACustomForm.Width),Max(1,ACustomForm.Height));
    gtk_widget_set_uposition(PGtkWidget(GtkWindow),
                             ACustomForm.Left, ACustomForm.Top);
  end;
  GtkWindowShowModal(GtkWindow);
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TScrollingWinControl, TGtkWSScrollingWinControl);
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
