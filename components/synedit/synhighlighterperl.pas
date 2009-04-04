{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterPerl.pas, released 2000-04-10.
The Original Code is based on the DcjSynPerl.pas file from the
mwEdit component suite by Martin Waldenburg and other developers, the Initial
Author of this file is Michael Trier.
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
  - Using q, qq, qw, qx, m, s, tr will not properly parse the contained
    information.
  - Not very optimized.
-------------------------------------------------------------------------------}
{
@abstract(Provides a Perl syntax highlighter for SynEdit)
@author(Michael Trier)
@created(1999, converted to SynEdit 2000-04-10 by Michael Hieke)
@lastmod(2000-06-23)
The SynHighlighterPerl unit provides SynEdit with a Perl syntax highlighter.
}
unit SynHighlighterPerl;

{$I synedit.inc}

interface

uses
  SysUtils, Classes,
  {$IFDEF SYN_CLX}
  Qt, QControls, QGraphics,
  {$ELSE}
  {$IFDEF SYN_LAZARUS}
  LCLIntf, LCLType,
  {$ELSE}
  Windows, Messages, Registry,
  {$ENDIF}
  Controls, Graphics,
  {$ENDIF}
  SynEditTypes, SynEditHighlighter;

type
  TtkTokenKind = (tkComment, tkIdentifier, tkKey, tkNull, tkNumber, tkOperator,
    tkPragma, tkSpace, tkString, tkSymbol, tkUnknown, tkVariable);

  TProcTableProc = procedure of object;
  TIdentFuncTableFunc = function: TtkTokenKind of object;

  TSynPerlSyn = class(TSynCustomHighlighter)
  private
    fLine: PChar;
    fProcTable: array[#0..#255] of TProcTableProc;
    Run: LongInt;
    fStringLen: Integer;
    fToIdent: PChar;
    fTokenPos: Integer;
    FTokenID: TtkTokenKind;
    fIdentFuncTable: array[0..2167] of TIdentFuncTableFunc;
    fLineNumber: Integer;
    fCommentAttri: TSynHighlighterAttributes;
    fIdentifierAttri: TSynHighlighterAttributes;
    fInvalidAttri: TSynHighlighterAttributes;
    fKeyAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fOperatorAttri: TSynHighlighterAttributes;
    fPragmaAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;
    fStringAttri: TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    fVariableAttri: TSynHighlighterAttributes;
    function KeyHash(ToHash: PChar): Integer;
    function KeyComp(const aKey: String): Boolean;
    function Func109: TtkTokenKind;
    function Func113: TtkTokenKind;
    function Func196: TtkTokenKind;
    function Func201: TtkTokenKind;
    function Func204: TtkTokenKind;
    function Func207: TtkTokenKind;
    function Func209: TtkTokenKind;
    function Func211: TtkTokenKind;
    function Func214: TtkTokenKind;
    function Func216: TtkTokenKind;
    function Func219: TtkTokenKind;
    function Func221: TtkTokenKind;
    function Func224: TtkTokenKind;
    function Func225: TtkTokenKind;
    function Func226: TtkTokenKind;
    function Func230: TtkTokenKind;
    function Func232: TtkTokenKind;
    function Func233: TtkTokenKind;
    function Func248: TtkTokenKind;
    function Func254: TtkTokenKind;
    function Func255: TtkTokenKind;
    function Func257: TtkTokenKind;
    function Func262: TtkTokenKind;
    function Func263: TtkTokenKind;
    function Func269: TtkTokenKind;
    function Func280: TtkTokenKind;
    function Func282: TtkTokenKind;
    function Func306: TtkTokenKind;
    function Func307: TtkTokenKind;
    function Func310: TtkTokenKind;
    function Func314: TtkTokenKind;
    function Func317: TtkTokenKind;
    function Func318: TtkTokenKind;
    function Func320: TtkTokenKind;
    function Func322: TtkTokenKind;
    function Func325: TtkTokenKind;
    function Func326: TtkTokenKind;
    function Func327: TtkTokenKind;
    function Func330: TtkTokenKind;
    function Func331: TtkTokenKind;
    function Func333: TtkTokenKind;
    function Func335: TtkTokenKind;
    function Func337: TtkTokenKind;
    function Func338: TtkTokenKind;
    function Func340: TtkTokenKind;
    function Func345: TtkTokenKind;
    function Func346: TtkTokenKind;
    function Func368: TtkTokenKind;
    function Func401: TtkTokenKind;
    function Func412: TtkTokenKind;
    function Func413: TtkTokenKind;
    function Func415: TtkTokenKind;
    function Func419: TtkTokenKind;
    function Func420: TtkTokenKind;
    function Func421: TtkTokenKind;
    function Func424: TtkTokenKind;
    function Func425: TtkTokenKind;
    function Func426: TtkTokenKind;
    function Func428: TtkTokenKind;
    function Func430: TtkTokenKind;
    function Func431: TtkTokenKind;
    function Func432: TtkTokenKind;
    function Func433: TtkTokenKind;
    function Func434: TtkTokenKind;
    function Func436: TtkTokenKind;
    function Func437: TtkTokenKind;
    function Func438: TtkTokenKind;
    function Func439: TtkTokenKind;
    function Func440: TtkTokenKind;
    function Func441: TtkTokenKind;
    function Func442: TtkTokenKind;
    function Func444: TtkTokenKind;
    function Func445: TtkTokenKind;
    function Func447: TtkTokenKind;
    function Func448: TtkTokenKind;
    function Func456: TtkTokenKind;
    function Func458: TtkTokenKind;
    function Func470: TtkTokenKind;
    function Func477: TtkTokenKind;
    function Func502: TtkTokenKind;
    function Func522: TtkTokenKind;
    function Func523: TtkTokenKind;
    function Func525: TtkTokenKind;
    function Func527: TtkTokenKind;
    function Func530: TtkTokenKind;
    function Func531: TtkTokenKind;
    function Func534: TtkTokenKind;
    function Func535: TtkTokenKind;
    function Func536: TtkTokenKind;
    function Func537: TtkTokenKind;
    function Func539: TtkTokenKind;
    function Func542: TtkTokenKind;
    function Func543: TtkTokenKind;
    function Func545: TtkTokenKind;
    function Func546: TtkTokenKind;
    function Func547: TtkTokenKind;
    function Func548: TtkTokenKind;
    function Func549: TtkTokenKind;
    function Func552: TtkTokenKind;
    function Func555: TtkTokenKind;
    function Func556: TtkTokenKind;
    function Func557: TtkTokenKind;
    function Func562: TtkTokenKind;
    function Func569: TtkTokenKind;
    function Func570: TtkTokenKind;
    function Func622: TtkTokenKind;
    function Func624: TtkTokenKind;
    function Func627: TtkTokenKind;
    function Func630: TtkTokenKind;
    function Func632: TtkTokenKind;
    function Func637: TtkTokenKind;
    function Func640: TtkTokenKind;
    function Func642: TtkTokenKind;
    function Func643: TtkTokenKind;
    function Func645: TtkTokenKind;
    function Func647: TtkTokenKind;
    function Func648: TtkTokenKind;
    function Func649: TtkTokenKind;
    function Func650: TtkTokenKind;
    function Func651: TtkTokenKind;
    function Func652: TtkTokenKind;
    function Func655: TtkTokenKind;
    function Func656: TtkTokenKind;
    function Func657: TtkTokenKind;
    function Func658: TtkTokenKind;
    function Func665: TtkTokenKind;
    function Func666: TtkTokenKind;
    function Func667: TtkTokenKind;
    function Func672: TtkTokenKind;
    function Func675: TtkTokenKind;
    function Func677: TtkTokenKind;
    function Func687: TtkTokenKind;
    function Func688: TtkTokenKind;
    function Func716: TtkTokenKind;
    function Func719: TtkTokenKind;
    function Func727: TtkTokenKind;
    function Func728: TtkTokenKind;
    function Func731: TtkTokenKind;
    function Func734: TtkTokenKind;
    function Func740: TtkTokenKind;
    function Func741: TtkTokenKind;
    function Func743: TtkTokenKind;
    function Func746: TtkTokenKind;
    function Func749: TtkTokenKind;
    function Func750: TtkTokenKind;
    function Func752: TtkTokenKind;
    function Func753: TtkTokenKind;
    function Func754: TtkTokenKind;
    function Func759: TtkTokenKind;
    function Func761: TtkTokenKind;
    function Func762: TtkTokenKind;
    function Func763: TtkTokenKind;
    function Func764: TtkTokenKind;
    function Func765: TtkTokenKind;
    function Func768: TtkTokenKind;
    function Func769: TtkTokenKind;
    function Func773: TtkTokenKind;
    function Func774: TtkTokenKind;
    function Func775: TtkTokenKind;
    function Func815: TtkTokenKind;
    function Func821: TtkTokenKind;
    function Func841: TtkTokenKind;
    function Func842: TtkTokenKind;
    function Func845: TtkTokenKind;
    function Func853: TtkTokenKind;
    function Func855: TtkTokenKind;
    function Func857: TtkTokenKind;
    function Func860: TtkTokenKind;
    function Func864: TtkTokenKind;
    function Func867: TtkTokenKind;
    function Func868: TtkTokenKind;
    function Func869: TtkTokenKind;
    function Func870: TtkTokenKind;
    function Func873: TtkTokenKind;
    function Func874: TtkTokenKind;
    function Func876: TtkTokenKind;
    function Func877: TtkTokenKind;
    function Func878: TtkTokenKind;
    function Func881: TtkTokenKind;
    function Func883: TtkTokenKind;
    function Func890: TtkTokenKind;
    function Func892: TtkTokenKind;
    function Func906: TtkTokenKind;
    function Func933: TtkTokenKind;
    function Func954: TtkTokenKind;
    function Func956: TtkTokenKind;
    function Func965: TtkTokenKind;
    function Func968: TtkTokenKind;
    function Func974: TtkTokenKind;
    function Func978: TtkTokenKind;
    function Func981: TtkTokenKind;
    function Func985: TtkTokenKind;
    function Func986: TtkTokenKind;
    function Func988: TtkTokenKind;
    function Func1056: TtkTokenKind;
    function Func1077: TtkTokenKind;
    function Func1079: TtkTokenKind;
    function Func1084: TtkTokenKind;
    function Func1086: TtkTokenKind;
    function Func1091: TtkTokenKind;
    function Func1093: TtkTokenKind;
    function Func1095: TtkTokenKind;
    function Func1103: TtkTokenKind;
    function Func1105: TtkTokenKind;
    function Func1107: TtkTokenKind;
    function Func1136: TtkTokenKind;
    function Func1158: TtkTokenKind;
    function Func1165: TtkTokenKind;
    function Func1169: TtkTokenKind;
    function Func1172: TtkTokenKind;
    function Func1176: TtkTokenKind;
    function Func1202: TtkTokenKind;
    function Func1211: TtkTokenKind;
    function Func1215: TtkTokenKind;
    function Func1218: TtkTokenKind;
    function Func1223: TtkTokenKind;
    function Func1230: TtkTokenKind;
    function Func1273: TtkTokenKind;
    function Func1277: TtkTokenKind;
    function Func1283: TtkTokenKind;
    function Func1327: TtkTokenKind;
    function Func1343: TtkTokenKind;
    function Func1361: TtkTokenKind;
    function Func1379: TtkTokenKind;
    function Func1396: TtkTokenKind;
    function Func1402: TtkTokenKind;
    function Func1404: TtkTokenKind;
    function Func1409: TtkTokenKind;
    function Func1421: TtkTokenKind;
    function Func1425: TtkTokenKind;
    function Func1440: TtkTokenKind;
    function Func1520: TtkTokenKind;
    function Func1523: TtkTokenKind;
    function Func1673: TtkTokenKind;
    function Func1752: TtkTokenKind;
    function Func1762: TtkTokenKind;
    function Func1768: TtkTokenKind;
    function Func2167: TtkTokenKind;
    procedure AndSymbolProc;
    procedure CRProc;
    procedure ColonProc;
    procedure CommentProc;
    procedure EqualProc;
    procedure GreaterProc;
    procedure IdentProc;
    procedure LFProc;
    procedure LowerProc;
    procedure MinusProc;
    procedure NotSymbolProc;
    procedure NullProc;
    procedure NumberProc;
    procedure OrSymbolProc;
    procedure PlusProc;
    procedure SlashProc;
    procedure SpaceProc;
    procedure StarProc;
    procedure StringInterpProc;
    procedure StringLiteralProc;
    procedure SymbolProc;
    procedure XOrSymbolProc;
    procedure UnknownProc;
    function AltFunc: TtkTokenKind;
    procedure InitIdent;
    function IdentKind(MayBe: PChar): TtkTokenKind;
    procedure MakeMethodTables;
  protected
    function GetIdentChars: TSynIdentChars; override;
  public
    {$IFNDEF SYN_CPPB_1} class {$ENDIF}                                         //mh 2000-07-14
    function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
      override;
    function GetEol: Boolean; override;
    function GetTokenID: TtkTokenKind;
    procedure SetLine({$IFDEF FPC}const {$ENDIF}NewValue: String;
      LineNumber:Integer); override;
    function GetToken: String; override;
    {$IFDEF SYN_LAZARUS}
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;
    {$ENDIF}
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: integer; override;
    function GetTokenPos: Integer; override;
    procedure Next; override;
  published
    property CommentAttri: TSynHighlighterAttributes read fCommentAttri
      write fCommentAttri;
    property IdentifierAttri: TSynHighlighterAttributes read fIdentifierAttri
      write fIdentifierAttri;
    property InvalidAttri: TSynHighlighterAttributes read fInvalidAttri
      write fInvalidAttri;
    property KeyAttri: TSynHighlighterAttributes read fKeyAttri write fKeyAttri;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri
      write fNumberAttri;
    property OperatorAttri: TSynHighlighterAttributes read fOperatorAttri
      write fOperatorAttri;
    property PragmaAttri: TSynHighlighterAttributes read fPragmaAttri
      write fPragmaAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri
      write fSpaceAttri;
    property StringAttri: TSynHighlighterAttributes read fStringAttri
      write fStringAttri;
    property SymbolAttri: TSynHighlighterAttributes read fSymbolAttri
      write fSymbolAttri;
    property VariableAttri: TSynHighlighterAttributes read fVariableAttri
      write fVariableAttri;
  end;

implementation

uses
  SynEditStrConst;

var
  Identifiers: array[#0..#255] of ByteBool;
//  mHashTable: array[#0..#255] of Integer;

procedure MakeIdentTable;
var
  I: Char;
begin
  for I := #0 to #255 do
  begin
    Case I of
      '_', '0'..'9', 'a'..'z', 'A'..'Z': Identifiers[I] := True;
    else Identifiers[I] := False;
    end;
    {Case I in['%', '@', '$', '_', 'a'..'z', 'A'..'Z'] of
      True:
        begin
          if (I > #64) and (I < #91) then mHashTable[I] := Ord(I) - 64 else
            if (I > #96) then mHashTable[I] := Ord(I) - 95;
        end;
    else mHashTable[I] := 0;
    end;}
  end;
end;

procedure TSynPerlSyn.InitIdent;
var
  I: Integer;
begin
  for I := 0 to 2167 do
    Case I of
      109: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}Func109;
      113: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func113;
      196: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func196;
      201: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func201;
      204: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func204;
      207: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func207;
      209: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func209;
      211: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func211;
      214: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func214;
      216: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func216;
      219: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func219;
      221: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func221;
      224: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func224;
      225: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func225;
      226: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func226;
      230: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func230;
      232: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func232;
      233: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func233;
      248: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func248;
      254: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func254;
      255: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func255;
      257: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func257;
      262: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func262;
      263: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func263;
      269: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func269;
      280: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func280;
      282: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func282;
      306: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func306;
      307: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func307;
      310: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func310;
      314: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func314;
      317: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func317;
      318: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func318;
      320: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func320;
      322: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func322;
      325: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func325;
      326: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func326;
      327: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func327;
      330: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func330;
      331: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func331;
      333: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func333;
      335: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func335;
      337: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func337;
      338: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func338;
      340: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func340;
      345: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func345;
      346: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func346;
      368: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func368;
      401: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func401;
      412: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func412;
      413: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func413;
      415: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func415;
      419: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func419;
      420: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func420;
      421: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func421;
      424: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func424;
      425: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func425;
      426: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func426;
      428: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func428;
      430: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func430;
      431: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func431;
      432: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func432;
      433: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func433;
      434: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func434;
      436: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func436;
      437: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func437;
      438: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func438;
      439: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func439;
      440: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func440;
      441: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func441;
      442: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func442;
      444: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func444;
      445: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func445;
      447: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func447;
      448: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func448;
      456: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func456;
      458: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func458;
      470: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func470;
      477: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func477;
      502: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func502;
      522: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func522;
      523: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func523;
      525: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func525;
      527: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func527;
      530: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func530;
      531: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func531;
      534: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func534;
      535: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func535;
      536: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func536;
      537: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func537;
      539: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func539;
      542: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func542;
      543: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func543;
      545: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func545;
      546: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func546;
      547: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func547;
      548: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func548;
      549: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func549;
      552: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func552;
      555: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func555;
      556: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func556;
      557: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func557;
      562: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func562;
      569: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func569;
      570: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func570;
      622: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func622;
      624: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func624;
      627: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func627;
      630: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func630;
      632: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func632;
      637: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func637;
      640: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func640;
      642: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func642;
      643: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func643;
      645: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func645;
      647: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func647;
      648: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func648;
      649: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func649;
      650: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func650;
      651: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func651;
      652: fIdentFuncTable[I] :={$IFDEF FPC}@{$ENDIF}func652;
      655: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func655;
      656: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func656;
      657: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func657;
      658: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func658;
      665: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func665;
      666: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func666;
      667: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func667;
      672: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func672;
      675: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func675;
      677: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func677;
      687: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func687;
      688: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func688;
      716: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func716;
      719: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func719;
      727: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func727;
      728: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func728;
      731: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func731;
      734: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func734;
      740: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func740;
      741: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func741;
      743: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func743;
      746: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func746;
      749: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func749;
      750: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func750;
      752: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func752;
      753: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func753;
      754: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func754;
      759: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func759;
      761: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func761;
      762: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func762;
      763: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func763;
      764: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func764;
      765: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func765;
      768: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func768;
      769: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func769;
      773: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func773;
      774: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func774;
      775: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func775;
      815: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func815;
      821: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func821;
      841: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func841;
      842: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func842;
      845: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func845;
      853: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func853;
      855: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func855;
      857: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func857;
      860: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func860;
      864: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func864;
      867: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func867;
      868: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func868;
      869: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func869;
      870: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func870;
      873: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func873;
      874: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func874;
      876: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func876;
      877: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func877;
      878: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func878;
      881: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func881;
      883: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func883;
      890: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func890;
      892: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func892;
      906: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func906;
      933: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func933;
      954: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func954;
      956: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func956;
      965: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func965;
      968: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func968;
      974: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func974;
      978: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func978;
      981: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func981;
      985: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func985;
      986: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func986;
      988: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func988;
      1056: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1056;
      1077: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1077;
      1079: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1079;
      1084: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1084;
      1086: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1086;
      1091: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1091;
      1093: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1093;
      1095: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1095;
      1103: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1103;
      1105: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1105;
      1107: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1107;
      1136: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1136;
      1158: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1158;
      1165: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1165;
      1169: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1169;
      1172: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1172;
      1176: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1176;
      1202: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1202;
      1211: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1211;
      1215: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1215;
      1218: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1218;
      1223: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1223;
      1230: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1230;
      1273: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1273;
      1277: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1277;
      1283: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1283;
      1327: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1327;
      1343: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1343;
      1361: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1361;
      1379: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1379;
      1396: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1396;
      1402: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1402;
      1404: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1404;
      1409: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1409;
      1421: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1421;
      1425: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1425;
      1440: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1440;
      1520: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1520;
      1523: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1523;
      1673: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1673;
      1752: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1752;
      1762: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1762;
      1768: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func1768;
      2167: fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}func2167;
    else fIdentFuncTable[I] := {$IFDEF FPC}@{$ENDIF}AltFunc;
    end;
end;

function TSynPerlSyn.KeyHash(ToHash: PChar): Integer;
begin
  Result := 0;
  while ToHash^ in ['%', '@', '$', '_', '0'..'9', 'a'..'z', 'A'..'Z'] do
  begin
    inc(Result, Integer(ToHash^));
    inc(ToHash);
  end;
  fStringLen := ToHash - fToIdent;
end; { KeyHash }

function TSynPerlSyn.KeyComp(const aKey: String): Boolean;
var
  I: Integer;
  Temp: PChar;
begin
  Temp := fToIdent;
  if Length(aKey) = fStringLen then
  begin
    Result := True;
    for i := 1 to fStringLen do begin
      if Temp^ <> aKey[i] then
      begin
        Result := False;
        break;
      end;
      inc(Temp);
    end;
  end else Result := False;
end; { KeyComp }

function TSynPerlSyn.Func109: TtkTokenKind;
begin
  if KeyComp('m') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func113: TtkTokenKind;
begin
  if KeyComp('q') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func196: TtkTokenKind;
begin
  if KeyComp('$NR') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func201: TtkTokenKind;
begin
  if KeyComp('$RS') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func204: TtkTokenKind;
begin
  if KeyComp('ge') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func207: TtkTokenKind;
begin
  if KeyComp('lc') then Result := tkKey else
    if KeyComp('if') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func209: TtkTokenKind;
begin
  if KeyComp('le') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func211: TtkTokenKind;
begin
  if KeyComp('ne') then Result := tkOperator else
    if KeyComp('do') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func214: TtkTokenKind;
begin
  if KeyComp('eq') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func216: TtkTokenKind;
begin
  if KeyComp('uc') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func219: TtkTokenKind;
begin
  if KeyComp('gt') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func221: TtkTokenKind;
begin
  if KeyComp('no') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func224: TtkTokenKind;
begin
  if KeyComp('lt') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func225: TtkTokenKind;
begin
  if KeyComp('or') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func226: TtkTokenKind;
begin
  if KeyComp('qq') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func230: TtkTokenKind;
begin
  if KeyComp('tr') then Result := tkKey else
    if KeyComp('my') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func232: TtkTokenKind;
begin
  if KeyComp('qw') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func233: TtkTokenKind;
begin
  if KeyComp('qx') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func248: TtkTokenKind;
begin
  if KeyComp('$GID') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func254: TtkTokenKind;
begin
  if KeyComp('$ARG') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func255: TtkTokenKind;
begin
  if KeyComp('%INC') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func257: TtkTokenKind;
begin
  if KeyComp('$PID') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func262: TtkTokenKind;
begin
  if KeyComp('$UID') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func263: TtkTokenKind;
begin
  if KeyComp('$SIG') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func269: TtkTokenKind;
begin
  if KeyComp('$ENV') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func280: TtkTokenKind;
begin
  if KeyComp('$ORS') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func282: TtkTokenKind;
begin
  if KeyComp('@INC') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func306: TtkTokenKind;
begin
  if KeyComp('die') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func307: TtkTokenKind;
begin
  if KeyComp('and') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func310: TtkTokenKind;
begin
  if KeyComp('abs') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func314: TtkTokenKind;
begin
  if KeyComp('eof') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func317: TtkTokenKind;
begin
  if KeyComp('ref') then Result := tkKey else
    if KeyComp('chr') then Result := tkKey else
      if KeyComp('$EGID') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func318: TtkTokenKind;
begin
  if KeyComp('vec') then Result := tkKey else
    if KeyComp('map') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func320: TtkTokenKind;
begin
  if KeyComp('cmp') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func322: TtkTokenKind;
begin
  if KeyComp('tie') then Result := tkKey else
    if KeyComp('log') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func325: TtkTokenKind;
begin
  if KeyComp('hex') then Result := tkKey else
    if KeyComp('ord') then Result := tkKey else
      if KeyComp('cos') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func326: TtkTokenKind;
begin
  if KeyComp('oct') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func327: TtkTokenKind;
begin
  if KeyComp('for') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func330: TtkTokenKind;
begin
  if KeyComp('sin') then Result := tkKey else
    if KeyComp('sub') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func331: TtkTokenKind;
begin
  if KeyComp('$EUID') then Result := tkVariable else
    if KeyComp('int') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func333: TtkTokenKind;
begin
  if KeyComp('use') then Result := tkKey else
    if KeyComp('exp') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func335: TtkTokenKind;
begin
  if KeyComp('pop') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func337: TtkTokenKind;
begin
  if KeyComp('not') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func338: TtkTokenKind;
begin
  if KeyComp('pos') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func340: TtkTokenKind;
begin
  if KeyComp('$ARGV') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func345: TtkTokenKind;
begin
  if KeyComp('xor') then Result := tkOperator else Result := tkIdentifier;
end;

function TSynPerlSyn.Func346: TtkTokenKind;
begin
  if KeyComp('$OFMT') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func368: TtkTokenKind;
begin
  if KeyComp('@ARGV') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func401: TtkTokenKind;
begin
  if KeyComp('$MATCH') then Result := tkVariable else
    if KeyComp('each') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func412: TtkTokenKind;
begin
  if KeyComp('read') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func413: TtkTokenKind;
begin
  if KeyComp('bind') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func415: TtkTokenKind;
begin
  if KeyComp('pack') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func419: TtkTokenKind;
begin
  if KeyComp('getc') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func420: TtkTokenKind;
begin
  if KeyComp('glob') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func421: TtkTokenKind;
begin
  if KeyComp('exec') then Result := tkKey else
    if KeyComp('rand') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func424: TtkTokenKind;
begin
  if KeyComp('seek') then Result := tkKey else
    if KeyComp('eval') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func425: TtkTokenKind;
begin
  if KeyComp('else') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func426: TtkTokenKind;
begin
  if KeyComp('chop') then Result := tkKey else
    if KeyComp('redo') then Result := tkKey else
      if KeyComp('send') then Result := tkKey else
        if KeyComp('$ERRNO') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func428: TtkTokenKind;
begin
  if KeyComp('kill') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func430: TtkTokenKind;
begin
  if KeyComp('grep') then Result := tkKey else
    if KeyComp('pipe') then Result := tkKey else
      if KeyComp('link') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func431: TtkTokenKind;
begin
  if KeyComp('time') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func432: TtkTokenKind;
begin
  if KeyComp('recv') then Result := tkKey else
    if KeyComp('join') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func433: TtkTokenKind;
begin
  if KeyComp('tell') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func434: TtkTokenKind;
begin
  if KeyComp('open') then Result := tkKey else
    if KeyComp('fork') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func436: TtkTokenKind;
begin
  if KeyComp('last') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func437: TtkTokenKind;
begin
  if KeyComp('wait') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func438: TtkTokenKind;
begin
  if KeyComp('dump') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func439: TtkTokenKind;
begin
  if KeyComp('less') then Result := tkPragma else Result := tkIdentifier;
end;

function TSynPerlSyn.Func440: TtkTokenKind;
begin
  if KeyComp('warn') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func441: TtkTokenKind;
begin
  if KeyComp('goto') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func442: TtkTokenKind;
begin
  if KeyComp('exit') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func444: TtkTokenKind;
begin
  if KeyComp('vars') then Result := tkPragma else
    if KeyComp('keys') then Result := tkKey else
      if KeyComp('stat') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func445: TtkTokenKind;
begin
  if KeyComp('subs') then Result := tkPragma else Result := tkIdentifier;
end;

function TSynPerlSyn.Func447: TtkTokenKind;
begin
  if KeyComp('next') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func448: TtkTokenKind;
begin
  if KeyComp('push') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func456: TtkTokenKind;
begin
  if KeyComp('sort') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func458: TtkTokenKind;
begin
  if KeyComp('sqrt') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func470: TtkTokenKind;
begin
  if KeyComp('atan2') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func477: TtkTokenKind;
begin
  if KeyComp('$PERLDB') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func502: TtkTokenKind;
begin
  if KeyComp('$SUBSEP') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func522: TtkTokenKind;
begin
  if KeyComp('chdir') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func523: TtkTokenKind;
begin
  if KeyComp('local') then Result := tkKey else
    if KeyComp('chmod') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func525: TtkTokenKind;
begin
  if KeyComp('alarm') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func527: TtkTokenKind;
begin
  if KeyComp('flock') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func530: TtkTokenKind;
begin
  if KeyComp('undef') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func531: TtkTokenKind;
begin
  if KeyComp('elsif') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func534: TtkTokenKind;
begin
  if KeyComp('close') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func535: TtkTokenKind;
begin
  if KeyComp('mkdir') then Result := tkKey else
    if KeyComp('fcntl') then Result := tkKey else
      if KeyComp('chomp') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func536: TtkTokenKind;
begin
  if KeyComp('index') then Result := tkKey else
    if KeyComp('srand') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func537: TtkTokenKind;
begin
  if KeyComp('sleep') then Result := tkKey else
    if KeyComp('while') then Result := tkKey else
      if KeyComp('bless') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func539: TtkTokenKind;
begin
  if KeyComp('ioctl') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func542: TtkTokenKind;
begin
  if KeyComp('shift') then Result := tkKey else
    if KeyComp('rmdir') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func543: TtkTokenKind;
begin
  if KeyComp('chown') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func545: TtkTokenKind;
begin
  if KeyComp('umask') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func546: TtkTokenKind;
begin
  if KeyComp('times') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func547: TtkTokenKind;
begin
  if KeyComp('reset') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func548: TtkTokenKind;
begin
  if KeyComp('semop') then Result := tkKey else
    if KeyComp('utime') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func549: TtkTokenKind;
begin
  if KeyComp('untie') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func552: TtkTokenKind;
begin
  if KeyComp('lstat') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func555: TtkTokenKind;
begin
  if KeyComp('write') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func556: TtkTokenKind;
begin
  if KeyComp('split') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func557: TtkTokenKind;
begin
  if KeyComp('print') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func562: TtkTokenKind;
begin
  if KeyComp('crypt') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func569: TtkTokenKind;
begin
  if KeyComp('study') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func570: TtkTokenKind;
begin
  if KeyComp('$WARNING') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func622: TtkTokenKind;
begin
  if KeyComp('$BASETIME') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func624: TtkTokenKind;
begin
  if KeyComp('locale') then Result := tkPragma else
    if KeyComp('accept') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func627: TtkTokenKind;
begin
  if KeyComp('caller') then Result := tkKey else
    if KeyComp('delete') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func630: TtkTokenKind;
begin
  if KeyComp('scalar') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func632: TtkTokenKind;
begin
  if KeyComp('rename') then Result := tkKey else
    if KeyComp('$PREMATCH') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func637: TtkTokenKind;
begin
  if KeyComp('fileno') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func640: TtkTokenKind;
begin
  if KeyComp('splice') then Result := tkKey else
    if KeyComp('select') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func642: TtkTokenKind;
begin
  if KeyComp('length') then Result := tkKey else
    if KeyComp('unpack') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func643: TtkTokenKind;
begin
  if KeyComp('gmtime') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func645: TtkTokenKind;
begin
  if KeyComp('semget') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func647: TtkTokenKind;
begin
  if KeyComp('msgget') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func648: TtkTokenKind;
begin
  if KeyComp('shmget') then Result := tkKey else
    if KeyComp('semctl') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func649: TtkTokenKind;
begin
  if KeyComp('socket') then Result := tkKey else
    if KeyComp('format') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func650: TtkTokenKind;
begin
  if KeyComp('rindex') then Result := tkKey else
    if KeyComp('msgctl') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func651: TtkTokenKind;
begin
  if KeyComp('shmctl') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func652: TtkTokenKind;
begin
  if KeyComp('msgsnd') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func655: TtkTokenKind;
begin
  if KeyComp('listen') then Result := tkKey else
    if KeyComp('chroot') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func656: TtkTokenKind;
begin
  if KeyComp('values') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func657: TtkTokenKind;
begin
  if KeyComp('unlink') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func658: TtkTokenKind;
begin
  if KeyComp('msgrcv') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func665: TtkTokenKind;
begin
  if KeyComp('strict') then Result := tkPragma else Result := tkIdentifier;
end;

function TSynPerlSyn.Func666: TtkTokenKind;
begin
  if KeyComp('unless') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func667: TtkTokenKind;
begin
  if KeyComp('import') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func672: TtkTokenKind;
begin
  if KeyComp('return') then Result := tkKey else
    if KeyComp('exists') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func675: TtkTokenKind;
begin
  if KeyComp('substr') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func677: TtkTokenKind;
begin
  if KeyComp('system') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func687: TtkTokenKind;
begin
  if KeyComp('$OS_ERROR') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func688: TtkTokenKind;
begin
  if KeyComp('$DEBUGGING') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func716: TtkTokenKind;
begin
  if KeyComp('package') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func719: TtkTokenKind;
begin
  if KeyComp('defined') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func727: TtkTokenKind;
begin
  if KeyComp('$POSTMATCH') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func728: TtkTokenKind;
begin
  if KeyComp('foreach') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func731: TtkTokenKind;
begin
  if KeyComp('readdir') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func734: TtkTokenKind;
begin
  if KeyComp('binmode') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func740: TtkTokenKind;
begin
  if KeyComp('shmread') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func741: TtkTokenKind;
begin
  if KeyComp('dbmopen') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func743: TtkTokenKind;
begin
  if KeyComp('seekdir') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func746: TtkTokenKind;
begin
  if KeyComp('connect') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func749: TtkTokenKind;
begin
  if KeyComp('getppid') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func750: TtkTokenKind;
begin
  if KeyComp('integer') then Result := tkPragma else Result := tkIdentifier;
end;

function TSynPerlSyn.Func752: TtkTokenKind;
begin
  if KeyComp('telldir') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func753: TtkTokenKind;
begin
  if KeyComp('opendir') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func754: TtkTokenKind;
begin
  if KeyComp('waitpid') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func759: TtkTokenKind;
begin
  if KeyComp('lcfirst') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func761: TtkTokenKind;
begin
  if KeyComp('getpgrp') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func762: TtkTokenKind;
begin
  if KeyComp('sigtrap') then Result := tkPragma else Result := tkIdentifier;
end;

function TSynPerlSyn.Func763: TtkTokenKind;
begin
  if KeyComp('sysread') then Result := tkKey else
    if KeyComp('syscall') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func764: TtkTokenKind;
begin
  if KeyComp('reverse') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func765: TtkTokenKind;
begin
  if KeyComp('require') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func768: TtkTokenKind;
begin
  if KeyComp('ucfirst') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func769: TtkTokenKind;
begin
  if KeyComp('unshift') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func773: TtkTokenKind;
begin
  if KeyComp('setpgrp') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func774: TtkTokenKind;
begin
  if KeyComp('sprintf') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func775: TtkTokenKind;
begin
  if KeyComp('symlink') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func815: TtkTokenKind;
begin
  if KeyComp('$PROCESS_ID') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func821: TtkTokenKind;
begin
  if KeyComp('$EVAL_ERROR') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func841: TtkTokenKind;
begin
  if KeyComp('dbmclose') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func842: TtkTokenKind;
begin
  if KeyComp('readlink') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func845: TtkTokenKind;
begin
  if KeyComp('getgrgid') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func853: TtkTokenKind;
begin
  if KeyComp('getgrnam') then Result := tkKey else
    if KeyComp('closedir') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func855: TtkTokenKind;
begin
  if KeyComp('endgrent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func857: TtkTokenKind;
begin
  if KeyComp('getlogin') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func860: TtkTokenKind;
begin
  if KeyComp('formline') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func864: TtkTokenKind;
begin
  if KeyComp('getgrent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func867: TtkTokenKind;
begin
  if KeyComp('getpwnam') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func868: TtkTokenKind;
begin
  if KeyComp('$ACCUMULATOR') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func869: TtkTokenKind;
begin
  if KeyComp('endpwent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func870: TtkTokenKind;
begin
  if KeyComp('truncate') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func873: TtkTokenKind;
begin
  if KeyComp('getpwuid') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func874: TtkTokenKind;
begin
  if KeyComp('constant') then Result := tkPragma else Result := tkIdentifier;
end;

function TSynPerlSyn.Func876: TtkTokenKind;
begin
  if KeyComp('setgrent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func877: TtkTokenKind;
begin
  if KeyComp('$FORMAT_NAME') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func878: TtkTokenKind;
begin
  if KeyComp('getpwent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func881: TtkTokenKind;
begin
  if KeyComp('$CHILD_ERROR') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func883: TtkTokenKind;
begin
  if KeyComp('shmwrite') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func890: TtkTokenKind;
begin
  if KeyComp('setpwent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func892: TtkTokenKind;
begin
  if KeyComp('shutdown') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func906: TtkTokenKind;
begin
  if KeyComp('syswrite') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func933: TtkTokenKind;
begin
  if KeyComp('$INPLACE_EDIT') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func954: TtkTokenKind;
begin
  if KeyComp('localtime') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func956: TtkTokenKind;
begin
  if KeyComp('$PROGRAM_NAME') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func965: TtkTokenKind;
begin
  if KeyComp('endnetent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func968: TtkTokenKind;
begin
  if KeyComp('rewinddir') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func974: TtkTokenKind;
begin
  if KeyComp('getnetent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func978: TtkTokenKind;
begin
  if KeyComp('$REAL_USER_ID') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func981: TtkTokenKind;
begin
  if KeyComp('quotemeta') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func985: TtkTokenKind;
begin
  if KeyComp('wantarray') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func986: TtkTokenKind;
begin
  if KeyComp('setnetent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func988: TtkTokenKind;
begin
  if KeyComp('$PERL_VERSION') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1056: TtkTokenKind;
begin
  if KeyComp('$REAL_GROUP_ID') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1077: TtkTokenKind;
begin
  if KeyComp('socketpair') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1079: TtkTokenKind;
begin
  if KeyComp('$SYSTEM_FD_MAX') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1084: TtkTokenKind;
begin
  if KeyComp('endhostent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1086: TtkTokenKind;
begin
  if KeyComp('endservent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1091: TtkTokenKind;
begin
  if KeyComp('getsockopt') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1093: TtkTokenKind;
begin
  if KeyComp('gethostent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1095: TtkTokenKind;
begin
  if KeyComp('getservent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1103: TtkTokenKind;
begin
  if KeyComp('setsockopt') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1105: TtkTokenKind;
begin
  if KeyComp('sethostent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1107: TtkTokenKind;
begin
  if KeyComp('setservent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1136: TtkTokenKind;
begin
  if KeyComp('$LIST_SEPARATOR') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1158: TtkTokenKind;
begin
  if KeyComp('$EXECUTABLE_NAME') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1165: TtkTokenKind;
begin
  if KeyComp('getpeername') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1169: TtkTokenKind;
begin
  if KeyComp('getsockname') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1172: TtkTokenKind;
begin
  if KeyComp('$FORMAT_FORMFEED') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1176: TtkTokenKind;
begin
  if KeyComp('diagnostics') then Result := tkPragma else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1202: TtkTokenKind;
begin
  if KeyComp('endprotoent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1211: TtkTokenKind;
begin
  if KeyComp('getprotoent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1215: TtkTokenKind;
begin
  if KeyComp('$FORMAT_TOP_NAME') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1218: TtkTokenKind;
begin
  if KeyComp('getpriority') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1223: TtkTokenKind;
begin
  if KeyComp('setprotoent') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1230: TtkTokenKind;
begin
  if KeyComp('setpriority') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1273: TtkTokenKind;
begin
  if KeyComp('$LAST_PAREN_MATCH') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1277: TtkTokenKind;
begin
  if KeyComp('getnetbyaddr') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1283: TtkTokenKind;
begin
  if KeyComp('getnetbyname') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1327: TtkTokenKind;
begin
  if KeyComp('$OUTPUT_AUTOFLUSH') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1343: TtkTokenKind;
begin
  if KeyComp('$EFFECTIVE_USER_ID') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1361: TtkTokenKind;
begin
  if KeyComp('$FORMAT_LINES_LEFT') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1379: TtkTokenKind;
begin
  if KeyComp('$INPUT_LINE_NUMBER') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1396: TtkTokenKind;
begin
  if KeyComp('gethostbyaddr') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1402: TtkTokenKind;
begin
  if KeyComp('gethostbyname') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1404: TtkTokenKind;
begin
  if KeyComp('getservbyname') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1409: TtkTokenKind;
begin
  if KeyComp('$MULTILINE_MATCHING') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1421: TtkTokenKind;
begin
  if KeyComp('$EFFECTIVE_GROUP_ID') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1425: TtkTokenKind;
begin
  if KeyComp('$FORMAT_PAGE_NUMBER') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1440: TtkTokenKind;
begin
  if KeyComp('getservbyport') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1520: TtkTokenKind;
begin
  if KeyComp('getprotobyname') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1523: TtkTokenKind;
begin
  if KeyComp('$SUBSCRIPT_SEPARATOR') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1673: TtkTokenKind;
begin
  if KeyComp('$FORMAT_LINES_PER_PAGE') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1752: TtkTokenKind;
begin
  if KeyComp('getprotobynumber') then Result := tkKey else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1762: TtkTokenKind;
begin
  if KeyComp('$INPUT_RECORD_SEPARATOR') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func1768: TtkTokenKind;
begin
  if KeyComp('$OUTPUT_FIELD_SEPARATOR') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.Func2167: TtkTokenKind;
begin
  if KeyComp('$FORMAT_LINE_BREAK_CHARACTERS') then Result := tkVariable else Result := tkIdentifier;
end;

function TSynPerlSyn.AltFunc: TtkTokenKind;
begin
  Result := tkIdentifier;
end;

function TSynPerlSyn.IdentKind(MayBe: PChar): TtkTokenKind;
var
  HashKey: Integer;
begin
  fToIdent := MayBe;
  HashKey := KeyHash(MayBe);
  if HashKey < 2168 then
    Result := fIdentFuncTable[HashKey]{$IFDEF FPC}(){$ENDIF}
  else
    Result := tkIdentifier;
end;

procedure TSynPerlSyn.MakeMethodTables;
var
  I: Char;
begin
  for I := #0 to #255 do
    case I of
      '&': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}AndSymbolProc;
      #13: fProcTable[I] := {$IFDEF FPC}@{$ENDIF}CRProc;
      ':': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}ColonProc;
      '#': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}CommentProc;
      '=': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}EqualProc;
      '>': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}GreaterProc;
      '%', '@', '$', 'A'..'Z', 'a'..'z', '_':
           fProcTable[I] := {$IFDEF FPC}@{$ENDIF}IdentProc;
      #10: fProcTable[I] := {$IFDEF FPC}@{$ENDIF}LFProc;
      '<': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}LowerProc;
      '-': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}MinusProc;
      '!': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}NotSymbolProc;
      #0: fProcTable[I] := {$IFDEF FPC}@{$ENDIF}NullProc;
      '0'..'9', '.': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}NumberProc;
      '|': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}OrSymbolProc;
      '+': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}PlusProc;
      '/': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}SlashProc;
      #1..#9, #11, #12, #14..#32: fProcTable[I] := {$IFDEF FPC}@{$ENDIF}SpaceProc;
      '*': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}StarProc;
      #34: fProcTable[I] := {$IFDEF FPC}@{$ENDIF}StringInterpProc;
      #39: fProcTable[I] := {$IFDEF FPC}@{$ENDIF}StringLiteralProc;
      '^': fProcTable[I] := {$IFDEF FPC}@{$ENDIF}XOrSymbolProc;
      '(', ')', '[', ']', '\', '{', '}', ',', ';', '?', '~':
        fProcTable[I] := {$IFDEF FPC}@{$ENDIF}SymbolProc;
    else
      fProcTable[I] := {$IFDEF FPC}@{$ENDIF}UnknownProc;
    end;
end;

constructor TSynPerlSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCommentAttri := TSynHighlighterAttributes.Create(SYNS_AttrComment);
  fCommentAttri.Style:= [fsItalic];
  AddAttribute(fCommentAttri);
  fIdentifierAttri := TSynHighlighterAttributes.Create(SYNS_AttrIdentifier);
  AddAttribute(fIdentifierAttri);
  fInvalidAttri := TSynHighlighterAttributes.Create(SYNS_AttrIllegalChar);
  AddAttribute(fInvalidAttri);
  fKeyAttri := TSynHighlighterAttributes.Create(SYNS_AttrReservedWord);
  fKeyAttri.Style:= [fsBold];
  AddAttribute(fKeyAttri);
  fNumberAttri := TSynHighlighterAttributes.Create(SYNS_AttrNumber);
  AddAttribute(fNumberAttri);
  fOperatorAttri := TSynHighlighterAttributes.Create(SYNS_AttrOperator);
  AddAttribute(fOperatorAttri);
  fPragmaAttri := TSynHighlighterAttributes.Create(SYNS_AttrPragma);
  fPragmaAttri.Style := [fsBold];
  AddAttribute(fPragmaAttri);
  fSpaceAttri := TSynHighlighterAttributes.Create(SYNS_AttrSpace);
  fSpaceAttri.Foreground := clWindow;
  AddAttribute(fSpaceAttri);
  fStringAttri := TSynHighlighterAttributes.Create(SYNS_AttrString);
  AddAttribute(fStringAttri);
  fSymbolAttri := TSynHighlighterAttributes.Create(SYNS_AttrSymbol);
  AddAttribute(fSymbolAttri);
  fVariableAttri := TSynHighlighterAttributes.Create(SYNS_AttrVariable);
  fVariableAttri.Style := [fsBold];
  AddAttribute(fVariableAttri);
  SetAttributesOnChange({$IFDEF FPC}@{$ENDIF}DefHighlightChange);
  InitIdent;
  MakeMethodTables;
  fDefaultFilter := SYNS_FilterPerl;
end; { Create }

procedure TSynPerlSyn.SetLine({$IFDEF FPC}const {$ENDIF}NewValue: String;
  LineNumber:Integer);
begin
  fLine := PChar(NewValue);
  Run := 0;
  fLineNumber := LineNumber;
  Next;
end; { SetLine }

procedure TSynPerlSyn.AndSymbolProc;
begin
  case FLine[Run + 1] of
    '=':                               {bit and assign}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '&':
      begin
        if FLine[Run + 2] = '=' then   {logical and assign}
          inc(Run, 3)
        else                           {logical and}
          inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {bit and}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.CRProc;
begin
  fTokenID := tkSpace;
  Case FLine[Run + 1] of
    #10: inc(Run, 2);
  else inc(Run);
  end;
end;

procedure TSynPerlSyn.ColonProc;
begin
  Case FLine[Run + 1] of
    ':':                               {double colon}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {colon}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.CommentProc;
begin
  fTokenID := tkComment;
  repeat
    case FLine[Run] of
      #0, #10, #13: break;
    end;
    inc(Run);
  until FLine[Run] = #0;
end;

procedure TSynPerlSyn.EqualProc;
begin
  case FLine[Run + 1] of
    '=':                               {logical equal}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '>':                               {digraph}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '~':                               {bind scalar to pattern}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {assign}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.GreaterProc;
begin
  Case FLine[Run + 1] of
    '=':                               {greater than or equal to}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '>':
      begin
        if FLine[Run + 2] = '=' then   {shift right assign}
          inc(Run, 3)
        else                           {shift right}
          inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {greater than}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.IdentProc;
begin
  Case FLine[Run] of
    '$':
      begin
        Case FLine[Run + 1] of
          '!'..'+', '-'..'@', '['..']', '_', '`', '|', '~':
            begin                      {predefined variables}
              inc(Run, 2);
              fTokenID := tkVariable;
              exit;
            end;
          '^':
            begin
              Case FLine[Run + 2] of
                'A', 'D', 'F', 'I', 'L', 'P', 'T', 'W', 'X':
                  begin                {predefined variables}
                    inc(Run, 3);
                    fTokenID := tkVariable;
                    exit;
                  end;
                #0, #10, #13:          {predefined variables}
                  begin
                    inc(Run, 2);
                    fTokenID := tkVariable;
                    exit;
                  end;
              end;
            end;
        end;
      end;
    '%':
      begin
        Case FLine[Run + 1] of
          '=':                         {mod assign}
            begin
              inc(Run, 2);
              fTokenID := tkSymbol;
              exit;
            end;
          #0, #10, #13:                {mod}
            begin
              inc(Run);
              fTokenID := tkSymbol;
              exit;
            end;
        end;
      end;
    'x':
      begin
        Case FLine[Run + 1] of
          '=':                         {repetition assign}
            begin
              inc(Run, 2);
              fTokenID := tkSymbol;
              exit;
            end;
          #0, #10, #13:                {repetition}
            begin
              inc(Run);
              fTokenID := tkSymbol;
              exit;
            end;
        end;
      end;
  end;
  {regular identifier}
  fTokenID := IdentKind((fLine + Run));
  inc(Run, fStringLen);
  while Identifiers[fLine[Run]] do inc(Run);
end;

procedure TSynPerlSyn.LFProc;
begin
  fTokenID := tkSpace;
  inc(Run);
end;

procedure TSynPerlSyn.LowerProc;
begin
  case FLine[Run + 1] of
    '=':
      begin
        if FLine[Run + 2] = '>' then   {compare - less than, equal, greater}
          inc(Run, 3)
        else                           {less than or equal to}
          inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '<':
      begin
        if FLine[Run + 2] = '=' then   {shift left assign}
          inc(Run, 3)
        else                           {shift left}
          inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {less than}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.MinusProc;
begin
  case FLine[Run + 1] of
    '=':                               {subtract assign}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '-':                               {decrement}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '>':                               {arrow}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {subtract}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.NotSymbolProc;
begin
  case FLine[Run + 1] of
    '~':                               {logical negated bind like =~}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '=':                               {not equal}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {not}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.NullProc;
begin
  fTokenID := tkNull;
end;

procedure TSynPerlSyn.NumberProc;
begin
  if FLine[Run] = '.' then
  begin
    case FLine[Run + 1] of
      '.':
        begin
          inc(Run, 2);
          if FLine[Run] = '.' then     {sed range}
            inc(Run);

          fTokenID := tkSymbol;        {range}
          exit;
        end;
      '=':
        begin
          inc(Run, 2);
          fTokenID := tkSymbol;        {concatenation assign}
          exit;
        end;
      'a'..'z', 'A'..'Z', '_':
        begin
          fTokenID := tkSymbol;        {concatenation}
          inc(Run);
          exit;
        end;
    end;
  end;
  inc(Run);
  fTokenID := tkNumber;
  while FLine[Run] in
      ['0'..'9', '-', '_', '.', 'A'..'F', 'a'..'f', 'x', 'X'] do
  begin
    case FLine[Run] of
      '.':
        if FLine[Run + 1] = '.' then break;
      '-':                             {check for e notation}
        if not ((FLine[Run + 1] = 'e') or (FLine[Run + 1] = 'E')) then break;
    end;
    inc(Run);
  end;
end;

procedure TSynPerlSyn.OrSymbolProc;
begin
  case FLine[Run + 1] of
    '=':                               {bit or assign}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '|':
      begin
        if FLine[Run + 2] = '=' then   {logical or assign}
          inc(Run, 3)
        else                           {logical or}
          inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {bit or}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.PlusProc;
begin
  case FLine[Run + 1] of
    '=':                               {add assign}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '+':                               {increment}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {add}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.SlashProc;
begin
  case FLine[Run + 1] of
    '=':                               {division assign}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {division}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.SpaceProc;
begin
  inc(Run);
  fTokenID := tkSpace;
  while FLine[Run] in [#1..#9, #11, #12, #14..#32] do inc(Run);
end;

procedure TSynPerlSyn.StarProc;
begin
  case FLine[Run + 1] of
    '=':                               {multiply assign}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
    '*':
      begin
        if FLine[Run + 2] = '=' then   {exponentiation assign}
          inc(Run, 3)
        else                           {exponentiation}
          inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {multiply}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.StringInterpProc;
begin
  fTokenID := tkString;
  if (FLine[Run + 1] = #34) and (FLine[Run + 2] = #34) then inc(Run, 2);
  repeat
    case FLine[Run] of
      #0, #10, #13: break;
      #92:
        { backslash quote not the ending one }
        if FLine[Run + 1] = #34 then inc(Run);
    end;
    inc(Run);
  until FLine[Run] = #34;
  if FLine[Run] <> #0 then inc(Run);
end;

procedure TSynPerlSyn.StringLiteralProc;
begin
  fTokenID := tkString;
  repeat
    case FLine[Run] of
      #0, #10, #13: break;
    end;
    inc(Run);
  until FLine[Run] = #39;
  if FLine[Run] <> #0 then inc(Run);
end;

procedure TSynPerlSyn.SymbolProc;
begin
  inc(Run);
  fTokenId := tkSymbol;
end;

procedure TSynPerlSyn.XOrSymbolProc;
begin
  Case FLine[Run + 1] of
    '=':                               {xor assign}
      begin
        inc(Run, 2);
        fTokenID := tkSymbol;
      end;
  else                                 {xor}
    begin
      inc(Run);
      fTokenID := tkSymbol;
    end;
  end;
end;

procedure TSynPerlSyn.UnknownProc;
begin
{$IFDEF SYN_MBCSSUPPORT}
  if FLine[Run] in LeadBytes then
    Inc(Run,2)
  else
{$ENDIF}
  inc(Run);
  {$IFDEF SYN_LAZARUS}
  while (fLine[Run] in [#128..#191]) OR // continued utf8 subcode
   ((fLine[Run]<>#0) and (fProcTable[fLine[Run]] = @UnknownProc)) do inc(Run);
  {$ENDIF}
  fTokenID := tkUnknown;
end;

procedure TSynPerlSyn.Next;
begin
  fTokenPos := Run;
  fProcTable[fLine[Run]]{$IFDEF FPC}(){$ENDIF};
end;

function TSynPerlSyn.GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := fIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := fKeyAttri;
    SYN_ATTR_STRING: Result := fStringAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL: Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynPerlSyn.GetEol: Boolean;
begin
  Result := fTokenID = tkNull;
end;

function TSynPerlSyn.GetToken: string;
var
  Len: LongInt;
begin
  Result := '';
  Len := Run - fTokenPos;
  SetString(Result, (FLine + fTokenPos), Len);
end;

{$IFDEF SYN_LAZARUS}
procedure TSynPerlSyn.GetTokenEx(out TokenStart: PChar;
  out TokenLength: integer);
begin
  TokenLength:=Run-fTokenPos;
  TokenStart:=FLine + fTokenPos;
end;
{$ENDIF}

function TSynPerlSyn.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TSynPerlSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case fTokenID of
    tkComment: Result := fCommentAttri;
    tkIdentifier: Result := fIdentifierAttri;
    tkKey: Result := fKeyAttri;
    tkNumber: Result := fNumberAttri;
    tkOperator: Result := fOperatorAttri;
    tkPragma: Result := fPragmaAttri;
    tkSpace: Result := fSpaceAttri;
    tkString: Result := fStringAttri;
    tkSymbol: Result := fSymbolAttri;
    tkUnknown: Result := fInvalidAttri;
    tkVariable: Result := fVariableAttri;
    else Result := nil;
  end;
end;

function TSynPerlSyn.GetTokenKind: integer;
begin
  Result := Ord(fTokenId);
end;

function TSynPerlSyn.GetTokenPos: Integer;
begin
  Result := fTokenPos;
end;

function TSynPerlSyn.GetIdentChars: TSynIdentChars;
begin
  Result := ['%', '@', '$', '_', '0'..'9', 'a'..'z', 'A'..'Z'] + TSynSpecialChars;
end;

{$IFNDEF SYN_CPPB_1} class {$ENDIF}                                             //mh 2000-07-14
function TSynPerlSyn.GetLanguageName: string;
begin
  Result := SYNS_LangPerl;
end;

initialization
  MakeIdentTable;
{$IFNDEF SYN_CPPB_1}                                                            //mh 2000-07-14
  RegisterPlaceableHighlighter(TSynPerlSyn);
{$ENDIF}
end.

