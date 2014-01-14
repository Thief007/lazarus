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

  Abtract:
    Frame for environment options for main paths, like
    Lazarus directory, compiler path.
}
unit files_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, FileUtil, CodeToolManager, DefineTemplates, Forms,
  StdCtrls, Dialogs, Controls, EnvironmentOpts, MacroIntf, LazarusIDEStrConsts,
  InputHistory, LazConf, IDEProcs, IDEOptionsIntf, IDEDialogs, InitialSetupDlgs;

type

  { TFilesOptionsFrame }

  TFilesOptionsFrame = class(TAbstractIDEOptionsEditor)
    AutoCloseCompileDialogCheckBox: TCheckBox;
    CompilerMessagesButton:TButton;
    CompilerMessagesComboBox:TComboBox;
    CompilerMessagesLabel:TLabel;
    CompilerPathButton:TButton;
    CompilerPathComboBox:TComboBox;
    CompilerPathLabel:TLabel;
    FPCSourceDirButton:TButton;
    FPCSourceDirComboBox:TComboBox;
    FPCSourceDirLabel:TLabel;
    LazarusDirButton:TButton;
    LazarusDirComboBox:TComboBox;
    LazarusDirLabel:TLabel;
    MakePathButton:TButton;
    MakePathComboBox:TComboBox;
    MakePathLabel:TLabel;
    MaxRecentOpenFilesComboBox: TComboBox;
    MaxRecentOpenFilesLabel: TLabel;
    MaxRecentProjectFilesComboBox: TComboBox;
    MaxRecentProjectFilesLabel: TLabel;
    OpenLastProjectAtStartCheckBox: TCheckBox;
    ShowCompileDialogCheckBox: TCheckBox;
    TestBuildDirButton:TButton;
    TestBuildDirComboBox:TComboBox;
    TestBuildDirLabel:TLabel;
    procedure CompilerMessagesButtonClick(Sender:TObject);
    procedure FilesButtonClick(Sender: TObject);
    procedure DirectoriesButtonClick(Sender: TObject);
    procedure ShowCompileDialogCheckBoxChange(Sender: TObject);
  private
    FOldLazarusDir: string;
    FOldRealLazarusDir: string;
    FOldCompilerFilename: string;
    FOldRealCompilerFilename: string;
    FOldFPCSourceDir: string;
    FOldRealFPCSourceDir: string;
    FOldMakeFilename: string;
    FOldRealMakeFilename: string;
    FOldTestDir: string;
    FOldRealTestDir: string;
    fOldCompilerMessagesFilename: string;
    fOldRealCompilerMessagesFilename: string;
    fOldMaxRecentOpenFiles: integer;
    fOldMaxRecentProjectFiles: integer;
    fOldOpenLastProjectAtStart: boolean;
    fOldShowCompileDialog: boolean;
    fOldAutoCloseCompileDialog: boolean;
    function CheckLazarusDir(Buttons: TMsgDlgButtons): boolean;
    function CheckCompiler(Buttons: TMsgDlgButtons): boolean;
    function CheckFPCSourceDir(Buttons: TMsgDlgButtons): boolean;
    function CheckTestDir: boolean;
    function CheckMake: boolean;
  public
    function Check: Boolean; override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    procedure RestoreSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{$R *.lfm}

{ TFilesOptionsFrame }

procedure TFilesOptionsFrame.FilesButtonClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  AFilename: string;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Options:=OpenDialog.Options+[ofPathMustExist];
    // set title
    if Sender=CompilerPathButton then
      OpenDialog.Title:=
                      Format(lisChooseCompilerPath,[GetDefaultCompilerFilename])
    else if Sender=MakePathButton then
      OpenDialog.Title:=lisChooseMakePath
    else
      exit;

    if OpenDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(OpenDialog.Filename);

      if Sender=CompilerPathButton then begin
        // check compiler filename
        SetComboBoxText(CompilerPathComboBox,AFilename,cstFilename);
        CheckCompiler([mbOk]);
      end else if Sender=MakePathButton then begin
        // check make filename
        SetComboBoxText(MakePathComboBox,AFilename,cstFilename);
        CheckMake;
      end;
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TFilesOptionsFrame.CompilerMessagesButtonClick(Sender:TObject);
var
  OpenDialog: TOpenDialog;
  AFilename: string;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Options:=OpenDialog.Options+[ofPathMustExist];
    OpenDialog.Title:=lisChooseCompilerMessages;
    OpenDialog.Filter:=lisFPCMessageFile+' (*.msg)|*.msg|'+dlgAllFiles+'|'+
      GetAllFilesMask;
    if OpenDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(OpenDialog.Filename);
      SetComboBoxText(CompilerMessagesComboBox,AFilename,cstFilename);
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TFilesOptionsFrame.DirectoriesButtonClick(Sender: TObject);
var
  OpenDialog: TSelectDirectoryDialog;
  ADirectoryName: string;
begin
  OpenDialog:=TSelectDirectoryDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Options:=OpenDialog.Options+[ofPathMustExist];
    // set title
    if Sender=LazarusDirButton then
      OpenDialog.Title:=lisChooseLazarusSourceDirectory
    else if Sender=FPCSourceDirButton then
      OpenDialog.Title:=lisChooseFPCSourceDir
    else if Sender=TestBuildDirButton then
      OpenDialog.Title:=lisChooseTestBuildDir
    else
      exit;

    if OpenDialog.Execute then begin
      ADirectoryName:=CleanAndExpandDirectory(OpenDialog.Filename);

      if Sender=LazarusDirButton then begin
        // check lazarus directory
        SetComboBoxText(LazarusDirComboBox,ADirectoryName,cstFilename);
        CheckLazarusDir([mbOk]);
      end else if Sender=FPCSourceDirButton then begin
        // check fpc source directory
        SetComboBoxText(FPCSourceDirComboBox,ADirectoryName,cstFilename);
        CheckFPCSourceDir([mbOK]);
      end else if Sender=TestBuildDirButton then begin
        // check test directory
        SetComboBoxText(TestBuildDirComboBox,ADirectoryName,cstFilename);
        CheckTestDir;
      end;

    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TFilesOptionsFrame.ShowCompileDialogCheckBoxChange(Sender: TObject);
begin
  AutoCloseCompileDialogCheckBox.Enabled := ShowCompileDialogCheckBox.Checked;
end;

procedure TFilesOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  MaxRecentOpenFilesLabel.Caption:=dlgMaxRecentFiles;
  MaxRecentProjectFilesLabel.Caption:=dlgMaxRecentProjs;
  OpenLastProjectAtStartCheckBox.Caption:=dlgQOpenLastPrj;
  ShowCompileDialogCheckBox.Caption:=dlgQShowCompileDialog;
  AutoCloseCompileDialogCheckBox.Caption:=dlgQAutoCloseCompileDialog;
  LazarusDirLabel.Caption:=dlgLazarusDir;

  with LazarusDirComboBox.Items do
  begin
    BeginUpdate;
    Add(ProgramDirectory(true));
    EndUpdate;
  end;

  CompilerPathLabel.Caption:=Format(dlgFpcPath,[GetDefaultCompilerFilename]);
  FPCSourceDirLabel.Caption:=dlgFpcSrcPath;
  MakePathLabel.Caption:=dlgMakePath;

  with MakePathComboBox.Items do
  begin
    BeginUpdate;
    Add('make');
    Add('gmake');
    EndUpdate;
  end;

  TestBuildDirLabel.Caption:=dlgTestPrjDir;

  with TestBuildDirComboBox.Items do
  begin
    BeginUpdate;
    Add('/tmp');
    Add('/var/tmp');
    Add('c:/tmp');
    Add('c:/windows/temp');
    EndUpdate;
  end;
  CompilerMessagesLabel.Caption:=dlgCompilerMessages;
end;

function TFilesOptionsFrame.GetTitle: String;
begin
  Result := dlgEnvFiles;
end;

function TFilesOptionsFrame.Check: Boolean;
begin
  Result := False;
  with EnvironmentOptions do
  begin
    LazarusDirectory:=LazarusDirComboBox.Text;
    CompilerFilename:=CompilerPathComboBox.Text;
    FPCSourceDirectory:=FPCSourceDirComboBox.Text;
    MakeFilename:=MakePathComboBox.Text;
    TestBuildDirectory:=TestBuildDirComboBox.Text;
    CompilerMessagesFilename:=CompilerMessagesComboBox.Text;
  end;
  // check lazarus directory
  if not CheckLazarusDir([mbIgnore,mbCancel]) then exit;
  // check compiler filename
  if not CheckCompiler([mbIgnore,mbCancel]) then exit;
  // check fpc source directory
  if not CheckFPCSourceDir([mbIgnore,mbCancel]) then exit;
  // check make filename
  if not CheckMake then exit;
  // check test directory
  if not CheckTestDir then exit;
  Result := True;
end;

procedure TFilesOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEnvironmentOptions do
  begin
    // Lazarus dir
    FOldLazarusDir:=LazarusDirectory;
    FOldRealLazarusDir:=GetParsedLazarusDirectory;
    LazarusDirComboBox.Items.Assign(LazarusDirHistory);
    SetComboBoxText(LazarusDirComboBox,LazarusDirectory,cstFilename,MaxComboBoxCount);
    with CompilerPathComboBox do
    begin
      Items.BeginUpdate;
      Items.Assign(CompilerFileHistory);
      AddFilenameToList(Items,FindDefaultCompilerPath);
      AddFilenameToList(Items,FindDefaultExecutablePath('fpc'+GetExecutableExt));
      Items.EndUpdate;
    end;

    // compiler filename
    FOldCompilerFilename:=CompilerFilename;
    FOldRealCompilerFilename:=GetParsedCompilerFilename;
    SetComboBoxText(CompilerPathComboBox,CompilerFilename,cstFilename,MaxComboBoxCount);

    // FPC src dir
    FOldFPCSourceDir:=FPCSourceDirectory;
    FOldRealFPCSourceDir:=GetParsedFPCSourceDirectory;
    FPCSourceDirComboBox.Items.Assign(FPCSourceDirHistory);
    SetComboBoxText(FPCSourceDirComboBox,FPCSourceDirectory,cstFilename,MaxComboBoxCount);

    // "make"
    FOldMakeFilename:=MakeFilename;
    FOldRealMakeFilename:=GetParsedMakeFilename;
    MakePathComboBox.Items.Assign(MakeFileHistory);
    SetComboBoxText(MakePathComboBox,MakeFilename,cstFilename,MaxComboBoxCount);

    // test build dir
    FOldTestDir:=TestBuildDirectory;
    FOldRealTestDir:=GetParsedTestBuildDirectory;
    TestBuildDirComboBox.Items.Assign(TestBuildDirHistory);
    SetComboBoxText(TestBuildDirComboBox,TestBuildDirectory,cstFilename,MaxComboBoxCount);

    // compiler messages file
    fOldCompilerMessagesFilename:=CompilerMessagesFilename;
    fOldRealCompilerMessagesFilename:=GetParsedCompilerMessagesFilename;
    CompilerMessagesComboBox.Items.Assign(CompilerMessagesFileHistory);
    SetComboBoxText(CompilerMessagesComboBox,CompilerMessagesFilename,cstFilename,MaxComboBoxCount);

    // recent files and directories
    fOldMaxRecentOpenFiles:=MaxRecentOpenFiles;
    SetComboBoxText(MaxRecentOpenFilesComboBox,IntToStr(MaxRecentOpenFiles),cstCaseInsensitive);
    fOldMaxRecentProjectFiles:=MaxRecentProjectFiles;
    SetComboBoxText(MaxRecentProjectFilesComboBox,IntToStr(MaxRecentProjectFiles),cstCaseInsensitive);
    fOldOpenLastProjectAtStart:=OpenLastProjectAtStart;

    // open last project at start
    OpenLastProjectAtStartCheckBox.Checked:=OpenLastProjectAtStart;

    // compile dialog
    fOldShowCompileDialog:=ShowCompileDialog;
    ShowCompileDialogCheckBox.Checked:=ShowCompileDialog;
    fOldAutoCloseCompileDialog:=AutoCloseCompileDialog;
    AutoCloseCompileDialogCheckBox.Checked:=AutoCloseCompileDialog;
    AutoCloseCompileDialogCheckBox.Enabled:=ShowCompileDialogCheckBox.Checked;
  end;
end;

procedure TFilesOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEnvironmentOptions do
  begin
    LazarusDirectory:=LazarusDirComboBox.Text;
    LazarusDirHistory.Assign(LazarusDirComboBox.Items);
    CompilerFilename:=CompilerPathComboBox.Text;
    CompilerFileHistory.Assign(CompilerPathComboBox.Items);
    FPCSourceDirectory:=FPCSourceDirComboBox.Text;
    FPCSourceDirHistory.Assign(FPCSourceDirComboBox.Items);
    MakeFilename:=MakePathComboBox.Text;
    MakeFileHistory.Assign(MakePathComboBox.Items);
    TestBuildDirHistory.Assign(TestBuildDirComboBox.Items);
    TestBuildDirectory:=TestBuildDirComboBox.Text;
    CompilerMessagesFileHistory.Assign(CompilerMessagesComboBox.Items);
    CompilerMessagesFilename:=CompilerMessagesComboBox.Text;

    // recent files and directories
    MaxRecentOpenFiles:=StrToIntDef(
        MaxRecentOpenFilesComboBox.Text,MaxRecentOpenFiles);
    MaxRecentProjectFiles:=StrToIntDef(
        MaxRecentProjectFilesComboBox.Text,MaxRecentProjectFiles);
    OpenLastProjectAtStart:=OpenLastProjectAtStartCheckBox.Checked;
    ShowCompileDialog := ShowCompileDialogCheckBox.Checked;
    AutoCloseCompileDialog := AutoCloseCompileDialogCheckBox.Checked;
  end;
end;

procedure TFilesOptionsFrame.RestoreSettings(AOptions: TAbstractIDEOptions);
begin
  inherited RestoreSettings(AOptions);
  with AOptions as TEnvironmentOptions do
  begin
    LazarusDirectory:=FOldLazarusDir;
    CompilerFilename:=FOldCompilerFilename;
    FPCSourceDirectory:=FOldFPCSourceDir;
    MakeFilename:=FOldMakeFilename;
    TestBuildDirectory:=FOldTestDir;
    CompilerMessagesFilename:=fOldCompilerMessagesFilename;

    // recent files and directories
    MaxRecentOpenFiles:=fOldMaxRecentOpenFiles;
    MaxRecentProjectFiles:=fOldMaxRecentProjectFiles;
    OpenLastProjectAtStart:=fOldOpenLastProjectAtStart;
    ShowCompileDialog := fOldShowCompileDialog;
    AutoCloseCompileDialog := fOldAutoCloseCompileDialog;
  end;
end;

function TFilesOptionsFrame.CheckLazarusDir(Buttons: TMsgDlgButtons): boolean;
var
  NewLazarusDir: string;
  Quality: TSDFilenameQuality;
  Note: string;
begin
  if EnvironmentOptions.LazarusDirectory=FOldLazarusDir then exit(true);
  Result := False;
  EnvironmentOptions.LazarusDirectory:=LazarusDirComboBox.Text;
  NewLazarusDir := EnvironmentOptions.GetParsedLazarusDirectory;
  Quality:=CheckLazarusDirectoryQuality(NewLazarusDir,Note);
  if Quality<>sddqCompatible then
  begin
    if IDEMessageDialog(lisCCOWarningCaption,
      Format(lisTheLazarusDirectoryDoesNotLookCorrect, [NewLazarusDir, #13, Note
        ]),
      mtWarning, Buttons)<>mrIgnore
    then
      exit;
  end;
  Result := true;
end;

function TFilesOptionsFrame.CheckFPCSourceDir(Buttons: TMsgDlgButtons): boolean;
var
  NewFPCSrcDir: string;
  Note: string;
  Quality: TSDFilenameQuality;
  CfgCache: TFPCTargetConfigCache;
  FPCVer: String;
begin
  if EnvironmentOptions.FPCSourceDirectory=FOldFPCSourceDir then exit(true);
  Result:=false;
  CfgCache:=CodeToolBoss.FPCDefinesCache.ConfigCaches.Find(
    EnvironmentOptions.GetParsedCompilerFilename,'','','',true);
  FPCVer:=CfgCache.GetFPCVer;
  EnvironmentOptions.FPCSourceDirectory:=FPCSourceDirComboBox.Text;
  NewFPCSrcDir:=EnvironmentOptions.GetParsedFPCSourceDirectory;
  Quality:=CheckFPCSrcDirQuality(NewFPCSrcDir,Note,FPCVer);
  if Quality<>sddqCompatible then
  begin
    if IDEMessageDialog(lisCCOWarningCaption,
      Format(lisTheFPCSourceDirectoryDoesNotLookCorrect, [NewFPCSrcDir, #13,
        Note]),
      mtWarning, Buttons)<>mrIgnore
    then
      exit;
  end;
  Result:=true;
end;

function TFilesOptionsFrame.CheckCompiler(Buttons: TMsgDlgButtons): boolean;
var
  NewCompilerFilename: String;
  Note: string;
  Quality: TSDFilenameQuality;
begin
  if EnvironmentOptions.CompilerFilename=FOldCompilerFilename then exit(true);
  Result:=false;
  EnvironmentOptions.CompilerFilename:=CompilerPathComboBox.Text;
  NewCompilerFilename:=EnvironmentOptions.GetParsedCompilerFilename;
  Quality:=CheckCompilerQuality(NewCompilerFilename,Note,
                                CodeToolBoss.FPCDefinesCache.TestFilename);
  if Quality<>sddqCompatible then
  begin
    if IDEMessageDialog(lisCCOWarningCaption,
      Format(lisTheCompilerFileDoesNotLookCorrect, [NewCompilerFilename, #13,
        Note]),
      mtWarning, Buttons)<>mrIgnore
    then
      exit;
  end;
  Result:=true;
end;

function TFilesOptionsFrame.CheckTestDir: boolean;
var
  NewTestDir: string;
  StopChecking: boolean;
begin
  if EnvironmentOptions.TestBuildDirectory=FOldTestDir then exit(true);
  EnvironmentOptions.TestBuildDirectory:=TestBuildDirComboBox.Text;
  NewTestDir:=EnvironmentOptions.GetParsedTestBuildDirectory;
  Result:=SimpleDirectoryCheck(FOldRealTestDir,NewTestDir,
                               lisEnvOptDlgTestDirNotFoundMsg,StopChecking);
end;

function TFilesOptionsFrame.CheckMake: boolean;
var
  NewMakeFilename: String;
begin
  if EnvironmentOptions.MakeFilename=FOldMakeFilename then exit(true);
  EnvironmentOptions.MakeFilename:=MakePathComboBox.Text;
  NewMakeFilename:=EnvironmentOptions.GetParsedMakeFilename;
  Result:=CheckExecutable(FOldRealMakeFilename,NewMakeFilename,
    lisCCOWarningCaption, Format(lisThePathOfMakeIsNotCorrect, [NewMakeFilename]));
end;

class function TFilesOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEnvironmentOptions;
end;

initialization
  RegisterIDEOptionsEditor(GroupEnvironment, TFilesOptionsFrame, EnvOptionsFiles);
end.
