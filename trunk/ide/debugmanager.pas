{  $Id$  }
{
 /***************************************************************************
                             debugmanager.pp
                             ---------------
      TDebugManager controls all debugging related stuff in the IDE.


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
unit DebugManager;

{$mode objfpc}{$H+}

interface

{$I ide.inc}

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  Classes, SysUtils, Forms, Controls, Dialogs, CompilerOptions, EditorOptions,
  EnvironmentOpts, KeyMapping, UnitEditor, Project, IDEProcs,
  Debugger, RunParamsOpts, ExtToolDialog,
  ProjectDefs, BaseDebugManager, MainBar, DebuggerDlg;
  
type
  TDebugDialogType = (ddtOutput, ddtBreakpoints, ddtWatches, ddtLocals);

  TDebugManager = class(TBaseDebugManager)
    // Menu events
    procedure mnuViewDebugDialogClick(Sender: TObject);

    // SrcNotebook events
    procedure OnSrcNotebookAddWatchesAtCursor(Sender: TObject);
    procedure OnSrcNotebookCreateBreakPoint(Sender: TObject; Line: Integer);
    procedure OnSrcNotebookDeleteBreakPoint(Sender: TObject; Line: Integer);

    // Debugger events
    procedure OnDebuggerChangeState(Sender: TObject);
    procedure OnDebuggerCurrentLine(Sender: TObject; const ALocation: TDBGLocationRec);
    procedure OnDebuggerOutput(Sender: TObject; const AText: String);
    procedure OnDebuggerException(Sender: TObject; const AExceptionID: Integer; const AExceptionText: String);
  private
    FBreakPoints: TDBGBreakPoints; // Points to debugger breakpoints if available
                                   // Else to own objet
    FWatches: TDBGWatches;         // Points to debugger watchess if available
                                   // Else to own objet
    FDialogs: array[TDebugDialogType] of TDebuggerDlg;

    FDebugger: TDebugger;

    procedure DebugDialogDestroy(Sender: TObject);
    procedure ViewDebugDialog(const ADialogType: TDebugDialogType);
    procedure DestroyDebugDialog(const ADialogType: TDebugDialogType);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure ConnectMainBarEvents; override;
    procedure ConnectSourceNotebookEvents; override;
    procedure SetupMainBarShortCuts; override;

    function DoInitDebugger: TModalResult; override;
    function DoPauseProject: TModalResult; override;
    function DoStepIntoProject: TModalResult; override;
    function DoStepOverProject: TModalResult; override;
    function DoRunToCursor: TModalResult; override;
    function DoStopProject: TModalResult; override;
    
    procedure RunDebugger; override;
    procedure EndDebugging; override;
  end;
  
  

implementation

uses
  Menus,
  Watchesdlg, BreakPointsdlg, LocalsDlg, DBGOutputForm, GDBMIDebugger;

 
//-----------------------------------------------------------------------------
// Menu events
//-----------------------------------------------------------------------------

procedure TDebugManager.mnuViewDebugDialogClick(Sender: TObject);
begin                       
  ViewDebugDialog(TDebugDialogType(TMenuItem(Sender).Tag));
end;

//-----------------------------------------------------------------------------
// ScrNoteBook events
//-----------------------------------------------------------------------------

procedure TDebugManager.OnSrcNotebookAddWatchesAtCursor(Sender : TObject);
var
  SE : TSourceEditor;
  WatchVar: String;
  NewWatch: TdbgWatch;
begin
  if FDebugger = nil then Exit;

  //get the sourceEditor.
  SE := TSourceNotebook(sender).GetActiveSE;
  if not Assigned(SE) then Exit;
  WatchVar := SE.GetWordAtCurrentCaret;
  if WatchVar = ''  then Exit;

  NewWatch := FWatches.Add(WatchVar);
  NewWatch.Enabled := True;
end;

procedure TDebugManager.OnSrcNotebookCreateBreakPoint(Sender: TObject; Line: Integer);
var
  NewBreak: TDBGBreakPoint;
begin
  if SourceNotebook.Notebook = nil then Exit;

  NewBreak := FBreakPoints.Add(ExtractFilename(TSourceNotebook(sender).GetActiveSe.FileName), Line);
  NewBreak.Enabled := True;
end;

procedure TDebugManager.OnSrcNotebookDeleteBreakPoint(Sender: TObject; Line: Integer);
begin
  if SourceNotebook.Notebook = nil then Exit;

  FBreakPoints.Find(ExtractFilename(TSourceNotebook(sender).GetActiveSe.FileName), Line).Free;
end;

//-----------------------------------------------------------------------------
// Debugger events
//-----------------------------------------------------------------------------

procedure TDebugManager.OnDebuggerException(Sender: TObject; const AExceptionID: Integer; const AExceptionText: String);
begin
  MessageDlg('Error',
    Format('Project %s raised exception class %d with message ''%s''.', [Project1.Title, AExceptionID, AExceptionText]),
    mtError,[mbOk],0);
end;

procedure TDebugManager.OnDebuggerOutput(Sender: TObject; const AText: String);
begin
  if FDialogs[ddtOutput] <> nil
  then TDbgOutputForm(FDialogs[ddtOutput]).AddText(AText);
end;

procedure TDebugManager.OnDebuggerChangeState(Sender: TObject);
const
  // dsNone, dsIdle, dsStop, dsPause, dsRun, dsError
  TOOLSTATEMAP: array[TDBGState] of TIDEToolStatus = (
    // dsNone, dsIdle, dsStop, dsPause, dsRun, dsError
    itNone, itNone, itNone, itDebugger, itDebugger, itDebugger
  );
  STATENAME: array[TDBGState] of string = (
    'dsNone', 'dsIdle', 'dsStop', 'dsPause', 'dsRun', 'dsError'
  );
begin
  // Is the next line needed ???
  if (Sender<>FDebugger) or (Sender=nil) then exit;

  WriteLN('[TDebugManager.OnDebuggerChangeState] state: ', STATENAME[FDebugger.State]);

  // All conmmands
  // -------------------
  // dcRun, dcPause, dcStop, dcStepOver, dcStepInto, dcRunTo, dcJumpto, dcBreak, dcWatch
  // -------------------

  with MainIDE do begin
    // For run end step bypass idle, so we can set the filename later
    RunSpeedButton.Enabled := (dcRun in FDebugger.Commands) or (FDebugger.State = dsIdle);
    itmProjectRun.Enabled := RunSpeedButton.Enabled;
    PauseSpeedButton.Enabled := dcPause in FDebugger.Commands;
    itmProjectPause.Enabled := PauseSpeedButton.Enabled;
    StepIntoSpeedButton.Enabled := (dcStepInto in FDebugger.Commands) or (FDebugger.State = dsIdle);
    itmProjectStepInto.Enabled := StepIntoSpeedButton.Enabled;
    StepOverSpeedButton.Enabled := (dcStepOver in FDebugger.Commands)  or (FDebugger.State = dsIdle);
    itmProjectStepOver.Enabled := StepOverSpeedButton.Enabled;

    itmProjectRunToCursor.Enabled := dcRunTo in FDebugger.Commands;
    itmProjectStop.Enabled := dcStop in FDebugger.Commands;;

    // TODO: add other debugger menuitems
    // TODO: implement by actions

    ToolStatus := TOOLSTATEMAP[FDebugger.State];
  end;

  if FDebugger.State = dsError
  then begin
    WriteLN('Ooops, the debugger entered the error state');
  end;
end;

procedure TDebugManager.OnDebuggerCurrentLine(Sender: TObject;
  const ALocation: TDBGLocationRec);
// debugger paused program due to pause or error
// -> show the current execution line in editor
// if SrcLine = -1 then no source is available
var
  ActiveSrcEdit: TSourceEditor;
  UnitFile: String;
begin
  if (Sender<>FDebugger) or (Sender=nil) then exit;

  //TODO: Show assembler window if no source can be found.
  if ALocation.SrcLine = -1 then Exit;

  UnitFile := MainIDE.FindUnitFile(ALocation.SrcFile);
  if UnitFile = ''
  then UnitFile := ALocation.SrcFile;
  if MainIDE.DoOpenEditorFile(UnitFile, [ofOnlyIfExists]) <> mrOk then exit;

  ActiveSrcEdit := SourceNoteBook.GetActiveSE;
  if ActiveSrcEdit=nil then exit;

  with ActiveSrcEdit.EditorComponent do
  begin
    CaretXY:=Point(1, ALocation.SrcLine);
    BlockBegin:=CaretXY;
    BlockEnd:=CaretXY;
    TopLine:=ALocation.SrcLine-(LinesInWindow div 2);
  end;
  ActiveSrcEdit.ErrorLine:=ALocation.SrcLine;
end;

//-----------------------------------------------------------------------------
// Debugger dialog routines
//-----------------------------------------------------------------------------

// Common handler
// The tag of the destroyed form contains the form variable pointing to it
procedure TDebugManager.DebugDialogDestroy(Sender: TObject);
begin
  if  (TForm(Sender).Tag >= Ord(Low(TDebugDialogType)))
  and (TForm(Sender).Tag <= Ord(High(TDebugDialogType)))
  then FDialogs[TDebugDialogType(TForm(Sender).Tag)] := nil;
end;

procedure TDebugManager.ViewDebugDialog(const ADialogType: TDebugDialogType);
const
  DEBUGDIALOGCLASS: array[TDebugDialogType] of TDebuggerDlgClass = (
    TDbgOutputForm, TBreakPointsDlg, TWatchesDlg, TLocalsDlg
  );
begin
  if FDialogs[ADialogType] = nil
  then begin
    try
      FDialogs[ADialogType] := DEBUGDIALOGCLASS[ADialogType].Create(Self);
    except
      on E: Exception do begin
        WriteLN('[ERROR] IDE: Probably FPC bug #1888 caused an exception while creating class ''', DEBUGDIALOGCLASS[ADialogType].ClassName, '''');
        WriteLN('[ERROR] IDE: Exception message: ', E.Message);
        Exit;
      end;
    end;
    FDialogs[ADialogType].Tag := Integer(ADialogType);
    FDialogs[ADialogType].OnDestroy := @DebugDialogDestroy;
    DoInitDebugger;
    FDialogs[ADialogType].Debugger := FDebugger;
  end;
  FDialogs[ADialogType].Show;
  FDialogs[ADialogType].BringToFront;
end;

procedure TDebugManager.DestroyDebugDialog(const ADialogType: TDebugDialogType);
begin
  if FDialogs[ADialogType] = nil then Exit;
  FDialogs[ADialogType].OnDestroy := nil;
  FDialogs[ADialogType].Debugger := nil;
  FDialogs[ADialogType].Free;
  FDialogs[ADialogType] := nil;
end;

constructor TDebugManager.Create(TheOwner: TComponent);
var
  DialogType: TDebugDialogType;
begin                          
  for DialogType := Low(TDebugDialogType) to High(TDebugDialogType) do 
    FDialogs[DialogType] := nil; 
  
  FDebugger := nil;
  FBreakPoints := TDBGBreakPoints.Create(nil, TDBGBreakPoint);
  FWatches := TDBGWatches.Create(nil, TDBGWatch);
  inherited Create(TheOwner);
end;

destructor TDebugManager.Destroy;
var
  DialogType: TDebugDialogType;
begin                          
  for DialogType := Low(TDebugDialogType) to High(TDebugDialogType) do 
    DestroyDebugDialog(DialogType);
  
  if FDebugger <> nil
  then begin
    if FDebugger.BreakPoints = FBreakPoints
    then FBreakPoints := nil;
    if FDebugger.Watches = FWatches
    then FWatches := nil;
  
    FreeThenNil(FDebugger);
  end
  else begin
    FreeThenNil(FBreakPoints);
    FreeThenNil(FWatches);
  end;

  inherited Destroy;
end;

procedure TDebugManager.ConnectMainBarEvents;
begin
  with MainIDE do begin
    itmViewWatches.OnClick := @mnuViewDebugDialogClick;
    itmViewWatches.Tag := Ord(ddtWatches);
    itmViewBreakPoints.OnClick := @mnuViewDebugDialogClick;
    itmViewBreakPoints.Tag := Ord(ddtBreakPoints);
    itmViewLocals.OnClick := @mnuViewDebugDialogClick;
    itmViewLocals.Tag := Ord(ddtLocals);
    itmViewDebugOutput.OnClick := @mnuViewDebugDialogClick;
    itmViewDebugOutput.Tag := Ord(ddtOutput);
  end;
end;

procedure TDebugManager.ConnectSourceNotebookEvents;
begin
  SourceNotebook.OnAddWatchAtCursor := @OnSrcNotebookAddWatchesAtCursor;
  SourceNotebook.OnCreateBreakPoint := @OnSrcNotebookCreateBreakPoint;
  SourceNotebook.OnDeleteBreakPoint := @OnSrcNotebookDeleteBreakPoint;
end;

procedure TDebugManager.SetupMainBarShortCuts;
begin
  with MainIDE, EditorOpts.KeyMap do
  begin
    itmViewWatches.ShortCut := CommandToShortCut(ecToggleWatches);
    itmViewBreakpoints.ShortCut := CommandToShortCut(ecToggleBreakPoints);
    itmViewDebugOutput.ShortCut := CommandToShortCut(ecToggleDebuggerOut);
    itmViewLocals.ShortCut := CommandToShortCut(ecToggleLocals);
  end;
end;

//-----------------------------------------------------------------------------
// Debugger routines
//-----------------------------------------------------------------------------

function TDebugManager.DoInitDebugger: TModalResult;
  procedure ResetDialogs;
  var
    DialogType: TDebugDialogType;
  begin                          
    for DialogType := Low(TDebugDialogType) to High(TDebugDialogType) do 
    begin
      if FDialogs[DialogType] <> nil
      then FDialogs[DialogType].Debugger := FDebugger;
    end;
  end;
var
  OldBreakpoints: TDBGBreakpoints;
  OldWatches: TDBGWatches;
  LaunchingCmdLine, LaunchingApplication, LaunchingParams: String;
begin
  WriteLN('[TDebugManager.DoInitDebugger] A');

  Result:=mrCancel;
  if Project1.MainUnit < 0 then Exit;

  LaunchingCmdLine:=MainIDE.GetRunCommandLine;
  SplitCmdLine(LaunchingCmdLine,LaunchingApplication,LaunchingParams);

  OldBreakpoints := nil;
  OldWatches := nil;

  case EnvironmentOptions.DebuggerType of
    dtGnuDebugger: begin
      if (FDebugger <> nil)
      and ( not(FDebugger is TGDBMIDebugger)
            or (FDebugger.ExternalDebugger <> EnvironmentOptions.DebuggerFilename)
          )
      then begin
        OldBreakpoints := TDBGBreakpoints.Create(nil, TDBGBreakpoint);
        OldBreakpoints.Assign(FBreakPoints);
        FBreakPoints := nil;

        OldWatches := TDBGWatches.Create(nil, TDBGWatch);
        OldWatches.Assign(FWatches);
        FWatches := nil;

        FDebugger.Free;
        FDebugger := nil;
        ResetDialogs;
      end;
      if FDebugger = nil
      then begin
        if FBreakPoints <> nil
        then begin
          OldBreakpoints := TDBGBreakpoints.Create(nil, TDBGBreakpoint);
          OldBreakpoints.Assign(FBreakPoints);
        end;
        if FWatches <> nil
        then begin
          OldWatches := TDBGWatches.Create(nil, TDBGWatch);
          OldWatches.Assign(FWatches);
        end;
        FDebugger := TGDBMIDebugger.Create(EnvironmentOptions.DebuggerFilename);
        FBreakPoints := FDebugger.BreakPoints;
        FWatches := FDebugger.Watches;
        ResetDialogs;
      end;
      if OldBreakpoints <> nil
      then FBreakPoints.Assign(OldBreakpoints);
      if OldWatches <> nil
      then FWatches.Assign(OldWatches);
    end;
  else
    OldBreakpoints := FBreakPoints;
    FBreakPoints := TDBGBreakpoints.Create(nil, TDBGBreakpoint);
    FBreakPoints.Assign(OldBreakpoints);

    OldWatches := FWatches;
    FWatches := TDBGWatches.Create(nil, TDBGWatch);
    FWatches.Assign(OldWatches);

    FDebugger.Free;
    FDebugger := nil;
    ResetDialogs;
    Exit;
  end;
  FDebugger.OnState     := @OnDebuggerChangeState;
  FDebugger.OnCurrent   := @OnDebuggerCurrentLine;
  FDebugger.OnDbgOutput := @OnDebuggerOutput;
  FDebugger.OnException := @OnDebuggerException;
  if FDebugger.State = dsNone
  then FDebugger.Init;
  
  FDebugger.FileName := LaunchingApplication;
  FDebugger.Arguments := LaunchingParams;

  if FDialogs[ddtOutput] <> nil
  then TDbgOutputForm(FDialogs[ddtOutput]).Clear;

  //TODO: Show/hide debug menuitems based on FDebugger.SupportedCommands

  // property BreakPointGroups: TDBGBreakPointGroups read FBreakPointGroups; // list of all breakpoints
  // property Watches: TDBGWatches read FWatches;   // list of all watches localvars etc

  Result := mrOk;
  WriteLN('[TDebugManager.DoInitDebugger] END');
end;

// still part of main, should go here when dummydebugger is finished
//
//function TDebugManager.DoRunProject: TModalResult;

function TDebugManager.DoPauseProject: TModalResult;
begin
  Result := mrCancel;
  if (MainIDE.ToolStatus <> itDebugger)
  or (FDebugger = nil)
  then Exit;
  FDebugger.Pause;
  Result := mrOk;
end;

function TDebugManager.DoStepIntoProject: TModalResult;
begin
  if (MainIDE.DoInitProjectRun <> mrOK)
  or (MainIDE.ToolStatus <> itDebugger)
  or (FDebugger = nil)
  then begin
    Result := mrAbort;
    Exit;
  end;

  FDebugger.StepInto;
  Result := mrOk;
end;

function TDebugManager.DoStepOverProject: TModalResult;
begin
  if (MainIDE.DoInitProjectRun <> mrOK)
  or (MainIDE.ToolStatus <> itDebugger)
  or (FDebugger = nil)
  then begin
    Result := mrAbort;
    Exit;
  end;

  FDebugger.StepOver;
  Result := mrOk;
end;

function TDebugManager.DoStopProject: TModalResult;
begin
  Result := mrCancel;
  if (MainIDE.ToolStatus <> itDebugger)
  or (FDebugger=nil)
  then Exit;

  FDebugger.Stop;
  Result := mrOk;
end;

procedure TDebugManager.RunDebugger;
begin
  if FDebugger <> nil then FDebugger.Run;
end;

procedure TDebugManager.EndDebugging;
begin
  if FDebugger <> nil then FDebugger.Done;
end;

function TDebugManager.DoRunToCursor: TModalResult;
var
  ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  UnitFilename: string;
begin
  if (MainIDE.DoInitProjectRun <> mrOK)
  or (MainIDE.ToolStatus <> itDebugger)
  or (FDebugger = nil)
  then begin
    Result := mrAbort;
    Exit;
  end;

  Result := mrCancel;

  MainIDE.GetCurrentUnit(ActiveSrcEdit, ActiveUnitInfo);
  if (ActiveSrcEdit=nil) or (ActiveUnitInfo=nil)
  then begin
    MessageDlg('Run to failed','Please open a unit before run.',mtError,
      [mbCancel],0);
    Exit;
  end;

  if not ActiveUnitInfo.Source.IsVirtual
  then UnitFilename:=ActiveUnitInfo.Filename
  else UnitFilename:=MainIDE.GetTestUnitFilename(ActiveUnitInfo);

  FDebugger.RunTo(ExtractFilename(UnitFilename), ActiveSrcEdit.EditorComponent.CaretY);

  Result := mrOK;
end;

end.

