{
 /***************************************************************************
                         win32proc.pp  -  Misc Support Functions
                             -------------------



 ***************************************************************************/

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
unit win32proc;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, LMessages, LCLType, LCLProc, Controls;

Type
  TEventType = (etNotify, etKey, etKeyPress, etMouseWheel, etMouseUpDown);

function WM_To_String(WM_Message: Integer): string;
function WindowPosFlagsToString(Flags: UINT): string;
procedure EventTrace(Message: String; Data: TObject);
Procedure AssertEx(Const Message: String; Const PassErr: Boolean;
  Const Severity: Byte);
Procedure AssertEx(Const PassErr: Boolean; Const Message: String);
Procedure AssertEx(Const Message: String);
Function GetShiftState: TShiftState;
Function DeliverMessage(Const Target: Pointer; Var Message): Integer;
Function DeliverMessage(Const Target: TObject; Var Message: TLMessage): Integer;
Procedure CallEvent(Const Target: TObject; Event: TNotifyEvent;
  Const Data: Pointer; Const EventType: TEventType);
Function ObjectToHWND(Const AObject: TObject): HWND;
function LCLControlSizeNeedsUpdate(Sender: TWinControl;
  SendSizeMsgOnDiff: boolean): boolean;
Procedure SetAccelGroup(Const Control: HWND; Const AnAccelGroup: HACCEL);
Function GetAccelGroup(Const Control: HWND): HACCEL;
Procedure SetAccelKey(Window: HWND; Const CommandId: Word; Const AKey: word;
  Const AModifier: TShiftState);
Function GetAccelKey(Const Control: HWND): LPACCEL;
function GetLCLClientBoundsOffset(Sender: TObject; var ORect: TRect): boolean;
function GetLCLClientBoundsOffset(Handle: HWnd; var Rect: TRect): boolean;
Procedure LCLBoundsToWin32Bounds(Sender: TObject;
  var Left, Top, Width, Height: Integer);
Procedure Win32PosToLCLPos(Sender: TObject; var Left, Top: SmallInt);
procedure UpdateWindowStyle(Handle: HWnd; Style: integer; StyleMask: integer);
function BorderStyleToWin32Flags(Style: TFormBorderStyle): DWORD;
function BorderStyleToWin32FlagsEx(Style: TFormBorderStyle): DWORD;
function GetFileVersion(FileName: string): dword;

implementation

uses
  SysUtils, LCLStrConsts, Menus, Dialogs, StdCtrls, ExtCtrls,
  LCLIntf; //remove this unit when GetWindowSize is moved to TWSWinControl

{$IFOPT C-}
// Uncomment for local trace
//  {$C+}
//  {$DEFINE ASSERT_IS_ON}
{$ENDIF}

{------------------------------------------------------------------------------
  Function: WM_To_String
  Params: WM_Message - a WinDows message
  Returns: A WinDows-message name

  Converts a winDows message identIfier to a string
 ------------------------------------------------------------------------------}
function WM_To_String(WM_Message: Integer): string;
Begin
 Case WM_Message of
  $0000: Result := 'WM_NULL';
  $0001: Result := 'WM_CREATE';
  $0002: Result := 'WM_DESTROY';
  $0003: Result := 'WM_MOVE';
  $0005: Result := 'WM_SIZE';
  $0006: Result := 'WM_ACTIVATE';
  $0007: Result := 'WM_SETFOCUS';
  $0008: Result := 'WM_KILLFOCUS';
  $000A: Result := 'WM_ENABLE';
  $000B: Result := 'WM_SETREDRAW';
  $000C: Result := 'WM_SETTEXT';
  $000D: Result := 'WM_GETTEXT';
  $000E: Result := 'WM_GETTEXTLENGTH';
  $000F: Result := 'WM_PAINT';
  $0010: Result := 'WM_CLOSE';
  $0011: Result := 'WM_QUERYENDSESSION';
  $0012: Result := 'WM_QUIT';
  $0013: Result := 'WM_QUERYOPEN';
  $0014: Result := 'WM_ERASEBKGND';
  $0015: Result := 'WM_SYSCOLORCHANGE';
  $0016: Result := 'WM_EndSESSION';
  $0017: Result := 'WM_SYSTEMERROR';
  $0018: Result := 'WM_SHOWWINDOW';
  $0019: Result := 'WM_CTLCOLOR';
  $001A: Result := 'WM_WININICHANGE or WM_SETTINGCHANGE';
  $001B: Result := 'WM_DEVMODECHANGE';
  $001C: Result := 'WM_ACTIVATEAPP';
  $001D: Result := 'WM_FONTCHANGE';
  $001E: Result := 'WM_TIMECHANGE';
  $001F: Result := 'WM_CANCELMODE';
  $0020: Result := 'WM_SETCURSOR';
  $0021: Result := 'WM_MOUSEACTIVATE';
  $0022: Result := 'WM_CHILDACTIVATE';
  $0023: Result := 'WM_QUEUESYNC';
  $0024: Result := 'WM_GETMINMAXINFO';
  $0026: Result := 'WM_PAINTICON';
  $0027: Result := 'WM_ICONERASEBKGND';
  $0028: Result := 'WM_NEXTDLGCTL';
  $002A: Result := 'WM_SPOOLERSTATUS';
  $002B: Result := 'WM_DRAWITEM';
  $002C: Result := 'WM_MEASUREITEM';
  $002D: Result := 'WM_DELETEITEM';
  $002E: Result := 'WM_VKEYTOITEM';
  $002F: Result := 'WM_CHARTOITEM';
  $0030: Result := 'WM_SETFONT';
  $0031: Result := 'WM_GETFONT';
  $0032: Result := 'WM_SETHOTKEY';
  $0033: Result := 'WM_GETHOTKEY';
  $0037: Result := 'WM_QUERYDRAGICON';
  $0039: Result := 'WM_COMPAREITEM';
  $003D: Result := 'WM_GETOBJECT';
  $0041: Result := 'WM_COMPACTING';
  $0044: Result := 'WM_COMMNOTIFY { obsolete in Win32}';
  $0046: Result := 'WM_WINDOWPOSCHANGING';
  $0047: Result := 'WM_WINDOWPOSCHANGED';
  $0048: Result := 'WM_POWER';
  $004A: Result := 'WM_COPYDATA';
  $004B: Result := 'WM_CANCELJOURNAL';
  $004E: Result := 'WM_NOTIFY';
  $0050: Result := 'WM_INPUTLANGCHANGEREQUEST';
  $0051: Result := 'WM_INPUTLANGCHANGE';
  $0052: Result := 'WM_TCARD';
  $0053: Result := 'WM_HELP';
  $0054: Result := 'WM_USERCHANGED';
  $0055: Result := 'WM_NOTIFYFORMAT';
  $007B: Result := 'WM_CONTEXTMENU';
  $007C: Result := 'WM_STYLECHANGING';
  $007D: Result := 'WM_STYLECHANGED';
  $007E: Result := 'WM_DISPLAYCHANGE';
  $007F: Result := 'WM_GETICON';
  $0080: Result := 'WM_SETICON';
  $0081: Result := 'WM_NCCREATE';
  $0082: Result := 'WM_NCDESTROY';
  $0083: Result := 'WM_NCCALCSIZE';
  $0084: Result := 'WM_NCHITTEST';
  $0085: Result := 'WM_NCPAINT';
  $0086: Result := 'WM_NCACTIVATE';
  $0087: Result := 'WM_GETDLGCODE';
  $00A0: Result := 'WM_NCMOUSEMOVE';
  $00A1: Result := 'WM_NCLBUTTONDOWN';
  $00A2: Result := 'WM_NCLBUTTONUP';
  $00A3: Result := 'WM_NCLBUTTONDBLCLK';
  $00A4: Result := 'WM_NCRBUTTONDOWN';
  $00A5: Result := 'WM_NCRBUTTONUP';
  $00A6: Result := 'WM_NCRBUTTONDBLCLK';
  $00A7: Result := 'WM_NCMBUTTONDOWN';
  $00A8: Result := 'WM_NCMBUTTONUP';
  $00A9: Result := 'WM_NCMBUTTONDBLCLK';
  $0100: Result := 'WM_KEYFIRST or WM_KEYDOWN';
  $0101: Result := 'WM_KEYUP';
  $0102: Result := 'WM_CHAR';
  $0103: Result := 'WM_DEADCHAR';
  $0104: Result := 'WM_SYSKEYDOWN';
  $0105: Result := 'WM_SYSKEYUP';
  $0106: Result := 'WM_SYSCHAR';
  $0107: Result := 'WM_SYSDEADCHAR';
  $0108: Result := 'WM_KEYLAST';
  $010D: Result := 'WM_IME_STARTCOMPOSITION';
  $010E: Result := 'WM_IME_ENDCOMPOSITION';
  $010F: Result := 'WM_IME_COMPOSITION or WM_IME_KEYLAST';
  $0110: Result := 'WM_INITDIALOG';
  $0111: Result := 'WM_COMMAND';
  $0112: Result := 'WM_SYSCOMMAND';
  $0113: Result := 'WM_TIMER';
  $0114: Result := 'WM_HSCROLL';
  $0115: Result := 'WM_VSCROLL';
  $0116: Result := 'WM_INITMENU';
  $0117: Result := 'WM_INITMENUPOPUP';
  $011F: Result := 'WM_MENUSELECT';
  $0120: Result := 'WM_MENUCHAR';
  $0121: Result := 'WM_ENTERIDLE';
  $0122: Result := 'WM_MENURBUTTONUP';
  $0123: Result := 'WM_MENUDRAG';
  $0124: Result := 'WM_MENUGETOBJECT';
  $0125: Result := 'WM_UNINITMENUPOPUP';
  $0126: Result := 'WM_MENUCOMMAND';
  $0132: Result := 'WM_CTLCOLORMSGBOX';
  $0133: Result := 'WM_CTLCOLOREDIT';
  $0134: Result := 'WM_CTLCOLORLISTBOX';
  $0135: Result := 'WM_CTLCOLORBTN';
  $0136: Result := 'WM_CTLCOLORDLG';
  $0137: Result := 'WM_CTLCOLORSCROLLBAR';
  $0138: Result := 'WM_CTLCOLORSTATIC';
  $0200: Result := 'WM_MOUSEFIRST or WM_MOUSEMOVE';
  $0201: Result := 'WM_LBUTTONDOWN';
  $0202: Result := 'WM_LBUTTONUP';
  $0203: Result := 'WM_LBUTTONDBLCLK';
  $0204: Result := 'WM_RBUTTONDOWN';
  $0205: Result := 'WM_RBUTTONUP';
  $0206: Result := 'WM_RBUTTONDBLCLK';
  $0207: Result := 'WM_MBUTTONDOWN';
  $0208: Result := 'WM_MBUTTONUP';
  $0209: Result := 'WM_MBUTTONDBLCLK';
  $020A: Result := 'WM_MOUSEWHEEL or WM_MOUSELAST';
  $0210: Result := 'WM_PARENTNOTIFY';
  $0211: Result := 'WM_ENTERMENULOOP';
  $0212: Result := 'WM_EXITMENULOOP';
  $0213: Result := 'WM_NEXTMENU';
  $0214: Result := 'WM_SIZING';
  $0215: Result := 'WM_CAPTURECHANGED';
  $0216: Result := 'WM_MOVING';
  $0218: Result := 'WM_POWERBROADCAST';
  $0219: Result := 'WM_DEVICECHANGE';
  $0220: Result := 'WM_MDICREATE';
  $0221: Result := 'WM_MDIDESTROY';
  $0222: Result := 'WM_MDIACTIVATE';
  $0223: Result := 'WM_MDIRESTORE';
  $0224: Result := 'WM_MDINEXT';
  $0225: Result := 'WM_MDIMAXIMIZE';
  $0226: Result := 'WM_MDITILE';
  $0227: Result := 'WM_MDICASCADE';
  $0228: Result := 'WM_MDIICONARRANGE';
  $0229: Result := 'WM_MDIGETACTIVE';
  $0230: Result := 'WM_MDISETMENU';
  $0231: Result := 'WM_ENTERSIZEMOVE';
  $0232: Result := 'WM_EXITSIZEMOVE';
  $0233: Result := 'WM_DROPFILES';
  $0234: Result := 'WM_MDIREFRESHMENU';
  $0281: Result := 'WM_IME_SETCONTEXT';
  $0282: Result := 'WM_IME_NOTIFY';
  $0283: Result := 'WM_IME_CONTROL';
  $0284: Result := 'WM_IME_COMPOSITIONFULL';
  $0285: Result := 'WM_IME_SELECT';
  $0286: Result := 'WM_IME_CHAR';
  $0288: Result := 'WM_IME_REQUEST';
  $0290: Result := 'WM_IME_KEYDOWN';
  $0291: Result := 'WM_IME_KEYUP';
  $02A1: Result := 'WM_MOUSEHOVER';
  $02A3: Result := 'WM_MOUSELEAVE';
  $0300: Result := 'WM_CUT';
  $0301: Result := 'WM_COPY';
  $0302: Result := 'WM_PASTE';
  $0303: Result := 'WM_CLEAR';
  $0304: Result := 'WM_UNDO';
  $0305: Result := 'WM_RENDERFORMAT';
  $0306: Result := 'WM_RENDERALLFORMATS';
  $0307: Result := 'WM_DESTROYCLIPBOARD';
  $0308: Result := 'WM_DRAWCLIPBOARD';
  $0309: Result := 'WM_PAINTCLIPBOARD';
  $030A: Result := 'WM_VSCROLLCLIPBOARD';
  $030B: Result := 'WM_SIZECLIPBOARD';
  $030C: Result := 'WM_ASKCBFORMATNAME';
  $030D: Result := 'WM_CHANGECBCHAIN';
  $030E: Result := 'WM_HSCROLLCLIPBOARD';
  $030F: Result := 'WM_QUERYNEWPALETTE';
  $0310: Result := 'WM_PALETTEISCHANGING';
  $0311: Result := 'WM_PALETTECHANGED';
  $0312: Result := 'WM_HOTKEY';
  $0317: Result := 'WM_PRINT';
  $0318: Result := 'WM_PRINTCLIENT';
  $0358: Result := 'WM_HANDHELDFIRST';
  $035F: Result := 'WM_HANDHELDLAST';
  $0380: Result := 'WM_PENWINFIRST';
  $038F: Result := 'WM_PENWINLAST';
  $0390: Result := 'WM_COALESCE_FIRST';
  $039F: Result := 'WM_COALESCE_LAST';
  $03E0: Result := 'WM_DDE_FIRST or WM_DDE_INITIATE';
  $03E1: Result := 'WM_DDE_TERMINATE';
  $03E2: Result := 'WM_DDE_ADVISE';
  $03E3: Result := 'WM_DDE_UNADVISE';
  $03E4: Result := 'WM_DDE_ACK';
  $03E5: Result := 'WM_DDE_DATA';
  $03E6: Result := 'WM_DDE_REQUEST';
  $03E7: Result := 'WM_DDE_POKE';
  $03E8: Result := 'WM_DDE_EXECUTE or WM_DDE_LAST';
  $0400: Result := 'WM_USER';
  $8000: Result := 'WM_APP';
  Else
    Result := 'Unknown WM_Message = $' + IntToHex(WM_Message, 4);
  End; {Case}
End;

function WindowPosFlagsToString(Flags: UINT): string;
var
  FlagsStr: string;
begin
  if (Flags and SWP_DRAWFRAME) <> 0 then
    FlagsStr := FlagsStr + '|SWP_DRAWFRAME';
  if (Flags and SWP_HIDEWINDOW) <> 0 then
    FlagsStr := FlagsStr + '|SWP_HIDEWINDOW';
  if (Flags and SWP_NOACTIVATE) <> 0 then
    FlagsStr := FlagsStr + '|SWP_NOACTIVATE';
  if (Flags and SWP_NOCOPYBITS) <> 0 then
    FlagsStr := FlagsStr + '|SWP_NOCOPYBITS';
  if (Flags and SWP_NOMOVE) <> 0 then
    FlagsStr := FlagsStr + '|SWP_NOMOVE';
  if (Flags and SWP_NOOWNERZORDER) <> 0 then
    FlagsStr := FlagsStr + '|SWP_NOOWNERZORDER';
  if (Flags and SWP_NOREDRAW) <> 0 then
    FlagsStr := FlagsStr + '|SWP_NOREDRAW';
  if (Flags and SWP_NOSENDCHANGING) <> 0 then
    FlagsStr := FlagsStr + '|SWP_NOSENDCHANGING';
  if (Flags and SWP_NOSIZE) <> 0 then
    FlagsStr := FlagsStr + '|SWP_NOSIZE';
  if (Flags and SWP_NOZORDER) <> 0 then
    FlagsStr := FlagsStr + '|SWP_NOZORDER';
  if (Flags and SWP_SHOWWINDOW) <> 0 then
    FlagsStr := FlagsStr + '|SWP_SHOWWINDOW';
  if Length(FlagsStr) > 0 then
    FlagsStr := Copy(FlagsStr, 2, Length(FlagsStr)-1);
  Result := FlagsStr;
end;


{------------------------------------------------------------------------------
  Procedure: EventTrace
  Params: Message - Event name
          Data    - Object which fired this event
  Returns: Nothing

  Displays a trace about an event
 ------------------------------------------------------------------------------}
Procedure EventTrace(Message: String; Data: TObject);
Begin
  If Data = Nil Then
    Assert(False, Format('Trace:Event [%S] fired', [Message]))
  Else
    Assert(False, Format('Trace:Event [%S] fired for %S',[Message, Data.Classname]));
End;

{------------------------------------------------------------------------------
  Function: AssertEx
  Params: Message  - Message sent
          PassErr  - Pass error to a catching Procedure (default: False)
          Severity - How severe is the error on a scale from 0 to 3
                     (default: 0)
  Returns: Nothing

  An expanded, better version of Assert
 ------------------------------------------------------------------------------}
Procedure AssertEx(Const Message: String; Const PassErr: Boolean; Const Severity: Byte);
Begin
  Case Severity Of
    0:
    Begin
      Assert(PassErr, Message);
    End;
    1:
    Begin
      Assert(PassErr, Format('Trace:%S', [Message]));
    End;
    2:
    Begin
      Case IsConsole Of
        True:
        Begin
          WriteLn(rsWin32Warning, Message);
        End;
        False:
        Begin
          MessageBox(0, PChar(Message), PChar(rsWin32Warning), MB_OK);
        End;
      End;
    End;
    3:
    Begin
      Case IsConsole Of
        True:
        Begin
          WriteLn(rsWin32Error, Message);
        End;
        False:
        Begin
          MessageBox(0, PChar(Message), Nil, MB_OK);
        End;
      End;
    End;
  End;
End;

Procedure AssertEx(Const PassErr: Boolean; Const Message: String);
Begin
  AssertEx(Message, PassErr, 0);
End;

Procedure AssertEx(Const Message: String);
Begin
  AssertEx(Message, False, 0);
End;

{------------------------------------------------------------------------------
  Function: GetShiftState
  Params: None
  Returns: A shift state

  Creates a TShiftState set based on the status when the function was called.
 ------------------------------------------------------------------------------}
Function GetShiftState: TShiftState;
Begin
  Result := [];
  If Hi(GetKeyState(VK_SHIFT)) = 1 Then
    Result := Result + [ssShift];
  If Hi(GetKeyState(VK_CAPITAL)) = 1 Then
    Result := Result + [ssCaps];
  If Hi(GetKeyState(VK_CONTROL)) = 1 Then
    Result := Result + [ssCtrl];
  If Hi(GetKeyState(VK_MENU)) = 1 Then
    Result := Result + [ssAlt];
  If Hi(GetKeyState(VK_SHIFT)) = 1 Then
    Result := Result + [ssShift];
  If Hi(GetKeyState(VK_CAPITAL)) = 1 Then
    Result := Result + [ssCaps];
  If Hi(GetKeyState(VK_CONTROL)) = 1 Then
    Result := Result + [ssCtrl];
  If Hi(GetKeyState(VK_NUMLOCK)) = 1 Then
    Result := Result + [ssNum];
  //TODO: ssSuper
  If Hi(GetKeyState(VK_SCROLL)) = 1 Then
    Result := Result + [ssScroll];
  If ((Hi(GetKeyState(VK_LBUTTON)) = 1) And (GetSystemMetrics(SM_SWAPBUTTON) = 0)) Or ((Hi(GetKeyState(VK_RBUTTON)) = 1) And (GetSystemMetrics(SM_SWAPBUTTON) <> 0)) Then
    Result := Result + [ssLeft];
  If Hi(GetKeyState(VK_MBUTTON)) = 1 Then
    Result := Result + [ssMiddle];
  If ((Hi(GetKeyState(VK_RBUTTON)) = 1) And (GetSystemMetrics(SM_SWAPBUTTON) = 0)) Or ((Hi(GetKeyState(VK_LBUTTON)) = 1) And (GetSystemMetrics(SM_SWAPBUTTON) <> 0)) Then
    Result := Result + [ssRight];
  //TODO: ssAltGr
End;

{------------------------------------------------------------------------------
  Procedure: GetWin32KeyInfo
  Params:  Event      - Requested info
           KeyCode    - the ASCII key code of the eventkey
           VirtualKey - the virtual key code of the eventkey
           SysKey     - True If the key is a syskey
           ExtEnded   - True If the key is an extended key
           Toggle     - True If the key is a toggle key and its value is on
  Returns: Nothing

  GetWin32KeyInfo returns information about the given key event
 ------------------------------------------------------------------------------}
{
Procedure GetWin32KeyInfo(const Event: Integer; var KeyCode, VirtualKey: Integer; var SysKey, Extended, Toggle: Boolean);
Const
  MVK_UNIFY_SIDES = 1;
Begin
  Assert(False, 'TRACE:Using function GetWin32KeyInfo which isn''t implemented yet');
  KeyCode := Word(Event);
  VirtualKey := MapVirtualKey(KeyCode, MVK_UNIFY_SIDES);
  SysKey := (VirtualKey = VK_SHIFT) Or (VirtualKey = VK_CONTROL) Or (VirtualKey = VK_MENU);
  ExtEnded := (SysKey) Or (VirtualKey = VK_INSERT) Or (VirtualKey = VK_HOME) Or (VirtualKey = VK_LEFT) Or (VirtualKey = VK_UP) Or (VirtualKey = VK_RIGHT) Or (VirtualKey = VK_DOWN) Or (VirtualKey = VK_PRIOR) Or (VirtualKey = VK_NEXT) Or (VirtualKey = VK_END) Or (VirtualKey = VK_DIVIDE);
  Toggle := Lo(GetKeyState(VirtualKey)) = 1;
End;
}
{------------------------------------------------------------------------------
  Function: DeliverMessage
  Params:    Message - The message to process
  Returns:   True If handled

  Generic function which calls the WindowProc if defined, otherwise the
  dispatcher
 ------------------------------------------------------------------------------}
Function DeliverMessage(Const Target: Pointer; Var Message): Integer;
Begin
  If Target = Nil Then
  begin
    DebugLn('[DeliverMessage Target: Pointer] Nil');
    Exit;
  end;
  If TObject(Target) Is TControl Then
  Begin
    TControl(Target).WinDowProc(TLMessage(Message));
  End
  Else
  Begin
    TObject(Target).Dispatch(TLMessage(Message));
  End;

  Result := TLMessage(Message).Result;
End;

{------------------------------------------------------------------------------
  Function: DeliverMessage
  Params: Target  - The target object
          Message - The message to process
  Returns: Message result

  Generic function which calls the WindowProc if defined, otherwise the
  dispatcher
 ------------------------------------------------------------------------------}
Function DeliverMessage(Const Target: TObject; Var Message: TLMessage): Integer;
Begin
  If Target = Nil Then
  begin
    DebugLn('[DeliverMessage (Target: TObject)] Nil');
    Exit;
  end;
  If Target Is TControl Then
    TControl(Target).WindowProc(Message)
  Else
    Target.Dispatch(Message);
  Result := Message.Result;
End;

{-----------------------------------------------------------------------------
  Procedure: CallEvent
  Params: Target    - the object for which the event will be called
          Event     - event to call
          Data      - misc data
          EventType - the type of event
  Returns: Nothing

  Calls an event
-------------------------------------------------------------------------------}
Procedure CallEvent(Const Target: TObject; Event: TNotifyEvent; Const Data: Pointer; Const EventType: TEventType);
Begin
  If Assigned(Target) And Assigned(Event) Then
  Begin
    Case EventType Of
      etNotify:
      Begin
        Event(Target);
      End;
    End;
  End;
End;

{------------------------------------------------------------------------------
  Function: ObjectToHWND
  Params: AObject - An LCL Object
  Returns: The Window handle of the given object

  Returns the Window handle of the given object, 0 if no object available
 ------------------------------------------------------------------------------}
Function ObjectToHWND(Const AObject: TObject): HWND;
Var
  Handle: HWND;
Begin
  Handle:=0;
  If Integer(AObject) = 0 Then
  Begin
    Assert (False, 'TRACE:[ObjectToHWND] Object not assigned');
  End
  Else If (AObject Is TWinControl) Then
  Begin
    If TWinControl(AObject).HandleAllocated Then
      Handle := TWinControl(AObject).Handle
  End
  Else If (AObject Is TMenuItem) Then
  Begin
    If TMenuItem(AObject).HandleAllocated Then
      Handle := TMenuItem(AObject).Handle
  End
  Else If (AObject Is TMenu) Then
  Begin
    If TMenu(AObject).HandleAllocated Then
      Handle := TMenu(AObject).Items.Handle
  End
  Else If (AObject Is TCommonDialog) Then
  Begin
    {If TCommonDialog(AObject).HandleAllocated Then }
    Handle := TCommonDialog(AObject).Handle
  End
  Else
  Begin
    Assert(False, Format('Trace:[ObjectToHWND] Message received With unhandled class-type <%s>', [AObject.ClassName]));
  End;
  Result := Handle;
  If Handle = 0 Then
    Assert (False, 'Trace:[ObjectToHWND]****** Warning: handle = 0 *******');
End;

(***********************************************************************
  Widget member Functions
************************************************************************)

{-------------------------------------------------------------------------------
  function LCLBoundsNeedsUpdate(Sender: TWinControl;
    SendSizeMsgOnDiff: boolean): boolean;

  Returns true if LCL bounds and win32 bounds differ for the control.
-------------------------------------------------------------------------------}
function LCLControlSizeNeedsUpdate(Sender: TWinControl;
  SendSizeMsgOnDiff: boolean): boolean;
var
  Window:HWND;
  LMessage: TLMSize;
  IntfWidth, IntfHeight: integer;
begin
  Result:=false;
  Window:= Sender.Handle;
  LCLIntf.GetWindowSize(Window, IntfWidth, IntfHeight);
  if (Sender.Width = IntfWidth)
  and (Sender.Height = IntfHeight)
  and (not Sender.ClientRectNeedsInterfaceUpdate) then
    exit;
  Result:=true;
  if SendSizeMsgOnDiff then begin
    //writeln('LCLBoundsNeedsUpdate B ',TheWinControl.Name,':',TheWinControl.ClassName,' Sending WM_SIZE');
    Sender.InvalidateClientRectCache(true);
    // send message directly to LCL, some controls not subclassed -> message
    // never reaches LCL
    with LMessage do
    begin
      Msg := LM_SIZE;
      SizeType := SIZE_RESTORED or Size_SourceIsInterface;
      Width := IntfWidth;
      Height := IntfHeight;
    end;
    DeliverMessage(Sender, LMessage);
  end;
end;

// ----------------------------------------------------------------------
// The Accelgroup and AccelKey is needed by menus
// ----------------------------------------------------------------------
Procedure SetAccelGroup(Const Control: HWND; Const AnAccelGroup: HACCEL);
Begin
  Assert(False, 'Trace:TODO: Code SetAccelGroup');
  Windows.SetProp(Control, 'AccelGroup', AnAccelGroup);
End;

Function GetAccelGroup(Const Control: HWND): HACCEL;
Begin
  Assert(False, 'Trace:TODO: Code GetAccelGroup');
  Result := HACCEL(Windows.GetProp(Control, 'AccelGroup'));
End;

Procedure SetAccelKey(Window: HWND; Const CommandId: Word; Const AKey: word; Const AModifier: TShiftState);
var AccelCount: integer; {number of accelerators in table}
    NewCount: integer; {total sum of accelerators in the table}
    ControlIndex: integer; {index of new (modified) accelerator in table}
    OldAccel: HACCEL; {old accelerator table}
    NewAccel: LPACCEL; {new accelerator table}
    NullAccel: LPACCEL; {nil pointer}

  function ControlInTable: integer;
  var i: integer;
  begin
    Result:=AccelCount;
    i:=0;
    while i < AccelCount do
    begin
      if NewAccel[i].cmd = CommandId then
      begin
        Result:=i;
        exit;
      end;
      inc(i);
    end;
  end;

  function GetVirtFromState(const AState: TShiftState): Byte;
  begin
    Result := FVIRTKEY;
    if ssAlt in AState then Result := Result or FALT;
    if ssCtrl in AState then Result := Result or FCONTROL;
    if ssShift in AState then Result := Result or FSHIFT;
  end;

Begin
  OldAccel := Windows.GetProp(Window, 'Accel');
  NullAccel := nil;
  AccelCount := CopyAcceleratorTable(OldAccel, NullAccel, 0);
  Assert(False,Format('Trace: AccelCount=%d',[AccelCount]));
  NewAccel := LPACCEL(LocalAlloc(LPTR, AccelCount * sizeof(ACCEL)));
  CopyAcceleratorTable(OldAccel, NewAccel, AccelCount);
  ControlIndex := ControlInTable;
  if ControlIndex = AccelCount then {realocating the accelerator array, adding new accelerator}
  begin
    LocalFree(HLOCAL(NewAccel));
    NewAccel := LPACCEL(LocalAlloc(LPTR, (AccelCount+1) * sizeof(ACCEL)));
    CopyAcceleratorTable(OldAccel, NewAccel, AccelCount);
    NewCount := AccelCount+1;
  end
  else NewCount := AccelCount;
  NewAccel[ControlIndex].cmd := CommandId;
  NewAccel[ControlIndex].fVirt := GetVirtFromState(AModifier);
  NewAccel[ControlIndex].key := AKey;
  DestroyAcceleratorTable(OldAccel);
  Windows.SetProp(Window, 'Accel', CreateAcceleratorTable(NewAccel, NewCount));
End;

Function GetAccelKey(Const Control: HWND): LPACCEL;
Begin
  Assert(False, 'Trace:TODO: Code GetAccelKey');
  Result := GetProp(Control, 'AccelKey');
End;

{-------------------------------------------------------------------------------
  function GetLCLClientOriginOffset(Sender: TObject;
    var LeftOffset, TopOffset: integer): boolean;

  Returns the difference between the client origin of a win32 handle
  and the definition of the LCL counterpart.
  For example:
    TGroupBox's client area is the area inside the groupbox frame.
    Hence, the LeftOffset is the frame width and the TopOffset is the caption
    height.
-------------------------------------------------------------------------------}
function GetLCLClientBoundsOffset(Sender: TObject; var ORect: TRect): boolean;
var
  TM: TextMetricA;
  DC: HDC;
  Handle: HWND;
  TheWinControl: TWinControl;
  ARect: TRect;
Begin
  Result:=false;
  if (Sender = nil) or (not (Sender is TWinControl)) then exit;
  TheWinControl:=TWinControl(Sender);
  if not TheWinControl.HandleAllocated then exit;
  Handle := TheWinControl.Handle;
  ORect.Left := 0;
  ORect.Top := 0;
  ORect.Bottom := 0;
  ORect.Right := 0;
  If (TheWinControl is TCustomGroupBox) Then
  Begin
    // The client area of a groupbox under win32 is the whole size, including
    // the frame. The LCL defines the client area without the frame.
    // -> Adjust the position
    DC := Windows.GetDC(Handle);
    // add the upper frame with the caption
    GetTextMetrics(DC, TM);
    ORect.Top := TM.TMHeight;
    // add the left frame border
    ORect.Left := 2;
    ORect.Right := -2;
    ORect.Bottom := -2;
    ReleaseDC(Handle, DC);
  End Else
  If TheWinControl is TCustomNoteBook then begin
    // Can't use complete client rect in win32 interface, top part contains the tabs
    Windows.GetClientRect(Handle, @ARect);
    ORect := ARect;
    Windows.SendMessage(Handle, TCM_AdjustRect, 0, LPARAM(@ORect));
    Dec(ORect.Right, ARect.Right);
    Dec(ORect.Bottom, ARect.Bottom);
  end;
{
  if (Windows.GetWindowLong(Handle, GWL_EXSTYLE) and WS_EX_CLIENTEDGE) <> 0 then
  begin
    Dec(LeftOffset, Windows.GetSystemMetrics(SM_CXEDGE));
    Dec(TopOffset, Windows.GetSystemMetrics(SM_CYEDGE));
  end;
}
  Result:=true;
end;

function GetLCLClientBoundsOffset(Handle: HWnd; var Rect: TRect): boolean;
var
  OwnerObject: TObject;
begin
  OwnerObject := TObject(GetProp(Handle, 'Wincontrol'));
  Result:=GetLCLClientBoundsOffset(OwnerObject, Rect);
end;

Procedure LCLBoundsToWin32Bounds(Sender: TObject;
  var Left, Top, Width, Height: Integer);
var
  ORect: TRect;
Begin
  if (Sender=nil) or (not (Sender is TWinControl)) then exit;
  if not GetLCLClientBoundsOffset(TWinControl(Sender).Parent, ORect) then exit;
  inc(Left, ORect.Left);
  inc(Top, ORect.Top);
End;

Procedure Win32PosToLCLPos(Sender: TObject; var Left, Top: SmallInt);
var
  ORect: TRect;
Begin
  if (Sender=nil) or (not (Sender is TWinControl)) then exit;
  if not GetLCLClientBoundsOffset(TWinControl(Sender).Parent, ORect) then exit;
  dec(Left, ORect.Left);
  dec(Top, ORect.Top);
End;

{
  Updates the window style of the window indicated by Handle.
  The new style is the Style parameter.
  Only the bits set in the StyleMask are changed,
  the other bits remain untouched.
  If the bits in the StyleMask are not used in the Style,
  there are cleared.
}
procedure UpdateWindowStyle(Handle: HWnd; Style: integer; StyleMask: integer);
var
  CurrentStyle: integer;
  NewStyle: integer;
begin
  CurrentStyle := Windows.GetWindowLong(Handle, GWL_STYLE);
  NewStyle := (Style and StyleMask) or (CurrentStyle and (not StyleMask));
  Windows.SetWindowLong(Handle, GWL_STYLE, NewStyle);
end;

function BorderStyleToWin32Flags(Style: TFormBorderStyle): DWORD;
begin
  Result := WS_CLIPCHILDREN or WS_CLIPSIBLINGS;
  case Style of
  bsSizeable, bsSizeToolWin:
    Result := Result or (WS_POPUP or WS_THICKFRAME or WS_CAPTION);
  bsSingle, bsToolWindow:
    Result := Result or (WS_OVERLAPPED or WS_BORDER or WS_CAPTION);
  bsDialog:
    Result := Result or (WS_POPUP or WS_BORDER or WS_CAPTION);
  bsNone:
    Result := Result or WS_POPUP;
  end;
end;

function BorderStyleToWin32FlagsEx(Style: TFormBorderStyle): DWORD;
begin
  Result := 0;
  case Style of
  bsDialog:
    Result := WS_EX_DLGMODALFRAME or WS_EX_WINDOWEDGE;
  bsToolWindow, bsSizeToolWin:
    Result := WS_EX_TOOLWINDOW;
  end;
end;

function GetFileVersion(FileName: string): dword;
var
  buf: pointer;
  lenBuf: dword;
  fixedInfo: ^VS_FIXEDFILEINFO;
begin
  Result := $FFFFFFFF;
  lenBuf := GetFileVersionInfoSize(PChar(FileName), lenBuf);
  if lenBuf > 0 then
  begin
    GetMem(buf, lenBuf);
    if GetFileVersionInfo(PChar(FileName), 0, lenBuf, buf) then
    begin
      VerQueryValue(buf, '\', pointer(fixedInfo), lenBuf);
      Result := fixedInfo^.dwFileVersionMS;
    end;
    FreeMem(buf);
  end;
end;

{$IFDEF ASSERT_IS_ON}
  {$UNDEF ASSERT_IS_ON}
  {$C-}
{$ENDIF}
end.

