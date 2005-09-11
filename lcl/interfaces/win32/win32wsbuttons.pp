{ $Id$}
{
 *****************************************************************************
 *                             Win32WSButtons.pp                             * 
 *                             -----------------                             * 
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
unit Win32WSButtons;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Windows, Buttons, Graphics, Controls,
////////////////////////////////////////////////////
  WSControls, WSButtons, WSLCLClasses, Win32WSControls, LCLType;

type

  { TWin32WSButton }

  TWin32WSButton = class(TWSButton)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure ActiveDefaultButtonChanged(const AButton: TCustomButton); override;
    class procedure SetShortCut(const AButton: TCustomButton; const OldKey, NewKey: word); override;
  end;

  { TWin32WSBitBtn }

  TWin32WSBitBtn = class(TWSBitBtn)
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure SetBounds(const AWinControl: TWinControl;
          const ALeft, ATop, AWidth, AHeight: integer); override;
    class procedure SetGlyph(const ABitBtn: TCustomBitBtn; const AValue: TBitmap); override;
    class procedure SetLayout(const ABitBtn: TCustomBitBtn; const AValue: TButtonLayout); override;
    class procedure SetMargin(const ABitBtn: TCustomBitBtn; const AValue: Integer); override;
    class procedure SetSpacing(const ABitBtn: TCustomBitBtn; const AValue: Integer); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: string); override;
  end;

  { TWin32WSSpeedButton }

  TWin32WSSpeedButton = class(TWSSpeedButton)
  private
  protected
  public
  end;

procedure DrawBitBtnImage(BitBtn: TCustomBitBtn; ButtonCaption: PChar);

implementation

uses
  Win32Int, InterfaceBase;

{ TWin32WSButton }

function TWin32WSButton.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    if TCustomButton(AWinControl).Default Then
      Flags := Flags or BS_DEFPUSHBUTTON
    else
      Flags := Flags or BS_PUSHBUTTON;
    pClassName := 'BUTTON';
    WindowTitle := StrCaption;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;
end;

procedure TWin32WSButton.ActiveDefaultButtonChanged(const AButton: TCustomButton);
var
  WindowStyle: dword;
begin
  WindowStyle := Windows.GetWindowLong(AButton.Handle, GWL_STYLE) and not (BS_DEFPUSHBUTTON or BS_PUSHBUTTON);
  If AButton.Active then
    WindowStyle := WindowStyle or BS_DEFPUSHBUTTON
  else
    WindowStyle := WindowStyle or BS_PUSHBUTTON;
  Windows.SendMessage(AButton.Handle, BM_SETSTYLE, WindowStyle, 1);
end;

procedure TWin32WSButton.SetShortCut(const AButton: TCustomButton; const OldKey, NewKey: word);
begin
  // TODO: implement me!
end;

{ TWin32WSBitBtn }

const
  BUTTON_IMAGELIST_ALIGN_LEFT   = 0;
  BUTTON_IMAGELIST_ALIGN_RIGHT  = 1;
  BUTTON_IMAGELIST_ALIGN_TOP    = 2;
  BUTTON_IMAGELIST_ALIGN_BOTTOM = 3;
  BUTTON_IMAGELIST_ALIGN_CENTER = 4;

  BCM_FIRST = $1600;
  BCM_GETIDEALSIZE  = BCM_FIRST + 1;
  BCM_SETIMAGELIST  = BCM_FIRST + 2;
  BCM_GETIMAGELIST  = BCM_FIRST + 3;
  BCM_SETTEXTMARGIN = BCM_FIRST + 4;
  BCM_GETTEXTMARGIN = BCM_FIRST + 5;

  { - you do need to destroy the imagelist yourself. 
    - you'll need 5 images to support all themed xp button states...

    Image 0 = normal
    Image 1 = mouse hover
    Image 2 = button down
    Image 3 = button disabled
    Image 4 = button focus       
  }

  XPBitBtn_ImageIndexToEnabled: array[1..6] of Boolean = 
    (true, true, true, false, true, true);
  
type
  BUTTON_IMAGELIST = packed record
    himl: Windows.HIMAGELIST;
    margin: Windows.RECT;
    uAlign: UINT;
  end;

{------------------------------------------------------------------------------
  Method: DrawBitBtnImage
  Params:  BitBtn: The TCustomBitBtn to update the image of
           ButtonCaption: new button caption
  Returns: Nothing

  Updates the button image combining the glyph and caption
 ------------------------------------------------------------------------------}
procedure DrawBitBtnImage(BitBtn: TCustomBitBtn; ButtonCaption: PChar);
var
  BitmapHandle: HBITMAP; // Handle of the button glyph
  BitBtnLayout: TButtonLayout; // Layout of button and glyph
  BitBtnHandle: HWND; // Handle to bitbtn window
  BitBtnDC: HDC; // Handle to DC of bitbtn window
  OldFontHandle: HFONT; // Handle of previous font in hdcNewBitmap
  hdcNewBitmap: HDC; // Device context of the new Bitmap
  BitmapInfo: BITMAP; // Buffer for bitmap
  TextSize: Windows.SIZE; // For computing the length of button caption in pixels
  OldBitmap: HBITMAP; // Handle to the old selected bitmap
  NewBitmap: HBITMAP; // Handle of the new bitmap
  XDestBitmap, YDestBitmap: integer; // X,Y coordinate of destination rectangle for bitmap
  XDestText, YDestText: integer; // X,Y coordinates of destination rectangle for caption
  newWidth, newHeight: integer; // dimensions of new combined bitmap
  BitmapRect: Windows.RECT;
  oldImageList: HIMAGELIST;
  ButtonImageList: BUTTON_IMAGELIST;
  I: integer;

  procedure DrawBitmap(Enabled: boolean);
  var
    SrcDC, MaskDC, MonoDC: HDC;
    MaskBmp, MonoBmp, OldSrcBmp, OldMaskBmp, OldMonoBmp: HBITMAP;
    BkColor: TColorRef;
    
    OldBitmapHandle: HBITMAP; // Handle of the provious bitmap in hdcNewBitmap
    TextFlags: integer; // flags for caption (enabled or disabled)
    themesActive: boolean;
  begin
    TextFlags := DST_PREFIXTEXT;

    OldBitmapHandle := SelectObject(hdcNewBitmap, NewBitmap);
    MaskDC := CreateCompatibleDC(hdcNewBitmap);
    if BitBtn.Glyph.MaskHandleAllocated then
    begin
      // Create a mask DC
      MaskBmp := CreateCompatibleBitmap(hdcNewBitmap, BitmapInfo.bmWidth, BitmapInfo.bmHeight);
      OldMaskBmp := SelectObject(MaskDC, MaskBmp);
      SrcDC := CreateCompatibleDC(hdcNewBitmap);
      OldSrcBmp := SelectObject(SrcDC, BitmapHandle);
      FillRect(MaskDC, BitmapRect, BitBtn.Brush.Handle);
      TWin32WidgetSet(WidgetSet).MaskBlt(MaskDC, 0, 0, BitmapInfo.bmWidth, BitmapInfo.bmHeight, SrcDC, 
        0, 0, BitBtn.Glyph.MaskHandle, 0, 0);
    end else begin
      MaskBmp := BitmapHandle;
      OldMaskBmp := SelectObject(MaskDC, MaskBmp);
    end;
       
    // fill with background color
    Windows.FillRect(hdcNewBitmap, BitmapRect, BitBtn.Brush.Handle);
    if Enabled then 
    begin
      if MaskBmp <> 0 then 
        BitBlt(hdcNewBitmap, XDestBitmap, YDestBitmap, BitmapInfo.bmWidth, 
          BitmapInfo.bmHeight, MaskDC, 0, 0, SRCCOPY);
    end else begin
      TextFlags := TextFlags or DSS_DISABLED;
      // when not themed, windows wants a white background picture for disabled button image
      themesActive := TWin32WidgetSet(WidgetSet).ThemesActive;
      if not themesActive then
        FillRect(hdcNewBitmap, BitmapRect, GetStockObject(WHITE_BRUSH));
      if BitmapHandle <> 0 then 
      begin
        // Create a Mono DC
        MonoBmp := CreateBitmap(BitmapInfo.bmWidth, BitmapInfo.bmHeight, 1, 1, nil);
        MonoDC := CreateCompatibleDC(hdcNewBitmap);
        OldMonoBmp := SelectObject(MonoDC, MonoBmp);
        // Create the black and white image
        BkColor := SetBkColor(MaskDC, ColorToRGB(BitBtn.Brush.Color));
        BitBlt(MonoDC, 0, 0, BitmapInfo.bmWidth, BitmapInfo.bmHeight, MaskDC, 0, 0, SRCCOPY);
        SetBkColor(MaskDC, BkColor);
        if themesActive then
        begin
          // non-themed winapi wants white/other as background/picture-disabled colors
          // themed winapi draws bitmap-as, with transparency defined by bitbtn.brush color
          BkColor := SetBkColor(hdcNewBitmap, ColorToRGB(BitBtn.Brush.Color));
          SetTextColor(hdcNewBitmap, GetSysColor(COLOR_BTNSHADOW));
        end;
        // Draw the black and white image
        BitBlt(hdcNewBitmap, XDestBitmap, YDestBitmap, BitmapInfo.bmWidth, BitmapInfo.bmHeight,
               MonoDC, 0, 0, SRCCOPY);  
  
        SelectObject(MonoDC, OldMonoBmp);
        DeleteDC(MonoDC);
        DeleteObject(MonoBmp);
      end;  
    end;
    
    if BitBtn.Glyph.MaskHandleAllocated then
    begin
      SelectObject(SrcDC, OldSrcBmp);
      DeleteDC(SrcDC);
      DeleteObject(MaskBmp);
    end;
    SelectObject(MaskDC, OldMaskBmp);
    DeleteDC(MaskDC);

    SetBkMode(hdcNewBitmap, TRANSPARENT);
    SetTextColor(hdcNewBitmap, 0);
    DrawState(hdcNewBitmap, 0, nil, LPARAM(ButtonCaption), 0, XDestText, YDestText, 0, 0, TextFlags);
    SelectObject(hdcNewBitmap, OldBitmapHandle);
  end;
  
begin
  // gather info about bitbtn
  BitBtnHandle := BitBtn.Handle;
  if BitBtn.Glyph.Empty then
  begin
    BitmapHandle := 0;
    BitmapInfo.bmWidth := 0;
    BitmapInfo.bmHeight := 0;
  end else begin
    BitmapHandle := BitBtn.Glyph.Handle;
    Windows.GetObject(BitmapHandle, sizeof(BitmapInfo), @BitmapInfo);
  end;
  BitBtnLayout := BitBtn.Layout;
  BitBtnDC := GetDC(BitBtnHandle);
  hdcNewBitmap := CreateCompatibleDC(BitBtnDC);
  OldFontHandle := SelectObject(hdcNewBitmap, BitBtn.Font.Handle);
  GetTextExtentPoint32(hdcNewBitmap, LPSTR(ButtonCaption), Length(ButtonCaption), TextSize);
  // calculate size of new bitmap
  case BitBtnLayout of
    blGlyphLeft, blGlyphRight:
    begin
      if BitBtn.Spacing = -1 then
        newWidth := BitBtn.Width - 10
      else
        newWidth := TextSize.cx + BitmapInfo.bmWidth + BitBtn.Spacing;
      if BitmapHandle <> 0 then
        inc(newWidth, 2);
      newHeight := TextSize.cy;
      if newHeight < BitmapInfo.bmHeight then
        newHeight := BitmapInfo.bmHeight;
      YDestBitmap := (newHeight - BitmapInfo.bmHeight) div 2;
      YDestText := (newHeight - TextSize.cy) div 2;
      case BitBtnLayout of
        blGlyphLeft: 
        begin
          XDestBitmap := 0;
          XDestText := BitmapInfo.bmWidth;
          if BitBtn.Spacing = -1 then
            inc(XDestText, (newWidth - BitmapInfo.bmWidth - TextSize.cx) div 2)
          else
            inc(XDestText, BitBtn.Spacing);
        end;
        blGlyphRight: 
        begin
          XDestBitmap := newWidth - BitmapInfo.bmWidth;
          XDestText := XDestBitmap - TextSize.cx;
          if BitBtn.Spacing = -1 then
            dec(XDestText, (newWidth - BitmapInfo.bmWidth - TextSize.cx) div 2)
          else
            dec(XDestText, BitBtn.Spacing);
        end;
      end;
    end;
    blGlyphTop, blGlyphBottom:
    begin
      newWidth := TextSize.cx;
      if newWidth < BitmapInfo.bmWidth then
        newWidth := BitmapInfo.bmWidth;
      if BitBtn.Spacing = -1 then
        newHeight := BitBtn.Height - 10
      else
        newHeight := TextSize.cy + BitmapInfo.bmHeight + BitBtn.Spacing;
      if BitmapHandle <> 0 then
        inc(newHeight, 2);
      XDestBitmap := (newWidth - BitmapInfo.bmWidth) shr 1;
      XDestText := (newWidth - TextSize.cx) shr 1;
      case BitBtnLayout of
        blGlyphTop: 
        begin
          YDestBitmap := 0;
          YDestText := BitmapInfo.bmHeight;
          if BitBtn.Spacing = -1 then
            inc(YDestText, (newHeight - BitmapInfo.bmHeight - TextSize.cy) div 2)
          else
            inc(YDestText, BitBtn.Spacing);
        end;
        blGlyphBottom: 
        begin
          YDestBitmap := newHeight - BitmapInfo.bmHeight;
          YDestText := YDestBitmap - TextSize.cy;
          if BitBtn.Spacing = -1 then
            dec(YDestText, (newHeight - BitmapInfo.bmHeight - TextSize.cy) div 2)
          else
            dec(YDestText, BitBtn.Spacing);
        end;
    end;
  end;
  end;
  // create new
  if (newWidth = 0) and (newHeight = 0) then
    NewBitmap := 0
  else
    NewBitmap := CreateCompatibleBitmap(BitBtnDC, newWidth, newHeight);
  BitmapRect.left := 0;
  BitmapRect.top := 0;
  BitmapRect.right := newWidth;
  BitmapRect.bottom := newHeight;
  // destroy previous bitmap, set new bitmap
  if TWin32WidgetSet(WidgetSet).ThemesActive then
  begin
    // winxp draws BM_SETIMAGE bitmap with old style button!
    // need to use BCM_SETIMAGELIST
    oldImageList := Windows.SendMessage(BitBtnHandle, BCM_GETIMAGELIST, 0, LPARAM(@ButtonImageList)); 
    if oldImageList <> 0 then
      oldImageList := ButtonImageList.himl;
    if NewBitmap <> 0 then
    begin
      ButtonImageList.himl := ImageList_Create(newWidth, newHeight, ILC_COLORDDB or ILC_MASK, 5, 0);
      ButtonImageList.margin.left := 5;
      ButtonImageList.margin.right := 5;
      ButtonImageList.margin.top := 5;
      ButtonImageList.margin.bottom := 5;
      ButtonImageList.uAlign := BUTTON_IMAGELIST_ALIGN_CENTER;
      // for some reason, if bitmap added to imagelist, need to redrawn, otherwise it's black!?
      for I := 1 to 6 do
      begin
        DrawBitmap(XPBitBtn_ImageIndexToEnabled[I]);
        ImageList_AddMasked(ButtonImageList.himl, NewBitmap, ColorToRGB(BitBtn.Brush.Color));
      end;
    end else begin
      ButtonImageList.himl := 0;
    end;
    Windows.SendMessage(BitBtnHandle, BCM_SETIMAGELIST, 0, LPARAM(@ButtonImageList));
    if oldImageList <> 0 then
      ImageList_Destroy(oldImageList);
    if NewBitmap <> 0 then
      DeleteObject(NewBitmap);
  end else begin
    OldBitmap := Windows.SendMessage(BitBtnHandle, BM_GETIMAGE, IMAGE_BITMAP, 0);
    if NewBitmap <> 0 then
      DrawBitmap(BitBtn.Enabled);
    Windows.SendMessage(BitBtnHandle, BM_SETIMAGE, IMAGE_BITMAP, NewBitmap);
    if OldBitmap <> 0 then
      DeleteObject(OldBitmap);
  end;
  SelectObject(hdcNewBitmap, OldFontHandle);
  DeleteDC(hdcNewBitmap);
  ReleaseDC(BitBtnHandle, BitBtnDC);
  BitBtn.Invalidate;
end;

function TWin32WSBitBtn.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    pClassName := 'BUTTON';
    if TCustomBitBtn(AWinControl).Default Then
      Flags := Flags or BS_DEFPUSHBUTTON
    else
      Flags := Flags or BS_PUSHBUTTON;
    Flags := Flags or BS_BITMAP;
    WindowTitle := nil;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Result := Params.Window;
end;

procedure TWin32WSBitBtn.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: integer);
begin
  TWin32WSWinControl.SetBounds(AWinControl, ALeft, ATop, AWidth, AHeight);
  if TCustomBitBtn(AWinControl).Spacing = -1 then
    DrawBitBtnImage(TCustomBitBtn(AWinControl), PChar(AWinControl.Caption));
end;

procedure TWin32WSBitBtn.SetGlyph(const ABitBtn: TCustomBitBtn;
  const AValue: TBitmap);
begin
  DrawBitBtnImage(ABitBtn, PChar(ABitBtn.Caption));
end;

procedure TWin32WSBitBtn.SetLayout(const ABitBtn: TCustomBitBtn;
  const AValue: TButtonLayout);
begin
  DrawBitBtnImage(ABitBtn, PChar(ABitBtn.Caption));
end;

procedure TWin32WSBitBtn.SetMargin(const ABitBtn: TCustomBitBtn;
  const AValue: Integer);
begin
  DrawBitBtnImage(ABitBtn, PChar(ABitBtn.Caption));
end;

procedure TWin32WSBitBtn.SetSpacing(const ABitBtn: TCustomBitBtn;
  const AValue: Integer);
begin
  DrawBitBtnImage(ABitBtn, PChar(ABitBtn.Caption));
end;

procedure TWin32WSBitBtn.SetText(const AWinControl: TWinControl; const AText: string);
begin
  DrawBitBtnImage(TCustomBitBtn(AWinControl), PChar(AText));
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCustomButton, TWin32WSButton);
  RegisterWSComponent(TCustomBitBtn, TWin32WSBitBtn);
//  RegisterWSComponent(TCustomSpeedButton, TWin32WSSpeedButton);
////////////////////////////////////////////////////
end.
