{ $Id$ }
{               ----------------------------------------------
                 breakpointsdlg.pp  -  Overview of breeakponts
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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LResources, StdCtrls,
  Buttons, Extctrls, Menus, ComCtrls, IDEProcs, Debugger, DebuggerDlg;

type
  TBreakPointsDlgState = (
    bpdsItemsNeedUpdate
    );
  TBreakPointsDlgStates = set of TBreakPointsDlgState;

  TBreakPointsDlg = class(TDebuggerDlg)
    lvBreakPoints: TListView;
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
    procedure lvBreakPointsClick(Sender: TObject);
    procedure lvBreakPointsSelectItem(Sender: TObject; AItem: TListItem;
      Selected: Boolean);
    procedure mnuPopupPopup(Sender: TObject);
    procedure popAddSourceBPClick(Sender: TObject);
    procedure popPropertiesClick(Sender: TObject);
    procedure popEnabledClick(Sender: TObject);
    procedure popDeleteClick(Sender: TObject);
    procedure popDisableAllClick(Sender: TObject);
    procedure popEnableAllClick(Sender: TObject);
    procedure popDeleteAllClick(Sender: TObject);
  private
    FBaseDirectory: string;
    FBreakpointsNotification: TDBGBreakPointsNotification;
    FStates: TBreakPointsDlgStates;
    procedure BreakPointAdd(const ASender: TDBGBreakPoints;
                            const ABreakpoint: TDBGBreakPoint);
    procedure BreakPointUpdate(const ASender: TDBGBreakPoints;
                               const ABreakpoint: TDBGBreakPoint);
    procedure BreakPointRemove(const ASender: TDBGBreakPoints;
                               const ABreakpoint: TDBGBreakPoint);
    procedure SetBaseDirectory(const AValue: string);

    procedure UpdateItem(const AItem: TListItem;
      const ABreakpoint: TDBGBreakPoint);
    procedure UpdateAll;
  protected
    procedure SetDebugger(const ADebugger: TDebugger); override;
    procedure DoEndUpdate; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    property BaseDirectory: string read FBaseDirectory write SetBaseDirectory;
  end;


implementation

procedure TBreakPointsDlg.BreakPointAdd(const ASender: TDBGBreakPoints;
  const ABreakpoint: TDBGBreakPoint);
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

procedure TBreakPointsDlg.BreakPointUpdate(const ASender: TDBGBreakPoints;
  const ABreakpoint: TDBGBreakPoint);
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

procedure TBreakPointsDlg.BreakPointRemove(const ASender: TDBGBreakPoints;
  const ABreakpoint: TDBGBreakPoint);
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
  FBreakpointsNotification := TDBGBreakPointsNotification.Create;
  FBreakpointsNotification.AddReference;
  FBreakpointsNotification.OnAdd := @BreakPointAdd;
  FBreakpointsNotification.OnUpdate := @BreakPointUpdate;
  FBreakpointsNotification.OnRemove := @BreakPointRemove;
end;       

destructor TBreakPointsDlg.Destroy;
begin
  SetDebugger(nil);
  FBreakpointsNotification.OnAdd := nil;
  FBreakpointsNotification.OnUpdate := nil;
  FBreakpointsNotification.OnRemove := nil;
  FBreakpointsNotification.ReleaseReference;
  inherited;
end;

procedure TBreakPointsDlg.lvBreakPointsClick(Sender: TObject);
begin
end;

procedure TBreakPointsDlg.lvBreakPointsSelectItem(Sender: TObject;
  AItem: TListItem; Selected: Boolean);
begin
end;

procedure TBreakPointsDlg.mnuPopupPopup(Sender: TObject);
var
  Enable: Boolean;
  CurBreakPoint: TDBGBreakPoint;
begin
  Enable := lvBreakPoints.Selected <> nil;
  if Enable then
    CurBreakPoint:=TDBGBreakPoint(lvBreakPoints.Selected.Data)
  else
    CurBreakPoint:=nil;
  popProperties.Enabled := Enable;
  popEnabled.Enabled := Enable;
  if CurBreakPoint<>nil then
    popEnabled.Checked := CurBreakPoint.Enabled
  else
    popEnabled.Checked := false;
  popDelete.Enabled := Enable;
  
  Enable := lvBreakPoints.Items.Count>0;
  popDisableAll.Enabled := Enable;
  popDeleteAll.Enabled := Enable;
  popEnableAll.Enabled := Enable;
end;

procedure TBreakPointsDlg.popAddSourceBPClick(Sender: TObject);
begin
end;

procedure TBreakPointsDlg.popDeleteAllClick(Sender: TObject);
var
  n: Integer;
begin                                    
  for n := lvBreakPoints.Items.Count - 1 downto 0 do
    TDBGBreakPoint(lvBreakPoints.Items[n].Data).Free;
end;

procedure TBreakPointsDlg.popDeleteClick(Sender: TObject);
var
  CurItem: TListItem;
  CurBreakPoint: TDBGBreakPoint;
begin
  CurItem:=lvBreakPoints.Selected;
  if CurItem=nil then exit;
  CurBreakPoint:=TDBGBreakPoint(CurItem.Data);
  if MessageDlg('Delete breakpoint?',
    'Delete breakpoint at'#13
    +'"'+CurBreakPoint.Source+'" line '+IntToStr(CurBreakPoint.Line)+'?',
    mtConfirmation,[mbYes,mbCancel],0)<>mrYes
  then exit;
  CurBreakPoint.Free;
end;

procedure TBreakPointsDlg.popDisableAllClick(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
begin
  for n := 0 to lvBreakPoints.Items.Count - 1 do
  begin
    Item := lvBreakPoints.Items[n];
    if Item.Data <> nil
    then TDBGBreakPoint(Item.Data).Enabled := False;
  end;
end;

procedure TBreakPointsDlg.popEnableAllClick(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
begin
  for n := 0 to lvBreakPoints.Items.Count - 1 do
  begin
    Item := lvBreakPoints.Items[n];
    if Item.Data <> nil
    then TDBGBreakPoint(Item.Data).Enabled := True;
  end;
end;

procedure TBreakPointsDlg.popEnabledClick(Sender: TObject);
var
  CurItem: TListItem;
begin
  CurItem:=lvBreakPoints.Selected;
  if (CurItem=nil) then exit;
  TDBGBreakPoint(CurItem.Data).Enabled:=not TDBGBreakPoint(CurItem.Data).Enabled;
end;

procedure TBreakPointsDlg.popPropertiesClick(Sender: TObject);
begin     
end;

procedure TBreakPointsDlg.SetDebugger(const ADebugger: TDebugger);
begin
  if ADebugger <> Debugger
  then begin
    if Debugger <> nil
    then begin                    
      Debugger.Breakpoints.RemoveNotification(FBreakpointsNotification);
    end;
    inherited;
    if Debugger <> nil
    then begin
      Debugger.Breakpoints.AddNotification(FBreakpointsNotification);
    end;
  end
  else inherited;
end;

procedure TBreakPointsDlg.DoEndUpdate;
begin
  inherited DoEndUpdate;
  if bpdsItemsNeedUpdate in FStates then UpdateAll;
end;

procedure TBreakPointsDlg.UpdateItem(const AItem: TListItem;
  const ABreakpoint: TDBGBreakPoint);
const
  DEBUG_ACTION: array[TDBGBreakPointAction] of string =
    ('Break', 'Enable Group', 'Disable Group');
    
  //                 enabled  valid
  DEBUG_STATE: array[Boolean, TValidState] of String = (
             {vsUnknown, vsValid, vsInvalid}
    {Disabled} ('?',    'Disabled','Invalid'),
    {Endabled} ('?',    'Enabled', 'Invalid'));
var
  Action: TDBGBreakPointAction;
  S: String;
  Filename: String;
begin
  // Filename/Address
  // Line/Length
  // Condition
  // Action
  // Pass Count
  // Group

  // state
  AItem.Caption := DEBUG_STATE[ABreakpoint.Enabled, ABreakpoint.Valid];
  
  // filename
  Filename:=ABreakpoint.Source;
  if BaseDirectory<>'' then
    Filename:=CreateRelativePath(Filename,BaseDirectory);
  AItem.SubItems[0] := Filename;
  
  // line
  if ABreakpoint.Line > 0
  then AItem.SubItems[1] := IntToStr(ABreakpoint.Line)
  else AItem.SubItems[1] := '';
  
  // expression
  AItem.SubItems[2] := ABreakpoint.Expression;
  
  // actions
  S := '';
  for Action := Low(Action) to High(Action) do
    if Action in ABreakpoint.Actions
    then begin
      if S <> '' then s := S + ', ';
      S := S + DEBUG_ACTION[Action]
    end;
  AItem.SubItems[3]  := S;
  
  // hitcount
  AItem.SubItems[4] := IntToStr(ABreakpoint.HitCount);
  
  // group
  if ABreakpoint.Group = nil
  then AItem.SubItems[5] := ''
  else AItem.SubItems[5] := ABreakpoint.Group.Name;
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
  for i:=0 to lvBreakPoints.Items.Count-1 do begin
    CurItem:=lvBreakPoints.Items[i];
    UpdateItem(CurItem,TDBGBreakPoint(CurItem.Data));
  end;
end;


initialization
  {$I breakpointsdlg.lrs}

end.

{ =============================================================================
  $Log$
  Revision 1.13  2003/05/27 20:58:12  mattias
  implemented enable and deleting breakpoint in breakpoint dlg

  Revision 1.12  2003/05/27 15:04:00  mattias
  small fixes for debugger without file

  Revision 1.11  2003/05/23 14:12:51  mattias
  implemented restoring breakpoints

  Revision 1.10  2003/05/22 23:08:19  marc
  MWE: = Moved and renamed debuggerforms so that they can be
         modified by the ide
       + Added some parsing to evaluate complex expressions
         not understood by the debugger

  Revision 1.9  2003/05/18 10:42:57  mattias
  implemented deleting empty submenus

  Revision 1.8  2003/02/28 19:10:25  mattias
  added new ... dialog

  Revision 1.7  2002/05/30 22:45:57  lazarus
  MWE:
    - Removed menucreation from loaded since streaming works

  Revision 1.6  2002/05/10 06:57:47  lazarus
  MG: updated licenses

  Revision 1.5  2002/04/24 20:42:29  lazarus
  MWE:
    + Added watches
    * Updated watches and watchproperty dialog to load as resource
    = renamed debugger resource files from *.lrc to *.lrs
    * Temporary fixed language problems on GDB (bug #508)
    * Made Debugmanager dialog handling more generic

  Revision 1.4  2002/03/27 00:31:02  lazarus
  MWE:
    * activated selection dependent popup

  Revision 1.3  2002/03/25 22:38:29  lazarus
  MWE:
    + Added invalidBreakpoint image
    * Reorganized uniteditor so that breakpoints can be added erternal
    * moved breakpoints events to notification object

  Revision 1.2  2002/03/23 15:54:30  lazarus
  MWE:
    + Added locals dialog
    * Modified breakpoints dialog (load as resource)
    + Added generic debuggerdlg class
    = Reorganized main.pp, all debbugger relater routines are moved
      to include/ide_debugger.inc

  Revision 1.1  2002/03/12 23:55:36  lazarus
  MWE:
    * More delphi compatibility added/updated to TListView
    * Introduced TDebugger.locals
    * Moved breakpoints dialog to debugger dir
    * Changed breakpoints dialog to read from resource

}
