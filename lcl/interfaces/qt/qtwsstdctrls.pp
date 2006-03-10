{ $Id$}
{
 *****************************************************************************
 *                              QtWSStdCtrls.pp                              * 
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
unit QtWSStdCtrls;

{$mode delphi}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Classes, StdCtrls, Controls, Graphics, Forms, SysUtils,
  InterfaceBase, qt4, qtprivate,
////////////////////////////////////////////////////
  WSStdCtrls, WSLCLClasses, LCLType;

type

  { TQtWSScrollBar }

  TQtWSScrollBar = class(TWSScrollBar)
  private
  protected
  public
  end;

  { TQtWSCustomGroupBox }

  TQtWSCustomGroupBox = class(TWSCustomGroupBox)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
  end;

  { TQtWSGroupBox }

  TQtWSGroupBox = class(TWSGroupBox)
  private
  protected
  public
  end;

  { TQtWSCustomComboBox }

  TQtWSCustomComboBox = class(TWSCustomComboBox)
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

  { TQtWSComboBox }

  TQtWSComboBox = class(TWSComboBox)
  private
  protected
  public
  end;

  { TQtWSCustomListBox }

  TQtWSCustomListBox = class(TWSCustomListBox)
  private
  protected
  public
  end;

  { TQtWSListBox }

  TQtWSListBox = class(TWSListBox)
  private
  protected
  public
  end;

  { TQtWSCustomEdit }

  TQtWSCustomEdit = class(TWSCustomEdit)
  private
  protected
  public
    class function CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
  public
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
  end;

  { TQtWSCustomMemo }

  TQtWSCustomMemo = class(TWSCustomMemo)
  private
  protected
  public
    class function CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
  public
//    class procedure AppendText(const ACustomMemo: TCustomMemo; const AText: string); virtual;
//    class function  GetStrings(const ACustomMemo: TCustomMemo): TStrings; virtual;
//    class procedure SetScrollbars(const ACustomMemo: TCustomMemo; const NewScrollbars: TScrollStyle); virtual;
//    class procedure SetWordWrap(const ACustomMemo: TCustomMemo; const NewWordWrap: boolean); virtual;
  public
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
  end;

  { TQtWSEdit }

  TQtWSEdit = class(TWSEdit)
  private
  protected
  public
  end;

  { TQtWSMemo }

  TQtWSMemo = class(TWSMemo)
  private
  protected
  public
  end;

  { TQtWSButtonControl }

  TQtWSButtonControl = class(TWSButtonControl)
  private
  protected
  public
  end;

  { TQtWSCustomCheckBox }

  TQtWSCustomCheckBox = class(TWSCustomCheckBox)
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

  { TQtWSCheckBox }

  TQtWSCheckBox = class(TWSCheckBox)
  private
  protected
  public
  end;

  { TQtWSToggleBox }

  TQtWSToggleBox = class(TWSToggleBox)
  private
  protected
  public
  end;

  { TQtWSRadioButton }

  TQtWSRadioButton = class(TWSRadioButton)
  private
    class procedure SetSlots(const QtRadioButton: TQtRadioButton);
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

  { TQtWSCustomStaticText }

  TQtWSCustomStaticText = class(TWSCustomStaticText)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class procedure SetAlignment(const ACustomStaticText: TCustomStaticText; const NewAlignment: TAlignment); override;

    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; virtual;

    class procedure SetText(const AWinControl: TWinControl; const AText: String); virtual;
  end;

  { TQtWSStaticText }

  TQtWSStaticText = class(TWSStaticText)
  private
  protected
  public
  end;


implementation

{ TQtWSCustomMemo }

{------------------------------------------------------------------------------
  Method: TQtWSCustomMemo.CreateHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomMemo.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  QtTextEdit: TQtTextEdit;
begin
  QtTextEdit := TQtTextEdit.Create(AWinControl, AParams);

  Result := THandle(QtTextEdit);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomMemo.DestroyHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomMemo.DestroyHandle(const AWinControl: TWinControl);
begin
  TQtTextEdit(AWinControl.Handle).Free;
end;

{ TQtWSCustomEdit }

{------------------------------------------------------------------------------
  Method: TQtWSCustomEdit.CreateHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomEdit.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  QtLineEdit: TQtLineEdit;
begin
  QtLineEdit := TQtLineEdit.Create(AWinControl, AParams);

  Result := THandle(QtLineEdit);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomEdit.DestroyHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomEdit.DestroyHandle(const AWinControl: TWinControl);
begin
  TQtLineEdit(AWinControl.Handle).Free;
end;

{ TQtWSStaticText }

{------------------------------------------------------------------------------
  Method: TQtWSCustomStaticText.CreateHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomStaticText.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  QtStaticText: TQtStaticText;
begin
  QtStaticText := TQtStaticText.Create(AWinControl, AParams);

//  SetSlots(QtStaticText);

  QWidget_show(QtStaticText.Widget);

  Result := THandle(QtStaticText);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomStaticText.DestroyHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomStaticText.DestroyHandle(const AWinControl: TWinControl);
begin
  TQtStaticText(AWinControl.Handle).Free;

  AWinControl.Handle := 0;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomStaticText.SetAlignment
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomStaticText.SetAlignment(
  const ACustomStaticText: TCustomStaticText; const NewAlignment: TAlignment);
begin
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomStaticText.GetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomStaticText.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
var
  Str: WideString;
begin
  TQtStaticText(AWinControl.Handle).Text(@Str);

  AText := string(Str);

  Result := True;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomStaticText.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomStaticText.SetText(const AWinControl: TWinControl; const AText: String);
var
  Str: WideString;
begin
  Str := WideString(AText);

  TQtStaticText(AWinControl.Handle).SetText(@Str);
end;

{ TQtWSCustomCheckBox }

class function TQtWSCustomCheckBox.RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState;
begin
  case TQtCheckBox(ACustomCheckBox.Handle).CheckState of
   QtPartiallyChecked: Result := cbGrayed;
   QtChecked: Result := cbChecked;
  else
    Result := cbUnchecked;
  end;
end;

class procedure TQtWSCustomCheckBox.SetShortCut(const ACustomCheckBox: TCustomCheckBox;
  const OldShortCut, NewShortCut: TShortCut);
begin
  inherited SetShortCut(ACustomCheckBox, OldShortCut, NewShortCut);
end;

class procedure TQtWSCustomCheckBox.SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState);
begin
  case NewState of
   cbGrayed: TQtCheckBox(ACustomCheckBox.Handle).setCheckState(QtPartiallyChecked);
   cbChecked: TQtCheckBox(ACustomCheckBox.Handle).setCheckState(QtChecked);
  else
    TQtCheckBox(ACustomCheckBox.Handle).setCheckState(QtUnchecked);
  end;
end;

class function TQtWSCustomCheckBox.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
var
  Str: WideString;
begin
  TQtAbstractButton(AWinControl.Handle).Text(@Str);

  AText := string(Str);

  Result := True;
end;

class procedure TQtWSCustomCheckBox.SetText(const AWinControl: TWinControl; const AText: String);
var
  Str: WideString;
begin
  Str := WideString(AText);

  TQtAbstractButton(AWinControl.Handle).SetText(@Str);
end;

class function TQtWSCustomCheckBox.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  QtCheckBox: TQtCheckBox;
begin
  QtCheckBox := TQtCheckBox.Create(AWinControl, AParams);

//  SetSlots(QtStaticText);

  QWidget_show(QtCheckBox.Widget);

  QWidget_setFocusPolicy(QtCheckBox.Widget, QtStrongFocus);

  Result := THandle(QtCheckBox);
end;

class procedure TQtWSCustomCheckBox.DestroyHandle(const AWinControl: TWinControl);
begin
  TQtCheckBox(AWinControl.Handle).Free;

  AWinControl.Handle := 0;
end;

{ TQtWSRadioButton }

{------------------------------------------------------------------------------
  Method: TQtWSRadioButton.SetSlots
  Params:  None
  Returns: Nothing

  Initializes the events
 ------------------------------------------------------------------------------}
class procedure TQtWSRadioButton.SetSlots(const QtRadioButton: TQtRadioButton);
var
  Method: TMethod;
  Hook : QObject_hookH;
begin
  // Various Events

  Hook := QObject_hook_create(QtRadioButton.Widget);

  TEventFilterMethod(Method) := QtRadioButton.EventFilter;

  QObject_hook_hook_events(Hook, Method);
end;

{------------------------------------------------------------------------------
  Method: TQtWSRadioButton.RetrieveState
  Params:  None
  Returns: The state of the control
 ------------------------------------------------------------------------------}
class function TQtWSRadioButton.RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState;
begin
  if TQtAbstractButton(ACustomCheckBox.Handle).isChecked then Result := cbChecked
  else Result := cbUnchecked;
end;

{------------------------------------------------------------------------------
  Method: TQtWSRadioButton.SetShortCut
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSRadioButton.SetShortCut(const ACustomCheckBox: TCustomCheckBox;
  const OldShortCut, NewShortCut: TShortCut);
begin
  inherited SetShortCut(ACustomCheckBox, OldShortCut, NewShortCut);
end;

{------------------------------------------------------------------------------
  Method: TQtWSRadioButton.SetState
  Params:  None
  Returns: Nothing

  Sets the state of the control
 ------------------------------------------------------------------------------}
class procedure TQtWSRadioButton.SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState);
begin
  case NewState of
   cbUnchecked: TQtAbstractButton(ACustomCheckBox.Handle).setChecked(False);
   cbChecked: TQtAbstractButton(ACustomCheckBox.Handle).setChecked(true);
  end;
end;

{------------------------------------------------------------------------------
  Method: TQtWSRadioButton.GetText
  Params:  None
  Returns: The text of the control
 ------------------------------------------------------------------------------}
class function TQtWSRadioButton.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
var
  Str: WideString;
begin
  TQtAbstractButton(AWinControl.Handle).Text(@Str);

  AText := string(Str);

  Result := True;
end;

{------------------------------------------------------------------------------
  Method: TQtWSRadioButton.SetText
  Params:  None
  Returns: Nothing

  Changes the text of the control
 ------------------------------------------------------------------------------}
class procedure TQtWSRadioButton.SetText(const AWinControl: TWinControl; const AText: String);
var
  Str: WideString;
begin
  Str := WideString(AText);

  TQtAbstractButton(AWinControl.Handle).SetText(@Str);
end;

{------------------------------------------------------------------------------
  Method: TQtWSRadioButton.CreateHandle
  Params:  None
  Returns: Nothing

  Allocates memory and resources for the control and shows it
 ------------------------------------------------------------------------------}
class function TQtWSRadioButton.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  QtRadioButton: TQtRadioButton;
begin
  QtRadioButton := TQtRadioButton.Create(AWinControl, AParams);

  SetSlots(QtRadioButton);

  QWidget_show(QtRadioButton.Widget);

  Result := THandle(QtRadioButton);
end;

{------------------------------------------------------------------------------
  Method: TQtWSRadioButton.DestroyHandle
  Params:  None
  Returns: Nothing

  Releases allocated memory and resources
 ------------------------------------------------------------------------------}
class procedure TQtWSRadioButton.DestroyHandle(const AWinControl: TWinControl);
begin
  TQtRadioButton(AWinControl.Handle).Free;

  AWinControl.Handle := 0;
end;

{ TQtWSCustomGroupBox }

{------------------------------------------------------------------------------
  Method: TQtWSCustomCheckGroup.CreateHandle
  Params:  None
  Returns: Nothing

  Allocates memory and resources for the control and shows it
 ------------------------------------------------------------------------------}
class function TQtWSCustomGroupBox.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  QtGroupBox: TQtGroupBox;
  Str: WideString;
begin
  QtGroupBox := TQtGroupBox.Create(AWinControl, AParams);

//  SetSlots(QtButtonGroup);

  QWidget_show(QtGroupBox.Widget);

  Result := THandle(QtGroupBox);
  
  Str := WideString(AWinControl.Caption);
  QGroupBox_setTitle(QGroupBoxH(QtGroupBox.Widget), @Str);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomCheckGroup.DestroyHandle
  Params:  None
  Returns: Nothing

  Releases allocated memory and resources
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomGroupBox.DestroyHandle(const AWinControl: TWinControl);
begin
  TQtGroupBox(AWinControl.Handle).Free;

  AWinControl.Handle := 0;
end;

{ TQtWSCustomComboBox }

class function TQtWSCustomComboBox.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  QtComboBox: TQtComboBox;
  Str: WideString;
begin
  QtComboBox := TQtComboBox.Create(AWinControl, AParams);

//  SetSlots(QtButtonGroup);

//  QWidget_show(QtGroupBox.Widget);

  Result := THandle(QtComboBox);

//  Str := WideString(AWinControl.Caption);
end;

class procedure TQtWSCustomComboBox.DestroyHandle(const AWinControl: TWinControl);
begin
  TQtComboBox(AWinControl.Handle).Free;

  AWinControl.Handle := 0;
end;

class function TQtWSCustomComboBox.GetItemIndex(
  const ACustomComboBox: TCustomComboBox): integer;
begin
  Result := TQtComboBox(ACustomComboBox.Handle).currentIndex;
end;

class procedure TQtWSCustomComboBox.SetItemIndex(
  const ACustomComboBox: TCustomComboBox; NewIndex: integer);
begin
  TQtComboBox(ACustomComboBox.Handle).setCurrentIndex(NewIndex);
end;

class function TQtWSCustomComboBox.GetItems(
  const ACustomComboBox: TCustomComboBox): TStrings;
begin
  Result := TStringList.Create;
  
  Result.Text := ACustomComboBox.Items.Text;
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TScrollBar, TQtWSScrollBar);
  RegisterWSComponent(TCustomGroupBox, TQtWSCustomGroupBox);
//  RegisterWSComponent(TGroupBox, TQtWSGroupBox);
  RegisterWSComponent(TCustomComboBox, TQtWSCustomComboBox);
//  RegisterWSComponent(TComboBox, TQtWSComboBox);
//  RegisterWSComponent(TCustomListBox, TQtWSCustomListBox);
//  RegisterWSComponent(TListBox, TQtWSListBox);
  RegisterWSComponent(TCustomEdit, TQtWSCustomEdit);
  RegisterWSComponent(TCustomMemo, TQtWSCustomMemo);
//  RegisterWSComponent(TEdit, TQtWSEdit);
//  RegisterWSComponent(TMemo, TQtWSMemo);
//  RegisterWSComponent(TCustomLabel, TQtWSCustomLabel);
//  RegisterWSComponent(TLabel, TQtWSLabel);
//  RegisterWSComponent(TButtonControl, TQtWSButtonControl);
  RegisterWSComponent(TCustomCheckBox, TQtWSCustomCheckBox);
//  RegisterWSComponent(TCheckBox, TQtWSCheckBox);
//  RegisterWSComponent(TCheckBox, TQtWSCheckBox);
//  RegisterWSComponent(TToggleBox, TQtWSToggleBox);
  RegisterWSComponent(TRadioButton, TQtWSRadioButton);
  RegisterWSComponent(TCustomStaticText, TQtWSCustomStaticText);
//  RegisterWSComponent(TStaticText, TQtWSStaticText);
////////////////////////////////////////////////////
end.
