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
  Classes, SysUtils, TypInfo, LCLProc, Controls, Forms, Menus, LCLStrConsts,
  StringHashList, LDockCtrlEdit, LDockTree;

type
  TNonDockConfigNames = (
    ndcnControlName, // '-Name ' + AControl.Name
    ndcnChildIndex,  // '-ID ' + IntToStr(AControl index in Parent) + AControl.ClassName
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
    ldcntSplitter,
    ldcntPages,
    ldcntPage
    );

  { TLazDockConfigNode }

  TLazDockConfigNode = class(TPersistent)
  private
    FBounds: TRect;
    FName: string;
    FParent: TLazDockConfigNode;
    FSides: array[TAnchorKind] of TLazDockConfigNode;
    FTheType: TLDConfigNodeType;
    FChilds: TFPList;
    function GetChildCount: Integer;
    function GetChilds(Index: integer): TLazDockConfigNode;
    function GetSides(Side: TAnchorKind): TLazDockConfigNode;
    procedure SetBounds(const AValue: TRect);
    procedure SetName(const AValue: string);
    procedure SetParent(const AValue: TLazDockConfigNode);
    procedure SetSides(Side: TAnchorKind; const AValue: TLazDockConfigNode);
    procedure SetTheType(const AValue: TLDConfigNodeType);
    procedure DoAdd(ChildNode: TLazDockConfigNode);
    procedure DoRemove(ChildNode: TLazDockConfigNode);
  public
    constructor Create(ParentNode: TLazDockConfigNode; const AName: string);
    destructor Destroy; override;
    procedure Clear;
    function FindByName(const AName: string): TLazDockConfigNode;
  public
    property TheType: TLDConfigNodeType read FTheType write SetTheType;
    property Name: string read FName write SetName;
    property Bounds: TRect read FBounds write SetBounds;
    property Parent: TLazDockConfigNode read FParent write SetParent;
    property Sides[Side: TAnchorKind]: TLazDockConfigNode read GetSides write SetSides;
    property ChildCount: Integer read GetChildCount;
    property Childs[Index: integer]: TLazDockConfigNode read GetChilds; default;
  end;

  TCustomLazControlDocker = class;

  { TCustomLazDockingManager }

  TCustomLazDockingManager = class(TComponent)
  private
    FDockers: TFPList;
    FManager: TAnchoredDockManager;
    function GetDockerCount: Integer;
    function GetDockers(Index: Integer): TCustomLazControlDocker;
  protected
    procedure Remove(Docker: TCustomLazControlDocker);
    function Add(Docker: TCustomLazControlDocker): Integer;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function FindDockerByName(const ADockerName: string;
                      Ignore: TCustomLazControlDocker): TCustomLazControlDocker;
    function FindDockerByControl(AControl: TControl;
                      Ignore: TCustomLazControlDocker): TCustomLazControlDocker;
    function CreateUniqueName(const AName: string;
                              Ignore: TCustomLazControlDocker): string;
    procedure SaveToStream(Stream: TStream);
    function GetControlConfigName(AControl: TControl): string;
    procedure WriteDebugReport;
  public
    property Manager: TAnchoredDockManager read FManager;
    property DockerCount: Integer read GetDockerCount;
    property Dockers[Index: Integer]: TCustomLazControlDocker read GetDockers; default;
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
    FConfigRootNode: TLazDockConfigNode;// the root node of the config tree
    FConfigSelfNode: TLazDockConfigNode;// the node of 'Control'
    FControl: TControl;
    FDockerName: string;
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
    procedure ShowDockingEditor; virtual;
    procedure ClearConfigNodes;
    procedure GetLayoutFromControl;
    function GetControlName(AControl: TControl): string;
    procedure WriteConfigTreeDebugReport;
    constructor Create(TheOwner: TComponent); override;
    property Control: TControl read FControl write SetControl;
    property Manager: TCustomLazDockingManager read FManager write SetManager;
    property ExtendPopupMenu: boolean read FExtendPopupMenu write SetExtendPopupMenu;
    property PopupMenuItem: TMenuItem read FPopupMenuItem;
    property LocalizedName: string read FLocalizedName write SetLocalizedName;
    property DockerName: string read FDockerName write SetDockerName;
    property ConfigRootNode: TLazDockConfigNode read FConfigRootNode;
    property ConfigSelfNode: TLazDockConfigNode read FConfigSelfNode;
  end;

  { TLazControlDocker }

  TLazControlDocker = class(TCustomLazControlDocker)
  published
    property Control;
    property Manager;
    property ExtendPopupMenu;
    property DockerName;
  end;
  
procedure Register;


implementation

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
  if Control.Visible then begin
    // control will be hidden -> the layout will change
    // save the layout for restore
    GetLayoutFromControl;
  end else begin
    // the control will become visible -> dock it to restore the last layout
    RaiseGDBException('TCustomLazControlDocker.ControlVisibleChanging TODO restore layout');
  end;
end;

procedure TCustomLazControlDocker.ControlVisibleChanged(Sender: TObject);
begin

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
      Result:=NonDockConfigNamePrefixes[ndcnChildIndex]+IntToStr(i)
                   +AControl.ClassName;
    end;
  end;
end;

procedure TCustomLazControlDocker.GetLayoutFromControl;

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
          DebugLn('CopyChildsLayout ',DbgSName(CurAnchorControl),' CurAnchorCtrlName="',CurAnchorCtrlName,'"');
          ChildNode.Sides[a]:=CurAnchorNode;
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
    if AControl=Control then
      FConfigSelfNode:=Result;
      
    // The Type
    if AControl is TLazDockSplitter then
      Result.FTheType:=ldcntSplitter
    else if AControl is TLazDockForm then
      Result.FTheType:=ldcntForm
    else if AControl is TLazDockPages then
      Result.FTheType:=ldcntPages
    else if AControl is TLazDockPage then
      Result.FTheType:=ldcntPage
    else
      Result.FTheType:=ldcntControl;

    // Bounds
    Result.FBounds:=AControl.BoundsRect;
    
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
  ClearConfigNodes;
  if (Control=nil) or (Manager=nil) then exit;
  
  RootControl:=Control;
  while RootControl.Parent<>nil do
    RootControl:=RootControl.Parent;
  FConfigRootNode:=AddNode(nil,RootControl);
end;

procedure TCustomLazControlDocker.ClearConfigNodes;
begin
  FConfigSelfNode:=nil;
  FConfigRootNode.Free;
  FConfigRootNode:=nil;
end;

procedure TCustomLazControlDocker.WriteConfigTreeDebugReport;

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
    DbgOut(' Childs='+dbgs(ANode.ChildCount));
    for a:=Low(TAnchorKind) to High(TAnchorKind) do begin
      if ANode.Sides[a]=nil then continue;
      s:=ANode.Sides[a].Name;
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
  DebugLn('TCustomLazControlDocker.WriteConfigTreeDebugReport '
     ,' Root=',dbgs(ConfigRootNode),' SelfNode=',dbgs(ConfigSelfNode));
  WriteNode('  ',ConfigRootNode);
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
  if FControl=nil then begin
    FControl.AddHandlerOnVisibleChanging(@ControlVisibleChanging);
    FControl.AddHandlerOnVisibleChanged(@ControlVisibleChanged);
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

procedure TCustomLazDockingManager.SaveToStream(Stream: TStream);
begin
  RaiseGDBException('TODO TCustomLazDockingManager.SaveToStream');
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

{ TLazDockConfigNode }

function TLazDockConfigNode.GetSides(Side: TAnchorKind): TLazDockConfigNode;
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
  const AValue: TLazDockConfigNode);
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
  FChilds.Remove(ChildNode);
end;

constructor TLazDockConfigNode.Create(ParentNode: TLazDockConfigNode;
  const AName: string);
begin
  FName:=AName;
  Parent:=ParentNode;
end;

destructor TLazDockConfigNode.Destroy;
begin
  Clear;
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

function TLazDockConfigNode.FindByName(const AName: string
  ): TLazDockConfigNode;
var
  i: Integer;
begin
  if FChilds<>nil then
    for i:=0 to FChilds.Count-1 do begin
      Result:=Childs[i];
      if CompareText(Result.Name,AName)=0 then exit;
    end;
  Result:=nil;
end;

end.

