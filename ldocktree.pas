{  $Id$  }
{
 /***************************************************************************
                               LDockTree.pas
                             -----------------

 ***************************************************************************/

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

  Author: Mattias Gaertner

  Abstract:
    This unit contains TLazDockTree, the default TDockTree for the LCL.
}
unit LDockTree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LCLType, Forms, Controls, ExtCtrls, Menus,
  LCLStrConsts;
  
type
  TLazDockPages = class;
  TLazDockPage = class;
  TLazDockSplitter = class;

  { TLazDockZone }

  TLazDockZone = class(TDockZone)
  private
    FPage: TLazDockPage;
    FPages: TLazDockPages;
    FSplitter: TLazDockSplitter;
  public
    destructor Destroy; override;
    function GetCaption: string;
    function GetParentControl: TWinControl;
    property Splitter: TLazDockSplitter read FSplitter write FSplitter;
    property Pages: TLazDockPages read FPages write FPages;
    property Page: TLazDockPage read FPage write FPage;
  end;

  { TLazDockTree }

  TLazDockTree = class(TDockTree)
  private
    FAutoFreeDockSite: boolean;
  protected
    procedure UndockControlForDocking(AControl: TControl);
    procedure BreakAnchors(Zone: TDockZone);
    procedure CreateDockLayoutHelperControls(Zone: TLazDockZone);
    procedure AnchorDockLayout(Zone: TLazDockZone);
  public
    constructor Create(TheDockSite: TWinControl); override;
    destructor Destroy; override;
    procedure InsertControl(AControl: TControl; InsertAt: TAlign;
                            DropControl: TControl); override;
    procedure BuildDockLayout(Zone: TLazDockZone);
    procedure FindBorderControls(Zone: TLazDockZone; Side: TAnchorKind;
                                 var List: TFPList);
    function FindBorderControl(Zone: TLazDockZone; Side: TAnchorKind): TControl;
    function GetAnchorControl(Zone: TLazDockZone; Side: TAnchorKind;
                              OutSide: boolean): TControl;
  public
    property AutoFreeDockSite: boolean read FAutoFreeDockSite write FAutoFreeDockSite;
  end;
  
  { TLazDockForm
    The default DockSite for a TLazDockTree
  
    If DockZone is a leaf (DockZone.ChildCount=0) then
      Only child control is DockZone.ChildControl
    else
      if DockZone.Orientation in [doHorizontal,doVertical] then
        Child controls are TLazDockForm and TSplitter
      else if DockZone.Orientation=doPages then
        Child control is a TLazDockPages
  }

  TLazDockForm = class(TCustomForm)
  private
    FDockZone: TDockZone;
    FPageControl: TLazDockPages;
  public
    property DockZone: TDockZone read FDockZone;
    property PageControl: TLazDockPages read FPageControl;
  end;
  
  { TLazDockPage
    Pretty the same as a TLazDockForm but as page of a TLazDockPages }

  TLazDockPage = class(TCustomPage)
  private
    FDockZone: TDockZone;
    function GetPageControl: TLazDockPages;
  public
    property DockZone: TDockZone read FDockZone;
    property PageControl: TLazDockPages read GetPageControl;
  end;
  
  { TLazDockPages }

  TLazDockPages = class(TCustomNotebook)
  private
    function GetActiveNotebookPageComponent: TLazDockPage;
    function GetNoteBookPage(Index: Integer): TLazDockPage;
    procedure SetActiveNotebookPageComponent(const AValue: TLazDockPage);
  public
    constructor Create(TheOwner: TComponent); override;
    property Page[Index: Integer]: TLazDockPage read GetNoteBookPage;
    property ActivePageComponent: TLazDockPage read GetActiveNotebookPageComponent
                                           write SetActiveNotebookPageComponent;
    property Pages;
  end;
  
  TLazDockSplitter = class(TCustomSplitter)
  end;
  
  //----------------------------------------------------------------------------
  
  { TAnchoredDockManager }

  TAnchoredDockManager = class(TDockManager)
  private
    FSplitterSize: integer;
    FUpdateCount: integer;
  protected
    procedure DeleteSideSplitter(Splitter: TLazDockSplitter; Side: TAnchorKind;
                                 NewAnchorControl: TControl);
    procedure CombineSpiralSplitterPair(Splitter1, Splitter2: TLazDockSplitter);
    procedure DeletePage(Page: TLazDockPage);
    procedure DeletePages(Pages: TLazDockPages);
    procedure DeleteDockForm(ADockForm: TLazDockForm);
    function GetAnchorDepth(AControl: TControl; Side: TAnchorKind): Integer;
  public
    constructor Create;
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    procedure GetControlBounds(Control: TControl;
                               out AControlBounds: TRect); override;
    procedure DockControl(Control: TControl; InsertAt: TAlign;
                          DropCtl: TControl);
    procedure UndockControl(Control: TControl; Float: boolean);
    procedure InsertControl(Control: TControl; InsertAt: TAlign;
                            DropCtl: TControl); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure PaintSite(DC: HDC); override;
    procedure PositionDockRect(Client, DropCtl: TControl; DropAlign: TAlign;
                               var DockRect: TRect); override;
    procedure RemoveControl(Control: TControl); override;
    procedure ResetBounds(Force: Boolean); override;
    procedure SaveToStream(Stream: TStream); override;
    procedure SetReplacingControl(Control: TControl); override;
    procedure ReplaceAnchoredControl(OldControl, NewControl: TControl);
    property SplitterSize: integer read FSplitterSize write FSplitterSize default 5;
  end;
  
  
  TCustomLazControlDocker = class;
  
  { TCustomLazDockingManager }

  TCustomLazDockingManager = class(TComponent)
  private
    FDockerCount: Integer;
    FDockers: TFPList;
    FManager: TAnchoredDockManager;
    function GetDockers(Index: Integer): TCustomLazControlDocker;
  protected
    procedure Remove(Docker: TCustomLazControlDocker);
    function Add(Docker: TCustomLazControlDocker): Integer;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Manager: TAnchoredDockManager read FManager;
    property DockerCount: Integer read FDockerCount;
    property Dockers[Index: Integer]: TCustomLazControlDocker read GetDockers;
  end;
  
  { TLazDockingManager }

  TLazDockingManager = class(TCustomLazDockingManager)
  published
  end;
  
  { TCustomLazControlDocker - a component to mark a form for the TLazDockingManager }

  TCustomLazControlDocker = class(TComponent)
    procedure PopupMenuItemClick(Sender: TObject);
  private
    FControl: TControl;
    FExtendPopupMenu: boolean;
    FManager: TCustomLazDockingManager;
    FPopupMenuItem: TMenuItem;
    procedure SetControl(const AValue: TControl);
    procedure SetExtendPopupMenu(const AValue: boolean);
    procedure SetManager(const AValue: TCustomLazDockingManager);
  protected
    procedure UpdatePopupMenu;
    procedure Loaded; override;
  public
    constructor Create(TheOwner: TComponent); override;
    property Control: TControl read FControl write SetControl;
    property Manager: TCustomLazDockingManager read FManager write SetManager;
    property ExtendPopupMenu: boolean read FExtendPopupMenu write SetExtendPopupMenu;
    property PopupMenuItem: TMenuItem read FPopupMenuItem;
  end;
  
  { TLazControlDocker }

  TLazControlDocker = class(TCustomLazControlDocker)
  published
    property Control;
    property Manager;
    property ExtendPopupMenu;
  end;

const
  DockAlignOrientations: array[TAlign] of TDockOrientation = (
    doPages,     //alNone,
    doVertical,  //alTop,
    doVertical,  //alBottom,
    doHorizontal,//alLeft,
    doHorizontal,//alRight,
    doPages,     //alClient,
    doPages      //alCustom
    );

implementation

{ TLazDockPages }

function TLazDockPages.GetActiveNotebookPageComponent: TLazDockPage;
begin
  Result:=TLazDockPage(GetActiveNotebookPageComponent);
end;

function TLazDockPages.GetNoteBookPage(Index: Integer): TLazDockPage;
begin
  Result:=TLazDockPage(inherited Page[Index]);
end;

procedure TLazDockPages.SetActiveNotebookPageComponent(
  const AValue: TLazDockPage);
begin
  ActivePageComponent:=AValue;
end;

constructor TLazDockPages.Create(TheOwner: TComponent);
begin
  PageClass:=TLazDockPage;
  inherited Create(TheOwner);
end;

{ TLazDockTree }

procedure TLazDockTree.UndockControlForDocking(AControl: TControl);
var
  AWinControl: TWinControl;
begin
  // undock AControl
  if AControl is TWinControl then begin
    AWinControl:=TWinControl(AControl);
    if AWinControl.DockManager<>nil then begin
      // TODO
    end;
  end;
  if AControl.Parent<>nil then begin
    AControl.Parent:=nil;
  end;
end;

procedure TLazDockTree.BreakAnchors(Zone: TDockZone);
begin
  if Zone=nil then exit;
  if Zone.ChildControl<>nil then begin
    Zone.ChildControl.AnchorSide[akLeft].Control:=nil;
    Zone.ChildControl.AnchorSide[akTop].Control:=nil;
    Zone.ChildControl.Anchors:=[akLeft,akTop];
  end;
  BreakAnchors(Zone.FirstChild);
  BreakAnchors(Zone.NextSibling);
end;

procedure TLazDockTree.CreateDockLayoutHelperControls(Zone: TLazDockZone);
var
  ParentPages: TLazDockPages;
  ZoneIndex: LongInt;
begin
  if Zone=nil then exit;

  // create needed TLazDockSplitter
  if (Zone.Parent<>nil)
  and (Zone.Parent.Orientation in [doVertical,doHorizontal])
  and (Zone.PrevSibling<>nil) then begin
    // a zone with a side sibling -> needs a TLazDockSplitter
    if Zone.Splitter=nil then begin
      Zone.Splitter:=TLazDockSplitter.Create(nil);
    end;
  end else if Zone.Splitter<>nil then begin
    // zone no longer needs the splitter
    Zone.Splitter.Free;
    Zone.Splitter:=nil;
  end;

  // create needed TLazDockPages
  if (Zone.Orientation=doPages) then begin
    // a zone of pages -> needs a TLazDockPages
    if Zone.FirstChild=nil then
      RaiseGDBException('TLazDockTree.CreateDockLayoutHelperControls Inconsistency: doPages without childs');
    if (Zone.Pages=nil) then begin
      Zone.Pages:=TLazDockPages.Create(nil);
    end;
  end else if Zone.Pages<>nil then begin
    // zone no longer needs the pages
    Zone.Pages.Free;
    Zone.Pages:=nil;
  end;

  // create needed TLazDockPage
  if (Zone.Parent<>nil)
  and (Zone.Parent.Orientation=doPages) then begin
    // a zone as page -> needs a TLazDockPage
    if (Zone.Page=nil) then begin
      ParentPages:=TLazDockZone(Zone.Parent).Pages;
      ZoneIndex:=Zone.GetIndex;
      ParentPages.Pages.Insert(ZoneIndex,Zone.GetCaption);
      Zone.Page:=ParentPages.Page[ZoneIndex];
    end;
  end else if Zone.Page<>nil then begin
    // zone no longer needs the page
    Zone.Page.Free;
    Zone.Page:=nil;
  end;

  // create controls for childs and siblings
  CreateDockLayoutHelperControls(Zone.FirstChild as TLazDockZone);
  CreateDockLayoutHelperControls(Zone.NextSibling as TLazDockZone);
end;

procedure TLazDockTree.AnchorDockLayout(Zone: TLazDockZone);
// setup all anchors between all docked controls and helper controls
var
  AnchorControls: array[TAnchorKind] of TControl;
  a: TAnchorKind;
  SplitterSide: TAnchorKind;
  CurControl: TControl;
  NewAnchors: TAnchors;
begin
  if Zone=nil then exit;
  
  // get outside anchor controls
  for a:=Low(TAnchorKind) to High(TAnchorKind) do
    AnchorControls[a]:=GetAnchorControl(Zone,a,true);

  // anchor splitter
  if (Zone.Splitter<>nil) then begin
    if Zone.Parent.Orientation=doHorizontal then
      SplitterSide:=akLeft
    else
      SplitterSide:=akTop;
    // IMPORTANT: first set the AnchorSide, then set the Anchors
    NewAnchors:=[akLeft,akRight,akTop,akBottom]-[SplitterSide];
    for a:=Low(TAnchorKind) to High(TAnchorKind) do
      if a in NewAnchors then
        Zone.Splitter.AnchorSide[a].Control:=AnchorControls[a];
    Zone.Splitter.Anchors:=NewAnchors;
    AnchorControls[SplitterSide]:=Zone.Splitter;
  end;
  
  // anchor pages
  if Zone.Pages<>nil then
    CurControl:=Zone.Pages
  else
    CurControl:=Zone.ChildControl;
  if CurControl<>nil then begin
    // IMPORTANT: first set the AnchorSide, then set the Anchors
    for a:=Low(TAnchorKind) to High(TAnchorKind) do
      CurControl.AnchorSide[a].Control:=AnchorControls[a];
    CurControl.Anchors:=[akLeft,akRight,akTop,akBottom];
  end;

  // anchor controls for childs and siblings
  AnchorDockLayout(Zone.FirstChild as TLazDockZone);
  AnchorDockLayout(Zone.NextSibling as TLazDockZone);
end;

constructor TLazDockTree.Create(TheDockSite: TWinControl);
begin
  SetDockZoneClass(TLazDockZone);
  if TheDockSite=nil then begin
    TheDockSite:=TLazDockForm.Create(nil);
    TheDockSite.DockManager:=Self;
    FAutoFreeDockSite:=true;
  end;
  inherited Create(TheDockSite);
end;

destructor TLazDockTree.Destroy;
begin
  if FAutoFreeDockSite then begin
    if DockSite.DockManager=Self then
      DockSite.DockManager:=nil;
    DockSite.Free;
    DockSite:=nil;
  end;
  inherited Destroy;
end;

procedure TLazDockTree.InsertControl(AControl: TControl; InsertAt: TAlign;
  DropControl: TControl);
{ undocks AControl and docks it into the tree
  It creates a new TDockZone for AControl and inserts it as a new leaf.
  It automatically changes the tree, so that the parent of the new TDockZone
  will have the Orientation for InsertAt.
  
  Example 1:

    A newly created TLazDockTree has only a DockSite (TLazDockForm) and a single
    TDockZone - the RootZone, which has as ChildControl the DockSite.
    
    Visual:
      +-DockSite--+
      |           |
      +-----------+
    Tree of TDockZone:
      RootZone (DockSite,doNoOrient)


  Inserting the first control:  InsertControl(Form1,alLeft,nil);
    Visual:
      +-DockSite---+
      |+--Form1---+|
      ||          ||
      |+----------+|
      +------------+
    Tree of TDockZone:
      RootZone (DockSite,doHorizontal)
       +-Zone2 (Form1,doNoOrient)


  Dock Form2 right of Form1:  InsertControl(Form2,alLeft,Form1);
    Visual:
      +-DockSite----------+
      |+-Form1-+|+-Form2-+|
      ||        ||       ||
      |+-------+|+-------+|
      +-------------------+
    Tree of TDockZone:
      RootZone (DockSite,doHorizontal)
       +-Zone2 (Form1,doNoOrient)
       +-Zone3 (Form2,doNoOrient)
}
const
  SplitterWidth = 5;
  SplitterHeight = 5;
var
  DropZone: TDockZone;
  NewZone: TLazDockZone;
  NewOrientation: TDockOrientation;
  NeedNewParentZone: Boolean;
  NewParentZone: TDockZone;
  OldParentZone: TDockZone;
  NewBounds: TRect;
  ASibling: TDockZone;
begin
  if DropControl=nil then
    DropControl:=DockSite;
  DropZone:=RootZone.FindZone(DropControl);
  if DropZone=nil then
    raise Exception.Create('TLazDockTree.InsertControl DropControl is not part of this TDockTree');

  NewOrientation:=DockAlignOrientations[InsertAt];

  // undock
  UndockControlForDocking(AControl);
  
  // dock
  // create a new zone for AControl
  NewZone:=DockZoneClass.Create(Self,AControl) as TLazDockZone;
  
  // insert new zone into tree
  if (DropZone=RootZone) and (RootZone.FirstChild=nil) then begin
    // this is the first child
    debugln('TLazDockTree.InsertControl First Child');
    RootZone.Orientation:=NewOrientation;
    RootZone.AddAsFirstChild(NewZone);
    if not AControl.Visible then
      DockSite.Visible:=false;
    DockSite.BoundsRect:=AControl.BoundsRect;
    AControl.Parent:=DockSite;
    if AControl.Visible then
      DockSite.Visible:=true;
  end else begin
    // there are already other childs

    // optimize DropZone
    if (DropZone.ChildCount>0)
    and (NewOrientation in [doHorizontal,doVertical])
    and ((DropZone.Orientation=NewOrientation)
         or (DropZone.Orientation=doNoOrient))
    then begin
      // docking on a side of an inner node is the same as docking to a side of
      // a child
      if InsertAt in [alLeft,alTop] then
        DropZone:=DropZone.FirstChild
      else
        DropZone:=DropZone.GetLastChild;
    end;
    
    // insert a new Parent Zone if needed
    NeedNewParentZone:=true;
    if (DropZone.Parent<>nil) then begin
      if (DropZone.Orientation=doNoOrient) then
        NeedNewParentZone:=false;
      if (DropZone.Orientation=NewOrientation) then
        NeedNewParentZone:=false;
    end;
    if NeedNewParentZone then begin
      // insert a new zone between current DropZone.Parent and DropZone
      // this new zone will become the new DropZone.Parent
      OldParentZone:=DropZone.Parent;
      NewParentZone:=DockZoneClass.Create(Self,nil);
      if OldParentZone<>nil then
        OldParentZone.ReplaceChild(DropZone,NewParentZone);
      NewParentZone.AddAsFirstChild(DropZone);
    end;
    
    // adjust Orientation in tree
    if DropZone.Parent.Orientation=doNoOrient then
      DropZone.Parent.Orientation:=NewOrientation;
    if DropZone.Parent.Orientation<>NewOrientation then
      RaiseGDBException('TLazDockTree.InsertControl Inconsistency DropZone.Orientation<>NewOrientation');

    // insert new node
    if DropZone.Parent=nil then
      RaiseGDBException('TLazDockTree.InsertControl Inconsistency DropZone.Parent=nil');
    if InsertAt in [alLeft,alTop] then
      DropZone.Parent.AddAsFirstChild(NewZone)
    else
      DropZone.Parent.AddAsLastChild(NewZone);
      
    // break anchors and resize DockSite
    BreakAnchors(RootZone);
    NewBounds:=DockSite.BoundsRect;
    case InsertAt of
    alLeft:  dec(NewBounds.Left,SplitterWidth+AControl.Width);
    alRight: inc(NewBounds.Right,SplitterWidth+AControl.Width);
    alTop:   dec(NewBounds.Top,SplitterHeight+AControl.Height);
    alBottom:inc(NewBounds.Bottom,SplitterHeight+AControl.Height);
    else     // no change
    end;
    DockSite.BoundsRect:=NewBounds;
    
    // add AControl to DockSite
    AControl.Visible:=false;
    AControl.Parent:=nil;
    AControl.Align:=alNone;
    AControl.Anchors:=[akLeft,akTop];
    AControl.AnchorSide[akLeft].Control:=nil;
    AControl.AnchorSide[akTop].Control:=nil;
    AControl.AutoSize:=false;
    // resize control
    RaiseGDBException('TLazDockTree.InsertControl TODO resize control');
    if NewOrientation in [doHorizontal,doVertical] then begin
      ASibling:=NewZone.PrevSibling;
      if ASibling=nil then ASibling:=NewZone.NextSibling;
      if ASibling<>nil then begin
        if NewOrientation=doHorizontal then
          AControl.Height:=ASibling.Height
        else
          AControl.Width:=ASibling.Width;
      end;
    end;
    AControl.Parent:=NewZone.GetParentControl;

    // Build dock layout (anchors, splitters, pages)
    BuildDockLayout(RootZone as TLazDockZone);
  end;
end;

procedure TLazDockTree.BuildDockLayout(Zone: TLazDockZone);
begin
  BreakAnchors(Zone);
  CreateDockLayoutHelperControls(Zone);
  AnchorDockLayout(Zone);
end;

procedure TLazDockTree.FindBorderControls(Zone: TLazDockZone; Side: TAnchorKind;
  var List: TFPList);
begin
  if List=nil then List:=TFPList.Create;
  if Zone=nil then exit;
  
  if (Zone.Splitter<>nil) and (Zone.Parent<>nil)
  and (Zone.Orientation=doVertical) then begin
    // this splitter is leftmost, topmost, bottommost
    if Side in [akLeft,akTop,akBottom] then
      List.Add(Zone.Splitter);
    if Side=akLeft then begin
      // the splitter fills the whole left side => no more controls
      exit;
    end;
  end;
  if (Zone.Splitter<>nil) and (Zone.Parent<>nil)
  and (Zone.Orientation=doHorizontal) then begin
    // this splitter is topmost, leftmost, rightmost
    if Side in [akTop,akLeft,akRight] then
      List.Add(Zone.Splitter);
    if Side=akTop then begin
      // the splitter fills the whole top side => no more controls
      exit;
    end;
  end;
  if Zone.ChildControl<>nil then begin
    // the ChildControl fills the whole zone (except for the splitter)
    List.Add(Zone.ChildControl);
    exit;
  end;
  if Zone.Pages<>nil then begin
    // the pages fills the whole zone (except for the splitter)
    List.Add(Zone.Pages);
    exit;
  end;

  // go recursively through all child zones
  if (Zone.Parent<>nil) and (Zone.Orientation in [doVertical,doHorizontal])
  and (Zone.FirstChild<>nil) then
  begin
    if Side in [akLeft,akTop] then
      FindBorderControls(Zone.FirstChild as TLazDockZone,Side,List)
    else
      FindBorderControls(Zone.GetLastChild as TLazDockZone,Side,List);
  end;
end;

function TLazDockTree.FindBorderControl(Zone: TLazDockZone; Side: TAnchorKind
  ): TControl;
var
  List: TFPList;
begin
  Result:=nil;
  if Zone=nil then exit;
  List:=nil;
  FindBorderControls(Zone,Side,List);
  if (List=nil) or (List.Count=0) then
    Result:=DockSite
  else
    Result:=TControl(List[0]);
  List.Free;
end;

function TLazDockTree.GetAnchorControl(Zone: TLazDockZone; Side: TAnchorKind;
  OutSide: boolean): TControl;
// find a control to anchor the Zone's Side
begin
  if Zone=nil then begin
    Result:=DockSite;
    exit;
  end;

  if not OutSide then begin
    // also check the Splitter and the Page
    if (Side=akLeft)
    and (Zone.Parent<>nil) and (Zone.Parent.Orientation=doHorizontal)
    and (Zone.Splitter<>nil) then begin
      Result:=Zone.Splitter;
      exit;
    end;
    if (Side=akTop)
    and (Zone.Parent<>nil) and (Zone.Parent.Orientation=doVertical)
    and (Zone.Splitter<>nil) then begin
      Result:=Zone.Splitter;
      exit;
    end;
    if (Zone.Page<>nil) then begin
      Result:=Zone.Page;
      exit;
    end;
  end;

  // search the neigbour zones:
  Result:=DockSite;
  if (Zone.Parent=nil) then exit;
  case Zone.Parent.Orientation of
  doHorizontal:
    if (Side=akLeft) and (Zone.PrevSibling<>nil) then
      Result:=FindBorderControl(Zone.PrevSibling as TLazDockZone,akRight)
    else if (Side=akRight) and (Zone.NextSibling<>nil) then
      Result:=FindBorderControl(Zone.NextSibling as TLazDockZone,akLeft)
    else
      Result:=GetAnchorControl(Zone.Parent as TLazDockZone,Side,false);
  doVertical:
    if (Side=akTop) and (Zone.PrevSibling<>nil) then
      Result:=FindBorderControl(Zone.PrevSibling as TLazDockZone,akBottom)
    else if (Side=akBottom) and (Zone.NextSibling<>nil) then
      Result:=FindBorderControl(Zone.NextSibling as TLazDockZone,akTop)
    else
      Result:=GetAnchorControl(Zone.Parent as TLazDockZone,Side,false);
  doPages:
    Result:=GetAnchorControl(Zone.Parent as TLazDockZone,Side,false);
  end;
end;

{ TLazDockZone }

destructor TLazDockZone.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FSplitter);
  FreeAndNil(FPage);
  FreeAndNil(FPages);
end;

function TLazDockZone.GetCaption: string;
begin
  if ChildControl<>nil then
    Result:=ChildControl.Caption
  else
    Result:=IntToStr(GetIndex);
end;

function TLazDockZone.GetParentControl: TWinControl;
var
  Zone: TDockZone;
begin
  Result:=nil;
  Zone:=Parent;
  while Zone<>nil do begin
    if Zone.Orientation=doPages then begin
      Result:=(Zone as TLazDockZone).Pages;
      exit;
    end;
    if (Zone.Parent=nil) then begin
      if Zone.ChildControl is TWinControl then
        Result:=TWinControl(Zone.ChildControl);
      exit;
    end;
    Zone:=Zone.Parent;
  end;
end;

{ TAnchoredDockManager }

procedure TAnchoredDockManager.DeleteSideSplitter(Splitter: TLazDockSplitter;
  Side: TAnchorKind; NewAnchorControl: TControl);
var
  SplitterParent: TWinControl;
  i: Integer;
  CurControl: TControl;
begin
  SplitterParent:=Splitter.Parent;
  SplitterParent.DisableAlign;
  try
    for i:=0 to SplitterParent.ControlCount-1 do begin
      CurControl:=SplitterParent.Controls[i];
      if CurControl.AnchorSide[Side].Control=Splitter then begin
        CurControl.AnchorSide[Side].Control:=NewAnchorControl;
      end;
    end;
    Splitter.Free;
  finally
    SplitterParent.EnableAlign;
  end;
end;

procedure TAnchoredDockManager.CombineSpiralSplitterPair(Splitter1,
  Splitter2: TLazDockSplitter);
{  Anchor all controls anchored to Splitter2 to Splitter1,
   extend Splitter1,
   delete Splitter2.

   Example:

   Four spiral splitters:

     Before:
              |
           A  |
     ---------|
       | +--+ |  C
     B | |  | |
       | +--+ |
       | ----------
       |   D

     The left and right splitter will be combined to one.

     After:
              |
           A  |
       -------|
              |  C
            B |
              |
              |------
              |   D
  }
  
  procedure MoveAnchorSide(AControl: TControl; Side: TAnchorKind);
  begin
    if AControl.AnchorSide[Side].Control=Splitter2 then
      AControl.AnchorSide[Side].Control:=Splitter1;
  end;
  
  procedure EnlargeSplitter(Side: TAnchorKind);
  begin
    if GetAnchorDepth(Splitter1,Side)<GetAnchorDepth(Splitter2,Side) then
      Splitter1.AnchorSide[Side].Assign(Splitter2.AnchorSide[Side]);
  end;
  
var
  LeftRightSplitter: boolean;
  ParentControl: TWinControl;
  i: Integer;
  CurControl: TControl;
begin
  // check splitters have the same Parent
  ParentControl:=Splitter1.Parent;
  if (ParentControl=nil) then
    RaiseGDBException('TAnchoredDockManager.CombineSpiralSplitterPair Inconsistency: Parent=nil');
  if (ParentControl<>Splitter2.Parent) then
    RaiseGDBException('TAnchoredDockManager.CombineSpiralSplitterPair Inconsistency: Splitters not siblings');
  // check splitters have same orientation
  LeftRightSplitter:=(Splitter1.ResizeAnchor in [akLeft,akRight]);
  if LeftRightSplitter<>(Splitter2.ResizeAnchor in [akLeft,akRight]) then
    RaiseGDBException('TAnchoredDockManager.CombineSpiralSplitterPair Inconsistency: different orientation');

  ParentControl.DisableAlign;
  try
    // move incident anchors from Splitter2 to Splitter1
    for i:=0 to ParentControl.ControlCount-1 do begin
      CurControl:=ParentControl.Controls[i];
      if CurControl=Splitter1 then continue;
      if CurControl=Splitter2 then continue;
      if LeftRightSplitter then begin
        MoveAnchorSide(CurControl,akLeft);
        MoveAnchorSide(CurControl,akRight);
      end else begin
        MoveAnchorSide(CurControl,akTop);
        MoveAnchorSide(CurControl,akBottom);
      end;
    end;
    
    // enlarge Splitter1
    if LeftRightSplitter then begin
      // enlarge Splitter1 to top and bottom
      EnlargeSplitter(akTop);
      EnlargeSplitter(akBottom);
    end else begin
      // enlarge Splitter1 to left and right
      EnlargeSplitter(akLeft);
      EnlargeSplitter(akRight);
    end;
    
    // delete Splitter2
    Splitter2.Free;
  finally
    ParentControl.EnableAlign;
  end;
end;

procedure TAnchoredDockManager.DeletePage(Page: TLazDockPage);
var
  Pages: TLazDockPages;
begin
  Pages:=Page.PageControl;
  Page.Free;
  if Pages.PageCount=0 then
    DeletePages(Pages);
end;

procedure TAnchoredDockManager.DeletePages(Pages: TLazDockPages);
begin
  if Pages.Parent<>nil then
    UndockControl(Pages,false);
  Pages.Free;
end;

procedure TAnchoredDockManager.DeleteDockForm(ADockForm: TLazDockForm);
begin
  if ADockForm.Parent<>nil then
    UndockControl(ADockForm,false);
  ADockForm.Free;
end;

function TAnchoredDockManager.GetAnchorDepth(AControl: TControl;
  Side: TAnchorKind): Integer;
var
  NewControl: TControl;
begin
  Result:=0;
  while (AControl<>nil) do begin
    inc(Result);
    NewControl:=AControl.AnchorSide[Side].Control;
    if NewControl=nil then break; // loose end
    if NewControl.Parent<>AControl.Parent then break; // parent end
    if Result>AControl.Parent.ControlCount then break; // circle
    AControl:=NewControl;
  end;
end;

constructor TAnchoredDockManager.Create;
begin
  FSplitterSize:=5;
end;

procedure TAnchoredDockManager.BeginUpdate;
begin
  inc(FUpdateCount);
end;

procedure TAnchoredDockManager.EndUpdate;
begin
  if FUpdateCount<=0 then
    RaiseGDBException('TAnchoredDockManager.EndUpdate');
  dec(FUpdateCount);
  if FUpdateCount=0 then begin

  end;
end;

procedure TAnchoredDockManager.GetControlBounds(Control: TControl;
  out AControlBounds: TRect);
begin
  AControlBounds:=Control.BoundsRect;
end;

{-------------------------------------------------------------------------------
  procedure TAnchoredDockManager.DockControl(Control: TControl;
    InsertAt: TAlign; DropCtl: TControl);

  Docks Control to or into DropCtl.
  Control.Parent must be nil.

  If InsertAt in [alLeft,alTop,alRight,alBottom] then Control will be docked to
  the side of DropCtl.
  Otherwise it is docked as Page to a TLazDockPages.

  Docking to a side:
    If DockCtl.Parent=nil then a parent will be created via
    DropCtl.ManualFloat.
    Then Control is added as child to DockCtl.Parent.
    Then a Splitter is added.
    Then all three are anchored.

  Docking as page:
    if DropCtl.Parent is not a TLazDockPage then a new TLazDockPages is created
    and replaces DropCtl and DropCtl is added as page.
    Then Control is added as page.
-------------------------------------------------------------------------------}
procedure TAnchoredDockManager.DockControl(Control: TControl;
  InsertAt: TAlign; DropCtl: TControl);
var
  Splitter: TLazDockSplitter;
  NewDropCtlBounds: TRect;
  NewControlBounds: TRect;
  NewDropCtlWidth: Integer;
  SplitterBounds: TRect;
  a: TAnchorKind;
  ControlAnchor: TAnchorKind;
  DropCtlAnchor: TAnchorKind;
  NewDropCtlHeight: Integer;
  SplitterWidth: LongInt;
  SplitterHeight: LongInt;
  DockPages: TLazDockPages;
  DropCtlPage: TLazDockPage;
  NewPageIndex: Integer;
  NewPage: TLazDockPage;
begin
  if Control.Parent<>nil then
    RaiseGDBException('TAnchoredDockManager.InsertControl Control.Parent<>nil');

  // dock Control to DropCtl
  case InsertAt of
  alLeft,alTop,alRight,alBottom:
    begin
      // dock Control to a side of DropCtl
      // e.g. alLeft: insert Control to the left of DropCtl

      DropCtlAnchor:=MainAlignAnchor[InsertAt];
      ControlAnchor:=OppositeAnchor[DropCtlAnchor];

      // make sure, there is a parent HostSite
      if DropCtl.Parent=nil then begin
        DropCtl.FloatingDockSiteClass:=TLazDockForm;
        DropCtl.ManualFloat(DropCtl.BoundsRect);
        if DropCtl.Parent=nil then begin
          RaiseGDBException('TAnchoredDockManager.InsertControl unable to create HostDockSite for DropCtl');
        end;
        // init anchors of DropCtl
        DropCtl.Align:=alNone;
        for a:=Low(TAnchorKind) to High(TAnchorKind) do
          DropCtl.AnchorParallel(a,0,DropCtl.Parent);
        DropCtl.Anchors:=[akLeft,akTop,akRight,akBottom];
      end;

      DropCtl.Parent.DisableAlign;
      try
        // create a splitter
        Splitter:=TLazDockSplitter.Create(Control);
        Splitter.Align:=alNone;
        Splitter.Beveled:=true;
        Splitter.ResizeAnchor:=ControlAnchor;
        //debugln('TAnchoredDockManager.InsertControl A Control.Bounds=',DbgSName(Control),dbgs(Control.BoundsRect),' DropCtl.Bounds=',DbgSName(DropCtl),dbgs(DropCtl.BoundsRect),' Splitter.Bounds=',DbgSName(Splitter),dbgs(Splitter.BoundsRect));

        // calculate new bounds
        NewDropCtlBounds:=DropCtl.BoundsRect;
        NewControlBounds:=NewDropCtlBounds;
        if InsertAt in [alLeft,alRight] then begin
          SplitterWidth:=Splitter.Constraints.MinMaxWidth(SplitterSize);
          NewDropCtlWidth:=NewDropCtlBounds.Right-NewDropCtlBounds.Left;
          dec(NewDropCtlWidth,Control.Width+SplitterWidth);
          NewDropCtlWidth:=DropCtl.Constraints.MinMaxWidth(NewDropCtlWidth);
          if InsertAt=alLeft then begin
            // alLeft: insert Control to the left of DropCtl
            NewDropCtlBounds.Left:=NewDropCtlBounds.Right-NewDropCtlWidth;
            NewControlBounds.Right:=NewDropCtlBounds.Left-SplitterWidth;
            SplitterBounds:=Rect(NewControlBounds.Right,NewDropCtlBounds.Top,
                                 NewDropCtlBounds.Left,NewDropCtlBounds.Bottom);
          end else begin
            // alRight: insert Control to the right of DropCtl
            NewDropCtlBounds.Right:=NewDropCtlBounds.Left+NewDropCtlWidth;
            NewControlBounds.Left:=NewDropCtlBounds.Right+SplitterWidth;
            SplitterBounds:=Rect(NewDropCtlBounds.Right,NewDropCtlBounds.Top,
                                 NewControlBounds.Left,NewDropCtlBounds.Bottom);
            //debugln('TAnchoredDockManager.InsertControl A NewDropCtlBounds=',dbgs(NewDropCtlBounds),' NewControlBounds=',dbgs(NewControlBounds),' SplitterBounds=',dbgs(SplitterBounds));
          end;
        end else begin
          SplitterHeight:=Splitter.Constraints.MinMaxHeight(SplitterSize);
          NewDropCtlHeight:=NewDropCtlBounds.Bottom-NewDropCtlBounds.Top;
          dec(NewDropCtlHeight,Control.Height+SplitterHeight);
          NewDropCtlHeight:=DropCtl.Constraints.MinMaxHeight(NewDropCtlHeight);
          if InsertAt=alTop then begin
            // alTop: insert Control to the top of DropCtl
            NewDropCtlBounds.Top:=NewDropCtlBounds.Bottom-NewDropCtlHeight;
            NewControlBounds.Bottom:=NewDropCtlBounds.Top-SplitterHeight;
            SplitterBounds:=Rect(NewDropCtlBounds.Left,NewControlBounds.Bottom,
                                 NewDropCtlBounds.Right,NewDropCtlBounds.Top);
          end else begin
            // alBottom: insert Control to the bottom of DropCtl
            NewDropCtlBounds.Bottom:=NewDropCtlBounds.Top+NewDropCtlHeight;
            NewControlBounds.Top:=NewDropCtlBounds.Bottom+SplitterHeight;
            SplitterBounds:=Rect(NewDropCtlBounds.Left,NewDropCtlBounds.Bottom,
                                 NewDropCtlBounds.Right,NewControlBounds.Top);
          end;
          //debugln('TAnchoredDockManager.InsertControl A NewDropCtlBounds=',dbgs(NewDropCtlBounds),' NewControlBounds=',dbgs(NewControlBounds),' SplitterBounds=',dbgs(SplitterBounds));
        end;

        // position splitter
        Splitter.BoundsRect:=SplitterBounds;
        if InsertAt in [alLeft,alRight] then begin
          Splitter.AnchorSide[akTop].Assign(DropCtl.AnchorSide[akTop]);
          Splitter.AnchorSide[akBottom].Assign(DropCtl.AnchorSide[akBottom]);
          Splitter.Anchors:=[akLeft,akTop,akBottom];
        end else begin
          Splitter.AnchorSide[akLeft].Assign(DropCtl.AnchorSide[akLeft]);
          Splitter.AnchorSide[akRight].Assign(DropCtl.AnchorSide[akRight]);
          Splitter.Anchors:=[akLeft,akTop,akRight];
        end;
        Splitter.Parent:=DropCtl.Parent;

        // position Control
        Control.Align:=alNone;
        for a:=Low(TAnchorKind) to High(TAnchorKind) do
          Control.AnchorSide[a].Control:=nil;
        Control.AnchorSide[DropCtlAnchor].Assign(DropCtl.AnchorSide[DropCtlAnchor]);
        Control.AnchorToNeighbour(ControlAnchor,0,Splitter);
        if InsertAt in [alLeft,alRight] then begin
          Control.AnchorSide[akTop].Assign(DropCtl.AnchorSide[akTop]);
          Control.AnchorSide[akBottom].Assign(DropCtl.AnchorSide[akBottom]);
        end else begin
          Control.AnchorSide[akLeft].Assign(DropCtl.AnchorSide[akLeft]);
          Control.AnchorSide[akRight].Assign(DropCtl.AnchorSide[akRight]);
        end;
        Control.Anchors:=[akLeft,akTop,akRight,akBottom];
        Control.Parent:=DropCtl.Parent;

        // position DropCtl
        DropCtl.AnchorToNeighbour(DropCtlAnchor,0,Splitter);

        //debugln('TAnchoredDockManager.InsertControl BEFORE ALIGNING Control.Bounds=',DbgSName(Control),dbgs(Control.BoundsRect),' DropCtl.Bounds=',DbgSName(DropCtl),dbgs(DropCtl.BoundsRect),' Splitter.Bounds=',DbgSName(Splitter),dbgs(Splitter.BoundsRect));
      finally
        DropCtl.Parent.EnableAlign;
      end;
      //debugln('TAnchoredDockManager.InsertControl END Control.Bounds=',DbgSName(Control),dbgs(Control.BoundsRect),' DropCtl.Bounds=',DbgSName(DropCtl),dbgs(DropCtl.BoundsRect),' Splitter.Bounds=',DbgSName(Splitter),dbgs(Splitter.BoundsRect));
    end;
    
  alClient:
    begin
      // docking as page
      DebugLn('TAnchoredDockManager.InsertControl alClient DropCtl=',DbgSName(DropCtl),' Control=',DbgSName(Control));

      if not (DropCtl.Parent is TLazDockPage) then begin
        // create a new TLazDockPages
        //DebugLn('TAnchoredDockManager.InsertControl Create TLazDockPages');
        DockPages:=TLazDockPages.Create(nil);
        if DropCtl.Parent<>nil then begin
          // DockCtl is a child control
          // => replace the anchors to and from DockCtl with the new DockPages
          ReplaceAnchoredControl(DropCtl,DockPages);
        end else begin
          // DockCtl has no parent
          // => float DockPages
          DockPages.ManualFloat(DropCtl.BoundsRect);
        end;
        // add DockCtl as page to DockPages
        DockPages.Pages.Add(DropCtl.Caption);
        DropCtlPage:=DockPages.Page[0];
        DropCtl.Parent:=DropCtlPage;
        DropCtl.Align:=alClient;
      end;
      // add Control as new page behind the page of DockCtl
      DropCtlPage:=DropCtl.Parent as TLazDockPage;
      DockPages:=DropCtlPage.PageControl as TLazDockPages;
      NewPageIndex:=DropCtlPage.PageIndex+1;
      DockPages.Pages.Insert(NewPageIndex,Control.Caption);
      NewPage:=DockPages.Page[NewPageIndex];
      Control.Parent:=NewPage;
      Control.Align:=alClient;
    end;
  else
    RaiseGDBException('TAnchoredDockManager.InsertControl TODO');
  end;
end;

{-------------------------------------------------------------------------------
  procedure TAnchoredDockManager.UndockControl(Control: TControl);

  Removes a control from a docking form.
  It breaks all anchors and cleans up.
  
  The created gap will be tried to fill up.
  It removes TLazDockSplitter, TLazDockPage and TLazDockPages if they are no
  longer needed.
-------------------------------------------------------------------------------}
procedure TAnchoredDockManager.UndockControl(Control: TControl; Float: boolean);
{

  Examples:

  Search Order:

  1. A TLazDockSplitter dividing only two controls:

     Before:
     |-------------
     | +--+ | +---
     | |  | | | B
     | +--+ | +---
     |-------------

     The splitter will be deleted and the right control will be anchored to the
     left.

     After:
     |-------------
     | +---
     | | B
     | +---
     |-------------


  2. Four spiral splitters:
  
     Before:
              |
           A  |
     ---------|
       | +--+ |  C
     B | |  | |
       | +--+ |
       | ----------
       |   D

     The left and right splitter will be combined to one.
     
     After:
              |
           A  |
       -------|
              |  C
            B |
              |
              |------
              |   D


  3. No TLazDockSplitter. Control is the only child of a TLazDockPage
     In this case the page will be deleted.
     If the TLazDockPages has no childs left, it is recursively undocked.
  
  4. No TLazDockSplitter, Control is the only child of a TLazDockForm.
     The TLazDockForm is deleted and the Control is floated.
     This normally means: A form will simply be placed on the desktop, other
     controls will be docked into their DockSite.
     
  5. Otherwise: this control was not docked.
}
var
  a: TAnchorKind;
  AnchorControl: TControl;
  AnchorSplitter: TLazDockSplitter;
  i: Integer;
  Sibling: TControl;
  OldAnchorControls: array[TAnchorKind] of TControl;
  IsSpiralSplitter: Boolean;
  ParentControl: TWinControl;
  Done: Boolean;
  
  procedure DoFinallyForParent;
  var
    OldParentControl: TWinControl;
  begin
    if Float then begin
      Control.ManualFloat(Control.BoundsRect);
    end else begin
      Control.Parent:=nil;
    end;
    if ParentControl<>nil then begin
      OldParentControl:=ParentControl;
      ParentControl:=nil;
      OldParentControl.DisableAlign;
    end;
  end;
  
begin
  if Control.Parent=nil then begin
    // already undocked
    RaiseGDBException('TAnchoredDockManager.UndockControl Control.Parent=nil');
  end;
  
  ParentControl:=Control.Parent;
  ParentControl.DisableAlign;
  try
    // break anchors
    Control.Align:=alNone;
    for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
      OldAnchorControls[a]:=Control.AnchorSide[a].Control;
      Control.AnchorSide[a].Control:=nil;
    end;
    Control.Anchors:=[akLeft,akTop];

    Done:=false;

    if not Done then begin
      // check if their is a splitter, that has a side with only Control
      // anchored to it.
      for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
        AnchorControl:=OldAnchorControls[a];
        if AnchorControl is TLazDockSplitter then begin
          AnchorSplitter:=TLazDockSplitter(AnchorControl);
          i:=Control.Parent.ControlCount-1;
          while i>=0 do begin
            Sibling:=Control.Parent.Controls[i];
            if (Sibling.AnchorSide[a].Control=AnchorSplitter) then begin
              // Sibling is anchored with the same side to the splitter
              // => this splitter is needed, can not be deleted.
              break;
            end;
          end;
          if i<0 then begin
            // this splitter is not needed anymore
            DeleteSideSplitter(AnchorSplitter,OppositeAnchor[a],
                               OldAnchorControls[OppositeAnchor[a]]);
            Done:=true;
          end;
        end;
      end;
    end;

    if not Done then begin
      // check if there are four spiral splitters around Control
      IsSpiralSplitter:=true;
      for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
        AnchorControl:=OldAnchorControls[a];
        if (AnchorControl=nil)
        or (not (AnchorControl is TLazDockSplitter)) then begin
          IsSpiralSplitter:=false;
        end;
      end;
      if IsSpiralSplitter then begin
        CombineSpiralSplitterPair(OldAnchorControls[akLeft] as TLazDockSplitter,
                                OldAnchorControls[akRight] as TLazDockSplitter);
        Done:=true;
      end;
    end;

    if not Done then begin
      // check if Control is the only child of a TLazDockPage
      if (ParentControl.ControlCount=1)
      and (ParentControl is TLazDockPage) then begin
        DoFinallyForParent;
        DeletePage(TLazDockPage(Control.Parent));
      end;
    end;
    
    if not Done then begin
      // check if Control is the only child of a TLazDockForm
      if (ParentControl.ControlCount=1)
      and (ParentControl is TLazDockForm) then begin
        DoFinallyForParent;
        DeleteDockForm(TLazDockForm(ParentControl));
      end;
    end;
    
    if not Done then begin
      // otherwise: keep
    end;
    
  finally
    DoFinallyForParent;
  end;
end;

procedure TAnchoredDockManager.InsertControl(Control: TControl;
  InsertAt: TAlign; DropCtl: TControl);
begin
  DockControl(Control, InsertAt, DropCtl);
end;

procedure TAnchoredDockManager.LoadFromStream(Stream: TStream);
begin
  RaiseGDBException('TAnchoredDockManager.LoadFromStream TODO');
end;

procedure TAnchoredDockManager.PaintSite(DC: HDC);
begin
  RaiseGDBException('TAnchoredDockManager.PaintSite TODO');
end;

procedure TAnchoredDockManager.PositionDockRect(Client, DropCtl: TControl;
  DropAlign: TAlign; var DockRect: TRect);
begin
  RaiseGDBException('TAnchoredDockManager.PositionDockRect TODO');
end;

procedure TAnchoredDockManager.RemoveControl(Control: TControl);
begin
  UndockControl(Control,false);
end;

procedure TAnchoredDockManager.ResetBounds(Force: Boolean);
begin
  RaiseGDBException('TAnchoredDockManager.ResetBounds TODO');
end;

procedure TAnchoredDockManager.SaveToStream(Stream: TStream);
begin
  RaiseGDBException('TAnchoredDockManager.SaveToStream TODO');
end;

procedure TAnchoredDockManager.SetReplacingControl(Control: TControl);
begin
  RaiseGDBException('TAnchoredDockManager.SetReplacingControl TODO');
end;

procedure TAnchoredDockManager.ReplaceAnchoredControl(OldControl,
  NewControl: TControl);
var
  a: TAnchorKind;
  Side: TAnchorSide;
  i: Integer;
  Sibling: TControl;
begin
  if OldControl.Parent<>nil then begin
    NewControl.Parent.DisableAlign;
    try
      // put NewControl on the same Parent with the same bounds
      NewControl.Parent:=nil;
      NewControl.Align:=alNone;
      NewControl.BoundsRect:=OldControl.BoundsRect;
      NewControl.Parent:=OldControl.Parent;
      // copy all four AnchorSide
      for a:=Low(TAnchorKind) to High(TAnchorKind) do
        NewControl.AnchorSide[a].Assign(OldControl.AnchorSide[a]);
      // bend all Anchors from OldControl to NewControl
      for i:=0 to OldControl.Parent.ControlCount-1 do begin
        Sibling:=OldControl.Parent.Controls[i];
        if (Sibling=NewControl) or (Sibling=OldControl) then continue;
        for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
          Side:=Sibling.AnchorSide[a];
          if Side.Control=OldControl then begin
            Side.Control:=NewControl;
          end;
        end;
      end;
      // remove OldControl from its Parent
      OldControl.Parent:=nil;
    finally
      NewControl.Parent.EnableAlign;
    end;
  end else begin
    NewControl.Parent:=nil;
    NewControl.Align:=alNone;
    NewControl.BoundsRect:=OldControl.BoundsRect;
  end;
end;

{ TLazDockPage }

function TLazDockPage.GetPageControl: TLazDockPages;
begin
  Result:=Parent as TLazDockPages;
end;

{ TCustomLazControlDocker }

procedure TCustomLazControlDocker.SetManager(
  const AValue: TCustomLazDockingManager);
begin
  if FManager=AValue then exit;
  if FManager<>nil then FManager.Remove(Self);
  FManager:=AValue;
  if FManager<>nil then FManager.Add(Self);
end;

procedure TCustomLazControlDocker.UpdatePopupMenu;
// creates or deletes the PopupMenuItem to the PopupMenu of Control
begin
  if [csDestroying,csDesigning]*ComponentState<>[] then exit;
  if csLoading in ComponentState then exit;
  
  if ExtendPopupMenu and (Control.PopupMenu<>nil) then begin
    if (PopupMenuItem<>nil) and (PopupMenuItem.Parent<>Control.PopupMenu.Items)
    then begin
      // PopupMenuItem is in the old PopupMenu -> delete it
      FreeAndNil(FPopupMenuItem);
    end;
    if (PopupMenuItem=nil) then begin
      // create a new PopupMenuItem
      FPopupMenuItem:=TMenuItem.Create(Self);
      PopupMenuItem.Caption:=rsDocking;
      PopupMenuItem.OnClick:=@PopupMenuItemClick;
    end;
    if PopupMenuItem.Parent=nil then begin
      // add PopupMenuItem to Control.PopupMenu
      Control.PopupMenu.Items.Add(PopupMenuItem);
    end;
  end else begin
    // delete PopupMenuItem
    FreeAndNil(FPopupMenuItem);
  end;
end;

procedure TCustomLazControlDocker.Loaded;
begin
  inherited Loaded;
  UpdatePopupMenu;
end;

constructor TCustomLazControlDocker.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  if (not (csLoading in ComponentState))
  and (TheOwner is TControl) then
    // use as default
    Control:=TControl(TheOwner);
  ExtendPopupMenu:=true;
end;

procedure TCustomLazControlDocker.PopupMenuItemClick(Sender: TObject);
begin

end;

procedure TCustomLazControlDocker.SetControl(const AValue: TControl);
begin
  if FControl=AValue then exit;
  FControl:=AValue;
end;

procedure TCustomLazControlDocker.SetExtendPopupMenu(const AValue: boolean);
begin
  if FExtendPopupMenu=AValue then exit;
  FExtendPopupMenu:=AValue;
  UpdatePopupMenu;
end;

{ TCustomLazDockingManager }

procedure TCustomLazDockingManager.Remove(Docker: TCustomLazControlDocker);
begin
  FDockers.Remove(Docker);
end;

function TCustomLazDockingManager.Add(Docker: TCustomLazControlDocker): Integer;
begin
  Result:=FDockers.Add(Docker);
end;

function TCustomLazDockingManager.GetDockers(Index: Integer
  ): TCustomLazControlDocker;
begin
  Result:=TCustomLazControlDocker(FDockers[Index]);
end;

constructor TCustomLazDockingManager.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FDockers:=TFPList.Create;
  FManager:=TAnchoredDockManager.Create;
end;

destructor TCustomLazDockingManager.Destroy;
var
  i: Integer;
begin
  for i:=FDockers.Count-1 downto 0 do
    Dockers[i].Manager:=nil;
  FreeAndNil(FDockers);
  FreeAndNil(FManager);
  inherited Destroy;
end;

end.

