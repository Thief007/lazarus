{
 /***************************************************************************
                                   ActnList.pas
                                   ------------


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.LCL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit ActnList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, ImgList;
  
type

  { TContainedAction }

  TCustomActionList = class;

  TContainedAction = class(TBasicAction)
  private
    FCategory: string;
    FActionList: TCustomActionList;
    function GetIndex: Integer;
    function IsCategoryStored: Boolean;
    procedure SetCategory(const Value: string);
    procedure SetIndex(Value: Integer);
    procedure SetActionList(AActionList: TCustomActionList);
  protected
    procedure ReadState(Reader: TReader); override;
    procedure SetParentComponent(AParent: TComponent); override;
    procedure Change; override;
  public
    destructor Destroy; override;
    function Execute: Boolean; override;
    function GetParentComponent: TComponent; override;
    function HasParent: Boolean; override;
    function Update: Boolean; override;
    property ActionList: TCustomActionList read FActionList write SetActionList;
    property Index: Integer read GetIndex write SetIndex stored False;
  published
    property Category: string
      read FCategory write SetCategory stored IsCategoryStored;
  end;

  TContainedActionClass = class of TContainedAction;


  { TCustomActionList }

  TActionEvent = procedure (Action: TBasicAction; var Handled: Boolean) of object;
  TActionListState = (asNormal, asSuspended, asSuspendedEnabled);

  TCustomActionList = class(TComponent)
  private
    FActions: TList;
    FImageChangeLink: TChangeLink;
    FImages: TCustomImageList;
    FOnChange: TNotifyEvent;
    FOnExecute: TActionEvent;
    FOnUpdate: TActionEvent;
    FState: TActionListState;
    function GetAction(Index: Integer): TContainedAction;
    function GetActionCount: Integer;
    procedure ImageListChange(Sender: TObject);
    procedure SetAction(Index: Integer; Value: TContainedAction);
    procedure SetState(const Value: TActionListState);
  protected
    procedure AddAction(Action: TContainedAction);
    procedure RemoveAction(Action: TContainedAction);
    procedure Change; virtual;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure SetChildOrder(Component: TComponent; Order: Integer); override;
    procedure SetImages(Value: TCustomImageList); virtual;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnExecute: TActionEvent read FOnExecute write FOnExecute;
    property OnUpdate: TActionEvent read FOnUpdate write FOnUpdate;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    //function IsShortCut(var Message: TWMKey): Boolean;
    function UpdateAction(Action: TBasicAction): Boolean; override;
    property Actions[Index: Integer]: TContainedAction
      read GetAction write SetAction; default;
    property ActionCount: Integer read GetActionCount;
    property Images: TCustomImageList read FImages write SetImages;
    property State: TActionListState read FState write SetState default asNormal;
  end;


  { TActionList }

  TActionList = class(TCustomActionList)
  published
    property Images;
    property State;
    property OnChange;
    property OnExecute;
    property OnUpdate;
  end;


  { TShortCutList }

  TShortCutList = class(TStringList)
  private
    function GetShortCuts(Index: Integer): TShortCut;
  public
    function Add(const S: String): Integer; override;
    function IndexOfShortCut(const Shortcut: TShortCut): Integer;
    property ShortCuts[Index: Integer]: TShortCut read GetShortCuts;
  end;


  { TControlAction }

  THintEvent = procedure (var HintStr: string; var CanShow: Boolean) of object;

  TCustomAction = class(TContainedAction)
  private
    FDisableIfNoHandler: Boolean;
    FCaption: string;
    FChecking: Boolean;
    FChecked: Boolean;
    FEnabled: Boolean;
    FGroupIndex: Integer;
    FHelpType: THelpType;
    FHelpContext: THelpContext;
    FHelpKeyword: string;
    FHint: string;
    FImageIndex: TImageIndex;
    FShortCut: TShortCut;
    FVisible: Boolean;
    FOnHint: THintEvent;
    FSecondaryShortCuts: TShortCutList;
    FSavedEnabledState: Boolean;
    FAutoCheck: Boolean;
    procedure SetAutoCheck(Value: Boolean);
    procedure SetCaption(const Value: string);
    procedure SetChecked(Value: Boolean);
    procedure SetEnabled(Value: Boolean);
    procedure SetGroupIndex(const Value: Integer);
    procedure SetHelpContext(Value: THelpContext); virtual;
    procedure SetHelpKeyword(const Value: string); virtual;
    procedure SetHelpType(Value: THelpType);
    procedure SetHint(const Value: string);
    procedure SetImageIndex(Value: TImageIndex);
    procedure SetShortCut(Value: TShortCut);
    procedure SetVisible(Value: Boolean);
    function GetSecondaryShortCuts: TShortCutList;
    procedure SetSecondaryShortCuts(const Value: TShortCutList);
    function IsSecondaryShortCutsStored: Boolean;
  protected
    FImage: TObject;
    FMask: TObject;
    procedure AssignTo(Dest: TPersistent); override;
    procedure SetName(const Value: TComponentName); override;
    function HandleShortCut: Boolean; virtual;
    property SavedEnabledState: Boolean
      read FSavedEnabledState write FSavedEnabledState;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function DoHint(var HintStr: string): Boolean; dynamic;
    function Execute: Boolean; override;
    property AutoCheck: Boolean
      read FAutoCheck write  SetAutoCheck default False;
    property Caption: string read FCaption write SetCaption;
    property Checked: Boolean read FChecked write SetChecked default False;
    property DisableIfNoHandler: Boolean
      read FDisableIfNoHandler write FDisableIfNoHandler default False;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property GroupIndex: Integer read FGroupIndex write SetGroupIndex default 0;
    property HelpContext: THelpContext
      read FHelpContext write SetHelpContext default 0;
    property HelpKeyword: string read FHelpKeyword write SetHelpKeyword;
    property HelpType: THelpType
      read FHelpType write SetHelpType default htKeyword;
    property Hint: string read FHint write SetHint;
    property ImageIndex: TImageIndex
      read FImageIndex write SetImageIndex default -1;
    property ShortCut: TShortCut read FShortCut write SetShortCut default 0;
    property SecondaryShortCuts: TShortCutList read GetSecondaryShortCuts
      write SetSecondaryShortCuts stored IsSecondaryShortCutsStored;
    property Visible: Boolean read FVisible write SetVisible default True;
    property OnHint: THintEvent read FOnHint write FOnHint;
  end;


  { TAction }

  TAction = class(TCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
  published
    property AutoCheck;
    property Caption;
    property Checked;
    property Enabled;
    property GroupIndex;
    property HelpContext;
    property HelpKeyword;
    property HelpType;
    property Hint;
    property ImageIndex;
    property ShortCut;
    property SecondaryShortCuts;
    property Visible;
    property OnExecute;
    property OnHint;
    property OnUpdate;
  end;


  { TActionLink }

  TActionLink = class(TBasicActionLink)
  protected
    function IsCaptionLinked: Boolean; virtual;
    function IsCheckedLinked: Boolean; virtual;
    function IsEnabledLinked: Boolean; virtual;
    function IsGroupIndexLinked: Boolean; virtual;
    function IsHelpContextLinked: Boolean; virtual;
    function IsHelpLinked: Boolean; virtual;
    function IsHintLinked: Boolean; virtual;
    function IsImageIndexLinked: Boolean; virtual;
    function IsShortCutLinked: Boolean; virtual;
    function IsVisibleLinked: Boolean; virtual;
    procedure SetAutoCheck(Value: Boolean); virtual;
    procedure SetCaption(const Value: string); virtual;
    procedure SetChecked(Value: Boolean); virtual;
    procedure SetEnabled(Value: Boolean); virtual;
    procedure SetGroupIndex(Value: Integer); virtual;
    procedure SetHelpContext(Value: THelpContext); virtual;
    procedure SetHelpKeyword(const Value: string); virtual;
    procedure SetHelpType(Value: THelpType); virtual;
    procedure SetHint(const Value: string); virtual;
    procedure SetImageIndex(Value: Integer); virtual;
    procedure SetShortCut(Value: TShortCut); virtual;
    procedure SetVisible(Value: Boolean); virtual;
  end;

  TActionLinkClass = class of TActionLink;



  TEnumActionProc = procedure (const Category: string;
    ActionClass: TBasicActionClass; Info: Pointer) of object;

procedure RegisterActions(const CategoryName: string;
  const AClasses: array of TBasicActionClass; Resource: TComponentClass);
procedure UnRegisterActions(const AClasses: array of TBasicActionClass);
procedure EnumRegisteredActions(Proc: TEnumActionProc; Info: Pointer);
function CreateAction(AOwner: TComponent;
  ActionClass: TBasicActionClass): TBasicAction;

const
  RegisterActionsProc: procedure (const CategoryName: string;
    const AClasses: array of TBasicActionClass; Resource: TComponentClass)= nil;
  UnRegisterActionsProc:
    procedure (const AClasses: array of TBasicActionClass) = nil;
  EnumRegisteredActionsProc:
    procedure (Proc: TEnumActionProc; Info: Pointer) = nil;
  CreateActionProc:
    function (AOwner: TComponent;
              ActionClass: TBasicActionClass): TBasicAction = nil;

var
  ApplicationActionComponent: TComponent;


implementation


const
  SInvalidActionRegistration = 'Invalid action registration';
  SInvalidActionUnregistration = 'Invalid action unregistration';
  SInvalidActionEnumeration = 'Invalid action enumeration';
  SInvalidActionCreation = 'Invalid action creation';


procedure RegisterActions(const CategoryName: string;
  const AClasses: array of TBasicActionClass; Resource: TComponentClass);
begin
  if Assigned(RegisterActionsProc) then
    RegisterActionsProc(CategoryName, AClasses, Resource) else
    raise Exception.Create(SInvalidActionRegistration);
end;

procedure UnRegisterActions(const AClasses: array of TBasicActionClass);
begin
  if Assigned(UnRegisterActionsProc) then
    UnRegisterActionsProc(AClasses) else
    raise Exception.Create(SInvalidActionUnregistration);
end;

procedure EnumRegisteredActions(Proc: TEnumActionProc; Info: Pointer);
begin
  if Assigned(EnumRegisteredActionsProc) then
    EnumRegisteredActionsProc(Proc, Info) else
    raise Exception.Create(SInvalidActionEnumeration);
end;

function CreateAction(AOwner: TComponent;
  ActionClass: TBasicActionClass): TBasicAction;
begin
  if Assigned(CreateActionProc) then
    Result := CreateActionProc(AOwner, ActionClass) else
    raise Exception.Create(SInvalidActionCreation);
end;

{$I containedaction.inc}
{$I customactionlist.inc}
{$I actionlink.inc}
{$I shortcutlist.inc}
{$I customaction.inc}
{$I action.inc}

initialization
  ApplicationActionComponent:=nil;

end.

