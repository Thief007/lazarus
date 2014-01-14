{%MainUnit ../stdctrls.pp}

{******************************************************************************
                               TCustomCheckbox
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

  Delphi compatibility:

   - alignment property is missing
}

{------------------------------------------------------------------------------
  Method: TCustomCheckBox.SetState
  Params:  value: new state of the object
  Returns: Nothing

  Set new state of the checkbox.
 ------------------------------------------------------------------------------}
procedure TCustomCheckBox.SetState(Value: TCheckBoxState);
begin
  if FState <> Value then
  begin
    FState := Value;
    //debugln('TCustomCheckBox.SetState ',dbgsname(Self),' ',dbgs(ord(FState)));
    ApplyChanges;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomCheckBox.GetState
  Params:  none
  Returns: current state of the object

  Get current state of the checkbox. To get the real state a call to the
  interface is made here.
 ------------------------------------------------------------------------------}
function TCustomCheckBox.GetState: TCheckBoxState;
begin
  fState:=RetrieveState;
  Result := fState;
end;

procedure TCustomCheckBox.DoChange(var Msg);
var
  NewState: TCheckBoxState;
begin
  //debugln('TCustomCheckBox.DoChange START ',dbgsname(Self),' ',dbgs(ord(FState)));
  NewState:=RetrieveState;
  if FState=NewState then exit;
  FState:=NewState;
  //debugln('TCustomCheckBox.DoChange CHANGED ',dbgsname(Self),' ',dbgs(ord(FState)));
  DoOnChange;
end;

function TCustomCheckBox.RetrieveState: TCheckBoxState;
begin
  Result:=FState;
  // get the actual state of the component
  // don't read from interface during loading
  if HandleAllocated and ([csLoading,csDestroying]*ComponentState=[]) then begin
    Result := TWSCustomCheckBoxClass(WidgetSetClass).RetrieveState(Self);
    //debugln('TCustomCheckBox.RetrieveState ',dbgsname(Self),' ',dbgs(ord(Result)));
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomCheckBox.Create
  Params:  TheOwner: the owner of the class
  Returns: Nothing

  Constructor for custom checkbox.
 ------------------------------------------------------------------------------}
constructor TCustomCheckBox.Create(TheOwner : TComponent);
begin
  Inherited Create(TheOwner);
  fCompStyle := csCheckbox;
  FState       := cbUnchecked;
  FAllowGrayed := false;
  TabStop := true;
  SetInitialBounds(0,0,90,23);
  AutoSize:=true;
end;

{------------------------------------------------------------------------------
  Method: TCustomCheckBox.InitializeWnd
  Params: none
  Returns: Nothing

  Set all properties after visual component has been created. Will be called
  from TWinControl.
 ------------------------------------------------------------------------------}
procedure TCustomCheckBox.InitializeWnd;
begin
  inherited InitializeWnd;
  ApplyChanges;
end;

{------------------------------------------------------------------------------
  Method: TCustomCheckBox.GetChecked
  Params:  none
  Returns: current state of the object

  Get current state of the checkbox and return it as boolean.
 ------------------------------------------------------------------------------}
function TCustomCheckBox.GetChecked : Boolean;
begin
  GetChecked := (GetState = cbChecked);
end;

{------------------------------------------------------------------------------
  Method: TCustomCheckBox.SetChecked
  Params:  Value - new state of checkbox
  Returns: Nothing

  Set the new state of the checkbox as boolean.
 ------------------------------------------------------------------------------}
procedure TCustomCheckBox.SetChecked(Value : Boolean);
var
  OldState : TCheckBoxState;
begin
  OldState := FState;
  If Value then
    FState := cbChecked
  else
    FState := cbUnChecked;
  //debugln('TCustomCheckBox.DoChange ',dbgsname(Self),' ',dbgs(ord(FState)));
  if FState <> OldState then
  begin
    if Assigned(Action)
    and (Action is TCustomAction) then
      TCustomAction(Action).Checked := FState=cbChecked;
    ApplyChanges;
    DoOnChange;
    if (not UseOnChange) and (not ClicksDisabled) then Click;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomCheckBox.Toggle
  Params: none
  Returns: Nothing

  Toggle the current state of the checkbox.
 ------------------------------------------------------------------------------}
procedure TCustomCheckBox.Toggle;
begin
  SetChecked(not GetChecked);
end;

{------------------------------------------------------------------------------
  Method: TCustomCheckBox.ApplyChanges
  Params: none
  Returns: Nothing

  Sends message to update the visual apperance of the object.
 ------------------------------------------------------------------------------}
procedure TCustomCheckBox.ApplyChanges;
begin
  if HandleAllocated and (not (csLoading in ComponentState)) then begin
    //debugln('TCustomCheckBox.ApplyChanges ',dbgsname(Self),' ',dbgs(ord(FState)),' ',WidgetSetClass.ClassName);
    TWSCustomCheckBoxClass(WidgetSetClass).SetState(Self, FState);
  end;
end;

procedure TCustomCheckBox.Loaded;
begin
  // Send first the FState to the interface before calling inherited,
  // otherwise the FState will be lost and the default interface State is taken.
  // TODO: MWE, remove this, it should be handled by InitializeWnd
  if HandleAllocated
  then TWSCustomCheckBoxClass(WidgetSetClass).SetState(Self, FState);
  inherited Loaded;
end;

{------------------------------------------------------------------------------
  procedure TCustomCheckBox.RealSetText(const Value: TCaption);
 ------------------------------------------------------------------------------}
procedure TCustomCheckBox.RealSetText(const Value: TCaption);
var
  ParseStr : String;
  AccelIndex : Longint;
  OldKey: word;
begin
  if Value=Text then exit;
  Inherited RealSetText(Value);
  If HandleAllocated and (not (csDesigning in ComponentState)) then begin
    ParseStr := Value;
    AccelIndex := DeleteAmpersands(ParseStr);
    If AccelIndex > -1 then begin
      OldKey := FShortCut;
      FShortCut := Char2VK(ParseStr[AccelIndex]);
      TWSCustomCheckBoxClass(WidgetSetClass).SetShortCut(Self, OldKey, FShortCut);
    end;
  end;
  InvalidatePreferredSize;
  AdjustSize;
end;

function TCustomCheckBox.DialogChar(var Message: TLMKey): boolean;
begin
  if IsAccel(Message.CharCode, Caption) and CanFocus then
  begin
    SetFocus;
    if Focused then Toggle;
    Result := true;
  end else
    Result := inherited;
end;

// included by stdctrls.pp

// included by stdctrls.pp