{
 /***************************************************************************
                        w32versioninfo.pas  -  Lazarus IDE unit
                        ---------------------------------------
                   TVersionInfo is responsible for the inclusion of the
                   version information in windows executables.


                   Initial Revision  : Sun Feb 20 12:00:00 CST 2006


 ***************************************************************************/

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
unit W32VersionInfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, LCLProc, Controls, Forms, FileUtil,
  CodeToolManager, LazConf, Laz_XMLCfg, IDEProcs, ProjectResourcesIntf,
  resource, versionresource, versiontypes;

type
  { TProjectVersionInfo }

  TProjectVersionInfo = class(TAbstractProjectResource)
  private
    FAutoIncrementBuild: boolean;
    FCommentsString: string;
    FCompanyString: string;
    FCopyrightString: string;
    FDescriptionString: string;
    FHexCharSet: string;
    FHexLang: string;
    FInternalNameString: string;
    FOriginalFilenameString: string;
    FProdNameString: string;
    FProductVersionString: string;
    FTrademarksString: string;
    FUseVersionInfo: boolean;
    FVersion: TFileProductVersion;
    function GetCharSets: TStringList;
    function GetHexCharSets: TStringList;
    function GetHexLanguages: TStringList;
    function GetLanguages: TStringList;
    function GetVersion(AIndex: integer): integer;
    procedure SetAutoIncrementBuild(const AValue: boolean);
    procedure SetCommentsString(const AValue: string);
    procedure SetCompanyString(const AValue: string);
    procedure SetCopyrightString(const AValue: string);
    procedure SetDescriptionString(const AValue: string);
    procedure SetHexCharSet(const AValue: string);
    procedure SetHexLang(const AValue: string);
    procedure SetInternalNameString(const AValue: string);
    procedure SetOriginalFilenameString(const AValue: string);
    procedure SetProdNameString(const AValue: string);
    procedure SetProductVersionString(const AValue: string);
    procedure SetTrademarksString(const AValue: string);
    procedure SetUseVersionInfo(const AValue: boolean);
    procedure SetVersion(AIndex: integer; const AValue: integer);
    function ExtractProductVersion: TFileProductVersion;
  public
    procedure DoBeforeBuild(AResources: TAbstractProjectResources;
      SaveToTestDir: boolean); override;
    function UpdateResources(AResources: TAbstractProjectResources;
      const MainFilename: string): boolean; override;
    procedure WriteToProjectFile(AConfig: {TXMLConfig}TObject; Path: string); override;
    procedure ReadFromProjectFile(AConfig: {TXMLConfig}TObject; Path: string); override;

    property UseVersionInfo: boolean read FUseVersionInfo write SetUseVersionInfo;
    property AutoIncrementBuild: boolean read FAutoIncrementBuild
      write SetAutoIncrementBuild;

    property MajorVersionNr: integer index 0 read GetVersion write SetVersion;
    property MinorVersionNr: integer index 1 read GetVersion write SetVersion;
    property RevisionNr: integer index 2 read GetVersion write SetVersion;
    property BuildNr: integer index 3 read GetVersion write SetVersion;

    property HexLang: string read FHexLang write SetHexLang;
    property HexCharSet: string read FHexCharSet write SetHexCharSet;
    property DescriptionString: string read FDescriptionString
      write SetDescriptionString;
    property CopyrightString: string read FCopyrightString write SetCopyrightString;
    property CommentsString: string read FCommentsString write SetCommentsString;
    property CompanyString: string read FCompanyString write SetCompanyString;
    property InternalNameString: string read FInternalNameString
      write SetInternalNameString;
    property TrademarksString: string read FTrademarksString write SetTrademarksString;
    property OriginalFilenameString: string
      read FOriginalFilenameString write SetOriginalFilenameString;
    property ProdNameString: string read FProdNameString write SetProdNameString;
    property ProductVersionString: string read FProductVersionString
      write SetProductVersionString;
  end;

function MSLanguageToHex(const s: string): string;
function MSHexToLanguage(const s: string): string;
function MSCharacterSetToHex(const s: string): string;
function MSHexToCharacterSet(const s: string): string;

function MSLanguages: TStringList;
function MSHexLanguages: TStringList;
function MSCharacterSets: TStringList;
function MSHexCharacterSets: TStringList;

const
  DefaultLanguage = '0409';
  DefaultCharSet = '04E4';

implementation

var
  // languages
  fLanguages: TStringList = nil;
  fHexLanguages: TStringList = nil;

  // character sets
  fCharSets: TStringList = nil;
  fHexCharSets: TStringList = nil;

procedure CreateCharSets;
begin
  if fCharSets <> nil then
    exit;
  fCharSets := TStringList.Create;
  fHexCharSets := TStringList.Create;

  fCharSets.Add('7-bit ASCII');
  fHexCharSets.Add('0000');
  fCharSets.Add('Japan (Shift - JIS X-0208)');
  fHexCharSets.Add('03A4');
  fCharSets.Add('Korea (Shift - KSC 5601)');
  fHexCharSets.Add('03B5');
  fCharSets.Add('Taiwan (Big5)');
  fHexCharSets.Add('03B6');
  fCharSets.Add('Unicode');
  fHexCharSets.Add('04B0');
  fCharSets.Add('Latin-2 (Eastern European)');
  fHexCharSets.Add('04E2');
  fCharSets.Add('Cyrillic');
  fHexCharSets.Add('04E3');
  fCharSets.Add('Multilingual');
  fHexCharSets.Add('04E4');
  fCharSets.Add('Greek');
  fHexCharSets.Add('04E5');
  fCharSets.Add('Turkish');
  fHexCharSets.Add('04E6');
  fCharSets.Add('Hebrew');
  fHexCharSets.Add('04E7');
  fCharSets.Add('Arabic');
  fHexCharSets.Add('04E8');
end;

procedure CreateLanguages;
begin
  if fLanguages <> nil then
    exit;
  fLanguages := TStringList.Create;
  fHexLanguages := TStringList.Create;
  fLanguages.Add('Arabic');
  fHexLanguages.Add('0401');
  fLanguages.Add('Bulgarian');
  fHexLanguages.Add('0402');
  fLanguages.Add('Catalan');
  fHexLanguages.Add('0403');
  fLanguages.Add('Traditional Chinese');
  fHexLanguages.Add('0404');
  fLanguages.Add('Czech');
  fHexLanguages.Add('0405');
  fLanguages.Add('Danish');
  fHexLanguages.Add('0406');
  fLanguages.Add('German');
  fHexLanguages.Add('0407');
  fLanguages.Add('Greek');
  fHexLanguages.Add('0408');
  fLanguages.Add('U.S. English');
  fHexLanguages.Add('0409');
  fLanguages.Add('Castillian Spanish');
  fHexLanguages.Add('040A');
  fLanguages.Add('Finnish');
  fHexLanguages.Add('040B');
  fLanguages.Add('French');
  fHexLanguages.Add('040C');
  fLanguages.Add('Hebrew');
  fHexLanguages.Add('040D');
  fLanguages.Add('Hungarian');
  fHexLanguages.Add('040E');
  fLanguages.Add('Icelandic');
  fHexLanguages.Add('040F');
  fLanguages.Add('Italian');
  fHexLanguages.Add('0410');
  fLanguages.Add('Japanese');
  fHexLanguages.Add('0411');
  fLanguages.Add('Korean');
  fHexLanguages.Add('0412');
  fLanguages.Add('Dutch');
  fHexLanguages.Add('0413');
  fLanguages.Add('Norwegian - Bokmal');
  fHexLanguages.Add('0414');
  fLanguages.Add('Swiss Italian');
  fHexLanguages.Add('0810');
  fLanguages.Add('Belgian Dutch');
  fHexLanguages.Add('0813');
  fLanguages.Add('Norwegian - Nynorsk');
  fHexLanguages.Add('0814');
  fLanguages.Add('Polish');
  fHexLanguages.Add('0415');
  fLanguages.Add('Portugese (Brazil)');
  fHexLanguages.Add('0416');
  fLanguages.Add('Rhaeto-Romantic');
  fHexLanguages.Add('0417');
  fLanguages.Add('Romanian');
  fHexLanguages.Add('0418');
  fLanguages.Add('Russian');
  fHexLanguages.Add('0419');
  fLanguages.Add('Croato-Serbian (Latin)');
  fHexLanguages.Add('041A');
  fLanguages.Add('Slovak');
  fHexLanguages.Add('041B');
  fLanguages.Add('Albanian');
  fHexLanguages.Add('041C');
  fLanguages.Add('Swedish');
  fHexLanguages.Add('041D');
  fLanguages.Add('Thai');
  fHexLanguages.Add('041E');
  fLanguages.Add('Turkish');
  fHexLanguages.Add('041F');
  fLanguages.Add('Urdu');
  fHexLanguages.Add('0420');
  fLanguages.Add('Bahasa');
  fHexLanguages.Add('0421');
  fLanguages.Add('Simplified Chinese');
  fHexLanguages.Add('0804');
  fLanguages.Add('Swiss German');
  fHexLanguages.Add('0807');
  fLanguages.Add('U.K. English');
  fHexLanguages.Add('0809');
  fLanguages.Add('Mexican Spanish');
  fHexLanguages.Add('080A');
  fLanguages.Add('Belgian French');
  fHexLanguages.Add('080C');
  fLanguages.Add('Canadian French');
  fHexLanguages.Add('0C0C');
  fLanguages.Add('Swiss French');
  fHexLanguages.Add('100C');
  fLanguages.Add('Portugese (Portugal)');
  fHexLanguages.Add('0816');
  fLanguages.Add('Sebro-Croatian (Cyrillic)');
  fHexLanguages.Add('081A');
end;

function MSLanguageToHex(const s: string): string;
var
  i: longint;
begin
  i := MSLanguages.IndexOf(s);
  if i >= 0 then
    Result := fHexLanguages[i]
  else
    Result := '';
end;

function MSHexToLanguage(const s: string): string;
var
  i: longint;
begin
  i := MSHexLanguages.IndexOf(s);
  if i >= 0 then
    Result := fLanguages[i]
  else
    Result := '';
end;

function MSCharacterSetToHex(const s: string): string;
var
  i: longint;
begin
  i := MSCharacterSets.IndexOf(s);
  if i >= 0 then
    Result := fHexCharSets[i]
  else
    Result := '';
end;

function MSHexToCharacterSet(const s: string): string;
var
  i: longint;
begin
  i := MSHexCharacterSets.IndexOf(s);
  if i >= 0 then
    Result := fCharSets[i]
  else
    Result := '';
end;

function MSLanguages: TStringList;
begin
  CreateLanguages;
  Result := fLanguages;
end;

function MSHexLanguages: TStringList;
begin
  CreateLanguages;
  Result := fHexLanguages;
end;

function MSCharacterSets: TStringList;
begin
  CreateCharSets;
  Result := fCharSets;
end;

function MSHexCharacterSets: TStringList;
begin
  CreateCharSets;
  Result := fHexCharSets;
end;

{ VersionInfo }

function TProjectVersionInfo.UpdateResources(AResources: TAbstractProjectResources;
  const MainFilename: string): boolean;
var
  ARes: TVersionResource;
  st: TVersionStringTable;
  ti: TVerTranslationInfo;
  lang: string;
  charset: string;
begin
  Result := True;
  if UseVersionInfo then
  begin
    // project indicates to use the versioninfo
    ARes := TVersionResource.Create(nil, nil);
    //it's always RT_VERSION and 1 respectively
    ARes.FixedInfo.FileVersion := FVersion;
    ARes.FixedInfo.ProductVersion := ExtractProductVersion;

    lang := HexLang;
    if lang = '' then
      lang := DefaultLanguage;
    charset := HexCharSet;
    if charset = '' then
      charset := DefaultCharSet;

    st := TVersionStringTable.Create(lang + charset);
    st.Add('Comments', Utf8ToAnsi(CommentsString));
    st.Add('CompanyName', Utf8ToAnsi(CompanyString));
    st.Add('FileDescription', Utf8ToAnsi(DescriptionString));
    st.Add('FileVersion', IntToStr(MajorVersionNr) + '.' + IntToStr(MinorVersionNr) +
      '.' + IntToStr(RevisionNr) + '.' + IntToStr(BuildNr));
    st.Add('InternalName', Utf8ToAnsi(InternalNameString));
    st.Add('LegalCopyright', Utf8ToAnsi(CopyrightString));
    st.Add('LegalTrademarks', Utf8ToAnsi(TrademarksString));
    st.Add('OriginalFilename', Utf8ToAnsi(OriginalFilenameString));
    st.Add('ProductName', Utf8ToAnsi(ProdNameString));
    st.Add('ProductVersion', StringReplace(Utf8ToAnsi(ProductVersionString),
      ',', '.', [rfReplaceAll]));
    ARes.StringFileInfo.Add(st);

    ti.language := StrToInt('$' + lang);
    ti.codepage := StrToInt('$' + charset);
    ARes.VarFileInfo.Add(ti);
    AResources.AddSystemResource(ARes);
  end;
end;

procedure TProjectVersionInfo.WriteToProjectFile(AConfig: TObject; Path: string);
begin
  with TXMLConfig(AConfig) do
  begin
    SetDeleteValue(Path + 'VersionInfo/UseVersionInfo/Value', UseVersionInfo, False);
    SetDeleteValue(Path + 'VersionInfo/AutoIncrementBuild/Value',
      AutoIncrementBuild, False);
    SetDeleteValue(Path + 'VersionInfo/MajorVersionNr/Value', MajorVersionNr, 0);
    SetDeleteValue(Path + 'VersionInfo/MinorVersionNr/Value', MinorVersionNr, 0);
    SetDeleteValue(Path + 'VersionInfo/RevisionNr/Value', RevisionNr, 0);
    SetDeleteValue(Path + 'VersionInfo/BuildNr/Value', BuildNr, 0);
    SetDeleteValue(Path + 'VersionInfo/ProjectVersion/Value', ProductVersionString, '1.0.0.0');
    SetDeleteValue(Path + 'VersionInfo/Language/Value', HexLang, DefaultLanguage);
    SetDeleteValue(Path + 'VersionInfo/CharSet/Value', HexCharSet, DefaultCharset);
    SetDeleteValue(Path + 'VersionInfo/Comments/Value', CommentsString, '');
    SetDeleteValue(Path + 'VersionInfo/CompanyName/Value', CompanyString, '');
    SetDeleteValue(Path + 'VersionInfo/FileDescription/Value', DescriptionString, '');
    SetDeleteValue(Path + 'VersionInfo/InternalName/Value', InternalNameString, '');
    SetDeleteValue(Path + 'VersionInfo/LegalCopyright/Value', CopyrightString, '');
    SetDeleteValue(Path + 'VersionInfo/LegalTrademarks/Value', TrademarksString, '');
    SetDeleteValue(Path + 'VersionInfo/OriginalFilename/Value', OriginalFilenameString, '');
    SetDeleteValue(Path + 'VersionInfo/ProductName/Value', ProdNameString, '');
  end;
end;

procedure TProjectVersionInfo.ReadFromProjectFile(AConfig: TObject; Path: string);
begin
  with TXMLConfig(AConfig) do
  begin
    UseVersionInfo := GetValue(Path + 'VersionInfo/UseVersionInfo/Value', False);
    AutoIncrementBuild := GetValue(Path + 'VersionInfo/AutoIncrementBuild/Value', False);

    MajorVersionNr := GetValue(Path + 'VersionInfo/CurrentVersionNr/Value',
      GetValue(Path + 'VersionInfo/MajorVersionNr/Value', 0));
    MinorVersionNr := GetValue(Path + 'VersionInfo/CurrentMajorRevNr/Value',
      GetValue(Path + 'VersionInfo/MinorVersionNr/Value', 0));
    RevisionNr := GetValue(Path + 'VersionInfo/CurrentMinorRevNr/Value',
      GetValue(Path + 'VersionInfo/RevisionNr/Value', 0));
    BuildNr := GetValue(Path + 'VersionInfo/CurrentBuildNr/Value',
      GetValue(Path + 'VersionInfo/BuildNr/Value', 0));

    ProductVersionString := GetValue(Path + 'VersionInfo/ProjectVersion/Value', '1.0.0.0');
    HexLang := GetValue(Path + 'VersionInfo/Language/Value', DefaultLanguage);
    HexCharSet := GetValue(Path + 'VersionInfo/CharSet/Value', DefaultCharset);
    CommentsString := LineBreaksToSystemLineBreaks(GetValue(Path + 'VersionInfo/Comments/Value', ''));
    CompanyString := LineBreaksToSystemLineBreaks(GetValue(Path + 'VersionInfo/CompanyName/Value', ''));
    DescriptionString := LineBreaksToSystemLineBreaks(GetValue(Path + 'VersionInfo/FileDescription/Value', ''));
    InternalNameString := LineBreaksToSystemLineBreaks(GetValue(Path + 'VersionInfo/InternalName/Value', ''));
    CopyrightString := LineBreaksToSystemLineBreaks(GetValue(Path + 'VersionInfo/LegalCopyright/Value', ''));
    TrademarksString := LineBreaksToSystemLineBreaks(GetValue(Path + 'VersionInfo/LegalTrademarks/Value', ''));
    OriginalFilenameString := GetValue(Path + 'VersionInfo/OriginalFilename/Value', '');
    ProdNameString := LineBreaksToSystemLineBreaks(GetValue(Path + 'VersionInfo/ProductName/Value', ''));
  end;
end;

function TProjectVersionInfo.GetCharSets: TStringList;
begin
  CreateCharSets;
  Result := fHexCharSets;
end;

function TProjectVersionInfo.GetHexCharSets: TStringList;
begin
  CreateCharSets;
  Result := fHexCharSets;
end;

function TProjectVersionInfo.GetHexLanguages: TStringList;
begin
  CreateLanguages;
  Result := fHexLanguages;
end;

function TProjectVersionInfo.GetLanguages: TStringList;
begin
  CreateLanguages;
  Result := fLanguages;
end;

function TProjectVersionInfo.GetVersion(AIndex: integer): integer;
begin
  Result := FVersion[AIndex];
end;

procedure TProjectVersionInfo.SetAutoIncrementBuild(const AValue: boolean);
begin
  if FAutoIncrementBuild = AValue then
    exit;
  FAutoIncrementBuild := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetCommentsString(const AValue: string);
begin
  if FCommentsString = AValue then
    exit;
  FCommentsString := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetCompanyString(const AValue: string);
begin
  if FCompanyString = AValue then
    exit;
  FCompanyString := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetCopyrightString(const AValue: string);
begin
  if FCopyrightString = AValue then
    exit;
  FCopyrightString := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetDescriptionString(const AValue: string);
begin
  if FDescriptionString = AValue then
    exit;
  FDescriptionString := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetHexCharSet(const AValue: string);
begin
  if FHexCharSet = AValue then
    exit;
  FHexCharSet := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetHexLang(const AValue: string);
begin
  if FHexLang = AValue then
    exit;
  FHexLang := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetInternalNameString(const AValue: string);
begin
  if FInternalNameString = AValue then
    exit;
  FInternalNameString := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetOriginalFilenameString(const AValue: string);
begin
  if FOriginalFilenameString = AValue then
    exit;
  FOriginalFilenameString := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetProdNameString(const AValue: string);
begin
  if FProdNameString = AValue then
    exit;
  FProdNameString := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetProductVersionString(const AValue: string);
var
  NewValue: string;
begin
  NewValue := StringReplace(AValue, ',', '.', [rfReplaceAll]);
  if FProductVersionString = NewValue then
    exit;
  FProductVersionString := NewValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetTrademarksString(const AValue: string);
begin
  if FTrademarksString = AValue then
    exit;
  FTrademarksString := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetUseVersionInfo(const AValue: boolean);
begin
  if FUseVersionInfo = AValue then
    exit;
  FUseVersionInfo := AValue;
  Modified := True;
end;

procedure TProjectVersionInfo.SetVersion(AIndex: integer; const AValue: integer);
begin
  if FVersion[AIndex] = AValue then
    Exit;
  FVersion[AIndex] := AValue;
  Modified := True;
end;

function TProjectVersionInfo.ExtractProductVersion: TFileProductVersion;
var
  S, Part: string;
  i, p: integer;
begin
  S := ProductVersionString;
  for i := 0 to 3 do
  begin
    p := Pos('.', S);
    if p >= 1 then
    begin
      Part := Copy(S, 1, p - 1);
      Delete(S, 1, P);
    end
    else
    begin
      Part := S;
      S := '';
    end;
    Result[i] := StrToIntDef(Part, 0);
  end;
end;

procedure TProjectVersionInfo.DoBeforeBuild(AResources: TAbstractProjectResources;
  SaveToTestDir: boolean);
begin
  if AutoIncrementBuild then // project indicate to use autoincrementbuild
    BuildNr := BuildNr + 1;
end;

initialization
  RegisterProjectResource(TProjectVersionInfo);

finalization
  FreeAndNil(fHexCharSets);
  FreeAndNil(fHexLanguages);
  FreeAndNil(fLanguages);
  FreeAndNil(fCharSets);

end.

