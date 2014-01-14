{%MainUnit ../dialogs.pp}
{
 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

function ShowInputDialog(const InputCaption, InputPrompt : String;
  MaskInput : Boolean; var Value : String) : Boolean;
var
  Form : TForm;
  Prompt : TLabel;
  Edit : TEdit;
  MinEditWidth: integer;
begin
  Result := False;
  Form := TForm.CreateNew(nil, 0);
  with Form do
  begin
    BorderStyle := bsDialog;
    Caption := InputCaption;
    Prompt := TLabel.Create(Form);
    with Prompt do
    begin
      Parent := Form;
      Caption := InputPrompt;
      Top := 8;
      Left := 8;
      Visible := True;
      AutoSize := True;
    end;
    Position := poScreenCenter;
    Edit := TEdit.Create(Form);
    with Edit do
    begin
      Parent := Form;
      Left := Prompt.Left;
      AnchorToNeighbour(akTop, 8, Prompt);
      AnchorParallel(akRight, 0, Prompt);
      MinEditWidth := max(260, Screen.Width div 4);
      Constraints.MinWidth := MinEditWidth;
      Text := Value;
      TabStop := True;
      Visible := True;
      if MaskInput then
      begin 
        EchoMode := emPassword; 
        PasswordChar:='*'; 
      end else 
      begin 
        EchoMode := emNormal;
        PasswordChar:=#0; 
      end; 
      TabOrder := 0;
    end;
    with TBitBtn.Create(Form) do
    begin
      Parent := Form;
      Kind := bkOk;
      Default := True;
      ModalResult := mrOk;
      Left := MinEditWidth div 6;
      AnchorToNeighbour(akTop, 8, Edit);
      AutoSize := True;
      TabStop := True;
      Visible := True;
      TabOrder := 1;
    end;
    with TBitBtn.Create(Form) do
    begin
      Parent := Form;
      Kind := bkCancel;
      Cancel := True;
      AnchorToNeighbour(akTop, 8, Edit);
      AnchorSide[akRight].Control := Edit;
      AnchorSide[akRight].Side := asrRight;
      BorderSpacing.Right := MinEditWidth div 6;
      Anchors := [akTop, akRight];
      
      AutoSize := True;
      TabStop := True;
      Visible := True;
      TabOrder := 2;
    end;
    
    ChildSizing.TopBottomSpacing := 8;
    ChildSizing.LeftRightSpacing := 8;
    AutoSize := true;

    // upon show, the edit control will be focused for editing, because it's
    // the first in the tab order
    if ShowModal = mrOk then
    begin
      Value := Edit.Text;
      Result := True;
    end;
    Form.Free;
  end;
end;

// included by dialogs.pp