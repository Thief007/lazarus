{ $Id$}
{
 *****************************************************************************
 *                             Win32WSDialogs.pp                             * 
 *                             -----------------                             * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit Win32WSDialogs;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Dialogs, Controls, Graphics, SysUtils, Classes,
////////////////////////////////////////////////////
  WSDialogs, WSLCLClasses, Windows, WinExt, LCLProc, LCLType, Win32Int, InterfaceBase;

type

  { TWin32WSCommonDialog }

  TWin32WSCommonDialog = class(TWSCommonDialog)
  private
  protected
  public
    class function  CreateHandle(const ACommonDialog: TCommonDialog): integer; override;
    class procedure DestroyHandle(const ACommonDialog: TCommonDialog); override;
  end;

  { TWin32WSFileDialog }

  TWin32WSFileDialog = class(TWSFileDialog)
  private
  protected
  public
  end;

  { TWin32WSOpenDialog }

  TWin32WSOpenDialog = class(TWSOpenDialog)
  private
  protected
  public
    class function  CreateHandle(const ACommonDialog: TCommonDialog): integer; override;
  end;

  { TWin32WSSaveDialog }

  TWin32WSSaveDialog = class(TWSSaveDialog)
  private
  protected
  public
    class function  CreateHandle(const ACommonDialog: TCommonDialog): integer; override;
  end;

  { TWin32WSSelectDirectoryDialog }

  TWin32WSSelectDirectoryDialog = class(TWSSelectDirectoryDialog)
  private
  protected
  public
    class function  CreateHandle(const ACommonDialog: TCommonDialog): integer; override;
  end;

  { TWin32WSColorDialog }

  TWin32WSColorDialog = class(TWSColorDialog)
  private
  protected
  public
    class function  CreateHandle(const ACommonDialog: TCommonDialog): integer; override;
  end;

  { TWin32WSColorButton }

  TWin32WSColorButton = class(TWSColorButton)
  private
  protected
  public
  end;

  { TWin32WSFontDialog }

  TWin32WSFontDialog = class(TWSFontDialog)
  private
  protected
  public
    class function  CreateHandle(const ACommonDialog: TCommonDialog): integer; override;
  end;


implementation

{------------------------------------------------------------------------------
  Method: GetOwnerHandle
  Params:  ADialog - dialog to get 'guiding parent' window handle for
  Returns: A window handle

  Returns window handle to be used as 'owner handle', ie. so that the user must
  finish the dialog before continuing
 ------------------------------------------------------------------------------}
function GetOwnerHandle(ADialog : TCommonDialog): HWND;
begin
  with ADialog do
  begin
    if Owner Is TWinControl then
      Result := TWinControl(Owner).Handle
{
    // TODO: fix Application.Handle to be the same as FAppHandle
    else if Owner Is TApplication then
      Result := TApplication(Owner).Handle
}
    else
      Result := TWin32WidgetSet(WidgetSet).AppHandle;
  end;
end;

procedure SetDialogResult(const ACommonDialog: TCommonDialog; Ret: WINBOOL);
begin
  if Ret then
    ACommonDialog.UserChoice := mrOK
  else
    ACommonDialog.UserChoice := mrCancel;
end;

{ TWin32WSColorDialog }

class function TWin32WSColorDialog.CreateHandle(const ACommonDialog: TCommonDialog): integer;
const
  { 16 basic RGB colors; names listed in comments for debugging }
  CustomColors: array[1..16] of dword = (
  0, //Black
  $C0C0C0, //Silver
  $808080, //Gray
  $FFFFFF, //White
  $000080, //Maroon
  $0000FF, //Red
  $800080, //Purple
  $FF00FF, //Fuchsia
  $008000, //Green
  $00FF00, //Lime
  $008080, //Olive
  $00FFFF, //Yellow
  $800000, //Navy
  $FF0000, //Blue
  $808000, //Teal
  $FFFF00 //Aqua
  );
var
  CC: TChooseColor;
  UserResult: WINBOOL;
begin
  ZeroMemory(@CC, sizeof(TChooseColor));
  with CC Do
  begin
    LStructSize := sizeof(TChooseColor);
    HWndOwner := GetOwnerHandle(ACommonDialog);
    RGBResult := ColorToRGB(TColorDialog(ACommonDialog).Color);
    LPCustColors := @CustomColors;
    Flags := CC_FULLOPEN or CC_RGBINIT;
  end;
  UserResult := ChooseColor(@CC);
  SetDialogResult(ACommonDialog, UserResult);
  if UserResult then
    TColorDialog(ACommonDialog).Color := CC.RGBResult;

  Result := 0;
end;

{Common code for OpenDialog and SaveDialog}

{The API of the multiselect open file dialog is a bit problematic.
 Before calling the OpenFile function you must create a buffer (lpStrFile) to
 hold the selected files.

 With a multiselect dialog there is no way to create a buffer with correct size:
 * either it is too small (for example 1 KB), if a lot a files are selected
 * or it wastes a lot of memory (for example 1 MB), and even than you have no
   guarantee, that is big enough.

 The OpenFile API call returns false, if an error has occurred or the user has
 pressed cancel. If there was an error CommDlgExtendedError returns
 FNERR_BUFFERTOOSMALL. But enlarging the buffer at that time is not usefull
 anymore, unless you show the dialog again with a bigger buffer (Sorry, the
 buffer was too small, please select the files again). This is not acceptable.

 It is possible to hook the filedialog, so you get messages, when the selection
 changes. A naive aproach would be to see, if the buffer would be big enough for
 the selected files and create or enlarge the buffer (as described in KB131462).
 Unfortunately, this only works with win9x and the unicode versions of later
 windows versions.

 Therefore in the hook function, if the size of the initial buffer (lpStrFile)
 is not large enough, the selected files are copied into a string. A pointer to
 this string is kept in the lCustData field of the the OpenFileName struct.
 When dialog is closed with a FNERR_BUFFERTOOSMALL error, this string is used to
 get the selected files. If this error did not occur, the normal way of
 retrieving the files is used.
}

type
  TWinFileDialogFunc = function(OpenFile: LPOPENFILENAME): WINBOOL; stdcall;

function OpenFileDialogCallBack(hwnd : Handle; uMsg : UINT; wParam: WPARAM;
  lParam: LPARAM) : UINT; stdcall;
var
  OpenFileNotify: LPOFNOTIFY;
  OpenFileName: POPENFILENAME;
  NeededSize: DWORD;
  FileNames: pstring;
begin
  if uMsg = WM_NOTIFY then begin
    OpenFileNotify := LPOFNOTIFY(lParam);
    if OpenFileNotify^.hdr.code=CDN_SELCHANGE then begin
      OpenFileName := OpenFileNotify^.lpOFN;
      // NeededSize is the size that the lpStrFile buffer must have.
      // the lpstrFile buffer contains the directory and a list of files
      // for example 'c:\winnt'#0'file1.txt'#0'file2.txt'#0#0.
      // GetFolderPath returns upper limit for the path, GetSpec for the files.
      // This is not exact because the GetSpec returns the size for
      // '"file1.txt" "file2.txt"', so that size will be two bytes per filename
      // more than needed in the lpStrFile buffer.
      NeededSize := CommDlg_OpenSave_GetFolderPath(GetParent(hwnd), nil, 0) +
                      CommDlg_OpenSave_GetSpec(GetParent(hwnd), nil, 0);
      // test if we need to use our own storage
      if OpenFileName^.nMaxFile<NeededSize then begin
        if OpenFileName^.lCustData=0 then
          OpenFileName^.lCustData := DWord(new(PString));
        FileNames := PString(OpenFileName^.lCustData);
        if length(FileNames^)<NeededSize then
          SetLength(FileNames^, NeededSize*2);
        CommDlg_OpenSave_GetSpec(GetParent(hwnd),
                                   PChar(FileNames^), Length(FileNames^));
      end;
    end;
  end;
  Result:= 0;
end;

procedure ShowFileDialog(AOpenDialog: TOpenDialog; AWinFunc: TWinFileDialogFunc);
var
  OpenFile: OPENFILENAME;
  UserResult: WINBOOL;

  function GetFlagsFromOptions(Options: TOpenOptions): DWord;
  begin
    Result := 0;
    if ofAllowMultiSelect in Options then
      Result := Result or OFN_ALLOWMULTISELECT or OFN_ENABLEHOOK;
    if ofCreatePrompt in Options then Result := Result or OFN_CREATEPROMPT;
    if not (ofOldStyleDialog in Options) then Result := Result or OFN_EXPLORER;
    if ofExtensionDifferent in Options then Result := Result or OFN_EXTENSIONDIFFERENT;
    if ofFileMustExist in Options then Result := Result or OFN_FILEMUSTEXIST;
    if ofHideReadOnly in Options then Result := Result or OFN_HIDEREADONLY;
    if ofNoChangeDir in Options then Result := Result or OFN_NOCHANGEDIR;
    if ofNoDereferenceLinks in Options then Result := Result or OFN_NODEREFERENCELINKS;
    if ofNoLongNames in Options then  Result := Result or OFN_NOLONGNAMES;
    if ofNoNetworkButton in Options then Result := Result or OFN_NONETWORKBUTTON;
    if ofNoReadOnlyReturn in  Options then Result := Result or OFN_NOREADONLYRETURN;
    if ofNoTestFileCreate in Options then Result := Result or OFN_NOTESTFILECREATE;
    if ofNoValidate in Options then Result := Result or OFN_NOVALIDATE;
    if ofOverwritePrompt in Options then Result := Result or OFN_OVERWRITEPROMPT;
    if ofPathMustExist in Options then Result := Result or OFN_PATHMUSTEXIST;
    if ofReadOnly in Options then Result := Result or OFN_READONLY;
    if ofShareAware in Options then Result := Result or OFN_SHAREAWARE;
    if ofShowHelp in Options then Result := Result or OFN_SHOWHELP;
  end;

  procedure ReplacePipe(var AFilter:string);
  var i:integer;
  begin
    for i := 1 to length(AFilter) do
      if AFilter[i] = '|' then AFilter[i]:=#0;
    AFilter:=AFilter + #0#0;
  end;

  procedure SetFilesProperty(AFiles:TStrings);
  var 
    I: integer;
    pName: PChar;
  begin
    pName := OpenFile.lpStrFile;
    I:=Length(pName);
    if I < OpenFile.nFileOffset then begin
      Inc(pName,Succ(I));
      I:=Length(pName);
      while I > 0 do
      begin
        AFiles.Add(ExpandFileName(StrPas(pName)));
        Inc(pName,Succ(I));
        I:=Length(pName);
      end;
    end
    else
      AFiles.Add(StrPas(pName));
  end;

  procedure SetFilesPropertyCustomFiles(AFiles:TStrings);
  var
    i, Start: integer;
    FileNames: String;
  begin
    FileNames := PString(OpenFile.lCustData)^;
    if (FileNames[1] = '"') then begin
      Start := 1; // first quote is on pos 1
      while FileNames[Start] <> #0 do begin
        i := Start + 1;
        while FileNames[i] <> '"' do
          inc(i);
        AFiles.Add(ExpandFileName(Copy(FileNames,Start+1,I - Start - 1)));
        start := i+1;
        while (FileNames[Start] <> #0) and (FileNames[start] <> '"') do
          inc(Start);
      end;
    end;
  end;

  procedure SetFilesPropertyForOldStyle(AFiles:TStrings);
  var
    SelectedStr: string;
    I,Start: integer;
  begin
    SelectedStr:=StrPas(OpenFile.lpStrFile);
    I:=Pos(' ',SelectedStr);
    if I = 0 then
      AFiles.Add(SelectedStr)
    else begin
      Delete(SelectedStr,1,I);
      SelectedStr:=SelectedStr+' ';
      Start:=1;
      for I:= 1 to Length(SelectedStr) do
        if SelectedStr[I] =  ' ' then 
        begin
          AFiles.Add(ExpandFileName(Copy(SelectedStr,Start,I - Start)));
          Start:=Succ(I);
        end;
    end;
  end;

var
  FFilter: string;
  FileNameBuffer: array[0..1000] of char;
  BufferTooSmall: boolean;
begin
  FillChar(FileNameBuffer[0], sizeof(FileNameBuffer), 0);
  StrLCopy(@FileNameBuffer[0],PChar(AOpenDialog.Filename),sizeof(FileNameBuffer)-1);
  if AOpenDialog.Filter <> '' then 
  begin
    FFilter := AOpenDialog.Filter;
    ReplacePipe(FFilter);
  end
  else
    FFilter:='All File Types(*.*)'+#0+'*.*'+#0#0; // Default -> avoid empty combobox
  ZeroMemory(@OpenFile, sizeof(OpenFileName));
  with OpenFile Do
  begin
    lStructSize := sizeof(OpenFileName);
    hWndOwner := GetOwnerHandle(AOpenDialog);
    hInstance := System.hInstance;
    lpStrFilter := StrAlloc(Length(FFilter)+1);
    StrPCopy(lpStrFilter, FFilter);
    nFilterIndex := AOpenDialog.FilterIndex;
    lpStrFile := FileNameBuffer;
    lpStrTitle := PChar(AOpenDialog.Title);
    lpStrInitialDir := PChar(AOpenDialog.InitialDir);
    nMaxFile := sizeof(FileNameBuffer);
    lpfnHook := @OpenFileDialogCallBack;
    Flags := GetFlagsFromOptions(AOpenDialog.Options);
  end;
  UserResult := AWinFunc(@OpenFile);
  BufferTooSmall := not UserResult and (CommDlgExtendedError=FNERR_BUFFERTOOSMALL);
  if BufferTooSmall then
    UserResult := true;
  SetDialogResult(AOpenDialog, UserResult);
  with AOpenDialog do
  begin
    Files.Clear;
    if UserResult then
    begin
      AOpenDialog.FilterIndex := OpenFile.nFilterIndex;
      if (ofOldStyleDialog in Options) then
        SetFilesPropertyForOldStyle(Files)
      else if BufferTooSmall then
        SetFilesPropertyCustomFiles(Files)
      else
        SetFilesProperty(Files);
      FileName := Files[0];
    end else
      FileName := '';

    if OpenFile.lCustData<>0 then
      Dispose(PString(OpenFile.lCustData));
    StrDispose(OpenFile.lpStrFilter);
  end;
end;

{ TWin32WSSaveDialog }

class function TWin32WSSaveDialog.CreateHandle(const ACommonDialog: TCommonDialog): integer;
begin
  ShowFileDialog(TOpenDialog(ACommonDialog), @GetSaveFileName);
  Result := 0;
end;

{ TWin32WSOpenDialog }

class function TWin32WSOpenDialog.CreateHandle(const ACommonDialog: TCommonDialog): integer;
begin
  ShowFileDialog(TOpenDialog(ACommonDialog), @GetOpenFileName);
  Result := 0;
end;

{ TWin32WSFontDialog }

class function TWin32WSFontDialog.CreateHandle(const ACommonDialog: TCommonDialog): integer;

  function GetFlagsFromOptions(Options : TFontDialogOptions): dword;
  begin
    Result := 0;
    if fdAnsiOnly in Options then Result := Result or CF_ANSIONLY;
    if fdTrueTypeOnly in Options then Result := Result or CF_TTONLY;
    if fdEffects in Options then Result := Result or CF_EFFECTS;
    if fdFixedPitchOnly in Options then Result := Result or CF_FIXEDPITCHONLY;
    if fdForceFontExist in Options then Result := Result or CF_FORCEFONTEXIST;
    if fdNoFaceSel in Options then Result := Result or CF_NOFACESEL;
    if fdNoOEMFonts in Options then Result := Result or CF_NOOEMFONTS;
    if fdNoSimulations in Options then Result := Result or CF_NOSIMULATIONS;
    if fdNoSizeSel in Options then Result := Result or CF_NOSIZESEL;
    if fdNoStyleSel in Options then Result := Result or CF_NOSTYLESEL;
    if fdNoVectorFonts in Options then Result := Result or CF_NOVECTORFONTS;
    if fdShowHelp in Options then Result := Result or CF_SHOWHELP;
    if fdWysiwyg in Options then Result := Result or CF_WYSIWYG;
    if fdLimitSize in Options then Result := Result or CF_LIMITSIZE;
    if fdScalableOnly in Options then Result := Result or CF_SCALABLEONLY;
    if fdApplyButton in Options then Result := Result or CF_APPLY;
  end;

var
  CF: TChooseFont;
  LF: LCLType.LOGFONT;
  UserResult: WINBOOL;
begin
  with TFontDialog(ACommonDialog) do
  begin
    ZeroMemory(@CF, sizeof(TChooseFont));
    ZeroMemory(@LF, sizeof(LogFont));
    with LF do
    begin
      LFHeight := Font.Height;
      LFFaceName := TFontDataName(Font.Name);
      if (fsBold in Font.Style) then LFWeight:= FW_BOLD;
      LFItalic := byte(fsItalic in Font.Style);
      LFStrikeOut := byte(fsStrikeOut in Font.Style);
      LFUnderline := byte(fsUnderline in Font.Style);
      LFCharSet := Font.CharSet;
    end;
    with CF do
    begin
      LStructSize := sizeof(TChooseFont);
      HWndOwner := GetOwnerHandle(ACommonDialog);
      LPLogFont := @LF;
      Flags := GetFlagsFromOptions(Options);
      Flags := Flags or CF_INITTOLOGFONTSTRUCT or CF_BOTH;
      RGBColors := Font.Color;
    end;
  end;

  UserResult := ChooseFont(@CF);
  SetDialogResult(ACommonDialog, UserResult);
  if UserResult then
  begin
    with TFontDialog(ACommonDialog).Font do
    begin
      Assign(LF);
      Color := CF.RGBColors;
    end;
  end;

  Result := 0;
end;

{ TWin32WSCommonDialog }

class function TWin32WSCommonDialog.CreateHandle(const ACommonDialog: TCommonDialog): integer;
begin
  DebugLn('TWin32WSCommonDialog.CreateHandle: unhandled dialog!');
  Result := 0;
end;

class procedure TWin32WSCommonDialog.DestroyHandle(const ACommonDialog: TCommonDialog);
begin
  DestroyWindow(ACommonDialog.Handle);
end;

{ TWin32WSSelectDirectoryDialog }

{------------------------------------------------------------------------------
 Function: BrowseForFolderCallback
 Params: Window_hwnd - The window that receives a message for the window
         Msg         - The message received
         LParam      - Long-integer parameter
         lpData      - Data parameter, contains initial path.
  Returns: non-zero long-integer

  Handles the messages sent to the toolbar button by Windows
 ------------------------------------------------------------------------------}
Function BrowseForFolderCallback(hwnd : Handle; uMsg : UINT;
  lParam, lpData : LPARAM) : Integer; stdcall;
begin
  case uMsg of
    BFFM_INITIALIZED:
        // Setting root dir
        SendMessage(hwnd, BFFM_SETSELECTION, ULONG(True), lpData);
    //BFFM_SELCHANGED
    //  : begin
    //    if Assigned(FOnSelectionChange) then .....
    //    end;
  end;
  Result := 0;
end;

class function TWin32WSSelectDirectoryDialog.CreateHandle(const ACommonDialog: TCommonDialog): integer;
var
  bi : TBrowseInfo;
  Buffer : PChar;
  iidl : PItemIDList;
  InitialDir: string;
begin
  Buffer := CoTaskMemAlloc(MAX_PATH);
  InitialDir := TSelectDirectoryDialog(ACommonDialog).FileName;
  if length(InitialDir)=0 then
    InitialDir := TSelectDirectoryDialog(ACommonDialog).InitialDir;
  if length(InitialDir)>0 then begin
    // remove the \ at the end.
    if Copy(InitialDir,length(InitialDir),1)=PathDelim then
      InitialDir := copy(InitialDir,1, length(InitialDir)-1);
    // if it is a rootdirectory, then the InitialDir must have a \ at the end.
    if Copy(InitialDir,length(InitialDir),1)=DriveDelim then
      InitialDir := InitialDir + PathDelim;
  end;
  with bi do
  begin
    hwndOwner := GetOwnerHandle(ACommonDialog);
    pidlRoot := nil;
    pszDisplayName := Buffer;
    lpszTitle := PChar(ACommonDialog.Title);
    ulFlags := BIF_RETURNONLYFSDIRS;
    lpfn := @BrowseForFolderCallback;
    // this value will be passed to callback proc as lpData
    lParam := LclType.LParam(PChar(InitialDir));
  end;

  iidl := SHBrowseForFolder(@bi);

  if Assigned(iidl) then
  begin
    SHGetPathFromIDList(iidl, Buffer);
    CoTaskMemFree(iidl);
    TSelectDirectoryDialog(ACommonDialog).FileName := Buffer;
  end;

  SetDialogResult(ACommonDialog, assigned(iidl));

  CoTaskMemFree(Buffer);

  Result := 0;
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCommonDialog, TWin32WSCommonDialog);
//  RegisterWSComponent(TFileDialog, TWin32WSFileDialog);
  RegisterWSComponent(TOpenDialog, TWin32WSOpenDialog);
  RegisterWSComponent(TSaveDialog, TWin32WSSaveDialog);
  RegisterWSComponent(TSelectDirectoryDialog, TWin32WSSelectDirectoryDialog);
  RegisterWSComponent(TColorDialog, TWin32WSColorDialog);
//  RegisterWSComponent(TColorButton, TWin32WSColorButton);
  RegisterWSComponent(TFontDialog, TWin32WSFontDialog);
////////////////////////////////////////////////////
end.
