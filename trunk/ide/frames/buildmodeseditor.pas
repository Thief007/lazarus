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

  Abstract:
    The frame for 'build modes' on the compiler options.
    Allows to edit build modes and build macro values.
    It does not allow to define new build macros.
}
unit BuildModesEditor;

{$mode objfpc}{$H+}

interface

uses
  Math, Classes, SysUtils, LCLProc, Controls, FileUtil, Forms,
  Grids, Graphics, Menus, ComCtrls, Dialogs, AvgLvlTree, DefineTemplates,
  StdCtrls, GraphMath, ExtCtrls, Buttons,
  ProjectIntf, IDEImagesIntf, IDEOptionsIntf,
  PackageDefs, compiler_inherited_options, TransferMacros,
  PathEditorDlg, Project, PackageSystem, LazarusIDEStrConsts, CompilerOptions,
  IDEProcs;

type

  { TBuildModesEditorFrame }

  TBuildModesEditorFrame = class(TAbstractIDEOptionsEditor)
    BuildMacroValuesGroupBox: TGroupBox;
    BuildMacroValuesStringGrid: TStringGrid;
    BuildModesGroupBox: TGroupBox;
    BuildModesPopupMenu: TPopupMenu;
    Splitter1: TSplitter;
    procedure BuildMacroValuesStringGridEditingDone(Sender: TObject);
    procedure BuildMacroValuesStringGridSelectEditor(Sender: TObject; aCol,
      aRow: Integer; var Editor: TWinControl);
    procedure BuildMacroValuesStringGridSelection(Sender: TObject; aCol,
      aRow: Integer);
  private
    FMacroValues: TProjectBuildMacros;
    FProject: TProject;
    procedure UpdateMacrosControls;
    function GetAllBuildMacros: TStrings;
    procedure CleanMacrosGrid;
    procedure Save(UpdateControls: boolean);
    procedure UpdateInheritedOptions;
    function FindOptionFrame(AClass: TComponentClass): TComponent;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
    property AProject: TProject read FProject;
    property MacroValues: TProjectBuildMacros read FMacroValues;
  end;

implementation

{$R *.lfm}

{ TBuildModesEditorFrame }

procedure TBuildModesEditorFrame.BuildMacroValuesStringGridSelectEditor(
  Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
var
  PickList: TPickListCellEditor;
  sl: TStringList;
  Macros: TStrings;
  Grid: TStringGrid;
  MacroName: string;
  i: LongInt;
  Macro: TLazBuildMacro;
begin
  if MacroValues=nil then exit;
  Grid:=BuildMacroValuesStringGrid;
  //debugln(['TBuildModesEditorFrame.BuildMacroValuesStringGridSelectEditor ',acol,',',aRow,' ',DbgSName(Editor)]);
  if aCol=0 then begin
    // list all build MacroValues
    if not (Editor is TPickListCellEditor) then exit;
    PickList:=TPickListCellEditor(Editor);
    sl:=TStringList.Create;
    Macros:=nil;
    try
      if aRow=Grid.RowCount-1 then
        sl.Add('(none)')
      else
        sl.Add('(delete)');

      Macros:=GetAllBuildMacros;
      sl.AddStrings(Macros);

      PickList.Items.Assign(sl);
    finally
      Macros.Free;
      sl.Free;
    end;
  end else if aCol=1 then begin
    // list all possible values of current macro

    if not (Editor is TPickListCellEditor) then exit;
    PickList:=TPickListCellEditor(Editor);

    MacroName:=Grid.Cells[0,aRow];
    sl:=TStringList.Create;
    try
      Macros:=GetAllBuildMacros;
      i:=Macros.IndexOf(MacroName);
      if i>=0 then begin
        Macro:=TLazBuildMacro(Macros.Objects[i]);
        sl.AddStrings(Macro.Values);
      end else begin
        sl.Add('');
      end;

      PickList.Items.Assign(sl);
    finally
      Macros.Free;
      sl.Free;
    end;
  end;
end;

procedure TBuildModesEditorFrame.BuildMacroValuesStringGridEditingDone(
  Sender: TObject);
begin
  //debugln(['TBuildModesEditorFrame.BuildMacroValuesStringGridEditingDone ']);
  Save(true);
end;

procedure TBuildModesEditorFrame.BuildMacroValuesStringGridSelection(
  Sender: TObject; aCol, aRow: Integer);
begin
  CleanMacrosGrid;
end;

procedure TBuildModesEditorFrame.UpdateMacrosControls;
var
  Grid: TStringGrid;
  i: Integer;
begin
  Grid:=BuildMacroValuesStringGrid;
  Grid.RowCount:=MacroValues.Count+2; // + titles + add button

  for i:=0 to MacroValues.Count-1 do begin
    Grid.Cells[0,i+1]:=MacroValues.Names[i];
    Grid.Cells[1,i+1]:=MacroValues.ValueFromIndex(i);
  end;
  i:=MacroValues.Count+1;
  Grid.Cells[0,i]:='(none)';
  Grid.Cells[1,i]:='';
end;

function TBuildModesEditorFrame.GetAllBuildMacros: TStrings;

  procedure Add(aBuildMacro: TLazBuildMacro);
  begin
    if GetAllBuildMacros.IndexOf(aBuildMacro.Identifier)>=0 then exit;
    GetAllBuildMacros.AddObject(aBuildMacro.Identifier,aBuildMacro);
  end;

  procedure Add(CompOpts: TLazCompilerOptions);
  var
    i: Integer;
  begin
    for i:=0 to CompOpts.BuildMacros.Count-1 do
      Add(CompOpts.BuildMacros[i]);
  end;

var
  PkgList: TFPList;
  APackage: TLazPackage;
  i: Integer;
begin
  Result:=TStringList.Create;
  if AProject=nil then exit;
  Add(AProject.CompilerOptions);
  PkgList:=nil;
  try
    PackageGraph.GetAllRequiredPackages(AProject.FirstRequiredDependency,PkgList);
    if PkgList<>nil then begin
      for i:=0 to PkgList.Count-1 do begin
        if TObject(PkgList[i]) is TLazPackage then begin
          APackage:=TLazPackage(PkgList[i]);
          Add(APackage.CompilerOptions);
        end;
      end;
    end;
  finally
    PkgList.Free;
  end;

  TStringList(Result).Sort;
end;

procedure TBuildModesEditorFrame.CleanMacrosGrid;
var
  Grid: TStringGrid;
  aRow: Integer;
  MacroName: string;
  NeedNewRow: Boolean;
begin
  Grid:=BuildMacroValuesStringGrid;
  // delete rows
  for aRow:=Grid.RowCount-2 downto 1 do begin
    if aRow=Grid.Row then continue; // row is selected
    MacroName:=Grid.Cells[0,aRow];
    if (MacroName<>'') and IsValidIdent(MacroName) then continue; // valid macro name
    // delete row
    Grid.DeleteColRow(false,aRow);
  end;
  NeedNewRow:=Grid.RowCount<2;
  if (not NeedNewRow) then begin
    MacroName:=Grid.Cells[0,Grid.RowCount-1];
    if (MacroName<>'') and IsValidIdent(MacroName) then
      NeedNewRow:=true;
  end;
  if NeedNewRow then begin
    Grid.RowCount:=Grid.RowCount+1;
    Grid.Cells[0,Grid.RowCount-1]:='(new)';
    Grid.Cells[1,Grid.RowCount-1]:='';
  end;
end;

procedure TBuildModesEditorFrame.Save(UpdateControls: boolean);
var
  Grid: TStringGrid;
  aRow: Integer;
  MacroName: string;
  Values: TStringList;
  Value: string;
begin
  Grid:=BuildMacroValuesStringGrid;
  Values:=TStringList.Create;
  try
    for aRow:=1 to Grid.RowCount-1 do begin
      MacroName:=Grid.Cells[0,aRow];
      if (MacroName='') or (not IsValidIdent(MacroName)) then continue;
      Value:=Grid.Cells[1,aRow];
      Values.Values[MacroName]:=Value;
    end;
    //debugln(['TBuildModesEditorFrame.Save ',Values.Text,' changed=',not MacroValues.Equals(Values)]);
    if not MacroValues.Equals(Values) then begin
      // has changed
      MacroValues.Assign(Values);
      if UpdateControls then begin
        UpdateInheritedOptions;
      end;
    end;
  finally
    Values.Free;
  end;
end;

procedure TBuildModesEditorFrame.UpdateInheritedOptions;
var
  InhOptionCtrl: TCompilerInheritedOptionsFrame;
begin
  InhOptionCtrl:=TCompilerInheritedOptionsFrame(
                               FindOptionFrame(TCompilerInheritedOptionsFrame));
  //debugln(['TBuildModesEditorFrame.UpdateInheritedOptions ',DbgSName(InhOptionCtrl)]);
  if InhOptionCtrl=nil then exit;
  InhOptionCtrl.UpdateInheritedTree(AProject.CompilerOptions);
end;

function TBuildModesEditorFrame.FindOptionFrame(AClass: TComponentClass
  ): TComponent;

  function Search(AControl: TControl): TComponent;
  var
    i: Integer;
    AWinControl: TWinControl;
  begin
    if AControl is AClass then
      exit(AControl);
    if AControl is TWinControl then begin
      AWinControl:=TWinControl(AControl);
      for i:=0 to AWinControl.ControlCount-1 do begin
        Result:=Search(AWinControl.Controls[i]);
        if Result<>nil then exit;
      end;
    end;
    Result:=nil;
  end;

begin
  Result:=Search(GetParentForm(Self));
end;

constructor TBuildModesEditorFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FMacroValues:=TProjectBuildMacros.Create;
end;

destructor TBuildModesEditorFrame.Destroy;
begin
  FreeAndNil(FMacroValues);
  inherited Destroy;
end;

function TBuildModesEditorFrame.GetTitle: String;
begin
  Result := 'Build modes';
end;

procedure TBuildModesEditorFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
var
  Grid: TStringGrid;
begin
  BuildModesGroupBox.Caption:='Build modes';

  BuildMacroValuesGroupBox.Caption:='Set macro values';
  Grid:=BuildMacroValuesStringGrid;
  Grid.Columns.Add;
  Grid.Columns[0].Title.Caption:='Macro name';
  Grid.Columns[0].ButtonStyle:=cbsPickList;
  Grid.Columns.Add;
  Grid.Columns[1].Title.Caption:='Macro value';
  Grid.Columns[1].ButtonStyle:=cbsPickList;
end;

procedure TBuildModesEditorFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  PCOptions: TProjectCompilerOptions;
begin
  //debugln(['TBuildModesEditorFrame.ReadSettings ',DbgSName(AOptions)]);
  if AOptions is TProjectCompilerOptions then begin
    PCOptions:=TProjectCompilerOptions(AOptions);
    FProject:=PCOptions.LazProject;
    MacroValues.Assign(FProject.MacroValues);
    UpdateMacrosControls;
  end;
end;

procedure TBuildModesEditorFrame.WriteSettings(AOptions: TAbstractIDEOptions);
var
  PCOptions: TProjectCompilerOptions;
begin
  if AOptions is TProjectCompilerOptions then begin
    PCOptions:=TProjectCompilerOptions(AOptions);
    Save(false);
    if not PCOptions.LazProject.MacroValues.Equals(MacroValues) then begin
      PCOptions.LazProject.MacroValues.Assign(MacroValues);
      IncreaseBuildMacroChangeStamp;
    end;
  end;
end;

class function TBuildModesEditorFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TProjectCompilerOptions;
end;

{$IFDEF EnableBuildModes}
initialization
  RegisterIDEOptionsEditor(GroupCompiler, TBuildModesEditorFrame,
    CompilerOptionsBuildModes);
{$ENDIF}
end.

