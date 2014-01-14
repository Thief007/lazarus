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

const
  UpState: array[Boolean] of TButtonState =
  (
{False} bsUp, // mouse in control = false
{True } bsHot // mouse in contorl = true
  );

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

  SetInitialBounds(0,0,GetControlClassDefaultSize.X,GetControlClassDefaultSize.Y);
  ControlStyle := ControlStyle + [csCaptureMouse]-[csSetCaption, csClickEvents];

  FLayout:= blGlyphLeft;
  FAllowAllUp:= false;
  FMouseInControl := False;
  FDragging := False;
  FShowAccelChar:=true;
  FSpacing := 4;
  FMargin := -1;
  FTransparent := true;
  Color := clBtnFace;
  FShowCaption := true;
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
  if (csLoading in ComponentState) then
  begin
    FDownLoaded := Value;
    exit;
  end else
  begin
    if FGroupIndex = 0 then
      Value:= false;
    if FDown <> Value then
    begin
      if FDown and not FAllowAllUp then
        Exit;
      OldDown := FDown;
      FDown := Value;
      OldState := FState;
      if FDown then
        FState := bsExclusive
      else
        FState := UpState[FMouseInControl];
      if (OldDown <> FDown) or (OldState <> FState) then
        Invalidate;
      if Value then
        UpdateExclusive;
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
  if Value > High(TNumGlyphs) then Value := High(TNumGlyphs);

  if Value <> TButtonGlyph(fGlyph).NumGlyphs then
  Begin
    TButtonGlyph(fGlyph).NumGlyphs := TNumGlyphs(Value);
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
  if Caption = Value then Exit;
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
  OldState := FState;
  if not Enabled then
  begin
    FState := bsDisabled;
    FDragging := False;
  end else
  begin
    if FState = bsDisabled then
    begin
      if FDown and (GroupIndex <> 0) then
        FState := bsExclusive
      else
        FState := UpState[FMouseInControl];
    end
    else
    if (FState in [bsHot, bsDown]) and (not FMouseInControl) and (not FDragging) and (not FDown) then
    begin
      // return to normal
      FState := bsUp;
    end
    else
    if (FState = bsUp) and FMouseInControl then
      FState := bsHot;
  end;
  if FState <> OldState then
    if (Action is TCustomAction) then
      TCustomAction(Action).Checked := FState = bsDown;
  //if InvalidateOnChange then DebugLn(['TCustomSpeedButton.UpdateState ',DbgSName(Self),' InvalidateOnChange=',InvalidateOnChange,' StateChange=',FState<>OldState]);
  if InvalidateOnChange and
     (
       (FState<>OldState) or
       not ThemedElementDetailsEqual(FLastDrawDetails, GetDrawDetails)
     )
  then
    Invalidate;
end;

{------------------------------------------------------------------------------
  function TCustomSpeedButton.GetDrawDetails: TThemedElementDetails;
 ------------------------------------------------------------------------------}
function TCustomSpeedButton.GetDrawDetails: TThemedElementDetails;

  function ButtonPart: TThemedButton;
  begin
    // tbPushButtonNormal, tbPushButtonHot, tbPushButtonPressed,
    // tbPushButtonDisabled, tbPushButtonDefaulted
    
    // no check states available
    Result := tbPushButtonNormal;
    if not Enabled then
      Result := tbPushButtonDisabled
    else
    if FState in [bsDown, bsExclusive] then
      Result := tbPushButtonPressed
    else
    if FState = bsHot then
      Result := tbPushButtonHot
    else
      Result := tbPushButtonNormal
  end;

  function ToolButtonPart: TThemedToolBar;
  begin
    // ttbButtonNormal, ttbButtonHot, ttbButtonPressed, ttbButtonDisabled
    // ttbButtonChecked, ttbButtonCheckedHot
    if not Enabled then
      Result := ttbButtonDisabled
    else
    begin
      if Down then
      begin // checked states
        if fMouseInControl then
          Result := ttbButtonCheckedHot
        else
          Result := ttbButtonChecked
      end
      else
      begin
        if FState in [bsDown, bsExclusive] then
          Result := ttbButtonPressed else
        if FState = bsHot then
          Result := ttbButtonHot
        else
          Result := ttbButtonNormal
      end;
    end;
  end;
  
begin
  if Flat then
    Result := ThemeServices.GetElementDetails(ToolButtonPart)
  else
    Result := ThemeServices.GetElementDetails(ButtonPart)
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

class function TCustomSpeedButton.GetControlClassDefaultSize: TPoint;
begin
  Result.X:=23;
  Result.Y:=22;
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

procedure TCustomSpeedButton.SetShowCaption(const AValue: boolean);
begin
  if FShowCaption=AValue then exit;
  FShowCaption:=AValue;
  invalidate;
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

function TCustomSpeedButton.DialogChar(var Message: TLMKey): boolean;
begin
  Result := false;

  Assert(Message.Msg = LM_SYSCHAR, '*** Warning: non LM_SYSCHAR passed to TCustomSpeedButton.DialogChar ! ***');

  if not FShowAccelChar then exit;

  if IsAccel(Message.CharCode, Caption) then
  begin
    Result := true;
    Self.Click;
  end else
    Result := inherited DialogChar(Message);
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.Paint
  Params: none
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.Paint;
var
  PaintRect: TRect;
  GlyphWidth, GlyphHeight: Integer;
  Offset, OffsetCap: TPoint;
  ClientSize, TotalSize, TextSize, GlyphSize: TSize;
  M, S : integer;
  SIndex : Longint;
  TMP : String;
begin
  UpdateState(false);
  if FGlyph = nil then exit;

  PaintRect:=ClientRect;
  FLastDrawDetails := GetDrawDetails;
  
  PaintBackground(PaintRect);

  GlyphSize := GetGlyphSize(PaintRect);
  GlyphWidth := GlyphSize.CX;
  if TButtonGlyph(FGlyph).NumGlyphs > 1 then
    GlyphWidth:=GlyphWidth div NumGlyphs;
  GlyphHeight := GlyphSize.CY;

  ClientSize.cx:= PaintRect.Right - PaintRect.Left;
  ClientSize.cy:= PaintRect.Bottom - PaintRect.Top;

  TextSize := GetTextSize(PaintRect);

  if Caption <> '' then
  begin
    TMP := Caption;
    SIndex := DeleteAmpersands(TMP);
    If SIndex > 0 then
      If SIndex <= Length(TMP) then begin
        FShortcut := Ord(TMP[SIndex]);
      end;
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

  DrawGlyph(Canvas, PaintRect, Offset, FState, Transparent, 0);
  if FShowCaption and (Caption <> '') then
  begin
    with PaintRect, OffsetCap do
    begin
      Left := Left + X;
      Top := Top + Y;
    end;

    ThemeServices.DrawText(Canvas, FLastDrawDetails, Caption, PaintRect,
      DT_LEFT or DT_TOP, 0);
  end;

  inherited Paint;
end;

procedure TCustomSpeedButton.PaintBackground(var PaintRect: TRect);
begin
  if not Transparent and ThemeServices.HasTransparentParts(FLastDrawDetails) then
  begin
    Canvas.Brush.Color := Color;
    Canvas.FillRect(PaintRect);
  end;
  ThemeServices.DrawElement(Canvas.Handle, FLastDrawDetails, PaintRect);
  PaintRect := ThemeServices.ContentRect(Canvas.Handle, FLastDrawDetails, PaintRect);
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

  if (Button = mbLeft) and Enabled then
  begin
    if not FDown then
    begin
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

  if FDragging then
  begin
    Assert(False,'Trace:FDragging is true');
    if FDown then
      NewState := bsExclusive
    else
    begin
      if  (X >= 0) and (X < Width)
      and (Y >= 0) and (Y < Height) 
      then
        NewState := bsDown
      else
        NewState := UpState[FMouseInControl];
    end;

    if NewState <> FState then
    begin
      //debugln(['TCustomSpeedButton.MouseMove ',DbgSName(Self),' fState=',ord(fstate),' NewState=',ord(NewState)]);
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
begin
  inherited MouseUp(Button, Shift, X, Y);
end;

{------------------------------------------------------------------------------
  procedure TCustomSpeedButton.DoBeforeMouseMessage;
------------------------------------------------------------------------------}
procedure TCustomSpeedButton.DoBeforeMouseMessage;
begin
  if Application<>nil then
    Application.DoBeforeMouseMessage(Self);
end;

{------------------------------------------------------------------------------
       TCustomSpeedButton DoMouseUp  "Event Handler"
------------------------------------------------------------------------------}
procedure TCustomSpeedButton.DoMouseUp(var Message: TLMMouse; Button: TMouseButton);
begin
  if not (csNoStdEvents in ControlStyle)
  then with Message do
    MouseUp(Button, KeysToShiftState(Keys), XPos, YPos);
end;

procedure TCustomSpeedButton.WMLButtonDown(var Message: TLMLButtonDown);
begin
  inherited;
  
  // because csClickEvents is not set no csClicked is set in the inherited method
  Include(FControlState, csClicked);
end;

procedure TCustomSpeedButton.WMLButtonDBLCLK(var Message: TLMLButtonDblClk);
begin
  inherited;
  
  // if in a group, raise dblclick event, otherwise translate to click event
  if Down
    then DblClick
    else Click;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.WMLButtonUp
  Params: Message
  Returns: Nothing

  Mouse event handler
 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.WMLButtonUp(var Message: TLMLButtonUp);
var
  OldState: TButtonState;
begin
  DoBeforeMouseMessage;
  //DebugLn('TCustomSpeedButton.WMLButtonUp A ',DbgSName(Self),' csCaptureMouse=',DbgS(csCaptureMouse in ControlStyle),' csClicked=',DbgS(csClicked in ControlState));
  if (csCaptureMouse in ControlStyle) and (mbLeft in CaptureMouseButtons) then
  begin
    {$IFDEF VerboseMouseCapture}
    DebugLn('TCustomSpeedButton.WMLButtonUp ',Name,':',ClassName);
    {$ENDIF}
    MouseCapture := False;
  end;

  if not (csDesigning in ComponentState) and FDragging then
  begin
    OldState := FState;
    FDragging := False;

    if FGroupIndex = 0 then
    begin
      FState := UpState[FMouseInControl];
      if OldState <> FState then
        Invalidate;
    end
    else if (Message.XPos >= 0) and (Message.XPos < Width)
        and (Message.YPos >= 0) and (Message.YPos < Height) then
      SetDown(not FDown);
  end;

  DoMouseUp(Message, mbLeft);

  if csClicked in ControlState then
  begin
    Exclude(FControlState, csClicked);
    //DebugLn('TCustomSpeedButton.WMLButtonUp B ',dbgs(ClientRect.Left),',',dbgs(ClientRect.Top),',',dbgs(ClientRect.Right),',',dbgs(ClientRect.Bottom),' ',dbgs(Message.Pos.X),',',dbgs(Message.Pos.Y));
    if PtInRect(ClientRect, SmallPointToPoint(Message.Pos))
    then begin
      //DebugLn('TCustomSpeedButton.WMLButtonUp C');
      // Important: Calling Click can invoke modal dialogs, so call this as last
      Click;
    end;
  end;
  
  
  //DebugLn('TCustomSpeedButton.WMLButtonUp END');
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
      ControlStyle:= ControlStyle - [csOpaque]
    else
      ControlStyle:= ControlStyle + [csOpaque];
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
        FState := UpState[FMouseInControl];
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
  if FDownLoaded then SetDown(FDownLoaded);
end;

function TCustomSpeedButton.GetGlyphSize(PaintRect: TRect): TSize;
begin
  Result.CX := TButtonGlyph(FGlyph).Glyph.Width;
  Result.CY := TButtonGlyph(FGlyph).Glyph.Height;
end;

function TCustomSpeedButton.GetTextSize(PaintRect: TRect): TSize;
var
  TMP: String;
  TXTStyle: TTextStyle;
  Flags: Cardinal;
begin
  if FShowCaption and (Caption <> '') then
  begin
    TMP := Caption;
    TXTStyle := Canvas.TextStyle;
    TXTStyle.Opaque := False;
    TXTStyle.Clipping := True;
    TXTStyle.ShowPrefix := ShowAccelChar;
    TXTStyle.Alignment := taLeftJustify;
    TXTStyle.Layout := tlTop;
    TXTStyle.SystemFont := Canvas.Font.IsDefault;//Match System Default Style
    DeleteAmpersands(TMP);

    Flags := DT_CalcRect;
    if not TXTStyle.SingleLine then Inc(Flags, DT_WordBreak);

    DrawText(Canvas.Handle, PChar(TMP), Length(TMP), PaintRect, Flags);
    Result.CY := PaintRect.Bottom - PaintRect.Top;
    Result.CX := PaintRect.Right - PaintRect.Left;
  end
  else
  begin
    Result.CY:= 0;
    Result.CX:= 0;
  end;
end;

function TCustomSpeedButton.DrawGlyph(ACanvas: TCanvas; const AClient: TRect;
  const AOffset: TPoint; AState: TButtonState; ATransparent: Boolean;
  BiDiFlags: Longint): TRect;
begin
  if Assigned(FGlyph) then
  begin
    if (AState = bsDown) or (Down = true) then
      Result := FGlyph.Draw(ACanvas, AClient, point(AOffset.x + 1, AOffset.y + 1), AState, ATransparent, BiDiFlags)
    else
      Result := FGlyph.Draw(ACanvas, AClient, AOffset, AState, ATransparent, BiDiFlags);
  end;
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
  if csDesigning in ComponentState then exit;
  if not FMouseInControl and Enabled and (GetCapture = 0) then
  begin
    FMouseInControl := True;
    UpdateState(true);
    inherited MouseEnter;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomSpeedButton.MouseLeave
  Params:
  Returns:  nothing

 ------------------------------------------------------------------------------}
procedure TCustomSpeedButton.MouseLeave;
begin
  if csDesigning in ComponentState then exit;
  ///DebugLn(['TCustomSpeedButton.MouseLeave ',DbgSName(Self),' FMouseInControl=',FMouseInControl,' FDragging=',FDragging]);
  if FMouseInControl then
  begin
    FMouseInControl := False;
    if Enabled then
    begin
      if FDragging and (not MouseCapture) then
      begin
        // something fetched our mouse capture
        FDragging:=false;
      end;
      UpdateState(true);
      inherited MouseLeave;
    end;
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