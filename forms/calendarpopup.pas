{ $Id$}
{
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

  Author: Vincent Snijders

  Abstract:
     Shows a non-modal calendar popup for a TDateEdit
}

unit CalendarPopup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Calendar,
  LCLType;
  
type
  TReturnDateEvent = procedure (Sender: TObject;const Date: TDateTime) of object;

  { TCalendarPopupForm }
  TCalendarPopupForm = class(TForm)
    Calendar: TCalendar;
    procedure CalendarDblClick(Sender: TObject);
    procedure CalendarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDeactivate(Sender: TObject);
  private
    { private declarations }
    FClosed: boolean;
    FOnReturnDate: TReturnDateEvent;
    procedure Initialize(const PopupOrigin: TPoint; ADate: TDateTime);
    procedure ReturnDate;
  public
    { public declarations }
  end;

procedure ShowCalendarPopup(const Position: TPoint; ADate: TDateTime;
                            OnReturnDate: TReturnDateEvent);

implementation

procedure ShowCalendarPopup(const Position: TPoint; ADate: TDateTime;
                            OnReturnDate: TReturnDateEvent);
var
  PopupForm: TCalendarPopupForm;
begin
  PopupForm := TCalendarPopupForm.Create(nil);
  PopupForm.Initialize(Position, ADate);
  PopupForm.FOnReturnDate := OnReturnDate;
  PopupForm.Show;
end;

{ TCalendarPopupForm }

procedure TCalendarPopupForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  FClosed := true;
  CloseAction := caFree;
end;

procedure TCalendarPopupForm.CalendarDblClick(Sender: TObject);
begin
  ReturnDate;
end;

procedure TCalendarPopupForm.CalendarKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Handled: Boolean;
begin
  if Shift=[] then begin
    Handled := true;
    case Key of
    VK_ESCAPE:
      Close;
    VK_RETURN, VK_SPACE:
      ReturnDate;
    else
      Handled := false;
    end;
    if Handled then
      Key := 0;
  end;
end;

procedure TCalendarPopupForm.FormDeactivate(Sender: TObject);
begin
  if not FClosed then
    Close;
end;

procedure TCalendarPopupForm.Initialize(const PopupOrigin: TPoint; ADate: TDateTime);
begin
  Left := PopupOrigin.x;
  Top := PopupOrigin.y;
  Calendar.DateTime := ADate;
end;

procedure TCalendarPopupForm.ReturnDate;
begin
  if assigned(FOnReturnDate) then
    FOnReturnDate(Self, Calendar.DateTime);
  Close;
end;

initialization
  {$I calendarpopup.lrs}

end.

