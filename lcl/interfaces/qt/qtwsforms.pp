{ $Id$}
{
 *****************************************************************************
 *                               QtWSForms.pp                                * 
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
unit QtWSForms;

{$mode delphi}{$H+}

interface

uses
  // Bindings
  qt4, qtprivate,
  // LCL
  SysUtils, Controls, LCLType, Forms,
  // Widgetset
  InterfaceBase, WSForms, WSLCLClasses;

type

  { TQtWSScrollingWinControl }

  TQtWSScrollingWinControl = class(TWSScrollingWinControl)
  private
  protected
  public
  end;

  { TQtWSScrollBox }

  TQtWSScrollBox = class(TWSScrollBox)
  private
  protected
  public
  end;

  { TQtWSCustomFrame }

  TQtWSCustomFrame = class(TWSCustomFrame)
  private
  protected
  public
  end;

  { TQtWSFrame }

  TQtWSFrame = class(TWSFrame)
  private
  protected
  public
  end;

  { TQtWSCustomForm }

  TQtWSCustomForm = class(TWSCustomForm)
  private
    class procedure SetSlots(const QtCustomForm: TQtCustomForm);
  protected
  public
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;

{    class procedure SetFormBorderStyle(const AForm: TCustomForm;
                             const AFormBorderStyle: TFormBorderStyle); override;
    class procedure SetIcon(const AForm: TCustomForm; const AIcon: HICON); override;
    class procedure SetShowInTaskbar(const AForm: TCustomForm; const AValue: TShowInTaskbar); override;
    class procedure ShowModal(const ACustomForm: TCustomForm); override;
    class procedure SetBorderIcons(const AForm: TCustomForm;
                                   const ABorderIcons: TBorderIcons); override;}
  end;

  { TQtWSForm }

  TQtWSForm = class(TWSForm)
  private
  protected
  public
  end;

  { TQtWSHintWindow }

  TQtWSHintWindow = class(TWSHintWindow)
  private
  protected
  public
  end;

  { TQtWSScreen }

  TQtWSScreen = class(TWSScreen)
  private
  protected
  public
  end;

  { TQtWSApplicationProperties }

  TQtWSApplicationProperties = class(TWSApplicationProperties)
  private
  protected
  public
  end;


implementation

uses QtWSControls;

{ TQtWSCustomForm }

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.SetSlots
  Params:  None
  Returns: Nothing

  Initializes the events
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomForm.SetSlots(const QtCustomForm: TQtCustomForm);
var
  Method: TMethod;
  Hook : QObject_hookH;
begin
  // Various Events

  Hook := QObject_hook_create(QtCustomForm.Widget); // PaintBox
  
  TEventFilterMethod(Method) := QtCustomForm.EventFilter;
  
  QObject_hook_hook_events(Hook, Method);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.CreateHandle
  Params:  None
  Returns: Nothing

  Creates a Qt Form and initializes it according to it�s properties
 ------------------------------------------------------------------------------}
class function TQtWSCustomForm.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  QtCustomForm: TQtCustomForm;
begin
  QtCustomForm := TQtCustomForm.Create(AWinControl, AParams);

  SetSlots(QtCustomForm);

  // Required to implement OnPaint event
  QMainWindow_setCentralWidget(QMainWindowH(QtCustomForm.Widget), QtCustomForm.PaintBox);

  // Accepts keyboard and mouse events
  QWidget_setFocusPolicy(QtCustomForm.Widget, QtStrongFocus);

  Result := THandle(QtCustomForm);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.DestroyHandle
  Params:  None
  Returns: Nothing

  Destroys a Qt Form and releases allocated memory and resources
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomForm.DestroyHandle(const AWinControl: TWinControl);
begin
  TQtCustomForm(AWinControl.Handle).Free;
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TScrollingWinControl, TQtWSScrollingWinControl);
//  RegisterWSComponent(TScrollBox, TQtWSScrollBox);
//  RegisterWSComponent(TCustomFrame, TQtWSCustomFrame);
//  RegisterWSComponent(TFrame, TQtWSFrame);
  RegisterWSComponent(TCustomForm, TQtWSCustomForm);
//  RegisterWSComponent(TForm, TQtWSForm);
//  RegisterWSComponent(THintWindow, TQtWSHintWindow);
//  RegisterWSComponent(TScreen, TQtWSScreen);
//  RegisterWSComponent(TApplicationProperties, TQtWSApplicationProperties);
////////////////////////////////////////////////////
end.
