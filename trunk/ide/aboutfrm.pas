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
}
unit AboutFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LResources, StdCtrls,
  Buttons, LazConf, LazarusIDEStrConsts;

type
  TAboutForm = class(TForm)
    Label2: TLABEL;
    Memo1: TMEMO;
    Button1: TBUTTON;
    Label1: TLABEL;
    procedure AboutFormResize(Sender: TObject);
  private
    { private declarations }
    FPixmap : TPixmap;
  public
    { public declarations }
    procedure Paint; override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end; 


function ShowAboutForm: TModalResult;
  

implementation


function ShowAboutForm: TModalResult;
var
  AboutForm: TAboutForm;
begin
  AboutForm:=TAboutForm.Create(Application);
  Result:=AboutForm.ShowModal;
  AboutForm.Free;
end;

{ TAboutForm }

constructor TAboutForm.Create(AOwner: TComponent);
  {The compiler generated date string is always of the form y/m/d.
   This function gives it a string respresentation according to the
   shortdateformat}
  function GetLocalizedBuildDate(): string;
  var
    BuildDate: string;
    SlashPos1, SlashPos2: integer;
    Date: TDate;
  begin
    BuildDate := {$I %date%};
    SlashPos1 := Pos('/',BuildDate);
    SlashPos2 := SlashPos1 +
      Pos('/', Copy(BuildDate, SlashPos1+1, Length(BuildDate)-SlashPos1));
    Date := EncodeDate(StrToInt(Copy(BuildDate,1,SlashPos1-1)),
      StrToInt(Copy(BuildDate,SlashPos1+1,SlashPos2-SlashPos1-1)),
      StrToInt(Copy(BuildDate,SlashPos2+1,Length(BuildDate)-SlashPos2)));
    Result := DateTimeToStr(Date);
  end;
begin
  inherited Create(AOwner);

  FPixmap := TPixmap.Create;
  FPixmap.LoadFromLazarusResource('lazarus_about_logo');
  Label1.Caption := lisVersion+' #: '+lisLazarusVersionString;
  Label2.Caption := lisDate+': '+GetLocalizedBuildDate;
  
  Memo1.Lines.Text:=Format(lisAboutLazarusMsg,[LineEnding,LineEnding,LineEnding]);
  Button1.Caption:=lisClose;

  OnResize:=@AboutFormResize;
end;


destructor TAboutForm.Destroy;
begin
  FPixmap.Free;
  FPixmap:=nil;

  inherited Destroy;
end;

procedure TAboutForm.AboutFormResize(Sender: TObject);
begin
  with Memo1 do begin
    Left:=225;
    Top:=10;
    Width:=Self.ClientWidth-Left-Top;
    Height:=Self.ClientHeight-2*Top;
  end;
end;

procedure TAboutForm.Paint;
begin
  inherited Paint;
  if FPixmap <>nil
  then Canvas.Copyrect(Bounds(12, 44, Width, Height)
    ,FPixmap.Canvas, Rect(0,0, Width, Height));
end;



initialization
  {$I aboutfrm.lrs}
  {$I lazarus_about_logo.lrs}

end.

