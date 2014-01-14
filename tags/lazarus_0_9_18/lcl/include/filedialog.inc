{%MainUnit ../dialogs.pp}

{******************************************************************************
                                  TFileDialog
 ******************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

{------------------------------------------------------------------------------}
{  TFileDialog Create                                                          }
{------------------------------------------------------------------------------}
constructor TFileDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  fCompStyle := csFileDialog;
  FFiles := TStringList.Create;
  FHistoryList:=TStringList.Create;
end;

{------------------------------------------------------------------------------}
{  TFileDialog Destroy                                                         }
{------------------------------------------------------------------------------}
destructor TFileDialog.Destroy;
begin
  FHistoryList.Free;
  FFiles.Free;
  inherited Destroy;
end;

{------------------------------------------------------------------------------}
{  TFileDialog Execute                                                         }
{------------------------------------------------------------------------------}
function TFileDialog.Execute : boolean;
begin
  FOldWorkingDir:=GetCurrentDir;
  if FInitialDir<>'' then SetCurrentDir(FInitialDir);
  try
    Result:=inherited Execute;
  finally
    SetCurrentDir(FOldWorkingDir);
  end;
end;

{------------------------------------------------------------------------------
  TFileDialog DoExecute
------------------------------------------------------------------------------}
procedure TFileDialog.SetHistoryList(const AValue: TStrings);
begin
  FHistoryList.Assign(AValue);
end;

{------------------------------------------------------------------------------
  procedure TFileDialog.SetDefaultExt(const AValue: string);
------------------------------------------------------------------------------}
procedure TFileDialog.SetDefaultExt(const AValue: string);
begin
  FDefaultExt:=AValue;
  if (FDefaultExt<>'') and (FDefaultExt[1]<>'.') then
    FDefaultExt:='.'+FDefaultExt;
end;

{------------------------------------------------------------------------------}
{  TFileDialog DoExecute                                                         }
{------------------------------------------------------------------------------}
function TFileDialog.DoExecute : boolean;
begin
  Result:= inherited DoExecute;
end;

{------------------------------------------------------------------------------}
{  TFileDialog SetFilter                                                       }
{------------------------------------------------------------------------------}
procedure TFileDialog.SetFilter(const value : string);
begin
  FFilter := Value;  // make sure this is defined first before the CNSendMessage
end;

{------------------------------------------------------------------------------}
{  TFileDialog SetFileName                                                     }
{------------------------------------------------------------------------------}
procedure TFileDialog.SetFileName(const value : string);
begin
  if FFilename=Value then exit;
  FFileName := Value;  // make sure this is defined first before the CNSendMessage
end;

{******************************************************************************
                                  TOpenDialog
 ******************************************************************************}

procedure TOpenDialog.DereferenceLinks;
var i: integer;
begin
  if Filename<>'' then
    Filename:=ExpandFilename(Filename);
  if Files<>nil then begin
    for i:=0 to Files.Count-1 do begin
      if Files[i]<>'' then
        Files[i]:=ExpandFilename(Files[i]);
    end;
  end;
end;

function TOpenDialog.CheckFile(var AFilename: string): boolean;
var
  Dir: string;
begin
  Result:=true;
  if (DefaultExt<>'') and (ExtractFileExt(AFilename)='')
  and (not FileExists(AFilename)) then begin
    AFilename:=AFilename+DefaultExt;
  end;
  //ofOverwritePrompt -> is done in the interface
  if (ofPathMustExist in Options)
  and (not DirPathExists(ExtractFileDir(AFilename))) then begin
    Result:=false;
    MessageDlg(rsfdPathMustExist,
               Format(rsfdPathNoExist,[ExtractFileDir(AFilename)]),
               mtError,[mbCancel],0);
    exit;
  end;
  if (ofFileMustExist in Options)
  and (not CheckFileMustExist(AFileName)) then begin
    // CheckFileMustExists shows message dialog
    Result:=false;
    exit;
  end;
  if ofNoReadOnlyReturn in Options then begin
    if FileExists(AFilename) then
      Result := FileIsWritable(AFilename)
    else begin { File does not exist - check directory }
      Dir := ExtractFileDir(AFilename);
      if Dir = '' then
        Dir := '.';
      Result := FileIsWritable(Dir);
    end;
    if not Result then begin
        MessageDlg(rsfdFileReadOnlyTitle,
                   Format(rsfdFileReadOnly,[AFileName]),
                   mtError,[mbCancel],0);
        exit;
    end;
  end;
end;

function TOpenDialog.CheckFileMustExist(const AFileName: string): boolean;
begin
  if not FileExists(AFilename) then begin
    Result:=false;
    MessageDlg(rsfdFileMustExist,
               Format(rsfdFileNotExist,[AFileName]),mtError,
               [mbCancel],0);
  end else
    Result:=true;
end;

function TOpenDialog.CheckAllFiles: boolean;
var
  AFilename: String;
  i: Integer;
begin
  Result:=true;

  AFilename:=Filename;
  if (AFilename<>'')
  or (not (ofAllowMultiSelect in Options)) then begin
    Result:=CheckFile(AFilename);
    Filename:=AFilename;
    if not Result then exit;
  end;

  if ofAllowMultiSelect in Options then begin
    for i:=0 to Files.Count-1 do begin
      AFilename:=Files[i];
      Result:=CheckFile(AFilename);
      Files[i]:=AFilename;
      if not Result then exit;
    end;
  end;
end;

{------------------------------------------------------------------------------
  Method: TOpenDialog.DoExecute
  Params:  none
  Returns: true if valid was selected

  Starts dialogs and lets user choose a filename.
 ------------------------------------------------------------------------------}
function TOpenDialog.DoExecute: boolean;
begin
  Result:=inherited DoExecute;
  if (not (ofNoDereferenceLinks in Options)) then begin
    DereferenceLinks;
  end;
  if (not (ofNoChangeDir in Options)) then begin
    if (ExtractFilePath(Filename)<>'') then
      InitialDir:=ExtractFilePath(Filename)
    else if (Files.Count>0) and (ExtractFilePath(Files[0])<>'') then
      InitialDir:=ExtractFilePath(Files[0]);
  end;
  if not Result then exit;
  Result:=CheckAllFiles;
end;

{------------------------------------------------------------------------------
  Method: TOpenDialog.Create
  Params:  AOwner: the owner of the class
  Returns: Nothing

  Constructor for the class.
 ------------------------------------------------------------------------------}
constructor TOpenDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  fCompStyle:=csOpenFileDialog;
  FTitle:= rsfdOpenFile;
  FOptions := DefaultOpenDialogOptions;
end;

procedure TOpenDialog.DoFolderChange;
begin
  if Assigned(OnFolderChange) then OnFolderChange(Self);
end;

procedure TOpenDialog.DoSelectionChange;
var
  CurFilename: String;
begin
  CurFilename:=Filename;
  if FLastSelectionChangeFilename=CurFilename then exit;
  FLastSelectionChangeFilename:=CurFilename;
  if Assigned(OnSelectionChange) then OnSelectionChange(Self);
end;

{******************************************************************************
                                  TSaveDialog
 ******************************************************************************}
{------------------------------------------------------------------------------
  Method: TSaveDialog.Create
  Params:  AOwner: the owner of the class
  Returns: Nothing

  Constructor for the class.
 ------------------------------------------------------------------------------}
constructor TSaveDialog.Create (AOwner : TComponent);
begin
  inherited Create(AOwner);
  fCompStyle:=csSaveFileDialog;
  FTitle:= rsfdFileSaveAs;
end;

{******************************************************************************
                             TSelectDirectoryDialog
 ******************************************************************************}

{ TSelectDirectoryDialog }

constructor TSelectDirectoryDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCompStyle:=csSelectDirectoryDialog;
  FTitle:=rsfdSelectDirectory;
end;

function TSelectDirectoryDialog.CheckFileMustExist(const AFilename: string): boolean;
begin
  if not DirPathExists(AFilename) then begin
    Result:=false;
    MessageDlg(rsfdDirectoryMustExist,
               Format(rsfdDirectoryNotExist,[AFileName]),mtError,
               [mbCancel],0);
  end else
    Result:=true;
end;
