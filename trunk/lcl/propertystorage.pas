{  $Id$  }
{
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
unit PropertyStorage;

{$mode objfpc}{$H+}

interface

{$IFDEF VER1_9_5}
  {$DEFINE EnableSessionProps}
{$ENDIF}

{$IFNDEF VER1_0}
uses
  Classes, SysUtils, RTLConst
  {$IFDEF EnableSessionProps}, RTTIUtils{$ENDIF};

Type
  TPlacementOperation = (poSave, poRestore);
  TCustomPropertyStorage = Class;
  TStoredValue = Class;
  TStoredValues = Class;

  { TStoredValue }

{$ifdef storevariant}
  TStoredType = Variant;
{$else}
  TStoredType = AnsiString;
{$endif}

  TStoredValueEvent = procedure(Sender: TStoredValue;
                                var Value: TStoredType) of object;

  TStoredValue = class(TCollectionItem)
  private
    FName: string;
    FValue: TStoredType;
    FKeyString: string;
    FOnSave: TStoredValueEvent;
    FOnRestore: TStoredValueEvent;
    function IsValueStored: Boolean;
    function GetStoredValues: TStoredValues;
  protected
    function GetDisplayName: string; override;
    procedure SetDisplayName(const Value: string); override;
  public
    constructor Create(ACollection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear;
    procedure Save; virtual;
    procedure Restore; virtual;
    property StoredValues: TStoredValues read GetStoredValues;
  published
    property Name: string read FName write SetDisplayName;
    property Value: TStoredType read FValue write FValue stored IsValueStored;
    property KeyString: string read FKeyString write FKeyString;
    property OnSave: TStoredValueEvent read FOnSave write FOnSave;
    property OnRestore: TStoredValueEvent read FOnRestore write FOnRestore;
  end;


  { TStoredValues }

  TStoredValues = class(TOwnedCollection)
  private
    FStorage: TCustomPropertyStorage;
    function GetValue(const AName: string): TStoredValue;
    procedure SetValue(const AName: string; StoredValue: TStoredValue);
    function GetStoredValue(const AName: string): TStoredType;
    procedure SetStoredValue(const AName: string; Value: TStoredType);
    function GetItem(Index: Integer): TStoredValue;
    procedure SetItem(Index: Integer; StoredValue: TStoredValue);
  public
    constructor Create(AOwner: TPersistent);
    function IndexOf(const AName: string): Integer;
    procedure SaveValues; virtual;
    procedure RestoreValues; virtual;
    property Storage: TCustomPropertyStorage read FStorage write FStorage;
    property Items[Index: Integer]: TStoredValue read GetItem write SetItem; default;
    property Values[const Name: string]: TStoredValue read GetValue write SetValue;
    property StoredValue[const Name: string]: TStoredType read GetStoredValue write SetStoredValue;
  end;


  { TCustomPropertyStorage }

  TPropertyStorageLink = class(TPersistent)
  private
    FStorage: TCustomPropertyStorage;
    FOnSave: TNotifyEvent;
    FOnLoad: TNotifyEvent;
    function GetRootSection: string;
    procedure SetStorage(Value: TCustomPropertyStorage);
  protected
    procedure SaveProperties; virtual;
    procedure LoadProperties; virtual;
  public
    destructor Destroy; override;
    property Storage: TCustomPropertyStorage read FStorage write SetStorage;
    property RootSection: string read GetRootSection;
    property OnSave: TNotifyEvent read FOnSave write FOnSave;
    property OnLoad: TNotifyEvent read FOnLoad write FOnLoad;
  end;

  TCustomPropertyStorage = Class (TComponent)
  private
    FStoredValues: TStoredValues;
    FActive: Boolean;
    FLinks: TList;
    FSaved: Boolean;
    FRestored: Boolean;
    FOnSaveProperties: TNotifyEvent;
    FOnRestoreProperties: TNotifyEvent;
    procedure AddLink(ALink: TPropertyStorageLink);
    procedure RemoveLink(ALink: TPropertyStorageLink);
    procedure NotifyLinks(Operation: TPlacementOperation);
    procedure SetStoredValues(Value: TStoredValues);
    function  GetStoredValue(const AName: string): TStoredType;
    procedure SetStoredValue(const AName: string; Value: TStoredType);
  protected
    function GetRoot: TComponent; virtual;
    procedure StorageNeeded(ReadOnly: Boolean);Virtual;
    procedure FreeStorage; Virtual;
    Function  RootSection: String; Virtual;
    procedure SaveProperties; virtual;
    procedure RestoreProperties; virtual;
    Procedure GetPropertyList(List: TStrings); virtual; abstract;
    procedure FinishPropertyList(List: TStrings); virtual;
    function  DoReadInteger(const Section, Ident : String; Default: Integer): Integer; Virtual;
    function  DoReadString(const Section, Ident, Default: string): string; Virtual; Abstract;
    procedure DoWriteString(const Section, Ident, Value: string); Virtual; Abstract;
    procedure DoWriteInteger(const Section, Ident : String; Value: Integer); Virtual;
    Procedure DoEraseSections(const ARootSection : String);virtual;abstract;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Save; virtual;
    procedure Restore; virtual;
    // Public Read/Write methods
    Function  ReadString(const Ident, Default: string): string;
    Function  ReadInteger(const Ident: string; Default: Longint): Longint;
    procedure WriteString(const Ident, Value: string);
    procedure WriteInteger(const Ident: string; Value: Longint);
    procedure EraseSections;
  public
    property StoredValue[const AName: string]: TStoredType read GetStoredValue write SetStoredValue;
    property Root: TComponent read GetRoot;
    property Active: Boolean read FActive write FActive default True;
    property StoredValues: TStoredValues read FStoredValues write SetStoredValues;
    property OnSaveProperties : TNotifyEvent read FOnSaveProperties write FOnSaveProperties;
    property OnRestoreProperties : TNotifyEvent read FOnRestoreProperties  write FOnRestoreProperties;
  end;
  
{$ENDIF not VER1_0}
implementation

{$IFNDEF VER1_0}
function XorEncode(const Key, Source: string): string;
var
  I: Integer;
  C: Byte;
begin
  Result := '';
  for I := 1 to Length(Source) do begin
    if Length(Key) > 0 then
      C := Byte(Key[1 + ((I - 1) mod Length(Key))]) xor Byte(Source[I])
    else
      C := Byte(Source[I]);
    Result := Result + AnsiLowerCase(IntToHex(C, 2));
  end;
end;

function XorDecode(const Key, Source: string): string;
var
  I: Integer;
  C: Char;

begin
  Result := '';
  for I := 0 to Length(Source) div 2 - 1 do begin
    C := Chr(StrToIntDef('$' + Copy(Source, (I * 2) + 1, 2), Ord(' ')));
    if Length(Key) > 0 then
      C := Chr(Byte(Key[1 + (I mod Length(Key))]) xor Byte(C));
    Result := Result + C;
  end;
end;


{ TPropertyStorageLink }

destructor TPropertyStorageLink.Destroy;
begin
  FOnSave := nil;
  FOnLoad := nil;
  SetStorage(nil);
  inherited Destroy;
end;

function TPropertyStorageLink.GetRootSection: string;
begin
  if Assigned(FStorage) then
    Result:=FStorage.RootSection
  else
    Result:='';
  if Result<>'' then
    Result:=Result+'\';
end;

procedure TPropertyStorageLink.SetStorage(Value: TCustomPropertyStorage);
begin
  if FStorage <> Value then
    begin
    if FStorage <> nil then
      FStorage.RemoveLink(Self);
    if Value <> nil then
      Value.AddLink(Self);
    end;
end;

procedure TPropertyStorageLink.SaveProperties;
begin
  if Assigned(FOnSave) then
    FOnSave(Self);
end;

procedure TPropertyStorageLink.LoadProperties;
begin
  if Assigned(FOnLoad) then
    FOnLoad(Self);
end;

{ TStoredValue }

constructor TStoredValue.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
{$ifdef storevariant}
  FValue := Unassigned;
{$else}
  FValue:='';
{$endif}
end;

procedure TStoredValue.Assign(Source: TPersistent);
begin
  if (Source is TStoredValue) and (Source <> nil) then
    begin
{$ifdef storevariant}
    if VarIsEmpty(TStoredValue(Source).FValue) then
      Clear
    else
{$endif}
      Value := TStoredValue(Source).FValue;
    Name := TStoredValue(Source).Name;
    KeyString := TStoredValue(Source).KeyString;
    end;
end;

function TStoredValue.GetDisplayName: string;
begin
  if FName = '' then
    Result := inherited GetDisplayName
  else
    Result := FName;
end;

procedure TStoredValue.SetDisplayName(const Value: string);
begin
  if (Value <> '') and (AnsiCompareText(Value, FName) <> 0)
  and (Collection is TStoredValues)
  and (TStoredValues(Collection).IndexOf(Value) >= 0) then
    raise Exception.Create(SDuplicateString);
  FName := Value;
  inherited;
end;

function TStoredValue.GetStoredValues: TStoredValues;
begin
  if Collection is TStoredValues then
    Result := TStoredValues(Collection)
  else
    Result := nil;
end;

procedure TStoredValue.Clear;
begin
{$ifdef storevariant}
  FValue := Unassigned;
{$else}
  FValue := '';
{$endif}
end;

function TStoredValue.IsValueStored: Boolean;
begin
{$ifdef storevariant}
  Result := not VarIsEmpty(FValue);
{$else}
  Result := (FValue<>'');
{$endif}
end;

procedure TStoredValue.Save;
var
  SaveValue: TStoredType;
  SaveStrValue: string;
begin
  SaveValue := Value;
  if Assigned(FOnSave) then
    FOnSave(Self, SaveValue);
{$ifdef storevariant}
  SaveStrValue := VarToStr(SaveValue);
{$else}
  SaveStrValue := SaveValue;
{$endif}
  if KeyString <> '' then
    SaveStrValue := XorEncode(KeyString, SaveStrValue);
  StoredValues.Storage.WriteString(Name, SaveStrValue);
end;

procedure TStoredValue.Restore;
var
  RestoreValue: TStoredType;
  RestoreStrValue, DefaultStrValue: string;
begin
{$ifdef storevariant}
  DefaultStrValue := VarToStr(Value);
{$else}
  DefaultStrValue := Value;
{$endif}
  if KeyString <> '' then
    DefaultStrValue := XorEncode(KeyString, DefaultStrValue);
  RestoreStrValue := StoredValues.Storage.ReadString(Name, DefaultStrValue);
  if KeyString <> '' then
    RestoreStrValue := XorDecode(KeyString, RestoreStrValue);
  RestoreValue := RestoreStrValue;
  if Assigned(FOnRestore) then
    FOnRestore(Self, RestoreValue);
  Value := RestoreValue;
end;

{ TStoredValues }

constructor TStoredValues.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TStoredValue);
  If AOwner is TCustomPropertyStorage then
    FStorage:=TCustomPropertyStorage(AOwner);
end;

function TStoredValues.IndexOf(const AName: string): Integer;
begin
  for Result := 0 to Count - 1 do
    if AnsiCompareText(Items[Result].Name, AName) = 0 then Exit;
  Result := -1;
end;

function TStoredValues.GetItem(Index: Integer): TStoredValue;
begin
  Result := TStoredValue(inherited Items[Index]);
end;

procedure TStoredValues.SetItem(Index: Integer; StoredValue: TStoredValue);
begin
  inherited SetItem(Index, TCollectionItem(StoredValue));
end;

function TStoredValues.GetStoredValue(const AName: string): TStoredType;
var
  AStoredValue: TStoredValue;
begin
  AStoredValue := GetValue(AName);
  if AStoredValue = nil then
{$ifdef storevariant}
    Result := Null
{$else}
    Result := ''
{$endif}
  else
    Result := AStoredValue.Value;
end;

procedure TStoredValues.SetStoredValue(const AName: string; Value: TStoredType);
var
  AStoredValue: TStoredValue;
begin
  AStoredValue := GetValue(AName);
  if AStoredValue = nil then begin
    AStoredValue := TStoredValue(Add);
    AStoredValue.Name := AName;
    AStoredValue.Value := Value;
  end
  else AStoredValue.Value := Value;
end;

function TStoredValues.GetValue(const AName: string): TStoredValue;
var
  I: Integer;
begin
  I := IndexOf(AName);
  if I < 0 then
    Result := nil
  else
    Result := Items[I];
end;

procedure TStoredValues.SetValue(const AName: string; StoredValue: TStoredValue);
var
  I: Integer;
begin
  I := IndexOf(AName);
  if I >= 0 then
    Items[I].Assign(StoredValue);
end;

procedure TStoredValues.SaveValues;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].Save;
end;

procedure TStoredValues.RestoreValues;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].Restore;
end;

{ TCustomPropertyStorage }

constructor TCustomPropertyStorage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := True;
  FLinks := TList.Create;
  FStoredValues:=TStoredValues.Create(Self);
  FStoredValues.Storage:=Self;
end;

destructor TCustomPropertyStorage.Destroy;
begin
  FreeStorage;
  FStoredValues.Free;
  while FLinks.Count > 0 do
    RemoveLink(TPropertyStorageLink(FLinks.Last));
  FreeAndNil(FLinks);
  inherited Destroy;
end;

procedure TCustomPropertyStorage.AddLink(ALink: TPropertyStorageLink);
begin
  FLinks.Add(ALink);
  ALink.FStorage := Self;
end;

procedure TCustomPropertyStorage.NotifyLinks(Operation: TPlacementOperation);
var
  I: Integer;
begin
  for I := 0 to FLinks.Count - 1 do
    with TPropertyStorageLink(FLinks[I]) do
      case Operation of
        poSave: SaveProperties;
        poRestore: LoadProperties;
      end;
end;

procedure TCustomPropertyStorage.RemoveLink(ALink: TPropertyStorageLink);
begin
  ALink.FStorage := nil;
  FLinks.Remove(ALink);
end;

function TCustomPropertyStorage.GetRoot: TComponent;
begin
  Result:=Owner;
end;

function TCustomPropertyStorage.RootSection : string;

var
  ARoot: TPersistent;
  Prepend: String;
  
begin
  Result:='';
  ARoot:=Root;
  while ARoot<>nil do begin
    if (ARoot is TComponent) and (TComponent(ARoot).Name<>'') then
      Prepend:=TComponent(ARoot).Name
    else begin
      Prepend:=ARoot.ClassName;
      ARoot:=nil;
    end;
    if Result<>'' then
      Result:=Prepend+'.'+Result
    else
      Result:=Prepend;
    if not (ARoot is TComponent) then break;
    ARoot:=TComponent(ARoot).Owner;
  end;
end;


procedure TCustomPropertyStorage.Save;
begin
  if FRestored or not Active then
    begin
    StorageNeeded(False);
    Try
      SaveProperties;
      FStoredValues.SaveVAlues;
      NotifyLinks(poSave);
      if Assigned(FOnSaveProperties) then
        FOnSaveProperties(Self);
      FSaved := True;
    Finally
      FreeStorage;
    end;
    end;
end;

procedure TCustomPropertyStorage.Restore;
begin
  if Active then begin
    FSaved := False;
    StorageNeeded(True);
    FStoredValues.RestoreValues;
    RestoreProperties;
    NotifyLinks(poRestore);
    FRestored:=True;
    if Assigned(FOnRestoreProperties) then
      FOnRestoreProperties(Self);
  end;
end;

procedure TCustomPropertyStorage.SaveProperties;

Var
  AStoredList : TStringList;
begin
  AStoredList:=TStringList.Create;
  Try
    GetPropertyList(AStoredList);
    FinishPropertyList(AStoredList);
    StorageNeeded(False);
    Try
      {$IFDEF EnableSessionProps}
      with TPropsStorage.Create do
        try
          Section := RootSection;
          OnWriteString := @DoWriteString;
          try
            StoreObjectsProps(Owner,AStoredList);
          except
            { ignore any exceptions }
            // even unable to write file?
            // not even giving the user a small hint?
          end;
        finally
          Free;
        end;
      {$ENDIF}
    Finally
      FreeStorage;
    end;
  finally
    AStoredList.Free;
  end;
end;

procedure TCustomPropertyStorage.RestoreProperties;

Var
  L : TStringList;

begin
  L:=TStringList.Create;
  Try
    GetPropertyList(L);
    FinishPropertyList(L);
    StorageNeeded(True);
    Try
      {$IFDEF EnableSessionProps}
      with TPropsStorage.Create do
        try
          Section := RootSection;
          OnReadString := @DoReadString;
          try
            LoadObjectsProps(Owner,L);
          except
            { ignore any exceptions }
          end;
        finally
          Free;
        end;
      {$ENDIF}
    Finally
      FreeStorage;
    end;
  finally
    L.Free;
  end;
end;

procedure TCustomPropertyStorage.FinishPropertyList(List: TStrings);
{$IFDEF EnableSessionProps}
var
  i: Integer;
  CompName: string;
  PropName: string;
  ARoot: TComponent;
  AComponent: TComponent;
{$ENDIF}
begin
  {$IFDEF EnableSessionProps}
  // set Objects (i.e. the component of each property)
  ARoot:=Root;
  for i:=List.Count-1 downto 0 do begin
    if ParseStoredItem(List[I], CompName, PropName) then begin
      if CompareText(ARoot.Name,CompName)=0 then
        List.Objects[i]:=ARoot
      else begin
        AComponent:=Root.FindComponent(CompName);
        if AComponent<>nil then
          List.Objects[i]:=AComponent
        else
          List.Delete(i);
      end;
    end else begin
      List.Delete(i);
    end;
  end;
  {$ENDIF}
end;

function TCustomPropertyStorage.DoReadInteger(const Section, Ident: String;
  Default: Integer): Integer;
begin
  Result:=StrToIntDef(DoReadString(Section,Ident,IntToStr(Default)),Default);
end;

procedure TCustomPropertyStorage.DoWriteInteger(const Section, Ident: String;
  Value: Integer);
begin
  DoWriteString(Section,Ident,IntToStr(Value))
end;

procedure TCustomPropertyStorage.StorageNeeded(ReadOnly: Boolean);
begin
end;

procedure TCustomPropertyStorage.FreeStorage;
begin
end;

function TCustomPropertyStorage.ReadString(const Ident, Default: string): string;
begin
  Result := DoReadString(RootSection, Ident, Default);
end;

procedure TCustomPropertyStorage.WriteString(const Ident, Value: string);
begin
  DoWriteString(RootSection, Ident, Value);
end;

function TCustomPropertyStorage.ReadInteger(const Ident: string; Default: Longint): Longint;
begin
  StorageNeeded(True);
  try
    Result := DoReadInteger(RootSection, Ident, Default);
  finally
    FreeStorage;
  end;
end;

procedure TCustomPropertyStorage.WriteInteger(const Ident: string; Value: Longint);
begin
  StorageNeeded(False);
  try
    DoReadInteger(RootSection, Ident, Value);
  finally
    FreeStorage;
  end;
end;


procedure TCustomPropertyStorage.EraseSections;

begin
  StorageNeeded(False);
  try
    DoEraseSections(RootSection);
  finally
    FreeStorage;
  end;
end;

procedure TCustomPropertyStorage.SetStoredValues(Value: TStoredValues);
begin
  FStoredValues.Assign(Value);
end;

function TCustomPropertyStorage.GetStoredValue(const AName: string): TStoredType;
begin
  Result := StoredValues.StoredValue[AName];
end;

procedure TCustomPropertyStorage.SetStoredValue(const AName: string; Value: TStoredType);
begin
  StoredValues.StoredValue[AName] := Value;
end;

{$ENDIF not VER1_0}

end.

