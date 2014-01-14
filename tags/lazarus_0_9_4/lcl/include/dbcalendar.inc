{%MainUnit ../dbctrls.pas}

{******************************************************************************
                                     TDBCalendar
                    data aware Calendar, base found in dbctrls.pp
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

// included by dbctrls.pp

{ Private Methods }

//update the caption on next record etc...
procedure TDBCalendar.DataChange(Sender: TObject);
begin
  if FDataLink.Field <> nil then
    inherited Date := FDataLink.Field.AsString//this is wrong, but Text seems Broken
  else
    inherited Date := '';
end;

procedure TDBCalendar.EditingChange(Sender: TObject);
begin
  //ok to hide the 'real' readonly state we must override it
  //and so here when the data changes we need to set the
  //'real' value to match the state of the FieldLink
  //i.e. always ReadOnly unless its editing
  inherited ReadOnly := not FDataLink.Editing;
end;

procedure TDBCalendar.UpdateData(Sender: TObject);
begin
  FDataLink.Field.Text := Text;
  FDataLink.Field.AsString := Text;// I shouldn't have to do this, but text seems broken
end;

procedure TDBCalendar.FocusRequest(Sender: TObject);
begin
  //the FieldLink has requested the control
  //recieve focus for some reason..
  //perhaps an error occured?
  SetFocus;
end;

function TDBCalendar.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

function TDBCalendar.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

function TDBCalendar.GetField: TField;
begin
  Result := FDataLink.Field;
end;

function TDBCalendar.GetReadOnly: Boolean;
begin
  //we want to override the readonly state so we can
  //reflect the state of the Datalink/Field
  Result := FDataLink.ReadOnly;
end;

procedure TDBCalendar.SetReadOnly(Value: Boolean);
begin
  //we want to override the readonly state so we can
  //reflect the state of the Datalink/Field, so changing
  //readonly changes the DataLink to ReadOnly, and when Editing
  //changes the 'real' Readonly state will be updated to match
  //according to the editing flag, which will always be false if
  //this is true anyway. so I think all should be happy...
  FDataLink.ReadOnly := Value;
end;

procedure TDBCalendar.SetDate(const AValue: String);
begin
  inherited Date := AValue;
  DataChange(Self);
end;

procedure TDBCalendar.SetDataField(Value: string);
begin
  FDataLink.FieldName := Value;
end;

procedure TDBCalendar.SetDataSource(Value: TDataSource);
begin
  FDataLink.DataSource := Value;
end;

{ Protected Methods}
procedure TDBCalendar.Loaded;
begin
  inherited Loaded;
  //need to make sure the state is updated on first load
  if (csDesigning in ComponentState) then
    DataChange(Self);
end;

procedure TDBCalendar.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation=opRemove) then begin
    if (FDataLink<>nil) and (AComponent=DataSource) then
      DataSource:=nil;
  end;
end;

procedure TDBCalendar.EditingDone;
begin
  FDataLink.UpdateRecord;
  inherited EditingDone;
end;

{ Public Methods }
constructor TDBCalendar.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := @DataChange;
  FDataLink.OnEditingChange := @EditingChange;
  FDataLink.OnUpdateData := @UpdateData;

  inherited ReadOnly := True;//start read only
end;

destructor TDBCalendar.Destroy;
begin
  FDataLink.Free;
  FDataLink := nil;
  inherited Destroy;
end;

{ =============================================================================

  $Log$
  Revision 1.4  2004/08/30 10:49:20  mattias
  fixed focus catch for combobox csDropDownList

  Revision 1.3  2004/04/10 17:58:57  mattias
  implemented mainunit hints for include files

  Revision 1.2  2003/09/22 15:03:19  ajgenius
  partly fixed streaming of DBCalendar, and opRemove notification of DBText DBEdit DBCalendar

  Revision 1.1  2003/09/18 15:27:07  ajgenius
  added initial TDBCalendar


}
