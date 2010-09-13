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

  Author: Juha Manninen

  Abstract:
    Settings for ConvertDelphi unit. Used for unit, project and package conversion.
}
unit ConvertSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, IDEProcs,
  StdCtrls, EditBtn, Buttons, ExtCtrls, DialogProcs, ButtonPanel,
  LazarusIDEStrConsts, CodeToolsStructs, AVL_Tree, BaseIDEIntf, LazConfigStorage,
  ConverterTypes, ReplaceNamesUnit, ReplaceFuncsUnit;

type

  TConvertTarget = (ctLazarus, ctLazarusWin, ctLazarusAndDelphi);

  { TConvertSettings }

  TConvertSettings = class
  private
    fTitle: String;       // Used for form caption.
    // Unit, Project or Package top file and path.
    fMainFilename: String;
    fMainPath: String;
    // Persistent storage in XML or some other format.
    fConfigStorage: TConfigStorage;
    // Actual user settings.
    fBackupFiles: boolean;
    fTarget: TConvertTarget;
    fSameDFMFile: boolean;
    fAutoRemoveProperties: boolean;
    fAutoReplaceUnits: boolean;
    fEnableReplaceFuncs: boolean;
    fEnableVisualOffs: boolean;
    // Delphi units mapped to Lazarus units, will be replaced or removed.
    fReplaceUnits: TStringToStringTree;
    // Delphi types mapped to Lazarus types, will be replaced.
    fReplaceTypes: TStringToStringTree;
    // Delphi global function names mapped to FCL/LCL functions.
    fReplaceFuncs: TFuncsAndCategories;
    // Coordinate offsets of components in a visual container.
    fVisualOffsets: TVisualOffsets;
    // Getter / setter:
    function GetBackupPath: String;
    procedure SetMainFilename(const AValue: String);
  public
    constructor Create(const ATitle: string);
    destructor Destroy; override;
    function RunForm: TModalResult;

    // Lazarus file name based on Delphi file name, keep suffix.
    function DelphiToLazFilename(const DelphiFilename: string;
      LowercaseFilename: boolean): string; overload;
    // Lazarus file name based on Delphi file name with new suffix.
    function DelphiToLazFilename(const DelphiFilename, LazExt: string;
      LowercaseFilename: boolean): string; overload;
    // Create Lazarus file name and copy/rename from Delphi file, keep suffix.
    function RenameDelphiToLazFile(const DelphiFilename: string;
      out LazFilename: string; LowercaseFilename: boolean): TModalResult; overload;
    // Create Lazarus file name and copy/rename from Delphi file with new suffix.
    function RenameDelphiToLazFile(const DelphiFilename, LazExt: string;
      out LazFilename: string; LowercaseFilename: boolean): TModalResult; overload;

    function RenameFile(const SrcFilename, DestFilename: string): TModalResult;
    function BackupFile(const AFilename: string): TModalResult;
  public
    property MainFilename: String read fMainFilename write SetMainFilename;
    property MainPath: String read fMainPath;
    property BackupPath: String read GetBackupPath;

    property BackupFiles: boolean read fBackupFiles;
    property Target: TConvertTarget read fTarget;
    property SameDFMFile: boolean read fSameDFMFile;
    property AutoRemoveProperties: boolean read fAutoRemoveProperties;
    property AutoReplaceUnits: boolean read fAutoReplaceUnits;
    property EnableReplaceFuncs: boolean read fEnableReplaceFuncs;
    property EnableVisualOffs: boolean read fEnableVisualOffs;
    property ReplaceUnits: TStringToStringTree read fReplaceUnits;
    property ReplaceTypes: TStringToStringTree read fReplaceTypes;
    property ReplaceFuncs: TFuncsAndCategories read fReplaceFuncs;
    property VisualOffsets: TVisualOffsets read fVisualOffsets;
  end;


  { TConvertSettingsForm }

  TConvertSettingsForm = class(TForm)
    PropRemoveAutoCheckBox: TCheckBox;
    UnitReplaceAutoCheckBox: TCheckBox;
    BackupCheckBox: TCheckBox;
    ButtonPanel: TButtonPanel;
    FuncReplaceEnableCheckBox: TCheckBox;
    VisualOffsEnableCheckBox: TCheckBox;
    Label1: TLabel;
    TypeReplInfoLabel: TLabel;
    VisualOffsButton: TBitBtn;
    TypeReplaceButton: TBitBtn;
    SameDFMCheckBox: TCheckBox;
    ProjectPathEdit: TLabeledEdit;
    TargetRadioGroup: TRadioGroup;
    FuncReplaceButton: TBitBtn;
    UnitReplaceButton: TBitBtn;
    SettingsGroupBox: TGroupBox;
    MissingStuffGroupBox: TGroupBox;
    procedure SameDFMCheckBoxChange(Sender: TObject);
    procedure TypeReplaceButtonClick(Sender: TObject);
    procedure FuncReplaceButtonClick(Sender: TObject);
    procedure VisualOffsButtonClick(Sender: TObject);
    procedure UnitReplaceButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TargetRadioGroupClick(Sender: TObject);
  private
    fSettings: TConvertSettings;
  public
    constructor Create(AOwner: TComponent; ASettings: TConvertSettings); reintroduce;
    destructor Destroy; override;
  end; 

var
  ConvertSettingsForm: TConvertSettingsForm;

implementation


{$R *.lfm}

// Load and store configuration in StringToStringTree :

procedure LoadStringToStringTree(Config: TConfigStorage; const Path: string;
  Tree: TStringToStringTree);
var
  SubPath: String;
  CurName, CurValue: String;
  Cnt, i: Integer;
begin
  Tree.Clear;
  Cnt:=Config.GetValue(Path+'Count', 0);
  for i:=0 to Cnt-1 do begin
    SubPath:=Path+'Item'+IntToStr(i)+'/';
    CurName:=Config.GetValue(SubPath+'Name','');
    CurValue:=Config.GetValue(SubPath+'Value','');
    Tree[CurName]:=CurValue;
  end;
end;

procedure SaveStringToStringTree(Config: TConfigStorage; const Path: string;
  Tree: TStringToStringTree);
var
  Node: TAVLTreeNode;
  Item: PStringToStringTreeItem;
  SubPath: String;
  i, j: Integer;
begin
  Config.SetDeleteValue(Path+'Count', Tree.Tree.Count, 0);
  Node:=Tree.Tree.FindLowest;
  i:=0;
  while Node<>nil do begin
    Item:=PStringToStringTreeItem(Node.Data);
    SubPath:=Path+'Item'+IntToStr(i)+'/';
    Config.SetDeleteValue(SubPath+'Name',Item^.Name,'');
    Config.SetDeleteValue(SubPath+'Value',Item^.Value,'');
    Node:=Tree.Tree.FindSuccessor(Node);
    inc(i);
  end;
  // Remove leftover items in case the list has become shorter.
  for j:=i to i+10 do begin
    SubPath:=Path+'Item'+IntToStr(j)+'/';
    Config.DeletePath(SubPath);
  end;
end;

// Load and store configuration in TFuncsAndCategories :

procedure LoadFuncReplacements(Config: TConfigStorage;
  const FuncPath, CategPath: string; aFuncsAndCateg: TFuncsAndCategories);
var
  SubPath: String;
  xCategory, xDelphiFunc, xReplacement, xPackage, xUnitName: String;
  CategUsed: Boolean;
  Cnt, i: Integer;
begin
  aFuncsAndCateg.Clear;
  // Replacement functions
  Cnt:=Config.GetValue(FuncPath+'Count', 0);
  for i:=0 to Cnt-1 do begin
    SubPath:=FuncPath+'Item'+IntToStr(i)+'/';
    xCategory   :=Config.GetValue(SubPath+'Category','');
    xDelphiFunc :=Config.GetValue(SubPath+'DelphiFunction','');
    xReplacement:=Config.GetValue(SubPath+'Replacement','');
    xPackage    :=Config.GetValue(SubPath+'Package','');
    xUnitName   :=Config.GetValue(SubPath+'UnitName','');
    aFuncsAndCateg.AddFunc(xCategory, xDelphiFunc, xReplacement, xPackage, xUnitName);
  end;
  // Categories
  Cnt:=Config.GetValue(CategPath+'Count', 0);
  for i:=0 to Cnt-1 do begin
    SubPath:=CategPath+'Item'+IntToStr(i)+'/';
    xCategory:=Config.GetValue(SubPath+'Name','');
    CategUsed:=Config.GetValue(SubPath+'InUse',True);
    aFuncsAndCateg.AddCategory(xCategory, CategUsed);
  end;
end;

procedure SaveFuncReplacements(Config: TConfigStorage;
  const FuncPath, CategPath: string; aFuncsAndCateg: TFuncsAndCategories);
var
  FuncRepl: TFuncReplacement;
  SubPath, s: String;
  i: Integer;
begin
  // Replacement functions
  Config.SetDeleteValue(FuncPath+'Count', aFuncsAndCateg.Funcs.Count, 0);
  for i:=0 to aFuncsAndCateg.Funcs.Count-1 do begin
    FuncRepl:=aFuncsAndCateg.FuncAtInd(i);
    if FuncRepl<>nil then begin
      SubPath:=FuncPath+'Item'+IntToStr(i)+'/';
      Config.SetDeleteValue(SubPath+'Category'      ,FuncRepl.Category,'');
      Config.SetDeleteValue(SubPath+'DelphiFunction',aFuncsAndCateg.Funcs[i],'');
      Config.SetDeleteValue(SubPath+'Replacement'   ,FuncRepl.ReplClause,'');
      Config.SetDeleteValue(SubPath+'Package'       ,FuncRepl.PackageName,'');
      Config.SetDeleteValue(SubPath+'UnitName'      ,FuncRepl.UnitName,'');
    end;
  end;
  // Remove leftover items in case the list has become shorter.
  for i:=aFuncsAndCateg.Funcs.Count to aFuncsAndCateg.Funcs.Count+10 do begin
    SubPath:=FuncPath+'Item'+IntToStr(i)+'/';
    Config.DeletePath(SubPath);
  end;
  // Categories
  Config.SetDeleteValue(CategPath+'Count', aFuncsAndCateg.Categories.Count, 0);
  for i:=0 to aFuncsAndCateg.Categories.Count-1 do begin
    s:=aFuncsAndCateg.Categories[i];
    if s<>'' then begin
      SubPath:=CategPath+'Item'+IntToStr(i)+'/';
      Config.SetDeleteValue(SubPath+'Name',s,'');
      Config.SetDeleteValue(SubPath+'InUse',aFuncsAndCateg.CategoryIsUsed(i),True);
    end;
  end;
  for i:=aFuncsAndCateg.Categories.Count to aFuncsAndCateg.Categories.Count+10 do begin
    SubPath:=CategPath+'Item'+IntToStr(i)+'/';
    Config.DeletePath(SubPath);
  end;
end;

// Load and store configuration in VisualOffsets :

procedure LoadVisualOffsets(Config: TConfigStorage; const Path: string;
  aVisualOffsets: TVisualOffsets);
var
  ParentType, SubPath: String;
  xTop, xLeft: Integer;
  Cnt, i: Integer;
begin
  aVisualOffsets.Clear;
  Cnt:=Config.GetValue(Path+'Count', 0);
  for i:=0 to Cnt-1 do begin
    SubPath:=Path+'Item'+IntToStr(i)+'/';
    ParentType:=Config.GetValue(SubPath+'ParentType','');
    xTop :=Config.GetValue(SubPath+'Top',0);
    xLeft:=Config.GetValue(SubPath+'Left',0);
    aVisualOffsets.Add(TVisualOffset.Create(ParentType, xTop, xLeft));
  end;
end;

procedure SaveVisualOffsets(Config: TConfigStorage; const Path: string;
  aVisualOffsets: TVisualOffsets);
var
  offs: TVisualOffset;
  SubPath: String;
  i: Integer;
begin
  Config.SetDeleteValue(Path+'Count', aVisualOffsets.Count, 0);
  for i:=0 to aVisualOffsets.Count-1 do begin
    offs:=aVisualOffsets[i];
    SubPath:=Path+'Item'+IntToStr(i)+'/';
    Config.SetDeleteValue(SubPath+'ParentType',offs.ParentType,'');
    Config.SetDeleteValue(SubPath+'Top'       ,offs.Top,0);
    Config.SetDeleteValue(SubPath+'Left'      ,offs.Left,0);
  end;
  // Remove leftover items in case the list has become shorter.
  for i:=aVisualOffsets.Count to aVisualOffsets.Count+10 do begin
    SubPath:=Path+'Item'+IntToStr(i)+'/';
    Config.DeletePath(SubPath);
  end;
end;

{ TConvertSettings }

constructor TConvertSettings.Create(const ATitle: string);
var
  TheMap: TStringToStringTree;
  Categ: string;

  procedure MapReplacement(aDelphi, aLCL: string);
  begin
    if not TheMap.Contains(aDelphi) then
      TheMap[aDelphi]:=aLCL;
  end;

  procedure AddDefaultCategory(aCategory: string);
  var
    x: integer;
  begin
    with fReplaceFuncs do
      if not Categories.Find(aCategory, x) then
        AddCategory(aCategory, True);
  end;

begin
  fTitle:=ATitle;
  fMainFilename:='';
  fMainPath:='';
  fReplaceUnits:=TStringToStringTree.Create(false);
  fReplaceTypes:=TStringToStringTree.Create(false);
  fReplaceFuncs:=TFuncsAndCategories.Create;
  fVisualOffsets:=TVisualOffsets.Create;
  // Load settings from ConfigStorage.
  fConfigStorage:=GetIDEConfigStorage('delphiconverter.xml', true);
  fBackupFiles          :=fConfigStorage.GetValue('BackupFiles', true);
  fTarget:=TConvertTarget(fConfigStorage.GetValue('ConvertTarget', 0));
  fSameDFMFile          :=fConfigStorage.GetValue('SameDFMFile', false);
  fAutoReplaceUnits     :=fConfigStorage.GetValue('AutoReplaceUnits', true);
  fAutoRemoveProperties :=fConfigStorage.GetValue('AutoRemoveProperties', true);
  fEnableReplaceFuncs   :=fConfigStorage.GetValue('EnableReplaceFuncs', true);
  fEnableVisualOffs     :=fConfigStorage.GetValue('EnableVisualOffs', true);
  LoadStringToStringTree(fConfigStorage, 'UnitReplacements/', fReplaceUnits);
  LoadStringToStringTree(fConfigStorage, 'TypeReplacements/', fReplaceTypes);
  LoadFuncReplacements(fConfigStorage, 'FuncReplacements/', 'Categories/', fReplaceFuncs);
  LoadVisualOffsets(fConfigStorage, 'VisualOffsets/', fVisualOffsets);

  // Add default values for configuration if ConfigStorage doesn't have them.

  // Map Delphi units to Lazarus units.
  TheMap:=fReplaceUnits;
  MapReplacement('Windows',             'LCLIntf, LCLType, LMessages');
  MapReplacement('Mask',                'MaskEdit');
  MapReplacement('Variants',            '');
  MapReplacement('ShellApi',            '');
  MapReplacement('pngImage',            '');
  MapReplacement('Jpeg',                '');
  MapReplacement('gifimage',            '');
  MapReplacement('^Q(.+)',              '$1');           // Kylix unit names.
  // Tnt* third party components.
  MapReplacement('TntLXStringGrids',    'Grids');
  MapReplacement('TntLXCombos',         '');
  MapReplacement('TntLXDataSet',        '');
  MapReplacement('TntLXVarArrayDataSet','');
  MapReplacement('TntLXLookupCtrls',    '');
  MapReplacement('^TntLX(.+)',          '$1');
  MapReplacement('^Tnt([^L][^X].+)',    '$1');
  // from Mattias: ^Tnt(([^L]|.[^X]).+)  or  ^Tnt(([^L]|L[^X]).*|L$)
  // from Alexander Klenin: ^Tnt(?!LX)(.+)$

  // Map Delphi types to LCL types.
  TheMap:=fReplaceTypes;
  MapReplacement('TFlowPanel',        'TPanel');
  MapReplacement('TGridPanel',        'TPanel');
  MapReplacement('TControlBar',       'TToolBar');
  MapReplacement('TCoolBar',          'TToolBar');
  MapReplacement('TComboBoxEx',       'TComboBox');
  MapReplacement('TValueListEditor',  'TStringGrid');
  MapReplacement('TRichEdit',         'TMemo');
  MapReplacement('TDBRichEdit',       'TDBMemo');
  MapReplacement('TApplicationEvents','TApplicationProperties');
  MapReplacement('TPNGObject',        'TPortableNetworkGraphic');
  // DevExpress components.
  MapReplacement('TCxEdit',           'TEdit');
  // Tnt* third party components.
  MapReplacement('^TTnt(.+)LX$',      'T$1');
  MapReplacement('^TTnt(.+[^L][^X])$','T$1');

  // Coordinate offsets for some visual containers.
  with fVisualOffsets do begin
    AddVisualOffset('TGroupBox' , 10,2);
    AddVisualOffset('TPanel',      2,2);
    AddVisualOffset('RadioGroup', 10,2);
    AddVisualOffset('CheckGroup', 10,2);
  end;

  // Map Delphi function names to FCL/LCL functions.
  with fReplaceFuncs do begin
    // File name encoding.
    Categ:='UTF8Names';
    AddDefaultCategory(Categ);
    AddFunc(Categ,'FileExists',          'FileExistsUTF8($1)',          'LCL','FileUtil');
    AddFunc(Categ,'FileAge',             'FileAgeUTF8($1)',             'LCL','FileUtil');
    AddFunc(Categ,'DirectoryExists',     'DirectoryExistsUTF8($1)',     'LCL','FileUtil');
    AddFunc(Categ,'ExpandFileName',      'ExpandFileNameUTF8($1)',      'LCL','FileUtil');
    AddFunc(Categ,'ExpandUNCFileName',   'ExpandUNCFileNameUTF8($1)',   'LCL','FileUtil');
    AddFunc(Categ,'ExtractShortPathName','ExtractShortPathNameUTF8($1)','LCL','FileUtil');
    AddFunc(Categ,'FindFirst',           'FindFirstUTF8($1,$2,$3)',     'LCL','FileUtil');
    AddFunc(Categ,'FindNext',            'FindNextUTF8($1)',            'LCL','FileUtil');
    AddFunc(Categ,'FindClose',           'FindCloseUTF8($1)',           'LCL','FileUtil');
    AddFunc(Categ,'FileSetDate',         'FileSetDateUTF8($1,$2)',      'LCL','FileUtil');
    AddFunc(Categ,'FileGetAttr',         'FileGetAttrUTF8($1)',         'LCL','FileUtil');
    AddFunc(Categ,'FileSetAttr',         'FileSetAttrUTF8($1)',         'LCL','FileUtil');
    AddFunc(Categ,'DeleteFile',          'DeleteFileUTF8($1)',          'LCL','FileUtil');
    AddFunc(Categ,'RenameFile',          'RenameFileUTF8($1,$2)',       'LCL','FileUtil');
    AddFunc(Categ,'FileSearch',          'FileSearchUTF8($1,$2)',       'LCL','FileUtil');
    AddFunc(Categ,'FileIsReadOnly',      'FileIsReadOnlyUTF8($1)',      'LCL','FileUtil');
    AddFunc(Categ,'GetCurrentDir',       'GetCurrentDirUTF8',           'LCL','FileUtil');
    AddFunc(Categ,'SetCurrentDir',       'SetCurrentDirUTF8($1)',       'LCL','FileUtil');
    AddFunc(Categ,'CreateDir',           'CreateDirUTF8($1)',           'LCL','FileUtil');
    AddFunc(Categ,'RemoveDir',           'RemoveDirUTF8($1)',           'LCL','FileUtil');
    AddFunc(Categ,'ForceDirectories',    'ForceDirectoriesUTF8($1)',    'LCL','FileUtil');
    // File functions using a handle.
    Categ:='FileHandle';
    AddDefaultCategory(Categ);
    AddFunc(Categ, 'CreateFile', 'FileCreate($1)','','SysUtils');
    AddFunc(Categ, 'GetFileSize','FileSize($1)'  ,'','SysUtils');
    AddFunc(Categ, 'ReadFile',   'FileRead($1)'  ,'','SysUtils');
    AddFunc(Categ, 'CloseHandle','FileClose($1)' ,'','SysUtils');
    // Others
    Categ:='Other';
    AddDefaultCategory(Categ);
    AddFunc(Categ, 'ShellExecute',
                   'if $3 match ":/" then OpenURL($3); OpenDocument($3)', '', '');
  end;
end;

destructor TConvertSettings.Destroy;
begin
  // Save possibly modified settings to ConfigStorage.
  fConfigStorage.SetDeleteValue('BackupFiles',          fBackupFiles, true);
  fConfigStorage.SetDeleteValue('ConvertTarget',        integer(fTarget), 0);
  fConfigStorage.SetDeleteValue('SameDFMFile',          fSameDFMFile, false);
  fConfigStorage.SetDeleteValue('AutoReplaceUnits',     fAutoReplaceUnits, true);
  fConfigStorage.SetDeleteValue('AutoRemoveProperties', fAutoRemoveProperties, true);
  fConfigStorage.SetDeleteValue('EnableReplaceFuncs',   fEnableReplaceFuncs, true);
  fConfigStorage.SetDeleteValue('EnableVisualOffs',     fEnableVisualOffs, true);
  SaveStringToStringTree(fConfigStorage, 'UnitReplacements/', fReplaceUnits);
  SaveStringToStringTree(fConfigStorage, 'TypeReplacements/', fReplaceTypes);
  SaveFuncReplacements(fConfigStorage, 'FuncReplacements/', 'Categories/', fReplaceFuncs);
  SaveVisualOffsets(fConfigStorage, 'VisualOffsets/', fVisualOffsets);
  // Free stuff
  fConfigStorage.Free;
  fReplaceFuncs.Clear;
  fReplaceFuncs.Free;
  fReplaceTypes.Free;
  fReplaceUnits.Free;
  fVisualOffsets.Free;
  inherited Destroy;
end;

function TConvertSettings.RunForm: TModalResult;
var
  SettingsForm: TConvertSettingsForm;
begin
  SettingsForm:=TConvertSettingsForm.Create(nil, Self);
  with SettingsForm do
  try
    Caption:=fTitle;
    ProjectPathEdit.Text:=fMainPath;
    // Settings --> UI. Loaded from ConfigSettings earlier.
    BackupCheckBox.Checked           :=fBackupFiles;
    TargetRadioGroup.ItemIndex       :=integer(fTarget);
    SameDFMCheckBox.Checked          :=fSameDFMFile;
    PropRemoveAutoCheckBox.Checked   :=fAutoRemoveProperties;
    UnitReplaceAutoCheckBox.Checked  :=fAutoReplaceUnits;
    FuncReplaceEnableCheckBox.Checked:=fEnableReplaceFuncs;
    VisualOffsEnableCheckBox.Checked :=fEnableVisualOffs;
    Result:=ShowModal;         // Let the user change settings in a form.
    if Result=mrOK then begin
      // UI --> Settings. Will be saved to ConfigSettings later.
      fBackupFiles         :=BackupCheckBox.Checked;
      fTarget              :=TConvertTarget(TargetRadioGroup.ItemIndex);
      fSameDFMFile         :=SameDFMCheckBox.Checked;
      fAutoRemoveProperties:=PropRemoveAutoCheckBox.Checked;
      fAutoReplaceUnits    :=UnitReplaceAutoCheckBox.Checked;
      fEnableReplaceFuncs  :=FuncReplaceEnableCheckBox.Checked;
      fEnableVisualOffs    :=VisualOffsEnableCheckBox.Checked;
    end;
  finally
    Free;
  end;
end;

function TConvertSettings.DelphiToLazFilename(const DelphiFilename: string;
                                              LowercaseFilename: boolean): string;
begin
  Result:=DelphiToLazFilename(DelphiFilename,'',LowercaseFilename);
end;

function TConvertSettings.DelphiToLazFilename(const DelphiFilename, LazExt: string;
                                              LowercaseFilename: boolean): string;
var
  RelPath, SubPath, fn: string;
begin
  RelPath:=FileUtil.CreateRelativePath(DelphiFilename, fMainPath);
  SubPath:=ExtractFilePath(RelPath);
  if LazExt='' then                 // Include ext in filename if not defined.
    fn:=ExtractFileName(RelPath)
  else
    fn:=ExtractFileNameOnly(RelPath);
  if LowercaseFilename then
    fn:=LowerCase(fn);
  Result:=fMainPath+SubPath+fn+LazExt;
end;

function TConvertSettings.RenameDelphiToLazFile(const DelphiFilename: string;
  out LazFilename: string; LowercaseFilename: boolean): TModalResult;
begin
  Result:=RenameDelphiToLazFile(DelphiFilename,'',LazFilename,LowercaseFilename);
end;

function TConvertSettings.RenameDelphiToLazFile(const DelphiFilename, LazExt: string;
  out LazFilename: string; LowercaseFilename: boolean): TModalResult;
var
  RelPath, SubPath, fn: string;
begin
  RelPath:=FileUtil.CreateRelativePath(DelphiFilename, fMainPath);
  SubPath:=ExtractFilePath(RelPath);
  if LazExt='' then                 // Include ext in filename if not defined.
    fn:=ExtractFileName(RelPath)
  else
    fn:=ExtractFileNameOnly(RelPath);
  if LowercaseFilename then
    fn:=LowerCase(fn);
  // Rename in the same directory.
  if fBackupFiles then begin
    Result:=BackupFile(DelphiFilename); // Save before rename.
    if Result<>mrOK then exit;
  end;
  LazFilename:=fMainPath+SubPath+fn+LazExt;
  Result:=RenameFileWithErrorDialogs(DelphiFilename,LazFilename,[mbAbort]);
end;

function TConvertSettings.RenameFile(const SrcFilename, DestFilename: string): TModalResult;
begin
//  Result:=mrOK;
  if fBackupFiles then
    BackupFile(SrcFilename); // Save before rename.
  Result:=RenameFileWithErrorDialogs(SrcFilename,DestFilename,[mbAbort]);
end;

function TConvertSettings.BackupFile(const AFilename: string): TModalResult;
var
  bp, fn: String;
begin
  bp:=BackupPath;
  fn:=ExtractFileName(AFilename);
  Result:=CopyFileWithErrorDialogs(AFilename,bp+fn,[mbAbort]);
end;

procedure TConvertSettings.SetMainFilename(const AValue: String);
begin
  fMainFilename:=AValue;
  fMainPath:=ExtractFilePath(AValue);
end;

function TConvertSettings.GetBackupPath: String;
const
  BackupPathName='ConverterBackup';
begin
  Result:='';
  if fBackupFiles then begin
    Result:=fMainPath+BackupPathName+PathDelim;
    // Create backup path if needed.
    if not DirectoryExistsUTF8(Result) then
      CreateDirUTF8(Result);
  end;
end;


{ TConvertSettingsForm }

constructor TConvertSettingsForm.Create(AOwner: TComponent; ASettings: TConvertSettings);
begin
  inherited Create(AOwner);
  fSettings:=ASettings;
end;

destructor TConvertSettingsForm.Destroy;
begin
  inherited Destroy;
end;

procedure TConvertSettingsForm.FormCreate(Sender: TObject);
begin
  ProjectPathEdit.Text:='';
  ProjectPathEdit.EditLabel.Caption:=lisProjectPath;
  ProjectPathEdit.Hint:=lisProjectPathHint;

  BackupCheckBox.Caption:=lisBackupChangedFiles;
  BackupCheckBox.Hint:=lisBackupHint;

  ButtonPanel.OKButton.Caption:=lisStartConversion;
  ButtonPanel.HelpButton.Caption:=lisMenuHelp;
  ButtonPanel.CancelButton.Caption:=dlgCancel;

  SameDFMCheckBox.Caption:=lisConvUseSameDFM;
  SameDFMCheckBox.Hint:=lisConvUseSameDFMHint;

  MissingStuffGroupBox.Caption:= lisReplacements; //lisConvUnitsTypesProp;
  PropRemoveAutoCheckBox.Caption:=lisConvAutoRemove;
  PropRemoveAutoCheckBox.Hint:=lisConvAutoHint;

  UnitReplaceButton.Caption:=lisConvUnitReplacements;
  UnitReplaceButton.Hint:=lisConvUnitReplHint;
  UnitReplaceAutoCheckBox.Caption:=lisConvAutoReplace; // lisMenuReplace
  UnitReplaceAutoCheckBox.Hint:=lisConvAutoHint;

  TypeReplaceButton.Caption:=lisConvTypeReplacements;
  TypeReplaceButton.Hint:=lisConvTypeReplHint;
  TypeReplInfoLabel.Caption:=lisInteractive;

  FuncReplaceButton.Caption:=lisConvFuncReplacements;
  FuncReplaceButton.Hint:=lisConvFuncReplHint;
  FuncReplaceEnableCheckBox.Caption:=lisEnable;

  VisualOffsButton.Caption:=lisConvCoordOffs;
  VisualOffsButton.Hint:=lisConvCoordHint;
  VisualOffsEnableCheckBox.Caption:=lisEnable;

  TargetRadioGroup.Items.Clear;
  TargetRadioGroup.Items.Append(lisConvertTarget1);
  TargetRadioGroup.Items.Append(lisConvertTarget2);
  TargetRadioGroup.Items.Append(lisConvertTarget3);
  TargetRadioGroup.ItemIndex:=0;
  TargetRadioGroup.Hint:=lisConvertTargetHint;
  TargetRadioGroupClick(TargetRadioGroup);
end;

procedure TConvertSettingsForm.FormDestroy(Sender: TObject);
begin
  ;
end;

procedure TConvertSettingsForm.TargetRadioGroupClick(Sender: TObject);
// Delphi compatibility doesn't allow renaming the form file.
var
  Trg: TConvertTarget;
begin
  Trg:=TConvertTarget((Sender as TRadioGroup).ItemIndex);
  if Trg<>ctLazarusAndDelphi then begin
    SameDFMCheckBox.Checked:=false;
  end;
  SameDFMCheckBox.Enabled:=Trg=ctLazarusAndDelphi;
end;

procedure TConvertSettingsForm.SameDFMCheckBoxChange(Sender: TObject);
begin
  if (Sender as TCheckBox).Checked then
    VisualOffsEnableCheckBox.Checked:=False;
end;

// Edit replacements in grids

procedure TConvertSettingsForm.UnitReplaceButtonClick(Sender: TObject);
begin
  EditMap(fSettings.ReplaceUnits, lisConvUnitsToReplace);
end;

procedure TConvertSettingsForm.TypeReplaceButtonClick(Sender: TObject);
begin
  EditMap(fSettings.ReplaceTypes, lisConvTypesToReplace);
end;

procedure TConvertSettingsForm.FuncReplaceButtonClick(Sender: TObject);
begin
  EditFuncReplacements(fSettings.ReplaceFuncs, lisConvFuncsToReplace);
end;

procedure TConvertSettingsForm.VisualOffsButtonClick(Sender: TObject);
begin
  EditVisualOffsets(fSettings.VisualOffsets, lisConvCoordOffs);
end;


end.

