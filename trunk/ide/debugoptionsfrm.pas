unit DebugOptionsFrm;

{$mode objfpc} {$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Buttons, ComCtrls, Menus, Spin, CheckLst,
  LazarusIDEStrConsts, FileProcs, InputHistory, EnvironmentOpts,
  BaseDebugManager, Debugger, DBGUtils;

type
  TDebuggerOptionsForm = class (TForm )
    clbExceptions: TCHECKLISTBOX;
    chkMessagesInterface: TCHECKBOX;
    chkClearLogOnRun: TCHECKBOX;
    chkLimitLineCount: TCHECKBOX;
    chkMessagesBreakpoint: TCHECKBOX;
    chkMessagesProcess: TCHECKBOX;
    chkMessagesThread: TCHECKBOX;
    chkMessagesModule: TCHECKBOX;
    chkMessagesOutput: TCHECKBOX;
    chkMessagesWindow: TCHECKBOX;
    cmdOpenDebuggerPath: TBUTTON;
    cmdOpenAdditionalPath: TBUTTON;
    cmdCancel: TBUTTON;
    cmdOK: TBUTTON;
    cmdExceptionRemove: TBUTTON;
    cmdExceptionAdd: TBUTTON;
    cmdSignalRemove: TBUTTON;
    cmdSignalAdd: TBUTTON;
    chkBreakOnException: TCHECKBOX;
    cmbDebuggerType: TCOMBOBOX;
    cmbDebuggerPath: TCOMBOBOX;
    N1: TMENUITEM;
    seLimitLinecount: TSPINEDIT;
    txtAdditionalPath: TEDIT;
    gbDebuggerType: TGROUPBOX;
    gbAdditionalSearchPath: TGROUPBOX;
    gbDebuggerSpecific: TGROUPBOX;
    gbGeneral: TGROUPBOX;
    gbMessages: TGROUPBOX;
    bgIgnoreExceptions: TGROUPBOX;
    gbSignals: TGROUPBOX;
    lvSignals: TLISTVIEW;
    mnuResumeUnhandled: TMENUITEM;
    mnuHandledByProgram: TMENUITEM;
    mnuiHandledByDebugger: TMENUITEM;
    mnuResumeHandled: TMENUITEM;
    nbDebugOptions: TNOTEBOOK;
    pgSignals: TPAGE;
    pgExceptions: TPAGE;
    pgEventLog: TPAGE;
    pgGeneral: TPAGE;
    popSignal: TPOPUPMENU;
    procedure DebuggerOptionsFormCREATE(Sender: TObject);
    procedure DebuggerOptionsFormDESTROY(Sender: TObject);
    procedure clbExceptionsCLICK (Sender: TObject );
    procedure cmbDebuggerTypeCHANGE(Sender: TObject);
    procedure cmdExceptionAddCLICK (Sender: TObject );
    procedure cmdExceptionRemoveCLICK (Sender: TObject );
    procedure cmdOKCLICK (Sender: TObject );
    procedure cmdOpenDebuggerPathCLICK(Sender: TObject);
  private
    FExceptionDeleteList: TStringList;
    FOldDebuggerPathAndParams: string;
    FDebuggerSpecificComponents: TList;
    FCurDebuggerClass: TDebuggerClass; // currently shown debugger class
    procedure AddExceptionLine(const AException: TIDEException; AName: String);
    procedure AddSignalLine(const ASignal: TIDESignal);
    procedure FetchDebuggerClass;
    procedure FetchDebuggerSpecificOptions;
    function  GetDebuggerClass: TDebuggerClass;
    procedure SetDebuggerClass(const AClass: TDebuggerClass);
  public
  end;

var
  DebuggerOptionsForm: TDebuggerOptionsForm;

implementation

const
  HANDLEDBY_CAPTION: array [Boolean] of String = ('Program', 'Debugger');
  RESUME_CAPTION: array[Boolean] of String = ('Unhandled', 'Handled');

{ TDebuggerOptionsForm }

procedure TDebuggerOptionsForm.AddExceptionLine(const AException: TIDEException;
  AName: String);
var
  idx: Integer;
begin
  if (AName = '') and (AException <> nil)
  then AName := AException.Name;
  if AName = '' then Exit;

  idx := clbExceptions.Items.AddObject(AName, AException);
  clbExceptions.Checked[idx] := (AException = nil) or AException.Enabled;
end;

procedure TDebuggerOptionsForm.AddSignalLine(const ASignal: TIDESignal);
var
  Item: TListItem;
begin
  Item := lvSignals.Items.Add;
  Item.Caption := ASignal.Name;
  Item.SubItems.Add(IntToStr(ASignal.ID));
  Item.SubItems.Add(HANDLEDBY_CAPTION[ASignal.HandledByDebugger]);
  Item.SubItems.Add(RESUME_CAPTION[ASignal.ResumeHandled]);
  Item.Data := ASignal;
end;

procedure TDebuggerOptionsForm.FetchDebuggerClass;
var
  n: Integer;
  AClass: TDebuggerClass;
  S: String;
begin
  with cmbDebuggerType.Items do
  begin
    BeginUpdate;
    Clear;
    AddObject('(none)', TObject(-1)); // temporary manual coded
    for n := 0 to DebugBoss.DebuggerCount - 1 do
    begin
      AClass := DebugBoss.Debuggers[n];
      AddObject(AClass.Caption, TObject(n));
      if  (FCurDebuggerClass = nil)
      and (CompareText(AClass.ClassName, EnvironmentOptions.DebuggerClass) = 0)
      then SetDebuggerClass(AClass);
    end;
    EndUpdate;
  end;
  
  if FCurDebuggerClass = nil
  then SetComboBoxText(cmbDebuggerType, '(none)')
  else SetComboBoxText(cmbDebuggerType, FCurDebuggerClass.Caption);

  with cmbDebuggerPath.Items do begin
    BeginUpdate;
    Assign(EnvironmentOptions.DebuggerFileHistory);
    if  (Count = 0)
    and (FCurDebuggerClass <> nil)
    then begin
      S := FCurDebuggerClass.ExePaths;
      while S <> '' do
      begin
        Add(GetPart([], [';'], S));
        if S <> '' then System.Delete(S, 1, 1);
      end;
    end;
    EndUpdate;
  end;
    
  FOldDebuggerPathAndParams:=EnvironmentOptions.DebuggerFilename;
  SetComboBoxText(cmbDebuggerPath,FOldDebuggerPathAndParams,20);
end;

procedure TDebuggerOptionsForm.FetchDebuggerSpecificOptions;
var
  i: Integer;
  AMemo: TMemo;
begin
  // clear debugger specific options components
  if FDebuggerSpecificComponents=nil then
    FDebuggerSpecificComponents:=TList.Create;
  for i:=0 to FDebuggerSpecificComponents.Count-1 do
    TComponent(FDebuggerSpecificComponents[i]).Free;
  FDebuggerSpecificComponents.Clear;

  if FCurDebuggerClass = nil then Exit;

  // create debugger specific options components
  // tmep hack
  if FCurDebuggerClass.ClassName = 'TSSHGDBMIDEBUGGER'
  then begin
    AMemo:=TMemo.Create(Self);
    FDebuggerSpecificComponents.Add(AMemo);
    with AMemo do
    begin
      Name:='DebOptsSpecMemo1';
      Parent:=gbDebuggerSpecific;
      SetBounds(5,5,Parent.Width-15,Parent.Height-35);
      WordWrap:=true;
      ReadOnly:=true;
      Caption:='The GNU debugger through ssh allows to remote debug via a ssh'
        +' connection. See docs/RemoteDebugging.txt for details. The path'
        +' must contain the ssh client filename, the hostname with an optional'
        +' username and the filename of gdb on the remote computer.'
        +' For example: "/usr/bin/ssh username@hostname gdb"';
    end;
  end;
end;

function TDebuggerOptionsForm.GetDebuggerClass: TDebuggerClass;
var
  idx: Integer;
begin
  Result := nil;

  idx := cmbDebuggerType.ItemIndex;
  if idx = -1 then Exit;
  idx := Integer(cmbDebuggerType.Items.Objects[idx]);

  if idx = -1 then Exit;
  Result := DebugBoss.Debuggers[idx];
end;

procedure TDebuggerOptionsForm.SetDebuggerClass(const AClass: TDebuggerClass);
begin
  if FCurDebuggerClass = AClass then Exit;
  FCurDebuggerClass := AClass;
  FetchDebuggerSpecificOptions;
end;

procedure TDebuggerOptionsForm.clbExceptionsCLICK (Sender: TObject );
begin
  cmdExceptionRemove.Enabled := clbExceptions.ItemIndex <> -1;
end;

procedure TDebuggerOptionsForm.cmbDebuggerTypeCHANGE(Sender: TObject);
begin
  SetDebuggerClass(GetDebuggerClass);
end;

procedure TDebuggerOptionsForm.cmdExceptionAddCLICK(Sender: TObject);
var
  idx: Integer;
  S: String;
begin
  if not InputQuery('Add Exception', 'Enter the name of the exception', S)
  then Exit;
  
  if clbExceptions.Items.IndexOf(S) = -1
  then begin
    idx := FExceptionDeleteList.IndexOf(S);
    if idx = -1
    then begin
      AddExceptionLine(nil, S);
    end
    else begin
      AddExceptionLine(TIDEException(FExceptionDeleteList.Objects[idx]), S);
      FExceptionDeleteList.Delete(idx);
    end;
  end
  else begin
    MessageDlg('Duplicate Exception name', mtError, [mbOK], 0);
  end;
end;

procedure TDebuggerOptionsForm.cmdExceptionRemoveCLICK(Sender: TObject);
var
  idx: Integer;
  obj: TObject;
begin
  idx := clbExceptions.ItemIndex;
  if idx <> -1
  then begin
    obj := clbExceptions.Items.Objects[idx];
    if obj <> nil
    then FExceptionDeleteList.AddObject(clbExceptions.Items[idx], obj);
    clbExceptions.Items.Delete(idx);
  end;
  cmdExceptionRemove.Enabled :=  clbExceptions.ItemIndex <> -1;
end;

procedure TDebuggerOptionsForm.cmdOKCLICK (Sender: TObject );
var
  n: Integer;
  ie: TIDEException;
begin
  for n := 0 to FExceptionDeleteList.Count - 1 do
    FExceptionDeleteList.Objects[n].Free;
    
  for n := 0 to clbExceptions.Items.Count - 1 do
  begin
    ie := TIDEException(clbExceptions.Items.Objects[n]);
    if ie = nil
    then begin
      ie := DebugBoss.Exceptions.Add(clbExceptions.Items[n]);
      ie.Enabled := clbExceptions.Checked[n];
    end
    else begin
      ie.BeginUpdate;        //ie^
      try
        ie.Name := clbExceptions.Items[n];
        ie.Enabled := clbExceptions.Checked[n];
      finally
        ie.EndUpdate;
      end;
    end;
  end;

  EnvironmentOptions.DebuggerFilename:=cmbDebuggerPath.Text;
  EnvironmentOptions.DebuggerFileHistory.Assign(cmbDebuggerPath.Items);
  if FCurDebuggerClass = nil
  then EnvironmentOptions.DebuggerClass := ''
  else EnvironmentOptions.DebuggerClass := FCurDebuggerClass.ClassName;

  ModalResult:=mrOk;
end;

procedure TDebuggerOptionsForm.cmdOpenDebuggerPathCLICK(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  AFilename: string;
begin
  OpenDialog:=TOpenDialog.Create(Application);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Options:=OpenDialog.Options+[ofPathMustExist];
    OpenDialog.Title:=lisChooseDebuggerPath;

    if OpenDialog.Execute then begin
      AFilename:=CleanAndExpandFilename(OpenDialog.Filename);
      SetComboBoxText(cmbDebuggerPath,AFilename);
      CheckExecutable(FOldDebuggerPathAndParams,cmbDebuggerPath.Text,
        lisEnvOptDlgInvalidDebuggerFilename,
        lisEnvOptDlgInvalidDebuggerFilenameMsg);
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TDebuggerOptionsForm.DebuggerOptionsFormCREATE(Sender: TObject);
var
  n: Integer;
begin
  FCurDebuggerClass := nil;
  
  FExceptionDeleteList := TStringList.Create;
  FExceptionDeleteList.Sorted := True;

  for n := 0 to DebugBoss.Exceptions.Count - 1 do
  begin
    AddExceptionLine(DebugBoss.Exceptions[n], '');
  end;
  
  for n := 0 to DebugBoss.Signals.Count - 1 do
  begin
    AddSignalLine(DebugBoss.Signals[n]);
  end;

  FetchDebuggerClass;

  // Fix designtime changes
  nbDebugOptions.PageIndex := 0;
end;

procedure TDebuggerOptionsForm.DebuggerOptionsFormDESTROY(Sender: TObject);
begin
  FreeAndNil(FDebuggerSpecificComponents);
  FreeAndNil(FExceptionDeleteList);
end;


initialization
  {$I debugoptionsfrm.lrs}

end.

