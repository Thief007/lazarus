{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is SettingsStream.pas, released October 2001.
The Initial Developer of the Original Code is Anthony Steele. 
Portions created by Anthony Steele are Copyright (C) 1999-2008 Anthony Steele.
All Rights Reserved.
Contributor(s): Anthony Steele.                  

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"). you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/NPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied.
See the License for the specific language governing rights and limitations 
under the License.

Alternatively, the contents of this file may be used under the terms of
the GNU General Public License Version 2 or later (the "GPL") 
See http://www.gnu.org/licenses/gpl.html
------------------------------------------------------------------------------*)
{*)}

unit SettingsStream;

{
  AFS 5 October 2001
  fns used in writing settings to a stream
  And yes, this was influenced by the fact
  that I have been recently working with Java io classes
}

{$I JcfGlobal.inc}

interface

uses
  { delphi }
  Classes;

type

  // abstract base class - interface
  TSettingsOutput = class(TObject)
  private
  public
    procedure WriteXMLHeader; virtual;

    procedure OpenSection(const psName: string); virtual;
    procedure CloseSection(const psName: string); virtual;

    procedure Write(const psTagName, psValue: string); overload; virtual;
    procedure Write(const psTagName: string; const piValue: integer); overload; virtual;
    procedure Write(const psTagName: string; const pbValue: boolean); overload; virtual;
    procedure Write(const psTagName: string; const pdValue: double); overload; virtual;
    procedure Write(const psTagName: string; const pcValue: TStrings); overload; virtual;
  end;


  // sublcass that wraps a stream (eg a file).
  TSettingsStreamOutput = class(TSettingsOutput)
  private
    fcStream: TStream;
    fbOwnStream: boolean;
    fiOpenSections: integer;

    procedure WriteText(const psText: string);
  public

    constructor Create(const psFileName: string); overload;
    constructor Create(const pcStream: TStream); overload;

    destructor Destroy; override;

    procedure WriteXMLHeader; override;

    procedure OpenSection(const psName: string); override;
    procedure CloseSection(const psName: string); override;

    procedure Write(const psTagName, psValue: string); override;
    procedure Write(const psTagName: string; const piValue: integer); override;
    procedure Write(const psTagName: string; const pbValue: boolean); override;
    procedure Write(const psTagName: string; const pdValue: double); override;
    procedure Write(const psTagName: string; const pcValue: TStrings); override;
  end;


  { settings reading interface }
  TSettingsInput = class(TObject)
  public
    function ExtractSection(const psSection: string): TSettingsInput; virtual;

    function HasTag(const psTag: string): boolean; virtual;

    function Read(const psTag: string): string; overload; virtual;
    function Read(const psTag, psDefault: string): string; overload; virtual;
    function Read(const psTag: string; const piDefault: integer): integer;
      overload; virtual;
    function Read(const psTag: string; const pfDefault: double): double;
      overload; virtual;
    function Read(const psTag: string; const pbDefault: boolean): boolean;
      overload; virtual;
    function Read(const psTag: string; const pcStrings: TStrings): boolean;
      overload; virtual;

  end;

  { object to read settings from a string }
  TSettingsInputString = class(TSettingsInput)
  private
    fsText: string;

    procedure InternalGetValue(const psTag: string; var psResult: string;
      var pbFound: boolean);

    //function RestrictToSection(const psSection: string): boolean;

  public

    constructor Create(const psText: string);
    destructor Destroy; override;

    function ExtractSection(const psSection: string): TSettingsInput; override;

    function HasTag(const psTag: string): boolean; override;

    function Read(const psTag: string): string; override;
    function Read(const psTag, psDefault: string): string; override;
    function Read(const psTag: string; const piDefault: integer): integer; override;
    function Read(const psTag: string; const pfDefault: double): double; override;
    function Read(const psTag: string; const pbDefault: boolean): boolean; override;
    function Read(const psTag: string; const pcStrings: TStrings): boolean; override;


    property Text: string Read fsText;
  end;


  { dummy impl that always returns the default }
  TSettingsInputDummy = class(TSettingsInput)
  private
  public
    function ExtractSection(const psSection: string): TSettingsInput; override;
    function HasTag(const psTag: string): boolean; override;

    function Read(const psTag, psDefault: string): string; override;
    function Read(const psTag: string; const piDefault: integer): integer; override;
    function Read(const psTag: string; const pbDefault: boolean): boolean; override;
    function Read(const psTag: string; const pcStrings: TStrings): boolean; override;
  end;

implementation

uses
  { delphi }
  SysUtils, Windows,
  { jcl }
  JclStrings, JclAnsiStrings, JclSysUtils,
  { local}
  JcfMiscFunctions;

const
  XML_HEADER = '<?xml version="1.0" ?>' + AnsiLineBreak;

procedure TSettingsOutput.WriteXMLHeader;
begin
  Assert(False, 'TSettingsOutput.WriteXMLHeader must be overridden in class ' + ClassName);
end;


procedure TSettingsOutput.OpenSection(const psName: string);
begin
  Assert(False, 'TSettingsOutput.OpenSection must be overridden in class ' + ClassName);
end;

procedure TSettingsOutput.CloseSection(const psName: string);
begin
  Assert(False, 'TSettingsOutput.CloseSection must be overridden in class ' + ClassName);
end;

procedure TSettingsOutput.Write(const psTagName, psValue: string);
begin
  Assert(False, 'TSettingsOutput.Write (string) must be overridden in class ' +
    ClassName);
end;

procedure TSettingsOutput.Write(const psTagName: string; const piValue: integer);
begin
  Assert(False, 'TSettingsOutput.Write (int) must be overridden in class ' + ClassName);
end;

procedure TSettingsOutput.Write(const psTagName: string; const pbValue: boolean);
begin
  Assert(False, 'TSettingsOutput.Write (boolean) must be overridden in class ' +
    ClassName);
end;

procedure TSettingsOutput.Write(const psTagName: string; const pdValue: double);
begin
  Assert(False, 'TSettingsOutput.Write (double) must be overridden in class ' +
    ClassName);
end;

procedure TSettingsOutput.Write(const psTagName: string; const pcValue: TStrings);
begin
  Assert(False, 'TSettingsOutput.Write (TStrings) must be overridden in class ' +
    ClassName);
end;

{--------------------}
constructor TSettingsStreamOutput.Create(const psFileName: string);
begin
  inherited Create();

  fcStream    := TFileStream.Create(psFileName, fmCreate);
  fbOwnStream := True;
  fiOpenSections := 0;
end;

constructor TSettingsStreamOutput.Create(const pcStream: TStream);
begin
  inherited Create();
  fcStream    := pcStream;
  fbOwnStream := False;
  fiOpenSections := 0;
end;


destructor TSettingsStreamOutput.Destroy;
begin
  if fbOwnStream then
    fcStream.Free;

  fcStream := nil;

  inherited;
end;

// internal used to implement all writes
procedure TSettingsStreamOutput.WriteText(const psText: string);
var
  lp: pchar;
begin
  Assert(fcStream <> nil);
  lp := pchar(psText);
  //fcStream.WriteBuffer(lp^, Length(psText)); // Changed for Delphi 2009 support
  fcStream.WriteBuffer(lp^, Length(psText) * SizeOf(Char));
end;

procedure TSettingsStreamOutput.WriteXMLHeader;
begin
  WriteText(XML_HEADER);
end;

procedure TSettingsStreamOutput.OpenSection(const psName: string);
begin
  WriteText(JclStrings.StrRepeat('  ', fiOpenSections) + '<' + psName + '>' + AnsiLineBreak);
  Inc(fiOpenSections);
end;

procedure TSettingsStreamOutput.CloseSection(const psName: string);
begin
  Dec(fiOpenSections);
  WriteText(JclStrings.StrRepeat('  ', fiOpenSections) + '</' + psName + '>' + AnsiLineBreak);
end;


procedure TSettingsStreamOutput.Write(const psTagName, psValue: string);
var
  lsTemp: string;
begin
  Assert(fcStream <> nil);
  lsTemp := JclStrings.StrRepeat('  ', fiOpenSections + 1) + '<' + psTagName + '> ' +
    psValue + ' </' + psTagName + '>' + AnsiLineBreak;
  WriteText(lsTemp);
end;

procedure TSettingsStreamOutput.Write(const psTagName: string; const piValue: integer);
begin
  Write(psTagName, IntToStr(piValue));
end;

procedure TSettingsStreamOutput.Write(const psTagName: string; const pbValue: boolean);
begin
  Write(psTagName, BooleanToStr(pbValue));
end;


// this also works for TDateTime
procedure TSettingsStreamOutput.Write(const psTagName: string; const pdValue: double);
begin
  Write(psTagName, Float2Str(pdValue));
end;

procedure TSettingsStreamOutput.Write(const psTagName: string; const pcValue: TStrings);
var
  ls: string;
begin
  ls := JclStrings.StringsToStr(pcValue, ', ');
  Write(psTagName, ls);
end;

{-----------------------------------------------------------------------------
  SettingsInput}

function TSettingsInput.ExtractSection(const psSection: string): TSettingsInput;
begin
  Assert(False, 'TSettingsInput.ExtractSection must be overridden in class ' +
    ClassName);
  Result := nil;
end;

function TSettingsInput.HasTag(const psTag: string): boolean;
begin
  Assert(False, 'TSettingsInput.HasTag must be overridden in class ' + ClassName);
  Result := False;
end;

function TSettingsInput.Read(const psTag: string): string;
begin
  Assert(False, 'TSettingsInput.GetValue(string) must be overridden in class ' +
    ClassName);
  Result := '';
end;

function TSettingsInput.Read(const psTag, psDefault: string): string;
begin
  Assert(False, 'TSettingsInput.GetValue(string) must be overridden in class ' +
    ClassName);
  Result := '';
end;

function TSettingsInput.Read(const psTag: string; const piDefault: integer): integer;
begin
  Assert(False, 'TSettingsInput.GetValue(integer) must be overridden in class ' +
    ClassName);
  Result := 0;
end;

function TSettingsInput.Read(const psTag: string; const pfDefault: double): double;
begin
  Assert(False, 'TSettingsInput.GetValue(double) must be overridden in class ' +
    ClassName);
  Result := 0.0;
end;

function TSettingsInput.Read(const psTag: string; const pbDefault: boolean): boolean;
begin
  Assert(False, 'TSettingsInput.GetValue(boolean) must be overridden in class ' +
    ClassName);
  Result := False;
end;

function TSettingsInput.Read(const psTag: string; const pcStrings: TStrings): boolean;
begin
  Assert(False, 'TSettingsInput.GetValue(TStrings) must be overridden in class ' +
    ClassName);
  Result := False;
end;


{-----------------------------------------------------------------------------
  SettingsInputString }


constructor TSettingsInputString.Create(const psText: string);
begin
  inherited Create;
  fsText := psText;
end;

destructor TSettingsInputString.Destroy;
begin
  inherited;
end;

procedure TSettingsInputString.InternalGetValue(const psTag: string;
  var psResult: string; var pbFound: boolean);
var
  liStart, liEnd: integer;
  lsStart, lsEnd: string;
begin
  lsStart := '<' + psTag + '>';
  lsEnd   := '</' + psTag + '>';

  liStart := JclStrings.StrFind(lsStart, fsText, 1);
  liEnd   := JclStrings.StrFind(lsEnd, fsText, 1);

  if (liStart > 0) and (liEnd > liStart) then
  begin
    liStart  := liStart + Length(lsStart);
    psResult := Copy(fsText, liStart, (liEnd - liStart));
    psResult := Trim(psResult);
    pbFound  := True;
  end
  else
  begin
    psResult := '';
    pbFound  := False;
  end;
end;

{
function TSettingsInputString.RestrictToSection(const psSection: string): boolean;
var
  lsNewText: string;
begin
  InternalGetValue(psSection, lsNewText, Result);
  if Result then
    fsText := lsNewText;
end;
}

function TSettingsInputString.ExtractSection(const psSection: string): TSettingsInput;
var
  lsNewText: string;
  lbFound:   boolean;
begin
  InternalGetValue(psSection, lsNewText, lbFound);
  if lbFound then
    Result := TSettingsInputString.Create(lsNewText)
  else
    Result := nil;
end;

function TSettingsInputString.Read(const psTag: string): string;
var
  lbFound: boolean;
begin
  InternalGetValue(psTag, Result, lbFound);
end;

function TSettingsInputString.Read(const psTag, psDefault: string): string;
var
  lbFound: boolean;
begin
  InternalGetValue(psTag, Result, lbFound);
  if not lbFound then
    Result := psDefault;
end;

function TSettingsInputString.Read(const psTag: string;
  const piDefault: integer): integer;
var
  lbFound:   boolean;
  lsNewText: string;
begin
  try
    InternalGetValue(psTag, lsNewText, lbFound);
    if lbFound and (lsNewText <> '') then
    begin
      // cope with some old data
      if AnsiSameText(lsNewText, 'true') then
        Result := 1
      else if AnsiSameText(lsNewText, 'false') then
        Result := 0
      else
        Result := StrToInt(lsNewText);
    end
    else
      Result := piDefault;
  except
    on E: Exception do
      raise Exception.Create('Could not read integer setting' + AnsiLineBreak +
        'name: ' + psTag + AnsiLineBreak +
        'value: ' + lsNewText + AnsiLineBreak + E.Message);
  end;

end;

function TSettingsInputString.Read(const psTag: string; const pfDefault: double): double;
var
  lbFound:   boolean;
  lsNewText: string;
begin
  try
    InternalGetValue(psTag, lsNewText, lbFound);
    if lbFound then
      Result := Str2Float(lsNewText)
    else
      Result := pfDefault;
  except
    on E: Exception do
      raise Exception.Create('Could not read float setting' + AnsiLineBreak +
        'name: ' + psTag + AnsiLineBreak +
        'value: ' + lsNewText + AnsiLineBreak + E.Message);
  end;
end;

function TSettingsInputString.Read(const psTag: string;
  const pbDefault: boolean): boolean;
var
  lbFound:   boolean;
  lsNewText: string;
begin
  try
    InternalGetValue(psTag, lsNewText, lbFound);
    if lbFound then
      Result := StrToBoolean(lsNewText)
    else
      Result := pbDefault;
  except
    on E: Exception do
      raise Exception.Create('Could not read boolean setting' + AnsiLineBreak +
        'name: ' + psTag + AnsiLineBreak +
        'value: ' + lsNewText + AnsiLineBreak + E.Message);
  end;

end;

function TSettingsInputString.Read(const psTag: string;
  const pcStrings: TStrings): boolean;
var
  lbFound:   boolean;
  lsNewText: string;
begin
  Assert(pcStrings <> nil);
  InternalGetValue(psTag, lsNewText, lbFound);
  if lbFound then
  begin
    JclStrings.StrToStrings(lsNewText, ',', pcStrings);
    TrimStrings(pcStrings);
  end;

  Result := lbFound;
end;


function TSettingsInputString.HasTag(const psTag: string): boolean;
var
  lsDummy: string;
begin
  InternalGetValue(psTag, lsDummy, Result);
end;


{ TSettingsInputDummy }

function TSettingsInputDummy.Read(const psTag: string;
  const piDefault: integer): integer;
begin
  Result := piDefault;
end;

function TSettingsInputDummy.Read(const psTag, psDefault: string): string;
begin
  Result := psDefault;
end;

function TSettingsInputDummy.ExtractSection(const psSection: string): TSettingsInput;
begin
  Result := TSettingsInputDummy.Create;
end;

function TSettingsInputDummy.HasTag(const psTag: string): boolean;
begin
  Result := True;
end;

function TSettingsInputDummy.Read(const psTag: string;
  const pbDefault: boolean): boolean;
begin
  Result := pbDefault;
end;

function TSettingsInputDummy.Read(const psTag: string;
  const pcStrings: TStrings): boolean;
begin
  Result := True;
end;

end.
