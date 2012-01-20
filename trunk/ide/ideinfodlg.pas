{
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
   IDE dialog showing stats about the IDE.
}
unit IDEInfoDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, LCLProc, LazHelpHTML, LazHelpIntf, DefineTemplates, EnvironmentOpts,
  AboutFrm, LazConf, IDEHelpIntf, LazarusIDEStrConsts, Project, SourceEditor,
  PackageSystem, PackageDefs;

type

  { TIDEInfoDialog }

  TIDEInfoDialog = class(TForm)
    GeneralMemo: TMemo;
    HelpMemo: TMemo;
    ModifiedMemo: TMemo;
    PageControl1: TPageControl;
    GeneralTabSheet: TTabSheet;
    ModifiedTabSheet: TTabSheet;
    HelpTabSheet: TTabSheet;
    procedure FormCreate(Sender: TObject);
  private
    // general
    procedure GatherIDEVersion(sl: TStrings);
    procedure GatherParameters(sl: TStrings);
    procedure GatherEnvironmentVars(sl: TStrings);
    procedure GatherGlobalOptions(sl: TStrings);
    // modified
    procedure GatherModifiedProject(AProject: TProject; sl: TStrings);
    procedure GatherModifiedPackages(sl: TStrings);
    // help
    procedure GatherHelpDB(sl: TStrings);
    procedure GatherFPCMessagesHelpDB(sl: TStrings);
  public
    procedure UpdateGeneralMemo;
    procedure UpdateModifiedMemo;
    procedure UpdateHelpMemo;
  end;

var
  IDEInfoDialog: TIDEInfoDialog;

function ShowIDEInfo: TModalResult;


implementation

function ShowIDEInfo: TModalResult;
var
  Dlg: TIDEInfoDialog;
begin
  Dlg:=TIDEInfoDialog.Create(nil);
  try
    Result:=Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

{$R *.lfm}

{ TIDEInfoDialog }

procedure TIDEInfoDialog.FormCreate(Sender: TObject);
begin
  Caption:=lisIDEInfoInformationAboutTheIDE;

  UpdateGeneralMemo;
  UpdateModifiedMemo;
  UpdateHelpMemo;
  PageControl1.ActivePage:=GeneralTabSheet;
end;

procedure TIDEInfoDialog.GatherIDEVersion(sl: TStrings);
const
  LazarusVersionStr= {$I version.inc};
begin
  sl.Add('Lazarus version: '+GetLazarusVersionString);
  sl.Add('Lazarus svn revision: '+LazarusRevisionStr);
  sl.Add('Lazarus build date: '+{$I %date%});
  sl.Add('Lazarus was compiled for '+GetCompiledTargetCPU+'-'+GetCompiledTargetOS);
  sl.Add('Lazarus was compiled with fpc '+{$I %FPCVERSION%});
  sl.Add('');
end;

procedure TIDEInfoDialog.GatherParameters(sl: TStrings);
var
  i: Integer;
begin
  sl.Add('Working directory='+GetCurrentDirUTF8);
  sl.Add('Application.ExeName='+Application.ExeName);
  sl.Add('');
  sl.add('Parameters:');
  for i:=0 to Paramcount do
    sl.Add(ParamStrUTF8(i));
  sl.Add('');
end;

procedure TIDEInfoDialog.GatherEnvironmentVars(sl: TStrings);
var
  i: Integer;
begin
  sl.Add('Environment variables:');
  for i:=0 to GetEnvironmentVariableCount-1 do
    sl.Add(GetEnvironmentStringUTF8(i));
  sl.Add('');
end;

procedure TIDEInfoDialog.GatherGlobalOptions(sl: TStrings);
begin
  sl.add('Global IDE options:');
  sl.Add('Primary config directory='+GetPrimaryConfigPath);
  sl.Add('Secondary config directory='+GetSecondaryConfigPath);
  sl.Add('LazarusDirectory='+EnvironmentOptions.LazarusDirectory);
  sl.Add('CompilerFilename='+EnvironmentOptions.CompilerFilename);
  sl.Add('Real CompilerFilename='+EnvironmentOptions.GetCompilerFilename);
  sl.Add('CompilerMessagesFilename='+EnvironmentOptions.CompilerMessagesFilename);
  sl.Add('FPC source directory='+EnvironmentOptions.FPCSourceDirectory);
  sl.Add('Real FPC source directory='+EnvironmentOptions.GetFPCSourceDirectory);
  sl.Add('Test directory='+EnvironmentOptions.GetTestBuildDirectory);
  sl.Add('');
end;

procedure TIDEInfoDialog.GatherModifiedProject(AProject: TProject; sl: TStrings);
var
  aFile: TUnitInfo;
  HeaderWritten: Boolean;
  s: String;
begin
  // summary
  if AProject.Modified then
    sl.Add('Project.Modified');
  if AProject.SessionModified then
    sl.Add('Project.SessionModified');
  if Project1.SomethingModified(true,false) then
    sl.Add('Project.SomethingModified Data');
  if Project1.SomethingModified(false,true) then
    sl.Add('Project.SomethingModified Session');
  if SourceEditorManager.SomethingModified(false) then
    sl.Add('SourceEditorManager.SomethingModified');
  if AProject.BuildModes.IsModified(false) then
    sl.Add('Project.BuildModes.IsModified data');
  if AProject.BuildModes.IsModified(true) then
    sl.Add('Project.BuildModes.IsModified session');
  sl.Add('');

  // details
  HeaderWritten:=false;
  aFile:=AProject.FirstPartOfProject;
  while aFile<>nil do begin
    if aFile.Modified or aFile.SessionModified
    or ((aFile.Source<>nil) and aFile.Source.Modified)
    then begin
      if not HeaderWritten then begin
        sl.Add('Project units:');
        s:=aFile.GetShortFilename(true);
        if aFile.Modified then
          s:=s+' Modified';
        if aFile.SessionModified then
          s:=s+' SessionModified';
        if (aFile.Source<>nil) and (aFile.Source.Modified) then
          s:=s+' Source.Modified';
        sl.Add(s);
      end;
    end;
    aFile:=aFile.NextPartOfProject;
  end;
  if HeaderWritten then
    sl.Add('');
end;

procedure TIDEInfoDialog.GatherModifiedPackages(sl: TStrings);
var
  i: Integer;
  Pkg: TLazPackage;
  HeaderWritten: Boolean;
begin
  HeaderWritten:=false;
  for i:=0 to PackageGraph.Count-1 do begin
    Pkg:=PackageGraph[i];
    if Pkg.Modified then begin
      if not HeaderWritten then begin
        HeaderWritten:=true;
        sl.Add('Packages:');
      end;
      sl.Add(Pkg.Name);
    end;
  end;
  if HeaderWritten then
    sl.Add('');
end;

procedure TIDEInfoDialog.GatherHelpDB(sl: TStrings);
begin
  // LazarusHelp

end;

procedure TIDEInfoDialog.GatherFPCMessagesHelpDB(sl: TStrings);
var
  HTMLHelp: THTMLHelpDatabase;
  i: Integer;
  DBItem: THelpDBItem;
  DBISourceFile: THelpDBISourceFile;
  DBISourceDirectory: THelpDBISourceDirectory;
  DBISourceDirectories: THelpDBISourceDirectories;
  DBIRegExprMessage: THelpDBIRegExprMessage;
begin
  sl.Add(DbgSName(FPCMessagesHelpDB));
  sl.Add('ID='+FPCMessagesHelpDB.ID);
  sl.Add('LocalizedName='+dbgstr(FPCMessagesHelpDB.GetLocalizedName));
  sl.Add('BasePathObject='+DbgSName(FPCMessagesHelpDB.BasePathObject));
  sl.Add('Registered='+dbgs(FPCMessagesHelpDB.Registered));
  if FPCMessagesHelpDB.SupportedMimeTypes<>nil then begin
    sl.Add('SupportedMimeTypes: '+IntToStr(FPCMessagesHelpDB.SupportedMimeTypes.Count));
    sl.AddStrings(FPCMessagesHelpDB.SupportedMimeTypes);
    sl.Add('');
  end;
  if FPCMessagesHelpDB is THTMLHelpDatabase then begin
    HTMLHelp:=THTMLHelpDatabase(FPCMessagesHelpDB);
    sl.Add('BaseURL='+dbgstr(HTMLHelp.BaseURL));
    if HTMLHelp.BaseURL='' then
      sl.Add('DefaultBaseURL='+dbgstr(HTMLHelp.DefaultBaseURL));
    sl.Add('KeywordPrefix='+dbgstr(HTMLHelp.KeywordPrefix));
  end;

  // registered items
  sl.Add('Items:');
  for i:=0 to FPCMessagesHelpDB.RegisteredItemCount-1 do begin
    DBItem:=FPCMessagesHelpDB.GetRegisteredItem(i);
    sl.Add(IntToStr(i+1)+'/'+IntToStr(FPCMessagesHelpDB.RegisteredItemCount)+': '+DbgSName(DBItem));
    if DBItem is THelpDBISourceFile then begin
      DBISourceFile:=THelpDBISourceFile(DBItem);
      sl.Add('  Filename='+DBISourceFile.Filename);
      sl.Add('  FullFilename='+DBISourceFile.GetFullFilename);
      sl.Add('  BasePath='+DBISourceFile.GetBasePath);
      if DBISourceFile is THelpDBISourceDirectory then begin
        DBISourceDirectory:=THelpDBISourceDirectory(DBISourceFile);
        sl.Add('  FileMask='+DBISourceDirectory.FileMask);
        sl.Add('  WithSubDirectories='+dbgs(DBISourceDirectory.WithSubDirectories));
        if DBISourceDirectory is THelpDBISourceDirectories then begin
          DBISourceDirectories:=THelpDBISourceDirectories(DBISourceDirectory);
          sl.Add('  BaseDirectory='+DBISourceDirectories.BaseDirectory);
        end;
      end;
    end else if DBItem is THelpDBIClass then begin
      sl.Add('  Class='+DbgSName(THelpDBIClass(DBItem)));
    end else if DBItem is THelpDBIRegExprMessage then begin
      DBIRegExprMessage:=THelpDBIRegExprMessage(DBItem);
      sl.Add('  Expression='+DBIRegExprMessage.Expression);
      sl.Add('  ModifierStr='+DBIRegExprMessage.ModifierStr);
    end;
  end;
end;

procedure TIDEInfoDialog.UpdateGeneralMemo;
var
  sl: TStringList;
begin
  sl:=TStringList.Create;
  try
    GatherIDEVersion(sl);
    GatherGlobalOptions(sl);
    GatherParameters(sl);
    GatherEnvironmentVars(sl);
    GeneralMemo.Lines.Assign(sl);
  finally
    sl.Free;
  end;
end;

procedure TIDEInfoDialog.UpdateModifiedMemo;
var
  sl: TStringList;
begin
  sl:=TStringList.Create;
  try
    GatherModifiedProject(Project1,sl);
    GatherModifiedPackages(sl);
    ModifiedMemo.Lines.Assign(sl);
  finally
    sl.Free;
  end;
end;

procedure TIDEInfoDialog.UpdateHelpMemo;
var
  sl: TStringList;
begin
  sl:=TStringList.Create;
  try
    GatherHelpDB(sl);
    GatherFPCMessagesHelpDB(sl);
    HelpMemo.Lines.Assign(sl);
  finally
    sl.Free;
  end;
end;

end.

