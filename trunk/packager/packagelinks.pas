{  $Id$  }
{
 /***************************************************************************
                            packagelinks.pas
                            ----------------


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

  Author: Mattias Gaertner

  Abstract:
    Package links helps the IDE to find package filenames by name
}
unit PackageLinks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, AVL_Tree, Laz_XMLCfg, FileCtrl, IDEProcs, EnvironmentOpts,
  PackageDefs, LazConf;
  
type
  { TPackageLink }

  TPkgLinkOrigin = (
    ploGlobal,
    ploUser
    );
  TPkgLinkOrigins = set of TPkgLinkOrigin;

  TPackageLink = class
  private
    FFilename: string;
    FOrigin: TPkgLinkOrigin;
    FPkgName: string;
    FVersion: TPkgVersion;
    procedure SetFilename(const AValue: string);
    procedure SetOrigin(const AValue: TPkgLinkOrigin);
    procedure SetPkgName(const AValue: string);
    procedure SetVersion(const AValue: TPkgVersion);
  public
    constructor Create;
    destructor Destroy; override;
    function Compare(Link2: TPackageLink): integer;
  public
    property Origin: TPkgLinkOrigin read FOrigin write SetOrigin;
    property PkgName: string read FPkgName write SetPkgName;
    property Version: TPkgVersion read FVersion write SetVersion;
    property Filename: string read FFilename write SetFilename;
  end;


  { TPackageLinks }

  TPackageLinks = class
  private
    FGlobalLinks: TAVLTree; // tree of TPackageLink
    FUserLinks: TAVLTree; // tree of TPackageLink
    function FindLeftMostNode(LinkTree: TAVLTree;
      const PkgName: string): TAVLTreeNode;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure UpdateGlobalLinks;
    procedure UpdateUserLinks;
    procedure UpdateAll;
    function FindPkgFileName(LinkTree: TAVLTree;
      const PkgName: string): TPackageLink;
    function FindPkgFilename(LinkTree: TAVLTree;
      Dependency: TPkgDependency): TPackageLink;
    function FindPkgFileName(const PkgName: string): TPackageLink;
    function FindPkgFilename(Dependency: TPkgDependency): TPackageLink;
  end;
  

implementation


const
  UserPkgLinkFile = 'packagefiles.xml';

function ComparePackageLinks(Data1, Data2: Pointer): integer;
var
  Link1: TPackageLink;
  Link2: TPackageLink;
begin
  Link1:=TPackageLink(Data1);
  Link2:=TPackageLink(Data2);
  Result:=Link1.Compare(Link2);
end;

function ComparePkgNameAndLink(Key, Data: Pointer): integer;
var
  PkgName: String;
  Link: TPackageLink;
begin
  if Key=nil then
    Result:=-1
  else begin
    PkgName:=AnsiString(Key);
    Link:=TPackageLink(Data);
    Result:=AnsiCompareText(PkgName,Link.PkgName);
  end;
end;

{ TPackageLink }

procedure TPackageLink.SetOrigin(const AValue: TPkgLinkOrigin);
begin
  if FOrigin=AValue then exit;
  FOrigin:=AValue;
end;

procedure TPackageLink.SetFilename(const AValue: string);
begin
  if FFilename=AValue then exit;
  FFilename:=AValue;
end;

procedure TPackageLink.SetPkgName(const AValue: string);
begin
  if FPkgName=AValue then exit;
  FPkgName:=AValue;
end;

procedure TPackageLink.SetVersion(const AValue: TPkgVersion);
begin
  if FVersion=AValue then exit;
  FVersion:=AValue;
end;

constructor TPackageLink.Create;
begin
  FVersion:=TPkgVersion.Create;
end;

destructor TPackageLink.Destroy;
begin
  FVersion.Free;
  inherited Destroy;
end;

function TPackageLink.Compare(Link2: TPackageLink): integer;
begin
  Result:=AnsiCompareText(PkgName,Link2.PkgName);
  if Result=0 then
    Result:=Version.Compare(Link2.Version);
end;

{ TPackageLinks }

function TPackageLinks.FindLeftMostNode(LinkTree: TAVLTree;
  const PkgName: string): TAVLTreeNode;
// find left most link with PkgName
var
  PriorNode: TAVLTreeNode;
begin
  Result:=nil;
  if PkgName='' then exit;
  Result:=LinkTree.FindKey(PChar(PkgName),@ComparePkgNameAndLink);
  if Result=nil then exit;
  // find left most
  while Result<>nil do begin
    PriorNode:=LinkTree.FindPrecessor(Result);
    if (PriorNode=nil)
    or (AnsiCompareText(TPackageLink(PriorNode.Data).PkgName,PkgName)<>0)
    then
      break;
    Result:=PriorNode;
  end;
end;

constructor TPackageLinks.Create;
begin
  FGlobalLinks:=TAVLTree.Create(@ComparePackageLinks);
  FUserLinks:=TAVLTree.Create(@ComparePackageLinks);
end;

destructor TPackageLinks.Destroy;
begin
  Clear;
  FGlobalLinks.Free;
  FUserLinks.Free;
  inherited Destroy;
end;

procedure TPackageLinks.Clear;
begin
  FGlobalLinks.FreeAndClear;
  FUserLinks.FreeAndClear;
end;

procedure TPackageLinks.UpdateGlobalLinks;

  function ParseFilename(const Filename: string;
    var PkgName: string; var PkgVersion: TPkgVersion): boolean;
  // checks if filename has the form
  // identifier-int.int.int.int.lpl
  var
    StartPos: Integer;
    i: Integer;
    EndPos: Integer;
    ints: array[1..4] of integer;
  begin
    Result:=false;
    StartPos:=1;
    // parse identifier
    if (StartPos>length(Filename))
    or (not (Filename[StartPos] in ['a'..'z','A'..'Z'])) then exit;
    inc(StartPos);
    while (StartPos<=length(Filename))
    and (Filename[StartPos] in ['a'..'z','A'..'Z']) do
      inc(StartPos);
    PkgName:=lowercase(copy(Filename,1,StartPos-1));
    // parse -
    if (StartPos>length(Filename)) or (Filename[StartPos]<>'-') then exit;
    inc(StartPos);
    // parse 4 times 'int.'
    for i:=Low(ints) to High(ints) do begin
      // parse int
      EndPos:=StartPos;
      while (EndPos<=length(Filename))
      and (Filename[EndPos] in ['0'..'9']) do inc(EndPos);
      ints[i]:=StrToIntDef(copy(Filename,StartPos,EndPos-StartPos),-1);
      if (ints[i]<0) or (ints[i]>99999) then exit;
      StartPos:=EndPos;
      // parse .
      if (StartPos>length(Filename)) or (Filename[StartPos]<>'.') then exit;
      inc(StartPos);
    end;
    // parse lpl
    if (AnsiCompareText(copy(Filename,StartPos,length(Filename)-StartPos+1),
                        'lpl')<>0) then exit;
    PkgVersion.Major:=ints[1];
    PkgVersion.Minor:=ints[2];
    PkgVersion.Build:=ints[3];
    PkgVersion.Release:=ints[4];
    Result:=true;
  end;

var
  GlobalLinksDir: String;
  FileInfo: TSearchRec;
  NewPkgName: string;
  PkgVersion: TPkgVersion;
  NewPkgLink: TPackageLink;
  sl: TStringList;
  CurFilename: String;
  NewFilename: string;
begin
  FGlobalLinks.FreeAndClear;
  GlobalLinksDir:=AppendPathDelim(EnvironmentOptions.LazarusDirectory)
                                  +'packager'+PathDelim+'globallinks'+PathDelim;
  if FindFirst(GlobalLinksDir+'*.lpl', faAnyFile, FileInfo)=0 then begin
    PkgVersion:=TPkgVersion.Create;
    repeat
      CurFilename:=GlobalLinksDir+FileInfo.Name;
      if ((FileInfo.Attr and faDirectory)<>0)
      or (not ParseFilename(FileInfo.Name,NewPkgName,PkgVersion))
      then begin
        writeln('WARNING: suspicious pkg link file found (name): ',CurFilename);
        continue;
      end;
      sl:=TStringList.Create;
      try
        sl.LoadFromFile(CurFilename);
        if sl.Count<0 then begin
          writeln('WARNING: suspicious pkg link file found (content): ',CurFilename);
          continue;
        end;
        NewFilename:=sl[0];
      except
        on E: Exception do begin
          writeln('ERROR: unable to read pkg link file: ',CurFilename,' : ',E.Message);
        end;
      end;
      sl.Free;
      
      NewPkgLink:=TPackageLink.Create;
      NewPkgLink.PkgName:=NewPkgName;
      NewPkgLink.Version.Assign(PkgVersion);
      NewPkgLink.Filename:=NewFilename;
      if IsValidIdent(NewPkgLink.PkgName) and FileExists(NewPkgLink.Filename)
      then
        FGlobalLinks.Add(NewPkgLink)
      else
        NewPkgLink.Free;
      
    until FindNext(FileInfo)<>0;
    if PkgVersion<>nil then PkgVersion.Free;
  end;
  FindClose(FileInfo);
end;

procedure TPackageLinks.UpdateUserLinks;
var
  ConfigFilename: String;
  Path: String;
  XMLConfig: TXMLConfig;
  LinkCount: Integer;
  i: Integer;
  NewPkgLink: TPackageLink;
  ItemPath: String;
begin
  FUserLinks.FreeAndClear;
  ConfigFilename:=AppendPathDelim(GetPrimaryConfigPath)+'packagefiles.xml';
  XMLConfig:=nil;
  try
    XMLConfig:=TXMLConfig.Create(ConfigFilename);
    
    Path:='UserPkgLinks/';
    LinkCount:=XMLConfig.GetValue(Path+'Count',0);
    for i:=0 to LinkCount-1 do begin
      ItemPath:=Path+'Item'+IntToStr(i)+'/';
      NewPkgLink:=TPackageLink.Create;
      NewPkgLink.PkgName:=XMLConfig.GetValue(ItemPath+'PkgName/Value','');
      NewPkgLink.Version.LoadFromXMLConfig(XMLConfig,ItemPath+'Version/',
                                                          LazPkgXMLFileVersion);
      NewPkgLink.Filename:=XMLConfig.GetValue(ItemPath+'Filename/Value','');
      if IsValidIdent(NewPkgLink.PkgName) and FileExists(NewPkgLink.Filename)
      then
        FUserLinks.Add(NewPkgLink)
      else
        NewPkgLink.Free;
    end;
  except
    on E: Exception do begin
      writeln('WARNING: unable to read ',ConfigFilename);
      exit;
    end;
  end;
  if XMLConfig<>nil then XMLConfig.Free;
end;

procedure TPackageLinks.UpdateAll;
begin
  UpdateGlobalLinks;
  UpdateUserLinks;
end;

function TPackageLinks.FindPkgFileName(LinkTree: TAVLTree;
  const PkgName: string): TPackageLink;
// find left most link with PkgName
var
  CurNode: TAVLTreeNode;
begin
  Result:=nil;
  if PkgName='' then exit;
  CurNode:=FindLeftMostNode(LinkTree,PkgName);
  if CurNode=nil then exit;
  Result:=TPackageLink(CurNode.Data);
end;

function TPackageLinks.FindPkgFilename(LinkTree: TAVLTree;
  Dependency: TPkgDependency): TPackageLink;
var
  Link: TPackageLink;
  CurNode: TAVLTreeNode;
begin
  Result:=nil;
  if (Dependency=nil) or (not Dependency.MakeSense) then exit;
  CurNode:=FindLeftMostNode(LinkTree,Dependency.PackageName);
  while CurNode<>nil do begin
    Link:=TPackageLink(CurNode.Data);
    if Dependency.IsCompatible(Link.Version) then begin
      Result:=Link;
      break;
    end;
    CurNode:=LinkTree.FindSuccessor(CurNode);
    if AnsiCompareText(TPackageLink(CurNode.Data).PkgName,Dependency.PackageName)
    <>0
    then begin
      CurNode:=nil;
      break;
    end;
  end;
end;

function TPackageLinks.FindPkgFileName(const PkgName: string): TPackageLink;
begin
  Result:=FindPkgFileName(FUserLinks,PkgName);
  if Result=nil then
    Result:=FindPkgFileName(FGlobalLinks,PkgName);
end;

function TPackageLinks.FindPkgFilename(Dependency: TPkgDependency
  ): TPackageLink;
begin
  Result:=FindPkgFileName(FUserLinks,Dependency);
  if Result=nil then
    Result:=FindPkgFileName(FGlobalLinks,Dependency);
end;

end.

