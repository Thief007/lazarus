{
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
unit ModeMatrixOpts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, LazConfigStorage, Laz2_XMLCfg, LazLogger,
  FileProcs, KeywordFuncLists, CodeToolsCfgScript, LazarusIDEStrConsts;

const
  BuildMatrixProjectName = '#project';
type
  TBuildMatrixOptionType = (
    bmotCustom,  // append fpc parameters in Value
    bmotOutDir,  // override output directory -FU of target
    bmotIDEMacro // MacroName and Value
    );
  TBuildMatrixOptionTypes = set of TBuildMatrixOptionType;

const
  BuildMatrixOptionTypeNames: array[TBuildMatrixOptionType] of string = (
    'Custom',
    'OutDir',
    'IDEMacro'
    );

type
  TBuildMatrixGroupType = (
    bmgtEnvironment,
    bmgtProject,
    bmgtSession
    );
  TBuildMatrixGroupTypes = set of TBuildMatrixGroupType;
const
  bmgtAll = [low(TBuildMatrixGroupType)..high(TBuildMatrixGroupType)];

type
  TIsModeEvent = function(const ModeIdentifier: string): boolean of object;

  TBuildMatrixOptions = class;

  TBMModesType = (
    bmmtStored,
    bmmtActive
    );
  TBMModesTypes = set of TBMModesType;

  { TBuildMatrixOption }

  TBuildMatrixOption = class(TPersistent)
  private
    FID: string;
    FList: TBuildMatrixOptions;
    FMacroName: string;
    FModes: array[TBMModesType] of string;
    FTargets: string;
    FTyp: TBuildMatrixOptionType;
    FValue: string;
    function GetModes(Typ: TBMModesType): string;
    procedure SetMacroName(AValue: string);
    procedure SetModes(Typ: TBMModesType; AValue: string);
    procedure SetTargets(AValue: string);
    procedure SetTyp(AValue: TBuildMatrixOptionType);
    procedure SetValue(AValue: string);
  public
    procedure Assign(Source: TPersistent); override;
    constructor Create(aList: TBuildMatrixOptions);
    destructor Destroy; override;
    function FitsTarget(const Target: string): boolean;
    function FitsMode(const Mode: string; aTyp: TBMModesType): boolean;
    property List: TBuildMatrixOptions read FList;
    property ID: string read FID write FID;
    property Targets: string read FTargets write SetTargets;
    property Modes[Typ: TBMModesType]: string read GetModes write SetModes; // modes separated by line breaks, case insensitive
    property Typ: TBuildMatrixOptionType read FTyp write SetTyp;
    property MacroName: string read FMacroName write SetMacroName;
    property Value: string read FValue write SetValue;
    function Equals(Obj: TObject): boolean; override;
    function GetModesSeparatedByComma(aTyp: TBMModesType): string;
    procedure SetModesFromCommaSeparatedList(aList: string; aTyp: TBMModesType);
    procedure DisableModes(const DisableModeEvent: TIsModeEvent; aTyp: TBMModesType);
    procedure EnableMode(const aMode: string; aTyp: TBMModesType);
    procedure LoadFromConfig(Cfg: TConfigStorage);
    procedure SaveToConfig(Cfg: TConfigStorage);
    procedure LoadFromXMLConfig(Cfg: TXMLConfig; const aPath: string);
    procedure SaveToXMLConfig(Cfg: TXMLConfig; const aPath: string);
    function AsString: string;
  end;

  { TBuildMatrixOptions }

  TBuildMatrixOptions = class(TPersistent)
  private
    FChangeStep: int64;
    fSavedChangeStep: int64;
    fClearing: boolean;
    fItems: TObjectList; // list of TBuildMatrixOption
    FOnChanged: TNotifyEvent;
    FOnChangesd: TNotifyEvent;
    function GetItems(Index: integer): TBuildMatrixOption;
    function GetModified: boolean;
    procedure SetModified(AValue: boolean);
  public
    procedure Assign(Source: TPersistent); override;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure DisableModes(const IsModeEvent: TIsModeEvent; aTyp: TBMModesType);
    function Count: integer;
    property Items[Index: integer]: TBuildMatrixOption read GetItems; default;
    function IndexOf(Option: TBuildMatrixOption): integer;
    function Add(Typ: TBuildMatrixOptionType = bmotCustom; Targets: string = '*'): TBuildMatrixOption;
    procedure Delete(Index: integer);

    // equals, modified
    property ChangeStep: int64 read FChangeStep;
    procedure IncreaseChangeStep;
    function Equals(Obj: TObject): boolean; override;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChangesd;
    property Modified: boolean read GetModified write SetModified;

    // load, save
    procedure LoadFromConfig(Cfg: TConfigStorage);
    procedure SaveToConfig(Cfg: TConfigStorage);
    procedure LoadFromXMLConfig(Cfg: TXMLConfig; const aPath: string);
    procedure SaveToXMLConfig(Cfg: TXMLConfig; const aPath: string);

    // queries
    procedure AppendCustomOptions(Target, ActiveMode: string; var Options: string);
    procedure GetOutputDirectory(Target, ActiveMode: string; var OutDir: string);
    function FindOption(const ID: string): TBuildMatrixOption;
  end;

  EMMMacroSyntaxException = class(Exception)
  end;


function BuildMatrixTargetFits(Target, Targets: string): boolean;
function BuildMatrixTargetFitsPattern(Target, Pattern: PChar): boolean;
function CheckBuildMatrixTargetsSyntax(const Targets: String): String;
function BuildMatrixModeFits(Mode, ModesSeparatedByLineBreaks: string): boolean;
function Str2BuildMatrixOptionType(const s: string): TBuildMatrixOptionType;
function CreateBuildMatrixOptionGUID: string;

function SplitMatrixMacro(MacroAssignment: string;
  out MacroName, MacroValue: string; ExceptionOnError: boolean): boolean;
procedure ApplyBuildMatrixMacros(Options: TBuildMatrixOptions; Target: string;
  CfgVars: TCTCfgScriptVariables);

implementation

function BuildMatrixTargetFits(Target, Targets: string): boolean;
{ case insensitive
  * = all
  a = fits a and A
  a* = fits all starting with a
  a? = fits all two letter names starting with a

  Comma and minus:
    Fits if there is at least one positive match and no negative match
  a,b = fits a or b
  -a = if target is a, stop immediately with 'false'
  -ab,a* = fits all beginning with a except for ab
  a*,-ab = fits all beginning with a, the -ab is ignored
}
var
  p: PChar;
  Negated: Boolean;
begin
  Result:=false;
  if (Targets='') or (Target='') then exit;
  p:=PChar(Targets);
  repeat
    if p^='-' then begin
      Negated:=true;
      inc(p);
    end else
      Negated:=false;
    if BuildMatrixTargetFitsPattern(PChar(Target),p) then begin
      if Negated then begin
        exit(false);
      end else begin
        Result:=true;
      end;
    end;
    while not (p^ in [',',#0]) do
      inc(p);
    while p^=',' do
      inc(p);
  until p^=#0;
end;

function BuildMatrixTargetFitsPattern(Target, Pattern: PChar): boolean;
// Pattern ends at #0 or comma
// ? means one arbitrary character
// * means any arbitrary characters, even none
begin
  Result:=false;
  if (Target=nil) or (Target^=#0) or (Pattern=nil) or (Pattern^ in [#0,',']) then
    exit;
  repeat
    case Pattern^ of
    #0,',':
      begin
        // end of pattern reached
        Result:=Target^=#0;
        exit;
      end;
    '?':
      begin
        // one arbitrary character
        if Target^=#0 then
          exit;
        inc(Pattern);
        inc(Target);
      end;
    '*':
      begin
        repeat
          inc(Pattern);
        until Pattern^<>'*';
        if Pattern^ in [#0,','] then
          exit(true);
        // behind the * comes a none * => check recursively all combinations
        while Target^<>#0 do begin
          if BuildMatrixTargetFitsPattern(Target,Pattern) then
            exit(true);
          inc(Target);
        end;
        exit;
      end;
    'a'..'z','A'..'Z':
      begin
        if UpChars[Pattern^]<>UpChars[Target^] then
          exit;
        inc(Pattern);
        inc(Target)
      end;
    else
      if Pattern^<>Target^ then
        exit;
      inc(Pattern);
      inc(Target);
    end;
  until false;
end;

function CheckBuildMatrixTargetsSyntax(const Targets: String): String;
var
  p: PChar;

  procedure WarnInvalidChar;
  begin
    Result:=Format(lisMMInvalidCharacterAt, [dbgstr(p^), IntToStr(p-PChar(
      Targets)+1)]);
  end;

begin
  Result:='';
  if Targets='' then exit;
  p:=PChar(Targets);
  repeat
    case p^ of
    #0:
      if p-PChar(Targets)=length(Targets) then
        break
      else begin
        WarnInvalidChar;
        exit;
      end;
    #1..#32,#127:
      begin
        WarnInvalidChar;
        exit;
      end;
    end;
    inc(p);
  until false;
end;

function BuildMatrixModeFits(Mode, ModesSeparatedByLineBreaks: string): boolean;
var
  p: PChar;
  m: PChar;
begin
  Result:=false;
  if Mode='' then exit;
  if ModesSeparatedByLineBreaks='' then exit;
  p:=PChar(ModesSeparatedByLineBreaks);
  while p^<>#0 do begin
    while p^ in [#1..#31] do inc(p);
    m:=PChar(Mode);
    while (UpChars[p^]=UpChars[m^]) and (p^>=' ') do begin
      inc(p);
      inc(m);
    end;
    if (m^=#0) and (p^ in [#10,#13,#0]) then
      exit(true);
    while p^>=' ' do inc(p);
  end;
end;

function Str2BuildMatrixOptionType(const s: string): TBuildMatrixOptionType;
begin
  for Result:=low(TBuildMatrixOptionType) to high(TBuildMatrixOptionType) do
    if SysUtils.CompareText(BuildMatrixOptionTypeNames[Result],s)=0 then exit;
  Result:=bmotCustom;
end;

function CreateBuildMatrixOptionGUID: string;
var
  i: Integer;
begin
  SetLength(Result,12);
  for i:=1 to length(Result) do
    Result[i]:=chr(ord('0')+random(10));
end;

function SplitMatrixMacro(MacroAssignment: string; out MacroName,
  MacroValue: string; ExceptionOnError: boolean): boolean;

  procedure E(Msg: string);
  begin
    raise EMMMacroSyntaxException.Create(Msg);
  end;

var
  p: PChar;
  StartP: PChar;
begin
  Result:=false;
  MacroName:='';
  MacroValue:='';
  if MacroAssignment='' then begin
    if ExceptionOnError then
      E(lisMMMissingMacroName);
    exit;
  end;
  p:=PChar(MacroAssignment);
  if not IsIdentStartChar[p^] then begin
    if ExceptionOnError then
      E(Format(lisMMExpectedMacroNameButFound, [dbgstr(p^)]));
    exit;
  end;
  StartP:=p;
  repeat
    inc(p);
  until not IsIdentChar[p^];
  MacroName:=copy(MacroAssignment,1,p-StartP);
  if (p^<>':') or (p[1]<>'=') then begin
    if ExceptionOnError then
      E(Format(lisMMExpectedAfterMacroNameButFound, [dbgstr(p^)]));
    exit;
  end;
  inc(p,2);
  StartP:=p;
  repeat
    if (p^=#0) and (p-PChar(MacroAssignment)=length(MacroAssignment)) then break;
    if p^ in [#0..#31,#127] then begin
      if ExceptionOnError then
        E(Format(lisMMInvalidCharacterInMacroValue, [dbgstr(p^)]));
      exit;
    end;
    inc(p);
  until false;
  MacroValue:=copy(MacroAssignment,StartP-PChar(MacroAssignment)+1,p-StartP);
  Result:=true;
end;

procedure ApplyBuildMatrixMacros(Options: TBuildMatrixOptions; Target: string;
  CfgVars: TCTCfgScriptVariables);
var
  i: Integer;
  Option: TBuildMatrixOption;
begin
  if (Options=nil) or (CfgVars=nil) then exit;
  for i:=0 to Options.Count-1 do begin
    Option:=Options[i];
    if Option.Typ<>bmotIDEMacro then continue;
    if not Option.FitsTarget(Target) then continue;
    //debugln(['ApplyBuildMatrixMacros Option.MacroName="',Option.MacroName,'" Value="',Option.Value,'"']);
    CfgVars.Values[Option.MacroName]:=Option.Value;
  end;
end;

{ TBuildMatrixOptions }

function TBuildMatrixOptions.GetItems(Index: integer): TBuildMatrixOption;
begin
  Result:=TBuildMatrixOption(fItems[Index]);
end;

function TBuildMatrixOptions.GetModified: boolean;
begin
  Result:=fSavedChangeStep<>FChangeStep;
end;

procedure TBuildMatrixOptions.SetModified(AValue: boolean);
begin
  if AValue then
    IncreaseChangeStep
  else
    fSavedChangeStep:=FChangeStep;
end;

procedure TBuildMatrixOptions.Assign(Source: TPersistent);
var
  aSource: TBuildMatrixOptions;
  i: Integer;
  Item: TBuildMatrixOption;
begin
  if Source is TBuildMatrixOptions then
  begin
    aSource:=TBuildMatrixOptions(Source);
    Clear;
    for i:=0 to aSource.Count-1 do begin
      Item:=TBuildMatrixOption.Create(Self);
      Item.Assign(aSource[i]);
    end;
  end else
    inherited Assign(Source);
end;

constructor TBuildMatrixOptions.Create;
begin
  FChangeStep:=CTInvalidChangeStamp64;
  fItems:=TObjectList.create(true);
end;

destructor TBuildMatrixOptions.Destroy;
begin
  Clear;
  FreeAndNil(fItems);
  inherited Destroy;
end;

procedure TBuildMatrixOptions.Clear;
begin
  if fItems.Count=0 then exit;
  fClearing:=true;
  fItems.Clear;
  fClearing:=false;
  IncreaseChangeStep;
end;

procedure TBuildMatrixOptions.DisableModes(const IsModeEvent: TIsModeEvent;
  aTyp: TBMModesType);
var
  i: Integer;
begin
  for i:=0 to Count-1 do
    Items[i].DisableModes(IsModeEvent,aTyp);
end;

function TBuildMatrixOptions.Count: integer;
begin
  Result:=fItems.Count;
end;

function TBuildMatrixOptions.IndexOf(Option: TBuildMatrixOption): integer;
begin
  Result:=fItems.IndexOf(Option);
end;

function TBuildMatrixOptions.Add(Typ: TBuildMatrixOptionType; Targets: string
  ): TBuildMatrixOption;
begin
  Result:=TBuildMatrixOption.Create(Self);
  Result.Targets:=Targets;
  Result.Typ:=Typ;
end;

procedure TBuildMatrixOptions.Delete(Index: integer);
begin
  Items[Index].Free;
end;

procedure TBuildMatrixOptions.IncreaseChangeStep;
begin
  CTIncreaseChangeStamp64(FChangeStep);
  if Assigned(OnChanged) then
    OnChanged(Self);
end;

function TBuildMatrixOptions.Equals(Obj: TObject): boolean;
var
  Src: TBuildMatrixOptions;
  i: Integer;
begin
  Result:=false;
  if Self=Obj then exit;
  if not (Obj is TBuildMatrixOptions) then exit;
  Src:=TBuildMatrixOptions(Obj);
  if Src.Count<>Count then exit;
  for i:=0 to Count-1 do
    if not Src[i].Equals(Items[i]) then exit;
  Result:=true;
end;

procedure TBuildMatrixOptions.LoadFromConfig(Cfg: TConfigStorage);
var
  Cnt: Integer;
  i: Integer;
  Option: TBuildMatrixOption;
begin
  Clear;
  Cnt:=Cfg.GetValue('Count',0);
  for i:=1 to Cnt do begin
    Option:=TBuildMatrixOption.Create(Self);
    Cfg.AppendBasePath('item'+IntToStr(i));
    Option.LoadFromConfig(Cfg);
    Cfg.UndoAppendBasePath;
  end;
end;

procedure TBuildMatrixOptions.SaveToConfig(Cfg: TConfigStorage);
var
  i: Integer;
begin
  Cfg.SetDeleteValue('Count',Count,0);
  for i:=0 to Count-1 do begin
    Cfg.AppendBasePath('item'+IntToStr(i+1));
    Items[i].SaveToConfig(Cfg);
    Cfg.UndoAppendBasePath;
  end;
end;

procedure TBuildMatrixOptions.LoadFromXMLConfig(Cfg: TXMLConfig;
  const aPath: string);
var
  Cnt: Integer;
  i: Integer;
  Option: TBuildMatrixOption;
begin
  Clear;
  Cnt:=Cfg.GetValue(aPath+'Count',0);
  //debugln(['TBuildMatrixOptions.LoadFromXMLConfig Cnt=',Cnt]);
  for i:=1 to Cnt do begin
    Option:=TBuildMatrixOption.Create(Self);
    Option.LoadFromXMLConfig(Cfg,aPath+'item'+IntToStr(i)+'/');
  end;
  //debugln(['TBuildMatrixOptions.LoadFromXMLConfig Count=',Count]);
end;

procedure TBuildMatrixOptions.SaveToXMLConfig(Cfg: TXMLConfig;
  const aPath: string);
var
  i: Integer;
begin
  //debugln(['TBuildMatrixOptions.SaveToXMLConfig ',aPath]);
  Cfg.SetDeleteValue(aPath+'Count',Count,0);
  for i:=0 to Count-1 do
    Items[i].SaveToXMLConfig(Cfg,aPath+'item'+IntToStr(i+1)+'/');
end;

procedure TBuildMatrixOptions.AppendCustomOptions(Target, ActiveMode: string;
  var Options: string);
var
  i: Integer;
  Option: TBuildMatrixOption;
  Value: String;
begin
  for i:=0 to Count-1 do begin
    Option:=Items[i];
    if Option.Typ<>bmotCustom then continue;
    Value:=Trim(Option.Value);
    if Value='' then continue;
    if not Option.FitsTarget(Target) then continue;
    if not Option.FitsMode(ActiveMode,bmmtActive) then continue;
    if Options<>'' then Options+=' ';
    Options+=Value;
  end;
end;

procedure TBuildMatrixOptions.GetOutputDirectory(Target, ActiveMode: string;
  var OutDir: string);
var
  i: Integer;
  Option: TBuildMatrixOption;
begin
  for i:=0 to Count-1 do begin
    Option:=Items[i];
    if Option.Typ<>bmotOutDir then continue;
    if not Option.FitsTarget(Target) then continue;
    if not Option.FitsMode(ActiveMode,bmmtActive) then continue;
    OutDir:=Option.Value;
  end;
end;

function TBuildMatrixOptions.FindOption(const ID: string): TBuildMatrixOption;
var
  i: Integer;
begin
  for i:=0 to Count-1 do begin
    Result:=Items[i];
    if Result.ID=ID then exit;
  end;
  Result:=nil;
end;

{ TBuildMatrixOption }

procedure TBuildMatrixOption.SetMacroName(AValue: string);
begin
  if FMacroName=AValue then Exit;
  FMacroName:=AValue;
  List.IncreaseChangeStep;
end;

function TBuildMatrixOption.GetModes(Typ: TBMModesType): string;
begin
  Result:=FModes[Typ];
end;

procedure TBuildMatrixOption.SetModes(Typ: TBMModesType; AValue: string);
begin
  if FModes[Typ]=AValue then exit;
  FModes[Typ]:=AValue;
  if Typ=bmmtStored then
    List.IncreaseChangeStep;
end;

procedure TBuildMatrixOption.SetTargets(AValue: string);
begin
  if FTargets=AValue then Exit;
  FTargets:=AValue;
  List.IncreaseChangeStep;
end;

procedure TBuildMatrixOption.SetTyp(AValue: TBuildMatrixOptionType);
begin
  if FTyp=AValue then Exit;
  FTyp:=AValue;
  List.IncreaseChangeStep;
end;

procedure TBuildMatrixOption.SetValue(AValue: string);
begin
  if FValue=AValue then Exit;
  FValue:=AValue;
  List.IncreaseChangeStep;
end;

procedure TBuildMatrixOption.Assign(Source: TPersistent);
var
  aSource: TBuildMatrixOption;
  mt: TBMModesType;
begin
  if Source is TBuildMatrixOption then
  begin
    aSource:=TBuildMatrixOption(Source);
    Targets:=aSource.Targets;
    for mt:=Low(TBMModesType) to high(TBMModesType) do
      Modes[mt]:=aSource.Modes[mt];
    Typ:=aSource.Typ;
    MacroName:=aSource.MacroName;
    Value:=aSource.Value;
  end else
    inherited Assign(Source);
end;

constructor TBuildMatrixOption.Create(aList: TBuildMatrixOptions);
begin
  FList:=aList;
  if List<>nil then
    List.fItems.Add(Self);
end;

destructor TBuildMatrixOption.Destroy;
begin
  List.fItems.Remove(Self);
  FList:=nil;
  inherited Destroy;
end;

function TBuildMatrixOption.FitsTarget(const Target: string): boolean;
begin
  Result:=BuildMatrixTargetFits(Target,Targets);
end;

function TBuildMatrixOption.FitsMode(const Mode: string; aTyp: TBMModesType
  ): boolean;
begin
  Result:=BuildMatrixModeFits(Mode,Modes[aTyp]);
end;

function TBuildMatrixOption.Equals(Obj: TObject): boolean;
var
  Src: TBuildMatrixOption;
  mt: TBMModesType;
begin
  Result:=false;
  if Obj=Self then exit;
  if not (Obj is TBuildMatrixOption) then exit;
  Src:=TBuildMatrixOption(Obj);
  if Src.Targets<>Targets then exit;
  for mt:=Low(TBMModesType) to high(TBMModesType) do
    if Src.Modes[mt]<>Modes[mt] then exit;
  if Src.Typ<>Typ then exit;
  if Src.MacroName<>MacroName then exit;
  if Src.Value<>Value then exit;
  Result:=true;
end;

function TBuildMatrixOption.GetModesSeparatedByComma(aTyp: TBMModesType): string;
var
  p: Integer;
begin
  Result:=Modes[aTyp];
  p:=1;
  while p<=length(Result) do begin
    case Result[p] of
    ',':
      begin
        system.Insert(',',Result,p);
        inc(p);
      end;
    #10,#13:
      begin
        while (p<=length(Result)) and (Result[p] in [#10,#13]) do
          System.Delete(Result,p,1);
        system.Insert(',',Result,p);
      end;
    end;
    inc(p);
  end;
end;

procedure TBuildMatrixOption.SetModesFromCommaSeparatedList(aList: string;
  aTyp: TBMModesType);
var
  p: Integer;
begin
  p:=1;
  while p<=length(aList) do begin
    if aList[p]=',' then begin
      if (p<length(aList)) and (aList[p+1]=',') then begin
        system.Delete(aList,p,1);
        inc(p);
      end else begin
        ReplaceSubstring(aList,p,1,LineEnding);
        inc(p,length(LineEnding));
      end;
    end else begin
      inc(p);
    end;
  end;
  Modes[aTyp]:=aList;
end;

procedure TBuildMatrixOption.DisableModes(const DisableModeEvent: TIsModeEvent;
  aTyp: TBMModesType);
var
  CurModes: String;
  p: PChar;
  StartP: PChar;
  CurMode: String;
  StartPos: integer;
begin
  CurModes:=Modes[aTyp];
  p:=PChar(CurModes);
  while p^<>#0 do begin
    StartP:=p;
    while not (p^ in [#0,#10,#13]) do inc(p);
    StartPos:=StartP-PChar(CurModes)+1;
    CurMode:=copy(CurModes,StartPos,p-StartP);
    while p^ in [#10,#13] do inc(p);
    if DisableModeEvent(CurMode) then begin
      System.Delete(CurModes,StartPos,p-StartP);
      p:=Pointer(CurModes)+StartPos-1;
    end;
  end;
  Modes[aTyp]:=CurModes;
end;

procedure TBuildMatrixOption.EnableMode(const aMode: string; aTyp: TBMModesType
  );
begin
  if FitsMode(aMode,aTyp) then exit;
  Modes[aTyp]:=Modes[aTyp]+aMode+LineEnding;
end;

procedure TBuildMatrixOption.LoadFromConfig(Cfg: TConfigStorage);
begin
  ID:=Cfg.GetValue('ID','');
  Targets:=Cfg.GetValue('Targets','*');
  SetModesFromCommaSeparatedList(Cfg.GetValue('Modes','*'),bmmtStored);
  Typ:=Str2BuildMatrixOptionType(Cfg.GetValue('Type',''));
  MacroName:=Cfg.GetValue('MacroName','');
  Value:=Cfg.GetValue('Value','');
end;

procedure TBuildMatrixOption.SaveToConfig(Cfg: TConfigStorage);
begin
  Cfg.SetDeleteValue('ID',ID,'');
  Cfg.SetDeleteValue('Targets',Targets,'*');
  Cfg.SetDeleteValue('Modes',GetModesSeparatedByComma(bmmtStored),'*');
  Cfg.SetDeleteValue('Type',BuildMatrixOptionTypeNames[Typ],BuildMatrixOptionTypeNames[bmotCustom]);
  Cfg.SetDeleteValue('MacroName',MacroName,'');
  Cfg.SetDeleteValue('Value',Value,'');
end;

procedure TBuildMatrixOption.LoadFromXMLConfig(Cfg: TXMLConfig;
  const aPath: string);
begin
  ID:=Cfg.GetValue(aPath+'ID','');
  Targets:=Cfg.GetValue(aPath+'Targets','*');
  SetModesFromCommaSeparatedList(Cfg.GetValue(aPath+'Modes','*'),bmmtStored);
  Modes[bmmtActive]:=Modes[bmmtStored];
  Typ:=Str2BuildMatrixOptionType(Cfg.GetValue(aPath+'Type',''));
  MacroName:=Cfg.GetValue(aPath+'MacroName','');
  Value:=Cfg.GetValue(aPath+'Value','');
end;

procedure TBuildMatrixOption.SaveToXMLConfig(Cfg: TXMLConfig;
  const aPath: string);
begin
  Cfg.SetDeleteValue(aPath+'ID',ID,'');
  Cfg.SetDeleteValue(aPath+'Targets',Targets,'*');
  Cfg.SetDeleteValue(aPath+'Modes',GetModesSeparatedByComma(bmmtStored),'*');
  Cfg.SetDeleteValue(aPath+'Type',BuildMatrixOptionTypeNames[Typ],BuildMatrixOptionTypeNames[bmotCustom]);
  Cfg.SetDeleteValue(aPath+'MacroName',MacroName,'');
  Cfg.SetDeleteValue(aPath+'Value',Value,'');
end;

function TBuildMatrixOption.AsString: string;
begin
  Result:='ID="'+ID+'" '+BuildMatrixOptionTypeNames[Typ]+' Value="'+Value+'" ActiveModes="'+dbgstr(Modes[bmmtActive])+'"';
end;

end.

