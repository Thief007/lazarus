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
  Gtk,
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Controls,
////////////////////////////////////////////////////
  Classes, LMessages,
  WSControls, WSLCLClasses;

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
    class procedure SetCursor(AControl: TControl; ACursor: TCursor); override;
  end;

  { TGtkWSWinControl }

  TGtkWSWinControl = class(TWSWinControl)
  private
  protected
  public
    class procedure SetCallbacks(const AGTKObject: PGTKObject; const AComponent: TComponent);
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


implementation

uses
  GtkProc, GtkDef, GtkInt;

{ TGtkWSControl }
  
procedure TGtkWSControl.SetCursor(AControl: TControl; ACursor: TCursor);
begin
  { TODO: Dangerous cast here! TControl.SetCursor exists }
  gtkproc.SetCursor(AControl as TWinControl, ACursor); 
end;

{ TGtkWSWinControl }
  
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


initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TDragImageList, TGtkWSDragImageList);
  RegisterWSComponent(TControl, TGtkWSControl);
//  RegisterWSComponent(TWinControl, TGtkWSWinControl);
//  RegisterWSComponent(TGraphicControl, TGtkWSGraphicControl);
//  RegisterWSComponent(TCustomControl, TGtkWSCustomControl);
//  RegisterWSComponent(TImageList, TGtkWSImageList);
////////////////////////////////////////////////////
end.
