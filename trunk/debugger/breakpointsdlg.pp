{ $Id$ }
{               ----------------------------------------------
                 breakpointsdlg.pp  -  Overview of breeakponts
                ----------------------------------------------

 @created(Fri Dec 14st WET 2001)
 @lastmod($Date$)
 @author(Shane Miller)
 @author(Marc Weustink <marc@@dommelstein.net>)

 This unit contains the Breakpoint dialog.


/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
}

unit breakpointsdlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LResources, StdCtrls,
  Buttons, Extctrls, Menus, ComCtrls, Debugger, DebuggerDlg;

type
  TBreakPointsDlg = class(TDebuggerDlg)
    lvBreakPoints: TListView;
    procedure lvBreakPointsClick(Sender: TObject);
    procedure lvBreakPointsSelectItem(Sender: TObject; AItem: TListItem; Selected: Boolean);
    mnuPopup: TPopupMenu;
    popAdd: TMenuItem;
    popAddSourceBP: TMenuItem;
    procedure popAddSourceBPClick(Sender: TObject);
    N1: TMenuItem; //--------------
    popProperties: TMenuItem;
    procedure popPropertiesClick(Sender: TObject);
    popEnabled: TMenuItem;
    procedure popEnabledClick(Sender: TObject);
    popDelete: TMenuItem;
    procedure popDeleteClick(Sender: TObject);
    N2: TMenuItem; //--------------
    popDisableAll: TMenuItem;
    procedure popDisableAllClick(Sender: TObject);
    popEnableAll: TMenuItem;
    procedure popEnableAllClick(Sender: TObject);
    popDeleteAll: TMenuItem;
    procedure popDeleteAllClick(Sender: TObject);
  private 
    FBreakpointsNotification: TDBGBreakPointsNotification;
    procedure BreakPointAdd(const ASender: TDBGBreakPoints; const ABreakpoint: TDBGBreakPoint);
    procedure BreakPointUpdate(const ASender: TDBGBreakPoints; const ABreakpoint: TDBGBreakPoint);
    procedure BreakPointRemove(const ASender: TDBGBreakPoints; const ABreakpoint: TDBGBreakPoint);

    procedure UpdateItem(const AItem: TListItem; const ABreakpoint: TDBGBreakPoint);
  protected
    procedure Loaded; override;
    procedure SetDebugger(const ADebugger: TDebugger); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // publish some properties until fpcbug #1888 is fixed
    property Top;
    property Left;
    property Width; 
    property Height; 
    property Caption;
  end;


implementation

procedure TBreakPointsDlg.BreakPointAdd(const ASender: TDBGBreakPoints; const ABreakpoint: TDBGBreakPoint);
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

procedure TBreakPointsDlg.BreakPointUpdate(const ASender: TDBGBreakPoints; const ABreakpoint: TDBGBreakPoint);
var
  Item: TListItem;
begin
  if ABreakpoint = nil then Exit;

  Item := lvBreakPoints.Items.FindData(ABreakpoint);
  if Item = nil
  then BreakPointAdd(ASender, ABreakPoint)
  else UpdateItem(Item, ABreakPoint);
end;

procedure TBreakPointsDlg.BreakPointRemove(const ASender: TDBGBreakPoints; const ABreakpoint: TDBGBreakPoint);
begin
  lvBreakPoints.Items.FindData(ABreakpoint).Free;
end;

constructor TBreakPointsDlg.Create(AOwner: TComponent);
begin
  inherited;
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

procedure TBreakPointsDlg.Loaded;
begin
  inherited Loaded;
  
  // Not yet through resources
  mnuPopUp.Items.Add(popAdd);
  popAdd.Add(popAddSourceBP);
  mnuPopUp.Items.Add(N1);
  mnuPopUp.Items.Add(popProperties);
  mnuPopUp.Items.Add(popEnabled);
  mnuPopUp.Items.Add(popDelete);
  mnuPopUp.Items.Add(N2);
  mnuPopUp.Items.Add(popDisableAll);
  mnuPopUp.Items.Add(popEnableAll);
  mnuPopUp.Items.Add(popDeleteAll);
end;

procedure TBreakPointsDlg.lvBreakPointsClick(Sender: TObject);
begin
end;

procedure TBreakPointsDlg.lvBreakPointsSelectItem(Sender: TObject; AItem: TListItem; Selected: Boolean);
var
  Enable: Boolean;
begin
  Enable := lvBreakPoints.Selected <> nil;
  popProperties.Enabled := Enable;
  popEnabled.Enabled := Enable;
  popDelete.Enabled := Enable;
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
begin
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
begin
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

procedure TBreakPointsDlg.UpdateItem(const AItem: TListItem; const ABreakpoint: TDBGBreakPoint);
const
  DEBUG_ACTION: array[TDBGBreakPointAction] of string = ('Break', 'Enable Group', 'Disable Group');
  //                 enabled  valid
  DEBUG_STATE: array[Boolean, Boolean] of String = (('?', ''), ('!', '*'));
var
  Action: TDBGBreakPointAction;
  S: String;
begin
// Filename/Address
// Line/Length
// Condition
// Action
// Pass Count
// Group

  AItem.Caption := DEBUG_STATE[ABreakpoint.Enabled, ABreakpoint.Valid];
  AItem.SubItems[0] := ABreakpoint.Source;
  if ABreakpoint.Line > 0
  then AItem.SubItems[1] := IntToStr(ABreakpoint.Line)
  else AItem.SubItems[1] := '';
  AItem.SubItems[2] := ABreakpoint.Expression;
  S := '';
  for Action := Low(Action) to High(Action) do
    if Action in ABreakpoint.Actions
    then begin
      if S <> '' then s := S + ', ';
      S := S + DEBUG_ACTION[Action]
    end;
  AItem.SubItems[3]  := S;
  AItem.SubItems[4] := IntToStr(ABreakpoint.HitCount);
  if ABreakpoint.Group = nil
  then AItem.SubItems[5] := ''
  else AItem.SubItems[5] := ABreakpoint.Group.Name;
end;


initialization
  {$I breakpointsdlg.lrs}

end.

{ =============================================================================
  $Log$
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