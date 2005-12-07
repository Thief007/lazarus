{  $Id$  }
{
 /***************************************************************************
                    mainbase.pas  -  the "integrated" in IDE
                    ----------------------------------------
  TMainIDEBase is the ancestor of TMainIDE. The various top level parts of the
  IDE (called bosses/managers) access the TMainIDE via TMainIDEBase.
  

  main.pp      - TMainIDE = class(TMainIDEBase)
                   The highest manager/boss of the IDE. Only lazarus.pp uses
                   this unit.
  mainbase.pas - TMainIDEBase = class(TMainIDEInterface)
                   The ancestor class used by (and only by) the other
                   bosses/managers like debugmanager, pkgmanager.
  mainintf.pas - TMainIDEInterface = class(TLazIDEInterface)
                   The interface class of the top level functions of the IDE.
                   TMainIDEInterface is used by functions/units, that uses
                   several different parts of the IDE (designer, source editor,
                   codetools), so they can't be added to a specific boss and
                   which are yet too small to become a boss of their own.
  lazideintf.pas - TLazIDEInterface = class(TComponent)
                   For designtime packages, this is the interface class of the
                   top level functions of the IDE.

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
unit MainBase;

{$mode objfpc}{$H+}

interface

{$I ide.inc}

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  Classes, LCLType, LCLIntf, StdCtrls, Buttons, Menus, ComCtrls, SysUtils,
  Controls, Graphics, ExtCtrls, Dialogs, FileUtil, Forms, CodeToolManager,
  CodeCache, AVL_Tree, SynEditKeyCmds,
  // IDE
  LazConf, LazarusIDEStrConsts, SrcEditorIntf, LazIDEIntf, MenuIntf,
  IDECommands,
  ProjectDefs, Project, PublishModule, BuildLazDialog, Compiler,
  ComponentReg,
  TransferMacros, ObjectInspector, PropEdits, OutputFilter, IDEDefs, MsgView,
  EnvironmentOpts, EditorOptions, CompilerOptions, KeyMapping, IDEProcs,
  Debugger, IDEOptionDefs, CodeToolsDefines, Splash, Designer,
  UnitEditor, MainBar, MainIntf;

type
  { TMainIDEBase }

  TMainIDEBase = class(TMainIDEInterface)
  private
    FToolStatus: TIDEToolStatus;
  protected
    CurrentParsedCompilerOption: TParsedCompilerOptions;
    TheCompiler: TCompiler;
    TheOutputFilter: TOutputFilter;
    OwningComponent: TComponent;

    function CreateMenuSeparator : TMenuItem;
    procedure CreateMenuItem(Section: TIDEMenuSection;
                             var MenuItem: TIDEMenuCommand;
                             const MenuItemName, MenuItemCaption: String;
                             const bmpName: String = '';
                             mnuEnabled: Boolean = true);
    procedure CreateMenuSeparatorSection(ParentSection: TIDEMenuSection;
                             var Section: TIDEMenuSection; const AName: String);
    procedure CreateMenuSubSection(ParentSection: TIDEMenuSection;
                             var Section: TIDEMenuSection;
                             const AName, ACaption: String;
                             const bmpName: String = '');
    procedure CreateMainMenuItem(var Section: TIDEMenuSection;
                                 const MenuItemName, MenuItemCaption: String);
    procedure SetupMainMenu; virtual;
    procedure SetupFileMenu; virtual;
    procedure SetupEditMenu; virtual;
    procedure SetupSearchMenu; virtual;
    procedure SetupViewMenu; virtual;
    procedure SetupProjectMenu; virtual;
    procedure SetupRunMenu; virtual;
    procedure SetupComponentsMenu; virtual;
    procedure SetupToolsMenu; virtual;
    procedure SetupEnvironmentMenu; virtual;
    procedure SetupWindowsMenu; virtual;
    procedure SetupHelpMenu; virtual;

    procedure LoadMenuShortCuts; virtual;
    function GetToolStatus: TIDEToolStatus; override;
    procedure SetToolStatus(const AValue: TIDEToolStatus); virtual;
    
    procedure mnuWindowsItemClick(Sender: TObject); virtual;
    procedure OnMainBarDestroy(Sender: TObject); virtual;
  public
    property ToolStatus: TIDEToolStatus read FToolStatus write SetToolStatus;

    constructor Create(TheOwner: TComponent); override;
    procedure StartIDE; virtual; abstract;
    destructor Destroy; override;
    procedure CreateOftenUsedForms; virtual; abstract;

    procedure GetUnitInfoForDesigner(ADesigner: TIDesigner;
                              var ActiveSourceEditor: TSourceEditorInterface;
                              var ActiveUnitInfo: TUnitInfo); override;

    procedure GetCurrentUnitInfo(var ActiveSourceEditor: TSourceEditorInterface;
                              var ActiveUnitInfo: TUnitInfo); override;
    procedure GetCurrentUnit(var ActiveSourceEditor: TSourceEditor;
                             var ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure GetUnitWithPageIndex(PageIndex: integer;
          var ActiveSourceEditor: TSourceEditor; var ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure GetDesignerUnit(ADesigner: TDesigner;
          var ActiveSourceEditor: TSourceEditor; var ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure GetObjectInspectorUnit(
          var ActiveSourceEditor: TSourceEditor; var ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure GetUnitWithForm(AForm: TCustomForm;
          var ActiveSourceEditor: TSourceEditor; var ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure GetUnitWithPersistent(APersistent: TPersistent;
          var ActiveSourceEditor: TSourceEditor; var ActiveUnitInfo: TUnitInfo); virtual; abstract;
    function GetSourceEditorForUnitInfo(AnUnitInfo: TUnitInfo): TSourceEditor; virtual; abstract;

    function DoCheckAmbiguousSources(const AFilename: string;
                                     Compiling: boolean): TModalResult; override;
    function DoCheckCreatingFile(const AFilename: string;
                                 CheckReadable: boolean): TModalResult; override;
    function DoDeleteAmbiguousFiles(const Filename:string
                                    ): TModalResult; override;
    function DoCheckUnitPathForAmbiguousPascalFiles(const BaseDir, TheUnitPath,
                                    CompiledExt, ContextDescription: string
                                    ): TModalResult; override;
    function DoOpenMacroFile(Sender: TObject; const AFilename: string
                             ): TModalResult; override;

    procedure UpdateWindowsMenu; override;
    procedure SetRecentSubMenu(Section: TIDEMenuSection; FileList: TStringList;
                               OnClickEvent: TNotifyEvent); override;

    function DoJumpToCodePosition(
                        ActiveSrcEdit: TSourceEditorInterface;
                        ActiveUnitInfo: TUnitInfo;
                        NewSource: TCodeBuffer; NewX, NewY, NewTopLine: integer;
                        AddJumpPoint: boolean): TModalResult; override;
    function DoJumpToCodePos(
                        ActiveSrcEdit: TSourceEditor;
                        ActiveUnitInfo: TUnitInfo;
                        NewSource: TCodeBuffer; NewX, NewY, NewTopLine: integer;
                        AddJumpPoint: boolean): TModalResult; virtual; abstract;
                        
    procedure FindInFilesPerDialog(AProject: TProject); override;
    procedure FindInFiles(AProject: TProject; const FindText: string); override;
  end;

var
  MainIDE: TMainIDEBase;

  ObjectInspector1 : TObjectInspector;
  SourceNotebook : TSourceNotebook;

implementation


type
  TUnitFile = record
    UnitName: string;
    Filename: string;
  end;
  PUnitFile = ^TUnitFile;

function CompareUnitFiles(UnitFile1, UnitFile2: PUnitFile): integer;
begin
  Result:=AnsiCompareText(UnitFile1^.UnitName,UnitFile2^.UnitName);
end;

function CompareUnitNameAndUnitFile(UnitName: PChar;
  UnitFile: PUnitFile): integer;
begin
  Result:=CompareStringPointerI(UnitName,PChar(UnitFile^.UnitName));
end;

{ TMainIDEBase }

procedure TMainIDEBase.mnuWindowsItemClick(Sender: TObject);
var
  i: Integer;
begin
  i:=Screen.CustomFormCount-1;
  while (i>=0) do begin
    if Screen.CustomForms[i].Caption=(Sender as TIDEMenuCommand).Caption then
    begin
      Screen.CustomForms[i].BringToFront;
      break;
    end;
    dec(i);
  end;
end;

procedure TMainIDEBase.OnMainBarDestroy(Sender: TObject);
begin
  //writeln('TMainIDEBase.OnMainBarDestroy');
end;

procedure TMainIDEBase.SetToolStatus(const AValue: TIDEToolStatus);
begin
  if FToolStatus=AValue then exit;
  FToolStatus:=AValue;
  UpdateCaption;
end;

constructor TMainIDEBase.Create(TheOwner: TComponent);
begin
  MainIDE:=Self;
  // Do not own everything in one big component hierachy. Otherwise the
  // notifications slow down everything
  OwningComponent:=TComponent.Create(nil);
  inherited Create(TheOwner);
end;

destructor TMainIDEBase.Destroy;
begin
  FreeThenNil(OwningComponent);
  inherited Destroy;
  MainIDE:=nil;
end;

procedure TMainIDEBase.GetUnitInfoForDesigner(ADesigner: TIDesigner;
  var ActiveSourceEditor: TSourceEditorInterface; var ActiveUnitInfo: TUnitInfo
  );
var
  SrcEdit: TSourceEditor;
begin
  ActiveSourceEditor:=nil;
  ActiveUnitInfo:=nil;
  if ADesigner is TDesigner then begin
    GetDesignerUnit(TDesigner(ADesigner),SrcEdit,ActiveUnitInfo);
    ActiveSourceEditor:=SrcEdit;
  end;
end;

procedure TMainIDEBase.GetCurrentUnitInfo(
  var ActiveSourceEditor: TSourceEditorInterface; var ActiveUnitInfo: TUnitInfo
  );
var
  ASrcEdit: TSourceEditor;
  AnUnitInfo: TUnitInfo;
begin
  GetCurrentUnit(ASrcEdit, AnUnitInfo);
  ActiveSourceEditor:=ASrcEdit;
  ActiveUnitInfo:=AnUnitInfo;
end;

function TMainIDEBase.CreateMenuSeparator : TMenuItem;
begin
  Result := TMenuItem.Create(MainIDEBar);
  Result.Caption := '-';
end;

procedure TMainIDEBase.CreateMenuItem(Section: TIDEMenuSection;
  var MenuItem: TIDEMenuCommand; const MenuItemName, MenuItemCaption: String;
  const bmpName: String; mnuEnabled: Boolean);
begin
  MenuItem:=RegisterIDEMenuCommand(Section,MenuItemName,MenuItemCaption);
  MenuItem.Enabled:=mnuEnabled;
  if bmpName<>'' then
    MenuItem.Bitmap.LoadFromLazarusResource(bmpName);
end;

procedure TMainIDEBase.CreateMenuSeparatorSection(
  ParentSection: TIDEMenuSection; var Section: TIDEMenuSection;
  const AName: String);
begin
  Section:=RegisterIDEMenuSection(ParentSection,AName);
  Section.ChildsAsSubMenu := false;
end;

procedure TMainIDEBase.CreateMenuSubSection(ParentSection: TIDEMenuSection;
  var Section: TIDEMenuSection; const AName, ACaption: String;
  const bmpName: String = '');
begin
  Section:=RegisterIDESubMenu(ParentSection,AName,ACaption);
  if bmpName<>'' then
    Section.Bitmap.LoadFromLazarusResource(bmpName);
end;

procedure TMainIDEBase.CreateMainMenuItem(var Section: TIDEMenuSection;
  const MenuItemName, MenuItemCaption: String);
begin
  Section:=RegisterIDESubMenu(mnuMain,MenuItemName,MenuItemCaption);
end;

procedure TMainIDEBase.SetupMainMenu;
begin
  MainIDEBar.mnuMainMenu := TMainMenu.Create(MainIDEBar);
  with MainIDEBar do begin
    mnuMain:=RegisterIDEMenuRoot('IDEMainMenu',mnuMainMenu.Items);
    CreateMainMenuItem(mnuFile,'File',lisMenuFile);
    CreateMainMenuItem(mnuEdit,'Edit',lisMenuEdit);
    CreateMainMenuItem(mnuSearch,'Search',lisMenuSearch);
    CreateMainMenuItem(mnuView,'View',lisMenuView);
    CreateMainMenuItem(mnuProject,'Project',lisMenuProject);
    CreateMainMenuItem(mnuRun,'Run',lisMenuRun);
    CreateMainMenuItem(mnuComponents,'Components',lisMenuComponents);
    CreateMainMenuItem(mnuTools,'Tools',lisMenuTools);
    CreateMainMenuItem(mnuEnvironment,'Environment',lisMenuEnvironent);
    CreateMainMenuItem(mnuWindows,'Windows',lisMenuWindows);
    CreateMainMenuItem(mnuHelp,'Help',lisMenuHelp);
  end;
end;

procedure TMainIDEBase.SetupFileMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuFile,itmFileNew,'itmFileNew');
    ParentMI:=itmFileNew;

    CreateMenuItem(ParentMI,itmFileNewUnit,'itmFileNewUnit',lisMenuNewUnit,'menu_new');
    CreateMenuItem(ParentMI,itmFileNewForm,'itmFileNewForm',lisMenuNewForm,'menu_new');
    CreateMenuItem(ParentMI,itmFileNewOther,'itmFileNewOther',lisMenuNewOther,'menu_new');

    CreateMenuSeparatorSection(mnuFile,itmFileOpenSave,'itmFileOpenSave');
    ParentMI:=itmFileOpenSave;

    CreateMenuItem(ParentMI,itmFileOpen,'itmFileOpen',lisMenuOpen,'menu_open');
    CreateMenuItem(ParentMI,itmFileRevert,'itmFileRevert',lisMenuRevert,'menu_undo');
    CreateMenuSubSection(ParentMI,itmFileRecentOpen,'itmFileRecentOpen',lisMenuOpenRecent);
    CreateMenuItem(ParentMI,itmFileSave,'itmFileSave',lisMenuSave,'menu_save');
    CreateMenuItem(ParentMI,itmFileSaveAs,'itmFileSaveAs',lisMenuSaveAs,'menu_save');
    CreateMenuItem(ParentMI,itmFileSaveAll,'itmFileSaveAll',lisMenuSaveAll,'menu_save');
    CreateMenuItem(ParentMI,itmFileClose,'itmFileClose',lisMenuClose,'menu_close',false);
    CreateMenuItem(ParentMI,itmFileCloseAll,'itmFileCloseAll',lisMenuCloseAll,'',false);

    CreateMenuSeparatorSection(mnuFile,itmFileDirectories,'itmFileDirectories');
    ParentMI:=itmFileDirectories;

    CreateMenuItem(ParentMI,itmFileCleanDirectory,'itmFileCleanDirectory',lisMenuCleanDirectory);

    CreateMenuSeparatorSection(mnuFile,itmFileIDEStart,'itmFileIDEStart');
    ParentMI:=itmFileIDEStart;

    CreateMenuItem(ParentMI,itmFileRestart,'itmFileRestart',lisMenuRestart);
    CreateMenuItem(ParentMI,itmFileQuit,'itmFileQuit',lisMenuQuit);
  end;
end;

procedure TMainIDEBase.SetupEditMenu;
var
  ParentMI: TIDEMenuSection;
  SubParentMI: TIDEMenuSection;
  SubSubParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuEdit,itmEditReUndo,'itmEditReUndo');
    ParentMI:=itmEditReUndo;
    CreateMenuItem(ParentMI,itmEditUndo,'itmEditUndo',lisMenuUndo,'menu_undo');
    CreateMenuItem(ParentMI,itmEditRedo,'itmEditRedo',lisMenuRedo,'menu_redo');

    CreateMenuSeparatorSection(mnuEdit,itmEditClipboard,'itmEditClipboard');
    ParentMI:=itmEditClipboard;

    CreateMenuItem(ParentMI,itmEditCut,'itmEditCut',lisMenuCut,'menu_cut');
    CreateMenuItem(ParentMI,itmEditCopy,'itmEditCopy',lisMenuCopy,'menu_copy');
    CreateMenuItem(ParentMI,itmEditPaste,'itmEditPaste',lisMenuPaste,'menu_paste');

    CreateMenuSeparatorSection(mnuEdit,itmEditBlockIndentation,'itmEditBlockIndentation');
    ParentMI:=itmEditBlockIndentation;

    CreateMenuItem(ParentMI,itmEditIndentBlock,'itmEditIndentBlock',lisMenuIndentSelection,'menu_indent');
    CreateMenuItem(ParentMI,itmEditUnindentBlock,'itmEditUnindentBlock',lisMenuUnindentSelection,'menu_unindent');
    CreateMenuItem(ParentMI,itmEditEncloseBlock,'itmEditEncloseBlock',lisMenuEncloseSelection);
    CreateMenuItem(ParentMI,itmEditCommentBlock,'itmEditCommentBlock',lisMenuCommentSelection);
    CreateMenuItem(ParentMI,itmEditUncommentBlock,'itmEditUncommentBlock',lisMenuUncommentSelection);
    CreateMenuItem(ParentMI,itmEditConditionalBlock,'itmEditConditionalBlock',lisMenuConditionalSelection);
    CreateMenuItem(ParentMI,itmEditSortBlock,'itmEditSortBlock',lisMenuSortSelection);

    CreateMenuSeparatorSection(mnuEdit,itmEditBlockCharConversion,'itmEditBlockCharConversion');
    ParentMI:=itmEditBlockCharConversion;

    CreateMenuItem(ParentMI,itmEditUpperCaseBlock,'itmEditUpperCaseBlock',lisMenuUpperCaseSelection);
    CreateMenuItem(ParentMI,itmEditLowerCaseBlock,'itmEditLowerCaseBlock',lisMenuLowerCaseSelection);
    CreateMenuItem(ParentMI,itmEditTabsToSpacesBlock,'itmEditTabsToSpacesBlock',lisMenuTabsToSpacesSelection);
    CreateMenuItem(ParentMI,itmEditSelectionBreakLines,'itmEditSelectionBreakLines',lisMenuBeakLinesInSelection);

    CreateMenuSubSection(mnuEdit,itmEditSelect,'itmEditSelect',lisMenuSelect);
    begin
      // select sub menu items
      SubParentMI:=itmEditSelect;
      CreateMenuItem(SubParentMI,itmEditSelectAll,'itmEditSelectAll',lisMenuSelectAll);
      CreateMenuItem(SubParentMI,itmEditSelectToBrace,'itmEditSelectToBrace',lisMenuSelectToBrace);
      CreateMenuItem(SubParentMI,itmEditSelectCodeBlock,'itmEditSelectCodeBlock',lisMenuSelectCodeBlock);
      CreateMenuItem(SubParentMI,itmEditSelectLine,'itmEditSelectLine',lisMenuSelectLine);
      CreateMenuItem(SubParentMI,itmEditSelectParagraph,'itmEditSelectParagraph',lisMenuSelectParagraph);
    end;

    CreateMenuSeparatorSection(mnuEdit,itmEditInsertions,'itmEditInsertions');
    ParentMI:=itmEditInsertions;

    CreateMenuItem(ParentMI,itmEditInsertCharacter,'itmEditInsertCharacter',lisMenuInsertCharacter);
    CreateMenuSubSection(ParentMI,itmEditInsertText,'itmEditInsertText',lisMenuInsertText);
     begin
      // insert text sub menu items
      SubParentMI:=itmEditInsertText;
      CreateMenuSubSection(SubParentMI,itmEditInsertCVSKeyWord,'itmEditInsertCVSKeyWord',lisMenuInsertCVSKeyword);
      begin
        // insert CVS keyword sub menu items
        SubSubParentMI:=itmEditInsertCVSKeyWord;
        CreateMenuItem(SubSubParentMI,itmEditInsertCVSAuthor,'itmEditInsertCVSAuthor','Author');
        CreateMenuItem(SubSubParentMI,itmEditInsertCVSDate,'itmEditInsertCVSDate','Date');
        CreateMenuItem(SubSubParentMI,itmEditInsertCVSHeader,'itmEditInsertCVSHeader','Header');
        CreateMenuItem(SubSubParentMI,itmEditInsertCVSID,'itmEditInsertCVSID','ID');
        CreateMenuItem(SubSubParentMI,itmEditInsertCVSLog,'itmEditInsertCVSLog','Log');
        CreateMenuItem(SubSubParentMI,itmEditInsertCVSName,'itmEditInsertCVSName','Name');
        CreateMenuItem(SubSubParentMI,itmEditInsertCVSRevision,'itmEditInsertCVSRevision','Revision');
        CreateMenuItem(SubSubParentMI,itmEditInsertCVSSource,'itmEditInsertCVSSource','Source');
      end;

      CreateMenuSubSection(SubParentMI,itmEditInsertGeneral,'itmEditInsertGeneral',lisMenuInsertGeneral);
      begin
        // insert general text sub menu items
        SubSubParentMI:=itmEditInsertGeneral;
        CreateMenuItem(SubSubParentMI,itmEditInsertGPLNotice,'itmEditInsertGPLNotice',lisMenuInsertGPLNotice);
        CreateMenuItem(SubSubParentMI,itmEditInsertLGPLNotice,'itmEditInsertLGPLNotice',lisMenuInsertLGPLNotice);
        CreateMenuItem(SubSubParentMI,itmEditInsertUsername,'itmEditInsertUsername',lisMenuInsertUsername);
        CreateMenuItem(SubSubParentMI,itmEditInsertDateTime,'itmEditInsertDateTime',lisMenuInsertDateTime);
        CreateMenuItem(SubSubParentMI,itmEditInsertChangeLogEntry,'itmEditInsertChangeLogEntry',lisMenuInsertChangeLogEntry);
      end;
    end;

    CreateMenuSeparatorSection(mnuEdit,itmEditMenuCodeTools,'itmEditMenuCodeTools');
    ParentMI:=itmEditMenuCodeTools;

    CreateMenuItem(ParentMI,itmEditCompleteCode,'itmEditCompleteCode',lisMenuCompleteCode);
    CreateMenuItem(ParentMI,itmEditExtractProc,'itmEditExtractProc',lisMenuExtractProc);
  end;
end;

procedure TMainIDEBase.SetupSearchMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuSearch,itmSearchFindReplace,'itmSearchFindReplace');
    ParentMI:=itmSearchFindReplace;

    CreateMenuItem(ParentMI,itmSearchFind,'itmSearchFind',lisMenuFind);
    CreateMenuItem(ParentMI,itmSearchFindNext,'itmSearchFindNext',lisMenuFindNext);
    CreateMenuItem(ParentMI,itmSearchFindPrevious,'itmSearchFindPrevious',lisMenuFindPrevious);
    CreateMenuItem(ParentMI,itmSearchFindInFiles,'itmSearchFindInFiles',lisMenuFindInFiles);
    CreateMenuItem(ParentMI,itmSearchReplace,'itmSearchReplace',lisMenuReplace);
    CreateMenuItem(ParentMI,itmIncrementalFind,'itmIncrementalFind',lisMenuIncrementalFind);
    CreateMenuItem(ParentMI,itmGotoLine,'itmGotoLine',lisMenuGotoLine);

    CreateMenuSeparatorSection(mnuSearch,itmJumpings,'itmJumpings');
    ParentMI:=itmJumpings;

    CreateMenuItem(ParentMI,itmJumpBack,'itmJumpBack',lisMenuJumpBack);
    CreateMenuItem(ParentMI,itmJumpForward,'itmJumpForward',lisMenuJumpForward);
    CreateMenuItem(ParentMI,itmAddJumpPoint,'itmAddJumpPoint',lisMenuAddJumpPointToHistory);
    CreateMenuItem(ParentMI,itmJumpHistory,'itmJumpHistory',lisMenuViewJumpHistory);
    CreateMenuItem(ParentMI,itmJumpToNextError,'itmJumpToNextError',lisMenuJumpToNextError);
    CreateMenuItem(ParentMI,itmJumpToPrevError,'itmJumpToPrevError',lisMenuJumpToPrevError);

    CreateMenuSeparatorSection(mnuSearch,itmBookmarks,'itmBookmarks');
    ParentMI:=itmBookmarks;

    CreateMenuItem(ParentMI,itmSetFreeBookmark,'itmSetFreeBookmark',lisMenuSetFreeBookmark);
    CreateMenuItem(ParentMI,itmJumpToNextBookmark,'itmJumpToNextBookmark',lisMenuJumpToNextBookmark);
    CreateMenuItem(ParentMI,itmJumpToPrevBookmark,'itmJumpToPrevBookmark',lisMenuJumpToPrevBookmark);

    CreateMenuSeparatorSection(mnuSearch,itmCodeToolSearches,'itmCodeToolSearches');
    ParentMI:=itmCodeToolSearches;

    CreateMenuItem(ParentMI,itmFindBlockOtherEnd,'itmFindBlockOtherEnd',lisMenuFindBlockOtherEndOfCodeBlock);
    CreateMenuItem(ParentMI,itmFindBlockStart,'itmFindBlockStart',lisMenuFindCodeBlockStart);
    CreateMenuItem(ParentMI,itmFindDeclaration,'itmFindDeclaration',lisMenuFindDeclarationAtCursor);
    CreateMenuItem(ParentMI,itmOpenFileAtCursor,'itmOpenFileAtCursor',lisMenuOpenFilenameAtCursor);
    CreateMenuItem(ParentMI,itmGotoIncludeDirective,'itmGotoIncludeDirective',lisMenuGotoIncludeDirective);
    CreateMenuItem(ParentMI,itmSearchFindIdentifierRefs,'itmSearchFindIdentifierRefs',lisMenuFindIdentifierRefs);
    CreateMenuItem(ParentMI,itmSearchRenameIdentifier,'itmSearchRenameIdentifier',lisMenuRenameIdentifier);
  end;
end;

procedure TMainIDEBase.SetupViewMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuView,itmViewMainWindows,'itmViewMainWindows');
    ParentMI:=itmViewMainWindows;

    CreateMenuItem(ParentMI,itmViewInspector,'itmViewInspector',lisMenuViewObjectInspector);
    CreateMenuItem(ParentMI,itmViewSourceEditor,'itmViewSourceEditor',lisMenuViewSourceEditor);
    CreateMenuItem(ParentMI,itmViewCodeExplorer,'itmViewCodeExplorer',lisMenuViewCodeExplorer);
    CreateMenuItem(ParentMI,itmViewLazDoc,'itmViewLazDoc',lisMenuLazDoc);   //DBlaszijk 5-sep-05

    CreateMenuSeparatorSection(mnuView,itmViewUnitWindows,'itmViewUnitWindows');
    ParentMI:=itmViewUnitWindows;

    CreateMenuItem(ParentMI,itmViewUnits,'itmViewUnits',lisMenuViewUnits);
    CreateMenuItem(ParentMI,itmViewForms,'itmViewForms',lisMenuViewForms);
    CreateMenuItem(ParentMI,itmViewUnitDependencies,'itmViewUnitDependencies',lisMenuViewUnitDependencies);
    CreateMenuItem(ParentMI,itmViewUnitInfo,'itmViewUnitInfo',lisMenuViewUnitInfo);
    CreateMenuItem(ParentMI,itmViewToggleFormUnit,'itmViewToggleFormUnit',lisMenuViewToggleFormUnit);

    CreateMenuSeparatorSection(mnuView,itmViewSecondaryWindows,'itmViewSecondaryWindows');
    ParentMI:=itmViewSecondaryWindows;

    CreateMenuItem(ParentMI,itmViewMessage,'itmViewMessage',lisMenuViewMessages);
    CreateMenuItem(ParentMI,itmViewSearchResults,'itmViewSearchResults',lisMenuViewSearchResults);
    CreateMenuItem(ParentMI,itmViewAnchorEditor,'itmViewAnchorEditor',lisMenuViewAnchorEditor);
    CreateMenuItem(ParentMI,itmViewComponentPalette,'itmViewComponentPalette',lisMenuViewComponentPalette);
    CreateMenuItem(ParentMI,itmViewIDESpeedButtons,'itmViewIDESpeedButtons',lisMenuViewIDESpeedButtons);
    CreateMenuSubSection(ParentMI,itmViewDebugWindows,'itmViewDebugWindows',lisMenuDebugWindows,'menu_debugger');
    begin
      CreateMenuItem(itmViewDebugWindows,itmViewWatches,'itmViewWatches',lisMenuViewWatches,'menu_watches');
      CreateMenuItem(itmViewDebugWindows,itmViewBreakPoints,'itmViewBreakPoints',lisMenuViewBreakPoints,'menu_breakpoints');
      CreateMenuItem(itmViewDebugWindows,itmViewLocals,'itmViewLocals',lisMenuViewLocalVariables,'');
      CreateMenuItem(itmViewDebugWindows,itmViewCallStack,'itmViewCallStack',lisMenuViewCallStack,'menu_callstack');
      CreateMenuItem(itmViewDebugWindows,itmViewDebugOutput,'itmViewDebugOutput',lisMenuViewDebugOutput,'menu_debugoutput');
    end;
  end;
end;

procedure TMainIDEBase.SetupProjectMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuProject,itmProjectNewSection,'itmProjectNewSection');
    ParentMI:=itmProjectNewSection;

    CreateMenuItem(ParentMI,itmProjectNew,'itmProjectNew',lisMenuNewProject);
    CreateMenuItem(ParentMI,itmProjectNewFromFile,'itmProjectNewFromFile',lisMenuNewProjectFromFile);

    CreateMenuSeparatorSection(mnuProject,itmProjectOpenSection,'itmProjectOpenSection');
    ParentMI:=itmProjectOpenSection;

    CreateMenuItem(ParentMI,itmProjectOpen,'itmProjectOpen',lisMenuOpenProject,'menu_openproject');
    CreateMenuSubSection(ParentMI,itmProjectRecentOpen,'itmProjectRecentOpen',lisMenuOpenRecentProject);

    CreateMenuSeparatorSection(mnuProject,itmProjectSaveSection,'itmProjectSaveSection');
    ParentMI:=itmProjectSaveSection;

    CreateMenuItem(ParentMI,itmProjectSave,'itmProjectSave',lisMenuSaveProject);
    CreateMenuItem(ParentMI,itmProjectSaveAs,'itmProjectSaveAs',lisMenuSaveProjectAs);
    CreateMenuItem(ParentMI,itmProjectPublish,'itmProjectPublish',lisMenuPublishProject);

    CreateMenuSeparatorSection(mnuProject,itmProjectWindowSection,'itmProjectWindowSection');
    ParentMI:=itmProjectWindowSection;

    CreateMenuItem(ParentMI,itmProjectInspector,'itmProjectInspector',lisMenuProjectInspector,'menu_projectinspector');
    CreateMenuItem(ParentMI,itmProjectOptions,'itmProjectOptions',lisMenuProjectOptions,'menu_projectoptions');
    CreateMenuItem(ParentMI,itmProjectCompilerOptions,'itmProjectCompilerOptions',lisMenuCompilerOptions);
    CreateMenuItem(ParentMI,itmProjectViewToDos,'itmProjectViewToDos',lisMenuViewProjectTodos);

    CreateMenuSeparatorSection(mnuProject,itmProjectAddRemoveSection,'itmProjectAddRemoveSection');
    ParentMI:=itmProjectAddRemoveSection;

    CreateMenuItem(ParentMI,itmProjectAddTo,'itmProjectAddTo',lisMenuAddToProject);
    CreateMenuItem(ParentMI,itmProjectRemoveFrom,'itmProjectRemoveFrom',lisMenuRemoveFromProject);
    CreateMenuItem(ParentMI,itmProjectViewSource,'itmProjectViewSource',lisMenuViewSource);

    {$IFDEF TRANSLATESTRING}
    CreateMenuSeparatorSection(mnuProject,itmProjectPoFileSection,'itmProjectPoFileSection');
    ParentMI:=itmProjectPoFileSection;
    CreateMenuItem(ParentMI, itmProjectCreatePoFiles,'itmProjectCreatePoFiles', lisMenuCreatePoFile);
    CreateMenuItem(ParentMI, itmProjectCollectPoFiles, 'itmProjectCollectPoFiles', lisMenuCollectPoFil);
    {$ENDIF}
  end;
end;

procedure TMainIDEBase.SetupRunMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuRun,itmRunBuilding,'itmRunBuilding');
    ParentMI:=itmRunBuilding;

    CreateMenuItem(ParentMI,itmRunMenuBuild,'itmRunMenuBuild',lisMenuBuild,'menu_build');
    CreateMenuItem(ParentMI,itmRunMenuBuildAll,'itmRunMenuBuildAll',lisMenuBuildAll,'menu_buildall');
    CreateMenuItem(ParentMI,itmRunMenuAbortBuild,'itmRunMenuAbortBuild',lisMenuAbortBuild);

    CreateMenuSeparatorSection(mnuRun,itmRunnning,'itmRunnning');
    ParentMI:=itmRunnning;

    CreateMenuItem(ParentMI,itmRunMenuRun,'itmRunMenuRun',lisMenuProjectRun,'menu_run');
    CreateMenuItem(ParentMI,itmRunMenuPause,'itmRunMenuPause',lisMenuPause,'menu_pause');
    CreateMenuItem(ParentMI,itmRunMenuStepInto,'itmRunMenuStepInto',lisMenuStepInto,'menu_stepinto');
    CreateMenuItem(ParentMI,itmRunMenuStepOver,'itmRunMenuStepOver',lisMenuStepOver,'menu_stepover');
    CreateMenuItem(ParentMI,itmRunMenuRunToCursor,'itmRunMenuRunToCursor',lisMenuRunToCursor);
    CreateMenuItem(ParentMI,itmRunMenuStop,'itmRunMenuStop',lisMenuStop,'');
    CreateMenuItem(ParentMI,itmRunMenuRunParameters,'itmRunMenuRunParameters',lisMenuRunParameters);
    CreateMenuItem(ParentMI,itmRunMenuResetDebugger,'itmRunMenuResetDebugger',lisMenuResetDebugger);

    CreateMenuSeparatorSection(mnuRun,itmRunBuildingFile,'itmRunBuildingFile');
    ParentMI:=itmRunBuildingFile;

    CreateMenuItem(ParentMI,itmRunMenuBuildFile,'itmRunMenuBuildFile',lisMenuBuildFile);
    CreateMenuItem(ParentMI,itmRunMenuRunFile,'itmRunMenuRunFile',lisMenuRunFile);
    CreateMenuItem(ParentMI,itmRunMenuConfigBuildFile,'itmRunMenuConfigBuildFile',lisMenuConfigBuildFile);

    CreateMenuSeparatorSection(mnuRun,itmRunDebugging,'itmRunDebugging');
    ParentMI:=itmRunDebugging;

    CreateMenuItem(ParentMI,itmRunMenuInspect,'itmRunMenuInspect',lisMenuInspect, '', False);
    CreateMenuItem(ParentMI,itmRunMenuEvaluate,'itmRunMenuEvaluate',lisMenuEvaluate, '', False);
    CreateMenuItem(ParentMI,itmRunMenuAddWatch,'itmRunMenuAddWatch',lisMenuAddWatch, '', False);
    CreateMenuSubSection(ParentMI,itmRunMenuAddBreakpoint,'itmRunMenuAddBreakpoint',lisMenuAddBreakpoint, '');
      CreateMenuItem(itmRunMenuAddBreakpoint,itmRunMenuAddBPSource,'itmRunMenuAdddBPSource',lisMenuAddBPSource, '', False);
  end;
end;

procedure TMainIDEBase.SetupComponentsMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuComponents,itmPkgOpening,'itmPkgOpening');
    ParentMI:=itmPkgOpening;

    CreateMenuItem(ParentMI,itmPkgOpenPackage,'itmPkgOpenPackage',lisMenuOpenPackage,'pkg_package');
    CreateMenuItem(ParentMI,itmPkgOpenPackageFile,'itmPkgOpenPackageFile',lisMenuOpenPackageFile,'pkg_package');
    CreateMenuItem(ParentMI,itmPkgOpenPackageOfCurUnit,'itmPkgOpenPackageOfCurUnit',lisMenuOpenPackageOfCurUnit,'pkg_package');
    CreateMenuSubSection(ParentMI,itmPkgOpenRecent,'itmPkgOpenRecent',lisMenuOpenRecentPkg,'pkg_package');

    CreateMenuSeparatorSection(mnuComponents,itmPkgUnits,'itmPkgUnits');
    ParentMI:=itmPkgUnits;

    CreateMenuItem(ParentMI,itmPkgAddCurUnitToPkg,'itmPkgAddCurUnitToPkg',lisMenuAddCurUnitToPkg,'pkg_addunittopackage');

    CreateMenuSeparatorSection(mnuComponents,itmPkgGraphSection,'itmPkgGraphSection');
    ParentMI:=itmPkgGraphSection;

    CreateMenuItem(ParentMI,itmPkgPkgGraph,'itmPkgPkgGraph',lisMenuPackageGraph,'pkg_packagegraph');
    CreateMenuItem(ParentMI,itmPkgEditInstallPkgs,'itmPkgEditInstallPkgs',lisMenuEditInstallPkgs,'pkg_package_install');

    {$IFDEF CustomIDEComps}
    CreateMenuItem(ParentMI,itmCompsConfigCustomComps,'itmCompsConfigCustomComps',lisMenuConfigCustomComps);
    {$ENDIF}
  end;
end;

procedure TMainIDEBase.SetupToolsMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuTools,itmCustomTools,'itmCustomTools');
    ParentMI:=itmCustomTools;

    CreateMenuItem(ParentMI,itmToolConfigure,'itmToolConfigure',lisMenuSettings);

    CreateMenuSeparatorSection(mnuTools,itmCodeToolChecks,'itmCodeToolChecks');
    ParentMI:=itmCodeToolChecks;

    CreateMenuItem(ParentMI,itmToolSyntaxCheck,'itmToolSyntaxCheck',lisMenuQuickSyntaxCheck);
    CreateMenuItem(ParentMI,itmToolGuessUnclosedBlock,'itmToolGuessUnclosedBlock',lisMenuGuessUnclosedBlock);
    CreateMenuItem(ParentMI,itmToolGuessMisplacedIFDEF,'itmToolGuessMisplacedIFDEF',lisMenuGuessMisplacedIFDEF);

    CreateMenuSeparatorSection(mnuTools,itmSecondaryTools,'itmSecondaryTools');
    ParentMI:=itmSecondaryTools;

    CreateMenuItem(ParentMI,itmToolMakeResourceString,'itmToolMakeResourceString',lisMenuMakeResourceString);
    CreateMenuItem(ParentMI,itmToolDiff,'itmToolDiff',lisMenuDiff);

    CreateMenuSeparatorSection(mnuTools,itmDelphiConversion,'itmDelphiConversion');
    ParentMI:=itmDelphiConversion;

    CreateMenuItem(ParentMI,itmToolCheckLFM,'itmToolCheckLFM',lisMenuCheckLFM);
    CreateMenuItem(ParentMI,itmToolConvertDelphiUnit,'itmToolConvertDelphiUnit',lisMenuConvertDelphiUnit);
    CreateMenuItem(ParentMI,itmToolConvertDelphiProject,'itmToolConvertDelphiProject',lisMenuConvertDelphiProject);
    CreateMenuItem(ParentMI,itmToolConvertDFMtoLFM,'itmToolConvertDFMtoLFM',lisMenuConvertDFMtoLFM);

    CreateMenuSeparatorSection(mnuTools,itmBuildingLazarus,'itmBuildingLazarus');
    ParentMI:=itmBuildingLazarus;

    CreateMenuItem(ParentMI,itmToolBuildLazarus,'itmToolBuildLazarus',lisMenuBuildLazarus,'menu_buildlazarus');
    CreateMenuItem(ParentMI,itmToolConfigureBuildLazarus,'itmToolConfigureBuildLazarus',lisMenuConfigureBuildLazarus);
  end;
end;

procedure TMainIDEBase.SetupEnvironmentMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuEnvironment,itmOptionsDialogs,'itmOptionsDialogs');
    ParentMI:=itmOptionsDialogs;

    CreateMenuItem(ParentMI,itmEnvGeneralOptions,'itmEnvGeneralOptions',
                   lisMenuGeneralOptions,'menu_environmentoptions');
    CreateMenuItem(ParentMI,itmEnvEditorOptions,'itmEnvEditorOptions',
                   lisMenuEditorOptions,'menu_editoroptions');
    CreateMenuItem(ParentMI,itmEnvCodeTemplates,'itmEnvCodeTemplates',
                   lisMenuEditCodeTemplates,'');
    CreateMenuItem(ParentMI,itmEnvDebuggerOptions,'itmEnvDebuggerOptions',
                   lisMenDebuggerOptions,'');
    CreateMenuItem(ParentMI,itmEnvCodeToolsOptions,'itmEnvCodeToolsOptions',
                   lisMenuCodeToolsOptions,'menu_codetoolsoptions');
    CreateMenuItem(ParentMI,itmEnvCodeToolsDefinesEditor,
                   'itmEnvCodeToolsDefinesEditor',lisMenuCodeToolsDefinesEditor,
                   'menu_codetoolsdefineseditor');

    CreateMenuSeparatorSection(mnuEnvironment,itmIDECacheSection,'itmIDECacheSection');
    ParentMI:=itmIDECacheSection;

    CreateMenuItem(ParentMI,itmEnvRescanFPCSrcDir,'itmEnvRescanFPCSrcDir',
                   lisMenuRescanFPCSourceDirectory);
  end;
end;

procedure TMainIDEBase.SetupWindowsMenu;
begin

end;

procedure TMainIDEBase.SetupHelpMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuHelp,itmOnlineHelps,'itmOnlineHelps');
    ParentMI:=itmOnlineHelps;

    CreateMenuItem(ParentMI,itmHelpOnlineHelp,'itmHelpOnlineHelp',
                   lisMenuOnlineHelp);
    CreateMenuItem(ParentMI,itmHelpConfigureHelp,'itmHelpConfigureHelp',
                   lisMenuConfigureHelp);

    CreateMenuSeparatorSection(mnuHelp,itmInfoHelps,'itmInfoHelps');
    ParentMI:=itmInfoHelps;

    CreateMenuItem(ParentMI,itmHelpAboutLazarus,'itmHelpAboutLazarus',
                   lisMenuAboutLazarus);
  end;
end;

procedure TMainIDEBase.LoadMenuShortCuts;

  function GetCommand(ACommand: word): TIDECommand;
  begin
    Result:=IDECommandList.FindIDECommand(ACommand);
  end;

begin
  with MainIDEBar do begin
    // file menu
    itmFileNewUnit.Command:=GetCommand(ecNewUnit);
    itmFileNewForm.Command:=GetCommand(ecNewForm);
    itmFileNewOther.Command:=GetCommand(ecNew);
    itmFileOpen.Command:=GetCommand(ecOpen);
    itmFileRevert.Command:=GetCommand(ecRevert);
    itmFileSave.Command:=GetCommand(ecSave);
    itmFileSaveAs.Command:=GetCommand(ecSaveAs);
    itmFileSaveAll.Command:=GetCommand(ecSaveAll);
    itmFileClose.Command:=GetCommand(ecClose);
    itmFileCloseAll.Command:=GetCommand(ecCloseAll);
    itmFileCleanDirectory.Command:=GetCommand(ecCleanDirectory);
    itmFileQuit.Command:=GetCommand(ecQuit);
    itmFileQuit.Command:=GetCommand(ecQuit);

    // edit menu
    itmEditUndo.Command:=GetCommand(ecUndo);
    itmEditRedo.Command:=GetCommand(ecRedo);
    itmEditCut.Command:=GetCommand(ecCut);
    itmEditCopy.Command:=GetCommand(ecCopy);
    itmEditPaste.Command:=GetCommand(ecPaste);
    itmEditIndentBlock.Command:=GetCommand(ecBlockIndent);
    itmEditUnindentBlock.Command:=GetCommand(ecBlockUnindent);
    itmEditEncloseBlock.Command:=GetCommand(ecSelectionEnclose);
    itmEditUpperCaseBlock.Command:=GetCommand(ecSelectionUpperCase);
    itmEditLowerCaseBlock.Command:=GetCommand(ecSelectionLowerCase);
    itmEditTabsToSpacesBlock.Command:=GetCommand(ecSelectionTabs2Spaces);
    itmEditCommentBlock.Command:=GetCommand(ecSelectionComment);
    itmEditUncommentBlock.Command:=GetCommand(ecSelectionUncomment);
    itmEditConditionalBlock.Command:=GetCommand(ecSelectionConditional);
    itmEditSortBlock.Command:=GetCommand(ecSelectionSort);
    itmEditSelectionBreakLines.Command:=GetCommand(ecSelectionBreakLines);
    itmEditSelectAll.Command:=GetCommand(ecSelectAll);
    itmEditSelectToBrace.Command:=GetCommand(ecSelectToBrace);
    itmEditSelectCodeBlock.Command:=GetCommand(ecSelectCodeBlock);
    itmEditSelectLine.Command:=GetCommand(ecSelectLine);
    itmEditSelectParagraph.Command:=GetCommand(ecSelectParagraph);
    itmEditCompleteCode.Command:=GetCommand(ecCompleteCode);
    itmEditExtractProc.Command:=GetCommand(ecExtractProc);

    itmEditInsertCVSAuthor.Command:=GetCommand(ecInsertCVSAuthor);
    itmEditInsertCVSDate.Command:=GetCommand(ecInsertCVSDate);
    itmEditInsertCVSHeader.Command:=GetCommand(ecInsertCVSHeader);
    itmEditInsertCVSID.Command:=GetCommand(ecInsertCVSID);
    itmEditInsertCVSLog.Command:=GetCommand(ecInsertCVSLog);
    itmEditInsertCVSName.Command:=GetCommand(ecInsertCVSName);
    itmEditInsertCVSRevision.Command:=GetCommand(ecInsertCVSRevision);
    itmEditInsertCVSSource.Command:=GetCommand(ecInsertCVSSource);

    itmEditInsertGPLNotice.Command:=GetCommand(ecInsertGPLNotice);
    itmEditInsertLGPLNotice.Command:=GetCommand(ecInsertLGPLNotice);
    itmEditInsertUsername.Command:=GetCommand(ecInsertUserName);
    itmEditInsertDateTime.Command:=GetCommand(ecInsertDateTime);
    itmEditInsertChangeLogEntry.Command:=GetCommand(ecInsertChangeLogEntry);

    // search menu
    itmSearchFind.Command:=GetCommand(ecFind);
    itmSearchFindNext.Command:=GetCommand(ecFindNext);
    itmSearchFindPrevious.Command:=GetCommand(ecFindPrevious);
    itmSearchFindInFiles.Command:=GetCommand(ecFindInFiles);
    itmSearchFindIdentifierRefs.Command:=GetCommand(ecFindIdentifierRefs);
    itmSearchReplace.Command:=GetCommand(ecReplace);
    itmSearchRenameIdentifier.Command:=GetCommand(ecRenameIdentifier);
    itmIncrementalFind.Command:=GetCommand(ecIncrementalFind);
    itmGotoLine.Command:=GetCommand(ecGotoLineNumber);
    itmJumpBack.Command:=GetCommand(ecJumpBack);
    itmJumpForward.Command:=GetCommand(ecJumpForward);
    itmAddJumpPoint.Command:=GetCommand(ecAddJumpPoint);
    itmJumpHistory.Command:=GetCommand(ecViewJumpHistory);
    itmJumpToNextError.Command:=GetCommand(ecJumpToNextError);
    itmJumpToPrevError.Command:=GetCommand(ecJumpToPrevError);
    itmSetFreeBookmark.Command:=GetCommand(ecSetFreeBookmark);
    itmJumpToNextBookmark.Command:=GetCommand(ecNextBookmark);
    itmJumpToPrevBookmark.Command:=GetCommand(ecPrevBookmark);
    itmFindBlockOtherEnd.Command:=GetCommand(ecFindBlockOtherEnd);
    itmFindBlockStart.Command:=GetCommand(ecFindBlockStart);
    itmFindDeclaration.Command:=GetCommand(ecFindDeclaration);
    itmOpenFileAtCursor.Command:=GetCommand(ecOpenFileAtCursor);
    itmGotoIncludeDirective.Command:=GetCommand(ecGotoIncludeDirective);

    // view menu
    itmViewInspector.Command:=GetCommand(ecToggleObjectInsp);
    itmViewSourceEditor.Command:=GetCommand(ecToggleSourceEditor);
    itmViewUnits.Command:=GetCommand(ecViewUnits);
    itmViewCodeExplorer.Command:=GetCommand(ecToggleCodeExpl);
    //itmViewLazDoc.Command:=GetCommand(ecLazDoc);   //DBlaszijk 5-sep-05
    itmViewUnitDependencies.Command:=GetCommand(ecViewUnitDependencies);
    itmViewUnitInfo.Command:=GetCommand(ecViewUnitInfo);
    itmViewForms.Command:=GetCommand(ecViewForms);
    itmViewToggleFormUnit.Command:=GetCommand(ecToggleFormUnit);
    itmViewMessage.Command:=GetCommand(ecToggleMessages);
    itmViewSearchResults.Command:=GetCommand(ecToggleSearchResults);
    itmViewAnchorEditor.Command:=GetCommand(ecViewAnchorEditor);
    itmViewComponentPalette.Command:=GetCommand(ecToggleCompPalette);
    itmViewIDESpeedButtons.Command:=GetCommand(ecToggleIDESpeedBtns);

    // project menu
    itmProjectNew.Command:=GetCommand(ecNewProject);
    itmProjectNewFromFile.Command:=GetCommand(ecNewProjectFromFile);
    itmProjectOpen.Command:=GetCommand(ecOpenProject);
    itmProjectSave.Command:=GetCommand(ecSaveProject);
    itmProjectSaveAs.Command:=GetCommand(ecSaveProjectAs);
    itmProjectPublish.Command:=GetCommand(ecPublishProject);
    itmProjectInspector.Command:=GetCommand(ecProjectInspector);
    itmProjectOptions.Command:=GetCommand(ecProjectOptions);
    itmProjectCompilerOptions.Command:=GetCommand(ecCompilerOptions);
    itmProjectAddTo.Command:=GetCommand(ecAddCurUnitToProj);
    itmProjectRemoveFrom.Command:=GetCommand(ecRemoveFromProj);
    itmProjectViewSource.Command:=GetCommand(ecViewProjectSource);

    // run menu
    itmRunMenuBuild.Command:=GetCommand(ecBuild);
    itmRunMenuBuildAll.Command:=GetCommand(ecBuildAll);
    itmRunMenuAbortBuild.Command:=GetCommand(ecAbortBuild);
    itmRunMenuRun.Command:=GetCommand(ecRun);
    itmRunMenuPause.Command:=GetCommand(ecPause);
    itmRunMenuStepInto.Command:=GetCommand(ecStepInto);
    itmRunMenuStepOver.Command:=GetCommand(ecStepOver);
    itmRunMenuRunToCursor.Command:=GetCommand(ecRunToCursor);
    itmRunMenuStop.Command:=GetCommand(ecStopProgram);
    itmRunMenuResetDebugger.Command:=GetCommand(ecResetDebugger);
    itmRunMenuRunParameters.Command:=GetCommand(ecRunParameters);
    itmRunMenuBuildFile.Command:=GetCommand(ecBuildFile);
    itmRunMenuRunFile.Command:=GetCommand(ecRunFile);
    itmRunMenuConfigBuildFile.Command:=GetCommand(ecConfigBuildFile);

    // components menu
    itmPkgOpenPackage.Command:=GetCommand(ecOpenPackage);
    itmPkgOpenPackageFile.Command:=GetCommand(ecOpenPackageFile);
    itmPkgOpenPackageOfCurUnit.Command:=GetCommand(ecOpenPackageOfCurUnit);
    itmPkgAddCurUnitToPkg.Command:=GetCommand(ecAddCurUnitToPkg);
    itmPkgPkgGraph.Command:=GetCommand(ecPackageGraph);
    itmPkgEditInstallPkgs.Command:=GetCommand(ecEditInstallPkgs);
    {$IFDEF CustomIDEComps}
    itmCompsConfigCustomComps.Command:=GetCommand(ecConfigCustomComps);
    {$ENDIF}

    // tools menu
    itmToolConfigure.Command:=GetCommand(ecExtToolSettings);
    itmToolSyntaxCheck.Command:=GetCommand(ecSyntaxCheck);
    itmToolGuessUnclosedBlock.Command:=GetCommand(ecGuessUnclosedBlock);
    itmToolGuessMisplacedIFDEF.Command:=GetCommand(ecGuessMisplacedIFDEF);
    itmToolMakeResourceString.Command:=GetCommand(ecMakeResourceString);
    itmToolDiff.Command:=GetCommand(ecDiff);
    itmToolConvertDFMtoLFM.Command:=GetCommand(ecConvertDFM2LFM);
    itmToolCheckLFM.Command:=GetCommand(ecCheckLFM);
    itmToolConvertDelphiUnit.Command:=GetCommand(ecConvertDelphiUnit);
    itmToolConvertDelphiProject.Command:=GetCommand(ecConvertDelphiProject);
    itmToolBuildLazarus.Command:=GetCommand(ecBuildLazarus);
    itmToolConfigureBuildLazarus.Command:=GetCommand(ecConfigBuildLazarus);

    // environment menu
    itmEnvGeneralOptions.Command:=GetCommand(ecEnvironmentOptions);
    itmEnvEditorOptions.Command:=GetCommand(ecEditorOptions);
    itmEnvCodeTemplates.Command:=GetCommand(ecEditCodeTemplates);
    itmEnvCodeToolsOptions.Command:=GetCommand(ecCodeToolsOptions);
    itmEnvCodeToolsDefinesEditor.Command:=GetCommand(ecCodeToolsDefinesEd);
    itmEnvRescanFPCSrcDir.Command:=GetCommand(ecRescanFPCSrcDir);

    // help menu
    itmHelpAboutLazarus.Command:=GetCommand(ecAboutLazarus);
    itmHelpOnlineHelp.Command:=GetCommand(ecOnlineHelp);
    itmHelpConfigureHelp.Command:=GetCommand(ecConfigureHelp);
  end;
end;

function TMainIDEBase.GetToolStatus: TIDEToolStatus;
begin
  Result:=FToolStatus;
end;

function TMainIDEBase.DoOpenMacroFile(Sender: TObject; const AFilename: string
  ): TModalResult;
begin
  Result:=DoOpenEditorFile(AFilename,-1,
                  [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofConvertMacros]);
end;

{-------------------------------------------------------------------------------
  function TMainIDEBase.DoCheckCreatingFile(const AFilename: string;
    CheckReadable: boolean): TModalResult;
-------------------------------------------------------------------------------}
function TMainIDEBase.DoCheckCreatingFile(const AFilename: string;
  CheckReadable: boolean): TModalResult;
var
  fs: TFileStream;
  c: char;
begin
  // create if not yet done
  if not FileExists(AFilename) then begin
    try
      InvalidateFileStateCache;
      fs:=TFileStream.Create(AFilename,fmCreate);
      fs.Free;
    except
      Result:=MessageDlg(lisUnableToCreateFile,
        Format(lisUnableToCreateFilename, ['"', AFilename, '"']), mtError, [
          mbCancel, mbAbort], 0);
      exit;
    end;
  end;
  // check writable
  try
    if CheckReadable then begin
      InvalidateFileStateCache;
      fs:=TFileStream.Create(AFilename,fmOpenWrite)
    end else
      fs:=TFileStream.Create(AFilename,fmOpenReadWrite);
    try
      fs.Position:=fs.Size;
      fs.Write(' ',1);
    finally
      fs.Free;
    end;
  except
    Result:=MessageDlg(lisUnableToWriteFile,
      Format(lisUnableToWriteFilename, ['"', AFilename, '"']), mtError, [
        mbCancel, mbAbort], 0);
    exit;
  end;
  // check readable
  try
    InvalidateFileStateCache;
    fs:=TFileStream.Create(AFilename,fmOpenReadWrite);
    try
      fs.Position:=fs.Size-1;
      fs.Read(c,1);
    finally
      fs.Free;
    end;
  except
    Result:=MessageDlg(lisUnableToReadFile,
      Format(lisUnableToReadFilename, ['"', AFilename, '"']), mtError, [
        mbCancel, mbAbort], 0);
    exit;
  end;
  Result:=mrOk;
end;

function TMainIDEBase.DoDeleteAmbiguousFiles(const Filename: string
  ): TModalResult;
var
  ADirectory: String;
  FileInfo: TSearchRec;
  ShortFilename: String;
  CurFilename: String;
  IsPascalUnit: Boolean;
  UnitName: String;
begin
  Result:=mrOk;
  if EnvironmentOptions.AmbiguousFileAction=afaIgnore then exit;
  if EnvironmentOptions.AmbiguousFileAction
    in [afaAsk,afaAutoDelete,afaAutoRename]
  then begin
    ADirectory:=AppendPathDelim(ExtractFilePath(Filename));
    if SysUtils.FindFirst(ADirectory+GetAllFilesMask,faAnyFile,FileInfo)=0 then begin
      ShortFilename:=ExtractFileName(Filename);
      IsPascalUnit:=FilenameIsPascalUnit(ShortFilename);
      UnitName:=ExtractFilenameOnly(ShortFilename);
      repeat
        if (FileInfo.Name='.') or (FileInfo.Name='..')
        or (FileInfo.Name='')
        or ((FileInfo.Attr and faDirectory)<>0) then continue;
        if (ShortFilename=FileInfo.Name) then continue;
        if (AnsiCompareText(ShortFilename,FileInfo.Name)<>0)
        and ((not IsPascalUnit) or (not FilenameIsPascalUnit(FileInfo.Name))
           or (AnsiCompareText(UnitName,ExtractFilenameOnly(FileInfo.Name))<>0))
        then
          continue;

        CurFilename:=ADirectory+FileInfo.Name;
        if EnvironmentOptions.AmbiguousFileAction=afaAsk then begin
          if MessageDlg(lisDeleteAmbiguousFile,
            Format(lisAmbiguousFileFoundThisFileCanBeMistakenWithDelete, ['"',
              CurFilename, '"', #13, '"', ShortFilename, '"', #13, #13]),
            mtConfirmation,[mbYes,mbNo],0)=mrNo
          then continue;
        end;
        if EnvironmentOptions.AmbiguousFileAction in [afaAutoDelete,afaAsk]
        then begin
          if not DeleteFile(CurFilename) then begin
            MessageDlg(lisDeleteFileFailed,
              Format(lisPkgMangUnableToDeleteFile, ['"', CurFilename, '"']),
              mtError,[mbOk],0);
          end;
        end else if EnvironmentOptions.AmbiguousFileAction=afaAutoRename then
        begin
          Result:=DoBackupFile(CurFilename,false);
          if Result=mrABort then exit;
          Result:=mrOk;
        end;
      until SysUtils.FindNext(FileInfo)<>0;
    end;
    FindClose(FileInfo);
  end;
end;

{-------------------------------------------------------------------------------
  function TMainIDEBase.DoCheckUnitPathForAmbiguousPascalFiles(
    const BaseDir, TheUnitPath, CompiledExt, ContextDescription: string
    ): TModalResult;

  Collect all pascal files and all compiled units in the unit path and check
  for ambiguous files. For example: doubles.
-------------------------------------------------------------------------------}
function TMainIDEBase.DoCheckUnitPathForAmbiguousPascalFiles(
  const BaseDir, TheUnitPath, CompiledExt, ContextDescription: string): TModalResult;

  procedure FreeUnitTree(var Tree: TAVLTree);
  var
    ANode: TAVLTreeNode;
    AnUnitFile: PUnitFile;
  begin
    if Tree<>nil then begin
      ANode:=Tree.FindLowest;
      while ANode<>nil do begin
        AnUnitFile:=PUnitFile(ANode.Data);
        Dispose(AnUnitFile);
        ANode:=Tree.FindSuccessor(ANode);
      end;
      Tree.Free;
      Tree:=nil;
    end;
  end;

var
  EndPos: Integer;
  StartPos: Integer;
  CurDir: String;
  FileInfo: TSearchRec;
  SourceUnitTree, CompiledUnitTree: TAVLTree;
  ANode: TAVLTreeNode;
  CurUnitName: String;
  CurFilename: String;
  AnUnitFile: PUnitFile;
  CurUnitTree: TAVLTree;
  FileInfoNeedClose: Boolean;
  UnitPath: String;
begin
  Result:=mrOk;
  UnitPath:=TrimSearchPath(TheUnitPath,BaseDir);

  //writeln('TMainIDEBase.DoCheckUnitPathForAmbiguousPascalFiles A UnitPath="',UnitPath,'" Ext=',CompiledExt,' Context=',ContextDescription);

  SourceUnitTree:=TAVLTree.Create(TListSortCompare(@CompareUnitFiles));
  CompiledUnitTree:=TAVLTree.Create(TListSortCompare(@CompareUnitFiles));
  FileInfoNeedClose:=false;
  try
    // collect all units (.pas, .pp, compiled units)
    EndPos:=1;
    while EndPos<=length(UnitPath) do begin
      StartPos:=EndPos;
      while (StartPos<=length(UnitPath)) and (UnitPath[StartPos]=';') do
        inc(StartPos);
      EndPos:=StartPos;
      while (EndPos<=length(UnitPath)) and (UnitPath[EndPos]<>';') do
        inc(EndPos);
      if EndPos>StartPos then begin
        CurDir:=AppendPathDelim(TrimFilename(copy(
                                             UnitPath,StartPos,EndPos-StartPos)));
        FileInfoNeedClose:=true;
        if SysUtils.FindFirst(CurDir+GetAllFilesMask,faAnyFile,FileInfo)=0 then begin
          repeat
            if (FileInfo.Name='.') or (FileInfo.Name='..') or (FileInfo.Name='')
            or ((FileInfo.Attr and faDirectory)<>0) then continue;
            if FilenameIsPascalUnit(FileInfo.Name) then
              CurUnitTree:=SourceUnitTree
            else if (CompareFileExt(FileInfo.Name,CompiledExt,false)=0) then
              CurUnitTree:=CompiledUnitTree
            else
              continue;
            CurUnitName:=ExtractFilenameOnly(FileInfo.Name);
            CurFilename:=CurDir+FileInfo.Name;
            // check if unit already found
            ANode:=CurUnitTree.FindKey(PChar(CurUnitName),
                                 TListSortCompare(@CompareUnitNameAndUnitFile));
            if ANode<>nil then begin
              // pascal unit exists twice
              Result:=MessageDlg('Ambiguous unit found',
                'The unit '+CurUnitName+' exists twice in the unit path of the '
                +ContextDescription+':'#13
                +#13
                +'1. "'+PUnitFile(ANode.Data)^.Filename+'"'#13
                +'2. "'+CurFilename+'"'#13
                +#13
                +'Hint: Check if two packages contain a unit with the same name.',
                mtWarning,[mbAbort,mbIgnore],0);
              if Result<>mrIgnore then exit;
            end;
            // add unit to tree
            New(AnUnitFile);
            AnUnitFile^.UnitName:=CurUnitName;
            AnUnitFile^.Filename:=CurFilename;
            CurUnitTree.Add(AnUnitFile);
          until SysUtils.FindNext(FileInfo)<>0;
        end;
        FindClose(FileInfo);
        FileInfoNeedClose:=false;
      end;
    end;
  finally
    // clean up
    if FileInfoNeedClose then FindClose(FileInfo);
    FreeUnitTree(SourceUnitTree);
    FreeUnitTree(CompiledUnitTree);
  end;
  Result:=mrOk;
end;

{-------------------------------------------------------------------------------
  function TMainIDEBase.DoCheckAmbiguousSources(const AFilename: string
    ): TModalResult;

  Checks if file exists with same name and similar extension. The compiler
  prefers for example .pp to .pas files. So, if we save a .pas file delete .pp
  file, so that compiling does what is expected.
-------------------------------------------------------------------------------}
function TMainIDEBase.DoCheckAmbiguousSources(const AFilename: string;
  Compiling: boolean): TModalResult;

  function DeleteAmbiguousFile(const AmbiguousFilename: string): TModalResult;
  begin
    if not DeleteFile(AmbiguousFilename) then begin
      Result:=MessageDlg(lisErrorDeletingFile,
       Format(lisUnableToDeleteAmbiguousFile, ['"', AmbiguousFilename, '"']),
       mtError,[mbOk,mbAbort],0);
    end else
      Result:=mrOk;
  end;

  function RenameAmbiguousFile(const AmbiguousFilename: string): TModalResult;
  var
    NewFilename: string;
  begin
    NewFilename:=AmbiguousFilename+'.ambiguous';
    if not RenameFile(AmbiguousFilename,NewFilename) then
    begin
      Result:=MessageDlg(lisErrorRenamingFile,
       Format(lisUnableToRenameAmbiguousFileTo, ['"', AmbiguousFilename, '"',
         #13, '"', NewFilename, '"']),
       mtError,[mbOk,mbAbort],0);
    end else
      Result:=mrOk;
  end;

  function AddCompileWarning(const AmbiguousFilename: string): TModalResult;
  begin
    Result:=mrOk;
    if Compiling then begin
      TheOutputFilter.ReadLine(Format(lisWarningAmbiguousFileFoundSourceFileIs,
        ['"', AmbiguousFilename, '"', '"', AFilename, '"']), true);
    end;
  end;

  function CheckFile(const AmbiguousFilename: string): TModalResult;
  begin
    Result:=mrOk;
    if not FileExists(AmbiguousFilename) then exit;
    if Compiling then begin
      Result:=AddCompileWarning(AmbiguousFilename);
      exit;
    end;
    case EnvironmentOptions.AmbiguousFileAction of
    afaAsk:
      begin
        Result:=MessageDlg(lisAmbiguousFileFound,
          Format(lisThereIsAFileWithTheSameNameAndASimilarExtension, [#13,
            AFilename, #13, AmbiguousFilename, #13, #13]),
          mtWarning,[mbYes,mbIgnore,mbAbort],0);
        case Result of
        mrYes:    Result:=DeleteAmbiguousFile(AmbiguousFilename);
        mrIgnore: Result:=mrOk;
        end;
      end;

    afaAutoDelete:
      Result:=DeleteAmbiguousFile(AmbiguousFilename);

    afaAutoRename:
      Result:=RenameAmbiguousFile(AmbiguousFilename);

    afaWarnOnCompile:
      Result:=AddCompileWarning(AmbiguousFilename);

    else
      Result:=mrOk;
    end;
  end;

var
  Ext, LowExt: string;
  i: integer;
begin
  Result:=mrOk;
  if EnvironmentOptions.AmbiguousFileAction=afaIgnore then exit;
  if (EnvironmentOptions.AmbiguousFileAction=afaWarnOnCompile)
  and not Compiling then exit;

  if FilenameIsPascalUnit(AFilename) then begin
    Ext:=ExtractFileExt(AFilename);
    LowExt:=lowercase(Ext);
    for i:=Low(PascalFileExt) to High(PascalFileExt) do begin
      if LowExt<>PascalFileExt[i] then begin
        Result:=CheckFile(ChangeFileExt(AFilename,PascalFileExt[i]));
        if Result<>mrOk then exit;
      end;
    end;
  end;
end;

procedure TMainIDEBase.UpdateWindowsMenu;
var
  WindowsList: TList;
  i: Integer;
  CurMenuItem: TIDEMenuItem;
  AForm: TForm;
begin
  WindowsList:=TList.Create;
  // add typical IDE windows at the start of the list
  if (SourceNotebook<>nil) and (SourceNotebook.Visible) then
    WindowsList.Add(SourceNotebook);
  if (ObjectInspector1<>nil) and (ObjectInspector1.Visible) then
    WindowsList.Add(ObjectInspector1);
  // add special IDE windows
  for i:=0 to Screen.FormCount-1 do begin
    AForm:=Screen.Forms[i];
    if (AForm<>MainIDEBar) and (AForm<>SplashForm)
    and (AForm.Designer=nil) and (AForm.Visible)
    and (WindowsList.IndexOf(AForm)<0) then
      WindowsList.Add(AForm);
  end;
  // add designer forms and datamodule forms
  for i:=0 to Screen.FormCount-1 do begin
    AForm:=Screen.Forms[i];
    if (AForm.Designer<>nil) and (WindowsList.IndexOf(AForm)<0) then
      WindowsList.Add(AForm);
  end;
  // create menuitems
  for i:=0 to WindowsList.Count-1 do begin
    if mnuWindows.Count>i then
      CurMenuItem:=mnuWindows.Items[i]
    else begin
      CurMenuItem:=RegisterIDEMenuCommand(mnuWindows.GetPath,
                                          'Window'+IntToStr(i),'');
      CurMenuItem.OnClick:=@mnuWindowsItemClick;
    end;
    CurMenuItem.Caption:=TCustomForm(WindowsList[i]).Caption;
  end;
  // remove unused menuitems
  while mnuWindows.Count>WindowsList.Count do
    mnuWindows.Items[mnuWindows.Count-1].Free;
  // clean up
  WindowsList.Free;
end;

procedure TMainIDEBase.SetRecentSubMenu(Section: TIDEMenuSection;
  FileList: TStringList; OnClickEvent: TNotifyEvent);
var
  i: integer;
  AMenuItem: TIDEMenuItem;
begin
  // create enough menuitems
  while Section.Count<FileList.Count do begin
    AMenuItem:=RegisterIDEMenuCommand(Section.GetPath,
                              Section.Name+'Recent'+IntToStr(Section.Count),'');
  end;
  // delete unused menuitems
  while Section.Count>FileList.Count do
    Section.Items[Section.Count-1].Free;
  Section.Enabled:=(Section.Count>0);
  // set captions and event
  for i:=0 to FileList.Count-1 do begin
    AMenuItem:=Section.Items[i];
    AMenuItem.Caption := FileList[i];
    AMenuItem.OnClick := OnClickEvent;
  end;
end;

function TMainIDEBase.DoJumpToCodePosition(
  ActiveSrcEdit: TSourceEditorInterface; ActiveUnitInfo: TUnitInfo;
  NewSource: TCodeBuffer; NewX, NewY, NewTopLine: integer; AddJumpPoint: boolean
  ): TModalResult;
var
  SrcEdit: TSourceEditor;
begin
  if ActiveSrcEdit=nil then
    SrcEdit:=nil
  else
    SrcEdit:=ActiveSrcEdit as TSourceEditor;
  Result:=DoJumpToCodePos(SrcEdit as TSourceEditor, ActiveUnitInfo,
                          NewSource, NewX, NewY, NewTopLine, AddJumpPoint);
end;

procedure TMainIDEBase.FindInFilesPerDialog(AProject: TProject);
begin
  SourceNotebook.FindInFilesPerDialog(AProject);
end;

procedure TMainIDEBase.FindInFiles(AProject: TProject; const FindText: string);
begin
  SourceNotebook.FindInFiles(AProject, FindText);
end;

end.

