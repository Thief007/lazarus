{  $Id$  }
{
 /***************************************************************************
                            checklfmdlg.pas
                            ---------------

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
unit CheckLFMDlg;

{$mode objfpc}{$H+}

interface

uses
  // FCL+LCL
  Classes, SysUtils, Math, LResources, Forms, Controls, Graphics, Dialogs,
  Buttons, StdCtrls,
  // components
  SynHighlighterLFM, SynEdit, BasicCodeTools, CodeCache, CodeToolManager,
  LFMTrees,
  // IDE
  OutputFilter, IDEProcs, IDEOptionDefs, EditorOptions;

type
  TCheckLFMDialog = class(TForm)
    CancelButton: TButton;
    ErrorsGroupBox: TGroupBox;
    ErrorsListBox: TListBox;
    NoteLabel: TLabel;
    LFMGroupBox: TGroupBox;
    LFMSynEdit: TSynEdit;
    RemoveAllButton: TButton;
    SynLFMSyn1: TSynLFMSyn;
    procedure ErrorsListBoxClick(Sender: TObject);
    procedure LFMSynEditSpecialLineColors(Sender: TObject; Line: integer;
      var Special: boolean; var FG, BG: TColor);
    procedure RemoveAllButtonClick(Sender: TObject);
    procedure CheckLFMDialogCREATE(Sender: TObject);
  private
    FLFMSource: TCodeBuffer;
    FLFMTree: TLFMTree;
    procedure SetLFMSource(const AValue: TCodeBuffer);
    procedure SetLFMTree(const AValue: TLFMTree);
    procedure SetupComponents;
    function FindListBoxError: TLFMError;
    procedure JumpToError(LFMError: TLFMError);
    procedure FindNiceNodeBounds(LFMNode: TLFMTreeNode;
                                 var StartPos, EndPos: integer);
    procedure AddReplacement(LFMChangeList: TList; StartPos, EndPos: integer;
                             const NewText: string);
    function ApplyReplacements(LFMChangeList: TList): boolean;
  public
    procedure LoadLFM;
    procedure FillErrorsListBox;
    function AutomaticFixIsPossible: boolean;
    property LFMTree: TLFMTree read FLFMTree write SetLFMTree;
    property LFMSource: TCodeBuffer read FLFMSource write SetLFMSource;
  end;
  
function CheckLFMBuffer(PascalBuffer, LFMBuffer: TCodeBuffer;
  const OnOutput: TOnOutputString): boolean;
function ShowRepairLFMWizard(LFMBuffer: TCodeBuffer;
  LFMTree: TLFMTree): boolean;


implementation

type
  TLFMChangeEntry = class
  public
    StartPos, EndPos: integer;
    NewText: string;
  end;

function CheckLFMBuffer(PascalBuffer, LFMBuffer: TCodeBuffer;
  const OnOutput: TOnOutputString): boolean;
var
  LFMTree: TLFMTree;
  
  procedure WriteLFMErrors;
  var
    CurError: TLFMError;
    Dir: String;
    Msg: String;
    Filename: String;
  begin
    if not Assigned(OnOutput) then exit;
    CurError:=LFMTree.FirstError;
    Dir:=ExtractFilePath(LFMBuffer.Filename);
    Filename:=ExtractFilename(LFMBuffer.Filename);
    while CurError<>nil do begin
      Msg:=Filename
           +'('+IntToStr(CurError.Caret.Y)+','+IntToStr(CurError.Caret.X)+')'
           +' Error: '
           +CurError.ErrorMessage;
      writeln('WriteLFMErrors ',Msg);
      OnOutput(Msg,Dir);
      CurError:=CurError.NextError;
    end;
  end;
  
begin
  Result:=CodeToolBoss.CheckLFM(PascalBuffer,LFMBuffer,LFMTree);
  try
    if Result then exit;
    WriteLFMErrors;
    Result:=ShowRepairLFMWizard(LFMBuffer,LFMTree);
  finally
    LFMTree.Free;
  end;
end;

function ShowRepairLFMWizard(LFMBuffer: TCodeBuffer;
  LFMTree: TLFMTree): boolean;
var
  CheckLFMDialog: TCheckLFMDialog;
begin
  Result:=false;
  CheckLFMDialog:=TCheckLFMDialog.Create(Application);
  CheckLFMDialog.LFMTree:=LFMTree;
  CheckLFMDialog.LFMSource:=LFMBuffer;
  CheckLFMDialog.LoadLFM;
  if CheckLFMDialog.ShowModal=mrOk then
    Result:=true;
  CheckLFMDialog.Free;
end;

{ TCheckLFMDialog }

procedure TCheckLFMDialog.RemoveAllButtonClick(Sender: TObject);
var
  CurError: TLFMError;
  DeleteNode: TLFMTreeNode;
  StartPos, EndPos: integer;
  Replacements: TList;
begin
  Replacements:=TList.Create;
  try
    // automatically delete each error location
    CurError:=LFMTree.LastError;
    while CurError<>nil do begin
      DeleteNode:=CurError.FindContextNode;
      if (DeleteNode<>nil) and (DeleteNode.Parent<>nil) then begin
        FindNiceNodeBounds(DeleteNode,StartPos,EndPos);
        AddReplacement(Replacements,StartPos,EndPos,'');
      end;
      CurError:=CurError.PrevError;
    end;

    if ApplyReplacements(Replacements) then
      ModalResult:=mrOk;
  finally
    Replacements.Free;
  end;
end;

procedure TCheckLFMDialog.ErrorsListBoxClick(Sender: TObject);
begin
  JumpToError(FindListBoxError);
end;

procedure TCheckLFMDialog.LFMSynEditSpecialLineColors(Sender: TObject;
  Line: integer; var Special: boolean; var FG, BG: TColor);
var
  CurError: TLFMError;
begin
  CurError:=LFMTree.FindErrorAtLine(Line);
  if CurError<>nil then begin
    EditorOpts.GetSpecialLineColors(SynLFMSyn1,ahaErrorLine,Special,FG,BG);
  end;
end;

procedure TCheckLFMDialog.CheckLFMDialogCREATE(Sender: TObject);
begin
  Caption:='Fix LFM file';
  Position:=poScreenCenter;
  IDEDialogLayoutList.ApplyLayout(Self,600,400);
  SetupComponents;
end;

procedure TCheckLFMDialog.SetLFMSource(const AValue: TCodeBuffer);
begin
  if FLFMSource=AValue then exit;
  FLFMSource:=AValue;
end;

procedure TCheckLFMDialog.SetLFMTree(const AValue: TLFMTree);
begin
  if FLFMTree=AValue then exit;
  FLFMTree:=AValue;
  RemoveAllButton.Enabled:=AutomaticFixIsPossible;
end;

procedure TCheckLFMDialog.SetupComponents;
begin
  NoteLabel.Caption:='The LFM (Lazarus form) file contains invalid properties. '
    +'This means for example it contains some properties/classes, which do not exist in the current LCL. '
    +'The normal fix is to remove these properties from the lfm and fix the pascal code manually.';
  CancelButton.Caption:='Cancel';
  ErrorsGroupBox.Caption:='Errors';
  LFMGroupBox.Caption:='LFM file';
  RemoveAllButton.Caption:='Remove all invalid properties';
  
  EditorOpts.GetHighlighterSettings(SynLFMSyn1);
  EditorOpts.GetSynEditSettings(LFMSynEdit);
end;

function TCheckLFMDialog.FindListBoxError: TLFMError;
var
  i: Integer;
begin
  Result:=nil;
  i:=ErrorsListBox.ItemIndex;
  if (i<0) or (i>=ErrorsListBox.Items.Count) then exit;
  Result:=LFMTree.FirstError;
  while Result<>nil do begin
    if i=0 then exit;
    Result:=Result.NextError;
    dec(i);
  end;
end;

procedure TCheckLFMDialog.JumpToError(LFMError: TLFMError);
begin
  if LFMError=nil then exit;
  LFMSynEdit.CaretXY:=LFMError.Caret;
end;

procedure TCheckLFMDialog.FindNiceNodeBounds(LFMNode: TLFMTreeNode;
  var StartPos, EndPos: integer);
var
  Src: String;
begin
  Src:=LFMSource.Source;
  StartPos:=FindLineEndOrCodeInFrontOfPosition(Src,LFMNode.StartPos,1,false,true);
  EndPos:=FindLineEndOrCodeInFrontOfPosition(Src,LFMNode.EndPos,1,false,true);
  EndPos:=FindLineEndOrCodeAfterPosition(Src,EndPos,length(Src),false);
end;

procedure TCheckLFMDialog.AddReplacement(LFMChangeList: TList;
  StartPos, EndPos: integer; const NewText: string);
var
  Entry: TLFMChangeEntry;
  NewEntry: TLFMChangeEntry;
  NextEntry: TLFMChangeEntry;
  i: Integer;
begin
  if StartPos>EndPos then
    RaiseException('TCheckLFMDialog.AddReplaceMent StartPos>EndPos');

  // check for intersection
  for i:=0 to LFMChangeList.Count-1 do begin
    Entry:=TLFMChangeEntry(LFMChangeList[i]);
    if ((Entry.StartPos<EndPos) and (Entry.EndPos>StartPos)) then begin
      // New and Entry intersects
      if (Entry.NewText='') and (NewText='') then begin
        // both are deletes => combine
        StartPos:=Min(StartPos,Entry.StartPos);
        EndPos:=Max(EndPos,Entry.EndPos);
      end else begin
        // not allowed
        RaiseException('TCheckLFMDialog.AddReplaceMent invalid Intersection');
      end;
    end;
  end;

  // combine deletions
  if NewText='' then begin
    for i:=0 to LFMChangeList.Count-1 do begin
      Entry:=TLFMChangeEntry(LFMChangeList[i]);
      if ((Entry.StartPos<EndPos) and (Entry.EndPos>StartPos)) then begin
        // New and Entry intersects
        Entry.StartPos:=Min(StartPos,Entry.StartPos);
        Entry.EndPos:=Max(EndPos,Entry.EndPos);
        if (i<LFMChangeList.Count-1) then begin
          NextEntry:=TLFMChangeEntry(LFMChangeList[i+1]);
          if NextEntry.StartPos<EndPos then begin
            // next entry can be merged
            LFMChangeList.Delete(i+1);
            NextEntry.Free;
          end;
        end;
      end;
    end;
  end;
  
  // insert new entry
  NewEntry:=TLFMChangeEntry.Create;
  NewEntry.NewText:=NewText;
  NewEntry.StartPos:=StartPos;
  NewEntry.EndPos:=EndPos;
  if LFMChangeList.Count=0 then begin
    LFMChangeList.Add(NewEntry);
  end else begin
    for i:=0 to LFMChangeList.Count-1 do begin
      Entry:=TLFMChangeEntry(LFMChangeList[i]);
      if Entry.StartPos>EndPos then begin
        LFMChangeList.Insert(i,NewEntry);
        break;
      end else begin
        if (i<LFMChangeList.Count-1) then
          NextEntry:=TLFMChangeEntry(LFMChangeList[i+1])
        else
          NextEntry:=nil;
        if NextEntry.StartPos>EndPos then begin
          LFMChangeList.Insert(i+1,NewEntry);
          break;
        end;
      end;
    end;
  end;
end;

function TCheckLFMDialog.ApplyReplacements(LFMChangeList: TList): boolean;
var
  i: Integer;
  Entry: TLFMChangeEntry;
begin
  Result:=false;
  //writeln(LFMSource.Source);
  for i:=LFMChangeList.Count-1 downto 0 do begin
    Entry:=TLFMChangeEntry(LFMChangeList[i]);
    writeln('TCheckLFMDialog.ApplyReplacements A ',i,' ',Entry.StartPos,',',Entry.EndPos,
      ' "',copy(LFMSource.Source,Entry.StartPos,Entry.EndPos-Entry.StartPos),'" -> "',Entry.NewText,'"');
    LFMSource.Replace(Entry.StartPos,Entry.EndPos-Entry.StartPos,Entry.NewText);
  end;
  //writeln(LFMSource.Source);
  Result:=true;
end;

procedure TCheckLFMDialog.LoadLFM;
begin
  LFMSynEdit.Lines.Text:=LFMSource.Source;
  FillErrorsListBox;
end;

procedure TCheckLFMDialog.FillErrorsListBox;
var
  CurError: TLFMError;
  Filename: String;
  Msg: String;
begin
  ErrorsListBox.Items.BeginUpdate;
  ErrorsListBox.Items.Clear;
  if LFMTree<>nil then begin
    Filename:=ExtractFileName(LFMSource.Filename);
    CurError:=LFMTree.FirstError;
    while CurError<>nil do begin
      Msg:=Filename
           +'('+IntToStr(CurError.Caret.Y)+','+IntToStr(CurError.Caret.X)+')'
           +' Error: '
           +CurError.ErrorMessage;
      ErrorsListBox.Items.Add(Msg);
      CurError:=CurError.NextError;
    end;
  end;
  ErrorsListBox.Items.EndUpdate;
end;

function TCheckLFMDialog.AutomaticFixIsPossible: boolean;
var
  CurError: TLFMError;
begin
  Result:=true;
  CurError:=LFMTree.FirstError;
  while CurError<>nil do begin
    if CurError.ErrorType in [lfmeNoError,lfmeIdentifierNotFound,
      lfmeObjectNameMissing,lfmeObjectIncompatible,lfmePropertyNameMissing,
      lfmePropertyHasNoSubProperties,lfmeIdentifierNotPublished]
    then begin
      // these things can be fixed automatically
    end else begin
      // these not
      Result:=false;
      exit;
    end;
    CurError:=CurError.NextError;
  end;
end;

initialization
  {$I checklfmdlg.lrs}

end.

