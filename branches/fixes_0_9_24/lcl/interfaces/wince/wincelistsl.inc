// included by win32int.pp

{******************************************************************************
                                 win32listsl.inc
                 TWin32ListStringList and TWin32CListStringList

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

{$IFOPT H+}
  {$DEFINE H_PLUS}
{$ELSE}
  {$H+}
  {$UNDEF H_PLUS}
{$ENDIF}

{*************************************************************}
{                      Default compare function               }
{*************************************************************}

Function DefaultCompareFunc(A, B: HWND): Integer; CDecl;
Var
  AStr, BStr: PWideChar;
Begin
  AStr:=nil;
  BStr:=nil;
  GetWindowText(A, AStr, GetWindowTextLength(A) + 1);
  GetWindowText(B, BStr, GetWindowTextLength(B) + 1);
  Result := WideCompareStr(widestring(AStr), widestring(BStr));//roozbeh:does this work?!
end;

Procedure SetComboHeight(Sender: TWinControl; AHeight:Integer);
var
  Left, Top, Width: integer;
begin
  Left := Sender.Left;
  Top := Sender.Top;
  Width := Sender.Width;
  LCLBoundsToWin32Bounds(Sender, Left, Top, Width, AHeight);
  MoveWindow(Sender.Handle, Left, Top, Width, AHeight, true);//roozbeh check if this works!
  LCLControlSizeNeedsUpdate(Sender, true);
end;

{*************************************************************}
{                      TWinCEListStringList methods           }
{*************************************************************}

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.Create
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Constructor TWinCEListStringList.Create(List : HWND; TheOwner: TWinControl);
Begin
  Inherited Create;
  If List = HWND(Nil) Then
    Raise Exception.Create('Unspecified list window');
    //Assert(False, 'Trace:Unspecified list window');
  FWinCEList := List;
  FSender := TheOwner;

  //Set proper wince flags for ComboBox/ListBox and get/set Combo Height
  InitFlags;
  // Determine if the list is sorted
  FSorted := (UINT(GetWindowLong(FWinCEList, GWL_STYLE)) and FFlagSort <> 0);
End;

procedure TWinCEListStringList.InitFlags;
begin
  FFlagSort         := UINT(LBS_SORT);
  FFlagGetText      := UINT(LB_GETTEXT);
  FFlagGetTextLen   := UINT(LB_GETTEXTLEN);
  FFlagGetCount     := UINT(LB_GETCOUNT);
  FFlagResetContent := UINT(LB_RESETCONTENT);
  FFlagDeleteString := UINT(LB_DELETESTRING);
  FFlagInsertString := UINT(LB_INSERTSTRING);
  FFlagAddString    := UINT(LB_ADDSTRING);
  FFlagGetItemData  := UINT(LB_GETITEMDATA);
  FFlagSetItemData  := UINT(LB_SETITEMDATA);
  FFlagGetItemIndex := UINT(LB_GETCURSEL);
  FFlagSetItemIndex := UINT(LB_SETCURSEL);
  FFlagGetSelected  := UINT(LB_GETSEL);
  FFlagSetSelected  := UINT(LB_SETSEL);
end;

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.SetSorted
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCEListStringList.SetSorted(Val: Boolean);
Begin
  If Val <> FSorted Then
  Begin
    FSorted:= Val;
    Sort;
  End;
End;

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.Sort
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCEListStringList.Sort;
Begin
  // The win api doesn't allow to change the sort on the fly,
  // so is needed to recreate the window
  RecreateWnd(FSender);
End;

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.Assign
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCEListStringList.Assign(Source: TPersistent);
Var
  S: TStrings;
  Counter: Integer;
  AnIndex: Integer;
  tmpStr : PWideChar;
Begin
  { Do not call inherited Assign as it does things we do not want to happen }
  If Source Is TStrings Then
  Begin
    S:= TStrings(Source);
    QuoteChar:=S.QuoteChar;
    Delimiter:=S.Delimiter;
    NameValueSeparator:=S.NameValueSeparator;
    Windows.SendMessage(FWinCEList, FFlagResetContent, 0, 0);
    For Counter := 0 To (TStrings(Source).Count - 1) Do
    Begin
      tmpStr := StringToPWideChar(s[Counter]);
      AnIndex := Windows.SendMessage(FWinCEList, FFlagAddString, 0, LPARAM(PWideChar(tmpStr))); //Insert
      FreeMem(tmpStr);
      PutObject(AnIndex, S.Objects[Counter]);
    end;
  End
  Else
    inherited Assign(Source);
End;


{------------------------------------------------------------------------------
  Method: TWinCEListStringList.Add
  Params:
  Returns:

 ------------------------------------------------------------------------------}
function TWinCEListStringList.Add(const S: string): Integer;
begin
  Result := Count;
  Insert(Count, S);
  if FSorted then
    Result := FLastInsertedIndex;
end;

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.Get
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Function TWinCEListStringList.Get(Index: Integer): String;
Var
  Item: PWideChar;
Begin
  If (Index < 0) Or (Index >= Count) Then
    Raise Exception.Create('Out of bounds.')
  Else
  Begin
    Item := PWideChar(SysAllocStringLen(nil,Windows.SendMessage(FWinCEList, FFlagGetTextLen, Index, 0)));
    Windows.SendMessage(FWinCEList, FFlagGetText, Index, LPARAM(Item));
  End;
  Result := String(WideString(Item));//roozbeh:maybe WideStringToString?
  SysFreeString(Item);
End;

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.GetCount
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Function TWinCEListStringList.GetCount: Integer;
Begin
  Result := Windows.SendMessage(FWinCEList, FFlagGetCount, 0, 0);
End;

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.Clear
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCEListStringList.Clear;
Begin
  Windows.SendMessage(FWinCEList, FFlagResetContent, 0, 0);
End;

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.Delete
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCEListStringList.Delete(Index: Integer);
Begin
  Windows.SendMessage(FWinCEList, FFlagDeleteString, Index, 0);
End;

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.GetObject
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Function TWinCEListStringList.GetObject(Index: Integer): TObject;
Begin
  HWND(Result) := Windows.SendMessage(FWinCEList, FFlagGetItemData, Index, 0);
End;

{------------------------------------------------------------------------------
  Method: TWinCEListStringList.Insert
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCEListStringList.Insert(Index: Integer; Const S: String);
var
tmpS : PWideChar;
Begin
  FLastInsertedIndex := Index;
  tmpS := StringToPWideChar(s);
  If FSorted Then
    FLastInsertedIndex := Windows.SendMessage(FWinCEList, FFlagAddString, 0, LPARAM(PWideChar(tmpS)))
  Else
    Windows.SendMessage(FWinCEList, FFlagInsertString, Index, LPARAM(PWideChar(tmpS)));
    FreeMem(tmpS);
End;

procedure TWinCEListStringList.Put(Index: integer; const S: string);
var
  lItemIndex: integer;
  lSelected: boolean;
begin
  // remember selection
  lItemIndex := -1;
  if FFlagGetSelected <> 0 then
  begin
    lItemIndex := SendMessage(FWinCEList, FFlagGetSelected, Index, 0);
    lSelected := lItemIndex > 0;
    if lItemIndex <> LB_ERR then
      lItemIndex := Index;
  end;
  if lItemIndex = -1 then
  begin
    lItemIndex := SendMessage(FWinCEList, FFlagGetItemIndex, 0, 0);
    lSelected := true;
  end;
  
  inherited;
 
  if lSelected then
  begin
    if (FFlagSetSelected = 0) 
      or (SendMessage(FWinCEList, FFlagSetSelected, Windows.WParam(true), lItemIndex) = -1) then
    begin
      SendMessage(FWinCEList, FFlagSetItemIndex, lItemIndex, 0);
    end;
  end;
end;
    
{------------------------------------------------------------------------------
  Method: TWinCEListStringList.PutObject
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCEListStringList.PutObject(Index: Integer; AObject: TObject);
Begin
  Windows.SendMessage(FWinCEList, FFlagSetItemData, Index, LPARAM(AObject));
End;

{ TWinCEComboBoxStringList }

procedure TWinCEComboBoxStringList.InitFlags;
var
  R: TRect;
begin
  FFlagSort         := UINT(CBS_SORT);
  FFlagGetText      := UINT(CB_GETLBTEXT);
  FFlagGetTextLen   := UINT(CB_GETLBTEXTLEN);
  FFlagGetCount     := UINT(CB_GETCOUNT);
  FFlagResetContent := UINT(CB_RESETCONTENT);
  FFlagDeleteString := UINT(CB_DELETESTRING);
  FFlagInsertString := UINT(CB_INSERTSTRING);
  FFlagAddString    := UINT(CB_ADDSTRING);
  FFlagGetItemData  := UINT(CB_GETITEMDATA);
  FFlagSetItemData  := UINT(CB_SETITEMDATA);
  FFlagGetItemIndex := UINT(CB_GETCURSEL);
  FFlagSetItemIndex := UINT(CB_SETCURSEL);
  FFlagGetSelected  := UINT(0);
  FFlagSetSelected  := UINT(0);
  //Get edit and item sizes
  Windows.GetClientRect(FWinCEList,@R);
  FEditHeight := R.Bottom;
  FItemHeight := Windows.SendMessage(FWinCEList, CB_GETITEMHEIGHT, 0, 0);
  FDropDownCount := TComboBox(FSender).DropDownCount;
  If FDropDownCount = 0 then
    FDropDownCount := 8;
end;

procedure TWinCEComboBoxStringList.Assign(Source: TPersistent);
var
  EditText: string;
  lItemIndex: integer;
begin
  if Source is TStrings then
  begin
    // save text in edit box, assigning strings clears the text
    TWinCEWSCustomComboBox.GetText(FSender, EditText);

    inherited Assign(Source);
    
    // restore text in edit box
    SetComboHeight(FSender, ComboHeight);
    TWinCEWSCustomComboBox.SetText(FSender, EditText);
    lItemIndex := IndexOf(EditText);
    if lItemIndex <> -1 then
      TWinCEWSCustomComboBox.SetItemIndex(TCustomComboBox(FSender), lItemIndex);
  end else
    inherited Assign(Source);
end;

function TWinCEComboBoxStringList.GetComboHeight: integer;
begin
  if Count = 0 then
  begin
    Result := FEditHeight + FItemHeight + 2;
  end else begin
    Result := FEditHeight + FDropDownCount*FItemHeight + 2;
  end;
end;

procedure TWinCEComboBoxStringList.Clear;
begin
  SetComboHeight(FSender, FEditHeight + FItemHeight + 2);
  inherited;
end;

procedure TWinCEComboBoxStringList.Delete(Index: integer);
begin
  if GetCount <= 1 then
    SetComboHeight(FSender, FEditHeight + FItemHeight + 2);
  inherited Delete(Index);
end;

procedure TWinCEComboBoxStringList.Insert(Index: integer; const S: string);
begin
  if GetCount = 0 then
    SetComboHeight(FSender, FEditHeight + FDropDownCount*FItemHeight + 2);
  inherited Insert(Index, S);
end;

    
{ TWinCECheckListBoxStrings }

constructor TWinCECheckListBoxStrings.Create(List : HWND; TheOwner: TWinControl);
begin
  inherited Create(List, TheOwner);
  with FDefaultItem do begin
    Checked := false;
    TheObject := nil;
  end;
end;

function TWinCECheckListBoxStrings.GetChecked(const Index: Integer): Boolean;
var
  Data: PWinCECheckListBoxItemRecord;
begin
  Data := GetItemRecord(Index, false);
  Result := Data^.Checked
end;

procedure TWinCECheckListBoxStrings.SetChecked(const Index: Integer;
  const AValue: Boolean);
var
  ItemRecord: PWinCECheckListBoxItemRecord;
begin
  ItemRecord := GetItemRecord(Index, true);
  ItemRecord^.Checked := AValue;
  SetItemRecord(Index, ItemRecord);
end;

function TWinCECheckListBoxStrings.GetItemRecord(const Index: Integer;
  const CreateNew: boolean): PWinCECheckListBoxItemRecord;
begin
  Result := PWinCECheckListBoxItemRecord(Windows.SendMessage(FWinCEList, LB_GETITEMDATA, Index, 0));
  if (not Assigned(Result)) then begin
    if CreateNew then begin
      Result := new(PWinCECheckListBoxItemRecord);
      Result^ := FDefaultItem;
    end
    else Result := @FDefaultItem;
  end;
end;

procedure TWinCECheckListBoxStrings.SetItemRecord(const Index: Integer;
  ItemRecord: PWinCECheckListBoxItemRecord);
begin
  Windows.SendMessage(FWinCEList, LB_SETITEMDATA, Index, LPARAM(ItemRecord));
end;

procedure TWinCECheckListBoxStrings.Clear;
begin
  DeleteItemRecords(FWinCEList);
  inherited Clear;
end;

procedure TWinCECheckListBoxStrings.Delete(Index: Integer);
begin
  DeleteItemRecord(FWinCEList, Index);
  inherited Delete(Index);
end;

function TWinCECheckListBoxStrings.GetObject(Index: Integer): TObject;
begin
  Result:= GetItemRecord(Index, false)^.TheObject;
end;

procedure TWinCECheckListBoxStrings.PutObject(Index: Integer; AObject: TObject);
var
  ItemRecord: PWinCECheckListBoxItemRecord;
begin
  ItemRecord := GetItemRecord(Index, true);
  ItemRecord^.TheObject := AObject;
  SetItemRecord(Index, ItemRecord);
end;

class procedure TWinCECheckListBoxStrings.DeleteItemRecords(const List: HWND);
var
  Index: Integer;
  ItemCount: Integer;
begin
  ItemCount := Windows.SendMessage(List, LB_GETCOUNT, 0, 0);
  for Index := 0 to ItemCount-1 do
    DeleteItemRecord(List, Index);
end;

class procedure TWinCECheckListBoxStrings.DeleteItemRecord(const List: HWND;const Index: integer);
var
  ItemRecord: PWinCECheckListBoxItemRecord;
begin
  ItemRecord := PWinCECheckListBoxItemRecord(Windows.SendMessage(List, LB_GETITEMDATA, Index, 0));
  if Assigned(ItemRecord)
    then Dispose(ItemRecord);
end;

{*************************************************************}
{                      TWinCECListStringList methods            }
{*************************************************************}

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.Create
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Constructor TWinCECListStringList.Create(List : HWND; TheOwner: TWinControl);
Begin
  Inherited Create;
  If List = HWND(Nil) Then
    Raise Exception.Create('Unspecified list widget');
  FWinCECList := List;
  FSorted := (GetWindowLong(FWinCECList, GWL_STYLE) and LBS_SORT <> 0);
  FSender:=TheOwner;
End;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.SetSorted
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCECListStringList.SetSorted(Val: Boolean);
Begin
  If Val <> FSorted Then
  Begin
    FSorted := Val;
    Sort;
  End;
End;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.Sort
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCECListStringList.Sort;
Begin
  // The win api doesn't allow to change the sort on the fly,
  // so is needed to recreate the window
  RecreateWnd(FSender);
End;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.Assign
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCECListStringList.Assign(Source: TPersistent);
Var
  Counter: Integer;
Begin
  { Do not call inherited Assign as it does things we do not want to happen }
  If Source Is TStrings Then
  Begin
    Clear;
    For Counter :=  0 To (TStrings(Source).Count - 1) Do
      InsertObject(0, TStrings(Source)[Counter], TStrings(Source).Objects[Counter]);
  End
  Else
    Inherited Assign(Source);
End;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.Clear
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCECListStringList.Clear;
Begin
  Windows.SendMessage(FWinCECList, LB_RESETCONTENT, 0, 0);
End;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.Delete
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TWinCECListStringList.Delete(Index: Integer);
begin
  Windows.SendMessage(FWinCECList, LB_DELETESTRING, Index, 0);
end;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.Get
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Function TWinCECListStringList.Get(Index: Integer): String;
Var
  Item: PWideChar;
Begin
  If (Index < 0) Or (Index >= Count) Then
    Raise Exception.Create('Out of bounds.')
  Else
  Begin
    Item := PWideChar(SysAllocStringLen(nil,Windows.SendMessage(FWinCECList,LB_GETTEXTLEN,Index,0)));
    Windows.SendMessage(FWinCECList, LB_GETTEXT, Index, LPARAM(Item));
    Result := String(WideString(Item));//roozbeh maybe Widestringtostring later
    SysFreeString(Item);
  End;
End;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.GetCount
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Function TWinCECListStringList.GetCount: Integer;
Begin
  Result := Windows.SendMessage(FWinCECList, LB_GETCOUNT, 0, 0);
End;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.GetObject
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Function TWinCECListStringList.GetObject(Index: Integer): TObject;
Begin
  HWND(Result) := Windows.SendMessage(FWinCECList, LB_GETITEMDATA, Index, 0);
End;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.Insert
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCECListStringList.Insert(Index: Integer; Const S: String);
var
tmpS : PWideChar;
Begin
  tmpS := StringToPWideChar(S);
  If FSorted Then
    Windows.SendMessage(FWinCECList,LB_ADDSTRING, 0, LPARAM(PWideChar(tmpS)))
  Else
    Windows.SendMessage(FWinCECList,LB_INSERTSTRING, Index, LPARAM(PWideChar(tmpS)));
  FreeMem(tmpS);
End;

{------------------------------------------------------------------------------
  Method: TWinCECListStringList.PutObject
  Params:
  Returns:

 ------------------------------------------------------------------------------}
Procedure TWinCECListStringList.PutObject(Index: Integer; AObject: TObject);
Begin
  Windows.SendMessage(FWinCECList, LB_SETITEMDATA, Index, LPARAM(AObject));
End;

{$IFDEF H_PLUS}
  {$UNDEF H_PLUS}
{$ELSE}
  {$H-}
{$ENDIF}



