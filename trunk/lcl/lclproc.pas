{
 /***************************************************************************
                                  lclproc.pas
                                  -----------
                             Component Library Code


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Useful lower level helper functions and classes.
}
unit LCLProc;

{$mode objfpc}{$H+}
{$inline on}

interface

uses
  Classes, SysUtils, Math, TypInfo, Types, FPCAdds, AvgLvlTree, FileUtil,
  LCLStrConsts, LCLType;

type
  { TMethodList - array of TMethod }

  TMethodList = class
  private
    FItems: ^TMethod;
    FCount: integer;
    function GetItems(Index: integer): TMethod;
    procedure SetItems(Index: integer; const AValue: TMethod);
  public
    destructor Destroy; override;
    function Count: integer;
    function NextDownIndex(var Index: integer): boolean;
    function IndexOf(const AMethod: TMethod): integer;
    procedure Delete(Index: integer);
    procedure Remove(const AMethod: TMethod);
    procedure Add(const AMethod: TMethod);
    procedure Add(const AMethod: TMethod; AsLast: boolean);
    procedure Insert(Index: integer; const AMethod: TMethod);
    procedure Move(OldIndex, NewIndex: integer);
    procedure RemoveAllMethodsOfObject(const AnObject: TObject);
    procedure CallNotifyEvents(Sender: TObject);
  public
    property Items[Index: integer]: TMethod read GetItems write SetItems; default;
  end;

type
  TStackTracePointers = array of Pointer;

  { TDebugLCLItemInfo }

  TDebugLCLItemInfo = class
  public
    Item: Pointer;
    IsDestroyed: boolean;
    Info: string;
    CreationStack: TStackTracePointers; // stack trace at creationg
    DestructionStack: TStackTracePointers;// stack trace at destruction
    function AsString(WithStackTraces: boolean): string;
    destructor Destroy; override;
  end;

  { TDebugLCLItems }

  TDebugLCLItems = class
  private
    FItems: TAvgLvlTree;// tree of TDebugLCLItemInfo
  public
    constructor Create;
    destructor Destroy; override;
    function FindInfo(p: Pointer; CreateIfNotExists: boolean = false
                      ): TDebugLCLItemInfo;
    function IsDestroyed(p: Pointer): boolean;
    function IsCreated(p: Pointer): boolean;
    function MarkCreated(p: Pointer; const InfoText: string): TDebugLCLItemInfo;
    procedure MarkDestroyed(p: Pointer);
    function GetInfo(p: Pointer; WithStackTraces: boolean): string;
  end;

  TLineInfoCacheItem = record
    Addr: Pointer;
    Info: string;
  end;
  PLineInfoCacheItem = ^TLineInfoCacheItem;

{$IFDEF DebugLCLComponents}
var
  DebugLCLComponents: TDebugLCLItems = nil;
{$ENDIF}

function CompareDebugLCLItemInfos(Data1, Data2: Pointer): integer;
function CompareItemWithDebugLCLItemInfo(Item, DebugItemInfo: Pointer): integer;

function CompareLineInfoCacheItems(Data1, Data2: Pointer): integer;
function CompareAddrWithLineInfoCacheItem(Addr, Item: Pointer): integer;


type
  TStringsSortCompare = function(const Item1, Item2: string): Integer;


procedure MergeSort(List: TFPList; const OnCompare: TListSortCompare);
procedure MergeSort(List: TStrings; const OnCompare: TStringsSortCompare);

function GetEnumValueDef(TypeInfo: PTypeInfo; const Name: string;
                         const DefaultValue: Integer): Integer;

function ShortCutToText(ShortCut: TShortCut): string;
function TextToShortCut(const ShortCutText: string): TShortCut;

function GetCompleteText(sText: string; iSelStart: Integer;
  bCaseSensitive, bSearchAscending: Boolean; slTextList: TStrings): string;
function IsEditableTextKey(Key: Word): Boolean;

// Hooks used to prevent unit circles
type
  TSendApplicationMessageFunction =
    function(Msg: Cardinal; WParam: WParam; LParam: LParam):Longint;
  TOwnerFormDesignerModifiedProc =
    procedure(AComponent: TComponent);


var
  SendApplicationMessageFunction: TSendApplicationMessageFunction=nil;
  OwnerFormDesignerModifiedProc: TOwnerFormDesignerModifiedProc=nil;

function SendApplicationMessage(Msg: Cardinal; WParam: WParam; LParam: LParam):Longint;
procedure OwnerFormDesignerModified(AComponent: TComponent);
procedure FreeThenNil(var AnObject: TObject);

{ the LCL interfaces finalization sections are called before the finalization
  sections of the LCL. Those parts, that should be finalized after the LCL, can
  be registered here. }
procedure RegisterInterfaceFinalizationHandler(p: TProcedure);
procedure CallInterfaceFinalizationHandlers;

function OffsetRect(var ARect: TRect; dx, dy: Integer): Boolean;
procedure MoveRect(var ARect: TRect; x, y: Integer);
procedure MoveRectToFit(var ARect: TRect; const MaxRect: TRect);
procedure MakeMinMax(var i1, i2: integer);
procedure CalculateLeftTopWidthHeight(X1,Y1,X2,Y2: integer;
  var Left,Top,Width,Height: integer);

function DeleteAmpersands(var Str : String) : Longint;
function BreakString(const s: string; MaxLineLength, Indent: integer): string;

function ComparePointers(p1, p2: Pointer): integer;
function CompareHandles(h1, h2: THandle): integer;
function CompareRect(R1, R2: PRect): Boolean;
function ComparePoints(const p1, p2: TPoint): integer;


function RoundToInt(const e: Extended): integer;
function RoundToCardinal(const e: Extended): cardinal;
function TruncToInt(const e: Extended): integer;
function TruncToCardinal(const e: Extended): cardinal;
function StrToDouble(const s: string): double;



// debugging
procedure RaiseGDBException(const Msg: string);
procedure DumpExceptionBackTrace;
procedure DumpStack;
function GetStackTrace(UseCache: boolean): string;
procedure GetStackTracePointers(var AStack: TStackTracePointers);
function StackTraceAsString(const AStack: TStackTracePointers;
                            UseCache: boolean): string;
function GetLineInfo(Addr: Pointer; UseCache: boolean): string;

procedure DebugLn(Args: array of const);
procedure DebugLn(const S: String; Args: array of const);// similar to Format(s,Args)
procedure DebugLn;
procedure DebugLn(const s: string);
procedure DebugLn(const s1,s2: string);
procedure DebugLn(const s1,s2,s3: string);
procedure DebugLn(const s1,s2,s3,s4: string);
procedure DebugLn(const s1,s2,s3,s4,s5: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7,s8: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7,s8,s9: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15: string);
procedure DebugLn(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s16: string);
function ConvertLineEndings(const s: string): string;

procedure DbgOut(const S: String; Args: array of const);
procedure DbgOut(const s: string);
procedure DbgOut(const s1,s2: string);
procedure DbgOut(const s1,s2,s3: string);
procedure DbgOut(const s1,s2,s3,s4: string);
procedure DbgOut(const s1,s2,s3,s4,s5: string);
procedure DbgOut(const s1,s2,s3,s4,s5,s6: string);
procedure DbgOut(const s1,s2,s3,s4,s5,s6,s7: string);
procedure DbgOut(const s1,s2,s3,s4,s5,s6,s7,s8: string);
procedure DbgOut(const s1,s2,s3,s4,s5,s6,s7,s8,s9: string);
procedure DbgOut(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10: string);
procedure DbgOut(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11: string);
procedure DbgOut(const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12: string);

function DbgS(const c: cardinal): string; overload;
function DbgS(const i: longint): string; overload;
function DbgS(const i: int64): string; overload;
function DbgS(const q: qword): string; overload;
function DbgS(const r: TRect): string; overload;
function DbgS(const p: TPoint): string; overload;
function DbgS(const p: pointer): string; overload;
function DbgS(const e: extended; MaxDecimals: integer = 999): string; overload;
function DbgS(const b: boolean): string; overload;
function DbgSName(const p: TObject): string; overload;
function DbgSName(const p: TClass): string; overload;
function DbgStr(const StringWithSpecialChars: string): string; overload;
function DbgWideStr(const StringWithSpecialChars: widestring): string; overload;
function dbgMemRange(P: PByte; Count: integer; Width: integer = 0): string; overload;
function dbgMemStream(MemStream: TCustomMemoryStream; Count: integer): string; overload;
function dbgObjMem(AnObject: TObject): string; overload;
function dbghex(i: Int64): string; overload;

function DbgS(const i1,i2,i3,i4: integer): string; overload;
function DbgS(const Shift: TShiftState): string; overload;
function DbgsVKCode(c: word): string;

procedure DbgOutThreadLog(const Msg: string); overload;
procedure DebuglnThreadLog(const Msg: string); overload;
procedure DebuglnThreadLog(Args: array of const); overload;
procedure DebuglnThreadLog; overload;

// some string manipulation functions
function StripLN(const ALine: String): String;
function GetPart(const ASkipTo, AnEnd: String; var ASource: String): String; overload;
function GetPart(const ASkipTo, AnEnd: String; var ASource: String; const AnIgnoreCase: Boolean): String; overload;
function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String): String; overload;
function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String; const AnIgnoreCase: Boolean): String; overload;
function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String; const AnIgnoreCase, AnUpdateSource: Boolean): String; overload;

// case..of utility functions
function StringCase(const AString: String; const ACase: array of String {; const AIgnoreCase = False, APartial = false: Boolean}): Integer; overload;
function StringCase(const AString: String; const ACase: array of String; const AIgnoreCase, APartial: Boolean): Integer; overload;
function ClassCase(const AClass: TClass; const ACase: array of TClass {; const ADecendant: Boolean = True}): Integer; overload;
function ClassCase(const AClass: TClass; const ACase: array of TClass; const ADecendant: Boolean): Integer; overload;


// UTF utility functions
// MG: Should be moved to the RTL
function UTF8CharacterLength(p: PChar): integer;
function UTF8Length(const s: string): integer;
function UTF8Length(p: PChar; ByteCount: integer): integer;
function UTF8CharacterToUnicode(p: PChar; out CharLen: integer): Cardinal;
function UnicodeToUTF8(u: cardinal): string;
function UTF8ToDoubleByteString(const s: string): string;
function UTF8ToDoubleByte(UTF8Str: PChar; Len: integer; DBStr: PByte): integer;
function UTF8FindNearestCharStart(UTF8Str: PChar; Len: integer;
                                  BytePos: integer): integer;
// find the n-th UTF8 character, ignoring BIDI
function UTF8CharStart(UTF8Str: PChar; Len, Index: integer): PChar;
procedure UTF8FixBroken(P: PChar);
function UTF8CStringToUTF8String(SourceStart: PChar; SourceLen: SizeInt) : string;
function UTF8Pos(const SearchForText, SearchInText: string): integer;
function UTF8Copy(const s: string; StartCharIndex, CharCount: integer): string;
function FindInvalidUTF8Character(p: PChar; Count: integer;
                                  StopOnNonASCII: Boolean = false): integer;

function UTF16CharacterLength(p: PWideChar): integer;
function UTF16Length(const s: widestring): integer;
function UTF16Length(p: PWideChar; WordCount: integer): integer;
function UTF16CharacterToUnicode(p: PWideChar; out CharLen: integer): Cardinal;
function UnicodeToUTF16(u: cardinal): widestring;


// identifier
function CreateFirstIdentifier(const Identifier: string): string;
function CreateNextIdentifier(const Identifier: string): string;


// ======================================================================
// Endian utility functions
// MWE: maybe to RTL ?
// inline ?
//
// These functions convert a BigEndian or LittleEndian number to
// a machine Native number and vice versa.
//
// Note: Lazarus resources are streamed using LE. So when writing data
//       use NtoLE(your_value), when reading use LEtoN(read_value)
// ======================================================================

function BEtoN(const AValue: SmallInt): SmallInt;
function BEtoN(const AValue: Word): Word;
function BEtoN(const AValue: LongInt): LongInt;
function BEtoN(const AValue: DWord): DWord;
function BEtoN(const AValue: Int64): Int64;
function BEtoN(const AValue: QWord): QWord;

function LEtoN(const AValue: SmallInt): SmallInt;
function LEtoN(const AValue: Word): Word;
function LEtoN(const AValue: LongInt): LongInt;
function LEtoN(const AValue: DWord): DWord;
function LEtoN(const AValue: Int64): Int64;
function LEtoN(const AValue: QWord): QWord;

function NtoBE(const AValue: SmallInt): SmallInt;
function NtoBE(const AValue: Word): Word;
function NtoBE(const AValue: LongInt): LongInt;
function NtoBE(const AValue: DWord): DWord;
function NtoBE(const AValue: Int64): Int64;
function NtoBE(const AValue: QWord): QWord;

function NtoLE(const AValue: SmallInt): SmallInt;
function NtoLE(const AValue: Word): Word;
function NtoLE(const AValue: LongInt): LongInt;
function NtoLE(const AValue: DWord): DWord;
function NtoLE(const AValue: Int64): Int64;
function NtoLE(const AValue: QWord): QWord;


implementation


var
  InterfaceFinalizationHandlers: TFPList;
  DebugTextAllocated: boolean;
  DebugText: ^Text;
  LineInfoCache: TAvgLvlTree = nil;


Function DeleteAmpersands(var Str : String) : Longint;
// Replace all &x with x
// and return the position of the first ampersand letter in the resulting Str.
// double ampersands && are converted to a single & and are ignored.
var
  SrcPos, DestPos, SrcLen: Integer;
begin
  Result:=-1;
  SrcLen:=length(Str);
  SrcPos:=1;
  DestPos:=1;
  while SrcPos<=SrcLen do begin
    if (Str[SrcPos]='&') and (SrcPos<SrcLen) then begin
      // & found
      inc(SrcPos); // skip &
      if (Str[SrcPos]<>'&') and (Result<1) then
        Result:=DestPos;
    end;
    if DestPos<SrcPos then
      Str[DestPos]:=Str[SrcPos];
    inc(SrcPos);
    inc(DestPos);
  end;
  if DestPos<SrcPos then
    SetLength(Str,DestPos-1);
end;

//-----------------------------------------------------------------------------
// Keys and shortcuts

type
  TMenuKeyCap = (mkcBkSp, mkcTab, mkcEsc, mkcEnter, mkcSpace, mkcPgUp,
    mkcPgDn, mkcEnd, mkcHome, mkcLeft, mkcUp, mkcRight, mkcDown, mkcIns,
    mkcDel, mkcShift, mkcCtrl, mkcAlt);

const
  SmkcBkSp = 'BkSp';
  SmkcTab = 'Tab';
  SmkcEsc = 'Esc';
  SmkcEnter = 'Enter';
  SmkcSpace = 'Space';
  SmkcPgUp = 'PgUp';
  SmkcPgDn = 'PgDn';
  SmkcEnd = 'End';
  SmkcHome = 'Home';
  SmkcLeft = 'Left';
  SmkcUp = 'Up';
  SmkcRight = 'Right';
  SmkcDown = 'Down';
  SmkcIns = 'Ins';
  SmkcDel = 'Del';
  SmkcShift = 'Shift+';
  SmkcCtrl = 'Ctrl+';
  SmkcAlt = 'Alt+';

  MenuKeyCaps: array[TMenuKeyCap] of string = (
    SmkcBkSp, SmkcTab, SmkcEsc, SmkcEnter, SmkcSpace, SmkcPgUp,
    SmkcPgDn, SmkcEnd, SmkcHome, SmkcLeft, SmkcUp, SmkcRight,
    SmkcDown, SmkcIns, SmkcDel, SmkcShift, SmkcCtrl, SmkcAlt);

function GetSpecialShortCutName(ShortCut: TShortCut): string;
{var
  ScanCode: Integer;
  KeyName: array[0..255] of Char;}
begin
  Result := '';
  // ToDo:
  {
  ScanCode := MapVirtualKey(WordRec(ShortCut).Lo, 0) shl 16;
  if ScanCode <> 0 then
  begin
    GetKeyNameText(ScanCode, KeyName, SizeOf(KeyName));
    Result := KeyName;
  end;
  }
end;

function CompareDebugLCLItemInfos(Data1, Data2: Pointer): integer;
begin
  Result:=ComparePointers(TDebugLCLItemInfo(Data1).Item,
                          TDebugLCLItemInfo(Data2).Item);
end;

function CompareItemWithDebugLCLItemInfo(Item, DebugItemInfo: Pointer): integer;
begin
  Result:=ComparePointers(Item,TDebugLCLItemInfo(DebugItemInfo).Item);
end;

function CompareLineInfoCacheItems(Data1, Data2: Pointer): integer;
begin
  Result:=ComparePointers(PLineInfoCacheItem(Data1)^.Addr,
                          PLineInfoCacheItem(Data2)^.Addr);
end;

function CompareAddrWithLineInfoCacheItem(Addr, Item: Pointer): integer;
begin
  Result:=ComparePointers(Addr,PLineInfoCacheItem(Item)^.Addr);
end;

function GetEnumValueDef(TypeInfo: PTypeInfo; const Name: string;
  const DefaultValue: Integer): Integer;
begin
  Result:=GetEnumValue(TypeInfo,Name);
  if Result<0 then
    Result:=DefaultValue;
end;

function ShortCutToText(ShortCut: TShortCut): string;
var
  Name: string;
begin
  case WordRec(ShortCut).Lo of
    $08, $09:
      Name := MenuKeyCaps[TMenuKeyCap(Ord(mkcBkSp) + WordRec(ShortCut).Lo - $08)];
    $0D: Name := MenuKeyCaps[mkcEnter];
    $1B: Name := MenuKeyCaps[mkcEsc];
    $20..$28:
      Name := MenuKeyCaps[TMenuKeyCap(Ord(mkcSpace) + WordRec(ShortCut).Lo - $20)];
    $2D..$2E:
      Name := MenuKeyCaps[TMenuKeyCap(Ord(mkcIns) + WordRec(ShortCut).Lo - $2D)];
    $30..$39: Name := Chr(WordRec(ShortCut).Lo - $30 + Ord('0'));
    $41..$5A: Name := Chr(WordRec(ShortCut).Lo - $41 + Ord('A'));
    $60..$69: Name := Chr(WordRec(ShortCut).Lo - $60 + Ord('0'));
    $70..$87: Name := 'F' + IntToStr(WordRec(ShortCut).Lo - $6F);
  else
    Name := GetSpecialShortCutName(ShortCut);
  end;
  if Name <> '' then
  begin
    Result := '';
    if ShortCut and scShift <> 0 then Result := Result + MenuKeyCaps[mkcShift];
    if ShortCut and scCtrl <> 0 then Result := Result + MenuKeyCaps[mkcCtrl];
    if ShortCut and scAlt <> 0 then Result := Result + MenuKeyCaps[mkcAlt];
    Result := Result + Name;
  end
  else Result := '';
end;

function TextToShortCut(const ShortCutText: string): TShortCut;

  function CompareFront(var StartPos: integer; const Front: string): Boolean;
  begin
    if (Front<>'') and (StartPos+length(Front)-1<=length(ShortCutText))
    and (AnsiStrLIComp(@ShortCutText[StartPos], PChar(Front), Length(Front))= 0)
    then begin
      Result:=true;
      inc(StartPos,length(Front));
    end else
      Result:=false;
  end;

var
  Key: TShortCut;
  Shift: TShortCut;
  StartPos: integer;
  Name: string;
begin
  Result := 0;
  Shift := 0;
  StartPos:=1;
  while True do
  begin
    if CompareFront(StartPos, MenuKeyCaps[mkcShift]) then
      Shift := Shift or scShift
    else if CompareFront(StartPos, '^') then
      Shift := Shift or scCtrl
    else if CompareFront(StartPos, MenuKeyCaps[mkcCtrl]) then
      Shift := Shift or scCtrl
    else if CompareFront(StartPos, MenuKeyCaps[mkcAlt]) then
      Shift := Shift or scAlt
    else
      Break;
  end;
  if ShortCutText = '' then Exit;
  for Key := $08 to $255 do begin { Copy range from table in ShortCutToText }
    Name:=ShortCutToText(Key);
    if (Name<>'') and (length(Name)=length(ShortCutText)-StartPos+1)
    and (AnsiStrLIComp(@ShortCutText[StartPos], PChar(Name), length(Name)) = 0)
    then begin
      Result := Key or Shift;
      Exit;
    end;
  end;
end;

function GetCompleteText(sText: string; iSelStart: Integer;
  bCaseSensitive, bSearchAscending: Boolean; slTextList: TStrings): string;

  function IsSamePrefix(sCompareText, sPrefix: string; iStart: Integer;
    var ResultText: string): Boolean;
  var sTempText: string;
  begin
    Result := False;
    sTempText := LeftStr(sCompareText, iStart);
    if not bCaseSensitive then sTempText := UpperCase(sTempText);
    if (sTempText = sPrefix) then
    begin
      ResultText := sCompareText;
      Result := True;
    end;//End if (sTempText = sPrefix)
  end;//End function IsSamePrefix

var i: Integer;
    sPrefixText: string;
begin
  Result := sText;//Default to return original text if no identical text are found
  if (sText = '') then Exit;//Everything is compatible with nothing, Exit.
  if (iSelStart = 0) then Exit;//Cursor at beginning
  if (slTextList.Count = 0) then Exit;//No text list to search for idtenticals, Exit.
  sPrefixText := LeftStr(sText, iSelStart);//Get text from beginning to cursor position.
  if not bCaseSensitive then
    sPrefixText := UpperCase(sPrefixText);
  if bSearchAscending then
  begin
    for i:=0 to slTextList.Count-1 do
      if IsSamePrefix(slTextList[i], sPrefixText, iSelStart, Result) then Break;
  end else
  begin
    for i:=slTextList.Count-1 downto 0 do
      if IsSamePrefix(slTextList[i], sPrefixText, iSelStart, Result) then Break;
  end;//End if bSearchAscending
end;

function IsEditableTextKey(Key: Word): Boolean;
begin
 Result := (((Key >= VK_A) and (Key <= VK_Z)) or
            ((Key >= VK_NUMPAD0) and (Key <= VK_DIVIDE)) or
            ((Key >= 186) and (Key <= 188)) or
            ((Key >= 190) and (Key <= 192)) or
            ((Key >= 219) and (Key <= 222)));
end;

function SendApplicationMessage(Msg: Cardinal; WParam: WParam; LParam: LParam
  ): Longint;
begin
  if SendApplicationMessageFunction<>nil then
    Result:=SendApplicationMessageFunction(Msg, WParam, LParam)
  else
    Result:=0;
end;

procedure OwnerFormDesignerModified(AComponent: TComponent);
begin
  if ([csDesigning,csLoading,csDestroying]*AComponent.ComponentState
    =[csDesigning])
  then begin
    if OwnerFormDesignerModifiedProc<>nil then
      OwnerFormDesignerModifiedProc(AComponent);
  end;
end;

function OffSetRect(var ARect: TRect; dx,dy: Integer): Boolean;
Begin
  with ARect do
  begin
    Left := Left + dx;
    Right := Right + dx;
    Top := Top + dy;
    Bottom := Bottom + dy;
  end;
  if (ARect.Left >= 0) and (ARect.Top >= 0) then
    Result := True
  else
    Result := False;
end;

procedure FreeThenNil(var AnObject: TObject);
begin
  if AnObject<>nil then begin
    AnObject.Free;
    AnObject:=nil;
  end;
end;

procedure RegisterInterfaceFinalizationHandler(p: TProcedure);
begin
  InterfaceFinalizationHandlers.Add(p);
end;

procedure CallInterfaceFinalizationHandlers;
var
  i: Integer;
begin
  for i:=0 to InterfaceFinalizationHandlers.Count-1 do
    TProcedure(InterfaceFinalizationHandlers[i])();
end;

{ TMethodList }

function TMethodList.GetItems(Index: integer): TMethod;
begin
  Result:=FItems[Index];
end;

procedure TMethodList.SetItems(Index: integer; const AValue: TMethod);
begin
  FItems[Index]:=AValue;
end;

destructor TMethodList.Destroy;
begin
  ReAllocMem(FItems,0);
  inherited Destroy;
end;

function TMethodList.Count: integer;
begin
  if Self<>nil then
    Result:=FCount
  else
    Result:=0;
end;

function TMethodList.NextDownIndex(var Index: integer): boolean;
begin
  if Self<>nil then begin
    dec(Index);
    if (Index>=FCount) then
      Index:=FCount-1;
  end else
    Index:=-1;
  Result:=(Index>=0);
end;

function TMethodList.IndexOf(const AMethod: TMethod): integer;
begin
  if Self<>nil then begin
    Result:=FCount-1;
    while Result>=0 do begin
      if (FItems[Result].Code=AMethod.Code)
      and (FItems[Result].Data=AMethod.Data) then exit;
      dec(Result);
    end;
  end else
    Result:=-1;
end;

procedure TMethodList.Delete(Index: integer);
begin
  dec(FCount);
  if FCount>Index then
    System.Move(FItems[Index+1],FItems[Index],(FCount-Index)*SizeOf(TMethod));
  ReAllocMem(FItems,FCount*SizeOf(TMethod));
end;

procedure TMethodList.Remove(const AMethod: TMethod);
var
  i: integer;
begin
  if Self<>nil then begin
    i:=IndexOf(AMethod);
    if i>=0 then Delete(i);
  end;
end;

procedure TMethodList.Add(const AMethod: TMethod);
begin
  inc(FCount);
  ReAllocMem(FItems,FCount*SizeOf(TMethod));
  FItems[FCount-1]:=AMethod;
end;

procedure TMethodList.Add(const AMethod: TMethod; AsLast: boolean);
begin
  if AsLast then
    Add(AMethod)
  else
    Insert(0,AMethod);
end;

procedure TMethodList.Insert(Index: integer; const AMethod: TMethod);
begin
  inc(FCount);
  ReAllocMem(FItems,FCount*SizeOf(TMethod));
  if Index<FCount then
    System.Move(FItems[Index],FItems[Index+1],(FCount-Index)*SizeOf(TMethod));
  FItems[Index]:=AMethod;
end;

procedure TMethodList.Move(OldIndex, NewIndex: integer);
var
  MovingMethod: TMethod;
begin
  if OldIndex=NewIndex then exit;
  MovingMethod:=FItems[OldIndex];
  if OldIndex>NewIndex then
    System.Move(FItems[NewIndex],FItems[NewIndex+1],
                SizeOf(TMethod)*(OldIndex-NewIndex))
  else
    System.Move(FItems[NewIndex+1],FItems[NewIndex],
                SizeOf(TMethod)*(NewIndex-OldIndex));
  FItems[NewIndex]:=MovingMethod;
end;

procedure TMethodList.RemoveAllMethodsOfObject(const AnObject: TObject);
var
  i: Integer;
begin
  if Self=nil then exit;
  i:=FCount-1;
  while i>=0 do begin
    if TObject(FItems[i].Data)=AnObject then Delete(i);
    dec(i);
  end;
end;

procedure TMethodList.CallNotifyEvents(Sender: TObject);
var
  i: LongInt;
begin
  i:=Count;
  while NextDownIndex(i) do
    TNotifyEvent(Items[i])(Sender);
end;

{------------------------------------------------------------------------------
  procedure RaiseGDBException(const Msg: string);

  Raises an exception.
  gdb does normally not catch fpc Exception objects, therefore this procedure
  raises a standard AV which is catched by gdb.
 ------------------------------------------------------------------------------}
procedure RaiseGDBException(const Msg: string);
begin
  debugln(rsERRORInLCL, Msg);
  // creates an exception, that gdb catches:
  debugln(rsCreatingGdbCatchableError);
//  {$IF defined(CPUI386) or defined(CPUX86_64) }
// MWE: not yet, linux i386 seems to choke on this
//  asm
//    INT $3
//  end;
//  {$ELSE}
  DumpStack;
  if (length(Msg) div (length(Msg) div 10000))=0 then ;
//  {$ENDIF}
end;

procedure DumpExceptionBackTrace;
var
  FrameCount: integer;
  Frames: PPointer;
  FrameNumber:Integer;
begin
  DebugLn('  Stack trace:');
  DebugLn(BackTraceStrFunc(ExceptAddr));
  FrameCount:=ExceptFrameCount;
  Frames:=ExceptFrames;
  for FrameNumber := 0 to FrameCount-1 do
    DebugLn(BackTraceStrFunc(Frames[FrameNumber]));
end;

procedure DumpStack;
Begin
  if assigned(DebugText) then
    Dump_Stack(DebugText^, get_frame);
End;

function GetStackTrace(UseCache: boolean): string;
var
  bp: Pointer;
  addr: Pointer;
  oldbp: Pointer;
  CurAddress: Shortstring;
begin
  Result:='';
  { retrieve backtrace info }
  bp:=get_caller_frame(get_frame);
  while bp<>nil do begin
    addr:=get_caller_addr(bp);
    CurAddress:=GetLineInfo(addr,UseCache);
    //DebugLn('GetStackTrace ',CurAddress);
    Result:=Result+CurAddress+LineEnding;
    oldbp:=bp;
    bp:=get_caller_frame(bp);
    if (bp<=oldbp) or (bp>(StackBottom + StackLength)) then
      bp:=nil;
  end;
end;

procedure GetStackTracePointers(var AStack: TStackTracePointers);
var
  Depth: Integer;
  bp: Pointer;
  oldbp: Pointer;
begin
  // get stack depth
  Depth:=0;
  bp:=get_caller_frame(get_frame);
  while bp<>nil do begin
    inc(Depth);
    oldbp:=bp;
    bp:=get_caller_frame(bp);
    if (bp<=oldbp) or (bp>(StackBottom + StackLength)) then
      bp:=nil;
  end;
  SetLength(AStack,Depth);
  if Depth>0 then begin
    Depth:=0;
    bp:=get_caller_frame(get_frame);
    while bp<>nil do begin
      AStack[Depth]:=get_caller_addr(bp);
      inc(Depth);
      oldbp:=bp;
      bp:=get_caller_frame(bp);
      if (bp<=oldbp) or (bp>(StackBottom + StackLength)) then
        bp:=nil;
    end;
  end;
end;

function StackTraceAsString(const AStack: TStackTracePointers;
  UseCache: boolean): string;
var
  i: Integer;
  CurAddress: String;
begin
  Result:='';
  for i:=0 to length(AStack)-1 do begin
    CurAddress:=GetLineInfo(AStack[i],UseCache);
    Result:=Result+CurAddress+LineEnding;
  end;
end;

function GetLineInfo(Addr: Pointer; UseCache: boolean): string;
var
  ANode: TAvgLvlTreeNode;
  Item: PLineInfoCacheItem;
begin
  if UseCache then begin
    if LineInfoCache=nil then
      LineInfoCache:=TAvgLvlTree.Create(@CompareLineInfoCacheItems);
    ANode:=LineInfoCache.FindKey(Addr,@CompareAddrWithLineInfoCacheItem);
    if ANode=nil then begin
      Result:=BackTraceStrFunc(Addr);
      New(Item);
      Item^.Addr:=Addr;
      Item^.Info:=Result;
      LineInfoCache.Add(Item);
    end else begin
      Result:=PLineInfoCacheItem(ANode.Data)^.Info;
    end;
  end else
    Result:=BackTraceStrFunc(Addr);
end;

procedure MoveRect(var ARect: TRect; x, y: Integer);
begin
  inc(ARect.Right,x-ARect.Left);
  inc(ARect.Bottom,y-ARect.Top);
  ARect.Left:=x;
  ARect.Top:=y;
end;

procedure MoveRectToFit(var ARect: TRect; const MaxRect: TRect);
// move ARect, so it fits into MaxRect
// if MaxRect is too small, ARect is resized.
begin
  if ARect.Left<MaxRect.Left then begin
    // move rectangle right
    ARect.Right:=Min(ARect.Right+MaxRect.Left-ARect.Left,MaxRect.Right);
    ARect.Left:=MaxRect.Left;
  end;
  if ARect.Top<MaxRect.Top then begin
    // move rectangle down
    ARect.Bottom:=Min(ARect.Bottom+MaxRect.Top-ARect.Top,MaxRect.Bottom);
    ARect.Top:=MaxRect.Top;
  end;
  if ARect.Right>MaxRect.Right then begin
    // move rectangle left
    ARect.Left:=Max(ARect.Left-ARect.Right+MaxRect.Right,MaxRect.Left);
    ARect.Right:=MaxRect.Right;
  end;
  if ARect.Bottom>MaxRect.Bottom then begin
    // move rectangle left
    ARect.Top:=Max(ARect.Top-ARect.Bottom+MaxRect.Bottom,MaxRect.Top);
    ARect.Bottom:=MaxRect.Bottom;
  end;
end;

procedure MakeMinMax(var i1, i2: integer);
var
  h: Integer;
begin
  if i1>i2 then begin
    h:=i1;
    i1:=i2;
    i2:=h;
  end;
end;

procedure CalculateLeftTopWidthHeight(X1, Y1, X2, Y2: integer;
  var Left, Top, Width, Height: integer);
begin
  if X1<=X2 then begin
    Left:=X1;
    Width:=X2 - X1;
  end else begin
    Left:=X2;
    Width:=X1 - X2;
  end;
  if Y1<=Y2 then begin
    Top:=Y1;
    Height:=Y2 - Y1;
  end else begin
    Top:=Y2;
    Height:=Y1 - Y2;
  end;
end;

function BreakString(const s: string; MaxLineLength, Indent: integer): string;
var
  SrcLen: Integer;
  APos: Integer;
  Src: String;
  SplitPos: Integer;
  CurMaxLineLength: Integer;
begin
  Result:='';
  Src:=s;
  CurMaxLineLength:=MaxLineLength;
  if Indent>MaxLineLength-2 then Indent:=MaxLineLength-2;
  if Indent<0 then MaxLineLength:=0;
  repeat
    SrcLen:=length(Src);
    if SrcLen<=CurMaxLineLength then begin
      Result:=Result+Src;
      break;
    end;
    // split line
    SplitPos:=0;
    // search new line chars
    APos:=1;
    while (APos<=CurMaxLineLength) do begin
      if Src[APos] in [#13,#10] then begin
        SplitPos:=APos;
        break;
      end;
      inc(APos);
    end;
    // search a space boundary
    if SplitPos=0 then begin
      APos:=CurMaxLineLength;
      while APos>1 do begin
        if (Src[APos-1] in [' ',#9])
        and (not (Src[APos] in [' ',#9])) then begin
          SplitPos:=APos;
          break;
        end;
        dec(APos);
      end;
    end;
    // search a word boundary
    if SplitPos=0 then begin
      APos:=CurMaxLineLength;
      while APos>1 do begin
        if (Src[APos] in ['A'..'Z','a'..'z'])
        and (not (Src[APos-1] in ['A'..'Z','a'..'z'])) then begin
          SplitPos:=APos;
          break;
        end;
        dec(APos);
      end;
    end;
    if SplitPos=0 then begin
      // no word boundary found -> split chars
      SplitPos:=CurMaxLineLength;
    end;
    // append part and newline
    if (SplitPos<=SrcLen) and (Src[SplitPos] in [#10,#13]) then begin
      // there is already a new line char at position
      inc(SplitPos);
      if (SplitPos<=SrcLen) and (Src[SplitPos] in [#10,#13])
      and (Src[SplitPos]<>Src[SplitPos-1]) then
        inc(SplitPos);
      Result:=Result+copy(Src,1,SplitPos-1);
    end else begin
      Result:=Result+copy(Src,1,SplitPos-1)+LineEnding;
    end;
    // append indent
    if Indent>0 then
      Result:=Result+StringOfChar(' ',Indent);
    // calculate new LineLength
    CurMaxLineLength:=MaxLineLength-Indent;
    // cut string
    Src:=copy(Src,SplitPos,length(Src)-SplitPos+1);
  until false;
end;

function ComparePointers(p1, p2: Pointer): integer;
begin
  if p1>p2 then
    Result:=1
  else if p1<p2 then
    Result:=-1
  else
    Result:=0;
end;

function CompareHandles(h1, h2: THandle): integer;
begin
  if h1>h2 then
    Result:=1
  else if h1<h2 then
    Result:=-1
  else
    Result:=0;
end;

function CompareRect(R1, R2: PRect): Boolean;
begin
  Result:=(R1^.Left=R2^.Left) and (R1^.Top=R2^.Top) and
          (R1^.Bottom=R2^.Bottom) and (R1^.Right=R2^.Right);
  {if not Result then begin
    DebugLn(' DIFFER: ',R1^.Left,',',R1^.Top,',',R1^.Right,',',R1^.Bottom
      ,' <> ',R2^.Left,',',R2^.Top,',',R2^.Right,',',R2^.Bottom);
  end;}
end;

function ComparePoints(const p1, p2: TPoint): integer;
begin
  if p1.Y>p2.Y then
    Result:=1
  else if p1.Y<p2.Y then
    Result:=-1
  else if p1.X>p2.X then
    Result:=1
  else if p1.X<p2.X then
    Result:=-1
  else
    Result:=0;
end;

function RoundToInt(const e: Extended): integer;
begin
  Result:=integer(Round(e));
  {$IFDEF VerboseRound}
  DebugLn('RoundToInt ',e,' ',Result);
  {$ENDIF}
end;

function RoundToCardinal(const e: Extended): cardinal;
begin
  Result:=cardinal(Round(e));
  {$IFDEF VerboseRound}
  DebugLn('RoundToCardinal ',e,' ',Result);
  {$ENDIF}
end;

function TruncToInt(const e: Extended): integer;
begin
  Result:=integer(Trunc(e));
  {$IFDEF VerboseRound}
  DebugLn('TruncToInt ',e,' ',Result);
  {$ENDIF}
end;

function TruncToCardinal(const e: Extended): cardinal;
begin
  Result:=cardinal(Trunc(e));
  {$IFDEF VerboseRound}
  DebugLn('TruncToCardinal ',e,' ',Result);
  {$ENDIF}
end;

function StrToDouble(const s: string): double;
begin
  {$IFDEF VerboseRound}
  DebugLn('StrToDouble "',s,'"');
  {$ENDIF}
  Result:=Double(StrToFloat(s));
end;

procedure MergeSort(List: TFPList; const OnCompare: TListSortCompare);
var
  MergeList: PPointer;

  procedure Merge(Pos1, Pos2, Pos3: PtrInt);
  // merge two sorted arrays
  // the first array ranges Pos1..Pos2-1, the second ranges Pos2..Pos3
  var Src1Pos,Src2Pos,DestPos,cmp,a:PtrInt;
  begin
    while (Pos3>=Pos2) and (OnCompare(List[Pos2-1],List[Pos3])<=0) do
      dec(Pos3);
    if (Pos1>=Pos2) or (Pos2>Pos3) then exit;
    Src1Pos:=Pos2-1;
    Src2Pos:=Pos3;
    DestPos:=Pos3;
    while (Src2Pos>=Pos2) and (Src1Pos>=Pos1) do begin
      cmp:=OnCompare(List[Src1Pos],List[Src2Pos]);
      if cmp>0 then begin
        MergeList[DestPos]:=List[Src1Pos];
        dec(Src1Pos);
      end else begin
        MergeList[DestPos]:=List[Src2Pos];
        dec(Src2Pos);
      end;
      dec(DestPos);
    end;
    while Src2Pos>=Pos2 do begin
      MergeList[DestPos]:=List[Src2Pos];
      dec(Src2Pos);
      dec(DestPos);
    end;
    for a:=DestPos+1 to Pos3 do
      List[a]:=MergeList[a];
  end;

  procedure Sort(StartPos, EndPos: PtrInt);
  // sort an interval in List. Use MergeList as work space.
  var
    cmp, mid: integer;
    p: Pointer;
  begin
    if StartPos=EndPos then begin
    end else if StartPos+1=EndPos then begin
      cmp:=OnCompare(List[StartPos],List[EndPos]);
      if cmp>0 then begin
        p:=List[StartPos];
        List[StartPos]:=List[EndPos];
        List[EndPos]:=p;
      end;
    end else if EndPos>StartPos then begin
      mid:=(StartPos+EndPos) shr 1;
      Sort(StartPos,mid);
      Sort(mid+1,EndPos);
      Merge(StartPos,mid+1,EndPos);
    end;
  end;

begin
  if (List=nil) or (List.Count<=1) then exit;
  ReAllocMem(MergeList,List.Count*SizeOf(Pointer));
  Sort(0,List.Count-1);
  Freemem(MergeList);
end;

procedure MergeSort(List: TStrings; const OnCompare: TStringsSortCompare);
var
  MergeList: PAnsiString;

  procedure Merge(Pos1, Pos2, Pos3: PtrInt);
  // merge two sorted arrays
  // the first array ranges Pos1..Pos2-1, the second ranges Pos2..Pos3
  var Src1Pos,Src2Pos,DestPos,cmp,a:integer;
  begin
    while (Pos3>=Pos2) and (OnCompare(List[Pos2-1],List[Pos3])<=0) do
      dec(Pos3);
    if (Pos1>=Pos2) or (Pos2>Pos3) then exit;
    Src1Pos:=Pos2-1;
    Src2Pos:=Pos3;
    DestPos:=Pos3;
    while (Src2Pos>=Pos2) and (Src1Pos>=Pos1) do begin
      cmp:=OnCompare(List[Src1Pos],List[Src2Pos]);
      if cmp>0 then begin
        MergeList[DestPos]:=List[Src1Pos];
        dec(Src1Pos);
      end else begin
        MergeList[DestPos]:=List[Src2Pos];
        dec(Src2Pos);
      end;
      dec(DestPos);
    end;
    while Src2Pos>=Pos2 do begin
      MergeList[DestPos]:=List[Src2Pos];
      dec(Src2Pos);
      dec(DestPos);
    end;
    for a:=DestPos+1 to Pos3 do
      List[a]:=MergeList[a];
  end;

  procedure Sort(StartPos, EndPos: PtrInt);
  // sort an interval in List. Use MergeList as work space.
  var
    cmp, mid: integer;
    s: string;
  begin
    if StartPos=EndPos then begin
    end else if StartPos+1=EndPos then begin
      cmp:=OnCompare(List[StartPos],List[EndPos]);
      if cmp>0 then begin
        s:=List[StartPos];
        List[StartPos]:=List[EndPos];
        List[EndPos]:=s;
      end;
    end else if EndPos>StartPos then begin
      mid:=(StartPos+EndPos) shr 1;
      Sort(StartPos,mid);
      Sort(mid+1,EndPos);
      Merge(StartPos,mid+1,EndPos);
    end;
  end;

var
  CurSize: PtrInt;
  i: PtrInt;
begin
  if (List=nil) or (List.Count<=1) then exit;
  CurSize:=PtrInt(List.Count)*SizeOf(Pointer);
  ReAllocMem(MergeList,CurSize);
  FillChar(MergeList^,CurSize,0);
  Sort(0,List.Count-1);
  for i:=0 to List.Count-1 do MergeList[i]:='';
  Freemem(MergeList);
end;

procedure InitializeDebugOutput;
var
  DebugFileName: string;

  function GetDebugFileName: string;
  const
    DebugLogStart = '--debug-log=';
    DebugLogStartLength = length(DebugLogStart);
  var
    i: integer;
    EnvVarName: string;
  begin
    Result := '';
    // first try to find the log file name in the command line parameters
    for i:= 1 to Paramcount do begin
      if copy(ParamStr(i),1, DebugLogStartLength)=DebugLogStart then begin
        Result := copy(ParamStr(i), DebugLogStartLength+1,
                   Length(ParamStr(i))-DebugLogStartLength);
      end;
    end;
    // if not found yet, then try to find in the environment variables
    if (length(result)=0) then begin
      EnvVarName:= ChangeFileExt(ExtractFileName(Paramstr(0)),'') + '_debuglog';
      Result := GetEnvironmentVariable(EnvVarName);
    end;
    if (length(result)>0) then
      Result := ExpandFileName(Result);
  end;

begin
  DebugText := nil;
  DebugFileName := GetDebugFileName;
  if (length(DebugFileName)>0) and
    (DirPathExists(ExtractFileDir(DebugFileName))) then begin
    new(DebugText);
    try
      Assign(DebugText^, DebugFileName);
      if FileExists(DebugFileName) then
        Append(DebugText^)
      else
        Rewrite(DebugText^);
    except
      Freemem(DebugText);
      DebugText := nil;
      // Add extra line ending: a dialog will be shown in windows gui application
      writeln(StdOut, 'Cannot open file: ', DebugFileName+LineEnding);
    end;
  end;
  if DebugText=nil then
  begin
    if TextRec(Output).Mode=fmClosed then
      DebugText := nil
    else
      DebugText := @Output;
    DebugTextAllocated := false;
  end else
    DebugTextAllocated := true;
end;

procedure FinalizeDebugOutput;
begin
  if DebugTextAllocated then begin
    Close(DebugText^);
    Dispose(DebugText);
    DebugTextAllocated := false;
  end;
end;

procedure DebugLn(Args: array of const);
var
  i: Integer;
begin
  for i:=Low(Args) to High(Args) do begin
    case Args[i].VType of
    vtInteger: DbgOut(dbgs(Args[i].vinteger));
    vtInt64: DbgOut(dbgs(Args[i].VInt64^));
    vtQWord: DbgOut(dbgs(Args[i].VQWord^));
    vtBoolean: DbgOut(dbgs(Args[i].vboolean));
    vtExtended: DbgOut(dbgs(Args[i].VExtended^));
{$ifdef FPC_CURRENCY_IS_INT64}
    // MWE:
    // ppcppc 2.0.2 has troubles in choosing the right dbgs() 
    // so we convert here (i don't know about other versions
    vtCurrency: DbgOut(dbgs(int64(Args[i].vCurrency^)/10000, 4));
{$else}    
    vtCurrency: DbgOut(dbgs(Args[i].vCurrency^));
{$endif}
    vtString: DbgOut(Args[i].VString^);
    vtAnsiString: DbgOut(AnsiString(Args[i].VAnsiString));
    vtChar: DbgOut(Args[i].VChar);
    vtPChar: DbgOut(Args[i].VPChar);
    vtPWideChar: DbgOut(Args[i].VPWideChar);
    vtWideChar: DbgOut(Args[i].VWideChar);
    vtWidestring: DbgOut(WideString(Args[i].VWideString));
    vtObject: DbgOut(DbgSName(Args[i].VObject));
    vtClass: DbgOut(DbgSName(Args[i].VClass));
    vtPointer: DbgOut(Dbgs(Args[i].VPointer));
    else
      DbgOut('?unknown variant?');
    end;
  end;
  DebugLn;
end;

procedure DebugLn(const S: String; Args: array of const);
begin
  DebugLn(Format(S, Args));
end;

procedure DebugLn;
begin
  DebugLn('');
end;

procedure DebugLn(const s: string);
begin
  if not Assigned(DebugText) then exit;
  writeln(DebugText^, ConvertLineEndings(s));
end;

procedure DebugLn(const s1, s2: string);
begin
  DebugLn(s1+s2);
end;

procedure DebugLn(const s1, s2, s3: string);
begin
  DebugLn(s1+s2+s3);
end;

procedure DebugLn(const s1, s2, s3, s4: string);
begin
  DebugLn(s1+s2+s3+s4);
end;

procedure DebugLn(const s1, s2, s3, s4, s5: string);
begin
  DebugLn(s1+s2+s3+s4+s5);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7, s8: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7+s8);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7, s8, s9: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7+s8+s9);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11,
  s12: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12,
  s13: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12+s13);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13,
  s14: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12+s13+s14);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13,
  s14, s15: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12+s13+s14+s15);
end;

procedure DebugLn(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13,
  s14, s15, s16: string);
begin
  DebugLn(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12+s13+s14+s15+s16);
end;

function ConvertLineEndings(const s: string): string;
var
  i: Integer;
  EndingStart: LongInt;
begin
  Result:=s;
  i:=1;
  while (i<=length(Result)) do begin
    if Result[i] in [#10,#13] then begin
      EndingStart:=i;
      inc(i);
      if (i<=length(Result)) and (Result[i] in [#10,#13])
      and (Result[i]<>Result[i-1]) then begin
        inc(i);
      end;
      if (length(LineEnding)<>i-EndingStart)
      or (LineEnding<>copy(Result,EndingStart,length(LineEnding))) then begin
        // line end differs => replace with current LineEnding
        Result:=
          copy(Result,1,EndingStart-1)+LineEnding+copy(Result,i,length(Result));
        i:=EndingStart+length(LineEnding);
      end;
    end else
      inc(i);
  end;
end;

procedure DbgOut(const S: String; Args: array of const);
begin
  DbgOut(Format(S, Args));
end;

procedure DBGOut(const s: string);
begin
  if Assigned(DebugText) then
    write(DebugText^, s);
end;

procedure DBGOut(const s1, s2: string);
begin
  DbgOut(s1+s2);
end;

procedure DbgOut(const s1, s2, s3: string);
begin
  DbgOut(s1+s2+s3);
end;

procedure DbgOut(const s1, s2, s3, s4: string);
begin
  DbgOut(s1+s2+s3+s4);
end;

procedure DbgOut(const s1, s2, s3, s4, s5: string);
begin
  DbgOut(s1+s2+s3+s4+s5);
end;

procedure DbgOut(const s1, s2, s3, s4, s5, s6: string);
begin
  DbgOut(s1+s2+s3+s4+s5+s6);
end;

procedure DbgOut(const s1, s2, s3, s4, s5, s6, s7: string);
begin
  DbgOut(s1+s2+s3+s4+s5+s6+s7);
end;

procedure DbgOut(const s1, s2, s3, s4, s5, s6, s7, s8: string);
begin
  DbgOut(s1+s2+s3+s4+s5+s6+s7+s8);
end;

procedure DbgOut(const s1, s2, s3, s4, s5, s6, s7, s8, s9: string);
begin
  DbgOut(s1+s2+s3+s4+s5+s6+s7+s8+s9);
end;

procedure DbgOut(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10: string);
begin
  DbgOut(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10);
end;

procedure DbgOut(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11: string);
begin
  DbgOut(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11);
end;

procedure DbgOut(const s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12: string
  );
begin
  DbgOut(s1+s2+s3+s4+s5+s6+s7+s8+s9+s10+s11+s12);
end;

function DbgS(const c: cardinal): string;
begin
  Result:=IntToStr(c);
end;

function DbgS(const i: longint): string;
begin
  Result:=IntToStr(i);
end;

function DbgS(const i: int64): string;
begin
  Result:=IntToStr(i);
end;

function DbgS(const q: qword): string;
begin
  Result:=IntToStr(q);
end;

function DbgS(const r: TRect): string;
begin
  Result:=' x1='+IntToStr(r.Left)+',y1='+IntToStr(r.Top)
         +',x2='+IntToStr(r.Right)+',y2='+IntToStr(r.Bottom);
end;

function DbgS(const p: TPoint): string;
begin
  Result:='(x='+IntToStr(p.x)+',y='+IntToStr(p.y)+')';
end;

function DbgS(const p: pointer): string;
begin
  Result:=HexStr(PtrInt(p),2*sizeof(PtrInt));
end;

function DbgS(const e: extended; MaxDecimals: integer): string;
begin
  Result:=copy(FloatToStr(e),1,MaxDecimals);
end;

function DbgS(const b: boolean): string;
begin
  if b then Result:='True' else Result:='False';
end;

function DbgSName(const p: TObject): string;
begin
  if p=nil then
    Result:='nil'
  else if p is TComponent then
    Result:=TComponent(p).Name+':'+p.ClassName
  else
    Result:=p.ClassName;
end;

function DbgSName(const p: TClass): string;
begin
  if p=nil then
    Result:='nil'
  else
    Result:=p.ClassName;
end;

function DbgStr(const StringWithSpecialChars: string): string;
var
  i: Integer;
  s: String;
begin
  Result:=StringWithSpecialChars;
  i:=1;
  while (i<=length(Result)) do begin
    case Result[i] of
    ' '..#126: inc(i);
    else
      s:='#'+HexStr(ord(Result[i]),2);
      Result:=copy(Result,1,i-1)+s+copy(Result,i+1,length(Result)-i);
      inc(i,length(s));
    end;
  end;
end;

function DbgWideStr(const StringWithSpecialChars: widestring): string;
var
  s: String;
  SrcPos: Integer;
  DestPos: Integer;
  i: Integer;
begin
  SetLength(Result,length(StringWithSpecialChars));
  SrcPos:=1;
  DestPos:=1;
  while SrcPos<=length(StringWithSpecialChars) do begin
    i:=ord(StringWithSpecialChars[SrcPos]);
    case i of
    32..126:
      begin
        Result[DestPos]:=chr(i);
        inc(SrcPos);
        inc(DestPos);
      end;
    else
      s:='#'+HexStr(i,4);
      inc(SrcPos);
      Result:=copy(Result,1,DestPos-1)+s+copy(Result,DestPos+1,length(Result));
      inc(DestPos,length(s));
    end;
  end;
end;

function dbgMemRange(P: PByte; Count: integer; Width: integer): string;
const
  HexChars: array[0..15] of char = '0123456789ABCDEF';
  LineEnd: shortstring = LineEnding;
var
  i: Integer;
  NewLen: Integer;
  Dest: PChar;
  Col: Integer;
  j: Integer;
begin
  Result:='';
  if (p=nil) or (Count<=0) then exit;
  NewLen:=Count*2;
  if Width>0 then begin
    inc(NewLen,(Count div Width)*length(LineEnd));
  end;
  SetLength(Result,NewLen);
  Dest:=PChar(Result);
  Col:=1;
  for i:=0 to Count-1 do begin
    Dest^:=HexChars[PByte(P)[i] shr 4];
    inc(Dest);
    Dest^:=HexChars[PByte(P)[i] and $f];
    inc(Dest);
    inc(Col);
    if (Width>0) and (Col>Width) then begin
      Col:=1;
      for j:=1 to length(LineEnd) do begin
        Dest^:=LineEnd[j];
        inc(Dest);
      end;
    end;
  end;
end;

function dbgMemStream(MemStream: TCustomMemoryStream; Count: integer): string;
var
  s: string;
begin
  Result:='';
  if (MemStream=nil) or (not (MemStream is TCustomMemoryStream)) or (Count<=0)
  then exit;
  Count:=Min(Count,MemStream.Size);
  if Count<=0 then exit;
  SetLength(s,Count);
  Count:=MemStream.Read(s[1],Count);
  Result:=dbgMemRange(PByte(s),Count);
end;

function dbgObjMem(AnObject: TObject): string;
begin
  Result:='';
  if AnObject=nil then exit;
  Result:=dbgMemRange(PByte(AnObject),AnObject.InstanceSize);
end;

function dbghex(i: Int64): string;
const
  Hex = '0123456789ABCDEF';
var
  Negated: Boolean;
begin
  Result:='';
  if i<0 then begin
    Negated:=true;
    i:=-i;
  end else
    Negated:=false;
  repeat
    Result:=Hex[(i mod 16)+1]+Result;
    i:=i div 16;
  until i=0;
  if Negated then
    Result:='-'+Result;
end;

function DbgS(const i1, i2, i3, i4: integer): string;
begin
  Result:=dbgs(i1)+','+dbgs(i2)+','+dbgs(i3)+','+dbgs(i4);
end;

function DbgS(const Shift: TShiftState): string;

  procedure Add(const s: string);
  begin
    if Result<>'' then Result:=Result+',';
    Result:=Result+s;
  end;

begin
  Result:='';
  if ssShift in Shift then Add('ssShift');
  if ssAlt in Shift then Add('ssAlt');
  if ssCtrl in Shift then Add('ssCtrl');
  if ssLeft in Shift then Add('ssLeft');
  if ssRight in Shift then Add('ssRight');
  if ssMiddle in Shift then Add('ssMiddle');
  if ssDouble in Shift then Add('ssDouble');
  if ssMeta in Shift then Add('ssMeta');
  if ssSuper in Shift then Add('ssSuper');
  if ssHyper in Shift then Add('ssHyper');
  if ssAltGr in Shift then Add('ssAltGr');
  if ssCaps in Shift then Add('ssCaps');
  if ssNum in Shift then Add('ssNum');
  if ssScroll in Shift then Add('ssScroll');
  if ssTriple in Shift then Add('ssTriple');
  if ssQuad in Shift then Add('ssQuad');
  Result:='['+Result+']';
end;

function DbgsVKCode(c: word): string;
begin
  case c of
  VK_UNKNOWN: Result:='VK_UNKNOWN';
  VK_LBUTTON: Result:='VK_LBUTTON';
  VK_RBUTTON: Result:='VK_RBUTTON';
  VK_CANCEL: Result:='VK_CANCEL';
  VK_MBUTTON: Result:='VK_MBUTTON';
  VK_BACK: Result:='VK_BACK';
  VK_TAB: Result:='VK_TAB';
  VK_CLEAR: Result:='VK_CLEAR';
  VK_RETURN: Result:='VK_RETURN';
  VK_SHIFT: Result:='VK_SHIFT';
  VK_CONTROL: Result:='VK_CONTROL';
  VK_MENU: Result:='VK_MENU';
  VK_PAUSE: Result:='VK_PAUSE';
  VK_CAPITAL: Result:='VK_CAPITAL';
  VK_KANA: Result:='VK_KANA';
  VK_JUNJA: Result:='VK_JUNJA';
  VK_FINAL: Result:='VK_FINAL';
  VK_HANJA: Result:='VK_HANJA';
  VK_ESCAPE: Result:='VK_ESCAPE';
  VK_CONVERT: Result:='VK_CONVERT';
  VK_NONCONVERT: Result:='VK_NONCONVERT';
  VK_ACCEPT: Result:='VK_ACCEPT';
  VK_MODECHANGE: Result:='VK_MODECHANGE';
  VK_SPACE: Result:='VK_SPACE';
  VK_PRIOR: Result:='VK_PRIOR';
  VK_NEXT: Result:='VK_NEXT';
  VK_END: Result:='VK_END';
  VK_HOME: Result:='VK_HOME';
  VK_LEFT: Result:='VK_LEFT';
  VK_UP: Result:='VK_UP';
  VK_RIGHT: Result:='VK_RIGHT';
  VK_DOWN: Result:='VK_DOWN';
  VK_SELECT: Result:='VK_SELECT';
  VK_PRINT: Result:='VK_PRINT';
  VK_EXECUTE: Result:='VK_EXECUTE';
  VK_SNAPSHOT: Result:='VK_SNAPSHOT';
  VK_INSERT: Result:='VK_INSERT';
  VK_DELETE: Result:='VK_DELETE';
  VK_HELP: Result:='VK_HELP';

  VK_0: Result:='VK_0';
  VK_1: Result:='VK_1';
  VK_2: Result:='VK_2';
  VK_3: Result:='VK_3';
  VK_4: Result:='VK_4';
  VK_5: Result:='VK_5';
  VK_6: Result:='VK_6';
  VK_7: Result:='VK_7';
  VK_8: Result:='VK_8';
  VK_9: Result:='VK_9';

  VK_A: Result:='VK_A';
  VK_B: Result:='VK_B';
  VK_C: Result:='VK_C';
  VK_D: Result:='VK_D';
  VK_E: Result:='VK_E';
  VK_F: Result:='VK_F';
  VK_G: Result:='VK_G';
  VK_H: Result:='VK_H';
  VK_I: Result:='VK_I';
  VK_J: Result:='VK_J';
  VK_K: Result:='VK_K';
  VK_L: Result:='VK_L';
  VK_M: Result:='VK_M';
  VK_N: Result:='VK_N';
  VK_O: Result:='VK_O';
  VK_P: Result:='VK_P';
  VK_Q: Result:='VK_Q';
  VK_R: Result:='VK_R';
  VK_S: Result:='VK_S';
  VK_T: Result:='VK_T';
  VK_U: Result:='VK_U';
  VK_V: Result:='VK_V';
  VK_W: Result:='VK_W';
  VK_X: Result:='VK_X';
  VK_Y: Result:='VK_Y';
  VK_Z: Result:='VK_Z';

  VK_LWIN: Result:='VK_LWIN';
  VK_RWIN: Result:='VK_RWIN';
  VK_APPS: Result:='VK_APPS';
  VK_SLEEP: Result:='VK_SLEEP';

  VK_NUMPAD0: Result:='VK_NUMPAD0';
  VK_NUMPAD1: Result:='VK_NUMPAD1';
  VK_NUMPAD2: Result:='VK_NUMPAD2';
  VK_NUMPAD3: Result:='VK_NUMPAD3';
  VK_NUMPAD4: Result:='VK_NUMPAD4';
  VK_NUMPAD5: Result:='VK_NUMPAD5';
  VK_NUMPAD6: Result:='VK_NUMPAD6';
  VK_NUMPAD7: Result:='VK_NUMPAD7';
  VK_NUMPAD8: Result:='VK_NUMPAD8';
  VK_NUMPAD9: Result:='VK_NUMPAD9';
  VK_MULTIPLY: Result:='VK_MULTIPLY';
  VK_ADD: Result:='VK_ADD';
  VK_SEPARATOR: Result:='VK_SEPARATOR';
  VK_SUBTRACT: Result:='VK_SUBTRACT';
  VK_DECIMAL: Result:='VK_DECIMAL';
  VK_DIVIDE: Result:='VK_DIVIDE';
  VK_F1: Result:='VK_F1';
  VK_F2: Result:='VK_F2';
  VK_F3: Result:='VK_F3';
  VK_F4: Result:='VK_F4';
  VK_F5: Result:='VK_F5';
  VK_F6: Result:='VK_F6';
  VK_F7: Result:='VK_F7';
  VK_F8: Result:='VK_F8';
  VK_F9: Result:='VK_F9';
  VK_F10: Result:='VK_F10';
  VK_F11: Result:='VK_F11';
  VK_F12: Result:='VK_F12';
  VK_F13: Result:='VK_F13';
  VK_F14: Result:='VK_F14';
  VK_F15: Result:='VK_F15';
  VK_F16: Result:='VK_F16';
  VK_F17: Result:='VK_F17';
  VK_F18: Result:='VK_F18';
  VK_F19: Result:='VK_F19';
  VK_F20: Result:='VK_F20';
  VK_F21: Result:='VK_F21';
  VK_F22: Result:='VK_F22';
  VK_F23: Result:='VK_F23';
  VK_F24: Result:='VK_F24';

  VK_NUMLOCK: Result:='VK_NUMLOCK';
  VK_SCROLL: Result:='VK_SCROLL';

  VK_LSHIFT: Result:='VK_LSHIFT';
  VK_RSHIFT: Result:='VK_RSHIFT';
  VK_LCONTROL: Result:='VK_LCONTROL';
  VK_RCONTROL: Result:='VK_RCONTROL';
  VK_LMENU: Result:='VK_LMENU';
  VK_RMENU: Result:='VK_RMENU';

  VK_BROWSER_BACK: Result:='VK_BROWSER_BACK';
  VK_BROWSER_FORWARD: Result:='VK_BROWSER_FORWARD';
  VK_BROWSER_REFRESH: Result:='VK_BROWSER_REFRESH';
  VK_BROWSER_STOP: Result:='VK_BROWSER_STOP';
  VK_BROWSER_SEARCH: Result:='VK_BROWSER_SEARCH';
  VK_BROWSER_FAVORITES: Result:='VK_BROWSER_FAVORITES';
  VK_BROWSER_HOME: Result:='VK_BROWSER_HOME';
  VK_VOLUME_MUTE: Result:='VK_VOLUME_MUTE';
  VK_VOLUME_DOWN: Result:='VK_VOLUME_DOWN';
  VK_VOLUME_UP: Result:='VK_VOLUME_UP';
  VK_MEDIA_NEXT_TRACK: Result:='VK_MEDIA_NEXT_TRACK';
  VK_MEDIA_PREV_TRACK: Result:='VK_MEDIA_PREV_TRACK';
  VK_MEDIA_STOP: Result:='VK_MEDIA_STOP';
  VK_MEDIA_PLAY_PAUSE: Result:='VK_MEDIA_PLAY_PAUSE';
  VK_LAUNCH_MAIL: Result:='VK_LAUNCH_MAIL';
  VK_LAUNCH_MEDIA_SELECT: Result:='VK_LAUNCH_MEDIA_SELECT';
  VK_LAUNCH_APP1: Result:='VK_LAUNCH_APP1';
  VK_LAUNCH_APP2: Result:='VK_LAUNCH_APP2';
  else
    Result:='VK_('+dbgs(c)+')';
  end;
end;

procedure DbgOutThreadLog(const Msg: string);
var
  PID: PtrInt;
  fs: TFileStream;
  Filename: string;
begin
  PID:=PtrInt(GetThreadID);
  Filename:='Log'+IntToStr(PID);
  if FileExists(Filename) then
    fs:=TFileStream.Create(Filename,fmOpenWrite)
  else
    fs:=TFileStream.Create(Filename,fmCreate);
  fs.Position:=fs.Size;
  fs.Write(Msg[1], length(Msg));
  fs.Free;
end;

procedure DebuglnThreadLog(const Msg: string);
var
  PID: PtrInt;
begin
  PID:=PtrInt(GetThreadID);
  DbgOutThreadLog(IntToStr(PtrInt(PID))+' : '+Msg+LineEnding);
end;

procedure DebuglnThreadLog(Args: array of const);
var
  i: Integer;
  s: String;
begin
  s:='';
  for i:=Low(Args) to High(Args) do begin
    case Args[i].VType of
    vtInteger: s:=s+dbgs(Args[i].vinteger);
    vtInt64: s:=s+dbgs(Args[i].VInt64^);
    vtQWord: s:=s+dbgs(Args[i].VQWord^);
    vtBoolean: s:=s+dbgs(Args[i].vboolean);
    vtExtended: s:=s+dbgs(Args[i].VExtended^);
{$ifdef FPC_CURRENCY_IS_INT64}
    // MWE:
    // ppcppc 2.0.2 has troubles in choosing the right dbgs()
    // so we convert here (i don't know about other versions
    vtCurrency: s:=s+dbgs(int64(Args[i].vCurrency^)/10000, 4);
{$else}
    vtCurrency: s:=s+dbgs(Args[i].vCurrency^);
{$endif}
    vtString: s:=s+Args[i].VString^;
    vtAnsiString: s:=s+AnsiString(Args[i].VAnsiString);
    vtChar: s:=s+Args[i].VChar;
    vtPChar: s:=s+Args[i].VPChar;
    vtPWideChar: s:=s+Args[i].VPWideChar;
    vtWideChar: s:=s+Args[i].VWideChar;
    vtWidestring: s:=s+WideString(Args[i].VWideString);
    vtObject: s:=s+DbgSName(Args[i].VObject);
    vtClass: s:=s+DbgSName(Args[i].VClass);
    vtPointer: s:=s+Dbgs(Args[i].VPointer);
    else
      DbgOutThreadLog('?unknown variant?');
    end;
  end;
  DebuglnThreadLog(s);
end;

procedure DebuglnThreadLog;
begin
  DebuglnThreadLog('');
end;

function StripLN(const ALine: String): String;
var
  idx: Integer;
begin
  idx := Pos(#10, ALine);
  if idx = 0
  then begin
    idx := Pos(#13, ALine);
    if idx = 0
    then begin
      Result := ALine;
      Exit;
    end;
  end
  else begin
    if (idx > 1)
    and (ALine[idx - 1] = #13)
    then Dec(idx);
  end;
  Result := Copy(ALine, 1, idx - 1);
end;

function GetPart(const ASkipTo, AnEnd: String; var ASource: String): String;
begin
  Result := GetPart([ASkipTo], [AnEnd], ASource, False, True);
end;

function GetPart(const ASkipTo, AnEnd: String; var ASource: String; const AnIgnoreCase: Boolean): String; overload;
begin
  Result := GetPart([ASkipTo], [AnEnd], ASource, AnIgnoreCase, True);
end;

function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String): String; overload;
begin
  Result := GetPart(ASkipTo, AnEnd, ASource, False, True);
end;

function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String; const AnIgnoreCase: Boolean): String; overload;
begin
  Result := GetPart(ASkipTo, AnEnd, ASource, AnIgnoreCase, True);
end;

function GetPart(const ASkipTo, AnEnd: array of String; var ASource: String; const AnIgnoreCase, AnUpdateSource: Boolean): String; overload;
var
  n, i, idx: Integer;
  S, Source, Match: String;
  HasEscape: Boolean;
begin
  Source := ASource;

  if High(ASkipTo) >= 0
  then begin
    idx := 0;
    HasEscape := False;
    if AnIgnoreCase
    then S := UpperCase(Source)
    else S := Source;
    for n := Low(ASkipTo) to High(ASkipTo) do
    begin
      if ASkipTo[n] = ''
      then begin
        HasEscape := True;
        Continue;
      end;
      if AnIgnoreCase
      then i := Pos(UpperCase(ASkipTo[n]), S)
      else i := Pos(ASkipTo[n], S);
      if i > idx
      then begin
        idx := i;
        Match := ASkipTo[n];
      end;
    end;
    if (idx = 0) and not HasEscape
    then begin
      Result := '';
      Exit;
    end;
    if idx > 0
    then Delete(Source, 1, idx + Length(Match) - 1);
  end;

  if AnIgnoreCase
  then S := UpperCase(Source)
  else S := Source;
  idx := MaxInt;
  for n := Low(AnEnd) to High(AnEnd) do
  begin
    if AnEnd[n] = '' then Continue;
    if AnIgnoreCase
    then i := Pos(UpperCase(AnEnd[n]), S)
    else i := Pos(AnEnd[n], S);
    if (i > 0) and (i < idx) then idx := i;
  end;

  if idx = MaxInt
  then begin
    Result := Source;
    Source := '';
  end
  else begin
    Result := Copy(Source, 1, idx - 1);
    Delete(Source, 1, idx - 1);
  end;

  if AnUpdateSource
  then ASource := Source;
end;

function StringCase(const AString: String; const ACase: array of String {; const AIgnoreCase = False, APartial = false: Boolean}): Integer;
begin
  Result := StringCase(AString, ACase, False, False);
end;

function StringCase(const AString: String; const ACase: array of String; const AIgnoreCase, APartial: Boolean): Integer;
var
  Search, S: String;
begin
  if High(ACase) = -1
  then begin
    Result := -1;
    Exit;
  end;

  if AIgnoreCase
  then Search := UpperCase(AString)
  else Search := AString;

  for Result := Low(ACase) to High(ACase) do
  begin
    if AIgnoreCase
    then S := UpperCase(ACase[Result])
    else S := ACase[Result];

    if Search = S then Exit;
    if not APartial then Continue;
    if Length(Search) >= Length(S) then Continue;
    if StrLComp(PChar(Search), PChar(S), Length(Search)) = 0 then Exit;
  end;

  Result := -1;
end;

function ClassCase(const AClass: TClass; const ACase: array of TClass {; const ADecendant: Boolean = True}): Integer;
begin
  Result := ClassCase(AClass, ACase, True);
end;

function ClassCase(const AClass: TClass; const ACase: array of TClass; const ADecendant: Boolean): Integer;
begin
  for Result := Low(ACase) to High(ACase) do
  begin
    if AClass = ACase[Result] then Exit;
    if not ADecendant then Continue;
    if AClass.InheritsFrom(ACase[Result]) then Exit;
  end;

  Result := -1;
end;

function UTF8CharacterLength(p: PChar): integer;
begin
  if p<>nil then begin
    if ord(p^)<%11000000 then begin
      // regular single byte character (#0 is a character, this is pascal ;)
      Result:=1;
    end
    else if ((ord(p^) and %11100000) = %11000000) then begin
      // could be 2 byte character
      if (ord(p[1]) and %11000000) = %10000000 then
        Result:=2
      else
        Result:=1;
    end
    else if ((ord(p^) and %11110000) = %11100000) then begin
      // could be 3 byte character
      if ((ord(p[1]) and %11000000) = %10000000)
      and ((ord(p[2]) and %11000000) = %10000000) then
        Result:=3
      else
        Result:=1;
    end
    else if ((ord(p^) and %11111000) = %11110000) then begin
      // could be 4 byte character
      if ((ord(p[1]) and %11000000) = %10000000)
      and ((ord(p[2]) and %11000000) = %10000000)
      and ((ord(p[3]) and %11000000) = %10000000) then
        Result:=4
      else
        Result:=1;
    end
    else
      Result:=1
  end else
    Result:=0;
end;

function UTF8Length(const s: string): integer;
begin
  Result:=UTF8Length(PChar(s),length(s));
end;

function UTF8Length(p: PChar; ByteCount: integer): integer;
var
  CharLen: LongInt;
begin
  Result:=0;
  while (ByteCount>0) do begin
    inc(Result);
    CharLen:=UTF8CharacterLength(p);
    inc(p,CharLen);
    dec(ByteCount,CharLen);
  end;
end;

function UTF8CharacterToUnicode(p: PChar; out CharLen: integer): Cardinal;
begin
  if p<>nil then begin
    if ord(p^)<%11000000 then begin
      // regular single byte character (#0 is a normal char, this is pascal ;)
      Result:=ord(p^);
      CharLen:=1;
    end
    else if ((ord(p^) and %11100000) = %11000000) then begin
      // could be double byte character
      if (ord(p[1]) and %11000000) = %10000000 then begin
        Result:=((ord(p^) and %00011111) shl 6)
                or (ord(p[1]) and %00111111);
        CharLen:=2;
      end else begin
        Result:=ord(p^);
        CharLen:=1;
      end;
    end
    else if ((ord(p^) and %11110000) = %11100000) then begin
      // could be triple byte character
      if ((ord(p[1]) and %11000000) = %10000000)
      and ((ord(p[2]) and %11000000) = %10000000) then begin
        Result:=((ord(p^) and %00011111) shl 12)
                or ((ord(p[1]) and %00111111) shl 6)
                or (ord(p[2]) and %00111111);
        CharLen:=3;
      end else begin
        Result:=ord(p^);
        CharLen:=1;
      end;
    end
    else if ((ord(p^) and %11111000) = %11110000) then begin
      // could be 4 byte character
      if ((ord(p[1]) and %11000000) = %10000000)
      and ((ord(p[2]) and %11000000) = %10000000)
      and ((ord(p[3]) and %11000000) = %10000000) then begin
        Result:=((ord(p^) and %00011111) shl 18)
                or ((ord(p[1]) and %00111111) shl 12)
                or ((ord(p[2]) and %00111111) shl 6)
                or (ord(p[3]) and %00111111);
        CharLen:=4;
      end else begin
        Result:=ord(p^);
        CharLen:=1;
      end;
    end
    else begin
      Result:=ord(p^);
      CharLen:=1;
    end;
  end else begin
    Result:=0;
    CharLen:=0;
  end;
end;

function UnicodeToUTF8(u: cardinal): string;

  procedure RaiseInvalidUnicode;
  begin
    raise Exception.Create('UnicodeToUTF8: invalid unicode: '+IntToStr(u));
  end;

begin
  case u of
    0..$7f:
      begin
        SetLength(Result,1);
        Result[1]:=char(byte(u));
      end;
    $80..$7ff:
      begin
        SetLength(Result,2);
        Result[1]:=char(byte($c0 or (u shr 6)));
        Result[2]:=char(byte($80 or (u and $3f)));
      end;
    $800..$ffff:
      begin
        SetLength(Result,3);
        Result[1]:=char(byte($e0 or (u shr 12)));
        Result[2]:=char(byte((u shr 6) and $3f) or $80);
        Result[3]:=char(byte(u and $3f) or $80);
      end;
    $10000..$1fffff:
      begin
        SetLength(Result,4);
        Result[1]:=char(byte($f0 or (u shr 18)));
        Result[2]:=char(byte((u shr 12) and $3f) or $80);
        Result[3]:=char(byte((u shr 6) and $3f) or $80);
        Result[4]:=char(byte(u and $3f) or $80);
      end;
  else
    RaiseInvalidUnicode;
  end;
end;

function UTF8ToDoubleByteString(const s: string): string;
var
  Len: Integer;
begin
  Len:=UTF8Length(s);
  SetLength(Result,Len*2);
  if Len=0 then exit;
  UTF8ToDoubleByte(PChar(s),length(s),PByte(Result));
end;

function UTF8ToDoubleByte(UTF8Str: PChar; Len: integer; DBStr: PByte): integer;
// returns number of double bytes
var
  SrcPos: PChar;
  CharLen: LongInt;
  DestPos: PByte;
  u: Cardinal;
begin
  SrcPos:=UTF8Str;
  DestPos:=DBStr;
  Result:=0;
  while Len>0 do begin
    u:=UTF8CharacterToUnicode(SrcPos,CharLen);
    DestPos^:=byte((u shr 8) and $ff);
    inc(DestPos);
    DestPos^:=byte(u and $ff);
    inc(DestPos);
    inc(SrcPos,CharLen);
    dec(Len,CharLen);
    inc(Result);
  end;
end;

function UTF8FindNearestCharStart(UTF8Str: PChar; Len: integer;
  BytePos: integer): integer;
var
  CharLen: LongInt;
begin
  Result:=0;
  if UTF8Str<>nil then begin
    if BytePos>Len then BytePos:=Len;
    while (BytePos>0) do begin
      CharLen:=UTF8CharacterLength(UTF8Str);
      dec(BytePos,CharLen);
      if (BytePos<0) then exit;
      inc(Result,CharLen);
      if (BytePos=0) then exit;
    end;
  end;
end;

function UTF8CharStart(UTF8Str: PChar; Len, Index: integer): PChar;
var
  CharLen: LongInt;
begin
  Result:=UTF8Str;
  if Result<>nil then begin
    while (Index>0) and (Len>0) do begin
      CharLen:=UTF8CharacterLength(Result);
      dec(Len,CharLen);
      dec(Index);
      inc(Result,CharLen);
    end;
    if (Index>0) or (Len<0) then
      Result:=nil;
  end;
end;

procedure UTF8FixBroken(P: PChar);
// fix any broken UTF8 sequences with spaces
begin
  if p=nil then exit;
  while p^<>#0 do begin
    if ord(p^)<%11000000 then begin
      // regular single byte character
      inc(p);
    end
    else if ((ord(p^) and %11100000) = %11000000) then begin
      // should be 2 byte character
      if (ord(p[1]) and %11000000) = %10000000 then
        inc(p,2)
      else if p[1]<>#0 then
        p^:=' ';
    end
    else if ((ord(p^) and %11110000) = %11100000) then begin
      // should be 3 byte character
      if ((ord(p[1]) and %11000000) = %10000000)
      and ((ord(p[2]) and %11000000) = %10000000) then
        inc(p,3)
      else
        p^:=' ';
    end
    else if ((ord(p^) and %11111000) = %11110000) then begin
      // should be 4 byte character
      if ((ord(p[1]) and %11000000) = %10000000)
      and ((ord(p[2]) and %11000000) = %10000000)
      and ((ord(p[3]) and %11000000) = %10000000) then
        inc(p,4)
      else
        p^:=' ';
    end
  end;
end;

function UTF8CStringToUTF8String(SourceStart: PChar; SourceLen: SizeInt) : string;
var
  Source: PChar;
  Dest: PChar;
  SourceEnd: PChar;
  CharLen: integer;
  SourceCopied: PChar;

  // Copies from SourceStart till Source to Dest and updates Dest
  procedure CopyPart; inline;
  var
    CopyLength: SizeInt;
  begin
    CopyLength := Source - SourceCopied;
    if CopyLength=0 then exit;
    move(SourceCopied^ , Dest^, CopyLength);
    SourceCopied:=Source;
    inc(Dest, CopyLength);
  end;

begin
  SetLength(Result, SourceLen);
  if SourceLen=0 then exit;
  SourceCopied:=SourceStart;
  Source:=SourceStart;
  Dest:=PChar(Result);
  SourceEnd := Source + SourceLen;
  while Source<SourceEnd do begin
    CharLen := UTF8CharacterLength(Source);
    if (CharLen=1) and (Source^='\') then begin
      CopyPart;
      inc(Source);
      if Source^ in ['t', 'n', '"', '\'] then begin
        case Source^ of
         't' : Dest^ := #9;
         '"' : Dest^ := '"';
         '\' : Dest^ := '\';
         'n' :
         // fpc 2.1.1 stores string constants as array of char so maybe this
         // will work for without ifdef (once available in 2.0.x too):
         // move(lineending, dest^, sizeof(LineEnding));
{$IFDEF WINDOWS}
               begin
                 move(lineending[1], dest^, length(LineEnding));
                 inc(dest^, length(LineEnding)-1);
               end;
{$ELSE}
               Dest^ := LineEnding;
{$ENDIF}
        end;
        inc(Source);
        inc(Dest);
      end;
      SourceCopied := Source;
    end
    else
      Inc(Source, CharLen);
  end;
  CopyPart;
  SetLength(Result, Dest - PChar(Result));
end;

function UTF8Pos(const SearchForText, SearchInText: string): integer;
// returns the character index, where the SearchForText starts in SearchInText
var
  p: LongInt;
begin
  p:=System.Pos(SearchForText,SearchInText);
  if p>0 then
    Result:=UTF8Length(PChar(SearchInText),p-1)+1
  else
    Result:=0;
end;

function UTF8Copy(const s: string; StartCharIndex, CharCount: integer): string;
// returns substring
var
  StartBytePos: PChar;
  EndBytePos: PChar;
  MaxBytes: PtrInt;
begin
  StartBytePos:=UTF8CharStart(PChar(s),length(s),StartCharIndex-1);
  if StartBytePos=nil then
    Result:=''
  else begin
    MaxBytes:=PtrInt(PChar(s)+length(s)-StartBytePos);
    EndBytePos:=UTF8CharStart(StartBytePos,MaxBytes,CharCount);
    if EndBytePos=nil then
      Result:=copy(s,StartBytePos-PChar(s)+1,MaxBytes)
    else
      Result:=copy(s,StartBytePos-PChar(s)+1,EndBytePos-StartBytePos);
  end;
end;

function FindInvalidUTF8Character(p: PChar; Count: integer;
  StopOnNonASCII: Boolean): integer;
// return -1 if ok
var
  CharLen: Integer;
begin
  if p<>nil then begin
    Result:=0;
    while Result<Count do begin
      if ord(p^)<128 then begin
        // regular single byte ASCII character (#0 is a character, this is pascal ;)
        CharLen:=1;
      end
      else if ord(p^)<%11000000 then begin
        // regular single byte character
        if StopOnNonASCII then
          exit;
        CharLen:=1;
      end
      else if ((ord(p^) and %11100000) = %11000000) then begin
        // could be 2 byte character
        if (ord(p[1]) and %11000000) = %10000000 then
          CharLen:=2
        else
          exit; // missing following bytes
      end
      else if ((ord(p^) and %11110000) = %11100000) then begin
        // could be 3 byte character
        if ((ord(p[1]) and %11000000) = %10000000)
        and ((ord(p[2]) and %11000000) = %10000000) then
          CharLen:=3
        else
          exit; // missing following bytes
      end
      else if ((ord(p^) and %11111000) = %11110000) then begin
        // could be 4 byte character
        if ((ord(p[1]) and %11000000) = %10000000)
        and ((ord(p[2]) and %11000000) = %10000000)
        and ((ord(p[3]) and %11000000) = %10000000) then
          CharLen:=4
        else
          exit; // missing following bytes
      end
      else begin
        if StopOnNonASCII then
          exit;
        CharLen:=1;
      end;
      inc(Result,CharLen);
      if Result>Count then begin
        dec(Result,CharLen);
        exit; // missing following bytes
      end;
    end;
  end;
  // ok
  Result:=-1;
end;

function UTF16CharacterLength(p: PWideChar): integer;
// returns length of UTF16 character in number of words
// The endianess of the machine will be taken.
begin
  if p<>nil then begin
    if ord(p[0])<$D800 then
      Result:=1
    else
      Result:=2;
  end else begin
    Result:=0;
  end;
end;

function UTF16Length(const s: widestring): integer;
begin
  Result:=UTF16Length(PWideChar(s),length(s));
end;

function UTF16Length(p: PWideChar; WordCount: integer): integer;
var
  CharLen: LongInt;
begin
  Result:=0;
  while (WordCount>0) do begin
    inc(Result);
    CharLen:=UTF16CharacterLength(p);
    inc(p,CharLen);
    dec(WordCount,CharLen);
  end;
end;

function UTF16CharacterToUnicode(p: PWideChar; out CharLen: integer): Cardinal;
var
  w1: cardinal;
  w2: Cardinal;
begin
  if p<>nil then begin
    w1:=ord(p[0]);
    if w1<$D800 then begin
      // is 1 word character
      Result:=w1;
      CharLen:=1;
    end else begin
      // could be 2 word character
      w2:=ord(p[1]);
      if (w2>=$DC00) then begin
        // is 2 word character
        Result:=(w1-$D800) shl 10 + (w2-$DC00);
        CharLen:=2;
      end else begin
        // invalid character
        Result:=w1;
        CharLen:=1;
      end;
    end;
  end else begin
    Result:=0;
    CharLen:=0;
  end;
end;

function UnicodeToUTF16(u: cardinal): widestring;
begin
  if u<$D800 then
    Result:=widechar(u)
  else
    Result:=widechar($D800+(u shr 10))+widechar($DC00+(u and $3ff));
end;

function CreateFirstIdentifier(const Identifier: string): string;
// example: Ident59 becomes Ident1
var
  p: Integer;
begin
  p:=length(Identifier);
  while (p>=1) and (Identifier[p] in ['0'..'9']) do dec(p);
  Result:=copy(Identifier,1,p)+'1';
end;

function CreateNextIdentifier(const Identifier: string): string;
// example: Ident59 becomes Ident60
var
  p: Integer;
begin
  p:=length(Identifier);
  while (p>=1) and (Identifier[p] in ['0'..'9']) do dec(p);
  Result:=copy(Identifier,1,p)
          +IntToStr(1+StrToIntDef(copy(Identifier,p+1,length(Identifier)-p),0));
end;


//==============================================================================
// Endian utils
//==============================================================================
{$R-}
function BEtoN(const AValue: SmallInt): SmallInt;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shr 8) or (AValue shl 8);
  {$ENDIF}
end;

function BEtoN(const AValue: Word): Word;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shr 8) or (AValue shl 8);
  {$ENDIF}
end;

function BEtoN(const AValue: LongInt): LongInt;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 24)
           or ((AValue and $0000FF00) shl 8)
           or ((AValue and $00FF0000) shr 8)
           or (AValue shr 24);
  {$ENDIF}
end;

function BEtoN(const AValue: DWord): DWord;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 24)
           or ((AValue and $0000FF00) shl 8)
           or ((AValue and $00FF0000) shr 8)
           or (AValue shr 24);
  {$ENDIF}
end;

function BEtoN(const AValue: Int64): Int64;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 56)
           or ((AValue and $000000000000FF00) shl 40)
           or ((AValue and $0000000000FF0000) shl 24)
           or ((AValue and $00000000FF000000) shl 8)
           or ((AValue and $000000FF00000000) shr 8)
           or ((AValue and $0000FF0000000000) shr 24)
           or ((AValue and $00FF000000000000) shr 40)
           or (AValue shr 56);
  {$ENDIF}
end;

function BEtoN(const AValue: QWord): QWord;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 56)
           or ((AValue and $000000000000FF00) shl 40)
           or ((AValue and $0000000000FF0000) shl 24)
           or ((AValue and $00000000FF000000) shl 8)
           or ((AValue and $000000FF00000000) shr 8)
           or ((AValue and $0000FF0000000000) shr 24)
           or ((AValue and $00FF000000000000) shr 40)
           or (AValue shr 56);
  {$ENDIF}
end;

function LEtoN(const AValue: SmallInt): SmallInt;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shr 8) or (AValue shl 8);
  {$ENDIF}
end;

function LEtoN(const AValue: Word): Word;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shr 8) or (AValue shl 8);
  {$ENDIF}
end;

function LEtoN(const AValue: LongInt): LongInt;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 24)
           or ((AValue and $0000FF00) shl 8)
           or ((AValue and $00FF0000) shr 8)
           or (AValue shr 24);
  {$ENDIF}
end;

function LEtoN(const AValue: DWord): DWord;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 24)
           or ((AValue and $0000FF00) shl 8)
           or ((AValue and $00FF0000) shr 8)
           or (AValue shr 24);
  {$ENDIF}
end;

function LEtoN(const AValue: Int64): Int64;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 56)
           or ((AValue and $000000000000FF00) shl 40)
           or ((AValue and $0000000000FF0000) shl 24)
           or ((AValue and $00000000FF000000) shl 8)
           or ((AValue and $000000FF00000000) shr 8)
           or ((AValue and $0000FF0000000000) shr 24)
           or ((AValue and $00FF000000000000) shr 40)
           or (AValue shr 56);
  {$ENDIF}
end;

function LEtoN(const AValue: QWord): QWord;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 56)
           or ((AValue and $000000000000FF00) shl 40)
           or ((AValue and $0000000000FF0000) shl 24)
           or ((AValue and $00000000FF000000) shl 8)
           or ((AValue and $000000FF00000000) shr 8)
           or ((AValue and $0000FF0000000000) shr 24)
           or ((AValue and $00FF000000000000) shr 40)
           or (AValue shr 56);
  {$ENDIF}
end;

function NtoBE(const AValue: SmallInt): SmallInt;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shr 8) or (AValue shl 8);
  {$ENDIF}
end;

function NtoBE(const AValue: Word): Word;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shr 8) or (AValue shl 8);
  {$ENDIF}
end;

function NtoBE(const AValue: LongInt): LongInt;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 24)
           or ((AValue and $0000FF00) shl 8)
           or ((AValue and $00FF0000) shr 8)
           or (AValue shr 24);
  {$ENDIF}
end;

function NtoBE(const AValue: DWord): DWord;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 24)
           or ((AValue and $0000FF00) shl 8)
           or ((AValue and $00FF0000) shr 8)
           or (AValue shr 24);
  {$ENDIF}
end;

function NtoBE(const AValue: Int64): Int64;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 56)
           or ((AValue and $000000000000FF00) shl 40)
           or ((AValue and $0000000000FF0000) shl 24)
           or ((AValue and $00000000FF000000) shl 8)
           or ((AValue and $000000FF00000000) shr 8)
           or ((AValue and $0000FF0000000000) shr 24)
           or ((AValue and $00FF000000000000) shr 40)
           or (AValue shr 56);
  {$ENDIF}
end;

function NtoBE(const AValue: QWord): QWord;
begin
  {$IFDEF ENDIAN_BIG}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 56)
           or ((AValue and $000000000000FF00) shl 40)
           or ((AValue and $0000000000FF0000) shl 24)
           or ((AValue and $00000000FF000000) shl 8)
           or ((AValue and $000000FF00000000) shr 8)
           or ((AValue and $0000FF0000000000) shr 24)
           or ((AValue and $00FF000000000000) shr 40)
           or (AValue shr 56);
  {$ENDIF}
end;

function NtoLE(const AValue: SmallInt): SmallInt;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shr 8) or (AValue shl 8);
  {$ENDIF}
end;

function NtoLE(const AValue: Word): Word;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shr 8) or (AValue shl 8);
  {$ENDIF}
end;

function NtoLE(const AValue: LongInt): LongInt;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 24)
           or ((AValue and $0000FF00) shl 8)
           or ((AValue and $00FF0000) shr 8)
           or (AValue shr 24);
  {$ENDIF}
end;

function NtoLE(const AValue: DWord): DWord;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 24)
           or ((AValue and $0000FF00) shl 8)
           or ((AValue and $00FF0000) shr 8)
           or (AValue shr 24);
  {$ENDIF}
end;

function NtoLE(const AValue: Int64): Int64;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 56)
           or ((AValue and $000000000000FF00) shl 40)
           or ((AValue and $0000000000FF0000) shl 24)
           or ((AValue and $00000000FF000000) shl 8)
           or ((AValue and $000000FF00000000) shr 8)
           or ((AValue and $0000FF0000000000) shr 24)
           or ((AValue and $00FF000000000000) shr 40)
           or (AValue shr 56);
  {$ENDIF}
end;

function NtoLE(const AValue: QWord): QWord;
begin
  {$IFDEF ENDIAN_LITTLE}
    Result := AValue;
  {$ELSE}
    Result := (AValue shl 56)
           or ((AValue and $000000000000FF00) shl 40)
           or ((AValue and $0000000000FF0000) shl 24)
           or ((AValue and $00000000FF000000) shl 8)
           or ((AValue and $000000FF00000000) shr 8)
           or ((AValue and $0000FF0000000000) shr 24)
           or ((AValue and $00FF000000000000) shr 40)
           or (AValue shr 56);
  {$ENDIF}
end;

procedure FreeLineInfoCache;
var
  ANode: TAvgLvlTreeNode;
  Item: PLineInfoCacheItem;
begin
  if LineInfoCache=nil then exit;
  ANode:=LineInfoCache.FindLowest;
  while ANode<>nil do begin
    Item:=PLineInfoCacheItem(ANode.Data);
    Dispose(Item);
    ANode:=LineInfoCache.FindSuccessor(ANode);
  end;
  LineInfoCache.Free;
  LineInfoCache:=nil;
end;

{ TDebugLCLItems }

constructor TDebugLCLItems.Create;
begin
  FItems:=TAvgLvlTree.Create(@CompareDebugLCLItemInfos);
end;

destructor TDebugLCLItems.Destroy;
begin
  FItems.FreeAndClear;
  FreeAndNil(FItems);
  inherited Destroy;
end;

function TDebugLCLItems.FindInfo(p: Pointer; CreateIfNotExists: boolean
  ): TDebugLCLItemInfo;
var
  ANode: TAvgLvlTreeNode;
begin
  ANode:=FItems.FindKey(p,@CompareItemWithDebugLCLItemInfo);
  if ANode<>nil then
    Result:=TDebugLCLItemInfo(ANode.Data)
  else begin
    // does not yet exists
    if CreateIfNotExists then begin
      Result:=MarkCreated(p,'TDebugLCLItems.FindInfo');
    end else begin
      Result:=nil;
    end;
  end;
end;

function TDebugLCLItems.IsDestroyed(p: Pointer): boolean;
var
  Info: TDebugLCLItemInfo;
begin
  Info:=FindInfo(p);
  if Info=nil then
    Result:=false
  else
    Result:=Info.IsDestroyed;
end;

function TDebugLCLItems.IsCreated(p: Pointer): boolean;
var
  Info: TDebugLCLItemInfo;
begin
  Info:=FindInfo(p);
  if Info=nil then
    Result:=false
  else
    Result:=not Info.IsDestroyed;
end;

procedure TDebugLCLItems.MarkDestroyed(p: Pointer);
var
  Info: TDebugLCLItemInfo;

  procedure RaiseNotCreated;
  begin
    DebugLn('TDebugLCLItems.MarkDestroyed not created: p=',dbgs(p));
    DumpStack;
    RaiseGDBException('TDebugLCLItems.MarkDestroyed');
  end;

  procedure RaiseDoubleDestroyed;
  begin
    debugLn('TDebugLCLItems.MarkDestroyed Double destroyed:');
    debugln(Info.AsString(true));
    debugln('Now:');
    DebugLn(GetStackTrace(true));
    RaiseGDBException('RaiseDoubleDestroyed');
  end;

begin
  Info:=FindInfo(p);
  if Info=nil then
    RaiseNotCreated;
  if Info.IsDestroyed then
    RaiseDoubleDestroyed;
  Info.IsDestroyed:=true;
  GetStackTracePointers(Info.DestructionStack);
end;

function TDebugLCLItems.GetInfo(p: Pointer; WithStackTraces: boolean): string;
var
  Info: TDebugLCLItemInfo;
begin
  Info:=FindInfo(p,false);
  if Info<>nil then
    Result:=Info.AsString(WithStackTraces)
  else
    Result:='';
end;

function TDebugLCLItems.MarkCreated(p: Pointer;
  const InfoText: string): TDebugLCLItemInfo;
var
  Info: TDebugLCLItemInfo;

  procedure RaiseDoubleCreated;
  begin
    debugLn('TDebugLCLItems.MarkCreated CREATED TWICE. Old:');
    debugln(Info.AsString(true));
    debugln(' New=',dbgs(p),' InfoText="',InfoText,'"');
    DebugLn(GetStackTrace(true));
    RaiseGDBException('RaiseDoubleCreated');
  end;

begin
  Info:=FindInfo(p);
  if Info=nil then begin
    Info:=TDebugLCLItemInfo.Create;
    Info.Item:=p;
    FItems.Add(Info);
  end else if not Info.IsDestroyed then begin
    RaiseDoubleCreated;
  end;
  Info.IsDestroyed:=false;
  Info.Info:=InfoText;
  GetStackTracePointers(Info.CreationStack);
  SetLength(Info.DestructionStack,0);
  Result:=Info;
end;

{ TDebugLCLItemInfo }

function TDebugLCLItemInfo.AsString(WithStackTraces: boolean): string;
begin
  Result:='Item='+Dbgs(Item)+LineEnding
          +'Info="'+DbgStr(Info)+LineEnding;
  if WithStackTraces then
    Result:=Result+'Creation:'+LineEnding+StackTraceAsString(CreationStack,true);
  if IsDestroyed then begin
    Result:=Result+'Destroyed:'+LineEnding;
    if WithStackTraces then
      Result:=Result+StackTraceAsString(DestructionStack,true);
  end;
end;

destructor TDebugLCLItemInfo.Destroy;
begin
  SetLength(CreationStack,0);
  SetLength(DestructionStack,0);
  inherited Destroy;
end;

initialization
  InitializeDebugOutput;
  InterfaceFinalizationHandlers:=TFPList.Create;
  {$IFDEF DebugLCLComponents}
  DebugLCLComponents:=TDebugLCLItems.Create;
  {$ENDIF}
finalization
  InterfaceFinalizationHandlers.Free;
  InterfaceFinalizationHandlers:=nil;
  {$IFDEF DebugLCLComponents}
  DebugLCLComponents.Free;
  DebugLCLComponents:=nil;
  {$ENDIF}
  FreeLineInfoCache;
  FinalizeDebugOutput;

end.
