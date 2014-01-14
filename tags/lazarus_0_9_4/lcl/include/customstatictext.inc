{%MainUnit ../stdctrls.pp}

{******************************************************************************
                               TCustomStaticText
 ******************************************************************************

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

  TODO:

    - Enable Tabbing/Focusing to focus FocusControl
    - Enable Escaped '&' Shortcut to focus FocusControl
    - Compare/Match AutoSize to Delphi/Kylix's
    - ?? Check For Full Delphi/Kylix Compatibility

}
Procedure TCustomStaticText.DoAutoSize;
var
  R : TRect;
  DC : hDC;
begin
  If AutoSizing or not AutoSize then
    Exit;
  if (not HandleAllocated) or ([csLoading,csDestroying]*ComponentState<>[]) then
    exit;
  AutoSizing := True;
  DC := GetDC(Handle);
  Try
    R := Rect(0,0, Width, Height);
    If BorderStyle <> sbsNone then
      InflateRect(R, -2, -2);
    SelectObject(DC, Font.Handle);
    DrawText(DC, PChar(Caption), Length(Caption), R,
      DT_CalcRect or DT_NoPrefix or DT_WordBreak);
    If BorderStyle <> sbsNone then
      InflateRect(R, 2, 2);

    Width := R.Right - R.Left;
    Height := R.Bottom - R.Top;
  Finally
    ReleaseDC(Handle, DC);
    AutoSizing := False;
  end;
end;

Procedure TCustomStaticText.SetAlignment(Value : TAlignment);
begin
  If FAlignment <> Value then begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TCustomStaticText.Notification(AComponent : TComponent; Operation : TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = FFocusControl) and (Operation = opRemove) then
    FFocusControl:= nil;
end;

procedure TCustomStaticText.SetFocusControl(Value : TWinControl);
begin
  if Value <> FFocusControl then begin
    FFocusControl:= Value;
    if Value <> nil then Value.FreeNotification(Self);
  end;
end;

procedure TCustomStaticText.WMActivate(var Message: TLMActivate);
begin
  if (FFocusControl <> nil) and (FFocusControl.CanFocus) then
    FFocusControl.SetFocus;
end;

Function TCustomStaticText.GetAlignment : TAlignment;
begin
  Result := FAlignment;
end;

Procedure TCustomStaticText.SetStaticBorderStyle(Value : TStaticBorderStyle);
begin
  If FStaticBorderStyle <> Value then begin
    FStaticBorderStyle := Value;
    Invalidate;
  end;
end;

Function TCustomStaticText.GetStaticBorderStyle : TStaticBorderStyle;
begin
  Result := FStaticBorderStyle;
end;

Procedure TCustomStaticText.SetShowAccelChar(Value : Boolean);
begin
  If FShowAccelChar <> Value then begin
    FShowAccelChar := Value;
    Invalidate;
  end;
end;

procedure TCustomStaticText.CMTextChanged(var Message: TLMSetText);
begin
  Invalidate;
end;

Function TCustomStaticText.GetShowAccelChar : Boolean;
begin
  Result := FShowAccelChar;
end;

function TCustomStaticText.CanTab: boolean;
begin
  Result:=false;
end;

constructor TCustomStaticText.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Font.OnChange := @FontChange;
  ControlStyle := [csSetCaption, csOpaque, csClickEvents, csDoubleClicks,
                   csReplicatable];
  Width := 65;
  Height := 17;
end;

Procedure TCustomStaticText.Paint;
var
  TR : TTextStyle;
  R : TRect;
begin
  R := Rect(0,0,Width,Height);
  With Canvas do begin
    Color := Self.Color;
    Font := Self.Font;
    if Color<>clNone then
      FillRect(R);
    If BorderStyle <> sbsNone then begin
      InflateRect(R,-2,-2);
      Pen.Style := psSolid;
      If BorderStyle = sbsSunken then
        Pen.Color := clBtnShadow
      else
        Pen.Color := clBtnHighlight;
      MoveTo(0, 0);
      LineTo(Width - 1,0);
      MoveTo(0, 0);
      LineTo(0,Height - 1);
      If BorderStyle = sbsSunken then
        Pen.Color := clBtnHighlight
      else
        Pen.Color := clBtnShadow;
      MoveTo(0,Height - 1);
      LineTo(Width - 1,Height - 1);
      MoveTo(Width - 1, 0);
      LineTo(Width - 1,Height);
    end;
    FillChar(TR,SizeOf(TR),0);
    With TR do begin
      Alignment := Self.Alignment;
      WordBreak := True;
      Clipping := True;
      ShowPrefix := ShowAccelChar;
      SystemFont:=false;
    end;
    TextRect(R, R.Left, R.Top, Caption, TR);
  end;
end;

Procedure TCustomStaticText.FontChange(Sender : TObject);
begin
  If Caption <> '' then
    Invalidate;
end;

 // included by stdctrls.pp


{
  $Log$
  Revision 1.9  2004/12/31 11:27:35  mattias
  skip FillRect in TStaticText.Paint when Color=clNone

  Revision 1.8  2004/09/24 13:45:32  mattias
  fixed TCanvas.TextRect Delphi compatible Rect and added TBarChart from Michael VC

  Revision 1.7  2004/08/04 09:57:17  mattias
  TStaticText.CanTab=false

  Revision 1.6  2004/05/21 09:03:55  micha
  implement new borderstyle
  - centralize to twincontrol (protected)
  - public expose at tcustomcontrol to let interface access it

  Revision 1.5  2004/04/10 17:58:57  mattias
  implemented mainunit hints for include files

  Revision 1.4  2004/03/07 09:37:20  mattias
  added workaround for AutoSize in TCustomLabel

  Revision 1.3  2004/01/03 23:14:59  mattias
  default font can now change height and fixed gtk crash

  Revision 1.2  2002/10/23 20:47:26  lazarus
  AJ: Started Form Scrolling
      Started StaticText FocusControl
      Fixed Misc Dialog Problems
      Added TApplication.Title

  Revision 1.1  2002/10/21 15:51:27  lazarus
  AJ: moved TCustomStaticText code to include/customstatictext.inc


}