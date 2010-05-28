{ This unit installs the EasyDockMgr as dock master for the Lazarus IDE.

  Copyright (C) 2010 Mattias Gaertner  mattias@freepascal.org

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this library. If you modify
  this library, you may extend this exception to your version of the library,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit RegisterEasyDockMgr;

{$mode objfpc}{$H+}

interface

uses
  Math, Classes, SysUtils, LCLProc, Forms, Controls, IDEWindowIntf,
  uMakeSite;

type

  { TIDEEasyDockMaster }

  TIDEEasyDockMaster = class(TIDEDockMaster)
  private
    procedure GetDefaultBounds(AForm: TCustomForm; out Creator: TIDEWindowCreator;
      out NewBounds: TRect; out DockSiblingName: string; out DockAlign: TAlign);
  public
    procedure MakeIDEWindowDockSite(AForm: TCustomForm); override;
    procedure MakeIDEWindowDockable(AControl: TWinControl); override;
    function IsDockSite(AForm: TCustomForm): boolean;
    function IsDockable(AForm: TCustomForm): boolean;
    procedure LoadDefaultLayout; override;
    procedure ShowForm(AForm: TCustomForm; BringToFront: boolean); override;
  end;

procedure Register;

implementation

procedure Register;
begin
  // ToDo: register menu items, events and options
end;

{ TIDEEasyDockMaster }

procedure TIDEEasyDockMaster.GetDefaultBounds(AForm: TCustomForm; out
  Creator: TIDEWindowCreator; out NewBounds: TRect; out DockSiblingName: string;
  out DockAlign: TAlign);
begin
  NewBounds:=Rect(0,0,0,0);
  DockSiblingName:='';
  DockAlign:=alNone;
  Creator:=IDEWindowCreators.FindWithName(AForm.Name);
  if Creator=nil then exit;
  if Creator.OnGetLayout<>nil then
    Creator.OnGetLayout(Self,AForm.Name,NewBounds,DockSiblingName,DockAlign)
  else begin
    Creator.GetDefaultBounds(AForm,NewBounds);
    DockSiblingName:=Creator.DockSibling;
    DockAlign:=Creator.DockAlign;
  end;
  NewBounds.Left:=Min(10000,Max(-10000,NewBounds.Left));
  NewBounds.Top:=Min(10000,Max(-10000,NewBounds.Top));
  NewBounds.Right:=Max(NewBounds.Left+100,NewBounds.Right);
  NewBounds.Bottom:=Max(NewBounds.Top+100,NewBounds.Bottom);
end;

procedure TIDEEasyDockMaster.MakeIDEWindowDockSite(AForm: TCustomForm);
var
  Creator: TIDEWindowCreator;
  NewBounds: TRect;
  DockSiblingName: string;
  DockAlign: TAlign;
begin
  debugln(['TIDEEasyDockMaster.MakeIDEWindowDockSite BEFORE ',DbgSName(AForm),' ',dbgs(AForm.BoundsRect)]);
  GetDefaultBounds(AForm,Creator,NewBounds,DockSiblingName,DockAlign);
  if Creator<>nil then
    AForm.BoundsRect:=NewBounds;
  DockMaster.AddElasticSites(AForm, [alBottom]);
  debugln(['TIDEEasyDockMaster.MakeIDEWindowDockSite AFTER ',DbgSName(AForm),' ',dbgs(AForm.BoundsRect)]);
end;

procedure TIDEEasyDockMaster.MakeIDEWindowDockable(AControl: TWinControl);
begin
  debugln(['TIDEEasyDockMaster.MakeIDEWindowDockable BEFORE ',DbgSName(AControl),' ',dbgs(AControl.BoundsRect)]);
  AControl.UndockWidth:=AControl.Width;
  AControl.UndockHeight:=AControl.Height;
  DockMaster.MakeDockable(AControl);
  debugln(['TIDEEasyDockMaster.MakeIDEWindowDockable AFTERE ',DbgSName(AControl),' ',dbgs(AControl.BoundsRect)]);
end;

function TIDEEasyDockMaster.IsDockSite(AForm: TCustomForm): boolean;
var
  i: Integer;
begin
  Result:=false;
  if AForm=nil then exit;
  if AForm.Parent<>nil then exit;
  for i:=0 to AForm.ControlCount-1 do
    if AForm.Controls[i] is TDockPanel then exit(true);
end;

function TIDEEasyDockMaster.IsDockable(AForm: TCustomForm): boolean;
begin
  Result:=false;
  if AForm=nil then exit;
  if AForm.Parent=nil then exit;
  Result:=true;
end;

procedure TIDEEasyDockMaster.LoadDefaultLayout;
begin
  // ToDo: load the users default layout
end;

procedure TIDEEasyDockMaster.ShowForm(AForm: TCustomForm; BringToFront: boolean
  );
var
  Parent: TCustomForm;
  Creator: TIDEWindowCreator;
  NewBounds: TRect;
  DockSiblingName: string;
  DockAlign: TAlign;
  DockSibling: TCustomForm;
  NewDockSite: TWinControl;
begin
  debugln(['TIDEEasyDockMaster.ShowForm ',DbgSName(AForm),' BringToFront=',BringToFront,' IsDockSite=',IsDockSite(AForm),' IsDockable=',IsDockable(AForm)]);
  try
    if not (IsDockSite(AForm) or IsDockable(AForm)) then
    begin
      AForm.DisableAlign;
      // this form was not yet docked
      // place it at a default position and make it dockable
      GetDefaultBounds(AForm,Creator,NewBounds,DockSiblingName,DockAlign);
      if Creator<>nil then
      begin
        // this window should become dockable
        NewBounds.Left:=Min(10000,Max(-10000,NewBounds.Left));
        NewBounds.Top:=Min(10000,Max(-10000,NewBounds.Top));
        NewBounds.Right:=Max(NewBounds.Left+100,NewBounds.Right);
        NewBounds.Bottom:=Max(NewBounds.Top+100,NewBounds.Bottom);
        AForm.UndockWidth:=NewBounds.Right-NewBounds.Left;
        AForm.UndockHeight:=NewBounds.Bottom-NewBounds.Top;
        debugln(['TIDEEasyDockMaster.ShowForm creator for ',DbgSName(AForm),' found: Left=',Creator.Left,' Top=',Creator.Top,' Width=',Creator.Width,' Height=',Creator.Height,' DockSiblingName=',DockSiblingName,' DockAlign=',dbgs(DockAlign)]);
        if DockSiblingName<>'' then
        begin
          DockSibling:=Screen.FindForm(DockSiblingName);
          debugln(['TIDEEasyDockMaster.ShowForm DockSiblingName="',DockSiblingName,'" DockSibling=',DbgSName(DockSibling)]);
          if DockSibling<>nil then
          begin
            NewDockSite:=DockSibling.HostDockSite;
            debugln(['TIDEEasyDockMaster.ShowForm NewDockSite=',DbgSName(NewDockSite)]);
            if NewDockSite<>nil then
              AForm.ManualDock(NewDockSite,nil,DockAlign)
            else
              AForm.ManualDock(nil,DockSibling,DockAlign);
          end;
        end;
        if AForm.Parent=nil then begin
          debugln(['TIDEEasyDockMaster.ShowForm ',DbgSName(AForm),' make dockable NewBounds=',dbgs(NewBounds)]);
          AForm.BoundsRect:=NewBounds;
          // make form dockable
          MakeIDEWindowDockable(AForm);
        end;
      end;
      AForm.EnableAlign;
    end;

  finally
    Parent:=GetParentForm(AForm);
    // ToDo switch pageindex of all parent note books
    if Parent<>nil then
      if BringToFront then
        Parent.ShowOnTop
      else
        Parent.Show;
  end;
  debugln(['TIDEEasyDockMaster.ShowForm END ',DbgSName(AForm),' ',dbgs(AForm.BoundsRect)]);
end;

initialization
  // create the dockmaster in the initialization section, so that is ready
  // when the Register procedures of the packages are called.
  TDockMaster.Create(nil);
  IDEDockMaster:=TIDEEasyDockMaster.Create;

finalization
  FreeAndNil(IDEDockMaster);
  FreeAndNil(DockMaster);

end.

