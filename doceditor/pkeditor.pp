{
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

  Author: Michael Van Canneyt
}
unit PkEditor;

{$mode objfpc}{$H+}

interface

uses SysUtils, Classes, dom, xmlwrite, Forms, Controls, extctrls, comctrls,
     stdctrls, Dialogs, menus, fpdeutil, lazdemsg, lazdeopts;

Type
  { TPackageEditor }
  TCustomPackageEditor = Class(TPanel)
  Private
    FModified : Boolean;
    FDescriptionNode : TDomNode;
    FCurrentPackage,
    FCurrentElement,
    FCurrentModule,
    FCurrentTopic : TDomElement;
    FOnSelectElement,
    FOnSelectPackage,
    FOnSelectTopic,
    FOnSelectModule : TElementEvent;
  protected
    Procedure SetCurrentModule(Value : TDomElement); virtual;
    Procedure SetCurrentPackage(Value : TDomElement); virtual;
    Procedure SetCurrentElement(E : TDomElement); virtual;
    Procedure SetCurrentTopic(T : TDomElement); virtual;
    Procedure SetDescriptionNode (Value : TDomNode); virtual;
  Public
    Procedure Refresh; virtual; abstract;
    Procedure AddElement(E : TDomElement);  virtual; abstract;
    Procedure DeletePackage(P : TDomElement); virtual; abstract;
    Procedure DeleteModule(M : TDomElement); virtual; abstract;
    Procedure DeleteElement(E : TDomElement); virtual; abstract;
    Procedure DeleteTopic(T : TDomElement); virtual; abstract;
    Procedure RenamePackage(P : TDomElement); virtual; abstract;
    Procedure RenameModule(M : TDomElement); virtual; abstract;
    Procedure RenameElement(E : TDomElement); virtual; abstract;
    Procedure RenameTopic(T : TDomElement); virtual; abstract;
    Property DescriptionNode : TDomNode Read FDescriptionNode Write SetDescriptionNode;
    Property OnSelectModule  : TElementEvent Read FOnSelectModule Write FOnSelectmodule;
    Property OnSelectTopic   : TElementEvent Read FOnSelectTopic Write FOnSelectTopic;
    Property OnSelectPackage : TElementEvent Read FOnSelectPackage Write FOnSelectPackage;
    Property OnSelectElement : TElementEvent Read FOnSelectElement Write FOnSelectElement;
    Property CurrentPackage  : TDomElement Read FCurrentPackage Write SetCurrentPackage;
    Property CurrentModule   : TDomElement Read FCurrentModule Write SetCurrentModule;
    Property CurrentTopic    : TDomElement Read FCurrentTopic Write SetCurrentTopic;
    Property CurrentElement  : TDomElement Read FCurrentElement  Write SetCurrentElement;
    Property Modified        : Boolean Read FModified Write FModified;
  end;

  TPackageEditor = Class(TCustomPackageEditor)
  Private
    FLModules,
    FLElements : TLabel;
    FPElements : TPanel;
    FModuleTree : TTreeView;
    FElementTree : TTreeView;
    FModuleNode : TTreeNode;
    FSplitter : TSplitter;
    PEMenu,
    PMMenu : TPopupMenu;
    FMRenameMenu,
    FMDeleteMenu,
    FERenameMenu,
    FEDeleteMenu : TMenuItem;
    // Callbacks for visual controls.
    Procedure ModuleChange(Sender: TObject; Node: TTreeNode);
    Procedure ModuleChanging(Sender: TObject; Node: TTreeNode;
                             Var AllowChange : Boolean);
    Procedure ElementChange(Sender: TObject; Node: TTreeNode);
    Procedure ElementChanging(Sender: TObject; Node: TTreeNode;
                              Var AllowChange : Boolean);
    // Till the above two get fixed, this one is used instead:
    Procedure TreeClick(Sender: TObject);
    Procedure MenuRenameClick(Sender : TObject);
    Procedure MenuDeleteClick(Sender : TObject);
    // Internal node methods.
    Procedure DeleteNode(Msg : String; N : TTreeNode; E : TDomElement);
    Procedure DeleteElementNode(N : TTreeNode);
    Procedure RenameNode(Msg : String; N : TTreeNode);
    Function  GetSelectedNode : TTreeNode;
    Function  NewName(ATitle : String;Var AName : String) : Boolean;
    Function  AddDomNode(E : TDomElement;Nodes: TTreeNodes;
                         AParent : TTreeNode) : TTreeNode;
    Procedure DoTopicNode(Node : TDomElement;Nodes: TTreeNodes;
                          AParent : TTreeNode);
    Procedure ClearElements;
    Procedure SetModuleNode(N : TTreeNode);
    Function  CreateElementNode(E : TDomelement) : TTreeNode;
    // Correspondence TreeNode<->TDomElement
    Function  FindPackageNode(P : TDomElement) : TTreeNode;
    Function  FindModuleNodeInNode(M : TDomElement; N : TTreeNode) : TTreeNode;
    Function  FindTopicNodeInNode(M : TDomElement; N : TTreeNode) : TTreeNode;
    Function  FindElementNode(E : TDomElement; N : TTreeNode) : TTreeNode;
    // Element node methods.
    Procedure SelectTopic(Sender : TDomElement);
    Procedure SelectModule(Sender : TDomElement);
    Procedure SelectPackage(Sender : TDomElement);
    Procedure SelectElement(Sender : TDomElement);
    Procedure ShowModuleElements(Module : TDomElement);
    Procedure SetCurrentElementNode(N : TTreeNode);
    Procedure SetCurrentModuleNode(N : TTreeNode);
    Procedure SetCurrentPackageNode(N : TTreeNode);
    Procedure SetCurrentTopicNode(T : TTreeNode);
  Protected
    Procedure SetCurrentModule(Value : TDomElement); override;
    Procedure SetCurrentPackage(Value : TDomElement); override;
    Procedure SetCurrentElement(E : TDomElement); override;
    Procedure SetCurrentTopic(T : TDomElement); override;
    Procedure SetDescriptionNode (Value : TDomNode); override;
  Public
    Constructor Create(AOwner : TComponent);override;
    Procedure Refresh; override;
    Procedure AddElement(E : TDomElement); override;
    Procedure DeletePackage(P : TDomElement); override;
    Procedure DeleteModule(M : TDomElement); override;
    Procedure DeleteElement(E : TDomElement); override;
    Procedure DeleteTopic(T : TDomElement); override;
    Procedure RenamePackage(P : TDomElement); override;
    Procedure RenameModule(M : TDomElement); override;
    Procedure RenameElement(E : TDomElement); override;
    Procedure RenameTopic(T : TDomElement); override;
    Property ModuleTree : TTreeView Read FModuleTree;
    Property ElementTree : TTreeView Read FElementTree;
  end;


implementation

uses frmNewNode;

{ ---------------------------------------------------------------------
  Auxiliary routines
  ---------------------------------------------------------------------}

Function GetNextNode(N : TTreeNode) : TTreeNode;

begin
  Result:=N.GetNextSibling;
  If (Result=Nil) and (N.Parent<>Nil) then
    begin
    Result:=N.Parent.Items[0]; // Count is always >=0, N !!
    While (Result<>Nil) and (Result.GetNextSibling<>N) do
      Result:=Result.GetNextSibling;
    If (Result=Nil) then
      Result:=N.Parent;
    end;
end;

Function SubNodeWithElement(P : TTreeNode; E : TDomElement) : TTreeNode;

Var
  N : TTreeNode;

begin
 Result:=Nil;
 If (E<>Nil) and (P<>Nil) and (P.Count>0) then
   begin
   N:=P.Items[0];
   While (Result=Nil) and (N<>Nil) do
     If (N.Data=Pointer(E)) then
       Result:=N
     else
       N:=N.GetNextSibling;
   end;
end;

{ ---------------------------------------------------------------------
  TCustomPackageEditor
  ---------------------------------------------------------------------}

procedure TCustomPackageEditor.SetCurrentModule(Value: TDomElement);
begin
  CurrentPackage:=Value.ParentNode as TDomElement;
  FCurrentModule:=Value;
end;

procedure TCustomPackageEditor.SetCurrentPackage(Value: TDomElement);
begin
  FCurrentPackage:=Value;
end;

procedure TCustomPackageEditor.SetCurrentElement(E: TDomElement);
begin
  FCurrentElement:=E;
end;

procedure TCustomPackageEditor.SetCurrentTopic(T: TDomElement);

Var
  N  : TDomElement;

begin
  If (FCurrentTopic<>T) then
    begin
    N:=T.ParentNode as TDomElement;
    if IsModuleNode(N) then
      CurrentModule:=N
    else if IsPackageNode(N) then
      begin
      CurrentModule:=Nil;
      CurrentPackage:=N;
      end
    else
      Raise Exception.Create('Unknown parent node for topic node '+TDomElement(T)['name']);
    FCurrentTopic:=T;
    end;
end;

procedure TCustomPackageEditor.SetDescriptionNode(Value: TDomNode);
begin
  FDescriptionNode:=Value;
end;


{ ---------------------------------------------------------------------
  TPackageEditor
  ---------------------------------------------------------------------}

Constructor TPackageEditor.Create(AOwner : TComponent);

  Function NewMenuItem(ACaption : String; AOnClick : TNotifyEvent) : TMenuItem;

  begin
    Result:=TMenuItem.Create(Self);
    Result.Caption:=ACaption;
    Result.OnClick:=AOnClick;
  end;

begin
  Inherited;
  FLModules:=Tlabel.Create(Self);
  With FLModules do
    begin
    Parent:=Self;
    Align:=alTop;
    Height:=20;
    Caption:=SFileStructure;
    end;
  FModuleTree:=TTreeView.Create(Self);
  With FModuleTree do
    begin
    Parent:=Self;
    Align:=AlTop;
    Height:=150;
    OnChange:=@ModuleChange;
    OnChanging:=@ModuleChanging;
    // Till the above two get fixed, use this
    OnClick:=@TreeClick;
    end;
  FSplitter:=TSplitter.Create(Self);
  With FSplitter do
    begin
    Parent:=Self;
    align:=alTop;
    end;
  FPElements:=TPanel.Create(Self);
  With FPElements do
    begin
    Parent:=Self;
    align:=AlClient;
    end;
  FLElements:=Tlabel.Create(Self);
  With FLElements do
    begin
    Parent:=FpElements;
    Align:=alTop;
    Height:=20;
    Caption:=SModuleElements;
    end;
  FElementTree:=TTreeView.Create(Self);
  With FElementTree do
    begin
    Parent:=FpElements;
    Align:=AlClient;
    OnChange:=@ElementChange;
    OnChanging:=@ElementChanging;
    // Till the above two get fixed, use this:
    OnClick:=@TreeClick;
    end;
  PEMenu:=TPopupMenu.Create(Self);
  FERenameMenu:=NewMenuItem(SMenuRename,@MenuRenameClick);
  FEDeleteMenu:=NewMenuItem(SMenuDelete,@MenuDeleteClick);
  PEMenu.Items.Add(FERenameMenu);
  PEMenu.Items.Add(FEDeleteMenu);
  FElementTree.PopupMenu:=PEMenu;
  PMMenu:=TPopupMenu.Create(Self);
  FMRenameMenu:=NewMenuItem(SMenuRename,@MenuRenameClick);
  FMDeleteMenu:=NewMenuItem(SMenuDelete,@MenuDeleteClick);
  PMMenu.Items.Add(FMRenameMenu);
  PMMenu.Items.Add(FMDeleteMenu);
  FModuleTree.PopupMenu:=PMMenu;
end;

Procedure TPackageEditor.SetDescriptionNode (Value : TDomNode);

begin
  Inherited;
  Refresh;
end;


procedure TPackageEditor.ModuleChanging(Sender: TObject; Node: TTreeNode;
  var AllowChange: Boolean);
begin
  if Sender=nil then ;
  if Node=nil then ;
  AllowChange:=True;
end;

Procedure TPackageEditor.ModuleChange(Sender: TObject; Node: TTreeNode);

Var
  o : TDomElement;

begin
  if Sender=nil then ;
  If (Node<>Nil) then
    begin
    O:=TDomElement(Node.Data);
    If (O<>Nil) then
      If IsPackageNode(O) then
        SelectPackage(O)
      else if IsModuleNode(O) then
        SelectModule(O)
      else if IsTopicNode(O) then
        SelectTopic(O)
    end;
end;

procedure TPackageEditor.ElementChanging(Sender: TObject; Node: TTreeNode;
  var AllowChange: Boolean);
begin
  if Sender=nil then ;
  if Node=nil then ;
  AllowChange:=True;
end;

// This one must disappear as soon as OnChange/OnChanging work !!
procedure TPackageEditor.TreeClick(Sender: TObject);
begin
  If Sender=FModuleTree then
    ModuleChange(Sender,FModuleTree.Selected)
  else
    ElementChange(Sender,FElementTree.Selected);
end;

Procedure TPackageEditor.SelectElement(Sender : TDomElement);

begin
  If IsElementNode(Sender) then
    CurrentElement:=Sender
  else // FModuleNode selected.
    CurrentElement:=Nil;
  If Assigned(FOnSelectElement) then
    OnSelectElement(Sender);
end;

Procedure TPackageEditor.ElementChange(Sender: TObject; Node: TTreeNode);

Var
  o : TDomElement;

begin
  if Sender=nil then ;
  if Node=nil then ;
  If (Node<>Nil) then
    begin
    O:=TDomElement(Node.Data);
    SelectElement(O)
    end;
end;


Procedure TPackageEditor.SelectModule(Sender : TDomElement);
begin
  Inherited CurrentElement:=Nil;
  Inherited CurrentTopic:=Nil;
  Inherited CurrentModule:=Sender;
  Inherited CurrentPackage:=FCurrentModule.ParentNode as TDomElement;
  ShowModuleElements(FCurrentModule);
  If Assigned(FOnSelectModule) then
    FOnSelectModule(Sender);
end;

Procedure TPackageEditor.SelectPackage(Sender : TDomElement);

begin
  Inherited CurrentElement:=Nil;
  Inherited CurrentModule:=Nil;
  Inherited CurrentTopic:=Nil;
  Inherited CurrentPackage:=Sender;
  ShowModuleElements(Nil);
  If Assigned(FOnSelectPackage) then
   FOnSelectPackage(Sender);
end;

Procedure TPackageEditor.SelectTopic(Sender : TDomElement);

Var
  P : TDomElement;

begin
  Inherited CurrentTopic:=Sender;
  P:=FCurrentTopic.ParentNode as TDomElement;
  if IsModuleNode(P) then
    Inherited CurrentModule:=P
  else if IsTopicNode(P) then
    Inherited CurrentPackage:=P.ParentNode as TDomElement
  else if IsPackageNode(P) then
   Inherited CurrentPackage:=p
  else
    Raise Exception.CreateFmt(SErrUnknownDomElement,[P.NodeName]);
  If Assigned(FOnSelectTopic) then
    FOnSelectTopic(Sender);
end;

Function  TPackageEditor.GetSelectedNode : TTreeNode;

begin
  Result:=FModuleTree.Selected;
end;

Procedure TPackageEditor.MenuRenameClick(Sender : TObject);

Var
  E : TDomElement;

begin
  if Sender=nil then ;
  E:=TDomElement(FModuleTree.Selected.Data);
  If Assigned(E) then
    If IsPackageNode(E)then
      RenamePackage(E)
    else if IsModuleNode(E) then
      RenameModule(E)
    Else if IsTopicNode(E) then
      RenameTopic(E)
    else if IsElementNode(E) then
      RenameElement(E)
end;


Procedure TPackageEditor.MenuDeleteClick(Sender : TObject);

Var
  E : TDomElement;

begin
  If (Sender=FEDeleteMenu) then
    begin
    E:=TDomElement(FElementTree.Selected.Data);
    If IsElementNode(E) then
      DeleteElement(E);
    end
  else
    begin
    E:=TDomElement(FModuleTree.Selected.Data);
    If IsPackageNode(E) then
      DeleteNode(SDeletePackage,FModuleTree.Selected,E)
    else if IsModuleNode(E) then
      DeleteNode(SDeleteModule,FModuleTree.Selected,E)
    else if IsTopicNode(E) then
      DeleteNode(SDeleteTopic,FModuleTree.Selected,E)
    end;
end;


Procedure TPackageEditor.SetModuleNode(N : TTreeNode);

begin
  If N<>Nil then
    begin
    FModuleTree.Selected:=N;
    ModuleChange(FModuleTree,N);
    end
  else
    Refresh;
end;

Procedure TPackageEditor.DeleteNode(Msg : String; N : TTreeNode; E : TDomElement);

Var
  P : TTreeNode;

begin
  If (Not ConfirmDelete) or
     (MessageDlg(Format(Msg,[E['name']]),mtConfirmation,[mbYes,mbNo],0)=mrYes) then
    begin
    P:=GetNextNode(N);
    FModuleTree.Items.Delete(N);
    FModified:=True;
    SetModuleNode(P);
    end;
end;

Function TPackageEditor.NewName(ATitle : String;Var AName : String) : Boolean;
begin
  Result:=false;
  With TNewNodeForm.Create(Self) do
    Try
      Caption:=ATitle;
      ENodeName.Text:=AName;
      If (ShowModal=mrOK) Then begin
        AName:=ENodeName.Text;
        Result:=AName<>'';
      end;
    Finally
      Free;
    end;
end;

Procedure TPackageEditor.RenameNode(Msg : String; N : TTreeNode);

Var
  E : TDomElement;
  S : String;

begin
  E:=TDomElement(N.Data);
  S:=E['name'];
  If NewName(Msg,S) then
    begin
    E['name']:=S;
    N.Text:=S;
    FModified:=True;
    end;
end;

Function TPackageEditor.CreateElementNode(E : TDomelement) : TTreeNode;

begin
  Result:=FELementTree.Items.AddChild(FModuleNode,E['name']);
  Result.Data:=E;
end;

Procedure TPackageEditor.DeleteElementNode(N : TTreeNode);

Var
  Reposition : Boolean;
  P : TTreeNode;

begin
  Reposition:=(TDomElement(N.Data)=CurrentElement) and (CurrentElement<>Nil) ;
  P:=GetNextNode(N);
  FElementTree.Items.Delete(N);
  FModified:=True;
  If Reposition then
    begin
    FElementTree.Selected:=P;
    ElementChange(FElementTree,P);
    end;
end;

Procedure TPackageEditor.DeleteElement(E : TDomElement);

Var
  N : TTreeNode;

begin
  N:=FindElementNode(E,Nil);
  If (N<>Nil) then
    DeleteElementNode(N);
end;

Procedure TPackageEditor.DeletePackage(P : TDomElement);

Var
  N : TTreeNode;

begin
  N:=FindPackageNode(P);
  If N<>NIl then
    DeleteNode(SDeletePackage,N,P);
end;


Procedure TPackageEditor.DeleteModule(M : TDomElement);

Var
  N : TTreeNode;

begin
  N:=FindModuleNodeInNode(M,Nil);
  If N<>NIl then
    DeleteNode(SDeleteModule,N,M);
end;


Procedure TPackageEditor.DeleteTopic(T : TDomElement);

Var
  N : TTreeNode;

begin
  N:=FindTopicNodeInNode(T,Nil);
  If N<>NIl then
    DeleteNode(SDeleteTopic,N,T);
end;


Procedure TPackageEditor.RenamePackage(P : TDomElement);

Var
  N : TTreeNode;

begin
  N:=FindPackageNode(P);
  If N<>NIl then
    RenameNode(SRenamePackage,N);
end;


Procedure TPackageEditor.RenameModule(M : TDomElement);

Var
  N : TTreeNode;

begin
  N:=FindModuleNodeInNode(M,Nil);
  If N<>NIl then
    RenameNode(SRenameModule,N);
end;


Procedure TPackageEditor.RenameTopic(T : TDomElement);

Var
  N : TTreeNode;

begin
  N:=FindTopicNodeInNode(T,Nil);
  If N<>NIl then
    RenameNode(SRenameTopic,N);
end;


Procedure TPackageEditor.RenameElement(E : TDomElement);

Var
  N : TTreeNode;

begin
  N:=FindElementNode(E,Nil);
  If N<>NIl then
    RenameNode(SRenameElement,N);
end;

Procedure TPackageEditor.ClearElements;

begin
  FElementTree.Items.Clear;
  FModuleNode:=Nil;
end;

Procedure TPackageEditor.ShowModuleElements(Module : TDomElement);

Var
  Node : TDomNode;
  SNode,PNode,TNode : TTreeNode;
  S : TStringList;
  I,L : Integer;
  N,PN : String;

begin
  ClearElements;
  If Assigned(Module) then
    begin
    FModuleNode:=FElementTree.Items.Add(Nil,Module['name']);
    S:=TStringList.Create;
    Try
      Node:=Module.FirstChild;
      While Assigned(Node) do
        begin
        If IsElementNode(Node) then
          S.AddObject(TDomElement(Node)['name'],Node);
        Node:=Node.NextSibling;
        end;
      S.Sorted:=True;
      TNode:=FModuleNode;
      For I:=0 to S.Count-1 do
        begin
        PNode:=Nil;
        SNode:=TNode;
        N:=S[i];
        While (SNode<>FModuleNode) and (PNode=Nil) do
          begin
          PN:=TDomElement(SNode.Data)['name']+'.';
          L:=Length(PN);
          If CompareText(Copy(N,1,L),PN)=0 then
            PNode:=SNode;
          SNode:=SNode.Parent;
          end;
        If (PNode=Nil) then
          PNode:=FModuleNode
        else
          System.Delete(N,1,L);
        TNode:=FElementTree.Items.AddChild(PNode,N);
        TNode.Data:=S.Objects[i];
        end;
      Finally
        S.Free;
      end;
    FModuleNode.Expand(False);
    FElementTree.Selected:=FModuleNode;
    ElementChange(FElementTree,FModuleNode);
    end;
end;

Function TPackageEditor.AddDomNode(E : TDomElement;Nodes: TTreeNodes;AParent : TTreeNode) : TTreeNode;

begin
  Result:=Nodes.AddChild(AParent,E['name']);
  Result.Data:=E;
end;

Procedure TPackageEditor.DoTopicNode(Node : TDomElement;Nodes: TTreeNodes;AParent : TTreeNode);

Var
  N : TTreeNode;
  SubNode : TDomNode;

begin
  N:=Nodes.AddChild(AParent,Node['name']);
  N.Data:=Node;
  SubNode:=Node.FirstChild;
  While (SubNode<>Nil) do
    begin
    If IsTopicNode(SubNode) then
      DoTopicNode(SubNode as TDomElement,Nodes,N);
    SubNode:=SubNode.NextSibling;
    end;
end;


Procedure TPackageEditor.Refresh;

var
  Node,SubNode,SSnode : TDomNode;
  R,P,M : TTreeNode;

begin
  FModuleTree.Items.Clear;
  R:=FModuleTree.Items.add(Nil,SPackages);
  If Assigned(FDescriptionNode) then
    begin
    Node:=FDescriptionNode.FirstChild;
    While Assigned(Node) do
      begin
      If IsPackageNode(Node) then
        begin
        P:=AddDomNode(Node as TDomElement,FModuleTree.Items,R);
        SubNode:=Node.FirstChild;
        While Assigned(SubNode) do
          begin
          If IsModuleNode(SubNode) then
            begin
            M:=AddDomNode(SubNode as TDomElement,FModuleTree.Items,P);
            SSNode:=SubNode.FirstChild;
            While (SSNode<>Nil) do
              begin
              if IsTopicNode(SSNode) then
                DoTopicNode(SSNode as TDomElement,FModuleTree.Items,M);
              SSNode:=SSNode.NextSibling;
              end;
            end
          else if IsTopicNode(SubNode) then
            DoTopicNode(SubNode as TDomElement,FModuleTree.Items,P);
          SubNode:=SubNode.NextSibling;
          end;
        end;
      Node:=Node.NextSibling;
      end;
    end;
  CurrentModule:=Nil;
  FModified:=False;
end;


Function TPackageEditor.FindPackageNode(P : TDomElement) : TTreeNode;
begin
  Result:=Nil;
  Result:=SubNodeWithElement(FModuleTree.Items[0],P);
  If (Result=Nil) then
    Raise Exception.CreateFmt(SErrNoNodeForPackage,[P['name']]);
end;

Function TPackageEditor.FindModuleNodeInNode(M : TDomElement; N : TTreeNode) : TTreeNode;

Var
  P : TTreeNode;

begin
  Result:=Nil;
  If (N<>Nil) then
    P:=N
  else
    P:=FindPackageNode(M.ParentNode as TDomElement);
  Result:=SubNodeWithElement(P,M);
  If (Result=Nil) then
    Raise Exception.CreateFmt(SErrNoNodeForModule,[M['name']]);
end;

Function TPackageEditor.FindTopicNodeInNode(M : TDomElement; N : TTreeNode) : TTreeNode;

Var
  P : TTreeNode;
  E : TDomElement;

begin
  Result:=Nil;
  If (N<>Nil) then
    P:=N
  else
    begin
    E:=M.ParentNode as TDomElement;
    If IsModuleNode(E) then
      P:=FindModuleNodeInNode(E,FindPackageNode(E.ParentNode as TDomElement))
    else if IsTopicNode(E) then
      // Assumes that we can only nest 2 deep inside package node !!
      P:=FindTopicNodeInNode(E,FindPackageNode(E.ParentNode as TDomElement))
    else if IsPackageNode(E) then
      P:=FindPackageNode(E);
    end;
  Result:=SubNodeWithElement(P,M);
  If (Result=Nil) then
    Raise Exception.CreateFmt(SErrNoNodeForTopic,[M['name']]);
end;

Function TPackageEditor.FindElementNode(E : TDomElement; N : TTreeNode) : TTreeNode;

Var
  P : TTreeNode;

begin
  If IsModuleNode(E) then
    Result:=FModuleNode
  else
    begin
    Result:=Nil;
    If (N<>Nil) then
      P:=N
    else
      P:=FModuleNode;
    Result:=SubNodeWithElement(P,E);
    end;
  If (Result=Nil) then
    Raise Exception.CreateFmt(SErrNoNodeForElement,[E['name']]);
end;

Procedure TPackageEditor.AddElement(E : TDomElement);

Var
  N : TTreeNode;

begin
  N:=CreateElementNode(E);
  SetCurrentElementNode(N);
  FModified:=True;
end;


Procedure TPackageEditor.SetCurrentPackage(Value : TDomElement);

begin
  if (Value<>CurrentPackage) then
    begin
    Inherited;
    If (Value<>Nil) then
      SetCurrentPackageNode(FindPackageNode(Value));
    end;
end;

Procedure TPackageEditor.SetCurrentPackageNode(N : TTreeNode);

begin
  FModuleTree.Selected:=N;
end;

Procedure TPackageEditor.SetCurrentModule(Value : TDomElement);
begin
  If (Value<>CurrentModule) then
    begin
    Inherited;
    If Assigned(Value) then
      SetCurrentModuleNode(FindModuleNodeInNode(Value,Nil))
    else
      ClearElements;
    end;
end;

Procedure TPackageEditor.SetCurrentModuleNode(N : TTreeNode);

Var
  P : TTreeNode;

begin
  P:=FindPackageNode(CurrentPackage);
  If Assigned(P) then
    P.Expand(False);
  FModuleTree.Selected:=N;
end;

Procedure TPackageEditor.SetCurrentTopic(T : TDomElement);

Var
  N  : TDomElement;
  PN : TTreeNode;
  
begin
  If (CurrentTopic<>T) then
    begin
    N:=T.ParentNode as TDomElement;
    if IsModuleNode(N) then
      begin
      CurrentModule:=N;
      PN:=FindModuleNodeInNode(N,Nil);
      end
    else if IsPackageNode(N) then
      begin
      CurrentModule:=Nil;
      CurrentPackage:=N;
      PN:=FindPackageNode(n);
      end;
    SetCurrentTopicNode(FindTopicNodeInNode(T,PN));
    end;
  Inherited;
end;

Procedure TPackageEditor.SetCurrentTopicNode(T : TTreeNode);

begin
 T.Parent.Expand(False);
 FModuleTree.Selected:=T;
 If (CurrentElement<>Nil) then
   CurrentElement:=Nil;
end;

Procedure TPackageEditor.SetCurrentElement(E : TDomElement);

begin
  If (E<>FCurrentElement) then
    begin
    Inherited;
    CurrentModule:=E.ParentNode as TDomElement;
    SetCurrentElementNode(FindElementNode(E,Nil));
    end;
end;

Procedure TPackageEditor.SetCurrentElementNode(N : TTreeNode);

begin
  FElementTree.Selected:=N;
end;

end.

