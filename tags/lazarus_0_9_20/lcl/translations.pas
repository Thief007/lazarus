{ $Id$}
{
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

  Author: Mattias Gaertner

  Abstract:
    Methods and classes for loading translations/localizations from po files.

  Example:

    procedure TForm1.FormCreate(Sender: TObject);
    var
      PODirectory: String;
    begin
      PODirectory:='/path/to/lazarus/lcl/languages/';
      TranslateUnitResourceStrings('LCLStrConsts',PODirectory+'lcl.%s.po',
                                   'nl','');
      MessageDlg('Title','Text',mtInformation,[mbOk,mbCancel,mbYes],0);
    end;

}
unit Translations;

{$mode objfpc}{$H+}{$INLINE ON}

{$IF defined(VER2_0_2) and defined(win32)}
// FPC <= 2.0.2 compatibility code
// WINDOWS define was added after FPC 2.0.2
  {$define WINDOWS}
{$endif}

interface

uses
  Classes, SysUtils, LCLProc, FileUtil, StringHashList
  {$IFDEF UNIX}{$IFNDEF DisableCWString}, cwstring{$ENDIF}{$ENDIF}
  {$IFDEF MultiLocale},LConv{$ENDIF};

type
  { TPOFileItem }

  TPOFileItem = class
  public
    Identifier: string;
    Original: string;
    Translation: string;
    constructor Create(const TheIdentifier, TheOriginal, TheTranslated: string);
  end;

  { TPOFile }

  TPOFile = class
  protected
    FItems: TFPList;// list of TPOFileItem
    FIdentifierToItem: TStringHashList;
    FOriginalToItem: TStringHashList;
  public
    constructor Create(const AFilename: String);
    constructor Create(AStream: TStream);
    destructor Destroy; override;
    procedure ReadPOText(const s: string);
    procedure Add(const Identifier, OriginalValue, TranslatedValue: string);
    function Translate(const Identifier, OriginalValue: String): String;
  end;

  EPOFileError = class(Exception);

var
  SystemCharSetIsUTF8: Boolean = false;


// translate resource strings for one unit
procedure TranslateUnitResourceStrings(const ResUnitName, BaseFilename,
  Lang, FallbackLang: string);
function UTF8ToSystemCharSet(const s: string): string;
  {$ifndef MultiLocale} inline;{$endif}
procedure InitTranslation;


implementation

var
  TranslationInitialized: Boolean = false;


function UTF8ToSystemCharSet(const s: string): string; {$ifndef MultiLocale} inline;{$endif}
begin
  if SystemCharSetIsUTF8 then
    exit(s);
  {$IFDEF NoUTF8Translations}
  Result:=s;
  {$ELSE}
    {$IFNDEF MultiLocale}
    Result:=Utf8ToAnsi(s);
    {$ELSE}
    try
    if (LowerCase(GetDefaultCodepage)<>'utf8')
      and (LowerCase(GetDefaultCodepage)<>'utf-8')then
      Result:=CPConvert(s,'utf8',LowerCase(GetDefaultCodepage)) else Result:=s;
    except Result:=s;end;
    {$ENDIF}
  {$ENDIF}
end;

procedure InitTranslation;
var
  Lang: String;
begin
  if TranslationInitialized then exit;
  TranslationInitialized:=true;

  Lang := SysUtils.GetEnvironmentVariable('LC_ALL');
  if Lang = '' then begin
    Lang := SysUtils.GetEnvironmentVariable('LC_MESSAGES');
    if Lang = '' then begin
      Lang := SysUtils.GetEnvironmentVariable('LANG');
    end;
  end;
  
  SystemCharSetIsUTF8:=(System.Pos('UTF8',Lang)>0)
                        or (System.Pos('UTF-8',Lang)>0)
end;

{$ifndef ver2_0}
function Translate (Name,Value : AnsiString; Hash : Longint; arg:pointer) : AnsiString;
var
  po: TPOFile;
begin
  po:=TPOFile(arg);
  // get UTF8 string
  result := po.Translate(Name,Value);
  // convert UTF8 to current local
  if result<>'' then
    result:=UTF8ToSystemCharSet(result);
end;
{$endif ver2_0}

function DoTranslateUnitResourceStrings(const ResUnitName, AFilename: string
  ): boolean;
var
{$ifdef ver2_0}
  TableID, StringID, TableCount: Integer;
  s: String;
  DefValue: String;
{$endif ver2_0}
  po: TPOFile;
begin
  Result:=false;
  InitTranslation;
  //debugln('DoTranslateUnitResourceStrings) ResUnitName="',ResUnitName,'" AFilename="',AFilename,'"');
  if (ResUnitName='') or (AFilename='') or (not FileExists(AFilename)) then
    exit;
  try
    po := nil;
    // read .po file
    po := TPOFile.Create(AFilename);
    try
{$ifdef ver2_0}
      for TableID:=0 to ResourceStringTableCount - 1 do begin
        TableCount := ResourceStringCount(TableID);

        // check if this table belongs to the ResUnitName
        if TableCount=0 then continue;
        s:=GetResourceStringName(TableID,0);
        if CompareText(ResUnitName+'.',LeftStr(s,length(ResUnitName)+1))<>0
        then continue;

        // translate all resource strings of the unit
        for StringID := 0 to TableCount - 1 do begin
          DefValue:=GetResourceStringDefaultValue(TableID,StringID);
          // get UTF8 string
          s := po.Translate(GetResourceStringName(TableID,StringID),DefValue);

          if Length(s) > 0 then begin
            // convert UTF8 to current local
            s:=UTF8ToSystemCharSet(s);
            SetResourceStringValue(TableID,StringID,s);
          end;
        end;
      end;
{$else ver2_0}
      SetUnitResourceStrings(ResUnitName,@Translate,po);
{$endif ver2_0}
    finally
      po.Free;
    end;
    Result:=true;
  except
    on e: Exception do begin
      DebugLn('Exception while translating ', ResUnitName);
      DebugLn(e.Message);
    end;
  end;
end;

procedure TranslateUnitResourceStrings(const ResUnitName, BaseFilename,
  Lang, FallbackLang: string);
begin
  if (ResUnitName='') or (BaseFilename='') then exit;

  //debugln('TranslateUnitResourceStrings BaseFilename="',BaseFilename,'"');
  if (FallbackLang<>'') then
    DoTranslateUnitResourceStrings(ResUnitName,Format(BaseFilename,[FallbackLang]));
  if (Lang<>'') then
    DoTranslateUnitResourceStrings(ResUnitName,Format(BaseFilename,[Lang]));
end;

{ TPOFile }

constructor TPOFile.Create(const AFilename: String);
var
  f: TStream;
begin
  f := TFileStream.Create(AFilename, fmOpenRead);
  try
    Self.Create(f);
  finally
    f.Free;
  end;
end;

constructor TPOFile.Create(AStream: TStream);
var
  Size: Integer;
  s: string;
begin
  inherited Create;

  FItems:=TFPList.Create;
  FIdentifierToItem:=TStringHashList.Create(false);
  FOriginalToItem:=TStringHashList.Create(true);

  Size:=AStream.Size-AStream.Position;
  if Size<=0 then exit;
  SetLength(s,Size);
  AStream.Read(s[1],Size);
  ReadPOText(s);
end;

destructor TPOFile.Destroy;
var
  i: Integer;
begin
  for i:=0 to FItems.Count-1 do
    TObject(FItems[i]).Free;
  FItems.Free;
  FIdentifierToItem.Free;
  FOriginalToItem.Free;
  inherited Destroy;
end;

procedure TPOFile.ReadPOText(const s: string);
{ Read a .po file. Structure:

Example
#: lazarusidestrconsts:lisdonotshowsplashscreen
msgid "                      Do not show splash screen"
msgstr ""

}
const
  sCommentIdentifier: PChar = '#: ';
  sMsgID: PChar = 'msgid "';
  sMsgStr: PChar = 'msgstr "';
var
  l: Integer;
  LineLen: Integer;
  p: PChar;
  LineStart: PChar;
  LineEnd: PChar;
  Identifier: String;
  MsgID: String;
  MsgStr: String;
  TextEnd: PChar;
begin
  if s='' then exit;
  l:=length(s);
  p:=PChar(s);
  LineStart:=p;
  TextEnd:=p+l;
  while LineStart<TextEnd do begin
    LineEnd:=LineStart;
    while (not (LineEnd^ in [#0,#10,#13])) do inc(LineEnd);
    LineLen:=LineEnd-LineStart;
    if LineLen>0 then begin
      if CompareMem(LineStart,sCommentIdentifier,3) then begin
        Identifier:=copy(s,LineStart-p+4,LineLen-3);
      end else if CompareMem(LineStart,sMsgID,7) then begin
        MsgID:=UTF8CStringToUTF8String(LineStart+7,LineLen-8);
      end else if CompareMem(LineStart,sMsgStr,8) then begin
        //MsgStr:=copy(s,LineStart-p+9,LineLen-9);
        MsgStr:=UTF8CStringToUTF8String(LineStart+8,LineLen-9);
        Add(Identifier,MsgID,MsgStr);
      end;
    end;
    LineStart:=LineEnd+1;
    while (LineStart<TextEnd) and (LineStart^ in [#10,#13]) do inc(LineStart);
  end;
end;

procedure TPOFile.Add(const Identifier, OriginalValue, TranslatedValue: string
  );
var
  Item: TPOFileItem;
begin
  if (TranslatedValue='') then exit;
  //debugln('TPOFile.Add Identifier="',Identifier,'" OriginalValue="',OriginalValue,'" TranslatedValue="',TranslatedValue,'"');
  Item:=TPOFileItem.Create(Identifier,OriginalValue,TranslatedValue);
  FItems.Add(Item);
  FIdentifierToItem.Add(Identifier,Item);
  FOriginalToItem.Add(OriginalValue,Item);
end;

function TPOFile.Translate(const Identifier, OriginalValue: String): String;
var
  Item: TPOFileItem;
begin
  Item:=TPOFileItem(FIdentifierToItem.Data[Identifier]);
  if Item=nil then
    Item:=TPOFileItem(FOriginalToItem.Data[OriginalValue]);
  if Item<>nil then begin
    Result:=Item.Translation;
    if Result='' then RaiseGDBException('TPOFile.Translate Inconsistency');
  end else
    Result:=OriginalValue;
end;

{ TPOFileItem }

constructor TPOFileItem.Create(const TheIdentifier, TheOriginal,
  TheTranslated: string);
begin
  Identifier:=TheIdentifier;
  Original:=TheOriginal;
  Translation:=TheTranslated;
end;

initialization
  InitTranslation;

end.


