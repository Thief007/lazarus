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
    Defines the TBuildLazarusOptions which stores the settings for the
    "Build Lazarus" function of the IDE.
    TConfigureBuildLazarusDlg is used to edit TBuildLazarusOptions.
    
    The BuildLazarus function will build the lazarus parts.
}
unit BuildLazDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Buttons, LResources,
  Laz_XMLCfg, LazarusIDEStrConsts, ExtToolDialog, ExtToolEditDlg,
  TransferMacros, LazConf, FileCtrl, IDEProcs;

type
  TMakeMode = (
    mmNone,
    mmBuild,
    mmCleanBuild
    );
  TMakeModes = set of TMakeMode;
    
  TLCLPlatform = (
    lpGtk,
    lpGtk2,
    lpGnome,
    lpWin32
    );
  TLCLPlatforms = set of TLCLPlatform;
  
  TBuildLazarusOptions = class
  private
    fBuildJITForm: TMakeMode;
    fBuildLCL: TMakeMode;
    fBuildComponents: TMakeMode;
    fBuildSynEdit: TMakeMode;
    fBuildCodeTools: TMakeMode;
    fBuildIDE: TMakeMode;
    fBuildExamples: TMakeMode;
    fCleanAll: boolean;
    fMakeFilename: string;
    fExtraOptions: string;
    FTargetDirectory: string;
    fTargetOS: string;
    fLCLPlatform: TLCLPlatform;
    fStaticAutoInstallPackages: TStringList;
    procedure SetTargetDirectory(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(XMLConfig: TXMLConfig; const Path: string);
    procedure Save(XMLConfig: TXMLConfig; const Path: string);
    property BuildLCL: TMakeMode read fBuildLCL write fBuildLCL;
    property BuildComponents: TMakeMode
      read fBuildComponents write fBuildComponents;
    property BuildSynEdit: TMakeMode read fBuildSynEdit write fBuildSynEdit;
    property BuildCodeTools: TMakeMode read fBuildCodeTools write fBuildCodeTools;
    property BuildJITForm: TMakeMode read fBuildJITForm write fBuildJITForm;
    property BuildIDE: TMakeMode read fBuildIDE write fBuildIDE;
    property BuildExamples: TMakeMode read fBuildExamples write fBuildExamples;
    property CleanAll: boolean read fCleanAll write fCleanAll;
    property MakeFilename: string read fMakeFilename write fMakeFilename;
    property ExtraOptions: string read fExtraOptions write fExtraOptions;
    property TargetOS: string read fTargetOS write fTargetOS;
    property LCLPlatform: TLCLPlatform read fLCLPlatform write fLCLPlatform;
    property StaticAutoInstallPackages: TStringList read fStaticAutoInstallPackages;
    property TargetDirectory: string read FTargetDirectory write SetTargetDirectory;
  end;

  TConfigureBuildLazarusDlg = class(TForm)
    CleanAllCheckBox: TCheckBox;
    BuildAllButton: TButton;
    BuildLCLRadioGroup: TRadioGroup;
    BuildComponentsRadioGroup: TRadioGroup;
    BuildSynEditRadioGroup: TRadioGroup;
    BuildCodeToolsRadioGroup: TRadioGroup;
    BuildIDERadioGroup: TRadioGroup;
    BuildExamplesRadioGroup: TRadioGroup;
    BuildJITFormCheckBox: TCheckBox;
    OptionsLabel: TLabel;
    OptionsEdit: TEdit;
    LCLInterfaceRadioGroup: TRadioGroup;
    TargetOSLabel: TLabel;
    TargetOSEdit: TEdit;
    OkButton: TButton;
    CancelButton: TButton;
    procedure BuildAllButtonClick(Sender: TObject);
    procedure ConfigureBuildLazarusDlgKeyDown(Sender: TObject; var Key: Word;
          Shift: TShiftState);
    procedure ConfigureBuildLazarusDlgResize(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    function MakeModeToInt(MakeMode: TMakeMode): integer;
    function IntToMakeMode(i: integer): TMakeMode;
  public
    procedure Load(Options: TBuildLazarusOptions);
    procedure Save(Options: TBuildLazarusOptions);
    constructor Create(AnOwner: TComponent); override;
  end;

function ShowConfigureBuildLazarusDlg(
  Options: TBuildLazarusOptions): TModalResult;

function BuildLazarus(Options: TBuildLazarusOptions;
  ExternalTools: TExternalToolList; Macros: TTransferMacroList;
  const PackageOptions: string): TModalResult;

implementation


uses
  LCLType;

const
  MakeModeNames: array[TMakeMode] of string = (
      'None', 'Build', 'Clean+Build'
    );
  LCLPlatformNames: array[TLCLPlatform] of string = (
      'gtk', 'gtk2', 'gnome', 'win32'
    );
    
  DefaultTargetDirectory = '$(ConfDir)/bin';

function GetTranslatedMakeModes(MakeMode: TMakeMode): string;
begin
  case MakeMode of
  mmNone: Result:=lisLazBuildNone;
  mmBuild: Result:=lisLazBuildBuild;
  mmCleanBuild: Result:=lisLazBuildCleanBuild;
  else
    Result:='???';
  end;
end;

function StrToMakeMode(const s: string): TMakeMode;
begin
  for Result:=Succ(mmNone) to High(TMakeMode) do
    if AnsiCompareText(s,MakeModeNames[Result])=0 then exit;
  Result:=mmNone;
end;

function StrToLCLPlatform(const s: string): TLCLPlatform;
begin
  for Result:=Low(TLCLPlatform) to High(TLCLPlatform) do
    if AnsiCompareText(s,LCLPlatformNames[Result])=0 then exit;
  Result:=lpGtk;
end;

function ShowConfigureBuildLazarusDlg(
  Options: TBuildLazarusOptions): TModalResult;
var ConfigBuildLazDlg: TConfigureBuildLazarusDlg;
begin
  Result:=mrCancel;
  ConfigBuildLazDlg:=TConfigureBuildLazarusDlg.Create(Application);
  try
    ConfigBuildLazDlg.Load(Options);
    Result:=ConfigBuildLazDlg.ShowModal;
    if Result=mrOk then
      ConfigBuildLazDlg.Save(Options);
  finally
    ConfigBuildLazDlg.Free;
  end;
  Result:=mrOk;
end;

function BuildLazarus(Options: TBuildLazarusOptions;
  ExternalTools: TExternalToolList; Macros: TTransferMacroList;
  const PackageOptions: string): TModalResult;
var
  Tool: TExternalToolOptions;
  IDEOptions: String;
  
  procedure SetMakeParams(MakeMode: TMakeMode;
    const ExtraOpts, TargetOS: string);
  begin
    if MakeMode=mmBuild then
      Tool.CmdLineParams:='all'
    else
      Tool.CmdLineParams:='clean all';
    if TargetOS<>'' then
      Tool.CmdLineParams:= 'OS_TARGET='+ TargetOS+' '+Tool.CmdLineParams;
    if ExtraOpts<>'' then
      Tool.CmdLineParams:='OPT='''+ExtraOpts+''' '+Tool.CmdLineParams;
  end;
  
  function CreateJITFormOptions: string;
  var
    p, StartPos: integer;
  begin
    Result:=Options.ExtraOptions;
    // delete profiler option
    p:=Pos('-pg',Result);
    if (p>0)
    and ((p+3>length(Result)) or (Result[p+3]=' ')) // option end
    and ((p=1) or (Result[p-1]=' ')) then begin
      // profiler option found
      StartPos:=p;
      while (StartPos>1) and (Result[StartPos-1]=' ') do
        dec(StartPos);
      System.Delete(Result,StartPos,p-StartPos+3);
    end;
  end;
  
  function DoBuildJITForm: TModalResult;
  begin
    // build IDE jitform
    Tool.Title:=lisBuildJITForm;
    Tool.WorkingDirectory:='$(LazarusDir)/designer/jitform';
    SetMakeParams(Options.BuildJITForm,CreateJITFormOptions,
                  Options.TargetOS);
    Result:=ExternalTools.Run(Tool,Macros);
    if Result<>mrOk then exit;
  end;
  
  function DoBuildPackager: TModalResult;
  begin
    // build packager interface
    Tool.Title:=lisBuildJITForm;
    Tool.WorkingDirectory:='$(LazarusDir)/packager/registration';
    SetMakeParams(Options.BuildJITForm,Options.ExtraOptions,
                  Options.TargetOS);
    Result:=ExternalTools.Run(Tool,Macros);
    if Result<>mrOk then exit;
  end;
  
begin
  Result:=mrCancel;
  Tool:=TExternalToolOptions.Create;
  try
    Tool.Filename:=Options.MakeFilename;
    Tool.EnvironmentOverrides.Values['LCL_PLATFORM']:=
      LCLPlatformNames[Options.LCLPlatform];
    if not FileExists(Tool.Filename) then begin
      Tool.Filename:=FindDefaultMakePath;
      if not FileExists(Tool.Filename) then exit;
    end;
    Tool.ScanOutputForFPCMessages:=true;
    Tool.ScanOutputForMakeMessages:=true;
    if Options.CleanAll then begin
      // clean lazarus source directories
      Tool.Title:=lisCleanLazarusSource;
      Tool.WorkingDirectory:='$(LazarusDir)';
      Tool.CmdLineParams:='cleanall';
      Result:=ExternalTools.Run(Tool,Macros);
      if Result<>mrOk then exit;
    end;
    if Options.BuildLCL<>mmNone then begin
      // build lcl
      Tool.Title:=lisBuildLCL;
      Tool.WorkingDirectory:='$(LazarusDir)/lcl';
      SetMakeParams(Options.BuildLCL,Options.ExtraOptions,Options.TargetOS);
      Result:=ExternalTools.Run(Tool,Macros);
      if Result<>mrOk then exit;
    end;
    if Options.BuildComponents<>mmNone then begin
      // build components
      Tool.Title:=lisBuildComponent;
      Tool.WorkingDirectory:='$(LazarusDir)/components';
      SetMakeParams(Options.BuildComponents,Options.ExtraOptions,
                    Options.TargetOS);
      Result:=ExternalTools.Run(Tool,Macros);
      if Result<>mrOk then exit;
    end else begin
      if Options.BuildSynEdit<>mmNone then begin
        // build SynEdit
        Tool.Title:=lisBuildSynEdit;
        Tool.WorkingDirectory:='$(LazarusDir)/components/synedit';
        SetMakeParams(Options.BuildSynEdit,Options.ExtraOptions,
                      Options.TargetOS);
        Result:=ExternalTools.Run(Tool,Macros);
        if Result<>mrOk then exit;
      end;
      if Options.BuildCodeTools<>mmNone then begin
        // build CodeTools
        Tool.Title:='Build CodeTools';
        Tool.WorkingDirectory:='$(LazarusDir)/components/codetools';
        SetMakeParams(Options.BuildCodeTools,Options.ExtraOptions,
                      Options.TargetOS);
        Result:=ExternalTools.Run(Tool,Macros);
        if Result<>mrOk then exit;
      end;
    end;
    if Options.BuildJITForm<>mmNone then begin
      Result:=DoBuildJITForm;
      if Result<>mrOk then exit;
      Result:=DoBuildPackager;
      if Result<>mrOk then exit;
    end;
    if Options.BuildIDE<>mmNone then begin
      // build IDE
      Tool.Title:=lisBuildIDE;
      Tool.WorkingDirectory:='$(LazarusDir)';
      IDEOptions:=Options.ExtraOptions;
      if PackageOptions<>'' then begin
        if IDEOptions<>'' then IDEOptions:=IDEOptions+' ';
        IDEOptions:=IDEOptions+PackageOptions;
      end;
      if Options.ExtraOptions<>'' then
        Tool.CmdLineParams:='OPT='''+IDEOptions+''' '
      else
        Tool.CmdLineParams:='';
      if Options.TargetOS<>'' then
        Tool.CmdLineParams:= 'OS_TARGET='+Options.TargetOS+' '
                             +Tool.CmdLineParams;
      if Options.BuildIDE=mmBuild then
        Tool.CmdLineParams:='' + Tool.CmdLineParams+'ide'
      else
        Tool.CmdLineParams:='' + Tool.CmdLineParams+'cleanide ide';
      Result:=ExternalTools.Run(Tool,Macros);
      if Result<>mrOk then exit;
    end;
    if Options.BuildExamples<>mmNone then begin
      // build Examples
      Tool.Title:=lisBuildExamples;
      Tool.WorkingDirectory:='$(LazarusDir)/examples';
      SetMakeParams(Options.BuildComponents,Options.ExtraOptions,
                    Options.TargetOS);
      Result:=ExternalTools.Run(Tool,Macros);
      if Result<>mrOk then exit;
    end;
    Result:=mrOk;
  finally
    Tool.Free;
  end;
end;

{ TConfigureBuildLazarusDlg }

constructor TConfigureBuildLazarusDlg.Create(AnOwner: TComponent);
var
  MakeMode: TMakeMode;
  LCLInterface: TLCLPlatform;
begin
  inherited Create(AnOwner);
  if LazarusResources.Find(Classname)=nil then begin
    Width:=480;
    Height:=435;
    Position:=poScreenCenter;
    Caption:=Format(lisConfigureBuildLazarus, ['"', '"']);
    OnResize:=@ConfigureBuildLazarusDlgResize;
    OnKeyDown:=@ConfigureBuildLazarusDlgKeyDown;
    
    CleanAllCheckBox:=TCheckBox.Create(Self);
    with CleanAllCheckBox do begin
      Parent:=Self;
      Name:='CleanAllCheckBox';
      SetBounds(10,10,Self.ClientWidth-150,20);
      Caption:=lisLazBuildCleanAll;
      Visible:=true;
    end;
    
    BuildAllButton:=TButton.Create(Self);
    with BuildAllButton do begin
      Name:='BuildAllButton';
      Parent:=Self;
      Left:=CleanAllCheckBox.Left;
      Top:=CleanAllCheckBox.Top+CleanAllCheckBox.Height+5;
      Width:=200;
      Caption:=Format(lisLazBuildSetToBuildAll, ['"', '"']);
      OnClick:=@BuildAllButtonClick;
      Visible:=true;
    end;
    
    BuildLCLRadioGroup:=TRadioGroup.Create(Self);
    with BuildLCLRadioGroup do begin
      Parent:=Self;
      Name:='BuildLCLRadioGroup';
      SetBounds(10,BuildAllButton.Top+BuildAllButton.Height+5,
                CleanAllCheckBox.Width,40);
      Caption:='Build LCL';
      for MakeMode:=Low(TMakeMode) to High(TMakeMode) do
        Items.Add(GetTranslatedMakeModes(MakeMode));
      Columns:=3;
      Visible:=true;
    end;

    BuildComponentsRadioGroup:=TRadioGroup.Create(Self);
    with BuildComponentsRadioGroup do begin
      Parent:=Self;
      Name:='BuildComponentsRadioGroup';
      SetBounds(10,BuildLCLRadioGroup.Top+BuildLCLRadioGroup.Height+5,
                BuildLCLRadioGroup.Width,BuildLCLRadioGroup.Height);
      Caption:=lisLazBuildBuildComponentsSynEditCodeTools;
      for MakeMode:=Low(TMakeMode) to High(TMakeMode) do
        Items.Add(GetTranslatedMakeModes(MakeMode));
      Columns:=3;
      Visible:=true;
    end;

    BuildSynEditRadioGroup:=TRadioGroup.Create(Self);
    with BuildSynEditRadioGroup do begin
      Parent:=Self;
      Name:='BuildSynEditRadioGroup';
      SetBounds(10,
                BuildComponentsRadioGroup.Top+BuildComponentsRadioGroup.Height+5,
                BuildComponentsRadioGroup.Width,
                BuildLCLRadioGroup.Height);
      Caption:=lisLazBuildBuildSynEdit;
      for MakeMode:=Low(TMakeMode) to High(TMakeMode) do
        Items.Add(GetTranslatedMakeModes(MakeMode));
      Columns:=3;
      Visible:=true;
    end;

    BuildCodeToolsRadioGroup:=TRadioGroup.Create(Self);
    with BuildCodeToolsRadioGroup do begin
      Parent:=Self;
      Name:='BuildCodeToolsRadioGroup';
      SetBounds(10,BuildSynEditRadioGroup.Top+BuildSynEditRadioGroup.Height+5,
                BuildLCLRadioGroup.Width,BuildLCLRadioGroup.Height);
      Caption:=lisLazBuildBuildCodeTools;
      for MakeMode:=Low(TMakeMode) to High(TMakeMode) do
        Items.Add(GetTranslatedMakeModes(MakeMode));
      Columns:=3;
      Visible:=true;
    end;

    BuildIDERadioGroup:=TRadioGroup.Create(Self);
    with BuildIDERadioGroup do begin
      Parent:=Self;
      Name:='BuildIDERadioGroup';
      SetBounds(10,BuildCodeToolsRadioGroup.Top+BuildCodeToolsRadioGroup.Height+5,
                BuildLCLRadioGroup.Width,BuildLCLRadioGroup.Height);
      Caption:=lisLazBuildBuildIDE;
      for MakeMode:=Low(TMakeMode) to High(TMakeMode) do
        Items.Add(GetTranslatedMakeModes(MakeMode));
      Columns:=3;
      Visible:=true;
    end;

    BuildExamplesRadioGroup:=TRadioGroup.Create(Self);
    with BuildExamplesRadioGroup do begin
      Parent:=Self;
      Name:='BuildExamplesRadioGroup';
      SetBounds(10,BuildIDERadioGroup.Top+BuildIDERadioGroup.Height+5,
                BuildLCLRadioGroup.Width,BuildLCLRadioGroup.Height);
      Caption:=lisLazBuildBuildExamples;
      for MakeMode:=Low(TMakeMode) to High(TMakeMode) do
        Items.Add(GetTranslatedMakeModes(MakeMode));
      Columns:=3;
      Visible:=true;
    end;
    
    OptionsLabel:=TLabel.Create(Self);
    with OptionsLabel do begin
      Name:='OptionsLabel';
      Parent:=Self;
      SetBounds(10,
                BuildExamplesRadioGroup.Top+BuildExamplesRadioGroup.Height+5,
                80,Height);
      Caption:=lisLazBuildOptions;
      Visible:=true;
    end;
    
    OptionsEdit:=TEdit.Create(Self);
    with OptionsEdit do begin
      Name:='OptionsEdit';
      Parent:=Self;
      SetBounds(OptionsLabel.Left+OptionsLabel.Width+5,
                OptionsLabel.Top,
                BuildExamplesRadioGroup.Width-OptionsLabel.Width-5,
                Height);
      Visible:=true;
    end;

    TargetOSLabel:=TLabel.Create(Self);
    with TargetOSLabel do begin
      Name:='TargetOSLabel';
      Parent:=Self;
      SetBounds(10,OptionsLabel.Top+OptionsLabel.Height+12,
                80,Height);
      Caption:=lisLazBuildTargetOS;
      Visible:=true;
    end;

    TargetOSEdit:=TEdit.Create(Self);
    with TargetOSEdit do begin
      Name:='TargetOSEdit';
      Parent:=Self;
      SetBounds(TargetOSLabel.Left+TargetOSLabel.Width+5,
                TargetOSLabel.Top,
                OptionsEdit.Width,
                Height);
      Visible:=true;
    end;

    LCLInterfaceRadioGroup:=TRadioGroup.Create(Self);
    with LCLInterfaceRadioGroup do begin
      Name:='LCLInterfaceRadioGroup';
      Parent:=Self;
      Left:=BuildLCLRadioGroup.Left+BuildLCLRadioGroup.Width+10;
      Top:=BuildLCLRadioGroup.Top;
      Width:=Parent.ClientHeight-Left-BuildLCLRadioGroup.Left;
      Height:=120;
      Caption:=lisLazBuildLCLInterface;
      for LCLInterface:=Low(TLCLPlatform) to High(TLCLPlatform) do begin
        Items.Add(LCLPlatformNames[LCLInterface]);
      end;
      Visible:=true;
    end;
    
    BuildJITFormCheckBox:=TCheckBox.Create(Self);
    with BuildJITFormCheckBox do begin
      Name:='BuildJITFormCheckBox';
      Parent:=Self;
      SetBounds(LCLInterfaceRadioGroup.Left,
           LCLInterfaceRadioGroup.Top+LCLInterfaceRadioGroup.Height+50,
           LCLInterfaceRadioGroup.Width,Height);
      Caption:=lisLazBuildBuildJITForm;
      Visible:=true;
    end;

    OkButton:=TButton.Create(Self);
    with OkButton do begin
      Parent:=Self;
      Name:='OkButton';
      SetBounds(Self.ClientWidth-180,Self.ClientHeight-38,80,25);
      Caption:=lisLazBuildOk;
      OnClick:=@OkButtonClick;
      Visible:=true;
    end;

    CancelButton:=TButton.Create(Self);
    with CancelButton do begin
      Parent:=Self;
      Name:='CancelButton';
      SetBounds(Self.ClientWidth-90,OkButton.Top,OkButton.Width,OkButton.Height);
      Caption:=lisLazBuildCancel;
      OnClick:=@CancelButtonClick;
      Visible:=true;
    end;

  end;
  ConfigureBuildLazarusDlgResize(nil);
end;

procedure TConfigureBuildLazarusDlg.BuildAllButtonClick(Sender: TObject);
begin
  CleanAllCheckBox.Checked:=true;
  BuildLCLRadioGroup.ItemIndex:=1;
  BuildComponentsRadioGroup.ItemIndex:=1;
  BuildSynEditRadioGroup.ItemIndex:=0;
  BuildCodeToolsRadioGroup.ItemIndex:=0;
  BuildIDERadioGroup.ItemIndex:=1;
  BuildJITFormCheckBox.Checked:=true;
  BuildExamplesRadioGroup.ItemIndex:=1;
  OptionsEdit.Text:='';
end;

procedure TConfigureBuildLazarusDlg.ConfigureBuildLazarusDlgKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_Escape then
    ModalResult:=mrCancel;
end;

procedure TConfigureBuildLazarusDlg.ConfigureBuildLazarusDlgResize(
  Sender: TObject);
begin
  CleanAllCheckBox.SetBounds(10,10,Self.ClientWidth-150,20);
  BuildAllButton.SetBounds(CleanAllCheckBox.Left,
                           CleanAllCheckBox.Top+CleanAllCheckBox.Height+5,
                           200,BuildAllButton.Height);
  BuildLCLRadioGroup.SetBounds(10,
              BuildAllButton.Top+BuildAllButton.Height+5,
              CleanAllCheckBox.Width,40);
  BuildComponentsRadioGroup.SetBounds(10,
              BuildLCLRadioGroup.Top+BuildLCLRadioGroup.Height+5,
              BuildLCLRadioGroup.Width,BuildLCLRadioGroup.Height);
  BuildSynEditRadioGroup.SetBounds(10,
              BuildComponentsRadioGroup.Top+BuildComponentsRadioGroup.Height+5,
              BuildComponentsRadioGroup.Width,BuildComponentsRadioGroup.Height);
  BuildCodeToolsRadioGroup.SetBounds(10,
              BuildSynEditRadioGroup.Top+BuildSynEditRadioGroup.Height+5,
              BuildLCLRadioGroup.Width,BuildLCLRadioGroup.Height);
  BuildIDERadioGroup.SetBounds(10,
              BuildCodeToolsRadioGroup.Top+BuildCodeToolsRadioGroup.Height+5,
              BuildLCLRadioGroup.Width,BuildLCLRadioGroup.Height);
  BuildExamplesRadioGroup.SetBounds(10,
              BuildIDERadioGroup.Top+BuildIDERadioGroup.Height+5,
              BuildLCLRadioGroup.Width,BuildLCLRadioGroup.Height);
  OptionsLabel.SetBounds(10,
            BuildExamplesRadioGroup.Top+BuildExamplesRadioGroup.Height+5,
            80,OptionsLabel.Height);
  OptionsEdit.SetBounds(OptionsLabel.Left+OptionsLabel.Width+5,
            OptionsLabel.Top,
            BuildExamplesRadioGroup.Width-OptionsLabel.Width-5,
            OptionsEdit.Height);
  TargetOSLabel.SetBounds(10,
                OptionsLabel.Top+OptionsLabel.Height+12,
                80,TargetOsLabel.Height);
  TargetOSEdit.SetBounds(TargetOSLabel.Left+TargetOSLabel.Width+5,
                TargetOSLabel.Top,
                OptionsEdit.Width,
                TargetOSEdit.Height);
  with LCLInterfaceRadioGroup do begin
    Left:=BuildLCLRadioGroup.Left+BuildLCLRadioGroup.Width+10;
    Top:=BuildLCLRadioGroup.Top;
    Width:=Parent.ClientWidth-Left-10;
  end;
  with BuildJITFormCheckBox do
    BuildJITFormCheckBox.SetBounds(LCLInterfaceRadioGroup.Left,
           LCLInterfaceRadioGroup.Top+LCLInterfaceRadioGroup.Height+50,
           LCLInterfaceRadioGroup.Width,Height);

  OkButton.SetBounds(Self.ClientWidth-180,Self.ClientHeight-38,80,25);
  CancelButton.SetBounds(Self.ClientWidth-90,OkButton.Top,
              OkButton.Width,OkButton.Height);
end;

procedure TConfigureBuildLazarusDlg.OkButtonClick(Sender: TObject);
begin
  ModalResult:=mrOk;
end;

procedure TConfigureBuildLazarusDlg.CancelButtonClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TConfigureBuildLazarusDlg.Load(Options: TBuildLazarusOptions);
begin
  CleanAllCheckBox.Checked:=Options.CleanAll;
  BuildLCLRadioGroup.ItemIndex:=MakeModeToInt(Options.BuildLCL);
  BuildComponentsRadioGroup.ItemIndex:=MakeModeToInt(Options.BuildComponents);
  BuildSynEditRadioGroup.ItemIndex:=MakeModeToInt(Options.BuildSynEdit);
  BuildCodeToolsRadioGroup.ItemIndex:=MakeModeToInt(Options.BuildCodeTools);
  BuildIDERadioGroup.ItemIndex:=MakeModeToInt(Options.BuildIDE);
  BuildExamplesRadioGroup.ItemIndex:=MakeModeToInt(Options.BuildExamples);
  OptionsEdit.Text:=Options.ExtraOptions;
  LCLInterfaceRadioGroup.ItemIndex:=ord(Options.LCLPlatform);
  BuildJITFormCheckBox.Checked:=Options.BuildJITForm in [mmBuild, mmCleanBuild];
  TargetOSEdit.Text:=Options.TargetOS;
end;

procedure TConfigureBuildLazarusDlg.Save(Options: TBuildLazarusOptions);
begin
  if Options=nil then exit;
  Options.CleanAll:=CleanAllCheckBox.Checked;
  Options.BuildLCL:=IntToMakeMode(BuildLCLRadioGroup.ItemIndex);
  Options.BuildComponents:=IntToMakeMode(BuildComponentsRadioGroup.ItemIndex);
  Options.BuildSynEdit:=IntToMakeMode(BuildSynEditRadioGroup.ItemIndex);
  Options.BuildCodeTools:=IntToMakeMode(BuildCodeToolsRadioGroup.ItemIndex);
  Options.BuildIDE:=IntToMakeMode(BuildIDERadioGroup.ItemIndex);
  Options.BuildExamples:=IntToMakeMode(BuildExamplesRadioGroup.ItemIndex);
  Options.ExtraOptions:=OptionsEdit.Text;
  Options.LCLPlatform:=TLCLPlatform(LCLInterfaceRadioGroup.ItemIndex);
  if BuildJITFormCheckBox.Checked then
    Options.BuildJITForm:=mmBuild
  else
    Options.BuildJITForm:=mmNone;
  Options.TargetOS:=TargetOSEdit.Text;
end;

function TConfigureBuildLazarusDlg.MakeModeToInt(MakeMode: TMakeMode): integer;
begin
  case MakeMode of
    mmBuild:      Result:=1;
    mmCleanBuild: Result:=2;
  else            Result:=0;
  end;
end;

function TConfigureBuildLazarusDlg.IntToMakeMode(i: integer): TMakeMode;
begin
  case i of
    1: Result:=mmBuild;
    2: Result:=mmCleanBuild;
  else Result:=mmNone;
  end;
end;

{ TBuildLazarusOptions }

procedure TBuildLazarusOptions.Save(XMLConfig: TXMLConfig; const Path: string);
begin
  XMLConfig.SetDeleteValue(Path+'BuildLCL/Value',
                           MakeModeNames[fBuildLCL],
                           MakeModeNames[mmBuild]);
  XMLConfig.SetDeleteValue(Path+'BuildComponents/Value',
                           MakeModeNames[fBuildComponents],
                           MakeModeNames[mmBuild]);
  XMLConfig.SetDeleteValue(Path+'BuildSynEdit/Value',
                           MakeModeNames[fBuildSynEdit],
                           MakeModeNames[mmNone]);
  XMLConfig.SetDeleteValue(Path+'BuildCodeTools/Value',
                           MakeModeNames[fBuildCodeTools],
                           MakeModeNames[mmNone]);
  XMLConfig.SetDeleteValue(Path+'BuildJITForm/Value',
                           MakeModeNames[fBuildJITForm],
                           MakeModeNames[mmBuild]);
  XMLConfig.SetDeleteValue(Path+'BuildIDE/Value',
                           MakeModeNames[fBuildIDE],
                           MakeModeNames[mmBuild]);
  XMLConfig.SetDeleteValue(Path+'BuildExamples/Value',
                           MakeModeNames[fBuildExamples],
                           MakeModeNames[mmBuild]);
  XMLConfig.SetDeleteValue(Path+'CleanAll/Value',fCleanAll,true);
  XMLConfig.SetDeleteValue(Path+'ExtraOptions/Value',fExtraOptions,'');
  XMLConfig.SetDeleteValue(Path+'TargetOS/Value',fTargetOS,'');
  XMLConfig.SetDeleteValue(Path+'MakeFilename/Value',fMakeFilename,'');
  XMLConfig.SetDeleteValue(Path+'LCLPlatform/Value',
                           LCLPlatformNames[fLCLPlatform],
                           LCLPlatformNames[lpGtk]);
  XMLConfig.SetDeleteValue(Path+'TargetDirectory/Value',
                           FTargetDirectory,DefaultTargetDirectory);
  // auto install packages
  SaveStringList(XMLConfig,fStaticAutoInstallPackages,
                 Path+'StaticAutoInstallPackages/');
end;

procedure TBuildLazarusOptions.Load(XMLConfig: TXMLConfig; const Path: string);
begin
  fBuildLCL:=StrToMakeMode(XMLConfig.GetValue(Path+'BuildLCL/Value',
                                              MakeModeNames[mmBuild]));
  fBuildComponents:=StrToMakeMode(XMLConfig.GetValue(Path+'BuildComponents/Value',
                                              MakeModeNames[mmBuild]));
  fBuildSynEdit:=StrToMakeMode(XMLConfig.GetValue(Path+'BuildSynEdit/Value',
                                    MakeModeNames[mmNone]));
  fBuildCodeTools:=StrToMakeMode(XMLConfig.GetValue(Path+'BuildCodeTools/Value',
                                      MakeModeNames[mmNone]));
  fBuildJITForm:=StrToMakeMode(XMLConfig.GetValue(Path+'BuildJITForm/Value',
                                              MakeModeNames[mmBuild]));
  fBuildIDE:=StrToMakeMode(XMLConfig.GetValue(Path+'BuildIDE/Value',
                                              MakeModeNames[mmBuild]));
  fBuildExamples:=StrToMakeMode(XMLConfig.GetValue(Path+'BuildExamples/Value',
                                                MakeModeNames[mmBuild]));
  fCleanAll:=XMLConfig.GetValue(Path+'CleanAll/Value',true);
  fExtraOptions:=XMLConfig.GetValue(Path+'ExtraOptions/Value','');
  fTargetOS:=XMLConfig.GetValue(Path+'TargetOS/Value','');
  fMakeFilename:=XMLConfig.GetValue(Path+'MakeFilename/Value','');
  fLCLPlatform:=StrToLCLPlatform(XMLConfig.GetValue(Path+'LCLPlatform/Value',
                                 LCLPlatformNames[lpGtk]));
  FTargetDirectory:=AppendPathDelim(SetDirSeparators(
                  XMLConfig.GetValue(Path+'TargetDirectory/Value',
                                     DefaultTargetDirectory)));

  // auto install packages
  LoadStringList(XMLConfig,fStaticAutoInstallPackages,
                 Path+'StaticAutoInstallPackages/');
end;

procedure TBuildLazarusOptions.SetTargetDirectory(const AValue: string);
begin
  if FTargetDirectory=AValue then exit;
  FTargetDirectory:=AValue;
end;

constructor TBuildLazarusOptions.Create;
begin
  inherited Create;
  fBuildJITForm:=mmBuild;
  fBuildLCL:=mmNone;
  fBuildComponents:=mmBuild;
  fBuildSynEdit:=mmNone;
  fBuildCodeTools:=mmNone;
  fBuildIDE:=mmBuild;
  fBuildExamples:=mmBuild;
  fCleanAll:=true;
  fMakeFilename:='';
  fExtraOptions:='';
  FTargetDirectory:=DefaultTargetDirectory;
  fTargetOS:='';
  fLCLPlatform:=lpGtk;

  // auto install packages
  fStaticAutoInstallPackages:=TStringList.Create;
end;

destructor TBuildLazarusOptions.Destroy;
begin
  fStaticAutoInstallPackages.Free;
  inherited Destroy;
end;


end.


