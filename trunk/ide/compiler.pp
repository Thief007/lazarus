{  $Id$  }
{
 /***************************************************************************
                        compiler.pp  -  Main application unit
                        -------------------------------------
                   TCompiler is responsible for configuration and running
                   the PPC386 compiler.


                   Initial Revision  : Sun Mar 28 23:15:32 CST 1999


 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
}
unit compiler;

{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, CompilerOptions, Project, Process,
  IDEProcs;

type
  TOnOutputString = procedure (const Value: String) of Object;
  TErrorType = (etNone, etHint, etWarning, etError, etFatal);
  TOnCmdLineCreate = procedure(var CmdLine: string; var Abort:boolean)
      of object;
  
  TCompiler = class(TObject)
  private
    FOnOutputString : TOnOutputString;
    FOutputList : TStringList;
    FOnCmdLineCreate : TOnCmdLineCreate;
    function IsHintForUnusedProjectUnit(const OutputLine, 
       ProgramSrcFile: string): boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Compile(AProject: TProject; BuildAll: boolean;
       const DefaultFilename: string): TModalResult;
    function GetSourcePosition(const Line: string; var Filename:string;
       var CaretXY: TPoint; var MsgType: TErrorType): boolean;
    property OnOutputString : TOnOutputString
       read FOnOutputString write FOnOutputString;
    property OutputList : TStringList read FOutputList;
    property OnCommandLineCreate: TOnCmdLineCreate
       read FOnCmdLineCreate write FOnCmdLineCreate;
  end;

const
  ErrorTypeNames : array[TErrorType] of string = (
      'None','Hint','Warning','Error','Fatal'
    );

var
  Compiler1 : TCompiler;

function ErrorTypeNameToType(const Name:string): TErrorType;


implementation


function ErrorTypeNameToType(const Name:string): TErrorType;
var LowName: string;
begin
  LowName:=lowercase(Name);
  for Result:=Low(TErrorType) to High(TErrorType) do
    if lowercase(ErrorTypeNames[Result])=LowName then exit;
  Result:=etNone;
end;

{ TCompiler }

{------------------------------------------------------------------------------}
{  TCompiler Constructor                                                       }
{------------------------------------------------------------------------------}
constructor TCompiler.Create;
begin
  inherited Create;
  FOutputList := TStringList.Create;
end;

{------------------------------------------------------------------------------}
{  TCompiler Destructor                                                        }
{------------------------------------------------------------------------------}
destructor TCompiler.Destroy;
begin
  FOutputList.Free;
  inherited Destroy;
end;

{------------------------------------------------------------------------------}
{  TCompiler Compile                                                           }
{------------------------------------------------------------------------------}
function TCompiler.Compile(AProject: TProject; BuildAll: boolean;
  const DefaultFilename: string): TModalResult;
const
  BufSize = 1024;
var
  CmdLine : String;
  I, Count, LineStart : longint;
  OutputLine, Buf : String;
  WriteMessage, ABort : Boolean;
  OldCurDir, ProjectDir, ProjectFilename: string;
  TheProcess : TProcess;

  procedure ProcessOutputLine;
  begin
writeln('[TCompiler.Compile] Output="',OutputLine,'"');
    FOutputList.Add(OutputLine);

    //determine what type of message it is
    if (pos(') Hint:',OutputLine) <> 0) then begin
      WriteMessage := AProject.CompilerOptions.ShowHints
                   or AProject.CompilerOptions.ShowAll;
      if (not AProject.CompilerOptions.ShowAll) 
      and (not AProject.CompilerOptions.ShowHintsForUnusedProjectUnits)
      and (IsHintForUnusedProjectUnit(OutputLine,ProjectFilename)) then
        WriteMessage:=false;
    end else if (pos(') Note:',OutputLine) <> 0) then
      WriteMessage := AProject.CompilerOptions.ShowNotes
                   or AProject.CompilerOptions.ShowAll
    else if (pos(') Error:',OutputLine) <> 0) then begin
      WriteMessage := AProject.CompilerOptions.ShowErrors
                   or AProject.CompilerOptions.ShowAll;
      Result:=mrCancel;
    end else if (pos(') Warning:',OutputLine) <> 0) then
      WriteMessage := AProject.CompilerOptions.ShowWarn
                   or AProject.CompilerOptions.ShowAll
    else if (copy(OutputLine,1,5)='Panic') or (pos(') Fatal:',OutputLine) <> 0) or (pos('Fatal: ',OutputLine) <> 0)
    then begin
      Result:=mrCancel;
      WriteMessage := true;
    end else if OutputLine='Closing script ppas.sh' then begin
      WriteMessage:=true;
    end;
    if (WriteMessage) and Assigned(OnOutputString) then
      OnOutputString(OutputLine);
    WriteMessage := false;

    Application.ProcessMessages;
    OutputLine:='';
  end;

// TCompiler.Compile
begin
  Result:=mrCancel;
  if AProject.MainUnit<0 then exit;
  OldCurDir:=GetCurrentDir;
  if Aproject.IsVirtual then
    ProjectFilename:=DefaultFilename
  else
    ProjectFilename:=AProject.Units[AProject.MainUnit].Filename;
  if ProjectFilename='' then exit;
  ProjectDir:=ExtractFilePath(ProjectFilename);
  if not SetCurrentDir(ProjectDir) then exit;
  try
    FOutputList.Clear;
    SetLength(Buf,BufSize);
    CmdLine := AProject.CompilerOptions.CompilerPath;
    
    if Assigned(FOnCmdLineCreate) then begin
      Abort:=false;
      FOnCmdLineCreate(CmdLine,Abort);
      if Abort then begin
        Result:=mrAbort;
        exit;
      end;
    end;
    try
      CheckIfFileIsExecutable(CmdLine);
    except
      on E: Exception do begin
        OutputLine:='Error: invalid compiler: '+E.Message;
        writeln(OutputLine);
        if Assigned(OnOutputString) then
          OnOutputString(OutputLine);
        if CmdLine='' then begin
          OutputLine:='Hint: you can set the compiler path in '
             +'Environment->General Options->Files->Compiler Path';
          writeln(OutputLine);
          if Assigned(OnOutputString) then
            OnOutputString(OutputLine);
        end;
        exit;
      end;
    end;
    if BuildAll then
      CmdLine := CmdLine+' -B';
    CmdLine := CmdLine
                 + ' '+ AProject.CompilerOptions.MakeOptionsString(ProjectFilename)
                 + ' '+ ProjectFilename;
    if Assigned(FOnCmdLineCreate) then begin
      Abort:=false;
      FOnCmdLineCreate(CmdLine,Abort);
      if Abort then begin
        Result:=mrAbort;
        exit;
      end;
    end;
    Writeln('[TCompiler.Compile] CmdLine="',CmdLine,'"');

    try
      
      TheProcess := TProcess.Create(nil);
      TheProcess.CommandLine := CmdLine;
      TheProcess.Options:= [poUsePipes, poNoConsole, poStdErrToOutPut];
      TheProcess.ShowWindow := swoNone;
      Result:=mrOk;
      try
        TheProcess.CurrentDirectory:=ProjectDir;
        TheProcess.Execute;
        Application.ProcessMessages;

        OutputLine:='';
        repeat
          if TheProcess.Output<>nil then
            Count:=TheProcess.Output.Read(Buf[1],length(Buf))
          else
            Count:=0;         
          WriteMessage := False;
          LineStart:=1;
          i:=1;
          while i<=Count do begin
            if Buf[i] in [#10,#13] then begin
              OutputLine:=OutputLine+copy(Buf,LineStart,i-LineStart);
              ProcessOutputLine;
              if (i<Count) and (Buf[i+1] in [#10,#13]) and (Buf[i]<>Buf[i+1])
              then
                inc(i);
              LineStart:=i+1;
            end;
            inc(i);
          end;
          OutputLine:=copy(Buf,LineStart,Count-LineStart+1);
        until Count=0;
      finally
        TheProcess.Free;
      end;
    except
      on e: Exception do begin
        writeln('[TCompiler.Compile] exception "',E.Message,'"');
        FOutputList.Add(E.Message);
        if Assigned(OnOutputString) then
          OnOutputString(E.Message);
        Result:=mrCancel;
        exit;
      end;
    end;
  finally
    SetCurrentDir(OldCurDir);
  end;
  writeln('[TCompiler.Compile] end');
end;

{--------------------------------------------------------------------------
            TCompiler IsHintForUnusedProjectUnit
---------------------------------------------------------------------------}
function TCompiler.IsHintForUnusedProjectUnit(const OutputLine, 
  ProgramSrcFile: string): boolean;
{ recognizes hints of the form

  mainprogram.pp(5,35) Hint: Unit UNUSEDUNIT not used in mainprogram
}
var Filename: string;
begin
  Result:=false;
  Filename:=ExtractFilename(ProgramSrcFile);
  if CompareFilenames(Filename,copy(OutputLine,1,length(Filename)))<>0 then
    exit;
  if (pos(') Hint: Unit ',OutputLine)<>0)
  and (pos(' not used in ',OutputLine)<>0) then
    Result:=true;
end;

{--------------------------------------------------------------------------
            TCompiler GetSourcePosition
---------------------------------------------------------------------------}
function TCompiler.GetSourcePosition(const Line: string; var Filename:string;
  var CaretXY: TPoint; var MsgType: TErrorType): boolean;
{ This assumes the line has one of the following formats
<filename>(123,45) <ErrorType>: <some text>
<filename>(456) <ErrorType>: <some text> in line (123)
Fatal: <some text>
}
var StartPos, EndPos: integer;
begin
  Result:=false;
  if copy(Line,1,7)='Fatal: ' then begin
    Result:=true;
    Filename:='';
    MsgType:=etFatal;
    exit;
  end;
  StartPos:=1;
  // find filename
  EndPos:=StartPos;
  while (EndPos<=length(Line)) and (Line[EndPos]<>'(') do inc(EndPos);
  if EndPos>length(Line) then exit;
  FileName:=copy(Line,StartPos,EndPos-StartPos);
  // read linenumber
  StartPos:=EndPos+1;
  EndPos:=StartPos;
  while (EndPos<=length(Line)) and (Line[EndPos] in ['0'..'9']) do inc(EndPos);
  if EndPos>length(Line) then exit;
  CaretXY.Y:=StrToIntDef(copy(Line,StartPos,EndPos-StartPos),-1);
  if Line[EndPos]=',' then begin
    // format: <filename>(123,45) <ErrorType>: <some text>
    // read column
    StartPos:=EndPos+1;
    EndPos:=StartPos;
    while (EndPos<=length(Line)) and (Line[EndPos] in ['0'..'9']) do inc(EndPos);
    if EndPos>length(Line) then exit;
    CaretXY.X:=StrToIntDef(copy(Line,StartPos,EndPos-StartPos),-1);
    // read error type
    StartPos:=EndPos+2;
    while (EndPos<=length(Line)) and (Line[EndPos]<>':') do inc(EndPos);
    if EndPos>length(Line) then exit;
    MsgType:=ErrorTypeNameToType(copy(Line,StartPos,EndPos-StartPos));
    Result:=true;
  end else if Line[EndPos]=')' then begin
    // <filename>(456) <ErrorType>: <some text> in line (123)
    // read error type
    StartPos:=EndPos+2;
    while (EndPos<=length(Line)) and (Line[EndPos]<>':') do inc(EndPos);
    if EndPos>length(Line) then exit;
    MsgType:=ErrorTypeNameToType(copy(Line,StartPos,EndPos-StartPos));
    // read second linenumber (more useful)
    while (EndPos<=length(Line)) and (Line[EndPos]<>'(') do inc(EndPos);
    if EndPos>length(Line) then exit;
    StartPos:=EndPos+1;
    EndPos:=StartPos;
    while (EndPos<=length(Line)) and (Line[EndPos] in ['0'..'9']) do inc(EndPos);
    if EndPos>length(Line) then exit;
    CaretXY.Y:=StrToIntDef(copy(Line,StartPos,EndPos-StartPos),-1);
    Result:=true;
  end;
end;


end.

{
  $Log$
  Revision 1.26  2002/01/13 12:46:17  lazarus
  MG: fixed linker options, compiler options dialog

  Revision 1.25  2001/12/16 22:24:54  lazarus
  MG: changes for new compiler 20011216

  Revision 1.24  2001/12/10 08:19:52  lazarus
  MG: added hint for unset compiler path

  Revision 1.23  2001/12/10 07:47:00  lazarus
  MG: minor fixes

  Revision 1.22  2001/11/21 13:09:49  lazarus
  MG: moved executable check to ideprocs.pp

  Revision 1.20  2001/11/09 20:48:36  lazarus
  Minor fixes
  Shane

  Revision 1.19  2001/11/09 18:39:11  lazarus
  MG: turned back to stable ground (use old process.pp)

  Revision 1.18  2001/11/07 16:14:11  lazarus
  MG: fixes for the new compiler

  Revision 1.17  2001/11/06 15:47:31  lazarus
  MG: added build all

  Revision 1.16  2001/11/05 18:18:13  lazarus
  added popupmenu+arrows to notebooks, added target filename

  Revision 1.15  2001/10/23 09:13:50  lazarus
  MG: fixed TestProject

  Revision 1.14  2001/07/08 22:33:56  lazarus
  MG: added rapid testing project

  Revision 1.13  2001/05/29 08:16:26  lazarus
  MG: bugfixes + starting programs

  Revision 1.12  2001/04/04 12:20:34  lazarus
  MG: added  add to/remove from project, small bugfixes

  Revision 1.11  2001/03/31 13:35:22  lazarus
  MG: added non-visual-component code to IDE and LCL

  Revision 1.10  2001/03/29 12:38:58  lazarus
  MG: new environment opts, ptApplication bugfixes

  Revision 1.9  2001/03/26 14:52:30  lazarus
  MG: TSourceLog + compiling bugfixes

  Revision 1.8  2001/03/12 09:34:51  lazarus
  MG: added transfermacros, renamed dlgmessage.pp to msgview.pp

  Revision 1.7  2001/02/06 13:38:57  lazarus
  Fixes from Mattias for EditorOPtions
  Fixes to COmpiler that should allow people to compile if their path is set up.
  Changes to code completion.
  Shane

  Revision 1.6  2001/02/04 18:24:41  lazarus
  Code cleanup
  Shane

  Revision 1.5  2001/01/31 06:26:23  lazarus
  Removed global unit.                                         CAW

  Revision 1.4  2001/01/13 06:11:06  lazarus
  Minor fixes
  Shane

  Revision 1.2  2000/12/20 20:04:30  lazarus
  Made PRoject Build compile the active unit.  This way we can actually play with it by compiling units.

  Revision 1.1  2000/07/13 10:27:46  michael
  + Initial import

  Revision 1.13  2000/07/09 20:18:55  lazarus
  MWE:
    + added new controlselection
    + some fixes
    ~ some cleanup

  Revision 1.12  2000/05/10 02:34:43  lazarus
  Changed writelns to Asserts except for ERROR and WARNING messages.   CAW

  Revision 1.11  2000/05/01 06:11:59  lazarus
  Changed to get compiler options from the Compiler Options dialog. This
  now makes the Compiler Options dialog fully functional.            CAW

  Revision 1.10  2000/04/18 20:06:39  lazarus
  Added some functions to Compiler.pp

  Revision 1.9  2000/04/17 06:47:40  lazarus
  Started implementing the ability to compile.          CAW

  Revision 1.8  1999/07/04 03:29:57  lazarus
  Code Cleaning

  Revision 1.7  1999/05/24 21:20:12  lazarus
  *** empty log message ***

  Revision 1.6  1999/05/17 22:22:34  lazarus
  *** empty log message ***

  Revision 1.5  1999/05/14 18:44:04  lazarus
  *** empty log message ***

  Revision 1.4  1999/05/14 14:53:00  michael
  + Removed objpas from uses clause

  Revision 1.3  1999/04/20 02:56:42  lazarus
  *** empty log message ***

  Revision 1.2  1999/04/18 05:42:05  lazarus
  *** empty log message ***

  Revision 1.1  1999/04/14 07:31:44  michael
  + Initial implementation

}
