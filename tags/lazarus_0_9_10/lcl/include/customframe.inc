{%MainUnit ../forms.pp}

{
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

{ TCustomFrame }

procedure TCustomFrame.AddActionList(ActionList: TCustomActionList);
var
  ParentForm: TCustomForm;
begin
  ParentForm:=GetParentForm(Self);
  if ParentForm<>nil then begin
    if ParentForm.FActionLists=nil then
      ParentForm.FActionLists:=TList.Create;
    ParentForm.FActionLists.Add(ActionList);
  end;
end;

procedure TCustomFrame.RemoveActionList(ActionList: TCustomActionList);
var
  ParentForm: TCustomForm;
begin
  ParentForm:=GetParentForm(Self);
  if (ParentForm<>nil) and (ParentForm.FActionLists<>nil) then
    ParentForm.FActionLists.Remove(ActionList);
end;

procedure TCustomFrame.GetChildren(Proc: TGetChildProc; Root: TComponent);
begin
  inherited GetChildren(Proc, Root);
end;

procedure TCustomFrame.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  case Operation of
  opInsert:
    if AComponent is TCustomActionList then
      AddActionList(TCustomActionList(AComponent));
  opRemove:
    if AComponent is TCustomActionList then
      RemoveActionList(TCustomActionList(AComponent));
  end;
end;

procedure TCustomFrame.SetParent(AParent: TWinControl);

  procedure UpdateActionLists(Operation: TOperation);
  var
    i: Integer;
    AComponent: TComponent;
  begin
    for i:=0 to ComponentCount-1 do begin
      AComponent:=Components[i];
      if AComponent is TCustomActionList then
        case Operation of
        opInsert: AddActionList(TCustomActionList(AComponent));
        opRemove: RemoveActionList(TCustomActionList(AComponent));
        end;
    end;
  end;

begin
  if Parent<>nil then UpdateActionLists(opRemove);
  if (Parent=nil) and HandleAllocated then
    DestroyHandle;
  inherited SetParent(AParent);
  if Parent<>nil then UpdateActionLists(opInsert);
end;

constructor TCustomFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle:=[csAcceptsControls,csCaptureMouse,csClickEvents,csSetCaption,
                 csDoubleClicks];
  if (ClassType<>TFrame) and not (csDesignInstance in ComponentState) then begin
    if not InitInheritedComponent(Self,TFrame) then
      raise EResNotFound.CreateFmt(rsResourceNotFound, [ClassName]);
  end else begin
    SetInitialBounds(0,0,320,240);
  end;
end;

// included by forms.pp
