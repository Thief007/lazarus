{ /***************************************************************************
                 codetoolsoptions.pas  -  Lazarus IDE unit
                 -----------------------------------------

 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

  Author: Mattias Gaertner

  Abstract:
    - TCodeToolsDefinesEditor
}
unit CodeToolsDefines;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLLinux, Forms, Controls, Buttons, StdCtrls, ComCtrls,
  ExtCtrls, Menus, LResources, Graphics, ImgList, SynEdit, DefineTemplates,
  CodeToolManager, CodeToolsOptions;

type
  TCodeToolsDefinesEditor = class(TForm)
    TheImageList: TImageList;
    MainMenu: TMainMenu;
    
    // exit menu
    ExitMenuItem: TMenuItem;
    SaveAndExitMenuItem: TMenuItem;
    DontSaveAndExitMenuItem: TMenuItem;

    // edit nodes
    EditMenuItem: TMenuItem;
    MoveNodeUpMenuItem: TMenuItem;
    MoveNodeDownMenuItem: TMenuItem;
    InsertDefineMenuItem: TMenuItem;
    InsertDefineAllMenuItem: TMenuItem;
    InsertUndefineMenuItem: TMenuItem;
    InsertBlockMenuItem: TMenuItem;
    InsertDirectoryMenuItem: TMenuItem;
    InsertIfMenuItem: TMenuItem;
    InsertIfDefMenuItem: TMenuItem;
    InsertIfNotDefMenuItem: TMenuItem;
    InsertElseMenuItem: TMenuItem;
    DeleteNodeMenuItem: TMenuItem;
    CopyToClipbrdMenuItem: TMenuItem;
    PasteFromClipbrdMenuItem: TMenuItem;

    // tools
    ToolsMenuItem: TMenuItem;
    OpenPreviewMenuItem: TMenuItem;
    ShowMacroListMenuItem: TMenuItem;

    // templates
    InsertTemplateMenuItem: TMenuItem;

    // define tree
    DefineTreeView: TTreeView;

    // selected item
    SelectedItemGroupBox: TGroupBox;
    TypeLabel: TLabel;
    ProjectSpecificCheckBox: TCheckBox;
    NameLabel: TLabel;
    NameEdit: TEdit;
    DescriptionLabel: TLabel;
    DescriptionEdit: TEdit;
    VariableLabel: TLabel;
    VariableEdit: TEdit;
    ValueNoteBook: TNoteBook;
    ValueAsTextSynEdit: TSynEdit;
    ValueAsFilePathsSynEdit: TSynEdit;
    MoveFilePathUpBitBtn: TBitBtn;
    MoveFilePathDownBitBtn: TBitBtn;
    DeleteFilePathBitBtn: TBitBtn;
    InsertFilePathBitBtn: TBitBtn;

    procedure SaveAndExitMenuItemClick(Sender: TObject);
    procedure DontSaveAndExitMenuItemClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure DefineTreeViewMouseUp(Sender:TObject; Button:TMouseButton;
                                    Shift:TShiftState;  X,Y:integer);
    procedure ValueNoteBookPageChanged(Sender:TObject);
  private
    FDefineTree: TDefineTree;
    FLastSelectedNode: TTreeNode;
    procedure CreateComponents;
    function CreateSeperator : TMenuItem;
    procedure RebuildDefineTreeView;
    procedure AddDefineNodes(ANode: TDefineTemplate; AParent: TTreeNode;
      WithChilds,WithNextSiblings: boolean);
    procedure SetNodeImages(ANode: TTreeNode);
    procedure ValueAsPathToValueAsText;
    procedure SaveSelectedValues;
    procedure ShowSelectedValues;
    function ValueToFilePathText(const AValue: string): string;
  public
    procedure Assign(ACodeToolBoss: TCodeToolManager;
      Options: TCodeToolsOptions);
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property DefineTree: TDefineTree read FDefineTree;
  end;

function ShowCodeToolsDefinesEditor(ACodeToolBoss: TCodeToolManager;
  Options: TCodeToolsOptions): TModalResult;


implementation

const
  DefineActionNames: array[TDefineAction] of string = (
      'None', 'Block', 'Define', 'Undefine', 'DefineAll',
      'If', 'IfDef', 'IfNDef', 'ElseIf', 'Else', 'Directory'
    );

type
  TWinControlClass = class of TWinControl;


function ShowCodeToolsDefinesEditor(ACodeToolBoss: TCodeToolManager;
  Options: TCodeToolsOptions): TModalResult;
var CodeToolsDefinesEditor: TCodeToolsDefinesEditor;
begin
  CodeToolsDefinesEditor:=TCodeToolsDefinesEditor.Create(Application);
  CodeToolsDefinesEditor.Assign(ACodeToolBoss,Options);
  Result:=CodeToolsDefinesEditor.ShowModal;
  CodeToolsDefinesEditor.Free;
end;

{ TCodeToolsDefinesEditor }

procedure TCodeToolsDefinesEditor.SaveAndExitMenuItemClick(Sender: TObject);
begin
  ModalResult:=mrOk;
end;

procedure TCodeToolsDefinesEditor.DontSaveAndExitMenuItemClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TCodeToolsDefinesEditor.FormResize(Sender: TObject);
var MaxX, MaxY, SelGrpBoxTop, SelItemMaxX, SelItemMaxY,
  ValNoteBookMaxX, ValNoteBookMaxY: integer;
begin
  MaxX:=ClientWidth-2;
  MaxY:=ClientHeight-2;
  SelGrpBoxTop:=MaxY-300;

  // define tree ---------------------------------------------------------------
  with DefineTreeView do begin
    Left:=3;
    Top:=3;
    Width:=MaxX-2*Left;
    Height:=SelGrpBoxTop-2*Top;
  end;

  // selected item -------------------------------------------------------------
  with SelectedItemGroupBox do begin
    Left:=DefineTreeView.Left;
    Top:=SelGrpBoxTop;
    Width:=MaxX-2*Left;
    Height:=MaxY-Top-30;
  end;
  SelItemMaxX:=SelectedItemGroupBox.ClientWidth-8;
  SelItemMaxY:=SelectedItemGroupBox.ClientHeight-18;
  with TypeLabel do begin
    Left:=5;
    Top:=3;
    Width:=SelItemMaxX-2*Left;
  end;
  with ProjectSpecificCheckBox do begin
    Left:=TypeLabel.Left;
    Top:=TypeLabel.Top+TypeLabel.Height+5;
    Width:=SelItemMaxX-2*Left;
  end;
  with DescriptionLabel do begin
    Left:=ProjectSpecificCheckBox.Left;
    Top:=ProjectSpecificCheckBox.Top+ProjectSpecificCheckBox.Height+5;
    Width:=70;
  end;
  with DescriptionEdit do begin
    Left:=DescriptionLabel.Left+DescriptionLabel.Width+5;
    Top:=DescriptionLabel.Top;
    Width:=SelItemMaxX-Left-5;
  end;
  with NameLabel do begin
    Left:=DescriptionLabel.Left;
    Top:=DescriptionLabel.Top+DescriptionLabel.Height+5;
    Width:=70;
  end;
  with NameEdit do begin
    Left:=NameLabel.Left+NameLabel.Width+5;
    Top:=NameLabel.Top;
    Width:=150;
  end;
  with VariableLabel do begin
    Left:=NameEdit.Left+NameEdit.Width+30;
    Top:=NameLabel.Top;
    Width:=70;
  end;
  with VariableEdit do begin
    Left:=VariableLabel.Left+VariableLabel.Width+5;
    Top:=VariableLabel.Top;
    Width:=SelItemMaxX-Left-5;
  end;
  with ValueNoteBook do begin
    Left:=0;
    Top:=VariableLabel.Top+VariableLabel.Height+8;
    Width:=SelItemMaxX;
    Height:=SelItemMaxY-Top-5;
  end;
  ValNoteBookMaxX:=ValueNoteBook.ClientWidth-7;//ValueAsTextSynEdit.Parent.ClientWidth;
  ValNoteBookMaxY:=ValueNoteBook.ClientHeight-32;//ValueAsTextSynEdit.Parent.ClientHeight;
  with ValueAsTextSynEdit do begin
    Left:=0;
    Top:=0;
    Width:=ValNoteBookMaxX;
    Height:=ValNoteBookMaxY;
  end;
  with ValueAsFilePathsSynEdit do begin
    Left:=0;
    Top:=0;
    Width:=ValNoteBookMaxX-80;
    Height:=ValNoteBookMaxY;
  end;
  with MoveFilePathUpBitBtn do begin
    Left:=ValNoteBookMaxX-75;
    Top:=1;
    Width:=ValNoteBookMaxX-Left-5;
  end;
  with MoveFilePathDownBitBtn do begin
    Left:=MoveFilePathUpBitBtn.Left;
    Top:=MoveFilePathUpBitBtn.Top+MoveFilePathUpBitBtn.Height+5;
    Width:=MoveFilePathUpBitBtn.Width;
  end;
  with DeleteFilePathBitBtn do begin
    Left:=MoveFilePathUpBitBtn.Left;
    Top:=MoveFilePathDownBitBtn.Top+MoveFilePathDownBitBtn.Height+5;
    Width:=MoveFilePathUpBitBtn.Width;
  end;
  with InsertFilePathBitBtn do begin
    Left:=MoveFilePathUpBitBtn.Left;
    Top:=DeleteFilePathBitBtn.Top+DeleteFilePathBitBtn.Height+5;
    Width:=MoveFilePathUpBitBtn.Width;
  end;
end;

procedure TCodeToolsDefinesEditor.DefineTreeViewMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  ShowSelectedValues;
end;

procedure TCodeToolsDefinesEditor.ValueNoteBookPageChanged(Sender: TObject);
begin
  if ValueNoteBook.PageIndex=0 then ValueAsPathToValueAsText;
end;

procedure TCodeToolsDefinesEditor.CreateComponents;

  procedure CreateWinControl(var AWinControl: TWinControl;
    AWinControlClass: TWinControlClass; const AName: string;
    AParent: TWinControl);
  begin
    AWinControl:=AWinControlClass.Create(Self);
    with AWinControl do begin
      Name:=AName;
      Parent:=AParent;
      Visible:=true;
    end;
  end;
  
  procedure AddMenuItem(var AMenuItem: TMenuItem; const AName, ACaption: string;
    AParent: TMenuItem);
  begin
    AMenuItem:=TMenuItem.Create(nil);
    AMenuItem.Name:=AName;
    AMenuItem.Caption:=ACaption;
    if AParent=nil then
      MainMenu.Items.Add(AMenuItem)
    else
      AParent.Add(AMenuItem);
  end;
  
  procedure AddResImg(const ResName: string);
  var Pixmap: TPixmap;
  begin
    Pixmap:=TPixmap.Create;
    Pixmap.TransparentColor:=clWhite;
    Pixmap.LoadFromLazarusResource(ResName);
    TheImageList.Add(Pixmap,nil)
  end;

begin
  TheImageList:=TImageList.Create(Self);
  with TheImageList do begin
    Width:=22;
    Height:=22;
    Name:='TheImageList';
    AddResImg('define_22x22');
    AddResImg('defineall_22x22');
    AddResImg('undefine_22x22');
    AddResImg('block_22x22');
    AddResImg('directory_22x22');
    AddResImg('if_22x22');
    AddResImg('ifdef_22x22');
    AddResImg('ifndef_22x22');
    AddResImg('elseif_22x22');
    AddResImg('else_22x22');
    AddResImg('ctdefinestate_none_22x22');
    AddResImg('ctdefinestate_auto_22x22');
    AddResImg('ctdefinestate_projspec_22x22');
    AddResImg('ctdefinestate_autoproj_22x22');
  end;

  // Main Menu -----------------------------------------------------------------
  MainMenu := TMainMenu.Create(Self);
  MainMenu.Name:='MainMenu';
  Menu := MainMenu;

  // exit menu
  AddMenuItem(ExitMenuItem,'ExitMenuItem','Exit',nil);
  AddMenuItem(SaveAndExitMenuItem,'SaveAndExitMenuItem','Save and Exit',
              ExitMenuItem);
  SaveAndExitMenuItem.OnClick:=@SaveAndExitMenuItemClick;
  ExitMenuItem.Add(CreateSeperator);
  AddMenuItem(DontSaveAndExitMenuItem,'DontSaveAndExitMenuItem',
              'Exit without Save',ExitMenuItem);
  DontSaveAndExitMenuItem.OnClick:=@DontSaveAndExitMenuItemClick;

  // edit nodes
  AddMenuItem(EditMenuItem,'EditMenuItem','Edit',nil);
  AddMenuItem(MoveNodeUpMenuItem,'MoveNodeUpMenuItem','Move node up',
              EditMenuItem);
  AddMenuItem(MoveNodeDownMenuItem,'MoveNodeDownMenuItem','Move node down',
              EditMenuItem);
  EditMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertDefineMenuItem,'InsertDefineMenuItem','Insert Define',
              EditMenuItem);
  AddMenuItem(InsertDefineAllMenuItem,'InsertDefineAllMenuItem','Insert Define All',
              EditMenuItem);
  AddMenuItem(InsertUndefineMenuItem,'InsertUndefineMenuItem','Insert Undefine',
              EditMenuItem);
  AddMenuItem(InsertBlockMenuItem,'InsertBlockMenuItem','Insert Block',
              EditMenuItem);
  AddMenuItem(InsertDirectoryMenuItem,'InsertDirectoryMenuItem','Insert Directory',
              EditMenuItem);
  AddMenuItem(InsertIfMenuItem,'InsertIfMenuItem','Insert If',
              EditMenuItem);
  AddMenuItem(InsertIfDefMenuItem,'InsertIfDefMenuItem','Insert IfDef',
              EditMenuItem);
  AddMenuItem(InsertIfNotDefMenuItem,'InsertIfNotDefMenuItem','Insert IfNDef',
              EditMenuItem);
  AddMenuItem(InsertElseMenuItem,'InsertElseMenuItem','Insert Else',
              EditMenuItem);
  EditMenuItem.Add(CreateSeperator);
  AddMenuItem(DeleteNodeMenuItem,'DeleteNodeMenuItem','Delete node',
              EditMenuItem);
  EditMenuItem.Add(CreateSeperator);
  AddMenuItem(CopyToClipbrdMenuItem,'CopyToClipbrdMenuItem','Copy to clipboard',
              EditMenuItem);
  AddMenuItem(PasteFromClipbrdMenuItem,'PasteFromClipbrdMenuItem',
              'Paste from clipboard',EditMenuItem);

  // tools
  AddMenuItem(ToolsMenuItem,'ToolsMenuItem','Tools',nil);
  AddMenuItem(OpenPreviewMenuItem,'OpenPreviewMenuItem','Open Preview',
              ToolsMenuItem);
  AddMenuItem(ShowMacroListMenuItem,'ShowMacroListMenuItem','Show Macros',
              ToolsMenuItem);

  // templates
  AddMenuItem(InsertTemplateMenuItem,'InsertTemplateMenuItem',
              'Insert Template',nil);


  // define tree----------------------------------------------------------------
  CreateWinControl(DefineTreeView,TTreeView,'DefineTreeView',Self);
  with DefineTreeView do begin
    DefaultItemHeight:=22;
    Images:=TheImageList;
    StateImages:=TheImageList;
    OnMouseUp:=@DefineTreeViewMouseUp;
  end;

  // selected item
  CreateWinControl(SelectedItemGroupBox,TGroupBox,'SelectedItemGroupBox',Self);
  SelectedItemGroupBox.Caption:='Selected Node:';
  
  CreateWinControl(TypeLabel,TLabel,'TypeLabel',SelectedItemGroupBox);
  
  CreateWinControl(ProjectSpecificCheckBox,TCheckBox,'ProjectSpecificCheckBox',
                   SelectedItemGroupBox);
  ProjectSpecificCheckBox.Caption:=
    'Node and its children are only valid for this project';
  
  CreateWinControl(NameLabel,TLabel,'NameLabel',SelectedItemGroupBox);
  NameLabel.Caption:='Name:';
  
  CreateWinControl(NameEdit,TEdit,'NameEdit',SelectedItemGroupBox);

  CreateWinControl(DescriptionLabel,TLabel,'DescriptionLabel',
                   SelectedItemGroupBox);
  DescriptionLabel.Caption:='Description:';
                   
  CreateWinControl(DescriptionEdit,TEdit,'DescriptionEdit',
                   SelectedItemGroupBox);
                   
  CreateWinControl(VariableLabel,TLabel,'VariableLabel',SelectedItemGroupBox);
  VariableLabel.Caption:='Variable:';
  
  CreateWinControl(VariableEdit,TEdit,'VariableEdit',SelectedItemGroupBox);
  
  CreateWinControl(ValueNoteBook,TNoteBook,'ValueNoteBook',
                   SelectedItemGroupBox);
  with ValueNoteBook do begin
    Pages[0]:='Value as Text';
    Pages.Add('Value as File Paths');
    OnPageChanged:=@ValueNoteBookPageChanged;
  end;
                   
  CreateWinControl(ValueAsTextSynEdit,TSynEdit,'ValueAsTextSynEdit',
                   ValueNoteBook.Page[0]);
  ValueAsTextSynEdit.Options:=[eoBracketHighlight, eoHideRightMargin,
    eoDragDropEditing, eoHalfPageScroll, eoScrollByOneLess, eoScrollPastEol,
    eoSmartTabs, eoTabsToSpaces, eoTrimTrailingSpaces];
  ValueAsTextSynEdit.Gutter.Visible:=false;

  CreateWinControl(ValueAsFilePathsSynEdit,TSynEdit,'ValueAsFilePathsSynEdit',
                   ValueNoteBook.Page[1]);
  ValueAsFilePathsSynEdit.Options:=[eoBracketHighlight, eoHideRightMargin,
    eoDragDropEditing, eoHalfPageScroll, eoScrollByOneLess, eoScrollPastEol,
    eoSmartTabs, eoTabsToSpaces, eoTrimTrailingSpaces];
  ValueAsFilePathsSynEdit.Gutter.Visible:=false;

  CreateWinControl(MoveFilePathUpBitBtn,TBitBtn,'MoveFilePathUpBitBtn',
                   ValueNoteBook.Page[1]);
  MoveFilePathUpBitBtn.Caption:='Move path up';
                   
  CreateWinControl(MoveFilePathDownBitBtn,TBitBtn,'MoveFilePathDownBitBtn',
                   ValueNoteBook.Page[1]);
  MoveFilePathDownBitBtn.Caption:='Move path down';
                   
  CreateWinControl(DeleteFilePathBitBtn,TBitBtn,'DeleteFilePathBitBtn',
                   ValueNoteBook.Page[1]);
  DeleteFilePathBitBtn.Caption:='Delete path';
                   
  CreateWinControl(InsertFilePathBitBtn,TBitBtn,'InsertFilePathBitBtn',
                   ValueNoteBook.Page[1]);
  InsertFilePathBitBtn.Caption:='Insert path';
end;

function TCodeToolsDefinesEditor.CreateSeperator : TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.Caption := '-';
end;

procedure TCodeToolsDefinesEditor.RebuildDefineTreeView;
begin
  DefineTreeView.Items.BeginUpdate;
  DefineTreeView.Items.Clear;
  AddDefineNodes(FDefineTree.RootTemplate,nil,true,true);
  DefineTreeView.Items.EndUpdate;
end;

procedure TCodeToolsDefinesEditor.AddDefineNodes(
  ANode: TDefineTemplate; AParent: TTreeNode;
  WithChilds, WithNextSiblings: boolean);
var NewTreeNode: TTreeNode;
begin
  if ANode=nil then exit;
//writeln(' AAA ',StringOfChar(' ',ANode.Level*2),' ',ANode.Name,' ',WithChilds,',',WithNextSiblings);
  DefineTreeView.Items.BeginUpdate;
  NewTreeNode:=DefineTreeView.Items.AddChildObject(AParent,ANode.Name,ANode);
  SetNodeImages(NewTreeNode);
  if WithChilds and (ANode.FirstChild<>nil) then begin
    AddDefineNodes(ANode.FirstChild,NewTreeNode,true,true);
  end;
  if WithNextSiblings and (ANode.Next<>nil) then begin
    AddDefineNodes(ANode.Next,AParent,WithChilds,true);
  end;
  DefineTreeView.Items.EndUpdate;
end;

procedure TCodeToolsDefinesEditor.SetNodeImages(ANode: TTreeNode);
var ADefineTemplate: TDefineTemplate;
begin
  ADefineTemplate:=TDefineTemplate(ANode.Data);
  case ADefineTemplate.Action of
    da_Define: ANode.ImageIndex:=0;
    da_DefineAll: ANode.ImageIndex:=1;
    da_Undefine: ANode.ImageIndex:=2;
    da_Block: ANode.ImageIndex:=3;
    da_Directory: ANode.ImageIndex:=4;
    da_If: ANode.ImageIndex:=5;
    da_IfDef: ANode.ImageIndex:=6;
    da_IfNDef: ANode.ImageIndex:=7;
    da_ElseIf: ANode.ImageIndex:=8;
    da_Else: ANode.ImageIndex:=9;
  else
    ANode.ImageIndex:=-1;
  end;
  ANode.SelectedIndex:=ANode.ImageIndex;
  if dtfAutoGenerated in ADefineTemplate.Flags then begin
    if dtfProjectSpecific in ADefineTemplate.Flags then
      ANode.StateIndex:=13
    else
      ANode.StateIndex:=11;
  end else begin
    if dtfProjectSpecific in ADefineTemplate.Flags then
      ANode.StateIndex:=12
    else
      ANode.StateIndex:=10;
  end;
end;

procedure TCodeToolsDefinesEditor.ValueAsPathToValueAsText;
var s: string;
  i, j, l: integer;
begin
  s:=ValueAsFilePathsSynEdit.Text;
  l:=length(s);
  if (l>0) and (s[l] in [#13,#10]) then begin
    // remove line end at end of Text, that was added automatically
    dec(l);
    if (l>0) and (s[l] in [#13,#10]) and (s[l]<>s[l+1]) then
      dec(l);
    SetLength(s,l);
  end;
  // replace line ends with semicolon
  i:=1;
  j:=1;
  while i<=l do begin
    if s[i] in [#10,#13] then begin
      inc(i);
      if (i<l) and (s[i] in [#10,#13]) and (s[i]<>s[i+1]) then
        inc(i);
      s[j]:=';';
      inc(j);
    end else begin
      s[j]:=s[i];
      inc(i);
      inc(j);
    end;
  end;
  SetLength(s,j-1);
  ValueAsTextSynEdit.Text:=s;
end;

procedure TCodeToolsDefinesEditor.SaveSelectedValues;
var
  SelTreeNode: TTreeNode;
  SelDefNode: TDefineTemplate;
  s: string;
  l: integer;
begin
  SelTreeNode:=DefineTreeView.Selected;
  if (SelTreeNode<>nil) then begin
    SelDefNode:=TDefineTemplate(SelTreeNode.Data);
    if (not SelDefNode.IsAutoGenerated) then begin
      if ProjectSpecificCheckBox.Checked then
        Include(SelDefNode.Flags,dtfProjectSpecific);
      SelDefNode.Name:=NameEdit.Text;
      SelDefNode.Variable:=VariableEdit.Text;
      SelDefNode.Description:=DescriptionEdit.Text;
      s:=ValueAsTextSynEdit.Text;
      l:=length(s);
      if (l>0) and (s[l] in [#13,#10]) then begin
        // remove line end at end of Text, that was added automatically
        dec(l);
        if (l>0) and (s[l] in [#13,#10]) and (s[l]<>s[l+1]) then
          dec(l);
        SetLength(s,l);
      end;
      SelDefNode.Value:=s;
    end;
  end;
end;

procedure TCodeToolsDefinesEditor.ShowSelectedValues;
var
  SelTreeNode: TTreeNode;
  SelDefNode: TDefineTemplate;
  s: string;
begin
  SelTreeNode:=DefineTreeView.Selected;
  if SelTreeNode<>FLastSelectedNode then begin
    SaveSelectedValues;
  end;
  if SelTreeNode<>nil then begin
    SelDefNode:=TDefineTemplate(SelTreeNode.Data);
    SelectedItemGroupBox.Enabled:=true;
    s:='Action: '+DefineActionNames[SelDefNode.Action];
    if SelDefNode.IsAutoGenerated then
      s:=s+', auto generated';
    if SelDefNode.IsProjectSpecific then
      s:=s+', project specific';
    TypeLabel.Caption:=s;
    ProjectSpecificCheckBox.Checked:=dtfProjectSpecific in SelDefNode.Flags;
    NameEdit.Text:=SelDefNode.Name;
    DescriptionEdit.Text:=SelDefNode.Description;
    VariableEdit.Text:=SelDefNode.Variable;
    ValueAsTextSynEdit.Text:=SelDefNode.Value;
    ValueAsFilePathsSynEdit.Text:=ValueToFilePathText(SelDefNode.Value);
    if SelDefNode.IsAutoGenerated then begin
      ValueAsTextSynEdit.Options:=ValueAsTextSynEdit.Options+[eoNoCaret];
      ValueAsTextSynEdit.ReadOnly:=true;
    end else begin
      ValueAsTextSynEdit.Options:=ValueAsTextSynEdit.Options-[eoNoCaret];
      ValueAsTextSynEdit.ReadOnly:=false;
    end;
    ValueAsFilePathsSynEdit.Options:=ValueAsTextSynEdit.Options;
    ValueAsFilePathsSynEdit.ReadOnly:=ValueAsTextSynEdit.ReadOnly;
  end else begin
    SelectedItemGroupBox.Enabled:=false;
    TypeLabel.Caption:='none selected';
    ProjectSpecificCheckBox.Enabled:=false;
    NameEdit.Text:='';
    DescriptionEdit.Text:='';
    VariableEdit.Text:='';
    ValueAsTextSynEdit.Text:='';
    ValueAsFilePathsSynEdit.Text:='';
  end;
  FLastSelectedNode:=SelTreeNode;
end;

function TCodeToolsDefinesEditor.ValueToFilePathText(const AValue: string
  ): string;
var i: integer;
begin
  Result:=AValue;
  for i:=1 to length(Result) do
    if Result[i]=';' then Result[i]:=#13;
end;

procedure TCodeToolsDefinesEditor.Assign(ACodeToolBoss: TCodeToolManager;
  Options: TCodeToolsOptions);
begin
  FLastSelectedNode:=nil;
  FDefineTree.Assign(ACodeToolBoss.DefineTree);
  RebuildDefineTreeView;
  ShowSelectedValues;
end;

constructor TCodeToolsDefinesEditor.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  if LazarusResources.Find(ClassName)=nil then begin
    SetBounds((Screen.Width-480) div 2,(Screen.Height-430) div 2, 485, 435);
    Caption:='CodeTools Defines Editor';
    OnResize:=@FormResize;
    
    CreateComponents;
  end;
  FDefineTree:=TDefineTree.Create;
  Resize;
end;

destructor TCodeToolsDefinesEditor.Destroy;
begin
  FDefineTree.Free;
  inherited Destroy;
end;

//==============================================================================

initialization
  {$I codetoolsdefines.lrs}


end.

