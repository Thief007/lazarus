{%MainUnit ../stdctrls.pp}
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
{ if not HandleAllocated then
    FItems contains a TExtendedStringList
  else
    FItems contains an interface specific TStrings descendent
}

type
  TCustomListBoxItemRecord = record
    TheObject: TObject;
    Selected: Boolean;
  end;
  PCustomListBoxItemRecord = ^TCustomListBoxItemRecord;

{------------------------------------------------------------------------------
 procedure TCustomListBox.AssignCacheToItemData
------------------------------------------------------------------------------}
procedure TCustomListBox.AssignCacheToItemData(const AIndex: Integer;
  const AData: Pointer);
begin
  if PCustomListBoxItemRecord(AData)^.Selected or (FItemIndex = AIndex) then
    SendItemSelected(AIndex, True);
end;

procedure TCustomListBox.Loaded;
begin
  inherited Loaded;
  if HandleAllocated then
    SendItemIndex;
end;

{------------------------------------------------------------------------------
 procedure TCustomListBox.AssignItemDataToCache
------------------------------------------------------------------------------}
procedure TCustomListBox.AssignItemDataToCache(const AIndex: Integer;
  const AData: Pointer);
begin
  PCustomListBoxItemRecord(AData)^.Selected := Selected[AIndex];
end;

{------------------------------------------------------------------------------
 procedure TCustomListBox.CreateHandle
------------------------------------------------------------------------------}
procedure TCustomListBox.CreateHandle;
var
  NewStrings : TStrings;
  i, cnt: integer;
  OldItems: TExtendedStringList;
begin
  LockSelectionChange;
  //DebugLn('[TCustomListBox.CreateHandle] A ',FItems.ClassName);
  inherited CreateHandle;
  //DebugLn('[TCustomListBox.CreateHandle] B ',FItems.ClassName);
  // create
  TWSCustomListBoxClass(WidgetSetClass).SetBorder(Self);

  // fetch the interface item list
  NewStrings := TWSCustomListBoxClass(WidgetSetClass).GetStrings(Self);
  // copy the items (text+objects)
  NewStrings.Assign(Items);
  OldItems := FItems as TExtendedStringList;

  // new item list is the interface item list
  FItems:= NewStrings;
  FCacheValid := False;

  SendItemIndex;

  // copy items attributes
  cnt := OldItems.Count;
  for i:=0 to cnt-1 do
    AssignCacheToItemData(i, OldItems.Records[i]);

  // free old items
  OldItems.Free;
  UnlockSelectionChange;
  //DebugLn('[TCustomListBox.CreateHandle] END ',FItems.ClassName);
end;

{------------------------------------------------------------------------------}
{ procedure TCustomListBox.DestroyHandle                                       }
{------------------------------------------------------------------------------}
procedure TCustomListBox.DestroyHandle;
var
  NewStrings : TExtendedStringList;
  i, Cnt: integer;
begin
  LockSelectionChange;
  
  // save ItemIndex on destroy handle
  if ([csDestroying,csLoading]*ComponentState=[]) then
    GetItemIndex;
  //DebugLn('[TCustomListBox.DestroyHandle] A ',FItems.ClassName);
  // create internal item list
  NewStrings:= TExtendedStringList.Create(GetCachedDataSize);

  // copy items (text+objects) from the interface items list
  NewStrings.Assign(Items);
  // copy items attributes
  Cnt:=Items.Count;
  for i:=0 to Cnt-1 do
    AssignItemDataToCache(i, NewStrings.Records[i]);

  // free the interface items list
  FItems.Free;
  // new item list is the internal item list
  FItems:= NewStrings;
  FCacheValid := True;
  //DebugLn('[TCustomListBox.DestroyHandle] B ',FItems.ClassName);
  inherited DestroyHandle;
  //DebugLn('[TCustomListBox.DestroyHandle] END ',FItems.ClassName);
  UnlockSelectionChange;
end;

{------------------------------------------------------------------------------}
{ procedure TCustomListBox.UpdateSelectionMode                                 }
{------------------------------------------------------------------------------}
procedure TCustomListBox.UpdateSelectionMode;
begin
  if not HandleAllocated then exit;
  LockSelectionChange;
  TWSCustomListBoxClass(WidgetSetClass).SetSelectionMode(Self, 
    ExtendedSelect, MultiSelect);
  UnlockSelectionChange;
end;

{------------------------------------------------------------------------------
  function TCustomListBox.GetTopIndex: Integer;
------------------------------------------------------------------------------}
function TCustomListBox.GetTopIndex: Integer;
begin
  if HandleAllocated then
    FTopIndex := TWSCustomListBoxClass(WidgetSetClass).GetTopIndex(Self);
  Result := FTopIndex;
end;

{------------------------------------------------------------------------------
  procedure TCustomListBox.SetTopIndex(const AValue: Integer);
------------------------------------------------------------------------------}
procedure TCustomListBox.SetTopIndex(const AValue: Integer);
begin
  // don't check if changed. If the item is only partly visible, the message
  // will make it complete visible.
  FTopIndex:=AValue;
  if HandleAllocated and ([csLoading,csDestroying]*ComponentState=[]) then
    TWSCustomListBoxClass(WidgetSetClass).SetTopIndex(Self, AValue);
end;

{------------------------------------------------------------------------------
  procedure TCustomListBox.UpdateSorted;
------------------------------------------------------------------------------}
procedure TCustomListBox.UpdateSorted;
begin
  if not HandleAllocated then exit;
  LockSelectionChange;
  TWSCustomListBoxClass(WidgetSetClass).SetSorted(Self, FItems, FSorted);
  UnlockSelectionChange;
end;

{------------------------------------------------------------------------------
  procedure TCustomListBox.LMDrawListItem(var TheMessage: TLMDrawListItem);

  Handler for custom drawing items.
 ------------------------------------------------------------------------------}
procedure TCustomListBox.LMDrawListItem(var TheMessage: TLMDrawListItem);
begin
  with TheMessage.DrawListItemStruct^ do
  begin
    FCanvas.Handle := DC;
    if Font<>nil then
      FCanvas.Font := Font;
    if Brush<>nil then
      FCanvas.Brush := Brush;
    if (ItemID >= 0) and (odSelected in ItemState) then
    begin
      FCanvas.Brush.Color := clHighlight;
      FCanvas.Font.Color := clHighlightText
    end else begin
      FCanvas.Brush.Color:=clWindow;
      FCanvas.Font.Color:=clWindowText;
    end;
    DrawItem(ItemID, Area, ItemState);
    if odFocused in ItemState then
      {DrawFocusRect(hDC, rcItem)};
    FCanvas.Handle := 0;
  end;
end;

{------------------------------------------------------------------------------
  procedure TCustomListBox.LMSelChange(var TheMessage);
------------------------------------------------------------------------------}
procedure TCustomListBox.LMSelChange(var TheMessage);
begin
  if [csLoading,csDestroying,csDesigning]*ComponentState<>[] then exit;
  //debugln('TCustomListBox.LMSelChange ',Name,':',ClassName,' ItemIndex=',dbgs(ItemIndex),' FLockSelectionChange=',dbgs(FLockSelectionChange));
  if FLockSelectionChange=0 then
    EditingDone;
  DoSelectionChange(FLockSelectionChange=0);
end;

{------------------------------------------------------------------------------
  procedure TCustomListBox.SendItemSelected(Index: integer; IsSelected: boolean);

  Tell the interface whether an item is selected.
------------------------------------------------------------------------------}
procedure TCustomListBox.SendItemSelected(Index: integer; IsSelected: boolean);
begin
  if HandleAllocated then begin
    LockSelectionChange;
    TWSCustomListBoxClass(WidgetSetClass).SelectItem(Self, Index, IsSelected);
    UnlockSelectionChange;
  end;
end;

{------------------------------------------------------------------------------}
{ procedure TCustomListBox.SetExtendedSelect                                   }
{------------------------------------------------------------------------------}
procedure TCustomListBox.SetExtendedSelect(Val : boolean);
begin
  if Val <> FExtendedSelect then begin
    FExtendedSelect:= Val;
    UpdateSelectionMode;
  end;
end;

{------------------------------------------------------------------------------}
{ procedure TCustomListBox.SetMultiSelect                                      }
{------------------------------------------------------------------------------}
procedure TCustomListBox.SetMultiSelect(Val : boolean);
begin
  if Val <> FMultiSelect then begin
    FMultiSelect:= Val;
    UpdateSelectionMode;
  end;
end;

{------------------------------------------------------------------------------}
{ procedure TCustomListBox.SetSelected                                         }
{------------------------------------------------------------------------------}
procedure TCustomListBox.SetSelected(Index : integer; Val : boolean);
begin
  CheckIndex(Index);

  if not MultiSelect then begin
    if Val then
      ItemIndex:=Index
    else if Index=ItemIndex then
      ItemIndex:=-1;
  end else begin
    if HandleAllocated
    then SendItemSelected(Index,Val)
    else PCustomListBoxItemRecord(GetCachedData(Index))^.Selected := Val;
  end;
end;

{------------------------------------------------------------------------------}
{ function TCustomListBox.GetSelected                                          }
{------------------------------------------------------------------------------}
function TCustomListBox.GetSelected(Index : integer) : boolean;
begin
  CheckIndex(Index);
  if HandleAllocated then
    Result:= TWSCustomListBoxClass(WidgetSetClass).GetSelected(Self, Index)
  else
    Result:= PCustomListBoxItemRecord(GetCachedData(Index))^.Selected;
end;

{------------------------------------------------------------------------------}
{ function TCustomListBox.GetSelCount                                          }
{------------------------------------------------------------------------------}
function TCustomListBox.GetSelCount : integer;
begin
  if HandleAllocated then
    Result := TWSCustomListBoxClass(WidgetSetClass).GetSelCount(Self)
  else
    Result := 0;
end;

function TCustomListBox.GetItemHeight: Integer;
begin
  Result := FItemHeight;
end;

procedure TCustomListBox.SetItemHeight(Value: Integer);
begin
  if (FItemHeight <> Value) and (Value > 0) then begin
    FItemHeight := Value;
    if (not HandleAllocated) or (csLoading in ComponentState) then exit;
    RecreateWnd;
  end;
end;

{------------------------------------------------------------------------------}
{ procedure TCustomListBox.SetSorted                                          }
{------------------------------------------------------------------------------}
procedure TCustomListBox.SetSorted(Val : boolean);
begin
  if Val <> FSorted then begin
    FSorted:= Val;
    UpdateSorted;
  end;
end;

{------------------------------------------------------------------------------}
{  procedure TCustomListBox.SetStyle                                }
{------------------------------------------------------------------------------}
procedure TCustomListBox.SetStyle(Val : TListBoxStyle);
begin
  if Val <> FStyle then begin
    FStyle:= Val;
    if HandleAllocated then
      TWSCustomListBoxClass(WidgetSetClass).SetStyle(Self);
  end;
end;

procedure TCustomListBox.DrawItem(Index: Integer; ARect: TRect;
  State: TOwnerDrawState);
{var
  Flags: Longint;
  Data: String;}
begin
  if Assigned(FOnDrawItem) then
    FOnDrawItem(Self, Index, ARect, State)
  else if not (odPainted in State) then
  begin
    FCanvas.FillRect(ARect);
    if (Index>=0) and (Index < Items.Count) then
    begin
      {Flags := DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);
      if not UseRightToLeftAlignment then
        Inc(Rect.Left, 2)
      else
        Dec(Rect.Right, 2);
      Data := '';
      if (Style in [lbVirtual, lbVirtualOwnerDraw]) then
        Data := DoGetData(Index)
      else
        Data := Items[Index];
      DrawText(FCanvas.Handle, PChar(Data), Length(Data), Rect, Flags);}
    end;
  end;
end;

procedure TCustomListBox.DoSelectionChange(User: Boolean);
begin
  if Assigned(OnSelectionChange) then
    OnSelectionChange(Self,User);
  if User and ClickOnSelChange then Click;
end;

procedure TCustomListBox.SendItemIndex;
begin
  LockSelectionChange;
  try
    // TODO 64bit
    TWSCustomListBoxClass(WidgetSetClass).SetItemIndex(Self, FItemIndex);
  finally
    UnlockSelectionChange;
  end;
end;

{------------------------------------------------------------------------------}
{  function TCustomListBox.GetCachedData                                       }
{------------------------------------------------------------------------------}
function TCustomListBox.GetCachedData(const AIndex: Integer): Pointer;
begin
  if not FCacheValid then raise EInvalidOperation.Create('Reading form invalid cache');
  Result := TExtendedStringList(FItems).Records[AIndex];
end;

{------------------------------------------------------------------------------}
{  function TCustomListBox.GetCachedDataSize                                   }
{                                                                              }
{  Returns the amount of data needed when the widged isn't realized in the     }
{  interface                                                                   }
{------------------------------------------------------------------------------}
function TCustomListBox.GetCachedDataSize: Integer;
begin
  Result := SizeOf(TCustomListBoxItemRecord);
end;

{------------------------------------------------------------------------------}
{  function TCustomListBox.SetItems                                   }
{------------------------------------------------------------------------------}
procedure TCustomListBox.SetItems(Value : TStrings);
begin
  if (Value <> FItems) then begin
//DebugLn('[TCustomListBox.SetItems] A FItems=',FItems.ClassName,' Value=',Value.ClassName);
    LockSelectionChange;
    FItems.Assign(Value);
    UnlockSelectionChange;
  end;
end;

{------------------------------------------------------------------------------}
{  function TCustomListBox.Create                                      }
{------------------------------------------------------------------------------}
constructor TCustomListBox.Create(TheOwner : TComponent);
begin
  inherited Create(TheOwner);
  LockSelectionChange;
  fCompStyle := csListBox;
  BorderStyle:= bsSingle;
  FItems := TExtendedStringList.Create(GetCachedDataSize);
  FCacheValid := True;
  FItemIndex:=-1;
  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;
  ParentColor := false;
  TabStop := true;
  SetInitialBounds(0, 0, 100, 80);
  UnlockSelectionChange;
end;

{------------------------------------------------------------------------------}
{  function TCustomListBox.Destroy                                      }
{------------------------------------------------------------------------------}
destructor TCustomListBox.Destroy;
begin
  Destroying;
  DestroyWnd;
  FreeAndNil(FCanvas);
  inherited Destroy;
  FreeAndNil(FItems);
end;

function TCustomListBox.GetItemIndex : integer;
begin
//DebugLn('[TCustomListBox.GetItemIndex] A ',FItems.ClassName);
  if HandleAllocated then 
  begin
    Result := TWSCustomListBoxClass(WidgetSetClass).GetItemIndex(Self);
    FItemIndex:=Result;
  end else
    Result:=FItemIndex;
//DebugLn('[TCustomListBox.GetItemIndex] END ');
end;

procedure TCustomListBox.SetItemIndex(Val : integer);
begin
  if (Val >= FItems.Count) then
    raise Exception.CreateFmt(rsIndexOutOfBounds,[ClassName,Val,FItems.Count]);
  if Val<0 then Val:=-1;
//DebugLn('[TCustomListBox.SetItemIndex] A ',FItems.ClassName,' ',Val);
  FItemIndex:=Val;
  if HandleAllocated and ([csLoading,csDestroying]*ComponentState=[]) then
    SendItemIndex;
//DebugLn('[TCustomListBox.SetItemIndex] END ',FItems.ClassName);
end;

{------------------------------------------------------------------------------
  procedure TCustomListBox.CheckIndex
------------------------------------------------------------------------------}
procedure TCustomListBox.CheckIndex(const AIndex: Integer);
begin
  if (AIndex < 0)
  or (AIndex >= Items.Count)
  then raise Exception.CreateFmt(rsIndexOutOfBounds,[ClassName, AIndex, Items.Count]);
end;

{------------------------------------------------------------------------------
  procedure TCustomListBox.Clear

  Delete all items.
------------------------------------------------------------------------------}
procedure TCustomListBox.Clear;
begin
  FItems.Clear;
end;

procedure TCustomListBox.LockSelectionChange;
begin
  inc(FLockSelectionChange);
end;

procedure TCustomListBox.UnlockSelectionChange;
begin
  dec(FLockSelectionChange);
end;

{------------------------------------------------------------------------------
  procedure TCustomListBox.MeasureItem(Index: Integer; var TheHeight: Integer);

 ------------------------------------------------------------------------------}
procedure TCustomListBox.MeasureItem(Index: Integer; var TheHeight: Integer);
begin
  if Assigned(OnMeasureItem) then
    OnMeasureItem(Self,Index,TheHeight);
end;

{------------------------------------------------------------------------------
  function TCustomListBox.GetIndexAtY(Y: integer): integer;

  Returns item index at y coordinate (including scrolling)
------------------------------------------------------------------------------}
function TCustomListBox.GetIndexAtY(Y: integer): integer;
begin
  Result:=-1;
  if (not HandleAllocated) then exit;
  Result:=GetListBoxIndexAtY(Self, Y);
end;

{------------------------------------------------------------------------------
  function TCustomListBox.ItemAtPos(const Pos: TPoint; Existing: Boolean
    ): Integer;

  Returns item index at y coordinate (including scrolling)
------------------------------------------------------------------------------}
function TCustomListBox.ItemAtPos(const Pos: TPoint; Existing: Boolean
  ): Integer;
begin
  Result:=GetIndexAtY(Pos.Y);
  if Existing then begin
    if Result>=Items.Count then Result:=-1;
  end else begin
    if (Result<0) and (Result>Items.Count) and PtInRect(ClientRect,Pos) then
      Result:=Items.Count;
  end;
end;

{------------------------------------------------------------------------------
  function TCustomListBox.ItemRect(Index: Integer): TRect;

  Returns coordinates of an item (including scrolling)
  Special: If Index=Count the rectangle is guessed (like VCL).
------------------------------------------------------------------------------}
function TCustomListBox.ItemRect(Index: Integer): TRect;
begin
  if (Index>=0) and (Index<Items.Count) then begin
    GetListBoxItemRect(Self,Index,Result);
  end else if (Index=Items.Count) and (Index>0) then begin
    GetListBoxItemRect(Self,Index-1,Result);
    OffsetRect(Result,0,Result.Bottom-Result.Top);
  end else begin
    FillChar(Result,SizeOf(Result),0);
  end;
end;

{------------------------------------------------------------------------------
  function TCustomListBox.ItemVisible(Index: Integer): boolean;

  Returns true if Item is partially visible.
------------------------------------------------------------------------------}
function TCustomListBox.ItemVisible(Index: Integer): boolean;
var
  ARect: TRect;
begin
  Result:=false;
  if (Index<0) or (Index>=Items.Count) then exit;
  if not GetListBoxItemRect(Self,Index,ARect) then exit;
  if (ARect.Bottom<0) or (ARect.Top>ClientHeight) then exit;
  Result:=true;
end;

{------------------------------------------------------------------------------
  function TCustomListBox.ItemFullyVisible(Index: Integer): boolean;

  Returns true if Item is fully visible.
------------------------------------------------------------------------------}
function TCustomListBox.ItemFullyVisible(Index: Integer): boolean;
var
  ARect: TRect;
begin
  Result:=false;
  if (Index<0) or (Index>=Items.Count) then exit;
  if not GetListBoxItemRect(Self,Index,ARect) then exit;
  if (ARect.Top<0) or (ARect.Bottom>ClientHeight) then exit;
  Result:=true;
end;

procedure TCustomListBox.MakeCurrentVisible;
var
  i: Integer;
begin
  i:=ItemIndex;
  if (i<0) or (i>=Items.Count) then exit;
  TopIndex:=ItemIndex;
end;


// back to stdctrls.pp