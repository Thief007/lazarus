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
unit Debugger;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Laz_XMLCfg, IDEProcs, DBGUtils;

type
  TDBGLocationRec = record
    Address: Pointer;
    FuncName: String;
    SrcFile: String;
    SrcLine: Integer;
  end;

  TDBGCommand = (
    dcRun,
    dcPause,
    dcStop,
    dcStepOver,
    dcStepInto,
    dcRunTo,
    dcJumpto,
    dcBreak,
    dcWatch,
    dcLocal,
    dcEvaluate,
    dcModify,
    dcEnvironment
    );
  TDBGCommands = set of TDBGCommand;
  
  TDBGState = (
    dsNone,
    dsIdle,
    dsStop,
    dsPause,
    dsRun,
    dsError
    );
    
{
  Debugger states
  --------------------------------------------------------------------------
  dsNone:
    The debug object is created, but no instance of an external debugger
    exists.
    Initial state, leave with Init, enter with Done

  dsIdle:
    The external debugger is started, but no filename (or no other params
    required to start) were given.

  dsStop:
    (Optional) The execution of the target is stopped
    The external debugger is loaded and ready to (re)start the execution
    of the target.
    Breakpoints, watches etc can be defined

  dsPause:
    The debugger has paused the target. Target variables can be examined

  dsRun:
    The target is running.

  dsError:
    Something unforseen has happened. A shutdown of the debugger is in
    most cases needed.
  --------------------------------------------------------------------------

}

  TValidState = (vsUnknown, vsValid, vsInvalid);


const
  dcRunCommands = [dcRun,dcStepInto,dcStepOver,dcRunTo];
  dsRunStates = [dsRun];

  XMLBreakPointsNode = 'BreakPoints';
  XMLBreakPointGroupsNode = 'BreakPointGroups';
  XMLWatchesNode = 'Watches';

type
  EDebuggerException = class(Exception);
  EDBGExceptions = class(EDebuggerException);

type
{ ---------------------------------------------------------<br>
  TDebuggerNotification is a reference counted baseclass
  for handling notifications for locals, watches, breakpoints etc.<br>
  ---------------------------------------------------------}
  TDebuggerNotification = class(TObject)
  private
    FRefCount: Integer;
  public
    procedure AddReference;
    constructor Create;
    destructor Destroy; override;
    procedure ReleaseReference;
  end;
  

  TIDEBreakPoints = class;
  TIDEBreakPointGroup = class;
  TIDEBreakPointGroups = class;
  TDBGWatches = class;
  TDebugger = class;

  TOnSaveFilenameToConfig = procedure(var Filename: string) of object;
  TOnLoadFilenameFromConfig = procedure(var Filename: string) of object;
  TOnGetGroupByName = function(const GroupName: string): TIDEBreakPointGroup of object;

(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   B R E A K P O I N T S                                                  **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  { TIDEBreakPoint }

  // The TBaseBreakpoint family is the common ancestor for the "public" available
  // TIDEBreakPoint through the DebugBoss as well as the "private" TDBGBreakPoint
  // used by the debugboss itself.
  // The BreakPointGroups are no longer part of the debugger, but they are now
  // managed by the debugboss.

  TIDEBreakPointAction = (
    bpaStop,
    bpaEnableGroup,
    bpaDisableGroup
    );
  TIDEBreakPointActions = set of TIDEBreakPointAction;
  
  TBaseBreakPoint = class(TDelayedUdateItem)
  private
    FEnabled: Boolean;
    FExpression: String;
    FHitCount: Integer;
    FLine: Integer;
    FSource: String;
    FValid: TValidState;
    FInitialEnabled: Boolean;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure DoExpressionChange; virtual;
    procedure DoEnableChange; virtual;
    procedure DoHit(const ACount: Integer; var AContinue: Boolean); virtual;
    procedure SetHitCount(const AValue: Integer);
    procedure SetLocation(const ASource: String; const ALine: Integer); virtual;
    procedure SetValid(const AValue: TValidState);

    // virtual properties
    function GetEnabled: Boolean; virtual;
    function GetExpression: String; virtual;
    function GetHitCount: Integer; virtual;
    function GetLine: Integer; virtual;
    function GetSource: String; virtual;
    function GetValid: TValidState; virtual;

    procedure SetEnabled(const AValue: Boolean); virtual;
    procedure SetExpression(const AValue: String); virtual;
    procedure SetInitialEnabled(const AValue: Boolean); virtual;
  public
    constructor Create(ACollection: TCollection); override;
    function GetSourceLine: integer; virtual;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property Expression: String read GetExpression write SetExpression;
    property HitCount: Integer read GetHitCount;
    property InitialEnabled: Boolean read FInitialEnabled write SetInitialEnabled;
    property Line: Integer read GetLine;
    property Source: String read GetSource;
    property Valid: TValidState read GetValid;
  end;
  TBaseBreakPointClass = class of TBaseBreakPoint;

  TIDEBreakPoint = class(TBaseBreakPoint)
  private
    FActions: TIDEBreakPointActions;
    FDisableGroupList: TList;
    FEnableGroupList: TList;
    FGroup: TIDEBreakPointGroup;
    FLoading: Boolean;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure DisableGroups;
    procedure DoActionChange; virtual;
    procedure DoHit(const ACount: Integer; var AContinue: Boolean); override;
    procedure EnableGroups;
    procedure RemoveFromGroupList(const AGroup: TIDEBreakPointGroup;
                                  const AGroupList: TList);
    procedure ClearGroupList(const AGroupList: TList);
    procedure ClearAllGroupLists;
    // virtual properties
    function GetActions: TIDEBreakPointActions; virtual;
    function GetGroup: TIDEBreakPointGroup; virtual;
    procedure SetActions(const AValue: TIDEBreakPointActions); virtual;
    procedure SetGroup(const AValue: TIDEBreakPointGroup); virtual;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure AddDisableGroup(const AGroup: TIDEBreakPointGroup);
    procedure AddEnableGroup(const AGroup: TIDEBreakPointGroup);
    procedure RemoveDisableGroup(const AGroup: TIDEBreakPointGroup);
    procedure RemoveEnableGroup(const AGroup: TIDEBreakPointGroup);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                      const OnLoadFilename: TOnLoadFilenameFromConfig;
                      const OnGetGroup: TOnGetGroupByName); virtual;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                      const OnSaveFilename: TOnSaveFilenameToConfig); virtual;
  public
    property Actions: TIDEBreakPointActions read GetActions write SetActions;
    property Group: TIDEBreakPointGroup read GetGroup write SetGroup;
    property Loading: Boolean read FLoading;
  end;
  TIDEBreakPointClass = class of TIDEBreakPoint;

  TDBGBreakPoint = class(TBaseBreakPoint)
  private
    FSlave: TBaseBreakPoint;
    function GetDebugger: TDebugger;
  protected
    procedure DoChanged; override;
    procedure DoDebuggerStateChange; virtual;
    procedure InitTargetStart; virtual;
    property  Debugger: TDebugger read GetDebugger;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    function GetSourceLine: integer; override;
    property Slave: TBaseBreakPoint read FSlave write FSlave;
  end;
  TDBGBreakPointClass = class of TDBGBreakPoint;

  { TIDEBreakPoints }

  TIDEBreakPointsEvent = procedure(const ASender: TIDEBreakPoints;
                                   const ABreakpoint: TIDEBreakPoint) of object;

  TIDEBreakPointsNotification = class(TDebuggerNotification)
  private
    FOnAdd:    TIDEBreakPointsEvent;
    FOnUpdate: TIDEBreakPointsEvent;//Item will be nil in case all items need to be updated
    FOnRemove: TIDEBreakPointsEvent;
  public
    property OnAdd:    TIDEBreakPointsEvent read FOnAdd    write FOnAdd;
    property OnUpdate: TIDEBreakPointsEvent read FOnUpdate write FOnUpdate;
    property OnRemove: TIDEBreakPointsEvent read FOnRemove write FonRemove;
  end;

  TBaseBreakPoints = class(TCollection)
  private
  protected
  public
    constructor Create(const ABreakPointClass: TBaseBreakPointClass);
    function Add(const ASource: String; const ALine: Integer): TBaseBreakPoint;
    function Find(const ASource: String; const ALine: Integer): TBaseBreakPoint; overload;
    function Find(const ASource: String; const ALine: Integer; const AIgnore: TBaseBreakPoint): TBaseBreakPoint; overload;
    // no items property needed, it is "overridden" anyhow
  end;

  TIDEBreakPoints = class(TBaseBreakPoints)
  private
    FNotificationList: TList;
    procedure NotifyRemove(const ABreakpoint: TIDEBreakPoint); // called by breakpoint when destructed
    procedure NotifyAdd(const ABreakPoint: TIDEBreakPoint);    // called when a breakpoint is added
    function GetItem(const AnIndex: Integer): TIDEBreakPoint;
    procedure SetItem(const AnIndex: Integer; const AValue: TIDEBreakPoint);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(const ABreakPointClass: TIDEBreakPointClass);
    destructor Destroy; override;
    function Add(const ASource: String; const ALine: Integer): TIDEBreakPoint;
    function Find(const ASource: String; const ALine: Integer): TIDEBreakPoint; overload;
    function Find(const ASource: String; const ALine: Integer; const AIgnore: TIDEBreakPoint): TIDEBreakPoint; overload;
    procedure AddNotification(const ANotification: TIDEBreakPointsNotification);
    procedure RemoveNotification(const ANotification: TIDEBreakPointsNotification);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                      const OnLoadFilename: TOnLoadFilenameFromConfig;
                      const OnGetGroup: TOnGetGroupByName); virtual;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string;
                      const OnSaveFilename: TOnSaveFilenameToConfig); virtual;
  public
    property Items[const AnIndex: Integer]: TIDEBreakPoint read GetItem
                                                         write SetItem; default;
  end;
  
  TDBGBreakPoints = class(TBaseBreakPoints)
  private
    FDebugger: TDebugger;  // reference to our debugger
    function GetItem(const AnIndex: Integer): TDBGBreakPoint;
    procedure SetItem(const AnIndex: Integer; const AValue: TDBGBreakPoint);
  protected
    procedure DoDebuggerStateChange; virtual;
    procedure InitTargetStart; virtual;
    property  Debugger: TDebugger read FDebugger;
  public
    function Add(const ASource: String; const ALine: Integer): TDBGBreakPoint;
    constructor Create(const ADebugger: TDebugger;
                       const ABreakPointClass: TDBGBreakPointClass);
    function Find(const ASource: String; const ALine: Integer): TDBGBreakPoint; overload;
    function Find(const ASource: String; const ALine: Integer; const AIgnore: TDBGBreakPoint): TDBGBreakPoint; overload;

    property Items[const AnIndex: Integer]: TDBGBreakPoint read GetItem
                                                              write SetItem; default;
  end;


  { TIDEBreakPointGroup }

  TIDEBreakPointGroup = class(TCollectionItem)
  private
    FEnabled: Boolean;
    FInitialEnabled: Boolean;
    FName: String;
    FBreakpoints: TList;// A list of breakpoints that member
    FReferences: TList; // A list of breakpoints that refer to us through En/disable group
    function GetBreakpoint(const AIndex: Integer): TIDEBreakPoint;
    procedure SetEnabled(const AValue: Boolean);
    procedure SetInitialEnabled(const AValue: Boolean);
    procedure SetName(const AValue: String);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure AddReference(const ABreakPoint: TIDEBreakPoint);
    procedure RemoveReference(const ABreakPoint: TIDEBreakPoint);
  public
    function Add(const ABreakPoint: TIDEBreakPoint): Integer;
    function Count: Integer;
    constructor Create(ACollection: TCollection); override;
    procedure Delete(const AIndex: Integer);
    destructor Destroy; override;
    function Remove(const ABreakPoint: TIDEBreakPoint): Integer;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig;
                                const Path: string); virtual;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig;
                              const Path: string); virtual;
  public
    property Breakpoints[const AIndex: Integer]: TIDEBreakPoint read GetBreakpoint;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property InitialEnabled: Boolean read FInitialEnabled write SetInitialEnabled;
    property Name: String read FName write SetName;
  end;


  { TIDEBreakPointGroups }

  TIDEBreakPointGroups = class(TCollection)
  private
    function GetItem(const AnIndex: Integer): TIDEBreakPointGroup;
    procedure SetItem(const AnIndex: Integer; const AValue: TIDEBreakPointGroup);
  protected
  public
    constructor Create;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig;
                                const Path: string); virtual;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig;
                              const Path: string); virtual;
    function GetGroupByName(const GroupName: string): TIDEBreakPointGroup;
    function FindGroupByName(const GroupName: string;
                             Ignore: TIDEBreakPointGroup): TIDEBreakPointGroup;
    function IndexOfGroupWithName(const GroupName: string;
                                  Ignore : TIDEBreakPointGroup): integer;
    procedure InitTargetStart; virtual;
//    procedure Regroup(SrcGroups: TIDEBreakPointGroups;
//                      SrcBreakPoints, DestBreakPoints: TIDEBreakPoints);
  public
    property Items[const AnIndex: Integer]: TIDEBreakPointGroup
                                            read GetItem write SetItem; default;
  end;
  
  
(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   W A T C H E S                                                          **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  { TDBGWatch }

  TDBGWatch = class(TCollectionItem)
  private
    FEnabled: Boolean;
    FExpression: String;
    FInitialEnabled: Boolean;
    FValid: TValidState;
    function  GetDebugger: TDebugger;
    procedure SetEnabled(const AValue: Boolean);
    procedure SetExpression(const AValue: String);
    procedure SetInitialEnabled(const AValue: Boolean);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure DoEnableChange; virtual;
    procedure DoExpressionChange; virtual;
    procedure DoStateChange; virtual;
    function  GetValue: String; virtual;
    function  GetValid: TValidState; virtual;
    procedure SetValid(const AValue: TValidState);
    property  Debugger: TDebugger read GetDebugger;
  public
    constructor Create(ACollection: TCollection); override;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig;
                                const Path: string); virtual;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig;
                              const Path: string); virtual;
  public
    property Enabled: Boolean read FEnabled write SetEnabled;
    property InitialEnabled: Boolean read FInitialEnabled write SetInitialEnabled;
    property Expression: String read FExpression write SetExpression;
    property Valid: TValidState read GetValid;
    property Value: String read GetValue;
  end;

  TDBGWatchClass = class of TDBGWatch;


  { TDBGWatches }

  TDBGWatchesEvent =
       procedure(const ASender: TDBGWatches; const AWatch: TDBGWatch) of object;
       
  TDBGWatchesNotification = class(TDebuggerNotification)
  private
    FOnAdd:    TDBGWatchesEvent;
    FOnUpdate: TDBGWatchesEvent;//Item will be nil in case all items need to be updated
    FOnRemove: TDBGWatchesEvent;
  public
    property OnAdd:    TDBGWatchesEvent read FOnAdd    write FOnAdd;
    property OnUpdate: TDBGWatchesEvent read FOnUpdate write FOnUpdate;
    property OnRemove: TDBGWatchesEvent read FOnRemove write FonRemove;
  end;

  TDBGWatches = class(TCollection)
  private
    FDebugger: TDebugger;  // reference to our debugger
    FNotificationList: TList;
    function GetItem(const AnIndex: Integer): TDBGWatch;
    procedure SetItem(const AnIndex: Integer; const AValue: TDBGWatch);
    procedure Removed(const AWatch: TDBGWatch); // called by watch when destructed
  protected
    procedure DoStateChange; virtual;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(const ADebugger: TDebugger;
                       const AWatchClass: TDBGWatchClass);
    destructor Destroy; override;
    function Add(const AExpression: String): TDBGWatch;
    function Find(const AExpression: String): TDBGWatch;
    procedure AddNotification(const ANotification: TDBGWatchesNotification);
    procedure RemoveNotification(const ANotification: TDBGWatchesNotification);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig;
                                const Path: string); virtual;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig;
                              const Path: string); virtual;
    procedure InitTargetStart; virtual;
  public
    property Items[const AnIndex: Integer]: TDBGWatch read GetItem
                                                      write SetItem; default;
  end;
  
  
(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   L O C A L S                                                            **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  { TDBGLocals }

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
    constructor Create(const ADebugger: TDebugger);
    function Count: Integer; virtual;
  public
    property Names[const AnIndex: Integer]: String read GetName;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Values[const AnIndex: Integer]: String read GetValue;
  end;
  
  
(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   C A L L S T A C K                                                      **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  { TDBGCallStackEntry }

  TDBGCallStackEntry = class(TObject)
  private
    FIndex: Integer;
    FAdress: Pointer;
    FFunctionName: String;
    FLine: Integer;
    FArguments: TStrings;
    FSource: String;
    function GetArgumentCount: Integer; 
    function GetArgumentName(const AnIndex: Integer): String;
    function GetArgumentValue(const AnIndex: Integer): String;
  protected
  public
    constructor Create(const AIndex:Integer; const AnAdress: Pointer;
                       const AnArguments: TStrings; const AFunctionName: String;
                       const ASource: String; const ALine: Integer);
    destructor Destroy; override;
    property Adress: Pointer read FAdress;
    property ArgumentCount: Integer read GetArgumentCount;
    property ArgumentNames[const AnIndex: Integer]: String read GetArgumentName;
    property ArgumentValues[const AnIndex: Integer]: String read GetArgumentValue;
    property FunctionName: String read FFunctionName;
    property Line: Integer read FLine;
    property Source: String read FSource;
  end;
  
  
  { TDBGCallStack }

  TDBGCallStack = class(TObject)
  private
    FDebugger: TDebugger;  // reference to our debugger
    FEntries: TList;       // list of created entries
    FOldState: TDBGState;  // records the previous debugger state 
    FOnChange: TNotifyEvent;
    procedure Clear;
    function GetStackEntry(const AIndex: Integer): TDBGCallStackEntry;
  protected
    procedure DoChange;
    function CreateStackEntry(const AIndex: Integer): TDBGCallStackEntry; virtual; 
    procedure DoStateChange; virtual;
    function GetCount: Integer; virtual;
    property Debugger: TDebugger read FDebugger;
  public   
    function Count: Integer;
    constructor Create(const ADebugger: TDebugger); 
    destructor Destroy; override;
    property Entries[const AIndex: Integer]: TDBGCallStackEntry read GetStackEntry;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;
  
(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   S I G N A L S  and  E X C E P T I O N S                                **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  { TBaseSignal }

  TBaseSignal = class(TDelayedUdateItem)
  private
    FHandledByDebugger: Boolean;
    FID: Integer;
    FName: String;
    FResumeHandled: Boolean;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure SetHandledByDebugger(const AValue: Boolean); virtual;
    procedure SetID(const AValue: Integer); virtual;
    procedure SetName(const AValue: String); virtual;
    procedure SetResumeHandled(const AValue: Boolean); virtual;
  public
    constructor Create(ACollection: TCollection); override;
    property ID: Integer read FID write SetID;
    property Name: String read FName write SetName;
    property HandledByDebugger: Boolean read FHandledByDebugger write SetHandledByDebugger;
    property ResumeHandled: Boolean read FResumeHandled write SetResumeHandled;
  end;
  TBaseSignalClass = class of TBaseSignal;
    
  { TDBGSignal }
  
  TDBGSignal = class(TBaseSignal)
  private
    function GetDebugger: TDebugger;
  protected
    property Debugger: TDebugger read GetDebugger;
  public
  end;
  TDBGSignalClass = class of TDBGSignal;
  
  TIDESignal = class(TBaseSignal)
  private
  protected
  public
    procedure LoadFromXMLConfig(const AXMLConfig: TXMLConfig;
                                const APath: string);
    procedure SaveToXMLConfig(const AXMLConfig: TXMLConfig;
                              const APath: string);
  end;

  { TBaseSignals }
  TBaseSignals = class(TCollection)
  private
    function Add(const AName: String; AID: Integer): TBaseSignal;
    function Find(const AName: String): TBaseSignal;
  protected
  public
    constructor Create(const AItemClass: TBaseSignalClass);
  end;

  { TDBGSignals }

  TDBGSignals = class(TBaseSignals)
  private
    FDebugger: TDebugger;  // reference to our debugger
    function GetItem(const AIndex: Integer): TDBGSignal;
    procedure SetItem(const AIndex: Integer; const AValue: TDBGSignal);
  protected
  public
    constructor Create(const ADebugger: TDebugger;
                       const ASignalClass: TDBGSignalClass);
    function Add(const AName: String; AID: Integer): TDBGSignal;
    function Find(const AName: String): TDBGSignal;
  public
    property Items[const AIndex: Integer]: TDBGSignal read GetItem
                                                      write SetItem; default;
  end;

  { TIDESignals }
  
  TIDESignals = class(TBaseSignals)
  private
    function GetItem(const AIndex: Integer): TIDESignal;
    procedure SetItem(const AIndex: Integer; const AValue: TIDESignal);
  protected
  public
    function Add(const AName: String; AID: Integer): TIDESignal;
    function Find(const AName: String): TIDESignal;
  public
    procedure LoadFromXMLConfig(const AXMLConfig: TXMLConfig;
                                const APath: string);
    procedure SaveToXMLConfig(const AXMLConfig: TXMLConfig;
                              const APath: string);
    property Items[const AIndex: Integer]: TIDESignal read GetItem
                                                      write SetItem; default;
  end;

  { TBaseException }
  TBaseException = class(TDelayedUdateItem)
  private
    FName: String;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure SetName(const AValue: String); virtual;
  public
    constructor Create(ACollection: TCollection); override;
    procedure LoadFromXMLConfig(const AXMLConfig: TXMLConfig;
                                const APath: string); virtual;
    procedure SaveToXMLConfig(const AXMLConfig: TXMLConfig;
                              const APath: string); virtual;
  public
    property Name: String read FName write SetName;
  end;
  TBaseExceptionClass = class of TBaseException;

  { TDBGException }
  TDBGException = class(TBaseException)
  private
  protected
  public
  end;
  TDBGExceptionClass = class of TDBGException;

  { TIDEException }
  TIDEException = class(TBaseException)
  private
    FEnabled: Boolean;
    procedure SetEnabled(const AValue: Boolean);
  protected
  public
    constructor Create(ACollection: TCollection); override;
    procedure LoadFromXMLConfig(const AXMLConfig: TXMLConfig;
                                const APath: string); override;
    procedure SaveToXMLConfig(const AXMLConfig: TXMLConfig;
                              const APath: string); override;
    property Enabled: Boolean read FEnabled write SetEnabled;
  end;

  { TBaseExceptions }
  TBaseExceptions = class(TCollection)
  private
    function Add(const AName: String): TBaseException;
    function Find(const AName: String): TBaseException;
  protected
    procedure ClearExceptions; virtual;
  public
    constructor Create(const AItemClass: TBaseExceptionClass);
    destructor Destroy; override;
  end;

  { TDBGExceptions }

  TDBGExceptions = class(TBaseExceptions)
  private
    FDebugger: TDebugger;  // reference to our debugger
    function GetItem(const AIndex: Integer): TDBGException;
    procedure SetItem(const AIndex: Integer; const AValue: TDBGException);
  protected
  public
    constructor Create(const ADebugger: TDebugger;
                       const AExceptionClass: TDBGExceptionClass);
    function Add(const AName: String): TDBGException;
    function Find(const AName: String): TDBGException;
  public
    property Items[const AIndex: Integer]: TDBGException read GetItem
                                                        write SetItem; default;
  end;

  { TIDEExceptions }

  TIDEExceptions = class(TBaseExceptions)
  private
    function GetItem(const AIndex: Integer): TIDEException;
    procedure SetItem(const AIndex: Integer; const AValue: TIDEException);
  protected
  public
    function Add(const AName: String): TIDEException;
    function Find(const AName: String): TIDEException;
  public
    procedure LoadFromXMLConfig(const AXMLConfig: TXMLConfig;
                                const APath: string);
    procedure SaveToXMLConfig(const AXMLConfig: TXMLConfig;
                              const APath: string);
    property Items[const AIndex: Integer]: TIDEException read GetItem
                                                        write SetItem; default;
  end;


(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   D E B U G G E R                                                        **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  { TDebugger }

  TDebuggerStateChangedEvent = procedure(ADebugger: TDebugger;
                                         OldState: TDBGState) of object;
  TDBGOutputEvent = procedure(Sender: TObject; const AText: String) of object;
  TDBGCurrentLineEvent = procedure(Sender: TObject;
                                   const ALocation: TDBGLocationRec) of object;
  TDBGExceptionEvent = procedure(Sender: TObject; const AExceptionClass: String;
                                 const AExceptionText: String) of object;

  TDebugger = class(TObject)
  private
    FArguments: String;
    FBreakPoints: TDBGBreakPoints;
    FDebuggerEnvironment: TStrings;
    FCurEnvironment: TStrings;
    FEnvironment: TStrings;
    FExceptions: TDBGExceptions;
    FExitCode: Integer;
    FExternalDebugger: String;
    //FExceptionss: TDBGExceptions;
    FFileName: String;
    FLocals: TDBGLocals;
    FSignals: TDBGSignals;
    FState: TDBGState;
    FCallStack: TDBGCallStack;
    FWatches: TDBGWatches;
    FOnCurrent: TDBGCurrentLineEvent;
    FOnException: TDBGExceptionEvent;
    FOnOutput: TDBGOutputEvent;
    FOnDbgOutput: TDBGOutputEvent;
    FOnState: TDebuggerStateChangedEvent;
    FWorkingDir: String;
    procedure DebuggerEnvironmentChanged(Sender: TObject);
    procedure EnvironmentChanged(Sender: TObject);
    function  GetState: TDBGState;
    function  ReqCmd(const ACommand: TDBGCommand;
                     const AParams: array of const): Boolean;
    procedure SetDebuggerEnvironment (const AValue: TStrings );
    procedure SetEnvironment(const AValue: TStrings);
    procedure SetFileName(const AValue: String);
  protected
    function  CreateBreakPoints: TDBGBreakPoints; virtual;
    function  CreateLocals: TDBGLocals; virtual;
    function  CreateCallStack: TDBGCallStack; virtual;
    function  CreateWatches: TDBGWatches; virtual;
    function  CreateSignals: TDBGSignals; virtual;
    function  CreateExceptions: TDBGExceptions; virtual;
    procedure DoCurrent(const ALocation: TDBGLocationRec);
    procedure DoDbgOutput(const AText: String);
    procedure DoException(const AExceptionClass: String; const AExceptionText: String);
    procedure DoOutput(const AText: String);
    procedure DoState(const OldState: TDBGState); virtual;
    function  ChangeFileName: Boolean; virtual;
    function  GetCommands: TDBGCommands;
    function  GetSupportedCommands: TDBGCommands; virtual;
    function  RequestCommand(const ACommand: TDBGCommand;
                             const AParams: array of const): Boolean;
                             virtual; abstract; // True if succesful
    procedure SetExitCode(const AValue: Integer);
    procedure SetState(const AValue: TDBGState);
    procedure InitTargetStart; virtual;
  public
    constructor Create(const AExternalDebugger: String); virtual; {Virtual constructor makes no sense}
                        //MWE: there will be a day that they do make sense :-)
                        // MG: there will be a day that they do make troubles :)
                        //MWE: do they ?
                        //MWE: Now they do make sense !
    destructor Destroy; override;

    class function Caption: String; virtual;         // The name of the debugger as shown in the debuggeroptions
    class function ExePaths: String; virtual;        // The default locations of the exe
    
    procedure Init; virtual;                         // Initializes the debugger
    procedure Done; virtual;                         // Kills the debugger
    procedure Run;                                   // Starts / continues debugging
    procedure Pause;                                 // Stops running
    procedure Stop;                                  // quit debugging
    procedure StepOver;
    procedure StepInto;
    procedure RunTo(const ASource: String; const ALine: Integer);                // Executes til a certain point
    procedure JumpTo(const ASource: String; const ALine: Integer);               // No execute, only set exec point

    function  Evaluate(const AExpression: String; var AResult: String): Boolean; // Evaluates the given expression, returns true if valid
    function  Modify(const AExpression, AValue: String): Boolean;                // Modifies the given expression, returns true if valid
    function  TargetIsStarted: boolean; virtual;

  public
    property Arguments: String read FArguments write FArguments;                 // Arguments feed to the program
    property BreakPoints: TDBGBreakPoints read FBreakPoints;                     // list of all breakpoints
    property CallStack: TDBGCallStack read FCallStack;
    property Commands: TDBGCommands read GetCommands;                            // All current available commands of the debugger
    property DebuggerEnvironment: TStrings read FDebuggerEnvironment
                                           write SetDebuggerEnvironment;         // The environment passed to the debugger process
    property Environment: TStrings read FEnvironment write SetEnvironment;       // The environment passed to the debuggee
    property Exceptions: TDBGExceptions read FExceptions;                        // A list of exceptions we should ignore
    property ExitCode: Integer read FExitCode;
    property ExternalDebugger: String read FExternalDebugger;                    // The name of the debugger executable
    property FileName: String read FFileName write SetFileName;                  // The name of the exe to be debugged
    property Locals: TDBGLocals read FLocals;
    property Signals: TDBGSignals read FSignals;                                 // A list of actions for signals we know
    property State: TDBGState read FState;                                       // The current state of the debugger
    property SupportedCommands: TDBGCommands read GetSupportedCommands;          // All available commands of the debugger
    property Watches: TDBGWatches read FWatches;                                 // list of all watches localvars etc
    property WorkingDir: String read FWorkingDir write FWorkingDir;              // The working dir of the exe being debugged
    // Events
    property OnCurrent: TDBGCurrentLineEvent read FOnCurrent write FOnCurrent;   // Passes info about the current line being debugged
    property OnDbgOutput: TDBGOutputEvent read FOnDbgOutput write FOnDbgOutput;  // Passes all debuggeroutput
    property OnException: TDBGExceptionEvent read FOnException write FOnException;  // Fires when the debugger received an exeption
    property OnOutput: TDBGOutputEvent read FOnOutput write FOnOutput;           // Passes all output of the debugged target
    property OnState: TDebuggerStateChangedEvent read FOnState write FOnState;   // Fires when the current state of the debugger changes
  end;
  TDebuggerClass = class of TDebugger;
  
const
  DBGCommandNames: array[TDBGCommand] of string = (
    'Run',
    'Pause',
    'Stop',
    'StepOver',
    'StepInto',
    'RunTo',
    'Jumpto',
    'Break',
    'Watch',
    'Local',
    'Evaluate',
    'Modify',
    'Environment'
    );
    
  DBGStateNames: array[TDBGState] of string = (
    'None',
    'Idle',
    'Stop',
    'Pause',
    'Run',
    'Error'
    );
    
  DBGBreakPointActionNames: array[TIDEBreakPointAction] of string = (
    'Stop',
    'EnableGroup',
    'DisableGroup'
    );
    
function DBGCommandNameToCommand(const s: string): TDBGCommand;
function DBGStateNameToState(const s: string): TDBGState;
function DBGBreakPointActionNameToAction(const s: string): TIDEBreakPointAction;

(******************************************************************************)
(******************************************************************************)
(******************************************************************************)
(******************************************************************************)

implementation

const
  COMMANDMAP: array[TDBGState] of TDBGCommands = (
  {dsNone } [],
  {dsIdle } [dcEnvironment],
  {dsStop } [dcRun, dcStepOver, dcStepInto, dcRunTo, dcJumpto, dcBreak, dcWatch,
             dcEvaluate, dcEnvironment],
  {dsPause} [dcRun, dcStop, dcStepOver, dcStepInto, dcRunTo, dcJumpto, dcBreak,
             dcWatch, dcLocal, dcEvaluate, dcModify, dcEnvironment],
  {dsRun  } [dcPause, dcStop, dcBreak, dcWatch, dcEnvironment],
  {dsError} [dcStop]
  );

function DBGCommandNameToCommand(const s: string): TDBGCommand;
begin
  for Result:=Low(TDBGCommand) to High(TDBGCommand) do
    if AnsiCompareText(s,DBGCommandNames[Result])=0 then exit;
  Result:=dcStop;
end;

function DBGStateNameToState(const s: string): TDBGState;
begin
  for Result:=Low(TDBGState) to High(TDBGState) do
    if AnsiCompareText(s,DBGStateNames[Result])=0 then exit;
  Result:=dsNone;
end;

function DBGBreakPointActionNameToAction(const s: string): TIDEBreakPointAction;
begin
  for Result:=Low(TIDEBreakPointAction) to High(TIDEBreakPointAction) do
    if AnsiCompareText(s,DBGBreakPointActionNames[Result])=0 then exit;
  Result:=bpaStop;
end;

{ =========================================================================== }
{ TDebuggerNotification }
{ =========================================================================== }

procedure TDebuggerNotification.AddReference;
begin
  Inc(FRefcount);
end;

constructor TDebuggerNotification.Create;
begin
  FRefCount := 0;
  inherited;
end;

destructor TDebuggerNotification.Destroy;
begin
  Assert(FRefcount = 0, 'Destroying referenced object');
  inherited;
end;

procedure TDebuggerNotification.ReleaseReference;
begin
  Dec(FRefCount);
  if FRefCount = 0 then Free;
end;


(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   D E B U G G E R                                                        **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)


{ =========================================================================== }
{ TDebugger }
{ =========================================================================== }

function TDebugger.Caption: String;
begin
  Result := 'No caption set';
end;

function TDebugger.ChangeFileName: Boolean;
begin
  Result := True;
end;

constructor TDebugger.Create(const AExternalDebugger: String);
var
  list: TStringList;
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

  list := TStringList.Create;
  list.Sorted := True;
  list.Duplicates := dupIgnore;
  list.OnChange := @DebuggerEnvironmentChanged;
  FDebuggerEnvironment := list;

  list := TStringList.Create;
  list.Sorted := True;
  list.Duplicates := dupIgnore;
  list.OnChange := @EnvironmentChanged;
  FEnvironment := list;
  FCurEnvironment := TStringList.Create;

  FBreakPoints := CreateBreakPoints;
  FLocals := CreateLocals;
  FCallStack := CreateCallStack;
  FWatches := CreateWatches;
  FExceptions := CreateExceptions;
  FSignals := CreateSignals;
  FExitCode := 0;
end;

function TDebugger.CreateBreakPoints: TDBGBreakPoints;
begin
  Result := TDBGBreakPoints.Create(Self, TDBGBreakPoint);
end;

function TDebugger.CreateCallStack: TDBGCallStack; 
begin
  Result := TDBGCallStack.Create(Self);
end;

function TDebugger.CreateExceptions: TDBGExceptions;
begin
  Result := TDBGExceptions.Create(Self, TDBGException);
end;

function TDebugger.CreateLocals: TDBGLocals;
begin
  Result := TDBGLocals.Create(Self);
end;

function TDebugger.CreateSignals: TDBGSignals;
begin
  Result := TDBGSignals.Create(Self, TDBGSignal);
end;

function TDebugger.CreateWatches: TDBGWatches;
begin
  Result := TDBGWatches.Create(Self, TDBGWatch);
end;

procedure TDebugger.DebuggerEnvironmentChanged (Sender: TObject );
begin
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

  FBreakPoints.FDebugger := nil;
  FLocals.FDebugger := nil;
  FCallStack.FDebugger := nil;
  FWatches.FDebugger := nil;

  FreeAndNil(FExceptions);
  FreeAndNil(FBreakPoints);
  FreeAndNil(FLocals);
  FreeAndNil(FCallStack);
  FreeAndNil(FWatches);
  FreeAndNil(FDebuggerEnvironment);
  FreeAndNil(FEnvironment);
  FreeAndNil(FCurEnvironment);
  FreeAndNil(FSignals);
  inherited;
end;

procedure TDebugger.Done;
begin
  FEnvironment.Clear;
  FCurEnvironment.Clear;
  SetState(dsNone);
end;

procedure TDebugger.DoCurrent(const ALocation: TDBGLocationRec);
begin
  if Assigned(FOnCurrent) then FOnCurrent(Self, ALocation);
end;

procedure TDebugger.DoDbgOutput(const AText: String);
begin                          
  // WriteLN(' [TDebugger] ', AText);
  if Assigned(FOnDbgOutput) then FOnDbgOutput(Self, AText);
end;

procedure TDebugger.DoException(const AExceptionClass: String;
  const AExceptionText: String);
begin
  if Assigned(FOnException) then
    FOnException(Self, AExceptionClass, AExceptionText);
end;

procedure TDebugger.DoOutput(const AText: String);
begin
  if Assigned(FOnOutput) then FOnOutput(Self, AText);
end;

procedure TDebugger.DoState(const OldState: TDBGState);
begin
  if Assigned(FOnState) then FOnState(Self,OldState);
end;

procedure TDebugger.EnvironmentChanged(Sender: TObject);
var
  n, idx: integer;
  S: String;
  Env: TStringList;
begin
  // Createe local copy
  Env := TStringList.Create;
  try
    Env.Assign(Environment);

    // Check for nonexisting and unchanged vars
    for n := 0 to FCurEnvironment.Count - 1 do
    begin
      S := FCurEnvironment[n];
      idx := Env.IndexOfName(GetPart([], ['='], S, False, False));
      if idx = -1
      then ReqCmd(dcEnvironment, [S, False])
      else begin
        if Env[idx] = S
        then Env.Delete(idx);
      end;
    end;
    
    // Set the remaining
    for n := 0 to Env.Count - 1 do
    begin
      ReqCmd(dcEnvironment, [Env[n], True]);
    end;
  finally
    Env.Free;
  end;
  FCurEnvironment.Assign(FEnvironment);
end;

function TDebugger.Evaluate(const AExpression: String;
  var AResult: String): Boolean;
begin
  Result := ReqCmd(dcEvaluate, [AExpression, @AResult]);
end;

function TDebugger.ExePaths: String;
begin
  Result := '';
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

function TDebugger.Modify(const AExpression, AValue: String): Boolean;
begin
  Result := False;
end;

function TDebugger.TargetIsStarted: boolean;
begin
  Result:=FState in [dsRun,dsPause];
end;

procedure TDebugger.Pause;
begin
  ReqCmd(dcPause, []);
end;

function TDebugger.ReqCmd(const ACommand: TDBGCommand;
  const AParams: array of const): Boolean;
begin
  if FState = dsNone then Init;
  if ACommand in Commands then begin
    if (not TargetIsStarted) and (ACommand in dcRunCommands) then
      InitTargetStart;
    Result := RequestCommand(ACommand, AParams);
  end
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

procedure TDebugger.SetDebuggerEnvironment (const AValue: TStrings );
begin
  FDebuggerEnvironment.Assign(AValue);
end;

procedure TDebugger.SetEnvironment(const AValue: TStrings);
begin
  FEnvironment.Assign(AValue);
end;

procedure TDebugger.SetExitCode(const AValue: Integer);
begin
  FExitCode := AValue;
end;

procedure TDebugger.SetFileName(const AValue: String);
begin
  if FFileName <> AValue
  then begin
    WriteLN('[TDebugger.SetFileName] ', AValue);
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
var
  OldState: TDBGState;
begin
  if AValue <> FState
  then begin
    OldState := FState;
    FState := AValue;
    FBreakpoints.DoDebuggerStateChange;
    FLocals.DoStateChange;
    FCallStack.DoStateChange;
    FWatches.DoStateChange;
    DoState(OldState);
  end;
end;

procedure TDebugger.InitTargetStart;
begin
  FBreakPoints.InitTargetStart;
  FWatches.InitTargetStart;
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

(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   B R E A K P O I N T S                                                  **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

{ ===========================================================================
  TBaseBreakPoint
  =========================================================================== }

procedure TBaseBreakPoint.SetInitialEnabled(const AValue: Boolean);
begin
  if FInitialEnabled=AValue then exit;
  //writeln('TBaseBreakPoint.SetInitialEnabled A Self=',HexStr(Cardinal(Self),8),' ',ClassName,' Line=',Line,' AValue=',AValue);
  FInitialEnabled:=AValue;
end;

procedure TBaseBreakPoint.AssignTo(Dest: TPersistent);
var
  DestBreakPoint: TBaseBreakPoint;
begin
  // updatelock is set in source.assignto
  if Dest is TBaseBreakPoint
  then begin
    DestBreakPoint:=TBaseBreakPoint(Dest);
    DestBreakPoint.SetLocation(FSource, FLine);
    DestBreakPoint.SetExpression(FExpression);
    DestBreakPoint.SetEnabled(FEnabled);
    //writeln('TBaseBreakPoint.AssignTo A ',Line,' Enabled=',Enabled,' InitialEnabled=',InitialEnabled);
    DestBreakPoint.InitialEnabled := FInitialEnabled;
  end
  else inherited;
end;

constructor TBaseBreakPoint.Create(ACollection: TCollection);
begin
  FSource := '';
  FLine := -1;
  FValid := vsUnknown;
  FEnabled := False;
  FHitCount := 0;
  FExpression := '';
  FInitialEnabled := False;
  inherited Create(ACollection);
end;

procedure TBaseBreakPoint.DoEnableChange;
begin
  Changed;
end;

procedure TBaseBreakPoint.DoExpressionChange;
begin
  Changed;
end;

procedure TBaseBreakPoint.DoHit(const ACount: Integer; var AContinue: Boolean );
begin
  SetHitCount(ACount);
end;

function TBaseBreakPoint.GetSourceLine: integer;
begin
  Result:=Line;
end;

function TBaseBreakPoint.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TBaseBreakPoint.GetExpression: String;
begin
  Result := FExpression;
end;

function TBaseBreakPoint.GetHitCount: Integer;
begin
  Result := FHitCount;
end;

function TBaseBreakPoint.GetLine: Integer;
begin
  Result := FLine;
end;

function TBaseBreakPoint.GetSource: String;
begin
  Result := FSource;
end;

function TBaseBreakPoint.GetValid: TValidState;
begin
  Result := FValid;
end;

procedure TBaseBreakPoint.SetEnabled (const AValue: Boolean );
begin
  if FEnabled <> AValue
  then begin
    FEnabled := AValue;
    DoEnableChange;
  end;
end;

procedure TBaseBreakPoint.SetExpression (const AValue: String );
begin
  if FExpression <> AValue
  then begin
    FExpression := AValue;
    DoExpressionChange;
  end;
end;

procedure TBaseBreakPoint.SetHitCount (const AValue: Integer );
begin
  if FHitCount <> AValue
  then begin
    FHitCount := AValue;
    Changed;
  end;
end;

procedure TBaseBreakPoint.SetLocation (const ASource: String; const ALine: Integer );
begin
  if (FSource = ASource) and (FLine = ALine) then exit;
  FSource := ASource;
  FLine := ALine;
  Changed;
end;

procedure TBaseBreakPoint.SetValid(const AValue: TValidState );
begin
  if FValid <> AValue
  then begin
    FValid := AValue;
    Changed;
  end;
end;

{ =========================================================================== }
{ TIDEBreakPoint }
{ =========================================================================== }

procedure TIDEBreakPoint.AddDisableGroup(const AGroup: TIDEBreakPointGroup);
begin
  if AGroup = nil then Exit;
  FDisableGroupList.Add(AGroup);
  AGroup.AddReference(Self);
  Changed;
end;

procedure TIDEBreakPoint.AddEnableGroup(const AGroup: TIDEBreakPointGroup);
begin
  if AGroup = nil then Exit;
  FEnableGroupList.Add(AGroup);
  AGroup.AddReference(Self);
  Changed;
end;

procedure TIDEBreakPoint.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TIDEBreakPoint
  then begin
    TIDEBreakPoint(Dest).Actions := FActions;
  end;
end;

procedure TIDEBreakPoint.ClearAllGroupLists;
begin
  ClearGroupList(FDisableGroupList);
  ClearGroupList(FEnableGroupList);
end;

procedure TIDEBreakPoint.ClearGroupList(const AGroupList: TList);
var
  i: Integer;
  AGroup: TIDEBreakPointGroup;
begin
  for i:=0 to AGroupList.Count-1 do begin
    AGroup:=TIDEBreakPointGroup(AGroupList[i]);
    AGroup.RemoveReference(Self);
  end;
  AGroupList.Clear;
end;

constructor TIDEBreakPoint.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FGroup := nil;
  FActions := [bpaStop];
  FDisableGroupList := TList.Create;
  FEnableGroupList := TList.Create;
end;

destructor TIDEBreakPoint.Destroy;
begin
  if (TIDEBreakPoints(Collection) <> nil)
  then TIDEBreakPoints(Collection).NotifyRemove(Self);

  if FGroup <> nil
  then FGroup.Remove(Self);

  ClearAllGroupLists;

  inherited;
  FreeAndNil(FDisableGroupList);
  FreeAndNil(FEnableGroupList);
end;

procedure TIDEBreakPoint.DisableGroups;
var
  n: Integer;
begin
  for n := 0 to FDisableGroupList.Count - 1 do
    TIDEBreakPointGroup(FDisableGroupList[n]).Enabled := False;
end;

procedure TIDEBreakPoint.DoActionChange;
begin
  Changed;
end;

procedure TIDEBreakPoint.DoHit (const ACount: Integer; var AContinue: Boolean );
begin
  inherited DoHit(ACount, AContinue);
  if bpaEnableGroup in Actions
  then EnableGroups;
  if bpaDisableGroup in Actions
  then DisableGroups;
end;

procedure TIDEBreakPoint.EnableGroups;
var
  n: Integer;
begin
  for n := 0 to FDisableGroupList.Count - 1 do
    TIDEBreakPointGroup(FDisableGroupList[n]).Enabled := True;
end;

function TIDEBreakPoint.GetActions: TIDEBreakPointActions;
begin
  Result := FActions;
end;

function TIDEBreakPoint.GetGroup: TIDEBreakPointGroup;
begin
  Result := FGroup;
end;

procedure TIDEBreakPoint.RemoveDisableGroup(const AGroup: TIDEBreakPointGroup);
begin
  RemoveFromGroupList(AGroup,FDisableGroupList);
end;

procedure TIDEBreakPoint.RemoveEnableGroup(const AGroup: TIDEBreakPointGroup);
begin
  RemoveFromGroupList(AGroup,FEnableGroupList);
end;

procedure TIDEBreakPoint.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; const OnLoadFilename: TOnLoadFilenameFromConfig;
  const OnGetGroup: TOnGetGroupByName);

  procedure LoadGroupList(GroupList: TList; const ListPath: string);
  var
    i: Integer;
    CurGroup: TIDEBreakPointGroup;
    NewCount: Integer;
    GroupName: String;
  begin
    ClearGroupList(GroupList);
    NewCount:=XMLConfig.GetValue(ListPath+'Count',0);
    for i:=0 to NewCount-1 do begin
      GroupName:=XMLConfig.GetValue(ListPath+'Group'+IntToStr(i+1)+'/Name','');
      if GroupName='' then continue;
      CurGroup:=OnGetGroup(GroupName);
      if CurGroup=nil then continue;
      if GroupList=FDisableGroupList then
        AddDisableGroup(CurGroup)
      else if GroupList=FEnableGroupList then
        AddEnableGroup(CurGroup);
    end;
  end;

var
  Filename: String;
  GroupName: String;
  NewActions: TIDEBreakPointActions;
  CurAction: TIDEBreakPointAction;
begin
  FLoading:=true;
  try
    GroupName:=XMLConfig.GetValue(Path+'Group/Name','');
    Group:=OnGetGroup(GroupName);
    Expression:=XMLConfig.GetValue(Path+'Expression/Value','');
    Filename:=XMLConfig.GetValue(Path+'Source/Value','');
    if Assigned(OnLoadFilename) then OnLoadFilename(Filename);
    FSource:=Filename;
    InitialEnabled:=XMLConfig.GetValue(Path+'InitialEnabled/Value',true);
    Enabled:=FInitialEnabled;
    FLine:=XMLConfig.GetValue(Path+'Line/Value',-1);
    NewActions:=[];
    for CurAction:=Low(TIDEBreakPointAction) to High(TIDEBreakPointAction) do
      if XMLConfig.GetValue(
          Path+'Actions/'+DBGBreakPointActionNames[CurAction],
          CurAction in [bpaStop])
      then
        Include(NewActions,CurAction);
    Actions:=NewActions;
    LoadGroupList(FDisableGroupList,Path+'DisableGroups/');
    LoadGroupList(FEnableGroupList,Path+'EnableGroups/');
  finally
    FLoading:=false;
  end;
end;

procedure TIDEBreakPoint.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; const OnSaveFilename: TOnSaveFilenameToConfig);
  
  procedure SaveGroupList(GroupList: TList; const ListPath: string);
  var
    i: Integer;
    CurGroup: TIDEBreakPointGroup;
  begin
    XMLConfig.SetDeleteValue(ListPath+'Count',GroupList.Count,0);
    for i:=0 to GroupList.Count-1 do begin
      CurGroup:=TIDEBreakPointGroup(GroupList[i]);
      XMLConfig.SetDeleteValue(ListPath+'Group'+IntToStr(i+1)+'/Name',
        CurGroup.Name,'');
    end;
  end;
  
var
  Filename: String;
  CurAction: TIDEBreakPointAction;
begin
  if Group<>nil then
    XMLConfig.SetDeleteValue(Path+'Group/Name',Group.Name,'');
  XMLConfig.SetDeleteValue(Path+'Expression/Value',Expression,'');
  Filename:=Source;
  if Assigned(OnSaveFilename) then OnSaveFilename(Filename);
  XMLConfig.SetDeleteValue(Path+'Source/Value',Filename,'');
  XMLConfig.SetDeleteValue(Path+'InitialEnabled/Value',InitialEnabled,true);
  XMLConfig.SetDeleteValue(Path+'Line/Value',Line,-1);
  for CurAction:=Low(TIDEBreakPointAction) to High(TIDEBreakPointAction) do
    XMLConfig.SetDeleteValue(
        Path+'Actions/'+DBGBreakPointActionNames[CurAction],
        CurAction in Actions,CurAction in [bpaStop]);
  SaveGroupList(FDisableGroupList,Path+'DisableGroups/');
  SaveGroupList(FEnableGroupList,Path+'EnableGroups/');
end;

procedure TIDEBreakPoint.SetActions(const AValue: TIDEBreakPointActions);
begin
  if FActions <> AValue
  then begin
    FActions := AValue;
    DoActionChange;
  end;
end;

procedure TIDEBreakPoint.SetGroup(const AValue: TIDEBreakPointGroup);
var
  Grp: TIDEBreakPointGroup;
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
    Changed;
  end;
end;

procedure TIDEBreakPoint.RemoveFromGroupList(const AGroup: TIDEBreakPointGroup;
  const AGroupList: TList);
begin
  if (AGroup = nil) then Exit;
  AGroupList.Remove(AGroup);
  AGroup.RemoveReference(Self);
end;

(*
procedure TIDEBreakPoint.CopyGroupList(SrcGroupList, DestGroupList: TList;
  DestGroups: TIDEBreakPointGroups);
var
  i: Integer;
  CurGroup: TIDEBreakPointGroup;
  NewGroup: TIDEBreakPointGroup;
begin
  ClearGroupList(DestGroupList);
  for i:=0 to SrcGroupList.Count-1 do begin
    CurGroup:=TIDEBreakPointGroup(SrcGroupList[i]);
    NewGroup:=DestGroups.GetGroupByName(CurGroup.Name);
    DestGroupList.Add(NewGroup);
  end;
end;

procedure TIDEBreakPoint.CopyAllGroupLists(SrcBreakPoint: TIDEBreakPoint;
  DestGroups: TIDEBreakPointGroups);
begin
  CopyGroupList(SrcBreakPoint.FEnableGroupList,FEnableGroupList,DestGroups);
  CopyGroupList(SrcBreakPoint.FDisableGroupList,FDisableGroupList,DestGroups);
end;
*)

{ =========================================================================== }
{ TDBGBreakPoint }
{ =========================================================================== }

constructor TDBGBreakPoint.Create (ACollection: TCollection );
begin
  FSlave := nil;
  inherited Create(ACollection);
end;

destructor TDBGBreakPoint.Destroy;
var
  SBP: TBaseBreakPoint;
begin
  SBP := FSlave;
  FSlave := nil;
  if SBP <> nil
  then SBP.Changed;
  inherited Destroy;
end;

function TDBGBreakPoint.GetSourceLine: integer;
begin
  if Slave<>nil then
    Result:=Slave.GetSourceLine
  else
    Result:=inherited GetSourceLine;
end;

procedure TDBGBreakPoint.DoChanged;
begin
  inherited DoChanged;
  if FSlave <> nil
  then FSlave.Changed;
end;

procedure TDBGBreakPoint.DoDebuggerStateChange;
begin
end;

function TDBGBreakPoint.GetDebugger: TDebugger;
begin
  Result := TDBGBreakPoints(Collection).FDebugger;
end;

procedure TDBGBreakPoint.InitTargetStart;
begin
  BeginUpdate;
  try
    SetLocation(FSource,GetSourceLine);
    Enabled := InitialEnabled;
    SetHitCount(0);
  finally
    EndUpdate;
  end;
end;

{ =========================================================================== }
{ TIDEBreakPoints }
{ =========================================================================== }

function TIDEBreakPoints.Add(const ASource: String;
  const ALine: Integer): TIDEBreakPoint;
begin
  Result := TIDEBreakPoint(inherited Add(ASource, ALine));
  NotifyAdd(Result);
end;

procedure TIDEBreakPoints.AddNotification(
  const ANotification: TIDEBreakPointsNotification);
begin
  FNotificationList.Add(ANotification);
  ANotification.AddReference;
end;

constructor TIDEBreakPoints.Create(const ABreakPointClass: TIDEBreakPointClass);
begin
  FNotificationList := TList.Create;
  inherited Create(ABreakPointClass);
end;

destructor TIDEBreakPoints.Destroy;
var
  n: Integer;
begin
  for n := FNotificationList.Count - 1 downto 0 do
    TDebuggerNotification(FNotificationList[n]).ReleaseReference;

  inherited;

  FreeAndNil(FNotificationList);
end;

function TIDEBreakPoints.Find(const ASource: String;
  const ALine: Integer): TIDEBreakPoint;
begin
  Result := TIDEBreakPoint(inherited Find(ASource, ALine, nil));
end;

function TIDEBreakPoints.Find(const ASource: String;
  const ALine: Integer; const AIgnore: TIDEBreakPoint): TIDEBreakPoint;
begin
  Result := TIDEBreakPoint(inherited Find(ASource, ALine, AIgnore));
end;

function TIDEBreakPoints.GetItem(const AnIndex: Integer): TIDEBreakPoint;
begin
  Result := TIDEBreakPoint(inherited GetItem(AnIndex));
end;

procedure TIDEBreakPoints.NotifyAdd(const ABreakPoint: TIDEBreakPoint);
var
  n: Integer;
  Notification: TIDEBreakPointsNotification;
begin
  for n := 0 to FNotificationList.Count - 1 do
  begin
    Notification := TIDEBreakPointsNotification(FNotificationList[n]);
    if Assigned(Notification.FOnAdd)
    then Notification.FOnAdd(Self, ABreakPoint);
  end;
end;

procedure TIDEBreakPoints.NotifyRemove(const ABreakpoint: TIDEBreakPoint);
var
  n: Integer;
  Notification: TIDEBreakPointsNotification;
begin
  for n := 0 to FNotificationList.Count - 1 do
  begin
    Notification := TIDEBreakPointsNotification(FNotificationList[n]);
    if Assigned(Notification.FOnRemove)
    then Notification.FOnRemove(Self, ABreakpoint);
  end;
end;

procedure TIDEBreakPoints.RemoveNotification(
  const ANotification: TIDEBreakPointsNotification);
begin
  FNotificationList.Remove(ANotification);
  ANotification.ReleaseReference;
end;

procedure TIDEBreakPoints.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; const OnLoadFilename: TOnLoadFilenameFromConfig;
  const OnGetGroup: TOnGetGroupByName);
var
  NewCount: Integer;
  i: Integer;
  LoadBreakPoint: TIDEBreakPoint;
  BreakPoint: TIDEBreakPoint;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'Count',0);

  for i:=0 to NewCount-1 do
  begin
    LoadBreakPoint := TIDEBreakPoint.Create(nil);
    LoadBreakPoint.LoadFromXMLConfig(XMLConfig,
      Path+'Item'+IntToStr(i+1)+'/',OnLoadFilename,OnGetGroup);
      
    BreakPoint := Find(LoadBreakPoint.Source, LoadBreakPoint.Line, LoadBreakPoint);

    if BreakPoint = nil
    then BreakPoint := Add(LoadBreakPoint.Source, LoadBreakPoint.Line);
    BreakPoint.Assign(LoadBreakPoint);
    
    FreeAndNil(LoadBreakPoint)
  end;
end;

procedure TIDEBreakPoints.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string; const OnSaveFilename: TOnSaveFilenameToConfig);
var
  Cnt: Integer;
  i: Integer;
  CurBreakPoint: TIDEBreakPoint;
begin
  Cnt:=Count;
  XMLConfig.SetDeleteValue(Path+'Count',Cnt,0);
  for i:=0 to Cnt-1 do begin
    CurBreakPoint:=Items[i];
    CurBreakPoint.SaveToXMLConfig(XMLConfig,
      Path+'Item'+IntToStr(i+1)+'/',OnSaveFilename);
  end;
end;

procedure TIDEBreakPoints.SetItem(const AnIndex: Integer;
  const AValue: TIDEBreakPoint);
begin
  inherited SetItem(AnIndex, AValue);
end;

procedure TIDEBreakPoints.Update(Item: TCollectionItem);
var
  n: Integer;
  Notification: TIDEBreakPointsNotification;
begin
  // Note: Item will be nil in case all items need to be updated
  for n := 0 to FNotificationList.Count - 1 do
  begin
    Notification := TIDEBreakPointsNotification(FNotificationList[n]);
    if Assigned(Notification.FOnUpdate)
    then Notification.FOnUpdate(Self, TIDEBreakPoint(Item));
  end;
end;

{ =========================================================================== }
{ TDBGBreakPoints }
{ =========================================================================== }

function TDBGBreakPoints.Add (const ASource: String; const ALine: Integer ): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Add(ASource, ALine));
end;

constructor TDBGBreakPoints.Create (const ADebugger: TDebugger; const ABreakPointClass: TDBGBreakPointClass );
begin
  FDebugger := ADebugger;
  inherited Create(ABreakPointClass);
end;

procedure TDBGBreakPoints.DoDebuggerStateChange;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
    GetItem(n).DoDebuggerStateChange;
end;

function TDBGBreakPoints.Find(const ASource: String; const ALine: Integer): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Find(Asource, ALine, nil));
end;

function TDBGBreakPoints.Find (const ASource: String; const ALine: Integer; const AIgnore: TDBGBreakPoint ): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Find(ASource, ALine, AIgnore));
end;

function TDBGBreakPoints.GetItem (const AnIndex: Integer ): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited GetItem(AnIndex));
end;

procedure TDBGBreakPoints.InitTargetStart;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].InitTargetStart;
end;

procedure TDBGBreakPoints.SetItem (const AnIndex: Integer; const AValue: TDBGBreakPoint );
begin
  inherited SetItem(AnIndex, AValue);
end;

{ =========================================================================== }
{ TBaseBreakPoints }
{ =========================================================================== }

function TBaseBreakPoints.Add(const ASource: String; const ALine: Integer): TBaseBreakPoint;
begin
  Result := TBaseBreakPoint(inherited Add);
  Result.SetLocation(ASource, ALine);
end;

constructor TBaseBreakPoints.Create(const ABreakPointClass: TBaseBreakPointClass);
begin
  inherited Create(ABreakPointClass);
end;

function TBaseBreakPoints.Find(const ASource: String; const ALine: Integer): TBaseBreakPoint;
begin
  Result := Find(ASource, ALine, nil);
end;

function TBaseBreakPoints.Find(const ASource: String; const ALine: Integer; const AIgnore: TBaseBreakPoint): TBaseBreakPoint;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
  begin
    Result := TBaseBreakPoint(GetItem(n));
    if  (Result.Line = ALine)
    and (AIgnore <> Result)
    and (CompareFilenames(Result.Source, ASource) = 0)
    then Exit;
  end;
  Result := nil;
end;

{ =========================================================================== }
{ TIDEBreakPointGroup }
{ =========================================================================== }

function TIDEBreakPointGroup.Add(const ABreakPoint: TIDEBreakPoint): Integer;
begin
  Result := FBreakpoints.IndexOf(ABreakPoint); //avoid dups
  if Result = -1
  then begin
    Result := FBreakpoints.Add(ABreakPoint);
    ABreakpoint.Group := Self;
  end;
end;

procedure TIDEBreakPointGroup.AddReference(const ABreakPoint: TIDEBreakPoint);
begin
  FReferences.Add(ABreakPoint);
end;

function TIDEBreakPointGroup.Count: Integer;
begin
  Result := FBreakpoints.Count;
end;

constructor TIDEBreakPointGroup.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FBreakpoints := TList.Create;
  FReferences := TList.Create;
  FEnabled := True;
end;

procedure TIDEBreakPointGroup.Delete(const AIndex: Integer);
begin
  Remove(TIDEBreakPoint(FBreakPoints[AIndex]));
end;

destructor TIDEBreakPointGroup.Destroy;
var
  n: Integer;
begin
  for n := FBreakpoints.Count - 1 downto 0 do
    TIDEBreakPoint(FBreakpoints[n]).Group := nil;
  for n := FReferences.Count - 1 downto 0 do
    TIDEBreakPoint(FReferences[n]).RemoveDisableGroup(Self);
  for n := FReferences.Count - 1 downto 0 do
    TIDEBreakPoint(FReferences[n]).RemoveEnableGroup(Self);

  inherited Destroy;
  FreeAndNil(FBreakpoints);
  FreeAndNil(FReferences);
end;

function TIDEBreakPointGroup.GetBreakpoint(const AIndex: Integer): TIDEBreakPoint;
begin
  Result := TIDEBreakPoint(FBreakPoints[AIndex]);
end;

function TIDEBreakPointGroup.Remove(const ABreakPoint: TIDEBreakPoint): Integer;
begin
  Result := FBreakpoints.Remove(ABreakPoint);
  if ABreakpoint.Group = Self
  then ABreakpoint.Group := nil;
end;

procedure TIDEBreakPointGroup.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  Name:=XMLConfig.GetValue(Path+'Name/Value','');
  // the breakpoints of this group are not loaded here.
  // They are loaded by the TIDEBreakPoints object.
  InitialEnabled:=XMLConfig.GetValue(Path+'InitialEnabled/Value',true);
  FEnabled:=InitialEnabled;
end;

procedure TIDEBreakPointGroup.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  XMLConfig.SetDeleteValue(Path+'Name/Value',Name,'');
  // the breakpoints of this group are not saved here.
  // They are saved by the TIDEBreakPoints object.
  XMLConfig.SetDeleteValue(Path+'InitialEnabled/Value',InitialEnabled,true);
end;

procedure TIDEBreakPointGroup.RemoveReference(const ABreakPoint: TIDEBreakPoint);
begin
  FReferences.Remove(ABreakPoint);
end;

procedure TIDEBreakPointGroup.SetEnabled(const AValue: Boolean);
var
  n: Integer;
begin
  if FEnabled <> AValue
  then begin
    FEnabled := AValue;
    for n := 0 to FBreakPoints.Count - 1 do
      TIDEBreakPoint(FBreakPoints[n]).Enabled := FEnabled;
  end;
end;

procedure TIDEBreakPointGroup.SetInitialEnabled(const AValue: Boolean);
begin
  if FInitialEnabled=AValue then exit;
  FInitialEnabled:=AValue;
end;

procedure TIDEBreakPointGroup.SetName(const AValue: String);
begin
  FName := AValue;
end;

procedure TIDEBreakPointGroup.AssignTo(Dest: TPersistent);
var
  DestGroup: TIDEBreakPointGroup;
begin
  if Dest is TIDEBreakPointGroup then begin
    DestGroup:=TIDEBreakPointGroup(Dest);
    DestGroup.Name:=Name;
    DestGroup.InitialEnabled:=InitialEnabled;
    DestGroup.Enabled:=Enabled;
  end else
    inherited AssignTo(Dest);
end;

{ =========================================================================== }
{ TIDEBreakPointGroups }
{ =========================================================================== }

constructor TIDEBreakPointGroups.Create;
begin
  inherited Create(TIDEBreakPointGroup);
end;

procedure TIDEBreakPointGroups.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var
  NewCount: integer;
  NewGroup: TIDEBreakPointGroup;
  i: Integer;
  OldGroup: TIDEBreakPointGroup;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'Count',0);
  for i:=0 to NewCount-1 do begin
    NewGroup:=TIDEBreakPointGroup(inherited Add);
    NewGroup.LoadFromXMLConfig(XMLConfig,
                               Path+'Item'+IntToStr(i+1)+'/');
    OldGroup:=FindGroupByName(NewGroup.Name,NewGroup);
    if OldGroup<>nil then
      NewGroup.Free;
  end;
end;

procedure TIDEBreakPointGroups.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var
  Cnt: Integer;
  CurGroup: TIDEBreakPointGroup;
  i: Integer;
begin
  Cnt:=Count;
  XMLConfig.SetDeleteValue(Path+'Count',Cnt,0);
  for i:=0 to Cnt-1 do begin
    CurGroup:=Items[i];
    CurGroup.SaveToXMLConfig(XMLConfig,
                             Path+'Item'+IntToStr(i+1)+'/');
  end;
end;

function TIDEBreakPointGroups.GetGroupByName(const GroupName: string
  ): TIDEBreakPointGroup;
begin
  Result:=FindGroupByName(GroupName,nil);
end;

function TIDEBreakPointGroups.FindGroupByName(const GroupName: string;
  Ignore: TIDEBreakPointGroup): TIDEBreakPointGroup;
var
  i: Integer;
begin
  i:=Count-1;
  while i>=0 do begin
    Result:=Items[i];
    if (AnsiCompareText(Result.Name,GroupName)=0)
    and (Ignore<>Result) then
      exit;
    dec(i);
  end;
  Result:=nil;
end;

function TIDEBreakPointGroups.IndexOfGroupWithName(const GroupName: string;
  Ignore : TIDEBreakPointGroup): integer;
begin
  Result:=Count-1;
  while (Result>=0)
  and ((AnsiCompareText(Items[Result].Name,GroupName)<>0)
    or (Items[Result]=Ignore))
  do
    dec(Result);
end;

procedure TIDEBreakPointGroups.InitTargetStart;
var
  i: Integer;
begin
  for i:=0 to Count-1 do
    Items[i].Enabled:=Items[i].InitialEnabled;
end;

function TIDEBreakPointGroups.GetItem(const AnIndex: Integer
  ): TIDEBreakPointGroup;
begin
  Result := TIDEBreakPointGroup(inherited GetItem(AnIndex));
end;

procedure TIDEBreakPointGroups.SetItem(const AnIndex: Integer;
  const AValue: TIDEBreakPointGroup);
begin
  inherited SetItem(AnIndex, AValue);
end;

(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   W A T C H E S                                                          **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

{ =========================================================================== }
{ TDBGWatch }
{ =========================================================================== }

procedure TDBGWatch.AssignTo(Dest: TPersistent);
begin
  if Dest is TDBGWatch
  then begin
    TDBGWatch(Dest).SetExpression(FExpression);
    TDBGWatch(Dest).SetEnabled(FEnabled);
  end
  else inherited;
end;

constructor TDBGWatch.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FEnabled := False;
end;

procedure TDBGWatch.LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string
  );
begin
  Expression:=XMLConfig.GetValue(Path+'Expression/Value','');
  InitialEnabled:=XMLConfig.GetValue(Path+'InitialEnabled/Value',true);
  FEnabled:=FInitialEnabled;
end;

procedure TDBGWatch.SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
begin
  XMLConfig.SetDeleteValue(Path+'Expression/Value',Expression,'');
  XMLConfig.SetDeleteValue(Path+'InitialEnabled/Value',InitialEnabled,true);
end;

procedure TDBGWatch.DoEnableChange;
begin
  Changed(False);
end;

procedure TDBGWatch.DoExpressionChange;
begin
  Changed(False);
end;

procedure TDBGWatch.DoStateChange;
begin    
end;

function TDBGWatch.GetDebugger: TDebugger;
begin
  Result := TDBGWatches(Collection).FDebugger;
end;

function TDBGWatch.GetValid: TValidState;
begin
  Result := vsUnknown;
end;

function TDBGWatch.GetValue: String;
begin       
  if not Enabled
  then Result := '<disabled>'
  else
    case Valid of
    vsValid:   Result := '<valid>';
    vsInvalid: Result := '<invalid>';
    else
    {vsUnknown:}Result := '<unknown>';
    end;
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
  if AValue <> FExpression
  then begin
    FExpression := AValue;
    DoExpressionChange;
  end;
end;

procedure TDBGWatch.SetInitialEnabled(const AValue: Boolean);
begin
  if FInitialEnabled=AValue then exit;
  FInitialEnabled:=AValue;
end;

procedure TDBGWatch.SetValid(const AValue: TValidState);
begin
  if FValid <> AValue
  then begin
    FValid := AValue;
    Changed(False);
  end;
end;

{ =========================================================================== }
{ TDBGWatches }
{ =========================================================================== }

function TDBGWatches.Add(const AExpression: String): TDBGWatch;
var
  n: Integer;
  Notification: TDBGWatchesNotification;
begin
  Result := Find(AExpression);
  if Result <> nil then Exit;

  Result := TDBGWatch(inherited Add);
  Result.Expression := AExpression;
  for n := 0 to FNotificationList.Count - 1 do
  begin
    Notification := TDBGWatchesNotification(FNotificationList[n]);
    if Assigned(Notification.FOnAdd)
    then Notification.FOnAdd(Self, Result);
  end;
end;

procedure TDBGWatches.AddNotification(
  const ANotification: TDBGWatchesNotification);
begin
  FNotificationList.Add(ANotification);
  ANotification.AddReference;
end;

constructor TDBGWatches.Create(const ADebugger: TDebugger;
  const AWatchClass: TDBGWatchClass);
begin
  FDebugger := ADebugger;
  FNotificationList := TList.Create;
  inherited Create(AWatchClass);
end;

destructor TDBGWatches.Destroy;
var
  n: Integer;
begin
  for n := FNotificationList.Count - 1 downto 0 do
    TDebuggerNotification(FNotificationList[n]).ReleaseReference;

  inherited;

  FreeAndNil(FNotificationList);
end;

procedure TDBGWatches.DoStateChange;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
    GetItem(n).DoStateChange;
end;

function TDBGWatches.Find(const AExpression: String): TDBGWatch;
var
  n: Integer;
  S: String;
begin
  S := UpperCase(AExpression);
  for n := 0 to Count - 1 do
  begin
    Result := GetItem(n);
    if UpperCase(Result.Expression) = S
    then Exit;
  end;
  Result := nil;
end;

function TDBGWatches.GetItem(const AnIndex: Integer): TDBGWatch;
begin
  Result := TDBGWatch(inherited GetItem(AnIndex));
end;

procedure TDBGWatches.Removed(const AWatch: TDBGWatch);
var
  n: Integer;
  Notification: TDBGWatchesNotification;
begin
  for n := 0 to FNotificationList.Count - 1 do
  begin
    Notification := TDBGWatchesNotification(FNotificationList[n]);
    if Assigned(Notification.FOnRemove)
    then Notification.FOnRemove(Self, AWatch);
  end;
end;

procedure TDBGWatches.RemoveNotification(
  const ANotification: TDBGWatchesNotification);
begin
  FNotificationList.Remove(ANotification);
  ANotification.ReleaseReference;
end;

procedure TDBGWatches.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var
  NewCount: Integer;
  i: Integer;
  NewWatch: TDBGWatch;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'Count',0);
  for i:=0 to NewCount-1 do begin
    NewWatch:=TDBGWatch(inherited Add);
    NewWatch.LoadFromXMLConfig(XMLConfig,Path+'Item'+IntToStr(i+1)+'/');
  end;
end;

procedure TDBGWatches.SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string
  );
var
  Cnt: Integer;
  i: Integer;
  CutWatch: TDBGWatch;
begin
  Cnt:=Count;
  XMLConfig.SetDeleteValue(Path+'Count',Cnt,0);
  for i:=0 to Cnt-1 do begin
    CutWatch:=Items[i];
    CutWatch.SaveToXMLConfig(XMLConfig,Path+'Item'+IntToStr(i+1)+'/');
  end;
end;

procedure TDBGWatches.InitTargetStart;
var
  i: Integer;
begin
  for i:=0 to Count-1 do
    Items[i].Enabled:=Items[i].InitialEnabled;
end;

procedure TDBGWatches.SetItem(const AnIndex: Integer; const AValue: TDBGWatch);
begin
  inherited SetItem(AnIndex, AValue);
end;

procedure TDBGWatches.Update(Item: TCollectionItem);
var
  n: Integer;
  Notification: TDBGWatchesNotification;
begin
  // Note: Item will be nil in case all items need to be updated
  for n := 0 to FNotificationList.Count - 1 do
  begin
    Notification := TDBGWatchesNotification(FNotificationList[n]);
    if Assigned(Notification.FOnUpdate)
    then Notification.FOnUpdate(Self, TDBGWatch(Item));
  end;
end;

(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   L O C A L S                                                            **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

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

(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   C A L L S T A C K                                                      **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

{ =========================================================================== }
{ TDBGCallStackEntry }
{ =========================================================================== }

constructor TDBGCallStackEntry.Create(const AIndex: Integer;
  const AnAdress: Pointer; const AnArguments: TStrings;
  const AFunctionName: String; const ASource: String; const ALine: Integer);
begin
  inherited Create;   
  FIndex := AIndex;
  FAdress := AnAdress;
  FArguments := TStringlist.Create;
  FArguments.Assign(AnArguments);
  FFunctionName := AFunctionName;
  FSource := ASource;
  FLine := ALine;
end;

destructor TDBGCallStackEntry.Destroy;
begin
  inherited;
  FreeAndNil(FArguments);
end;

function TDBGCallStackEntry.GetArgumentCount: Integer; 
begin
  Result := FArguments.Count;
end;

function TDBGCallStackEntry.GetArgumentName(const AnIndex: Integer): String;
begin
  Result := FArguments.Names[AnIndex];
end;

function TDBGCallStackEntry.GetArgumentValue(const AnIndex: Integer): String;
begin                        
  Result := FArguments[AnIndex];
  Result := GetPart('=', '', Result);
end;

{ =========================================================================== }
{ TDBGCallStack }
{ =========================================================================== }

procedure TDBGCallStack.Clear;
var
  n:Integer;
begin
  for n := 0 to FEntries.Count - 1 do 
    TObject(FEntries[n]).Free;
    
  FEntries.Clear;  
end;

function TDBGCallStack.Count: Integer;
begin
  if  (FDebugger <> nil) 
  and (FDebugger.State = dsPause)
  then Result := GetCount
  else Result := 0;
end;

constructor TDBGCallStack.Create(const ADebugger: TDebugger);
begin
  FDebugger := ADebugger;
  FEntries := TList.Create;
  FOldState := FDebugger.State;
  inherited Create;
end;

function TDBGCallStack.CreateStackEntry(
  const AIndex: Integer): TDBGCallStackEntry;
begin
  Result := nil;
end;

destructor TDBGCallStack.Destroy;
begin
  Clear;
  inherited;
  FreeAndNil(FEntries);
end;

procedure TDBGCallStack.DoChange; 
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TDBGCallStack.DoStateChange; 
begin
  if FDebugger.State = dsPause
  then DoChange
  else begin
    if FOldState = dsPause
    then begin 
      Clear;
      DoChange;
    end;
  end;          
  FOldState := FDebugger.State;
end;

function TDBGCallStack.GetCount: Integer;
begin
  Result := 0;
end;

function TDBGCallStack.GetStackEntry(const AIndex: Integer): TDBGCallStackEntry;
var
  n: Integer;
begin
  if (AIndex < 0) 
  or (AIndex >= Count)
  then raise EInvalidOperation.CreateFmt('Index out of range (%d)', [AIndex]);
  
  for n := 0 to FEntries.Count - 1 do
  begin
    Result := TDBGCallStackEntry(FEntries[n]);
    if Result.FIndex = AIndex 
    then Exit;
  end;
  
  Result := CreateStackEntry(AIndex);
  if Result <> nil 
  then FEntries.Add(Result);
end;


(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   S I G N A L S  and  E X C E P T I O N S                                **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

{ =========================================================================== }
{ TBaseSignal }
{ =========================================================================== }

procedure TBaseSignal.AssignTo(Dest: TPersistent);
begin
  if Dest is TBaseSignal
  then begin
    TBaseSignal(Dest).Name := FName;
    TBaseSignal(Dest).ID := FID;
    TBaseSignal(Dest).HandledByDebugger := FHandledByDebugger;
    TBaseSignal(Dest).ResumeHandled := FResumeHandled;
  end
  else inherited AssignTo(Dest);
end;

constructor TBaseSignal.Create(ACollection: TCollection);
begin
  FID := 0;
  FHandledByDebugger := False;
  FResumeHandled := True;
  inherited Create(ACollection);
end;

procedure TBaseSignal.SetHandledByDebugger(const AValue: Boolean);
begin
  if AValue = FHandledByDebugger then Exit;
  FHandledByDebugger := AValue;
  Changed;
end;

procedure TBaseSignal.SetID (const AValue: Integer );
begin
  if FID = AValue then Exit;
  FID := AValue;
  Changed;
end;

procedure TBaseSignal.SetName (const AValue: String );
begin
  if FName = AValue then Exit;
  FName := AValue;
  Changed;
end;

procedure TBaseSignal.SetResumeHandled(const AValue: Boolean);
begin
  if FResumeHandled = AValue then Exit;
  FResumeHandled := AValue;
  Changed;
end;

{ =========================================================================== }
{ TDBGSignal }
{ =========================================================================== }

function TDBGSignal.GetDebugger: TDebugger;
begin
  Result := TDBGSignals(Collection).FDebugger;
end;

{ =========================================================================== }
{ TIDESignal }
{ =========================================================================== }

procedure TIDESignal.LoadFromXMLConfig (const AXMLConfig: TXMLConfig; const APath: string );
begin
  // TODO
end;

procedure TIDESignal.SaveToXMLConfig (const AXMLConfig: TXMLConfig; const APath: string );
begin
  // TODO
end;

{ =========================================================================== }
{ TBaseSignals }
{ =========================================================================== }

function TBaseSignals.Add (const AName: String; AID: Integer ): TBaseSignal;
begin
  Result := TBaseSignal(inherited Add);
  Result.BeginUpdate;
  try
    Result.Name := AName;
    Result.ID := AID;
  finally
    Result.EndUpdate;
  end;
end;

constructor TBaseSignals.Create (const AItemClass: TBaseSignalClass );
begin
  inherited Create(AItemClass);
end;

function TBaseSignals.Find(const AName: String): TBaseSignal;
var
  n: Integer;
  S: String;
begin
  S := UpperCase(AName);
  for n := 0 to Count - 1 do
  begin
    Result := TBaseSignal(GetItem(n));
    if UpperCase(Result.Name) = S
    then Exit;
  end;
  Result := nil;
end;

{ =========================================================================== }
{ TDBGSignals }
{ =========================================================================== }

function TDBGSignals.Add(const AName: String; AID: Integer): TDBGSignal;
begin
  Result := TDBGSignal(inherited Add(AName, AID));
end;

constructor TDBGSignals.Create(const ADebugger: TDebugger;
                               const ASignalClass: TDBGSignalClass);
begin
  FDebugger := ADebugger;
  inherited Create(ASignalClass);
end;

function TDBGSignals.Find(const AName: String): TDBGSignal;
begin
  Result := TDBGSignal(inherited Find(ANAme));
end;

function TDBGSignals.GetItem(const AIndex: Integer): TDBGSignal;
begin
  Result := TDBGSignal(inherited GetItem(AIndex));
end;

procedure TDBGSignals.SetItem(const AIndex: Integer; const AValue: TDBGSignal);
begin
  inherited SetItem(AIndex, AValue);
end;

{ =========================================================================== }
{ TIDESignals }
{ =========================================================================== }

function TIDESignals.Add(const AName: String; AID: Integer): TIDESignal;
begin
  Result := TIDESignal(inherited Add(AName, AID));
end;

function TIDESignals.Find(const AName: String): TIDESignal;
begin
  Result := TIDESignal(inherited Find(AName));
end;

function TIDESignals.GetItem(const AIndex: Integer): TIDESignal;
begin
  Result := TIDESignal(inherited GetItem(AIndex));
end;

procedure TIDESignals.LoadFromXMLConfig(const AXMLConfig: TXMLConfig; const APath: string);
begin
  // TODO
end;

procedure TIDESignals.SaveToXMLConfig(const AXMLConfig: TXMLConfig; const APath: string);
begin
  // TODO
end;

procedure TIDESignals.SetItem(const AIndex: Integer; const AValue: TIDESignal);
begin
  inherited SetItem(AIndex, AValue);
end;

{ =========================================================================== }
{ TBaseException }
{ =========================================================================== }

procedure TBaseException.AssignTo(Dest: TPersistent);
begin
  if Dest is TBaseException
  then begin
    TBaseException(Dest).Name := FName;
  end
  else inherited AssignTo(Dest);
end;

constructor TBaseException.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
end;

procedure TBaseException.LoadFromXMLConfig(const AXMLConfig: TXMLConfig;
  const APath: string);
begin
  FName:=AXMLConfig.GetValue(APath+'Name/Value','');
end;

procedure TBaseException.SaveToXMLConfig(const AXMLConfig: TXMLConfig;
  const APath: string);
begin
  AXMLConfig.SetDeleteValue(APath+'Name/Value',FName,'');
end;

procedure TBaseException.SetName(const AValue: String);
begin
  if FName = AValue then exit;
  
  if TBaseExceptions(GetOwner).Find(AValue) <> nil
  then raise EDBGExceptions.Create('Duplicate name');

  FName := AValue;
  Changed;
end;

{ =========================================================================== }
{ TIDEException }
{ =========================================================================== }

constructor TIDEException.Create (ACollection: TCollection );
begin
  FEnabled := True;
  inherited Create(ACollection);
end;

procedure TIDEException.LoadFromXMLConfig(const AXMLConfig: TXMLConfig;
  const APath: string);
begin
  inherited LoadFromXMLConfig(AXMLConfig, APath);
  FEnabled:=AXMLConfig.GetValue(APath+'Enabled/Value',true);
end;

procedure TIDEException.SaveToXMLConfig(const AXMLConfig: TXMLConfig;
  const APath: string);
begin
  inherited SaveToXMLConfig(AXMLConfig, APath);
  AXMLConfig.SetDeleteValue(APath+'Enabled/Value',FEnabled,true);
end;

procedure TIDEException.SetEnabled(const AValue: Boolean);
begin
  if FEnabled = AValue then Exit;
  FEnabled := AValue;
  Changed;
end;

{ =========================================================================== }
{ TBaseExceptions }
{ =========================================================================== }

function TBaseExceptions.Add(const AName: String): TBaseException;
begin
  Result := TBaseException(inherited Add);
  Result.Name := AName;
end;

constructor TBaseExceptions.Create(const AItemClass: TBaseExceptionClass);
begin
  inherited Create(AItemClass);
end;

destructor TBaseExceptions.Destroy;
begin
  ClearExceptions;
  inherited Destroy;
end;

function TBaseExceptions.Find(const AName: String): TBaseException;
var
  n: Integer;
  S: String;
begin
  S := UpperCase(AName);
  for n := 0 to Count - 1 do
  begin
    Result := TBaseException(GetItem(n));
    if UpperCase(Result.Name) = S
    then Exit;
  end;
  Result := nil;
end;

procedure TBaseExceptions.ClearExceptions;
begin
  while Count>0 do
    TBaseException(GetItem(Count-1)).Free;
end;

{ =========================================================================== }
{ TDBGExceptions }
{ =========================================================================== }

function TDBGExceptions.Add(const AName: String): TDBGException;
begin
  Result := TDBGException(inherited Add(AName));
end;

constructor TDBGExceptions.Create(const ADebugger: TDebugger; const AExceptionClass: TDBGExceptionClass);
begin
  FDebugger := ADebugger;
  inherited Create(AExceptionClass);
end;

function TDBGExceptions.Find(const AName: String): TDBGException;
begin
  Result := TDBGException(inherited Find(AName));
end;

function TDBGExceptions.GetItem(const AIndex: Integer): TDBGException;
begin
  Result := TDBGException(inherited GetItem(AIndex));
end;

procedure TDBGExceptions.SetItem(const AIndex: Integer; const AValue: TDBGException);
begin
  inherited SetItem(AIndex, AValue);
end;

{ =========================================================================== }
{ TIDEExceptions }
{ =========================================================================== }

function TIDEExceptions.Add(const AName: String): TIDEException;
begin
  Result := TIDEException(inherited Add(AName));
end;

function TIDEExceptions.Find(const AName: String): TIDEException;
begin
  Result := TIDEException(inherited Find(AName));
end;

function TIDEExceptions.GetItem(const AIndex: Integer): TIDEException;
begin
  Result := TIDEException(inherited GetItem(AIndex));
end;

procedure TIDEExceptions.LoadFromXMLConfig (const AXMLConfig: TXMLConfig;
  const APath: string);
begin
  // TODO
end;

procedure TIDEExceptions.SaveToXMLConfig (const AXMLConfig: TXMLConfig;
  const APath: string);
begin
  // TODO
end;

procedure TIDEExceptions.SetItem(const AIndex: Integer;
  const AValue: TIDEException);
begin
  inherited SetItem(Aindex, AValue);
end;

end.
{ =============================================================================
  $Log$
  Revision 1.51  2003/08/08 10:24:48  mattias
  fixed initialenabled, debuggertype, linkscaner open string constant

  Revision 1.50  2003/08/08 07:49:56  mattias
  fixed mem leaks in debugger

  Revision 1.49  2003/08/02 00:20:20  marc
  * fixed environment handling to debuggee

  Revision 1.48  2003/07/30 23:15:39  marc
  * Added RegisterDebugger

  Revision 1.47  2003/07/28 18:02:06  mattias
  added findinfiles strat implementation from Bob Wingard

  Revision 1.46  2003/07/25 17:05:58  mattias
  moved debugger type to the debugger options

  Revision 1.45  2003/07/24 08:47:37  marc
  + Added SSHGDB debugger

  Revision 1.44  2003/06/13 19:21:31  marc
  MWE: + Added initial signal and exception handling

  Revision 1.43  2003/06/11 22:29:42  mattias
  fixed realizing bounds after loading form

  Revision 1.42  2003/06/09 15:58:05  mattias
  implemented view call stack key and jumping to last stack frame with debug info

  Revision 1.41  2003/06/09 14:30:47  marc
  MWE: + Added working dir.

  Revision 1.39  2003/06/03 16:12:14  mattias
  fixed loading bookmarks for editor index 0

  Revision 1.38  2003/06/03 10:29:22  mattias
  implemented updates between source marks and breakpoints

  Revision 1.37  2003/06/03 08:02:33  mattias
  implemented showing source lines in breakpoints dialog

  Revision 1.36  2003/06/03 01:35:39  marc
  MWE: = Splitted TDBGBreakpoint into TBaseBreakPoint, TIDEBreakpoint and
         TDBGBreakPoint

  Revision 1.35  2003/06/02 21:37:30  mattias
  fixed debugger stop

  Revision 1.34  2003/05/29 18:47:27  mattias
  fixed reposition sourcemark

  Revision 1.33  2003/05/29 17:40:10  marc
  MWE: * Fixed string resolving
       * Updated exception handling

  Revision 1.32  2003/05/28 17:40:55  mattias
  recuced update notifications

  Revision 1.31  2003/05/28 17:27:29  mattias
  recuced update notifications

  Revision 1.30  2003/05/28 00:58:50  marc
  MWE: * Reworked breakpoint handling

  Revision 1.29  2003/05/27 20:58:12  mattias
  implemented enable and deleting breakpoint in breakpoint dlg

  Revision 1.28  2003/05/27 08:01:31  marc
  MWE: + Added exception break
       * Reworked adding/removing breakpoints
       + Added Unknown breakpoint type

  Revision 1.27  2003/05/26 20:05:21  mattias
  made compiling gtk2 interface easier

  Revision 1.26  2003/05/26 11:08:20  mattias
  fixed double breakpoints

  Revision 1.25  2003/05/26 10:34:47  mattias
  implemented search, fixed double loading breakpoints

  Revision 1.24  2003/05/23 16:46:13  mattias
  added message, that debugger is readonly while running

  Revision 1.23  2003/05/23 14:12:51  mattias
  implemented restoring breakpoints

  Revision 1.22  2003/05/22 23:08:19  marc
  MWE: = Moved and renamed debuggerforms so that they can be
         modified by the ide
       + Added some parsing to evaluate complex expressions
         not understood by the debugger

  Revision 1.21  2003/05/22 17:06:49  mattias
  implemented InitialEnabled for breakpoints and watches

  Revision 1.20  2003/05/21 16:19:12  mattias
  implemented saving breakpoints and watches

  Revision 1.19  2003/05/21 08:09:04  mattias
  started loading/saving watches

  Revision 1.18  2003/05/20 21:41:07  mattias
  started loading/saving breakpoints

  Revision 1.17  2003/02/28 19:10:25  mattias
  added new ... dialog

  Revision 1.16  2002/08/28 10:44:44  lazarus
  MG: implemented run param environment variables

  Revision 1.15  2002/05/10 06:57:47  lazarus
  MG: updated licenses

  Revision 1.14  2002/04/30 15:57:39  lazarus
  MWE:
    + Added callstack object and dialog
    + Added checks to see if debugger = nil
    + Added dbgutils

  Revision 1.13  2002/04/24 20:42:29  lazarus
  MWE:
    + Added watches
    * Updated watches and watchproperty dialog to load as resource
    = renamed debugger resource files from *.lrc to *.lrs
    * Temporary fixed language problems on GDB (bug #508)
    * Made Debugmanager dialog handling more generic

  Revision 1.12  2002/03/25 22:38:29  lazarus
  MWE:
    + Added invalidBreakpoint image
    * Reorganized uniteditor so that breakpoints can be added erternal
    * moved breakpoints events to notification object

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
