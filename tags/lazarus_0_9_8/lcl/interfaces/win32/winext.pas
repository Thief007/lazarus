{
  Extra Win32 code that's not in the RTL.
  Copyright (C) 2001, 2002 Keith Bowes.

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

Unit WinExt;

{$mode objfpc}{$H+}

{$IFDEF TRACE}
  {$ASSERTIONS ON}
{$ENDIF}

{$PACKRECORDS C}
{$SMARTLINK ON}

Interface

Uses Classes, Windows;

{ Win32 API records not included in windows.pp }
Type
  { Record for the @link(GetComboBoxInfo) function }
  COMBOBOXINFO = Record
    cbSize, stateButton: DWORD;
    rcItem, rcButton: RECT;
    hwndCombo, hwndItem, hwndList: HWND;
  End;
  { Pointer to @link(COMBOBOXINFO) }
  PComboBoxInfo = ^COMBOBOXINFO;

{ Win32 API constants not included in windows.pp }
Const
  { Recommended modal-dialog style }
  DSC_MODAL = WS_POPUP Or WS_SYSMENU Or WS_CAPTION Or DS_MODALFRAME;
  { Recommended modeless-dialog style }
  DSC_MODELESS = WS_POPUP Or WS_CAPTION Or WS_BORDER Or WS_SYSMENU;
  { The window's direct parent window }
  GA_PARENT = 1;
  { The window's root window }
  GA_ROOT = 2;
  { The window's owner }
  GA_ROOTOWNER = 3;
  { Application starting cursor }
  IDC_APPSTARTING = 32650;
  { Hand cursor }
  IDC_HAND = 32649;
  { Get the progress bar range }
  PBM_GETRANGE = 1031;
  { Smooth progrss bar }
  PBS_SMOOTH = 1;
  { Vertical progress bar }
  PBS_VERTICAL = 4;
  { Mouse-hovering message }
  WM_MOUSEHOVER = $02A1;
  { Mouse-leaving message }
  WM_MOUSELEAVE = $02A3;
  { Mouse-wheel message }
  WM_MOUSEWHEEL = $020A;
  { Left-to-right reading text }
  WS_EX_LTRLEADING = 0;

  { Tab Control Styles}
  TCS_RIGHT = $0002;
  TCS_BOTTOM = $0002;
  TCS_VERTICAL = $0080;
  TCS_MULTILINE = $0200;
  
{$IFDEF VER1_0}
  ICON_SMALL			       = 0;
  ICON_BIG  			       = 1;
{$ENDIF}

  { BrowseForFolder dialog}
  BIF_RETURNONLYFSDIRS = 1;

  BFFM_INITIALIZED = 1;
  BFFM_SELCHANGED = 2;

  BFFM_SETSELECTION = WM_USER + 102;
  
  {SpinEdit 32 bit messages}
  UDM_GETPOS32 = 1138;
  UDM_GETRANGE32 = 1136;
  UDM_SETPOS32 = 1137;
  UDM_SETRANGE32 = 1135;

  // Listview constants
  LVCFMT_JUSTIFYMASK = LVCFMT_LEFT or LVCFMT_RIGHT or LVCFMT_CENTER;
  LVCFMT_IMAGE            = $0800;
  LVCFMT_BITMAP_ON_RIGHT  = $1000;
  LVCFMT_COL_HAS_IMAGES   = $8000;

  LVCF_IMAGE = $0010;
  LVCF_ORDER = $0020;

  LVM_FIRST                    = $1000;
  LVM_GETHEADER                = LVM_FIRST + 31;
  LVM_SETEXTENDEDLISTVIEWSTYLE = LVM_FIRST + 54;
  LVM_GETEXTENDEDLISTVIEWSTYLE = LVM_FIRST + 55;
  LVM_SETHOVERTIME             = LVM_FIRST + 71;
  LVM_GETHOVERTIME             = LVM_FIRST + 72;

  LVS_TYPEMASK = LVS_ICON  or LVS_SMALLICON or LVS_LIST or LVS_REPORT;

  // Comctl32 version:
  // 4.70
  LVS_EX_GRIDLINES        = $00000001;
  LVS_EX_SUBITEMIMAGES    = $00000002;
  LVS_EX_CHECKBOXES       = $00000004;
  LVS_EX_TRACKSELECT      = $00000008;
  LVS_EX_HEADERDRAGDROP   = $00000010;
  LVS_EX_FULLROWSELECT    = $00000020;
  LVS_EX_ONECLICKACTIVATE = $00000040;
  LVS_EX_TWOCLICKACTIVATE = $00000080;
  // 4.71
  LVS_EX_FLATSB           = $00000100;
  LVS_EX_REGIONAL         = $00000200;
  LVS_EX_INFOTIP          = $00000400;
  LVS_EX_UNDERLINEHOT     = $00000800;
  LVS_EX_UNDERLINECOLD    = $00001000;
  LVS_EX_MULTIWORKAREAS   = $00002000;
  // 5.80
  LVS_EX_LABELTIP         = $00004000;
  // 4.71
  LVS_EX_BORDERSELECT     = $00008000;
  // 6
  LVS_EX_DOUBLEBUFFER     = $00010000;   // TODO: investigate
                                         // this may be a valid (ex) style message for other controls as well
                                         // atleast the same value is used for controls on the .net framework
                                         // coincidence ??
  LVS_EX_HIDELABELS       = $00020000;
  LVS_EX_SINGLEROW        = $00040000;
  LVS_EX_SNAPTOGRID       = $00080000;
  LVS_EX_SIMPLESELECT     = $00100000;
  
// missing listview macros
function ListView_GetHeader(hwndLV: HWND): HWND;
function ListView_GetExtendedListViewStyle(hwndLV: HWND): DWORD;
function ListView_SetExtendedListViewStyle(hwndLV: HWND; dw: DWORD): BOOL;
function ListView_GetHoverTime(hwndLV: HWND): DWORD;
function ListView_SetHoverTime(hwndLV: HWND; dwHoverTimeMs: DWORD): DWORD;



{ Win32 API functions not included in windows.pp }
{ Get the ancestor at level Flag of window HWnd }
Function GetAncestor(Const HWnd: HWND; Const Flag: UINT): HWND; StdCall; External 'user32';
{ Get information about combo box hwndCombo and place in pcbi }
Function GetComboBoxInfo(Const hwndCombo: HWND; pcbi: PCOMBOBOXINFO): BOOL; StdCall; External 'user32';

{ Functions allocate and dealocate memory used in ole32 functions
  e.g. BrowseForFolder dialog functions}
function CoTaskMemAlloc(cb : ULONG) : PVOID; stdcall; external 'ole32.dll' name 'CoTaskMemAlloc';
procedure CoTaskMemFree(pv : PVOID); stdcall; external 'ole32.dll' name 'CoTaskMemFree';

{ Miscellaneous functions }
{ Convert string Str to a PChar }
Function StrToPChar(Const Str: String): PChar;

{ Replace OrigStr with ReplStr in Str }
Function Replace(Const Str, OrigStr, ReplStr: String; Const Global: Boolean): String;

{ Creates a string list limited to Count (-1 for no limit) entries by splitting
  Str into substrings around SplitStr }
Function Split(Const Str: String; SplitStr: String; Count: Integer; Const CaseSensitive: Boolean): TStringList;

Implementation

Uses SysUtils;

{$PACKRECORDS NORMAL}

function ListView_GetHeader(hwndLV: HWND): HWND;
begin
  Result := SendMessage(hwndLV, LVM_GETHEADER, 0, 0);
end;

function ListView_GetExtendedListViewStyle(hwndLV: HWND): DWORD;
begin
  Result := SendMessage(hwndLV, LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0);
end;

function ListView_SetExtendedListViewStyle(hwndLV: HWND; dw: DWORD): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, dw));
end;

function ListView_GetHoverTime(hwndLV: HWND): DWORD;
begin
  Result := SendMessage(hwndLV, LVM_GETHOVERTIME, 0, 0);
end;

function ListView_SetHoverTime(hwndLV: HWND; dwHoverTimeMs: DWORD): DWORD;
begin
  Result := SendMessage(hwndLV, LVM_SETHOVERTIME, 0, dwHoverTimeMs);
end;



Var
  TmpStr: PChar;

Function StrToPChar(Const Str: String): PChar;
Begin
  TmpStr := PChar(Str);
  Result := TmpStr;
End;

Function Replace(Const Str, OrigStr, ReplStr: String; Const Global: Boolean): String;
Var
  InsPt: Integer;
Begin
  Result := Str;
  Repeat
    InsPt := Pos(OrigStr, Result);
    If InsPt <> 0 Then
    Begin
      Delete(Result, InsPt, Length(OrigStr));
      Insert(ReplStr, Result, InsPt);
    End;

    If Not Global Then
      Break;
  Until InsPt = 0;
End;

Function Split(Const Str: String; SplitStr: String; Count: Integer;
  Const CaseSensitive: Boolean): TStringList;
Var
  LastP, P: Integer;
  OrigCt: Integer;
  S: String;
Begin
  Result := TStringList.Create;
  OrigCt := Count;
  If Not CaseSensitive Then
  Begin
    S := LowerCase(Str);
    SplitStr := LowerCase(SplitStr);
  End
  Else
    S := Str;
  P := Pos(SplitStr, Str);
  LastP:=0;
  Repeat
    S := Copy(S, P + 1, Length(S));
    Result.Capacity := Result.Count;
    Result.Add(Copy(Str, LastP + 1, P - 1));
    P := Pos(SplitStr, S);
    LastP := P;
    If Count > 0 Then
      Dec(Count)
  Until (P = 0) Or (Count = 0);
  If OrigCt <> 0 Then
  Begin
    Result.Capacity := Result.Count;
    Result.Add(Copy(Str, (Length(Str) - Length(S)) + 1, Pos(SplitStr, Str) - 1));
  End;
End;

Initialization

TmpStr := StrNew('');

Finalization

Try
  StrDispose(TmpStr);
  TmpStr := Nil;
Except
  On E: Exception Do
    Assert(False, Format('Trace:Could not deallocate string --> %S', [E.Message]));
End;

End.
