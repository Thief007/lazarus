{
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
    Dialog to edit System-Variables-User-Overrides.
    Used by the run parameter dialog
}
unit SysVarUserOverrideDlg;

{$mode objfpc}{$H+}

{$I ide.inc}

interface

uses
  {$IFDEF IDE_MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, Controls, Forms, Buttons, StdCtrls, ComCtrls, Dialogs,
  ExtCtrls, LResources, XMLCfg, DOS, IDEProcs;

type
  TSysVarUserOverrideDialog = class(TForm)
    VariableLabel: TLabel;
    VariableEdit: TEdit;
    ValueLabel: TLabel;
    ValueEdit: TEdit;
    OkButton: TButton;
    CancelButton: TButton;
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
  public
    constructor Create(TheOwner: TComponent); override;
  end;

function ShowSysVarUserOverrideDialog(var Variable, Value: string): TModalResult;


implementation


function ShowSysVarUserOverrideDialog(var Variable, Value: string): TModalResult;
var SysVarUserOverrideDialog: TSysVarUserOverrideDialog;
begin
  SysVarUserOverrideDialog:=TSysVarUserOverrideDialog.Create(Application);
  with SysVarUserOverrideDialog do begin
    VariableEdit.Text:=Variable;
    ValueEdit.Text:=Value;
    Result:=ShowModal;
    if (Result=mrOk) then begin
      Variable:=Trim(VariableEdit.Text);
      Value:=ValueEdit.Text;
    end;
    Free;
  end;
end;

{ TSysVarUserOverrideDialog }

procedure TSysVarUserOverrideDialog.OkButtonClick(Sender: TObject);
var v: string;
begin
  v:=Trim(VariableEdit.Text);
  if not IsValidIdent(v) then begin
    if MessageDlg('Invalid variable name',
      '"'+v+'" is not a valid identifier.',
      mtWarning,[mbCancel,mbIgnore],0)=mrCancel
    then exit;
  end;
  ModalResult:=mrOk;
end;

procedure TSysVarUserOverrideDialog.CancelButtonClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

constructor TSysVarUserOverrideDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  if LazarusResources.Find(ClassName)=nil then begin

    Caption:='Override system variable';
    Width:=400;
    Height:=170;
    Position:=poScreenCenter;

    VariableLabel:=TLabel.Create(Self);
    with VariableLabel do begin
      Name:='VariableLabel';
      Parent:=Self;
      SetBounds(10,10,150,Height);
      Caption:='Variable:';
      Visible:=true;
    end;
    
    VariableEdit:=TEdit.Create(Self);
    with VariableEdit do begin
      Name:='VariableEdit';
      Parent:=Self;
      SetBounds(VariableLabel.Left,VariableLabel.Top+VariableLabel.Height+2,
        Self.ClientWidth-2*VariableLabel.Left,Height);
      Visible:=true;
    end;

    ValueLabel:=TLabel.Create(Self);
    with ValueLabel do begin
      Name:='ValueLabel';
      Parent:=Self;
      SetBounds(VariableEdit.Left,VariableEdit.Top+VariableEdit.Height+10,
        150,Height);
      Caption:='Value:';
      Visible:=true;
    end;

    ValueEdit:=TEdit.Create(Self);
    with ValueEdit do begin
      Name:='ValueEdit';
      Parent:=Self;
      SetBounds(ValueLabel.Left,ValueLabel.Top+ValueLabel.Height+2,
        Self.ClientWidth-2*ValueLabel.Left,Height);
      Visible:=true;
    end;

    OkButton:=TButton.Create(Self);
    with OkButton do begin
      Name:='OkButton';
      Parent:=Self;
      SetBounds(Self.ClientWidth-220,Self.ClientHeight-40,100,25);
      Caption:='Ok';
      OnClick:=@OkButtonClick;
      Visible:=true;
    end;

    CancelButton:=TButton.Create(Self);
    with CancelButton do begin
      Name:='CancelButton';
      Parent:=Self;
      SetBounds(OkButton.Left+OkButton.Width+10,OkButton.Top,100,25);
      Caption:='Cancel';
      OnClick:=@CancelButtonClick;
      Visible:=true;
    end;
  end;
end;

end.

