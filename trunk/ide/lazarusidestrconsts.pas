{  $Id$  }
{
 /***************************************************************************
                          lazarusidestrconsts.pas
                          -----------------------
              This unit contains all resource strings of the IDE


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
  Note: All resource strings should be prefixed with 'lis'

}
unit LazarusIDEStrConsts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 
  
resourcestring
  // version
  lisLazarusVersionString = '0.9.0 beta';
  lisNoStringConstantFound = 'No String Constant Found';
  lisHintTheMakeResourcestringFunctionExpectsAStringCon = 'Hint: The Make '
    +'Resourcestring Function expects a string constant.%sPlease select the '
    +'expression and try again.';

  // command line help
  listhisHelpMessage = 'this help message';
  lisprimaryConfigDirectoryWhereLazarusStoresItsConfig =
    '                      primary config '
    +'directory, where Lazarus stores its config files. Default is ';
  lislazarusOptionsProjectFilename = 'lazarus [options] <project-filename>';
  lisIDEOptions = 'IDE Options:';
  lisCmdLineLCLInterfaceSpecificOptions =
    'LCL Interface specific options:';
  lisDoNotShowSplashScreen = 'Do not show splash screen';
  lissecondaryConfigDirectoryWhereLazarusSearchesFor =
    '                      secondary config '
    +'directory, where Lazarus searches for config template files. Default is ';

  // component palette
  lisSelectionTool = 'Selection tool';
  
  // macros
  lisCursorColumnInCurrentEditor = 'Cursor column in current editor';
  lisCursorRowInCUrrentEditor = 'Cursor row in current editor';
  lisCompilerFilename = 'Compiler filename';
  lisWordAtCursorInCurrentEditor = 'Word at cursor in current editor';
  lisExpandedFilenameOfCurrentEditor = 'Expanded filename of current editor file';
  lisFreePascalSourceDirectory = 'Freepascal source directory';
  lisLazarusDirectory = 'Lazarus directory';
  lisLCLWidgetType = 'LCL Widget Type';
  lisCommandLineParamsOfProgram = 'Command line parameters of program';
  lisPromptForValue = 'Prompt for value';
  lisProjectFilename = 'Project filename';
  lisProjectDirectory = 'Project directory';
  lisSaveCurrentEditorFile = 'save current editor file';
  lisSaveAllModified = 'save all modified files';
  lisTargetFilenameOfProject = 'Target filename of project';
  lisTargetFilenamePlusParams = 'Target filename + params';
  lisTestDirectory = 'Test directory';
  lisLaunchingCmdLine = 'Launching target command line';
  lisPublishProjDir = 'Publish project directory';
  lisProjectUnitPath = 'Project Unit Path';
  lisProjectIncPath = 'Project Include Path';
  lisProjectSrcPath = 'Project Src Path';
  lisConfigDirectory = 'Lazarus config directory';

  // main bar menu
  lisMenuFile = '&File';
  lisMenuEdit = '&Edit';
  lisMenuSearch = '&Search';
  lisMenuView = '&View';
  lisMenuProject = '&Project';
  lisMenuRun = '&Run';
  lisMenuComponents = '&Components';
  lisMenuTools = '&Tools';
  lisMenuEnvironent = 'E&nvironment';
  lisMenuWindows = '&Windows';
  lisMenuHelp = '&Help';
  
  lisMenuNewUnit = 'New Unit';
  lisMenuNewForm = 'New Form';
  lisMenuNewOther = 'New ...';
  lisMenuOpen = 'Open';
  lisMenuRevert = 'Revert';
  lisPkgEditPublishPackage = 'Publish Package';
  lisMenuOpenRecent = 'Open Recent';
  lisMenuSave = 'Save';
  lisMenuSaveAs = 'Save As';
  lisMenuSaveAll = 'Save All';
  lisMenuClose = 'Close';
  lisMenuCloseAll = 'Close all editor files';
  lisMenuQuit = 'Quit';
  
  lisMenuUndo = 'Undo';
  lisMenuRedo = 'Redo';
  lisMenuCut = 'Cut';
  lisMenuCopy = 'Copy';
  lisMenuPaste = 'Paste';
  lisMenuIndentSelection = 'Indent selection';
  lisMenuUnindentSelection = 'Unindent selection';
  lisMenuUpperCaseSelection = 'Uppercase selection';
  lisMenuLowerCaseSelection = 'Lowercase selection';
  lisMenuTabsToSpacesSelection = 'Tabs to spaces in selection';
  lisMenuEncloseSelection = 'Enclose selection';
  lisMenuCommentSelection = 'Comment selection';
  lisMenuUncommentSelection = 'Uncomment selection';
  lisMenuSortSelection = 'Sort selection';
  lisMenuSelect = 'Select';
  lisMenuSelectAll = 'Select all';
  lisMenuSelectToBrace = 'Select to brace';
  lisMenuSelectCodeBlock = 'Select code block';
  lisMenuSelectLine = 'Select line';
  lisMenuSelectParagraph = 'Select paragraph';
  lisMenuInsertText = 'Insert text';
  lisMenuInsertCVSKeyword = 'CVS keyword';
  lisMenuInsertGeneral = 'General';
  lisMenuCompleteCode = 'Complete Code';

  lisMenuInsertGPLNotice = 'GPL notice';
  lisMenuInsertLGPLNotice = 'LGPL notice';
  lisMenuInsertUserName = 'Current username';
  lisMenuInsertDateTime = 'Current date and time';
  lisMenuInsertChangeLogEntry = 'ChangeLog entry';

  lisMenuFind = 'Find';
  lisMenuFindNext = 'Find &Next';
  lisMenuFindPrevious = 'Find &Previous';
  lisMenuFindInFiles = 'Find &in files';
  lisMenuReplace = 'Replace';
  lisMenuIncrementalFind = 'Incremental Find';
  lisMenuGotoLine = 'Goto line';
  lisMenuJumpBack = 'Jump back';
  lisMenuJumpForward = 'Jump forward';
  lisMenuAddJumpPointToHistory = 'Add jump point to history';
  lisMenuViewJumpHistory = 'View Jump-History';
  lisMenuFindBlockOtherEndOfCodeBlock = 'Find other end of code block';
  lisMenuFindCodeBlockStart = 'Find code block start';
  lisMenuFindDeclarationAtCursor = 'Find Declaration at cursor';
  lisMenuOpenFilenameAtCursor = 'Open filename at cursor';
  lisMenuGotoIncludeDirective = 'Goto include directive';
  
  lisMenuViewObjectInspector = 'Object Inspector';
  lisMenuViewSourceEditor = 'Source Editor';
  lisMenuViewCodeExplorer = 'Code Explorer';
  lisMenuViewUnits = 'Units...';
  lisMenuViewForms = 'Forms...';
  lisMenuViewUnitDependencies = 'View Unit Dependencies';
  lisMenuViewToggleFormUnit = 'Toggle form/unit view';
  lisMenuViewMessages = 'Messages';
  lisMenuDebugWindows = 'Debug windows';
  lisMenuViewWatches = 'Watches';
  lisMenuViewBreakPoints = 'BreakPoints';
  lisMenuViewLocalVariables = 'Local Variables';
  lisMenuViewCallStack = 'Call Stack';
  lisMenuViewDebugOutput = 'Debug output';
  
  lisMenuNewProject = 'New Project';
  lisMenuNewProjectFromFile = 'New Project from file';
  lisMenuOpenProject = 'Open Project';
  lisMenuOpenRecentProject = 'Open Recent Project';
  lisMenuSaveProject = 'Save Project';
  lisMenuSaveProjectAs = 'Save Project As...';
  lisMenuPublishProject = 'Publish Project';
  lisMenuProjectInspector = 'Project Inspector';
  lisMenuAddUnitToProject = 'Add active unit to Project';
  lisMenuRemoveUnitFromProject = 'Remove from Project';
  lisMenuViewSource = 'View Source';
  lisMenuViewProjectTodos = 'View ToDo List';
  lisMenuProjectOptions = 'Project Options...';
  
  lisMenuBuild = 'Build';
  lisMenuBuildAll = 'Build all';
  lisMenuAbortBuild = 'Abort Build';
  lisMenuProjectRun = 'Run';
  lisMenuPause = 'Pause';
  lisMenuStepInto = 'Step into';
  lisMenuStepOver = 'Step over';
  lisMenuRunToCursor = 'Run to cursor';
  lisMenuStop = 'Stop';
  lisMenuResetDebugger = 'Reset debugger';
  lisMenuCompilerOptions = 'Compiler Options...';
  lisMenuRunParameters = 'Run Parameters ...';
  
  lisMenuOpenPackage = 'Open package';
  lisMenuOpenRecentPkg = 'Open recent package';
  lisMenuOpenPackageFile = 'Open package file';
  lisMenuAddCurUnitToPkg = 'Add active unit to a package';
  lisMenuPackageGraph = 'Package Graph';
  lisMenuConfigCustomComps = 'Configure custom components';

  lisMenuSettings = 'Configure custom tools ...';
  lisMenuQuickSyntaxCheck = 'Quick syntax check';
  lisMenuGuessUnclosedBlock = 'Guess unclosed block';
  lisMenuGuessMisplacedIFDEF = 'Guess misplaced IFDEF/ENDIF';
  lisMenuMakeResourceString = 'Make Resource String';
  lisMenuDiff = 'Diff';
  lisMenuConvertDFMtoLFM = 'Convert DFM file to LFM';
  lisMenuBuildLazarus = 'Build Lazarus';
  lisMenuConfigureBuildLazarus = 'Configure "Build Lazarus"';
  
  lisMenuGeneralOptions = 'Environment options';
  lisMenuEditorOptions = 'Editor options';
  lisMenDebuggerOptions = 'Debugger Options';
  lisMenuCodeToolsOptions = 'CodeTools options';
  lisMenuCodeToolsDefinesEditor = 'CodeTools defines editor';
  
  lisMenuAboutLazarus = 'About Lazarus';
  
  lisDsgCopyComponents = 'Copy selected components to clipboard';
  lisDsgCutComponents = 'Cut selected components to clipboard';
  lisDsgPasteComponents = 'Paste selected components from clipboard';
  lisDsgSelectParentComponent = 'Select parent component';

  // main
  lisChooseProgramSourcePpPasLpr = 'Choose program source (*.pp,*.pas,*.lpr)';
  lisProgramSourceMustHaveAPascalExtensionLikePasPpOrLp = 'Program source '
    +'must have a pascal extension like .pas, .pp or .lpr';
  lisLazarusProjectInfoLpiLpiAllFiles = 'Lazarus Project Info (*.lpi)|*.lpi|'
    +'All Files|*.*';
  lisCompilerOptionsForProject = 'Compiler Options for Project: %s';
  lisUnableToReadFileError = 'Unable to read file %s%s%s%sError: %s';
  lisFormatError = 'Format error';
  lisUnableToConvertFileError = 'Unable to convert file %s%s%s%sError: %s';
  lisUnableToWriteFileError = 'Unable to write file %s%s%s%sError: %s';
  lisUnableToLoadOldResourceFileTheResourceFileIs = 'Unable to load old '
    +'resource file.%sThe resource file is the first include file in the%'
    +'sinitialization section.%sFor example {$I %s.lrs}.%sProbably a syntax '
    +'error.';
  lisResourceLoadError = 'Resource load error';
  lisnoname = 'noname';
  lisTheDestinationDirectoryDoesNotExist = 'The destination directory%s%s%s%s '
    +'does not exist.';
  lisRenameFile = 'Rename file?';
  lisThisLooksLikeAPascalFileFpc10XExpectsPascalFiles = 'This looks like a '
    +'pascal file.%sfpc 1.0.x expects pascal files lowercase.%sRename it to '
    +'lowercase?';
  lisOverwriteFile = 'Overwrite file?';
  lisAFileAlreadyExistsReplaceIt = 'A file %s%s%s already exists.%sReplace it?';
  lisAmbigiousFilesFound = 'Ambigious files found';
  lisThereAreOtherFilesInTheDirectoryWithTheSameName = 'There are other files '
    +'in the directory with the same name,%swhich only differ in case:%s%s%'
    +'sDelete them?';
  lisDeleteOldFile = 'Delete old file %s%s%s?';
  lisDeletingOfFileFailed = 'Deleting of file %s%s%s failed.';
  lisStreamingError = 'Streaming error';
  lisUnableToStreamT = 'Unable to stream %s:T%s.';
  lisResourceSaveError = 'Resource save error';
  lisUnableToAddResourceHeaderCommentToResourceFile = 'Unable to add resource '
    +'header comment to resource file %s%s%s%s.%sProbably a syntax error.';
  lisUnableToAddResourceTFORMDATAToResourceFileProbably = 'Unable to add '
    +'resource T%s:FORMDATA to resource file %s%s%s%s.%sProbably a syntax '
    +'error.';
  lisUnableToCreateFile2 = 'Unable to create file %s%s%s';
  lisUnableToTransformBinaryComponentStreamOfTIntoText = 'Unable to transform '
    +'binary component stream of %s:T%s into text.';
  lisTheFileWasNotFoundIgnoreWillGoOnLoadingTheProject = 'The file %s%s%s%'
    +'swas not found.%sIgnore will go on loading the project,%sAbort  will '
    +'stop the loading.';
  lisFileNotFound2 = 'File %s%s%s not found.%s';
  lisFileNotFoundDoYouWantToCreateIt = 'File %s%s%s not found.%sDo you want '
    +'to create it?%s';
  lisTheFileSeemsToBeTheProgramFileOfAnExistingLazarus = 'The file %s%s%s%'
    +'sseems to be the program file of an existing lazarus Project1.%sOpen '
    +'project?%sCancel will load the file as normal source.';
  lisProjectInfoFileDetected = 'Project info file detected';
  lisTheFileSeemsToBeAProgramCloseCurrentProject = 'The file %s%s%s%sseems to '
    +'be a program. Close current project and create a new lazarus project '
    +'for this program?%sCancel will load the file as normal source.';
  lisProgramDetected = 'Program detected';
  lisUnableToConvertTextFormDataOfFileIntoBinaryStream = 'Unable to convert '
    +'text form data of file %s%s%s%s%sinto binary stream. (%s)';
  lisFormLoadError = 'Form load error';
  lisUnableToBuildFormFromFile = 'Unable to build form from file %s%s%s%s.';
  lisSaveProjectLpi = 'Save Project %s (*.lpi)';
  lisInvalidProjectFilename = 'Invalid project filename';
  lisisAnInvalidProjectNamePleaseChooseAnotherEGProject = '%s%s%s is an '
    +'invalid project name.%sPlease choose another (e.g. project1.lpi)';
  lisTheNameIsNotAValidPascalIdentifier = 'The name %s%s%s is not a valid '
    +'pascal identifier.';
  lisChooseADifferentName = 'Choose a different name';
  lisTheProjectInfoFileIsEqualToTheProjectMainSource = 'The project info '
    +'file %s%s%s%sis equal to the project main source file!';
  lisUnitIdentifierExists = 'Unit identifier exists';
  lisThereIsAUnitWithTheNameInTheProjectPlzChoose = 'There is a unit with the '
    +'name %s%s%s in the project.%sPlz choose a different name';
  lisErrorCreatingFile = 'Error creating file';
  lisUnableToCreateFile3 = 'Unable to create file%s%s%s%s';
  lisCopyError2 = 'Copy error';
  lisSourceDirectoryDoesNotExists = 'Source directory %s%s%s does not exists.';
  lisUnableToCreateDirectory = 'Unable to create directory %s%s%s.';
  lisUnableToCopyFileTo = 'Unable to copy file %s%s%s%sto %s%s%s';
  lisSorryThisTypeIsNotYetImplemented = 'Sorry, this type is not yet '
    +'implemented';
  lisFileHasChangedSave = 'File %s%s%s has changed. Save?';
  lisUnitHasChangedSave = 'Unit %s%s%s has changed. Save?';
  lisSourceOfPageHasChangedSave = 'Source of page %s%s%s has changed. Save?';
  lisSourceModified = 'Source modified';
  lisOpenProject = 'Open Project?';
  lisOpenTheProjectAnswerNoToLoadItAsXmlFile = 'Open the project %s?%sAnswer '
    +'No to load it as xml file.';
  lisOpenPackage = 'Open Package?';
  lisOpenThePackageAnswerNoToLoadItAsXmlFile = 'Open the package %s?%sAnswer '
    +'No to load it as xml file.';
  lisRevertFailed = 'Revert failed';
  lisFileIsVirtual = 'File %s%s%s is virtual.';
  lisUnableToWrite = 'Unable to write %s%s%s%s%s.';
  lisFileNotText = 'File not text';
  lisFileDoesNotLookLikeATextFileOpenItAnyway = 'File %s%s%s%sdoes not look '
    +'like a text file.%sOpen it anyway?';
  lisInvalidCommand = 'Invalid command';
  lisTheCommandAfterIsNotExecutable = 'The command after %s%s%s is not '
    +'executable.';
  lisInvalidDestinationDirectory = 'Invalid destination directory';
  lisDestinationDirectoryIsInvalidPleaseChooseAComplete = 'Destination '
    +'directory %s%s%s is invalid.%sPlease choose a complete path.';
  lisUnableToCleanUpDestinationDirectory = 'Unable to clean up destination '
    +'directory';
  lisUnableToCleanUpPleaseCheckPermissions = 'Unable to clean up %s%s%s.%'
    +'sPlease check permissions.';
  lisCommandAfterPublishingModule = 'Command after publishing module';
  lisUnableToAddToProjectBecauseThereIsAlreadyAUnitWith = 'Unable to add %s '
    +'to project, because there is already a unit with the same name in the '
    +'Project.';
  lisAddToProject = 'Add %s to project?';
  lisTheFile = 'The file %s%s%s';
  lisisAlreadyPartOfTheProject = '%s is already part of the Project.';
  lisRemoveFromProject = 'Remove from project';
  lisCreateAProjectFirst = 'Create a project first!';
  lisTheTestDirectoryCouldNotBeFoundSeeEnvironmentOpt = 'The Test Directory '
    +'could not be found:%s%s%s%s%s(see environment options)';
  lisBuildNewProject = 'Build new project';
  lisTheProjectMustBeSavedBeforeBuildingIfYouSetTheTest = 'The project must '
    +'be saved before building%sIf you set the Test Directory in the '
    +'environment options,%syou can create new projects and build them at '
    +'once.%sSave project?';
  lisProjectSuccessfullyBuilt = 'Project %s%s%s successfully built. :)';
  lisNoProgramFileSFound = 'No program file %s%s%s found.';
  lisErrorInitializingProgramSErrorS = 'Error initializing program%s%s%s%s%s'
    +'Error: %s';
  lisNotNow = 'Not now';
  lisYouCanNotBuildLazarusWhileDebuggingOrCompiling = 'You can not build '
    +'lazarus while debugging or compiling.';
  lisUnableToSaveFile = 'Unable to save file %s%s%s';
  lisReadError = 'Read Error';
  lisUnableToReadFile2 = 'Unable to read file %s%s%s!';
  lisWriteError = 'Write Error';
  lisUnableToWriteToFile = 'Unable to write to file %s%s%s!';
  lisFileDoesNotLookLikeATextFileOpenItAnyway2 = 'File %s%s%s%sdoes not look '
    +'like a text file.%sOpen it anyway?';
  lisUnableToCreateBackupDirectory =
    'Unable to create backup directory %s%s%s.';
  lisDeleteFileFailed = 'Delete file failed';
  lisUnableToRemoveOldBackupFile = 'Unable to remove old backup file %s%s%s!';
  lisRenameFileFailed = 'Rename file failed';
  lisUnableToRenameFileTo = 'Unable to rename file %s%s%s to %s%s%s!';
  lisBackupFileFailed = 'Backup file failed';
  lisUnableToBackupFileTo = 'Unable to backup file %s%s%s to %s%s%s!';
  lisFileNotLowercase = 'File not lowercase';
  lisTheUnitIsNotLowercaseTheFreePascalCompiler10XNeeds = 'The unit %s%s%s is '
    +'not lowercase.%sThe FreePascal compiler 1.0.x needs lowercase '
    +'filenames. If you do not use the fpc 1.0.x to compile this unit, you '
    +'can ignore this message.%s%sRename file?';
  lisDeleteAmbigiousFile = 'Delete ambigious file?';
  lisAmbigiousFileFoundThisFileCanBeMistakenWithDelete = 'Ambigious file '
    +'found: %s%s%s%sThis file can be mistaken with %s%s%s%s%sDelete the '
    +'ambigious file?';
  lisLazarusEditorV = 'Lazarus Editor v%s';
  lisnewProject = '%s - (new project)';
  liscompiling = '%s (compiling ...)';
  lisdebugging = '%s (debugging ...)';
  lisUnableToFindFile = 'Unable to find file %s%s%s.';
  lisUnableToFindFileCheckSearchPathInRunCompilerOption = 'Unable to find '
    +'file %s%s%s.%sCheck search path in%sRun->Compiler Options...->Search '
    +'Paths->Other Unit Files';
  lisNOTECouldNotCreateDefineTemplateForFreePascal = 'NOTE: Could not create '
    +'Define Template for Free Pascal Sources';
  lisNOTECouldNotCreateDefineTemplateForLazarusSources = 'NOTE: Could not '
    +'create Define Template for Lazarus Sources';
  lisInvalidExpressionHintTheMakeResourcestringFunction = 'Invalid expression.%'
    +'sHint: The Make Resourcestring Function expects a string constant in a '
    +'single file. Please select the expression and try again.';
  lisSelectionExceedsStringConstant = 'Selection exceeds string constant';
  lisHintTheMakeResourcestringFunctionExpectsAStringCon2 = 'Hint: The Make '
    +'Resourcestring Function expects a string constant.%sPlease select only '
    +'a string expression and try again.';
  lisNoResourceStringSectionFound = 'No ResourceString Section found';
  lisUnableToFindAResourceStringSectionInThisOrAnyOfThe = 'Unable to find a '
    +'ResourceString section in this or any of the used units.';
  lisComponentNameIsNotAValidIdentifier = 'Component name %s%s%s is not a '
    +'valid identifier';
  lisComponentNameIsKeyword = 'Component name %s%s%s is keyword';
  lisUnableToRenameVariableInSourceSeeMessages = 'Unable to rename variable '
    +'in source.%sSee messages.';
  lisThereIsAlreadyAFormWithTheName = 'There is already a form with the name %'
    +'s%s%s';
  lisUnableToRenameFormInSourceSeeMessages = 'Unable to rename form in '
    +'source.%sSee messages.';
  lisSorryNotImplementedYet = 'Sorry, not implemented yet';
  lisUnableToFindMethodPlzFixTheErrorShownInTheMessage = 'Unable to find '
    +'method. Plz fix the error shown in the message window.';
  lisUnableToCreateNewMethodPlzFixTheErrorShownIn = 'Unable to create new '
    +'method. Plz fix the error shown in the message window.';
  lisUnableToShowMethodPlzFixTheErrorShownInTheMessage = 'Unable to show '
    +'method. Plz fix the error shown in the message window.';
  lisUnableToRenameMethodPlzFixTheErrorShownInTheMessag = 'Unable to rename '
    +'method. Plz fix the error shown in the message window.';

  // resource files
  lisResourceFileComment =
    'This is an automatically generated lazarus resource file';

  // file dialogs
  lisOpenFile = 'Open file';
  lisDebugUnableToLoadFile = 'Unable to load file';
  lisDebugUnableToLoadFile2 = 'Unable to load file %s%s%s.';
  lisOpenProjectFile = 'Open Project File';
  lisOpenPackageFile = 'Open Package File';
  lisSaveSpace = 'Save ';
  lisSelectDFMFiles = 'Select Delphi form files (*.dfm)';
  lisChooseDirectory = 'Choose directory';
  lisChooseLazarusSourceDirectory = 'Choose Lazarus Directory';
  lisChooseCompilerPath = 'Choose compiler filename (ppc386)';
  lisChooseFPCSourceDir = 'Choose FPC source directory';
  lisChooseDebuggerPath = 'Choose debugger filename';
  lisChooseTestBuildDir = 'Choose the directory for tests';

  // dialogs
  lisSaveChangesToProject = 'Save changes to project %s?';
  lisProjectChanged = 'Project changed';

  lisFPCSourceDirectoryError = 'FPC Source Directory error';
  lisPlzCheckTheFPCSourceDirectory = 'Please check the freepascal source directory';
  lisCompilerError = 'Compiler error';
  lisPlzCheckTheCompilerName = 'Please check the compiler name';
  lisAboutLazarus = 'About Lazarus';
  lisVersion = 'Version';
  lisClose = 'Close';
  lisAboutLazarusMsg =
       'License: GPL/LGPL'
      +'%s'
      +'Lazarus are the class libraries for Free Pascal that '
      +'emulate Delphi. Free Pascal is a (L)GPL''ed compiler that '
      +'runs on Linux, Win32, OS/2, 68K and more. Free Pascal '
      +'is designed to be able to understand and compile Delphi '
      +'syntax, which is of course OOP.'
      +'%s'
      +'Lazarus is the missing part of the puzzle that will allow '
      +'you to develop Delphi like programs in all of the above '
      +'platforms. The IDE will eventually become a RAD tool like '
      +'Delphi.'
      +'%s'
      +'As Lazarus is growing we need more developers.';
  lisUnitNameAlreadyExistsCap = 'Unitname already in project';
  lisTheUnitAlreadyExistsIgnoreWillForceTheRenaming = 'The unit %s%s%s '
    +'already exists.%sIgnore will force the renaming,%sCancel will cancel '
    +'the saving of this source and%sAbort will abort the whole saving.';
  lisInvalidPascalIdentifierCap = 'Invalid Pascal Identifier';
  lisInvalidPascalIdentifierText =
    'The name "%s" is not a valid pascal identifier.';
  lisCopyError = 'Copy Error';

  // hints
  lisHintNewUnit = 'New Unit';
  lisHintOpen = 'Open';
  lisHintSave = 'Save';
  lisHintSaveAll = 'Save all';
  lisHintNewForm = 'New Form';
  lisHintToggleFormUnit = 'Toggle Form/Unit';
  lisHintViewUnits = 'View Units';
  lisHintViewForms = 'View Forms';
  lisHintRun = 'Run';
  lisHintPause = 'Pause';
  lisHintStepInto = 'Step Into';
  lisHintStepOver = 'Step Over';
  
  lisGPLNotice =
    'Copyright (C) <year> <name of author>'
   +'%s'
   +'This program is free software; you can redistribute it and/or modify '
   +'it under the terms of the GNU General Public License as published by '
   +'the Free Software Foundation; either version 2 of the License, or '
   +'(at your option) any later version. '
   +'%s'
   +'This program is distributed in the hope that it will be useful, '
   +'but WITHOUT ANY WARRANTY; without even the implied warranty of '
   +'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the '
   +'GNU Library General Public License for more details. '
   +'%s'
   +'You should have received a copy of the GNU General Public License '
   +'along with this program; if not, write to the Free Software '
   +'Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.';
   
  lisLGPLNotice =
    'Copyright (C) <year> <name of author>'
   +'%s'
   +'This library is free software; you can redistribute it and/or modify '
   +'it under the terms of the GNU Library General Public License as published '
   +'by the Free Software Foundation; either version 2 of the License, or '
   +'(at your option) any later version. '
   +'%s'
   +'This program is distributed in the hope that it will be useful, '
   +'but WITHOUT ANY WARRANTY; without even the implied warranty of '
   +'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the '
   +'GNU Library General Public License for more details. '
   +'%s'
   +'You should have received a copy of the GNU Library General Public License '
   +'along with this library; if not, write to the Free Software '
   +'Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.';


  //IDE components
  ideStandard = 'Standard';
  ideAdditional = 'Additional';
  ideMisc = 'Misc';
  ideSystem = 'System';
  ideDialogs = 'Dialogs';
  ideDataAccess = 'Data Access';
  ideInterbase = 'Interbase Data Access';

  //Environment dialog
  dlgBakDirectory='(no subdirectoy)';
  
  dlgDesktop = 'Desktop';
  dlgWindows = 'Windows';
  dlgFrmEditor = 'Form Editor';
  dlgObjInsp = 'Object Inspector';
  dlgEnvFiles = 'Files';
  dlgEnvBckup = 'Backup';
  dlgNaming = 'Naming';
  dlgCancel = 'Cancel';
  lisCompTest = 'Test';
  lisA2PFilename2 = 'Filename';
  dlgEnvLanguage = 'Language';
  dlgAutoSave = 'Auto save';
  dlgEdFiles = 'Editor files';
  dlgEnvProject = 'Project';
  dlgIntvInSec = 'Interval in secs';
  dlgDesktopFiles = 'Desktop files';
  dlgSaveDFile = 'Save desktop settings to file';
  dlgLoadDFile = 'Load desktop settings from file';
  dlgMinimizeAllOnMinimizeMain = 'Minimize all on minimize main';
  dlgHideIDEOnRun = 'Hide IDE windows on run';
  dlgPalHints = 'Hints for component palette';
  dlgSpBHints = 'Hints for main speed buttons (open, save, ...)';
  lisEnvDoubleClickOnMessagesJumpsOtherwiseSingleClick = 'Double click on '
    +'messages jumps (otherwise: single click)';
  dlgWinPos = 'Window Positions';
  dlgMainMenu = 'Main Menu';
  dlgSrcEdit = 'Source Editor';
  dlgMsgs = 'Messages';
  dlgProjFiles = 'Project files';
  dlgEnvType = 'Type';
  dlgEnvNone = 'None';
  dlgSmbFront = 'Symbol in front (.~pp)';
  dlgSmbBehind = 'Symbol behind (.pp~)';
  dlgSmbCounter = 'Counter (.pp;1)';
  dlgCustomExt = 'User defined extension (.pp.xxx)';
  dlgBckUpSubDir = 'Same name (in subdirectory)';
  dlgEdCustomExt = 'User defined extension';
  dlgMaxCntr = 'Maximum counter';
  dlgEdBSubDir = 'Sub directory';
  dlgEnvOtherFiles = 'Other files';
  dlgMaxRecentFiles = 'Max recent files';
  dlgMaxRecentProjs = 'Max recent project files';
  dlgQOpenLastPrj = 'Open last project at start';
  dlgLazarusDir = 'Lazarus directory (default for all projects)';
  dlgFpcPath = 'Compiler path (ppc386)';
  dlgFpcSrcPath = 'FPC source directory';
  dlgDebugType = 'Debugger type and path';
  dlgTestPrjDir = 'Directory for building test projects';
  dlgQShowGrid = 'Show grid';
  dlgGridColor = 'Grid color';
  dlgQSnapToGrid = 'Snap to grid';
  dlgGridX = 'Grid size X';
  dlgGridY = 'Grid size Y';
  dlgGuideLines = 'Show Guide Lines';
  dlgSnapGuideLines = 'Snap to Guide Lines';
  dlgLeftTopClr = 'color for left, top';
  dlgRightBottomClr = 'color for right, bottom';
  dlgShowCaps = 'Show component captions';
  dlgShowEdrHints = 'Show editor hints';
  dlgAutoForm = 'Auto create form when opening unit';
  dlgGrabberColor = 'Grabber color';
  dlgMarkerColor = 'Marker color';
  dlgEnvGrid = 'Grid';
  dlgEnvLGuideLines = 'Guide lines';
  dlgEnvMisc = 'Miscellaneous';
  dlgRuberbandSelectionColor = 'Selection';
  dlgRuberbandCreationColor = 'Creation';
  dlgRubberbandSelectsGrandChilds = 'Select grand childs';
  dlgRubberBandGroup='Rubber band';
  dlgPasExt = 'Default pascal extension';
  dlgPasAutoLower = '%sSave As%s always saves pascal files lowercase';
  dlgPasAskLower = '%sSave As%s asks to save pascal files lowercase';
  dlgAmbigFileAct = 'Ambigious file action:';
  dlgEnvAsk = 'Ask';
  dlgAutoDel = 'Auto delete file';
  dlgAutoRen = 'Auto rename file';
  dlgAmbigWarn = 'Warn on compile';
  dlgIgnoreVerb = 'Ignore';
  dlgBackColor = 'Background color';
  dlgOIMiscellaneous = 'Miscellaneous';
  dlgOIItemHeight = 'Item height';
  dlgEnvColors = 'Colors';
  dlgEnvBackupHelpNote =
    'Notes: Project files are all files in the project directory';
  lisEnvOptDlgInvalidCompilerFilename = 'Invalid compiler filename';
  lisEnvOptDlgInvalidCompilerFilenameMsg =
    'The compiler file "%s" is not an executable.';
  lisEnvOptDlgInvalidDebuggerFilename = 'Invalid debugger filename';
  lisEnvOptDlgInvalidDebuggerFilenameMsg =
    'The debugger file "%s" is not an executable.';
  lisEnvOptDlgDirectoryNotFound = 'Directory not found';
  lisEnvOptDlgLazarusDirNotFoundMsg = 'Lazarus directory "%s" not found.';
  lisEnvOptDlgInvalidLazarusDir = 'The lazarus directory "%s" does not look correct.'
    +' Normally it contains directories like lcl, debugger, designer, components, ... .';
  lisEnvOptDlgFPCSrcDirNotFoundMsg = 'FPC source directory "%s" not found.';
  lisEnvOptDlgInvalidFPCSrcDir = 'The FPC source directory "%s" does not look correct.'
    +' Normally it contains directories like rtl, fcl, packages, compiler, ... .';
  lisEnvOptDlgTestDirNotFoundMsg = 'Test directory "%s" not found.';

  // editor options
  dlgEdDisplay = 'Display';
  dlgKeyMapping = 'Key Mappings';
  dlgEdColor = 'Color';
  dlgKeyMappingErrors = 'Key mapping errors';
  dlgEdBack = 'Back';
  dlgReport = 'Report';
  dlgEdNoErr = 'No errors in key mapping found.';
  dlgDelTemplate = 'Delete template ';
  dlgChsCodeTempl = 'Choose code template file (*.dci)';
  dlgAllFiles = 'All files';
  dlgAltSetClMode = 'Alt Sets Column Mode';
  dlgAutoIdent = 'Auto Indent';
  dlgBracHighlight = 'Bracket Highlight';
  dlgDragDropEd = 'Drag Drop Editing';
  dlgDropFiles = 'Drop Files';
  dlgHalfPageScroll = 'Half Page Scroll';
  dlgKeepCaretX = 'Keep Caret X';
  dlgPersistentCaret = 'Persistent Caret';
  dlgScrollByOneLess = 'Scroll By One Less';
  dlgScrollPastEndFile = 'Scroll Past End of File';
  dlgScrollPastEndLine = 'Scroll Past End of Line';
  dlgCloseButtonsNotebook = 'Show Close Buttons in notebook';
  dlgShowScrollHint = 'Show Scroll Hint';
  dlgMouseLinks = 'Mouse links';
  dlgShowGutterHints = 'Show Gutter Hints';
  dlgSmartTabs = 'Smart Tabs';
  dlgTabsToSpaces = 'Tabs To Spaces';
  dlgTrimTrailingSpaces = 'Trim Trailing Spaces';
  dlgUndoAfterSave = 'Undo after save';
  dlgDoubleClickLine = 'Double click line';
  dlgFindTextatCursor = 'Find text at cursor';
  dlgUseSyntaxHighlight = 'Use syntax highlight';
  dlgCopyWordAtCursorOnCopyNone = 'Copy word on copy none';
  dlgBlockIndent = 'Block indent:';
  dlgUndoLimit = 'Undo limit:';
  dlgTabWidths = 'Tab widths:';
  dlgMarginGutter = 'Margin and gutter';//What is gutter?
  dlgVisibleRightMargin = 'Visible right margin';
  dlgVisibleGutter = 'Visible gutter';//I know only about fish guts... :( :)
  dlgShowLineNumbers = 'Show line numbers';
  dlgRightMargin = 'Right margin';
  dlgRightMarginColor = 'Right margin color';
  dlgGutterWidth = 'Gutter width';// as I am food technology bachelor
  dlgGutterColor = 'Gutter color';// and fish technology engineer :) - VVI
  dlgEditorFont = 'Editor font';
  dlgDefaultEditorFont='Default editor font';
  dlgEditorFontHeight = 'Editor font height';
  dlgExtraLineSpacing = 'Extra line spacing';
  dlgKeyMappingScheme = 'Key Mapping Scheme';
  dlgCheckConsistency = 'Check consistency';
  dlgEdHintCommand = 'Hint: click on the command you want to edit';
  dlgLang = 'Language:';
  dlgClrScheme = 'Color Scheme:';
  dlgFileExts = 'File extensions:';
  dlgEdElement = 'Element';
  dlgSetElementDefault = 'Set element to default';
  dlgSetAllElementDefault = 'Set all elements to default';
  dlgForecolor = 'Foreground color';
  dlgEdUseDefColor = 'Use default color';
  dlgTextAttributes = 'Text attributes';
  dlgEdBold = 'Bold';
  dlgEdItal = 'Italic';
  dlgEdUnder = 'Underline';
  dlgEdIdComlet = 'Identifier completion';
  dlgEdCodeParams = 'Code parameters';
  dlgTooltipEval = 'Tooltip expression evaluation';
  dlgTooltipTools = 'Tooltip symbol Tools';
  dlgEdDelay = 'Delay';
  dlgTimeSecondUnit = 'sec';
  dlgEdCodeTempl = 'Code templates';
  dlgTplFName = 'Template file name';
  dlgEdAdd = 'Add...';
  dlgEdEdit = 'Edit...';
  dlgEdDelete = 'Delete';
  lisA2PAddFilesToPackage = 'Add files to package';
  dlgIndentCodeTo = 'Indent code to';
  dlgCodeToolsTab = 'Code Tools';
  
  //CodeTools dialogue
  dlgCodeToolsOpts = 'CodeTools Options';
  dlgCodeCreation = 'Code Creation';
  dlgWordsPolicies = 'Words';
  dlgLineSplitting = 'Line Splitting';
  dlgSpaceNotCosmos{:)} = 'Space';
  dlgAdditionalSrcPath = 'Additional Source search path for all projects (.pp;.pas)';
  dlgJumpingETC = 'Jumping (e.g. Method Jumping)';
  dlgAdjustTopLine = 'Adjust top line due to comment in front';
  dlgCenterCursorLine = 'Center Cursor Line';
  dlgCursorBeyondEOL = 'Cursor beyond EOL';
  dlgClassInsertPolicy = 'Class part insert policy';
  dlgAlphabetically = 'Alphabetically';
  dlgCDTLast = 'Last';
  dlgMixMethodsAndProperties = 'Mix methods and properties';
  dlgForwardProcsInsertPolicy = 'Procedure insert policy';
  dlgLast = 'Last (i.e. at end of source)';
  dlgInFrontOfMethods = 'In front of methods';
  dlgBehindMethods = 'Behind methods';
  dlgForwardProcsKeepOrder = 'Keep order of procedures';
  dlgMethodInsPolicy = 'Method insert policy';
  dlgCDTClassOrder = 'Class order';
  dlgKeywordPolicy = 'Keyword policy';
  dlgCDTLower = 'lowercase';
  dlgCDTUPPERCASE = 'UPPERCASE';
  dlg1UP2low = 'Lowercase, first letter up';
  dlgIdentifierPolicy = 'Identifier policy';
  dlgPropertyCompletion = 'Property completion';
  dlgCompleteProperties = 'Complete properties';
  dlgCDTReadPrefix = 'Read prefix';
  dlgCDTWritePrefix = 'Write prefix';
  dlgCDTStoredPostfix = 'Stored postfix';
  dlgCDTVariablePrefix = 'Variable prefix';
  dlgSetPropertyVariable = 'Set property Variable';
  dlgMaxLineLength = 'Max line length:';
  dlgNotSplitLineFront = 'Do not split line In front of:';
  dlgNotSplitLineAfter = 'Do not split line after:';
  dlgCDTPreview = 'Preview (Max line length = 1)';
  dlgInsSpaceFront = 'Insert space in front of';
  dlgInsSpaceAfter = 'Insert space after';
  dlgWRDPreview = 'Preview';

  locwndSrcEditor = 'Lazarus Source Editor';
  
  // compiler options
  dlgCompilerOptions = 'Compiler Options';
  lisPkgEdOnlineHelpNotYetImplemented = 'Online Help not yet implemented';
  lisPkgEdRightClickOnTheItemsTreeToGetThePopupmenuWithAllAv = 'Right click '
    +'on the items tree to get the popupmenu with all available package '
    +'functions.';
  dlgSearchPaths = 'Paths';
  dlgCOParsing = 'Parsing';
  dlgCodeGeneration = 'Code';
  dlgCOLinking = 'Linking';
  dlgCOMessages = 'Messages';
  dlgCOOther = 'Other';
  dlgCOInherited = 'Inherited';
  dlgCOCompilation = 'Compilation';
  dlgShowCompilerOptions = 'Show compiler options';
  dlgCOOpts = 'Options: ';
  dlgCOStyle = 'Style:';
  dlgCOAsIs = 'As-Is';
  dlgSymantecChecking = 'Symantec Checking:';
  dlgDelphi2Ext = 'Delphi 2 Extensions';
  dlgCOCOps = 'C Style Operators (*=, +=, /= and -=)';
  dlgAssertCode = 'Include Assertion Code';
  dlgLabelGoto = 'Allow LABEL and GOTO';
  dlgCppInline = 'C++ Styled INLINE';
  dlgCMacro = 'C Style Macros (global)';
  dlgBP7Cptb = 'TP/BP 7.0 Compatible';
  dlgInitDoneOnly = 'Constructor name must be ''' + 'init' + ''' (destructor must be ''' + 'done' + ''')';
  dlgStaticKeyword = 'Static Keyword in Objects';
  dlgDeplhiComp = 'Delphi Compatible';
  dlgCOAnsiStr = 'Use Ansi Strings';
  dlgGPCComp = 'GPC (GNU Pascal Compiler) Compatible';
  dlgCOUnitStyle = 'Unit Style:';
  dlgStatic = 'Static';
  dlgDynamic = 'Dynamic';
  dlgCOSmart = 'Smart';
  dlgCOChecks = 'Checks:';
  dlgCORange = 'Range';
  dlgCOOverflow = 'Overflow';
  dlgCOStack = 'Stack';
  dlgHeapSize = 'Heap Size';
  dlgCOGenerate = 'Generate:';
  dlgCOFast = 'Faster Code';
  dlgCOSmaller = 'Smaller Code';
  dlgTargetProc = 'Target Processor:';
  dlgOptimiz = 'Optimizations:';
  dlgCOKeepVarsReg = 'Keep certain variables in registers';
  dlgUncertOpt = 'Uncertain Optimizations';
  dlgLevel1Opt = 'Level 1 (Quick Optimizations)';
  dlgLevel2Opt = 'Level 2 (Level 1 + Slower Optimizations)';
  dlgLevel3Opt = 'Level 3 (Level 2 + Uncertain)';
  dlgTargetOS = 'Target OS';
  dlgCODebugging = 'Debugging:';
  dlgCOGDB = 'Generate Debugging Info For GDB (Slows Compiling)';
  dlgCODBX = 'Generate Debugging Info For DBX (Slows Compiling)';
  dlgLNumsBct = 'Display Line Numbers in Run-time Error Backtraces';
  dlgCOHeaptrc = 'Use Heaptrc Unit';
  dlgGPROF = 'Generate code for gprof';
  dlgCOStrip = 'Strip Symbols From Executable';
  dlgLinkLibraries = 'Link Libraries:';
  dlgLinkDinLibs = 'Link With Dynamic Libraries';
  dlgLinkStatLibs = 'Link With Static Libraries';
  dlgLinkSmart = 'Link Smart';
  dlgPassOptsLinker = 'Pass Options To The Linker (Delimiter is space)';
  dlgVerbosity = 'Verbosity:';
  dlgCOShowErr = 'Show Errors';
  dlgShowWarnings = 'Show Warnings';
  dlgShowNotes = 'Show Notes';
  dlgShowHint = 'Show Hints';
  dlgShowGeneralInfo = 'Show General Info';
  dlgShowProcsError = 'Show all procs on error';
  dlgShowEverything ='Show Everything';
  dlgShowDebugInfo = 'Show Debug Info';
  dlgShowUsedFiles = 'Show Used Files';
  dlgShowTriedFiles = 'Show Tried Files';
  dlgShowDefinedMacros = 'Show Defined Macros';
  dlgShowCompiledProcedures = 'Show Compiled Procedures';
  dlgShowConditionals = 'Show Conditionals';
  dlgShowNothing = 'Show Nothing (only errors)';
  dlgWriteFPCLogo = 'Write an FPC Logo';
  dlgHintsUnused = 'Show Hints for unused project units';
  dlgConfigFiles = 'Config Files:';
  dlgUseFpcCfg = 'Use Compiler Config File (fpc.cfg)';
  dlgUseAdditionalConfig = 'Use Additional Compiler Config File';
  dlgStopAfterNrErr = 'Stop after number of errors:';
  dlgOtherUnitFiles = 'Other Unit Files (Delimiter is semicolon):';
  dlgCOIncFiles = 'Include Files:';
  dlgCOSources = 'Other Sources:  (.pp/.pas files)';
  dlgCOLibraries = 'Libraries:';
  dlgCODebugPath = 'Debugger path addition:';
  dlgToFPCPath = 'Path To Compiler:';
  lisCOSkipCallingCompiler = 'Skip calling Compiler';
  lisCOExecuteAfter = 'Execute after';
  lisCOExecuteBefore = 'Execute before';
  lisCOCommand = 'Command:';
  lisCOScanForFPCMessages = 'Scan for FPC messages';
  lisCOScanForMakeMessages = 'Scan for Make messages';
  dlgUnitOutp = 'Unit output directory:';
  dlgLCLWidgetType = 'LCL Widget Type';
  dlgButApply = 'Apply';
  dlgCOShowOptions = 'Show Options';
  dlgMainViewForms = 'View project forms';
  dlgMainViewUnits = 'View project units';
  dlgMulti = 'Multi';
  
  // project options dialog
  dlgProjectOptions = 'Project Options';
  dlgPOApplication = 'Application';
  dlgPOFroms = 'Forms';
  dlgPOInfo = 'Info';
  dlgApplicationSettings = 'Application Settings';
  dlgPOTitle = 'Title:';
  dlgPOOutputSettings = 'Output Settings';
  dlgPOTargetFileName = 'Target file name:';
  dlgAutoCreateForms = 'Auto-create forms:';
  dlgAvailableForms = 'Available forms:';
  dlgAutoCreateNewForms = 'When creating new forms, add them to auto-created forms';
  dlgSaveEditorInfo = 'Save editor info for closed files';
  dlgSaveEditorInfoProject = 'Save editor info only for project files';
  dlgRunParameters = 'Run parameters';
  dlgRunOLocal = 'Local';
  dlgRunOEnvironment = 'Environment';
  dlgHostApplication = 'Host application';
  dlgCommandLineParams = 'Command line parameters (without application name)';
  dlgUseLaunchingApp = 'Use launching application';
  dlgROWorkingDirectory = 'Working directory';
  dlgRunODisplay = 'Display (not for win32, e.g. 198.112.45.11:0, x.org:1, hydra:0.1)';
  dlgRunOUsedisplay = 'Use display';
  dlgRunOSystemVariables = 'System variables';
  dlgRunOVariable = 'Variable';
  dlgRunOValue = 'Value';
  dlgRunOUserOverrides = 'User overrides';
  dlgIncludeSystemVariables = 'Include system variables';
  dlgDirectoryDoesNotExist = 'Directory does not exist';
  lisRunParamsFileNotExecutable = 'File not executable';
  lisRunParamsTheHostApplicationIsNotExecutable = 'The host application %s%s%'
    +'s is not executable.';
  dlgTheDirectory = 'The directory "';
  dlgDoesNotExist = '" does not exist.';
  dlgTextToFing = '&Text to Find';
  dlgReplaceWith = '&Replace With';
  dlgFROpts = 'Options';
  dlgCaseSensitive = 'Case Sensitive';
  dlgWholeWordsOnly = 'Whole Words Only';
  dlgRegularExpressions = 'Regular Expressions';
  dlgMultiLine = 'Multi Line';
  dlgPromptOnReplace = 'Prompt On Replace';
  dlgSROrigin = 'Origin';
  dlgFromCursor = 'From Cursor';
  dlgEntireScope = 'Entire Scope';
  dlgScope = 'Scope';
  dlgGlobal = 'Global';
  dlgSelectedText = 'Selected Text';
  dlgDirection = 'Direction';
  dlgUpWord = 'Up';
  dlgDownWord = 'Down';
  dlgReplaceAll = 'Replace All';
  
  //IDEOptionDefs
  dlgGetPosition = 'Get position';
  dlgLeftPos     = 'Left:';
  dlgWidthPos    = 'Width:';
  dlgTopPos      = 'Top:';
  DlgHeightPos   = 'Height:';
  rsiwpUseWindowManagerSetting = 'Use windowmanager setting';
  rsiwpDefault                 = 'Default';
  rsiwpRestoreWindowGeometry   = 'Restore window geometry';
  rsiwpDocked                  = 'Docked';
  rsiwpCustomPosition          = 'Custom position';
  rsiwpRestoreWindowSize       = 'Restore window size';

  // Code Explorer
  lisCodeExplorer = 'Code Explorer';

  // Unit editor
  uemFindDeclaration = '&Find Declaration';
  uemOpenFileAtCursor = '&Open file at cursor';
  uemClosePage = '&Close Page';
  uemGotoBookmark = '&Goto Bookmark';
  uemBookmarkN = 'Bookmark';
  uemSetBookmark = '&Set Bookmark';
  uemReadOnly = 'Read Only';
  uemUnitInfo = 'Unit Info';
  uemDebugWord = 'Debug';
  uemAddBreakpoint = '&Add Breakpoint';
  uemAddWatchAtCursor = 'Add &Watch At Cursor';
  uemRunToCursor='&Run to Cursor';
  uemViewCallStackCursor = 'View Call Stack';
  uemMoveEditorLeft='Move Editor Left';
  uemMoveEditorRight='Move Editor Right';
  uemEditorproperties='Editor properties';
  ueNotImplCap='Not implemented yet';
  ueNotImplText='If You can help us to implement this feature, mail to '
   +'lazarus@miraclec.com';
  ueNotImplCapAgain='I told You: Not implemented yet';
  ueFileROCap= 'File is readonly';
  ueFileROText1='The file "';
  ueFileROText2='" is not writable.';
  ueModified='Modified';
  uepReadonly= 'Readonly';
  uepIns='INS';
  uepOvr='OVR';

  // Form designer
  fdInvalidMutliselectionCap='Invalid mutliselection';
  fdInvalidMutliselectionText='Multiselected components must be of a single form.';
  fdmAlignWord='Align';
  fdmMirrorHorizontal='Mirror horizontal';
  fdmMirrorVertical='Mirror vertical';
  fdmScaleWord='Scale';
  fdmSizeWord='Size';
  fdmBringTofront='Bring to front';
  fdmSendtoback='Send to back';
  fdmDeleteSelection='Delete selection';
  fdmSnapToGridOption='Option: Snap to grid';
  fdmSnapToGuideLinesOption='Option: Snap to guide lines';
  fdmShowOptions='Show Options for form editing';

  //-----------------------
  // keyMapping
  //
  srkmEditKeys ='Edit Keys';
  srkmCommand  = 'Command ';
  srkmConflic  = 'Conflict ';
  srkmConflicW = ' conflicts with ';
  srkmCommand1 = '    command1 "';
  srkmCommand2 = '    command2 "';
  srkmEditForCmd='Edit keys for command';
  srkmKey      = 'Key';
  srkmGrabKey  = 'Grab Key';
  srkmPressKey = 'Please press a key ...';
  srkmAlternKey= 'Alternative Key';
  srkmAlreadyConnected = ' The key "%s" is already connected to "%s".';

  //Commands
  srkmecWordLeft              = 'Move cursor word left';
  srkmecWordRight             = 'Move cursor word right';
  srkmecLineStart             = 'Move cursor to line start';
  srkmecLineEnd               = 'Move cursor to line end';
  srkmecPageUp                = 'Move cursor up one page';
  srkmecPageDown              = 'Move cursor down one page';
  srkmecPageLeft              = 'Move cursor left one page';
  srkmecPageRight             = 'Move cursor right one page';
  srkmecPageTop               = 'Move cursor to top of page';
  srkmecPageBottom            = 'Move cursor to bottom of page';
  srkmecEditorTop             = 'Move cursor to absolute beginning';
  srkmecEditorBottom          = 'Move cursor to absolute end';
  srkmecGotoXY                = 'Goto XY';
  srkmecSelLeft               = 'SelLeft';
  srkmecSelRight              = 'SelRight';
  srkmecSelUp                 = 'Select Up';
  srkmecSelDown               = 'Select Down';
  srkmecSelWordLeft           = 'Select Word Left';
  srkmecSelWordRight          = 'Select Word Right';
  srkmecSelLineStart          = 'Select Line Start';
  srkmecSelLineEnd            = 'Select Line End';
  srkmecSelPageUp             = 'Select Page Up';
  srkmecSelPageDown           = 'Select Page Down';
  srkmecSelPageLeft           = 'Select Page Left';
  srkmecSelPageRight          = 'Select Page Right';
  srkmecSelPageTop            = 'Select Page Top';
  srkmecSelPageBottom         = 'Select Page Bottom';
  srkmecSelEditorTop          = 'Select to absolute beginning';
  srkmecSelEditorBottom       = 'Select to absolute end';
  srkmecSelGotoXY             = 'Select Goto XY';
  srkmecSelectAll             = 'Select All';
  srkmecDeleteLastChar        = 'Delete Last Char';
  srkmecDeletechar            = 'Delete char at cursor';
  srkmecDeleteWord            = 'Delete to end of word';
  srkmecDeleteLastWord        = 'Delete to start of word';
  srkmecDeleteBOL             = 'Delete to beginning of line';
  srkmecDeleteEOL             = 'Delete to end of line';
  srkmecDeleteLine            = 'Delete current line';
  srkmecClearAll              = 'Delete whole text';
  srkmecLineBreak             = 'Break line and move cursor';
  srkmecInsertLine            = 'Break line, leave cursor';
  srkmecChar                  = 'Char';
  srkmecImeStr                = 'Ime Str';
  srkmecCut                   = 'Cut selection to clipboard';
  srkmecCopy                  = 'Copy selection to clipboard';
  srkmecPaste                 = 'Paste clipboard to current position';
  srkmecScrollUp              = 'Scroll up one line';
  srkmecScrollDown            = 'Scroll down one line';
  srkmecScrollLeft            = 'Scroll left one char';
  srkmecScrollRight           = 'Scroll right one char';
  srkmecInsertMode            = 'Insert Mode';
  srkmecOverwriteMode         = 'Overwrite Mode';
  srkmecToggleMode            = 'Toggle Mode';
  srkmecBlockIndent           = 'Indent block';
  srkmecBlockUnindent         = 'Unindent block';
  srkmecShiftTab              = 'Shift Tab';
  srkmecMatchBracket          = 'Go to matching bracket';
  srkmecNormalSelect          = 'Normal selection mode';
  srkmecColumnSelect          = 'Column selection mode';
  srkmecLineSelect            = 'Line selection mode';
  srkmecAutoCompletion        = 'Code template completion';
  srkmecUserFirst             = 'User First';
  srkmecGotoMarker            = 'Go to Marker %d';
  srkmecSetMarker             = 'Set Marker %d';
  srkmecPeriod                = 'period';
  // sourcenotebook
  srkmecJumpToEditor          = 'Focus to source editor';
  srkmecNextEditor            = 'Go to next editor';
  srkmecPrevEditor            = 'Go to prior editor';
  srkmecMoveEditorLeft        = 'Move editor left';
  srkmecMoveEditorRight       = 'Move editor right';
  srkmecGotoEditor            = 'Go to editor %d';
  // file menu
  srkmecNew                   = 'New';
  srkmecNewUnit               = 'New unit';
  srkmecNewForm               = 'New form';
  srkmecSaveAs                = 'Save as';
  srkmecSaveAll               = 'Save all';
  srkmecCloseAll              = 'Close all';

  // edit menu
  srkmecSelectionTabs2Spaces  = 'Convert tabs to spaces in selection';
  srkmecInsertGPLNotice       = 'Insert GPL notice';
  srkmecInsertLGPLNotice      = 'Insert LGPL notice';
  srkmecInsertUserName        = 'Insert current username';
  srkmecInsertDateTime        = 'Insert current date and time';
  srkmecInsertChangeLogEntry  = 'Insert ChangeLog entry';
  srkmecInsertCVSAuthor       = 'Insert CVS keyword Author';
  srkmecInsertCVSDate         = 'Insert CVS keyword Date';
  srkmecInsertCVSHeader       = 'Insert CVS keyword Header';
  srkmecInsertCVSID           = 'Insert CVS keyword ID';
  srkmecInsertCVSLog          = 'Insert CVS keyword Log';
  srkmecInsertCVSName         = 'Insert CVS keyword Name';
  srkmecInsertCVSRevision     = 'Insert CVS keyword Revision';
  srkmecInsertCVSSource       = 'Insert CVS keyword Source';
  // search menu
  srkmecFind                      = 'Find text';
  srkmecFindNext                  = 'Find next';
  srkmecFindPrevious              = 'Find previous';
  srkmecFindInFiles               = 'Find in files';
  srkmecReplace                   = 'Replace text';
  srkmecFindProcedureDefinition   = 'Find procedure definiton';
  srkmecFindProcedureMethod       = 'Find procedure method';
  srkmecGotoLineNumber            = 'Go to line number';
  srkmecAddJumpPoint              = 'Add jump point';
  srkmecOpenFileAtCursor          = 'Open file at cursor';
  srkmecGotoIncludeDirective      = 'Go to to include directive of current include file';
  // view menu
  srkmecToggleFormUnit            = 'Switch between form and unit';
  srkmecToggleObjectInsp          = 'View Object Inspector';
  srkmecToggleSourceEditor        = 'View Source Editor';
  srkmecToggleCodeExpl            = 'View Code Explorer';
  srkmecToggleMessages            = 'View messages';
  srkmecToggleWatches             = 'View watches';
  srkmecToggleBreakPoints         = 'View breakpoints';
  srkmecToggleDebuggerOut         = 'View debugger output';
  srkmecToggleLocals              = 'View local variables';
  srkmecTogglecallStack           = 'View call stack';
  srkmecViewUnits                 = 'View units';
  srkmecViewForms                 = 'View forms';
  srkmecViewUnitDependencies      = 'View unit dependencies';
  // codetools
  srkmecWordCompletion            = 'Word completion';
  srkmecCompletecode              = 'Complete code';
  srkmecSyntaxCheck               = 'Syntax check';
  srkmecGuessMisplacedIFDEF       = 'Guess misplaced $IFDEF';
  srkmecFindDeclaration           = 'Find declaration';
  srkmecFindBlockOtherEnd         = 'Find block other end';
  srkmecFindBlockStart            = 'Find block start';
  // project uuse menu resource

  // run menu
  srkmecBuild                     = 'build program/project';
  srkmecBuildAll                  = 'build all files of program/project';
  srkmecAbortBuild                = 'abort build';
  srkmecRun                       = 'run program';
  srkmecPause                     = 'pause program';
  srkmecStopProgram               = 'stop program';
  srkmecResetDebugger             = 'reset debugger';
  srkmecRunParameters             = 'run parameters';
  srkmecCompilerOptions           = 'compiler options';
  // tools menu
  srkmecExtToolSettings           = 'External tools settings';
  srkmecBuildLazarus              = 'Build lazarus';
  srkmecExtTool                   = 'External tool %d';
  // environment menu
  srkmecEnvironmentOptions        = 'General environment options';
  srkmecCodeToolsOptions          = 'Codetools options';
  srkmecCodeToolsDefinesEd        = 'Codetools defines editor';
  srkmecMakeResourceString        = 'Make resource string';
  srkmecDiff                      = 'Diff';
  // help menu
  srkmecunknown                   = 'unknown editor command';
   
  //Key strings
  srVK_UNKNOWN    = 'Unknown';
  srVK_LBUTTON    = 'Mouse Button Left';
  srVK_RBUTTON    = 'Mouse Button Right';
  //srVK_CANCEL     = 'Cancel'; = dlgCancel
  srVK_MBUTTON    = 'Mouse Button Middle';
  srVK_BACK       = 'Backspace';
  srVK_TAB        = 'Tab';
  srVK_CLEAR      = 'Clear';
  srVK_RETURN     = 'Return';
  srVK_SHIFT      = 'Shift';
  srVK_CONTROL    = 'Control';
  srVK_MENU       = 'Menu';
  srVK_PAUSE      = 'Pause key';
  srVK_CAPITAL    = 'Capital';
  srVK_KANA       = 'Kana';
  srVK_JUNJA      = 'Junja';
  srVK_FINAL      = 'Final';
  srVK_HANJA      = 'Hanja';
  srVK_ESCAPE     = 'Escape';
  srVK_CONVERT    = 'Convert';
  srVK_NONCONVERT = 'Nonconvert';
  srVK_ACCEPT     = 'Accept';
  srVK_MODECHANGE = 'Mode Change';
  srVK_SPACE      = 'Space key';
  srVK_PRIOR      = 'Prior';
  srVK_NEXT       = 'Next';
  srVK_END        = 'End';
  srVK_HOME       = 'Home';
  srVK_LEFT       = 'Left';
  srVK_UP         = 'Up';
  srVK_RIGHT      = 'Right';
  //srVK_DOWN       = 'Down'; = dlgdownword
  //srVK_SELECT     = 'Select'; = lismenuselect
  srVK_PRINT      = 'Print';
  srVK_EXECUTE    = 'Execute';
  srVK_SNAPSHOT   = 'Snapshot';
  srVK_INSERT     = 'Insert';
  //srVK_DELETE     = 'Delete'; dlgeddelete
  srVK_HELP       = 'Help';
  srVK_LWIN       = 'left windows key';
  srVK_RWIN       = 'right windows key';
  srVK_APPS       = 'application key';
  srVK_NUMPAD     = 'Numpad %d';
  srVK_NUMLOCK    = 'Numlock';
  srVK_SCROLL     = 'Scroll';
  srVK_IRREGULAR  = 'Irregular ';
   
  //Category
  srkmCatCursorMoving   = 'Cursor moving commands';
  srkmCatSelection      = 'Text selection commands';
  srkmCatEditing        = 'Text editing commands';
  srkmCatCmdCmd         = 'Command commands';
  srkmCatSearchReplace  = 'Text search and replace commands';
  srkmCatMarker         = 'Text marker commands';
  srkmCatCodeTools      = 'CodeTools commands';
  srkmCatSrcNoteBook    = 'Source Notebook commands';
  srkmCatFileMenu       = 'File menu commands';
  srkmCatViewMenu       = 'View menu commands';
  srkmCatProjectMenu    = 'Project menu commands';
  srkmCatRunMenu        = 'Run menu commands';
  srkmCatComponentsMenu = 'Components menu commands';
  srkmCatToolMenu       = 'Tools menu commands';
  srkmCatEnvMenu        = 'Environment menu commands';
  srkmCarHelpMenu       = 'Help menu commands';
  lisKeyCatDesigner     = 'Designer commands';

  //Languages
  rsLanguageAutomatic   = 'Automatic (or english)';
  rsLanguageEnglish     = 'English';
  rsLanguageDeutsch     = 'Deutsch';
  rsLanguageSpanish     = 'Espa�ol';
  rsLanguageFrench      = 'French';
  rsLanguageRussian     = '�������';
  rsLanguagePolish      = 'polski';

  //Units dependencies
  dlgUnitDepCaption     = 'Unit dependencies';
  dlgUnitDepBrowse      = 'Browse...';
  dlgUnitDepRefresh     = 'Refresh';
   
  // Build lazarus dialog
  lisCleanLazarusSource = 'Clean Lazarus Source';
  lisCompileIDEWithoutLinking = 'Compile IDE (without linking)';
  lisBuildLCL = 'Build LCL';
  lisBuildComponent = 'Build Component';
  lisBuildCodeTools = 'Build CodeTools';
  lisBuildSynEdit = 'Build SynEdit';
  lisBuildJITForm = 'Build JIT Form';
  lisBuildPkgReg = 'Build Package Registration';
  lisBuildIDE = 'Build IDE';
  lisBuildExamples = 'Build Examples';
  lisConfigureBuildLazarus = 'Configure %sBuild Lazarus%s';
  lisLazBuildCleanAll = 'Clean all';
  lisLazBuildSetToBuildAll = 'Set to %sBuild All%s';
  lisLazBuildBuildComponentsSynEditCodeTools = 'Build Components (SynEdit, '
    +'CodeTools)';
  lisLazBuildBuildSynEdit = 'Build SynEdit';
  lisLazBuildBuildCodeTools = 'Build CodeTools';
  lisLazBuildBuildIDE = 'Build IDE';
  lisLazBuildBuildExamples = 'Build Examples';
  lisLazBuildOptions = 'Options:';
  lisLazBuildTargetOS = 'Target OS:';
  lisLazBuildTargetDirectory = 'Target Directory:';
  lisLazBuildLCLInterface = 'LCL interface';
  lisLazBuildBuildJITForm = 'Build JITForm';
  lisLazBuildWithStaticPackages = 'With Packages';
  lisLazBuildOk = 'Ok';
  lisLazBuildCancel = 'Cancel';
  lisLazBuildNone = 'None';
  lisLazBuildBuild = 'Build';
  lisLazBuildCleanBuild = 'Clean+Build';
   
  // compiler
  lisCompilerErrorInvalidCompiler = 'Error: invalid compiler: %s';
  lisCompilerHintYouCanSetTheCompilerPath = 'Hint: you can set the compiler '
    +'path in Environment->Environment options->Files->Compiler Path';
  lisCompilerNOTELoadingOldCodetoolsOptionsFile = 'NOTE: loading old '
    +'codetools options file: ';
  lisCompilerNOTECodetoolsConfigFileNotFoundUsingDefaults = 'NOTE: codetools '
    +'config file not found - using defaults';
     
  // codetools options dialog
  lisCodeToolsOptsOk          = 'Ok';
  lisCodeToolsOptsNone        = 'None';
  lisCodeToolsOptsKeyword     = 'Keyword';
  lisCodeToolsOptsIdentifier  = 'Identifier';
  lisCodeToolsOptsColon       = 'Colon';
  lisCodeToolsOptsSemicolon   = 'Semicolon';
  lisCodeToolsOptsComma       = 'Comma';
  lisCodeToolsOptsPoint       = 'Point';
  lisCodeToolsOptsAt          = 'At';
  lisCodeToolsOptsNumber      = 'Number';
  lisCodeToolsOptsStringConst = 'String constant';
  lisCodeToolsOptsNewLine     = 'Newline';
  lisCodeToolsOptsSpace       = 'Space';
  lisCodeToolsOptsSymbol      = 'Symbol';
  
  // codetools defines
  lisCodeToolsDefsCodeToolsDefinesPreview = 'CodeTools Defines Preview';
  lisCodeToolsDefsWriteError = 'Write error';
  lisCodeToolsDefsErrorWhileWriting = 'Error while writing %s%s%s%s%s';
  lisCodeToolsDefsErrorWhileWritingProjectInfoFile = 'Error while writing '
    +'project info file %s%s%s%s%s';
  lisCodeToolsDefsReadError = 'Read error';
  lisCodeToolsDefsErrorReading = 'Error reading %s%s%s%s%s';
  lisCodeToolsDefsErrorReadingProjectInfoFile = 'Error reading project info '
    +'file %s%s%s%s%s';
  lisCodeToolsDefsNodeIsReadonly = 'Node is readonly';
  lisCodeToolsDefsAutoGeneratedNodesCanNotBeEdited = 'Auto generated nodes '
    +'can not be edited.';
  lisCodeToolsDefsInvalidPreviousNode = 'Invalid previous node';
  lisCodeToolsDefsPreviousNodeCanNotContainChildNodes = 'Previous node can '
    +'not contain child nodes.';
  lisCodeToolsDefsCreateFPCMacrosAndPathsForAFPCProjectDirectory = 'Create '
    +'FPC Macros and paths for a fpc project directory';
  lisCodeToolsDefsProjectDirectory = 'Project directory';
  lisCodeToolsDefsTheFreePascalProjectDirectory = 'The Free Pascal project '
    +'directory.';
  lisCodeToolsDefscompilerPath = 'compiler path';
  lisCodeToolsDefsThePathToTheFreePascalCompilerForThisProject = 'The path to '
    +'the free pascal compiler for this project. Only required if you set the '
    +'FPC CVS source below. Used to autocreate macros.';
  lisCodeToolsDefsFPCCVSSourceDirectory = 'FPC CVS source directory';
  lisCodeToolsDefsTheFreePascalCVSSourceDirectory = 'The Free Pascal CVS '
    +'source directory. Not required. This will improve find declarationand '
    +'debugging.';
  lisCodeToolsDefsCreateDefinesForFreePascalCompiler = 'Create Defines for '
    +'Free Pascal Compiler';
  lisCodeToolsDefsThePathToTheFreePascalCompilerForExample = 'The '
    +'path to the free pascal compiler.%s For example %s/usr/bin/ppc386 -n%s '
    +'or %s/usr/local/bin/fpc @/etc/11fpc.cfg%s.';
  lisCodeToolsDefsCreateDefinesForFreePascalCVSSources = 'Create Defines for '
    +'Free Pascal CVS Sources';
  lisCodeToolsDefsTheFreePascalCVSSourceDir = 'The Free Pascal CVS source '
    +'directory.';
  lisCodeToolsDefsCreateDefinesForLazarusDir = 'Create Defines for Lazarus '
    +'Directory';
  lisCodeToolsDefsLazarusDirectory = 'Lazarus Directory';
  lisCodeToolsDefsTheLazarusMainDirectory = 'The Lazarus main directory.';
  lisCodeToolsDefsCreateDefinesForDirectory = 'Create Defines for %s Directory';
  lisCodeToolsDefsdirectory = '%s directory';
  lisCodeToolsDefsDelphiMainDirectoryDesc = 'The %s main directory,%swhere '
    +'Borland has installed all %s sources.%sFor example: C:/Programme/'
    +'Borland/Delphi%s';
  lisCodeToolsDefsCreateDefinesForProject = 'Create Defines for %s Project';
  lisCodeToolsDefsprojectDirectory2 = '%s project directory';
  lisCodeToolsDefsTheProjectDirectory = 'The %s project directory,%swhich '
    +'contains the .dpr, dpk file.';
  lisCodeToolsDefsDelphiMainDirectoryForProject = 'The %s main directory,%'
    +'swhere Borland has installed all %s sources,%swhich are used by this %s '
    +'project.%sFor example: C:/Programme/Borland/Delphi%s';
  lisCodeToolsDefsExit = 'Exit';
  lisCodeToolsDefsSaveAndExit = 'Save and Exit';
  lisCodeToolsDefsExitWithoutSave = 'Exit without Save';
  lisCodeToolsDefsEdit = 'Edit';
  lisCodeToolsDefsMoveNodeUp = 'Move node up';
  lisCodeToolsDefsMoveNodeDown = 'Move node down';
  lisCodeToolsDefsMoveNodeOneLevelUp = 'Move node one level up';
  lisCodeToolsDefsMoveNodeOneLevelDown = 'Move node one level down';
  lisCodeToolsDefsInsertNodeBelow = 'Insert node below';
  lisCodeToolsDefsInsertNodeAsChild = 'Insert node as child';
  lisCodeToolsDefsDeleteNode = 'Delete node';
  lisCodeToolsDefsConvertNode = 'Convert node';
  lisCodeToolsDefsDefine = 'Define';
  lisCodeToolsDefsDefineRecurse = 'Define Recurse';
  lisCodeToolsDefsUndefine = 'Undefine';
  lisCodeToolsDefsUndefineRecurse = 'Undefine Recurse';
  lisCodeToolsDefsUndefineAll = 'Undefine All';
  lisCodeToolsDefsBlock = 'Block';
  lisCodeToolsDefsInsertBehindDirectory = 'Directory';
  lisCodeToolsDefsIf = 'If';
  lisCodeToolsDefsIfDef = 'IfDef';
  lisCodeToolsDefsIfNDef = 'IfNDef';
  lisCodeToolsDefsElseIf = 'ElseIf';
  lisCodeToolsDefsElse = 'Else';
  lisCodeToolsDefsInsertTemplate = 'Insert Template';
  lisCodeToolsDefsInsertFreePascalProjectTe = 'Insert Free Pascal Project '
    +'Template';
  lisCodeToolsDefsInsertFreePascalCompilerT = 'Insert Free Pascal Compiler '
    +'Template';
  lisCodeToolsDefsInsertFreePascalCVSSource = 'Insert Free Pascal CVS Source '
    +'Template';
  lisCodeToolsDefsInsertLazarusDirectoryTem = 'Insert Lazarus Directory '
    +'Template';
  lisCodeToolsDefsInsertDelphi5CompilerTemp = 'Insert Delphi 5 Compiler '
    +'Template';
  lisCodeToolsDefsInsertDelphi5DirectoryTem = 'Insert Delphi 5 Directory '
    +'Template';
  lisCodeToolsDefsInsertDelphi5ProjectTempl =
    'Insert Delphi 5 Project Template';
  lisCodeToolsDefsInsertDelphi6CompilerTemp = 'Insert Delphi 6 Compiler '
    +'Template';
  lisCodeToolsDefsInsertDelphi6DirectoryTem = 'Insert Delphi 6 Directory '
    +'Template';
  lisCodeToolsDefsInsertDelphi6ProjectTempl =
    'Insert Delphi 6 Project Template';
  lisCodeToolsDefsSelectedNode = 'Selected Node:';
  lisCodeToolsDefsNodeAndItsChildrenAreOnly = 'Node and its children are only '
    +'valid for this project';
  lisCodeToolsDefsName = 'Name:';
  lisCodeToolsDefsDescription = 'Description:';
  lisCodeToolsDefsVariable = 'Variable:';
  lisCodeToolsDefsValueAsText = 'Value as Text';
  lisCodeToolsDefsValueAsFilePaths = 'Value as File Paths';
  lisCodeToolsDefsAction = 'Action: %s';
  lisCodeToolsDefsautoGenerated = '%s, auto generated';
  lisCodeToolsDefsprojectSpecific = '%s, project specific';
  lisCodeToolsDefsnoneSelected = 'none selected';
  lisCodeToolsDefsInvalidParent = 'Invalid parent';
  lisCodeToolsDefsAutoCreatedNodesReadOnly = 'Auto created nodes can not be '
    +'edited,%snor can they have non auto created child nodes.';
  lisCodeToolsDefsInvalidParentNode = 'Invalid parent node';
  lisCodeToolsDefsParentNodeCanNotContainCh = 'Parent node can not contain '
    +'child nodes.';
  lisCodeToolsDefsNewNode = 'NewNode';
  lisCodeToolsDefsCodeToolsDefinesEditor = 'CodeTools Defines Editor';
  
  // code template dialog
  lisCodeTemplAddCodeTemplate = 'Add code template';
  lisCodeTemplAdd = 'Add';
  lisCodeTemplEditCodeTemplate = 'Edit code template';
  lisCodeTemplChange = 'Change';
  lisCodeTemplToken = 'Token:';
  lisCodeTemplComment = 'Comment:';
  lisCodeTemplATokenAlreadyExists = ' A token %s%s%s already exists! ';
  lisCodeTemplError = 'Error';

  // make resource string dialog
  lisMakeResourceString = 'Make ResourceString';
  lisMakeResStrInvalidResourcestringSect = 'Invalid Resourcestring section';
  lisMakeResStrPleaseChooseAResourstring = 'Please choose a resourstring '
    +'section from the list.';
  lisMakeResStrResourcestringAlreadyExis = 'Resourcestring already exists';
  lisMakeResStrChooseAnotherName = 'The resourcestring %s%s%s already exists.%'
    +'sPlease choose another name.%sUse Ignore to add it anyway.';
  lisMakeResStrStringConstantInSource = 'String Constant in source';
  lisMakeResStrConversionOptions = 'Conversion Options';
  lisMakeResStrIdentifierPrefix = 'Identifier Prefix:';
  lisMakeResStrIdentifierLength = 'Identifier Length:';
  lisMakeResStrCustomIdentifier = 'Custom Identifier';
  lisMakeResStrResourcestringSection = 'Resourcestring Section:';
  lisMakeResStrStringsWithSameValue = 'Strings with same value:';
  lisMakeResStrAppendToSection = 'Append to section';
  lisMakeResStrInsertAlphabetically = 'Insert alphabetically';
  lisMakeResStrInsertContexttSensitive = 'Insert context sensitive';
  lisMakeResStrSourcePreview = 'Source preview';
  
  // diff dialog
  lisDiffDlgText1 = 'Text1';
  lisDiffDlgOnlySelection = 'Only selection';
  lisDiffDlgText2 = 'Text2';
  lisDiffDlgCaseInsensitive = 'Case Insensitive';
  lisDiffDlgIgnoreIfEmptyLinesWereAdd = 'Ignore if empty lines were added or '
    +'removed';
  lisDiffDlgIgnoreSpacesAtStartOfLine = 'Ignore spaces at start of line';
  lisDiffDlgIgnoreSpacesAtEndOfLine = 'Ignore spaces at end of line';
  lisDiffDlgIgnoreIfLineEndCharsDiffe = 'Ignore difference in line ends (e.'
    +'g. #10 = #13#10)';
  lisDiffDlgIgnoreIfSpaceCharsWereAdd = 'Ignore amount of space chars';
  lisDiffDlgIgnoreSpaces = 'Ignore spaces (newline chars not included)';
  lisDiffDlgOpenDiffInEditor = 'Open Diff in editor';

  //todolist
  lisTodoListCaption='ToDo List';
  lisTodolistRefresh='Refresh todo items';
  lisTodoListGotoLine='Goto selected source line';
  lisTodoListPrintList='Print todo items';
  lisToDoListOptions='ToDo options...';
  lisToDoLDescription = 'Description';
  lisToDoLFile = 'File';
  lisToDoLLine = 'Line';
  
  // packages
  lisPkgFileTypeUnit = 'Unit';
  lisPkgFileTypeVirtualUnit = 'Virtual Unit';
  lisPkgFileTypeLFM = 'LFM - Lazarus form text';
  lisPkgFileTypeLRS = 'LRS - Lazarus resource';
  lisPkgFileTypeInclude = 'Include file';
  lisPkgFileTypeText = 'Text';
  lisPkgFileTypeBinary = 'Binary';

  // view project units dialog
  lisViewProjectUnits = 'View Project Units';
  
  // unit info dialog
  lisInformationAboutUnit = 'Information about %s';
  lisUIDyes = 'yes';
  lisUIDno = 'no';
  lisUIDbytes = '%s bytes';
  lisUIDName = 'Name:';
  lisUIDType = 'Type:';
  lisUIDinProject = 'in Project:';
  lisUIDIncludedBy = 'Included by:';
  lisUIDClear = 'Clear';
  lisUIDPathsReadOnly = 'Paths (Read Only)';
  lisUIDSrc = 'Src';
  lisUIDOk = 'Ok';
  
  // unit editor
  lisUEErrorInRegularExpression = 'Error in regular expression';
  lisUENotFound = 'Not found';
  lisUESearchStringNotFound = 'Search string ''%s'' not found!';
  lisUEReplaceThisOccurrenceOfWith = 'Replace this occurrence of %s%s%s%s '
    +'with %s%s%s?';
  lisUESearching = 'Searching: %s';
  lisUEReadOnly = '%s/ReadOnly';
  lisUEGotoLine = 'Goto line :';
  
  // Transfer Macros
  lisTMFunctionExtractFileExtension = 'Function: extract file extension';
  lisTMFunctionExtractFilePath = 'Function: extract file path';
  lisTMFunctionExtractFileNameExtension = 'Function: extract file name+'
    +'extension';
  lisTMFunctionExtractFileNameOnly = 'Function: extract file name only';
  lisTMFunctionAppendPathDelimiter = 'Function: append path delimiter';
  lisTMFunctionChompPathDelimiter = 'Function: chomp path delimiter';
  lisTMunknownMacro = '(unknown macro: %s)';
  
  // System Variables Override Dialog
  lisSVUOInvalidVariableName = 'Invalid variable name';
  lisSVUOisNotAValidIdentifier = '%s%s%s is not a valid identifier.';
  lisSVUOOverrideSystemVariable = 'Override system variable';
  lisSVUOOk = 'Ok';
  
  // sort selection dialog
  lisSortSelSortSelection = 'Sort Selection';
  lisSortSelPreview = 'Preview';
  lisSortSelAscending = 'Ascending';
  lisSortSelDescending = 'Descending';
  lisSortSelDomain = 'Domain';
  lisSortSelLines = 'Lines';
  lisSortSelWords = 'Words';
  lisSortSelParagraphs = 'Paragraphs';
  lisSortSelOptions = 'Options';
  lisSortSelCaseSensitive = 'Case Sensitive';
  lisSortSelIgnoreSpace = 'Ignore Space';
  lisSortSelSort = 'Sort';
  lisSortSelCancel = 'Cancel';

  // publish project dialog
  lisPublProjInvalidIncludeFilter = 'Invalid Include filter';
  lisPublProjInvalidExcludeFilter = 'Invalid Exclude filter';

  // project options
  lisProjOptsUnableToChangeTheAutoCreateFormList = 'Unable to change the auto '
    +'create form list in the program source.%sPlz fix errors first.';
  lisProjOptsError = 'Error';
  
  // path edit dialog
  lisPathEditSelectDirectory = 'Select directory';
  lisPathEditSearchPaths = 'Search paths:';
  lisPathEditMovePathDown = 'Move path down';
  lisPathEditMovePathUp = 'Move path up';
  lisPathEditBrowse = 'Browse';
  lisPathEditPathTemplates = 'Path templates';
  
  // new dialog
  lisNewDlgNoItemSelected = 'No item selected';
  lisNewDlgPleaseSelectAnItemFirst = 'Please select an item first.';
  lisNewDlgCreateANewEditorFileChooseAType = 'Create a new editor file.%'
    +'sChoose a type.';
  lisNewDlgCreateANewProjectChooseAType = 'Create a new project.%sChoose a '
    +'type.';
  lisNewDlgCreateANewPascalUnit = 'Create a new pascal unit.';
  lisNewDlgCreateANewUnitWithALCLForm = 'Create a new unit with a LCL form.';
  lisNewDlgCreateANewUnitWithADataModule = 'Create a new unit with a datamodule.';
  lisNewDlgCreateANewEmptyTextFile = 'Create a new empty text file.';
  lisNewDlgCreateANewGraphicalApplication = 'Create a new '
    +'graphical application.%sThe program file is maintained by Lazarus.';
  lisNewDlgCreateANewProgram = 'Create a new '
    +'program.%sThe program file is maintained by Lazarus.';
  lisNewDlgCreateANewCustomProgram = 'Create a new program.';
  lisNewDlgCreateANewStandardPackageAPackageIsACollectionOfUn = 'Create a new '
    +'standard package.%sA package is a collection of units and components.';

  // file checks
  lisUnableToCreateFile = 'Unable to create file';
  lisCanNotCreateFile = 'Can not create file %s%s%s';
  lisUnableToCreateFilename = 'Unable to create file %s%s%s.';
  lisUnableToWriteFile = 'Unable to write file';
  lisUnableToWriteFilename = 'Unable to write file %s%s%s.';
  lisUnableToReadFile = 'Unable to read file';
  lisUnableToReadFilename = 'Unable to read file %s%s%s.';
  lisErrorDeletingFile = 'Error deleting file';
  lisUnableToDeleteAmbigiousFile = 'Unable to delete ambigious file %s%s%s';
  lisErrorRenamingFile = 'Error renaming file';
  lisUnableToRenameAmbigiousFileTo = 'Unable to rename ambigious file %s%s%s%'
    +'sto %s%s%s';
  lisWarningAmbigiousFileFoundSourceFileIs = 'Warning: ambigious file found: %'
    +'s%s%s. Source file is: %s%s%s';
  lisAmbigiousFileFound = 'Ambigious file found';
  lisThereIsAFileWithTheSameNameAndASimilarExtension = 'There is a file with '
    +'the same name and a similar extension ond disk%sFile: %s%sAmbigious '
    +'File: %s%s%sDelete ambigious file?';

  // add to project dialog
  lisProjAddInvalidMinMaxVersion = 'Invalid Min-Max version';
  lisProjAddTheMaximumVersionIsLowerThanTheMinimimVersion = 'The Maximum '
    +'Version is lower than the Minimim Version.';
  lisProjAddInvalidPackagename = 'Invalid packagename';
  lisProjAddThePackageNameIsInvalidPlaseChooseAnExistingPackag = 'The package '
    +'name %s%s%s is invalid.%sPlase choose an existing package.';
  lisProjAddDependencyAlreadyExists = 'Dependency already exists';
  lisProjAddTheProjectHasAlreadyADependency = 'The project has already a '
    +'dependency for the package %s%s%s.';
  lisProjAddPackageNotFound = 'Package not found';
  lisProjAddTheDependencyWasNotFound = 'The dependency %s%s%s was not found.%'
    +'sPlease choose an existing package.';
  lisProjAddInvalidVersion = 'Invalid version';
  lisProjAddTheMinimumVersionIsInvalid = 'The Minimum Version %s%s%s is '
    +'invalid.%sPlease use the format major.minor.release.build%sFor '
    +'exmaple: 1.0.20.10';
  lisProjAddTheMaximumVersionIsInvalid = 'The Maximum Version %s%s%s is '
    +'invalid.%sPlease use the format major.minor.release.build%sFor '
    +'exmaple: 1.0.20.10';
  lisProjAddInvalidPascalUnitName = 'Invalid pascal unit name';
  lisProjAddTheUnitNameIsNotAValidPascalIdentifier = 'The unit name %s%s%s is '
    +'not a valid pascal identifier.';
  lisProjAddUnitNameAlreadyExists = 'Unit name already exists';
  lisProjAddTheUnitNameAlreadyExistsInTheProject = 'The unit name %s%s%s '
    +'already exists in the project%swith file: %s%s%s.';
  lisProjAddTheUnitNameAlreadyExistsInTheSelection = 'The unit name %s%s%s '
    +'already exists in the selection%swith file: %s%s%s.';
  lisProjAddNewRequirement = 'New Requirement';
  lisProjAddAddFileToProject = 'Add file to project:';
  lisProjAddPackageName = 'Package Name:';
  lisProjAddMinimumVersionOptional = 'Minimum Version (optional):';
  lisProjAddMaximumVersionOptional = 'Maximum Version (optional):';
  
  // component palette
  lisCompPalOpenPackage = 'Open package';
  lisCompPalOpenUnit = 'Open unit';

  // macro promp dialog
  lisMacroPromptEnterData = 'Enter data';
  lisMacroPromptEnterRunParameters = 'Enter run parameters';
  
  // debugger
  lisDebuggerError = 'Debugger error';
  lisDebuggerErrorOoopsTheDebuggerEnteredTheErrorState = 'Debugger error%'
    +'sOoops, the debugger entered the error state%sSave your work now !%sHit '
    +'Stop, and hope the best, we''re pulling the plug.';
  lisExecutionStopped = 'Execution stopped';
  lisExecutionStoppedOn = 'Execution stopped%s';
  lisExecutionPaused = 'Execution paused';
  lisExecutionPausedAdress = 'Execution paused%s  Adress: $%p%s  Procedure: %'
    +'s%s  File: %s%s(Some day an assembler window might popup here :)%s';
  lisFileNotFound = 'File not found';
  lisTheFileWasNotFoundDoYouWantToLocateItYourself = 'The file %s%s%s%swas '
    +'not found.%sDo you want to locate it yourself ?%s';
  lisRunToFailed = 'Run-to failed';
  lisPleaseOpenAUnitBeforeRun = 'Please open a unit before run.';
  
  // disk diff dialog
  lisDiskDiffErrorReadingFile = 'Error reading file: %s';
  lisDiskDiffSomeFilesHaveChangedOnDisk = 'Some files have changed on disk:';
  lisDiskDiffChangedFiles = 'Changed files:';
  lisDiskDiffClickOnOneOfTheAboveItemsToSeeTheDiff = 'Click on one of the '
    +'above items to see the diff';
  lisDiskDiffRevertAll = 'Revert All';
  lisDiskDiffIgnoreDiskChanges = 'Ignore disk changes';
  
  // edit define tree
  lisEdtDefCurrentProject = 'Current Project';
  lisEdtDefCurrentProjectDirectory = 'Current Project Directory';
  lisEdtDefProjectSrcPath = 'Project SrcPath';
  lisEdtDefProjectIncPath = 'Project IncPath';
  lisEdtDefProjectUnitPath = 'Project UnitPath';
  lisEdtDefAllPackages = 'All packages';
  lisEdtDefsetFPCModeToDELPHI = 'set FPC mode to DELPHI';
  lisEdtDefsetFPCModeToTP = 'set FPC mode to TP';
  lisEdtDefsetFPCModeToGPC = 'set FPC mode to GPC';
  lisEdtDefsetIOCHECKSOn = 'set IOCHECKS on';
  lisEdtDefsetRANGECHECKSOn = 'set RANGECHECKS on';
  lisEdtDefsetOVERFLOWCHECKSOn = 'set OVERFLOWCHECKS on';
  lisEdtDefuseLineInfoUnit = 'use LineInfo unit';
  lisEdtDefuseHeapTrcUnit = 'use HeapTrc unit';
  lisEdtDefGlobalSourcePathAddition = 'Global Source Path addition';
  
  // external tools
  lisExtToolFailedToRunTool = 'Failed to run tool';
  lisExtToolUnableToRunTheTool = 'Unable to run the tool %s%s%s:%s%s';
  lisExtToolExternalTools = 'External Tools';
  lisExtToolRemove = 'Remove';
  lisExtToolMoveUp = 'Move Up';
  lisExtToolMoveDown = 'Move Down';
  lisExtToolMaximumToolsReached = 'Maximum Tools reached';
  lisExtToolThereIsAMaximumOfTools = 'There is a maximum of %s tools.';
  
  // edit external tools
  lisEdtExtToolEditTool = 'Edit Tool';
  lisEdtExtToolProgramfilename = 'Programfilename:';
  lisEdtExtToolParameters = 'Parameters:';
  lisEdtExtToolWorkingDirectory = 'Working Directory:';
  lisEdtExtToolScanOutputForFreePascalCompilerMessages = 'Scan output for '
    +'Free Pascal Compiler messages';
  lisEdtExtToolScanOutputForMakeMessages = 'Scan output for make messages';
  lisEdtExtToolKey = 'Key';
  lisEdtExtToolCtrl = 'Ctrl';
  lisEdtExtToolAlt = 'Alt';
  lisEdtExtToolShift = 'Shift';
  lisEdtExtToolMacros = 'Macros';
  lisEdtExtToolInsert = 'Insert';
  lisEdtExtToolTitleAndFilenameRequired = 'Title and Filename required';
  lisEdtExtToolAValidToolNeedsAtLeastATitleAndAFilename = 'A valid tool needs '
    +'at least a title and a filename.';
    
  // find in files dialog
  lisFindFileTextToFind = 'Text to find:';
  lisFindFileCaseSensitive = 'Case sensitive';
  lisFindFileWholeWordsOnly = 'Whole words only';
  lisFindFileRegularExpressions = 'Regular expressions';
  lisFindFileWhere = 'Where';
  lisFindFilesearchAllFilesInProject = 'search all files in project';
  lisFindFilesearchAllOpenFiles = 'search all open files';
  lisFindFilesearchInDirectories = 'search in directories';
  lisFindFileDirectoryOptions = 'Directory options';
  lisFindFileFileMaskBak = 'File mask (*, *.*, *.bak?)';
  lisFindFileIncludeSubDirectories = 'Include sub directories';
  
  // package manager
  lisPkgMangPackage = 'Package: %s';
  lisPkgMangProject = 'Project: %s';
  lisPkgMangLazarus = 'Lazarus';
  lisPkgMangDependencyWithoutOwner = 'Dependency without Owner: %s';
  lisPkgMangSavePackageLpk = 'Save Package %s (*.lpk)';
  lisPkgMangInvalidPackageFileExtension = 'Invalid package file extension';
  lisPkgMangPackagesMustHaveTheExtensionLpk = 'Packages must have the '
    +'extension .lpk';
  lisPkgMangInvalidPackageName = 'Invalid package name';
  lisPkgMangThePackageNameIsNotAValidPackageNamePleaseChooseAn = 'The package '
    +'name %s%s%s is not a valid package name%sPlease choose another name (e.'
    +'g. package1.lpk)';
  lisPkgMangRenameFileLowercase = 'Rename File lowercase?';
  lisPkgMangShouldTheFileRenamedLowercaseTo = 'Should the file be renamed '
    +'lowercase to%s%s%s%s?';
  lisPkgMangPackageNameAlreadyExists = 'Package name already exists';
  lisPkgMangThereIsAlreadyAnotherPackageWithTheName = 'There is already '
    +'another package with the name %s%s%s.%sConflict package: %s%s%s%sFile: %'
    +'s%s%s';
  lisPkgMangFilenameIsUsedByProject = 'Filename is used by project';
  lisPkgMangTheFileNameIsPartOfTheCurrentProject = 'The file name %s%s%s is '
    +'part of the current project.%sProjects and Packages should not share '
    +'files.';
  lisPkgMangFilenameIsUsedByOtherPackage = 'Filename is used by other package';
  lisPkgMangTheFileNameIsUsedByThePackageInFile = 'The file name %s%s%s is '
    +'used by%sthe package %s%s%s%sin file %s%s%s.';
  lisPkgMangReplaceFile = 'Replace File';
  lisPkgMangReplaceExistingFile = 'Replace existing file %s%s%s?';
  lisPkgMangDeleteOldPackageFile = 'Delete Old Package File?';
  lisPkgMangDeleteOldPackageFile2 = 'Delete old package file %s%s%s?';
  lisPkgMangDeleteFailed = 'Delete failed';
  lisPkgMangUnableToDeleteFile = 'Unable to delete file %s%s%s.';
  lisPkgMangUnsavedPackage = 'Unsaved package';
  lisPkgMangThereIsAnUnsavedPackageInTheRequiredPackages = 'There is an '
    +'unsaved package in the required packages. See package graph.';
  lisPkgMangBrokenDependency = 'Broken dependency';
  lisPkgMangTheProjectRequiresThePackageButItWasNotFound = 'The project '
    +'requires the package %s%s%s.%sBut it was not found. See Project -> '
    +'Project Inspector.';
  lisPkgMangARequiredPackagesWasNotFound = 'A required packages was not '
    +'found. See package graph.';
  lisPkgMangCircleInPackageDependencies = 'Circle in package dependencies';
  lisPkgMangThereIsACircleInTheRequiredPackages = 'There is a circle in the '
    +'required packages. See package graph.';
  lisPkgMangErrorWritingFile = 'Error writing file';
  lisPkgMangUnableToWriteStateFileOfPackageError = 'Unable to write state '
    +'file %s%s%s%sof package %s.%sError: %s';
  lisPkgMangErrorReadingFile = 'Error reading file';
  lisPkgMangUnableToReadStateFileOfPackageError = 'Unable to read state file %'
    +'s%s%s%sof package %s.%sError: %s';
  lisPkgMangUnableToCreateDirectory = 'Unable to create directory';
  lisPkgMangUnableToCreateOutputDirectoryForPackage = 'Unable to create '
    +'output directory %s%s%s%sfor package %s.';
  lisPkgMangUnableToDeleteFilename = 'Unable to delete file';
  lisPkgMangUnableToDeleteOldStateFileForPackage = 'Unable to delete old '
    +'state file %s%s%s%sfor package %s.';
  lisPkgMangUnableToCreatePackageSourceDirectoryForPackage = 'Unable to '
    +'create package source directory %s%s%s%sfor package %s.';
  lisPkgMangUnableToLoadPackage = 'Unable to load package';
  lisPkgMangUnableToOpenThePackage = 'Unable to open the package %s%s%s.%'
    +'sThis package was marked for for installation.';
  lisPkgMangInvalidPackageName2 = 'Invalid Package Name';
  lisPkgMangThePackageNameOfTheFileIsInvalid = 'The package name %s%s%s of%'
    +'sthe file %s%s%s is invalid.';
  lisPkgMangPackageConflicts = 'Package conflicts';
  lisPkgMangThereIsAlreadyAPackageLoadedFromFile = 'There is already a '
    +'package %s%s%s loaded%sfrom file %s%s%s.%sSee Components -> Package '
    +'Graph.%sReplace is impossible.';
  lisPkgMangSavePackage = 'Save Package?';
  lisPkgMangLoadingPackageWillReplacePackage = 'Loading package %s will '
    +'replace package %s%sfrom file %s.%sThe old package is modified.%s%sSave '
    +'old package %s?';
  lisPkgMangNewPackage = 'NewPackage';
  lisPkgMangInvalidFileExtension = 'Invalid file extension';
  lisPkgMangTheFileIsNotALazarusPackage = 'The file %s%s%s is not a lazarus '
    +'package.';
  lisPkgMangInvalidPackageFilename = 'Invalid package filename';
  lisPkgMangThePackageFileNameInIsNotAValidLazarusPackageName = 'The package '
    +'file name %s%s%s in%s%s%s%s is not a valid lazarus package name.';
  lisPkgMangFileNotFound = 'File %s%s%s not found.';
  lisPkgMangErrorReadingPackage = 'Error Reading Package';
  lisPkgMangUnableToReadPackageFile = 'Unable to read package file %s%s%s.';
  lisPkgMangFilenameDiffersFromPackagename =
    'Filename differs from Packagename';
  lisPkgMangTheFilenameDoesNotCorrespondToThePackage = 'The filename %s%s%s '
    +'does not correspond to the package name %s%s%s in the file.%sChange '
    +'package name to %s%s%s?';
  lisPkgMangSavePackage2 = 'Save package?';
  lisPkgMangPackageChangedSave = 'Package %s%s%s changed. Save?';
  lisPkgMangErrorWritingPackage = 'Error Writing Package';
  lisPkgMangUnableToWritePackageToFileError = 'Unable to write package %s%s%s%'
    +'sto file %s%s%s.%sError: %s';
  lisPkgManginvalidCompilerFilename = 'invalid Compiler filename';
  lisPkgMangTheCompilerFileForPackageIsNotAValidExecutable = 'The compiler '
    +'file for package %s is not a valid executable:%s%s';
  lisPkgMangPackageHasNoValidOutputDirectory = 'Package %s%s%s has no valid '
    +'output directory:%s%s%s%s';
  lisPkgMangThisFileWasAutomaticallyCreatedByLazarusDoNotEdit = '{ This file '
    +'was automatically created by Lazarus. Do not edit!%s  This source is '
    +'only used to compile and install%s  the package %s.%s}%s';
  lisPkgMangpackageMainSourceFile = 'package main source file';
  lisPkgMangRenameFileInPackage = 'Rename file in package?';
  lisPkgMangThePackageOwnsTheFileShouldTheFileBeRenamed = 'The package %s '
    +'owns the file%s%s%s%s.%sShould the file be renamed in the package as '
    +'well?';
  lisPkgMangFileNotSaved = 'File not saved';
  lisPkgMangPleaseSaveTheFileBeforeAddingItToAPackage = 'Please save the file '
    +'before adding it to a package.';
  lisPkgMangFileIsInProject = 'File is in Project';
  lisPkgMangWarningTheFileBelongsToTheCurrentProject = 'Warning: The file %s%'
    +'s%s%sbelongs to the current project.';
  lisPkgMangFileIsAlreadyInPackage = 'File is already in package';
  lisPkgMangTheFileIsAlreadyInThePackage = 'The file %s%s%s%sis already in '
    +'the package %s.';
  lisPkgMangPackageIsNoDesigntimePackage = 'Package is no designtime package';
  lisPkgMangThePackageIsARuntimeOnlyPackageRuntimeOnlyPackages = 'The package %'
    +'s is a runtime only package.%sRuntime only packages can not be '
    +'installed in the IDE.';
  lisPkgMangAutomaticallyInstalledPackages = 'Automatically installed packages';
  lisPkgMangInstallingThePackageWillAutomaticallyInstall = 'Installing the '
    +'package %s will automatically install the package(s):%s%s';
  lisPkgMangRebuildLazarus = 'Rebuild Lazarus?';
  lisPkgMangThePackageWasMarkedForInstallationCurrentlyLazarus = 'The package %'
    +'s%s%s was marked for installation.%sCurrently lazarus only supports '
    +'static linked packages. The real installation needs rebuilding and '
    +'restarting of lazarus.%s%sDo you want to rebuild Lazarus now?';
  lisPkgMangPackageIsRequired = 'Package is required';
  lisPkgMangThePackageIsRequiredByWhichIsMarkedForInstallation = 'The package %'
    +'s is required by %s, which is marked for installation.%sSee package '
    +'graph.';
  lisPkgMangUninstallPackage = 'Uninstall package?';
  lisPkgMangUninstallPackage2 = 'Uninstall package %s?';
  lisPkgMangThePackageWasMarkedCurrentlyLazarus = 'The package %s%s%s was '
    +'marked.%sCurrently lazarus only supports static linked packages. The '
    +'real un-installation needs rebuilding and restarting of lazarus.%s%'
    +'sDo you want to rebuild Lazarus now?';
  lisPkgMangThePackageIsMarkedForInstallationButCanNotBeFound = 'The package %'
    +'s%s%s is marked for installation, but can not be found.%sRemove '
    +'dependency from the installation list of packages?';
  lisPkgMangstaticPackagesConfigFile = 'static packages config file';
  lisPkgMangUnableToCreateTargetDirectoryForLazarus = 'Unable to create '
    +'target directory for lazarus:%s%s%s%s.%sThis directory is needed for '
    +'the new changed lazarus IDE with your custom packages.';

  // package system
  lisPkgSysInvalidUnitname = 'Invalid Unitname: %s';
  lisPkgSysUnitNotFound = 'Unit not found: %s%s%s';
  lisPkgSysUnitWasRemovedFromPackage = 'Unit %s%s%s was removed from package';
  lisPkgSysCanNotRegisterComponentsWithoutUnit = 'Can not register components '
    +'without unit';
  lisPkgSysInvalidComponentClass = 'Invalid component class';
  lisPkgSysComponentClassAlreadyDefined = 'Component Class %s%s%s already '
    +'defined';
  lisPkgSysRegisterUnitWasCalledButNoPackageIsRegistering = 'RegisterUnit was '
    +'called, but no package is registering.';
  lisPkgSysUnitName = '%s%sUnit Name: %s%s%s';
  lisPkgSysFileName = '%s%sFile Name: %s%s%s';
  lisPkgSysRegistrationError = 'Registration Error';
  lisPkgSysTheFCLFreePascalComponentLibraryProvidesTheBase =
      'The FCL - '
    +'FreePascal Component Library provides the base classes for object pascal.';
  lisPkgSysTheLCLLazarusComponentLibraryContainsAllBase = 'The LCL - Lazarus '
    +'Component Library contains all base components for form editing.';
  lisPkgSysSynEditTheEditorComponentUsedByLazarus = 'SynEdit - the editor '
    +'component used by Lazarus. http://sourceforge.net/projects/synedit/';
  lisPkgSysThisIsTheDefaultPackageUsedOnlyForComponents = 'This is the '
    +'default package. Used only for components without a package. These '
    +'components are outdated.';
  lisPkgSysRegisterProcedureIsNil = 'Register procedure is nil';
  lisPkgSysThisPackageIsInstalledButTheLpkFileWasNotFound = 'This package is '
    +'installed, but the lpk file was not found.All its components are '
    +'deactivated. Please fix this.';
  lisPkgSysPackageFileNotFound = 'Package file not found';
  lisPkgSysThePackageIsInstalledButNoValidPackageFileWasFound = 'The package %'
    +'s%s%s is installed, but no valid package file was found.%sA broken '
    +'dummy package was created.';

  // package defs
  lisPkgDefsOutputDirectory = 'Output directory';
  lisPkgDefsCompiledSrcPathAddition = 'CompiledSrcPath addition';
  lisPkgDefsUnitPath = 'Unit Path';

  // add active file to package dialog
  lisAF2PInvalidPackage = 'Invalid Package';
  lisAF2PInvalidPackageID = 'Invalid package ID: %s%s%s';
  lisAF2PPackageNotFound = 'Package %s%s%s not found.';
  lisAF2PPackageIsReadOnly = 'Package is read only';
  lisAF2PThePackageIsReadOnly = 'The package %s is read only.';
  lisAF2PTheFileIsAlreadyInThePackage = 'The file %s%s%s%sis already in the '
    +'package %s.';
  lisAF2PUnitName = 'Unit Name: ';
  lisAF2PHasRegisterProcedure = 'Has Register procedure';
  lisAF2PIsVirtualUnit = 'Virtual unit (file is not in package)';
  lisAF2PFileType = 'File Type';
  lisAF2PDestinationPackage = 'Destination Package';
  lisAF2PShowAll = 'Show All';
  lisAF2PAddFileToAPackage = 'Add file to a package';
  
  // add to package dialog
  lisA2PInvalidFilename = 'Invalid filename';
  lisA2PTheFilenameIsAmbigiousPleaseSpecifiyAFilename = 'The filename %s%s%s '
    +'is ambigious.%sPlease specifiy a filename with full path.';
  lisA2PFileNotUnit = 'File not unit';
  lisA2PPascalUnitsMustHaveTheExtensionPPOrPas = 'Pascal units must have the '
    +'extension .pp or .pas';
  lisA2PisNotAValidUnitName = '%s%s%s is not a valid unit name.';
  lisA2PUnitnameAlreadyExists = 'Unitname already exists';
  lisA2PTheUnitnameAlreadyExistsInThisPackage = 'The unitname %s%s%s already '
    +'exists in this package.';
  lisA2PTheUnitnameAlreadyExistsInThePackage = 'The unitname %s%s%s already '
    +'exists in the package:%s%s';
  lisA2PAmbigiousUnitName = 'Ambigious Unit Name';
  lisA2PTheUnitNameIsTheSameAsAnRegisteredComponent = 'The unit name %s%s%s '
    +'is the same as an registered component.%sUsing this can cause strange '
    +'error messages.';
  lisA2PFileAlreadyExistsInTheProject = 'File %s%s%s already exists in the '
    +'project.';
  lisA2PExistingFile = '%sExisting file: %s%s%s';
  lisA2PFileAlreadyExists = 'File already exists';
  lisA2PFileIsUsed = 'File is used';
  lisA2PTheFileIsPartOfTheCurrentProjectItIsABadIdea = 'The file %s%s%s is '
    +'part of the current project.%sIt is a bad idea to share files between '
    +'projects and packages.';
  lisA2PTheMaximumVersionIsLowerThanTheMinimimVersion = 'The Maximum Version '
    +'is lower than the Minimim Version.';
  lisA2PThePackageNameIsInvalidPlaseChooseAnExisting = 'The package name %s%s%'
    +'s is invalid.%sPlase choose an existing package.';
  lisA2PThePackageHasAlreadyADependencyForThe = 'The package has already a '
    +'dependency for the package %s%s%s.';
  lisA2PNoPackageFoundForDependencyPleaseChooseAnExisting = 'No package found '
    +'for dependency %s%s%s.%sPlease choose an existing package.';
  lisA2PInvalidUnitName = 'Invalid Unit Name';
  lisA2PTheUnitNameAndFilenameDiffer = 'The unit name %s%s%s and filename '
    +'differ.';
  lisA2PFileAlreadyInPackage = 'File already in package';
  lisA2PTheFileIsAlreadyInThePackage = 'The file %s%s%s is already in the '
    +'package.';
  lisA2PInvalidFile = 'Invalid file';
  lisA2PAPascalUnitMustHaveTheExtensionPPOrPas = 'A pascal unit must have the '
    +'extension .pp or .pas';
  lisA2PInvalidAncestorType = 'Invalid Ancestor Type';
  lisA2PTheAncestorTypeIsNotAValidPascalIdentifier = 'The ancestor type %s%s%'
    +'s is not a valid pascal identifier.';
  lisA2PPageNameTooLong = 'Page Name too long';
  lisA2PThePageNameIsTooLongMax100Chars = 'The page name %s%s%s is too long ('
    +'max 100 chars).';
  lisA2PUnitNameInvalid = 'Unit Name Invalid';
  lisA2PTheUnitNameDoesNotCorrespondToTheFilename = 'The unit name %s%s%s '
    +'does not correspond to the filename.';
  lisA2PInvalidClassName = 'Invalid Class Name';
  lisA2PTheClassNameIsNotAValidPascalIdentifier = 'The class name %s%s%s is '
    +'not a valid pascal identifier.';
  lisA2PInvalidCircle = 'Invalid Circle';
  lisA2PTheClassNameAndAncestorTypeAreTheSame = 'The class name %s%s%s and '
    +'ancestor type %s%s%s are the same.';
  lisA2PAmbigiousAncestorType = 'Ambigious Ancestor Type';
  lisA2PTheAncestorTypeHasTheSameNameAsTheUnit = 'The ancestor type %s%s%s '
    +'has the same name as%sthe unit %s%s%s.';
  lisA2PAmbigiousClassName = 'Ambigious Class Name';
  lisA2PTheClassNameHasTheSameNameAsTheUnit = 'The class name %s%s%s has the '
    +'same name as%sthe unit %s%s%s.';
  lisA2PClassNameAlreadyExists = 'Class Name already exists';
  lisA2PTheClassNameExistsAlreadyInPackageFile = 'The class name %s%s%s '
    +'exists already in%sPackage %s%sFile: %s%s%s';
  lisA2PTheMinimumVersionIsInvalidPleaseUseTheFormatMajor = 'The Minimum '
    +'Version %s%s%s is invalid.%sPlease use the format major.minor.release.'
    +'build%sFor exmaple: 1.0.20.10';
  lisA2PTheMaximumVersionIsInvalidPleaseUseTheFormatMajor = 'The Maximum '
    +'Version %s%s%s is invalid.%sPlease use the format major.minor.release.'
    +'build%sFor exmaple: 1.0.20.10';
  lisA2PAddUnit = 'Add Unit';
  lisA2PNewComponent = 'New Component';
  lisA2PAddFile = 'Add File';
  lisA2PAddFiles = 'Add Files';
  lisA2PUnitFileName = 'Unit file name:';
  lisA2PchooseAnExistingFile = '<choose an existing file>';
  lisA2PAddLFMLRSFilesIfTheyExist = 'Add LFM, LRS files, if they exist';
  lisA2PUpdateUnitNameAndHasRegisterProcedure = 'Update Unit Name and Has '
    +'Register procedure';
  lisA2PAncestorType = 'Ancestor Type';
  lisA2PShowAll = 'Show all';
  lisA2PNewClassName = 'New class name:';
  lisA2PPalettePage = 'Palette Page:';
  lisA2PUnitFileName2 = 'Unit File Name:';
  lisA2PUnitName = 'Unit Name:';
  lisA2PFileName = 'File name:';
  
  // broken dependencies dialog
  lisBDDChangingThePackageNameOrVersionBreaksDependencies = 'Changing the '
    +'package name or version breaks dependencies. Should these dependencies '
    +'be changed as well?%sSelect Yes to change all listed dependencies.%'
    +'sSelect Ignore to break the dependencies and continue.';
  lisA2PDependency = 'Dependency';
  lisA2PBrokenDependencies = 'Broken Dependencies';
  
  // open installed packages dialog
  lisOIPFilename = 'Filename:  %s';
  lisOIPThisPackageWasAutomaticallyCreated = '%sThis package was '
    +'automatically created';
  lisOIPThisPackageIsInstalledButTheLpkFileWasNotFound = '%sThis package is '
    +'installed, but the lpk file was not found';
  lisOIPDescriptionDescription = '%sDescription:  %s';
  lisOIPDescription = 'Description:  ';
  lisOIPPleaseSelectAPackage = 'Please select a package';
  lisOIPNoPackageSelected = 'No package selected';
  lisOIPPleaseSelectAPackageToOpen = 'Please select a package to open';
  lisOIPPackageName = 'Package Name';
  lisOIPState = 'State';
  lisOIPmodified = 'modified';
  lisOIPmissing = 'missing';
  lisOIPinstalledStatic = 'installed static';
  lisOIPinstalledDynamic = 'installed dynamic';
  lisOIPautoInstallStatic = 'auto install static';
  lisOIPautoInstallDynamic = 'auto install dynamic';
  lisOIPreadonly = 'readonly';
  lisOIPOpenLoadedPackage = 'Open loaded package';
  
  // package editor
  lisPckEditRemoveFile = 'Remove file';
  lisPckEditReAddFile = 'Re-Add file';
  lisPckEditRemoveDependency = 'Remove dependency';
  lisPckEditMoveDependencyUp = 'Move dependency up';
  lisPckEditMoveDependencyDown = 'Move dependency down';
  lisPckEditReAddDependency = 'Re-Add dependency';
  lisPckEditCompile = 'Compile';
  lisPckEditRecompileClean = 'Recompile clean';
  lisPckEditRecompileAllRequired = 'Recompile all required';
  lisPckEditInstall = 'Install';
  lisPckEditUninstall = 'Uninstall';
  lisPckEditGeneralOptions = 'General Options';
  lisPckEditSaveChanges = 'Save Changes?';
  lisPckEditPackageHasChangedSavePackage = 'Package %s%s%s has changed.%sSave '
    +'package?';
  lisPckEditPage = '%s, Page: %s';
  lisPckEditRemoveFile2 = 'Remove file?';
  lisPckEditRemoveFileFromPackage = 'Remove file %s%s%s%sfrom package %s%s%s?';
  lisPckEditRemoveDependency2 = 'Remove Dependency?';
  lisPckEditRemoveDependencyFromPackage = 'Remove dependency %s%s%s%sfrom '
    +'package %s%s%s?';
  lisPckEditInvalidMinimumVersion = 'Invalid minimum version';
  lisPckEditTheMinimumVersionIsNotAValidPackageVersion = 'The minimum '
    +'version %s%s%s is not a valid package version.%s(good example 1.2.3.4)';
  lisPckEditInvalidMaximumVersion = 'Invalid maximum version';
  lisPckEditTheMaximumVersionIsNotAValidPackageVersion = 'The maximum '
    +'version %s%s%s is not a valid package version.%s(good example 1.2.3.4)';
  lisPckEditCompileEverything = 'Compile everything?';
  lisPckEditReCompileThisAndAllRequiredPackages = 'Re-Compile this and all '
    +'required packages?';
  lisPckEditCompilerOptionsForPackage = 'Compiler Options for Package %s';
  lisPckEditSavePackage = 'Save package';
  lisPckEditCompilePackage = 'Compile package';
  lisPckEditAddAnItem = 'Add an item';
  lisPckEditRemoveSelectedItem = 'Remove selected item';
  lisPckEditInstallPackageInTheIDE = 'Install package in the IDE';
  lisPckEditEditGeneralOptions = 'Edit General Options';
  lisPckEditCompOpts = 'Compiler Options';
  lisPckEditHelp = 'Help';
  lisPkgEdThereAreMoreFunctionsInThePopupmenu = 'There are more functions in '
    +'the popupmenu';
  lisPckEditMore = 'More ...';
  lisPckEditEditOptionsToCompilePackage = 'Edit Options to compile package';
  lisPckEditRequiredPackages = 'Required Packages';
  lisPckEditFileProperties = 'File Properties';
  lisPckEditRegisterUnit = 'Register unit';
  lisPckEditCallRegisterProcedureOfSelectedUnit = 'Call %sRegister%s '
    +'procedure of selected unit';
  lisPckEditRegisteredPlugins = 'Registered plugins';
  lisPckEditMinimumVersion = 'Minimum Version:';
  lisPckEditMaximumVersion = 'Maximum Version:';
  lisPckEditApplyChanges = 'Apply changes';
  lisPckEditPackage = 'Package %s';
  lisPckEditRemovedFilesTheseEntriesAreNotSavedToTheLpkFile = 'Removed Files ('
    +'these entries are not saved to the lpk file)';
  lisPckEditRemovedRequiredPackagesTheseEntriesAreNotSaved = 'Removed '
    +'required packages (these entries are not saved to the lpk file)';
  lisPckEditDependencyProperties = 'Dependency Properties';
  lisPckEditpackageNotSaved = 'package %s not saved';
  lisPckEditReadOnly = 'Read Only: %s';
  lisPckEditModified = 'Modified: %s';
  lisPkgEditNewUnitNotInUnitpath = 'New unit not in unitpath';
  lisPkgEditTheFileIsCurrentlyNotInTheUnitpathOfThePackage = 'The file %s%s%s%'
    +'sis currently not in the unitpath of the package.%s%sAdd %s%s%s to '
    +'UnitPath?';
  lisPkgEditRevertPackage = 'Revert package?';
  lisPkgEditDoYouReallyWantToForgetAllChangesToPackageAnd = 'Do you really '
    +'want to forget all changes to package %s and reload it from file?';

  // package options dialog
  lisPckOptsUsage = 'Usage';
  lisPckOptsIDEIntegration = 'IDE Integration';
  lisPckOptsDescriptionAbstract = 'Description/Abstract';
  lisPckOptsAuthor = 'Author:';
  lisPckOptsLicense = 'License:';
  lisPckOptsMajor = 'Major';
  lisPckOptsMinor = 'Minor';
  lisPckOptsRelease = 'Release';
  lisPckOptsAutomaticallyIncrementVersionOnBuild = 'Automatically increment '
    +'version on build';
  lisPckOptsPackageType = 'PackageType';
  lisPckOptsDesigntimeOnly = 'Designtime only';
  lisPckOptsRuntimeOnly = 'Runtime only';
  lisPckOptsDesigntimeAndRuntime = 'Designtime and Runtime';
  lisPckOptsUpdateRebuild = 'Update/Rebuild';
  lisPckOptsAutomaticallyRebuildAsNeeded = 'Automatically rebuild as needed';
  lisPckOptsAutoRebuildWhenRebuildingAll = 'Auto rebuild when rebuilding all';
  lisPckOptsManualCompilationNeverAutomatically = 'Manual compilation (never '
    +'automatically)';
  lisPckOptsAddPathsToDependentPackagesProjects = 'Add paths to dependent '
    +'packages/projects';
  lisPckOptsInclude = 'Include';
  lisPckOptsObject = 'Object';
  lisPckOptsLibrary = 'Library';
  lisPckOptsAddOptionsToDependentPackagesAndProjects = 'Add options to '
    +'dependent packages and projects';
  lisPckOptsLinker = 'Linker';
  lisPckOptsCustom = 'Custom';
  lisPckOptsInvalidPackageType = 'Invalid package type';
  lisPckOptsThePackageHasTheAutoInstallFlagThisMeans = 'The package %s%s%s '
    +'has the auto install flag.%sThis means it will be installed in the IDE. '
    +'Installation packages%smust be designtime Packages.';
  lisPckOptsPackageOptions = 'Package Options';

  // package explorer (package graph)
  lisPckExplLoadedPackages = 'Loaded Packages:';
  lisPckExplIsRequiredBy = 'Is required by:';
  lisPckExplPackageNotFound = 'Package %s not found';
  lisPckExplState = '%sState: ';
  lisPckExplAutoCreated = 'AutoCreated';
  lisPckExplInstalled = 'Installed';
  lisPckExplInstallOnNextStart = 'Install on next start';
  lisPckExplUninstallOnNextStart = 'Uninstall on next start';
  
  // project inspector
  lisProjInspConfirmDeletingDependency = 'Confirm deleting dependency';
  lisProjInspConfirmRemovingFile = 'Confirm removing file';
  lisProjInspDeleteDependencyFor = 'Delete dependency for %s?';
  lisProjInspRemoveFileFromProject = 'Remove file %s from project?';
  lisProjInspRemovedRequiredPackages = 'Removed required packages';
  lisProjInspProjectInspector = 'Project Inspector - %s';
  
  
  // --------------------------------------------------------//
  // Menu editor -> form captions, labels and context menu --//
  // --------------------------------------------------------//

  lisMenuEditorMenuEditor = 'Menu Editor';
  lisMenuEditorSelectMenu = 'Select Menu:';
  lisMenuEditorSelectTemplate = 'Select Template:';
  lisMenuEditorTemplatePreview = 'Template Preview';
  lisMenuEditorNewTemplateDescription = 'New Template Description...';
  lisMenuEditorCancel = 'Cancel';
  lisMenuEditorInsertNewItemAfter = 'Insert New Item (after)';
  lisMenuEditorInsertNewItemBefore = 'Insert New Item (before)';
  lisMenuEditorDeleteItem = 'Delete Item';
  lisMenuEditorCreateSubMenu = 'Create Submenu';
  lisMenuEditorHandleOnClickEvent = 'Handle OnCLick Event';
  lisMenuEditorMoveUp = 'Move Up(left)';
  lisMenuEditorMoveDown = 'Move Up(right)';
  lisMenuEditorInsertFromTemplate = 'Insert From Template...';
  lisMenuEditorSaveAsTemplate = 'Save As Template...';
  lisMenuEditorDeleteFromTemplate = 'Delete From Template...';

  // --------------------------------//
  // Menu editor -> menu templates --//
  // --------------------------------//

  //Standard File menu
  lisMenuTemplateDescriptionStandardFileMenu = 'Standard File Menu';
  lisMenuTemplateFile = 'File';
  lisMenuTemplateNew = 'New';
  lisMenuTemplateOpen = 'Open';
  lisMenuTemplateOpenRecent = 'Open Recent';
  lisMenuTemplateSave = 'Save';
  lisMenuTemplateSaveAs = 'Save As';
  lisMenuTemplateClose = 'Close';
  lisMenuTemplateExit = 'Exit';

  //Standard Edit menu
  lisMenuTemplateDescriptionStandardEditMenu = 'Standard Edit Menu';
  lisMenuTemplateEdit = 'Edit';
  lisMenuTemplateUndo = 'Undo';
  lisMenuTemplateRedo = 'Redo';
  lisMenuTemplateCut = 'Cut';
  lisMenuTemplateCopy = 'Copy';
  lisMenuTemplatePaste = 'Paste';
  lisMenuTemplateFind = 'Find';
  lisMenuTemplateFindNext = 'Find Next';

  //Standard Help menu
  lisMenuTemplateDescriptionStandardHelpMenu = 'Standard Help Menu';
  lisMenuTemplateHelp = 'Help';
  lisMenuTemplateContents = 'Contents';
  lisMenuTemplateTutorial = 'Tutorial';
  lisMenuTemplateAbout = 'About';

implementation
end.

