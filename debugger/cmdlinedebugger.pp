{ $Id$ }
{                        ----------------------------------------------  
                         CMDLineDebugger.pp  -  Debugger class for 
                                                commandline debuggers
                         ---------------------------------------------- 
 
 @created(Wed Feb 28st WET 2001)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@lazarus.dommelstein.net>)                       

 This unit contains the Commandline debugger class for external commandline
 debuggers.
 
 
/*************************************************************************** 
 *                                                                         * 
 *   This program is free software; you can redistribute it and/or modify  * 
 *   it under the terms of the GNU General Public License as published by  * 
 *   the Free Software Foundation; either version 2 of the License, or     * 
 *   (at your option) any later version.                                   * 
 *                                                                         * 
 ***************************************************************************/ 
} 
unit CmdLineDebugger;

{$mode objfpc}
{$H+}

interface

uses
  Classes, Process, Debugger{, strmlsnr};

type
  TCmdLineDebugger = class(TDebugger)
  private
    FDbgProcess: TProcess;   // The process used to call the debugger
    FLineEnds: TStringList;  // List of strings considered as lineends
    FOutputBuf: String;
    FReading: Boolean;       // Set if we are in the ReadLine loop
    FFlushAfterRead: Boolean;// Set if we should flus if we finished reading
    function GetDebugProcessRunning: Boolean;
  protected
    function  CreateDebugProcess(const AName: String): Boolean;
    procedure Flush;         // Flushes output buffer
//    procedure KillTargetProcess;
    function  ReadLine: String; overload;
    function  ReadLine(const APeek: Boolean): String; overload;
    procedure SendCmdLn(const ACommand: String); overload;
    procedure SendCmdLn(const ACommand: String; Values: array of const); overload;
    property  DebugProcess: TProcess read FDbgProcess;         
    property  DebugProcessRunning: Boolean read GetDebugProcessRunning;         
    property  LineEnds: TStringList read FLineEnds;
  public
    constructor Create; {override; }
    destructor Destroy; override;
    procedure TestCmd(const ACommand: String); virtual;// For internal debugging purposes
  end;

procedure SendBreak(const AHandle: Integer);

function GetLine(var ABuffer: String): String;
function StripLN(const ALine: String): String;
function GetPart(const ASkipTo, AnEnd: String; var ASource: String): String;

const
{$IFDEF WIN32}
  LINE_END = #13#10;
{$ELSE}
  LINE_END = #10;
{$ENDIF}

implementation

uses
{$IFDEF Linux}
 {$IFDEF Ver1_0}
   Linux,
 {$ELSE}
   Unix,
 {$ENDIF}     
{$ENDIF}
  SysUtils, Forms;
  
//////////////////////////////////////////////////
//       Needs to go to proper include
//          Platform dependent
//////////////////////////////////////////////////

{------------------------------------------------------------------------------
  Function: SendBreak
  Params:   AHandle              THe handle of the proces tosend break to
  Returns:  
 ------------------------------------------------------------------------------}
procedure SendBreak(const AHandle: Integer);
begin
{$IFDEF Linux}
  if AHandle <> 0
  then Kill(AHandle, SIGINT);
{$ENDIF}
end;

{------------------------------------------------------------------------------
  Function: WaitForHandles
  Params:  AHandles:              A set of handles to wait for (max 32)
  Returns: BitArray of handles set, 0 when an error ocoured
 ------------------------------------------------------------------------------}
function WaitForHandles(const AHandles: array of Integer): Integer;
{$IFDEF Linux}
var
  n, R, Max, Count: Integer;
  TimeOut: Integer;
  FDSWait, FDS: TFDSet;
begin      
  Result := 0;
  Max := 0;
  Count := High(AHandles);
  if Count < 0 then Exit;
  if Count > 31 then Count := 31;
  FD_ZERO(FDS);

  for n := 0 to Count do   
  begin
    if Max < AHandles[n] then Max := AHandles[n];
    if AHandles[n] <> 0
    then FD_Set(AHandles[n], FDS);
  end;

  repeat
    FDSWait := FDS;
    TimeOut := 10;
    R := Select(Max + 1, @FDSWait, nil, nil, TimeOut);
    Application.ProcessMessages;
  until R <> 0;
  
  if R > 0 
  then begin
    for n := 0 to Count do   
      if  (AHandles[n] <> 0) 
      and (FD_ISSET(AHandles[n], FDSWait))
      then begin
        Result := Result or 1 shl n;
        Dec(R);
        if R=0 then Break;
      end;
  end;
{$ELSE}
begin
  Result := 0;
{$ENDIF}
end;
  
//////////////////////////////////////////////////

//////////////////////////////////////////////////
//           Tools and utilities
//          
//////////////////////////////////////////////////
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
var
  idx: Integer;
begin                  
  if ASkipTo <> ''
  then begin
    idx := Pos(ASkipTo, ASource);
    if idx = 0 
    then begin
      Result := '';
      Exit;
    end;
    Delete(ASource, 1, idx + Length(ASkipTo) - 1);
  end;
  if AnEnd = ''
  then idx := 0
  else idx := Pos(AnEnd, ASource);
  if idx = 0 
  then begin
    Result := ASource;
    ASource := '';
  end
  else begin
    Result := Copy(ASource, 1, idx - 1);
    Delete(ASource, 1, idx - 1);
  end;
end;

//////////////////////////////////////////////////

{ TCmdLineDebugger }

constructor TCmdLineDebugger.Create;
begin
  FDbgProcess := nil;
  FLineEnds := TStringList.Create;
  FLineEnds.Add(LINE_END);
  FReading := False;
  FFlushAfterRead := False;
  inherited Create;
end;

function TCmdLineDebugger.CreateDebugProcess(const AName:String): Boolean;
begin
  if FDbgProcess = nil 
  then begin
    FDbgProcess := TProcess.Create(nil);
    FDbgProcess.CommandLine := AName;
    FDbgProcess.Options:= [poUsePipes, poNoConsole, poStdErrToOutPut];
    FDbgProcess.ShowWindow := swoNone;
  end;
  if not FDbgProcess.Running 
  then begin
    FDbgProcess.Execute;
    WriteLn('[TCmdLineDebugger] Debug PID: ', FDbgProcess.Handle);
  end;
  Result := FDbgProcess.Running;
end;

(*
function TCmdLineDebugger.CreateTargetProcess(const AName:String): Boolean;
begin
  // TODO: Better cleanup
  FTargetProcess.Free;
  FTargetProcess := TProcess.Create(nil);
  FTargetProcess.CommandLine := AName;
  FTargetProcess.Options:= [poUsePipes, poNoConsole, poRunSuspended, poStdErrToOutPut];
  FTargetProcess.ShowWindow := swoNone;
  FTargetProcess.Execute;
  WriteLN('[TCmdLineDebugger] Target PID = ', FTargetProcess.Handle);
  Result := FTargetProcess.Running;  
end;
*)

destructor TCmdLineDebugger.Destroy;
begin
  inherited;
  try
    FDbgProcess.Free;
  except
    on E: Exception do WriteLN('Exeption while freeing debugger: ', E.Message);
  end;
end;

procedure TCmdLineDebugger.Flush;
begin
  if FReading
  then FFlushAfterRead := True
  else FOutputBuf := '';
end;

function TCmdLineDebugger.GetDebugProcessRunning: Boolean;
begin
  Result := (FDbgProcess <> nil) and FDbgProcess.Running;
end;

(*
procedure TCmdLineDebugger.KillTargetProcess;
begin           
  if FTargetProcess = nil then Exit;
  
  FTargetProcess.Terminate(0);
  FTargetProcess.WaitOnExit;
  try
    FTargetProcess.Free;
  except
    on E: Exception do WriteLN('Exeption while freeing target: ', E.Message);
  end;
  FTargetProcess:= nil;
end;
*)
  
function TCmdLineDebugger.ReadLine: String;
begin
  Result := ReadLine(False);
end;

function TCmdLineDebugger.ReadLine(const APeek: Boolean): String;
  function ReadData(const AStream: TStream; var ABuffer: String): Integer;
  var
    S: String;
  begin
    SetLength(S, 1024);
    Result := AStream.Read(S[1], 1024);
    if Result > 0
    then begin
      SetLength(S, Result);
      ABuffer := ABuffer + S;
    end;
  end;

var   
  WaitSet: Integer;
  LineEndMatch: String;
  n, Idx, MinIdx: Integer;
begin                
//  WriteLN('[TCmdLineDebugger.GetOutput] Enter');

// TODO: get extra handles to wait for
  
  FReading := True;
  repeat                       
    if FOutputBuf <> ''
    then begin
      MinIdx := MaxInt;
      for n := 0 to FLineEnds.Count - 1 do
      begin
        LineEndMatch := FLineEnds[n];
        Idx := Pos(LineEndMatch, FOutputBuf);
        if (idx > 0) and (idx < MinIdx) 
        then MinIdx := idx;
      end;
    
      if MinIdx < MaxInt 
      then begin
        n := MinIdx + Length(LineEndMatch) - 1;
        Result := Copy(FOutputBuf, 1, n);
        if not APeek 
        then Delete(FOutputBuf, 1, n);
      
        DoDbgOutput(Result);
        Break;
      end;
    end;

    WaitSet := WaitForHandles([FDbgProcess.Output.Handle]);
    if WaitSet = 0
    then begin
      WriteLN('[TCmdLineDebugger.Getoutput] Error waiting ');
      SetState(dsError);
      Break;
    end;
    
    if  ((WaitSet and 1) <> 0) 
    and (FDbgProcess <> nil)
    and (ReadData(FDbgProcess.Output, FOutputBuf) > 0) 
    then Continue; // start lineend search

(*
    if ((WaitSet and 2) <> 0) and (FTargetProcess <> nil)
    then begin
      Count := ReadData(FTargetProcess.Output, FTargetOutputBuf);
      if Count > 0
      then while True do
      begin
        Line := StripLN(GetLine(FTargetOutputBuf));
        if Line = '' then Break;
        DoOutput(Line); 
      end;
    end;
*)
  until not DebugProcessRunning; 

  FReading := False;
  if FFlushAfterRead 
  then FOutputBuf := '';
  FFlushAfterRead := False;
end;

procedure TCmdLineDebugger.SendCmdLn(const ACommand: String); overload;
begin
  if DebugProcessRunning
  then begin
    DoDbgOutput('<' + ACommand + '>');
    if ACommand <> ''
    then FDbgProcess.Input.Write(ACommand[1], Length(ACommand));
    FDbgProcess.Input.Write(LINE_END, 1);
  end;
end;

procedure TCmdLineDebugger.SendCmdLn(const ACommand: String; Values: array of const);
begin
  SendCmdLn(Format(ACommand, Values));
end;

procedure TCmdLineDebugger.TestCmd(const ACommand: String);
begin
  SendCmdLn(ACommand);
end;

end.
{ =============================================================================
  $Log$
  Revision 1.7  2002/03/09 02:03:58  lazarus
  MWE:
    * Upgraded gdb debugger to gdb/mi debugger
    * Set default value for autpopoup
    * Added Clear popup to debugger output window

  Revision 1.6  2002/02/20 23:33:23  lazarus
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

  Revision 1.3  2001/11/07 00:17:33  lazarus
  MWE: Added IFDEFs so non linux targetswill compile

  Revision 1.2  2001/11/06 23:59:12  lazarus
  MWE: + Initial breakpoint support
       + Added exeption handling on process.free

  Revision 1.1  2001/11/05 00:12:51  lazarus
  MWE: First steps of a debugger.


}
