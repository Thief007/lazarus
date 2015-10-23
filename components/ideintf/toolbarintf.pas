{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Ondrej Pokorny

  Abstract:
    Interface to the IDE toolbars.
}
unit ToolBarIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ComCtrls, IDECommands, MenuIntf;

type
  TIDEToolButton = class;
  TIDEToolButtonClass = class of TIDEToolButton;
  TIDEToolButtons = class;

  TIDEButtonCommand = class(TIDESpecialCommand)
  private
    FToolButtonClass: TIDEToolButtonClass;
    FToolButtons: TIDEToolButtons;
  protected
    procedure SetName(const aName: string); override;
    procedure SetEnabled(const aEnabled: Boolean); override;
    procedure SetChecked(const aChecked: Boolean); override;
    procedure SetCaption(aCaption: string); override;
    procedure SetHint(const aHint: string); override;
    procedure SetImageIndex(const aImageIndex: Integer); override;
    procedure SetResourceName(const aResourceName: string); override;
    procedure ShortCutsUpdated(const aShortCut, aShortCutKey2: TShortCut); override;
  public
    procedure ToolButtonAdded(const aBtn: TIDEToolButton);
  public
    constructor Create(const TheName: string); override;
    destructor Destroy; override;
  public
    property ToolButtonClass: TIDEToolButtonClass read FToolButtonClass write FToolButtonClass;
    property ToolButtons: TIDEToolButtons read FToolButtons;
  end;

  { TIDEToolButton }

  TIDEToolButton = class(TToolButton)
  private
    FItem: TIDEButtonCommand;
  protected
    procedure DoOnShowHint(HintInfo: PHintInfo); override;
  public
    procedure DoOnAdded; virtual;

    procedure Click; override;
    property Item: TIDEButtonCommand read FItem write FItem;
  end;

  TIDEToolButtonCategory = class
  private
    FButtons: TFPList;
    FDescription: string;
    FName: string;
    function GetButtons(Index: Integer): TIDEButtonCommand;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property Description: string read FDescription write FDescription;
    property Name: string read FName write FName;
    function ButtonCount: Integer;
    property Buttons[Index: Integer]: TIDEButtonCommand read GetButtons; default;
  end;

  TIDEToolButtonCategories = class
  private
    FButtonNames: TStringList;
    FCategories: TStringList;
    function GetItems(Index: Integer): TIDEToolButtonCategory;
  public
    constructor Create;
    destructor Destroy; override;
  public
    function Count: Integer;
    function AddButton(const aCategory: TIDEToolButtonCategory; const aName: string;
      const aCommand: TIDECommand): TIDEButtonCommand; overload;
    function AddButton(const aCommand: TIDECommand): TIDEButtonCommand; overload;
    function FindCreateCategory(const aName, aDescription: string): TIDEToolButtonCategory;
    function FindItemByName(const aName: string): TIDEButtonCommand;
    function FindItemByMenuPathOrName(var aName: string): TIDEButtonCommand;
    function FindItemByCommand(const aCommand: TIDECommand): TIDEButtonCommand;
    property Items[Index: Integer]: TIDEToolButtonCategory read GetItems; default;
  end;

  TIDEToolButtonsEnumerator = class
  private
    FList: TIDEToolButtons;
    FPosition: Integer;
  public
    constructor Create(AButtons: TIDEToolButtons);
    function GetCurrent: TIDEToolButton;
    function MoveNext: Boolean;
    property Current: TIDEToolButton read GetCurrent;
  end;

  TIDEToolButtons = class(TComponent)
  private
    FList: TFPList;
    function GetCount: Integer;
    function GetItems(Index: Integer): TIDEToolButton;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  public
    function GetEnumerator: TIDEToolButtonsEnumerator;
    procedure Add(const aBtn: TIDEToolButton);

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TIDEToolButton read GetItems; default;
  end;


var
  IDEToolButtonCategories: TIDEToolButtonCategories = nil;// created by the IDE


function RegisterIDEButtonCategory(const aName, aDescription: string): TIDEToolButtonCategory;
function RegisterIDEButtonCommand(const aCategory: TIDEToolButtonCategory; const aName: string;
  const aCommand: TIDECommand): TIDEButtonCommand;
function RegisterIDEButtonCommand(const aCommand: TIDECommand): TIDEButtonCommand;

implementation

function RegisterIDEButtonCategory(const aName, aDescription: string): TIDEToolButtonCategory;
begin
  Result := IDEToolButtonCategories.FindCreateCategory(aName, aDescription);
end;

function RegisterIDEButtonCommand(const aCategory: TIDEToolButtonCategory;
  const aName: string; const aCommand: TIDECommand): TIDEButtonCommand;
begin
  Result := IDEToolButtonCategories.AddButton(aCategory,  aName,  aCommand);
end;

function RegisterIDEButtonCommand(const aCommand: TIDECommand): TIDEButtonCommand;
begin
  Result := IDEToolButtonCategories.AddButton(aCommand);
end;

{ TIDEToolButtonsEnumerator }

constructor TIDEToolButtonsEnumerator.Create(AButtons: TIDEToolButtons);
begin
  inherited Create;
  FList := AButtons;
  FPosition := -1;
end;

function TIDEToolButtonsEnumerator.GetCurrent: TIDEToolButton;
begin
  Result := FList[FPosition];
end;

function TIDEToolButtonsEnumerator.MoveNext: Boolean;
begin
  Inc(FPosition);
  Result := FPosition < FList.Count;
end;

{ TIDEToolButtons }

procedure TIDEToolButtons.Add(const aBtn: TIDEToolButton);
begin
  FList.Add(aBtn);
  aBtn.FreeNotification(Self);
end;

constructor TIDEToolButtons.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FList := TFPList.Create;
end;

destructor TIDEToolButtons.Destroy;
var
  I: Integer;
begin
  for I := 0 to Count-1 do
    Items[I].RemoveFreeNotification(Self);
  FList.Free;
  inherited Destroy;
end;

function TIDEToolButtons.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TIDEToolButtons.GetEnumerator: TIDEToolButtonsEnumerator;
begin
  Result := TIDEToolButtonsEnumerator.Create(Self);
end;

function TIDEToolButtons.GetItems(Index: Integer): TIDEToolButton;
begin
  Result := TIDEToolButton(FList[Index]);
end;

procedure TIDEToolButtons.Notification(AComponent: TComponent; Operation: TOperation);
var
  xIndex: Integer;
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) then
  begin
    xIndex := FList.IndexOf(AComponent);
    if xIndex >= 0 then
      FList.Delete(xIndex);
  end;
end;

{ TIDEButtonCommand }

constructor TIDEButtonCommand.Create(const TheName: string);
begin
  inherited Create(TheName);
  FToolButtonClass := TIDEToolButton;
  FToolButtons := TIDEToolButtons.Create(nil);
end;

destructor TIDEButtonCommand.Destroy;
begin
  FToolButtons.Free;
  inherited Destroy;
end;

procedure TIDEButtonCommand.SetEnabled(const aEnabled: Boolean);
var
  xBtn: TIDEToolButton;
begin
  inherited SetEnabled(aEnabled);
  for xBtn in FToolButtons do
    xBtn.Enabled:=Enabled;
end;

procedure TIDEButtonCommand.SetHint(const aHint: string);
var
  xBtn: TIDEToolButton;
begin
  inherited SetHint(aHint);
  for xBtn in FToolButtons do
    xBtn.Hint:=GetHintOrCaptionWithShortCut;
end;

procedure TIDEButtonCommand.SetImageIndex(const aImageIndex: Integer);
var
  xBtn: TIDEToolButton;
begin
  inherited SetImageIndex(aImageIndex);
  for xBtn in FToolButtons do
    xBtn.ImageIndex:=ImageIndex;
end;

procedure TIDEButtonCommand.SetName(const aName: string);
var
  i: Integer;
begin
  if Name=aName then Exit;
  i:=IDEToolButtonCategories.FButtonNames.IndexOf(Name);
  inherited SetName(aName);
  if (i>=0) and (IDEToolButtonCategories.FButtonNames.Objects[i] = Self) then
  begin
    IDEToolButtonCategories.FButtonNames.Delete(i);
    IDEToolButtonCategories.FButtonNames.AddObject(aName,  Self);
  end;
end;

procedure TIDEButtonCommand.SetCaption(aCaption: string);
var
  xBtn: TIDEToolButton;
begin
  inherited SetCaption(aCaption);
  for xBtn in FToolButtons do
    xBtn.Hint:=GetHintOrCaptionWithShortCut;
end;

procedure TIDEButtonCommand.SetChecked(const aChecked: Boolean);
var
  xBtn: TIDEToolButton;
begin
  inherited SetChecked(aChecked);
  for xBtn in FToolButtons do
    xBtn.Down:=Checked;
end;

procedure TIDEButtonCommand.SetResourceName(const aResourceName: string);
var
  xBtn: TIDEToolButton;
begin
  inherited SetResourceName(aResourceName);
  for xBtn in FToolButtons do
    xBtn.ImageIndex:=ImageIndex;
end;

procedure TIDEButtonCommand.ShortCutsUpdated(const aShortCut, aShortCutKey2: TShortCut);
var
  xBtn: TIDEToolButton;
begin
  inherited ShortCutsUpdated(aShortCut, aShortCutKey2);
  for xBtn in FToolButtons do
    xBtn.Hint:=GetHintOrCaptionWithShortCut;
end;

procedure TIDEButtonCommand.ToolButtonAdded(const aBtn: TIDEToolButton);
begin
  FToolButtons.Add(aBtn);
  aBtn.DoOnAdded;
end;

{ TIDEToolButtonCategory }

function TIDEToolButtonCategory.ButtonCount: Integer;
begin
  Result := FButtons.Count;
end;

constructor TIDEToolButtonCategory.Create;
begin
  FButtons := TFPList.Create;
end;

destructor TIDEToolButtonCategory.Destroy;
var
  i: Integer;
begin
  for i := 0 to ButtonCount-1 do
    Buttons[i].Free;
  FButtons.Free;
  inherited Destroy;
end;

function TIDEToolButtonCategory.GetButtons(Index: Integer): TIDEButtonCommand;
begin
  Result := TIDEButtonCommand(FButtons[Index]);
end;

{ TIDEToolButtonCategories }

function TIDEToolButtonCategories.AddButton(const aCommand: TIDECommand): TIDEButtonCommand;
var
  xCategory: TIDEToolButtonCategory;
begin
  Assert(aCommand<>nil, 'TIDEToolButtonCategories.AddButton: aCommand=nil');
  xCategory := RegisterIDEButtonCategory(aCommand.Category.Name, aCommand.Category.Description);
  Result := RegisterIDEButtonCommand(xCategory,  aCommand.Name, aCommand);
end;

function TIDEToolButtonCategories.AddButton(
  const aCategory: TIDEToolButtonCategory; const aName: string;
  const aCommand: TIDECommand): TIDEButtonCommand;
begin
  Result := FindItemByName(aName);
  if Result=nil then
  begin
    Result := TIDEButtonCommand.Create(aName);
    FButtonNames.AddObject(aName, Result);
    aCategory.FButtons.Add(Result);
    Result.Command:=aCommand;
  end;
end;

function TIDEToolButtonCategories.Count: Integer;
begin
  Result := FCategories.Count;
end;

constructor TIDEToolButtonCategories.Create;
begin
  FButtonNames := TStringList.Create;
  FButtonNames.Sorted := True;
  FButtonNames.Duplicates := dupIgnore;
  FCategories := TStringList.Create;
  FCategories.Sorted := True;
  FCategories.Duplicates := dupIgnore;
  FCategories.OwnsObjects := True;
end;

destructor TIDEToolButtonCategories.Destroy;
begin
  FButtonNames.Free;
  FCategories.Free;
  inherited Destroy;
end;

function TIDEToolButtonCategories.FindItemByMenuPathOrName(var aName: string
  ): TIDEButtonCommand;
var
  xMI: TIDEMenuItem;
begin
  Result := FindItemByName(aName);
  if Result<>nil then Exit;

  //find by path from aName (backwards compatibility)
  xMI := IDEMenuRoots.FindByPath(aName, False);
  if Assigned(xMI) and Assigned(xMI.Command) then
  begin
    Result := FindItemByCommand(xMI.Command);
    if Assigned(Result) then
      aName := xMI.Command.Name;
  end;
end;

function TIDEToolButtonCategories.FindCreateCategory(const aName,
  aDescription: string): TIDEToolButtonCategory;
var
  i: Integer;
begin
  i := FCategories.IndexOf(aName);
  if (i>=0) and (FCategories.Objects[i]<>nil) then
    Result := FCategories.Objects[i] as TIDEToolButtonCategory
  else
  begin
    Result := TIDEToolButtonCategory.Create;
    Result.Name := aName;
    Result.Description := aDescription;
    FCategories.AddObject(aName, Result);
  end;
end;

function TIDEToolButtonCategories.FindItemByCommand(const aCommand: TIDECommand
  ): TIDEButtonCommand;
var
  i, l: Integer;
begin
  for i := 0 to Count-1 do
    for l := 0 to Items[i].ButtonCount-1 do
      if Items[i].Buttons[l].Command = aCommand then
        Exit(Items[i].Buttons[l]);

  Result := nil;
end;

function TIDEToolButtonCategories.FindItemByName(const aName: string
  ): TIDEButtonCommand;
var
  i: Integer;
begin
  i := FButtonNames.IndexOf(aName);
  if (i>=0) and (FButtonNames.Objects[i]<>nil) then
    Result := FButtonNames.Objects[i] as TIDEButtonCommand
  else
    Result := nil;
end;

function TIDEToolButtonCategories.GetItems(Index: Integer): TIDEToolButtonCategory;
begin
  Result := TIDEToolButtonCategory(FCategories.Objects[Index]);
end;

{ TIDEToolButton }

procedure TIDEToolButton.Click;
begin
  inherited Click;
  if Assigned(FItem) then
    FItem.DoOnClick;
end;

procedure TIDEToolButton.DoOnAdded;
begin
  //override in descendants
end;

procedure TIDEToolButton.DoOnShowHint(HintInfo: PHintInfo);
begin
  inherited DoOnShowHint(HintInfo);
  if Assigned(FItem) and FItem.DoOnRequestCaption(Self) then
    HintInfo^.HintStr := FItem.GetHintOrCaptionWithShortCut;
end;

end.

