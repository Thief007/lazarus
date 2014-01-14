{%MainUnit ../buttons.pp}

{******************************************************************************
                                   TCustomSpeedButton
 ******************************************************************************

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

{$IFOPT C-}
// Uncomment for local trace
//  {$C+}
//  {$DEFINE ASSERT_IS_ON}
{$ENDIF}

{------------------------------------------------------------------------------
  Method:  TCustomSpeedButton.Create
  Params:  none
  Returns: Nothing

  Constructor for the class.
 ------------------------------------------------------------------------------}
constructor TCustomSpeedButton.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  FCompStyle := csSpeedButton;

  FGlyph := TButtonGlyph.Create;
  FGlyph.OnChange := @GlyphChanged;

  SetInitialBounds(0, 0, 23, 22);
  ControlStyle := ControlStyle + [csCaptureMouse]-[csSetCaption];

  FLayout:= blGlyphLeft;
  FAllowAllUp:= false;
  FMouseInControl := False;
  FDragging := False;
  FShowAccelChar:=true;
  FSpacing := 4;
  FMargin := -1;
  FTransparent := true;
  Color := clBtnFace;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.Destroy
  Params:  None
  Returns: Nothing

  Destructor for the class.
 ------------------------------------------------------------------------------}
destructor TCustomSpeedButton.Destroy;
begin
  FreeAndNil(FGlyph);
  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.FindDownButton: TCustomSpeedButton;

  Searches the speed button with Down=true and the same GroupIndex.
 ------------------------------------------------------------------------------}
function TCustomSpeedButton.FindDownButton: TCustomSpeedButton;

  function FindDown(AWinControl: TWinControl): TCustomSpeedButton;
  var
    i: Integer;
    Child: TControl;
    Button: TCustomSpeedButton;
  begin
    if AWinControl=nil then exit(nil);
    for i:=0 to AWinControl.ControlCount-1 do begin
      Child:=AWinControl.Controls[i];
      if Child is TCustomSpeedButton then begin
        Button:=TCustomSpeedButton(Child);
        if (Button.GroupIndex=GroupIndex)
        and (Button.Down) then
          exit(Button);
      end;
      if Child is TWinControl then begin
        Result:=FindDown(TWinControl(Child));
        if Result<>nil then exit;
      end;
    end;
    Result:=nil;
  end;

begin
  if Down or (GroupIndex=0) then exit(Self);
  Result:=FindDown(GetFirstParentForm(Self));
end;

procedure TCustomSpeedButton.Click;
begin
  inherited Click;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetAllowAllUp
  Params: Value:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetAllowAllUp(Value : Boolean);
begin
  if FAllowAllUp <> Value
  then begin
    FAllowAllUp := Value;
    UpdateExclusive;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetDown
  Params: Value:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetDown(Value : Boolean);
var
  OldState: TButtonState;
  OldDown: Boolean;
begin
  //since Down needs GroupIndex, then we need to wait that all properties
  //loaded before we continue
  if (csLoading in ComponentState) then begin
    FDownBuffered := Value;
    exit;
  end else begin
    if FGroupIndex = 0 then Value:= false;
    if FDown <> Value then begin
      if FDown and not FAllowAllUp then Exit;
      OldDown:=FDown;
      FDown := Value;
      OldState := fState;
      if FDown then begin
        fState := bsExclusive;
      end else begin
        FState := bsUp;
      end;
      if (OldDown<>FDown) or (OldState<>FState) then Invalidate;
      if Value then begin
        UpdateExclusive;
      end;
    end;
  end;
end;

procedure TCustomSpeedButton.SetEnabled(NewEnabled: boolean);
begin
  inherited;

  UpdateState(true);
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetFlat
  Params: Value:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetFlat(const Value : boolean);
begin
  if FFlat <> Value then begin
    FFlat := Value;
    Invalidate;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetGlyph
  Params: Value:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetGlyph(Value : TBitmap);
begin
  FGlyph.Glyph := Value;
  Invalidate;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetGroupIndex
  Params: Value:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetGroupIndex(const Value : Integer);
begin
  if FGroupIndex <> Value then begin
    FGroupIndex := Value;
    UpdateExclusive;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetMargin
  Params: Value:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetMargin(const Value : Integer);
begin
  if FMargin <> Value then begin
    FMargin := Value;
    Invalidate;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetNumGlyphs
  Params: Value : Integer = Number of glyphs in the file/resource
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetNumGlyphs(Value : integer);
Begin
  if Value < 0 then Value := 1;
  if Value > 4 then Value := 4;

  if Value <> TButtonGlyph(fGlyph).NumGlyphs then
  Begin
    TButtonGlyph(fGlyph).NumGlyphs :=  TNumGlyphs(Value);
    Invalidate;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetSpacing
  Params: Value:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetSpacing(const Value : Integer);
begin
  if FSpacing <> Value then begin
    FSpacing := Value;
    Invalidate;
  end;
end;

Procedure TCustomSpeedButton.SetShowAccelChar(Value : Boolean);
begin
  If FShowAccelChar <> Value then begin
    FShowAccelChar := Value;
    Invalidate;
  end;
end;


{------------------------------------------------------------------------------
  procedure TCustomSpeedButton.RealSetText(const Value: TCaption);
 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.RealSetText(const Value: TCaption);
begin
  if Caption=Value then exit;
  inherited RealSetText(Value);
  Invalidate;
end;

{------------------------------------------------------------------------------
  procedure TCustomSpeedButton.UpdateState(InvalidateOnChange: boolean);
 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.UpdateState(InvalidateOnChange: boolean);
var
  OldState: TButtonState;
begin
  OldState:=FState;
  if not Enabled then begin
    FState := bsDisabled;
    FDragging := False;
  end else begin
    if FState = bsDisabled
    then begin
      if FDown and (GroupIndex <> 0)
      then FState := bsExclusive
      else FState := bsUp;
    end;
  end;
  if FState<>OldState then
    if (Action is TCustomAction) then
      TCustomAction(Action).Checked := FState=bsDown;

  if InvalidateOnChange
  and ((FState<>OldState) or (FLastDrawFlags<>GetDrawFlags))
  then
    Invalidate;
end;

{------------------------------------------------------------------------------
  function TCustomSpeedButton.GetDrawFlags: integer;
 ------------------------------------------------------------------------------}
function TCustomSpeedButton.GetDrawFlags: integer;
begin
  // if flat and not mouse in control and not down, don't draw anything
  if FFlat and not FMouseInControl and not (FState in [bsDown, bsExclusive]) then
  begin
    Result := DFCS_FLAT;
    if not Enabled then
      inc(Result,DFCS_INACTIVE)
  end else begin
    Result:=DFCS_BUTTONPUSH;
    if FState in [bsDown, bsExclusive] then 
      inc(Result,DFCS_PUSHED);
    if not Enabled then
      inc(Result,DFCS_INACTIVE)
    else if fMouseInControl then
      inc(Result,DFCS_CHECKED);
  end;
end;

procedure TCustomSpeedButton.ActionChange(Sender: TObject;
  CheckDefaults: Boolean);

  procedure CopyImage(ImageList: TCustomImageList; Index: Integer);
  begin
    ImageList.GetBitmap(Index, Glyph);
  end;

begin
  inherited ActionChange(Sender,CheckDefaults);
  if Sender is TCustomAction then begin
    with TCustomAction(Sender) do begin
      if CheckDefaults or (Self.GroupIndex = 0) then
        Self.GroupIndex := GroupIndex;
      if (Glyph.Empty) and (ActionList <> nil) and (ActionList.Images <> nil)
      and (ImageIndex >= 0) and (ImageIndex < ActionList.Images.Count) then
        CopyImage(ActionList.Images,ImageIndex);
    end;
  end;
end;

function TCustomSpeedButton.GetActionLinkClass: TControlActionLinkClass;
begin
  Result := TSpeedButtonActionLink;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.UpdateExclusive
  Params: none
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.UpdateExclusive;
var
  msg : TLMessage;
begin
  if (FGroupIndex <> 0) and (Parent <> nil)
  and (not (csLoading in ComponentState))
  then begin
    Msg.Msg := CM_ButtonPressed;
    Msg.WParam := FGroupIndex;
    Msg.LParam := PtrInt(Self);
    Msg.Result := 0;
    Parent.Broadcast(Msg);
  end;
end;

{------------------------------------------------------------------------------
  Function: TCustomSpeedButton.GetGlyph
  Params: none
  Returns:  The bitmap

 ------------------------------------------------------------------------------}
function TCustomSpeedButton.GetGlyph : TBitmap;
begin
  Result := FGlyph.Glyph;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.GetNumGlyphs
  Params: none
  Returns:  The number stored in TButtonGlyph(FGlyph).NumGlyphs

 ------------------------------------------------------------------------------}
Function TCustomSpeedButton.GetNumGlyphs : Integer;
Begin
  Result :=  TButtonGlyph(fGlyph).NumGlyphs;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.GlyphChanged
  Params: Sender - The glyph that changed
  Returns:  zippo

 ------------------------------------------------------------------------------}
Procedure TCustomSpeedButton.GlyphChanged(Sender : TObject);
Begin
  //redraw the button;
  Invalidate;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.Paint
  Params: none
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.Paint;
var
  fRect,
  PaintRect: TRect;
  GlyphWidth, GlyphHeight: Integer;
  Offset, OffsetCap: TPoint;
  ClientSize, TotalSize, TextSize: TSize;
  //BrushStyle : TBrushStyle;
  M, S : integer;
  TXTStyle : TTextStyle;
  Flags,
  SIndex : Longint;
  TMP : String;
  xBevel :  tBevelCut;
begin
  UpdateState(false);
  if FGlyph=nil then exit;

  PaintRect:=ClientRect;

  {if Transparent and not (csDesigning in ComponentState) then
    BrushStyle:= bsClear
  else
    BrushStyle:= bsSolid;}

  FLastDrawFlags:=GetDrawFlags;
  //DebugLn('TCustomSpeedButton.Paint ',Name,':',ClassName,' Parent.Name=',Parent.Name);

  {if (FLastDrawFlags and DFCS_FLAT) = 0 then begin
    if (FLastDrawFlags and DFCS_PUSHED) <>0 then xBevel := bvLowered
                                            else xBevel := bvRaised;
    Canvas.Frame3d(PaintRect, 1, xBevel);
    InflateRect(PaintRect, -1, -1);
  end;}

  // do not draw anything if flat and mouse not in control (simplified)
  if Transparent then begin
    if (FLastDrawFlags and DFCS_FLAT) = 0 then begin
       if (FLastDrawFlags and DFCS_PUSHED) <>0 then xBevel := bvLowered
                                               else xBevel := bvRaised;
        Canvas.Frame3D(PaintRect,1,xBevel);
      InflateRect(PaintRect, -1, -1);
    end;
  end else begin
    if (FLastDrawFlags and DFCS_FLAT) = 0 then begin
      DrawFrameControl(Canvas.GetUpdatedHandle([csBrushValid,csPenValid]),
        PaintRect, DFC_BUTTON, FLastDrawFlags);
       InflateRect(PaintRect, -1, -1);
    end;
  end;

  //writeln('TCustomSpeedButton.Paint ',Name,':',ClassName,' Parent.Name=',Parent.Name,
  //  ' DFCS_BUTTONPUSH=',FLastDrawFlags and DFCS_BUTTONPUSH,
  //  ' DFCS_PUSHED=',FLastDrawFlags and DFCS_PUSHED,
  //  ' DFCS_INACTIVE=',FLastDrawFlags and DFCS_INACTIVE,
  //  ' DFCS_FLAT=',FLastDrawFlags and DFCS_FLAT,
  //  '');
  if (not Transparent) and Enabled and (Color<>clBtnFace) then begin
    Canvas.Brush.Color := Color;
    Canvas.FillRect(PaintRect);
  end;

  GlyphWidth:= TButtonGlyph(FGlyph).Glyph.Width;
  if TButtonGlyph(FGlyph).NumGlyphs > 1 then
    GlyphWidth:=GlyphWidth div NumGlyphs;
  GlyphHeight:=TButtonGlyph(FGlyph).Glyph.Height;

  ClientSize.cx:= PaintRect.Right - PaintRect.Left;
  ClientSize.cy:= PaintRect.Bottom - PaintRect.Top;

  if Caption <> '' then begin
    TMP := Caption;
    TXTStyle := Canvas.TextStyle;
    TXTStyle.Opaque := False;
    TXTStyle.Clipping := True;
    TXTStyle.ShowPrefix := ShowAccelChar;
    TXTStyle.Alignment := taLeftJustify;
    TXTStyle.Layout := tlTop;
    TXTStyle.SystemFont := Canvas.Font.IsDefault;//Match System Default Style
    SIndex := DeleteAmpersands(TMP);
    fRect:=PaintRect;
    Flags:=DT_CalcRect;
    if not TXTStyle.SingleLine then inc(Flags,DT_WordBreak);

    DrawText(canvas.Handle,pChar(TMP),Length(TMP),fRect,flags);
    TextSize.cy:=fRect.bottom-fRect.top;
    TextSize.cx:=fRect.right-fRect.left;
    If SIndex > 0 then
      If SIndex <= Length(TMP) then begin
        FShortcut := Ord(TMP[SIndex]);
      end;
  end
  else begin
    TextSize.cx:= 0;
    TextSize.cy:= 0;
  end;

  if (GlyphWidth = 0) or (GlyphHeight = 0)
  or (TextSize.cx = 0) or (TextSize.cy = 0)
  then
    S:= 0
  else
    S:= Spacing;

  // Calculate caption and glyph layout

  if Margin = -1 then begin
    if S = -1 then begin
      TotalSize.cx:= TextSize.cx + GlyphWidth;
      TotalSize.cy:= TextSize.cy + GlyphHeight;
      if Layout in [blGlyphLeft, blGlyphRight] then
        M:= (ClientSize.cx - TotalSize.cx) div 3
      else
        M:= (ClientSize.cy - TotalSize.cy) div 3;
      S:= M;
    end else begin
      TotalSize.cx:= GlyphWidth + S + TextSize.cx;
      TotalSize.cy:= GlyphHeight + S + TextSize.cy;
      if Layout in [blGlyphLeft, blGlyphRight] then
        M:= (ClientSize.cx - TotalSize.cx) div 2
      else
        M:= (ClientSize.cy - TotalSize.cy) div 2;
    end;
  end else begin
    if S = -1 then begin
      TotalSize.cx:= ClientSize.cx - (Margin + GlyphWidth);
      TotalSize.cy:= ClientSize.cy - (Margin + GlyphHeight);
      if Layout in [blGlyphLeft, blGlyphRight] then
        S:= (TotalSize.cx - TextSize.cx) div 2
      else
        S:= (TotalSize.cy - TextSize.cy) div 2;
    end;
    M:= Margin;
  end;

  case Layout of
    blGlyphLeft : begin
      Offset.X:= M;
      Offset.Y:= (ClientSize.cy - GlyphHeight) div 2;
      OffsetCap.X:= Offset.X + GlyphWidth + S;
      OffsetCap.Y:= (ClientSize.cy - TextSize.cy) div 2;
    end;
    blGlyphRight : begin
      Offset.X:= ClientSize.cx - M - GlyphWidth;
      Offset.Y:= (ClientSize.cy - GlyphHeight) div 2;
      OffsetCap.X:= Offset.X - S - TextSize.cx;
      OffsetCap.Y:= (ClientSize.cy - TextSize.cy) div 2;
    end;
    blGlyphTop : begin
      Offset.X:= (ClientSize.cx - GlyphWidth) div 2;
      Offset.Y:= M;
      OffsetCap.X:= (ClientSize.cx - TextSize.cx) div 2;
      OffsetCap.Y:= Offset.Y + GlyphHeight + S;
    end;
    blGlyphBottom : begin
      Offset.X:= (ClientSize.cx - GlyphWidth) div 2;
      Offset.Y:= ClientSize.cy - M - GlyphHeight;
      OffsetCap.X:= (ClientSize.cx - TextSize.cx) div 2;
      OffsetCap.Y:= Offset.Y - S - TextSize.cy;
    end;
  end;

  FGlyph.Draw(Canvas, PaintRect, Offset, FState, Transparent, 0);
  if Caption <> '' then begin

    With PaintRect, OffsetCap do begin
      Left := Left + X;
      Top := Top + Y;
    end;
    If not Enabled then begin
      Canvas.Font.Color := clBtnHighlight;
      OffsetRect(PaintRect, 1, 1);
      Canvas.TextRect(PaintRect, PaintRect.Left, PaintRect.Top, Caption, TXTStyle);
      Canvas.Font.Color := clBtnShadow;
      OffsetRect(PaintRect, -1, -1);
    end
    else Canvas.Font.Color := Font.Color;
    //DebugLn('TCustomSpeedButton.Paint PaintRect=',PaintRect.Left,',',PaintRect.TOp,',',PaintRect.Right,',',PaintRect.Bottom,caption);
    Canvas.TextRect(PaintRect, PaintRect.Left, PaintRect.Top, Caption, TXTStyle);
  end;

  inherited Paint;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.MouseDown
  Params: Button:
          Shift:
          X, Y:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if csDesigning in ComponentState then exit;

  if (Button = mbLeft) and Enabled
  then begin
    if not FDown
    then begin
      FState := bsDown;
      if (Action is TCustomAction) then
        TCustomAction(Action).Checked := False;
      Invalidate;
    end;
    FDragging := True;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.MouseMove
  Params: Shift:
          X, Y:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewState: TButtonState;
begin
  inherited MouseMove(Shift, X, Y);
  if csDesigning in ComponentState then exit;

  if FDragging
  then begin
    Assert(False,'Trace:FDragging is true');
    if FDown then
      NewState := bsExclusive
    else begin
      if  (X >= 0) and (X < Width)
      and (Y >= 0) and (Y < Height) 
      then
        NewState := bsDown
      else
        NewState := bsUp;
    end;

    if NewState <> FState
    then begin
      FState := NewState;
      Invalidate;
    end;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.MouseUp
  Params: Button:
          Shift:
          X, Y:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  OldState: TButtonState;
begin
  if not (csDesigning in ComponentState) and FDragging
  then begin
    FDragging := False;
    OldState:=FState;

    if FGroupIndex = 0
    then begin
      FState := bsUp;
      if OldState<>FState then Invalidate;
    end 
    else if (X >= 0) and (X < Width)
        and (Y >= 0) and (Y < Height) then
      SetDown(not FDown);
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetLayout
  Params: Value: new layout value
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetLayout(const Value : TButtonLayout);
begin
  if Value <> FLayout then begin
    FLayout:= Value;
    Invalidate;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.SetTransparent
  Params: Value: new transparency value
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.SetTransparent(const Value : boolean);
begin
  if Value <> FTransparent then begin
    FTransparent:= Value;
    if Value then
      ControlStyle:= ControlStyle + [csOpaque]
    else
      ControlStyle:= ControlStyle - [csOpaque];
    Invalidate;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.CMButtonPressed
  Params: Message:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.CMButtonPressed(var Message : TLMessage);
var
  Sender : TCustomSpeedButton;
begin
  if csDestroying in ComponentState then exit;
  if Message.WParam = WParam(FGroupIndex)
  then begin
    Sender := TCustomSpeedButton(Message.LParam);
    if Sender <> Self
    then begin
      if Sender.Down and FDown
      then begin
        FDown := False;
        FState := bsUp;
        Invalidate;
      end;
      FAllowAllUp := Sender.AllowAllUp;
    end;
  end;
end;

procedure TCustomSpeedButton.Loaded;
begin
  inherited Loaded;
  UpdateExclusive;
  if FDownBuffered then SetDown(FDownBuffered);
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.CMEnabledChanged
  Params: Message:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.CMEnabledChanged(var Message: TLMEssage);
Begin
  //Should create a new glyph based on the new state
  Invalidate;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.MouseEnter
  Params:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.MouseEnter;
begin
  inherited MouseEnter;
  if csDesigning in ComponentState then exit;
  if not FMouseInControl
  and Enabled and (GetCapture = 0)
  then begin
    FMouseInControl := True;
    UpdateState(true);
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.MouseLeave
  Params:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.MouseLeave;
begin
  inherited MouseLeave;
  if csDesigning in ComponentState then exit;

  if FMouseInControl
  then begin
    FMouseInControl := False;
    if Enabled then
      UpdateState(true);
  end;
end;

{ TSpeedButtonActionLink }

procedure TSpeedButtonActionLink.AssignClient(AClient: TObject);
begin
  inherited AssignClient(AClient);
  FClient := AClient as TCustomSpeedButton;
end;

function TSpeedButtonActionLink.IsCheckedLinked: Boolean;
var
  SpeedButton: TCustomSpeedButton;
begin
  SpeedButton:=TCustomSpeedButton(FClient);
  Result := inherited IsCheckedLinked
            and (SpeedButton.GroupIndex <> 0)
            and SpeedButton.AllowAllUp
            and (SpeedButton.Down = (Action as TCustomAction).Checked);
end;

function TSpeedButtonActionLink.IsGroupIndexLinked: Boolean;
var
  SpeedButton: TCustomSpeedButton;
begin
  SpeedButton:=TCustomSpeedButton(FClient);
  Result := (SpeedButton is TCustomSpeedButton) and
    (SpeedButton.GroupIndex = (Action as TCustomAction).GroupIndex);
end;

procedure TSpeedButtonActionLink.SetGroupIndex(Value: Integer);
begin
  if IsGroupIndexLinked then TCustomSpeedButton(FClient).GroupIndex := Value;
end;

procedure TSpeedButtonActionLink.SetChecked(Value: Boolean);
begin
  if IsCheckedLinked then TCustomSpeedButton(FClient).Down := Value;
end;


{$IFDEF ASSERT_IS_ON}
  {$UNDEF ASSERT_IS_ON}
  {$C-}
{$ENDIF}


// included by buttons.pp