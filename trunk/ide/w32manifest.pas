{
 /***************************************************************************
                        w32manifest.pas  -  Lazarus IDE unit
                        ---------------------------------------
              TProjectXPManifest is responsible for the inclusion of the 
                   manifest in windows executables.


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

  The manifest file is needed for windows XP themes.
  The file is created in the directory, where the project exe is created.
}
unit W32Manifest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Process, LCLProc, Controls, Forms,
  CodeToolManager, CodeCache, LazConf, DialogProcs, LResources,
  ProjectResourcesIntf;
   
type
  { TProjectXPManifest }

  TProjectXPManifest = class(TAbstractProjectResource)
  private
    FManifestName: string;
    FUseManifest: boolean;
    procedure SetFileNames(const MainFilename: string);
    procedure SetUseManifest(const AValue: boolean);
  public
    function UpdateResources(AResources: TAbstractProjectResources; const MainFilename: string): Boolean; override;
    function CreateManifestFile(ExeFilename: string): TModalResult;
    function NeedManifest(AResources: TAbstractProjectResources): boolean;

    property UseManifest: boolean read FUseManifest write SetUseManifest;
    property ManifestName: string read FManifestName;
  end;

implementation

const
  sManifest: String =
    '#define RT_MANIFEST  24'#$D#$A+
    '#define CREATEPROCESS_MANIFEST_RESOURCE_ID 1'#$D#$A+
    '#define ISOLATIONAWARE_MANIFEST_RESOURCE_ID 2'#$D#$A+
    '#define ISOLATIONAWARE_NOSTATICIMPORT_MANIFEST_RESOURCE_ID 3'#$D#$A#$D#$A+
    'CREATEPROCESS_MANIFEST_RESOURCE_ID RT_MANIFEST';
  sManifestFileData: String =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'#$D#$A+
    '<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">'#$D#$A+
    ' <assemblyIdentity version="1.0.0.0" processorArchitecture="*" name="CompanyName.ProductName.YourApp" type="win32"/>'#$D#$A+
    ' <description>Your application description here.</description>'#$D#$A+
    ' <dependency>'#$D#$A+
    '  <dependentAssembly>'#$D#$A+
    '   <assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="*" publicKeyToken="6595b64144ccf1df" language="*"/>'#$D#$A+
    '  </dependentAssembly>'#$D#$A+
    ' </dependency>'#$D#$A+
    ' <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">'#$D#$A+
    '  <security>'#$D#$A+
    '   <requestedPrivileges>'#$D#$A+
    '    <requestedExecutionLevel level="asInvoker" uiAccess="false"/>'#$D#$A+
    '   </requestedPrivileges>'#$D#$A+
    '  </security>'#$D#$A+
    ' </trustInfo>'#$D#$A+
    '</assembly>';

procedure TProjectXPManifest.SetFileNames(const MainFilename: string);
begin
  FManifestName := ExtractFileNameOnly(MainFilename)+'.manifest';
end;

procedure TProjectXPManifest.SetUseManifest(const AValue: boolean);
begin
  if FUseManifest = AValue then exit;
  FUseManifest := AValue;
  Modified := True;
end;

function TProjectXPManifest.UpdateResources(AResources: TAbstractProjectResources;
  const MainFilename: string): Boolean;
begin
  Result := True;

  if not NeedManifest(AResources) then
    Exit;

  SetFileNames(MainFilename);

  AResources.AddSystemResource(sManifest + ' "' + ManifestName + '"');
  Result:=true;
end;

function TProjectXPManifest.CreateManifestFile(ExeFilename: string): TModalResult;
var
  ManifestFileName: String;
  Code: TCodeBuffer;
begin
  Result := mrCancel;
  if not FilenameIsAbsolute(ExeFilename) then exit(mrOk);
  ManifestFileName:=ChangeFileExt(ExeFilename,'.manifest');
  // check if manifest file is uptodate
  // (needed for readonly files and for version control systems)
  Code:=CodeToolBoss.LoadFile(ManifestFileName,true,true);
  if (Code<>nil) and (Code.Source=sManifestFileData) then exit(mrOk);
  // save
  if Code=nil then
    Code:=CodeToolBoss.CreateFile(ManifestFileName);
  Code.Source:=sManifestFileData;
  Result:=SaveCodeBuffer(Code);
end;

function TProjectXPManifest.NeedManifest(AResources: TAbstractProjectResources
  ): boolean;
var
  TargetOS: String;
begin
  Result:=false;
  if not UseManifest then exit;
  if AResources.Project=nil then exit;
  TargetOS:=AResources.Project.LazCompilerOptions.TargetOS;
  if (TargetOS='') or (TargetOS='default') then
    TargetOS:=GetDefaultTargetOS;
  if (TargetOS<>'win32') and (TargetOS<>'win64') then exit;
  Result:=true;
end;


end.

