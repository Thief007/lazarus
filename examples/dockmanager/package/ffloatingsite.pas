unit fFloatingSite;
(* Floating dock host.
  Host one or more docked clients.
  To distinguish multiple clients, use the form header style (named caption).
  Destroy the site on the last undock.

  Handle flaws of the Delphi docking model (improper undock).
  - Disallow TControls to float (else nothing but trouble).
  - For the IDE, floating client forms must wrap themselves into a new
    host site, to allow for continued docking of other clients.
*)

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls;

type
  TFloatingSite = class(TForm)
    Image1: TImage;
    procedure FormDockDrop(Sender: TObject; Source: TDragDockObject;
      X, Y: Integer);
    procedure FormUnDock(Sender: TObject; Client: TControl;
      NewTarget: TWinControl; var Allow: Boolean);
  protected
    procedure Loaded; override;
  public
    procedure UpdateCaption(without: TControl);
  end;

var
  FloatingSite: TFloatingSite;

implementation

uses
  LCLproc,  //debugging only
  EasyDockSite; //our DockManager

{ TFloatingSite }

procedure TFloatingSite.UpdateCaption(without: TControl);
var
  i: integer;
  s: string;
  ctl: TControl;
begin
(* Show the combined captions of all clients.
  Exclude client to be undocked.
*)
  s := '';
  for i := 0 to DockClientCount - 1 do begin
    ctl := DockClients[i];
    if ctl <> without then
      s := s + GetDockCaption(ctl) + ', ';
  end;
  SetLength(s, Length(s) - 2); //strip trailing ", "
  Caption := s;
end;

procedure TFloatingSite.FormDockDrop(Sender: TObject; Source: TDragDockObject;
  X, Y: Integer);
begin
(* Update the caption.
*)
  UpdateCaption(nil);
end;

procedure TFloatingSite.FormUnDock(Sender: TObject; Client: TControl;
  NewTarget: TWinControl; var Allow: Boolean);
begin
(* Check for undock last client, if allowed kill empty docksite.
  Refresh caption after undock.

Shit: in both cases the docking management does the opposite of what it should do :-(

When the last control is dragged away, it's hosted in a *new* site.
When a second control is dragged away, the entire site is moved.

Fix: disallow TControls to become floating.
*)
//try to distinguish between TControl and TWinControl (TCustomForm?)
  Allow := (NewTarget <> nil) or (Client is TWinControl); //seems to be safe
  if not Allow then
    exit; //all done

  if DockClientCount <= 1 then begin
    Release; //destroy empty site
  end else begin
    UpdateCaption(Client); //update caption, excluding removed client
    DockManager.ResetBounds(True); //required with gtk2!?
  end;
end;

procedure TFloatingSite.Loaded;
begin
(* select and configure the docking manager.
*)
  inherited Loaded;
  if DockManager = nil then
    DockManager := TEasyTree.Create(self);
  if DockManager is TEasyTree then begin
  //adjust as desired (order required!?)
    TEasyTree(DockManager).HideSingleCaption := True; //only show headers for multiple clients
    TEasyTree(DockManager).SetStyle(hsForm);  //show client name in the header
  end;
end;

initialization
  {$I ffloatingsite.lrs}

end.

