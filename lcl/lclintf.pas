{  $Id$  }
{
 /***************************************************************************
                                LCLIntf.pas
                                -----------
                             Component Library Windows Controls
                   Initial Revision  : Fri Jul 23 20:00:00 PDT 1999


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

{
@author(Curtis White <cwhite@aracnet.com>)
@created(17-Oct-1999)

This unit is being created specifically for compatibility with Delphi. It
contains selected functions that are included in the Delphi Windows unit.
These functions are mostly abstract and implemented by the LCL interfaces.

For LCL users:
The functions can be used to make porting of Delphi applications easier
and are not 100% emulating winapi functions, not even under windows. They were
implemented and tested with some common Delphi libraries.
The LCL contains many extra functions that the Delphi VCL does not have.
For example:
Instead of using the common windows functions SaveDC and RestoreDC use instead
the Canvas.SaveHandleState and Canvas.RestoreHandleState.
}

unit LCLIntf;

{$mode objfpc}{$H+}
{$inline on}

interface

uses
  {$IFDEF Windows}Windows, {$ifndef ver2_2_0}ShellApi, {$ENDIF}{$ENDIF}
  {$IFDEF Darwin}MacOSAll, {$ENDIF}
  Types, Math, Classes, SysUtils, LCLType, LCLProc, GraphType, InterfaceBase,
  LResources, FileUtil, UTF8Process, Maps, LMessages;

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}
{$DEFINE ClientRectBugFix}

// All winapi related stuff (Delphi compatible)
{$I winapih.inc}
// All interface communication (Our additions)
{$I lclintfh.inc}

function PredefinedClipboardFormat(
  AFormat: TPredefinedClipboardFormat): TClipboardFormat;


function MsgKeyDataToShiftState(KeyData: Longint): TShiftState;


{$IFDEF WINDOWS}

{$IFDEF MSWindows}
function GetTickCount:DWORD; stdcall; external 'kernel32.dll' name 'GetTickCount';
{$ELSE}
function GetTickCount:DWORD; stdcall; external KernelDLL name 'GetTickCount';
{$ENDIF}

{$ELSE}
function GetTickCount: DWord;
{$ENDIF}

{$IFDEF DebugLCL}
function GetTickStep: DWord;
{$ENDIF}

function FindDefaultBrowser(out ABrowser, AParams: String): Boolean;
function OpenURL(AURL: String): Boolean;
function OpenDocument(APath: String): Boolean;

implementation

type
  { TTimerID }

  TTimerID = class
    procedure TimerNotify;
  end;

  PTimerInfo = ^TTimerInfo;
  TTimerInfo = record
    Wnd: HWND;
    IDEvent: UINT_PTR;
    TimerProc: TTimerProc;
    Handle: THandle;
  end;

var
  MTimerMap: TMap = nil;   // hWnd + nIDEvent -> ID
  MTimerInfo: TMap = nil;  // ID -> TTimerInfo
  MTimerSeq: Cardinal;

  FPredefinedClipboardFormats:
    array[TPredefinedClipboardFormat] of TClipboardFormat;
  LowerCaseChars: array[char] of char;
  UpperCaseChars: array[char] of char;


  { TTimerMap }

procedure TTimerID.TimerNotify;
var
  Info: PTimerInfo;
  ID: Cardinal;
begin
  if MTimerInfo = nil then Exit;

  // this is a bit of a hack.
  // to pass the ID if the timer, it is passed as an cast to self
  // So there isn't realy an instance of TTimerID
  ID := PtrUInt(Self);
  Info := MTimerInfo.GetDataPtr(ID);
  if Info = nil then Exit;

  if Info^.TimerProc = nil
  then begin
    // send message
    PostMessage(Info^.Wnd, LM_TIMER, Info^.IDEvent, 0);
  end
  else begin
    // a timerproc was passed
    Info^.TimerProc(Info^.Wnd, LM_TIMER, Info^.IDEvent, GetTickCount);
  end;
end;


{$IFNDEF WINDOWS}
function GetTickCount: DWord;
begin
  Result := DWord(Trunc(Now * 24 * 60 * 60 * 1000));
end;
{$ENDIF}

{$IFDEF DebugLCL}
var
  LastTickValid: boolean;
  LastTick: DWord;

function GetTickStep: DWord;
var
  CurTick: DWord;
begin
  CurTick:=GetTickCount;
  if LastTickValid then begin
    if LastTick<=CurTick then
      Result:=CurTick-LastTick
    else begin
      // tick counter has restarted
      Result:=CurTick+(DWord($FFFFFFFF)-LastTick+1);
    end;
  end else begin
    Result:=0;
  end;
  LastTickValid:=true;
  LastTick:=CurTick;
end;
{$ENDIF}


function PredefinedClipboardFormat(AFormat: TPredefinedClipboardFormat
  ): TClipboardFormat;
begin
  if FPredefinedClipboardFormats[AFormat]=0 then
    FPredefinedClipboardFormats[AFormat]:=
      ClipboardRegisterFormat(PredefinedClipboardMimeTypes[AFormat]);
  Result:=FPredefinedClipboardFormats[AFormat];
end;

function MsgKeyDataToShiftState(KeyData: Longint): TShiftState;
begin
  Result := [];

  if GetKeyState(VK_SHIFT) < 0 then Include(Result, ssShift);
  if GetKeyState(VK_CONTROL) < 0 then Include(Result, ssCtrl);
  if GetKeyState(VK_LWIN) < 0 then Include(Result, ssMeta);
  if KeyData and $20000000 <> 0 then Include(Result, ssAlt);
end;

function FindDefaultBrowser(out ABrowser, AParams: String): Boolean;

  function Find(const ShortFilename: String; out ABrowser: String): Boolean; inline;
  begin
    ABrowser := SearchFileInPath(ShortFilename + GetExeExt, '',
                      GetEnvironmentVariableUTF8('PATH'), PathSeparator,
                      [sffDontSearchInBasePath]);
    Result := ABrowser <> '';
  end;

begin
  {$IFDEF MSWindows}
  Find('rundll32', ABrowser);
  AParams := 'url.dll,FileProtocolHandler %s';
  {$ELSE}
    {$IFDEF DARWIN}
    // open command launches url in the appropriate browser under Mac OS X
    Find('open', ABrowser);
    AParams := '%s';
    {$ELSE}
      ABrowser := '';
    {$ENDIF}
  {$ENDIF}
  if ABrowser = '' then
  begin
    AParams := '%s';
    // Then search in path. Prefer open source ;)
    if Find('xdg-open', ABrowser)  // Portland OSDL/FreeDesktop standard on Linux
    or Find('htmlview', ABrowser)  // some redhat systems
    or Find('firefox', ABrowser)
    or Find('mozilla', ABrowser)
    or Find('galeon', ABrowser)
    or Find('konqueror', ABrowser)
    or Find('safari', ABrowser)
    or Find('netscape', ABrowser)
    or Find('opera', ABrowser)
    or Find('iexplore', ABrowser) then ;// some windows systems
  end;
  Result := ABrowser <> '';
end;

function OpenURL(AURL: String): Boolean;
{$IFDEF Windows}
var
{$IFDEF WinCE}
  Info: SHELLEXECUTEINFO;
{$ELSE}
  ws: WideString;
  ans: AnsiString;
{$ENDIF}
begin
  Result := False;
  if AURL = '' then Exit;

  {$IFDEF WinCE}
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := SEE_MASK_FLAG_NO_UI;
  Info.lpVerb := 'open';
  Info.lpFile := PWideChar(UTF8Decode(AURL));
  Result := ShellExecuteEx(@Info);
  {$ELSE}
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    ws := UTF8Decode(AURL);
    Result := ShellExecuteW(0, 'open', PWideChar(ws), nil, nil, SW_SHOWNORMAL) > 32;
  end
  else
  begin
    ans := Utf8ToAnsi(AURL); // utf8 must be converted to Windows Ansi-codepage
    Result := ShellExecute(0, 'open', PAnsiChar(ans), nil, nil, SW_SHOWNORMAL) > 32;
  end;
  {$ENDIF}
end;
{$ELSE}
{$IFDEF DARWIN}
var
  cf: CFStringRef;
  url: CFURLRef;
begin
  if AURL = '' then
    Exit(False);
  cf := CFStringCreateWithCString(kCFAllocatorDefault, @AURL[1], kCFStringEncodingUTF8);
  if not Assigned(cf) then
    Exit(False);
  url := CFURLCreateWithString(nil, cf, nil);
  Result := LSOpenCFURLRef(url, nil) = 0;
  CFRelease(url);
  CFRelease(cf);
end;
{$ELSE}
var
  ABrowser, AParams: String;
  BrowserProcess: TProcessUTF8;
begin
  Result := FindDefaultBrowser(ABrowser, AParams) and FileExistsUTF8(ABrowser) and FileIsExecutable(ABrowser);
  if not Result then
    Exit;

  // run
  BrowserProcess := TProcessUTF8.Create(nil);
  try
    BrowserProcess.CommandLine := ABrowser + ' ' + Format(AParams, [AURL]);
    BrowserProcess.Execute;
  finally
    BrowserProcess.Free;
  end;
end;
{$ENDIF}
{$ENDIF}

function OpenDocument(APath: String): Boolean;
{$IFDEF Windows}
begin
  Result := OpenURL(APath);
end;
{$ELSE}
{$IFDEF DARWIN}
begin
  Result := True;
  Shell('Open ' + APath);
end;
{$ELSE}
var
  lApp: string;
begin
  Result := True;

  if shell('which xdg-open') = 0 then       // Portland OSDL/FreeDesktop standard on Linux
    lApp := 'xdg-open '
  else if shell('which kfmclient') = 0 then // KDE command
    lApp := 'kfmclient exec '
  else if shell('which gnome-open') = 0 then// GNOME command
    lApp := 'gnome-open '
  else Exit(False);

  shell(lApp + APath);
end;
{$ENDIF}
{$ENDIF}

{$I winapi.inc}
{$I lclintf.inc}

procedure InternalInit;
var
  AClipboardFormat: TPredefinedClipboardFormat;
  c: char;
  s: string;
begin
  for AClipboardFormat:=Low(TPredefinedClipboardFormat) to
    High(TPredefinedClipboardFormat) do
      FPredefinedClipboardFormats[AClipboardFormat]:=0;
  for c:=Low(char) to High(char) do begin
    s:=lowercase(c);
    LowerCaseChars[c]:=s[1];
    UpperCaseChars[c]:=upcase(c);
  end;
  {$IFDEF DebugLCL}
  LastTickValid:=false;
  {$ENDIF}
end;

initialization
  InternalInit;

finalization
  FreeAndNil(MTimerMap);
  FreeAndNil(MTimerInfo);
end.
