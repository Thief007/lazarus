unit fDockBook;
(* Notebook for docking multiple controls into a tabbed control.
  By DoDi <DrDiettrich1@aol.com> 2009.

Example of a dock site without an docking manager.
Unmanaged docking requires:
- OnGetSiteInfo handler, at least indicating acceptance
- OnDockOver handler, indicating acceptance, optionally placing the DockRect
- OnDockDrop handler, when the control is not docked as an immediate client
  of the dock site (here: dedicated panel becomes the Parent).

In this (notebook) implementation:
  The form is a dock site that manages docked clients itself.
  Controls are docked into a dedicated panel, i.e. the panel becomes their Parent.
  A tab is created for every docked control, in a dedicated toolbar.
  The tab, associated with the currently visible page, is in down state.
  A control can be undocked by dragging the associated tab.
    This makes the tabs act as grab regions for undocking e.g. forms or other
    controls, which otherwise deny undocking from their client area.
  The entire notebook can be docked from the empty part of the toolbar.
    Again for use with widgetsets and controls that do not drag properly.

TWinControls are not really draggable, unless they have parts that do not
normally react on mouse buttons (borders...). E.g. a SynEdit has to be wrapped
into a form, before it can be dragged and docked by dragging the form.

Apply ToolButtonAutoSizeAlign.patch to improve the appearance and behaviour
of the toolbar buttons. (new version will use TToggleBox)

Close docked forms on notebook destruction.
*)

(* Applications
Stand alone form (not recommended)
Parent=Nil, HostDockSite=Nil

Not-docked part of a form (Editor)
The form should never close itself.
Parent<>Nil, HostDockSite=Nil

Part of an dock tree
The form is automatically created and docked by the EasyTree.
It must notify the tree (HostDockSite) when it has 1 client left,
  for replacement by that client.
It also should notify the HostDockSite of any un/dock, to update the caption.
Parent=HostDockSite (<>Nil)

Suggested methods:
HostDockSite.ReplaceDockedControl (self by last client)
HostDockSite.UpdateDockCaption (provide composed dock caption)
*)

{$mode objfpc}{$H+}

{.$DEFINE undockFix}
{$DEFINE closeFix}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ComCtrls, ExtCtrls, StdCtrls, EasyDockSite;

type
  TTabButton = class(TToolButton)
  protected
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;

  public
    Control: TControl;
    constructor Create(TheOwner: TComponent); override;
  end;

  TTabs = class(TToolBar)
  protected
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(TheOwner: TComponent); override;
  end;

  { TEasyDockBook }

  TEasyDockBook = class(TCustomDockSite)
    pnlDock: TPanel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDockDrop(Sender: TObject; Source: TDragDockObject;
      X, Y: Integer);
    procedure FormDockOver(Sender: TObject; Source: TDragDockObject;
      X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure FormGetSiteInfo(Sender: TObject; DockClient: TControl;
      var InfluenceRect: TRect; MousePos: TPoint; var CanDock: Boolean);
    procedure FormUnDock(Sender: TObject; Client: TControl;
      NewTarget: TWinControl; var Allow: Boolean);
    procedure ToolButton1Click(Sender: TObject);
  protected
    Tabs: TTabs;
    CurTab: TTabButton;
  protected
    function GetDefaultDockCaption: string; override;
    function GetControlTab(AControl: TControl): TTabButton;
    procedure AfterUndock(tabidx: integer); virtual;
  {$IFDEF old}
    procedure LoadNames(const str: string); override;
    function  SaveNames: string; override;
  {$ELSE}
    //class function ReloadSite(AName: string; AOwner: TComponent): TCustomDockSite;
    //function  SaveSite: string; virtual;
    //procedure LoadFromStream(strm: TStream); override;
    //procedure SaveToStream(strm: TStream); override;
  {$ENDIF}
  public
  {$IFDEF undockFix}
    destructor Destroy; override;
  {$ENDIF}
  {$IFDEF closeFix}
    destructor Destroy; override;
  {$ENDIF}
  end;

//procedure Register;

implementation

uses
  fFloatingSite,
  LCLProc; //debug only

procedure Register;
begin
  //RegisterComponents('Common Controls', [TEasyDockBook]);
end;

{ TEasyDockBook }

{$IFDEF undockFix}
destructor TEasyDockBook.Destroy;
var
  i: integer;
  ctl: TControl;
begin
(* Problem with undocking?

  The DockClients are not properly undocked when we (HostDockSite) are destroyed :-(

  This code prevents an error when the DockClients are docked later,
    by definitely undocking all clients.

  But then the bug will strike back when the notebook is destroyed at the
    end of the application.
  Fix: check ctl.ComponentState for csDestroying.
*)
  for i := DockClientCount - 1 downto 0 do begin
    ctl := DockClients[i];
    if not (csDestroying in ctl.ComponentState) then
      ctl.ManualDock(nil);
    DebugLn('Undocked %s P=%p H=%p', [ctl.Name,
      pointer(ctl.Parent), pointer(ctl.HostDockSite)]);
  end;
  inherited Destroy;
end;
{$ELSE}
  //LCL updated accordingly?
{$ENDIF}

{$IFDEF closeFix}
destructor TEasyDockBook.Destroy;
var
  i: integer;
  ctl: TControl;
  frm: TCustomForm absolute ctl;
begin
(* Close docked forms, make all docked controls visible - or hidden?
*)
  for i := DockClientCount - 1 downto 0 do begin
    ctl := DockClients[i];
    if not (csDestroying in ctl.ComponentState) then begin
      ctl.Visible := True; //make hidden notebook pages visible
      if ctl is TCustomForm then
        if frm.CloseQuery then
          frm.Close
        else
          ctl.Visible := True; //make hidden notebook pages visible
    end;
  end;
  inherited Destroy;
end;
{$ELSE}
  //pure option
{$ENDIF}

procedure TEasyDockBook.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
var
  i: integer;
  ctl: TControl;
  //wc: TWinControl absolute ctl;
  frm: TCustomForm absolute ctl;
begin
(* When an empty notebook is closed, it shall be freed.
  Otherwise the clients must be handled (close forms)
*)
  DebugLn(['TEasyDockBook.FormClose ',DbgSName(Self),' ',dbgs(Pointer(Self))]);
  CloseAction := caFree;
end;

procedure TEasyDockBook.FormCreate(Sender: TObject);
begin
  Tabs := TTabs.Create(self);
  Visible := True;
end;

procedure TEasyDockBook.FormDockDrop(Sender: TObject; Source: TDragDockObject;
  X, Y: Integer);
var
  btn: TTabButton;
begin
  Source.Control.Parent := pnlDock; //overwrite DoAddDockClient behaviour

  btn := TTabButton.Create(Tabs);
  btn.Control := Source.Control;
  btn.Control.Align := alClient;
  btn.Control.DockOrientation := doPages;
  btn.Caption := GetDockCaption(btn.Control);
  btn.OnClick := @ToolButton1Click;
  btn.Down := True;
  btn.Visible := True;
  btn.Click;
end;

procedure TEasyDockBook.FormDockOver(Sender: TObject; Source: TDragDockObject;
  X, Y: Integer; State: TDragState; var Accept: Boolean);
var
  ARect: TRect;
begin
//unmanaged dock site requires an OnDockOver handler.
  Accept := True; //this is the default, can be omitted
//make DockRect reflect the docking area
  Source.DockRect := ScreenRect(pnlDock);
end;

procedure TEasyDockBook.FormGetSiteInfo(Sender: TObject; DockClient: TControl;
  var InfluenceRect: TRect; MousePos: TPoint; var CanDock: Boolean);
begin
//override TCustomForm behaviour!
  CanDock := True;
  InfluenceRect := ScreenRect(pnlDock);
end;

procedure TEasyDockBook.FormUnDock(Sender: TObject; Client: TControl;
  NewTarget: TWinControl; var Allow: Boolean);
var
  i: integer;
  btn: TTabButton;
begin
(* Client undocked, remove associated tab.
   We'll have to find the tab, associated with the control.
*)
  Allow := true;
  //assert(CurTab.Control = Client, 'diff client');
  btn := GetControlTab(Client);
  //i := CurTab.Index;
  i := btn.Index;
  if btn = CurTab then begin
    CurTab := nil;
  end else begin
    Client.Visible := True; //make hidden page control visible
  end;
  Tabs.ButtonList.Delete(i);
  Application.ReleaseComponent(btn);
//special handle remove of current and last tab
  AfterUndock(i);
end;

procedure TEasyDockBook.AfterUndock(tabidx: integer);
begin
(* A client has undocked, we have various options:
  If 1 client remains, replace ourselves by this client (if docked)
    Opt: hide Tabs.
  If 0 clients remain, free ourselves (if docked or floating)

Finally update Parent (DockCaption if docked, if destroying self)

We can be either:
  docked - HDS<>nil, HDS<>floating site
  floating - HDS=Parent=floating site (which exactly? having no kids except us?)
  child - HDS=nil, Parent<>nil.

*)
{$IFDEF new}
  //if not StayDocked and (Tabs.ButtonCount = 1) then begin
  if False then begin
  //push up last client
    if HostDockSite <> nil then begin
      CurTab := Tabs.Buttons[0] as TTabButton;
     (* Problem: a floating HostDockSite may close itself, in between.
     *)
    {$IFDEF old}
      CurTab.Control.ReplaceDockedControl(self, HostDockSite, nil, alNone);
    {$ELSE}
      CurTab.Control.ManualDock(HostDockSite, self, alLeft);
    {$ENDIF}
      Release;
    end else begin
    end;
  end else
{$ELSE}
  //above code doesn't work :-(
  //retry: explicit replace by last client, undock(?) and release
{$ENDIF}
  if Tabs.ButtonCount > 0 then begin
  //tab moved?
    if CurTab = nil then begin //current button removed
    //find next tab to show
      if tabidx >= Tabs.ButtonCount then
        tabidx := Pred(Tabs.ButtonCount);  //  dec(i);
    //activate new tab
      CurTab := Tabs.Buttons[tabidx] as TTabButton;
      CurTab.Down := True;
      CurTab.Click;
    end;
    Caption := GetDefaultDockCaption;
  end else if not StayDocked then begin
  //last tab removed - close ONLY if we are docked or floating
    if (Parent = nil) then begin
    //we are floating
      Release;
      exit;
    end else if (HostDockSite <> nil) then begin //may be cleared already???
      ManualDock(nil);  //undock before closing
      Release;
      exit;
    end;
  end;
//update the host dock site and its DockManager
  if HostDockSite <> nil then begin
    if (HostDockSite is TFloatingSite) then
      TFloatingSite(HostDockSite).UpdateCaption(nil);
    if HostDockSite.DockManager <> nil then
      HostDockSite.Invalidate;
  end else if Parent <> nil then begin
    //notify - how?
  end;
end;

function TEasyDockBook.GetControlTab(AControl: TControl): TTabButton;
var
  i: integer;
  btn: TToolButton absolute Result;
begin
  for i := 0 to Tabs.ButtonCount - 1 do begin
    btn := Tabs.Buttons[i];
    if Result.Control = AControl then
      exit;
  end;
//not found - raise exception?
  Result := nil;
end;

function TEasyDockBook.GetDefaultDockCaption: string;
var
  i: integer;
  pg: TToolButton;
begin
  Result := '';
  for i := 0 to Tabs.ButtonCount - 1 do begin
    pg := Tabs.Buttons[i];
    if Result = '' then
      Result := pg.Caption
    else
      Result := Result + ', ' + pg.Caption;
  end;
end;

{$IFDEF new}
procedure TEasyDockBook.LoadFromStream(strm: TStream);
begin
(*
*)
  inherited LoadFromStream(strm);
end;

procedure TEasyDockBook.SaveToStream(strm: TStream);
begin
(* Save docked pages, residing in?
*)
  if false then inherited SaveToStream(strm);
  ...
end;
{$ELSE}
{$ENDIF}

{$IFDEF old}
procedure TEasyDockBook.LoadNames(const str: string);
var
  lst: TStringList;
  i: integer;
  s: string;
  ctl: TControl;
begin
(* This is a suggestion for handling arguments in ReloadDockedControl.
  Skip lst[0], it contains our ClassName and (optional) Name
    ','<ClassName> ['='<Name>]
*)
  lst := TStringList.Create;
  lst.CommaText := str;
  //s := lst.Names[0];
  s := lst.ValueFromIndex[0];
  if s <> '' then
    TryRename(self, s);
  for i := i to lst.Count - 1 do begin
    s := lst.Strings[i];
    ReloadDockedControl(s, ctl); //handle everything in s!
    if ctl <> nil then begin
      //ctl.Name := s;
      ctl.ManualDock(pnlDock, nil, alCustom);
    end;
  end;
end;

function TEasyDockBook.SaveNames: string;
var
  i: integer;
  ctl: TControl;
begin
(* Entry[0] is <ClassName> ['='<Name>]
  else <Name> (with ClassName = 'T'<Name>)
*)
  //Result := '*' + Name + '=' + ClassName; //really?
  Result := ClassName + '=' + Name;
  for i := 0 to pnlDock.DockClientCount - 1 do begin
    ctl := pnlDock.DockClients[i];
    Result := Result + ',' + ctl.Name;
  end;
end;
{$ELSE}
{$ENDIF}

procedure TEasyDockBook.ToolButton1Click(Sender: TObject);
var
  btn: TTabButton absolute Sender;
begin
  if CurTab <> nil then begin
    CurTab.Control.Visible := false;
  end;
  if btn.Control <> nil then
    btn.Control.Visible := True;
  CurTab := btn;
end;

{ TTabButton }

constructor TTabButton.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
//these properties must be set before Parent
  Style := tbsCheck; //allow button to stay down
  AutoSize := True; //depending on the Caption text width
  Parent := TWinControl(TheOwner); //seems to be required
//these properties must be set after Parent
  Grouped := True;
end;

procedure TTabButton.MouseMove(Shift: TShiftState; X, Y: Integer);
//var AControl: TControl;
begin
(* Implement dragging of the associated page.
*)
  inherited MouseMove(Shift, X, Y);
  if (ssLeft in Shift) and not DragManager.IsDragging then begin
    if Control <> nil then begin
{ Problems with TWinControls - must be wrapped into forms :-(
      //DebugLn('---undock "', Control.GetDefaultDockCaption, '"');
      DebugLn('---undock "', Control.ClassName, '"');
      if False and (Control is TWinControl) then begin
        AControl := Control; //will change when undocked?
        AControl.ManualDock(nil);
        if AControl.HostDockSite <> nil then
          AControl.HostDockSite.BeginDrag(True);
      end else
}
//both immediate and delayed drag start seem to work
        //Control.BeginDrag(False); //delayed docking
        Control.BeginDrag(True); //immediate drag
    end;
  end;
end;

{ TTabs }

constructor TTabs.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Align := alTop;
  AutoSize := True;
  Color := clBtnFace;
  Flat := False;
  Height := 28; //?
  List := True;
  ParentColor := False;
  ParentFont := False; //which one?
  Font.Style := [fsBold];
  ShowCaptions := True;
  Wrapable := True;
  Visible := True;
  Parent := TWinControl(TheOwner);
end;

procedure TTabs.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
(* Implement dragging of the entire notebook.
  Parent is assumed to be the notebook form.
  Try prevent undocking of NOT docked form.
*)
  inherited MouseMove(Shift, X, Y);
  //if ssLeft in Shift then
  if (ssLeft in Shift) and (Parent.HostDockSite <> nil) then
    Parent.BeginDrag(False); //delayed docking of the container form
end;

initialization
  {$I fdockbook.lrs}
  RegisterClass(TEasyDockBook);
end.


