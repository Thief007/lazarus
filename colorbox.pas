{
  TColorBox is component that displays colors in a combobox

  Copyright (C) 2005 Darius Blaszijk

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

unit ColorBox;

{$mode objfpc}
{$H+}

interface

uses
  LResources, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TColorPalette = (cpDefault, cpFull);

  TColorBox = class(TCustomComboBox)
  private
    FPalette: TColorPalette;
    function GetSelection: TColor;
    procedure SetSelection(Value: TColor);

    procedure SetPalette(Value: TColorPalette);
  protected
    procedure SetStyle(Value: TComboBoxStyle); override;
    procedure DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetColorList;
    property Selection: TColor read GetSelection write SetSelection;
  published
    property Color;
    property Ctl3D;
    property DragMode;
    property DragCursor;
    property DropDownCount;
    property Enabled;
    property Font;
    property ItemHeight;
    property Items;
    property MaxLength;
    property Palette: TColorPalette read FPalette write SetPalette;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Sorted;
    property TabOrder;
    property TabStop;
    property Text;
    property Visible;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnDropDown;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMeasureItem;
    property OnStartDrag;
  end;

procedure Register;

implementation

// The following colors match the predefined Delphi Colors
// as defined in Graphics.pp
const
  ColorDefault: array[0..20] of Integer =
  ( clBlack, clMaroon, clGreen, clOlive, clNavy, clPurple, clTeal, clGray,
    clSilver, clRed, clLime, clYellow, clBlue, clFuchsia, clAqua, clLtGray,
    clDkGray, clWhite, clCream, clNone, clDefault);

{------------------------------------------------------------------------------}
procedure Register;
begin
  RegisterComponents('Additional', [TColorBox]);
end;
{------------------------------------------------------------------------------
  Method:   TColorBox.Create
  Params:   AOwner
  Returns:  Nothing

  Use Create to create an instance of TColorBox and initialize all properties
  and variables.

 ------------------------------------------------------------------------------}
constructor TColorBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FPalette := cpDefault;

  SetColorList;

  Style := csOwnerDrawFixed;
end;
{------------------------------------------------------------------------------
  Method:   TColorBox.GetSelection
  Params:   None
  Returns:  TColor

  Use GetSelection to convert the item selected into a system color.

 ------------------------------------------------------------------------------}
function TColorBox.GetSelection: TColor;
begin
  Result := 0;
  if ItemIndex >= 0 then
    if not IdentToColor(Items[ItemIndex], LongInt(Result)) then
      Result := 0;
end;
{------------------------------------------------------------------------------
  Method:   TColorBox.SetSelection
  Params:   Value
  Returns:  Nothing

  Use SetSelection to set the item in the ColorBox when appointed a color
  from code.

 ------------------------------------------------------------------------------}
procedure TColorBox.SetSelection(Value: TColor);
var
  c: integer;
  i: Longint;
begin
  ItemIndex := -1;

  for c := 0 to Pred(Items.Count) do
    if IdentToColor(Items[c], i) then
      if i = Value then
        ItemIndex := c;
end;
{------------------------------------------------------------------------------
  Method:   TColorBox.SetPalette
  Params:   Value
  Returns:  Nothing

  Use SetPalette to determine wether to reset the colorlist in the ColorBox
  based on the type of palette.

 ------------------------------------------------------------------------------}
procedure TColorBox.SetPalette(Value: TColorPalette);
begin
  if Value <> FPalette then
  begin
    FPalette := Value;
    SetColorList;
  end;
end;
{------------------------------------------------------------------------------
  Method:   TColorBox.SetStyle
  Params:   Value
  Returns:  Nothing

  Use SetStyle to prevent the style to be changed to anything else than
  csOwnerDrawFixed.

 ------------------------------------------------------------------------------}
procedure TColorBox.SetStyle(Value: TComboBoxStyle);
begin
  inherited SetStyle(csOwnerDrawFixed);
end;
{------------------------------------------------------------------------------
  Method:   TColorBox.DrawItem
  Params:   Index, Rect, State
  Returns:  Nothing

  Use DrawItem to customdraw an item in the ColorBox. A color preview is drawn
  and the item rectangle is made smaller and given to the inherited method to
  draw the corresponding text. The Brush color and Pen color where changed and
  reset to their original values.

 ------------------------------------------------------------------------------}
procedure TColorBox.DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  r: TRect;
  ItemColor: TColor;
  BrushColor: TColor;
  PenColor: TColor;
begin
  if Index<0 then
    exit;
  r.top := Rect.top + 3;
  r.bottom := Rect.bottom - 3;
  r.left := Rect.left + 3;
  r.right := r.left + 14;
  with Canvas do begin
    FillRect(Rect);

    BrushColor := Brush.Color;
    PenColor := Pen.Color;

    if IdentToColor(Items[Index], LongInt(ItemColor)) then
      Brush.Color := ItemColor;
      
    Pen.Color := clBlack;

    Rectangle(r);

    Brush.Color := BrushColor;
    Pen.Color := PenColor;
  end;
  r := Rect;
  r.left := r.left + 20;
  
  inherited DrawItem(Index, r, State);
end;
{------------------------------------------------------------------------------
  Method:   TColorBox.SetColorList
  Params:   None
  Returns:  Nothing

  Use SetColorList to fill the itemlist in the ColorBox with the right color
  entries. Based on the value of the Palette property.

 ------------------------------------------------------------------------------}
procedure TColorBox.SetColorList;
var
  c: Longint;
  s: ANSIString;
  m: TIdentMapEntry;
begin
  with Items do
  begin
    Clear;

    //add palettes as desired
    case Palette of
      cpFull : begin
                 c := 0;
                 while IdentEntry(c, m) do
                 begin
                   Add(m.Name);
                   Inc(c);
                 end;
               end;
      else
      begin
        for c := 0 to High(ColorDefault) do
          if ColorToIdent(ColorDefault[c], s) then Add(s);
      end;
    end;
  end;
end;
{------------------------------------------------------------------------------}
end.
