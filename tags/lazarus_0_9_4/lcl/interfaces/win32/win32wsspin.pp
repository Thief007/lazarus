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
 *  See the file COPYING.LCL, included in this distribution,                 *
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
  Spin, Controls, LCLType,
////////////////////////////////////////////////////
  WSSpin, WSLCLClasses, Windows, Win32Int, WinExt,
  Win32WSStdCtrls, Win32WSControls;
  
type

  { TWin32WSCustomSpinEdit }

  TWin32WSCustomSpinEdit = class(TWSCustomSpinEdit)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class function  GetSelStart(const ACustomSpinEdit: TCustomSpinEdit): integer; override;
    class function  GetSelLength(const ACustomSpinEdit: TCustomSpinEdit): integer; override;
    class function  GetValue(const ACustomSpinEdit: TCustomSpinEdit): single; override;

    class procedure SetSelStart(const ACustomSpinEdit: TCustomSpinEdit; NewStart: integer); override;
    class procedure SetSelLength(const ACustomSpinEdit: TCustomSpinEdit; NewLength: integer); override;
  
    class procedure UpdateControl(const ACustomSpinEdit: TCustomSpinEdit); override;
  end;

  { TWin32WSSpinEdit }

  TWin32WSSpinEdit = class(TWSSpinEdit)
  private
  protected
  public
  end;


implementation

{ TWin32WSCustomSpinEdit }

function TWin32WSCustomSpinEdit.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    //this needs to be created in the actual code because it requires a gtkadjustment Win32Control
    Buddy := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', StrCaption, Flags Or ES_AUTOHSCROLL, Left, Top, Width, Height, Parent, HMENU(Nil), HInstance, Nil);
    Window := CreateUpDownControl(Flags or DWORD(WS_BORDER or UDS_ALIGNRIGHT or UDS_NOTHOUSANDS or UDS_ARROWKEYS or UDS_WRAP or UDS_SETBUDDYINT),
      0, 0,       // pos -  ignored for buddy
      0, 0,       // size - ignored for buddy
      Parent, 0, HInstance, Buddy,
      Trunc(TSpinEdit(AWinControl).MaxValue),
      Trunc(TSpinEdit(AWinControl).MinValue),
      Trunc(TSpinEdit(AWinControl).Value));
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, true);
  // init buddy
  Params.SubClassWndProc := @ChildEditWindowProc;
  WindowCreateInitBuddy(AWinControl, Params);
  Result := Params.Window;
end;

function  TWin32WSCustomSpinEdit.GetSelStart(const ACustomSpinEdit: TCustomSpinEdit): integer;
begin
  Result := EditGetSelStart(SendMessage(ACustomSpinEdit.Handle, UDM_GETBUDDY, 0, 0));
end;

function  TWin32WSCustomSpinEdit.GetSelLength(const ACustomSpinEdit: TCustomSpinEdit): integer;
begin
  Result := EditGetSelLength(SendMessage(ACustomSpinEdit.Handle, UDM_GETBUDDY, 0, 0));
end;

function  TWin32WSCustomSpinEdit.GetValue(const ACustomSpinEdit: TCustomSpinEdit): single;
begin
  Result := SendMessage(ACustomSpinEdit.Handle, UDM_GETPOS32, 0, 0);
end;

procedure TWin32WSCustomSpinEdit.SetSelStart(const ACustomSpinEdit: TCustomSpinEdit; NewStart: integer);
begin
  EditSetSelStart(SendMessage(ACustomSpinEdit.Handle, UDM_GETBUDDY, 0, 0), NewStart); 
end;

procedure TWin32WSCustomSpinEdit.SetSelLength(const ACustomSpinEdit: TCustomSpinEdit; NewLength: integer);
begin
  EditSetSelLength(SendMessage(ACustomSpinEdit.Handle, UDM_GETBUDDY, 0, 0), NewLength); 
end;

procedure TWin32WSCustomSpinEdit.UpdateControl(const ACustomSpinEdit: TCustomSpinEdit);
var
  Handle: HWND;
begin
  Handle := ACustomSpinEdit.Handle;
  SendMessage(Handle, UDM_SETRANGE32, WParam(Trunc(ACustomSpinEdit.MaxValue)),
    LParam(Trunc(ACustomSpinEdit.MinValue)));
  SendMessage(Handle, UDM_SETPOS32, 0, LParam(Trunc(ACustomSpinEdit.Value)));
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCustomSpinEdit, TWin32WSCustomSpinEdit);
//  RegisterWSComponent(TSpinEdit, TWin32WSSpinEdit);
////////////////////////////////////////////////////
end.
