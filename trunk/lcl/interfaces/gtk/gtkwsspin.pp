{ $Id$}
{
 *****************************************************************************
 *                               GtkWSSpin.pp                                * 
 *                               ------------                                * 
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
unit GtkWSSpin;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF gtk2}
  glib2, gdk2pixbuf, gdk2, gtk2, Pango,
  {$ELSE}
  glib, gdk, gtk,
  {$ENDIF}
  LCLProc, Spin, GtkProc, gtkExtra, GtkWSStdCtrls, WSSpin, WSLCLClasses, LCLType;

type

  { TGtkWSCustomFloatSpinEdit }

  TGtkWSCustomFloatSpinEdit = class(TWSCustomFloatSpinEdit)
  private
  protected
  public
    class function  GetSelStart(const ACustomFloatSpinEdit: TCustomFloatSpinEdit): integer; override;
    class function  GetSelLength(const ACustomFloatSpinEdit: TCustomFloatSpinEdit): integer; override;
    class function  GetValue(const ACustomFloatSpinEdit: TCustomFloatSpinEdit): single; override;

    class procedure SetSelStart(const ACustomFloatSpinEdit: TCustomFloatSpinEdit; NewStart: integer); override;
    class procedure SetSelLength(const ACustomFloatSpinEdit: TCustomFloatSpinEdit; NewLength: integer); override;

    class procedure UpdateControl(const ACustomFloatSpinEdit: TCustomFloatSpinEdit); override;
  end;

function GetGtkSpinEntry(Spin: PGtkSpinButton): PGtkEntry;
function GetSpinGtkEntry(Spin: TCustomFloatSpinEdit): PGtkEntry;
function GetGtkFloatSpinEditable(Spin: PGtkSpinButton): PGtkOldEditable;
function GetSpinGtkEditable(Spin: TCustomFloatSpinEdit): PGtkOldEditable;

implementation

function GetGtkSpinEntry(Spin: PGtkSpinButton): PGtkEntry;
begin
  Result:=PGtkEntry(@(Spin^.entry));
end;

function GetSpinGtkEntry(Spin: TCustomFloatSpinEdit): PGtkEntry;
begin
  Result:=GetGtkSpinEntry(PGtkSpinButton(Spin.Handle));
end;

function GetGtkFloatSpinEditable(Spin: PGtkSpinButton): PGtkOldEditable;
begin
  Result:=PGtkOldEditable(@(Spin^.entry));
end;

function GetSpinGtkEditable(Spin: TCustomFloatSpinEdit): PGtkOldEditable;
begin
  Result:=GetGtkFloatSpinEditable(PGtkSpinButton(Spin.Handle));
end;

{ TGtkWSCustomFloatSpinEdit }

//const
//  GtkValueEmpty: array[boolean] of integer = (0,1);

class function TGtkWSCustomFloatSpinEdit.GetSelStart(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit
  ): integer;
begin
  Result :=
           WidgetGetSelStart(PGtkWidget(GetSpinGtkEntry(ACustomFloatSpinEdit)));
end;

class function TGtkWSCustomFloatSpinEdit.GetSelLength(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit): integer;
begin
  with GetSpinGtkEditable(ACustomFloatSpinEdit)^ do
    Result := Abs(integer(selection_end_pos)-integer(selection_start_pos));
end;

class function TGtkWSCustomFloatSpinEdit.GetValue(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit): single;
begin
  Result:=gtk_spin_button_get_value_as_float(
                                   PGtkSpinButton(ACustomFloatSpinEdit.Handle));
end;

class procedure TGtkWSCustomFloatSpinEdit.SetSelStart(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit; NewStart: integer);
begin
  gtk_editable_set_position(GetSpinGtkEditable(ACustomFloatSpinEdit), NewStart);
end;

class procedure TGtkWSCustomFloatSpinEdit.SetSelLength(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit; NewLength: integer);
begin
  WidgetSetSelLength(PGtkWidget(GetSpinGtkEntry(ACustomFloatSpinEdit)),
                     NewLength);
end;

class procedure TGtkWSCustomFloatSpinEdit.UpdateControl(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit);
var
  AnAdjustment: PGtkAdjustment;
  wHandle: HWND;
  SpinWidget: PGtkSpinButton;
begin
  //DebugLn(['TGtkWSCustomFloatSpinEdit.UpdateControl ',dbgsName(ACustomFloatSpinEdit)]);
  wHandle := ACustomFloatSpinEdit.Handle;
  SpinWidget:=GTK_SPIN_BUTTON(Pointer(wHandle));
  AnAdjustment:=gtk_spin_button_get_adjustment(SpinWidget);
  if (AnAdjustment^.lower<>ACustomFloatSpinEdit.MinValue)
  or (AnAdjustment^.upper<>ACustomFloatSpinEdit.MaxValue) then
  begin
    AnAdjustment^.lower:=ACustomFloatSpinEdit.MinValue;
    AnAdjustment^.upper:=ACustomFloatSpinEdit.MaxValue;
    gtk_adjustment_changed(AnAdjustment);
  end;
  gtk_spin_button_set_digits(SpinWidget, ACustomFloatSpinEdit.DecimalPlaces);
  gtk_spin_button_set_value(SpinWidget,ACustomFloatSpinEdit.Value);
  AnAdjustment^.step_increment := ACustomFloatSpinEdit.Increment;
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCustomFloatSpinEdit, TGtkWSCustomFloatSpinEdit);
//  RegisterWSComponent(TFloatSpinEdit, TGtkWSFloatSpinEdit);
////////////////////////////////////////////////////
end.
