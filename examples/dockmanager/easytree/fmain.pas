unit fMain;
(* EasyDockSite dock test form by DoDi.
  Demonstrates docking of various controls, and related bugs in the LCL.
*)

(* A dock site should contain no other (not docked) controls.
  Delphi docks all controls in a dock site, when a docking manager is assigned.
  This does not (yet) work with the LCL :-(
  When a docking manager is replaced, the controls should be undocked again?
  (depends on the lists, where docked and undocked controls reside in the dock site)

  LCL does not notify the docking manager of a resized dock site?
*)

//some defines, to demonstrate LCL flaws
{$DEFINE Docker}    //using control (undef: entire form) as dock site
{$DEFINE easy}      //using EasyDockSite (undef: default LDockTree)
{.$DEFINE dragForm}  //create a form from the draggable images (or drag images)
  //dragging forms is not supported on all platforms!


interface

uses
  LCLIntf,
  SysUtils, Classes, Graphics, Controls, Forms,
{$IFDEF easy}
  //use EasyDockSite
{$ELSE}
  LDockTree,
{$ENDIF}
  Dialogs, StdCtrls, ComCtrls, Menus, ExtCtrls, LResources;

type

  { TEasyDockMain }

  TEasyDockMain = class(TForm)
    pnlDocker: TPanel;
    edDock: TEdit;
    lbDock: TLabel;
    sb: TStatusBar;
    ToolBar1: TToolBar;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    buDump: TButton;
    procedure DockerUnDock(Sender: TObject; Client: TControl;
      NewTarget: TWinControl; var Allow: Boolean);
    procedure Shape1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure DockerDockDrop(Sender: TObject; Source: TDragDockObject; X,
      Y: Integer);
    procedure DockerMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure DockerDockOver(Sender: TObject; Source: TDragDockObject; X,
      Y: Integer; State: TDragState; var Accept: Boolean);
    procedure buDumpClick(Sender: TObject);
  private
  {$IFDEF docker}
    //Docker: TPanel;
  {$ELSE}
    //Docker: TForm;
  {$ENDIF}
    Docker: TWinControl;
    ShapeCount: integer;
  public
    { Public declarations }
  end;

var
  EasyDockMain: TEasyDockMain;

implementation

uses
  fDockable,
{$IFDEF easy}
  EasyDockSite,
{$ELSE}
{$ENDIF}
  LCLProc,
  Interfacebase,
  fTree;


procedure TEasyDockMain.Shape1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  df: TDockable;
  shp: TShape;
  c: TColor;
  ctl: TShape;
  r: TRect;
begin
  if sender is TShape then begin
    shp := Sender as TShape;
  {$IFDEF dragForm}
    df := TDockable.Create(self);
    sb.SimpleText := df.Name;
    c := shp.Brush.Color;
    //df.Color := c; - not all widgetsets support TForm.Color!?
    //c := df.Color;
    df.Shape1.Brush.Color := c;

  { TODO -cdocking : form is not dockable with some widgetsets? }
  // all this doesn't help
    df.DragKind := dkDock;
    df.DragMode := dmAutomatic;
    //df.ManualFloat(df.BoundsRect);

    df.Visible := True;

    if WidgetSet.GetLCLCapability(lcDragDockStartOnTitleClick) <> 0 then begin
      sb.SimpleText := 'should dock'
    end else begin
      sb.SimpleText := 'cannot dock'
    end;
  {$ELSE}
    ctl := TShape.Create(self);
    //ctl.Assign(shp);
    ctl.Name := 'test' + IntToStr(ShapeCount);
    inc(ShapeCount);
    ctl.Brush.Color := shp.Brush.Color;
    ctl.DragMode := dmAutomatic;
    ctl.DragKind := dkDock;
    r.TopLeft := self.BoundsRect.TopLeft;
    //r.Left := x; r.Top := y;
    r.Right := r.Left + 100;
    r.Bottom := r.Top + 100;
    ctl.ManualFloat(r); //(ctl.BoundsRect);
  {$ENDIF}
    //df.Name := shp.Name;
  end;
end;

procedure TEasyDockMain.FormCreate(Sender: TObject);
begin
{$IFDEF docker}
  pnlDocker.Visible := True;
  Docker := pnlDocker;
{$ELSE}
  pnlDocker.Visible := False;
  Docker := self;
{$ENDIF}
{$IFDEF easy}
  Docker.DockManager := TEasyTree.Create(Docker);
{$ELSE}
  //use default dockmanager
{$ENDIF}
  Docker.DockSite := True;
  Docker.UseDockManager := True;
  Docker.OnDockOver:=@self.DockerDockOver;
  Docker.OnDockDrop := @self.DockerDockDrop;
  Mouse.DragImmediate := False; //appropriate at least for docking
end;

procedure TEasyDockMain.DockerDockDrop(Sender: TObject;
  Source: TDragDockObject; X, Y: Integer);
begin
  sb.SimpleText := 'drop!';
end;

procedure TEasyDockMain.DockerMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  //sb.SimpleText := 'move';
  //Docker.DockManager.
end;

procedure TEasyDockMain.DockerUnDock(Sender: TObject; Client: TControl;
  NewTarget: TWinControl; var Allow: Boolean);
var
  s, n: string;
  r: TRect;
begin
(* problem: DockObj seems to be invalid - here? how?
*)
{ debug only - problem with exception handling!
  DebugLn('--- UnDock ---');
  try
    if DockObj <> nil then begin
      r := DockObj.DockRect;
      if DockObj.DropOnControl = nil then
        n := '<none>'
      else
        n := '...'; // DockObj.DropOnControl.Name;
      s := Format('drop onto %s[%d,%d - %d,%d] %s', [
        n, r.Top, r.Left, r.Bottom, r.Right, AlignNames[DockObj.DropAlign]]);
      sb.SimpleText := s;
      if DockObj.DropOnControl = DockObj.Control then begin
        sb.SimpleText := 'NO undock to self';
        Allow := False;
      end;
    end;
  except
    sb.SimpleText := '<invalid undock obj>';
  end;
}
end;

procedure TEasyDockMain.DockerDockOver(Sender: TObject;
  Source: TDragDockObject; X, Y: Integer; State: TDragState;
  var Accept: Boolean);
var
  s: string;
  DropOn: TControl;
  r: TRect;
begin
{$IFDEF easy}
  //if DropOn = nil then
  if Source.DragTarget = nil then
    sb.SimpleText := '<drop nowhere>'
  else begin
    DropOn := Source.DragTarget;
    r := Source.DockRect;
    s := Format('drop onto %s[%d,%d - %d,%d] %s', [
      DropOn.Name, r.Top, r.Left, r.Bottom, r.Right, AlignNames[Source.DropAlign]]);
    sb.SimpleText := s;
  end;
{$ELSE}
{$ENDIF}
{ we cannot prevent undocking right now :-(
  if Source.DropOnControl = Source.Control then
    Accept := False;
}
end;

procedure TEasyDockMain.buDumpClick(Sender: TObject);
var
  s: TStringStream;
begin
  s := TStringStream.Create('');
  try
    Docker.DockManager.SaveToStream(s);
    DumpBox.Memo1.Text := s.DataString;
  finally
    s.Free;
  end;
  DumpBox.Visible := True;
  sb.SimpleText := lbDock.Name;
end;

initialization
  {$i fMain.lrs}
end.

