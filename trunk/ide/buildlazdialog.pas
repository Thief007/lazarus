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
  Converted to lfm by: Matthijs Willemstein
  Quickoptions added by: Giuliano Colla
  Then extensively modified by: Juha Manninen
   - added support for Build Profiles which extend the idea of Quick Options.
   - changed UI to be less weird and comply better with UI design norms.
   - changed object structure to keep it logical and to avoid duplicate data.

  Abstract:
    Defines settings for the "Build Lazarus" function of the IDE.
    TConfigureBuildLazarusDlg is used to edit the build options.

    The BuildLazarus function will build the lazarus parts.

    Building occurs only with options defined in the Detail Page.
    Profiles are just used to set options there. Therefore beginners can
    use default profiles and don't need to touch the Detail Page.
    Advanced users can define their own profiles for example for cross compiling.
}
unit BuildLazDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LConvEncoding, Forms, Controls, LCLType, LCLIntf,
  Graphics, GraphType, StdCtrls, ExtCtrls, Buttons, FileUtil, Dialogs, Types,
  InterfaceBase, Themes, ComCtrls,
  DefineTemplates, Laz_XMLCfg,
  LazarusIDEStrConsts, TransferMacros, LazConf, IDEProcs, DialogProcs,
  IDEMsgIntf, IDEContextHelpEdit, IDEImagesIntf, MainBar,
  InputHistory, ExtToolDialog, ExtToolEditDlg, EnvironmentOpts,
  {$IFDEF win32}
  CodeToolManager, // added for windres workaround
  {$ENDIF}
  ApplicationBundle, CompilerOptions, BuildProfileManager;

type

  TBuildLazarusFlag = (
    blfWithoutCompilingIDE, // skip compiling stage of IDE
    blfWithoutLinkingIDE,   // skip linking stage of IDE
    blfOnlyIDE,             // skip all but IDE
    blfDontClean,           // ignore clean up
    blfWithStaticPackages,  // build with IDE static design time packages
    blfUseMakeIDECfg        // use idemake.cfg
    );
  TBuildLazarusFlags = set of TBuildLazarusFlag;

  { TConfigureBuildLazarusDlg }

  TConfigureBuildLazarusDlg = class(TForm)
    CancelButton: TBitBtn;
    CBLDBtnPanel: TPanel;
    CleanAllCheckBox: TCheckBox;
    BuildProfileComboBox: TComboBox;
    CompileButton: TBitBtn;
    CompileAllButton: TBitBtn;
    ConfirmBuildCheckBox: TCheckBox;
    BuildWithAllCheckBox: TCheckBox;
    DetailsPanel: TPanel;
    HelpButton: TBitBtn;
    BuildProfileLabel: TLabel;
    MakeModeListBox: TListBox;
    MakeModeListHeader: THeaderControl;
    LCLInterfaceRadioGroup: TRadioGroup;
    OptionsEdit: TEdit;
    OptionsLabel: TLabel;
    DetailSettingPanel: TPanel;
    RestartAfterBuildCheckBox: TCheckBox;
    Panel2: TPanel;
    SaveSettingsButton: TBitBtn;
    TargetCPUComboBox: TComboBox;
    BuildProfileButton: TButton;
    TargetOSComboBox: TComboBox;
    TargetCPULabel: TLabel;
    TargetDirectoryButton: TButton;
    TargetDirectoryComboBox: TComboBox;
    TargetDirectoryLabel: TLabel;
    TargetOSLabel: TLabel;
    UpdateRevisionIncCheckBox: TCheckBox;
    WithStaticPackagesCheckBox: TCheckBox;
    procedure BuildProfileButtonClick(Sender: TObject);
    procedure BuildProfileComboBoxSelect(Sender: TObject);
    procedure CompileAllButtonClick(Sender: TObject);
    procedure CompileButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
    procedure MakeModeListHeaderResize(Sender: TObject);
    procedure MakeModeListHeaderSectionClick(HeaderControl: TCustomHeaderControl;
      Section: THeaderSection);
    procedure MakeModeListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure MakeModeListBoxMouseDown(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MakeModeListBoxShowHint(Sender: TObject; HintInfo: PHintInfo);
    procedure SaveSettingsButtonClick(Sender: TObject);
    procedure TargetDirectoryButtonClick(Sender: TObject);
  private
    // Data is copied by caller before and after opening this dialog.
    fProfiles: TBuildLazarusProfiles;
    fUpdatingProfileCombo: Boolean;
    function GetMakeModeAtX(const X: Integer; out MakeMode: TMakeMode): boolean;
    function MakeModeToInt(MakeMode: TMakeMode): integer;
    function IntToMakeMode(i: integer): TMakeMode;
    procedure PrepareClose;
  public
    constructor Create(TheOwner: TComponent); overload; reintroduce;
    destructor Destroy; override;
    procedure CopyMakeModeDefsToUI(AMakeModeDefs: TMakeModeDefs);
    procedure CopyProfileToUI(AProfile: TBuildLazarusProfile);
    procedure CopyUIToProfile(AProfile: TBuildLazarusProfile);
    procedure UpdateProfileNamesUI;
  public
    property  Profiles: TBuildLazarusProfiles read fProfiles;
  end;

function ShowConfigureBuildLazarusDlg(AProfiles: TBuildLazarusProfiles): TModalResult;

function BuildLazarus(Profiles: TBuildLazarusProfiles;
  ExternalTools: TExternalToolList; Macros: TTransferMacroList;
  const PackageOptions, CompilerPath, MakePath: string;
  Flags: TBuildLazarusFlags): TModalResult;

function CreateBuildLazarusOptions(Profiles: TBuildLazarusProfiles;
  ItemIndex: integer; Macros: TTransferMacroList;
  const PackageOptions: string; Flags: TBuildLazarusFlags;
  var ExtraOptions: string; out UpdateRevisionInc: boolean;
  out OutputDirRedirected: boolean): TModalResult;

function SaveIDEMakeOptions(Profiles: TBuildLazarusProfiles;
  Macros: TTransferMacroList;
  const PackageOptions: string; Flags: TBuildLazarusFlags): TModalResult;

function GetMakeIDEConfigFilename: string;

function GetTranslatedMakeModes(MakeMode: TMakeMode): string;


implementation

{$R *.lfm}

const
  DefaultIDEMakeOptionFilename = 'idemake.cfg';
  ButtonSize = 24;

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

function ShowConfigureBuildLazarusDlg(AProfiles: TBuildLazarusProfiles): TModalResult;
// mrOk=save
// mrYes=save and compile
// mrAll=save and compile all selected profiles
var
  ConfigBuildLazDlg: TConfigureBuildLazarusDlg;
begin
  Result := mrCancel;
  ConfigBuildLazDlg := TConfigureBuildLazarusDlg.Create(nil);
  try
    ConfigBuildLazDlg.Profiles.Assign(AProfiles); // Copy profiles to dialog.
    Result := ConfigBuildLazDlg.ShowModal;
    if Result in [mrOk,mrYes,mrAll] then begin
      AProfiles.Assign(ConfigBuildLazDlg.Profiles); // Copy profiles back from dialog.
    end;
  finally
    ConfigBuildLazDlg.Free;
  end;
end;

function BuildLazarus(Profiles: TBuildLazarusProfiles;
  ExternalTools: TExternalToolList; Macros: TTransferMacroList;
  const PackageOptions, CompilerPath, MakePath: string;
  Flags: TBuildLazarusFlags): TModalResult;

  function CheckDirectoryWritable(Dir: string): boolean;
  begin
    if DirectoryIsWritableCached(Dir) then exit(true);
    Result:=false;
    MessageDlg(lisBuildingLazarusFailed,
               Format(lisThisSetOfOptionsToBuildLazarusIsNotSupportedByThis,
                      [#13, '"', Dir, '"', #13]),
               mtError,[mbCancel],0);
  end;

var
  Tool: TExternalToolOptions;
  Options: TBuildLazarusProfile;
  i: Integer;
  MMDef: TMakeModeDef;
  ExtraOptions, LinkerAddition: String;
  CurMakeMode: TMakeMode;
  WorkingDirectory: String;
  OutputDirRedirected, UpdateRevisionInc: boolean;
begin
  Result:=mrCancel;

  if (blfOnlyIDE in Flags) and (blfWithoutLinkingIDE in Flags)
  and (blfWithoutCompilingIDE in Flags) then
    exit(mrOk); // only IDE, but skip both parts -> nothing to do

  Options:=Profiles.Current;
  Tool:=TExternalToolOptions.Create;
  try
    // setup external tool
    Tool.Filename:=MakePath;
    Tool.EnvironmentOverrides.Values['LCL_PLATFORM']:=
      LCLPlatformDirNames[Options.TargetPlatform];
    Tool.EnvironmentOverrides.Values['LANG']:= 'en_US';
    if CompilerPath<>'' then
      Tool.EnvironmentOverrides.Values['PP']:=CompilerPath;
    if (Tool.Filename<>'') and (not FileExistsUTF8(Tool.Filename)) then
      Tool.Filename:=FindDefaultExecutablePath(Tool.Filename);
    if (Tool.Filename='') or (not FileExistsUTF8(Tool.Filename)) then begin
      Tool.Filename:=FindDefaultMakePath;
      if (Tool.Filename='') or (not FileExistsUTF8(Tool.Filename)) then begin
        MessageDlg(lisMakeNotFound,
                   Format(lisTheProgramMakeWasNotFoundThisToolIsNeededToBuildLa,
                          ['"', '"', #13, #13]),
                   mtError,[mbCancel],0);
        exit;
      end;
    end;
    Tool.ScanOutputForFPCMessages:=true;
    Tool.ScanOutputForMakeMessages:=true;

    // clean up
    if Options.CleanAll
    and ([blfDontClean,blfOnlyIDE]*Flags=[]) then begin
      WorkingDirectory:=EnvironmentOptions.LazarusDirectory;
      if not CheckDirectoryWritable(WorkingDirectory) then exit(mrCancel);

      // clean lazarus source directories
      Tool.Title:=lisCleanLazarusSource;
      Tool.WorkingDirectory:=WorkingDirectory;
      Tool.CmdLineParams:='cleanlaz';
      // append target OS
      if Options.TargetOS<>'' then
        Tool.CmdLineParams:=Tool.CmdLineParams+' OS_TARGET='+Options.FPCTargetOS;
      // append target CPU
      if Options.TargetCPU<>'' then
        Tool.CmdLineParams:=Tool.CmdLineParams+' CPU_TARGET='+Options.FPCTargetCPU;
      Result:=ExternalTools.Run(Tool,Macros);
      if Result<>mrOk then exit;
    end;

    // build every item
    for i:=0 to Profiles.MakeModeDefs.Count-1 do begin
      MMDef:=Profiles.MakeModeDefs[i]; // build item
      WorkingDirectory:=TrimFilename(EnvironmentOptions.LazarusDirectory
                                     +PathDelim+MMDef.Directory);
      // calculate make mode
      CurMakeMode:=Profiles.Current.MakeModes[i];
      if (blfOnlyIDE in Flags) then begin
        if (MMDef<>Profiles.MakeModeDefs.ItemIDE) then
          CurMakeMode:=mmNone;
      end;
      if (MMDef=Profiles.MakeModeDefs.ItemIDE) then
      begin
        if (blfWithoutCompilingIDE in Flags) and (blfWithoutLinkingIDE in Flags)
        then
          CurMakeMode:=mmNone
        // build the IDE when blfOnlyIDE is set, eg. when installing packages
        // even if that build node is disabled in configure build lazarus dialog
        else if (blfOnlyIDE in Flags) and (CurMakeMode=mmNone) then
          CurMakeMode := mmBuild;
      end;

      if CurMakeMode=mmNone then continue;

      if (blfDontClean in Flags) and (CurMakeMode=mmCleanBuild) then
        CurMakeMode:=mmBuild;
      Tool.Title:=MMDef.Description;
      if (MMDef=Profiles.MakeModeDefs.ItemIDE) and (blfWithoutLinkingIDE in Flags) then
        Tool.Title:=lisCompileIDEWithoutLinking;
      Tool.WorkingDirectory:=WorkingDirectory;
      Tool.CmdLineParams:=MMDef.Commands[CurMakeMode];
      // append extra options
      ExtraOptions:='';
      Result:=CreateBuildLazarusOptions(Profiles,i,Macros,PackageOptions,Flags,
                                 ExtraOptions,UpdateRevisionInc,OutputDirRedirected);
      if Result<>mrOk then exit;

      if (not OutputDirRedirected)
      and (not CheckDirectoryWritable(WorkingDirectory)) then
        exit(mrCancel);

      // add Linker options for wigdet set
      LinkerAddition := LCLWidgetLinkerAddition[Options.TargetPlatform];
      if LinkerAddition <> '' then
      begin
        if ExtraOptions <> '' then
          ExtraOptions := ExtraOptions + ' ' + LinkerAddition
        else
          ExtraOptions := LinkerAddition;
      end;
      
      if ExtraOptions<>'' then
        Tool.EnvironmentOverrides.Values['OPT'] := ExtraOptions;
      if not UpdateRevisionInc then
        Tool.EnvironmentOverrides.Values['USESVN2REVISIONINC'] := '0';
      // add -w option to print leaving/entering messages
      Tool.CmdLineParams:=Tool.CmdLineParams+' -w';
      // append target OS
      if Options.TargetOS<>'' then
        Tool.CmdLineParams:=Tool.CmdLineParams+' OS_TARGET='+Options.FPCTargetOS;
      // append target CPU
      if Options.TargetCPU<>'' then
        Tool.CmdLineParams:=Tool.CmdLineParams+' CPU_TARGET='+Options.FPCTargetCPU;
      // run
      Result:=ExternalTools.Run(Tool,Macros);
      if Result<>mrOk then exit;
    end;
    Result:=mrOk;
  finally
    Tool.Free;
  end;
end;

function CreateBuildLazarusOptions(Profiles: TBuildLazarusProfiles;
  ItemIndex: integer; Macros: TTransferMacroList;
  const PackageOptions: string; Flags: TBuildLazarusFlags;
  var ExtraOptions: string; out UpdateRevisionInc: boolean;
  out OutputDirRedirected: boolean): TModalResult;

  function RemoveProfilerOption(const ExtraOptions: string): string;
  var
    p, StartPos: integer;
  begin
    Result:=ExtraOptions;
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

  procedure AppendExtraOption(const AddOption: string; EncloseIfSpace: boolean);
  begin
    if AddOption='' then exit;
    if ExtraOptions<>'' then ExtraOptions:=ExtraOptions+' ';
    if EncloseIfSpace and (Pos(' ',AddOption)>0) then
      ExtraOptions:=ExtraOptions+'"'+AddOption+'"'
    else
      ExtraOptions:=ExtraOptions+AddOption;
    //DebugLn(['AppendExtraOption ',ExtraOptions]);
  end;

  procedure AppendExtraOption(const AddOption: string);
  begin
    AppendExtraOption(AddOption,true);
  end;

var
  MMDef: TMakeModeDef;
  Options: TBuildLazarusProfile;
  MakeIDECfgFilename: String;
  NewTargetFilename: String;
  NewTargetDirectory: String;
  NewUnitDirectory: String;
  DefaultTargetOS: string;
  DefaultTargetCPU: string;
  NewTargetOS: String;
  NewTargetCPU: String;
  CrossCompiling: Boolean;
  CurTargetFilename: String;
  BundleDir: String;
begin
  Result:=mrOk;
  Options:=Profiles.Current;
  OutputDirRedirected:=false;
  UpdateRevisionInc:=Options.UpdateRevisionInc;
  MMDef:=Profiles.MakeModeDefs[ItemIndex];

  // create extra options
  ExtraOptions:=Options.ExtraOptions;

  if MMDef=Profiles.MakeModeDefs.ItemIDE then begin
    // check for special IDE config file
    if (blfUseMakeIDECfg in Flags) then begin
      MakeIDECfgFilename:=GetMakeIDEConfigFilename;
      //DebugLn(['CreateBuildLazarusOptions MAKE MakeIDECfgFilename=',MakeIDECfgFilename,' ',FileExistsUTF8(MakeIDECfgFilename)]);
      if (FileExistsUTF8(MakeIDECfgFilename)) then begin
        // If a file name contains spaces, a file name whould need to be quoted.
        // Using a single quote is not possible, it is used already in the
        // makefile to group all options in OPT='bla bla'.
        // using " implicates that make uses a shell to execute the command of
        // that line. But using shells (i.e. command.com, cmd.exe, etc) is so
        // fragile (see bug 11362), that is better to avoid this.
        // Therefore we use a short 8.3 file and path name, so we don't need to
        // use quotes at all.
        // On platforms other than windows, ExtractShortPathName is implemented
        // too and simply returns the passed file name, so there is no need
        // for $IFDEF.
        if pos(' ',MakeIDECfgFilename)>0 then
          MakeIDECfgFilename:=ExtractShortPathNameUTF8(MakeIDECfgFilename);
        AppendExtraOption('@'+MakeIDECfgFilename);
      end;
    end;
    // check if linking should be skipped
    if blfWithoutLinkingIDE in Flags then begin
      AppendExtraOption('-Cn');
    end;

    // set target filename and target directory:
    // 1. the user has set a target directory
    // 2. For crosscompiling the IDE it needs a different directory
    // 3. If lazarus is installed as root/administrator, the lazarus executable
    //    is readonly and needs a different name and directory
    //    (e.g. ~/.lazarus/bin/lazarus).
    // 4. Platforms like windows locks executables, so lazarus can not replace
    //    itself. They need a different name (e.g. lazarus.new.exe).
    //    The target directory is writable, the lazarus.o file can be created.
    // 5. If the user uses the startlazarus utility, then we need a backup.
    //    Under non locking platforms 'make' cleans the lazarus executable, so
    //    the IDE will rename the old file first (e.g. to lazarus.old).
    //    Renaming is not needed.
    // Otherwise: Don't touch the target filename.

    NewTargetFilename:='';
    NewUnitDirectory:='';
    NewTargetDirectory:='';
    DefaultTargetOS:=GetDefaultTargetOS;
    DefaultTargetCPU:=GetDefaultTargetCPU;
    NewTargetOS:=Options.FPCTargetOS;
    NewTargetCPU:=Options.FPCTargetCPU;
    if NewTargetOS='' then NewTargetOS:=DefaultTargetOS;
    if NewTargetCPU='' then NewTargetCPU:=DefaultTargetCPU;
    CrossCompiling:=(CompareText(NewTargetOS,DefaultTargetOS)<>0) or (CompareText(NewTargetCPU,DefaultTargetCPU)<>0);
    DebugLn(['CreateBuildLazarusOptions NewTargetOS=',NewTargetOS,' NewTargetCPU=',NewTargetCPU]);
    if (Options.TargetDirectory<>'') then begin
      // Case 1. the user has set a target directory
      NewTargetDirectory:=Options.TargetDirectory;
      if not Macros.SubstituteStr(NewTargetDirectory) then begin
        debugln('CreateBuildLazarusOptions macro aborted Options.TargetDirectory=',Options.TargetDirectory);
        Result:=mrAbort;
        exit;
      end;
      NewTargetDirectory:=CleanAndExpandDirectory(NewTargetDirectory);
      debugln('CreateBuildLazarusOptions Options.TargetDirectory=',NewTargetDirectory);
      Result:=ForceDirectoryInteractive(NewTargetDirectory,[]);
      if Result<>mrOk then exit;
      if OSLocksExecutables and not CrossCompiling then begin
        // Allow for the case where this corresponds to the current executable
        NewTargetFilename:='lazarus'+GetExecutableExt(NewTargetOS);
        if FileExistsUTF8(AppendPathDelim(NewTargetDirectory)+NewTargetFilename) then
          NewTargetFilename:='lazarus.new'+GetExecutableExt(NewTargetOS)
      end;
    end else begin
      // no user defined target directory
      // => find it automatically

      if CrossCompiling then
      begin
        // Case 2. crosscompiling the IDE
        // create directory <primary config dir>/bin/<TargetCPU>-<TargetOS>
        NewTargetDirectory:=AppendPathDelim(GetPrimaryConfigPath)+'bin'
                            +PathDelim+NewTargetOS+'-'+NewTargetCPU;
        Macros.SubstituteStr(NewUnitDirectory);
        debugln('CreateBuildLazarusOptions Options.TargetOS=',Options.FPCTargetOS,' Options.TargetCPU=',
                Options.FPCTargetCPU,' DefaultOS=',DefaultTargetOS,' DefaultCPU=',DefaultTargetCPU);
        Result:=ForceDirectoryInteractive(NewTargetDirectory,[]);
        if Result<>mrOk then exit;
      end else begin
        // -> normal compile for this platform

        // get lazarus directory
        if Macros<>nil then begin
          NewTargetDirectory:='$(LazarusDir)';
          Macros.SubstituteStr(NewTargetDirectory);
        end;

        if (NewTargetDirectory<>'') and DirPathExists(NewTargetDirectory) then
        begin
          if not DirectoryIsWritableCached(NewTargetDirectory) then begin
            // Case 3. the lazarus directory is not writable
            // create directory <primary config dir>/bin/
            UpdateRevisionInc:=false;
            NewTargetDirectory:=AppendPathDelim(GetPrimaryConfigPath)+'bin';
            NewUnitDirectory:=AppendPathDelim(GetPrimaryConfigPath)+'units'
                            +PathDelim+NewTargetCPU+'-'+NewTargetOS;
            debugln('CreateBuildLazarusOptions LazDir readonly NewTargetDirectory=',NewTargetDirectory);
            Result:=ForceDirectoryInteractive(NewTargetDirectory,[]);
            if Result<>mrOk then exit;
          end else begin
            // the lazarus directory is writable
            if OSLocksExecutables then begin
              // Case 4. the current executable is locked
              // => use a different output name
              NewTargetFilename:='lazarus.new'+GetExecutableExt(NewTargetOS);
              debugln('CreateBuildLazarusOptions exe locked NewTargetFilename=',NewTargetFilename);
            end else begin
              // Case 5. or else: => just compile to current directory
              NewTargetDirectory:='';
            end;
          end;
        end else begin
          // lazarus dir is not valid (probably someone is experimenting)
          // -> just compile to current directory
          NewTargetDirectory:='';
        end;
      end;
    end;

    OutputDirRedirected:=NewTargetDirectory<>'';

    // create apple bundle if needed
    //debugln(['CreateBuildLazarusOptions NewTargetDirectory=',NewTargetDirectory]);
    if (Options.TargetPlatform in [lpCarbon,lpCocoa])
    and (NewTargetDirectory<>'')
    and (DirectoryIsWritableCached(NewTargetDirectory)) then begin
      CurTargetFilename:=NewTargetFilename;
      if CurTargetFilename='' then
        CurTargetFilename:='lazarus'+GetExecutableExt(NewTargetOS);
      if not FilenameIsAbsolute(CurTargetFilename) then
        CurTargetFilename:=NewTargetDirectory+PathDelim+CurTargetFilename;
      BundleDir:=ChangeFileExt(CurTargetFilename,'.app');
      //debugln(['CreateBuildLazarusOptions checking bundle ',BundleDir]);
      if not FileExistsCached(BundleDir) then begin
        //debugln(['CreateBuildLazarusOptions CurTargetFilename=',CurTargetFilename]);
        Result:=CreateApplicationBundle(CurTargetFilename, 'Lazarus');
        if not (Result in [mrOk,mrIgnore]) then begin
          debugln(['CreateBuildLazarusOptions CreateApplicationBundle failed']);
          IDEMessagesWindow.AddMsg('Error: failed to create application bundle '+BundleDir,NewTargetDirectory,-1);
          exit;
        end;
        Result:=CreateAppBundleSymbolicLink(CurTargetFilename);
        if not (Result in [mrOk,mrIgnore]) then begin
          debugln(['CreateBuildLazarusOptions CreateAppBundleSymbolicLink failed']);
          IDEMessagesWindow.AddMsg('Error: failed to create application bundle symlink to '+CurTargetFilename,NewTargetDirectory,-1);
          exit;
        end;
      end;
    end;

    if NewUnitDirectory<>'' then
      // FPC interpretes '\ ' as an escape for a space in a path,
      // so make sure the directory doesn't end with the path delimeter.
      AppendExtraOption('-FU'+ChompPathDelim(NewTargetDirectory));

    if NewTargetDirectory<>'' then
      // FPC interpretes '\ ' as an escape for a space in a path,
      // so make sure the directory doesn't end with the path delimeter.
      AppendExtraOption('-FE'+ChompPathDelim(NewTargetDirectory));

    if NewTargetFilename<>'' then begin
      // FPC automatically changes the last extension (append or replace)
      // For example under linux, where executables don't need any extension
      // fpc removes the last extension of the -o option.
      // Trick fpc:
      if GetExecutableExt(NewTargetOS)='' then
        NewTargetFilename:=NewTargetFilename+'.dummy';
      AppendExtraOption('-o'+NewTargetFilename);
    end;

    // add package options for IDE
    //DebugLn(['CreateBuildLazarusOptions blfUseMakeIDECfg=',blfUseMakeIDECfg in FLags,' ExtraOptions="',ExtraOptions,'" ',PackageOptions]);
    if not (blfUseMakeIDECfg in Flags) then
      AppendExtraOption(PackageOptions,false);
  end;
  //DebugLn(['CreateBuildLazarusOptions ',MMDef.Name,' ',ExtraOptions]);
end;

function SaveIDEMakeOptions(Profiles: TBuildLazarusProfiles;
  Macros: TTransferMacroList;
  const PackageOptions: string; Flags: TBuildLazarusFlags): TModalResult;

  function BreakOptions(const OptionString: string): string;
  var
    StartPos: Integer;
    EndPos: Integer;
    c: Char;
    CurLine: String;
  begin
    Result:='';
    // write each option into a line of its own
    StartPos:=1;
    repeat
      while (StartPos<=length(OptionString)) and (OptionString[StartPos]=' ') do
        inc(StartPos);
      EndPos:=StartPos;
      while EndPos<=length(OptionString) do begin
        c:=OptionString[EndPos];
        case c of
        ' ': break;

        '''','"','`':
          begin
            repeat
              inc(EndPos);
              if (OptionString[EndPos]=c) then begin
                inc(EndPos);
                break;
              end;
            until (EndPos>length(OptionString));
          end;

        else
          inc(EndPos);
        end;
      end;
      if (EndPos>StartPos) then begin
        CurLine:=Trim(copy(OptionString,StartPos,EndPos-StartPos));
        if (length(CurLine)>2) and (CurLine[1] in ['''','"','`'])
        and (CurLine[1]=CurLine[length(CurLine)]) then begin
          // whole line enclosed in quotation marks
          // in fpc config this is forbidden and gladfully unncessary
          CurLine:=copy(CurLine,2,length(CurLine)-2);
        end;
        Result:=Result+CurLine+LineEnding;
      end;
      StartPos:=EndPos;
    until StartPos>length(OptionString);
  end;

var
  ExtraOptions: String;
  Filename: String;
  fs: TFileStream;
  OptionsAsText: String;
  UpdateRevisionInc: boolean;
  OutputDirRedirected: boolean;
begin
  ExtraOptions:='';
  Result:=CreateBuildLazarusOptions(Profiles,
             Profiles.MakeModeDefs.IndexOf(Profiles.MakeModeDefs.ItemIDE),
             Macros, PackageOptions, Flags, ExtraOptions,
             UpdateRevisionInc, OutputDirRedirected);
  if Result<>mrOk then exit;
  Filename:=GetMakeIDEConfigFilename;
  try
    InvalidateFileStateCache;
    fs:=TFileStream.Create(UTF8ToSys(Filename),fmCreate);
    try
      if ExtraOptions<>'' then begin
        OptionsAsText:=BreakOptions(ExtraOptions);
        fs.Write(OptionsAsText[1],length(OptionsAsText));
      end;
    finally
      fs.Free;
    end;
  except
    on E: Exception do begin
      Result:=MessageDlg(lisLazBuildErrorWritingFile,
        Format(lisLazBuildUnableToWriteFile, [Filename, #13])
        +E.Message,
        mtError,[mbCancel,mbAbort],0);
      exit;
    end;
  end;
  Result:=mrOk;
end;

function GetMakeIDEConfigFilename: string;
begin
  Result:=AppendPathDelim(GetPrimaryConfigPath)+DefaultIDEMakeOptionFilename;
end;

{ TConfigureBuildLazarusDlg }

constructor TConfigureBuildLazarusDlg.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  fProfiles:=TBuildLazarusProfiles.Create;
  fUpdatingProfileCombo:=False;
end;

destructor TConfigureBuildLazarusDlg.Destroy;
begin
  fProfiles.Free;
  inherited Destroy;
end;

procedure TConfigureBuildLazarusDlg.FormCreate(Sender: TObject);
var
  LCLInterface: TLCLPlatform;
begin
  Caption := Format(lisConfigureBuildLazarus, ['"', '"']);

  MakeModeListHeader.Images := IDEImages.Images_16;
  with MakeModeListHeader.Sections.Add do
  begin
    Width := ButtonSize;
    MinWidth := Width;
    MaxWidth := Width;
    ImageIndex := IDEImages.LoadImage(16, 'menu_close');
  end;
  with MakeModeListHeader.Sections.Add do
  begin
    Width := ButtonSize;
    MinWidth := Width;
    MaxWidth := Width;
    ImageIndex := IDEImages.LoadImage(16, 'menu_build');
  end;
  with MakeModeListHeader.Sections.Add do
  begin
    Width := ButtonSize;
    MinWidth := Width;
    MaxWidth := Width;
    ImageIndex := IDEImages.LoadImage(16, 'menu_build_clean');
  end;
  with MakeModeListHeader.Sections.Add do
  begin
    Width := MakeModeListHeader.Width - 90 - 3 * ButtonSize;
    MinWidth := Width;
    MaxWidth := Width;
    Text := lisLazBuildABOPart;
  end;
  with MakeModeListHeader.Sections.Add do
  begin
    Width := 90;
    MinWidth := Width;
    MaxWidth := Width;
    Text := lisLazBuildABOAction;
  end;

  // Show Build target names in radiogroup.
  with LCLInterfaceRadioGroup do
  begin
    Caption := lisLazBuildLCLInterface;
    for LCLInterface := Low(TLCLPlatform) to High(TLCLPlatform) do
      Items.Add(LCLPlatformDisplayNames[LCLInterface]);
  end;

  BuildProfileLabel.Caption:=lisLazBuildProfile;
  CleanAllCheckBox.Caption := lisLazBuildCleanAll;
  OptionsLabel.Caption := lisLazBuildOptions;
  WithStaticPackagesCheckBox.Caption := lisLazBuildWithStaticPackages;
  UpdateRevisionIncCheckBox.Caption := lisUpdateRevisionInc;
  RestartAfterBuildCheckBox.Caption := lisLazBuildRestartAfterBuild;
  ConfirmBuildCheckBox.Caption := lisLazBuildConfirmBuild;
  BuildWithAllCheckBox.Caption := lisLazBuildWithAll;
  CompileButton.Caption := lisMenuBuild;
  CompileAllButton.Caption := lisMenuBuildAll;
  SaveSettingsButton.Caption := lisLazBuildSaveSettings;
  CancelButton.Caption := lisLazBuildCancel;
  HelpButton.Caption := lisMenuHelp;
  TargetOSLabel.Caption := lisLazBuildTargetOS;
  TargetCPULabel.Caption := lisLazBuildTargetCPU;
  TargetDirectoryLabel.Caption := lisLazBuildTargetDirectory;

  CompileButton.LoadGlyphFromLazarusResource('menu_build');
  CompileAllButton.LoadGlyphFromLazarusResource('menu_build_all');
  SaveSettingsButton.LoadGlyphFromStock(idButtonSave);
  if SaveSettingsButton.Glyph.Empty then
    SaveSettingsButton.LoadGlyphFromLazarusResource('laz_save');

  with TargetOSComboBox do
  begin
    with Items do begin
      Add(''); //('+rsiwpDefault+')');
      Add('Darwin');
      Add('FreeBSD');
      Add('Linux');
      Add('NetBSD');
      Add('OpenBSD');
      Add('Solaris');
      Add('Win32');
      Add('Win64');
      Add('WinCE');
      Add('go32v2');
      Add('os2');
      Add('beos');
      Add('haiku');
      Add('qnx');
      Add('netware');
      Add('wdosx');
      Add('emx');
      Add('watcom');
      Add('netwlibc');
      Add('amiga');
      Add('atari');
      Add('palmos');
      Add('gba');
      Add('nds');
      Add('macos');
      Add('morphos');
      Add('embedded');
      Add('symbian');
    end;
    ItemIndex:=0;
  end;

  with TargetCPUComboBox do begin
    with Items do begin
      Add(''); //('+rsiwpDefault+')');
      Add('arm');
      Add('i386');
      Add('m68k');
      Add('powerpc');
      Add('sparc');
      Add('x86_64');
    end;
    ItemIndex:=0;
  end;
end;

procedure TConfigureBuildLazarusDlg.FormDestroy(Sender: TObject);
begin
  ;
end;

procedure TConfigureBuildLazarusDlg.FormShow(Sender: TObject);
begin
  CopyMakeModeDefsToUI(fProfiles.MakeModeDefs);
  UpdateProfileNamesUI;
end;

procedure TConfigureBuildLazarusDlg.HelpButtonClick(Sender: TObject);
begin
  ShowContextHelpForIDE(Self);
end;

procedure TConfigureBuildLazarusDlg.MakeModeListHeaderResize(Sender: TObject);
begin
  if MakeModeListHeader.Sections.Count >= 3 then
    MakeModeListHeader.Sections[3].Width := MakeModeListHeader.Width - 90 - 3 * ButtonSize;
end;

procedure TConfigureBuildLazarusDlg.MakeModeListHeaderSectionClick(
               HeaderControl: TCustomHeaderControl; Section: THeaderSection);
var
  i: Integer;
begin
  if Section.Index in [0..2] then begin
    with fProfiles.Current do begin
      for i := 0 to Length(MakeModes)-1 do
        MakeModes[i] := IntToMakeMode(Section.Index);
    end;
    // Radiobuttons are drawn based on MakeModeSettings in an owner drawn Listbox.
    MakeModeListBox.Invalidate;
  end;
end;

procedure TConfigureBuildLazarusDlg.MakeModeListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  ButtonState: TThemedButton;
  ButtonDetails: TThemedElementDetails;
  x: Integer;
  ButtonRect: TRect;
  TxtH: Integer;
  CurRect: TRect;
  CurMmDef: TMakeModeDef;
  CurMmVal, mm: TMakeMode;
  RadioSize: TSize;
begin
  if (Index<0) or (Profiles.Count=0) or (Index>=Profiles.MakeModeDefs.Count) then exit;
  CurMmDef:=Profiles.MakeModeDefs[Index];
  CurMmVal:=fProfiles.Current.MakeModes[Index];
  TxtH:=MakeModeListBox.Canvas.TextHeight(CurMmDef.Description);
  CurRect:=ARect;
  MakeModeListBox.Canvas.Brush.Style:=bsSolid;
  MakeModeListBox.Canvas.FillRect(CurRect);
  // draw the buttons
  x:=0;
  for mm:=Low(TMakeMode) to High(TMakeMode) do
  begin
    // draw button
    ButtonRect.Left:=x;
    ButtonRect.Top:=ARect.Top+((ARect.Bottom-ARect.Top-ButtonSize) div 2);
    ButtonRect.Right:=x+ButtonSize;
    ButtonRect.Bottom:=ButtonRect.Top + ButtonSize;

    if CurMmVal = mm then // checked
      ButtonState := tbRadioButtonCheckedNormal
    else
      ButtonState := tbRadioButtonUncheckedNormal;

    ButtonDetails := ThemeServices.GetElementDetails(ButtonState);
    if ThemeServices.HasTransparentParts(ButtonDetails) then
      MakeModeListBox.Canvas.FillRect(ButtonRect);

    RadioSize := ThemeServices.GetDetailSize(ButtonDetails);
    if (RadioSize.cx <> -1) and (RadioSize.cy <> -1) then
    begin
      ButtonRect.Left := (ButtonRect.Left + ButtonRect.Right - RadioSize.cx) div 2;
      ButtonRect.Right := ButtonRect.Left + RadioSize.cx;
      ButtonRect.Top := (ButtonRect.Top + ButtonRect.Bottom - RadioSize.cy) div 2;
      ButtonRect.Bottom := ButtonRect.Top + RadioSize.cy;
    end;

    ThemeServices.DrawElement(
        MakeModeListBox.Canvas.GetUpdatedHandle([csBrushValid,csPenValid]),
        ButtonDetails, ButtonRect);
    Inc(x, ButtonSize);
  end;

  MakeModeListBox.Canvas.Brush.Style:=bsClear;
  MakeModeListBox.Canvas.TextOut(x+2, ARect.Top+(ARect.Bottom-ARect.Top-TxtH) div 2,
                                 CurMmDef.Description);
  // draw make mode text
  x:=MakeModeListBox.ClientWidth-90;
  MakeModeListBox.Canvas.TextOut(x+2, ARect.Top+(ARect.Bottom-ARect.Top-TxtH) div 2,
                                 GetTranslatedMakeModes(CurMmVal));
end;

procedure TConfigureBuildLazarusDlg.MakeModeListBoxMouseDown(Sender: TOBject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  NewMakeMode: TMakeMode;
  i: Integer;
begin
  if not GetMakeModeAtX(X, NewMakeMode) then
    exit;
  i:=MakeModeListBox.ItemAtPos(Point(X,Y),true);
  if (i < 0) or (i >= Profiles.MakeModeDefs.Count) then
    exit;
  Profiles.Current.MakeModes[i]:=NewMakeMode;
  MakeModeListBox.Invalidate;
end;

procedure TConfigureBuildLazarusDlg.MakeModeListBoxShowHint(Sender: TObject; HintInfo: PHintInfo);
var
  MakeMode: TMakeMode;
  i: Integer;
begin
  with HintInfo^ do begin
    HintStr:='';
    if not GetMakeModeAtX(CursorPos.X, MakeMode) then exit;
    i:=MakeModeListBox.ItemAtPos(CursorPos,true);
    if (i<0) or (i>=Profiles.MakeModeDefs.Count) then exit;
    HintStr:=MakeModeNames[MakeMode];
  end;
end;

procedure TConfigureBuildLazarusDlg.TargetDirectoryButtonClick(Sender: TObject);
var
  AFilename: String;
  DirDialog: TSelectDirectoryDialog;
begin
  DirDialog:=TSelectDirectoryDialog.Create(nil);
  try
    DirDialog.Options:=DirDialog.Options+[ofPathMustExist];
    DirDialog.Title:=lisLazBuildABOChooseOutputDir+'(lazarus'+
                      GetExecutableExt(Profiles.Current.FPCTargetOS)+')';
    if DirDialog.Execute then begin
      AFilename:=CleanAndExpandDirectory(DirDialog.Filename);
      TargetDirectoryComboBox.AddHistoryItem(AFilename,10,true,true);
    end;
  finally
    DirDialog.Free;
  end;
end;

procedure TConfigureBuildLazarusDlg.CopyMakeModeDefsToUI(AMakeModeDefs: TMakeModeDefs);
var
  i: Integer;
begin
  MakeModeListBox.Items.BeginUpdate;
  for i:=0 to AMakeModeDefs.Count-1 do
    MakeModeListBox.Items.Add(AMakeModeDefs[i].Description);
  MakeModeListBox.Items.EndUpdate;
end;

procedure TConfigureBuildLazarusDlg.CopyProfileToUI(AProfile: TBuildLazarusProfile);
begin
  CleanAllCheckBox.Checked          :=AProfile.CleanAll;
  OptionsEdit.Text                  :=AProfile.ExtraOptions;
  LCLInterfaceRadioGroup.ItemIndex  :=ord(AProfile.TargetPlatform);
  WithStaticPackagesCheckBox.Checked:=AProfile.WithStaticPackages;
  UpdateRevisionIncCheckBox.Checked :=AProfile.UpdateRevisionInc;
  RestartAfterBuildCheckBox.Checked :=AProfile.RestartAfterBuild;
  ConfirmBuildCheckBox.Checked      :=AProfile.ConfirmBuild;
  BuildWithAllCheckBox.Checked      :=AProfile.BuildWithAll;
  TargetOSComboBox.Text             :=AProfile.TargetOS;
  TargetDirectoryComboBox.Text      :=AProfile.TargetDirectory;
  TargetCPUComboBox.Text            :=AProfile.TargetCPU;
end;

procedure TConfigureBuildLazarusDlg.CopyUIToProfile(AProfile: TBuildLazarusProfile);
begin
  AProfile.CleanAll          :=CleanAllCheckBox.Checked;
  AProfile.ExtraOptions      :=OptionsEdit.Text;
  AProfile.TargetPlatform    :=TLCLPlatform(LCLInterfaceRadioGroup.ItemIndex);
  AProfile.WithStaticPackages:=WithStaticPackagesCheckBox.Checked;
  AProfile.UpdateRevisionInc :=UpdateRevisionIncCheckBox.Checked;
  AProfile.RestartAfterBuild :=RestartAfterBuildCheckBox.Checked;
  AProfile.ConfirmBuild      :=ConfirmBuildCheckBox.Checked;
  AProfile.BuildWithAll      :=BuildWithAllCheckBox.Checked;
  AProfile.TargetOS          :=TargetOSComboBox.Text;
  AProfile.TargetDirectory   :=TargetDirectoryComboBox.Text;
  AProfile.TargetCPU         :=TargetCPUComboBox.Text;
end;

procedure TConfigureBuildLazarusDlg.UpdateProfileNamesUI;
var
  i: Integer;
begin
  // Update the Profiles ComboBox.
  fUpdatingProfileCombo:=True;
  BuildProfileComboBox.Items.BeginUpdate;
  BuildProfileComboBox.Items.Clear;
  for i:=0 to fProfiles.Count-1 do
    BuildProfileComboBox.Items.Add(fProfiles[i].Name);
  BuildProfileCombobox.ItemIndex:=fProfiles.CurrentIndex;
  CopyProfileToUI(fProfiles.Current); // Copy current selection to UI.
  BuildProfileComboBox.Items.EndUpdate;
  fUpdatingProfileCombo:=False;
  MakeModeListBox.Invalidate;
end;

function TConfigureBuildLazarusDlg.GetMakeModeAtX(const X: Integer;
  out MakeMode: TMakeMode): boolean;
var
  i: integer;
begin
  Result:=True;
  MakeMode:=mmNone;
  i := X div ButtonSize;
  case i of
    0: MakeMode:=mmNone;
    1: MakeMode:=mmBuild;
    2: MakeMode:=mmCleanBuild;
  else
    Result:=False;
  end;
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

procedure TConfigureBuildLazarusDlg.PrepareClose;
begin
  CopyUIToProfile(Profiles.Current);
  MainIDEBar.itmToolBuildLazarus.Caption:=
    Format(lisMenuBuildLazarusProf, [Profiles.Current.Name]);
end;

procedure TConfigureBuildLazarusDlg.CompileAllButtonClick(Sender: TObject);
begin
  PrepareClose;
  ModalResult:=mrAll;
end;

procedure TConfigureBuildLazarusDlg.CompileButtonClick(Sender: TObject);
begin
  PrepareClose;
  ModalResult:=mrYes;
end;

procedure TConfigureBuildLazarusDlg.SaveSettingsButtonClick(Sender: TObject);
begin
  PrepareClose;
  ModalResult:=mrOk;
end;

procedure TConfigureBuildLazarusDlg.BuildProfileButtonClick(Sender: TObject);
var
  Frm: TBuildProfileManagerForm;
begin
  Frm:=TBuildProfileManagerForm.Create(nil);
  try
    CopyUIToProfile(Profiles.Current);     // Make sure changed fields get included.
    Frm.Prepare(fProfiles);                // Copy profiles to dialog.
    if Frm.ShowModal = mrOk then begin
      fProfiles.Assign(Frm.ProfsToManage); // Copy profiles back from dialog.
      UpdateProfileNamesUI;
    end;
  finally
    Frm.Free;
  end;
end;

procedure TConfigureBuildLazarusDlg.BuildProfileComboBoxSelect(Sender: TObject);
begin
  // QT binding calls this also when items are added to list. It shouldn't.
  if (fProfiles.Count>0) and not fUpdatingProfileCombo then
    if (Sender as TComboBox).ItemIndex<>-1 then begin
      CopyUIToProfile(fProfiles.Current);    // Save old selection from UI.
      fProfiles.CurrentIndex:=(Sender as TComboBox).ItemIndex;
      CopyProfileToUI(fProfiles.Current);    // Copy new selection to UI.
      MakeModeListBox.Invalidate;
    end;
end;


end.

