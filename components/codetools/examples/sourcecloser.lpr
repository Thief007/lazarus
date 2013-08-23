{ Command line utility to create closed source Lazarus packages.

  Copyright (C) 2013 Mattias Gaertner mattias@freepascal.org

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this library. If you modify
  this library, you may extend this exception to your version of the library,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}
program sourcecloser;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, AvgLvlTree, LazLogger, LazFileUtils, Laz2_XMLCfg, LazUTF8,
  FileProcs, BasicCodeTools, CodeToolManager, CodeCache, SourceChanger,
  CodeTree, DefineTemplates, CustApp, contnrs;

type

  { TTarget }

  TTarget = class
  public
    Names, Values: array of string;
    procedure Add(Name, Value: string);
    function AsString: string;
  end;

  { TSourceCloser }

  TSourceCloser = class(TCustomApplication)
  private
    FDefines: TStringToStringTree;
    FIncludePath: string;
    FLPKFilenames: TStrings;
    FRemoveComments: boolean;
    FTargets: TObjectList;
    FUndefines: TStringToStringTree;
    FUnitFilenames: TStrings;
    FVerbosity: integer;
    fDefinesApplied: boolean;
    function GetTargets(Index: integer): TTarget;
  protected
    procedure DoRun; override;
    procedure ApplyDefines;
    procedure ConvertLPK(LPKFilename: string);
    procedure ConvertUnit(UnitFilename: string);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    property Verbosity: integer read FVerbosity write FVerbosity;
    property RemoveComments: boolean read FRemoveComments write FRemoveComments;
    property Defines: TStringToStringTree read FDefines;
    property Undefines: TStringToStringTree read FUndefines;
    property IncludePath: string read FIncludePath write FIncludePath;
    property LPKFilenames: TStrings read FLPKFilenames;
    property UnitFilenames: TStrings read FUnitFilenames;
    property Targets[Index: integer]: TTarget read GetTargets;
    function TargetCount: integer;
  end;

function IndexOfFilename(List: TStrings; Filename: string): integer;
begin
  Result:=List.Count-1;
  while (Result>=0) and (CompareFilenames(List[Result],Filename)<>0) do
    dec(Result);
end;

{ TTarget }

procedure TTarget.Add(Name, Value: string);
var
  Cnt: Integer;
begin
  Cnt:=length(Names);
  SetLength(Names,Cnt+1);
  Names[Cnt]:=Name;
  SetLength(Values,Cnt+1);
  Values[Cnt]:=Value;
end;

function TTarget.AsString: string;
var
  i: Integer;
begin
  Result:='';
  for i:=0 to length(Names)-1 do begin
    if Result<>'' then Result+=',';
    Result+=Names[i]+'='+Values[i];
  end;
end;

{ TSourceCloser }

function TSourceCloser.GetTargets(Index: integer): TTarget;
begin
  Result:=TTarget(FTargets[Index]);
end;

procedure TSourceCloser.DoRun;
const
  ShortOpts = 'hvqrd:u:i:t:';
  LongOpts = 'help verbose quiet removecomments define: undefine: includepath: target:';

  procedure E(Msg: string; WithHelp: boolean = false);
  begin
    DebugLn(['ERROR: ',Msg]);
    if WithHelp then
      WriteHelp;
    Terminate;
    Halt(1);
  end;

  procedure AddTarget(const Param: string);
  var
    p: PChar;
    MacroName: String;
    Target: TTarget;
    StartPos: PChar;
    MacroValue: String;
  begin
    if Param='' then
      E('invalid target:'+Param);
    Target:=TTarget.Create;
    p:=PChar(Param);
    repeat
      MacroName:=GetIdentifier(p);
      if not IsValidIdent(MacroName) then
        E('invalid target:'+Param);
      inc(p,length(MacroName));
      if p^<>'=' then
        E('invalid target:'+Param);
      inc(p);
      StartPos:=p;
      repeat
        case p^ of
        #0,',': break;
        #1..#8,#10..#31:
          E('invalid target:'+Param);
        end;
        inc(p);
      until false;
      MacroValue:=copy(Param,StartPos-PChar(Param),p-StartPos);
      Target.Add(MacroName,MacroValue);
      while p^=',' do inc(p);
    until p^=#0;
    FTargets.Add(Target);
  end;

  procedure ParseValueParam(ShortOpt: char; Value: string);
  begin
    case ShortOpt of
    't':
      AddTarget(Value);
    'i':
      begin
        Value:=UTF8Trim(Value,[]);
        if Value='' then exit;
        if IncludePath<>'' then
          Value:=';'+Value;
        fIncludePath+=Value;
      end;
    'd':
      begin
        if not IsValidIdent(Value) then
          E('invalid define:'+Value);
        Defines[Value]:='';
      end;
    'u':
      begin
        if not IsValidIdent(Value) then
          E('invalid define:'+Value);
        Defines[Value]:='';
      end;
    else
      E('invalid option "'+ShortOpt+'"');
    end;
  end;

var
  ErrorMsg: String;
  i: Integer;
  Param: String;
  S2SItem: PStringToStringItem;
  Filename: String;
  Ext: String;
  Option: string;
  p: SizeInt;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions(ShortOpts,LongOpts);
  if ErrorMsg<>'' then
    E(ErrorMsg);

  // parse parameters
  if HasOption('h','help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  i:=1;
  while i<=System.ParamCount do begin
    Param:=ParamStrUTF8(i);
    inc(i);
    if Param='' then continue;
    if (Param='-q') or (Param='--quiet') then
      dec(fVerbosity)
    else if (Param='-v') or (Param='--verbose') then
      inc(fVerbosity)
    else if (Param='-r') or (Param='--removecomments') then
      RemoveComments:=true
    else if Param[1]<>'-' then begin
      Filename:=TrimAndExpandFilename(Param);
      if not FileExistsUTF8(Filename) then
        E('file not found: '+Param);
      if DirPathExists(Filename) then
        E('file is a directory: '+Param);
      Ext:=lowercase(ExtractFileExt(Filename));
      if Ext='.lpk' then begin
        if IndexOfFilename(LPKFilenames,Filename)>=0 then
          E('duplicate lpk:'+Param); // duplicate lpk, compilation order is unclear => error
        LPKFilenames.Add(Filename);
      end
      else if FilenameIsPascalUnit(Filename) then begin
        if IndexOfFilename(UnitFilenames,Filename)>=0 then
          continue; // duplicate unit is ok => ignore
        UnitFilenames.Add(Filename);
      end else
        E('only lpk and units are supported, invalid file:'+Param);
    end else if (length(Param)=2) and (Pos(Param[2]+':',ShortOpts)>0) then begin
      // e.g. -t <target>
      Option:=Param[2];
      if i>System.ParamCount then
        E('missing value for option: '+Param);
      Param:=ParamStrUTF8(i);
      inc(i);
      ParseValueParam(Option[1],Param);
    end else if (copy(Param,1,2)='--') then begin
      p:=Pos('=',Param);
      if p<1 then
        E('invalid option: '+Param);
      Option:=copy(Param,3,p-3);
      delete(Param,1,p);
      if Option='target' then Option:='t'
      else if Option='define' then Option:='d'
      else if Option='undefine' then Option:='u'
      else if Option='includepath' then Option:='i'
      else
        E('invalid option');
      ParseValueParam(Option[1],Param);
    end else
      E('invalid option: '+Param);
  end;

  if Verbosity>0 then begin
    debugln(['Options:']);
    debugln(['Verbosity=',Verbosity]);
    debugln(['RemoveComments=',RemoveComments]);
    debugln(['IncludePath=',IncludePath]);
    for S2SItem in Defines do
      debugln('Define:',S2SItem^.Name);
    for S2SItem in Undefines do
      debugln('Undefine:',S2SItem^.Name);
    for i:=0 to TargetCount-1 do
      debugln(['Target[',i+1,']:',Targets[i].AsString]);
    for i:=0 to LPKFilenames.Count-1 do
      debugln(['LPK[',i+1,']:',LPKFilenames[i]]);
    for i:=0 to UnitFilenames.Count-1 do
      debugln(['Unit[',i+1,']:',UnitFilenames[i]]);
  end;
  if (LPKFilenames.Count=0) and (UnitFilenames.Count=0) then
    E('you must pass at least one lpk or pas file',true);

  ApplyDefines;

  for i:=0 to LPKFilenames.Count-1 do
    ConvertLPK(LPKFilenames[i]);
  for i:=0 to UnitFilenames.Count-1 do
    ConvertUnit(UnitFilenames[i]);

  // stop program loop
  Terminate;
end;

procedure TSourceCloser.ApplyDefines;
var
  IncPathTemplate: TDefineTemplate;
  S2SItem: PStringToStringItem;
  MacroName: String;
  DefTemplate: TDefineTemplate;
begin
  if fDefinesApplied then exit;
  fDefinesApplied:=true;

  CodeToolBoss.SimpleInit('codetools.cache');

  if IncludePath<>'' then begin
    IncPathTemplate:=TDefineTemplate.Create('IncPath',
      'extending include search path',
      IncludePathMacroName,  // variable name: #IncPath
      '$('+IncludePathMacroName+');'+IncludePath
      ,da_DefineRecurse
      );
    CodeToolBoss.DefineTree.Add(IncPathTemplate);
  end;
  for S2SItem in Defines do begin
    MacroName:=S2SItem^.Name;
    DefTemplate:=TDefineTemplate.Create('Define '+MacroName,
      'Define '+MacroName,
      MacroName,S2SItem^.Value,da_DefineRecurse);
    CodeToolBoss.DefineTree.Add(DefTemplate);
  end;
  for S2SItem in Undefines do begin
    MacroName:=S2SItem^.Name;
    DefTemplate:=TDefineTemplate.Create('Undefine '+MacroName,
      'Undefine '+MacroName,
      MacroName,'',da_UndefineRecurse);
    CodeToolBoss.DefineTree.Add(DefTemplate);
  end;
end;

procedure TSourceCloser.ConvertLPK(LPKFilename: string);
// set lpk to compile only manually
// add -Ur to compiler options
const
  CustomOptionsPath='Package/CompilerOptions/Other/CustomOptions/Value';
var
  xml: TXMLConfig;
  CustomOptions: String;
begin
  debugln(['Converting lpk: ',LPKFilename]);
  xml:=TXMLConfig.Create(LPKFilename);
  try
    // set lpk to compile only manually
    xml.SetValue('Package/AutoUpdate/Value','Manually');

    // add -Ur to compiler options
    CustomOptions:=xml.GetValue(CustomOptionsPath,'');
    if Pos('-Ur',CustomOptions)<1 then begin
      if CustomOptions<>'' then CustomOptions+=' ';
      CustomOptions+='-Ur';
      xml.SetValue(CustomOptionsPath,CustomOptions);
    end;

    // write
    xml.Flush;
  finally
    xml.Free;
  end;
end;

procedure TSourceCloser.ConvertUnit(UnitFilename: string);

  procedure E(Msg: string);
  begin
    writeln('ERROR: '+Msg);
    Halt(1);
  end;

var
  Code: TCodeBuffer;
  Changer: TSourceChangeCache;
  Tool: TCodeTool;
  Node: TCodeTreeNode;
  StartPos: Integer;
  EndPos: Integer;
  CodeList: TFPList;
  i: Integer;
begin
  debugln(['Converting unit: ',UnitFilename]);
  ApplyDefines;

  Code:=CodeToolBoss.LoadFile(UnitFilename,true,false);
  if Code=nil then
    E('unable to read "'+UnitFilename+'"');
  if (not CodeToolBoss.Explore(Code,Tool,false)) or (CodeToolBoss.ErrorMessage<>'') then
    E('parse error');
  if Tool.GetSourceType<>ctnUnit then
    E('not a unit, skipping "'+Code.Filename+'"');
  Changer:=CodeToolBoss.SourceChangeCache;
  Changer.MainScanner:=Tool.Scanner;

  // delete implementation, initialization and finalization section
  Node:=Tool.Tree.Root;
  while (Node<>nil)
  and (not (Node.Desc in [ctnImplementation,ctnInitialization,ctnFinalization]))
  do
    Node:=Node.NextBrother;
  if Node=nil then
    exit;
  StartPos:=Node.StartPos;
  while (Node<>nil) do begin
    EndPos:=Node.StartPos;
    Node:=Node.NextBrother;
  end;
  if not Changer.Replace(gtNone,gtNone,StartPos,EndPos,'') then
    E('unable to delete implementation of "'+UnitFilename+'"');

  // apply changes and write changes to disk
  CodeList:=TFPList.Create;
  try
    for i:=0 to Changer.BuffersToModifyCount-1 do
      CodeList.Add(Changer.BuffersToModify[i]);
    if not Changer.Apply then
      E('unable to modify "'+UnitFilename+'"');
    for i:=0 to CodeList.Count-1 do begin
      Code:=TCodeBuffer(CodeList[i]);
      if not Code.Save then
        E('unable to write "'+Code.Filename+'"');
    end;
  finally
    CodeList.Free;
  end;
end;

constructor TSourceCloser.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
  fDefines:=TStringToStringTree.Create(false);
  FUndefines:=TStringToStringTree.Create(false);
  FLPKFilenames:=TStringList.Create;
  FUnitFilenames:=TStringList.Create;
  FTargets:=TObjectList.Create(true);
end;

destructor TSourceCloser.Destroy;
begin
  FreeAndNil(FTargets);
  FreeAndNil(FLPKFilenames);
  FreeAndNil(FUnitFilenames);
  FreeAndNil(FDefines);
  FreeAndNil(FUndefines);
  inherited Destroy;
end;

procedure TSourceCloser.WriteHelp;
begin
  writeln('Usage:');
  writeln('  ',ExeName,' -h');
  writeln('  ',ExeName,' [options] [unit1.pas unit2.pp ...] [pkg1.lpk pk2.lpk ..]');
  writeln;
  writeln('Description:');
  writeln('  If you pass a lpk file, this tool will set "compile manually"');
  writeln('  and appends "-Ur" to the compiler options.');
  writeln('  You can pass multiple lpk files and they will be edited in this order.');
  writeln('  If you pass a .pas or .pp file it will be treated as a pascal unit and');
  writeln('  will remove the implementation, initialization, finalization sections.');
  //writeln('  If you pass the removecomments option the comments in the units will');
  //writeln('  removed as well.');
  //writeln('  If you pass the target option, lazbuild is called once for each lpk');
  //writeln('  and each target.');
  writeln;
  writeln('Options:');
  writeln('  -h, --help    : This help messages.');
  writeln('  -v, --verbose : be more verbose.');
  writeln('  -q, --quiet   : be more quiet.');
  writeln('  -r, --removecomments : remove comments from units');
  writeln('  -d <MacroName>, --define=<MacroName> :');
  writeln('          Define Free Pascal macro. Can be passed multiple times.');
  writeln('  -u <MacroName>, --undefine=<MacroName> :');
  writeln('          Undefine Free Pascal macro. Can be passed multiple times.');
  writeln('  -i <path>, --includepath=<path> :');
  writeln('         Append <path> to include search path. Can be passed multiple times.');
  //writeln('  -t <target>, --target=<target> :');
  //writeln('         Call lazbuild once for each target and each package.');
  //writeln('         <target> is a comma separated list of name=value pairs.');
  //writeln('         For example: --target=targetos=linux,targetcpu=i386,lclwidgettype=gtk2');
  writeln;
  writeln('Environment variables:');
  writeln('  ');
end;

function TSourceCloser.TargetCount: integer;
begin
  Result:=FTargets.Count;
end;

var
  Application: TSourceCloser;
begin
  Application:=TSourceCloser.Create(nil);
  Application.Title:='SourceCloser';
  Application.Run;
  Application.Free;
end.

