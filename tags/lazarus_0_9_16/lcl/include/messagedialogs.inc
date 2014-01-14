{%MainUnit ../dialogs.pp}

{******************************************************************************
                                  MessageDialogs
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
  current design flaws:

  - ??? There has to be at least one :-)

  Delphi compatibility:

   - the interface is almost like in delphi 5
     
  TODO:
    - Help Context
    - Help-button
    - User ability to customize Button order

}
Function ModalEscapeValue(Buttons : TMsgDlgButtons) : TModalResult;
begin
  If mbCancel in Buttons then
    Result := mrCancel
  else
    If mbAbort in Buttons then
      Result := mrAbort
  else
    If mbNo in Buttons then
      Result := mrNo
  else
    If mbIgnore in Buttons then
      Result := mrIgnore
  else
    If mbNoToAll in Buttons then
      Result := mrNoToAll
  else
    If mbYes in Buttons then
      Result := mrYes
  else
    If mbOk in Buttons then
      Result := mrOk
  else
    If mbRetry in Buttons then
      Result := mrRetry
  else
    If mbAll in Buttons then
      Result := mrAll
  else
    If mbYesToAll in Buttons then
      Result := mrYesToAll;
end;

Function ModalDefaultButton(Buttons : TMsgDlgButtons) : TMsgDlgbtn;
begin
  If mbYes in Buttons then
    Result := mbYes
  else
    If mbOk in Buttons then
      Result := mbOk
  else
    If mbYesToAll in Buttons then
      Result := mbYesToAll
  else
    If mbAll in Buttons then
      Result := mbAll
  else
    If mbRetry in Buttons then
      Result := mbRetry
  else
    If mbCancel in Buttons then
      Result := mbCancel
  else
    If mbNo in Buttons then
      Result := mbNo
  else
    If mbNoToAll in Buttons then
      Result := mbNoToAll
  else
    If mbAbort in Buttons then
      Result := mbAbort
  else
    If mbIgnore in Buttons then
      Result := mbIgnore;
end;

const
  DialogIds : Array[mtWarning..mtCustom] of Longint = (idDialogWarning,
    idDialogError, idDialogInfo, idDialogConfirm, idDialogBase);

  ButtonIds : Array[TMsgDlgbtn] of Longint = (idButtonYes, idButtonNo,
    idButtonOK, idButtonCancel, idButtonAbort, idButtonRetry, idButtonIgnore,
    idButtonAll, idButtonNoToAll, idButtonYesToAll, idButtonHelp,
    idButtonClose);

  DialogResults : Array[idButtonOK..idButtonNoToAll] of TModalResult = (
    mrOk, mrCancel, mrOk{CLOSE!!}, mrYes, mrNo, -1{HELP!!}, mrAbort, mrRetry,
    mrIgnore, mrAll, mrYesToAll, mrNoToAll);

  ButtonResults : Array[mrNone..mrYesToAll] of Longint = (
    -1, idButtonOK, idButtonCancel, idButtonAbort, idButtonRetry,
    idButtonIgnore, idButtonYes,idButtonNo, idButtonAll, idButtonNoToAll,
    idButtonYesToAll);

Function GetPromptUserButtons(Buttons: TMsgDlgButtons; var CancelValue,
  DefaultIndex, ButtonCount : Longint) : PLongint;
var
  CurBtn      : TMsgDlgBtn; // variable to loop through TMsgDlgButtons
  DefaultButton : TMsgDlgBtn;
begin
  If (Buttons = []) or (Buttons = [mbHelp]) then
    Buttons := Buttons + [mbOk];
  CancelValue := ButtonResults[ModalEscapeValue (Buttons)];
  DefaultButton := ModalDefaultButton(Buttons);
  DefaultIndex := 0;
  ButtonCount := 0;
  Result := nil;
  For CurBtn := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do begin
    If CurBtn in Buttons then begin
      ReallocMem(Result, (ButtonCount + 1)*SizeOf(Longint));
      Result[ButtonCount] := ButtonIds[CurBtn];
      If DefaultButton = CurBtn then
        DefaultIndex := ButtonCount;
      Inc(ButtonCount)
    end;
  end;
end;

function MessageDlg(const aMsg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
var
  DefaultIndex,
  CancelValue,
  ButtonCount : Longint;
  Btns : PLongint;
begin
  Btns := GetPromptUserButtons(Buttons, CancelValue, DefaultIndex, ButtonCount);
  Result := DialogResults[PromptUser(aMsg, DialogIds[DlgType], Btns, ButtonCount,
    DefaultIndex, CancelValue)];
  ReallocMem(Btns, 0);
end;

function MessageDlg(const aCaption, aMsg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
var
  DefaultIndex,
  CancelValue,
  ButtonCount : Longint;
  Btns : PLongint;
begin
  Btns := GetPromptUserButtons(Buttons, CancelValue, DefaultIndex, ButtonCount);
  Result := DialogResults[PromptUser(aCaption, aMsg, DialogIds[DlgType], Btns,
    ButtonCount, DefaultIndex, CancelValue)];
  ReallocMem(Btns, 0);
end;

function MessageDlgPos(const aMsg: String; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; Helpctx : Longint; X,Y : Integer): Integer;
var
  DefaultIndex,
  CancelValue,
  ButtonCount : Longint;
  Btns : PLongint;
begin
  Btns := GetPromptUserButtons(Buttons, CancelValue, DefaultIndex, ButtonCount);
  Result := DialogResults[PromptUserAtXY(aMsg, DialogIds[DlgType], Btns,
    ButtonCount, DefaultIndex, CancelValue, X, Y)];
  ReallocMem(Btns, 0);
end;

function MessageDlgPosHelp(const aMsg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint; X, Y: Integer;
  const HelpFileName: string): Integer;
begin
  DebugLn ('MessageDlgPosHelp ****** NOT YET FULLY IMPLEMENTED ********');
//TODO: set helpcontext and helpfile
  result := MessageDlgPos(aMsg, DlgType, buttons, helpctx, X, Y);
end;

procedure ShowMessage(const aMsg: string);
begin
  NotifyUser(aMsg, idDialogBase);
end;

procedure ShowMessageFmt(const aMsg: string; Params: array of const);
begin
  NotifyUser(Format(aMsg, Params), idDialogBase);
end;

procedure ShowMessagePos(const aMsg: string; X, Y: Integer);
begin
  NotifyUserAtXY(aMsg, idDialogBase, X, Y);
end;

//----------------------------------------------------------------------------//
//-----------------------Prompt User For Information--------------------------//
Function InputBox(const ACaption, APrompt, ADefault : String) : String;
begin
  Result := ADefault;
  InputQuery(ACaption, APrompt, Result);
end;

Function PasswordBox(const ACaption, APrompt : String) : String;
begin
  Result := '';
  InputQuery(ACaption, APrompt, True, Result);
end;

function SelectDirectory(const Caption, InitialDirectory: string;
  var Directory: string): boolean;
begin
  Result:=SelectDirectory(Caption,InitialDirectory,Directory,false);
end;

function SelectDirectory(const Caption, InitialDirectory: string;
  var Directory: string; ShowHidden: boolean; HelpCtx: Longint): boolean;
var
  SelectDirectoryDialog: TSelectDirectoryDialog;
begin
  SelectDirectoryDialog:=TSelectDirectoryDialog.Create(nil);
  if ShowHidden then
    SelectDirectoryDialog.Options:=SelectDirectoryDialog.Options
                                   +[ofForceShowHidden];
  SelectDirectoryDialog.InitialDir:=InitialDirectory;
  SelectDirectoryDialog.Title:=Caption;
  SelectDirectoryDialog.HelpContext:=HelpCtx;
  Result:=SelectDirectoryDialog.Execute;
  if Result then
    Directory:=SelectDirectoryDialog.Filename
  else
    Directory:='';
end;

function SelectDirectory(var Directory: string;
  Options: TSelectDirOpts; HelpCtx: Longint): Boolean;
var
  SelectDirectoryDialog: TSelectDirectoryDialog;
begin
  SelectDirectoryDialog:=TSelectDirectoryDialog.Create(nil);
  // TODO: sdAllowCreate,
  // TODO: sdPrompt
  SelectDirectoryDialog.HelpContext:=HelpCtx;
  Result:=SelectDirectoryDialog.Execute;
  if Result then begin
    Directory:=SelectDirectoryDialog.Filename;
    if (sdPerformCreate in Options) and (not DirPathExists(Directory)) then
      ForceDirectories(Directory);
  end else
    Directory:='';
end;

Function InputQuery(const ACaption, APrompt : String; MaskInput : Boolean;
  var Value : String) : Boolean;
begin
  Result := LCLIntf.RequestInput(ACaption, APrompt, MaskInput, Value);
end;

Function InputQuery(const ACaption, APrompt : String; var Value : String) : Boolean;
begin
  Result := InputQuery(ACaption, APrompt, False, Value);
end;

// included by dialogs.pp