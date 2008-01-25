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

  see for todo list: http://wiki.lazarus.freepascal.org/index.php/LazDoc
}

unit FPDocEditWindow;

{$mode objfpc}{$H+}

{ $define VerboseCodeHelp}

interface

uses
  // FCL
  Classes, SysUtils, StrUtils,
  // LCL
  LCLProc, LResources, StdCtrls, Buttons, ComCtrls, Controls, Dialogs,
  ExtCtrls, Forms, Graphics,
  // Synedit
  SynEdit,
  // codetools
  FileProcs, CodeAtom, CodeCache, CodeToolManager,
  Laz_DOM, Laz_XMLRead, Laz_XMLWrite,
  // IDEIntf
  IDEHelpIntf, LazHelpIntf,
  // IDE
  IDEOptionDefs, EnvironmentOpts,
  IDEProcs, LazarusIDEStrConsts, FPDocSelectInherited, CodeHelp;

type
  TFPDocEditorFlag = (
    fpdefWriting,
    fpdefChainNeedsUpdate,
    fpdefCaptionNeedsUpdate,
    fpdefValueControlsNeedsUpdate,
    fpdefInheritedControlsNeedsUpdate,
    fpdefLinkIDComboNeedsUpdate
    );
  TFPDocEditorFlags = set of TFPDocEditorFlag;
  
  { TFPDocEditor }

  TFPDocEditor = class(TForm)
    AddLinkButton: TButton;
    BrowseExampleButton: TButton;
    SaveButton: TButton;
    CreateButton: TButton;
    CopyFromInheritedButton: TButton;
    MoveToInheritedButton: TButton;
    InheritedShortEdit: TEdit;
    ExampleEdit: TEdit;
    InheritedShortLabel: TLabel;
    LinkIdComboBox: TComboBox;
    DeleteLinkButton: TButton;
    DescrMemo: TMemo;
    LinkTextEdit: TEdit;
    LinkListBox: TListBox;
    OpenDialog: TOpenDialog;
    Panel1: TPanel;
    ShortEdit: TEdit;
    ErrorsMemo: TMemo;
    PageControl: TPageControl;
    DescrTabSheet: TTabSheet;
    ErrorsTabSheet: TTabSheet;
    ShortTabSheet: TTabSheet;
    BoldFormatButton: TSpeedButton;
    ItalicFormatButton: TSpeedButton;
    InsertCodeTagButton: TSpeedButton;
    InsertRemarkButton: TSpeedButton;
    InsertVarTagButton: TSpeedButton;
    ExampleTabSheet: TTabSheet;
    InheritedTabSheet: TTabSheet;
    UnderlineFormatButton: TSpeedButton;
    SeeAlsoTabSheet: TTabSheet;
    procedure AddLinkButtonClick(Sender: TObject);
    procedure BrowseExampleButtonClick(Sender: TObject);
    procedure CopyFromInheritedButtonClick(Sender: TObject);
    procedure CreateButtonClick(Sender: TObject);
    procedure DeleteLinkButtonClick(Sender: TObject);
    procedure DocumentationTagChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormatButtonClick(Sender: TObject);
    procedure LinkChange(Sender: TObject);
    procedure LinkListBoxClick(Sender: TObject);
    procedure ApplicationIdle(Sender: TObject; var Done: Boolean);
    procedure MoveToInheritedButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
  private
    FCaretXY: TPoint;
    FModified: Boolean;
    FFlags: TFPDocEditorFlags;
    fUpdateLock: Integer;
    fSourceFilename: string;
    fChain: TCodeHelpElementChain;
    FOldValues: TFPDocElementValues;
    function GetDoc: TXMLdocument;
    function GetDocFile: TLazFPDocFile;
    function GetSourceFilename: string;
    function GetFirstElement: TDOMNode;

    function GetContextTitle(Element: TCodeHelpElement): string;

    function MakeLink: String;
    function FindInheritedIndex: integer;
    procedure Save;
    function GetValues: TFPDocElementValues;
    procedure SetModified(const AValue: boolean);
    function WriteNode(Element: TCodeHelpElement; Values: TFPDocElementValues;
                       Interactive: Boolean): Boolean;
    procedure UpdateChain;
    procedure UpdateCaption;
    procedure UpdateLinkIdComboBox;
    procedure UpdateValueControls;
    procedure UpdateInheritedControls;
    procedure OnLazDocChanging(Sender: TObject; LazDocFPFile: TLazFPDocFile);
    procedure OnLazDocChanged(Sender: TObject; LazDocFPFile: TLazFPDocFile);
    procedure LoadGUIValues(Element: TCodeHelpElement);
    procedure MoveToInherited(Element: TCodeHelpElement);
    function CreateElement(Element: TCodeHelpElement): Boolean;
  public
    procedure Reset;
    procedure InvalidateChain;
    procedure UpdateFPDocEditor(const SrcFilename: string; const Caret: TPoint);
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure ClearEntry(DoSave: Boolean);
    property DocFile: TLazFPDocFile read GetDocFile;
    property Doc: TXMLdocument read GetDoc;
    property SourceFilename: string read GetSourceFilename;
    property CaretXY: TPoint read FCaretXY;
    property Modified: boolean read FModified write SetModified;
  end;

var
  FPDocEditor: TFPDocEditor = nil;

procedure DoShowFPDocEditor;

implementation

{ TFPDocEditor }

procedure DoShowFPDocEditor;
begin
  if FPDocEditor = Nil then begin
    Application.CreateForm(TFPDocEditor, FPDocEditor);
    EnvironmentOptions.IDEWindowLayoutList.ItemByEnum(nmiwFPDocEditorName).Apply;
  end;

  FPDocEditor.Show;
end;

function TFPDocEditor.GetFirstElement: TDOMNode;
var
  CurDocFile: TLazFPDocFile;
begin
  Result:=nil;
  CurDocFile:=DocFile;
  if CurDocFile=nil then exit;
  Result:=CurDocFile.GetFirstElement;
end;

procedure TFPDocEditor.UpdateLinkIdComboBox;
// fills LinkIdComboBox.Items
var
  n: TDOMNode;
  sl: TStringList;
begin
  if fUpdateLock>0 then begin
    Include(FFLags,fpdefLinkIDComboNeedsUpdate);
    exit;
  end;
  Exclude(FFLags,fpdefLinkIDComboNeedsUpdate);

  {$IFDEF VerboseCodeHelp}
  DebugLn(['TFPDocEditForm.UpdateLinkIdComboBox START']);
  {$ENDIF}
  LinkIdComboBox.Clear;
  if Doc=nil then exit;

  // element nodes
  sl:=TStringList.Create;
  n := GetFirstElement;
  while n<>nil do
  begin
    if n.NodeName <> '#comment' then
      sl.Add(TDomElement(n)['name']);
    n := n.NextSibling;
  end;
  LinkIdComboBox.Items.Assign(sl);
  sl.Free;
end;

procedure TFPDocEditor.FormCreate(Sender: TObject);
begin
  Caption := lisCodeHelpMainFormCaption;

  with PageControl do
  begin
    Page[0].Caption := lisCodeHelpShortTag;
    Page[1].Caption := lisCodeHelpDescrTag;
    Page[2].Caption := lisCodeHelpErrorsTag;
    Page[3].Caption := lisCodeHelpSeeAlsoTag;
    Page[4].Caption := lisCodeHelpExampleTag;
    Page[5].Caption := lisCodeHelpInherited;
    PageIndex := 0;
  end;

  BoldFormatButton.Hint := lisCodeHelpHintBoldFormat;
  ItalicFormatButton.Hint := lisCodeHelpHintItalicFormat;
  UnderlineFormatButton.Hint := lisCodeHelpHintUnderlineFormat;
  InsertCodeTagButton.Hint := lisCodeHelpHintInsertCodeTag;
  InsertRemarkButton.Hint := lisCodeHelpHintRemarkTag;
  InsertVarTagButton.Hint := lisCodeHelpHintVarTag;

  CreateButton.Caption := lisCodeHelpCreateButton;
  CreateButton.Enabled:=false;
  SaveButton.Caption := lisCodeHelpSaveButton;
  SaveButton.Enabled:=false;

  AddLinkButton.Caption := lisCodeHelpAddLinkButton;
  DeleteLinkButton.Caption := lisCodeHelpDeleteLinkButton;

  BrowseExampleButton.Caption := lisCodeHelpBrowseExampleButton;
  
  MoveToInheritedButton.Caption:=lisLDMoveEntriesToInherited;
  CopyFromInheritedButton.Caption:=lisLDCopyFromInherited;
  
  Reset;
  
  CodeHelpBoss.AddHandlerOnChanging(@OnLazDocChanging);
  CodeHelpBoss.AddHandlerOnChanged(@OnLazDocChanged);
  Application.AddOnIdleHandler(@ApplicationIdle);
  
  Name := NonModalIDEWindowNames[nmiwFPDocEditorName];
  EnvironmentOptions.IDEWindowLayoutList.Apply(Self, Name);
end;

procedure TFPDocEditor.FormDestroy(Sender: TObject);
begin
  Reset;
  FreeAndNil(fChain);
  CodeHelpBoss.RemoveAllHandlersOfObject(Self);
  Application.RemoveAllHandlersOfObject(Self);
end;

procedure TFPDocEditor.FormResize(Sender: TObject);
begin
  LinkIdComboBox.Width := (AddLinkButton.Left - LinkIdComboBox.Left - 8) div 2;
end;

procedure TFPDocEditor.FormatButtonClick(Sender: TObject);

  procedure InsertTag(starttag, endtag: String);
  begin
    if PageControl.ActivePage.Caption = lisCodeHelpDescrTag then
      DescrMemo.SelText := starttag + DescrMemo.SelText + endtag;
    if PageControl.ActivePage.Caption = lisCodeHelpErrorsTag then
      ErrorsMemo.SelText := starttag + ErrorsMemo.SelText + endtag;
  end;

begin
  case TSpeedButton(Sender).Tag of
    //bold
    0:
      InsertTag('<b>', '</b>');
    //italic
    1:
      InsertTag('<i>', '</i>');
    //underline
    2:
      InsertTag('<u>', '</u>');
    //codetag
    3:
      InsertTag('<p><code>', '</code></p>');
    //remarktag
    4:
      InsertTag('<p><remark>', '</remark></p>');
    //vartag
    5:
      InsertTag('<var>', '</var>');
  end;
end;

procedure TFPDocEditor.LinkChange(Sender: TObject);
begin
  if LinkListBox.ItemIndex<0 then
    Exit;

  LinkListBox.Items.Strings[LinkListBox.ItemIndex] := MakeLink;
end;

procedure TFPDocEditor.LinkListBoxClick(Sender: TObject);
var
  strTmp: String;
  intTmp: Integer;
  intStart: Integer;
  LinkIndex: LongInt;
begin
  //split the link into Id and Text
  LinkIndex := LinkListBox.ItemIndex;
  if LinkIndex = -1 then
    Exit;

  intStart := PosEx('"', LinkListBox.Items[LinkIndex], 1);

  intTmp := PosEx('"', LinkListBox.Items[LinkIndex], intStart + 1);

  LinkIdComboBox.Text := Copy(LinkListBox.Items[LinkIndex],
    intStart + 1, intTmp - intStart - 1);

  strTmp := Copy(LinkListBox.Items[LinkIndex], intTmp + 2,
    Length(LinkListBox.Items[LinkIndex]));

  if strTmp = '>' then
    LinkTextEdit.Text := ''
  else
    LinkTextEdit.Text := Copy(strTmp, 1, Length(strTmp) - Length('</link>'));
end;

procedure TFPDocEditor.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  Done:=false;
  if fpdefChainNeedsUpdate in FFlags then
    UpdateChain
  else if fpdefCaptionNeedsUpdate in FFlags then
    UpdateCaption
  else if fpdefValueControlsNeedsUpdate in FFlags then
    UpdateValueControls
  else if fpdefInheritedControlsNeedsUpdate in FFlags then
    UpdateInheritedControls
  else if fpdefLinkIDComboNeedsUpdate in FFlags then
    UpdateLinkIdComboBox
  else
    Done:=true;
end;

procedure TFPDocEditor.MoveToInheritedButtonClick(Sender: TObject);
var
  i: Integer;
  Element: TCodeHelpElement;
  Candidates: TFPList;
  FPDocSelectInheritedDlg: TFPDocSelectInheritedDlg;
  ShortDescr: String;
begin
  if fChain=nil then exit;
  Candidates:=nil;
  FPDocSelectInheritedDlg:=nil;
  try
    // find all entries till the first inherited entry with a description
    for i:=1 to fChain.Count-1 do begin
      Element:=fChain[i];
      if Candidates=nil then
        Candidates:=TFPList.Create;
      Candidates.Add(Element);
      if (Element.ElementNode<>nil)
      and (Element.FPDocFile.GetValueFromNode(Element.ElementNode,fpdiShort)<>'')
      then
        break;
    end;
    
    // choose one entry
    if (Candidates=nil) or (Candidates.Count=0) then exit;
    if Candidates.Count=1 then begin
      // there is only one candidate
      Element:=TCodeHelpElement(Candidates[0]);
      if (Element.ElementNode<>nil) then begin
        ShortDescr:=Element.FPDocFile.GetValueFromNode(Element.ElementNode,fpdiShort);
        if ShortDescr<>'' then begin
          // the inherited entry already contains a description.
          // ask if it should be really replaced
          if QuestionDlg(lisCodeHelpConfirmreplace,
            GetContextTitle(Element)+' already contains the help:'+#13
            +ShortDescr,
            mtConfirmation,[mrYes,lisCodeHelpReplaceButton,mrCancel],0)<>mrYes then exit;
        end;
      end;
    end else begin
      // there is more than one candidate
      // => ask which one to replace
      FPDocSelectInheritedDlg:=TFPDocSelectInheritedDlg.Create(nil);
      FPDocSelectInheritedDlg.InheritedComboBox.Items.Clear;
      for i:=0 to Candidates.Count-1 do begin
        Element:=TCodeHelpElement(Candidates[i]);
        FPDocSelectInheritedDlg.InheritedComboBox.Items.Add(
                                                      GetContextTitle(Element));
      end;
      if FPDocSelectInheritedDlg.ShowModal<>mrOk then exit;
      i:=FPDocSelectInheritedDlg.InheritedComboBox.ItemIndex;
      if i<0 then exit;
      Element:=TCodeHelpElement(Candidates[i]);
    end;

    // move the content of the current entry to the inherited entry
    MoveToInherited(Element);
  finally
    FPDocSelectInheritedDlg.Free;
    Candidates.Free;
  end;
end;

procedure TFPDocEditor.SaveButtonClick(Sender: TObject);
begin
  Save;
end;

function TFPDocEditor.GetContextTitle(Element: TCodeHelpElement): string;
// get codetools path. for example: TButton.Align
begin
  Result:='';
  if Element=nil then exit;
  Result:=Element.ElementName;
end;

function TFPDocEditor.GetDoc: TXMLdocument;
begin
  if DocFile<>nil then
    Result:=DocFile.Doc
  else
    Result:=nil;
end;

function TFPDocEditor.GetDocFile: TLazFPDocFile;
begin
  Result:=nil;
  if fChain=nil then exit;
  Result:=fChain.DocFile;
end;

function TFPDocEditor.GetSourceFilename: string;
begin
  Result:=fSourceFilename;
end;

procedure TFPDocEditor.UpdateCaption;
var
  strCaption: String;
begin
  if fUpdateLock>0 then begin
    Include(FFlags,fpdefCaptionNeedsUpdate);
    exit;
  end;
  Exclude(FFlags,fpdefCaptionNeedsUpdate);
  
  {$IFDEF VerboseCodeHelp}
  DebugLn(['TFPDocEditForm.UpdateCaption START']);
  {$ENDIF}
  strCaption := lisCodeHelpMainFormCaption + ' - ';

  if (fChain <> nil) and (fChain.Count>0) then
    strCaption := strCaption + GetContextTitle(fChain[0]) + ' - '
  else
    strCaption := strCaption + lisCodeHelpNoTagCaption + ' - ';

  if DocFile<>nil then
    Caption := strCaption + DocFile.Filename
  else
    Caption := strCaption + lisCodeHelpNoTagCaption;
  {$IFDEF VerboseCodeHelp}
  DebugLn(['TLazDocForm.UpdateCaption ',Caption]);
  {$ENDIF}
end;

procedure TFPDocEditor.UpdateValueControls;
var
  Element: TCodeHelpElement;
begin
  if fUpdateLock>0 then begin
    Include(FFLags,fpdefValueControlsNeedsUpdate);
    exit;
  end;
  Exclude(FFLags,fpdefValueControlsNeedsUpdate);

  {$IFDEF VerboseCodeHelp}
  DebugLn(['TFPDocEditForm.UpdateValueControls START']);
  {$ENDIF}
  Element:=nil;
  if (fChain<>nil) and (fChain.Count>0) then
    Element:=fChain[0];
  LoadGUIValues(Element);
  SaveButton.Enabled:=FModified;
end;

procedure TFPDocEditor.UpdateInheritedControls;
var
  i: LongInt;
  Element: TCodeHelpElement;
  ShortDescr: String;
begin
  if fUpdateLock>0 then begin
    Include(FFLags,fpdefInheritedControlsNeedsUpdate);
    exit;
  end;
  Exclude(FFLags,fpdefInheritedControlsNeedsUpdate);

  {$IFDEF VerboseCodeHelp}
  DebugLn(['TFPDocEditForm.UpdateInheritedControls START']);
  {$ENDIF}
  i:=FindInheritedIndex;
  if i<0 then begin
    InheritedShortEdit.Text:='';
    InheritedShortEdit.Enabled:=false;
    InheritedShortLabel.Caption:=lisCodeHelpnoinheriteddescriptionfound;
  end else begin
    Element:=fChain[i];
    ShortDescr:=Element.FPDocFile.GetValueFromNode(Element.ElementNode,fpdiShort);
    InheritedShortEdit.Text:=ShortDescr;
    InheritedShortEdit.Enabled:=true;
    InheritedShortLabel.Caption:=lisCodeHelpShortdescriptionof+' '
                                 +GetContextTitle(Element);
  end;
  MoveToInheritedButton.Enabled:=(fChain<>nil)
                                 and (fChain.Count>1)
                                 and (ShortEdit.Text<>'');
  CopyFromInheritedButton.Enabled:=(i>=0);
end;

procedure TFPDocEditor.UpdateChain;
var
  Code: TCodeBuffer;
  LDResult: TCodeHelpParseResult;
  NewChain: TCodeHelpElementChain;
  CacheWasUsed: Boolean;
begin
  FreeAndNil(fChain);
  if fUpdateLock>0 then begin
    Include(FFLags,fpdefChainNeedsUpdate);
    exit;
  end;
  Exclude(FFLags,fpdefChainNeedsUpdate);

  if (fSourceFilename='') or (CaretXY.X<1) or (CaretXY.Y<1) then exit;

  {$IFDEF VerboseCodeHelp}
  DebugLn(['TFPDocEditForm.UpdateChain START']);
  {$ENDIF}
  NewChain:=nil;
  try
    // fetch pascal source
    Code:=CodeToolBoss.LoadFile(fSourceFilename,true,false);
    if Code=nil then begin
      DebugLn(['TFPDocEditForm.UpdateChain failed loading ',fSourceFilename]);
      exit;
    end;

    // start getting the lazdoc element chain
    LDResult:=CodeHelpBoss.GetElementChain(Code,CaretXY.X,CaretXY.Y,true,
                                         NewChain,CacheWasUsed);
    case LDResult of
    chprParsing:
      begin
        Include(FFLags,fpdefChainNeedsUpdate);
        DebugLn(['TFPDocEditForm.UpdateChain ToDo: still parsing LazDocBoss.GetElementChain for ',fSourceFilename,' ',dbgs(CaretXY)]);
        exit;
      end;
    chprFailed:
      begin
        //DebugLn(['TFPDocEditForm.UpdateChain failed LazDocBoss.GetElementChain for ',fSourceFilename,' ',dbgs(CaretXY)]);
        exit;
      end;
    else
      fChain:=NewChain;
      NewChain:=nil;
    end;
  finally
    NewChain.Free;
  end;
end;

procedure TFPDocEditor.OnLazDocChanging(Sender: TObject;
  LazDocFPFile: TLazFPDocFile);
begin
  if fpdefWriting in FFlags then exit;
  if (fChain<>nil) and (fChain.IndexOfFile(LazDocFPFile)>=0) then
    InvalidateChain;
end;

procedure TFPDocEditor.OnLazDocChanged(Sender: TObject;
  LazDocFPFile: TLazFPDocFile);
begin
  if fpdefWriting in FFlags then exit;

end;

procedure TFPDocEditor.LoadGUIValues(Element: TCodeHelpElement);
var
  EnabledState: Boolean;
  OldModified: Boolean;
begin
  OldModified:=FModified;
  
  EnabledState := (Element<>nil) and (Element.ElementNode<>nil);
  
  CreateButton.Enabled := (Element<>nil) and (Element.ElementNode=nil)
                          and (Element.ElementName<>'');

  if EnabledState then
  begin
    FOldValues:=Element.FPDocFile.GetValuesFromNode(Element.ElementNode);
    ShortEdit.Text := ConvertLineEndings(FOldValues[fpdiShort]);
    DescrMemo.Lines.Text := ConvertLineEndings(FOldValues[fpdiDescription]);
    ErrorsMemo.Lines.Text := ConvertLineEndings(FOldValues[fpdiErrors]);
    LinkListBox.Items.Text := ConvertLineEndings(FOldValues[fpdiSeeAlso]);
    LinkIdComboBox.Text := '';
    LinkTextEdit.Clear;
    ExampleEdit.Text := ConvertLineEndings(FOldValues[fpdiExample]);
  end
  else
  begin
    ShortEdit.Text := lisCodeHelpNoDocumentation;
    DescrMemo.Lines.Text := lisCodeHelpNoDocumentation;
    ErrorsMemo.Lines.Text := lisCodeHelpNoDocumentation;
    LinkIdComboBox.Text := lisCodeHelpNoDocumentation;
    LinkTextEdit.Text := lisCodeHelpNoDocumentation;
    LinkListBox.Clear;
    ExampleEdit.Text := lisCodeHelpNoDocumentation;
  end;

  ShortEdit.Enabled := EnabledState;
  DescrMemo.Enabled := EnabledState;
  ErrorsMemo.Enabled := EnabledState;
  LinkIdComboBox.Enabled := EnabledState;
  LinkTextEdit.Enabled := EnabledState;
  LinkListBox.Enabled := EnabledState;
  AddLinkButton.Enabled := EnabledState;
  DeleteLinkButton.Enabled := EnabledState;
  ExampleEdit.Enabled := EnabledState;
  BrowseExampleButton.Enabled := EnabledState;

  FModified:=OldModified;
end;

procedure TFPDocEditor.MoveToInherited(Element: TCodeHelpElement);
var
  Values: TFPDocElementValues;
begin
  Values:=GetValues;
  WriteNode(Element,Values,true);
end;

function TFPDocEditor.CreateElement(Element: TCodeHelpElement): Boolean;
var
  NewElement: TCodeHelpElement;
begin
  DebugLn(['TFPDocEditForm.CreateElement ']);
  if (Element=nil) or (Element.ElementName='') then exit(false);
  NewElement:=nil;
  Include(FFlags,fpdefWriting);
  try
    Result:=CodeHelpBoss.CreateElement(Element.CodeXYPos.Code,
                            Element.CodeXYPos.X,Element.CodeXYPos.Y,NewElement);
  finally
    Exclude(FFlags,fpdefWriting);
    NewElement.Free;
  end;
  Reset;
  InvalidateChain;
end;

procedure TFPDocEditor.Reset;
begin
  FreeAndNil(fChain);

  // clear all element editors/viewers
  ShortEdit.Clear;
  DescrMemo.Clear;
  ErrorsMemo.Clear;
  LinkIdComboBox.Text := '';
  LinkTextEdit.Clear;
  LinkListBox.Clear;
  ExampleEdit.Clear;

  Modified := False;
  CreateButton.Enabled:=false;
end;

procedure TFPDocEditor.InvalidateChain;
begin
  FreeAndNil(fChain);
  FFlags:=FFlags+[fpdefChainNeedsUpdate,fpdefCaptionNeedsUpdate,
      fpdefValueControlsNeedsUpdate,fpdefInheritedControlsNeedsUpdate,
      fpdefLinkIDComboNeedsUpdate];
end;

procedure TFPDocEditor.UpdateFPDocEditor(const SrcFilename: string;
  const Caret: TPoint);
var
  NewSrcFilename: String;
begin
  // save the current changes to documentation
  Save;
  // check if visible
  if not Visible then exit;
  
  NewSrcFilename:=CleanAndExpandFilename(SrcFilename);
  if (NewSrcFilename=SourceFilename) and (CompareCaret(Caret,CaretXY)=0)
  and (fChain<>nil) and fChain.IsValid then
    exit;

  FCaretXY:=Caret;
  fSourceFilename:=NewSrcFilename;
  
  Reset;
  InvalidateChain;
end;

procedure TFPDocEditor.BeginUpdate;
begin
  inc(fUpdateLock);
end;

procedure TFPDocEditor.EndUpdate;
begin
  dec(fUpdateLock);
  if fUpdateLock<0 then RaiseGDBException('');
  if fUpdateLock=0 then begin
    if fpdefCaptionNeedsUpdate in FFlags then UpdateCaption;
  end;
end;

procedure TFPDocEditor.ClearEntry(DoSave: Boolean);
begin
  Modified:=true;
  ShortEdit.Text:='';
  DescrMemo.Text:='';
  ErrorsMemo.Text:='';
  LinkListBox.Items.Clear;
  ExampleEdit.Text:='';
  if DoSave then Save;
end;

procedure TFPDocEditor.Save;
var
  Values: TFPDocElementValues;
begin
  if not FModified then Exit; // nothing changed => exit
  FModified:=false;
  if (fChain=nil) or (fChain.Count=0) then exit;
  if not fChain.IsValid then exit;
  Values:=GetValues;
  if not WriteNode(fChain[0],Values,true) then begin
    DebugLn(['TLazDocForm.Save FAILED']);
  end else begin
    FModified := False;
  end;
  SaveButton.Enabled:=false;
end;

function TFPDocEditor.GetValues: TFPDocElementValues;
begin
  Result[fpdiShort]:=ShortEdit.Text;
  Result[fpdiDescription]:=DescrMemo.Text;
  Result[fpdiErrors]:=ErrorsMemo.Text;
  Result[fpdiSeeAlso]:=LinkListBox.Items.Text;
  Result[fpdiExample]:=ExampleEdit.Text;
end;

procedure TFPDocEditor.SetModified(const AValue: boolean);
begin
  if FModified=AValue then exit;
  FModified:=AValue;
  SaveButton.Enabled:=FModified;
end;

function TFPDocEditor.WriteNode(Element: TCodeHelpElement;
  Values: TFPDocElementValues; Interactive: Boolean): Boolean;
var
  TopNode: TDOMNode;
  CurDocFile: TLazFPDocFile;
  CurDoc: TXMLDocument;

  function Check(Test: boolean; const  Msg: string): Boolean;
  var
    CurName: String;
  begin
    Result:=Test;
    if not Test then exit;
    DebugLn(['TLazDocForm.WriteNode  ERROR ',Msg]);
    if Interactive then begin;
      if Element.FPDocFile<>nil then
        CurName:=Element.FPDocFile.Filename
      else
        CurName:=Element.ElementName;
      MessageDlg('Write error',
        'Error writing "'+CurName+'"'#13
        +Msg,mtError,[mbCancel],0);
    end;
  end;

  {procedure CheckAndWriteNode(const NodeName: String; NodeText: String;
    NodeIndex: TFPDocItem);
  var
    child: TDOMNode;
    FileAttribute: TDOMAttr;
    OldNode: TDOMNode;
    NewValue: String;
  begin
    DebugLn('TLazDocForm.Save[CheckAndWriteNode]: checking element: ' +
      NodeName);

    if CurNodeName <> NodeName then exit;

    NewValue:=ToUnixLineEnding(NodeText);
    if CurNodeName = 'example' then begin
      OldNode:=Node.Attributes.GetNamedItem('file');
      NewValue:=FilenameToURLPath(NewValue);
      if (NodeText<>'')
      or (not (OldNode is TDOMAttr))
      or (TDOMAttr(OldNode).Value<>NewValue) then begin
        DebugLn(['TLazDocForm.CheckAndWriteNode Changing NodeName=',NodeName,' NodeText="',NewValue,'"']);
        // add or change example
        FileAttribute := Entry.DocFile.Doc.CreateAttribute('file');
        FileAttribute.Value := NewValue;
        OldNode:=Node.Attributes.SetNamedItem(FileAttribute);
        OldNode.Free;
      end;
    end
    else if not Assigned(Node.FirstChild) then begin
      // add node
      if NodeText<>'' then begin
        DebugLn(['TLazDocForm.CheckAndWriteNode Adding NodeName=',NodeName,' NodeText="',NewValue,'"']);
        child := Entry.DocFile.Doc.CreateTextNode(NewValue);
        Node.AppendChild(child);
      end;
    end else begin
      // change node
      if Node.FirstChild.NodeValue <> NewValue then begin
        DebugLn(['TLazDocForm.CheckAndWriteNode Changing NodeName=',NodeName,' NodeText="',NewValue,'"']);
        Node.FirstChild.NodeValue := NewValue;
      end;
    end;
    NodeWritten[NodeIndex] := True;
  end;

  procedure CheckAndWriteNode(const NodeName: String; NodeType: TFPDocItem);
  begin
    CheckAndWriteNode(NodeName,DocNode[NodeType],NodeType);
  end;

  procedure InsertNodeElement(const ElementName, ElementText: String);
  var
    child: TDOMNode;
    FileAttribute: TDOMAttr;
  begin
    DebugLn('TLazDocForm.Save[InsertNodeElement]: inserting element: ' + ElementName);
    if (ElementText='') then exit;

    DebugLn(['InsertNodeElement Adding node ElementName=',ElementName,' ElementText="',ElementText,'"']);
    child := Entry.DocFile.doc.CreateElement(ElementName);
    if ElementName='example' then begin
      FileAttribute := Entry.DocFile.Doc.CreateAttribute('file');
      FileAttribute.Value := FilenameToURLPath(ElementText);
      child.Attributes.SetNamedItem(FileAttribute);
    end
    else begin
      child.AppendChild(Entry.DocFile.Doc.CreateTextNode(
                                                ToUnixLineEnding(ElementText)));
    end;
    TopNode.AppendChild(child);
  end;}
  
begin
  Result:=false;
  if fpdefWriting in FFlags then begin
    DebugLn(['TFPDocEditForm.WriteNode inconsistency detected: recursive write']);
    exit;
  end;
  
  if Check(Element=nil,'Element=nil') then exit;
  CurDocFile:=Element.FPDocFile;
  if Check(CurDocFile=nil,'Element.FPDocFile=nil') then begin
    // no fpdoc file found
    // TODO: create a new file
    DebugLn(['TFPDocEditForm.WriteNode TODO: implement creating new fpdoc file']);
    exit;
  end;
  CurDoc:=CurDocFile.Doc;
  if Check(CurDoc=nil,'Element.FPDocFile.Doc=nil') then exit;
  if Check(not Element.ElementNodeValid,'not Element.ElementNodeValid') then exit;
  TopNode:=Element.ElementNode;
  if Check(TopNode=nil,'TopNode=nil') then begin
    // no old node found
    // TODO: create a new node
    Check(false,'no old node found. TODO: implement creating a new.');
    Exit;
  end;

  Include(FFlags,fpdefWriting);
  CurDocFile.BeginUpdate;
  try
    CurDocFile.SetChildValue(TopNode,'short',Values[fpdiShort]);
    CurDocFile.SetChildValue(TopNode,'descr',Values[fpdiDescription]);
    CurDocFile.SetChildValue(TopNode,'errors',Values[fpdiErrors]);
    CurDocFile.SetChildValue(TopNode,'seealso',Values[fpdiSeeAlso]);
    CurDocFile.SetChildValue(TopNode,'example',Values[fpdiExample]);

  finally
    CurDocFile.EndUpdate;
    fChain.MakeValid;
    Exclude(FFlags,fpdefWriting);
  end;

  if CodeHelpBoss.SaveFPDocFile(CurDocFile)<>mrOk then begin
    DebugLn(['TFPDocEditForm.WriteNode failed writing ',CurDocFile.Filename]);
    exit;
  end;
  Result:=true;
end;

procedure TFPDocEditor.DocumentationTagChange(Sender: TObject);
begin
  Modified := True;
end;

function TFPDocEditor.MakeLink: String;
begin
  if Trim(LinkTextEdit.Text) = '' then
    Result := '<link id="' + Trim(LinkIdComboBox.Text) + '"/>'
  else
    Result := '<link id="' + Trim(LinkIdComboBox.Text) + '">' +
      LinkTextEdit.Text + '</link>';
end;

function TFPDocEditor.FindInheritedIndex: integer;
// returns Index in chain of an overriden Element with a short description
// returns -1 if not found
var
  Element: TCodeHelpElement;
begin
  if (fChain<>nil) then begin
    Result:=1;
    while (Result<fChain.Count) do begin
      Element:=fChain[Result];
      if (Element.ElementNode<>nil)
      and (Element.FPDocFile.GetValueFromNode(Element.ElementNode,fpdiShort)<>'')
      then
        exit;
      inc(Result);
    end;
  end;
  Result:=-1;
end;

procedure TFPDocEditor.AddLinkButtonClick(Sender: TObject);
begin
  if Trim(LinkIdComboBox.Text) <> '' then
  begin
    LinkListBox.Items.Add(MakeLink);
    Modified := True;
  end;
end;

procedure TFPDocEditor.BrowseExampleButtonClick(Sender: TObject);
begin
  if Doc=nil then exit;
  if OpenDialog.Execute then
    ExampleEdit.Text := SetDirSeparators(ExtractRelativepath(
      ExtractFilePath(DocFile.Filename), OpenDialog.FileName));
end;

procedure TFPDocEditor.CopyFromInheritedButtonClick(Sender: TObject);
var
  i: LongInt;
begin
  i:=FindInheritedIndex;
  if i<0 then exit;
  DebugLn(['TFPDocEditForm.CopyFromInheritedButtonClick ']);
  if ShortEdit.Text<>'' then begin
    if QuestionDlg('Confirm replace',
      GetContextTitle(fChain[0])+' already contains the help:'+#13
      +ShortEdit.Text,
      mtConfirmation,[mrYes,'Replace',mrCancel],0)<>mrYes then exit;
  end;
  LoadGUIValues(fChain[i]);
  Modified:=true;
end;

procedure TFPDocEditor.CreateButtonClick(Sender: TObject);
begin
  if (fChain=nil) or (fChain.Count=0) then exit;
  CreateElement(fChain[0]);
end;

procedure TFPDocEditor.DeleteLinkButtonClick(Sender: TObject);
begin
  if LinkListBox.ItemIndex >= 0 then begin
    LinkListBox.Items.Delete(LinkListBox.ItemIndex);
    DebugLn(['TFPDocEditForm.DeleteLinkButtonClick ']);
    Modified := True;
  end;
end;

initialization
  {$I fpdoceditwindow.lrs}

end.
