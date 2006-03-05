{  $Id$  }
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
    Functions to convert delphi units to lcl units.

}
unit DelphiUnit2Laz;

{$mode objfpc}{$H+}

interface

uses
  // FCL+LCL
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Graphics,
  Dialogs, Buttons, StdCtrls, FileUtil, IniFiles,
  // Components
  SynEdit, CodeCache, CodeToolManager, DefineTemplates,
  // IDE
  Project, DialogProcs, IDEProcs, LazarusIDEStrConsts;

type
  TDelphi2LazarusDialog = class(TForm)
  private
  public
  end;

var
  Delphi2LazarusDialog: TDelphi2LazarusDialog;
  
function CheckDelphiFileExt(const Filename: string): TModalResult;
function CheckFilenameForLCLPaths(const Filename: string): TModalResult;
function ConvertDelphiToLazarusFilename(const DelphiFilename: string): string;
function ConvertDFMToLFMFilename(const DFMFilename: string;
  KeepCase: boolean): string;
function FindDFMFileForDelphiUnit(const DelphiFilename: string): string;
function RenameDelphiUnitToLazarusUnit(const DelphiFilename: string;
  RenameDFMFile: boolean;
  var LazarusFilename, LFMFilename: string): TModalResult;
function ConvertDFMFileToLFMFile(const DFMFilename: string): TModalResult;
function ConvertDelphiSourceToLazarusSource(const LazarusUnitFilename: string;
  AddLRSCode: boolean): TModalResult;
function FixMissingUnits(const LazarusUnitFilename: string): TModalResult;
function LoadUnitAndLFMFile(const UnitFileName: string;
  var UnitCode, LFMCode: TCodeBuffer; LFMMustExist: boolean): TModalResult;
function ConvertLFMtoLRSfile(const LFMFilename: string): TModalResult;
function CheckDelphiProjectExt(const Filename: string): TModalResult;
function CreateLPRFileForDPRFile(const DPRFilename, LPRFilename: string;
  out LPRCode: TCodeBuffer): TModalResult;
function ExtractOptionsFromDPR(DPRCode: TCodeBuffer;
  AProject: TProject): TModalResult;


function FindDelphiDOF(const DelphiFilename: string): string;
function ExtractOptionsFromDOF(const DOFFilename: string;
                               AProject: TProject): TModalResult;
function FindDelphiCFG(const DelphiFilename: string): string;
function ExtractOptionsFromCFG(const CFGFilename: string;
                               AProject: TProject): TModalResult;

function ConvertDelphiAbsoluteToRelativeFile(const Filename: string;
                                             AProject: TProject): string;
function ExpandDelphiFilename(const Filename: string; AProject: TProject): string;
function ExpandDelphiSearchPath(const SearchPath: string;
                                AProject: TProject): string;


implementation


function CheckDelphiFileExt(const Filename: string): TModalResult;
begin
  if CompareFileExt(Filename,'.pas',false)<>0 then begin
    Result:=MessageDlg(lisNotADelphiUnit,
      Format(lisTheFileIsNotADelphiUnit, ['"', Filename, '"']),
      mtError,[mbCancel,mbAbort],0);
    exit;
  end;
  Result:=mrOk;
end;

function CheckFilenameForLCLPaths(const Filename: string): TModalResult;
// check if the unitpath of the directory of filename contains the path to the
// LCL
var
  Directory: String;
  UnitPath: String;
  LazarusSrcDir: string;
  LCLPath: String;
  NextStartPos: Integer;
begin
  // get directory of filename
  Directory:=ExtractFilePath(Filename);
  // get unitpath definition of directory
  UnitPath:=CodeToolBoss.GetUnitPathForDirectory(Directory);
  // get lazarus source directory
  LazarusSrcDir:=
           CodeToolBoss.GlobalValues.Variables[ExternalMacroStart+'LazarusDir'];
  // create base path to LCL compiled units <LazarusSrcDir>/lcl/units/
  LCLPath:=TrimFilename(LazarusSrcDir+SetDirSeparators('/lcl/units/'));
  NextStartPos:=1;
  //writeln('CheckFilenameForLCLPaths UnitPath="',UnitPath,'" LCLPath="',LCLPath,'"');
  if GetNextUsedDirectoryInSearchPath(UnitPath,LCLPath,NextStartPos)='' then
  begin
    LCLPath:=LCLPath+'$(TargetCPU)-$(TargetOS)';
    Result:=MessageDlg(lisLCLUnitPathMissing,
      Format(lisTheCurrentUnitPathForTheFileIsThePathToTheLCLUnits, [#13, '"',
        Filename, '"', #13, '"', UnitPath, '"', #13, #13, '"', LCLPath, '"',
        #13, #13, #13]),
      mtError,[mbCancel,mbAbort],0);
    exit;
  end;
  Result:=mrOk;
end;

function ConvertDelphiToLazarusFilename(const DelphiFilename: string): string;
begin
  Result:=ExtractFilePath(DelphiFilename)
          +lowercase(ExtractFileName(DelphiFilename));
end;

function ConvertDFMToLFMFilename(const DFMFilename: string;
  KeepCase: boolean): string;
begin
  if DFMFilename<>'' then begin
    // platform and fpc independent unitnames are lowercase, so are the lfm files
    Result:=lowercase(ExtractFilenameOnly(DFMFilename));
    if KeepCase then
      Result:=ExtractFilenameOnly(DFMFilename);
    Result:=ExtractFilePath(DFMFilename)+Result+'.lfm';
  end else
    Result:='';
end;

function FindDFMFileForDelphiUnit(const DelphiFilename: string): string;
begin
  Result:=ChangeFileExt(DelphiFilename,'.dfm');
  if FileExists(Result) then exit;
  Result:=ChangeFileExt(DelphiFilename,'.DFM');
  if FileExists(Result) then exit;
  Result:=ChangeFileExt(DelphiFilename,'.xfm');
  if FileExists(Result) then exit;
  Result:=ChangeFileExt(DelphiFilename,'.XFM');
  if FileExists(Result) then exit;
  Result:='';
end;

function RenameDelphiUnitToLazarusUnit(const DelphiFilename: string;
  RenameDFMFile: boolean;
  var LazarusFilename, LFMFilename: string): TModalResult;
var
  DFMFilename: String;
begin
  LazarusFilename:=ConvertDelphiToLazarusFilename(DelphiFilename);
  LFMFilename:='';
  //writeln('RenameDelphiUnitToLazarusUnit Unit "',DelphiFilename,'" -> "',LazarusFilename,'"');
  Result:=RenameFileWithErrorDialogs(DelphiFilename,LazarusFilename,[mbAbort]);
  if Result<>mrOK then exit;
  if RenameDFMFile then begin
    DFMFilename:=FindDFMFileForDelphiUnit(DelphiFilename);
    if DFMFilename<>'' then begin
      LFMFilename:=ConvertDFMToLFMFilename(DFMFilename,false);
      //writeln('RenameDelphiUnitToLazarusUnit Unit "',DFMFilename,'" -> "',LFMFilename,'"');
      Result:=RenameFileWithErrorDialogs(DFMFilename,LFMFilename,[mbAbort]);
      if Result<>mrOK then exit;
    end;
  end;
  Result:=mrOk;
end;

function ConvertDFMFileToLFMFile(const DFMFilename: string): TModalResult;
var
  DFMStream, LFMStream: TMemoryStream;
  LFMFilename: string;
begin
  Result:=mrOk;
  DFMStream:=TMemoryStream.Create;
  LFMStream:=TMemoryStream.Create;
  try
    try
      DFMStream.LoadFromFile(DFMFilename);
    except
      on E: Exception do begin
        Result:=MessageDlg(lisCodeToolsDefsReadError, Format(
          lisUnableToReadFileError, ['"', DFMFilename, '"', #13, E.Message]),
          mtError,[mbIgnore,mbAbort],0);
        exit;
      end;
    end;
    try
      FormDataToText(DFMStream,LFMStream);
    except
      on E: Exception do begin
        Result:=MessageDlg(lisFormatError,
          Format(lisUnableToConvertFileError, ['"', DFMFilename, '"', #13,
            E.Message]),
          mtError,[mbIgnore,mbAbort],0);
        exit;
      end;
    end;
    // converting dfm file, without renaming unit -> keep case
    LFMFilename:=ConvertDFMToLFMFilename(DFMFilename,true);
    //writeln('ConvertDFMFileToLFMFile LFMFilename="',LFMFilename,'"');
    try
      LFMStream.SaveToFile(LFMFilename);
    except
      on E: Exception do begin
        Result:=MessageDlg(lisCodeToolsDefsWriteError,
          Format(lisUnableToWriteFileError, ['"', LFMFilename, '"', #13,
            E.Message]),
          mtError,[mbIgnore,mbAbort],0);
        exit;
      end;
    end;
  finally
    LFMSTream.Free;
    DFMStream.Free;
  end;
end;

function ConvertDelphiSourceToLazarusSource(const LazarusUnitFilename: string;
  AddLRSCode: boolean): TModalResult;
var
  LazUnitCode: TCodeBuffer;
  CTResult: Boolean;
begin
  Result:=LoadCodeBuffer(LazUnitCode,LazarusUnitFilename,
                         [lbfCheckIfText,lbfUpdateFromDisk]);
  if Result<>mrOk then exit;
  CTResult:=CodeToolBoss.ConvertDelphiToLazarusSource(LazUnitCode,AddLRSCode);
  if not CTResult then begin
    Result:=mrCancel;
    exit;
  end;
  Result:=mrOk;
end;

function FixMissingUnits(const LazarusUnitFilename: string): TModalResult;
var
  LazUnitCode: TCodeBuffer;
  CTResult: Boolean;
  MissingUnits: TStrings;
  MissingUnitsText: String;
  i: Integer;
  Msg: String;
begin
  Result:=LoadCodeBuffer(LazUnitCode,LazarusUnitFilename,
                         [lbfCheckIfText,lbfUpdateFromDisk]);
  if Result<>mrOk then exit;
  MissingUnits:=nil;
  try
    // find missing units
    DebugLn('FixMissingUnits FindMissingUnits');
    CTResult:=CodeToolBoss.FindMissingUnits(LazUnitCode,MissingUnits);
    if not CTResult then begin
      Result:=mrCancel;
      exit;
    end;
    if (MissingUnits=nil) or (MissingUnits.Count=0) then begin
      Result:=mrOk;
      exit;
    end;

    MissingUnitsText:='';
    for i:=0 to MissingUnits.Count-1 do begin
      if MissingUnitsText<>'' then
        MissingUnitsText:=MissingUnitsText+', ';
      MissingUnitsText:=MissingUnitsText+MissingUnits[i];
    end;
    DebugLn('FixMissingUnits FindMissingUnits="',MissingUnitsText,'"');
    // ask user if missing units should be commented
    if MissingUnits.Count=1 then
      Msg:=lisUnitNotFound
    else
      Msg:=lisUnitsNotFound2;
    Result:=MessageDlg(Msg,
      Format(lisTheFollowingUnitsWereNotFound1EitherTheseUnitsAreN, [#13,
        MissingUnitsText, #13, #13, #13, #13, #13, #13]),
      mtConfirmation,[mbYes,mbAbort],0);
    if Result<>mrYes then exit;

    // comment missing units
    DebugLn('FixMissingUnits CommentUnitsInUsesSections');
    CTResult:=CodeToolBoss.CommentUnitsInUsesSections(LazUnitCode,MissingUnits);
    if not CTResult then begin
      Result:=mrCancel;
      exit;
    end;

  finally
    MissingUnits.Free;
  end;
  Result:=mrOk;
end;

function LoadUnitAndLFMFile(const UnitFileName: string;
  var UnitCode, LFMCode: TCodeBuffer; LFMMustExist: boolean): TModalResult;
var
  LFMFilename: string;
begin
  UnitCode:=nil;
  LFMCode:=nil;
  Result:=LoadCodeBuffer(UnitCode,UnitFileName,
                         [lbfCheckIfText,lbfUpdateFromDisk]);
  if Result<>mrOk then exit;
  LFMFilename:=ChangeFileExt(UnitFileName,'.lfm');
  if FileExists(LFMFilename) then begin
    Result:=LoadCodeBuffer(LFMCode,LFMFilename,
                           [lbfCheckIfText,lbfUpdateFromDisk]);
    if Result<>mrOk then exit;
  end else if LFMMustExist then begin
    Result:=MessageDlg(lisLFMFileNotFound,
                       Format(lisUnitLFMFile, [UnitFileName, #13, LFMFilename]),
                       mtError,[mbCancel,mbAbort],0);
  end;
end;

function ConvertLFMtoLRSfile(const LFMFilename: string): TModalResult;
begin
  if not LFMtoLRSfile(LFMFilename) then begin
    Result:=MessageDlg(lisErrorCreatingLrs,
      lisUnableToConvertLfmToLrsAndWriteLrsFile,
      mtError,[mbCancel],0);
    exit;
  end;
  Result:=mrOk;
end;

function CheckDelphiProjectExt(const Filename: string): TModalResult;
begin
  if CompareFileExt(Filename,'.dpr',false)<>0 then begin
    Result:=MessageDlg(lisNotADelphiProject,
      Format(lisTheFileIsNotADelphiProjectDpr, ['"', Filename, '"']),
      mtError,[mbCancel,mbAbort],0);
    exit;
  end;
  Result:=mrOk;
end;

function CreateLPRFileForDPRFile(const DPRFilename, LPRFilename: string;
  out LPRCode: TCodeBuffer): TModalResult;
begin
  if not FileExists(LPRFilename) then begin
    Result:=CopyFileWithErrorDialogs(DPRFilename,LPRFilename,[]);
    if Result<>mrOk then exit;
  end;
  Result:=LoadCodeBuffer(LPRCode,LPRFilename,
                         [lbfCheckIfText,lbfUpdateFromDisk]);
end;

function ExtractOptionsFromDPR(DPRCode: TCodeBuffer; AProject: TProject
  ): TModalResult;
begin
  // TODO remove compiler directives in code and put them into AProject
  Result:=mrOk;
end;

function FindDelphiDOF(const DelphiFilename: string): string;
var
  Filename: String;
begin
  Result:=ChangeFileExt(DelphiFilename,'.dof');
  Filename:=FindDiskFileCaseInsensitive(Result);
  if Filename<>'' then
    Result:=Filename;
end;

function ExtractOptionsFromDOF(const DOFFilename: string; AProject: TProject
  ): TModalResult;
// parse .dof file and put options into AProject
var
  IniFile: TIniFile;
  
  function ReadDirectory(const Section, Ident: string): string;
  begin
    Result:=IniFile.ReadString(Section,Ident,'');
    DebugLn('.dof ReadDirectory Section=',Section,' Ident=',Ident,' Result="',Result,'"');
    Result:=ExpandDelphiFilename(Result,AProject);
  end;
  
  function ReadSearchPath(const Section, Ident: string): string;
  var
    SearchPath: String;
  begin
    SearchPath:=IniFile.ReadString(Section,Ident,'');
    DebugLn('.dof ReadSearchPath Section=',Section,' Ident=',Ident,' SearchPath="',SearchPath,'"');
    Result:=ExpandDelphiSearchPath(SearchPath,AProject);
  end;
  
  procedure AddPackageDependency(const DelphiPkgName, DelphiPkgNames,
    LazarusPkgName: string);
  begin
    if DelphiPkgName='' then exit;
    if System.Pos(';'+lowercase(DelphiPkgName)+';',
                  ';'+lowercase(DelphiPkgNames)+';')>0 then begin
      DebugLn('AddPackageDependency adding package dependency ',LazarusPkgName);
      AProject.AddPackageDependency(LazarusPkgName);
    end;
  end;

  procedure ReadDelphiPackages;
  var
    DelphiPackages: String;
    Pkgs: TStringList;
    i: Integer;
    Pkg: string;
  begin
    DelphiPackages:=IniFile.ReadString('Directories','Packages','');
    //DebugLn('ReadDelphiPackages DelphiPackages=',DelphiPackages);
    Pkgs:=SplitString(DelphiPackages,';');
    if Pkgs=nil then exit;
    for i:=0 to Pkgs.Count-1 do begin
      Pkg:=Pkgs[i];
      DebugLn('ReadDelphiPackages Pkg=',Pkg);
      AddPackageDependency(Pkg,'rtl,dbrtl','FCL');
      AddPackageDependency(Pkg,'vcl;vcldb;vcldbx','LCL');
    end;
  end;

var
  OutputDir: String;
  SearchPath: String;
  DebugSourceDirs: String;
begin
  if not FileExists(DOFFilename) then exit(mrOk);
  try
    IniFile:=TIniFile.Create(DOFFilename);
    try
      // output directory
      OutputDir:=ReadDirectory('Directories','OutputDir');
      if (OutputDir<>'') then begin
        DebugLn('ExtractOptionsFromDOF setting unit output directory to "',OutputDir,'"');
        AProject.CompilerOptions.UnitOutputDirectory:=OutputDir;
      end;
      
      // search path
      SearchPath:=ReadSearchPath('Directories','SearchPath');
      if (SearchPath<>'') then begin
        DebugLn('ExtractOptionsFromDOF Adding to search paths: "',SearchPath,'"');
        AProject.CompilerOptions.IncludeFiles:=
             MergeSearchPaths(AProject.CompilerOptions.IncludeFiles,SearchPath);
        AProject.CompilerOptions.Libraries:=
             MergeSearchPaths(AProject.CompilerOptions.Libraries,SearchPath);
        AProject.CompilerOptions.OtherUnitFiles:=
             MergeSearchPaths(AProject.CompilerOptions.OtherUnitFiles,SearchPath);
        AProject.CompilerOptions.ObjectPath:=
             MergeSearchPaths(AProject.CompilerOptions.ObjectPath,SearchPath);
        AProject.CompilerOptions.DebugPath:=
             MergeSearchPaths(AProject.CompilerOptions.DebugPath,SearchPath);
      end;
      
      // debug source dirs
      DebugSourceDirs:=ReadSearchPath('Directories','DebugSourceDirs');
      if DebugSourceDirs<>'' then begin
        DebugLn('ExtractOptionsFromDOF Adding to debug paths: "',DebugSourceDirs,'"');
        AProject.CompilerOptions.DebugPath:=
           MergeSearchPaths(AProject.CompilerOptions.DebugPath,DebugSourceDirs);
      end;
      
      // packages
      ReadDelphiPackages;
      
      if IniFile.ReadString('Linker','ConsoleApp','')='0' then begin
        // does not need a windows console
        DebugLn('ExtractOptionsFromDOF ConsoleApp=0');
        AProject.LazCompilerOptions.Win32GraphicApp:=true;
      end;
    finally
      IniFile.Free;
    end;
  except
    on E: Exception do begin
      DebugLn('ExtractOptionsFromDOF failed reading "'+DOFFilename+'" '+E.Message);
    end;
  end;
  Result:=mrOk;
end;

function FindDelphiCFG(const DelphiFilename: string): string;
var
  Filename: String;
begin
  Result:=ChangeFileExt(DelphiFilename,'.cfg');
  Filename:=FindDiskFileCaseInsensitive(Result);
  if Filename<>'' then
    Result:=Filename;
end;

function ExtractOptionsFromCFG(const CFGFilename: string; AProject: TProject
  ): TModalResult;
var
  sl: TStringList;
  i: Integer;
  Line: string;
  UnitPath: String;
  IncludePath: String;
begin
  if not FileExists(CFGFilename) then exit(mrOk);
  try
    sl:=TStringList.Create;
    try
      sl.LoadFromFile(CFGFilename);
      for i:=0 to sl.Count-1 do begin
        Line:=sl[i];
        if Line='' then continue;
        if (Line[1]<>'-') or (length(Line)<2) then continue;
        if Line[2]='U' then begin
          UnitPath:=ExpandDelphiSearchPath(copy(Line,4,length(Line)-4),AProject);
          if UnitPath<>'' then begin
            DebugLn('ExtractOptionsFromCFG adding unitpath "',UnitPath,'"');
            AProject.CompilerOptions.OtherUnitFiles:=
             MergeSearchPaths(AProject.CompilerOptions.OtherUnitFiles,UnitPath);
          end;
        end else if Line[2]='I' then begin
          IncludePath:=ExpandDelphiSearchPath(copy(Line,4,length(Line)-4),AProject);
          if IncludePath<>'' then begin
            DebugLn('ExtractOptionsFromCFG adding IncludePath "',IncludePath,'"');
            AProject.CompilerOptions.IncludeFiles:=
             MergeSearchPaths(AProject.CompilerOptions.IncludeFiles,IncludePath);
          end;
        end;
      end;
    finally
      sl.Free;
    end;
  except
    on E: Exception do begin
      DebugLn('ExtractOptionsFromDOF failed reading "'+CFGFilename+'" '+E.Message);
    end;
  end;
  Result:=mrOk;
end;

function ConvertDelphiAbsoluteToRelativeFile(const Filename: string;
  AProject: TProject): string;
var
  ProjectDir: String;
  ShortProjectDir: String;
  p: LongInt;
begin
  // often projects use paths near to their project directory
  // For example:
  //   A project /somewhere/MyProjects/project1.dpr
  // and a path C:\Delphi\MyProject\folder
  // can mean, that the relative path is 'folder'

  ProjectDir:=AProject.ProjectDirectory;
  ShortProjectDir:='\'+ExtractFileName(ChompPathDelim(ProjectDir))+'\';
  p:=System.Pos(ShortProjectDir,Filename);
  if (p>0) then begin
    Result:=copy(Filename,p+length(ShortProjectDir),length(Filename));
    exit;
  end;

  // ignore all other absolute paths
  Result:='';
end;

function ExpandDelphiFilename(const Filename: string; AProject: TProject
  ): string;
var
  p: LongInt;
begin
  Result:=Filename;
  if Result='' then exit;
  Result:=TrimFilename(SetDirSeparators(Result));

  // check for $(Delphi) makro
  p:=System.Pos('$(DELPHI)',Result);
  if p>0 then begin
    // Delphi features are provided by FPC and Lazarus
    // -> ignore
    Result:='';
  end;

  // check for other makros
  p:=System.Pos('$(',Result);
  if p>0 then begin
    // path makros are not supported
    // -> ignore
    Result:='';
  end;

  if FilenameIsWinAbsolute(Result) then begin
    // absolute filenames are not portable
    Result:=ConvertDelphiAbsoluteToRelativeFile(Result,AProject);
  end;

  // change PathDelim
  Result:=TrimFilename(SetDirSeparators(Result));
end;

function ExpandDelphiSearchPath(const SearchPath: string;
  AProject: TProject): string;
var
  Paths: TStringList;
  i: Integer;
  CurPath: String;
  j: Integer;
begin
  Result:='';
  Paths:=SplitString(SearchPath,';');
  if Paths=nil then exit;
  try
    // expand Delphi paths
    for i:=0 to Paths.Count-1 do
      Paths[i]:=ExpandDelphiFilename(Paths[i],AProject);
    // remove doubles
    for i:=Paths.Count-1 downto 0 do begin
      CurPath:=Paths[i];
      if (CurPath='') then
        Paths.Delete(i)
      else begin
        j:=i-1;
        while (j>=0) and (CompareText(CurPath,Paths[i])<>0) do dec(j);
        if j>=0 then
          Paths.Delete(i);
      end;
    end;
    Result:='';
    for i:=0 to Paths.Count-1 do begin
      if i>0 then Result:=Result+';';
      Result:=Result+Paths[i];
    end;
  finally
    Paths.Free;
  end;
end;

initialization
  {$I delphiunit2laz.lrs}

end.

