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
    A dialog for cleaning directories.
}
unit CleanDirDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, FileCtrl, Laz_XMLCfg, SynRegExpr,
  LazarusIDEStrConsts, LazConf, IDEProcs, TransferMacros, ExtCtrls;

type
  TCleanDirectoryDialog = class(TForm)
    KeepTextFilesCheckbox: TCHECKBOX;
    SubDirsCheckbox: TCHECKBOX;
    SimpleSyntaxKeepCheckbox: TCHECKBOX;
    KeepCombobox: TCOMBOBOX;
    KeepGroupbox: TGROUPBOX;
    SimpleSyntaxRemoveCheckbox: TCHECKBOX;
    RemoveCombobox: TCOMBOBOX;
    DirCombobox: TCOMBOBOX;
    DirGroupbox: TGROUPBOX;
    RemoveGroupbox: TGROUPBOX;
    OkButton: TBUTTON;
    CancelButton: TBUTTON;
    procedure CleanDirectoryDialogCreate(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    FMacros: TTransferMacroList;
    procedure SetMacros(const AValue: TTransferMacroList);
  public
    procedure LoadSettings;
    procedure SaveSettings;
    function GetConfigFilename: string;
    function SearchFilesToDelete(var List: TStrings): boolean;
    function DeleteFiles(List: TStrings): boolean;
    procedure AddDirectory(const Directory: string);
    property Macros: TTransferMacroList read FMacros write SetMacros;
  end;
  
  TShowDeletingFilesDialog = class(TForm)
    FilesListBox: TListBox;
    OkButton: TBUTTON;
    CancelButton: TBUTTON;
  public
    constructor Create(TheOwner: TComponent); override;
  end;

function ShowCleanDirectoryDialog(const DefaultDirectory: string;
  Macros: TTransferMacroList): TModalResult;


implementation


const
  CleanDirXMLFilename = 'cleandirectorydialog.xml';
  CleanDirXMLVersion = 1;

function ShowCleanDirectoryDialog(const DefaultDirectory: string;
  Macros: TTransferMacroList): TModalResult;
var
  CleanDirectoryDialog: TCleanDirectoryDialog;
begin
  CleanDirectoryDialog:=TCleanDirectoryDialog.Create(Application);
  CleanDirectoryDialog.Macros:=Macros;
  CleanDirectoryDialog.LoadSettings;
  CleanDirectoryDialog.AddDirectory(DefaultDirectory);
  Result:=CleanDirectoryDialog.ShowModal;
  CleanDirectoryDialog.Free;
end;

{ TCleanDirectoryDialog }

procedure TCleanDirectoryDialog.OkButtonClick(Sender: TObject);
var
  List: TStrings;
begin
  SaveSettings;
  if not SearchFilesToDelete(List) then exit;
  try
    if not DeleteFiles(List) then exit;
  finally
    List.Free;
  end;
  ModalResult:=mrOk;
end;

procedure TCleanDirectoryDialog.SetMacros(const AValue: TTransferMacroList);
begin
  if FMacros=AValue then exit;
  FMacros:=AValue;
end;

procedure TCleanDirectoryDialog.CleanDirectoryDialogCreate(Sender: TObject);
begin
  Caption:=lisClDirCleanDirectory;
  DirGroupbox.Caption:=lisCodeToolsDefsInsertBehindDirectory;
  SubDirsCheckbox.Caption:=lisClDirCleanSubDirectories;
  RemoveGroupbox.Caption:=lisClDirRemoveFilesMatchingFilter;
  SimpleSyntaxRemoveCheckbox.Caption:=lisClDirSimpleSyntaxEGInsteadOf;
  KeepGroupbox.Caption:=lisClDirKeepFilesMatchingFilter;
  SimpleSyntaxKeepCheckbox.Caption:=lisClDirSimpleSyntaxEGInsteadOf;
  KeepTextFilesCheckbox.Caption:=lisClDirKeepAllTextFiles;
  OkButton.Caption:=lisLazBuildOk;
  CancelButton.Caption:=dlgCancel;
end;

procedure TCleanDirectoryDialog.LoadSettings;
var
  XMLConfig: TXMLConfig;

  procedure LoadComboList(AComboBox: TComboBox; const Path: string);
  var
    List: TStringList;
  begin
    List:=TStringList.Create;
    LoadRecentList(XMLConfig,List,Path+'Directories');
    AComboBox.Items.Assign(List);
    List.Free;
  end;
  
  procedure AddStandardComboItem(AComboBox: TComboBox; const Item: string);
  begin
    if AComboBox.Items.IndexOf(Item)>=0 then exit;
    AComboBox.Items.Add(Item);
    AComboBox.ItemIndex:=0;
  end;

var
  Filename: String;
  Path: String;
begin
  try
    Filename:=GetConfigFilename;
    XMLConfig:=TXMLConfig.Create(Filename);
  except
    writeln('ERROR: unable to open clean directory options "',Filename,'"');
    exit;
  end;
  try
    try
      Path:='CleanDirectoryOptions/';
      //FileVersion:=XMLConfig.GetValue(Path+'Version/Value',0);
      
      SubDirsCheckbox.Checked:=XMLConfig.GetValue(
                                             Path+'SubDirectories/Value',false);
      LoadComboList(DirCombobox,Path+'Directories');
      LoadComboList(RemoveCombobox,Path+'RemoveFilters');
      SimpleSyntaxRemoveCheckbox.Checked:=XMLConfig.GetValue(
                                         Path+'RemoveFilter/SimpleSyntax',true);
      LoadComboList(KeepCombobox,Path+'KeepFilters');
      SimpleSyntaxKeepCheckbox.Checked:=XMLConfig.GetValue(
                                           Path+'KeepFilter/SimpleSyntax',true);
      KeepTextFilesCheckbox.Checked:=XMLConfig.GetValue(
                                               Path+'KeepTextFiles/Value',true);

      // set defaults
      AddStandardComboItem(DirCombobox,'$(ProjPath)');
      AddStandardComboItem(RemoveCombobox,'*.(bak|ppu|ppw|ppl|o|a|so|dll)');
      AddStandardComboItem(RemoveCombobox,'*.bak|*~');
      AddStandardComboItem(KeepCombobox,
                           '*.(pas|pp|lpr|lfm|lrs|lpi|lpk|inc|sh|xml)');

    finally
      XMLConfig.Free;
    end;
  except
    on E: Exception do begin
      writeln('ERROR: unable to read clean directory options from "',
        Filename,'": ',E.Message);
    end;
  end;
end;

procedure TCleanDirectoryDialog.SaveSettings;
var
  XMLConfig: TXMLConfig;
  Filename: String;
  Path: String;
begin
  try
    Filename:=GetConfigFilename;
    XMLConfig:=TXMLConfig.CreateClean(Filename);
  except
    writeln('ERROR: unable to open clean directory options "',Filename,'"');
    exit;
  end;
  try
    try
      Path:='CleanDirectoryOptions/';
      XMLConfig.SetValue(Path+'Version/Value',CleanDirXMLVersion);

      XMLConfig.SetDeleteValue(Path+'SubDirectories/Value',
                               SubDirsCheckbox.Checked,false);
      SaveRecentList(XMLConfig,DirCombobox.Items,Path+'Directories');
      SaveRecentList(XMLConfig,RemoveCombobox.Items,Path+'RemoveFilters');
      XMLConfig.SetDeleteValue(Path+'RemoveFilter/SimpleSyntax',
                               SimpleSyntaxRemoveCheckbox.Checked,true);
      SaveRecentList(XMLConfig,KeepCombobox.Items,Path+'KeepFilters');
      XMLConfig.SetDeleteValue(Path+'KeepFilter/SimpleSyntax',
                               SimpleSyntaxKeepCheckbox.Checked,true);
      XMLConfig.SetDeleteValue(Path+'KeepTextFiles/Value',
                               KeepTextFilesCheckbox.Checked,true);

      XMLConfig.Flush;
    finally
      XMLConfig.Free;
    end;
  except
    on E: Exception do begin
      writeln('ERROR: unable to write clean directory options from "',
        Filename,'": ',E.Message);
    end;
  end;
end;

function TCleanDirectoryDialog.GetConfigFilename: string;
begin
  Result:=AppendPathDelim(GetPrimaryConfigPath)+CleanDirXMLFilename;
end;

function TCleanDirectoryDialog.SearchFilesToDelete(var List: TStrings): boolean;
var
  RemoveFilterRegExpr: TRegExpr;
  KeepFilterRegExpr: TRegExpr;

  function FileMatches(const Filename: string): boolean;
  var
    ShortFilename: String;
  begin
    Result:=false;
    ShortFilename:=ExtractFilename(Filename);
    if (RemoveFilterRegExpr=nil)
    or not RemoveFilterRegExpr.Exec(ExtractFilename(ShortFilename)) then exit;
    if (KeepFilterRegExpr<>nil)
    and KeepFilterRegExpr.Exec(ExtractFilename(ShortFilename)) then exit;
    if KeepTextFilesCheckbox.Checked and FileIsText(Filename) then exit;
    Result:=true;
  end;

  function SearchInDirectory(const MainDirectory: string;
    Lvl: integer): boolean;
  var
    FileInfo: TSearchRec;
    FullFilename: String;
  begin
    Result:=false;
    if (not FileExists(MainDirectory)) or (Lvl>20) then exit;
    if SysUtils.FindFirst(MainDirectory+FindMask,
                          faAnyFile,FileInfo)=0
    then begin
      repeat
        // check if special file
        if (FileInfo.Name='.') or (FileInfo.Name='..') then continue;
        FullFilename:=MainDirectory+FileInfo.Name;
        if (FileInfo.Attr and faDirectory)>0 then begin
          if SubDirsCheckbox.Checked then begin
            // search recursively
            if not SearchInDirectory(AppendPathDelim(FullFilename),Lvl+1) then
              break;
          end;
        end else begin
          if FileMatches(FullFilename) then
            List.Add(FullFilename);
        end;
      until SysUtils.FindNext(FileInfo)<>0;
    end;
    SysUtils.FindClose(FileInfo);
    Result:=true;
  end;
  
  function SetupFilter(var Filter: TRegExpr; SimpleSyntax: boolean;
    const FilterAsText: string): boolean;
  var
    Expr: String;
  begin
    Result:=false;
    if FilterAsText='' then begin
      Filter:=nil;
      Result:=true;
      exit;
    end;
    Filter:=TRegExpr.Create;
    if SimpleSyntax then
      Expr:=SimpleSyntaxToRegExpr(FilterAsText)
    else
      Expr:=FilterAsText;
    try
      Filter.Expression:=Expr;
      Result:=true;
    except
      on E: Exception do begin
        MessageDlg('Invalid Mask',
          'The mask "'+FilterAsText+'" is not a valid expression.',
          mtError,[mbCancel],0);
      end;
    end;
  end;

var
  Directory: String;
begin
  Result:=false;
  RemoveFilterRegExpr:=nil;
  KeepFilterRegExpr:=nil;
  List:=nil;

  try
    // get directory
    Directory:=DirCombobox.Text;
    if (Macros<>nil) and (not Macros.SubstituteStr(Directory)) then exit;
    Directory:=AppendPathDelim(Directory);

    // setup filters
    SetupFilter(RemoveFilterRegExpr,SimpleSyntaxRemoveCheckbox.Checked,
      RemoveCombobox.Text);
    SetupFilter(KeepFilterRegExpr,SimpleSyntaxKeepCheckbox.Checked,
      KeepCombobox.Text);

    // search files
    List:=TStringList.Create;
    if not SearchInDirectory(Directory,0) then exit;

    Result:=true;
  finally
    RemoveFilterRegExpr.Free;
    KeepFilterRegExpr.Free;
    if not Result then begin
      List.Free;
      List:=nil;
    end;
  end;
end;

function TCleanDirectoryDialog.DeleteFiles(List: TStrings): boolean;
var
  i: Integer;
  Filename: string;
  MsgResult: TModalResult;
  ShowDeletingFilesDialog: TShowDeletingFilesDialog;
begin
  Result:=false;
  if List.Count=0 then begin
    Result:=true;
    exit;
  end;
  
  // ask user for confirmation
  ShowDeletingFilesDialog:=TShowDeletingFilesDialog.Create(Self);
  try
    ShowDeletingFilesDialog.FilesListBox.Items.Assign(List);
    if ShowDeletingFilesDialog.ShowModal<>mrOk then exit;
  finally
    ShowDeletingFilesDialog.Free;
  end;

  // delete them all
  for i:=0 to List.Count-1 do begin
    Filename:=List[i];
    writeln('Deleting file ',Filename);
    if FileExists(Filename) then begin
      repeat
        if DeleteFile(Filename) then begin
          break;
        end else begin
          MsgResult:=MessageDlg('Error deleting file',
            'Unable to delete file "'+Filename+'".',
            mtError,[mbAbort,mbIgnore,mbRetry],0);
          if (MsgResult=mrIgnore) then break;
          if MsgResult=mrAbort then exit;
        end;
      until false;
    end;
  end;
  Result:=true;
end;

procedure TCleanDirectoryDialog.AddDirectory(const Directory: string);
begin
  AddToRecentList(Directory,DirCombobox.Items,20);
end;

{ TShowDeletingFilesDialog }

constructor TShowDeletingFilesDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Caption:='Delete all these files?';
  Width:=400;
  Height:=350;
  Position:=poScreenCenter;
  
  FilesListBox:=TListBox.Create(Self);
  with FilesListBox do begin
    Name:='FilesListBox';
    Parent:=Self;
    Height:=Self.ClientHeight-40;
    Align:=alTop;
    Anchors:=[akLeft,akTop,akBottom,akRight];
  end;
  
  OkButton:=TButton.Create(Self);
  with OkButton do begin
    Name:='OkButton';
    Parent:=Self;
    Left:=20;
    Top:=Self.ClientHeight-35;
    Width:=100;
    Height:=25;
    Caption:='Delete';
    ModalResult:=mrOk;
  end;
  
  CancelButton:=TButton.Create(Self);
  with CancelButton do begin
    Name:='CancelButton';
    Parent:=Self;
    Left:=150;
    Top:=Self.ClientHeight-35;
    Width:=100;
    Height:=25;
    Caption:='Cancel';
    ModalResult:=mrCancel;
  end;
end;

initialization
  {$I cleandirdlg.lrs}

end.

