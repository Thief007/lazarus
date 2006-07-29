{  $Id: ldocktree.pas 8153 2005-11-14 21:53:06Z mattias $  }
{
 /***************************************************************************
                               LDockCtrl.pas
                             -----------------

 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Mattias Gaertner

  Abstract:
    This unit contains visual components for docking and streaming.

  ToDo:
    - restoring layout, when a docked control becomes visible
    - save TLazDockConfigNode to stream
    - load TLazDockConfigNode from stream
}
unit LDockCtrl;

{$mode objfpc}{$H+}

interface

uses
  Classes, Math, SysUtils, TypInfo, LCLProc, Controls, Forms, Menus,
  LCLStrConsts, AvgLvlTree, StringHashList, LazConfigStorage, LDockCtrlEdit,
  LDockTree;

type
  TNonDockConfigNames = (
    ndcnControlName, // '-Name ' + AControl.Name
    ndcnChildIndex,  // '-ID ' + IntToStr(AControl index in Parent) +' '+ AControl.ClassName
    ndcnParent       // '-Parent' : AControl.Parent
    );

const
  NonDockConfigNamePrefixes: array[TNonDockConfigNames] of string = (
    '-Name ',
    '-ID ',
    '-Parent');

type
  TLDConfigNodeType = (
    ldcntControl,
    ldcntForm,
    ldcntSplitterLeftRight,// vertical splitter, can be moved left/right
    ldcntSplitterUpDown,   // horizontal splitter, can be moved up/down
    ldcntPages,
    ldcntPage
    );
    
const
  LDConfigNodeTypeNames: array[TLDConfigNodeType] of string = (
    'Control',
    'Form',
    'SplitterLeftRight',
    'SplitterUpDown',
    'Pages',
    'Page'
    );

type
  { TLazDockConfigNode }

  TLazDockConfigNode = class(TPersistent)
  private
    FBounds: TRect;
    FClientBounds: TRect;
    FName: string;
    FParent: TLazDockConfigNode;
    FSides: array[TAnchorKind] of string;
    FTheType: TLDConfigNodeType;
    FChilds: TFPList;
    function GetChildCount: Integer;
    function GetChilds(Index: integer): TLazDockConfigNode;
    function GetSides(Side: TAnchorKind): string;
    procedure SetBounds(const AValue: TRect);
    procedure SetClientBounds(const AValue: TRect);
    procedure SetName(const AValue: string);
    procedure SetParent(const AValue: TLazDockConfigNode);
    procedure SetSides(Side: TAnchorKind; const AValue: string);
    procedure SetTheType(const AValue: TLDConfigNodeType);
    procedure DoAdd(ChildNode: TLazDockConfigNode);
    procedure DoRemove(ChildNode: TLazDockConfigNode);
  public
    constructor Create(ParentNode: TLazDockConfigNode);
    constructor Create(ParentNode: TLazDockConfigNode; const AName: string);
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(Source: TPersistent); override;
    function FindByName(const AName: string; Recursive: boolean = false;
                        WithRoot: boolean = true): TLazDockConfigNode;
    function IndexOf(const AName: string): Integer;
    function GetScreenBounds: TRect;
    procedure SaveToConfig(Config: TConfigStorage; const Path: string = '');
    procedure LoadFromConfig(Config: TConfigStorage; const Path: string = '');
    function GetPath: string;
    procedure WriteDebugReport;
    function DebugLayoutAsString: string;
  public
    property Bounds: TRect read FBounds write SetBounds;
    property ClientBounds: TRect read FClientBounds write SetClientBounds;
    property Parent: TLazDockConfigNode read FParent write SetParent;
    property Sides[Side: TAnchorKind]: string read GetSides write SetSides;
    property ChildCount: Integer read GetChildCount;
    property Childs[Index: integer]: TLazDockConfigNode read GetChilds; default;
  published
    property TheType: TLDConfigNodeType read FTheType write SetTheType default ldcntControl;
    property Name: string read FName write SetName;
  end;
  
  { TLazDockerConfig }

  TLazDockerConfig = class
  private
    FDockerName: string;
    FRoot: TLazDockConfigNode;
  public
    constructor Create(const ADockerName: string; ANode: TLazDockConfigNode);
    procedure WriteDebugReport;
    property DockerName: string read FDockerName;
    property Root: TLazDockConfigNode read FRoot;
  end;
  
  TCustomLazControlDocker = class;

  { TCustomLazDockingManager }

  TCustomLazDockingManager = class(TComponent)
  private
    FDockers: TFPList;
    FManager: TAnchoredDockManager;
    FConfigs: TFPList;// list of TLazDockerConfig
    function GetConfigCount: Integer;
    function GetConfigs(Index: Integer): TLazDockerConfig;
    function GetDockerCount: Integer;
    function GetDockers(Index: Integer): TCustomLazControlDocker;
  protected
    procedure Remove(Docker: TCustomLazControlDocker);
    function Add(Docker: TCustomLazControlDocker): Integer;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function FindDockerByName(const ADockerName: string;
                Ignore: TCustomLazControlDocker = nil): TCustomLazControlDocker;
    function FindControlByDockerName(const ADockerName: string;
                Ignore: TCustomLazControlDocker = nil): TControl;
    function FindDockerByControl(AControl: TControl;
                Ignore: TCustomLazControlDocker = nil): TCustomLazControlDocker;
    function CreateUniqueName(const AName: string;
                              Ignore: TCustomLazControlDocker): string;
    function GetControlConfigName(AControl: TControl): string;
    procedure SaveToConfig(Config: TConfigStorage; const Path: string = '');
    procedure LoadFromConfig(Config: TConfigStorage; const Path: string = '');
    procedure AddOrReplaceConfig(const DockerName: string;
                                 Config: TLazDockConfigNode);
    procedure ClearConfigs;
    function GetConfigWithDockerName(const DockerName: string
                                     ): TLazDockerConfig;
    function CreateLayout(const DockerName: string; VisibleControl: TControl;
                          ExceptionOnError: boolean = false): TLazDockConfigNode;
    function ConfigIsCompatible(RootNode: TLazDockConfigNode;
                                ExceptionOnError: boolean = false): boolean;

    procedure WriteDebugReport;
  public
    property Manager: TAnchoredDockManager read FManager;
    property DockerCount: Integer read GetDockerCount;
    property Dockers[Index: Integer]: TCustomLazControlDocker read GetDockers; default;
    property ConfigCount: Integer read GetConfigCount;
    property Configs[Index: Integer]: TLazDockerConfig read GetConfigs;
  end;

  { TLazDockingManager }

  TLazDockingManager = class(TCustomLazDockingManager)
  published
  end;

  { TCustomLazControlDocker
    A component to connect a form to the TLazDockingManager.
    When the control gets visible TCustomLazControlDocker restores the layout.
    Before the control gets invisible, TCustomLazControlDocker saves the layout.
    }
  TCustomLazControlDocker = class(TComponent)
  private
    FControl: TControl;
    FDockerName: string;
    FEnabled: boolean;
    FExtendPopupMenu: boolean;
    FLocalizedName: string;
    FManager: TCustomLazDockingManager;
    FPopupMenuItem: TMenuItem;
    procedure SetControl(const AValue: TControl);
    procedure SetDockerName(const AValue: string);
    procedure SetExtendPopupMenu(const AValue: boolean);
    procedure SetLocalizedName(const AValue: string);
    procedure SetManager(const AValue: TCustomLazDockingManager);
    procedure PopupMenuItemClick(Sender: TObject);
  protected
    procedure UpdatePopupMenu; virtual;
    procedure Loaded; override;
    function GetLocalizedName: string;
    procedure ControlVisibleChanging(Sender: TObject);
    procedure ControlVisibleChanged(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
    procedure ShowDockingEditor; virtual;
    function GetLayoutFromControl: TLazDockConfigNode;
    procedure SaveLayout;
    procedure RestoreLayout;
    function GetControlName(AControl: TControl): string;
    property Control: TControl read FControl write SetControl;
    property Manager: TCustomLazDockingManager read FManager write SetManager;
    property ExtendPopupMenu: boolean read FExtendPopupMenu write SetExtendPopupMenu;
    property PopupMenuItem: TMenuItem read FPopupMenuItem;
    property LocalizedName: string read FLocalizedName write SetLocalizedName;
    property DockerName: string read FDockerName write SetDockerName;
    property Enabled: boolean read FEnabled write FEnabled;// true to auto restore layout on show
  end;

  { TLazControlDocker }

  TLazControlDocker = class(TCustomLazControlDocker)
  published
    property Control;
    property Manager;
    property ExtendPopupMenu;
    property DockerName;
    property Enabled;
  end;


function LDConfigNodeTypeNameToType(const s: string): TLDConfigNodeType;

function dbgs(Node: TLazDockConfigNode): string; overload;
  
procedure Register;


implementation

function LDConfigNodeTypeNameToType(const s: string): TLDConfigNodeType;
begin
  for Result:=Low(TLDConfigNodeType) to High(TLDConfigNodeType) do
    if CompareText(LDConfigNodeTypeNames[Result],s)=0 then exit;
  Result:=ldcntControl;
end;

function dbgs(Node: TLazDockConfigNode): string;
begin
  if Node=nil then begin
    Result:='nil';
  end else begin
    Result:=Node.Name+'{Type='+LDConfigNodeTypeNames[Node.TheType]
                     +',ChildCnt='+IntToStr(Node.ChildCount)+'}';
  end;
end;

procedure Register;
begin
  RegisterComponents('Misc',[TLazDockingManager,TLazControlDocker]);
end;

{ TCustomLazControlDocker }

procedure TCustomLazControlDocker.SetManager(
  const AValue: TCustomLazDockingManager);
begin
  if FManager=AValue then exit;
  //DebugLn('TCustomLazControlDocker.SetManager Old=',DbgSName(Manager),' New=',DbgSName(AValue));
  if FManager<>nil then FManager.Remove(Self);
  FManager:=AValue;
  if FManager<>nil then FManager.Add(Self);
  UpdatePopupMenu;
end;

procedure TCustomLazControlDocker.UpdatePopupMenu;
// creates or deletes the PopupMenuItem to the PopupMenu of Control
begin
  if [csDestroying,csDesigning]*ComponentState<>[] then exit;
  if csLoading in ComponentState then exit;

  //DebugLn('TCustomLazControlDocker.UpdatePopupMenu ',DbgSName(Control),' Manager=',DbgSName(Manager),' PopupMenu=',dbgs((Control<>nil) and (Control.PopupMenu<>nil)),' ExtendPopupMenu=',dbgs(ExtendPopupMenu));

  if ExtendPopupMenu and (Control<>nil) and (Control.PopupMenu<>nil)
  and (Manager<>nil) then begin
    //DebugLn('TCustomLazControlDocker.UpdatePopupMenu ADDING');
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

procedure TCustomLazControlDocker.ShowDockingEditor;
var
  Dlg: TLazDockControlEditorDlg;
  i: Integer;
  TargetDocker: TCustomLazControlDocker;
  Side: TAlign;
  CurDocker: TCustomLazControlDocker;
begin
  Dlg:=TLazDockControlEditorDlg.Create(nil);
  try
    // fill the list of controls this control can dock to
    Dlg.DockControlComboBox.Text:='';
    Dlg.DockControlComboBox.Items.BeginUpdate;
    //DebugLn('TCustomLazControlDocker.ShowDockingEditor Self=',DockerName,' Manager.DockerCount=',dbgs(Manager.DockerCount));
    try
      Dlg.DockControlComboBox.Items.Clear;
      for i:=0 to Manager.DockerCount-1 do begin
        CurDocker:=Manager.Dockers[i];
        //DebugLn('TCustomLazControlDocker.ShowDockingEditor Self=',DockerName,' CurDocker=',CurDocker.DockerName);
        if CurDocker=Self then continue;
        if CurDocker.Control=nil then continue;
        Dlg.DockControlComboBox.Items.Add(CurDocker.GetLocalizedName);
      end;
      Dlg.DockControlComboBox.Enabled:=Dlg.DockControlComboBox.Items.Count>0;
    finally
      Dlg.DockControlComboBox.Items.EndUpdate;
    end;

    // enable Undock button, if Control is docked
    Dlg.UndockGroupBox.Enabled:=(Control.Parent<>nil)
                                 and (Control.Parent.ControlCount>1);
    
    if Dlg.ShowModal=mrOk then begin
      // dock or undock
      case Dlg.DlgResult of
      ldcedrUndock:
        // undock
        Manager.Manager.UndockControl(Control,true);
      ldcedrDockLeft,ldcedrDockRight,ldcedrDockTop,
        ldcedrDockBottom,ldcedrDockPage:
        // dock
        begin
          TargetDocker:=nil;
          for i:=0 to Manager.DockerCount-1 do begin
            CurDocker:=Manager.Dockers[i];
            if CurDocker=Self then continue;
            if Dlg.DockControlComboBox.Text=CurDocker.GetLocalizedName then
              TargetDocker:=CurDocker;
          end;
          if TargetDocker=nil then begin
            RaiseGDBException('TCustomLazControlDocker.ShowDockingEditor TargetDocker=nil');
          end;
          case Dlg.DlgResult of
          ldcedrDockLeft: Side:=alLeft;
          ldcedrDockRight: Side:=alRight;
          ldcedrDockTop: Side:=alTop;
          ldcedrDockBottom: Side:=alBottom;
          ldcedrDockPage: Side:=alClient;
          else RaiseGDBException('TCustomLazControlDocker.ShowDockingEditor ?');
          end;
          Manager.Manager.DockControl(Control,Side,TargetDocker.Control);
        end;
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

function TCustomLazControlDocker.GetLocalizedName: string;
begin
  Result:=LocalizedName;
  if LocalizedName='' then begin
    Result:=DockerName;
    if (Result='') and (Control<>nil) then
      Result:=Control.Name;
    if Result='' then
      Result:=Name;
  end;
end;

procedure TCustomLazControlDocker.ControlVisibleChanging(Sender: TObject);
begin
  if Control<>Sender then begin
    DebugLn('TCustomLazControlDocker.ControlVisibleChanging WARNING: ',
      DbgSName(Control),'<>',DbgSName(Sender));
    exit;
  end;
  DebugLn(['TCustomLazControlDocker.ControlVisibleChanging Sender=',DbgSName(Sender)]);
  if Control.Visible then begin
    // control will be hidden -> the layout will change
    // save the layout for later restore
    SaveLayout;
  end else begin
    // the control will become visible -> dock it to restore the last layout
    RestoreLayout;
  end;
end;

procedure TCustomLazControlDocker.ControlVisibleChanged(Sender: TObject);
begin
  DebugLn(['TCustomLazControlDocker.ControlVisibleChanged Sender=',DbgSName(Sender)]);
end;

function TCustomLazControlDocker.GetControlName(AControl: TControl): string;
var
  i: Integer;
begin
  Result:=Manager.GetControlConfigName(AControl);
  if Result='' then begin
    if AControl=Control.Parent then
      Result:=NonDockConfigNamePrefixes[ndcnParent]
    else if AControl.Name<>'' then
      Result:=NonDockConfigNamePrefixes[ndcnControlName]+AControl.Name
    else if AControl.Parent<>nil then begin
      i:=AControl.Parent.ControlCount-1;
      while (i>=0) and (AControl.Parent.Controls[i]<>AControl) do dec(i);
      Result:=NonDockConfigNamePrefixes[ndcnChildIndex]+IntToStr(i)+' '
                   +AControl.ClassName;
    end;
  end;
end;

function TCustomLazControlDocker.GetLayoutFromControl: TLazDockConfigNode;

  procedure CopyChildsLayout(ParentNode: TLazDockConfigNode;
    ParentNodeControl: TWinControl);
  // saves for each child node the names of the anchor side controls
  var
    i: Integer;
    ChildNode: TLazDockConfigNode;
    ChildControl: TControl;
    a: TAnchorKind;
    ChildNames: TStringHashList;// name to control mapping
    ChildName: String;
    CurAnchorControl: TControl;
    CurAnchorCtrlName: String;
    CurAnchorNode: TLazDockConfigNode;
  begin
    ChildNames:=TStringHashList.Create(false);
    try
      // build mapping of name to control
      ChildNames.Data[ParentNode.Name]:=ParentNodeControl;
      for i:=0 to ParentNodeControl.ControlCount-1 do begin
        ChildControl:=ParentNodeControl.Controls[i];
        ChildName:=GetControlName(ChildControl);
        if ChildName<>'' then
          ChildNames.Data[ChildName]:=ChildControl;
      end;
      // build mapping control to node
      
      // set 'Sides'
      for i:=0 to ParentNode.ChildCount-1 do begin
        ChildNode:=ParentNode[i];
        ChildControl:=TControl(ChildNames.Data[ChildNode.Name]);
        if ChildControl=nil then continue;
        for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
          CurAnchorControl:=ChildControl.AnchorSide[a].Control;
          if CurAnchorControl=nil then continue;
          if CurAnchorControl=ParentNodeControl then
            CurAnchorNode:=ParentNode
          else begin
            CurAnchorCtrlName:=GetControlName(CurAnchorControl);
            CurAnchorNode:=ParentNode.FindByName(CurAnchorCtrlName);
            if CurAnchorNode=nil then
              RaiseGDBException('inconsistency');
          end;
          //DebugLn('CopyChildsLayout ',DbgSName(CurAnchorControl),' CurAnchorCtrlName="',CurAnchorCtrlName,'"');
          ChildNode.Sides[a]:=CurAnchorNode.Name;
        end;
      end;
    finally
      ChildNames.Free;
    end;
  end;

  function AddNode(ParentNode: TLazDockConfigNode;
    AControl: TControl): TLazDockConfigNode;
  var
    i: Integer;
    CurChildControl: TControl;
    NeedChildNodes: boolean;
  begin
    Result:=TLazDockConfigNode.Create(ParentNode,GetControlName(AControl));

    // The Type
    if AControl is TLazDockSplitter then begin
      if TLazDockSplitter(AControl).ResizeAnchor in [akLeft,akRight] then
        Result.FTheType:=ldcntSplitterLeftRight
      else
        Result.FTheType:=ldcntSplitterUpDown;
    end else if AControl is TLazDockForm then
      Result.FTheType:=ldcntForm
    else if AControl is TLazDockPages then
      Result.FTheType:=ldcntPages
    else if AControl is TLazDockPage then
      Result.FTheType:=ldcntPage
    else
      Result.FTheType:=ldcntControl;

    // Bounds
    Result.FBounds:=AControl.BoundsRect;
    if AControl is TWinControl then
      Result.FClientBounds:=TWinControl(AControl).GetChildsRect(false)
    else
      Result.FClientBounds:=Rect(0,0,Result.FBounds.Right-Result.FBounds.Left,
                                 Result.FBounds.Bottom-Result.FBounds.Top);

    // Childs
    if (AControl is TWinControl) then begin
      // check if childs need nodes
      NeedChildNodes:=(AControl is TLazDockPages)
                   or (AControl is TLazDockPage);
      if not NeedChildNodes then begin
        for i:=0 to TWinControl(AControl).ControlCount-1 do begin
          CurChildControl:=TWinControl(AControl).Controls[i];
          if Manager.FindDockerByControl(CurChildControl,nil)<>nil then begin
            NeedChildNodes:=true;
            break;
          end;
        end;
      end;
      // add child nodes
      if NeedChildNodes then begin
        for i:=0 to TWinControl(AControl).ControlCount-1 do begin
          CurChildControl:=TWinControl(AControl).Controls[i];
          AddNode(Result,CurChildControl);
        end;
        for i:=0 to Result.ChildCount-1 do begin
        end;
      end;
      CopyChildsLayout(Result,TWinControl(AControl));
    end;
  end;

var
  RootControl: TControl;
begin
  if (Control=nil) or (Manager=nil) then exit(nil);
  
  RootControl:=Control;
  while RootControl.Parent<>nil do
    RootControl:=RootControl.Parent;
  Result:=AddNode(nil,RootControl);
end;

procedure TCustomLazControlDocker.SaveLayout;
var
  Layout: TLazDockConfigNode;
begin
  if Manager=nil then exit;
  Layout:=GetLayoutFromControl;
  if (Layout=nil) then exit;
  Manager.AddOrReplaceConfig(DockerName,Layout);
end;

procedure TCustomLazControlDocker.RestoreLayout;
  { TODO
  
  Goals of this algorithm:
  - If a form is hidden and immediately shown again, the layout should be
    restored 1:1.
    That's why a TCustomLazControlDocker stores the complete layout on every
    hide. And restores it on every show.
  - If an application is closed and all dock forms are closed (in any order)
    the layout should be restored on startup, when the forms
    are created (in any order).
    This is done by saving the layout before all forms are closed.


  Example 1: Docking to a side.
    
    Current:
    +---+
    | A |
    +---+
    
    Formerly:
    +------------+
    |+---+|+----+|
    || A |||Self||
    |+---+|+----+|
    +------------+

    Then put A into a new TLazDockForm, add a splitter and Self.
    

  Example 2: Docking in between
  
    Current:
    +-----------+
    |+---+|+---+|
    || A ||| C ||
    |+---+|+---+|
    +-----------+

    Formerly:
    +------------------+
    |+---+|+----+|+---+|
    || A |||Self||| C ||
    |+---+|+----+|+---+|
    +------------------+

    Then enlarge the parent of A and C, add a splitter and Self.
    
  Example:

    Formerly:
    +-------------------------+
    |+-----------------------+|
    ||           A           ||
    |+-----------------------+|
    |=========================|
    |+---+#+-----------+#+---+|
    || D |#|           |#|   ||
    |+---+#|           |#|   ||
    |=====#|     B     |#| E ||
    |+---+#|           |#|   ||
    ||   |#|           |#|   ||
    ||   |#+-----------+#+---+|
    || F |#===================|
    ||   |#+-----------------+|
    ||   |#|        C        ||
    |+---+#+-----------------+|
    +-------------------------+


    1. Showing A:
    There is no other form yet, so just show it at the old position.
    +-----------------------+
    |           A           |
    +-----------------------+


    2. Showing B:
    B is the bottom sibling of A. Put A into a new TLazDockForm, add a splitter,
    enlarge B horizontally.

    +-------------------------+
    |+-----------------------+|
    ||           A           ||
    |+-----------------------+|
    |=========================|
    |+-----------------------+|
    ||                       ||
    ||                       ||
    ||           B           ||
    ||                       ||
    ||                       ||
    |+-----------------------+|
    +-------------------------+


    3. Showing C:
    C is the bottom sibling of B. Enlarge the parent vertically, add a splitter
    and enlarge C horizontally.
    
    +-------------------------+
    |+-----------------------+|
    ||           A           ||
    |+-----------------------+|
    |=========================|
    |+-----------------------+|
    ||                       ||
    ||                       ||
    ||           B           ||
    ||                       ||
    ||                       ||
    |+-----------------------+|
    |=========================|
    |+-----------------------+|
    ||           C           ||
    |+-----------------------+|
    +-------------------------+


    4. Showing D:
    D is below of A, and left of B and C. Shrink B and C, add a splitter.
    
    +-------------------------+
    |+-----------------------+|
    ||           A           ||
    |+-----------------------+|
    |=========================|
    |+---+#+-----------------+|
    ||   |#|                 ||
    ||   |#|                 ||
    ||   |#|        B        ||
    ||   |#|                 ||
    || D |#|                 ||
    ||   |#+-----------------+|
    ||   |#===================|
    ||   |#+-----------------+|
    ||   |#|        C        ||
    |+---+#+-----------------+|
    +-------------------------+


    5. Showing E:
    Shrink B, add a splitter.
    
    +-------------------------+
    |+-----------------------+|
    ||           A           ||
    |+-----------------------+|
    |=========================|
    |+---+#+-----------+#+---+|
    ||   |#|           |#|   ||
    ||   |#|           |#|   ||
    ||   |#|     B     |#| E ||
    ||   |#|           |#|   ||
    || D |#|           |#|   ||
    ||   |#+-----------+#+---+|
    ||   |#===================|
    ||   |#+-----------------+|
    ||   |#|        C        ||
    |+---+#+-----------------+|
    +-------------------------+


    6. Showing F:
    Shrink D and add a splitter.

    +-------------------------+
    |+-----------------------+|
    ||           A           ||
    |+-----------------------+|
    |=========================|
    |+---+#+-----------+#+---+|
    || D |#|           |#|   ||
    |+---+#|           |#|   ||
    |=====#|     B     |#| E ||
    |+---+#|           |#|   ||
    ||   |#|           |#|   ||
    ||   |#+-----------+#+---+|
    || F |#===================|
    ||   |#+-----------------+|
    ||   |#|        C        ||
    |+---+#+-----------------+|
    +-------------------------+
  }
type
  TSiblingDistance = (
    sdUnknown,
    sdThreeSides,        // sibling shares 3 sides
    sdOneSide,           // sibling shares 1 side
    sdSplitterThreeSides,// splitter, then sibling shares 3 sides
    sdSplitterOneSide    // splitter, then sibling shares 1 side
    );
var
  Layout: TLazDockerConfig;
  SelfNode: TLazDockConfigNode;

  procedure RaiseLayoutInconsistency(Node: TLazDockConfigNode);
  begin
    raise Exception.Create('TCustomLazControlDocker.RestoreLayout'
      +' DockerName="'+DockerName+'"'
      +' Control='+DbgSName(Control)
      +' Node='+Node.Name);
  end;
  
  procedure FindSibling(Node: TLazDockConfigNode; Side: TAnchorKind;
    out Sibling: TControl; out SiblingNode: TLazDockConfigNode;
    out Distance: TSiblingDistance);
  // find the nearest visible sibling control at Side
  var
    SiblingName: string;
  begin
    Sibling:=nil;
    SiblingNode:=nil;
    Distance:=sdUnknown;
    if Node=nil then exit;
    SiblingName:=Node.Sides[Side];
    if SiblingName<>'' then begin
      SiblingNode:=Layout.Root.FindByName(SiblingName,true);
      if SiblingNode=nil then
        RaiseLayoutInconsistency(Node);
      case SiblingNode.TheType of
      ldcntSplitterLeftRight,ldcntSplitterUpDown:
        begin
          FindSibling(SiblingNode,Side,Sibling,SiblingNode,Distance);
          if Distance=sdOneSide then
            Distance:=sdSplitterOneSide;
          if Distance=sdThreeSides then
            Distance:=sdSplitterThreeSides;
          if Distance=sdSplitterThreeSides then begin

          end;
          exit;
        end;
      else
        exit;
      end;
      // TODO
    end;
  end;
  
var
  NewBounds: TRect;
begin
  DebugLn(['TCustomLazControlDocker.RestoreLayout A ',DockerName,' Control=',DbgSName(Control)]);
  if (Manager=nil) or (Control=nil) then exit;
  Layout:=Manager.GetConfigWithDockerName(DockerName);
  if (Layout=nil) or (Layout.Root=nil) then exit;
  SelfNode:=Layout.Root.FindByName(DockerName,true);
  DebugLn(['TCustomLazControlDocker.RestoreLayout ',SelfNode<>nil,' DockerName=',DockerName,' ',Manager.Configs[0].DockerName]);
  if (SelfNode=nil) or (SelfNode.TheType<>ldcntControl) then exit;
  
  if SelfNode.Parent<>nil then begin
    // this control was docked
    case SelfNode.Parent.TheType of
    ldcntPage:
      begin
        // this control was docked as child of a page
        DebugLn(['TCustomLazControlDocker.RestoreLayout TODO restore page']);
      end;
    ldcntControl,ldcntForm:
      begin
        // this control was docked on a form as child
        DebugLn(['TCustomLazControlDocker.RestoreLayout TODO restore splitter']);
        //FindSibling(SelfNode,akLeft,LeftSibling,LeftSiblingDistance);
      end;
    else
      exit;
    end;
  end;
  
  // default: do not dock, just move
  DebugLn(['TCustomLazControlDocker.RestoreLayout ',DockerName,' not docking, just moving ...']);
  NewBounds:=SelfNode.GetScreenBounds;
  Control.SetBoundsKeepBase(NewBounds.Left,NewBounds.Top,
                            NewBounds.Right-NewBounds.Left,
                            NewBounds.Bottom-NewBounds.Top);
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
  ShowDockingEditor;
end;

procedure TCustomLazControlDocker.SetControl(const AValue: TControl);
begin
  if FControl=AValue then exit;
  if FControl<>nil then
    FControl.RemoveAllHandlersOfObject(Self);
  FControl:=AValue;
  if Control<>nil then begin
    Control.AddHandlerOnVisibleChanging(@ControlVisibleChanging);
    Control.AddHandlerOnVisibleChanged(@ControlVisibleChanged);
  end;
  if DockerName='' then
    DockerName:=AValue.Name;
  UpdatePopupMenu;
end;

procedure TCustomLazControlDocker.SetDockerName(const AValue: string);
var
  NewDockerName: String;
begin
  if FDockerName=AValue then exit;
  NewDockerName:=AValue;
  if Manager<>nil then
    NewDockerName:=Manager.CreateUniqueName(NewDockerName,Self);
  FDockerName:=NewDockerName;
end;

procedure TCustomLazControlDocker.SetExtendPopupMenu(const AValue: boolean);
begin
  if FExtendPopupMenu=AValue then exit;
  FExtendPopupMenu:=AValue;
  UpdatePopupMenu;
end;

procedure TCustomLazControlDocker.SetLocalizedName(const AValue: string);
begin
  if FLocalizedName=AValue then exit;
  FLocalizedName:=AValue;
end;

{ TCustomLazDockingManager }

procedure TCustomLazDockingManager.Remove(Docker: TCustomLazControlDocker);
begin
  FDockers.Remove(Docker);
end;

function TCustomLazDockingManager.Add(Docker: TCustomLazControlDocker): Integer;
begin
  Docker.DockerName:=CreateUniqueName(Docker.DockerName,nil);
  Result:=FDockers.Add(Docker);
end;

function TCustomLazDockingManager.GetDockers(Index: Integer
  ): TCustomLazControlDocker;
begin
  Result:=TCustomLazControlDocker(FDockers[Index]);
end;

function TCustomLazDockingManager.GetDockerCount: Integer;
begin
  Result:=FDockers.Count;
end;

function TCustomLazDockingManager.GetConfigCount: Integer;
begin
  if FConfigs<>nil then
    Result:=FConfigs.Count
  else
    Result:=0;
end;

function TCustomLazDockingManager.GetConfigs(Index: Integer
  ): TLazDockerConfig;
begin
  Result:=TLazDockerConfig(FConfigs[Index]);
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
  ClearConfigs;
  FreeAndNil(FConfigs);
  inherited Destroy;
end;

function TCustomLazDockingManager.FindDockerByName(const ADockerName: string;
  Ignore: TCustomLazControlDocker): TCustomLazControlDocker;
var
  i: Integer;
begin
  i:=DockerCount-1;
  while (i>=0) do begin
    Result:=Dockers[i];
    if (CompareText(Result.DockerName,ADockerName)=0) and (Ignore<>Result) then
      exit;
    dec(i);
  end;
  Result:=nil;
end;

function TCustomLazDockingManager.FindControlByDockerName(
  const ADockerName: string; Ignore: TCustomLazControlDocker): TControl;
var
  Docker: TCustomLazControlDocker;
begin
  Docker:=FindDockerByName(ADockerName);
  if Docker=nil then
    Result:=nil
  else
    Result:=Docker.Control;
end;

function TCustomLazDockingManager.FindDockerByControl(AControl: TControl;
  Ignore: TCustomLazControlDocker): TCustomLazControlDocker;
var
  i: Integer;
begin
  i:=DockerCount-1;
  while (i>=0) do begin
    Result:=Dockers[i];
    if (Result.Control=AControl) and (Ignore<>Result) then
      exit;
    dec(i);
  end;
  Result:=nil;
end;

function TCustomLazDockingManager.CreateUniqueName(const AName: string;
  Ignore: TCustomLazControlDocker): string;
begin
  Result:=AName;
  if FindDockerByName(Result,Ignore)=nil then exit;
  Result:=CreateFirstIdentifier(Result);
  while FindDockerByName(Result,Ignore)<>nil do
    Result:=CreateNextIdentifier(Result);
end;

function TCustomLazDockingManager.GetControlConfigName(AControl: TControl
  ): string;
var
  Docker: TCustomLazControlDocker;
begin
  Docker:=FindDockerByControl(AControl,nil);
  if Docker<>nil then
    Result:=Docker.DockerName
  else
    Result:='';
end;

procedure TCustomLazDockingManager.SaveToConfig(Config: TConfigStorage;
  const Path: string);
var
  i: Integer;
  ADocker: TCustomLazControlDocker;
  CurDockConfig: TLazDockerConfig;
  SubPath: String;
begin
  // collect configs
  for i:=0 to DockerCount-1 do begin
    ADocker:=Dockers[i];
    if ((ADocker.Control<>nil) and ADocker.Control.Visible) then begin
      ADocker.SaveLayout;
    end;
  end;

  // save configs
  Config.SetDeleteValue(Path+'Configs/Count',ConfigCount,0);
  for i:=0 to ConfigCount-1 do begin
    SubPath:=Path+'Config'+IntToStr(i)+'/';
    CurDockConfig:=Configs[i];
    Config.SetDeleteValue(SubPath+'DockerName/Value',CurDockConfig.DockerName,'');
    CurDockConfig.Root.SaveToConfig(Config,SubPath);
  end;
end;

procedure TCustomLazDockingManager.LoadFromConfig(Config: TConfigStorage;
  const Path: string);
var
  i: Integer;
  NewConfigCount: LongInt;
  SubPath: String;
  NewRoot: TLazDockConfigNode;
  NewDockerName: String;
  NewRootName: String;
begin
  // merge the configs
  NewConfigCount:=Config.GetValue(Path+'Configs/Count',0);
  DebugLn(['TCustomLazDockingManager.LoadFromConfig NewConfigCount=',NewConfigCount]);
  for i:=0 to NewConfigCount-1 do begin
    SubPath:=Path+'Config'+IntToStr(i)+'/';
    NewDockerName:=Config.GetValue(SubPath+'DockerName/Value','');
    if NewDockerName='' then continue;
    NewRootName:=Config.GetValue(SubPath+'Name/Value','');
    if NewRootName='' then continue;
    DebugLn(['TCustomLazDockingManager.LoadFromConfig NewDockerName=',NewDockerName,' NewRootName=',NewRootName]);
    NewRoot:=TLazDockConfigNode.Create(nil,NewRootName);
    NewRoot.LoadFromConfig(Config,SubPath);
    AddOrReplaceConfig(NewDockerName,NewRoot);
    NewRoot.WriteDebugReport;
  end;
end;

procedure TCustomLazDockingManager.AddOrReplaceConfig(
  const DockerName: string; Config: TLazDockConfigNode);
var
  i: Integer;
  CurConfig: TLazDockerConfig;
begin
  if FConfigs=nil then
    FConfigs:=TFPList.Create;
  for i:=FConfigs.Count-1 downto 0 do begin
    CurConfig:=Configs[i];
    if CompareText(CurConfig.DockerName,DockerName)=0 then begin
      CurConfig.FRoot.Free;
      CurConfig.FRoot:=Config;
      exit;
    end;
  end;
  FConfigs.Add(TLazDockerConfig.Create(DockerName,Config));
end;

procedure TCustomLazDockingManager.WriteDebugReport;
var
  i: Integer;
  ADocker: TCustomLazControlDocker;
begin
  DebugLn('TCustomLazDockingManager.WriteDebugReport DockerCount=',dbgs(DockerCount));
  for i:=0 to DockerCount-1 do begin
    ADocker:=Dockers[i];
    DebugLn('  ',dbgs(i),' Name="',ADocker.Name,'" DockerName="',ADocker.DockerName,'"');
  end;
end;

procedure TCustomLazDockingManager.ClearConfigs;
var
  i: Integer;
begin
  if FConfigs=nil then exit;
  for i:=0 to FConfigs.Count-1 do TObject(FConfigs[i]).Free;
  FConfigs.Clear;
end;

function TCustomLazDockingManager.GetConfigWithDockerName(
  const DockerName: string): TLazDockerConfig;
var
  i: Integer;
begin
  i:=ConfigCount-1;
  while (i>=0) do begin
    Result:=Configs[i];
    if CompareText(Result.DockerName,DockerName)=0 then exit;
    dec(i);
  end;
  Result:=nil;
end;

function TCustomLazDockingManager.CreateLayout(const DockerName: string;
  VisibleControl: TControl; ExceptionOnError: boolean): TLazDockConfigNode;
// create a usable config
// This means: search a config, create a copy
// and remove all nodes without visible controls.
var
  Root: TLazDockConfigNode;
  CurDockControl: TControl;

  function ControlIsVisible(AControl: TControl): boolean;
  begin
    Result:=false;
    if (AControl=nil) then exit;
    if (not AControl.IsVisible) and (AControl<>VisibleControl) then exit;
    if (CurDockControl<>nil) and (CurDockControl<>AControl.GetTopParent) then
      exit;
    Result:=true;
  end;
  
  function FindNode(const AName: string): TLazDockConfigNode;
  begin
    if AName='' then
      Result:=nil
    else
      Result:=Root.FindByName(AName,true,true);
  end;
  
  function FindNodeUsingSplitter(Splitter: TLazDockConfigNode;
    SiblingSide: TAnchorKind; NilIfAmbiguous: boolean): TLazDockConfigNode;
  var
    i: Integer;
    ParentNode: TLazDockConfigNode;
    Child: TLazDockConfigNode;
  begin
    Result:=nil;
    ParentNode:=Splitter.Parent;
    for i:=0 to ParentNode.ChildCount-1 do begin
      Child:=ParentNode.Childs[i];
      if CompareText(Child.Sides[SiblingSide],Splitter.Name)=0 then begin
        if Result=nil then
          Result:=Child
        else if NilIfAmbiguous then
          exit(nil);
      end;
    end;
  end;
  
  function SplitterIsOnlyUsedByNodeAtSide(Splitter, Node: TLazDockConfigNode;
    SiblingSide: TAnchorKind): boolean;
  { check if one side of the Splitter is only used by Node.
    For example: If only Node.Sides[SiblingSide]=Splitter.Name
        ---------+      --------+
        --+#+---+|          ---+|
        B |#| A ||  ->       B ||
        --+#+---+|          ---+|
        ---------+      --------+}
  begin
    Result:=FindNodeUsingSplitter(Splitter,SiblingSide,true)<>nil;
  end;

  procedure DeleteNode(var DeletingNode: TLazDockConfigNode);
  
    function IsOwnSideSplitter(Side: TAnchorKind;
      var SplitterNode: TLazDockConfigNode): boolean;
    { check if DeletingNode has a splitter to Side, and this node is the only
      node anchored to the splitter at this side.
      If yes, it removes the splitter and the DeletingNode and reconnects the
      nodes using the splitter with the opposite side
      For example:
        ---------+      --------+
        --+#+---+|          ---+|
        B |#| A ||  ->       B ||
        --+#+---+|          ---+|
        ---------+      --------+
    }
    var
      i: Integer;
      Sibling: TLazDockConfigNode;
      OppositeSide: TAnchorKind;
    begin
      Result:=false;
      // check if this is the only node using this Side of the splitter
      if not SplitterIsOnlyUsedByNodeAtSide(SplitterNode,DeletingNode,
        Side) then exit;

      // All nodes, that uses the splitter from the other side will now be
      // anchored to the other side of DeletingNode
      OppositeSide:=OppositeAnchor[Side];
      for i:=0 to DeletingNode.Parent.ChildCount-1 do begin
        Sibling:=DeletingNode.Parent.Childs[i];
        if CompareText(Sibling.Sides[OppositeSide],SplitterNode.Name)=0 then
          Sibling.Sides[OppositeSide]:=DeletingNode.Sides[OppositeSide];
      end;
      
      // delete splitter
      FreeAndNil(SplitterNode);

      Result:=true;
    end;
    
    function UnbindSpiralNode: boolean;
    { DeletingNode has 4 splitters like a spiral.
      In this case merge the two vertical splitters.
      For example:
             |             |
      -------|        -----|
       |+---+|             |
       || A ||   ->        |
       |+---+|             |
       |--------           |------
       |                   |
    }
    var
      LeftSplitter: TLazDockConfigNode;
      RightSplitter: TLazDockConfigNode;
      i: Integer;
      Sibling: TLazDockConfigNode;
    begin
      LeftSplitter:=FindNode(DeletingNode.Sides[akLeft]);
      RightSplitter:=FindNode(DeletingNode.Sides[akRight]);
      // remove LeftSplitter
      
      // 1. enlarge RightSplitter
      if CompareText(RightSplitter.Sides[akTop],DeletingNode.Sides[akTop])=0 then
        RightSplitter.Sides[akTop]:=LeftSplitter.Sides[akTop];
      if CompareText(RightSplitter.Sides[akBottom],DeletingNode.Sides[akBottom])=0 then
        RightSplitter.Sides[akBottom]:=LeftSplitter.Sides[akBottom];
        
      // 2. anchor all siblings using LeftSplitter to now use RightSplitter
      for i:=0 to DeletingNode.Parent.ChildCount-1 do begin
        Sibling:=DeletingNode.Parent.Childs[i];
        if Sibling=DeletingNode then continue;
        if CompareText(Sibling.Sides[akLeft],LeftSplitter.Name)=0 then
          Sibling.Sides[akLeft]:=RightSplitter.Name;
        if CompareText(Sibling.Sides[akRight],LeftSplitter.Name)=0 then
          Sibling.Sides[akRight]:=RightSplitter.Name;
      end;
      
      // 3. delete LeftSplitter
      FreeAndNil(LeftSplitter);
      
      Result:=true;
    end;
  
    procedure RaiseUnknownCase;
    begin
      raise Exception.Create('TCustomLazDockingManager.CreateLayout invalid Config');
    end;

  var
    a: TAnchorKind;
    SiblingNode: TLazDockConfigNode;
    SplitterCount: Integer;
  begin
    SplitterCount:=0;
    for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
      SiblingNode:=FindNode(DeletingNode.Sides[a]);
      if (SiblingNode<>nil)
      and (SiblingNode.TheType in [ldcntSplitterLeftRight,ldcntSplitterUpDown])
      then begin
        // there is a splitter
        if IsOwnSideSplitter(a,SiblingNode) then break;
        inc(SplitterCount);
      end;
    end;
    if SplitterCount=0 then begin
      // no splitter -> simply delete the node
    end else if SplitterCount=4 then begin
      // this is a spiral splitter node
      UnbindSpiralNode;
    end else begin
      // this should never be reached
      RaiseUnknownCase;
    end;
    FreeAndNil(DeletingNode);
  end;
  
  procedure SimplifyOnePageNode(var PagesNode: TLazDockConfigNode);
  { PagesNode has only one page left.
    Remove Page and Pages node and move the content to the parent
  }
  var
    ParentNode: TLazDockConfigNode;
    PageNode: TLazDockConfigNode;
    i: Integer;
    Child: TLazDockConfigNode;
    ChildBounds: TRect;
    PagesBounds: TRect;
    OffsetX: Integer;
    OffsetY: Integer;
    a: TAnchorKind;
  begin
    DebugLn(['SimplifyOnePageNode ',dbgs(PagesNode)]);
    ParentNode:=PagesNode.Parent;
    if ParentNode=nil then RaiseGDBException('');
    if (PagesNode.TheType<>ldcntPages) then RaiseGDBException('');
    if PagesNode.ChildCount<>1 then RaiseGDBException('');
    PageNode:=PagesNode.Childs[0];
    PagesBounds:=PagesNode.Bounds;
    OffsetX:=PagesBounds.Left;
    OffsetY:=PagesBounds.Top;
    for i:=0 to PageNode.ChildCount-1 do begin
      Child:=PageNode.Childs[i];
      // changes parent of child
      Child.Parent:=ParentNode;
      // move childs to place where PagesNode was
      ChildBounds:=Child.Bounds;
      OffsetRect(ChildBounds,OffsetX,OffsetY);
      Child.Bounds:=ChildBounds;
      // change anchors of child
      for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
        if CompareText(Child.Sides[a],PageNode.Name)=0 then
          Child.Sides[a]:=PagesNode.Sides[a];
      end;
    end;
    FreeAndNil(PagesNode);
  end;

  procedure RemoveEmptyNodes(var Node: TLazDockConfigNode);
  // remove unneeded child nodes
  // if no childs left and Node itself is unneeded, it s freed and set to nil
  var
    i: Integer;
    Docker: TCustomLazControlDocker;
    Child: TLazDockConfigNode;
  begin
    if Node=nil then exit;
    DebugLn(['RemoveEmptyNodes ',Node.Name,' Node.ChildCount=',Node.ChildCount]);
    
    // remove unneeded childs
    i:=Node.ChildCount-1;
    while i>=0 do begin
      Child:=Node.Childs[i];
      RemoveEmptyNodes(Child);// beware: this can delete more than one child
      dec(i);
      if i>=Node.ChildCount then i:=Node.ChildCount-1;
    end;
      
    case Node.TheType of
    ldcntControl:
      begin
        Docker:=FindDockerByName(Node.Name);
        // if the associated control does not exist or is not visible,
        // then delete the node
        if (Docker=nil) or not ControlIsVisible(Docker.Control) then begin
          DebugLn(['RemoveEmptyNodes delete unknown or invisible node: ',dbgs(Node)]);
          DeleteNode(Node);
        end;
      end;
    ldcntForm,ldcntPage:
      // these are auto created parent nodes. If they have no childs: delete
      if Node.ChildCount=0 then begin
        DebugLn(['RemoveEmptyNodes delete node without childs: ',dbgs(Node)]);
        DeleteNode(Node);
      end;
    ldcntPages:
      // this is an auto created parent node. If it has no childs: delete
      if Node.ChildCount=0 then begin
        DebugLn(['RemoveEmptyNodes delete node without childs: ',dbgs(Node)]);
        DeleteNode(Node);
      end else if Node.ChildCount=1 then begin
        // Only one page left
        SimplifyOnePageNode(Node);
      end;
    end;
  end;

  function AllControlsAreOnSameForm: boolean;
  var
    RootForm: TControl;
  
    function Check(Node: TLazDockConfigNode): boolean;
    var
      i: Integer;
      CurForm: TControl;
    begin
      if Node.TheType=ldcntControl then begin
        CurForm:=FindControlByDockerName(Node.Name);
        if (CurForm<>nil) then begin
          while CurForm.Parent<>nil do
            CurForm:=CurForm.Parent;
          if RootForm=nil then
            RootForm:=CurForm
          else if RootForm<>CurForm then
            exit(false);
        end;
      end;
      // check childs
      for i:=0 to Node.ChildCount-1 do
        if not Check(Node.Childs[i]) then exit(false);
      Result:=true;
    end;
  
  begin
    RootForm:=nil;
    Result:=Check(Root);
  end;
  
  function FindNearestControlNode: TLazDockConfigNode;
  
    function FindOwnSplitterSiblingWithControl(Node: TLazDockConfigNode
      ): TLazDockConfigNode;
    { find a sibling, that is a direct neighbour behind a splitter, and the
      splitter is only used by the node and the sibling
      For example:
        ---------+
        --+#+---+|
        B |#| A ||
        --+#+---+|
        ---------+
    }
    var
      a: TAnchorKind;
      SplitterNode: TLazDockConfigNode;
    begin
      for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
        if Node.Sides[a]='' then continue;
        SplitterNode:=FindNode(Node.Sides[a]);
        if (SplitterNode.TheType in [ldcntSplitterLeftRight,ldcntSplitterUpDown])
        and SplitterIsOnlyUsedByNodeAtSide(SplitterNode,Node,a) then
        begin
          Result:=FindNodeUsingSplitter(SplitterNode,OppositeAnchor[a],true);
          if Result<>nil then exit;
        end;
      end;
      Result:=nil;
    end;
    
    function FindSiblingWithControl(Node: TLazDockConfigNode
      ): TLazDockConfigNode;
    var
      ParentNode: TLazDockConfigNode;
      i: Integer;
    begin
      ParentNode:=Node.Parent;
      for i:=0 to ParentNode.ChildCount-1 do begin
        Result:=ParentNode.Childs[i];
        if CompareText(Result.Name,DockerName)=0 then continue;
        if Result.TheType=ldcntControl then
          exit;
      end;
      Result:=nil;
    end;

    function FindPageSiblingWithControl(Node: TLazDockConfigNode
      ): TLazDockConfigNode;
    { find direct page sibling
      This means:
        Node is the only child of a page
        A sibling page has a single child with a control
    }
    var
      PagesNode: TLazDockConfigNode;
      PageNode: TLazDockConfigNode;
      PageIndex: LongInt;
    begin
      // check if node is on a page without siblings
      PageNode:=Node.Parent;
      if (PageNode=nil) or (PageNode.TheType<>ldcntPage)
      or (PageNode.ChildCount>1) then exit;
      // check if left page has only one control
      PagesNode:=PageNode.Parent;
      PageIndex:=PagesNode.IndexOf(PageNode.Name);
      if (PageIndex>0)
      and (PagesNode[PageIndex-1].ChildCount=1) then begin
        Result:=PagesNode[PageIndex-1].Childs[0];
        if Result.TheType=ldcntControl then exit;
      end;
      // check if right page has only one control
      if (PageIndex<PagesNode.ChildCount-1)
      and (PagesNode[PageIndex+1].ChildCount=1) then begin
        Result:=PagesNode[PageIndex+1].Childs[0];
        if Result.TheType=ldcntControl then exit;
      end;
      Result:=nil;
    end;

    function FindOtherNodeWithControl(Node: TLazDockConfigNode
      ): TLazDockConfigNode;
    var
      i: Integer;
    begin
      Result:=nil;
      if (Node.TheType=ldcntControl)
      and (CompareText(Node.Name,DockerName)<>0) then
        exit(Node);
      for i:=0 to Node.ChildCount-1 do begin
        Result:=FindOtherNodeWithControl(Node.Childs[i]);
        if Result<>nil then exit;
      end;
    end;
  
  var
    Node: TLazDockConfigNode;
  begin
    Node:=FindNode(DockerName);
    Result:=FindOwnSplitterSiblingWithControl(Node);
    if Result<>nil then exit;
    Result:=FindSiblingWithControl(Node);
    Node:=Root.FindByName(DockerName);
    Result:=FindPageSiblingWithControl(Node);
    if Result<>nil then exit;
    Result:=FindOtherNodeWithControl(Root);
  end;

var
  Config: TLazDockerConfig;
  CurControl: TControl;
  NearestControlNode: TLazDockConfigNode;
begin
  Result:=nil;
  CurDockControl:=nil;
  Root:=nil;
  
  Config:=GetConfigWithDockerName(DockerName);
  DebugLn(['TCustomLazDockingManager.CreateLayout DockerName="',DockerName,'"']);
  config.WriteDebugReport;
  if (Config=nil) or (Config.Root=nil) then exit;
  CurControl:=FindControlByDockerName(DockerName);
  DebugLn(['TCustomLazDockingManager.CreateLayout CurControl=',DbgSName(CurControl)]);
  if not ControlIsVisible(CurControl) then exit;
  DebugLn(['TCustomLazDockingManager.CreateLayout CurControl is treated as visible']);
  if (not ConfigIsCompatible(Config.Root,ExceptionOnError)) then exit;
  DebugLn(['TCustomLazDockingManager.CreateLayout Config is compatible']);

  // create a copy of the config
  Root:=TLazDockConfigNode.Create(nil);
  try
    Root.Assign(Config.Root);

    // clean up by removing all invisible, unknown and empty nodes
    RemoveEmptyNodes(Root);

    // check if all used controls are on the same dock form
    if not AllControlsAreOnSameForm then begin
      // the used controls are distributed on different dock forms
      // => choose one dock form and remove the nodes of the others
      NearestControlNode:=FindNearestControlNode;
      if NearestControlNode<>nil then begin
        CurDockControl:=FindControlByDockerName(NearestControlNode.Name);
        if CurDockControl<>nil then begin
          CurDockControl:=CurDockControl.GetTopParent;
          // remove nodes of other dock forms
          RemoveEmptyNodes(Root);
        end;
      end;
    end;

    Result:=Root;
    Root:=nil;
  finally
    Root.Free;
  end;
end;

function TCustomLazDockingManager.ConfigIsCompatible(
  RootNode: TLazDockConfigNode; ExceptionOnError: boolean): boolean;
  
  function CheckNode(Node: TLazDockConfigNode): boolean;
  
    procedure Error(const Msg: string);
    var
      s: String;
    begin
      s:='Error: Node="'+Node.GetPath+'"';
      s:=s+' NodeType='+LDConfigNodeTypeNames[Node.TheType];
      s:=s+Msg;
      DebugLn(s);
      if ExceptionOnError then raise Exception.Create(s);
    end;
    
    function CheckSideAnchored(a: TAnchorKind): boolean;
    var
      SiblingName: string;
      Sibling: TLazDockConfigNode;
      
      procedure ErrorWrongSplitter;
      begin
        Error('invalid Node.Sides[a] Node="'+Node.Name+'"'
          +' Node.Sides['+AnchorNames[a]+']="'+Node.Sides[a]+'"');
      end;
      
    begin
      SiblingName:=Node.Sides[a];
      if SiblingName='' then begin
        Error('Node.Sides[a]=''''');
        exit(false);
      end;
      Sibling:=RootNode.FindByName(SiblingName,true);
      if Sibling=nil then begin
        Error('Node.Sides[a] not found');
        exit(false);
      end;
      if Sibling=Node.Parent then
        exit(true); // anchored to parent: ok
      if (a in [akLeft,akRight]) and (Sibling.TheType=ldcntSplitterLeftRight)
      then
        exit(true); // left/right side anchored to a left/right splitter: ok
      if (a in [akTop,akBottom]) and (Sibling.TheType=ldcntSplitterUpDown)
      then
        exit(true); // top/bottom side anchored to a up/down splitter: ok
      // otherwise: not ok
      ErrorWrongSplitter;
      Result:=false;
    end;
    
    function CheckAllSidesAnchored: boolean;
    var
      a: TAnchorKind;
    begin
      for a:=Low(TAnchorKind) to High(TAnchorKind) do
        if not CheckSideAnchored(a) then exit(false);
      Result:=true;
    end;
    
    function CheckSideNotAnchored(a: TAnchorKind): boolean;
    begin
      if Node.Sides[a]<>'' then begin
        Error('Sides[a]<>''''');
        Result:=false;
      end else
        Result:=true;
    end;
    
    function CheckNoSideAnchored: boolean;
    var
      a: TAnchorKind;
    begin
      for a:=Low(TAnchorKind) to High(TAnchorKind) do
        if not CheckSideNotAnchored(a) then exit(false);
      Result:=true;
    end;
    
    function CheckHasChilds: boolean;
    begin
      if Node.ChildCount=0 then begin
        Error('ChildCount=0');
        Result:=false;
      end else
        Result:=true;
    end;

    function CheckHasNoChilds: boolean;
    begin
      if Node.ChildCount>0 then begin
        Error('ChildCount>0');
        Result:=false;
      end else
        Result:=true;
    end;
    
    function CheckHasParent: boolean;
    begin
      if Node.Parent=nil then begin
        Error('Parent=nil');
        Result:=false;
      end else
        Result:=true;
    end;

  var
    a: TAnchorKind;
    i: Integer;
  begin
    Result:=false;
    
    for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
      if Node.Sides[a]<>'' then begin
        if CompareText(Node.Sides[a],Node.Name)=0 then begin
          Error('Node.Sides[a]=Node');
          exit;
        end;
        if RootNode.FindByName(Node.Sides[a],true)=nil then begin
          Error('unknown Node.Sides[a]');
          exit;
        end;
      end;
    end;
    
    case Node.TheType of
    ldcntControl:
      begin
        // a control node contains a TControl
        if not CheckAllSidesAnchored then exit;
      end;
    ldcntForm:
      begin
        // a dock form is a dummy control, used as top level container
        if Node.Parent<>nil then begin
          Error('Parent<>nil');
          exit;
        end;
        if not CheckHasChilds then exit;
        if not CheckNoSideAnchored then exit;
      end;
    ldcntPages:
      begin
        // a pages node has only page nodes as childs
        if not CheckHasChilds then exit;
        for i:=0 to Node.ChildCount-1 do
          if Node.Childs[i].TheType<>ldcntPage then begin
            Error('Childs[i].TheType<>ldcntPage');
            exit;
          end;
        if not CheckAllSidesAnchored then exit;
      end;
    ldcntPage:
      begin
        // a page is the child of a pages node, and a container
        if not CheckHasParent then exit;
        if not CheckHasChilds then exit;
        if Node.Parent.TheType<>ldcntPages then begin
          Error('Parent.TheType<>ldcntPages');
          exit;
        end;
        if not CheckNoSideAnchored then exit;
      end;
    ldcntSplitterLeftRight:
      begin
        // a vertical splitter can be moved left/right
        if not CheckHasParent then exit;
        if not CheckHasNoChilds then exit;
        if not CheckSideNotAnchored(akLeft) then exit;
        if not CheckSideNotAnchored(akRight) then exit;
        CheckSideAnchored(akTop);
        CheckSideAnchored(akBottom);
      end;
    ldcntSplitterUpDown:
      begin
        // a horizontal splitter can be moved up/down
        // it is anchored left and right, and not top/bottom
        // it is not a root node
        // it has no childs
        if not CheckHasParent then exit;
        if not CheckHasNoChilds then exit;
        if not CheckSideNotAnchored(akTop) then exit;
        if not CheckSideNotAnchored(akBottom) then exit;
        CheckSideAnchored(akLeft);
        CheckSideAnchored(akRight);
      end;
    else
      Error('unknown type');
      exit;
    end;
    
    // check childs
    for i:=0 to Node.ChildCount-1 do
      if not CheckNode(Node.Childs[i]) then exit;

    Result:=true;
  end;
  
begin
  if RootNode=nil then exit(false);
  Result:=CheckNode(RootNode);
end;

{ TLazDockConfigNode }

function TLazDockConfigNode.GetSides(Side: TAnchorKind): string;
begin
  Result:=FSides[Side];
end;

function TLazDockConfigNode.GetChildCount: Integer;
begin
  if FChilds<>nil then
    Result:=FChilds.Count
  else
    Result:=0;
end;

function TLazDockConfigNode.GetChilds(Index: integer): TLazDockConfigNode;
begin
  Result:=TLazDockConfigNode(FChilds[Index]);
end;

procedure TLazDockConfigNode.SetBounds(const AValue: TRect);
begin
  if CompareRect(@FBounds,@AValue) then exit;
  FBounds:=AValue;
end;

procedure TLazDockConfigNode.SetClientBounds(const AValue: TRect);
begin
  if CompareRect(@FClientBounds,@AValue) then exit;
  FClientBounds:=AValue;
end;

procedure TLazDockConfigNode.SetName(const AValue: string);
begin
  if FName=AValue then exit;
  FName:=AValue;
end;

procedure TLazDockConfigNode.SetParent(const AValue: TLazDockConfigNode);
begin
  if FParent=AValue then exit;
  if FParent<>nil then
    FParent.DoRemove(Self);
  FParent:=AValue;
  if FParent<>nil then
    FParent.DoAdd(Self);
end;

procedure TLazDockConfigNode.SetSides(Side: TAnchorKind;
  const AValue: string);
begin
  FSides[Side]:=AValue;
end;

procedure TLazDockConfigNode.SetTheType(const AValue: TLDConfigNodeType);
begin
  if FTheType=AValue then exit;
  FTheType:=AValue;
end;

procedure TLazDockConfigNode.DoAdd(ChildNode: TLazDockConfigNode);
begin
  if FChilds=nil then FChilds:=TFPList.Create;
  FChilds.Add(ChildNode);
end;

procedure TLazDockConfigNode.DoRemove(ChildNode: TLazDockConfigNode);
begin
  if TObject(FChilds[FChilds.Count-1])=ChildNode then
    FChilds.Delete(FChilds.Count-1)
  else
    FChilds.Remove(ChildNode);
end;

constructor TLazDockConfigNode.Create(ParentNode: TLazDockConfigNode);
begin
  FTheType:=ldcntControl;
  Parent:=ParentNode;
end;

constructor TLazDockConfigNode.Create(ParentNode: TLazDockConfigNode;
  const AName: string);
begin
  FName:=AName;
  Create(ParentNode);
end;

destructor TLazDockConfigNode.Destroy;
begin
  Clear;
  Parent:=nil;
  FChilds.Free;
  FChilds:=nil;
  inherited Destroy;
end;

procedure TLazDockConfigNode.Clear;
var
  i: Integer;
begin
  if FChilds=nil then exit;
  for i:=ChildCount-1 downto 0 do Childs[i].Free;
  FChilds.Clear;
end;

procedure TLazDockConfigNode.Assign(Source: TPersistent);
var
  Src: TLazDockConfigNode;
  i: Integer;
  SrcChild: TLazDockConfigNode;
  NewChild: TLazDockConfigNode;
  a: TAnchorKind;
begin
  if Source is TLazDockConfigNode then begin
    Clear;
    Src:=TLazDockConfigNode(Source);
    FBounds:=Src.FBounds;
    FClientBounds:=Src.FClientBounds;
    FName:=Src.FName;
    for a:=Low(TAnchorKind) to High(TAnchorKind) do
      FSides[a]:=Src.FSides[a];
    FTheType:=Src.FTheType;
    for i:=0 to Src.ChildCount-1 do begin
      SrcChild:=Src.Childs[i];
      NewChild:=TLazDockConfigNode.Create(Self);
      NewChild.Assign(SrcChild);
      FChilds.Add(NewChild);
    end;
  end else
    inherited Assign(Source);
end;

function TLazDockConfigNode.FindByName(const AName: string;
  Recursive: boolean; WithRoot: boolean): TLazDockConfigNode;
var
  i: Integer;
begin
  if WithRoot and (CompareText(Name,AName)=0) then exit(Self);
  if FChilds<>nil then
    for i:=0 to FChilds.Count-1 do begin
      Result:=Childs[i];
      if CompareText(Result.Name,AName)=0 then exit;
      if Recursive then begin
        Result:=Result.FindByName(AName,true,false);
        if Result<>nil then exit;
      end;
    end;
  Result:=nil;
end;

function TLazDockConfigNode.IndexOf(const AName: string): Integer;
begin
  if FChilds<>nil then begin
    Result:=FChilds.Count-1;
    while (Result>=0) and (CompareText(Childs[Result].Name,AName)<>0) do
      dec(Result);
  end else begin
    Result:=-1;
  end;
end;

function TLazDockConfigNode.GetScreenBounds: TRect;
var
  NewWidth: Integer;
  NewHeight: Integer;
  NewLeft: LongInt;
  NewTop: LongInt;
  Node: TLazDockConfigNode;
begin
  NewWidth:=FBounds.Right-FBounds.Left;
  NewHeight:=FBounds.Bottom-FBounds.Top;
  NewLeft:=FBounds.Left;
  NewTop:=FBounds.Top;
  Node:=Parent;
  while Node<>nil do begin
    inc(NewLeft,Node.FBounds.Left+Node.FClientBounds.Left);
    inc(NewTop,Node.FBounds.Top+Node.FClientBounds.Top);
    Node:=Node.Parent;
  end;
  Result:=Classes.Bounds(NewLeft,NewTop,NewWidth,NewHeight);
end;

procedure TLazDockConfigNode.SaveToConfig(Config: TConfigStorage;
  const Path: string);
var
  a: TAnchorKind;
  i: Integer;
  Child: TLazDockConfigNode;
  SubPath: String;
begin
  Config.SetDeleteValue(Path+'Name/Value',Name,'');
  Config.SetDeleteValue(Path+'Type/Value',LDConfigNodeTypeNames[TheType],
                        LDConfigNodeTypeNames[ldcntControl]);
  Config.SetDeleteValue(Path+'Bounds/',FBounds,Rect(0,0,0,0));
  Config.SetDeleteValue(Path+'ClientBounds/',FClientBounds,
                Rect(0,0,FBounds.Right-FBounds.Left,FBounds.Bottom-FBounds.Top));

  // Sides
  for a:=Low(TAnchorKind) to High(TAnchorKind) do
    Config.SetDeleteValue(Path+'Sides/'+AnchorNames[a]+'/Name',Sides[a],'');

  // childs
  Config.SetDeleteValue(Path+'Childs/Count',ChildCount,0);
  for i:=0 to ChildCount-1 do begin
    Child:=Childs[i];
    SubPath:=Path+'Child'+IntToStr(i+1)+'/';
    Child.SaveToConfig(Config,SubPath);
  end;
end;

procedure TLazDockConfigNode.LoadFromConfig(Config: TConfigStorage;
  const Path: string);
var
  a: TAnchorKind;
  i: Integer;
  NewChildCount: LongInt;
  NewChildName: String;
  NewChild: TLazDockConfigNode;
  SubPath: String;
begin
  Clear;
  // Note: 'Name' is stored only for information, but not restored on load
  TheType:=LDConfigNodeTypeNameToType(Config.GetValue(Path+'Type/Value',
                                      LDConfigNodeTypeNames[ldcntControl]));
  Config.GetValue(Path+'Bounds/',FBounds,Rect(0,0,0,0));
  Config.GetValue(Path+'ClientBounds/',FClientBounds,
               Rect(0,0,FBounds.Right-FBounds.Left,FBounds.Bottom-FBounds.Top));

  // Sides
  for a:=Low(TAnchorKind) to High(TAnchorKind) do
    Sides[a]:=Config.GetValue(Path+'Sides/'+AnchorNames[a]+'/Name','');

  // childs
  NewChildCount:=Config.GetValue(Path+'Childs/Count',0);
  for i:=0 to NewChildCount-1 do begin
    SubPath:=Path+'Child'+IntToStr(i+1)+'/';
    NewChildName:=Config.GetValue(SubPath+'Name/Value','');
    NewChild:=TLazDockConfigNode.Create(Self,NewChildName);
    NewChild.Parent:=Self;
    NewChild.LoadFromConfig(Config,SubPath);
  end;
end;

procedure TLazDockConfigNode.WriteDebugReport;

  procedure WriteNode(const Prefix: string; ANode: TLazDockConfigNode);
  var
    a: TAnchorKind;
    i: Integer;
    s: string;
  begin
    if ANode=nil then exit;
    DbgOut(Prefix,'Name="'+ANode.Name+'"');
    DbgOut(' Type=',GetEnumName(TypeInfo(TLDConfigNodeType),ord(ANode.TheType)));
    DbgOut(' Bounds='+dbgs(ANode.Bounds));
    DbgOut(' ClientBounds='+dbgs(ANode.ClientBounds));
    DbgOut(' Childs='+dbgs(ANode.ChildCount));
    for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
      s:=ANode.Sides[a];
      if s='' then
        s:='?';
      DbgOut(' '+AnchorNames[a]+'="'+s+'"');
    end;
    debugln;
    for i:=0 to ANode.ChildCount-1 do begin
      WriteNode(Prefix+'  ',ANode[i]);
    end;
  end;

begin
  DebugLn('TLazDockConfigNode.WriteDebugReport Root=',dbgs(Self));
  WriteNode('  ',Self);
  DebugLn(DebugLayoutAsString);
end;

function TLazDockConfigNode.DebugLayoutAsString: string;
type
  TArrayOfRect = array of TRect;
  TNodeInfo = record
    MinSize: TPoint;
    MinSizeValid, MinSizeCalculating: boolean;
    MinLeft: integer;
    MinLeftValid, MinLeftCalculating: boolean;
    MinTop: Integer;
    MinTopValid, MinTopCalculating: boolean;
  end;
  PNodeInfo = ^TNodeInfo;
var
  Cols: LongInt;
  Rows: LongInt;
  LogCols: Integer;
  NodeInfos: TPointerToPointerTree;// TLazDockConfigNode to PNodeInfo
  
  procedure InitNodeInfos;
  begin
    NodeInfos:=TPointerToPointerTree.Create;
  end;

  procedure FreeNodeInfos;
  var
    Item: PNodeInfo;
    NodePtr, InfoPtr: Pointer;
  begin
    NodeInfos.GetFirst(NodePtr,InfoPtr);
    repeat
      Item:=PNodeInfo(InfoPtr);
      if Item=nil then break;
      Dispose(Item);
    until not  NodeInfos.GetNext(NodePtr,NodePtr,InfoPtr);
  end;
  
  function GetNodeInfo(Node: TLazDockConfigNode): PNodeInfo;
  begin
    Result:=PNodeInfo(NodeInfos[Node]);
    if Result=nil then begin
      New(Result);
      FillChar(Result^,SizeOf(Result),0);
      NodeInfos[Node]:=Result;
    end;
  end;

  procedure w(x,y: Integer; const s: string; MaxY: Integer = 0);
  var
    i: Integer;
  begin
    for i:=1 to length(s) do begin
      if (MaxY>0) and (y>MaxY) then exit;
      Result[LogCols*(y-1) + x + i-1]:=s[i];
    end;
  end;

  procedure wfillrect(const ARect: TRect; c: char);
  var
    x: LongInt;
    y: LongInt;
  begin
    for x:=ARect.Left to ARect.Right do
      for y:=ARect.Top to ARect.Bottom do
        w(x,y,c);
  end;
  
  procedure wrectangle(const ARect: TRect);
  begin
    w(ARect.Left,ARect.Top,'+');
    w(ARect.Right,ARect.Top,'+');
    w(ARect.Left,ARect.Bottom,'+');
    w(ARect.Right,ARect.Bottom,'+');
    if ARect.Left<ARect.Right then begin
      if ARect.Top<ARect.Bottom then begin
        wfillrect(Rect(ARect.Left+1,ARect.Top,ARect.Right-1,ARect.Top),'-');// top line
        wfillrect(Rect(ARect.Left+1,ARect.Bottom,ARect.Right-1,ARect.Bottom),'-');// bottom line
        wfillrect(Rect(ARect.Left,ARect.Top+1,ARect.Left,ARect.Bottom-1),'|');// left line
        wfillrect(Rect(ARect.Right,ARect.Top+1,ARect.Right,ARect.Bottom-1),'|');// right line
      end else begin
        wfillrect(Rect(ARect.Left+1,ARect.Top,ARect.Right-1,ARect.Top),'=');// horizontal line
      end;
    end else begin
      wfillrect(Rect(ARect.Left,ARect.Top+1,ARect.Left,ARect.Bottom-1),'#');// vertical line
    end;
  end;
  
  function MapRect(const OriginalRect, OldBounds, NewBounds: TRect): TRect;
  
    function MapX(i: Integer): Integer;
    begin
      Result:=NewBounds.Left+
        (((i-OldBounds.Left)*(NewBounds.Right-NewBounds.Left))
         div (OldBounds.Right-OldBounds.Left));
    end;
  
    function MapY(i: Integer): Integer;
    begin
      Result:=NewBounds.Top+
        (((i-OldBounds.Top)*(NewBounds.Bottom-NewBounds.Top))
         div (OldBounds.Bottom-OldBounds.Top));
    end;

  begin
    Result.Left:=MapX(OriginalRect.Left);
    Result.Top:=MapY(OriginalRect.Left);
    Result.Right:=MapX(OriginalRect.Left);
    Result.Bottom:=MapY(OriginalRect.Left);
  end;
  
  function GetMinSize(Node: TLazDockConfigNode): TPoint; forward;
  
  function GetMinPos(Node: TLazDockConfigNode; Side: TAnchorKind): Integer;
  // calculates left or top position of Node
  
    function Compute(var MinPosValid, MinPosCalculating: boolean; var MinPos: Integer): Integer;
      
      procedure Improve(Neighbour: TLazDockConfigNode);
      var
        NeighbourPos: LongInt;
        NeighbourSize: TPoint;
        NeighbourLength: LongInt;
      begin
        if Neighbour=nil then exit;
        NeighbourPos:=GetMinPos(Neighbour,Side);
        NeighbourSize:=GetMinSize(Neighbour);
        if Side=akLeft then
          NeighbourLength:=NeighbourSize.X
        else
          NeighbourLength:=NeighbourSize.Y;
        MinPos:=Max(MinPos,NeighbourPos+NeighbourLength);
      end;
      
    var
      Sibling: TLazDockConfigNode;
      i: Integer;
    begin
      if MinPosCalculating then begin
        DebugLn(['DebugLayoutAsString.GetMinPos.Compute WARNING: anchor circle detected']);
        exit(1);
      end;
      if (not MinPosValid) then begin
        MinPosValid:=true;
        MinPosCalculating:=true;
        if Node.Sides[Side]<>'' then begin
          Sibling:=FindByName(Node.Sides[Side],true,true);
          Improve(Sibling);
        end;
        if Node.Parent<>nil then begin
          for i:=0 to Node.Parent.ChildCount-1 do begin
            Sibling:=Node.Parent.Childs[i];
            if CompareText(Sibling.Sides[OppositeAnchor[Side]],Node.Name)=0 then
              Improve(Sibling);
          end;
        end;
        MinPosCalculating:=false;
      end;
      Result:=MinPos;
    end;
  
  var
    Info: PNodeInfo;
  begin
    Info:=GetNodeInfo(Node);
    if Side=akLeft then
      Result:=Compute(Info^.MinLeftValid,Info^.MinLeftCalculating,Info^.MinLeft)
    else
      Result:=Compute(Info^.MinTopValid,Info^.MinTopCalculating,Info^.MinTop);
  end;

  function GetChildsMinSize(Node: TLazDockConfigNode): TPoint;
  // calculate the minimum size needed to draw the content of the node
  var
    i: Integer;
    ChildMinSize: TPoint;
    Child: TLazDockConfigNode;
    ChildSize: TPoint;
  begin
    Result:=Point(0,0);
    if Node.TheType=ldcntPages then begin
      // maximum size of all pages
      for i:=0 to Node.ChildCount-1 do begin
        ChildMinSize:=GetMinSize(Node.Childs[i]);
        Result.X:=Max(Result.X,ChildMinSize.X);
        Result.Y:=Max(Result.Y,ChildMinSize.Y);
      end;
    end else begin
      for i:=0 to Node.ChildCount-1 do begin
        Child:=Node.Childs[i];
        ChildSize:=GetMinSize(Child);
        Result.X:=Max(Result.X,GetMinPos(Child,akLeft)+ChildSize.X);
        Result.Y:=Max(Result.Y,GetMinPos(Child,akTop)+ChildSize.Y);
      end;
    end;
  end;
  
  function GetMinSize(Node: TLazDockConfigNode): TPoint;
  // calculate the minimum size needed to draw the node
  var
    ChildMinSize: TPoint;
    Info: PNodeInfo;
  begin
    Info:=GetNodeInfo(Node);
    if Info^.MinSizeValid then begin
      Result:=Info^.MinSize;
      exit;
    end;
    if Info^.MinSizeCalculating then begin
      DebugLn(['DebugLayoutAsString.GetMinSize WARNING: anchor circle detected']);
      Result:=Point(1,1);
      exit;
    end;
    Info^.MinSizeCalculating:=true;
    Result.X:=2+length(Node.Name);// border plus caption
    Result.Y:=2;  // border
    if (Node.ChildCount=0) then begin
      case Node.TheType of
      ldcntSplitterLeftRight,ldcntSplitterUpDown:
        Result:=Point(1,1); // splitters don't need captions
      end;
    end else begin
      ChildMinSize:=GetChildsMinSize(Node);
      Result.X:=Max(Result.X,ChildMinSize.X+2);
      Result.Y:=Max(Result.Y,ChildMinSize.Y+2);
    end;
    Info^.MinSizeCalculating:=false;
    Info^.MinSize:=Result;
    Info^.MinSizeValid:=true;
  end;

  procedure DrawNode(Node: TLazDockConfigNode; ARect: TRect);
  var
    i: Integer;
    Child: TLazDockConfigNode;
    ChildSize: TPoint;
    ChildPos: TPoint;
    ChildRect: TRect;
  begin
    wrectangle(ARect);
    w(ARect.Left+1,ARect.Top,Node.Name,ARect.Right);
    
    for i := 0 to Node.ChildCount-1 do begin
      Child:=Node.Childs[i];
      ChildSize:=GetMinSize(Child);
      ChildPos:=Point(GetMinPos(Child,akLeft),GetMinPos(Child,akTop));
      ChildRect.Left:=ARect.Left+1+ChildPos.X;
      ChildRect.Top:=ARect.Top+1+ChildPos.Y;
      ChildRect.Right:=ChildRect.Left+ChildSize.X-1;
      ChildRect.Bottom:=ChildRect.Top+ChildSize.Y-1;
      DrawNode(Child,ChildRect);
      if Node.TheType=ldcntPages then begin
        // paint only one page
        break;
      end;
    end;
  end;

var
  e: string;
  y: Integer;
begin
  Cols:=StrToIntDef(Application.GetOptionValue('ldcn-colunms'),79);
  Rows:=StrToIntDef(Application.GetOptionValue('ldcn-rows'),20);

  InitNodeInfos;
  try
    e:=LineEnding;
    LogCols:=Cols+length(e);
    SetLength(Result,LogCols*Rows);
    // fill space
    FillChar(Result[1],length(Result),' ');
    // add line endings
    for y:=1 to Rows do
      w(Cols+1,y,e);
    // draw node
    DrawNode(Self,Rect(1,1,Cols,Rows));
  finally
    FreeNodeInfos;
  end;
end;

function TLazDockConfigNode.GetPath: string;
var
  Node: TLazDockConfigNode;
begin
  Result:='';
  Node:=Self;
  while Node<>nil do begin
    if Result<>'' then
      Result:=Node.Name+'/'+Result
    else
      Result:=Node.Name;
    Node:=Node.Parent;
  end;
end;

{ TLazDockerConfig }

constructor TLazDockerConfig.Create(const ADockerName: string;
  ANode: TLazDockConfigNode);
begin
  FDockerName:=ADockerName;
  FRoot:=ANode;
end;

procedure TLazDockerConfig.WriteDebugReport;
begin
  DebugLn(['TLazDockerConfig.WriteDebugReport DockerName="',DockerName,'"']);
  if Root<>nil then begin
    Root.WriteDebugReport;
  end else begin
    DebugLn(['  Root=nil']);
  end;
end;

end.
