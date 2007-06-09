{ $Id$}
{
 *****************************************************************************
 *                              Win32WSMenus.pp                              *
 *                              ---------------                              *
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
unit Win32WSMenus;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Menus, Forms,
////////////////////////////////////////////////////
  WSMenus, WSLCLClasses,
  Windows, Controls, Classes, SysUtils, Win32Int, Win32Proc, InterfaceBase, LCLProc;

type

  { TWin32WSMenuItem }

  TWin32WSMenuItem = class(TWSMenuItem)
  private
  protected
  public
    class procedure AttachMenu(const AMenuItem: TMenuItem); override;
    class function  CreateHandle(const AMenuItem: TMenuItem): HMENU; override;
    class procedure DestroyHandle(const AMenuItem: TMenuItem); override;
    class procedure SetCaption(const AMenuItem: TMenuItem; const ACaption: string); override;
    class procedure SetShortCut(const AMenuItem: TMenuItem; const OldShortCut, NewShortCut: TShortCut); override;
    class function SetEnable(const AMenuItem: TMenuItem; const Enabled: boolean): boolean; override;
    class function SetRightJustify(const AMenuItem: TMenuItem; const Justified: boolean): boolean; override;
  end;

  { TWin32WSMenu }

  TWin32WSMenu = class(TWSMenu)
  private
  protected
  public
    class function  CreateHandle(const AMenu: TMenu): HMENU; override;
  end;

  { TWin32WSMainMenu }

  TWin32WSMainMenu = class(TWSMainMenu)
  private
  protected
  public
  end;

  { TWin32WSPopupMenu }

  TWin32WSPopupMenu = class(TWSPopupMenu)
  private
  protected
  public
    class function  CreateHandle(const AMenu: TMenu): HMENU; override;
    class procedure Popup(const APopupMenu: TPopupMenu; const X, Y: integer); override;
  end;

  function MenuItemSize(aMenuItem: TMenuItem; aHDC: HDC): TSize;  
  procedure DrawMenuItem(const aMenuItem: TMenuItem; const aHDC: HDC; const aRect: Windows.RECT; const aSelected: boolean);
  function FindMenuItemAccelerator(const ACharCode: char; const AMenuHandle: HMENU): integer;


implementation

uses strutils;

{ helper routines }

const
  SpaceBetweenIcons = 5;

  // define the size of the MENUITEMINFO structure used by older Windows
  // versions (95, NT4) to keep the kompatibility with them
  // Since W98 the size is 48 (hbmpItem was added)
  W95_MENUITEMINFO_SIZE = 44;

var
  menuiteminfosize : DWORD = 0;

type
  TCaptionFlags = (cfBold, cfUnderline);
  TCaptionFlagsSet = set of TCaptionFlags;

(* Returns index of the character in the menu item caption that is displayed
   as underlined and is therefore the hot key of the menu item.
   If the caption does not contain any underlined character, 0 is returned.
   If there are more "underscored" characters in the caption, the last one is returned.
   Does some Windows API function exists which can do the same?
   AnUnderlinedChar - character which tells that tne following character should be underlined
   ACaption - menu item caption which is parsed *)
function SearchMenuItemHotKeyIndex(const AnUnderlinedChar: char; ACaption: string): integer;
var position: integer;
begin
  position := pos(AnUnderlinedChar, ACaption);
  Result := 0;
  // if aChar is on the last position then there is nothing to underscore, ignore this character
  while (position > 0) and (position < length(ACaption)) do
  begin
    // two 'AnUnderlinedChar' characters together are not valid hot key, they are replaced by one
    if ACaption[position + 1] <> AnUnderlinedChar then
      Result := position + 1;
    position := posEx(AnUnderlinedChar, ACaption, position + 2);
  end;
end;

function FindMenuItemAccelerator(const ACharCode: char; const AMenuHandle: HMENU): integer;
var MenuItemIndex: integer;
    ItemInfo: MENUITEMINFO;
    FirstMenuItem: TMenuItem;
    SiblingMenuItem: TmenuItem;
    HotKeyIndex: integer;
    i: integer;
begin
  Result := MakeLResult(0, 0);
  MenuItemIndex := -1;
  ItemInfo.cbSize := menuiteminfosize;
  ItemInfo.fMask := MIIM_DATA;
  if not GetMenuItemInfo(AMenuHandle, 0, true, @ItemInfo) then Exit;
  FirstMenuItem := TMenuItem(ItemInfo.dwItemData);
  if FirstMenuItem = nil then exit;
  i := 0;
  while (i < FirstMenuItem.Parent.Count) and (MenuItemIndex < 0) do
  begin
    SiblingMenuItem := FirstMenuItem.Parent.Items[i];
    HotKeyIndex := SearchMenuItemHotKeyIndex('&', SiblingMenuItem.Caption);
    if (HotKeyIndex > 0) and
      (Upcase(ACharCode) = Upcase(SiblingMenuItem.Caption[HotKeyIndex])) then
        MenuItemIndex := i;
    inc(i);
  end;
  if MenuItemIndex > -1 then Result := MakeLResult(MenuItemIndex, 2)
  else Result := MakeLResult(0, 0);
end;


function GetMenuItemFont(const aFlags: TCaptionFlagsSet): HFONT;
var 
  lf: LOGFONT;
  ncm: NONCLIENTMETRICS;
begin
  ncm.cbSize:= sizeof(ncm);
  if SystemParametersInfo(SPI_GETNONCLIENTMETRICS, sizeof(ncm), @ncm, 0) then
    lf:= ncm.lfMenuFont
  else
    GetObject(GetStockObject(DEFAULT_GUI_FONT), sizeof(LOGFONT), @lf);
  if cfUnderline in aFlags then lf.lfUnderline := 1
  else lf.lfUnderline := 0;
  if cfBold in aFlags then
  begin
    if lf.lfWeight<=400 then
      lf.lfWeight:= lf.lfWeight + 300
    else
      lf.lfWeight:= lf.lfWeight + 100;
  end;
  Result := CreateFontIndirect(@lf);
end;

(* Get the menu item caption including shortcut *)
function CompleteMenuItemCaption(const aMenuItem: TMenuItem): string;
begin
  Result := aMenuItem.Caption;
  if aMenuItem.shortCut <> scNone then
    Result := Result  + ShortCutToText(aMenuItem.shortCut);
end;

(* Get the maximum length of the given string in pixels *)
function StringSize(const aCaption: String; const aHDC: HDC; const aDecoration:TCaptionFlagsSet): TSize;
var oldFont: HFONT;
    newFont: HFONT;
    tmpRect: Windows.RECT;
begin
  tmpRect.right := 0;
  tmpRect.left := 0;
  newFont := getMenuItemFont(aDecoration);
  oldFont := SelectObject(aHDC, newFont);
  DrawText(aHDC, pChar(aCaption), length(aCaption), @TmpRect, DT_CALCRECT);
  SelectObject(aHDC, oldFont);
  DeleteObject(newFont);
  Result.cx := TmpRect.right - TmpRect.left;
  Result.cy := TmpRect.Bottom - TmpRect.Top;
end;
  
function LeftIconPosition: integer;
begin
  Result := GetSystemMetrics(SM_CXMENUCHECK);
end;

function MenuIconWidth(const AMenuItem: TMenuItem): integer;
var
  SiblingMenuItem : TMenuItem;
  i : integer;
  RequiredWidth: integer;
begin
  Result := 0;
  for i:= 0 to AMenuItem.Parent.Count -1 do begin
    SiblingMenuItem := AMenuItem.Parent.Items[i];
    if SiblingMenuItem.HasIcon then begin
      RequiredWidth := SiblingMenuItem.Bitmap.Width;
      if RequiredWidth > Result then
        Result := RequiredWidth;
    end;
  end;
  Result := Result + LeftIconPosition;
end;

function MenuItemSize(aMenuItem: TMenuItem; aHDC: HDC): TSize;
var
  decoration: TCaptionFlagsSet;
  minimumHeight: Integer;
begin
  if aMenuItem.Default then
    decoration := [cfBold]
  else
    decoration := [];
  Result := StringSize(CompleteMenuItemCaption(aMenuItem), aHDC, decoration);
  if not aMenuItem.IsInMenuBar then
    Inc(Result.cx, MenuIconWidth(aMenuItem) + (2 * spaceBetweenIcons));
  if aMenuItem.ShortCut <> scNone then
    Inc(Result.cx, spaceBetweenIcons);
	
  minimumHeight := GetSystemMetrics(SM_CYMENU);
  if not aMenuItem.IsInMenuBar then
    Dec(minimumHeight, 2);
  if aMenuItem.IsLine then
    Result.cy := 10 // it is a separator
  else
  begin
    if aMenuItem.hasIcon and (aMenuItem.bitmap.height > Result.cy) then
      Result.cy := aMenuItem.bitmap.height;
    Inc(Result.cy, 2);
    if Result.cy < minimumHeight then
      Result.cy := minimumHeight;
  end;
end;

function LeftCaptionPosition(const aMenuItemLength: integer; const anElementLength: integer; const AMenuItem: TMenuItem): integer;
begin
  if AMenuItem.IsInMenuBar then Result := (aMenuItemLength - anElementLength) div 2
  else Result := MenuIconWidth(AMenuItem) + SpaceBetweenIcons;
end;

function TopPosition(const aMenuItemHeight: integer; const anElementHeight: integer): integer;
begin
  Result := (aMenuItemHeight - anElementHeight) div 2;
end;

function BackgroundColorMenu(const aSelected: boolean; const aInMainMenu: boolean): COLORREF;
var IsFlatMenu: Windows.BOOL;
begin
  if aSelected then
    Result := GetSysColor(COLOR_HIGHLIGHT)
  // SPI_GETFLATMENU = 0x1022, it is not yet defined in the FPC
  else if aInMainMenu and (SystemParametersInfo($1022, 0, @IsFlatMenu, 0)) and IsFlatMenu then // COLOR_MENUBAR is not supported on Windows version < XP
    Result := GetSysColor(COLOR_MENUBAR)
  else
    Result := GetSysColor(COLOR_MENU);
end;

function TextColorMenu(const aSelected: boolean; const anEnabled: boolean): COLORREF;
begin
  if anEnabled then
  begin
    if aSelected then
      Result := GetSysColor(COLOR_HIGHLIGHTTEXT)
    else
      Result := GetSysColor(COLOR_MENUTEXT);
  end else
    Result := GetSysColor(COLOR_GRAYTEXT);
end;

procedure DrawSeparator(const aHDC: HDC; const aRect: Windows.RECT);
var separatorRect: Windows.RECT;
begin
  separatorRect.left := aRect.left;
  separatorRect.right := aRect.right;
  separatorRect.top := aRect.top + (aRect.bottom - aRect.top) div 2 - 1;
  separatorRect.bottom := separatorRect.top + 2;
  DrawEdge(aHDC, separatorRect, BDR_SUNKENOUTER, BF_RECT);
end;

procedure DrawMenuItemCheckMark(const aMenuItem: TMenuItem; const aHDC: HDC; const aRect: Windows.RECT; const aSelected: boolean);
var checkMarkWidth: integer;
    checkMarkHeight: integer;
    hdcMem: HDC;
    monoBitmap: HBITMAP;
    oldBitmap: HBITMAP;
    checkMarkShape: integer;
    checkMarkRect: Windows.RECT;
begin
  hdcMem := CreateCompatibleDC(aHDC);
  checkMarkWidth := GetSystemMetrics(SM_CXMENUCHECK);
  checkMarkHeight := GetSystemMetrics(SM_CYMENUCHECK);
  monoBitmap := CreateBitmap(checkMarkWidth, checkMarkHeight, 1, 1, nil);
  oldBitmap := SelectObject(hdcMem, monoBitmap);
  checkMarkRect.left := 0;
  checkMarkRect.top := 0;
  checkMarkRect.right := checkMarkWidth;
  checkMarkRect.bottom := checkMarkHeight;
  if aMenuItem.RadioItem then checkMarkShape := DFCS_MENUBULLET
  else checkMarkShape := DFCS_MENUCHECK;
  DrawFrameControl(hdcMem, @checkMarkRect, DFC_MENU, checkMarkShape);
  BitBlt(aHDC, aRect.left, aRect.top + topPosition(aRect.bottom - aRect.top, checkMarkRect.bottom - checkMarkRect.top), checkMarkWidth, checkMarkHeight, hdcMem, 0, 0, SRCCOPY);
  SelectObject(hdcMem, oldBitmap);
  DeleteObject(monoBitmap);
  DeleteDC(hdcMem);
end;

procedure DrawMenuItemText(const aMenuItem: TMenuItem; const aHDC: HDC; aRect: Windows.RECT; const aSelected: boolean);
var crText: COLORREF;
    crBkgnd: COLORREF;
    TmpLength: integer;
    TmpHeight: integer;
    oldFont: HFONT;
    newFont: HFONT;
    decoration: TCaptionFlagsSet;
	shortCutText: string;
	WorkRect: Windows.RECT;
begin
  crText := TextColorMenu(aSelected, aMenuItem.Enabled);
  crBkgnd := BackgroundColorMenu(aSelected, aMenuItem.IsInMenuBar);
  SetTextColor(aHDC, crText);
  SetBkColor(aHDC, crBkgnd);
  if aMenuItem.Default then decoration := [cfBold]
  else decoration := [];
  newFont := getMenuItemFont(decoration);
  oldFont := SelectObject(aHDC, newFont);
  ExtTextOut(aHDC, 0, 0, ETO_OPAQUE, @aRect, PChar(''), 0, nil);
  TmpLength := aRect.right - aRect.left;
  TmpHeight := aRect.bottom - aRect.top;
  DrawText(aHDC, pChar(aMenuItem.Caption), length(aMenuItem.Caption), @WorkRect, DT_CALCRECT);
  Inc(aRect.Left, leftCaptionPosition(TmpLength, WorkRect.Right - WorkRect.Left, aMenuItem));
  Inc(aRect.Top, topPosition(TmpHeight, WorkRect.Bottom - WorkRect.Top));
  DrawText(aHDC, pChar(aMenuItem.Caption), length(aMenuItem.Caption), @aRect, 0);
  if aMenuItem.ShortCut <> scNone then
  begin
    shortCutText := ShortCutToText(aMenuItem.ShortCut);
    Dec(aRect.Right, GetSystemMetrics(SM_CXMENUCHECK));	
	DrawText(aHDC, pChar(shortCutText), Length(shortCutText), @aRect, DT_RIGHT);
  end;
  SelectObject(aHDC, oldFont);
  DeleteObject(newFont);
end;

procedure DrawMenuItemIcon(const aMenuItem: TMenuItem; const aHDC: HDC; const aRect: Windows.RECT; const aSelected: boolean);
var
  hdcMem: HDC;
  hbmpOld: HBITMAP;
begin
  // dont remove this with or you'll get n-times bitmap copying from imagelist into menu bitmap
  with aMenuItem.Bitmap do
  begin
    hdcMem := Canvas.Handle;
    hbmpOld := SelectObject(hdcMem, Handle);
    TWin32WidgetSet(WidgetSet).MaskBlt(aHDC, aRect.left + LeftIconPosition, aRect.top + TopPosition(aRect.bottom - aRect.top, Height), Width, Height, hdcMem, 0, 0, MaskHandle, 0, 0);
    SelectObject(hdcMem, hbmpOld);
  end;
end;

procedure DrawMenuItem(const aMenuItem: TMenuItem; const aHDC: HDC; const aRect: Windows.RECT; const aSelected: boolean);
begin
  if aMenuItem.IsLine then
    DrawSeparator(aHDC, aRect)
  else begin
    DrawMenuItemText(aMenuItem, aHDC, aRect, aSelected);
    if aMenuItem.Checked then
      DrawMenuItemCheckMark(aMenuItem, aHDC, aRect, aSelected);
    if aMenuItem.hasIcon then
      DrawMenuItemIcon(aMenuItem, aHDC, aRect, aSelected);
  end;
end;


procedure TriggerFormUpdate(const AMenuItem: TMenuItem);
var
  lMenu: TMenu;
begin
  lMenu := AMenuItem.GetParentMenu;
  if (lMenu<>nil) and (lMenu.Parent<>nil)
  and (lMenu.Parent is TCustomForm)
  and TCustomForm(lMenu.Parent).HandleAllocated
  and not (csDestroying in lMenu.Parent.ComponentState) then
    AddToChangedMenus(TCustomForm(lMenu.Parent).Handle);
end;

function ChangeMenuFlag(const AMenuItem: TMenuItem; Flag: Integer; Value: boolean): boolean;
var
  MenuInfo: MENUITEMINFO;
begin
  MenuInfo.cbSize := menuiteminfosize;
  MenuInfo.fMask := MIIM_TYPE;
  MenuInfo.dwTypeData := nil;  // don't retrieve caption
  GetMenuItemInfo(AMenuItem.Parent.Handle, AMenuItem.Command, false, @MenuInfo);
  if Value then
    MenuInfo.fType := MenuInfo.fType or Flag
  else
    MenuInfo.fType := MenuInfo.fType and (not Flag);
  MenuInfo.dwTypeData := LPSTR(AMenuItem.Caption);
  Result := SetMenuItemInfo(AMenuItem.Parent.Handle, AMenuItem.Command, false, @MenuInfo);
  TriggerFormUpdate(AMenuItem);
end;

{ TWin32WSMenuItem }

procedure UpdateCaption(const AMenuItem: TMenuItem; ACaption: String);
var
  MenuInfo: MENUITEMINFO;
begin
  with MenuInfo do
  begin
    cbsize := menuiteminfosize;
    if ACaption <> '-' then
    begin
      fType := MFT_STRING;
      fMask:=MIIM_TYPE;
      dwTypeData:=LPSTR(ACaption);
      cch := StrLen(dwTypeData);
    end
    else fType := MFT_SEPARATOR;
  end;
  SetMenuItemInfo(AMenuItem.Parent.Handle, AMenuItem.Command, false, @MenuInfo);
  with MenuInfo do
  begin
    cbsize := menuiteminfosize;
    fMask := MIIM_TYPE;
    fType := MFT_OWNERDRAW;
    dwTypeData:=LPSTR(ACaption);
    cch := StrLen(dwTypeData);
  end;
  SetMenuItemInfo(AMenuItem.Parent.Handle, AMenuItem.Command, false, @MenuInfo);
  TriggerFormUpdate(AMenuItem);
end;

class procedure TWin32WSMenuItem.AttachMenu(const AMenuItem: TMenuItem);
var
  MenuInfo: MENUITEMINFO;
  ParentMenuHandle: HMenu;
  ParentOfParent: HMenu;
begin
  ParentMenuHandle := AMenuItem.Parent.Handle;

  {Following part fixes the case when an item is added in runtime
  but the parent item has not defined the submenu flag (hSubmenu=0) }
  if AMenuItem.Parent.Parent<>nil then
  begin
    ParentOfParent := AMenuItem.Parent.Parent.Handle;
    with MenuInfo do begin
      cbSize := menuiteminfosize;
      fMask:=MIIM_SUBMENU;
    end;
    GetMenuItemInfo(ParentOfParent, AMenuItem.Parent.Command,
                    false, @MenuInfo);
    if MenuInfo.hSubmenu=0 then // the parent menu item is not yet defined with submenu flag
    begin
      MenuInfo.hSubmenu:=ParentMenuHandle;
      SetMenuItemInfo(ParentOfParent, AMenuItem.Parent.Command,
                      false, @MenuInfo);
    end;
  end;

  with MenuInfo do begin
    cbsize := menuiteminfosize;
    if AMenuItem.Enabled then fState:=MFS_ENABLED else fstate:=MFS_GRAYED;
    if AMenuItem.Checked then fState:=fState or MFS_CHECKED;
    fMask:=MIIM_ID or MIIM_DATA or MIIM_STATE or MIIM_TYPE;
    wID:=AMenuItem.Command; {value may only be 16 bit wide!}
    dwItemData:=PtrInt(AMenuItem);
    if (AMenuItem.Count > 0) then
    begin
      fMask := fMask or MIIM_SUBMENU;
      hSubMenu := AMenuItem.Handle;
    end else
      hSubMenu := 0;
    if not AMenuItem.IsLine then
    begin
      fType:=MFT_OWNERDRAW;
    end else begin
      fType:=MFT_OWNERDRAW or MFT_SEPARATOR;
      fState:=fState or MFS_DISABLED;
    end;
    dwTypeData := PChar(AMenuItem);
    if AMenuItem.RadioItem then fType := fType or MFT_RADIOCHECK;
    if AMenuItem.RightJustify then fType := fType or MFT_RIGHTJUSTIFY;
  end;
  if dword(InsertMenuItem(ParentMenuHandle,
       AMenuItem.Parent.VisibleIndexOf(AMenuItem), true, @MenuInfo)) = 0 then
    DebugLn('InsertMenuItem failed with error: ', IntToStr(Windows.GetLastError));
  TriggerFormUpdate(AMenuItem);
end;

class function TWin32WSMenuItem.CreateHandle(const AMenuItem: TMenuItem): HMENU;
begin
  Result := CreatePopupMenu;
end;

class procedure TWin32WSMenuItem.DestroyHandle(const AMenuItem: TMenuItem);
begin
  if Assigned(AMenuItem.Parent) then
    DeleteMenu(AMenuItem.Parent.Handle, AMenuItem.Command, MF_BYCOMMAND);
  DestroyMenu(AMenuItem.Handle);
  TriggerFormUpdate(AMenuItem);
end;

class procedure TWin32WSMenuItem.SetCaption(const AMenuItem: TMenuItem; const ACaption: string);
begin
  UpdateCaption(AMenuItem, aCaption);
end;

class procedure TWin32WSMenuItem.SetShortCut(const AMenuItem: TMenuItem;
  const OldShortCut, NewShortCut: TShortCut);
begin
  UpdateCaption(AMenuItem, aMenuItem.Caption);
end;

class function TWin32WSMenuItem.SetEnable(const AMenuItem: TMenuItem; const Enabled: boolean): boolean;
var
  EnableFlag: Integer;
begin
  if Enabled then EnableFlag := MF_ENABLED
  else EnableFlag := MF_GRAYED;
  EnableFlag := EnableFlag or MF_BYCOMMAND;
  Result := Boolean(Windows.EnableMenuItem(AMenuItem.Parent.Handle, AMenuItem.Command, EnableFlag));
  TriggerFormUpdate(AMenuItem);
end;

class function TWin32WSMenuItem.SetRightJustify(const AMenuItem: TMenuItem; const Justified: boolean): boolean;
begin
  Result := ChangeMenuFlag(AMenuItem, MFT_RIGHTJUSTIFY, Justified);
end;


{ TWin32WSMenu }

class function TWin32WSMenu.CreateHandle(const AMenu: TMenu): HMENU;
begin
  Result := CreateMenu;
end;

{ TWin32WSPopupMenu }

class function TWin32WSPopupMenu.CreateHandle(const AMenu: TMenu): HMENU;
begin
  Result := CreatePopupMenu;
end;

class procedure TWin32WSPopupMenu.Popup(const APopupMenu: TPopupMenu; const X, Y: integer);
var
  MenuHandle: HMENU;
  AppHandle: HWND;
begin
  MenuHandle := APopupMenu.Handle;
  AppHandle := TWin32WidgetSet(WidgetSet).AppHandle;
  GetWindowInfo(AppHandle)^.PopupMenu := APopupMenu;
  TrackPopupMenuEx(MenuHandle, TPM_LEFTALIGN or TPM_LEFTBUTTON or TPM_RIGHTBUTTON,
    X, Y, AppHandle, Nil);
end;

initialization
  if (Win32MajorVersion=4) and (Win32MinorVersion=0) then
    menuiteminfosize:=W95_MENUITEMINFO_SIZE
  else
    menuiteminfosize:=sizeof(TMenuItemInfo);

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TMenuItem, TWin32WSMenuItem);
  RegisterWSComponent(TMenu, TWin32WSMenu);
//  RegisterWSComponent(TMainMenu, TWin32WSMainMenu);
  RegisterWSComponent(TPopupMenu, TWin32WSPopupMenu);
////////////////////////////////////////////////////
end.
