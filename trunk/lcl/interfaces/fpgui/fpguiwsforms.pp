{ $Id: FpGuiwsforms.pp 5319 2004-03-17 20:11:29Z marc $}
{
 *****************************************************************************
 *                               FpGuiWSForms.pp                                * 
 *                               ------------                                * 
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
unit FpGuiWSForms;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Forms,
////////////////////////////////////////////////////
  WSForms, WSLCLClasses, LCLType, Controls;

type

  { TFpGuiWSScrollingWinControl }

  TFpGuiWSScrollingWinControl = class(TWSScrollingWinControl)
  private
  protected
  public
  end;

  { TFpGuiWSScrollBox }

  TFpGuiWSScrollBox = class(TWSScrollBox)
  private
  protected
  public
  end;

  { TFpGuiWSCustomFrame }

  TFpGuiWSCustomFrame = class(TWSCustomFrame)
  private
  protected
  public
  end;

  { TFpGuiWSFrame }

  TFpGuiWSFrame = class(TWSFrame)
  private
  protected
  public
  end;

  { TFpGuiWSCustomForm }

  TFpGuiWSCustomForm = class(TWSCustomForm)
  private
  protected
  public
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    
    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure SetFormBorderStyle(const AForm: Forms.TCustomForm;
                             const AFormBorderStyle: TFormBorderStyle); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
  end;

  { TFpGuiWSForm }

  TFpGuiWSForm = class(TWSForm)
  private
  protected
  public
  end;

  { TFpGuiWSHintWindow }

  TFpGuiWSHintWindow = class(TWSHintWindow)
  private
  protected
  public
  end;

  { TFpGuiWSScreen }

  TFpGuiWSScreen = class(TWSScreen)
  private
  protected
  public
  end;

  { TFpGuiWSApplicationProperties }

  TFpGuiWSApplicationProperties = class(TWSApplicationProperties)
  private
  protected
  public
  end;


implementation
uses FPGuiWSPrivate, fpgui, fpgfx, gfxbase, Classes;

{ TFpGuiWSCustomForm }

class function TFpGuiWSCustomForm.GetText(const AWinControl: TWinControl;
  var AText: String): Boolean;
var
  FPForm: TFPGUIPrivateWindow;
begin
  Result := True;
  FPForm := TFPGUIPrivateWindow(AWinControl.Handle);
  AText := FPForm.GetText;
end;
class function TFpGuiWSCustomForm.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  FPForm: TFPGUIPrivateWindow;
begin
  FPForm := TFPGUIPrivateWindow.Create(AWinControl, AParams);
  Result := TLCLIntfHandle(FPForm);
end;

class procedure TFpGuiWSCustomForm.SetFormBorderStyle(const AForm: Forms.TCustomForm;
  const AFormBorderStyle: TFormBorderStyle);
var
  FPForm: TFPGUIPrivateWindow;
begin
  FPForm := TFPGUIPrivateWindow(AForm.Handle);

end;

class procedure TFpGuiWSCustomForm.SetText(const AWinControl: TWinControl;
  const AText: String);
var
  FPForm: TFPGUIPrivateWindow;
begin
  FPForm := TFPGUIPrivateWindow(AWincontrol.Handle);
  FPForm.SetText(AText);
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TScrollingWinControl, TFpGuiWSScrollingWinControl);
//  RegisterWSComponent(TScrollBox, TFpGuiWSScrollBox);
//  RegisterWSComponent(TCustomFrame, TFpGuiWSCustomFrame);
//  RegisterWSComponent(TFrame, TFpGuiWSFrame);
  RegisterWSComponent(Forms.TCustomForm, TFpGuiWSCustomForm);
//  RegisterWSComponent(Forms.TForm, TFpGuiWSForm);
//  RegisterWSComponent(THintWindow, TFpGuiWSHintWindow);
//  RegisterWSComponent(TScreen, TFpGuiWSScreen);
//  RegisterWSComponent(TApplicationProperties, TFpGuiWSApplicationProperties);
////////////////////////////////////////////////////
end.
