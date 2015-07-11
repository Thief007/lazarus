{                        ----------------------------------------------
                            GDBMIMiscClasses.pp  -  Debugger helper class
                         ----------------------------------------------

  This unit contains a helper class for decoding GDB output.


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

unit GDBMIMiscClasses;
{$mode objfpc}{$H+}
{$IFDEF linux} {$DEFINE DBG_ENABLE_TERMINAL} {$ENDIF}

interface

uses
  SysUtils,
  {$IFDEF DBG_ENABLE_TERMINAL}
  IDEMiniLibC, BaseUnix, Classes,
  {$ENDIF}
  DebugUtils, DbgIntfDebuggerBase;

type

  TGDBMIResultFlags = set of (
    rfNoMI,        // flag is set if the output is not MI formatted
                   // some MI functions return normal output
                   // some normal functions return MI output
    rfAsyncFailed  //
  );

  TGDBMIExecResult = record
    State: TDBGState;
    Values: String;
    Flags: TGDBMIResultFlags
  end;
const
  GDBMIExecResultDefault: TGDBMIExecResult = (State: dsNone; Values: ''; Flags: []);

type
  PGDBMINameValue = ^TGDBMINameValue;
  TGDBMINameValue = record
    Name: TPCharWithLen;
    Value: TPCharWithLen;
  end;


  { TGDBMINameValueList }

  TGDBMINameValueList = class(TObject)
  private
    FDataLen: Integer;
    FText: String;
    FData: PChar;
    FCount: Integer;
    FIndex: array of TGDBMINameValue;
    FUseTrim: Boolean;

    function Find(const AName : string): PGDBMINameValue;
    function GetItem(const AIndex: Integer): PGDBMINameValue;
    function GetText: String;
    function GetValue(const AName : string): string;
    function GetValuePtr(const AName: string): TPCharWithLen;
  public
    function GetString(const AIndex: Integer): string;
  public
    constructor Create(const AResultValues: String); overload;
    constructor Create(const AResultValues: TPCharWithLen); overload;
    constructor Create(AResult: TGDBMIExecResult); overload;
    constructor Create(const AResultValues: String; const APath: array of String); overload;
    constructor Create(AResult: TGDBMIExecResult; const APath: array of String); overload;
    procedure Delete(AIndex: Integer);
    procedure Init(const AResultValues: String);
    procedure Init(AResultValues: PChar; ALength: Integer);
    procedure Init(const AResultValues: TPCharWithLen);
    procedure SetPath(const APath: String); overload;
    procedure SetPath(const APath: array of String); overload;
    function IndexOf(const AName: string): Integer;
    property Count: Integer read FCount;
    property Items[const AIndex: Integer]: PGDBMINameValue read GetItem;
    property Values[const AName: string]: string read GetValue;
    property ValuesPtr[const AName: string]: TPCharWithLen read GetValuePtr;
    property UseTrim: Boolean read FUseTrim write FUseTrim;
    property Data: PChar read FData;
    property DataLen: Integer read FDataLen;
    property Text: String read GetText;
  end;

  {$IFDEF DBG_ENABLE_TERMINAL}
type

  { TPseudoTerminal }

  TPseudoTerminal = class
  private
    FDeviceName: string;
    FOnCanRead: TNotifyEvent;
    FPTy: Integer;
    FReadBuf: String;
    procedure CloseInp;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Open;
    procedure Close;
    function Write(s: string): Integer;
    function Read: String;
    procedure CheckCanRead;
    property OnCanRead: TNotifyEvent read FOnCanRead write FOnCanRead;
    property Devicename: string read FDeviceName;
  end;
  {$ENDIF}


implementation

{ TGDBMINameValueList }

constructor TGDBMINameValueList.Create(const AResultValues: String);
begin
  inherited Create;
  Init(AResultValues);
end;

constructor TGDBMINameValueList.Create(const AResultValues: TPCharWithLen);
begin
  inherited Create;
  Init(AResultValues);
end;

constructor TGDBMINameValueList.Create(const AResultValues: String; const APath: array of String);
begin
  inherited Create;
  Init(AResultValues);
  SetPath(APath);
end;

constructor TGDBMINameValueList.Create(AResult: TGDBMIExecResult);
begin
  inherited Create;
  Init(AResult.Values);
end;

constructor TGDBMINameValueList.Create(AResult: TGDBMIExecResult; const APath: array of String);
begin
  inherited Create;
  Init(AResult.Values);
  SetPath(APath);
end;

procedure TGDBMINameValueList.Delete(AIndex: Integer);
begin
  if AIndex < 0 then Exit;
  if AIndex >= FCount then Exit;
  Dec(FCount);
  Move(FIndex[AIndex + 1], FIndex[AIndex], SizeOf(FIndex[0]) * (FCount - AIndex));
end;

function TGDBMINameValueList.Find(const AName: string): PGDBMINameValue;
var
  n: Integer;
begin
  n := IndexOf(AName);
  if n < 0 then Exit(nil);
  Result := @FIndex[n];
end;

function TGDBMINameValueList.GetItem(const AIndex: Integer): PGDBMINameValue;
begin
  if AIndex < 0 then Exit(nil);
  if AIndex >= FCount then Exit(nil);
  Result := @FIndex[AIndex];
end;

function TGDBMINameValueList.GetText: String;
begin
  Result := copy(FData, 1, FDataLen);
end;

function TGDBMINameValueList.GetString(const AIndex : Integer) : string;
var
  len: Integer;
  item: PGDBMINameValue;
begin
  Result := '';
  if (AIndex < 0) or (AIndex >= FCount) then Exit;
  item := @FIndex[AIndex];
  if item = nil then Exit;

  len := Item^.Name.Len;
  if Item^.Value.Ptr <> nil then begin
    if (Item^.Value.Ptr-1) = '"' then inc(len, 2);
    len := len + 1 + Item^.Value.Len;
  end;

  SetLength(Result, len);
  if len > 0 then
    Move(Item^.Name.Ptr^, Result[1], len);
end;

function TGDBMINameValueList.GetValue(const AName: string): string;
var
  item: PGDBMINameValue;
begin
  Result := '';
  if FCount = 0 then Exit;
  item := Find(AName);
  if item = nil then Exit;

  SetLength(Result, Item^.Value.Len);
  if Item^.Value.Len > 0 then
    Move(Item^.Value.Ptr^, Result[1], Item^.Value.Len);
end;

function TGDBMINameValueList.GetValuePtr(const AName: string): TPCharWithLen;
var
  item: PGDBMINameValue;
begin
  Result.Ptr := nil;
  Result.Len := 0;
  if FCount = 0 then Exit;
  item := Find(AName);
  if item = nil then Exit;

  Result := item^.Value;
end;

procedure TGDBMINameValueList.Init(AResultValues: PChar; ALength: Integer);

  function FindNextQuote(ACurPtr, AEndPtr: PChar): PChar;
  begin
    Result := ACurPtr;
    while Result <= AEndPtr do
    begin
      case Result^ of
        '\': Inc(Result, 2);
        '"': Break;
      else
        Inc(Result);
      end;
    end;
  end;

  function FindClosingBracket(ACurPtr, AEndPtr: PChar): PChar;
  var
    deep: Integer;
  begin
    deep := 1;
    Result := ACurPtr;

    while Result <= AEndPtr do
    begin
      case Result^ of
        '\': Inc(Result);
        '"': Result := FindNextQuote(Result + 1, AEndPtr);
        '[', '{': Inc(deep);
        ']', '}': begin
          Dec(deep);
          if deep = 0 then break;
        end;
      end;
      Inc(Result);
    end;
  end;

  procedure Add(AStartPtr, AEquPtr, AEndPtr: PChar);
  var
    Item: PGDBMINameValue;
  begin
    if AEndPtr <= AStartPtr then Exit;

    // check space
    if Length(FIndex) <= FCount
    then SetLength(FIndex, FCount + 16);

    Item := @FIndex[FCount];
    if AEquPtr < AStartPtr
    then begin
      // trim spaces
      if UseTrim then
      begin
        while (AStartPtr < AEndPtr) and (AStartPtr^ = #32) do
          inc(AStartPtr);
        while (AEndPtr > AStartPtr) and (AEndPtr^ = #32) do
          dec(AEndPtr);
      end;

      // only name, no value
      Item^.Name.Ptr := AStartPtr;
      Item^.Name.Len := {%H-}PtrUInt(AEndPtr) - {%H-}PtrUInt(AStartPtr) + 1;
      Item^.Value.Ptr := nil;
      Item^.Value.Len := 0;
    end
    else begin
      // trim surrounding spaces
      if UseTrim then
      begin
        while (AStartPtr < AEquPtr) and (AStartPtr^ = #32) do
          inc(AStartPtr);
        while (AEndPtr > AEquPtr) and (AEndPtr^ = #32) do
          dec(AEndPtr);
      end;

      Item^.Name.Ptr := AStartPtr;
      Item^.Name.Len := {%H-}PtrUInt(AEquPtr) - {%H-}PtrUInt(AStartPtr);

      // trim name spaces
      if UseTrim then
        while (Item^.Name.Len > 0) and (Item^.Name.Ptr[Item^.Name.Len - 1] = #32) do
          dec(Item^.Name.Len);

      if (AEquPtr < AEndPtr - 1) and (AEquPtr[1] = '"') and (AEndPtr^ = '"')
      then begin
        // strip surrounding "
        Item^.Value.Ptr := AEquPtr + 2;
        Item^.Value.Len := {%H-}PtrUInt(AEndPtr) - {%H-}PtrUInt(AEquPtr) - 2;
      end
      else begin
        Item^.Value.Ptr := AEquPtr + 1;
        Item^.Value.Len := {%H-}PtrUInt(AEndPtr) - {%H-}PtrUInt(AEquPtr)
      end;
      // trim value spaces
      if UseTrim then
        while (Item^.Value.Len > 0) and (Item^.Value.Ptr[0] = #32) do
        begin
          inc(Item^.Value.Ptr);
          dec(Item^.Value.Len);
        end;
    end;

    Inc(FCount);
  end;

var
  CurPtr, StartPtr, EquPtr, EndPtr: PChar;
begin
  // clear
  FCount := 0;
  FData := AResultValues;
  FDataLen := ALength;

  if AResultValues = nil then Exit;
  if ALength <= 0 then Exit;
  EndPtr := AResultValues + ALength - 1;

  // strip surrounding '[]' OR '{}' first
  case AResultValues^ of
    '[': begin
      if EndPtr^ = ']'
      then begin
        Inc(AResultValues);
        Dec(EndPtr);
      end;
    end;
    '{': begin
      if EndPtr^ = '}'
      then begin
        Inc(AResultValues);
        Dec(EndPtr);
      end;
    end;
  end;

  StartPtr := AResultValues;
  CurPtr := AResultValues;
  EquPtr := nil;
  while CurPtr <= EndPtr do
  begin
    case CurPtr^ of
      '\': Inc(CurPtr); // skip escaped char
      '"': CurPtr := FindNextQuote(CurPtr + 1, EndPtr);
      '[',
      '{': CurPtr := FindClosingBracket(CurPtr + 1, EndPtr);
      '=': EquPtr := CurPtr;
      ',': begin
        Add(StartPtr, EquPtr, CurPtr - 1);
        Inc(CurPtr);
        StartPtr := CurPtr;
        Continue;
      end;
    end;
    Inc(CurPtr);
  end;
  if StartPtr <= EndPtr
  then Add(StartPtr, EquPtr, EndPtr);
end;

procedure TGDBMINameValueList.Init(const AResultValues: TPCharWithLen);
begin
  Init(AResultValues.Ptr, AResultValues.Len)
end;

procedure TGDBMINameValueList.Init(const AResultValues: String);
begin
  FText := AResultValues;
  Init(PChar(FText), Length(FText));
end;

procedure TGDBMINameValueList.SetPath(const APath: String);
begin
  SetPath([APath]);
end;

procedure TGDBMINameValueList.SetPath(const APath: array of String);
var
  i: integer;
  Item: PGDBMINameValue;
begin
  for i := low(APath) to High(APath) do
  begin
    item := Find(APath[i]);
    if item = nil
    then begin
      FCount := 0;
      Exit;
    end;
    Init(Item^.Value);
  end;
end;

function TGDBMINameValueList.IndexOf(const AName: string): Integer;
var
  len: Integer;
begin
  len := Length(AName);
  Result := 0;
  while Result < FCount do begin
    if (FIndex[Result].Name.Len = len)
    and (strlcomp(FIndex[Result].Name.Ptr, PChar(AName), len) = 0)
    then exit;
    inc(Result);
  end;
  Result := -1;
end;

{$IFDEF DBG_ENABLE_TERMINAL}

{ TPseudoTerminal }

procedure TPseudoTerminal.CloseInp;
var
  ios: termios;
begin
  // Based on MSEGui
  if FPTy = InvalHandle then exit;
  tcgetattr(FPty, @ios);
  ios.c_lflag:= (ios.c_lflag and not (icanon)) or echo;
  ios.c_cc[vmin]:= 0;
  ios.c_cc[vtime]:= 0;
  tcsetattr(FPty, tcsanow, @ios);
    //foutput.writeln('');
end;

constructor TPseudoTerminal.Create;
begin
  FPTy := InvalHandle;
end;

destructor TPseudoTerminal.Destroy;
begin
  Close;
  inherited Destroy;
end;

procedure TPseudoTerminal.Close;
begin
  CloseInp;
  if FPTy <> InvalHandle
  then __Close(FPTy);
  FPTy := InvalHandle;
end;

procedure TPseudoTerminal.Open;
const
  BufLen = 100;
var
  ios: termios;
  int1: integer;

  procedure Error;
  begin
    if FPTy <> InvalHandle
    then __Close(FPTy);
    FPTy := InvalHandle;
    FDeviceName := '';
  end;

begin
  Close;
  FPTy := getpt;
  if FPTy < 0 then Error;
  if (grantpt(FPTy) < 0) or (unlockpt(FPTy) < 0) then begin
    Error;
    exit;
  end;
  setlength(FDeviceName, BufLen);
  if ptsname_r(FPTy, @FDeviceName[1], BufLen) < 0 then begin
    Error;
    exit;
  end;
  setlength(FDeviceName,length(pchar(FDeviceName)));
  if tcgetattr(FPTy, @ios) <> 0 then begin
    Error;
    exit;
  end;
  ios.c_lflag:= ios.c_lflag and not (icanon); // or echo);
  ios.c_cc[vmin]:= 1;
  ios.c_cc[vtime]:= 0;
  if tcsetattr(FPTy, tcsanow, @ios) <> 0 then begin
    Error;
    exit;
  end;

  int1 := fcntl(FPTy, f_getfl, 0);
  if int1 = InvalHandle then begin
    Error;
    exit;
  end;
  if fcntl(FPTy, f_setfl, int1 or o_nonblock) = InvalHandle then Error;
end;

function TPseudoTerminal.Write(s: string): Integer;
var
  int1, nbytes: Integer;
  p: PChar;
begin
  nbytes := length(s);
  if (FPTy = InvalHandle) or (nbytes = 0) then exit(0);
  Result:= nbytes;
  p := @s[1];
  repeat
    int1 := __write(FPTy, p^, nbytes);
    if int1 = -1 then begin
      if errno <> eintr then begin
        Result:= int1;
        break;
      end;
      continue;
    end;
    inc(p, int1);
    dec(nbytes, int1);
  until integer(nbytes) <= 0;
end;

function TPseudoTerminal.Read: String;
const
  BufLen = 1024;
var
  buf: String;
  i: Integer;
begin
  if (FPTy = InvalHandle) then exit('');

  SetLength(buf, BufLen + 1);
  Result := FReadBuf;
  FReadBuf := '';
  repeat
    i := __read(FPTy, buf[1], BufLen);
    if i > 0 then Result := Result + copy(buf, 1, i);
  until i <= 0;
end;

procedure TPseudoTerminal.CheckCanRead;
begin
  FReadBuf := Read;
  if (FReadBuf <> '') and assigned(FOnCanRead)
  then FOnCanRead(self);
end;

{$ENDIF}

end.

