{%MainUnit ../stdctrls.pp}

{******************************************************************************
                               TCustomComboBox
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
  Method: TCustomComboBox.CreateWnd
  Params: ---
  Returns: Nothing

  Create the underlying interface-object.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.CreateWnd;
var
  NewStrings: TStrings;
begin
  inherited CreateWnd;

  // get the interface based item list
  NewStrings:= TWSCustomComboBoxClass(WidgetSetClass).GetItems(Self);
  // then delete internal list
  if (FItems<>NewStrings) and (FItems<>nil) then begin
    NewStrings.Assign(FItems);
    FItems.Free;
  end;
  // and use the interface based list
  FItems:= NewStrings;

  if FItemIndex <> -1 then
    TWSCustomComboBoxClass(WidgetSetClass).SetItemIndex(Self, FItemIndex);
  TWSCustomComboBoxClass(WidgetSetClass).SetStyle(Self, FStyle);
  TWSCustomComboBoxClass(WidgetSetClass).SetArrowKeysTraverseList(Self, FArrowKeysTraverseList);
  TWSCustomComboBoxClass(WidgetSetClass).SetReadOnly(Self, FReadOnly);
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.DestroyWnd
  Params: ---
  Returns: Nothing

  Destroy the underlying interface-object.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.DestroyWnd;
var NewStrings : TStrings;
begin
  if not HandleAllocated then RaiseGDBException('');
  // store itemindex
  GetItemIndex;
  // create an internal list for storing items internally
  NewStrings:= TStringList.Create;
  // copy from interface based list
  if FItems<>nil then begin
    NewStrings.Assign(FItems);
    // delete interface based list
    FItems.Free;
  end;
  // and use the internal list
  FItems:= NewStrings;

  inherited DestroyWnd;
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.DrawItem(Index: Integer; Rect: TRect;
    State: TOwnerDrawState);
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.DrawItem(Index: Integer; ARect: TRect;
  State: TOwnerDrawState);
begin
  //TControlCanvas(FCanvas).UpdateTextFlags;
  if Assigned(FOnDrawItem) then
    FOnDrawItem(Self, Index, ARect, State)
  else if not (odPainted in State) then
  begin
    FCanvas.FillRect(ARect);
    FCanvas.TextOut(ARect.Left + 2, ARect.Top, Items[Index]);
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.InitializeWnd
  Params: ---
  Returns: Nothing

  Initialize window after it has been created.
 ------------------------------------------------------------------------------}

procedure TCustomComboBox.InitializeWnd;
var ASelStart, ASelLength : integer;
begin
  inherited InitializeWnd;
  if FSelStart <> FSelLength then begin
    ASelStart:= FSelStart;
    ASelLength:= FSelLength;
    SelStart:= ASelStart;
    SelLength:= ASelLength;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.SetSorted
  Params: val - true means "sort" the combo
  Returns: Nothing

  Set the "sorted" property of the combobox and Sort the current entries.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetSorted(Val : boolean);
begin
  if (Val <> FSorted) then begin
    FSorted:= Val;
    UpdateSorted;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.SetMaxLength
  Params: val -
  Returns: Nothing

  Set the maximum length for user input.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetMaxLength(Val : integer);
begin
  if Val < 0 then Val:= 0;
  if Val<>MaxLength then begin
    fMaxlength:=Val;
    if HandleAllocated then
      TWSCustomComboBoxClass(WidgetSetClass).SetMaxLength(Self, Val);
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.GetMaxLength
  Params: ---
  Returns: the maximum length of user input

  Get the maximum length for user input.
 ------------------------------------------------------------------------------}
function TCustomComboBox.GetMaxLength : integer;
begin
  if HandleAllocated then
    fMaxLength := TWSCustomComboBoxClass(WidgetSetClass).GetMaxLength(Self);
  Result:=fMaxLength;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.DoChange
  Params: msg -
  Returns: Nothing

  Call handler for "OnChange"-event if one is assigned.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.LMChange(var Msg);
begin
  Change;
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.Change;

  Called on change
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.Change;
begin
  inherited Changed;
  if Assigned(FOnChange) then FOnChange(Self);
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.Select;

  Returns the selected part of text-field.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.Select;
begin
  if Assigned(FOnSelect) then
    FOnSelect(Self)
  else
    Change;
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.DropDown;

  Called whenever the list popups.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.DropDown;
begin
  if Assigned(FOnDropDown) then FOnDropDown(Self);
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.CloseUp;

  Called whenever the list hides.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.CloseUp;
begin
  if [csLoading,csDestroying,csDesigning]*ComponentState<>[] then exit;
  if not ReadOnly then
    EditingDone;
  if Assigned(FOnCloseUp) then FOnCloseUp(Self);
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.AdjustDropDown;

 ------------------------------------------------------------------------------}
procedure TCustomComboBox.AdjustDropDown;
var
  Count, MinItemsWidth, MinItemsHeight: Integer;
begin
  if (not HandleAllocated) or (not DroppedDown) then exit;
  Count := Items.Count;
  if Count > DropDownCount then Count := DropDownCount;
  if Count < 1 then Count := 1;
  MinItemsWidth:=ItemWidth;
  MinItemsHeight:=Count*ItemHeight;
  SetComboMinDropDownSize(Handle,MinItemsWidth,MinItemsHeight,Count);
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.GetSelText
  Params: ---
  Returns: selected text

  Returns the selected part of text-field.
 ------------------------------------------------------------------------------}
function TCustomComboBox.GetSelText: string;
begin
  //debugln('TCustomComboBox.GetSelText ');
  if FStyle in [csDropDown, csSimple] then
    Result:= Copy(Text, SelStart, SelLength)
  else
    Result:= '';
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.SetSelText
  Params: val - new string for text-field
  Returns: nothings

  Replace the selected part of text-field with "val".
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetSelText(const Val: string);
var
  OldText, NewText: string;
begin
  //debugln('TCustomComboBox.SetSelText ',Val);
  if FStyle in [csDropDown, csSimple] then begin
    OldText:=Text;
    NewText:=LeftStr(OldText,SelStart-1)+Val
               +RightStr(OldText,length(OldText)-SelStart-SelLength+1);
    Text:=NewText;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.GetSelStart
  Params: ---
  Returns: starting index of selected text

  Returns starting index of selected text
 ------------------------------------------------------------------------------}
function TCustomComboBox.GetSelStart : integer;
begin
  if HandleAllocated then
    fSelStart:=TWSCustomComboBoxClass(WidgetSetClass).GetSelStart(Self);
  Result:=fSelStart;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.SetSelStart
  Params: val -
  Returns: nothing

  Sets starting index for selected text.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetSelStart(Val : integer);
begin
  fSelStart:=Val;
  if HandleAllocated then
    TWSCustomComboBoxClass(WidgetSetClass).SetSelStart(Self, Val);
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.GetSelLength
  Params: ---
  Returns: length of selected text

  Returns length of selected text
 ------------------------------------------------------------------------------}
function TCustomComboBox.GetSelLength : integer;
begin
  if HandleAllocated then
    fSelLength := TWSCustomComboBoxClass(WidgetSetClass).GetSelLength(Self);
  Result:=fSelLength;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.SetSelLength
  Params: val -
  Returns: nothing

  Sets length of selected text.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetSelLength(Val : integer);
begin
  fSelLength:=Val;
  if HandleAllocated then
    TWSCustomComboBoxClass(WidgetSetClass).SetSelLength(Self, Val);
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.SelectAll
  Params: -
  Returns: nothing

  Select entire text.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SelectAll;
var
  CurText: String;
begin
  //debugln('TCustomComboBox.SelectAll ');
  if (FStyle in [csDropDown, csSimple]) then begin
    CurText:=Text;
    if (CurText <> '') then begin
      SetSelStart(0);
      SetSelLength(Length(CurText));
    end;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.SetStyle
  Params: val - new style for combobox
  Returns: nothing

  Sets a new style for the combobox.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetStyle(Val : TComboBoxStyle);
begin
  if Val <> FStyle then begin
    FStyle:= Val;
    if HandleAllocated and ([csLoading,csDestroying]*ComponentState=[]) then
      TWSCustomComboBoxClass(WidgetSetClass).SetStyle(Self, Val);
  end;
end;

procedure TCustomComboBox.SetArrowKeysTraverseList(Value : Boolean);
begin
  if Value <> FArrowKeysTraverseList then begin
    FArrowKeysTraverseList := Value;
    if HandleAllocated and ([csLoading,csDestroying]*ComponentState=[]) then
      TWSCustomComboBoxClass(WidgetSetClass).SetArrowKeysTraverseList(Self, Value);
   end;
end;

procedure TCustomComboBox.WMChar(var Message: TLMChar);
begin
  // all normal characters are handled by the ComboBox
  //debugln('TCustomEdit.WMChar ',DbgSName(Self),' ',dbgs(Message.CharCode));
  if (Message.CharCode in [ord('A')..ord('Z'),ord('a')..ord('z')]) then
    // eat normal keys, so they don't trigger accelerators
    Message.Result := 1
  else
    inherited WMChar(Message);
end;

procedure TCustomComboBox.KeyDown(var Key: Word; Shift: TShiftState);
var
  skip : Boolean;
  UserDropDown: boolean;
begin
  Skip := False;
  UserDropDown := ((Shift *[ssCtrl] = [ssCtrl]) and (Key = VK_DOWN));

  if AutoDropDown or UserDropDown or FReturnArrowState then
  begin
    case Key of
      VK_TAB,VK_RETURN:
       begin

        if FReturnArrowState = True then
        begin
          SetArrowKeysTraverseList(False); //we need this here, else we cannot traverse popup list
          FReturnArrowState := False;
        end;

        DroppedDown := False;
       end;
    else
      begin
        if ArrowKeysTraverseList = False then
        begin
          SetArrowKeysTraverseList(True); //we need this here, else we cannot traverse popup list
          FReturnArrowState := True;
          Skip := True;
        end;
        //AutoDropDown := True;
        DroppedDown := True;
        if UserDropDown then
          Skip := True;
      end;
    end;
  end;
  
  if Style=csDropDownList then begin
    //debugln('TCustomComboBox.KeyDown ');
    // DropDownList: allow only navigation keys
    if not (Key in [VK_UP,VK_DOWN,VK_END,VK_HOME,VK_PRIOR,VK_NEXT,VK_TAB,
      VK_RETURN])
    then begin
      Skip := True;
    end;
  end;

  if Skip then
    Key := VK_UNKNOWN
  else
    inherited KeyDown(Key, Shift);
end;

{------------------------------------------------------------------------------
  function TCustomComboBox.SelectItem(const AnItem: String): Boolean;

  Selects the item with the Text of AnItem
 ------------------------------------------------------------------------------}
function TCustomComboBox.SelectItem(const AnItem: String): Boolean;
var
  i: integer;
  ValueChanged: boolean;
begin
  i:=Items.IndexOf(AnItem);
  if i>=0 then begin
    Result:=true;
    ValueChanged:=ItemIndex<>i;
    ItemIndex:=i;
    Text:=Items[i];
    if ValueChanged then begin
      Click;
      Select;
    end;
  end else
    Result:=false;
end;

{------------------------------------------------------------------------------
  function TCustomComboBox.GetItemCount: Integer;

  Returns the number of items
 ------------------------------------------------------------------------------}
function TCustomComboBox.GetItemCount: Integer;
begin
  Result:=Items.Count;
end;

{------------------------------------------------------------------------------
  function TCustomComboBox.GetItemHeight: Integer;

  Gets default ItemHeight.
 ------------------------------------------------------------------------------}
function TCustomComboBox.GetItemHeight: Integer;
begin
  Result:=FItemHeight;
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.SetDropDownCount(const AValue: Integer);

  Sets the number of items that fits into the drop down list.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetDropDownCount(const AValue: Integer);
begin
  FDropDownCount:=AValue;
  // ToDo
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.SetItemHeight(const AValue: Integer);

  Sets default ItemHeight. 0 or negative values are ignored.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetItemHeight(const AValue: Integer);
begin
  if AValue=FItemHeight then exit;
  FItemHeight:=AValue;
  // ToDo
end;

{------------------------------------------------------------------------------
  function TCustomComboBox.GetDroppedDown: Boolean;

  Returns true, if list is shown.
 ------------------------------------------------------------------------------}
function TCustomComboBox.GetDroppedDown: Boolean;
begin
  Result:=FDroppedDown;
end;

{------------------------------------------------------------------------------
  function TCustomComboBox.GetItemWidth: Integer;

  The ItemWidth is the minimum pixels, that is allocated for the items in the
  dropdown list.
 ------------------------------------------------------------------------------}
function TCustomComboBox.GetItemWidth: Integer;
begin
  Result:=FItemWidth;
end;

{------------------------------------------------------------------------------
  function TCustomComboBox.GetDroppedDown: Boolean;


 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetDroppedDown(const AValue: Boolean);
begin
  if FDroppedDown=AValue then exit;
  if (not HandleAllocated) or (csLoading in ComponentState) then exit;
  ComboBoxDropDown(Handle,AValue);
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.SetItemWidth(const AValue: Integer);

  The ItemWidth is the minimum pixels, that is allocated for the items in the
  dropdown list.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetItemWidth(const AValue: Integer);
begin
  if FItemWidth=AValue then exit;
  FItemWidth:=AValue;
  AdjustDropDown;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.SetItems
  Params: value - stringlist with items for combobox
  Returns: nothing

  Assigns items for ComboBox from a stringlist.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetItems(Value : TStrings);
begin
  if (Value <> FItems) then begin
    FItems.Assign(Value);
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.Create
  Params: AOwner - owner of the object
  Returns: reference to the newly created object

  Creates the object.
 ------------------------------------------------------------------------------}
constructor TCustomComboBox.Create(TheOwner : TComponent);
begin
  inherited Create(TheOwner);

  fCompStyle := csComboBox;
  SetInitialBounds(0,0,100,25);
  FItems := TStringlist.Create;
  FItemIndex:=-1;
  FDropDownCount:=8;
  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;
  ArrowKeysTraverseList := True;
  TabStop := true;
  ParentColor := false;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.Destroy
  Params: ---
  Returns: nothing

  Destroys the object.
 ------------------------------------------------------------------------------}
destructor TCustomComboBox.Destroy;
begin
  if HandleAllocated then DestroyHandle;
  FCanvas.Free;
  FCanvas:=nil;
  FItems.Free;
  FItems:=nil;
  inherited Destroy;
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.AddItem(const Item: String; AnObject: TObject);

  Adds an Item with an associated object to Items
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.AddItem(const Item: String; AnObject: TObject);
begin
  Items.AddObject(Item,AnObject);
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.AddHistoryItem(const Item: string;
    MaxHistoryCount: integer; SetAsText, CaseSensitive: boolean);

  Adds an Item as first item. Removes the Item from old positions and removes
  last item if history is full.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.AddHistoryItem(const Item: string;
  MaxHistoryCount: integer; SetAsText, CaseSensitive: boolean);
begin
  AddHistoryItem(Item,nil,MaxHistoryCount,SetAsText,CaseSensitive);
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.AddHistoryItem(const Item: string;
    AnObject: TObject; MaxHistoryCount: integer;
    SetAsText, CaseSensitive: boolean);

  Adds an Item as first item. Removes the Item from old positions and removes
  last item if history is full.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.AddHistoryItem(const Item: string; AnObject: TObject;
  MaxHistoryCount: integer; SetAsText, CaseSensitive: boolean);
var i: integer;
begin
  // insert as first
  if (Items.Count=0)
  or (CaseSensitive and (AnsiCompareText(Items[0],Item)<>0))
  or (not CaseSensitive and (Items[0]<>Item)) then
  begin
    Items.InsertObject(0,Item,AnObject);
  end;
  // delete old
  for i:=Items.Count-1 downto 1 do begin
    if (CaseSensitive and (AnsiCompareText(Items[i],Item)=0))
    or (not CaseSensitive and (Items[i]=Item)) then
      Items.Delete(i);
  end;
  // delete overflow items
  while Items.Count>MaxHistoryCount do
    Items.Delete(Items.Count-1);
  // set as text
  if SetAsText then
    Text:=Item;
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.Clear;

  Removes all Items
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.Clear;
begin
  Items.Clear;
  Text:='';
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.ClearSelection;

  Unselects all items.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.ClearSelection;
begin
  ItemIndex := -1;
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.MeasureItem(Index: Integer; var TheHeight: Integer);

 ------------------------------------------------------------------------------}
procedure TCustomComboBox.MeasureItem(Index: Integer; var TheHeight: Integer);
begin
  if Assigned(OnMeasureItem) then
    OnMeasureItem(Self,Index,TheHeight);
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.GetItemIndex
  Params: ---
  Returns: index of the currently selected item

  Returns index of the currently selected item in the combobox. -1 is returned
  if no item is currently selected.
 ------------------------------------------------------------------------------}
function TCustomComboBox.GetItemIndex : integer;
begin
  if HandleAllocated then
    FItemIndex:= TWSCustomComboBoxClass(WidgetSetClass).GetItemIndex(Self);
  Result:=FItemIndex;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.RealSetText
  Params: AValue -
  Returns: nothing

  If the text AValue occurs in the list of strings, then sets the itemindex,
  otherwise does the default action
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.RealSetText(const AValue: TCaption);
var
  I: integer;
begin
  I := FItems.IndexOf(AValue);
  if I >= 0 then
    ItemIndex := I
  else if (not (csLoading in ComponentState)) then
    FItemIndex := -1;
  inherited;
end;

{------------------------------------------------------------------------------
  Method: TCustomComboBox.SetItemIndex
  Params: Val -
  Returns: nothing

  Sets ths index of the currently selected item in the combobox.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.SetItemIndex(Val : integer);
begin
  //if CompareText(Name,'TextToFindComboBox')=0 then
  //  debugln('TCustomComboBox.SetItemIndex A ',DbgSName(Self),' Text="',Text,'"');
  if Val=GetItemIndex then exit;
  if Val>=Items.Count then exit;

  FItemIndex:= Val;
  //if (FItemIndex>=0) and (not (csLoading in ComponentState)) then
  //  Text:=FItems[FItemIndex];
  if HandleAllocated then
  begin
    TWSCustomComboBoxClass(WidgetSetClass).SetItemIndex(Self, FItemIndex);
  end else begin
    // remember text, in case one reads text without creating handle
    Text := FItems.Strings[FItemIndex];
  end;
  //if CompareText(Name,'TextToFindComboBox')=0 then
  //  debugln('TCustomComboBox.SetItemIndex END ',DbgSName(Self),' Text="',Text,'"');
end;

{------------------------------------------------------------------------------
  Procedure TCustomComboBox.LMDrawListItem(var TheMessage : TLMDrawListItem);

  Handler for custom drawing items.
 ------------------------------------------------------------------------------}
Procedure TCustomComboBox.LMDrawListItem(var TheMessage : TLMDrawListItem);
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
    end;
    DrawItem(ItemID, Area, ItemState);
    if odFocused in ItemState then
      {DrawFocusRect(hDC, rcItem)};
    FCanvas.Handle := 0;
  end;
end;

procedure TCustomComboBox.LMMeasureItem(var TheMessage: TLMMeasureItem);
var
  AHeight: Integer;
begin
  with TheMessage.MeasureItemStruct^ do begin
    if Self.ItemHeight <> 0 then
      AHeight := Self.ItemHeight
    else
      Aheight := ItemHeight;
    MeasureItem(ItemId, AHeight);
    if AHeight>0 then
      ItemHeight := AHeight;
  end;
end;

procedure TCustomComboBox.LMSelChange(var TheMessage);
begin
  if [csLoading,csDestroying,csDesigning]*ComponentState<>[] then exit;
  if Assigned(OnSelect) then
    OnSelect(Self);
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.CNCommand(var TheMessage: TLMCommand);

  Handler for various notifications.
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.CNCommand(var TheMessage: TLMCommand);
begin
  case TheMessage.NotifyCode of
    CBN_DROPDOWN:
      begin
        FDroppedDown:=true;
        DropDown;
        AdjustDropDown;
      end;
    CBN_CLOSEUP:
      begin
        FDroppedDown:=false;
        CloseUp;
      end;
  end;
end;

procedure TCustomComboBox.SetReadOnly(const AValue: Boolean);
begin
  if FReadOnly=AValue then exit;
  FReadOnly:=AValue;
  if HandleAllocated then
    TWSCustomComboBoxClass(WidgetSetClass).SetReadOnly(Self, AValue);
end;

{------------------------------------------------------------------------------
  procedure TCustomComboBox.UpdateSorted;
 ------------------------------------------------------------------------------}
procedure TCustomComboBox.UpdateSorted;
var
  lText: string;
begin
  if HandleAllocated then
    TWSCustomComboBoxClass(WidgetSetClass).Sort(Self, Items, FSorted)
  else if FItems is TStringList then
  begin
    // remember text
    lText := Text;
    TStringList(FItems).Sorted := FSorted;
    ItemIndex := FItems.IndexOf(lText);
  end;
end;

// included by stdctrls.pp
