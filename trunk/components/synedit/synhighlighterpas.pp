{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterPas.pas, released 2000-04-17.
The Original Code is based on the mwPasSyn.pas file from the
mwEdit component suite by Martin Waldenburg and other developers, the Initial
Author of this file is Martin Waldenburg.
Portions created by Martin Waldenburg are Copyright (C) 1998 Martin Waldenburg.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id$

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}
{
@abstract(Provides a Pascal/Delphi syntax highlighter for SynEdit)
@author(Martin Waldenburg)
@created(1998, converted to SynEdit 2000-04-07)
@lastmod(2000-06-23)
The SynHighlighterPas unit provides SynEdit with a Object Pascal syntax highlighter.
An extra boolean property "D4Syntax" is included to enable the recognition of the
advanced features found in Object Pascal in Delphi 4.
}
unit SynHighlighterPas;

{$I synedit.inc}

interface

uses
  SysUtils,
  {$IFDEF SYN_LAZARUS}
  LCLProc, LCLIntf,
  {$ELSE}
  Windows, Messages,
  {$ENDIF}
  Classes, Registry, Controls, Graphics, SynEditHighlighterFoldBase, SynEditMiscProcs,
  SynEditTypes, SynEditHighlighter, SynEditTextBuffer,
  SynEditStrConst;

type
  TtkTokenKind = (tkAsm, tkComment, tkIdentifier, tkKey, tkNull, tkNumber,
    tkSpace, tkString, tkSymbol, {$IFDEF SYN_LAZARUS}tkDirective, {$ENDIF}
    tkUnknown);

  TRangeState = (
    // rsAnsi, rsBor, rsDirective are exclusive to each other
    rsAnsi,   // *) comment
    rsBor,    // { comment
    {$IFDEF SYN_LAZARUS}
    rsDirective,
    {$ENDIF}
    rsAsm,    // assembler block
    rsProperty,
    rsInterface,
    rsImplementation,   // Program or Implementation
    // we need to detect if procedure is a "type x = procedure"
    rsAtEqual,      // "=" either in compare or in type/const assign
    rsAfterEqual,
    // Detect if class/object is ended by ";" or "end;"
    rsAtClass,
    rsAfterClass,
    rsAtClosingBracket // ')'
  );
  TRangeStates = set of TRangeState;

type
  {$IFDEF SYN_LAZARUS}
  TPascalCodeFoldBlockType = (
    cfbtNone,
    cfbtBeginEnd,      // Nested
    cfbtTopBeginEnd,   // Begin of Procedure
    cfbtNestedComment,
    cfbtProcedure,
    cfbtUses,
    cfbtVarType,
    cfbtLocalVarType,
    cfbtClass,
    cfbtClassSection,
    cfbtUnitSection,
    cfbtProgram,
    cfbtUnit,
    cfbtRecord,
    cfbtTry,
    cfbtExcept,
    cfbtRepeat,
    cfbtAsm,
    cfbtCase
    );
  TPascalCodeFoldBlockTypes = set of TPascalCodeFoldBlockType;

const
  CountPascalCodeFoldBlockOffset: Pointer =
    Pointer(PtrInt(Integer(high(TPascalCodeFoldBlockType))+1));

  cfbtAll: TPascalCodeFoldBlockTypes =
    [low(TPascalCodeFoldBlockType)..high(TPascalCodeFoldBlockType)];
  PascalWordTrippletRanges: TPascalCodeFoldBlockTypes =
    [cfbtBeginEnd, cfbtTopBeginEnd, cfbtProcedure, cfbtClass, cfbtProgram, cfbtRecord,
     cfbtTry, cfbtExcept, cfbtRepeat, cfbtAsm, cfbtCase
    ];

type

  TPascalCompilerMode = (
    pcmObjFPC,
    pcmDelphi,
    pcmFPC,
    pcmTP,
    pcmGPC,
    pcmMacPas
    );

  TSynPasDividerDrawLocation = (
      pddlUnitSection,
      pddlUses,
      pddlVarGlobal,     // Var, Type, Const in global scope
      pddlVarLocal,      // Var, Type, Const in local (procedure) scope
      pddlStructGlobal,  // Class, Object, Record in global type block
      pddlStructLocal,   // Class, Object, Record in local (procedure) type block
      pddlProcedure,
      pddlBeginEnd,      // Includes Repeat
      pddlTry
    );

const

  PasDividerDrawLocationDefaults: Array [TSynPasDividerDrawLocation] of
    Integer = (1, 0, // unit, uses
               1, 0, // var
               1, 0, // struct
               2, 0, // proc, begin
               0);

type

  { TSynPasSynRange }

  TSynPasSynRange = class(TSynCustomHighlighterRange)
  private
    FMode: TPascalCompilerMode;
    FBracketNestLevel : Integer;
    FLastLineCodeFoldLevelFix: integer;
    FPasFoldEndLevel: Smallint;
    FPasFoldFixLevel: Smallint;
    FPasFoldMinLevel: Smallint;
  public
    procedure Clear; override;
    function Compare(Range: TSynCustomHighlighterRange): integer; override;
    procedure Assign(Src: TSynCustomHighlighterRange); override;
    function Add(ABlockType: Pointer = nil; IncreaseLevel: Boolean = True):
        TSynCustomCodeFoldBlock; override;
    procedure Pop(DecreaseLevel: Boolean = True); override;
    function MaxFoldLevel: Integer; override;
    procedure IncBracketNestLevel;
    procedure DecBracketNestLevel;
    procedure DecLastLineCodeFoldLevelFix;
    procedure DecLastLinePasFoldFix;
    property Mode: TPascalCompilerMode read FMode write FMode;
    property BracketNestLevel: integer read FBracketNestLevel write FBracketNestLevel;
    property LastLineCodeFoldLevelFix: integer
      read FLastLineCodeFoldLevelFix write FLastLineCodeFoldLevelFix;
    property PasFoldEndLevel: Smallint read FPasFoldEndLevel write FPasFoldEndLevel;
    property PasFoldFixLevel: Smallint read FPasFoldFixLevel write FPasFoldFixLevel;
    property PasFoldMinLevel: Smallint read FPasFoldMinLevel write FPasFoldMinLevel;
  end;
  {$ENDIF}

  TProcTableProc = procedure of object;

  PIdentFuncTableFunc = ^TIdentFuncTableFunc;
  TIdentFuncTableFunc = function: TtkTokenKind of object;

  { TSynPasSyn }

  TSynPasSyn = class(TSynCustomFoldHighlighter)
  private
    fAsmStart: Boolean;
    FNestedComments: boolean;
    FStartCodeFoldBlockLevel: integer;
    FPasStartLevel: Smallint;
    fRange: TRangeStates;
    FAtLineStart: Boolean; // Line had only spaces or comments sofar
    {$IFDEF SYN_LAZARUS}
    fLineStr: string;
    fLine: PChar;
    fLineLen: integer;
    {$ELSE}
    fLine: PChar;
    {$ENDIF}
    fLineNumber: Integer;
    fProcTable: array[#0..#255] of TProcTableProc;
    Run: LongInt;// current parser postion in fLine
    fStringLen: Integer;// current length of hash
    {$IFDEF SYN_LAZARUS}
    fToIdent: integer;// start of current identifier in fLine
    {$ELSE}
    fToIdent: PChar;
    {$ENDIF}
    fIdentFuncTable: array[0..191] of TIdentFuncTableFunc;
    fTokenPos: Integer;// start of current token in fLine
    FTokenID: TtkTokenKind;
    fStringAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fKeyAttri: TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    fAsmAttri: TSynHighlighterAttributes;
    fCommentAttri: TSynHighlighterAttributes;
    fIdentifierAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;
    {$IFDEF SYN_LAZARUS}
    fDirectiveAttri: TSynHighlighterAttributes;
    FCompilerMode: TPascalCompilerMode;
    {$ENDIF}
    fD4syntax: boolean;
    {$IFDEF SYN_LAZARUS}
    FCatchNodeInfo: Boolean;
    FNodeInfoLine, FNodeInfoCount: Integer;
    FNodeInfoList: Array of TSynFoldNodeInfo;
    FDividerDrawConfig: Array [TSynPasDividerDrawLocation] of TSynDividerDrawConfig;
    FFoldConfig: Array [TPascalCodeFoldBlockType] of Boolean;
    procedure GrowNodeInfoList;
    function GetPasCodeFoldRange: TSynPasSynRange;
    procedure SetCompilerMode(const AValue: TPascalCompilerMode);
    function TextComp(aText: PChar): Boolean;
    function KeyHash: Integer;
    {$ELSE}
    function KeyHash(ToHash: PChar): Integer;
    {$ENDIF}
    function KeyComp(const aKey: string): Boolean;
    function Func15: TtkTokenKind;
    function Func19: TtkTokenKind;
    function Func20: TtkTokenKind;
    function Func21: TtkTokenKind;
    function Func23: TtkTokenKind;
    function Func25: TtkTokenKind;
    function Func27: TtkTokenKind;
    function Func28: TtkTokenKind;
    {$ifdef SYN_LAZARUS}
    function Func29: TtkTokenKind;  // "on"
    {$endif}
    function Func32: TtkTokenKind;
    function Func33: TtkTokenKind;
    function Func35: TtkTokenKind;
    function Func37: TtkTokenKind;
    function Func38: TtkTokenKind;
    function Func39: TtkTokenKind;
    function Func40: TtkTokenKind;
    function Func41: TtkTokenKind;
    function Func44: TtkTokenKind;
    function Func45: TtkTokenKind;
    function Func47: TtkTokenKind;
    function Func49: TtkTokenKind;
    function Func52: TtkTokenKind;
    function Func54: TtkTokenKind;
    function Func55: TtkTokenKind;
    function Func56: TtkTokenKind;
    function Func57: TtkTokenKind;
    function Func59: TtkTokenKind;
    function Func60: TtkTokenKind;
    function Func61: TtkTokenKind;
    function Func63: TtkTokenKind;
    function Func64: TtkTokenKind;
    function Func65: TtkTokenKind;
    function Func66: TtkTokenKind;
    function Func69: TtkTokenKind;
    function Func71: TtkTokenKind;
    function Func73: TtkTokenKind;
    function Func75: TtkTokenKind;
    function Func76: TtkTokenKind;
    function Func79: TtkTokenKind;
    function Func81: TtkTokenKind;
    function Func84: TtkTokenKind;
    function Func85: TtkTokenKind;
    function Func86: TtkTokenKind;
    function Func87: TtkTokenKind;
    function Func88: TtkTokenKind;
    function Func91: TtkTokenKind;
    function Func92: TtkTokenKind;
    function Func94: TtkTokenKind;
    function Func95: TtkTokenKind;
    function Func96: TtkTokenKind;
    function Func97: TtkTokenKind;
    function Func98: TtkTokenKind;
    function Func99: TtkTokenKind;
    function Func100: TtkTokenKind;
    function Func101: TtkTokenKind;
    function Func102: TtkTokenKind;
    function Func103: TtkTokenKind;
    function Func105: TtkTokenKind;
    function Func106: TtkTokenKind;
    {$ifdef SYN_LAZARUS}
    function Func108: TtkTokenKind;  // "operator"
    function Func112: TtkTokenKind;  // "requires"
    {$endif}
    function Func117: TtkTokenKind;
    {$ifdef SYN_LAZARUS}
    function Func122: TtkTokenKind; // "otherwise"
    {$endif}
    function Func126: TtkTokenKind;
    function Func128: TtkTokenKind;
    function Func129: TtkTokenKind;
    function Func130: TtkTokenKind;
    function Func132: TtkTokenKind;
    function Func133: TtkTokenKind;
    function Func136: TtkTokenKind;
    function Func141: TtkTokenKind;
    function Func143: TtkTokenKind;
    function Func166: TtkTokenKind;
    function Func167: TtkTokenKind;
    function Func168: TtkTokenKind;
    function Func191: TtkTokenKind;
    function AltFunc: TtkTokenKind;
    procedure InitIdent;
    {$IFDEF SYN_LAZARUS}
    function IdentKind(p: integer): TtkTokenKind;
    {$ELSE}
    function IdentKind(MayBe: PChar): TtkTokenKind;
    {$ENDIF}
    procedure MakeMethodTables;
    procedure AddressOpProc;
    procedure AsciiCharProc;
    procedure AnsiProc;
    procedure BorProc;
    procedure BraceOpenProc;
    procedure ColonOrGreaterProc;
    procedure CRProc;
    {$IFDEF SYN_LAZARUS}
    procedure DirectiveProc;
    {$ENDIF}
    procedure IdentProc;
    procedure IntegerProc;
    procedure LFProc;
    procedure LowerProc;
    procedure NullProc;
    procedure NumberProc;
    procedure PointProc;
    procedure RoundOpenProc;
    procedure RoundCloseProc;
    procedure SquareOpenProc;
    procedure SquareCloseProc;
    procedure EqualSignProc;
    procedure SemicolonProc;                                                    //mh 2000-10-08
    procedure SlashProc;
    procedure SpaceProc;
    procedure StringProc;
    procedure SymbolProc;
    procedure UnknownProc;
    procedure SetD4syntax(const Value: boolean);
    procedure InitNode(var Node: TSynFoldNodeInfo; EndOffs: Integer;
                       ABlockType: TPascalCodeFoldBlockType);
    procedure CreateDividerDrawConfig;
    procedure DestroyDividerDrawConfig;
    procedure InitFoldConfig;
  protected
    function GetFoldConfig(Index: Integer): Boolean; override;
    function GetFoldConfigCount: Integer; override;
    procedure SetFoldConfig(Index: Integer; const AValue: Boolean); override;

    function GetFoldNodeInfo(Line, Index: Integer): TSynFoldNodeInfo; override;
    function GetFoldNodeInfoCount(Line: Integer): Integer; override;

    function GetIdentChars: TSynIdentChars; override;
    function IsFilterStored: boolean; override;                                 //mh 2000-10-08

    procedure CreateRootCodeFoldBlock; override;
    function StartPascalCodeFoldBlock(ABlockType: TPascalCodeFoldBlockType):
                                                        TSynCustomCodeFoldBlock;
    procedure EndCodeFoldBlock(DecreaseLevel: Boolean = True); override;
    procedure CloseBeginEndBlocks;
    procedure EndCodeFoldBlockLastLine;
    function TopPascalCodeFoldBlockType(DownIndex: Integer = 0): TPascalCodeFoldBlockType;

    function GetRangeClass: TSynCustomHighlighterRangeClass; override;
    property PasCodeFoldRange: TSynPasSynRange read GetPasCodeFoldRange;

    function MinimumPasFoldLevel(Index: Integer): integer;
    function EndPasFoldLevel(Index: Integer): integer;
    function LastLinePasFoldLevelFix(Index: Integer): integer;

    function LastLineFoldLevelFix(Index: Integer): integer;
    function GetDrawDivider(Index: integer): TSynDividerDrawConfigSetting; override;
    function GetDividerDrawConfig(Index: Integer): TSynDividerDrawConfig; override;
    function GetDividerDrawConfigCount: Integer; override;
  public
    {$IFNDEF SYN_CPPB_1} class {$ENDIF}
    function GetCapabilities: TSynHighlighterCapabilities; override;
    {$IFNDEF SYN_CPPB_1} class {$ENDIF}
    function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
      override;
    function GetEol: Boolean; override;
    function GetRange: Pointer; override;
    function GetToken: string; override;
    {$IFDEF SYN_LAZARUS}
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;
    {$ENDIF}
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenID: TtkTokenKind;
    function GetTokenKind: integer; override;
    function GetTokenPos: Integer; override;
    function IsKeyword(const AKeyword: string): boolean; override;
    procedure Next; override;

    procedure ResetRange; override;
    procedure SetLine({$IFDEF FPC}const {$ENDIF}NewValue: string;
      LineNumber: Integer); override;
    procedure SetRange(Value: Pointer); override;

    function UseUserSettings(settingIndex: integer): boolean; override;
    procedure EnumUserSettings(settings: TStrings); override;

    // fold-nodes that can be collapsed
    function FoldOpenCount(ALineIndex: Integer): integer; override;
    function FoldCloseCount(ALineIndex: Integer): integer; override;
    function FoldNestCount(ALineIndex: Integer): integer; override;
    function FoldLineLength(ALineIndex, FoldIndex: Integer): integer; override;

    function MinimumFoldLevel(Index: Integer): integer; override;
    function EndFoldLevel(Index: Integer): integer; override;
  published
    property AsmAttri: TSynHighlighterAttributes read fAsmAttri write fAsmAttri;
    property CommentAttri: TSynHighlighterAttributes read fCommentAttri
      write fCommentAttri;
    property IdentifierAttri: TSynHighlighterAttributes read fIdentifierAttri
      write fIdentifierAttri;
    property KeyAttri: TSynHighlighterAttributes read fKeyAttri write fKeyAttri;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri
      write fNumberAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri
      write fSpaceAttri;
    property StringAttri: TSynHighlighterAttributes read fStringAttri
      write fStringAttri;
    property SymbolAttri: TSynHighlighterAttributes read fSymbolAttri
      write fSymbolAttri;
    {$IFDEF SYN_LAZARUS}
    property DirectiveAttri: TSynHighlighterAttributes read fDirectiveAttri
      write fDirectiveAttri;
    property CompilerMode: TPascalCompilerMode read FCompilerMode write SetCompilerMode;
    property NestedComments: boolean read FNestedComments write FNestedComments;
    {$ENDIF}
    property D4syntax: boolean read FD4syntax write SetD4syntax default true;
  end;

  { TSynFreePascalSyn }

  TSynFreePascalSyn = class(TSynPasSyn)
  public
    constructor Create(AOwner: TComponent); override;
    procedure ResetRange; override;
  end;


implementation

const
  RESERVED_WORDS_TP: array [1..54] of String = (
    'absolute', 'and', 'array', 'asm',
    'begin',
    'case', 'const', 'constructor',
    'destructor', 'div', 'do', 'downto',
    'else', 'end',
    'file', 'for', 'function',
    'goto',
    'if', 'implementation', 'in', 'inherited', 'inline', 'interface',
    'label',
    'mod',
    'nil', 'not',
    'object', 'of', 'on', 'operator', 'or',
    'packed', 'procedure', 'program',
    'record', 'reintroduce', 'repeat',
    'self', 'set', 'shl', 'shr', 'string',
    'then', 'to', 'type',
    'unit', 'until', 'uses',
    'var',
    'while', 'with',
    'xor'
  );

  RESERVED_WORDS_DELPHI: array [1..15] of String = (
    'as',
    'class',
    'except', 'exports',
    'finalization', 'finally',
    'initialization', 'is',
    'library',
    'on', 'out',
    'property',
    'raise',
    'threadvar',
    'try'
  );

  RESERVED_WORDS_FPC: array [1..5] of String = (
    'dispose', 'exit', 'false', 'new', 'true'
  );

var
  Identifiers: array[#0..#255] of ByteBool;
  mHashTable: array[#0..#255] of Integer;
  KeywordsList: TStringList;
  {$IFDEF SYN_LAZARUS}
  IsIntegerChar: array[char] of Boolean;
  IsNumberChar: array[char] of Boolean;
  IsSpaceChar: array[char] of Boolean;
  IsUnderScoreOrNumberChar: array[char] of Boolean;
  IsLetterChar: array[char] of Boolean;
  {$ENDIF}

procedure MakeIdentTable;
var
  I, J: Char;
begin
  for I := #0 to #255 do
  begin
    Case I of
      '_', '0'..'9', 'a'..'z', 'A'..'Z': Identifiers[I] := True;
    else Identifiers[I] := False;
    end;
    J := UpCase(I);
    Case I of
      'a'..'z', 'A'..'Z', '_': mHashTable[I] := Ord(J) - 64;
    else mHashTable[Char(I)] := 0;
    end;
    {$IFDEF SYN_LAZARUS}
    IsIntegerChar[I]:=(I in ['0'..'9', 'A'..'F', 'a'..'f']);
    IsNumberChar[I]:=(I in ['0'..'9', '.', 'e', 'E']);
    IsSpaceChar[I]:=(I in [#1..#9, #11, #12, #14..#32]);
    IsUnderScoreOrNumberChar[I]:=(I in ['_','0'..'9']);
    IsLetterChar[I]:=(I in ['a'..'z','A'..'Z']);
    {$ENDIF}
  end;
end;

procedure TSynPasSyn.InitIdent;
var
  I: Integer;
  pF: PIdentFuncTableFunc;
begin
  pF := PIdentFuncTableFunc(@fIdentFuncTable);
  for I := Low(fIdentFuncTable) to High(fIdentFuncTable) do begin
    {$IFDEF FPC}
    pF^ := @AltFunc;
    {$ELSE}
    pF^ := AltFunc;
    {$ENDIF}
    Inc(pF);
  end;
  {$IFDEF FPC}
  fIdentFuncTable[15] := @Func15;
  fIdentFuncTable[19] := @Func19;
  fIdentFuncTable[20] := @Func20;
  fIdentFuncTable[21] := @Func21;
  fIdentFuncTable[23] := @Func23;
  fIdentFuncTable[25] := @Func25;
  fIdentFuncTable[27] := @Func27;
  fIdentFuncTable[28] := @Func28;
  {$ifdef SYN_LAZARUS}
  fIdentFuncTable[29] := @Func29; // "on"
  {$endif}
  fIdentFuncTable[32] := @Func32;
  fIdentFuncTable[33] := @Func33;
  fIdentFuncTable[35] := @Func35;
  fIdentFuncTable[37] := @Func37;
  fIdentFuncTable[38] := @Func38;
  fIdentFuncTable[39] := @Func39;
  fIdentFuncTable[40] := @Func40;
  fIdentFuncTable[41] := @Func41;
  fIdentFuncTable[44] := @Func44;
  fIdentFuncTable[45] := @Func45;
  fIdentFuncTable[47] := @Func47;
  fIdentFuncTable[49] := @Func49;
  fIdentFuncTable[52] := @Func52;
  fIdentFuncTable[54] := @Func54;
  fIdentFuncTable[55] := @Func55;
  fIdentFuncTable[56] := @Func56;
  fIdentFuncTable[57] := @Func57;
  fIdentFuncTable[59] := @Func59;
  fIdentFuncTable[60] := @Func60;
  fIdentFuncTable[61] := @Func61;
  fIdentFuncTable[63] := @Func63;
  fIdentFuncTable[64] := @Func64;
  fIdentFuncTable[65] := @Func65;
  fIdentFuncTable[66] := @Func66;
  fIdentFuncTable[69] := @Func69;
  fIdentFuncTable[71] := @Func71;
  fIdentFuncTable[73] := @Func73;
  fIdentFuncTable[75] := @Func75;
  fIdentFuncTable[76] := @Func76;
  fIdentFuncTable[79] := @Func79;
  fIdentFuncTable[81] := @Func81;
  fIdentFuncTable[84] := @Func84;
  fIdentFuncTable[85] := @Func85;
  fIdentFuncTable[86] := @Func86;
  fIdentFuncTable[87] := @Func87;
  fIdentFuncTable[88] := @Func88;
  fIdentFuncTable[91] := @Func91;
  fIdentFuncTable[92] := @Func92;
  fIdentFuncTable[94] := @Func94;
  fIdentFuncTable[95] := @Func95;
  fIdentFuncTable[96] := @Func96;
  fIdentFuncTable[97] := @Func97;
  fIdentFuncTable[98] := @Func98;
  fIdentFuncTable[99] := @Func99;
  fIdentFuncTable[100] := @Func100;
  fIdentFuncTable[101] := @Func101;
  fIdentFuncTable[102] := @Func102;
  fIdentFuncTable[103] := @Func103;
  fIdentFuncTable[105] := @Func105;
  fIdentFuncTable[106] := @Func106;
  {$ifdef SYN_LAZARUS}
  fIdentFuncTable[108] := @Func108; // "operator"
  fIdentFuncTable[112] := @Func112; // "requires"
  {$endif}
  fIdentFuncTable[117] := @Func117;
  {$ifdef SYN_LAZARUS}
  fIdentFuncTable[122] := @Func122;
  {$ENDIF}
  fIdentFuncTable[126] := @Func126;
  {$ifdef SYN_LAZARUS}
  fIdentFuncTable[128] := @Func128;
  {$endif}
  fIdentFuncTable[129] := @Func129;
  {$ifdef SYN_LAZARUS}
  fIdentFuncTable[130] := @Func130;
  {$endif}
  fIdentFuncTable[132] := @Func132;
  fIdentFuncTable[133] := @Func133;
  fIdentFuncTable[136] := @Func136;
  fIdentFuncTable[141] := @Func141;
  fIdentFuncTable[143] := @Func143;
  fIdentFuncTable[166] := @Func166;
  {$ifdef SYN_LAZARUS}
  fIdentFuncTable[167] := @Func167;
  {$endif}
  fIdentFuncTable[168] := @Func168;
  fIdentFuncTable[191] := @Func191;
  {$ELSE}
  fIdentFuncTable[15] := Func15;
  fIdentFuncTable[19] := Func19;
  fIdentFuncTable[20] := Func20;
  fIdentFuncTable[21] := Func21;
  fIdentFuncTable[23] := Func23;
  fIdentFuncTable[25] := Func25;
  fIdentFuncTable[27] := Func27;
  fIdentFuncTable[28] := Func28;
  fIdentFuncTable[32] := Func32;
  fIdentFuncTable[33] := Func33;
  fIdentFuncTable[35] := Func35;
  fIdentFuncTable[37] := Func37;
  fIdentFuncTable[38] := Func38;
  fIdentFuncTable[39] := Func39;
  fIdentFuncTable[40] := Func40;
  fIdentFuncTable[41] := Func41;
  fIdentFuncTable[44] := Func44;
  fIdentFuncTable[45] := Func45;
  fIdentFuncTable[47] := Func47;
  fIdentFuncTable[49] := Func49;
  fIdentFuncTable[52] := Func52;
  fIdentFuncTable[54] := Func54;
  fIdentFuncTable[55] := Func55;
  fIdentFuncTable[56] := Func56;
  fIdentFuncTable[57] := Func57;
  fIdentFuncTable[59] := Func59;
  fIdentFuncTable[60] := Func60;
  fIdentFuncTable[61] := Func61;
  fIdentFuncTable[63] := Func63;
  fIdentFuncTable[64] := Func64;
  fIdentFuncTable[65] := Func65;
  fIdentFuncTable[66] := Func66;
  fIdentFuncTable[69] := Func69;
  fIdentFuncTable[71] := Func71;
  fIdentFuncTable[73] := Func73;
  fIdentFuncTable[75] := Func75;
  fIdentFuncTable[76] := Func76;
  fIdentFuncTable[79] := Func79;
  fIdentFuncTable[81] := Func81;
  fIdentFuncTable[84] := Func84;
  fIdentFuncTable[85] := Func85;
  fIdentFuncTable[86] := Func86;
  fIdentFuncTable[87] := Func87;
  fIdentFuncTable[88] := Func88;
  fIdentFuncTable[91] := Func91;
  fIdentFuncTable[92] := Func92;
  fIdentFuncTable[94] := Func94;
  fIdentFuncTable[95] := Func95;
  fIdentFuncTable[96] := Func96;
  fIdentFuncTable[97] := Func97;
  fIdentFuncTable[98] := Func98;
  fIdentFuncTable[99] := Func99;
  fIdentFuncTable[100] := Func100;
  fIdentFuncTable[101] := Func101;
  fIdentFuncTable[102] := Func102;
  fIdentFuncTable[103] := Func103;
  fIdentFuncTable[105] := Func105;
  fIdentFuncTable[106] := Func106;
  fIdentFuncTable[117] := Func117;
  fIdentFuncTable[126] := Func126;
  fIdentFuncTable[129] := Func129;
  fIdentFuncTable[132] := Func132;
  fIdentFuncTable[133] := Func133;
  fIdentFuncTable[136] := Func136;
  fIdentFuncTable[141] := Func141;
  fIdentFuncTable[143] := Func143;
  fIdentFuncTable[166] := Func166;
  fIdentFuncTable[168] := Func168;
  fIdentFuncTable[191] := Func191;
  {$ENDIF}
end;

{$IFDEF SYN_LAZARUS}
function TSynPasSyn.KeyHash: Integer;
var
  Start, ToHash: PChar;
begin
  Result := 0;
  if (fToIdent<fLineLen) then begin
    Start := fLine + fToIdent;
    ToHash := Start;
    while (IsLetterChar[ToHash^]) do begin
      inc(Result, mHashTable[ToHash^]);
      inc(ToHash);
    end;
    if IsUnderScoreOrNumberChar[ToHash^] then
      inc(ToHash);
    fStringLen := PtrUInt(ToHash) - PtrUInt(Start);
    //if CompareText(copy(fLineStr,fToIdent+1,fStringLen),'varargs')=0 then debugln('TSynPasSyn.KeyHash '+copy(fLineStr,fToIdent+1,fStringLen)+'='+dbgs(Result));
  end else begin
    fStringLen := 0;
  end;
end; { KeyHash }
{$ELSE}
function TSynPasSyn.KeyHash(ToHash: PChar): Integer;
begin
  Result := 0;
  while ToHash^ in ['a'..'z', 'A'..'Z'] do
  begin
    inc(Result, mHashTable[ToHash^]);
    inc(ToHash);
  end;
  if ToHash^ in ['_', '0'..'9'] then inc(ToHash);
  fStringLen := ToHash - fToIdent;
end; { KeyHash }
{$ENDIF}

function TSynPasSyn.KeyComp(const aKey: string): Boolean;
var
  I: Integer;
  Temp: PChar;
begin
  if Length(aKey) = fStringLen then
  begin
    {$IFDEF SYN_LAZARUS}
    Temp := fLine + fToIdent;
    {$ELSE}
    Temp := fToIdent;
    {$ENDIF}
    Result := True;
    for i := 1 to fStringLen do
    begin
      if mHashTable[Temp^] <> mHashTable[aKey[i]] then
      begin
        Result := False;
        break;
      end;
      inc(Temp);
    end;
  end else Result := False;
end; { KeyComp }

{$IFDEF SYN_LAZARUS}
function TSynPasSyn.TextComp(aText: PChar): Boolean;
var
  CurPos: PChar;
begin
  CurPos:=@fLine[Run];
  while (aText^<>#0) do begin
    if mHashTable[aText^]<>mHashTable[CurPos^] then exit(false);
    inc(aText);
    inc(CurPos);
  end;
  Result:=true;
end;

procedure TSynPasSyn.SetCompilerMode(const AValue: TPascalCompilerMode);
begin
  if FCompilerMode=AValue then exit;
  FCompilerMode:=AValue;
  FNestedComments:=FCompilerMode in [pcmFPC,pcmObjFPC];
  PasCodeFoldRange.Mode:=FCompilerMode;
  //DebugLn(['TSynPasSyn.SetCompilerMode FCompilerMode=',ord(FCompilerMode),' FNestedComments=',FNestedComments]);
end;

procedure TSynPasSyn.GrowNodeInfoList;
begin
  if FNodeInfoCount < length(FNodeInfoList) then
    exit;
  SetLength(FNodeInfoList, FNodeInfoCount + Max(10, FNodeInfoCount div 4));
end;

function TSynPasSyn.GetPasCodeFoldRange: TSynPasSynRange;
begin
  Result := TSynPasSynRange(CodeFoldRange);
end;

{$ENDIF}

function TSynPasSyn.Func15: TtkTokenKind;
begin
  if KeyComp('If') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func19: TtkTokenKind;
begin
  if KeyComp('Do') then Result := tkKey else
    if KeyComp('And') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func20: TtkTokenKind;
begin
  if KeyComp('As') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func21: TtkTokenKind;
begin
  if KeyComp('Of') then begin
    Result := tkKey;
    if (rsAfterClass in fRange) and (TopPascalCodeFoldBlockType = cfbtClass)
    then begin
      // Accidental start of block // End at next semicolon (usually same line)
      CodeFoldRange.Pop(false); // avoid minlevel
      CodeFoldRange.Add(Pointer(PtrInt(cfbtUses)), false);
    end;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func23: TtkTokenKind;
begin
  if KeyComp('End') then begin
    if ((fToIdent<2) or (fLine[fToIdent-1]<>'@'))
    then begin
      Result := tkKey;
      fRange := fRange - [rsAsm];
        PasCodeFoldRange.BracketNestLevel := 0; // Reset in case of partial code
      {$IFDEF SYN_LAZARUS}
      // there may be more than on block ending here
      if TopPascalCodeFoldBlockType = cfbtRecord then begin
        EndCodeFoldBlock;
      end else if TopPascalCodeFoldBlockType = cfbtUnit then begin
        EndCodeFoldBlock;
      end else if TopPascalCodeFoldBlockType = cfbtExcept then begin
        EndCodeFoldBlock;
        if TopPascalCodeFoldBlockType = cfbtTry then
          EndCodeFoldBlock;
      end else if TopPascalCodeFoldBlockType = cfbtTry then begin
          EndCodeFoldBlock;
      end else if TopPascalCodeFoldBlockType in [cfbtTopBeginEnd, cfbtAsm] then begin
        EndCodeFoldBlock;
        if TopPascalCodeFoldBlockType = cfbtProcedure then
          EndCodeFoldBlock;
        if TopPascalCodeFoldBlockType = cfbtProgram then
          EndCodeFoldBlock;
      end else if TopPascalCodeFoldBlockType in [cfbtBeginEnd, cfbtCase] then begin
        EndCodeFoldBlock;
      end else if TopPascalCodeFoldBlockType = cfbtUnitSection then begin
        EndCodeFoldBlockLastLine;
        if TopPascalCodeFoldBlockType = cfbtUnit then // "Unit".."end."
          EndCodeFoldBlock;
      end else begin
        if TopPascalCodeFoldBlockType = cfbtClassSection then
          EndCodeFoldBlockLastLine;
        if TopPascalCodeFoldBlockType = cfbtClass then
          EndCodeFoldBlock;
      end;
      {$ENDIF}
    end else begin
      Result := tkKey; // @@end or @end label
    end;
  end else
    if KeyComp('In') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func25: TtkTokenKind;
begin
  if KeyComp('Far') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func27: TtkTokenKind;
begin
  if KeyComp('Cdecl') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func28: TtkTokenKind;
begin
  if KeyComp('Is') then Result := tkKey else
    if KeyComp('Read') then
    begin
      if rsProperty in fRange then Result := tkKey else Result := tkIdentifier;
    end else
      if KeyComp('Case') then begin
        if TopPascalCodeFoldBlockType in
           [cfbtBeginEnd, cfbtTopBeginEnd, cfbtCase, cfbtTry, cfbtExcept, cfbtRepeat] then
          StartPascalCodeFoldBlock(cfbtCase);
        Result := tkKey;
      end else Result := tkIdentifier;
end;

{$IFDEF SYN_LAZARUS}
function TSynPasSyn.Func29: TtkTokenKind;
begin
  if KeyComp('On') then Result := tkKey else Result := tkIdentifier;
end;
{$ENDIF}

function TSynPasSyn.Func32: TtkTokenKind;
begin
  if KeyComp('Label') then Result := tkKey else
    if KeyComp('Mod') then Result := tkKey else
      if KeyComp('File') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func33: TtkTokenKind;
begin
  if KeyComp('Or') then Result := tkKey else
    if KeyComp('Asm') then
    begin
      Result := tkKey;
      fRange := fRange + [rsAsm];
      fAsmStart := True;
      {$IFDEF SYN_LAZARUS}
      StartPascalCodeFoldBlock(cfbtAsm);
      //debugln('TSynPasSyn.Func37 BEGIN ',dbgs(ord(TopPascalCodeFoldBlockType)),' LineNumber=',dbgs(fLineNumber),' ',dbgs(MinimumCodeFoldBlockLevel),' ',dbgs(CurrentCodeFoldBlockLevel));
      {$ENDIF}
    end else Result := tkIdentifier;
end;

function TSynPasSyn.Func35: TtkTokenKind;
begin
  if KeyComp('Nil') then Result := tkKey else
    if KeyComp('To') then Result := tkKey else
      if KeyComp('Div') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func37: TtkTokenKind;
begin
  if KeyComp('Begin') then begin
    // if we are in an include file, we may not know the state
    if (fRange * [rsImplementation, rsInterface] = []) then
      Include(fRange, rsImplementation);
    PasCodeFoldRange.BracketNestLevel := 0; // Reset in case of partial code
    if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
      EndCodeFoldBlockLastLine;
    Result := tkKey;
    if TopPascalCodeFoldBlockType in [cfbtProcedure]
    then StartPascalCodeFoldBlock(cfbtTopBeginEnd)
    else StartPascalCodeFoldBlock(cfbtBeginEnd);
    //debugln('TSynPasSyn.Func37 BEGIN ',dbgs(ord(TopPascalCodeFoldBlockType)),' LineNumber=',dbgs(fLineNumber),' ',dbgs(MinimumCodeFoldBlockLevel),' ',dbgs(CurrentCodeFoldBlockLevel));
  end else
    Result := tkIdentifier;
end;

function TSynPasSyn.Func38: TtkTokenKind;
begin
  if KeyComp('Near') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func39: TtkTokenKind;
begin
  if KeyComp('For') then Result := tkKey else
    if KeyComp('Shl') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func40: TtkTokenKind;
begin
  if KeyComp('Packed') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func41: TtkTokenKind;
begin
  if KeyComp('Else') then
    Result := tkKey
  else if KeyComp('Var') then begin
    if (PasCodeFoldRange.BracketNestLevel = 0) and
        (TopPascalCodeFoldBlockType in
        [cfbtVarType, cfbtLocalVarType, cfbtNone, cfbtProcedure, cfbtProgram,
         cfbtUnit, cfbtUnitSection]) then begin
      if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
        EndCodeFoldBlockLastLine;
      if TopPascalCodeFoldBlockType in [cfbtProcedure]
      then StartPascalCodeFoldBlock(cfbtLocalVarType)
      else StartPascalCodeFoldBlock(cfbtVarType);
    end;
    Result := tkKey;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func44: TtkTokenKind;
begin
  if KeyComp('Set') then
    Result := tkKey
  else if KeyComp('Package') then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynPasSyn.Func45: TtkTokenKind;
begin
  if KeyComp('Shr') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func47: TtkTokenKind;
begin
  if KeyComp('Then') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func49: TtkTokenKind;
begin
  if KeyComp('Not') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func52: TtkTokenKind;
begin
  if KeyComp('Pascal') then Result := tkKey
  else if KeyComp('Raise') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func54: TtkTokenKind;
begin
  if KeyComp('Class') then begin
    Result := tkKey;
    if (rsAfterEqual in fRange) and (PasCodeFoldRange.BracketNestLevel = 0)
    then begin
      fRange := fRange + [rsAtClass];
      StartPascalCodeFoldBlock(cfbtClass);
    end;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func55: TtkTokenKind;
begin
  if KeyComp('Object') then begin
    Result := tkKey;
    if (rsAfterEqual in fRange) and (PasCodeFoldRange.BracketNestLevel = 0)
    then begin
      fRange := fRange + [rsAtClass];
      StartPascalCodeFoldBlock(cfbtClass);
    end;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func56: TtkTokenKind;
begin
  if KeyComp('Index') then
  begin
    if rsProperty in fRange then Result := tkKey else Result := tkIdentifier;
  end else
    if KeyComp('Out') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func57: TtkTokenKind;
begin
  if KeyComp('Goto') then Result := tkKey else
    if KeyComp('While') then Result := tkKey else
      if KeyComp('Xor') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func59: TtkTokenKind;
begin
  if KeyComp('Safecall') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func60: TtkTokenKind;
begin
  if KeyComp('With') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func61: TtkTokenKind;
begin
  if KeyComp('Dispid') {$IFDEF SYN_LAZARUS}or KeyComp('Generic'){$ENDIF}then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynPasSyn.Func63: TtkTokenKind;
begin
  if KeyComp('Public') then begin
    Result := tkKey;
    if (TopPascalCodeFoldBlockType in [cfbtClass, cfbtClassSection]) then begin
      if (TopPascalCodeFoldBlockType=cfbtClassSection) then
        EndCodeFoldBlockLastLine;
      StartPascalCodeFoldBlock(cfbtClassSection);
    end;
  end
  else if KeyComp('Record') then begin
    StartPascalCodeFoldBlock(cfbtRecord);
    Result := tkKey;
  end
  else if KeyComp('Array') then Result := tkKey
  else if KeyComp('Try') then
  begin
    if TopPascalCodeFoldBlockType in
       [cfbtBeginEnd, cfbtTopBeginEnd, cfbtCase, cfbtTry, cfbtExcept, cfbtRepeat] then
      StartPascalCodeFoldBlock(cfbtTry);
    Result := tkKey;
  end
  else if KeyComp('Inline') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func64: TtkTokenKind;
begin
  if KeyComp('Unit') then begin
    if TopPascalCodeFoldBlockType=cfbtNone then StartPascalCodeFoldBlock(cfbtUnit);
    Result := tkKey;
  end
  else if KeyComp('Uses') then begin
    if (TopPascalCodeFoldBlockType in
        [cfbtNone, cfbtProgram, cfbtUnit, cfbtUnitSection]) then begin
      StartPascalCodeFoldBlock(cfbtUses);
    end;
    Result := tkKey;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func65: TtkTokenKind;
begin
  if KeyComp('Repeat') then begin
    Result := tkKey;
    StartPascalCodeFoldBlock(cfbtRepeat);
   end
   else Result := tkIdentifier;
end;

function TSynPasSyn.Func66: TtkTokenKind;
begin
  if KeyComp('Type') then begin
    if (PasCodeFoldRange.BracketNestLevel = 0)
       and (TopPascalCodeFoldBlockType in
        [cfbtVarType, cfbtLocalVarType, cfbtNone, cfbtProcedure, cfbtProgram,
         cfbtUnit, cfbtUnitSection]) and not(rsAfterEqual in fRange)
    then begin
      if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
        EndCodeFoldBlockLastLine;
      if TopPascalCodeFoldBlockType in [cfbtProcedure]
      then StartPascalCodeFoldBlock(cfbtLocalVarType)
      else StartPascalCodeFoldBlock(cfbtVarType);
    end;
    Result := tkKey;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func69: TtkTokenKind;
begin
  if KeyComp('Default') then Result := tkKey else
    if KeyComp('Dynamic') then Result := tkKey else
      if KeyComp('Message') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func71: TtkTokenKind;
begin
  if KeyComp('Stdcall') then
    Result := tkKey
  else if KeyComp('Const') then begin
    if (PasCodeFoldRange.BracketNestLevel = 0) and
        (TopPascalCodeFoldBlockType in
        [cfbtVarType, cfbtLocalVarType, cfbtNone, cfbtProcedure, cfbtProgram,
         cfbtUnit, cfbtUnitSection]) then begin
      if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
        EndCodeFoldBlockLastLine;
      if TopPascalCodeFoldBlockType in [cfbtProcedure]
      then StartPascalCodeFoldBlock(cfbtLocalVarType)
      else StartPascalCodeFoldBlock(cfbtVarType);
    end;
    Result := tkKey;
  end
  {$IFDEF SYN_LAZARUS}
  else if KeyComp('Bitpacked') then
    Result := tkKey
  {$ENDIF}
  else
    Result := tkIdentifier;
end;

function TSynPasSyn.Func73: TtkTokenKind;
begin
  if KeyComp('Except') then begin
    Result := tkKey;
    if TopPascalCodeFoldBlockType = cfbtTry then
      StartPascalCodeFoldBlock(cfbtExcept);
   end
   else Result := tkIdentifier;
end;

function TSynPasSyn.Func75: TtkTokenKind;
begin
  if KeyComp('Write') then
  begin
    if rsProperty in fRange then Result := tkKey else Result := tkIdentifier;
  end else Result := tkIdentifier;
end;

function TSynPasSyn.Func76: TtkTokenKind;
begin
  if KeyComp('Until') then begin
    Result := tkKey;
    if TopPascalCodeFoldBlockType = cfbtRepeat then EndCodeFoldBlock;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func79: TtkTokenKind;
begin
  if KeyComp('Finally') then begin
    Result := tkKey;
    if TopPascalCodeFoldBlockType = cfbtTry then
      StartPascalCodeFoldBlock(cfbtExcept);
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func81: TtkTokenKind;
begin
  if KeyComp('Stored') then
  begin
    if rsProperty in fRange then Result := tkKey else Result := tkIdentifier;
  end else
    if KeyComp('Interface') then begin
      if not(rsAfterEqual in fRange) and
         (fRange * [rsInterface, rsImplementation] = []) then
      begin
        CloseBeginEndBlocks;
        if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
          EndCodeFoldBlockLastLine;
        if TopPascalCodeFoldBlockType=cfbtUnitSection then EndCodeFoldBlockLastLine;
        StartPascalCodeFoldBlock(cfbtUnitSection);
        fRange := fRange + [rsInterface];
        // Interface has no ";", implicit end of statement
      end;
      Result := tkKey
    end
    else if KeyComp('Deprecated') then
      Result := tkKey
    else
      Result := tkIdentifier;
end;

function TSynPasSyn.Func84: TtkTokenKind;
begin
  if KeyComp('Abstract') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func85: TtkTokenKind;
begin
  if KeyComp('Forward') then Result := tkKey else
    if KeyComp('Library') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func86: TtkTokenKind;
begin
  if KeyComp('VarArgs') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func87: TtkTokenKind;
begin
  if KeyComp('String') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func88: TtkTokenKind;
begin
  if KeyComp('Program') then begin
    fRange := fRange - [rsInterface] + [rsImplementation];
    if TopPascalCodeFoldBlockType=cfbtNone then StartPascalCodeFoldBlock(cfbtProgram);
    Result := tkKey;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func91: TtkTokenKind;
begin
  if KeyComp('Downto') then Result := tkKey
  else if KeyComp('Private') then begin
    Result := tkKey;
    if (TopPascalCodeFoldBlockType in [cfbtClass, cfbtClassSection]) then begin
      if (TopPascalCodeFoldBlockType=cfbtClassSection) then
        EndCodeFoldBlockLastLine;
      StartPascalCodeFoldBlock(cfbtClassSection);
    end;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func92: TtkTokenKind;
begin
  if D4syntax and KeyComp('overload') then Result := tkKey else
    if KeyComp('Inherited') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func94: TtkTokenKind;
begin
  if KeyComp('Assembler') then Result := tkKey else
    if KeyComp('Readonly') then
    begin
      if rsProperty in fRange then Result := tkKey else Result := tkIdentifier;
    end else Result := tkIdentifier;
end;

function TSynPasSyn.Func95: TtkTokenKind;
begin
  if KeyComp('Absolute') then
    Result := tkKey
  else if KeyComp('Contains') then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynPasSyn.Func96: TtkTokenKind;
begin
  if KeyComp('Published') then begin
    Result := tkKey;
    if (TopPascalCodeFoldBlockType in [cfbtClass, cfbtClassSection]) then begin
      if (TopPascalCodeFoldBlockType=cfbtClassSection) then
        EndCodeFoldBlockLastLine;
      StartPascalCodeFoldBlock(cfbtClassSection);
    end;
  end
  else if KeyComp('Override') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func97: TtkTokenKind;
begin
  if KeyComp('Threadvar') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func98: TtkTokenKind;
begin
  if KeyComp('Export') then Result := tkKey else
    if KeyComp('Nodefault') then
    begin
      if rsProperty in fRange then Result := tkKey else Result := tkIdentifier;
    end else Result := tkIdentifier;
end;

function TSynPasSyn.Func99: TtkTokenKind;
begin
  if KeyComp('External') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func100: TtkTokenKind;
begin
  if KeyComp('Automated') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func101: TtkTokenKind;
begin
  if KeyComp('Register') then
    Result := tkKey
  else
    if KeyComp('Platform') then
      Result := tkKey
    else
      Result := tkIdentifier;
end;

function TSynPasSyn.Func102: TtkTokenKind;
begin
  if KeyComp('Function') then begin
    if not(rsAfterEqual in fRange) then begin
      PasCodeFoldRange.BracketNestLevel := 0; // Reset in case of partial code
      CloseBeginEndBlocks;
      if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
        EndCodeFoldBlockLastLine;
      if ((rsImplementation in fRange) and
          not(TopPascalCodeFoldBlockType in [cfbtClass, cfbtClassSection]))
      then
        StartPascalCodeFoldBlock(cfbtProcedure);
    end;
    Result := tkKey;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func103: TtkTokenKind;
begin
  if KeyComp('Virtual') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func105: TtkTokenKind;
begin
  if KeyComp('Procedure') then begin
    if not(rsAfterEqual in fRange) then begin
      PasCodeFoldRange.BracketNestLevel := 0; // Reset in case of partial code
      CloseBeginEndBlocks;
      if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
        EndCodeFoldBlockLastLine;
      if ((rsImplementation in fRange) and
          not(TopPascalCodeFoldBlockType in [cfbtClass, cfbtClassSection]))
      then
        StartPascalCodeFoldBlock(cfbtProcedure);
    end;
    Result := tkKey;
  end
  {$IFDEF SYN_LAZARUS}
  else if KeyComp('specialize') then
    Result := tkKey
  {$ENDIF}
  else
    Result := tkIdentifier;
end;

function TSynPasSyn.Func106: TtkTokenKind;
begin
  if KeyComp('Protected') then begin
    Result := tkKey;
    if (TopPascalCodeFoldBlockType in [cfbtClass, cfbtClassSection]) then begin
      if (TopPascalCodeFoldBlockType=cfbtClassSection) then
        EndCodeFoldBlockLastLine;
      StartPascalCodeFoldBlock(cfbtClassSection);
    end;
  end
  else Result := tkIdentifier;
end;

{$ifdef SYN_LAZARUS}
function TSynPasSyn.Func108: TtkTokenKind;
begin
  if KeyComp('Operator') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func112: TtkTokenKind;
begin
  if KeyComp('Requires') then Result := tkKey else Result := tkIdentifier;
end;
{$endif}

function TSynPasSyn.Func117: TtkTokenKind;
begin
  if KeyComp('Exports') then Result := tkKey else Result := tkIdentifier;
end;

{$ifdef SYN_LAZARUS}
function TSynPasSyn.Func122: TtkTokenKind;
begin
  if KeyComp('Otherwise') then Result := tkKey else Result := tkIdentifier;
end;
{$endif}

function TSynPasSyn.Func126: TtkTokenKind;
begin
  if D4syntax and KeyComp('Implements') then
  begin
    if rsProperty in fRange then Result := tkKey else Result := tkIdentifier;
  end else if KeyComp('NoStackFrame') then
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynPasSyn.Func128: TtkTokenKind;
begin
  if KeyComp('Widestring') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func129: TtkTokenKind;
begin
  if KeyComp('Dispinterface') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func130: TtkTokenKind;
begin
  if KeyComp('Ansistring') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func132: TtkTokenKind;
begin
  if D4syntax and KeyComp('Reintroduce') then Result := tkKey else
    Result := tkIdentifier;
end;

function TSynPasSyn.Func133: TtkTokenKind;
begin
  if KeyComp('Property') then
  begin
    Result := tkKey;
    fRange := fRange + [rsProperty];
  end else Result := tkIdentifier;
end;

function TSynPasSyn.Func136: TtkTokenKind;
begin
  if KeyComp('Finalization') then begin
    PasCodeFoldRange.BracketNestLevel := 0; // Reset in case of partial code
    CloseBeginEndBlocks;
    if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
      EndCodeFoldBlockLastLine;
    if TopPascalCodeFoldBlockType=cfbtUnitSection then EndCodeFoldBlockLastLine;
    StartPascalCodeFoldBlock(cfbtUnitSection);
    fRange := fRange - [rsInterface] + [rsImplementation];
    Result := tkKey
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func141: TtkTokenKind;
begin
  if KeyComp('Writeonly') then
  begin
    if rsProperty in fRange then Result := tkKey else Result := tkIdentifier;
  end else Result := tkIdentifier;
end;

function TSynPasSyn.Func143: TtkTokenKind;
begin
  if KeyComp('Destructor') then
  begin
    if not(rsAfterEqual in fRange) then
    begin
      PasCodeFoldRange.BracketNestLevel := 0; // Reset in case of partial code
      CloseBeginEndBlocks;
      if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
        EndCodeFoldBlockLastLine;
      if ((rsImplementation in fRange) and
          not(TopPascalCodeFoldBlockType in [cfbtClass, cfbtClassSection]))
      then
        StartPascalCodeFoldBlock(cfbtProcedure);
    end;
    Result := tkKey;
  end else
  if KeyComp('compilerproc') then // fpc modifier
    Result := tkKey
  else
    Result := tkIdentifier;
end;

function TSynPasSyn.Func166: TtkTokenKind;
begin
  if KeyComp('Constructor') then begin
    if not(rsAfterEqual in fRange) then begin
      PasCodeFoldRange.BracketNestLevel := 0; // Reset in case of partial code
      CloseBeginEndBlocks;
      if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
        EndCodeFoldBlockLastLine;
      if ((rsImplementation in fRange) and
          not(TopPascalCodeFoldBlockType in [cfbtClass, cfbtClassSection]))
      then
        StartPascalCodeFoldBlock(cfbtProcedure);
    end;
    Result := tkKey;
  end else
    if KeyComp('Implementation') then begin
      PasCodeFoldRange.BracketNestLevel := 0; // Reset in case of partial code
      CloseBeginEndBlocks;
      if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
        EndCodeFoldBlockLastLine;
      if TopPascalCodeFoldBlockType=cfbtUnitSection then EndCodeFoldBlockLastLine;
      StartPascalCodeFoldBlock(cfbtUnitSection);
      fRange := fRange - [rsInterface] + [rsImplementation];
      // implicit end of statement
      Result := tkKey;
    end else
      Result := tkIdentifier;
end;

function TSynPasSyn.Func167: TtkTokenKind;
begin
  if KeyComp('Shortstring') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.Func168: TtkTokenKind;
begin
  if KeyComp('Initialization') then begin
    PasCodeFoldRange.BracketNestLevel := 0; // Reset in case of partial code
    CloseBeginEndBlocks;
    if TopPascalCodeFoldBlockType in [cfbtVarType, cfbtLocalVarType] then
      EndCodeFoldBlockLastLine;
    if TopPascalCodeFoldBlockType=cfbtUnitSection then EndCodeFoldBlockLastLine;
    StartPascalCodeFoldBlock(cfbtUnitSection);
    fRange := fRange - [rsInterface] + [rsImplementation];
    Result := tkKey;
  end
  else Result := tkIdentifier;
end;

function TSynPasSyn.Func191: TtkTokenKind;
begin
  if KeyComp('Resourcestring') then Result := tkKey else
    if KeyComp('Stringresource') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPasSyn.AltFunc: TtkTokenKind;
begin
  Result := tkIdentifier
end;

{$IFDEF SYN_LAZARUS}
function TSynPasSyn.IdentKind(p: integer): TtkTokenKind;
var
  HashKey: Integer;
begin
  fToIdent := p;
  HashKey := KeyHash;
  if HashKey < 192 then
    Result := fIdentFuncTable[HashKey]{$IFDEF FPC}(){$ENDIF}
  else
    Result := tkIdentifier;
end;
{$ELSE}
function TSynPasSyn.IdentKind(MayBe: PChar): TtkTokenKind;
var
  HashKey: Integer;
begin
  fToIdent := MayBe;
  HashKey := KeyHash(MayBe);
  if HashKey < 192 then
    Result := fIdentFuncTable[HashKey]{$IFDEF FPC}(){$ENDIF}
  else
    Result := tkIdentifier;
end;
{$ENDIF}

procedure TSynPasSyn.MakeMethodTables;
var
  I: Char;
begin
  for I := #0 to #255 do
    {$IFDEF FPC}
    case I of
      #0: fProcTable[I] := @NullProc;
      #10: fProcTable[I] := @LFProc;
      #13: fProcTable[I] := @CRProc;
      #1..#9, #11, #12, #14..#32:
        fProcTable[I] := @SpaceProc;
      '#': fProcTable[I] := @AsciiCharProc;
      '$': fProcTable[I] := @IntegerProc;
      #39: fProcTable[I] := @StringProc;
      '0'..'9': fProcTable[I] := @NumberProc;
      'A'..'Z', 'a'..'z', '_':
        fProcTable[I] := @IdentProc;
      '{': fProcTable[I] := @BraceOpenProc;
      '}', '!', '"', '%', '&', '('..'/', ':'..'@', '['..'^', '`', '~':
        begin
          case I of
            '(': fProcTable[I] := @RoundOpenProc;
            ')': fProcTable[I] := @RoundCloseProc;
            '[': fProcTable[I] := @SquareOpenProc;
            ']': fProcTable[I] := @SquareCloseProc;
            '=': fProcTable[I] := @EqualSignProc;
            '.': fProcTable[I] := @PointProc;
            ';': fProcTable[I] := @SemicolonProc;                                //mh 2000-10-08
            '/': fProcTable[I] := @SlashProc;
            ':', '>': fProcTable[I] := @ColonOrGreaterProc;
            '<': fProcTable[I] := @LowerProc;
            '@': fProcTable[I] := @AddressOpProc;
          else
            fProcTable[I] := @SymbolProc;
          end;
        end;
    else
      fProcTable[I] := @UnknownProc;
    end;
    {$ELSE}
    case I of
      #0: fProcTable[I] := NullProc;
      #10: fProcTable[I] := LFProc;
      #13: fProcTable[I] := CRProc;
      #1..#9, #11, #12, #14..#32:
        fProcTable[I] := SpaceProc;
      '#': fProcTable[I] := AsciiCharProc;
      '$': fProcTable[I] := IntegerProc;
      #39: fProcTable[I] := StringProc;
      '0'..'9': fProcTable[I] := NumberProc;
      'A'..'Z', 'a'..'z', '_':
        fProcTable[I] := IdentProc;
      '{': fProcTable[I] := BraceOpenProc;
      '}', '!', '"', '%', '&', '('..'/', ':'..'@', '['..'^', '`', '~':
        begin
          case I of
            '(': fProcTable[I] := RoundOpenProc;
            ')': fProcTable[I] := RoundCloseProc;
            '[': fProcTable[I] := SquareOpenProc;
            ']': fProcTable[I] := SquareCloseProc;
            '=': fProcTable[I] := EqualSignProc;
            '.': fProcTable[I] := PointProc;
            ';': fProcTable[I] := SemicolonProc;                                //mh 2000-10-08
            '/': fProcTable[I] := SlashProc;
            ':', '>': fProcTable[I] := ColonOrGreaterProc;
            '<': fProcTable[I] := LowerProc;
            '@': fProcTable[I] := AddressOpProc;
          else
            fProcTable[I] := SymbolProc;
          end;
        end;
    else
      fProcTable[I] := UnknownProc;
    end;
    {$ENDIF}
end;

constructor TSynPasSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  CreateDividerDrawConfig;
  InitFoldConfig;
  fD4syntax := true;
  fAsmAttri := TSynHighlighterAttributes.Create(SYNS_AttrAssembler);
  AddAttribute(fAsmAttri);
  fCommentAttri := TSynHighlighterAttributes.Create(SYNS_AttrComment);
  fCommentAttri.Style:= [fsItalic];
  AddAttribute(fCommentAttri);
  fIdentifierAttri := TSynHighlighterAttributes.Create(SYNS_AttrIdentifier);
  AddAttribute(fIdentifierAttri);
  fKeyAttri := TSynHighlighterAttributes.Create(SYNS_AttrReservedWord);
  fKeyAttri.Style:= [fsBold];
  AddAttribute(fKeyAttri);
  fNumberAttri := TSynHighlighterAttributes.Create(SYNS_AttrNumber);
  AddAttribute(fNumberAttri);
  fSpaceAttri := TSynHighlighterAttributes.Create(SYNS_AttrSpace);
  AddAttribute(fSpaceAttri);
  fStringAttri := TSynHighlighterAttributes.Create(SYNS_AttrString);
  AddAttribute(fStringAttri);
  fSymbolAttri := TSynHighlighterAttributes.Create(SYNS_AttrSymbol);
  AddAttribute(fSymbolAttri);
  {$IFDEF SYN_LAZARUS}
  fDirectiveAttri := TSynHighlighterAttributes.Create(SYNS_AttrDirective);
  fDirectiveAttri.Style:= [fsItalic];
  AddAttribute(fDirectiveAttri);
  CompilerMode:=pcmDelphi;
  {$ENDIF}
  SetAttributesOnChange({$IFDEF FPC}@{$ENDIF}DefHighlightChange);

  InitIdent;
  MakeMethodTables;
  fRange := [];
  fAsmStart := False;
  fDefaultFilter := SYNS_FilterPascal;
  FNodeInfoLine := -1;
end; { Create }

destructor TSynPasSyn.Destroy;
begin
  DestroyDividerDrawConfig;
  inherited Destroy;
end;

procedure TSynPasSyn.SetLine(const NewValue: string; LineNumber:Integer);
begin
  //DebugLn(['TSynPasSyn.SetLine START LineNumber=',LineNumber,' Line="',NewValue,'"']);
  fLineStr := NewValue;
  fLineLen:=length(fLineStr);
  fLine:=PChar(Pointer(fLineStr));
  Run := 0;
  Inherited SetLine(NewValue,LineNumber);
  FStartCodeFoldBlockLevel := MinimumCodeFoldBlockLevel;
  PasCodeFoldRange.LastLineCodeFoldLevelFix := 0;
  PasCodeFoldRange.PasFoldFixLevel := 0;
  PasCodeFoldRange.PasFoldMinLevel :=
    PasCodeFoldRange.PasFoldEndLevel;
  FPasStartLevel := PasCodeFoldRange.PasFoldMinLevel;
  FNodeInfoLine := -1;
  fLineNumber := LineNumber;
  FAtLineStart := True;
  if not FCatchNodeInfo then
    Next;
end; { SetLine }

procedure TSynPasSyn.AddressOpProc;
begin
  fTokenID := tkSymbol;
  inc(Run);
  if fLine[Run] = '@' then inc(Run);
end;

procedure TSynPasSyn.AsciiCharProc;
begin
  fTokenID := tkString;
  inc(Run);
  while (FLine[Run] in ['0'..'9']) do inc(Run);
end;

procedure TSynPasSyn.BorProc;
begin
  {$IFDEF SYN_LAZARUS}
  fTokenID := tkComment;
  repeat
    case fLine[Run] of
    #0: break;
    '}':
      if TopPascalCodeFoldBlockType=cfbtNestedComment then
        EndCodeFoldBlock
      else begin
        fRange := fRange - [rsBor];
        Inc(Run);
        break;
      end;
    '{':
      if NestedComments then begin
        StartPascalCodeFoldBlock(cfbtNestedComment);
      end;
    end;
    Inc(Run);
  until (Run>=fLineLen) or (fLine[Run] in [#0, #10, #13]);
  {$ELSE}
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
    else begin
      fTokenID := tkComment;
      repeat
        if fLine[Run] = '}' then begin
          Inc(Run);
          fRange := fRange - [rsBor];
          break;
        end;
        Inc(Run);
      until (fLine[Run] in [#0, #10, #13]);
    end;
  end;
  {$ENDIF}
end;

{$IFDEF SYN_LAZARUS}
procedure TSynPasSyn.DirectiveProc;
begin
  fTokenID := tkDirective;
  if TextComp('mode') then begin
    // $mode directive
    inc(Run,4);
    // skip space
    while (fLine[Run] in [' ',#9,#10,#13]) do inc(Run);
    if TextComp('objfpc') then
      CompilerMode:=pcmObjFPC
    else if TextComp('delphi') then
      CompilerMode:=pcmDelphi
    else if TextComp('fpc') then
      CompilerMode:=pcmFPC
    else if TextComp('gpc') then
      CompilerMode:=pcmGPC
    else if TextComp('tp') then
      CompilerMode:=pcmTP
    else if TextComp('macpas') then
      CompilerMode:=pcmMacPas;
  end;
  repeat
    case fLine[Run] of
    #0,#10,#13: break;
    '}':
      if TopPascalCodeFoldBlockType=cfbtNestedComment then
        EndCodeFoldBlock
      else begin
        fRange := fRange - [rsDirective];
        Inc(Run);
        break;
      end;
    '{':
      if NestedComments then
        StartPascalCodeFoldBlock(cfbtNestedComment);
    end;
    Inc(Run);
  until (Run>=fLineLen);
  //DebugLn(['TSynPasSyn.DirectiveProc Run=',Run,' fTokenPos=',fTokenPos,' fLineStr=',fLineStr,' Token=',GetToken]);
end;
{$ENDIF}

procedure TSynPasSyn.BraceOpenProc;
begin
  {$IFDEF SYN_LAZARUS}
  if (Run=fLineLen-1) or (fLine[Run+1]<>'$') then begin
    // curly bracket open -> borland comment
    inc(Run);
  {$ENDIF}
    fRange := fRange + [rsBor];
    BorProc;
  {$IFDEF SYN_LAZARUS}
  end else begin
    // compiler directive
    fRange := fRange + [rsDirective];
    inc(Run,2);
    DirectiveProc;
  end;
  {$ENDIF}
end;

procedure TSynPasSyn.ColonOrGreaterProc;
begin
  fTokenID := tkSymbol;
  inc(Run);
  if fLine[Run] = '=' then inc(Run);
end;

procedure TSynPasSyn.CRProc;
begin
  fTokenID := tkSpace;
  inc(Run);
  if fLine[Run] = #10 then inc(Run);
end;

procedure TSynPasSyn.IdentProc;
begin
  {$IFDEF SYN_LAZARUS}
  fTokenID := IdentKind(Run);
  {$ELSE}
  fTokenID := IdentKind((fLine + Run));
  {$ENDIF}
  inc(Run, fStringLen);
  while Identifiers[fLine[Run]] do inc(Run);
end;

procedure TSynPasSyn.IntegerProc;
begin
  inc(Run);
  fTokenID := tkNumber;
  {$IFDEF SYN_LAZARUS}
  while (IsIntegerChar[FLine[Run]]) do inc(Run);
  {$ELSE}
  while FLine[Run] in ['0'..'9', 'A'..'F', 'a'..'f'] do inc(Run);
  {$ENDIF}
end;

procedure TSynPasSyn.LFProc;
begin
  fTokenID := tkSpace;
  inc(Run);
end;

procedure TSynPasSyn.LowerProc;
begin
  fTokenID := tkSymbol;
  inc(Run);
  if fLine[Run] in ['=', '>'] then inc(Run);
end;

procedure TSynPasSyn.NullProc;
begin
  fTokenID := tkNull;
  {$IFDEF SYN_LAZARUS}
  if Run<fLineLen then inc(Run);
  {$ENDIF}
end;

procedure TSynPasSyn.NumberProc;
begin
  inc(Run);
  fTokenID := tkNumber;
  {$IFDEF SYN_LAZARUS}
  if Run<fLineLen then begin
    while (IsNumberChar[FLine[Run]]) do begin
      if (FLine[Run]='.') and (fLine[Run+1]='.')  then
        break;
      inc(Run);
    end;
  end;
  {$ELSE}
  while FLine[Run] in ['0'..'9', '.', 'e', 'E'] do
  begin
    case FLine[Run] of
      '.':
        if FLine[Run + 1] = '.' then break;
    end;
    inc(Run);
  end;
  {$ENDIF}
end;

procedure TSynPasSyn.PointProc;
begin
  fTokenID := tkSymbol;
  inc(Run);
  if fLine[Run] in ['.', ')'] then inc(Run);
end;

procedure TSynPasSyn.AnsiProc;
begin
  {$IFDEF SYN_LAZARUS}
  fTokenID := tkComment;
  repeat
    if fLine[Run]=#0 then
      break
    else if (fLine[Run] = '*') and (fLine[Run + 1] = ')') then
    begin
      Inc(Run, 2);
      if TopPascalCodeFoldBlockType=cfbtNestedComment then begin
        EndCodeFoldBlock;
      end else begin
        fRange := fRange - [rsAnsi];
        break;
      end;
    end
    else if NestedComments
    and (fLine[Run] = '(') and (fLine[Run + 1] = '*') then
    begin
      Inc(Run,2);
      StartPascalCodeFoldBlock(cfbtNestedComment);
    end else
      Inc(Run);
  until (Run>=fLineLen) or (fLine[Run] in [#0, #10, #13]);
  {$ELSE}
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
  else
    fTokenID := tkComment;
    repeat
      if (fLine[Run] = '*') and (fLine[Run + 1] = ')') then begin
        Inc(Run, 2);
        fRange := fRange - [rsAnsi];
        break;
      end;
      Inc(Run);
    until (Run>fLineLen) or (fLine[Run] in [#0, #10, #13]);
  end;
  {$ENDIF}
end;

procedure TSynPasSyn.RoundOpenProc;
begin
  Inc(Run);
  {$IFDEF SYN_LAZARUS}
  if Run>=fLineLen then begin
    fTokenID:=tkSymbol;
    PasCodeFoldRange.IncBracketNestLevel;
    exit;
  end;
  {$ENDIF}
  case fLine[Run] of
    '*':
      begin
        Inc(Run);
        // We would not be here, if we were in a comment or directive already
        fRange := fRange + [rsAnsi];
        fTokenID := tkComment;
        if not (fLine[Run] in [#0, #10, #13]) then begin
          AnsiProc;
        end;
      end;
    '.':
      begin
        inc(Run);
        fTokenID := tkSymbol;
        PasCodeFoldRange.IncBracketNestLevel;
      end;
  else
    fTokenID := tkSymbol;
    PasCodeFoldRange.IncBracketNestLevel;
  end;
end;

procedure TSynPasSyn.RoundCloseProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
  PasCodeFoldRange.DecBracketNestLevel;
  fRange := fRange + [rsAtClosingBracket];
end;

procedure TSynPasSyn.SquareOpenProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
  PasCodeFoldRange.IncBracketNestLevel;
end;

procedure TSynPasSyn.SquareCloseProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
  PasCodeFoldRange.DecBracketNestLevel;
end;

procedure TSynPasSyn.EqualSignProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
  fRange := fRange + [rsAtEqual];
end;

procedure TSynPasSyn.SemicolonProc;
begin
  Inc(Run);
  fTokenID := tkSymbol;
  if TopPascalCodeFoldBlockType = cfbtUses then
    EndCodeFoldBlock;
  if (TopPascalCodeFoldBlockType = cfbtClass) and (rsAfterClass in fRange) then
    EndCodeFoldBlock;
  if (rsProperty in fRange) and (PasCodeFoldRange.BracketNestLevel = 0) then
    fRange := fRange - [rsProperty];
end;

procedure TSynPasSyn.SlashProc;
begin
  Inc(Run);
  if fLine[Run] = '/' then begin
    fTokenID := tkComment;
    repeat
      Inc(Run);
    until fLine[Run] in [#0, #10, #13];
  end else
    fTokenID := tkSymbol;
end;

procedure TSynPasSyn.SpaceProc;
begin
  inc(Run);
  fTokenID := tkSpace;
  {$IFDEF SYN_LAZARUS}
  while IsSpaceChar[FLine[Run]] do inc(Run);
  {$ELSE}
  while FLine[Run] in [#1..#9, #11, #12, #14..#32] do inc(Run);
  {$ENDIF}
end;

procedure TSynPasSyn.StringProc;
begin
  fTokenID := tkString;
  Inc(Run);
  {$IFDEF SYN_LAZARUS}
  while (not (fLine[Run] in [#0, #10, #13])) do begin
    if fLine[Run] = '''' then begin
      Inc(Run);
      if (fLine[Run] <> '''') then
        break;
    end;
    Inc(Run);
  end;
  {$ELSE}
  while not (fLine[Run] in [#0, #10, #13]) do begin
    if fLine[Run] = #39 then begin
      Inc(Run);
      if fLine[Run] <> #39 then
        break;
    end;
    Inc(Run);
  end;
  {$ENDIF}
end;

procedure TSynPasSyn.SymbolProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
end;

procedure TSynPasSyn.UnknownProc;
begin
  inc(Run);
  {$IFDEF SYN_LAZARUS}
  while (fLine[Run] in [#128..#191]) OR // continued utf8 subcode
   ((fLine[Run]<>#0) and (fProcTable[fLine[Run]] = @UnknownProc)) do inc(Run);
  {$ENDIF}
  fTokenID := tkUnknown;
end;

procedure TSynPasSyn.Next;
begin
  fAsmStart := False;
  fTokenPos := Run;
  {$IFDEF SYN_LAZARUS}
  if Run>=fLineLen then begin
    fTokenID := tkNull;
    exit;
  end;
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
    else
  {$ENDIF}
      if rsAnsi in fRange then
        AnsiProc
      else if rsBor in fRange then
        BorProc
      {$IFDEF SYN_LAZARUS}
      else if rsDirective in fRange then
        DirectiveProc
      {$ENDIF}
      else begin
        if rsAtEqual in fRange then
          fRange := fRange + [rsAfterEqual] - [rsAtEqual]
        else
        if rsAtClass in fRange then
          fRange := fRange + [rsAfterClass] - [rsAtClass];
        fProcTable[fLine[Run]];
        if not (FTokenID in [tkSpace, tkComment, tkDirective]) then begin
          if (PasCodeFoldRange.BracketNestLevel = 0) and
             not(rsAtClosingBracket in fRange) then
            fRange := fRange - [rsAfterClass];
          fRange := fRange - [rsAfterEqual, rsAtClosingBracket];
        end
        else
          fRange := fRange - [rsAtClosingBracket];
      end
  {$IFDEF SYN_LAZARUS}
  end;
  {$ENDIF}
  if not(FTokenID in [tkSpace, tkComment]) then
    FAtLineStart := False;
  //DebugLn(['TSynPasSyn.Next Run=',Run,' fTokenPos=',fTokenPos,' fLineStr=',fLineStr,' Token=',GetToken]);
end;

function TSynPasSyn.GetDefaultAttribute(Index: integer):
  TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := fIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := fKeyAttri;
    SYN_ATTR_STRING: Result := fStringAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
  else
    Result := nil;
  end;
end;

function TSynPasSyn.GetEol: Boolean;
begin
  Result := (fTokenID = tkNull)
            {$IFDEF SYN_LAZARUS}and (Run >= fLineLen){$ENDIF};
end;

function TSynPasSyn.GetToken: string;
var
  Len: LongInt;
begin
  Len := Run - fTokenPos;
  {$IFDEF SYN_LAZARUS}
  SetLength(Result,Len);
  if Len>0 then
    System.Move(fLine[fTokenPos],Result[1],Len);
  {$ELSE}
  SetString(Result, (FLine + fTokenPos), Len);
  {$ENDIF}
end;

{$IFDEF SYN_LAZARUS}
procedure TSynPasSyn.GetTokenEx(out TokenStart: PChar; out TokenLength: integer);
begin
  TokenLength:=Run-fTokenPos;
  if TokenLength>0 then begin
    TokenStart:=@fLine[fTokenPos];
  end else begin
    TokenStart:=nil;
  end;
end;
{$ENDIF}

function TSynPasSyn.GetTokenID: TtkTokenKind;
begin
  if not fAsmStart and (fRange * [rsAnsi, rsBor, rsDirective, rsAsm] = [rsAsm])
    and not (fTokenId in [tkNull, tkComment, tkSpace, tkDirective])
  then
    Result := tkAsm
  else
    Result := fTokenId;
end;

function TSynPasSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case GetTokenID of
    tkAsm: Result := fAsmAttri;
    tkComment: Result := fCommentAttri;
    tkIdentifier: Result := fIdentifierAttri;
    tkKey: Result := fKeyAttri;
    tkNumber: Result := fNumberAttri;
    tkSpace: Result := fSpaceAttri;
    tkString: Result := fStringAttri;
    tkSymbol: Result := fSymbolAttri;
    {$IFDEF SYN_LAZARUS}
    tkDirective: Result := fDirectiveAttri;
    {$ENDIF}
    tkUnknown: Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynPasSyn.GetTokenKind: integer;
begin
  Result := Ord(GetTokenID);
end;

function TSynPasSyn.GetTokenPos: Integer;
begin
  Result := fTokenPos;
end;

function TSynPasSyn.GetRange: Pointer;
begin
  // For speed reasons, we work with fRange instead of CodeFoldRange.RangeType
  // -> update now
  CodeFoldRange.RangeType:=Pointer(PtrUInt(Integer(fRange)));
  // return a fixed copy of the current CodeFoldRange instance
  Result := inherited GetRange;
end;

procedure TSynPasSyn.SetRange(Value: Pointer);
begin
  //DebugLn(['TSynPasSyn.SetRange START']);
  inherited SetRange(Value);
  CompilerMode := PasCodeFoldRange.Mode;
  fRange := TRangeStates(Integer(PtrUInt(CodeFoldRange.RangeType)));
  FNodeInfoLine := -1;
end;

procedure TSynPasSyn.ResetRange;
begin
  fRange := [];
  FStartCodeFoldBlockLevel:=0;
  FPasStartLevel := 0;
  Inherited ResetRange;
  CompilerMode:=pcmDelphi;
end;

procedure TSynPasSyn.EnumUserSettings(settings: TStrings);
begin
  { returns the user settings that exist in the registry }
  with TBetterRegistry.Create do
  begin
    try
      RootKey := HKEY_LOCAL_MACHINE;
      {$IFNDEF SYN_LAZARUS}
      // ToDo Registry
      if OpenKeyReadOnly('\SOFTWARE\Borland\Delphi') then
      begin
        try
          GetKeyNames(settings);
        finally
          CloseKey;
        end;
      end;
      {$ENDIF}
    finally
      Free;
    end;
  end;
end;

function TSynPasSyn.TopPascalCodeFoldBlockType(DownIndex: Integer = 0): TPascalCodeFoldBlockType;
var
  p: Pointer;
begin
  p := TopCodeFoldBlockType(DownIndex);
  if p >= CountPascalCodeFoldBlockOffset then
    p := p - PtrUInt(CountPascalCodeFoldBlockOffset);
  Result := TPascalCodeFoldBlockType(PtrUInt(p));
end;

function TSynPasSyn.FoldOpenCount(ALineIndex: Integer): integer;
begin
  Result := EndPasFoldLevel(ALineIndex) - MinimumPasFoldLevel(ALineIndex);
end;

function TSynPasSyn.FoldCloseCount(ALineIndex: Integer): integer;
begin
  Result := EndPasFoldLevel(ALineIndex - 1) - MinimumPasFoldLevel(ALineIndex);
end;

function TSynPasSyn.FoldNestCount(ALineIndex: Integer): integer;
begin
  Result := EndPasFoldLevel(ALineIndex);
end;

function TSynPasSyn.FoldLineLength(ALineIndex, FoldIndex: Integer): integer;
var
  i, lvl, cnt : Integer;
  e, m: Integer;
begin
  cnt := CurrentLines.Count;
  e := EndPasFoldLevel(ALineIndex);
  m := MinimumPasFoldLevel(ALineIndex);
  lvl := Min(m+1+FoldIndex, e);
  i := ALineIndex + 1;
  while (i < cnt) and (MinimumPasFoldLevel(i) >= lvl) do inc(i);
  // check if fold last line of block (not mixed "end begin")
  // and not lastlinefix
  if (i = cnt) or (EndPasFoldLevel(i) > MinimumPasFoldLevel(i)) then
    dec(i);
  // Amount of lines, that will become invisible (excludes the cfCollapsed line)
  Result := i - ALineIndex;
end;

function TSynPasSyn.MinimumPasFoldLevel(Index: Integer): integer;
var
  r: TSynPasSynRange;
begin
  if (Index < 0) or (Index >= CurrentLines.Count) then
    exit(0);
  r := TSynPasSynRange(CurrentRanges[Index]);
  if (r <> nil) and (Pointer(r) <> NullRange) then
    Result := Min(r.PasFoldEndLevel + LastLinePasFoldLevelFix(Index + 1),
                  r.PasFoldMinLevel)
  else
    Result := 0;
end;

function TSynPasSyn.EndPasFoldLevel(Index: Integer): integer;
var
  r: TSynPasSynRange;
begin
  if (Index < 0) or (Index >= CurrentLines.Count) then
    exit(0);
  r := TSynPasSynRange(CurrentRanges[Index]);
  if (r <> nil) and (Pointer(r) <> NullRange) then
    Result := r.PasFoldEndLevel + LastLinePasFoldLevelFix(Index + 1)
  else
    Result := 0;
end;

function TSynPasSyn.LastLinePasFoldLevelFix(Index: Integer): integer;
var
  r: TSynPasSynRange;
begin
  if (Index < 0) or (Index >= CurrentLines.Count) then
    exit(0);
  r := TSynPasSynRange(CurrentRanges[Index]);
  if (r <> nil) and (Pointer(r) <> NullRange) then
    Result := r.PasFoldFixLevel
  else
    Result := 0;
end;


function TSynPasSyn.MinimumFoldLevel(Index: Integer): integer;
var
  r: TSynPasSynRange;
begin
  if (Index < 0) or (Index >= CurrentLines.Count) then
    exit(0);
  r := TSynPasSynRange(CurrentRanges[Index]);
  if (r <> nil) and (Pointer(r) <> NullRange) then
    Result := Min(r.CodeFoldStackSize + LastLineFoldLevelFix(Index + 1),
                  r.MinimumCodeFoldBlockLevel)
  else
    Result := 0;
end;

function TSynPasSyn.EndFoldLevel(Index: Integer): integer;
var
  r: TSynPasSynRange;
begin
  if (Index < 0) or (Index >= CurrentLines.Count) then
    exit(0);
  r := TSynPasSynRange(CurrentRanges[Index]);
  if (r <> nil) and (Pointer(r) <> NullRange) then
    Result := r.CodeFoldStackSize + LastLineFoldLevelFix(Index + 1)
  else
    Result := 0;
end;

function TSynPasSyn.LastLineFoldLevelFix(Index: Integer): integer;
var
  r: TSynPasSynRange;
begin
  if (Index < 0) or (Index >= CurrentLines.Count) then
    exit(0);
  r := TSynPasSynRange(CurrentRanges[Index]);
  if (r <> nil) and (Pointer(r) <> NullRange) then
    Result := r.LastLineCodeFoldLevelFix
  else
    Result := 0;
end;


procedure TSynPasSyn.InitNode(var Node: TSynFoldNodeInfo; EndOffs: Integer;
  ABlockType: TPascalCodeFoldBlockType);
begin
  Node.LogXStart := Run;
  Node.LogXEnd := Run + fStringLen;
  Node.FoldLvlStart := CurrentCodeFoldBlockLevel;
  Node.FoldLvlEnd := CurrentCodeFoldBlockLevel + EndOffs;
  Node.FoldType := Pointer(PtrInt(ABlockType));
  if ABlockType in PascalWordTrippletRanges then
    Node.FoldAction := [sfaMarkup]
  else
    Node.FoldAction := [];
end;

function TSynPasSyn.StartPascalCodeFoldBlock(
  ABlockType: TPascalCodeFoldBlockType): TSynCustomCodeFoldBlock;
var
  p: PtrInt;
  FoldBlock: Boolean;
begin
  FoldBlock := FFoldConfig[ABlockType];
  p := 0;
  if FCatchNodeInfo then begin // exclude subblocks, because they do not increase the foldlevel yet
    GrowNodeInfoList;
    InitNode(FNodeInfoList[FNodeInfoCount], +1, ABlockType);
//    if not SubBlock then
      include(FNodeInfoList[FNodeInfoCount].FoldAction, sfaOpen);
    inc(FNodeInfoCount);
  end;
  if not FoldBlock then
    p := PtrInt(CountPascalCodeFoldBlockOffset);
  Result:=TSynCustomCodeFoldBlock(
     inherited StartCodeFoldBlock(p+Pointer(PtrInt(ABlockType)), FoldBlock));
end;

procedure TSynPasSyn.EndCodeFoldBlock(DecreaseLevel: Boolean);
begin
  DecreaseLevel := TopCodeFoldBlockType < CountPascalCodeFoldBlockOffset;
  if FCatchNodeInfo then begin // exclude subblocks, because they do not increase the foldlevel yet
    GrowNodeInfoList;
    InitNode(FNodeInfoList[FNodeInfoCount], -1, TopPascalCodeFoldBlockType);
//    if DecreaseLevel then
      include(FNodeInfoList[FNodeInfoCount].FoldAction, sfaClose);
    inc(FNodeInfoCount);
  end;
  inherited EndCodeFoldBlock(DecreaseLevel);
end;

procedure TSynPasSyn.CloseBeginEndBlocks;
begin
  if not(TopPascalCodeFoldBlockType in
         [cfbtBeginEnd, cfbtTopBeginEnd, cfbtCase, cfbtAsm, cfbtExcept, cfbtTry,
          cfbtRepeat]) then
    exit;
  while TopPascalCodeFoldBlockType in
        [cfbtBeginEnd, cfbtTopBeginEnd, cfbtCase, cfbtAsm, cfbtExcept, cfbtTry,
         cfbtRepeat] do
    EndCodeFoldBlockLastLine;
  if TopPascalCodeFoldBlockType = cfbtProcedure then
    EndCodeFoldBlockLastLine; // This procedure did have a begin/end block, so it must end too
end;

procedure TSynPasSyn.EndCodeFoldBlockLastLine;
var
  i: Integer;
begin
  i := FNodeInfoCount;
  EndCodeFoldBlock;
  if FAtLineStart then begin
    // If we are not at linestart, new folds could have been opened => handle as normal close
    if (CurrentCodeFoldBlockLevel < FStartCodeFoldBlockLevel) and
      (FStartCodeFoldBlockLevel > 0)
    then begin
      PasCodeFoldRange.DecLastLineCodeFoldLevelFix;
      dec(FStartCodeFoldBlockLevel);
    end;
    if (PasCodeFoldRange.PasFoldEndLevel < FPasStartLevel) and
      (FPasStartLevel > 0)
    then begin
      PasCodeFoldRange.DecLastLinePasFoldFix;
      dec(FPasStartLevel);
    end;
  end
  else if FNodeInfoCount > i then begin
    exclude(FNodeInfoList[FNodeInfoCount - 1].FoldAction, sfaMarkup); // not markup able
    FNodeInfoList[FNodeInfoCount - 1].LogXEnd := 0;
  end;
end;

function TSynPasSyn.GetDrawDivider(Index: integer): TSynDividerDrawConfigSetting;
  function CheckFoldNestLevel(MaxDepth, StartLvl: Integer;
    CountTypes, SkipTypes: TPascalCodeFoldBlockTypes;
    out ResultLvl: Integer): Boolean;
  var
    i, j, m: Integer;
    t: TPascalCodeFoldBlockType;
  begin
    i := 0;
    j := StartLvl;
    m := CurrentCodeFoldBlockLevel;
    t := TopPascalCodeFoldBlockType(j);
    while (i <= MaxDepth) and (j < m) and
          ((t in CountTypes) or (t in SkipTypes)) do begin
      inc(j);
      if t in CountTypes then
        inc(i);
      t := TopPascalCodeFoldBlockType(j)
    end;
    ResultLvl := i;
    Result := i <= MaxDepth;
  end;

var
  cur: TPascalCodeFoldBlockType;
  CloseCnt, ClosedByNextLine, ClosedInLastLine: Integer;
  i, top, c: Integer;
  t: TSynPasDividerDrawLocation;
begin
  Result := inherited;
  if (index = 0) then exit;
  CloseCnt :=  EndFoldLevel(Index - 1) - MinimumFoldLevel(Index);
  if (CloseCnt = 0) or (MinimumFoldLevel(Index) <> EndFoldLevel(Index)) then // not a mixed line
    exit;

  // SetRange[Index] has the folds at the start of this line
  // ClosedByNextLine: Folds closed by the next lines LastLineFix
  //                   must be taken from SetRange[Index+1] (end of this line)
  ClosedByNextLine := -LastLineFoldLevelFix(Index + 1);
  // ClosedInLastLine: Folds Closed by this lines LastLineFix
  //                   must be ignored. (They are part of SetRange[Index] / this line)
  ClosedInLastLine := -LastLineFoldLevelFix(Index);

  // Get the highest close-offset
  i := ClosedByNextLine - 1;
  if i >= 0 then begin
    SetRange(CurrentRanges[Index]);     // Checking ClosedByNextLine
    top := 0;
  end else begin
    SetRange(CurrentRanges[Index - 1]); // Checking Closed in this Line
    i := CloseCnt - ClosedByNextLine + ClosedInLastLine - 1;
    top := ClosedInLastLine;
  end;

  cur := TopPascalCodeFoldBlockType(i + 1);
  while (i >= top) do begin
    //nxt := cur; // The "next higher" close node compared to current
    cur := TopPascalCodeFoldBlockType(i);
    Result := FDividerDrawConfig[pddlUses].TopSetting; //// xxxx
    case cur of
      cfbtUnitSection:
        if FDividerDrawConfig[pddlUnitSection].MaxDrawDepth > 0 then
          exit(FDividerDrawConfig[pddlUnitSection].TopSetting);
      cfbtUses:
        if FDividerDrawConfig[pddlUses].MaxDrawDepth > 0 then
          exit(FDividerDrawConfig[pddlUses].TopSetting);
      cfbtLocalVarType:
        if CheckFoldNestLevel(FDividerDrawConfig[pddlVarLocal].MaxDrawDepth - 1,
                              i + 2, [cfbtProcedure], cfbtAll, c) then begin
          if c = 0
          then exit(FDividerDrawConfig[pddlVarLocal].TopSetting)
          else exit(FDividerDrawConfig[pddlVarLocal].NestSetting);
        end;
      cfbtVarType:
        if FDividerDrawConfig[pddlVarGlobal].MaxDrawDepth > 0 then
          exit(FDividerDrawConfig[pddlVarGlobal].TopSetting);
      cfbtClass, cfbtRecord:
        begin
          if CheckFoldNestLevel(0, i + 1, [cfbtProcedure],
                                cfbtAll - [cfbtVarType, cfbtLocalVarType], c)
          then t := pddlStructGlobal
          else t := pddlStructLocal;
          if CheckFoldNestLevel(FDividerDrawConfig[t].MaxDrawDepth - 1,
                                i + 1, [cfbtClass, cfbtRecord],
                                cfbtAll - [cfbtVarType, cfbtLocalVarType], c) then begin
            if c = 0
            then exit(FDividerDrawConfig[t].TopSetting)
            else exit(FDividerDrawConfig[t].NestSetting);
          end;
        end;
      cfbtProcedure:
        if CheckFoldNestLevel(FDividerDrawConfig[pddlProcedure].MaxDrawDepth - 1,
                              i + 1, [cfbtProcedure], cfbtAll, c) then begin
          if c = 0
          then exit(FDividerDrawConfig[pddlProcedure].TopSetting)
          else exit(FDividerDrawConfig[pddlProcedure].NestSetting);
        end;
      cfbtTopBeginEnd:
        if FDividerDrawConfig[pddlBeginEnd].MaxDrawDepth > 0 then
          exit(FDividerDrawConfig[pddlBeginEnd].TopSetting);
      cfbtBeginEnd, cfbtRepeat, cfbtCase, cfbtAsm:
        if CheckFoldNestLevel(FDividerDrawConfig[pddlBeginEnd].MaxDrawDepth - 2,
                              i + 1, [cfbtBeginEnd, cfbtRepeat, cfbtCase, cfbtAsm],
                              cfbtAll - [cfbtProcedure, cfbtTopBeginEnd], c) then
          exit(FDividerDrawConfig[pddlBeginEnd].NestSetting);
      cfbtTry:
        if CheckFoldNestLevel(FDividerDrawConfig[pddlTry].MaxDrawDepth - 1,
                              i + 1, [cfbtTry], cfbtAll - [cfbtProcedure], c)
        then begin
          if c = 0
          then exit(FDividerDrawConfig[pddlTry].TopSetting)
          else exit(FDividerDrawConfig[pddlTry].NestSetting);
        end;
    end;
    dec(i);
    if (i < top) and (ClosedByNextLine > 0) then begin
      // Switch to blocks closed in this line
      SetRange(CurrentRanges[Index - 1]);
      i := CloseCnt - ClosedByNextLine + ClosedInLastLine - 1;
      ClosedByNextLine := 0;
      top := ClosedInLastLine;
      cur := TopPascalCodeFoldBlockType(i + 1);
    end;
  end;
  Result := inherited;
end;

procedure TSynPasSyn.CreateDividerDrawConfig;
var
  i: TSynPasDividerDrawLocation;
begin
  for i := low(TSynPasDividerDrawLocation) to high(TSynPasDividerDrawLocation) do
  begin
    FDividerDrawConfig[i] := TSynDividerDrawConfig.Create;
    FDividerDrawConfig[i].OnChange := {$IFDEF FPC}@{$ENDIF}DefHighlightChange;
    FDividerDrawConfig[i].MaxDrawDepth := PasDividerDrawLocationDefaults[i];
  end;
end;

procedure TSynPasSyn.DestroyDividerDrawConfig;
var
  i: TSynPasDividerDrawLocation;
begin
  for i := low(TSynPasDividerDrawLocation) to high(TSynPasDividerDrawLocation) do
    FreeAndNil(FDividerDrawConfig[i]);
end;

procedure TSynPasSyn.InitFoldConfig;
var
  i: TPascalCodeFoldBlockType;
begin
  for i := low(TPascalCodeFoldBlockType) to high(TPascalCodeFoldBlockType) do
    FFoldConfig[i] := i in [cfbtBeginEnd, cfbtTopBeginEnd, cfbtNestedComment,
                            cfbtProcedure, cfbtUses, cfbtLocalVarType, cfbtClass,
                            cfbtClassSection, cfbtRecord, cfbtRepeat, cfbtCase,
                            cfbtAsm];
end;

function TSynPasSyn.GetFoldConfig(Index: Integer): Boolean;
begin
  // + 1 as we skip cfbtNone;
  Result := FFoldConfig[TPascalCodeFoldBlockType(Index + 1)];
end;

function TSynPasSyn.GetFoldConfigCount: Integer;
begin
  // excluded cfbtNone;
  Result := ord(high(TPascalCodeFoldBlockType)) -
            ord(low(TPascalCodeFoldBlockType));
end;

procedure TSynPasSyn.SetFoldConfig(Index: Integer; const AValue: Boolean);
begin
   if FFoldConfig[TPascalCodeFoldBlockType(Index + 1)] = AValue then
     exit;
  FFoldConfig[TPascalCodeFoldBlockType(Index + 1)] := AValue;
  FAttributeChangeNeedScan := True;
  DefHighlightChange(self);
  // Todo: Since all synedits will rescan => delete all foldranges
end;

function TSynPasSyn.GetDividerDrawConfig(Index: Integer): TSynDividerDrawConfig;
begin
  Result := FDividerDrawConfig[TSynPasDividerDrawLocation(Index)];
end;

function TSynPasSyn.GetDividerDrawConfigCount: Integer;
begin
  Result := ord(high(TSynPasDividerDrawLocation))
          - ord(low(TSynPasDividerDrawLocation)) + 1;
end;

function TSynPasSyn.GetFoldNodeInfo(Line, Index: Integer): TSynFoldNodeInfo;
var
  i: LongInt;
begin
  if FNodeInfoLine <> Line then begin
    FCatchNodeInfo := True;
    FNodeInfoCount := 0;
    StartAtLineIndex(Line);
    fStringLen := 0;
    i := LastLineFoldLevelFix(Line);
    while i < 0 do begin
      EndCodeFoldBlock;
      inc(i);
    end;
    NextToEol;
    FCatchNodeInfo := False;
    FNodeInfoLine := Line;
  end;

  if (index < 0) or (index >= FNodeInfoCount) then
    Result := inherited GetFoldNodeInfo(Line, Index)
  else
    Result := FNodeInfoList[Index];
end;

function TSynPasSyn.GetFoldNodeInfoCount(Line: Integer): Integer;
begin
  if FNodeInfoLine <> Line then
    GetFoldNodeInfo(Line, 0);
  Result := FNodeInfoCount;
end;

function TSynPasSyn.GetRangeClass: TSynCustomHighlighterRangeClass;
begin
  Result:=TSynPasSynRange;
end;

function TSynPasSyn.UseUserSettings(settingIndex: integer): boolean;
// Possible parameter values:
//   index into TStrings returned by EnumUserSettings
// Possible return values:
//   true : settings were read and used
//   false: problem reading settings or invalid version specified - old settings
//          were preserved

  function ReadDelphiSettings(settingIndex: integer): boolean;

    function ReadDelphiSetting(settingTag: string;
      attri: TSynHighlighterAttributes; key: string): boolean;

      function ReadDelphi2Or3(settingTag: string;
        attri: TSynHighlighterAttributes; name: string): boolean;
      var
        i: integer;
      begin
        for i := 1 to Length(name) do
          if name[i] = ' ' then name[i] := '_';
        Result := attri.LoadFromBorlandRegistry(HKEY_CURRENT_USER,
                '\Software\Borland\Delphi\'+settingTag+'\Highlight',name,true);
      end; { ReadDelphi2Or3 }

      function ReadDelphi4OrMore(settingTag: string;
        attri: TSynHighlighterAttributes; key: string): boolean;
      begin
        Result := attri.LoadFromBorlandRegistry(HKEY_CURRENT_USER,
               '\Software\Borland\Delphi\'+settingTag+'\Editor\Highlight',
               key,false);
      end; { ReadDelphi4OrMore }

    begin { ReadDelphiSetting }
      try
        if (settingTag[1] = '2') or (settingTag[1] = '3')
          then Result := ReadDelphi2Or3(settingTag,attri,key)
          else Result := ReadDelphi4OrMore(settingTag,attri,key);
      except Result := false; end;
    end; { ReadDelphiSetting }

  var
    tmpStringAttri    : TSynHighlighterAttributes;
    tmpNumberAttri    : TSynHighlighterAttributes;
    tmpKeyAttri       : TSynHighlighterAttributes;
    tmpSymbolAttri    : TSynHighlighterAttributes;
    tmpAsmAttri       : TSynHighlighterAttributes;
    tmpCommentAttri   : TSynHighlighterAttributes;
    {$IFDEF SYN_LAZARUS}
    tmpDirectiveAttri : TSynHighlighterAttributes;
    {$ENDIF}
    tmpIdentifierAttri: TSynHighlighterAttributes;
    tmpSpaceAttri     : TSynHighlighterAttributes;
    s                 : TStringList;

  begin { ReadDelphiSettings }
    s := TStringList.Create;
    try
      EnumUserSettings(s);
      if (settingIndex < 0) or (settingIndex >= s.Count) then Result := false
      else begin
        tmpStringAttri    := TSynHighlighterAttributes.Create('');
        tmpNumberAttri    := TSynHighlighterAttributes.Create('');
        tmpKeyAttri       := TSynHighlighterAttributes.Create('');
        tmpSymbolAttri    := TSynHighlighterAttributes.Create('');
        tmpAsmAttri       := TSynHighlighterAttributes.Create('');
        tmpCommentAttri   := TSynHighlighterAttributes.Create('');
        {$IFDEF SYN_LAZARUS}
        tmpDirectiveAttri := TSynHighlighterAttributes.Create('');
        {$ENDIF}
        tmpIdentifierAttri:= TSynHighlighterAttributes.Create('');
        tmpSpaceAttri     := TSynHighlighterAttributes.Create('');
        tmpStringAttri    .Assign(fStringAttri);
        tmpNumberAttri    .Assign(fNumberAttri);
        tmpKeyAttri       .Assign(fKeyAttri);
        tmpSymbolAttri    .Assign(fSymbolAttri);
        tmpAsmAttri       .Assign(fAsmAttri);
        tmpCommentAttri   .Assign(fCommentAttri);
        {$IFDEF SYN_LAZARUS}
        tmpDirectiveAttri .Assign(fDirectiveAttri);
        {$ENDIF}
        tmpIdentifierAttri.Assign(fIdentifierAttri);
        tmpSpaceAttri     .Assign(fSpaceAttri);
        Result := ReadDelphiSetting(s[settingIndex],fAsmAttri,'Assembler')
              and ReadDelphiSetting(s[settingIndex],fCommentAttri,'Comment')
              {$IFDEF SYN_LAZARUS}
              and ReadDelphiSetting(s[settingIndex],fDirectiveAttri,'Directive')
              {$ENDIF}
              and ReadDelphiSetting(s[settingIndex],fIdentifierAttri,'Identifier')
              and ReadDelphiSetting(s[settingIndex],fKeyAttri,'Reserved word')
              and ReadDelphiSetting(s[settingIndex],fNumberAttri,'Number')
              and ReadDelphiSetting(s[settingIndex],fSpaceAttri,'Whitespace')
              and ReadDelphiSetting(s[settingIndex],fStringAttri,'string')
              and ReadDelphiSetting(s[settingIndex],fSymbolAttri,'Symbol');
        if not Result then begin
          fStringAttri    .Assign(tmpStringAttri);
          fNumberAttri    .Assign(tmpNumberAttri);
          fKeyAttri       .Assign(tmpKeyAttri);
          fSymbolAttri    .Assign(tmpSymbolAttri);
          fAsmAttri       .Assign(tmpAsmAttri);
          fCommentAttri   .Assign(tmpCommentAttri);
          {$IFDEF SYN_LAZARUS}
          fDirectiveAttri .Assign(tmpDirectiveAttri);
          {$ENDIF}
          fIdentifierAttri.Assign(tmpIdentifierAttri);
          fSpaceAttri     .Assign(tmpSpaceAttri);
        end;
        tmpStringAttri    .Free;
        tmpNumberAttri    .Free;
        tmpKeyAttri       .Free;
        tmpSymbolAttri    .Free;
        tmpAsmAttri       .Free;
        tmpCommentAttri   .Free;
        {$IFDEF SYN_LAZARUS}
        tmpDirectiveAttri .Free;
        {$ENDIF}
        tmpIdentifierAttri.Free;
        tmpSpaceAttri     .Free;
      end;
    finally s.Free; end;
  end; { ReadDelphiSettings }

begin
  Result := ReadDelphiSettings(settingIndex);
end; { TSynPasSyn.UseUserSettings }

function TSynPasSyn.GetIdentChars: TSynIdentChars;
begin
  Result := ['_', '0'..'9', 'a'..'z', 'A'..'Z'];
end;

{$IFNDEF SYN_CPPB_1} class {$ENDIF}
function TSynPasSyn.GetLanguageName: string;
begin
  Result := SYNS_LangPascal;
end;

{$IFNDEF SYN_CPPB_1} class {$ENDIF}
function TSynPasSyn.GetCapabilities: TSynHighlighterCapabilities;
begin
  Result := inherited GetCapabilities + [hcUserSettings];
end;

{begin}                                                                         //mh 2000-10-08
function TSynPasSyn.IsFilterStored: boolean;
begin
  Result := fDefaultFilter <> SYNS_FilterPascal;
end;

procedure TSynPasSyn.CreateRootCodeFoldBlock;
begin
  inherited;
  RootCodeFoldBlock.InitRootBlockType(Pointer(PtrInt(cfbtNone)));
end;

function TSynPasSyn.IsKeyword(const AKeyword: string): boolean;
// returns true for some common keywords
// Note: this words are not always keywords (e.g. end), and some keywords are
// not listed here at all (e.g. static)
var
  i: integer;
  m: TPascalCompilerMode;
begin
  if KeywordsList = nil then begin
    KeywordsList := TStringList.Create;
    for i := 1 to High(RESERVED_WORDS_TP) do
      KeywordsList.AddObject(RESERVED_WORDS_TP[i], TObject(pcmTP));
    for i := 1 to High(RESERVED_WORDS_DELPHI) do
      KeywordsList.AddObject(RESERVED_WORDS_DELPHI[i], TObject(pcmDelphi));
    for i := 1 to High(RESERVED_WORDS_FPC) do
      KeywordsList.AddObject(RESERVED_WORDS_FPC[i], TObject(pcmFPC));
    KeywordsList.Sorted := true;
  end;
  Result := KeywordsList.Find(LowerCase(AKeyword), i);
  if not Result then exit;
  m := TPascalCompilerMode(PtrUInt(KeywordsList.Objects[i]));
  case FCompilerMode of
    pcmFPC, pcmObjFPC: ;
    pcmDelphi: Result := m in [pcmTP, pcmDelphi];
    else Result := m = pcmTP;
  end;
end;

{end}                                                                           //mh 2000-10-08

procedure TSynPasSyn.SetD4syntax(const Value: boolean);
begin
  FD4syntax := Value;
end;

{ TSynFreePascalSyn }

constructor TSynFreePascalSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  CompilerMode:=pcmObjFPC;
end;

procedure TSynFreePascalSyn.ResetRange;
begin
  inherited ResetRange;
  CompilerMode:=pcmObjFPC;
end;

{ TSynPasSynRange }

procedure TSynPasSynRange.Clear;
begin
  inherited Clear;
  FBracketNestLevel := 0;
  FLastLineCodeFoldLevelFix := 0;
  FPasFoldEndLevel := 0;
  FPasFoldFixLevel := 0;
  FPasFoldMinLevel := 0;
end;

function TSynPasSynRange.Compare(Range: TSynCustomHighlighterRange): integer;
begin
  Result:=inherited Compare(Range);
  if Result<>0 then exit;

  Result:=ord(FMode)-ord(TSynPasSynRange(Range).FMode);
  if Result<>0 then exit;
  Result := FBracketNestLevel - TSynPasSynRange(Range).FBracketNestLevel;
  if Result<>0 then exit;
  Result := FLastLineCodeFoldLevelFix - TSynPasSynRange(Range).FLastLineCodeFoldLevelFix;
  if Result<>0 then exit;
  Result := FPasFoldEndLevel - TSynPasSynRange(Range).FPasFoldEndLevel;
  if Result<>0 then exit;
  Result := FPasFoldMinLevel - TSynPasSynRange(Range).FPasFoldMinLevel;
  if Result<>0 then exit;
  Result := FPasFoldFixLevel - TSynPasSynRange(Range).FPasFoldFixLevel;
end;

procedure TSynPasSynRange.Assign(Src: TSynCustomHighlighterRange);
begin
  if (Src<>nil) and (Src<>TSynCustomHighlighterRange(NullRange)) then begin
    inherited Assign(Src);
    FMode:=TSynPasSynRange(Src).FMode;
    FBracketNestLevel:=TSynPasSynRange(Src).FBracketNestLevel;
    FLastLineCodeFoldLevelFix := TSynPasSynRange(Src).FLastLineCodeFoldLevelFix;
    FPasFoldEndLevel := TSynPasSynRange(Src).FPasFoldEndLevel;
    FPasFoldMinLevel := TSynPasSynRange(Src).FPasFoldMinLevel;
    FPasFoldFixLevel := TSynPasSynRange(Src).FPasFoldFixLevel;
  end;
end;

function TSynPasSynRange.Add(ABlockType: Pointer; IncreaseLevel: Boolean): TSynCustomCodeFoldBlock;
begin
  Result := inherited Add(ABlockType, True);
  if IncreaseLevel and assigned(result) then
    inc(FPasFoldEndLevel);
end;

procedure TSynPasSynRange.Pop(DecreaseLevel: Boolean);
begin
  if assigned(Top.Parent) then begin
    if DecreaseLevel then
      dec(FPasFoldEndLevel);
    if FPasFoldMinLevel > FPasFoldEndLevel then
      FPasFoldMinLevel := FPasFoldEndLevel;
  end;
  inherited Pop(True);
end;

function TSynPasSynRange.MaxFoldLevel: Integer;
begin
  // Protect from overly mem consumption, by too many nested folds
  Result := 100;
end;

procedure TSynPasSynRange.IncBracketNestLevel;
begin
  inc(FBracketNestLevel);
end;

procedure TSynPasSynRange.DecBracketNestLevel;
begin
  dec(FBracketNestLevel);
end;

procedure TSynPasSynRange.DecLastLineCodeFoldLevelFix;
begin
  dec(FLastLineCodeFoldLevelFix)
end;

procedure TSynPasSynRange.DecLastLinePasFoldFix;
begin
  dec(FPasFoldFixLevel);
end;

initialization
  MakeIdentTable;
{$IFNDEF SYN_CPPB_1}
  RegisterPlaceableHighlighter(TSynPasSyn);
{$ENDIF}

finalization
  FreeAndNil(KeywordsList);

end.


