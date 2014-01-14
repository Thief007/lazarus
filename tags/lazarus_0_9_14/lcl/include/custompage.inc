{%MainUnit ../extctrls.pp}

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

{------------------------------------------------------------------------------
  TCustomPage Constructor
 ------------------------------------------------------------------------------}
constructor TCustomPage.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);

  fImageIndex:=-1;
  fCompStyle := csPage;
  fTabVisible := True;
  ControlStyle := ControlStyle + [csAcceptsControls,csDesignFixedBounds,csNoDesignVisible];

  // height and width depends on parent, align to client rect
  Align := alClient;
  Caption := '';
  Visible := false;
end;

{------------------------------------------------------------------------------
  method TCustomPage SetImageIndex
  Params: const AValue: integer
  Result: none

  Set the image index of the image shown in the tabs.
 ------------------------------------------------------------------------------}
procedure TCustomPage.SetImageIndex(const AValue: integer);
begin
  if FImageIndex=AValue then exit;
  FImageIndex:=AValue;
  if not HandleAllocated or (csLoading in ComponentState) then exit;
  TWSCustomPageClass(WidgetSetClass).UpdateProperties(Self);
end;

function TCustomPage.GetTabVisible: Boolean;
begin
  Result := fTabVisible;
end;

procedure TCustomPage.SetTabVisible(const AValue: Boolean);
begin
  if AValue = FTabVisible then exit;
  TCustomNotebook(Parent).ChildPageSetTabVisible(Self, AValue, PageIndex);
  fTabVisible := AValue;
end;

{------------------------------------------------------------------------------
  TCustomPage WMPaint
  Params: a TLMPaint message
 ------------------------------------------------------------------------------}
procedure TCustomPage.WMPaint(var Msg: TLMPaint);
var Notebook: TCustomNoteBook;
begin
  if (Parent<>nil) and (Parent is TCustomNoteBook) then begin
    NoteBook:=TCustomNoteBook(Parent);
    if (NoteBook.PageIndex>=0) and (NoteBook.Page[NoteBook.PageIndex]=Self) then
      inherited WMPaint(Msg);
  end else
    inherited WMPaint(Msg);
end;

{------------------------------------------------------------------------------
  procedure TCustomPage.SetParent(AParent: TWinControl);

  Set parent wincontrol.
 ------------------------------------------------------------------------------}
procedure TCustomPage.SetParent(AParent: TWinControl);
var
  OldParent: TWinControl;
  ParentNotebook: TCustomNotebook;
  i: integer;
begin
  if AParent=Parent then exit;
  CheckNewParent(AParent);
  OldParent:=Parent;
  if (OldParent<>AParent) and (OldParent<>nil)
  and (OldParent is TCustomNotebook)
  and (not (pfRemoving in FFlags)) then begin
    // remove from old pagelist
    ParentNotebook:=TCustomNotebook(OldParent);
    i:=PageIndex;
    if i>=0 then begin
      Include(FFlags,pfRemoving);
      try
        TabVisible := False;
        ParentNotebook.RemovePage(i);
        //ParentNoteBook.ChildPageSetTabVisible(Self, False, i);
      finally
        Exclude(FFlags,pfRemoving);
      end;
    end;
  end;

  inherited SetParent(AParent);

  if (OldParent<>AParent) and (Parent<>nil)
  and (Parent is TCustomNotebook) then begin
    // add to new pagelist
    ParentNotebook:=TCustomNotebook(Parent);
    if ParentNotebook.PageList.IndexOf(Self)<0 then begin
      ParentNotebook.InsertPage(Self, ParentNotebook.PageCount);
      //ParentNoteBook.ChildPageSetTabVisible(Self, FTabVisible, ParentNotebook.PageCount);
    end;
  end;
end;

{------------------------------------------------------------------------------
  procedure TCustomPage.CMHitTest(var Message: TLMNCHITTEST);
 ------------------------------------------------------------------------------}
procedure TCustomPage.CMHitTest(var Message: TLMNCHITTEST);
begin
  if (Parent<>nil) and (Parent is TCustomNotebook)
  and (TCustomNotebook(Parent).ActivePageComponent<>Self) then
    Message.Result:=0 // no hit
  else
    inherited CMHitTest(Message);
  {DebugLn('TCustomPage.CMHitTest A ',Name,' ',(Parent<>nil),' ',
    (Parent is TCustomNotebook),' ',
    (TCustomNotebook(Parent).ActivePageComponent<>Self),
    ' Message.Result=',Message.Result);}
end;

procedure TCustomPage.DestroyHandle;
begin
  inherited DestroyHandle;
  Exclude(FFlags,pfAdded);
end;

{------------------------------------------------------------------------------
  TCustomPage AdjustClientRect
  Params: Rect
 ------------------------------------------------------------------------------}
procedure TCustomPage.AdjustClientRect(var ARect: TRect);
begin
  ARect:=GetClientRect;
end;

{------------------------------------------------------------------------------
  function TCustomPage.PageIndex: integer;

  Returns the index of the page in the notebook.
 ------------------------------------------------------------------------------}
function TCustomPage.GetPageIndex: integer;
begin
  if (Parent<>nil) and (Parent is TCustomNotebook) then
    Result:=TCustomNotebook(Parent).PageList.IndexOf(Self)
  else
    Result := -1;
end;

procedure TCustomPage.SetPageIndex(AValue: Integer);
begin
  if (Parent<>nil) and (Parent is TCustomNotebook) then begin
    TCustomNotebook(Parent).MoveTab(Self,AValue);
  end;
  // ToDo
  //DebugLn('TCustomPage.SetPageIndex Old=',dbgs(PageIndex),' New=',dbgs(AValue));
end;

function TCustomPage.IsVisible: Boolean;
begin
  if Parent is TCustomNotebook then
  begin
    Result := PageIndex = TCustomNotebook(Parent).PageIndex;
  //DebugLn('TCustomPage.IsVisible PageIndex=',dbgs(PageIndex),' Parent.PageIndex=',dbgs(TCustomNotebook(Parent).PageIndex));
  end else begin
    Result := inherited IsVisible;
  end;
end;

{------------------------------------------------------------------------------
  function TCustomPage.CanTab: boolean;
 ------------------------------------------------------------------------------}
function TCustomPage.CanTab: boolean;
begin
  Result:=false;
end;


// included by extctrls.pp
