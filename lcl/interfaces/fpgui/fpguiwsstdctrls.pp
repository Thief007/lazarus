{ $Id: FpGuiwsstdctrls.pp 5319 2004-03-17 20:11:29Z marc $}
{
 *****************************************************************************
 *                              FpGuiWSStdCtrls.pp                              * 
 *                              ---------------                              * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
}
unit FpGuiWSStdCtrls;

{$mode objfpc}{$H+}

interface

uses
  // Bindings
  fpgui, fpguiwsprivate,
  // LCL
  Classes, StdCtrls, Controls, LCLType,
  // Widgetset
  WSStdCtrls, WSLCLClasses;

type

  { TFpGuiWSScrollBar }

  TFpGuiWSScrollBar = class(TWSScrollBar)
  private
  protected
  public
  end;

  { TFpGuiWSCustomGroupBox }

  TFpGuiWSCustomGroupBox = class(TWSCustomGroupBox)
  private
  protected
  public
  end;

  { TFpGuiWSGroupBox }

  TFpGuiWSGroupBox = class(TWSGroupBox)
  private
  protected
  public
  end;

  { TFpGuiWSCustomComboBox }

  TFpGuiWSCustomComboBox = class(TWSCustomComboBox)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
  public
{    class function  GetSelStart(const ACustomComboBox: TCustomComboBox): integer; override;
    class function  GetSelLength(const ACustomComboBox: TCustomComboBox): integer; override;}
    class function  GetItemIndex(const ACustomComboBox: TCustomComboBox): integer; override;
{    class function  GetMaxLength(const ACustomComboBox: TCustomComboBox): integer; override;

    class procedure SetArrowKeysTraverseList(const ACustomComboBox: TCustomComboBox;
      NewTraverseList: boolean); virtual;
    class procedure SetSelStart(const ACustomComboBox: TCustomComboBox; NewStart: integer); override;
    class procedure SetSelLength(const ACustomComboBox: TCustomComboBox; NewLength: integer); override;}
    class procedure SetItemIndex(const ACustomComboBox: TCustomComboBox; NewIndex: integer); override;
{    class procedure SetMaxLength(const ACustomComboBox: TCustomComboBox; NewLength: integer); override;
    class procedure SetStyle(const ACustomComboBox: TCustomComboBox; NewStyle: TComboBoxStyle); override;
    class procedure SetReadOnly(const ACustomComboBox: TCustomComboBox; NewReadOnly: boolean); override;}

    class function GetItems(const ACustomComboBox: TCustomComboBox): TStrings; override;
//    class procedure Sort(const ACustomComboBox: TCustomComboBox; AList: TStrings; IsSorted: boolean); override;
  end;

  { TFpGuiWSComboBox }

  TFpGuiWSComboBox = class(TWSComboBox)
  private
  protected
  public
  end;

  { TFpGuiWSCustomListBox }

  TFpGuiWSCustomListBox = class(TWSCustomListBox)
  private
  protected
  public
  end;

  { TFpGuiWSListBox }

  TFpGuiWSListBox = class(TWSListBox)
  private
  protected
  public
  end;

  { TFpGuiWSCustomEdit }

  TFpGuiWSCustomEdit = class(TWSCustomEdit)
  private
  protected
  public
    class function CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
  public
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class procedure SetText(const AWinControl: TWinControl; const AText: string); override;
{    class function  GetSelStart(const ACustomEdit: TCustomEdit): integer; override;
    class function  GetSelLength(const ACustomEdit: TCustomEdit): integer; override;

    class procedure SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase); override;
    class procedure SetEchoMode(const ACustomEdit: TCustomEdit; NewMode: TEchoMode); override;
    class procedure SetMaxLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;
    class procedure SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char); override;
    class procedure SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean); override;
    class procedure SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer); override;
    class procedure SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;

    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer); override;}
//    class procedure SetColor(const AWinControl: TWinControl); override;
  end;

  { TFpGuiWSCustomMemo }

  TFpGuiWSCustomMemo = class(TWSCustomMemo)
  private
  protected
  public
  end;

  { TFpGuiWSEdit }

  TFpGuiWSEdit = class(TWSEdit)
  private
  protected
  public
  end;

  { TFpGuiWSMemo }

  TFpGuiWSMemo = class(TWSMemo)
  private
  protected
  public
  end;

  { TFpGuiWSButtonControl }

  TFpGuiWSButtonControl = class(TWSButtonControl)
  private
  protected
  public
  end;

  { TFpGuiWSButton }

  TFpGuiWSButton = class(TWSButton)
  private
  protected
  public
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

  { TFpGuiWSCustomCheckBox }

  TFpGuiWSCustomCheckBox = class(TWSCustomCheckBox)
  private
  protected
  public
    class function  RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState; override;
    class procedure SetShortCut(const ACustomCheckBox: TCustomCheckBox;
      const OldShortCut, NewShortCut: TShortCut); override;
    class procedure SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState); override;
  public
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;

    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;

    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
  end;

  { TFpGuiWSCheckBox }

  TFpGuiWSCheckBox = class(TWSCheckBox)
  private
  protected
  public
  end;

  { TFpGuiWSToggleBox }

  TFpGuiWSToggleBox = class(TWSToggleBox)
  private
  protected
  public
  end;

  { TFpGuiWSRadioButton }

  TFpGuiWSRadioButton = class(TWSRadioButton)
  private
  protected
  public
    class function  RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState; override;
    class procedure SetShortCut(const ACustomCheckBox: TCustomCheckBox;
      const OldShortCut, NewShortCut: TShortCut); override;
    class procedure SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState); override;
  public
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;

    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;

    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
  end;

  { TFpGuiWSCustomStaticText }

  TFpGuiWSCustomStaticText = class(TWSCustomStaticText)
  private
  protected
  public
  end;

  { TFpGuiWSStaticText }

  TFpGuiWSStaticText = class(TWSStaticText)
  private
  protected
  public
  end;


implementation

{ TFpGuiWSCustomComboBox }

{------------------------------------------------------------------------------
  Method: TQtWSCustomComboBox.CreateHandle
  Params:  None
  Returns: Nothing

  Allocates memory and resources for the control and shows it
 ------------------------------------------------------------------------------}
class function TFpGuiWSCustomComboBox.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
begin
  Result := TLCLIntfHandle(TFPGUIPrivateComboBox.Create(AWinControl, AParams));
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomComboBox.DestroyHandle
  Params:  None
  Returns: Nothing

  Releases allocated memory and resources
 ------------------------------------------------------------------------------}
class procedure TFpGuiWSCustomComboBox.DestroyHandle(const AWinControl: TWinControl);
begin
//  TFPGUIPrivateComboBox(AWinControl.Handle).Free;

//  AWinControl.Handle := 0;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomComboBox.GetItemIndex
  Params:  None
  Returns: The state of the control
 ------------------------------------------------------------------------------}
class function TFpGuiWSCustomComboBox.GetItemIndex(
  const ACustomComboBox: TCustomComboBox): integer;
var
  vComboBox: TFComboBox;
begin
  vComboBox := TFPGUIPrivateComboBox(ACustomComboBox.Handle).ComboBox;

  Result := vComboBox.ItemIndex;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomComboBox.SetItemIndex
  Params:  None
  Returns: The state of the control
 ------------------------------------------------------------------------------}
class procedure TFpGuiWSCustomComboBox.SetItemIndex(
  const ACustomComboBox: TCustomComboBox; NewIndex: integer);
var
  vComboBox: TFComboBox;
begin
  vComboBox := TFPGUIPrivateComboBox(ACustomComboBox.Handle).ComboBox;

  vComboBox.ItemIndex := NewIndex;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomComboBox.GetItems
  Params:  None
  Returns: The state of the control
 ------------------------------------------------------------------------------}
class function TFpGuiWSCustomComboBox.GetItems(
  const ACustomComboBox: TCustomComboBox): TStrings;
var
  FComboBox: TFComboBox;
begin
  FComboBox := TFPGUIPrivateComboBox(ACustomComboBox.Handle).ComboBox;

  Result := FComboBox.Items;
end;

{ TFpGuiWSCustomEdit }

{------------------------------------------------------------------------------
  Method: TFpGuiWSCustomEdit.CreateHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TFpGuiWSCustomEdit.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
begin
  Result := TLCLIntfHandle(TFPGUIPrivateEdit.Create(AWinControl, AParams));
end;

{------------------------------------------------------------------------------
  Method: TFpGuiWSCustomEdit.DestroyHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TFpGuiWSCustomEdit.DestroyHandle(const AWinControl: TWinControl);
begin

end;

{------------------------------------------------------------------------------
  Method: TFpGuiWSCustomEdit.GetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TFpGuiWSCustomEdit.GetText(const AWinControl: TWinControl;
  var AText: String): Boolean;
var
  vEdit: TFEdit;
begin
  vEdit := TFPGUIPrivateEdit(AWinControl.Handle).Edit;

  AText := vEdit.Text;
  
  Result := True;
end;

{------------------------------------------------------------------------------
  Method: TFpGuiWSCustomEdit.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TFpGuiWSCustomEdit.SetText(const AWinControl: TWinControl;
  const AText: string);
var
  vEdit: TFEdit;
begin
  vEdit := TFPGUIPrivateEdit(AWinControl.Handle).Edit;

  vEdit.Text := AText;
end;

{ TFpGuiWSButton }

{------------------------------------------------------------------------------
  Method: TFpGuiWSButton.GetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TFpGuiWSButton.GetText(const AWinControl: TWinControl;
  var AText: String): Boolean;
begin
  Result := True;
  AText := TFPGUIPrivateButton(AWinControl.Handle).GetText;
end;

{------------------------------------------------------------------------------
  Method: TFpGuiWSButton.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TFpGuiWSButton.SetText(const AWinControl: TWinControl;
  const AText: String);
begin
  TFPGUIPrivateButton(AWinControl.Handle).SetText(AText);
end;

{------------------------------------------------------------------------------
  Method: TFpGuiWSButton.CreateHandle
  Params:  None
  Returns: Nothing

  Allocates memory and resources for the control and shows it
 ------------------------------------------------------------------------------}
class function TFpGuiWSButton.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
begin
  Result := TLCLIntfHandle(TFPGUIPrivateButton.Create(AWinControl, AParams));
end;

{ TFpGuiWSCustomCheckBox }

class function TFpGuiWSCustomCheckBox.RetrieveState(
  const ACustomCheckBox: TCustomCheckBox): TCheckBoxState;
var
  vCheckBox: TFCheckBox;
begin
  vCheckBox := TFPGUIPrivateCheckBox(ACustomCheckBox.Handle).CheckBox;

  if vCheckBox.Checked then Result := cbChecked
  else Result := cbUnchecked;
end;

class procedure TFpGuiWSCustomCheckBox.SetShortCut(
  const ACustomCheckBox: TCustomCheckBox; const OldShortCut,
  NewShortCut: TShortCut);
begin

end;

class procedure TFpGuiWSCustomCheckBox.SetState(
  const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState);
var
  vCheckBox: TFCheckBox;
begin
  vCheckBox := TFPGUIPrivateCheckBox(ACustomCheckBox.Handle).CheckBox;

  if NewState = cbChecked then vCheckBox.Checked := True
  else vCheckBox.Checked := False;
end;

class function TFpGuiWSCustomCheckBox.GetText(const AWinControl: TWinControl;
  var AText: String): Boolean;
var
  vCheckBox: TFCheckBox;
begin
  Result := False;

  vCheckBox := TFPGUIPrivateCheckBox(AWinControl.Handle).CheckBox;

  AText := vCheckBox.Text;
  
  Result := True;
end;

class procedure TFpGuiWSCustomCheckBox.SetText(const AWinControl: TWinControl;
  const AText: String);
var
  vCheckBox: TFCheckBox;
begin
  vCheckBox := TFPGUIPrivateCheckBox(AWinControl.Handle).CheckBox;

  vCheckBox.Text := AText;
end;

class function TFpGuiWSCustomCheckBox.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams
  ): TLCLIntfHandle;
begin
  Result := TLCLIntfHandle(TFPGUIPrivateCheckBox.Create(AWinControl, AParams));
end;

class procedure TFpGuiWSCustomCheckBox.DestroyHandle(
  const AWinControl: TWinControl);
begin

end;

{ TFpGuiWSRadioButton }

class function TFpGuiWSRadioButton.RetrieveState(
  const ACustomCheckBox: TCustomCheckBox): TCheckBoxState;
var
  vRadioButton: TFRadioButton;
begin
  vRadioButton := TFPGUIPrivateRadioButton(ACustomCheckBox.Handle).RadioButton;

  if vRadioButton.Checked then Result := cbChecked
  else Result := cbUnchecked;
end;

class procedure TFpGuiWSRadioButton.SetShortCut(
  const ACustomCheckBox: TCustomCheckBox; const OldShortCut,
  NewShortCut: TShortCut);
begin

end;

class procedure TFpGuiWSRadioButton.SetState(
  const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState);
var
  vRadioButton: TFRadioButton;
begin
  vRadioButton := TFPGUIPrivateRadioButton(ACustomCheckBox.Handle).RadioButton;

  if NewState = cbChecked then vRadioButton.Checked := True
  else vRadioButton.Checked := False;
end;

class function TFpGuiWSRadioButton.GetText(const AWinControl: TWinControl;
  var AText: String): Boolean;
var
  vRadioButton: TFRadioButton;
begin
  Result := False;

  vRadioButton := TFPGUIPrivateRadioButton(AWinControl.Handle).RadioButton;

  AText := vRadioButton.Text;

  Result := True;
end;

class procedure TFpGuiWSRadioButton.SetText(const AWinControl: TWinControl;
  const AText: String);
var
  vRadioButton: TFRadioButton;
begin
  vRadioButton := TFPGUIPrivateRadioButton(AWinControl.Handle).RadioButton;

  vRadioButton.Text := AText;
end;

class function TFpGuiWSRadioButton.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
begin
  Result := TLCLIntfHandle(TFPGUIPrivateRadioButton.Create(AWinControl, AParams));
end;

class procedure TFpGuiWSRadioButton.DestroyHandle(const AWinControl: TWinControl);
begin

end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TScrollBar, TFpGuiWSScrollBar);
//  RegisterWSComponent(TCustomGroupBox, TFpGuiWSCustomGroupBox);
//  RegisterWSComponent(TGroupBox, TFpGuiWSGroupBox);
  RegisterWSComponent(TCustomComboBox, TFpGuiWSCustomComboBox);
//  RegisterWSComponent(TComboBox, TFpGuiWSComboBox);
//  RegisterWSComponent(TCustomListBox, TFpGuiWSCustomListBox);
//  RegisterWSComponent(TListBox, TFpGuiWSListBox);
  RegisterWSComponent(TCustomEdit, TFpGuiWSCustomEdit);
//  RegisterWSComponent(TCustomMemo, TFpGuiWSCustomMemo);
//  RegisterWSComponent(TEdit, TFpGuiWSEdit);
//  RegisterWSComponent(TMemo, TFpGuiWSMemo);
//  RegisterWSComponent(TCustomLabel, TFpGuiWSCustomLabel);
//  RegisterWSComponent(TLabel, TFpGuiWSLabel);
//  RegisterWSComponent(TButtonControl, TFpGuiWSButtonControl);
  RegisterWSComponent(Buttons.TCustomButton, TFpGuiWSButton);
  RegisterWSComponent(TCustomCheckBox, TFpGuiWSCustomCheckBox);
//  RegisterWSComponent(TCheckBox, TFpGuiWSCheckBox);
//  RegisterWSComponent(TToggleBox, TFpGuiWSToggleBox);
  RegisterWSComponent(TRadioButton, TFpGuiWSRadioButton);
//  RegisterWSComponent(TCustomStaticText, TFpGuiWSCustomStaticText);
//  RegisterWSComponent(TStaticText, TFpGuiWSStaticText);
////////////////////////////////////////////////////
end.
