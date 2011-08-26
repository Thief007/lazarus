unit javalang;

{$mode objfpc}{$H+}
{$INTERFACES CORBA}

interface

uses
  Classes, SysUtils, fgl;

type

  { IJavaInterface }

  IJavaInterface = interface
    function GetIndex: Integer;
    procedure SetIndex(AValue: Integer);
    property Index: Integer read GetIndex write SetIndex;
  end;

  { TJavaObject }

  TJavaObject = class(IJavaInterface)
  public
    FIndex: Integer;
    constructor Create(AIndex: Integer); virtual; overload;
    constructor Create(); virtual; overload;
    function GetIndex: Integer;
    procedure SetIndex(AValue: Integer);
    property Index: Integer read GetIndex write SetIndex;
  end;

  TCharSequence = class(TJavaObject)
  public
  end;

  { TString }

  TString = class(TCharSequence)
  public
    constructor Create(AStr: string);
  end;

  TJavaObjectList = specialize TFPGList<TJavaObject>;

function FindIndexInList(AList: TJavaObjectList; AIndex: Integer): TJavaObject;

implementation

uses androidpipescomm;

const
  amkJavaLang_New_String = $0000;

function FindIndexInList(AList: TJavaObjectList; AIndex: Integer): TJavaObject;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to AList.Count - 1 do
  begin
    if AList.Items[i].Index = AIndex then Exit(AList.Items[i]);
  end;
end;

{ TJavaObject }

constructor TJavaObject.Create(AIndex: Integer);
begin
  Index := AIndex;
end;

// For global objects which have no Index
constructor TJavaObject.Create;
begin
  inherited Create;
end;

function TJavaObject.GetIndex: Integer;
begin
  Result := FIndex;
end;

procedure TJavaObject.SetIndex(AValue: Integer);
begin
  FIndex := AValue;
end;

{ TString }

constructor TString.Create(AStr: string);
begin
  vAndroidPipesComm.SendByte(ShortInt(amkJavaLangCall));
  vAndroidPipesComm.SendInt(amkJavaLang_New_String);
  vAndroidPipesComm.SendString(AStr);
  Index := vAndroidPipesComm.WaitForIntReturn();
end;

end.

