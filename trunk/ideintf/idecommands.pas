{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

 Abstract:
   Under construction by Mattias
 
 
   Interface unit for IDE commands.
   IDE commands are functions like open file, save, build, ... .
   
   Every command can have up to two shortcuts. For example:
     ecCopy: two shortcuts: Ctrl+C and Ctrl+Insert
     ecDeleteChar: one shortcut: Delete
     ecInsertDateTime: no shortcut
   
   Commands are sorted into categories. For example:
     ecCopy is in the category 'Selection'.
     This is only to help the user find commands.
     
   Scopes:
     A command can work globally or only in some IDE windows.
     For example: When the user presses a key in the source editor, the IDE
       first searches in all commands with the Scope IDECmdScopeSrcEdit.
       Then it will search in all commands without scope.
}
unit IDECommands;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, LCLType, Menus, TextTools;
  
{$IFNDEF UseIDEScopes}
type
  TCommandArea = (
    caMenu,
    caSourceEditor,
    caDesigner
    );
  TCommandAreas = set of TCommandArea;

const
  caAll = [caMenu, caSourceEditor, caDesigner];
  caMenuOnly = [caMenu];
  caSrcEdit = [caMenu,caSourceEditor];
  caSrcEditOnly = [caSourceEditor];
  caDesign = [caMenu,caDesigner];
  caDesignOnly = [caDesigner];
{$ENDIF}

type
  TIDECommandKeys = class;

  { TIDECommandScope }
  { A TIDECommandScope defines a set of IDE windows that will share the same
    IDE commands. }

  TIDECommandScope = class(TPersistent)
  private
    FName: string;
    FIDEWindows: TFPList;
    FCommands: TFPList;
    function GetCommands(Index: integer): TIDECommandKeys;
    function GetIDEWindows(Index: integer): TCustomForm;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddWindow(AnWindow: TCustomForm);
    function IDEWindowCount: integer;
    procedure AddCommand(ACommand: TIDECommandKeys);
    function CommandCount: integer;
    function HasIDEWindow(AnWindow: TCustomForm): boolean;
  public
    property Name: string read FName;
    property IDEWindows[Index: integer]: TCustomForm read GetIDEWindows;
    property Commands[Index: integer]: TIDECommandKeys read GetCommands;
  end;

  { TIDECommandScopes }

  TIDECommandScopes = class(TPersistent)
  private
    FItems: TFPList;
    function GetItems(Index: integer): TIDECommandScope;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(NewItem: TIDECommandScope);
    function IndexOf(AnItem: TIDECommandScope): Integer;
    function IndexByName(const AName: string): Integer;
    function FindByName(const AName: string): TIDECommandScope;
    function CreateUniqueName(const AName: string): string;
    function Count: integer;
  public
    property Items[Index: integer]: TIDECommandScope read GetItems;
  end;
  

  { TIDEShortCut }

  TIDEShortCut = record
    Key1: word;
    Shift1: TShiftState;
    Key2: word;
    Shift2: TShiftState;
  end;

  { TIDECommandCategory }
  { TIDECommandCategory is used to divide the commands in handy packets }
    
  TIDECommandCategory = class(TList)
  protected
    {$IFDEF UseIDEScopes}
    FScope: TIDECommandScope;
    {$ELSE}
    FAreas: TCommandAreas;
    {$ENDIF}
    FDescription: string;
    FName: string;
    FParent: TIDECommandCategory;
  public
    property Name: string read FName;
    property Description: string read FDescription;
    property Parent: TIDECommandCategory read FParent;
    procedure Delete(Index: Integer); virtual;
    {$IFDEF UseIDEScopes}
    property Scope: TIDECommandScope read FScope write FScope;
    {$ELSE}
    property Areas: TCommandAreas read FAreas;
    {$ENDIF}
  end;
  
  
  { TIDECommandKeys }
  { class for storing the keys of a single command
    (shortcut-command relationship) }
  TIDECommandKeys = class
  private
    FCategory: TIDECommandCategory;
    FCommand: word;
    FLocalizedName: string;
    FName: String;
  protected
    function GetLocalizedName: string; virtual;
    procedure SetLocalizedName(const AValue: string); virtual;
    procedure SetCategory(const AValue: TIDECommandCategory); virtual;
  public
    function AsShortCut: TShortCut; virtual;
    constructor Create(TheCategory: TIDECommandCategory; const TheName: String;
      TheCommand: word; const TheKeyA, TheKeyB: TIDEShortCut);
  public
    KeyA: TIDEShortCut;
    KeyB: TIDEShortCut;
    DefaultKeyA: TIDEShortCut;
    DefaultKeyB: TIDEShortCut;
    procedure ClearKeyA;
    procedure ClearKeyB;
    function GetCategoryAndName: string;
    property Name: String read FName;
    property Command: word read FCommand;  // see the ecXXX constants above
    property LocalizedName: string read GetLocalizedName write SetLocalizedName;
    property Category: TIDECommandCategory read FCategory write SetCategory;
  end;

const
  CleanIDEShortCut: TIDEShortCut =
    (Key1: VK_UNKNOWN; Shift1: []; Key2: VK_UNKNOWN; Shift2: []);

function IDEShortCut(Key1: word; Shift1: TShiftState;
  Key2: word; Shift2: TShiftState): TIDEShortCut;


type
  TExecuteIDEShortCut = procedure(Sender: TObject;
                                  var Key: word; Shift: TShiftState;
                                  {$IFDEF UseIDEScopes}
                                  IDEWindow: TCustomForm
                                  {$ELSE}
                                  Areas: TCommandAreas
                                  {$ENDIF}) of object;
  TExecuteIDECommand = procedure(Sender: TObject; Command: word) of object;

var
  OnExecuteIDEShortCut: TExecuteIDEShortCut;
  OnExecuteIDECommand: TExecuteIDECommand;

procedure ExecuteIDEShortCut(Sender: TObject; var Key: word; Shift: TShiftState;
  {$IFDEF UseIDEScopes}IDEWindow: TCustomForm{$ELSE}Areas: TCommandAreas{$ENDIF});
procedure ExecuteIDEShortCut(Sender: TObject; var Key: word; Shift: TShiftState);
procedure ExecuteIDECommand(Sender: TObject; Command: word);

function IDEShortCutToMenuShortCut(const IDEShortCut: TIDEShortCut): TShortCut;


var
  // will be set by the IDE
  IDECommandScopes: TIDECommandScopes = nil;
var
  IDECmdScopeSrcEdit: TIDECommandScope;
  IDECmdScopeDesigner: TIDECommandScope;

procedure CreateStandardIDECommandScopes;
function RegisterIDECommandScope(const Name: string): TIDECommandScope;


implementation


function IDEShortCut(Key1: word; Shift1: TShiftState;
  Key2: word; Shift2: TShiftState): TIDEShortCut;
begin
  Result.Key1:=Key1;
  Result.Shift1:=Shift1;
  Result.Key2:=Key2;
  Result.Shift2:=Shift2;
end;

procedure ExecuteIDEShortCut(Sender: TObject; var Key: word; Shift: TShiftState;
  {$IFDEF UseIDEScopes}IDEWindow: TCustomForm{$ELSE}Areas: TCommandAreas{$ENDIF});
begin
  if (OnExecuteIDECommand<>nil) and (Key<>VK_UNKNOWN) then
    OnExecuteIDEShortCut(Sender,Key,Shift,
                         {$IFDEF UseIDEScopes}IDEWindow{$ELSE}Areas{$ENDIF});
end;

procedure ExecuteIDEShortCut(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  OnExecuteIDEShortCut(Sender,Key,Shift,caMenuOnly);
end;

procedure ExecuteIDECommand(Sender: TObject; Command: word);
begin
  if (OnExecuteIDECommand<>nil) and (Command<>0) then
    OnExecuteIDECommand(Sender,Command);
end;

function IDEShortCutToMenuShortCut(const IDEShortCut: TIDEShortCut): TShortCut;
begin
  if IDEShortCut.Key2=VK_UNKNOWN then
    Result:=ShortCut(IDEShortCut.Key1,IDEShortCut.Shift1)
  else
    Result:=ShortCut(VK_UNKNOWN,[]);
end;

procedure CreateStandardIDECommandScopes;
begin
  IDECommandScopes:=TIDECommandScopes.Create;
  IDECmdScopeSrcEdit:=RegisterIDECommandScope('SourceEditor');
  IDECmdScopeDesigner:=RegisterIDECommandScope('Designer');
end;

function RegisterIDECommandScope(const Name: string): TIDECommandScope;
begin
  Result:=TIDECommandScope.Create;
  IDECommandScopes.Add(Result);
end;

{ TIDECommandKeys }

function TIDECommandKeys.GetLocalizedName: string;
begin
  if FLocalizedName<>'' then
    Result:=FLocalizedName
  else
    Result:=Name;
end;

procedure TIDECommandKeys.SetLocalizedName(const AValue: string);
begin
  if FLocalizedName=AValue then exit;
  FLocalizedName:=AValue;
end;

procedure TIDECommandKeys.SetCategory(const AValue: TIDECommandCategory);
begin
  if FCategory=AValue then exit;
  // unbind
  if Category<>nil then
    Category.Remove(Self);
  // bind
  fCategory:=AValue;
  if Category<>nil then
    Category.Add(Self);
end;

function TIDECommandKeys.AsShortCut: TShortCut;
var
  CurKey: TIDEShortCut;
begin
  if (KeyA.Key1<>VK_UNKNOWN) and (KeyA.Key2=VK_UNKNOWN) then
    CurKey:=KeyA
  else if (KeyB.Key1<>VK_UNKNOWN) and (KeyB.Key2=VK_UNKNOWN) then
    CurKey:=KeyB
  else
    CurKey:=CleanIDEShortCut;
  Result:=CurKey.Key1;
  if ssCtrl in CurKey.Shift1 then
    Result:=Result+scCtrl;
  if ssShift in CurKey.Shift1 then
    Result:=Result+scShift;
  if ssAlt in CurKey.Shift1 then
    Result:=Result+scAlt;
end;

constructor TIDECommandKeys.Create(TheCategory: TIDECommandCategory;
  const TheName: String; TheCommand: word;
  const TheKeyA, TheKeyB: TIDEShortCut);
begin
  fCommand:=TheCommand;
  fName:=TheName;
  KeyA:=TheKeyA;
  KeyB:=TheKeyB;
  DefaultKeyA:=KeyA;
  DefaultKeyB:=KeyB;
  Category:=TheCategory;
end;

procedure TIDECommandKeys.ClearKeyA;
begin
  KeyA:=CleanIDEShortCut;
end;

procedure TIDECommandKeys.ClearKeyB;
begin
  KeyB:=CleanIDEShortCut;
end;

function TIDECommandKeys.GetCategoryAndName: string;
begin
  Result:='"'+GetLocalizedName+'"';
  if Category<>nil then
    Result:=Result+' in "'+Category.Description+'"';
end;

{ TIDECommandScopes }

function TIDECommandScopes.GetItems(Index: integer): TIDECommandScope;
begin
  Result:=TIDECommandScope(FItems[Index]);
end;

constructor TIDECommandScopes.Create;
begin
  FItems:=TFPList.Create;
end;

destructor TIDECommandScopes.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TIDECommandScopes.Clear;
var
  i: Integer;
begin
  for i:=0 to FItems.Count-1 do Items[i].Free;
  FItems.Clear;
end;

procedure TIDECommandScopes.Add(NewItem: TIDECommandScope);
begin
  NewItem.fName:=CreateUniqueName(NewItem.Name);
  FItems.Add(NewItem);
end;

function TIDECommandScopes.IndexOf(AnItem: TIDECommandScope): Integer;
begin
  Result:=FItems.IndexOf(AnItem);
end;

function TIDECommandScopes.IndexByName(const AName: string): Integer;
begin
  Result:=Count-1;
  while (Result>=0) and (CompareText(AName,Items[Result].Name)<>0) do
    dec(Result);
end;

function TIDECommandScopes.FindByName(const AName: string): TIDECommandScope;
var
  i: LongInt;
begin
  i:=IndexByName(AName);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

function TIDECommandScopes.CreateUniqueName(const AName: string): string;
begin
  Result:=AName;
  if IndexByName(Result)<0 then exit;
  Result:=CreateFirstIdentifier(Result);
  while IndexByName(Result)>=0 do
    Result:=CreateNextIdentifier(Result);
end;

function TIDECommandScopes.Count: integer;
begin
  Result:=FItems.Count;
end;

{ TIDECommandCategory }

procedure TIDECommandCategory.Delete(Index: Integer);
begin
  inherited Delete(Index);
end;

{ TIDECommandScope }

function TIDECommandScope.GetIDEWindows(Index: integer): TCustomForm;
begin
  Result:=TCustomForm(FIDEWindows[Index]);
end;

function TIDECommandScope.GetCommands(Index: integer): TIDECommandKeys;
begin
  Result:=TIDECommandKeys(FCommands[Index]);
end;

constructor TIDECommandScope.Create;
begin
  FIDEWindows:=TFPList.Create;
  FCommands:=TFPList.Create;
end;

destructor TIDECommandScope.Destroy;
begin
  FreeAndNil(FIDEWindows);
  FreeAndNil(FCommands);
  inherited Destroy;
end;

procedure TIDECommandScope.AddWindow(AnWindow: TCustomForm);
begin
  FIDEWindows.Add(AnWindow);
end;

function TIDECommandScope.IDEWindowCount: integer;
begin
  Result:=FIDEWindows.Count;
end;

procedure TIDECommandScope.AddCommand(ACommand: TIDECommandKeys);
begin
  FCommands.Add(ACommand);
end;

function TIDECommandScope.CommandCount: integer;
begin
  Result:=FCommands.Count;
end;

function TIDECommandScope.HasIDEWindow(AnWindow: TCustomForm): boolean;
var
  i: Integer;
begin
  for i:=0 to FIDEWindows.Count-1 do
    if TCustomForm(FIDEWindows[i])=AnWindow then exit(true);
  Result:=false;
end;

end.

