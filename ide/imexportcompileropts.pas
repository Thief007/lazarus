{ /***************************************************************************
                      imexportcompilerOpts.pas
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

  Author: Mattias Gaertner
}
unit ImExportCompilerOpts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, FileUtil, {$IFNDEF VER1_0}XMLCfg{$ELSE}Laz_XMLCfg{$ENDIF},
  LazarusIDEStrConsts, InputHistory, CompilerOptions, CompilerOptionsDlg;

type
  TImExportCompOptsResult = (
    iecorCancel,
    iecorImport,
    iecorExport
    );

  TImExportCompOptsDlg = class(TForm)
    SaveToRecentButton: TBUTTON;
    OpenRecentButton: TBUTTON;
    RecentListbox: TLISTBOX;
    SaveButton: TBUTTON;
    OpenButton: TBUTTON;
    CancelButton: TBUTTON;
    OpenRecentGroupbox: TGROUPBOX;
    procedure ImExportCompOptsDlgCLOSE(Sender: TObject;
                                       var CloseAction: TCloseAction);
    procedure ImExportCompOptsDlgCREATE(Sender: TObject);
    procedure OpenButtonCLICK(Sender: TObject);
    procedure OpenRecentButtonCLICK(Sender: TObject);
    procedure RecentListboxCLICK(Sender: TObject);
    procedure RecentListboxDBLCLICK(Sender: TObject);
    procedure SaveButtonCLICK(Sender: TObject);
    procedure SaveToRecentButtonCLICK(Sender: TObject);
  private
    FFilename: string;
    FImExportResult: TImExportCompOptsResult;
    procedure LoadRecentList;
    procedure SaveRecentList;
    procedure UpdateRecentButtons;
    procedure SetFilename(const AValue: string);
    procedure SetImExportResult(const AValue: TImExportCompOptsResult);
    procedure DoOpenFile(const AFilename: string);
    procedure DoSaveFile(const AFilename: string);
  public
    property ImExportResult: TImExportCompOptsResult read FImExportResult
                                                     write SetImExportResult;
    property Filename: string read FFilename write SetFilename;
  end;

function ShowImExportCompilerOptionsDialog(
  CompOpts: TBaseCompilerOptions; var Filename: string): TImExportCompOptsResult;

function DoImportComilerOptions(CompOptsDialog: TfrmCompilerOptions;
  CompilerOpts: TBaseCompilerOptions; const Filename: string): TModalResult;
function DoExportComilerOptions(CompOptsDialog: TfrmCompilerOptions;
  CompilerOpts: TBaseCompilerOptions; const Filename: string): TModalResult;
function GetXMLPathForCompilerOptions(XMLConfig: TXMLConfig): string;
function ReadIntFromXMLConfig(const Filename, Path: string;
  DefaultValue, ValueForReadError: integer): integer;

implementation


function ShowImExportCompilerOptionsDialog(
  CompOpts: TBaseCompilerOptions; var Filename: string): TImExportCompOptsResult;
var
  ImExportCompOptsDlg: TImExportCompOptsDlg;
begin
  Result:=iecorCancel;
  ImExportCompOptsDlg:=TImExportCompOptsDlg.Create(nil);
  if ImExportCompOptsDlg.ShowModal=mrOk then begin
    Result:=ImExportCompOptsDlg.ImExportResult;
    Filename:=ImExportCompOptsDlg.Filename;
  end;
  ImExportCompOptsDlg.Free;
end;

function DoImportComilerOptions(CompOptsDialog: TfrmCompilerOptions;
  CompilerOpts: TBaseCompilerOptions; const Filename: string): TModalResult;
var
  XMLConfig: TXMLConfig;
  FreeCompilerOpts: Boolean;
  Path: String;
begin
  Result:=mrCancel;
  try
    XMLConfig:=TXMLConfig.Create(Filename);
  except
    on E: Exception do begin
      Result:=MessageDlg('Error loading xml',
        'Error loading xml file "'+Filename+'":'#13
        +E.Message,mtError,[mbCancel],0);
    end;
  end;
  FreeCompilerOpts:=false;
  try
    if (CompOptsDialog<>nil) then begin
      CompilerOpts:=TBaseCompilerOptions.Create(nil);
      FreeCompilerOpts:=true;
    end;
    Path:=GetXMLPathForCompilerOptions(XMLConfig);
    CompilerOpts.LoadFromXMLConfig(XMLConfig,Path);
    if CompOptsDialog<>nil then
      CompOptsDialog.GetCompilerOptions(CompilerOpts);
  finally
    if FreeCompilerOpts then
      CompilerOpts.Free;
    XMLConfig.Free;
  end;
end;

function DoExportComilerOptions(CompOptsDialog: TfrmCompilerOptions;
  CompilerOpts: TBaseCompilerOptions; const Filename: string): TModalResult;
var
  XMLConfig: TXMLConfig;
  FreeCompilerOpts: Boolean;
  Path: String;
begin
  FreeCompilerOpts:=false;
  if (CompOptsDialog<>nil) then begin
    CompilerOpts:=TBaseCompilerOptions.Create(nil);
    FreeCompilerOpts:=true;
    CompOptsDialog.PutCompilerOptions(CompilerOpts);
  end;
  try
    Result:=mrCancel;
    try
      XMLConfig:=TXMLConfig.Create(Filename);
      try
        Path:=GetXMLPathForCompilerOptions(XMLConfig);
        CompilerOpts.SaveToXMLConfig(XMLConfig,Path);
        XMLConfig.Flush;
      finally
        XMLConfig.Free;
      end;
    except
      on E: Exception do begin
        Result:=MessageDlg('Error accessing xml',
          'Error accessing xml file "'+Filename+'":'#13
          +E.Message,mtError,[mbCancel],0);
      end;
    end;
  finally
    if FreeCompilerOpts then
      CompilerOpts.Free;
  end;
end;

function ReadIntFromXMLConfig(const Filename, Path: string;
  DefaultValue, ValueForReadError: integer): integer;
var
  XMLConfig: TXMLConfig;
begin
  Result:=ValueForReadError;
  if FileExists(Filename) then
    try
      XMLConfig:=TXMLConfig.Create(Filename);
      Result:=XMLConfig.GetValue(Path,DefaultValue);
    except
      Result:=ValueForReadError;
    end;
end;

function GetXMLPathForCompilerOptions(XMLConfig: TXMLConfig): string;
var
  FileVersion: Integer;
begin
  if XMLConfig.GetValue('SearchPaths/CompilerPath/Value','')<>'' then
    Result:=''
  else if XMLConfig.GetValue(
    'CompilerOptions/SearchPaths/CompilerPath/Value','')<>''
  then
    Result:='CompilerOptions/'
  else if XMLConfig.GetValue(
    'Package/CompilerOptions/SearchPaths/CompilerPath/Value','')<>''
  then
    Result:='Package/CompilerOptions/'
  else begin
    // default: depending on file type
    Result:='CompilerOptions/';
    if CompareFileExt(XMLConfig.Filename,'.lpk',false)=0 then begin
      FileVersion:=ReadIntFromXMLConfig(XMLConfig.Filename,'Package/Version',0,2);
      if FileVersion>=2 then
        Result:='Package/CompilerOptions/';
    end;
  end;
end;

{ TImExportCompOptsDlg }

procedure TImExportCompOptsDlg.ImExportCompOptsDlgCREATE(Sender: TObject);
begin
  ImExportResult:=iecorCancel;
  
  Caption:='Open or Load Compiler Options';
  OpenRecentGroupbox.Caption:='Recent files';
  SaveToRecentButton.Caption:='Save to recent';
  OpenRecentButton.Caption:='Open recent';
  SaveButton.Caption:='Save to file';
  OpenButton.Caption:='Load from file';
  CancelButton.Caption:='Cancel';
  
  LoadRecentList;
end;

procedure TImExportCompOptsDlg.OpenButtonCLICK(Sender: TObject);
var
  AFilename: String;
  OpenDialog: TOpenDialog;
begin
  AFilename:='';
  OpenDialog:=TOpenDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Title:=lisOpenFile;
    OpenDialog.Options:=OpenDialog.Options+[ofPathMustExist];
    if OpenDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(OpenDialog.Filename);
      DoOpenFile(AFilename);
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TImExportCompOptsDlg.OpenRecentButtonCLICK(Sender: TObject);
var
  i: Integer;
begin
  i:=RecentListbox.ItemIndex;
  if i<0 then exit;
  DoOpenFile(RecentListbox.Items[i]);
end;

procedure TImExportCompOptsDlg.RecentListboxCLICK(Sender: TObject);
begin
  UpdateRecentButtons;
end;

procedure TImExportCompOptsDlg.RecentListboxDBLCLICK(Sender: TObject);
begin
  OpenRecentButtonCLICK(Sender);
end;

procedure TImExportCompOptsDlg.SaveButtonCLICK(Sender: TObject);
var
  AFilename: String;
  SaveDialog: TSaveDialog;
begin
  AFilename:='';
  SaveDialog:=TSaveDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(SaveDialog);
    SaveDialog.Title:=lisOpenFile;
    if SaveDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(SaveDialog.Filename);
      DoSaveFile(AFilename);
    end;
    InputHistories.StoreFileDialogSettings(SaveDialog);
  finally
    SaveDialog.Free;
  end;
end;

procedure TImExportCompOptsDlg.SaveToRecentButtonCLICK(Sender: TObject);
var
  i: Integer;
begin
  i:=RecentListbox.ItemIndex;
  if i<0 then exit;
  DoSaveFile(RecentListbox.Items[i]);
end;

procedure TImExportCompOptsDlg.ImExportCompOptsDlgCLOSE(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  SaveRecentList;
end;

procedure TImExportCompOptsDlg.LoadRecentList;
begin
  RecentListbox.Items.Assign(
    InputHistories.HistoryLists.GetList(hlCompilerOptsImExport,true));
  if RecentListbox.Items.Count>0 then
    RecentListbox.ItemIndex:=0;
  UpdateRecentButtons;
end;

procedure TImExportCompOptsDlg.SaveRecentList;
begin
  InputHistories.HistoryLists.GetList(hlCompilerOptsImExport,true).Assign(
    RecentListbox.Items);
  InputHistories.Save;
end;

procedure TImExportCompOptsDlg.UpdateRecentButtons;
var
  RecentSelected: boolean;
begin
  RecentSelected:=RecentListbox.ItemIndex>=0;
  OpenRecentButton.Enabled:=RecentSelected;
  SaveToRecentButton.Enabled:=RecentSelected;
end;

procedure TImExportCompOptsDlg.SetFilename(const AValue: string);
begin
  if FFilename=AValue then exit;
  FFilename:=AValue;
  InputHistories.HistoryLists.GetList(hlCompilerOptsImExport,true).
    AppendEntry(FFilename);
  LoadRecentList;
end;

procedure TImExportCompOptsDlg.SetImExportResult(
  const AValue: TImExportCompOptsResult);
begin
  if FImExportResult=AValue then exit;
  FImExportResult:=AValue;
end;

procedure TImExportCompOptsDlg.DoOpenFile(const AFilename: string);
begin
  if DirPathExists(AFilename) then exit;
  Filename:=AFilename;
  ImExportResult:=iecorImport;
  ModalResult:=mrOk;
end;

procedure TImExportCompOptsDlg.DoSaveFile(const AFilename: string);
var
  MsgResult: TModalResult;
begin
  if DirPathExists(AFilename) then exit;
  Filename:=AFilename;
  if FileExists(AFilename) then begin
    MsgResult:=MessageDlg('Export file exists',
      'Export file "'+AFilename+'" exists.'#13
      +'Open file and replace only compiler options?'#13
      +'(Other settings will be kept.)',
      mtConfirmation,[mbYes,mbCancel],0);
    if MsgResult<>mrYes then exit;
  end;
  ImExportResult:=iecorExport;
  ModalResult:=mrOk;
end;

initialization
  {$I imexportcompileropts.lrs}

end.

