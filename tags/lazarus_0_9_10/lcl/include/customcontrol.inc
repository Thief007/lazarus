{%MainUnit ../controls.pp}

{******************************************************************************
                                     TCustomControl
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
}

{------------------------------------------------------------------------------
  Method:  TCustomControl.Create
  Params:  none
  Returns: Nothing

  Constructor for the class.
 ------------------------------------------------------------------------------}
constructor TCustomControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;
  // ----PREVIOUS COMMENT-----
  // custom controls are painted by the LCL, not the interface, so enable
  // double buffering. It's up to the interface to do the actual
  // doublebuffering.
  // ----Micha's comment----
  // If double buffering has to be enabled before LCL can draw anything,
  // something is wrong. In the overridden Paint method you should always be
  // able to draw, independent of DoubleBuffered setting.
  //
  // Disable the switch by default: 
  //  1) it greatly improves resizing speed (it doesn't feel like java then ;) )
  //  2) VCL compatible
  //  3) users of LCL should enable switch per control if they so desire
  DoubleBuffered:=false;
end;

{------------------------------------------------------------------------------
  Method: TCustomControl.Destroy
  Params:  None
  Returns: Nothing

  Destructor for the class.
 ------------------------------------------------------------------------------}
Destructor TCustomControl.Destroy;
begin
  FCanvas.Free;
  FCanvas:=nil;
  inherited Destroy;
end;

procedure TCustomControl.DestroyComponent;
begin
  if FCanvas<>nil then
    TControlCanvas(FCanvas).FreeHandle;
  inherited DestroyComponent;
end;

{------------------------------------------------------------------------------
  Method: TCustomControl.Paint
  Params:   none
  Returns:  nothing

  Default paint handler. Derived classed should paint themselves
 ------------------------------------------------------------------------------}
Procedure TCustomControl.Paint;
begin
  if Assigned(FOnPaint) then FOnPaint(Self);
end;

procedure TCustomControl.FontChanged(Sender: TObject);
begin
  Canvas.Font:=Font;
  inherited FontChanged(Sender);
end;

{------------------------------------------------------------------------------
  Method: TCustomControl.LMPaint
  Params:   Msg: The paint message
  Returns:  nothing

  Paint event handler.
 ------------------------------------------------------------------------------}
procedure TCustomControl.WMPaint(var Message: TLMPaint);
begin
  if (csDestroying in ComponentState) or (not HandleAllocated) then exit;
  Include(FControlState, csCustomPaint);
  inherited WMPaint(Message);
  Exclude(FControlState, csCustomPaint);
end;

{------------------------------------------------------------------------------
  Method: TCustomControl.PaintWindow
  Params:   DC: The device context to paint on
  Returns:  nothing

  This is a plug-in in TWinControl to get the DC, assign it to our canvas and
  call the paint method for descendents to do the actual painting
 ------------------------------------------------------------------------------}
procedure TCustomControl.PaintWindow(DC: HDC);
var
  DCChanged: boolean;
begin
  DCChanged:=(not FCanvas.HandleAllocated) or (FCanvas.Handle<>DC);
  if DCChanged then
    FCanvas.Handle := DC;
  try
    Paint;
  finally
    if DCChanged then FCanvas.Handle := 0;
  end;
end;

// included by controls.pp
