{  $Id$  }
{
 /***************************************************************************
                          mainbar.pp  -  Toolbar
                          ----------------------
                   TMainBar is the application toolbar window
                   and the base class for TMainIDE.


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
unit MainBar;

{$mode objfpc}{$H+}

interface

{$I ide.inc}

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  Classes, LCLType, LclLinux, Compiler, StdCtrls, Forms, Buttons, Menus,
  ComCtrls, Spin, Project, SysUtils, FileCtrl, Controls, Graphics, ExtCtrls,
  Dialogs, LazConf, CompReg, CodeToolManager, CodeCache, DefineTemplates,
  MsgView, NewProjectDlg, IDEComp, AbstractFormEditor, FormEditor,
  CustomFormEditor, ObjectInspector, PropEdits, ControlSelection, UnitEditor,
  CompilerOptions, EditorOptions, EnvironmentOpts, TransferMacros,
  SynEditKeyCmds, KeyMapping, ProjectOpts, IDEProcs, Process, UnitInfoDlg,
  Debugger, DBGOutputForm, GDBMIDebugger, RunParamsOpts, ExtToolDialog,
  MacroPromptDlg, LMessages, ProjectDefs, Watchesdlg, BreakPointsdlg, ColumnDlg,
  OutputFilter, BuildLazDialog, MiscOptions, EditDefineTree, CodeToolsOptions,
  TypInfo, IDEOptionDefs, CodeToolsDefines, LocalsDlg, DebuggerDlg;

const
  Version_String = '0.8.3 alpha';

type
  {
    The IDE is at anytime in a specific state:

    itNone: The default mode. All editing allowed.
    itBuilder: compiling the project. Loading/Saving/Debugging is not allowed.
    itDebugger: debugging the project. Loading/Saving/Compiling is not allowed.
    itCustom: this state is not used yet.
  }
  TIDEToolStatus = (itNone, itBuilder, itDebugger, itCustom);

  TSaveFlag = (sfSaveAs, sfSaveToTestDir, sfProjectSaving);
  TSaveFlags = set of TSaveFlag;
  TOpenFlag = (ofProjectLoading, ofOnlyIfExists, ofRevert, ofQuiet);
  TOpenFlags = set of TOpenFlag;
  TRevertFlag = (rfQuiet);
  TRevertFlags = set of TRevertFlag;
  TCloseFlag = (cfSaveFirst, cfProjectClosing);
  TCloseFlags = set of TCloseFlag;
  TLoadBufferFlag = (lbfUpdateFromDisk, lbfRevert, lbfCheckIfText);
  TLoadBufferFlags = set of TLoadBufferFlag;

  TMainIDEBar = class(TForm)
  
    // the speedbuttons panel for frequently used IDE functions
    pnlSpeedButtons : TPanel;
    ViewUnitsSpeedBtn   : TSpeedButton;
    ViewFormsSpeedBtn   : TSpeedButton;
    NewUnitSpeedBtn     : TSpeedButton;
    OpenFileSpeedBtn    : TSpeedButton;
    OpenFileArrowSpeedBtn: TSpeedButton;
    SaveSpeedBtn        : TSpeedButton;
    SaveAllSpeedBtn     : TSpeedButton;
    ToggleFormSpeedBtn  : TSpeedButton;
    NewFormSpeedBtn     : TSpeedButton;
    RunSpeedButton      : TSpeedButton;
    PauseSpeedButton    : TSpeedButton;
    StepIntoSpeedButton : TSpeedButton;
    StepOverSpeedButton : TSpeedButton;
    OpenFilePopUpMenu   : TPopupMenu;

    // MainMenu
    mnuMain: TMainMenu;

    mnuFile: TMenuItem;
    mnuEdit: TMenuItem;
    mnuSearch: TMenuItem;
    mnuView: TMenuItem;
    mnuProject: TMenuItem;
    mnuRun: TMenuItem;
    mnuTools: TMenuItem;
    mnuEnvironment: TMenuItem;
    mnuHelp: TMenuItem;

    itmSeperator: TMenuItem;

    itmFileNewUnit : TMenuItem;
    itmFileNewForm : TMenuItem;
    itmFileOpen: TMenuItem;
    itmFileRevert: TMenuItem;
    itmFileRecentOpen: TMenuItem;
    itmFileSave: TMenuItem;
    itmFileSaveAs: TMenuItem;
    itmFileSaveAll: TMenuItem;
    itmFileClose: TMenuItem;
    itmFileCloseAll: TMenuItem;
    itmFileQuit: TMenuItem;

    itmEditUndo: TMenuItem;
    itmEditRedo: TMenuItem;
    itmEditCut: TMenuItem;
    itmEditCopy: TMenuItem;
    itmEditPaste: TMenuItem;
    itmEditIndentBlock: TMenuItem;
    itmEditUnindentBlock: TMenuItem;
    itmEditUpperCaseBlock: TMenuItem;
    itmEditLowerCaseBlock: TMenuItem;
    itmEditTabsToSpacesBlock: TMenuItem;
    itmEditCompleteCode: TMenuItem;

    itmSearchFind: TMenuItem;
    itmSearchFindNext: TMenuItem;
    itmSearchFindPrevious: TMenuItem;
    itmSearchFindInFiles: TMenuItem;
    itmSearchReplace: TMenuItem;
    itmGotoLine: TMenuItem;
    itmJumpBack: TMenuItem;
    itmJumpForward: TMenuItem;
    itmAddJumpPoint: TMenuItem;
    itmJumpHistory: TMenuItem;
    itmFindBlockOtherEnd: TMenuItem;
    itmFindBlockStart: TMenuItem;
    itmFindDeclaration: TMenuItem;
    itmOpenFileAtCursor: TMenuItem;
    itmGotoIncludeDirective: TMenuItem;

    itmViewInspector: TMenuItem;
    itmViewProject: TMenuItem;
    itmViewUnits : TMenuItem;
    itmViewCodeExplorer : TMenuItem;
    itmViewForms : TMenuItem;
    itmViewMessage : TMenuItem;
    itmViewDebugWindows: TMenuItem;
    itmViewWatches: TMenuItem;
    itmViewBreakpoints: TMenuItem;
    itmViewLocals: TMenuItem;
    itmViewCallStack: TMenuItem;
    itmViewDebugOutput: TMenuItem;
    itmViewToggleFormUnit: TMenuItem;

    itmProjectNew: TMenuItem;
    itmProjectOpen: TMenuItem;
    itmProjectRecentOpen: TMenuItem;
    itmProjectSave: TMenuItem;
    itmProjectSaveAs: TMenuItem;
    itmProjectAddTo: TMenuItem;
    itmProjectRemoveFrom: TMenuItem;
    itmProjectViewSource: TMenuItem;
    itmProjectOptions: TMenuItem;

    itmProjectBuild: TMenuItem;
    itmProjectBuildAll: TMenuItem;
    itmProjectRun: TMenuItem;
    itmProjectPause: TMenuItem;
    itmProjectStepInto: TMenuItem;
    itmProjectStepOver: TMenuItem;
    itmProjectRunToCursor: TMenuItem;
    itmProjectStop: TMenuItem;
    itmProjectCompilerSettings: TMenuItem;
    itmProjectRunParameters: TMenuItem;

    itmToolConfigure: TMenuItem;
    itmToolSyntaxCheck: TMenuItem;
    itmToolGuessUnclosedBlock: TMenuItem;
    itmToolGuessMisplacedIFDEF: TMenuItem;
    itmToolConvertDFMtoLFM: TMenuItem;
    itmToolBuildLazarus: TMenuItem;
    itmToolConfigureBuildLazarus: TMenuItem;

    itmEnvGeneralOptions: TMenuItem;
    itmEnvEditorOptions: TMenuItem;
    itmEnvCodeToolsOptions: TMenuItem;
    itmEnvCodeToolsDefinesEditor: TMenuItem;

    itmHelpAboutLazarus: TMenuItem;

    // component palette
    ComponentNotebook : TNotebook;
    GlobalMouseSpeedButton: TSpeedButton;

    // hints. Note/ToDo: hints should be controlled by the lcl, this is a workaround
    HintTimer1 : TTimer;
    HintWindow1 : THintWindow;
  public
    ToolStatus: TIDEToolStatus;
    function FindUnitFile(const AFilename: string): string; virtual; abstract;
    procedure GetCurrentUnit(var ActiveSourceEditor:TSourceEditor;
      var ActiveUnitInfo:TUnitInfo); virtual; abstract;
      
    function GetTestUnitFilename(AnUnitInfo: TUnitInfo): string; virtual; abstract;
    function GetRunCommandLine: string; virtual; abstract;

    function DoOpenEditorFile(AFileName:string; PageIndex: integer;
        Flags: TOpenFlags): TModalResult; virtual; abstract;
    function DoInitProjectRun: TModalResult; virtual; abstract;
    
    function DoCheckFilesOnDisk: TModalResult; virtual; abstract;
  end;

var
  MainIDE : TMainIDEBar;

  ObjectInspector1 : TObjectInspector;
  PropertyEditorHook1 : TPropertyEditorHook;
  SourceNotebook : TSourceNotebook;
  Project1: TProject;


implementation



end.

