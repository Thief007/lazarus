{ $Id$ }
{                   -------------------------------------------
                     dbgutils.pp  -  Debugger utility routines
                    -------------------------------------------

 @created(Sun Apr 28st WET 2002)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.net>)

 This unit contains a collection of debugger support routines.

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
unit DBGUtils;

{$mode objfpc}{$H+}

interface 

uses
  Classes;

type
  TDelayedUdateItem = class(TCollectionItem)
  private
    FUpdateCount: Integer;
    FDoChanged: Boolean;
  protected
    procedure Changed;
    procedure DoChanged; virtual;
  public
    procedure Assign(ASource: TPersistent); override;
    procedure BeginUpdate;
    constructor Create(ACollection: TCollection); override;
    procedure EndUpdate;
  end;
  
function GetLine(var ABuffer: String): String;
function StripLN(const ALine: String): String;
function GetPart(const ASkipTo, AnEnd: String; var ASource: String): String; overload;
function GetPart(const ASkipTo, AnEnd: String; var ASource: String; const AnIgnoreCase: Boolean): String; overload;
function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String): String; overload;
function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String; const AnIgnoreCase: Boolean): String; overload;
function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String; const AnIgnoreCase, AnUpdateSource: Boolean): String; overload;
function ConvertToCString(const AText: String): String;
function DeleteEscapeChars(const AText: String; const AEscapeChar: Char): String;

const
{$IFDEF WIN32}
  LINE_END = #13#10;
{$ELSE}
  LINE_END = #10;
{$ENDIF}

implementation

uses
  SysUtils;

function GetLine(var ABuffer: String): String;
var
  idx: Integer;
begin
  idx := Pos(#10, ABuffer);
  if idx = 0
  then Result := ''
  else begin
    Result := Copy(ABuffer, 1, idx);
    Delete(ABuffer, 1, idx);
  end;
end;

function StripLN(const ALine: String): String;
var
  idx: Integer;
begin
  idx := Pos(#10, ALine);
  if idx = 0
  then begin
    idx := Pos(#13, ALine);
    if idx = 0
    then begin
      Result := ALine;
      Exit;
    end;
  end
  else begin
    if (idx > 1)
    and (ALine[idx - 1] = #13)
    then Dec(idx);
  end;
  Result := Copy(ALine, 1, idx - 1);
end;           

function GetPart(const ASkipTo, AnEnd: String; var ASource: String): String;
begin
  Result := GetPart([ASkipTo], [AnEnd], ASource, False, True);
end;

function GetPart(const ASkipTo, AnEnd: String; var ASource: String; const AnIgnoreCase: Boolean): String; overload;
begin
  Result := GetPart([ASkipTo], [AnEnd], ASource, AnIgnoreCase, True);
end;

function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String): String; overload;
begin
  Result := GetPart(ASkipTo, AnEnd, ASource, False, True);
end;

function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String; const AnIgnoreCase: Boolean): String; overload;
begin
  Result := GetPart(ASkipTo, AnEnd, ASource, AnIgnoreCase, True);
end;

function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String; const AnIgnoreCase, AnUpdateSource: Boolean): String; overload;
var
  n, i, idx: Integer;
  S, Source, Match: String;
  HasEscape: Boolean;
begin                  
  Source := ASource;

  if High(ASkipTo) >= 0
  then begin
    idx := 0;
    HasEscape := False;
    if AnIgnoreCase
    then S := UpperCase(Source)
    else S := Source;
    for n := Low(ASkipTo) to High(ASkipTo) do
    begin
      if ASkipTo[n] = ''
      then begin
        HasEscape := True;
        Continue;
      end;
      if AnIgnoreCase
      then i := Pos(UpperCase(ASkipTo[n]), S)
      else i := Pos(ASkipTo[n], S);
      if i > idx
      then begin
        idx := i;
        Match := ASkipTo[n];
      end;
    end;
    if (idx = 0) and not HasEscape
    then begin
      Result := '';
      Exit;
    end;
    if idx > 0
    then Delete(Source, 1, idx + Length(Match) - 1);
  end;
  
  if AnIgnoreCase
  then S := UpperCase(Source)
  else S := Source;
  idx := MaxInt;
  for n := Low(AnEnd) to High(AnEnd) do
  begin
    if AnEnd[n] = '' then Continue;
    if AnIgnoreCase
    then i := Pos(UpperCase(AnEnd[n]), S)
    else i := Pos(AnEnd[n], S);
    if (i > 0) and (i < idx) then idx := i;
  end;

  if idx = MaxInt
  then begin
    Result := Source;
    Source := '';
  end
  else begin
    Result := Copy(Source, 1, idx - 1);
    Delete(Source, 1, idx - 1);
  end;
  
  if AnUpdateSource
  then ASource := Source;
end;

function ConvertToCString(const AText: String): String;
var
  n: Integer;
begin
  Result := AText;
  n := 1;
  while n <= Length(Result) do
  begin
    case Result[n] of
      '''': begin
        if (n < Length(Result))
        and (Result[n + 1] = '''')
        then Delete(Result, n, 1)
        else Result[n] := '"';
      end;
      '"': begin
        Insert('"', Result, n);
        Inc(n);
      end;
    end;
    Inc(n);
  end;
end;

function DeleteEscapeChars(const AText: String; const AEscapeChar: Char): String;
var
  i: Integer;
  l: Integer;
  Escape: Boolean;
begin
  Result:=AText;
  Escape := False;
  i:=1;
  l:=length(Result);
  while i<l do begin
    Escape := not Escape and (Result[i]=AEscapeChar);
    if Escape then
      System.Delete(Result,i,1);
    inc(i);
  end;
end;

{ TDelayedUdateItem }

procedure TDelayedUdateItem.Assign(ASource: TPersistent);
begin
  BeginUpdate;
  try
    inherited Assign(ASource);
  finally
    EndUpdate;
  end;
end;

procedure TDelayedUdateItem.BeginUpdate;
begin
  Inc(FUpdateCount);
  if FUpdateCount = 1 then FDoChanged := False;
end;

procedure TDelayedUdateItem.Changed;
begin
  if FUpdateCount > 0
  then FDoChanged := True
  else DoChanged;
end;

constructor TDelayedUdateItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FUpdateCount := 0;
end;

procedure TDelayedUdateItem.DoChanged;
begin
  inherited Changed(False);
end;

procedure TDelayedUdateItem.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount < 0 then raise EInvalidOperation.Create('TDelayedUdateItem.EndUpdate');
  if (FUpdateCount = 0) and FDoChanged
  then begin
    DoChanged;
    FDoChanged := False;
  end;
end;

end.
{ =============================================================================
  $Log$
  Revision 1.8  2003/07/09 00:13:18  marc
  * fixed cached items.object storage if TCheckListBox
  * Changed DebuggerOptions dialog to use new TCheckListBox

  Revision 1.7  2003/06/13 19:21:31  marc
  MWE: + Added initial signal and exception handling

  Revision 1.6  2003/06/10 23:48:26  marc
  MWE: * Enabled modification of breakpoints while running

  Revision 1.5  2003/06/09 15:58:05  mattias
  implemented view call stack key and jumping to last stack frame with debug info

  Revision 1.4  2003/05/29 17:40:10  marc
  MWE: * Fixed string resolving
       * Updated exception handling

  Revision 1.3  2003/05/22 23:08:19  marc
  MWE: = Moved and renamed debuggerforms so that they can be
         modified by the ide
       + Added some parsing to evaluate complex expressions
         not understood by the debugger

  Revision 1.2  2002/05/10 06:57:47  lazarus
  MG: updated licenses

  Revision 1.1  2002/04/30 15:57:39  lazarus
  MWE:
    + Added callstack object and dialog
    + Added checks to see if debugger = nil
    + Added dbgutils

}
