unit CheckCompilerOpts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, LazarusIDEStrConsts, FileUtil, IDEProcs, EnvironmentOpts,
  CompilerOptions, ExtToolEditDlg, TransferMacros;

type
  TCompilerOptionsTest = (
    cotNone,
    cotCheckCompilerExe,
    cotCompileBogusFiles
    );

  TCheckCompilerOptsDlg = class(TForm)
    CloseButton: TBUTTON;
    TestMemo: TMEMO;
    TestGroupbox: TGROUPBOX;
    OutputListbox: TLISTBOX;
    OutputGroupBox: TGROUPBOX;
    procedure ApplicationOnIdle(Sender: TObject);
    procedure CloseButtonCLICK(Sender: TObject);
  private
    FMacroList: TTransferMacroList;
    FOptions: TCompilerOptions;
    FTest: TCompilerOptionsTest;
    FLastLineIsProgress: boolean;
    FDirectories: TStringList;
    procedure SetMacroList(const AValue: TTransferMacroList);
    procedure SetOptions(const AValue: TCompilerOptions);
    procedure SetMsgDirectory(Index: integer; const CurDir: string);
  public
    function DoTest: TModalResult;
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function RunTool(ExtTool: TExternalToolOptions): TModalResult;
    procedure Add(const Msg, CurDir: String; ProgressLine: boolean);
    procedure AddMsg(const Msg, CurDir: String);
    procedure AddProgress(const Msg, CurDir: String);
  public
    property Options: TCompilerOptions read FOptions write SetOptions;
    property Test: TCompilerOptionsTest read FTest;
    property MacroList: TTransferMacroList read FMacroList write SetMacroList;
  end;

var
  CheckCompilerOptsDlg: TCheckCompilerOptsDlg;

implementation

{ TCheckCompilerOptsDlg }

procedure TCheckCompilerOptsDlg.ApplicationOnIdle(Sender: TObject);
begin
  Application.RemoveOnIdleHandler(@ApplicationOnIdle);
  DoTest;
end;

procedure TCheckCompilerOptsDlg.CloseButtonCLICK(Sender: TObject);
begin
  ModalResult:=mrOk;
end;

procedure TCheckCompilerOptsDlg.SetOptions(const AValue: TCompilerOptions);
begin
  if FOptions=AValue then exit;
  FOptions:=AValue;
end;

procedure TCheckCompilerOptsDlg.SetMsgDirectory(Index: integer;
  const CurDir: string);
begin
  if FDirectories=nil then FDirectories:=TStringList.Create;
  while FDirectories.Count<=Index do FDirectories.Add('');
  FDirectories[Index]:=CurDir;
end;

procedure TCheckCompilerOptsDlg.SetMacroList(const AValue: TTransferMacroList);
begin
  if FMacroList=AValue then exit;
  FMacroList:=AValue;
end;

function TCheckCompilerOptsDlg.DoTest: TModalResult;
var
  TestDir: String;
  BogusFilename: String;
  CompilerFilename: String;
  CompileTool: TExternalToolOptions;
  CmdLineParams: String;
begin
  Result:=mrCancel;
  if Test<>cotNone then exit;
  CompileTool:=nil;
  TestMemo.Lines.Clear;
  try
    // check compiler filename
    FTest:=cotCheckCompilerExe;
    TestGroupbox.Caption:='Test: Checking compiler ...';
    CompilerFilename:=Options.ParsedOpts.GetParsedValue(pcosCompilerPath);
    try
      CheckIfFileIsExecutable(CompilerFilename);
    except
      on e: Exception do begin
        Result:=MessageDlg('Invalid compiler',
          'The compiler "'+CompilerFilename+'" is not an executable file.',
          mtError,[mbCancel,mbAbort],0);
        exit;
      end;
    end;
    
    // compile bogus file
    FTest:=cotCompileBogusFiles;
    TestGroupbox.Caption:='Test: Compiling an empty file ...';
    // get Test directory
    TestDir:=AppendPathDelim(EnvironmentOptions.TestBuildDirectory);
    if not DirPathExists(TestDir) then begin
      MessageDlg('Invalid Test Directory',
        'Please check the Test directory under'#13
        +'Environment -> Environment Options -> Files -> Directory for building test projects',
        mtError,[mbCancel],0);
      Result:=mrCancel;
      exit;
    end;
    // create bogus file
    BogusFilename:=CreateNonExistingFilename(TestDir+'testcompileroptions.pas');
    if not CreateEmptyFile(BogusFilename) then begin
      MessageDlg('Unable to create Test File',
        'Unable to create Test pascal file "'+BogusFilename+'".',
        mtError,[mbCancel],0);
      Result:=mrCancel;
      exit;
    end;
    try
      // create compiler command line options
      CmdLineParams:=Options.MakeOptionsString(BogusFilename,nil,
                                [ccloAddVerboseAll,ccloDoNotAppendOutFileOption])
                     +' '+BogusFilename;

      CompileTool:=TExternalToolOptions.Create;
      CompileTool.Title:='Test: Compiling empty file';
      CompileTool.ScanOutputForFPCMessages:=true;
      CompileTool.ScanOutputForMakeMessages:=true;
      CompileTool.WorkingDirectory:=TestDir;
      CompileTool.Filename:=CompilerFilename;
      CompileTool.CmdLineParams:=CmdLineParams;
      
      Result:=RunTool(CompileTool);
      FreeThenNil(CompileTool);
    finally
      DeleteFile(BogusFilename);
    end;

  finally
    CompileTool.Free;
    FTest:=cotNone;
    TestGroupbox.Caption:='Test';
  end;
end;

constructor TCheckCompilerOptsDlg.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Application.AddOnIdleHandler(@ApplicationOnIdle,true);
end;

destructor TCheckCompilerOptsDlg.Destroy;
begin
  Application.RemoveOnIdleHandler(@ApplicationOnIdle);
  FDirectories.Free;
  inherited Destroy;
end;

function TCheckCompilerOptsDlg.RunTool(ExtTool: TExternalToolOptions
  ): TModalResult;
begin
  TestMemo.Lines.Text:=ExtTool.Filename+' '+ExtTool.CmdLineParams;
  Result:=EnvironmentOptions.ExternalTools.Run(ExtTool,MacroList);
end;

procedure TCheckCompilerOptsDlg.Add(const Msg, CurDir: String;
  ProgressLine: boolean);
var
  i: Integer;
Begin
  if FLastLineIsProgress then begin
    OutputListbox.Items[OutputListbox.Items.Count-1]:=Msg;
  end else begin
    OutputListbox.Items.Add(Msg);
  end;
  FLastLineIsProgress:=ProgressLine;
  i:=OutputListbox.Items.Count-1;
  SetMsgDirectory(i,CurDir);
  OutputListbox.TopIndex:=OutputListbox.Items.Count-1;
end;

procedure TCheckCompilerOptsDlg.AddMsg(const Msg, CurDir: String);
begin
  Add(Msg,CurDir,false);
end;

procedure TCheckCompilerOptsDlg.AddProgress(const Msg, CurDir: String);
begin
  Add(Msg,CurDir,false);
end;

initialization
  {$I checkcompileropts.lrs}

end.

