{%MainUnit ../extctrls.pp}

{******************************************************************************
                                   TNBPages
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

{ $DEFINE NOTEBOOK_DEBUG}

{------------------------------------------------------------------------------
  TNBPages Constructor
 ------------------------------------------------------------------------------}
constructor TNBPages.Create(thePageList: TList; theNotebook: TCustomNotebook);
begin
  inherited Create;
  // Create the page list and a notebook
  fPageList := thePageList;
  fNotebook := theNotebook;
end;

{------------------------------------------------------------------------------
  TNBPages Get
 ------------------------------------------------------------------------------}
function TNBPages.Get(Index: Integer): String;
begin
//DebugLn('TNBPages.Get Index=',Index);
  if (Index<0) or (Index>=fPageList.Count) then
    RaiseGDBException('TNBPages.Get Index out of bounds');
  Result := TCustomPage(fPageList[Index]).Caption;
end;

{------------------------------------------------------------------------------
  TNBPages GetCount
 ------------------------------------------------------------------------------}
function TNBPages.GetCount: Integer;
begin
  Result := fPageList.Count;
end;

{------------------------------------------------------------------------------
  TNBPages GetObject
 ------------------------------------------------------------------------------}
function TNBPages.GetObject(Index: Integer): TObject;
begin
  if (Index<0) or (Index>=fPageList.Count) then
    RaiseGDBException('TNBPages.GetObject Index out of bounds');
  Result := TCustomPage(fPageList[Index]);
end;

{------------------------------------------------------------------------------
  TNBPages Put
 ------------------------------------------------------------------------------}
procedure TNBPages.Put(Index: Integer; const S: String);
begin
  if (Index<0) or (Index>=fPageList.Count) then
    RaiseGDBException('TNBPages.Put Index out of bounds');
  
  TCustomPage(fPageList[Index]).Caption := S;
end;

{------------------------------------------------------------------------------
  TNBPages Clear
 ------------------------------------------------------------------------------}
procedure TNBPages.Clear;
begin
  while fPageList.Count>0 do
    Delete(fPageList.Count-1);
end;

{------------------------------------------------------------------------------
  TNBPages Delete
 ------------------------------------------------------------------------------}
procedure TNBPages.Delete(Index: Integer);
var
  APage: TCustomPage;
begin
  // Make sure Index is in the range of valid pages to delete
  {$IFDEF NOTEBOOK_DEBUG}
  //DebugLn('TNBPages.Delete A Index=',Index);
  DebugLn('TNBPages.Delete B ',fNoteBook.Name,' Index=',Index,' fPageList.Count=',fPageList.Count,' fNoteBook.PageIndex=',fNoteBook.PageIndex);
  {$ENDIF}
  if (Index >= 0) and
     (Index < fPageList.Count) then
  begin
    APage:=TCustomPage(fPageList[Index]);
    // delete handle
    APage.Parent:=nil;
    // free the page
    APage.Free;
  end;
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TNBPages.Delete END ',fNoteBook.Name,' Index=',Index,' fPageList.Count=',fPageList.Count,' fNoteBook.PageIndex=',fNoteBook.PageIndex);
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  TNBPages Insert
 ------------------------------------------------------------------------------}
procedure TNBPages.Insert(Index: Integer; const S: String);
var
  NewPage: TCustomPage;
  NewOwner: TComponent;
begin
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TNBPages.Insert A ',FNoteBook.Name,' Index=',Index,' S="',S,'"');
  {$ENDIF}
  NewOwner:=FNotebook.Owner;
  if NewOwner=nil then
    NewOwner:=FNotebook;
  NewPage := FNotebook.PageClass.Create(NewOwner);
  with NewPage do
    Caption := S;

  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TNBPages.Insert B ',FNotebook;.Name,' Index=',Index,' S="',S,'"');
  {$ENDIF}
  FNoteBook.InsertPage(NewPage,Index);
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TNBPages.Insert END ',FNotebook;.Name,' Index=',Index,' S="',S,'"');
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  TNBPages Move
 ------------------------------------------------------------------------------}
procedure TNBPages.Move(CurIndex, NewIndex: Integer);
var
  APage: TCustomPage;
  NewControlIndex, NewPageIndex: integer;
begin
  if CurIndex=NewIndex then exit;
  NewPageIndex:=NewIndex;

  APage:=TCustomPage(fPageList[CurIndex]);

  // calculate new control index (i.e. ZOrderPosition)
  if NewIndex>=fPageList.Count-1 then
    NewControlIndex:=fNoteBook.ControlCount-1
  else
    NewControlIndex:=fNoteBook.GetControlIndex(TCustomPage(fPageList[NewIndex]));

  // calculate new PageIndex
  if fNoteBook.PageIndex=CurIndex then
    NewPageIndex:=NewIndex
  else if fNoteBook.PageIndex>CurIndex then begin
    if fNoteBook.PageIndex<=NewIndex then
      NewPageIndex:=fNoteBook.PageIndex-1;
  end else begin
    if fNoteBook.PageIndex>=NewIndex then
      NewPageIndex:=fNoteBook.PageIndex+1;
  end;

   // move Page in notebook handle
  FNotebook.WSMovePage(APage, NewIndex);

  // move Page in fPageList
  fPageList.Move(CurIndex, NewIndex);

  // move in wincontrol list
  fNoteBook.SetControlIndex(APage,NewControlIndex);
  
  // update PageIndex
  fNoteBook.PageIndex:=NewPageIndex;
end;


{******************************************************************************
                                TCustomNotebook
 ******************************************************************************}
{------------------------------------------------------------------------------
  TCustomNotebook Constructor
 ------------------------------------------------------------------------------}
constructor TCustomNotebook.Create(TheOwner: TComponent);
begin
  if PageClass=nil then
    RaiseGDBException('');
  inherited Create(TheOwner);

  fCompStyle := csNoteBook;

  fPageList := TList.Create;

  fAccess := TNBPages.Create(fPageList, Self);
  fPageIndex := -1;
  FLoadedPageIndex:=-1;

  ControlStyle := [csAcceptsControls];
  TabPosition := tpTop;
  TabStop := true;
  ShowTabs := True;
  SetInitialBounds(0,0,200,200);
end;

{------------------------------------------------------------------------------
  Method:  TCustomNotebook.CreateWnd
  Params:  None
  Returns: Nothing

  Creates the interface object.
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.CreateWnd;
begin
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TCustomNotebook.CreateWnd ',Name,':',ClassName,' HandleAllocated=',HandleAllocated);
  {$ENDIF}
  inherited CreateWnd;
  DoCreateWnd;
end;

{------------------------------------------------------------------------------
  procedure TCustomNotebook.DoCreateWnd;

  Creates the handles for the pages and updates the notebook handle.
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.DoCreateWnd;
var
  i: Integer;
  lPage: TCustomPage;
begin
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TCustomNotebook.DoCreateWnd ',Name,':',ClassName,' HandleAllocated=',HandleAllocated);
  {$ENDIF}
  fAddingPages:=true;
  for i := 0 to FPageList.Count -1 do begin
    {$IFDEF NOTEBOOK_DEBUG}
    DebugLn('TCustomNotebook.DoCreateWnd ',Name,':',ClassName,' ',Page[i].Caption,' ',not (pfAdded in Page[i].Flags));
    {$ENDIF}
    lPage := Page[i];
    if not (pfAdded in lPage.Flags) then begin
      TWSCustomNotebookClass(WidgetSetClass).AddPage(Self, lPage, i);
      Include(lPage.FFlags,pfAdded);
    end;
  end;
  fAddingPages:=false;

  DoSendShowTabs;
  DoSendTabPosition;
  DoSendPageIndex;
end;

{------------------------------------------------------------------------------
  Method: TCustomNotebook.Destroy
  Params:  None
  Returns: Nothing

  Destructor for the class.
 ------------------------------------------------------------------------------}
destructor TCustomNotebook.Destroy;
begin
  Pages.Clear;
  FreeAndNil(FAccess);
  FreeAndNil(FPageList);
  inherited Destroy;
end;

{------------------------------------------------------------------------------
  function TCustomNotebook.TabIndexAtClientPos(ClientPos: TPoint): integer;

  Returns the index of the page of the tab at the client position.
  For example:
    Index:=NoteBook1.PageIndexAtClientPos(
               NoteBook1.ScreenToClient(Mouse.CursorPos));
 ------------------------------------------------------------------------------}
function TCustomNotebook.TabIndexAtClientPos(ClientPos: TPoint): integer;
begin
  if HandleAllocated then
    Result:=TWSCustomNotebookClass(WidgetSetClass).GetTabIndexAtPos(Self, ClientPos)
  else
    Result:=-1;
end;

function TCustomNotebook.CanTab: boolean;
begin
  Result:=false;
end;

function TCustomNotebook.GetImageIndex(ThePageIndex: Integer): Integer;
var
  APage: TCustomPage;
begin
  APage:=Page[ThePageIndex];
  if APage<>nil then
    Result:=APage.ImageIndex
  else
    Result:=-1;
  if Assigned(OnGetImageIndex) then
    OnGetImageIndex(Self,ThePageIndex,Result);
end;

function TCustomNotebook.IndexOf(APage: TCustomPage): integer;
begin
  Result:=FPageList.IndexOf(APage);
end;

function TCustomNotebook.CustomPage(Index: integer): TCustomPage;
begin
  Result:=GetPage(Index);
end;

function TCustomNotebook.CanChangePageIndex: boolean;
begin
  Result:=true;
  if Assigned(OnChanging) then OnChanging(Self,Result);
end;

function TCustomNotebook.GetMinimumTabWidth: integer;
begin
  Result:=TWSCustomNotebookClass(WidgetSetClass).GetNotebookMinTabWidth(Self);
  //debugln('TCustomNotebook.GetMinimumTabWidth A ',dbgs(Result));
end;

function TCustomNotebook.GetMinimumTabHeight: integer;
begin
  Result:=TWSCustomNotebookClass(WidgetSetClass).GetNotebookMinTabHeight(Self);
  //debugln('TCustomNotebook.GetMinimumTabHeight A ',dbgs(Result));
end;

{------------------------------------------------------------------------------
  method TCustomNotebook DoCloseTabClicked
  Params: APage: TCustomPage
  Result: none

  Called whenever the user closes the tab.
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.DoCloseTabClicked(APage: TCustomPage);
begin
  if Assigned(OnCloseTabClicked) then OnCloseTabClicked(APage);
end;

{------------------------------------------------------------------------------
  TCustomNotebook GetActivePage
 ------------------------------------------------------------------------------}
function TCustomNotebook.GetActivePage: String;
begin
  if (PageIndex>=0) and (PageIndex<PageCount) then
    Result := TCustomPage(fPageList[PageIndex]).Caption
  else
    Result:='';
end;

{------------------------------------------------------------------------------
  function TCustomNotebook.GetActivePageComponent: TCustomPage;
 ------------------------------------------------------------------------------}
function TCustomNotebook.GetActivePageComponent: TCustomPage;
var
  i: Integer;
begin
  i:=PageIndex;
  if (i>=0) and (i<PageCount) then
    Result:=Page[i]
  else
    Result:=nil;
end;

{------------------------------------------------------------------------------
  TCustomNotebook SetActivePage
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.SetActivePage(const Value: String);
var
  i: Integer;
begin
  for i := 0 to fPageList.Count - 1 do
  begin
    if TCustomPage(fPageList[i]).Caption = Value then
    begin
      SetPageIndex(i);
      Break;
    end;
  end;
end;

procedure TCustomNotebook.SetActivePageComponent(const AValue: TCustomPage);
begin
  PageIndex:=fPageList.IndexOf(AValue);
end;

procedure TCustomNotebook.SetImages(const AValue: TImageList);
begin
  if FImages=AValue then exit;
  FImages:=AValue;
  UpdateTabProperties;
end;

procedure TCustomNotebook.SetOptions(const AValue: TNoteBookOptions);
var ChangedOptions: TNoteBookOptions;
begin
  if FOptions=AValue then exit;
  ChangedOptions:=(FOptions-AValue)+(AValue-FOptions);
  FOptions:=AValue;
  if nboShowCloseButtons in ChangedOptions then
    UpdateTabProperties;
end;

{------------------------------------------------------------------------------
  TCustomNotebook SetPageIndex
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.SetPageIndex(AValue: Integer);
begin
  if (csLoading in ComponentState) then FLoadedPageIndex:=AValue;
  //debugln('TCustomNotebook.SetPageIndex A ',dbgsName(Self),' AValue=',dbgs(AValue),' fPageIndex=',dbgs(fPageIndex),' PageCount=',dbgs(PageCount),' HandleAllocated=',dbgs(HandleAllocated));
  if (AValue < 0) or (AValue >= PageCount) then exit;
  if fPageIndex = AValue then exit;
  if not CanChangePageIndex then exit;
  //debugln('TCustomNotebook.SetPageIndex B ',dbgsName(Self),' AValue=',dbgs(AValue),' fPageIndex=',dbgs(fPageIndex),' PageCount=',dbgs(PageCount),' HandleAllocated=',dbgs(HandleAllocated));
  if not Page[AValue].TabVisible then exit;
  fPageIndex := AValue;
  UpdateAllDesignerFlags;
  DoSendPageIndex;
end;

{------------------------------------------------------------------------------
  TCustomNotebook GetPageIndex
 ------------------------------------------------------------------------------}
function TCustomNotebook.GetPageIndex: Integer;
begin
  Result := fPageIndex;
end;

procedure TCustomNotebook.InsertPage(APage: TCustomPage; Index: Integer);
var
  NewZPosition: integer;
begin
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TCustomNotebook.InsertPage A ',Name,' Index=',Index,' Name=',
    APage.Name,' Caption=',APage.Caption);
  {$ENDIF}
  APage.DisableAutoSizing;
  try
    if Index<FPageList.Count then
      NewZPosition:=GetControlIndex(TCustomPage(fPageList[Index]))
    else
      NewZPosition:=-1;
    FPageList.Insert(Index,APage);
    APage.Parent := Self;
    if NewZPosition>=0 then
      SetControlIndex(APage,NewZPosition);
    if PageIndex = -1 then
      FPageIndex := Index;

  {$ifndef WINDOWS}
    // TODO: remove when gtk widgetset fixed to show tabpage tab upon
    //   AddPage, instead of needing TabPage.Visible := true
    APage.Visible := true;
  {$endif}

    UpdateDesignerFlags(Index);

    if HandleAllocated and (not (csLoading in ComponentState)) then begin
      //TWSCustomNotebookClass(WidgetSetClass).AddPage(Self, APage, Index);
      ChildPageSetTabVisible(APage, APage.TabVisible, Index);
      Include(APage.FFlags, pfAdded);
      if PageIndex = Index then
        DoSendPageIndex;
    end;
  finally
    APage.EnableAutoSizing;
  end;
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TCustomNotebook.InsertPage END ',Name,' Index=',
    Index,' Name=',APage.Name,' Caption=',APage.Caption);
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  TCustomNotebook MoveTab
 ------------------------------------------------------------------------------}
procedure TCustomNoteBook.MoveTab(Sender: TObject; NewIndex: Integer);
begin
  if (Sender <> nil) and (NewIndex < PageCount) then begin
    TNBPages(fAccess).Move(TCustomPage(Sender).PageIndex,NewIndex);
  end
  else ; //raise exception?
end;

procedure TCustomNotebook.WSMovePage(APage: TCustomPage; NewIndex: Integer);
begin
  if HandleAllocated and (not (csLoading in ComponentState)) then
    TWSCustomNotebookClass(WidgetSetClass).MovePage(Self, APage, NewIndex);
end;

procedure TCustomNoteBook.ChildPageSetTabVisible(APage: TCustomPage;
  AValue: Boolean; AIndex: Integer);
var
  X: Integer;
  RealIndex: Integer;
begin
  RealIndex:= AIndex;
  for X := 0 to AIndex-1 do
    if not (Page[X].TabVisible) then Dec(RealIndex);
  if AValue then
    TWSCustomNotebookClass(WidgetSetClass).AddPage(Self, APage, RealIndex)
  else
    TWSCustomNotebookClass(WidgetSetClass).RemovePage(Self, RealIndex);
  APage.FTabVisible := AValue;
  if not AValue and (AIndex = PageIndex) then
    if RealIndex > 0 then
      PageIndex := AIndex-1
    else
    if AIndex < (PageCount-1) then
      PageIndex := AIndex+1;
end;

procedure TCustomNotebook.RemovePage(Index: Integer);
var
  NewPageIndex: integer;
  APage: TCustomPage;
begin
  // Make sure Index is in the range of valid pages to delete
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TCustomNotebook.RemovePage A ',Name,' Index=',Index,
    ' FPageList.Count=',FPageList.Count,' PageIndex=',PageIndex);
  {$ENDIF}
  if (Index >= 0) and
     (Index < FPageList.Count) then
  begin
    APage:=TCustomPage(fPageList[Index]);
    NewPageIndex:=PageIndex;
    if not (csLoading in ComponentState) then begin
      // If that page is showing, then show the next page before deleting it
      if (Index = PageIndex) then begin
        if NewPageIndex<FPageList.Count-1 then
          // switch current page to next (right) page
          inc(NewPageIndex)
        else if FPageList.Count>0 then
          // switch to previous (left) page
          dec(NewPageIndex)
        else
          // deleting last page
          NewPageIndex:=-1;

        if NewPageIndex>=0 then
          PageIndex:=NewPageIndex;
      end;
    end;
    if HandleAllocated and APage.TabVisible then begin
      //TWSCustomNotebookClass(WidgetSetClass).RemovePage(Self, Index);
      ChildPageSetTabVisible(APage, False, Index);
    end;
    FPageList.Delete(Index);
    APage.Parent:=nil;
    if fPageIndex >= Index then
      Dec(fPageIndex);
  end;
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('TCustomNotebook.RemovePage END ',fNoteBook.Name,' Index=',Index,' fPageList.Count=',fPageList.Count,' fNoteBook.PageIndex=',fNoteBook.PageIndex);
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  function TCustomNotebook.IsStoredActivePage: boolean;
 ------------------------------------------------------------------------------}
function TCustomNotebook.IsStoredActivePage: boolean;
begin
  Result:=false;
end;

{------------------------------------------------------------------------------
  TCustomNotebook GetPageCount
 ------------------------------------------------------------------------------}
function TCustomNotebook.GetPageCount: Integer;
begin
  Result := fPageList.Count;
end;

{------------------------------------------------------------------------------
  TCustomNotebook SetPages
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.SetPages(AValue: TStrings);
begin
  FAccess.Assign(AValue);
end;

{------------------------------------------------------------------------------
  TCustomNotebook GetPage
 ------------------------------------------------------------------------------}
function TCustomNotebook.GetPage(aIndex: Integer): TCustomPage;
begin
  if (aIndex<0) or (aIndex>=fPageList.Count) then
    RaiseGDBException('TCustomNotebook.GeTCustomPage Index out of bounds');
  Result := TCustomPage(fPageList.Items[aIndex]);
end;

{------------------------------------------------------------------------------
  TCustomNotebook SetShowTabs
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.SetShowTabs(AValue: Boolean);
begin
  if fShowTabs=AValue then exit;
  fShowTabs := AValue;
  DoSendShowTabs;
end;

{------------------------------------------------------------------------------
  TCustomNotebook SetTabPosition
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.SetTabPosition(tabPos: TTabPosition);
begin
  if fTabPosition = tabPos then exit;
  fTabPosition := tabPos;
  DoSendTabPosition;
end;

{------------------------------------------------------------------------------
  procedure TCustomNotebook.UpdateAllDesignerFlags;
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.UpdateAllDesignerFlags;
var
  i: integer;
begin
  for i:=0 to PageCount-1 do
    UpdateDesignerFlags(i);
end;

{------------------------------------------------------------------------------
  procedure TCustomNotebook.UpdateDesignerFlags(APageIndex: integer);
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.UpdateDesignerFlags(APageIndex: integer);
begin
  if APageIndex<>fPageIndex then
    Page[APageIndex].ControlStyle:=
      Page[APageIndex].ControlStyle+[csNoDesignVisible]
  else
    Page[APageIndex].ControlStyle:=
      Page[APageIndex].ControlStyle-[csNoDesignVisible];
end;

{------------------------------------------------------------------------------
  TCustomNotebook ReadState
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.ReadState(Reader: TAbstractReader);
begin
  fAccess.Clear;
  inherited ReadState(Reader);
end;

{------------------------------------------------------------------------------
  TCustomNotebook ShowControl
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.ShowControl(APage: TControl);
var
  i: LongInt;
begin
  //inherited ShowControl(AControl);
  { Find a child control that matches the one passed in and display
    the page that contains that control. This method is necessary
    for compatibility with Delphi }
  for i := 0 to fPageList.Count - 1 do begin
    if TControl(fPageList[i]) = APage then begin
      PageIndex := i;
      Exit;
    end;
  end;
end;

{------------------------------------------------------------------------------
  method TCustomNotebook UpdateTabProperties
  Params: none
  Result: none

  Tells the interface to update all tabs.
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.UpdateTabProperties;
var i: integer;
begin
  if not HandleAllocated or (csLoading in ComponentState) then exit;
  for i := 0 to PageCount - 1 do
    TWSCustomPageClass(Page[i].WidgetSetClass).UpdateProperties(Page[i]);
end;

function TCustomNotebook.ChildClassAllowed(ChildClass: TClass): boolean;
begin
  Result:=(ChildClass<>nil) and (ChildClass.InheritsFrom(PageClass));
end;

{------------------------------------------------------------------------------
  TCustomNotebook Change
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.Change;
Begin
  fPageIndexOnLastChange:=fPageIndex;
  ShowCurrentPage;
  if ([csLoading,csDestroying]*ComponentState=[])
  and (not fAddingPages) then begin
    if Assigned(fOnPageChanged) then fOnPageChanged(Self);
  end;
end;

procedure TCustomNotebook.Loaded;
begin
  inherited Loaded;
  if FLoadedPageIndex>=0 then PageIndex:=FLoadedPageIndex;
  FLoadedPageIndex:=-1;
  fPageIndexOnLastChange:=PageIndex;
  if HandleAllocated then DoCreateWnd;
end;

{------------------------------------------------------------------------------
  TCustomNotebook CNNotify
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.CNNotify(var Message: TLMNotify);
Begin
  with Message do
    Case NMHdr^.code of
      TCN_SELCHANGE:
        begin
          // set the page from the NMHDR^.idfrom
          if (not fAddingPages) then begin
            FPageIndex := NMHDR^.idfrom;
            if FPageIndex>=PageCount then
              FPageIndex:=-1;
            //debugln('TCustomNotebook.CNNotify A fPageIndex=',fPageIndex,' FLoadedPageIndex=',FLoadedPageIndex);
            UpdateAllDesignerFlags;
            if ([csLoading,csDestroying]*ComponentState=[]) then begin
              if fPageIndexOnLastChange<>fPageIndex then begin
                Change;
                if csDesigning in ComponentState then
                  OwnerFormDesignerModified(Self);
              end;
            end;
          end;
        end;
      TCN_SELCHANGING:
        begin
          if CanChangePageIndex then
            Result := 0
          else
            Result := 1;
          //debugln('TCustomNotebook.CNNotify TCN_SELCHANGING Result=',dbgs(Result));
        end;
    else
      begin
        {$IFDEF NOTEBOOK_DEBUG}
        DebugLn('[TCustomNotebook.CNNotify] unhandled NMHdr code:', NMHdr^.code);
        {$ENDIF}
      end;
    end;
end;

{------------------------------------------------------------------------------
  procedure TCustomNotebook.DoSendPageIndex

  Makes sure Visible = true for page which has index FPageIndex
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.ShowCurrentPage;
begin
  if (FPageIndex >= 0) and (FPageIndex < PageCount) then
    Page[FPageIndex].Visible := true;
end;

{------------------------------------------------------------------------------
  procedure TCustomNotebook.DoSendPageIndex;
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.DoSendPageIndex;
begin
  //DebugLn('[TCustomNotebook.DoSendPageIndex] A ',Name,' PageIndex=',dbgs(fPageIndex),' ',dbgs(csLoading in ComponentState),' ',dbgs(HandleAllocated));
  if not HandleAllocated or (csLoading in ComponentState) then exit;
  {$IFDEF NOTEBOOK_DEBUG}
  //DebugLn('[TCustomNotebook.DoSendPageIndex] B ',Name,' PageIndex=',dbgs(fPageIndex));
  {$ENDIF}
  ShowCurrentPage;
  TWSCustomNotebookClass(WidgetSetClass).SetPageIndex(Self, FPageIndex);
  {$IFDEF NOTEBOOK_DEBUG}
  //DebugLn('[TCustomNotebook.DoSendPageIndex] END ',dbgs(FPageIndex));
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  procedure TCustomNotebook.DoSendShowTabs;
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.DoSendShowTabs;
begin
  if not HandleAllocated or (csLoading in ComponentState) then exit;
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('[TCustomNotebook.DoSendShowTabs] A ',Name);
  {$ENDIF}
  TWSCustomNotebookClass(WidgetSetClass).ShowTabs(Self, FShowTabs);
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn('[TCustomNotebook.DoSendShowTabs] B ',Name);
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  procedure TCustomNotebook.DoSendTabPosition;
 ------------------------------------------------------------------------------}
procedure TCustomNotebook.DoSendTabPosition;
begin
  if not HandleAllocated or (csLoading in ComponentState) then exit;
  TWSCustomNotebookClass(WidgetSetClass).SetTabPosition(Self, FTabPosition);
end;

