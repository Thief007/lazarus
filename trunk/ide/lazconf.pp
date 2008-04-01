{
 /***************************************************************************
                               lazconf.pp
                             -------------------
                           Lazarus Config Functions
                   Initial Revision  : Tue Apr 18 22:10:00 CET 2000

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

{
@author(Config Path Functions - Curtis White <cwhite@aracnet.com>)
@created(18-Apr-2000)
@lastmod(18-Apr-2000)

This unit contains functions to manage OS specific configuration path
information from within Lazarus.
}
unit LazConf;

{$mode objfpc}{$H+}

interface

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}

uses
  SysUtils, Classes, LCLProc, DefineTemplates, FileUtil, InterfaceBase;

const
  LCLPlatformDisplayNames: array[TLCLPlatform] of string = (
      'gtk',
      'gtk 2 (beta)',
      'win32/win64',
      'wince (beta)',
      'carbon (alpha)',
      'qt (alpha)',
      'fpGUI (pre-alpha)',
      'NoGUI (pre-alpha)'
    );


  { Config Path Functions }

  { The primary config path is the local or user specific path.
    If the primary config path does not exist, it will automatically be
    created by the IDE.
    The secondary config path is for templates. The IDE will never write to it.
    If a config file is not found in the primary config file, Lazarus will
    copy the template file from the secondary config file. If there is no
    template file, the IDE will use defaults.
  }
  function GetPrimaryConfigPath: String;
  function GetSecondaryConfigPath: String;
  procedure CreatePrimaryConfigPath;
  procedure SetPrimaryConfigPath(const NewValue: String);
  procedure SetSecondaryConfigPath(const NewValue: String);
  procedure CopySecondaryConfigFile(const AFilename: String);
  function GetProjectSessionsConfigPath: String;

  function GetDefaultTestBuildDirectory: string;
  
  function FindDefaultExecutablePath(const Executable: string): string;
  function FindDefaultCompilerPath: string;
  function FindDefaultMakePath: string;
  function FindDefaultFPCSrcDirectory: string;
  function FindDefaultLazarusSrcDirectory: string;
  function CheckFPCSourceDir(const ADirectory: string): boolean;
  function CheckLazarusDirectory(const ADirectory: string): boolean;

  // create a pascal file, which can be used to test the compiler
  function CreateCompilerTestPascalFilename: string;

  // returns the standard executable extension (e.g '.exe')
  function GetExecutableExt(TargetOS: string = ''): string;
  // returns the standard library extension (e.g '.dll' or '.dynlib')
  function GetLibraryExt(TargetOS: string = ''): string;

  // returns the standard file extension for compiled units (e.g '.ppu')
  function GetDefaultCompiledUnitExt(FPCVersion, FPCRelease: integer): string;
  
  function OSLocksExecutables: boolean;

  procedure GetDefaultCompilerFilenames(List: TStrings);
  procedure GetDefaultMakeFilenames(List: TStrings);
  procedure GetDefaultTestBuildDirs(List: TStrings);
  function GetDefaultCompilerFilename: string;

  function GetDefaultTargetCPU: string;
  function GetDefaultTargetOS: string;

  function GetDefaultLCLWidgetType: TLCLPlatform;
  function DirNameToLCLPlatform(const ADirName: string): TLCLPlatform;
  procedure GetDefaultLCLLibPaths(List: TStrings);
  function GetDefaultLCLLibPaths(const Prefix, Postfix, Separator: string): string;
  
  // returrns the default browser
  procedure GetDefaultBrowser(var Browser, Params: string);

const
  EmptyLine = LineEnding + LineEnding;
  EndOfLine: shortstring = LineEnding;
  
const
  ExitCodeRestartLazarus = 99;

implementation

{$I lazconf.inc}

function FindDefaultExecutablePath(const Executable: string): string;
begin
  if FilenameIsAbsolute(Executable) then
    Result:=Executable
  else
    Result:=SearchFileInPath(Executable,'',
                             SysUtils.GetEnvironmentVariable('PATH'),':',
                             [sffDontSearchInBasePath]);
end;

function GetDefaultLCLWidgetType: TLCLPlatform;
begin
  if WidgetSet<>nil then
    Result:=WidgetSet.LCLPlatform
  else begin
    {$IFDEF MSWindows}{$DEFINE WidgetSetDefined}
    Result:= lpWin32;
    {$ENDIF}
    {$IFNDEF WidgetSetDefined}
    Result:= lpGtk;
    {$ENDIF}
  end;
end;

function DirNameToLCLPlatform(const ADirName: string): TLCLPlatform;
begin
  for Result:=Low(TLCLPlatform) to High(TLCLPlatform) do
    if CompareText(ADirName,LCLPlatformDirNames[Result])=0 then exit;
  Result:=lpGtk;
end;

function GetDefaultLCLLibPaths(const Prefix, Postfix, Separator: string): string;
var
  List: TStringList;
  i: Integer;
begin
  List:=TStringList.Create;
  GetDefaultLCLLibPaths(List);
  Result:='';
  for i:=0 to List.Count-1 do begin
    if Result<>'' then Result:=Result+Separator;
    Result:=Result+Prefix+List[i]+PostFix;
  end;
  List.Free;
end;

{---------------------------------------------------------------------------
  CopySecondaryConfigFile procedure
 ---------------------------------------------------------------------------}
procedure CopySecondaryConfigFile(const AFilename: String);
var
  PrimaryFilename, SecondaryFilename: string;
  SrcFS, DestFS: TFileStream;
begin
  PrimaryFilename:=GetPrimaryConfigPath+PathDelim+AFilename;
  SecondaryFilename:=GetSecondaryConfigPath+PathDelim+AFilename;
  if (not FileExists(PrimaryFilename))
  and (FileExists(SecondaryFilename)) then begin
    try
      SrcFS:=TFileStream.Create(SecondaryFilename,fmOpenRead);
      try
        DestFS:=TFileStream.Create(PrimaryFilename,fmCreate);
        try
          DestFS.CopyFrom(SrcFS,SrcFS.Size);
        finally
          DestFS.Free;
        end;
      finally
        SrcFS.Free;
      end;
    except
    end;
  end;
end;

function GetProjectSessionsConfigPath: String;
begin
  Result:=AppendPathDelim(GetPrimaryConfigPath)+'projectsessions';
end;

function GetExecutableExt(TargetOS: string): string;
begin
  if TargetOS='' then
    TargetOS:=GetDefaultTargetOS;
  if (CompareText(copy(TargetOS,1,3), 'win') = 0)
  or (CompareText(copy(TargetOS,1,3), 'dos') = 0) then
    Result:='.exe'
  else
    Result:='';
end;

function GetLibraryExt(TargetOS: string): string;
begin
  if TargetOS='' then
    TargetOS:=GetDefaultTargetOS;
  if CompareText(copy(TargetOS,1,3), 'win') = 0 then
    Result:='.dll'
  else if CompareText(TargetOS, 'darwin') = 0 then
    Result:='.dylib'
  else
    Result:='';
end;

function GetDefaultTargetOS: string;
begin
  Result:=lowerCase({$I %FPCTARGETOS%});
end;

function GetDefaultTargetCPU: string;
begin
  Result:=lowerCase({$I %FPCTARGETCPU%});
end;

function GetDefaultCompilerFilename: string;
begin
  Result:=DefineTemplates.GetDefaultCompilerFilename;
end;

function CheckFPCSourceDir(const ADirectory: string): boolean;
var
  Dir: String;
begin
  Result:=false;
  if DirPathExists(ADirectory) then begin
    Dir:=AppendPathDelim(ADirectory);
    // test on rtl/inc, to prevent a false positive on a fpc compiled units dir
    // fpc 2.0: fcl is in fcl directory in fpc 2.0.x,
    // fpc 2.1 and later: fcl is in packages/fcl-base
    Result:=DirPathExists(Dir+SetDirSeparators('rtl/inc'))
        and (DirPathExists(SetDirSeparators(Dir+'packages/fcl-base'))
          or DirPathExists(SetDirSeparators(Dir+'fcl')));
  end;
end;

function FindDefaultFPCSrcDirectory: string;
var
  i: integer;
begin
  for i:=Low(DefaultFPCSrcDirs) to High(DefaultFPCSrcDirs) do begin
    Result:=DefaultFPCSrcDirs[i];
    if CheckFPCSourceDir(Result) then exit;
  end;
  Result:='';
end;

function FindDefaultLazarusSrcDirectory: string;
var
  i: integer;
begin
  for i:=Low(DefaultLazarusSrcDirs) to High(DefaultLazarusSrcDirs) do begin
    Result:=DefaultLazarusSrcDirs[i];
    if CheckLazarusDirectory(Result) then exit;
  end;
  Result:='';
end;

function CheckLazarusDirectory(const ADirectory: string): boolean;
var
  Dir: String;
begin
  Result:=false;
  if DirPathExists(ADirectory) then begin
    Dir:=AppendPathDelim(ADirectory);
    Result:=DirPathExists(Dir+'lcl')
        and DirPathExists(Dir+'components')
        and DirPathExists(Dir+'ide')
        and DirPathExists(Dir+'ideintf')
        and DirPathExists(Dir+'designer')
        and DirPathExists(Dir+'debugger');
  end;
end;

initialization
  InternalInit;

end.


