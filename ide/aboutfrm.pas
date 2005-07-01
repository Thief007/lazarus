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
  Classes, SysUtils, FPCAdds, Forms, Controls, Graphics, Dialogs, LResources,
  StdCtrls, Buttons, LazConf, LazarusIDEStrConsts, ExtCtrls, EnvironmentOpts;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    Button1: TBitBtn;
    Label2: TLABEL;
    AboutMemo: TMEMO;
    Label1: TLABEL;
    ContributorsMemo:TMemo;
    Notebook1:TNotebook;
    AboutPage:TPage;
    ContributorsPage:TPage;
    procedure AboutFormCreate(Sender:TObject);
  private
    FPixmap : TPixmap;
    procedure LoadContributors;
  public
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
  AboutForm:=TAboutForm.Create(nil);
  Result:=AboutForm.ShowModal;
  AboutForm.Free;
end;

{ TAboutForm }

constructor TAboutForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;


destructor TAboutForm.Destroy;
begin
  FPixmap.Free;
  FPixmap:=nil;

  inherited Destroy;
end;

procedure TAboutForm.AboutFormCreate(Sender:TObject);
  {The compiler generated date string is always of the form y/m/d.
   This function gives it a string respresentation according to the
   shortdateformat}
  function GetLocalizedBuildDate(): string;
  var
    BuildDate: string;
    SlashPos1, SlashPos2: integer;
    Date: TDateTime;
  begin
    BuildDate := {$I %date%};
    SlashPos1 := Pos('/',BuildDate);
    SlashPos2 := SlashPos1 +
      Pos('/', Copy(BuildDate, SlashPos1+1, Length(BuildDate)-SlashPos1));
    Date := EncodeDate(StrToWord(Copy(BuildDate,1,SlashPos1-1)),
      StrToWord(Copy(BuildDate,SlashPos1+1,SlashPos2-SlashPos1-1)),
      StrToWord(Copy(BuildDate,SlashPos2+1,Length(BuildDate)-SlashPos2)));
    Result := DateTimeToStr(Date);
  end;
begin
  FPixmap := TPixmap.Create;
  FPixmap.LoadFromLazarusResource('lazarus_about_logo');
  Caption:=lisAboutLazarus;
  Label1.Caption := lisVersion+' #: '+lisLazarusVersionString;
  Label2.Caption := lisDate+': '+GetLocalizedBuildDate;
  AboutPage.Caption:=lisMenuTemplateAbout;
  ContributorsPage.Caption:=lisContributors;
  Constraints.MinWidth:= 600;
  Constraints.MinHeight:= 300;

  AboutMemo.Lines.Text:=Format(lisAboutLazarusMsg,[LineEnding,LineEnding,LineEnding])
    +LineEnding+LineEnding
    +'Official: http://sourceforge.net/projects/lazarus/'+LineEnding
    +'Tutorials: http://lazarus-ccr.sourceforge.net'+LineEnding
    ;
  LoadContributors;
  Button1.Caption:=lisClose;
end;

procedure TAboutForm.LoadContributors;
var
  ContributorsFileName: string;
begin
  ContributorsFileName:=
    EnvironmentOptions.LazarusDirectory+'docs'+PathDelim+'Contributors.txt';
  if FileExists(ContributorsFileName) then
    ContributorsMemo.Lines.LoadFromFile(ContributorsFileName)
  else
    ContributorsMemo.Text:=lisAboutNoContributors;
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

