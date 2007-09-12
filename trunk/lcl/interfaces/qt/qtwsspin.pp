{ $Id$}
{
 *****************************************************************************
 *                                QtWSSpin.pp                                * 
 *                                -----------                                * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
}
unit QtWSSpin;

{$mode objfpc}{$H+}

interface

uses
  // Bindings
{$ifdef USE_QT_4_3}
  qt43,
{$else}
  qt4,
{$endif}
  qtwidgets,
  // LCL
  Spin, SysUtils, Controls, Classes, LCLType, LCLProc, LCLIntf, Forms, StdCtrls,
  // Widgetset
  WSSpin, WSLCLClasses;

type

  { TQtWSCustomFloatSpinEdit }

  TQtWSCustomFloatSpinEdit = class(TWSCustomFloatSpinEdit)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure UpdateControl(const ACustomFloatSpinEdit: TCustomFloatSpinEdit); override;

    class function  GetSelStart(const ACustomEdit: TCustomEdit): integer; override;
    class function  GetSelLength(const ACustomEdit: TCustomEdit): integer; override;
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class function  GetValue(const ACustomFloatSpinEdit: TCustomFloatSpinEdit): single; override;

    class procedure SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase); override;
    class procedure SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean); override;
    class procedure SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;
    class procedure SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: string); override;

  (*TODO: seperation into properties instead of bulk update
    class procedure SetIncrement(const ACustomFloatSpinEdit: TCustomFloatSpinEdit; NewIncrement: single); virtual;
    class procedure SetMinValue(const ACustomFloatSpinEdit: TCustomFloatSpinEdit; NewValue: single); virtual;
    class procedure SetMaxValue(const ACustomFloatSpinEdit: TCustomFloatSpinEdit; NewValue: single); virtual;
    class procedure SetValueEmpty(const ACustomFloatSpinEdit: TCustomFloatSpinEdit; NewEmpty: boolean); virtual;
    *)

  end;

  { TQtWSFloatSpinEdit }

  TQtWSFloatSpinEdit = class(TWSFloatSpinEdit)
  private
  protected
  public
  end;


implementation

{ TQtWSCustomFloatSpinEdit }

{------------------------------------------------------------------------------
  Method: TQtWSCustomFloatSpinEdit.CreateHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomFloatSpinEdit.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  QtSpinBox: TQtAbstractSpinBox;
begin
  // qt4 has two different QSpinBoxes, one is QSpinBox (integer), another is QDoubleSpinBox (double)

  if TCustomFloatSpinEdit(AWinControl).DecimalPlaces > 0 then
    QtSpinBox := TQtFloatSpinBox.Create(AWinControl, AParams)
  else
    QtSpinBox := TQtSpinBox.Create(AWinControl, AParams);
  
  QtSpinBox.AttachEvents;
  Result := THandle(QtSpinBox);
end;

class function  TQtWSCustomFloatSpinEdit.GetValue(const ACustomFloatSpinEdit: TCustomFloatSpinEdit): single;
begin
  Result := TQtAbstractSpinBox(ACustomFloatSpinEdit.Handle).getValue;
end;

class procedure TQtWSCustomFloatSpinEdit.SetCharCase(
  const ACustomEdit: TCustomEdit; NewCase: TEditCharCase);
begin
  {$note implement}
end;

class procedure TQtWSCustomFloatSpinEdit.UpdateControl(const ACustomFloatSpinEdit: TCustomFloatSpinEdit);
var
  QtSpinEdit: TQtSpinBox;
  QtFloatSpinEdit: TQtFloatSpinBox;
begin
  if ACustomFloatSpinEdit.DecimalPlaces > 0 then
  begin
    QtFloatSpinEdit := TQtFloatSpinBox(ACustomFloatSpinEdit.Handle);
    QDoubleSpinBox_setDecimals(QDoubleSpinBoxH(QtFloatSpinEdit.Widget), ACustomFloatSpinEdit.DecimalPlaces);
    QtFloatSpinEdit.setValue(ACustomFloatSpinEdit.Value);
    QDoubleSpinBox_setMinimum(QDoubleSpinBoxH(QtFloatSpinEdit.Widget), ACustomFloatSpinEdit.MinValue);
    QDoubleSpinBox_setMaximum(QDoubleSpinBoxH(QtFloatSpinEdit.Widget), ACustomFloatSpinEdit.MaxValue);
    QDoubleSpinBox_setSingleStep(QDoubleSpinBoxH(QtFloatSpinEdit.Widget), ACustomFloatSpinEdit.Increment);
  end
  else
  begin
    QtSpinEdit := TQtSpinBox(ACustomFloatSpinEdit.Handle);
    QtSpinEdit.setValue(Round(ACustomFloatSpinEdit.Value));
    QSpinBox_setMinimum(QSpinBoxH(QtSpinEdit.Widget), Round(ACustomFloatSpinEdit.MinValue));
    QSpinBox_setMaximum(QSpinBoxH(QtSpinEdit.Widget), Round(ACustomFloatSpinEdit.MaxValue));
    QSpinBox_setSingleStep(QSpinBoxH(QtSpinEdit.Widget), Round(ACustomFloatSpinEdit.Increment));
  end;
end;

class function TQtWSCustomFloatSpinEdit.GetSelStart(
  const ACustomEdit: TCustomEdit): integer;
begin
  {$note implement}
  Result := 0;
end;

class function TQtWSCustomFloatSpinEdit.GetSelLength(
  const ACustomEdit: TCustomEdit): integer;
begin
  {$note implement}
  Result := 0;
end;

class function  TQtWSCustomFloatSpinEdit.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
begin
  {$note implement}
  Result := True;
end;

class procedure TQtWSCustomFloatSpinEdit.SetText(const AWinControl: TWinControl; const AText: string);
begin
  // perhaps QSpinBox_setSuffix() goes here one day (if we get LCL support)
  {$note implement}
end;

class procedure TQtWSCustomFloatSpinEdit.SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean);
begin
  TQtAbstractSpinBox(ACustomEdit.Handle).setReadOnly(NewReadOnly);
end;

class procedure TQtWSCustomFloatSpinEdit.SetSelLength(
  const ACustomEdit: TCustomEdit; NewLength: integer);
begin
  {$note implement}
end;

class procedure TQtWSCustomFloatSpinEdit.SetSelStart(
  const ACustomEdit: TCustomEdit; NewStart: integer);
begin
  {$note implement}
end;


initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCustomFloatSpinEdit, TQtWSCustomFloatSpinEdit);
//  RegisterWSComponent(TFloatSpinEdit, TQtWSFloatSpinEdit);
////////////////////////////////////////////////////
end.
