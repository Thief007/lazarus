{ $Id$}
{
 *****************************************************************************
 *                              Win32WSForms.pp                              * 
 *                              ---------------                              * 
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
unit Win32WSForms;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Forms, Controls, LCLType, Classes,
////////////////////////////////////////////////////
  WSForms, WSLCLClasses, Windows, SysUtils, WinExt, 
  Win32Int, Win32Proc, Win32WSControls;

type

  { TWin32WSScrollingWinControl }

  TWin32WSScrollingWinControl = class(TWSScrollingWinControl)
  private
  protected
  public
  end;

  { TWin32WSScrollBox }

  TWin32WSScrollBox = class(TWSScrollBox)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
  end;

  { TWin32WSCustomFrame }

  TWin32WSCustomFrame = class(TWSCustomFrame)
  private
  protected
  public
  end;

  { TWin32WSFrame }

  TWin32WSFrame = class(TWSFrame)
  private
  protected
  public
  end;

  { TWin32WSCustomForm }

  TWin32WSCustomForm = class(TWSCustomForm)
  private
  protected
  public
    class procedure SetBorderIcons(const AForm: TCustomForm;
          const ABorderIcons: TBorderIcons); override;
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure SetIcon(const AForm: TCustomForm; const AIcon: HICON); override;
    class procedure ShowModal(const ACustomForm: TCustomForm); override;
  end;

  { TWin32WSForm }

  TWin32WSForm = class(TWSForm)
  private
  protected
  public
  end;

  { TWin32WSHintWindow }

  TWin32WSHintWindow = class(TWSHintWindow)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
  end;

  { TWin32WSScreen }

  TWin32WSScreen = class(TWSScreen)
  private
  protected
  public
  end;

  { TWin32WSApplicationProperties }

  TWin32WSApplicationProperties = class(TWSApplicationProperties)
  private
  protected
  public
  end;


implementation

{-----------------------------------------------------------------------------
  Function: DisableWindowsProc
  Params: Window - handle of toplevel windows to be disabled
          Data   - handle of current window form
  Returns: Whether the enumeration should continue

  Used in LM_SHOWMODAL to disable the windows of application thread
  except the current form.
 -----------------------------------------------------------------------------}
function DisableWindowsProc(Window: HWND; Data: LParam): LongBool; stdcall;
var
  Buffer: array[0..15] of Char;
begin
  Result:=true;
  // Don't disable the current window form
  if Window=HWND(Data) then exit;

  // Don't disable any ComboBox listboxes
  if (GetClassName(Window, @Buffer, sizeof(Buffer))<sizeof(Buffer))
    and (StrIComp(Buffer, 'ComboLBox')=0) then exit;

  EnableWindow(Window,False);
end;

{ TWin32WSScrollBox }

function TWin32WSScrollBox.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    //TODO: Make control respond to user scroll request
    FlagsEx := FlagsEx or WS_EX_CLIENTEDGE;
    pClassName := @ClsName;
    Flags := Flags or WS_HSCROLL or WS_VSCROLL;
    SubClassWndProc := nil;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;
end;



{ TWin32WSCustomForm }

function CalcBorderIconsFlags(const AForm: TCustomForm): dword;
var
  BorderIcons: TBorderIcons;
begin
  Result := 0;
  if not (AForm.BorderStyle in [bsNone, bsDialog, bsToolWindow]) then
  begin
    BorderIcons := AForm.BorderIcons;
    if biSystemMenu in BorderIcons then
    begin
      Result := Result or WS_SYSMENU;
      if biMinimize in BorderIcons then
        Result := Result or WS_MINIMIZEBOX;
      if biMaximize in BorderIcons then
        Result := Result or WS_MAXIMIZEBOX;
    end;
  end;
end;

function TWin32WSCustomForm.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
  lForm: TCustomForm;
  BorderStyle: TFormBorderStyle;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    lForm := TCustomForm(AWinControl);
    BorderStyle := lForm.BorderStyle;
    Flags := BorderStyleToWin32Flags(BorderStyle);
    FlagsEx := BorderStyleToWin32FlagsEx(BorderStyle);
    if (lForm.FormStyle in fsAllStayOnTop) and 
        (not (csDesigning in lForm.ComponentState)) then
      FlagsEx := FlagsEx or WS_EX_TOPMOST;
    Flags := Flags or CalcBorderIconsFlags(lForm);
    pClassName := @ClsName;
    WindowTitle := StrCaption;
    Left := LongInt(CW_USEDEFAULT);
    Top := LongInt(CW_USEDEFAULT);
    Width := LongInt(CW_USEDEFAULT);
    Height := LongInt(CW_USEDEFAULT);
    SubClassWndProc := nil;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;
end;

procedure TWin32WSCustomForm.SetBorderIcons(const AForm: TCustomForm;
          const ABorderIcons: TBorderIcons);
begin
  UpdateWindowStyle(AForm.Handle, CalcBorderIconsFlags(AForm), 
    WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX);
end;

procedure TWin32WSCustomForm.SetIcon(const AForm: TCustomForm; const AIcon: HICON);
begin
  SendMessage(AForm.Handle, WM_SETICON, ICON_BIG, AIcon);
end;

procedure TWin32WSCustomForm.ShowModal(const ACustomForm: TCustomForm);
var
  FormHandle: HWND;
begin
  FormHandle := ACustomForm.Handle;
  EnumThreadWindows(GetWindowThreadProcessId(FormHandle, nil), @DisableWindowsProc, FormHandle);
  ShowWindow(FormHandle, SW_SHOW);
end;

{ TWin32WSHintWindow }

function TWin32WSHintWindow.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    pClassName := @ClsName;
    WindowTitle := StrCaption;
    Flags := WS_POPUP;
    FlagsEx := FlagsEx or WS_EX_TOOLWINDOW;
    Left := LongInt(CW_USEDEFAULT);
    Top := LongInt(CW_USEDEFAULT);
    Width := LongInt(CW_USEDEFAULT);
    Height := LongInt(CW_USEDEFAULT);
    SubClassWndProc := nil;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TScrollingWinControl, TWin32WSScrollingWinControl);
  RegisterWSComponent(TScrollBox, TWin32WSScrollBox);
//  RegisterWSComponent(TCustomFrame, TWin32WSCustomFrame);
//  RegisterWSComponent(TFrame, TWin32WSFrame);
  RegisterWSComponent(TCustomForm, TWin32WSCustomForm);
//  RegisterWSComponent(TForm, TWin32WSForm);
  RegisterWSComponent(THintWindow, TWin32WSHintWindow);
//  RegisterWSComponent(TScreen, TWin32WSScreen);
//  RegisterWSComponent(TApplicationProperties, TWin32WSApplicationProperties);
////////////////////////////////////////////////////
end.
