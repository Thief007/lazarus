{ $Id$ }
{
 ---------------------------------------------------------------------------
 fpdcommand.pas  -  FP standalone debugger - Command interpreter
 ---------------------------------------------------------------------------

 This unit contains handles all debugger commands

 ---------------------------------------------------------------------------

 @created(Mon Apr 10th WET 2006)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.nl>)

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
unit FPDCommand;
{$mode objfpc}{$H+}
interface

uses
  SysUtils, Classes,
{$ifdef windows}
  Windows,
{$endif}
  LCLProc, FpDbgInfo, FpDbgClasses, DbgIntfBaseTypes, FpDbgUtil, CustApp;

procedure HandleCommand(ACommand: String; out CallProcessLoop: boolean);

implementation

uses
  FPDGlobal
{$ifdef windows}
  , FPDPEImage
{$endif windows}
  ;

type
  TFPDCommandHandler = procedure(AParams: String; out CallProcessLoop: boolean);

  TFPDCommand = class
  private
    FCommand: String;
    FHandler: TFPDCommandHandler;
    FHelp: String;
  public
    constructor Create(const AHandler: TFPDCommandHandler; const ACommand, AHelp: String);
    property Command: String read FCommand;
    property Handler: TFPDCommandHandler read FHandler;
    property Help: String read FHelp;
  end;

  { TFPDCommandList }

  TFPDCommandList = class
  private
    FCommands: TStringList;
    function GetItem(const AIndex: Integer): TFPDCommand;
  public
    procedure AddCommand(const ACommands: array of String; const AHandler: TFPDCommandHandler; const AHelp: String);
    function Count: Integer;
    constructor Create;
    destructor Destroy; override;
    function FindCommand(const ACommand: String): TFPDCommand;
    procedure HandleCommand(ACommand: String; out CallProcessLoop: boolean);
    property Items[const AIndex: Integer]: TFPDCommand read GetItem; default;
  end;


var
  MCommands: TFPDCommandList;
  MShowCommands: TFPDCommandList;
  MSetCommands: TFPDCommandList;

procedure HandleCommand(ACommand: String; out CallProcessLoop: boolean);
begin
  MCommands.HandleCommand(ACommand, CallProcessLoop);
end;


procedure HandleHelp(AParams: String; out CallProcessLoop: boolean);
var
  n: Integer;
  cmd: TFPDCommand;
begin
  CallProcessLoop:=false;
  if AParams = ''
  then begin
    WriteLN('Available commands:');
    for n := 0 to MCommands.Count - 1 do
      WriteLN(' ', MCommands[n].Command);
    end
  else begin
    cmd := MCommands.FindCommand(AParams);
    if cmd = nil
    then WriteLN('Unknown command: "', AParams, '"')
    else WriteLN(cmd.Help);
  end;
end;

procedure HandleFile(AParams: String; out CallProcessLoop: boolean);
begin
  if AParams <> ''
  then GController.ExecutableFilename := AParams;

  CallProcessLoop:=false;
  // TODO separate exec from args
end;

procedure HandleShow(AParams: String; out CallProcessLoop: boolean);
var
  cmd: TFPDCommand;
  S: String;
begin
  CallProcessLoop:=false;
  S := GetPart([], [' ', #9], AParams);
  if S = '' then S := 'help';
  cmd := MShowCommands.FindCommand(S);
  if cmd = nil
  then WriteLN('Unknown item: "', S, '"')
  else cmd.Handler(Trim(AParams), CallProcessLoop);
end;

procedure HandleSet(AParams: String; out CallProcessLoop: boolean);
var
  cmd: TFPDCommand;
  S: String;
begin
  S := GetPart([], [' ', #9], AParams);
  if S = '' then S := 'help';
  cmd := MSetCommands.FindCommand(S);
  if cmd = nil
  then WriteLN('Unknown param: "', S, '"')
  else cmd.Handler(Trim(AParams), CallProcessLoop);
end;

procedure HandleRun(AParams: String; out CallProcessLoop: boolean);
begin
  if Assigned(GController.MainProcess)
  then begin
    WriteLN('The debuggee is already running');
    Exit;
  end;

  if GController.ExecutableFilename = ''
  then begin
    WriteLN('No filename set');
    Exit;
  end;

  if not GController.Run then
    begin
    writeln('Failed to run '+GController.ExecutableFilename);
    CallProcessLoop:=false;
    end
  else
    CallProcessLoop:=true;
end;

procedure HandleBreak(AParams: String; out CallProcessLoop: boolean);
var
  S, P: String;
  Remove: Boolean;
  Address: TDbgPtr;
  e: Integer;
  Line: Cardinal;
  bp: TDbgBreakpoint;
begin
  if GController.MainProcess = nil
  then begin
    WriteLN('No Process');
    Exit;
  end;
  CallProcessLoop:=false;

  S := AParams;
  P := GetPart([], [' ', #9], S);
  Remove := P = '-d';
  if not Remove
  then S := P;
  
  if S = ''
  then begin
    // current addr
    P := '';
    Address := GController.CurrentProcess.GetInstructionPointerRegisterValue;
  end
  else begin
    P := GetPart([], [':'], S);
  end;
  
  if S = ''
  then begin
    if P <> ''
    then begin
      // address given
      Val(P, Address, e);
      if e <> 0
      then begin
        WriteLN('Illegal address: ', P);
        Exit;
      end;
    end;
    if Remove
    then begin
      if GController.CurrentProcess.RemoveBreak(Address)
      then WriteLn('breakpoint removed')
      else WriteLn('remove breakpoint failed');
    end
    else begin
      if GController.CurrentProcess.AddBreak(Address) <> nil
      then WriteLn('breakpoint added')
      else WriteLn('add breakpoint failed');
    end;
  end
  else begin
    S := GetPart([':'], [], S);
    Val(S, Line, e);
    if e <> 0
    then begin
      WriteLN('Illegal line: ', S);
      Exit;
    end;
    if Remove
    then begin
      if TDbgInstance(GController.CurrentProcess).RemoveBreak(P, Line)
      then WriteLn('breakpoint removed')
      else WriteLn('remove breakpoint failed');
      Exit;
    end;

    bp := TDbgInstance(GController.CurrentProcess).AddBreak(P, Line);
    if bp = nil
    then begin
      WriteLn('add breakpoint failed');
      Exit;
    end;
    
    WriteLn('breakpoint added at: ', FormatAddress(bp.Location));
  end;
end;

procedure HandleContinue(AParams: String; out CallProcessLoop: boolean);
begin
  CallProcessLoop:=false;
  if not assigned(GController.MainProcess)
  then begin
    WriteLN('The process is not paused');
    Exit;
  end;

  CallProcessLoop:=true;
end;

procedure HandleKill(AParams: String; out CallProcessLoop: boolean);
begin
  CallProcessLoop:=false;
  if not assigned(GController.MainProcess)
  then begin
    WriteLN('No process');
    Exit;
  end;

  WriteLN('Terminating ...');
  GController.Stop;
  CallProcessLoop:=true;
end;

procedure HandleNextInst(AParams: String; out CallProcessLoop: boolean);
begin
  CallProcessLoop:=false;
  if not assigned(GController.MainProcess)
  then begin
    WriteLN('The process is not paused');
    Exit;
  end;
  GController.StepOverInstr;
  CallProcessLoop:=true;
end;

procedure HandleNext(AParams: String; out CallProcessLoop: boolean);
begin
  CallProcessLoop:=false;
  if not assigned(GController.MainProcess)
  then begin
    WriteLN('The process is not paused');
    Exit;
  end;
  GController.Next;
  CallProcessLoop:=true;
end;

procedure HandleStepOut(AParams: String; out CallProcessLoop: boolean);
begin
  CallProcessLoop:=false;
  if not assigned(GController.MainProcess)
  then begin
    WriteLN('The process is not paused');
    Exit;
  end;
  GController.StepOut;
  CallProcessLoop:=true;
end;

procedure HandleStepInst(AParams: String; out CallProcessLoop: boolean);
begin
  CallProcessLoop:=false;
  if not assigned(GController.MainProcess)
  then begin
    WriteLN('The process is not paused');
    Exit;
  end;
  GController.StepIntoInstr;
  CallProcessLoop:=true;
end;

procedure HandleList(AParams: String; out CallProcessLoop: boolean);
begin
  WriteLN('not implemented: list');
  CallProcessLoop:=false;
end;

procedure HandleMemory(AParams: String; out CallProcessLoop: boolean);
// memory [-<size>] [<adress> <count>|<location> <count>]
var
  P: array[1..3] of String;
  Size, Count: Integer;
  Address: QWord;
  e, idx: Integer;
  buf: array[0..256*16 - 1] of Byte;
  BytesRead: Cardinal;
begin
  CallProcessLoop:=false;
  if GController.MainProcess = nil
  then begin
    WriteLN('No process');
    Exit;
  end;

  P[1] := GetPart([], [' ', #9], AParams);
  P[2] := GetPart([' ', #9], [' ', #9], AParams);
  P[3] := GetPart([' ', #9], [' ', #9], AParams);

  idx := 1;
  Count := 1;
  Size := 4;

  Address := GController.CurrentProcess.GetInstructionPointerRegisterValue;

  if P[idx] <> ''
  then begin
    if P[idx][1] = '-'
    then begin
      Size := -StrToIntDef(P[idx], -Size);
      if not (Size in [1,2,4,8,16])
      then begin
        WriteLN('Illegal size: "', P[idx], '"');
        Exit;
      end;
      Inc(idx);
    end;
    if P[idx] <> ''
    then begin
      if P[idx][1] = '%'
      then begin

      end
      else begin
        Val(P[idx], Address, e);
        if e <> 0
        then begin
          WriteLN('Location "',P[idx],'": Symbol resolving not implemented');
          Exit;
        end;
      end;
      Inc(idx);
    end;

    if P[idx] <> ''
    then begin
      Count := StrToIntDef(P[idx], Count);
      if Count > 256
      then begin
        WriteLN('Limiting count to 256');
        Count := 256;
      end;
      Inc(idx);
    end;
  end;


  BytesRead := Count * Size;
  if not GController.MainProcess.ReadData(Address, BytesRead, buf)
  then begin
    WriteLN('Could not read memory at: ', FormatAddress(Address));
    Exit;
  end;

  e := 0;
  while BytesRead >= size do
  begin
    if e and ((32 div Size) - 1) = 0
    then Write('[', FormatAddress(Address), '] ');

    for idx := Size - 1 downto 0 do Write(IntToHex(buf[e * size + idx], 2));

    Inc(e);
    if e = 32 div Size
    then WriteLn
    else Write(' ');
    Dec(BytesRead, Size);
    Inc(Address, Size);
  end;
  if e <> 32 div Size
  then WriteLn;
end;

procedure HandleWriteMemory(AParams: String; out CallProcessLoop: boolean);
// memory [<adress> <value>]
var
  P: array[1..2] of String;
  Size, Count: Integer;
  Address: QWord;
  Value: QWord;
  e, idx: Integer;
  buf: array[0..256*16 - 1] of Byte;
  BytesRead: Cardinal;
begin
  CallProcessLoop:=false;
  if GController.MainProcess = nil
  then begin
    WriteLN('No process');
    Exit;
  end;

  P[1] := GetPart([], [' ', #9], AParams);
  P[2] := GetPart([' ', #9], [' ', #9], AParams);

  idx := 1;
  Count := 1;
  Size := 4;

  if P[idx] <> ''
  then begin
    if P[idx] <> ''
    then begin
      Val(P[idx], Address, e);
      if e <> 0
      then begin
        WriteLN('Location "',P[idx],'": Symbol resolving not implemented');
        Exit;
      end;
      Inc(idx);
    end;

    if P[idx] <> ''
    then begin
      Val(P[idx], Value, e);
      if e <> 0
      then begin
        WriteLN('Value "',P[idx],'": Symbol resolving not implemented');
        Exit;
      end;
      Inc(idx);
    end;
  end;


  if not GController.MainProcess.WriteData(Address, 4, Value)
  then begin
    WriteLN('Could not write memory at: ', FormatAddress(Address));
    Exit;
  end;
end;


procedure HandleDisas(AParams: String; out CallProcessLoop: boolean);
begin
  CallProcessLoop:=false;
  WriteLN('not implemented: disassemble');
end;

procedure HandleEval(AParams: String; out CallProcessLoop: boolean);
begin
  CallProcessLoop:=false;
  WriteLN('not implemented: evaluate');
end;

procedure HandleQuit(AParams: String; out CallProcessLoop: boolean);
begin
  WriteLN('Quitting ...');
  CallProcessLoop := assigned(GController.MainProcess);
  CustomApplication.Terminate;
end;

//=================
// S H O W
//=================

procedure HandleShowHelp(AParams: String; out CallProcessLoop: boolean);
var
  n: Integer;
  cmd: TFPDCommand;
begin
  CallProcessLoop:=false;
  if AParams = ''
  then begin
    WriteLN('Available items:');
    for n := 0 to MShowCommands.Count - 1 do
      WriteLN(' ', MShowCommands[n].Command);
    end
  else begin
    cmd := MShowCommands.FindCommand(AParams);
    if cmd = nil
    then WriteLN('Unknown item: "', AParams, '"')
    else WriteLN(cmd.Help);
  end;
end;

procedure HandleShowFile(AParams: String; out CallProcessLoop: boolean);
var
  hFile, hMap: THandle;
  FilePtr: Pointer;
begin
  CallProcessLoop:=false;
  if GController.ExecutableFilename = ''
  then begin
    WriteLN('No filename set');
    Exit;
  end;
{$ifdef windows}
  hFile := CreateFile(PChar(GController.ExecutableFilename), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_RANDOM_ACCESS, 0);
  if hFile = INVALID_HANDLE_VALUE
  then begin
    WriteLN('File "', GController.ExecutableFilename, '" does not exist');
    Exit;
  end;

  hMap := 0;
  FilePtr := nil;
  try
    hMap := CreateFileMapping(hFile, nil, PAGE_READONLY{ or SEC_IMAGE}, 0, 0, nil);
    if hMap = 0
    then begin
      WriteLN('Map error');
      Exit;
    end;

    FilePtr := MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
    DumpPEImage(GetCurrentProcess, TDbgPtr(FilePtr));
  finally
    UnmapViewOfFile(FilePtr);
    CloseHandle(hMap);
    CloseHandle(hFile);
  end;
{$endif windows}
end;

procedure HandleShowCallStack(AParams: String; out CallProcessLoop: boolean);
var
  Address, Frame, LastFrame: QWord;
  Size, Count: integer;
begin
  CallProcessLoop:=false;
  if (GController.MainProcess = nil)
  then begin
    WriteLN('No process');
    Exit;
  end;

  Address := GController.CurrentProcess.GetInstructionPointerRegisterValue;
  Frame := GController.CurrentProcess.GetStackBasePointerRegisterValue;;
  Size := sizeof(pointer);

  WriteLN('Callstack:');
  WriteLn(' ', FormatAddress(Address));
  LastFrame := 0;
  Count := 25;
  while (Frame <> 0) and (Frame > LastFrame) do
  begin
    if not GController.CurrentProcess.ReadData(Frame + Size, Size, Address) or (Address = 0) then Break;
    WriteLn(' ', FormatAddress(Address));
    Dec(count);
    if Count <= 0 then Exit;
    if not GController.CurrentProcess.ReadData(Frame, Size, Frame) then Break;
  end;
end;

//=================
// S E T
//=================

procedure HandleSetHelp(AParams: String; out CallProcessLoop: boolean);
var
  n: Integer;
  cmd: TFPDCommand;
begin
  CallProcessLoop:=false;
  if AParams = ''
  then begin
    WriteLN('Usage: set param [<value>] When no value is given, the current value is shown.');
    WriteLN('Available params:');
    for n := 0 to MSetCommands.Count - 1 do
      WriteLN(' ', MSetCommands[n].Command);
    end
  else begin
    cmd := MSetCommands.FindCommand(AParams);
    if cmd = nil
    then WriteLN('Unknown param: "', AParams, '"')
    else WriteLN(cmd.Help);
  end;
end;

procedure HandleSetMode(AParams: String; out CallProcessLoop: boolean);
const
  MODE: array[TFPDMode] of String = ('32', '64');
begin
  CallProcessLoop:=false;
  if AParams = ''
  then WriteLN(' Mode: ', MODE[GMode])
  else if AParams = '32'
  then GMode := dm32
  else if AParams = '64'
  then GMode := dm64
  else WriteLN('Unknown mode: "', AParams, '"')
end;

procedure HandleSetBoll(AParams: String; out CallProcessLoop: boolean);
const
  MODE: array[Boolean] of String = ('off', 'on');
begin
  CallProcessLoop:=false;
  if AParams = ''
  then WriteLN(' Break on library load: ', MODE[GBreakOnLibraryLoad])
  else GBreakOnLibraryLoad := (Length(Aparams) > 1) and (AParams[2] in ['n', 'N'])
end;

procedure HandleSetImageInfo(AParams: String; out CallProcessLoop: boolean);
const
  MODE: array[TFPDImageInfo] of String = ('none', 'name', 'detail');
begin
  CallProcessLoop:=false;
  if AParams = ''
  then WriteLN(' Imageinfo: ', MODE[GImageInfo])
  else begin
    case StringCase(AParams, MODE, True, False) of
      0: GImageInfo := iiNone;
      1: GImageInfo := iiName;
      2: GImageInfo := iiDetail;
    else
      WriteLN('Unknown type: "', AParams, '"')
    end;
  end;
end;


//=================
//=================
//=================

{ TFPDCommand }

constructor TFPDCommand.Create(const AHandler: TFPDCommandHandler; const ACommand, AHelp: String);
begin
  inherited Create;
  FCommand := ACommand;
  FHandler := AHandler;
  FHelp := AHelp;
end;

{ TFPDCommandList }

procedure TFPDCommandList.AddCommand(const ACommands: array of String; const AHandler: TFPDCommandHandler; const AHelp: String);
var
  n: Integer;
begin
  for n := Low(ACommands) to High(ACommands) do
    FCommands.AddObject(ACommands[n], TFPDCommand.Create(AHandler, ACommands[n], AHelp));
end;

function TFPDCommandList.Count: Integer;
begin
  Result := FCommands.Count;
end;

constructor TFPDCommandList.Create;
begin
  inherited;
  FCommands := TStringList.Create;
  FCommands.Duplicates := dupError;
  FCommands.Sorted := True;
end;

destructor TFPDCommandList.Destroy;
var
  n: integer;
begin
  for n := 0 to FCommands.Count - 1 do
    FCommands.Objects[n].Free;
  FreeAndNil(FCommands);
  inherited;
end;

function TFPDCommandList.FindCommand(const ACommand: String): TFPDCommand;
var
  idx: Integer;
begin
  idx := FCommands.IndexOf(ACommand);
  if idx = -1
  then Result := nil
  else Result := TFPDCommand(FCommands.Objects[idx]);
end;

function TFPDCommandList.GetItem(const AIndex: Integer): TFPDCommand;
begin
  Result := TFPDCommand(FCommands.Objects[AIndex]);
end;

procedure TFPDCommandList.HandleCommand(ACommand: String; out CallProcessLoop: boolean);
var
  cmd: TFPDCommand;
  S: String;
begin
  S := GetPart([], [' ', #9], ACommand);
  cmd := FindCommand(S);
  if cmd = nil
  then WriteLN('Unknown command: "', S, '"')
  else cmd.Handler(Trim(ACommand), CallProcessLoop);
end;

//=================
//=================
//=================

procedure Initialize;
begin
  MCommands := TFPDCommandList.Create;

  MCommands.AddCommand(['help', 'h', '?'], @HandleHelp, 'help [<command>]: Shows help on a command, or this help if no command given');
  MCommands.AddCommand(['quit', 'q'], @HandleQuit,  'quit: Quits the debugger');
  MCommands.AddCommand(['file', 'f'], @HandleFile, 'file <filename>: Loads the debuggee <filename>');
  MCommands.AddCommand(['show', 's'], @HandleShow, 'show <info>: Enter show help for more info');
  MCommands.AddCommand(['set'], @HandleSet,  'set param: Enter set help for more info');
  MCommands.AddCommand(['run', 'r'], @HandleRun,  'run: Starts the loaded debuggee');
  MCommands.AddCommand(['break', 'b'], @HandleBreak,  'break [-d] <adress>|<filename:line>: Set a breakpoint at <adress> or <filename:line>. -d removes');
  MCommands.AddCommand(['continue', 'cont', 'c'], @HandleContinue,  'continue: Continues execution');
  MCommands.AddCommand(['kill', 'k'], @HandleKill,  'kill: Stops execution of the debuggee');
  MCommands.AddCommand(['step-inst', 'si'], @HandleStepInst,  'step-inst: Steps-into one instruction');
  MCommands.AddCommand(['next-inst', 'ni'], @HandleNextInst,  'next-inst: Steps-over one instruction');
  MCommands.AddCommand(['next', 'n'], @HandleNext,  'next: Steps one line');
  MCommands.AddCommand(['step-out', 'so'], @HandleStepOut,  'step-out: Steps out of current procedure');
  MCommands.AddCommand(['list', 'l'], @HandleList,  'list [<adress>|<location>]: Lists the source for <adress> or <location>');
  MCommands.AddCommand(['memory', 'mem', 'm'], @HandleMemory,  'memory [-<size>] [<adress> <count>|<location> <count>]: Dump <count> (default: 1) from memory <adress> or <location> (default: current) of <size> (default: 4) bytes, where size is 1,2,4,8 or 16.');
  MCommands.AddCommand(['writememory', 'w'], @HandleWriteMemory,  'writememory [<adress> <value>]: Write <value> (with a length of 4 bytes) into memory at address <adress>.');
  MCommands.AddCommand(['disassemble', 'dis', 'd'], @HandleDisas,  'disassemble [<adress>|<location>] [<count>]: Disassemble <count> instructions from <adress> or <location> or current IP if none given');
  MCommands.AddCommand(['evaluate', 'eval', 'e'], @HandleEval,  'evaluate <symbol>: Evaluate <symbol>');


  MShowCommands := TFPDCommandList.Create;

  MShowCommands.AddCommand(['help', 'h', '?'], @HandleShowHelp, 'show help [<info>]: Shows help for info or this help if none given');
  MShowCommands.AddCommand(['file', 'f'], @HandleShowFile, 'show file: Shows the info for the current file');
  MShowCommands.AddCommand(['callstack', 'c'], @HandleShowCallStack,  'show callstack: Shows the callstack');

  MSetCommands := TFPDCommandList.Create;

  MSetCommands.AddCommand(['help', 'h', '?'], @HandleSetHelp, 'set help [<param>]: Shows help for param or this help if none given');
  MSetCommands.AddCommand(['mode', 'm'], @HandleSetMode, 'set mode 32|64: Set the mode for retrieving process info');
  MSetCommands.AddCommand(['break_on_library_load', 'boll'], @HandleSetBOLL, 'set break_on_library_load on|off: Pause running when a library is loaded (default off)');
  MSetCommands.AddCommand(['imageinfo', 'ii'], @HandleSetImageInfo, 'set imageinfo none|name|detail: When a library is loaded, show nothing, only its name or all details (default none)');
end;

procedure Finalize;
begin
  FreeAndNil(MCommands);
  FreeAndNil(MSetCommands);
  FreeAndNil(MShowCommands);
end;

initialization
  Initialize;

finalization
  Finalize;

end.
