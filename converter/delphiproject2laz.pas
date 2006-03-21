{  $Id: delphiunit2laz.pas 8788 2006-02-20 23:48:13Z mattias $  }
{
 /***************************************************************************
                          delphiunit2laz.pas
                          ------------------

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
    Functions to convert delphi projects/packages to lazarus projects/packages.

    The process of converting a delphi project/package/unit to lazarus contains
    some monotone and boring work. These functions try to help here.
    Because any conversion step can fail and can need manual fix before
    continuing, the functions are written to recognize, what have been done.
    So, you can call the delphi conversion, abort at any step, fix a few things,
    and invoke it again.
}
unit DelphiProject2Laz;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, Forms, Controls, Dialogs, FileProcs, FileUtil,
  ExprEval, DefineTemplates, CodeCache, CodeToolManager, CodeToolsStructs,
  LinkScanner,
  SrcEditorIntf, MsgIntf, MainIntf, LazIDEIntf, PackageIntf, ProjectIntf,
  IDEProcs, DelphiUnit2Laz, Project, DialogProcs, CheckLFMDlg,
  EditorOptions, ProjectInspector, CompilerOptions, PackageDefs,
  BasePkgManager, PkgManager;
  
const
  SettingDelphiModeTemplName = 'Setting Delphi Mode';
  
type
  TConvertDelphiToLazarusUnitFlag = (
    cdtlufRenameLowercase, // rename the unit lowercase
    cdtlufIsSubProc, // this is part of a big conversion -> add Abort button to all questions
    cdtlufCheckLFM,  // check and fix LFM
    cdtlufDoNotSetDelphiMode // do not set delphi mode for project directories
    );
  TConvertDelphiToLazarusUnitFlags = set of TConvertDelphiToLazarusUnitFlag;

// project
function ConvertDelphiToLazarusProject(const ProjectFilename: string
                                       ): TModalResult;
function FindAllDelphiProjectUnits(AProject: TProject): TModalResult;
function ConvertAllDelphiProjectUnits(AProject: TProject;
                         Flags: TConvertDelphiToLazarusUnitFlags): TModalResult;

// package
function ConvertDelphiToLazarusPackage(const PackageFilename: string
                                       ): TModalResult;

// unit
function ConvertDelphiToLazarusUnit(const DelphiFilename: string;
  Flags: TConvertDelphiToLazarusUnitFlags): TModalResult;

// project parts
function CreateDelphiToLazarusProjectInstance(const LPIFilename: string;
                                          out AProject: TProject): TModalResult;
function CreateDelphiToLazarusMainSourceFile(AProject: TProject;
                                  const DPRFilename, MainSourceFilename: string;
                                  out LPRCode: TCodeBuffer): TModalResult;
function FindDPRFilename(const StartFilename: string): string;
function ReadDelphiProjectConfigFiles(AProject: TProject): TModalResult;
procedure CleanUpProjectSearchPaths(AProject: TProject);
procedure SetCompilerModeForProjectSrcDirs(AProject: TProject);
procedure UnsetCompilerModeForProjectSrcDirs(AProject: TProject);

// package parts
function CreateDelphiToLazarusPackageInstance(const LPKFilename: string;
                                       out APackage: TLazPackage): TModalResult;


implementation

function ConvertDelphiToLazarusProject(const ProjectFilename: string
  ): TModalResult;
{ Creates or updates a lazarus project (.lpi+.lpr)
  This function can be invoked on a delphi project .dpr file, or a lazarus
  project (.lpi/.lpr) file.
  It will use, whatever it finds and will make it more lazarus-like.
  It can be aborted and called again.
}
var
  LPRCode: TCodeBuffer;
  LPIFilename: String;
  DPRFilename: String;
  MainSourceFilename: String;
  ConvertUnitFlags: TConvertDelphiToLazarusUnitFlags;
  AProject: TProject;
begin
  debugln('ConvertDelphiToLazarusProject ProjectFilename="',ProjectFilename,'"');
  IDEMessagesWindow.Clear;

  // create/open lazarus project file
  LPIFilename:=ChangeFileExt(ProjectFilename,'.lpi');
  Result:=CreateDelphiToLazarusProjectInstance(LPIFilename,AProject);
  if Result<>mrOk then begin
    DebugLn('ConvertDelphiToLazarusProject failed to create/open project LPIFilename="',LPIFilename,'"');
    exit;
  end;
  
  // create main source file (.lpr) (only copy, no conversion)
  DPRFilename:=FindDPRFilename(ProjectFilename);
  DebugLn('ConvertDelphiToLazarusProject DPRFilename="',DPRFilename,'"');
  MainSourceFilename:=ChangeFileExt(LPIFilename,'.lpr');
  Result:=CreateDelphiToLazarusMainSourceFile(AProject,DPRFilename,
                                              MainSourceFilename,LPRCode);
  if Result<>mrOk then exit;

  // read config files (they often contain clues about paths, switches and defines)
  Result:=ReadDelphiProjectConfigFiles(AProject);
  if Result<>mrOk then begin
    DebugLn('ConvertDelphiToLazarusProject failed reading Delphi configs');
    exit;
  end;

  // clean up project
  AProject.RemoveNonExistingFiles(false);
  CleanUpProjectSearchPaths(AProject);

  // load required packages
  AProject.AddPackageDependency('LCL');// Nearly all Delphi projects require it
  PkgBoss.AddDefaultDependencies(AProject);

  // we have now enough information to parse the .dpr file,
  // but not enough to parse the units
  
  // set Delphi mode for all project source directories
  SetCompilerModeForProjectSrcDirs(AProject);
  try

    // init codetools
    if not LazarusIDE.BeginCodeTools then begin
      DebugLn('ConvertDelphiToLazarusProject failed BeginCodeTools');
      Result:=mrCancel;
      exit;
    end;

    // fix .lpr
    ConvertUnitFlags:=[cdtlufIsSubProc,cdtlufDoNotSetDelphiMode];
    Result:=ConvertDelphiToLazarusUnit(LPRCode.Filename,ConvertUnitFlags);
    if Result=mrAbort then begin
      DebugLn('ConvertDelphiToLazarusProject failed converting unit ',LPRCode.Filename);
      exit;
    end;

    // get all options from .lpr (the former .dpr)
    Result:=ExtractOptionsFromDPR(LPRCode,AProject);
    if Result<>mrOk then exit;

    // find and convert all project files
    Result:=FindAllDelphiProjectUnits(AProject);
    if Result<>mrOk then exit;

    // convert all project files
    Result:=ConvertAllDelphiProjectUnits(AProject,[cdtlufIsSubProc,cdtlufCheckLFM]);
    if Result<>mrOk then exit;
  finally
    UnsetCompilerModeForProjectSrcDirs(AProject);
  end;

  debugln('ConvertDelphiToLazarusProject Done');
  Result:=mrOk;
end;

function FindAllDelphiProjectUnits(AProject: TProject): TModalResult;
var
  FoundInUnits, MissingInUnits, NormalUnits: TStrings;
  LPRCode: TCodeBuffer;
  NotFoundUnits: String;
  i: Integer;
  CurUnitInfo: TUnitInfo;
  NewSearchPath: String;
  CurFilename: string;
  p: LongInt;
  OffendingUnit: TUnitInfo;
begin
  LPRCode:=AProject.MainUnitInfo.Source;

  FoundInUnits:=nil;
  MissingInUnits:=nil;
  NormalUnits:=nil;
  try
    debugln('ConvertDelphiToLazarusProject gathering all project units ...');
    if not CodeToolBoss.FindDelphiProjectUnits(LPRCode,FoundInUnits,
                                               MissingInUnits, NormalUnits) then
    begin
      LazarusIDE.DoJumpToCodeToolBossError;
      Result:=mrCancel;
      exit;
    end;
    debugln('ConvertDelphiToLazarusProject FoundInUnits=[',FoundInUnits.Text,']',
      ' MissingInUnits=[',MissingInUnits.Text,']',
      ' NormalUnits=[',NormalUnits.Text,']');
    // warn about missing units
    if (MissingInUnits<>nil) and (MissingInUnits.Count>0) then begin
      NotFoundUnits:=MissingInUnits.Text;
      Result:=QuestionDlg('Units not found',
        'Some units of the delphi project are missing:'#13
        +NotFoundUnits,mtWarning,[mrIgnore,mrAbort],0);
      if Result<>mrIgnore then exit;
    end;

    try
      // add all units to the project
      debugln('ConvertDelphiToLazarusProject adding all project units to project ...');

      for i:=0 to FoundInUnits.Count-1 do begin
        CurFilename:=FoundInUnits[i];
        p:=System.Pos(' in ',CurFilename);
        if p>0 then
          CurFilename:=copy(CurFilename,p+4,length(CurFilename));
        if CurFilename='' then continue;
        if not FilenameIsAbsolute(CurFilename) then
          CurFilename:=AppendPathDelim(AProject.ProjectDirectory)+CurFilename;
        CurFilename:=TrimFilename(CurFilename);
        if not FileExists(CurFilename) then begin
          DebugLn('ConvertDelphiToLazarusProject file not found: "',CurFilename,'"');
          continue;
        end;
        CurUnitInfo:=AProject.UnitInfoWithFilename(CurFilename);
        if CurUnitInfo<>nil then begin
          CurUnitInfo.IsPartOfProject:=true;
        end else begin
          if FilenameIsPascalUnit(CurFilename) then begin
            // check unitname
            OffendingUnit:=AProject.UnitWithUnitname(
                                                ExtractFileNameOnly(CurFilename));
            if OffendingUnit<>nil then begin
              Result:=QuestionDlg('Unitname exists twice',
                'There are two units with the same unitname:'#13
                +OffendingUnit.Filename+#13
                +CurFilename+#13,
                mtWarning,[mrYes,'Remove first',mrNo,'Remove second',
                           mrIgnore,'Keep both',mrAbort],0);
              case Result of
              mrYes: OffendingUnit.IsPartOfProject:=false;
              mrNo:  continue;
              mrIgnore: ;
              else
                Result:=mrAbort;
                exit;
              end;
            end;
          end;

          // add new unit to project
          CurUnitInfo:=TUnitInfo.Create(nil);
          CurUnitInfo.Filename:=CurFilename;
          CurUnitInfo.IsPartOfProject:=true;
          AProject.AddFile(CurUnitInfo,false);
        end;
      end;

    finally
      // set unit paths to find all project units
      NewSearchPath:=MergeSearchPaths(AProject.CompilerOptions.OtherUnitFiles,
                       AProject.SourceDirectories.CreateSearchPathFromAllFiles);
      NewSearchPath:=RemoveSearchPaths(NewSearchPath,
                                     '.;'+VirtualDirectory+';'+VirtualTempDir
                                     +';'+AProject.ProjectDirectory);
      AProject.CompilerOptions.OtherUnitFiles:=MinimizeSearchPath(
               RemoveNonExistingPaths(NewSearchPath,AProject.ProjectDirectory));
      // set include path
      NewSearchPath:=MergeSearchPaths(AProject.CompilerOptions.IncludeFiles,
                       AProject.SourceDirectories.CreateSearchPathFromAllFiles);
      NewSearchPath:=RemoveSearchPaths(NewSearchPath,
                                     '.;'+VirtualDirectory+';'+VirtualTempDir
                                     +';'+AProject.ProjectDirectory);
      AProject.CompilerOptions.IncludeFiles:=MinimizeSearchPath(
               RemoveNonExistingPaths(NewSearchPath,AProject.ProjectDirectory));
      // clear caches
      AProject.DefineTemplates.SourceDirectoriesChanged;
      CodeToolBoss.DefineTree.ClearCache;
      DebugLn('ConvertDelphiToLazarusProject UnitPath="',AProject.CompilerOptions.OtherUnitFiles,'"');
    end;

    // save project
    debugln('ConvertDelphiToLazarusProject Saving project ...');
    Result:=LazarusIDE.DoSaveProject([]);
    if Result<>mrOk then begin
      DebugLn('ConvertDelphiToLazarusProject failed saving project');
      exit;
    end;

  finally
    FoundInUnits.Free;
    MissingInUnits.Free;
    NormalUnits.Free;
  end;

  Result:=mrOk;
end;

function ConvertAllDelphiProjectUnits(AProject: TProject;
  Flags: TConvertDelphiToLazarusUnitFlags): TModalResult;
  
  function Convert(CurFlags: TConvertDelphiToLazarusUnitFlags): TModalResult;
  var
    i: Integer;
    CurUnitInfo: TUnitInfo;
  begin
    // convert all units
    i:=0;
    while i<AProject.UnitCount do begin
      CurUnitInfo:=AProject.Units[i];
      if CurUnitInfo.IsPartOfProject then begin
        Result:=ConvertDelphiToLazarusUnit(CurUnitInfo.Filename,
                                           CurFlags+[cdtlufIsSubProc]);
        if Result=mrAbort then exit;
        if Result=mrCancel then begin
          Result:=QuestionDlg('Failed converting unit',
            'Failed to convert unit'+#13
            +CurUnitInfo.Filename+#13,
            mtWarning,[mrIgnore,'Ignore and continue',mrAbort],0);
          if Result=mrAbort then exit;
        end;
        if LazarusIDE.DoCloseEditorFile(CurUnitInfo.Filename,
          [cfSaveFirst,cfQuiet]) = mrAbort
        then
          exit;
      end;
      inc(i);
    end;
    Result:=mrOk;
  end;
  
begin
  // first convert all units
  Result:=Convert(Flags-[cdtlufCheckLFM]);
  if Result<>mrOk then exit;
  // now the units can be parsed
  if cdtlufCheckLFM in Flags then begin
    // fix the .lfm files
    Result:=Convert(Flags);
    if Result<>mrOk then exit;
  end;
end;

function ConvertDelphiToLazarusPackage(const PackageFilename: string
  ): TModalResult;
var
  APackage: TLazPackage;
  LPKFilename: String;
begin
  debugln('ConvertDelphiToLazarusPackage PackageFilename="',PackageFilename,'"');
  IDEMessagesWindow.Clear;

  // create/open lazarus project file
  LPKFilename:=ChangeFileExt(PackageFilename,'.lpk');
  Result:=CreateDelphiToLazarusPackageInstance(LPKFilename,APackage);
  if Result<>mrOk then begin
    DebugLn('ConvertDelphiToLazarusPackage failed to create/open package LPKFilename="',LPKFilename,'"');
    exit;
  end;

  Result:=mrOk;
end;

function ConvertDelphiToLazarusUnit(const DelphiFilename: string;
  Flags: TConvertDelphiToLazarusUnitFlags): TModalResult;
var
  DFMFilename: String;
  LazarusUnitFilename: String;
  LRSFilename: String;
  UnitCode, LFMCode: TCodeBuffer;
  HasDFMFile: boolean;
  LFMFilename: String;
begin
  // check file and directory
  DebugLn('ConvertDelphiToLazarusUnit A ',DelphiFilename,' FixLFM=',dbgs(cdtlufCheckLFM in Flags));
  Result:=CheckFileIsWritable(DelphiFilename,[mbAbort]);
  if Result<>mrOk then exit;

  // close Delphi files in editor
  DebugLn('ConvertDelphiToLazarusUnit Close files in editor .pas/.dfm');
  Result:=LazarusIDE.DoCloseEditorFile(DelphiFilename,[cfSaveFirst]);
  if Result<>mrOk then exit;
  DFMFilename:=FindDFMFileForDelphiUnit(DelphiFilename);
  DebugLn('ConvertDelphiToLazarusUnit DFM file="',DFMFilename,'"');
  HasDFMFile:=DFMFilename<>'';
  if HasDFMFile then begin
    Result:=LazarusIDE.DoCloseEditorFile(DFMFilename,[cfSaveFirst]);
    if Result<>mrOk then exit;
  end;

  // rename files (.pas,.dfm) lowercase
  // TODO: rename files in project
  DebugLn('ConvertDelphiToLazarusUnit Rename files');
  LazarusUnitFilename:='';
  LFMFilename:='';
  Result:=RenameDelphiUnitToLazarusUnit(DelphiFilename,true,
                                        cdtlufRenameLowercase in Flags,
                                        LazarusUnitFilename,LFMFilename);
  if Result<>mrOk then exit;
  if LFMFilename='' then LFMFilename:=ChangeFileExt(LazarusUnitFilename,'.lfm');
  HasDFMFile:=FileExists(LFMFilename);
  
  // convert .dfm file to .lfm file (without context type checking)
  if HasDFMFile then begin
    DebugLn('ConvertDelphiToLazarusUnit Rename dfm to lfm "',LFMFilename,'"');
    Result:=ConvertDFMFileToLFMFile(LFMFilename);
    if Result<>mrOk then exit;
  end;
  // create empty .lrs file
  DebugLn('ConvertDelphiToLazarusUnit Create empty lrs');
  if HasDFMFile then begin
    LRSFilename:=ChangeFileExt(LazarusUnitFilename,'.lrs');
    DebugLn('ConvertDelphiToLazarusUnit Create ',LRSFilename);
    Result:=CreateEmptyFile(LRSFilename,[mbAbort,mbRetry]);
    if Result<>mrOk then exit;
  end else
    LRSFilename:='';

  DebugLn('ConvertDelphiToLazarusUnit Convert delphi source');
  if not LazarusIDE.BeginCodeTools then begin
    Result:=mrCancel;
    exit;
  end;

  // check LCL path
  Result:=CheckFilenameForLCLPaths(LazarusUnitFilename);
  if Result<>mrOk then exit;

  // fix or comment missing units
  DebugLn('ConvertDelphiToLazarusUnit FixMissingUnits');
  Result:=FixMissingUnits(LazarusUnitFilename,cdtlufIsSubProc in Flags);
  if Result=mrAbort then exit;
  if (Result<>mrOk) then begin
    Result:=JumpToCodetoolErrorAndAskToAbort(cdtlufIsSubProc in Flags);
    exit;
  end;

  // add {$mode delphi} directive
  // remove windows unit and add LResources, LCLIntf
  // remove {$R *.dfm} or {$R *.xfm} directive
  // add initialization
  // add {$i unit.lrs} directive
  // TODO: fix delphi ambiguousities like incomplete proc implementation headers
  Result:=ConvertDelphiSourceToLazarusSource(LazarusUnitFilename,
                                             LRSFilename<>'');
  if not IfNotOkJumpToCodetoolErrorAndAskToAbort(Result=mrOk,
                                                cdtlufIsSubProc in Flags,Result)
  then exit;

  if cdtlufCheckLFM in Flags then begin
    // check the LFM file and the pascal unit
    DebugLn('ConvertDelphiToLazarusUnit Check new .lfm and .pas file');
    Result:=LoadUnitAndLFMFile(LazarusUnitFilename,UnitCode,LFMCode,HasDFMFile);
    if Result<>mrOk then exit;
    if HasDFMFile and (LFMCode=nil) then
      DebugLn('WARNING: ConvertDelphiToLazarusUnit unable to load LFMCode');
    if (LFMCode<>nil)
    and (CheckLFMBuffer(UnitCode,LFMCode,@IDEMessagesWindow.AddMsg,true,true)<>mrOk)
    then begin
      LazarusIDE.DoJumpToCompilerMessage(-1,true);
      exit(mrAbort);
    end;

    if LFMCode<>nil then begin
      // save LFM file
      DebugLn('ConvertDelphiToLazarusUnit Save LFM');
      Result:=MainIDEInterface.DoSaveCodeBufferToFile(LFMCode,LFMCode.Filename,false);
      if Result<>mrOk then exit;

      // convert lfm to lrs
      DebugLn('ConvertDelphiToLazarusUnit Convert lfm to lrs');
      Result:=ConvertLFMtoLRSfile(LFMCode.Filename);
      if Result<>mrOk then exit;
    end;
  end;

  Result:=mrOk;
end;

function CreateDelphiToLazarusProjectInstance(const LPIFilename: string;
  out AProject: TProject): TModalResult;
// If .lpi does not exist, create it
// open new project
begin
  DebugLn('CreateDelphiToLazarusProjectInstance LPIFilename="',LPIFilename,'"');
  AProject:=Project1;
  if FileExists(LPIFilename) then begin
    // there is already a lazarus project -> open it, if not already open
    if CompareFilenames(AProject.ProjectInfoFile,LPIFilename)<>0 then begin
      DebugLn('CreateDelphiToLazarusProject open "',LPIFilename,'"');
      Result:=LazarusIDE.DoOpenProjectFile(LPIFilename,[]);
      AProject:=Project1;
      if Result<>mrOk then exit;
    end;
  end else begin
    // create a new lazarus project
    Result:=LazarusIDE.DoNewProject(ProjectDescriptorEmptyProject);
    AProject:=Project1;
    if Result<>mrOk then begin
      DebugLn('CreateDelphiToLazarusProjectInstance failed to create a new project');
      exit;
    end;
    AProject.ProjectInfoFile:=LPIFilename;
  end;
  // save to disk (this makes sure, all editor changes are saved too)
  DebugLn('CreateDelphiToLazarusProjectInstance saving project ...');
  Result:=LazarusIDE.DoSaveProject([]);
end;

function CreateDelphiToLazarusMainSourceFile(AProject: TProject;
  const DPRFilename, MainSourceFilename: string;
  out LPRCode: TCodeBuffer): TModalResult;
// if .lpr does not exists, copy the .dpr file to the .lpr
// adds the .lpr as main unit to the project, if not already done
var
  MainUnitInfo: TUnitInfo;
begin
  LPRCode:=nil;
  Result:=CreateLPRFileForDPRFile(DPRFilename,MainSourceFilename,LPRCode);
  if Result<>mrOk then begin
    DebugLn('CreateDelphiToLazarusMainSourceFile CreateLPRFileForDPRFile failed DPRFilename="',DPRFilename,'" MainSourceFilename="',MainSourceFilename,'"');
    exit;
  end;
  if AProject.MainUnitInfo=nil then begin
    // add .lpr file to project as main unit
    DebugLn('CreateDelphiToLazarusMainSourceFile adding .lpr file to project as main unit ',LPRCode.Filename);
    MainUnitInfo:=TUnitInfo.Create(LPRCode);
    MainUnitInfo.SyntaxHighlighter:=
              ExtensionToLazSyntaxHighlighter(ExtractFileExt(LPRCode.Filename));
    MainUnitInfo.IsPartOfProject:=true;
    AProject.AddFile(MainUnitInfo,false);
    AProject.MainFileID:=0;
  end else begin
    // replace main unit in project
    AProject.MainUnitInfo.Source:=LPRCode;
  end;
end;

function FindDPRFilename(const StartFilename: string): string;
// searches the corresponding .dpr file
begin
  if CompareFileExt(StartFilename,'.dpr',false)=0 then
    Result:=StartFilename
  else
    Result:=ChangeFileExt(StartFilename,'.dpr');
  if not FileExists(Result) then
    Result:=FindDiskFileCaseInsensitive(StartFilename);
end;

function ReadDelphiProjectConfigFiles(AProject: TProject): TModalResult;
var
  MainSourceFilename: String;
  DOFFilename: String;
  CFGFilename: String;
begin
  if AProject.MainUnitInfo=nil then exit(mrOk);
  MainSourceFilename:=AProject.MainUnitInfo.Filename;

  // read .dof file
  DOFFilename:=FindDelphiDOF(MainSourceFilename);
  if FileExists(DOFFilename) then begin
    Result:=ExtractOptionsFromDOF(DOFFilename,Project1);
    if Result<>mrOk then exit;
  end;

  // read .cfg file
  CFGFilename:=FindDelphiCFG(MainSourceFilename);
  if FileExists(CFGFilename) then begin
    Result:=ExtractOptionsFromCFG(CFGFilename,Project1);
    if Result<>mrOk then exit;
  end;
end;

procedure CleanUpProjectSearchPaths(AProject: TProject);

  function CleanProjectSearchPath(const SearchPath: string): string;
  begin
    Result:=RemoveNonExistingPaths(SearchPath,Project1.ProjectDirectory);
    Result:=MinimizeSearchPath(Result);
  end;

begin
  AProject.CompilerOptions.OtherUnitFiles:=
              CleanProjectSearchPath(AProject.CompilerOptions.OtherUnitFiles);
  AProject.CompilerOptions.IncludeFiles:=
              CleanProjectSearchPath(AProject.CompilerOptions.IncludeFiles);
  AProject.CompilerOptions.Libraries:=
              CleanProjectSearchPath(AProject.CompilerOptions.Libraries);
  AProject.CompilerOptions.ObjectPath:=
              CleanProjectSearchPath(AProject.CompilerOptions.ObjectPath);
  AProject.CompilerOptions.SrcPath:=
              CleanProjectSearchPath(AProject.CompilerOptions.SrcPath);
end;

procedure SetCompilerModeForProjectSrcDirs(AProject: TProject);
begin
  if AProject.DefineTemplates.CustomDefines.FindChildByName(
    SettingDelphiModeTemplName)<>nil
  then exit;
  AProject.DefineTemplates.CustomDefines.ReplaceChild(
                  CreateDefinesForFPCMode(SettingDelphiModeTemplName,cmDELPHI));
  CodeToolBoss.DefineTree.ClearCache;
end;

procedure UnsetCompilerModeForProjectSrcDirs(AProject: TProject);
begin
  if AProject.DefineTemplates.CustomDefines.FindChildByName(
    SettingDelphiModeTemplName)=nil
  then exit;
  AProject.DefineTemplates.CustomDefines.DeleteChild(SettingDelphiModeTemplName);
  CodeToolBoss.DefineTree.ClearCache;
end;

function CreateDelphiToLazarusPackageInstance(const LPKFilename: string; out
  APackage: TLazPackage): TModalResult;
// If .lpk does not exist, create it
// open new package
begin
  DebugLn('CreateDelphiToLazarusPackageInstance LPKFilename="',LPKFilename,'"');
  APackage:=nil;
  if FileExists(LPKFilename) then begin
    // there is already a lazarus package file
    // open the package editor
    Result:=PackageEditingInterface.DoOpenPackageFile(LPKFilename,[pofAddToRecent]);
    // TODO: get package
    Result:=mrAbort;
    if Result<>mrOk then exit;
  end else begin
    // create a new lazarus package
    // TODO: get package
    Result:=mrAbort;
    if Result<>mrOk then exit;
  end;
  // save to disk (this makes sure, all editor changes are saved too)
  DebugLn('CreateDelphiToLazarusProject saving project ...');
  Result:=PackageEditingInterface.DoSaveAllPackages([]);
end;

end.

