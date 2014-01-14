{%MainUnit win32wscomctrls.pp}
{ $Id$

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

{ TWin32WSCustomListView }

type
  TLVStyleType = (lsStyle, lsInvert, lsExStyle);

const
  LV_STYLES: array[TListViewProperty] of record
    StyleType: TLVStyleType;
    Style: Integer;
  end = (
    (StyleType: lsStyle;   Style: LVS_AUTOARRANGE),        // lvpAutoArrange
    (StyleType: lsExStyle; Style: LVS_EX_CHECKBOXES),      // lvpCheckboxes
    (StyleType: lsInvert;  Style: LVS_NOSORTHEADER),       // lvpColumnClick
    (StyleType: lsExStyle; Style: LVS_EX_FLATSB),          // lvpFlatScrollBars
    (StyleType: lsExStyle; Style: LVS_EX_HEADERDRAGDROP),  // lvpFullDrag
    (StyleType: lsExStyle; Style: LVS_EX_GRIDLINES),       // lvpGridLines
    (StyleType: lsInvert;  Style: LVS_SHOWSELALWAYS),      // lvpHideSelection
    (StyleType: lsExStyle; Style: LVS_EX_TRACKSELECT),     // lvpHotTrack
    (StyleType: lsInvert;  Style: LVS_SINGLESEL),          // lvpMultiSelect
    (StyleType: lsStyle;   Style: LVS_OWNERDRAWFIXED),     // lvpOwnerDraw
    (StyleType: lsInvert;  Style: LVS_EDITLABELS),         // lvpReadOnly,
    (StyleType: lsExStyle; Style: LVS_EX_FULLROWSELECT),   // lvpRowSelect
    (StyleType: lsInvert;  Style: LVS_NOCOLUMNHEADER),     // lvpShowColumnHeaders
    (StyleType: lsExStyle; Style: LVS_EX_MULTIWORKAREAS),  // lvpShowWorkAreas
    (StyleType: lsInvert;  Style: LVS_NOLABELWRAP),        // lvpWrapText
    (StyleType: lsExStyle; Style: LVS_EX_LABELTIP)         // lvpToolTips
  );


type
  // TODO: add iImage and iOrder to exiting TLvColumn
  // this is a hack !!!
  TLvColumn_v4_7 = record
    lvc: TLvColumn;
    iImage: Integer;
    iOrder: Integer;
  end;


////////////////////////////////////////////////////////////////////////////////
// Event code
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// Column code
////////////////////////////////////////////////////////////////////////////////

class procedure TWin32WSCustomListView.ColumnDelete(const ALV: TCustomListView; const AIndex: Integer);
var
  hHdr, hLV: THandle;
  Count: Integer;
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnDelete')
  then Exit;

  hLV := ALV.Handle;
  hHdr := GetHeader(hLV);
  if hHdr = 0 then Exit; //???

  Count := Header_GetItemCount(hHdr);
  if Count <= Aindex then Exit;

  // Move column to the last, otherwise our items get shuffeled
  if AIndex <> Count - 1 then
    ColumnMove(ALV, AIndex, Count - 1, nil);
  ListView_DeleteColumn(hLV, Count - 1);
end;

class function TWin32WSCustomListView.ColumnGetWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn): Integer;
var
  lvc: TLvColumn;
begin
  Result := -1;
  // this implementation uses columnwidht = 0 for invisible
  // so fallback to default (= AColumn.FWidth)
  // Don't return AColumn.Width, this will cause a loop
  if not AColumn.Visible then Exit;

  if not WSCheckHandleAllocated(ALV, 'ColumnGetWidth')
  then Exit;

  // dont use ListView_GetColumnWidth since we cant detect errors
  lvc.Mask := LVCF_WIDTH;
  if ListView_GetColumn(ALV.Handle, AIndex, lvc) <> 0
  then Result := lvc.cx;
end;

class procedure TWin32WSCustomListView.ColumnInsert(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn);
var
  lvc: TLvColumn;
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnInsert')
  then Exit;

  lvc.Mask := LVCF_TEXT;

  {$ifdef WindowsUnicodeSupport}
    if UnicodeEnabledOS then
    begin
      lvc.pszText := PChar(PWideChar(UTF8ToUTF16(AColumn.Caption)));
      SendMessage(ALV.Handle, LVM_INSERTCOLUMNW, WPARAM(AIndex), LPARAM(@lvc));
    end
    else
    begin
      lvc.pszText := PChar(Utf8ToAnsi(AColumn.Caption));
      ListView_InsertColumn(ALV.Handle, AIndex, lvc);
    end;
  {$else}
    lvc.pszText := PChar(AColumn.Caption);
    ListView_InsertColumn(ALV.Handle, AIndex, lvc);
  {$endif}
end;

class procedure TWin32WSCustomListView.ColumnMove(const ALV: TCustomListView; const AOldIndex, ANewIndex: Integer; const AColumn: TListColumn);
var
  lvc, oldlvc: TLvColumn_v4_7;
  buf, oldbuf: array[0..1024] of Char;
  Count, idx: Integer;

begin
  if not WSCheckHandleAllocated(ALV, 'ColumnMove')
  then Exit;

  Count := AOldIndex - ANewIndex;

  // Fetch old column values
  oldlvc.lvc.Mask := LVCF_FMT or LVCF_IMAGE or LVCF_TEXT or LVCF_WIDTH;
  oldlvc.lvc.pszText := @oldbuf[0];
  oldlvc.lvc.cchTextMax := SizeOF(oldbuf);
  ListView_GetColumn(ALV.Handle, AOldIndex, oldlvc.lvc);

  idx := AOldIndex;
  while Count <> 0 do
  begin
    // get next index
    if Count < 0
    then Inc(idx)
    else Dec(idx);
    // and data
    lvc.lvc.Mask := LVCF_FMT or LVCF_IMAGE or LVCF_TEXT or LVCF_WIDTH;
    lvc.lvc.pszText := @buf[0];
    lvc.lvc.cchTextMax := SizeOF(buf);
    ListView_GetColumn(ALV.Handle, idx, lvc.lvc);
    // set data
    ListView_SetColumn(ALV.Handle, ANewIndex + Count, lvc.lvc);

    if Count < 0
    then Inc(Count)
    else Dec(Count);
  end;
  // finally copy original data to new column
  ListView_SetColumn(ALV.Handle, ANewIndex, oldlvc.lvc);
end;

class procedure TWin32WSCustomListView.ColumnSetAlignment(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AAlignment: TAlignment);
const
  JUSTIFICATION: array[TAlignment] of Integer = (
    LVCFMT_LEFT,
    LVCFMT_RIGHT,
    LVCFMT_CENTER
  );
var
  lvc: TLvColumn;
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetAlignment')
  then Exit;

  lvc.Mask := LVCF_FMT;
  ListView_GetColumn(ALV.Handle, AIndex, lvc);
  lvc.fmt := (lvc.fmt and not LVCFMT_JUSTIFYMASK) or JUSTIFICATION[AAlignment];
  ListView_SetColumn(ALV.Handle, AIndex, lvc);
end;

class procedure TWin32WSCustomListView.ColumnSetAutoSize(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AAutoSize: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetAutoSize')
  then Exit;

  if AAutoSize
  then ListView_SetColumnWidth(ALV.Handle, AIndex, LVSCW_AUTOSIZE)
  else ListView_SetColumnWidth(ALV.Handle, AIndex, AColumn.Width);
end;

class procedure TWin32WSCustomListView.ColumnSetCaption(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const ACaption: String);
var
  lvc: TLvColumn;
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetCaption')
  then Exit;

  lvc.Mask := LVCF_TEXT;

  {$ifdef WindowsUnicodeSupport}
    if UnicodeEnabledOS then
    begin
      lvc.pszText := PChar(PWideChar(UTF8ToUTF16(AColumn.Caption)));
      SendMessage(ALV.Handle, LVM_SETCOLUMNW, WPARAM(AIndex), LPARAM(@lvc));
    end
    else
    begin
      lvc.pszText := PChar(Utf8ToAnsi(ACaption));
      ListView_SetColumn(ALV.Handle, AIndex, lvc);
    end;
  {$else}
    lvc.pszText := PChar(ACaption);
    ListView_SetColumn(ALV.Handle, AIndex, lvc);
  {$endif}
end;

class procedure TWin32WSCustomListView.ColumnSetImage(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AImageIndex: Integer);
var
  lvc: TLvColumn_v4_7;
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetImage')
  then Exit;

  // forst get the old lvc, since we have to tell the bloody thing that this
  // column has an image otherwise we will have a crash on XP using comctl 6

  lvc.lvc.Mask := LVCF_FMT;
  ListView_GetColumn(ALV.Handle, AIndex, lvc.lvc);

  if AImageIndex = -1
  then begin
    lvc.lvc.Mask := LVCF_FMT;
    lvc.lvc.fmt := lvc.lvc.fmt and not (LVCFMT_IMAGE or LVCFMT_COL_HAS_IMAGES);
  end
  else begin
    lvc.lvc.Mask := LVCF_IMAGE or LVCF_FMT;
    lvc.lvc.fmt := lvc.lvc.fmt or LVCFMT_IMAGE or LVCFMT_COL_HAS_IMAGES;
    lvc.iImage := AImageIndex;
  end;

  ListView_SetColumn(ALV.Handle, AIndex, lvc.lvc);
end;

class procedure TWin32WSCustomListView.ColumnSetMaxWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AMaxWidth: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetMaxWidth')
  then Exit;

  // TODO: in messageHandler
end;

class procedure TWin32WSCustomListView.ColumnSetMinWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AMinWidth: integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetMinWidth')
  then Exit;

  // TODO: in messageHandler
end;

class procedure TWin32WSCustomListView.ColumnSetWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AWidth: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetWidth')
  then Exit;

  ListView_SetColumnWidth(ALV.Handle, AIndex, AWidth)
end;

class procedure TWin32WSCustomListView.ColumnSetVisible(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AVisible: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetVisible')
  then Exit;

  // TODO: implement with LV_COLUMN.subitem (associate different columns and insert/delete last.

  if AVisible
  then ListView_SetColumnWidth(ALV.Handle, AIndex, AColumn.Width)
  else ListView_SetColumnWidth(ALV.Handle, AIndex, 0);
end;

////////////////////////////////////////////////////////////////////////////////
// Item code
////////////////////////////////////////////////////////////////////////////////

class procedure TWin32WSCustomListView.ItemDelete(const ALV: TCustomListView; const AIndex: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemDelete')
  then Exit;

  ListView_DeleteItem(ALV.Handle, AIndex);
end;

class function TWin32WSCustomListView.ItemDisplayRect(const ALV: TCustomListView; const AIndex, ASubItem: Integer; ACode: TDisplayCode):TRect; 
const 
  DISPLAYCODES: array[TDisplayCode] of DWORD=(LVIR_BOUNDS, LVIR_ICON, LVIR_LABEL, LVIR_SELECTBOUNDS);
var
  mes: uint;
begin
  Result := Rect(0,0,0,0);
  if not WSCheckHandleAllocated(ALV, 'ItemDisplayRect')
  then Exit;                                          
  
  if ASubItem = 0 
  then mes:=LVM_GETITEMRECT
  else begin
    mes:=LVM_GETSUBITEMRECT;
    if ACode = drSelectBounds 
    then ACode := drBounds;
  end;
  Result.top := ASubItem;
  Result.left := DISPLAYCODES[ACode];
  SendMessage(ALV.Handle, mes, AIndex, lparam(@Result));
end;

class function TWin32WSCustomListView.ItemGetChecked(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem): Boolean;
begin
  Result := False;
  if not WSCheckHandleAllocated(ALV, 'ItemGetChecked')
  then Exit;
  // shr 12 will give teh stateimage index, however a value of 
  // 0 means no image and 1 means unchecked. All other 14 are checked (?)
  // so shifting 13 will always result in something <> 0 when checked.
  Result := SendMessage(ALV.Handle, LVM_GETITEMSTATE, AIndex, LVIS_STATEIMAGEMASK) shr 13 <> 0;
end;

class function TWin32WSCustomListView.ItemGetPosition(
  const ALV: TCustomListView; const AIndex: Integer): TPoint;
begin
  Result := Point(0, 0);
  if WSCheckHandleAllocated(ALV, 'ItemGetPosition') then
    SendMessage(ALV.Handle, LVM_GETITEMPOSITION, AIndex, LPARAM(@Result));
end;

class function TWin32WSCustomListView.ItemGetState(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem; const AState: TListItemState;
  out AIsSet: Boolean): Boolean;
const
  // lisCut, lisDropTarget, lisFocused, lisSelected
  FLAGS: array[TListItemState] of Integer = (LVIS_CUT, LVIS_DROPHILITED, LVIS_FOCUSED, LVIS_SELECTED);
begin
  Result := False;

  if not WSCheckHandleAllocated(ALV, 'ItemGetState')
  then Exit;

  AIsSet := 0 <> ListView_GetItemState(ALV.Handle, AIndex, FLAGS[AState]);
  Result := True;
end;

class procedure TWin32WSCustomListView.ItemInsert(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem);
var
  lvi: TLvItem;
begin
  if not WSCheckHandleAllocated(ALV, 'ItemInsert')
  then Exit;

  lvi.Mask := LVIF_TEXT or LVIF_PARAM;
  lvi.iItem := AIndex;
  lvi.iSubItem := 0;
  lvi.lParam := LPARAM(AItem);

  {$ifdef WindowsUnicodeSupport}
    if UnicodeEnabledOS then
    begin
      lvi.pszText := PChar(PWideChar(UTF8ToUTF16(AItem.Caption)));
      SendMessage(ALV.Handle, LVM_INSERTITEMW, 0, LPARAM(@lvi));
    end
    else
    begin
      lvi.pszText := PChar(Utf8ToAnsi(AItem.Caption));
      ListView_InsertItem(ALV.Handle, lvi);
    end;
  {$else}
    lvi.pszText := PChar(AItem.Caption);
    ListView_InsertItem(ALV.Handle, lvi);
  {$endif}
end;

class procedure TWin32WSCustomListView.ItemSetChecked(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AChecked: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetChecked')
  then Exit;

  if AChecked then
    ListView_SetItemState(ALV.Handle, AIndex, IndexToStateImageMask(2), LVIS_STATEIMAGEMASK)
  else
    ListView_SetItemState(ALV.Handle, AIndex, IndexToStateImageMask(1), LVIS_STATEIMAGEMASK);
end;

class procedure TWin32WSCustomListView.ItemSetImage(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const ASubIndex, AImageIndex: Integer);
var
  lvi: TLvItem;
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetImage')
  then Exit;

  lvi.Mask := LVIF_IMAGE;
  lvi.iItem := AIndex;
  lvi.iSubItem := ASubIndex;
  lvi.iImage := AImageIndex;

  ListView_SetItem(ALV.Handle, lvi);
end;

class function TWin32WSCustomListView.ItemSetPosition(const ALV: TCustomListView; const AIndex: Integer; const ANewPosition: TPoint): Boolean;
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetPosition') then
    Result := False
  else
    Result := SendMessage(ALV.Handle, LVM_SETITEMPOSITION,
      AIndex, MAKELPARAM(ANewPosition.X, ANewPosition.Y)) <> 0;
end;

class procedure TWin32WSCustomListView.ItemSetState(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AState: TListItemState; const AIsSet: Boolean);
const
  // lisCut, lisDropTarget, lisFocused, lisSelected
  FLAGS: array[TListItemState] of Integer = (LVIS_CUT, LVIS_DROPHILITED, LVIS_FOCUSED, LVIS_SELECTED);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetState')
  then Exit;
  {Don't change the state if it already has needed value}
  if ((ListView_GetItemState(ALV.Handle, AIndex, FLAGS[AState]) and FLAGS[AState]) = FLAGS[AState]) = AIsSet then exit;

  if AIsSet
  then ListView_SetItemState(ALV.Handle, AIndex, FLAGS[AState], FLAGS[AState])
  else ListView_SetItemState(ALV.Handle, AIndex, 0, FLAGS[AState]);
end;

class procedure TWin32WSCustomListView.ItemSetText(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const ASubIndex: Integer; const AText: String);
{$ifdef WindowsUnicodeSupport}
var
  _gnu_lvi : LV_ITEM;
{$endif}
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetText')
  then Exit;

  {$ifdef WindowsUnicodeSupport}
    if UnicodeEnabledOS then
    begin
      _gnu_lvi.iSubItem := ASubIndex;
      _gnu_lvi.pszText := PChar(PWideChar(UTF8ToUTF16(AText)));

      SendMessage(ALV.Handle, LVM_SETITEMTEXTW, WPARAM(AIndex), LPARAM(@_gnu_lvi));
    end
    else
      ListView_SetItemText(ALV.Handle, AIndex, ASubIndex, PChar(Utf8ToAnsi(AText)));
  {$else}
    ListView_SetItemText(ALV.Handle, AIndex, ASubIndex, PChar(AText));
  {$endif}
end;

class procedure TWin32WSCustomListView.ItemShow(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const PartialOK: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemShow')
  then Exit;

  ListView_EnsureVisible(ALV.Handle, AIndex, Ord(PartialOK));
end;

////////////////////////////////////////////////////////////////////////////////
// LV code
////////////////////////////////////////////////////////////////////////////////


class function TWin32WSCustomListView.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
const
  LISTVIEWSTYLES: array[TViewStyle] of DWORD = (LVS_ICON, LVS_SMALLICON, LVS_LIST, LVS_REPORT);
  Arrangement: array[TIconArrangement] of DWord = (LVS_ALIGNTOP, LVS_ALIGNLEFT);
var
  Params: TCreateWindowExParams;
begin
  // general initialization of Params
  PrepareCreateWindow(AWinControl, Params);
  // customization of Params
  with Params do
  begin
    pClassName := WC_LISTVIEW;
    WindowTitle := StrCaption;
    Flags := Flags or LISTVIEWSTYLES[TListView(AWinControl).ViewStyle] or
      LVS_SINGLESEL or LVS_SHAREIMAGELISTS or
      Arrangement[TListView(AWinControl).IconOptions.Arrangement];
    if TCustomListView(AWinControl).OwnerData then 
      Flags := Flags or LVS_OWNERDATA;
    if TCustomListView(AWinControl).BorderStyle = bsSingle then
      FlagsEx := FlagsEx or WS_EX_CLIENTEDGE;
  end;
  // create window
  FinishCreateWindow(AWinControl, Params, false);
  Params.WindowInfo^.needParentPaint := false;
  Result := Params.Window;
end;

class procedure TWin32WSCustomListView.BeginUpdate(const ALV: TCustomListView);
begin
  if not WSCheckHandleAllocated(ALV, 'BeginUpdate')
  then Exit;

  SendMessage(ALV.Handle,WM_SETREDRAW,WPARAM(False),0);
end;

class procedure TWin32WSCustomListView.EndUpdate(const ALV: TCustomListView);
begin
  if not WSCheckHandleAllocated(ALV, 'EndUpdate')
  then Exit;

  SendMessage(ALV.Handle,WM_SETREDRAW,WPARAM(True),0);
end;

class function TWin32WSCustomListView.GetBoundingRect(const ALV: TCustomListView): TRect;
begin
  Result := Rect(0,0,0,0); 
  if not WSCheckHandleAllocated(ALV, 'GetBoundingRect')
  then Exit;

  ListView_GetViewRect(ALV.Handle, Result);
end;

class function TWin32WSCustomListView.GetDropTarget(const ALV: TCustomListView): Integer;
begin
  Result := -1; 
  if not WSCheckHandleAllocated(ALV, 'GetDropTarget')
  then Exit;

  Result := ListView_GetNextItem(ALV.Handle, -1, LVNI_ALL or LVNI_DROPHILITED);
end;

class function TWin32WSCustomListView.GetFocused(const ALV: TCustomListView): Integer;
begin       
  Result := -1; 
  if not WSCheckHandleAllocated(ALV, 'GetFocused')
  then Exit;

  Result := ListView_GetNextItem(ALV.Handle, -1, LVNI_ALL or LVNI_FOCUSED);
end;

class function TWin32WSCustomListView.GetHoverTime(const ALV: TCustomListView): Integer;
begin
  Result := -1; 
  if not WSCheckHandleAllocated(ALV, 'GetHoverTime')
  then Exit;

  Result := SendMessage(ALV.Handle, LVM_GETHOVERTIME, 0, 0);
end;

class function TWin32WSCustomListView.GetItemAt(const ALV: TCustomListView; x,y: integer): Integer;
var 
  HitInfo: LV_HITTESTINFO;
begin
  Result := -1; 
  if not WSCheckHandleAllocated(ALV, 'GetItemAt')
  then Exit;

  HitInfo.pt.x:=x;
  HitInfo.pt.y:=y;
  ListView_HitTest(alv.Handle,HitInfo);
  if HitInfo.flags <> LVHT_NOWHERE 
  then Result:=HitInfo.iItem;
end;

class function TWin32WSCustomListView.GetSelCount(const ALV: TCustomListView): Integer;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ALV, 'GetSelCount')
  then Exit;

  Result := ListView_GetSelectedCount(ALV.Handle);
end;

class function TWin32WSCustomListView.GetSelection(const ALV: TCustomListView): Integer;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ALV, 'GetSelection')
  then Exit;

  Result := ListView_GetNextItem(ALV.Handle, -1, LVNI_ALL or LVNI_SELECTED);
end;

class function TWin32WSCustomListView.GetTopItem(const ALV: TCustomListView): Integer;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ALV, 'GetTopItem')
  then Exit;

  case GetWindowLong(ALV.Handle, GWL_STYLE) and LVS_TYPEMASK of
    LVS_LIST,
    LVS_REPORT: Result := ListView_GetTopIndex(ALV.Handle);
  else
    Result := -1;
  end;
end;

class function TWin32WSCustomListView.GetViewOrigin(const ALV: TCustomListView): TPoint;
begin
  if not WSCheckHandleAllocated(ALV, 'GetViewOrigin')
  then begin
    Result := Point(0, 0);
    Exit;
  end;

  ListView_GetOrigin(ALV.Handle, Result);
end;

class function TWin32WSCustomListView.GetVisibleRowCount(const ALV: TCustomListView): Integer;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ALV, 'GetVisibleRowCount')
  then Exit;

  case GetWindowLong(ALV.Handle, GWL_STYLE) and LVS_TYPEMASK of
    LVS_LIST,
    LVS_REPORT: Result := ListView_GetCountPerPage(ALV.Handle);
  else
    Result := -1;
  end;
end;

class function TWin32WSCustomListView.GetHeader(const AHandle: THandle): THandle;
begin
  Result := SendMessage(AHandle, LVM_GETHEADER, 0, 0);
  if Result <> 0 then Exit;

  // probably old version, try the first child
  Result := GetWindow(AHandle, GW_CHILD);
end;

// MWE: original from MS knowledgebase KB137520
(********************************************************************
    PositionHeader

    Call this function when the ListView is created, resized, the
    view is changed, or a WM_SYSPARAMETERCHANGE message is received.

 ********************************************************************)
class procedure TWin32WSCustomListView.PositionHeader(const AHandle: THandle);
var
  hwndHeader: HWND;
  dwStyle: PtrInt;
  rc: TRect;
  hdLayout: THDLAYOUT;
  wpos: Windows.TWINDOWPOS;
begin
  dwStyle := GetWindowLong(AHandle, GWL_STYLE);

  if dwStyle and LVS_NOSCROLL = 0 then Exit; // nothing to do
  if dwStyle and LVS_REPORT = 0 then Exit;   // nothing to do

  hwndHeader := GetHeader(AHandle);
  if hwndHeader = 0 then Exit; // nothing to do

  Windows.GetClientRect(AHandle, rc);
  FillChar(hdLayout, SizeOf(hdLayout), 0);
  hdLayout.prc := @rc;
  hdLayout.pwpos := @wpos;
  Header_Layout(hwndHeader, hdLayout);

  Windows.SetWindowPos(hwndHeader,
                       wpos.hwndInsertAfter,
                       wpos.x,
                       wpos.y,
                       wpos.cx,
                       wpos.cy,
                       wpos.flags or SWP_SHOWWINDOW);

  ListView_EnsureVisible(AHandle, 0, 0);
end;

class procedure TWin32WSCustomListView.SetAllocBy(const ALV: TCustomListView; const AValue: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'SetAllocBy')
  then Exit;

  ListView_SetItemCount(ALV.Handle, AValue);
end;

class procedure TWin32WSCustomListView.SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
begin
  if not WSCheckHandleAllocated(AWinControl, 'TWin32WSCustomListView.SetBorder') then
    Exit;
  // changing border style by changing EXSTYLE here does not work correctly
  RecreateWnd(AWinControl);
end;

class procedure TWin32WSCustomListView.SetColor(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWinControl, 'TWin32WSCustomListView.SetColor') then
    Exit;
  Windows.SendMessage(AWinControl.Handle, LVM_SETBKCOLOR, 0, ColorToRGB(AWinControl.Color));
  Windows.SendMessage(AWinControl.Handle, LVM_SETTEXTBKCOLOR, 0, ColorToRGB(AWinControl.Color));
end;

class procedure TWin32WSCustomListView.SetDefaultItemHeight(const ALV: TCustomListView; const AValue: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'SetDefaultItemHeight')
  then Exit;

  // TODO ???
end;

class procedure TWin32WSCustomListView.SetFont(const AWinControl: TWinControl;
  const AFont: TFont);
begin
  // call inherited SetFont; need to do it this way,
  // because the compile time ancestor class is TWSCustomListView
  TWSWinControlClass(ClassParent).SetFont(AWinControl, AFont);
  Windows.SendMessage(AWinControl.Handle, LVM_SETTEXTCOLOR, 0, ColorToRGB(AFont.Color));
end;

class procedure TWin32WSCustomListView.SetHotTrackStyles(const ALV: TCustomListView; const AValue: TListHotTrackStyles);
const
  MASK = LVS_EX_ONECLICKACTIVATE or LVS_EX_TWOCLICKACTIVATE or LVS_EX_UNDERLINEHOT or LVS_EX_UNDERLINECOLD;
var
  Style: Integer;
begin
  if not WSCheckHandleAllocated(ALV, 'SetHotTrackStyles')
  then Exit;

  if htHandPoint in AValue
  then Style := LVS_EX_ONECLICKACTIVATE
  else if [htUnderlineHot, htUnderlineCold] * AValue <> []
  then Style := LVS_EX_TWOCLICKACTIVATE
  else Style := 0;

  if htUnderlineHot in AValue
  then Style := Style or LVS_EX_UNDERLINEHOT;

  if htUnderlineCold in AValue
  then Style := Style or LVS_EX_UNDERLINECOLD;

  UpdateExStyle(ALV.Handle, MASK, Style);
end;

class procedure TWin32WSCustomListView.SetHoverTime(const ALV: TCustomListView; const AValue: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'SetHoverTime')
  then Exit;

  SendMessage(ALV.Handle, LVM_SETHOVERTIME, 0, AValue);
end;

class procedure TWin32WSCustomListView.SetIconArrangement(
  const ALV: TCustomListView; const AValue: TIconArrangement);
const
  ArrangementMap: array[TIconArrangement] of DWord = (
    { iaTop  } LVS_ALIGNTOP,
    { iaLeft } LVS_ALIGNLEFT
  );
begin
  if not WSCheckHandleAllocated(ALV, 'SetIconArrangement')
  then Exit;

  // LVM_ALIGN styles are not implemented in windows (according to w7 sdk) => change style
  UpdateStyle(ALV.Handle, LVS_ALIGNMASK, ArrangementMap[AValue]);
end;

class procedure TWin32WSCustomListView.SetImageList(const ALV: TCustomListView; const AList: TListViewImageList; const AValue: TCustomImageList);
const
  LIST_MAP: array[TListViewImageList] of WPARAM = (
   {lvilSmall} LVSIL_SMALL,
   {lvilLarge} LVSIL_NORMAL,
   {lvilState} LVSIL_STATE
  );
begin
  if not WSCheckHandleAllocated(ALV, 'SetImageList')
  then Exit;

  if AValue <> nil then
    SendMessage(ALV.Handle, LVM_SETIMAGELIST, LIST_MAP[AList], AValue.Reference._Handle)
  else
    SendMessage(ALV.Handle, LVM_SETIMAGELIST, LIST_MAP[AList], 0);
end;

class procedure TWin32WSCustomListView.SetItemsCount(const ALV: TCustomListView; const AValue: Integer); 
begin
  if not WSCheckHandleAllocated(ALV, 'SetItemsCount')
  then Exit;
  SendMessage(ALV.Handle, LVM_SETITEMCOUNT, AValue, 0);
end;

class procedure TWin32WSCustomListView.SetOwnerData(const ALV: TCustomListView; const AValue: Boolean); 
begin
  if not WSCheckHandleAllocated(ALV, 'SetOwnerData')
  then Exit;
  RecreateWnd(ALV);
end;

class procedure TWin32WSCustomListView.SetProperty(const ALV: TCustomListView; const AProp: TListViewProperty; const AIsSet: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'SetProperty')
  then Exit;

  case LV_STYLES[AProp].StyleType of
    lsStyle: begin
      if AIsSet
      then UpdateStyle(ALV.Handle, LV_STYLES[AProp].Style, LV_STYLES[AProp].Style)
      else UpdateStyle(ALV.Handle, LV_STYLES[AProp].Style, 0);
    end;
    lsInvert: begin
      if AIsSet
      then UpdateStyle(ALV.Handle, LV_STYLES[AProp].Style, 0)
      else UpdateStyle(ALV.Handle, LV_STYLES[AProp].Style, LV_STYLES[AProp].Style);
    end;
    lsExStyle: begin
      if AIsSet
      then UpdateExStyle(ALV.Handle, LV_STYLES[AProp].Style, LV_STYLES[AProp].Style)
      else UpdateExStyle(ALV.Handle, LV_STYLES[AProp].Style, 0);
    end;
  end;
end;

class procedure TWin32WSCustomListView.SetProperties(const ALV: TCustomListView; const AProps: TListViewProperties);
var
  Prop: TListViewProperty;
  Style, ExStyle, Mask, ExMask: Integer;
begin
  if not WSCheckHandleAllocated(ALV, 'SetProperties')
  then Exit;

  Style := 0;
  ExStyle := 0;
  Mask := 0;
  ExMask := 0;

  for Prop := Low(Prop) to High(Prop) do
  begin
    case LV_STYLES[Prop].StyleType of
      lsStyle,
      lsInvert: begin
        Mask := Mask or LV_STYLES[Prop].Style;

        if (LV_STYLES[Prop].StyleType = lsStyle) = (Prop in AProps)
        then Style := Style or LV_STYLES[Prop].Style
        else Style := Style and not LV_STYLES[Prop].Style;
      end;
      lsExStyle: begin
        ExMask := ExMask or LV_STYLES[Prop].Style;

        if Prop in AProps
        then ExStyle := ExStyle or LV_STYLES[Prop].Style
        else ExStyle := ExStyle and not LV_STYLES[Prop].Style;
      end;
    end;
  end;

  if Mask <> 0
  then UpdateStyle(ALV.Handle, Mask, Style);
  if ExMask <> 0
  then UpdateExStyle(ALV.Handle, ExMask, ExStyle);
end;

class procedure TWin32WSCustomListView.SetScrollBars(const ALV: TCustomListView; const AValue: TScrollStyle);
begin
  if not WSCheckHandleAllocated(ALV, 'SetScrollBars')
  then Exit;

  // we only can hide all scrollbars.
  if AValue = ssNone
  then UpdateStyle(ALV.Handle, LVS_NOSCROLL, LVS_NOSCROLL)
  else UpdateStyle(ALV.Handle, LVS_NOSCROLL, 0);
end;


function ListCompare(lParam1, lParam2: LParam; lParamSort: LParam): Integer; stdcall;
var
  Item1: TListItem absolute lParam1;
  Item2: TListItem absolute lParam2;
begin
  Result := CompareValue(Item1.Index, Item2.Index);
end;

class procedure TWin32WSCustomListView.SetSort(const ALV: TCustomListView; const AType: TSortType; const AColumn: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'SetSort')
  then Exit;

  ListView_SortItems(ALV.Handle, @ListCompare, 0);
end;

class procedure TWin32WSCustomListView.SetViewOrigin(const ALV: TCustomListView; const AValue: TPoint);
var
  dx, dy: Integer;
  Origin: TPoint;
begin
  if not WSCheckHandleAllocated(ALV, 'SetViewOrigin')
  then Exit;

  ListView_GetOrigin(ALV.Handle, Origin);

  dx := AValue.X - Origin.X;
  dy := AValue.Y - Origin.Y;
  if (dx <> 0) or (dy <> 0)
  then ListView_Scroll(ALV.Handle, dx, dy);
end;

class procedure TWin32WSCustomListView.SetViewStyle(const ALV: TCustomListView; const Avalue: TViewStyle);
const
  //vsIcon, vsSmallIcon, vsList, vsReport
  STYLES: array[TViewStyle] of DWORD = (LVS_ICON, LVS_SMALLICON, LVS_LIST, LVS_REPORT);
begin
  if not WSCheckHandleAllocated(ALV, 'SetViewStyle')
  then Exit;

  UpdateStyle(ALV.Handle, LVS_TYPEMASK, STYLES[AValue]);
end;

class procedure TWin32WSCustomListView.UpdateStyle(const AHandle: THandle; const AMask, AStyle: Integer);
var
  OldStyle, NewStyle: PtrInt;
begin
  OldStyle := GetWindowLong(AHandle, GWL_STYLE);

  NewStyle := (OldStyle and not AMask) or AStyle;

  if OldStyle = NewStyle then Exit;

  SetWindowLong(AHandle, GWL_STYLE, NewStyle);

  // fix header if needed
  if (NewStyle and LVS_NOSCROLL)<> 0 then begin
    if (OldStyle and LVS_NOSCROLL = 0)
    or (NewStyle and LVS_REPORT <> 0)
    then PositionHeader(AHandle);
  end;

  //Invalidate Listview, so that changes are made visible
  Windows.InvalidateRect(AHandle, nil, true);
end;

class procedure TWin32WSCustomListView.UpdateExStyle(const AHandle: THandle; const AMask, AStyle: Integer);
var
  OldStyle, NewStyle: Integer;
begin
  OldStyle := SendMessage(AHandle, LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0);

  NewStyle := (OldStyle and not AMask) or AStyle;

  if OldStyle = NewStyle then Exit;

  SendMessage(AHandle, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, NewStyle);

 //Invalidate Listview, so that changes are made visible
  Windows.InvalidateRect(AHandle, nil, true);
end;