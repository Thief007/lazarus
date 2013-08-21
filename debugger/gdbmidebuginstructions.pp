unit GDBMIDebugInstructions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, math, CmdLineDebugger, GDBMIMiscClasses, LazLoggerBase, LazClasses;

type

  { TGDBMICmdLineDebugger }

  TGDBMICmdLineDebugger = class(TCmdLineDebugger)
  protected
    FErrorHandlingFlags: set of (ehfDeferReadWriteError, ehfGotReadError, ehfGotWriteError);
    procedure DoReadError; override;
    procedure DoWriteError; override;
  end;

  { TGDBInstruction }

  TGDBInstructionFlag = (
    ifRequiresThread,
    ifRequiresStackFrame
  );
  TGDBInstructionFlags = set of TGDBInstructionFlag;

  TGDBInstructionResultFlag = (
    ifrComleted,
    ifrFailed
  );
  TGDBInstructionResultFlags = set of TGDBInstructionResultFlag;

  TGDBInstructionErrorFlag = (
    ifeContentError,
    ifeWriteError,
    ifeReadError,
    ifeGdbNotRunning,
    ifeTimedOut,
    ifeRecoveredTimedOut,
    ifeInvalidStackFrame,
    ifeInvalidThreadId
  );
  TGDBInstructionErrorFlags = set of TGDBInstructionErrorFlag;

  TGDBInstructionQueue = class;

  { TGDBInstruction }

  TGDBInstruction = class(TRefCountedObject)
  private
    FCommand: String;
    FFlags: TGDBInstructionFlags;
    FStackFrame: Integer;
    FThreadId: Integer;
  protected
    FResultFlags: TGDBInstructionResultFlags;
    FErrorFlags: TGDBInstructionErrorFlags;
    FTimeOut: Integer;
    procedure SendCommandDataToGDB(AQueue: TGDBInstructionQueue); virtual;
    function  ProcessInputFromGdb(const AData: String): Boolean; virtual; abstract; // True if data was handled
    function IsCompleted: boolean; virtual;                                        // No more InputFromGdb required

    procedure MarkAsSuccess;
    procedure HandleWriteError(ASender: TGDBInstruction); virtual;
    procedure HandleReadError; virtual;
    procedure HandleTimeOut; virtual;
    procedure HandleRecoveredTimeOut; virtual;
    procedure HandleNoGdbRunning; virtual;
    procedure HandleContentError; virtual;
    procedure HandleError(AnError: TGDBInstructionErrorFlag; AMarkAsFailed: Boolean = True); virtual;

    function  GetTimeOutVerifier: TGDBInstruction; virtual;
    function  DebugText: String;
    procedure Init; virtual;
    procedure InternalCreate(ACommand: String;
                             AThread, AFrame: Integer; // ifRequiresThread, ifRequiresStackFrame will always be included
                             AFlags: TGDBInstructionFlags;
                             ATimeOut: Integer
                            );
  public
    constructor Create(ACommand: String;
                       AFlags: TGDBInstructionFlags = [];
                       ATimeOut: Integer = 0
                      );
    constructor Create(ACommand: String;
                       AThread: Integer;         // ifRequiresThread will always be included
                       AOtherFlags: TGDBInstructionFlags = [];
                       ATimeOut: Integer = 0
                      );
    constructor Create(ACommand: String;
                       AThread, AFrame: Integer; // ifRequiresThread, ifRequiresStackFrame will always be included
                       AOtherFlags: TGDBInstructionFlags = [];
                       ATimeOut: Integer = 0
                      );
    function IsSuccess: Boolean;
    property Command: String read FCommand;
    property ThreadId: Integer read FThreadId;
    property StackFrame: Integer read FStackFrame;
    property Flags: TGDBInstructionFlags read FFlags;
    property ResultFlags: TGDBInstructionResultFlags read FResultFlags;
    property ErrorFlags: TGDBInstructionErrorFlags read FErrorFlags;
    property TimeOut: Integer read FTimeOut;
  end;

  { TGDBInstructionVerifyTimeOut }

  TGDBInstructionVerifyTimeOutState = (
    vtSent, vtError,
    vtGotPrompt,
    vtGotPrompt7, vtGotPrompt7gdb, vtGotPrompt7and7, vtGotPrompt7and7gdb,
    vtGotPrompt1, vtGotPrompt1gdb,
    vtGot7, vtGot7gdb, vtGot7and7, vtGot7and7gdb, vtGot1, vtGot1gdb
  );

  TGDBInstructionVerifyTimeOut = class(TGDBInstruction)
  private
    FRunnigInstruction: TGDBInstruction;
    FList: TGDBMINameValueList;
    FPromptAfterErrorCount: Integer;
    FVal7Data: String;
    FState: TGDBInstructionVerifyTimeOutState;
  protected
    procedure SendCommandDataToGDB(AQueue: TGDBInstructionQueue); override;
    function ProcessInputFromGdb(const AData: String): Boolean; override;

    procedure HandleWriteError(ASender: TGDBInstruction); override;
    procedure HandleReadError; override;
    procedure HandleTimeOut; override;
    procedure HandleNoGdbRunning; override;
    function GetTimeOutVerifier: TGDBInstruction; override;
    function DebugText: String;
  public
    constructor Create(ARunnigInstruction: TGDBInstruction);
    destructor Destroy; override;
  end;

  { TGDBInstructionChangeThread }

  TGDBInstructionChangeThread = class(TGDBInstruction)
  private
    FSelThreadId: Integer;
    FQueue: TGDBInstructionQueue;
    FDone: Boolean;
  protected
    procedure SendCommandDataToGDB(AQueue: TGDBInstructionQueue); override;
    function ProcessInputFromGdb(const AData: String): Boolean; override;
    procedure HandleError(AnError: TGDBInstructionErrorFlag; AMarkAsFailed: Boolean = True);
      override;
    function DebugText: String;
  public
    constructor Create(AQueue: TGDBInstructionQueue; AThreadId: Integer);
  end;

  { TGDBInstructionChangeStackFrame }

  TGDBInstructionChangeStackFrame = class(TGDBInstruction)
  private
    FSelStackFrame: Integer;
    FQueue: TGDBInstructionQueue;
    FDone: Boolean;
  protected
    procedure SendCommandDataToGDB(AQueue: TGDBInstructionQueue); override;
    function ProcessInputFromGdb(const AData: String): Boolean; override;
    procedure HandleError(AnError: TGDBInstructionErrorFlag; AMarkAsFailed: Boolean = True);
      override;
    function DebugText: String;
  public
    constructor Create(AQueue: TGDBInstructionQueue; AFrame: Integer);
  end;

  { TGDBInstructionQueue }

  TGDBInstructionQueueFlag = (
    ifqValidThread,
    ifqValidStackFrame
  );
  TGDBInstructionQueueFlags = set of TGDBInstructionQueueFlag;

  TGDBInstructionQueue = class
  private
    FCurrentInstruction: TGDBInstruction;
    FCurrentStackFrame: Integer;
    FCurrentThreadId: Integer;
    FDebugger: TGDBMICmdLineDebugger;
    FFlags: TGDBInstructionQueueFlags;

    procedure ExecuteCurrentInstruction;
    procedure FinishCurrentInstruction;
    procedure SetCurrentInstruction(AnInstruction: TGDBInstruction);
    function  HasCorrectThreadIdFor(AnInstruction: TGDBInstruction): Boolean;
    function  HasCorrectFrameFor(AnInstruction: TGDBInstruction): Boolean;
  protected
    function SendDataToGDB(ASender: TGDBInstruction; AData: String): Boolean;
    function SendDataToGDB(ASender: TGDBInstruction; AData: String; const AValues: array of const): Boolean;
    procedure HandleGdbDataBeforeInstruction(var AData: String; var SkipData: Boolean;
                                             const TheInstruction: TGDBInstruction); virtual;
    procedure HandleGdbDataAfterInstruction(var AData: String; const Handled: Boolean;
                                             const TheInstruction: TGDBInstruction); virtual;
    function GetSelectThreadInstruction(AThreadId: Integer): TGDBInstruction; virtual;
    function GetSelectFrameInstruction(AFrame: Integer): TGDBInstruction; virtual;
  public
    constructor Create(ADebugger: TGDBMICmdLineDebugger);
    procedure InvalidateThredAndFrame(AStackFrameOnly: Boolean = False);
    procedure SetKnownThread(AThread: Integer);
    procedure SetKnownThreadAndFrame(AThread, AFrame: Integer);
    procedure RunInstruction(AnInstruction: TGDBInstruction); // Wait for instruction to be finished, not queuing
    property CurrentThreadId: Integer read FCurrentThreadId;
    property CurrentStackFrame: Integer read FCurrentStackFrame;
    property Flags: TGDBInstructionQueueFlags read FFlags;
  end;

function dbgs(AState: TGDBInstructionVerifyTimeOutState): String; overload;
function dbgs(AFlag: TGDBInstructionQueueFlag): String; overload;
function dbgs(AFlags: TGDBInstructionQueueFlags): String; overload;
function dbgs(AFlag: TGDBInstructionFlag): String; overload;
function dbgs(AFlags: TGDBInstructionFlags): String; overload;

implementation

var
  DBGMI_TIMEOUT_DEBUG, DBG_THREAD_AND_FRAME, DBG_VERBOSE: PLazLoggerLogGroup;

const
  TIMEOUT_AFTER_WRITE_ERROR          = 50;
  TIMEOUT_FOR_QUEUE_INSTR      = 50; // select thread/frame
  TIMEOUT_FOR_SYNC_AFTER_TIMEOUT     = 2500; // extra timeout, while trying to recover from a suspected timeout
  TIMEOUT_FOR_SYNC_AFTER_TIMEOUT_MAX = 3000; // upper limit, when using 2*original_timeout

function dbgs(AState: TGDBInstructionVerifyTimeOutState): String; overload;
begin
  writestr(Result{%H-}, AState);
end;

function dbgs(AFlag: TGDBInstructionQueueFlag): String;
begin
  writestr(Result{%H-}, AFlag);
end;

function dbgs(AFlags: TGDBInstructionQueueFlags): String;
var
  i: TGDBInstructionQueueFlag;
begin
  Result := '';
  for i := low(TGDBInstructionQueueFlags) to high(TGDBInstructionQueueFlags) do
    if i in AFlags then
      if Result = '' then
        Result := Result + dbgs(i)
      else
        Result := Result + ', ' +dbgs(i);
  if Result <> '' then
    Result := '[' + Result + ']';
end;

function dbgs(AFlag: TGDBInstructionFlag): String;
begin
  writestr(Result{%H-}, AFlag);
end;

function dbgs(AFlags: TGDBInstructionFlags): String;
var
  i: TGDBInstructionFlag;
begin
  Result := '';
  for i := low(TGDBInstructionFlags) to high(TGDBInstructionFlags) do
    if i in AFlags then
      if Result = '' then
        Result := Result + dbgs(i)
      else
        Result := Result + ', ' +dbgs(i);
  if Result <> '' then
    Result := '[' + Result + ']';
end;

{ TGDBMICmdLineDebugger }

procedure TGDBMICmdLineDebugger.DoReadError;
begin
  include(FErrorHandlingFlags, ehfGotReadError);
  if not(ehfDeferReadWriteError in FErrorHandlingFlags)
  then inherited DoReadError;
end;

procedure TGDBMICmdLineDebugger.DoWriteError;
begin
  include(FErrorHandlingFlags, ehfGotWriteError);
  if not(ehfDeferReadWriteError in FErrorHandlingFlags)
  then inherited DoWriteError;
end;

{ TGDBInstruction }

procedure TGDBInstruction.SendCommandDataToGDB(AQueue: TGDBInstructionQueue);
begin
  AQueue.SendDataToGDB(Self, FCommand);
end;

function TGDBInstruction.IsCompleted: boolean;
begin
  Result := FResultFlags * [ifrComleted, ifrFailed] <> [];
end;

procedure TGDBInstruction.MarkAsSuccess;
begin
  Include(FResultFlags, ifrComleted);
end;

procedure TGDBInstruction.HandleWriteError(ASender: TGDBInstruction);
begin
  HandleError(ifeWriteError, False);
  if (FTimeOut = 0) or (FTimeOut > TIMEOUT_AFTER_WRITE_ERROR) then
    FTimeOut := TIMEOUT_AFTER_WRITE_ERROR;
end;

procedure TGDBInstruction.HandleReadError;
begin
  HandleError(ifeReadError, True);
end;

procedure TGDBInstruction.HandleTimeOut;
begin
  HandleError(ifeTimedOut, True);
end;

procedure TGDBInstruction.HandleRecoveredTimeOut;
begin
  Include(FErrorFlags, ifeRecoveredTimedOut);
end;

procedure TGDBInstruction.HandleNoGdbRunning;
begin
  HandleError(ifeGdbNotRunning, True);
end;

procedure TGDBInstruction.HandleContentError;
begin
  HandleError(ifeContentError, True);
end;

procedure TGDBInstruction.HandleError(AnError: TGDBInstructionErrorFlag;
  AMarkAsFailed: Boolean = True);
begin
  if AMarkAsFailed then
    Include(FResultFlags, ifrFailed);
  Include(FErrorFlags,  AnError);
end;

function TGDBInstruction.GetTimeOutVerifier: TGDBInstruction;
begin
  if (ifeWriteError in ErrorFlags) then
    Result := nil
  else
    Result := TGDBInstructionVerifyTimeOut.Create(Self);
end;

function TGDBInstruction.DebugText: String;
begin
  Result := ClassName + ': "' + FCommand + '", ' + dbgs(FFlags);
  if ifRequiresThread in FFlags then
    Result := Result + ' Thr=' + IntToStr(FThreadId);
  if ifRequiresStackFrame in FFlags then
    Result := Result + ' Frm=' + IntToStr(FStackFrame);
end;

procedure TGDBInstruction.Init;
begin
  //
end;

procedure TGDBInstruction.InternalCreate(ACommand: String; AThread, AFrame: Integer;
  AFlags: TGDBInstructionFlags; ATimeOut: Integer);
begin
  FCommand := ACommand;
  FThreadId   := AThread;
  FStackFrame := AFrame;
  FFlags := AFlags;
  FTimeOut := ATimeOut;
end;

constructor TGDBInstruction.Create(ACommand: String; AFlags: TGDBInstructionFlags;
  ATimeOut: Integer = 0);
begin
  InternalCreate(ACommand, -1, -1, AFlags, ATimeOut);
  Init;
end;

constructor TGDBInstruction.Create(ACommand: String; AThread: Integer;
  AOtherFlags: TGDBInstructionFlags; ATimeOut: Integer = 0);
begin
  InternalCreate(ACommand, AThread, -1,
                 AOtherFlags + [ifRequiresThread], ATimeOut);
  Init;
end;

constructor TGDBInstruction.Create(ACommand: String; AThread, AFrame: Integer;
  AOtherFlags: TGDBInstructionFlags; ATimeOut: Integer = 0);
begin
  InternalCreate(ACommand, AThread, AFrame,
                 AOtherFlags + [ifRequiresThread, ifRequiresStackFrame], ATimeOut);
  Init;
end;

function TGDBInstruction.IsSuccess: Boolean;
begin
  Result := ResultFlags * [ifrComleted, ifrFailed] = [ifrComleted]
end;

{ TGDBInstructionVerifyTimeOut }

procedure TGDBInstructionVerifyTimeOut.SendCommandDataToGDB(AQueue: TGDBInstructionQueue);
begin
  AQueue.SendDataToGDB(Self, '-data-evaluate-expression 7');
  AQueue.SendDataToGDB(Self, '-data-evaluate-expression 1');
  FState := vtSent;
end;

function TGDBInstructionVerifyTimeOut.ProcessInputFromGdb(const AData: String): Boolean;
type
  TLineDataTipe = (ldOther, ldGdb, ldValue7, ldValue1);

  function CheckData(const ALineData: String): TLineDataTipe;
  begin
    Result := ldOther;
    if ALineData= '(gdb) ' then begin
      Result := ldGdb;
      exit;
    end;
    if (copy(AData, 1, 6) = '^done,') or (AData = '^done') then begin
      if FList = nil then
        FList := TGDBMINameValueList.Create(ALineData)
      else
        FList.Init(ALineData);
      if FList.Values['value'] = '7' then
        Result := ldValue7
      else
      if FList.Values['value'] = '1' then
        Result := ldValue1
    end;
  end;

  procedure SetError(APromptCount: Integer);
  begin
    FState := vtError;
    FPromptAfterErrorCount := APromptCount; // prompt for val7 and val1 needed
    FRunnigInstruction.HandleTimeOut;
    if FPromptAfterErrorCount <= 0 then
      FTimeOut := 50; // wait for timeout
  end;

begin
  Result := True;
  if FState = vtError then begin
    dec(FPromptAfterErrorCount);
    if FPromptAfterErrorCount <= 0 then
      FTimeOut := 50; // wait for timeout
    exit;
  end;

  case CheckData(AData) of
    ldOther: begin
        debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Got other data']);
        Result := FRunnigInstruction.ProcessInputFromGdb(AData);
      end;
    ldGdb:
      case FState of
        vtSent: begin
            debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Got prompt in order']);
            FState := vtGotPrompt;
            Result := FRunnigInstruction.ProcessInputFromGdb(AData);
            if not FRunnigInstruction.IsCompleted then begin
              debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Prompt was not accepted']);
              SetError(2); // prompt for val=7 and val=1 needed
            end;
          end;
        vtGotPrompt7:     FState := vtGotPrompt7gdb;
        vtGotPrompt7and7: FState := vtGotPrompt7and7gdb;
        vtGotPrompt1:     FState := vtGotPrompt1gdb;
        vtGot7:           FState := vtGot7gdb;
        vtGot7and7:       FState := vtGot7and7gdb;
        vtGot1:           FState := vtGot1gdb;
        else begin
            debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Extra Prompt ']);
            if FState = vtGotPrompt
            then SetError(1)  // prompt val=1 needed
            else SetError(0); // no more prompt needed
          end;
      end;
    ldValue7:
      case FState of
        vtSent, vtGotPrompt: begin
            debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Got value 7']);
            FVal7Data := AData;
            if FState = vtSent
            then FState := vtGot7
            else FState := vtGotPrompt7;
          end;
        vtGotPrompt7gdb, vtGot7gdb: begin
            debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Got value 7 twice. Original Result?']);
            Result := FRunnigInstruction.ProcessInputFromGdb(FVal7Data);
            if FState = vtGotPrompt7gdb
            then FState := vtGotPrompt7and7
            else FState := vtGot7and7;
          end;
        else begin
          debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Extra VAlue 7']);
          if FState in [vtGotPrompt7, vtGot7]
          then SetError(1)  // prompt val=1 needed
          else SetError(0); // no more prompt needed
        end;
      end;
    ldValue1:
      case FState of
        vtSent: begin
          debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Got other data']);
          Result := FRunnigInstruction.ProcessInputFromGdb(AData);
        end;
        vtGotPrompt7gdb:     FState := vtGotPrompt1;
        vtGotPrompt7and7gdb: FState := vtGotPrompt1;
        vtGot7gdb:           FState := vtGot1;
        vtGot7and7gdb:       FState := vtGot1;
        else begin
          debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Wrong Value 1']);
          SetError(0);
        end;
      end;
  end;

  if FState = vtGot1gdb then begin
    // timeout, but recovored
    debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): Recovered']);
    FRunnigInstruction.ProcessInputFromGdb('(gdb) '); // simulate prompt
    FRunnigInstruction.HandleRecoveredTimeOut;
  end;
  if FState in [vtGot1gdb, vtGotPrompt1gdb] then begin
    debugln(DBGMI_TIMEOUT_DEBUG, ['GDBMI TimeOut(', dbgs(FState), '): All done: original Instruction completed=',dbgs(FRunnigInstruction.IsCompleted)]);
    Include(FResultFlags, ifrComleted);
    if not FRunnigInstruction.IsCompleted then
      FRunnigInstruction.HandleTimeOut;
  end;

end;

procedure TGDBInstructionVerifyTimeOut.HandleWriteError(ASender: TGDBInstruction);
begin
  inherited HandleWriteError(ASender);
  FRunnigInstruction.HandleWriteError(ASender);
end;

procedure TGDBInstructionVerifyTimeOut.HandleReadError;
begin
  inherited HandleReadError;
  FRunnigInstruction.HandleReadError;
end;

procedure TGDBInstructionVerifyTimeOut.HandleTimeOut;
begin
  inherited HandleTimeOut;
  FRunnigInstruction.HandleTimeOut;
end;

procedure TGDBInstructionVerifyTimeOut.HandleNoGdbRunning;
begin
  inherited HandleNoGdbRunning;
  FRunnigInstruction.HandleNoGdbRunning;
end;

function TGDBInstructionVerifyTimeOut.GetTimeOutVerifier: TGDBInstruction;
begin
  Result := nil;
end;

function TGDBInstructionVerifyTimeOut.DebugText: String;
begin
  Result := ClassName + ': for "' + FRunnigInstruction.DebugText;
end;

constructor TGDBInstructionVerifyTimeOut.Create(ARunnigInstruction: TGDBInstruction);
var
  t: Integer;
begin
  FRunnigInstruction := ARunnigInstruction;
  FRunnigInstruction.AddReference;
  t := FRunnigInstruction.TimeOut;
  t := max(TIMEOUT_FOR_SYNC_AFTER_TIMEOUT, Min(TIMEOUT_FOR_SYNC_AFTER_TIMEOUT_MAX, t * 2));
  inherited Create('', FRunnigInstruction.ThreadId, FRunnigInstruction.StackFrame,
                   FRunnigInstruction.Flags * [ifRequiresThread, ifRequiresStackFrame],
                   t);
end;

destructor TGDBInstructionVerifyTimeOut.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FList);
  if (FRunnigInstruction <> nil) then
    FRunnigInstruction.ReleaseReference;
end;

{ TGDBInstructionChangeThread }

procedure TGDBInstructionChangeThread.SendCommandDataToGDB(AQueue: TGDBInstructionQueue);
begin
  AQueue.SendDataToGDB(Self, '-thread-select %d', [FSelThreadId]);
end;

function TGDBInstructionChangeThread.ProcessInputFromGdb(const AData: String): Boolean;
begin
//  "-thread-select 2"
//  "^done,new-thread-id="2",frame={level="0",addr="0x7707878f",func="ntdll!DbgUiConvertStateChangeStructure",args=[],from="C:\\Windows\\system32\\ntdll.dll"}"
//  "(gdb) "

  Result := False;
  if (copy(AData, 1, 6) = '^done,') or (AData = '^done') then begin
    Result := True;
    if FDone then
      HandleContentError;
    FDone := True;
  end

  else
  if (AData = '(gdb) ') then begin
    Result := True;
    if not FDone then begin
      HandleContentError;
    end
    else begin
      MarkAsSuccess;
      FQueue.FCurrentThreadId := FSelThreadId;
      FQueue.FFlags := FQueue.FFlags + [ifqValidThread];
    end;
  end

  else
  begin
    debugln(DBG_VERBOSE, ['GDBMI TGDBInstructionChangeThread ignoring: ', AData]);
  end;
end;

procedure TGDBInstructionChangeThread.HandleError(AnError: TGDBInstructionErrorFlag;
  AMarkAsFailed: Boolean);
begin
  inherited HandleError(AnError, AMarkAsFailed);
  FQueue.InvalidateThredAndFrame;
end;

function TGDBInstructionChangeThread.DebugText: String;
begin
  Result := ClassName;
end;

constructor TGDBInstructionChangeThread.Create(AQueue: TGDBInstructionQueue;
  AThreadId: Integer);
begin
  inherited Create('', [], TIMEOUT_FOR_QUEUE_INSTR);
  FQueue := AQueue;
  FDone := False;
  FSelThreadId := AThreadId;
end;

{ TGDBInstructionChangeStackFrame }

procedure TGDBInstructionChangeStackFrame.SendCommandDataToGDB(AQueue: TGDBInstructionQueue);
begin
  AQueue.SendDataToGDB(Self, '-stack-select-frame %d', [FSelStackFrame]);
end;

function TGDBInstructionChangeStackFrame.ProcessInputFromGdb(const AData: String): Boolean;
begin
//  "-stack-select-frame 0"
//  "^done"
//  "(gdb) "
//OR ^error => keep selected ?

  Result := False;
  if (copy(AData, 1, 6) = '^done,') or (AData = '^done') then begin
    Result := True;
    if FDone then
      HandleContentError;
    FDone := True;
  end

  else
  if (AData = '(gdb) ') then begin
    Result := True;
    if not FDone then begin
      HandleContentError;
    end
    else begin
      MarkAsSuccess;
      FQueue.FCurrentStackFrame := FSelStackFrame;
      FQueue.FFlags := FQueue.FFlags + [ifqValidStackFrame];
    end;
  end

  else
  begin
    debugln(DBG_VERBOSE, ['GDBMI TGDBInstructionChangeStackFrame ignoring: ', AData]);
  end;
end;

procedure TGDBInstructionChangeStackFrame.HandleError(AnError: TGDBInstructionErrorFlag;
  AMarkAsFailed: Boolean);
begin
  inherited HandleError(AnError, AMarkAsFailed);
  FQueue.InvalidateThredAndFrame(True);
end;

function TGDBInstructionChangeStackFrame.DebugText: String;
begin
  Result := ClassName;
end;

constructor TGDBInstructionChangeStackFrame.Create(AQueue: TGDBInstructionQueue;
  AFrame: Integer);
begin
  inherited Create('', [], TIMEOUT_FOR_QUEUE_INSTR);
  FQueue := AQueue;
  FDone := False;
  FSelStackFrame := AFrame;
end;

{ TGDBInstructionQueue }

procedure TGDBInstructionQueue.ExecuteCurrentInstruction;
var
  ExeInstr, HelpInstr: TGDBInstruction;
begin
  if FCurrentInstruction = nil then
    exit;

  ExeInstr := FCurrentInstruction;
  ExeInstr.AddReference;
  try

    if not HasCorrectThreadIdFor(ExeInstr) then begin
      HelpInstr := GetSelectThreadInstruction(ExeInstr.ThreadId);
      DebugLn(DBG_THREAD_AND_FRAME, ['TGDB_IQ: Changing Thread from: ', FCurrentThreadId, ' - ', dbgs(FFlags),
        ' to ', ExeInstr.ThreadId, ' using [', HelpInstr.DebugText, '] for [', ExeInstr.DebugText, ']']);
      HelpInstr.AddReference;
      try
        FCurrentInstruction := HelpInstr;
        FCurrentInstruction.SendCommandDataToGDB(Self);
        FinishCurrentInstruction;
        if not HelpInstr.IsSuccess then begin
          DebugLn(DBG_THREAD_AND_FRAME, ['TGDB_IQ: Changing Thread FAILED']);
          ExeInstr.HandleError(ifeInvalidThreadId);
          exit;
        end;
      finally
        HelpInstr.ReleaseReference;
      end;
    end;
    if not HasCorrectFrameFor(ExeInstr) then begin
      HelpInstr := GetSelectFrameInstruction(ExeInstr.StackFrame);
      DebugLn(DBG_THREAD_AND_FRAME, ['TGDB_IQ: Changing Stack from: ', FCurrentStackFrame, ' - ', dbgs(FFlags),
        ' to ', ExeInstr.StackFrame, ' using [', HelpInstr.DebugText, '] for [', ExeInstr.DebugText, ']']);
      HelpInstr.AddReference;
      try
        FCurrentInstruction := HelpInstr;
        FCurrentInstruction.SendCommandDataToGDB(Self);
        FinishCurrentInstruction;
        if not HelpInstr.IsSuccess then begin
          DebugLn(DBG_THREAD_AND_FRAME, ['TGDB_IQ: Changing Stackframe FAILED']);
          ExeInstr.HandleError(ifeInvalidStackFrame);
          exit;
        end;
      finally
        HelpInstr.ReleaseReference;
      end;
    end;

  finally
    if ExeInstr.RefCount > 1 then
      FCurrentInstruction := ExeInstr
    else
      FCurrentInstruction := nil;
    ExeInstr.ReleaseReference;
  end;

  if FCurrentInstruction <> nil then
    FCurrentInstruction.SendCommandDataToGDB(Self);
end;

procedure TGDBInstructionQueue.FinishCurrentInstruction;
var
  S: String;
  NewInstr, ExeInstr: TGDBInstruction;
  Skip: Boolean;
  Handled: Boolean;
begin
  if FCurrentInstruction = nil then exit;
  ExeInstr := FCurrentInstruction;
  ExeInstr.AddReference;
  try
    while (FCurrentInstruction <> nil) and
          (not FCurrentInstruction.IsCompleted)
    do begin
      if not FDebugger.DebugProcessRunning then begin
        FCurrentInstruction.HandleNoGdbRunning;
        break;
      end;

      S := FDebugger.ReadLine(FCurrentInstruction.TimeOut);
      // Readline, may go into Application.ProcessMessages.
      // If it does, it has not (yet) read any data.
      // Therefore, if it does, another nested call to readline will work, and data will be returned in the correct order.
      // If a nested readline reads all data, then the outer will have nothing to return.
      // TODO: need a flag, so the outer will immediately return empty.
      // TODO: also need a ReadlineCallCounter, to detect inner nested calls

      Skip := False;
      HandleGdbDataBeforeInstruction(S, Skip, FCurrentInstruction);

      if (not Skip) and
         ( (not FDebugger.ReadLineTimedOut) or (S <> '') )
      then
        Handled := FCurrentInstruction.ProcessInputFromGdb(S);

      HandleGdbDataAfterInstruction(S, Handled, FCurrentInstruction);

      if (ehfGotReadError in FDebugger.FErrorHandlingFlags) then begin
        FCurrentInstruction.HandleReadError;
        break;
      end;
      if FDebugger.ReadLineTimedOut then begin
        NewInstr := FCurrentInstruction.GetTimeOutVerifier;
        if NewInstr <> nil then begin
          NewInstr.AddReference;
          ExeInstr.ReleaseReference;
          ExeInstr := NewInstr;
          // TODO: Run NewInstr;
          FCurrentInstruction := NewInstr;
          FCurrentInstruction.SendCommandDataToGDB(Self); // ExecuteCurrentInstruction;

        end
        else begin
          FCurrentInstruction.HandleTimeOut;
          break;
        end;
      end;

    end; // while
    FCurrentInstruction := nil;
  finally
    ExeInstr.ReleaseReference;
  end;
end;

procedure TGDBInstructionQueue.SetCurrentInstruction(AnInstruction: TGDBInstruction);
begin
  FinishCurrentInstruction;
  FCurrentInstruction := AnInstruction;
end;

function TGDBInstructionQueue.HasCorrectThreadIdFor(AnInstruction: TGDBInstruction): Boolean;
begin
  Result := not(ifRequiresThread in AnInstruction.Flags);
  if Result then
    exit;
  Result := (ifqValidThread in Flags) and (CurrentThreadId = AnInstruction.ThreadId);
end;

function TGDBInstructionQueue.HasCorrectFrameFor(AnInstruction: TGDBInstruction): Boolean;
begin
  Result := not(ifRequiresStackFrame in AnInstruction.Flags);
  if Result then
    exit;
  Result := (ifqValidStackFrame in Flags) and (CurrentStackFrame = AnInstruction.StackFrame);
end;

function TGDBInstructionQueue.SendDataToGDB(ASender: TGDBInstruction; AData: String): Boolean;
begin
  Result := True;
  FDebugger.FErrorHandlingFlags := FDebugger.FErrorHandlingFlags
    + [ehfDeferReadWriteError] - [ehfGotReadError, ehfGotWriteError];

  FDebugger.SendCmdLn(AData);

  if ehfGotWriteError in FDebugger.FErrorHandlingFlags then begin
    Result := False;
// TODO try reading, but ensure timeout
    if FCurrentInstruction <> nil then
      FCurrentInstruction.HandleWriteError(ASender)
    else
    if ASender <> nil then
      ASender.HandleWriteError(ASender);
  end;
end;

function TGDBInstructionQueue.SendDataToGDB(ASender: TGDBInstruction; AData: String;
  const AValues: array of const): Boolean;
begin
  Result := SendDataToGDB(ASender, Format(AData, AValues));
end;

procedure TGDBInstructionQueue.HandleGdbDataBeforeInstruction(var AData: String;
  var SkipData: Boolean; const TheInstruction: TGDBInstruction);
begin
  //
end;

procedure TGDBInstructionQueue.HandleGdbDataAfterInstruction(var AData: String;
  const Handled: Boolean; const TheInstruction: TGDBInstruction);
begin
  //
end;

function TGDBInstructionQueue.GetSelectThreadInstruction(AThreadId: Integer): TGDBInstruction;
begin
  Result := TGDBInstructionChangeThread.Create(Self, AThreadId);
end;

function TGDBInstructionQueue.GetSelectFrameInstruction(AFrame: Integer): TGDBInstruction;
begin
  Result := TGDBInstructionChangeStackFrame.Create(Self, AFrame);
end;

constructor TGDBInstructionQueue.Create(ADebugger: TGDBMICmdLineDebugger);
begin
  FDebugger := ADebugger;
end;

procedure TGDBInstructionQueue.InvalidateThredAndFrame(AStackFrameOnly: Boolean = False);
begin
  if AStackFrameOnly then begin
    DebugLn(DBG_THREAD_AND_FRAME, ['TGDB_IQ: Invalidating queue''s stack only. Was: ', dbgs(FFlags), ' Thr=', FCurrentThreadId, ' Frm=', FCurrentStackFrame]);
    FFlags := FFlags - [ifqValidStackFrame];
  end
  else begin
    DebugLn(DBG_THREAD_AND_FRAME, ['TGDB_IQ: Invalidating queue''s current thread and stack. Was: ', dbgs(FFlags), ' Thr=', FCurrentThreadId, ' Frm=', FCurrentStackFrame]);
    FFlags := FFlags - [ifqValidThread, ifqValidStackFrame];
  end;
end;

procedure TGDBInstructionQueue.SetKnownThread(AThread: Integer);
begin
  DebugLn(DBG_THREAD_AND_FRAME, ['TGDB_IQ: Setting queue''s current thread and stack. New: Thr=', AThread, ' Was: ', dbgs(FFlags), ' Thr=', FCurrentThreadId, ' Frm=', FCurrentStackFrame]);
  FCurrentThreadId := AThread;
  FFlags := FFlags + [ifqValidThread] - [ifqValidStackFrame];
end;

procedure TGDBInstructionQueue.SetKnownThreadAndFrame(AThread, AFrame: Integer);
begin
  DebugLn(DBG_THREAD_AND_FRAME, ['TGDB_IQ: Setting queue''s current thread and stack. New: Thr=', AThread, ' Frm=', AFrame,' Was: ', dbgs(FFlags), ' Thr=', FCurrentThreadId, ' Frm=', FCurrentStackFrame]);
  FCurrentThreadId := AThread;
  FCurrentStackFrame := AFrame;
  FFlags := FFlags + [ifqValidThread, ifqValidStackFrame];
end;

procedure TGDBInstructionQueue.RunInstruction(AnInstruction: TGDBInstruction);
begin
  SetCurrentInstruction(AnInstruction);
  ExecuteCurrentInstruction;
  FinishCurrentInstruction;
end;

initialization
  DBGMI_TIMEOUT_DEBUG := DebugLogger.RegisterLogGroup('DBGMI_TIMEOUT_DEBUG' {$IFDEF DBGMI_TIMEOUT_DEBUG} , True {$ENDIF} );
  DBG_THREAD_AND_FRAME := DebugLogger.FindOrRegisterLogGroup('DBG_THREAD_AND_FRAME' {$IFDEF DBG_THREAD_AND_FRAME} , True {$ENDIF} );
  DBG_VERBOSE := DebugLogger.FindOrRegisterLogGroup('DBG_VERBOSE' {$IFDEF DBG_VERBOSE} , True {$ENDIF} );

end.

