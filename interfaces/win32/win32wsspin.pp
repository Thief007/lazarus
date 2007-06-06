{ $Id$}
{
 *****************************************************************************
 *                              Win32WSSpin.pp                               * 
 *                              --------------                               * 
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
unit Win32WSSpin;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Spin, Controls, StdCtrls, LCLType,
////////////////////////////////////////////////////
  WSSpin, WSLCLClasses, Windows, Win32Int, Win32Extra, Win32Proc,
  Win32WSStdCtrls, Win32WSControls;
  
type

  { TWin32WSCustomFloatSpinEdit }

  TWin32WSCustomFloatSpinEdit = class(TWSCustomFloatSpinEdit)
  private
  protected
  public
    class procedure AdaptBounds(const AWinControl: TWinControl;
          var Left, Top, Width, Height: integer; var SuppressMove: boolean); override;
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class function  GetSelStart(const ACustomEdit: TCustomEdit): integer; override;
    class function  GetSelLength(const ACustomEdit: TCustomEdit): integer; override;
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class function  GetValue(const ACustomFloatSpinEdit: TCustomFloatSpinEdit): single; override;

    class procedure SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer); override;
    class procedure SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;

    class procedure UpdateControl(const ACustomFloatSpinEdit: TCustomFloatSpinEdit); override;
  end;

  { TWin32WSFloatSpinEdit }

  TWin32WSFloatSpinEdit = class(TWSFloatSpinEdit)
  private
  protected
  public
  end;


procedure UpdateFloatSpinEditText(const ASpinHandle: HWND; const ANewValue: single;
  const ADecimalPlaces: integer);

implementation

uses
  SysUtils;

{ TWin32WSCustomFloatSpinEdit }

function GetBuddyWindow(AHandle: HWND): HWND;
begin
  Result := SendMessage(AHandle, UDM_GETBUDDY, 0, 0)
end;

function SpinWindowProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
    LParam: Windows.LParam): LResult; stdcall;
begin
  if Msg = WM_SETFOCUS then
    Window := GetBuddyWindow(Window);
  Result := WindowProc(Window, Msg, WParam, LParam);
end;

procedure UpdateFloatSpinEditControl(const Handle: HWND;
  const AFloatSpinEdit: TCustomFloatSpinEdit);
var
  lWindowInfo: PWindowInfo;
begin
  lWindowInfo := GetWindowInfo(Handle);
  if lWindowInfo <> @DefaultWindowInfo then
  begin
    lWindowInfo^.spinValue := AFloatSpinEdit.Value;
    UpdateFloatSpinEditText(Handle, AFloatSpinEdit.Value, AFloatSpinEdit.DecimalPlaces);
  end;
end;

procedure UpdateFloatSpinEditText(const ASpinHandle: HWND; const ANewValue: single;
  const ADecimalPlaces: integer);
var
  editHandle: HWND;
  newValueText: string;
begin
  editHandle := GetBuddyWindow(ASpinHandle);
  newValueText := FloatToStrF(ANewValue, ffFixed, 20, ADecimalPlaces);
  Windows.SendMessage(editHandle, WM_SETTEXT, 0, Windows.LPARAM(PChar(newValueText)));
end;
  
class function TWin32WSCustomFloatSpinEdit.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    SubClassWndProc := @SpinWindowProc;
    Buddy := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', StrCaption, Flags Or ES_AUTOHSCROLL, Left, Top, Width, Height, Parent, HMENU(Nil), HInstance, Nil);
    Window := CreateUpDownControl(Flags or DWORD(WS_BORDER or UDS_ALIGNRIGHT or UDS_ARROWKEYS),
      0, 0,       // pos -  ignored for buddy
      0, 0,       // size - ignored for buddy
      Parent, 0, HInstance, Buddy,
      1000, 0, 500);
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, true);
  UpdateFloatSpinEditControl(Params.Window, TCustomFloatSpinEdit(AWinControl));
  // init buddy
  Params.SubClassWndProc := @WindowProc;
  WindowCreateInitBuddy(AWinControl, Params);
  Params.BuddyWindowInfo^.isChildEdit := true;
  // make possible LCL Wincontrol identification by Buddy handle
  // TODO: should move to widget specific SetProp method
  SetProp(Params.Buddy, 'WinControl', PtrUInt(AWinControl));
  Result := Params.Window;
end;

class procedure TWin32WSCustomFloatSpinEdit.AdaptBounds(const AWinControl: TWinControl;
  var Left, Top, Width, Height: integer; var SuppressMove: boolean);
var
  WinHandle, BuddyHandle: HWND;
begin
  WinHandle := AWinControl.Handle;
  // detach from buddy first
  BuddyHandle := Windows.SendMessage(WinHandle, UDM_SETBUDDY, 0, 0);
  MoveWindow(BuddyHandle, Left, Top, Width, Height, True);
  // reattach
  Windows.SendMessage(WinHandle, UDM_SETBUDDY, BuddyHandle, 0);
  SuppressMove := true;
end;

class function TWin32WSCustomFloatSpinEdit.GetSelStart(const ACustomEdit: TCustomEdit): integer;
begin
  Result := EditGetSelStart(GetBuddyWindow(ACustomEdit.Handle));
end;

class function TWin32WSCustomFloatSpinEdit.GetSelLength(const ACustomEdit: TCustomEdit): integer;
begin
  Result := EditGetSelLength(GetBuddyWindow(ACustomEdit.Handle));
end;

class function TWin32WSCustomFloatSpinEdit.GetText(const AWinControl: TWinControl;
  var AText: string): boolean;
begin
  Result := AWinControl.HandleAllocated;
  if not Result then
    exit;
  AText := GetControlText(GetBuddyWindow(AWinControl.Handle));
end;

class function TWin32WSCustomFloatSpinEdit.GetValue(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit): single;
begin
  Result := GetWindowInfo(ACustomFloatSpinEdit.Handle)^.spinValue;
end;

class procedure TWin32WSCustomFloatSpinEdit.SetSelStart(const ACustomEdit: TCustomEdit;
  NewStart: integer);
begin
  EditSetSelStart(GetBuddyWindow(ACustomEdit.Handle), NewStart);
end;

class procedure TWin32WSCustomFloatSpinEdit.SetSelLength(const ACustomEdit: TCustomEdit;
  NewLength: integer);
begin
  EditSetSelLength(GetBuddyWindow(ACustomEdit.Handle), NewLength);
end;

class procedure TWin32WSCustomFloatSpinEdit.ShowHide(const AWinControl: TWinControl);
var
  Buddy: HWND;
begin
  // call inherited
  TWin32WSWinControl.ShowHide(AWinControl);
  Buddy := GetBuddyWindow(AWinControl.Handle);
  if AWinControl.HandleObjectShouldBeVisible then
    ShowWindow(Buddy, SW_SHOW)
  else
    ShowWindow(Buddy, SW_HIDE);
end;

class procedure TWin32WSCustomFloatSpinEdit.UpdateControl(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit);
begin
  UpdateFloatSpinEditControl(ACustomFloatSpinEdit.Handle, ACustomFloatSpinEdit);
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCustomFloatSpinEdit, TWin32WSCustomFloatSpinEdit);
//  RegisterWSComponent(TFloatSpinEdit, TWin32WSFloatSpinEdit);
////////////////////////////////////////////////////
end.
