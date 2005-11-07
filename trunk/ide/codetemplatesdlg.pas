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

  Abstract:
    A dialog for adding and editing code templates

}
unit CodeTemplatesDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Graphics, Dialogs,
  ClipBrd, StdCtrls, Buttons, ExtCtrls, Menus,
  SynEdit, SynHighlighterPas, SynEditAutoComplete,
  IDECommands, TextTools, SrcEditorIntf, MenuIntf,
  InputHistory, LazarusIDEStrConsts, EditorOptions, CodeMacroSelect;

type

  { TCodeTemplateDialog }

  TCodeTemplateDialog = class(TForm)
    AddButton: TButton;
    UseMakrosCheckBox: TCheckBox;
    EditButton: TButton;
    DeleteButton: TButton;
    CancelButton: TButton;
    TemplateListBox: TListBox;
    TemplateSplitter: TSplitter;
    TemplateSynEdit: TSynEdit;
    ASynPasSyn: TSynPasSyn;
    TemplateGroupBox: TGroupBox;
    OkButton: TButton;
    FilenameButton: TButton;
    FilenameEdit: TEdit;
    FilenameGroupBox: TGroupBox;
    MainPopupMenu: TPopupMenu;
    procedure AddButtonClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure EditButtonClick(Sender: TObject);
    procedure FilenameButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure OnCopyMenuItem(Sender: TObject);
    procedure OnCutMenuItem(Sender: TObject);
    procedure OnInsertMacroMenuItem(Sender: TObject);
    procedure OnPasteMenuItem(Sender: TObject);
    procedure TemplateListBoxSelectionChange(Sender: TObject; User: boolean);
  private
    SynAutoComplete: TSynEditAutoComplete;
    LastTemplate: integer;
    procedure BuildPopupMenu;
  public
    procedure FillCodeTemplateListBox;
    procedure ShowCurCodeTemplate;
    procedure SaveCurCodeTemplate;
  end;

  { TCodeTemplateEditForm }

  TCodeTemplateEditForm = class(TForm)
    TokenLabel: TLabel;
    TokenEdit: TEdit;
    CommentLabel: TLabel;
    CommentEdit: TEdit;
    OkButton: TButton;
    CancelButton: TButton;
    procedure CodeTemplateEditFormResize(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
    SynAutoComplete: TSynEditAutoComplete;
    TemplateIndex: integer;
  end;
  
  { TLazCodeMacros }

  TLazCodeMacros = class(TIDECodeMacros)
  private
    FItems: TFPList; // list of TIDECodeMacro
  protected
    function GetItems(Index: integer): TIDECodeMacro; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    property Items[Index: integer]: TIDECodeMacro read GetItems; default;
    function Count: integer; override;
    function Add(Macro: TIDECodeMacro): integer; override;
    function FindByName(const AName: string): TIDECodeMacro; override;
    function CreateUniqueName(const AName: string): string; override;
  end;

function ShowCodeTemplateDialog: TModalResult;

function AddCodeTemplate(ASynAutoComplete: TSynEditAutoComplete;
  var Token, Comment: string): TModalResult;
function EditCodeTemplate(ASynAutoComplete: TSynEditAutoComplete;
  Index: integer): TModalResult;
  
procedure CreateStandardCodeMacros;

// standard code macros
function CodeMakroUpper(const Parameter: string; InteractiveValue: TPersistent;
                        SrcEdit: TSourceEditorInterface;
                        var Value, ErrorMsg: string): boolean;
function CodeMakroLower(const Parameter: string; InteractiveValue: TPersistent;
                        SrcEdit: TSourceEditorInterface;
                        var Value, ErrorMsg: string): boolean;
function CodeMakroPaste(const Parameter: string; InteractiveValue: TPersistent;
                        SrcEdit: TSourceEditorInterface;
                        var Value, ErrorMsg: string): boolean;

const
  CodeTemplatesMenuRootName = 'CodeTemplates';

var
  CodeTemplateCopyIDEMenuCommand: TIDEMenuCommand;
  CodeTemplateCutIDEMenuCommand: TIDEMenuCommand;
  CodeTemplatePasteIDEMenuCommand: TIDEMenuCommand;
  CodeTemplateInsertMacroIDEMenuCommand: TIDEMenuCommand;

procedure RegisterStandardCodeTemplatesMenuItems;

implementation

function ShowCodeTemplateDialog: TModalResult;
var
  CodeTemplateDialog: TCodeTemplateDialog;
begin
  CodeTemplateDialog:=TCodeTemplateDialog.Create(nil);
  Result:=CodeTemplateDialog.ShowModal;
  CodeTemplateDialog.Free;
end;

function AddCodeTemplate(ASynAutoComplete:TSynEditAutoComplete;
  var Token,Comment:ansistring):TModalResult;
var
  CodeTemplateEditForm:TCodeTemplateEditForm;
begin
  Result:=mrCancel;
  CodeTemplateEditForm:=TCodeTemplateEditForm.Create(nil);
  try
    CodeTemplateEditForm.SynAutoComplete:=ASynAutoComplete;
    CodeTemplateEditForm.TemplateIndex:=ASynAutoComplete.Completions.Count;
    CodeTemplateEditForm.Caption:=lisCodeTemplAddCodeTemplate;
    CodeTemplateEditForm.OkButton.Caption:=lisCodeTemplAdd;
    CodeTemplateEditForm.TokenEdit.Text:=Token;
    CodeTemplateEditForm.CommentEdit.Text:=Comment;
    Result:=CodeTemplateEditForm.ShowModal;
    if Result=mrOk then begin
      Token:=CodeTemplateEditForm.TokenEdit.Text;
      Comment:=CodeTemplateEditForm.CommentEdit.Text;
    end;
  finally
    CodeTemplateEditForm.Free;
  end;
end;

function EditCodeTemplate(ASynAutoComplete:TSynEditAutoComplete;
  Index:integer):TModalResult;
var
  CodeTemplateEditForm:TCodeTemplateEditForm;
begin
  Result:=mrCancel;
  if (Index<0) or (Index>=ASynAutoComplete.Completions.Count) then exit;
  CodeTemplateEditForm:=TCodeTemplateEditForm.Create(nil);
  try
    CodeTemplateEditForm.SynAutoComplete:=ASynAutoComplete;
    CodeTemplateEditForm.TemplateIndex:=Index;
    CodeTemplateEditForm.Caption:=lisCodeTemplEditCodeTemplate;
    CodeTemplateEditForm.OkButton.Caption:=lisCodeTemplChange;
    CodeTemplateEditForm.TokenEdit.Text:=ASynAutoComplete.Completions[Index];
    CodeTemplateEditForm.CommentEdit.Text:=
      ASynAutoComplete.CompletionComments[Index];
    Result:=CodeTemplateEditForm.ShowModal;
    if Result=mrOk then begin
      ASynAutoComplete.Completions[Index]:=
        CodeTemplateEditForm.TokenEdit.Text;
      ASynAutoComplete.CompletionComments[Index]:=
        CodeTemplateEditForm.CommentEdit.Text;
    end;
  finally
    CodeTemplateEditForm.Free;
  end;
end;

function CodeMakroUpper(const Parameter: string; InteractiveValue: TPersistent;
                        SrcEdit: TSourceEditorInterface;
                        var Value, ErrorMsg: string): boolean;
begin
  Value:=UpperCase(Parameter);
  Result:=true;
end;
                        
function CodeMakroLower(const Parameter: string; InteractiveValue: TPersistent;
                        SrcEdit: TSourceEditorInterface;
                        var Value, ErrorMsg: string): boolean;
begin
  Value:=LowerCase(Parameter);
  Result:=true;
end;

function CodeMakroPaste(const Parameter: string; InteractiveValue: TPersistent;
                        SrcEdit: TSourceEditorInterface;
                        var Value, ErrorMsg: string): boolean;
begin
  Value:=Clipboard.AsText;
  Result:=true;
end;

procedure RegisterStandardCodeTemplatesMenuItems;
var
  Path: string;
begin
  CodeTemplatesMenuRoot := RegisterIDEMenuRoot(CodeTemplatesMenuRootName);
  Path := CodeTemplatesMenuRoot.Name;
  CodeTemplateCutIDEMenuCommand := RegisterIDEMenuCommand(Path,'Cut','Cut');
  CodeTemplateCopyIDEMenuCommand := RegisterIDEMenuCommand(Path,'Copy','Copy');
  CodeTemplatePasteIDEMenuCommand := RegisterIDEMenuCommand(Path,'Paste','Paste');
  CodeTemplateInsertMacroIDEMenuCommand := RegisterIDEMenuCommand(Path,
                                                  'InsertMacro','Insert Macro');
end;

procedure CreateStandardCodeMacros;
begin
  IDECodeMacros:=TLazCodeMacros.Create;
  RegisterCodeMacro('Upper','uppercase string',
                    'Uppercase string given as parameter',
                    @CodeMakroUpper,nil);
  RegisterCodeMacro('Lower','lowercase string',
                    'Lowercase string given as parameter',
                    @CodeMakroLower,nil);
  RegisterCodeMacro('Paste','paste clipboard',
                    'Paste text from clipboard',
                    @CodeMakroPaste,nil);
end;

{ TCodeTemplateEditForm }

constructor TCodeTemplateEditForm.Create(TheOwner:TComponent);
begin
  inherited Create(TheOwner);
  if LazarusResources.Find(ClassName)=nil then begin
    Width:=300;
    Height:=150;
    Position:=poScreenCenter;
    OnResize:=@CodeTemplateEditFormResize;

    TokenLabel:=TLabel.Create(Self);
    with TokenLabel do begin
      Name:='TokenLabel';
      Parent:=Self;
      Caption:=lisCodeTemplToken;
      Left:=12;
      Top:=6;
      Width:=Self.ClientWidth-Left-Left;
      Show;
    end;

    TokenEdit:=TEdit.Create(Self);
    with TokenEdit do begin
      Name:='TokenEdit';
      Parent:=Self;
      Left:=10;
      Top:=TokenLabel.Top+TokenLabel.Height+2;
      Width:=Self.ClientWidth-Left-Left-4;
      Text:='';
      Show;
    end;

    CommentLabel:=TLabel.Create(Self);
    with CommentLabel do begin
      Name:='CommentLabel';
      Parent:=Self;
      Caption:=lisCodeTemplComment;
      Left:=12;
      Top:=TokenEdit.Top+TokenEdit.Height+10;
      Width:=Self.ClientWidth-Left-Left;
      Show;
    end;

    CommentEdit:=TEdit.Create(Self);
    with CommentEdit do begin
      Name:='CommentEdit';
      Parent:=Self;
      Left:=10;
      Top:=CommentLabel.Top+CommentLabel.Height+2;
      Width:=Self.ClientWidth-Left-Left-4;
      Text:='';
      Show;
    end;

    OkButton:=TButton.Create(Self);
    with OkButton do begin
      Name:='OkButton';
      Parent:=Self;
      Caption:=lisLazBuildOk;
      OnClick:=@OkButtonClick;
      Left:=50;
      Top:=Self.ClientHeight-Height-12;
      Width:=80;
      Show;
    end;

    CancelButton:=TButton.Create(Self);
    with CancelButton do begin
      Name:='CancelButton';
      Parent:=Self;
      Caption:=dlgCancel;
      ModalResult:=mrCancel;
      Width:=80;
      Left:=Self.ClientWidth-50-Width;
      Top:=Self.ClientHeight-Height-12;
      Show;
    end;
  end;
  CodeTemplateEditFormResize(nil);
end;

procedure TCodeTemplateEditForm.CodeTemplateEditFormResize(Sender: TObject);
begin
  with TokenLabel do begin
    Left:=12;
    Top:=6;
    Width:=Self.ClientWidth-Left-Left;
  end;

  with TokenEdit do begin
    Left:=10;
    Top:=TokenLabel.Top+TokenLabel.Height+2;
    Width:=Self.ClientWidth-Left-Left-4;
  end;

  with CommentLabel do begin
    Left:=12;
    Top:=TokenEdit.Top+TokenEdit.Height+10;
    Width:=Self.ClientWidth-Left-Left;
  end;

  with CommentEdit do begin
    Left:=10;
    Top:=CommentLabel.Top+CommentLabel.Height+2;
    Width:=Self.ClientWidth-Left-Left-4;
  end;

  with OkButton do begin
    Left:=50;
    Top:=Self.ClientHeight-Height-12;
    Width:=80;
  end;

  with CancelButton do begin
    Width:=80;
    Left:=Self.ClientWidth-50-Width;
    Top:=Self.ClientHeight-Height-12;
  end;
end;

procedure TCodeTemplateEditForm.OkButtonClick(Sender:TObject);
var a:integer;
  AText,ACaption:AnsiString;
begin
  a:=SynAutoComplete.Completions.IndexOf(TokenEdit.Text);
  if (a<0) or (a=TemplateIndex) then
    ModalResult:=mrOk
  else begin
    AText:=Format(lisCodeTemplATokenAlreadyExists, ['"', TokenEdit.Text, '"']);
    ACaption:=lisCodeTemplError;

//    Application.MessageBox(PChar(AText),PChar(ACaption),0);
    MessageDlg(ACaption,AText,mterror,[mbok],0);

  end;
end;

{ TCodeTemplateDialog }

procedure TCodeTemplateDialog.FormCreate(Sender: TObject);
var
  s: String;
  ColorScheme: String;
begin
  SynAutoComplete:=TSynEditAutoComplete.Create(Self);
  LastTemplate:=-1;

  // init captions
  Caption:=lisMenuEditCodeTemplates;
  AddButton.Caption:=lisCodeTemplAdd;
  EditButton.Caption:=lisCodeToolsDefsEdit;
  DeleteButton.Caption:=dlgEdDelete;
  CancelButton.Caption:=dlgCancel;
  TemplateGroupBox.Caption:=lisCTDTemplates;
  OkButton.Caption:=lisLazBuildOk;
  FilenameGroupBox.Caption:=lisToDoLFile;
  UseMakrosCheckBox.Caption:=lisEnableMakros;

  FilenameEdit.Text:=EditorOpts.CodeTemplateFileName;

  // init synedit
  ColorScheme:=EditorOpts.ReadColorScheme(ASynPasSyn.GetLanguageName);
  EditorOpts.AddSpecialHilightAttribsToHighlighter(ASynPasSyn);
  EditorOpts.ReadHighlighterSettings(ASynPasSyn,ColorScheme);
  if EditorOpts.UseSyntaxHighlight then
    TemplateSynEdit.Highlighter:=ASynPasSyn
  else
    TemplateSynEdit.Highlighter:=nil;
  EditorOpts.GetSynEditSettings(TemplateSynEdit);
  EditorOpts.KeyMap.AssignTo(TemplateSynEdit.KeyStrokes,
                             TSourceEditorWindowInterface);
  TemplateSynEdit.Gutter.Visible:=false;

  // init SynAutoComplete
  with SynAutoComplete do begin
    s:=EditorOpts.CodeTemplateFileName;
    if FileExists(s) then
      try
        AutoCompleteList.LoadFromFile(s);
      except
        DebugLn('NOTE: unable to read code template file ''',s,'''');
      end;
  end;
  
  // init listbox
  FillCodeTemplateListBox;
  with TemplateListBox do
    if Items.Count>0 then begin
      ItemIndex:=0;
      ShowCurCodeTemplate;
    end;
    
  BuildPopupMenu;
end;

procedure TCodeTemplateDialog.OkButtonClick(Sender: TObject);
var
  Res: TModalResult;
begin
  SaveCurCodeTemplate;

  EditorOpts.CodeTemplateFileName:=FilenameEdit.Text;
  //EditorOpts.CodeTemplateIndentToTokenStart:=
  //  (CodeTemplateIndentTypeRadioGroup.ItemIndex=0);

  EditorOpts.Save;

  if BuildBorlandDCIFile(SynAutoComplete) then begin
    Res:=mrOk;
    repeat
      try
        SynAutoComplete.AutoCompleteList.SaveToFile(
          EditorOpts.CodeTemplateFileName);
      except
        res:=MessageDlg(' Unable to write code templates to file '''
          +EditorOpts.CodeTemplateFileName+'''! ',mtError
          ,[mbAbort, mbIgnore, mbRetry],0);
        if res=mrAbort then exit;
      end;
    until Res<>mrRetry;
  end;

  ModalResult:=mrOk;
end;

procedure TCodeTemplateDialog.OnCopyMenuItem(Sender: TObject);
begin
  TemplateSynEdit.CopyToClipboard;
end;

procedure TCodeTemplateDialog.OnCutMenuItem(Sender: TObject);
begin
  TemplateSynEdit.CutToClipboard;
end;

procedure TCodeTemplateDialog.OnInsertMacroMenuItem(Sender: TObject);
begin

end;

procedure TCodeTemplateDialog.OnPasteMenuItem(Sender: TObject);
begin
  TemplateSynEdit.PasteFromClipboard;
end;

procedure TCodeTemplateDialog.AddButtonClick(Sender: TObject);
var
  Token: String;
  Comment: String;
  Index: LongInt;
begin
  SaveCurCodeTemplate;
  Token:='new';
  Comment:='(custom)';
  if AddCodeTemplate(SynAutoComplete,Token,Comment)=mrOk then begin
    SynAutoComplete.AddCompletion(Token, '', Comment);
    FillCodeTemplateListBox;
    Index:=SynAutoComplete.Completions.IndexOf(Token);
    if (Index>=0) and (Index<TemplateListBox.Items.Count) then begin
      TemplateListBox.ItemIndex:=Index;
    end;
    ShowCurCodeTemplate;
  end;
end;

procedure TCodeTemplateDialog.DeleteButtonClick(Sender: TObject);
var
  i: LongInt;
begin
  i:=TemplateListBox.ItemIndex;
  if i<0 then exit;
  if MessageDlg(dlgDelTemplate
      +'"'+SynAutoComplete.Completions[i]+' - '
      +SynAutoComplete.CompletionComments[i]+'"'
      +'?',mtConfirmation,[mbOk,mbCancel],0)=mrOK then begin
    SynAutoComplete.DeleteCompletion(i);
    FillCodeTemplateListBox;
    if (i>=0) and (i<TemplateListBox.Items.Count) then begin
      TemplateListBox.ItemIndex:=i;
    end;
    ShowCurCodeTemplate;
  end;
end;

procedure TCodeTemplateDialog.EditButtonClick(Sender: TObject);
var
  i: LongInt;
begin
  i:=TemplateListBox.ItemIndex;
  if i<0 then exit;
  if EditCodeTemplate(SynAutoComplete,i)=mrOk then begin
    TemplateListBox.Items[i]:=
       SynAutoComplete.Completions[i]
       +' - "'+SynAutoComplete.CompletionComments[i]+'"';
    ShowCurCodeTemplate;
  end;
end;

procedure TCodeTemplateDialog.FilenameButtonClick(Sender: TObject);
var OpenDialog:TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    with OpenDialog do begin
      Title:=dlgChsCodeTempl;
      Filter:='DCI file (*.dci)|*.dci|'+dlgAllFiles+'|*.*';
      if Execute then
        FilenameEdit.Text:=FileName;
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TCodeTemplateDialog.TemplateListBoxSelectionChange(Sender: TObject;
  User: boolean);
begin
  SaveCurCodeTemplate;
  ShowCurCodeTemplate;
end;

procedure TCodeTemplateDialog.BuildPopupMenu;
begin
  CodeTemplateCopyIDEMenuCommand.OnClick:=@OnCopyMenuItem;
  CodeTemplateCutIDEMenuCommand.OnClick:=@OnCutMenuItem;
  CodeTemplatePasteIDEMenuCommand.OnClick:=@OnPasteMenuItem;
  CodeTemplateInsertMacroIDEMenuCommand.OnClick:=@OnInsertMacroMenuItem;

  // assign the root TMenuItem to the registered menu root.
  MainPopupMenu:=TPopupMenu.Create(Self);
  // This will automatically create all registered items
  CodeTemplatesMenuRoot.MenuItem := MainPopupMenu.Items;
  //MainPopupMenu.Items.WriteDebugReport('TMessagesView.Create ');
  
  PopupMenu:=MainPopupMenu;
end;

procedure TCodeTemplateDialog.FillCodeTemplateListBox;
var a:integer;
begin
  with TemplateListBox do begin
    Items.BeginUpdate;
    Items.Clear;
    for a:=0 to SynAutoComplete.Completions.Count-1 do begin
      Items.Add(SynAutoComplete.Completions[a]
          +' - "'+SynAutoComplete.CompletionComments[a]+'"');
    end;
    Items.EndUpdate;
  end;
end;

procedure TCodeTemplateDialog.ShowCurCodeTemplate;
var
  EnableMakros: boolean;
  LineCount: integer;

  procedure AddLine(const s: string);
  begin
    if (LineCount=0) and (s=CodeTemplateMakroMagic) then
      EnableMakros:=true
    else
      TemplateSynEdit.Lines.Add(s);
    inc(LineCount);
  end;

var
  i, sp, ep: integer;
  s: string;
begin
  EnableMakros:=false;
  LineCount:=0;
  TemplateSynEdit.Lines.BeginUpdate;
  TemplateSynEdit.Lines.Clear;
  i:=TemplateListBox.ItemIndex;
  //debugln('TCodeTemplateDialog.ShowCurCodeTemplate A i=',dbgs(i));
  if i>=0 then begin
    LastTemplate:=-1;
    s:=SynAutoComplete.CompletionValues[i];
    //debugln('TCodeTemplateDialog.ShowCurCodeTemplate s="',s,'"');
    sp:=1;
    ep:=1;
    while ep<=length(s) do begin
      if s[ep] in [#10,#13] then begin
        AddLine(copy(s,sp,ep-sp));
        inc(ep);
        if (ep<=length(s)) and (s[ep] in [#10,#13]) and (s[ep-1]<>s[ep]) then
          inc(ep);
        sp:=ep;
      end else inc(ep);
    end;
    if (ep>sp) or ((s<>'') and (s[length(s)] in [#10,#13])) then
      AddLine(copy(s,sp,ep-sp));
  end;
  LastTemplate:=i;
  TemplateSynEdit.Lines.EndUpdate;
  TemplateSynEdit.Invalidate;
  UseMakrosCheckBox.Checked:=EnableMakros;
end;

procedure TCodeTemplateDialog.SaveCurCodeTemplate;
var
  NewValue: string;
  l: integer;
  i: LongInt;
begin
  if LastTemplate<0 then exit;
  i:=LastTemplate;
  //DebugLn('TCodeTemplateDialog.SaveCurCodeTemplate A i=',dbgs(i));
  NewValue:=TemplateSynEdit.Lines.Text;
  // remove last EOL
  if NewValue<>'' then begin
    l:=length(NewValue);
    if NewValue[l] in [#10,#13] then begin
      dec(l);
      if (l>0) and (NewValue[l] in [#10,#13])
      and (NewValue[l]<>NewValue[l+1]) then
        dec(l);
      SetLength(NewValue,l);
    end;
  end;
  if UseMakrosCheckBox.Checked then
    NewValue:=CodeTemplateMakroMagic+LineEnding+NewValue;
  SynAutoComplete.CompletionValues[i]:=NewValue;
end;

{ TLazCodeMacros }

function TLazCodeMacros.GetItems(Index: integer): TIDECodeMacro;
begin
  Result:=TIDECodeMacro(FItems[Index]);
end;

constructor TLazCodeMacros.Create;
begin
  FItems:=TFPList.Create;
end;

destructor TLazCodeMacros.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TLazCodeMacros.Clear;
var
  i: Integer;
begin
  for i:=0 to FItems.Count-1 do TObject(FItems[i]).Free;
  FItems.Clear;
end;

function TLazCodeMacros.Count: integer;
begin
  Result:=FItems.Count;
end;

function TLazCodeMacros.Add(Macro: TIDECodeMacro): integer;
begin
  if FindByName(Macro.Name)<>nil then
    RaiseGDBException('TLazCodeMacros.Add Name already exists');
  Result:=FItems.Add(Macro);
end;

function TLazCodeMacros.FindByName(const AName: string): TIDECodeMacro;
var
  i: LongInt;
begin
  i:=Count-1;
  while (i>=0) do begin
    Result:=Items[i];
    if (CompareText(Result.Name,AName)=0) then exit;
    dec(i);
  end;
  Result:=nil;
end;

function TLazCodeMacros.CreateUniqueName(const AName: string): string;
begin
  Result:=AName;
  if FindByName(Result)=nil then exit;
  Result:=CreateFirstIdentifier(Result);
  while FindByName(Result)<>nil do
    Result:=CreateNextIdentifier(Result);
end;

initialization
  {$I codetemplatesdlg.lrs}

end.
