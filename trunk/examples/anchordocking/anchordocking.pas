{ Unit implementing anchor docking.

  Copyright (C) 2010 Mattias Gaertner mattias@freepascal.org

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

  Features:
    - dnd docking
    - preview rectangle while drag over
    - inside and outside docking
    - header with close button and hints
    - using stock item for close button glyph
    - auto header caption from content
    - hide header caption for floating form
    - auto site for headers to safe space (configurable)
    - bidimode for headers
    - page docking
    - pagecontrols uses TPageControl for native look&feel
    - page control is automatically removed if only one page left
    - scaling on resize (configurable)
    - auto insert splitters between controls (size configurable)
    - keep size when docking
    - header is automatically hidden when docked into page
    - save complete layout
    - restore layout:
       - close unneeded windows,
       - automatic clean up if windows are missing,
       - reusing existing docksites to minimize flickering
    - popup menu
       - close site
       - lock/unlock
       - header auto, left, top, right, bottom
       - undock (needed if no place to undock on screen)
       - merge (for example after moving a dock page into a layout)

  ToDo:
    - popup menu
       - enlarge side to left, top, right, bottom
       - shrink side left, top, right, bottom
       - options
       - close (for pages)
       - tab position (default, left, top, right, bottom)
    - fpdoc
    - examples on wiki:
        screenshots
        example how to dock in code
        step by step how to use it in applications
    - simple way to make forms dockable at designtime
    - move page index
    - move page to another pagecontrol
    - minimize button and Hide => show in header
    - on close button: save a default layout
    - on show again: restore a default layout
    - close button for pages
    - design time package for IDE
}

unit AnchorDocking;

{$mode objfpc}{$H+}

interface

uses
  Math, Classes, SysUtils, LResources, types, LCLType, LCLIntf, LCLProc,
  Controls, Forms, ExtCtrls, ComCtrls, Graphics, Themes, Menus, Buttons,
  LazConfigStorage, AnchorDockStr, AnchorDockStorage;

type
  TAnchorDockHostSite = class;

  { TAnchorDockCloseButton }

  TAnchorDockCloseButton = class(TSpeedButton)
  protected
    procedure GetCloseGlyph;
    procedure ReleaseCloseGlyph;
    function GetGlyphSize(PaintRect: TRect): TSize; override;
    function DrawGlyph(ACanvas: TCanvas; const AClient: TRect;
            const AOffset: TPoint; AState: TButtonState; ATransparent: Boolean;
            BiDiFlags: Longint): TRect; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TAnchorDockHeader }

  TAnchorDockHeader = class(TCustomPanel)
  private
    FCloseButton: TSpeedButton;
    FHeaderPosition: TADLHeaderPosition;
    procedure CloseButtonClick(Sender: TObject);
    procedure ChangeLockButtonClick(Sender: TObject);
    procedure HeaderPositionItemClick(Sender: TObject);
    procedure UndockButtonClick(Sender: TObject);
    procedure MergeButtonClick(Sender: TObject);
    procedure SetHeaderPosition(const AValue: TADLHeaderPosition);
  protected
    procedure Paint; override;
    procedure CalculatePreferredSize(var PreferredWidth,
          PreferredHeight: integer; WithThemeSpace: Boolean); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,
             Y: Integer); override;
    procedure UpdateHeaderControls;
    procedure SetAlign(Value: TAlign); override;
    procedure DoOnShowHint(HintInfo: PHintInfo); override;
    procedure PopupMenuPopup(Sender: TObject); virtual;
    function AddPopupMenuItem(AName, ACaption: string;
                    const OnClickEvent: TNotifyEvent; AParent: TMenuItem = nil): TMenuItem;
  public
    constructor Create(TheOwner: TComponent); override;
    property CloseButton: TSpeedButton read FCloseButton;
    property HeaderPosition: TADLHeaderPosition read FHeaderPosition write SetHeaderPosition;
  end;

  { TAnchorDockSplitter }

  TAnchorDockSplitter = class(TCustomSplitter)
  private
    FDockBounds: TRect;
    FDockParentClientSize: TSize;
  protected
    procedure SetResizeAnchor(const AValue: TAnchorKind); override;
  public
    constructor Create(TheOwner: TComponent); override;
    property DockBounds: TRect read FDockBounds write FDockBounds;
    property DockParentClientSize: TSize read FDockParentClientSize write FDockParentClientSize;
    procedure UpdateDockBounds;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
    procedure SetBoundsKeepDockBounds(ALeft, ATop, AWidth, AHeight: integer);
    function SideAnchoredControlCount(Side: TAnchorKind): integer;
    procedure SaveLayout(LayoutNode: TAnchorDockLayoutTreeNode);
    function HasOnlyOneSibling(Side: TAnchorKind; MinPos, MaxPos: integer): TControl;
  end;

  { TAnchorDockPage }

  TAnchorDockPage = class(TCustomPage)
  public
    procedure UpdateDockCaption(Exclude: TControl = nil); override;
    procedure InsertControl(AControl: TControl; Index: integer); override;
    procedure RemoveControl(AControl: TControl); override;
    function GetSite: TAnchorDockHostSite;
  end;

  { TAnchorDockPageControl }

  TAnchorDockPageControl = class(TCustomNotebook)
  private
    function GetDockPages(Index: integer): TAnchorDockPage;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
  public
    constructor Create(TheOwner: TComponent); override;
    procedure UpdateDockCaption(Exclude: TControl = nil); override;
    property DockPages[Index: integer]: TAnchorDockPage read GetDockPages;
    procedure RemoveControl(AControl: TControl); override;
  end;

  { TAnchorDockHostSite
    This form is the dockhostsite for all controls.
    When docked together they build a tree structure with the docked controls
    as leaf nodes.
    A TAnchorDockHostSite has three forms:
    }

  TAnchorDockHostSiteType = (
    adhstNone,  // fresh created, no control docked
    adhstOneControl, // a control and a TAnchorDockHeader
    adhstLayout, // several controls/TAnchorDockHostSite separated by TAnchorDockSplitters
    adhstPages  // several controls/TAnchorDockHostSite in a TPageControl
    );

  TAnchorDockHostSite = class(TCustomForm)
  private
    FHeader: TAnchorDockHeader;
    FHeaderSide: TAnchorKind;
    FPages: TAnchorDockPageControl;
    FSiteType: TAnchorDockHostSiteType;
    fUpdateLayout: integer;
    procedure SetHeaderSide(const AValue: TAnchorKind);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation);
                           override;
    function DoDockClientMsg(DragDockObject: TDragDockObject;
                             aPosition: TPoint): boolean; override;
    function DockFirstControl(DragDockObject: TDragDockObject): boolean; virtual;
    function DockSecondControl(NewControl: TControl; DockAlign: TAlign;
                               Inside: boolean): boolean; virtual;
    function DockAnotherControl(Sibling, NewControl: TControl; DockAlign: TAlign;
                                Inside: boolean): boolean; virtual;
    procedure CreatePages; virtual;
    function DockSecondPage(NewControl: TControl): boolean; virtual;
    function DockAnotherPage(NewControl: TControl): boolean; virtual;
    procedure AddCleanControl(AControl: TControl; TheAlign: TAlign = alNone);
    procedure RemoveControlFromLayout(AControl: TControl);
    procedure RemoveSpiralSplitter(AControl: TControl);
    procedure Simplify;
    procedure SimplifyPages;
    procedure SimplifyOneControl;
    function GetOneControl: TControl;
    function GetSiteCount: integer;
    function IsOneSiteLayout(out Site: TAnchorDockHostSite): boolean;
    function IsTwoSiteLayout(out Site1, Site2: TAnchorDockHostSite): boolean;
    function GetUniqueSplitterName: string;
    function GetSite(AControl: TControl): TAnchorDockHostSite;
    procedure MoveAllControls(dx, dy: integer);
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure DoDock(NewDockSite: TWinControl; var ARect: TRect); override;
    procedure SetParent(NewParent: TWinControl); override;
    function HeaderNeedsShowing: boolean;
    procedure DoClose(var CloseAction: TCloseAction); override;
    procedure Undock;
    function CanMerge: boolean;
    procedure Merge;
    function EnlargeSide(Side: TAnchorKind;
                         OnlyCheckIfPossible: boolean): boolean;
    function EnlargeSideResizeTwoSplitters(Side, SideEnlarge: TAnchorKind;
                         OnlyCheckIfPossible: boolean): boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CloseQuery: boolean; override;
    function CloseSite: boolean; virtual;
    procedure RemoveControl(AControl: TControl); override;
    procedure InsertControl(AControl: TControl; Index: integer); override;
    procedure GetSiteInfo(Client: TControl; var InfluenceRect: TRect;
                          MousePos: TPoint; var CanDock: Boolean); override;
    function GetPageArea: TRect;
    procedure ChangeBounds(ALeft, ATop, AWidth, AHeight: integer;
                           KeepBase: boolean); override;
    procedure UpdateDockCaption(Exclude: TControl = nil); override;
    procedure UpdateHeaderAlign;
    procedure UpdateHeaderShowing;
    procedure BeginUpdateLayout;
    procedure EndUpdateLayout;
    function UpdatingLayout: boolean;

    // save/restore layout
    procedure SaveLayout(LayoutTree: TAnchorDockLayoutTree;
                         LayoutNode: TAnchorDockLayoutTreeNode);

    property HeaderSide: TAnchorKind read FHeaderSide write SetHeaderSide;
    property Header: TAnchorDockHeader read FHeader;
    property Pages: TAnchorDockPageControl read FPages;
    property SiteType: TAnchorDockHostSiteType read FSiteType;
  end;

  { TAnchorDockManager }

  TAnchorDockManager = class(TDockManager)
  private
    FDockSite: TAnchorDockHostSite;
  public
    constructor Create(ADockSite: TWinControl); override;
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    procedure GetControlBounds(Control: TControl; out AControlBounds: TRect);
      override;
    procedure InsertControl(Control: TControl; InsertAt: TAlign;
      DropCtl: TControl); override; overload;
    procedure LoadFromStream(Stream: TStream); override;
    procedure PositionDockRect(Client, DropCtl: TControl; DropAlign: TAlign;
      var DockRect: TRect); override; overload;
    procedure RemoveControl(Control: TControl); override;
    procedure ResetBounds(Force: Boolean); override;
    procedure SaveToStream(Stream: TStream); override;
    function GetDockEdge(ADockObject: TDragDockObject): boolean; override;
    property DockSite: TAnchorDockHostSite read FDockSite;
  end;

  { TAnchorDockMaster }

  TADCreateControlEvent = procedure(Sender: TObject; aName: string;
                var AControl: TControl; DoDisableAutoSizing: boolean) of object;

  TAnchorDockMaster = class(TComponent)
  private
    FAllowDragging: boolean;
    FControls: TFPList;
    FDockOutsideMargin: integer;
    FDockParentMargin: integer;
    FDragTreshold: integer;
    FHeaderAlignLeft: integer;
    FHeaderAlignTop: integer;
    FHeaderHint: string;
    FOnCreateControl: TADCreateControlEvent;
    FPageAreaInPercent: integer;
    FScaleOnResize: boolean;
    FShowHeaderCaptionFloatingControl: boolean;
    FSplitterWidth: integer;
    fNeedSimplify: TFPList; // list of TControl
    fNeedFree: TFPList; // list of TControl
    fSimplifying: boolean;
    fUpdateCount: integer;
    fDisabledAutosizing: TFPList; // list of TControl
    function GetControls(Index: integer): TControl;
    procedure SetHeaderAlignLeft(const AValue: integer);
    procedure SetHeaderAlignTop(const AValue: integer);
    function CloseUnneededControls(Tree: TAnchorDockLayoutTree): boolean;
    function CreateNeededControls(Tree: TAnchorDockLayoutTree;
                DisableAutoSizing: boolean; ControlNames: TStrings): boolean;
    procedure MapTreeToControls(Tree: TAnchorDockLayoutTree;
                                TreeNameToDocker: TADNameToControl);
    function RestoreLayout(Tree: TAnchorDockLayoutTree;
                           TreeNameToDocker: TADNameToControl): boolean;
    function DoCreateControl(aName: string; DisableAutoSizing: boolean): TControl;
    procedure EnableAllAutoSizing;
    procedure ClearLayoutProperties(AControl: TControl);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation);
          override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ControlCount: integer;
    property Controls[Index: integer]: TControl read GetControls;
    function IndexOfControl(const aName: string): integer;
    function FindControl(const aName: string): TControl;

    // show / make a control dockable
    procedure MakeDockable(AControl: TControl; Show: boolean = true;
                           BringToFront: boolean = false;
                           AddDockHeader: boolean = true);
    function ShowControl(ControlName: string; BringToFront: boolean = false
                         ): TControl;

    // save/restore layouts
    procedure SaveMainLayoutToTree(LayoutTree: TAnchorDockLayoutTree);
    procedure SaveLayoutToConfig(Config: TConfigStorage);
    function LoadLayoutFromConfig(Config: TConfigStorage): boolean;

    // simplification/garbage collection
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure NeedSimplify(AControl: TControl);
    procedure NeedFree(AControl: TControl);
    procedure SimplifyPendingLayouts;
    function AutoFreedIfControlIsRemoved(AControl, RemovedControl: TControl): boolean;
    function CreateSite(NamePrefix: string = '';
                        DisableAutoSizing: boolean = true): TAnchorDockHostSite;
    function CreateSplitter(NamePrefix: string = ''): TAnchorDockSplitter;

    // options
    property DragTreshold: integer read FDragTreshold write FDragTreshold default 4;
    property DockOutsideMargin: integer read FDockOutsideMargin write FDockOutsideMargin default 10; // max distance for outside mouse snapping
    property DockParentMargin: integer read FDockParentMargin write FDockParentMargin default 10; // max distance for snap to parent
    property PageAreaInPercent: integer read FPageAreaInPercent write FPageAreaInPercent default 40; // size of inner mosue snapping area for page docking
    property HeaderAlignTop: integer read FHeaderAlignTop write SetHeaderAlignTop default 80; // move header to top, when (width/height)*100<=HeaderAlignTop
    property HeaderAlignLeft: integer read FHeaderAlignLeft write SetHeaderAlignLeft default 120; // move header to left, when (width/height)*100>=HeaderAlignLeft
    property HeaderHint: string read FHeaderHint write FHeaderHint;
    property SplitterWidth: integer read FSplitterWidth write FSplitterWidth default 4;
    property ScaleOnResize: boolean read FScaleOnResize write FScaleOnResize default true; // scale children when resizing a site
    property ShowHeaderCaptionFloatingControl: boolean read FShowHeaderCaptionFloatingControl
                          write FShowHeaderCaptionFloatingControl default false;
    property OnCreateControl: TADCreateControlEvent read FOnCreateControl write FOnCreateControl;
    property AllowDragging: boolean read FAllowDragging write FAllowDragging default true;
  end;

var
  DockMaster: TAnchorDockMaster = nil;

function dbgs(SiteType: TAnchorDockHostSiteType): string; overload;

procedure CopyAnchorBounds(Source, Target: TControl);
function ControlsLeftTopOnScreen(AControl: TControl): TPoint;

implementation

var
  CloseBtnReferenceCount: integer = 0;
  CloseBtnBitmap: TBitmap = nil;

function dbgs(SiteType: TAnchorDockHostSiteType): string; overload;
begin
  case SiteType of
  adhstNone: Result:='None';
  adhstOneControl: Result:='OneControl';
  adhstLayout: Result:='Layout';
  adhstPages: Result:='Pages';
  else Result:='?';
  end;
end;

procedure CopyAnchorBounds(Source, Target: TControl);
var
  a: TAnchorKind;
begin
  Target.DisableAutoSizing;
  Target.BoundsRect:=Source.BoundsRect;
  Target.Anchors:=Source.Anchors;
  Target.Align:=Source.Align;
  for a:=low(TAnchorKind) to high(TAnchorKind) do
    Target.AnchorSide[a].Assign(Source.AnchorSide[a]);
  Target.EnableAutoSizing;
end;

function ControlsLeftTopOnScreen(AControl: TControl): TPoint;
begin
  if AControl.Parent<>nil then begin
    Result:=AControl.Parent.ClientOrigin;
    inc(Result.X,AControl.Left);
    inc(Result.Y,AControl.Top);
  end else begin
    Result:=AControl.Parent.ClientOrigin;
  end;
end;

{ TAnchorDockMaster }

function TAnchorDockMaster.GetControls(Index: integer): TControl;
begin
  Result:=TControl(FControls[Index]);
end;

procedure TAnchorDockMaster.SetHeaderAlignLeft(const AValue: integer);
begin
  if FHeaderAlignLeft=AValue then exit;
  FHeaderAlignLeft:=AValue;
  FHeaderAlignTop:=Max(FHeaderAlignLeft+1,FHeaderAlignTop);
end;

procedure TAnchorDockMaster.SetHeaderAlignTop(const AValue: integer);
begin
  if FHeaderAlignTop=AValue then exit;
  FHeaderAlignTop:=AValue;
  FHeaderAlignLeft:=Min(FHeaderAlignTop-1,FHeaderAlignLeft);
end;

function TAnchorDockMaster.CloseUnneededControls(Tree: TAnchorDockLayoutTree
  ): Boolean;
var
  i: Integer;
  AControl: TControl;
begin
  i:=ControlCount-1;
  while i>=0 do begin
    AControl:=Controls[i];
    if (AControl.HostDockSite is TAnchorDockHostSite)
    and GetParentForm(AControl).IsVisible
    and (Tree.Root.FindChildNode(AControl.Name,true)=nil) then begin
      // AControl is currently on a visible site, but not in the Tree
      // => close site
      debugln(['TAnchorDockMaster.CloseUnneededControls Control=',DbgSName(AControl),' Site=',AControl.HostDockSite.Name]);
      if not TAnchorDockHostSite(AControl.HostDockSite).CloseSite then
        exit(false);
    end;
    i:=Min(i,ControlCount)-1;
  end;
  Result:=true;
end;

function TAnchorDockMaster.CreateNeededControls(Tree: TAnchorDockLayoutTree;
  DisableAutoSizing: boolean; ControlNames: TStrings): boolean;

  procedure CreateControlsForNode(Node: TAnchorDockLayoutTreeNode);
  var
    i: Integer;
    AControl: TControl;
  begin
    if (Node.NodeType=adltnControl) and (Node.Name<>'') then begin
      AControl:=FindControl(Node.Name);
      if AControl<>nil then begin
        debugln(['CreateControlsForNode ',Node.Name,' already exists']);
        if DisableAutoSizing and (fDisabledAutosizing.IndexOf(AControl)<0) then
        begin
          AControl.DisableAutoSizing;
          fDisabledAutosizing.Add(AControl);
        end;
      end else begin
        debugln(['CreateControlsForNode ',Node.Name,' needs creation']);
        AControl:=DoCreateControl(Node.Name,DisableAutoSizing);
        if AControl<>nil then begin
          debugln(['CreateControlsForNode ',AControl.Name,' created']);
          if fDisabledAutosizing.IndexOf(AControl)>=0 then
            RaiseGDBException(''); // should never happen
          fDisabledAutosizing.Add(AControl);
          MakeDockable(AControl,false);
        end else begin
          debugln(['CreateControlsForNode ',Node.Name,' failed to create']);
        end;
      end;
      if AControl<>nil then
        ControlNames.Add(AControl.Name);
    end;
    for i:=0 to Node.Count-1 do
      CreateControlsForNode(Node[i]);
  end;

begin
  Result:=false;
  CreateControlsForNode(Tree.Root);
  Result:=true;
end;

procedure TAnchorDockMaster.MapTreeToControls(Tree: TAnchorDockLayoutTree;
  TreeNameToDocker: TADNameToControl);

  procedure MapHostDockSites(Node: TAnchorDockLayoutTreeNode);
  // map in TreeNameToDocker each control name to its HostDockSite
  var
    i: Integer;
    AControl: TControl;
  begin
    if Node.IsSplitter then exit;
    if (Node.NodeType=adltnControl) then begin
      AControl:=FindControl(Node.Name);
      if (AControl<>nil) and (AControl.HostDockSite is TAnchorDockHostSite) then
        TreeNameToDocker[Node.Name]:=AControl.HostDockSite;
    end else
      for i:=0 to Node.Count-1 do
        MapHostDockSites(Node[i]); // recursive
  end;

  procedure MapTopLevelSites(Node: TAnchorDockLayoutTreeNode);
  // map in TreeNameToDocker each RootWindow node name to a site whith a
  // corresponding control
  // For example: if there is control on a complex site (SiteA), and the control
  //    has a node in the Tree, then the root node of the tree node is mapped to
  //    the SiteA. This way the corresponding root forms are kept which reduces
  //    flickering.

    function FindMappedControl(ChildNode: TAnchorDockLayoutTreeNode
      ): TAnchorDockHostSite;
    var
      i: Integer;
    begin
      if ChildNode.NodeType=adltnControl then
        Result:=TAnchorDockHostSite(TreeNameToDocker[ChildNode.Name])
      else
        for i:=0 to ChildNode.Count-1 do begin
          Result:=FindMappedControl(ChildNode[i]); // search recursive
          if Result<>nil then exit;
        end;
    end;

  var
    i: Integer;
    RootSite: TCustomForm;
    Site: TAnchorDockHostSite;
  begin
    if Node.IsSplitter then exit;
    if Node.IsRootWindow then begin
      if Node.Name='' then exit;
      if Node.NodeType=adltnControl then exit;
      // not is a complex site
      if TreeNameToDocker[Node.Name]<>nil then exit;
      // and not yet mapped to a site
      Site:=FindMappedControl(Node);
      if Site=nil then exit;
      // and there is sub node mapped to a site
      RootSite:=GetParentForm(Site);
      if not (RootSite is TAnchorDockHostSite) then exit;
      // and the mapped site has a root site
      if TreeNameToDocker.ControlToName(RootSite)<>'' then exit;
      // and the root site is not yet mapped
      // => map the root node to the root site
      TreeNameToDocker[Node.Name]:=RootSite;
    end else
      for i:=0 to Node.Count-1 do
        MapTopLevelSites(Node[i]); // recursive
  end;

  procedure MapBottomUp(Node: TAnchorDockLayoutTreeNode);
  { map the other nodes to existing sites
    The heuristic works like this:
      if a child node was mapped to a site and the site has a parent site then
      map this node to this parent site.
  }
  var
    i: Integer;
    BestSite: TControl;
  begin
    if Node.IsSplitter then exit;
    BestSite:=TreeNameToDocker[Node.Name];
    for i:=0 to Node.Count-1 do begin
      MapBottomUp(Node[i]); // recursive
      if BestSite=nil then
        BestSite:=TreeNameToDocker[Node[i].Name];
    end;
    if (TreeNameToDocker[Node.Name]=nil) and (BestSite<>nil) then begin
      // search the parent site of a child site
      repeat
        BestSite:=BestSite.Parent;
        if BestSite is TAnchorDockHostSite then begin
          if TreeNameToDocker.ControlToName(BestSite)='' then
            TreeNameToDocker[Node.Name]:=BestSite;
          break;
        end;
      until (BestSite=nil);
    end;
  end;

  procedure MapSplitters(Node: TAnchorDockLayoutTreeNode);
  { map the splitter nodes to existing splitters
    The heuristic works like this:
      If a node is mapped to a site and the node is at Side anchored to a
      splitter node and the site is anchored at Side to a splitter then
      map the the splitter node to the splitter.
  }
  var
    i: Integer;
    Side: TAnchorKind;
    Site: TControl;
    SplitterNode: TAnchorDockLayoutTreeNode;
    Splitter: TControl;
  begin
    if Node.IsSplitter then exit;
    for i:=0 to Node.Count-1 do
      MapSplitters(Node[i]); // recursive

    if Node.Parent=nil then exit;
    // node is a child node
    Site:=TreeNameToDocker[Node.Name];
    if Site=nil then exit;
    // node is mapped to a site
    // check each side
    for Side:=Low(TAnchorKind) to high(TAnchorKind) do begin
      if Node.Anchors[Side]='' then continue;
      SplitterNode:=Node.Parent.FindChildNode(Node.Anchors[Side],false);
      if (SplitterNode=nil) then continue;
      // this side of node is anchored to a splitter node
      if TreeNameToDocker[SplitterNode.Name]<>nil then continue;
      // the splitter node is not yet mapped
      Splitter:=Site.AnchorSide[Side].Control;
      if (not (Splitter is TAnchorDockSplitter))
      or (Splitter.Parent<>Site.Parent) then continue;
      // there is an unmapped splitter anchored to the Site
      // => map the splitter to the splitter node
      TreeNameToDocker[Splitter.Name]:=Splitter;
    end;
  end;

begin
  MapHostDockSites(Tree.Root);
  MapTopLevelSites(Tree.Root);
  MapBottomUp(Tree.Root);
  MapSplitters(Tree.Root);
end;

function TAnchorDockMaster.RestoreLayout(Tree: TAnchorDockLayoutTree;
  TreeNameToDocker: TADNameToControl): boolean;

  procedure SetupSite(Site: TAnchorDockHostSite;
    Node: TAnchorDockLayoutTreeNode; Parent: TWinControl);
  begin
    Site.BoundsRect:=Node.BoundsRect;
    Site.Visible:=true;
    Site.Parent:=Parent;
    Site.Header.HeaderPosition:=Node.HeaderPosition;
    if Parent=nil then begin
      Site.WindowState:=Node.WindowState;
      if (Node.Monitor>=0) and (Node.Monitor<Screen.MonitorCount) then
      begin
        // ToDo: move to monitor
      end;
    end;
  end;

  function Restore(Node: TAnchorDockLayoutTreeNode; Parent: TWinControl): TControl;
  var
    AControl: TControl;
    Site: TAnchorDockHostSite;
    Splitter: TAnchorDockSplitter;
    i: Integer;
    Side: TAnchorKind;
    AnchorControl: TControl;
    ChildNode: TAnchorDockLayoutTreeNode;
  begin
    Result:=nil;
    debugln(['Restore ',Node.Name,' ',dbgs(Node.NodeType),' Bounds=',dbgs(Node.BoundsRect),' Parent=',DbgSName(Parent),' ']);
    if Node.NodeType=adltnControl then begin
      // restore control
      // the control was already created
      // => dock it
      AControl:=FindControl(Node.Name);
      if AControl=nil then begin
        debugln(['TAnchorDockMaster.RestoreLayout.Restore can not find control ',Node.Name]);
        exit;
      end;
      if AControl.HostDockSite=nil then
        MakeDockable(AControl,false)
      else
        ClearLayoutProperties(AControl);
      Site:=AControl.HostDockSite as TAnchorDockHostSite;
      debugln(['Restore Control Node.Name=',Node.Name,' Control=',DbgSName(AControl),' Site=',DbgSName(Site)]);
      AControl.Visible:=true;
      SetupSite(Site,Node,Parent);
      Result:=Site;
    end else if Node.IsSplitter then begin
      // restore splitter
      Splitter:=TAnchorDockSplitter(TreeNameToDocker[Node.Name]);
      if Splitter=nil then begin
        Splitter:=CreateSplitter;
        TreeNameToDocker[Node.Name]:=Splitter;
      end;
      debugln(['Restore Splitter Node.Name=',Node.Name,' ',dbgs(Node.NodeType),' Splitter=',DbgSName(Splitter)]);
      Splitter.Parent:=Parent;
      Splitter.BoundsRect:=Node.BoundsRect;
      if Node.NodeType=adltnSplitterVertical then
        Splitter.ResizeAnchor:=akLeft
      else
        Splitter.ResizeAnchor:=akTop;
      Result:=Splitter;
    end else if Node.NodeType=adltnLayout then begin
      // restore layout
      Site:=TAnchorDockHostSite(TreeNameToDocker[Node.Name]);
      if Site=nil then begin
        Site:=CreateSite('',true);
        fDisabledAutosizing.Add(Site);
        TreeNameToDocker[Node.Name]:=Site;
      end;
      debugln(['Restore Layout Node.Name=',Node.Name,' ChildCount=',Node.Count]);
      Site.BeginUpdateLayout;
      try
        SetupSite(Site,Node,Parent);
        Site.FSiteType:=adhstLayout;
        Site.Header.Parent:=nil;
        // create children
        for i:=0 to Node.Count-1 do
          Restore(Node[i],Site);
        // anchor children
        for i:=0 to Node.Count-1 do begin
          ChildNode:=Node[i];
          AControl:=TreeNameToDocker[ChildNode.Name];
          debugln(['  Restore layout child anchors Site=',DbgSName(Site),' ChildNode.Name=',ChildNode.Name,' Control=',DbgSName(AControl)]);
          if AControl=nil then continue;
          for Side:=Low(TAnchorKind) to high(TAnchorKind) do begin
            if ((ChildNode.NodeType=adltnSplitterHorizontal)
                and (Side in [akTop,akBottom]))
            or ((ChildNode.NodeType=adltnSplitterVertical)
                and (Side in [akLeft,akRight]))
            then continue;
            AnchorControl:=nil;
            if ChildNode.Anchors[Side]<>'' then
              AnchorControl:=TreeNameToDocker[ChildNode.Anchors[Side]];
            if AnchorControl<>nil then
              AControl.AnchorToNeighbour(Side,0,AnchorControl)
            else
              AControl.AnchorParallel(Side,0,Site);
          end;
        end;
      finally
        Site.EndUpdateLayout;
      end;
      Result:=Site;
    end else if Node.NodeType=adltnPages then begin
      // restore pages
      Site:=TAnchorDockHostSite(TreeNameToDocker[Node.Name]);
      if Site=nil then begin
        Site:=CreateSite('',true);
        fDisabledAutosizing.Add(Site);
        TreeNameToDocker[Node.Name]:=Site;
      end;
      Site.BeginUpdateLayout;
      try
        SetupSite(Site,Node,Parent);
        Site.FSiteType:=adhstPages;
        Site.Header.Parent:=nil;
        Site.CreatePages;
        for i:=0 to Node.Count-1 do begin
          Site.Pages.Pages.Add(Node[i].Name);
          AControl:=Restore(Node[i],Site.Pages.Page[i]);
          if AControl=nil then continue;
          AControl.Align:=alClient;
          for Side:=Low(TAnchorKind) to high(TAnchorKind) do
            AControl.AnchorSide[Side].Control:=nil;
        end;
      finally
        Site.EndUpdateLayout;
      end;
      Result:=Site;
    end else begin
      // create children
      for i:=0 to Node.Count-1 do
        Restore(Node[i],Parent);
    end;
  end;

begin
  Result:=true;
  Restore(Tree.Root, nil);
end;

function TAnchorDockMaster.DoCreateControl(aName: string;
  DisableAutoSizing: boolean): TControl;
begin
  Result:=nil;
  OnCreateControl(Self,aName,Result,DisableAutoSizing);
  if (Result<>nil) and (Result.Name<>aName) then
    raise Exception.Create('TAnchorDockMaster.DoCreateControl'+Format(
      adrsRequestedButCreated, [aName, Result.Name]));
end;

procedure TAnchorDockMaster.EnableAllAutoSizing;
var
  i: Integer;
begin
  i:=fDisabledAutosizing.Count-1;
  while (i>=0) do begin
    debugln(['TAnchorDockMaster.EnableAllAutoSizing ',DbgSName(TControl(fDisabledAutosizing[i]))]);
    TControl(fDisabledAutosizing[i]).EnableAutoSizing;
    i:=Min(i,fDisabledAutosizing.Count)-1;
  end;
end;

procedure TAnchorDockMaster.ClearLayoutProperties(AControl: TControl);
var
  a: TAnchorKind;
begin
  AControl.AutoSize:=false;
  AControl.Align:=alClient;
  AControl.BorderSpacing.Around:=0;
  AControl.BorderSpacing.Left:=0;
  AControl.BorderSpacing.Top:=0;
  AControl.BorderSpacing.Right:=0;
  AControl.BorderSpacing.Bottom:=0;
  AControl.BorderSpacing.InnerBorder:=0;
  for a:=Low(TAnchorKind) to High(TAnchorKind) do
    AControl.AnchorSide[a].Control:=nil;
end;

procedure TAnchorDockMaster.Notification(AComponent: TComponent;
  Operation: TOperation);
var
  AControl: TControl;
begin
  inherited Notification(AComponent, Operation);
  if Operation=opRemove then begin
    if AComponent is TControl then begin
      AControl:=TControl(AComponent);
      FControls.Remove(AControl);
      fNeedSimplify.Remove(AControl);
      fNeedFree.Remove(AControl);
      fDisabledAutosizing.Remove(AControl);
    end;
  end;
end;

constructor TAnchorDockMaster.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FControls:=TFPList.Create;
  FAllowDragging:=true;
  FDragTreshold:=4;
  FDockOutsideMargin:=10;
  FDockParentMargin:=10;
  FPageAreaInPercent:=40;
  FHeaderAlignTop:=80;
  HeaderAlignLeft:=120;
  FHeaderHint:=adrsDragAndDockC;
  FSplitterWidth:=4;
  FScaleOnResize:=true;
  fNeedSimplify:=TFPList.Create;
  fNeedFree:=TFPList.Create;
  fDisabledAutosizing:=TFPList.Create;
end;

destructor TAnchorDockMaster.Destroy;
var
  AControl: TControl;
begin
  if FControls.Count>0 then begin
    while ControlCount>0 do begin
      AControl:=Controls[ControlCount-1];
      debugln(['TAnchorDockMaster.Destroy: still in list: ',DbgSName(AControl),' Caption="',AControl.Caption,'"']);
      AControl.Free;
    end;
  end;
  FreeAndNil(fNeedSimplify);
  FreeAndNil(FControls);
  FreeAndNil(fNeedFree);
  FreeAndNil(fDisabledAutosizing);
  inherited Destroy;
end;

function TAnchorDockMaster.ControlCount: integer;
begin
  Result:=FControls.Count;
end;

function TAnchorDockMaster.IndexOfControl(const aName: string): integer;
begin
  Result:=ControlCount-1;
  while (Result>=0) and (Controls[Result].Name<>aName) do dec(Result);
end;

function TAnchorDockMaster.FindControl(const aName: string): TControl;
var
  i: LongInt;
begin
  i:=IndexOfControl(aName);
  if i>=0 then
    Result:=Controls[i]
  else
    Result:=nil;
end;

procedure TAnchorDockMaster.MakeDockable(AControl: TControl; Show: boolean;
  BringToFront: boolean; AddDockHeader: boolean);

  procedure ShowSite(Site: TAnchorDockHostSite);
  var
    CurControl: TControl;
  begin
    CurControl:=Site;
    while CurControl<>nil do begin
      CurControl.Visible:=true;
      if BringToFront and (CurControl is TAnchorDockPage) then
        TAnchorDockPageControl(CurControl.Parent).PageIndex:=
          TAnchorDockPage(CurControl).PageIndex;
      CurControl:=CurControl.Parent;
    end;
  end;

var
  Site: TAnchorDockHostSite;
begin
  if AControl.Name='' then
    raise Exception.Create('TAnchorDockMaster.MakeDockable '+
      adrsMissingControlName);
  Site:=nil;
  AControl.DisableAutoSizing;
  try
    if AControl is TAnchorDockHostSite then begin
      Site:=TAnchorDockHostSite(AControl);
    end else if AControl.Parent=nil then begin

      if FControls.IndexOf(AControl)<0 then begin
        FControls.Add(AControl);
        AControl.FreeNotification(Self);
      end;

      // create docksite
      Site:=CreateSite;
      try
        try
          Site.BoundsRect:=AControl.BoundsRect;
          ClearLayoutProperties(AControl);
          // dock
          AControl.ManualDock(Site);
          AControl.Visible:=true;
          if not AddDockHeader then
            Site.Header.Parent:=nil; // ToDo set property
        except
          FreeAndNil(Site);
          raise;
        end;
      finally
        if Site<>nil then
          Site.EnableAutoSizing;
      end;
    end else if AControl.Parent is TAnchorDockHostSite then begin
      // AControl is already docked => show site
      Site:=TAnchorDockHostSite(AControl.Parent);
      AControl.Visible:=true;
    end else begin
      raise Exception.Create('TAnchorDockMaster.MakeDockable '+Format(
        adrsNotSupportedHasParent, [DbgSName(AControl), DbgSName(AControl)]));
    end;
    if (Site<>nil) and Show then
      ShowSite(Site);
  finally
    AControl.EnableAutoSizing;
  end;
  // BringToFront
  if BringToFront and (Site<>nil) then
    GetParentForm(Site).BringToFront;
end;

function TAnchorDockMaster.ShowControl(ControlName: string;
  BringToFront: boolean): TControl;
begin
  Result:=DoCreateControl(ControlName,false);
  if Result=nil then exit;
  MakeDockable(Result,true,BringToFront);
end;

procedure TAnchorDockMaster.SaveMainLayoutToTree(LayoutTree: TAnchorDockLayoutTree
  );
var
  i: Integer;
  AControl: TControl;
  Site: TAnchorDockHostSite;
  SavedSites: TFPList;
  LayoutNode: TAnchorDockLayoutTreeNode;
begin
  SavedSites:=TFPList.Create;
  try
    for i:=0 to ControlCount-1 do begin
      AControl:=Controls[i];
      if not AControl.IsVisible then continue;
      Site:=GetParentForm(AControl) as TAnchorDockHostSite;
      if SavedSites.IndexOf(Site)>=0 then continue;
      SavedSites.Add(Site);
      debugln(['TAnchorDockMaster.SaveMainLayoutToTree Site=',DbgSName(Site)]);
      DebugWriteChildAnchors(Site);
      LayoutNode:=LayoutTree.NewNode(LayoutTree.Root);
      Site.SaveLayout(LayoutTree,LayoutNode);
    end;
  finally
    SavedSites.Free;
  end;
end;

procedure TAnchorDockMaster.SaveLayoutToConfig(Config: TConfigStorage);
var
  Tree: TAnchorDockLayoutTree;
begin
  Tree:=TAnchorDockLayoutTree.Create;
  try
    Config.AppendBasePath('MainConfig/');
    SaveMainLayoutToTree(Tree);
    Tree.SaveToConfig(Config);
    Config.UndoAppendBasePath;
    WriteDebugLayout('TAnchorDockMaster.SaveLayoutToConfig ',Tree.Root);
    DebugWriteChildAnchors(Tree.Root);
  finally
    Tree.Free;
  end;
end;

function TAnchorDockMaster.LoadLayoutFromConfig(Config: TConfigStorage): Boolean;
var
  Tree: TAnchorDockLayoutTree;
  ControlNames: TStringList;
  TreeNameToDocker: TADNameToControl;
begin
  Result:=false;
  ControlNames:=TStringList.Create;
  TreeNameToDocker:=TADNameToControl.Create;
  Tree:=TAnchorDockLayoutTree.Create;
  try
    // load tree
    Config.AppendBasePath('MainConfig/');
    Tree.LoadFromConfig(Config);
    Config.UndoAppendBasePath;
    WriteDebugLayout('TAnchorDockMaster.LoadLayoutFromConfig ',Tree.Root);
    DebugWriteChildAnchors(Tree.Root);

    // close all unneeded forms/controls
    if not CloseUnneededControls(Tree) then exit;

    // create all needed forms/controls
    if not CreateNeededControls(Tree,true,ControlNames) then exit;

    // simplify layouts
    ControlNames.Sort;
    debugln(['TAnchorDockMaster.LoadLayoutFromConfig controls: ']);
    debugln(ControlNames.Text);
    Tree.Root.Simplify(ControlNames);

    // reuse existing sites to reduce flickering
    MapTreeToControls(Tree,TreeNameToDocker);
    TreeNameToDocker.WriteDebugReport('TAnchorDockMaster.LoadLayoutFromConfig Map');

    // create sites
    RestoreLayout(Tree,TreeNameToDocker);
  finally
    // clean up
    TreeNameToDocker.Free;
    ControlNames.Free;
    Tree.Free;
    // commit (this can raise an exception)
    EnableAllAutoSizing;
  end;
  Result:=true;
end;

procedure TAnchorDockMaster.BeginUpdate;
begin
  inc(fUpdateCount);
end;

procedure TAnchorDockMaster.EndUpdate;
begin
  if fUpdateCount<=0 then
    RaiseGDBException('');
  dec(fUpdateCount);
  if fUpdateCount=0 then
    SimplifyPendingLayouts;
end;

procedure TAnchorDockMaster.NeedSimplify(AControl: TControl);
begin
  if Self=nil then exit;
  if csDestroying in ComponentState then exit;
  if csDestroying in AControl.ComponentState then exit;
  if fNeedSimplify=nil then exit;
  if fNeedSimplify.IndexOf(AControl)>=0 then exit;
  if not ((AControl is TAnchorDockHostSite)
          or (AControl is TAnchorDockPage))
  then
    exit;
  if Application.Terminated then exit;
  debugln(['TAnchorDockMaster.NeedSimplify ',DbgSName(AControl),' Caption="',AControl.Caption,'"']);
  fNeedSimplify.Add(AControl);
  AControl.FreeNotification(Self);
end;

procedure TAnchorDockMaster.NeedFree(AControl: TControl);
begin
  if fNeedFree.IndexOf(AControl)>=0 then exit;
  if csDestroying in AControl.ComponentState then exit;
  fNeedFree.Add(AControl);
  AControl.DisableAutoSizing;
  AControl.Parent:=nil;
  AControl.Visible:=false;
end;

procedure TAnchorDockMaster.SimplifyPendingLayouts;
var
  AControl: TControl;
  Changed: Boolean;
  i: Integer;
begin
  if fSimplifying or (fUpdateCount>0) then exit;
  fSimplifying:=true;
  try
    // simplify layout (do not free controls in this step, only mark them)
    repeat
      Changed:=false;
      i:=fNeedSimplify.Count-1;
      while i>=0 do begin
        AControl:=TControl(fNeedSimplify[i]);
        if (csDestroying in AControl.ComponentState)
        or (fNeedFree.IndexOf(AControl)>=0) then begin
          fNeedSimplify.Delete(i);
          Changed:=true;
        end else if (AControl is TAnchorDockHostSite) then begin
          if not TAnchorDockHostSite(AControl).UpdatingLayout then begin
            fNeedSimplify.Delete(i);
            Changed:=true;
            if TAnchorDockHostSite(AControl).SiteType=adhstNone then
            begin
              debugln(['TAnchorDockMaster.SimplifyPendingLayouts free empty site: ',dbgs(pointer(AControl)),' Caption="',AControl.Caption,'"']);
              NeedFree(AControl);
            end else
              TAnchorDockHostSite(AControl).Simplify;
          end;
        end else if AControl is TAnchorDockPage then begin
          fNeedSimplify.Delete(i);
          Changed:=true;
          NeedFree(AControl);
        end else
          RaiseGDBException('TAnchorDockMaster.SimplifyPendingLayouts inconsistency');
        i:=Min(fNeedSimplify.Count,i)-1;
      end;
    until not Changed;

    // free unneeded controls
    while fNeedFree.Count>0 do
      if csDestroying in TControl(fNeedFree[0]).ComponentState then
        fNeedFree.Delete(0)
      else
        TControl(fNeedFree[0]).Free;

  finally
    fSimplifying:=false;
  end;
end;

function TAnchorDockMaster.AutoFreedIfControlIsRemoved(AControl,
  RemovedControl: TControl): boolean;
{ returns true if the simplification algorithm will automatically free
     AControl when RemovedControl is removed
  Some sites are dummy sites that were autocreated. They will be auto freed
  if not needed anymore.
  1. A TAnchorDockPage has a TAnchorDockHostSite as child. If the child is freed
     the page will be freed.
  2. When a TAnchorDockPageControl has only one page left the content is moved
     up and the pagecontrol and page will be freed.
  3. When a layout site has only one child site left, the content is moved up
     and the child site will be freed.
  4. When the control of a OneControl site is freed the site will be freed.
}
var
  ParentSite: TAnchorDockHostSite;
  Page: TAnchorDockPage;
  PageControl: TAnchorDockPageControl;
  OtherPage: TAnchorDockPage;
  Site, Site1, Site2: TAnchorDockHostSite;
begin
  Result:=false;
  if (RemovedControl=nil) or (AControl=nil) then exit;
  while RemovedControl<>nil do begin
    if RemovedControl=AControl then exit(true);
    if RemovedControl is TAnchorDockPage then begin
      // a page will be removed
      Page:=TAnchorDockPage(RemovedControl);
      if not (Page.Parent is TAnchorDockPageControl) then exit;
      PageControl:=TAnchorDockPageControl(Page.Parent);
      if PageControl.PageCount>2 then exit;
      if PageControl.PageCount=2 then begin
        // this pagecontrol will be replaced by the content of the other page
        if PageControl=AControl then exit(true);
        if PageControl.Page[0]=Page then
          OtherPage:=PageControl.DockPages[1]
        else
          OtherPage:=PageControl.DockPages[0];
        // the other page will be removed (its content will be moved up)
        if OtherPage=AControl then exit(true);
        if (OtherPage.ControlCount>0) then begin
          if (OtherPage.Controls[0] is TAnchorDockHostSite)
          and (OtherPage.Controls[0]=RemovedControl) then
            exit(true); // the site of the other page will be removed (its content moved up)
        end;
        exit;
      end;
      // the last page of the pagecontrol is freed => the pagecontrol will be removed too
    end else if RemovedControl is TAnchorDockPageControl then begin
      // the pagecontrol will be removed
      if not (RemovedControl.Parent is TAnchorDockHostSite) then exit;
      // a pagecontrol is always the only child of a site
      // => the site will be removed too
    end else if RemovedControl is TAnchorDockHostSite then begin
      // a site will be removed
      Site:=TAnchorDockHostSite(RemovedControl);
      if Site.Parent is TAnchorDockPage then begin
        // a page has only one site
        // => the page will be removed too
      end else if Site.Parent is TAnchorDockHostSite then begin
        ParentSite:=TAnchorDockHostSite(Site.Parent);
        if (ParentSite.SiteType=adhstOneControl)
        or ParentSite.IsOneSiteLayout(Site) then begin
          // the control of a OneControl site is removed => the ParentSite is freed too
        end else if ParentSite.SiteType=adhstLayout then begin
          if ParentSite.IsTwoSiteLayout(Site1,Site2) then begin
            // when there are two sites and one of them is removed
            // the content of the other will be moved up and then both sites are
            // removed
            if (Site1=AControl) or (Site2=AControl) then
              exit(true);
          end;
          exit; // removing only site will not free the layout
        end else begin
          raise Exception.Create('TAnchorDockMaster.AutoFreedIfControlIsRemoved ParentSiteType='+dbgs(ParentSite.SiteType)+' ChildSiteType='+dbgs(Site.SiteType));
        end;
      end else
        exit; // other classes will never be auto freed
    end else begin
      // control is not a site => check if control is in a OneControl site
      if not (RemovedControl.Parent is TAnchorDockHostSite) then exit;
      ParentSite:=TAnchorDockHostSite(RemovedControl.Parent);
      if (ParentSite.SiteType<>adhstOneControl) then exit;
      if ParentSite.GetOneControl<>RemovedControl then exit;
      // the control of a OneControl site is removed => the site is freed too
    end;
    RemovedControl:=RemovedControl.Parent;
  end;
end;

function TAnchorDockMaster.CreateSite(NamePrefix: string;
  DisableAutoSizing: boolean): TAnchorDockHostSite;
var
  i: Integer;
  NewName: String;
begin
  Result:=TAnchorDockHostSite(TAnchorDockHostSite.NewInstance);
  Result.DisableAutoSizing;
  Result.Create(Self);
  i:=0;
  repeat
    inc(i);
    NewName:=NamePrefix+AnchorDockSiteName+IntToStr(i);
  until (Screen.FindForm(NewName)=nil) and (FindComponent(NewName)=nil);
  Result.Name:=NewName;
  if not DisableAutoSizing then
    Result.EnableAutoSizing;
end;

function TAnchorDockMaster.CreateSplitter(NamePrefix: string
  ): TAnchorDockSplitter;
var
  i: Integer;
  NewName: String;
begin
  Result:=TAnchorDockSplitter.Create(Self);
  i:=0;
  repeat
    inc(i);
    NewName:=NamePrefix+AnchorDockSplitterName+IntToStr(i);
  until FindComponent(NewName)=nil;
  Result.Name:=NewName;
end;

{ TAnchorDockHostSite }

procedure TAnchorDockHostSite.SetHeaderSide(const AValue: TAnchorKind);
begin
  if FHeaderSide=AValue then exit;
  FHeaderSide:=AValue;
end;

procedure TAnchorDockHostSite.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation=opRemove then begin
    if AComponent=Pages then FPages:=nil;
    if AComponent=Header then FHeader:=nil;
  end;
end;

function TAnchorDockHostSite.DoDockClientMsg(DragDockObject: TDragDockObject;
  aPosition: TPoint): boolean;
var
  NewControl: TControl;
begin
  Result:=false;
  if aPosition.X=0 then ;
  if UpdatingLayout then exit;
  debugln(['TAnchorDockHostSite.DoDockClientMsg Self="',Caption,'"  Control=',DbgSName(DragDockObject.Control),' DropOnControl=',DbgSName(DragDockObject.DropOnControl),' Align=',dbgs(DragDockObject.DropAlign)]);

  DisableAutoSizing;
  try
    BeginUpdateLayout;
    try
      DockMaster.SimplifyPendingLayouts;
      NewControl:=DragDockObject.Control;
      NewControl.DisableAutoSizing;

      if NewControl.Parent=Self then begin
        // change of layout
        if SiteType=adhstLayout then
          RemoveControlFromLayout(NewControl)
        else
          raise Exception.Create('TAnchorDockHostSite.DoDockClientMsg TODO redock of '+NewControl.Caption);
      end;

      if SiteType=adhstNone then begin
        // make a control dockable by docking it into a TAnchorDockHostSite;
        Result:=DockFirstControl(DragDockObject);
      end else if DragDockObject.DropAlign=alClient then begin
        // page docking
        if SiteType=adhstOneControl then begin
          if Parent is TAnchorDockPage then begin
            // add as sibling page
            Result:=(Parent.Parent.Parent as TAnchorDockHostSite).DockAnotherPage(NewControl);
          end else
            // create pages
            Result:=DockSecondPage(NewControl);
        end else if SiteType=adhstPages then
          // add as sibling page
          Result:=DockAnotherPage(NewControl)
      end else if DragDockObject.DropAlign in [alLeft,alTop,alRight,alBottom] then
      begin
        // anchor docking
        if SiteType=adhstOneControl then begin
          if Parent is TAnchorDockHostSite then begin
            // add site as sibling
            Result:=TAnchorDockHostSite(Parent).DockAnotherControl(Self,NewControl,
                      DragDockObject.DropAlign,DragDockObject.DropOnControl<>nil);
          end else
            // create layout
            Result:=DockSecondControl(NewControl,DragDockObject.DropAlign,
                                      DragDockObject.DropOnControl<>nil);
        end else if SiteType=adhstLayout then
          // add site as sibling
          Result:=DockAnotherControl(nil,NewControl,DragDockObject.DropAlign,
                                     DragDockObject.DropOnControl<>nil);
      end;

      NewControl.EnableAutoSizing;
    finally
      EndUpdateLayout;
    end;
  finally
    EnableAutoSizing;
  end;
end;

function TAnchorDockHostSite.DockFirstControl(DragDockObject: TDragDockObject
  ): boolean;
var
  DestRect: TRect;
begin
  if SiteType<>adhstNone then
    RaiseGDBException('TAnchorDockHostSite.DockFirstControl inconsistency');
  // create adhstOneControl
  with DragDockObject do begin
    DestRect := DockRect;
    DragDockObject.Control.Dock(Self, DestRect);
  end;
  FSiteType:=adhstOneControl;
  Result:=true;
end;

function TAnchorDockHostSite.DockSecondControl(NewControl: TControl;
  DockAlign: TAlign; Inside: boolean): boolean;
{ Convert a adhstOneControl into a adhstLayout by docking NewControl
  at a side (DockAlign).
  If Inside=true this DockSite is not expanded and both controls share the old space.
  If Inside=false this DockSite is expanded.
}
var
  OldSite: TAnchorDockHostSite;
  OldControl: TControl;
begin
  Result:=true;
  debugln(['TAnchorDockHostSite.DockSecondControl Self="',Caption,'" AControl=',DbgSName(NewControl),' Align=',dbgs(DockAlign),' Inside=',Inside]);
  if SiteType<>adhstOneControl then
    RaiseGDBException('TAnchorDockHostSite.DockSecondControl inconsistency: not adhstOneControl');
  if not (DockAlign in [alLeft,alTop,alRight,alBottom]) then
    RaiseGDBException('TAnchorDockHostSite.DockSecondControl inconsistency: DockAlign='+dbgs(DockAlign));

  FSiteType:=adhstLayout;

  // remove header (keep it for later use)
  Header.Parent:=nil;

  // put the OldControl into a site of its own (OldSite) and dock OldSite
  OldControl:=GetOneControl;
  OldSite:=GetSite(OldControl);
  AddCleanControl(OldSite);
  OldSite.AnchorClient(0);
  // the LCL will compute the bounds later after EnableAutoSizing
  // but the bounds are needed now => set them manually
  OldSite.BoundsRect:=Rect(0,0,ClientWidth,ClientHeight);

  Result:=DockAnotherControl(OldSite,NewControl,DockAlign,Inside);

  debugln(['TAnchorDockHostSite.DockSecondControl END Self="',Caption,'" AControl=',DbgSName(NewControl),' Align=',dbgs(DockAlign),' Inside=',Inside]);
end;

function TAnchorDockHostSite.DockAnotherControl(Sibling, NewControl: TControl;
  DockAlign: TAlign; Inside: boolean): boolean;
var
  Splitter: TAnchorDockSplitter;
  a: TAnchorKind;
  NewSite: TAnchorDockHostSite;
  NewBounds: TRect;
  MainAnchor: TAnchorKind;
  i: Integer;
  NewSiblingWidth: Integer;
  NewSiblingHeight: Integer;
  NewSize: LongInt;
  BoundsIncreased: Boolean;
begin
  Result:=false;
  if SiteType<>adhstLayout then
    RaiseGDBException('TAnchorDockHostSite.DockAnotherControl inconsistency');
  if not (DockAlign in [alLeft,alTop,alRight,alBottom]) then
    RaiseGDBException('TAnchorDockHostSite.DockAnotherControl inconsistency');

  // add a splitter
  Splitter:=DockMaster.CreateSplitter;
  Splitter.Name:=GetUniqueSplitterName;
  if DockAlign in [alLeft,alRight] then begin
    Splitter.ResizeAnchor:=akLeft;
    Splitter.Width:=DockMaster.SplitterWidth;
  end else begin
    Splitter.ResizeAnchor:=akTop;
    Splitter.Height:=DockMaster.SplitterWidth;
  end;
  Splitter.Parent:=Self;

  // dock the NewControl
  NewSite:=GetSite(NewControl);
  AddCleanControl(NewSite);

  BoundsIncreased:=false;
  if (not Inside) and (Parent=nil) then begin
    // expand
    NewBounds:=BoundsRect;
    case DockAlign of
    alLeft:
      begin
        dec(NewBounds.Left,NewSite.Width+Splitter.Width);
        MoveAllControls(NewSite.Width+Splitter.Width,0);
      end;
    alRight:
      inc(NewBounds.Right,NewSite.Width+Splitter.Width);
    alTop:
      begin
        dec(NewBounds.Top,NewSite.Height+Splitter.Height);
        MoveAllControls(0,NewSite.Height+Splitter.Height);
      end;
    alBottom:
      inc(NewBounds.Bottom,NewSite.Height+Splitter.Height);
    end;
    BoundsRect:=NewBounds;
    BoundsIncreased:=true;
    debugln(['TAnchorDockHostSite.DockAnotherControl AFTER ENLARGE ',Caption]);
    DebugWriteChildAnchors(Self);
  end;

  // anchors
  MainAnchor:=MainAlignAnchor[DockAlign];
  if Inside and (Sibling<>nil) then begin
    { Example: insert right of Sibling
                    #                                  #
        ################          ########################
            -------+#                -------+#+-------+#
            Sibling|#     ----->     Sibling|#|NewSite|#
            -------+#                -------+#+-------+#
        ################          ########################
                    #                                  #
     }
    for a:=low(TAnchorKind) to high(TAnchorKind) do begin
      if a in AnchorAlign[DockAlign] then begin
        NewSite.AnchorSide[a].Assign(Sibling.AnchorSide[a]);
      end else begin
        NewSite.AnchorToNeighbour(a,0,Splitter);
      end;
    end;
    Sibling.AnchorToNeighbour(MainAnchor,0,Splitter);

    if DockAlign in [alLeft,alRight] then begin
      Splitter.AnchorSide[akTop].Assign(Sibling.AnchorSide[akTop]);
      Splitter.AnchorSide[akBottom].Assign(Sibling.AnchorSide[akBottom]);
      // resize and move
      // the NewSite gets at maximum half the space
      // Many bounds are later set by the LCL anchoring. When docking several
      // controls at once the bounds are needed earlier.
      NewSize:=Max(1,Min(NewSite.Width,Sibling.Width div 2));
      NewBounds:=Rect(0,0,NewSize,Sibling.Height);
      NewSiblingWidth:=Max(1,Sibling.Width-NewSize-Splitter.Width);
      if DockAlign=alLeft then begin
        // alLeft: NewControl, Splitter, Sibling
        Splitter.SetBounds(Sibling.Left+NewSize,Sibling.Top,
                           Splitter.Width,Sibling.Height);
        OffsetRect(NewBounds,Sibling.Left,Sibling.Top);
        Sibling.SetBounds(Splitter.Left+Splitter.Width,Sibling.Top,
                          NewSiblingWidth,Sibling.Height);
      end else begin
        // alRight: Sibling, Splitter, NewControl
        Sibling.Width:=NewSiblingWidth;
        Splitter.SetBounds(Sibling.Left+Sibling.Width,Sibling.Top,
                           Splitter.Width,Sibling.Height);
        OffsetRect(NewBounds,Splitter.Left+Splitter.Width,Sibling.Top);
      end;
      NewSite.BoundsRect:=NewBounds;
    end else begin
      Splitter.AnchorSide[akLeft].Assign(Sibling.AnchorSide[akLeft]);
      Splitter.AnchorSide[akRight].Assign(Sibling.AnchorSide[akRight]);
      // resize and move
      // the NewSite gets at maximum half the space
      // Many bounds are later set by the LCL anchoring. When docking several
      // controls at once the bounds are needed earlier.
      NewSize:=Max(1,Min(NewSite.Height,Sibling.Height div 2));
      NewSiblingHeight:=Max(1,Sibling.Height-NewSize-Splitter.Height);
      if DockAlign=alTop then begin
        // alTop: NewControl, Splitter, Sibling
        Splitter.SetBounds(Sibling.Left,Sibling.Top+NewSize,
                           Sibling.Width,Splitter.Height);
        NewSite.SetBounds(Sibling.Left,Sibling.Top,Sibling.Width,NewSize);
        Sibling.SetBounds(Sibling.Left,Splitter.Top+Splitter.Height,
                          Sibling.Width,NewSiblingHeight);
      end else begin
        // alBottom: Sibling, Splitter, NewControl
        Sibling.Height:=NewSiblingHeight;
        Splitter.SetBounds(Sibling.Left,Sibling.Top+Sibling.Height,
                           Sibling.Width,Splitter.Height);
        NewSite.SetBounds(Sibling.Left,Splitter.Top+Splitter.Height,
                          Sibling.Width,NewSize);
      end;
    end;
  end else begin
    { Example: insert right of all siblings
        ##########         #######################
        --------+#         --------+#+----------+#
        SiblingA|#         SiblingA|#|          |#
        --------+#         --------+#|          |#
        ##########  -----> ##########|NewControl|#
        --------+#         --------+#|          |#
        SiblingB|#         SiblingB|#|          |#
        --------+#         --------+#+----------+#
        ##########         #######################
    }
    if DockAlign in [alLeft,alRight] then
      NewSize:=NewSite.Width
    else
      NewSize:=NewSite.Height;
    for i:=0 to ControlCount-1 do begin
      Sibling:=Controls[i];
      if Sibling.AnchorSide[MainAnchor].Control=Self then begin
        // this Sibling is anchored to the docked site
        // anchor it to the splitter
        Sibling.AnchorToNeighbour(MainAnchor,0,Splitter);
        if not BoundsIncreased then begin
          // the NewSite gets at most half the space
          if DockAlign in [alLeft,alRight] then
            NewSize:=Min(NewSize,Sibling.Width div 2)
          else
            NewSize:=Min(NewSize,Sibling.Height div 2);
        end;
      end;
    end;
    NewSize:=Max(1,NewSize);

    // anchor Splitter and NewSite
    a:=ClockwiseAnchor[MainAnchor];
    Splitter.AnchorParallel(a,0,Self);
    Splitter.AnchorParallel(OppositeAnchor[a],0,Self);
    NewSite.AnchorParallel(a,0,Self);
    NewSite.AnchorParallel(OppositeAnchor[a],0,Self);
    NewSite.AnchorParallel(MainAnchor,0,Self);
    NewSite.AnchorToNeighbour(OppositeAnchor[MainAnchor],0,Splitter);

    // Many bounds are later set by the LCL anchoring. When docking several
    // controls at once the bounds are needed earlier.
    if DockAlign in [alLeft,alRight] then begin
      if DockAlign=alLeft then begin
        // alLeft: NewSite, Splitter, other siblings
        Splitter.SetBounds(NewSize,0,Splitter.Width,ClientHeight);
        NewSite.SetBounds(0,0,NewSize,ClientHeight);
      end else begin
        // alRight: other siblings, Splitter, NewSite
        NewSite.SetBounds(ClientWidth-NewSize,0,NewSize,ClientHeight);
        Splitter.SetBounds(NewSite.Left-Splitter.Width,0,Splitter.Width,ClientHeight);
      end;
    end else begin
      if DockAlign=alTop then begin
        // alTop: NewSite, Splitter, other siblings
        Splitter.SetBounds(0,NewSize,ClientWidth,Splitter.Height);
        NewSite.SetBounds(0,0,ClientWidth,NewSize);
      end else begin
        // alBottom: other siblings, Splitter, NewSite
        NewSite.SetBounds(0,ClientHeight-NewSize,ClientWidth,NewSize);
        Splitter.SetBounds(0,NewSite.Top-Splitter.Height,ClientWidth,Splitter.Height);
      end;
    end;
    // shrink siblings
    for i:=0 to ControlCount-1 do begin
      Sibling:=Controls[i];
      if Sibling.AnchorSide[MainAnchor].Control=Splitter then begin
        NewBounds:=Sibling.BoundsRect;
        case DockAlign of
        alLeft: NewBounds.Left:=Splitter.Left+Splitter.Width;
        alRight: NewBounds.Right:=Splitter.Left;
        alTop: NewBounds.Top:=Splitter.Top+Splitter.Height;
        alBottom: NewBounds.Bottom:=Splitter.Top;
        end;
        NewBounds.Right:=Max(NewBounds.Left+1,NewBounds.Right);
        NewBounds.Bottom:=Max(NewBounds.Top+1,NewBounds.Bottom);
        Sibling.BoundsRect:=NewBounds;
      end;
    end;
  end;

  DebugWriteChildAnchors(Self);
  Result:=true;
end;

procedure TAnchorDockHostSite.CreatePages;
begin
  FPages:=TAnchorDockPageControl.Create(nil); // do not own it, pages can be moved to another site
  FPages.FreeNotification(Self);
  FPages.Parent:=Self;
  FPages.Align:=alClient;
end;

function TAnchorDockHostSite.DockSecondPage(NewControl: TControl): boolean;
var
  OldControl: TControl;
  OldSite: TAnchorDockHostSite;
begin
  debugln(['TAnchorDockHostSite.DockSecondPage Self="',Caption,'" AControl=',DbgSName(NewControl)]);
  if SiteType<>adhstOneControl then
    RaiseGDBException('TAnchorDockHostSite.DockSecondPage inconsistency');

  FSiteType:=adhstPages;
  CreatePages;

  // remove header (keep it for later use)
  debugln(['TAnchorDockHostSite.DockSecondPage Self="',Caption,'" removing header ...']);
  Header.Parent:=nil;

  // put the OldControl into a page of its own
  debugln(['TAnchorDockHostSite.DockSecondPage Self="',Caption,'" move oldcontrol to site of its own ...']);
  OldControl:=GetOneControl;
  OldSite:=GetSite(OldControl);
  OldSite.HostDockSite:=nil;
  debugln(['TAnchorDockHostSite.DockSecondPage Self="',Caption,'" adding oldcontrol site ...']);
  FPages.Pages.Add(OldSite.Caption);
  OldSite.Parent:=FPages.Page[0];
  OldSite.Align:=alClient;
  OldSite.Visible:=true;

  Result:=DockAnotherPage(NewControl);
end;

function TAnchorDockHostSite.DockAnotherPage(NewControl: TControl): boolean;
var
  NewSite: TAnchorDockHostSite;
begin
  debugln(['TAnchorDockHostSite.DockAnotherPage Self="',Caption,'" make new control (',DbgSName(NewControl),') dockable ...']);
  if SiteType<>adhstPages then
    RaiseGDBException('TAnchorDockHostSite.DockAnotherPage inconsistency');

  NewSite:=GetSite(NewControl);
  //debugln(['TAnchorDockHostSite.DockAnotherPage Self="',Caption,'" adding newcontrol site ...']);
  FPages.Pages.Add(NewSite.Caption);
  //debugln(['TAnchorDockHostSite.DockAnotherPage ',DbgSName(FPages.Page[1])]);
  NewSite.Parent:=FPages.Page[FPages.PageCount-1];
  NewSite.Align:=alClient;
  NewSite.Visible:=true;
  FPages.PageIndex:=FPages.PageCount-1;

  Result:=true;
end;

procedure TAnchorDockHostSite.AddCleanControl(AControl: TControl;
  TheAlign: TAlign);
var
  a: TAnchorKind;
begin
  AControl.Parent:=Self;
  AControl.Align:=TheAlign;
  AControl.Anchors:=[akLeft,akTop,akRight,akBottom];
  for a:=Low(TAnchorKind) to high(TAnchorKind) do
    AControl.AnchorSide[a].Control:=nil;
  AControl.Visible:=true;
end;

procedure TAnchorDockHostSite.RemoveControlFromLayout(AControl: TControl);

  procedure RemoveControlBoundSplitter(Splitter: TAnchorDockSplitter;
    Side: TAnchorKind);
  var
    i: Integer;
    Sibling: TControl;
    NewBounds: TRect;
  begin
    debugln(['RemoveControlBoundSplitter START ',DbgSName(Splitter)]);
    { Example: Side=akRight
                          #             #
        #####################     #########
           ---+S+--------+#         ---+#
           ---+S|AControl|#   --->  ---+#
           ---+S+--------+#         ---+#
        #####################     #########
    }
    for i:=Splitter.AnchoredControlCount-1 downto 0 do begin
      Sibling:=Splitter.AnchoredControls[i];
      if Sibling.AnchorSide[Side].Control=Splitter then begin
        // anchor Sibling to next
        Sibling.AnchorSide[Side].Assign(AControl.AnchorSide[Side]);
        // enlarge Sibling
        NewBounds:=Sibling.BoundsRect;
        case Side of
        akTop: NewBounds.Top:=AControl.Top;
        akLeft: NewBounds.Left:=AControl.Left;
        akRight: NewBounds.Right:=AControl.Left+AControl.Width;
        akBottom: NewBounds.Bottom:=AControl.Top+AControl.Height;
        end;
        Sibling.BoundsRect:=NewBounds;
      end;
    end;
    debugln(['RemoveControlBoundSplitter ',DbgSName(Splitter)]);
    Splitter.Free;

    DebugWriteChildAnchors(GetParentForm(Self));
  end;

  procedure ConvertToOneControlType(OnlySiteLeft: TAnchorDockHostSite);
  var
    a: TAnchorKind;
    NewBounds: TRect;
    p: TPoint;
    i: Integer;
    Sibling: TControl;
  begin
    BeginUpdateLayout;
    try
      // remove splitters
      for i:=ControlCount-1 downto 0 do begin
        Sibling:=Controls[i];
        if Sibling is TAnchorDockSplitter then
          Sibling.Free
        else if Sibling is TAnchorDockHostSite then
          for a:=low(TAnchorKind) to high(TAnchorKind) do
            Sibling.AnchorSide[a].Control:=nil;
      end;
      if Parent=nil then begin
        // shrink this site
        NewBounds:=OnlySiteLeft.BoundsRect;
        p:=ClientOrigin;
        OffsetRect(NewBounds,p.x,p.y);
        BoundsRect:=NewBounds;
      end;

      // change type
      FSiteType:=adhstOneControl;
      OnlySiteLeft.Align:=alClient;
      Header.Parent:=Self;
      UpdateHeaderAlign;

      debugln(['TAnchorDockHostSite.RemoveControlFromLayout.ConvertToOneControlType AFTER CONVERT "',Caption,'" to onecontrol OnlySiteLeft="',OnlySiteLeft.Caption,'"']);
      DebugWriteChildAnchors(GetParentForm(Self));

      DockMaster.NeedSimplify(Self);
    finally
      EndUpdateLayout;
    end;
  end;

var
  Side: TAnchorKind;
  Splitter: TAnchorDockSplitter;
  OnlySiteLeft: TAnchorDockHostSite;
  Sibling: TControl;
  SplitterCount: Integer;
begin
  debugln(['TAnchorDockHostSite.RemoveControlFromLayout Self="',Caption,'" AControl=',DbgSName(AControl),'="',AControl.Caption,'"']);
  if SiteType<>adhstLayout then
    RaiseGDBException('TAnchorDockHostSite.RemoveControlFromLayout inconsistency');

  if IsOneSiteLayout(OnlySiteLeft) then begin
    ConvertToOneControlType(OnlySiteLeft);
    exit;
  end;

  // remove a splitter and fill the gap
  SplitterCount:=0;
  for Side:=Low(TAnchorKind) to high(TAnchorKind) do begin
    Sibling:=AControl.AnchorSide[OppositeAnchor[Side]].Control;
    if Sibling is TAnchorDockSplitter then begin
      inc(SplitterCount);
      Splitter:=TAnchorDockSplitter(Sibling);
      if Splitter.SideAnchoredControlCount(Side)=1 then begin
        // Splitter is only used by AControl at Side
        RemoveControlBoundSplitter(Splitter,Side);
        exit;
      end;
    end;
  end;

  if SplitterCount=4 then
    RemoveSpiralSplitter(AControl);
end;

procedure TAnchorDockHostSite.RemoveSpiralSplitter(AControl: TControl);
{ Merge two splitters and delete one of them.
  Prefer the pair with shortest distance between.

  For example:
                   3            3
     111111111111113            3
        2+--------+3            3
        2|AControl|3  --->  111111111
        2+--------+3            2
        24444444444444          2
        2                       2
   Everything anchored to 4 is now anchored to 1.
   And right side of 1 is now anchored to where the right side of 4 was anchored.
}
var
  Splitters: array[TAnchorKind] of TAnchorDockSplitter;
  Side: TAnchorKind;
  Keep: TAnchorKind;
  DeleteSplitter: TAnchorDockSplitter;
  i: Integer;
  Sibling: TControl;
  NextSide: TAnchorKind;
  NewBounds: TRect;
begin
  for Side:=low(TAnchorKind) to high(TAnchorKind) do
    Splitters[Side]:=AControl.AnchorSide[Side].Control as TAnchorDockSplitter;
  // Prefer the pair with shortest distance between
  if (Splitters[akRight].Left-Splitters[akLeft].Left)
    <(Splitters[akBottom].Top-Splitters[akTop].Top)
  then
    Keep:=akLeft
  else
    Keep:=akTop;
  DeleteSplitter:=Splitters[OppositeAnchor[Keep]];
  // transfer anchors from the deleting splitter to the kept splitter
  for i:=0 to ControlCount-1 do begin
    Sibling:=Controls[i];
    for Side:=low(TAnchorKind) to high(TAnchorKind) do begin
      if Sibling.AnchorSide[Side].Control=DeleteSplitter then
        Sibling.AnchorSide[Side].Control:=Splitters[Keep];
    end;
  end;
  // longen kept splitter
  NextSide:=ClockwiseAnchor[Keep];
  if Splitters[Keep].AnchorSide[NextSide].Control<>Splitters[NextSide] then
    NextSide:=OppositeAnchor[NextSide];
  Splitters[Keep].AnchorSide[NextSide].Control:=
                                    DeleteSplitter.AnchorSide[NextSide].Control;
  case NextSide of
  akTop: Splitters[Keep].Top:=DeleteSplitter.Top;
  akLeft: Splitters[Keep].Left:=DeleteSplitter.Left;
  akRight: Splitters[Keep].Width:=DeleteSplitter.Left+DeleteSplitter.Width-Splitters[Keep].Left;
  akBottom: Splitters[Keep].Height:=DeleteSplitter.Top+DeleteSplitter.Height-Splitters[Keep].Top;
  end;

  // move splitter to the middle
  if Keep=akLeft then
    Splitters[Keep].Left:=(Splitters[Keep].Left+DeleteSplitter.Left) div 2
  else
    Splitters[Keep].Top:=(Splitters[Keep].Top+DeleteSplitter.Top) div 2;
  // adjust all anchored controls
  for i:=0 to ControlCount-1 do begin
    Sibling:=Controls[i];
    for Side:=low(TAnchorKind) to high(TAnchorKind) do begin
      if Sibling.AnchorSide[Side].Control=Splitters[Keep] then begin
        NewBounds:=Sibling.BoundsRect;
        case Side of
        akTop: NewBounds.Top:=Splitters[Keep].Top+Splitters[Keep].Height;
        akLeft: NewBounds.Left:=Splitters[Keep].Left+Splitters[Keep].Width;
        akRight: NewBounds.Right:=Splitters[Keep].Left;
        akBottom: NewBounds.Bottom:=Splitters[Keep].Top;
        end;
        Sibling.BoundsRect:=NewBounds;
      end;
    end;
  end;

  // delete the splitter
  DeleteSplitter.Free;
end;

procedure TAnchorDockHostSite.Simplify;
begin
  if (Pages<>nil) and (Pages.PageCount=1) then
    SimplifyPages
  else if (SiteType=adhstOneControl) and (GetOneControl is TAnchorDockHostSite) then
    SimplifyOneControl;
end;

procedure TAnchorDockHostSite.SimplifyPages;
var
  Page: TAnchorDockPage;
  Site: TAnchorDockHostSite;
begin
  if Pages=nil then exit;
  if Pages.PageCount=1 then begin
    debugln(['TAnchorDockHostSite.SimplifyPages "',Caption,'" PageCount=1']);
    DisableAutoSizing;
    BeginUpdateLayout;
    try
      // move the content of the Page to the place where Pages is
      Page:=Pages.DockPages[0];
      Site:=Page.GetSite;
      Site.Parent:=Self;
      if Site<>nil then
        CopyAnchorBounds(Pages,Site);
      if SiteType=adhstPages then
        FSiteType:=adhstOneControl;
      // free Pages
      FreeAndNil(FPages);
      if SiteType=adhstOneControl then
        SimplifyOneControl;
    finally
      EndUpdateLayout;
      EnableAutoSizing;
    end;
    debugln(['TAnchorDockHostSite.SimplifyPages END Self="',Caption,'"']);
    DebugWriteChildAnchors(GetParentForm(Self));
  end else if Pages.PageCount=0 then begin
    debugln(['TAnchorDockHostSite.SimplifyPages "',Caption,'" PageCount=0 Self=',dbgs(Pointer(Self))]);
    FSiteType:=adhstNone;
    FreeAndNil(FPages);
    DockMaster.NeedSimplify(Self);
  end;
end;

procedure TAnchorDockHostSite.SimplifyOneControl;
var
  Site: TAnchorDockHostSite;
  i: Integer;
  Child: TControl;
  a: TAnchorKind;
begin
  if SiteType<>adhstOneControl then exit;
  if not IsOneSiteLayout(Site) then exit;
  debugln(['TAnchorDockHostSite.SimplifyOneControl Self="',Caption,'" Site="',Site.Caption,'"']);
  DisableAutoSizing;
  BeginUpdateLayout;
  try
    // move the content of Site up and free Site
    // Note: it is not possible to do it the other way round, because moving a
    // form to screen changes the z order and focus
    FSiteType:=Site.SiteType;

    // header
    Header.Align:=Site.Header.Align;
    Header.Caption:=Site.Header.Caption;
    UpdateHeaderShowing;
    Caption:=Site.Caption;

    Site.BeginUpdateLayout;
    // move controls
    i:=Site.ControlCount-1;
    while i>=0 do begin
      Child:=Site.Controls[i];
      if Child.Owner<>Site then begin
        debugln(['TAnchorDockHostSite.SimplifyOneControl Self="',Caption,'" Child=',DbgSName(Child),'="',Child.Caption,'"']);
        Child.Parent:=Self;
        if Child=Site.Pages then begin
          FPages:=Site.Pages;
          Site.FPages:=nil;
        end;
        if Child.HostDockSite=Site then
          Child.HostDockSite:=Self;
        for a:=low(TAnchorKind) to high(TAnchorKind) do begin
          if Child.AnchorSide[a].Control=Site then
            Child.AnchorSide[a].Control:=Self;
        end;
      end;
      i:=Min(i,Site.ControlCount)-1;
    end;
    Site.EndUpdateLayout;

    // delete Site
    Site.FSiteType:=adhstNone;
    DockMaster.NeedFree(Site);
  finally
    EndUpdateLayout;
    EnableAutoSizing;
  end;

  debugln(['TAnchorDockHostSite.SimplifyOneControl END Self="',Caption,'"']);
  DebugWriteChildAnchors(GetParentForm(Self));
end;

function TAnchorDockHostSite.GetOneControl: TControl;
var
  i: Integer;
begin
  for i:=0 to ControlCount-1 do begin
    Result:=Controls[i];
    if Result.Owner<>Self then exit;
  end;
  Result:=nil;
end;

function TAnchorDockHostSite.GetSiteCount: integer;
var
  i: Integer;
  Child: TControl;
begin
  Result:=0;
  for i:=0 to ControlCount-1 do begin
    Child:=Controls[i];
    if not (Child is TAnchorDockHostSite) then continue;
    if not Child.IsVisible then continue;
    inc(Result);
  end;
end;

function TAnchorDockHostSite.IsOneSiteLayout(out Site: TAnchorDockHostSite
  ): boolean;
var
  i: Integer;
  Child: TControl;
begin
  Site:=nil;
  for i:=0 to ControlCount-1 do begin
    Child:=Controls[i];
    if not (Child is TAnchorDockHostSite) then continue;
    if not Child.IsVisible then continue;
    if Site<>nil then exit(false);
    Site:=TAnchorDockHostSite(Child);
  end;
  Result:=Site<>nil;
end;

function TAnchorDockHostSite.IsTwoSiteLayout(out Site1,
  Site2: TAnchorDockHostSite): boolean;
var
  i: Integer;
  Child: TControl;
begin
  Site1:=nil;
  Site2:=nil;
  for i:=0 to ControlCount-1 do begin
    Child:=Controls[i];
    if not (Child is TAnchorDockHostSite) then continue;
    if not Child.IsVisible then continue;
    if Site1=nil then
      Site1:=TAnchorDockHostSite(Child)
    else if Site2=nil then
      Site2:=TAnchorDockHostSite(Child)
    else
      exit(false);
  end;
  Result:=Site2<>nil;
end;

function TAnchorDockHostSite.GetUniqueSplitterName: string;
var
  i: Integer;
begin
  i:=0;
  repeat
    inc(i);
    Result:=AnchorDockSplitterName+IntToStr(i);
  until FindComponent(Result)=nil;
end;

function TAnchorDockHostSite.GetSite(AControl: TControl): TAnchorDockHostSite;
begin
  if AControl is TAnchorDockHostSite then
    Result:=TAnchorDockHostSite(AControl)
  else begin
    Result:=DockMaster.CreateSite;
    try
      AControl.ManualDock(Result,nil,alClient);
    finally
      Result.EnableAutoSizing;
    end;
  end;
end;

procedure TAnchorDockHostSite.MoveAllControls(dx, dy: integer);
// move all childs, except the sides that are anchored to parent left,top
var
  i: Integer;
  Child: TControl;
  NewBounds: TRect;
begin
  for i:=0 to ControlCount-1 do begin
    Child:=Controls[i];
    NewBounds:=Child.BoundsRect;
    OffsetRect(NewBounds,dx,dy);
    if Child.AnchorSideLeft.Control=Self then
      NewBounds.Left:=0;
    if Child.AnchorSideTop.Control=Self then
      NewBounds.Top:=0;
    Child.BoundsRect:=NewBounds;
  end;
end;

procedure TAnchorDockHostSite.AlignControls(AControl: TControl; var ARect: TRect
  );
var
  i: Integer;
  Child: TControl;
  Splitter: TAnchorDockSplitter;
begin
  inherited AlignControls(AControl, ARect);
  if csDestroying in ComponentState then exit;
  if DockMaster.ScaleOnResize and (not UpdatingLayout) then begin
    // scale splitters
    for i:=0 to ControlCount-1 do begin
      Child:=Controls[i];
      if not Child.IsVisible then continue;
      if Child is TAnchorDockSplitter then begin
        Splitter:=TAnchorDockSplitter(Child);
        //debugln(['TAnchorDockHostSite.AlignControls ',Caption,' ',DbgSName(Splitter),' OldBounds=',dbgs(Splitter.BoundsRect),' BaseBounds=',dbgs(Splitter.DockBounds),' BaseParentSize=',dbgs(Splitter.DockParentClientSize),' ParentSize=',ClientWidth,'x',ClientHeight]);
        if Splitter.ResizeAnchor in [akLeft,akRight] then begin
          if Splitter.DockParentClientSize.cx>0 then
            Splitter.SetBoundsKeepDockBounds(
              (Splitter.DockBounds.Left*ClientWidth) div Splitter.DockParentClientSize.cx,
              Splitter.Top,Splitter.Width,Splitter.Height);
        end else begin
          if Splitter.DockParentClientSize.cy>0 then
            Splitter.SetBoundsKeepDockBounds(Splitter.Left,
              (Splitter.DockBounds.Top*ClientHeight) div Splitter.DockParentClientSize.cy,
              Splitter.Width,Splitter.Height);
        end;
        //debugln(['TAnchorDockHostSite.AlignControls ',Caption,' ',DbgSName(Child),' NewBounds=',dbgs(Child.BoundsRect)]);
      end;
    end;
  end;
end;

procedure TAnchorDockHostSite.DoDock(NewDockSite: TWinControl; var ARect: TRect
  );
begin
  inherited DoDock(NewDockSite, ARect);
  DockMaster.SimplifyPendingLayouts;
end;

procedure TAnchorDockHostSite.SetParent(NewParent: TWinControl);
var
  OldCaption: string;
begin
  if NewParent=Parent then exit;
  inherited SetParent(NewParent);
  OldCaption:=Caption;
  UpdateDockCaption;
  if OldCaption<>Caption then begin
    // UpdateDockCaption has not updated parents => do it now
    if Parent is TAnchorDockHostSite then
      TAnchorDockHostSite(Parent).UpdateDockCaption;
    if Parent is TAnchorDockPage then
      TAnchorDockPage(Parent).UpdateDockCaption;
  end;
  UpdateHeaderShowing;
end;

function TAnchorDockHostSite.HeaderNeedsShowing: boolean;
begin
  Result:=(SiteType<>adhstLayout) and (not (Parent is TAnchorDockPage));
end;

procedure TAnchorDockHostSite.DoClose(var CloseAction: TCloseAction);
begin
  inherited DoClose(CloseAction);
end;

procedure TAnchorDockHostSite.Undock;
var
  p: TPoint;
begin
  if Parent=nil then exit;
  DisableAutoSizing;
  p:=ClientOrigin;
  Parent:=nil;
  SetBounds(Left+p.x,Top+p.y,Width,Height);
  EnableAutoSizing;
end;

function TAnchorDockHostSite.CanMerge: boolean;
begin
  Result:=(SiteType=adhstLayout)
      and (Parent is TAnchorDockHostSite)
      and (TAnchorDockHostSite(Parent).SiteType=adhstLayout);
end;

procedure TAnchorDockHostSite.Merge;
{ Move all child controls to parent and delete this site
}
var
  ParentSite: TAnchorDockHostSite;
  i: Integer;
  Child: TControl;
  Side: TAnchorKind;
begin
  ParentSite:=Parent as TAnchorDockHostSite;
  if (SiteType<>adhstLayout) or (ParentSite.SiteType<>adhstLayout) then
    RaiseGDBException('');
  ParentSite.BeginUpdateLayout;
  DisableAutoSizing;
  try
    i:=0;
    while i<ControlCount-1 do begin
      Child:=Controls[i];
      if Child.Owner=Self then
        inc(i)
      else begin
        Child.Parent:=ParentSite;
        Child.SetBounds(Child.Left+Left,Child.Top+Top,Child.Width,Child.Height);
        for Side:=Low(TAnchorKind) to High(TAnchorKind) do begin
          if Child.AnchorSide[Side].Control=Self then
            Child.AnchorSide[Side].Assign(AnchorSide[Side]);
        end;
      end;
    end;
    DockMaster.NeedFree(Self);
  finally
    ParentSite.EndUpdateLayout;
  end;
end;

function TAnchorDockHostSite.EnlargeSide(Side: TAnchorKind;
  OnlyCheckIfPossible: boolean): boolean;
{
 Enlarge one, shrink another

 Shrink one neighbor control, enlarge Control. Two splitters are resized.

     |#|         |#         |#|         |#
     |#| Control |#         |#|         |#
   --+#+---------+#   --> --+#| Control |#
   ===============#       ===#|         |#
   --------------+#       --+#|         |#
       A         |#        A|#|         |#
   --------------+#       --+#+---------+#
   ==================     ===================

 Enlarge one, shrink many

 Move one neighbor splitter, enlarge Control, resize one splitter, rotate the other splitter.

     |#|         |#|          |#|         |#|
     |#| Control |#|          |#|         |#|
   --+#+---------+#+--  --> --+#| Control |#+--
   ===================      ===#|         |#===
   --------+#+--------      --+#|         |#+--
           |#|   B            |#|         |#|B
           |#+--------        |#|         |#+--
       A   |#=========       A|#|         |#===
           |#+--------        |#|         |#+--
           |#|   C            |#|         |#|C
   --------+#+--------      --+#+---------+#+--
   ===================      ===================
}
begin
  Result:=false;
  if EnlargeSideResizeTwoSplitters(Side,ClockwiseAnchor[Side],
                                   OnlyCheckIfPossible) then exit;
  if EnlargeSideResizeTwoSplitters(Side,OppositeAnchor[ClockwiseAnchor[Side]],
                                   OnlyCheckIfPossible) then exit(true);
end;

function TAnchorDockHostSite.EnlargeSideResizeTwoSplitters(Side,
  SideEnlarge: TAnchorKind; OnlyCheckIfPossible: boolean): boolean;
{ Shrink one neighbor control, enlarge Control. Two splitters are resized.

    |#|         |#         |#|         |#
    |#| Control |#         |#|         |#
  --+#+---------+#   --> --+#| Control |#
  ===============#       ===#|         |#
  --------------+#       --+#|         |#
      A         |#        A|#|         |#
  --------------+#       --+#+---------+#
  ==================     ===================
}
var
  Splitter: TAnchorDockSplitter;
  EnlargeSplitter: TAnchorDockSplitter;
  SideShrink: TAnchorKind;
  ShrinkSplitter: TAnchorDockSplitter;
  i: Integer;
  Sibling: TControl;
  ParentSite: TAnchorDockHostSite;
begin
  Result:=false;
  if not (Parent is TAnchorDockHostSite) then exit;
  ParentSite:=TAnchorDockHostSite(Parent);
  if not OnlyCheckIfPossible then
    ParentSite.BeginUpdateLayout;
  try
    Splitter:=TAnchorDockSplitter(AnchorSide[Side].Control);
    if not (Splitter is TAnchorDockSplitter) then exit;
    // side has a splitter
    if (SideEnlarge<>ClockwiseAnchor[Side])
    and (SideEnlarge<>OppositeAnchor[ClockwiseAnchor[Side]]) then
      exit;
    // enlarge side is not a neighbor side
    EnlargeSplitter:=TAnchorDockSplitter(AnchorSide[SideEnlarge].Control);
    if not (EnlargeSplitter is TAnchorDockSplitter) then exit;
    // enlarge side has a splitter
    SideShrink:=OppositeAnchor[SideEnlarge];
    ShrinkSplitter:=TAnchorDockSplitter(AnchorSide[SideShrink].Control);
    if not (ShrinkSplitter is TAnchorDockSplitter) then exit;
    // shrink side has a splitter
    if Splitter.AnchorSide[SideShrink].Control<>ShrinkSplitter then exit;
    // Splitter stopps at ShrinkSplitter
    if not OnlyCheckIfPossible then begin
      EnlargeSplitter.AnchorSide[Side].Assign(ShrinkSplitter.AnchorSide[Side]);
      Splitter.AnchorSide[SideShrink].Control:=EnlargeSplitter;
    end;

    for i:=0 to Parent.ControlCount-1 do begin
      Sibling:=Controls[i];
      if Sibling.AnchorSide[SideEnlarge].Control<>EnlargeSplitter then continue;
      // Sibling is on the shrinking side
      case Side of
      akTop: if Sibling.Top>Top then continue;
      akLeft: if Sibling.Left>Left then continue;
      akRight: if Sibling.Left<Left then continue;
      akBottom: if Sibling.Top<Top then continue;
      end;
      if OnlyCheckIfPossible then begin
        // check if the Sibling is big enough for shrinking
        case SideShrink of
        akTop: if Sibling.Top>=EnlargeSplitter.Top then exit;
        akLeft: if Sibling.Left>=EnlargeSplitter.Left then exit;
        akRight: if Sibling.Left+Sibling.Width<=EnlargeSplitter.Left+EnlargeSplitter.Width then exit;
        akBottom: if Sibling.Top+Sibling.Height<=EnlargeSplitter.Top+EnlargeSplitter.Height then exit;
        end;
      end else begin
        // shrink Sibling
        Sibling.AnchorSide[SideShrink].Control:=EnlargeSplitter;
      end;
    end;

  finally
    if not OnlyCheckIfPossible then
      ParentSite.EndUpdateLayout;
  end;
  Result:=true;
end;

function TAnchorDockHostSite.CloseQuery: boolean;

  function Check(AControl: TWinControl): boolean;
  var
    i: Integer;
    Child: TControl;
  begin
    for i:=0 to AControl.ControlCount-1 do begin
      Child:=AControl.Controls[i];
      if Child is TWinControl then begin
        if Child is TCustomForm then begin
          if not TCustomForm(Child).CloseQuery then exit(false);
        end else begin
          if not Check(TWinControl(Child)) then exit(false);
        end;
      end;
    end;
    Result:=true;
  end;

begin
  Result:=Check(Self);
end;

function TAnchorDockHostSite.CloseSite: Boolean;
var
  AControl: TControl;
  AForm: TCustomForm;
  IsMainForm: Boolean;
  CloseAction: TCloseAction;
begin
  Result:=CloseQuery;
  if not Result then exit;

  case SiteType of
  adhstNone:
    Release;
  adhstOneControl:
    begin
      AControl:=GetOneControl;
      if AControl is TCustomForm then begin
        AForm:=TCustomForm(AControl);
        IsMainForm := (Application.MainForm = AForm)
                      or (AForm.IsParentOf(Application.MainForm));
        if IsMainForm then
          CloseAction := caFree
        else
          CloseAction := caHide;
        // ToDo: TCustomForm(AControl).DoClose(CloseAction);
        case CloseAction of
        caHide: Hide;
        caMinimize: WindowState := wsMinimized;
        caFree:
          begin
            // if form is MainForm, then terminate the application
            // the owner of the MainForm is the application,
            // so the Application will take care of free-ing the form
            // and Release is not necessary
            if IsMainForm then
              Application.Terminate
            else begin
              Release;
              AForm.Release;
            end;
          end;
        end;
      end else begin
        Release;
        AControl.Visible:=false;
      end;
    end;
  end;
end;

procedure TAnchorDockHostSite.RemoveControl(AControl: TControl);
begin
  DisableAutoSizing{$IFDEF DebugDisableAutoSizing}('TAnchorDockHostSite.RemoveControl'){$ENDIF};
  inherited RemoveControl(AControl);
  if not (csDestroying in ComponentState) then begin
    if (not ((AControl is TAnchorDockHeader)
             or (AControl is TAnchorDockSplitter)))
    then begin
      debugln(['TAnchorDockHostSite.RemoveControl START ',Caption,' ',dbgs(SiteType),' ',DbgSName(AControl)]);
      if (not UpdatingLayout) and (SiteType=adhstLayout) then
        RemoveControlFromLayout(AControl)
      else
        DockMaster.NeedSimplify(Self);
      UpdateDockCaption;
      debugln(['TAnchorDockHostSite.RemoveControl END ',Caption,' ',dbgs(SiteType),' ',DbgSName(AControl)]);
    end;
  end;
  EnableAutoSizing{$IFDEF DebugDisableAutoSizing}('TAnchorDockHostSite.RemoveControl'){$ENDIF};
end;

procedure TAnchorDockHostSite.InsertControl(AControl: TControl; Index: integer
  );
begin
  DisableAutoSizing;
  try
    inherited InsertControl(AControl, Index);
    if not ((AControl is TAnchorDockSplitter)
            or (AControl is TAnchorDockHeader))
    then
      UpdateDockCaption;
  finally
    EnableAutoSizing;
  end;
end;

procedure TAnchorDockHostSite.UpdateDockCaption(Exclude: TControl);
var
  i: Integer;
  Child: TControl;
  NewCaption, OldCaption: String;
begin
  if csDestroying in ComponentState then exit;
  NewCaption:='';
  for i:=0 to ControlCount-1 do begin
    Child:=Controls[i];
    if Child=Exclude then continue;
    if (Child.HostDockSite=Self) or (Child is TAnchorDockHostSite)
    or (Child is TAnchorDockPageControl) then begin
      if NewCaption<>'' then
        NewCaption:=NewCaption+',';
      NewCaption:=NewCaption+Child.Caption;
    end;
  end;
  OldCaption:=Caption;
  Caption:=NewCaption;
  if (Parent=nil) and not DockMaster.ShowHeaderCaptionFloatingControl then
    Header.Caption:=''
  else
    Header.Caption:=Caption;
  if OldCaption<>Caption then begin
    debugln(['TAnchorDockHostSite.UpdateDockCaption Caption="',Caption,'" NewCaption="',NewCaption,'" HasParent=',Parent<>nil]);
    if Parent is TAnchorDockHostSite then
      TAnchorDockHostSite(Parent).UpdateDockCaption;
    if Parent is TAnchorDockPage then
      TAnchorDockPage(Parent).UpdateDockCaption;
  end;
end;

procedure TAnchorDockHostSite.GetSiteInfo(Client: TControl;
  var InfluenceRect: TRect; MousePos: TPoint; var CanDock: Boolean);
var
  ADockMargin: LongInt;
begin
  GetWindowRect(Handle, InfluenceRect);

  if Parent=nil then begin
    // allow docking outside => enlarge margins
    ADockMargin:=DockMaster.DockOutsideMargin;
    InfluenceRect.Left := InfluenceRect.Left-ADockMargin;
    InfluenceRect.Top := InfluenceRect.Top-ADockMargin;
    InfluenceRect.Right := InfluenceRect.Right+ADockMargin;
    InfluenceRect.Bottom := InfluenceRect.Bottom+ADockMargin;
  end else if Parent is TAnchorDockHostSite then begin
    // do not cover parent site => shrink margins
    ADockMargin:=DockMaster.DockParentMargin;
    ADockMargin:=Min(ADockMargin,Min(ClientWidth,ClientHeight) div 10);
    ADockMargin:=Max(0,ADockMargin);
    InfluenceRect.Left := InfluenceRect.Left+ADockMargin;
    InfluenceRect.Top := InfluenceRect.Top+ADockMargin;
    InfluenceRect.Right := InfluenceRect.Right-ADockMargin;
    InfluenceRect.Bottom := InfluenceRect.Bottom-ADockMargin;
  end;

  CanDock:=(Client is TAnchorDockHostSite)
           and not DockMaster.AutoFreedIfControlIsRemoved(Self,Client);
  //debugln(['TAnchorDockHostSite.GetSiteInfo ',DbgSName(Self),' ',dbgs(BoundsRect),' CanDock=',CanDock]);

  if Assigned(OnGetSiteInfo) then
    OnGetSiteInfo(Self, Client, InfluenceRect, MousePos, CanDock);
end;

function TAnchorDockHostSite.GetPageArea: TRect;
begin
  Result:=Rect(0,0,Width*DockMaster.PageAreaInPercent div 100,
               Height*DockMaster.PageAreaInPercent div 100);
  OffsetRect(Result,(Width*(100-DockMaster.PageAreaInPercent)) div 200,
                    (Height*(100-DockMaster.PageAreaInPercent)) div 200);
end;

procedure TAnchorDockHostSite.ChangeBounds(ALeft, ATop, AWidth,
  AHeight: integer; KeepBase: boolean);
begin
  inherited ChangeBounds(ALeft, ATop, AWidth, AHeight, KeepBase);
  if Header<>nil then UpdateHeaderAlign;
end;

procedure TAnchorDockHostSite.UpdateHeaderAlign;
begin
  if Header=nil then exit;
  case Header.HeaderPosition of
  adlhpAuto:
    if Header.Align in [alLeft,alRight] then begin
      if (ClientHeight>0)
      and ((ClientWidth*100 div ClientHeight)<=DockMaster.HeaderAlignTop) then
        Header.Align:=alTop;
    end else begin
      if (ClientHeight>0)
      and ((ClientWidth*100 div ClientHeight)>=DockMaster.HeaderAlignLeft) then
      begin
        if Application.BidiMode=bdRightToLeft then
          Header.Align:=alRight
        else
          Header.Align:=alLeft;
      end;
    end;
  adlhpLeft: Header.Align:=alLeft;
  adlhpTop: Header.Align:=alTop;
  adlhpRight: Header.Align:=alRight;
  adlhpBottom: Header.Align:=alBottom;
  end;
end;

procedure TAnchorDockHostSite.UpdateHeaderShowing;
begin
  if Header=nil then exit;
  if HeaderNeedsShowing then
    Header.Parent:=Self
  else
    Header.Parent:=nil;
end;

procedure TAnchorDockHostSite.BeginUpdateLayout;
begin
  inc(fUpdateLayout);
  if fUpdateLayout=1 then DockMaster.BeginUpdate;
end;

procedure TAnchorDockHostSite.EndUpdateLayout;
begin
  if fUpdateLayout=0 then RaiseGDBException('TAnchorDockHostSite.EndUpdateLayout');
  dec(fUpdateLayout);
  if fUpdateLayout=0 then
    DockMaster.EndUpdate;
end;

function TAnchorDockHostSite.UpdatingLayout: boolean;
begin
  Result:=(fUpdateLayout>0) or (csDestroying in ComponentState);
end;

procedure TAnchorDockHostSite.SaveLayout(
  LayoutTree: TAnchorDockLayoutTree; LayoutNode: TAnchorDockLayoutTreeNode);
var
  i: Integer;
  Site: TAnchorDockHostSite;
  ChildNode: TAnchorDockLayoutTreeNode;
  Child: TControl;
  Splitter: TAnchorDockSplitter;
  OneControl: TControl;
begin
  if SiteType=adhstOneControl then
    OneControl:=GetOneControl
  else
    OneControl:=nil;
  if (SiteType=adhstOneControl) and (OneControl<>nil)
  and (not (OneControl is TAnchorDockHostSite)) then begin
    LayoutNode.NodeType:=adltnControl;
    LayoutNode.Assign(Self);
    LayoutNode.Name:=OneControl.Name;
    LayoutNode.HeaderPosition:=Header.HeaderPosition;
  end else if (SiteType in [adhstLayout,adhstOneControl]) then begin
    LayoutNode.NodeType:=adltnLayout;
    for i:=0 to ControlCount-1 do begin
      Child:=Controls[i];
      if Child.Owner=Self then continue;
      if (Child is TAnchorDockHostSite) then begin
        Site:=TAnchorDockHostSite(Child);
        ChildNode:=LayoutTree.NewNode(LayoutNode);
        Site.SaveLayout(LayoutTree,ChildNode);
      end else if (Child is TAnchorDockSplitter) then begin
        Splitter:=TAnchorDockSplitter(Child);
        ChildNode:=LayoutTree.NewNode(LayoutNode);
        Splitter.SaveLayout(ChildNode);
      end;
    end;
    LayoutNode.Assign(Self);
    LayoutNode.HeaderPosition:=Header.HeaderPosition;
  end else if SiteType=adhstPages then begin
    LayoutNode.NodeType:=adltnPages;
    for i:=0 to Pages.PageCount-1 do begin
      Site:=Pages.DockPages[i].GetSite;
      if Site<>nil then begin
        ChildNode:=LayoutTree.NewNode(LayoutNode);
        Site.SaveLayout(LayoutTree,ChildNode);
      end;
    end;
    LayoutNode.Assign(Self);
    LayoutNode.HeaderPosition:=Header.HeaderPosition;
  end else
    LayoutNode.NodeType:=adltnNone;
end;

constructor TAnchorDockHostSite.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Visible:=false;
  FHeaderSide:=akTop;
  FHeader:=TAnchorDockHeader.Create(Self);
  FHeader.Align:=alTop;
  FHeader.Parent:=Self;
  FSiteType:=adhstNone;
  UpdateHeaderAlign;
  DragKind:=dkDock;
  DockManager:=TAnchorDockManager.Create(Self);
  UseDockManager:=true;
  DragManager.RegisterDockSite(Self,true);
end;

destructor TAnchorDockHostSite.Destroy;
var
  i: Integer;
begin
  debugln(['TAnchorDockHostSite.Destroy ',DbgSName(Self),' Caption="',Caption,'" Self=',dbgs(Pointer(Self)),' ComponentCount=',ComponentCount,' ControlCount=',ControlCount]);
  for i:=0 to ComponentCount-1 do
    debugln(['TAnchorDockHostSite.Destroy Component ',i,'/',ComponentCount,' ',DbgSName(Components[i])]);
  for i:=0 to ControlCount-1 do
    debugln(['TAnchorDockHostSite.Destroy Control ',i,'/',ControlCount,' ',DbgSName(Controls[i])]);
  FreeAndNil(FPages);
  inherited Destroy;
end;

{ TAnchorDockHeader }

procedure TAnchorDockHeader.PopupMenuPopup(Sender: TObject);
var
  ChangeLockItem: TMenuItem;
  HeaderPosItem: TMenuItem;
  UndockItem: TMenuItem;
  MergeItem: TMenuItem;
begin
  debugln(['TAnchorDockHeader.PopupMenuPopup START']);
  ChangeLockItem:=AddPopupMenuItem('ChangeLockMenuItem', adrsLocked,@ChangeLockButtonClick);
  ChangeLockItem.Checked:=not DockMaster.AllowDragging;
  ChangeLockItem.ShowAlwaysCheckable:=true;

  AddPopupMenuItem('CloseMenuItem',adrsClose,@CloseButtonClick);

  UndockItem:=AddPopupMenuItem('UndockMenuItem',adrsUndock,@UndockButtonClick);
  UndockItem.Visible:=Parent.Parent<>nil;
  MergeItem:=AddPopupMenuItem('MergeMenuItem', adrsMerge, @MergeButtonClick);
  MergeItem.Visible:=TAnchorDockHostSite(Parent).CanMerge;

  HeaderPosItem:=AddPopupMenuItem('HeaderPosMenuItem', adrsHeaderPosition, nil);
  AddPopupMenuItem('HeaderPosAutoMenuItem', adrsAutomatically, @
                   HeaderPositionItemClick, HeaderPosItem);
  AddPopupMenuItem('HeaderPosLeftMenuItem', adrsLeft, @HeaderPositionItemClick,
                    HeaderPosItem);
  AddPopupMenuItem('HeaderPosTopMenuItem', adrsTop, @HeaderPositionItemClick,
                   HeaderPosItem);
  AddPopupMenuItem('HeaderPosRightMenuItem', adrsRight, @HeaderPositionItemClick,
                   HeaderPosItem);
  AddPopupMenuItem('HeaderPosBottomMenuItem', adrsBottom, @HeaderPositionItemClick,
                   HeaderPosItem);
end;

function TAnchorDockHeader.AddPopupMenuItem(AName, ACaption: string;
  const OnClickEvent: TNotifyEvent; AParent: TMenuItem): TMenuItem;
begin
  Result:=TMenuItem(FindComponent(AName));
  if Result=nil then begin
    Result:=TMenuItem.Create(Self);
    Result.Name:=AName;
    if AParent=nil then
      PopupMenu.Items.Add(Result)
    else
      AParent.Add(Result);
  end;
  Result.Caption:=ACaption;
  Result.OnClick:=OnClickEvent;
end;

procedure TAnchorDockHeader.CloseButtonClick(Sender: TObject);
begin
  if Parent is TAnchorDockHostSite then
    TAnchorDockHostSite(Parent).CloseSite;
end;

procedure TAnchorDockHeader.ChangeLockButtonClick(Sender: TObject);
begin
  DockMaster.AllowDragging:=not DockMaster.AllowDragging;
end;

procedure TAnchorDockHeader.HeaderPositionItemClick(Sender: TObject);
var
  Item: TMenuItem;
begin
  if not (Sender is TMenuItem) then exit;
  Item:=TMenuItem(Sender);
  HeaderPosition:=TADLHeaderPosition(Item.Parent.IndexOf(Item));
end;

procedure TAnchorDockHeader.UndockButtonClick(Sender: TObject);
begin
  TAnchorDockHostSite(Parent).Undock;
end;

procedure TAnchorDockHeader.MergeButtonClick(Sender: TObject);
begin
  TAnchorDockHostSite(Parent).Merge;
end;

procedure TAnchorDockHeader.SetHeaderPosition(const AValue: TADLHeaderPosition
  );
begin
  if FHeaderPosition=AValue then exit;
  FHeaderPosition:=AValue;
  if Parent is TAnchorDockHostSite then
    TAnchorDockHostSite(Parent).UpdateHeaderAlign;
end;

procedure TAnchorDockHeader.Paint;
var
  r: TRect;
  TxtH: longint;
begin
  r:=ClientRect;
  Canvas.Frame3d(r,1,bvRaised);
  Canvas.FillRect(r);

  // caption
  if Caption<>'' then begin
    TxtH:=Canvas.TextHeight('ABCMgq');
    if Align in [alLeft,alRight] then begin
      Canvas.Font.Orientation:=900;
      Canvas.TextOut((r.Left+r.Right-TxtH) div 2,r.Bottom,Caption);
    end else begin
      Canvas.Font.Orientation:=0;
      Canvas.TextOut(r.Left,(r.Top+r.Bottom-TxtH) div 2,Caption);
    end;
  end;
end;

procedure TAnchorDockHeader.CalculatePreferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  if WithThemeSpace then ;
  if Align in [alLeft,alRight] then begin
    PreferredWidth:=20;
  end else begin
    PreferredHeight:=20;
  end;
end;

procedure TAnchorDockHeader.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button=mbLeft) and DockMaster.AllowDragging then
    DragManager.DragStart(Parent,false,DockMaster.DragTreshold);
end;

procedure TAnchorDockHeader.UpdateHeaderControls;
begin
  if Align in [alLeft,alRight] then begin
    if CloseButton<>nil then
      CloseButton.Align:=alTop;
  end else begin
    if CloseButton<>nil then
      CloseButton.Align:=alRight;
  end;
  //debugln(['TAnchorDockHeader.UpdateHeaderControls ',dbgs(Align),' ',dbgs(CloseButton.Align)]);
end;

procedure TAnchorDockHeader.SetAlign(Value: TAlign);
begin
  if Value=Align then exit;
  DisableAutoSizing;
  inherited SetAlign(Value);
  UpdateHeaderControls;
  EnableAutoSizing;
end;

procedure TAnchorDockHeader.DoOnShowHint(HintInfo: PHintInfo);
var
  s: String;
  p: LongInt;
  c: String;
begin
  s:=DockMaster.HeaderHint;
  p:=Pos('%c',s);
  if p>0 then begin
    if Parent<>nil then
      c:=Parent.Caption
    else
      c:='';
    s:=copy(s,1,p-1)+c+copy(s,p+2,length(s));
  end;
  //debugln(['TAnchorDockHeader.DoOnShowHint "',s,'" "',DockMaster.HeaderHint,'"']);
  HintInfo^.HintStr:=s;
  inherited DoOnShowHint(HintInfo);
end;

constructor TAnchorDockHeader.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FHeaderPosition:=adlhpAuto;
  FCloseButton:=TAnchorDockCloseButton.Create(Self);
  with FCloseButton do begin
    Name:='CloseButton';
    Parent:=Self;
    Flat:=true;
    BorderWidth:=1;
    ShowHint:=true;
    Hint:=adrsClose;
    OnClick:=@CloseButtonClick;
  end;
  Align:=alTop;
  AutoSize:=true;
  ShowHint:=true;
  PopupMenu:=TPopupMenu.Create(Self);
  PopupMenu.OnPopup:=@PopupMenuPopup;
end;

{ TAnchorDockCloseButton }

constructor TAnchorDockCloseButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  GetCloseGlyph;
  Glyph:=CloseBtnBitmap;
end;

destructor TAnchorDockCloseButton.Destroy;
begin
  ReleaseCloseGlyph;
  inherited Destroy;
end;

procedure TAnchorDockCloseButton.GetCloseGlyph;
var
  BitmapHandle,MaskHandle: HBITMAP;
  OrigBitmap: TBitmap;
begin
  inc(CloseBtnReferenceCount);
  if CloseBtnReferenceCount=1 then begin
    ThemeServices.GetStockImage(idButtonClose,BitmapHandle,MaskHandle);
    OrigBitmap:=TBitmap.Create;
    OrigBitmap.Handle:=BitmapHandle;
    if MaskHandle<>0 then
      OrigBitmap.MaskHandle:=MaskHandle;
    CloseBtnBitmap:=TBitmap.Create;
    CloseBtnBitmap.SetSize(12,12);
    CloseBtnBitmap.Canvas.Brush.Color:=clWhite;
    CloseBtnBitmap.Canvas.FillRect(Rect(0,0,CloseBtnBitmap.Width,CloseBtnBitmap.Height));
    CloseBtnBitmap.Canvas.StretchDraw(Rect(0,0,CloseBtnBitmap.Width,CloseBtnBitmap.Height),OrigBitmap);
    CloseBtnBitmap.Transparent:=true;
    CloseBtnBitmap.TransparentColor:=clWhite;
    OrigBitmap.Free;
  end;
end;

procedure TAnchorDockCloseButton.ReleaseCloseGlyph;
begin
  dec(CloseBtnReferenceCount);
  if CloseBtnReferenceCount=0 then
    FreeAndNil(CloseBtnBitmap);
end;

function TAnchorDockCloseButton.GetGlyphSize(PaintRect: TRect): TSize;
begin
  if PaintRect.Left=0 then ;
  Result.cx:=CloseBtnBitmap.Width;
  Result.cy:=CloseBtnBitmap.Height;
end;

function TAnchorDockCloseButton.DrawGlyph(ACanvas: TCanvas;
  const AClient: TRect; const AOffset: TPoint; AState: TButtonState;
  ATransparent: Boolean; BiDiFlags: Longint): TRect;
begin
  if BiDiFlags=0 then ;
  if ATransparent then ;
  if AState=bsDisabled then ;
  Result:=Rect(0,0,CloseBtnBitmap.Width,CloseBtnBitmap.Height);
  OffsetRect(Result,AClient.Left+AOffset.X,AClient.Top+AOffset.Y);
  ACanvas.Draw(Result.Left,Result.Top,CloseBtnBitmap);
end;

{ TAnchorDockManager }

constructor TAnchorDockManager.Create(ADockSite: TWinControl);
begin
  inherited Create(ADockSite);
  if not (ADockSite is TAnchorDockHostSite) then
    raise Exception.Create('TAnchorDockManager.Create not supported: '+DbgSName(ADockSite));
  FDockSite:=TAnchorDockHostSite(ADockSite);
end;

procedure TAnchorDockManager.BeginUpdate;
begin

end;

procedure TAnchorDockManager.EndUpdate;
begin

end;

procedure TAnchorDockManager.GetControlBounds(Control: TControl; out
  AControlBounds: TRect);
begin
  AControlBounds:=Rect(0,0,0,0);
  debugln(['TAnchorDockManager.GetControlBounds DockSite="',DockSite.Caption,'" Control=',DbgSName(Control)]);
end;

procedure TAnchorDockManager.InsertControl(Control: TControl; InsertAt: TAlign;
  DropCtl: TControl);
begin
  debugln(['TAnchorDockManager.InsertControl DockSite="',DockSite.Caption,'" Control=',Control,' InsertAt=',dbgs(InsertAt),' DropCtl=',DbgSName(DropCtl)]);
end;

procedure TAnchorDockManager.LoadFromStream(Stream: TStream);
begin
  debugln(['TAnchorDockManager.LoadFromStream TODO DockSite="',DockSite.Caption,'"']);
  if Stream=nil then ;
end;

procedure TAnchorDockManager.PositionDockRect(Client, DropCtl: TControl;
  DropAlign: TAlign; var DockRect: TRect);
{ Client = dragged source site (a TAnchorDockHostSite)
  DropCtl is dragged child control of Client
  DropAlign: where on Client DropCtl should be placed
  DockRect: the estimated new bounds of DropCtl
}
var
  Offset: TPoint;
  Inside: Boolean;
begin
  Inside:=(DropCtl=DockSite) or (DockSite.Parent<>nil);
  case DropAlign of
  alLeft:
    if Inside then
      DockRect:=Rect(0,0,Min(Client.Width,DockSite.ClientWidth div 2),DockSite.ClientHeight)
    else
      DockRect:=Rect(-Client.Width,0,0,DockSite.ClientHeight);
  alRight:
    if Inside then begin
      DockRect:=Rect(0,0,Min(Client.Width,DockSite.Width div 2),DockSite.ClientHeight);
      OffsetRect(DockRect,DockSite.ClientWidth-DockRect.Right,0);
    end else
      DockRect:=Bounds(DockSite.ClientWidth,0,Client.Width,DockSite.ClientHeight);
  alTop:
    if Inside then
      DockRect:=Rect(0,0,DockSite.ClientWidth,Min(Client.Height,DockSite.ClientHeight div 2))
    else
      DockRect:=Rect(0,-Client.Height,DockSite.ClientWidth,0);
  alBottom:
    if Inside then begin
      DockRect:=Rect(0,0,DockSite.ClientWidth,Min(Client.Height,DockSite.ClientHeight div 2));
      OffsetRect(DockRect,0,DockSite.ClientHeight-DockRect.Bottom);
    end else
      DockRect:=Bounds(0,DockSite.ClientHeight,DockSite.ClientWidth,Client.Height);
  alClient:
    begin
      // paged docking => show this as center
      DockRect:=DockSite.GetPageArea;
    end;
  else
    exit; // use default
  end;
  Offset:=DockSite.ClientOrigin;
  OffsetRect(DockRect,Offset.X,Offset.Y);
end;

procedure TAnchorDockManager.RemoveControl(Control: TControl);
begin
  debugln(['TAnchorDockManager.RemoveControl DockSite="',DockSite.Caption,'" Control=',DbgSName(Control)]);
end;

procedure TAnchorDockManager.ResetBounds(Force: Boolean);
begin
  debugln(['TAnchorDockManager.ResetBounds DockSite="',DockSite.Caption,'" Force=',Force]);
end;

procedure TAnchorDockManager.SaveToStream(Stream: TStream);
begin
  if STream=nil then ;
  debugln(['TAnchorDockManager.SaveToStream TODO DockSite="',DockSite.Caption,'"']);
end;

function TAnchorDockManager.GetDockEdge(ADockObject: TDragDockObject): boolean;
var
  BestDistance: Integer;

  procedure FindMinDistance(CurAlign: TAlign; CurDistance: integer);
  begin
    if CurDistance<0 then
      CurDistance:=-CurDistance;
    if CurDistance>=BestDistance then exit;
    ADockObject.DropAlign:=CurAlign;
    BestDistance:=CurDistance;
  end;

var
  p: TPoint;
begin
  p:=DockSite.ScreenToClient(ADockObject.DragPos);
  if PtInRect(DockSite.GetPageArea,p) then begin
    // page docking
    ADockObject.DropAlign:=alClient;
  end else begin

    // check side
    BestDistance:=High(Integer);
    FindMinDistance(alLeft,p.X);
    FindMinDistance(alRight,DockSite.ClientWidth-p.X);
    FindMinDistance(alTop,p.Y);
    FindMinDistance(alBottom,DockSite.ClientHeight-p.Y);

    // check inside
    if ((ADockObject.DropAlign=alLeft) and (p.X>=0))
    or ((ADockObject.DropAlign=alTop) and (p.Y>=0))
    or ((ADockObject.DropAlign=alRight) and (p.X<DockSite.ClientWidth))
    or ((ADockObject.DropAlign=alBottom) and (p.Y<DockSite.ClientHeight))
    then
      ADockObject.DropOnControl:=DockSite
    else
      ADockObject.DropOnControl:=nil;
  end;
  //debugln(['TAnchorDockManager.GetDockEdge ADockObject.DropAlign=',dbgs(ADockObject.DropAlign),' ',DbgSName(ADockObject.DropOnControl)]);
  Result:=true;
end;

{ TAnchorDockSplitter }

procedure TAnchorDockSplitter.SetResizeAnchor(const AValue: TAnchorKind);
begin
  inherited SetResizeAnchor(AValue);

  case ResizeAnchor of
  akLeft: Anchors:=AnchorAlign[alLeft];
  akTop: Anchors:=AnchorAlign[alTop];
  akRight: Anchors:=AnchorAlign[alRight];
  akBottom: Anchors:=AnchorAlign[alBottom];
  end;
  //debugln(['TAnchorDockSplitter.SetResizeAnchor ',DbgSName(Self),' ResizeAnchor=',dbgs(ResizeAnchor),' Align=',dbgs(Align),' Anchors=',dbgs(Anchors)]);
end;

procedure TAnchorDockSplitter.UpdateDockBounds;
begin
  FDockBounds:=BoundsRect;
  if Parent<>nil then begin
    FDockParentClientSize.cx:=Parent.ClientWidth;
    FDockParentClientSize.cy:=Parent.ClientHeight;
  end else begin
    FDockParentClientSize.cx:=0;
    FDockParentClientSize.cy:=0;
  end;
end;

procedure TAnchorDockSplitter.SetBounds(ALeft, ATop, AWidth, AHeight: integer);
begin
  DisableAutoSizing;
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  UpdateDockBounds;
  EnableAutoSizing;
end;

procedure TAnchorDockSplitter.SetBoundsKeepDockBounds(ALeft, ATop, AWidth,
  AHeight: integer);
begin
  inherited SetBounds(ALeft,ATop,AWidth,AHeight);
end;

function TAnchorDockSplitter.SideAnchoredControlCount(Side: TAnchorKind
  ): integer;
var
  Sibling: TControl;
  i: Integer;
begin
  Result:=0;
  for i:=0 to AnchoredControlCount-1 do begin
    Sibling:=AnchoredControls[i];
    if Sibling.AnchorSide[OppositeAnchor[Side]].Control=Self then
      inc(Result);
  end;
end;

procedure TAnchorDockSplitter.SaveLayout(
  LayoutNode: TAnchorDockLayoutTreeNode);
begin
  if ResizeAnchor in [akLeft,akRight] then
    LayoutNode.NodeType:=adltnSplitterVertical
  else
    LayoutNode.NodeType:=adltnSplitterHorizontal;
  LayoutNode.Assign(Self);
end;

function TAnchorDockSplitter.HasOnlyOneSibling(Side: TAnchorKind; MinPos,
  MaxPos: integer): TControl;
var
  i: Integer;
  AControl: TControl;
begin
  Result:=nil;
  for i:=0 to AnchoredControlCount-1 do begin
    AControl:=AnchoredControls[i];
    if AControl.AnchorSide[OppositeAnchor[Side]].Control<>Self then continue;
    // AControl is anchored at Side to this splitter
    if (Side in [akLeft,akRight]) then begin
      if (AControl.Left>MaxPos) or (AControl.Left+AControl.Width<MinPos) then
        continue;
    end else begin
      if (AControl.Top>MaxPos) or (AControl.Top+AControl.Height<MinPos) then
        continue;
    end;
    // AControl is in range
    if Result=nil then
      Result:=AControl
    else begin
      // there is more than one control
      Result:=nil;
      exit;
    end;
  end;
end;

constructor TAnchorDockSplitter.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Align:=alNone;
  ResizeAnchor:=akLeft;
  // make sure the splitter never vanish
  Constraints.MinWidth:=2;
  Constraints.MinHeight:=2;
end;

{ TAnchorDockPageControl }

function TAnchorDockPageControl.GetDockPages(Index: integer): TAnchorDockPage;
begin
  Result:=TAnchorDockPage(Page[Index]);
end;

procedure TAnchorDockPageControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ATabIndex: LongInt;
  APage: TCustomPage;
  Site: TAnchorDockHostSite;
begin
  inherited MouseDown(Button, Shift, X, Y);
  ATabIndex := TabIndexAtClientPos(Point(X,Y));
  if (Button = mbLeft) and DockMaster.AllowDragging and (ATabIndex >= 0) then
  begin
    APage:=Page[ATabIndex];
    if (APage.ControlCount>0) and (APage.Controls[0] is TAnchorDockHostSite) then
    begin
      Site:=TAnchorDockHostSite(APage.Controls[0]);
      DragManager.DragStart(Site,false,DockMaster.DragTreshold);
    end;
  end;
end;

procedure TAnchorDockPageControl.UpdateDockCaption(Exclude: TControl);
begin
  if Exclude=nil then ;
end;

procedure TAnchorDockPageControl.RemoveControl(AControl: TControl);
begin
  inherited RemoveControl(AControl);
  if (not (csDestroying in ComponentState)) then begin
    if (PageCount<=1) and (Parent is TAnchorDockHostSite) then
      DockMaster.NeedSimplify(Parent);
  end;
end;

constructor TAnchorDockPageControl.Create(TheOwner: TComponent);
begin
  PageClass:=TAnchorDockPage;
  inherited Create(TheOwner);
end;

{ TAnchorDockPage }

procedure TAnchorDockPage.UpdateDockCaption(Exclude: TControl);
var
  i: Integer;
  Child: TControl;
  NewCaption: String;
begin
  NewCaption:='';
  for i:=0 to ControlCount-1 do begin
    Child:=Controls[i];
    if Child=Exclude then continue;
    if not (Child is TAnchorDockHostSite) then continue;
    if NewCaption<>'' then
      NewCaption:=NewCaption+',';
    NewCaption:=NewCaption+Child.Caption;
  end;
  //debugln(['TAnchorDockPage.UpdateDockCaption ',Caption,' ',NewCaption]);
  if Caption=NewCaption then exit;
  Caption:=NewCaption;
  if Parent is TAnchorDockPageControl then
    TAnchorDockPageControl(Parent).UpdateDockCaption;
end;

procedure TAnchorDockPage.InsertControl(AControl: TControl; Index: integer);
begin
  inherited InsertControl(AControl, Index);
  //debugln(['TAnchorDockPage.InsertControl ',DbgSName(AControl)]);
  if AControl is TAnchorDockHostSite then begin
    if TAnchorDockHostSite(AControl).Header<>nil then
      TAnchorDockHostSite(AControl).Header.Parent:=nil;
    UpdateDockCaption;
  end;
end;

procedure TAnchorDockPage.RemoveControl(AControl: TControl);
begin
  inherited RemoveControl(AControl);
  if (GetSite=nil) and (not (csDestroying in ComponentState))
  and (Parent<>nil) and (not (csDestroying in Parent.ComponentState)) then
    DockMaster.NeedSimplify(Self);
end;

function TAnchorDockPage.GetSite: TAnchorDockHostSite;
begin
  Result:=nil;
  if ControlCount=0 then exit;
  if not (Controls[0] is TAnchorDockHostSite) then exit;
  Result:=TAnchorDockHostSite(Controls[0]);
end;

initialization
  DockMaster:=TAnchorDockMaster.Create(nil);

finalization
  FreeAndNil(DockMaster);

end.

