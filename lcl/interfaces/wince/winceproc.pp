unit winceproc;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, LMessages, LCLType, LCLProc, Controls, Forms, Menus,
  WinCEExtra, GraphType;
  
Type
  TEventType = (etNotify, etKey, etKeyPress, etMouseWheel, etMouseUpDown);

  PWindowInfo = ^TWindowInfo;
  TWindowInfo = record
    AccelGroup: HACCEL;
    Accel: HACCEL;
    Overlay: HWND;            // overlay, transparent window on top, used by designer
    PopupMenu: TPopupMenu;
    DefWndProc: WNDPROC;
    ParentPanel: HWND;        // if non-zero, winxp groupbox parent window hack
    WinControl: TWinControl;
    PWinControl: TWinControl; // control to paint for
    AWinControl: TWinControl; // control associated with (for buddy controls)
    List: TStrings;
    DisabledWindowList: TList;// a list of windows that were disabled when showing modal
    needParentPaint: boolean; // has a tabpage as parent, and is winxp themed
    isTabPage: boolean;       // is window of tabpage
    isComboEdit: boolean;     // is buddy of combobox, the edit control
    isChildEdit: boolean;     // is buddy edit of a control
    isGroupBox: boolean;      // is groupbox, and does not have themed tabpage as parent
    MaxLength: dword;
    DrawItemIndex: integer;   // in case of listbox, when handling WM_DRAWITEM
    DrawItemSelected: boolean;// whether this item is selected LB_GETSEL not uptodate yet
    myButton : HWND;
    MouseX, MouseY: word; // noticing spurious WM_MOUSEMOVE messages
    case integer of
      0: (spinValue: single);
      1: (
        TrackValid: Boolean; // Set when we have a valid trackpos
        TrackPos: Integer    // keeps the thumb position while tracking
      );
  end;

function WideStringToString(inWideString : WideString) : String;
function WM_To_String(WM_Message: Integer): string;
function WindowPosFlagsToString(Flags: UINT): string;
procedure EventTrace(Message: String; Data: TObject);
procedure AssertEx(const Message: String; const PassErr: Boolean;
  const Severity: Byte);
procedure AssertEx(const PassErr: Boolean; const Message: String);
procedure AssertEx(const Message: String);
function GetShiftState: TShiftState;
function DeliverMessage(const Target: Pointer; var Message): Integer;
function DeliverMessage(const Target: TObject; var Message: TLMessage): Integer;
procedure CallEvent(const Target: TObject; Event: TNotifyEvent;
  const Data: Pointer; const EventType: TEventType);
function ObjectToHWND(Const AObject: TObject): HWND;
function GetDesigningBorderStyle(const AForm: TCustomForm): TFormBorderStyle;

function BytesPerLine(nWidth, nBitsPerPixel: Integer): Integer;
function CreateDIBSectionFromDescription(ADC: HDC; const ADesc: TRawImageDescription; out ABitsPtr: Pointer): HBITMAP;
procedure FillRawImageDescriptionColors(var ADesc: TRawImageDescription);
procedure FillRawImageDescription(const ABitmapInfo: Windows.TBitmap; out ADesc: TRawImageDescription);

function GetBitmapBytes(ABitmap: HBITMAP; const ARect: TRect; ALineEnd: TRawImageLineEnd; var AData: Pointer; var ADataSize: PtrUInt): Boolean;



//roozbeh:these are simply copy-pasted from win32...i bet most of them can be changed
//or not that much neccessary on wince!
function LCLControlSizeNeedsUpdate(Sender: TWinControl;
  SendSizeMsgOnDiff: boolean): boolean;

function GetLCLClientBoundsOffset(Sender: TObject; var ORect: TRect): boolean;
function GetLCLClientBoundsOffset(Handle: HWnd; var Rect: TRect): boolean;
Procedure LCLBoundsToWin32Bounds(Sender: TObject;
  var Left, Top, Width, Height: Integer);
Procedure LCLFormSizeToWin32Size(Form: TCustomForm; var AWidth, AHeight: Integer);
Procedure Win32PosToLCLPos(Sender: TObject; var Left, Top: SmallInt);
procedure GetWin32ControlPos(Window, Parent: HWND; var Left, Top: integer);

procedure UpdateWindowStyle(Handle: HWnd; Style: integer; StyleMask: integer);
function BorderStyleToWin32Flags(Style: TFormBorderStyle): DWORD;
function BorderStyleToWin32FlagsEx(Style: TFormBorderStyle): DWORD;

function GetFileVersion(FileName: string): dword;
function AllocWindowInfo(Window: HWND): PWindowInfo;
function DisposeWindowInfo(Window: HWND): boolean;
function GetWindowInfo(Window: HWND): PWindowInfo;
function DisableWindowsProc(Window: HWND; Data: LParam): LongBool; stdcall;
procedure DisableApplicationWindows(Window: HWND);
procedure EnableApplicationWindows(Window: HWND);
procedure AddToChangedMenus(Window: HWnd);
procedure RedrawMenus;
function MeasureText(const AWinControl: TWinControl; Text: string; var Width, Height: integer): boolean;
function GetControlText(AHandle: HWND): string;

type
  PDisableWindowsInfo = ^TDisableWindowsInfo;
  TDisableWindowsInfo = record
    NewModalWindow: HWND;
    DisabledWindowList: TList;
  end;

var
  DefaultWindowInfo: TWindowInfo;
  OverwriteCheck: Integer = 0;
  ChangedMenus: TList; // list of HWNDs which menus needs to be redrawn


implementation

uses
  SysUtils, LCLStrConsts, Dialogs, StdCtrls, ExtCtrls,
  LCLIntf; //remove this unit when GetWindowSize is moved to TWSWinControl



//well this is diffrent from normal string(widestring) or other rtl functions becouse it uses windows local codepage
//better name for this?!
function WideStringToString(inWideString : WideString) : String;
var
tmpStr : PChar;
//test : string;
inStrLen: integer;
begin
//  test := string(inWideString);
  inStrLen := Length(inWideString);
  tmpStr := StrAlloc(inStrLen+1);
  WideCharToMultiByte(CP_ACP, 0, PWideChar(inWideString), -1, tmpStr, inStrLen,nil,nil);
  char((tmpStr+inStrLen)^) := #0;
  Result := string(tmpStr);
  StrDispose(tmpStr);
end;


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
    Result := 'Unknown(' + IntToStr(WM_Message) + ')';
  End; {Case}
End;

function WindowPosFlagsToString(Flags: UINT): string;
var
  FlagsStr: string;
begin
  FlagsStr := '';
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
//roozbeh todo:remove the unecessary ones
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
  If not assigned(AObject) Then
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
//  Else If (AObject Is TCommonDialog) Then
//  Begin
//    {If TCommonDialog(AObject).HandleAllocated Then }
//    Handle := TCommonDialog(AObject).Handle
//  End
  Else
  Begin
    Assert(False, Format('Trace:[ObjectToHWND] Message received With unhandled class-type <%s>', [AObject.ClassName]));
  End;
  Result := Handle;
  If Handle = 0 Then
    Assert (False, 'Trace:[ObjectToHWND]****** Warning: handle = 0 *******');
end;

function BytesPerLine(nWidth, nBitsPerPixel: Integer): Integer;
begin
  Result := ((nWidth * nBitsPerPixel + 31) and (not 31) ) div 8;
end;

procedure FillRawImageDescriptionColors(var ADesc: TRawImageDescription);
begin
  case ADesc.BitsPerPixel of
    1,4,8:
      begin
        // palette mode, no offsets
        ADesc.Format := ricfGray;
        ADesc.RedPrec := ADesc.BitsPerPixel;
        ADesc.GreenPrec := 0;
        ADesc.BluePrec := 0;
        ADesc.RedShift := 0;
        ADesc.GreenShift := 0;
        ADesc.BlueShift := 0;
      end;
    16:
      begin
        // 5-6-5 mode
        //roozbeh all changed from 5-5-5 to 5-6-5
        ADesc.RedPrec := 5;
        ADesc.GreenPrec := 6;
        ADesc.BluePrec := 5;
        ADesc.RedShift := 11;
        ADesc.GreenShift := 5;
        ADesc.BlueShift := 0;
        ADesc.Depth := 16;
      end;
    24:
      begin
        // 8-8-8 mode
        ADesc.RedPrec := 8;
        ADesc.GreenPrec := 8;
        ADesc.BluePrec := 8;
        ADesc.RedShift := 16;
        ADesc.GreenShift := 8;
        ADesc.BlueShift := 0;
      end;
  else    //  32:
    // 8-8-8-8 mode, high byte can be native alpha or custom 1bit maskalpha
    ADesc.AlphaPrec := 8;
    ADesc.RedPrec := 8;
    ADesc.GreenPrec := 8;
    ADesc.BluePrec := 8;
    ADesc.AlphaShift := 24;
    ADesc.RedShift := 16;
    ADesc.GreenShift := 8;
    ADesc.BlueShift := 0;
    ADesc.Depth := 32;
  end;
end;


procedure FillRawImageDescription(const ABitmapInfo: Windows.TBitmap; out ADesc: TRawImageDescription);
begin
  ADesc.Init;

  ADesc.Format := ricfRGBA;

  ADesc.Depth := ABitmapInfo.bmBitsPixel;             // used bits per pixel
  ADesc.Width := ABitmapInfo.bmWidth;
  ADesc.Height := ABitmapInfo.bmHeight;
  ADesc.BitOrder := riboReversedBits;
  ADesc.ByteOrder := riboLSBFirst;
  ADesc.LineOrder := riloTopToBottom;
  ADesc.BitsPerPixel := ABitmapInfo.bmBitsPixel;      // bits per pixel. can be greater than Depth.
  ADesc.LineEnd := rileDWordBoundary;

  if ABitmapInfo.bmBitsPixel <= 8
  then begin
    // each pixel is an index in the palette
    // TODO, ColorCount
    ADesc.PaletteColorCount := 0;
  end
  else ADesc.PaletteColorCount := 0;

  FillRawImageDescriptionColors(ADesc);
  
  ADesc.MaskBitsPerPixel := 1;
  ADesc.MaskShift := 0;
  ADesc.MaskLineEnd := rileWordBoundary; // CreateBitmap requires word boundary
  ADesc.MaskBitOrder := riboReversedBits;
end;

function CreateDIBSectionFromDescription(ADC: HDC; const ADesc: TRawImageDescription; out ABitsPtr: Pointer): HBITMAP;
  function GetMask(APrec, AShift: Byte): Cardinal;
  begin
    Result := ($FFFFFFFF shr (32-APrec)) shl AShift;
  end;

var
  Info: record
    Header: Windows.TBitmapInfoHeader;
    Colors: array[0..3] of Cardinal; // reserve extra color for colormasks
  end;
begin
  FillChar(Info, sizeof(Info), 0);
  Info.Header.biSize := sizeof(Windows.TBitmapInfoHeader);
  Info.Header.biWidth := ADesc.Width;
  Info.Header.biHeight := -ADesc.Height;
  Info.Header.biPlanes := 1;
  Info.Header.biBitCount := ADesc.BitsPerPixel;
  // TODO: palette support
  Info.Header.biClrUsed := 0;
  Info.Header.biClrImportant := 0;
  Info.Header.biSizeImage := BytesPerLine(Info.Header.biWidth, Info.Header.biBitCount) * ADesc.Height;
  // CE only supports bitfields
  Info.Header.biCompression := BI_BITFIELDS;

  // when 24bpp, CE only supports B8G8R8 encoding
  // TODO: check the description
  Info.Colors[0] := GetMask(ADesc.RedPrec, ADesc.RedShift);
  Info.Colors[1] := GetMask(ADesc.GreenPrec, ADesc.GreenShift);
  Info.Colors[2] := GetMask(ADesc.BluePrec, ADesc.BlueShift);

  // Use createDIBSection, since only devicedepth bitmaps can be selected into a DC
  // when they are created with createDIBitmap
  Result := Windows.CreateDIBSection(ADC, Windows.PBitmapInfo(@Info)^, DIB_RGB_COLORS, ABitsPtr, 0, 0);

  //DbgDumpBitmap(Result, 'CreateDIBSectionFromDescription - Image');
end;

function GetBitmapBytes(ABitmap: HBITMAP; const ARect: TRect; ALineEnd: TRawImageLineEnd; var AData: Pointer; var ADataSize: PtrUInt): Boolean;
var
  Section: Windows.TDIBSection;
begin
  // first try if the bitmap is created as section
  if (Windows.GetObject(ABitmap, SizeOf(Section), @Section) > 0) and (Section.dsBm.bmBits <> nil)
  then begin
    with Section.dsBm do
      Result := CopyImageData(bmWidth, bmHeight, bmWidthBytes, bmBitsPixel, bmBits, ARect, riloTopToBottom, riloTopToBottom, ALineEnd, AData, ADataSize);
    Exit;
  end;
  
  // bitmap is not a section, retrieve only bitmap
  if Windows.GetObject(ABitmap, SizeOf(Section.dsBm), @Section) = 0
  then Exit(False);

  {$note TODO: create copy bitmap to section and use bits}

  Result := True;
end;


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

//roozbeh : not yet ready!
(*
// ----------------------------------------------------------------------
// The Accelgroup and AccelKey is needed by menus
// ----------------------------------------------------------------------
Procedure SetAccelGroup(Const Control: HWND; Const AnAccelGroup: HACCEL);
var
  WindowInfo: PWindowInfo;
Begin
  Assert(False, 'Trace:TODO: Code SetAccelGroup');
  WindowInfo := GetWindowInfo(Control);
  if WindowInfo <> @DefaultWindowInfo then
  begin
    WindowInfo^.AccelGroup := AnAccelGroup;
  end else begin
    DebugLn('Win32 - SetAccelGroup: no window info to store accelgroup in!');
  end;
End;

Function GetAccelGroup(Const Control: HWND): HACCEL;
Begin
  Assert(False, 'Trace:TODO: Code GetAccelGroup');
  Result := GetWindowInfo(Control)^.AccelGroup;
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

var
  WindowInfo: PWindowInfo;
Begin
  WindowInfo := GetWindowInfo(Window);
  OldAccel := WindowInfo^.Accel;
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
  if WindowInfo <> @DefaultWindowInfo then
  begin
    WindowInfo^.Accel := CreateAcceleratorTable(NewAccel, NewCount);
  end else begin
    DebugLn('Win32 - SetAccelKey: no windowinfo to put accelerator table in!');
  end;
End;

Function GetAccelKey(Const Control: HWND): LPACCEL;
Begin
  Assert(False, 'Trace:TODO: Code GetAccelKey');
  //Result := GetWindowInfo(Control)^.AccelKey;
  Result := nil;
End;
*)
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
  TM: TextMetric;
  DC: HDC;
  Handle: HWND;
  TheWinControl: TWinControl;
  ARect: TRect;
  Ignore: Integer;
Begin
  Result:=false;
  if (Sender = nil) or (not (Sender is TWinControl)) then exit;
  TheWinControl:=TWinControl(Sender);
  if not TheWinControl.HandleAllocated then exit;
  Handle := TheWinControl.Handle;
  FillChar(ORect, SizeOf(ORect), 0);
  if TheWinControl is TScrollingWinControl then
    with TScrollingWinControl(TheWinControl) do
    begin
      if HorzScrollBar <> nil then
      begin
        // left and right bounds are shifted by scroll position
        ORect.Left := -HorzScrollBar.Position;
        ORect.Right := -HorzScrollBar.Position;
      end;
      if VertScrollBar <> nil then
      begin
        // top and bottom bounds are shifted by scroll position
        ORect.Top := -VertScrollBar.Position;
        ORect.Bottom := -VertScrollBar.Position;
      end;
    end;
  if (TheWinControl is TCustomGroupBox) then
  begin
    // The client area of a groupbox under winapi is the whole size, including
    // the frame. The LCL defines the client area without the frame.
    // -> Adjust the position
    // add the upper frame with the caption
    DC := Windows.GetDC(Handle);
    GetTextMetrics(DC, TM);
    ORect.Top := TM.TMHeight;
    ReleaseDC(Handle, DC);
    { GetTextMetrics may not be supported on all devices, so we
      have fallback to GetSystemMetrics if it doesn't work.
      Also careful that SM_CYSMCAPTION returns 0 on the emulator }
    if ORect.Top = 0 then ORect.Top := GetSystemMetrics(SM_CYCAPTION);
    // add the left, right and bottom frame borders
    ORect.Left := 2;
    ORect.Right := -2;
    ORect.Bottom := -2;
  end else
  if TheWinControl is TCustomNoteBook then
  begin
    // Can't use complete client rect in win32 interface, top part contains the tabs
    Windows.GetClientRect(Handle, @ARect);
    ORect := ARect;
    Windows.SendMessage(Handle, TCM_AdjustRect, 0, LPARAM(@ORect));
    Dec(ORect.Right, ARect.Right);
    Dec(ORect.Bottom, ARect.Bottom);
  end;
{
  if (GetWindowLong(Handle, GWL_EXSTYLE) and WS_EX_CLIENTEDGE) <> 0 then
  begin
    Dec(LeftOffset, Windows.GetSystemMetrics(SM_CXEDGE));
    Dec(TopOffset, Windows.GetSystemMetrics(SM_CYEDGE));
  end;
}
  Result := True;
end;

function GetLCLClientBoundsOffset(Handle: HWnd; var Rect: TRect): boolean;
var
  OwnerObject: TObject;
begin
  OwnerObject := GetWindowInfo(Handle)^.WinControl;
  Result:=GetLCLClientBoundsOffset(OwnerObject, Rect);
end;

procedure LCLBoundsToWin32Bounds(Sender: TObject;
  var Left, Top, Width, Height: Integer);
var
  ORect: TRect;
Begin
  if (Sender=nil) or (not (Sender is TWinControl)) then exit;
  if not GetLCLClientBoundsOffset(TWinControl(Sender).Parent, ORect) then exit;
  inc(Left, ORect.Left);
  inc(Top, ORect.Top);
End;

procedure LCLFormSizeToWin32Size(Form: TCustomForm; var AWidth, AHeight: Integer);
{$NOTE Should be moved to WSWin32Forms, if the windowproc is splitted}
var
  SizeRect: Windows.RECT;
  BorderStyle: TFormBorderStyle;
begin
  with SizeRect do
  begin
    Left := 0;
    Top := 0;
    Right := AWidth;
    Bottom := AHeight;
  end;
  BorderStyle := GetDesigningBorderStyle(Form);
  Windows.AdjustWindowRectEx(@SizeRect, BorderStyleToWin32Flags(
      BorderStyle), false, BorderStyleToWin32FlagsEx(BorderStyle));
  AWidth := SizeRect.Right - SizeRect.Left;
  AHeight := SizeRect.Bottom - SizeRect.Top;
end;

//roozbeh...new update what is it?!
Procedure Win32PosToLCLPos(Sender: TObject; var Left, Top: SmallInt);
var
  ORect: TRect;
Begin
  if (Sender=nil) or (not (Sender is TWinControl)) then exit;
  if not GetLCLClientBoundsOffset(TWinControl(Sender).Parent, ORect) then exit;
  dec(Left, ORect.Left);
  dec(Top, ORect.Top);
End;

procedure GetWin32ControlPos(Window, Parent: HWND; var Left, Top: integer);
var
  parRect, winRect: Windows.TRect;
begin
  Windows.GetWindowRect(Window, @winRect);
  Windows.GetWindowRect(Parent, @parRect);
  Left := winRect.Left - parRect.Left;
  Top := winRect.Top - parRect.Top;
end;

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
  CurrentStyle,
  NewStyle : PtrInt;
begin
  CurrentStyle := Windows.GetWindowLong(Handle, GWL_STYLE);
  NewStyle := (Style and StyleMask) or (CurrentStyle and (not StyleMask));
  Windows.SetWindowLong(Handle, GWL_STYLE, NewStyle);
end;

function BorderStyleToWin32Flags(Style: TFormBorderStyle): DWORD;
begin
  Result := WS_CLIPCHILDREN or WS_CLIPSIBLINGS;
  case Application.ApplicationType of
  { Under Desktop or Handheld mode we get an application which
    looks similar to a desktop one, with sizable windows }
    atDesktop, atHandheld:
      begin
        case Style of
        bsSizeable, bsSizeToolWin:
          Result := Result or (WS_OVERLAPPED or WS_THICKFRAME or WS_CAPTION);
        bsSingle, bsToolWindow:
          Result := Result or (WS_OVERLAPPED or WS_BORDER or WS_CAPTION);
        bsDialog:
          Result := Result or (WS_POPUP or WS_BORDER or WS_CAPTION);
        bsNone:
          Result := Result or WS_POPUP;
        end;
      end;
    { Under PDA or Smartphone modes most windows are enlarged to fit the screen
      Dialogs and borderless windows are exceptions }
    atPDA, atSmartphone, atDefault:
      begin
        case Style of
        bsDialog:
          Result := Result or (WS_POPUP or WS_BORDER or WS_CAPTION);
        bsNone:
          Result := Result or WS_POPUP;
        else
          Result := WS_VISIBLE;
        end;
      end;
  end;
end;

function BorderStyleToWin32FlagsEx(Style: TFormBorderStyle): DWORD;
begin
  Result := 0;
  case Application.ApplicationType of
  atDesktop,atHandheld:
    begin
      case Style of
      bsDialog:
        Result := WS_EX_DLGMODALFRAME or WS_EX_WINDOWEDGE;
      bsToolWindow, bsSizeToolWin:
        Result := WS_EX_TOOLWINDOW;
      end;
    end;
  atPDA,atSmartphone,atDefault:
    begin
{     This code is comented because the OK button wasn't being handled
      and it's hard to know if the dialog actually needs an OK button

      case Style of
      bsDialog:
        Result := WS_EX_CAPTIONOKBTN;
      end;}
    end;
  end;
end;

//roozbeh:new update test it

function GetDesigningBorderStyle(const AForm: TCustomForm): TFormBorderStyle;
{$NOTE Belongs in Win32WSForms, but is needed in windowproc}
begin
//  if csDesigning in AForm.ComponentState then
//    Result := bsSizeable
//  else
    Result := AForm.BorderStyle;
end;

function GetFileVersion(FileName: string): dword;
var
  buf: pointer;
  lenBuf: dword;
  fixedInfo: ^VS_FIXEDFILEINFO;
  tmpText : PWideChar;
begin
  Result := $FFFFFFFF;
  tmpText := StringToPWideChar(FileName);
  lenBuf := GetFileVersionInfoSize(tmpText, lenBuf);
  if lenBuf > 0 then
  begin
    GetMem(buf, lenBuf);
    if GetFileVersionInfo(tmpText, 0, lenBuf, buf) then
    begin
      VerQueryValue(buf, '\', pointer(fixedInfo), lenBuf);
      Result := fixedInfo^.dwFileVersionMS;
    end;
    FreeMem(buf);
  end;
  FreeMem(tmpText);
end;

function AllocWindowInfo(Window: HWND): PWindowInfo;
var
  WindowInfo: PWindowInfo;
begin
  New(WindowInfo);
  FillChar(WindowInfo^, sizeof(WindowInfo^), 0);
  WindowInfo^.DrawItemIndex := -1;
  WinCEExtra.SetProp(Window, {PChar(dword(WindowInfoAtom)),} dword(WindowInfo));
  Result := WindowInfo;
end;

function DisposeWindowInfo(Window: HWND): boolean;
var
  WindowInfo: PWindowInfo;
begin
  WindowInfo := PWindowInfo(WinCEExtra.GetProp(Window{, PChar(dword(WindowInfoAtom))}));
  Result := WinCEExtra.RemoveProp(Window{, PChar(dword(WindowInfoAtom))})<>0;
  if Result then
  begin
    WindowInfo^.DisabledWindowList.Free;
    Dispose(WindowInfo);
  end;
end;

function GetWindowInfo(Window: HWND): PWindowInfo;
begin
  Result := PWindowInfo(WinCEExtra.GetProp(Window{, PChar(dword(WindowInfoAtom))}));
  if Result = nil then
    Result := @DefaultWindowInfo;
end;

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
  if Window = PDisableWindowsInfo(Data)^.NewModalWindow then exit;

  // Don't disable any ComboBox listboxes
  if (GetClassName(Window, @Buffer, sizeof(Buffer))<sizeof(Buffer))
    and (StrIComp(Buffer, 'ComboLBox')=0) then exit;

  if not IsWindowVisible(Window) or not IsWindowEnabled(Window) then exit;

  PDisableWindowsInfo(Data)^.DisabledWindowList.Add(Pointer(Window));
  EnableWindow(Window,False);
end;

var
  InDisableApplicationWindows: boolean = false;

procedure DisableApplicationWindows(Window: HWND);
var
  DisableWindowsInfo: PDisableWindowsInfo;
  WindowInfo: PWindowInfo;
begin
  // prevent recursive calling when the AppHandle window is disabled
  If InDisableApplicationWindows then exit;
  InDisableApplicationWindows:=true;
  New(DisableWindowsInfo);
  DisableWindowsInfo^.NewModalWindow := Window;
  DisableWindowsInfo^.DisabledWindowList := TList.Create;
  WindowInfo := GetWindowInfo(DisableWindowsInfo^.NewModalWindow);
  WindowInfo^.DisabledWindowList := DisableWindowsInfo^.DisabledWindowList;
// :)) well....
//  EnumThreadWindows(GetWindowThreadProcessId(DisableWindowsInfo^.NewModalWindow, nil),
//    @DisableWindowsProc, LPARAM(DisableWindowsInfo));
  Dispose(DisableWindowsInfo);
  InDisableApplicationWindows := false;
end;

procedure EnableApplicationWindows(Window: HWND);
var
  WindowInfo: PWindowInfo;
  I: integer;
begin
  WindowInfo := GetWindowInfo(Window);
  if WindowInfo^.DisabledWindowList <> nil then
  begin
    for I := 0 to WindowInfo^.DisabledWindowList.Count - 1 do
      EnableWindow(HWND(WindowInfo^.DisabledWindowList.Items[I]), true);
    FreeAndNil(WindowInfo^.DisabledWindowList);
  end;
end;

function MeasureText(const AWinControl: TWinControl; Text: string; var Width, Height: integer): boolean;
var
  textSize: Windows.SIZE;
  winHandle: HWND;
  canvasHandle: HDC;
  oldFontHandle: HFONT;
  tmpText : PWideChar;
begin
  winHandle := AWinControl.Handle;
  canvasHandle := GetDC(winHandle);
  oldFontHandle := SelectObject(canvasHandle, Windows.SendMessage(winHandle, WM_GetFont, 0, 0));
  DeleteAmpersands(Text);

  tmpText := StringToPWideChar(Text);
  Result := Windows.GetTextExtentPoint32(canvasHandle, PWideChar(tmpText), Length(Text), @textSize);
  FreeMem(tmpText);

  if Result then
  begin
    Width := textSize.cx;
    Height := textSize.cy;
  end;
  SelectObject(canvasHandle, oldFontHandle);
  ReleaseDC(winHandle, canvasHandle);
end;

function GetControlText(AHandle: HWND): string;
var
  TextLen: dword;
  tmpWideStr : PWideChar;
begin
  TextLen := GetWindowTextLength(AHandle);
  tmpWideStr := PWideChar(SysAllocStringLen(nil,TextLen + 1));
  GetWindowText(AHandle, tmpWideStr, TextLen + 1);
  Result := WideStringToString(widestring(tmpWideStr));
  SysFreeString(tmpWideStr);
end;


{-------------------------------------------------------------------------------
  procedure AddToChangedMenus(Window: HWnd);

  Adds Window to the list of windows which need to redraw the main menu.
-------------------------------------------------------------------------------}
procedure AddToChangedMenus(Window: HWnd);
begin
  if ChangedMenus.IndexOf(Pointer(Window)) = -1 then // Window handle is not yet in the list
    ChangedMenus.Add(Pointer(Window));
end;

{------------------------------------------------------------------------------
  Method: RedrawMenus
  Params:  None
  Returns: Nothing

  Redraws all changed menus
 ------------------------------------------------------------------------------}
procedure RedrawMenus;
var
  I: integer;
begin
  for I := 0 to  ChangedMenus.Count - 1 do
    DrawMenuBar(HWND(ChangedMenus[I]));
  ChangedMenus.Clear;
end;

initialization
  FillChar(DefaultWindowInfo, sizeof(DefaultWindowInfo), 0);
  DefaultWindowInfo.DrawItemIndex := -1;
  ChangedMenus := TList.Create;

finalization
//roozbeh:unless i implement enumprop i should free my tpropertylist myself!
  ChangedMenus.Free;

end.





