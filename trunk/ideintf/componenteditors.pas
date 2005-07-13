{
 *****************************************************************************
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
    This units defines the component editors used by the designer.
    A Component Editor is a plugin used by the designer to add special
    functions for component classes.
    For more information see the big comment part below.
}
unit ComponentEditors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, LCLProc, Forms, Controls, Menus, ExtCtrls,
  Graphics, Grids, CheckLst, Buttons, ComCtrls, Dialogs, GraphType,
  PropEdits, ObjInspStrConsts;

type
  { TComponentEditorDesigner }
  
  TComponentPasteSelectionFlag = (
    cpsfReplace,
    cpsfFindUniquePositions
    );
  TComponentPasteSelectionFlags = set of TComponentPasteSelectionFlag;


  TComponentEditorDesigner = class(TIDesigner)
  protected
    FForm: TCustomForm;
    function GetPropertyEditorHook: TPropertyEditorHook; virtual; abstract;
  public
    function CopySelection: boolean; virtual; abstract;
    function CutSelection: boolean; virtual; abstract;
    function CanPaste: boolean; virtual; abstract;
    function PasteSelection(Flags: TComponentPasteSelectionFlags): boolean; virtual; abstract;
    function DeleteSelection: boolean; virtual; abstract;
    function CopySelectionToStream(s: TStream): boolean; virtual; abstract;
    function InsertFromStream(s: TStream; Parent: TWinControl;
                              Flags: TComponentPasteSelectionFlags
                              ): Boolean; virtual; abstract;
    function InvokeComponentEditor(AComponent: TComponent;
                                   MenuIndex: integer): boolean; virtual; abstract;

    procedure DrawDesignerItems(OnlyIfNeeded: boolean); virtual; abstract;
    function CreateUniqueComponentName(const AClassName: string
                                       ): string; virtual; abstract;
    property PropertyEditorHook: TPropertyEditorHook read GetPropertyEditorHook;
    property Form: TCustomForm read FForm;
  end;


{ Component Editor Types }

type

{ TComponentEditor
  A component editor is created for each component that is selected in the
  form designer based on the component's type (see GetComponentEditor and
  RegisterComponentEditor). When the component is double-clicked the Edit
  method is called. When the context menu for the component is invoked the
  GetVerbCount and GetVerb methods are called to build the menu. If one
  of the verbs are selected, ExecuteVerb is called. Paste is called whenever
  the component is pasted to the clipboard. You only need to create a
  component editor if you wish to add verbs to the context menu, change
  the default double-click behavior, or paste an additional clipboard format.
  The default component editor (TDefaultEditor) implements Edit to searches the
  properties of the component and generates (or navigates to) the OnCreate,
  OnChanged, or OnClick event (whichever it finds first). Whenever the
  component editor modifies the component, it *must* call Designer.Modified to
  inform the designer that the form has been modified. (Or else the user can not
  save the changes).

    Edit
      Called when the user double-clicks the component. The component editor can
      bring up a dialog in response to this method, for example, or some kind
      of design expert. If GetVerbCount is greater than zero, edit will execute
      the first verb in the list (ExecuteVerb(0)).

    ExecuteVerb(Index)
      The Index'ed verb was selected by the use off the context menu. The
      meaning of this is determined by component editor.

    GetVerb
      The component editor should return a string that will be displayed in the
      context menu. It is the responsibility of the component editor to place
      the & character and the '...' characters as appropriate.

    GetVerbCount
      The number of valid indices to GetVerb and Execute verb. The index is
      assumed to be zero based (i.e. 0..GetVerbCount - 1).

    PrepareItem
      While constructing the context menu PrepareItem will be called for
      each verb. It will be passed the menu item that will be used to represent
      the verb. The component editor can customize the menu item as it sees fit,
      including adding subitems. If you don't want that particular menu item
      to be shown, don't free it, simply set its Visible property to False.

    Copy
      Called when the component is being copied to the clipboard. The
      component's filed image is already on the clipboard. This gives the
      component editor a chance to paste a different type of format which is
      ignored by the designer but might be recognized by another application.

    IsInInlined
      Determines whether Component is in the Designer which owns it.
      Essentially, Components should not be able to be added to a Frame
      instance (collections are fine though) so this function checks to
      determine whether the currently selected component is within a Frame
      instance or not.

    GetComponent
      Returns the edited component.

    GetDesigner
      Returns the current Designer for the form owning the component.
    }

{ TComponentEditor
  All component editors are assumed derived from TBaseComponentEditor.

    Create(AComponent, ADesigner)
      Called to create the component editor. AComponent is the component to
      be edited by the editor. ADesigner is an interface to the designer to
      find controls and create methods (this is not used often). If a component
      editor modifies the component in any way it *must* call
      ADesigner.Modified. }

  TBaseComponentEditor = class
  protected
  public
    constructor Create(AComponent: TComponent;
      ADesigner: TComponentEditorDesigner); virtual;
    procedure Edit; virtual; abstract;
    procedure ExecuteVerb(Index: Integer); virtual; abstract;
    function GetVerb(Index: Integer): string; virtual; abstract;
    function GetVerbCount: Integer; virtual; abstract;
    procedure PrepareItem(Index: Integer; const AnItem: TMenuItem); virtual; abstract;
    procedure Copy; virtual; abstract;
    function IsInInlined: Boolean; virtual; abstract;
    function GetComponent: TComponent; virtual; abstract;
    function GetDesigner: TComponentEditorDesigner; virtual; abstract;
    function GetHook(var Hook: TPropertyEditorHook): boolean; virtual; abstract;
    procedure Modified; virtual; abstract;
  end;

  TComponentEditorClass = class of TBaseComponentEditor;


{ TComponentEditor
  This class provides a default implementation for the IComponentEditor
  interface. There is no assumption by the designer that you use this class
  only that your class derive from TBaseComponentEditor and implement
  IComponentEditor. This class is provided to help you implement a class
  that meets those requirements. }
  TComponentEditor = class(TBaseComponentEditor)
  private
    FComponent: TComponent;
    FDesigner: TComponentEditorDesigner;
  public
    constructor Create(AComponent: TComponent;
      ADesigner: TComponentEditorDesigner); override;
    procedure Edit; override;
    procedure ExecuteVerb(Index: Integer); override;
    function GetComponent: TComponent; override;
    function GetDesigner: TComponentEditorDesigner; override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
    function IsInInlined: Boolean; override;
    procedure Copy; override;
    procedure PrepareItem(Index: Integer; const AnItem: TMenuItem); override;
    property Component: TComponent read FComponent;
    property Designer: TComponentEditorDesigner read GetDesigner;
    function GetHook(var Hook: TPropertyEditorHook): boolean; override;
    procedure Modified; override;
  end;


{ TDefaultComponentEditor
  An editor that provides default behavior for the double-click that will
  iterate through the properties looking for the most appropriate method
  property to edit }
  TDefaultComponentEditor = class(TComponentEditor)
  private
    FBestEditEvent: string;
    FFirst: TPropertyEditor;
    FBest: TPropertyEditor;
    FContinue: Boolean;
    FPropEditCandidates: TList; // list of TPropertyEditor
    procedure CheckEdit(Prop: TPropertyEditor);
  protected
    procedure EditProperty(const Prop: TPropertyEditor;
      var Continue: Boolean); virtual;
    procedure ClearPropEditorCandidates;
  public
    constructor Create(AComponent: TComponent;
      ADesigner: TComponentEditorDesigner); override;
    destructor Destroy; override;
    procedure Edit; override;
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
    property BestEditEvent: string read FBestEditEvent write FBestEditEvent;
  end;
  
  
{ TNotebookComponentEditor
  The default component editor for TCustomNotebook. }
  TNotebookComponentEditor = class(TDefaultComponentEditor)
  protected
    procedure AddNewPageToDesigner(Index: integer); virtual;
    procedure DoAddPage; virtual;
    procedure DoInsertPage; virtual;
    procedure DoDeletePage; virtual;
    procedure DoMoveActivePageLeft; virtual;
    procedure DoMoveActivePageRight; virtual;
    procedure DoMoveActivePage(CurIndex, NewIndex: Integer); virtual;
    procedure AddMenuItemsForPages(ParentMenuItem: TMenuItem); virtual;
    procedure ShowPageMenuItemClick(Sender: TObject);
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
    procedure PrepareItem(Index: Integer; const AnItem: TMenuItem); override;
    function Notebook: TCustomNotebook; virtual;
  end;
  
  
{ TPageComponentEditor
  The default component editor for TCustomPage. }
  TPageComponentEditor = class(TNotebookComponentEditor)
  protected
  public
    function Notebook: TCustomNotebook; override;
    function Page: TCustomPage; virtual;
  end;


{ TStringGridComponentEditor
  The default componenteditor for TStringGrid }

  TStringGridComponentEditor = class(TDefaultComponentEditor)
  protected
    procedure DoShowEditor;
    procedure AssignGrid(dstGrid, srcGrid: TStringGrid; Full: boolean);
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

{ TCheckListBoxComponentEditor
  The default componenteditor for TCheckListBox }

  TCheckListBoxComponentEditor = class(TDefaultComponentEditor)
  protected
    procedure DoShowEditor;
    procedure AssignCheck(dstCheck, srcCheck: TCheckListBox);
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;


{ TCheckGroupComponentEditor
  The default componenteditor for TCheckGroup }

  TCheckGroupComponentEditor = class(TDefaultComponentEditor)
  protected
    procedure DoShowEditor;
    procedure AssignCheck(dstCheck, srcCheck: TCheckGroup);
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;


{ TToolBarComponentEditor
  The default componenteditor for TToolBar }

  TToolBarComponentEditor = class(TDefaultComponentEditor)
  protected
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
    function ToolBar: TToolBar; virtual;
  end;


{ TFileDialogComponentEditor
  The default componenteditor for TFileDialog }

  TFileDialogComponentEditor = class(TComponentEditor)
  private
    procedure TestDialog;
  public
    function GetVerbCount:integer;override;
    function GetVerb(Index:integer):string;override;
    procedure ExecuteVerb(Index:integer);override;
    procedure Edit;override;
  end;
  

{ Register a component editor }
type
  TRegisterComponentEditorProc =
    procedure (ComponentClass: TComponentClass;
               ComponentEditor: TComponentEditorClass);

var
  RegisterComponentEditorProc: TRegisterComponentEditorProc;


procedure RegisterComponentEditor(ComponentClass: TComponentClass;
  ComponentEditor: TComponentEditorClass);
function GetComponentEditor(Component: TComponent;
  const Designer: TComponentEditorDesigner): TBaseComponentEditor;

type
  TPropertyEditorFilterFunc =
    function(const ATestEditor: TPropertyEditor): Boolean of object;


implementation


{ RegisterComponentEditor }
type
  PComponentClassRec = ^TComponentClassRec;
  TComponentClassRec = record
    Group: Integer;
    ComponentClass: TComponentClass;
    EditorClass: TComponentEditorClass;
  end;

const
  ComponentClassList: TList = nil;

procedure DefaultRegisterComponentEditorProc(ComponentClass: TComponentClass;
  ComponentEditor: TComponentEditorClass);
var
  P: PComponentClassRec;
begin
  if ComponentClassList = nil then
    ComponentClassList := TList.Create;
  New(P);
  P^.Group := -1;//CurrentGroup;
  P^.ComponentClass := ComponentClass;
  P^.EditorClass := ComponentEditor;
  ComponentClassList.Insert(0, P);
end;

procedure RegisterComponentEditor(ComponentClass: TComponentClass;
  ComponentEditor: TComponentEditorClass);
begin
  if Assigned(RegisterComponentEditorProc) then
    RegisterComponentEditorProc(ComponentClass, ComponentEditor);
end;

function GetComponentEditor(Component: TComponent;
  const Designer: TComponentEditorDesigner): TBaseComponentEditor;
var
  P: PComponentClassRec;
  I: Integer;
  ComponentClass: TComponentClass;
  EditorClass: TComponentEditorClass;
begin
  ComponentClass := TComponentClass(TPersistent);
  EditorClass := TDefaultComponentEditor;
  if ComponentClassList <> nil then
    for I := 0 to ComponentClassList.Count-1 do
    begin
      P := PComponentClassRec(ComponentClassList[I]);
      if (Component is P^.ComponentClass) and
        (P^.ComponentClass <> ComponentClass) and
        (P^.ComponentClass.InheritsFrom(ComponentClass)) then
      begin
        EditorClass := P^.EditorClass;
        ComponentClass := P^.ComponentClass;
      end;
    end;
  Result := EditorClass.Create(Component, Designer);
end;

{ Component Editors -----------------------------------------------------------}


{ TBaseComponentEditor }

constructor TBaseComponentEditor.Create(AComponent: TComponent;
  ADesigner: TComponentEditorDesigner);
begin
  inherited Create;
end;

{ TComponentEditor }

constructor TComponentEditor.Create(AComponent: TComponent;
  ADesigner: TComponentEditorDesigner);
begin
  inherited Create(AComponent, ADesigner);
  FComponent := AComponent;
  FDesigner := ADesigner;
end;

procedure TComponentEditor.Edit;
begin
  if GetVerbCount > 0 then ExecuteVerb(0);
end;

function TComponentEditor.GetComponent: TComponent;
begin
  Result := FComponent;
end;

function TComponentEditor.GetDesigner: TComponentEditorDesigner;
begin
  Result := FDesigner;
end;

function TComponentEditor.GetVerbCount: Integer;
begin
  // Intended for descendents to implement
  Result := 0;
end;

function TComponentEditor.GetVerb(Index: Integer): string;
begin
  // Intended for descendents to implement
  Result:=ClassName+IntToStr(Index);
end;

procedure TComponentEditor.ExecuteVerb(Index: Integer);
begin
  // Intended for descendents to implement
  DebugLn(Classname+'.ExecuteVerb: ',IntToStr(Index));
end;

procedure TComponentEditor.Copy;
begin
  // Intended for descendents to implement
end;

function TComponentEditor.IsInInlined: Boolean;
begin
  Result := csInline in Component.Owner.ComponentState;
end;

procedure TComponentEditor.PrepareItem(Index: Integer;
  const AnItem: TMenuItem);
begin
  // Intended for descendents to implement
end;

function TComponentEditor.GetHook(var Hook: TPropertyEditorHook): boolean;
begin
  Result:=false;
  if GetDesigner=nil then exit;
  Hook:=GetDesigner.PropertyEditorHook;
  Result:=Hook<>nil;
end;

procedure TComponentEditor.Modified;
begin
  GetDesigner.Modified;
end;

{ TDefaultComponentEditor }

procedure TDefaultComponentEditor.CheckEdit(Prop: TPropertyEditor);
begin
  if FContinue then
    EditProperty(Prop, FContinue);
  if FPropEditCandidates=nil then
    FPropEditCandidates:=TList.Create;
  FPropEditCandidates.Add(Prop);
end;

procedure TDefaultComponentEditor.EditProperty(const Prop: TPropertyEditor;
  var Continue: Boolean);
var
  PropName: string;
  BestName: string;

  procedure ReplaceBest;
  begin
    FBest := Prop;
    if FFirst = FBest then FFirst := nil;
  end;

begin
  if not Assigned(FFirst) and (Prop is TMethodPropertyEditor) then
    FFirst := Prop;
  PropName := Prop.GetName;
  BestName := '';
  if Assigned(FBest) then BestName := FBest.GetName;
  if CompareText(PropName, FBestEditEvent) = 0 then
    ReplaceBest
  else if CompareText(BestName, FBestEditEvent) <> 0 then
    if CompareText(PropName, 'ONCHANGE') = 0 then
      ReplaceBest
    else if CompareText(BestName, 'ONCHANGE') <> 0 then
      if CompareText(PropName, 'ONCLICK') = 0 then
        ReplaceBest;
end;

procedure TDefaultComponentEditor.ClearPropEditorCandidates;
var
  i: Integer;
begin
  if FPropEditCandidates=nil then exit;
  for i:=0 to FPropEditCandidates.Count-1 do
    TObject(FPropEditCandidates[i]).Free;
  FPropEditCandidates.Free;
  FPropEditCandidates:=nil;
end;

constructor TDefaultComponentEditor.Create(AComponent: TComponent;
  ADesigner: TComponentEditorDesigner);
begin
  inherited Create(AComponent, ADesigner);
  FBestEditEvent:='OnCreate';
end;

destructor TDefaultComponentEditor.Destroy;
begin
  ClearPropEditorCandidates;
  inherited Destroy;
end;

procedure TDefaultComponentEditor.Edit;
var
  PropertyEditorHook: TPropertyEditorHook;
  NewLookupRoot: TPersistent;
begin
  PropertyEditorHook:=nil;
  if not GetHook(PropertyEditorHook) then exit;
  NewLookupRoot:=GetLookupRootForComponent(Component);
  if not (NewLookupRoot is TComponent) then exit;
  if NewLookupRoot<>PropertyEditorHook.LookupRoot then
    GetDesigner.SelectOnlyThisComponent(Component);
  FContinue := True;
  FFirst := nil;
  FBest := nil;
  try
    GetPersistentProperties(Component,tkAny,PropertyEditorHook,@CheckEdit,nil);
    if FContinue
    then begin
      if Assigned(FBest) then
        FBest.Edit
      else if Assigned(FFirst) then
        FFirst.Edit;
    end;
  finally
    FFirst := nil;
    FBest := nil;
    ClearPropEditorCandidates;
  end;
end;

function TDefaultComponentEditor.GetVerbCount: Integer;
begin
  Result:=1;
end;

function TDefaultComponentEditor.GetVerb(Index: Integer): string;
begin
  Result:=oisCreateDefaultEvent;
end;

procedure TDefaultComponentEditor.ExecuteVerb(Index: Integer);
begin
  Edit;
end;


{ TNotebookComponentEditor }

const
  nbvAddPage       = 0;
  nbvInsertPage    = 1;
  nbvDeletePage    = 2;
  nbvMovePageLeft  = 3;
  nbvMovePageRight = 4;
  nbvShowPage      = 5;

procedure TNotebookComponentEditor.ShowPageMenuItemClick(Sender: TObject);
var
  AMenuItem: TMenuItem;
  NewPageIndex: integer;
begin
  AMenuItem:=TMenuItem(Sender);
  if (AMenuItem=nil) or (not (AMenuItem is TMenuItem)) then exit;
  NewPageIndex:=AMenuItem.MenuIndex;
  if (NewPageIndex<0) or (NewPageIndex>=Notebook.PageCount) then exit;
  NoteBook.PageIndex:=NewPageIndex;
  GetDesigner.SelectOnlyThisComponent(NoteBook.CustomPage(NoteBook.PageIndex));
end;

procedure TNotebookComponentEditor.AddNewPageToDesigner(Index: integer);
var
  Hook: TPropertyEditorHook;
  NewPage: TCustomPage;
  NewName: string;
begin
  Hook:=nil;
  if not GetHook(Hook) then exit;
  NewPage:=NoteBook.CustomPage(Index);
  NewName:=GetDesigner.CreateUniqueComponentName(NewPage.ClassName);
  NewPage.Caption:=NewName;
  NewPage.Name:=NewName;
  NoteBook.PageIndex:=Index;
  Hook.PersistentAdded(NewPage,true);
  Modified;
end;

procedure TNotebookComponentEditor.DoAddPage;
var
  Hook: TPropertyEditorHook;
begin
  if not GetHook(Hook) then exit;
  NoteBook.Pages.Add('');
  AddNewPageToDesigner(NoteBook.PageCount-1);
end;

procedure TNotebookComponentEditor.DoInsertPage;
var
  Hook: TPropertyEditorHook;
  NewIndex: integer;
begin
  if not GetHook(Hook) then exit;
  NewIndex:=Notebook.PageIndex;
  if NewIndex<0 then NewIndex:=0;
  Notebook.Pages.Insert(NewIndex,'');
  AddNewPageToDesigner(NewIndex);
end;

procedure TNotebookComponentEditor.DoDeletePage;
var
  Hook: TPropertyEditorHook;
  OldIndex: integer;
  PageComponent: TComponent;
begin
  OldIndex:=Notebook.PageIndex;
  if (OldIndex>=0) and (OldIndex<Notebook.PageCount) then begin
    if not GetHook(Hook) then exit;
    PageComponent:=TComponent(NoteBook.Pages.Objects[OldIndex]);
    Hook.DeletePersistent(PageComponent);
  end;
end;

procedure TNotebookComponentEditor.DoMoveActivePageLeft;
var
  Index: integer;
begin
  Index:=NoteBook.PageIndex;
  if (Index<0) then exit;
  DoMoveActivePage(Index,Index-1);
end;

procedure TNotebookComponentEditor.DoMoveActivePageRight;
var
  Index: integer;
begin
  Index:=NoteBook.PageIndex;
  if (Index>=0)
  and (Index>=NoteBook.PageCount-1) then exit;
  DoMoveActivePage(Index,Index+1);
end;

procedure TNotebookComponentEditor.DoMoveActivePage(
  CurIndex, NewIndex: Integer);
begin
  NoteBook.Pages.Move(CurIndex,NewIndex);
  Modified;
end;

procedure TNotebookComponentEditor.AddMenuItemsForPages(
  ParentMenuItem: TMenuItem);
var
  i: integer;
  NewMenuItem: TMenuItem;
begin
  ParentMenuItem.Enabled:=NoteBook.PageCount>0;
  for i:=0 to NoteBook.PageCount-1 do begin
    NewMenuItem:=TMenuItem.Create(ParentMenuItem);
    NewMenuItem.Name:='ShowPage'+IntToStr(i);
    NewMenuItem.Caption:=Notebook.CustomPage(i).Name+' "'+Notebook.Pages[i]+'"';
    NewMenuItem.OnClick:=@ShowPageMenuItemClick;
    ParentMenuItem.Add(NewMenuItem);
  end;
end;

procedure TNotebookComponentEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    nbvAddPage:       DoAddPage;
    nbvInsertPage:    DoInsertPage;
    nbvDeletePage:    DoDeletePage; // beware: this can free the editor itself
    nbvMovePageLeft:  DoMoveActivePageLeft;
    nbvMovePageRight: DoMoveActivePageRight;
  end;
end;

function TNotebookComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    nbvAddPage:       Result:=nbcesAddPage;
    nbvInsertPage:    Result:=nbcesInsertPage;
    nbvDeletePage:    Result:=nbcesDeletePage;
    nbvMovePageLeft:  Result:=nbcesMovePageLeft;
    nbvMovePageRight: Result:=nbcesMovePageRight;
    nbvShowPage:      Result:=nbcesShowPage;
  else
    Result:='';
  end;
end;

function TNotebookComponentEditor.GetVerbCount: Integer;
begin
  Result:=6;
end;

procedure TNotebookComponentEditor.PrepareItem(Index: Integer;
  const AnItem: TMenuItem);
begin
  inherited PrepareItem(Index, AnItem);
  case Index of
    nbvAddPage:       ;
    nbvInsertPage:    AnItem.Enabled:=Notebook.PageIndex>=0;
    nbvDeletePage:    AnItem.Enabled:=Notebook.PageIndex>=0;
    nbvMovePageLeft:  AnItem.Enabled:=Notebook.PageIndex>0;
    nbvMovePageRight: AnItem.Enabled:=Notebook.PageIndex<Notebook.PageCount-1;
    nbvShowPage:      AddMenuItemsForPages(AnItem);
  end;
end;

function TNotebookComponentEditor.Notebook: TCustomNotebook;
begin
  Result:=TCustomNotebook(GetComponent);
end;

{ TPageComponentEditor }

function TPageComponentEditor.Notebook: TCustomNotebook;
var
  APage: TCustomPage;
begin
  APage:=Page;
  if (APage.Parent<>nil) and (APage.Parent is TCustomNoteBook) then
    Result:=TCustomNoteBook(APage.Parent);
end;

function TPageComponentEditor.Page: TCustomPage;
begin
  Result:=TCustomPage(GetComponent);
end;

{ TStringGridEditorDlg }

Type
  TStringGridEditorDlg=Class(TForm)
  private
    FGrid: TStringGrid;
    FFixedColor: TColor;
    FFixedRows,FFixedCols: Integer;
    //procedure OnFixedRows(Sender: TObject);
    //procedure OnFixedCols(Sender: TObject);
    procedure OnPrepareCanvas(Sender: TObject; Col,Row:Integer; aState: TGridDrawState);
  public
    constructor create(AOwner: TComponent); override;
    property Grid: TStringGrid read FGrid write FGrid;
    property FixedColor: TColor read FFixedColor write FFixedColor;
    property FixedRows: Integer read FFixedRows write FFixedRows;
    property FixedCols: Integer read FFixedCols write FFixedCols;
  end;
{
procedure TStringGridEditorDlg.OnFixedRows(Sender: TObject);
begin
  FGrid.FixedRows := FGrid.FixedRows + 1 - 2 * (Sender as TComponent).Tag;
end;

procedure TStringGridEditorDlg.OnFixedCols(Sender: TObject);
begin
  FGrid.FixedCols := FGrid.FixedCols + 1 - 2 * (Sender as TComponent).Tag;
end;
}
procedure TStringGridEditorDlg.OnPrepareCanvas(Sender: TObject;
  Col,Row: Integer; aState: TGridDrawState);
begin
  if (Col<FFixedCols) or (Row<FFixedRows) then
    FGrid.Canvas.Brush.Color := FFixedColor
end;

constructor TStringGridEditorDlg.create(AOwner: TComponent);
begin
  inherited create(AOwner);
  BorderStyle:=bsDialog;
  SetBounds(0,0,350,320);
  Position :=poScreenCenter;
  Caption  :=cesStringGridEditor2;

  FGrid:=TStringGrid.Create(Self);
  FGrid.Parent:=Self;
  FGrid.SetBounds(5,5,Width-15, 250);
  FGrid.FixedCols:=0;
  FGrid.FixedRows:=0;
  FGrid.Options:=Fgrid.Options + [goEditing,goColSizing,goRowSizing];
  FGrid.OnPrepareCanvas := @OnPrepareCanvas;
  FGrid.ExtendedColSizing := True;
  {
  With TButton.Create(Self) do begin
    parent:=self;
    SetBounds(5, FGrid.Top + Fgrid.Height + 10, 80, 18);
    Tag:=0;
    Caption:='+ FixedRows';
    OnClick:=@OnFixedRows;
  end;
  With TButton.Create(Self) do begin
    parent:=self;
    SetBounds(5, FGrid.Top + Fgrid.Height + 30, 80, 18);
    Tag:=1;
    Caption:='- FixedRows';
    OnClick:=@OnFixedRows;
  end;
  With TButton.Create(Self) do begin
    parent:=self;
    SetBounds(90, FGrid.Top + Fgrid.Height + 10, 80, 18);
    Tag:=0;
    Caption:='+ FixedCols';
    OnClick:=@OnFixedCols;
  end;
  With TButton.Create(Self) do begin
    parent:=self;
    Left:=90;
    SetBounds(90, FGrid.Top + Fgrid.Height + 30, 80, 18);
    Tag:=1;
    Caption:='- FixedCols';
    OnClick:=@OnFixedCols;
  end;
  }
  //Bnt Ok
  With TBitBtn.Create(self) do
  begin
    Left  := 240;
    Top   := FGrid.Top + Fgrid.Height + 5;
    Width := 99;
    Kind  := bkOk;
    Parent:= self;
  end;

  //Bnt Cancel
  With TBitBtn.Create(self) do
  begin
    Left  := 240;
    Top   := FGrid.Top + Fgrid.Height + height + 5;
    Width := 99;
    Kind  := bkCancel;
    Parent:= self;
  end;

  // Save/load buttons
end;

{ TStringGridComponentEditor }

procedure TStringGridComponentEditor.DoShowEditor;
var Dlg : TStringGridEditorDlg;
    Hook: TPropertyEditorHook;
    aGrid: TStringGrid;
begin
  Dlg:=TStringGridEditorDlg.Create(nil);
  try
    if GetComponent is TStringGrid then begin
      aGrid:=TStringGrid(GetComponent);
      GetHook(Hook);

      Dlg.FixedRows :=  AGrid.FixedRows;
      Dlg.FixedCols :=  AGrid.FixedCols;
      Dlg.FixedColor := AGrid.FixedColor;
      
      AssignGrid(Dlg.FGrid, aGrid, true);
      
      //ShowEditor
      if Dlg.ShowModal=mrOK then
      begin
        //Apply the modifications
        AssignGrid(aGrid, Dlg.FGrid, false);
        //not work :o( aImg.AddImages(Dlg.fGrid);
        Modified;
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TStringGridComponentEditor.AssignGrid(dstGrid, srcGrid: TStringGrid;
 Full: boolean);
var
  i,j: integer;
begin
  DstGrid.BeginUpdate;
  try
    if Full then begin
      DstGrid.Clear;
      Dstgrid.ColCount:=srcGrid.ColCount;
      DstGrid.RowCount:=srcGrid.RowCount;
      //DstGrid.FixedRows:=srcGrid.FixedRows;
      //Dstgrid.FixedCols:=srcGrid.FixedCols;
    end;
    for i:=0 to srcGrid.RowCount-1 do
      DstGrid.RowHeights[i]:=srcGrid.RowHeights[i];
    for i:=0 to srcGrid.ColCount-1 do
      DstGrid.ColWidths[i]:=srcGrid.ColWidths[i];
    for i:=0 to srcGrid.ColCount-1 do
      for j:=0 to srcGrid.RowCount-1 do
        if srcGrid.Cells[i,j]<>dstGrid.Cells[i,j] then
          dstGrid.Cells[i,j]:=srcGrid.Cells[i,j];
  finally
    Dstgrid.EndUpdate(uoFull);
  end;
end;

procedure TStringGridComponentEditor.ExecuteVerb(Index: Integer);
begin
  doShowEditor;
end;

function TStringGridComponentEditor.GetVerb(Index: Integer): string;
begin
  Result:=cesStringGridEditor;
end;

function TStringGridComponentEditor.GetVerbCount: Integer;
begin
  Result:=1;
end;

{ TCheckListBoxEditorDlg }

Type
  TCheckListBoxEditorDlg=Class(TForm)
  private
    FCheck: TCheckListBox;
    FBtnAdd,FBtnDelete,FBtnUp,FBtnDown,FBtnModify:TButton;
    FBtnOK,FBtnCancel:TBitBtn;
    FPanelButtons:TPanel;
    FPanelOKCancel:TPanel;
  protected
    procedure AddItem(Sender:TObject);
    procedure DeleteItem(Sender:TObject);
    procedure MoveUpItem(Sender:TObject);
    procedure MoveDownItem(Sender:TObject);
    procedure ModifyItem(Sender:TObject);
  public
    constructor create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Check: TCheckListBox read FCheck write FCheck;
  end;

constructor TCheckListBoxEditorDlg.create(AOwner: TComponent);
begin
  inherited create(AOwner);
  BorderStyle:=bsDialog;
  Position:=poScreenCenter;
  Caption:=clbCheckListBoxEditor;
  SetBounds(0,0,200,300);

  FPanelButtons:=TPanel.Create(Self);
  with FPanelButtons do begin
    Parent:=Self;
    Align:=alTop;
    BevelInner:=bvLowered;
    BevelOuter:=bvSpace;
    AutoSize:=true;
  end;

  //Button Add
  FBtnAdd:=TButton.Create(self);
  with FBtnAdd do begin
    Caption:=oiscAdd;
    Parent:=FPanelButtons;
    OnClick:=@AddItem;
    AutoSize:=true;
    Top:=0;
  end;

  //Button Delete
  FBtnDelete:=TButton.Create(self);
  with FBtnDelete do begin
    Caption:=oiscDelete;
    Parent:=FPanelButtons;
    OnClick:=@DeleteItem;
    AutoSize:=true;
    AnchorToCompanion(akLeft,0,FBtnAdd);
  end;

  //Button Up
  FBtnUp:=TButton.Create(self);
  with FBtnUp do begin
    Caption:=clbUp;
    Parent:=FPanelButtons;
    OnClick:=@MoveUpItem;
    AutoSize:=true;
    AnchorToCompanion(akLeft,0,FBtnDelete);
  end;

  //Button Down
  FBtnDown:=TButton.Create(self);
  with FBtnDown do begin
    Caption:=clbDown;
    Parent:=FPanelButtons;
    OnClick:=@MoveDownItem;
    AutoSize:=true;
    AnchorToCompanion(akLeft,0,FBtnUp);
  end;

  //Button Modify
  FBtnModify:=TButton.Create(self);
  with FBtnModify do begin
    Caption:='...';
    Parent:=FPanelButtons;
    ShowHint:=true;
    Hint:=clbModify;
    OnClick:=@ModifyItem;
    AutoSize:=true;
    AnchorToCompanion(akLeft,0,FBtnDown);
  end;

  FCheck:=TCheckListBox.Create(Self);
  with FCheck do begin
    Parent:=Self;
    Align:=alClient;
  end;

  FPanelOKCancel:=TPanel.Create(Self);
  with FPanelOKCancel do begin
    Parent:=Self;
    Align:=alBottom;
    BevelInner:=bvLowered;
    BevelOuter:=bvSpace;
    AutoSize:=true;
  end;

  //Btn Ok
  FBtnOK:=TBitBtn.Create(self);
  with FBtnOK do begin
    Parent:=FPanelOKCancel;
    Kind:=bkOk;
    AutoSize:=true;
  end;

  //Btn Cancel
  FBtnCancel:=TBitBtn.Create(self);
  with FBtnCancel do begin
    Parent:=FPanelOKCancel;
    Kind:=bkCancel;
    AutoSize:=true;
    AnchorToCompanion(akLeft,0,FBtnOK);
  end;
end;

destructor TCheckListBoxEditorDlg.Destroy;
begin
  FreeThenNil(FCheck);
  FreeThenNil(FBtnAdd);
  FreeThenNil(FBtnDelete);
  FreeThenNil(FBtnUp);
  FreeThenNil(FBtnDown);
  FreeThenNil(FBtnModify);
  FreeThenNil(FBtnOK);
  FreeThenNil(FBtnCancel);
  FreeThenNil(FPanelOKCancel);
  FreeThenNil(FPanelButtons);
  inherited Destroy
end;

procedure TCheckListBoxEditorDlg.AddItem(Sender:TObject);
var strItem:string;
begin
  if InputQuery(clbCheckListBoxEditor, clbAdd, strItem) then
    FCheck.Items.Add(strItem);
end;

procedure TCheckListBoxEditorDlg.DeleteItem(Sender:TObject);
begin
  if FCheck.ItemIndex=-1 then exit;
  if MessageDlg(clbCheckListBoxEditor,Format(clbDelete,[FCheck.ItemIndex,FCheck.Items[FCheck.ItemIndex]]),
    mtConfirmation, mbYesNo, 0)=mrYes then
    FCheck.Items.Delete(FCheck.ItemIndex);
end;

procedure TCheckListBoxEditorDlg.MoveUpItem(Sender:TObject);
var itemtmp:string;
    checkedtmp:boolean;
begin
  if (FCheck.Items.Count<=1)or(FCheck.ItemIndex<1) then exit;
  itemtmp:=FCheck.Items[FCheck.ItemIndex-1];
  checkedtmp:=FCheck.Checked[FCheck.ItemIndex-1];
  FCheck.Items[FCheck.ItemIndex-1]:=FCheck.Items[FCheck.ItemIndex];
  FCheck.Checked[FCheck.ItemIndex-1]:=FCheck.Checked[FCheck.ItemIndex];
  FCheck.Items[FCheck.ItemIndex]:=itemtmp;
  FCheck.Checked[FCheck.ItemIndex]:=checkedtmp;
  FCheck.ItemIndex:=FCheck.ItemIndex-1
end;

procedure TCheckListBoxEditorDlg.MoveDownItem(Sender:TObject);
var itemtmp:string;
    checkedtmp:boolean;
begin
  if (FCheck.Items.Count<=1)or(FCheck.ItemIndex=FCheck.Items.Count-1)or(FCheck.ItemIndex=-1) then exit;
  itemtmp:=FCheck.Items[FCheck.ItemIndex+1];
  checkedtmp:=FCheck.Checked[FCheck.ItemIndex+1];
  FCheck.Items[FCheck.ItemIndex+1]:=FCheck.Items[FCheck.ItemIndex];
  FCheck.Checked[FCheck.ItemIndex+1]:=FCheck.Checked[FCheck.ItemIndex];
  FCheck.Items[FCheck.ItemIndex]:=itemtmp;
  FCheck.Checked[FCheck.ItemIndex]:=checkedtmp;
  FCheck.ItemIndex:=FCheck.ItemIndex+1
end;

procedure TCheckListBoxEditorDlg.ModifyItem(Sender:TObject);
begin
  if FCheck.ItemIndex=-1 then exit;
  FCheck.Items[FCheck.ItemIndex]:=InputBox(clbCheckListBoxEditor,clbModify,FCheck.Items[FCheck.ItemIndex]);
end;

{ TCheckListBoxComponentEditor }

procedure TCheckListBoxComponentEditor.DoShowEditor;
var Dlg : TCheckListBoxEditorDlg;
    Hook: TPropertyEditorHook;
    aCheck: TCheckListBox;
begin
  Dlg:=TCheckListBoxEditorDlg.Create(nil);
  try
    if GetComponent is TCheckListBox then begin
      aCheck:=TCheckListBox(GetComponent);
      GetHook(Hook);

      AssignCheck(Dlg.FCheck, aCheck);

      //ShowEditor
      if Dlg.ShowModal=mrOK then begin
        //Apply the modifications
        AssignCheck(aCheck, Dlg.FCheck);
        Modified;
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TCheckListBoxComponentEditor.AssignCheck(dstCheck, srcCheck: TCheckListBox);
var i: integer;
begin
  DstCheck.Items.Clear;
  DstCheck.Items:=srcCheck.Items;
  DstCheck.ItemHeight:=srcCheck.ItemHeight;
  for i:=0 to srcCheck.Items.Count-1 do begin
    if srcCheck.Items[i]<>dstCheck.Items[i] then
        dstCheck.Items[i]:=srcCheck.Items[i];
    dstCheck.Checked[i]:=srcCheck.Checked[i]
  end;
end;

procedure TCheckListBoxComponentEditor.ExecuteVerb(Index: Integer);
begin
  doShowEditor;
end;

function TCheckListBoxComponentEditor.GetVerb(Index: Integer): string;
begin
  Result:=clbCheckListBoxEditor+' ...';
end;

function TCheckListBoxComponentEditor.GetVerbCount: Integer;
begin
  Result:=1;
end;

{ TCheckGroupEditorDlg }

Type
  TCheckGroupEditorDlg=Class(TForm)
  private
    FCheck: TCheckGroup;
    FBtnAdd,FBtnDelete,FBtnUp,FBtnDown,FBtnModify:TButton;
    FBtnOK,FBtnCancel:TBitBtn;
    FPanelButtons:TPanel;
    FPanelOKCancel:TPanel;
    FPopupMenu:TPopupMenu;
    ItemIndex:integer;
  protected
    procedure AddItem(Sender:TObject);
    procedure DeleteItem(Sender:TObject);
    procedure MoveUpItem(Sender:TObject);
    procedure MoveDownItem(Sender:TObject);
    procedure ModifyItem(Sender:TObject);
    procedure ItemClick(Sender: TObject; Index: integer);
    procedure EnableDisable(Sender:TObject);
    procedure CreateItems(Sender:TObject);
  public
    constructor create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Check: TCheckGroup read FCheck write FCheck;
  end;

constructor TCheckGroupEditorDlg.Create(AOwner: TComponent);
begin
  inherited create(AOwner);
  BorderStyle:=bsDialog;
  Position:=poScreenCenter;
  Caption:=clbCheckGroupEditor;
  SetBounds(0,0,200,300);
  ItemIndex:=-1;

  FPanelButtons:=TPanel.Create(Self);
  with FPanelButtons do begin
    Parent:=Self;
    Align:=alTop;
    BevelInner:=bvLowered;
    BevelOuter:=bvSpace;
    Height:=25;
  end;

  //Button Add
  FBtnAdd:=TButton.Create(self);
  with FBtnAdd do begin
    Parent:=FPanelButtons;
    Align:=alLeft;
    Width:=43;
    Caption:=oiscAdd;
    OnClick:=@AddItem;
  end;

  //Button Delete
  FBtnDelete:=TButton.Create(self);
  with FBtnDelete do begin
    Parent:=FPanelButtons;
    Align:=alLeft;
    Width:=43;
    Caption:=oiscDelete;
    OnClick:=@DeleteItem;
  end;

  //Button Up
  FBtnUp:=TButton.Create(self);
  with FBtnUp do begin
    Parent:=FPanelButtons;
    Align:=alLeft;
    Width:=43;
    Caption:=clbUp;
    OnClick:=@MoveUpItem;
  end;

  //Button Down
  FBtnDown:=TButton.Create(self);
  with FBtnDown do begin
    Parent:=FPanelButtons;
    Align:=alLeft;
    Width:=43;
    Caption:=clbDown;
    OnClick:=@MoveDownItem;
  end;

  //Button Modify
  FBtnModify:=TButton.Create(self);
  with FBtnModify do begin
    Parent:=FPanelButtons;
    Align:=alClient;
    ShowHint:=true;
    Hint:=clbModify;
    Caption:='...';
    OnClick:=@ModifyItem;
  end;

  FCheck:=TCheckGroup.Create(Self);
  with FCheck do begin
    Parent:=Self;
    Align:=alClient;
    OnItemClick:=@ItemClick;
  end;

  FPanelOKCancel:=TPanel.Create(Self);
  with FPanelOKCancel do begin
    Parent:=Self;
    Align:=alBottom;
    BevelInner:=bvLowered;
    BevelOuter:=bvSpace;
    Height:=25;
  end;

  FPopupMenu:=TPopupMenu.Create(Self);
  FPopupMenu.OnPopup:=@CreateItems;
  FCheck.PopupMenu:=FPopupMenu;

  //Bnt Ok
  FBtnOK:=TBitBtn.Create(self);
  with FBtnOK do begin
    Parent:=FPanelOKCancel;
    Align:=alLeft;
    Kind:=bkOk;
  end;

  //Bnt Cancel
  FBtnCancel:=TBitBtn.Create(self);
  with FBtnCancel do begin
    Parent:=FPanelOKCancel;
    Align:=alRight;
    Kind:=bkCancel;
  end;

end;

destructor TCheckGroupEditorDlg.Destroy;
begin
  FreeThenNil(FCheck);
  FreeThenNil(FBtnAdd);
  FreeThenNil(FBtnDelete);
  FreeThenNil(FBtnUp);
  FreeThenNil(FBtnDown);
  FreeThenNil(FBtnModify);
  FreeThenNil(FBtnOK);
  FreeThenNil(FBtnCancel);
  FreeThenNil(FPanelOKCancel);
  FreeThenNil(FPanelButtons);
  FreeThenNil(FPopupMenu);
  inherited Destroy
end;

procedure TCheckGroupEditorDlg.AddItem(Sender:TObject);
var strItem:string;
begin
  if InputQuery(clbCheckGroupEditor, clbAdd, strItem) then
    FCheck.Items.Add(strItem);
end;

procedure TCheckGroupEditorDlg.DeleteItem(Sender:TObject);
begin
  if ItemIndex=-1 then exit;
  if MessageDlg(clbCheckGroupEditor,Format(clbDelete,[ItemIndex, FCheck.Items[ItemIndex]]),
    mtConfirmation, mbYesNo, 0)=mrYes then begin
    FCheck.Items.Delete(ItemIndex);
    if ItemIndex>FCheck.Items.Count-1 then
      ItemIndex:=FCheck.Items.Count-1;
  end;
end;

procedure TCheckGroupEditorDlg.MoveUpItem(Sender:TObject);
var itemtmp:string;
    checkedtmp:boolean;
begin
  if (FCheck.Items.Count<=1)or(ItemIndex<1) then exit;
   //swap the caption and the checked states
  itemtmp:=FCheck.Items[ItemIndex-1];
  checkedtmp:=FCheck.Checked[ItemIndex-1];
  FCheck.Items[ItemIndex-1]:=FCheck.Items[ItemIndex];
  FCheck.Checked[ItemIndex-1]:=FCheck.Checked[ItemIndex];
  FCheck.Items[ItemIndex]:=itemtmp;
  FCheck.Checked[ItemIndex]:=checkedtmp;
  //swap the states enabled
  checkedtmp:=FCheck.CheckEnabled[ItemIndex-1];
  FCheck.CheckEnabled[ItemIndex-1]:=FCheck.CheckEnabled[ItemIndex];
  FCheck.CheckEnabled[ItemIndex]:=checkedtmp;

  ItemIndex:=ItemIndex-1
end;

procedure TCheckGroupEditorDlg.MoveDownItem(Sender:TObject);
var itemtmp:string;
    checkedtmp:boolean;
begin
  if (FCheck.Items.Count<=1)or(ItemIndex=FCheck.Items.Count-1)or(ItemIndex=-1) then exit;
   //swap the caption and the checked states
  itemtmp:=FCheck.Items[ItemIndex+1];
  checkedtmp:=FCheck.Checked[ItemIndex+1];
  FCheck.Items[ItemIndex+1]:=FCheck.Items[ItemIndex];
  FCheck.Checked[ItemIndex+1]:=FCheck.Checked[ItemIndex];
  FCheck.Items[ItemIndex]:=itemtmp;
  FCheck.Checked[ItemIndex]:=checkedtmp;
  //swap the states enabled
  checkedtmp:=FCheck.CheckEnabled[ItemIndex+1];
  FCheck.CheckEnabled[ItemIndex+1]:=FCheck.CheckEnabled[ItemIndex];
  FCheck.CheckEnabled[ItemIndex]:=checkedtmp;

  ItemIndex:=ItemIndex+1
end;

procedure TCheckGroupEditorDlg.ModifyItem(Sender:TObject);
begin
  if ItemIndex=-1 then exit;
  FCheck.Items[ItemIndex]:=InputBox(clbCheckGroupEditor,clbModify,FCheck.Items[ItemIndex]);
end;

procedure TCheckGroupEditorDlg.ItemClick(Sender: TObject; Index: integer);
begin
  ItemIndex:=Index;
end;

procedure TCheckGroupEditorDlg.EnableDisable(Sender:TObject);
var i:integer;
begin
  for i:=0 to FCheck.Items.Count-1 do begin
    if (Sender=FPopupMenu.Items[i]) then
      FCheck.CheckEnabled[i]:=not FCheck.CheckEnabled[i]
  end;
end;

procedure TCheckGroupEditorDlg.CreateItems(Sender:TObject);
var i:integer;
begin
  FPopupMenu.Items.Clear;
  for i:=0 to FCheck.Items.Count-1 do begin
    FPopupMenu.Items.Add(TMenuItem.Create(self));
    FPopupMenu.Items[i].Caption:=FCheck.Items[i];
    FPopupMenu.Items[i].Checked:=FCheck.CheckEnabled[i];
    FPopupMenu.Items[i].OnClick:=@EnableDisable;
  end;;
end;

procedure TCheckGroupComponentEditor.DoShowEditor;
var Dlg : TCheckGroupEditorDlg;
    Hook: TPropertyEditorHook;
    aCheck: TCheckGroup;
begin
  Dlg:=TCheckGroupEditorDlg.Create(nil);
  try
    if GetComponent is TCheckGroup then begin
      aCheck:=TCheckGroup(GetComponent);
      GetHook(Hook);

      AssignCheck(Dlg.FCheck, aCheck);

      //ShowEditor
      if Dlg.ShowModal=mrOK then begin
        //Apply the modifications
        AssignCheck(aCheck, Dlg.FCheck);
        Modified;
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TCheckGroupComponentEditor.AssignCheck(dstCheck, srcCheck: TCheckGroup);
var i: integer;
begin
  DstCheck.Items.Clear;
  DstCheck.Items:=srcCheck.Items;
  DstCheck.Caption:=srcCheck.Caption;
  for i:=0 to srcCheck.Items.Count-1 do begin
    dstCheck.Checked[i]:=srcCheck.Checked[i];
    dstCheck.CheckEnabled[i]:=srcCheck.CheckEnabled[i]
  end;
end;

procedure TCheckGroupComponentEditor.ExecuteVerb(Index: Integer);
begin
  doShowEditor;
end;

function TCheckGroupComponentEditor.GetVerb(Index: Integer): string;
begin
  Result:=clbCheckGroupEditor+' ...';
end;

function TCheckGroupComponentEditor.GetVerbCount: Integer;
begin
  Result:=1;
end;

{ TToolBarComponentEditor }

procedure TToolBarComponentEditor.ExecuteVerb(Index: Integer);
var
  NewStyle: TToolButtonStyle;
  Hook: TPropertyEditorHook;
  NewToolButton: TToolButton;
  NewName: string;
  CurToolBar: TToolBar;
begin
  Hook:=nil;
  if not GetHook(Hook) then exit;
  case Index of
  0: NewStyle:=tbsButton;
  1: NewStyle:=tbsCheck;
  2: NewStyle:=tbsSeparator;
  else exit;
  end;
  CurToolBar:=ToolBar;
  NewToolButton:=TToolButton.Create(CurToolBar.Owner);
  NewName:=GetDesigner.CreateUniqueComponentName(NewToolButton.ClassName);
  NewToolButton.Caption:=NewName;
  NewToolButton.Name:=NewName;
  NewToolButton.Style:=NewStyle;
  NewToolButton.Parent:=CurToolBar;
  Hook.PersistentAdded(NewToolButton,true);
  Modified;
end;

function TToolBarComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
  0: Result:='New Button';
  1: Result:='New Checkbutton';
  2: Result:='New Separator';
  else Result:='';
  end;
end;

function TToolBarComponentEditor.GetVerbCount: Integer;
begin
  Result:=3;
end;

function TToolBarComponentEditor.ToolBar: TToolBar;
begin
  Result:=TToolBar(GetComponent);
end;

{ TFileDialogComponentEditor }

procedure TFileDialogComponentEditor.TestDialog;
begin
  with Component as TFileDialog do Execute;
end;

function TFileDialogComponentEditor.GetVerbCount: integer;
begin
  Result:=1;
end;

function TFileDialogComponentEditor.GetVerb(Index: integer): string;
begin
  case Index of
    0:Result:='Test dialog...';
  else
    Result:=inherited GetVerb(Index);
  end;
end;

procedure TFileDialogComponentEditor.ExecuteVerb(Index: integer);
begin
  case Index of
    0:TestDialog;
  else
    inherited ExecuteVerb(Index);
  end;
end;

procedure TFileDialogComponentEditor.Edit;
begin
  TestDialog;
end;

//------------------------------------------------------------------------------

procedure InternalFinal;
var
  p: PComponentClassRec;
  i: integer;
begin
  if ComponentClassList<>nil then begin
    for i:=0 to ComponentClassList.Count-1 do begin
      p:=PComponentClassRec(ComponentClassList[i]);
      Dispose(p);
    end;
    ComponentClassList.Free;
  end;
end;

initialization
  RegisterComponentEditorProc:=@DefaultRegisterComponentEditorProc;
  RegisterComponentEditor(TCustomNotebook,TNotebookComponentEditor);
  RegisterComponentEditor(TCustomPage,TPageComponentEditor);
  RegisterComponentEditor(TStringGrid,TStringGridComponentEditor);
  RegisterComponentEditor(TCheckListBox,TCheckListBoxComponentEditor);
  RegisterComponentEditor(TCheckGroup,TCheckGroupComponentEditor);
  RegisterComponentEditor(TToolBar,TToolBarComponentEditor);
  RegisterComponentEditor(TFileDialog, TFileDialogComponentEditor);

finalization
  InternalFinal;

end.

