unit DefaultTranslator;
{ Copyright (C) 2004 V.I.Volchenko and Lazarus Developers Team

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}
{This unit is needed for using translated form strings made by Lazarus IDE.
It seeks for localized .mo file in some common places. If you want to find
.mo file anywhere else, don't use this unit but initialize LRSMoFile variable
from LResources in your project by yourself. If you need standard translation,
just use this unit in your project.
As translation works only with 'patched' classes unit, you must install it, then
rebuild lazarus with -dTRANSLATESTRING. If don't, this unit
(and any such translation) will be completely useless}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, GetText, Controls, typinfo;
{$IFDEF TRANSLATESTRING}
type
 TDefaultTranslator=class(TAbstractTranslator)
 private
  FMOFile:TMOFile;
 public
  constructor Create(MOFileName:string);
  destructor Destroy;override;
  procedure TranslateStringProperty(Sender:TObject; const Instance: TPersistent; PropInfo: PPropInfo; var Content:string);override;
 end;
{$ENDIF}
implementation
uses Menus;

function FindLocaleFileName:string;
var LANG,lng:string;
  i: Integer;
begin
 LANG:=GetEnvironmentVariable('LANG');
 if LANG='' then begin
   for i:=1 to Paramcount-1 do
    if (paramstr(i)='--LANG') or
     (paramstr(i)='-l') or
     (paramstr(i)='--lang') then LANG:=ParamStr(i+1);
 end;
 if LANG<>'' then begin
  //paramstr(0) is said not to work properly in linux, but I've tested it
  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+LANG+
    DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;

  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'languages'+DirectorySeparator+LANG+
    DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;

  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'locale'+DirectorySeparator
    +LANG+DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;

  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'locale'+DirectorySeparator
    +LANG+DirectorySeparator+'LC_MESSAGES'+DirectorySeparator+
    ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;

  {$IFDEF UNIX}
  //In unix-like systems we can try to search for global locale
  Result:='/usr/share/locale/'+LANG+'/LC_MESSAGES/'
   +ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;
  {$ENDIF}
  //Let us search for reducted files
  lng:=copy(LANG,1,2);
  //At first, check all was checked
  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+lng+
    DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;

  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'languages'+DirectorySeparator+lng+
    DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;

  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'locale'+DirectorySeparator
    +lng+DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;

  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'locale'+DirectorySeparator
    +LANG+DirectorySeparator+'LC_MESSAGES'+DirectorySeparator+
    ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;

  //Full language in file name - this will be default for the project
  //We need more carefull handling, as it MAY result in incorrect filename
  try
    Result:=ExtractFilePath(paramstr(0))+ChangeFileExt(ExtractFileName(paramstr(0)),'.'+LANG)+'.mo';
    if FileExists(Result) then exit;
   //Common location (like in Lazarus)
    Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'locale'+DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.'+LANG)+'.mo';
    if FileExists(Result) then exit;

    Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'languages'+DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.'+LANG)+'.mo';
    if FileExists(Result) then exit;
  except
    Result:='';//Or do something else (useless)
  end;
  {$IFDEF UNIX}
  Result:='/usr/share/locale/'+lng+'/LC_MESSAGES/'
   +ChangeFileExt(ExtractFileName(paramstr(0)),'.mo');
  if FileExists(Result) then exit;
  {$ENDIF}
  Result:=ExtractFilePath(paramstr(0))+ChangeFileExt(ExtractFileName(paramstr(0)),'.'+lng)+'.mo';
  if FileExists(Result) then exit;

  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'locale'+DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.'+lng)+'.mo';
  if FileExists(Result) then exit;

  Result:=ExtractFilePath(paramstr(0))+DirectorySeparator+'languages'+DirectorySeparator+ChangeFileExt(ExtractFileName(paramstr(0)),'.'+lng)+'.mo';
  if FileExists(Result) then exit;
 end;
 Result:=ChangeFileExt(paramstr(0),'.mo');
 if FileExists(Result) then exit;

 Result:='';
end;
var lcfn:string;
{$IFNDEF TRANSLATESTRING}
{$WARNING TranslateString is not enabled. Nothing to translate}
{$ELSE}

{ TDefaultTranslator }

constructor TDefaultTranslator.Create(MOFileName: string);
begin
  inherited Create;
  FMOFile:=TMOFile.Create(MOFileName);
end;

destructor TDefaultTranslator.Destroy;
begin
  FMOFile.Free;
//If someone will use this class incorrectly, it can be destroyed
//before Reader destroying. It is a very bad thing, but in THIS situation
//in this case is impossible. May be, in future we can overcome this difficulty
  inherited Destroy;
end;

procedure TDefaultTranslator.TranslateStringProperty(Sender: TObject;
  const Instance: TPersistent; PropInfo: PPropInfo; var Content: string);
var
  s: String;
  s1: String;
begin
  if not Assigned(FMOFile) then exit;
  if not Assigned(PropInfo) then exit;
{DO we really need this?}
  if Instance is TComponent then
   if csDesigning in (Instance as TComponent).ComponentState then exit;
{End DO :)}
  if (AnsiUpperCase(PropInfo^.PropType^.Name)<>'TTRANSLATESTRING')and
   not (Instance is TMenuItem)
   then exit;
  s:=AnsiUpperCase(Instance.ClassName+'.'+PropInfo^.Name)+'=';
  s1:=s+Content;
  s1:=FMOFile.Translate(s1);
  if (copy(s1,1,length(s))=s)and(s1<>s+Content) then
  begin
    Content:=copy(s1,length(s)+1,length(s1)-length(s));
    exit;
  end;
  s:=AnsiUpperCase(PropInfo^.Name)+'=';
  s1:=s+Content;
  s1:=FMOFile.Translate(s1);
  if (copy(s1,1,length(s))=s)and(s1<>s+Content) then
  begin
    Content:=copy(s1,length(s)+1,length(s1)-length(s));
    exit;
  end;
  s1:=FMOFile.Translate(Content);
  if s1<>'' then Content:=s1;
  //TODO:another types of translation
end;
{$ENDIF}
initialization
//It is safe to place code here as no form is initialized before unit
//initialization made
//We are to search for all
  try
    lcfn:=FindLocaleFileName;
  except
    lcfn:='';
  end;
  {$IFDEF TRANSLATESTRING}
  if lcfn<>'' then
  begin
    TranslateResourceStrings(lcfn);
    LRSTranslator:=TDefaultTranslator.Create(lcfn);
  end;
  {$ENDIF}
finalization
end.
{
$Log$
Revision 1.1  2004/12/27 12:56:42  mattias
started TTranslateStrings and .lrt files support  from Vasily

Revision 1.1 2004/10/17 13:49 VVI
added <project_name>.<full language>.mo file search
}
{
No revision (not in LOG)
 2004/10/09 Sent as is to Lazarus Team - VVI
}

