unit FpGdbmiDebugger;

{$mode objfpc}{$H+}

interface

uses
  Classes, sysutils, math, FpDbgClasses, GDBMIDebugger, BaseDebugManager, Debugger,
  GDBMIMiscClasses, GDBTypeInfo, maps, LCLProc, FpDbgLoader, FpDbgDwarf, FpDbgDwarfConst,
  LazLoggerBase, LazLoggerProfiling;

type

  TFpGDBMIExpressionPart = class;
  TFpGDBMIExpressionPartClass = class of TFpGDBMIExpressionPart;

  { TFpGDBMIExpression }

  TFpGDBMIExpression = class
  private
    FError: String;
    FTextExpression: String;
    FExpressionPart: TFpGDBMIExpressionPart;
    FValid: Boolean;
    procedure Parse;
    procedure SetError(AMsg: String);
    function PosFromPChar(APChar: PChar): Integer;
  protected
    property ExpressionPart: TFpGDBMIExpressionPart read FExpressionPart;
  public
    constructor Create(ATextExpression: String);
    destructor Destroy; override;
    function DebugDump: String;
    property Error: String read FError;
    property Valid: Boolean read FValid;
  end;

  TFpGDBMIExpressionPartContainer = class;
  TFpGDBMIExpressionPartBracket = class;
  { TFpGDBMIExpressionPart }

  TFpGDBMIExpressionPart = class
  private
    FEndChar: PChar;
    FParent: TFpGDBMIExpressionPartContainer;
    FStartChar: PChar;
    FExpression: TFpGDBMIExpression;
    function GetSurroundingBracket: TFpGDBMIExpressionPartBracket;
    function GetTopParent: TFpGDBMIExpressionPart;
    procedure SetEndChar(AValue: PChar);
    procedure SetParent(AValue: TFpGDBMIExpressionPartContainer);
    procedure SetStartChar(AValue: PChar);
    function  GetText(AMaxLen: Integer=0): String;
    procedure SetError(AMsg: String = '');
    procedure SetError(APart: TFpGDBMIExpressionPart; AMsg: String = '');
  protected
    function DebugText(AIndent: String): String; virtual; // Self desc only
    function DebugDump(AIndent: String): String; virtual;
  protected
    procedure Init; virtual;
    Procedure ReplaceInParent(AReplacement: TFpGDBMIExpressionPart);
    procedure DoHandleEndOfExpression; virtual;

    function IsValidNextPart(APart: TFpGDBMIExpressionPart): Boolean; virtual;
    function CanHaveBinaryOperatorAsNext: Boolean; virtual; // True
  public
    constructor Create(AExpression: TFpGDBMIExpression; AStartChar: PChar; AnEndChar: PChar = nil);
    function  HandleNextPart(APart: TFpGDBMIExpressionPart): TFpGDBMIExpressionPart; virtual;
    procedure HandleEndOfExpression; virtual;
    property StartChar: PChar read FStartChar write SetStartChar;
    property EndChar: PChar read FEndChar write SetEndChar;
    property Parent: TFpGDBMIExpressionPartContainer read FParent write SetParent;
    property TopParent: TFpGDBMIExpressionPart read GetTopParent; // or self
    property SurroundingBracket: TFpGDBMIExpressionPartBracket read GetSurroundingBracket; // incl self
  end;

  { TFpGDBMIExpressionPartContainer }

  TFpGDBMIExpressionPartContainer = class(TFpGDBMIExpressionPart)
  private
    FList: TList;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TFpGDBMIExpressionPart;
    function GetLastItem: TFpGDBMIExpressionPart;
    procedure SetItems(AIndex: Integer; AValue: TFpGDBMIExpressionPart);
    procedure SetLastItem(AValue: TFpGDBMIExpressionPart);
  protected
    procedure Init; override;
    function DebugDump(AIndent: String): String; override;
  public
    destructor Destroy; override;
    function Add(APart: TFpGDBMIExpressionPart): Integer;
    function IndexOf(APart: TFpGDBMIExpressionPart): Integer;
    procedure Clear;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TFpGDBMIExpressionPart read GetItems write SetItems;
    property LastItem: TFpGDBMIExpressionPart read GetLastItem write SetLastItem;
  end;

  { TFpGDBMIExpressionPartIdentifer }

  TFpGDBMIExpressionPartIdentifer = class(TFpGDBMIExpressionPartContainer)
  // may >contain< "()" or "[]"
  public
  end;

  TFpGDBMIExpressionPartBracket = class(TFpGDBMIExpressionPartContainer)
  end;

  { TFpGDBMIExpressionPartRoundBracket }

  TFpGDBMIExpressionPartRoundBracket = class(TFpGDBMIExpressionPartBracket)
  private
    FIsClosed: boolean;
    FIsClosing: boolean;
  protected
    procedure Init; override;
    procedure DoHandleEndOfExpression; override;
    function CanHaveBinaryOperatorAsNext: Boolean; override;
  public
    procedure CloseBracket;
    function HandleNextPart(APart: TFpGDBMIExpressionPart): TFpGDBMIExpressionPart; override;
    procedure HandleEndOfExpression; override;
    property IsClosed: boolean read FIsClosed;
  end;

  { TFpGDBMIExpressionPartOperator }

  TFpGDBMIExpressionPartOperator = class(TFpGDBMIExpressionPartContainer)
  private
    FIsUnary: Boolean;
    FPrecedence: Integer;
  protected
    function DebugText(AIndent: String): String; override;
    function CanHaveBinaryOperatorAsNext: Boolean; override;
    procedure DoHandleEndOfExpression; override;
  public
    function HandleNextPart(APart: TFpGDBMIExpressionPart): TFpGDBMIExpressionPart; override;
    function HandlePrevPart(APart: TFpGDBMIExpressionPart): TFpGDBMIExpressionPart; virtual;
    property IsUnary: Boolean read FIsUnary;
    property Precedence: Integer read FPrecedence;
  end;

  { TFpGDBMIExpressionPartUnaryOperator }

  TFpGDBMIExpressionPartUnaryOperator = class(TFpGDBMIExpressionPartOperator)
  protected
    procedure Init; override;
  public
  end;

  { TFpGDBMIExpressionPartBinaryOperator }

  TFpGDBMIExpressionPartBinaryOperator = class(TFpGDBMIExpressionPartOperator)
  protected
    procedure Init; override;
  public
  end;

  { TFpGDBMIExpressionPartOperatorAddressOf }

  TFpGDBMIExpressionPartOperatorAddressOf = class(TFpGDBMIExpressionPartUnaryOperator)  // @
  protected
    procedure Init; override;
  end;

  { TFpGDBMIExpressionPartOperatorUnaryPlusMinus }

  TFpGDBMIExpressionPartOperatorUnaryPlusMinus = class(TFpGDBMIExpressionPartUnaryOperator)  // + -
  // Unary + -
  protected
    procedure Init; override;
  end;

  { TFpGDBMIExpressionPartOperatorPlusMinus }

  TFpGDBMIExpressionPartOperatorPlusMinus = class(TFpGDBMIExpressionPartBinaryOperator)  // + -
  // Binary + -
  protected
    procedure Init; override;
  end;

  { TFpGDBMIExpressionPartOperatorMulDiv }

  TFpGDBMIExpressionPartOperatorMulDiv = class(TFpGDBMIExpressionPartBinaryOperator)    // * /
  protected
    procedure Init; override;
  end;

  TFpGDBMIDebugger = class;

  { TFpGDBPTypeRequestCache }

  TFpGDBPTypeRequestCache = class(TGDBPTypeRequestCache)
  private
    FDebugger: TFpGDBMIDebugger;
    FInIndexOf: Boolean;
  public
    constructor Create(ADebugger: TFpGDBMIDebugger);
    function IndexOf(AThreadId, AStackFrame: Integer; ARequest: TGDBPTypeRequest): Integer; override;
    property Debugger: TFpGDBMIDebugger read FDebugger;
  end;

  { TFpGDBMIDebugger }

  TFpGDBMIDebugger = class(TGDBMIDebugger)
  private
    FImageLoader: TDbgImageLoader;
    FDwarfInfo: TDbgDwarf;
  protected
    function CreateCommandStartDebugging(AContinueCommand: TGDBMIDebuggerCommand): TGDBMIDebuggerCommandStartDebugging; override;
    function CreateLineInfo: TDBGLineInfo; override;
    function  CreateWatches: TWatchesSupplier; override;
    procedure DoState(const OldState: TDBGState); override;
    function  HasDwarf: Boolean;
    procedure LoadDwarf;
    procedure UnLoadDwarf;
    function  RequestCommand(const ACommand: TDBGCommand; const AParams: array of const): Boolean; override;

    procedure GetCurrentContext(out AThreadId, AStackFrame: Integer);
    function  GetLocationForContext(AThreadId, AStackFrame: Integer): TDBGPtr;
    procedure AddToGDBMICache(AThreadId, AStackFrame: Integer; AnIdent: TDbgSymbol);
    function CreateTypeRequestCache: TGDBPTypeRequestCache; override;
  public
    class function Caption: String; override;
  public
    destructor Destroy; override;
  end;


implementation

type

  { TFpGDBMIDebuggerCommandStartDebugging }

  TFpGDBMIDebuggerCommandStartDebugging = class(TGDBMIDebuggerCommandStartDebugging)
  protected
    function DoExecute: Boolean; override;
  end;

  { TFPGDBMIWatches }

  TFPGDBMIWatches = class(TGDBMIWatches)
  private
  protected
    function  FpDebugger: TFpGDBMIDebugger;
    //procedure DoStateChange(const AOldState: TDBGState); override;
    procedure InternalRequestData(AWatchValue: TCurrentWatchValue); override;
  public
    //constructor Create(const ADebugger: TDebugger);
    //destructor Destroy; override;
  end;

  { TFpGDBMILineInfo }

  TFpGDBMILineInfo = class(TDBGLineInfo) //class(TGDBMILineInfo)
  private
    FRequestedSources: TStringList;
  protected
    function  FpDebugger: TFpGDBMIDebugger;
    procedure DoStateChange(const AOldState: TDBGState); override;
    procedure ClearSources;
  public
    constructor Create(const ADebugger: TDebugger);
    destructor Destroy; override;
    function Count: Integer; override;
    function GetAddress(const AIndex: Integer; const ALine: Integer): TDbgPtr; override;
    function GetInfo(AAdress: TDbgPtr; out ASource, ALine, AOffset: Integer): Boolean; override;
    function IndexOf(const ASource: String): integer; override;
    procedure Request(const ASource: String); override;
    procedure Cancel(const ASource: String); override;
  end;

{ TFpGDBMIExpressionPartRoundBracket }

procedure TFpGDBMIExpressionPartRoundBracket.Init;
begin
  inherited Init;
  FIsClosed := False;
  FIsClosing := False;
end;

procedure TFpGDBMIExpressionPartRoundBracket.DoHandleEndOfExpression;
begin
  if not IsClosed then begin
    SetError('Bracket not closed');
    exit;
  end;
  inherited DoHandleEndOfExpression;
end;

function TFpGDBMIExpressionPartRoundBracket.CanHaveBinaryOperatorAsNext: Boolean;
begin
  Result := IsClosed;
end;

procedure TFpGDBMIExpressionPartRoundBracket.CloseBracket;
begin
  FIsClosing := True;
  if LastItem <> nil then
    LastItem.HandleEndOfExpression;
  FIsClosing := False;
  FIsClosed := True;
end;

function TFpGDBMIExpressionPartRoundBracket.HandleNextPart(APart: TFpGDBMIExpressionPart): TFpGDBMIExpressionPart;
begin
  if IsClosed then begin
    Result := inherited HandleNextPart(APart);
    exit;
  end;

  Result := Self;
  if Count > 0 then begin
    SetError('To many expressions');
    exit;
  end;

  Result := APart;
  Add(APart);
end;

procedure TFpGDBMIExpressionPartRoundBracket.HandleEndOfExpression;
begin
  if not FIsClosing then
    inherited HandleEndOfExpression;
end;

{ TFpGDBMIExpressionPartOperatorUnaryPlusMinus }

procedure TFpGDBMIExpressionPartOperatorUnaryPlusMinus.Init;
begin
  FPrecedence := 1;
  inherited Init;
end;

{ TFpGDBMIExpression }

procedure TFpGDBMIExpression.Parse;
var
  CurPtr, EndPtr, TokenEndPtr: PChar;
  CurPart, NewPart: TFpGDBMIExpressionPart;

  procedure AddPart(AClass: TFpGDBMIExpressionPartClass);
  begin
    NewPart := AClass.Create(Self, CurPtr, TokenEndPtr-1);
  end;

  procedure AddPlusMinus;
  begin
    if (CurPart = nil) or (not CurPart.CanHaveBinaryOperatorAsNext)
    then
      AddPart(TFpGDBMIExpressionPartOperatorUnaryPlusMinus)
    else
      AddPart(TFpGDBMIExpressionPartOperatorPlusMinus);
  end;

  procedure AddConstChar;
  begin
  end;

  procedure AddConstNumber;
  begin
  end;

  procedure AddIdentifier;
  begin
    while TokenEndPtr^ in ['a'..'z', 'A'..'Z', '_', '0'..'9'] do
      inc(TokenEndPtr);
    // TODO: Check functions not, and, in, as, is ...
    NewPart := TFpGDBMIExpressionPartIdentifer.Create(Self, CurPtr, TokenEndPtr-1);
  end;

  procedure CloseRounBracket;
  begin
    NewPart := CurPart.SurroundingBracket;
    if NewPart = nil then begin
      SetError('Closing bracket "(" found without opening')
    end
    else
    if not (NewPart is TFpGDBMIExpressionPartRoundBracket) then begin
      SetError('Mismatch bracket')
    end
    else begin
      TFpGDBMIExpressionPartRoundBracket(NewPart).CloseBracket;
      CurPart := nil;
    end;
  end;

begin
  if FTextExpression = '' then
    exit;
  CurPtr := @FTextExpression[1];
  EndPtr := CurPtr + length(FTextExpression);
  CurPart := nil;

  While (CurPtr < EndPtr) and FValid do begin
    if CurPtr^ in [' ', #9, #10, #13] then begin
      while (CurPtr^ in [' ', #9, #10, #13]) and (CurPtr < EndPtr) do
        Inc(CurPtr);
      continue;
    end;

    NewPart := nil;
    TokenEndPtr := CurPtr + 1;
    case CurPtr^ of
      '@' :      AddPart(TFpGDBMIExpressionPartOperatorAddressOf);
      '+', '-' : AddPlusMinus;
      '*', '/' : AddPart(TFpGDBMIExpressionPartOperatorMulDiv);
      '(':       AddPart(TFpGDBMIExpressionPartRoundBracket);
      ')':       CloseRounBracket;
      //'[': ;
      //'''':     AddConstChar;
      //'0'..'9',
      //'$', '%': AddConstNumber;
      'a'..'z',
      'A'..'Z', '_': AddIdentifier;
      else begin
          SetError(Format('Unexpected char ''%0:s'' at pos %1:s', [CurPtr^, PosFromPChar(CurPtr)])); // error
          break;
        end;
    end;
    if not FValid then
      break;
    assert(NewPart <> nil);

debugln('=================================');
DebugLn('NEWPART:  '+NewPart.DebugText(''));
    if CurPart = nil
    then CurPart := NewPart
    else CurPart := CurPart.HandleNextPart(NewPart);
DebugLn('CURPART:  '+CurPart.DebugText(''));

    CurPtr :=  TokenEndPtr;
  end; // While CurPtr < EndPtr do begin



  if CurPart <> nil then begin
    CurPart.HandleEndOfExpression;
    CurPart := CurPart.TopParent;
  end
  else
  if Valid then
    SetError('No Expression');

  FExpressionPart := CurPart;
end;

procedure TFpGDBMIExpression.SetError(AMsg: String);
begin
  FValid := False;
  FError := AMsg;
end;

function TFpGDBMIExpression.PosFromPChar(APChar: PChar): Integer;
begin
  Result := APChar - @FTextExpression[1] + 1;
end;

constructor TFpGDBMIExpression.Create(ATextExpression: String);
begin
  FTextExpression := ATextExpression;
  FValid := True;
  Parse;
end;

destructor TFpGDBMIExpression.Destroy;
begin
  FreeAndNil(FExpressionPart);
  inherited Destroy;
end;

function TFpGDBMIExpression.DebugDump: String;
begin
  Result := 'TFpGDBMIExpression: ' + FTextExpression + LineEnding +
            'Valid: ' + dbgs(FValid) + '   Error: "' + FError + '"'+ LineEnding
            ;
  if FExpressionPart <> nil then
    Result := Result + FExpressionPart.DebugDump('  ');
end;

{ TFpGDBMIExpressionPartContainer }

function TFpGDBMIExpressionPartContainer.GetItems(AIndex: Integer): TFpGDBMIExpressionPart;
begin
  Result := TFpGDBMIExpressionPart(FList[AIndex]);
end;

function TFpGDBMIExpressionPartContainer.GetLastItem: TFpGDBMIExpressionPart;
begin
  if Count > 0 then
    Result := Items[Count - 1]
  else
    Result := nil;
end;

procedure TFpGDBMIExpressionPartContainer.SetItems(AIndex: Integer;
  AValue: TFpGDBMIExpressionPart);
begin
  AValue.Parent := Self;
  FList[AIndex] := AValue;
end;

procedure TFpGDBMIExpressionPartContainer.SetLastItem(AValue: TFpGDBMIExpressionPart);
begin
  assert(Count >0);
  Items[Count-1] := AValue;
end;

procedure TFpGDBMIExpressionPartContainer.Init;
begin
  FList := TList.Create;
  inherited Init;
end;

function TFpGDBMIExpressionPartContainer.DebugDump(AIndent: String): String;
var
  i: Integer;
begin
  Result := inherited DebugDump(AIndent);
  for i := 0 to Count - 1 do
    Result := Result + Items[i].DebugDump(AIndent+'  ');
end;

function TFpGDBMIExpressionPartContainer.GetCount: Integer;
begin
  Result := FList.Count;
end;

destructor TFpGDBMIExpressionPartContainer.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited Destroy;
end;

function TFpGDBMIExpressionPartContainer.Add(APart: TFpGDBMIExpressionPart): Integer;
begin
  APart.Parent := Self;
  Result := FList.Add(APart);
end;

function TFpGDBMIExpressionPartContainer.IndexOf(APart: TFpGDBMIExpressionPart): Integer;
begin
  Result := Count - 1;
  while (Result >= 0) and (Items[Result] <> APart) do
    dec(Result);
end;

procedure TFpGDBMIExpressionPartContainer.Clear;
begin
  while Count > 0 do begin
    Items[0].Free;
    FList.Delete(0);
  end;
end;

{ TFpGDBMIExpressionPart }

procedure TFpGDBMIExpressionPart.SetEndChar(AValue: PChar);
begin
  if FEndChar = AValue then Exit;
  FEndChar := AValue;
end;

function TFpGDBMIExpressionPart.GetTopParent: TFpGDBMIExpressionPart;
begin
  Result := Self;
  while Result.Parent <> nil do
    Result := Result.Parent;
end;

function TFpGDBMIExpressionPart.GetSurroundingBracket: TFpGDBMIExpressionPartBracket;
var
  tmp: TFpGDBMIExpressionPart;
begin
  Result := nil;
  tmp := Self;
  while (tmp <> nil) and not(tmp is TFpGDBMIExpressionPartBracket) do
    tmp := tmp.Parent;
  if tmp <> nil then
    Result := TFpGDBMIExpressionPartBracket(tmp);
end;

procedure TFpGDBMIExpressionPart.SetParent(AValue: TFpGDBMIExpressionPartContainer);
var
  Old: TFpGDBMIExpressionPart;
begin
  if FParent = AValue then Exit;
  Old := FParent;
  FParent := AValue;
end;

procedure TFpGDBMIExpressionPart.SetStartChar(AValue: PChar);
begin
  if FStartChar = AValue then Exit;
  FStartChar := AValue;
end;

function TFpGDBMIExpressionPart.GetText(AMaxLen: Integer): String;
var
  Len: Integer;
begin
  if FEndChar <> nil
  then Len := FEndChar - FStartChar + 1
  else Len := min(AMaxLen, 10);
  if (AMaxLen > 0) and (Len > AMaxLen) then
    Len := AMaxLen;
  Result := Copy(FStartChar, 1, Len);
end;

procedure TFpGDBMIExpressionPart.SetError(AMsg: String);
begin
  if AMsg = '' then
    AMsg := 'Invalid Expression';
  FExpression.SetError(Format('%0:s at %1:d: "%2:s"', [AMsg, FExpression.PosFromPChar(FStartChar), GetText(20)]));
end;

procedure TFpGDBMIExpressionPart.SetError(APart: TFpGDBMIExpressionPart; AMsg: String);
begin
  if APart <> nil
  then APart.SetError(AMsg)
  else Self.SetError(AMsg);
end;

procedure TFpGDBMIExpressionPart.Init;
begin
  //
end;

procedure TFpGDBMIExpressionPart.ReplaceInParent(AReplacement: TFpGDBMIExpressionPart);
var
  i: Integer;
begin
  if Parent = nil then exit;
  i := Parent.IndexOf(Self);
  Assert(i >= 0);
  Parent.Items[i] := AReplacement;
  Parent := nil;
end;

procedure TFpGDBMIExpressionPart.DoHandleEndOfExpression;
begin
  //
end;

function TFpGDBMIExpressionPart.IsValidNextPart(APart: TFpGDBMIExpressionPart): Boolean;
begin
  Result := True;
  if (APart is TFpGDBMIExpressionPartOperator) and
     (not TFpGDBMIExpressionPartOperator(APart).IsUnary)
  then
    Result := Result and CanHaveBinaryOperatorAsNext;
//TODO move
  if (Parent <> nil) and (Parent is TFpGDBMIExpressionPartOperator) and
     (not TFpGDBMIExpressionPartOperator(APart).IsUnary) and
     (APart is TFpGDBMIExpressionPartOperator)
  then
    Result := False; //Result and CanHaveBinaryOperatorAsNext;
end;

function TFpGDBMIExpressionPart.CanHaveBinaryOperatorAsNext: Boolean;
begin
  Result := True;
end;

function TFpGDBMIExpressionPart.DebugText(AIndent: String): String;
begin
  Result := Format('%s%s at %d: "%s"',
                   [AIndent, ClassName, FExpression.PosFromPChar(FStartChar), GetText])
                   + LineEnding;
end;

function TFpGDBMIExpressionPart.DebugDump(AIndent: String): String;
begin
  Result := DebugText(AIndent);
end;

constructor TFpGDBMIExpressionPart.Create(AExpression: TFpGDBMIExpression; AStartChar: PChar;
  AnEndChar: PChar);
begin
  FExpression := AExpression;
  FStartChar := AStartChar;
  FEndChar := AnEndChar;
  Init;
end;

function TFpGDBMIExpressionPart.HandleNextPart(APart: TFpGDBMIExpressionPart): TFpGDBMIExpressionPart;
begin
  if (APart is TFpGDBMIExpressionPartOperator) and IsValidNextPart(APart) then begin
    Result := TFpGDBMIExpressionPartOperator(APart).HandlePrevPart(Self);
    exit;
  end;

  if Parent <> nil then begin
    Result := Parent.HandleNextPart(APart);
    exit;
  end;

  SetError(APart, 'Unexpected ');
  APart.Free;
  Result := Self;
end;

procedure TFpGDBMIExpressionPart.HandleEndOfExpression;
begin
  DoHandleEndOfExpression;
  if Parent <> nil then
    Parent.HandleEndOfExpression;
end;

{ TFpGDBMIExpressionPartOperator }

function TFpGDBMIExpressionPartOperator.DebugText(AIndent: String): String;
begin
  Result := inherited DebugText(AIndent);
  while Result[Length(Result)] in [#10, #13] do SetLength(Result, Length(Result)-1);
  Result := Result +
    ' IsUnary:' + dbgs(FIsUnary) +
    ' Precedence:' + dbgs(FPrecedence) +
    LineEnding;
end;

function TFpGDBMIExpressionPartOperator.CanHaveBinaryOperatorAsNext: Boolean;
begin
  if IsUnary then
    Result := (Count = 1) and Items[0].CanHaveBinaryOperatorAsNext
  else
    Result := (Count = 2) and Items[1].CanHaveBinaryOperatorAsNext;
end;

procedure TFpGDBMIExpressionPartOperator.DoHandleEndOfExpression;
begin
  if (IsUnary and (Count < 1)) or
     (not IsUnary and (Count < 2))
  then
    SetError(Self, 'Not enough operands')
  else
    inherited DoHandleEndOfExpression;
end;

function TFpGDBMIExpressionPartOperator.HandleNextPart(APart: TFpGDBMIExpressionPart): TFpGDBMIExpressionPart;
begin
  Result := Self;
  if (IsUnary and (Count > 0)) or (Count > 1) then begin
    Result := inherited HandleNextPart(APart);
    exit;
  end;
  if not IsValidNextPart(APart) then begin
    SetError(APart, 'Not possible after Operator '+GetText+': ');
    APart.Free;
    exit;
  end;

  Add(APart);
  Result := APart;
end;

function TFpGDBMIExpressionPartOperator.HandlePrevPart(APart: TFpGDBMIExpressionPart): TFpGDBMIExpressionPart;
var
  OpPart: TFpGDBMIExpressionPartOperator;
begin
  Result := Self;
  if IsUnary or     // Unary has no previous // TODO deref ^
     (Count > 0) or // Previous already set
     (not APart.CanHaveBinaryOperatorAsNext) // can not have 2 operators follow each other
  then begin
    SetError(APart, 'Can not apply operator '+GetText+': ');
    APart.Free;
    Result := Self;
    exit
  end;

  // precedence: 1 = highest
  if APart is TFpGDBMIExpressionPartOperator then begin
    OpPart := TFpGDBMIExpressionPartOperator(APart);

    while true do begin
      if OpPart.LastItem = nil then begin
        SetError(APart, 'Internal parser error for operator '+GetText+': ');
        APart.Free;
        Result := Self;
        exit
      end;

      if OpPart.Precedence > Self.Precedence then begin
        if (OpPart.LastItem is TFpGDBMIExpressionPartOperator) and
           (TFpGDBMIExpressionPartOperator(OpPart.LastItem).Precedence > Self.Precedence)
        then begin
          OpPart := TFpGDBMIExpressionPartOperator(OpPart.LastItem);
          continue;
        end;

        // APart := OpPart.LastItem; break;
        Add(OpPart.LastItem);
        OpPart.LastItem := Self;
        exit;
      end;

      break;
    end;
  end;

  APart.ReplaceInParent(Self);
  Add(APart);
end;

{ TFpGDBMIExpressionPartUnaryOperator }

procedure TFpGDBMIExpressionPartUnaryOperator.Init;
begin
  FIsUnary := True;
  inherited Init;
end;

{ TFpGDBMIExpressionPartBinaryOperator }

procedure TFpGDBMIExpressionPartBinaryOperator.Init;
begin
  FIsUnary := False;
  inherited Init;
end;

{ TFpGDBMIExpressionPartOperatorAddressOf }

procedure TFpGDBMIExpressionPartOperatorAddressOf.Init;
begin
  FPrecedence := 1; // highest
  inherited Init;
end;

{ TFpGDBMIExpressionPartOperatorPlusMinus }

procedure TFpGDBMIExpressionPartOperatorPlusMinus.Init;
begin
  FPrecedence := 3;
  inherited Init;
end;

{ TFpGDBMIExpressionPartOperatorMulDiv }

procedure TFpGDBMIExpressionPartOperatorMulDiv.Init;
begin
  FPrecedence := 2;
  inherited Init;
end;

{ TFpGDBPTypeRequestCache }

constructor TFpGDBPTypeRequestCache.Create(ADebugger: TFpGDBMIDebugger);
begin
  FDebugger := ADebugger;
  FInIndexOf := False;
  inherited Create;
end;

function TFpGDBPTypeRequestCache.IndexOf(AThreadId, AStackFrame: Integer;
  ARequest: TGDBPTypeRequest): Integer;
var
  IdentName: String;
  Loc: TDBGPtr;
  Ident: TDbgSymbol;
begin
  Result := inherited IndexOf(AThreadId, AStackFrame, ARequest);

  if (Result > 0) or FInIndexOf then
    exit;

  FInIndexOf := True;
  try
  if FDebugger.HasDwarf and (ARequest.ReqType = gcrtPType) then begin
    if copy(ARequest.Request, 1, 6) = 'ptype ' then
	     IdentName := trim(copy(ARequest.Request, 7, length(ARequest.Request)))
    else
    if copy(ARequest.Request, 1, 7) = 'whatis ' then
      IdentName := trim(copy(ARequest.Request, 8, length(ARequest.Request)));

    if IdentName <> '' then begin
      Loc := FDebugger.GetLocationForContext(AThreadId, AStackFrame);
      if (Loc <> 0) then begin
        Ident := FDebugger.FDwarfInfo.FindIdentifier(Loc, IdentName);
        if Ident <> nil then begin
          FDebugger.AddToGDBMICache(AThreadId, AStackFrame, Ident);
          Result := inherited IndexOf(AThreadId, AStackFrame, ARequest);
        end;
       ReleaseRefAndNil(Ident);
      end;
    end;
  end;
  finally
    FInIndexOf := False;
  end;
end;

{ TFPGDBMIWatches }

function TFPGDBMIWatches.FpDebugger: TFpGDBMIDebugger;
begin
  Result := TFpGDBMIDebugger(Debugger);
end;

procedure TFPGDBMIWatches.InternalRequestData(AWatchValue: TCurrentWatchValue);
var
  Loc: TDBGPtr;
  Ident: TDbgSymbol;
begin
  //if FpDebugger.HasDwarf then begin
  //   Loc := FpDebugger.GetLocationForContext(AWatchValue.ThreadId, AWatchValue.StackFrame);
  //
  //   if (Loc <> 0) then begin
  //     Ident := FpDebugger.FDwarfInfo.FindIdentifier(Loc, AWatchValue.Watch.Expression);
  //
  //     if Ident <> nil then
  //       FpDebugger.AddToGDBMICache(AWatchValue.ThreadId, AWatchValue.StackFrame, Ident);
  //
  //     ReleaseRefAndNil(Ident);
  //   end;
  //end;

  inherited InternalRequestData(AWatchValue);
end;

{ TFpGDBMILineInfo }

function TFpGDBMILineInfo.FpDebugger: TFpGDBMIDebugger;
begin
  Result := TFpGDBMIDebugger(Debugger);
end;

procedure TFpGDBMILineInfo.DoStateChange(const AOldState: TDBGState);
begin
  //inherited DoStateChange(AOldState);
  if not (Debugger.State in [dsPause, dsInternalPause, dsRun]) then
    ClearSources;
end;

procedure TFpGDBMILineInfo.ClearSources;
begin
  FRequestedSources.Clear;
end;

constructor TFpGDBMILineInfo.Create(const ADebugger: TDebugger);
begin
  FRequestedSources := TStringList.Create;
  inherited Create(ADebugger);
end;

destructor TFpGDBMILineInfo.Destroy;
begin
  FreeAndNil(FRequestedSources);
  inherited Destroy;
end;

function TFpGDBMILineInfo.Count: Integer;
begin
  Result := FRequestedSources.Count;
end;

function TFpGDBMILineInfo.GetAddress(const AIndex: Integer; const ALine: Integer): TDbgPtr;
var
  Map: PDWarfLineMap;
begin
  Result := 0;
  if not FpDebugger.HasDwarf then
    exit;
  //Result := FpDebugger.FDwarfInfo.GetLineAddress(FRequestedSources[AIndex], ALine);
  Map := PDWarfLineMap(FRequestedSources.Objects[AIndex]);
  if Map <> nil then
    Result := Map^.GetAddressForLine(ALine);
end;

function TFpGDBMILineInfo.GetInfo(AAdress: TDbgPtr; out ASource, ALine,
  AOffset: Integer): Boolean;
begin
  Result := False;
  //ASource := '';
  //ALine := 0;
  //if not FpDebugger.HasDwarf then
  //  exit(nil);
  //FpDebugger.FDwarfInfo.
end;

function TFpGDBMILineInfo.IndexOf(const ASource: String): integer;
begin
  Result := FRequestedSources.IndexOf(ASource);
end;

procedure TFpGDBMILineInfo.Request(const ASource: String);
begin
  if not FpDebugger.HasDwarf then
    exit;
  FRequestedSources.AddObject(ASource, TObject(FpDebugger.FDwarfInfo.GetLineAddressMap(ASource)));
  DoChange(ASource);
end;

procedure TFpGDBMILineInfo.Cancel(const ASource: String);
begin
  //
end;


{ TFpGDBMIDebuggerCommandStartDebugging }

function TFpGDBMIDebuggerCommandStartDebugging.DoExecute: Boolean;
begin
  TFpGDBMIDebugger(FTheDebugger).LoadDwarf;
  Result := inherited DoExecute;
end;

{ TFpGDBMIDebugger }

procedure TFpGDBMIDebugger.DoState(const OldState: TDBGState);
begin
  inherited DoState(OldState);
  if State in [dsStop, dsError, dsNone] then
    UnLoadDwarf;
end;

function TFpGDBMIDebugger.HasDwarf: Boolean;
begin
  Result := FDwarfInfo <> nil;
end;

procedure TFpGDBMIDebugger.LoadDwarf;
begin
  UnLoadDwarf;
  debugln(['TFpGDBMIDebugger.LoadDwarf ']);
  FImageLoader := TDbgImageLoader.Create(FileName);
  FDwarfInfo := TDbgDwarf.Create(FImageLoader);
  FDwarfInfo.LoadCompilationUnits;
end;

procedure TFpGDBMIDebugger.UnLoadDwarf;
begin
  debugln(['TFpGDBMIDebugger.UnLoadDwarf ']);
  FreeAndNil(FDwarfInfo);
  FreeAndNil(FImageLoader);
end;

function TFpGDBMIDebugger.RequestCommand(const ACommand: TDBGCommand;
  const AParams: array of const): Boolean;
var
  Ident: TDbgSymbol;
  Loc: TDBGPtr;
  CurThread, CurStack: Integer;
begin
  if HasDwarf and (ACommand = dcEvaluate) then begin
     //GetCurrentContext(CurThread, CurStack);
     //Loc := GetLocationForContext(CurThread, CurStack);
     //
     //if (Loc <> 0) then begin
     //  Ident := FDwarfInfo.FindIdentifier(Loc, String(AParams[0].VAnsiString));
     //
     //  if Ident <> nil then
     //    AddToGDBMICache(CurThread, CurStack, Ident);
     //
     //  ReleaseRefAndNil(Ident);
     //end;

//    //EvalFlags := [];
//    //if high(AParams) >= 3 then
//    //  EvalFlags := TDBGEvaluateFlags(AParams[3].VInteger);
//    //Result := GDBEvaluate(String(AParams[0].VAnsiString),
//    //  String(AParams[1].VPointer^), TGDBType(AParams[2].VPointer^),
//    //  EvalFlags);
    Result := inherited RequestCommand(ACommand, AParams);
  end
  else
    Result := inherited RequestCommand(ACommand, AParams);
end;

procedure TFpGDBMIDebugger.GetCurrentContext(out AThreadId, AStackFrame: Integer);
begin
  if (AThreadId <= 0) and CurrentThreadIdValid then begin
    AThreadId := CurrentThreadId;
    AStackFrame := 0;
  end
  else
  if (AThreadId <= 0) and (not CurrentThreadIdValid) then begin
    AThreadId := 1;
    AStackFrame := 0;
  end
  else
  if (AStackFrame < 0) and (CurrentStackFrameValid) then begin
    AStackFrame := CurrentStackFrame;
  end
  else
  if (AStackFrame < 0) and (not CurrentStackFrameValid) then begin
    AStackFrame := 0;
  end;
end;

function TFpGDBMIDebugger.GetLocationForContext(AThreadId, AStackFrame: Integer): TDBGPtr;
var
  t: TThreadEntry;
  s: TCallStack;
  f: TCallStackEntry;
begin
  Result := 0;
  if (AThreadId <= 0) then begin
    GetCurrentContext(AThreadId, AStackFrame);
  end
  else
  if (AStackFrame < 0) then begin
    AStackFrame := 0;
  end;

  t := Threads.CurrentThreads.EntryById[AThreadId];
  if t = nil then begin
    DebugLn(['NO Threads']);
    exit;
  end;
  if AStackFrame = 0 then begin
    Result := t.Address;
    DebugLn(['Returning addr from Threads', dbgs(Result)]);
    exit;
  end;

  s := CallStack.CurrentCallStackList.EntriesForThreads[AThreadId];
  if s = nil then begin
    DebugLn(['NO Stackframe list for thread']);
    exit;
  end;
  f := s.Entries[AStackFrame];
  if f = nil then begin
    DebugLn(['NO Stackframe']);
    exit;
  end;

  Result := f.Address;
  DebugLn(['Returning addr from frame', dbgs(Result)]);

end;

type
  TGDBMIDwarfTypeIdentifier = class(TDbgDwarfTypeIdentifier)
  public
    property InformationEntry;
  end;

procedure TFpGDBMIDebugger.AddToGDBMICache(AThreadId, AStackFrame: Integer;
  AnIdent: TDbgSymbol);
const
  GdbCmdPType = 'ptype ';
  GdbCmdWhatIs = 'whatis ';

  procedure MaybeAdd(AType: TGDBCommandRequestType; AQuery, AAnswer: String);
  var
    AReq: TGDBPTypeRequest;
  begin
    AReq.ReqType := AType;
    AReq.Request := AQuery;
    if TypeRequestCache.IndexOf(AThreadId, AStackFrame, AReq) < 0 then begin
      AReq.Result := ParseTypeFromGdb(AAnswer);
      TypeRequestCache.Add(AThreadId, AStackFrame, AReq);
      debugln(['TFpGDBMIDebugger.AddToGDBMICache ', AReq.Request, ' T:', AThreadId, ' S:',AStackFrame, ' >> ', AAnswer]);
    end;
  end;

var
  TypeIdent: TDbgDwarfTypeIdentifier;
  VarName, TypeName: String;
  AReq: TGDBPTypeRequest;
  IsPointer: Boolean;
begin
  (* Simulate gdb answers *)
  //TypeRequestCache

  if AnIdent is TDbgDwarfValueIdentifier then begin
    VarName := TDbgDwarfValueIdentifier(AnIdent).IdentifierName;
    TypeIdent := TDbgDwarfValueIdentifier(AnIdent).TypeInfo;
    if TypeIdent = nil then exit;
    TypeName := TypeIdent.IdentifierName;
    IsPointer := TypeIdent.IsPointerType;
    while (TypeIdent <> nil) and TypeIdent.IsPointerType do
      TypeIdent := TypeIdent.PointedToType;
    if TypeIdent = nil then exit;


    if TGDBMIDwarfTypeIdentifier(TypeIdent).IsBaseType then begin
      if IsPointer then begin
        MaybeAdd(gcrtPType, GdbCmdPType + VarName, Format('type = ^%s', [TypeName]));
        MaybeAdd(gcrtPType, GdbCmdWhatIs + VarName, Format('type = ^%s', [TypeName]));
        MaybeAdd(gcrtPType, GdbCmdPType + GDBMIMaybeApplyBracketsToExpr(VarName) + '^',
                 Format('type = %s', [TypeName]));
        MaybeAdd(gcrtPType, GdbCmdWhatIs + GDBMIMaybeApplyBracketsToExpr(VarName) + '^',
                 Format('type = %s', [TypeName]));
      end
      else begin
        MaybeAdd(gcrtPType, GdbCmdPType + VarName, Format('type = %s', [TypeName]));
        MaybeAdd(gcrtPType, GdbCmdWhatIs + VarName, Format('type = %s', [TypeName]));
      end;
    end;


  end;
  (*
    ptype i
    ~"type = LONGINT\n"
    whatis i
    ~"type = LONGINT\n"


    ptype @i
    ~"type = ^LONGINT\n"
    ptype (@i)^
    ~"type = LONGINT\n"
    whatis @i
    ~"type = ^LONGINT\n"
  *)

end;

function TFpGDBMIDebugger.CreateTypeRequestCache: TGDBPTypeRequestCache;
begin
  Result := TFpGDBPTypeRequestCache.Create(Self);
end;

function TFpGDBMIDebugger.CreateCommandStartDebugging(AContinueCommand: TGDBMIDebuggerCommand): TGDBMIDebuggerCommandStartDebugging;
begin
  Result := TFpGDBMIDebuggerCommandStartDebugging.Create(Self, AContinueCommand);
end;

function TFpGDBMIDebugger.CreateLineInfo: TDBGLineInfo;
begin
  Result := TFpGDBMILineInfo.Create(Self);
end;

function TFpGDBMIDebugger.CreateWatches: TWatchesSupplier;
begin
  Result := TFPGDBMIWatches.Create(Self);
end;

class function TFpGDBMIDebugger.Caption: String;
begin
  Result := 'GNU remote debugger (with fpdebug)';
end;

destructor TFpGDBMIDebugger.Destroy;
begin
  UnLoadDwarf;
  inherited Destroy;
end;

initialization
  RegisterDebugger(TFpGDBMIDebugger);

end.

