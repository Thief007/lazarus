{ $Id$ }
{                        ----------------------------------------------
                         GDBDebugger.pp  -  Debugger class forGDB
                         ----------------------------------------------

 @created(Wed Feb 23rd WET 2002)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@lazarus.dommelstein.net>)

 This unit contains debugger class for the GDB/MI debugger.


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
unit GDBMIDebugger;

{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils, LCLProc, Dialogs, LazConf, DBGUtils, Debugger,
  CmdLineDebugger, GDBTypeInfo, 
{$IFDEF WIN32}
  Windows,
{$ENDIF}
{$IFDEF UNIX}
 {$IFDEF Ver1_0}
   Linux,
 {$ELSE}
   Unix,BaseUnix,
 {$ENDIF}     
{$ENDIF}
  BaseDebugManager;

type
  TGDBMIProgramInfo = record
    State: TDBGState;
    BreakPoint: Integer; // ID of Breakpoint hit
    Signal: Integer;     // Signal no if we hit one
    SignalText: String;  // Signal text if we hit one
  end;

  TGDBMICmdFlags = set of (
    cfNoMiCommand, // the command is not a MI command
    cfIgnoreState, // ignore the result state of the command
    cfIgnoreError, // ignore errors
    cfExternal     // the command is a result from a user action
  );
  TGDBMICallback = procedure(var AResultState: TDBGState; var AResultValues: String; const ATag: Integer) of object;
  TGDBMIPauseWaitState = (pwsNone, pwsInternal, pwsExternal);

  TGDBMITargetFlags = set of (
    tfHasSymbols,      // Debug symbols are present
    tfRTLUsesRegCall   // the RTL is compiled with RegCall calling convention
  );

  TGDBMIDebuggerFlags = set of (
    dfImplicidTypes    // Debugger supports implicit types (^Type)
  );


  TGDBMIRTLCallingConvention = (ccDefault, ccRegCall, ccStdCall);

  TGDBMIDebuggerProperties = class(TDebuggerProperties)
  private
    FOverrideRTLCallingConvention: TGDBMIRTLCallingConvention;
  public
    constructor Create;
  published
    property OverrideRTLCallingConvention: TGDBMIRTLCallingConvention read FOverrideRTLCallingConvention write FOverrideRTLCallingConvention;
  end;

  { TGDBMIDebugger }

  TGDBMIDebugger = class(TCmdLineDebugger)
  private
    FCommandQueue: TStringList;
    FTargetPID: Integer;
    FBreakErrorBreakID: Integer;
    FRunErrorBreakID: Integer;
    FExceptionBreakID: Integer;
    FVersion: String;
    FPauseWaitState: TGDBMIPauseWaitState;
    FInExecuteCount: Integer;
    FTargetFlags: TGDBMITargetFlags;
    FDebuggerFlags: TGDBMIDebuggerFlags;
    // Implementation of external functions
    function  GDBEnvironment(const AVariable: String; const ASet: Boolean): Boolean;
    function  GDBEvaluate(const AExpression: String; var AResult: String): Boolean;
    function  GDBRun: Boolean;
    function  GDBPause(const AInternal: Boolean): Boolean;
    function  GDBStop: Boolean;
    function  GDBStepOver: Boolean;
    function  GDBStepInto: Boolean;
    function  GDBRunTo(const ASource: String; const ALine: Integer): Boolean;
    function  GDBJumpTo(const ASource: String; const ALine: Integer): Boolean;
    // ---
    procedure GDBStopCallback(var AResultState: TDBGState; var AResultValues: String; const ATag: Integer);
    function  FindBreakpoint(const ABreakpoint: Integer): TDBGBreakPoint;
    function  GetClassName(const AClass: TDBGPtr): String; overload;
    function  GetClassName(const AExpression: String; const AValues: array of const): String; overload;
    function  GetInstanceClassName(const AInstance: TDBGPtr): String; overload;
    function  GetInstanceClassName(const AExpression: String; const AValues: array of const): String; overload;
    function  GetText(const ALocation: TDBGPtr): String; overload;
    function  GetText(const AExpression: String; const AValues: array of const): String; overload;
    function  GetData(const ALocation: TDbgPtr): TDbgPtr; overload;
    function  GetData(const AExpression: String; const AValues: array of const): TDbgPtr; overload;
    function  GetStrValue(const AExpression: String; const AValues: array of const): String;
    function  GetIntValue(const AExpression: String; const AValues: array of const): Integer;
    function  GetPtrValue(const AExpression: String; const AValues: array of const): TDbgPtr;
    function  GetGDBTypeInfo(const AExpression: String): TGDBType;
    function  ProcessResult(var ANewState: TDBGState; var AResultValues: String; const ANoMICommand: Boolean): Boolean;
    function  ProcessRunning(var AStoppedParams: String): Boolean;
    function  ProcessStopped(const AParams: String; const AIgnoreSigIntState: Boolean): Boolean;
    function  ExecuteCommand(const ACommand: String; const AFlags: TGDBMICmdFlags): Boolean; overload;
    function  ExecuteCommand(const ACommand: String; const AFlags: TGDBMICmdFlags; const ACallback: TGDBMICallback; const ATag: Integer): Boolean; overload;
    function  ExecuteCommand(const ACommand: String; var AResultValues: String; const AFlags: TGDBMICmdFlags): Boolean; overload;
    function  ExecuteCommand(const ACommand: String; const AValues: array of const; const AFlags: TGDBMICmdFlags): Boolean; overload;
    function  ExecuteCommand(const ACommand: String; const AValues: array of const; const AFlags: TGDBMICmdFlags; const ACallback: TGDBMICallback; const ATag: Integer): Boolean; overload;
    function  ExecuteCommand(const ACommand: String; const AValues: array of const; var AResultValues: String; const AFlags: TGDBMICmdFlags): Boolean; overload;
    function  ExecuteCommand(const ACommand: String; const AValues: array of const; var AResultState: TDBGState; const AFlags: TGDBMICmdFlags): Boolean; overload;
    function  ExecuteCommand(const ACommand: String; const AValues: array of const; var AResultState: TDBGState; var AResultValues: String; const AFlags: TGDBMICmdFlags): Boolean; overload;
    function  ExecuteCommand(const ACommand: String; const AValues: array of const; var AResultState: TDBGState; var AResultValues: String; const AFlags: TGDBMICmdFlags; const ACallback: TGDBMICallback; const ATag: Integer): Boolean; overload;
    function  StartDebugging(const AContinueCommand: String): Boolean;
  protected
    function  ChangeFileName: Boolean; override;
    function  CreateBreakPoints: TDBGBreakPoints; override;
    function  CreateLocals: TDBGLocals; override;
    function  CreateCallStack: TDBGCallStack; override;
    function  CreateWatches: TDBGWatches; override;
    function  GetSupportedCommands: TDBGCommands; override;
    procedure InterruptTarget; virtual;
    {$IFDEF WIN32}
    procedure InterruptTargetCallback(var AResultState: TDBGState; var AResultValues: String; const ATag: Integer); virtual;
    {$ENDIF}
    function  ParseInitialization: Boolean; virtual;
    function  RequestCommand(const ACommand: TDBGCommand; const AParams: array of const): Boolean; override;
    procedure ClearCommandQueue;
    property  TargetPID: Integer read FTargetPID;
  public
    class function CreateProperties: TDebuggerProperties; override; // Creates debuggerproperties
    class function Caption: String; override;
    class function ExePaths: String; override;
    
    constructor Create(const AExternalDebugger: String); override;
    destructor Destroy; override;

    procedure Init; override;         // Initializes external debugger
    procedure Done; override;         // Kills external debugger
    
    // internal testing
    procedure TestCmd(const ACommand: String); override;
  end;


implementation

type
  TGDBMIBreakPoint = class(TDBGBreakPoint)
  private
    FBreakID: Integer;
    procedure SetBreakPointCallback(var AResultState: TDBGState; var AResultValues: String; const ATag: Integer);
    procedure SetBreakPoint;
    procedure ReleaseBreakPoint;
    procedure UpdateEnable;
    procedure UpdateExpression;
  protected
    procedure DoEnableChange; override;
    procedure DoExpressionChange; override;
    procedure DoStateChange(const AOldState: TDBGState); override;
    procedure SetLocation(const ASource: String; const ALine: Integer); override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Hit(var ACanContinue: Boolean);
  end;

  TGDBMILocals = class(TDBGLocals)
  private
    FLocals: TStringList;
    FLocalsValid: Boolean;
    procedure LocalsNeeded;
    procedure AddLocals(const AParams:String);
  protected
    procedure DoStateChange(const AOldState: TDBGState); override;
    function GetCount: Integer; override;
    function GetName(const AnIndex: Integer): String; override;
    function GetValue(const AnIndex: Integer): String; override;
  public
    constructor Create(const ADebugger: TDebugger);
    destructor Destroy; override;
  end;

  TGDBMIWatch = class(TDBGWatch)
  private
    FEvaluated: Boolean;
    FValue: String;
    procedure EvaluationNeeded;
  protected
    procedure DoEnableChange; override;
    procedure DoExpressionChange; override;
    procedure DoStateChange(const AOldState: TDBGState); override;
    function  GetValue: String; override;
    function  GetValid: TValidState; override;
  public
    constructor Create(ACollection: TCollection); override;
  end;
  
  TGDBMICallStack = class(TDBGCallStack)
  private
  protected
    function CheckCount: Boolean; override;
    function CreateStackEntry(const AIndex: Integer): TCallStackEntry; override;
  public
  end;

  TGDBMIExpression = class(TObject)
  private
    FDebugger: TGDBMIDebugger; 
    FOperator: String;
    FLeft: TGDBMIExpression;
    FRight: TGDBMIExpression;
    procedure CreateSubExpression(const AExpression: String);
  protected
  public
    constructor Create(const ADebugger: TGDBMIDebugger; const AExpression: String);
    destructor Destroy; override;
    function DumpExpression: String;
    function GetExpression(var AResult: String): Boolean;
  end;
  
  PGDBMICmdInfo = ^TGDBMICmdInfo;
  TGDBMICmdInfo = record
    Flags: TGDBMICmdFlags;
    CallBack: TGDBMICallback;
    Tag: Integer;
  end;
  
{ =========================================================================== }
{ Some win32 stuff }
{ =========================================================================== }
{$IFDEF WIN32}
var
  DebugBreakAddr: Pointer = nil;
  // use our own version. Win9x doesn't support this, so it is a nice check
  _CreateRemoteThread: function(hProcess: THandle; lpThreadAttributes: Pointer; dwStackSize: DWORD; lpStartAddress: TFNThreadStartRoutine; lpParameter: Pointer; dwCreationFlags: DWORD; var lpThreadId: DWORD): THandle; stdcall = nil;

procedure InitWin32;
var
  hMod: THandle;
begin           
  // Check if we already are initialized
  if DebugBreakAddr <> nil then Exit;
   
  // normally you would load a lib, but since kernel32 is 
  // always loaded we can use this (and we don't have to free it
  hMod := GetModuleHandle(kernel32);
  if hMod = 0 then Exit; //????

  DebugBreakAddr := GetProcAddress(hMod, 'DebugBreak');
  Pointer(_CreateRemoteThread) := GetProcAddress(hMod, 'CreateRemoteThread');
end;
{$ENDIF}  

{ =========================================================================== }
{ Helpers }
{ =========================================================================== }

function CreateMIValueList(AResultValues: String): TStringList;
var
  n: Integer;
  InString: Boolean;
  InList: Integer;
  c: Char;
begin
  Result := TStringList.Create;
  if AResultValues = '' then Exit;
  // strip surrounding '[]' and '{}' first
  case AResultValues[1] of
    '[': begin
      if AResultValues[Length(AResultValues)] = ']'
      then begin
        Delete(AResultValues, Length(AResultValues), 1);
        Delete(AResultValues, 1, 1);
      end;
    end;
    '{': begin
      if AResultValues[Length(AResultValues)] = '}'
      then begin
        Delete(AResultValues, Length(AResultValues), 1);
        Delete(AResultValues, 1, 1);
      end;
    end;
  end;

  n := 1;
  InString := False;
  InList := 0;
  c := #0;
  while (n <= Length(AResultValues)) do
  begin
    if c = '\'
    then begin
      // previous char was escape char
      c := #0;
      Inc(n);
      Continue;
    end;
    c := AResultValues[n];
    if c = '\'
    then begin
      Delete(AResultValues, n, 1);
      Continue;
    end;

    if InString
    then begin
      if  c = '"'
      then begin
        InString := False;
        Delete(AResultValues, n, 1);
        Continue;
      end;
    end
    else begin
      if InList > 0
      then begin
        if c in [']', '}']
        then Dec(InList);
      end
      else begin
        if c = ','
        then begin
          Result.Add(Copy(AResultValues, 1, n - 1));
          Delete(AResultValues, 1, n);
          n := 1;
          Continue;
        end
        else if c = '"'
        then begin
          InString := True;
          Delete(AResultValues, n, 1);
          Continue;
        end;
      end;
      if c in ['[', '{']
      then Inc(InList);
    end;
    Inc(n);
  end;
  if AResultValues <> ''
  then Result.Add(AResultValues);
end;

function CreateValueList(AResultValues: String): TStringList;
var
  n: Integer;
begin
  Result := TStringList.Create;
  if AResultValues = '' then Exit;
  n := Pos(' = ', AResultValues);
  if n > 0
  then begin
    Delete(AResultValues, n, 1);
    Delete(AResultValues, n + 1, 1);
  end;
  Result.Add(AResultValues);
end;

{ =========================================================================== }
{ TGDBMIDebuggerProperties }
{ =========================================================================== }

constructor TGDBMIDebuggerProperties.Create;
begin
  FOverrideRTLCallingConvention := ccDefault;
  inherited;
end;


{ =========================================================================== }
{ TGDBMIDebugger }
{ =========================================================================== }

function TGDBMIDebugger.Caption: String;
begin
  Result := 'GNU debugger (gdb)';
end;

function TGDBMIDebugger.ChangeFileName: Boolean;
  function GetFileNameForGDB: string;
  // GDB wants forward slashes in its filenames, even on win32.
  var
    SeperatorPos: integer;
  begin
    Result := FileName;
    if DirectorySeparator = '/' then Exit;

    repeat
      SeperatorPos := Pos(DirectorySeparator, Result);
      if SeperatorPos <= 0 then Exit;
      
      Delete(Result, SeperatorPos, 1);
      Insert('/', Result, SeperatorPos);
    until False;
  end;              
  
  procedure ClearBreakpoint(var ABreakID: Integer);
  begin
    if ABreakID = -1 then Exit;
    ExecuteCommand('-break-delete %d', [ABreakID], [cfIgnoreError]);
    ABreakID := -1;
  end;
var
  S: String;
  ResultState: TDBGState;
begin
  Result := False;
  
  //Cleanup our own breakpoints
  ClearBreakpoint(FExceptionBreakID);
  ClearBreakpoint(FBreakErrorBreakID);
  ClearBreakpoint(FRunErrorBreakID);


  S := GetFileNameForGDB; 
  if not ExecuteCommand('-file-exec-and-symbols %s', [S], ResultState, [cfIgnoreError]) then Exit;
  if  (ResultState = dsError) 
  and (FileName <> '')
  then begin
    SetState(dsError);
    Exit;
  end;
  if not (inherited ChangeFileName) then Exit;
  if State = dsError then Exit;
  if FileName = '' 
  then begin
    Result := True;
    Exit;
  end;
  
  if tfHasSymbols in FTargetFlags
  then begin
    // Force setting language
    // Setting extensions dumps GDB (bug #508)
    if not ExecuteCommand('-gdb-set language pascal', []) then exit;
    if State=dsError then exit;
(*
    ExecuteCommand('-gdb-set extension-language .lpr pascal', False);
    if not FHasSymbols then Exit; // file-exec-and-symbols not allways result in no symbols
    ExecuteCommand('-gdb-set extension-language .lrs pascal', False);
    ExecuteCommand('-gdb-set extension-language .dpr pascal', False);
    ExecuteCommand('-gdb-set extension-language .pas pascal', False);
    ExecuteCommand('-gdb-set extension-language .pp pascal', False);
    ExecuteCommand('-gdb-set extension-language .inc pascal', False);
*)
  end;
  Result:=true;
end;

constructor TGDBMIDebugger.Create(const AExternalDebugger: String);
begin
  FBreakErrorBreakID := -1;
  FRunErrorBreakID := -1;
  FExceptionBreakID := -1;
  FCommandQueue := TStringList.Create;
  FTargetPID := 0;
  FTargetFlags := [];
  FDebuggerFlags := [];

{$IFDEF Win32}
  InitWin32;
{$ENDIF}  

  inherited;
end;

function TGDBMIDebugger.CreateBreakPoints: TDBGBreakPoints;
begin
  Result := TDBGBreakPoints.Create(Self, TGDBMIBreakPoint);
end;

function TGDBMIDebugger.CreateCallStack: TDBGCallStack; 
begin
  Result := TGDBMICallStack.Create(Self);
end;

function TGDBMIDebugger.CreateLocals: TDBGLocals;
begin
  Result := TGDBMILocals.Create(Self);
end;

function TGDBMIDebugger.CreateProperties: TDebuggerProperties;
begin
  Result := TGDBMIDebuggerProperties.Create;
end;

function TGDBMIDebugger.CreateWatches: TDBGWatches;
begin
  Result := TDBGWatches.Create(Self, TGDBMIWatch);
end;

destructor TGDBMIDebugger.Destroy;
begin
  inherited;
  ClearCommandQueue;
  FreeAndNil(FCommandQueue);
end;

procedure TGDBMIDebugger.Done;
begin
  if State = dsRun then GDBPause(True);
  ExecuteCommand('-gdb-exit', []);
  inherited Done;
end;

function TGDBMIDebugger.ExecuteCommand(const ACommand: String;
  const AFlags: TGDBMICmdFlags): Boolean;
var
  S: String;
  ResultState: TDBGState;
begin
  Result := ExecuteCommand(ACommand, [], ResultState, S, AFlags, nil, 0);
end;

function TGDBMIDebugger.ExecuteCommand(const ACommand: String;
  const AFlags: TGDBMICmdFlags; const ACallback: TGDBMICallback; const ATag: Integer): Boolean;
var
  S: String;
  ResultState: TDBGState;
begin
  Result := ExecuteCommand(ACommand, [], ResultState, S, AFlags, ACallback, ATag);
end;

function TGDBMIDebugger.ExecuteCommand(const ACommand: String;
  var AResultValues: String; const AFlags: TGDBMICmdFlags): Boolean;
var
  ResultState: TDBGState;
begin
  Result := ExecuteCommand(ACommand, [], ResultState, AResultValues, AFlags, nil, 0);
end;

function TGDBMIDebugger.ExecuteCommand(const ACommand: String;
  const AValues: array of const; const AFlags: TGDBMICmdFlags): Boolean;
var
  S: String;
  ResultState: TDBGState;
begin
  Result := ExecuteCommand(ACommand, AValues, ResultState, S, AFlags, nil, 0);
end;

function TGDBMIDebugger.ExecuteCommand(const ACommand: String;
  const AValues: array of const; const AFlags: TGDBMICmdFlags;
  const ACallback: TGDBMICallback; const ATag: Integer): Boolean;
var
  S: String;
  ResultState: TDBGState;
begin
  Result := ExecuteCommand(ACommand, AValues, ResultState, S, AFlags, ACallback, ATag);
end;

function TGDBMIDebugger.ExecuteCommand(const ACommand: String;
  const AValues: array of const; var AResultValues: String;
  const AFlags: TGDBMICmdFlags): Boolean;
var
  ResultState: TDBGState;
begin
  Result := ExecuteCommand(ACommand, AValues, ResultState, AResultValues, AFlags, nil, 0);
end;

function TGDBMIDebugger.ExecuteCommand(const ACommand: String; 
  const AValues: array of const; var AResultState: TDBGState;
  const AFlags: TGDBMICmdFlags): Boolean; 
var
  S: String;
begin
  Result := ExecuteCommand(ACommand, AValues, AResultState, S, AFlags, nil, 0);
end;

function TGDBMIDebugger.ExecuteCommand(const ACommand: String;
  const AValues: array of const; var AResultState: TDBGState;
  var AResultValues: String; const AFlags: TGDBMICmdFlags): Boolean;
begin
  Result := ExecuteCommand(ACommand, AValues, AResultState, AResultValues, AFlags, nil, 0);
end;

function TGDBMIDebugger.ExecuteCommand(const ACommand: String;
  const AValues: array of const; var AResultState: TDBGState;
  var AResultValues: String; const AFlags: TGDBMICmdFlags;
  const ACallback: TGDBMICallback; const ATag: Integer): Boolean;
var
  Cmd: String;
  CmdInfo: PGDBMICmdInfo;
  R, FirstCmd: Boolean;
  StoppedParams: String;
  ResultState: TDBGState;
  ResultValues: String;
begin
  Result := False; // Assume queued
  AResultValues := '';
  AResultState := dsNone;

  New(CmdInfo);
  CmdInfo^.Flags := AFlags;
  CmdInfo^.Callback := ACallBack;
  CmdInfo^.Tag := ATag;
  FCommandQueue.AddObject(Format(ACommand, AValues), TObject(CmdInfo));

  if FCommandQueue.Count > 1
  then begin
    if cfExternal in AFlags
    then DebugLn('[WARNING] Debugger: Execution of external command "', ACommand, '" while queue exists');
    Exit;
  end;
  // If we are here we can process the command directly
  Result := True;
  FirstCmd := True;
  repeat
    Inc(FInExecuteCount);
    try
      ResultValues := '';
      ResultState := dsNone;

      Cmd := FCommandQueue[0];
      CmdInfo := PGDBMICmdInfo(FCommandQueue.Objects[0]);
      SendCmdLn(Cmd);
      R := ProcessResult(ResultState, ResultValues, cfNoMICommand in CmdInfo^.Flags);
      if not R
      then begin
        DebugLn('[WARNING] TGDBMIDebugger:  ExecuteCommand "',Cmd,'" failed.');
        SetState(dsError);
        Break;
      end;

      if (ResultState <> dsNone)
      and not (cfIgnoreState in CmdInfo^.Flags)
      and ((ResultState <> dsError) or not (cfIgnoreError in CmdInfo^.Flags))
      then SetState(ResultState);

      StoppedParams := '';
      if ResultState = dsRun
      then R := ProcessRunning(StoppedParams);

      // Delete command first to allow GDB access while processing stopped
      FCommandQueue.Delete(0);
      try

        if StoppedParams <> ''
        then ProcessStopped(StoppedParams, FPauseWaitState = pwsInternal);

        if Assigned(CmdInfo^.Callback)
        then CmdInfo^.Callback(ResultState, ResultValues, CmdInfo^.Tag);
      finally
        Dispose(CmdInfo);
      end;

      if FirstCmd
      then begin
        FirstCmd := False;
        AResultValues := ResultValues;
        AResultState := ResultState;
      end;
    finally
      Dec(FInExecuteCount);
    end;
    
    if  FCommandQueue.Count = 0
    then begin
      if  (FInExecuteCount = 0)
      and (FPauseWaitState = pwsInternal)
      and (State = dsRun)
      then begin
        // reset state
        FPauseWaitState := pwsNone;
        // insert continue command
        New(CmdInfo);
        CmdInfo^.Flags := [];
        CmdInfo^.Callback := nil;
        FCommandQueue.AddObject('-exec-continue', TObject(CmdInfo));
      end
      else Break;
    end;
  until not R;
end;

function TGDBMIDebugger.ExePaths: String;
begin
  Result := '/usr/bin/gdb;/usr/local/bin/gdb;/opt/fpc/gdb';
end;

function TGDBMIDebugger.FindBreakpoint(
  const ABreakpoint: Integer): TDBGBreakPoint;
var
  n: Integer;
begin
  if  ABreakpoint > 0
  then
    for n := 0 to Breakpoints.Count - 1 do
    begin
      Result := Breakpoints[n];
      if TGDBMIBreakPoint(Result).FBreakID = ABreakpoint
      then Exit;
    end;
  Result := nil;
end;

function TGDBMIDebugger.GetClassName(const AClass: TDBGPtr): String;
var
  S: String;
begin
  // format has a problem with %u, so use Str for it
  Str(AClass, S);
  Result := GetClassName(S, []);
end;

function TGDBMIDebugger.GetClassName(const AExpression: String; const AValues: array of const): String;
var
  OK: Boolean;
  S: String;
  ResultList: TStrings;
begin
  Result := '';

  if dfImplicidTypes in FDebuggerFlags
  then begin
    OK :=  ExecuteCommand(
          '-data-evaluate-expression ^^shortstring(' + AExpression + '+12)^^',
          AValues,
          S, [cfIgnoreError]);
  end
  else begin
    Str(TDbgPtr(GetData(AExpression + '+12', AValues)), S);
    OK := ExecuteCommand('-data-evaluate-expression pshortstring(%s)^',
          [S],
          S, [cfIgnoreError]);
  end;

  if OK
  then begin
    ResultList := CreateMIValueList(S);
    S := ResultList.Values['value'];
    Result := GetPart('''', '''', S);
    ResultList.Free;
  end;
end;

function TGDBMIDebugger.GetInstanceClassName(const AInstance: TDBGPtr): String;
var
  S: String;
begin
  Str(AInstance, S);
  Result := GetInstanceClassName(S, []);
end;

function TGDBMIDebugger.GetInstanceClassName(const AExpression: String; const AValues: array of const): String;
begin
  if dfImplicidTypes in FDebuggerFlags
  then begin
    Result := GetClassName('^pointer(' + AExpression + ')^', AValues);
  end
  else begin
    Result := GetClassName(Int64(GetData(AExpression, AValues)));
  end;
end;

function TGDBMIDebugger.GDBEnvironment(const AVariable: String; const ASet: Boolean): Boolean;
var
  S: String;
begin
  Result := True;

  if State = dsRun
  then GDBPause(True);
  if ASet
  then ExecuteCommand('-gdb-set env %s', [AVariable], [cfIgnoreState, cfExternal])
  else begin
    S := AVariable;
    ExecuteCommand('unset env %s', [GetPart([], ['='], S, False, False)], [cfNoMiCommand, cfIgnoreState, cfExternal]);
  end;
end;

function TGDBMIDebugger.GDBEvaluate(const AExpression: String;
  var AResult: String): Boolean;
  
  function MakePrintable(const AString: String): String;
  var
    n: Integer;
    InString: Boolean;
  begin
    Result := '';
    InString := False;
    for n := 1 to Length(AString) do
    begin
      case AString[n] of
        ' '..#127: begin
          if not InString
          then begin
            InString := True;
            Result := Result + '''';
          end;
          Result := Result + AString[n];
          if AString[n] = '''' then Result := Result + '''';
        end;
      else
        if InString
        then begin
          InString := False;
          Result := Result + '''';
        end;
        Result := Result + Format('#%d', [Ord(AString[n])]);
      end;
    end;
    if InString
    then Result := Result + '''';
  end;
  
var
  ResultState: TDBGState;
  S, ResultValues: String;
  ResultList: TStringList;
  ResultInfo: TGDBType;
  addr: TDbgPtr;
  e: Integer;
//  Expression: TGDBMIExpression;
begin
// TGDBMIExpression was an attempt to make expression evaluation on Objects possible for GDB <= 5.2
// It is not completed and buggy. Since 5.3 expression evaluation is OK, so maybe in future the
// TGDBMIExpression will be completed to support older gdb versions
(*
  Expression := TGDBMIExpression.Create(Self, AExpression);
  if not Expression.GetExpression(S)
  then S := AExpression;
  WriteLN('[GDBEval] AskExpr: ', AExpression, ' EvalExp:', S ,' Dump: ',
          Expression.DumpExpression);
  Expression.Free;
*)
  S := AExpression;

  Result := ExecuteCommand('-data-evaluate-expression %s', [S], ResultState,
                           ResultValues, [cfIgnoreError, cfExternal]);

  ResultList := CreateMIValueList(ResultValues);
  if ResultState = dsError
  then AResult := ResultList.Values['msg']
  else AResult := ResultList.Values['value'];
  ResultList.Free;
  if ResultState = dsError
  then Exit;

  // Check for strings
  ResultInfo := GetGDBTypeInfo(S);
  if (ResultInfo = nil) then Exit;
  
  try
    case ResultInfo.Kind of
      skPointer: begin
        Val(AResult, addr, e);
        if e <> 0 then Exit;

        S := Lowercase(ResultInfo.TypeName);
        if (S = 'character')
        or (S = 'ansistring')
        then begin
          if Addr = 0
          then AResult := ''''''
          else AResult := MakePrintable(GetText(Addr));
        end
        else begin
          if Addr = 0
          then AResult := 'nil';
          if S = 'pointer' then Exit;
          if Length(S) = 0 then Exit;
          if S[1] = 't'
          then begin
            S[1] := 'T';
            if Length(S) > 1 then S[2] := UpperCase(S[2])[1];
          end;
          AResult := '^' + S + ' ' + AResult;
        end;
      end;
      skClass: begin
        Val(AResult, addr, e);
        if e <> 0 then Exit;

        S := GetInstanceClassName(Addr);
        if S = '' then S := '???';
        AResult := S + ' ' + AResult;
      end;
    end;
  finally
    ResultInfo.Free;
  end;
end;

function TGDBMIDebugger.GDBJumpTo(const ASource: String;
  const ALine: Integer): Boolean;
begin
  Result := False;
end;

function TGDBMIDebugger.GDBPause(const AInternal: Boolean): Boolean;
begin
  // Check if we already issued a break
  if FPauseWaitState = pwsNone
  then InterruptTarget;

  if AInternal
  then begin
    if FPauseWaitState = pwsNone
    then FPauseWaitState := pwsInternal;
  end
  else FPauseWaitState := pwsExternal;

  Result := True;
end;

function TGDBMIDebugger.GDBRun: Boolean;
begin
  Result := False;
  case State of
    dsStop: begin
      Result := StartDebugging('-exec-continue');
    end;
    dsPause: begin
      Result := ExecuteCommand('-exec-continue', [cfExternal]);
    end;
    dsIdle: begin
      DebugLn('[WARNING] Debugger: Unable to run in idle state');
    end;
  end;
end;

function TGDBMIDebugger.GDBRunTo(const ASource: String;
  const ALine: Integer): Boolean;
begin
  Result := False;
  case State of
    dsStop: begin
      Result := StartDebugging(Format('-exec-until %s:%d', [ASource, ALine]));
    end;
    dsPause: begin
      Result := ExecuteCommand('-exec-until %s:%d', [ASource, ALine], [cfExternal]);
    end;
    dsIdle: begin
      DebugLn('[WARNING] Debugger: Unable to runto in idle state');
    end;
  end;

end;

function TGDBMIDebugger.GDBStepInto: Boolean;
begin
  Result := False;
  case State of
    dsStop: begin
      Result := StartDebugging('');
    end;
    dsPause: begin
      Result := ExecuteCommand('-exec-step', [cfExternal]);
    end;
    dsIdle: begin
      DebugLn('[WARNING] Debugger: Unable to step in idle state');
    end;
  end;
end;

function TGDBMIDebugger.GDBStepOver: Boolean;
begin
  Result := False;
  case State of
    dsStop: begin
      Result := StartDebugging('');
    end;
    dsPause: begin
      Result := ExecuteCommand('-exec-next', [cfExternal]);
    end;
    dsIdle: begin
      DebugLn('[WARNING] Debugger: Unable to step over in idle state');
    end;
  end;
end;

function TGDBMIDebugger.GDBStop: Boolean;
begin
  Result := False;

  if State = dsError
  then begin
    // We don't know the state of the debugger, 
    // force a reinit. Let's hope this works.
    DebugProcess.Terminate(0);
    Done;
    Result := True;
    Exit;
  end;

  if State = dsRun
  then GDBPause(True);

  // not supported yet
  // ExecuteCommand('-exec-abort');
  ExecuteCommand('kill', [cfNoMiCommand], @GDBStopCallback, 0);
end;

procedure TGDBMIDebugger.GDBStopCallback(var AResultState: TDBGState; var AResultValues: String; const ATag: Integer );
var
  S: String;
begin
  // verify stop
  if not ExecuteCommand('info program', [], S, [cfNoMICommand]) then Exit;

  if Pos('not being run', S) > 0
  then SetState(dsStop);
end;

function TGDBMIDebugger.GetGDBTypeInfo(const AExpression: String): TGDBType;
var
  ResultState: TDBGState;
  ResultValues: String;
begin
  if not ExecuteCommand('ptype %s', [AExpression], ResultState, ResultValues,
                        [cfIgnoreError, cfNoMiCommand])
  or (ResultState = dsError)
  then begin
    Result := nil;
  end
  else begin
    Result := TGdbType.CreateFromValues(ResultValues);
  end;
end;

function TGDBMIDebugger.GetData(const ALocation: TDbgPtr): TDbgPtr;
var
  S: String;
begin
  Str(ALocation, S);
  Result := GetData(S, []);
end;

function TGDBMIDebugger.GetData(const AExpression: String;
  const AValues: array of const): TDbgPtr;
var
  S: String;
  e: Integer;
begin
  Result := 0;
  if ExecuteCommand('x/d ' + AExpression, AValues, S, [cfNoMICommand])
  then Val(StripLN(GetPart('\t', '', S)), Result, e);
end;

function TGDBMIDebugger.GetIntValue(const AExpression: String; const AValues: array of const): Integer;
var
  e: Integer;
begin
  Result := 0;
  Val(GetStrValue(AExpression, AValues), Result, e);
end;

function TGDBMIDebugger.GetPtrValue(const AExpression: String; const AValues: array of const): TDbgPtr;
var
  e: Integer;
begin
  Result := 0;
  Val(GetStrValue(AExpression, AValues), Result, e);
end;

function TGDBMIDebugger.GetStrValue(const AExpression: String; const AValues: array of const): String;
var
  S: String;
  ResultList: TStringList;
begin
  if ExecuteCommand('-data-evaluate-expression %s', [Format(AExpression, AValues)], S, [cfIgnoreError])
  then begin
    ResultList := CreateMIValueList(S);
    Result := ResultList.Values['value'];
    ResultList.Free;
  end
  else Result := '';
end;

function TGDBMIDebugger.GetText(const ALocation: TDBGPtr): String;
var
  S: String;
begin
  Str(ALocation, S);
  Result := GetText(S, []);
end;

function TGDBMIDebugger.GetText(const AExpression: String;
  const AValues: array of const): String;
var
  S: String;
  n, len, idx: Integer;
  v: Integer;
begin
  if not ExecuteCommand('x/s ' + AExpression, AValues, S, [cfNoMICommand, cfIgnoreError])
  then begin
    Result := '';
  end
  else begin
    S := StripLN(S);
    // don't use ' as end terminator, there might be one as part of the text
    // since ' will be the last char, simply strip it.
    S := GetPart(['\t '], [], S);

    // Scan the string
    len := Length(S);
    SetLength(Result, len);
    n := 0;
    idx := 1;
    while idx <= len do
    begin
      case S[idx] of
        '''': begin
          Inc(idx);
          // scan till end
          while idx <= len do
          begin
            if S[idx] = ''''
            then begin
              Inc(idx);
              if idx > len then Break;
              if S[idx] <> '''' then Break;
            end;
            Inc(n);
            Result[n] := S[idx];
            Inc(idx);
          end;
        end;
        '#': begin
          Inc(idx);
          v := 0;
          // scan till non number (correct input is assumed)
          while (idx <= len) and (S[idx] >= '0') and (S[idx] <= '9') do
          begin
            v := v * 10 + Ord(S[idx]) - Ord('0');
            Inc(idx)
          end;
          Inc(n);
          Result[n] := Chr(v and $FF);
        end;
      else
        Break; //??
      end;
    end;
    SetLength(Result, n);
  end;
end;

function TGDBMIDebugger.GetSupportedCommands: TDBGCommands;
begin
  Result := [dcRun, dcPause, dcStop, dcStepOver, dcStepInto, dcRunTo, dcJumpto,
             dcBreak{, dcWatch}, dcLocal, dcEvaluate, dcModify, dcEnvironment]
end;

procedure TGDBMIDebugger.Init;
  procedure ResolveGDBVersion;
  var
    S: String;
  begin
    FVersion := '';
    if not ExecuteCommand('-gdb-version', [], S, [cfNoMiCommand]) // No MI since the output is no MI
    then Exit;
    
    FVersion := GetPart(['('], [')'], S, False, False);
    if FVersion <> '' then Exit;
    
    FVersion := GetPart(['gdb '], [#10, #13], S, True, False);
    if FVersion <> '' then Exit;
  end;
begin
  FPauseWaitState := pwsNone;
  FInExecuteCount := 0;
  
  if CreateDebugProcess('-silent -i mi -nx')
  then begin
    if not ParseInitialization
    then begin
      SetState(dsError);
      Exit;                             
    end;
    
    ExecuteCommand('-gdb-set confirm off', []);
    // for win32, turn off a new console otherwise breaking gdb will fail
    // ignore the error on other platforms
    ExecuteCommand('-gdb-set new-console off', [cfIgnoreError]);
    
    // try to find the debugger version
    ResolveGDBVersion;
    if FVersion < '5.3'
    then begin
      DebugLn('[WARNING] Debugger: Running an old (< 5.3) GDB version: ', FVersion);
      DebugLn('                    Not all functionality will be supported.');
    end
    else begin
      DebugLn('[Debugger] Running GDB version: ', FVersion);
      Include(FDebuggerFlags, dfImplicidTypes);
    end;

    inherited Init;
  end
  else begin
    if DebugProcess = nil
    then MessageDlg('Debugger', 'Failed to create debug process for unknown reason', mtError, [mbOK], 0)
    else MessageDlg('Debugger', Format('Failed to create debug process: %s', [ReadLine]), mtError, [mbOK], 0);
    SetState(dsError);
  end;
end;

procedure TGDBMIDebugger.InterruptTarget;
{$IFDEF WIN32}
  function TryNT: Boolean;
  var
    hProcess: THandle;
    hThread: THandle;
    ThreadID: Cardinal;
    E: Integer;
    Emsg: PChar;
  begin                  
    Result := False;
    
    hProcess := OpenProcess(PROCESS_CREATE_THREAD or PROCESS_QUERY_INFORMATION or PROCESS_VM_OPERATION or PROCESS_VM_WRITE or PROCESS_VM_READ, False, TargetPID);
    if hProcess = 0 then Exit;
  
    try
      hThread := _CreateRemoteThread(hProcess, nil, 0, DebugBreakAddr, nil, 0, ThreadID);
      if hThread = 0
      then begin
        E := GetLastError;
        FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ALLOCATE_BUFFER, nil, E, 0, @Emsg, 0, nil);
        DebugLN('Error creating remote thread: ' + String(EMsg));
        // Yuck !
        // mixing handles and pointers, but it is how MS documented it
        LocalFree(HLOCAL(Emsg));
        Exit;
      end;
      Result := True;
      CloseHandle(hThread);

      // queue an info to find out if we are stopped in our interrupt thread
      ExecuteCommand('info program', [cfNoMICommand], @InterruptTargetCallback, ThreadID);
    finally
      CloseHandle(hProcess);
    end;
  end;
{$ENDIF}
begin
  if TargetPID = 0 then Exit;
{$IFDEF UNIX}
  {$IFDEF Ver1_0}Kill{$ELSE}FpKill{$ENDIF}(TargetPID, SIGINT);
{$ENDIF}

{$IFDEF WIN32}
  // GenerateConsoleCtrlEvent is nice, but only works if both gdb and
  // our target have a console. On win95 and family this is our only
  // option, on NT4+ we have a choice. Since this is not likely that
  // we have a console, we do it the hard way. On XP there exists 
  // DebugBreakProcess, but it does efectively the same.
  
  if (DebugBreakAddr = nil)
  or not Assigned(_CreateRemoteThread)
  or not TryNT
  then begin
    // We have no other choice than trying this
    GenerateConsoleCtrlEvent(CTRL_BREAK_EVENT, TargetPID);
    Exit;
  end;   
{$ENDIF}
end;

{$IFDEF WIN32}
procedure TGDBMIDebugger.InterruptTargetCallback(var AResultState: TDBGState; var AResultValues: String; const ATag: Integer);
var
  S: String;
  List: TStringList;
  n: Integer;
  ID1, ID2: Integer;
begin
  // check if we need to get out of the interrupt thread
  S := AResultValues;
  S := GetPart(['.0x'], ['.'], S, True, False);
  if StrToIntDef('$'+S, 0) <> ATag then Exit;

  // we're stopped in our thread
  if FPauseWaitState = pwsInternal then Exit; // internal, dont care
  
  S := '';
  if not ExecuteCommand('-thread-list-ids', S, [cfIgnoreError]) then Exit;
  List := CreateMIValueList(S);
  try
    n := StrToIntDef(List.Values['number-of-threads'], 0);
    if n < 2 then Exit; //nothing to switch
    S := List.Values['thread-ids'];
  finally
    List.Free;
  end;
  List := CreateMIValueList(S);
  ID1 := StrToIntDef(List.Values['thread-id'], 0);
  List.Delete(0);
  ID2 := StrToIntDef(List.Values['thread-id'], 0);
  List.Free;
  if ID1 = ID2 then Exit;
  
  if not ExecuteCommand('-thread-select %d', [ID2], S, [cfIgnoreError]) then Exit;
end;
{$ENDIF}

function TGDBMIDebugger.ParseInitialization: Boolean;
var
  Line, S: String;
begin
  Result := True;

  // Get initial debugger lines
  S := '';
  Line := StripLN(ReadLine);
  while DebugProcessRunning and (Line <> '(gdb) ') do
  begin
    S := S + Line + LineEnding;
    Line := StripLN(ReadLine);
  end;
  if S <> ''
  then MessageDlg('Debugger', 'Initialization output: ' + LineEnding + S,
    mtInformation, [mbOK], 0);
end;

function TGDBMIDebugger.ProcessResult(var ANewState: TDBGState;
  var AResultValues: String; const ANoMICommand: Boolean): Boolean;
var
  S: String;
begin
  Result := False;
  AResultValues:='';
  S := StripLN(ReadLine);
  ANewState := dsNone;
  while DebugProcessRunning and (S <> '(gdb) ') do
  begin
    if S <> ''
    then begin
      case S[1] of
        '^': begin // result-record
          if ANoMICommand
          then begin
            S := GetPart('^', ',', S);
          end
          else begin
            AResultValues := S;
            S := GetPart('^', ',', AResultValues);
          end;
          if S = 'done'
          then begin
            Result := True;
          end
          else if S = 'running'
          then begin
            Result := True;
            ANewState := dsRun;
          end
          else if S = 'error'
          then begin
            Result := True;
            DebugLn('TGDBMIDebugger.ProcessResult Error: ',S);
            // todo implement with values
            if  (pos('msg=', AResultValues) > 0)
            and (pos('not being run', AResultValues) > 0)
            then ANewState := dsStop
            else ANewState := dsError;
          end
          else if S = 'exit'
          then begin
            Result := True;
            ANewState := dsIdle;
          end
          else DebugLn('[WARNING] Debugger: Unknown result class: ', S);
        end;
        '~': begin // console-stream-output
          // check for symbol info
          if Pos('no debugging symbols', S) > 0
          then begin
            Exclude(FTargetFlags, tfHasSymbols);
            DebugLn('[WARNING] Debugger: File ''',FileName, ''' has no debug symbols');
          end
          else if ANoMICommand 
          then begin
            // Strip surrounding ~" "
            S := Copy(S, 3, Length(S) - 3);
            if (RightStr(S, 2) = '\n') and (RightStr(S, 3) <> '\\n')
            then begin
              // Delete lineend symbol & add lineend
              S := Copy(S, 1, Length(S) - 2) + LineEnding;
            end;
            AResultValues := AResultValues + S;
          end
          else begin
            DebugLn('[Debugger] Console output: ', S);
          end;
        end;
        '@': begin // target-stream-output
          DebugLn('[Debugger] Target output: ', S);
        end;
        '&': begin // log-stream-output
          DebugLn('[Debugger] Log output: ', S);
          if S='&"kill\n"' then
            ANewState:=dsStop
          else if LeftStr(S,8)='&"Error ' then
            ANewState:=dsError;
        end;
        '*', '+', '=': begin
          DebugLn('[WARNING] Debugger: Unexpected async-record: ', S);
        end;
      else
        DebugLn('[WARNING] Debugger: Unknown record: ', S);
      end;
    end;
    S := StripLN(ReadLine);
  end;
end;

function TGDBMIDebugger.ProcessRunning(var AStoppedParams: String): Boolean;
var
  S, AsyncClass: String;
  idx: Integer;
begin
  Result := True;
  S := StripLN(ReadLine);
  while DebugProcessRunning and (S <> '(gdb) ') do
  begin
    if S <> ''
    then begin
      case S[1] of
        '^': begin
          DebugLn('[WARNING] Debugger: unexpected result-record: ', S);
        end;
        '~': begin // console-stream-output
          DebugLn('[Debugger] Console output: ', S);
        end;
        '@': begin // target-stream-output
          DebugLn('[Debugger] Target output: ', S);
        end;
        '&': begin // log-stream-output
          DebugLn('[Debugger] Log output: ', S);
        end;
        '*': begin // exec-async-output
          AsyncClass := GetPart('*', ',', S);
          if AsyncClass = 'stopped'
          then begin
            AStoppedParams := S;
          end
          // Known, but undocumented classes
          else if AsyncClass = 'started'
          then begin
          end
          else if AsyncClass = 'disappeared'
          then begin
          end
          else begin
            // Assume targetoutput, strip char and continue
            DebugLn('[DBGTGT] *');
            S := AsyncClass + S;
            Continue;
          end;
        end;
        '+': begin // status-async-output
          DebugLn('[Debugger] Status output: ', S);
        end;
        '=': begin // notify-async-output
          DebugLn('[Debugger] Notify output: ', S);
        end;
      else
        // since target output isn't prefixed (yet?)
        // one of our known commands could be part of it.
        idx := Pos('*stopped', S);
        if idx  > 0
        then begin
          DebugLn('[DBGTGT] ', Copy(S, 1, idx - 1));
          Delete(S, 1, idx - 1);
          Continue;
        end
        else begin
          // normal target output
          DebugLn('[DBGTGT] ', S);
        end;
      end;
    end;
    S := StripLN(ReadLine);
  end;
end;

function TGDBMIDebugger.ProcessStopped(const AParams: String; const AIgnoreSigIntState: Boolean): Boolean;
  procedure ProcessFrame(const AFrame: String);
  var
    Frame: TStringList;
    Location: TDBGLocationRec;
    e: Integer;
  begin
    Frame := CreateMIValueList(AFrame);

    Location.Address := 0;
    Val(Frame.Values['addr'], Location.Address, e);
    Location.FuncName := Frame.Values['func'];
    Location.SrcFile := Frame.Values['file'];
    Location.SrcLine := StrToIntDef(Frame.Values['line'], -1);

    Frame.Free;

    DoCurrent(Location);
  end;

  procedure ProcessException;
  var
    S: String;
    ObjAddr, ExceptionName, ExceptionMessage: String;
    ResultList: TStringList;
    Location: TDBGLocationRec;
    OK: Boolean;
  begin
    if tfRTLUsesRegCall in FTargetFlags
    then  ObjAddr := '$eax'
    else begin
      if dfImplicidTypes in FDebuggerFlags
      then ObjAddr := '^pointer($fp+8)^'
      else Str(GetData('$fp+8', []), ObjAddr);
    end;
    
(*
    if dfImplicidTypes in FDebuggerFlags
    then begin
      OK :=  ExecuteCommand(
            '-data-evaluate-expression ^^shortstring(^pointer(%s)^+12)^^',
            [ObjAddr],
            S, [cfIgnoreError]);
    end
    else begin
      OK := ExecuteCommand('-data-evaluate-expression pshortstring(%u)^',
            [Integer(GetData(GetData(ObjAddr, [])+12))],
            S, [cfIgnoreError]);
    end;

    if OK
    then begin
      ResultList := CreateMIValueList(S);
      ExceptionName := ResultList.Values['value'];
      ExceptionName := GetPart('''', '''', ExceptionName);
      ResultList.Free;
    end;
*)
    ExceptionName := GetInstanceClassName(ObjAddr, []);
    if ExceptionName = ''
    then ExceptionName := 'Unknown';

    // check if we should ignore this exception
    if Exceptions.Find(ExceptionName) <> nil
    then begin
      ExecuteCommand('-exec-continue', []);
      Exit;
    end;

    if dfImplicidTypes in FDebuggerFlags
    then begin
      ExceptionMessage := GetText('^Exception(%s)^.FMessage', [ObjAddr]);
      //ExceptionMessage := GetText('^^Exception($fp+8)^^.FMessage', []);
      ExceptionMessage := DeleteEscapeChars(ExceptionMessage, '\');
    end
    else ExceptionMessage := '### Not supported on GDB < 5.3 ###';

    Location.SrcLine := -1;
    Location.SrcFile := '';
    Location.FuncName := '';
    if tfRTLUsesRegCall in FTargetFlags
    then Location.Address := GetPtrValue('$edx', [])
    else Location.Address := GetData('$fp+12', []);
    
    if ExecuteCommand('info line * pointer(%d)', [Integer(Location.Address)],
                      S, [cfIgnoreError, cfNoMiCommand])
    then begin
      Location.SrcLine := StrToIntDef(GetPart('Line ', ' of', S), -1);
      Location.SrcFile := GetPart('\"', '\"', S);
    end;

    DoException(ExceptionName, ExceptionMessage);
    DoCurrent(Location);
  end;
  
  procedure ProcessBreak;
  var
    S: String;
    ErrorNo: Integer;
    Location: TDBGLocationRec;
  begin
    if tfRTLUsesRegCall in FTargetFlags
    then ErrorNo := GetIntValue('$eax', [])
    else ErrorNo := Integer(GetData('$fp+8', []));
    
    Location.SrcLine := -1;
    Location.SrcFile := '';
    if tfRTLUsesRegCall in FTargetFlags
    then Location.Address := GetPtrValue('$edx', [])
    else Location.Address := GetData('$fp+12', []);
    Location.FuncName := '';
    Str(Location.Address, S);
    if ExecuteCommand('info line * pointer(%s)', [S], S, [cfIgnoreError, cfNoMiCommand])
    then begin
      Location.SrcLine := StrToIntDef(GetPart('Line ', ' of', S), -1);
      Location.SrcFile := GetPart('\"', '\"', S);
    end;

    DoException(Format('RunError(%d)', [ErrorNo]), '');
    DoCurrent(Location);
  end;
  
  procedure ProcessRunError;
  var
    S: String;
    ErrorNo: Integer;
    List: TStrings;
  begin
    if tfRTLUsesRegCall in FTargetFlags
    then ErrorNo := GetIntValue('$eax', [])
    else ErrorNo := Integer(GetData('$fp+8', []));

    DoException(Format('RunError(%d)', [ErrorNo]), '');

    if ExecuteCommand('-stack-list-frames 1 1', [], S, [cfIgnoreError])
    then begin
      List := CreateMIValueList(S);
      S := List.Values['stack'];
      FreeAndNil(List);
      List := CreateMIValueList(S);
      S := List.Values['frame'];
      FreeAndNil(List);
      ProcessFrame(S);
    end;
  end;

  procedure ProcessSignalReceived(const AList: TStringList);
  var
    SigInt: Boolean;
    S: String;
  begin
    // TODO: check to run (un)handled

    S := AList.Values['signal-name'];
    {$IFDEF WIN32}
    SigInt := S = 'SIGTRAP';
    {$ELSE}
    SigInt := S = 'SIGINT';
    {$ENDIF}
    if not AIgnoreSigIntState
    or not SigInt
    then SetState(dsPause);
    
    if not SigInt
    then DoException('External: ' + S, '');
    
    if not AIgnoreSigIntState
    or not SigInt
    then ProcessFrame(AList.Values['frame']);
  end;

var
  List: TStringList;
  Reason: String;
  BreakID: Integer;
  BreakPoint: TGDBMIBreakPoint;
  CanContinue: Boolean;
begin
  Result := True;
  List := CreateMIValueList(AParams);
  try
    Reason := List.Values['reason'];
    if (Reason = 'exited-normally')
    then begin
      SetState(dsStop);
      Exit;
    end;
    
    if Reason = 'exited'
    then begin
      SetExitCode(StrToIntDef(List.Values['exit-code'], 0));
      SetState(dsStop);
      Exit;
    end;
    
    if Reason = 'exited-signalled'
    then begin
      SetState(dsStop);
      DoException('External: ' + List.Values['signal-name'], '');
      // ProcessFrame(List.Values['frame']);
      Exit;
    end;
    
    if Reason = 'signal-received'
    then begin
      ProcessSignalReceived(List);
      Exit;
    end;   
    
    if Reason = 'breakpoint-hit'
    then begin
      BreakID := StrToIntDef(List.Values['bkptno'], -1);
      if BreakID = -1
      then begin
        SetState(dsError);
        // ???
        Exit;
      end;

      if BreakID = FBreakErrorBreakID
      then begin
        SetState(dsPause);
        ProcessBreak;
        Exit;
      end;

      if BreakID = FRunErrorBreakID
      then begin
        SetState(dsPause);
        ProcessRunError;
        Exit;
      end;
      
      if BreakID = FExceptionBreakID
      then begin
        SetState(dsPause);
        ProcessException;
        Exit;
      end;
      
      BreakPoint := TGDBMIBreakPoint(FindBreakpoint(BreakID));
      if BreakPoint <> nil
      then begin
        CanContinue := False;
        BreakPoint.Hit(CanContinue);
        if CanContinue
        then begin
          ExecuteCommand('-exec-continue', []);
        end
        else begin
          SetState(dsPause);
          ProcessFrame(List.Values['frame']);
        end;
      end;
      Exit;
    end;
    
    if Reason = 'function-finished'
    then begin
      SetState(dsPause);
      ProcessFrame(List.Values['frame']);
      Exit;
    end;
    
    if Reason = 'end-stepping-range'
    then begin
      SetState(dsPause);
      ProcessFrame(List.Values['frame']);
      Exit;
    end;
    
    if Reason = 'location-reached'
    then begin
      SetState(dsPause);
      ProcessFrame(List.Values['frame']);
      Exit;
    end;
    
    Result := False;
    DebugLn('[WARNING] Debugger: Unknown stopped reason: ', Reason);
  finally
    List.Free;
  end; 
end;

function TGDBMIDebugger.RequestCommand(const ACommand: TDBGCommand; const AParams: array of const): Boolean;
begin
  case ACommand of
    dcRun:      Result := GDBRun;
    dcPause:    Result := GDBPause(False);
    dcStop:     Result := GDBStop;
    dcStepOver: Result := GDBStepOver;
    dcStepInto: Result := GDBStepInto;
    dcRunTo:    Result := GDBRunTo(String(APArams[0].VAnsiString), APArams[1].VInteger);
    dcJumpto:   Result := GDBJumpTo(String(APArams[0].VAnsiString), APArams[1].VInteger);
    dcEvaluate: Result := GDBEvaluate(String(APArams[0].VAnsiString), String(APArams[1].VPointer^));
    dcEnvironment: Result := GDBEnvironment(String(APArams[0].VAnsiString), AParams[1].VBoolean);
  end;
end;

procedure TGDBMIDebugger.ClearCommandQueue;
var
  CmdInfo: PGDBMICmdInfo;
  i: Integer;
begin
  for i:=0 to FCommandQueue.Count-1 do begin
    CmdInfo:=PGDBMICmdInfo(FCommandQueue.Objects[i]);
    if CmdInfo<>nil then Dispose(CmdInfo);
  end;
  FCommandQueue.Clear;
end;

function TGDBMIDebugger.StartDebugging(const AContinueCommand: String): Boolean;
  function CheckFunction(const AFunction: String): Boolean;
  var
    S: String;
    idx: Integer;
  begin
    ExecuteCommand('info functions %s', [AFunction],
                    S, [cfIgnoreError, cfNoMICommand]);
    idx := Pos(AFunction, S);
    if idx <> 0
    then begin
      // Strip first
      Delete(S, 1, idx + Length(AFunction) - 1);
      idx := Pos(AFunction, S);
    end;
    Result := idx <> 0;
  end;

  procedure RetrieveRegcall;
  var
    S: String;
    ResultState: TDBGState;
  begin
    // Assume it is
    Include(FTargetFlags, tfRTLUsesRegCall);

    ExecuteCommand('-data-evaluate-expression FPC_THREADVAR_RELOCATE_PROC', [],
                    ResultState, S, [cfIgnoreError]);
    if ResultState <> dsError then Exit; // guessed right
    
    // next attempt, posibly no symbols, try functions
    if CheckFunction('FPC_CPUINIT') then Exit; // function present --> not 1.0

    // this runerror is only defined for < 1.1 ?
    if not CheckFunction('$$_RUNERROR$') then Exit;

    // We are here in 2 cases
    // 1) there are no symbols at all
    //    We dont have to know the calling convention
    // 2) target is compiled with an earlier version than 1.9.2
    //    params are passes by stack
    Exclude(FTargetFlags, tfRTLUsesRegCall);
  end;
  
  function InsertBreakPoint(const AName: String): Integer;
  var
    S: String;
    ResultList, BkptList: TStringList;
    ResultState: TDBGState;
  begin
    ExecuteCommand('-break-insert %s', [AName], ResultState, S, [cfIgnoreError]);
    if ResultState <> dsError
    then begin
      ResultList := CreateMIValueList(S);
      BkptList := CreateMIValueList(ResultList.Values['bkpt']);
      Result := StrToIntDef(BkptList.Values['number'], -1);
      ResultList.Free;
      BkptList.Free;
    end;
  end;

var
  S, FileType, EntryPoint: String;
  ResultState: TDBGState;
  TargetPIDPart: String;
  TempInstalled: Boolean;
begin
  if not (State in [dsStop])
  then begin
    Result := True;
    Exit;
  end;

  if WorkingDir <> ''
  then ExecuteCommand('-environment-cd %s', [WorkingDir], []);

  FTargetFlags := [tfHasSymbols]; // Set until proven otherwise

  // check if the exe is compiled with FPC >= 1.9.2
  // then the rtl is compiled with regcalls
  RetrieveRegCall;

  if Arguments <>''
  then ExecuteCommand('-exec-arguments %s', [Arguments], [cfIgnoreError]);
  
  if tfHasSymbols in FTargetFlags
  then begin
    // Make sure we are talking pascal
    ExecuteCommand('-gdb-set language pascal', []);
    ExecuteCommand('-break-insert -t main', [], ResultState, S, [cfIgnoreError]);
    TempInstalled := ResultState <> dsError;
  end
  else begin
    DebugLn('TGDBMIDebugger.StartDebugging Note: Target has no symbols');
    TempInstalled := False;
  end;
  
  // try Insert Break breakpoint
  // we might have rtl symbols
  if FExceptionBreakID = -1
  then FExceptionBreakID := InsertBreakPoint('FPC_RAISEEXCEPTION');
  if FBreakErrorBreakID = -1
  then FBreakErrorBreakID := InsertBreakPoint('FPC_BREAK_ERROR');
  if FRunErrorBreakID = -1
  then FRunErrorBreakID := InsertBreakPoint('FPC_RUNERROR');

  
  // try to retrieve the filetype and program entry point
  if ExecuteCommand('info file', [], ResultState, S, [cfIgnoreError, cfNoMICommand])
  then begin
     FileType := GetPart('file type ', '.', S);
     EntryPoint := GetPart('Entry point: ', '\n', S);
     DebugLn('[Debugger] File type: ', FileType);
     DebugLn('[Debugger] Entry point: ', EntryPoint);
  end;
  
  // TODO: use filetype to determine register types
  
  if not TempInstalled and (Length(EntryPoint) > 0)
  then begin
    // We could not set our initial break to get info and allow stepping
    // Try it with the program entry point
    ExecuteCommand('-break-insert -t *%s', [EntryPoint], ResultState, S, [cfIgnoreError]);
    TempInstalled := ResultState <> dsError;
  end;
  
  // fire the first step
  if TempInstalled
  then ExecuteCommand('-exec-run', []);


  // try to find PID
  if ExecuteCommand('info program', [], ResultState, S, [cfIgnoreError, cfNoMICommand])
  then begin
     TargetPIDPart := GetPart(['child process ', 'child thread ', 'lwp '], 
                              [' ', '.', ')'], S, True);
     FTargetPID := StrToIntDef(TargetPIDPart, 0);
     DebugLn('[Debugger] Target PID: ', IntToStr(FTargetPID));
  end
  else begin
    FTargetPID := 0;
  end;

  if FTargetPID = 0
  then begin
    Result := False;
    SetState(dsError);
    Exit;
  end;
  
  if ResultState = dsNone
  then begin
    SetState(dsInit);
    if AContinueCommand <> ''
    then Result := ExecuteCommand(AContinueCommand, [])
    else SetState(dsPause);
  end
  else SetState(ResultState);

  Result := True;
end;

procedure TGDBMIDebugger.TestCmd(const ACommand: String);
begin
  ExecuteCommand(ACommand, [cfIgnoreError]);
end;

{ =========================================================================== }
{ TGDBMIBreakPoint }
{ =========================================================================== }

constructor TGDBMIBreakPoint.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FBreakID := 0;
end;

destructor TGDBMIBreakPoint.Destroy;
begin
  ReleaseBreakPoint;
  inherited Destroy;
end;

procedure TGDBMIBreakPoint.DoEnableChange;
begin
  UpdateEnable;
  inherited;
end;

procedure TGDBMIBreakPoint.DoExpressionChange;
begin
  UpdateExpression;
  inherited;
end;

procedure TGDBMIBreakPoint.DoStateChange(const AOldState: TDBGState);
begin
  inherited DoStateChange(AOldState);
  
  case Debugger.State of
    dsInit: begin
      SetBreakpoint;
    end;
    dsStop: begin
      if AOldState = dsRun
      then ReleaseBreakpoint;
    end;
  end;
end;

procedure TGDBMIBreakPoint.Hit(var ACanContinue: Boolean);
begin
  DoHit(HitCount + 1, ACanContinue);
end;

procedure TGDBMIBreakPoint.SetBreakpoint;
begin
  if Debugger = nil then Exit;

  if FBreakID <> 0
  then ReleaseBreakPoint;

  if Debugger.State = dsRun
  then TGDBMIDebugger(Debugger).GDBPause(True);
  TGDBMIDebugger(Debugger).ExecuteCommand('-break-insert %s:%d',
    [ExtractFileName(Source), Line], [cfIgnoreError], @SetBreakPointCallback, 0);
  
end;

procedure TGDBMIBreakPoint.SetBreakPointCallback(var AResultState: TDBGState; var AResultValues: String; const ATag: Integer );
var
  ResultList, BkptList: TStringList;
begin
  BeginUpdate;
  try
    ResultList := CreateMIValueList(AResultValues);
    BkptList := CreateMIValueList(ResultList.Values['bkpt']);
    FBreakID := StrToIntDef(BkptList.Values['number'], 0);
    SetHitCount(StrToIntDef(BkptList.Values['times'], 0));
    if FBreakID <> 0
    then SetValid(vsValid)
    else SetValid(vsInvalid);
    UpdateExpression;
    UpdateEnable;
    ResultList.Free;
    BkptList.Free;
  finally
    EndUpdate;
  end;
end;

procedure TGDBMIBreakPoint.ReleaseBreakPoint;
begin
  if  (FBreakID <> 0)
  and (Debugger <> nil)
  then begin
    if Debugger.State = dsRun
    then TGDBMIDebugger(Debugger).GDBPause(True);
    TGDBMIDebugger(Debugger).ExecuteCommand('-break-delete %d', [FBreakID], []);
    FBreakID:=0;
    SetHitCount(0);
  end;
end;

procedure TGDBMIBreakPoint.SetLocation(const ASource: String;
  const ALine: Integer);
begin
  if (Source = ASource) and (Line = ALine) then exit;
  inherited;
  if Debugger = nil then Exit;
  if TGDBMIDebugger(Debugger).State in [dsStop, dsPause, dsRun]
  then SetBreakpoint;
end;

procedure TGDBMIBreakPoint.UpdateEnable;
const                         
  // Use shortstring as fix for fpc 1.9.5 [2004/07/15]
  CMD: array[Boolean] of ShortString = ('disable', 'enable');
begin
  if (FBreakID = 0)
  or (Debugger = nil)
  then Exit;

  if Debugger.State = dsRun
  then TGDBMIDebugger(Debugger).GDBPause(True);
  //writeln('TGDBMIBreakPoint.UpdateEnable Line=',Line,' Enabled=',Enabled,' InitialEnabled=',InitialEnabled);
  TGDBMIDebugger(Debugger).ExecuteCommand('-break-%s %d',
                                          [CMD[Enabled], FBreakID], []);
end;

procedure TGDBMIBreakPoint.UpdateExpression;
begin
end;

{ =========================================================================== }
{ TGDBMILocals }
{ =========================================================================== }

procedure TGDBMILocals.AddLocals(const AParams: String);
var
  n, e: Integer;
  addr: TDbgPtr;
  LocList, List: TStrings;
  S, Name, Value: String;
begin
  LocList := CreateMIValueList(AParams);
  for n := 0 to LocList.Count - 1 do
  begin
    List := CreateMIValueList(LocList[n]);
    Name := List.Values['name'];
    if Name = 'this'
    then Name := 'Self';

    Value := List.Values['value'];
    // try to deref. strings
    S := GetPart(['(pchar) ', '(ansistring) '], [], Value, True, False);
    if S <> ''
    then begin
      addr := 0;
      Val(S, addr, e);
      if addr = 0
      then Value := ''''''
      else Value := '''' + TGDBMIDebugger(Debugger).GetText(addr) + '''';
    end;

    FLocals.Add(Name + '=' + Value);
    FreeAndNil(List);
  end;
  FreeAndNil(LocList);
end;

constructor TGDBMILocals.Create(const ADebugger: TDebugger);
begin
  FLocals := TStringList.Create;
  FLocals.Sorted := True;
  FLocalsValid := False;
  inherited;
end;

destructor TGDBMILocals.Destroy;
begin
  inherited;
  FreeAndNil(FLocals);
end;

procedure TGDBMILocals.DoStateChange(const AOldState: TDBGState);
begin
  if  (Debugger <> nil)
  and (Debugger.State = dsPause)
  then begin
    DoChange;
  end
  else begin
    FLocalsValid := False;
    FLocals.Clear;
  end;
end;

function TGDBMILocals.GetCount: Integer;
begin
  if  (Debugger <> nil)
  and (Debugger.State = dsPause)
  then begin
    LocalsNeeded;
    Result := FLocals.Count;
  end
  else Result := 0;
end;

function TGDBMILocals.GetName(const AnIndex: Integer): String;
begin
  if  (Debugger <> nil)
  and (Debugger.State = dsPause)
  then begin
    LocalsNeeded;
    Result := FLocals.Names[AnIndex];
  end
  else Result := '';
end;

function TGDBMILocals.GetValue(const AnIndex: Integer): String;
begin
  if  (Debugger <> nil)
  and (Debugger.State = dsPause)
  then begin
    LocalsNeeded;
    Result := FLocals[AnIndex];
    Result := GetPart('=', '', Result);
  end
  else Result := '';
end;

procedure TGDBMILocals.LocalsNeeded;
var
  S: String;
  List: TStrings;
begin
  if Debugger = nil then Exit;
  if not FLocalsValid
  then begin
    // args
    TGDBMIDebugger(Debugger).ExecuteCommand('frame', S, []);
    List := CreateMIValueList(S);
    S := List.Values['frame'];
    FreeAndNil(List);
    List := CreateMIValueList(S);
    AddLocals(List.Values['args']);
    FreeAndNil(List);

    // variables
    TGDBMIDebugger(Debugger).ExecuteCommand('-stack-list-locals 1', S, []);
    List := CreateMIValueList(S);
    AddLocals(List.Values['locals']);
    FreeAndNil(List);
    FLocalsValid := True;
  end;
end;

{ =========================================================================== }
{ TGDBMIWatch }
{ =========================================================================== }

constructor TGDBMIWatch.Create(ACollection: TCollection);
begin
  FEvaluated := False;
  inherited;
end;

procedure TGDBMIWatch.DoEnableChange;
begin
  inherited;
end;

procedure TGDBMIWatch.DoExpressionChange;
begin
  FEvaluated := False;
  inherited;
end;

procedure TGDBMIWatch.DoStateChange(const AOldState: TDBGState);
begin
  if Debugger = nil then Exit;

  if Debugger.State in [dsPause, dsStop]
  then FEvaluated := False;
  if Debugger.State = dsPause then Changed;
end;

procedure TGDBMIWatch.EvaluationNeeded;
var
  ExprIsValid: Boolean;
begin
  if FEvaluated then Exit;
  if Debugger = nil then Exit;

  if (Debugger.State in [dsPause, dsStop])
  and Enabled
  then begin
    ExprIsValid:=TGDBMIDebugger(Debugger).GDBEvaluate(Expression, FValue);
    if ExprIsValid then
      SetValid(vsValid)
    else
      SetValid(vsInvalid);
  end
  else begin
    SetValid(vsInvalid);
  end;
  FEvaluated := True;
end;

function TGDBMIWatch.GetValue: String;
begin
  if  (Debugger <> nil)
  and (Debugger.State in [dsStop, dsPause])
  and Enabled
  then begin
    EvaluationNeeded;
    Result := FValue;
  end
  else Result := inherited GetValue;
end;

function TGDBMIWatch.GetValid: TValidState;
begin
  EvaluationNeeded;
  Result := inherited GetValid;
end;

{ =========================================================================== }
{ TGDBMICallStack }
{ =========================================================================== }

function TGDBMICallStack.CheckCount: Boolean;
var
  S: String;
  List: TStrings;
begin
  Result := inherited CheckCount;

  if not Result then Exit;

  TGDBMIDebugger(Debugger).ExecuteCommand('-stack-info-depth', S, []);
  List := CreateMIValueList(S);
  SetCount(StrToIntDef(List.Values['depth'], 0));
  FreeAndNil(List);
end;

function TGDBMICallStack.CreateStackEntry(const AIndex: Integer): TCallStackEntry;
var                 
  n: Integer;
  S: String;
  Arguments, ArgList, List: TStrings;
begin
  if Debugger = nil then Exit;

  Arguments := TStringList.Create;
  TGDBMIDebugger(Debugger).ExecuteCommand('-stack-list-arguments 1 %d %d',
                                          [AIndex, AIndex], S, []);
  List := CreateMIValueList(S);   
  S := List.Values['stack-args'];
  FreeAndNil(List);
  List := CreateMIValueList(S);
  S := List.Values['frame']; // all arguments
  FreeAndNil(List);
  List := CreateMIValueList(S);   
  S := List.Values['args'];
  FreeAndNil(List);
  
  ArgList := CreateMIValueList(S);
  for n := 0 to ArgList.Count - 1 do
  begin
    List := CreateMIValueList(ArgList[n]);
    Arguments.Add(List.Values['name'] + '=' + List.Values['value']);
    FreeAndNil(List);
  end;
  FreeAndNil(ArgList);
  
  TGDBMIDebugger(Debugger).ExecuteCommand('-stack-list-frames %d %d',
                                          [AIndex, AIndex], S, []);
  List := CreateMIValueList(S);   
  S := List.Values['stack'];
  FreeAndNil(List);
  List := CreateMIValueList(S);   
  S := List.Values['frame'];
  FreeAndNil(List);
  List := CreateMIValueList(S);   
  Result := TCallStackEntry.Create(
    AIndex, 
    Pointer(StrToIntDef(List.Values['addr'], 0)),
    Arguments,
    List.Values['func'],
    List.Values['file'],
    StrToIntDef(List.Values['line'], 0)
  );
  
  FreeAndNil(List);
  Arguments.Free;
end;

{ =========================================================================== }
{ TGDBMIExpression }
{ =========================================================================== }

constructor TGDBMIExpression.Create(const ADebugger: TGDBMIDebugger; const AExpression: String);
begin
  inherited Create;
  FDebugger := ADebugger;
  FLeft := nil;
  FRight := nil;
  CreateSubExpression(Trim(AExpression));
end;

procedure TGDBMIExpression.CreateSubExpression(const AExpression: String);
  function CheckOperator(const APos: Integer; const AOperator: String): Boolean;
  var
    S: String;
  begin
    Result := False;
    if APos + Length(AOperator) > Length(AExpression) then Exit;
    if StrLIComp(@AExpression[APos], @AOperator[1], Length(AOperator)) <> 0 then Exit;
    if (APos > 1) and not (AExpression[APos - 1] in [' ', '(']) then Exit;
    if (APos + Length(AOperator) <= Length(AExpression)) and not (AExpression[APos + Length(AOperator)] in [' ', '(']) then Exit;

    S := Copy(AExpression, 1, APos - 1);
    if S <> ''
    then FLeft := TGDBMIExpression.Create(FDebugger, S);
    S := Copy(AExpression, APos + Length(AOperator), MaxInt);
    if S <> ''
    then FRight := TGDBMIExpression.Create(FDebugger, S);
    FOperator := AOperator;
    Result := True;
  end;
type
  TStringState = (ssNone, ssString, ssLeave);
var
  n: Integer;
  S, LastWord: String;
  HookCount: Integer;
  InString: TStringState;
  Sub: TGDBMIExpression;
begin
  HookCount := 0;
  InString := ssNone;
  LastWord := '';
  for n := 1 to Length(AExpression)  do
  begin
    if AExpression[n] = ''''
    then begin
      case InString of
        ssNone:  InString := ssString;
        ssString:InString := ssLeave;
        ssLeave: InString := ssString;
      end;
      S := S + AExpression[n];
      LastWord := '';
      Continue;
    end;
    if InString = ssString
    then begin
      S := S + AExpression[n];
      LastWord := '';
      Continue;
    end;
    InString := ssNone;

    case AExpression[n] of
      '(', '[': begin
        if HookCount = 0
        then begin
          SetLength(S, Length(S) - Length(LastWord));
          if S <> ''
          then FLeft := TGDBMIExpression.Create(FDebugger, S);
          if LastWord = ''
          then begin
            FOperator := AExpression[n];
          end
          else begin
            FOperator := LastWord;
            FRight := TGDBMIExpression.Create(FDebugger, '');
            FRight.FOperator := AExpression[n];
          end;
          LastWord := '';
          S := '';
        end;
        Inc(HookCount);
        if HookCount = 1
        then Continue;
      end;
      ')', ']': begin
        Dec(HookCount);
        if HookCount = 0
        then begin
          if S <> ''
          then begin
            if FRight = nil
            then FRight := TGDBMIExpression.Create(FDebugger, S)
            else FRight.FRight := TGDBMIExpression.Create(FDebugger, S);
          end;
          if n < Length(AExpression)
          then begin
            Sub := TGDBMIExpression.Create(FDebugger, '');
            Sub.FLeft := FLeft;
            Sub.FOperator := FOperator;
            Sub.FRight := FRight;
            FLeft := Sub;
            Sub := TGDBMIExpression.Create(FDebugger, Copy(AExpression, n + 1, MaxInt));
            if Sub.FLeft = nil
            then begin
              FOperator := Sub.FOperator;
              FRight := Sub.FRight;
              Sub.FRight := nil;
              Sub.Free;
            end
            else begin
              FOperator := '';
              FRight := Sub;
            end;
          end;
          Exit;
        end;
      end;
    end;
    if HookCount = 0
    then begin
      case AExpression[n] of
        '-', '+', '*', '/', '^', '@', '=', ',': begin
          if S <> ''
          then FLeft := TGDBMIExpression.Create(FDebugger, S);
          S := Copy(AExpression, n + 1, MaxInt);
          if Trim(S) <> ''
          then FRight := TGDBMIExpression.Create(FDebugger, S);
          FOperator := AExpression[n];
          Exit;
        end;
        'a', 'A': begin
          if CheckOperator(n, 'and') then Exit;
        end;
        'o', 'O': begin
          if CheckOperator(n, 'or') then Exit;
        end;
        'm', 'M': begin
          if CheckOperator(n, 'mod') then Exit;
        end;
        'd', 'D': begin
          if CheckOperator(n, 'div') then Exit;
        end;
        'x', 'X': begin
          if CheckOperator(n, 'xor') then Exit;
        end;
        's', 'S': begin
          if CheckOperator(n, 'shl') then Exit;
          if CheckOperator(n, 'shr') then Exit;
        end;
      end;
    end;

    if AExpression[n] = ' '
    then LastWord := ''
    else LastWord := LastWord + AExpression[n];
    S := S + AExpression[n];
  end;
  if S = AExpression
  then FOperator := S
  else CreateSubExpression(S);
end;

destructor TGDBMIExpression.Destroy;
begin
  FreeAndNil(FRight);
  FreeAndNil(FLeft);
  inherited;
end;

function TGDBMIExpression.DumpExpression: String;
// Mainly used for debugging purposes
begin
  if FLeft = nil
  then Result := ''
  else Result := '�L:' + FLeft.DumpExpression + '�';

  if FOperator = '('
  then Result := Result + '(�R:' + FRight.DumpExpression + '�)'
  else if FOperator = '['
  then Result := Result + '[�R:' + FRight.DumpExpression + '�]'
  else begin
    if (Length(FOperator) > 0)
    and (FOperator[1] = '''')
    then Result := Result + '�O:' + ConvertToCString(FOperator) + '�'
    else Result := Result + '�O:' + FOperator + '�';
    if FRight <> nil
    then Result := Result + '�R:' + FRight.DumpExpression + '�';
  end;
end;

function TGDBMIExpression.GetExpression(var AResult: String): Boolean;
var
  ResultState: TDBGState;
  S, ResultValues: String;
  List: TStrings;
  GDBType: TGDBType;
begin  
  Result := False;
  
  if FLeft = nil
  then AResult := ''
  else begin
    if not FLeft.GetExpression(S) then Exit;
    AResult := S;
  end;

  if FOperator = '('
  then begin
    if not FRight.GetExpression(S) then Exit;
    AResult := AResult + '(' + S + ')';
  end
  else if FOperator = '['
  then begin              
    if not FRight.GetExpression(S) then Exit;
    AResult := AResult + '[' + S + ']';
  end
  else begin
    if (Length(FOperator) > 0)
    and (FOperator[1] = '''')
    then AResult := AResult + ConvertToCString(FOperator)
    else begin                                           
      GDBType := FDebugger.GetGDBTypeInfo(FOperator);
      if GDBType = nil
      then begin
        // no type possible, use literal operator
        AResult := AResult + FOperator;
      end;

      if not FDebugger.ExecuteCommand('ptype %s', [FOperator],  ResultState,
                                       ResultValues, [cfIgnoreError, cfNoMiCommand])
      then Exit;
      
      if ResultState = dsError
      then begin
        // no type possible, use literal operator
        AResult := AResult + FOperator;
      end
      else begin
        DebugLn('PType result: ', ResultValues);
        List := CreateValueList(ResultValues);
        S := List.Values['type'];
        DebugLn('PType type: ', S);
        List.Free;
        if (S <> '') and (S[1] = '^') and (Pos('class', S) <> 0)
        then begin
          AResult := AResult + GetPart('^', ' ', S) + '(' + FOperator + ')';
        end
        else begin
          // no type possible or no class, use literal operator
          AResult := AResult + FOperator;
        end
      end;
    end;
    if FRight <> nil
    then begin
      if not FRight.GetExpression(S) then Exit;
      AResult := AResult + S;
    end;
  end;
  
  Result := True;
end;

initialization
  RegisterDebugger(TGDBMIDebugger);
  
end.
{ =============================================================================
  $Log$
  Revision 1.55  2004/11/21 18:52:47  marc
  * fixed resetting internal breakpoints

  Revision 1.54  2004/11/21 15:19:08  marc
  * worked aound lack of %u as formatspecifier
  + introduced dbgptr for dealing with pointers on the target
  + added classnames to pointer evaluation

  Revision 1.53  2004/11/19 00:41:18  marc
  * Fixed string evaluation

  Revision 1.52  2004/11/02 23:25:02  marc
  * Introduced another method of interrupting gdb on win32

  Revision 1.51  2004/10/11 23:28:13  marc
  * Fixed interrupting GDB on win32
  * Reset exename after run so that the exe is not locked on win32

  Revision 1.50  2004/09/14 21:30:36  vincents
  replaced writeln by DebugLn

  Revision 1.49  2004/09/04 21:54:08  marc
  + Added option to skip compiler step on compile, build or run
  * Fixed adding of runtime watches
  * Fixed runnerror reporting (correct number and location is shown)

  Revision 1.48  2004/08/26 23:50:05  marc
  * Restructured debugger view classes
  * Fixed help

  Revision 1.47  2004/07/19 22:29:46  marc
  * Temp (?) fix for FPC 1.9.5 [2004/07/15]

  Revision 1.46  2004/04/14 23:07:20  marc
  * Merged Getpart for target PID form Colin Western

  Revision 1.45  2004/04/13 20:14:26  mattias
  fixed debugging under fedora core  from Colin

  Revision 1.44  2004/03/13 00:01:53  marc
  * fixed debugtarget PID parsing (for win32)

  Revision 1.43  2004/03/12 21:39:29  vincents
  Lazarus can communicate with debugger on win32

  Revision 1.42  2004/01/17 13:29:04  mattias
  using now fpc constant LineEnding   from Vincent

  Revision 1.41  2004/01/09 00:10:51  marc
  * More debugger properties
  * Fixed debugger for regcall callingconvention in RTL

  Revision 1.40  2004/01/05 15:22:42  mattias
  improved debugger: saved log, error handling in initialization, better reinitialize

  Revision 1.39  2003/12/05 08:39:53  mattias
  fixed memleak in debugger  from Vincent

  Revision 1.38  2003/08/15 14:28:48  mattias
  clean up win32 ifdefs

  Revision 1.37  2003/08/08 10:24:48  mattias
  fixed initialenabled, debuggertype, linkscaner open string constant

  Revision 1.36  2003/08/08 07:49:56  mattias
  fixed mem leaks in debugger

  Revision 1.35  2003/08/02 00:20:20  marc
  * fixed environment handling to debuggee

  Revision 1.34  2003/07/30 23:15:39  marc
  * Added RegisterDebugger

  Revision 1.33  2003/07/24 08:47:37  marc
  + Added SSHGDB debugger

  Revision 1.32  2003/06/24 23:56:33  marc
  * Fixed version detection of gdb

  Revision 1.31  2002/08/18 08:57:49  marc
  * Improved hint evaluation

  Revision 1.30  2003/06/13 19:21:31  marc
  MWE: + Added initial signal and exception handling

  Revision 1.29  2003/06/10 23:48:26  marc
  MWE: * Enabled modification of breakpoints while running

  Revision 1.28  2003/06/09 17:20:43  mattias
  implemented stop debugging on rebuild

  Revision 1.27  2003/06/09 15:58:05  mattias
  implemented view call stack key and jumping to last stack frame with debug info

  Revision 1.26  2003/06/09 14:30:47  marc
  MWE: + Added working dir.

  Revision 1.25  2003/06/05 00:20:26  marc
  MWE: * Fixed initial run to cursor

  Revision 1.24  2003/06/03 10:29:22  mattias
  implemented updates between source marks and breakpoints

  Revision 1.23  2003/06/03 01:35:40  marc
  MWE: = Splitted TDBGBreakpoint into TBaseBreakPoint, TIDEBreakpoint and
         TDBGBreakPoint

  Revision 1.22  2003/06/02 21:37:30  mattias
  fixed debugger stop

  Revision 1.21  2003/05/30 00:53:09  marc
  MWE: * fixed debugger.stop

  Revision 1.20  2003/05/29 18:47:27  mattias
  fixed reposition sourcemark

  Revision 1.19  2003/05/29 17:40:10  marc
  MWE: * Fixed string resolving
       * Updated exception handling

  Revision 1.18  2003/05/29 07:25:02  mattias
  added Destroying flag, debugger now always shuts down

  Revision 1.17  2003/05/29 02:32:52  marc
  MWE: + Added GDB version check to exception parser

  Revision 1.16  2003/05/28 17:40:55  mattias
  recuced update notifications

  Revision 1.15  2003/05/28 08:46:24  mattias
  break;points dialog now gets the items without debugger

  Revision 1.14  2003/05/28 00:58:50  marc
  MWE: * Reworked breakpoint handling

  Revision 1.13  2003/05/27 20:58:12  mattias
  implemented enable and deleting breakpoint in breakpoint dlg

  Revision 1.12  2003/05/27 17:53:44  mattias
  fixed getting target PID for fpc1.1 programs

  Revision 1.11  2003/05/27 08:01:31  marc
  MWE: + Added exception break
       * Reworked adding/removing breakpoints
       + Added Unknown breakpoint type

  Revision 1.10  2003/05/23 14:12:51  mattias
  implemented restoring breakpoints

  Revision 1.9  2003/05/22 23:08:19  marc
  MWE: = Moved and renamed debuggerforms so that they can be
         modified by the ide
       + Added some parsing to evaluate complex expressions
         not understood by the debugger

  Revision 1.8  2002/11/05 22:41:13  lazarus
  MWE:
    * Some minor debugger updates
    + Added evaluate to debugboss
    + Added hint debug evaluation

  Revision 1.7  2002/05/10 06:57:48  lazarus
  MG: updated licenses

  Revision 1.6  2002/04/30 15:57:40  lazarus
  MWE:
    + Added callstack object and dialog
    + Added checks to see if debugger = nil
    + Added dbgutils

  Revision 1.5  2002/04/24 20:42:29  lazarus
  MWE:
    + Added watches
    * Updated watches and watchproperty dialog to load as resource
    = renamed debugger resource files from *.lrc to *.lrs
    * Temporary fixed language problems on GDB (bug #508)
    * Made Debugmanager dialog handling more generic

  Revision 1.4  2002/03/27 08:57:16  lazarus
  MG: reduced compiler warnings

  Revision 1.3  2002/03/23 15:54:30  lazarus
  MWE:
    + Added locals dialog
    * Modified breakpoints dialog (load as resource)
    + Added generic debuggerdlg class
    = Reorganized main.pp, all debbugger relater routines are moved
      to include/ide_debugger.inc

  Revision 1.2  2002/03/12 23:55:36  lazarus
  MWE:
    * More delphi compatibility added/updated to TListView
    * Introduced TDebugger.locals
    * Moved breakpoints dialog to debugger dir
    * Changed breakpoints dialog to read from resource

  Revision 1.1  2002/03/09 02:03:59  lazarus
  MWE:
    * Upgraded gdb debugger to gdb/mi debugger
    * Set default value for autpopoup
    * Added Clear popup to debugger output window

  Revision 1.6  2002/02/20 23:33:24  lazarus
  MWE:
    + Published OnClick for TMenuItem
    + Published PopupMenu property for TEdit and TMemo (Doesn't work yet)
    * Fixed debugger running twice
    + Added Debugger output form
    * Enabled breakpoints

  Revision 1.5  2002/02/06 08:58:29  lazarus
  MG: fixed compiler warnings and asking to create non existing files

  Revision 1.4  2002/02/05 23:16:48  lazarus
  MWE: * Updated tebugger
       + Added debugger to IDE

  Revision 1.3  2001/11/12 19:28:23  lazarus
  MG: fixed create, virtual constructors makes no sense

  Revision 1.2  2001/11/06 23:59:13  lazarus
  MWE: + Initial breakpoint support
       + Added exeption handling on process.free

  Revision 1.1  2001/11/05 00:12:51  lazarus
  MWE: First steps of a debugger.


}
