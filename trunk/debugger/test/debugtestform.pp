{ $Id$ }
{                        ----------------------------------------  
                          debugtestform.pp  -  Debugger test app
                         ---------------------------------------- 
 
 @created(Wed Feb 25st WET 2001)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.net>)                       

*************************************************************************** 
 *                                                                         * 
 *   This program is free software; you can redistribute it and/or modify  * 
 *   it under the terms of the GNU General Public License as published by  * 
 *   the Free Software Foundation; either version 2 of the License, or     * 
 *   (at your option) any later version.                                   * 
 *                                                                         * 
 ***************************************************************************/ 
} 
unit debugtestform;

{$mode objfpc}
{$H+}

interface

uses
  Classes, Graphics, Controls, Forms, Dialogs, LResources,
  Buttons, StdCtrls, Debugger, DbgOutputForm;

type
  TDebugTestForm = class(TForm)
    cmdInit : TButton;
    cmdDone : TButton;
    cmdRun : TButton;
    cmdPause : TButton;
    cmdStop : TButton;
    cmdStep : TButton;
    cmdStepInto : TButton;
    cmdSetBreak : TButton;
    cmdResetBreak : TButton;
    lblFileName: TLabel;
    lblAdress: TLabel;
    lblSource: TLabel;
    lblLine: TLabel;
    lblFunc: TLabel;
    lblState: TLabel;
    txtLog: TMemo;
    cmdCommand: TButton;
    cmdClear: TButton;
    txtCommand: TEdit;
    txtFileName: TEdit;
    txtBreakFile: TEdit;
    txtBreakLine: TEdit;
    chkBreakEnable: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cmdInitClick(Sender: TObject);
    procedure cmdDoneClick(Sender: TObject);
    procedure cmdRunClick(Sender: TObject);
    procedure cmdPauseClick(Sender: TObject);
    procedure cmdStopClick(Sender: TObject);
    procedure cmdStepClick(Sender: TObject);
    procedure cmdStepIntoClick(Sender: TObject);
    procedure cmdCommandClick(Sender: TObject);
    procedure cmdClearClick(Sender: TObject);
    procedure cmdSetBreakClick(Sender: TObject);
    procedure cmdResetBreakClick(Sender: TObject); 
    procedure chkBreakEnableClick(Sender: TObject);
  private
    FDebugger: TDebugger;
    FOutputForm: TDBGOutputForm;
    procedure DBGState(Sender: TObject);
    procedure DBGCurrent(Sender: TObject; const ALocation: TDBGLocationRec);
    procedure DBGOutput(Sender: TObject; const AText: String);
    procedure DBGTargetOutput(Sender: TObject; const AText: String);
    procedure OutputFormDestroy(Sender: TObject);
  protected
    procedure Loaded; override;
  public
    destructor Destroy; override;
  end;

var
  DebugTestForm1: TDebugTestForm;

implementation

uses
  SysUtils,
  GDBDebugger, DBGBreakPoint;

procedure TDebugTestForm.Loaded;
begin
  inherited Loaded;
  
  // Not yet through resources
  txtLog.Scrollbars := ssBoth;
end;

destructor TDebugTestForm.Destroy; 
begin
  // This shouldn't be needed, but the OnDestroy event isn't called
  inherited;                        
  FormDestroy(Self);
end;

procedure TDebugTestForm.FormCreate(Sender: TObject);
begin
  txtLog.Lines.Clear;
  FDebugger := nil;
end;

procedure TDebugTestForm.FormDestroy(Sender: TObject);
begin
  FDebugger.Free;
  FDebugger := nil;
end;

procedure TDebugTestForm.cmdInitClick(Sender: TObject);
begin
  if FDebugger = nil 
  then begin
    FDebugger := TGDBDebugger.Create;
    FDebugger.OnDbgOutput := @DBGOutput;
    FDebugger.OnOutput := @DBGTargetOutput;
    FDebugger.OnCurrent := @DBGCurrent;
    FDebugger.OnState := @DBGState;   
    TDBGBreakPointGroup(FDebugger.BreakPointGroups.Add).Name := 'Default';
                                               
    // Something strange going on here, 
    // sometimes the form crashes during load with Application as owner
    // sometimes the form crashes during load with nil as owner
    FOutputForm := TDBGOutputForm.Create(nil);
    FOutputForm.OnDestroy := @OutputFormDestroy;
    FOutputForm.Show;
  end;
  FDebugger.Init;
  FDebugger.FileName := txtFileName.Text;
end;

procedure TDebugTestForm.cmdDoneClick(Sender: TObject);
begin
  if FDebugger <> nil 
  then begin
    FDebugger.Done;
    FDebugger.Free;
    FDebugger := nil;
  end;
end;

procedure TDebugTestForm.cmdRunClick(Sender: TObject);
begin
  if FDebugger <> nil 
  then begin
    FDebugger.FileName := txtFileName.Text;
    FDebugger.Run; 
  end;
end;

procedure TDebugTestForm.cmdPauseClick(Sender: TObject);
begin
  if FDebugger <> nil 
  then begin
    FDebugger.Pause; 
  end;
end;

procedure TDebugTestForm.cmdStepClick(Sender: TObject);
begin
  if FDebugger <> nil 
  then begin
    FDebugger.StepOver; 
  end;
end;

procedure TDebugTestForm.cmdStepIntoClick(Sender: TObject);
begin
  if FDebugger <> nil 
  then begin
    FDebugger.StepInto; 
  end;
end;

procedure TDebugTestForm.cmdStopClick(Sender: TObject);
begin
  if FDebugger <> nil 
  then begin
    FDebugger.Stop; 
  end;
end;

procedure TDebugTestForm.cmdCommandClick(Sender: TObject);
begin
  TGDBDebugger(FDebugger).TestCmd(txtCommand.Text);
end;

procedure TDebugTestForm.cmdClearClick(Sender: TObject);
begin
  txtLog.Lines.Clear;
end;

procedure TDebugTestForm.cmdSetBreakClick(Sender: TObject);
begin
  FDebugger.Breakpoints.Add(txtBreakFile.Text, StrToIntDef(txtBreakLine.Text, 1));
end;

procedure TDebugTestForm.cmdResetBreakClick(Sender: TObject);
begin
  if FDebugger.Breakpoints.Count > 0
  then FDebugger.Breakpoints[0].Free;
end;

procedure TDebugTestForm.chkBreakEnableClick(Sender: TObject);
begin
  if FDebugger.Breakpoints.Count > 0
  then FDebugger.Breakpoints[0].Enabled := chkBreakEnable.Checked;
end;

procedure TDebugTestForm.OutputFormDestroy(Sender: TObject);
begin
  FOutputForm := nil;
end;

procedure TDebugTestForm.DBGOutput(Sender: TObject; const AText: String);
begin
  txtLog.Lines.Add(AText);
end;

procedure TDebugTestForm.DBGTargetOutput(Sender: TObject; const AText: String);
begin
  if FOutputForm <> nil
  then FOutputForm.AddText(AText);
end;

procedure TDebugTestForm.DBGCurrent(Sender: TObject; const ALocation: TDBGLocationRec);
begin
  lblAdress.Caption := Format('$%p', [ALocation.Adress]);
  lblSource.Caption := ALocation.SrcFile; 
  lblLine.Caption := IntToStr(ALocation.SrcLine);
  lblFunc.Caption := ALocation.FuncName;
end;

procedure TDebugTestForm.DBGState(Sender: TObject);
begin
  case FDebugger.State of
    dsNone :lblState.Caption := 'dsNone ';
    dsIdle :lblState.Caption := 'dsIdle ';
    dsStop :lblState.Caption := 'dsStop ';
    dsPause:lblState.Caption := 'dsPause'; 
    dsRun  :lblState.Caption := 'dsRun  ';
    dsError:lblState.Caption := 'dsError';
  else
    lblState.Caption := '?';
  end;
end;

initialization
  {$I debugtestform.lrc}

end.
{ =============================================================================
  $Log$
  Revision 1.3  2002/02/05 23:16:48  lazarus
  MWE: * Updated tebugger
       + Added debugger to IDE

  Revision 1.2  2001/11/06 23:59:13  lazarus
  MWE: + Initial breakpoint support
       + Added exeption handling on process.free

  Revision 1.1  2001/11/05 00:12:51  lazarus
  MWE: First steps of a debugger.

}
