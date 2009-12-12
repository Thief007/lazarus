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
}
unit BuildModesEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, FileUtil, LResources, Forms, Grids, Menus,
  ComCtrls, CompilerOptions;

type

  { TBuildModeGridRow }

  TBuildModeGridRow = class
  private
    FFlag: TBuildModeFlag;
    FIndexInGroup: integer;
    FMode: TBuildMode;
  public
    constructor Create(aMode: TBuildMode; aFlag: TBuildModeFlag);
    destructor Destroy; override;
    property Mode: TBuildMode read FMode;
    property Flag: TBuildModeFlag read FFlag;
    property IndexInGroup: integer read FIndexInGroup write FIndexInGroup;
  end;

  { TBuildModesGrid }

  TBuildModesGrid = class(TStringGrid)
  private
    FGraph: TBuildModeGraph;
    FGroupModeCount: integer;
    FModeRows: TFPList; // list of TBuildModeGridRow
    function GetModeRowCount: integer;
    function GetModeRows(Index: integer): TBuildModeGridRow;
    procedure ClearModeRows;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Graph: TBuildModeGraph read FGraph;
    procedure RebuildGrid; // call this after Graph changed
    property ModeRowCount: integer read GetModeRowCount;
    property ModeRows[Index: integer]: TBuildModeGridRow read GetModeRows;
    property GroupModeCount: integer read FGroupModeCount; // number of modes that are group of modes
  end;

  { TBuildModesEditorFrame }

  TBuildModesEditorFrame = class(TFrame)
    BuildModesPopupMenu: TPopupMenu;
    BuildModesToolBar1: TToolBar;
    NewBuildModeToolButton: TToolButton;
  private
    FGrid: TBuildModesGrid;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Grid: TBuildModesGrid read FGrid;
  end;

function BuildModeFlagTypeCaptions(f: TBuildModeFlagType): string;

implementation

function BuildModeFlagTypeCaptions(f: TBuildModeFlagType): string;
begin
  case f of
  bmftAddUnitPath: Result:='+UnitPath';
  bmftAddIncludePath: Result:='+IncludePath';
  bmftAddLinkerPath: Result:='+linkerPath';
  bmftAddObjectPath: Result:='+ObjectPath';
  bmftAddLinkerOption: Result:='+LinkerOptions';
  bmftAddCustomOption: Result:='+CustomOptions';
  else Result:='';
  end;
end;

{ TBuildModesGrid }

function TBuildModesGrid.GetModeRows(Index: integer): TBuildModeGridRow;
begin
  Result:=TBuildModeGridRow(FModeRows[Index]);
end;

procedure TBuildModesGrid.ClearModeRows;
var
  i: Integer;
begin
  for i:=0 to FModeRows.Count-1 do
    TObject(FModeRows[i]).Free;
  FModeRows.Clear;
  FGroupModeCount:=0;
end;

function TBuildModesGrid.GetModeRowCount: integer;
begin
  Result:=FModeRows.Count;
end;

constructor TBuildModesGrid.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  fGraph:=TBuildModeGraph.Create;
  FModeRows:=TFPList.Create;
end;

destructor TBuildModesGrid.Destroy;
begin
  ClearModeRows;
  FreeAndNil(FModeRows);
  FreeAndNil(FGraph);
  inherited Destroy;
end;

procedure TBuildModesGrid.RebuildGrid;
var
  GroupInsertPos: Integer;

  procedure AddRow(CurMode: TBuildMode; NewRow: TBuildModeGridRow);
  var
    InsertPos: LongInt;
  begin
    if CurMode.ShowIncludes then begin
      InsertPos:=GroupInsertPos;
      inc(GroupInsertPos);
    end else begin
      InsertPos:=FModeRows.Count;
    end;
    if (InsertPos=0) or (ModeRows[InsertPos-1].Mode<>CurMode) then
      NewRow.IndexInGroup:=0
    else
      NewRow.IndexInGroup:=ModeRows[InsertPos-1].IndexInGroup+1;
    FModeRows.Insert(InsertPos,NewRow);
  end;

var
  i: Integer;
  CurMode: TBuildMode;
  NewRow: TBuildModeGridRow;
  j: Integer;
  CurRow: TBuildModeGridRow;
  TypeCol: Integer;
  ValueCol: Integer;
  CurFlag: TBuildModeFlag;
  TypeStr: String;
  ValueStr: String;
begin
  ClearModeRows;
  GroupInsertPos:=0;
  // create rows
  for i:=0 to Graph.ModeCount-1 do begin
    CurMode:=Graph.Modes[i];
    if CurMode.ShowIncludes then inc(FGroupModeCount);
    if (CurMode.FlagCount=0) then begin
      // no flags => create an empty one
      NewRow:=TBuildModeGridRow.Create(CurMode,nil);
      AddRow(CurMode,NewRow);
    end else begin
      for j:=0 to CurMode.FlagCount-1 do begin
        CurFlag:=CurMode.Flags[j];
        NewRow:=TBuildModeGridRow.Create(CurMode,CurFlag);
        AddRow(CurMode,NewRow);
      end;
    end;
  end;
  // grid size
  RowCount:=FModeRows.Count+1;
  ColCount:=GroupModeCount+3;
  // header
  Cells[0,0]:='Build mode';
  for i:=1 to GroupModeCount do Cells[i,0]:='';
  TypeCol:=GroupModeCount+1;
  ValueCol:=TypeCol+1;
  Cells[TypeCol,0]:='Type';
  Cells[ValueCol,0]:='Value';
  // values
  for i:=1 to ModeRowCount do begin
    CurRow:=ModeRows[i-1];
    // name
    if CurRow.IndexInGroup=0 then
      Cells[0,i]:=CurRow.Mode.Name
    else
      Cells[0,i]:='';
    // included by
    for j:=0 to GroupModeCount-1 do
      Cells[j+1,i]:='';
    // type + value
    CurFlag:=CurRow.Flag;
    TypeStr:='';
    ValueStr:='';
    if CurFlag<>nil then begin
      if CurFlag.FlagType=bmftSetVariable then
      begin
        TypeStr:=CurFlag.Variable;
        ValueStr:=CurFlag.Value;
      end else
        TypeStr:=BuildModeFlagTypeCaptions(CurFlag.FlagType);
    end;
    Cells[TypeCol,i]:=TypeStr;
    Cells[ValueCol,i]:=ValueStr;
  end;

end;

{ TBuildModeGridRow }

constructor TBuildModeGridRow.Create(aMode: TBuildMode; aFlag: TBuildModeFlag);
begin
  FMode:=aMode;
  FFlag:=aFlag;
end;

destructor TBuildModeGridRow.Destroy;
begin
  inherited Destroy;
end;

{ TBuildModesEditorFrame }

constructor TBuildModesEditorFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FGrid:=TBuildModesGrid.Create(Self);
  with Grid do begin
    Name:='Grid';
    Parent:=Self;
    Align:=alClient;
  end;
end;

destructor TBuildModesEditorFrame.Destroy;
begin
  inherited Destroy;
end;

initialization
  {$I buildmodeseditor.lrs}

end.

