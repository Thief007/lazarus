{ $Id$}
{
 *****************************************************************************
 *                            Win32WSControls.pp                             * 
 *                            ------------------                             * 
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
unit Win32WSControls;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Controls, Graphics,
////////////////////////////////////////////////////
  WSControls, WSLCLClasses, SysUtils, Win32Proc,
  { TODO: needs to move }
  Forms, ComCtrls, Buttons, StdCtrls, ExtCtrls, GraphMath, GraphType, InterfaceBase, LCLIntf, LCLType;

type

  { TWin32WSDragImageList }

  TWin32WSDragImageList = class(TWSDragImageList)
  private
  protected
  public
  end;

  { TWin32WSControl }

  TWin32WSControl = class(TWSControl)
  private
  protected
  public
    class procedure SetCursor(const AControl: TControl; const ACursor: TCursor); override;
  end;

  { TWin32WSWinControl }

  TWin32WSWinControl = class(TWSWinControl)
  private
  protected
  public
    class procedure AddControl(const AControl: TControl); override;
  
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); override;
    class procedure SetColor(const AWinControl: TWinControl); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: string); override;

    class procedure ConstraintsChange(const AWinControl: TWinControl); override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class procedure Invalidate(const AWinControl: TWinControl); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
  end;

  { TWin32WSGraphicControl }

  TWin32WSGraphicControl = class(TWSGraphicControl)
  private
  protected
  public
  end;

  { TWin32WSCustomControl }

  TWin32WSCustomControl = class(TWSCustomControl)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
  end;

  { TWin32WSImageList }

  TWin32WSImageList = class(TWSImageList)
  private
  protected
  public
  end;

  
type
  TCreateWindowExParams = record
    Buddy, Parent, Window: HWND;
    Left, Top, Height, Width: integer;
    WindowInfo, BuddyWindowInfo: PWindowInfo;
    MenuHandle: HMENU;
    Flags, FlagsEx: dword;
    SubClassWndProc: pointer;
    WindowTitle, StrCaption: PChar;
    pClassName: PChar;
  end;


// TODO: better names?

procedure PrepareCreateWindow(const AWinControl: TWinControl; var Params: TCreateWindowExParams);
procedure FinishCreateWindow(const AWinControl: TWinControl; var Params: TCreateWindowExParams;
  const AlternateCreateWindow: boolean);
procedure WindowCreateInitBuddy(const AWinControl: TWinControl; 
  var Params: TCreateWindowExParams);

implementation

uses
  Windows, Win32Int, Win32WSButtons;

{ Global helper routines }

procedure PrepareCreateWindow(const AWinControl: TWinControl; var Params: TCreateWindowExParams);
begin
  with Params do
  begin
    Flags := WS_CHILD or WS_CLIPSIBLINGS or WS_CLIPCHILDREN;
    FlagsEx := 0;
    Assert(False, 'Trace:Setting flags');
    Window := HWND(Nil);
    Buddy := HWND(Nil);
    Assert(False, 'Trace:Setting window');

    if AWinControl.Parent <> nil then
    begin
      Parent := AWinControl.Parent.Handle;
    end else
      Parent := TWin32WidgetSet(InterfaceObject).AppHandle;

    SubClassWndProc := @WindowProc;
    WindowTitle := nil;
    StrCaption := PChar(AWinControl.Caption);
    WindowTitle := nil;
    Height := AWinControl.Height;
    Left := AWinControl.Left;
    //Parent := AWinControl.Parent;
    Top := AWinControl.Top;
    Width := AWinControl.Width;
    if AWinControl.Visible then
      Flags := Flags or WS_VISIBLE;
    if csAcceptsControls in AWinControl.ControlStyle then
      FlagsEx := FlagsEx or WS_EX_CONTROLPARENT;
    if AWinControl.TabStop then
      Flags := Flags or WS_TABSTOP;
    Assert(False, 'Trace:Setting dimentions');
    LCLBoundsToWin32Bounds(AWinControl, Left, Top, Width, Height);
    if AWinControl is TCustomControl then
      if TCustomControl(AWinControl).BorderStyle = bsSingle then
        FlagsEx := FlagsEx or WS_EX_CLIENTEDGE;
    {$IFDEF VerboseSizeMsg}
    writeln('TWin32WidgetSet.CreateComponent A ',AWinControl.Name,':',AWinControl.ClassName,' ',Left,',',Top,',',Width,',',Height);
    {$ENDIF}

    Assert(False, Format('Trace:TWin32WidgetSet.CreateComponent - Creating component %S with the caption of %S', [AWinControl.ClassName, AWinControl.Caption]));
    Assert(False, Format('Trace:TWin32WidgetSet.CreateComponent - Left: %D, Top: %D, Width: %D, Height: %D, Parent handle: 0x%X, instance handle: 0x%X', [Left, Top, Width, Height, Parent, HInstance]));
  end;
end;

procedure FinishCreateWindow(const AWinControl: TWinControl; var Params: TCreateWindowExParams;
  const AlternateCreateWindow: boolean);
begin
  if not AlternateCreateWindow then
  begin
    with Params do
    begin
      if (Flags and WS_CHILD) <> 0 then
      begin
        // menu handle is also for specifying a control id if this is a child
        MenuHandle := HMENU(AWinControl);
      end else begin
        MenuHandle := HMENU(nil);
      end;
      Window := CreateWindowEx(FlagsEx, pClassName, WindowTitle, Flags,
          Left, Top, Width, Height, Parent, MenuHandle, HInstance, Nil);  
      if Window = 0 then
      begin
        raise exception.create('failed to create win32 control, error: '+IntToStr(GetLastError()));
      end;
    end;
    { after creating a child window the following happens:
      1) the previously bottom window is thrown to the top
      2) the created window is added at the bottom
      undo this by throwing them both to the bottom again }
    { not needed anymore, tab order is handled entirely by LCL now
    Windows.SetWindowPos(Windows.GetTopWindow(Parent), HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
    Windows.SetWindowPos(Window, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
    }
  end;
  
  with Params do
  begin
    if Window <> HWND(Nil) then
    begin
      // some controls (combobox) immediately send a message upon setting font
      WindowInfo := AllocWindowInfo(Window);
      if GetWindowInfo(Parent)^.hasTabParent then
        WindowInfo^.hasTabParent := true;
      WindowInfo^.WinControl := AWinControl;
      AWinControl.Handle := Window;
      if SubClassWndProc <> nil then
        WindowInfo^.DefWndProc := Windows.WNDPROC(Windows.SetWindowLong(
          Window, GWL_WNDPROC, LongInt(SubClassWndProc)));
      Windows.SendMessage(Window, WM_SETFONT, 
        WParam(TWin32WidgetSet(InterfaceObject).MessageFont), 0);
    end;
  end;
end;

procedure WindowCreateInitBuddy(const AWinControl: TWinControl; 
  var Params: TCreateWindowExParams);
begin
  with Params do
    if Buddy <> HWND(Nil) then
    begin
      BuddyWindowInfo := AllocWindowInfo(Buddy);
      BuddyWindowInfo^.AWinControl := AWinControl;
      BuddyWindowInfo^.DefWndProc := Windows.WNDPROC(Windows.SetWindowLong(
        Buddy, GWL_WNDPROC, LongInt(SubClassWndProc)));
      Windows.SendMessage(Buddy, WM_SETFONT, 
        WParam(TWin32WidgetSet(InterfaceObject).MessageFont), 0);
    end;
end;

{ TWin32WSControl }

procedure TWin32WSControl.SetCursor(const AControl: TControl; const ACursor: TCursor);
begin
  Windows.SetCursor(Windows.LoadCursor(0, LclCursorToWin32CursorMap[ACursor]));
end;

{ TWin32WSWinControl }

procedure TWin32WSWinControl.AddControl(const AControl: TControl);
var
  ParentPanelHandle, ParentHandle, ChildHandle: HWND;
begin
  {$ifdef OldToolbar}
  if (AControl.Parent is TToolbar) then
    exit;
  {$endif}

  with TWinControl(AControl) do
  begin
    Assert(False, Format('Trace:[TWin32WSWinControl.AddControl] %S --> Calling Add Child: %S', [Parent.ClassName, ClassName]));
    ParentHandle := Parent.Handle;
    ChildHandle := Handle;
  end;

  Assert(False, 'Trace:AddControl - Parent Window Handle is $' + IntToHex(LongInt(ParentHandle), 8));
  Assert(False, 'Trace:AddControl - Child Window Handle is $' + IntToHex(LongInt(ChildHandle), 8));
  // handle groupbox exception
  ParentPanelHandle := GetWindowInfo(ChildHandle)^.ParentPanel;
  if ParentPanelHandle <> 0 then
    ChildHandle := ParentPanelHandle;
  SetParent(ChildHandle, ParentHandle);
end;

function  TWin32WSWinControl.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
var
  CapLen: Cardinal;
  Caption: PChar;
  Handle: HWND;
begin
  Result := AWinControl.HandleAllocated;
  if not Result then
    exit;
  AText := '';
  Handle := AWinControl.Handle;
  case AWinControl.FCompStyle of
    csComboBox:
    begin
      // + 1 = terminating null character
      CapLen := Windows.SendMessage(Handle, WM_GETTEXTLENGTH, 0, 0) + 1;
      Caption := StrAlloc(CapLen);
      Windows.SendMessage(Handle, WM_GETTEXT, CapLen, LPARAM(Caption));
      AText := StrPas(Caption);
      StrDispose(Caption);
    end;
    csEdit, csMemo:
    begin
      CapLen := GetWindowTextLength(Handle);
      Caption := StrAlloc(CapLen + 1);
      GetWindowText(Handle, Caption, CapLen + 1);
      AText := StrPas(Caption);
      StrDispose(Caption);
    end;
    else
      Result := false;
  end;
end;

procedure TWin32WSWinControl.SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
begin
  TWin32WidgetSet(InterfaceObject).RecreateWnd(AWinControl);
end;

procedure TWin32WSWinControl.SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer);
var
  SizeRect: Windows.RECT;
begin
  with SizeRect do
  begin
    Left := ALeft;
    Top := ATop;
    Right := ALeft + AWidth;
    Bottom := ATop + AHeight;
  end;
  case AWinControl.FCompStyle of
    csForm:
    begin
      // the LCL defines the size of a form without border, win32 with.
      // -> adjust size according to BorderStyle
      Windows.AdjustWindowRectEx(@SizeRect, BorderStyleToWin32Flags(TCustomForm(AWinControl).BorderStyle), false,
          BorderStyleToWin32FlagsEx(TCustomForm(AWinControl).BorderStyle));
    end;
  end;
  TWin32WidgetSet(InterfaceObject).ResizeChild(AWinControl, ALeft, ATop,
     SizeRect.Right - SizeRect.Left, SizeRect.Bottom - SizeRect.Top);
end;

procedure TWin32WSWinControl.SetColor(const AWinControl: TWinControl);
begin
  // TODO: to be implemented, had no implementation in LM_SETCOLOR message
end;

procedure TWin32WSWinControl.SetFont(const AWinControl: TWinControl; const AFont: TFont);
begin
  Windows.SendMessage(AWinControl.Handle, WM_SETFONT, Windows.WParam(AFont.Handle), 1);
end;

procedure TWin32WSWinControl.SetText(const AWinControl: TWinControl; const AText: string);
Var
  Handle: HWnd;
{  TCI: TC_ITEM; }
  TempText: string;
Const
  TermChar: PChar = #0#0;
Begin
  Handle := AWinControl.Handle;
  Assert(Handle<>0,'Trace:WARNING: [TWin32WidgetSet.SetLabel] --> Got NULL handle');
  Assert(False, 'Trace:Setting the label in TWin32WidgetSet.SetLabel');

  Case AWinControl.FCompStyle Of
    csBitBtn:
      DrawBitBtnImage(TCustomBitBtn(AWinControl), PChar(AText));
      
      
{ TODO: CHECK !! Code was never reached in SetLabel ? }
{
    csFileDialog, csOpenFileDialog, csSaveFileDialog, csSelectDirectoryDialog,
    csColorDialog, csFontDialog:
    Begin
      Assert(False, Format('Trace:TWin32WidgetSet.SetLabel - Got %S', [CS_To_String(AWinControl.FCompStyle)]));
      Assert(False, 'Trace:TWin32WidgetSet.SetLabel - I''m not sure if this''ll work');
      Assert(False, Format('Trace:Is Sender a TCommonDialog - %S', [BOOL_RESULT[AWinControl Is TCommonDialog]]));
      If AWinControl Is TCommonDialog Then
        TCommonDialog(AWinControl).Title := AText 
      Else
        AWinControl.Caption := AText;
      Assert(False, Format('Trace:TWin32WidgetSet.SetLabel - Leaving %S', [CS_To_String(AWinControl.FCompStyle)]));
    End;
}
  
    csComboBox:
    Begin
      Assert(False, Format('Trace:TWin32WidgetSet.SetLabel - Got %S', [CS_To_String(AWinControl.FCompStyle)]));
      Assert(False, Format('Trace:TWin32WidgetSet.SetLabel - label --> %S', [AText]));
      if TCustomComboBox(AWinControl).Style = csDropDownList then
        Windows.SendMessage(Handle, CB_SELECTSTRING, -1, LPARAM(PChar(AText)))
      else
        Windows.SendMessage(Handle, WM_SETTEXT, 0, LPARAM(PChar(AText)));
    End;
    csMemo:
    Begin
      SendMessage(Handle, WM_SETTEXT, 0, LPARAM(PChar(AText)));
    End;
  {
    csNotebook:
    Begin
      Assert(False, 'Trace: TWin32WidgetSet.SetLabel - Got csNotebook');
      with TLMNotebookEvent(Data^) do
      if Parent=Sender then
      begin
        TCI.mask := TCIF_TEXT;
        Assert(False, Format('Trace:TWin32WidgetSet.SetLabel - label --> %S', [Str]));
        TCI.pszText := PChar(Str);
        Windows.SendMessage(TCustomNotebook(Sender).Handle, TCM_SETITEM, Page, LPARAM(@TCI));
      end
    End;
  }
    csToolButton:
    Begin
      TempText := AText + TermChar;
      SendMessage(AWinControl.Parent.Handle, TB_ADDSTRING, 0, LPARAM(PChar(TempText)));
    End;
  Else
    Windows.SetWindowText(Handle, PChar(AText));
  End;
  Assert(False, Format('Trace:[TWin32WidgetSet.SetLabel] %S --> END', [AWinControl.ClassName]));
End;

procedure TWin32WSWinControl.ConstraintsChange(const AWinControl: TWinControl);
begin
  // TODO: implement me!
end;

procedure TWin32WSWinControl.DestroyHandle(const AWinControl: TWinControl);
var
  Handle: HWND;
  AccelTable: HACCEL;
begin
  Handle := AWinControl.Handle;
  AccelTable := GetWindowInfo(Handle)^.Accel;
  if AccelTable <> 0 then
    DestroyAcceleratorTable(AccelTable);
  DestroyWindow(Handle);
end;

procedure TWin32WSWinControl.Invalidate(const AWinControl: TWinControl);
begin
  // lpRect = nil updates entire client area of window
  InvalidateRect(AWinControl.Handle, nil, true);
end;

procedure TWin32WSWinControl.ShowHide(const AWinControl: TWinControl);
begin
  // other methods also use ShowHide, can't move code
  TWin32WidgetSet(InterfaceObject).ShowHide(AWinControl);
end;

{ TWin32WSCustomControl }

function TWin32WSCustomControl.CreateHandle(const AWinControl: TWinControl;
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
//  RegisterWSComponent(TDragImageList, TWin32WSDragImageList);
  RegisterWSComponent(TControl, TWin32WSControl);
  RegisterWSComponent(TWinControl, TWin32WSWinControl);
//  RegisterWSComponent(TGraphicControl, TWin32WSGraphicControl);
  RegisterWSComponent(TCustomControl, TWin32WSCustomControl);
//  RegisterWSComponent(TImageList, TWin32WSImageList);
////////////////////////////////////////////////////
end.
