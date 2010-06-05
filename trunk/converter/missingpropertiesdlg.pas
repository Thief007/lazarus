{  $Id$  }
{
 /***************************************************************************
                            MissingPropertiesDlg.pas
                            ------------------------

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
unit MissingPropertiesDlg;

{$mode objfpc}{$H+}

interface

uses
  // FCL+LCL
  Classes, SysUtils, Math, LCLProc, Forms, Controls, Grids, LResources,
  Graphics, Dialogs, Buttons, StdCtrls, ExtCtrls, contnrs, FileUtil,
  // components
  SynHighlighterLFM, SynEdit, SynEditMiscClasses, LFMTrees,
  // codetools
  BasicCodeTools, CodeCache, CodeToolManager, CodeToolsStructs,
  // IDE
  IDEDialogs, ComponentReg, PackageIntf, IDEWindowIntf, DialogProcs,
  CustomFormEditor, LazarusIDEStrConsts, IDEProcs, OutputFilter,
  EditorOptions, CheckLFMDlg,
  // Converter
  ConvertSettings, ReplaceNamesUnit, ConvCodeTool;

type

  { TDFMConverter }

  // Encapsulates some basic form file conversions.
  TDFMConverter = class
  private
    fOrigFormat: TLRSStreamOriginalFormat;
    function GetLFMFilename(const DfmFilename: string; KeepCase: boolean): string;

  public
    constructor Create;
    destructor Destroy; override;
    function ConvertDfmToLfm(const DfmFilename: string): TModalResult;
    function Convert(const DfmFilename: string): TModalResult;
  end;

  { TLfmFixer }

  TLFMFixer = class(TLFMChecker)
  private
    fSettings: TConvertSettings;
    // There are also unknown object types, not just properties.
    fHasMissingObjectTypes: Boolean;
    // References to controls in UI:
    fPropReplaceGrid: TStringGrid;
    function ReplaceAndRemoveAll: TModalResult;
    // Fill StringGrid with missing properties from fLFMTree.
    procedure FillPropReplaceList;
  protected
    procedure LoadLFM;
    function ShowRepairLFMWizard: TModalResult; override;
  public
    constructor Create(APascalBuffer, ALFMBuffer: TCodeBuffer;
                       const AOnOutput: TOnAddFilteredLine);
    destructor Destroy; override;
    function Repair: TModalResult;
  public
    property Settings: TConvertSettings read fSettings write fSettings;
  end;


  { TFixLFMDialog }

  TFixLFMDialog = class(TForm)
    CancelButton: TBitBtn;
    ErrorsGroupBox: TGroupBox;
    ErrorsListBox: TListBox;
    PropertyReplaceGroupBox: TGroupBox;
    NoteLabel: TLabel;
    LFMGroupBox: TGroupBox;
    LFMSynEdit: TSynEdit;
    BtnPanel: TPanel;
    ReplaceAllButton: TBitBtn;
    Splitter1: TSplitter;
    PropertyReplaceGrid: TStringGrid;
    SynLFMSyn1: TSynLFMSyn;
    procedure ErrorsListBoxClick(Sender: TObject);
    procedure ReplaceAllButtonClick(Sender: TObject);
    procedure LFMSynEditSpecialLineMarkup(Sender: TObject;
      Line: integer; var Special: boolean; AMarkup: TSynSelectedColor);
    procedure CheckLFMDialogCREATE(Sender: TObject);
  private
    fLfmFixer: TLFMFixer;
  public
    constructor Create(AOwner: TComponent; ALfmFixer: TLFMFixer); reintroduce;
    destructor Destroy; override;
  end;


function ConvertDfmToLfm(const DfmFilename: string): TModalResult;


implementation

{$R *.lfm}

function ConvertDfmToLfm(const DfmFilename: string): TModalResult;
var
  DFMConverter: TDFMConverter;
begin
  DFMConverter:=TDFMConverter.Create;
  try     Result:=DFMConverter.ConvertDfmToLfm(DfmFilename);
  finally DFMConverter.Free;
  end;
end;

{ TDFMConverter }

constructor TDFMConverter.Create;
begin
  inherited Create;
end;

destructor TDFMConverter.Destroy;
begin
  inherited Destroy;
end;

function TDFMConverter.Convert(const DfmFilename: string): TModalResult;
begin
  Result:=ConvertDfmToLfm(DfmFilename);
  if Result=mrOK then begin
    if fOrigFormat=sofBinary then
      ShowMessage(Format('File %s is successfully converted to text format.',
                         [DfmFilename]))
    else
      ShowMessage(Format('File %s syntax is correct.', [DfmFilename]));
  end;
end;

function TDFMConverter.GetLFMFilename(const DfmFilename: string;
  KeepCase: boolean): string;
begin
  if DfmFilename<>'' then begin
    // platform and fpc independent unitnames are lowercase, so are the lfm files
    Result:=lowercase(ExtractFilenameOnly(DfmFilename));
    if KeepCase then
      Result:=ExtractFilenameOnly(DfmFilename);
    Result:=ExtractFilePath(DfmFilename)+Result+'.lfm';
  end else
    Result:='';
end;

function TDFMConverter.ConvertDfmToLfm(const DfmFilename: string): TModalResult;
var
  DFMStream, LFMStream: TMemoryStream;
begin
  Result:=mrOk;
  DFMStream:=TMemoryStream.Create;
  LFMStream:=TMemoryStream.Create;
  try
    // Note: The file is copied from DFM file earlier.
    try
      DFMStream.LoadFromFile(UTF8ToSys(DfmFilename));
    except
      on E: Exception do begin
        Result:=QuestionDlg(lisCodeToolsDefsReadError, Format(
          lisUnableToReadFileError, ['"', DfmFilename, '"', #13, E.Message]),
          mtError,[mrIgnore,mrAbort],0);
        if Result=mrIgnore then // The caller will continue like nothing happened.
          Result:=mrOk;
        exit;
      end;
    end;
    fOrigFormat:=TestFormStreamFormat(DFMStream);
    try
      FormDataToText(DFMStream,LFMStream);
    except
      on E: Exception do begin
        Result:=QuestionDlg(lisFormatError,
          Format(lisUnableToConvertFileError, ['"',DfmFilename,'"',#13,E.Message]),
          mtError,[mrIgnore,mrAbort],0);
        if Result=mrIgnore then
          Result:=mrOk;
        exit;
      end;
    end;
    // converting dfm file, without renaming unit -> keep case...
    try
      LFMStream.SaveToFile(UTF8ToSys(DfmFilename));
    except
      on E: Exception do begin
        Result:=MessageDlg(lisCodeToolsDefsWriteError,
          Format(lisUnableToWriteFileError, ['"',DfmFilename,'"',#13,E.Message]),
          mtError,[mbIgnore,mbAbort],0);
        if Result=mrIgnore then
          Result:=mrOk;
        exit;
      end;
    end;
  finally
    LFMSTream.Free;
    DFMStream.Free;
  end;
end;


{ TLFMFixer }

constructor TLFMFixer.Create(APascalBuffer, ALFMBuffer: TCodeBuffer;
  const AOnOutput: TOnAddFilteredLine);
begin
  inherited Create(APascalBuffer, ALFMBuffer, AOnOutput);
  fHasMissingObjectTypes:=false;
end;

destructor TLFMFixer.Destroy;
begin
  inherited Destroy;
end;

function TLFMFixer.ReplaceAndRemoveAll: TModalResult;
// Replace or remove properties and types based on values in grid.
// Returns mrRetry if some types were changed and a new scan is needed,
//         mrOK if no types were changed, and mrCancel if there was an error.
var
  CurError: TLFMError;
  TheNode: TLFMTreeNode;
  ObjNode: TLFMObjectNode;
  // Type name --> replacement name.
  NameReplacements: TStringToStringTree;
  // List of TLFMChangeEntry objects.
  ChgEntryRepl: TObjectList;
  GridUpdater: TGridUpdater;
  OldIdent, NewIdent: string;
  StartPos, EndPos: integer;
begin
  Result:=mrOK;
  ChgEntryRepl:=TObjectList.Create;
  NameReplacements:=TStringToStringTree.Create(false);
  GridUpdater:=TGridUpdater.Create(NameReplacements, fPropReplaceGrid);
  try
    // Collect (maybe edited) properties from StringGrid to NameReplacements.
    GridUpdater.GridToMap;
    // Replace each missing property / type or delete it if no replacement.
    CurError:=fLFMTree.LastError;
    while CurError<>nil do begin
      TheNode:=CurError.FindContextNode;
      if (TheNode<>nil) and (TheNode.Parent<>nil) then begin
        if CurError.IsMissingObjectType then begin
          // Object type
          ObjNode:=CurError.Node as TLFMObjectNode;
          OldIdent:=ObjNode.TypeName;
          NewIdent:=NameReplacements[OldIdent];
          // Keep the old class name if no replacement.
          if NewIdent<>'' then begin
            StartPos:=ObjNode.TypeNamePosition;
            EndPos:=StartPos+Length(OldIdent);
            AddReplacement(ChgEntryRepl,StartPos,EndPos,NewIdent);
            Result:=mrRetry;
          end;
        end
        else begin
          // Property
          TheNode.FindIdentifier(StartPos,EndPos);
          if StartPos>0 then begin
            OldIdent:=copy(fLFMBuffer.Source,StartPos,EndPos-StartPos);
            NewIdent:=NameReplacements[OldIdent];
            // Delete the whole property line if no replacement.
            if NewIdent='' then
              FindNiceNodeBounds(TheNode,StartPos,EndPos);
            AddReplacement(ChgEntryRepl,StartPos,EndPos,NewIdent);
          end;
        end;
      end;
      CurError:=CurError.PrevError;
    end;
    // Apply replacement types also to pascal source.
    if not CodeToolBoss.RetypeClassVariables(fPascalBuffer,
                TLFMObjectNode(fLFMTree.Root).TypeName, NameReplacements, false)
    then begin
      Result:=mrCancel;
      exit;
    end;
    // Apply replacements to LFM.
    if not ApplyReplacements(ChgEntryRepl) then
      Result:=mrCancel;
  finally
    GridUpdater.Free;
    NameReplacements.Free;
    ChgEntryRepl.Free;
  end;
end;

procedure TLFMFixer.FillPropReplaceList;
var
  CurError: TLFMError;
  GridUpdater: TGridUpdater;
  OldIdent: string;
begin
  fHasMissingObjectTypes:=false;
  GridUpdater:=TGridUpdater.Create(fSettings.ReplaceTypes, fPropReplaceGrid);
  try
    if fLFMTree<>nil then begin
      CurError:=fLFMTree.FirstError;
      while CurError<>nil do begin
        if CurError.IsMissingObjectType then begin
          OldIdent:=(CurError.Node as TLFMObjectNode).TypeName;
          fHasMissingObjectTypes:=true;
        end
        else
          OldIdent:=CurError.Node.GetIdentifier;
        // Add only one instance of each property name.
        GridUpdater.AddUnique(OldIdent);
        CurError:=CurError.NextError;
      end;
    end;
  finally
    GridUpdater.Free;
  end;
end;

procedure TLFMFixer.LoadLFM;
begin
  inherited LoadLFM;
  // Fill PropertyReplaceGrid
  FillPropReplaceList;
end;

function TLFMFixer.ShowRepairLFMWizard: TModalResult;
var
  FixLFMDialog: TFixLFMDialog;
  PrevCursor: TCursor;
begin
  Result:=mrCancel;
  FixLFMDialog:=TFixLFMDialog.Create(nil, self);
  try
    fLFMSynEdit:=FixLFMDialog.LFMSynEdit;
    fErrorsListBox:=FixLFMDialog.ErrorsListBox;
    fPropReplaceGrid:=FixLFMDialog.PropertyReplaceGrid;
    LoadLFM;
    if fSettings.AutoRemoveProperties and not fHasMissingObjectTypes then
      Result:=ReplaceAndRemoveAll
    else begin
      // Cursor is earlier set to HourGlass. Show normal cursor while in dialog.
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crDefault;
      try
        Result:=FixLFMDialog.ShowModal;
      finally
        Screen.Cursor:=PrevCursor;
      end;
    end;
  finally
    FixLFMDialog.Free;
  end;
end;

function TLFMFixer.Repair: TModalResult;
var
  CurError: TLFMError;
  MissingObjectTypes: TStringList;
  ConvTool: TConvDelphiCodeTool;
  RegComp: TRegisteredComponent;
  TypeName: String;
  i, LoopCount: integer;
begin
  Result:=mrCancel;
  MissingObjectTypes:=TStringList.Create;
  try
    fLFMTree:=DefaultLFMTrees.GetLFMTree(fLFMBuffer, true);
    if not fLFMTree.ParseIfNeeded then exit;
    // Change a type that main form inherits from to a fall-back type if needed.
    ConvTool:=TConvDelphiCodeTool.Create(fPascalBuffer);
    try
      if not ConvTool.FixMainClassAncestor(TLFMObjectNode(fLFMTree.Root).TypeName,
                                           fSettings.ReplaceTypes) then exit;
    finally
      ConvTool.Free;
    end;
    LoopCount:=0;
    repeat
      if CodeToolBoss.CheckLFM(fPascalBuffer,fLFMBuffer,fLFMTree,
                               fRootMustBeClassInIntf,fObjectsMustExists)
      or (Result=mrOK) then begin // mrOK was returned from ShowRepairLFMWizard.
        Result:=mrOk;
        exit;
      end;
      // collect all missing object types
      CurError:=fLFMTree.FirstError;
      while CurError<>nil do begin
        if CurError.IsMissingObjectType then begin
          TypeName:=(CurError.Node as TLFMObjectNode).TypeName;
          if MissingObjectTypes.IndexOf(TypeName)<0 then
            MissingObjectTypes.Add(TypeName);
        end;
        CurError:=CurError.NextError;
      end;
      // Missing object types in unit.

      // keep all object types with a registered component class
      TypeName:=MissingObjectTypes.Text;
      for i:=MissingObjectTypes.Count-1 downto 0 do begin
        RegComp:=IDEComponentPalette.FindComponent(MissingObjectTypes[i]);
        if (RegComp=nil) or (RegComp.GetUnitName='') then
          MissingObjectTypes.Delete(i);
      end;
      if MissingObjectTypes.Count>0 then begin
        // Missing object types, but luckily found in IDE registered component classes.
        Result:=PackageEditingInterface.AddUnitDependenciesForComponentClasses(
                                     fPascalBuffer.Filename, MissingObjectTypes);
        if Result<>mrOk then exit;
        // check LFM again
        if not CodeToolBoss.CheckLFM(fPascalBuffer,fLFMBuffer,fLFMTree,
                                   fRootMustBeClassInIntf,fObjectsMustExists) then
          exit;
      end;
      // Rename / remove properties and types interactively.
      Result:=ShowRepairLFMWizard;
      Inc(LoopCount);
    until (Result in [mrOK, mrCancel]) or (LoopCount=10);
    // Show remaining errors to user.
    WriteLFMErrors;
  finally
    MissingObjectTypes.Free;
  end;
end;


{ TFixLFMDialog }

constructor TFixLFMDialog.Create(AOwner: TComponent; ALfmFixer: TLFMFixer);
begin
  inherited Create(AOwner);
  fLfmFixer:=ALfmFixer;
end;

destructor TFixLFMDialog.Destroy;
begin
  inherited Destroy;
end;

procedure TFixLFMDialog.CheckLFMDialogCREATE(Sender: TObject);
const // Will be moved to LazarusIDEStrConsts
  lisLFMFileContainsInvalidProperties = 'The LFM (Lazarus form) '
    +'file contains unknown properties/classes which do not exist in LCL. '
    +'They can be replaced or removed.';
begin
  Caption:=lisFixLFMFile;
  Position:=poScreenCenter;
  //  IDEDialogLayoutList.ApplyLayout(Self,600,400);
  NoteLabel.Caption:=lisLFMFileContainsInvalidProperties;
  ErrorsGroupBox.Caption:=lisErrors;
  LFMGroupBox.Caption:=lisLFMFile;
  PropertyReplaceGroupBox.Caption:=lisReplacementPropTypes;
  ReplaceAllButton.Caption:=lisReplaceRemoveUnknown;
  ReplaceAllButton.LoadGlyphFromLazarusResource('laz_refresh');
  EditorOpts.GetHighlighterSettings(SynLFMSyn1);
  EditorOpts.GetSynEditSettings(LFMSynEdit);
end;

procedure TFixLFMDialog.ReplaceAllButtonClick(Sender: TObject);
begin
  ModalResult:=fLfmFixer.ReplaceAndRemoveAll;
end;

procedure TFixLFMDialog.ErrorsListBoxClick(Sender: TObject);
begin
  fLfmFixer.JumpToError(fLfmFixer.FindListBoxError);
end;

procedure TFixLFMDialog.LFMSynEditSpecialLineMarkup(Sender: TObject;
  Line: integer; var Special: boolean; AMarkup: TSynSelectedColor);
var
  CurError: TLFMError;
begin
  CurError:=fLfmFixer.fLFMTree.FindErrorAtLine(Line);
  if CurError = nil then Exit;
  Special := True;
  EditorOpts.SetMarkupColor(SynLFMSyn1, ahaErrorLine, AMarkup);
end;


end.

