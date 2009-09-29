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

  Author: Mattias Gaertner

  Abstract:
    Dialog for the Extract Proc feature.
    Allows user choose what kind of procedure/function to create and
    shows missing identifiers.
}
unit ExtractProcDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, AVL_Tree, LResources, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, Buttons, StdCtrls,
  BasicCodeTools, CodeTree, CodeAtom, CodeCache, CodeToolManager,
  ExtractProcTool,
  LazarusIDEStrConsts, IDEProcs, MiscOptions, IDEContextHelpEdit;

type

  { TExtractProcDialog }

  TExtractProcDialog = class(TForm)
    FuncVariableComboBox: TComboBox;
    CreateFunctionCheckBox: TCheckBox;
    FunctionGroupBox: TGroupBox;
    FuncVariableLabel: TLabel;
    MissingIdentifiersListBox: TListBox;
    MissingIdentifiersGroupBox: TGroupBox;
    NameEdit: TEdit;
    NameGroupbox: TGroupBox;
    OkButton: TBitBtn;
    CancelButton: TBitBtn;
    HelpButton: TBitBtn;
    BtnPanel: TPanel;
    TypeRadiogroup: TRadioGroup;
    procedure CreateFunctionCheckBoxChange(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
    procedure ExtractProcDialogCreate(Sender: TObject);
    procedure ExtractProcDialogClose(Sender: TObject;
      var CloseAction: TCloseAction);
    procedure OkButtonClick(Sender: TObject);
  private
    FMethodPossible: boolean;
    FMissingIdentifiers: TAVLTree;
    FSubProcSameLvlPossible: boolean;
    FVariables: TAVLTree;
    procedure SetMissingIdentifiers(const AValue: TAVLTree);
    procedure SetVariables(const AValue: TAVLTree);
    function VarNodeToStr(Variable: TExtractedProcVariable): string;
  public
    procedure UpdateAvailableTypes;
    procedure UpdateFunction;
    function GetProcType: TExtractProcType;
    function GetProcName: string;
    function GetFunctionNode: TCodeTreeNode;

    property MethodPossible: boolean read FMethodPossible write FMethodPossible;
    property SubProcSameLvlPossible: boolean read FSubProcSameLvlPossible write FSubProcSameLvlPossible;
    property MissingIdentifiers: TAVLTree read FMissingIdentifiers write SetMissingIdentifiers;
    property Variables: TAVLTree read FVariables write SetVariables;// tree of TExtractedProcVariable
  end;

function ShowExtractProcDialog(Code: TCodeBuffer;
  const BlockBegin, BlockEnd: TPoint;
  var NewSource: TCodeBuffer;
  var NewX, NewY, NewTopLine: integer): TModalResult;

implementation

function ShowExtractProcDialog(Code: TCodeBuffer;
  const BlockBegin, BlockEnd: TPoint;
  var NewSource: TCodeBuffer;
  var NewX, NewY, NewTopLine: integer): TModalresult;
var
  ExtractProcDialog: TExtractProcDialog;
  MethodPossible: Boolean;
  SubProcSameLvlPossible: boolean;
  ProcName: String;
  ProcType: TExtractProcType;
  MissingIdentifiers: TAVLTree;
  VarTree: TAVLTree;
  FuncNode: TCodeTreeNode;
  FunctionResultVariableStartPos: Integer;
begin
  Result:=mrCancel;
  if CompareCaret(BlockBegin,BlockEnd)<=0 then begin
    MessageDlg(lisNoCodeSelected,
      lisPleaseSelectSomeCodeToExtractANewProcedureMethod,
      mtInformation,[mbCancel],0);
    exit;
  end;
  
  MissingIdentifiers:=nil;
  VarTree:=nil;
  try
    VarTree:=CreateExtractProcVariableTree;
    // check if selected statements can be extracted
    if not CodeToolBoss.CheckExtractProc(Code,BlockBegin,BlockEnd,MethodPossible,
      SubProcSameLvlPossible,MissingIdentifiers,VarTree)
    then begin
      if CodeToolBoss.ErrorMessage='' then begin
        MessageDlg(lisInvalidSelection,
          Format(lisThisStatementCanNotBeExtractedPleaseSelectSomeCode, [#13]),
        mtInformation,[mbCancel],0);
      end;
      exit;
    end;

    // ask user how to extract
    ExtractProcDialog:=TExtractProcDialog.Create(nil);
    try
      ExtractProcDialog.MethodPossible:=MethodPossible;
      ExtractProcDialog.SubProcSameLvlPossible:=SubProcSameLvlPossible;
      ExtractProcDialog.MissingIdentifiers:=MissingIdentifiers;
      ExtractProcDialog.UpdateAvailableTypes;
      ExtractProcDialog.Variables:=VarTree;
      Result:=ExtractProcDialog.ShowModal;
      if Result<>mrOk then exit;
      ProcName:=ExtractProcDialog.GetProcName;
      ProcType:=ExtractProcDialog.GetProcType;
      FuncNode:=ExtractProcDialog.GetFunctionNode;
      FunctionResultVariableStartPos:=0;
      if (FuncNode<>nil) then
        FunctionResultVariableStartPos:=FuncNode.StartPos;
    finally
      ExtractProcDialog.Free;
    end;

    // extract procedure/method
    if not CodeToolBoss.ExtractProc(Code,BlockBegin,BlockEnd,ProcType,ProcName,
      MissingIdentifiers,NewSource,NewX,NewY,NewTopLine,
      FunctionResultVariableStartPos)
    then begin
      Result:=mrCancel;
      exit;
    end;
    Result:=mrOk;
  finally
    ClearExtractProcVariableTree(VarTree,true);
    CodeToolBoss.FreeTreeOfPCodeXYPosition(MissingIdentifiers);
  end;
end;

{ TExtractProcDialog }

procedure TExtractProcDialog.ExtractProcDialogCreate(Sender: TObject);
begin
  Caption:=lisExtractProcedure;
  NameGroupbox.Caption:=lisNameOfNewProcedure;
  TypeRadiogroup.Caption:=dlgEnvType;
  NameEdit.Text:=MiscellaneousOptions.ExtractProcName;
  MissingIdentifiersGroupBox.Caption:=lisMissingIdentifiers;

  FunctionGroupBox.Caption:=lisFunction;
  CreateFunctionCheckBox.Caption:=lisCreateFunction;
  FuncVariableLabel.Caption:=lisResult2;
  
  OkButton.Caption:=lisExtract;
end;

procedure TExtractProcDialog.HelpButtonClick(Sender: TObject);
begin
  ShowContextHelpForIDE(Self);
end;

procedure TExtractProcDialog.CreateFunctionCheckBoxChange(Sender: TObject);
begin
  FuncVariableComboBox.Enabled:=CreateFunctionCheckBox.Checked;
  FuncVariableLabel.Enabled:=FuncVariableComboBox.Enabled;
end;

procedure TExtractProcDialog.ExtractProcDialogClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  MiscellaneousOptions.ExtractProcName:=NameEdit.Text;
end;

procedure TExtractProcDialog.OkButtonClick(Sender: TObject);
var
  ProcName: String;
begin
  ProcName:=GetProcName;
  if (ProcName='') or (not IsValidIdent(ProcName)) then begin
    MessageDlg(lisInvalidProcName,
      Format(lisSVUOisNotAValidIdentifier, ['"', ProcName, '"']),
      mtError,[mbCancel],0);
    exit;
  end;
  ModalResult:=mrOk;
end;

procedure TExtractProcDialog.SetMissingIdentifiers(const AValue: TAVLTree);
var
  Node: TAVLTreeNode;
  CodePos: PCodeXYPosition;
  p: integer;
  Identifier: string;
  s: String;
begin
  if AValue=FMissingIdentifiers then exit;
  FMissingIdentifiers:=AValue;
  MissingIdentifiersListBox.Items.BeginUpdate;
  MissingIdentifiersListBox.Items.Clear;
  if FMissingIdentifiers<>nil then begin
    Node:=FMissingIdentifiers.FindLowest;
    while Node<>nil do begin
      CodePos:=PCodeXYPosition(Node.Data);
      CodePos^.Code.LineColToPosition(CodePos^.Y,CodePos^.X,p);
      if p>=1 then
        Identifier:=GetIdentifier(@CodePos^.Code.Source[p])
      else
        Identifier:='?';
      s:=Identifier+' at '+IntToStr(CodePos^.Y)+','+IntToStr(CodePos^.X);
      MissingIdentifiersListBox.Items.Add(s);
      Node:=FMissingIdentifiers.FindSuccessor(Node);
    end;
  end;
  MissingIdentifiersListBox.Items.EndUpdate;
  
  // show/hide the MissingIdentifiersGroupBox
  MissingIdentifiersGroupBox.Visible:=MissingIdentifiersListBox.Items.Count>0;
end;

procedure TExtractProcDialog.SetVariables(const AValue: TAVLTree);
begin
  if FVariables=AValue then exit;
  FVariables:=AValue;
  UpdateFunction;
end;

function TExtractProcDialog.VarNodeToStr(Variable: TExtractedProcVariable
  ): string;
begin
  if Variable.Node.Desc=ctnVarDefinition then
    Result:=Variable.Tool.ExtractDefinitionName(Variable.Node)
            +' : '+Variable.Tool.ExtractDefinitionNodeType(Variable.Node)
  else
    Result:='';
end;

procedure TExtractProcDialog.UpdateAvailableTypes;
begin
  with TypeRadiogroup.Items do begin
    BeginUpdate;
    Clear;
    if MethodPossible then begin
      Add(lisPublicMethod);
      Add(lisPrivateMethod);
      Add(lisProtectedMethod);
      Add(lisPublishedMethod);
      TypeRadiogroup.Columns:=2;
    end else begin
      TypeRadiogroup.Columns:=1;
    end;
    Add(lisProcedure);
    Add(lisProcedureWithInterface);
    Add(lisSubProcedure);
    if SubProcSameLvlPossible then
      Add(lisSubProcedureOnSameLevel);
    EndUpdate;
    TypeRadiogroup.ItemIndex:=Count-1;
  end;
end;

procedure TExtractProcDialog.UpdateFunction;
var
  AVLNode: TAVLTreeNode;
  Variable: TExtractedProcVariable;
  sl: TStringList;
begin
  FuncVariableComboBox.Items.BeginUpdate;
  FuncVariableComboBox.Items.Clear;
  if Variables<>nil then begin
    sl:=TStringList.Create;
    try
      AVLNode:=Variables.FindLowest;
      while AVLNode<>nil do begin
        Variable:=TExtractedProcVariable(AVLNode.Data);
        if Variable.WriteInSelection then begin
          //DebugLn(['TExtractProcDialog.UpdateFunction ',Variable.Node.DescAsString]);
          if Variable.Node.Desc=ctnVarDefinition then begin
            sl.Add(VarNodeToStr(Variable));
          end;
        end;
        AVLNode:=Variables.FindSuccessor(AVLNode);
      end;
      sl.Sort;
      FuncVariableComboBox.Items.Assign(sl);
      if FuncVariableComboBox.Items.Count>0 then
        FuncVariableComboBox.Text:=FuncVariableComboBox.Items[0];
      FuncVariableComboBox.ItemIndex:=0;
    finally
      sl.Free;
    end;
  end;
  FuncVariableComboBox.Items.EndUpdate;
  FuncVariableComboBox.Enabled:=CreateFunctionCheckBox.Checked;
  FuncVariableLabel.Enabled:=FuncVariableComboBox.Enabled;
  FunctionGroupBox.Visible:=FuncVariableComboBox.Items.Count>0;
end;

function TExtractProcDialog.GetProcType: TExtractProcType;
var
  Item: string;
begin
  Result:=eptSubProcedure;
  if TypeRadiogroup.ItemIndex>=0 then begin
    Item:=TypeRadiogroup.Items[TypeRadiogroup.ItemIndex];
    if Item=lisPublicMethod then Result:=eptPublicMethod
    else if Item=lisPrivateMethod then Result:=eptPrivateMethod
    else if Item=lisProtectedMethod then Result:=eptProtectedMethod
    else if Item=lisPublishedMethod then Result:=eptPublishedMethod
    else if Item=lisProcedure then Result:=eptProcedure
    else if Item=lisProcedureWithInterface then Result:=eptProcedureWithInterface
    else if Item=lisSubProcedure then Result:=eptSubProcedure
    else if Item=lisSubProcedureOnSameLevel then Result:=eptSubProcedureSameLvl;
  end;
end;

function TExtractProcDialog.GetProcName: string;
begin
  Result:=NameEdit.Text;
end;

function TExtractProcDialog.GetFunctionNode: TCodeTreeNode;
var
  AVLNode: TAVLTreeNode;
  s: String;
  Find: String;
  Variable: TExtractedProcVariable;
begin
  Result:=nil;
  if (Variables=nil) or (not CreateFunctionCheckBox.Checked) then exit;
  Find:=FuncVariableComboBox.Text;
  AVLNode:=Variables.FindLowest;
  while AVLNode<>nil do begin
    Variable:=TExtractedProcVariable(AVLNode.Data);
    if Variable.WriteInSelection then begin
      //DebugLn(['TExtractProcDialog.UpdateFunction ',Variable.Node.DescAsString]);
      if Variable.Node.Desc=ctnVarDefinition then begin
        s:=VarNodeToStr(Variable);
        if s=Find then begin
          Result:=Variable.Node;
          exit;
        end;
      end;
    end;
    AVLNode:=Variables.FindSuccessor(AVLNode);
  end;
end;

initialization
  {$I extractprocdlg.lrs}

end.

