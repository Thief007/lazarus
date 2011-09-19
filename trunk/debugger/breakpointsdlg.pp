{ $Id$ }
{               ----------------------------------------------
                 breakpointsdlg.pp  -  Overview of breakpoints
                ----------------------------------------------

 @created(Fri Dec 14st WET 2001)
 @lastmod($Date$)
 @author(Shane Miller)
 @author(Marc Weustink <marc@@dommelstein.net>)

 This unit contains the Breakpoint dialog.


 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************
}

unit BreakPointsDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, Menus, ComCtrls, IDEProcs, Debugger, DebuggerDlg, lclType, ActnList, MainBase,
  IDEImagesIntf, SourceEditor;

type
  TBreakPointsDlgState = (
    bpdsItemsNeedUpdate
    );
  TBreakPointsDlgStates = set of TBreakPointsDlgState;

  { TBreakPointsDlg }

  TBreakPointsDlg = class(TDebuggerDlg)
    actAddSourceBP: TAction;
    actAddAddressBP: TAction;
    actAddWatchPoint: TAction;
    actShow: TAction;
    actProperties: TAction;
    actToggleCurrentEnable: TAction;
    actDeleteAllInSrc: TAction;
    actEnableSelected: TAction;
    actDisableSelected: TAction;
    actDeleteSelected: TAction;
    actEnableAll: TAction;
    actDisableAll: TAction;
    actDeleteAll: TAction;
    actEnableAllInSrc: TAction;
    actDisableAllInSrc: TAction;
    ActionList1: TActionList;
    lvBreakPoints: TListView;
    popAddWatchPoint: TMenuItem;
    popAddAddressBP: TMenuItem;
    N0: TMenuItem;
    popShow: TMenuItem;
    mnuPopup: TPopupMenu;
    popAdd: TMenuItem;
    popAddSourceBP: TMenuItem;
    N1: TMenuItem; //--------------
    popProperties: TMenuItem;
    popEnabled: TMenuItem;
    popDelete: TMenuItem;
    N2: TMenuItem; //--------------
    popDisableAll: TMenuItem;
    popEnableAll: TMenuItem;
    popDeleteAll: TMenuItem;
    N3: TMenuItem; //--------------
    popDisableAllSameSource: TMenuItem;
    popEnableAllSameSource: TMenuItem;
    popDeleteAllSameSource: TMenuItem;
    ToolBar1: TToolBar;
    ToolButtonProperties: TToolButton;
    ToolButton10: TToolButton;
    ToolButtonEnable: TToolButton;
    ToolButtonDisable: TToolButton;
    ToolButtonTrash: TToolButton;
    ToolButton6: TToolButton;
    ToolButtonEnableAll: TToolButton;
    ToolButtonDisableAll: TToolButton;
    ToolButtonTrashAll: TToolButton;
    procedure actAddAddressBPExecute(Sender: TObject);
    procedure actAddSourceBPExecute(Sender: TObject);
    procedure actAddWatchPointExecute(Sender: TObject);
    procedure actDisableSelectedExecute(Sender: TObject);
    procedure actEnableSelectedExecute(Sender: TObject);
    procedure actShowExecute(Sender: TObject);
    procedure BreakpointsDlgCREATE(Sender: TObject);
    procedure lvBreakPointsClick(Sender: TObject);
    procedure lvBreakPointsColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvBreakPointsDBLCLICK(Sender: TObject);
    procedure lvBreakPointsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure popDeleteAllSameSourceCLICK(Sender: TObject);
    procedure popDisableAllSameSourceCLICK(Sender: TObject);
    procedure popEnableAllSameSourceCLICK(Sender: TObject);
    procedure popPropertiesClick(Sender: TObject);
    procedure popEnabledClick(Sender: TObject);
    procedure popDeleteClick(Sender: TObject);
    procedure popDisableAllClick(Sender: TObject);
    procedure popEnableAllClick(Sender: TObject);
    procedure popDeleteAllClick(Sender: TObject);
  private
    FBaseDirectory: string;
    FStates: TBreakPointsDlgStates;
    FLockActionUpdate: Integer;
    procedure BreakPointAdd(const ASender: TIDEBreakPoints;
                            const ABreakpoint: TIDEBreakPoint);
    procedure BreakPointUpdate(const ASender: TIDEBreakPoints;
                               const ABreakpoint: TIDEBreakPoint);
    procedure BreakPointRemove(const ASender: TIDEBreakPoints;
                               const ABreakpoint: TIDEBreakPoint);
    procedure SetBaseDirectory(const AValue: string);

    procedure UpdateItem(const AnItem: TListItem;
                         const ABreakpoint: TIDEBreakPoint);
    procedure UpdateAll;
    
    procedure DeleteSelectedBreakpoints;
    procedure JumpToCurrentBreakPoint;
    procedure ShowProperties;
  protected
    procedure DoBreakPointsChanged; override;
    procedure DoBeginUpdate; override;
    procedure DoEndUpdate; override;
    procedure DisableAllActions;
  public
    constructor Create(AOwner: TComponent); override;
  public
    property BaseDirectory: string read FBaseDirectory write SetBaseDirectory;
    property BreakPoints;
  end;
  
function GetBreakPointStateDescription(ABreakpoint: TBaseBreakpoint): string;
function GetBreakPointActionsDescription(ABreakpoint: TBaseBreakpoint): string;


implementation

{$R *.lfm}

uses
  LazarusIDEStrConsts, BaseDebugManager;

function GetBreakPointStateDescription(ABreakpoint: TBaseBreakpoint): string;
const
  //                 enabled  valid
  DEBUG_STATE: array[Boolean, TValidState] of ShortString = (
                {vsUnknown,     vsValid,   vsInvalid}
    {Disabled} (lisOff, lisDisabled, lisInvalidOff),
    {Endabled} (lisOn, lisEnabled, lisInvalidOn));
begin
  Result:=DEBUG_STATE[ABreakpoint.Enabled,ABreakpoint.Valid];
end;

function GetBreakPointActionsDescription(ABreakpoint: TBaseBreakpoint): string;
const
  DEBUG_ACTION: array[TIDEBreakPointAction] of ShortString =
    (lisBreak, lisEnableGroups, lisDisableGroups, lisLogMessage, lisLogCallStack, lisTakeSnapshot);
var
  CurBreakPoint: TIDEBreakPoint;
  Action: TIDEBreakPointAction;
begin
  Result := '';
  if ABreakpoint is TIDEBreakPoint then begin
    CurBreakPoint:=TIDEBreakPoint(ABreakpoint);
    for Action := Low(TIDEBreakPointAction) to High(TIDEBreakPointAction) do
      if Action in CurBreakpoint.Actions
      then begin
        if Result <> '' then Result := Result + ', ';
        Result := Result + DEBUG_ACTION[Action]
      end;
  end;
end;

procedure TBreakPointsDlg.BreakPointAdd(const ASender: TIDEBreakPoints;
  const ABreakpoint: TIDEBreakPoint);
var
  Item: TListItem;
  n: Integer;
begin
  Item := lvBreakPoints.Items.FindData(ABreakpoint);
  if Item = nil
  then begin
    Item := lvBreakPoints.Items.Add;
    Item.Data := ABreakPoint;
    for n := 0 to 5 do
      Item.SubItems.Add('');
  end;

  UpdateItem(Item, ABreakPoint);
end;

procedure TBreakPointsDlg.BreakPointUpdate(const ASender: TIDEBreakPoints;
  const ABreakpoint: TIDEBreakPoint);
var
  Item: TListItem;
begin
  if ABreakpoint = nil then Exit;

  Item := lvBreakPoints.Items.FindData(ABreakpoint);
  if Item = nil
  then BreakPointAdd(ASender, ABreakPoint)
  else begin
    if UpdateCount>0 then begin
      Include(FStates,bpdsItemsNeedUpdate);
      exit;
    end;
    UpdateItem(Item, ABreakPoint);
  end;
end;

procedure TBreakPointsDlg.BreakPointRemove(const ASender: TIDEBreakPoints;
  const ABreakpoint: TIDEBreakPoint);
begin
  lvBreakPoints.Items.FindData(ABreakpoint).Free;
end;

procedure TBreakPointsDlg.SetBaseDirectory(const AValue: string);
begin
  if FBaseDirectory=AValue then exit;
  FBaseDirectory:=AValue;
  UpdateAll;
end;

constructor TBreakPointsDlg.Create(AOwner: TComponent);
begin
  inherited;
  Name:='BreakPointsDlg';
  BreakpointsNotification.OnAdd    := @BreakPointAdd;
  BreakpointsNotification.OnUpdate := @BreakPointUpdate;
  BreakpointsNotification.OnRemove := @BreakPointRemove;

  ActionList1.Images := IDEImages.Images_16;
  ToolBar1.Images := IDEImages.Images_16;
  mnuPopup.Images := IDEImages.Images_16;

  actEnableSelected.Caption := lisDbgItemEnable;
  actEnableSelected.Hint    := lisDbgItemEnableHint;
  actEnableSelected.ImageIndex := IDEImages.LoadImage(16, 'debugger_enable');

  actDisableSelected.Caption := lisDbgItemDisable;
  actDisableSelected.Hint    := lisDbgItemDisableHint;
  actDisableSelected.ImageIndex := IDEImages.LoadImage(16, 'debugger_disable');

  actDeleteSelected.Caption := liswlDelete; //lisDbgItemDelete;
  actDeleteSelected.Hint    := lisDbgItemDeleteHint;
  actDeleteSelected.ImageIndex := IDEImages.LoadImage(16, 'laz_delete');

  actEnableAll.Caption := lisEnableAll; //lisDbgAllItemEnable;
  actEnableAll.Hint    := lisDbgAllItemEnableHint;
  actEnableAll.ImageIndex := IDEImages.LoadImage(16, 'debugger_enable_all');

  actDisableAll.Caption := liswlDIsableAll; //lisDbgAllItemDisable;
  actDisableAll.Hint    := lisDbgAllItemDisableHint;
  actDisableAll.ImageIndex := IDEImages.LoadImage(16, 'debugger_disable_all');

  actDeleteAll.Caption := lisDeleteAll; //lisDbgAllItemDelete;
  actDeleteAll.Hint    := lisDbgAllItemDeleteHint;
  actDeleteAll.ImageIndex := IDEImages.LoadImage(16, 'menu_clean');

  actProperties.Caption:= liswlProperties;
  actProperties.Hint := lisDbgBreakpointPropertiesHint;
  actProperties.ImageIndex := IDEImages.LoadImage(16, 'menu_environment_options');

  actToggleCurrentEnable.Caption:= liswlEnabled;

  actEnableAllInSrc.Caption:= lisEnableAllInSameSource;
  actDisableAllInSrc.Caption:= lisDisableAllInSameSource;
  actDeleteAllInSrc.Caption:= lisDeleteAllInSameSource;

  FLockActionUpdate := 0;
end;

procedure TBreakPointsDlg.lvBreakPointsColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  lvBreakPoints.SortColumn := Column.Index;
end;

procedure TBreakPointsDlg.BreakpointsDlgCREATE(Sender: TObject);
begin
  Caption:= lisMenuViewBreakPoints;
  lvBreakPoints.Align:=alClient;
  lvBreakPoints.Columns[0].Caption:= lisOIPState;
  lvBreakPoints.Columns[1].Caption:= lisFilenameAddress;
  lvBreakPoints.Columns[2].Caption:= lisLineLength;
  lvBreakPoints.Columns[3].Caption:= lisCondition;
  lvBreakPoints.Columns[4].Caption:= lisLazBuildABOAction;
  lvBreakPoints.Columns[5].Caption:= lisPassCount;
  lvBreakPoints.Columns[6].Caption:= lisGroup;
  actShow.Caption := lisViewSource;
  popAdd.Caption:= lisLazBuildAdd;
  actAddSourceBP.Caption := lisSourceBreakpoint;
  actAddAddressBP.Caption := lisAddressBreakpoint;
  actAddWatchPoint.Caption := lisWatchPoint;
end;

procedure TBreakPointsDlg.actEnableSelectedExecute(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
begin
  try
    DisableAllActions;
    for n := 0 to lvBreakPoints.Items.Count -1 do
    begin
      Item := lvBreakPoints.Items[n];
      if Item.Selected then
        TIDEBreakPoint(Item.Data).Enabled := True;
    end;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.actShowExecute(Sender: TObject);
begin
  JumpToCurrentBreakPoint;
end;

procedure TBreakPointsDlg.actDisableSelectedExecute(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
begin
  try
    DisableAllActions;
    for n := 0 to lvBreakPoints.Items.Count -1 do
    begin
      Item := lvBreakPoints.Items[n];
      if Item.Selected then
        TIDEBreakPoint(Item.Data).Enabled := False;
    end;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.actAddSourceBPExecute(Sender: TObject);
var
  NewBreakpoint: TIDEBreakPoint;
  SrcEdit: TSourceEditor;
begin
  SrcEdit := SourceEditorManager.GetActiveSE;
  if SrcEdit <> nil then
    NewBreakpoint := BreakPoints.Add(SrcEdit.FileName, SrcEdit.CurrentCursorYLine)
  else
    NewBreakpoint := BreakPoints.Add('', 0);
  if DebugBoss.ShowBreakPointProperties(NewBreakpoint) = mrOk then
    UpdateAll
  else
    NewBreakpoint.Free;
end;

procedure TBreakPointsDlg.actAddWatchPointExecute(Sender: TObject);
var
  NewBreakpoint: TIDEBreakPoint;
begin
  NewBreakpoint := BreakPoints.Add('', wpsGlobal, wpkWrite);
  if DebugBoss.ShowBreakPointProperties(NewBreakpoint) = mrOk then
    UpdateAll
  else
    NewBreakpoint.Free;
end;

procedure TBreakPointsDlg.actAddAddressBPExecute(Sender: TObject);
var
  NewBreakpoint: TIDEBreakPoint;
begin
  NewBreakpoint := BreakPoints.Add(0);
  if DebugBoss.ShowBreakPointProperties(NewBreakpoint) = mrOk then
    UpdateAll
  else
    NewBreakpoint.Free;
end;

procedure TBreakPointsDlg.lvBreakPointsClick(Sender: TObject);
begin
  lvBreakPointsSelectItem(nil, nil, False);
end;

procedure TBreakPointsDlg.lvBreakPointsDBLCLICK(Sender: TObject);
begin
  lvBreakPointsSelectItem(nil, nil, False);
  JumpToCurrentBreakPoint;
end;

procedure TBreakPointsDlg.lvBreakPointsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  ItemSelected: Boolean;
  SelCanEnable, SelCanDisable: Boolean;
  AllCanEnable, AllCanDisable: Boolean;
  CurBreakPoint: TIDEBreakPoint;
  i: Integer;
begin
  if FLockActionUpdate > 0 then exit;

  ItemSelected := lvBreakPoints.Selected <> nil;
  if ItemSelected then
    CurBreakPoint := TIDEBreakPoint(lvBreakPoints.Selected.Data)
  else
    CurBreakPoint := nil;
  SelCanEnable := False;
  SelCanDisable := False;
  AllCanEnable := False;
  allCanDisable := False;
  for i := 0 to lvBreakPoints.Items.Count - 1 do begin
    if lvBreakPoints.Items[i].Data = nil then
      continue;
    if lvBreakPoints.Items[i].Selected then begin
      SelCanEnable := SelCanEnable or not TIDEBreakPoint(lvBreakPoints.Items[i].Data).Enabled;
      SelCanDisable := SelCanDisable or TIDEBreakPoint(lvBreakPoints.Items[i].Data).Enabled;
    end;
    AllCanEnable := AllCanEnable or not TIDEBreakPoint(lvBreakPoints.Items[i].Data).Enabled;
    AllCanDisable := AllCanDisable or TIDEBreakPoint(lvBreakPoints.Items[i].Data).Enabled;
  end;

  actToggleCurrentEnable.Enabled := ItemSelected;
  actToggleCurrentEnable.Checked := (CurBreakPoint <> nil) and CurBreakPoint.Enabled;

  actEnableSelected.Enabled := SelCanEnable;
  actDisableSelected.Enabled := SelCanDisable;
  actDeleteSelected.Enabled := ItemSelected;

  actEnableAll.Enabled := AllCanEnable;
  actDisableAll.Enabled := AllCanDisable;
  actDeleteAll.Enabled := lvBreakPoints.Items.Count > 0;

  actEnableAllInSrc.Enabled := ItemSelected;
  actDisableAllInSrc.Enabled := ItemSelected;
  actDeleteAllInSrc.Enabled := ItemSelected;

  actProperties.Enabled := ItemSelected;
  actShow.Enabled := ItemSelected;
end;

procedure TBreakPointsDlg.popDeleteAllSameSourceCLICK(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
  CurItem: TListItem;
  CurBreakPoint: TIDEBreakPoint;
  Filename: String;
begin
  try
    DisableAllActions;
    CurItem:=lvBreakPoints.Selected;
    if (CurItem=nil) then exit;
    Filename:=TIDEBreakpoint(CurItem.Data).Source;
    if MessageDlg(lisDeleteAllBreakpoints,
      Format(lisDeleteAllBreakpoints2, ['"', Filename, '"']),
      mtConfirmation,[mbYes,mbCancel],0)<>mrYes
    then exit;
    for n := lvBreakPoints.Items.Count - 1 downto 0 do
    begin
      Item := lvBreakPoints.Items[n];
      CurBreakPoint:=TIDEBreakPoint(Item.Data);
      if CompareFilenames(CurBreakPoint.Source,Filename)=0
      then CurBreakPoint.Free;
    end;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.popDisableAllSameSourceCLICK(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
  CurItem: TListItem;
  CurBreakPoint: TIDEBreakPoint;
  Filename: String;
begin
  try
    DisableAllActions;
    CurItem:=lvBreakPoints.Selected;
    if (CurItem=nil) then exit;
    Filename:=TIDEBreakpoint(CurItem.Data).Source;
    for n := 0 to lvBreakPoints.Items.Count - 1 do
    begin
      Item := lvBreakPoints.Items[n];
      CurBreakPoint:=TIDEBreakPoint(Item.Data);
      if CompareFilenames(CurBreakPoint.Source,Filename)=0
      then CurBreakPoint.Enabled := False;
    end;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.popEnableAllSameSourceCLICK(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
  CurItem: TListItem;
  CurBreakPoint: TIDEBreakPoint;
  Filename: String;
begin
  try
    DisableAllActions;
    CurItem:=lvBreakPoints.Selected;
    if (CurItem=nil) then exit;
    Filename:=TIDEBreakpoint(CurItem.Data).Source;
    for n := 0 to lvBreakPoints.Items.Count - 1 do
    begin
      Item := lvBreakPoints.Items[n];
      CurBreakPoint:=TIDEBreakPoint(Item.Data);
      if CompareFilenames(CurBreakPoint.Source,Filename)=0
      then CurBreakPoint.Enabled := True;
    end;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.popDeleteAllClick(Sender: TObject);
var
  n: Integer;
begin                                    
  try
    DisableAllActions;
    if MessageDlg(lisDeleteAllBreakpoints,
      lisDeleteAllBreakpoints,
      mtConfirmation,[mbYes,mbCancel],0)<>mrYes
    then exit;
    lvBreakPoints.BeginUpdate;
    try
      for n := lvBreakPoints.Items.Count - 1 downto 0 do
        TIDEBreakPoint(lvBreakPoints.Items[n].Data).Free;
    finally
      lvBreakPoints.EndUpdate;
    end;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.popDeleteClick(Sender: TObject);
begin
  try
    DisableAllActions;
    DeleteSelectedBreakpoints;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.popDisableAllClick(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
begin
  try
    DisableAllActions;
    for n := 0 to lvBreakPoints.Items.Count - 1 do
    begin
      Item := lvBreakPoints.Items[n];
      if Item.Data <> nil
      then TIDEBreakPoint(Item.Data).Enabled := False;
    end;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.popEnableAllClick(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
begin
  try
    DisableAllActions;
    for n := 0 to lvBreakPoints.Items.Count - 1 do
    begin
      Item := lvBreakPoints.Items[n];
      if Item.Data <> nil
      then TIDEBreakPoint(Item.Data).Enabled := True;
    end;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.popEnabledClick(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
  Enable: Boolean;
begin
  try
    DisableAllActions;
    Item:=lvBreakPoints.Selected;
    if (Item=nil) then exit;

    Enable := not TIDEBreakPoint(Item.Data).Enabled;

    if lvBreakPoints.SelCount > 1
    then begin
      for n := 0 to lvBreakPoints.Items.Count -1 do
      begin
        Item := lvBreakPoints.Items[n];
        if Item.Selected then
          TIDEBreakPoint(Item.Data).Enabled := Enable;
      end;
    end
    else begin
      TIDEBreakPoint(Item.Data).Enabled:= Enable;
    end;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.popPropertiesClick(Sender: TObject);
begin
  try
    DisableAllActions;
    ShowProperties;
  finally
    lvBreakPointsSelectItem(nil, nil, False);
  end;
end;

procedure TBreakPointsDlg.DoEndUpdate;
begin
  inherited DoEndUpdate;
  if bpdsItemsNeedUpdate in FStates then UpdateAll;
  lvBreakPointsSelectItem(nil, nil, False);
end;

procedure TBreakPointsDlg.DisableAllActions;
var
  i: Integer;
begin
  for i := 0 to ActionList1.ActionCount - 1 do
    (ActionList1.Actions[i] as TAction).Enabled := False;
  actAddSourceBP.Enabled := True;
  actAddAddressBP.Enabled := True;
  actAddWatchPoint.Enabled := True;
end;

procedure TBreakPointsDlg.UpdateItem(const AnItem: TListItem;
  const ABreakpoint: TIDEBreakPoint);
var
  s, Filename: String;
begin
  // Filename/Address
  // Line/Length
  // Condition
  // Action
  // Pass Count
  // Group

  // state
  AnItem.Caption := GetBreakPointStateDescription(ABreakpoint);
  
  // filename/address
  case ABreakpoint.Kind of
    bpkSource:
      begin
        Filename:=ABreakpoint.Source;
        if BaseDirectory<>'' then
          Filename:=CreateRelativePath(Filename,BaseDirectory);
        AnItem.SubItems[0] := Filename;
        // line
        if ABreakpoint.Line > 0
        then AnItem.SubItems[1] := IntToStr(ABreakpoint.Line)
        else AnItem.SubItems[1] := '';
      end;
    bpkAddress:
      begin
        // todo: how to define digits count? 8 or 16 depends on gdb pointer size for platform
        AnItem.SubItems[0] := '$' + IntToHex(ABreakpoint.Address, 8);
      end;
    bpkData:
      begin
        AnItem.SubItems[0] := ABreakpoint.WatchData;
        case ABreakpoint.WatchScope of
          wpsGlobal: s:= lisWatchScopeGlobal;
          wpsLocal:  s:= lisWatchScopeLocal;
        end;
        s := s +' / ';
        case ABreakpoint.WatchKind of
          wpkRead:      s := s + lisWatchKindRead;
          wpkReadWrite: s := s + lisWatchKindReadWrite;
          wpkWrite:     s := s + lisWatchKindWrite;
        end;
        AnItem.SubItems[1] := s;
      end;
  end;

  // expression
  AnItem.SubItems[2] := ABreakpoint.Expression;
  
  // actions
  AnItem.SubItems[3]  := GetBreakPointActionsDescription(ABreakpoint);
  
  // hitcount
  AnItem.SubItems[4] := IntToStr(ABreakpoint.HitCount);
  
  // group
  if ABreakpoint.Group = nil
  then AnItem.SubItems[5] := ''
  else AnItem.SubItems[5] := ABreakpoint.Group.Name;

  lvBreakPointsSelectItem(nil, nil, False);
end;

procedure TBreakPointsDlg.UpdateAll;
var
  i: Integer;
  CurItem: TListItem;
begin
  if UpdateCount>0 then begin
    Include(FStates,bpdsItemsNeedUpdate);
    exit;
  end;
  Exclude(FStates,bpdsItemsNeedUpdate);
  inc(FLockActionUpdate);
  for i:=0 to lvBreakPoints.Items.Count-1 do begin
    CurItem:=lvBreakPoints.Items[i];
    UpdateItem(CurItem,TIDEBreakPoint(CurItem.Data));
  end;
  dec(FLockActionUpdate);
  lvBreakPointsSelectItem(nil, nil, False);
end;

procedure TBreakPointsDlg.DeleteSelectedBreakpoints;
var
  Item: TListItem;
  CurBreakPoint: TIDEBreakPoint;
  Msg: String;
  List: TList;
  n: Integer;
begin
  Item:=lvBreakPoints.Selected;
  if Item = nil then exit;

  if lvBreakPoints.SelCount = 1 then
  begin
    CurBreakPoint:=TIDEBreakPoint(Item.Data);
    case CurBreakPoint.Kind of
      bpkSource: Msg := Format(lisDeleteBreakpointAtLine, [#13, CurBreakPoint.Source, CurBreakPoint.Line]);
      bpkAddress: Msg := Format(lisDeleteBreakpointForAddress, ['$' + IntToHex(CurBreakPoint.Address, 8)]);
      bpkData: Msg := Format(lisDeleteBreakpointForWatch, [CurBreakPoint.WatchData]);
    end;
  end
  else
    Msg := lisDeleteAllSelectedBreakpoints;
  if MessageDlg(Msg, mtConfirmation, [mbYes,mbCancel],0) <> mrYes then exit;

  if lvBreakPoints.SelCount = 1
  then begin
    TObject(Item.Data).Free;
    Exit;
  end;

  List := TList.Create;
  for n := 0 to lvBreakPoints.Items.Count - 1 do
  begin
    Item := lvBreakPoints.Items[n];
    if Item.Selected
    then List.Add(Item.Data);
  end;

  lvBreakPoints.BeginUpdate;
  try
    for n := 0 to List.Count - 1 do
      TObject(List[n]).Free;
  finally
    lvBreakPoints.EndUpdate;
  end;
  List.Free;
end;

procedure TBreakPointsDlg.JumpToCurrentBreakPoint;
var
  CurItem: TListItem;
  CurBreakPoint: TIDEBreakPoint;
begin
  CurItem:=lvBreakPoints.Selected;
  if CurItem=nil then exit;
  CurBreakPoint:=TIDEBreakPoint(CurItem.Data);
  if CurBreakPoint.Kind = bpkSource then
    MainIDE.DoJumpToSourcePosition(CurBreakPoint.Source, 0, CurBreakPoint.Line, 0, True);
end;

procedure TBreakPointsDlg.ShowProperties;
var
  Item: TListItem;
  CurBreakPoint: TIDEBreakPoint;
begin
  Item:=lvBreakPoints.Selected;
  if Item = nil then exit;

  CurBreakPoint:=TIDEBreakPoint(Item.Data);

  DebugBoss.ShowBreakPointProperties(CurBreakPoint);
end;

procedure TBreakPointsDlg.DoBreakPointsChanged;
var
  i: Integer;
begin
  lvBreakPoints.Items.Clear;
  if BreakPoints <> nil
  then begin
    for i:=0 to BreakPoints.Count-1 do
      BreakPointUpdate(BreakPoints, BreakPoints.Items[i]);
  end;
end;

procedure TBreakPointsDlg.DoBeginUpdate;
begin
  inherited DoBeginUpdate;
  DisableAllActions;
end;

end.

