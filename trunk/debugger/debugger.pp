{ $Id$ }
{                        ----------------------------------------  
                           Debugger.pp  -  Debugger base classes
                         ---------------------------------------- 
 
 @created(Wed Feb 25st WET 2001)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.net>)                       

 This unit contains the base class definitions of the debugger. These
 classes are only definitions. Implemented debuggers should be
 derived from these. 
 
/*************************************************************************** 
 *                                                                         * 
 *   This program is free software; you can redistribute it and/or modify  * 
 *   it under the terms of the GNU General Public License as published by  * 
 *   the Free Software Foundation; either version 2 of the License, or     * 
 *   (at your option) any later version.                                   * 
 *                                                                         * 
 ***************************************************************************/ 
} 
unit Debugger;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  TDBGLocationRec = record
    Adress: Pointer;
    FuncName: String;
    SrcFile: String;
    SrcLine: Integer;
  end;

  TDBGCommand = (dcRun, dcPause, dcStop, dcStepOver, dcStepInto, dcRunTo, dcJumpto, dcBreak, dcWatch, dcLocal);
  TDBGCommands = set of TDBGCommand;
  TDBGState = (dsNone, dsIdle, dsStop, dsPause, dsRun, dsError);
  
(*
  Debugger states
  --------------------------------------------------------------------------
  dsNone: 
    The debug object is created, but no instance of an external debugger 
    exists.
    Initial state, leave with Init, enter with Done
  
  dsIdle:
    The external debugger is started, but no filename (or no other params 
    requred to start) were given.
    
  dsStop:
    (Optional) The execution of the target is stopped
    The external debugger is loaded and ready to (re)start the execution 
    of the target.
    Breakpoints, wathes etc can be defined
    
  dsPause:
    De debugger has paused the target. Targer variables canbe examined
    
  dsRun:
    The target is running.
    
  dsError:
    Something unforseen has happened. A shutdown of the debugger is in
    most cases needed.
  --------------------------------------------------------------------------
  
*)  


  TDBGBreakPointAction = (bpaStop, bpaEnableGroup, bpaDisableGroup);
  TDBGBreakPointActions =set of TDBGBreakPointAction;

  TDebugger = class;
  TDBGBreakPointGroup = class;
  TDBGBreakPointClass = class of TDBGBreakPoint;
  TDBGBreakPoint = class(TCollectionItem)
  private
    FDebugger: TDebugger;  // reference to our debugger
    FGroup: TDBGBreakPointGroup;
    FValid: Boolean;
    FEnabled: Boolean;
    FHitCount: Integer;
    FExpression: String;                                             
    FSource: String; 
    FLine: Integer;
    FFirstRun: Boolean;
    FActions: TDBGBreakPointActions;
    FDisableGroupList: TList;
    FEnableGroupList: TList;
    procedure SetActions(const AValue: TDBGBreakPointActions); 
    procedure SetEnabled(const AValue: Boolean); 
    procedure SetExpression(const AValue: String); 
    procedure SetGroup(const AValue: TDBGBreakPointGroup);
  protected                                        
    procedure AssignTo(Dest: TPersistent); override;
    procedure DisableGroups;
    procedure DoActionChange; virtual;
    procedure DoEnableChange; virtual;
    procedure DoExpressionChange; virtual;
    procedure DoStateChange; virtual;
    procedure EnableGroups;
    procedure SetHitCount(const AValue: Integer); 
    procedure SetLocation(const ASource: String; const ALine: Integer); virtual;
    procedure SetValid(const AValue: Boolean); 
    property  Debugger: TDebugger read FDebugger;
  public
    procedure AddDisableGroup(const AGroup: TDBGBreakPointGroup);
    procedure AddEnableGroup(const AGroup: TDBGBreakPointGroup);
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure RemoveDisableGroup(const AGroup: TDBGBreakPointGroup);
    procedure RemoveEnableGroup(const AGroup: TDBGBreakPointGroup);
    property Actions: TDBGBreakPointActions read FActions write SetActions;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Group: TDBGBreakPointGroup read FGroup write SetGroup;
    property HitCount: Integer read FHitCount;
    property Expression: String read FExpression write SetExpression;
    property Source: String read FSource; 
    property Line: Integer read FLine;
    property Valid: Boolean read FValid;
  end;

  TDBGBreakPoints = class;
  TDBGBreakPointsEvent = procedure(const ASender: TDBGBreakPoints; const ABreakpoint: TDBGBreakPoint) of object;
  TDBGBreakPoints = class(TCollection)
  private
    FDebugger: TDebugger;  // reference to our debugger
    FOnAdd:    TDBGBreakPointsEvent;
    FOnUpdate: TDBGBreakPointsEvent;  //Item will be nil in case all items need to be updated
    FOnRemove: TDBGBreakPointsEvent;
    function GetItem(const AnIndex: Integer): TDBGBreakPoint;
    procedure SetItem(const AnIndex: Integer; const AValue: TDBGBreakPoint);
  protected
    procedure DoStateChange; virtual;
    procedure Update(Item: TCollectionItem); override;
  public 
    constructor Create(const ADebugger: TDebugger; const ABreakPointClass: TDBGBreakPointClass);
    function Add(const ASource: String; const ALine: Integer): TDBGBreakPoint;
    function Find(const ASource: String; const ALine: Integer): TDBGBreakPoint;
    property Items[const AnIndex: Integer]: TDBGBreakPoint read GetItem write SetItem; default;
    property OnAdd:    TDBGBreakPointsEvent read FOnAdd write FOnAdd;
    property OnUpdate: TDBGBreakPointsEvent read FOnUpdate write FOnUpdate;  
    property OnRemove: TDBGBreakPointsEvent read FOnRemove write FonRemove;
  end;
  
  TDBGBreakPointGroup = class(TCollectionItem)
  private
    FEnabled: Boolean;
    FName: String;
    FBreakpoints: TList;  // A list of breakpoints that member
    FReferences: TList;   // A list of breakpoints that refer to us through En/disable group
    function GetBreakpoint(const AIndex: Integer): TDBGBreakPoint;
    procedure SetEnabled(const AValue: Boolean);
    procedure SetName(const AValue: String);
  protected
    procedure AddReference(const ABreakPoint: TDBGBreakPoint);
    procedure RemoveReference(const ABreakPoint: TDBGBreakPoint);
  public
    function Add(const ABreakPoint: TDBGBreakPoint): Integer;
    function Count: Integer;
    constructor Create(ACollection: TCollection); override;
    procedure Delete(const AIndex: Integer);
    destructor Destroy; override;
    function Remove(const ABreakPoint: TDBGBreakPoint): Integer;
    property Breakpoints[const AIndex: Integer]: TDBGBreakPoint read GetBreakpoint;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Name: String read FName write SetName;
  end;

  TDBGBreakPointGroups = class(TCollection)
  private                     
    function GetItem(const AnIndex: Integer): TDBGBreakPointGroup;
    procedure SetItem(const AnIndex: Integer; const AValue: TDBGBreakPointGroup);
  protected
  public
    constructor Create;
    property Items[const AnIndex: Integer]: TDBGBreakPointGroup read GetItem write SetItem; default;
  end;

  TDBGWatchClass = class of TDBGWatch;
  TDBGWatch = class(TCollectionItem)
  private
    FDebugger: TDebugger;  // reference to our debugger
    FEnabled: Boolean;
    FExpression: String;
    //FValue: String;
    FOnChange: TNotifyEvent;
    procedure SetEnabled(const AValue: Boolean);
  protected
    procedure DoEnableChange; virtual;
    procedure DoStateChange; virtual; 
    function  GetValue: String; virtual;
    function  GetValid: Boolean; virtual;
    procedure SetExpression(const AValue: String); virtual;
    procedure SetValue(const AValue: String); virtual;
    property  Debugger: TDebugger read FDebugger;
  public
    constructor Create(ACollection: TCollection); override;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Expression: String read FExpression write SetExpression;
    property Valid: Boolean read GetValid;
    property Value: String read GetValue write SetValue;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TDBGWatches = class(TCollection)
  private
    FDebugger: TDebugger;  // reference to our debugger
    function GetItem(const AnIndex: Integer): TDBGWatch;
    procedure SetItem(const AnIndex: Integer; const AValue: TDBGWatch);
  protected
    procedure DoStateChange; virtual;
  public
    constructor Create(const ADebugger: TDebugger; const AWatchClass: TDBGWatchClass); 
    property Items[const AnIndex: Integer]: TDBGWatch read GetItem write SetItem; default;
  end;
          
  TDBGLocals = class(TObject)
  private
    FDebugger: TDebugger;  // reference to our debugger
    FOnChange: TNotifyEvent;
  protected
    procedure DoChange; 
    procedure DoStateChange; virtual;
    function GetName(const AnIndex: Integer): String; virtual;
    function GetValue(const AnIndex: Integer): String; virtual;
    property Debugger: TDebugger read FDebugger;
  public
    function Count: Integer; virtual;
    constructor Create(const ADebugger: TDebugger); 
    property Names[const AnIndex: Integer]: String read GetName;
    property Values[const AnIndex: Integer]: String read GetValue;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;
          
  TDBGOutputEvent = procedure(Sender: TObject; const AText: String) of object;
  TDBGCurrentLineEvent = procedure(Sender: TObject; const ALocation: TDBGLocationRec) of object;
  TDBGExceptionEvent = procedure(Sender: TObject; const AExceptionID: Integer; const AExceptionText: String) of object;

  TDebugger = class(TObject)
  private
    FArguments: String;
    FBreakPoints: TDBGBreakPoints;
    FBreakPointGroups: TDBGBreakPointGroups;
    FExitCode: Integer;
    FExternalDebugger: String; 
    FFileName: String;    
    FLocals: TDBGLocals;                          
    FState: TDBGState;
    FWatches: TDBGWatches;
    FOnCurrent: TDBGCurrentLineEvent;
    FOnException: TDBGExceptionEvent;
    FOnOutput: TDBGOutputEvent;
    FOnDbgOutput: TDBGOutputEvent;
    FOnState: TNotifyEvent;
    function  GetState: TDBGState;              
    function  ReqCmd(const ACommand: TDBGCommand; const AParams: array of const): Boolean; 
    procedure SetFileName(const AValue: String); 
  protected  
    function  CreateBreakPoints: TDBGBreakPoints; virtual;
    function  CreateLocals: TDBGLocals; virtual;
    function  CreateWatches: TDBGWatches; virtual;
    procedure DoCurrent(const ALocation: TDBGLocationRec);
    procedure DoDbgOutput(const AText: String);
    procedure DoException(const AExceptionID: Integer; const AExceptionText: String);
    procedure DoOutput(const AText: String);
    procedure DoState;
    function  ChangeFileName: Boolean; virtual;
    function  GetCommands: TDBGCommands; 
    function  GetSupportedCommands: TDBGCommands; virtual;
    function  RequestCommand(const ACommand: TDBGCommand; const AParams: array of const): Boolean; virtual; abstract; // True if succesful
    procedure SetExitCode(const AValue: Integer); 
    procedure SetState(const AValue: TDBGState); 
  public
    constructor Create(const AExternalDebugger: String); {virtual; Virtual constructor makes no sense}
                        //MWE: there will be a day that they do make sense :-)
    destructor Destroy; override;
    
    procedure Init; virtual;                         // Initializes the debugger
    procedure Done; virtual;                         // Kills the debugger
    procedure Run;                                   // Starts / continues debugging
    procedure Pause;                                 // Stops running
    procedure Stop;                                  // quit debugging
    procedure StepOver;         
    procedure StepInto;          
    procedure RunTo(const ASource: String; const ALine: Integer); virtual;       // Executes til a certain point
    procedure JumpTo(const ASource: String; const ALine: Integer); virtual;      // No execute, only set exec point
    property SupportedCommands: TDBGCommands read GetSupportedCommands;          // All available commands of the debugger
    property Arguments: String read FArguments write FArguments;                 // Arguments feed to the program
    property BreakPoints: TDBGBreakPoints read FBreakPoints;                     // list of all breakpoints
    property BreakPointGroups: TDBGBreakPointGroups read FBreakPointGroups;      // list of all breakpointgroups
    property Commands: TDBGCommands read GetCommands;                            // All current available commands of the debugger
    property ExitCode: Integer read FExitCode;
    property ExternalDebugger: String read FExternalDebugger;
    property FileName: String read FFileName write SetFileName;                  // The name of the exe to be debugged
    property Locals: TDBGLocals read FLocals;
    property State: TDBGState read FState;                                       // The current state of the debugger    
    property Watches: TDBGWatches read FWatches;                                 // list of all watches localvars etc
    property OnCurrent: TDBGCurrentLineEvent read FOnCurrent write FOnCurrent;   // Passes info about the current line being debugged
    property OnException: TDBGExceptionEvent read FOnException write FOnException;  // Fires when the debugger received an exeption
    property OnState: TNotifyEvent read FOnState write FOnState;                 // Fires when the current state of the debugger changes
    property OnOutput: TDBGOutputEvent read FOnOutput write FOnOutput;           // Passes all output of the debugged target
    property OnDbgOutput: TDBGOutputEvent read FOnDbgOutput write FOnDbgOutput;  // Passes all debuggeroutput        
  end;   
  
implementation

uses
  SysUtils;
  
const
  COMMANDMAP: array[TDBGState] of TDBGCommands = (
  {dsNone } [], 
  {dsIdle } [],
  {dsStop } [dcRun, dcStepOver, dcStepInto, dcRunTo, dcJumpto, dcBreak, dcWatch],
  {dsPause} [dcRun, dcStop, dcStepOver, dcStepInto, dcRunTo, dcJumpto, dcBreak, dcWatch, dcLocal],
  {dsRun  } [dcPause, dcStop, dcBreak, dcWatch],
  {dsError} [dcStop]
  );

{ =========================================================================== }
{ TDebugger }
{ =========================================================================== }
              
function TDebugger.ChangeFileName: Boolean;              
begin
  Result := True;
end;
              
constructor TDebugger.Create(const AExternalDebugger: String);
begin
  inherited Create;
  FOnState := nil;
  FOnCurrent := nil;
  FOnOutput := nil;
  FOnDbgOutput := nil;
  FState := dsNone;
  FArguments := '';
  FFilename := '';
  FExternalDebugger := AExternalDebugger;
  FBreakPoints := CreateBreakPoints;
  FLocals := CreateLocals;
  FWatches := CreateWatches;
  FBreakPointGroups := TDBGBreakPointGroups.Create;
  FExitCode := 0;
end;

function TDebugger.CreateBreakPoints: TDBGBreakPoints; 
begin                                                            
  Result := TDBGBreakPoints.Create(Self, TDBGBreakPoint);
end;

function TDebugger.CreateLocals: TDBGLocals; 
begin                                                            
  Result := TDBGLocals.Create(Self);
end;

function TDebugger.CreateWatches: TDBGWatches; 
begin         
  Result := TDBGWatches.Create(Self, TDBGWatch);
end;

destructor TDebugger.Destroy;
begin
  // don't call events
  FOnState := nil;
  FOnCurrent := nil;
  FOnOutput := nil;
  FOnDbgOutput := nil;

  if FState <> dsNone
  then Done;
  
  FBreakPointGroups.Free;
  FWatches.Free;
  inherited;
end;

procedure TDebugger.Done;
begin
  SetState(dsNone);
end;

procedure TDebugger.DoCurrent(const ALocation: TDBGLocationRec);
begin
  if Assigned(FOnCurrent) then FOnCurrent(Self, ALocation);
end;

procedure TDebugger.DoDbgOutput(const AText: String);
begin
  if Assigned(FOnDbgOutput) then FOnDbgOutput(Self, AText);
end;

procedure TDebugger.DoException(const AExceptionID: Integer; const AExceptionText: String);
begin
  if Assigned(FOnException) then FOnException(Self, AExceptionID, AExceptionText);
end;

procedure TDebugger.DoOutput(const AText: String);
begin
  if Assigned(FOnOutput) then FOnOutput(Self, AText);
end;

procedure TDebugger.DoState;
begin
  if Assigned(FOnState) then FOnState(Self);
end;

function TDebugger.GetCommands: TDBGCommands; 
begin
  Result := COMMANDMAP[State] * GetSupportedCommands;
end;

function TDebugger.GetState: TDBGState;
begin
  Result := FState;
end;

function TDebugger.GetSupportedCommands: TDBGCommands; 
begin
  Result := [];
end;

procedure TDebugger.Init;
begin    
  FExitCode := 0;
  SetState(dsIdle);
end;

procedure TDebugger.JumpTo(const ASource: String; const ALine: Integer);
begin
  ReqCmd(dcJumpTo, [ASource, ALine]);
end;

procedure TDebugger.Pause;
begin
  ReqCmd(dcPause, []);
end;

function TDebugger.ReqCmd(const ACommand: TDBGCommand; const AParams: array of const): Boolean; 
begin
  if FState = dsNone then Init;
  if ACommand in Commands 
  then Result := RequestCommand(ACommand, AParams)
  else Result := False;
end;

procedure TDebugger.Run;
begin
  ReqCmd(dcRun, []);
end;

procedure TDebugger.RunTo(const ASource: String; const ALine: Integer);
begin
  ReqCmd(dcRunTo, [ASource, ALine]);
end;

procedure TDebugger.SetExitCode(const AValue: Integer); 
begin
  FExitCode := AValue;
end;

procedure TDebugger.SetFileName(const AValue: String);
begin
  if FFileName <> AValue
  then begin 
    if FState in [dsRun, dsPause]
    then begin
      Stop;    
      // check if stopped
      if FState <> dsStop
      then SetState(dsError);
    end;
       
    if FState = dsStop
    then begin
      // Reset state
      FFileName := '';
      SetState(dsIdle); 
    end;
    
    FFileName := AValue;
    if (FFilename <> '') and (FState = dsIdle) and ChangeFileName
    then SetState(dsStop); 
  end;
end;

procedure TDebugger.SetState(const AValue: TDBGState); 
begin
  if AValue <> FState 
  then begin
    FState := AValue;
    FBreakpoints.DoStateChange;
    FLocals.DoStateChange;
    FWatches.DoStateChange;
    DoState;
  end;
end;

procedure TDebugger.StepInto;
begin
  ReqCmd(dcStepInto, []);
end;

procedure TDebugger.StepOver;
begin
  ReqCmd(dcStepOver, []);
end;

procedure TDebugger.Stop;
begin
  ReqCmd(dcStop, []);
end;

{ =========================================================================== }
{ TDBGBreakPoint }
{ =========================================================================== }

procedure TDBGBreakPoint.AddDisableGroup(const AGroup: TDBGBreakPointGroup);
begin
  if AGroup = nil then Exit;
  FDisableGroupList.Add(AGroup);
  AGroup.AddReference(Self);
  Changed(False);
end;

procedure TDBGBreakPoint.AddEnableGroup(const AGroup: TDBGBreakPointGroup);
begin
  if AGroup = nil then Exit;
  FEnableGroupList.Add(AGroup);
  AGroup.AddReference(Self);
  Changed(False);
end;

procedure TDBGBreakPoint.AssignTo(Dest: TPersistent);
begin
  if Dest is TDBGBreakPoint 
  then begin
    TDBGBreakPoint(Dest).SetLocation(FSource, FLine);
    TDBGBreakPoint(Dest).SetExpression(FExpression);
    TDBGBreakPoint(Dest).SetActions(FActions);
    TDBGBreakPoint(Dest).SetEnabled(FEnabled);
  end
  else inherited; 
end;

constructor TDBGBreakPoint.Create(ACollection: TCollection); 
begin
  inherited Create(ACollection);
  FSource := '';
  FLine := -1;
  FValid := False;
  FEnabled := False;
  FHitCount := 0;
  FExpression := '';
  FGroup := nil;      
  FFirstRun := True;  
  FActions := [bpaStop];
  FDebugger := TDBGBreakPoints(ACollection).FDebugger;
  FDisableGroupList := TList.Create;
  FEnableGroupList := TList.Create;
end;

destructor TDBGBreakPoint.Destroy;
var
  n: Integer;
begin
  if (TDBGBreakPoints(Collection) <> nil)
  and Assigned(TDBGBreakPoints(Collection).FOnRemove) 
  then TDBGBreakPoints(Collection).FOnRemove(TDBGBreakPoints(Collection), Self);
  
  if FGroup <> nil
  then FGroup.Remove(Self);
  
  for n := 0 to FDisableGroupList.Count - 1 do
    TDBGBreakPointGroup(FDisableGroupList[n]).RemoveReference(Self);
  for n := 0 to FEnableGroupList.Count - 1 do
    TDBGBreakPointGroup(FEnableGroupList[n]).RemoveReference(Self);
  
  inherited;
  FreeAndNil(FDisableGroupList);
  FreeAndNil(FEnableGroupList);
end;

procedure TDBGBreakPoint.DisableGroups;
var
  n: Integer;
begin
  for n := 0 to FDisableGroupList.Count - 1 do
    TDBGBreakPointGroup(FDisableGroupList[n]).Enabled := False;
end;

procedure TDBGBreakPoint.DoActionChange; 
begin
  Changed(False);
end;

procedure TDBGBreakPoint.DoEnableChange; 
begin
  Changed(False);
end;

procedure TDBGBreakPoint.DoExpressionChange; 
begin
  Changed(False);
end;

procedure TDBGBreakPoint.DoStateChange; 
begin  
  case Debugger.State of
    dsStop, dsIdle: begin
      FFirstRun := True;
    end;
    dsRun: begin
      if FFirstRun 
      then begin
        FHitCount := 0;
        FFirstRun := False;
      end;
    end;
  end;  
end;

procedure TDBGBreakPoint.EnableGroups;
var
  n: Integer;
begin
  for n := 0 to FDisableGroupList.Count - 1 do
    TDBGBreakPointGroup(FDisableGroupList[n]).Enabled := True;
end;

procedure TDBGBreakPoint.RemoveDisableGroup(const AGroup: TDBGBreakPointGroup);
begin                                                                          
  if AGroup = nil then Exit;
  FDisableGroupList.Remove(AGroup);
  AGroup.RemoveReference(Self);
end;

procedure TDBGBreakPoint.RemoveEnableGroup(const AGroup: TDBGBreakPointGroup);
begin
  if AGroup = nil then Exit;
  FEnableGroupList.Remove(AGroup);
  AGroup.RemoveReference(Self);
end;

procedure TDBGBreakPoint.SetActions(const AValue: TDBGBreakPointActions);
begin
  if FActions <> AValue
  then begin
    FActions := AValue;
    DoActionChange;
    Changed(False);
  end;
end;

procedure TDBGBreakPoint.SetEnabled(const AValue: Boolean);
begin
  if FEnabled <> AValue
  then begin
    FEnabled := AValue;
    DoEnableChange;
    Changed(False);
  end;
end;

procedure TDBGBreakPoint.SetExpression(const AValue: String);
begin
  if FExpression <> AValue
  then begin
    FExpression := AValue;
    DoExpressionChange;
    Changed(False);
  end;
end;

procedure TDBGBreakPoint.SetGroup(const AValue: TDBGBreakPointGroup);
var
  Grp: TDBGBreakPointGroup;
begin
  if FGroup <> AValue
  then begin
    
    if FGroup <> nil 
    then begin
      Grp := FGroup;
      FGroup := nil;  //  avoid second entrance
      Grp.Remove(Self);
    end;
    FGroup := AValue;
    if FGroup <> nil 
    then begin
      FGroup.Add(Self);
    end;
    Changed(False);
  end;
end;

procedure TDBGBreakPoint.SetHitCount(const AValue: Integer);
begin
  if FHitCount <> AValue
  then begin
    FHitCount := AValue;
    Changed(False);
  end;
end;

procedure TDBGBreakPoint.SetLocation(const ASource: String; const ALine: Integer); 
begin
  if (FSource <> ASource)
  or (FLine <> ALine)
  then begin
    FSource := ASource;
    FLine := ALine;
    Changed(False);
  end;
end;

procedure TDBGBreakPoint.SetValid(const AValue: Boolean);
begin
  if FValid <> AValue
  then begin
    FValid := AValue;
    Changed(False);
  end;
end;

{ =========================================================================== }
{ TDBGBreakPoints }
{ =========================================================================== }

function TDBGBreakPoints.Add(const ASource: String; const ALine: Integer): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Add);
  Result.SetLocation(ASource, ALine);
  if Assigned(FOnAdd) then FOnAdd(Self, Result);
end;

constructor TDBGBreakPoints.Create(const ADebugger: TDebugger; const ABreakPointClass: TDBGBreakPointClass);
begin
  inherited Create(ABreakPointClass);
  FDebugger := ADebugger;
end;

procedure TDBGBreakPoints.DoStateChange;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
    GetItem(n).DoStateChange;
end;

function TDBGBreakPoints.Find(const ASource: String; const ALine: Integer): TDBGBreakPoint;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
  begin
    Result := GetItem(n);
    if  (Result.Line = ALine)
    and (Result.Source = ASource)
    then Exit;
  end;    
  Result := nil;
end;

function TDBGBreakPoints.GetItem(const AnIndex: Integer): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited GetItem(AnIndex));
end;

procedure TDBGBreakPoints.SetItem(const AnIndex: Integer; const AValue: TDBGBreakPoint);
begin  
  SetItem(AnIndex, AValue);   
end;

procedure TDBGBreakPoints.Update(Item: TCollectionItem); 
begin
  // Note: Item will be nil in case all items need to be updated
  if Assigned(FOnUpdate) 
  then FOnUpdate(Self, TDBGBreakPoint(Item)); 
end;

{ =========================================================================== }
{ TDBGBreakPointGroup }
{ =========================================================================== }

function TDBGBreakPointGroup.Add(const ABreakPoint: TDBGBreakPoint): Integer;
begin
  Result := FBreakpoints.IndexOf(ABreakPoint); //avoid dups
  if Result = -1
  then begin
    Result := FBreakpoints.Add(ABreakPoint);
    ABreakpoint.Group := Self;
  end;
end;

procedure TDBGBreakPointGroup.AddReference(const ABreakPoint: TDBGBreakPoint);
begin
  FReferences.Add(ABreakPoint); 
end;

function TDBGBreakPointGroup.Count: Integer;
begin
  Result := FBreakpoints.Count;
end;

constructor TDBGBreakPointGroup.Create(ACollection: TCollection); 
begin
  inherited Create(ACollection);
  FBreakpoints := TList.Create;
  FReferences := TList.Create;
  FEnabled := True;
end;

procedure TDBGBreakPointGroup.Delete(const AIndex: Integer);
begin
  Remove(TDBGBreakPoint(FBreakPoints[AIndex]));
end;

destructor TDBGBreakPointGroup.Destroy; 
var
  n: Integer;
begin     
  for n := FBreakpoints.Count - 1 downto 0 do
    TDBGBreakPoint(FBreakpoints[n]).Group := nil;
  for n := FReferences.Count - 1 downto 0 do
    TDBGBreakPoint(FReferences[n]).RemoveDisableGroup(Self);
  for n := FReferences.Count - 1 downto 0 do
    TDBGBreakPoint(FReferences[n]).RemoveEnableGroup(Self);
      
  inherited Destroy;
  FreeAndNil(FBreakpoints);
  FreeAndNil(FReferences);
end;

function TDBGBreakPointGroup.GetBreakpoint(const AIndex: Integer): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(FBreakPoints[AIndex]);
end;

function TDBGBreakPointGroup.Remove(const ABreakPoint: TDBGBreakPoint): Integer;
begin
  Result := FBreakpoints.Remove(ABreakPoint);
  if ABreakpoint.Group = Self
  then ABreakpoint.Group := nil;
end;

procedure TDBGBreakPointGroup.RemoveReference(const ABreakPoint: TDBGBreakPoint);
begin
  FReferences.Remove(ABreakPoint); 
end;

procedure TDBGBreakPointGroup.SetEnabled(const AValue: Boolean);
var
  n: Integer;
begin
  if FEnabled <> AValue
  then begin
    FEnabled := AValue;
    for n := 0 to FBreakPoints.Count - 1 do
      TDBGBreakpoint(FBreakPoints[n]).Enabled := FEnabled;
  end;
end;

procedure TDBGBreakPointGroup.SetName(const AValue: String);
begin
  FName := AValue;
end;

{ =========================================================================== }
{ TDBGBreakPointGroups }
{ =========================================================================== }

constructor TDBGBreakPointGroups.Create; 
begin
  inherited Create(TDBGBreakPointGroup);
end;

function TDBGBreakPointGroups.GetItem(const AnIndex: Integer): TDBGBreakPointGroup;
begin
  Result := TDBGBreakPointGroup(inherited GetItem(AnIndex));
end;

procedure TDBGBreakPointGroups.SetItem(const AnIndex: Integer; const AValue: TDBGBreakPointGroup);
begin
  inherited SetItem(AnIndex, AValue);
end;

{ =========================================================================== }
{ TDBGWatch }
{ =========================================================================== }

constructor TDBGWatch.Create(ACollection: TCollection); 
begin
  inherited Create(ACollection);
  FEnabled := False;
  FDebugger := TDBGWatches(ACollection).FDebugger;
end;

procedure TDBGWatch.DoEnableChange; 
begin
end;

procedure TDBGWatch.DoStateChange;  
begin
end;

function TDBGWatch.GetValid: Boolean;
begin
  Result := False;
end;

function TDBGWatch.GetValue: String;
begin
  if Valid 
  then Result := '<unknown>'
  else Result := '<invalid>';
end;

procedure TDBGWatch.SetEnabled(const AValue: Boolean);
begin
  if FEnabled <> AValue
  then begin
    FEnabled := AValue;
    DoEnableChange;
 end;
end;

procedure TDBGWatch.SetExpression(const AValue: String);
begin
end;

procedure TDBGWatch.SetValue(const AValue: String);
begin
end;

{ =========================================================================== }
{ TDBGWatches }
{ =========================================================================== }

constructor TDBGWatches.Create(const ADebugger: TDebugger; const AWatchClass: TDBGWatchClass);
begin                   
  FDebugger := ADebugger;
  inherited Create(AWatchClass);
end;

procedure TDBGWatches.DoStateChange;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
    GetItem(n).DoStateChange;
end;

function TDBGWatches.GetItem(const AnIndex: Integer): TDBGWatch;
begin
  Result := TDBGWatch(inherited GetItem(AnIndex));
end;

procedure TDBGWatches.SetItem(const AnIndex: Integer; const AValue: TDBGWatch);
begin
  inherited SetItem(AnIndex, AValue);
end;

{ =========================================================================== }
{ TDBGLocals }
{ =========================================================================== }

function TDBGLocals.Count: Integer;
begin
  Result := 0;
end;

constructor TDBGLocals.Create(const ADebugger: TDebugger);
begin
  inherited Create;
  FDebugger := ADebugger;
end;

procedure TDBGLocals.DoChange;  
begin                  
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TDBGLocals.DoStateChange;  
begin
end;

function TDBGLocals.GetName(const AnIndex: Integer): String;
begin
  Result := '';
end;

function TDBGLocals.GetValue(const AnIndex: Integer): String;
begin
  Result := '';
end;

end.
{ =============================================================================
  $Log$
  Revision 1.11  2002/03/23 15:54:30  lazarus
  MWE:
    + Added locals dialog
    * Modified breakpoints dialog (load as resource)
    + Added generic debuggerdlg class
    = Reorganized main.pp, all debbugger relater routines are moved
      to include/ide_debugger.inc

  Revision 1.10  2002/03/12 23:55:36  lazarus
  MWE:
    * More delphi compatibility added/updated to TListView
    * Introduced TDebugger.locals
    * Moved breakpoints dialog to debugger dir
    * Changed breakpoints dialog to read from resource

  Revision 1.9  2002/03/09 02:03:59  lazarus
  MWE:
    * Upgraded gdb debugger to gdb/mi debugger
    * Set default value for autpopoup
    * Added Clear popup to debugger output window

  Revision 1.8  2002/02/20 23:33:24  lazarus
  MWE:
    + Published OnClick for TMenuItem
    + Published PopupMenu property for TEdit and TMemo (Doesn't work yet)
    * Fixed debugger running twice
    + Added Debugger output form
    * Enabled breakpoints

  Revision 1.7  2002/02/06 08:58:29  lazarus
  MG: fixed compiler warnings and asking to create non existing files

  Revision 1.6  2002/02/05 23:16:48  lazarus
  MWE: * Updated tebugger
       + Added debugger to IDE

  Revision 1.5  2001/11/12 19:28:23  lazarus
  MG: fixed create, virtual constructors makes no sense

  Revision 1.4  2001/11/06 23:59:13  lazarus
  MWE: + Initial breakpoint support
       + Added exeption handling on process.free

  Revision 1.3  2001/11/05 00:12:51  lazarus
  MWE: First steps of a debugger.

  Revision 1.2  2001/10/18 13:01:31  lazarus
  MG: fixed speedbuttons numglyphs>1 and started IDE debugging

  Revision 1.1  2001/02/28 22:09:15  lazarus
  MWE:
    * Renamed DBGDebugger to Debugger

  Revision 1.2  2001/02/25 16:44:57  lazarus
  MWE:
    + Added header and footer

}
